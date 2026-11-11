///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure UpdateSettings2(InfobaseNode, SettingKind, SettingValue) Export
	
	UpdateRecord(InfobaseNode, "Settings", SettingKind, SettingValue);
	
EndProcedure

Procedure UpdateCorrespondentSettings(InfobaseNode, SettingKind, SettingValue) Export
	
	UpdateRecord(InfobaseNode, "CorrespondentSettings", SettingKind, SettingValue);
	
EndProcedure

Function SettingValue(InfobaseNode, SettingKind) Export
	
	Result = Undefined;
	
	ReadRecord(InfobaseNode, "Settings", SettingKind, Result);
	
	Return Result;
	
EndFunction

Function CorrespondentSettingValue(InfobaseNode, SettingKind) Export
	
	Result = Undefined;
	
	ReadRecord(InfobaseNode, "CorrespondentSettings", SettingKind, Result);
	
	Return Result;
	
EndFunction

#EndRegion
	
#Region Private

Procedure UpdateRecord(InfobaseNode, DimensionName, SettingKind, SettingValue)
	
	Manager = CreateRecordManager();
	Manager.InfobaseNode = InfobaseNode;
	
	Manager.Read();
	
	NewSettings1 = New Structure;
	
	If Manager.Selected() Then
		CurrentSettings = Manager[DimensionName].Get();
		
		If TypeOf(CurrentSettings) = Type("ValueTable") Then
			
			NewSettings1.Insert("SupportedObjects", CurrentSettings);
			
		ElsIf TypeOf(CurrentSettings) = Type("Structure") Then
			
			For Each SettingItem In CurrentSettings Do
				
				NewSettings1.Insert(SettingItem.Key, SettingItem.Value);
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	NewSettings1.Insert(SettingKind, SettingValue);
	
	RecordStructure = New Structure;
	RecordStructure.Insert("InfobaseNode", InfobaseNode);
	RecordStructure.Insert(DimensionName, New ValueStorage(NewSettings1, New Deflation(9)));
	
	DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "XDTODataExchangeSettings");
	
EndProcedure

Procedure ReadRecord(InfobaseNode, DimensionName, SettingKind, Result)
	
	Manager = CreateRecordManager();
	Manager.InfobaseNode = InfobaseNode;
	
	Manager.Read();
	
	SettingStructure = New Structure;
	
	If Manager.Selected() Then
		CurrentSettings = Manager[DimensionName].Get();
		
		If TypeOf(CurrentSettings) = Type("ValueTable") Then
			
			SettingStructure.Insert("SupportedObjects", CurrentSettings);
			
		ElsIf TypeOf(CurrentSettings) = Type("Structure") Then
			
			For Each SettingItem In CurrentSettings Do
				
				SettingStructure.Insert(SettingItem.Key, SettingItem.Value);
				
			EndDo;
			
		EndIf;
	EndIf;
	
	SettingStructure.Property(SettingKind, Result);
	
EndProcedure

#Region UpdateHandlers

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName             = "InformationRegister.XDTODataExchangeSettings";
	
	XTDOExchangePlans = New Array;
	For Each ExchangePlan In DataExchangeCached.SSLExchangePlans() Do
		If Not DataExchangeCached.IsXDTOExchangePlan(ExchangePlan) Then
			Continue;
		EndIf;
		XTDOExchangePlans.Add(ExchangePlan);
	EndDo;
	
	If XTDOExchangePlans.Count() = 0 Then
		Return;
	EndIf;
	
	QueryOptions = New Structure;
	QueryOptions.Insert("ExchangePlansArray1",                 XTDOExchangePlans);
	QueryOptions.Insert("AdditionalExchangePlanProperties", "");
	QueryOptions.Insert("ResultToTemporaryTable",       True);
	
	TempTablesManager = New TempTablesManager;
	
	ExchangeNodesQuery = New Query(DataExchangeServer.ExchangePlansForMonitorQueryText(QueryOptions, False));
	ExchangeNodesQuery.TempTablesManager = TempTablesManager;
	ExchangeNodesQuery.Execute();
	
	Query = New Query(
	"SELECT
	|	ConfigurationExchangePlans.InfobaseNode AS InfobaseNode
	|FROM
	|	ConfigurationExchangePlans AS ConfigurationExchangePlans
	|		LEFT JOIN InformationRegister.XDTODataExchangeSettings AS XDTODataExchangeSettings
	|		ON (XDTODataExchangeSettings.InfobaseNode = ConfigurationExchangePlans.InfobaseNode)
	|WHERE
	|	(XDTODataExchangeSettings.InfobaseNode IS NULL
	|			OR XDTODataExchangeSettings.CorrespondentExchangePlanName = """")");
	
	Query.TempTablesManager = TempTablesManager;
	
	Result = Query.Execute().Unload();
	
	InfobaseUpdate.MarkForProcessing(Parameters, Result, AdditionalParameters);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ProcessingCompleted = True;
	
	RegisterMetadata    = Metadata.InformationRegisters.XDTODataExchangeSettings;
	FullRegisterName     = RegisterMetadata.FullName();
	RegisterPresentation = RegisterMetadata.Presentation();
	FilterPresentation   = NStr("vi = 'УзелИнформационнойБазы = ""%1""';
								|ru = 'УзелИнформационнойБазы = ""%1""';
								|en = 'InfobaseNode = %1'; fa = 'InfobaseNode = %1';
								|it = 'SiteInformationBase = ""%1""';
								|pl = 'WęzełBazyInformacyjnej = ""%1""';
								|tr = 'УзелИнформационнойБазы = ""%1""'");
	
	AdditionalProcessingDataSelectionParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	
	Selection = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(
		Parameters.Queue, FullRegisterName, AdditionalProcessingDataSelectionParameters);
	
	Processed = 0;
	RecordsWithIssuesCount = 0;
	
	While Selection.Next() Do
		
		Try
			
			RefreshDataExchangeSettingsOfCorrespondentXDTO(Selection.InfobaseNode);
			Processed = Processed + 1;
			
		Except
			
			RecordsWithIssuesCount = RecordsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xử lý tập hợp bản ghi của biểu ghi ""%1"" với bộ lọc %2 do nguyên nhân:
				|%3';
				|ru = 'Не удалось обработать набор записей регистра ""%1"" с отбором %2 по причине:
				|%3';
				|en = 'Couldn''t process a set of ""%1"" register records with filter %2 due to:
				|%3'; fa = 'Couldn''t process a set of ""%1"" register records with filter %2 due to:
				|%3';
				|it = 'Impossibile elaborare il set di registri ""%1"" con la selezione %2 a causa di: 
				|%3';
				|pl = 'Nie udało się przetworzyć zestawu zapisów rejestru ""%1"" z selekcją %2 z powodu: 
				|%3';
				|tr = 'Aşağıdaki nedenle kaydedicinin kayıt kümesi ""%1"" %2 seçimle işlenemedi: 
				|%3'"), RegisterPresentation, FilterPresentation, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				RegisterMetadata, , MessageText);
			
		EndTry;
		
	EndDo;
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName) Then
		ProcessingCompleted = False;
	EndIf;
	
	If Processed = 0 And RecordsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thủ tục РегистрыСведений.НастройкиОбменаДаннымиXDTO.ОбработатьДанныеДляПереходаНаНовуюВерсию không thể xử lý nhiều bản ghi của nút trao đổi (đã bỏ qua): %1';
				|ru = 'Процедуре РегистрыСведений.НастройкиОбменаДаннымиXDTO.ОбработатьДанныеДляПереходаНаНовуюВерсию не удалось обработать некоторые записи узлов обмена (пропущены): %1';
				|en = 'Procedure InformationRegisters.XDTODataExchangeSettings.ProcessDataForMigrationToNewVersion failed to process (skipped) some exchange node records: %1'; fa = 'Procedure InformationRegisters.XDTODataExchangeSettings.ProcessDataForMigrationToNewVersion failed to process (skipped) some exchange node records: %1';
				|it = 'La procedura RegistroInformazioni. ImpostazioniScambioDatieXFTO.ElaborazioneDatiTransizioneNuovaVersione non è riuscita ad elaborare alcune voci del nodo di scambio (omesse): %1';
				|pl = 'Procedura RejestryInformacjiUstawieniaDaneXDTO.PrzetwarzanieDanychDlaPrzejściaDoNowejWersji nie udało się opracować niektórych zapisów węzłów wymiany (pominięte): %1';
				|tr = 'РегистрыСведений.НастройкиОбменаДаннымиXDTO.ОбработатьДанныеДляПереходаНаНовуюВерсию prosedürü bazı alışveriş ünitesi kayıtlarını işleyemedi (atlandı): %1'"), 
			RecordsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			, ,
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thủ tục РегистрыСведений.НастройкиОбменаДаннымиXDTO.ОбработатьДанныеДляПереходаНаНовуюВерсию đã xử lý tùy chọn ghi lại theo trình tự: %1';
				|ru = 'Процедура РегистрыСведений.НастройкиОбменаДаннымиXDTO.ОбработатьДанныеДляПереходаНаНовуюВерсию обработала очередную порцию записей: %1';
				|en = 'The InformationRegisters.XDTODataExchangeSettings.ProcessDataForMigrationToNewVersion procedure processed records: %1'; fa = 'The InformationRegisters.XDTODataExchangeSettings.ProcessDataForMigrationToNewVersion procedure processed records: %1';
				|it = 'La procedura RegistroInformazioni. ImpostazioniScambioDatieXFTO.ElaborazioneDatiTransizioneNuovaVersione ha elaborato un''ulteriore porzione di registro: %1';
				|pl = 'Procedura РегистрыСведений.НастройкиОбменаДаннымиXDTO.ОбработатьДанныеДляПереходаНаНовуюВерсию przetworzyła  nową część wpisów: %1';
				|tr = 'РегистрыСведений.НастройкиОбменаДаннымиXDTO.ОбработатьДанныеДляПереходаНаНовуюВерсию prosedürü sıradaki kayıt grubunu işledi: %1'"),
			Processed));
	EndIf;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

Procedure RefreshDataExchangeSettingsOfCorrespondentXDTO(InfobaseNode)
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		
		LockItem = Block.Add("InformationRegister.XDTODataExchangeSettings");
		LockItem.SetValue("InfobaseNode", InfobaseNode);
		
		Block.Lock();
		
		RecordSet = CreateRecordSet();
		RecordSet.Filter.InfobaseNode.Set(InfobaseNode);
		
		RecordSet.Read();
		
		If RecordSet.Count() > 0 Then
			CurrentRecord = RecordSet[0];
		Else
			CurrentRecord = RecordSet.Add();
			CurrentRecord.InfobaseNode = InfobaseNode;
		EndIf;
		
		CurrentRecord.CorrespondentExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
		
		InfobaseUpdate.WriteRecordSet(RecordSet);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf