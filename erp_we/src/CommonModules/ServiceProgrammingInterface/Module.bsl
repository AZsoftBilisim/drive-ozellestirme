////////////////////////////////////////////////////////////////////////////////
// The software interface of the service: performing regular MS functions with application code
// via an external API 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns properties of the version of the service Manager's software interface.
// 
// Returns:
//  Structure - properties of the version of the external software interface:
//   * Version - Number - version number of the external software interface.
//   * ServiceManagerVersion - String - version number of the service Manager.
//   * TimeZoneOfServiceManager - String - time zone of the service Manager.
//   * ServiceManagerExternalURL - String
//
Function InterfaceVersionProperties() Export

	Return ServiceProgrammingInterfaceCached.InterfaceVersionProperties();

EndFunction

// Returns a valid user access token.
// 
// Parameters:
//  User - CatalogRef.Users - if not specified, the Cur user is used.
//  RaiseExceptionAtError - Boolean - default = True
//  ResponseProperties - Structure - returned parameter:
//   * Error - Boolean - error receiving the token
//   * Message - String - error message.
//   * LifeTime - Date - Token expiration date.
// 
// Returns:
//  String - access token.
//  
Function ValidAccessToken(User = Undefined, RaiseExceptionAtError = True, ResponseProperties = Undefined) Export
	
	ResponseProperties = New Structure;
	ResponseProperties.Insert("Error", False);
	ResponseProperties.Insert("Message", "");
	ResponseProperties.Insert("LifeTime", '00010101');
	
	If User = Undefined Then
		User =  Users.CurrentUser();
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	AccessTokenData = Common.ReadDataFromSecureStorage(User, "AccessTokenData");
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	If Not AccessTokenData = Undefined And AccessTokenData.LifeTime > CurrentSessionDate() Then
		ResponseProperties.LifeTime = AccessTokenData.LifeTime;
		Return AccessTokenData.AccessToken;
	EndIf;
	
	AccessTokenData = NewAccessToken(User, RaiseExceptionAtError);
	
	If Not AccessTokenData.Error Then
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(User, AccessTokenData, "AccessTokenData");
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
	EndIf;
	
	ResponseProperties.Error = AccessTokenData.Error;
	ResponseProperties.Message = AccessTokenData.Message;
	ResponseProperties.LifeTime = AccessTokenData.LifeTime;
	
	Return AccessTokenData.AccessToken;
	
EndFunction

// Gets a new user access token.
// 
// Parameters:
//  User - CatalogRef.Users - if not specified, the Cur user is used.
//  RaiseExceptionAtError - Boolean
// 
// Returns:
//  Structure - data of the new access token:
//   * AccessToken - String - if the token was received successfully
//                  - Undefined - if an error occurred when receiving the token
//   * LifeTime - Date - Lifetime Of The Access Token
//   * Error - Boolean - error receiving the token
//   * Message - String - Error message 
Function NewAccessToken(User = Undefined, RaiseExceptionAtError = True) Export
	
	Result = New Structure;
	Result.Insert("AccessToken", Undefined);
	Result.Insert("LifeTime", '00010101');
	Result.Insert("Error", False);
	Result.Insert("Message", "");
	
	If User = Undefined Then
		User =  Users.CurrentUser();
	EndIf;
	
	ResultingProperties = New Array;
	ResultingProperties.Add("IBUserID");
	ResultingProperties.Add("ServiceUserID");
	UserProperties = Common.ObjectAttributesValues(User, ResultingProperties);
	
	ProviderURL = SaaSOperations.AuthenticationProviderURL();
	If Not ValueIsFilled(ProviderURL) Then
		Message = NStr("vi = 'Chưa chỉ ra địa chỉ của nhà cung cấp đăng nhập.';
						|ru = 'Не указан адрес провайдера аутентификации.';
						|en = 'Authentication provider address required.'; fa = 'Authentication provider address required.';
						|it = 'Не указан адрес провайдера аутентификации.';
						|pl = 'Authentication provider address required.';
						|tr = 'Kimlik doğrulama sağlayıcısının adresi belirtilmedi.'");
		If RaiseExceptionAtError Then
			Raise Message;
		Else
			Result.Error = True;
			Result.Message = Message;
			Return Result;
		EndIf;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	// The user must be read from the database, because when changing the password, the current user() contains the old password
	CurrentUser = InfoBaseUsers.FindByUUID(
		UserProperties.IBUserID);

	If CurrentUser = Undefined Then
		// A request is made from the information database administrator after entering the data area.
		Raise ServiceProgrammingInterfaceInternal.ExecutingRequestFromAdministratorExceptionText();
	EndIf;
	
	PasswrdHash = StrSplit(CurrentUser.StoredPasswordValue, ",")[0];
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	ServerData = CommonClientServer.URIStructure(ProviderURL);
	
	SSLScheme = "https";
	If Lower(ServerData.Schema) = SSLScheme Then
		SecureConnection =  CommonClientServer.NewSecureConnection();
	Else
		SecureConnection = Undefined;
	EndIf;
	
	Data = New Structure;
	Data.Insert("grant_type", "client_credentials");
	Data.Insert("client_id", String(UserProperties.ServiceUserID));
	Data.Insert("client_secret", PasswrdHash);
	
	SetSafeModeDisabled(True);
	HTTPConnection = New HTTPConnection(ServerData.Host, ServerData.Port, , ,
		GetFilesFromInternet.GetProxy(ServerData.Schema), 5, SecureConnection);
	SetSafeModeDisabled(False);
	
	MomentOfReceipt = CurrentSessionDate();
	HTTPRequest = New HTTPRequest(StrTemplate("%1/token", ServerData.PathAtServer));
	HTTPRequest.Headers.Insert("Content-Type", "application/json; charset=utf-8");
	HTTPRequest.SetBodyFromString(SaaSOperationsCTL.StringFromJSONStructure(Data));
	
	Try
		HTTPResponse = HTTPConnection.CallHTTPMethod("POST", HTTPRequest);
	Except
		If RaiseExceptionAtError Then
			Raise
		Else
			Result.Error = True;
			Result.Message = CloudTechnology.DetailedErrorText(ErrorInfo());
			Return Result;
		EndIf;
	EndTry;
	
	If Not HTTPResponse.StatusCode = 200 Then
		ResponseBody = HTTPResponse.GetBodyAsString();
		Message = StrTemplate("%1 %2", HTTPResponse.StatusCode, ResponseBody);
		If RaiseExceptionAtError Then
			Raise Message;
		Else
			Result.Error = True;
			Result.Message = Message;
			Return Result;
		EndIf;
	EndIf;
	
	MIMEType = CommonCTLClientServer.HTTPHeader(HTTPResponse, "Content-Type");
	If StrFind(MIMEType, "application/json") = 0 Then
		Message = NStr("vi = 'Sử dụng nhà cung cấp OpenID của nền tảng 1C:Enterprise
		|Để nhận mã thông báo truy cập, bạn cần sử dụng nhà cung cấp OpenID của Service Manager (xem https://its.1c.ru/db/freshpub#content:130:hdoc).';
		|ru = 'Используется OpenID-провайдер платформы 1С:Предприятие
		|Для получения токенов доступа нужно использовать OpenID-провайдер Менеджера сервиса (см. https://its.1c.ru/db/freshpub#content:130:hdoc).';
		|en = 'The OpenID provider of the 1C:Enterprise platform is used
		|To get access tokens, use the service manager OpenID provider (see https://its.1c.ru/db/freshpub#content:130:hdoc).'; fa = 'The OpenID provider of the 1C:Enterprise platform is used
		|To get access tokens, use the service manager OpenID provider (see https://its.1c.ru/db/freshpub#content:130:hdoc).';
		|it = 'The OpenID provider of the 1C:Enterprise platform is used
		|To get access tokens, use the service manager OpenID provider (see https://its.1c.ru/db/freshpub#content:130:hdoc).';
		|pl = 'The OpenID provider of the 1C:Enterprise platform is used
		|To get access tokens, use the service manager OpenID provider (see https://its.1c.ru/db/freshpub#content:130:hdoc).';
		|tr = '1C:Enterprise platformunun OpenID sağlayıcısı kullanılmaktadır
		|Erişim belirteçlerini almak için Servis Yöneticisi''nin OpenID sağlayıcısını kullanmanız gerekmektedir (bkz. https://its.1c.ru/db/freshpub#content:130:hdoc).'");
		If RaiseExceptionAtError Then
			Raise Message;
		Else
			Result.Error = True;
			Result.Message = Message;
			Return Result;
		EndIf;
	EndIf;
	
	DataStream = HTTPResponse.GetBodyAsStream();
	Data = SaaSOperationsCTL.StructureFromJSONStream(DataStream);
	
	Result.AccessToken = Data.access_token;
	Result.LifeTime = MomentOfReceipt + Data.expires_in;
	
	Return Result;
	
EndFunction

#Region Account

// Returns a list of subscribers for the current user.
// 
// Returns:
//  ValueTable - list of subscribers:
//    * Description - String - the name of the caller
//    * Code - Number - subscriber code
//    * UserRole - EnumRef.SubscriberUsersRoles - the role of the current user of the subscriber.
//
Function Subscribers_() Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/list";
	QueryData = IsInternal.QueryTemplate(Method);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingSubscriber();
	Renamings.Insert("role", IsInternal.ColumnDetails("UserRole", 
		New TypeDescription("EnumRef.SubscriberUsersRoles")));

	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.account, Renamings);

EndFunction

// Returns additional information (details and properties) for the subscriber of this application.
// Implements the external programming interface method-account/attached_info.
// 
// Parameters:
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Structure - additional Attributes and subscriber properties:
//   * PublicId - String - public subscriber ID
//   * Attributes - ValueTable - additional Attributes of the subscriber:
//     ** Key - String - name of additional account details
//     ** Type - String - Value type 
//     ** Value - String, Number, Date, Boolean - Value of additional details
//   * Properties - ValueTable - additional subscriber properties:
//     ** Key - String - name of the additional property
//     ** Type - String - Value type
//     ** Value - String, Number, Date, Boolean - value of the additional property
//
Function AdditionalSubscriberInformation(RaiseExceptionAtError = True, 
	BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/attached_info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriberCode());
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, 
		RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
		
	ResponseData.Delete("general");
	
	Renamings = New Map;
	Renamings.Insert("public_id", IsInternal.ColumnDetails(
		"PublicId", Common.StringTypeDetails(36)));
	Renamings.Insert("properties", "Properties");
	Renamings.Insert("fields", "Attributes");
	Result = IsInternal.RenameProperties(ResponseData, Renamings);
	
	Result.Properties = IsInternal.StructuresArrayIntoValueTable(
		Result.Properties, IsInternal.RenamingAdditionalInformation());
	Result.Attributes = IsInternal.StructuresArrayIntoValueTable(
		Result.Attributes, IsInternal.RenamingAdditionalInformation());
	
	Return Result;
	
EndFunction

// Updates additional information (details and properties) of the subscriber.
// Implements the method of the external programming interface - account/update_attached_info.
//
// Parameters:
//  AddProperties - See NewAdditionalSubscriberInformation
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//  
// Returns:
//  Boolean - setting additional information: True - installed, False - an error occurred.
//
Function UpdateAdditionalSubscriberInformation(AddProperties, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/update_attached_info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", AddProperties.SubscriberCode);

	If AddProperties.Property("PublicId") Then
		QueryData.Insert("public_id", AddProperties.PublicId);
	EndIf;
	Renamings = IsInternal.RenamingAdditionalInformation(False);
	If AddProperties.Property("Attributes") Then
		QueryData.Insert("fields", IsInternal.TableOfValuesInArrayOfStructures(
			AddProperties.Attributes, Renamings));
	EndIf;
	If AddProperties.Property("Properties") Then
		QueryData.Insert("properties", IsInternal.TableOfValuesInArrayOfStructures(
			AddProperties.Properties, Renamings));
	EndIf;

	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns additional information (details and properties) of the specified subscriber
// required for a paid subscription.
// Implements the method of the external programming interface - account/attached_info_for_subscribing
//
// Parameters:
//  SubscriberCode - Number - the code of the subscriber for whom you need to get additional information.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Structure - additional Attributes and subscriber properties:
//   * HasErrors - Boolean - indicates whether there are filling errors.
//   * Attributes - ValueTable - additional Attributes of the subscriber:
//     ** Key - String - name of additional account details
//     ** Title - String - the header of the additional props
//     ** Type - String - Value type 
//     ** Value - String, Number, Date, Boolean - Value of additional details
//     ** RequiredToFill - Boolean - required field sign
//     ** ToolTip - String - filling hint
//     ** Error - Boolean - indication of a filling error
//     ** Message - String - error message.
//   * Properties - ValueTable - additional subscriber properties:
//     ** Key - String - name of the additional property
//     ** Title - String - the header of the additional props
//     ** Type - String - Value type
//     ** Value - String, Number, Date, Boolean - value of the additional property
//     ** RequiredToFill - Boolean - the attribute indicates that the field must be filled in
//     ** ToolTip - String - filling hint
//     ** Error - Boolean - indication of a filling error
//     ** Message - String - error message.
//
Function RequiredInformationForSubscribing(SubscriberCode, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/attached_info_for_subscribing";

	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriberCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingAdditionalInformation();
	Renamings.Insert("required", IsInternal.ColumnDetails(
		"RequiredToFill", New TypeDescription("Boolean")));
	Renamings.Insert("tooltip", IsInternal.ColumnDetails(
		"ToolTip", New TypeDescription("String")));
	Renamings.Insert("error", IsInternal.ColumnDetails(
		"Error", New TypeDescription("Boolean")));
	Renamings.Insert("message", IsInternal.ColumnDetails(
		"Message", New TypeDescription("String")));
		
	If ResponseData <> Undefined Then
		Properties = IsInternal.StructuresArrayIntoValueTable(ResponseData.properties, Renamings);
		Attributes = IsInternal.StructuresArrayIntoValueTable(ResponseData.fields, Renamings);
	Else
		Properties = IsInternal.NewAdditionalInformation();
		Attributes = IsInternal.NewAdditionalInformation();
	EndIf;

	Return New Structure("HasErrors, Properties, Attributes", ResponseData.errors, Properties, Attributes);

EndFunction

// Returns values of additional information.
// 
// Parameters:
//  NameOfProperty - String - the name of the information to get values for.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  ValueTable - Additional Information Values:
//   * Description - String - Length100
//   * Weight - Number - accuracy 10.2  
Function AdditionalInformationValues(NameOfProperty, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "attached_info_values";

	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("key", NameOfProperty);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method, , False);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	Renamings = New Map;
	Renamings.Insert("name", IsInternal.ColumnDetails(
		"Description", Common.StringTypeDetails(100)));
	Renamings.Insert("weight", IsInternal.ColumnDetails(
		"Weight", Common.TypeDescriptionNumber(10, 2)));
	
	If ResponseData <> Undefined Then
		Values = IsInternal.StructuresArrayIntoValueTable(ResponseData.values, Renamings);
	Else 
		Values = New ValueTable;
	EndIf;
	
	Return Values;

EndFunction

#EndRegion

#Region Account_Users

// Returns the list of users of the subscriber of this application.
// Implements the method of the external programming interface - account/users/list.
// 
// Parameters:
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//  
//  Returns:
//  ValueTable - Subscriber Users:
//   * Login - String - username (name) of the user
//   * FullName - String - full account name
//   * Mail - String - user's email address
//   * UserRole - EnumRef.SubscriberUsersRoles - user role
//   * AllowedNumberOfSessions - Number - allowed number of sessions
//   * TemporaryAccess - Boolean - temporary access
//
Function SubscriberUsers(RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriberCode());
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	
	Renamings = IsInternal.RenamingSubscriberUsers();
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.user, Renamings);
	
EndFunction

// Returns the properties of the subscriber's user by login.
// Implements the method of the external programming interface - account/users/info.
// Parameters:
//  Login - String - username (name) of the user.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Structure - Subscriber User Properties:
//   * Login - String - username (name) of the user
//   * FullName - String - full account name
//   * Mail - String - user's email address
//   * Phone - String - user phone
//   * UserRole - EnumRef.SubscriberUsersRoles - user role
//   * AllowedNumberOfSessions - Number - allowed number of sessions
//   * TemporaryAccess - Boolean - temporary access
//   * AdditionalAttributes - ValueTable - additional Attributes of the subscriber's user:
//     ** Key - String - name of additional account details
//     ** Title - String - the header of the additional props
//     ** Type - String - Value type 
//     ** Value - String, Number, Date, Boolean - Value of additional details
Function SubscriberUserProperties(Login,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriberCode());
	QueryData.Insert("login", Login);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingSubscriberUsers();
	
	Result = IsInternal.RenameProperties(ResponseData.user, Renamings);
	If Result.Property("fields") Then
		Renamings = IsInternal.RenamingAdditionalInformation();
		AdditionalAttributes = IsInternal.StructuresArrayIntoValueTable(Result.fields, Renamings);
		IsInternal.ProcessDateInAdditionalAttributes(AdditionalAttributes);
		Result.Delete("fields");
		Result.Insert("AdditionalAttributes", AdditionalAttributes);
	Else
		Result.Insert("AdditionalAttributes", IsInternal.NewAdditionalInformation());
	EndIf;
	
	Return Result;

EndFunction

// Creates a new service user account and connects the created user to the subscriber of this application. 
//
// Parameters:
//  CreationParameters - See NewUserCreationOptions
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - If the user has been added, True means the user has been added, False means an error has occurred.
//
Function CreateSubscriberUser(CreationParameters,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/create";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriberCode());
	QueryData.Insert("role", Enums.SubscriberUsersRoles.NameByValue(CreationParameters.UserRole));
	QueryData.Insert("login", CreationParameters.Login);
	QueryData.Insert("password", CreationParameters.Password);
	QueryData.Insert("email", CreationParameters.Mail);
	QueryData.Insert("email_required", CreationParameters.MailRequired_);
	QueryData.Insert("name", CreationParameters.FullName);
	QueryData.Insert("phone", CreationParameters.Phone);
	QueryData.Insert("timezone", CreationParameters.TimeZone);
	QueryData.Insert("description", CreationParameters.LongDesc);
	QueryData.Insert("invite", CreationParameters.InviteOnly);
	If CreationParameters.Property("AdditionalAttributes") 
	   And CreationParameters.AdditionalAttributes.Count() > 0 Then
		AdditionalAttributes = New Array; // Array of Structure
		For Each String In CreationParameters.AdditionalAttributes Do
			TypeValueName = New Structure;
			TypeValueName.Insert("key", String.Key);
			If ValueIsFilled(String.Type) Then
				TypeValueName.Insert("type", String.Type);
			EndIf;
			TypeValueName.Insert("value", String.Value);
			AdditionalAttributes.Add(TypeValueName);
		EndDo;
		QueryData.Insert("fields", AdditionalAttributes);
	EndIf;
		
	If CreationParameters.SetAppPermissions Then
		
		AppPermissions = New Array;
		For Each String In CreationParameters.AppPermissions Do
			
			AppPermission = New Structure;
			AppPermission.Insert("id", String.ApplicationCode);
			AppPermission.Insert("role", Enums.ApplicationUserRights.NameByValue(String.Right));
			
			AppPermissions.Add(AppPermission);
			
		EndDo;
		
		QueryData.Insert("tenants", AppPermissions);
		
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Adds an existing service user to the subscriber of this application. 
//
// Parameters:
//  AddingOptions - See NewParametersForAddingUser
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - the sign of account creation is True - created, False - an error occurred.
//
Function AddSubscriberUser(AddingOptions,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/add";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriberCode());
	QueryData.Insert("role", Enums.SubscriberUsersRoles.NameByValue(AddingOptions.UserRole));
	QueryData.Insert("login", AddingOptions.Login);
	QueryData.Insert("description", AddingOptions.LongDesc);
	QueryData.Insert("force", AddingOptions.Forcibly);
	If AddingOptions.Property("AdditionalAttributes") 
	   And AddingOptions.AdditionalAttributes.Count() > 0 Then
		AdditionalAttributes = New Array; // Array of Structure
		For Each String In AddingOptions.AdditionalAttributes Do
			TypeValueName = New Structure;
			TypeValueName.Insert("key", String.Key);
			If ValueIsFilled(String.Type) Then
				TypeValueName.Insert("type", String.Type);
			EndIf;
			TypeValueName.Insert("value", String.Value);
			AdditionalAttributes.Add(TypeValueName);
		EndDo;
		QueryData.Insert("fields", AdditionalAttributes);
	EndIf;
		
	If AddingOptions.SetAppPermissions Then
		
		AppPermissions = New Array;
		For Each String In AddingOptions.AppPermissions Do
			
			AppPermission = New Structure;
			AppPermission.Insert("id", String.ApplicationCode);
			AppPermission.Insert("role", Enums.ApplicationUserRights.NameByValue(String.Right));
			
			AppPermissions.Add(AppPermission);
			
		EndDo;
		
		QueryData.Insert("tenants", AppPermissions);
		
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Updates the subscriber's user properties.
// Implements the method of the external programming interface - account/users/update.
//
// Parameters:
//  Parameters - See NewSubscriberUserUpdateParameters
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - the sign of account creation is True - created, False - an error occurred.
Function UpdateSubscriberUser(Parameters,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/update";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("login", Parameters.Login);
	
	If Parameters.UpdateAllowedSessionsNumber Then
		QueryData.Insert("session_restriction", Parameters.AllowedNumberOfSessions);
	EndIf;
	
	If ValueIsFilled(Parameters.Role) Then
		QueryData.Insert("role", Enums.SubscriberUsersRoles.NameByValue(Parameters.Role));
	EndIf;
	
	If ValueIsFilled(Parameters.Applications) Then
		UserApps = New Array;
		For Each String In Parameters.Applications Do
			
			UserApp = New Structure;
			UserApp.Insert("id", String.ApplicationCode);
			UserApp.Insert("role", Enums.ApplicationUserRights.NameByValue(String.Right));
			
			UserApps.Add(UserApp);
			
		EndDo;
		
		QueryData.Insert("tenants", UserApps);
		
	EndIf;
	
	If ValueIsFilled(Parameters.AdditionalAttributes) Then
		
		AdditionalAttributes = New Array; // Array of Structure
		For Each String In Parameters.AdditionalAttributes Do
			AdditionalAttribute = New Structure;
			AdditionalAttribute.Insert("key", String.Key);
			If ValueIsFilled(String.Type) Then
				AdditionalAttribute.Insert("type", String.Type);
			EndIf;
			AdditionalAttribute.Insert("value", String.Value);
			AdditionalAttributes.Add(AdditionalAttribute);
		EndDo;
		
		QueryData.Insert("fields", AdditionalAttributes);
		
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Cancels the service user with the specified login access to the subscriber of this application.
//
// Parameters:
//  DeletionParameters - See NewUserDeletionParameters
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - the result of the cancellation of the access right to the subscriber: True - the right has been canceled, False - an error has occurred.
//
Function DeleteSubscriberUser(DeletionParameters,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/delete";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriberCode());
	QueryData.Insert("login", DeletionParameters.Login);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Sets the specified user of the subscriber of this application the specified role.
// Implements the method of the external programming interface - account/users/set_role.
// 
// Parameters:
//  Login - String - username (name) of the user. 
//  Role - EnumRef.SubscriberUsersRoles - the user role to install.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - role settings True - installed, False - an error occurred.
//
Function SetSubscriberUserRole(Login, Role,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
		
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/set_role";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriberCode());
	QueryData.Insert("login", Login);
	QueryData.Insert("role", Enums.SubscriberUsersRoles.NameByValue(Role));
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
			
EndFunction

// Sets the specified user of the subscriber of this application a limit on the number
// of simultaneous sessions of working with applications.
// Implements the method of the external programming interface - account/users/set_session_restriction.
// 
// Parameters:
//  RestrictionSettingParameters - See NewSessionLimitsParameters 
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - the result of setting the restriction: True - set, False - an error occurred.
//
Function SetLimitOfSubscriberUserSessionsNumber(RestrictionSettingParameters,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
		
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/set_session_restriction";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriberCode());
	QueryData.Insert("login", RestrictionSettingParameters.Login);
	QueryData.Insert("restriction", RestrictionSettingParameters.AllowedNumberOfSessions);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Updates additional details of the subscriber's user
// Implements the method of the external programming interface - account/users/update_attached_info.
// 
// Parameters:
//  Login - String - username (name) of the user. 
//  AddAttributes - ValueTable - additional Attributes of the subscriber's user:
//     * Key - String - name of additional account details
//     * Type - String - Value type 
//     * Value - String, Number, Date, Boolean - Value of additional details
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - installation of additional details: True - installed, False - an error occurred.
Function UpdateAdditionalDetailsOfSubscriberSUser(Login, AddAttributes,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/update_attached_info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriberCode());
	QueryData.Insert("login", Login);
	QueryData.Insert("fields", New Array);
	
	For Each String In AddAttributes Do
		Data = New Structure;
		Data.Insert("key", String.Key);
		Data.Insert("value", String.Value);
		If ValueIsFilled(String.Type) Then
			Data.Insert("type", String.Type);
		EndIf;
		QueryData.fields.Add(Data);
	EndDo;

	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;

EndFunction

// Returns a list of applications that the subscriber's user is allowed to access
//
// Parameters:
//  Parameters - See NewParametersForRequestingSubscriberUserApp.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// 
// Returns:
//  ValueTable - users who are allowed access:
//   * Code - Number - application code (number)
//   * Right - EnumRef.ApplicationUserRights - the user's right to the app in the service manager.
//   * SetupInAppRequired - Boolean - indicates that you need to configure user rights in the application.
//
Function SubscriberUserApps(Parameters,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/tenant/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("login", Parameters.Login);
	
	AddSubscriberAuthorization(QueryData, Parameters.SubscriberCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;

	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails("Code",
		Common.TypeDescriptionNumber(7, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("role", IsInternal.ColumnDetails("Right", 
		New TypeDescription("EnumRef.ApplicationUserRights")));
	Renamings.Insert("setup_required", IsInternal.ColumnDetails("SetupInAppRequired",
		New TypeDescription("Boolean")));
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.tenants, Renamings);
	
EndFunction

// Returns a template for user creation parameters for the Programinterface service method.Create a user of the subscriber.
// 
// Returns:
//  Structure - template for user creation parameters:
//	 * Login - String - login (user name)
//	 * Password - String - user password
//   * MailRequired_ - Boolean - mandatory mail installation flag (default = True)
//   * Mail - String - Email
//   * UserRole - EnumRef.SubscriberUsersRoles - role (default = user of the component)
//   * FullName - String - full name of the user
//   * Phone - String - user phone
//   * TimeZone - String - user's working time zone
//   * LongDesc - String - User description
//   * InviteOnly - Boolean - if True, then the user will be invited to join the subscriber
//   * AdditionalAttributes - ValueTable - additional Attributes of the subscriber's user:
//     ** Key - String - The name of the props
//     ** Type - String - the type of the prop. 
//              Simple: string, decimal, date, boolean
//              Reference: user, subscriber, tariff, service_provider_tariff, tariff_period, 
//                         subscription, service, additional_value, additional_value_group.
//     ** Value - String, Number, Date, Boolean - the value of the props.
//   * SetAppPermissions - Boolean - the need to set rights to applications.
//   * AppPermissions - ValueTable - installable rights to applications:
//     ** ApplicationCode - Number - application code (area number)
//     ** Right - EnumRef.ApplicationUserRights - the user role to install.
//
Function NewUserCreationOptions() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	
	Parameters = New Structure;
	Parameters.Insert("Login", "");
	Parameters.Insert("Password", "");
	Parameters.Insert("MailRequired_", True);
	Parameters.Insert("Mail", "");
	Parameters.Insert("UserRole", Enums.SubscriberUsersRoles.SubscriberUser);
	Parameters.Insert("FullName", "");
	Parameters.Insert("Phone", "");
	Parameters.Insert("TimeZone", "");
	Parameters.Insert("LongDesc", "");
	Parameters.Insert("InviteOnly", False);
	
	Parameters.Insert("AdditionalAttributes", IsInternal.NewAdditionalInformation());
	
	Parameters.Insert("SetAppPermissions", False);
	AppPermissions = New ValueTable;
	AppPermissions.Columns.Add("ApplicationCode", Common.TypeDescriptionNumber(10));
	AppPermissions.Columns.Add("Right", New TypeDescription("EnumRef.ApplicationUserRights"));
	Parameters.Insert("AppPermissions", AppPermissions);
	
	Return Parameters;
	
EndFunction

// Returns a template for user update parameters for the Software Interface Service method.Update the user of the component.
// 
// Returns:
//  Structure - template for user update parameters:
//	 * Login - String - login (user name)
//	 * UpdateAllowedSessionsNumber - Boolean - indicates whether the allowed number of sessions has been updated
//	 * AllowedNumberOfSessions - Number - allowed number of sessions
//	 * Role - EnumRef.SubscriberUsersRoles - user role
//	 * Applications - ValueTable - apps being added:
//	   ** ApplicationCode - Number - application code (area number)
//	   ** Right - EnumRef.ApplicationUserRights - the user's right to the current application
//	 * AdditionalAttributes - ValueTable - additional Attributes of the subscriber's user:
//	   ** Key - String - name of additional account details
//	   ** Type - String - Value type 
//	   ** Value - String, Number, Date, Boolean - Value of additional details
Function NewSubscriberUserUpdateParameters() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	
	Parameters = New Structure;
	Parameters.Insert("Login", "");
	Parameters.Insert("UpdateAllowedSessionsNumber", False);
	Parameters.Insert("AllowedNumberOfSessions", 0);
	Parameters.Insert("Role", Enums.SubscriberUsersRoles.EmptyRef());
	
	UserApps = New ValueTable;
	UserApps.Columns.Add("ApplicationCode", Common.TypeDescriptionNumber(10));
	UserApps.Columns.Add("Right", New TypeDescription("EnumRef.ApplicationUserRights"));
	Parameters.Insert("Applications", UserApps);
	
	Parameters.Insert("AdditionalAttributes", IsInternal.NewAdditionalInformation());
	
	Return Parameters;
	
EndFunction

// Returns a template for parameters for adding an existing user for the Software Interface Service method.Create a user of the component.
// 
// Returns:
//  Structure - template for user creation parameters:
//	 * Login - String - login (user name)
//   * UserRole - EnumRef.SubscriberUsersRoles - role (default = user of the component)
//   * LongDesc - String - User description
//   * Forcibly - Boolean - execute even if there are warnings
//   * AdditionalAttributes - ValueTable - additional Attributes of the subscriber's user:
//     ** Key - String - The name of the props
//     ** Type - String - the type of the prop. 
//              Simple: string, decimal, date, boolean
//              Reference: user, subscriber, tariff, service_provider_tariff, tariff_period, 
//                         subscription, service, additional_value, additional_value_group.
//     ** Value - String, Number, Date, Boolean - the value of the props.
//   * SetAppPermissions - Boolean - the need to set rights to applications.
//   * AppPermissions - ValueTable - installable rights to applications:
//     ** ApplicationCode - Number - application code (area number)
//     ** Right - EnumRef.ApplicationUserRights - the user role to install.
//
Function NewParametersForAddingUser() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	
	Parameters = New Structure;
	Parameters.Insert("Login", "");
	Parameters.Insert("UserRole", Enums.SubscriberUsersRoles.SubscriberUser);
	Parameters.Insert("LongDesc", "");
	Parameters.Insert("Forcibly", False);
	
	Parameters.Insert("AdditionalAttributes", IsInternal.NewAdditionalInformation());
	
	Parameters.Insert("SetAppPermissions", False);
	AppPermissions = New ValueTable;
	AppPermissions.Columns.Add("ApplicationCode", Common.TypeDescriptionNumber(10));
	AppPermissions.Columns.Add("Right", New TypeDescription("EnumRef.ApplicationUserRights"));
	Parameters.Insert("AppPermissions", AppPermissions);
	
	Return Parameters;
	
EndFunction

// Returns the parameter template for the method
// The service's software interface.Delete the user of the component.
// 
// Returns:
//  Structure:
//   * Login - String - login (user name)
Function NewUserDeletionParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Login", "");
	
	Return Parameters;
	
EndFunction

// Returns the parameter template for the method 
// The service's software interface.Set a limit on the number of sessions of the user of the component.
// 
// Returns:
//  Structure:
//   * Login - String - login (user name)
//   * AllowedNumberOfSessions - Number - set value.
Function NewSessionLimitsParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Login", "");
	Parameters.Insert("AllowedNumberOfSessions", 0);
	
	Return Parameters;
	
EndFunction

// Returns the available additional Attributes for the subscriber's user.
// Implements the method of the external programming interface - account/users/available_attached_info.
// Parameters:
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  ValueTable - additional Attributes of the subscriber's user:
//   * Key - String - name of additional account details
//   * Title - String - the header of the additional props
//   * Type - String - Value type 
Function AvailableSubscriberUserAdditionalAttributes(
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/available_attached_info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingAdditionalInformation();
	AdditionalAttributes = IsInternal.StructuresArrayIntoValueTable(ResponseData.fields, Renamings);
	
	Return AdditionalAttributes;
	
EndFunction

// Returns the parameter template for the method
// The service's software interface.Component UserApplication.
// 
// Returns:
//  Structure - template for parameters for adding a user to an application:
//   * SubscriberCode - Number - subscriber code
//   * Login - String - user login
//
Function NewParametersForRequestingSubscriberUserApp() Export
	
	Parameters = New Structure;
	Parameters.Insert("SubscriberCode", 0);
	Parameters.Insert("Login", "");
	
	Return Parameters;
	
EndFunction

#EndRegion 

#Region Account_Servants

// Returns the list of service organizations of the subscriber of this application.
// Implements the method of the external programming interface - account/servants/list
//
// Returns:
//  ValueTable - Subscriber's Service Organizations:
//   * Code - Number - code (number) of the service organization
//   * Description - String - name of the service organization
//   * Id - String - subscriber ID
//   * City - String - City
//   * Website1 - String - Website1
//   * Mail - String - Email
//   * Phone - String - Phone
//   * YouCanSubscribeToPricingPlans - Boolean - it is allowed to subscribe to tariffs
//   * AutomaticInvoiceIssuanceAllowed - Boolean - automatic billing is allowed
//   * TariffOverrideAllowed - Boolean - tariff redefinition allowed
//   * FareSelectionPageOnly - Boolean - display only the tariff selection page in the payment form
//
Function SubscriberSServiceOrganizations() Export

	Return ServiceProgrammingInterfaceCached.SubscriberSServiceOrganizations();

EndFunction

// Returns the HTML page of the tariff selection of the subscriber's service organization of this application.
// Implements the method of the external programming interface - account/servants/tariff_selection_page
// Parameters:
//  SCCode - Number - code of the service organization.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  String - HTML page for selecting the tariff of the service organization.
//
Function PageForSelectingServiceCompanySPricingPlan(SCCode,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/servants/tariff_selection_page";

	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("servant", SCCode);

	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(
		Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData <> Undefined Then
		Return ResponseData.html;
	Else
		Return Undefined;
	EndIf;

EndFunction

// Returns a list of recommended tariffs defined by the service organization.
// Implements the method of the external programming interface - account/servants/recommended_tariffs
//
// Parameters:
//  SCCode - Number - code of the service organization.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  ValueTable - list of tariffs:
//   * ProviderServicePlanCode - String - provider's tariff code
//   * ServiceProviderPlanCode - String - code of the service organization's tariff.
Function RecommendedRates(SCCode,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/servants/recommended_tariffs";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("servant", SCCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingRecommendedRates();
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.recommended_tariffs, Renamings);

EndFunction

// Returns a list of tariffs of the service organization.
// Implements the method of the external programming interface - account/servant_tariffs/list
//
// Parameters:
//  Filter - See NewSelectionOfSupportCompanyTariffsList
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  ValueTable - list of tariffs:
//   * Code - String - fare code
//   * Description - String - name of the tariff
//   * ProviderServicePlanCode - String - base rate code
//   * ShortDescription - String - brief description of the tariff
//   * ActionPeriods - ValueTable - periods of validity. Is filled in if the parameter for receiving the parameterreception period is passed:
//     ** Code - String - validity period code
//     ** Description - String - name of the validity period
//     ** Sum - Number - the cost of the tariff with this validity period
//     ** Recommended_ - Boolean - indicates that the validity period is recommended 
//     ** Comment - String - comment on the validity period.
//
Function ServiceOrganizationRates(Filter, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/servant_tariffs/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("servant", Filter.ServiceProviderCode);
	InterfaceVersion = InterfaceVersionProperties().Version;
	
	If InterfaceVersion >= 19 Then
		QueryData.Insert("scope", Filter.ReceivingParameters);
	EndIf;
	
	If InterfaceVersion >= 23 And Filter.AvailableServicePlans.Count() > 0 Then
		QueryData.Insert("available_tariffs", Filter.AvailableServicePlans);
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;

	RenamingValidityPeriods = IsInternal.RenamingServiceOrganizationTariffValidityPeriods();
	ValidityPeriodsField = "validity_periods";
	TariffField = "servant_tariff";
	
	If InterfaceVersion >= 19	And Not Filter.ReceivingParameters.Find(ParameterForGettingValidityPeriods()) = Undefined Then
		For Each Item In ResponseData[TariffField] Do
			Item[ValidityPeriodsField] = IsInternal.StructuresArrayIntoValueTable(Item[ValidityPeriodsField], RenamingValidityPeriods);
		EndDo;
	EndIf;
	
	Renamings = IsInternal.RenamingServiceOrganizationRates(Method);
	Result = IsInternal.StructuresArrayIntoValueTable(ResponseData[TariffField], Renamings);

	Return Result;

EndFunction

// Returns information about the service organization's pricing plan.
//
// Parameters:
//  SCCode - Number - code of the service organization.
//  ServicePlanCode - String - code of the service organization's tariff. 
// 
// Returns:
//  Structure - tariff information:
//   * Code - String - fare code
//   * Description - String - name of the tariff
//   * ProviderServicePlanCode - String - provider's tariff code
//   * ShortDescription - String - brief description of the tariff
//   * DescriptionForSubscribers - FormattedDocument - description of the tariff for subscribers.
//   * ActionPeriods - ValueTable - tariff validity periods:
//     ** Code - String - validity period code
//     ** Description - String - name of the validity period
//     ** Sum - Number - Cost
//     ** Recommended_ - Boolean - indicates that the period is recommended for purchase
//     ** Comment - String - comment on the validity period
//
Function ServiceOrganizationTariff(SCCode, ServicePlanCode) Export
	
	Return ServiceProgrammingInterfaceCached.ServiceOrganizationTariff(SCCode, ServicePlanCode);
	
EndFunction

#EndRegion 

#Region Backup

// Returns a list of subscriber backups
//
// Parameters:
//  Parameters - See NewGettingBackupsListParameters
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
Function SubscriberBackupsList(Parameters = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "backup/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	
	If ValueIsFilled(Parameters.BeginOfPeriod) Then
		QueryData.Insert("start_date", Parameters.BeginOfPeriod);
	EndIf;
	
	If ValueIsFilled(Parameters.EndOfPeriod) Then
		QueryData.Insert("end_date", Parameters.EndOfPeriod);
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingsBackups();
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.backup, Renamings);
	
EndFunction

// Returns properties of the backup copy by ID.
// Implements the method of the external software interface - backup/info.
// 
// Parameters:
//  CopyID - String - Backup ID
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Structure - Backup Properties:
//   * BackupIdentificator - UUID
//   * AreaNumber - Number
//   * AreaDescription - String
//   * Size - Number
//   * ConfigurationVersion - String
//   * AppTypeName - String
//   * Original - Boolean
//   * CreationDateUTC - Date
//   * OnDemand - Boolean
//   * Annual - Boolean
//   * Monthly_ - Boolean
//   * Daily_ - Boolean
//   * Comment - String
//   * TimeZone - String
//   * FileName - String
Function BackupProperties(CopyID,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "backup/info";

	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", CopyID);

	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingsBackups();
	
	Result = IsInternal.RenameProperties(ResponseData.backup, Renamings);
	
	Return Result;
	
EndFunction

// Returns the template for the application creation parameters for the Software Interface Service method.List of reserved copies of the component.
// 
// Returns:
//  Structure - template for app creation parameters:
//   * BeginOfPeriod - Date - start date of the period.
//   * EndOfPeriod - Date - end date of the period.
Function NewGettingBackupsListParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("BeginOfPeriod", '00010101');
	Parameters.Insert("EndOfPeriod", '00010101');
	
	Return Parameters;
	
EndFunction

// Returns data for downloading backups
//
// Parameters:
//  Parameters - See NewGettingBackupFileParameters
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Structure - backup download data:
//   * FileAddress - String - URL of the backup file.
//   * FileName - String - recommended file name to save.
//   * JobID - UUID - ID of the backup preparation task.
//   * Token - String
//   * TokenExpirationDate - Date
Function GettingBackupFileData(Parameters = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "backup/file_token/download";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	
	QueryData.Insert("id", Parameters.BackupIdentificator);
	
	If ValueIsFilled(Parameters.JobID) Then
		QueryData.Insert("task_id", Parameters.JobID);
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = New Map;
	Renamings.Insert("url", IsInternal.ColumnDetails(
		"FileAddress", Common.StringTypeDetails(0)));
	Renamings.Insert("file_name", IsInternal.ColumnDetails(
		"FileName", Common.StringTypeDetails(0)));
	Renamings.Insert("task_id", IsInternal.ColumnDetails(
		"JobID", Common.StringTypeDetails(36)));
	Renamings.Insert("token", IsInternal.ColumnDetails(
		"Token", Common.StringTypeDetails(0)));
	Renamings.Insert("expires_at", IsInternal.ColumnDetails(
		"TokenExpirationDate", Common.DateTypeDetails(DateFractions.DateTime)));
	
	Result = IsInternal.RenameProperties(ResponseData, Renamings);
	
	Return Result;
	
EndFunction

// Returns a template for parameters for getting a backup file for the Software Interface Service method.Data for receiving a backup copy file.
// 
// Returns:
//  Structure - template for parameters for getting a backup file:
//   * BackupIdentificator - String - ID of the backup.
//   * JobID - String - ID of the backup preparation task.
Function NewGettingBackupFileParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("BackupIdentificator", "");
	Parameters.Insert("JobID", "");
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Customers

// Returns a list of serviced subscribers.
// Implements the method of the external programming interface - account/customers/list
//
// Parameters:
//  SCCode - Number - the code (number) of the lead subscriber (if not specified, the subscriber of the current application is used).
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  ValueTable:
//   * Description - String - subscriber name (length-64)
//   * Code - String - code (number) of the served subscriber (length-12).
Function ServedSubscribers(SCCode = Undefined, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customers/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	If SCCode = Undefined Then
		SCCode = SubscriberCode();
	EndIf; 
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SCCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.customer, IsInternal.RenamingSubscriber());

EndFunction

// Returns properties of the served subscriber.
// Implements the method of the external programming interface - account/customers/info
//
// Parameters:
//  SubscriberCode - Number - the code (number) of the served subscriber.
//  SCCode - Number - the code (number) of the lead subscriber (if not specified, the subscriber of the current application is used).
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Structure:
//   * Description - String - subscriber name (length-64)
//   * Code - String - code (number) of the served subscriber (length-12)
//   * Website1 - String - site from KI (length-500)
//   * City - String - city of KI (length-500)
//   * Mail - String - mail from KI (length-500)
//   * Phone - String - phone from KI (length-500)
//
Function PropertiesOfServedSubscriber(SubscriberCode, SCCode = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customers/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	If SCCode = Undefined Then
		SCCode = SubscriberCode();
	EndIf; 
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SCCode);
	QueryData.Insert("account", SubscriberCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Return IsInternal.RenameProperties(ResponseData.customer, IsInternal.RenamingSubscriber(True));
	
EndFunction

// Returns additional information (details and properties) of the serviced subscriber.
// Implements the method of the external programming interface - account/customers/attached_info
//
// Parameters:
//  SubscriberCode - Number - the code (number) of the served subscriber.
//  SCCode - Number - the code (number) of the lead subscriber (if not specified, the subscriber of the current application is used).
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//  
// Returns:
//  Structure - additional Attributes and subscriber properties:
//   * PublicId - String - public subscriber ID
//   * Attributes - ValueTable - additional Attributes of the subscriber:
//     ** Key - String - name of additional account details
//     ** Type - String - Value type 
//     ** Value - String, Number, Date, Boolean - Value of additional details
//   * Properties - ValueTable - additional subscriber properties:
//     ** Key - String - name of the additional property
//     ** Type - String - Value type
//     ** Value - String, Number, Date, Boolean - value of the additional property
Function AdditionalInformationOfServedSubscriber(SubscriberCode, SCCode = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customers/attached_info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	If SCCode = Undefined Then
		SCCode = SubscriberCode();
	EndIf; 
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SCCode);
	QueryData.Insert("account", SubscriberCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
		
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	ResponseData.Delete("general");
	
	Renamings = New Map;
	Renamings.Insert("public_id", IsInternal.ColumnDetails(
		"PublicId", Common.StringTypeDetails(36)));
	Renamings.Insert("properties", "Properties");
	Renamings.Insert("fields", "Attributes");
	Result = IsInternal.RenameProperties(ResponseData, Renamings);
	
	Result.Properties = IsInternal.StructuresArrayIntoValueTable(
		Result.Properties, IsInternal.RenamingAdditionalInformation());
	Result.Attributes = IsInternal.StructuresArrayIntoValueTable(
		Result.Attributes, IsInternal.RenamingAdditionalInformation());
	
	Return Result;
	
EndFunction

// Updates additional information (details and properties) of the serviced subscriber.
// Implements the method of the external programming interface - account/customers/update_attached_info.
//
// Parameters:
//  AddProperties - See NewAdditionalSubscriberInformation
//  SCCode - Number - the code (number) of the lead subscriber (if not specified, the subscriber of the current application is used).
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//  
// Returns:
//  Boolean - setting additional information: True - installed, False - an error occurred.
//
Function UpdateAdditionalInformationOfServedSubscriber(AddProperties, SCCode = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customers/update_attached_info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	If SCCode = Undefined Then
		SCCode = SubscriberCode();
	EndIf; 
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SCCode);
	QueryData.Insert("account", AddProperties.SubscriberCode);
	QueryData.Insert("public_id", AddProperties.PublicId);
	
	Renamings = IsInternal.RenamingAdditionalInformation(False);
	If AddProperties.Property("Attributes") Then
		QueryData.Insert("fields", IsInternal.TableOfValuesInArrayOfStructures(
			AddProperties.Attributes, Renamings));
	EndIf;
	If AddProperties.Property("Properties") Then
		QueryData.Insert("properties", IsInternal.TableOfValuesInArrayOfStructures(
			AddProperties.Properties, Renamings));
	EndIf;

	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns a template for additional subscriber information.
// 
// Returns:
//  Structure:
//   * SubscriberCode - Number - subscriber code
//   * PublicId - String - public subscriber ID (length - 36), may be missing.
//   * Attributes - ValueTable - additional Attributes of the subscriber: 
//     ** Key - String - name of additional account details
//     ** Type - String - value type (optional if the additional property has the same value type)
//     ** Value - String, Number, Date, Boolean - Value of additional details
//   * Properties - ValueTable - additional subscriber properties: 
//     ** Key - String - name of the additional property
//     ** Type - String - value type (optional, if the add. the properties of one type of value)
//     ** Value - String, Number, Date, Boolean - value of the additional property
//
Function NewAdditionalSubscriberInformation() Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	
	Result = New Structure;
	Result.Insert("SubscriberCode", 0);
	Result.Insert("PublicId", "");
	Result.Insert("Attributes", IsInternal.NewAdditionalInformation());
	Result.Insert("Properties", IsInternal.NewAdditionalInformation());
	
	Return Result;

EndFunction

#EndRegion

#Region CustomerSubscriptions

// Returns a list of subscriptions to the tariffs of the subscribers served.
// Implements the method of the external programming interface - account/customer_subscriptions/list
//
// Parameters:
//  Filter - See NewPricingPlanSubscriptionSelection
//  SCCode - Number - the code (number) of the lead subscriber (if not specified, the subscriber of the current application is used).
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  ValueTable - existing tariff subscriptions:
//   * Number - String - subscription number
//   * Date - Date - registration date of the subscription
//   * ConnectionDate - Date - subscription rate activation date
//   * DateOfExpiration - Date - date when the tariff was disabled
//   * ServicedSubscriberCode - Number - code (number) of the served subscriber
//   * MasterSubscriberCode - Number - code (number) of the lead subscriber
//   * ServiceProviderPlanCode - String - tariff code of the service organization
//   * ProviderServicePlanCode - String - subscription rate code
//   * ValidityPeriodCode - String - validity period code
//   * Count - Number - the number of tariffs in the subscription
//   * PrimarySubscriptionNumber - String - number of the main subscription, if the current subscription to the plan is an extension.
//   * SubscriptionType - EnumRef.ServiceSubscriptionsTypes - subscription type
//   * InvoiceNum - String - Invoice Number For Payment
//   * PaymentInvoiceID - UUID - ID of the payment invoice
//
Function SubscriptionsToPricingPlans(Filter, SCCode = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customer_subscriptions/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	If SCCode = Undefined Then
		SCCode = SubscriberCode();
	EndIf; 
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("servant", SCCode);
	
	If TypeOf(Filter) = Type("Structure") Then
		FilterFields = New Map;
		FilterFields.Insert("ServicedSubscriberCode", "account");
		FilterFields.Insert("ActiveOnly", "active");
		FilterFields.Insert("MainOnly", "basic");
		FilterFields.Insert("BeginOfPeriod", "start_date");
		FilterFields.Insert("EndOfPeriod", "end_date");
		For Each Item In FilterFields Do
			If Filter.Property(Item.Key) And ValueIsFilled(Filter[Item.Key]) Then
				QueryData.Insert(Item.Value, Filter[Item.Key]);
			EndIf; 
		EndDo;
	Else
		Filter = NewPricingPlanSubscriptionSelection();
	EndIf; 
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
		
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingSubscriptionPlan(True);
	
	Result = IsInternal.StructuresArrayIntoValueTable(ResponseData.subscription, Renamings);
	Result.Sort("Date");
	InterfaceVersion = InterfaceVersionProperties().Version;
	For IndexOf = 1 To Result.Count() Do
		String = Result[Result.Count() - IndexOf];
		If Filter.MainOnly And InterfaceVersion < 14 And Not IsBlankString(String.PrimarySubscriptionNumber) Then
			Result.Delete(String);
			Continue;
		EndIf;
		If String.Count = 0 Then
			String.Count = 1;
		EndIf;
	EndDo;
	
	Return Result;

EndFunction

// Returns properties of subscription to the tariff of the served subscriber.
// Implements the method of the external programming interface - account/customer_subscriptions/info
// 
// Parameters:
//  SubscriptionNumber - String - subscription number.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//  
// Returns:
//  Structure - Tariff Subscription Properties:
//   * Number - String - subscription number
//   * Date - Date - registration date of the subscription
//   * ConnectionDate - Date - subscription rate activation date
//   * DateOfExpiration - Date - date when the tariff was disabled
//   * ServicedSubscriberCode - Number - code (number) of the served subscriber
//   * MasterSubscriberCode - Number - code (number) of the lead subscriber
//   * ServiceProviderPlanCode - String - tariff code of the service organization
//   * ProviderServicePlanCode - String - subscription rate code
//   * ValidityPeriodCode - String - validity period code
//   * Count - Number - the number of tariffs in the subscription
//   * PrimarySubscriptionNumber - String - number of the main subscription, if the current subscription to the plan is an extension.
//   * SubscriptionType - EnumRef.ServiceSubscriptionsTypes - subscription type
//   * InvoiceNum - String - Invoice Number For Payment
//   * PaymentInvoiceID - UUID - ID of the payment invoice
Function TariffSubscriptionProperties(SubscriptionNumber,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customer_subscriptions/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriptionNumber);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingSubscriptionPlan(True);
	
	Result = IsInternal.RenameProperties(ResponseData.subscription, Renamings);
	If Result.Count = 0 Then
		Result.Count = 1;
	EndIf; 
	
	Return Result;
	
EndFunction

// Returns properties of the subscriber's subscription plan.
// Implements the method of the external program interface - subscription/info
// 
// Parameters:
//  SubscriptionNumber - String - subscription number.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//  
// Returns:
//  Structure - Tariff Subscription Properties:
//   * Number - String - subscription number
//   * Date - Date - registration date of the subscription
//   * ConnectionDate - Date - subscription rate activation date
//   * DateOfExpiration - Date - date when the tariff was disabled
//   * ServicedSubscriberCode - Number - code (number) of the served subscriber
//   * MasterSubscriberCode - Number - code (number) of the lead subscriber
//   * ServiceProviderPlanCode - String - tariff code of the service organization
//   * ProviderServicePlanCode - String - subscription rate code
//   * ValidityPeriodCode - String - validity period code
//   * Count - Number - the number of tariffs in the subscription
//   * PrimarySubscriptionNumber - String - number of the main subscription, if the current subscription to the plan is an extension.
//   * SubscriptionType - EnumRef.ServiceSubscriptionsTypes - subscription type
//   * InvoiceNum - String - Invoice Number For Payment
//   * PaymentInvoiceID - UUID - ID of the payment invoice
Function SubscriberTariffSubscriptionProperties(SubscriptionNumber,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "subscription/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriptionNumber);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	Renamings = IsInternal.RenamingSubscriptionPlan(True);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Result = IsInternal.RenameProperties(ResponseData.subscription, Renamings);
	If Result.Count = 0 Then
		Result.Count = 1;
	EndIf; 
	
	Return Result;
	
EndFunction

// Creates a new subscription to the main tariff of the serviced subscriber
// Implements the method of the external programming interface - account/customer_subscriptions/create
//
// Parameters:
//  SubscriptionData_ - See NewSubscriptionTemplateForBasicPlan
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Undefined, Structure - if the subscription was completed successfully:
//   * Number - String - the number of the created subscription.
//   * DateOfExpiration - Date - the date when the created subscription was disabled.
Function CreateSubscriptionToMainTariff(SubscriptionData_,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customer_subscriptions/create";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	PropertiesNames = IsInternal.SubscriptionCreationPropertyNames();
	For Each Item In PropertiesNames Do
		If SubscriptionData_.Property(Item.Key) And ValueIsFilled(SubscriptionData_[Item.Key]) Then
			QueryData.Insert(Item.Value, SubscriptionData_[Item.Key]);
		EndIf; 
	EndDo; 
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
		
	If BasicResponseProperties.ResponseCode >=10200 And BasicResponseProperties.ResponseCode <= 10299 Then
		Renamings = IsInternal.RenamingAndCreatingSubscriptionToPricingPlan();
		Result = IsInternal.RenameProperties(ResponseData, Renamings);
		Result.Delete("general");
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;

EndFunction

// The method creates a new subscription or several subscriptions to expand the tariff of the served subscriber.
// Implements the method of the external programming interface - account/customer_subscriptions/create_enhanced
//
// Parameters:
//  TariffExtensionData - See NewSubscriptionTemplateForTariffExpansion
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Undefined, ValueTable - if the subscription was completed successfully:
//   * Number - String - the number of the created subscription.
//   * DateOfExpiration - Date - the date when the created subscription was disabled.
Function CreateSubscriptionToTariffExtension(TariffExtensionData,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customer_subscriptions/create_enhanced";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	
	PropertiesNames = IsInternal.SubscriptionCreationPropertyNames(True);
	For Each Item In PropertiesNames Do
		If TariffExtensionData.Property(Item.Key) And ValueIsFilled(TariffExtensionData[Item.Key]) Then
			QueryData.Insert(Item.Value, TariffExtensionData[Item.Key]);
		EndIf; 
	EndDo; 
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
		
	If BasicResponseProperties.ResponseCode >=10200 And BasicResponseProperties.ResponseCode <= 10299 Then
		Renamings = IsInternal.RenamingAndCreatingSubscriptionToPricingPlan();
		Result = IsInternal.StructuresArrayIntoValueTable(ResponseData.subscription_info, Renamings);
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;

EndFunction

// Returns a template for a new subscription to the main tariff of the served subscriber.
//
// Returns:
//  Structure:
//   * MasterSubscriberCode - Number - code (number) of the lead subscriber
//   * ServicedSubscriberCode - Number - code (number) of the served subscriber
//   * ServiceProviderPlanCode - String - tariff code of the service organization
//   * ProviderServicePlanCode - String - subscription rate code
//   * ValidityPeriodCode - String - subscription period code
//   * ConnectionDate - Date - subscription rate activation date
//   * DateOfExpiration - Date - date when the tariff was disabled
Function NewSubscriptionTemplateForBasicPlan() Export

	Template = New Structure;
	Template.Insert("MasterSubscriberCode", 0);
	Template.Insert("ServicedSubscriberCode", 0);
	Template.Insert("ServiceProviderPlanCode", "");
	Template.Insert("ProviderServicePlanCode", "");
	Template.Insert("ValidityPeriodCode", "");
	Template.Insert("ConnectionDate", '00010101');
	Template.Insert("DateOfExpiration", '00010101');
	
	Return Template;
	
EndFunction

// Returns a template for a new subscription to expand the tariff of the serviced subscriber.
//
// Returns:
//  Structure:
//   * MasterSubscriberCode - Number - code (number) of the lead subscriber
//   * ServicedSubscriberCode - Number - code (number) of the served subscriber
//   * ServiceProviderPlanCode - String - tariff code of the service organization
//   * ProviderServicePlanCode - String - subscription rate code
//   * ValidityPeriodCode - String - subscription period code
//   * ConnectionDate - Date - subscription rate activation date
//   * DateOfExpiration - Date - date when the tariff was disabled
//   * PrimarySubscriptionNumber - String - basic plan subscription number
//   * Count - Number - the number of tariffs in the subscription.
Function NewSubscriptionTemplateForTariffExpansion() Export
	
	Template = NewSubscriptionTemplateForBasicPlan();
	Template.Insert("PrimarySubscriptionNumber", "");
	Template.Insert("Count", 0);
	
	Return Template;
	
EndFunction

#EndRegion

#Region AccountingSystem

// Returns a list of accounting systems available to the subscriber.
// Implements the method of the external programming interface - accounting_system/list
//
// Parameters:
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  ValueTable - list of subscriber's accounting systems:
//   * Code - Number - the code of the accounting system
//   * Description - String - name of the accounting system
//   * OwnerCode - Number - code of the subscriber-owner of the accounting system
//   * ImportingData - Boolean - indication of data loading
//   * LoginUserToUpload - String - user login for uploading data
//   * ExportingData - Boolean - indication of data upload
//   * ExportingURL - String - URL of the accounting system for uploading data
//   * ExportingUserLogin - String - user login for uploading data
//
Function ListOfAccountingSystems(RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "accounting_system/list";
	QueryData = IsInternal.QueryTemplate(Method);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
		
	Renamings = IsInternal.RenamingAccountingSystem(Method);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.accounting_system, Renamings);
	
EndFunction

// Returns the properties of the subscriber's accounting system by the code of the accounting system.
// Implements the method of the external programming interface - accounting_system/info
//
// Parameters:
//  Code - Number - the code of the subscriber's accounting system.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Structure - Accounting System Properties:
//   * Code - Number - subscriber's accounting system code
//   * Description - String - name of the accounting system
//   * LongDesc - String - description of the accounting system
//   * OwnerCode - Number - code of the subscriber-owner of the accounting system
//   * ImportingData - Boolean - indication of data loading
//   * ImportingUserLogin - String - user login for uploading data to the service manager
//   * ImportingRules - ValueTable - rules for uploading data:
//     ** RuleCode - String - code of the data loading rule
//     ** Address - String - address of the object to upload data to
//   * ExportingData - Boolean - indication of data upload
//   * ExportingURL - String - The URL of the accounting system for uploading data to the accounting system
//   * ExportingUserLogin - String - user login for uploading data 
//   * ExportingRules - ValueTable - rules for uploading data:
//     ** RuleCode - String - the code of the data upload rule
//     ** RowID - UUID - id of the upload rule line 
//     ** ConditionCode - String - code of the terms of use of the upload rule
//     ** Address - String - address of the object to upload data to
//     ** FastSending - Boolean - a sign of a fast dispatch
//     ** ScheduledExport - Boolean - indication of scheduled unloading
//     ** SelectionBySupplier - Boolean - indication of selection by supplier
//   * ResponseProcessingRules - ValueTable:
//     ** ExportingRuleLineId - UUID - id of the upload rule line
//     ** RuleCode - String - code of the response processing rule
//     ** ResponseCodes - Array of Number - response codes for calling the processing rule.
//   
Function AccountingSystemProperties(Code, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "accounting_system/info";
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", Code);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
		
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingAccountingSystem(Method);
	
	Result = IsInternal.RenameProperties(ResponseData.accounting_system, Renamings);
	
	Result.ExportingRules = IsInternal.StructuresArrayIntoValueTable(
		Result.ExportingRules, IsInternal.RenamingAccountingSystemUploadRules());
		
	Result.ImportingRules = IsInternal.StructuresArrayIntoValueTable(
		Result.ImportingRules, IsInternal.RenamingAccountSystemUploadRules());
		
	Result.ResponseProcessingRules = IsInternal.StructuresArrayIntoValueTable(
		Result.ResponseProcessingRules, IsInternal.RenamingAccountSystemResponseProcessingRules());
	
	Return Result;
	
EndFunction

// Creates a new or updates an existing billing system.
// Implements the method of the external programming interface - accounting_system/create_update_billing
//
// Parameters:
//  UpdateCreationParameters - See NewSettingsForCreatingUpdatingBillingAccountSystem
//  RaiseExceptionAtError - Boolean - indicates whether an exception is raised in case of an error.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Structure - Accounting System Properties:
//   * Code - Number - subscriber's accounting system code
//   * Description - String - name of the accounting system
//
Function CreateUpdateBillingAccountSystem(UpdateCreationParameters, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "accounting_system/create_update_billing";
	QueryData = IsInternal.QueryTemplate(Method);
	If ValueIsFilled(UpdateCreationParameters.AccountingSystemCode) Then
		QueryData.Insert("id", UpdateCreationParameters.AccountingSystemCode);
	EndIf; 
	QueryData.Insert("import_login", UpdateCreationParameters.ImportingUserLogin);
	QueryData.Insert("export_url", UpdateCreationParameters.ExportingURL);
	QueryData.Insert("export_login", UpdateCreationParameters.ExportingUserLogin);
	QueryData.Insert("export_password", UpdateCreationParameters.ExportingPassword);

	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
		
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails(
		"Code", Common.TypeDescriptionNumber(9, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("name", IsInternal.ColumnDetails(
		"Description", Common.StringTypeDetails(100)));
	
	Result = IsInternal.RenameProperties(ResponseData, Renamings);
	Result.Delete("general");
	
	Return Result;

EndFunction

// Returns the template of parameters for creating\updating the billing accounting system.
//
// Returns:
//  Structure - Parameter Template:
//   * ImportingUserLogin - String - user login for uploading data to the service manager
//   * ExportingUserLogin - String - user login for uploading data to the accounting system
//   * ExportingURL - String - The URL of the accounting system for uploading data to the accounting system
//   * ExportingPassword - String - the user's password for uploading data to the accounting system 
//   * AccountingSystemCode - Number - the code of the subscriber's updated accounting system.
//   								If not specified, a new accounting system is created.
Function NewSettingsForCreatingUpdatingBillingAccountSystem() Export

	Parameters = New Structure;
	Parameters.Insert("AccountingSystemCode", 0);
	Parameters.Insert("ImportingUserLogin", "");
	Parameters.Insert("ExportingURL", "");
	Parameters.Insert("ExportingUserLogin", "");
	Parameters.Insert("ExportingPassword", "");
	
	Return Parameters;
	
EndFunction

#EndRegion 

#Region Application

// Returns a list of application configurations available to the subscriber of this application.
// 
// Parameters:
//  RaiseExceptionAtError - Boolean - indicates whether an exception is raised in case of an error.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//   
// Returns:
//  ValueTable - available configurations:
//    * Code - String - configuration code
//    * Description - String - synonym for configuration 
//    * Name - String - name of the configuration (as specified in the Configurator).
//    * LongDesc - String - the description of the configuration 
//    * SubscriberCode - Number - code of the subscriber. 
//
Function Configurations(RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "application/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode());
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingsConfiguration();
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.application, Renamings);
	
EndFunction

// Returns the properties of the application configuration.
// 
// Parameters:
//  ConfigurationCode - String - Configuration code.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is raised in case of an error.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//   
// Returns:
//  ValueTable - available configurations:
//    * Code - String - configuration code
//    * Description - String - synonym for configuration 
//    * Name - String - name of the configuration (as specified in the Configurator).
//    * LongDesc - String - configuration description.
//    * Picture - String - configuration icon in Base64 format.
//    * SubscriberCode - Number - code of the subscriber.
//
Function Configuration(ConfigurationCode,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "application/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", ConfigurationCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingsConfiguration();
	Return IsInternal.RenameProperties(ResponseData.application, Renamings);
	
EndFunction

#EndRegion

#Region AppType

// Returns a list of transition options for application types
// Implements the method of the external programming interface - apptype/transition_options/list
// 
// Parameters:
//  Filter - See NewUpgradeOptionsFilter
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Undefined, ValueTable - list of app view transition handlers:
//   * ConfigurationVersionNumber - String - Configuration Version Number
//   * PreviousAppTypeCode - String - Code Of The Previous Application Type
//   * AppTypeCode - String - code of the target application type
//   * AppTypeName - String - Name Of The Target Application Type
//   * NameOfAppType - String - name of the target application type 
//
Function AppTypesUpgradeOptionsList(Filter = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "apptype/transition_options/list";
	QueryData = IsInternal.QueryTemplate(Method);
	
	If TypeOf(Filter) = Type("Structure") Then
		FilterFields = New Map;
		FilterFields.Insert("ConfigurationCode", "conf_id");
		FilterFields.Insert("ConfigurationVersion", "conf_version");
		FilterFields.Insert("AppTypeCode", "apptype_id");
		For Each Item In FilterFields Do
			If Filter.Property(Item.Key) And ValueIsFilled(Filter[Item.Key]) Then
				QueryData.Insert(Item.Value, Filter[Item.Key]);
			EndIf;
		EndDo;
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingAppTypesUpgradeOptions();
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.transition_options, Renamings);
	
EndFunction

// Returns a template for selecting transition handlers.
//
// Returns:
//  Structure:
//   * ConfigurationCode - String - configuration code
//   * ConfigurationVersion - String - configuration version
//   * AppTypeCode - String - Application Type Code
Function NewUpgradeOptionsFilter() Export
	
	UpgradeOptionsFilter = New Structure;
	UpgradeOptionsFilter.Insert("ConfigurationCode", "");
	UpgradeOptionsFilter.Insert("ConfigurationVersion", "");
	UpgradeOptionsFilter.Insert("AppTypeCode", "");
	
	Return UpgradeOptionsFilter;
	
EndFunction

#EndRegion

#Region Bill

// Returns a list of invoices for payment
// Implements the method of the external programming interface - bill/list
// 
// Parameters:
//  Filter - See NewSelectionOfInvoicesForPayment
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  ValueTable - List Of Invoices:
//	 * Number - String - account number
//	 * Date - Date - invoice creation date
//	 * ChangeDate - Date - date of invoice change
//	 * InvoiceId - UUID - account ID
//	 * SellerCode - Number - code (number) of the subscriber-seller
//	 * BuyerSCode - Number - code (number) of the subscriber-buyer
//	 * Sum - Number - invoice amount
//	 * Renewal - Boolean - sign of renewal
//	 * PaymentURL - String - the payment link
//	 * Paid - Boolean - indication of payment of the invoice
//	 * AdditionalInformation - String - additional account information
//	 * Comment - String - review of accounts
Function ListOfInvoices(Filter = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/list";
	QueryData = IsInternal.QueryTemplate(Method);
	
	If TypeOf(Filter) = Type("Structure") Then
		FilterFields = New Map;
		FilterFields.Insert("Seller", "seller_id");
		FilterFields.Insert("Customer", "customer_id");
		FilterFields.Insert("BeginOfPeriod", "start_date");
		FilterFields.Insert("EndOfPeriod", "end_date");
		For Each Item In FilterFields Do
			If Filter.Property(Item.Key) And ValueIsFilled(Filter[Item.Key]) Then
				QueryData.Insert(Item.Value, Filter[Item.Key]);
			EndIf; 
		EndDo; 
	EndIf; 
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
		
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.InvoiceRenamings(Method);
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.bill, Renamings);
	
EndFunction

// Returns the invoice data for payment by the invoice number or ID.
// Implements the method of the external programming interface - bill/info
//
// Parameters:
//  InvoiceId - UUID - account ID (not specified if the account number is passed)
//  AccountNumber - String - account number (not specified if the account ID is passed)
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Structure - account data:
//	 * Number - String - account number
//	 * Date - Date - invoice creation date
//	 * ChangeDate - Date - date of invoice change
//	 * InvoiceId - UUID - account ID
//	 * SellerCode - Number - code (number) of the subscriber-seller
//	 * BuyerSCode - Number - code (number) of the subscriber-buyer
//	 * Sum - Number - invoice amount
//	 * Renewal - Boolean - sign of renewal
//	 * PaymentURL - String - the payment link
//	 * Paid - Boolean - indication of payment of the invoice
//	 * AdditionalInformation - String - additional account information
//	 * Comment - String - review of accounts
//   * ServicePlans - ValueTable - ServicePlans:
//     ** ProviderServicePlanCode - String - provider's tariff code
//     ** ServiceProviderPlanCode - String - tariff code of the service organization
//     ** ValidityPeriodCode - String - code of the tariff validity period
//     ** Count - Number - the number of tariffs in the subscription
//     ** Sum - Number - the cost of the tariff, including the validity period
//     ** NumberOfBaseDocument - String - the number of subscription-base
//   * Services - ValueTable - Services:
//     ** OperationService - String - name of the service
//     ** Sum - Number - the cost of the service
//   * Files - ValueTable - The Presentation files of the Cur Invoice for payment:
//     ** Id - UUID - file id
//     ** LongDesc - String - name of the invoice view file
//   * AdditionalAttributes - ValueTable - additional Attributes of the account:
//     ** Key - String - name of additional account details
//     ** Type - String - Value type 
//     ** Value - String, Number, Date, Boolean - Value of additional details
//	 * State - Structure - account State Data:
//     ** Error - Boolean - error indication
//     ** LongDesc - String - status description
//     ** Name - String - State Name:
//         "created" - created
//         "wait_sending" - pending
//         "wait_registration" - pending
//         "wait_payment" - pending
//         "paid" - paid
//         "billing_error" - billing error.
Function CustomerInvoiceDetails(InvoiceId = Undefined, AccountNumber = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/info";
	QueryData = IsInternal.QueryTemplate(Method);
	If Not IsBlankString(AccountNumber) Then
		QueryData.Insert("id", AccountNumber);
	ElsIf TypeOf(InvoiceId) = Type("UUID") 
		And InvoiceId <> CommonClientServer.BlankUUID() Then
		QueryData.Insert("bill_id", InvoiceId);
	EndIf; 
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.InvoiceRenamings(Method);
	Renamings.Insert("tariffs", "ServicePlans");
	Renamings.Insert("services", "Services");
	Renamings.Insert("files", "Files");
	Renamings.Insert("fields", "AdditionalAttributes");
	Renamings.Insert("status", "State");
	
	Result = IsInternal.RenameProperties(ResponseData.bill, Renamings);
	Result.ServicePlans = IsInternal.StructuresArrayIntoValueTable(Result.ServicePlans, IsInternal.RenamingInvoice());
	Result.Services = IsInternal.StructuresArrayIntoValueTable(Result.Services, IsInternal.RenamingServiceAccount());
	Result.Files = IsInternal.StructuresArrayIntoValueTable(Result.Files, IsInternal.RenamingAccountFiles());
	Result.AdditionalAttributes = IsInternal.StructuresArrayIntoValueTable(
		Result.AdditionalAttributes, IsInternal.RenamingAdditionalInformation());
	Result.State = IsInternal.RenameProperties(Result.State, IsInternal.RenamingAccountState());
	
	Return Result;

EndFunction

// Creates a new invoice for payment.
// Implements the method of the external programming interface - bill/create
// 
// Parameters:
//  InvoiceData - Structure:
//	 * InvoiceId - UUID - account ID
//	 * SellerCode - Number - code (number) of the subscriber-seller
//	 * BuyerSCode - Number - code (number) of the subscriber-buyer
//	 * Sum - Number - invoice amount
//	 * Renewal - Boolean - sign of renewal
//	 * PaymentURL - String - the payment link
//	 * Paid - Boolean - indication of payment of the invoice
//	 * AdditionalInformation - String - additional account information
//	 * Comment - String - review of accounts
//   * ServicePlans - ValueTable - ServicePlans:
//     ** ProviderServicePlanCode - String - provider's tariff code
//     ** ServiceProviderPlanCode - String - tariff code of the service organization
//     ** ValidityPeriodCode - String - code of the tariff validity period
//     ** Count - Number - the number of tariffs in the subscription
//     ** Sum - Number - the cost of the tariff, including the validity period
//     ** NumberOfBaseDocument - String - the number of subscription-base
//   * Services - ValueTable - Services:
//     ** OperationService - String - name of the service
//     ** Sum - Number - the cost of the service
//   * Files - ValueTable - The Presentation files of the Cur Invoice for payment:
//     ** Id - UUID - file id
//     ** LongDesc - String - name of the invoice view file
//   * AdditionalAttributes - ValueTable - additional Attributes of the account:
//     ** Key - String - name of additional account details
//     ** Type - String - value type (optional if the additional property has the same value type)
//     ** Value - String, Number, Date, Boolean - Value of additional details
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Structure:
//   * Number - String - the number of the created payment invoice
//   * InvoiceId - UUID - the ID of the newly created invoices.	
Function CreatePaymentInvoice(InvoiceData,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/create";
	QueryData = IsInternal.RequestDataForCreatingAndModifyingInvoiceForPayment(InvoiceData, Method);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	Result = New Structure;
	Result.Insert("Number");
	Result.Insert("InvoiceId", CommonCTL.BlankUUID());
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Renamings = IsInternal.RenamingAccountResultOfCreatingChange();
		IsInternal.RenameProperties(ResponseData, Renamings);
		FillPropertyValues(Result, ResponseData);
	EndIf;
	
	Return Result;
	
EndFunction

// Modifies an existing payment invoice.
// Implements the method of the external programming interface - bill/update
// 
// Parameters:
//  InvoiceData - Structure:
//   * InvoiceId - UUID - account ID
//   * SellerCode - Number - code (number) of the subscriber-seller
//	 * BuyerSCode - Number - code (number) of the subscriber-buyer
//	 * Sum - Number - invoice amount
//	 * Renewal - Boolean - sign of renewal
//	 * PaymentURL - String - the payment link
//	 * Paid - Boolean - indication of payment of the invoice
//	 * AdditionalInformation - String - additional account information
//	 * Comment - String - review of accounts
//   * ServicePlans - ValueTable - ServicePlans:
//     ** ProviderServicePlanCode - String - provider's tariff code
//     ** ServiceProviderPlanCode - String - tariff code of the service organization
//     ** ValidityPeriodCode - String - code of the tariff validity period
//     ** Count - Number - the number of tariffs in the subscription
//     ** Sum - Number - the cost of the tariff, including the validity period
//     ** NumberOfBaseDocument - String - the number of subscription-base
//   * Services - ValueTable - Services:
//     ** OperationService - String - name of the service
//     ** Sum - Number - the cost of the service
//   * Files - ValueTable - The Presentation files of the Cur Invoice for payment:
//     ** Id - UUID - file id
//     ** LongDesc - String - name of the invoice view file
//   * AdditionalAttributes - ValueTable - additional Attributes of the account:
//     ** Key - String - name of additional account details
//     ** Type - String - value type (optional if the additional property has the same value type)
//     ** Value - String, Number, Date, Boolean - Value of additional details
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Structure:
//   * Number - String - number of the changed payment invoice
//   * InvoiceId - UUID - id of the modified payment invoice.	
Function ChangeInvoiceForPayment(InvoiceData,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/update";
	
	QueryData = IsInternal.RequestDataForCreatingAndModifyingInvoiceForPayment(InvoiceData, Method) ;
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	Result = New Structure;
	Result.Insert("Number");
	Result.Insert("InvoiceId", CommonCTL.BlankUUID());
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Renamings = IsInternal.RenamingAccountResultOfCreatingChange();
		IsInternal.RenameProperties(ResponseData, Renamings);
		FillPropertyValues(Result, ResponseData);
	EndIf;
	
	Return Result;
	
EndFunction	

// Returns a coupon for uploading a file to an existing payment invoice
// Implements the method of the external programming interface - bill/file_token/upload
//
// Parameters:
//  ReceivingParameters - See NewOptionsForGettingFileUploadCoupon
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//  
// Returns:
//  Structure:
//  * AccountNumber - String - account number
//  * InvoiceId - UUID - account ID
//  * DataTransferDirection - String - the direction of the transmission file = "upload"
//  * FileImportCoupon - String - a ticket for downloading a file
//  * ImportURL - String - URL for uploading a file using the PUT method
Function InvoiceForPaymentAndDownloadCoupon(ReceivingParameters,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/file_token/upload";
	QueryData = IsInternal.QueryTemplate(Method);
	If ReceivingParameters.Property("AccountNumber") Then
		AccountNumber = ReceivingParameters.AccountNumber;
	Else
		AccountNumber = "";
	EndIf; 
	If ReceivingParameters.Property("InvoiceId") Then
		InvoiceId = ReceivingParameters.InvoiceId;	
	Else
		InvoiceId = CommonClientServer.BlankUUID();
	EndIf; 
	If Not IsBlankString(AccountNumber) Then
		QueryData.Insert("id", AccountNumber);
	ElsIf TypeOf(InvoiceId) = Type("UUID") 
		And InvoiceId <> CommonClientServer.BlankUUID() Then
		QueryData.Insert("bill_id", InvoiceId);
	EndIf; 
	QueryData.Insert("name", ReceivingParameters.FileName);
	QueryData.Insert("size", ReceivingParameters.Size);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
		
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingInvoiceDownloadCoupon();
	Result = IsInternal.RenameProperties(ResponseData, Renamings);
	Result.Delete("general");
	
	Return Result;
	
EndFunction

// Create tariff subscriptions based on the payment invoice.
// 
// Parameters:
//  CreationParameters - See NewParametersForCreatingTariffSubscriptionsBasedOnPaymentInvoice
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Array of String - subscription numbers created
Function CreateTariffSubscriptionsBasedOnPaymentInvoice(CreationParameters, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/create_subscription";
	QueryData = IsInternal.QueryTemplate(Method);
	If CreationParameters.Property("AccountNumber") Then
		AccountNumber = CreationParameters.AccountNumber;
	Else
		AccountNumber = "";
	EndIf; 
	If CreationParameters.Property("InvoiceId") Then
		InvoiceId = CreationParameters.InvoiceId;
	Else
		InvoiceId = CommonClientServer.BlankUUID();
	EndIf; 
	If Not IsBlankString(AccountNumber) Then
		QueryData.Insert("id", AccountNumber);
	ElsIf TypeOf(InvoiceId) = Type("UUID") 
		And InvoiceId <> CommonClientServer.BlankUUID() Then
		QueryData.Insert("bill_id", InvoiceId);
	EndIf;
	 
	If ValueIsFilled(CreationParameters.ConnectionDate) Then
		QueryData.Insert("start", CreationParameters.ConnectionDate);
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
		
	CreatedSubscriptions = New ValueList;
	For Each Item In ResponseData.subscription Do
		CreatedSubscriptions.Add(Item.id);
	EndDo;
	
	CreatedSubscriptions.SortByValue();
	
	Return CreatedSubscriptions.UnloadValues();

EndFunction

// Creates a new email to send to the service organization 
// with information about the need to receive an invoice for payment for services.
// Implements the method of the external programming interface - bill/email_create
// 
// Parameters:
//  InvoiceRequestByEmailParameters - See NewInvoiceRequestByEmailParameters
//	RaiseExceptionAtError - Boolean - default = True
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// Returns:
//  Structure:
//   * Error - Boolean - Indicates whether there was an error when creating the message
//   * Message - String - String description of the error.	
Function CreateServicesInvoiceToPayRequestByEmail(InvoiceRequestByEmailParameters, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/email_create";
	
	InterfaceVersion = InterfaceVersionProperties().Version;

	Result = New Structure("Error,Message", False, "");
	If InterfaceVersion >= 30 Then
		
		QueryData = IsInternal.QueryTemplate(Method);
		QueryData.Insert("servant", InvoiceRequestByEmailParameters.MasterSubscriberCode);
		QueryData.Insert("account", InvoiceRequestByEmailParameters.SubscriberCode);
		QueryData.Insert("copy", InvoiceRequestByEmailParameters.SendCopyToMe);
		QueryData.Insert("comment", InvoiceRequestByEmailParameters.Comment);		
		
		CallResult = IsInternal.SendDataToServiceManager(QueryData, Method);
		ResponseData = IsInternal.ExecutionResult(CallResult, RaiseExceptionAtError, 
			BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
		
		If ResponseData.general.error Then
			Result.Error = True;
			Result.Message = ResponseData.general.message;			
		EndIf;
		 
	Else
		
		Result.Error = True;
		Result.Message = NStr("vi = 'Không hỗ trợ việc gửi thư để yêu cầu hóa đơn thanh toán 
		|trong phiên bản hiện tại của trình quản lý dịch vụ.';
		|ru = 'Отправка письма для запроса счета на оплату не поддерживается 
		|в текущей версии менеджера сервиса.';
		|en = 'Sending an email to request a proforma invoice is not supported 
		|in the current Service Manager version.'; fa = 'Sending an email to request a proforma invoice is not supported 
		|in the current Service Manager version.';
		|it = 'Sending an email to request a proforma invoice is not supported 
		|in the current Service Manager version.';
		|pl = 'Sending an email to request a proforma invoice is not supported 
		|in the current Service Manager version.';
		|tr = 'Ödeme faturası talep etmek için e-posta gönderimi, 
		|hizmet yöneticisinin mevcut sürümünde desteklenmemektedir.'");
		
	EndIf;

		
	Return Result;	
	
EndFunction

// Returns a template for selecting invoices for payment.
// 
// Returns:
//  Structure:
//   * SellerCode - Number - code of the subscriber-seller
//   * BuyerSCode - Number - subscriber code, the buyer
//   * BeginOfPeriod - Date - start date of the period
//   * EndOfPeriod - Date - period end date 
//   
Function NewSelectionOfInvoicesForPayment() Export

	SelectingInvoicesForPayment = New Structure;
	SelectingInvoicesForPayment.Insert("Seller", 0);
	SelectingInvoicesForPayment.Insert("Customer", 0);
	SelectingInvoicesForPayment.Insert("BeginOfPeriod", '00010101');
	SelectingInvoicesForPayment.Insert("EndOfPeriod", '00010101');
	
	Return SelectingInvoicesForPayment;
	
EndFunction

// Returns a template for a new payment invoice.
//
// Returns:
//  Structure:
//   * InvoiceId - UUID - account ID
//	 * SellerCode - Number - code (number) of the subscriber-seller
//	 * BuyerSCode - Number - code (number) of the subscriber-buyer
//	 * Sum - Number - invoice amount
//	 * Renewal - Boolean - sign of renewal
//	 * PaymentURL - String - the payment link
//	 * Paid - Boolean - indication of payment of the invoice
//	 * AdditionalInformation - String - additional account information
//	 * Comment - String - review of accounts
//   * ServicePlans - ValueTable - ServicePlans:
//     ** ProviderServicePlanCode - String - provider's tariff code
//     ** ServiceProviderPlanCode - String - tariff code of the service organization
//     ** ValidityPeriodCode - String - code of the tariff validity period
//     ** NumberOfBaseDocument - String - the number of subscription-base
//     ** Sum - Number - the cost of the tariff, including the validity period
//   * Services - ValueTable - Services:
//     ** OperationService - String - name of the service
//     ** Sum - Number - the cost of the service
//   * Files - ValueTable - The Presentation files of the Cur Invoice for payment:
//     ** Id - UUID - file id
//     ** LongDesc - String - name of the invoice view file
//   * AdditionalAttributes - ValueTable - additional Attributes of the account:
//     ** Key - String - name of additional account details
//     ** Type - String - value type (optional if the additional property has the same value type)
//     ** Value - String, Number, Date, Boolean - Value of additional details
Function NewInvoiceTemplate() Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	
	InvoiceData = New Structure;
	InvoiceData.Insert("InvoiceId", New TypeDescription("UUID"));
	InvoiceData.Insert("SellerCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative));
	InvoiceData.Insert("BuyerSCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative));
	InvoiceData.Insert("Sum", Common.TypeDescriptionNumber(31, 2, AllowedSign.Nonnegative));
	InvoiceData.Insert("Renewal", New TypeDescription("Boolean"));
	InvoiceData.Insert("PaymentURL", Common.StringTypeDetails(1024));
	InvoiceData.Insert("Paid", New TypeDescription("Boolean"));
	InvoiceData.Insert("AdditionalInformation", New TypeDescription("String"));
	InvoiceData.Insert("Comment", New TypeDescription("String"));
	
	InvoiceData.Insert("ServicePlans", NewPaymentInvoiceNumber());
	InvoiceData.Insert("Services", NewInvoiceNumber());
	InvoiceData.Insert("Files", NewInvoiceFile());
	InvoiceData.Insert("AdditionalAttributes", IsInternal.NewAdditionalInformation());
	
	Return InvoiceData;
	
EndFunction

// Returns a template of parameters for receiving a file download coupon.
// 
// Returns:
//  Structure:
//   * AccountNumber - String - account number (not specified if the account ID is passed)
//   * InvoiceId - UUID - account ID (not specified if the account number is passed)
//   * FileName - String - name of the file with the extension
//   * Size - String - file size in bytes.
Function NewOptionsForGettingFileUploadCoupon() Export

	Parameters = New Structure;
	Parameters.Insert("AccountNumber", "");
	Parameters.Insert("InvoiceId", CommonClientServer.BlankUUID());
	Parameters.Insert("FileName", "");
	Parameters.Insert("Size", 0);
	
	Return Parameters;

EndFunction

// Returns a template for parameters for creating tariff subscriptions based on a payment invoice.
// 
// Returns:
//  Structure:
//   * AccountNumber - String - account number (not specified if the account ID is passed)
//   * InvoiceId - UUID - account ID (not specified if the account number is passed)
//   * ConnectionDate - Date - activation date of the tariff subscriptions being created.
Function NewParametersForCreatingTariffSubscriptionsBasedOnPaymentInvoice() Export
	
	Parameters = New Structure;
	Parameters.Insert("AccountNumber", "");
	Parameters.Insert("InvoiceId", CommonClientServer.BlankUUID());
	Parameters.Insert("ConnectionDate", '00010101000000');
	
	Return Parameters;
	
EndFunction

// Returns the template of the tabular part "Tariffs" of the invoice for payment.
// 
// Returns:
//  ValueTable - New Payment Invoice Number:
// * ProviderServicePlanCode - String - length 9
// * ServiceProviderPlanCode - String - length 9
// * ValidityPeriodCode - String - Length10
// * Count - Number - bit depth 10.0
// * Sum  - Number - bit depth 31.2
// * NumberOfBaseDocument - String - the bit depth is 9.
Function NewPaymentInvoiceNumber() Export
	
 	ServicePlans = New ValueTable;
	ServicePlans.Columns.Add("ProviderServicePlanCode", Common.StringTypeDetails(9));
	ServicePlans.Columns.Add("ServiceProviderPlanCode", Common.StringTypeDetails(9));
	ServicePlans.Columns.Add("ValidityPeriodCode", Common.StringTypeDetails(10));
	ServicePlans.Columns.Add("Count", Common.TypeDescriptionNumber(10,0));
	ServicePlans.Columns.Add("Sum", Common.TypeDescriptionNumber(31,2));
	ServicePlans.Columns.Add("NumberOfBaseDocument", Common.StringTypeDetails(9));
	
	Return ServicePlans;
	
EndFunction

// Returns the template of the tabular part of the "Services" invoice for payment.
// 
// Returns:
//  ValueTable - New Invoice Number:
// * OperationService - String - Length1000
// * Sum - Number - the bit depth is 31.2.
Function NewInvoiceNumber() Export
	
	Services = New ValueTable;
	Services.Columns.Add("OperationService", Common.StringTypeDetails(1000));
	Services.Columns.Add("Sum",Common.TypeDescriptionNumber(31,2));
	
	Return Services;

EndFunction

// Returns the template of the tabular part "Files" of the invoice for payment.
// 
// Returns:
//  ValueTable - New Invoice File:
// * Id - UUID
// * LongDesc - String -length 150.
Function NewInvoiceFile() Export
	
	Files = New ValueTable;
	Files.Columns.Add("Id", New TypeDescription("UUID"));
	Files.Columns.Add("LongDesc", Common.StringTypeDetails(150));
	
	Return Files;

EndFunction

// Returns a template for parameters for creating an invoice request by email for payment for a service.
// 
// Returns:
//  Structure:
//   * MasterSubscriberCode - Number - Subscriber code of the service organization
//   * SubscriberCode - Number - The code of the subscriber who generates an email requesting an invoice for payment
//   * SendCopyToMe - Boolean - Add the subscriber's mailing address to the copy of the letter
//   * Comment - String - An arbitrary subscriber comment for the service organization.
Function NewInvoiceRequestByEmailParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("MasterSubscriberCode", 0);
	Parameters.Insert("SubscriberCode", 0);
	Parameters.Insert("SendCopyToMe", False);
	Parameters.Insert("Comment", "");
	
	Return Parameters;
EndFunction

#EndRegion

#Region Tenant

// Returns the subscriber data of this app.
//
// Parameters:
//	User - CatalogRef.Users - the user of the subscriber you want to identify. If not specified, the Cur is used.
//	Token - String - the key issued to the information security administrator for the operation.
// 
// Returns:
//  Structure - subscriber data:
//    * Description - String - the name of the caller
//    * Code - Number - subscriber code
//    * UserRole - EnumRef.SubscriberUsersRoles - the role of the current user of the subscriber.
//
Function SubscriberOfThisApplication(Val User = Undefined, Val Token = Undefined) Export
	
	Return ServiceProgrammingInterfaceCached.SubscriberOfThisApplication(User, Token);
	
EndFunction

// Returns a list of applications available to the user of the subscriber of this application. 
// 
// Parameters:
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  ValueTable - available applications:
//   * Code - Number - application code (number)
//   * Description - String - Description
//   * SubscriberOwnerCode - Number - code of the subscriber who owns the app
//   * ConfigurationCode - String - configuration code
//   * ConfigurationVersion - String - configuration version
//   * ConfigurationDescription - String - the name of the configuration
//   * AppTypeCode - String - Application Type Code
//   * AppTypeName - String - Name of the Application Type
//   * NameOfAppType - String - Name Of The Application Type
//   * ApplicationState - EnumRef.ApplicationsStates - application state
//   * ApplicationURL - String - The URL of the application
//   * UserLanguageCode - String - the user's language code in the app
//   * TimeZone - String - app time zone
//
Function Applications(RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);

	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;

	Renamings = IsInternal.RenamingApp();

	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.tenant, Renamings);

EndFunction

// Returns a list of applications available to the user of the subscriber of this application. 
// 
// Parameters:
//  SubscriberCode - Number - subscriber's code (number).
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  ValueTable - available applications:
//   * Code - Number - application code (number)
//   * Description - String - Description
//   * SubscriberOwnerCode - Number - code of the subscriber who owns the app
//   * ConfigurationCode - String - configuration code
//   * ConfigurationVersion - String - configuration version
//   * ConfigurationDescription - String - the name of the configuration
//   * AppTypeCode - String - Application Type Code
//   * AppTypeName - String - Name of the Application Type
//   * NameOfAppType - String - Name Of The Application Type
//   * ApplicationState - EnumRef.ApplicationsStates - application state
//   * ApplicationURL - String - The URL of the application
//   * UserLanguageCode - String - the user's language code in the app
//   * TimeZone - String - app time zone
//
Function SubscriberApplications(SubscriberCode, RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	AddSubscriberAuthorization(QueryData, SubscriberCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);

	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;

	Renamings = IsInternal.RenamingApp();

	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.tenant, Renamings);

EndFunction

// Returns information about the specified application.
//
// Parameters:
//  ApplicationCode - String - application code (area number).
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Structure - Application Properties:
//   * Code - Number - application code (number)
//   * Description - String- Description
//   * SubscriberOwnerCode - Number - code of the subscriber who owns the app
//   * ConfigurationCode - String - configuration code
//   * ConfigurationVersion - String - configuration version
//   * ConfigurationDescription - String - the name of the configuration
//   * AppTypeCode - String - Application Type Code
//   * AppTypeName - String - Name of the Application Type
//   * NameOfAppType - String - Name Of The Application Type
//   * ApplicationState - EnumRef.ApplicationsStates - application state
//   * ApplicationURL - String - The URL of the application
//   * UserLanguageCode - String - the user's language code in the app
//   * TimeZone - String - app time zone
//   * PlatformVersion - String - platform version
//   * ApplicationSize - Number - Application Size
//   * CalculationAppSizeDate - Date - Date The App Size Was Calculated
//
Function ApplicationProperties(ApplicationCode,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", ApplicationCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);

	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingApp();
	
	Return IsInternal.RenameProperties(ResponseData.tenant, Renamings);
	
EndFunction

// Returns a list of users who are allowed access to the specified application.
//
// Parameters:
//  ApplicationCode - Number - application code (area number)
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// 
// Returns:
//  ValueTable - users who are allowed access:
//   * Login - String - username (name) of the user
//   * Right - EnumRef.ApplicationUserRights - the user's right to the Cur application in the service manager.
//   * SetupInAppRequired - Boolean - indicates that you need to configure user rights in the application.
//
Function ApplicationUsers(ApplicationCode,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/users/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", ApplicationCode);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;

	Renamings = New Map;
	Renamings.Insert("login", IsInternal.ColumnDetails("Login", Common.StringTypeDetails(50)));
	Renamings.Insert("role", IsInternal.ColumnDetails("Right", 
		New TypeDescription("EnumRef.ApplicationUserRights")));
	Renamings.Insert("setup_required", IsInternal.ColumnDetails("SetupInAppRequired",
		New TypeDescription("Boolean")));
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.user, Renamings);
	
EndFunction

// Returns a list of users who are allowed access to the specified application.
//
// Parameters:
//  Parameters - See NewSubscriberAppUsersRequestParameters.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// 
// Returns:
//  ValueTable - users who are allowed access:
//   * Login - String - username (name) of the user
//   * Right - EnumRef.ApplicationUserRights - the user's right to the Cur application in the service manager.
//   * SetupInAppRequired - Boolean - indicates that you need to configure user rights in the application.
//
Function SubscriberAppUsers(Parameters,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/users/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", Parameters.ApplicationCode);
	If ValueIsFilled(Parameters.Login) Then
		QueryData.Insert("login", Parameters.Login);
	EndIf;
	
	AddSubscriberAuthorization(QueryData, Parameters.SubscriberCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;

	Renamings = New Map;
	Renamings.Insert("login", IsInternal.ColumnDetails("Login", Common.StringTypeDetails(50)));
	Renamings.Insert("role", IsInternal.ColumnDetails("Right", 
		New TypeDescription("EnumRef.ApplicationUserRights")));
	Renamings.Insert("setup_required", IsInternal.ColumnDetails("SetupInAppRequired",
		New TypeDescription("Boolean")));
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.user, Renamings);
	
EndFunction

// Establishes access to the specified application for the user with the specified login 
// and assigns the specified role to work in the application.
//
// Parameters:
//  AddingOptions - See NewOptionsForAddingUserToApplication
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - the result of setting the access right to the application: True - the right is set, False - an error occurred.
//
Function AddUserToApp(AddingOptions,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/users/add";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", AddingOptions.ApplicationCode);
	QueryData.Insert("login", AddingOptions.Login);
	QueryData.Insert("role", Enums.ApplicationUserRights.NameByValue(AddingOptions.Right));
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Revokes access to the specified application for the user with the specified username.
//
// Parameters:
//  Login - String - username (name) of the user.
//  ApplicationCode - Number - application code (area number)
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - the result of revoking the access right to the application: True - the right has been revoked, False - an error has occurred.
//
Function RemoveUserFromApp(Login, ApplicationCode,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/users/delete";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", ApplicationCode);
	QueryData.Insert("login", Login);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Creates a new application with the specified application configuration.
//
// Parameters:
//  CreationParameters - See NewAppCreationOptions
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Structure - the result of creating the application:
//  * Code - Number - code of the created application (area number)
//  * ApplicationState - EnumRef.ApplicationsStates - the state of the application after it is created.
//  * ApplicationURL - String - address of the created app.
//
Function CreateApp(CreationParameters,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/create";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("application", CreationParameters.ConfigurationCode);
	QueryData.Insert("name", CreationParameters.Description);
	QueryData.Insert("timezone", CreationParameters.TimeZone);
	
	If CreationParameters.SetAppPermissions Then
		
		AppPermissions = New Array;
		For Each String In CreationParameters.AppPermissions Do
			
			AppPermission = New Structure;
			AppPermission.Insert("login", String.Login);
			AppPermission.Insert("role", Enums.ApplicationUserRights.NameByValue(String.Right));
			
			AppPermissions.Add(AppPermission);
			
		EndDo;
		
		QueryData.Insert("users", AppPermissions);
		
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);

	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails("Code", Common.TypeDescriptionNumber(7, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("status", IsInternal.ColumnDetails("ApplicationState", New TypeDescription("EnumRef.ApplicationsStates")));
	Renamings.Insert("url", IsInternal.ColumnDetails("ApplicationURL", Common.StringTypeDetails(500)));
	
	If BasicResponseProperties.ResponseCode = 10200 Or BasicResponseProperties.ResponseCode = 10202 Then
		Result = Common.CopyRecursive(ResponseData.tenant);
		Result = IsInternal.RenameProperties(Result, Renamings);
	Else
		Result = New Structure;
		Result.Insert("Code", 0);
		Result.Insert("ApplicationState", Enums.ApplicationsStates.EmptyRef());
		Result.Insert("ApplicationURL", "");
	EndIf;
	
	Return Result;
	
EndFunction

// Updates the application properties.
// Implements the method of the external program interface - tenant/update.
//
// Parameters:
//  Parameters - See NewAppUpdateParameters
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Structure - the result of creating the application:
//  * Code - Number - code of the created application (area number)
//  * ApplicationState - EnumRef.ApplicationsStates - the state of the application after it is created.
//  * ApplicationURL - String - address of the created app.
//
Function UpdateApp(Parameters,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/update";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", Parameters.ApplicationCode);
	If Not IsBlankString(Parameters.Description) Then
		QueryData.Insert("name", Parameters.Description);
	EndIf;
	
	If Not IsBlankString(Parameters.TimeZone) Then
		QueryData.Insert("timezone", Parameters.TimeZone);
	EndIf;
	
	If ValueIsFilled(Parameters.Users) Then
		ApplicationUsers = New Array;
		For Each String In Parameters.Users Do
			
			ApplicationUser = New Structure;
			ApplicationUser.Insert("login", String.Login);
			ApplicationUser.Insert("role", Enums.ApplicationUserRights.NameByValue(String.Right));
			
			ApplicationUsers.Add(ApplicationUser);
			
		EndDo;
		
		QueryData.Insert("users", ApplicationUsers);
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Creates a new application from the specified upload file.
//
// Parameters:
//  CreationParameters - See NewCreatingAppFromFileParameters
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Structure - the result of creating the application:
//  * Code - Number - code of the created application (area number)
//  * ApplicationState - EnumRef.ApplicationsStates - the state of the application after it is created.
//  * ApplicationURL - String - address of the created app.
//
Function CreateAppFromExportFile(CreationParameters,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/create_from_data_dump";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("file_id", CreationParameters.FileID);
	QueryData.Insert("name", CreationParameters.Description);
	QueryData.Insert("timezone", CreationParameters.TimeZone);
	
	UsersList = New Array;
	For Each String In CreationParameters.Users Do
		
		User = New Structure;
		User.Insert("login", String.Login);
		User.Insert("role", Enums.ApplicationUserRights.NameByValue(String.Right));
		User.Insert("user_id", String.UserIdentificator);
		
		UsersList.Add(User);
		
	EndDo;
	QueryData.Insert("users", UsersList);
	
	ExtensionsList = New Array;
	For Each String In CreationParameters.Extensions Do
		
		Extension = New Structure;
		Extension.Insert("version_uuid", String.UUID);
		Extension.Insert("id", String.Name);
		Extension.Insert("restore_frame", String.RestoreWireframeVersion);
		
		ExtensionsList.Add(Extension);
		
	EndDo;
	QueryData.Insert("extensions", ExtensionsList);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);

	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails("Code", Common.TypeDescriptionNumber(7, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("status", IsInternal.ColumnDetails("ApplicationState", New TypeDescription("EnumRef.ApplicationsStates")));
	Renamings.Insert("url", IsInternal.ColumnDetails("ApplicationURL", Common.StringTypeDetails(500)));
	
	If (BasicResponseProperties.ResponseCode = 10200 Or BasicResponseProperties.ResponseCode = 10202)
		And ResponseData.Property("tenant") Then
		
		Result = Common.CopyRecursive(ResponseData.tenant);
		Result = IsInternal.RenameProperties(Result, Renamings);
	Else
		Result = New Structure;
		Result.Insert("Code", 0);
		Result.Insert("ApplicationState", Enums.ApplicationsStates.EmptyRef());
		Result.Insert("ApplicationURL", "");
	EndIf;
	
	Return Result;
	
EndFunction

// Gets the name for the new app.
//
// Parameters:
//  AppTypeCode - String - application type code of the new application.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  String - the name to install the new application.
//
Function NewAppName(AppTypeCode,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/new_name";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("apptype_id", AppTypeCode);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Return ResponseData.name;
	
EndFunction

// Sets a new app name.
//
// Parameters:
//  ChangeParameters - See NewAppTypeInstallationOptions
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - the result of setting the app name: True - the name is set, False - an error occurred.
//
Function SetApplicationDescription(ChangeParameters,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/set_name";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", ChangeParameters.ApplicationCode);
	QueryData.Insert("name", ChangeParameters.ApplicationName_2);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Sets a new time zone for the app.
//
// Parameters:
//  ChangeParameters - See NewApplicationTimeZoneParameters
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - the result of setting the time zone for the application: True - set, False - an error occurred.
//
Function SetAppTimeZone(ChangeParameters,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/set_timezone";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", ChangeParameters.ApplicationCode);
	QueryData.Insert("timezone", ChangeParameters.TimeZone);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns a list of application backups.
// Implements the method of the external programming interface - tenant/backup/list.
//
// Returns:
//  ValueTable - list of backups:
//   * BackupIdentificator - String - backup ID, length - 36
//   * BackupTimestamp - Date - the time when the backup was created, the datetime
//   * ForTechSupport - Boolean - whether to create a backup for technical support
//
Function ListOfApplicationBackups() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/backup/list";
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SaaSOperations.SessionSeparatorValue());
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result);

	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingApplicationBackups();
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.backup, Renamings);
	
EndFunction

// Returns a list of application backups.
// Implements the method of the external programming interface - tenant/backup/list.
//
// Parameters:
//  Parameters - See NewGettingSubscriberAppBackupsListParameters
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  ValueTable - list of backups:
//   * BackupIdentificator - String - backup ID, length - 36
//   * AreaNumber - Number
//   * AreaDescription - String
//   * Size - Number - File size
//   * ConfigurationVersion - String
//   * AppTypeName - String
//   * Original - Boolean
//   * CreationDateUTC - Date - date of creation in universal time
//   * OnDemand - Boolean
//   * Annual - Boolean
//   * Monthly_ - Boolean
//   * Daily_ - Boolean
//   * Comment - String
//   * TimeZone - String
//
Function SubscriberAppBackupsList(Parameters,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/backup/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	AddSubscriberAuthorization(QueryData, Parameters.SubscriberCode);
	QueryData.Insert("id", Parameters.ApplicationCode);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingsBackups();
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.backup, Renamings);
	
EndFunction

// Returns a template for application creation parameters for the Programinterface service method.Create an app.
// 
// Returns:
//  Structure - template for app creation parameters:
//   * Description - String - name of the application being created.
//   * ConfigurationCode - String - configuration code (application view)
//   * TimeZone - String - the app's working time zone
//   * SetAppPermissions - Boolean - the need to set rights to applications.
//   * AppPermissions - ValueTable - installable rights to applications:
//     ** Login - String - login (user name)
//     ** Right - EnumRef.ApplicationUserRights - the user role to install.
Function NewAppCreationOptions() Export
	
	Parameters = New Structure;
	Parameters.Insert("Description", "");
	Parameters.Insert("ConfigurationCode", "");
	Parameters.Insert("TimeZone", "");
	
	Parameters.Insert("SetAppPermissions", False);
	AppPermissions = New ValueTable;
	AppPermissions.Columns.Add("Login", Common.StringTypeDetails(0));
	AppPermissions.Columns.Add("Right", New TypeDescription("EnumRef.ApplicationUserRights"));
	Parameters.Insert("AppPermissions", AppPermissions);
	
	Return Parameters;
	
EndFunction

// Returns a template for application update parameters for the Software Interface Service method.Update the app.
// 
// Returns:
//  Structure - template for app creation parameters:
//   * ApplicationCode - Number - the code of the updated application.
//   * Description - String - Name of the application.
//   * TimeZone - String - the app's working time zone
//   * Users - ValueTable - installable rights to applications:
//     ** Login - String - login (user name)
//     ** Right - EnumRef.ApplicationUserRights - the user role to install.
Function NewAppUpdateParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("ApplicationCode", 0);
	Parameters.Insert("Description", "");
	Parameters.Insert("TimeZone", "");
	ApplicationUsers = New ValueTable;
	ApplicationUsers.Columns.Add("Login", Common.StringTypeDetails(0));
	ApplicationUsers.Columns.Add("Right", New TypeDescription("EnumRef.ApplicationUserRights"));
	Parameters.Insert("Users", ApplicationUsers);
	
	Return Parameters;
	
EndFunction

// Returns the template for the application creation parameters for the Software Interface Service method.Create an attachment from the Upload file.
// 
// Returns:
//  Structure - template for app creation parameters:
//   * FileID - String - configuration code (application view)
//   * Description - String - name of the application being created.
//   * TimeZone - String - the app's working time zone
//   * Users - ValueTable - users for matching:
//     ** Login - String - login (user name).
//     ** Right - EnumRef.ApplicationUserRights - the user role to install.
//     ** UserIdentificator - UUID - user ID from the data file.
Function NewCreatingAppFromFileParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("FileID", "");
	Parameters.Insert("Description", "");
	Parameters.Insert("TimeZone", "");
	
	UsersList = New ValueTable;
	UsersList.Columns.Add("Login", Common.StringTypeDetails(0));
	UsersList.Columns.Add("Right", New TypeDescription("EnumRef.ApplicationUserRights"));
	UsersList.Columns.Add("UserIdentificator",
		New TypeDescription("UUID"));
	Parameters.Insert("Users", UsersList);
	
	ExtensionsList = New ValueTable;
	ExtensionsList.Columns.Add("UUID", New TypeDescription("UUID"));
	ExtensionsList.Columns.Add("Name", Common.StringTypeDetails(0));
	ExtensionsList.Columns.Add("RestoreWireframeVersion", New TypeDescription("Boolean"));
	Parameters.Insert("Extensions", ExtensionsList);
	
	Return Parameters;
	
EndFunction

// Returns the template of the parameters for adding a user to the application for the method
// The software interface of the service.Add a UserApplication.
// 
// Returns:
//  Structure - template for parameters for adding a user to an application:
//	 * ApplicationCode - Number - application number.
//	 * Login - String - login (user name) 
//   * Right - EnumRef.ApplicationUserRights - user's right to the app in the service Manager 
//
Function NewOptionsForAddingUserToApplication() Export
	
	Parameters = New Structure;
	Parameters.Insert("ApplicationCode", 0);
	Parameters.Insert("Login", "");
	Parameters.Insert("Right", Enums.ApplicationUserRights.EmptyRef());
	
	Return Parameters;
	
EndFunction

// Returns a template for parameters for changing the name of the application for the method
// The service's software interface.Set the App names.
// 
// Returns:
//  Structure - template for parameters for adding a user to an application:
//   * ApplicationCode - Number - application code (area number)
//   * ApplicationName_2 - String - new app name
//
Function NewAppTypeInstallationOptions() Export
	
	Parameters = New Structure;
	Parameters.Insert("ApplicationCode", 0);
	Parameters.Insert("ApplicationName_2", "");
	
	Return Parameters;
	
EndFunction

// Returns a template for parameters for changing the application name for the method
// The service's software interface.Set the hourly application.
// 
// Returns:
//  Structure - template for parameters for adding a user to an application:
//   * ApplicationCode - Number - application code (area number)
//   * TimeZone - String - set time zone
//
Function NewApplicationTimeZoneParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("ApplicationCode", 0);
	Parameters.Insert("TimeZone", "");
	
	Return Parameters;
	
EndFunction

// Returns the parameter template for the method
// The service's software interface.UserApplication of the component.
// 
// Returns:
//  Structure - template for parameters for adding a user to an application:
//   * SubscriberCode - Number - subscriber code
//   * ApplicationCode - Number - application code (area number)
//   * Login - String - filter by user login
//
Function NewSubscriberAppUsersRequestParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("SubscriberCode", 0);
	Parameters.Insert("ApplicationCode", 0);
	Parameters.Insert("Login", "");
	
	Return Parameters;
	
EndFunction

// Returns the parameter template for the method
// The service's software interface.List of reserved copies of the Subscriber's application.
// 
// Returns:
//  Structure - template for app creation parameters:
//   * SubscriberCode - Number - subscriber code
//   * ApplicationCode - Number - application code (area number)
Function NewGettingSubscriberAppBackupsListParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("SubscriberCode", 0);
	Parameters.Insert("ApplicationCode", 0);
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Tariff

// Returns information about the service rate by the rate code.
//
// Parameters:
//  ServicePlanCode - String - fare code.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Structure - tariff information:
//   * Code - String - fare code
//   * Description - String - name of the tariff
//   * DescriptionForServiceOrganizations - String - description of the tariff for the service organization.
//   * DescriptionForSubscribers - FormattedDocument - description of the tariff for subscribers.
//   * ValidityStartDate - Date - start date of the tariff.
//   * ValidityEndDate - Date - expiration date of the tariff.
//   * ProlongationSubscriptionPeriod - Number - the period (in days) during which the renewing subscription is valid (if renewal is allowed).
//   * ExtensionSubscriptionPeriod - Number - the period (in days) during which the extension subscription is valid.
//   * PeriodForAddingRenewingSubscription - Number - the period (in days) after the subscription expires during which you can create a renewal subscription.
//   * TariffExpansion - Boolean - indicates that the tariff is an extension
//   * TariffType - EnumRef.TariffTypes - Fare Type
//   * Paid - Boolean - indicates that the tariff is paid (contains paid validity periods)
//   * Test_ - Boolean - indicates that the tariff is a test one
//   * ThereIsCondition - Boolean - indicates that the use of the tariff requires compliance with the terms of use.
//   * PeriodicPayment - Boolean - indicates that the tariff uses periodic payment
//   * FrequencyOfPayment - String - code of the payment frequency period
//   * Services - ValueTable - tariff services:
//     ** Code - String - service code
//     ** Description - String - name of the service
//     ** ServiceType - EnumRef.ServicesTypes - type of service
//     ** LongDesc - String - Service description
//     ** LicensesCount - Number - number of service licenses included in the tariff
//     ** NumberOfAdditionalLicensesForExpandingSubscription - Number - the number of service licenses that can be provided by an extension subscription
//     ** VendorID - String - ID of the service provider
//     ** SupplierName - String - name of the service provider
//   * Extensions - ValueTable - tariff extensions:
//     ** Code - String - extension rate code
//     ** Description - String - name of the extension rate
//   * Configurations - ValueTable - tariff configurations:
//     ** Code - String - configuration code
//     ** Description - String - configuration name
//     ** LongDesc - String - the description of the configuration
//   * ActionPeriods - ValueTable - tariff validity periods:
//     ** Code - String - validity period code
//     ** Description - String - name of the validity period
//     ** Sum - Number - Cost
//     ** Comment - String - comment on the validity period
//   * SubscriptionTerminationNotificationPeriods - ValueTable - periods of notifications about the end of subscription to the tariff:
//     ** DaysCount - Number - the number of days to notify the user.
//
Function ServiceRate(ServicePlanCode, RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	BasicResponseProperties.StatusCode = 200;
	
	Try
		Result = ServiceProgrammingInterfaceCached.ServiceRate(ServicePlanCode);
		BasicResponseProperties.ResponseCode = 10200;
	Except
		If RaiseExceptionAtError Then
			Raise;
		Else
			Result = Undefined;
			BasicResponseProperties.ResponseCode = 10404;
			BasicResponseProperties.Message = CloudTechnology.ShortErrorText(ErrorInfo());
		EndIf; 
	EndTry;
	
	Return Result;
	
EndFunction

// Returns a list of service rates available to the subscriber of this app.
// Parameters:
//  Filter - See NewTariffsListFilter
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  ValueTable - list of service rates:
//   * Code - String - fare code
//   * Description - String - name of the tariff
//   * DescriptionForServiceOrganizations - String - description of the tariff for the service organization.
//   * DescriptionForSubscribers - FormattedDocument - description of the tariff for subscribers.
//   * ValidityStartDate - Date - start date of the tariff.
//   * ValidityEndDate - Date - expiration date of the tariff.
//   * ProlongationSubscriptionPeriod - Number - the period (in days) during which the renewing subscription is valid (if renewal is allowed).
//   * ExtensionSubscriptionPeriod - Number - the period (in days) during which the extension subscription is valid.
//   * PeriodForAddingRenewingSubscription - Number - the period (in days) after the subscription expires during which you can create a renewal subscription.
//   * TariffExpansion - Boolean - indicates that the tariff is an extension
//   * TariffType - EnumRef.TariffTypes - Fare Type
//   * Paid - Boolean - indicates that the tariff is paid (contains paid validity periods)
//   * Test_ - Boolean - indicates that the tariff is a test one
//   * ThereIsCondition - Boolean - indicates that the use of the tariff requires compliance with the terms of use.
//   * PeriodicPayment - Boolean - indicates that the tariff uses periodic payment
//   * FrequencyOfPayment - String - code of the payment frequency period
//   * ActionPeriods - ValueTable - periods of validity. Is filled in if the parameter for receiving the parameterreception period is passed:
//     ** Code - String - validity period code
//     ** Description - String - name of the validity period
//     ** Sum - Number - Cost
//     ** Comment - String - comment on the validity period
//
Function ServiceRates(Filter = Undefined, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tariff/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	If Filter = Undefined Then
		Filter = NewTariffsListFilter();
	EndIf; 
	
	QueryData = IsInternal.QueryTemplate(Method);
	InterfaceVersion = InterfaceVersionProperties().Version;
	
	ValidityPeriodsField = "validity_periods";
	TariffField = "tariff";
		
	If Not IsBlankString(Filter.Description) Then
		QueryData.Insert("name", Filter.Description);
	EndIf;
	If InterfaceVersion >= 23 And Filter.AvailableServicePlans.Count() > 0 Then
		QueryData.Insert("available_tariffs", Filter.AvailableServicePlans);
	EndIf;
		
	If InterfaceVersion >= 19 Then
		If Filter.ReceivingParameters.Count() > 0 Then
			QueryData.Insert("scope", New Array);
			For Each String In Filter.ReceivingParameters Do
				If String = ParameterForGettingExtensionsOnly() And InterfaceVersion < 23 Then
					Continue;
				Else
					QueryData["scope"].Add(String);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
		
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	If InterfaceVersion >= 19 And Not Filter.ReceivingParameters.Find(ParameterForGettingValidityPeriods()) = Undefined Then
		RenamingValidityPeriods = IsInternal.RenamesAndValidityPeriods();
		For Each Item In ResponseData[TariffField] Do
			Item[ValidityPeriodsField] = IsInternal.StructuresArrayIntoValueTable(
				Item[ValidityPeriodsField], RenamingValidityPeriods);
		EndDo; 
	EndIf;
	
	Renamings = IsInternal.RenamingRates();
	Result = IsInternal.StructuresArrayIntoValueTable(ResponseData[TariffField], Renamings);
	
	Return Result;
	
EndFunction

// Returns a template for selecting the provider's tariff list.
// 
// Returns:
//  Structure:
//    * Description - String - selection by part of the name
//    * AvailableServicePlans - Array of String - selection of tariffs by codes of available tariffs
//    * ReceivingParameters - Array of String - it can contain parameters for getting data returned by methods
//     - See ParameterForGettingValidityPeriods
//     - See ParameterForGettingPaidOnly
//     - See ParameterForGettingExtensionsOnly
Function NewTariffsListFilter() Export
	
	Filter = New Structure;
	Filter.Insert("Description", "");
	Filter.Insert("ReceivingParameters", New Array);
	Filter.Insert("AvailableServicePlans", New Array);
	
	Return Filter;
	
EndFunction

// Returns a template for selecting the list of tariffs of the service organization.
// 
// Returns:
//  Structure:
//    * ServiceProviderCode - String - code of the service organization
//    * AvailableServicePlans - Array of String - selection of tariffs by codes of available tariffs
//    * ReceivingParameters - Array of String - it can contain parameters for getting data returned by methods
//     - See ParameterForGettingValidityPeriods
//     - See ParameterForGettingExtensionsOnly
Function NewSelectionOfSupportCompanyTariffsList() Export
	
	Filter = New Structure;
	Filter.Insert("ServiceProviderCode", "");
	Filter.Insert("ReceivingParameters", New Array);
	Filter.Insert("AvailableServicePlans", New Array);
	
	Return Filter;
	
EndFunction
	
// Returns the "Validity Periods" tariff receipt parameter
// 
// Returns:
//  String 
//
Function ParameterForGettingValidityPeriods() Export
	
	Return "validity_periods";
	
EndFunction

// Returns the "Paid only" tariff receipt parameter
// 
// Returns:
//  String 
Function ParameterForGettingPaidOnly() Export
	
	Return "is_payable";
	
EndFunction

// Returns the parameter for getting "Extensions only" tariffs
// 
// Returns:
//  String 
Function ParameterForGettingExtensionsOnly() Export
	
	Return "is_extension";
	
EndFunction

#EndRegion

#Region Subscription

// Returns a list of existing subscriptions for the current app subscriber.
//
// Parameters:
//  Filter - See NewPricingPlanSubscriptionSelection
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  ValueTable - existing subscriber subscriptions:
//   * SubscriberCode - Number - code (number) of the subscriber
//   * Number - String - subscription number
//   * Date - Date - registration date of the subscription
//   * SubscriptionType - EnumRef.ServiceSubscriptionsTypes - subscription type
//   * ServiceProviderCode - Number - code (number) of the subscriber of the service organization
//   * ConnectionDate - Date - subscription rate activation date
//   * DateOfExpiration - Date - date when the tariff was disabled
//   * ServicePlanCode - String - subscription rate code
//   * ServiceProviderPlanCode - String - tariff code of the service organization
//   * ValidityPeriodCode - String - validity period code
//   * Count - Number - the number of tariffs in the subscription
//   * PrimarySubscriptionNumber - String - number of the main subscription, if the current subscription to the plan is an extension.
//   * InvoiceNum - String - Invoice Number For Payment
//   * PaymentInvoiceID - UUID - ID of the payment invoice
//
Function SubscriberSubscriptions(Filter = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "subscription/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	SubscriberCode = SubscriberCode();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode);
	
	If TypeOf(Filter) = Type("Structure") Then
		FilterFields = New Map;
		FilterFields.Insert("ActiveOnly", "active");
		FilterFields.Insert("MainOnly", "basic");
		FilterFields.Insert("BeginOfPeriod", "start_date");
		FilterFields.Insert("EndOfPeriod", "end_date");
		For Each Item In FilterFields Do
			If Filter.Property(Item.Key) And ValueIsFilled(Filter[Item.Key]) Then
				QueryData.Insert(Item.Value, Filter[Item.Key]);
			EndIf; 
		EndDo;
	Else
		Filter = NewPricingPlanSubscriptionSelection();
	EndIf; 
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingSubscriptionPlan(False);
	Result = IsInternal.StructuresArrayIntoValueTable(ResponseData.subscription, Renamings);
	
	InterfaceVersion = InterfaceVersionProperties().Version;
	
	FiltersEnabled = (Filter.MainOnly Or Filter.ActiveOnly 
						Or ValueIsFilled(Filter.BeginOfPeriod) Or ValueIsFilled(Filter.EndOfPeriod));
						 
	SessionDate = CurrentSessionDate();
	For IndexOf = 1 To Result.Count() Do
		String = Result[Result.Count() - IndexOf];
		If InterfaceVersion < 14 And FiltersEnabled Then // Backward compatibility
			If (Filter.MainOnly And Not IsBlankString(String.PrimarySubscriptionNumber))
			 Or (Filter.ActiveOnly And String.DateOfExpiration < SessionDate) 
			 Or (ValueIsFilled(Filter.BeginOfPeriod) And String.Date < Filter.BeginOfPeriod) 
			 Or (ValueIsFilled(Filter.EndOfPeriod) And String.Date > Filter.EndOfPeriod) Then
				Result.Delete(String);
				Continue;
			EndIf;
		EndIf;
		If String.Count = 0 Then
			String.Count = 1;
		EndIf; 
	EndDo;
	
	Return Result;
	
EndFunction

// Extends the subscription of the subscriber of the Cur application.
//
// Parameters:
//  SubscriptionNumber - String - the number of the main subscription.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Structure - properties of the subscriber's expanding subscription:
//   * Number - String - subscription number
//
Function ExpandSubscriberSubscription(SubscriptionNumber,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "subscription/extend";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	SubscriberCode = SubscriberCode();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode);
	QueryData.Insert("id", SubscriptionNumber);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails(
		"Number", Common.StringTypeDetails(9)));
	Result = IsInternal.RenameProperties(ResponseData, Renamings);
	
	Return Result;
	
EndFunction

// Extends the subscription of the subscriber of the Cur application.
//
// Parameters:
//  SubscriptionNumber - String - the number of the main subscription.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Structure - properties of the subscriber's renewing subscription:
//   * Number - String - subscription number
//
Function RenewSubscriberSubscription(SubscriptionNumber,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "subscription/prolong";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	SubscriberCode = SubscriberCode();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode);
	QueryData.Insert("id", SubscriptionNumber);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails(
		"Number", Common.StringTypeDetails(9)));
	Result = IsInternal.RenameProperties(ResponseData, Renamings);
	
	Return Result;
	
EndFunction

// Returns a template for selecting subscriptions to the tariffs of the subscribers served.
// 
// Returns:
//  Structure:
//   * ServicedSubscriberCode - Number - code (number) of the served subscriber 
//										   (not used if called for the subscription method of the subscriber)
//   * ActiveOnly - Boolean - getting only active subscriptions
//   * MainOnly - Boolean - getting only basic subscriptions
//   * BeginOfPeriod - Date - start date of the period
//   * EndOfPeriod - Date - period end date
Function NewPricingPlanSubscriptionSelection() Export
	
	Filter = New Structure;
	Filter.Insert("ServicedSubscriberCode", 0);
	Filter.Insert("ActiveOnly", False);
	Filter.Insert("MainOnly", False);
	Filter.Insert("BeginOfPeriod", '00010101');
	Filter.Insert("EndOfPeriod", '00010101');
	
	Return Filter;
	
EndFunction

#EndRegion

#Region PromoCode

// Activates the specified promo code for the subscriber of the current app.
//
// Parameters:
//  PromoCode - String - the promo code used.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - the result of use: True - the promo code is activated, False - an error has occurred.
//
Function UsePromoCode(PromoCode,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "promo_code/activate";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	SubscriberCode = SubscriberCode();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode);
	QueryData.Insert("code", PromoCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Activates the specified promo code for the subscriber of the current app.
//
// Parameters:
//  PromoCode - String - the promo code used.
//  Label - String - additional information about the promo code
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - the result of use: True - the promo code is activated, False - an error has occurred.
//
Function UsePromoCodeWithTag(PromoCode, Label, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "promo_code/activate";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	SubscriberCode = SubscriberCode();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode);
	QueryData.Insert("code", PromoCode);
	QueryData.Insert("subid", Label);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;

EndFunction

#EndRegion

#Region Sessions

// Sends a request to prepare a list of user sessions in applications.
//
// Parameters:
//  QueryID - String - unique identifier of the request to get a list of sessions (UUID).
//  AppCodes - Array of Number - application codes for selection.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Boolean - True - a sign of successful execution, False - an error has occurred.
Function PrepareSessionsList(QueryID, AppCodes = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "session/prepare_list";
	InterfaceVersion = InterfaceVersionProperties().Version;
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode());
	
	If InterfaceVersion >= 27 Then
		QueryData.Insert("request_id", QueryID);
	EndIf;
	
	If InterfaceVersion >= 27 And AppCodes <> Undefined Then
		QueryData.Insert("tenants", AppCodes);
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10202 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Checks the availability of the list of user sessions in the applications requested earlier.
//
// Parameters:
//  QueryID - String - unique identifier of the request to get a list of sessions (UUID)
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  Boolean - True - the list is prepared, False - the list is being prepared or an error has occurred.
Function CheckSessionsList(QueryID,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "session/check_list";
	InterfaceVersion = InterfaceVersionProperties().Version;
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode());
	
	If InterfaceVersion >= 27 Then
		QueryData.Insert("request_id", QueryID);
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);

	Return ResponseData.ready;
	
EndFunction

// Retrieves the previously requested list of user sessions in applications.
//
// Parameters:
//  QueryID - String - unique identifier of the request to get a list of sessions (UUID)
//  AppCodes - Array of Number - application codes for selection.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  ValueTable - list of sessions:
//   * AreaNumber - Number
//   * AreaDescription - String
//   * UserName - String
//   * SessionStarted - Date
//   * SessionNumber - Date
//   * ApplicationName - String
//   * Sleep - Boolean
//   * IPAddress - String
Function ReadSessions(QueryID, AppCodes = Undefined, RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "session/list";
	InterfaceVersion = InterfaceVersionProperties().Version;
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode());
	
	If InterfaceVersion >= 27 Then
		QueryData.Insert("request_id", QueryID);
	EndIf;
	
	If InterfaceVersion >= 27 And AppCodes <> Undefined Then
		QueryData.Insert("tenants", AppCodes);
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Or BasicResponseProperties.ResponseCode = 10202 Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingsSession();
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.session, Renamings);
	
EndFunction

// Performs reading sessions in the background using the methods Prepare Sessions, check sessions and read sessions.
// The method must be called in the background job.
//
// Parameters:
//  QueryID - String - unique identifier of the request to get a list of sessions (UUID)
//  AppCodes - Array of Number - application codes for selection.
//  Timeout - Number - timeout waiting for the list of sessions to be prepared.
//  Calling an exception to an error is a Boolean flag indicating that an exception is raised if data is received incorrectly.
//  The main property of the response is the structure - the returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  ValueTable - list of sessions:
//   * AreaNumber - Number
//   * AreaDescription - String
//   * UserName - String
//   * SessionStarted - Date
//   * SessionNumber - Date
//   * ApplicationName - String
//   * Sleep - Boolean
//   * IPAddress - String
Function ReadSessionsInBackground(QueryID, AppCodes = Undefined, Timeout = 120) Export
	
	If GetCurrentInfoBaseSession().GetBackgroundJob() = Undefined Then
		Raise NStr("vi = 'Có thể gọi phương thức chỉ trong nhiệm vụ nền.';
					|ru = 'Метода можно вызывать только в фоновом задании.';
					|en = 'You can call the method only in a background job.'; fa = 'You can call the method only in a background job.';
					|it = 'You can call the method only in a background job.';
					|pl = 'You can call the method only in a background job.';
					|tr = 'Yöntem sadece bir arka plan işinde çağrılabilir.'");
	EndIf;
	
	PrepareSessionsList(QueryID, AppCodes);
	
	CompletedOn = CurrentSessionDate() + Timeout;
	While True Do
		
		If CheckSessionsList(QueryID) Then
			Return ReadSessions(QueryID);
		ElsIf CurrentSessionDate() > CompletedOn Then
			Return Undefined;
		Else
			CommonCTL.Pause(1);
		EndIf;
		
	EndDo;
	
EndFunction

// Performs the termination of user sessions.
// 
// Parameters:
// 	ApplicationCode -  Number - the application where you need to end sessions
// 	SessionsNumbers - Array of Number - the numbers of the sessions that you want to terminate.
// 	User - CatalogRef.Users - the user of the subscriber
// 	on whose behalf the operation is performed or the ID of the information security administrator.
// 	Token - String - the secret key used to perform the operation on behalf of the information security administrator
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
Procedure EndSessions(Val ApplicationCode, Val SessionsNumbers,
	Val User = Undefined, Val Token = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "session/terminate";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Address = IsInternal.ExecutionAddressOfExternalSoftwareInterface(Method);
	
	If Not ValueIsFilled(ApplicationCode) Then
		ApplicationCode = SaaSOperations.SessionSeparatorValue();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode());
	QueryData.Insert("tenant", ApplicationCode);
	QueryData.Insert("user", "DummyUser");
	QueryData.Insert("id", SessionsNumbers);
	QueryData.Insert("auth", IsInternal.AuthorizationProperties(SubscriberCode(), User, Token));
	
	If SaaSOperations.AccessTokenAuthenticationOfInternalAPIRequests()
		And Token = Undefined Then
		AccessToken = ValidAccessToken(User);
		Result = ServiceProgrammingInterfaceInternal.SendRequestToServiceManagerByAccessToken(
			"POST", Address, AccessToken, QueryData);
	Else
		Result = SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);
	EndIf;
	
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
EndProcedure

#EndRegion

#Region Task

// Retrieves the list of active user tasks from the MS related to the Cur user area
// 
// Parameters:
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//   
// Returns:
//  ValueTable:
//	* TaskNumber - String - issue number
//	* TaskDescription - String - issue number
Function Tasks(RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "task/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingUserTask();
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.task, Renamings);
	
EndFunction

// Returns the description of the user's task.
// 
// Parameters:
//  TaskNumber - String - the number of the task to get the data for.
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Structure:
//   * type - String - task type
//   * author - String - the author of the problem
//   * description - String - task description
//   * tenant - String - Name of the application
//   * subscriber - String - Name of the lead subscriber (Subscriber of the OO or LC)
//   * backup_type - String - type of requested backup (For those.support or not)
Function TaskProperties(TaskNumber,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "task/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", TaskNumber);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Return ResponseData.task;

EndFunction

// User task completion, rejection, or approval.
//
// Parameters:
//  QueryOptions - See NewTaskConfirmationParameters
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Boolean - the result of the task: True - the task is completed, False - an error occurred.
Function ExecuteTask(QueryOptions,
		RaiseExceptionAtError = True,  BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "task/execute";

	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("result", QueryOptions.ConsentObtained);
	QueryData.Insert("id", QueryOptions.TaskNumber);
	QueryData.Insert("date_access", QueryOptions.AccessExpirationDate);
	QueryData.Insert("backup_id", QueryOptions.CopyID);
	QueryData.Insert("backup_existing", QueryOptions.ExistingCopy);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns a template for issue confirmation parameters.
//
// Returns:
//  Structure:
//   * ConsentObtained - Boolean - a sign of obtaining consent to grant access.
//   * TaskNumber - String - the number of the confirmed task.
//   * AccessExpirationDate - Date - date of termination of access to the copy.
//   * CopyID - String - id of the existing copy
//   * ExistingCopy - Boolean - indicates whether an existing copy is being used.
Function NewTaskConfirmationParameters() Export

	Parameters = New Structure;
	Parameters.Insert("ConsentObtained", False);
	Parameters.Insert("TaskNumber", "");
	Parameters.Insert("AccessExpirationDate");
	Parameters.Insert("CopyID");
	Parameters.Insert("ExistingCopy");

	Return Parameters;

EndFunction

#EndRegion

#Region Extension

// Gets a list of extensions to match.
//
// Parameters:
//  QueryOptions - See NewExtensionForMatchingRequestParameters
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//
// Returns:
//  ValueTable:
//   * Name - String - Extension name
//   * ExternalID - String - ID in the external system
//   * Owner - Number - Owner's Subscriber Code
//   * Description - String - Name of the Extension
//   * Version - String - Extension Version
//   * ModifiesDataStructure - Boolean - The extension extends the data
//
Function ExtensionsForMatching(QueryOptions,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "extension/list_for_compare";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	If Not IsBlankString(QueryOptions.ConfigurationName) Then
		QueryData.Insert("sysname", QueryOptions.ConfigurationName);
	EndIf;
	
	If Not IsBlankString(QueryOptions.AppTypeCode) Then
		QueryData.Insert("apptype_id", QueryOptions.AppTypeCode);
	EndIf;
	
	QueryData.Insert("sysversion", QueryOptions.ConfigurationVersion);
	QueryData.Insert("account", SubscriberCode());
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);

	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails("Name", Common.StringTypeDetails(260)));
	Renamings.Insert("ext_system_id", IsInternal.ColumnDetails("ExternalID", Common.StringTypeDetails(150)));
	Renamings.Insert("owner", IsInternal.ColumnDetails("Owner", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("description", IsInternal.ColumnDetails("Description", Common.StringTypeDetails(100)));
	Renamings.Insert("version", IsInternal.ColumnDetails("Version", Common.StringTypeDetails(18)));
	Renamings.Insert("changes_data_structure", IsInternal.ColumnDetails("ModifiesDataStructure", New TypeDescription("Boolean")));
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.extension, Renamings);
	
EndFunction

// Returns the parameter template for the Interface Service method.Extensions for Comparison.
// 
// Returns:
//  Structure:
//   * ConfigurationName - String - The name of the configuration as it is specified in the configurator
//   * AppTypeCode - String - Application Type Code
//   * ConfigurationVersion - String - configuration version
//
Function NewExtensionForMatchingRequestParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("ConfigurationName", "");
	Parameters.Insert("AppTypeCode", "");
	Parameters.Insert("ConfigurationVersion", "");
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Srv

#Region Files

// Gets parameters for multipart upload.
//
// Parameters:
//  FileName - String 
//  FileSize - Number
//  FileType - String
//  Owner - Arbitrary
// 
// Returns:
//  Structure:
//    * FileID - String
//    * Type - String
//    * Address - String
//    * Headers - Map of KeyAndValue:
//      ** Key - String
//      ** Value - String
Function StartMultipartUpload(FileName, FileSize, FileType, Owner) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "files/new_multipart";
	InterfaceType = "srv";

	QueryData = IsInternal.QueryTemplate(Method, InterfaceType);
	QueryData.Insert("name", FileName);
	QueryData.Insert("size", FileSize);
	If FileType = "DataAreaBackup" Then
		QueryData.Insert("type", "tenant_backup");
	Else
		Raise NStr("vi = 'Kiểu tệp không xác định';
					|ru = 'Неизвестный тип файла';
					|en = 'Unknown file type'; fa = 'Unknown file type';
					|it = 'Неизвестный тип файла';
					|pl = 'Unknown file type';
					|tr = 'Bilinmeyen dosya türü'");
	EndIf;
	QueryData.Insert("owner", Owner);
	Address = IsInternal.ExecutionAddressOfExternalSoftwareInterface(Method, InterfaceType);
	Result = SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);
	ResponseData = IsInternal.ExecutionResult(Result);
	
	Headers = New Map;
	If ResponseData.Property("headers") Then
		For Each Title In ResponseData.headers Do
			Separator = StrFind(Title, ":");
			Headers.Insert(Left(Title, Separator - 1), Mid(Title, Separator + 1));
		EndDo;
	EndIf;
	
	Response = New Structure;
	Response.Insert("Type", ResponseData.type);
	Response.Insert("FileID", ResponseData.file_id);
	Response.Insert("Address", String(ResponseData.url));
	Response.Insert("Headers", Headers);
	
	Return Response;
	
EndFunction

// Gets parameters for the new part
//
// Parameters:
//  FileID - String
//  PartNumber - String
// 
// Returns:
//  Structure:
//    * Type - String
//    * Address - String
//    * Headers - Map of KeyAndValue:
//      ** Key - String
//      ** Value - String
Function NewPart(FileID, PartNumber) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "files/new_part";
	InterfaceType = "srv";
	
	QueryData = IsInternal.QueryTemplate(Method, InterfaceType);
	QueryData.Insert("file_id", FileID);
	QueryData.Insert("part_number", PartNumber);
	
	Address = IsInternal.ExecutionAddressOfExternalSoftwareInterface(Method, InterfaceType);
	Result = SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);
	ResponseData = IsInternal.ExecutionResult(Result);
	
	Headers = New Map;
	For Each Title In ResponseData.headers Do
		Separator = StrFind(Title, ":");
		Headers.Insert(Left(Title, Separator - 1), Mid(Title, Separator + 1));
	EndDo;
	
	Response = New Structure;
	Response.Insert("Type", ResponseData.type);
	Response.Insert("Address", ResponseData.url);
	Response.Insert("Headers", Headers);
	
	Return Response;
	
EndFunction

// Completes a multipart upload
//
// Parameters:
//  FileID - String
//  Parts - Array of String
Procedure CompleteMultipartUpload(FileID, Parts) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "files/complete_multipart"; 
	InterfaceType = "srv";
	
	QueryData = IsInternal.QueryTemplate(Method, InterfaceType);
	QueryData.Insert("file_id", FileID);
	QueryData.Insert("parts", Parts);
	
	Address = IsInternal.ExecutionAddressOfExternalSoftwareInterface(Method, InterfaceType);
	SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData, , Parts.Count() * 60);
	
EndProcedure

// Cancels multipart upload
//
// Parameters:
//  FileID - String
Procedure CancelMultipartUpload(FileID) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "files/abort_multipart";
	InterfaceType = "srv";
	
	QueryData = IsInternal.QueryTemplate(Method, InterfaceType);
	QueryData.Insert("file_id", FileID);
	
	Address = IsInternal.ExecutionAddressOfExternalSoftwareInterface(Method, InterfaceType);
	SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);
	
EndProcedure

// Reads the properties of the uploaded file.
//
// Parameters:
//  ReaderSettings - See NewReadingFilePropertiesParameters
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
// 
// Returns:
//  Structure:
//   * FileName - String
//   * Size - Number
//   * ConfigurationName - String - The name of the configuration as it is specified in the configurator
//   * AppTypeCode - String
//   * NameOfAppType - String
//   * ConfigurationVersion - String
//   * Users - ValueTable:
//    ** Login - String
//    ** FullName - String - full account name
//    ** UserIdentificator - String
//   * Extensions - ValueTable:
//    ** Name - String
//    ** Description - String
//    ** Version - String
//    ** ModifiesDataStructure - Boolean
Function FileProperties(ReaderSettings,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "files/info";
	InterfaceType = "srv";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method, InterfaceType);
	QueryData.Insert("file_id", ReaderSettings.FileID);
	ReceivingParameters = New Array;
	If ReaderSettings.ReadDataFromFile Then
		ReceivingParameters.Add("data_dump_info");
	EndIf;
	QueryData.Insert("scope", ReceivingParameters);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method, InterfaceType, False);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingsFileProperties();
	Result = IsInternal.RenameProperties(ResponseData.file, Renamings);
	
	If Result.Property("data_dump_info") Then
		
		Renamings = IsInternal.RenamingsArchiveCopyData();
		ArchiveCopyData = IsInternal.RenameProperties(Result.data_dump_info, Renamings);
		Result.Delete("data_dump_info");
		Result.Insert("ArchiveCopyData", ArchiveCopyData);
		
		If ArchiveCopyData.Property("users") Then
			Renamings = IsInternal.RenamingsUsersFromArchive();
			UsersFromArchive = IsInternal.StructuresArrayIntoValueTable(ArchiveCopyData.users, Renamings);
			ArchiveCopyData.Delete("users");
			ArchiveCopyData.Insert("Users", UsersFromArchive);
		EndIf;
		
		If ArchiveCopyData.Property("extensions") Then
			Renamings = IsInternal.RenamingsExtensionFromArchive();
			ExtensionsFromArchive = IsInternal.StructuresArrayIntoValueTable(ArchiveCopyData.extensions, Renamings);
			ArchiveCopyData.Delete("extensions");
			ArchiveCopyData.Insert("Extensions", ExtensionsFromArchive);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a template for reading file property parameters for the method
// The service's software interface.File propertiesafile
// 
// Returns:
//  Structure - parameters for reading file properties:
//   * FileID - String
//   * ReadDataFromFile - Boolean
//
Function NewReadingFilePropertiesParameters() Export
	
	Result = New Structure;
	Result.Insert("FileID", "");
	Result.Insert("ReadDataFromFile", False);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region FAQ

// Returns a list of frequently asked questions.
// Implements the external programming interface method - faq/list.
// 
// Parameters:
//  RaiseExceptionAtError - Boolean - indicates whether an exception is thrown when a data acquisition error occurs.
//  BasicResponseProperties - Structure - returned parameter:
//   * StatusCode - Number - status code of the HTTP service response.
//   * ResponseCode - Number - filled in from the response with the value of the "general.response" property.
//   * Message - String - filled in from the response with the value of the "general.message" property.
//  
// Returns:
//  ValueTable - Frequently Asked Questions:
//   * LongDesc - String - description of the question.
//   * Hyperlink - String - Link to the answer to the question.
//
Function FrequentlyAskedQuestions(RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "faq/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = New Map;
	Renamings.Insert("description", IsInternal.ColumnDetails("LongDesc", Common.StringTypeDetails(100)));
	Renamings.Insert("link", IsInternal.ColumnDetails("Hyperlink", Common.StringTypeDetails(0)));
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.faq, Renamings);
	
EndFunction

#EndRegion

#Region Timezone

// Returns a list of time zones.
// Implements the method of the external programming interface - timezones/list.
// 
// Returns:
//  ValueTable - Frequently Asked Questions:
//   * Id - String - ID of the time zone.
//   * Presentation - String - Presentation of the time zone.
//   * Offset - Number - offset in seconds relative to universal time.
//   * Main - Boolean - The time zone is set as the main one in the service settings.
//
Function TimeZones() Export
	
	Return ServiceProgrammingInterfaceCached.TimeZones();
	
EndFunction

#EndRegion

// Returns the template of the basic properties of the response to the request of the program interface.
// 
// Returns:
// 	Structure:
// * StatusCode - Number - status code of the HTTP service call response.
// * ResponseCode - Number - the response code of the program interface. 
// * Message - String - the message of the program interface.
Function NewBasicResponseProperties() Export
	
	Properties = New Structure;
	Properties.Insert("StatusCode", 0);
	Properties.Insert("ResponseCode", 0);
	Properties.Insert("Message", "");

	Return Properties;

EndFunction

#EndRegion

#Region Internal

// Returns a description of the value type of an additional property by name.
//
// Parameters:
//  TypeName - String - name of the value type of the additional property.
// 
// Returns:
//  TypeDescription - description of the value type.
Function ValueTypeOfAdditionalPropertyByName(TypeName) Export
	
	If TypeName = "string" Then
		Return Common.StringTypeDetails(1024);
	ElsIf TypeName = "decimal" Then
		Return Common.TypeDescriptionNumber(10);
	ElsIf TypeName = "date" Then
		Return Common.DateTypeDetails(DateFractions.DateTime);
	ElsIf TypeName = "boolean" Then
		Return New TypeDescription("Boolean");
	ElsIf TypeName = "subscriber" Then
		Return Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative);
	ElsIf TypeName = "service" Then
		Return Common.StringTypeDetails(9);
	ElsIf TypeName = "additional_value" Then
		Return Common.StringTypeDetails(255);
	ElsIf TypeName = "additional_value_group" Then
		Return Common.StringTypeDetails(255);
	ElsIf TypeName = "tariff" Then
		Return Common.StringTypeDetails(9);
	ElsIf TypeName = "service_provider_tariff" Then
		Return Common.StringTypeDetails(9);
	ElsIf TypeName = "user" Then
		Return Common.StringTypeDetails(32);
	ElsIf TypeName = "tariff_period" Then
		Return Common.StringTypeDetails(10);
	ElsIf TypeName = "subscription" Then
		Return Common.StringTypeDetails(9);
	Else
		Return Type("Undefined");
	EndIf;
	
EndFunction

// Fills in the selection list of value types of additional properties.
//
// Parameters:
//  ChoiceList - ValueList of String - the selection list on the form.
Procedure FillInListForSelectingValueTypesForAdditionalProperties(ChoiceList) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	TypesPresentation1 = IsInternal.PresentationsOfValueTypesForAdditionalInformation();
	For Each String In TypesPresentation1 Do
		NewRow = ChoiceList.Add();
		FillPropertyValues(NewRow, String);
	EndDo; 

EndProcedure

// Fills in the conditional design of the additional property type field by value.
//
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance - conditional form design.
//  AttributeName - String - name of the form's details
//  FieldName - String - name of the form field
//
Procedure SetAppearanceOfAdditionalPropertyTypeField(ConditionalAppearance, AttributeName, FieldName) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	TypesPresentation1 = IsInternal.PresentationsOfValueTypesForAdditionalInformation();
	
	For Each Item In TypesPresentation1 Do
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		Item_Text = ConditionalAppearanceItem.Appearance.Items.Find("Text");
		Item_Text.Value = Item.Presentation;
		Item_Text.Use = True;
		
		DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DataFilterItem.LeftValue  = New DataCompositionField(AttributeName);
		DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
		DataFilterItem.RightValue = Item.Value;
		DataFilterItem.Use  = True;
		
		AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
		AppearanceFieldItem.Field = New DataCompositionField(FieldName);
		AppearanceFieldItem.Use = True;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Function AddSubscriberAuthorization(QueryData, SubscriberCode)
	
	SubscriberAuthorization = New Structure("account", SubscriberCode);
	QueryData.Insert("auth", SubscriberAuthorization);
	
	Return QueryData;

EndFunction

Function SubscriberCode() Export
	
	SubscriberCode = ServiceProgrammingInterfaceCached.SubscriberCode();
	If SubscriberCode = 0 Then
		SubscriberCode = SubscriberOfThisApplication().Code;
	EndIf;
	
	Return SubscriberCode;
	
EndFunction

#EndRegion
