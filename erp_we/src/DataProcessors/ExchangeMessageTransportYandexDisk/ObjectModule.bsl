///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
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

	HTTPConnection = HTTPConnection("cloud-api.yandex.net", Timeout);
	
	Headers = New Map();
	Headers.Insert("Authorization","OAuth " + AccessToken);
	
	If IsBlankString(CloudDirectory) Then
		Path = "disk:/";
	Else
		Path = "disk:/" + CloudDirectory + "/";
	EndIf;
	
	ResourceAddress = "/v1/disk/resources?path=%1&fields=_embedded.items,_embedded.items.name,_embedded.items.path,_embedded.items.modified";
	ResourceAddress = StrTemplate(ResourceAddress, Path); 
		
	Query = New HTTPRequest(ResourceAddress, Headers);
	
	Response = HTTPConnection.Get(Query);
	Body = Response.GetBodyAsString(TextEncoding.UTF8);
	
	If Response.StatusCode <> 200 Then
		
		ErrorMessage = ExchangeMessagesTransport.JSONValue(Body)["message"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndIf;
	
	QueryResult = ExchangeMessagesTransport.JSONValue(Body,,"modified");
		
	TableOfFiles = New ValueTable;
	TableOfFiles.Columns.Add("FileName", New TypeDescription("String",,,, New StringQualifiers(200)));
	TableOfFiles.Columns.Add("Path", New TypeDescription("String",,,, New StringQualifiers(200)));
	TableOfFiles.Columns.Add("Date", New TypeDescription("Date",,,,, New DateQualifiers(DateFractions.DateTime)));
		
	For Each File In QueryResult["_embedded"]["items"] Do
		
		NewString = TableOfFiles.Add();
		NewString.FileName = File["name"];
		NewString.Path = File["path"];
		NewString.Date = File["modified"];
		
	EndDo;

	Query = New Query;
	Query.Text = 
		"SELECT
		|	T.FileName AS FileName,
		|	T.Path AS Path,
		|	T.Date AS Date
		|INTO TT
		|FROM
		|	&TableOfFiles AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT.Path AS Path
		|FROM
		|	TT AS TT
		|WHERE
		|	TT.FileName LIKE &Template
		|
		|ORDER BY
		|	TT.Date DESC";
		
	MessageNameTemplateForSearching = StrReplace(MessageNameTemplate, "*", "%");
	
	Query.SetParameter("Template", MessageNameTemplateForSearching);
	Query.SetParameter("TableOfFiles", TableOfFiles);
	
	FileSearchResult = Query.Execute().Unload();
	
	If FileSearchResult.Count() = 0 Then
		
		ErrorMessage = NStr("vi = 'Trong thư mục trao đổi thông tin, chưa tìm thấy tệp thông báo có dữ liệu.
                                  |Thư mục trao đổi thông tin trên server: ""%1""
                                  |Tên tệp thông báo trao đổi: ""%2""';
                                  |ru = 'В каталоге обмена информацией не был обнаружен файл сообщения с данными.
                                  |Каталог обмена информацией на сервере: ""%1""
                                  |Имя файла сообщения обмена: ""%2""';
                                  |en = 'The data message file is not found in the data exchange directory.
                                  |The data exchange directory on the server: ""%1""
                                  |The exchange message file name: ""%2""'; fa = 'The data message file is not found in the data exchange directory.
                                  |The data exchange directory on the server: ""%1""
                                  |The exchange message file name: ""%2""';
                                  |it = 'В каталоге обмена информацией не был обнаружен файл сообщения с данными.
                                  |Каталог обмена информацией на сервере: ""%1""
                                  |Имя файла сообщения обмена: ""%2""';
                                  |pl = 'The data message file is not found in the data exchange directory.
                                  |The data exchange directory on the server: ""%1""
                                  |The exchange message file name: ""%2""';
                                  |tr = 'Veri mesajı dosyası iletişim dizininde bulunamadı.
                                  |Sunucudaki iletişim dizini: ""%1""
                                  |Alışveriş mesajı dosyasının adı: ""%2""'");
		
		ErrorMessage = StrTemplate(ErrorMessage, CloudDirectory, MessageNameTemplate);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndIf;
	
	PathToFile = FileSearchResult[0].Path;
	
	// Get a download link
	Headers = New Map();
	Headers.Insert("Authorization","OAuth " + AccessToken);
	
	ResourceAddress = "/v1/disk/resources/download?path=" + StrReplace(PathToFile,"/","%2F");
	
	Query = New HTTPRequest(ResourceAddress, Headers);
	
	Response = HTTPConnection.Get(Query);
	Body = Response.GetBodyAsString(TextEncoding.UTF8);
	
	If Response.StatusCode <> 200 Then
		
		ErrorMessage = ExchangeMessagesTransport.JSONValue(Body)["message"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndIf;
	
	QueryResult = ExchangeMessagesTransport.JSONValue(Body);
	Ref = QueryResult.Get("href");
	LinkInParts = CommonClientServer.URIStructure(Ref);
	
	HTTPConnection = HTTPConnection(LinkInParts.ServerName,Timeout);
	Query = New HTTPRequest(LinkInParts.PathAtServer);
	Response = HTTPConnection.Get(Query);
	
	If Response.StatusCode <> 302 Then
		
		Body = Response.GetBodyAsString(TextEncoding.UTF8);
		ErrorMessage = ExchangeMessagesTransport.JSONValue(Body)["message"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndIf;
	
	Ref = Response.Headers.Get("Location");
	LinkInParts = CommonClientServer.URIStructure(Ref);
	
	HTTPConnection = HTTPConnection(LinkInParts.ServerName, TimeoutSendingReceiving);
		
	Query = New HTTPRequest(LinkInParts.PathAtServer);
	Response = HTTPConnection.Get(Query);
	
	If Response.StatusCode <> 200 Then
		
		Body = Response.GetBodyAsString(TextEncoding.UTF8);
		ErrorMessage = ExchangeMessagesTransport.JSONValue(Body)["message"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndIf;
	
	FilePacked = Upper(Right(PathToFile, 3)) = "ZIP";
	
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

	If IsBlankString(CloudDirectory) Then
		Path = "disk:/";
	Else
		Path = "disk:/" + CloudDirectory + "/";
	EndIf;
	
	If CompressOutgoingMessageFile Then
		
		If Not ExchangeMessagesTransport.PackExchangeMessageIntoZipFile(ThisObject, ArchivePasswordExchangeMessages) Then
			Return False;
		EndIf;

		File = New File(NameOfMessageToSend);
		Path = Path + File.BaseName + ".zip";
		
	Else
		
		Path = Path + NameOfMessageToSend;
		
	EndIf;
		
	Headers = New Map();
	Headers.Insert("Authorization","OAuth " + AccessToken);
	
	ResourceAddress = "/v1/disk/resources/upload?path=%1&overwrite=true";
	ResourceAddress = StrTemplate(ResourceAddress, Path);
	
	HTTPConnection = HTTPConnection("cloud-api.yandex.net", Timeout);
	Query = New HTTPRequest(ResourceAddress, Headers);
	
	Response = HTTPConnection.Get(Query);
	
	If Response.StatusCode <> 200 Then
		
		Body = Response.GetBodyAsString(TextEncoding.UTF8);
		ErrorMessage = ExchangeMessagesTransport.JSONValue(Body)["message"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Return False;
		
	EndIf;
	
	Body = Response.GetBodyAsString(TextEncoding.UTF8);
	
	QueryResult = ExchangeMessagesTransport.JSONValue(Body);
	
	Ref = QueryResult.Get("href"); //Link
	LinkInParts = CommonClientServer.URIStructure(Ref);
	
	HTTPConnection = HTTPConnection(LinkInParts.ServerName, TimeoutSendingReceiving);
		
	Query = New HTTPRequest(LinkInParts.PathAtServer);
	
	Data = New BinaryData(ExchangeMessage);
	Query.SetBodyFromBinaryData(Data);
		
	Response = HTTPConnection.Put(Query);
	
	If Response.StatusCode <> 201 Then
		
		Body = Response.GetBodyAsString(TextEncoding.UTF8);
		ErrorMessage = ExchangeMessagesTransport.JSONValue(Body)["message"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

Function ConnectionIsSet() Export
	
	If IsBlankString(CloudDirectory) Then
		Path = "disk:/";
	Else
		Path = "disk:/" + CloudDirectory + "/";
	EndIf;
	
	HTTPHeader = New Map();
	HTTPHeader.Insert("Authorization","OAuth " + AccessToken);
	
	RequestResource = "/v1/disk/resources?fields=resource_id&path=%1&limit=1";
	RequestResource = StrTemplate(RequestResource, Path);
		
	HTTPConnection = HTTPConnection("cloud-api.yandex.net", Timeout);
	ResourceAddress = New HTTPRequest(RequestResource, HTTPHeader);
	Response = HTTPConnection.Get(ResourceAddress);
		
	If Response.StatusCode <> 200 Then
		
		Body = Response.GetBodyAsString(TextEncoding.UTF8);
		ErrorMessage = ExchangeMessagesTransport.JSONValue(Body)["message"];
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
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