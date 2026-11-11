///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ListReadingAllowed(ObjectWithIssue)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName             = Metadata.InformationRegisters.AccountingCheckResults.FullName();
	
	AllIssuesProcessed = False;
	UniqueKey      = CommonClientServer.BlankUUID();
	While Not AllIssuesProcessed Do
		
		Query = New Query;
		Query.Text = "SELECT TOP 1000
			|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
			|	AccountingCheckResults.CheckRule AS CheckRule,
			|	AccountingCheckResults.CheckKind AS CheckKind,
			|	AccountingCheckResults.UniqueKey AS UniqueKey
			|FROM
			|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
			|WHERE
			|	AccountingCheckResults.UniqueKey > &UniqueKey
			|
			|ORDER BY
			|	UniqueKey";
		
		Query.SetParameter("UniqueKey", UniqueKey);
		Result = Query.Execute().Unload(); // @skip-check query-in-loop - batch registration of data for updating.
	
		InfobaseUpdate.MarkForProcessing(Parameters, Result, AdditionalParameters);
		
		RecordsCount = Result.Count();
		If RecordsCount < 1000 Then
			AllIssuesProcessed = True;
		EndIf;
		
		If RecordsCount > 0 Then
			UniqueKey = Result[RecordsCount - 1].UniqueKey;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ProcessingCompleted = True;
	
	RegisterMetadata    = Metadata.InformationRegisters.AccountingCheckResults;
	FullRegisterName     = RegisterMetadata.FullName();
	RegisterPresentation = RegisterMetadata.Presentation();
	FilterPresentation   = NStr("vi = 'Đối tượng có vấn đề = ""%1""
		|Quy tắc kiểm tra = ""%2""
		|Dạng kiểm tra = ""%3""
		|Khóa duy nhất = ""%4""';
		|ru = 'Проблемный объект = ""%1""
		|Правило проверки = ""%2""
		|Вид проверки = ""%3""
		|Ключ уникальности = ""%4""';
		|en = 'Object with issues = ""%1""
		|Check rule = ""%2""
		|Check type = ""%3""
		|Unique key = ""%4""'; fa = 'Object with issues = ""%1""
		|Check rule = ""%2""
		|Check type = ""%3""
		|Unique key = ""%4""';
		|it = 'Oggetto problematico = ""%1 ""
		|Regola di verifica = ""%2""
		|Tipo di verifica = ""%3""
		|Chiave univoca = ""%4""';
		|pl = 'Problemowy obiekt = ""%1""
		|Reguła sprawdzenia = ""%2""
		|Rodzaj sprawdzenia = ""%3""
		|Klucz unikalności = ""%4""';
		|tr = 'Problemli nesne = ""%1""
		|Kontrol kuralı = ""%2""
		|Kontrol türü =""%3""
		|Benzersizlik anahtarı = ""%4""'");
	
	AdditionalProcessingDataSelectionParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	
	Selection = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(
		Parameters.Queue, FullRegisterName, AdditionalProcessingDataSelectionParameters);
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			ObjectWithIssue = Selection.ObjectWithIssue;
			CheckRule  = Selection.CheckRule;
			CheckKind      = Selection.CheckKind;
			UniqueKey = Selection.UniqueKey;
			
			Block = New DataLock;
			LockItem = Block.Add(FullRegisterName);
			LockItem.SetValue("ObjectWithIssue", ObjectWithIssue);
			LockItem.SetValue("CheckRule",  CheckRule);
			LockItem.SetValue("CheckKind",      CheckKind);
			LockItem.SetValue("UniqueKey", UniqueKey);
			Block.Lock();
			
			RecordSet = CreateRecordSet();
			Filter = RecordSet.Filter;
			Filter.UniqueKey.Set(UniqueKey);
			Filter.ObjectWithIssue.Set(ObjectWithIssue);
			Filter.CheckRule.Set(CheckRule);
			Filter.CheckKind.Set(CheckKind);
			
			FilterPresentation = StringFunctionsClientServer.SubstituteParametersToString(FilterPresentation, ObjectWithIssue, CheckRule, CheckKind, UniqueKey);
			
			RecordSet.Read();
			For Each CurrentRecord In RecordSet Do
				
				If Not ValueIsFilled(CurrentRecord.Checksum) Then
					CurrentRecord.Checksum = AccountingAuditInternal.IssueChecksum(CurrentRecord);
				EndIf;
				
				If CurrentRecord.DeleteIgnoreIssue And Not CurrentRecord.IgnoreIssue Then
					CurrentRecord.IgnoreIssue = CurrentRecord.DeleteIgnoreIssue;
				EndIf;
				
			EndDo;
			
			InfobaseUpdate.WriteRecordSet(RecordSet);
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xử lý kết quả kiểm tra tiến hành kế toán có bộ lọc %1 theo nguyên nhân:
				|%2';
				|ru = 'Не удалось обработать результаты проверки ведения учета с отбором %1 по причине:
				|%2';
				|en = 'Couldn''t process data integrity check results with filter %1. Reason:
				|%2'; fa = 'Couldn''t process data integrity check results with filter %1. Reason:
				|%2';
				|it = 'Couldn''t process data integrity check results with filter %1. Reason:
				|%2';
				|pl = 'Couldn''t process data integrity check results with filter %1. Reason:
				|%2';
				|tr = '%1 filtresi ile muhasebe denetimi sonuçları şu sebeple işlenemedi:
				|%2'"), FilterPresentation, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			InfobaseUpdate.WriteErrorToEventLog(
				RegisterMetadata,
				RegisterPresentation,
				MessageText);
			
		EndTry;
		
	EndDo;
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "InformationRegister.AccountingCheckResults") Then
		ProcessingCompleted = False;
	EndIf;
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý một số kết quả kiểm tra tiến hành kế toán (bị bỏ qua): %1';
				|ru = 'Не удалось обработать некоторые результаты проверки ведения учета (пропущены): %1';
				|en = 'Couldn''t process (skipped) some data integrity check results: %1'; fa = 'Couldn''t process (skipped) some data integrity check results: %1';
				|it = 'Non è stato possibile elaborare alcuni risultati di verifica di contabilità (saltati): %1';
				|pl = 'Nie udało się przetworzyć niektórych wyników sprawdzenia prowadzenia ewidencji (pominięte): %1';
				|tr = 'Bazı muhasebe denetimi sonuçları işlenemedi (atlandı): %1'"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), 
			EventLogLevel.Information, Metadata.InformationRegisters.AccountingCheckResults, ,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xử lý phần trình tự kết quả kiểm tra tiến hành kế toán: %1';
					|ru = 'Обработана очередная порция результатов проверки ведения учета: %1';
					|en = 'Yet another batch of data integrity check results is processed: %1'; fa = 'Yet another batch of data integrity check results is processed: %1';
					|it = 'È stata elaborata un''altra porzione di risultati di verifica di contabilità: %1';
					|pl = 'Przetworzono kolejną porcję wyników sprawdzenia prowadzenia ewidencji: %1';
					|tr = 'Bir muhasebe denetimi sonuçları grubu daha işlendi: %1'"),
				ObjectsProcessed));
	EndIf;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#EndIf