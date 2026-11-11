///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ExchangeMessage Export; // For import, it is the name of the file stored in "TempDirectory". For export, the name of the file to be sent out
Var TempDirectory Export; // A temporary exchange directory.
Var DirectoryID Export;
Var Peer Export;
Var ExchangePlanName Export;
Var CorrespondentExchangePlanName Export;
Var ErrorMessage Export;
Var ErrorMessageEventLog Export;

Var NameTemplatesForReceivingMessage Export;
Var NameOfMessageToSend Export;

#EndRegion

#Region Public

// See DataProcessorObject.ExchangeMessageTransportFILE.SendData
Function SendData(MessageForDataMapping = False) Export
	
	Try
		Result = SendExchangeMessage(MessageForDataMapping);
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Result = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.GetData
Function GetData() Export

	Try
		Result = GetExchangeMessage();
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Result = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.CorrespondentParameters
Function CorrespondentParameters(ConnectionSettings) Export
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	Result.Insert("CorrespondentExchangePlanName", CorrespondentExchangePlanName);
	
	HTTPConnection = HTTPConnection();
	
	Parameters = New Structure;
	Parameters.Insert("ExchangePlanName", CorrespondentExchangePlanName);
	Parameters.Insert("NodeCode", ExchangePlans[ExchangePlanName].ThisNode().Code);
	Parameters.Insert("IsXDTOExchangePlan", DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName));
	Parameters.Insert("SettingID", ConnectionSettings.SettingID);
	
	Response = ExecuteHTTPRequest(HTTPConnection, "GET", "GetIBParameters", Parameters);
	
	If AnswerIsMistake(Response) Then
		
		Result.ConnectionIsSet = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;

	EndIf;
	
	Body = Response.GetBodyAsString();
	QueryResult = ExchangeMessagesTransport.JSONValue(Body);
		
	CorrespondentParameters = New Structure;
	
	CorrespondentParameters.Insert("ExchangePlanExists", QueryResult["ExchangePlanExists"]);
	CorrespondentParameters.Insert("InfobasePrefix", QueryResult["InfobasePrefix"]);
	CorrespondentParameters.Insert("DefaultInfobasePrefix", QueryResult["DefaultInfobasePrefix"]);
	CorrespondentParameters.Insert("InfobaseDescription", QueryResult["InfobaseDescription"]);
	CorrespondentParameters.Insert("DefaultInfobaseDescription", QueryResult["DefaultInfobaseDescription"]);
	CorrespondentParameters.Insert("AccountingParametersSettingsAreSpecified", QueryResult["AccountingParametersSettingsAreSpecified"]);
	CorrespondentParameters.Insert("ThisNodeCode", QueryResult["ThisNodeCode"]); 
	CorrespondentParameters.Insert("ConfigurationVersion", QueryResult["ConfigurationVersion"]);
	CorrespondentParameters.Insert("NodeExists", QueryResult["NodeExists"]);
	CorrespondentParameters.Insert("DataExchangeSettingsFormatVersion", QueryResult["DataExchangeSettingsFormatVersion"]);
	CorrespondentParameters.Insert("UsePrefixesForExchangeSettings", QueryResult["UsePrefixesForExchangeSettings"]);
	CorrespondentParameters.Insert("ExchangeFormat", QueryResult["ExchangeFormat"]);
	CorrespondentParameters.Insert("ExchangePlanName", QueryResult["ExchangePlanName"]);
	CorrespondentParameters.Insert("ExchangeFormatVersions", QueryResult["ExchangeFormatVersions"]);
	CorrespondentParameters.Insert("DataSynchronizationSetupCompleted", QueryResult["DataSynchronizationSetupCompleted"]);
	CorrespondentParameters.Insert("MessageReceivedForDataMapping", QueryResult["MessageReceivedForDataMapping"]);
	CorrespondentParameters.Insert("DataMappingSupported", QueryResult["DataMappingSupported"]);
	
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		
		FormatObjects = ExchangeMessagesTransport.TableFromArray_SupportedObjectsInFormat(
			QueryResult["SupportedObjectsInFormat"],
			QueryResult["ExchangeFormatVersions"]);
	
		CorrespondentParameters.Insert("SupportedObjectsInFormat", FormatObjects);
		
	EndIf;

	Result.ConnectionIsSet = False;
	
 	If Not CorrespondentParameters.ExchangePlanExists Then
		
		Text = NStr("vi = 'Trong cơ sở trao đổi tin không tìm thấy sơ đồ trao đổi ""%1"".
			|Hãy chắc chắn rằng,
			| - đã chọn đúng dạng ứng dụng để tùy chỉnh trao đổi;
			| - đã chỉ ra đúng địa chỉ ứng dụng trên Internet.';
			|ru = 'В корреспонденте не найден план обмена ""%1"".
			|Убедитесь, что
			| - выбран правильный вид приложения для настройки обмена;
			| - указан правильный адрес приложения в Интернете.';
			|en = 'Exchange plan ""%1"" is not found in the peer application.
			|Ensure that the following data is correct:
			|- The application type selected in the exchange settings.
			|- The web application address.'; fa = 'Exchange plan ""%1"" is not found in the peer application.
			|Ensure that the following data is correct:
			|- The application type selected in the exchange settings.
			|- The web application address.';
			|it = 'Il piano di scambio %1"""" non è stato trovato nel corrispondente.
			| Assicurarsi che
			| - è stato selezionato il tipo corretto di applicazione per impostare lo scambio;
			| - è indicato l''indirizzo corretto dell''applicazione in Internet.';
			|pl = 'W korespondencie nie znaleziono planu wymiany ""%1"".
			|Przekonaj się, że
			| - wybrano właściwy rodzaj aplikacji dla ustawienia wymiany;
			| - podano poprawny adres aplikacji w Internecie.';
			|tr = 'Muhabirde ""%1"" alışveriş planı bulunamadı. 
			| - 
			|Veri alışverişini yapılandırmak için uygulamanın türü doğru seçildiğinden; 
			|- bağlantının yapıldığı programın İnternet''teki konumunun doğru belirtildiğinden emin olun.'");
		
		ErrorMessage = StrTemplate(Text, ExchangePlanName);
		
		Result.ConnectionIsSet = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;
		
	EndIf;
	
	Result.CorrespondentParametersReceived = True;
	Result.CorrespondentParameters = CorrespondentParameters;
	Result.CorrespondentExchangePlanName = CorrespondentParameters.ExchangePlanName;
	Result.ConnectionIsSet = True;
	
	Cancel = False;
	ErrorMessage = "";
	
	ConfigurationVersion = Result.CorrespondentParameters.ConfigurationVersion;
	
	ExchangeMessagesTransport.OnConnectToCorrespondent(Cancel, ExchangePlanName, ConfigurationVersion, ErrorMessage);
		
	If Cancel Then
		
		Result.ConnectionAllowed = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;
		
	EndIf;
	
	ExchangeMessagesTransport.CheckForDuplicateSyncs(ExchangePlanName, CorrespondentParameters, Result);
	
	Result.ConnectionAllowed = True;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.BeforeExportData
Function BeforeExportData(MessageForDataMapping = False) Export
	
	Return ConnectionIsSet();
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.SaveSettingsInCorrespondent
Function SaveSettingsInCorrespondent(ConnectionSettings) Export
	
	HTTPConnection = HTTPConnection();
	
	ConnectionSettingsINJSON = ExchangeMessagesTransport.ConnectionSettingsINJSON(ConnectionSettings);
	
	Response = ExecuteHTTPRequest(HTTPConnection, "POST", "CreateExchangeNode", , ConnectionSettingsINJSON);
	
	If AnswerIsMistake(Response) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.AuthenticationRequired
Function AuthenticationRequired() Export
	
	Return Not RememberPassword;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.DeleteSynchronizationSettingInCorrespondent
Function DeleteSynchronizationSettingInCorrespondent() Export
	
	HTTPConnection = HTTPConnection();
	
	Parameters = New Structure;
	Parameters.Insert("ExchangePlanName", CorrespondentExchangePlanName);
	Parameters.Insert("NodeCode", ExchangePlans[ExchangePlanName].ThisNode().Code);
	
	Response = ExecuteHTTPRequest(HTTPConnection, "DELETE", "RemoveExchangeNode", Parameters);
	
	If AnswerIsMistake(Response) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionIsSet() Export
	
	HTTPConnection = HTTPConnection();
	
	URIStructure = CommonClientServer.URIStructure(WebServiceAddress);
	ResourceAddress = URIStructure.PathAtServer + "/hs/exchange_dsl_1_0_0_1/version";
		
	Headers = New Map();
	Query = New HTTPRequest(ResourceAddress, Headers);
	
	Response = HTTPConnection.Get(Query);
	If AnswerIsMistake(Response) Then
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

Function SendExchangeMessage(MessageForDataMapping)
		
	HTTPConnection = HTTPConnection(180);
	
	If Not ValueIsFilled(Peer) Then
		UIDFileID = PutFileInStorageInService(HTTPConnection, ExchangeMessage, 1024);
		Return True;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("ExchangePlanName", CorrespondentExchangePlanName);
	Parameters.Insert("NodeCode", ExchangePlans[ExchangePlanName].ThisNode().Code);
	Parameters.Insert("IsXDTOExchangePlan", DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName));
	
	Response = ExecuteHTTPRequest(HTTPConnection, "GET", "GetIBParameters", Parameters);
	
	If AnswerIsMistake(Response, "DataExport") Then
		Return False;
	EndIf;
	
	Body = Response.GetBodyAsString();
	SetupStatus = ExchangeMessagesTransport.JSONValue(Body);
	UIDFileID = PutFileInStorageInService(HTTPConnection, ExchangeMessage, 1024);
	
	FileIDAsString = String(UIDFileID);
	
	If MessageForDataMapping
		And (SetupStatus["DataMappingSupported"]
		Or Not SetupStatus["DataSynchronizationSetupCompleted"]) Then
			
		Parameters = New Structure;
		Parameters.Insert("ExchangePlanName", CorrespondentExchangePlanName);
		Parameters.Insert("NodeCode", ExchangePlans[ExchangePlanName].ThisNode().Code);
		Parameters.Insert("FileID", FileIDAsString);
		
		Response = ExecuteHTTPRequest(HTTPConnection, "POST", "PutMessageForDataMatching", Parameters);
		
		If AnswerIsMistake(Response, "DataExport") Then
			Return False;
		EndIf;
		
	Else
		
		Parameters = New Structure;
		Parameters.Insert("ExchangePlanName", CorrespondentExchangePlanName);
		Parameters.Insert("NodeCode", ExchangePlans[ExchangePlanName].ThisNode().Code);
		Parameters.Insert("FileID", FileIDAsString);
		Parameters.Insert("TimeConsumingOperationAllowed", True);
		
		Response = ExecuteHTTPRequest(HTTPConnection, "POST", "DownloadData", Parameters);
		
		Body = Response.GetBodyAsString();
		
		If AnswerIsMistake(Response, "DataExport") Then
			Return False;
		EndIf;
		
		Result = ExchangeMessagesTransport.JSONValue(Body);
		
		ExchangeParameters = DataExchangeServer.ExchangeParameters();
		ExchangeParameters.TheTimeoutOnTheServer = 15;
		ExchangeParameters.TimeConsumingOperation = Result["TimeConsumingOperation"];
		ExchangeParameters.OperationID = Result["OperationID"];
		
		If ExchangeParameters.TimeConsumingOperation Then
			
			WaitingForTheOperationToComplete(HTTPConnection, ExchangeParameters, Enums.ActionsOnExchange.DataExport);
			
		EndIf;
		
	EndIf;
		
	Return True;
	
EndFunction

Function PutFileInStorageInService(HTTPConnection, Val FileName, 
	Val PartSizeKB = 1024, FileID = Undefined) Export
	
	If HTTPConnection = Undefined Then
		
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

		Parameters = New Structure;
		Parameters.Insert("SessionID", SessionID);
		Parameters.Insert("PartNumber", PartNumber);
		
		Response = ExecuteHTTPRequest(HTTPConnection, "POST", "PutFilePart", Parameters, FileData);
		
		If AnswerIsMistake(Response, "DataExport") Then
			Return False;
		EndIf;
		
	EndDo;
	
	Try
		DeleteFiles(FilesDirectory);
	Except
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
		
	Parameters = New Structure;
	Parameters.Insert("SessionID", SessionID);
	Parameters.Insert("PartCount", PartCount);
	
	Response = ExecuteHTTPRequest(HTTPConnection, "POST", "SaveFileFromParts", Parameters);
	
	If AnswerIsMistake(Response, "DataExport") Then
		Return False;
	EndIf;
	
	Body = Response.GetBodyAsString();
	Result = ExchangeMessagesTransport.JSONValue(Body);
	
	Return Result["FileID"]; 
	
EndFunction

Procedure WaitingForTheOperationToComplete(HTTPConnection, ExchangeParameters, ActionWhenExchangingInThisInformationSystem = Undefined) Export
	
	If ExchangeParameters.TheTimeoutOnTheServer = 0 Then
		
		If ActionWhenExchangingInThisInformationSystem <> Undefined Then
			
			// For this infobase, "Import". Therefore, for the peer infobase, "Export".
			If ActionWhenExchangingInThisInformationSystem = Enums.ActionsOnExchange.DataImport Then
				
				ActionInTheCorrespondentLine = NStr("vi = 'kết xuất';
													|ru = 'выгрузка';
													|en = 'export'; fa = 'export';
													|it = 'выгрузка';
													|pl = 'eksport';
													|tr = 'dışa aktar'", Common.DefaultLanguageCode());
				
			Else
				
				ActionInTheCorrespondentLine = NStr("vi = 'kết nhập';
													|ru = 'загрузка';
													|en = 'import'; fa = 'import';
													|it = 'загрузка';
													|pl = 'import';
													|tr = 'içe aktar'", Common.DefaultLanguageCode());
				
			EndIf;
			
			MessageTemplate = NStr("vi = 'Đợi thực hiện giao dịch (%1 dữ liệu trong cơ sở trao đổi tin)...';
									|ru = 'Ожидание выполнения операции (%1 данных в базе-корреспонденте)...';
									|en = 'Waiting for the operation to be executed (%1 of the data in the peer infobase)…'; fa = 'Waiting for the operation to be executed (%1 of the data in the peer infobase)…';
									|it = 'Attesa di esecuzione operazione (%1 dati nella base corrispondente)...';
									|pl = 'Oczekiwanie wykonania operacji (%1 danych w bazie korespondencie)...';
									|tr = 'İşlemin yürütülmesi bekleniyor (muhabir veri tabanındaki %1veriler)...'", Common.DefaultLanguageCode());
			Message = StrTemplate(MessageTemplate, ActionInTheCorrespondentLine);
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject,, Message, False);
			
		EndIf;
		
		Return;
		
	EndIf;
	
	While ExchangeParameters.TimeConsumingOperation Do // Replace recursion.
		
		DataExchangeServer.Pause(ExchangeParameters.TheTimeoutOnTheServer);
		
		ErrorMessageString = "";
			
		Parameters = New Structure;
		Parameters.Insert("OperationID",  ExchangeParameters.OperationID);
		
		Response = ExecuteHTTPRequest(HTTPConnection, "GET", "GetContinuousOperationStatus", Parameters);
		
		If AnswerIsMistake(Response) Then
			ActionState = "";
		Else
			Body = Response.GetBodyAsString();
			Result = ExchangeMessagesTransport.JSONValue(Body);
			ActionState = Result["ActionState"];
		EndIf;
			
		If ActionState = "Active" Then
			
			ExchangeParameters.TheTimeoutOnTheServer = Min(ExchangeParameters.TheTimeoutOnTheServer + 30, 180);
			
		ElsIf ActionState = "Completed" Then
			
			ExchangeParameters.TheTimeoutOnTheServer = 15;
			ExchangeParameters.TimeConsumingOperation = False; 
			ExchangeParameters.OperationID = Undefined;
			
		Else
			
			Raise StrTemplate(NStr("vi = 'Lỗi trong cơ sở trao đổi dữ liệu:%1 %2';
									|ru = 'Ошибка в базе-корреспонденте:%1 %2';
									|en = 'Peer infobase error: %1 %2'; fa = 'Peer infobase error: %1 %2';
									|it = 'Errore nella base corrispondente: %1 %2';
									|pl = 'Błąd w bazie korespondencie:%1 %2';
									|tr = 'Muhabir tabanındaki hata: %1%2'"), Chars.LF, ErrorMessageString);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function GetExchangeMessage()
	
	HTTPConnection = HTTPConnection(180);
	
	If Not ValueIsFilled(Peer) Then
		ExchangeMessage = GetFileFromStorageInService(HTTPConnection, NameTemplatesForReceivingMessage[0], 1024);
		Return True;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("ExchangePlanName", CorrespondentExchangePlanName);
	Parameters.Insert("NodeCode", ExchangePlans[ExchangePlanName].ThisNode().Code);
	Parameters.Insert("TimeConsumingOperationAllowed", True);
	
	Response = ExecuteHTTPRequest(HTTPConnection, "POST", "UploadData", Parameters);
	
	If AnswerIsMistake(Response, "DataImport") Then
		Return False;
	EndIf;
	
	Body = Response.GetBodyAsString();
	
	Result = ExchangeMessagesTransport.JSONValue(Body);
		
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	ExchangeParameters.TimeConsumingOperationAllowed = True;
	ExchangeParameters.TheTimeoutOnTheServer = 15;
	ExchangeParameters.FileID = Result["FileID"];
	ExchangeParameters.TimeConsumingOperation = Result["TimeConsumingOperation"];
	ExchangeParameters.OperationID = Result["OperationID"];
	
	If ExchangeParameters.TimeConsumingOperation Then
		
		WaitingForTheOperationToComplete(HTTPConnection, ExchangeParameters, Enums.ActionsOnExchange.DataImport);
		
	EndIf;
	
	UIDOfTheMessageFile = New UUID(ExchangeParameters.FileID);
	
	ExchangeMessage = GetFileFromStorageInService(HTTPConnection, UIDOfTheMessageFile, 1024);
		
	If AnswerIsMistake(Response, "DataImport") Then
		Return False;
	EndIf;
		
	Return True;
	
EndFunction

Function GetFileFromStorageInService(HTTPConnection, Val FileID, Val PartSize = 1024) Export
	
	// Function return value.
	ResultFileName = "";
	
	Parameters = New Structure;
	Parameters.Insert("FileID", FileID);
	Parameters.Insert("BlockSize", Format(PartSize, "NG="));
	
	Response = ExecuteHTTPRequest(HTTPConnection, "POST", "PrepareGetFile", Parameters);
	
	If AnswerIsMistake(Response, "DataImport") Then
		Return False;
	EndIf;
	
	Body = Response.GetBodyAsString();
	
	Result = ExchangeMessagesTransport.JSONValue(Body);
	
	SessionID = Result["SessionID"];
	PartCount = Result["PartCount"];
	
	FilesNames = New Array;
	
	TempFilesStorageDirectory = DataExchangeServer.TempFilesStorageDirectory();
	BuildDirectory = CommonClientServer.GetFullFileName(TempFilesStorageDirectory, "{" + String(New UUID) + "}");

	CreateDirectory(BuildDirectory);
	
	FileNameTemplate = "data.zip.[n]";
	
	MessageTemplate = NStr("vi = 'Bắt đầu nhận thông điệp trao đổi từ Internet (số phần trong tệp %1).';
							|ru = 'Начало получения сообщения обмена из Интернета (количество частей файла %1).';
							|en = 'Start receiving an exchange message from the Internet. The message is split into %1 parts.'; fa = 'Start receiving an exchange message from the Internet. The message is split into %1 parts.';
							|it = 'Inizio della ricezione del messaggio di scambio da internet (numero di parti nel file %1).';
							|pl = 'Początek otrzymania komunikatu wymiany z Internetu (ilość części pliku %1).';
							|tr = 'İnternet değişim mesajının alınmaya başlaması (dosya parçalarının sayısı%1).'");
	Message = StrTemplate(MessageTemplate, Format(PartCount, "NZ=0; NG=0"));
	ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport", Message, False);
		
	For PartNumber = 1 To PartCount Do
		PartData = Undefined; // BinaryData
		
		Parameters = New Structure;
		Parameters.Insert("SessionID", SessionID);
		Parameters.Insert("PartNumber", PartNumber);
		
		Response = ExecuteHTTPRequest(HTTPConnection, "GET", "GetFilePart", Parameters);
		
		If AnswerIsMistake(Response, "DataImport") Then
			
			Parameters = New Structure;
			Parameters.Insert("SessionID", SessionID);
			
			ExecuteHTTPRequest(HTTPConnection, "DELETE", "ReleaseFile", Parameters);
			
			Return False;
			
		Else
			
			PartData = Response.GetBodyAsBinaryData();
			
		EndIf;
		
		FileName = StrReplace(FileNameTemplate, "[n]", Format(PartNumber, "NG=0"));
		PartFileName = CommonClientServer.GetFullFileName(BuildDirectory, FileName);
		
		PartData.Write(PartFileName);
		FilesNames.Add(PartFileName);
		
	EndDo;
	
	PartData = Undefined;
		
	Parameters = New Structure;
	Parameters.Insert("SessionID", SessionID);
			
	Response = ExecuteHTTPRequest(HTTPConnection, "DELETE", "ReleaseFile", Parameters);
			
	If AnswerIsMistake(Response, "DataImport") Then
		Return False;
	EndIf;
	
	ArchiveName = CommonClientServer.GetFullFileName(BuildDirectory, "data.zip");
	
	MergeFiles(FilesNames, ArchiveName);
		
	Dearchiver = New ZipFileReader(ArchiveName);
	If Dearchiver.Items.Count() = 0 Then
		Try
			DeleteFiles(BuildDirectory);
		Except
			ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
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
	
	MessageTemplate = NStr("vi = 'Kết thúc nhận thông điệp trao đổi từ Internet (dung lượng thông điệp nén trao đổi %1 Mb).';
							|ru = 'Окончание получения сообщения обмена из Интернета (размер сжатого сообщения обмена %1 Мб).';
							|en = 'Complete receiving an exchange message from the Internet. Compressed message size: %1 MB.'; fa = 'Complete receiving an exchange message from the Internet. Compressed message size: %1 MB.';
							|it = 'Fine della ricezione del messaggio di scambio da internet (dimensione del messaggio di scambio compresso %1 Mb).';
							|pl = 'Zakończenie otrzymania komunikatu wymiany z Internetu (rozmiar komunikatu skompresowanego wymiany %1 Mb).';
							|tr = 'İnternetten alınan değişim mesajının sonu (sıkıştırılmış bir değişim mesajının boyutu %1MB''dir).'");
	Message = StrTemplate(MessageTemplate, Format(Round(ArchiveFile1.Size() / 1024 / 1024, 3), "NZ=0; NG=0"));
	ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport", Message, False);
	
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
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
	EndTry;
		
	Return ResultFileName;
	
EndFunction

Function HTTPConnection(Timeout = 20)
	
	URIStructure = CommonClientServer.URIStructure(WebServiceAddress);
	
	If Lower(URIStructure.Schema) = Lower("https") Then
		SecureConnection = CommonClientServer.NewSecureConnection();
	Else
		SecureConnection = Undefined;
	EndIf;
	
	Proxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Proxy = ModuleNetworkDownload.GetProxy(URIStructure.Schema);
	EndIf;
	
	Return New HTTPConnection(URIStructure.ServerName,,UserName, Password, Proxy, Timeout, SecureConnection);
	
EndFunction

Function ExecuteHTTPRequest(HTTPConnection, RequestType, Method, Parameters = Undefined, Body = Undefined)
	
	URIStructure = CommonClientServer.URIStructure(WebServiceAddress);
		
	ResourceAddressTemplate = "/%1/hs/exchange_dsl_1_0_0_1/v1/%2?%3";
	ParametersByString = "";
	
	If ValueIsFilled(Parameters) Then
		
		For Each KeyAndValue In Parameters Do
		
			If ParametersByString <> "" Then
				ParametersByString = ParametersByString + "&"
			EndIf;
			
			ParametersByString = ParametersByString + KeyAndValue.Key + "=" + KeyAndValue.Value
		
		EndDo;
		
	EndIf;
	
	ResourceAddress = StrTemplate(ResourceAddressTemplate, URIStructure.PathAtServer, Method, ParametersByString); 
	
	Headers = New Map();
	Query = New HTTPRequest(ResourceAddress, Headers);
	
	If TypeOf(Body) = Type("String") Then
		Query.SetBodyFromString(Body);
	ElsIf TypeOf(Body) = Type("BinaryData") Then
		Query.SetBodyFromBinaryData(Body);
	EndIf;
	
	If Lower(RequestType) = "post" Then 
		Response = HTTPConnection.Post(Query);
	ElsIf Lower(RequestType) = "get" Then 
		Response = HTTPConnection.Get(Query);
	ElsIf Lower(RequestType) = "delete" Then
		Response = HTTPConnection.Delete(Query);
	EndIf;
	
	Return Response;
	
EndFunction

Function AnswerIsMistake(Response, ActionOnExchange = Undefined)
	
	If Response.StatusCode <> 200 Then
		
		Body = Response.GetBodyAsString();
		
		Try
			ErrorMessage = ExchangeMessagesTransport.JSONValue(Body)["message"];
		Except
			ErrorMessage = Body;
		EndTry;
		
		If Response.StatusCode = 401 Then
			
			RefinementErrors = NStr("vi = 'Lỗi 401: lỗi đăng nhập dịch vụ HTTP exchange_dsl_1_0_0_1 (truy cập bị từ chối).';
									|ru = 'Ошибка 401: ошибка авторизации HTTP-сервиса exchange_dsl_1_0_0_1 (отказ в доступе).';
									|en = 'Error 401: exchange_dsl_1_0_0_1 HTTP service authorization error (access denied).'; fa = 'Error 401: exchange_dsl_1_0_0_1 HTTP service authorization error (access denied).';
									|it = 'Ошибка 401: ошибка авторизации HTTP-сервиса exchange_dsl_1_0_0_1 (отказ в доступе).';
									|pl = 'Error 401: exchange_dsl_1_0_0_1 HTTP service authorization error (access denied).';
									|tr = '401 Hatası: HTTP hizmeti exchange_dsl_1_0_0_1 için doğrulama hatası (erişim reddi).'");
			ErrorMessage = RefinementErrors + Chars.LF + Chars.LF + ErrorMessage
			
		ElsIf Response.StatusCode = 404 Then
			
			RefinementErrors = NStr("vi = 'Lỗi 404: chưa tìm thấy dịch vụ HTTP exchange_dsl_1_0_0_1 (trên server không có nguồn được yêu cầu.';
									|ru = 'Ошибка 404: HTTP-сервис exchange_dsl_1_0_0_1 не найден (на сервере отсутствует запрашиваемый ресурс.';
									|en = 'Error 404: exchange_dsl_1_0_0_1 HTTP service is not found (the requested resource is not available on the server).'; fa = 'Error 404: exchange_dsl_1_0_0_1 HTTP service is not found (the requested resource is not available on the server).';
									|it = 'Ошибка 404: HTTP-сервис exchange_dsl_1_0_0_1 не найден (на сервере отсутствует запрашиваемый ресурс.';
									|pl = 'Error 404: exchange_dsl_1_0_0_1 HTTP service is not found (the requested resource is not available on the server).';
									|tr = '404 Hatası: HTTP hizmeti exchange_dsl_1_0_0_0_1 bulunamadı ( istenilen kaynak sunucuda mevcut değil).'");
			ErrorMessage = RefinementErrors + Chars.LF + Chars.LF + ErrorMessage
			
		EndIf;
		
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange);
		
		Return True;
		
	Else
		
		Return False;
	
	EndIf;
	
EndFunction

#EndRegion

#Region Initialize

TempDirectory = Undefined;
MessagesOfExchange = Undefined;

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf