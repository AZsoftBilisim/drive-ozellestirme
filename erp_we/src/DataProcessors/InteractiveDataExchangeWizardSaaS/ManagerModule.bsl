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

#Region ExportMappingData

// Parameters:
//   ExportSettings1 - Structure - operation execution setting details.
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   ContinueWait - Boolean - True if a long-running operation is running.
//
Procedure OnStartExportDataForMapping(ExportSettings1, HandlerParameters, ContinueWait) Export
	
	BackgroundJobKey = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kết xuất dữ liệu để so sánh (%1)';
			|ru = 'Выгрузка данных для сопоставления (%1)';
			|en = 'Export mapping data (%1)'; fa = 'Export mapping data (%1)';
			|it = 'Upload dei dati per riscontro (%1)';
			|pl = 'Pobieranie danych do porówniania (%1)';
			|tr = 'Karşılaştırılacak verileri dışa aktarma (%1)'"),
		ExportSettings1.Peer);

	If HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang thực hiện kết xuất dữ liệu để so sánh đối với ""%1"".';
				|ru = 'Выгрузка данных для сопоставления для ""%1"" уже выполняется.';
				|en = 'Data to map for ""%1"" is already being exported.'; fa = 'Data to map for ""%1"" is already being exported.';
				|it = 'Upload dei dati per associazione per ""%1"" è già in corso.';
				|pl = 'Ładowanie danych dla dopasowania dla ""%1"" jest już wykonywane.';
				|tr = '""%1"" karşılaştırılacak veriler zaten dışa aktarılıyor.'"),
			ExportSettings1.Peer);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ExportSettings1", ExportSettings1);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kết xuất dữ liệu để so sánh (%1).';
			|ru = 'Выгрузка данных для сопоставления (%1).';
			|en = 'Data export for mapping (%1).'; fa = 'Data export for mapping (%1).';
			|it = 'Upload dei dati per associazione (%1).';
			|pl = 'Pobieranie danych do porówniania (%1).';
			|tr = 'Karşılaştırılacak verileri dışa aktarma (%1).'"),
		ExportSettings1.Peer);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.InteractiveDataExchangeWizardSaaS.ExportDataForMapping",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
	If Not ContinueWait
		And Not HandlerParameters.Cancel Then
		HandlerParameters.AdditionalParameters.Insert("BackgroundJobCompleted");
		ContinueWait = True;
	EndIf;
	
	HandlerParameters.AdditionalParameters.Insert("ExportSettings1", ExportSettings1);
	
EndProcedure

// Parameters:
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   ContinueWait - Boolean - True if a long-running operation is not completed yet.
// 
Procedure OnWaitForExportDataForMapping(HandlerParameters, ContinueWait) Export
	
	If HandlerParameters.AdditionalParameters.Property("WaitForPutDataToMapSession") Then
		
		OnWaitSystemMessagesExchangeSession(
			HandlerParameters.AdditionalParameters.SessionHandlerParameters, ContinueWait);
			
	Else
		JobCompleted = False;
		
		If HandlerParameters.AdditionalParameters.Property("BackgroundJobCompleted") Then
			JobCompleted = True;
		Else
			OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
			
			JobCompleted = Not ContinueWait And Not HandlerParameters.Cancel;
		EndIf;
		
		If JobCompleted Then
			
			Result = GetFromTempStorage(HandlerParameters.ResultAddress);
	
			If Result.DataExported1 Then
				
				HandlerParameters.AdditionalParameters.Insert("WaitForPutDataToMapSession");
				HandlerParameters.AdditionalParameters.Insert("SessionHandlerParameters");
				
				OnStartPuttingDataToMap(HandlerParameters.AdditionalParameters.ExportSettings1,
					HandlerParameters.AdditionalParameters.SessionHandlerParameters, ContinueWait);
			Else
				
				HandlerParameters.Cancel = True;
				HandlerParameters.ErrorMessage = Result.ErrorMessage;
				ContinueWait = False;
				
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

// Parameters:
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   CompletionStatus - Structure - operation execution result details.
//
Procedure OnCompleteDataExportForMapping(HandlerParameters, CompletionStatus) Export
	
	InitializeCompletionStatusOfTimeConsumingOperation(CompletionStatus);
	
	If HandlerParameters.Cancel Then
		FillPropertyValues(CompletionStatus, HandlerParameters, "Cancel, ErrorMessage");
	Else
		SessionHandlerParameters = HandlerParameters.AdditionalParameters.SessionHandlerParameters;
		
		Result = New Structure;
		Result.Insert("DataExported1",   True);
		Result.Insert("ErrorMessage", "");
		
		If SessionHandlerParameters.Cancel Then
			Result.DataExported1   = False;
			Result.ErrorMessage = SessionHandlerParameters.ErrorMessage;
		EndIf;
		
		CompletionStatus.Result = Result;
		
	EndIf;
	
	HandlerParameters = Undefined;
	
EndProcedure

#EndRegion

#Region ExportImportData

// Parameters:
//   ExportSettings1 - Structure - operation execution setting details.
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   ContinueWait - Boolean - True if a long-running operation is running.
//
Procedure OnStartExportData(ExportSettings1, HandlerParameters, ContinueWait) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	InitializeTimeConsumingOperationHandlerParameters(HandlerParameters, Undefined);
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		Message = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesManagementInterface.GetCorrespondentAccountingParametersMessage());
			
		Message.Body.ExchangePlan      = DataExchangeCached.GetExchangePlanName(ExportSettings1.Peer);
		Message.Body.CorrespondentCode = DataExchangeServer.NodeIDForExchange(ExportSettings1.Peer);
		
		Message.Body.CorrespondentZone = ExportSettings1.CorrespondentDataArea;
		
		AdditionalProperties = New Structure;
		AdditionalProperties.Insert("Interface", "3.0.1.1");
		
		Message.AdditionalInfo = XDTOSerializer.WriteXDTO(AdditionalProperties);
	
		HandlerParameters.OperationID = DataExchangeSaaS.SendMessage(Message);
			
		CommitTransaction();
	Except
		RollbackTransaction();
		
		Information = ErrorInfo();
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationMonitor(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
			
		HandlerParameters.Cancel = True;
		HandlerParameters.ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
		HandlerParameters.OperationID = Undefined;
	EndTry;

	If Not HandlerParameters.Cancel Then
		ModuleMessagesSaaS.DeliverQuickMessages();
		HandlerParameters.AdditionalParameters.Insert("ExportSettings1",
			New ValueStorage(ExportSettings1, New Deflation));
		ContinueWait = True;
	Else
		ContinueWait = False;
	EndIf;
	
EndProcedure

// Parameters:
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   ContinueWait - Boolean - True if a long-running operation is not completed yet.
//
Procedure OnWaitForExportData(HandlerParameters, ContinueWait) Export
	
	If HandlerParameters.AdditionalParameters.Property("WaitForDataExportImportSession") Then
		
		OnWaitSystemMessagesExchangeSession(
			HandlerParameters.AdditionalParameters.SessionHandlerParameters, ContinueWait);
	
	ElsIf HandlerParameters.AdditionalParameters.Property("TimeConsumingOperationWaitingForDataExportImport") Then
		
		TimeConsumingOperationHandlerParameters = HandlerParameters.AdditionalParameters.TimeConsumingOperationHandlerParameters;
		
		JobCompleted = False;
		
		If HandlerParameters.AdditionalParameters.Property("BackgroundJobCompleted") Then
			JobCompleted = True;
		Else
			OnWaitTimeConsumingOperation(TimeConsumingOperationHandlerParameters, ContinueWait);
			
			JobCompleted = Not ContinueWait And Not TimeConsumingOperationHandlerParameters.Cancel;
		EndIf;
		
		If JobCompleted Then
			
			Result = GetFromTempStorage(TimeConsumingOperationHandlerParameters.ResultAddress);
			
			If Result.Property("SessionHandlerParameters") Then
				
				HandlerParameters.AdditionalParameters.Insert("WaitForDataExportImportSession");
				HandlerParameters.AdditionalParameters.Insert("SessionHandlerParameters", Result.SessionHandlerParameters);
				
				ContinueWait = True;
				
			Else
				
				ContinueWait = False;
				
			EndIf;
			
		EndIf;
			
	Else
			
		OnWaitSystemMessagesExchangeSession(HandlerParameters, ContinueWait);
		
		If Not ContinueWait
			And Not HandlerParameters.Cancel Then
			
			ExportSettingsStorage = Undefined;
			HandlerParameters.AdditionalParameters.Property("ExportSettings1", ExportSettingsStorage);
			ExportSettings1 = ExportSettingsStorage.Get();
			
			CorrespondentParameters = Undefined;
			
			SetPrivilegedMode(True);
			Try
				CorrespondentParameters = InformationRegisters.SystemMessageExchangeSessions.GetSessionData(
					HandlerParameters.OperationID).Get();
			Except
				HandlerParameters.Cancel = True;
				HandlerParameters.ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				HandlerParameters.OperationID = Undefined;
				
				WriteLogEvent(DataExchangeSaaS.DataSyncronizationLogEvent(),
					EventLogLevel.Error, , , HandlerParameters.ErrorMessage);
					
				ContinueWait = False;
				Return;
			EndTry;
				
			InfoBaseAdmParams = Undefined;	
			If CorrespondentParameters.Property("InfoBaseAdmParams", InfoBaseAdmParams) Then
				If InfoBaseAdmParams.NodeExists Then
					If InfoBaseAdmParams.Property("DataSynchronizationSetupCompleted")
						And Not InfoBaseAdmParams.DataSynchronizationSetupCompleted Then
						HandlerParameters.Cancel = True;
						HandlerParameters.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Trước khi khởi động trao đổi dữ liệu, hãy hoàn thành tùy chỉnh đồng bộ trong chương trình ""%1"".';
								|ru = 'Перед запуском обмена данными завершите настройку синхронизации в программе ""%1"".';
								|en = 'Before starting the data exchange, finish the synchronization setup in ""%1"" application.'; fa = 'Before starting the data exchange, finish the synchronization setup in ""%1"" application.';
								|it = 'Prima di avviare lo scambio dati, completare l''impostazione di sincronizzazione nel programma ""%1"".';
								|pl = 'Przed uruchomieniem wymiany danych zakończ ustawienie synchronizacji w programie ""%1"".';
								|tr = 'Veri değişimini başlatmadan önce ""%1"" programında senkronizasyon ayarını tamamlayın.'"),
							String(ExportSettings1.Peer));
						ContinueWait = False;
						Return;
					EndIf;
					
					If InfoBaseAdmParams.Property("MessageReceivedForDataMapping")
						And InfoBaseAdmParams.MessageReceivedForDataMapping Then
						HandlerParameters.Cancel = True;
						HandlerParameters.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Trước khi khởi động trao đổi dữ liệu, hãy hoàn tất so sánh dữ liệu trong chương trình ""%1"".';
								|ru = 'Перед запуском обмена данными завершите сопоставление данных в программе ""%1"".';
								|en = 'Before starting the data exchange, finish data mapping in ""%1"" application.'; fa = 'Before starting the data exchange, finish data mapping in ""%1"" application.';
								|it = 'Prima dell''avvio dello scambio dati, completare il confronto dati nel programma ""%1"".';
								|pl = 'Przed rozpoczęciem wymiany danych zakończ porównanie danych w programie ""%1"".';
								|tr = 'Veri değişimini başlatmadan önce ""%1"" programında veri eşleştirmesini tamamlayın.'"),
							String(ExportSettings1.Peer));
						ContinueWait = False;
						Return;
					EndIf;
				EndIf;
			EndIf;
			
			BackgroundJobKey = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trao đổi dữ liệu (%1)';
					|ru = 'Обмен данными (%1)';
					|en = 'Data exchange (%1)'; fa = 'Data exchange (%1)';
					|it = 'Scambio di dati (%1)';
					|pl = 'Wymiana danych (%1)';
					|tr = 'Veri değişimi (%1)'"),
				ExportSettings1.Peer);

			If HasActiveBackgroundJobs(BackgroundJobKey) Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đang thực hiện trao đổi dữ liệu với ""%1"".';
						|ru = 'Обмен данными с ""%1"" уже выполняется.';
						|en = 'Data exchange with ""%1"" is already in progress.'; fa = 'Data exchange with ""%1"" is already in progress.';
						|it = 'Scambio di dati con ""%1"" in corso.';
						|pl = 'Wymiana danych z ""%1"" jest już w toku.';
						|tr = '""%1"" ile veri değişimi zaten yapılıyor.'"),
					ExportSettings1.Peer);
			EndIf;
				
			ProcedureParameters = New Structure;
			ProcedureParameters.Insert("ExportSettings1", ExportSettings1);
			
			ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
			ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trao đổi dữ liệu (%1).';
					|ru = 'Обмен данными (%1).';
					|en = 'Data exchange (%1).'; fa = 'Data exchange (%1).';
					|it = 'Scambio di dati (%1).';
					|pl = 'Wymiana danych (%1).';
					|tr = 'Veri değişimi (%1).'"),
				ExportSettings1.Peer);
			ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
			ExecutionParameters.RunNotInBackground1    = False;
			
			BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
				"DataProcessors.InteractiveDataExchangeWizardSaaS.ExportImportDataOnRequest",
				ProcedureParameters,
				ExecutionParameters);
				
			TimeConsumingOperationHandlerParameters = Undefined;
			OnStartTimeConsumingOperation(BackgroundJob, TimeConsumingOperationHandlerParameters, ContinueWait);
				
			HandlerParameters.AdditionalParameters.Insert("TimeConsumingOperationWaitingForDataExportImport");
			HandlerParameters.AdditionalParameters.Insert("TimeConsumingOperationHandlerParameters", TimeConsumingOperationHandlerParameters);
			
			If Not ContinueWait
				And Not HandlerParameters.Cancel Then
				HandlerParameters.AdditionalParameters.Insert("BackgroundJobCompleted");
				ContinueWait = True;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//   HandlerParameters - Structure - secondary parameters:
//     * AdditionalParameters - Structure - arbitrary additional parameters.
//   CompletionStatus - Structure - operation execution result details.
//
Procedure OnCompleteDataExport(HandlerParameters, CompletionStatus) Export
	
	InitializeCompletionStatusOfTimeConsumingOperation(CompletionStatus);
	
	If HandlerParameters.Cancel Then
		FillPropertyValues(CompletionStatus, HandlerParameters, "Cancel, ErrorMessage");
	Else
		SessionHandlerParameters = HandlerParameters.AdditionalParameters.SessionHandlerParameters;
		
		Result = New Structure;
		Result.Insert("DataExported1",   True);
		Result.Insert("ErrorMessage", "");
		
		If SessionHandlerParameters.Cancel Then
			Result.DataExported1   = False;
			Result.ErrorMessage = SessionHandlerParameters.ErrorMessage;
		EndIf;
		
		CompletionStatus.Result = Result;
		
	EndIf;
	
	HandlerParameters = Undefined;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region MessagesExchangeSessions

Procedure OnWaitSystemMessagesExchangeSession(HandlerParameters, ContinueWait) Export
	
	SessionStatus = "";
	Try
		SessionStatus = SessionStatus(HandlerParameters.OperationID);
	Except
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationMonitor(),
			EventLogLevel.Error, , , ErrorMessage);
			
		HandlerParameters.Cancel = True;
		HandlerParameters.ErrorMessage = ErrorMessage;
		HandlerParameters.OperationID = Undefined;
		
		ContinueWait  = False;
		Return;
	EndTry;
	
	If SessionStatus = "Success" Then
		
		ContinueWait = False;
		
	ElsIf SessionStatus = "Error" Then
		
		HandlerParameters.Cancel = True;
		HandlerParameters.OperationID = Undefined;
		ContinueWait  = False;
		
	Else
		
		ContinueWait = True;
		
	EndIf;
	
EndProcedure

Function SessionStatus(Val Session)
	
	SetPrivilegedMode(True);
	
	Return InformationRegisters.SystemMessageExchangeSessions.SessionStatus(Session);
	
EndFunction

#EndRegion

#Region TimeConsumingOperations1

// For internal use.
//
Procedure OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait = True)
	
	InitializeTimeConsumingOperationHandlerParameters(HandlerParameters, BackgroundJob);
	
	If BackgroundJob.Status = "Running" Then
		HandlerParameters.ResultAddress       = BackgroundJob.ResultAddress;
		HandlerParameters.OperationID = BackgroundJob.JobID;
		HandlerParameters.TimeConsumingOperation    = True;
		
		ContinueWait = True;
		Return;
	ElsIf BackgroundJob.Status = "Completed2" Then
		HandlerParameters.ResultAddress    = BackgroundJob.ResultAddress;
		HandlerParameters.TimeConsumingOperation = False;
		
		ContinueWait = False;
		Return;
	Else
		HandlerParameters.ErrorMessage = BackgroundJob.BriefErrorDescription;
		If ValueIsFilled(BackgroundJob.DetailErrorDescription) Then
			HandlerParameters.ErrorMessage = BackgroundJob.DetailErrorDescription;
		EndIf;
		
		HandlerParameters.Cancel = True;
		HandlerParameters.TimeConsumingOperation = False;
		
		ContinueWait = False;
		Return;
	EndIf;
	
EndProcedure

// For internal use.
//
Procedure OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait = True)
	
	If HandlerParameters.Cancel
		Or Not HandlerParameters.TimeConsumingOperation Then
		ContinueWait = False;
		Return;
	EndIf;
	
	JobCompleted = False;
	Try
		JobCompleted = TimeConsumingOperations.JobCompleted(HandlerParameters.OperationID);
	Except
		HandlerParameters.Cancel             = True;
		HandlerParameters.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , HandlerParameters.ErrorMessage);
	EndTry;
		
	If HandlerParameters.Cancel Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ContinueWait = Not JobCompleted;
	
EndProcedure

Procedure InitializeTimeConsumingOperationHandlerParameters(HandlerParameters, BackgroundJob)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("BackgroundJob",          BackgroundJob);
	HandlerParameters.Insert("Cancel",                   False);
	HandlerParameters.Insert("ErrorMessage",       "");
	HandlerParameters.Insert("TimeConsumingOperation",      False);
	HandlerParameters.Insert("OperationID",   Undefined);
	HandlerParameters.Insert("ResultAddress",         Undefined);
	HandlerParameters.Insert("AdditionalParameters", New Structure);
	
EndProcedure

Function HasActiveBackgroundJobs(BackgroundJobKey)
	
	Filter = New Structure;
	Filter.Insert("Key",      BackgroundJobKey);
	Filter.Insert("State", BackgroundJobState.Active);
	
	ActiveBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	
	Return (ActiveBackgroundJobs.Count() > 0);
	
EndFunction

Procedure InitializeCompletionStatusOfTimeConsumingOperation(CompletionStatus)
	
	CompletionStatus = New Structure;
	CompletionStatus.Insert("Cancel",             False);
	CompletionStatus.Insert("ErrorMessage", "");
	CompletionStatus.Insert("Result",         Undefined);

EndProcedure

#EndRegion

#Region BackgroundJobsHandlers

Procedure ExportDataForMapping(Parameters, ResultAddress) Export
	
	ExportSettings1 = Undefined;
	Parameters.Property("ExportSettings1", ExportSettings1);
	
	Result = New Structure;
	Result.Insert("DataExported1",   True);
	Result.Insert("ErrorMessage", "");
	
	Cancel = False;
	Try
		DataExchangeSaaS.RunDataExport(Cancel, ExportSettings1.Peer);
	Except
		Result.DataExported1 = False;
		Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error, , , Result.ErrorMessage);
	EndTry;
		
	Result.DataExported1 = Result.DataExported1 And Not Cancel;
	
	If Not Result.DataExported1
		And IsBlankString(Result.ErrorMessage) Then
		Result.ErrorMessage = NStr("vi = 'Khi thực hiện kết xuất dữ liệu để so sánh, đã xảy ra lỗi (xem Nhật ký sự kiện).';
									|ru = 'При выполнении выгрузки данных для сопоставления возникли ошибки (см. Журнал регистрации).';
									|en = 'Errors occurred while exporting mapping data. See the event log.'; fa = 'Errors occurred while exporting mapping data. See the event log.';
									|it = 'Si sono verificati degli errori durante upload dei dati per associazione (vedere il Registro).';
									|pl = 'Podczas wykonywania ładowania danych dla dopasowania wynikły błędy (patrz Dziennik rejestracji).';
									|tr = 'Karşılaştırılacak veri dışa aktarma işlemi sırasında hatalar oluştu (bkz. Kayıt günlüğü).'");
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure ExportImportDataOnRequest(Parameters, ResultAddress) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	ExportSettings1 = Undefined;
	Parameters.Property("ExportSettings1", ExportSettings1);
	
	SessionHandlerParameters = Undefined;
	InitializeTimeConsumingOperationHandlerParameters(SessionHandlerParameters, Undefined);
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		If ExportSettings1.Property("ExportAddition") Then
			RegisterAdditionExportData(ExportSettings1.ExportAddition);
		EndIf;
		
		Message = ModuleMessagesSaaS.NewMessage(
			MessagesDataExchangeAdministrationManagementInterface.PushSynchronizationBetweenTwoApplicationsMessage());
			
		Message.Body.CorrespondentZone = ExportSettings1.CorrespondentDataArea;
		
		SessionHandlerParameters.OperationID = DataExchangeSaaS.SendMessage(Message);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		SessionHandlerParameters.Cancel = True;
		SessionHandlerParameters.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.DataSyncronizationLogEvent(),
			EventLogLevel.Error, , , SessionHandlerParameters.ErrorMessage);
	EndTry;
	
	If Not SessionHandlerParameters.Cancel Then
		ModuleMessagesSaaS.DeliverQuickMessages();
	EndIf;
	
	Result = New Structure;
	Result.Insert("SessionHandlerParameters", SessionHandlerParameters);
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

#EndRegion

// Registers additional data on settings.
//
// Parameters:
//     ExportProcessing - Structure
//                       - DataProcessorObject.InteractiveExportChange - an initialized object.
//
Procedure RegisterAdditionExportData(Val ExportProcessing)
	
	If TypeOf(ExportProcessing) = Type("Structure") Then
		DataProcessor = DataProcessors.InteractiveExportChange.Create();
		FillPropertyValues(DataProcessor, ExportProcessing, , "AdditionalRegistration, AdditionalNodeScenarioRegistration");
		
		DataProcessor.AllDocumentsFilterComposer.LoadSettings(ExportProcessing.AllDocumentsSettingFilterComposer);
	Else
		DataProcessor = ExportProcessing;
	EndIf;
	
	If DataProcessor.ExportOption <= 0 Then
		// Do not add.
		Return;
		
	ElsIf DataProcessor.ExportOption = 1 Then
		// For a period with filter, clearing additional registration
		DataProcessor.AdditionalRegistration.Clear();
		
	ElsIf DataProcessor.ExportOption = 2 Then
		// Detailed settings, clearing general parameters
		DataProcessor.AllDocumentsFilterComposer = Undefined;
		DataProcessor.AllDocumentsFilterPeriod      = Undefined;
		
		DataExchangeServer.FillValueTable(DataProcessor.AdditionalRegistration, ExportProcessing.AdditionalRegistration);
		
	ElsIf DataProcessor.ExportOption = 3 Then
		// According to the node scenario, simulating a detailed option.
		DataProcessor.ExportOption = 2;
		
		DataProcessor.AllDocumentsFilterComposer = Undefined;
		DataProcessor.AllDocumentsFilterPeriod      = Undefined;
		
		DataExchangeServer.FillValueTable(DataProcessor.AdditionalRegistration, ExportProcessing.AdditionalNodeScenarioRegistration);
		
	EndIf;
	
	DataProcessor.RecordAdditionalChanges();
	
EndProcedure

Procedure OnStartPuttingDataToMap(ExportSettings1, HandlerParameters, ContinueWait) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
		
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	InitializeTimeConsumingOperationHandlerParameters(HandlerParameters, Undefined);
	
	SetPrivilegedMode(True);
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExportSettings1.Peer);
	
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		PredefinedNodeAlias = DataExchangeServer.PredefinedNodeAlias(ExportSettings1.Peer);
	
		If ValueIsFilled(PredefinedNodeAlias) Then
			// A sender node code correction is required.
			ThisApplicationCode = TrimAll(PredefinedNodeAlias);
		Else
			ThisApplicationCode = DataExchangeServer.NodeIDForExchange(ExportSettings1.Peer);
		EndIf;
	Else
		ThisApplicationCode = DataExchangeCached.GetThisNodeCodeForExchangePlan(ExchangePlanName);
	EndIf;
	
	BeginTransaction();
	Try
		// Send a message to a peer infobase.
		Message = ModuleMessagesSaaS.NewMessage(
			DataExchangeMessagesManagementInterface.ImportExchangeMessageMessage());
			
		Message.Body.CorrespondentZone = ExportSettings1.CorrespondentDataArea;
		Message.Body.ExchangePlan      = ExchangePlanName;
		Message.Body.CorrespondentCode = ThisApplicationCode;
		
		Message.Body.MessageForDataMatching = True;
		
		AdditionalProperties = New Structure;
		AdditionalProperties.Insert("Interface", "3.0.1.1");
		AdditionalProperties.Insert("MessageForDataMapping", True);
		
		Message.AdditionalInfo = XDTOSerializer.WriteXDTO(AdditionalProperties);
		
		HandlerParameters.OperationID = DataExchangeSaaS.SendMessage(Message);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		Information = ErrorInfo();
		
		WriteLogEvent(DataExchangeSaaS.EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
			
		HandlerParameters.Cancel = True;
		HandlerParameters.ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
		HandlerParameters.OperationID = Undefined;
		
		ContinueWait = False;
		Return;
	EndTry;
	
	ModuleMessagesSaaS.DeliverQuickMessages();
	ContinueWait = True;
	
EndProcedure

#EndRegion

#EndIf