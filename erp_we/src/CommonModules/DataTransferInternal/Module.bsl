#Region Internal

Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
	
	VersionsArray = New Array;
	VersionsArray.Add("1.0.1.1");
	SupportedVersionsStructure.Insert("DataTransfer", VersionsArray);
	
EndProcedure

Function Get(AccessParameters, FromPhysicalStorage, StorageID, Id, Span = Undefined, FileName = Undefined) Export
	
	Access = AccessFile(AccessParameters, FromPhysicalStorage, StorageID, Id);
	
	If Access = Undefined Then
		Return Undefined;
	EndIf;
	
	If ValueIsFilled(Access.S3Address) Then
		Return GetS3(Access.S3Address, Span, FileName);
	Else
		Return GetDT(AccessParameters, Access.Address, Access.Cookies, Span, FileName);	
	EndIf;
	
EndFunction

Function GetFileSize(AccessParameters, FromPhysicalStorage, StorageID, Id) Export
	
	Access = AccessFile(AccessParameters, FromPhysicalStorage, StorageID, Id);
	
	If Access = Undefined Then
		Return Undefined;
	EndIf;
	
	If Access.Size = Undefined Then
		If ValueIsFilled(Access.S3Address) Then
			URIStructure = URIStructure(Access.S3Address);
			Join = ConnectionS3(URIStructure);
			Query = New HTTPRequest(URIStructure.PathAtServer);
			Query.Headers.Insert("Range", "bytes=0-0");
			Response = Join.Get(Query);
			If Response.StatusCode <> 206 Then
				ErrorReceivingData(Response);
				Return Undefined;
			EndIf;
			Return Number(StrSplit(GetTitle(Response, "Content-Range"), "/")[1]);
		Else
		    URIStructure = URIStructure(Access.Address);
			Join = DTConnection(URIStructure, AccessParameters.UserName, AccessParameters.Password);
			DataRequest = New HTTPRequest(URIStructure.PathAtServer);
			If ValueIsFilled(Access.Cookies) Then
				DataRequest.Headers.Insert("Cookie", Access.Cookies);
			EndIf;
			
			DataRequest.Headers.Insert("Range", "bytes=0-0");
			Response = Join.Get(DataRequest);
			If Response.StatusCode <> 206 Then
				ErrorReceivingData(Response);
				Return Undefined;
			EndIf;
			Return Number(StrSplit(GetTitle(Response, "Content-Range"), "/")[1]);			
		EndIf;
		
	EndIf;
	
	Return Access.Size;
	
EndFunction

Function Send(AccessParameters, ToPhysicalStorage, StorageID, Data, Val FileName, AdditionalParameters = Undefined) Export
	
	SendOptions = StartSending(AccessParameters, ToPhysicalStorage, StorageID, Data, FileName, AdditionalParameters);
	
	If SendOptions = Undefined Then
		Return Undefined;
	EndIf;
	
	BlockSizeForSendingData = BlockSizeForSendingData();	
	
	Address = ?(ValueIsFilled(SendOptions.S3Address), SendOptions.S3Address, SendOptions.Location);
	
	URIStructure = URIStructure(Address);
	
	If ValueIsFilled(SendOptions.S3Address) Then
		Join = ConnectionS3(URIStructure);
	Else
		Join = DTConnection(URIStructure, AccessParameters.UserName, AccessParameters.Password);
	EndIf;
	
	DataRequest = New HTTPRequest(URIStructure.PathAtServer);
	If ValueIsFilled(SendOptions.SetCookie) Then
		DataRequest.Headers.Insert("Cookie", SendOptions.SetCookie);
	EndIf;
	
	If BlockSizeForSendingData > 0 
		And SendOptions.TransferInParts Then
		
		Return SendPartOfFile(AccessParameters, SendOptions, Data, True, 0);
		
	Else
		
		If IsTempStorageURL(Data) Then
			
			BinaryData = GetFromTempStorage(Data);
			FileSize = BinaryData.Size();
			DataRequest.SetBodyFromBinaryData(BinaryData);
			
		ElsIf TypeOf(Data) = Type("String") Then
			
			File = New File(Data);
			FileSize = File.Size();
			DataRequest.SetBodyFileName(Data);
			
		ElsIf TypeOf(Data) = Type("File") Then
			
			FileSize = Data.Size();
			DataRequest.SetBodyFileName(Data.FullName);
			
		ElsIf TypeOf(Data) = Type("BinaryData") Then
			
			FileSize = Data.Size();
			DataRequest.SetBodyFromBinaryData(Data);
			
		EndIf;
		
		If ValueIsFilled(SendOptions.SetCookie) Then
			DataRequest.Headers.Insert("IBSession", "finish");
		EndIf;
		
		DataRequest.Headers.Insert("Content-Length", Format(FileSize, "NG=0"));
		DataRequest.Headers.Insert("Transfer-Encoding", Undefined);
		
		ResponseToDataRequest = Join.Put(DataRequest);
		
		Result = Undefined;
		
		If ResponseToDataRequest.StatusCode = 201 Then
			
			JSONReader = New JSONReader;
			JSONReader.SetString(ResponseToDataRequest.GetBodyAsString());
			ResponseData = ReadJSON(JSONReader);
			
			If ResponseData.Count() = 1 And ResponseData.Property("id") Then
				
				Result = ResponseData.id;
				
			Else
				
				Result = ResponseData;
				
			EndIf;
			
		ElsIf ResponseToDataRequest.StatusCode = 200 Then
			
			Result = SendOptions.S3FileId;
			
		Else
			
			AnErrorOccurredWhileSendingData(ResponseToDataRequest);
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Starts sending the file to the repository
// 
// Parameters:
//   AccessParameters - Structure - Fields:
//     * URL - String - The service URL must be present and filled in;
//     * UserName - String - user name;
//     * Password - String - user password.
//   ToPhysicalStorage - Boolean - To Physical Storage
//   StorageID - String - ID of the logical storage.
//   Data - String - address of data in temporary storage;
//          - String - full file name (including the path to the file);
//          - File - file object;
//          - BinaryData - the value is in the form of binary data.
//   FileName - String - name of the file to transfer.
//   AdditionalParameters - Structure - a structure with values serialized in json.
// 
// Returns:
//  Undefined, Structure - Start Sending:
//    * Location - Undefined, Arbitrary - 
//    * SetCookie - Undefined, Arbitrary - 
//    * S3Address - Undefined, Arbitrary - 
//    * S3FileId - Undefined, Arbitrary - 
//    * TransferInParts - Boolean - 
//
Function StartSending(AccessParameters, ToPhysicalStorage, StorageID, Data, Val FileName, AdditionalParameters = Undefined) Export
	
	AccessURIStructure = URIStructure(AccessParameters.URL);
	Join = DTConnection(AccessURIStructure, AccessParameters.UserName, AccessParameters.Password);
	
	If ToPhysicalStorage Then
		
		ResourceAddressTemplate = "/hs/dt/volume/%1/%2";
		
	Else
		
		ResourceAddressTemplate = "/hs/dt/storage/%1/%2";
		
	EndIf;
	
	If Not ValueIsFilled(FileName) And TypeOf(Data) = Type("File") Then
		
		FileName = Data.Name;
		
	ElsIf Not ValueIsFilled(FileName) Then
		
		FileObject1 = New File(GetTempFileName());
		FileName = FileObject1.Name;
		
	EndIf;
	
	ResourceAddress = AccessURIStructure.PathAtServer + StrTemplate(ResourceAddressTemplate, StorageID, FileName);
	
	ResourceRequest = New HTTPRequest(ResourceAddress);
	ResourceRequest.Headers.Insert("IBSession", "start");
	
	If AdditionalParameters <> Undefined Then
		JSONWriter = New JSONWriter;
		JSONWriter.SetString();
		WriteJSON(JSONWriter, AdditionalParameters);
		Body = JSONWriter.Close();
		ResourceRequest.SetBodyFromString(Body);
	EndIf;
	
	ResponseToResourceRequest = Join.Post(ResourceRequest);
	
	If ResponseToResourceRequest.StatusCode = 400 Then
		
		ResourceRequest.Headers.Delete("IBSession");
		ResponseToResourceRequest = Join.Post(ResourceRequest);
		
	EndIf;
	
	If ResponseToResourceRequest.StatusCode <> 200 Then
		AnErrorOccurredWhileSendingData(ResponseToResourceRequest);
		Return Undefined;
	EndIf;
	
	Access = New Structure;
	Access.Insert("Location", GetTitle(ResponseToResourceRequest, "Location"));
	Access.Insert("SetCookie", GetTitle(ResponseToResourceRequest, "Set-Cookie"));
	Access.Insert("S3Address", GetTitle(ResponseToResourceRequest, "x-url-s3"));
	Access.Insert("S3FileId", GetTitle(ResponseToResourceRequest, "x-file-id"));
	Access.Insert("TransferInParts", GetTitle(ResponseToResourceRequest, "Accept-Ranges") = "bytes" And Not ValueIsFilled(Access.S3Address));
	
	Return Access;
		
EndFunction

Function SendPartOfFile(AccessParameters, SendOptions, Data, LastPart = True, Offset = 0) Export

	SetCookie = SendOptions.SetCookie;
	URIStructure = URIStructure(SendOptions.Location);
	Join = DTConnection(URIStructure, AccessParameters.UserName, AccessParameters.Password);
	DataRequest = New HTTPRequest(URIStructure.PathAtServer);
	If ValueIsFilled(SetCookie) Then
		DataRequest.Headers.Insert("Cookie", SetCookie);
	Else
		DataRequest.Headers.Insert("IBSession", "start");
	EndIf;
	
	BlockSize = BlockSizeForSendingData();

	If IsTempStorageURL(Data) Then

		DataStream = GetFromTempStorage(Data).OpenStreamForRead();

	ElsIf TypeOf(Data) = Type("String") Then

		DataStream = FileStreams.Open(Data, FileOpenMode.Open, FileAccess.Read);

	ElsIf TypeOf(Data) = Type("File") Then

		DataStream = FileStreams.Open(Data.FullName, FileOpenMode.Open, FileAccess.Read);

	ElsIf TypeOf(Data) = Type("BinaryData") Then

		DataStream = Data.OpenStreamForRead();

	EndIf;
	
	Size = Offset + DataStream.Size();

	SendingRange = New Structure;
	SendingRange.Insert("Begin", Offset);
	SendingRange.Insert("End", Offset + Min(BlockSize - 1, Size - 1));

	While True Do

		Buffer = New BinaryDataBuffer(SendingRange.End - SendingRange.Begin + 1);
		Read = DataStream.Read(Buffer, 0, Buffer.Size);
		DataRequest.SetBodyFromBinaryData(GetBinaryDataFromBinaryDataBuffer(Buffer));

		DataRequest.Headers.Insert("Content-Range", 
			StrTemplate("bytes %1-%2/%3", 
				Format(SendingRange.Begin, "NZ=0; NG=0"), 
				Format(SendingRange.Begin + Read - 1, "NZ=0; NG=0"), 
				Format(Size + ?(LastPart, 0, 1), "NZ=0; NG=0")));

		If SendingRange.End = Size - 1 And ValueIsFilled(SetCookie) Then

			DataRequest.Headers.Insert("IBSession", "finish");

		EndIf;

		ResponseToDataRequest = Join.Put(DataRequest);
		
		If ResponseToDataRequest.StatusCode = 400 Then
			DataRequest.Headers.Delete("IBSession");
			ResponseToDataRequest = Join.Put(DataRequest);
		EndIf;
		
		If ResponseToDataRequest.StatusCode = 201 Then

			JSONReader = New JSONReader;
			JSONReader.SetString(ResponseToDataRequest.GetBodyAsString());
			ResponseData = ReadJSON(JSONReader);
			
			DataStream.Close();
			
			If ResponseData.Count() = 1 And ResponseData.Property("id") Then

				Return ResponseData.id;

			Else

				Return ResponseData;

			EndIf;

		ElsIf ResponseToDataRequest.StatusCode <> 202 Then
			
			DataStream.Close();
			AnErrorOccurredWhileSendingData(ResponseToDataRequest);
			Return Undefined;

		EndIf;
		
		SendingRange.Begin = SendingRange.End + 1;
		SendingRange.End = Min(SendingRange.End + BlockSize, Size - 1);
		
		If SendingRange.Begin > SendingRange.End Then
			// everything is transferred
			Return Size;
		EndIf;
		
		If ValueIsFilled(GetTitle(ResponseToDataRequest, "Set-Cookie")) Then
			SetCookie = GetTitle(ResponseToDataRequest, "Set-Cookie");
			DataRequest.Headers.Insert("Cookie", SetCookie);
		EndIf;

	EndDo;
	
	Return Size;

EndFunction

Function ResultingRange(Query) Export
	
	ContentRange = GetTitle(Query, "Content-Range");
	
	Span = Undefined;
	ContentRange = TrimAll(ContentRange);
	
	If Not IsBlankString(ContentRange) And StrStartsWith(ContentRange, "bytes ") Then
		
		ContentRange = Right(ContentRange, StrLen(ContentRange) - StrLen("bytes "));
		SubstringsArray = StrSplit(ContentRange, "/");
		Range = SubstringsArray[0];
		Size = SubstringsArray[1];
		SubstringsArray = StrSplit(Range, "-");
		
		Try
			
			Begin = Number(SubstringsArray[0]);
			End = Number(SubstringsArray[1]);
			Var_Size = Number(Size);
			
			Span = New Structure("Begin, End, Size", Begin, End, Var_Size);
			
		Except
			
			Span = Undefined;
			
		EndTry;
		
	EndIf;
		
	Return Span;
	
EndFunction

Function ValidityPeriodOfTemporaryID() Export
	
	ValidityPeriodOfTemporaryID = 600; // 10 minutes
	
	DataTransferIntegration.ValidityPeriodOfTemporaryID(ValidityPeriodOfTemporaryID);
	DataTransferOverridable.ValidityPeriodOfTemporaryID(ValidityPeriodOfTemporaryID);
	
	Return ValidityPeriodOfTemporaryID;
	
EndFunction

Function DataBlockSize() Export
	
	DataBlockSize = 1024 * 1024;
	
	DataTransferIntegration.DataBlockSize(DataBlockSize);
	DataTransferOverridable.DataBlockSize(DataBlockSize);
	
	Return DataBlockSize;

EndFunction

Function BlockSizeForSendingData() Export
	
	BlockSizeForSendingData = 1024 * 1024;
	
	DataTransferIntegration.BlockSizeForSendingData(BlockSizeForSendingData);
	DataTransferOverridable.BlockSizeForSendingData(BlockSizeForSendingData);
	
	Return BlockSizeForSendingData;

EndFunction

Procedure ErrorReceivingData(Response) Export
	
	DataTransferIntegration.ErrorReceivingData(Response);
	DataTransferOverridable.ErrorReceivingData(Response);
	
EndProcedure

Procedure AnErrorOccurredWhileSendingData(Response) Export
	
	DataTransferIntegration.AnErrorOccurredWhileSendingData(Response);
	DataTransferOverridable.AnErrorOccurredWhileSendingData(Response);
	
EndProcedure

Function TempFileName(Extension = Undefined, AdditionalParameters = Undefined) Export
	
	TempFileName = GetTempFileName(Extension);
	DataTransferIntegration.OnGetTemporaryFileName(TempFileName, Extension);
	DataTransferOverridable.OnGetTemporaryFileName(TempFileName, Extension, AdditionalParameters);
	
	Return TempFileName;
	
EndFunction

Procedure OnExtendTemporaryIDValidity(Id, RecordManager) Export
	
	JSONReader = New JSONReader;
	JSONReader.SetString(RecordManager.Query.Get());
	Query = ReadJSON(JSONReader, True);
	
	DataTransferIntegration.OnExtendTemporaryIDValidity(Id, RecordManager.Date, Query);
	DataTransferOverridable.OnExtendTemporaryIDValidity(Id, RecordManager.Date, Query);
	
EndProcedure

Function GetBinaryDataFromS3(Address, Begin = Undefined, End = Undefined) Export
	
	URIStructure = URIStructure(Address);
	Join = ConnectionS3(URIStructure);
	
	Query = New HTTPRequest(URIStructure.PathAtServer);
	If Begin <> Undefined Then
		Query.Headers.Insert("Range", StrTemplate("bytes=%1-%2", Format(Begin, "NZ=0; NG=0"), Format(End, "NZ=0; NG=0")));
	EndIf;
	
	Response = Join.Get(Query);
	
	If Response.StatusCode <> 200 And Response.StatusCode <> 206 Then
		Raise StrTemplate("%1: %2 %3", Response.StatusCode, Chars.LF, Left(Response.GetBodyAsString(), 128));
	EndIf;
	
	Return Response.GetBodyAsBinaryData(); 
	
EndFunction

#EndRegion

#Region Private

Function URIStructure(Val URIString1)
	
	URIString1 = TrimAll(URIString1);
	
	// Scheme.
	Schema = "";
	Position = StrFind(URIString1, "://");
	
	If Position > 0 Then
		
		Schema = Lower(Left(URIString1, Position - 1));
		URIString1 = Mid(URIString1, Position + 3);
		
	EndIf;

	// The connection string and the path on the server.
	ConnectionString = URIString1;
	PathAtServer = "";
	Position = StrFind(ConnectionString, "/");
	
	If Position > 0 Then
		
		PathAtServer = Mid(ConnectionString, Position + 1);
		ConnectionString = Left(ConnectionString, Position - 1);
		
	EndIf;
		
	// User information and server name.
	AuthorizationString = "";
	ServerName = ConnectionString;
	Position = StrFind(ConnectionString, "@");
	
	If Position > 0 Then
		
		AuthorizationString = Left(ConnectionString, Position - 1);
		ServerName = Mid(ConnectionString, Position + 1);
		
	EndIf;
	
	// Login and password.
	Login = AuthorizationString;
	Password = "";
	Position = StrFind(AuthorizationString, ":");
	
	If Position > 0 Then
		
		Login = Left(AuthorizationString, Position - 1);
		Password = Mid(AuthorizationString, Position + 1);
		
	EndIf;
	
	// Host and port.
	Host = ServerName;
	Port = "";
	Position = StrFind(ServerName, ":");
	
	If Position > 0 Then
		
		Host = Left(ServerName, Position - 1);
		Port = Mid(ServerName, Position + 1);
		
		If Not OnlyNumbersInString(Port) Then
			Port = "";
		ElsIf Port = "80" And Schema = "http" Then
			Port = "";
		ElsIf Port = "443" And Schema = "https" Then
			Port = "";
		EndIf;
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("Schema", Schema);
	Result.Insert("Login", Login);
	Result.Insert("Password", Password);
	Result.Insert("Host", Host);
	Result.Insert("Port", ?(IsBlankString(Port), Undefined, Number(Port)));
	Result.Insert("PathAtServer", PathAtServer);
	
	Return Result;
	
EndFunction

Function OnlyNumbersInString(Val CheckString)
	
	If TypeOf(CheckString) <> Type("String") Then
		
		Return False;
		
	EndIf;
	
	CheckString = StrReplace(CheckString, " ", "");
		
	If IsBlankString(CheckString) Then
		
		Return True;
		
	EndIf;
	
	Digits = "0123456789";
	
	Return StrSplit(CheckString, Digits, False).Count() = 0;
	
EndFunction

Function Join(URIStructure, User, Password, Timeout)
	
	Return DataTransferCached.Join(URIStructure, User, Password, Timeout);
	
EndFunction

Function ConnectionS3(URIStructure)
	
	Return Join(URIStructure, Undefined, Undefined, 7200);
	
EndFunction

Function DTConnection(URIStructure, User, Password)
	
	Return Join(URIStructure, User, Password, 180);
	
EndFunction

Procedure DeleteTempFile(FileName)
	
	File = New File(FileName);
	If Not File.Exists() Then
		Return;
	EndIf;
	
	Try
		DeleteFiles(FileName);
	Except
		WriteLogEvent(NStr("vi = 'ПередачаДанных';
							|ru = 'ПередачаДанных';
							|en = 'DataTransfer'; fa = 'DataTransfer';
							|it = 'ПередачаДанных';
							|pl = 'DataTransfer';
							|tr = 'Veri transferi'", Common.DefaultLanguageCode()), EventLogLevel.Error,,, DataTransferClientServer.DetailedErrorText(ErrorInfo()));
	EndTry;
	
EndProcedure

Function AccessFile(AccessParameters, FromPhysicalStorage, StorageID, Id)
	
	AccessURIStructure = URIStructure(AccessParameters.URL);
	
	If FromPhysicalStorage Then
		ResourceAddressTemplate = "/hs/dt/volume/%1/%2";
	Else
		ResourceAddressTemplate = "/hs/dt/storage/%1/%2";
	EndIf;
	
	ResourceAddress = AccessURIStructure.PathAtServer + StrTemplate(ResourceAddressTemplate, StorageID, String(Id));
	
	If AccessParameters.Property("Cache") Then
		Access = AccessParameters.Cache.Get(ResourceAddress);
		If Access <> Undefined And Access.Expires > CurrentUniversalDate() Then
			Return Access;
		EndIf;
	EndIf;
	
	ResourceRequest = New HTTPRequest(ResourceAddress);
	ResourceRequest.Headers.Insert("IBSession", "start");
	
	Join = DTConnection(AccessURIStructure, AccessParameters.UserName, AccessParameters.Password);
	ResponseToResourceRequest = Join.Get(ResourceRequest);
	
	If ResponseToResourceRequest.StatusCode = 400 Then
		
		ResourceRequest.Headers.Delete("IBSession");
		ResponseToResourceRequest = Join.Get(ResourceRequest);
		
	EndIf;
	
	If ResponseToResourceRequest.StatusCode <> 302 Then
		ErrorReceivingData(ResponseToResourceRequest);
		Return Undefined;
	EndIf;
		
	Access = New Structure;
	Access.Insert("S3Address", GetTitle(ResponseToResourceRequest, "x-url-s3"));
	Access.Insert("Address", GetTitle(ResponseToResourceRequest, "Location"));
	Access.Insert("Cookies", GetTitle(ResponseToResourceRequest, "Set-Cookie"));
	Access.Insert("Size", GetTitle(ResponseToResourceRequest, "x-file-length"));
	If Access.Size <> Undefined Then
		Access.Size = Number(Access.Size);
	EndIf;
	Access.Insert("FileName", GetTitle(ResponseToResourceRequest, "x-file-name"));
	
	If AccessParameters.Property("Cache") Then
		
		If ValueIsFilled(Access.S3Address) Then
			PathOnS3Server = URIStructure(Access.S3Address).PathAtServer;
			QueryOptions = ParametersFromURLEncoding(Mid(PathOnS3Server, StrFind(PathOnS3Server, "?")+1));
			SignatureDate = Date(StrReplace(StrReplace(QueryOptions["X-Amz-Date"], "T", ""), "Z", ""));
			LifeSpan = Number(QueryOptions["X-Amz-Expires"]);
			Expires = SignatureDate + LifeSpan - 900; // 15 minutes error in s3
			Access.Insert("Expires", Expires);
			AccessParameters.Cache.Insert(ResourceAddress, Access);
		ElsIf Not ValueIsFilled(Access.Cookies) Then
			// The cache is used only if explicit session management is not used
			Access.Insert("Expires", CurrentUniversalDate() + 300); // In MS 10 minutes, here so as not to be overdue will be 5 minutes.
			AccessParameters.Cache.Insert(ResourceAddress, Access);
		EndIf;
	
	EndIf;
	
	Return Access;
	
EndFunction

Function GetS3(S3Address, Span, FileName = Undefined)
	
	URIStructure = URIStructure(S3Address);
	Join = ConnectionS3(URIStructure);
	Query = New HTTPRequest(URIStructure.PathAtServer);
	If Span <> Undefined Then
		If Span.Begin >= 0 Then
			Query.Headers.Insert("Range", StrTemplate("bytes=%1-%2", Format(Span.Begin, "NZ=0; NG=0"), Format(Span.End, "NZ=0; NG=0")));
		Else
			Query.Headers.Insert("Range", "bytes=0-0");
			Response = Join.Get(Query);
			If Response.StatusCode <> 206 Then
				ErrorReceivingData(Response);
				Return Undefined;
			EndIf;
			FileSize = Number(StrSplit(GetTitle(Response, "Content-Range"), "/")[1]);	
			Query.Headers.Insert("Range", StrTemplate("bytes=%1-%2", Format(FileSize - 1 + Span.Begin, "NZ=0; NG=0"), Format(FileSize - 1 + Span.End, "NZ=0; NG=0")));
		EndIf;
	EndIf;
	
	If FileName = Undefined Then
		FileName = GetTempFileName();
	EndIf;
	
	ResponseToDataRequest = Join.Get(Query, FileName);
	
	If ResponseToDataRequest.StatusCode = 200 Or ResponseToDataRequest.StatusCode = 206 Then
		FileProperties = New File(FileName);
		Return New Structure("Name, FullName", FileProperties.Name, FileProperties.FullName);
	EndIf;
	
	DeleteTempFile(FileName);
	ErrorReceivingData(ResponseToDataRequest);
		
EndFunction

Function GetDT(AccessParameters, Address, Cookies, Span, FileName = Undefined)
	
	RequestedRange = Undefined;
	
	URIStructure = URIStructure(Address);
	Join = DTConnection(URIStructure, AccessParameters.UserName, AccessParameters.Password);
	DataRequest = New HTTPRequest(URIStructure.PathAtServer);
	If ValueIsFilled(Cookies) Then
		DataRequest.Headers.Insert("Cookie", Cookies);
	EndIf;
	
	DataBlockSize = DataBlockSize();
			
	If DataBlockSize > 0 Or Span <> Undefined Then
		
		If Span = Undefined Then
			RequestedRange = New Structure("Begin, End", 0, DataBlockSize - 1);
		Else
			RequestedRange = New Structure("Begin, End", Span.Begin, Min(Span.Begin + DataBlockSize - 1, Span.End));
		EndIf;
		DataRequest.Headers.Insert("Range", StrTemplate("bytes=%1-%2", Format(RequestedRange.Begin, "NZ=0; NG=0"), Format(RequestedRange.End, "NZ=0; NG=0")));	
	EndIf;
		
	ResponseToDataRequest = Join.Get(DataRequest);
	
	If ResponseToDataRequest.StatusCode <> 200 And ResponseToDataRequest.StatusCode <> 206 Then
		ErrorReceivingData(ResponseToDataRequest);
		Return Undefined;
	EndIf;
	
	If FileName = Undefined Then
		FileName = GetTempFileName();
	EndIf;	

	DataStream = FileStreams.Open(FileName, FileOpenMode.CreateNew, FileAccess.Write);
	Stream = ResponseToDataRequest.GetBodyAsStream();
	
	If ResponseToDataRequest.StatusCode = 200 Then
		
		Stream.CopyTo(DataStream);
		
	Else // The response of the requested data.State Code = 206
		
		ResultingRange = ResultingRange(ResponseToDataRequest);
		If Span <> Undefined Then
			ResultingRange.Size = Span.End + 1;
		EndIf;
		Stream.CopyTo(DataStream);
		
		While ResultingRange.End < ResultingRange.Size - 1 Do
			
			RequestedRange = New Structure("Begin, End", ResultingRange.End + 1, Min(ResultingRange.End + DataBlockSize, ResultingRange.Size - 1));
			
			If RequestedRange.End = ResultingRange.Size - 1 And ValueIsFilled(Cookies) Then
				
				DataRequest.Headers.Insert("IBSession", "finish");
				
			EndIf;
			
			DataRequest.Headers.Insert("Range", StrTemplate("bytes=%1-%2", Format(RequestedRange.Begin, "NZ=0; NG=0"), Format(RequestedRange.End, "NZ=0; NG=0")));
			ResponseToDataRequest = Join.Get(DataRequest);
			
			If ResponseToDataRequest.StatusCode = 206 Then
				
				Stream = ResponseToDataRequest.GetBodyAsStream();
				
				ResultingRange = ResultingRange(ResponseToDataRequest);
				If Span <> Undefined Then
					ResultingRange.Size = Span.End + 1;
				EndIf;
				
				Stream.CopyTo(DataStream);
				
			Else
				
				DataStream.Close();
				DeleteTempFile(FileName);
				ErrorReceivingData(ResponseToDataRequest);
				Return Undefined;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Stream.Close();
	DataStream.Close();
	
	FileProperties = New File(FileName);
	
	Return New Structure("Name, FullName", FileProperties.Name, FileProperties.FullName);
	
EndFunction

Function GetTitle(RequestResponse, Val Title)
	
	Title = Lower(Title);
	For Each KeyAndValue In RequestResponse.Headers Do
		If Lower(KeyAndValue.Key) = Title Then
			Return KeyAndValue.Value;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

Function ParametersFromURLEncoding(ParametersString1) 
	
	Parameters = New Map;
	
	If Not IsBlankString(ParametersString1) Then
		For Each Parameter In StrSplit(ParametersString1, "&", False) Do
			Parts = StrSplit(Parameter, "=");
			If Parts.Count() = 2 Then
				Parameters.Insert(Parts[0], DecodeString(Parts[1], StringEncodingMethod.URLEncoding));
			EndIf;
		EndDo;
	EndIf;
	
	Return Parameters;
	
EndFunction

#EndRegion
