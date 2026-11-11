////////////////////////////////////////////////////////////////////////////////
// Subsystem "Remote administration".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Fills the structure with arrays of supported versions of all subsystems to be versioned,
// using the names of subsystems as keys.
// Provides the functionality of the InterfaceVersion Web service.
// When implementing, you need to change the body of the procedure so that it returns the current version sets (see the example below).
//
// Parameters:
//  SupportedVersionsStructure - Structure - structure of supported versions:
//	  * Keys - String - name of the subsystem. 
//	  * Values - Array of String - names of supported versions.
//
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export

	VersionsArray = New Array;
	VersionsArray.Add("1.0.0.1");
	SupportedVersionsStructure.Insert("ManagedApplication", VersionsArray);

EndProcedure

#EndRegion 

#Region Internal

// Checks whether the session belongs to the current data area.
//
// Parameters:
//  SessionNumber - Number - the number of the session that is being checked for ownership.
//
// Returns:
//  Boolean - indicates whether the session belongs to the current data area.
//
Function CheckWhetherSessionBelongsToCurDataArea(Val SessionNumber) Export
	
	AreaSessions = GetInfoBaseSessions();
	For Each SessionArea In AreaSessions Do
		If SessionArea.SessionNumber = SessionNumber Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Terminates the data area user session.
//
// Parameters:
//  SessionsNumbers - Array of Number - array of session numbers,
//  UserPassword - String - password of the current user of the data area.
//  MessageToUsers - String - the text of the message to users at the end of sessions.
//
Procedure EndDataAreaSessions(Val SessionsNumbers, Val UserPassword, Val MessageToUsers) Export

	AuthorizationParameters = AuthorizationParametersForManagingApplication(UserPassword);
	ServiceVersionOfManagingApplication = VersionOfManagementApplicationServiceUsed(AuthorizationParameters);
	If CommonClientServer.CompareVersions(ServiceVersionOfManagingApplication, "1.0.3.3") < 0 Then
		Raise NStr(
			"vi = 'Phiên bản hiện tại của ứng dụng được quản lý không hỗ trợ kết thúc phiên làm việc từ ứng dụng.';
			|ru = 'Текущая версия управляющего приложения не поддерживает завершение сеанса из приложений.';
			|en = 'The current version of the managing application does not support closing sessions from applications.'; fa = 'The current version of the managing application does not support closing sessions from applications.';
			|it = 'La versione corrente dell''applicazione di gestione non supporta la chiusura della sessione dall''applicazione.';
			|pl = 'Bieżąca wersja aplikacji zarządzającej nie obsługuje zakończenie sesji z aplikacji.';
			|tr = 'Yönetilen uygulamanın mevcut sürümü, uygulamalardan oturum sonlandırmayı desteklemiyor.'");
	EndIf;

	Proxy = ProxyServiceOfManagingApplication(AuthorizationParameters);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	CurrentDataArea = SaaSOperations.SessionSeparatorValue();
	KeyCurDataArea = Constants.DataAreaKey.Get();
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);

	If CommonClientServer.CompareVersions(ServiceVersionOfManagingApplication, "1.0.3.4") >= 0 Then

		ErrorInfo = Undefined;
		InformationAboutSessionNumbers = GiveSessionNumbers(SessionsNumbers, Proxy.XDTOFactory);

		If CommonClientServer.CompareVersions(ServiceVersionOfManagingApplication, "1.0.3.6") >= 0 Then
			OperationName = "TerminateSessionsWithMessage";
			Proxy.TerminateSessionsWithMessage(
				CurrentDataArea,
				KeyCurDataArea,
				InformationAboutSessionNumbers,
				MessageToUsers,
				ErrorInfo); 
		Else
			OperationName = "TerminateSessions";
			Proxy.TerminateSessions(
				CurrentDataArea,
				KeyCurDataArea,
				InformationAboutSessionNumbers,
				ErrorInfo);
		EndIf;
		
		SaaSOperations.HandleWebServiceErrorInfo(
			ErrorInfo,
			Metadata.Subsystems.CloudTechnology.Subsystems.RemoteAdministration,
			ServiceInterfaceOfManagingApplication(),
			OperationName);

	Else

		For Each SessionNumber In SessionsNumbers Do

			ErrorInfo = Undefined;
			Proxy.TerminateSession(
				CurrentDataArea,
				KeyCurDataArea,
				SessionNumber,
				ErrorInfo);

			SaaSOperations.HandleWebServiceErrorInfo(
				ErrorInfo,
				Metadata.Subsystems.CloudTechnology.Subsystems.RemoteAdministration,
				ServiceInterfaceOfManagingApplication(),
				"TerminateSession");

		EndDo;

	EndIf;

EndProcedure

// Returns the name of the control application interface.
//
// Returns:
//  String - interface name.
//
Function ServiceInterfaceOfManagingApplication() Export

	Return "ManageApplication"; // Not localized

EndFunction

// Authorization parameters of the control application
// 
// Parameters:
// 	UserPassword - String - The user's password for authorization. If specified or an empty string, the name of the current 
// 	user is used.
// 	 
// Returns:
// 	Structure:
//   * Address - String - internal address of the Service Manager
//   * User - String - user name
//   * Password - String
//   * AccessToken - String
Function AuthorizationParametersForManagingApplication(Val UserPassword = Undefined) Export

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Address = SaaSOperations.InternalServiceManagerURL();
	If Not ValueIsFilled(Address) Then
		Raise NStr("vi = 'Chưa chỉ ra địa chỉ nội bộ của Bộ quản lý dịch vụ';
					|ru = 'Не указан внутренний адрес Менеджера сервиса';
					|en = 'Internal Service Manager URL is not specified'; fa = 'Internal Service Manager URL is not specified';
					|it = 'Indirizzo interno del Manager di servizio non indicato';
					|pl = 'Nie podano adresu wewnętrznego Menedżera usługi';
					|tr = 'Servis yöneticisinin dahili adresi belirtilmemiş.'");
	EndIf;
	AccessToken = Undefined;
	If UserPassword <> Undefined Then
		User = UserName();
		Password = UserPassword;
		If SaaSOperations.AccessTokenAuthenticationOfInternalAPIRequests() Then
			IBUser = InfoBaseUsers.FindByName(User); // The user needs to be reread.
			If Not IBUser.StandardAuthentication 
			   And VerifyUserPassword(IBUser.StoredPasswordValue, UserPassword) Then
				AccessToken = ServiceProgrammingInterface.ValidAccessToken(); 
			EndIf;
		EndIf;
	Else
		User = SaaSOperations.ServiceManagerInternalUserName();
		Password = SaaSOperations.ServiceManagerInternalUserPassword();
	EndIf;
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	If Not ValueIsFilled(User) Then
		Raise NStr("vi = 'Chưa chỉ ra người sử dụng để đăng nhập vào Bộ quản lý dịch vụ';
					|ru = 'Не указан пользователь для авторизации в Менеджере сервиса';
					|en = 'No user is specified for authorization in Service Manager'; fa = 'No user is specified for authorization in Service Manager';
					|it = 'Utente non indicato per l''autorizzazione nel Manager di servizio';
					|pl = 'Nie wskazano użytkownika do uwierzytelniania w Menedżerze usługi';
					|tr = 'Servis Yöneticisinde kimlik doğrulama için kullanıcı belirtilmemiş'");
	EndIf;
	
	Result = New Structure;
	Result.Insert("Address", Address);
	Result.Insert("User", User); 
	Result.Insert("Password", Password); 
	Result.Insert("AccessToken", AccessToken);

	Return Result;

EndFunction

// The version of the management application service used
// 
// Parameters:
// 	AuthorizationParameters - See AuthorizationParametersForManagingApplication
// 	RequiredVersion - String, Undefined - if not specified, the maximum supported version will be obtained
// Returns:
// 	String - ws ManageApplication_a_b_c_d version of the Service Manager
Function VersionOfManagementApplicationServiceUsed(AuthorizationParameters, RequiredVersion = Undefined) Export

	InterfaceName = ServiceInterfaceOfManagingApplication();
	SupportedVersions = Common.GetInterfaceVersions(AuthorizationParameters.Address,
		AuthorizationParameters.User, AuthorizationParameters.Password, InterfaceName);

	If Not ValueIsFilled(SupportedVersions) Then
		Raise StrTemplate(NStr("vi = 'Cơ sở thông tin trao đổi %1 không hỗ trợ giao diện %2';
								|ru = 'Корреспондент %1 не поддерживает интерфейс %2';
								|en = 'Peer infobase %1 does not support interface %2'; fa = 'Peer infobase %1 does not support interface %2';
								|it = 'Il corrispondente %1 non supporta l''interfaccia %2';
								|pl = 'Korespondent %1 nie obsługuje interfejsu %2';
								|tr = '%1 muhabir %2arayüzünü desteklemiyor'"),
			AuthorizationParameters.Address, InterfaceName);
	EndIf;

	VersionUsed_ = Undefined;

	For Each SupportedVersion In SupportedVersions Do
		If Not ValueIsFilled(RequiredVersion) Then
			If VersionUsed_ = Undefined Or CommonClientServer.CompareVersions(SupportedVersion,
				VersionUsed_) > 0 Then
				VersionUsed_ = SupportedVersion;
			EndIf;
		ElsIf RequiredVersion = SupportedVersion Then
			VersionUsed_ = SupportedVersion;
			Break;
		EndIf;
	EndDo;

	If ValueIsFilled(RequiredVersion) And Not ValueIsFilled(VersionUsed_) Then
		Raise StrTemplate(NStr("vi = 'Cơ sở thông tin %1 không hỗ trợ giao diện %2 của phiên bản cần thiết %3';
								|ru = 'Корреспондент %1 не поддерживает интерфейс %2 требуемой версии %3';
								|en = 'Peer infobase %1 does not support interface %2 of required version %3'; fa = 'Peer infobase %1 does not support interface %2 of required version %3';
								|it = 'Il corrispondente %1 non supporta l''interfaccia %2 della versione richiesta %3';
								|pl = 'Korespondent %1 nie obsługuje interfejsu %2 wymaganej wersji %3';
								|tr = '%1 muhabir %2arayüzünün gerekli %3 sürümünü desteklemiyor'"),
			AuthorizationParameters.Address, InterfaceName, RequiredVersion);
	EndIf;

	Return VersionUsed_;

EndFunction

// Returns the proxy Manager of the maximum supported version of the service
// 
// Parameters:
// 	AuthorizationParameters - See AuthorizationParametersForManagingApplication
// 	RequiredVersion - String, Undefined - if not specified, a proxy of the maximum supported version will be obtained
// Returns:
// 	WSProxy - proxy ws ManageApplication_a_b_c_d of the Service Manager
Function ProxyServiceOfManagingApplication(AuthorizationParameters, RequiredVersion = Undefined) Export

	VersionUsed_ = VersionOfManagementApplicationServiceUsed(AuthorizationParameters, RequiredVersion);
	ConnectionParameters = Common.WSProxyConnectionParameters();
	ConnectionParameters.WSDLAddress = AuthorizationParameters.Address + "/ws/ManageApplication_" + StrReplace(
		VersionUsed_, ".", "_") + "?wsdl";
	ConnectionParameters.NamespaceURI = "http://www.1c.ru/SaaS/ManageApplication/" + VersionUsed_;
	ConnectionParameters.ServiceName = "ManageApplication_" + StrReplace(VersionUsed_, ".", "_");
	ConnectionParameters.EndpointName = "";
	ConnectionParameters.UserName = AuthorizationParameters.User;
	ConnectionParameters.Password = AuthorizationParameters.Password;
	ConnectionParameters.Timeout = 60;
	
	If SaaSOperations.AccessTokenAuthenticationOfInternalAPIRequests() 
       And ValueIsFilled(AuthorizationParameters.AccessToken) Then
		Return InternalWSProxyByAccessToken(ConnectionParameters, AuthorizationParameters.AccessToken);
	EndIf;

	Return Common.CreateWSProxy(ConnectionParameters);

EndFunction

#EndRegion

#Region Private

// Returns an array of session numbers to the xdto Object.
//
// Parameters:
//  SessionsNumbers - Array of Number - array of session numbers.
//  Factory - XDTOFactory - the XDTO factory.
//
// Returns:
//  XDTODataObject - list of session numbers.
//
Function GiveSessionNumbers(Val SessionsNumbers, Val Factory) Export
	
	SessionNumberListType = Factory.Type("http://www.1c.ru/1cFresh/ManageApplication/1.0.3.4", "SessionNumberList");
	ListOfSessionNumbers = Factory.Create(SessionNumberListType);
	
	For Each SessionNumber In SessionsNumbers Do
		NumbersList = ListOfSessionNumbers.SessionNumbers; // XDTOList
		NumbersList.Add(SessionNumber);
	EndDo;
	
	Return ListOfSessionNumbers;
	
EndFunction

// Returns an internal WS proxy with access token authorization.
// 
// Parameters:
//  Parameters - See Common.WSProxyConnectionParameters
//  AccessToken - String - see the current Access code
// 
// Returns:
//  WSProxy
Function InternalWSProxyByAccessToken(Parameters, AccessToken) Export
	
	Protocol = "";
	Position = StrFind(Parameters.WSDLAddress, "://");
	If Position > 0 Then
		Protocol = Lower(Left(Parameters.WSDLAddress, Position - 1));
	EndIf;
		
	SecureConnection = Parameters.SecureConnection;
	If (Protocol = "https" Or Protocol = "ftps") And SecureConnection = Undefined Then
		SecureConnection = CommonClientServer.NewSecureConnection();
	EndIf;
	
	InternetProxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		InternetProxy = ModuleNetworkDownload.GetProxy(Parameters.WSDLAddress);
	EndIf;
	
	WSDefinitions = New WSDefinitions(StrTemplate("%1&AccessToken=%2", Parameters.WSDLAddress, AccessToken), , ,
		InternetProxy, Parameters.Timeout, SecureConnection);
	
	EndpointName = Parameters.EndpointName;
	If IsBlankString(EndpointName) Then
		EndpointName = Parameters.ServiceName + "Soap";
	EndIf;
		
	Location = Parameters.Location;
	If IsBlankString(Location) Then
		Location = Parameters.WSDLAddress;
		Position = StrFind(Location, "?");
		If Position > 0 Then
			Location = Left(Location, Position - 1);
		EndIf;
	EndIf;
	
	Location = StrTemplate("%1?AccessToken=%2", Location, AccessToken); 
	Proxy = New WSProxy(WSDefinitions, Parameters.NamespaceURI, Parameters.ServiceName, 
		EndpointName, InternetProxy, Parameters.Timeout, SecureConnection, Location);

	Return Proxy;
	
EndFunction

Function VerifyUserPassword(StoredPasswordValue, CurrentPassword)
	
	Result = False;
	
	If Not ValueIsFilled(StoredPasswordValue) And IsBlankString(CurrentPassword) Then
		Result = True;
		
	ElsIf ValueIsFilled(StoredPasswordValue) Then
		IBUser = InfoBaseUsers.CurrentUser();
		If CommonClientServer.HasAttributeOrObjectProperty(IBUser, "PasswordHashAlgorithmType") Then
			CallParameters = New Structure();
			CallParameters.Insert("UserSecret", CurrentPassword);
			CallParameters.Insert("IBUser", IBUser);
			Result = Common.CalculateInSafeMode(
				"CheckUserPasswordComplianceWithStoredValue(Parameters.UserSecret, Parameters.IBUser)",
				CallParameters);
		Else
			Result = StoredPasswordValue = Users.PasswordHashString(CurrentPassword);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
