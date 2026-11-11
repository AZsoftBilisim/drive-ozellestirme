///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// The function downloads the file from the file transfer service by the passed ID.
//
// Parameters:
//  FileID       - UUID - an ID of the file being received.
//  InfobaseNode   - ExchangePlanRef - The exchange plan node that should receive the file.
//  PartSize              - Number - Chunk size in kilobytes. If the passed value is 0,
//                             the file is not split into chunks.
//  AuthenticationParameters - Structure: ServiceAddress, UserName, UserPassword.
//
// Returns:
//  String - The path to the received file.
//
Function GetFileFromStorageInService(Proxy, Val FileID, Val InfobaseNode = Undefined,
	Val PartSize = 1024, Val DataArea = 0) Export
	
	// Function return value.
	ResultFileName = "";
	
	SessionID = Undefined;
	PartCount    = Undefined;
	
	PrepareFileForReceipt(Proxy, FileID, PartSize, SessionID, PartCount, DataArea);
	
	FilesNames = New Array;
	
	TempFilesStorageDirectory = DataExchangeServer.TempFilesStorageDirectory();
	
	BuildDirectory = CommonClientServer.GetFullFileName(TempFilesStorageDirectory, "{" + String(New UUID) + "}");
	CreateDirectory(BuildDirectory);
	
	FileNameTemplate = "data.zip.[n]";
	
	// Log exchange events.
	If ValueIsFilled(InfobaseNode) Then
		
		ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
			InfobaseNode, Enums.ActionsOnExchange.DataExport);

		ExchangeSettingsStructure.EventLogMessageKey = DataExchangeServer.EventLogMessageKey(
			InfobaseNode, Enums.ActionsOnExchange.DataImport);
		
		Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Bắt đầu nhận thông điệp trao đổi từ Internet (số phần trong tệp %1).';
				|ru = 'Начало получения сообщения обмена из Интернета (количество частей файла %1).';
				|en = 'Start receiving an exchange message from the Internet. The message is split into %1 parts.'; fa = 'Start receiving an exchange message from the Internet. The message is split into %1 parts.';
				|it = 'Inizio della ricezione del messaggio di scambio da internet (numero di parti nel file %1).';
				|pl = 'Początek otrzymania komunikatu wymiany z Internetu (ilość części pliku %1).';
				|tr = 'İnternet değişim mesajının alınmaya başlaması (dosya parçalarının sayısı%1).'"),
			Format(PartCount, "NZ=0; NG=0"));
			
		DataExchangeServer.WriteEventLogDataExchange(Comment, ExchangeSettingsStructure);
		
	EndIf;
	
	For PartNumber = 1 To PartCount Do
		
		PartData = Undefined; // BinaryData
		
		Try
			GetFileChunk(Proxy, SessionID, PartNumber, PartData, DataArea);
		Except
			Proxy.ReleaseFile(SessionID);
			Raise;
		EndTry;
		
		FileName = StrReplace(FileNameTemplate, "[n]", Format(PartNumber, "NG=0"));
		PartFileName = CommonClientServer.GetFullFileName(BuildDirectory, FileName);
		
		PartData.Write(PartFileName);
		FilesNames.Add(PartFileName);
		
	EndDo;
	
	PartData = Undefined;
	
	Proxy.ReleaseFile(SessionID);
	
	ArchiveName = CommonClientServer.GetFullFileName(BuildDirectory, "data.zip");
	
	MergeFiles(FilesNames, ArchiveName);
		
	Dearchiver = New ZipFileReader(ArchiveName);
	If Dearchiver.Items.Count() = 0 Then
		Try
			DeleteFiles(BuildDirectory);
		Except
			WriteLogEvent(TempFileDeletionEventLogEvent(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		Raise(NStr("vi = 'Tệp sao lưu không chứa dữ liệu.';
					|ru = 'Файл архива не содержит данных.';
					|en = 'The archive file is empty.'; fa = 'The archive file is empty.';
					|it = 'Il file d''archivio non contiene dati.';
					|pl = 'Plik archiwum nie zawiera danych.';
					|tr = 'Arşiv dosyası veri içermemektedir.'"));
	EndIf;
	
	// Log exchange events.
	ArchiveFile1 = New File(ArchiveName);
	
	If ValueIsFilled(InfobaseNode) Then
	
		Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kết thúc nhận thông điệp trao đổi từ Internet (dung lượng thông điệp nén trao đổi %1 Mb).';
				|ru = 'Окончание получения сообщения обмена из Интернета (размер сжатого сообщения обмена %1 Мб).';
				|en = 'Complete receiving an exchange message from the Internet. Compressed message size: %1 MB.'; fa = 'Complete receiving an exchange message from the Internet. Compressed message size: %1 MB.';
				|it = 'Fine della ricezione del messaggio di scambio da internet (dimensione del messaggio di scambio compresso %1 Mb).';
				|pl = 'Zakończenie otrzymania komunikatu wymiany z Internetu (rozmiar komunikatu skompresowanego wymiany %1 Mb).';
				|tr = 'İnternetten alınan değişim mesajının sonu (sıkıştırılmış bir değişim mesajının boyutu %1MB''dir).'"),
			Format(Round(ArchiveFile1.Size() / 1024 / 1024, 3), "NZ=0; NG=0"));
			
		DataExchangeServer.WriteEventLogDataExchange(Comment, ExchangeSettingsStructure);
	
	EndIf;
	
	ArchiveItem = Dearchiver.Items.Get(0);
	FileName = CommonClientServer.GetFullFileName(BuildDirectory, ArchiveItem.Name);
	
	Dearchiver.Extract(ArchiveItem, BuildDirectory);
	Dearchiver.Close();
	
	File = New File(FileName);
	
	TempFilesStorageDirectory = DataExchangeServer.TempFilesStorageDirectory();
	
	TempDirectory = CommonClientServer.GetFullFileName(TempFilesStorageDirectory, "{" + String(New UUID) + "}"); //ACC:441 - The directory is deleted when the peer infobase receives the exchange data
	CreateDirectory(TempDirectory);
	
	ResultFileName = CommonClientServer.GetFullFileName(TempDirectory, File.Name);
	
	MoveFile(FileName, ResultFileName);
	
	Try
		DeleteFiles(BuildDirectory);
	Except
		WriteLogEvent(TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
		
	Return ResultFileName;
	
EndFunction

// Passes the specified file to the file transfer service.
//
// Parameters:
//  Proxy                   - 
//  ExchangeSettingsStructure - Structure - a structure with all necessary data and objects to execute the exchange.
//  FileName                 - String - Path to the transferred file.
//  InfobaseNode - ExchangePlanRef - The recipient exchange node. 
//  PartSizeKB            - Number - part size in kilobytes. If the passed value is 0,
//                             the file is not split into parts.
//  FileID       - UUID - The id of the file being uploaded to the service.
//
// Returns:
//  UUID  - The id of the file in the file transfer service.
//
Function PutFileInStorageInService(Proxy, Val FileName, 
	Val PartSizeKB = 1024, FileID = Undefined, DataArea = 0) Export
	
	If Proxy = Undefined Then
		
		Raise NStr("vi = 'Chưa xác định WS-proxy truyền tệp kết xuất sang cơ sở đích.
			|Hãy liên hệ với người quản trị.';
			|ru = 'Не определен WS-прокси передачи файла выгрузки в базу приемник. 
			|Обратитесь к администратору.';
			|en = 'The WS proxy of transferring the export file to the destination infobase is not defined. 
			|Contact the administrator.'; fa = 'The WS proxy of transferring the export file to the destination infobase is not defined. 
			|Contact the administrator.';
			|it = 'Non è indicato il proxy-WS di trasferimento file di esportazione nella base di destinazione. 
			|Rivolgersi all''amministratore.';
			|pl = 'Nie określono proxy WS przekazania pliku eksportu do bazy odbiorcy. 
			|Zwróć się do administratora.';
			|tr = 'Yükleme dosyasını hedef tabanına aktarmak için WS-proxy''si tanımlı değil. 
			|Yöneticinize başvurun.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	TempFilesStorageDirectory = DataExchangeServer.TempFilesStorageDirectory();
	
	FilesDirectory = CommonClientServer.GetFullFileName(TempFilesStorageDirectory, "{" + String(New UUID) + "}");
	CreateDirectory(FilesDirectory);
	
	// Archive the file.
	SharedFileName = CommonClientServer.GetFullFileName(FilesDirectory, "data.zip");
	Archiver = New ZipFileWriter(SharedFileName,,,, ZIPCompressionLevel.Maximum);
	Archiver.Add(FileName);
	Archiver.Write();
	
	// Splitting a file into parts.
	SessionID = New UUID;
	
	TheSizeOfThePartInBytes = PartSizeKB * 1024;
	FilesNames = SplitFile(SharedFileName, TheSizeOfThePartInBytes);
	
	PartCount = FilesNames.Count();
	For PartNumber = 1 To PartCount Do
		
		PartFileName = FilesNames[PartNumber - 1];
		FileData = New BinaryData(PartFileName);
		PutFileChunk(Proxy, SessionID, PartNumber, FileData, DataArea);
		
	EndDo;
	
	Try
		DeleteFiles(FilesDirectory);
	Except
		WriteLogEvent(TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	AssembleFileFromParts(Proxy, SessionID, PartCount, FileID, DataArea);
	
	Return FileID;
	
EndFunction

Function GetWSProxyByConnectionParameters(
					SettingsStructure,
					ErrorMessageString = "",
					UserMessage = "",
					ProbingCallRequired = False) Export
	
	Try
		CheckWSProxyAddressFormatCorrectness(SettingsStructure.WSWebServiceURL);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;

	Try
		CheckProhibitedCharsInWSProxyUsername(SettingsStructure.WSUserName);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;
	
	WSDLLocation = "[WebServiceURL]/ws/[ServiceName]?wsdl";
	WSDLLocation = StrReplace(WSDLLocation, "[WebServiceURL]", SettingsStructure.WSWebServiceURL);
	WSDLLocation = StrReplace(WSDLLocation, "[ServiceName]",    SettingsStructure.WSServiceName);
	
	ConnectionParameters = Common.WSProxyConnectionParameters();
	ConnectionParameters.WSDLAddress = WSDLLocation;
	ConnectionParameters.NamespaceURI = SettingsStructure.WSServiceNamespaceURL;
	ConnectionParameters.ServiceName = SettingsStructure.WSServiceName;
	ConnectionParameters.UserName = SettingsStructure.WSUserName; 
	ConnectionParameters.Password = SettingsStructure.WSPassword;
	ConnectionParameters.Timeout = SettingsStructure.WSTimeout;
	ConnectionParameters.ProbingCallRequired = ProbingCallRequired;
	
	Try
		WSProxy = Common.CreateWSProxy(ConnectionParameters);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessageString);
		Return Undefined;
	EndTry;
	
	Return WSProxy;
EndFunction

Function WSProxy(ConnectionParameters, ErrorMessage = "", UserMessage = "") Export
	
	Try
		CheckWSProxyAddressFormatCorrectness(ConnectionParameters.WebServiceAddress);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessage);
		Return Undefined;
	EndTry;

	Try
		CheckProhibitedCharsInWSProxyUsername(ConnectionParameters.UserName);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessage);
		Return Undefined;
	EndTry;

	Try
		SettingsStructure = New Structure;
		SettingsStructure.Insert("WSWebServiceURL", ConnectionParameters.WebServiceAddress);
		SettingsStructure.Insert("WSUserName", ConnectionParameters.UserName);
		SettingsStructure.Insert("WSPassword", ConnectionParameters.Password);
		CorrespondentVersions = DataExchangeCached.CorrespondentVersions(SettingsStructure);
	Except
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		Return Undefined;
	EndTry;
		
	InterfaceVersion = MaximumGeneralVersionOfExchangeInterface(CorrespondentVersions);
	
	If InterfaceVersion = "0.0.0.0" Then
		VersionForAddress = "";
	Else
		VersionForAddress = "_" + StrReplace(InterfaceVersion, ".", "_");
	EndIf;
	
	DataExchangeServer.DeleteInsignificantCharactersInConnectionSettings(ConnectionParameters);
	
	ConnectionParameters.Insert("NamespaceURI", "http://www.1c.ru/SSL/Exchange" + VersionForAddress);
	ConnectionParameters.Insert("ServiceName", "Exchange" + VersionForAddress);
	
	If Not ConnectionParameters.Property("Timeout") Then
		ConnectionParameters.Insert("Timeout", 600);
	EndIf;
	
	If Not ConnectionParameters.Property("ProbingCallRequired") Then
		ConnectionParameters.Insert("ProbingCallRequired", True);
	EndIf;
		
	WSDLLocation = "[WebServiceURL]/ws/[ServiceName]?wsdl";
	WSDLLocation = StrReplace(WSDLLocation, "[WebServiceURL]", ConnectionParameters.WebServiceAddress);
	WSDLLocation = StrReplace(WSDLLocation, "[ServiceName]",    ConnectionParameters.ServiceName);
	
	ConnectionParameters.Insert("WSDLAddress", WSDLLocation);
	
	ConnectionParameters.Insert("EndpointName");
	ConnectionParameters.Insert("UseOSAuthentication", False);
	ConnectionParameters.Insert("Location");
	ConnectionParameters.Insert("SecureConnection");
	
	Try
		WSProxy = Common.CreateWSProxy(ConnectionParameters);
	Except
		UserMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EstablishWebServiceConnectionEventLogEvent(), EventLogLevel.Error,,, ErrorMessage);
		Return Undefined;
	EndTry;
	
	Return WSProxy;
	
EndFunction

Function SetupStatus(Proxy, SettingsStructure, DataArea = 0, Cancel = False, ErrorMessageString = "") Export
	
	If DataExchangeServer.IsXDTOExchangePlan(SettingsStructure.ExchangePlanName) Then
		
		NodeAlias = DataExchangeServer.PredefinedNodeAlias(SettingsStructure.InfobaseNode);
		If ValueIsFilled(NodeAlias) Then
			// Checking a setting with an old ID (prefix).
			SettingsStructureOfPredefined = Common.CopyRecursive(SettingsStructure, False); // Structure
			SettingsStructureOfPredefined.Insert("CurrentExchangePlanNodeCode1", NodeAlias);
			SetupStatus = SynchronizationSetupStatusInCorrespondent(Proxy, SettingsStructureOfPredefined);
				
			If Not SetupStatus.SettingExists Then
				If ObsoleteExchangeSettingsOptionInCorrespondent(
						Proxy, SetupStatus, SettingsStructure, NodeAlias, Cancel, ErrorMessageString)
					Or Cancel Then
					Return SetupStatus;
				EndIf;
			Else
				SettingsStructure.CurrentExchangePlanNodeCode1 = NodeAlias;
				Return SetupStatus;
			EndIf;
		EndIf;
		
		SetupStatus = SynchronizationSetupStatusInCorrespondent(Proxy, SettingsStructure, DataArea);
			
		If Not SetupStatus.SettingExists Then
			If ObsoleteExchangeSettingsOptionInCorrespondent(
					Proxy, SetupStatus, SettingsStructure, SettingsStructure.CurrentExchangePlanNodeCode1, Cancel, ErrorMessageString)
				Or Cancel Then
				Return SetupStatus;
			EndIf;
		EndIf;
		
	Else
		
		SetupStatus = SynchronizationSetupStatusInCorrespondent(Proxy, SettingsStructure, DataArea);
			
	EndIf;
	
	If Not SetupStatus.SettingExists Then
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy tùy chỉnh đồng bộ dữ liệu ""%1"" với tên định danh ""%2"".';
				|ru = 'Не найдена настройка синхронизации данных ""%1"" с идентификатором ""%2"".';
				|en = 'Data synchronization setting with ID ""%2"" is not found. Exchange plan: %1.'; fa = 'Data synchronization setting with ID ""%2"" is not found. Exchange plan: %1.';
				|it = 'Non è stata trovata l''impostazione di sincronizzazione dei dati ""%1"" con ID ""%2"".';
				|pl = 'Nie znaleziono konfiguracji synchronizacji danych ""%1"" z identyfikatorem ""%2"".';
				|tr = '""%2"" kimliğine sahip ""%1"" veri senkronizasyon ayarı bulunamadı.'"),
			SettingsStructure.ExchangePlanName,
			SettingsStructure.CurrentExchangePlanNodeCode1);
		Cancel = True;
	EndIf;
	
	Return SetupStatus;
	
EndFunction

Procedure ExportToFileTransferServiceForInfobaseNode(ProcedureParameters, StorageAddress) Export
	
	ExchangePlanName            = ProcedureParameters["ExchangePlanName"];
	InfobaseNodeCode = ProcedureParameters["InfobaseNodeCode"];
	FileID        = ProcedureParameters["FileID"];
	
	UseCompression = ProcedureParameters.Property("UseCompression") And ProcedureParameters["UseCompression"];
	
	SetPrivilegedMode(True);
	
	MessageFileName = CommonClientServer.GetFullFileName(
		DataExchangeServer.TempFilesStorageDirectory(),
		DataExchangeServer.UniqueExchangeMessageFileName());
	
	DataExchangeParameters = DataExchangeServer.DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = MessageFileName;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataExport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	DataExchangeServer.ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
	NameOfFileToPutInStorage = MessageFileName;
	If UseCompression Then
		NameOfFileToPutInStorage = CommonClientServer.GetFullFileName(
			DataExchangeServer.TempFilesStorageDirectory(),
			DataExchangeServer.UniqueExchangeMessageFileName("zip"));
		
		Archiver = New ZipFileWriter(NameOfFileToPutInStorage, , , , ZIPCompressionLevel.Maximum);
		Archiver.Add(MessageFileName);
		Archiver.Write();
		
		DeleteFiles(MessageFileName);
	EndIf;
	
	DataExchangeServer.PutFileInStorage(NameOfFileToPutInStorage, FileID);
	
EndProcedure

Procedure ImportFromFileTransferServiceForInfobaseNode(ProcedureParameters, StorageAddress) Export
	
	ExchangePlanName            = ProcedureParameters["ExchangePlanName"];
	InfobaseNodeCode = ProcedureParameters["InfobaseNodeCode"];
	FileID        = ProcedureParameters["FileID"];
	
	SetPrivilegedMode(True);
	
	TempFileName = DataExchangeServer.GetFileFromStorage(FileID);
	
	DataExchangeParameters = DataExchangeServer.DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = TempFileName;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataImport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	Try
		DataExchangeServer.ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		DeleteFiles(TempFileName);
		Raise ErrorPresentation;
	EndTry;
	
	DeleteFiles(TempFileName);
EndProcedure

// An analog of the "UploadData" operation
Procedure RunDataExport(Proxy, ExchangeSettingsStructure, ExchangeParameters, DataArea = 0) Export
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.UploadData(
			ExchangeSettingsStructure.CorrespondentExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			ExchangeParameters.FileID,
			ExchangeParameters.TimeConsumingOperation,
			ExchangeParameters.OperationID,
			ExchangeParameters.TimeConsumingOperationAllowed,
			DataArea);

	Else
					
		Proxy.UploadData(
			ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			ExchangeParameters.FileID,
			ExchangeParameters.TimeConsumingOperation,
			ExchangeParameters.OperationID,
			ExchangeParameters.TimeConsumingOperationAllowed);
			
	EndIf;

EndProcedure

// An analog of the "DownloadData" operation
Procedure RunDataImport(Proxy, ExchangeSettingsStructure, ExchangeParameters, FileIDAsString, DataArea = 0) Export
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.DownloadData(
			ExchangeSettingsStructure.CorrespondentExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			FileIDAsString,
			ExchangeParameters.TimeConsumingOperation,
			ExchangeParameters.OperationID,
			ExchangeParameters.TimeConsumingOperationAllowed,
			DataArea);
		
	Else
		
		Proxy.DownloadData(
			ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			FileIDAsString,
			ExchangeParameters.TimeConsumingOperation,
			ExchangeParameters.OperationID,
			ExchangeParameters.TimeConsumingOperationAllowed);
			
	EndIf;

EndProcedure

// Matches the GetIBParameters web service operation.

Function GetParametersOfInfobase(Proxy, ExchangePlanName, NodeCode, ErrorMessage, DataArea = 0, AdditionalParameters = Undefined) Export
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_2(ProxyVersion) Then
		
		If AdditionalParameters = Undefined Then
			AdditionalParameters = New Structure;
		EndIf;
		
		AdditionalXDTOParameters = XDTOSerializer.WriteXDTO(AdditionalParameters);
		
		Return Proxy.GetIBParameters(ExchangePlanName, NodeCode, ErrorMessage, DataArea, AdditionalXDTOParameters);
		
	ElsIf Version3_0_2_1(ProxyVersion) Then
		
		Return Proxy.GetIBParameters(ExchangePlanName, NodeCode, ErrorMessage, DataArea);
			
	Else
		
		Return Proxy.GetIBParameters(ExchangePlanName, NodeCode, ErrorMessage);
		
	EndIf;
	
EndFunction 

// An analog of the "PutMessageForDataMatching" operation
Procedure PutMessageForDataMapping(Proxy, ExchangeSettingsStructure, FileIDAsString, DataArea = 0) Export
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.PutMessageForDataMatching(ExchangeSettingsStructure.CorrespondentExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			FileIDAsString,
			DataArea);
		
	Else
		
		Proxy.PutMessageForDataMatching(ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			FileIDAsString);
	
	EndIf;
	
EndProcedure

// An analog of the "RemoveExchangeNode" operation
Procedure DeleteExchangeNode(Proxy, ExchangeSettingsStructure, DataArea = 0) Export
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.RemoveExchangeNode(ExchangeSettingsStructure.CorrespondentExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			DataArea);
			
	Else
	
		Proxy.RemoveExchangeNode(ExchangeSettingsStructure.ExchangePlanName, ExchangeSettingsStructure.CurrentExchangePlanNodeCode1);
		
	EndIf;
	
EndProcedure

// An analog of the "CreateExchangeNode" operation
Procedure CreateExchangeNode(Proxy, ConnectionParameters, DataArea = 0) Export
	
	ProxyVersion = ProxyVersion(Proxy);
	
	Serializer = New XDTOSerializer(Proxy.XDTOFactory);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.CreateExchangeNode(Serializer.WriteXDTO(ConnectionParameters), DataArea);
		
	Else
		
		Proxy.CreateExchangeNode(Serializer.WriteXDTO(ConnectionParameters));
		
	EndIf;
	
EndProcedure

// Returns:
//   String
//
Function TempFileDeletionEventLogEvent() Export
	
	Return NStr("vi = 'Trao đổi dữ liệu.Xóa tệp tạm thời';
				|ru = 'Обмен данными.Удаление временного файла';
				|en = 'Data exchange.Delete temporary file'; fa = 'Data exchange.Delete temporary file';
				|it = 'Scambio di dati. Cancellazione del file temporaneo';
				|pl = 'Wymiana danych.Usunięcie pliku tymczasowego';
				|tr = 'Veri alışverişi. Geçici dosyayı kaldırma'", Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//   String
//
Function EventLogEventTransportChangedOnWS() Export
	
	Return NStr("vi = 'Trao đổi dữ liệu.Thay đổi truyền đến WS';
				|ru = 'Обмен данными.Изменение транспорта на WS';
				|en = 'Data exchange.Change transport to WS'; fa = 'Data exchange.Change transport to WS';
				|it = 'Scambio dati.Modifica trasporto in WS';
				|pl = 'Wymiana danych Zmiana transportu na WS';
				|tr = 'Veri değişimi.WS''de araç değişimi'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#Region Private

// Returns:
//   String
//
Function EstablishWebServiceConnectionEventLogEvent()
	
	Return NStr("vi = 'Trao đổi dữ liệu.Thiết lập kết nối đến Web-service';
				|ru = 'Обмен данными.Установка подключения к web-сервису';
				|en = 'Data exchange.Establish web service connection'; fa = 'Data exchange.Establish web service connection';
				|it = 'Scambio di dati. Instaurazione di una connessione al web-service';
				|pl = 'Wymiana danych.Instalacja podłączenia do web-serwisu';
				|tr = 'Veri alışverişi. Web servisine bağlanma'", Common.DefaultLanguageCode());
	
EndFunction

Procedure WaitingForTheOperationToComplete(ExchangeSettingsStructure, ExchangeParameters, Proxy, ActionWhenExchangingInThisInformationSystem = Undefined) Export
	
	If ExchangeParameters.TheTimeoutOnTheServer = 0 Then
		
		If ActionWhenExchangingInThisInformationSystem <> Undefined Then
			
			// For this infobase, "Import". Therefore, for the peer infobase, "Export".
			If ActionWhenExchangingInThisInformationSystem = Enums.ActionsOnExchange.DataImport Then
				
				ActionInTheCorrespondentLine = NStr("vi = 'kết xuất';
													|ru = 'выгрузка';
													|en = 'export'; fa = 'export';
													|it = 'upload';
													|pl = 'eksport';
													|tr = 'dışa aktar'", Common.DefaultLanguageCode());
				
			Else
				
				ActionInTheCorrespondentLine = NStr("vi = 'kết nhập';
													|ru = 'загрузка';
													|en = 'import'; fa = 'import';
													|it = 'download';
													|pl = 'import';
													|tr = 'içe aktar'", Common.DefaultLanguageCode());
				
			EndIf;
			
			MessageTemplate = NStr("vi = 'Đợi thực hiện giao dịch (%1 dữ liệu trong cơ sở trao đổi tin)...';
									|ru = 'Ожидание выполнения операции (%1 данных в базе-корреспонденте)...';
									|en = 'Waiting for the operation to be executed (%1 of the data in the peer infobase)…'; fa = 'Waiting for the operation to be executed (%1 of the data in the peer infobase)…';
									|it = 'Attesa di esecuzione operazione (%1 dati nella base corrispondente)...';
									|pl = 'Oczekiwanie wykonania operacji (%1 danych w bazie korespondencie)...';
									|tr = 'İşlemin yürütülmesi bekleniyor (muhabir veri tabanındaki %1veriler)...'", Common.DefaultLanguageCode());
			DataExchangeServer.WriteEventLogDataExchange(StrTemplate(MessageTemplate, ActionInTheCorrespondentLine), ExchangeSettingsStructure);
			
		EndIf;
		
		Return;
		
	EndIf;
	
	While ExchangeParameters.TimeConsumingOperation Do // Replace recursion.
		
		DataExchangeServer.Pause(ExchangeParameters.TheTimeoutOnTheServer);
		
		ErrorMessageString = "";
	
		ActionState = GetLongRunningOperationStatus(Proxy, ExchangeParameters, ErrorMessageString);
			
		If ActionState = "Active" Then
			
			ExchangeParameters.TheTimeoutOnTheServer = Min(ExchangeParameters.TheTimeoutOnTheServer + 30, 180);
			
		ElsIf ActionState = "Completed" Then
			
			ExchangeParameters.TheTimeoutOnTheServer = 15;
			ExchangeParameters.TimeConsumingOperation = False; 
			ExchangeParameters.OperationID = Undefined;
			
		Else
			
			Raise StrTemplate(NStr("vi = 'Lỗi trong cơ sở trao đổi dữ liệu:%1%2';
									|ru = 'Ошибка в базе-корреспонденте:%1 %2';
									|en = 'Peer infobase error: %1 %2'; fa = 'Peer infobase error: %1 %2';
									|it = 'Errore nella base corrispondente: %1 %2';
									|pl = 'Błąd w bazie korespondencie:%1 %2';
									|tr = 'Muhabir tabanındaki hata: %1%2'"), Chars.LF, ErrorMessageString);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function Version3_0_2_1(ProxyVersion)
	
	Return CommonClientServer.CompareVersions(ProxyVersion, "3.0.2.1") >= 0;
		
EndFunction

Function Version3_0_2_2(ProxyVersion)
	
	Return CommonClientServer.CompareVersions(ProxyVersion, "3.0.2.2") >= 0;
		
EndFunction

Function ProxyVersion(Proxy)

	Name = Proxy.Endpoint.Name;
	Version = StrReplace(Name, "Exchange_", "");
	Version = StrReplace(Version, "Soap", "");
	Version = StrReplace(Version, "_", ".");
	
	Return Version;
	
EndFunction

// An analog of the "GetContinuousOperationStatus" operation
Function GetLongRunningOperationStatus(Proxy, ExchangeParameters, ErrorMessageString, DataArea = 0)

	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Return Proxy.GetContinuousOperationStatus(ExchangeParameters.OperationID,
			ErrorMessageString, 
			DataArea);
		
	Else
	
		Return Proxy.GetContinuousOperationStatus(ExchangeParameters.OperationID, ErrorMessageString);
		
	EndIf;
	
EndFunction

// An analog of the "PrepareGetFile" operation
Function PrepareFileForReceipt(Proxy, FileID, PartSize, SessionID, PartCount, DataArea = 0)
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Return Proxy.PrepareGetFile(FileID,
			PartSize,
			SessionID,
			PartCount, 
			DataArea);
		
	Else
	
		Return Proxy.PrepareGetFile(FileID, PartSize, SessionID, PartCount);
	
	EndIf;
	
EndFunction

// An analog of the "GetFilePart" operation
Procedure GetFileChunk(Proxy, SessionID, PartNumber, PartData, DataArea = 0)
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.GetFilePart(SessionID,
			PartNumber, PartData,
			DataArea);
			
	Else
	
		Proxy.GetFilePart(SessionID, PartNumber, PartData);
		
	EndIf;
	
EndProcedure

// An analog of the "PutFilePart" operation
Procedure PutFileChunk(Proxy, SessionID, PartNumber, FileData, DataArea = 0)
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.PutFilePart(SessionID, PartNumber, FileData,
			DataArea);
		
	Else
	
		Proxy.PutFilePart(SessionID, PartNumber, FileData);
		
	EndIf;
	
EndProcedure

// An analog of the "SaveFileFromParts" operation
Procedure AssembleFileFromParts(Proxy, SessionID, PartCount, FileID, DataArea = 0)
	
	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Proxy.SaveFileFromParts(SessionID, PartCount, FileID, DataArea);
		
	Else
		
		Proxy.SaveFileFromParts(SessionID, PartCount, FileID);
		
	EndIf; 
	
EndProcedure

// An analog of the "TestConnection" operation
Function ConnectionTesting(Proxy, ExchangeSettingsStructure, ErrorMessage, DataArea = 0)

	ProxyVersion = ProxyVersion(Proxy);
	
	If Version3_0_2_1(ProxyVersion) Then
		
		Return Proxy.TestConnection(
			ExchangeSettingsStructure.CorrespondentExchangePlanName, 
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1, 
			ErrorMessage, 
			DataArea); 
			
	Else
		
		Return Proxy.TestConnection(ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			ErrorMessage);
		
	EndIf;
	
EndFunction

Procedure CheckProhibitedCharsInWSProxyUsername(Val UserName)
	
	InvalidChars = ProhibitedCharsInWSProxyUsername();
	
	If StringContainsCharacter(UserName, InvalidChars) Then
		
		MessageString = NStr("vi = 'Trong tên của người sử dụng %1 có chứa các ký tự không hợp lệ.
			|Tên người sử dụng không được chứa ký tự %2.';
			|ru = 'В имени пользователя %1 содержатся недопустимые символы.
			|Имя пользователя не должно содержать символы %2.';
			|en = 'Username ""%1"" contains illegal characters:
			|%2'; fa = 'Username ""%1"" contains illegal characters:
			|%2';
			|it = 'Nel nome dell''utente %1 sono presenti dei caratteri non ammessi.
			|Il nome dell''utente non deve contenere i caratteri %2.';
			|pl = 'W imieniu użytkownika %1 zawarte są niedopuszczalne symbole.
			|Imię użytkownika nie powinno zawierać symbole %2.';
			|tr = 'Kullanıcı adı %1 geçersiz karakterler içeriyor. 
			|Kullanıcı adı %2.sembol içermemelidir.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, UserName, InvalidChars);
		
		Raise MessageString;
		
	EndIf;
	
EndProcedure

Function StringContainsCharacter(Val String, Val CharacterString)
	
	For IndexOf = 1 To StrLen(CharacterString) Do
		Char = Mid(CharacterString, IndexOf, 1);
		
		If StrFind(String, Char) <> 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ProhibitedCharsInWSProxyUsername()
	
	Return ":";
	
EndFunction

Procedure CheckWSProxyAddressFormatCorrectness(Val WSProxyAddress)
	
	IsInternetAddress           = False;
	AllowedWSProxyPrefixes = AllowedWSProxyPrefixes();
	
	For Each Prefix In AllowedWSProxyPrefixes Do
		If Left(Lower(WSProxyAddress), StrLen(Prefix)) = Lower(Prefix) Then
			IsInternetAddress = True;
			Break;
		EndIf;
	EndDo;
	
	If Not IsInternetAddress Then
		PrefixesString = "";
		For Each Prefix In AllowedWSProxyPrefixes Do
			PrefixesString = PrefixesString + ?(IsBlankString(PrefixesString), """", " or """) + Prefix + """";
		EndDo;
		
		MessageString = NStr("vi = 'Sai định dạng địa chỉ ""%1"".
			|Địa chỉ phải bắt đầu bằng tiền tố giao thức Internet %2 (ví dụ: ""http://myserver.com/service"").';
			|ru = 'Неверный формат адреса ""%1"".
			|Адрес должен начинаться с префикса Интернет протокола %2 (например: ""http://myserver.com/service"").';
			|en = 'Invalid address format: ""%1"".
			|An address must start with an Internet protocol prefix: %2. For example, ""http://myserver.com/service"".'; fa = 'Invalid address format: ""%1"".
			|An address must start with an Internet protocol prefix: %2. For example, ""http://myserver.com/service"".';
			|it = 'Formato scorretto dell''indirizzo ""%1"".
			|L''indirizzo deve cominciare con il prefisso del protocollo Internet %2 (ad esempio: ""http://myserver.com/service"").';
			|pl = 'Błędny format adresu ""%1"".
			|Adres musi zaczynać się od prefiksu protokołu Internetu %2 (na przykład: ""http://myserver.com/service"").';
			|tr = 'Yanlış Adres biçimi ""%1""
			|. Adres Internet Protokolü öneki ile başlamalıdır%2 (örneğin, ""http://myserver.com/service"").'");
			
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, WSProxyAddress, PrefixesString);
		
		Raise MessageString;
	EndIf;
	
EndProcedure

Function AllowedWSProxyPrefixes()
	
	Result = New Array();
	
	Result.Add("http");
	Result.Add("https");
	
	Return Result;
	
EndFunction

Function SynchronizationSetupStatusInCorrespondent(Proxy, SettingsStructure, DataArea = 0)
	
	Result = New Structure;
	Result.Insert("SettingExists",                     False);
	
	Result.Insert("DataSynchronizationSetupCompleted",   True);
	Result.Insert("MessageReceivedForDataMapping", False);
	Result.Insert("DataMappingSupported",       True);
		
	ErrorMessageString = "";
	ProxyVersion = ProxyVersion(Proxy);
	
	If CommonClientServer.CompareVersions(ProxyVersion, "2.0.1.6") >= 0 Then
		
		SettingExists = ConnectionTesting(Proxy, SettingsStructure, ErrorMessageString, DataArea);
		
		If SettingExists
			And CommonClientServer.CompareVersions(ProxyVersion, "3.0.1.1") >= 0 Then
			
			ProxyDestinationParameters = GetParametersOfInfobase(Proxy,
				SettingsStructure.CorrespondentExchangePlanName,
				SettingsStructure.CurrentExchangePlanNodeCode1,
				ErrorMessageString,
				DataArea);
			
			DestinationParameters = XDTOSerializer.ReadXDTO(ProxyDestinationParameters);
			
			FillPropertyValues(Result, DestinationParameters);
		EndIf;
		
		Result.SettingExists = SettingExists;
	Else
		
		ProxyDestinationParameters = GetParametersOfInfobase(Proxy,
				SettingsStructure.ExchangePlanName,
				SettingsStructure.CurrentExchangePlanNodeCode1,
				ErrorMessageString,
				DataArea);
			
		DestinationParameters = ValueFromStringInternal(ProxyDestinationParameters);
		
		If DestinationParameters.Property("NodeExists") Then
			Result.SettingExists = DestinationParameters.NodeExists;
		Else
			Result.SettingExists = True;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

Function ObsoleteExchangeSettingsOptionInCorrespondent(Proxy, SetupStatus, SettingsStructure, NodeCode, Cancel, ErrorMessageString = "")
	
	StateOfOptionSetup = New Structure();
	StateOfOptionSetup.Insert("TransportSettings", SettingsStructure.TransportSettings);
	
	// Checking if migration is possible.
	For Each SettingsMode In ObsoleteExchangeSettingsOptions(SettingsStructure.InfobaseNode) Do
		
		StateOfOptionSetup.Insert("ExchangePlanName", SettingsMode.ExchangePlanName);
		StateOfOptionSetup.Insert("CurrentExchangePlanNodeCode1", NodeCode);
				
		SetupStatus = SynchronizationSetupStatusInCorrespondent(
			Proxy, StateOfOptionSetup);
		
		If SetupStatus.SettingExists Then
			If SettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport Then
				SettingsStructure.ExchangePlanName = SettingsMode.ExchangePlanName;
				If NodeCode <> SettingsStructure.CurrentExchangePlanNodeCode1 Then
					SettingsStructure.CurrentExchangePlanNodeCode1 = NodeCode;
				EndIf;
			Else
				// This infobase has switched to another exchange plan, and its peer hasn't.
				// Data import is aborted.
				ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong chương trình ""%1"" đang thực hiện cập nhật tùy chỉnh đồng bộ.
					|Đã hủy kết nhập dữ liệu. Hãy khởi động lại đồng bộ dữ liệu.';
					|ru = 'В программе ""%1"" выполняется обновление настроек синхронизации.
					|Загрузка данных отменена. Запустите синхронизацию данных повторно.';
					|en = 'Synchronization settings are being updated in ""%1"" application.
					|The data import is canceled. Restart the data synchronization later.'; fa = 'Synchronization settings are being updated in ""%1"" application.
					|The data import is canceled. Restart the data synchronization later.';
					|it = 'Nel programma ""%1"" è in corso l''aggiornamento delle impostazioni di sincronizzazione.
					|Download dati annullato. Ripetere la sincronizzazione dati.';
					|pl = 'W programie ""%1"" trwa aktualizacja ustawień synchronizacji.
					|Pobieranie danych zostało anulowane. Uruchom synchronizację danych ponownie.';
					|tr = '""%1"" programında senkronizasyon ayarları güncelleniyor.
					|Veri yüklemesi iptal edildi. Veri senkronzasyonunu tekrar başlatın.'"),
					String(SettingsStructure.InfobaseNode));
				Cancel = True;
			EndIf;
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ObsoleteExchangeSettingsOptions(ExchangeNode)
	
	Result = New Array;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeNode);
	
	SettingsMode = "";
	If Common.HasObjectAttribute("SettingsMode", ExchangeNode.Metadata()) Then
		SettingsMode = Common.ObjectAttributeValue(ExchangeNode, "SettingsMode");
	EndIf;
	
	If ValueIsFilled(SettingsMode) Then
		For Each PreviousExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
			If PreviousExchangePlanName = ExchangePlanName Then
				Continue;
			EndIf;
			If DataExchangeCached.IsDistributedInfobaseExchangePlan(PreviousExchangePlanName) Then
				Continue;
			EndIf;
			
			PreviousExchangePlanSettings = DataExchangeServer.ExchangePlanSettingValue(PreviousExchangePlanName,
				"ExchangePlanNameToMigrateToNewExchange,ExchangeSettingsOptions");
			
			If PreviousExchangePlanSettings.ExchangePlanNameToMigrateToNewExchange = ExchangePlanName Then
				SettingsOption = PreviousExchangePlanSettings.ExchangeSettingsOptions.Find(SettingsMode, "SettingID");
				If Not SettingsOption = Undefined Then
					Result.Add(New Structure("ExchangePlanName, SettingID", 
						PreviousExchangePlanName, SettingsOption.SettingID));
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

Function MaximumGeneralVersionOfExchangeInterface(VersionsOfCorrespondentExchangeInterface) Export
	
	SupportedVersionsStructure = New Structure;
	DataExchangeServer.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	VersionsOfExchangeInterface = SupportedVersionsStructure.DataExchange;
	
	MaxVersion = "0.0.0.0";
	
	For Each Version In VersionsOfCorrespondentExchangeInterface Do
		
		If VersionsOfExchangeInterface.Find(Version) = Undefined Then
			Continue;
		EndIf;
		
		If CommonClientServer.CompareVersions(Version, MaxVersion) > 0 Then
			MaxVersion = Version;
		EndIf;
		
	EndDo;
	
	// Exception
	If MaxVersion = "2.1.1.7" Then
		MaxVersion = "2.0.1.6";
	EndIf;
	
	Return MaxVersion;
	
EndFunction

#EndRegion

