///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("ClientID") 
		Or Not Parameters.Property("ClientSecret") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", 
			Common.DefaultLanguageCode());
		
	EndIf;
		
	HTMLField = DataProcessors.ExchangeMessageTransportGoogleDrive.GetTemplate("ReceiveToken_ru").GetText();
	
	FillPropertyValues(ThisObject, Parameters, "ClientID,ClientSecret");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GetToken(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ClientID", ClientID);
	
	Notification = New CallbackDescription("GetTokenCompletion", ThisObject);
	
	OpenForm("DataProcessor.ExchangeMessageTransportGoogleDrive.Form.AuthorizationForm",
		FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GetTokenCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Code = Result;
		
	Result = GetEndTokenOnServer();
	
	Close(Result);
	
EndProcedure

&AtServer
Function GetEndTokenOnServer()
	
	ServerName = "accounts.google.com";
	ResourceAddress = "/o/oauth2/token";
	
	QueryString = "client_id=" + ClientID + "&" +
		"client_secret=" + ClientSecret + "&" +
		"grant_type=authorization_code" + "&" +
		"code=" + Code + "&" +
		"redirect_uri=http://localhost";
	
	Headers  = New Map;
	Headers.Insert("Content-Type","application/x-www-form-urlencoded");

	Query = New HTTPRequest(ResourceAddress, Headers);
	Query.SetBodyFromString(QueryString);
	
	SecureConnection = CommonClientServer.NewSecureConnection();
	Proxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Proxy = ModuleNetworkDownload.GetProxy("https");
	EndIf;
	Join = New HTTPConnection(ServerName, 443,,, Proxy, 20, SecureConnection);
	
	Response = Join.Post(Query);
	ResponseBody = Response.GetBodyAsString(TextEncoding.UTF8);
	QueryResult = ExchangeMessagesTransport.JSONValue(ResponseBody);
	
	If Response.StatusCode <> 200 Then
		
		ErrorMessage = QueryResult["error"]["message"];
		Common.MessageToUser(ErrorMessage);
		
		Return Undefined;
		
	EndIf;

	Result = New Structure();
	Result.Insert("AccessToken", QueryResult["access_token"]); 
	Result.Insert("RefreshToken", QueryResult["refresh_token"]);
	Result.Insert("ExpiresIn", CurrentSessionDate() + QueryResult["expires_in"]);
	Result.Insert("ClientID", ClientID);
	Result.Insert("ClientSecret", ClientSecret);
	
	Return Result;
	
EndFunction

#EndRegion
