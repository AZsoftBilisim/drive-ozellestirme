#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetPrivilegedMode(True);
	
	ThisIsExchangeJobUser = IntegrationWith1CDocumentManagementCoreServerCall.ThisIsExchangeJobUser();
	Parameters.Property("CallingExchangeJobForUser", CallingExchangeJobForUser);
	Parameters.Property("CallingToSetUpAccess", CallingToSetUpAccess);
	
	ServiceAddress = IntegrationWith1CDocumentManagementCore.AddressOf1CDocumentManagementWebService(
		CallingExchangeJobForUser Or CallingToSetUpAccess Or Parameters.ConnectingToCentralSubAsset);
	
	UserNameForExchange = Constants.IntegrationWith1CDocumentManagementUsernameForExchange.Get();
	
	If CallingExchangeJobForUser Or ThisIsExchangeJobUser Then
		UserName = UserNameForExchange;
		Password = Constants.IntegrationWith1CDocumentManagementPasswordForExchange.Get();
		
	ElsIf SessionParameters.IntegrationWith1CDocumentManagementPasswordIsKnown
			And Not SessionParameters.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed
			And Not SessionParameters.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed Then
		UserName = SessionParameters.IntegrationWith1CDocumentManagementUsername;
		Password = SessionParameters.IntegrationWith1CDocumentManagementPassword;
		
	EndIf;
	
	IBUserName =
		IntegrationWith1CDocumentManagementCore.IBUserNameForVDOAuthorization(
			Users.CurrentUser());
#If Not WebClient Then
	If Not ValueIsFilled(IBUserName) Then
		// Add the IP user name to the selection list.
		IBUser = InfoBaseUsers.CurrentUser();
		IBUserName = IBUser.Name;
	EndIf;
#EndIf
	
	If ValueIsFilled(IBUserName) Then
		// Add the IP user name to the selection list.
		Items.UserName.ChoiceList.Add(IBUserName);
		Items.UserName.DropListButton = True;
	EndIf;
	
	// If the call is automatic, when checking the connection, and the OS authentication was successful,
	// then you do not need to open the form.
	If Parameters.AutomaticCallWhenCheckingConnection
			And (OSAuthenticationIsUsed Or JWTAuthenticationIsUsed) Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CheckUseOfAuthenticationWithoutLogin();
	
	If Not CallingExchangeJobForUser And Not ThisIsExchangeJobUser Then
		ReadAuthorizationSettings();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not ValueIsFilled(UserName)
			And Not OSAuthenticationIsUsed
			And Not JWTAuthenticationIsUsed Then
		CurrentItem = Items.UserName;
		ShowMessageBox(, NStr("vi = 'Chưa điền tên người sử dụng 1C:Document Management.';
								|ru = 'Не заполнено имя пользователя 1С:Документооборота.';
								|en = '1C:Document Management username is required.'; fa = '1C:Document Management username is required.';
								|it = 'Nome utente di 1C:Document Management non compilato.';
								|pl = 'Nie wypełniono nazwy użytkownika 1C:Document Management.';
								|tr = '1C:Document Management''in kullanıcı adı doldurulmamıştır.'"));
		Return;
	EndIf;
	
	EndAuthorization();
	
EndProcedure

&AtClient
Procedure SettingUpJWT(Command)
	
	Notification = New CallbackDescription("SettingUpJwtEnd", ThisObject);
	NameOfJWTForm = "DataProcessor.AdministrationPanelDMIL.Form.SetUpJWTTokenAuthentication";
	
	OpenForm(NameOfJWTForm,, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SettingUpJwtEnd(Result, Var_Parameters) Export
	
	If Result <> True Then
		Return;
	EndIf;
	
	EndAuthorization();
	
EndProcedure

&AtClient
Procedure AddressOfDocumentManagementWebService(Command)
	
	ShowMessageBox(, ServiceAddress,, NStr("vi = 'Sẽ thực hiện kết nối theo địa chỉ:';
											|ru = 'Подключение будет выполнено по адресу:';
											|en = 'Connection will be performed at:'; fa = 'Connection will be performed at:';
											|it = 'Подключение будет выполнено по адресу:';
											|pl = 'Connection will be performed at:';
											|tr = 'Şu adrese bağlanılacaktır:'"));
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CheckUseOfAuthenticationWithoutLogin()
	
	OSAuthenticationIsUsed = False;
	JWTAuthenticationIsUsed = False;
	SetItemsVisibility();
	
	CallbackOnCompletion = New CallbackDescription(
		"CheckUseOfAuthenticationWithoutLoginCompletion",
		ThisObject);
	TimeConsumingOperation = IntegrationWith1CDocumentManagementCoreServerCall.ConnectAndGetServiceVersionAsynchronously(
		"",
		"",
		UUID,
		False);
	If TimeConsumingOperation <> Undefined Then
		Enabled = False;
		IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
			ThisObject,
			TimeConsumingOperation,
			CallbackOnCompletion,
			True,
			NStr("vi = 'Thiết lập kết nối với 1C:Document Management.';
				|ru = 'Установка соединения с 1С:Документооборот.';
				|en = 'Connecting to 1C:Document Management.'; fa = 'Connecting to 1C:Document Management.';
				|it = 'Установка соединения с 1С:Документооборот.';
				|pl = 'Connecting to 1C:Document Management.';
				|tr = '1C:Document Management ile bağlantı ayarlama.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckUseOfAuthenticationWithoutLoginCompletion(Result, NotificationParameters) Export
	
	Enabled = True;
	
	If Result = Undefined Then
		If IsOpen() Then
			Close(False);
		EndIf;
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		
		OperationParametersList = Result.ResultLongOperation;
		ServiceVersion = OperationParametersList.IntegrationWith1CDocumentManagementServiceVersion;
		
		If IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
			OSAuthenticationIsUsed = OperationParametersList.IntegrationWith1CDocumentManagementOSAuthenticationIsUsed;
			JWTAuthenticationIsUsed = OperationParametersList.IntegrationWith1CDocumentManagementJWTTokenAuthenticationIsUsed;
		EndIf;
		
		IntegrationWith1CDocumentManagementCoreClient.WhenLoggingIn(JWTAuthenticationIsUsed);
		
		SetItemsVisibility(True);
		
	ElsIf Result.Status = "Error" Then
		
		Raise Result.DetailErrorDescription;
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure ReadAuthorizationSettings()
	
	AuthorizationSettings =
		Await IntegrationWith1CDocumentManagementCoreClient.ReadAuthorizationSettingsAsync();
	UserName = AuthorizationSettings.UserName;
	Password = AuthorizationSettings.Password;
	
EndProcedure

&AtClient
Procedure SetItemsVisibility(SetBlankMark = False)
	
	VisibilityOfAuthorizationExplanation = CallingExchangeJobForUser
		Or (CallingToSetUpAccess And Not ValueIsFilled(UserNameForExchange));
	
	Items.SettingUpJWT.Visible = CallingToSetUpAccess;
	Items.DecorationUsedIsFAAuthentication.Visible = OSAuthenticationIsUsed
		And Not VisibilityOfAuthorizationExplanation;
	Items.DecorationUsedIsJWTAuthentication.Visible = JWTAuthenticationIsUsed
		And Not VisibilityOfAuthorizationExplanation;
	Items.ExplanationAuthorization.Visible = VisibilityOfAuthorizationExplanation;
	Items.BlankDecoration.Visible = Not CallingToSetUpAccess
		And Not VisibilityOfAuthorizationExplanation
		And Not OSAuthenticationIsUsed
		And Not JWTAuthenticationIsUsed;
	
	WindowOptionsKey = StrTemplate("SettingUpJWT%1OSAuthentication%2АутентификацияJWT%3",
		Items.SettingUpJWT.Visible,
		Items.DecorationUsedIsFAAuthentication.Visible,
	Items.DecorationUsedIsJWTAuthentication.Visible);
		
	If SetBlankMark Then
		Items.UserName.AutoMarkIncomplete = Not OSAuthenticationIsUsed
			And Not JWTAuthenticationIsUsed;
	EndIf;
	
EndProcedure

&AtClient
Async Procedure EndAuthorization()
	
	If Not CallingExchangeJobForUser And Not ThisIsExchangeJobUser Then
		IntegrationWith1CDocumentManagementCoreServerCall.ResetInternetConnectionCache();
	EndIf;
	
	ErrorMessageText = "";
	
	AuthorizationSettings =
		IntegrationWith1CDocumentManagementCoreClientServer.AuthorizationSettingsIn1CDocumentManagement();
	AuthorizationSettings.UserName = UserName;
	AuthorizationSettings.Password = Password;
	AuthorizationSettings.OSAuthenticationIsUsed = OSAuthenticationIsUsed;
	AuthorizationSettings.JWTAuthenticationIsUsed = JWTAuthenticationIsUsed;
	
	If IntegrationWith1CDocumentManagementCoreServerCall.TestConnection(
			AuthorizationSettings,
			ServiceAddress,
			ErrorMessageText,
			CallingExchangeJobForUser) Then
		
		// The settings for using FA and JWT authentication are implicitly changed during connection verification.
		OSAuthenticationIsUsed = AuthorizationSettings.OSAuthenticationIsUsed;
		JWTAuthenticationIsUsed = AuthorizationSettings.JWTAuthenticationIsUsed;
		
		If CallingExchangeJobForUser Or ThisIsExchangeJobUser Then
			IntegrationWith1CDocumentManagementCoreServerCall.SaveAuthorizationSettingsForExchange(
				UserName,
				Password);
		EndIf;
		
		If CallingToSetUpAccess
				And ValueIsFilled(UserName)
				And Not ValueIsFilled(UserNameForExchange) Then
			IntegrationWith1CDocumentManagementCoreServerCall.SaveAuthorizationSettingsForExchange(
				UserName,
				Password);
		EndIf;
		
		If Not CallingExchangeJobForUser And Not ThisIsExchangeJobUser Then
			IntegrationWith1CDocumentManagementCoreClient.SaveAuthorizationSettings(
				AuthorizationSettings);
			IntegrationWith1CDocumentManagementCoreServerCall.SetServiceVersionInSessionSettings();
			IntegrationWith1CDocumentManagementCoreClient.WhenLoggingIn(JWTAuthenticationIsUsed);
			Notify("IntegrationWith1CDocumentManagement_SuccessfulConnection",, FormOwner);
		EndIf;
		
		Close(True);
		Return;
		
	Else
		
		QuestionParametersYesNo = IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo();
		QuestionParametersYesNo.YesButtonText = NStr("vi = 'Đồng ý';
													|ru = 'ОК';
													|en = 'OK'; fa = 'تأیید';
													|it = 'ОК';
													|pl = 'OK';
													|tr = 'Tamam'");
		QuestionParametersYesNo.NoButtonText = NStr("vi = 'Chi tiết...';
													|ru = 'Подробнее...';
													|en = 'Details...'; fa = 'Details...';
													|it = 'Подробнее...';
													|pl = 'Details...';
													|tr = 'Ayrıntılar...'");
		Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
			NStr("vi = 'Không thể kết nối đến 1C:Document Management với tên
				|người sử dụng và mật khẩu đã chỉ ra. Hãy liên hệ với người quản trị.';
				|ru = 'Не удалось подключиться к 1С:Документообороту с указанным
				|именем пользователя и паролем. Обратитесь к администратору.';
				|en = 'Cannot connect to 1C:Document Management
				|with the specified username and password. Contact the administrator.'; fa = 'Cannot connect to 1C:Document Management
				|with the specified username and password. Contact the administrator.';
				|it = 'Не удалось подключиться к 1С:Документообороту с указанным
				|именем пользователя и паролем. Обратитесь к администратору.';
				|pl = 'Nie udało się do 1C:Document Management ze wskazaną
				|nazwą użytkownika i hasłem. Zwóróć się do administratora.';
				|tr = 'Belirtilen kullanıcı
				|adı ve parola ile 1C:Document Management''te bağlanılamadı. Yönetici ile iletişime geç.'"),
			QuestionParametersYesNo);
		
		If Response = DialogReturnCode.No Then
			ShowMessageBox(, ErrorMessageText);
		EndIf;
		
	EndIf;
	
	SetItemsVisibility();
	
EndProcedure

#EndRegion