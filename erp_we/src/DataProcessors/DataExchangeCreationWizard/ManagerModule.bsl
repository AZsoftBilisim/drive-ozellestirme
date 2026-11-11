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
Procedure ExportConnectionSettingsForSubordinateDIBNode(ConnectionSettings) Export
	
	SetPrivilegedMode(True);
	
	JSONText = "";
	Try
		JSONText = ExchangeMessagesTransport.ConnectionSettingsINJSON(ConnectionSettings);
	Except
		Raise;
	EndTry;
		
	Constants.SubordinateDIBNodeSettings.Set(JSONText);
	
	ExchangePlans.RecordChanges(ConnectionSettings.InfobaseNode,
		Metadata.Constants.SubordinateDIBNodeSettings);
	
EndProcedure

#Region CheckConnectionToCorrespondent

// For internal use.
//
Procedure OnStartTestConnection(ConnectionSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = DataExchangeServer.BackgroundJobKey(ConnectionSettings.ExchangePlanName,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kiểm tra kết nối %1';
				|ru = 'Проверка подключения %1';
				|en = 'Checking connection %1'; fa = 'Checking connection %1';
				|it = 'Controllo della connessione %1';
				|pl = 'Weryfikacja połączenia %1';
				|tr = 'Bağlantı kontrolü %1'"), ConnectionSettings.TransportID));

	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang kiểm tra kết nối %1.';
				|ru = 'Проверка подключения %1 уже выполняется.';
				|en = '%1 connection check is already in progress.'; fa = '%1 connection check is already in progress.';
				|it = 'Controllo della connessione %1 è già in corso.';
				|pl = 'Weryfikacja połączenia %1 jest już w toku.';
				|tr = '%1 bağlantısının kontrolü zaten devam ediyor.'"), ConnectionSettings.TransportID);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ConnectionSettings", ConnectionSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kiểm tra kết nối đến cơ sở trao đổi tin: %1.';
			|ru = 'Проверка подключения к корреспонденту: %1.';
			|en = 'Check connection to peer: %1.'; fa = 'Check connection to peer: %1.';
			|it = 'Controllo della connessione al corrispondente: %1.';
			|pl = 'Weryfikacja połączenia do korespondenta: %1.';
			|tr = 'Muhabir ile bağlantı kontrolü: %1.'"), ConnectionSettings.TransportID);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.TestCorrespondentConnection",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

Procedure OnWaitForTestConnection(HandlerParameters, ContinueWait = True) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

Procedure OnCompleteConnectionTest(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region SaveSynchronizationSettings

// For internal use.
//
Procedure OnStartSaveSynchronizationSettings(SynchronizationSettings, HandlerParameters, ContinueWait = True) Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(SynchronizationSettings.ExchangeNode);
	
	BackgroundJobKey = DataExchangeServer.BackgroundJobKey(ExchangePlanName,
		NStr("vi = 'Lưu lại tùy chỉnh đồng bộ dữ liệu';
			|ru = 'Сохранение настроек синхронизации данных';
			|en = 'Save data synchronization settings'; fa = 'Save data synchronization settings';
			|it = 'Salvataggio delle configurazioni di sincronizzazione dei dati';
			|pl = 'Zapisywanie ustawień synchronizacji danych';
			|tr = 'Veri eşleşme ayarlarının kaydı'"));

	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang lưu lại tùy chỉnh đồng bộ dữ liệu đối với ""%1"".';
				|ru = 'Сохранение настроек синхронизации данных для ""%1"" уже выполняется.';
				|en = 'Saving data synchronization settings for ""%1"" is already in progress.'; fa = 'Saving data synchronization settings for ""%1"" is already in progress.';
				|it = 'Salvataggio delle configurazioni di sincronizzazione dei dati per ""%1"" è già in corso.';
				|pl = 'Zapisywanie ustawień synchronizacji danych dla ""%1"" jest już w toku.';
				|tr = '""%1"" için veri eşleşme ayarları zaten kaydediliyor.'"), ExchangePlanName);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("SynchronizationSettings", SynchronizationSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lưu lại tùy chỉnh đồng bộ dữ liệu: %1.';
			|ru = 'Сохранение настроек синхронизации данных: %1.';
			|en = 'Save data synchronization settings: %1'; fa = 'Save data synchronization settings: %1';
			|it = 'Salvataggio delle configurazioni di sincronizzazione dei dati: %1.';
			|pl = 'Zapisywanie ustawień synchronizacji danych: %1.';
			|tr = 'Veri eşleşme ayarlarının kaydı: %1.'"), ExchangePlanName);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.SaveSynchronizationSettings1",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForSaveSynchronizationSettings(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteSaveSynchronizationSettings(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region DeleteDataSynchronizationSetting

// For internal use.
//
Procedure OnStartDeleteSynchronizationSettings(DeletionSettings, HandlerParameters, ContinueWait = True) Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(DeletionSettings.ExchangeNode);
	
	BackgroundJobKey = DataExchangeServer.BackgroundJobKey(ExchangePlanName,
		NStr("vi = 'Xóa tùy chỉnh đồng bộ dữ liệu';
			|ru = 'Удаление настройки синхронизации данных';
			|en = 'Delete data synchronization settings'; fa = 'Delete data synchronization settings';
			|it = 'Eliminazione della configurazione di sincronizzazione dei dati';
			|pl = 'Usuwanie ustawienia synchronizacji danych';
			|tr = 'Veri eşleşme ayarını kaldır'"));

	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang xóa tùy chỉnh đồng bộ dữ liệu đối với ""%1"".';
				|ru = 'Удаление настройки синхронизации данных для ""%1"" уже выполняется.';
				|en = 'Deletion of data synchronization settings for ""%1"" is already in progress.'; fa = 'Deletion of data synchronization settings for ""%1"" is already in progress.';
				|it = 'Eliminazione della configurazione di sincronizzazione dei dati per ""%1"" è già in corso.';
				|pl = 'Usuwanie ustawienia synchronizacji danych dla ""%1"" jest już w toku.';
				|tr = '""%1"" için veri eşleşme ayarları zaten kaldırılıyor.'"), ExchangePlanName);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("DeletionSettings", DeletionSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Xóa tùy chỉnh đồng bộ dữ liệu: %1.';
			|ru = 'Удаление настройки синхронизации данных: %1.';
			|en = 'Delete data synchronization settings: %1'; fa = 'Delete data synchronization settings: %1';
			|it = 'Eliminazione della configurazione di sincronizzazione dei dati per ""%1"".';
			|pl = 'Usuwanie ustawienia synchronizacji danych: %1.';
			|tr = 'Veri eşleşme ayarını kaldır:%1'"), ExchangePlanName);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.DeleteSynchronizationSetting",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForDeleteSynchronizationSettings(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteSynchronizationSettingsDeletion(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region DataRegistrationForInitialExport

// For internal use.
//
Procedure OnStartRecordDataForInitialExport(RegistrationSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Ghi nhận dữ liệu để kết xuất ban đầu (%1)';
			|ru = 'Регистрация данных для начальной выгрузки (%1)';
			|en = 'Register data for initial export (%1)'; fa = 'Register data for initial export (%1)';
			|it = 'La registrazione dei dati per upload iniziale (%1)';
			|pl = 'Rejestracja danych dla początkowego ładowania (%1)';
			|tr = 'Dışa aktarılacak ilk verilerin kaydı (%1)'"),
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
		NStr("vi = 'Ghi nhận dữ liệu để kết xuất ban đầu (%1).';
			|ru = 'Регистрация данных для начальной выгрузки (%1).';
			|en = 'Register data for initial export (%1)'; fa = 'Register data for initial export (%1)';
			|it = 'La registrazione dei dati per upload iniziale (%1).';
			|pl = 'Rejestracja danych dla początkowego ładowania (%1).';
			|tr = 'Dışa aktarılacak ilk verilerin kaydı (%1).'"),
		RegistrationSettings.ExchangeNode);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.RegisterDataForInitialExport",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForRecordDataForInitialExport(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteDataRecordingForInitialExport(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region XDTOSettingsImport

// For internal use.
//
Procedure OnStartImportXDTOSettings(ImportSettings, HandlerParameters, ContinueWait = True) Export
	
	BackgroundJobKey = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kết nhập tùy chỉnh XDTO (%1)';
			|ru = 'Загрузка настроек XDTO (%1)';
			|en = 'Import XDTO settings (%1)'; fa = 'Import XDTO settings (%1)';
			|it = 'Il download delle configurazioni XDTO (%1)';
			|pl = 'Pobieranie ustawień XDTO (%1)';
			|tr = 'XDTO ayarlarının içe aktarılması (%1)'"),
		ImportSettings.ExchangeNode);

	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang thực hiện kết nhập tùy chỉnh XDTO đối với ""%1"".';
				|ru = 'Загрузка настроек XDTO для ""%1"" уже выполняется.';
				|en = 'Import of XDTO settings for ""%1"" is already in progress.'; fa = 'Import of XDTO settings for ""%1"" is already in progress.';
				|it = 'Il download delle configurazioni XDTO per ""%1"" è già in corso.';
				|pl = 'Pobieranie ustawień XDTO  dla ""%1"" jest już w toku.';
				|tr = '""%1"" için XDTO ayarları zaten içe aktarılıyor.'"),
			ImportSettings.ExchangeNode);
	EndIf;
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ImportSettings", ImportSettings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kết nhập tùy chỉnh XDTO (%1).';
			|ru = 'Загрузка настроек XDTO (%1).';
			|en = 'Import XDTO settings (%1)'; fa = 'Import XDTO settings (%1)';
			|it = 'Il download delle configurazioni XDTO (%1).';
			|pl = 'Pobieranie ustawień XDTO (%1).';
			|tr = 'XDTO ayarlarının içe aktarılması (%1).'"),
		ImportSettings.ExchangeNode);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeCreationWizard.ImportXDTOCorrespondentSettings",
		ProcedureParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnWaitForImportXDTOSettings(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure OnCompleteImportXDTOSettings(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

#EndRegion

#Region MigrationToWebService

Procedure ChangeNodeTransportInWS(Node, Endpoint, CorrespondentDataArea) Export
	
	TransportSettings = New Structure; 
	TransportSettings.Insert("InternalPublication", True);
	TransportSettings.Insert("Endpoint", "");
	TransportSettings.Insert("CorrespondentEndpoint", Endpoint);
	TransportSettings.Insert("PeerInfobaseName", "");
	TransportSettings.Insert("CorrespondentDataArea", CorrespondentDataArea);
	
	Try
		
		ExchangeMessagesTransport.SaveTransportSettings(Node, "SM", TransportSettings, True);
		
		RecordStructure = New Structure("Peer", Node);
		DataExchangeInternal.DeleteRecordSetFromInformationRegister(RecordStructure,"DataAreaExchangeTransportSettings");
		
		JobSchedule = Catalogs.DataExchangeScenarios.DefaultJobSchedule();
		Catalogs.DataExchangeScenarios.CreateScenario(Node, JobSchedule, True);
			
	Except
		
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeWebService.EventLogEventTransportChangedOnWS(),
			EventLogLevel.Error, , , ErrorMessage);
		
		Raise ErrorMessage;
		
	EndTry;
		
EndProcedure

Procedure ChangeTransportOfPeerNodeOnWS(Node, Endpoint, CorrespondentEndpoint, DataArea) Export
		
	SetPrivilegedMode(True);
	
	ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
	TransportSettingsWS = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(CorrespondentEndpoint);
	
	ExchangePlanName = Node.Metadata().Name;
	EndpointCode = Common.ObjectAttributeValue(Endpoint,"Code");
	
	SetPrivilegedMode(False);
	
	Try
		
		InterfaceVersions = DataExchangeCached.CorrespondentVersions(TransportSettingsWS);
		
	Except
		
		ErrorMessageInCorrespondent = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessageInCorrespondent);
		
		Raise ErrorMessageInCorrespondent;
		
	EndTry;

	ErrorMessage = "";
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("WebServiceAddress", TransportSettingsWS.WSWebServiceURL);
	ConnectionParameters.Insert("UserName", TransportSettingsWS.WSUserName);
	ConnectionParameters.Insert("Password", TransportSettingsWS.WSPassword);
	
	Proxy = DataExchangeWebService.WSProxy(ConnectionParameters, ErrorMessage);
	
	CorrespondentNodeCode = DataExchangeCached.GetThisNodeCodeForExchangePlan(ExchangePlanName);
	CorrespondentDataArea = SessionParameters["DataAreaValue"];
	
	Parameters = New Structure;
	Parameters.Insert("ExchangePlanName", ExchangePlanName);
	Parameters.Insert("CorrespondentNodeCode", CorrespondentNodeCode);
	Parameters.Insert("CorrespondentEndpoint", EndpointCode);
	Parameters.Insert("CorrespondentDataArea", CorrespondentDataArea);
	
	Try
		
		Proxy.ChangeNodeTransportToWSInt(XDTOSerializer.WriteXDTO(Parameters), DataArea);
		 
	Except
		
		ErrorMessageInCorrespondent = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessageInCorrespondent);
		
		Raise ErrorMessageInCorrespondent;
		
	EndTry;
		
EndProcedure

#EndRegion

#Region LoadingPriorityDataToSubordinateRIBNode

Procedure AtBeginningOfDownloadMessageExchangesDataWithUpdate(ImportParameters, HandlerParameters, ContinueWait = False) Export
	
	AtStartOfDataExchangeStartup(ImportParameters, HandlerParameters, "DataProcessors.DataExchangeCreationWizard.UploadPriorityDataToSubordinateRIBVNodeInBackground", ContinueWait);
		
EndProcedure   

// For internal use.
//
Procedure WhileWaitingForUpdateDataExchangeMessageToLoad(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure WhenDownloadIsCompleteMessageExchangesDataWithUpdate(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

Procedure UploadPriorityDataToSubordinateRIBVNodeInBackground(ImportParameters, StorageAddress) Export
	
	Result = InitializeResultOfOperation();

	Try
		ImportPriorityDataToSubordinateDIBNode(ImportParameters);
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorPresentation);

		Result.Cancel = True;
		Result.ErrorMessage = ErrorPresentation;
	EndTry;
	
	If ImportParameters.HasErrors Then
		Result.Cancel = True;
		Result.ErrorMessage = NStr("vi = 'Khi thực hiện kết nhập dữ liệu để so sánh, đã xảy ra lỗi (xem Nhật ký sự kiện).';
									|ru = 'При выполнении загрузки данных возникли ошибки (см. Журнал регистрации).';
									|en = 'Errors occurred while importing data. See the event log.'; fa = 'Errors occurred while importing data. See the event log.';
									|it = 'Errors occurred while importing data. See the event log.';
									|pl = 'Errors occurred while importing data. See the event log.';
									|tr = 'Veri dışa aktarma işlemi esnasında hata oluştu (bkz. Olay Günlüğü).'")
	EndIf;
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

#EndRegion

#Region LoadingMessageBeforeUpdatingInformationBase

Procedure AtBeginningOfDownloadOfDataExchangeMessageWithoutUpdatingInfobase(ImportParameters, HandlerParameters, ContinueWait = False) Export
	
	AtStartOfDataExchangeStartup(ImportParameters, HandlerParameters, "DataProcessors.DataExchangeCreationWizard.UploadMessageBeforeUpdatingInformationBaseInBackground", ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure WhileWaitingForMessageToLoadBeforeUpdatingInformationBase(HandlerParameters, ContinueWait) Export
	
	OnWaitTimeConsumingOperation(HandlerParameters, ContinueWait);
	
EndProcedure

// For internal use.
//
Procedure UponCompletionOfMessageDownloadBeforeUpdatingInformationBase(HandlerParameters, CompletionStatus) Export
	
	OnCompleteTimeConsumingOperation(HandlerParameters, CompletionStatus);
	
EndProcedure

Procedure UploadMessageBeforeUpdatingInformationBaseInBackground(ProcedureParameters, StorageAddress) Export
	
	Result = InitializeResultOfOperation();
	
	Try
		ImportMessageBeforeInfobaseUpdate(ProcedureParameters);
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());

		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorPresentation);
		
		Result.Cancel = True;
		Result.ErrorMessage = ErrorPresentation;
	EndTry;
	
	If ProcedureParameters.HasErrors Then
		Result.Cancel = True;
		Result.ErrorMessage = NStr("vi = 'Khi thực hiện kết nhập dữ liệu để so sánh, đã xảy ra lỗi (xem Nhật ký sự kiện).';
									|ru = 'При выполнении загрузки данных возникли ошибки (см. Журнал регистрации).';
									|en = 'Errors occurred while importing data. See the event log.'; fa = 'Errors occurred while importing data. See the event log.';
									|it = 'Errors occurred while importing data. See the event log.';
									|pl = 'Errors occurred while importing data. See the event log.';
									|tr = 'Veri dışa aktarma işlemi esnasında hata oluştu (bkz. Olay Günlüğü).'");
	EndIf;
	
	PutToTempStorage(Result, StorageAddress);

	If Result.Cancel Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
	
	// If the message is imported, reimporting is not required.
	If Constants.LoadDataExchangeMessage.Get() Then
		Constants.LoadDataExchangeMessage.Set(False);
	EndIf;
	
	Constants.RetryDataExchangeMessageImportBeforeStart.Set(False);
	
	Try
		ExportMessageAfterInfobaseUpdate(ProcedureParameters);
	Except
		// If import fails, resume the startup and
		// run import in 1C:Enterprise mode.
		EventLogMessageKey = DataExchangeServer.DataExchangeEventLogEvent();
		
		WriteLogEvent(EventLogMessageKey,
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

Function DataExchangeSettingsFormatVersion() Export
	
	Return "1.2";
	
EndFunction

// For internal use.
//
Procedure OnStartGetDataExchangeSettingOptions(UUID, HandlerParameters, ContinueWait) Export
	
	StandardSettingsTable = Undefined;
	OnGetAvailableDataSynchronizationSettings(StandardSettingsTable, HandlerParameters);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("ResultAddressDefaultSettings", PutToTempStorage(StandardSettingsTable, UUID));
	
	If Common.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
		ContinueWait = True;
		
		SettingVariants = ExternalSystemsDataExchangeSettingsOptionDetails();
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("SettingVariants", SettingVariants);
		ProcedureParameters.Insert("ExchangeNode",       Undefined);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Nhận phương án tùy chỉnh trao đổi dữ liệu hợp lệ với các hệ thống ngoài.';
															|ru = 'Получение доступных вариантов настроек обмена данными с внешними системами.';
															|en = 'Get available setup options for data exchange with external systems'; fa = 'Get available setup options for data exchange with external systems';
															|it = 'Ricezione delle varianti disponibili delle impostazioni dello scambio di dati con sistemi esterni.';
															|pl = 'Uzyskiwanie dostępnych opcji ustawiania wymiany danych z systemami zewnętrznymi.';
															|tr = 'Harici sistemlerle veri alışverişi ayarları için mevcut seçeneklerin alınması.'");
		ExecutionParameters.WaitCompletion = 0;
		
		BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
			"DataExchangeWithExternalSystems.OnGetDataExchangeSettingsOptions",
			ProcedureParameters,
			ExecutionParameters);
			
		HandlerParameterExternalSystems = Undefined;	
		OnStartTimeConsumingOperation(BackgroundJob, HandlerParameterExternalSystems, ContinueWait);
		
		HandlerParameters.Insert("HandlerParameterExternalSystems", HandlerParameterExternalSystems);
		
	EndIf;
	
EndProcedure

// For internal use.
//
Procedure OnWaitForGetDataExchangeSettingOptions(HandlerParameters, ContinueWait) Export
	
	If HandlerParameters.Property("HandlerParameterExternalSystems") Then
		OnWaitTimeConsumingOperation(HandlerParameters.HandlerParameterExternalSystems, ContinueWait);
	Else
		ContinueWait = False;
	EndIf;
	
EndProcedure

// For internal use.
//
// Parameters:
//   HandlerParameters - Structure - Long-running operation parameters.
//   Result - Structure:
//   * SettingsExternalSystems - Structure:
//                    * ErrorCode - String -
//                    * ErrorMessage - String -
//                    * SettingVariants - ValueTable -
// 
Procedure OnCompleteGettingDataExchangeSettingsOptions(HandlerParameters, Result) Export
	
	Result = New Structure;
	Result.Insert("ExchangeDefaultSettings", GetFromTempStorage(HandlerParameters.ResultAddressDefaultSettings));
	
	If HandlerParameters.Property("HandlerParameterExternalSystems") Then
		
		SettingsExternalSystems = New Structure;
		SettingsExternalSystems.Insert("ErrorCode"); // SettingsReceived, NoSettings, Error, OnlineSupportNotConnected
		SettingsExternalSystems.Insert("ErrorMessage");
		SettingsExternalSystems.Insert("SettingVariants");
		
		CompletionStatusExternalSystems = Undefined;
		OnCompleteTimeConsumingOperation(HandlerParameters.HandlerParameterExternalSystems, CompletionStatusExternalSystems);
		
		If CompletionStatusExternalSystems.Cancel Then
			SettingsExternalSystems.ErrorCode = "BackgroundJobError";
			SettingsExternalSystems.ErrorMessage = CompletionStatusExternalSystems.ErrorMessage;
		Else
			FillPropertyValues(SettingsExternalSystems, CompletionStatusExternalSystems.Result);
		EndIf;
		
		Result.Insert("SettingsExternalSystems", SettingsExternalSystems);
		
	EndIf;
	
EndProcedure

Function ExternalSystemsDataExchangeSettingsOptionDetails() Export
	
	SettingVariants = New ValueTable;
	SettingVariants.Columns.Add("ExchangePlanName",                                 New TypeDescription("String"));
	SettingVariants.Columns.Add("SettingID",                         New TypeDescription("String"));
	SettingVariants.Columns.Add("NewDataExchangeCreationCommandTitle", New TypeDescription("String"));
	SettingVariants.Columns.Add("BriefExchangeInfo",                      New TypeDescription("FormattedString"));
	SettingVariants.Columns.Add("DetailedExchangeInformation",                    New TypeDescription("String"));
	SettingVariants.Columns.Add("ExchangeCreateWizardTitle",               New TypeDescription("String"));
	SettingVariants.Columns.Add("PeerInfobaseName",                     New TypeDescription("String"));
	SettingVariants.Columns.Add("ConnectionParameters");
	
	Return SettingVariants;
	
EndFunction

Function SettingOptionDetailsStructure() Export
	
	SettingOptionDetails = New Structure;
	SettingOptionDetails.Insert("NewDataExchangeCreationCommandTitle", "");
	SettingOptionDetails.Insert("BriefExchangeInfo", New FormattedString(""));
	SettingOptionDetails.Insert("DetailedExchangeInformation", "");
	SettingOptionDetails.Insert("ExchangeCreateWizardTitle", "");
	SettingOptionDetails.Insert("PeerInfobaseName", "");
	
	Return SettingOptionDetails;
	
EndFunction

Procedure ConfigureDataExchange(ConnectionSettings) Export
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		
		// Creating/updating the exchange plan node.
		CreateUpdateExchangePlanNodes(ConnectionSettings);
		
		// Loading message transport settings.
		If ValueIsFilled(ConnectionSettings.TransportID) Then
			
			ExchangeMessagesTransport.SaveTransportSettings(
				ConnectionSettings.InfobaseNode,
				ConnectionSettings.TransportID,
				ConnectionSettings.TransportSettings,
				True);
			
		EndIf;
		
		// Updating the infobase prefix constant value.
		If IsBlankString(GetFunctionalOption("InfobasePrefix"))
			And Not IsBlankString(ConnectionSettings.SourceInfobasePrefix) Then
			
			DataExchangeServer.SetInfobasePrefix(ConnectionSettings.SourceInfobasePrefix);
			
		EndIf;
		
		If DataExchangeCached.IsDistributedInfobaseExchangePlan(ConnectionSettings.ExchangePlanName)
			And ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup" Then
			
			Constants.SubordinateDIBNodeSetupCompleted.Set(True);
			Constants.UseDataSynchronization.Set(True);
			Constants.DoNotUseSeparationByDataAreas.Set(True);
			
			DataExchangeServer.SetDefaultDataImportTransactionItemsCount();
			
			// Importing rules as exchange rules are not migrated to DIB.
			DataExchangeServer.UpdateDataExchangeRules();
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure FillConnectionSettingsFromXMLString(
	ConnectionSettings, FileNameXMLString, IsFile = False, IsOnlineConnection = False, TransportID = "") Export
	
	If Not ValueIsFilled(TransportID) Then
		
		If StrFind(FileNameXMLString, "COM") Then
			TransportID = "COM";
		Else
			TransportID = "WS";
		EndIf;
		
	EndIf;
	
	ConnectionSettingsFromXML = ExchangeMessagesTransport.ConnectionSettingsFromXML(FileNameXMLString, TransportID);
	ExchangeMessagesTransport.CheckAndFillInXMLConnectionSettings(ConnectionSettings, ConnectionSettingsFromXML);
	
EndProcedure

#EndRegion

#Region Private

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
			WriteLogEvent(
				DataExchangeServer.DataExchangeEventLogEvent(), 
				EventLogLevel.Error,
				Metadata.DataProcessors.DataExchangeCreationWizard,
				,
				BackgroundJob.DetailErrorDescription);
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

#EndRegion

Procedure OnGetAvailableDataSynchronizationSettings(SettingsTable1, HandlerParameters)
	
	SettingsTable1 = New ValueTable;
	SettingsTable1.Columns.Add("ExchangePlanName",                                 New TypeDescription("String"));
	SettingsTable1.Columns.Add("SettingID",                         New TypeDescription("String"));
	SettingsTable1.Columns.Add("CorrespondentConfigurationName",                  New TypeDescription("String"));
	SettingsTable1.Columns.Add("CorrespondentConfigurationDescription",         New TypeDescription("String"));
	SettingsTable1.Columns.Add("NewDataExchangeCreationCommandTitle", New TypeDescription("String"));
	SettingsTable1.Columns.Add("ExchangeCreateWizardTitle",               New TypeDescription("String"));
	SettingsTable1.Columns.Add("BriefExchangeInfo",                      New TypeDescription("String"));
	SettingsTable1.Columns.Add("DetailedExchangeInformation",                    New TypeDescription("String"));
	SettingsTable1.Columns.Add("IsDIBExchangePlan",                               New TypeDescription("Boolean"));
	SettingsTable1.Columns.Add("IsXDTOExchangePlan",                              New TypeDescription("Boolean"));
	SettingsTable1.Columns.Add("ExchangePlanNameToMigrateToNewExchange",          New TypeDescription("String"));
	
	ExchangePlansList = ExchangePlansForSynchronizationSetup();
	
	For Each ExchangePlanName In ExchangePlansList Do
		
		FillTableWithExchangePlanSettingsOptions(SettingsTable1, HandlerParameters, ExchangePlanName);

	EndDo;
	
	DeleteObsoleteSettingsOptionsSaaS(SettingsTable1);
	
EndProcedure

Function ExchangePlansForSynchronizationSetup()
	
	ExchangePlansList = New Array;
	
	IsFullUser = Users.IsFullUser(, True);
	
	SaaSModel = Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable();
	
	If SaaSModel Then
		ModuleDataExchangeSaaSCached = Common.CommonModule("DataExchangeSaaSCached");
		ExchangePlansList = ModuleDataExchangeSaaSCached.DataSynchronizationExchangePlans();
	Else
		ExchangePlansList = DataExchangeCached.SSLExchangePlans();
	EndIf;
	
	For Indus = -ExchangePlansList.UBound() To 0 Do
		
		ExchangePlanName = ExchangePlansList[-Indus];
		
		If (Not IsFullUser
				And DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName))
			Or Not DataExchangeCached.ExchangePlanUsageAvailable(ExchangePlanName) Then
			// Creating a DIB exchange requires system administrator rights.
			ExchangePlansList.Delete(-Indus);
		EndIf;
		
	EndDo;
	
	Return ExchangePlansList;
	
EndFunction

Procedure FillTableWithExchangePlanSettingsOptions(SettingsTable1, HandlerParameters, ExchangePlanName)
	
	SelectionBySettingsOptions = Undefined;
	If HandlerParameters <> Undefined
			And ValueIsFilled(HandlerParameters.SelectionBySettingsOptions)Then
		SelectionBySettingsOptions = HandlerParameters.SelectionBySettingsOptions;
	EndIf;
	
	ExchangeSettings = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName,
		"ExchangeSettingsOptions, ExchangePlanNameToMigrateToNewExchange");
	
	For Each SettingsMode In ExchangeSettings.ExchangeSettingsOptions Do
		If SelectionBySettingsOptions <> Undefined
			And SelectionBySettingsOptions.FindByValue(SettingsMode.SettingID) = Undefined Then
			Continue;
		EndIf;
		
		PredefinedSetting = SettingsMode.SettingID;
		
		SettingsValuesForOption = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName,
			"UseDataExchangeCreationWizard,
			|CorrespondentConfigurationName,
			|CorrespondentConfigurationDescription,
			|NewDataExchangeCreationCommandTitle,
			|ExchangeCreateWizardTitle,
			|BriefExchangeInfo,
			|DetailedExchangeInformation",
			PredefinedSetting);
			
		If Not SettingsValuesForOption.UseDataExchangeCreationWizard Then
			Continue;
		EndIf;
		
		SettingString = SettingsTable1.Add();
		FillPropertyValues(SettingString, SettingsValuesForOption);
		
		SettingString.ExchangePlanName = ExchangePlanName;
		SettingString.SettingID = PredefinedSetting;
		SettingString.IsDIBExchangePlan  = DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName);
		SettingString.IsXDTOExchangePlan = DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName);
		SettingString.ExchangePlanNameToMigrateToNewExchange = ExchangeSettings.ExchangePlanNameToMigrateToNewExchange;
		
	EndDo;
	
EndProcedure

Procedure DeleteObsoleteSettingsOptionsSaaS(SettingsTable1)
	
	SaaSModel = Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable();
		
	If Not SaaSModel Then
		Return;
	EndIf;
	
	XTDOExchangePlans     = New Array;
	ObsoleteSettings = New Array;
	
	For Each SettingString In SettingsTable1 Do
		If SettingString.IsXDTOExchangePlan Then
			If XTDOExchangePlans.Find(SettingString.ExchangePlanName) = Undefined Then
				XTDOExchangePlans.Add(SettingString.ExchangePlanName);
			EndIf;
			Continue;
		EndIf;
		If Not ValueIsFilled(SettingString.ExchangePlanNameToMigrateToNewExchange) Then
			Continue;
		EndIf;
		ObsoleteSettings.Add(SettingString);
	EndDo;
	
	XDTOSettingsTable = SettingsTable1.Copy(New Structure("IsXDTOExchangePlan", True));
	
	SettingsForDelete = New Array;
	For Each SettingString In ObsoleteSettings Do
		For Each XTDOExchangePlan In XTDOExchangePlans Do
			SettingsMode = DataExchangeServer.ExchangeSetupOptionForCorrespondent(
				XTDOExchangePlan, SettingString.CorrespondentConfigurationName);
			If Not ValueIsFilled(SettingsMode) Then
				Continue;
			EndIf;
			XDTOSettings = XDTOSettingsTable.FindRows(New Structure("SettingID", SettingsMode));	
			If XDTOSettings.Count() > 0 Then
				SettingsForDelete.Add(SettingString);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	For Cnt = 1 To SettingsForDelete.Count() Do
		SettingsTable1.Delete(SettingsForDelete[Cnt - 1]);
	EndDo;
	
EndProcedure

Procedure TestCorrespondentConnection(Parameters, ResultAddress) Export
	
	CheckResult = New Structure;
	CheckResult.Insert("ConnectionIsSet", False);
	CheckResult.Insert("ConnectionAllowed",   False); 
	CheckResult.Insert("InterfaceVersions",       Undefined);
	CheckResult.Insert("ErrorMessage",      "");
	
	CheckResult.Insert("CorrespondentParametersReceived", False);
	CheckResult.Insert("CorrespondentParameters",         Undefined);
	
	CheckResult.Insert("ThisNodeExistsInPeerInfobase", False);
	CheckResult.Insert("ThisInfobaseHasPeerInfobaseNode", False);
	CheckResult.Insert("NodeToDelete", Undefined);
	
	CheckResult.Insert("CorrespondentExchangePlanName","");
	
	Transport = ExchangeMessagesTransport.Initialize(Parameters.ConnectionSettings);
	
	If Transport.ConnectionIsSet() Then
		
		CheckResult.ConnectionIsSet = True;
		CheckResult.ConnectionAllowed   = True;
		
	Else
		
		ErrorMessage = Transport.ErrorMessage;
		
	EndIf;
	
	PutToTempStorage(CheckResult, ResultAddress);
	
EndProcedure

Function SaveConnectionSettings1(ConnectionSettings) Export
		
	SetPrivilegedMode(True);
	
	Result = New Structure;
	Result.Insert("ConnectionSettingsSaved", False);
	Result.Insert("HasDataToMap",    False); // For offline transport only.
	Result.Insert("ExchangeNode",                    Undefined);
	Result.Insert("ErrorMessage",             "");
	Result.Insert("XMLConnectionSettingsString",  "");
	Result.Insert("JSONConnectionSettingsString", "");
	
	Cancel = False;
	
	FixDuplicateSynchronizationSettings(ConnectionSettings, Result, Cancel);
		
	If Cancel Then
		Return Result;
	EndIf;
	
	// Save the node and connection settings to the infobase.
	Try
		ConfigureDataExchange(ConnectionSettings);
	Except
		Cancel = True;
		Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , Result.ErrorMessage);
		Return Result;
	EndTry;
	
	// Save the connection settings on the peer infobase side for online connections,
	// or send a message with XDTO settings for offline connections.
	TransportID = ConnectionSettings.TransportID;
	TransportParameters = ExchangeMessagesTransport.TransportParameters(TransportID);

	If TransportParameters.DirectConnection Then
		
		Parameters = ExchangeMessagesTransport.InitializationParameters();
		Parameters.Peer = ConnectionSettings.InfobaseNode;
		FillPropertyValues(Parameters, ConnectionSettings); 
		
		Transport = ExchangeMessagesTransport.Initialize(Parameters);
		
		If Not Transport.SaveSettingsInCorrespondent(ConnectionSettings) Then
			Cancel = True;
			Result.ErrorMessage = Transport.ErrorMessage;
		EndIf;
		
	ElsIf Not DataExchangeCached.IsDistributedInfobaseExchangePlan(ConnectionSettings.ExchangePlanName) Then
		
		Result.XMLConnectionSettingsString = ExchangeMessagesTransport.ConnectionSettingsInXML(ConnectionSettings);
		Result.JSONConnectionSettingsString = ExchangeMessagesTransport.ConnectionSettingsINJSON(ConnectionSettings);
	
	EndIf;
		
	// Export for offline exchange via universal format
	If Not TransportParameters.DirectConnection Then
		If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
		
			If ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup" Then
				// Getting an exchange message with XDTO settings.
				ExchangeParameters = DataExchangeServer.ExchangeParameters();
				ExchangeParameters.ExecuteImport1 = True;
				ExchangeParameters.ExecuteExport2 = False;
				ExchangeParameters.TransportID = ConnectionSettings.TransportID;
				
				// Errors that occur when getting messages via the common channels are not critical.
				// It's acceptable if there's no exchange message at all.
				CancelReceipt = False;
				AdditionalParameters = New Structure;
				Try
					DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
						ConnectionSettings.InfobaseNode, ExchangeParameters, CancelReceipt, AdditionalParameters);
				Except
					// Avoiding exceptions is crucial for successfully saving the setting.
					// 
					Cancel = True; 
					Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
					
					WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
					EventLogLevel.Error, , , Result.ErrorMessage);
				EndTry;
				
				If AdditionalParameters.Property("DataReceivedForMapping") Then
					Result.HasDataToMap = AdditionalParameters.DataReceivedForMapping;
				EndIf;
			Else
				// Sending an exchange message with XDTO settings.
				ExchangeParameters = DataExchangeServer.ExchangeParameters();
				ExchangeParameters.ExecuteImport1 = False;
				ExchangeParameters.ExecuteExport2 = True;
				ExchangeParameters.TransportID = ConnectionSettings.TransportID;
				
				Try
					DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
						ConnectionSettings.InfobaseNode, ExchangeParameters, Cancel);
				Except
					Cancel = True;
					Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
					
					WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
						EventLogLevel.Error, , , Result.ErrorMessage);
				EndTry;
			EndIf;
			
		ElsIf Not DataExchangeCached.IsDistributedInfobaseExchangePlan(ConnectionSettings.ExchangePlanName)
			And Not DataExchangeCached.IsStandardDataExchangeNode(ConnectionSettings.ExchangePlanName) Then
			
			Parameters = ExchangeMessagesTransport.InitializationParameters(TransportID);
			Parameters.Peer = ConnectionSettings.InfobaseNode;
			FillPropertyValues(Parameters, ConnectionSettings); 
		
			Transport = ExchangeMessagesTransport.Initialize(Parameters);
			
			Result.HasDataToMap = Transport.GetData();
			
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		Result.ConnectionSettingsSaved = True;
		Result.ExchangeNode = ConnectionSettings.InfobaseNode;
	Else
		DataExchangeServer.DeleteSynchronizationSetting(ConnectionSettings.InfobaseNode);
		
		Result.ConnectionSettingsSaved = False;
		Result.ExchangeNode = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure FixDuplicateSynchronizationSettings(ConnectionSettings, Result, Cancel)

	If ConnectionSettings.FixDuplicateSynchronizationSettings Then
		
		ManagerExchangePlan = ExchangePlans[ConnectionSettings.ExchangePlanName];
		
		If ConnectionSettings.ThisNodeExistsInPeerInfobase Then
						
			BeginTransaction();
			Try
				
				ThisNode = ManagerExchangePlan.ThisNode();
				
				DataLock = New DataLock;
				
				DataLockItem = DataLock.Add("ExchangePlan." + ConnectionSettings.ExchangePlanName);
				DataLockItem.SetValue("Ref", ThisNode);
						
				DataLock.Lock();

				NewCode = String(New UUID);
				
				ExchangeNodeObject = ThisNode.GetObject();
				ExchangeNodeObject.Code = NewCode;
				ExchangeNodeObject.DataExchange.Load = True;
				ExchangeNodeObject.Write();
								
				ConnectionSettings.NodeCode = NewCode;
				ConnectionSettings.PredefinedNodeCode = NewCode;
				
				CommitTransaction();
				
			Except

				RollbackTransaction();
				
				Cancel = True;
				
				Information = ErrorInfo();
				Result.ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
							
				WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
					EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
				
			EndTry;
		
		EndIf;
		
		NodeRef1 = ManagerExchangePlan.FindByCode(ConnectionSettings.DestinationInfobaseID);
		TheNodeExistsInThisDatabase = Not NodeRef1.IsEmpty();
		
		If TheNodeExistsInThisDatabase And ConnectionSettings.ThisInfobaseHasPeerInfobaseNode Then
	
			Try
				
				DataExchangeServer.DeleteSynchronizationSetting(NodeRef1);
				
			Except
				
				Cancel = True;
				
				Information = ErrorInfo();
				Result.ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
					
				WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
					EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
					
			EndTry;
			
		EndIf;
				
	EndIf;
	
EndProcedure
	
Procedure ImportXDTOCorrespondentSettings(Parameters, ResultAddress) Export
	
	ImportSettings = Undefined;
	Parameters.Property("ImportSettings", ImportSettings);
	
	Result = New Structure;
	Result.Insert("SettingsImported",             True);
	Result.Insert("DataReceivedForMapping", False);
	Result.Insert("ErrorMessage",              "");
	
	// Getting an exchange message with XDTO settings.
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	ExchangeParameters.ExecuteImport1 = True;
	ExchangeParameters.ExecuteExport2 = False;
	ExchangeParameters.TransportID = ExchangeMessagesTransport.DefaultTransport(ImportSettings.ExchangeNode); 
	
	AdditionalParameters = New Structure;
	
	Cancel = False;
	Try
		DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
			ImportSettings.ExchangeNode, ExchangeParameters, Cancel, AdditionalParameters);
	Except
		Cancel = True;
		Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , Result.ErrorMessage);
	EndTry;
		
	If Cancel Then
		Result.SettingsImported = False; 
		If IsBlankString(Result.ErrorMessage) Then
			Result.ErrorMessage = NStr("vi = 'Không thể nhận tham số của cơ sở trao đổi tin.';
										|ru = 'Не удалось получить параметры корреспондента.';
										|en = 'Cannot get peer application parameters.'; fa = 'Cannot get peer application parameters.';
										|it = 'Impossibile ottenere i parametri del corrispondente.';
										|pl = 'Nie udało się uzyskać parametry korespondenta.';
										|tr = 'Muhabirin parametreleri alınamadı.'");
		EndIf;
	Else
		CorrespondentSettings = DataExchangeXDTOServer.SupportedPeerInfobaseFormatObjects(
			ImportSettings.ExchangeNode, "SendReceive");
		Result.SettingsImported = (CorrespondentSettings.Count() > 0);
		
		If Result.SettingsImported Then
			If AdditionalParameters.Property("DataReceivedForMapping") Then
				Result.DataReceivedForMapping = AdditionalParameters.DataReceivedForMapping;
			EndIf;
		EndIf;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure SaveSynchronizationSettings1(Parameters, ResultAddress) Export
	
	SynchronizationSettings = Undefined;
	Parameters.Property("SynchronizationSettings", SynchronizationSettings);
	
	Result = New Structure;
	Result.Insert("SettingsSaved", True);
	Result.Insert("ErrorMessage",  "");
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(SynchronizationSettings.ExchangeNode);
	
	If DataExchangeServer.HasExchangePlanManagerAlgorithm("OnSaveDataSynchronizationSettings", ExchangePlanName) Then
		BeginTransaction();
		Try
			Block = New DataLock;
		    LockItem = Block.Add(Common.TableNameByRef(SynchronizationSettings.ExchangeNode));
		    LockItem.SetValue("Ref", SynchronizationSettings.ExchangeNode);
		    Block.Lock();
			
			ObjectNode = SynchronizationSettings.ExchangeNode.GetObject(); // ExchangePlanObject
			ExchangePlans[ExchangePlanName].OnSaveDataSynchronizationSettings(ObjectNode,
				SynchronizationSettings.FillingData);
			ObjectNode.Write();
			
			If Not DataExchangeServer.SynchronizationSetupCompleted(SynchronizationSettings.ExchangeNode) Then
				DataExchangeServer.CompleteDataSynchronizationSetup(SynchronizationSettings.ExchangeNode);
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			Result.SettingsSaved = False;
			Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
				EventLogLevel.Error, , , Result.ErrorMessage);
		EndTry;
	Else
		If Not DataExchangeServer.SynchronizationSetupCompleted(SynchronizationSettings.ExchangeNode) Then
			DataExchangeServer.CompleteDataSynchronizationSetup(SynchronizationSettings.ExchangeNode);
		EndIf;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure DeleteSynchronizationSetting(Parameters, ResultAddress) Export
	
	DeletionSettings = Undefined;
	Parameters.Property("DeletionSettings", DeletionSettings);
	
	Result = New Structure;
	Result.Insert("SettingDeleted",                 True);
	Result.Insert("SettingDeletedInCorrespondent",  DeletionSettings.DeleteSettingItemInCorrespondent);
	Result.Insert("ErrorMessage",                "");
	Result.Insert("ErrorMessageInCorrespondent", "");
	
	// 1. Optional: Delete the sync setting in the peer application.
	If DeletionSettings.DeleteSettingItemInCorrespondent Then
		DeleteSynchronizationSettingInCorrespondent(DeletionSettings, Result);
		If Not Result.SettingDeletedInCorrespondent Then
			Result.SettingDeleted = False;
			Result.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi xóa tùy chỉnh đồng bộ trong chương trình ""%1"" đã xảy ra lỗi: %2
				|
				|Hãy thử xóa sau hoặc bỏ dấu hộp kiểm ""Xóa tùy chỉnh cả trong chương trình..."".';
				|ru = 'При удалении настройки синхронизации в программе ""%1"" возникла ошибка: %2.
				|
				|Попробуйте выполнить удаление позже, или снимите флажок ""Удалить настройку также в программе..."".';
				|en = 'Cannot delete the synchronization setting in %1: %2.
				|
				|Try to delete it later or clear the ""Also delete the setting in…"" check box.'; fa = 'Cannot delete the synchronization setting in %1: %2.
				|
				|Try to delete it later or clear the ""Also delete the setting in…"" check box.';
				|it = 'Si è verificato un errore durante l''eliminazione dell''impostazione di sincronizzazione nel programma ""%1"": %2.
				|
				| Provate a ripetere l''eliminazione più tardi o togliete il flag ""Eliminare l''impostazione anche nel programma..."".';
				|pl = 'Podczas usuwania ustawień synchronizacji w programie ""%1"" wystąpił błąd: %2.
				|
				| Spróbuj usunąć później lub usuń zaznaczenie pola „Usuń ustawienia również w programie...”.';
				|tr = '""%1"" uygulamasında senkronizasyon ayarları silinirken hata oluştu: %2.
				|
				|Silmeyi daha sonra deneyin veya ""... uygulamasında da ayarları silin"" işaretini kaldırın.'"),
				String(DeletionSettings.ExchangeNode),
				Result.ErrorMessageInCorrespondent);
				
			PutToTempStorage(Result, ResultAddress);
			Return;
		EndIf;
	EndIf;
	
	// 2. Delete the sync setting in this application.
	Try
		DataExchangeServer.DeleteSynchronizationSetting(DeletionSettings.ExchangeNode);
	Except
		Information = ErrorInfo();
		Result.SettingDeleted  = False;
		Result.ErrorMessage = ErrorProcessing.BriefErrorDescription(Information);
		
		WriteLogEvent(DataExchangeServer.DataExchangeDeletionEventLogEvent(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure DeleteSynchronizationSettingInCorrespondent(DeletionSettings, Result)
	
	SetPrivilegedMode(True);
	
	Parameters = ExchangeMessagesTransport.InitializationParameters();
	Parameters.Peer = DeletionSettings.ExchangeNode;
	Parameters.AuthenticationData = DeletionSettings.AuthenticationData;
	
	Transport = ExchangeMessagesTransport.Initialize(Parameters);
	
	If Not Transport.DeleteSynchronizationSettingInCorrespondent() Then
		
		Result.ErrorMessageInCorrespondent = Transport.ErrorMessage;
		Result.SettingDeletedInCorrespondent = False;
		
	EndIf;
	
EndProcedure

Procedure RegisterDataForInitialExport(Parameters, ResultAddress) Export
	
	RegistrationSettings = Undefined;
	Parameters.Property("RegistrationSettings", RegistrationSettings);
	
	Result = New Structure;
	Result.Insert("DataRegistered", True);
	Result.Insert("ErrorMessage",      "");
	
	ReceivedNo = Common.ObjectAttributeValue(RegistrationSettings.ExchangeNode, "ReceivedNo");
	
	Try
		DataExchangeServer.RegisterDataForInitialExport(RegistrationSettings.ExchangeNode, , ReceivedNo = 0);
	Except
		Result.DataRegistered = False;
		Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeServer.RegisterDataForInitialExportEventLogEvent(),
			EventLogLevel.Error, , , Result.ErrorMessage);
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Function NodeCode(ConnectionSettings)
	
	If ConnectionSettings.UsePrefixesForExchangeSettings
		Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings Then
		
		Return ConnectionSettings.SourceInfobasePrefix;
			
	Else
		
		Return ConnectionSettings.SourceInfobaseID;
		
	EndIf;
	
EndFunction

Function CorrespondentNodeCode(ConnectionSettings)
	
	If ConnectionSettings.UsePrefixesForExchangeSettings
		Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings Then
		
		Return ConnectionSettings.DestinationInfobasePrefix;
			
	Else
		
		Return ConnectionSettings.DestinationInfobaseID;
		
	EndIf;
	
EndFunction

Procedure CreateUpdateExchangePlanNodes(ConnectionSettings)
	
	ThisNodeCode  = NodeCode(ConnectionSettings);
	NewNodeCode = CorrespondentNodeCode(ConnectionSettings);
	RestoreExchangeSettings = TypeOf(ConnectionSettings) = Type("Structure") 
		And ConnectionSettings.Property("RestoreExchangeSettings")
		And StrFind(ConnectionSettings.RestoreExchangeSettings, "Restoring");
		
	ManagerExchangePlan = ExchangePlans[ConnectionSettings.ExchangePlanName]; // ExchangePlanManager
	
	// Refreshing predefined node code of this base if it is not filled in.
	ThisNode = ManagerExchangePlan.ThisNode();
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("ExchangePlan." + ConnectionSettings.ExchangePlanName);
		LockItem.SetValue("Ref", ThisNode);
		Block.Lock();
		
		ThisNodeProperties = Common.ObjectAttributesValues(ThisNode, "Code, Description");
		ThisNodeCodeInDatabase          = ThisNodeProperties.Code;
		ThisNodeDescriptionInBase = ThisNodeProperties.Description;
		
		UpdateCode          = False;
		UpdateDescription = False;
		
		If IsBlankString(ThisNodeCodeInDatabase) Then
			UpdateCode          = True;
			UpdateDescription = True;
		ElsIf ThisNodeCodeInDatabase <> ThisNodeCode Then
			If Not Common.DataSeparationEnabled()
				And Not DataExchangeServer.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName)
				And (ConnectionSettings.UsePrefixesForExchangeSettings
					Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings)
				And DataExchangeCached.ExchangePlanNodes(ConnectionSettings.ExchangePlanName).Count() = 0 Then
				
				UpdateCode = True;
				
			EndIf;
		EndIf;
			
		If RestoreExchangeSettings Then
			UpdateCode = True;
		EndIf;
		
		If Not UpdateDescription
			And Not Common.DataSeparationEnabled()
			And ThisNodeDescriptionInBase <> ConnectionSettings.ThisInfobaseDescription Then
			UpdateDescription = True;
		EndIf;
		
		If UpdateCode Or UpdateDescription Then
			ThisNodeObject = ThisNode.GetObject();
			If UpdateCode Then
				ThisNodeObject.Code = ThisNodeCode;
				ThisNodeCodeInDatabase  = ThisNodeCode;
			EndIf;
			If UpdateDescription Then
				ThisNodeObject.Description = ConnectionSettings.ThisInfobaseDescription;
			EndIf;
			ThisNodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
			ThisNodeObject.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	CreateNewNode = False;
	
	// Get the peer infobase's node.
	If DataExchangeCached.IsDistributedInfobaseExchangePlan(ConnectionSettings.ExchangePlanName)
		And ConnectionSettings.WizardRunOption = "ContinueDataExchangeSetup" Then
		
		MasterNode = DataExchangeServer.MasterNode();
		
		If MasterNode = Undefined Then
			
			Raise NStr("vi = 'Không xác định nút chính đối với cơ sở thông tin hiện tại.
							|Có thể là cơ sở thông tin không phải là nút trực thuộc trong CSTTPT.';
							|ru = 'Главный узел для текущей информационной базы не определен.
							|Возможно, информационная база не является подчиненным узлом в РИБ.';
							|en = 'The master node is not defined.
							|Probably this infobase is not a subordinate DIB node.'; fa = 'The master node is not defined.
							|Probably this infobase is not a subordinate DIB node.';
							|it = 'Il nodo principale per il database informatico corrente non è definito.
							|È possibile che il database informatico non sia un nodo subordinato nel database informatico distribuito.';
							|pl = 'Główny węzeł dla bieżącej bazy informacyjnej nie został zdefiniowany. 
							|Możliwe, baza informacyjna nie jest podwładnym węzłem w RBI.';
							|tr = 'Geçerli Infobase için master düğüm tanımlanmamıştır.
							| Infobase DBT''deki alt düğüm olmayabilir.'");
		EndIf;
		
		NewNode = MasterNode.GetObject();
		
		// Transferring common data from the predefined node.
		ThisNodeObject = ThisNode.GetObject();
		
		MetadataOfExchangePlan = NewNode.Metadata();
		SharedDataString = DataExchangeServer.ExchangePlanSettingValue(ConnectionSettings.ExchangePlanName,
			"CommonNodeData", ConnectionSettings.ExchangeSetupOption);
		
		SharedData = StrSplit(SharedDataString, ", ", False);
		For Each ItemCommonData In SharedData Do
			If MetadataOfExchangePlan.TabularSections.Find(ItemCommonData) = Undefined Then
				FillPropertyValues(NewNode, ThisNodeObject, ItemCommonData);
			Else
				NewNode[ItemCommonData].Load(ThisNodeObject[ItemCommonData].Unload());
			EndIf;
		EndDo;
	Else
		// Create or update a node.
		NewNodeRef = ManagerExchangePlan.FindByCode(NewNodeCode);
		
		CreateNewNode = NewNodeRef.IsEmpty();
		
		If CreateNewNode Then
			NewNode = ManagerExchangePlan.CreateNode();
			NewNode.Code = NewNodeCode;
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Giá trị tiền tố chương trình ""%1"" không đơn trị (""%2""). Đã tồn tại tùy chỉnh đồng bộ với tiền tố như vậy.
				|Để tiếp tục, hãy ấn định tiền tố cơ sở thông tin đơn trị, khác với tiền tố hiện tại trong chương trình ""%1"".';
				|ru = 'Значение префикса программы ""%1"" не уникально (""%2""). Уже существует настройка синхронизации с таким же префиксом.
				|Для продолжения назначьте в программе ""%1"" уникальный префикс информационной базы, отличный от текущего.';
				|en = 'The %1 application prefix value is not unique (""%2""). A synchronization setting with the specified prefix already exists.
				|To continue, specify a unique infobase prefix different from the current one in %1.'; fa = 'The %1 application prefix value is not unique (""%2""). A synchronization setting with the specified prefix already exists.
				|To continue, specify a unique infobase prefix different from the current one in %1.';
				|it = 'Il valore del prefisso del programma ""%1"" non è univoco (""%2""). Esiste già l''impostazione di sincronizzazione con tale prefisso.
				|Per continuare, assegnare nel programma ""%1"" un prefisso univoco all''infobase diverso da quello corrente.';
				|pl = 'Wartość prefiksu programu ""%1"" nie jest unikalna (""%2""). Już istnieje ustawienie synchronizacji z takim samym prefiksem.
				|Aby kontynuować wyznacz w programie ""%1"" unikalny prefiks bazy informacyjnej, odmienny od aktualnego.';
				|tr = '""%1"" uygulamasının önek değeri benzersiz değil (""%2""). Aynı önek ile eşitleme ayarı zaten mevcut.
				|Devam etmek için, ""%1"" programında, mevcut ile aynı olmayan, benzersiz bir infobase öneki atayın.'"),
				ConnectionSettings.SecondInfobaseDescription, NewNodeCode);
		EndIf;
		
		NewNode.Description = ConnectionSettings.SecondInfobaseDescription;
		
		If Common.HasObjectAttribute("SettingsMode", Metadata.ExchangePlans[ConnectionSettings.ExchangePlanName]) Then
			NewNode.SettingsMode = ConnectionSettings.ExchangeSetupOption;
		EndIf;
		
		If CreateNewNode Then
			NewNode.Fill(Undefined);
		EndIf;
		
		If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
			If ValueIsFilled(ConnectionSettings.ExchangeFormatVersion) Then
				NewNode.ExchangeFormatVersion = ConnectionSettings.ExchangeFormatVersion;
			EndIf;
		EndIf;
		
	EndIf;
	
	// Reset message counters.
	NewNode.SentNo = 0;
	NewNode.ReceivedNo     = 0;
	
	If RestoreExchangeSettings Then
		NewNode.SentNo = ConnectionSettings.ReceivedNo;
		NewNode.ReceivedNo = ConnectionSettings.SentNo;
	EndIf;
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable()
		And DataExchangeServer.IsSeparatedSSLExchangePlan(ConnectionSettings.ExchangePlanName) Then
		
		NewNode.RegisterChanges = True;
		
	EndIf;
	
	If ValueIsFilled(ConnectionSettings.RefToNew) Then
		NewNode.SetNewObjectRef(ConnectionSettings.RefToNew);
	EndIf;
	
	NewNode.DataExchange.Load = True;
	NewNode.Write();
	
	If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
		If ConnectionSettings.SupportedObjectsInFormat <> Undefined Then
			InformationRegisters.XDTODataExchangeSettings.UpdateCorrespondentSettings(NewNode.Ref,
				"SupportedObjects", ConnectionSettings.SupportedObjectsInFormat.Get());
		EndIf;
		
		DataExchangeLoopControl.UpdateCircuit(ConnectionSettings.ExchangePlanName);

		RecordStructure = New Structure;
		RecordStructure.Insert("InfobaseNode", NewNode.Ref);
		RecordStructure.Insert("CorrespondentExchangePlanName", ConnectionSettings.CorrespondentExchangePlanName);
		
		DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "XDTODataExchangeSettings");
		
	EndIf;
	
	ConnectionSettings.InfobaseNode = NewNode.Ref;
	
	// Shared node data.
	InformationRegisters.CommonInfobasesNodesSettings.UpdatePrefixes(
		ConnectionSettings.InfobaseNode,
		?(ConnectionSettings.UsePrefixesForExchangeSettings
			Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings, ConnectionSettings.SourceInfobasePrefix, ""),
		ConnectionSettings.DestinationInfobasePrefix);
		
	InformationRegisters.CommonInfobasesNodesSettings.SetNameOfCorrespondentExchangePlan(
		ConnectionSettings.InfobaseNode,
		ConnectionSettings.CorrespondentExchangePlanName);
			
	If CreateNewNode
		And Not Common.DataSeparationEnabled() Then
		DataExchangeServer.UpdateDataExchangeRules();
	EndIf;
	
	If ThisNodeCode <> ThisNodeCodeInDatabase
		And DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName)
		And (ConnectionSettings.UsePrefixesForExchangeSettings
			Or ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings) Then
		// Node in the correspondent base needs recoding.
		StructureTemporaryCode = New Structure;
		StructureTemporaryCode.Insert("Peer", ConnectionSettings.InfobaseNode);
		StructureTemporaryCode.Insert("NodeCode",       ThisNodeCode);
		
		DataExchangeInternal.AddRecordToInformationRegister(StructureTemporaryCode, "PredefinedNodesAliases");
	EndIf;

EndProcedure

Function GettingCorrespondentParameters(ConnectionSettings) Export
	
	SetPrivilegedMode(True);
	
	InitializationParameters = ExchangeMessagesTransport.InitializationParameters();
	FillPropertyValues(InitializationParameters, ConnectionSettings);
	
	Transport = ExchangeMessagesTransport.Initialize(InitializationParameters);
	CorrespondentParameters = Transport.CorrespondentParameters(ConnectionSettings);
	
	Return CorrespondentParameters;
	
EndFunction

Procedure AtStartOfDataExchangeStartup(ImportParameters, HandlerParameters, MethodName, ContinueWait = False)
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ImportParameters.InfobaseNode);
	TransportID = ExchangeMessagesTransport.DefaultTransport(ImportParameters.InfobaseNode);
	
	BackgroundJobKey = DataExchangeServer.BackgroundJobKey(ExchangePlanName,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kết nhập thông điệp trao đổi: %1';
				|ru = 'Загрузка сообщения обмена данными: %1';
				|en = 'Importing data exchange message: %1'; fa = 'Importing data exchange message: %1';
				|it = 'Importing data exchange message: %1';
				|pl = 'Importing data exchange message: %1';
				|tr = 'Veri değişim mesajını dışa aktarma: %1'"), TransportID));

	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã thực hiện kết nhập thông điệp trao đổi: %1.';
				|ru = 'Загрузка сообщения обмена данными: %1 уже выполняется.';
				|en = 'Importing the ""%1"" data exchange message is already in progress.'; fa = 'Importing the ""%1"" data exchange message is already in progress.';
				|it = 'Importing the ""%1"" data exchange message is already in progress.';
				|pl = 'Importing the ""%1"" data exchange message is already in progress.';
				|tr = 'Veri değişim mesajını dışa aktarma: %1 hali hazırda gerçekleştiriliyor.'"), TransportID);
	EndIf;
		
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kết nhập thông điệp trao đổi: %1.';
			|ru = 'Загрузка сообщения обмена данными: %1.';
			|en = 'Importing data exchange message: %1.'; fa = 'Importing data exchange message: %1.';
			|it = 'Importing data exchange message: %1.';
			|pl = 'Importing data exchange message: %1.';
			|tr = 'Veri değişim mesajını dışa aktarma: %1'"), TransportID);
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1    = False;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		MethodName,
		ImportParameters,
		ExecutionParameters);
		
	OnStartTimeConsumingOperation(BackgroundJob, HandlerParameters, ContinueWait);
		
EndProcedure

// Returns:
//  Structure:
//   * Cancel - Boolean
//   * ErrorMessage - String
//
Function InitializeResultOfOperation()
	
	Result = New Structure;
	Result.Insert("Cancel",             False);
	Result.Insert("ErrorMessage", "");
	
	Return Result;
	
EndFunction

Procedure ImportMessageBeforeInfobaseUpdate(ImportParameters)
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
		"SkipImportDataExchangeMessageBeforeStart") Then
		Return;
	EndIf;
	
	If GetFunctionalOption("UseDataSynchronization") Then
		
		If ImportParameters.InfobaseNode <> Undefined Then
			
			SetPrivilegedMode(True);
			DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", True);
			SetPrivilegedMode(False);
			
			// Updating object registration rules before importing data.
			DataExchangeServer.UpdateDataExchangeRules();
			
			TransportID = ExchangeMessagesTransport.DefaultTransport(ImportParameters.InfobaseNode);
			
			If ImportParameters.ContinueUploadingMessageFromArchive Then
				DataExchangeServer.SaveMessageFromArchiveToCache(ImportParameters.InfobaseNode);
			EndIf;
			
			// Import only.
			ExchangeParameters = DataExchangeServer.ExchangeParameters();
			ExchangeParameters.TransportID = TransportID;
			ExchangeParameters.AuthenticationData = ImportParameters.AuthenticationData;
			ExchangeParameters.ExecuteImport1 = True;
			ExchangeParameters.ExecuteExport2 = False;
			
			DataExchangeServer.ExecuteDataExchangeForInfobaseNode(ImportParameters.InfobaseNode, ExchangeParameters, ImportParameters.HasErrors);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ExportMessageAfterInfobaseUpdate(ExportingParameters)
	
	// The repeat mode can be disabled if messages are imported and the infobase is updated successfully.
	DataExchangeServer.DisableDataExchangeMessageImportRepeatBeforeStart();
	
	Try
		If GetFunctionalOption("UseDataSynchronization") Then
			
			InfobaseNode = DataExchangeServer.MasterNode();
			
			If InfobaseNode <> Undefined Then
				
				ExecuteExport = True;
				
				TransportID = ExchangeMessagesTransport.DefaultTransport(InfobaseNode);
				
				If ExecuteExport Then
					
					// Export only.
					Cancel = False;
					
					ExchangeParameters = DataExchangeServer.ExchangeParameters();
					ExchangeParameters.TransportID = TransportID;
					ExchangeParameters.AuthenticationData    = ExportingParameters.AuthenticationData;
					ExchangeParameters.ExecuteImport1       = False;
					ExchangeParameters.ExecuteExport2       = True;
						
					DataExchangeServer.ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, Cancel);

				EndIf;
				
			EndIf;
			
		EndIf;
		
	Except
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure ImportPriorityDataToSubordinateDIBNode(ImportParameters)
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
		"SkipImportDataExchangeMessageBeforeStart") Then
		Return;
	EndIf;
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
		"SkipImportPriorityDataBeforeStart") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", True);
	SetPrivilegedMode(False);
	
	CheckDataSynchronizationEnabled();
	
	If GetFunctionalOption("UseDataSynchronization") Then
		
		InfobaseNode = DataExchangeServer.MasterNode();
		
		If InfobaseNode <> Undefined Then
			
			TransportID = ExchangeMessagesTransport.DefaultTransport(InfobaseNode);
			If TransportID = Undefined Then
				
				Catalogs.ExchangeMessageTransportSettings.ProcessDataForMigrationToNewVersion();
				TransportID = ExchangeMessagesTransport.DefaultTransport(InfobaseNode);
				
			EndIf;
			
			UpdatingRulesForDataExchange(ImportParameters.InfobaseNode);
			
			If ImportParameters.ContinueUploadingMessageFromArchive Then
				DataExchangeServer.SaveMessageFromArchiveToCache(InfobaseNode);
			EndIf;
			
			// Importing application parameters only.
			ExchangeParameters = DataExchangeServer.ExchangeParameters();
			ExchangeParameters.TransportID = TransportID;
			ExchangeParameters.AuthenticationData = ImportParameters.AuthenticationData;
			ExchangeParameters.ExecuteImport1 = True;
			ExchangeParameters.ExecuteExport2 = False;
			ExchangeParameters.ParametersOnly   = True;
			
			DataExchangeServer.ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, ImportParameters.HasErrors);
			
		EndIf;
		
	EndIf; 
	
EndProcedure

Procedure UpdatingRulesForDataExchange(InfobaseNode)
	
	ParameterName = "StandardSubsystems.DataExchange.RecordRules."
		+ DataExchangeCached.GetExchangePlanName(InfobaseNode);  
		
	RegistrationRulesUpdated = StandardSubsystemsServer.ApplicationParameter(ParameterName);
	
	If RegistrationRulesUpdated = Undefined Then
		DataExchangeServer.UpdateDataExchangeRules();
	EndIf;
	
	RegistrationRulesUpdated = StandardSubsystemsServer.ApplicationParameter(ParameterName);
	
	If RegistrationRulesUpdated = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa thực hiện cập nhật bộ nhớ đệm quy tắc ghi nhận dữ liệu cho sơ đồ trao đổi ""%1""';
				|ru = 'Не выполнено обновление кэша правил регистрации данных для плана обмена ""%1""';
				|en = 'Cannot update data registration rules cache for exchange plan ""%1""'; fa = 'Cannot update data registration rules cache for exchange plan ""%1""';
				|it = 'Non è stato eseguito l''aggiornamento delle regole di registrazione dati per il piano di scambio %1';
				|pl = 'Nie wykonano aktualizacji buforu reguł rejestracji danych dla planu wymiany ""%1""';
				|tr = 'Değişim planı için veri kayıt kurallarının güncellenmesi yürütülmedi ""%1""'"),
			DataExchangeCached.GetExchangePlanName(InfobaseNode));
	EndIf;
	
EndProcedure  

Procedure CheckDataSynchronizationEnabled()
	
	If Not GetFunctionalOption("UseDataSynchronization") Then
		
		If Common.DataSeparationEnabled() Then
			
			UseDataSynchronization = Constants.UseDataSynchronization.CreateValueManager();
			UseDataSynchronization.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
			UseDataSynchronization.DataExchange.Load = True;
			UseDataSynchronization.Value = True;
			UseDataSynchronization.Write();
			
		Else
			
			If DataExchangeServer.GetExchangePlansInUse().Count() > 0 Then
				
				UseDataSynchronization = Constants.UseDataSynchronization.CreateValueManager();
				UseDataSynchronization.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
				UseDataSynchronization.DataExchange.Load = True;
				UseDataSynchronization.Value = True;
				UseDataSynchronization.Write();
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf