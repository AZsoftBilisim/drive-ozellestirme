///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

Function SendTheAuthorizationCode(Query)
	
	Try
		
		QueryOptions = QueryOptions(Query);
		SendServerNotification(QueryOptions);
		
		ResponseCode = ResponseCodes().Success;
		ResponseText = SuccessfulResponseText();
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		If ErrorInfo.Code = "UnknownQuery" Then
			ResponseCode = ResponseCodes().UnknownQuery;
		Else
			ResponseCode = ResponseCodes().InternalError;
		EndIf;
		
		ResponseText = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		
		EventName = EventName() + "." + NStr("ru = 'Исключение при отправке кода авторизации';
											|vi = 'Exception while sending authorization code';
											|en = 'Exception while sending authorization code'; fa = 'Exception while sending authorization code';
											|it = 'Exception while sending authorization code';
											|pl = 'Exception while sending authorization code';
											|tr = 'Yetkilendirme kodu gönderimi istisnası'", DefaultLanguageCode());
		WriteLogEvent(EventName, EventLogLevel.Error, , , ResponseText);
		
	EndTry;
	
	Response = New HTTPServiceResponse(ResponseCode);
	Response.Headers.Insert("Content-Type", "text/html; charset=utf-8");
	Response.SetBodyFromString(ResponseText);
	
	Return Response;
	
EndFunction

Function CheckServiceAvailability(Query)
	
	ResponseCode = ResponseCodes().Success;
	
	Response = New HTTPServiceResponse(ResponseCode);
	Response.Headers.Insert("Content-Type", "text/html; charset=utf-8");
	Response.SetBodyFromString("success");
	
	Return Response;
	
EndFunction

#EndRegion

#Region Private

Function QueryOptions(Query)
	
	RequestIncomingParameters = Query.QueryOptions;
	
	QueryProcessedParameters = New Structure;
	QueryProcessedParameters.Insert("AuthorizationCode");
	QueryProcessedParameters.Insert("SessionNumber");
	QueryProcessedParameters.Insert("AreaNumber");
	QueryProcessedParameters.Insert("QueryID");
	QueryProcessedParameters.Insert("UserIdentificator");
	
	FillAuthorizationCode(RequestIncomingParameters, QueryProcessedParameters);
	FillSessionNumber(RequestIncomingParameters, QueryProcessedParameters);
	FillAreaNumber(RequestIncomingParameters, QueryProcessedParameters);
	FillQueryID(RequestIncomingParameters, QueryProcessedParameters);
	FillUserID(RequestIncomingParameters, QueryProcessedParameters);
	
	Return QueryProcessedParameters;
	
EndFunction

Procedure FillAuthorizationCode(Source, Receiver)
	
	AuthorizationCode = Source.Get("code");
	
	If AuthorizationCode = Undefined Then
		ResponseText = NStr("ru = 'Не заполнен обязательный параметр запроса ""code""';
							|vi = 'The required request parameter ""code"" is not filled in.';
							|en = 'The required request parameter ""code"" is not filled in.'; fa = 'The required request parameter ""code"" is not filled in.';
							|it = 'The required request parameter ""code"" is not filled in.';
							|pl = 'The required request parameter ""code"" is not filled in.';
							|tr = 'Zorunlu sorgu parametresi ""code"" doldurulmadı'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownQuery");
	EndIf;
	
	Receiver.AuthorizationCode = AuthorizationCode;
	
EndProcedure

Procedure FillSessionNumber(Source, Receiver)
	
	SessionNumber = Source.Get("session");
	
	If SessionNumber = Undefined Then
		ResponseText = NStr("ru = 'Не заполнен обязательный параметр запроса ""session""';
							|vi = 'The required request parameter ""session"" is not filled in.';
							|en = 'The required request parameter ""session"" is not filled in.'; fa = 'The required request parameter ""session"" is not filled in.';
							|it = 'The required request parameter ""session"" is not filled in.';
							|pl = 'The required request parameter ""session"" is not filled in.';
							|tr = 'Zorunlu sorgu parametresi ""session"" doldurulmadı'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownQuery");
	EndIf;
	
	Try
		SessionNumber = Number(SessionNumber);
	Except
		ResponseText = NStr("ru = 'Параметра запроса ""session"" не является числом';
							|vi = 'Request parameter ""session"" is not a number';
							|en = 'Request parameter ""session"" is not a number'; fa = 'Request parameter ""session"" is not a number';
							|it = 'Request parameter ""session"" is not a number';
							|pl = 'Request parameter ""session"" is not a number';
							|tr = '""session"" sorgu parametresi bir sayı değil'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownQuery");
	EndTry;
	
	Receiver.SessionNumber = SessionNumber;
	
EndProcedure

Procedure FillAreaNumber(Source, Receiver)
	
	AreaNumber = Source.Get("zone");
	
	If AreaNumber = Undefined Then
		ResponseText = NStr("ru = 'Не заполнен обязательный параметр запроса ""zone""';
							|vi = 'The required request parameter ""zone"" is not filled in.';
							|en = 'The required request parameter ""zone"" is not filled in.'; fa = 'The required request parameter ""zone"" is not filled in.';
							|it = 'The required request parameter ""zone"" is not filled in.';
							|pl = 'The required request parameter ""zone"" is not filled in.';
							|tr = 'Zorunlu sorgu parametresi ""zone"" doldurulmadı'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownQuery");
	EndIf;
	
	Try
		AreaNumber = Number(AreaNumber);
	Except
		ResponseText = NStr("ru = 'Параметра запроса ""zone"" не является числом';
							|vi = 'Request parameter ""zone"" is not a number';
							|en = 'Request parameter ""zone"" is not a number'; fa = 'Request parameter ""zone"" is not a number';
							|it = 'Request parameter ""zone"" is not a number';
							|pl = 'Request parameter ""zone"" is not a number';
							|tr = '""zone"" sorgu parametresi bir sayı değil'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownQuery");
	EndTry;
	
	Receiver.AreaNumber = AreaNumber;
	
EndProcedure

Procedure FillQueryID(Source, Receiver)
	
	QueryID = Source.Get("request_id");
	
	If QueryID = Undefined Then
		ResponseText = NStr("ru = 'Не заполнен обязательный параметр запроса ""request_id""';
							|vi = 'The required request parameter ""request_id"" is not filled in.';
							|en = 'The required request parameter ""request_id"" is not filled in.'; fa = 'The required request parameter ""request_id"" is not filled in.';
							|it = 'The required request parameter ""request_id"" is not filled in.';
							|pl = 'The required request parameter ""request_id"" is not filled in.';
							|tr = 'Zorunlu sorgu parametresi ""request_id"" doldurulmadı'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownQuery");
	EndIf;
	
	Try
		QueryID = New UUID(QueryID);
	Except
		ResponseText = NStr("ru = 'Параметра запроса ""request_id"" не является уникальным идентификатором';
							|vi = 'Request parameter ""request_id"" is not a unique ID';
							|en = 'Request parameter ""request_id"" is not a unique ID'; fa = 'Request parameter ""request_id"" is not a unique ID';
							|it = 'Request parameter ""request_id"" is not a unique ID';
							|pl = 'Request parameter ""request_id"" is not a unique ID';
							|tr = '""request_id"" sorgu parametresi benzersiz bir tanımlayıcı değil'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownQuery");
	EndTry;
	
	Receiver.QueryID = QueryID;
	
EndProcedure

Procedure FillUserID(Source, Receiver)
	
	UserIdentificator = Source.Get("user_id");
	
	If UserIdentificator = Undefined Then
		ResponseText = NStr("ru = 'Не заполнен обязательный параметр запроса ""user_id""';
							|vi = 'The required request parameter ""user_id"" is not filled in.';
							|en = 'The required request parameter ""user_id"" is not filled in.'; fa = 'The required request parameter ""user_id"" is not filled in.';
							|it = 'The required request parameter ""user_id"" is not filled in.';
							|pl = 'The required request parameter ""user_id"" is not filled in.';
							|tr = 'Zorunlu sorgu parametresi ""user_id"" doldurulmadı'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownQuery");
	EndIf;
	
	Try
		UserIdentificator = New UUID(UserIdentificator);
	Except
		ResponseText = NStr("ru = 'Параметра запроса ""user_id"" не является уникальным идентификатором';
							|vi = 'Request parameter ""user_id"" is not a unique ID';
							|en = 'Request parameter ""user_id"" is not a unique ID'; fa = 'Request parameter ""user_id"" is not a unique ID';
							|it = 'Request parameter ""user_id"" is not a unique ID';
							|pl = 'Request parameter ""user_id"" is not a unique ID';
							|tr = '""user_id"" sorgu parametresi benzersiz bir tanımlayıcı değil'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownQuery");
	EndTry;
	
	Receiver.UserIdentificator = UserIdentificator;
	
EndProcedure

Procedure SendServerNotification(QueryOptions)
	
	Context = New Structure;
	Context.Insert("AuthorizationCode", QueryOptions.AuthorizationCode);
	Context.Insert("QueryID", QueryOptions.QueryID);
	
	ServerNotificationParameters = New Structure;
	ServerNotificationParameters.Insert("EventName", "OpenAuthorizationOfTheEmailService");
	ServerNotificationParameters.Insert("Context", Context);
	
	ServerNotificationName = EmailOperationsInternalClientServer.ServerNotificationName();
	ServerNotificationAddressees = ServerNotificationAddressees(QueryOptions);
	
	ServerNotifications.SendServerNotification(
		ServerNotificationName,
		ServerNotificationParameters,
		ServerNotificationAddressees,
		True);
	
EndProcedure

Function ServerNotificationAddressees(QueryOptions)
	
	ServerNotificationAddressees = New Map;
	
	ActiveSessionsOfMonthEndClosing = GetInfoBaseSessions();
	RequiredSession = Undefined;
	
	For Each ActiveSession In ActiveSessionsOfMonthEndClosing Do
		If ActiveSession.SessionNumber = QueryOptions.SessionNumber Then
			RequiredSession = ActiveSession;
			Break;
		EndIf;
	EndDo;
	
	SessionKey = CommonClientServer.ValueInArray(ServerNotifications.SessionKey(RequiredSession));
	ServerNotificationAddressees.Insert(QueryOptions.UserIdentificator, SessionKey);
	
	Return ServerNotificationAddressees;
	
EndFunction

Function SuccessfulResponseText()
	
	SuccessfulResponseText = "<!DOCTYPE html>
		|<html>
		|<head>
		|    <meta charset='utf-8'>
		|    <title>Authorization completed_</title>
		|    <style>
		|        * { margin: 0; padding: 0; box-sizing: border-box; }
		|        body {
		|            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
		|            text-align: center;
		|            padding: 60px 20px;
		|            background: #F7FAFC url(" + ImageOfSuccessfulResponse() + ") no-repeat center bottom;
		|            background-size: contain;
		|            color: #2D3748;
		|            min-height: 100vh;
		|            display: flex;
		|            align-items: center;
		|            justify-content: center;
		|        }
		|        .container {
		|            max-width: 420px;
		|            background: rgba(255,255,255,0.9);
		|            padding: 40px 30px;
		|            border-radius: 16px;
		|            box-shadow: 0 10px 30px rgba(0,0,0,0.08);
		|        }
		|        .message {
		|            font-size: 24px;
		|            margin-bottom: 12px;
		|            font-weight: 600;
		|        }
		|        p {
		|            font-size: 18px;
		|            color: #4A5568;
		|            line-height: 1.6;
		|        }
		|    </style>
		|</head>
		|<body>
		|    <div class='container'>
		|        <div class='message'>Authorization completed_</div>
		|        <p>ThisOne tab can close</p>
		|    </div>
		|    <script>
		|        if (window.history && window.history.replaceState) {
		|            window.history.replaceState({}, document.title, window.location.pathname);
		|        }
		|        window.close();
		|    </script>
		|</body>
		|</html>";
		
	Return SuccessfulResponseText;
	
EndFunction

Function ImageOfSuccessfulResponse()
	
	Picture = PictureLib.CatOpenAuthorizationOfTheEmailService;
	BinaryData = Picture.GetBinaryData();
	
	Base64Row = Base64String(BinaryData);
	Base64Row = StrReplace(Base64Row, Chars.CR, "");
	Base64Row = StrReplace(Base64Row, Chars.LF, "");
	
	ImageOfSuccessfulResponse = "data:image/svg+xml;base64," + Base64Row;
	
	Return ImageOfSuccessfulResponse;
	
EndFunction

Function ResponseCodes()
	
	ResponseCodes = New Structure;
	ResponseCodes.Insert("Success", 200);
	ResponseCodes.Insert("UnknownQuery", 400);
	ResponseCodes.Insert("InternalError", 500);
	
	Return ResponseCodes;
	
EndFunction

Function DefaultLanguageCode()
	
	Return Common.DefaultLanguageCode();
	
EndFunction

Function EventName()
	
	Return NStr("ru = 'Открытая авторизация почтового сервиса';
				|vi = 'Open authorization of the email service';
				|en = 'Open authorization of the email service'; fa = 'بازکردن احراز مجوز سرویس ایمیل';
				|it = 'Open authorization of the email service';
				|pl = 'Open authorization of the email service';
				|tr = 'E-posta servisi açık yetkilendirmesi'", DefaultLanguageCode());
	
EndFunction

#EndRegion
