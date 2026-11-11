#Region Public

// Data for managing the interaction system.
// 
// Returns: 
//  String
Function DataForInteractionSystemManagement() Export
	
	DataFromStorage = Common.ReadDataFromSecureStorage(
		"DataForInteractionSystemManagement", 
		"DataForInteractionSystemManagement");
	
	Return String(DataFromStorage);
	
EndFunction

// You can connect to the interaction system in the service model.
// 
// Returns:
//  Boolean - False
Function CanConnectToCollaborationSystemSaaS() Export
	
	Return False;
	
EndFunction

// Register the database via the service
// 
// Parameters: 
//  ManagementServicePublicationURL - String
//  ControlCode - String
//  BaseName - String
// 
// Returns: See RequestToService
Function RegisterDatabaseThroughService(ManagementServicePublicationURL, ControlCode, BaseName) Export
	
	QueryOptions = New Structure;
	QueryOptions.Insert("BaseName", BaseName);
	SetSafeModeDisabled(True);
	Return RequestToService(
		ManagementServicePublicationURL, 
		ControlCode, 
		NameOfDatabaseRegistrationMethod(), 
		QueryOptions);
	
EndFunction

// Integration with the interaction system in the service model is used.
// 
// Returns:
//  Boolean
Function IntegrationWithCollaborationSystemUsedSaaS() Export
	
	Return False;
	
EndFunction

// Object of the interaction system.
// 
// Returns: 
//  CollaborationSystemManager
Function ObjectOfInteractionSystem() Export
	
	Return CollaborationSystem;
	
EndFunction

// Get data about users of the service.
// 
// Parameters: 
//  ManagementServicePublicationURL - String
//  ControlCode - String
// 
// Returns: See RequestToService
//
Function GetDataAboutServiceUsers(ManagementServicePublicationURL, ControlCode) Export
	
	SetSafeModeDisabled(True);
	Return RequestToService(
		ManagementServicePublicationURL, 
		ControlCode, 
		MethodNameListOfUsers());
	
EndFunction

// Returns the decrypted data intended for managing the interaction system via the http service.
//
// Parameters:
//  DataToManage - String - encrypted data
// 
// Returns:
//  Structure - decryption result with fields:
//	* MessageText - String - message generated during decryption
//	* Deciphered - Boolean - indicates whether the decryption was successful
//	* Data - Structure - decrypted data:
//	  ** ManagementServicePublicationURL - String
//	  ** ControlCode - String
//
Function DecryptDataForManagement(DataToManage) Export
	
	Result = New Structure;
	Result.Insert("MessageText", "");
	Result.Insert("Deciphered", False);
	Result.Insert("Data", Undefined);
	
	Try
	
		BinaryData = base64UrlDecode(DataToManage);
		
		DataReader = New DataReader(BinaryData);
		ReadingResult = "";
		While Not DataReader.ReadCompleted Do
			ReadLine_ = DataReader.ReadLine();
			ReadingResult = ReadingResult + ReadLine_ + Chars.LF;
		EndDo;
		DataReader.Close();
		
		StructureOfData = StructureFromJSONString(ReadingResult);
		
		Result.Data = StructureOfData;
		Result.Deciphered = True;
	
	Except
		
		ErrorInfo = ErrorInfo();
		Result.MessageText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		Return Result;
		
	EndTry;
	
	Return Result;
	
EndFunction

// The collection of application IDs type.
// 
// Returns:
//  Type - Type
Function TypeCollectionOfApplicationIds() Export
	
	Return Type("CollaborationSystemApplicationIDCollection");
	
EndFunction

// Type of information security registration parameters.
// 
// Returns:
//  Type - Type
Function TypeInformationSecurityRegistrationParameters() Export
	
	Return Type("CollaborationSystemInfoBaseRegistrationParameters");
	
EndFunction

// The app sharing type.
// 
// Returns:
//  Type - Type
Function TypeAppSharing() Export
	
	Return Type("CollaborationSystemApplicationLinks");
	
EndFunction

#EndRegion

#Region Private

// Returns the result of a request to the http service for managing the interaction system
//
// Parameters:
//  ManagementServicePublicationURL - String
//  ControlCode					 - String
//  MethodName						 - String
//  QueryOptions				 - Structure
// 
// Returns:
//  Structure - result of a request to the service with fields:
//		* Success - Boolean
//		* MessageText - String
//		* ResultData - Structure
//
// @unavailable-in-safemode
Function RequestToService(ManagementServicePublicationURL, ControlCode, MethodName, QueryOptions = Undefined)
	
	Result = New Structure;
	Result.Insert("Success", False);
	Result.Insert("MessageText", "");
	Result.Insert("ResultData", Undefined);
	
	Try
		
		URIStructure = CommonClientServer.URIStructure(ManagementServicePublicationURL);
		Host = URIStructure.Host;
		PathAtServer = URIStructure.PathAtServer;
		Port = URIStructure.Port;
		SecureConnection = 
			CommonClientServer.NewSecureConnection(, New OSCertificationAuthorityCertificates);
		
		Join = New HTTPConnection(
			Host,
			Port,
			,
			,
			GetFilesFromInternet.GetProxy(URIStructure.Schema),
			,
			SecureConnection);
		
		QueryData = New Structure;
		QueryData.Insert("control_code", ControlCode);
		QueryData.Insert("method", MethodName);
		
		JSONWriter = New JSONWriter;
		JSONWriter.SetString();
		WriteJSON(JSONWriter, QueryData);
		
		QueryString = JSONWriter.Close();
		
		Headers = New Map;
		Headers.Insert("Content-Type", "application/x-www-form-urlencoded");
		
		Query = New HTTPRequest(PathAtServer, Headers);
		Query.SetBodyFromString(QueryString);
		
		Response = Join.Post(Query);
		
		If Response.StatusCode <> 200 Then
			ErrorText = StrTemplate(NStr("vi = 'Lỗi %1';
										|ru = 'Ошибка %1';
										|en = 'Error %1'; fa = 'Error %1';
										|it = 'Errore %1';
										|pl = 'Błąd %1';
										|tr = '%1 hatası'", Common.DefaultLanguageCode()), String(Response.StatusCode));
			Raise ErrorText;
		EndIf;
		
		JSONReader = New JSONReader;
		
		ResponseBodyString = Response.GetBodyAsString();
		JSONReader.SetString(ResponseBodyString);
		
		Try
			ResponseData = ReadJSON(JSONReader, False);	
		Except
			Raise ResponseBodyString;
		EndTry;
		
		If ResponseData.error Then
			Result.MessageText = ResponseData.message;
			Return Result;
		EndIf;
		
		If MethodName = NameOfDatabaseRegistrationMethod() Then
			
			BaseName = QueryOptions.BaseName;
			RegistrationParameters = New(TypeInformationSecurityRegistrationParameters()); // CollaborationSystemInfoBaseRegistrationParameters
			RegistrationParameters.ServerAddress = ResponseData.ServerAddress;
			RegistrationParameters.Email = ResponseData.SubscriberID;
			RegistrationParameters.InfoBaseName = BaseName;
			RegistrationParameters.ActivationCode = ResponseData.ActivationCode;
			
			RegistrationResult = 
				IntegrationWithCollaborationSystem.ObjectOfInteractionSystem().RegisterInfoBase(
					RegistrationParameters);
			
			If RegistrationResult.RegistrationCompleted Then
				Result.Success = True;
				Result.ResultData = New Structure;
				Result.ResultData.Insert("UserData_", ResponseData.Users);
			Else
				Result.MessageText = RegistrationResult.MessageText;
			EndIf;
			
		ElsIf MethodName = MethodNameListOfUsers() Then
			
			Result.Success = True;
			Result.ResultData = New Structure;
			Result.ResultData.Insert("UserData_", ResponseData.Users);
			
		EndIf;
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		WriteLogEvent(
			StrTemplate("%1.%2", EventLogEventName(), NStr("vi = 'Đăng ký cơ sở thông qua dịch vụ';
															|ru = 'Регистрация базы через сервис';
															|en = 'Base registration via the service'; fa = 'Base registration via the service';
															|it = 'Registrazione del database tramite il servizio';
															|pl = 'Rejestracja bazy przez serwis';
															|tr = 'Servis üzerinden taban kaydı'", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			CloudTechnology.DetailedErrorText(ErrorInfo));
		
		Result.MessageText = CloudTechnology.ShortErrorText(ErrorInfo);
		
	EndTry;
	
	Return Result;
	
EndFunction

Function base64UrlDecode(Val String)
	
	While StrLen(String) % 4 <> 0 Do
		String = String + "=";
	EndDo;
	
	String = StrReplace(String, "-", "+");
	String = StrReplace(String, "_", "/");
	
	Return Base64Value(String);
	
EndFunction

Function NameOfDatabaseRegistrationMethod()
	
	Return "register";
	
EndFunction

Function MethodNameListOfUsers()
	
	Return "users_list";
	
EndFunction

Function EventLogEventName()
	
	Return NStr("vi = 'Hệ thống giao tiếp';
				|ru = 'Система взаимодействия';
				|en = 'Collaboration system'; fa = 'سیستم همکاری';
				|it = 'Sistema di interazione';
				|pl = 'System interakcji';
				|tr = 'Etkileşim sistemi'", Common.DefaultLanguageCode());
	
EndFunction

Function StructureFromJSONString(String, DateTypeProperties = Undefined)
    
	JSONReader = New JSONReader;
    JSONReader.SetString(String);
    Response = ReadJSON(JSONReader,, DateTypeProperties, JSONDateFormat.ISO); 
    Return Response
    
EndFunction

#EndRegion