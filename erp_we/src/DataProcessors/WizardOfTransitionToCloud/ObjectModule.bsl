#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal

// Returns the version.
// 
// Returns:
//  Number
Function Version() Export
	
	Return 1.2;
	
EndFunction
 
// Returns the NTTP connection
// 
// Parameters: 
//  Address - String
//  Login - String
//  Password - String
//  Timeout - Number
// 
// Returns:
//  HTTPConnection
Function Join(Address, Login = Undefined, Password = Undefined, Timeout = 30) Export

	AddressParts = CommonClientServer.URIStructure(Address);
	Join = New HTTPConnection(AddressParts.Host, 443, Login, Password,
		GetFilesFromInternet.GetProxy(AddressParts.Schema), Timeout,
		CommonClientServer.NewSecureConnection());
	
	Return Join;
	
EndFunction

// Obtain data
// 
// Parameters:
//  Parameters - Structure:
// * Address - String
// * Method - String
//  ResultAddress - String - address of the result room
// 
// Returns: 
//  See QueryResult
Function GetData(Parameters, ResultAddress) Export
	
	Address = Parameters.Address;
	Method = Parameters.Method;
	
	Join = Join(Address);
	Query = New HTTPRequest(StrTemplate("/info/hs/migration/%1", Method));
	
	Try
		Response = Join.CallHTTPMethod("GET", Query);
		Result = QueryResult(Response);
	Except
		ErrorInfo = ErrorInfo();
		Result = QueryExecutionError(ErrorInfo);
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
	Return Result;
	
EndFunction

Procedure SendData(Parameters, ResultAddress) Export
	
	Address = Parameters.Address;
	Method = Parameters.Method;
	Data = Parameters.Data;
	
	Join = Join(Address);
	Query = New HTTPRequest(StrTemplate("/info/hs/migration/%1", Method));
	Query.SetBodyFromString(SaaSOperationsCTL.StringFromJSONStructure(Data));
	Try
		Response = Join.CallHTTPMethod("POST", Query);
		PutToTempStorage(QueryResult(Response), ResultAddress);
	Except
		ErrorInfo = ErrorInfo();
		PutToTempStorage(QueryExecutionError(ErrorInfo), ResultAddress);
	EndTry;
	
EndProcedure

Function ExecuteExternalInterfaceMethod(Parameters, ResultAddress) Export
	
	APIAddress = Parameters.APIAddress;
	Method = Parameters.Method;
	MethodComposition = StrSplit(Method,"/");
	RequestType_ = MethodComposition[0];
	MethodComposition.Delete(0);
	Method = StrConcat(MethodComposition, "/");
	
	SoftwareInterfaceVersion = 0;
	Parameters.Property("SoftwareInterfaceVersion", SoftwareInterfaceVersion);
	MethodInAddressIsSupported = (SoftwareInterfaceVersion <> Undefined And SoftwareInterfaceVersion >=19);
	
	Authorization = Parameters.Authorization;
	Data = Parameters.Data;
	If Parameters.Property("Timeout") Then
		Timeout = Parameters.Timeout;
	Else
		Timeout = 30;
	EndIf;
	
	URLStructure1 = CommonClientServer.URIStructure(APIAddress);
	Join = Join(URLStructure1.Host, Authorization.Login, Authorization.Password, Timeout);
	
	ResourceAddress = StrTemplate("%1/execute", URLStructure1.PathAtServer);
	If MethodInAddressIsSupported Then
		ResourceAddress = ResourceAddress + "/" + RequestType_ + "/" + Method;
	EndIf;
	Query = New HTTPRequest(ResourceAddress);
	
	If Data <> Undefined Then
		QueryData = Common.CopyRecursive(Data);
	Else
		QueryData = New Structure;
	EndIf; 
	
	If Not MethodInAddressIsSupported Then
		MainSection_ = New Structure;
		MainSection_.Insert("type", RequestType_);
		MainSection_.Insert("method", Method);
		If TypeOf(QueryData) = Type("Structure") Then
			QueryData.Insert("general", MainSection_);
		EndIf;
	EndIf;
	
	If Authorization.Property("SubscriberCode") Then
		AuthorizationSection = New Structure;
		AuthorizationSection.Insert("account", Authorization.SubscriberCode);
		If TypeOf(QueryData) = Type("Structure") Then
			QueryData.Insert("auth", AuthorizationSection);
		EndIf;
	EndIf;
	
	Query.SetBodyFromString(SaaSOperationsCTL.StringFromJSONStructure(QueryData));
	
	Try
		Response = Join.CallHTTPMethod("POST", Query);
		Result = QueryResult(Response);
	Except
		ErrorInfo = ErrorInfo();
		Result = QueryExecutionError(ErrorInfo);
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
	Return Result;
	
EndFunction

// Transfers the file to the cloud service server.
// 
// Parameters:
//  Parameters - Structure:
//   * APIAddress - String
//   * SoftwareInterfaceVersion - Number
//   * Login - String
//   * Password - String
//   * SubscriberCode - Number
//   * FileName - String
//   * FileSize - Number
//   * TemporaryStorageFileName - String
//  ResultAddress - String - the address of saving the result in temporary storage.
//
Procedure TransferFile_(Parameters, ResultAddress) Export
	
	MethodParameters = New Structure;
	MethodParameters.Insert("APIAddress", Parameters.APIAddress);
	MethodParameters.Insert("SoftwareInterfaceVersion", Parameters.SoftwareInterfaceVersion);
	MethodParameters.Insert("Authorization", AuthorizationParameters(Parameters.Login, Parameters.Password));
	MethodParameters.Insert("Method", "srv/files/new_multipart");
	
	Data = New Structure;
	Data.Insert("name", Parameters.FileName);
	Data.Insert("size", Parameters.FileSize);
	Data.Insert("type", "new_data_dump");
	Data.Insert("owner", Parameters.SubscriberCode);
	
	MethodParameters.Insert("Data", Data);
	
	Result = ExecuteExternalInterfaceMethod(MethodParameters, ResultAddress);
	
	If Result.Error Then
		Return;
	EndIf;
	
	FileID = Result.Data.file_id;
	FileLocation1 = FilesCTL.FullTemporaryStorageFileName(Parameters.TemporaryStorageFileName);
	Location = Result.Data.url;
	
	If Result.Data.type = "s3" Then
		
		BlockSize = 1024 * 1024 * 100; // 100 MB
		URIStructure = CommonClientServer.URIStructure(Location);
		Join = Join(Location);
		DataStream = FileStreams.Open(FileLocation1, FileOpenMode.Open, FileAccess.Read);
		SendingRange = New Structure;
		SendingRange.Insert("Begin", 0);
		SendingRange.Insert("End", Min(BlockSize - 1, Parameters.FileSize - 1));
		Parts = New Array;
		While True Do
			Buffer = New BinaryDataBuffer(SendingRange.End - SendingRange.Begin + 1);
			DataStream.Read(Buffer, 0, Buffer.Size);
			DataRequest = New HTTPRequest(URIStructure.PathAtServer);
			DataRequest.SetBodyFromBinaryData(GetBinaryDataFromBinaryDataBuffer(Buffer));
			For Each Title In Result.Data.headers Do
				KeyValue = StrSplit(Title, ":");
				DataRequest.Headers.Insert(KeyValue[0], KeyValue[1]);
			EndDo; 
			Response = Join.CallHTTPMethod("PUT", DataRequest);
			If Response.StatusCode <> 200 Then
				DataStream.Close();
				MethodParameters.Method = "srv/files/abort_multipart";
				MethodParameters.Data = New Structure("file_id", FileID);
				ExecuteExternalInterfaceMethod(MethodParameters, ResultAddress);
				Result = ResultTemplate();
				Result.Error = True;
				Result.ErrorMessage = StrTemplate(
					NStr("vi = 'Không gửi được một phần của tệp, mã phản hồi: %1%2%3';
						|ru = 'Не удалось отправить часть файла, код ответа: %1%2%3';
						|en = 'Cannot send the file part. Response code: %1%2%3'; fa = 'Cannot send the file part. Response code: %1%2%3';
						|it = 'Impossibile inviare una parte del file, codice di risposta: %1%2%3';
						|pl = 'Nie udało się wysłać części pliku, kod odpowiedzi: %1%2%3';
						|tr = 'Dosyanın bir kısmı gönderilemedi, cevap kodu: %1%2%3'"), 
					Response.StatusCode, Chars.LF, Response.GetBodyAsString());
				PutToTempStorage(Result, ResultAddress);
				Return;
			EndIf;
			Parts.Add(StrReplace(CommonCTLClientServer.HTTPHeader(Response, "ETag"),"""",""));
			SendingRange.Begin = SendingRange.End + 1;
			SendingRange.End = Min(SendingRange.End + BlockSize, Parameters.FileSize - 1);
			If SendingRange.Begin > SendingRange.End Then // everything is transferred
				Break;
			EndIf;
			MethodParameters.Method = "srv/files/new_part";
			MethodParameters.Data = New Structure("file_id, part_number", FileID, Parts.Count() + 1);
			Result = ExecuteExternalInterfaceMethod(MethodParameters, ResultAddress);
			If Result.Error Then
				DataStream.Close();
				Return;
			EndIf;
			URIStructure = CommonClientServer.URIStructure(Result.Data.url);
		EndDo;
		DataStream.Close();
		
		MethodParameters.Method = "srv/files/complete_multipart";
		MethodParameters.Data = New Structure("file_id, parts", FileID, Parts);
		ExecuteExternalInterfaceMethod(MethodParameters, ResultAddress);
		If Result.Error Then
			Return;
		EndIf;
			
	Else
		
		AccessParameters = New Structure;
		AccessParameters.Insert("URL", Parameters.APIAddress);
		AccessParameters.Insert("UserName", Parameters.Login);
		AccessParameters.Insert("Password", Parameters.Password);
		
		SendOptions = New Structure;
		SendOptions.Insert("Location", Location);
		SendOptions.Insert("SetCookie", Undefined);
		
		Result = DataTransferServer.SendPartOfFileToLogicalStorage(
			AccessParameters, SendOptions, FileLocation1);
			
		If Result = Undefined Then
			Result = ResultTemplate();
			Result.Error = True;
			Result.ErrorMessage = StrTemplate(
				NStr("vi = 'Không thể gửi tệp theo địa chỉ: %1';
					|ru = 'Не удалось отправить файл по адресу: %1';
					|en = 'Cannot send the file to: %1'; fa = 'Cannot send the file to: %1';
					|it = 'Не удалось отправить файл по адресу: %1';
					|pl = 'Cannot send the file to: %1';
					|tr = 'Bu adrese dosya gönderilemedi: %1'"), Location);
			PutToTempStorage(Result, ResultAddress);
			Return;
		EndIf;
		
	EndIf;
	
	Result = ResultTemplate();
	Result.Insert("FileID", FileID);
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

// Returns the authorization parameters.
// 
// Parameters: 
//  Login - String
//  Password - String
//  SubscriberCode - Number
// 
// Returns: 
//  Structure - Authorization parameters:
// * Login - String
// * Password - String
// * SubscriberCode - Number - if the value is passed in the parameters
Function AuthorizationParameters(Login, Password, SubscriberCode = Undefined) Export
	
	AuthorizationParameters = New Structure;
	AuthorizationParameters.Insert("Login", Login);
	AuthorizationParameters.Insert("Password", Password);
	If Not SubscriberCode = Undefined Then
		AuthorizationParameters.Insert("SubscriberCode", SubscriberCode);
	EndIf; 
	
	Return AuthorizationParameters;
	
EndFunction

Procedure GetInformationAboutTransitionOptions(Parameters, ResultAddress) Export

	QueryOptions = New Structure;
	QueryOptions.Insert("Address", Parameters.Address);
	QueryOptions.Insert("Method", Parameters.MethodInformation);
	
	Result = New Structure;
	Result.Insert("Information", GetData(QueryOptions, ResultAddress));
	
	QueryOptions.Insert("Method", Parameters.LoadingOptionsMethod);
	Result.Insert("ImportOptions", GetData(QueryOptions, ResultAddress));
	Result.Insert("VersionOfProcessingOnServer", 0);
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure CheckPlusExtensions(Parameters, ResultAddress) Export
	Result = New Structure;
	Result.Insert("Error", False);
	Result.Insert("ErrorMessage", "");
	
	Try
		Result.Insert("Data", ExportImportDataInternal.CheckPlusExtensions());
	Except
		Result.Error = True;
		Result.ErrorMessage = CloudTechnology.DetailedErrorText(ErrorInfo());
	EndTry;
		
	PutToTempStorage(Result, ResultAddress);
EndProcedure

#EndRegion 
 
#Region Private

// Parameters:
//  Response - HTTPResponse
//  IncludeHeadings - Boolean
// 
// Returns:
//  Structure:
//   * Headers - Array of String
//   * Data - Arbitrary
//   * ErrorMessage - String
//   * Error - Boolean
//   * ResponseBody - String
//   * StatusCode - Number
Function QueryResult(Response, IncludeHeadings = False)
	
	ResponseString = Response.GetBodyAsString();
	
	Result = ResultTemplate();
	
	If IncludeHeadings Then
		Headers = New Array;
		For Each Title In Response.Headers Do
			Headers.Add(StrTemplate("%1:%2", Title.Key, Title.Value));
		EndDo; 	
		Result.Insert("Headers", Headers);
	EndIf; 
	
	Result.StatusCode = Response.StatusCode;
	Result.ResponseBody = ResponseString;
	Result.Error = (Response.StatusCode > 204);
	
	If Response.StatusCode = 401 Then
		Result.ErrorMessage = NStr("vi = 'Lỗi đăng nhập. Đã đặt sai tên đăng nhập hoặc mật khẩu.';
									|ru = 'Ошибка авторизации. Неправильно задан логин или пароль.';
									|en = 'Authorization error. Username or password is incorrect.'; fa = 'Authorization error. Username or password is incorrect.';
									|it = 'Errore di accesso. Login o password errati.';
									|pl = 'Błąd autoryzacji. Nieprawidłowo jest zadany login lub hasło.';
									|tr = 'Kimlik doğrulama hatası. Hatalı kullanıcı adı veya parola.'"); 
	ElsIf Response.StatusCode = 403 Then
		Result.ErrorMessage = NStr("vi = 'Lỗi đăng nhập. Người sử dụng không có quyền đối với giao diện chương trình.';
									|ru = 'Ошибка авторизации. У пользователя нет доступа к программному интерфейсу.';
									|en = 'Authorization error. User does not have access to API.'; fa = 'Authorization error. User does not have access to API.';
									|it = 'Errore di accesso. L''utente non ha l''accesso all''interfaccia di programmazione.';
									|pl = 'Błąd autoryzacji. Użytkownik nie ma dostępu do interfejsu programowego.';
									|tr = 'Kimlik doğrulama hatası. Kullanıcının programlama arayüzüne erişimi bulunmuyor.'");
	ElsIf Response.StatusCode = 404 Then
		Result.ErrorMessage = NStr("vi = 'Không tìm thấy. Đã điền sai địa chỉ dịch vụ hoặc không tìm thấy dịch vụ.';
									|ru = 'Не найдено. Адрес сервиса указан неверно или сервис не найден.';
									|en = 'Not found. Service address is incorrect or service is not found.'; fa = 'Not found. Service address is incorrect or service is not found.';
									|it = 'Не найдено. Адрес сервиса указан неверно или сервис не найден.';
									|pl = 'Not found. Service address is incorrect or service is not found.';
									|tr = 'Bulunamadı. Servis adresi yanlış belirtildi veya servis bulunamadı.'");
	ElsIf Response.StatusCode >= 500 Then
		Result.ErrorMessage = NStr("vi = 'Lỗi nội bộ. Chi tiết xem trong nhật ký sự kiện.';
									|ru = 'Внутренняя ошибка. Подробности в журнале регистрации.';
									|en = 'Internal error. For more information, see the event log.'; fa = 'Internal error. For more information, see the event log.';
									|it = 'Errore interno. Vedi dettagli nel registro degli eventi.';
									|pl = 'Błąd wewnętrzny. Szczegóły znajdują się w dzienniku rejestracji.';
									|tr = 'Dahili hata. Ayrıntılar için kayıt günlüğüne bakın.'");
	EndIf;
	
	If Result.Error Then
		WriteLogEvent(
			NStr("vi = 'Chuyển sang đám mây';
				|ru = 'Переход в облако';
				|en = 'Cloud migration'; fa = 'مهاجرت ابری';
				|it = 'Passaggio al cloud';
				|pl = 'Przejście do chmury';
				|tr = 'Buluta geçiş'"), 
			EventLogLevel.Error,,,
			ResponseString);
		If Not IsBlankString(ResponseString) Then
			//@skip-check empty-except-statement - If we couldn't get the data, we don't try to return it.
			Try
				Result.Data = SaaSOperationsCTL.StructureFromJSONString(ResponseString);	
				If Result.Data.Property("message") Then
					Result.ErrorMessage = Result.Data.message;
				ElsIf Result.Data.Property("description") Then
					Result.ErrorMessage = Result.Data.description;
				EndIf; 
			Except
			EndTry;
		EndIf; 
			
		Return Result;
	ElsIf Not IsBlankString(ResponseString) Then
		Result.Data = SaaSOperationsCTL.StructureFromJSONString(ResponseString);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function QueryExecutionError(ErrorInfo)
	
	WriteLogEvent(
		NStr("vi = 'Chuyển sang đám mây';
			|ru = 'Переход в облако';
			|en = 'Cloud migration'; fa = 'مهاجرت ابری';
			|it = 'Passaggio al cloud';
			|pl = 'Przejście do chmury';
			|tr = 'Buluta geçiş'"), 
		EventLogLevel.Error,,,
		CloudTechnology.DetailedErrorText(ErrorInfo));
		
	Result = ResultTemplate();
	Result.Error = True;
	Result.ErrorMessage = CloudTechnology.DetailedErrorText(ErrorInfo);
	
	Return Result;
	
EndFunction

Function ResultTemplate()
	
	Result = New Structure;
	Result.Insert("StatusCode", 0);
	Result.Insert("ResponseBody", "");
	Result.Insert("Error", False);
	Result.Insert("ErrorMessage", "");
	Result.Insert("Data", Undefined);
	
	Return Result;
	
EndFunction
 
#EndRegion 

#EndIf