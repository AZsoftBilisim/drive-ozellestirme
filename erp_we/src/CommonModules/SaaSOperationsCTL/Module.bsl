////////////////////////////////////////////////////////////////////////////////
// Subsystem "Basic functionality in the service model".
// General-purpose server procedures and functions:
// - Support for working in the service model.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates the signature of the transmitted data using the passed key using the HMAC-SHA256 algorithm.
//
// Parameters:
//   Var_Key - BinaryData - binary data of the signature key.
//   Data - String - signed data.
//
// Returns:
//   String - signature in Base64 format.
//
Function Signature(Var_Key, Data) Export
	
	Return Base64String(HMACSHA256(Var_Key, GetBinaryDataFromString(Data)));
	
EndFunction

#EndRegion 

#Region Internal

// Returns HMACSHA-256
// 
// Parameters: 
//  Var_Key - BinaryData
//  Data - BinaryData
// 
// Returns:
//  BinaryData
Function HMACSHA256(Val Var_Key, Val Data) Export
	
	Return HMAC(Var_Key, Data, HashFunction.SHA256, 64);
	
EndFunction

// Parameters: 
//  Data - Structure
// 
// Returns: 
//  String - a string from a JSON structure.
Function StringFromJSONStructure(Data) Export
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Data, , "ConvertingJSONValues", SaaSOperationsCTL);
	Return JSONWriter.Close();
	
EndFunction

// Parameters:
// 	String - String - a string in JSON format.
// 	DateTypeProperties - Array of String - names of properties with the "Date" type.
// 
// Returns:
// 	Arbitrary, Structure - the resulting Structure:
// 	* Field - Arbitrary - custom set of fields
//
Function StructureFromJSONString(String, DateTypeProperties = Undefined) Export
	
	JSONReader = New JSONReader;
	JSONReader.SetString(String);
	Response = ReadJSON(JSONReader,, DateTypeProperties, JSONDateFormat.ISO); 
	Return Response;
	
EndFunction

// Parameters:
// 	DataStream - FileStream, MemoryStream - data flow.
// 	DateTypeProperties - Array of String - names of properties with the "Date" type.
// 
// Returns:
// 	Arbitrary, Structure - the resulting Structure:
// 	* Field - Arbitrary - custom set of fields
//
Function StructureFromJSONStream(DataStream, DateTypeProperties = Undefined) Export
	
	JSONReader = New JSONReader;
	JSONReader.OpenStream(DataStream);
	Response = ReadJSON(JSONReader, , DateTypeProperties, JSONDateFormat.ISO);
	JSONReader.Close();
	Return Response;
	
EndFunction

// Sends data to the specified address to the service Manager.
//
// Parameters:
//  Method - String - name of the HTTP method for the request according to the RFC7230 standard (https://tools.ietf.org/html/rfc7230).
//  Address  - String - the address to which data is sent, such as "hs/ext_api/execute".
//  Data - Structure - data sent to the service Manager.
//  ConnectionCache - Boolean - use the connection cache when sending requests.
//  Timeout - String - waiting time for a response from the service manager.
// 
// Returns:
//  HTTPResponse - the response of the HTTP service of the Service Manager. 
//
Function SendRequestToServiceManager(Method, Address, Val Data = Undefined, ConnectionCache = True, Timeout = 60) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	FullAddress = StrTemplate("%1/%2", SaaSOperations.InternalServiceManagerURL(), Address);

	ServerData = CommonClientServer.URIStructure(FullAddress);

	If ConnectionCache Then
		Join = SaaSOperationsCTLCached.ConnectingToServiceManager(ServerData, Timeout);
	Else
		Join = ConnectingToServiceManager(ServerData, Timeout);
	EndIf;

	Query = New HTTPRequest(ServerData.PathAtServer);
	Query.Headers.Insert("Content-Type", "application/json; charset=utf-8");

	If TypeOf(Data) = Type("Structure") Then
		Data = StringFromJSONStructure(Data);
		Query.SetBodyFromString(Data);
	ElsIf TypeOf(Data) = Type("BinaryData") Then
		Query.SetBodyFromBinaryData(Data);
	ElsIf TypeOf(Data) = Type("String") Then
		Query.SetBodyFromString(Data);
	EndIf;

	Return Join.CallHTTPMethod(Method, Query);

EndFunction
 
// Returns the HTTP connection to the Service Manager.
// The calling code must independently set the privileged mode.
//
// Parameters:
//	ServerData - Structure - see the General purpose of the Clientserver.Structururi
//	Timeout - Number - waiting time for a response from the server
//	Access Token - String - user access token
// 
// Returns:
//  HTTPConnection - connection with the Service Manager.
//
Function ConnectingToServiceManager(ServerData, Timeout = 60) Export

	SSLScheme = "https";
	If Lower(ServerData.Schema) = SSLScheme Then
		SecureConnection =  CommonClientServer.NewSecureConnection();
	Else
		SecureConnection = Undefined;
	EndIf;

	SetSafeModeDisabled(True);
	Join = New HTTPConnection(ServerData.Host, ServerData.Port,
		SaaSOperations.ServiceManagerInternalUserName(),
		SaaSOperations.ServiceManagerInternalUserPassword(),
		GetFilesFromInternet.GetProxy(ServerData.Schema), Timeout, SecureConnection);
	
	Return Join;

EndFunction

// Template for the parameters of the "Attach Data Area" action.
// 
// Returns:
//  Structure:
//   * ApplicationTimeZone - Undefined
//   * ApplicationPresentation - Undefined
//   * UsersList - Undefined
//   * DataAreaCode - Undefined
//   * ApplicationKind - Undefined
//   * SubscriberCode - Undefined
Function NewActionOptionsAttachDataArea() Export
	
	Parameters = New Structure;
	Parameters.Insert("DataAreaCode", Undefined);
	Parameters.Insert("UsersList", Undefined);
	Parameters.Insert("ApplicationPresentation", Undefined);
	Parameters.Insert("ApplicationTimeZone", Undefined);
	Parameters.Insert("ApplicationKind", Undefined);
	Parameters.Insert("SubscriberCode", Undefined);
	
	Return Parameters;
	
EndFunction

// Returns the domain user by the service user ID.
// 
// Parameters: 
//  ServiceUserID - UUID
// 
// Returns:
//  CatalogRef.Users - the received user.
Function DomainUserByServiceUserID(Val ServiceUserID) Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Users.Ref AS Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.ServiceUserID = &ServiceUserID";
	Query.SetParameter("ServiceUserID", ServiceUserID);
	
	Block = New DataLock;
	Block.Add("Catalog.Users");
	
	BeginTransaction();
	Try
		Block.Lock();
		Result = Query.Execute();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Result.IsEmpty() Then
		MessageTemplate = NStr("vi = 'Chưa tìm thấy người sử dụng có tên định danh của người sử dụng dịch vụ %1';
								|ru = 'Не найден пользователь с идентификатором пользователя сервиса %1';
								|en = 'The user with service user ID %1 is not found'; fa = 'The user with service user ID %1 is not found';
								|it = 'Nessun utente trovato con ID utente del servizio %1';
								|pl = 'Nie znaleziono użytkownika o identyfikatorze użytkownika usługi %1';
								|tr = '%1 servisinin kullanıcı kimliğine sahip kullanıcı bulunamadı'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ServiceUserID);
		Raise(MessageText);
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.Ref;
	
EndFunction

// Called when the Service Manager endpoint is installed.
// @skip-warning EmptyMethod - a feature of the implementation.
// @skip-check module-empty-method
Procedure OnSetServiceManagerEndpoint() Export
EndProcedure

#EndRegion

#Region Private

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
//  Handlers - ValueTable - description of fields 
//                                   see the procedure for updating the information database.New Update processing table.
//
// Example:
//  Adding a handler to the list.
//  Handler = Handlers.Add();
//  Handler.Version = "1.0.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_0_0_0";
//  Handler.Monopoly Mode = False;
//  Handler.Optional = True;
// 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If Common.DataSeparationEnabled() Then
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.Procedure = "SaaSOperationsCTL.CreateUnsharedPredefinedElements";
		Handler.Priority = 99;
		Handler.SharedData = True;
		Handler.ExclusiveMode = False;
				
				
		
	EndIf;
	
EndProcedure

// Fills in the split data handler that depends on changes to the undivided data.
//
// Parameters:
//   Parameters - Structure - structure of handler parameters:
//     * SeparatedHandlers - See InfobaseUpdate.NewUpdateHandlerTable
// 
Procedure FillSeparatedDataHandlers(Parameters = Undefined) Export
	
	
EndProcedure

// Called when data separation by data area is enabled.
//
Procedure OnEnableSeparationByDataAreas() Export
	
	CreateUnsharedPredefinedElements();
	
EndProcedure

// Generates a list of information security parameters.
//
// Parameters:
// ParametersTable - See SaaSOperations.IBParameters
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "MasterApplicationExternalAddress");
	
EndProcedure

// Handler for creating / updating predefined elements
// of undivided metadata objects.
//
Procedure CreateUnsharedPredefinedElements() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		
		Raise NStr("vi = 'Có thể thực hiện thao tác chỉ trong phiên làm việc mà chưa thiết lập giá trị đường chia tách';
					|ru = 'Операция может быть выполнена только в сеансе, в котором не установлены значения разделителей';
					|en = 'Operation can only be performed in a session without specified separator values'; fa = 'Operation can only be performed in a session without specified separator values';
					|it = 'L''operazione può essere completata soltanto in una sessione in cui i valori dei separatori non sono impostati';
					|pl = 'Operacja może być wykonana tylko w sesji, w której nie ustalono wartości separatorów';
					|tr = 'İşlem yalnızca ayırıcı değerleri ayarlanmamış bir oturumda gerçekleştirilebilir.'");
		
	EndIf;
	
	InitializePredefinedData();
	
EndProcedure

// Handler for creating/updating access groups of supplied profiles
// Parameters:
//  Parameters - Arbitrary
Procedure UpdateAccessGroupsOfSuppliedProfiles(Parameters = Undefined) Export
EndProcedure

// Called when generating the configuration manifest.
//
// Parameters:
//  AdvancedInformation - Array of XDTODataObject - inside the handler procedure, you need
//    to add objects of the Objectxdto type to this array with the xdto Type inherited from
//    {http://www.1c.ru/1cFresh/Application/Manifest/a.b.c.d}ExtendedInfoItem.
//
Procedure OnGenerateConfigurationManifest(AdvancedInformation) Export
	
	If TransactionActive() Then
		Raise NStr("vi = 'Giao dịch không thể thực hiện khi giao tác ngoài đang kích hoạt';
					|ru = 'Операция не может быть выполнена при активной внешней транзакции';
					|en = 'Operation cannot be completed when an external transaction is active'; fa = 'Operation cannot be completed when an external transaction is active';
					|it = 'L''operazione non può essere completata con una transazione esterna attiva';
					|pl = 'Operacja nie może być wykonana przy aktywnej transakcji zewnętrznej';
					|tr = 'Harici bir işlem etkinken işlem gerçekleştirilemez'");
	EndIf;
	
	CallInUndividedIB = Not Common.DataSeparationEnabled();
	
	BeginTransaction();
	
	Try
		
		PermissionsDetails = XDTOFactory.Create(
			XDTOFactory.Type("http://www.1c.ru/1cFresh/Application/Permissions/Manifes/1.0.0.1", "RequiredPermissions"));
		
		AddInsDetails = XDTOFactory.Create(
			XDTOFactory.Type("http://www.1c.ru/1cFresh/Application/Permissions/Manifes/1.0.0.1", "Addins"));
		
		TemplatesForExternalComponents = New Map();
		UseSeparationByDataAreas = Constants.UseSeparationByDataAreas.Get();
		DisableSeparationByDataAreas = False;
		
		If CallInUndividedIB Then
			
			If Not UseSeparationByDataAreas Then
				Constants.UseSeparationByDataAreas.Set(True);
				DisableSeparationByDataAreas = True;
			EndIf; 
			
			RefreshReusableValues();
			
		EndIf;
		
		Constants.UseSecurityProfiles.Set(True);
		Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Set(True);
		
		RequestsIDs = SafeModeManager.RequestsToUpdateApplicationPermissions();
		
		ApplicationManager = SafeModeManagerInternalSaaS.PermissionsApplicationManager(RequestsIDs);
		Delta = ApplicationManager.DeltaIgnoringOwners();
		
		TemplatesForExternalComponents = New Array();
		
		For Each DeltaElement In Delta.ItemsToAdd Do
			
			For Each KeyAndValue In DeltaElement.Permissions Do
				
				Resolution = Common.XDTODataObjectFromXMLString(KeyAndValue.Value);
				PermissionsDetails.Permission.Add(Resolution);
				
				If Resolution.Type() = XDTOFactory.Type("http://www.1c.ru/1cFresh/Application/Permissions/1.0.0.1", "AttachAddin") Then
					TemplatesForExternalComponents.Add(Resolution.TemplateName);
				EndIf;
				
			EndDo;
			
		EndDo;
		
		For Each TemplateName In TemplatesForExternalComponents Do
			
			AddInDetails = XDTOFactory.Create(XDTOFactory.Type("http://www.1c.ru/1cFresh/Application/Permissions/Manifes/1.0.0.1", "AddinBundle"));
			AddInDetails.TemplateName = TemplateName;
			
			FilesDetails1 = SafeModeManager.AddInBundleFilesChecksum(TemplateName);
			
			For Each KeyAndValue In FilesDetails1 Do
				
				FileDetails = XDTOFactory.Create(XDTOFactory.Type("http://www.1c.ru/1cFresh/Application/Permissions/Manifes/1.0.0.1", "AddinFile"));
				FileDetails.FileName = KeyAndValue.Key;
				FileDetails.Hash = KeyAndValue.Value;
				
				AddInDetails.Files.Add(FileDetails);
				
			EndDo;
			
			AddInsDetails.Bundles.Add(AddInDetails);
			
		EndDo;
		
		AdvancedInformation.Add(PermissionsDetails);
		AdvancedInformation.Add(AddInsDetails);
		
		If DisableSeparationByDataAreas Then
			Constants.UseSeparationByDataAreas.Set(False);
		EndIf; 
		
	Except
		
		RollbackTransaction();
		If CallInUndividedIB Then
			RefreshReusableValues();
		EndIf;
		
		Raise;
		
	EndTry;
	
	RollbackTransaction();
	If CallInUndividedIB Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Returns the internal address of the service Manager.
//
// Returns:
//  String - internal address of the service Manager.
//
Function InternalServiceManagerURL() Export
	
	Return Constants.InternalServiceManagerURL.Get();
	
EndFunction

// Sets the internal address of the service Manager.
//
// Parameters:
//  Value - String - internal address of the service Manager.
//
Procedure SetInternalAddressOfServiceManager(Val Value) Export
	
	Constants.InternalServiceManagerURL.Set(Value);
	
EndProcedure

// Returns the address of the authentication provider.
//
// Returns:
//  String - the address of the authentication provider.
//
Function AuthenticationProviderURL() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Return Constants.AuthenticationProviderURL.Get();
	
EndFunction

// Returns a sign of authentication with the access token for internal calls to the program interface.
// 
// Returns:
//  Boolean
Function AccessTokenAuthenticationOfInternalAPIRequests() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Return Constants.AccessTokenAuthenticationOfInternalAPIRequests.Get();
	
EndFunction

// Sets the address of the authentication provider.
//
// Parameters:
//  Value - String - the address of the authentication provider.
//
Procedure SetAuthenticationProviderURL(Val Value) Export
	
	Constants.AuthenticationProviderURL.Set(Value);
	
EndProcedure

Procedure SetAccessTokenAuthenticationOfInternalAPIRequests(Val Value) Export
	
	Constants.AccessTokenAuthenticationOfInternalAPIRequests.Set(Value);
	
EndProcedure

// Returns the name of the service manager service user.
// The calling code must independently set the privileged mode.
//
// Returns:
//  String - the name of the service manager's service user.
//
Function ServiceManagerInternalUserName() Export
	
	Owner = Common.MetadataObjectID("Constant.InternalServiceManagerURL");
	InternalUsername = Common.ReadDataFromSecureStorage(Owner, "ServiceManagerInternalUserName", True);
	
	Return InternalUsername;
	
EndFunction

// Returns the service manager service user password.
// The calling code must independently set the privileged mode.
//
// Returns:
//  String - the password of the service manager's service user.
//
Function ServiceManagerInternalUserPassword() Export
	
	Owner = Common.MetadataObjectID("Constant.InternalServiceManagerURL");
	InternalUserPassword = Common.ReadDataFromSecureStorage(Owner, "ServiceManagerInternalUserPassword", True);
	
	Return InternalUserPassword;
	
EndFunction

// Returns the endpoint for sending messages to the service Manager.
//
// Returns:
//  ExchangePlanRef.MessagesExchange - the node corresponding to the service manager.
//
Function ServiceManagerEndpoint() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Return Constants.ServiceManagerEndpoint.Get();
	
EndFunction

// Parameters: 
//  LanguageCode - String
// 
// Returns: 
//  String - Language by code.
//
Function LanguageByCode(Val LanguageCode) Export
	
	If ValueIsFilled(LanguageCode) Then
		
		For Each Language In Metadata.Languages Do
			If Language.LanguageCode = LanguageCode Then
				Return Language.Name;
			EndIf;
		EndDo;
		
		MessageTemplate = NStr("vi = 'Không hỗ trợ mã ngôn ngữ: %1';
								|ru = 'Неподдерживаемый код языка: %1';
								|en = 'Unsupported language code: %1'; fa = 'Unsupported language code: %1';
								|it = 'Codice di linguaggio non supportato: %1';
								|pl = 'Nieobsługiwany kod języka: %1';
								|tr = 'Desteklenmeyen kod dili: %1'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, LanguageCode);
		Raise(MessageText);
		
	Else
		
		Return Metadata.DefaultLanguage.Name;
		
	EndIf;
	
EndFunction

// Composition of the postal address
// 
// Parameters: 
//  EMAddress - String -EP address
// 
// Returns:
// Structure: 
//   * Status - Boolean - the success or failure of the conversion.
//   * Value - Array of Structure:
//    ** Address - String - recipient's e-mail address.
//    ** Presentation - String - recipient's name.
//   * ErrorMessage - String - (this parameter is available if Status = False) error information.
// (See CommonClientServer.ParseStringWithEmailAddresses.)
Function CompositionOfPostalAddress(Val EMAddress) Export
	
	If ValueIsFilled(EMAddress) Then
		
		Try
			ItemInstanceAddressStructure = CommonClientServer.ParseStringWithEmailAddresses(EMAddress);
		Except
			MessageTemplate = NStr("vi = 'Đã chỉ định địa chỉ E-mail không hợp lệ: %1
				|Lỗi: %2';
				|ru = 'Указан некорректный адрес электронной почты: %1
				|Ошибка: %2';
				|en = 'Invalid email address: %1
				|Error: %2'; fa = 'Invalid email address: %1
				|Error: %2';
				|it = 'L''indirizzo di posta elettronica indicato è errato: %1
				|Errore: %2';
				|pl = 'Podano nieprawidłowy adres e-mail: %1
				|Błąd: %2';
				|tr = 'Hatalı e-posta adresi belirtilmiş: %1
				|Hata: %2'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, EMAddress, ErrorInfo().Description);
			Raise(MessageText);
		EndTry;
		
		Return ItemInstanceAddressStructure;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Procedure UpdateEmailAddress(Val UserObject, Val Address, Val ItemInstanceAddressStructure) Export
	
	CIKind = Catalogs.ContactInformationKinds.UserEmail;
	
	If ItemInstanceAddressStructure = Undefined Then
		LineOfATabularSection = UserObject.ContactInformation.Find(CIKind, "Kind");
		If LineOfATabularSection <> Undefined Then
			UserObject.ContactInformation.Delete(LineOfATabularSection);
		EndIf;
	Else
		ContactsManager.AddContactInformation(UserObject, Address, CIKind);
	EndIf;
	
EndProcedure

Procedure UpdatePhone(Val UserObject, Val Phone) Export
	
	CIKind = Catalogs.ContactInformationKinds.UserPhone;
	
	If IsBlankString(Phone) Then
		LineOfATabularSection = UserObject.ContactInformation.Find(CIKind, "Kind");
		If LineOfATabularSection <> Undefined Then
			UserObject.ContactInformation.Delete(LineOfATabularSection);
		EndIf;
	Else
		ContactsManager.AddContactInformation(UserObject, Phone, CIKind);
	EndIf;
	
EndProcedure

Procedure UpdatePropertiesOfPredefinedNodes(Val Description) Export

	If Not Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		Return;
		
	EndIf;
	
	ModuleDataExchangeCached = Common.CommonModule("DataExchangeCached");
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If SaaSOperations.IsSeparatedMetadataObject(ExchangePlan) Then
			
			Query = New Query(
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	&ExchangePlanTableName AS ExchangePlan
			|WHERE
			|	ExchangePlan.ThisNode");
			
			Query.Text = StrReplace(Query.Text, "&ExchangePlanTableName", "ExchangePlan." + ExchangePlan.Name);
			
			If Query.Execute().IsEmpty() Then
				
				NewNodeObject = ExchangePlans[ExchangePlan.Name].CreateNode();
				NewNodeObject.ThisNode = True;
				NewNodeObject.DataExchange.Load = True;
				NewNodeObject.Write();
				
			EndIf;
			
		EndIf;
			
		If ModuleDataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlan.Name) Then
			
			ThisNode = ExchangePlans[ExchangePlan.Name].ThisNode();
			NodeDescription = Common.ObjectAttributeValue(ThisNode, "Description");
			
			If NodeDescription <> Description Then
				
				ThisNodeObject = ThisNode.GetObject();
				ThisNodeObject.Description = Description;
				ThisNodeObject.Write();
				
			EndIf;
			
		EndIf;
		
	EndDo;

EndProcedure

Procedure UpdatePredefinedNodesCode() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		Return;
		
	EndIf;
	
	ModuleDataExchangeCached = Common.CommonModule("DataExchangeCached");
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If SaaSOperations.IsSeparatedMetadataObject(ExchangePlan) Then
			
			Query = New Query(
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	&ExchangePlanTableName AS ExchangePlan
			|WHERE
			|	ExchangePlan.ThisNode");
			
			Query.Text = StrReplace(Query.Text, "&ExchangePlanTableName", "ExchangePlan." + ExchangePlan.Name);
			
			If Query.Execute().IsEmpty() Then
				
				NewNode = ExchangePlans[ExchangePlan.Name].CreateNode();
				NewNode.ThisNode = True;
				NewNode.DataExchange.Load = True;
				NewNode.Write();
				
			EndIf;
			
		EndIf;
			
		If ModuleDataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlan.Name) Then
			
			ThisNode = ExchangePlans[ExchangePlan.Name].ThisNode();
			NodeCode = Common.ObjectAttributeValue(ThisNode, "Code");
			
			If DataExchangeServer.IsXDTOExchangePlan(ExchangePlan.Name) Then
				
				NodeNewCode = String(ThisNode.UUID());
				
			Else
				
				NodeNewCode = RemoteAdministrationMessagesImplementation.ExchangePlanNodeCodeInService(SaaSOperations.SessionSeparatorValue());
				
			EndIf;
			
			If NodeCode <> NodeNewCode Then
				
				ThisNodeObject = ThisNode.GetObject();
				ThisNodeObject.Code = NodeNewCode;
				ThisNodeObject.Write();
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure UpdateCurDataAreaParameters(Val Presentation, Val TimeZone) Export
	
	Constants.DataAreaPresentation.Set(Presentation);
	Constants.DataAreaTimeZone.Set(TimeZone);
	
	If GetInfoBaseTimeZone() <> TimeZone Then
	
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		
		BeginTransaction();
		
		MessageChannel = "ExclusiveMode\SetIBTimeZone";
		Body = New Structure;
		Body.Insert("TimeZone", TimeZone);
		Body.Insert("DataArea", ModuleSaaSOperations.SessionSeparatorValue());
		
		MessagesExchange.SendMessage(
			MessageChannel,
			Body,
			MessagesExchangeInner.ThisNode());
			
		CommitTransaction();
		
	EndIf;
	
	CTLSubsystemsIntegration.OnUpdateCurrentDataAreaParameters();
	
EndProcedure

#Region Cryptography

Function Hash(BinaryData, Type)
	
	Hashing = New DataHashing(Type);
	Hashing.Append(BinaryData);
	
	Return Hashing.HashSum;
		
EndFunction

Function HMAC(Val Var_Key, Val Data, Type, BlockSize)
	
	If Var_Key.Size() > BlockSize Then
		Var_Key = Hash(Var_Key, Type);
	EndIf;
	
	If Var_Key.Size() < BlockSize Then
		Var_Key = GetHexStringFromBinaryData(Var_Key);
		Var_Key = Left(Var_Key + RepeatLine("00", BlockSize), BlockSize * 2);
	EndIf;
	
	Var_Key = GetBinaryDataBufferFromBinaryData(GetBinaryDataFromHexString(Var_Key));
	
	ipad = GetBinaryDataBufferFromHexString(RepeatLine("36", BlockSize));
	opad = GetBinaryDataBufferFromHexString(RepeatLine("5c", BlockSize));
	
	ipad.WriteBitwiseXor(0, Var_Key);
	ikeypad = GetBinaryDataFromBinaryDataBuffer(ipad);
	
	opad.WriteBitwiseXor(0, Var_Key);
	okeypad = GetBinaryDataFromBinaryDataBuffer(opad);
	
	Return Hash(GlueBinaryData(okeypad, Hash(GlueBinaryData(ikeypad, Data), Type)), Type);
	
EndFunction

Function GlueBinaryData(BinaryData1, BinaryData2)
	
	BinaryDataArray = New Array;
	BinaryDataArray.Add(BinaryData1);
	BinaryDataArray.Add(BinaryData2);
	
	Return ConcatBinaryData(BinaryDataArray);
	
EndFunction

Function RepeatLine(String, Count)
	
	Parts = New Array(Count);
	For K = 1 To Count Do
		Parts.Add(String);
	EndDo;
	
	Return StrConcat(Parts, "");
	
EndFunction

#EndRegion

// For the JSON value conversion function
// , see the global context function - Write JSON.
//
// Returns:
//  String - Unique Identifier -> String(Unique Identifier)
//
Function ConvertingJSONValues(Property, Value, AdditionalParameters, Cancel) Export 
	
    If TypeOf(Value) = Type("UUID") Then
        Return String(Value);
    EndIf; 
    
    Return Value;
	
EndFunction

#Region Checks

// Control of exclusion of split objects in controlling subscriptions.
// 
// Parameters: 
//  RaiseException1 - Boolean
// 
// Returns:
//  Undefined, Structure - if there are no errors, then Undefined:
//  * MetadataObjects - Array of MetadataObject
//  * ExceptionText - String
Function ControllingExclusionOfSharedObjectsInControllingSubscriptions(RaiseException1 = True) Export
	
	MetadataControlRules = New Map;
	
	MetadataControlRules.Insert(Metadata.Constants, "ConstantValueManager.%1");
	MetadataControlRules.Insert(Metadata.Catalogs, "CatalogObject.%1");
	MetadataControlRules.Insert(Metadata.Documents, "DocumentObject.%1");
	MetadataControlRules.Insert(Metadata.BusinessProcesses, "BusinessProcessObject.%1");
	MetadataControlRules.Insert(Metadata.Tasks, "TaskObject.%1");
	MetadataControlRules.Insert(Metadata.ChartsOfCalculationTypes, "ChartOfCalculationTypesObject.%1");
	MetadataControlRules.Insert(Metadata.ChartsOfCharacteristicTypes, "ChartOfCharacteristicTypesObject.%1");
	MetadataControlRules.Insert(Metadata.ExchangePlans, "ExchangePlanObject.%1");
	MetadataControlRules.Insert(Metadata.ChartsOfAccounts, "ChartOfAccountsObject.%1");
	MetadataControlRules.Insert(Metadata.AccountingRegisters, "AccountingRegisterRecordSet.%1");
	MetadataControlRules.Insert(Metadata.AccumulationRegisters, "AccumulationRegisterRecordSet.%1");
	MetadataControlRules.Insert(Metadata.CalculationRegisters, "CalculationRegisterRecordSet.%1");
	MetadataControlRules.Insert(Metadata.InformationRegisters, "InformationRegisterRecordSet.%1");
	
	StandardSeparators = New Array; // Array of MetadataObject
	StandardSeparators.Add(Metadata.CommonAttributes.DataAreaMainData);
	StandardSeparators.Add(Metadata.CommonAttributes.DataAreaAuxiliaryData);
	
	ControlProcedures = New Array;
	ControlProcedures.Add(Metadata.EventSubscriptions.CheckSharedRecordSetsOnWriteSaaSTechnology.Handler);
	ControlProcedures.Add(Metadata.EventSubscriptions.CheckSharedObjectsOnWriteSaaSTechnology.Handler);
	
	ControllingSubscriptions = New Array; // Array of MetadataObjectEventSubscription
	For Each EventSubscription In Metadata.EventSubscriptions Do
		If ControlProcedures.Find(EventSubscription.Handler) <> Undefined Then
			ControllingSubscriptions.Add(EventSubscription);
		EndIf;
	EndDo;
	
	ViolationsOfControlExclusionOfSeparatedObjectsInControllingSubscriptions = New Array();
	
	MetadataObjectsWithViolations = New Array;
	
	For Each MetadataControlRule In MetadataControlRules Do
		
		ControlledMetadataObjects = MetadataControlRule.Key; // Array of MetadataObject
		ConstructorForMetadataObjectType = MetadataControlRule.Value;
		
		For Each ControlledMetadataObject In ControlledMetadataObjects Do
			
			
			// 2. Checking of undivided metadata objects for inclusion in controlling
			// event subscriptions.
			
			If ValueIsFilled(ConstructorForMetadataObjectType) Then
				
				MetadataObjectType = Type(StringFunctionsClientServer.SubstituteParametersToString(ConstructorForMetadataObjectType, ControlledMetadataObject.Name));
				
				ProvidedControlOfExclusionOfSharedObjectsInUnsharedSubscriptions = True;
				
				For Each ControllingSubscription In ControllingSubscriptions Do
					
					If ControllingSubscription.Source.ContainsType(MetadataObjectType) Then
						For Each StandardSeparator In StandardSeparators Do
							If SaaSOperations.IsSeparatedMetadataObject(ControlledMetadataObject, StandardSeparator.Name) Then
								ProvidedControlOfExclusionOfSharedObjectsInUnsharedSubscriptions = False;
							EndIf;
						EndDo;
					EndIf;
					
				EndDo;
				
				If Not ProvidedControlOfExclusionOfSharedObjectsInUnsharedSubscriptions Then
					ViolationsOfControlExclusionOfSeparatedObjectsInControllingSubscriptions.Add(ControlledMetadataObject);
					MetadataObjectsWithViolations.Add(ControlledMetadataObject);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ExceptionsRaised = New Array();
	
	If ViolationsOfControlExclusionOfSeparatedObjectsInControllingSubscriptions.Count() > 0 Then
		
		ExceptionText = "";
		
		For Each OffendingMetadataObject In ViolationsOfControlExclusionOfSeparatedObjectsInControllingSubscriptions Do
			
			If Not IsBlankString(ExceptionText) Then
				ExceptionText = ExceptionText + ", ";
			EndIf;
			
			ExceptionText = ExceptionText + OffendingMetadataObject.FullName();
			
		EndDo;
		
		SubscriptionText = "";
		For Each ControllingSubscription In ControllingSubscriptions Do
			
			If Not IsBlankString(SubscriptionText) Then
				SubscriptionText = SubscriptionText + ", ";
			EndIf;
			
			SubscriptionText = SubscriptionText + ControllingSubscription.Name;
			
		EndDo;
		
		ExceptionsRaised.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Các đối tượng metadata chia tách của cấu hình không thể thuộc thành phần đăng ký sự kiện (%1).
                  |Các đối tượng sau không đáp ứng tiêu chí này: %2';
                  |ru = 'Разделенные объекты метаданных конфигурации не должны входить в состав подписок на события (%1).
                  |Следующие объекты не удовлетворяют этому критерию: %2';
                  |en = 'Separated configuration metadata objects cannot be included into event subscriptions (%1).
                  |The following objects do not meet this criterion: %2'; fa = 'Separated configuration metadata objects cannot be included into event subscriptions (%1).
                  |The following objects do not meet this criterion: %2';
                  |it = 'Gli oggetti separati della configurazione di metadati non devono fare parte delle sottoscrizioni a eventi (%1). 
                  | I seguenti oggetti non soddisfano questo criterio: %2';
                  |pl = 'Oddzielone elementy metadanych konfiguracji nie powinny wchodzić w skład subskrypcji na zdarzenia (%1).
                  |Następujące obiekty nie spełniają tego kryterium: %2';
                  |tr = 'Paylaşılan konfigürasyon meta verisi nesneleri, etkinlik aboneliklerinin parçası olmamalıdır (%1).
                  |Aşağıdaki nesneler bu ölçütü karşılamıyor: %2'"),
			SubscriptionText, ExceptionText));
		
	EndIf;
	
	ResultingException = "";
	Iterator_SSLy = 1;
	
	For Each RaisedException In ExceptionsRaised Do
		
		If Not IsBlankString(ResultingException) Then
			ResultingException = ResultingException + Chars.LF + Chars.CR;
		EndIf;
		
		ResultingException = ResultingException + Format(Iterator_SSLy, "NFD=0; NG=0") + ". " + RaisedException;
		Iterator_SSLy = Iterator_SSLy + 1;
		
	EndDo;
	
	If Not IsBlankString(ResultingException) Then
		
		ResultingException = NStr("vi = 'Đã tìm thấy lỗi trong cấu trúc metadata của cấu hình:';
									|ru = 'Обнаружены ошибки в структуре метаданных конфигурации:';
									|en = 'The following errors are found in the applied solution metadata structure:'; fa = 'The following errors are found in the applied solution metadata structure:';
									|it = 'Sono stati rilevati degli errori nella struttura della configurazione dei metadati:';
									|pl = 'Wykryto błędy w strukturze metadanych konfiguracji:';
									|tr = 'Meta veri yapılandırmasının yapısında bulunan hatalar:'") + Chars.LF + Chars.CR + ResultingException;
		
		If RaiseException1 Then
			
			Raise ResultingException;
			
		Else
			
			Return New Structure("MetadataObjects, ExceptionText", MetadataObjectsWithViolations, ResultingException);
			
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion
