///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Infobase update.

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DigitalSignatures.SignedObject AS SignedObject,
	|	DigitalSignatures.SequenceNumber AS SequenceNumber
	|FROM
	|	InformationRegister.DigitalSignatures AS DigitalSignatures
	|WHERE
	|	DigitalSignatures.SignatureID = &BlankUUID";
	
	Query.SetParameter("BlankUUID", New UUID("00000000-0000-0000-0000-000000000000"));
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName = Metadata.InformationRegisters.DigitalSignatures.FullName();
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload(), AdditionalParameters);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ProcessingCompleted = True;
	
	RegisterMetadata    = Metadata.InformationRegisters.DigitalSignatures;
	RegisterPresentation = RegisterMetadata.Presentation();
	FullRegisterName     = RegisterMetadata.FullName();
	Selection = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(
		Parameters.Queue, FullRegisterName);
	
	Processed = 0;
	RecordsWithIssuesCount = 0;
	
	While Selection.Next() Do
		RecordSet = InformationRegisters.DigitalSignatures.CreateRecordSet();
		RecordSet.Filter.SignedObject.Set(Selection.SignedObject);
		RecordSet.Filter.SequenceNumber.Set(Selection.SequenceNumber);
		Block = New DataLock;
		LockItem = Block.Add(FullRegisterName);
		LockItem.SetValue("SignedObject", Selection.SignedObject);
		LockItem = Block.Add(FullRegisterName);
		LockItem.SetValue("SequenceNumber", Selection.SequenceNumber);
		BeginTransaction();
		Try
			Block.Lock();
			RecordSet.Read();
			If RecordSet.Count() > 0 Then
				Record = RecordSet[0];
				WriteSet = False;
				If Not ValueIsFilled(Record.SignatureID) Then
					Record.SignatureID = New UUID;
					WriteSet = True;
				EndIf;
				If WriteSet Then
					InfobaseUpdate.WriteRecordSet(RecordSet);
				EndIf;
			EndIf;
			InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			Processed = Processed + 1;
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorInfo = ErrorInfo();
			RecordsWithIssuesCount = RecordsWithIssuesCount + 1;
			KeyProperties1 = New Structure("SignedObject, SequenceNumber",
				Selection.SignedObject, Selection.SequenceNumber);
			RecordKey = InformationRegisters.DigitalSignatures.CreateRecordKey(KeyProperties1);
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xử lý bản ghi của biểu ghi %1 do nguyên nhân:
					|%2';
					|ru = 'Не удалось обработать запись регистра %1 по причине:
					|%2';
					|en = 'Couldn''t process a ""%1"" register record. Reason:
					|%2'; fa = 'Couldn''t process a ""%1"" register record. Reason:
					|%2';
					|it = 'Non è stato possibile elaborare la registrazione%1 a causa di:
					|%2';
					|pl = 'Nie udało się przetworzyć wpisu rejestru %1 z powodu:
					|%2';
					|tr = 'Bu nedenle %1 kayıt defleri kaydı işlenemedi:
					|%2'"),
				GetURL(RecordKey),
				ErrorProcessing.DetailErrorDescription(ErrorInfo));
			
			InfobaseUpdate.WriteErrorToEventLog(
				RegisterMetadata,
				RegisterPresentation,
				MessageText);
		EndTry;
	EndDo;
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName) Then
		ProcessingCompleted = False;
	EndIf;
	
	ProcedureName = FullRegisterName + "." + "ProcessDataForMigrationToNewVersion";
	
	If Processed = 0 And RecordsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Quy trình %1 không thể xử lý một số hồ sơ (bỏ qua): %2';
				|ru = 'Процедуре %1 не удалось обработать некоторые записи (пропущены): %2';
				|en = 'Procedure %1 failed to process (skipped) some records: %2.'; fa = 'Procedure %1 failed to process (skipped) some records: %2.';
				|it = 'La procedura %1 non è riuscita a elaborare alcuni record (ignorati): %2';
				|pl = 'Procedurze %1 nie udało się przetworzyć niektóre wpisy (pominięte): %2';
				|tr = '%1 prosedürü bazı kayıtları işleyemedi (atlandı): %2'"), 
			ProcedureName,
			RecordsWithIssuesCount);
		Raise MessageText;
	EndIf;
	
	WriteLogEvent(
		InfobaseUpdate.EventLogEvent(), 
		EventLogLevel.Information, RegisterMetadata, ,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Quy trình %1 đã xử lý lô hồ sơ tiếp theo: %2';
				|ru = 'Процедура %1 обработала очередную порцию записей: %2';
				|en = 'Procedure %1 processed yet another batch of records: %2.'; fa = 'Procedure %1 processed yet another batch of records: %2.';
				|it = 'La procedura %1 ha elaborato un''ulteriore porzione di record: %2';
				|pl = 'Procedura %1 przetworzyła kolejną część wpisów: %2';
				|tr = '%1 prosedürü diğer bir kayıt kümesini işledi: %2'"),
			ProcedureName,
			Processed));
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#EndIf
