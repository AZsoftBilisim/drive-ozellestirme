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

Var Timeout;
Var TimeoutSendingReceiving;

#EndRegion

#Region Public

// See DataProcessorObject.ExchangeMessageTransportFILE.SendData
Function SendData(MessageForDataMapping = False) Export

	Try
		Result = SendMessage();
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
		
		For Each Template In NameTemplatesForReceivingMessage Do
			
			Result = GetMessage(Template);
			
			If Result Then
				Break;
			EndIf;
			
		EndDo;
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Result = False;
		
	EndTry;
	
	Return Result;
		
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.BeforeExportData
Function BeforeExportData(MessageForDataMapping = False) Export
	
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.CorrespondentParameters
Function CorrespondentParameters(ConnectionSettings) Export
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	Result.ConnectionIsSet = True;
	Result.ConnectionAllowed = True;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.SaveSettingsInCorrespondent
Function SaveSettingsInCorrespondent(ConnectionSettings) Export
		
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.AuthenticationRequired
Function AuthenticationRequired() Export
	
	Return False;
	
EndFunction

#EndRegion

#Region Private

Function GetMessage(MessageNameTemplate)

	UpdateAToken();
	
	Headers = New Map();
	Headers.Insert("Authorization","Bearer " + AccessToken);
	
	IdOfFolderInCloud = IdOfFolderInCloud();
	
	ResourceAddress = "/drive/v3/files?q='%1' in parents and trashed = false and name contains '%2'&orderBy=modifiedTime desc";
	ResourceAddress = StrTemplate(ResourceAddress, IdOfFolderInCloud, MessageNameTemplate);
		
	HTTPConnection = HTTPConnection("www.googleapis.com", Timeout);
	
	Query = New HTTPRequest(ResourceAddress, Headers);
	
	Response = HTTPConnection.Get(Query);
	Body = Response.GetBodyAsString(TextEncoding.UTF8);
	QueryResult = ExchangeMessagesTransport.JSONValue(Body); 
	
	If Response.StatusCode <> 200 Then
		
		ErrorMessage = QueryResult["error"]["message"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
	
	EndIf;
		
	FilesInCloud = QueryResult["files"];
	
	TableOfFiles = New ValueTable;
	TableOfFiles.Columns.Add("FileName", New TypeDescription("String",,,, New StringQualifiers(200)));
	TableOfFiles.Columns.Add("Id", New TypeDescription("String",,,, New StringQualifiers(200)));
	
	For Each File In FilesInCloud Do
		
		NewString = TableOfFiles.Add();
		NewString.FileName = File["name"];
		NewString.Id = File["id"];
		
	EndDo;

	Query = New Query;
	Query.Text = 
		"SELECT
		|	T.FileName AS FileName,
		|	T.Id AS Id
		|INTO TT
		|FROM
		|	&TableOfFiles AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT.FileName AS FileName,
		|	TT.Id AS Id
		|FROM
		|	TT AS TT
		|WHERE
		|	TT.FileName LIKE &Template";
		
	MessageNameTemplateForSearching = StrReplace(MessageNameTemplate, "*", "%");
	
	Query.SetParameter("Template", MessageNameTemplateForSearching);
	Query.SetParameter("TableOfFiles", TableOfFiles);
	
	FileSearchResult = Query.Execute().Unload();
	
	If FileSearchResult.Count() = 0 Then
		
		ErrorMessage = NStr("vi = 'Trong thư mục trao đổi thông tin, chưa tìm thấy tệp thông báo có dữ liệu.
                                  |Tên thư mục trên server: ""%1""
                                  |Tên tệp thông báo trao đổi: ""%2""';
                                  |ru = 'В каталоге обмена информацией не был обнаружен файл сообщения с данными.
                                  |Идентификатор каталога на сервере на сервере: ""%1""
                                  |Имя файла сообщения обмена: ""%2""';
                                  |en = 'An information exchange directory is missing a message file.
                                  |Server directory ID: %1
                                  |File: %2'; fa = 'An information exchange directory is missing a message file.
                                  |Server directory ID: %1
                                  |File: %2';
                                  |it = 'В каталоге обмена информацией не был обнаружен файл сообщения с данными.
                                  |Идентификатор каталога на сервере на сервере: ""%1""
                                  |Имя файла сообщения обмена: ""%2""';
                                  |pl = 'An information exchange directory is missing a message file.
                                  |Server directory ID: %1
                                  |File: %2';
                                  |tr = 'Veri mesajı dosyası iletişim dizininde bulunamadı.
                                  |Sunucudaki iletişim dizini: ""%1""
                                  |Alışveriş mesajı dosyasının adı: ""%2""'");

		ErrorMessage = StrTemplate(ErrorMessage, IdOfFolderInCloud, MessageNameTemplate);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;

	EndIf;
	
	// Upload file from a hard drive
	File = FileSearchResult[0];
	
	HTTPConnection = HTTPConnection("www.googleapis.com", TimeoutSendingReceiving);
	
	Headers = New Map();
	Headers.Insert("Authorization","Bearer " + AccessToken);
	
	ResourceAddress = "/drive/v3/files/%1?alt=media";
	ResourceAddress = StrTemplate(ResourceAddress, File["Id"]);
	
	Query = New HTTPRequest(ResourceAddress, Headers);
	Response = HTTPConnection.Get(Query);
	
	If Response.StatusCode <> 200 Then
		
		ErrorMessage = ExchangeMessagesTransport.JSONValue(Body)["message"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
	
	EndIf;
	
	FilePacked = Upper(Right(File["FileName"], 3)) = "ZIP";
	
	If FilePacked Then
			
		// Getting the temporary archive file name.
		ArchiveTempFileName = CommonClientServer.GetFullFileName(
			TempDirectory, String(New UUID) + ".zip");
		
		BinaryData = Response.GetBodyAsBinaryData();
		BinaryData.Write(ArchiveTempFileName);
		
		If Not ExchangeMessagesTransport.UnzipExchangeMessageFromZipFile(
			ThisObject, ArchiveTempFileName, ArchivePasswordExchangeMessages) Then
			
			Return False;
			
		EndIf;
		
	Else
		
		BinaryData = Response.GetBodyAsBinaryData();
		BinaryData.Write(ExchangeMessage);
		
	EndIf;
	
	Return True;
	
EndFunction

Function SendMessage()

	UpdateAToken();
	
	If CompressOutgoingMessageFile Then
			
		Type = "application/zip";
		
		If Not ExchangeMessagesTransport.PackExchangeMessageIntoZipFile(ThisObject, ArchivePasswordExchangeMessages) Then
			Return False;
		EndIf;
		
		File = New File(NameOfMessageToSend);
		MessageName = File.BaseName + ".zip";
		
	Else
		
		MessageName = NameOfMessageToSend;
		Type = "application/xml";
		
	EndIf;
	
	FileID = "";
	
	If Not FileSearch(MessageName, FileID, "DataExport") Then
		Return False;
	EndIf;
	
	Separator = "v8exchange_cloud";
	
	// File metadata
	Properties = New Map();
	Properties.Insert("name", MessageName);
	Properties.Insert("mimeType", Type);
	
	IdOfFolderInCloud = IdOfFolderInCloud();
	
	If Not ValueIsFilled(FileID) Then 
		DirectoriesArray = New Array;
		DirectoriesArray.Add(IdOfFolderInCloud);
		Properties.Insert("parents", DirectoriesArray);
	EndIf;
	
	FileMetadata = ExchangeMessagesTransport.ValueToJSON(Properties); 
	
	Stream = New MemoryStream();
	DataWriter = New DataWriter(Stream);
	
	DataWriter.WriteLine("Content-Type: application/json; charset=UTF-8");
	DataWriter.WriteLine("");
	DataWriter.WriteLine(FileMetadata);
	DataWriter.Close();
	
	BinaryDataMetadata = Stream.CloseAndGetBinaryData();
		
	// File data
	BinaryData = New BinaryData(ExchangeMessage);
		
	Stream = New MemoryStream();
	DataWriter = New DataWriter(Stream);
	DataWriter.WriteLine("Content-Type:" + Type);
	DataWriter.WriteLine("");
	DataWriter.Write(BinaryData);
	DataWriter.Close();
	
	BinaryDataFile = Stream.CloseAndGetBinaryData();
		
	// Query body
	FlowBody = New MemoryStream();
	DataWriter = New DataWriter(FlowBody);
	DataWriter.WriteLine("--" + Separator);
	DataWriter.Write(BinaryDataMetadata);
	DataWriter.WriteLine("--" + Separator);
	DataWriter.Write(BinaryDataFile);
	DataWriter.WriteLine("");
	DataWriter.WriteLine("--" + Separator + "--");
	DataWriter.WriteLine("--" + Separator + "--");
	
	DataWriter.Close();
	
	BinaryDataBody = FlowBody.CloseAndGetBinaryData();
		
	Headers  = New Map;
	Headers.Insert("Authorization", "Bearer " + AccessToken);
	Headers.Insert("Content-Type", "Multipart/Related; boundary=" + Separator);
	Headers.Insert("Content-Length", Format(BinaryDataBody.Size(), "NG="));
	
	Join = HTTPConnection("www.googleapis.com", TimeoutSendingReceiving);
	
	If ValueIsFilled(FileID) Then
			
		Query = New HTTPRequest("/upload/drive/v3/files/" + FileID + "?uploadType=multipart", Headers);
		Query.SetBodyFromBinaryData(BinaryDataBody);
		
		Response = Join.Patch(Query);
		
	Else
		
		Query = New HTTPRequest("/upload/drive/v3/files?uploadType=multipart", Headers);
		Query.SetBodyFromBinaryData(BinaryDataBody);
		
		Response = Join.Post(Query);
		
	EndIf;
	
	Body = Response.GetBodyAsString(TextEncoding.UTF8);
	QueryResult = ExchangeMessagesTransport.JSONValue(Body);
	
	If Response.StatusCode <> 200 Then
		
		ErrorMessage = QueryResult["error"]["message"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Return False;
		
	EndIf;
		
	Return True;
	
EndFunction

Function ConnectionIsSet() Export
	
	UpdateAToken();

	Headers = New Map();
	Headers.Insert("Authorization","Bearer " + AccessToken);
	
	ResourceAddress = "/drive/v3/files?pageSize=1"; 
	
	HTTPConnection = HTTPConnection("www.googleapis.com", Timeout);
	
	Query = New HTTPRequest(ResourceAddress, Headers);
	
	Response = HTTPConnection.Get(Query);
	Body = Response.GetBodyAsString(TextEncoding.UTF8);
	QueryResult = ExchangeMessagesTransport.JSONValue(Body);
			
	If Response.StatusCode <> 200 Then
		
		ErrorMessage = QueryResult["error"]["message"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

Function UpdateAToken()
	
	If ValueIsFilled(ExpiresIn) And CurrentSessionDate() < ExpiresIn Then
		Return True;
	EndIf;
	
	ResourceAddress = "client_id=%1&client_secret=%2&grant_type=refresh_token&refresh_token=%3";
	ResourceAddress = StrTemplate(ResourceAddress, ClientID, ClientSecret, RefreshToken);
	
	Join = HTTPConnection("accounts.google.com", Timeout);

	Headers  = New Map;
	Headers.Insert("Content-Type","application/x-www-form-urlencoded");
	
	Query = New HTTPRequest("/o/oauth2/token", Headers);
	Query.SetBodyFromString(ResourceAddress);

	Response = Join.CallHTTPMethod("POST", Query);
	Body = Response.GetBodyAsString(TextEncoding.UTF8);
	QueryResult = ExchangeMessagesTransport.JSONValue(Body);
	
	If Response.StatusCode <> 200 Then
		
		ErrorMessage = QueryResult["error_description"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		Return False;
		
	EndIf;
	
	access_token = QueryResult["access_token"];
	expires_in = CurrentSessionDate() + QueryResult["expires_in"] - 25;
	
	If ValueIsFilled(Peer) Then
	
		TransportSettings = ExchangeMessagesTransport.TransportSettings(Peer, "GoogleDrive"); 
		
		If TransportSettings <> Undefined Then
			
			TransportSettings.Insert("Google_access_token", access_token);
			TransportSettings.Insert("Google_expires_in", expires_in);
			
			ExchangeMessagesTransport.SaveTransportSettings(Peer, "GoogleDrive", TransportSettings);
			
		EndIf;
	
	EndIf;
	
	Return True;
	
EndFunction

Function IdOfFolderInCloud()

	If ValueIsFilled(CloudDirectory) Then
		
		Headers = New Map();
		Headers.Insert("Authorization","Bearer " + AccessToken);
		
		ResourceAddress = "/drive/v3/files?q=trashed = false and name='%1'";
		ResourceAddress = StrTemplate(ResourceAddress, CloudDirectory); 
		
		HTTPConnection = HTTPConnection("www.googleapis.com", Timeout);
		
		Query = New HTTPRequest(ResourceAddress, Headers);
		
		Response = HTTPConnection.Get(Query);
		Body = Response.GetBodyAsString(TextEncoding.UTF8);
		QueryResult = ExchangeMessagesTransport.JSONValue(Body); 
	
		If Response.StatusCode <> 200 Then
			
			ErrorMessage = QueryResult["error"]["message"];
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject,"DataImport");
			Return "";
		
		EndIf;
		
		FilesInCloud = QueryResult["files"];
	
		If FilesInCloud.Count() = 0 Then
			Return "";
		Else
			Return FilesInCloud[0]["id"];
		EndIf;
	
	Else 
		
		Return "root";
		
	EndIf;
	
EndFunction

Function FileSearch(FileName, FileID, ActionOnExchange)
	
	Headers = New Map();
	Headers.Insert("Authorization","Bearer " + AccessToken);
	
	IdOfFolderInCloud = IdOfFolderInCloud();
	
	ResourceAddress = "/drive/v3/files?q='%1' in parents and trashed = false and name='%2'";
	ResourceAddress = StrTemplate(ResourceAddress, IdOfFolderInCloud, FileName); 
	
	HTTPConnection = HTTPConnection("www.googleapis.com", Timeout);
	
	Query = New HTTPRequest(ResourceAddress, Headers);
	
	Response = HTTPConnection.Get(Query);
	Body = Response.GetBodyAsString(TextEncoding.UTF8);
	QueryResult = ExchangeMessagesTransport.JSONValue(Body);

	If Response.StatusCode <> 200 Then
		
		ErrorMessage = QueryResult["error"]["message"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange);
		
		Return False;
		
	EndIf;
		
	FilesInCloud = QueryResult["files"];
	
	If FilesInCloud.Count() = 0 Then
		FileID = "";
	Else
		FileID = FilesInCloud[0]["id"];
	EndIf;
	
	Return True;
	
EndFunction

Function HTTPConnection(Server, Timeout)

	SecureConnection = CommonClientServer.NewSecureConnection();
		
	Proxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Proxy = ModuleNetworkDownload.GetProxy("https");
	EndIf;
	
	Return New HTTPConnection(Server,,,, Proxy, Timeout, SecureConnection);	
		
EndFunction

#EndRegion

#Region Initialize

TempDirectory = Undefined;
ExchangeMessage = Undefined;

Timeout = 20;
TimeoutSendingReceiving = 43200;

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf