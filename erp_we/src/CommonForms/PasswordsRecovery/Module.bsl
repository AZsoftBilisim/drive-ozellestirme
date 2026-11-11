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
	
	If Not Users.IsFullUser() Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện giao dịch.';
					|ru = 'Недостаточно прав для выполнения операции.';
					|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione.';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji.';
					|tr = 'İşlem için gerekli yetkiler yok.'"),
			ErrorCategory.AccessViolation);
	EndIf;
	
	ReadPasswordRestorationSettings();
	
	If ShowHelpHyperlink And IsBlankString(HelpURL) Then
		Items.HelpURL.MarkIncomplete = True;
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		AccountEmail                      = Undefined;
		Items.GroupMailSettings.Visible = False;
	EndIf;

	ThereIsSubsystemOfInternetUserSupport =
		Common.SubsystemExists("OnlineUserSupport");
	If ThereIsSubsystemOfInternetUserSupport Then
		ModuleOnlineUserSupport = Common.CommonModule("OnlineUserSupport");
		
		SetPrivilegedMode(True);
		AuthenticationData = ModuleOnlineUserSupport.OnlineSupportUserAuthenticationData();
		AuthenticationDataInStandard1CServiceIsFilledIn = (AuthenticationData <> Undefined);
		SetPrivilegedMode(False);
	Else
		Items.SendByEmailOptionStandardService.ExtendedTooltip.Title = 
			NStr("ru = 'Для работы сервиса должны быть установлены настройки клиента лицензирования.';
				|vi = 'The licensing client settings must be configured for the service to work.';
				|en = 'The licensing client settings must be configured for the service to work.'; fa = 'The licensing client settings must be configured for the service to work.';
				|it = 'The licensing client settings must be configured for the service to work.';
				|pl = 'The licensing client settings must be configured for the service to work.';
				|tr = 'Hizmetin çalışması için lisanslama istemci ayarları yapılmış olmalıdır.'");
	EndIf;
	
	CheckPlatformVersionForStandardService();

	OptionOfSendingViaStandardServiceIsAvailable = ThereIsSubsystemOfInternetUserSupport
		Or WhenReadingStandardServiceIsUsed;
	Items.ServiceGroupWillStopWorking.Visible = OptionOfSendingViaStandardServiceIsAvailable
		And Not PlatformSupportsSendingViaStandardService;
	Items.SendByEmailOptionStandardService.Visible = OptionOfSendingViaStandardServiceIsAvailable;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetItemsAvailability();
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndCloseNotification", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "OnlineSupportEnabled" Then
		EnteredAuthenticationData = Parameter;
		If EnteredAuthenticationData <> Undefined Then
			AuthenticationDataInStandard1CServiceIsFilledIn = True;
			SetItemsAvailability();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordRecoveryOptionOnChange(Item)
	
	If PasswordRecoveryOption = "ViaEmail" Then
		Items.RecoveryOptions.CurrentPage = Items.Email;
	Else
		Items.RecoveryOptions.CurrentPage = Items.LinkAction;
	EndIf;
	
EndProcedure

&AtClient
Procedure RestorePasswordOnChange(Item)
	
	SetItemsAvailability();
	
EndProcedure

&AtClient
Procedure NeedHelpOnChange(Item)
	
	Items.HelpURL.Enabled = ShowHelpHyperlink;
	
EndProcedure

&AtClient
Procedure SendByEmailOptionOnChange(Item)
	
	SetItemsAvailability();
	
EndProcedure

&AtClient
Procedure SendingOptionByEmailSettingOnChange(Item)
	
	SetItemsAvailability();
	
EndProcedure

&AtClient
Procedure SendingOptionStandardServiceOnChange(Item)
	
	SetItemsAvailability();
	
EndProcedure

&AtClient
Procedure EncryptOnReceiveMailOnChange(Item)
	
	If EncryptOnSendMail = "Auto" Then
		SMTPPort = 25;
	Else
		SMTPPort = 465;
	EndIf;
	
EndProcedure

&AtClient
Procedure SMTPPasswordOnChange(Item)
	
	PasswordChanged = True;
	
EndProcedure

&AtClient
Procedure SendByEmailOptionStandardServiceExtendedTooltipURLProcessing(Item, FormattedStringURL, StandardProcessing)

	StandardProcessing = False;
	
	If ThereIsSubsystemOfInternetUserSupport Then
		ModuleOnlineUserSupportClient = 
			CommonClient.CommonModule("OnlineUserSupportClient");
		ModuleOnlineUserSupportClient.EnableInternetUserSupport(, ThisObject);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	If PasswordRecoverySettingsAreCorrect() Then
		SavePasswordRecoverySettings();
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure Write(Command)
	
	If PasswordRecoverySettingsAreCorrect() Then
		SavePasswordRecoverySettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure HelpURLOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	FileSystemClient.OpenURL(HelpURL);
	
EndProcedure

&AtClient
Procedure ConfirmationCode(Command)
	
	InsertAParameterInATemplate("&VerificationCode");
	
EndProcedure

&AtClient
Procedure ParameterUsername(Command)
	
	InsertAParameterInATemplate("&UserPresentation");
	
EndProcedure

&AtClient
Procedure ConfigurationDescription(Command)
	
	InsertAParameterInATemplate("&ApplicationPresentation");
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WriteAndCloseNotification(Result, Context) Export
	
	If PasswordRecoverySettingsAreCorrect() Then
		SavePasswordRecoverySettings();
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure SetItemsAvailability()
	
	Items.PasswordRecoveryOption.Enabled = RestorePassword;
	Items.RecoveryOptions.Enabled      = RestorePassword;
	
	ManualAdjustmentIsAvailable = SendByEmailOption = "ManualSetting";
	Items.SMTPServerGroup.Enabled       = ManualAdjustmentIsAvailable;
	Items.GroupSMTPUser.Enabled = ManualAdjustmentIsAvailable;
	Items.SenderName.Enabled         = ManualAdjustmentIsAvailable;
	
	If ManualAdjustmentIsAvailable Then
		Items.GroupManualMailSettings.Show();	
	EndIf;
	
	SendViaStandardService = SendByEmailOption = "StandardService";
	Items.EmailSubject.Enabled                             = Not SendViaStandardService;
	Items.GroupFormattedDocumentButtons.Enabled  = Not SendViaStandardService;
	Items.MessageText.Enabled                         = Not SendViaStandardService;
	Items.WarningGroupTextIsNotEditable.Visible = SendViaStandardService;
	
	If Not SendViaStandardService Then
		Items.MessageTextGroup.Show();
	Else
		Items.MessageTextGroup.Hide();
	EndIf;
	
	Items.ServiceGroupWillStopWorking.Visible = SendViaStandardService 
		And Not PlatformSupportsSendingViaStandardService;

	If PlatformSupportsSendingViaStandardService Then	
		If SendViaStandardService
		  And ((Not ThereIsSubsystemOfInternetUserSupport And WhenReadingStandardServiceIsUsed)
		  Or (ThereIsSubsystemOfInternetUserSupport And Not AuthenticationDataInStandard1CServiceIsFilledIn)) Then
			Items.SendByEmailOptionStandardService.ToolTipRepresentation = ToolTipRepresentation.ShowBottom; 
		Else
			Items.SendByEmailOptionStandardService.ToolTipRepresentation = ToolTipRepresentation.None;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Function PasswordRecoverySettingsAreCorrect()
	
	ClearMessages();
	
	TheSettingsAreCorrect = True;
	
	If ShowHelpHyperlink And IsBlankString(HelpURL) Then
		
		CommonClient.MessageToUser(NStr("vi = 'Địa chỉ của trang trợ giúp không được điền';
										|ru = 'Не заполнен адрес страницы помощи';
										|en = 'Help page address is required'; fa = 'Help page address is required';
										|it = 'L''indirizzo della pagina della guida non è compilato';
										|pl = 'Nie wypełniono adresu strony pomocy';
										|tr = 'Yardım sayfası adresi doldurulmadı'"),,
					"HelpURL");
		TheSettingsAreCorrect = False;
		
	EndIf;
	
	If PasswordRecoveryOption <> "ViaEmail" Then
		
		If IsBlankString(PasswordRecoveryURL) Then
			
			CommonClient.MessageToUser(NStr("vi = 'Địa chỉ của trang khôi phục mật khẩu không được điền';
											|ru = 'Не заполнен адрес страницы восстановления пароля';
											|en = 'Password recovery page address is required'; fa = 'Password recovery page address is required';
											|it = 'L''indirizzo della pagina di recupero password non è compilato';
											|pl = 'Nie wypełniono adresu strony odzyskiwania hasła';
											|tr = 'Şifre kurtarma sayfasının adresi doldurulmadı'"),,
					"PasswordRecoveryURL");
				TheSettingsAreCorrect = False;
				
		EndIf;
		
		Return TheSettingsAreCorrect;
		
	EndIf;
	
	If SendByEmailOption = "ExternalMailServer" Then
		
		If Not ValueIsFilled(AccountEmail) Then
		
			CommonClient.MessageToUser(NStr("vi = 'Cài đặt thư không được điền';
											|ru = 'Не заполнены настройки почты';
											|en = 'Email account is required'; fa = 'Email account is required';
											|it = 'Impostazioni della mail non sono compilate';
											|pl = 'Nie wypełniono ustawień poczty';
											|tr = 'Posta ayarları doldurulmadı'"),,
				"AccountEmail");
			TheSettingsAreCorrect = False;
			
		ElsIf Not AccountSetUp(AccountEmail) Then
			
			CommonClient.MessageToUser(NStr("vi = 'Thư không được cài đặt để gửi email';
											|ru = 'Почта не настроена для отправки писем';
											|en = 'The email account is not configured to send mail'; fa = 'The email account is not configured to send mail';
											|it = 'L''email non è configurata per l''invio di messaggi';
											|pl = 'Poczta nie jest ustawiona do wysyłki wiadomości';
											|tr = 'Posta, e-posta göndermek için ayarlanmamış'"),,
				"AccountEmail");
			TheSettingsAreCorrect = False;
			
		EndIf;
		
	ElsIf SendByEmailOption = "ManualSetting" Then
		
		If IsBlankString(SMTPServerAddress) Then
		
			CommonClient.MessageToUser(NStr("vi = 'Chưa điền địa chỉ máy chủ SMTP';
											|ru = 'Не заполнен адрес сервера SMTP';
											|en = 'SMTP server address is required'; fa = 'SMTP server address is required';
											|it = 'Manca indirizzo server SMTP';
											|pl = 'Nie wypełniono adresu serwera SMTP';
											|tr = 'SMTP sunucu adresi doldurulmadı'"),,
				"SMTPServerAddress");
			TheSettingsAreCorrect = False;
			
		EndIf;
		
		If IsBlankString(SMTPUser) Then
		
			CommonClient.MessageToUser(NStr("vi = 'Chưa điền người dùng SMTP';
											|ru = 'Не заполнен пользователь SMTP';
											|en = 'SMTP user is required'; fa = 'SMTP user is required';
											|it = 'Manca utente SMTP';
											|pl = 'Nie wypełniono użytkownika SMTP';
											|tr = 'SMTP kullanıcısı doldurulmadı'"),,
				"SMTPUser");
			TheSettingsAreCorrect = False;
			
		EndIf;
		
		If IsBlankString(SMTPPassword) Then
		
			CommonClient.MessageToUser(NStr("vi = 'Chưa điền mật khẩu SMTP';
											|ru = 'Не заполнен пароль SMTP';
											|en = 'SMTP password is required'; fa = 'SMTP password is required';
											|it = 'Manca password SMTP';
											|pl = 'Nie wypełniono hasła SMTP';
											|tr = 'SMTP şifresi doldurulmadı'"),,
				"SMTPPassword");
			TheSettingsAreCorrect = False;
			
		EndIf;
		
		If IsBlankString(SenderName) Then
		
			CommonClient.MessageToUser(NStr("vi = 'Chưa điền tên người gửi';
											|ru = 'Не заполнено имя отправителя';
											|en = 'Sender name is required'; fa = 'Sender name is required';
											|it = 'Manca il nome del mittente';
											|pl = 'Nie wypełniono imienia nadawcy';
											|tr = 'Gönderenin adı doldurulmadı'"),,
				"SenderName");
			TheSettingsAreCorrect = False;
			
		EndIf;

		
	EndIf;
	
	Return TheSettingsAreCorrect;
	
EndFunction

&AtServerNoContext
Function AccountSetUp(Account)
	
	If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		
		ModuleEmailOperations = Common.CommonModule("EmailOperations");
		Return ModuleEmailOperations.AccountSetUp(Account, True, False);
		
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Procedure InsertAParameterInATemplate(ParameterName)
	
	If CurrentItem.Name = Items.EmailSubject.Name Then
		EmailSubject = EmailSubject + " " + ParameterName;
	Else
		BookmarkToInsertStart = Undefined;
		BookmarkToInsertEnd  = Undefined;
		Items.MessageText.GetTextSelectionBounds(BookmarkToInsertStart, BookmarkToInsertEnd);
		MessageText.Insert(BookmarkToInsertEnd, ParameterName);
	EndIf;
	
EndProcedure

&AtServer
Procedure StartBackgroundFillingOfUsersMail()
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Điền thư người dùng để khôi phục mật khẩu';
														|ru = 'Заполнение почты пользователей для восстановления пароля';
														|en = 'Fill in user email for password recovery'; fa = 'Fill in user email for password recovery';
														|it = 'Inserimento dell''email degli utenti per il recupero della password';
														|pl = 'Wypełnienie poczty użytkowników do odzyskiwania hasła';
														|tr = 'Parola kurtarma için kullanıcı postasını doldurma'");
	
	TimeConsumingOperations.ExecuteInBackground("UsersInternal.FillInTheEmailForPasswordRecoveryFromUsersInTheBackground",
		New Structure, ExecutionParameters);
	
EndProcedure

&AtServer
Function YouNeedToStartFillingInTheUsersMail()
	
	If Not RestorePassword Then
		Return False;
	EndIf;
	
	Settings = AdditionalAuthenticationSettings.GetPasswordRecoverySettings(); // PasswordRecoverySettings
	
	// Previous values.
	If Settings.PasswordRecoveryMethod
			<> InfoBaseUserPasswordRecoveryMethod.None Then
		Return False;
	EndIf;
	
	IBUsers = InfoBaseUsers.GetUsers();
	For Each IBUser In IBUsers Do
		If IBUser.CannotRecoveryPassword = False Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

&AtServer
Procedure SavePasswordRecoverySettings()
	
	StartBackgroundFillingOfUsersMail = YouNeedToStartFillingInTheUsersMail();
	
	If PasswordChanged Then
		CurrentSMTPPassword = SMTPPassword;
	Else
		CurrentSettings = AdditionalAuthenticationSettings.GetPasswordRecoverySettings(); // PasswordRecoverySettings
		CurrentSMTPPassword = CurrentSettings.SMTPPassword;
	EndIf;
	
	Attachments = New Structure;
	MessageText.GetHTML(HTMLMessageText, Attachments);
	
	For Each Attachment In Attachments Do
		
		ImageFormat = ?(Attachment.Value.Format() <> PictureFormat.UnknownFormat,
			Lower(Attachment.Value.Format()), Lower(PictureFormat.PNG));
			
		PictureText = "src=""data:image/" + ImageFormat + ";base64," + Base64String(Attachment.Value.GetBinaryData()) + """";
		HTMLMessageText = StrReplace(HTMLMessageText,
			"src=""" + Attachment.Key + """", 
			PictureText);
			
	EndDo;
	
	Settings = AdditionalAuthenticationSettings.GetPasswordRecoverySettings(); // PasswordRecoverySettings
	FillPropertyValues(Settings, ThisObject, ListOfSettingsFields());
	
	Settings.Header  = EmailSubject;
	Settings.SMTPPassword = CurrentSMTPPassword;
	
	If RestorePassword Then
		
		If PasswordRecoveryOption = "LinkAction" Then
			Settings.PasswordRecoveryMethod =
				InfoBaseUserPasswordRecoveryMethod.GotoURL;
		
		ElsIf SendByEmailOption = "StandardService" Then
			Settings.PasswordRecoveryMethod =
				InfoBaseUserPasswordRecoveryMethod.SendVerificationCodeByStandardService;
		
		ElsIf SendByEmailOption = "ExternalMailServer" Then
			Settings.PasswordRecoveryMethod =
				InfoBaseUserPasswordRecoveryMethod.SendVerificationCodeBySetParameters;
			
			If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
				ModuleEmailOperationsInternal = Common.CommonModule("EmailOperationsInternal");
				AccountSettingsForSendingMail = ModuleEmailOperationsInternal.AccountSettingsForSendingMail(AccountEmail);
				FillPropertyValues(Settings, AccountSettingsForSendingMail);
			EndIf;
		Else
			Settings.PasswordRecoveryMethod = 
				InfoBaseUserPasswordRecoveryMethod.SendVerificationCodeBySetParameters;
			FillPropertyValues(Settings, ThisObject, "SMTPServerAddress, SMTPUser, SMTPPort, SenderName");
			Settings.UseSSL = EncryptOnSendMail = "SSL";
			
		EndIf;
	Else
		Settings.PasswordRecoveryMethod = InfoBaseUserPasswordRecoveryMethod.None;
	EndIf;
	
	SetUpAPasswordRecoveryAccount(AccountEmail, SendByEmailOption = "ExternalMailServer");
	AdditionalAuthenticationSettings.SetPasswordRecoverySettings(Settings);
	Modified = False;
	
	If StartBackgroundFillingOfUsersMail Then
		StartBackgroundFillingOfUsersMail();
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadPasswordRestorationSettings()
	
	SendByEmailOption      = "StandardService";
	PasswordRecoveryOption = "ViaEmail";
	
	AccountInformation = AccountSettingsForPasswordRecovery();
	
	If TypeOf(AccountInformation) = Type("Structure") Then
		AccountEmail = AccountInformation.AccountEmail;
	EndIf;
	
	Settings = AdditionalAuthenticationSettings.GetPasswordRecoverySettings(); // PasswordRecoverySettings 
	FillPropertyValues(ThisObject, Settings, ListOfSettingsFields());
	
	If ValueIsFilled(Settings.SMTPPassword) Then
		SMTPPassword = String(New UUID);
	EndIf;
	
	EncryptOnSendMail = ?(Settings.UseSSL, "SSL", "Auto");
	
	If IsBlankString(HTMLMessageText) Then
		HTMLMessageText = DefaultText();
	EndIf;
	MessageText.SetHTML(HTMLMessageText, New Structure);
	
	EmailSubject = ?(ValueIsFilled(Settings.Header),
		Settings.Header, NStr("vi = 'Khôi phục mật khẩu';
								|ru = 'Восстановление пароля';
								|en = 'Password recovery'; fa = 'بازیابی رمز عبور';
								|it = 'Ripristino password';
								|pl = 'Odzyskiwanie hasła';
								|tr = 'Şifre kurtarma'"));
	
	SendByEmailOption = "ManualSetting"; // default value
	If Settings.PasswordRecoveryMethod = InfoBaseUserPasswordRecoveryMethod.None Then
		RestorePassword = False;
				
	Else
		RestorePassword = True;
		If Settings.PasswordRecoveryMethod = InfoBaseUserPasswordRecoveryMethod.SendVerificationCodeByStandardService Then
			SendByEmailOption = "StandardService";
			
		ElsIf Settings.PasswordRecoveryMethod
					= InfoBaseUserPasswordRecoveryMethod.SendVerificationCodeBySetParameters Then
				
			Items.RecoveryOptions.CurrentPage = Items.Email;
			PasswordRecoveryOption = "ViaEmail";
			If AccountInformation.Used Then
				SendByEmailOption = "ExternalMailServer";
			Else
				SendByEmailOption = "ManualSetting";
				Items.GroupManualMailSettings.Show();
			EndIf;
		Else
			Items.RecoveryOptions.CurrentPage = Items.LinkAction;
			PasswordRecoveryOption = "LinkAction";
		EndIf;
	EndIf;
	
	WhenReadingStandardServiceIsUsed = SendByEmailOption = "StandardService"; 
	
EndProcedure

&AtServerNoContext
Function ListOfSettingsFields()
	
	Return "VerificationCodeRefreshRequestLockDuration,
	|MaxUnsuccessfulVerificationCodeValidationAttemptsCount,PasswordRecoveryURL,
	|ShowHelpHyperlink,HelpURL,VerificationCodeLength,HTMLMessageText,
	|SMTPServerAddress,SMTPPort,UseSSL,SMTPUser,SenderName";
	
EndFunction

&AtServerNoContext
Function DefaultText()
	
	TemplateMessageHTML = NStr("vi = 'Xin chào, %1
	|
	|Chúng tôi đã nhận yêu cầu khôi phục mật khẩu từ %2.
	|
	|Hãy nhập mã %3 để đặt lại mật khẩu.
	|
	|Nếu bạn không yêu cầu khôi phục mật khẩu thì hãy thông báo về điều này cho chuyên gia kỹ thuật.';
	|ru = 'Здравствуйте, %1
	|
	|Мы получили запрос на восстановление пароля от %2.
	|
	|Введите код %3 для сброса пароля.
	|
	|Если восстановление пароля не запрашивалось, сообщите об этом техническому специалисту.';
	|en = 'Dear %1,
	|
	|We have received a request to recover your password from %2.
	|
	|To reset the password, enter the code: %3.
	|
	|If you didn''t send the request, please contact the technical support.'; fa = 'Dear %1,
	|
	|We have received a request to recover your password from %2.
	|
	|To reset the password, enter the code: %3.
	|
	|If you didn''t send the request, please contact the technical support.';
	|it = 'Salve,%1
	|
	|Abbiamo ricevuto la richiesta di ripristino della password da %2.
	|
	|Inserire il codice %3per la sostituzione della password.
	|
	|Se il ripristino della password non è stato richiesto, rivolgersi al tecnico specializzato.';
	|pl = 'Dzień dobry, %1
	|
	|Otrzymaliśmy zapytanie na odzyskiwanie hasła od %2.
	|
	|Wpisz kod %3 do zresetowania hasła.
	|
	|Jeśli Pan/Pani nie wysyłaliście zapytania, prosimy o zawiadomić o tym specjalistę technicznego.';
	|tr = 'Merhaba%1
	|
	|, %2adresinden bir şifre sıfırlama talebi aldık
	|
	|.%3 şifre sıfırlama kodunu girin.
	|
	| Parola kurtarma istenmediyse teknisyeni bilgilendirin.'");
	
	HTMLMessageText = StringFunctionsClientServer.SubstituteParametersToString(TemplateMessageHTML,
		"&UserPresentation", "&ApplicationPresentation", "&VerificationCode");
	
	Return HTMLMessageText;
	
EndFunction

&AtServerNoContext
Procedure SetUpAPasswordRecoveryAccount(AccountEmail, Used)
	
	If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		
		ModuleEmailOperationsInternal = Common.CommonModule("EmailOperationsInternal");
		
		AccountInformation = ModuleEmailOperationsInternal.DescriptionOfAccountSettingsForPasswordRecovery();
		AccountInformation.AccountEmail = AccountEmail;
		AccountInformation.Used       = Used;
		
		ModuleEmailOperationsInternal.SaveYourAccountSettingsForPasswordRecovery(AccountInformation);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function AccountSettingsForPasswordRecovery()
	
	AccountInformation = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsInternal = Common.CommonModule("EmailOperationsInternal");
		AccountInformation = ModuleEmailOperationsInternal.AccountSettingsForPasswordRecovery();
	EndIf;
	
	Return AccountInformation;
	
EndFunction

&AtServer
Procedure CheckPlatformVersionForStandardService()
	
	SystemInfo = New SystemInfo;
	Current = SystemInfo.AppVersion;
	
	If StrStartsWith(Current, "8.3.") Then
		MinVersion = MinimumVersionOfPlatformIs83ForSendingViaStandardService();
		TextOfRequiredVersion = StrTemplate("%1 (%2)", MinVersion,
			MinPlatformVersion85ToSendViaStandardService()); 
	Else
		MinVersion = MinPlatformVersion85ToSendViaStandardService();
		TextOfRequiredVersion = MinVersion; 
	EndIf;
	
	PlatformSupportsSendingViaStandardService =
		CommonClientServer.CompareVersions(Current, MinVersion) >= 0;
	Items.CommentServiceWillStopWorking.Title =
		StringFunctions.FormattedString(Items.CommentServiceWillStopWorking.Title,
			TextOfRequiredVersion);

EndProcedure

&AtServerNoContext
Function MinimumVersionOfPlatformIs83ForSendingViaStandardService()
	Return "8.3.27.2130";
EndFunction

&AtServerNoContext
Function MinPlatformVersion85ToSendViaStandardService()
	Return "8.5.1.1302";
EndFunction

#EndRegion