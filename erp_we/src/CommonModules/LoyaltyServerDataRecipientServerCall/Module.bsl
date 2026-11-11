///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Auxiliary method for processing JSON on a web client
//
// Parameters:
//  JSONString - String - source data in JSON format
//  ResponseData - Structure, Undefined - result of parsing the response
//
Procedure ProcessJSON(JSONString, ResponseData) Export
	
	If ValueIsFilled(JSONString) Then
		
		ReadResponse = New JSONReader;
		ReadResponse.SetString(JSONString);
		
		Try
			ResponseData = ReadJSON(ReadResponse);
		Except
			
			LocalizedMessage = NStr("vi = 'Lỗi phân tích cú pháp JSON, có thể là đã nhận thông báo hệ thống về chương trình khách hàng thân thiết không có hiệu lực.';
									|ru = 'Ошибка разбора JSON, возможно, получено служебное сообщение о недоступности сервера лояльности.';
									|en = 'An error occurred when parsing JSON. An internal message about the loyalty server unavailability might have been received.'; fa = 'An error occurred when parsing JSON. An internal message about the loyalty server unavailability might have been received.';
									|it = 'Ошибка разбора JSON, возможно, получено служебное сообщение о недоступности сервера лояльности.';
									|pl = 'An error occurred when parsing JSON. An internal message about the loyalty server unavailability might have been received.';
									|tr = 'JSON ayrıştırma hatası, sadakat sunucusunun kullanılamadığına dair bir hizmet mesajı alınmış olabilir.'");
			
			DefaultLanguageCode = Undefined;
			LoyaltyServerDataRecipientClientServerOverridable.FillInMainLanguageCode(DefaultLanguageCode);
			EventName = NStr("vi = 'Thử phân tích phản hồi từ chương trình khách hàng thân thiết';
							|ru = 'Попытка разбора ответа от сервера лояльности';
							|en = 'An attempt to parse the response from the loyalty server'; fa = 'An attempt to parse the response from the loyalty server';
							|it = 'Попытка разбора ответа от сервера лояльности';
							|pl = 'An attempt to parse the response from the loyalty server';
							|tr = 'Sadakat sunucusundan gelen yanıtı ayrıştırma girişimi'", DefaultLanguageCode);
					
			WriteLogEvent(EventName,
				EventLogLevel.Error, , , LocalizedMessage);
				
		EndTry;
		
	EndIf;
	
EndProcedure

// Auxiliary method for serialization on a web client
//
// Parameters:
//  ParametersStructure - Structure - parameters for serialization
// 
// Returns:
// String - the result of parameter serialization.
//
Function SerializeParameterStructure(ParametersStructure) Export
	
	StructureOfJSONResponse = New JSONWriter;
	StructureOfJSONResponse.SetString();
	WriteJSON(StructureOfJSONResponse, ParametersStructure);
	SerializedParameterStructure = StructureOfJSONResponse.Close();
	
	Return SerializedParameterStructure;
	
EndFunction

// Procedure for batch recording messages in the log.
// After recording, the event variable for the registration Log is cleared.
//
// Parameters:
//  EventName - String - name of the event to record.
//  LocalizedMessage - String - a message to write to the registration Log
//
Procedure WriteEventsToEventLog(EventName, LocalizedMessage) Export
	
	WriteLogEvent(EventName,
				EventLogLevel.Error, , , LocalizedMessage);
	
EndProcedure

// Accesses the resource of the loyalty server 
//
// Parameters:
//  RequestExecutionParameters - Structure:
//		* RequestType_ - String - the default is "POST"
//		* ServerAddress - String
//		* Login - String
//		* Password - String
//		* Resource - String
//		* MethodParameters - Structure
//		* InternetProxy - String
//
// Returns:
//   Structure:
//		* ResponseData - String
//		* HasErrors - Boolean
//		* ErrorText - String
//
Function MakeRequestToLoyaltyServer(RequestExecutionParameters) Export
	
	ExecutionResult = LoyaltyServerDataRecipientClientServer.ResultOfDefaultRequest();
	
	If LoyaltyServerDataRecipientClientServer.RequestExecutionParametersAreCorrect(RequestExecutionParameters) Then
		
		ConnectionParameters = LoyaltyServerDataRecipientClientServer.GetConnectionParametersFromLine(RequestExecutionParameters.ServerAddress);
		
		RequestType_				= RequestExecutionParameters.RequestType_;
		ServerAddress			= ConnectionParameters.ServerAddress;
		Login					= RequestExecutionParameters.Login;
		Password 					= RequestExecutionParameters.Password;
		Resource					= RequestExecutionParameters.Resource;
		Port					= ConnectionParameters.ConnectionPort;
		InternetProxy			= GetFilesFromInternet.GetProxy(ServerAddress);
		SecureConnection	= ?(ConnectionParameters.ThisIsSecureConnection,
			CommonClientServer.NewSecureConnection(), Undefined);
		
		MethodParameters = RequestExecutionParameters.MethodParameters;
		
		AddParametersToResource(Resource, MethodParameters);
		
		DefaultTimeout = 60;
		TimeoutInSeconds = ?(RequestExecutionParameters.Timeout = 0, DefaultTimeout, RequestExecutionParameters.Timeout);
		HTTPConnection = New HTTPConnection(ServerAddress,, Login, Password, InternetProxy, TimeoutInSeconds,
			SecureConnection);
		NTTRRequest = New HTTPRequest(Resource);
		
		If RequestExecutionParameters.Property("RequestBody")
			And Not IsBlankString(RequestExecutionParameters.RequestBody) Then 
			
			NTTRRequest.SetBodyFromString(RequestExecutionParameters.RequestBody);
			
		EndIf;
		
		EventName = NStr("vi = 'Kết nối với server khách hàng thân thiết.';
						|ru = 'Соединение с сервером лояльности.';
						|en = 'Loyalty server connection.'; fa = 'Loyalty server connection.';
						|it = 'Соединение с сервером лояльности.';
						|pl = 'Loyalty server connection.';
						|tr = 'Sadakat sunucusuna bağlantı.'");
		Try
			
			Response = HTTPConnection.CallHTTPMethod(RequestType_, NTTRRequest);
			
			StatusCode = Response.StatusCode;
			
			ExecutionResult.HasErrors = (StatusCode > 200);
			
			If StatusCode >= 500 Then
				
				ErrorText = StrTemplate(
				NStr("vi = 'Khi thực hiện truy vấn đến chương trình khách hàng thân thiết đã xảy ra lỗi ở phía máy chủ. Mã lỗi: %1';
					|ru = 'При выполнении запроса к серверу лояльности возникла ошибка на стороне сервера. Код ошибки: %1';
					|en = 'An error occurred on the server when executing the request to the loyalty server. Error code: %1'; fa = 'An error occurred on the server when executing the request to the loyalty server. Error code: %1';
					|it = 'При выполнении запроса к серверу лояльности возникла ошибка на стороне сервера. Код ошибки: %1';
					|pl = 'An error occurred on the server when executing the request to the loyalty server. Error code: %1';
					|tr = 'Sadakat sunucusuna bir talep gerçekleştirirken sunucu tarafında bir hata oluştu. Hata kodu: %1'"),
				StatusCode);
				WriteLogEvent(EventName, EventLogLevel.Error,,,ErrorText);
				
			ElsIf StatusCode >= 400 Then
				
				ErrorText = StrTemplate(
				NStr("vi = 'Đã chỉ định sai tham số thực hiện truy vấn đến chương trình khách hàng thân thiết. Mã lỗi: %1';
					|ru = 'Некорректно указаны параметры выполнения запроса к серверу лояльности. Код ошибки: %1';
					|en = 'Parameters for executing the request to the loyalty server are specified incorrectly. Error code: %1'; fa = 'Parameters for executing the request to the loyalty server are specified incorrectly. Error code: %1';
					|it = 'Некорректно указаны параметры выполнения запроса к серверу лояльности. Код ошибки: %1';
					|pl = 'Parameters for executing the request to the loyalty server are specified incorrectly. Error code: %1';
					|tr = 'Sadakat sunucusuna yapılan talebin yerine getirilmesi için gerekli parametreler doğru belirtilmedi. Hata kodu: %1'"),
				StatusCode);
				WriteLogEvent(EventName, EventLogLevel.Error,,,ErrorText);
			EndIf;
			
			ExecutionResult.ErrorText = ErrorText;
			
		Except
			
			ErrorInfo = ErrorInfo();
			
			ExecutionResult.HasErrors = True;
			ErrorText = StrTemplate(
			NStr("vi = 'Kiểu yêu cầu: %1
			|Địa chỉ server: %2
			|Tên đăng nhập: %3
			|Mật khẩu: %4
			|Nguồn: %5
			|Mô tả lỗi: %6';
			|ru = 'Тип запроса: %1
			|Адрес сервера: %2
			|Логин: %3
			|Пароль: %4
			|Ресурс: %5
			|Описание ошибки: %6';
			|en = 'Request type: %1
			|Server address: %2
			|Username: %3
			|Password: %4
			|Resource: %5
			|Error details: %6'; fa = 'Request type: %1
			|Server address: %2
			|Username: %3
			|Password: %4
			|Resource: %5
			|Error details: %6';
			|it = 'Тип запроса: %1
			|Адрес сервера: %2
			|Логин: %3
			|Пароль: %4
			|Ресурс: %5
			|Описание ошибки: %6';
			|pl = 'Request type: %1
			|Server address: %2
			|Username: %3
			|Password: %4
			|Resource: %5
			|Error details: %6';
			|tr = 'İstek türü: %1
			|Sunucu adresi: %2
			|Kullanıcı adı: %3
			|Şifre: %4
			|Kaynak: %5
			|Hata ayrıntıları: %6'"),
			String(RequestType_),
			String(ServerAddress),
			String(Login),
			NStr("vi = '********';
				|ru = '********';
				|en = '********'; fa = '********';
				|it = '********';
				|pl = '********';
				|tr = '********'"),
			String(Resource),
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
			ExecutionResult.ErrorText = ErrorText;
			WriteLogEvent(EventName, EventLogLevel.Error,,,ErrorText);
			
		EndTry;
		
		If ExecutionResult.HasErrors Then
			Return ExecutionResult;
		EndIf;
		
		ResponseData = Response.GetBodyAsString();
		ExecutionResult.ResponseData = ResponseData;
		
	Else
		ExecutionResult.HasErrors = True;
		ExecutionResult.ErrorText =
		NStr("vi = 'Hãy kiểm tra tham số kết nối đã chỉ định với chương trình khách hàng thân thiết trong tùy chỉnh quầy thu ngân.';
			|ru = 'Проверьте указанные параметры соединения с сервером лояльности в настройках РМК.';
			|en = 'Check the specified parameters for connecting to the loyalty server in the settings of the point of sale workplace.'; fa = 'Check the specified parameters for connecting to the loyalty server in the settings of the point of sale workplace.';
			|it = 'Проверьте указанные параметры соединения с сервером лояльности в настройках РМК.';
			|pl = 'Check the specified parameters for connecting to the loyalty server in the settings of the point of sale workplace.';
			|tr = 'KİY ayarlarında belirtilen sadakat sunucusu bağlantı ayarlarını kontrol et.'");
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

#EndRegion

#Region Private

// Adds method parameters to the method resource 
//
// Parameters:
//  Resource - String - method resource, the name of the endpoint to access
//  MethodExecutionParameters - Structure - source data of method parameters
//
Procedure AddParametersToResource(Resource, MethodExecutionParameters)
	
	If ValueIsFilled(Resource)	And ValueIsFilled(MethodExecutionParameters)
		And TypeOf(MethodExecutionParameters) = Type("Structure") Then
	
		MethodParametersAsString = "?";
		
		For Each Parameter In MethodExecutionParameters Do
		
			UnifyingSymbol = ?(StrEndsWith(MethodParametersAsString, "?"),
				"", "&");
			MethodParametersAsString = StrTemplate("%1%2%3=%4",
				MethodParametersAsString, UnifyingSymbol, Parameter.Key, Parameter.Value);
		
		EndDo;
		
		Resource = StrTemplate("/%1/%2", Resource, MethodParametersAsString);

	EndIf;
	
EndProcedure

#EndRegion
