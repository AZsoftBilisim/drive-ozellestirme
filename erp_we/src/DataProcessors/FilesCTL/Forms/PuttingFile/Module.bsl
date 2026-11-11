#Region Variables

&AtClient
Var Context;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PlacingFileMethod = Parameters.PlacingFileMethod;
	
	DialogTitle = "";
	If Parameters.Property("DialogTitle", DialogTitle) And ValueIsFilled(DialogTitle) Then
		ThisObject.Title = DialogTitle;
		ThisObject.AutoTitle = False;
	EndIf;

	Parameters.Property("FileNameOrAddress", FileNameOrAddress);
	FileProperties = FilesCTL.TemporaryStorageFileProperties(FileNameOrAddress);
	If FileProperties.Registered Then
		WindowsFilePath = FileProperties.WindowsPath;
		LinuxFilePath = FileProperties.LinuxPath;
	Else
		Parameters.Property("WindowsFilePath", WindowsFilePath);
		Parameters.Property("LinuxFilePath", LinuxFilePath);
	EndIf;

	Parameters.Property("FileNameAtClient", FileNameAtClient);
	Parameters.Property("FileSize", FileSize);

	FilePresentation = "";
	Parameters.Property("FilePresentation", FilePresentation);

	Items.TimeConsumingOperationNoteTextDecoration.Title = StrTemplate(NStr("vi = 'Tải xuống tệp %1';
																			|ru = 'Загрузка файла %1';
																			|en = 'Import file %1'; fa = 'Import file %1';
																			|it = 'Scaricamento del file %1';
																			|pl = 'Pobieranie pliku %1';
																			|tr = '%1 dosyasının içe aktarımı'"),
		FilePresentation);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("StartFileUpload", 0.1, True);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If Not ImportCompleted Then
		Cancel = True;
		CancelImport = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure StartFileUpload()
	
	Notification = New CallbackDescription("AfterOpeningStream", ThisObject, , "OnError", ThisObject);
	FileStreams.BeginOpen(Notification, FileNameAtClient, FileOpenMode.Open, FileAccess.Read);
	
EndProcedure

// After opening the stream.
// 
// Parameters:
//  Stream - FileStream
//  AdditionalParameters - Structure
&AtClient
Async Procedure AfterOpeningStream(Stream, AdditionalParameters) Export
	
	Context = New Structure;
	Context.Insert("Stream", Stream);
	Context.Insert("Buffer", New BinaryDataBuffer(FilesCTLClientServer.ProcessingPortionSize(
		FileSize, PlacingFileMethod = "ImportToService")));
	
	If PlacingFileMethod = "ImportToService" Then
		Try
			Await InitializeImportToService();
		Except
			ImportCompleted = True;
			Raise;
		EndTry;
	EndIf;
	
	ReadNextBatch();
	
EndProcedure

&AtClient
Procedure ReadNextBatch()
	
	Notification = New CallbackDescription("NextPartIsRead", ThisObject, , "OnError",
		ThisObject);
	Context.Stream.BeginReading(Notification, Context.Buffer, 0,
		Context.Buffer.Size);

EndProcedure

// The next part has been read.
// 
// Parameters:
//  Count -Number
// 	AdditionalParameters - Structure:
// * Stream - FileStream
// * Buffer - BinaryDataBuffer
&AtClient
Procedure NextPartIsRead(Count, AdditionalParameters) Export
	
	Position = Context.Stream.CurrentPosition();
	
	Buffer = ?(Context.Buffer.Size = Count, Context.Buffer,
		Context.Buffer.Read(0, Count));
	Context.Insert("SendingPartInProgress", True);
	SendAnotherPortion(GetBinaryDataFromBinaryDataBuffer(Buffer), Position - Count, Position);
	AttachIdleHandler("SendingWaitingHandler", 0.1, True);
	
EndProcedure

&AtClient
Async Procedure SendingWaitingHandler() Export
	
	If Context.SendingPartInProgress Then
		AttachIdleHandler("SendingWaitingHandler", 0.1, True);
		Return;
	EndIf;
	
	If CancelImport Then
		CancelDownload();
		Return;
	EndIf;
	
	Position = Context.Stream.CurrentPosition();
	If Position = FileSize Then
		Await CompleteDownload();
		Return;
	EndIf;
	
	ReadNextBatch();
	
EndProcedure

&AtClient
Async Procedure SendAnotherPortion(BinaryData, Begin, End)
	
	Try
		
		Progress = 100 * Begin / FileSize;
		If PlacingFileMethod = "FileOnServer" Then
			SendNextPortionToServer(FileNameOrAddress, WindowsFilePath, LinuxFilePath, BinaryData, Begin);
		ElsIf PlacingFileMethod = "ImportToService" Then
			Await SendPartToService(BinaryData, Begin, End);
		EndIf;
		
		Context.Insert("SendingPartInProgress", False);
	Except
		Context.Insert("SendingPartInProgress", False);
		Raise;
	EndTry;
	
EndProcedure

&AtServerNoContext
Procedure SendNextPortionToServer(FileNameOrAddress, WindowsFilePath, LinuxFilePath, Val BinaryData,
	Val Begin)

	If Begin = 0 Then
		OpeningMode = FileOpenMode.Create;
	Else
		OpeningMode = FileOpenMode.Append;
	EndIf;

	FileNameAtServer = FilesCTL.FullNameOfFileInSession(FileNameOrAddress, WindowsFilePath, LinuxFilePath);
	WriteStream = FileStreams.Open(FileNameAtServer, OpeningMode, FileAccess.Write);
	SizeOfRecordedFragment = WriteStream.Size();
	If SizeOfRecordedFragment <> Begin Then
		Raise StrTemplate(NStr("vi = 'Kích thước tệp %1 không khớp với dự kiến %2';
								|ru = 'Размер файла %1 не соответствует ожидаемому %2';
								|en = 'Size of file %1 does not match the expected size %2'; fa = 'Size of file %1 does not match the expected size %2';
								|it = 'La dimensione del file %1 non corrisponde al previsto %2';
								|pl = 'Rozmiar pliku %1 nie odpowiada oczekiwanemu %2';
								|tr = '%1 dosyasının boyutu beklenen %2 ile eşleşmiyor'"),
			SizeOfRecordedFragment, Begin);
	EndIf;

	DataStream = BinaryData.OpenStreamForRead();
	DataStream.CopyTo(WriteStream);
	WriteStream.Close();
	DataStream.Close();
	WriteStream = Undefined;
	DataStream = Undefined;

EndProcedure

#Region HTTPCalls

&AtClient
Function Join(Address, Timeout = 60)
	
	URIStructure = CommonClientServer.URIStructure(Address);
	
	If Lower(URIStructure.Schema) = "https" Then
		SecureConnection = CommonClientServer.NewSecureConnection();
	Else
		SecureConnection = Undefined;
	EndIf;
	
	Join = New HTTPConnection(URIStructure.Host, URIStructure.Port, , , Undefined, Timeout,
		SecureConnection);
	
	Return Join;
	
EndFunction

&AtClient
Function StringFromJSONStructure(Data)
	
	#If WebClient Then
		Return StringFromJSONStructureAtServer(Data);
	#Else
		
		JSONWriter = New JSONWriter;
		JSONWriter.SetString();
		WriteJSON(JSONWriter, Data);
		Return JSONWriter.Close();
		
	#EndIf
	
EndFunction

&AtServerNoContext
Function StringFromJSONStructureAtServer(Data)
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Data, , "ConvertingJSONValues", SaaSOperationsCTL);
	Return JSONWriter.Close();
	
EndFunction

&AtClient
Function StructureFromJSONString(String)
	
	#If WebClient Then
		Return StructureFromJSONStringOnServer(String);
	#Else
		
		JSONReader = New JSONReader;
		JSONReader.SetString(String);
		Response = ReadJSON(JSONReader); 
		Return Response;
		
	#EndIf
	
EndFunction

&AtServerNoContext
Function StructureFromJSONStringOnServer(String)
	
	JSONReader = New JSONReader;
	JSONReader.SetString(String);
	Response = ReadJSON(JSONReader);
	If TypeOf(Response) = Type("Structure")
		And Response.Property("url") Then
		Response.url = DecodeString(Response.url, StringEncodingMethod.URLInURLEncoding);
	EndIf;
	Return Response;
	
EndFunction

&AtClient
Async Function SendDataToServiceManager(ConnectionParameters, QueryData, InterfaceType, Method) Export
	
	Join = Undefined;
	If Not ConnectionParameters.Property("Join", Join) Then
		Join = Join(ConnectionParameters.Address);
		ConnectionParameters.Insert("Join", Join);
	EndIf;
	
	URIStructure = CommonClientServer.URIStructure(ConnectionParameters.Address);
	HTTPRequest = New HTTPRequest(StrTemplate("%1/execute/%2/%3", URIStructure.PathAtServer, InterfaceType, Method));
	HTTPRequest.Headers.Insert("Authorization", StrTemplate("Bearer %1", AccessToken(ConnectionParameters.Authentication)));
	HTTPRequest.Headers.Insert("Content-Type", "application/json; charset=utf-8");
	
	HTTPRequest.SetBodyFromString(StringFromJSONStructure(QueryData));
	
	Response = Await Join.CallHTTPMethodAsync("POST", HTTPRequest);
	
	Result = Undefined;
	If Response.StatusCode = 200 Then
		
		ResponseString = Response.GetBodyAsString();
		Result = StructureFromJSONString(ResponseString);
		ResponseCode = Result.general.response;
		If Not (ResponseCode = 10200 Or ResponseCode = 10201 Or ResponseCode = 10202 Or ResponseCode = 10240) Then
			Raise Result.general.message;
		EndIf;
		
	Else
		ErrorText = StrTemplate(NStr("vi = 'Lỗi gọi ra giao diện chương trình. Mã trạng thái: %1';
									|ru = 'Ошибка вызова программного интерфейса. Код состояния: %1';
									|en = 'Error calling the API. Status code: %1'; fa = 'Error calling the API. Status code: %1';
									|it = 'Ошибка вызова программного интерфейса. Код состояния: %1';
									|pl = 'Error calling the API. Status code: %1';
									|tr = 'Yazılım arayüzü çağrısı hatası. Durum kodu: %1'"),
			Response.StatusCode);
		Raise ErrorText;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function ServiceManagerConnectionParameters()
	
	Result = New Structure;
	
	ServiceManagerExternalURL = ServiceProgrammingInterface.InterfaceVersionProperties().ServiceManagerExternalURL;
	Result.Insert("Address", ServiceManagerExternalURL);
	Result.Insert("SubscriberCode", ServiceProgrammingInterface.SubscriberCode());
	Result.Insert("Authentication", Authentication());
	Return Result;
	
EndFunction

&AtServerNoContext
Function Authentication()
	
	ResponseProperties = Undefined;
	Result = New Structure;
	Result.Insert("AccessToken", ServiceProgrammingInterface.ValidAccessToken(, , ResponseProperties));
	Result.Insert("LifeTime", ResponseProperties.LifeTime);
	
	Return Result;
	
EndFunction

&AtClient
Function AccessToken(Authentication)
	
	If Authentication.LifeTime <= CommonClient.SessionDate() Then
		Authentication = Authentication();
	EndIf;
	
	Return Authentication.AccessToken;
	
EndFunction

#EndRegion

#Region ImportToService

&AtClient
Async Function InitializeImportToService()
	
	SMParameters = ServiceManagerConnectionParameters();
	
	File = New File(FileNameAtClient);
	QueryData = New Structure;
	QueryData.Insert("name", File.Name);
	QueryData.Insert("size", FileSize);
	QueryData.Insert("type", "new_data_dump");
	QueryData.Insert("owner", SMParameters.SubscriberCode);
	QueryResult = Await SendDataToServiceManager(SMParameters, QueryData, "srv", "files/new_multipart");
	
	Context.Insert("SMParameters", SMParameters);
	
	ImportParameters = New Structure;
	AddressToSend = QueryResult.url;
	ImportParameters.Insert("FileID", QueryResult.file_id);
	ImportParameters.Insert("AddressType", QueryResult.type);
	ImportParameters.Insert("AddressToSend", AddressToSend);
	ImportParameters.Insert("Parts", New Array);
	ImportParameters.Insert("Join", Join(AddressToSend));
	If QueryResult.type = "s3" Then
		ImportParameters.Insert("RequestHeaders", QueryResult.headers);
	EndIf;
	
	Context.Insert("ImportParameters", ImportParameters);
	
EndFunction

&AtClient
Async Function SendPartToService(BinaryData, Begin, End)
	
	ImportParameters = Context.ImportParameters;
	SMParameters = Context.SMParameters;
	URIStructure = CommonClientServer.URIStructure(ImportParameters.AddressToSend);
	If ImportParameters.AddressType = "s3" Then
		
		Query = New HTTPRequest(URIStructure.PathAtServer);
		Query.SetBodyFromBinaryData(BinaryData);
		For Each HeaderOfRequest In ImportParameters.RequestHeaders Do
			KeyValue = StrSplit(HeaderOfRequest, ":");
			Query.Headers.Insert(KeyValue[0], KeyValue[1]);
		EndDo;
		
		Response = Await ImportParameters.Join.CallHTTPMethodAsync("PUT", Query);
		If Response.StatusCode <> 200 Then
			
			ErrorMessage = StrTemplate(
				NStr("vi = 'Không thể gửi phần tệp, mã trả lời: %1';
					|ru = 'Не удалось отправить часть файла, код ответа: %1';
					|en = 'Cannot send the file part. Response code: %1'; fa = 'Cannot send the file part. Response code: %1';
					|it = 'Не удалось отправить часть файла, код ответа: %1';
					|pl = 'Cannot send the file part. Response code: %1';
					|tr = 'Dosyanın bir kısmı gönderilemedi, cevap kodu: %1'"), 
				Response.StatusCode);
			Raise ErrorMessage;
			
		EndIf;
		
		ImportParameters.Parts.Add(StrReplace(CommonCTLClientServer.HTTPHeader(Response, "ETag"), """", ""));
		
		QueryData = New Structure;
		QueryData.Insert("file_id", ImportParameters.FileID);
		QueryData.Insert("part_number", ImportParameters.Parts.Count() + 1);
		
		NewRequestResult = Await SendDataToServiceManager(SMParameters, QueryData, "srv", "files/new_part");
		ImportParameters.Insert("AddressToSend", NewRequestResult.url);
		ImportParameters.Insert("RequestHeaders", NewRequestResult.headers);
		
	Else
		
		Query = New HTTPRequest(URIStructure.PathAtServer);
		Query.SetBodyFromBinaryData(BinaryData);
		Query.Headers.Insert("Content-Range",
			StrTemplate("bytes %1-%2/%3", 
			Format(Begin, "NZ=0; NG=0"), 
			Format(End - 1, "NZ=0; NG=0"), 
			Format(FileSize - ?(End = FileSize, 0, 0), "NZ=0; NG=0")));
		Response = Await ImportParameters.Join.CallHTTPMethodAsync("PUT", Query);
		If Response.StatusCode <> 201 And Response.StatusCode <> 202 Then
			
			ErrorMessage = StrTemplate(
				NStr("vi = 'Không gửi được một phần của tệp, mã phản hồi: %1%2%3';
					|ru = 'Не удалось отправить часть файла, код ответа: %1%2%3';
					|en = 'Cannot send the file part. Response code: %1%2%3'; fa = 'Cannot send the file part. Response code: %1%2%3';
					|it = 'Не удалось отправить часть файла, код ответа: %1%2%3';
					|pl = 'Nie udało się wysłać części pliku, kod odpowiedzi: %1%2%3';
					|tr = 'Dosyanın bir kısmı gönderilemedi, cevap kodu: %1%2%3'"), 
				Response.StatusCode, Chars.LF, Response.GetBodyAsString());
			Raise ErrorMessage;
			
		EndIf;
		
	EndIf;
	
EndFunction

&AtClient
Async Function CompleteImportToService()
	
	ImportParameters = Context.ImportParameters;
	SMParameters = Context.SMParameters;
	If ImportParameters.AddressType = "s3" Then
		
		QueryData = New Structure;
		QueryData.Insert("file_id", ImportParameters.FileID);
		QueryData.Insert("parts", ImportParameters.Parts);
		Await SendDataToServiceManager(SMParameters, QueryData, "srv", "files/complete_multipart");
		
	EndIf;
	
EndFunction

&AtClient
Procedure CancelImportToService()
	
	ImportParameters = Context.ImportParameters;
	SMParameters = Context.SMParameters;
	
	If ImportParameters.AddressType = "s3" Then
		
		QueryData = New Structure;
		QueryData.Insert("file_id", ImportParameters.FileID);
		SendDataToServiceManager(SMParameters, QueryData, "srv", "files/abort_multipart");
		
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Async Function CompleteDownload()
	
	Result = New Structure;
	
	If PlacingFileMethod = "ImportToService" Then
		Await CompleteImportToService();
		Result.Insert("FileID", Context.ImportParameters.FileID);
	EndIf;
	
	Progress = 100;
	Status(NStr("vi = 'Tập tin được đặt';
				|ru = 'Файл помещен';
				|en = 'File placed'; fa = 'File placed';
				|it = 'File allocato';
				|pl = 'Plik jest umieszczony';
				|tr = 'Dosya yerleştirildi'"));
	ImportCompleted = True;
	
	Result.Insert("FileNameOrAddress", FileNameOrAddress);
	Result.Insert("FileNameAtClient", FileNameAtClient);
	
	Close(Result);
	
EndFunction

&AtClient
Procedure CancelDownload()
	
	//@skip-check empty-except-statement
	Try
		
		If PlacingFileMethod = "ImportToService" Then
			CancelImportToService();
		Else
			CancelImportAtServer();
		EndIf;
	Except
		// When canceling the upload, we do not cause exceptions, because it is necessary to close the form.
	EndTry;
	
	ImportCompleted = True;
	Close();
	
EndProcedure

&AtServer
Procedure CancelImportAtServer()
	
	FileProperties = FilesCTL.TemporaryStorageFileProperties(FileNameOrAddress);
	If FileProperties.Registered Then
		FilesCTL.DeleteTemporaryStorageFile(FileNameOrAddress);
	Else
		FileNameAtServer = FilesCTL.FullNameOfFileInSession(FileNameOrAddress, WindowsFilePath, LinuxFilePath);
		// @skip-check module-nstr-camelcase - verification error
		EventNameLR = NStr("vi = 'Xóa tập tin. Hủy tải lên';
							|ru = 'Удаление файла.Отмена загрузки';
							|en = 'Delete file.Cancel import'; fa = 'Delete file.Cancel import';
							|it = 'Удаление файла.Отмена загрузки';
							|pl = 'Usunięcie pliku. Anulowanie pobierania';
							|tr = 'Dosyanın silinmesi.Dışa aktarma iptal'", Common.DefaultLanguageCode());
		FilesCTL.DeleteFilesInAttempt(FileNameAtServer, EventNameLR);
	EndIf;
	
EndProcedure

// In case of an error.
// 
// Parameters:
//  ErrorInfo - ErrorInfo
//  StandardProcessing - Boolean
//  AdditionalParameters - Structure
&AtClient
Procedure OnError(ErrorInfo, StandardProcessing, AdditionalParameters) Export
	CancelDownload();
EndProcedure

#EndRegion
