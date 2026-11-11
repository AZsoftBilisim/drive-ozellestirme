#Region Internal

// Returns the address for the request to the external programming interface of the service manager.
//
// Parameters:
//  Method - String - name of the method of the external program interface of the service Manager.
//  InterfaceType - String, Undefined - the interface type of the service manager's external programming interface method.
//                                         If not specified, the value "usr" is accepted.
// 
// Returns:
//  String
//
Function ExecutionAddressOfExternalSoftwareInterface(Method, InterfaceType = Undefined) Export
	
	Address = "hs/ext_api/execute";
	
	If ServiceProgrammingInterfaceCached.ServiceManagerSupportsMethodInAddress() Then
		
		Return Address + "/" + ?(InterfaceType = Undefined, "usr", InterfaceType) + "/" + Method;
		
	EndIf;
	
	Return Address;
	
EndFunction

// The http version of the ExtAPI service of the service manager obtained through the BSP interface version mechanism.
// 
// Returns:
//  Number, Undefined - ExtAPI version. Undefined is returned when the connection to the Service Manager is not configured
Function ServiceManagerExtAPIVersion() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If SaaSOperations.DataSeparationEnabled() Then
		If Not SaaSOperations.ServiceManagerEndpointConfigured() Then
			Return Undefined;
		EndIf;
		Versions = Common.GetInterfaceVersions(
			SaaSOperations.InternalServiceManagerURL(),
			SaaSOperations.ServiceManagerInternalUserName(),
			SaaSOperations.ServiceManagerInternalUserPassword(),
			"ExtAPI");
		If Not ValueIsFilled(Versions) Then
			Return 1;
		EndIf;
			
		Return Versions[Versions.UBound()];
	Else
		Return ServiceProgrammingInterfaceCached.InterfaceVersionProperties().Version;
	EndIf; 
	
EndFunction

// The service manager supports specifying the method in the http address of the ExtAPI service.
// 
// Returns:
//  Boolean
Function ServiceManagerSupportsMethodInAddress() Export
	
	EXTAPIVersion = ServiceManagerExtAPIVersion();
	
	Return EXTAPIVersion <> Undefined And EXTAPIVersion >= 19;

EndFunction

// Returns the request template to the external programming interface of the service manager.
//
// Parameters:
//  Method - String - name of the method of the external program interface of the service Manager.
//  InterfaceType - String, Undefined - the interface type of the service manager's external programming interface method.
//                                         If not specified, the value "usr" is accepted.
// 
// Returns:
//  Structure - request template:
//  * general - Structure:
//     ** type - String
//     ** method - String
//
Function QueryTemplate(Method, InterfaceType = Undefined) Export

	If ServiceProgrammingInterfaceCached.ServiceManagerSupportsMethodInAddress() Then
		Return New Structure;
	EndIf;
	
	MainParametersOfMethod = New Structure;
	MainParametersOfMethod.Insert("type", ?(InterfaceType = Undefined, "usr", InterfaceType));
	MainParametersOfMethod.Insert("method", Method);

	QueryTemplate = New Structure;
	QueryTemplate.Insert("general", MainParametersOfMethod);

	Return QueryTemplate;

EndFunction

// Sends a request to the service from the external program interface of the service Manager.
//
// Parameters:
//  QueryData - Structure - request data, in the appropriate format.
//                              For more information, see the article https://its.1c.ru/db/freshsm#content:15205582:hdoc . 
//                              It can contain an auth.account section with the subscriber code.
//  Method - String - name of the method of the external program interface of the service Manager.
//  InterfaceType - String, Undefined - the interface type of the service manager's external programming interface method.
//                                         If not specified, the value "usr" is accepted.
//  AuthorizeSubscriber - Boolean - indicates whether the subscriber's authorization has been added to the current area.
//   Authorization data is added immediately before executing the request.
//
// Returns:
//  HTTPResponse - the response of the HTTP service of the Service Manager. 
//
Function SendDataToServiceManager(QueryData, Method, InterfaceType = Undefined, AuthorizeSubscriber = True) Export

	DataSeparationEnabled = SaaSOperations.DataSeparationEnabled();
	Address = ExecutionAddressOfExternalSoftwareInterface(Method, InterfaceType);
	
	If AuthorizeSubscriber Then
		If QueryData.Property("auth") And QueryData.auth.Property("account") Then
			SubscriberCode = QueryData.auth.account;
		ElsIf DataSeparationEnabled Then
			SubscriberCode = ServiceProgrammingInterface.SubscriberCode();
		Else
			SubscriberCode = AuthorizationDataInService().SubscriberCode;
		EndIf;
		AuthorizationProperties = AuthorizationProperties(SubscriberCode);
	Else
		AuthorizationProperties = AuthorizationProperties();
	EndIf;
	
	QueryData.Insert("auth", AuthorizationProperties);
	
	If DataSeparationEnabled Then
		If SaaSOperations.AccessTokenAuthenticationOfInternalAPIRequests() Then
			AccessToken = ServiceProgrammingInterface.ValidAccessToken();
			Result = SendRequestToServiceManagerByAccessToken("POST", Address, AccessToken, QueryData); 
		Else
			Result = SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);
		EndIf;
	Else
		Result = SendRequestToServiceFromLocalDatabase("POST", Address, QueryData);
	EndIf; 
	
	Return Result;

EndFunction

Function SendRequestToServiceManagerByAccessToken(Method, Address, AccessToken, Data = Undefined, 
	ConnectionCache = True, Timeout = 60) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	FullAddress = StrTemplate("%1/%2", SaaSOperations.InternalServiceManagerURL(), Address);
	ServerData = CommonClientServer.URIStructure(FullAddress);

	If ConnectionCache Then
		Join = ServiceProgrammingInterfaceCached.ConnectionToServiceManagerWithoutAuthorization(ServerData, Timeout);
	Else
		Join = ConnectionToServiceManagerWithoutAuthorization(ServerData, Timeout);
	EndIf;

	HTTPRequest = New HTTPRequest(ServerData.PathAtServer);
	HTTPRequest.Headers.Insert("Authorization", StrTemplate("Bearer %1", AccessToken));
	HTTPRequest.Headers.Insert("Content-Type", "application/json; charset=utf-8");

	If TypeOf(Data) = Type("Structure") Then
		Data = SaaSOperationsCTL.StringFromJSONStructure(Data);
		HTTPRequest.SetBodyFromString(Data);
	ElsIf TypeOf(Data) = Type("BinaryData") Then
		HTTPRequest.SetBodyFromBinaryData(Data);
	ElsIf TypeOf(Data) = Type("String") Then
		HTTPRequest.SetBodyFromString(Data);
	EndIf;

	Return Join.CallHTTPMethod(Method, HTTPRequest);

EndFunction

// Renames response data fields based on the corresponding field renames.
// 
// Parameters:
// 	ResponseData - Structure - response data.
// 	Renamings - Map of KeyAndValue:
// 	* Key - String - name of the source field.
// 	* Value  - See ColumnDetails
// 				- String - column name.
// Returns:
// 	See RenameProperties.ResponseData
Function RenameProperties(ResponseData, Val Renamings) Export

	For Each Item In Renamings Do
		RenamingValue = Item.Value; // See ColumnDetails
		If TypeOf(RenamingValue) = Type("String") Then 
			FieldName = RenamingValue;
			FieldType = Undefined;
		Else
			FieldName = RenamingValue.Name;
			FieldType = RenamingValue.Type;
		EndIf;
		If ResponseData.Property(Item.Key) Then
			Value = ResponseData[Item.Key];
			ResponseData.Delete(Item.Key);
		Else
			Value = Undefined;
		EndIf;
		If FieldType <> Undefined Then
			Value = ValueByType(FieldType, Value);
		EndIf; 
			
		ResponseData.Insert(FieldName, Value);
		
	EndDo;

	Return ResponseData;

EndFunction

// Returns the response data of the program interface method call.
//
// Parameters:
// 	Response - HTTPResponse - HTTP response to be processed.
// 	RaiseExceptionAtError - Boolean - indicates whether an exception is raised in case of an error. Error when the status code is not equal to 102xx.
// 	StatusCode - Number - the returned parameter is the HTTP response status code.
// 	ResponseCode - Number - returned parameter-filled in from the response with the value of the "general.response" property.
// 	Message - String - returned parameter-filled in from the response with the value of the "general.message" property.
//  
// Returns:
// 	Undefined, Structure - Result Data:
//   * Fields - Arbitrary - arbitrary result fields.
Function ExecutionResult(Response, RaiseExceptionAtError = True,
		StatusCode = 0, ResponseCode = 0, Message = "") Export

	StatusCode = Response.StatusCode;
	If StatusCode <> 200 Then
		If RaiseExceptionAtError Then
			Raise StrTemplate("%1 %2", StatusCode, Response.GetBodyAsString());
		Else
			Return Undefined;
		EndIf;
	EndIf;

	DataStream = Response.GetBodyAsStream();
	DateNames = New Array;
	DateNames.Add("start");
	DateNames.Add("completion");
	DateNames.Add("planned_date");
	DateNames.Add("created");
	DateNames.Add("modified");
	DateNames.Add("activated");
	DateNames.Add("blocked");
	DateNames.Add("expiration");
	DateNames.Add("timestamp");
	DateNames.Add("utc_timestamp");
	DateNames.Add("size_calc_date");
	DateNames.Add("expires_at");
	Data = SaaSOperationsCTL.StructureFromJSONStream(DataStream, DateNames);

	ResponseCode = Data.general.response;
	Message = Data.general.message;

	If Not (ResponseCode = 10200 Or ResponseCode = 10201 Or ResponseCode = 10202 Or ResponseCode = 10240) Then
		If RaiseExceptionAtError Then
			If ResponseCode <> 10404 Then
				Message = StrTemplate("%1 %2", ResponseCode, Message);
			EndIf; 
			Raise Message;
		Else
			Return Undefined;
		EndIf;
	EndIf;

	Return Data;

EndFunction

// Returns the authorization properties for the request to the external programming interface of the service manager.
// 
// Parameters:
// 	SubscriberCode - Number
// 	User - CatalogRef.Users
// 	Token - String - temporary service user token
// 	
// Returns:
// 	Structure:
//   * account - Number - area subscriber code (number).
//  If authorization is performed in the service model, additional data is transmitted:
//   * type - String - type of request. From BTS is always equal to "smtl".
//   * host - String - the showcase host where the application is located
//   * tenant - Number - area number
//   * key - String - area key
//  If the authorization comes from a service user, additionally transmitted:
//   * login - String - user login
//   * hash - String - hash of the user's password
//
Function AuthorizationProperties(SubscriberCode = Undefined,
	Val User = Undefined, Val Token = Undefined) Export

	AuthorizationProperties = New Structure;
	If ValueIsFilled(SubscriberCode) Then
		AuthorizationProperties.Insert("account", SubscriberCode);
	EndIf;
	
	If Not SaaSOperations.DataSeparationEnabled() Then
		Return AuthorizationProperties;
	EndIf;
	
	If User = Undefined Then
		UserIdentificator = InfoBaseUsers.CurrentUser().UUID;
	Else
		UserIdentificator = Common.ObjectAttributeValue(User, "IBUserID");
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	// The user must be read from the database, because when changing the password, the current user() contains the old password
	CurrentUser = InfoBaseUsers.FindByUUID(UserIdentificator);

	If CurrentUser = Undefined And Token = Undefined Then
		// A request is made from the information database administrator after entering the data area.
		Raise ExecutingRequestFromAdministratorExceptionText(); 
	EndIf;
	
	If CurrentUser = Undefined Then
	
		StoredPasswordValue = Token;
		
		If UserIdentificator <> CommonClientServer.BlankUUID() Then
			UserName = InfoBaseUsers.CurrentUser().Name;
		Else
			UserName = StrTemplate("service user (%1)", Left(New UUID, 8));
		EndIf;
	
	Else
		StoredPasswordValue = CurrentUser.StoredPasswordValue;
		UserName = CurrentUser.Name;
	EndIf;
	
	ApplicationLocation = CommonClientServer.URIStructure(GetInfoBaseURL());
	
	AuthorizationProperties.Insert("type", "smtl");
	AuthorizationProperties.Insert("host", ApplicationLocation.Host);
	AuthorizationProperties.Insert("tenant", SaaSOperations.SessionSeparatorValue());
	AuthorizationProperties.Insert("key", Constants.DataAreaKey.Get());
	
	If Not (SaaSOperations.AccessTokenAuthenticationOfInternalAPIRequests()
		And Token = Undefined) Then
		AuthorizationProperties.Insert("login", UserName);
		AuthorizationProperties.Insert("hash", StoredPasswordValue);
	EndIf;
	
	Return AuthorizationProperties;

EndFunction

Function ExecutingRequestFromAdministratorExceptionText() Export
	
	Administrator = InfoBaseUsers.CurrentUser();
	ExceptionPattern = NStr("vi = 'Không thể thực hiện truy vấn, bởi vì nó được gọi ra từ người quản trị cơ sở thông tin - %1 (%2).
							 |Chỉ có thể thực hiện theo tên người sử dụng vùng - %3.';
							 |ru = 'Запрос не может быть выполнен, т.к. вызывается от администратора информационной базы - %1 (%2).
							 |Возможно выполнение только от имени пользователя области - %3.';
							 |en = 'Cannot execute the query as it is called from the infobase administrator - %1 (%2).
							 |It can be executed only on behalf of the area user: %3.'; fa = 'Cannot execute the query as it is called from the infobase administrator - %1 (%2).
							 |It can be executed only on behalf of the area user: %3.';
							 |it = 'La richiesta non può essere eseguita, poiché chiamata dall''amministratore dell''infobase - %1(%2).
							 |È possibile la compilazione solo a nome dell''utente d''area - %3.';
							 |pl = 'Zapytanie nie może być wykonane, ponieważ jest wywołane od administratora bazy informacyjnej - %1 (%2).
							 |Możliwe jest tylko wykonanie w imieniu użytkownika obszaru - %3.';
							 |tr = 'İstek tamamlanamıyor çünkü infobase yöneticisinden çağrıldı - %1 (%2).
							 |Yalnızca bölge kullanıcısı adına yürütülebilir- %3.'");
	ViewArea = Format(SaaSOperations.SessionSeparatorValue(), "NG=0");
	Return StrTemplate(ExceptionPattern, Administrator.Name, Administrator.FullName, ViewArea );
	
EndFunction

// Send a request to the service from the local database.
// 
// Parameters:
//  Method - String
//  Address - String
//  Data - Structure:
//   * auth - Structure:
//      ** account - Number
//  ConnectionCache - Boolean
//  Timeout - Number
// 
// Returns:
//  HTTPResponse
Function SendRequestToServiceFromLocalDatabase(Method, Address, Data = Undefined, ConnectionCache = True, Timeout = 60) Export
	
	ServiceAddress = ServiceAddressFromLocalDatabase();
	
	FullAddress = StrTemplate("%1/%2", ServiceAddress, Address);
	ServerData = CommonClientServer.URIStructure(FullAddress);
	
	If ConnectionCache Then
		Join = ServiceProgrammingInterfaceCached.ConnectingToServiceManagerFromLocalDatabase(ServerData, Timeout);
	Else
		Join = ConnectingToServiceManagerFromLocalDatabase(ServerData, Timeout);
	EndIf;
	
	Query = New HTTPRequest(ServerData.PathAtServer);
	Query.Headers.Insert("Content-Type", "application/json; charset=utf-8");

	If TypeOf(Data) = Type("Structure") Then
		Data = SaaSOperationsCTL.StringFromJSONStructure(Data);
		Query.SetBodyFromString(Data);
	ElsIf TypeOf(Data) = Type("BinaryData") Then
		Query.SetBodyFromBinaryData(Data);
	ElsIf TypeOf(Data) = Type("String") Then
		Query.SetBodyFromString(Data);
	EndIf;

	Return Join.CallHTTPMethod(Method, Query);
	
EndFunction

// the address of the service from the local database.
// 
// Returns:
//  String - the address of the service from the local database.
Function ServiceAddressFromLocalDatabase() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	ServiceAddress = Constants.Fresh1CServiceAddress.Get();
	
	If Not ValueIsFilled(ServiceAddress) Then
		ErrorText = NStr("vi = 'Chưa thiết lập địa chỉ dịch vụ. Cần thiết lập địa chỉ trong tùy chỉnh theo tham chiếu: 
		|%1';
		|ru = 'Не установлен адрес сервиса. Нужно установить адрес в настройках по ссылке: 
		|%1';
		|en = 'Service address is not specified. Set the address in the settings by reference:
		|%1'; fa = 'Service address is not specified. Set the address in the settings by reference:
		|%1';
		|it = 'Indirizzo del servizio non impostato. È necessario impostare l''indirizzo nelle impostazioni al collegamento: 
		|%1';
		|pl = 'Adres usługi nie jest ustawiony. Należy ustawić adres usługi. Należy ustawić adres w ustawieniach, otwierając odnośnik: 
		|%1';
		|tr = 'Servis adresi ayarlanmadı. Şu bağlantıyı kullanarak ayarlarda adresi ayarlamanız gerekir: 
		|%1'");
		LinkToSettings = "e1cib/data/DataProcessor.AdministrationPanelCTL.Form.FreshServiceConnectionSettings";
		Raise StrTemplate(ErrorText, LinkToSettings); 
	EndIf;
	
	Return ServiceAddress;

EndFunction

// Connection with the service manager from the local database.
// 
// Parameters:
//  ServerData - See CommonClientServer.URIStructure
//  Timeout - Number
// 
// Returns:
//  HTTPConnection
Function ConnectingToServiceManagerFromLocalDatabase(ServerData, Timeout = 60) Export
	
	SSLScheme = "https";
	If Lower(ServerData.Schema) = SSLScheme Then
		SecureConnection =  CommonClientServer.NewSecureConnection();
	Else
		SecureConnection = Undefined;
	EndIf;
	
	AuthorizationData = AuthorizationDataInService();
	SetSafeModeDisabled(True);
	Join = New HTTPConnection(ServerData.Host, ServerData.Port,
		AuthorizationData.Login, AuthorizationData.Password,
		GetFilesFromInternet.GetProxy(ServerData.Schema), Timeout, SecureConnection);

	Return Join;
	
EndFunction

Function ConnectionToServiceManagerWithoutAuthorization(ServerData, Timeout = 60) Export
	
	SSLScheme = "https";
	If Lower(ServerData.Schema) = SSLScheme Then
		SecureConnection =  CommonClientServer.NewSecureConnection();
	Else
		SecureConnection = Undefined;
	EndIf;
	
	SetSafeModeDisabled(True);
	Join = New HTTPConnection(ServerData.Host, ServerData.Port, , ,
		GetFilesFromInternet.GetProxy(ServerData.Schema), Timeout, SecureConnection);
	
	Return Join;
	
EndFunction

// Returns authorization data in the service for the specified user.
// If no user is specified, the current one is used.
//
// Parameters:
//  User - CatalogRef.Users - if not passed, the Cur user is used.
//  
// Returns:
//  Structure:
//   * Login - String
//   * Password - String
//   * SubscriberCode - Number
//
Function AuthorizationDataInService(User = Undefined) Export
	
	If User = Undefined Then
		User = Users.CurrentUser();
	EndIf; 
	AuthorizationData = InformationRegisters.AuthorizationIn1cFresh.Read(User);
	If Not ValueIsFilled(AuthorizationData.Login) Then
		ErrorText = NStr("vi = 'Chưa thiết lập dữ liệu đăng nhập vào dịch vụ. Cần thiết lập dữ liệu đăng nhập theo tham chiếu:
						         |%1.';
						         |ru = 'Не установлены данные авторизации в сервисе. Нужно установить данные авторизации по ссылке:
						         |%1.';
						         |en = 'Authorization data in the service is not specified. Set authorization data by reference:
						         |%1.'; fa = 'Authorization data in the service is not specified. Set authorization data by reference:
						         |%1.';
						         |it = 'Non sono impostati i dati di autorizzazione nel servizio. È necessario impostare i dati di autorizzazione al collegamento:
						         |%1.';
						         |pl = 'Dane uwierzytelniania nie są ustawione w usłudze. Należy ustawić dane uwierzytelniania, otwierając odnośnik:
						         |%1.';
						         |tr = 'Servisteki yetkilendirme verileri ayarlanmamış. Bağlantıdan kimlik doğrulama verilerini ayarlamanız gerekir:
						         |%1'");
		LinkToAuthorizationData = "e1cib/data/InformationRegister.AuthorizationIn1cFresh";
		Raise StrTemplate(ErrorText, LinkToAuthorizationData);
	EndIf; 
	
	Return AuthorizationData;
	
EndFunction
 
// An array of structures in a table of values.
// 
// Parameters:
//  StructuresArray - Array of Structure:
//   * Fields - Arbitrary - the fields correspond to the columns of the table.
//  RenamingColumns - Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
// 
// Returns:
//  ValueTable:
//   * Fields - Arbitrary - a set of columns corresponding to the fields of the array structures.
Function StructuresArrayIntoValueTable(StructuresArray, RenamingColumns) Export
	
	Prefix = StrTemplate("%1_","Column"); // For the absence of intersections when renaming.
	PrefixLength = StrLen(Prefix);
	
	Result = New ValueTable;
	For Each String In StructuresArray Do
		For Each KeyValue In String Do
			ColumnType = Undefined;
			RenamingValue = RenamingColumns.Get(KeyValue.Key);
			If ValueIsFilled(RenamingValue) And TypeOf(RenamingValue) = Type("Structure") Then
				ColumnType = RenamingValue.Type;
			EndIf;
			If Result.Columns.Find(Prefix + KeyValue.Key) = Undefined Then
				Result.Columns.Add(Prefix + KeyValue.Key, ColumnType);
			EndIf;
			If ColumnType <> Undefined Then
				String[KeyValue.Key] = ValueByType(ColumnType, KeyValue.Value);
			EndIf;
		EndDo;
		NewRow = Result.Add();
		For Each KeyAndValue In String Do
			NewRow[Prefix + KeyAndValue.Key] = String[KeyAndValue.Key];
		EndDo;
	EndDo;

	For Each Item In RenamingColumns Do
		If TypeOf(Item.Value) = Type("String") Then
			ColumnName = Item.Value;
			ColumnType = Undefined;
		Else
			ColumnName = Item.Value.Name;
			ColumnType = Item.Value.Type;
		EndIf;
		If Result.Columns.Find(Prefix + Item.Key) <> Undefined Then
			Column = Result.Columns[Prefix + Item.Key]; // ValueTableColumn
			Column.Name = ColumnName;
		Else
			Result.Columns.Add(ColumnName, ColumnType);
		EndIf;
	EndDo;
	
	For Each Column In Result.Columns Do
		If Left(Column.Name, PrefixLength) = Prefix Then
			Column.Name = Mid(Column.Name, PrefixLength + 1);
		EndIf;
	EndDo;

	Return Result;

EndFunction

// A table of values in an array of structures.
// 
// Parameters:
//  ValueTable - ValueTable:
//   * Fields - Arbitrary - an arbitrary set of fields.
// RenamingProperties - Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
// 
// Returns:
//  Array of Structure:
//   * Fields - Arbitrary - the fields correspond to the columns of the table.
Function TableOfValuesInArrayOfStructures(ValueTable, RenamingProperties) Export
	
	Result = New Array;
	For Each String In ValueTable Do
		Item = New Structure;
		For Each KeyValue In RenamingProperties Do
			Value = String[KeyValue.Value.Name];
			If KeyValue.Value.Type.ContainsType(Type("UUID")) Then
				Value = String(Value);
			EndIf; 
			Item.Insert(KeyValue.Key, Value);
		EndDo; 
		Result.Add(Item);
	EndDo; 
	
	Return Result;
	
EndFunction
 
#Region Subscriber

// Returns the subscriber renaming fields.
//
// Parameters:
//  KI - Boolean - Add contact information fields.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String - API field name
//   * Value - See ColumnDetails
//
Function RenamingSubscriber(KI = False) Export
	
	Renamings = New Map;
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(64)));
	Renamings.Insert("id", ColumnDetails(
		"Code", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("email", ColumnDetails("Mail", Common.StringTypeDetails(500)));
	Renamings.Insert("public_id", ColumnDetails("PublicId", Common.StringTypeDetails(36)));
	If KI Then // Add contact information fields.
		Renamings.Insert("site", ColumnDetails("Website1", Common.StringTypeDetails(500)));
		Renamings.Insert("city", ColumnDetails("City", Common.StringTypeDetails(500)));
		Renamings.Insert("phone", ColumnDetails("Phone", Common.StringTypeDetails(500)));
	EndIf; 
	
	Return Renamings;

EndFunction

// Renaming the "Subscriber Users" table.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingSubscriberUsers() Export
	
	Renamings = New Map;
	Renamings.Insert("login", ColumnDetails(
		"Login", Common.StringTypeDetails(250)));
	Renamings.Insert("name", ColumnDetails(
		"FullName", Common.StringTypeDetails(150)));
	Renamings.Insert("email", ColumnDetails(
		"Mail", Common.StringTypeDetails(254)));
	Renamings.Insert("phone", ColumnDetails(
		"Phone", Common.StringTypeDetails(500)));
	Renamings.Insert("role", ColumnDetails(
		"UserRole", New TypeDescription("EnumRef.SubscriberUsersRoles")));
	Renamings.Insert("session_restriction", ColumnDetails(
		"AllowedNumberOfSessions", Common.TypeDescriptionNumber(10, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("is_temporary", ColumnDetails(
		"TemporaryAccess", New TypeDescription("Boolean")));
	Renamings.Insert("description", ColumnDetails(
		"LongDesc", Common.StringTypeDetails(300)));
	
	Return Renamings;
	
EndFunction
 
#EndRegion

#Region AccountingSystem

// Renaming the "Accounting System" object.
// 
// Parameters:
//  Method - String - name of the program interface method
//  
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountingSystem(Method) Export
	
	Renamings = New Map;
	
	Renamings.Insert("id", ColumnDetails(
		"Code", Common.TypeDescriptionNumber(9, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(100)));
	Renamings.Insert("owner_id", ColumnDetails(
		"OwnerCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("import", ColumnDetails("ImportingData",New TypeDescription("Boolean")));
	Renamings.Insert("import_login", ColumnDetails(
		"ImportingUserLogin", Common.StringTypeDetails(250)));
	Renamings.Insert("export", ColumnDetails("ExportingData",New TypeDescription("Boolean")));
	Renamings.Insert("export_url", ColumnDetails(
		"ExportingURL", Common.StringTypeDetails(150)));
	Renamings.Insert("export_login", ColumnDetails(
		"ExportingUserLogin", Common.StringTypeDetails(250)));
	
	If Method = "accounting_system/info" Then
		Renamings.Insert("description", ColumnDetails("LongDesc", New TypeDescription("String")));
		Renamings.Insert("export_rules", "ExportingRules");
		Renamings.Insert("import_rules", "ImportingRules");
		Renamings.Insert("response_processing_rules", "ResponseProcessingRules");
	EndIf;
	
	Return Renamings;
	
EndFunction
 
// Renaming tab. parts of the "Unloading rules" of the "Accounting system" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountingSystemUploadRules() Export
	
	Renamings = New Map;
	
	Renamings.Insert("rule_id",  ColumnDetails(
		"RuleCode", Common.StringTypeDetails(120)));
	Renamings.Insert("rule_line_id",  ColumnDetails(
		"RowID", New TypeDescription("UUID")));
	Renamings.Insert("condition_id",  ColumnDetails(
		"ConditionCode", Common.TypeDescriptionNumber(9, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("url",  ColumnDetails(
		"Address", Common.StringTypeDetails(150)));
	Renamings.Insert("fast_sending",  ColumnDetails(
		"FastSending", New TypeDescription("Boolean")));
	Renamings.Insert("scheduled_export",  ColumnDetails(
		"ScheduledExport", New TypeDescription("Boolean")));
	Renamings.Insert("provider_selection",  ColumnDetails(
		"SelectionBySupplier", New TypeDescription("Boolean")));
	
	Return Renamings;
	
EndFunction

// Renaming tab. parts of the "Loading rules" of the "Accounting system" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountSystemUploadRules() Export
	
	Renamings = New Map;
	
	Renamings.Insert("rule_id",  ColumnDetails(
		"RuleCode", Common.StringTypeDetails(120)));
	Renamings.Insert("url",  ColumnDetails(
		"Address", Common.StringTypeDetails(150)));
	
	Return Renamings;

EndFunction

// Renaming tab. parts of the "Response processing rules" of the "Accounting System" object.
// 
// Returns:
// Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountSystemResponseProcessingRules() Export
	
	Renamings = New Map;
	
	Renamings.Insert("rule_line_id",  ColumnDetails(
		"ExportingRuleLineId", New TypeDescription("UUID")));
	Renamings.Insert("rule_id",  ColumnDetails(
		"RuleCode", Common.StringTypeDetails(120)));
	Renamings.Insert("response_codes",  ColumnDetails(
		"ResponseCodes", New TypeDescription("Array")));
	
	Return Renamings;
	
EndFunction

#EndRegion

#Region SubscriptionPlan

// Renaming the "Subscription to the tariff" object.
// 
// Parameters:
//  ForServiceOrganization - Boolean - flag for getting a description for service organizations.
//  
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingSubscriptionPlan(ForServiceOrganization) Export
	
	Renamings = New Map;
	
	Renamings.Insert("id",  ColumnDetails(
		"Number", Common.StringTypeDetails(9)));
	Renamings.Insert("created", ColumnDetails(
		"Date", Common.DateTypeDetails(DateFractions.DateTime)));
	Renamings.Insert("start", ColumnDetails(
		"ConnectionDate", Common.DateTypeDetails(DateFractions.DateTime)));
	Renamings.Insert("completion", ColumnDetails(
		"DateOfExpiration", Common.DateTypeDetails(DateFractions.DateTime)));
	If ForServiceOrganization Then
		Renamings.Insert("account", ColumnDetails(
			"ServicedSubscriberCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
		Renamings.Insert("servant", ColumnDetails(
			"MasterSubscriberCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
		Renamings.Insert("tariff", ColumnDetails(
			"ProviderServicePlanCode", Common.StringTypeDetails(9)));
	Else
		Renamings.Insert("account", ColumnDetails(
			"SubscriberCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
		Renamings.Insert("servant", ColumnDetails(
			"ServiceProviderCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
		Renamings.Insert("tariff", ColumnDetails(
			"ServicePlanCode", Common.StringTypeDetails(9)));
	EndIf; 
	
	Renamings.Insert("servant_tariff", ColumnDetails(
		"ServiceProviderPlanCode", Common.StringTypeDetails(9)));
	Renamings.Insert("period", ColumnDetails(
		"ValidityPeriodCode", Common.StringTypeDetails(10)));
	Renamings.Insert("amount", ColumnDetails(
		"Count", Common.TypeDescriptionNumber(10, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("parent", ColumnDetails(
		"PrimarySubscriptionNumber", Common.StringTypeDetails(9)));
	Renamings.Insert("type", ColumnDetails(
		"SubscriptionType", New TypeDescription("EnumRef.ServiceSubscriptionsTypes")));
	Renamings.Insert("bill", ColumnDetails(
		"InvoiceNum", Common.StringTypeDetails(9)));
	Renamings.Insert("bill_id", ColumnDetails(
		"PaymentInvoiceID", New TypeDescription("UUID")));
	
	Return Renamings;
	
EndFunction

// Renaming the fields of the response to creating a subscription to the tariff.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAndCreatingSubscriptionToPricingPlan() Export
	
	Renamings = New Map;
	Renamings.Insert("id",  ColumnDetails(
		"Number", Common.StringTypeDetails(9)));
	Renamings.Insert("completion", ColumnDetails(
		"DateOfExpiration", Common.DateTypeDetails(DateFractions.DateTime)));
	
	Return Renamings;

EndFunction

// Names of subscription creation properties.
// 
// Parameters:
//  ExtensionProperties1 - Boolean - indicates whether to add subscription extension properties.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - String
Function SubscriptionCreationPropertyNames(ExtensionProperties1 = False) Export
	
	PropertiesNames = New Map;
	PropertiesNames.Insert("MasterSubscriberCode", "servant");
	PropertiesNames.Insert("ServicedSubscriberCode", "account");
	PropertiesNames.Insert("ServiceProviderPlanCode", "servant_tariff");
	PropertiesNames.Insert("ProviderServicePlanCode", "tariff");
	PropertiesNames.Insert("ValidityPeriodCode", "period");
	PropertiesNames.Insert("ConnectionDate", "start");
	PropertiesNames.Insert("DateOfExpiration", "completion");
	If ExtensionProperties1 Then
		PropertiesNames.Insert("PrimarySubscriptionNumber", "parent");
		PropertiesNames.Insert("Count", "amount");
	EndIf; 
	
	Return PropertiesNames;

EndFunction

#EndRegion

#Region Backups

// Renaming the "Backup Copies" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingsBackups() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails(
		"BackupIdentificator", Common.StringTypeDetails(36)));
	Renamings.Insert("tenant", ColumnDetails(
		"AreaNumber", Common.TypeDescriptionNumber(7, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("tenant_name", ColumnDetails(
		"AreaDescription", Common.StringTypeDetails(100)));
	Renamings.Insert("size", ColumnDetails(
		"Size", Common.TypeDescriptionNumber(15, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("app_version", ColumnDetails(
		"ConfigurationVersion", Common.StringTypeDetails(18)));
	Renamings.Insert("app_name", ColumnDetails(
		"AppTypeName", Common.StringTypeDetails(255)));
	Renamings.Insert("is_original", ColumnDetails(
		"Original", New TypeDescription("Boolean")));
	Renamings.Insert("utc_timestamp", ColumnDetails(
		"CreationDateUTC", Common.DateTypeDetails(DateFractions.DateTime)));
	Renamings.Insert("is_ondemand", ColumnDetails(
		"OnDemand", New TypeDescription("Boolean")));
	Renamings.Insert("is_annual", ColumnDetails(
		"Annual", New TypeDescription("Boolean")));
	Renamings.Insert("is_monthly", ColumnDetails(
		"Monthly_", New TypeDescription("Boolean")));
	Renamings.Insert("is_daily", ColumnDetails(
		"Daily_", New TypeDescription("Boolean")));
	Renamings.Insert("comment", ColumnDetails(
		"Comment", Common.StringTypeDetails(0)));
	Renamings.Insert("timezone", ColumnDetails(
		"TimeZone", Common.StringTypeDetails(100)));
	Renamings.Insert("file_name", ColumnDetails(
		"FileName", Common.StringTypeDetails(0)));
	
	Return Renamings;
	
EndFunction

#EndRegion

#Region Tariff

// Renaming the "Tariff" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingRates() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Code", Common.StringTypeDetails(9)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(150)));
	Renamings.Insert("description", ColumnDetails("DescriptionForServiceOrganizations", New TypeDescription("String")));
	Renamings.Insert("description_for_subscribers", ColumnDetails("DescriptionForSubscribers", New TypeDescription("FormattedDocument")));
	Renamings.Insert("start", ColumnDetails("ValidityStartDate", Common.DateTypeDetails(DateFractions.Date)));
	Renamings.Insert("expiration", ColumnDetails("ValidityEndDate", Common.DateTypeDetails(DateFractions.Date)));
	Renamings.Insert("prolongation_validity", ColumnDetails(
		"ProlongationSubscriptionPeriod", Common.TypeDescriptionNumber(10,, AllowedSign.Nonnegative)));
	Renamings.Insert("extension_validity", ColumnDetails(
		"ExtensionSubscriptionPeriod", Common.TypeDescriptionNumber(10,, AllowedSign.Nonnegative)));
	Renamings.Insert("prolongation_during", ColumnDetails(
		"PeriodForAddingRenewingSubscription", Common.TypeDescriptionNumber(10,, AllowedSign.Nonnegative)));
	Renamings.Insert("is_extension", ColumnDetails("TariffExpansion", New TypeDescription("Boolean")));
	Renamings.Insert("type", ColumnDetails("TariffType", New TypeDescription("EnumRef.TariffTypes")));
	Renamings.Insert("is_payable", ColumnDetails("Paid", New TypeDescription("Boolean")));
	Renamings.Insert("is_trial", ColumnDetails("Test_", New TypeDescription("Boolean")));
	Renamings.Insert("has_condition", ColumnDetails("ThereIsCondition", New TypeDescription("Boolean")));
	Renamings.Insert("payment_by_periods", ColumnDetails("PeriodicPayment", New TypeDescription("Boolean")));
	Renamings.Insert("periods_frequency", ColumnDetails("FrequencyOfPayment", Common.StringTypeDetails(10)));
	Renamings.Insert("validity_periods", ColumnDetails("ActionPeriods", New TypeDescription("ValueTable")));
	
	Return Renamings;

EndFunction

// Renaming tab. parts of the "Validity periods" of the "Tariff" object.
// 
// Returns:
// Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamesAndValidityPeriods() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Code", Common.StringTypeDetails(10)));
	Renamings.Insert("period", ColumnDetails("Periodicity", New TypeDescription("EnumRef.ValidityPeriodsFrequency")));
	Renamings.Insert("quantity", ColumnDetails("Count", Common.TypeDescriptionNumber(10,, AllowedSign.Nonnegative)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(50)));
	Renamings.Insert("cost", ColumnDetails("Sum", Common.TypeDescriptionNumber(31,2)));
	Renamings.Insert("comment", ColumnDetails("Comment", New TypeDescription("String")));
	
	Return Renamings;

EndFunction

// Renaming tab. parts of the "Extension"
// 
// Returns:
// Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function TariffExtensionsRenamings() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Code", Common.StringTypeDetails(9)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(150)));
	
	Return Renamings;

EndFunction

// Renaming the fields of the "Recommended rates" list.
// 
// Returns:
// Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingRecommendedRates() Export
	
	Renamings = New Map;
	Renamings.Insert("provider_tariff_id", ColumnDetails(
		"ProviderServicePlanCode", Common.StringTypeDetails(9)));
	Renamings.Insert("servant_tariff_id", ColumnDetails(
		"ServiceProviderPlanCode", Common.StringTypeDetails(9)));
	
	Return Renamings;
	
EndFunction

#EndRegion
 
#Region ServiceOrganizationTariff

// Renaming the object "Tariff of the service organization".
// 
// Parameters:
//  Method - String - name of the program interface method.
//  
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingServiceOrganizationRates(Method) Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Code", Common.StringTypeDetails(12)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(64)));
	Renamings.Insert("tariff_id", ColumnDetails("ProviderServicePlanCode", Common.StringTypeDetails(9)));
	Renamings.Insert("brief_description", ColumnDetails("ShortDescription", Common.StringTypeDetails(1024)));
	If Method = "account/servant_tariffs/info" Then
		Renamings.Insert("description_for_subscribers", ColumnDetails(
			"DescriptionForSubscribers", New TypeDescription("FormattedDocument")));
	EndIf; 
	Renamings.Insert("validity_periods", ColumnDetails("ActionPeriods", New TypeDescription("ValueTable")));
	
	Return Renamings;

EndFunction

// Renaming tab. parts of the "Validity periods" of the "Tariff of the service organization" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingServiceOrganizationTariffValidityPeriods() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Code", Common.StringTypeDetails(10)));
	Renamings.Insert("period", ColumnDetails("Periodicity", New TypeDescription("EnumRef.ValidityPeriodsFrequency")));
	Renamings.Insert("quantity", ColumnDetails("Count", Common.TypeDescriptionNumber(10,, AllowedSign.Nonnegative)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(50)));
	Renamings.Insert("cost", ColumnDetails("Sum", Common.TypeDescriptionNumber(31,2)));
	Renamings.Insert("recommended", ColumnDetails("Recommended_", New TypeDescription("Boolean")));
	Renamings.Insert("comment", ColumnDetails("Comment", New TypeDescription("String")));
	
	Return Renamings;

EndFunction

#EndRegion  

#Region ProformaInvoice

// Renaming the "Account" object.
// 
// Parameters:
//  Method - String
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function InvoiceRenamings(Method) Export
	
	Renamings = New Map;
	If Not (Method = "bill/update" Or Method = "bill/create") Then
		Renamings.Insert("id", ColumnDetails(
			"Number", Common.StringTypeDetails(9)));
		Renamings.Insert("created", ColumnDetails(
			"Date", Common.DateTypeDetails(DateFractions.DateTime)));
		Renamings.Insert("modified", ColumnDetails(
			"ChangeDate", Common.DateTypeDetails(DateFractions.DateTime)));
	EndIf; 
	Renamings.Insert("bill_id", ColumnDetails(
		"InvoiceId", New TypeDescription("UUID")));
	Renamings.Insert("seller_id", ColumnDetails(
		"SellerCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("customer_id", ColumnDetails(
		"BuyerSCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("total_cost", ColumnDetails(
		"Sum", Common.TypeDescriptionNumber(31, 2, AllowedSign.Nonnegative)));
	Renamings.Insert("renewal", ColumnDetails(
		"Renewal", New TypeDescription("Boolean")));
	Renamings.Insert("payment_link", ColumnDetails(
		"PaymentURL", Common.StringTypeDetails(1024)));
	Renamings.Insert("paid", ColumnDetails(
		"Paid", New TypeDescription("Boolean")));
	Renamings.Insert("add_info", ColumnDetails(
		"AdditionalInformation", New TypeDescription("String")));
	Renamings.Insert("comment", ColumnDetails(
		"Comment", New TypeDescription("String")));
		
	Return Renamings;
	
EndFunction

// Renaming tab. the "Tariffs" part of the "Invoice" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingInvoice() Export
	
	Renamings = New Map;
	Renamings.Insert("tariff_id", ColumnDetails("ProviderServicePlanCode", Common.StringTypeDetails(9)));
	Renamings.Insert("servant_tariff_id", ColumnDetails(
		"ServiceProviderPlanCode", Common.StringTypeDetails(9)));
	Renamings.Insert("period_id", ColumnDetails("ValidityPeriodCode", Common.StringTypeDetails(10)));
	Renamings.Insert("amount", ColumnDetails("Count", Common.TypeDescriptionNumber(10,0)));
	Renamings.Insert("cost", ColumnDetails("Sum", Common.TypeDescriptionNumber(31,2)));
	Renamings.Insert("basis_id", ColumnDetails("NumberOfBaseDocument", Common.StringTypeDetails(9)));
	
	Return Renamings;

EndFunction

// Renaming tab. parts of the "Services" of the "Invoice" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingServiceAccount() Export
	
	Renamings = New Map;
	Renamings.Insert("service", ColumnDetails("OperationService", Common.StringTypeDetails(1000)));
	Renamings.Insert("cost", ColumnDetails("Sum", Common.TypeDescriptionNumber(31,2)));
	
	Return Renamings;
	
EndFunction

// Renaming tab. the "Files" parts of the "Invoice" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountFiles() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Id", New TypeDescription("UUID")));
	Renamings.Insert("name", ColumnDetails("LongDesc", Common.StringTypeDetails(150)));
	
	Return Renamings;

EndFunction

// Renaming account status data.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountState() Export
	
	Renamings = New Map;
	Renamings.Insert("name", ColumnDetails("Name", Common.StringTypeDetails(17)));
	Renamings.Insert("error", ColumnDetails("Error", New TypeDescription("Boolean")));
	Renamings.Insert("description", ColumnDetails("LongDesc", New TypeDescription("String")));
	
	Return Renamings;
	
EndFunction

// Renaming the result of creating \changing the invoice.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAccountResultOfCreatingChange() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Number", Common.StringTypeDetails(9)));
	Renamings.Insert("bill_id", ColumnDetails("InvoiceId", New TypeDescription("UUID")));

	Return Renamings;
	
EndFunction

// Renaming the object "Download ticket" of the object "Invoice".
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingInvoiceDownloadCoupon() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Number", Common.StringTypeDetails(9)));
	Renamings.Insert("bill_id", ColumnDetails("InvoiceId", New TypeDescription("UUID")));
	Renamings.Insert("direction", ColumnDetails("DataTransferDirection", Common.StringTypeDetails(8)));
	Renamings.Insert("token", ColumnDetails("FileImportCoupon",  Common.StringTypeDetails(64)));
	Renamings.Insert("url", ColumnDetails("ImportURL", New TypeDescription("String")));
	
	Return Renamings;
	
EndFunction

// Renaming the data of the account creation/modification request.
// Parameters:
//  InvoiceData - See ServiceProgrammingInterface.NewInvoiceTemplate
//  Method - String - name of the program interface method
//  
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails 
Function RequestDataForCreatingAndModifyingInvoiceForPayment(InvoiceData, Method) Export
	
	QueryData = QueryTemplate(Method);
	Renamings = InvoiceRenamings(Method);
	For Each KeyValue In Renamings Do
		If Not InvoiceData.Property(KeyValue.Value.Name) Then
			Continue;
		EndIf; 
		Simple = InvoiceData[KeyValue.Value.Name];
		If KeyValue.Value.Type.ContainsType(Type("UUID")) Then
			Simple = String(Simple);
		EndIf; 
		QueryData.Insert(KeyValue.Key, Simple);		
	EndDo;
	If InvoiceData.Property("ServicePlans") Then
		Renamings = RenamingInvoice();
		QueryData.Insert("tariffs", TableOfValuesInArrayOfStructures(InvoiceData.ServicePlans, Renamings));
	EndIf; 
	If InvoiceData.Property("Services") Then
		Renamings = RenamingServiceAccount();
		QueryData.Insert("services", TableOfValuesInArrayOfStructures(InvoiceData.Services, Renamings));
	EndIf; 
	If InvoiceData.Property("Files") Then
		Renamings = RenamingAccountFiles();
		QueryData.Insert("files", TableOfValuesInArrayOfStructures(InvoiceData.Files, Renamings));
	EndIf; 
	If InvoiceData.Property("AdditionalAttributes") Then
		Renamings = RenamingAdditionalInformation(False);
		QueryData.Insert("fields", TableOfValuesInArrayOfStructures(
			InvoiceData.AdditionalAttributes, Renamings));
	EndIf;
	
	Return QueryData;

EndFunction

#EndRegion

#Region Application

// Renaming the "Application" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingApp() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails(
		"Code", Common.TypeDescriptionNumber(7, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("name", ColumnDetails(
		"Description", Common.StringTypeDetails(100)));
	Renamings.Insert("owner", ColumnDetails(
		"SubscriberOwnerCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("application", ColumnDetails(
		"ConfigurationCode", Common.StringTypeDetails(22)));
	Renamings.Insert("app_version", ColumnDetails(
		"ConfigurationVersion", Common.StringTypeDetails(18)));
	Renamings.Insert("app_name", ColumnDetails(
		"ConfigurationDescription", Common.StringTypeDetails(64)));
	Renamings.Insert("apptype_id", ColumnDetails(
		"AppTypeCode", Common.StringTypeDetails(22)));
	Renamings.Insert("apptype_name", ColumnDetails(
		"AppTypeName", Common.StringTypeDetails(255)));
	Renamings.Insert("apptype_presentation", ColumnDetails(
		"NameOfAppType", Common.StringTypeDetails(150)));
	Renamings.Insert("status", ColumnDetails(
		"ApplicationState", New TypeDescription("EnumRef.ApplicationsStates")));
	Renamings.Insert("url", ColumnDetails(
		"ApplicationURL", Common.StringTypeDetails(500)));
	Renamings.Insert("user_language", ColumnDetails(
		"UserLanguageCode", Common.StringTypeDetails(10)));
	Renamings.Insert("timezone", ColumnDetails(
		"TimeZone", Common.StringTypeDetails(100)));
	Renamings.Insert("platform", ColumnDetails(
		"PlatformVersion", Common.StringTypeDetails(18)));
	Renamings.Insert("size", ColumnDetails(
		"ApplicationSize", Common.TypeDescriptionNumber(15, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("size_calc_date", ColumnDetails(
		"CalculationAppSizeDate", Common.DateTypeDetails(DateFractions.DateTime)));

	Return Renamings;
	
EndFunction

// Renaming the "Backup Copy of the Application" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingApplicationBackups() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails(
		"BackupIdentificator", Common.StringTypeDetails(36)));
	Renamings.Insert("timestamp", ColumnDetails(
		"BackupTimestamp", Common.DateTypeDetails(DateFractions.DateTime)));
	Renamings.Insert("for_support", ColumnDetails(
		"ForTechSupport", New TypeDescription("Boolean")));
	
	Return Renamings;
	
EndFunction
 
#EndRegion

#Region UserTask

// Renaming the "User Task" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingUserTask() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails(
		"Number", Common.StringTypeDetails(32)));
	Renamings.Insert("name", ColumnDetails(
		"TaskDescription", New TypeDescription("String")));
	Renamings.Insert("created", ColumnDetails(
		"Date", Common.DateTypeDetails(DateFractions.DateTime)));
	Renamings.Insert("author", ColumnDetails(
		"AuthorAsString", New TypeDescription("String")));
	
	Return Renamings;
	
EndFunction

#Region ApplicationKind

// Renaming the "Transition option" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAppTypesUpgradeOptions() Export
	
	Renamings = New Map;
	
	Renamings.Insert("conf_version", ColumnDetails(
		"ConfigurationVersionNumber", Common.StringTypeDetails(18)));
	Renamings.Insert("apptype_original_id", ColumnDetails(
		"PreviousAppTypeCode", Common.StringTypeDetails(22)));
	Renamings.Insert("apptype_id", ColumnDetails(
		"AppTypeCode", Common.StringTypeDetails(22)));
	Renamings.Insert("apptype_name", ColumnDetails(
		"AppTypeName", Common.StringTypeDetails(255)));
	Renamings.Insert("apptype_presentation", ColumnDetails(
		"NameOfAppType", Common.StringTypeDetails(150)));
	
	Return Renamings;
	
EndFunction

#EndRegion

#Region AdditionalInfo

// Renaming the list of additional information.
// 
// Parameters:
//  AddTitle_ - Boolean - indicates whether to add the additional information header to the renaming parameters.
//  
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingAdditionalInformation(AddTitle_ = True) Export
	
	Renamings = New Map;
	Renamings.Insert("key", ColumnDetails("Key", Common.StringTypeDetails(100)));
	If AddTitle_ Then
		Renamings.Insert("name", ColumnDetails("Title", Common.StringTypeDetails(150)));
	EndIf;
	Renamings.Insert("type", ColumnDetails("Type", Common.StringTypeDetails(50)));
	Renamings.Insert("value", ColumnDetails("Value", DescriptionOfValueTypesForAdditionalInformation()));
	
	Return Renamings;
	
EndFunction

// Data constructor for additional information.
// 
// Returns:
//  ValueTable - New Additional Information:
// * Key - String
// * Type - String
// * Value - See DescriptionOfValueTypesForAdditionalInformation
Function NewAdditionalInformation() Export
	
	AdditionalInfo = New ValueTable;
	AdditionalInfo.Columns.Add("Key", Common.StringTypeDetails(100));
	AdditionalInfo.Columns.Add("Type", Common.StringTypeDetails(50));
	AdditionalInfo.Columns.Add("Value", DescriptionOfValueTypesForAdditionalInformation());

	Return AdditionalInfo

EndFunction

// Representations of value types of additional information.
// 
// Returns:
//  ValueList of String
Function PresentationsOfValueTypesForAdditionalInformation() Export
	
	TypesPresentation1 = New ValueList;
    TypesPresentation1.Add("string", NStr("vi = 'Xâu ký tự';
											|ru = 'Строка';
											|en = 'String'; fa = 'رشته';
											|it = 'Riga';
											|pl = 'String';
											|tr = 'Satır'"));
    TypesPresentation1.Add("decimal", NStr("vi = 'Số';
											|ru = 'Число';
											|en = 'Number'; fa = 'شماره';
											|it = 'Numero';
											|pl = 'Number';
											|tr = 'Sayı'"));
    TypesPresentation1.Add("date", NStr("vi = 'Ngày';
										|ru = 'Дата';
										|en = 'Date'; fa = 'تاریخ';
										|it = 'Data';
										|pl = 'Date';
										|tr = 'Tarih'"));
    TypesPresentation1.Add("boolean", NStr("vi = 'Boolean';
											|ru = 'Булево';
											|en = 'Boolean'; fa = 'بولی';
											|it = 'Variabile booleana';
											|pl = 'Boolean';
											|tr = 'Boolean'"));
    TypesPresentation1.Add("subscriber", NStr("vi = 'Danh sách ""Thuê bao""';
												|ru = 'Справочник ""Абоненты""';
												|en = 'The ""Subscribers"" catalog'; fa = 'The ""Subscribers"" catalog';
												|it = 'Directory ""Abbonati""';
												|pl = 'Katalog ""Sybskrybenci""';
												|tr = '""Aboneler"" kataloğu'"));
    TypesPresentation1.Add("service", NStr("vi = 'Danh sách ""Dịch vụ""';
											|ru = 'Справочник ""Услуги""';
											|en = 'The ""Services"" catalog'; fa = 'The ""Services"" catalog';
											|it = 'Directory ""Servizi""';
											|pl = 'Katalog ""Usługi""';
											|tr = '""Hizmetler"" kataloğu'"));
    TypesPresentation1.Add("additional_value", NStr("vi = 'Danh mục ""Giá trị bổ sung""';
													|ru = 'Справочник ""Дополнительные значения""';
													|en = 'The ""Additional values"" catalog'; fa = 'The ""Additional values"" catalog';
													|it = 'Directory ""Valori aggiuntivi""';
													|pl = 'Katalog ""Wartości dodatkowe""';
													|tr = '""Ek değerler"" kataloğu'"));
    TypesPresentation1.Add("additional_value_group", NStr("vi = 'Danh mục ""Giá trị bổ sung (phân nhánh)""';
															|ru = 'Справочник ""Дополнительные значения (иерархия)""';
															|en = 'The ""Additional values (hierarchy)"" catalog'; fa = 'The ""Additional values (hierarchy)"" catalog';
															|it = 'Directory ""Valori aggiuntivi (gerarchia)""';
															|pl = 'Katalog ""Wartości dodatkowe (hierarchia)""';
															|tr = '""Ek değerler (hiyerarşi)"" kataloğu'"));
    TypesPresentation1.Add("tariff", NStr("vi = 'Danh mục ""Biểu phí""';
											|ru = 'Справочник ""Тарифы""';
											|en = 'The ""Service plans"" catalog'; fa = 'The ""Service plans"" catalog';
											|it = 'Directory ""Tariffe""';
											|pl = 'Katalog ""Taryfy""';
											|tr = '""Servis planı"" kataloğu'"));
    TypesPresentation1.Add("service_provider_tariff", NStr("vi = 'Danh mục ""Biểu phí nhà cung cấp dịch vụ""';
															|ru = 'Справочник ""Тарифы поставщиков услуг""';
															|en = 'The ""Service plan of service providers"" catalog'; fa = 'The ""Service plan of service providers"" catalog';
															|it = 'Directory ""Tariffe dei fornitori dei servizi""';
															|pl = 'Katalog ""Taryfy dostawców usług""';
															|tr = '""Hizmet tedarikçi servis planları"" kataloğu'"));
    TypesPresentation1.Add("user", NStr("vi = 'Danh mục ""Người sử dụng""';
										|ru = 'Справочник ""Пользователи""';
										|en = 'The ""Users"" catalog'; fa = 'The ""Users"" catalog';
										|it = 'Directory ""Utenti""';
										|pl = 'Katalog ""Użytkownicy""';
										|tr = '""Kullanıcılar"" kataloğu'"));
    TypesPresentation1.Add("tariff_period", NStr("vi = 'Danh mục ""Kỳ biểu phí""';
												|ru = 'Справочник ""Периоды тарифов""';
												|en = 'The ""Periods of service plans"" catalog'; fa = 'The ""Periods of service plans"" catalog';
												|it = 'Directory ""Periodi tariffe""';
												|pl = 'Katalog ""Okresy taryf""';
												|tr = '""Servis planı dönemleri"" kataloğu'"));
    TypesPresentation1.Add("subscription", NStr("vi = 'Chứng từ ""Đăng ký""';
												|ru = 'Документ ""Подписка""';
												|en = 'The ""Subscription"" document'; fa = 'The ""Subscription"" document';
												|it = 'Documento ""Firma""';
												|pl = 'Dokument ""Subskrypcja""';
												|tr = '""Abonelik"" belgesi'"));
	
	Return TypesPresentation1;
	
EndFunction

// Description of the types of additional information values.
// 
// Returns:
//  TypeDescription
Function DescriptionOfValueTypesForAdditionalInformation() Export
	
	ValueTypes = New Array;
	ValueTypes.Add("Number");
	ValueTypes.Add("String");
	ValueTypes.Add("Date");
	ValueTypes.Add("Boolean");
	
	Return New TypeDescription(ValueTypes);

EndFunction

// Converts date fields in additional Attributes from a string to a date.
//
// Parameters:
//   AdditionalAttributes - See NewAdditionalInformation
Function ProcessDateInAdditionalAttributes(AdditionalAttributes) Export
	
	For Each AdditionalAttribute In AdditionalAttributes Do
		
		If AdditionalAttribute.Type = "date" Then
			AdditionalAttribute.Value = ReadJSONDate(AdditionalAttribute.Value, JSONDateFormat.ISO);
		EndIf;
		
	EndDo;
	
EndFunction

#EndRegion

#EndRegion

#Region Sessions

// Renaming the "File" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingsFileProperties() Export
	
	Renamings = New Map;
	
	Renamings.Insert("name", ColumnDetails(
		"FileName", Common.StringTypeDetails(255)));
	Renamings.Insert("size", ColumnDetails(
		"Size", Common.TypeDescriptionNumber(15, 0, AllowedSign.Nonnegative)));
	
	Return Renamings;
	
EndFunction

// Renaming the "Archive Copy data" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingsArchiveCopyData() Export
	
	Renamings = New Map;
	
	Renamings.Insert("conf_name", ColumnDetails(
		"ConfigurationName", Common.StringTypeDetails(255)));
	Renamings.Insert("conf_presentation", ColumnDetails(
		"ConfigurationDescription", Common.StringTypeDetails(255)));
	Renamings.Insert("apptype_id", ColumnDetails(
		"AppTypeCode", Common.StringTypeDetails(22)));
	Renamings.Insert("apptype_presentation", ColumnDetails(
		"NameOfAppType", Common.StringTypeDetails(255)));
	Renamings.Insert("app_version", ColumnDetails(
		"ConfigurationVersion", Common.StringTypeDetails(18)));
	
	Return Renamings;
	
EndFunction

// Renaming the "Archive Useris" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingsUsersFromArchive() Export
	
	Renamings = New Map;
	
	Renamings.Insert("login", ColumnDetails(
		"Login", Common.StringTypeDetails(50)));
	Renamings.Insert("name", ColumnDetails(
		"FullName", Common.StringTypeDetails(150)));
	Renamings.Insert("user_id", ColumnDetails(
		"UserIdentificator", Common.StringTypeDetails(36)));
	
	Return Renamings;
	
EndFunction

// Renaming the "Archive Extensions" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingsExtensionFromArchive() Export
	
	Renamings = New Map;
	
	Renamings.Insert("id", ColumnDetails(
		"Name", Common.StringTypeDetails(260)));
	Renamings.Insert("description", ColumnDetails(
		"Description", Common.StringTypeDetails(100)));
	Renamings.Insert("version", ColumnDetails(
		"Version", Common.StringTypeDetails(18)));
	Renamings.Insert("version_uuid", ColumnDetails(
		"UUID", New TypeDescription("UUID")));
	Renamings.Insert("changes_data_structure", ColumnDetails(
		"ModifiesDataStructure", New TypeDescription("Boolean")));
	
	Return Renamings;
	
EndFunction

#EndRegion

#Region Files

// Renaming the "Session" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingsSession() Export
	
	Renamings = New Map;
	Renamings.Insert("tenant", ColumnDetails(
		"AreaNumber", Common.TypeDescriptionNumber(7, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("tenant_name", ColumnDetails(
		"AreaDescription", Common.StringTypeDetails(100)));
	Renamings.Insert("user", ColumnDetails(
		"UserName", Common.StringTypeDetails(100)));
	Renamings.Insert("start", ColumnDetails(
		"SessionStarted", Common.DateTypeDetails(DateFractions.DateTime)));
	Renamings.Insert("id", ColumnDetails(
		"SessionNumber", Common.TypeDescriptionNumber(10, 0, AllowedSign.Any)));
	Renamings.Insert("application", ColumnDetails(
		"ApplicationName", Common.StringTypeDetails(20)));
	Renamings.Insert("sleeping", ColumnDetails(
		"Sleep", New TypeDescription("Boolean")));
	Renamings.Insert("IP", ColumnDetails(
		"IPAddress", Common.StringTypeDetails(15)));
	
	Return Renamings;
	
EndFunction

#EndRegion

#Region Configuration

// Renaming the "Configuration" object.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ColumnDetails
Function RenamingsConfiguration() Export
	
	Renamings = New Map;
	Renamings.Insert("id", ColumnDetails("Code", Common.StringTypeDetails(22)));
	Renamings.Insert("name", ColumnDetails("Description", Common.StringTypeDetails(64)));
	Renamings.Insert("sysname", ColumnDetails("Name", Common.StringTypeDetails(255)));
	Renamings.Insert("description", ColumnDetails("LongDesc", Common.StringTypeDetails(0)));
	Renamings.Insert("icon", ColumnDetails("Picture", Common.StringTypeDetails(0)));
	Renamings.Insert("account", ColumnDetails("SubscriberCode", 
		Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	
	Return Renamings;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function ValueByType(ValueType, Value)
	
	If ValueType.ContainsType(Type("UUID")) Then
		Return New UUID(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.ServicesTypes")) Then
		Return Enums.ServicesTypes.ValueByName(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.ValidityPeriodsFrequency")) Then
		Return Enums.ValidityPeriodsFrequency.ValueByName(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.ApplicationsStates")) Then
		Return Enums.ApplicationsStates.ValueByName(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.ServiceSubscriptionsTypes")) Then
		Return Enums.ServiceSubscriptionsTypes.ValueByName(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.ApplicationUserRights")) Then
		Return Enums.ApplicationUserRights.ValueByName(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.SubscriberUsersRoles")) Then
		Return Enums.SubscriberUsersRoles.ValueByName(Value);
	ElsIf ValueType.ContainsType(Type("EnumRef.TariffTypes")) Then
		Return Enums.TariffTypes.ValueByName(Value);
	Else
		Return Value;
	EndIf;
	
EndFunction
 
// Returns the description of the column of the field renaming table.
// 
// Parameters:
//	Name - String - name of the rename.
//	Type - TypeDescription - the type of value.
//	
// Returns:
//	Structure:
//	 * Name - String - name of the rename.
//	 * Type - TypeDescription - the type of value.
Function ColumnDetails(Name, Type) Export

	Return New Structure("Name, Type", Name, Type);

EndFunction

#EndRegion
