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

// For internal use.
//
Procedure ExecuteAutomaticDataMapping(Parameters, TempStorageAddress) Export
	
	Result = AutomaticDataMappingResult(
		Parameters.InfobaseNode,
		Parameters.ExchangeMessageFileName,
		Parameters.TempExchangeMessagesDirectoryName,
		Parameters.CheckVersionDifference);
	
	PutToTempStorage(Result, TempStorageAddress);
		
EndProcedure

// For internal use.
// Imports an exchange message from the external source
//  (ftp, email, network directory) to the temporary directory of the operational system user.
//
Procedure GetExchangeMessageToTemporaryDirectory(Parameters, TempStorageAddress) Export
	
	Cancel = False;
	SetPrivilegedMode(True);
	
	StructureOfData = New Structure;
	StructureOfData.Insert("TempExchangeMessagesDirectoryName", "");
	StructureOfData.Insert("DataPackageFileID",       Undefined);
	StructureOfData.Insert("ExchangeMessageFileName",              "");
	
	If Parameters.MessageReceivedForDataMapping Then
		
		Filter = New Structure("InfobaseNode", Parameters.InfobaseNode);
		CommonSettings = InformationRegisters.CommonInfobasesNodesSettings.Get(Filter);
		
		TempFileName = "";
		If ValueIsFilled(CommonSettings.MessageForDataMapping) Then
	
			PassiveModeFileInformation = Common.FileInfobase()
				And ExchangeMessagesTransport.TransportParameter(Parameters.TransportID, "PassiveMode");
			
			TempFileName = DataExchangeServer.GetFileFromStorage(CommonSettings.MessageForDataMapping, PassiveModeFileInformation);
			
			File = New File(TempFileName);
			If File.Exists() And File.IsFile() Then
				// Put the message info for mapping back to the storage.
				// Intended to restore the data in case of abnormal analysis termination.
				DataExchangeServer.PutFileInStorage(TempFileName, CommonSettings.MessageForDataMapping);
				
				DataPackageFileID = File.GetModificationTime();
				
				DirectoryIDForExchange = "";
				TempDirectoryNameForExchange = DataExchangeServer.CreateTempExchangeMessagesDirectory(DirectoryIDForExchange);
				TempFileNameForExchange    = CommonClientServer.GetFullFileName(
					TempDirectoryNameForExchange, DataExchangeServer.UniqueExchangeMessageFileName());
				
				CopyFile(TempFileName, TempFileNameForExchange);
				
				StructureOfData.TempExchangeMessagesDirectoryName = TempDirectoryNameForExchange;
				StructureOfData.DataPackageFileID       = DataPackageFileID;
				StructureOfData.ExchangeMessageFileName              = TempFileNameForExchange;
				
				Parameters.TempDirectoryIDForExchange   = String(DirectoryIDForExchange);
			Else
				DataExchangeInternal.PutMessageForDataMapping(Parameters.InfobaseNode, Undefined);
			EndIf;
			
		EndIf;
		
		If IsBlankString(StructureOfData.ExchangeMessageFileName) Then
			// A message file for mapping is not found.
			Cancel = True;
			
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tìm thấy thông điệp để so sánh với tên định danh %1 theo đường dẫn %2.';
					|ru = 'Сообщение для сопоставления с идентификатором %1 не найдено по пути %2.';
					|en = 'A message to be mapped with ID %1 was not found by path %2.'; fa = 'A message to be mapped with ID %1 was not found by path %2.';
					|it = 'Messaggio per il confronto con l''identificativo %1 non trovato nel percorso %2.';
					|pl = 'Wiadomość do porównania z identyfikatorem %1 nie znaleziono ścieżki %2.';
					|tr = '%1 belirteciyle uyumlama için mesaj%2 dizin yolunda bulunamadı.'"),
				String(CommonSettings.MessageForDataMapping),
				TempFileName);
			
			Parameters.Insert("ErrorMessage", ErrorMessage);
		EndIf;
	
	Else
		
		InitializationParameters = ExchangeMessagesTransport.InitializationParameters();
		InitializationParameters.Peer = Parameters.InfobaseNode;
		FillPropertyValues(InitializationParameters, Parameters);
		
		Transport = ExchangeMessagesTransport.Initialize(InitializationParameters);
		
		If Transport.GetData() Then
			StructureOfData.ExchangeMessageFileName = Transport.ExchangeMessage;
			StructureOfData.TempExchangeMessagesDirectoryName = Transport.TempDirectory;
			
			File = New File(Transport.ExchangeMessage);
			If File.Exists() Then
				StructureOfData.DataPackageFileID = File.GetModificationTime();
			EndIf;
			
		Else
			
			Cancel = True;
		
		EndIf;
		
	EndIf;
	
	Parameters.Cancel                                = Cancel;
	Parameters.TempExchangeMessagesDirectoryName = StructureOfData.TempExchangeMessagesDirectoryName;
	Parameters.DataPackageFileID       = StructureOfData.DataPackageFileID;
	Parameters.ExchangeMessageFileName              = StructureOfData.ExchangeMessageFileName;
	
	PutToTempStorage(Parameters, TempStorageAddress);
	
EndProcedure

// Imports data into the infobase for StatisticsInformation table rows.
// If all exchange message data is imported, the incoming exchange message
// number is stored in the exchange node.
// It implies that all data is imported to the infobase.
// The repeat import of this message will be canceled.
//
Procedure RunDataImport(Parameters, TempStorageAddress) Export
	
	DataExchangeParameters = DataExchangeServer.DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.InfobaseNode        = Parameters.InfobaseNode;
	DataExchangeParameters.FullNameOfExchangeMessageFile = Parameters.ExchangeMessageFileName;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataImport;
	
	DataExchangeServer.ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
EndProcedure

// For internal use.
// It exports data and is called by a background job.
// Parameters - a structure with parameters to pass.
//
Procedure RunDataExport(Parameters, TempStorageAddress) Export
	
	Cancel = False;
	
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	ExchangeParameters.ExecuteImport1            = False;
	ExchangeParameters.ExecuteExport2            = True;
	ExchangeParameters.TimeConsumingOperationAllowed  = True;
	ExchangeParameters.TransportID      = Parameters.TransportID;
	ExchangeParameters.TimeConsumingOperation           = Parameters.TimeConsumingOperation;
	ExchangeParameters.OperationID        = Parameters.OperationID;
	ExchangeParameters.FileID           = Parameters.FileID;
	ExchangeParameters.AuthenticationData         = Parameters.AuthenticationData;
	
	DataExchangeServer.ExecuteDataExchangeForInfobaseNode(Parameters.InfobaseNode, ExchangeParameters, Cancel);
	
	Parameters.TimeConsumingOperation      = ExchangeParameters.TimeConsumingOperation;
	Parameters.OperationID   = ExchangeParameters.OperationID;
	Parameters.FileID      = ExchangeParameters.FileID;
	Parameters.AuthenticationData    = ExchangeParameters.AuthenticationData;
	
	Parameters.Cancel                   = Cancel;
	
	PutToTempStorage(Parameters, TempStorageAddress);
	
EndProcedure

// For internal use.
// 
// Parameters:
//  StatisticsInformation - ValueTable 
// 
// Returns:
//  Boolean - All data is mapped
//
Function AllDataMapped(StatisticsInformation) Export
	
	Return (StatisticsInformation.FindRows(New Structure("PictureIndex", 1)).Count() = 0);
	
EndFunction

// For internal use.
// 
// Parameters:
//  StatisticsInformation - ValueTable 
// 
// Returns:
//  Boolean - Unmapped master data found
//
Function HasUnmappedMasterData(StatisticsInformation) Export
	Return (StatisticsInformation.FindRows(New Structure("PictureIndex, IsMasterData", 1, True)).Count() > 0);
EndFunction

#Region DataRegistration

Procedure OnStartRecordData(RegistrationSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Ghi nhận dữ liệu để kết xuất (%1)';
			|ru = 'Регистрация данных для выгрузки (%1)';
			|en = 'Register data for export (%1)'; fa = 'Register data for export (%1)';
			|it = 'Registrazione dei dati per upload (%1)';
			|pl = 'Rejestracja danych do pobierania (%1)';
			|tr = 'Dışa aktarılacak verilerin kaydı (%1)'"),
		RegistrationSettings.ExchangeNode);

	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang thực hiện ghi nhận dữ liệu để kết xuất ban đầu đối với ""%1"".';
				|ru = 'Регистрация данных для начальной выгрузки для ""%1"" уже выполняется.';
				|en = 'Data registration for initial export to ""%1"" is already running.'; fa = 'Data registration for initial export to ""%1"" is already running.';
				|it = 'La registrazione dei dati per upload iniziale per ""%1"" è già in corso.';
				|pl = 'Rejestracja danych dla początkowego ładowania dla ""%1"" jest już wykonywane.';
				|tr = '""%1"" için dışa aktarılacak ilk veriler zaten kaydediliyor.'"),
			RegistrationSettings.ExchangeNode);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("RegistrationSettings", RegistrationSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Ghi nhận dữ liệu để kết xuất (%1).';
			|ru = 'Регистрация данных для выгрузки (%1).';
			|en = 'Register data for export (%1).'; fa = 'Register data for export (%1).';
			|it = 'La registrazione dei dati per upload (%1).';
			|pl = 'Rejestracja danych do pobierania (%1).';
			|tr = 'Dışa aktarılacak verilerin kaydı (%1).'"),
		RegistrationSettings.ExchangeNode);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.InteractiveDataExchangeWizard.RegisterDataforExport",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

Procedure OnWaitForRecordData(HandlerParameters, ContinueWait = True) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

Procedure OnCompleteDataRecording(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region ExportMappingData

// For internal use.
//
Procedure OnStartExportDataForMapping(ExportSettings1, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kết xuất dữ liệu để so sánh (%1)';
			|ru = 'Выгрузка данных для сопоставления (%1)';
			|en = 'Export mapping data (%1)'; fa = 'Export mapping data (%1)';
			|it = 'Upload dei dati per riscontro (%1)';
			|pl = 'Pobieranie danych do porówniania (%1)';
			|tr = 'Karşılaştırılacak verileri dışa aktarma (%1)'"),
		ExportSettings1.ExchangeNode);

	ActiveBackgroundJobs = Undefined;
	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey, ActiveBackgroundJobs) Then
		FinishBackgroundTasks(BackgroundJobKey, ActiveBackgroundJobs);
	EndIf;
	
	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang thực hiện kết xuất dữ liệu để so sánh đối với ""%1"".';
				|ru = 'Выгрузка данных для сопоставления для ""%1"" уже выполняется.';
				|en = 'Data to map for ""%1"" is already being exported.'; fa = 'Data to map for ""%1"" is already being exported.';
				|it = 'Upload dei dati per associazione per ""%1"" è già in corso.';
				|pl = 'Ładowanie danych dla dopasowania dla ""%1"" jest już wykonywane.';
				|tr = '""%1"" karşılaştırılacak veriler zaten dışa aktarılıyor.'"),
			ExportSettings1.ExchangeNode);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ExportSettings1", ExportSettings1);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kết xuất dữ liệu để so sánh (%1).';
			|ru = 'Выгрузка данных для сопоставления (%1).';
			|en = 'Export mapping data (%1).'; fa = 'Export mapping data (%1).';
			|it = 'Upload dei dati per associazione (%1).';
			|pl = 'Pobieranie danych do porówniania (%1).';
			|tr = 'Karşılaştırılacak verileri dışa aktarma (%1).'"),
		ExportSettings1.ExchangeNode);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.InteractiveDataExchangeWizard.ExportDataForMapping",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteDataExportForMapping(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure RegisterDataforExport(Parameters, ResultAddress) Export
	
	RegistrationSettings = Undefined;
	Parameters.Property("RegistrationSettings", RegistrationSettings);
	
	Result = New Structure;
	Result.Insert("DataRegistered", True);
	Result.Insert("ErrorMessage",      "");
	
	StructureAddition = RegistrationSettings.ExportAddition;
	
	ExportAddition = DataProcessors.InteractiveExportChange.Create();
	FillPropertyValues(ExportAddition, StructureAddition, , "AdditionalRegistration, AdditionalNodeScenarioRegistration");
	
	ExportAddition.AllDocumentsFilterComposer.LoadSettings(StructureAddition.AllDocumentsSettingFilterComposer);
		
	DataExchangeServer.FillValueTable(ExportAddition.AdditionalRegistration, StructureAddition.AdditionalRegistration);
	DataExchangeServer.FillValueTable(ExportAddition.AdditionalNodeScenarioRegistration, StructureAddition.AdditionalNodeScenarioRegistration);
	
	If Not StructureAddition.AllDocumentsComposer = Undefined Then
		ExportAddition.AllDocumentsComposerAddress = PutToTempStorage(StructureAddition.AllDocumentsComposer);
	EndIf;
	
	// Saving export addition settings.
	DataExchangeServer.InteractiveExportChangeSaveSettings(ExportAddition, 
		DataExchangeServer.ExportAdditionSettingsAutoSavingName());
	
	// Register additional data.
	Try
		DataExchangeServer.InteractiveExportChangeRegisterAdditionalData(ExportAddition);
	Except
		Result.DataRegistered = False;
		
		Information = ErrorInfo();
		
		Result.ErrorMessage = NStr("vi = 'Xảy ra lỗi khi thêm dữ liệu để kết xuất:';
									|ru = 'Возникла проблема при добавлении данных к выгрузке:';
									|en = 'An issue occurred while adding data to export:'; fa = 'An issue occurred while adding data to export:';
									|it = 'Si è verificato un problema durante l''aggiunta di dati per upload:';
									|pl = 'Wystąpił problem podczas dodawania danych do ładowania:';
									|tr = 'Veriler dışa aktarmaya eklendiğinde bir sorun oluştu:'") 
			+ Chars.LF + ErrorProcessing.BriefErrorDescription(Information)
			+ Chars.LF + NStr("vi = 'Hãy thay đổi điều kiện lọc.';
								|ru = 'Измените условия отбора.';
								|en = 'Edit filter criteria.'; fa = 'Edit filter criteria.';
								|it = 'Modificare le condizioni di filtro.';
								|pl = 'Zmień warunki filtru.';
								|tr = 'Filtre koşullarını değiştirin'");
			
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure ExportDataForMapping(Parameters, ResultAddress) Export
	
	ExportSettings1 = Undefined;
	Parameters.Property("ExportSettings1", ExportSettings1);
	
	Result = New Structure;
	Result.Insert("DataExported1",   True);
	Result.Insert("ErrorMessage", "");
	
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	ExchangeParameters.ExecuteImport1 = False;
	ExchangeParameters.ExecuteExport2 = True;
	ExchangeParameters.TransportID = ExportSettings1.TransportID;
	ExchangeParameters.TransportSettings = ExportSettings1.TransportSettings;
	
	ExchangeParameters.MessageForDataMapping = True;
	
	If ExportSettings1.Property("AuthenticationData") Then
		ExchangeParameters.Insert("AuthenticationData", ExportSettings1.AuthenticationData);
	EndIf;
	
	Cancel = False;
	Try
		DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
			ExportSettings1.ExchangeNode, ExchangeParameters, Cancel);
	Except
		Result.DataExported1 = False;
		Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExportToMapEventLogEvent(),
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

// For internal use.
//
Procedure OnCompleteTimeConsumingOperation(HandlerParameters,
		CompletionStatus = Undefined)
	
	CompletionStatus = New Structure;
	CompletionStatus.Insert("Cancel",             False);
	CompletionStatus.Insert("ErrorMessage", "");
	CompletionStatus.Insert("Result",         Undefined);
	
	If HandlerParameters.Cancel Then
		FillPropertyValues(CompletionStatus, HandlerParameters, "Cancel, ErrorMessage");
	Else
		CompletionStatus.Result = GetFromTempStorage(HandlerParameters.ResultAddress);
	EndIf;
	
	HandlerParameters = Undefined;
		
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

Procedure FinishBackgroundTasks(BackgroundJobKey, ActiveBackgroundJobs)
	
	Pauses = New Array;
	Pauses.Add(1);
	Pauses.Add(5);
	Pauses.Add(10);
	
	Iteration = 0;
	
	For Each BackgroundJob In ActiveBackgroundJobs Do
		
		TimeConsumingOperations.CancelJobExecution(BackgroundJob.UUID);
		
		While DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) And Iteration < Pauses.Count() Do
			Pause = Pauses[Iteration];
			BackgroundJob.WaitForExecutionCompletion(Pause);
			Iteration = Iteration + 1;
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

// Analyzes the incoming exchange message. Fills in the StatisticsInformation table with data.
//
// Parameters:
//   Parameters - Structure
//   Cancel - Boolean - a cancellation flag. It is set to True if errors occur during the procedure execution.
//   ExchangeExecutionResult - EnumRef.ExchangeExecutionResults - data exchange result.
//
Function StatisticsTableExchangeMessages(Parameters,
		Cancel, ExchangeExecutionResult = Undefined, ErrorMessage = "")
		
	StatisticsInformation = Undefined; // ValueTable
	InitializeStatisticsTable(StatisticsInformation);
	
	TempExchangeMessagesDirectoryName = Parameters.TempExchangeMessagesDirectoryName;
	InfobaseNode               = Parameters.InfobaseNode;
	ExchangeMessageFileName              = Parameters.ExchangeMessageFileName;
	
	If IsBlankString(TempExchangeMessagesDirectoryName) Then
		// Data from the correspondent infobase cannot be received.
		Cancel = True;
		Return StatisticsInformation;
	EndIf;
	
	SetPrivilegedMode(True);
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsStructureForInteractiveImportSession(
		InfobaseNode, ExchangeMessageFileName);
	
	If ExchangeSettingsStructure.Cancel Then
		Return StatisticsInformation;
	EndIf;
	
	DataExchangeDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor;
	
	AnalysisParameters = New Structure("CollectClassifiersStatistics", True);	
	DataExchangeDataProcessor.ExecuteExchangeMessageAnalysis(AnalysisParameters);
	
	ExchangeExecutionResult = DataExchangeDataProcessor.ExchangeExecutionResult();
	
	If DataExchangeDataProcessor.ErrorFlag() Then
		Cancel = True;
		ErrorMessage = DataExchangeDataProcessor.ErrorMessageString();
		Return StatisticsInformation;
	EndIf;
	
	PackageHeaderDataTable = DataExchangeDataProcessor.PackageHeaderDataTable();
	For Each BatchTitleDataLine In PackageHeaderDataTable Do
		StatisticsInformationString = StatisticsInformation.Add();
		FillPropertyValues(StatisticsInformationString, BatchTitleDataLine);
	EndDo;
	
	// Supplying the statistic table with utility data
	ErrorMessage = "";
	SupplementStatisticTable(StatisticsInformation, Cancel, ErrorMessage);
	
	// Determining table strings with the OneToMany flag
	TempStatistics = StatisticsInformation.Copy(, "DestinationTableName, IsObjectDeletion");
	
	AddColumnWithValueToTable(TempStatistics, 1, "Iterator_SSLy");
	
	TempStatistics.GroupBy("DestinationTableName, IsObjectDeletion", "Iterator_SSLy");
	
	For Each TableRow In TempStatistics Do
		
		If TableRow.Iterator_SSLy > 1 And Not TableRow.IsObjectDeletion Then
			
			StatisticsInformationRows = StatisticsInformation.FindRows(New Structure("DestinationTableName, IsObjectDeletion",
				TableRow.DestinationTableName, TableRow.IsObjectDeletion));
			
			For Each StatisticsInformationString In StatisticsInformationRows Do
				
				StatisticsInformationString["OneToMany"] = True;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return StatisticsInformation;
	
EndFunction

// For internal use.
//
Function AutomaticDataMappingResult(Val Peer,
		Val ExchangeMessageFileName, Val TempExchangeMessagesDirectoryName, CheckVersionDifference)
		
	Result = New Structure;
	Result.Insert("StatisticsInformation",      Undefined);
	Result.Insert("AllDataMapped",     True);
	Result.Insert("HasUnmappedMasterData",   False);
	Result.Insert("StatisticsBlank",          True);
	Result.Insert("Cancel",                     False);
	Result.Insert("ErrorMessage",         "");
	Result.Insert("ExchangeExecutionResult", Undefined);
	
	// Auto-map the data received from the peer infobase.
	// Gather the mapping statistics.
	SetPrivilegedMode(True);
	
	DataExchangeServer.InitializeVersionDifferenceCheckParameters(CheckVersionDifference);
	
	// Analyzing exchange messages.
	AnalysisParameters = New Structure;
	AnalysisParameters.Insert("TempExchangeMessagesDirectoryName", TempExchangeMessagesDirectoryName);
	AnalysisParameters.Insert("InfobaseNode",               Peer);
	AnalysisParameters.Insert("ExchangeMessageFileName",              ExchangeMessageFileName);
	
	StatisticsInformation = StatisticsTableExchangeMessages(AnalysisParameters,
		Result.Cancel, Result.ExchangeExecutionResult, Result.ErrorMessage);
	
	If Result.Cancel Then
		If SessionParameters.VersionDifferenceErrorOnGetData.HasError Then
			Return SessionParameters.VersionDifferenceErrorOnGetData;
		EndIf;
		
		Return Result;
	EndIf;
	
	InteractiveDataExchangeWizard = Create();
	InteractiveDataExchangeWizard.InfobaseNode = Peer;
	InteractiveDataExchangeWizard.ExchangeMessageFileName = ExchangeMessageFileName;
	InteractiveDataExchangeWizard.TempExchangeMessagesDirectoryName = TempExchangeMessagesDirectoryName;
	InteractiveDataExchangeWizard.ExchangePlanName = DataExchangeCached.GetExchangePlanName(Peer);
	InteractiveDataExchangeWizard.TransportID = "";
	
	InteractiveDataExchangeWizard.StatisticsInformation.Load(StatisticsInformation);
	
	// Mapping data and getting statistics.
	InteractiveDataExchangeWizard.ExecuteDefaultAutomaticMappingAndGetMappingStatistics(Result.Cancel);
	
	If Result.Cancel Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nhập dữ liệu từ ""%1"" (giai đoạn tự động so sánh dữ liệu).';
				|ru = 'Не удалось загрузить данные из ""%1"" (этап автоматического сопоставления данных).';
				|en = 'Cannot import data from ""%1"" (automatic data mapping step).'; fa = 'Cannot import data from ""%1"" (automatic data mapping step).';
				|it = 'Impossibile caricare i dati da ""%1"" (passaggio automatico per associazione dei dati).';
				|pl = 'Nie udało się pobrać dane z ""%1"" (etap automatycznego dopasowania danych).';
				|tr = 'Veriler ""%1"" (otomatik veri eşlenme adımı) ''dan içe aktarılamıyor.'"),
			String(Peer));
	EndIf;
	
	StatisticsTable = InteractiveDataExchangeWizard.StatisticsTable();
	
	Result.StatisticsInformation    = StatisticsTable;
	Result.AllDataMapped   = AllDataMapped(StatisticsTable);
	Result.StatisticsBlank        = (StatisticsTable.Count() = 0);
	Result.HasUnmappedMasterData = HasUnmappedMasterData(StatisticsTable);
	
	Return Result;
	
EndFunction

Procedure InitializeStatisticsTable(StatisticsTable1)
	
	StatisticsTable1 = New ValueTable;
	StatisticsTable1.Columns.Add("DataImportedSuccessfully", New TypeDescription("Boolean"));
	StatisticsTable1.Columns.Add("DestinationTableName", New TypeDescription("String"));
	StatisticsTable1.Columns.Add("PictureIndex", New TypeDescription("Number"));
	StatisticsTable1.Columns.Add("UsePreview", New TypeDescription("Boolean"));
	StatisticsTable1.Columns.Add("Key", New TypeDescription("String"));
	StatisticsTable1.Columns.Add("ObjectCountInSource", New TypeDescription("Number"));
	StatisticsTable1.Columns.Add("ObjectCountInDestination", New TypeDescription("Number"));
	StatisticsTable1.Columns.Add("UnmappedObjectsCount", New TypeDescription("Number"));
	StatisticsTable1.Columns.Add("MappedObjectCount", New TypeDescription("Number"));
	StatisticsTable1.Columns.Add("OneToMany", New TypeDescription("Boolean"));
	StatisticsTable1.Columns.Add("SearchFields", New TypeDescription("String"));
	StatisticsTable1.Columns.Add("TableFields", New TypeDescription("String"));
	StatisticsTable1.Columns.Add("Presentation", New TypeDescription("String"));
	StatisticsTable1.Columns.Add("MappedObjectPercentage", New TypeDescription("Number"));
	StatisticsTable1.Columns.Add("SynchronizeByID", New TypeDescription("Boolean"));
	StatisticsTable1.Columns.Add("SourceTypeString", New TypeDescription("String"));
	StatisticsTable1.Columns.Add("ObjectTypeString", New TypeDescription("String"));
	StatisticsTable1.Columns.Add("DestinationTypeString", New TypeDescription("String"));
	StatisticsTable1.Columns.Add("IsClassifier", New TypeDescription("Boolean"));
	StatisticsTable1.Columns.Add("IsObjectDeletion", New TypeDescription("Boolean"));
	StatisticsTable1.Columns.Add("IsMasterData", New TypeDescription("Boolean"));
	
EndProcedure

Procedure SupplementStatisticTable(StatisticsInformation, Cancel, ErrorMessage = "")
	
	For Each TableRow In StatisticsInformation Do
		
		Try
			Type = Type(TableRow.ObjectTypeString);
		Except
			Cancel = True;
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi: kiểu ""%1"" không xác định.';
					|ru = 'Ошибка: тип ""%1"" не определен.';
					|en = 'Error: the %1 type is not defined.'; fa = 'Error: the %1 type is not defined.';
					|it = 'Errore: il tipo ""%1"" non è definito.';
					|pl = 'Błąd: rodzaj ""%1"" nie został określony.';
					|tr = 'Hata: ""%1"" tipi tanımlanmamış.'"), TableRow.ObjectTypeString);
			Break;
		EndTry;
		
		ObjectMetadata = Metadata.FindByType(Type);
		
		TableRow.DestinationTableName = ObjectMetadata.FullName();
		TableRow.Presentation       = ObjectMetadata.Presentation();
		
		TableRow.Key = String(New UUID);
		
	EndDo;
	
EndProcedure

// Parameters:
//   Table - ValueTable
//   IteratorValue - Number
//   IteratorFieldName - String
//
Procedure AddColumnWithValueToTable(Table, IteratorValue, IteratorFieldName)
	
	Table.Columns.Add(IteratorFieldName);
	
	Table.FillValues(IteratorValue, IteratorFieldName);
	
EndProcedure

#EndRegion

#EndIf

