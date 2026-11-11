///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Connect NTTRClient Async.
// 
// Returns:
//   See AddInsCELClient.ConnectionResult
Async Function ConnectHTTPClientAsync() Export
	
	DescriptionOfConnectionComponent = ComponentDetails();
	ObjectName = DescriptionOfConnectionComponent.ObjectName;
	FullTemplateName = DescriptionOfConnectionComponent.FullTemplateName;
	
	Result = AddInsCELClient.ConnectionResult();
	
	ComponentObject = EquipmentManagerClient.DriverObjectFromCache(ObjectName);
	If ComponentObject <> Undefined Then   
		Result.Attached = True;
		Result.Attachable_Module = ComponentObject;   
		Return Result;
	EndIf;
	
	ConnectionResult = Await AddInsCELClient.AttachAddInFromTemplateAsync(ObjectName, FullTemplateName);
	If Not ConnectionResult.Attached Then
		
		InstallResult = Await AddInsCELClient.InstallAddInFromTemplateAsync(FullTemplateName); // Structure
		If Not InstallResult.IsSet Then
			Result.Attached = False;
			Result.ErrorDescription = StrTemplate(NStr("vi = 'Lỗi cài đặt cấu phần: %1: %2';
														|ru = 'Ошибка установки компоненты %1: %2';
														|en = 'An error occurred when installing the add-in %1: %2'; fa = 'An error occurred when installing the add-in %1: %2';
														|it = 'Ошибка установки компоненты %1: %2';
														|pl = 'An error occurred when installing the add-in %1: %2';
														|tr = '%1 eklentisinin kurulumu başarısız oldu: %2'"), ObjectName, InstallResult.ErrorDescription);
			Return Result;
		EndIf;
		
		ConnectionResult = Await AddInsCELClient.AttachAddInFromTemplateAsync(ObjectName, FullTemplateName);
		If Not ConnectionResult.Attached Then
			Result.Attached = False;
			Result.ErrorDescription = StrTemplate(NStr("vi = 'Lỗi kết nối cấu phần %1: %2';
														|ru = 'Ошибка подключения компоненты %1: %2';
														|en = 'Error connecting the add-in %1: %2'; fa = 'Error connecting the add-in %1: %2';
														|it = 'Ошибка подключения компоненты %1: %2';
														|pl = 'Error connecting the add-in %1: %2';
														|tr = '%1 eklentisinin bağlantısı başarısız oldu: %2'"), ObjectName, ConnectionResult.ErrorDescription);
			Return Result;
		EndIf;
		
	EndIf;
	
	FillPropertyValues(Result, ConnectionResult);
	
	EquipmentManagerClient.AddDriverToCache(ObjectName, ConnectionResult.Attachable_Module); 
	
	Return Result; 
	
EndFunction

// version of the component.
// 
// Returns:
//  Promise - Version of Async
// See OperationResult
Async Function VersionAsync() Export
	
	ConnectionResult = Await ConnectHTTPClientAsync();
	If Not ConnectionResult.Attached Then
		Return AddInAttachmentError(ConnectionResult.ErrorDescription);
	EndIf;
	
	DriverObject = ConnectionResult.Attachable_Module;
	Try
		CallResult = Await DriverObject.VersionAsync();    
		OperationResult = OperationResult();
		OperationResult.Insert("Version", CallResult.Value);  
	Except           
		OperationResult = ErrorCallMethodComponents("Version");
	EndTry;
	
	Return OperationResult;
	
EndFunction     

// Calling Put.
// 
// Parameters:
//  URL - String     
//  Body - String
//  Headers - String
// 
// Returns:
//  See OperationResult  
//
Async Function PutAsync(URL, Body, Headers = Undefined) Export
	
	ConnectionResult = Await ConnectHTTPClientAsync();
	If Not ConnectionResult.Attached Then
		Return AddInAttachmentError(ConnectionResult.ErrorDescription);
	EndIf;
	
	DriverObject = ConnectionResult.Attachable_Module;
	ConfiguringJSONConnection = JSONConnectionSettings(URL);
	JSONHeaders = JSONHeaders(Headers);
	Try
		AnswerRow = "";
		CallResult = Await DriverObject.PutAsync(ConfiguringJSONConnection, JSONHeaders, Body, AnswerRow); // AddInAsyncCallResult
		OperationResult = OperationResult();
		OperationResult.ResponseCode = CallResult.Value;
		OperationResult.Response = CallResult.Parameters[2];
		SetHeaders(OperationResult.Headers, CallResult.Parameters[1]);
		If OperationResult.ResponseCode = -1 Then
			Await FillInErrorInformation(DriverObject, OperationResult);
		EndIf;
	Except           
		OperationResult = ErrorCallMethodComponents("Put");
	EndTry;
	
	Return OperationResult;
	
EndFunction

// Calling Get.
// 
// Parameters:
//  URL - String
//  Headers - String
// 
// Returns:
//  See OperationResult  
//
Async Function GetAsync(URL, Headers = Undefined) Export
	
	ConnectionResult = Await ConnectHTTPClientAsync();
	If Not ConnectionResult.Attached Then
		Return AddInAttachmentError(ConnectionResult.ErrorDescription);
	EndIf;

	DriverObject = ConnectionResult.Attachable_Module;
	ConfiguringJSONConnection = JSONConnectionSettings(URL);
	JSONHeaders = JSONHeaders(Headers);
	Try
		AnswerRow = "";
		CallResult = Await DriverObject.GetAsync(ConfiguringJSONConnection, JSONHeaders, AnswerRow); // AddInAsyncCallResult
		OperationResult = OperationResult();
		OperationResult.ResponseCode = CallResult.Value;
		OperationResult.Response = CallResult.Parameters[2];
		SetHeaders(OperationResult.Headers, CallResult.Parameters[1]);
		If OperationResult.ResponseCode = -1 Then
			Await FillInErrorInformation(DriverObject, OperationResult);
		EndIf;
	Except
		OperationResult = ErrorCallMethodComponents("Get");
	EndTry;
	
	Return OperationResult;
	
EndFunction

// Calling the Post.
// 
// Parameters:
//  URL - String
//  Body - String
//  Headers - Map of KeyAndValue
// 
// Returns:
//  See OperationResult    
//
Async Function PostAsync(URL, Body, Headers = Undefined) Export
	
	ConnectionResult = Await ConnectHTTPClientAsync();
	If Not ConnectionResult.Attached Then
		Return AddInAttachmentError(ConnectionResult.ErrorDescription);
	EndIf;
	
	DriverObject = ConnectionResult.Attachable_Module;
	ConfiguringJSONConnection = JSONConnectionSettings(URL);
	JSONHeaders = JSONHeaders(Headers);
	Try
		AnswerRow = "";
		CallResult = Await DriverObject.PostAsync(ConfiguringJSONConnection, JSONHeaders, Body, AnswerRow); // AddInAsyncCallResult
		OperationResult = OperationResult();
		OperationResult.ResponseCode = CallResult.Value;
		OperationResult.Response = CallResult.Parameters[3];
		SetHeaders(OperationResult.Headers, CallResult.Parameters[1]);
		If OperationResult.ResponseCode = -1 Then
			Await FillInErrorInformation(DriverObject, OperationResult);
		EndIf;
	Except           
		OperationResult = ErrorCallMethodComponents("Post");
	EndTry;
	
	Return OperationResult;
	
EndFunction

// Calling DeletePost.
// 
// Parameters:
//  URL - String
//  Headers - Map of KeyAndValue
// 
// Returns:
//  See OperationResult      
//
Async Function DeleteAsync(URL, Headers = Undefined) Export
	
	ConnectionResult = Await ConnectHTTPClientAsync();
	If Not ConnectionResult.Attached Then
		Return AddInAttachmentError(ConnectionResult.ErrorDescription);
	EndIf;
	
	DriverObject = ConnectionResult.Attachable_Module;
	ConfiguringJSONConnection = JSONConnectionSettings(URL);
	JSONHeaders = JSONHeaders(Headers);
	Try
		AnswerRow = "";
		CallResult = Await DriverObject.DeleteAsync(ConfiguringJSONConnection, JSONHeaders, AnswerRow); // AddInAsyncCallResult
		OperationResult = OperationResult();
		OperationResult.ResponseCode = CallResult.Value;
		OperationResult.Response = CallResult.Parameters[2];    
		SetHeaders(OperationResult.Headers, CallResult.Parameters[1]);
		If OperationResult.ResponseCode = -1 Then
			Await FillInErrorInformation(DriverObject, OperationResult);
		EndIf;
	Except           
		OperationResult = ErrorCallMethodComponents("Delete");
	EndTry;
	
	Return OperationResult;
	
EndFunction

#EndRegion

#Region Private

Function ComponentDetails()
	
	Parameters = New Structure;
	Parameters.Insert("ObjectName", "HttpBridge");
	Parameters.Insert("FullTemplateName", "CommonTemplate.HTTPBridgeAddIn");
	Return Parameters;               
	
EndFunction

// The Result Of The Operation
// 
// Returns:
//  Structure - Result of operation:
// * Result - Boolean - 
// * ErrorDescription - String - 
// * ResponseCode - String - 
// * Response - String -  
//
Function OperationResult()
	
	OperationResult = New Structure;
	OperationResult.Insert("Result", True);
	OperationResult.Insert("ErrorDescription", "");
	OperationResult.Insert("ResponseCode", "");  
	OperationResult.Insert("Headers", New Map);
	OperationResult.Insert("Response", "");
	Return OperationResult;
	
EndFunction

Procedure SetHeaders(Headers, JSONHeaders)
	
	If IsBlankString(JSONHeaders) Then
		Return;
	EndIf;    
	
	Length = StrLen(JSONHeaders);
	Values = Mid(JSONHeaders, 2, Length - 2);
	TitleArray = CommonCELClientServer.SplitStringIntoSubstringsArray(Values, """,""");
	For Each TitleText In TitleArray Do
		Position = StrFind(TitleText, ":");
		TitleName = Left(TitleText, Position - 1);
		HeaderValue = Mid(TitleText, Position + 1);
		Headers.Insert(
			StrReplace(TitleName, """", ""), 
			StrReplace(HeaderValue, """", ""));
	EndDo;
	
EndProcedure

Async Function FillInErrorInformation(DriverObject, OperationResult)
	
	CallResult = Await DriverObject.GetLastErrorAsync(""); // Structure
	OperationResult.Result = False;
	OperationResult.ErrorDescription = CallResult.Parameters[0];
	
EndFunction

Function ErrorCallMethodComponents(Method)
	
	ErrorDescription = NStr("vi = 'Lỗi gọi ra phương thức driver <%1>.:%2';
							|ru = 'Ошибка вызова метода драйвера <%1>.:%2';
							|en = 'Error calling the driver method <%1>.:%2'; fa = 'Error calling the driver method <%1>.:%2';
							|it = 'Ошибка вызова метода драйвера <%1>.:%2';
							|pl = 'Error calling the driver method <%1>.:%2';
							|tr = '<%1> sürücü yönteminin çağrısında hata oluştu: %2'");
	ErrorDescription = StrTemplate(
		ErrorDescription, 
		Method, 
		ErrorProcessing.ErrorMessageForUser(ErrorInfo()));
	
	OperationResult = OperationResult();
	OperationResult.Result = False;
	OperationResult.ErrorDescription = ErrorDescription;
	Return OperationResult;
	
EndFunction  

Function AddInAttachmentError(ErrorDescription)
	
	OperationResult = OperationResult();
	OperationResult.Result = False;
	OperationResult.ErrorDescription = ErrorDescription;
	Return OperationResult;
	
EndFunction  

Function JSONConnectionSettings(URL)
	
	ParsedURL = ParseURL(URL);
	
	ConnectionSetup = New Structure;
	ConnectionSetup.Insert("Host", ParsedURL.Host);
	ConnectionSetup.Insert("Url", URL);
	Return WriteJSONValue(ConnectionSetup);
	
EndFunction

Function JSONHeaders(Headers)
	
	Result = "";
	If ValueIsFilled(Headers) Then
		Result = "{";
		For Each KeyValue In Headers Do
			Result = Result + """"+KeyValue.Key+""":"""+String(KeyValue.Value)+""",";
		EndDo;
		If StrEndsWith(Result,",") Then
			Result = Left(Result, StrLen(Result)-1);
		EndIf;
		Result = Result + "}";
		Return Result;
	EndIf;
	Return "{}";
	
EndFunction

Function ParseURL(Val URL)
	
	Protocol = "";
	Position = StrFind(URL, "://");
	If Position > 0 Then
		Protocol = Left(URL, Position - 1);
		URL = Mid(URL, Position + 3);
	EndIf;
	
	Server = "";
	Position = StrFind(URL, "/");
	If Position > 0 Then
		Server = Left(URL, Position - 1);
		URL = Mid(URL, Position);
	Else
		Server = URL;
		URL = "";
	EndIf;
	
	ResourceAddress = URL;
	
	Result = New Structure;
	Result.Insert("Host", ?(ValueIsFilled(Protocol), Protocol + "://"+Server, Server));
	Result.Insert("Protocol", Protocol);
	Result.Insert("Server", Server);
	Result.Insert("ResourceAddress", ResourceAddress);
	
	Return Result;
	
EndFunction

#EndRegion
