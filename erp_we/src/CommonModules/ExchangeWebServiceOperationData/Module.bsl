///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region HandlersOfOperations

Function ExecuteExport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage, DataArea = 0) Export
	
	SignInToDataArea(DataArea);
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	ExchangeMessage = "";
	
	DataExchangeServer.ExportForInfobaseNodeViaString(ExchangePlanName, InfobaseNodeCode, ExchangeMessage);
	
	ExchangeMessageStorage = New ValueStorage(ExchangeMessage, New Deflation(9));
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

Function RunDataExport(ExchangePlanName,
								InfobaseNodeCode,
								FileIDAsString,
								TimeConsumingOperation,
								OperationID,
								TimeConsumingOperationAllowed,
								DataArea = 0) Export
								
	SignInToDataArea(DataArea);
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	FileID = New UUID;
	FileIDAsString = String(FileID);
	
	RunExportDataInClientServerMode(ExchangePlanName, InfobaseNodeCode, FileID, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed);
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

Function RunDataExportInternalPublication(ExchangePlanName, InfobaseNodeCode, 
	TaskID__, DataArea) Export
	
	SetPrivilegedMode(True);
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
		
	ExportDataInClientServerModeInternalPublication(
		ExchangePlanName, InfobaseNodeCode, TaskID__, DataArea);
		
	Return "";
	
EndFunction

Function ExecuteImport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage, DataArea = 0) Export
	
	SignInToDataArea(DataArea);
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	DataExchangeServer.ImportForInfobaseNodeViaString(
		ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage.Get());
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

Function RunDataImport(ExchangePlanName, InfobaseNodeCode, FileIDAsString, TimeConsumingOperation,
	OperationID, TimeConsumingOperationAllowed, DataArea = 0) Export
								
	SignInToDataArea(DataArea);
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	FileID = New UUID(FileIDAsString);
	
	RunImportDataInClientServerMode(ExchangePlanName, InfobaseNodeCode, FileID, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed);	
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

Function RunDataImportInternalPublication(ExchangePlanName, InfobaseNodeCode, TaskID__,
	FileIDAsString, DataArea = 0) Export
	
	SetPrivilegedMode(True);
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	FileID = New UUID(FileIDAsString);
	
	ImportDataInClientServerModeInternalPublication(
		ExchangePlanName, InfobaseNodeCode, TaskID__, FileID, DataArea);

	Return "";
	
EndFunction

Function GetInfobaseParameters(ExchangePlanName, NodeCode, ErrorMessage,
	DataArea = 0, AdditionalXDTOParameters = Undefined) Export
	
	SignInToDataArea(DataArea);
	
	If AdditionalXDTOParameters <> Undefined Then
		
		AdditionalParameters = XDTOSerializer.ReadXDTO(AdditionalXDTOParameters);
		
	EndIf;
	
	Result = DataExchangeServer.InfoBaseAdmParams(ExchangePlanName, NodeCode, ErrorMessage, AdditionalParameters);
	
	SignOutOfDataArea(DataArea);
	
	Return XDTOSerializer.WriteXDTO(Result);
	
EndFunction

Function CreateDataExchangeNode(XDTOParameters, DataArea = 0) Export
	
	SignInToDataArea(DataArea);
	
	SetPrivilegedMode(True);
	
	DataExchangeServer.CheckDataExchangeUsage(True);
	
	Parameters = XDTOSerializer.ReadXDTO(XDTOParameters);
	
	ConnectionSettings = Parameters.ConnectionSettings;
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	Try
		
		If ConnectionSettings.Property("WSCorrespondentEndpoint")
			And ValueIsFilled(ConnectionSettings.WSCorrespondentEndpoint) Then
			
			ConnectionSettingsFromXML = 
				ExchangeMessagesTransport.ConnectionSettingsFromXML(Parameters.XMLParametersString, "SM");
			
			// ACC:1416-off - 4.2. Structures whose format is not fixed (from the peer) are considered exceptions.
			
			// A connection via an internal publication from previous versions; do not pass the ID
			If Not ConnectionSettings.Property("TransportID") Then
				
				ConnectionSettings.Insert("TransportID", "SM");
				
			EndIf;
			
			// When connecting via internal publication for new transport types
			If Not ConnectionSettings.Property("TransportSettings")
				Or TypeOf(ConnectionSettings.TransportSettings) <> Type("Structure") Then
				
				// The CloudTechnology.MessagesExchange subsystem is mandatory for SaaS deployments.
				// Therefore, checking the call is skipped.
				CorrespondentEndpoint = ExchangePlans["MessagesExchange"].FindByCode(ConnectionSettings["WSКонечнаяТочкаКорреспондента"]); // @Non-NLS-2
				
				TransportSettings = New Structure;
				TransportSettings.Insert("CorrespondentEndpoint", CorrespondentEndpoint);	
				TransportSettings.Insert("CorrespondentDataArea", ConnectionSettings["WSОбластьДанныхКорреспондента"]); // @Non-NLS-2
				TransportSettings.Insert("PeerInfobaseName", "");
				TransportSettings.Insert("InternalPublication", True);
				
				ConnectionSettings.Insert("TransportSettings", TransportSettings);
				
			EndIf;
			
			// ACC:1416-on
			
		Else
		
			ConnectionSettingsFromXML = 
				ExchangeMessagesTransport.ConnectionSettingsFromXML(Parameters.XMLParametersString, "WS");
				
			ConnectionSettings.Insert("TransportID", "PassiveMode");
			ConnectionSettings.Insert("TransportSettings", New Structure);
		
		EndIf;
	
		ExchangeMessagesTransport.CheckAndFillInXMLConnectionSettings(ConnectionSettings, ConnectionSettingsFromXML, True);
		
		ModuleSetupWizard.ConfigureDataExchange(ConnectionSettings);
		
	Except
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessage);
			
		Raise ErrorMessage;
	EndTry;
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

Function DeleteDataExchangeNode(ExchangePlanName, NodeID, DataArea = 0) Export
	
	SignInToDataArea(DataArea);
	
	SetPrivilegedMode(True);
	
	ExchangeNode = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeID);
		
	If ExchangeNode = Undefined Then
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong ""%1""không tìm thấy nút sơ đồ trao đổi ""%2"" có tên định danh ""%3"".';
				|ru = 'В ""%1"" не найден узел плана обмена ""%2"" с идентификатором ""%3"".';
				|en = 'Exchange plan node ""%2"" with ID %3 is not found in %1.'; fa = 'Exchange plan node ""%2"" with ID %3 is not found in %1.';
				|it = 'In ""%1"" non è stata trovato il nodo di piano di scambio  ""%2"" con ID ""%3"".';
				|pl = 'W ""%1"" nie znaleziono węzła planu wymiany ""%2"" z identyfikatorem ""%3"".';
				|tr = '""%1""de ""%3"" belirteçli ""%2"" değişim planı düğümü bulunamadı.'"),
			ApplicationPresentation, ExchangePlanName, NodeID);
	EndIf;
	
	DataExchangeServer.DeleteSynchronizationSetting(ExchangeNode);
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

Function GetTimeConsumingOperationState(OperationID, ErrorMessageString, DataArea = 0) Export
	
	SignInToDataArea(DataArea);
	
	SetPrivilegedMode(True);
		
	BackgroundJobStates = New Map;
	BackgroundJobStates.Insert(BackgroundJobState.Active,           "Active");
	BackgroundJobStates.Insert(BackgroundJobState.Completed,         "Completed");
	BackgroundJobStates.Insert(BackgroundJobState.Failed, "Failed");
	BackgroundJobStates.Insert(BackgroundJobState.Canceled,          "Canceled");
		
	BackgroundJob = BackgroundJobs.FindByUUID(New UUID(OperationID));
	
	If BackgroundJob = Undefined Then
		
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy hoạt động lâu với tên định danh %1.';
				|ru = 'Не найдено длительной операции с идентификатором %1.';
				|en = 'No long-running operation with ID %1 was found.'; fa = 'No long-running operation with ID %1 was found.';
				|it = 'Non è stata trovata nessuna operazione di lunga durata con l''identificativo %1.';
				|pl = 'Nie znaleziono operacji długotrwałej z identyfikatorem %1';
				|tr = '%1 belirteçli uzun süreli işlemler bulunamadı.'"),
			OperationID);
			
		SignOutOfDataArea(DataArea);
		
		Return BackgroundJobStates.Get(BackgroundJobState.Canceled);
		
	EndIf;
	
	If BackgroundJob.ErrorInfo <> Undefined Then
		
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(BackgroundJob.ErrorInfo);
		
	EndIf;
	
	SignOutOfDataArea(DataArea);
	
	Return BackgroundJobStates.Get(BackgroundJob.State);
	
EndFunction

Function PrepareFileForReceipt(FileID, BlockSize, TransferID, PartCount, Area = 0) Export
	
	SignInToDataArea(Area);
	
	SetPrivilegedMode(True);
	
	TransferID = New UUID;
	
	ExchangeMessagesTransportOverridable.BeforeRetrievingFileFromRepository(FileID);
	
	SourceFileName1 = DataExchangeServer.GetFileFromStorage(FileID);
	
	TempDirectory = TemporaryExportDirectory(TransferID);
	
	SourceFileNameInTemporaryDirectory = CommonClientServer.GetFullFileName(TempDirectory, "data.zip");
	
	CreateDirectory(TempDirectory);
	
	MoveFile(SourceFileName1, SourceFileNameInTemporaryDirectory);
	
	If BlockSize <> 0 Then
		// Splitting a file into parts
		FilesNames = SplitFile(SourceFileNameInTemporaryDirectory, BlockSize * 1024);
		PartCount = FilesNames.Count();
		
		DeleteFiles(SourceFileNameInTemporaryDirectory);
	Else
		PartCount = 1;
		MoveFile(SourceFileNameInTemporaryDirectory, SourceFileNameInTemporaryDirectory + ".1");
	EndIf;
	
	SignOutOfDataArea(Area);
		
	Return "";
	
EndFunction

Function GetFileChunk(TransferID, PartNumber, PartData, Area = 0) Export
	
	SignInToDataArea(Area);
	
	FilesNames = FindPartFile(TemporaryExportDirectory(TransferID), PartNumber);
	
	If FilesNames.Count() = 0 Then
		
		MessageTemplate = NStr("vi = 'Không tìm thấy phân đoạn %1 của phiên truyền dữ liệu có tên định danh %2';
								|ru = 'Не найден фрагмент %1 сессии передачи с идентификатором %2';
								|en = 'Part %1 of the transfer session with ID %2 is not found'; fa = 'Part %1 of the transfer session with ID %2 is not found';
								|it = 'Frammento %1 della sessione di trasferimento con ID %2 non trovato.';
								|pl = 'Nie znaleziono fragmentu %1 sesji transmisji z identyfikatorem %2';
								|tr = '%2 belirteçli %1 aktarım oturumu kısmı bulunamadı'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate, String(PartNumber), String(TransferID));
		Raise(MessageText);
		
	ElsIf FilesNames.Count() > 1 Then
		
		MessageTemplate = NStr("vi = 'Đã tìm thấy nhiều phân đoạn %1 của phiên truyền dữ liệu có tên định danh %2';
								|ru = 'Найдено несколько фрагментов %1 сессии передачи с идентификатором %2';
								|en = 'Multiple parts %1 of the transfer session with ID %2 are not found'; fa = 'Multiple parts %1 of the transfer session with ID %2 are not found';
								|it = 'Sono stati ritrovati alcuni frammenti %1 della sessione di trasferimento con ID%2';
								|pl = 'Znaleziono parę fragmentów %1 sesji transmisji z identyfikatorem %2';
								|tr = '%2 belirteçli bir kaç %1 aktarım oturumu kısmı bulundu'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate, String(PartNumber), String(TransferID));
		Raise(MessageText);
		
	EndIf;
	
	PartFileName = FilesNames[0].FullName;
	PartData = New BinaryData(PartFileName);
	
	SignOutOfDataArea(Area);
	
	Return "";
	
EndFunction

Function DeleteExchangeMessage(TransferID) Export
	
	Try
		DeleteFiles(TemporaryExportDirectory(TransferID));
	Except
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return "";
	
EndFunction

Function PutFileChunk(TransferID, PartNumber, PartData, Area = 0) Export
	
	SignInToDataArea(Area);
	
	TempDirectory = TemporaryExportDirectory(TransferID);
	
	If PartNumber = 1 Then
		
		CreateDirectory(TempDirectory);
		
	EndIf;
	
	FileName = CommonClientServer.GetFullFileName(TempDirectory, GetPartFileName(PartNumber));
	
	PartData.Write(FileName);
	
	SignOutOfDataArea(Area);
	
	Return "";
	
EndFunction

Function AssembleFileFromParts(TransferID, PartCount, FileID, Area = 0) Export
	
	SignInToDataArea(Area);
	
	SetPrivilegedMode(True);
	
	TempDirectory = TemporaryExportDirectory(TransferID);
	
	PartsFilesToMerge = New Array;
	
	For PartNumber = 1 To PartCount Do
		
		FileName = CommonClientServer.GetFullFileName(TempDirectory, GetPartFileName(PartNumber));
		
		If FindFiles(FileName).Count() = 0 Then
			MessageTemplate = NStr("vi = 'Không tìm thấy phân đoạn %1 của phiên truyền có tên định danh %2.
					|Cần chắc chắn rằng, trong tùy chỉnh chương trình có đặt tham số
					|""Thư mục tệp tạm thời dành cho Linux"" và ""Thư mục tệp tạm thời dành cho Windows"".';
					|ru = 'Не найден фрагмент %1 сессии передачи с идентификатором %2.
					|Необходимо убедиться, что в настройках программы заданы параметры
					|""Каталог временных файлов для Linux"" и ""Каталог временных файлов для Windows"".';
					|en = 'Part %1 of the transfer session with ID %2 is not found. 
					|Make sure that the ""Directory of temporary files for Linux""
					| and ""Directory of temporary files for Windows"" parameters are specified in the application settings.'; fa = 'Part %1 of the transfer session with ID %2 is not found. 
					|Make sure that the ""Directory of temporary files for Linux""
					| and ""Directory of temporary files for Windows"" parameters are specified in the application settings.';
					|it = 'Il  frammento %1 della sessione di trasferimento con l''ID non è stato trovato.%2
					| È necessario assicurarsi che le impostazioni del programma specifichino i parametri 
					|""File temporanei per Linux"" e ""File temporanei per Windows"".';
					|pl = 'Nie znaleziono fragment %1 sesji transmisji z identyfikatorem %2.
					|Należy upewnić się, że w opcjach programu ustawiono parametry
					|""Katalog tymczasowych plików dla systemu Linux"" i ""Katalog plików tymczasowych systemu Windows"".';
					|tr = '%2belirteç ile aktarım oturumu %1kısmı bulunamadı. 
					|Uygulama ayarlarında ""Linux için geçici dosya dizini"" ve ""Windows için geçici dosya dizini"" 
					|belirtildiğinden emin olmak gerekir.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate, String(PartNumber), String(TransferID));
			Raise(MessageText);
		EndIf;
		
		PartsFilesToMerge.Add(FileName);
		
	EndDo;
	
	ArchiveName = CommonClientServer.GetFullFileName(TempDirectory, "data.zip");
	
	MergeFiles(PartsFilesToMerge, ArchiveName);
	
	Dearchiver = New ZipFileReader(ArchiveName);
	
	If Dearchiver.Items.Count() = 0 Then
		
		Try
			DeleteFiles(TempDirectory);
		Except
			WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));	
		EndTry;
		
		SignOutOfDataArea(Area);
		Raise(NStr("vi = 'Tệp sao lưu không chứa dữ liệu.';
					|ru = 'Файл архива не содержит данных.';
					|en = 'The archive file is empty.'; fa = 'The archive file is empty.';
					|it = 'Il file d''archivio non contiene dati.';
					|pl = 'Plik archiwum nie zawiera danych.';
					|tr = 'Arşiv dosyası veri içermemektedir.'"));
		
	EndIf;
	
	DumpDirectory = DataExchangeServer.TempFilesStorageDirectory();
	
	ArchiveItem = Dearchiver.Items.Get(0);
	FileName = CommonClientServer.GetFullFileName(DumpDirectory, ArchiveItem.Name);
	
	Dearchiver.Extract(ArchiveItem, DumpDirectory);
	Dearchiver.Close();
	
	FileID = DataExchangeServer.PutFileInStorage(FileName, FileID);
	
	ExchangeMessagesTransportOverridable.OnPutFileToStorage(FileName, FileID);
	
	Try
		DeleteFiles(TempDirectory);
	Except
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	SignOutOfDataArea(Area);
	
	Return "";
	
EndFunction

Function PutMessageForDataMapping(ExchangePlanName, NodeID, FileID, DataArea = 0) Export
	
	SignInToDataArea(DataArea);
	
	SetPrivilegedMode(True);
	
	ExchangeNode = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeID);
		
	If ExchangeNode = Undefined Then
		
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		SignOutOfDataArea(DataArea);	
			
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong ""%1"" không tìm thấy nút sơ đồ trao đổi ""%2"" có tên định danh ""%3"".';
				|ru = 'В ""%1"" не найден узел плана обмена ""%2"" с идентификатором ""%3"".';
				|en = 'Exchange plan node ""%2"" with ID %3 is not found in %1.'; fa = 'Exchange plan node ""%2"" with ID %3 is not found in %1.';
				|it = 'In ""%1"" non è stata trovato il nodo di piano di scambio  ""%2"" con ID ""%3"".';
				|pl = 'W ""%1"" nie znaleziono węzła planu wymiany ""%2"" z identyfikatorem ""%3"".';
				|tr = '""%1""de ""%3"" belirteçli ""%2"" değişim planı düğümü bulunamadı.'"),
			ApplicationPresentation, ExchangePlanName, NodeID);
			
	EndIf;
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	DataExchangeInternal.PutMessageForDataMapping(ExchangeNode, FileID);
	
	// The web client and the thin client have dedicated temporary directories. 
	// Configuring syncing from the thin client will result in an error due to the missing file
	// in the temporary directory.
	// 
	MoveTheMessageFileForTheFileIB(FileID);
	
	SignOutOfDataArea(DataArea);
	
	Return "";
	
EndFunction

Function TestingConnection(ExchangePlanName, NodeCode, Result, DataArea = 0) Export
	
	SignInToDataArea(DataArea);
	
	SetPrivilegedMode(True);
	
	// Checking whether a user has rights to perform the data exchange.
	Try
		DataExchangeServer.CheckCanSynchronizeData(True);
	Except
		Result = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	// Checking whether the infobase is locked for update.
	Try
		CheckInfobaseLockForUpdate();
	Except
		Result = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	// Checking whether the exchange plan node exists (it might be deleted).
	NodeRef1 = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeCode); 
	If NodeRef1 = Undefined
		Or Common.ObjectAttributeValue(NodeRef1, "DeletionMark") Then
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		ExchangePlanPresentation1 = Metadata.ExchangePlans[ExchangePlanName].Presentation();
			
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong ""%1"" không tìm thấy tùy chỉnh đồng bộ dữ liệu ""%2"" với tên định danh ""%3"".';
				|ru = 'В ""%1"" не найдена настройка синхронизации данных ""%2"" с идентификатором ""%3"".';
				|en = 'Data synchronization setting ""%2"" with ID %3 is not found in %1.'; fa = 'Data synchronization setting ""%2"" with ID %3 is not found in %1.';
				|it = 'In ""%1"" non è stata trovata l''impostazione di sincronizzazione dei dati ""%2"" con ID ""%3"".';
				|pl = 'W ""%1"" nie znaleziono ustawienia synchronizacji danych ""%2"" z identyfikatorem ""%3"".';
				|tr = '""%1""de ""%3"" belirteçli ""%2"" veri senkronizasyonu ayarları bulunamadı.'"),
			ApplicationPresentation, ExchangePlanPresentation1, NodeCode);
			
		SignOutOfDataArea(DataArea);
			
		Return False;
	EndIf;
	
	SignOutOfDataArea(DataArea);
	
	Return True;
	
EndFunction

Function ChangeTransportToInternalPublishingWebService(XDTOParameters, DataArea) Export
	
	SignInToDataArea(DataArea);
	
	SetPrivilegedMode(True);
	
	Parameters = XDTOSerializer.ReadXDTO(XDTOParameters);
	
	ExchangeNode = DataExchangeServer.ExchangePlanNodeByCode(Parameters.ExchangePlanName, Parameters.CorrespondentNodeCode);
		
	If ExchangeNode = Undefined Then
		
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong ""%1"" không tìm thấy nút sơ đồ trao đổi ""%2"" có tên định danh ""%3"".';
				|ru = 'В ""%1"" не найден узел плана обмена ""%2"" с идентификатором ""%3"".';
				|en = 'Exchange plan node ""%2"" with ID %3 is not found in %1.'; fa = 'Exchange plan node ""%2"" with ID %3 is not found in %1.';
				|it = 'In ""%1"" non è stata trovato il nodo di piano di scambio  ""%2"" con ID ""%3"".';
				|pl = 'W ""%1"" nie znaleziono węzła planu wymiany ""%2"" z identyfikatorem ""%3"".';
				|tr = '""%1""de ""%3"" belirteçli ""%2"" değişim planı düğümü bulunamadı.'"),
			ApplicationPresentation, Parameters.ExchangePlanName, Parameters.CorrespondentNodeCode);
			
	EndIf;
		
	Endpoint = ExchangePlans["MessagesExchange"].FindByCode(Parameters.CorrespondentEndpoint);	
	
	TransportSettings = New Structure; 
	TransportSettings.Insert("InternalPublication", True);
	TransportSettings.Insert("Endpoint", "");
	TransportSettings.Insert("CorrespondentEndpoint", Endpoint);
	TransportSettings.Insert("PeerInfobaseName", "");
	TransportSettings.Insert("CorrespondentDataArea", Parameters.CorrespondentDataArea);
	
	ExchangeMessagesTransport.SaveTransportSettings(ExchangeNode, "SM", TransportSettings, True);
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thay đổi truyền của nút ""%1"" sơ đồ trao đổi ""%2"" trong vùng dữ liệu %3trên ""Internet"".';
			|ru = 'Изменение транспорта узла ""%1"" плана обмена ""%2"" в области данных %3 на ""Интернет"".';
			|en = 'Change the transport for node ""%1"" of exchange plan ""%2"" in data area %3 to ""Internet connection"".'; fa = 'Change the transport for node ""%1"" of exchange plan ""%2"" in data area %3 to ""Internet connection"".';
			|it = 'Modifica del trasporto del nodo ""%1"" del piano di scambio ""%2"" nell''area dati %3 in ""Internet"".';
			|pl = 'Zmiana transportu węzła ""%1"" planu wymiany ""%2"" w obszarze danych %3 na ""Internet"".';
			|tr = '""İnternette"" %3 veri alanında ""%2"" veri değişiminin ""%1"" düğümünün aracını değiştir.'"),
		Parameters.CorrespondentNodeCode, Parameters.ExchangePlanName, DataArea);
			
	WriteLogEvent(DataExchangeWebService.EventLogEventTransportChangedOnWS(),
		EventLogLevel.Information, , , MessageText);
	
	RecordStructure = New Structure("Peer", ExchangeNode);
	DataExchangeInternal.DeleteRecordSetFromInformationRegister(RecordStructure, "DataAreaExchangeTransportSettings");
	
	SignOutOfDataArea(DataArea);
	
EndFunction

Function CallingBack(TaskID__, Error, Area) Export
	
	SignInToDataArea(Area);
	
	SetPrivilegedMode(True);
	
	ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
	ModuleDataExchangeInternalPublication.MarkTaskAsCompleted(TaskID__, Error);
		
	CancelRepeatTaskFlagIsEnabled = StrFind(Error, ModuleDataExchangeInternalPublication.IndicatesWhetherTaskHasBeenCanceledAgain()) > 0;
		
	If Error = "" Or CancelRepeatTaskFlagIsEnabled Then
		
		If CancelRepeatTaskFlagIsEnabled Then
			Error = StrReplace(Error, ModuleDataExchangeInternalPublication.IndicatesWhetherTaskHasBeenCanceledAgain() + ":", "");
		EndIf;
		
		Task = ModuleDataExchangeInternalPublication.NextTask(TaskID__);
		JobPrev = TaskID__;
		
		If Task = Undefined Then
			Return "";
		EndIf;
		
		ProcedureParameters = New Array;
		ProcedureParameters.Add(Task);
		ProcedureParameters.Add(JobPrev);

		Var_Key = Task.TaskID__;

		JobParameters = New Structure;
		JobParameters.Insert("Key", Left(Var_Key, 120));
		JobParameters.Insert("MethodName"    , "DataExchangeInternalPublication.RunTaskQueue");
		JobParameters.Insert("DataArea", Area);
		JobParameters.Insert("Use", True);
		JobParameters.Insert("Parameters", ProcedureParameters);
		JobParameters.Insert("RestartCountOnFailure", 3);
		JobParameters.Insert("RestartIntervalOnFailure", 900);

		ModuleJobsQueue = Common.CommonModule("JobsQueue");
		ModuleJobsQueue.AddJob(JobParameters);
	
	Else
		
		Task = ModuleDataExchangeInternalPublication.TaskByID(TaskID__);
		
		Cancel = False;
		ExchangeSettingsStructure = 
			ModuleDataExchangeInternalPublication.ExchangeSettingsForInfobaseNode(Task.InfobaseNode, Task.Action, Cancel);
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
		
		DataExchangeServer.WriteEventLogDataExchange(Error, ExchangeSettingsStructure, True);
		DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
		
	EndIf;
	
	SignOutOfDataArea(Area);
	
EndFunction

Function TaskStatus(TaskID__) Export
	
	SetPrivilegedMode(True);
	
	JobParameters = New Structure("Key", TaskID__);
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	Jobs = ModuleJobsQueue.GetJobs(JobParameters);
	
	If Jobs.Count() > 0 Then
		
		State = Common.ObjectAttributeValue(Jobs[0].Id, "JobState");
		Return Common.EnumerationValueName(State);
		
	Else
		
		Return "";
		
	EndIf;

	
EndFunction

Function StopTasks(TasksIDs, Area) Export
	
	SignInToDataArea(Area);
	
	SetPrivilegedMode(True);
	
	TaskIdsArray = XDTOSerializer.ReadXDTO(TasksIDs);
	
	For Each TaskID__ In TaskIdsArray Do
		
		Filter = New Structure("Key", TaskID__);
		ModuleJobsQueue = Common.CommonModule("JobsQueue");
		Jobs = ModuleJobsQueue.GetJobs(Filter);
	
		For Each Job In Jobs Do
			
			JobParameters = New Structure;
			JobParameters.Insert("RestartCountOnFailure", 0);
			
			ModuleJobsQueue.ChangeJob(Job.Id, JobParameters);
			ModuleJobsQueue.DeleteJob(Job.Id);
			
			BackgrJobUUID = Common.ObjectAttributeValue(
				Job.Id, "ActiveBackgroundJob");
				
			TimeConsumingOperations.CancelJobExecution(BackgrJobUUID);
		
		EndDo;
		
	EndDo;
	
	SignOutOfDataArea(Area);
	
	Return "";
		
EndFunction

#EndRegion

Procedure CheckInfobaseLockForUpdate()
	
	If ValueIsFilled(InfobaseUpdateInternal.InfobaseLockedForUpdate()) Then
		
		Raise NStr("vi = 'Tạm thời không thể đồng bộ dữ liệu do đang cập nhật ứng dụng trên Internet.';
					|ru = 'Синхронизация данных временно недоступна в связи с обновлением приложения в Интернете.';
					|en = 'Data synchronization is temporarily unavailable due to online application update.'; fa = 'Data synchronization is temporarily unavailable due to online application update.';
					|it = 'La sincronizzazione dei dati non è momentaneamente disponibile a causa dell''aggiornamento dell''app su internet.';
					|pl = 'Synchronizacja danych jest chwilowo niedostępna z powodu aktualizacji aplikacji w Internecie.';
					|tr = 'Uygulamanın çevrimiçi güncellemesi nedeniyle veri senkronizasyonu geçici olarak kullanılamıyor.'");
		
	EndIf;
	
EndProcedure

Procedure RunExportDataInClientServerMode(ExchangePlanName,
														InfobaseNodeCode,
														FileID,
														TimeConsumingOperation,
														OperationID,
														TimeConsumingOperationAllowed)
	
	BackgroundJobKey = ExportImportDataBackgroundJobKey(ExchangePlanName,
		InfobaseNodeCode,
		NStr("vi = 'Kết xuất';
			|ru = 'Выгрузка';
			|en = 'Export'; fa = 'خروج اطلاعات';
			|it = 'Выгрузка';
			|pl = 'Eksportowanie';
			|tr = 'Dışa aktar'"));
	
	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise NStr("vi = 'Đang thực hiện đồng bộ dữ liệu.';
					|ru = 'Синхронизация данных уже выполняется.';
					|en = 'Data synchronization is already running.'; fa = 'Data synchronization is already running.';
					|it = 'Sincronizzazione dati già eseguita';
					|pl = 'Synchronizacja danych jest już w toku.';
					|tr = 'Verilerin senkronizasyonu zaten yürütülüyor.'");
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ExchangePlanName", ExchangePlanName);
	ProcedureParameters.Insert("InfobaseNodeCode", InfobaseNodeCode);
	ProcedureParameters.Insert("FileID", FileID);
	ProcedureParameters.Insert("UseCompression", True);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kết xuất dữ liệu thông qua Web-service.';
														|ru = 'Выгрузка данных через веб-сервис.';
														|en = 'Export data via web service.'; fa = 'Export data via web service.';
														|it = 'Caricamento dati tramite web-service.';
														|pl = 'Wyeksportowanie danych za pośrednictwem serwisu internetowego.';
														|tr = 'Web servis üzerinden verilerin dışa aktarılması.'");
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1 = Not TimeConsumingOperationAllowed;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeWebService.ExportToFileTransferServiceForInfobaseNode",
		ProcedureParameters,
		ExecutionParameters);
		
	If BackgroundJob.Status = "Running" Then
		OperationID = String(BackgroundJob.JobID);
		TimeConsumingOperation = True;
		Return;
	ElsIf BackgroundJob.Status = "Completed2" Then
		TimeConsumingOperation = False;
		Return;
	Else
		Message = NStr("vi = 'Lỗi khi kết xuất dữ liệu thông qua Web-service.';
						|ru = 'Ошибка при выгрузке данных через веб-сервис.';
						|en = 'Error exporting data via web service.'; fa = 'Error exporting data via web service.';
						|it = 'Errore durante il caricamento dati tramite web-service.';
						|pl = 'Błąd podczas wyeksportowania danych za pośrednictwem serwisu internetowego.';
						|tr = 'Web servis üzerinden verilerin dışa aktarılması sırasında hata.'");
		If ValueIsFilled(BackgroundJob.DetailErrorDescription) Then
			Message = BackgroundJob.DetailErrorDescription;
		EndIf;
		
		WriteLogEvent(DataExchangeServer.ExportDataToFilesTransferServiceEventLogEvent(),
			EventLogLevel.Error, , , Message);
		
		Raise Message;
	EndIf;
	
EndProcedure

Procedure ExportDataInClientServerModeInternalPublication(ExchangePlanName,
		InfobaseNodeCode, TaskID__, DataArea)
			
	ProcedureParameters = New Array;
	ProcedureParameters.Add(ExchangePlanName);
	ProcedureParameters.Add(InfobaseNodeCode);
	ProcedureParameters.Add(TaskID__);
	
	Var_Key = TaskID__;
	
	JobParameters = New Structure;
	JobParameters.Insert("Key", Left(Var_Key, 120));
	JobParameters.Insert("MethodName"    , "DataExchangeInternalPublication.ExportToFileTransferServiceForInfobaseNode");
	JobParameters.Insert("DataArea", DataArea);
	JobParameters.Insert("Use", True);
	JobParameters.Insert("Parameters", ProcedureParameters);
	JobParameters.Insert("RestartCountOnFailure", 3);
	JobParameters.Insert("RestartIntervalOnFailure", 900);
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	ModuleJobsQueue.AddJob(JobParameters);
	
EndProcedure

Procedure RunImportDataInClientServerMode(ExchangePlanName,
													InfobaseNodeCode,
													FileID,
													TimeConsumingOperation,
													OperationID,
													TimeConsumingOperationAllowed)
	
													
	BackgroundJobKey = ExportImportDataBackgroundJobKey(ExchangePlanName,
		InfobaseNodeCode,
		NStr("vi = 'Kết nhập';
			|ru = 'Загрузка';
			|en = 'Import'; fa = 'ورود اطلاعات';
			|it = 'Загрузка';
			|pl = 'Pobieranie';
			|tr = 'İçe aktar'"));
	
	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise NStr("vi = 'Đang thực hiện đồng bộ dữ liệu.';
					|ru = 'Синхронизация данных уже выполняется.';
					|en = 'Data synchronization is already running.'; fa = 'Data synchronization is already running.';
					|it = 'Sincronizzazione dati già eseguita';
					|pl = 'Synchronizacja danych jest już w toku.';
					|tr = 'Verilerin senkronizasyonu zaten yürütülüyor.'");
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ExchangePlanName", ExchangePlanName);
	ProcedureParameters.Insert("InfobaseNodeCode", InfobaseNodeCode);
	ProcedureParameters.Insert("FileID", FileID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kết nhập dữ liệu thông qua Web-service.';
														|ru = 'Загрузка данных через веб-сервис.';
														|en = 'Import data via web service.'; fa = 'Import data via web service.';
														|it = 'Caricamento dati tramite web-service';
														|pl = 'Pobieranie danych za pośrednictwem serwisu internetowego.';
														|tr = 'Web-istemci üzerinden verilerin yüklemesi.'");
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1 = Not TimeConsumingOperationAllowed;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeWebService.ImportFromFileTransferServiceForInfobaseNode",
		ProcedureParameters,
		ExecutionParameters);
		
	If BackgroundJob.Status = "Running" Then
		OperationID = String(BackgroundJob.JobID);
		TimeConsumingOperation = True;
		Return;
	ElsIf BackgroundJob.Status = "Completed2" Then
		TimeConsumingOperation = False;
		Return;
	Else
		
		Message = NStr("vi = 'Lỗi khi kết nhập dữ liệu thông qua Web-service.';
						|ru = 'Ошибка при загрузке данных через веб-сервис.';
						|en = 'Error importing data via web service.'; fa = 'Error importing data via web service.';
						|it = 'Errore durante il caricamento dati tramite web-service.';
						|pl = 'Błąd podczas pobierania danych za pośrednictwem serwisu internetowego.';
						|tr = 'Web-istemci üzerinden verilerin yükleme hatası.'");
		If ValueIsFilled(BackgroundJob.DetailErrorDescription) Then
			Message = BackgroundJob.DetailErrorDescription;
		EndIf;
		
		WriteLogEvent(DataExchangeServer.ImportDataFromFilesTransferServiceEventLogEvent(),
			EventLogLevel.Error, , , Message);
		
		Raise Message;
	EndIf;
	
EndProcedure

Procedure ImportDataInClientServerModeInternalPublication(ExchangePlanName,
		InfobaseNodeCode, TaskID__, FileID, DataArea)
		
	ProcedureParameters = New Array;
	ProcedureParameters.Add(ExchangePlanName);
	ProcedureParameters.Add(InfobaseNodeCode);
	ProcedureParameters.Add(TaskID__);
	ProcedureParameters.Add(FileID);
	
	Var_Key = TaskID__;
	
	JobParameters = New Structure;
	JobParameters.Insert("Key", Left(Var_Key, 120));
	JobParameters.Insert("MethodName"    , "DataExchangeInternalPublication.ImportFromFileTransferServiceForInfobaseNode");
	JobParameters.Insert("DataArea", DataArea);
	JobParameters.Insert("Use", True);
	JobParameters.Insert("Parameters", ProcedureParameters);
	JobParameters.Insert("RestartCountOnFailure", 3);
	JobParameters.Insert("RestartIntervalOnFailure", 900);
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	ModuleJobsQueue.AddJob(JobParameters);
	
EndProcedure

Function ExportImportDataBackgroundJobKey(ExchangePlan, NodeCode, Action)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'SơĐồTraoĐổi:%1 MãNút:%2 ThaoTác:%3';
			|ru = 'ПланОбмена:%1 КодУзла:%2 Действие:%3';
			|en = 'ExchangePlan:%1 NodeCode:%2 Action:%3'; fa = 'ExchangePlan:%1 NodeCode:%2 Action:%3';
			|it = 'PianoScambio: %1 CodiceNodo:%2 Attività: %3';
			|pl = 'PlanWymiany:%1 KodWęzła:%2 Działanie:%3';
			|tr = 'ПланОбмена:%1 КодУзла:%2 İşlem:%3'"),
		ExchangePlan,
		NodeCode,
		Action);
	
EndFunction

Function TemporaryExportDirectory(Val SessionID)
	
	SetPrivilegedMode(True);
	
	TempDirectory = "{SessionID}";
	TempDirectory = StrReplace(TempDirectory, "SessionID", String(SessionID));
	
	Result = CommonClientServer.GetFullFileName(DataExchangeServer.TempFilesStorageDirectory(), TempDirectory);
	
	Return Result;
	
EndFunction

Function FindPartFile(Val Directory, Val FileNumber)
	
	For DigitsCount = NumberDigitsCount(FileNumber) To 5 Do
		
		FormatString = StringFunctionsClientServer.SubstituteParametersToString("ND=%1; NLZ=; NG=0", String(DigitsCount));
		
		FileName = StringFunctionsClientServer.SubstituteParametersToString("data.zip.%1", Format(FileNumber, FormatString));
		
		FilesNames = FindFiles(Directory, FileName);
		
		If FilesNames.Count() > 0 Then
			
			Return FilesNames;
			
		EndIf;
		
	EndDo;
	
	Return New Array;
	
EndFunction

Function GetPartFileName(PartNumber)
	
	Result = "data.zip.[n]";
	
	Return StrReplace(Result, "[n]", Format(PartNumber, "NG=0"));
	
EndFunction

Function NumberDigitsCount(Val Number)
	
	Return StrLen(Format(Number, "NFD=0; NG=0"));
	
EndFunction

Procedure MoveTheMessageFileForTheFileIB(FileID)
	
	If Not Common.FileInfobase() Then
		Return;
	EndIf;
		
	QueryText =
		"SELECT
		|	DataExchangeMessages.MessageFileName AS FileName
		|FROM
		|	InformationRegister.DataExchangeMessages AS DataExchangeMessages
		|WHERE
		|	DataExchangeMessages.MessageID = &MessageID";

	Query = New Query;
	Query.SetParameter("MessageID", String(FileID));
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	FileName = Selection.FileName;
	MessageFileName = CommonClientServer.GetFullFileName(DataExchangeServer.TempFilesStorageDirectory(), FileName);
	
	DirectoryName = DataExchangeServer.TheNameOfTheDirectoryToMapToTheFileInformationSystem();
	
	Directory = New File(DirectoryName);
	If Not Directory.Exists() Then
		CreateDirectory(DirectoryName);
	EndIf;

	NameOfTheNewMessageFile = DataExchangeServer.TheFullNameOfTheFileToBeMappedIsFileInformationSystem(FileName);
	
	MoveFile(MessageFileName, NameOfTheNewMessageFile);
	
EndProcedure

Procedure SignInToDataArea(DataArea)
	
	If DataArea = 0 
		Or Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");

	ModuleSaaSTechnology = Common.CommonModule("CloudTechnology");
	CTLVersion = ModuleSaaSTechnology.LibraryVersion();

	If CommonClientServer.CompareVersions(CTLVersion, "2.0.7.46") >= 0 Then
		ModuleSaaSOperations.SignInToDataArea(DataArea); //ACC:287
	Else
		ModuleSaaSOperations.SetSessionSeparation(True, DataArea); //ACC:222
	EndIf;
	
EndProcedure

Procedure SignOutOfDataArea(DataArea)
	
	If DataArea = 0 
		Or Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");

	ModuleSaaSTechnology = Common.CommonModule("CloudTechnology");
	CTLVersion = ModuleSaaSTechnology.LibraryVersion();

	If CommonClientServer.CompareVersions(CTLVersion, "2.0.7.46") >= 0 Then
		ModuleSaaSOperations.SignOutOfDataArea(); //ACC:287
	Else
		ModuleSaaSOperations.SetSessionSeparation(False); //ACC:222
	EndIf;
	
EndProcedure

#EndRegion

