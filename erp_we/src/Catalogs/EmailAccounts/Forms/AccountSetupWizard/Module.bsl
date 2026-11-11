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
	
	Title = NStr("vi = 'Tài khoản thư';
				|ru = 'Настройка почты';
				|en = 'Account setup'; fa = 'Account setup';
				|it = 'Impostazioni di posta';
				|pl = 'Konfiguracja poczty';
				|tr = 'E-posta ayarı'");
	AuthenticationOption = "OAuth";
	
	Items.GoToSettingsButton.Visible = False;
	Items.BackButton.Visible = False;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
	Else
		UseSecurityProfiles = False;
	EndIf;
	
	If UseSecurityProfiles Then
		SetupMethod = ManualSetting();
	Else
		SetupMethod = AutoSetUp();
	EndIf;
	
	CanReceiveEmails = EmailOperationsInternal.SubsystemSettings().CanReceiveEmails;
	ShouldUsePOP3Protocol = EmailOperationsInternal.SubsystemSettings().ShouldUsePOP3Protocol;
	
	If Not ShouldUsePOP3Protocol Then
		Protocol = "IMAP";
	EndIf;
	
	ContextMode = Parameters.ContextMode;
	Reconfigure = Parameters.Reconfigure;
	
	UseForReceiving = Not ContextMode And CanReceiveEmails;
	UseForSending = True;
	AuthorizationRequiredOnSendMail = True;
	
	Items.EmailSenderName.Visible = Not ContextMode;
	Items.UseForReceiving.Visible = Not ContextMode And CanReceiveEmails;
	Items.Pages.CurrentPage = Items.EmailAddressInput;
	
	WindowOptionsKey = ?(ContextMode, "ContextMode", "NoContextMode");
	
	If ValueIsFilled(Parameters.Key) Then
		AccountRef = Parameters.Key;
		AuthenticationOption = "Password";
		PopulateUserAccountProperties();
	Else
		NewAccountRef = Catalogs.EmailAccounts.GetRef();
		
		If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
			
			ModuleContactsManager = Common.CommonModule("ContactsManager");
			TypeEmail = ModuleContactsManager.TypeEmail();
			ObjectContactInformation = ModuleContactsManager.ObjectContactInformation(
				Users.CurrentUser(), TypeEmail, , False);
			
			For Each Contact In ObjectContactInformation Do
				Address = Contact.Presentation;
				If Catalogs.EmailAccounts.FindByAttribute("Email", Address).IsEmpty() Then
					Email = Address;
					EmailSenderName = String(Users.CurrentUser());
					Break;
				EndIf;
			EndDo;
			
		EndIf;
	EndIf;
	
	IsFullUser = Users.IsFullUser();
	Items.UserAccountKind.Visible = IsFullUser And Not ContextMode;
	UserAccountKind = ?(IsFullUser, "Shared3", "Personal1");
	
	If Common.IsMobileClient() Then
		Items.Password.HorizontalStretch = True;
		Items.Password.TitleLocation = FormItemTitleLocation.Auto;
	EndIf;
	
	Items.AssistanceRequiredGroup.Visible = False;
	
	// StandardSubsystems.SupportRequests
	If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternal = Common.CommonModule(
			"SupportRequestsInternal");
		
		ModuleSupportRequestsInternal.OnCreateAtServer(ThisObject);
		
	Else
		Items.AssistanceRequiredGroup.Visible = False;
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("AdjustCurrentPageElementsOnOpening", 0.1, True);
	AttachIdleHandler("CheckOpenAuthorizationServiceAvailability", 0.1, True);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not FormClosingConfirmationRequired Then
		Return;
	EndIf;
	
	Cancel = True;
	
	If Exit Then
		Return;
	EndIf;
	
	AttachIdleHandler("ShowQueryBoxBeforeCloseForm", 0.1, True);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "OpenAuthorizationOfTheEmailService" Then
		Return;
	EndIf;
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	KeyReceiptAddress = AuthorizationSettings.KeyReceiptAddress;
	
	If QueryID <> String(Parameter.QueryID) Then
		ErrorsMessages = NStr("ru = 'Не удалось авторизоваться на почтовом сервере. Неверный идентификатор ответа.';
								|vi = 'Cannot authorize on the mail server. Incorrect response ID.';
								|en = 'Cannot authorize on the mail server. Incorrect response ID.'; fa = 'Cannot authorize on the mail server. Incorrect response ID.';
								|it = 'Non è stato possibile ricevere l''autorizzazione per il servizio di posta. ID risposta non valido.';
								|pl = 'Nie udało się autoryzować się na serwerze pocztowym. Niepoprawny identyfikator odpowiedzi.';
								|tr = 'Posta sunucusunda kimlik doğrulanamadı. Yanıt Kimliği geçerli değil.'");
		ValidationCompletedWithErrors = True;
	ElsIf Not GetAccessKeysToMailServer(Parameter.AuthorizationCode, KeyReceiptAddress) Then
		ValidationCompletedWithErrors = True;
	EndIf;
	
	If ValidationCompletedWithErrors Then
		FillinExplanations();
	EndIf;
	
	GotoNextPage();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordOnChange(Item)
	
	PasswordForSendingEmails = PasswordForReceivingEmails;
	
EndProcedure

&AtClient
Procedure PasswordStartChoice(Item, ChoiceData, StandardProcessing)
	
	EmailOperationsClient.PasswordFieldStartChoice(Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure EmailOnChange(Item)
	
	SettingsFilled = False;
	FormClosingConfirmationRequired = True;
	
EndProcedure

&AtClient
Procedure EmailSenderNameOnChange(Item)
	
	FormClosingConfirmationRequired = True;
	
EndProcedure

&AtClient
Procedure DecorationTechnicalDetailsClick(Item)
	
	Items.Pages.CurrentPage = Items.TechnicalDetails;
	Items.BackButton.Visible = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	GotoNextPage(Command);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	CurrentPage = Items.Pages.CurrentPage;
	
	PreviousPage = Undefined;
	
	If CurrentPage = Items.AccountSettings1 Then
		PreviousPage = Items.EmailAddressInput;
	ElsIf CurrentPage = Items.Authorization Or CurrentPage = Items.AccountPasswordInput Then
		
		If Not ContextMode Then
			PreviousPage = Items.AccountSettings1;
		Else
			PreviousPage = Items.EmailAddressInput;
		EndIf;
		
	ElsIf CurrentPage = Items.ErrorsFoundOnCheck Then
		
		If ValueIsFilled(AppID) Then
			PreviousPage = Items.AccountSettings1;
		Else
			PreviousPage = Items.AccountPasswordInput;
			ValidationCompletedWithErrors = False;
		EndIf;
		
	ElsIf CurrentPage = Items.TechnicalDetails Then
		PreviousPage = Items.ErrorsFoundOnCheck;
	EndIf;
	
	If PreviousPage <> Undefined Then
		Items.Pages.CurrentPage = PreviousPage;
	Else
		Items.Pages.CurrentPage = Items.EmailAddressInput;
	EndIf;
	
	SetCurrentPageItems();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	CancelJobExecution(JobID);
	Close(False);
	
EndProcedure

&AtClient
Procedure GoToSettings(Command)
	
	CurrentPage = Items.Pages.CurrentPage;
	
	If Not ContextMode And CurrentPage = Items.AccountConfigured Then
		ShowValue(,AccountRef);
		Close(True);
	Else
		OpenManualSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupportTicket(Command)
	
	// StandardSubsystems.SupportRequests
	If CommonClient.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternalClient = CommonClient.CommonModule(
			"SupportRequestsInternalClient");
		
		If ValueIsFilled(BriefErrorDetails) Then
			DetailsForRequestTopic = BriefErrorDetails;
		Else
			DetailsForRequestTopic = ErrorsMessages;
		EndIf;
		
		RequestParameters_ = ModuleSupportRequestsInternalClient.RequestParameters_();
		RequestParameters_.TechnologicalInfo = ErrorsMessages;
		RequestParameters_.EventLogFilter.Insert("StartDate", ErrorRegistrationTime);
		
		RequestParameters_.Subject = EmailOperationsInternalClient.SupportRequestTopic(
			DetailsForRequestTopic);
		
		RequestParameters_.Message = EmailOperationsInternalClient.SupportRequestText(
			Email,
			DetailsForRequestTopic);
		
		ModuleSupportRequestsInternalClient.SubmitSupportTicket(
			ThisObject,
			RequestParameters_);
		
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

&AtClient
Procedure InfoForSupport(Command)
	
	// StandardSubsystems.SupportRequests
	If CommonClient.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternalClient = CommonClient.CommonModule(
			"SupportRequestsInternalClient");
		
		RequestParameters_ = ModuleSupportRequestsInternalClient.RequestParameters_();
		RequestParameters_.TechnologicalInfo = ErrorsMessages;
		RequestParameters_.EventLogFilter.Insert("StartDate", ErrorRegistrationTime);
		
		ModuleSupportRequestsInternalClient.DownloadInfoForSupport(
			ThisObject,
			RequestParameters_);
		
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenManualSettings()
	
	AccountParameters1 = AccountParameters1();
	CompletionHandler = New CallbackDescription("AfterAccountManualSetting", ThisObject);
	
	OpenForm("Catalog.EmailAccounts.Form.ItemForm", AccountParameters1, , , , ,
		CompletionHandler, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure PopulateUserAccountProperties()
	
	QueryText =
	"SELECT
	|	EmailAccounts.Email AS Email,
	|	EmailAccounts.UserName AS EmailSenderName,
	|	EmailAccounts.Description AS AccountName,
	|	EmailAccounts.EmailServiceAuthorization
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.Ref = &Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", AccountRef);
	
	Selection = Query.Execute().Select();
	
	If Not Selection.Next() Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, Selection);
	OnlyAuthorization = Parameters.OnlyAuthorization;
	
	If Selection.EmailServiceAuthorization Or OnlyAuthorization Then
		
		AuthenticationOption = "OAuth";
		
		If OnlyAuthorization Then
			
			SettingsAuthorizationOnMailServer = SettingsAuthorizationOnMailServer();
			AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
			
			If ValueIsFilled(AuthorizationSettings) And ValueIsFilled(AuthorizationSettings.AppID) Then
				
				AppID = AuthorizationSettings.AppID;
				RedirectAddress = AuthorizationSettings.RedirectAddress;
				
				If IsWebClient() And Not IsMailServiceOpenAuthorizationPublished Then
					RedirectAddress = AuthorizationSettings.RedirectionAddressWebClient;
				EndIf;
				
				ApplicationPassword = AuthorizationSettings.ApplicationPassword;
				Items.Pages.CurrentPage = Items.Authorization;
				
				If IsWebClient() And Not IsMailServiceOpenAuthorizationPublished Then
					Items.AuthorizationOptions.CurrentPage = Items.OperatingSystemBrowser;
					CurrentItem = Items.WebPage;
				Else
					Items.AuthorizationOptions.CurrentPage = Items.EmbeddedBrowser;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowQueryBoxBeforeCloseForm()
	
	QueryText = NStr("vi = 'Dữ liệu đã nhập chưa được ghi lại. Đóng biểu mẫu?';
					|ru = 'Введенные данные не записаны. Закрыть форму?';
					|en = 'Changes are not saved. Close the form?'; fa = 'Changes are not saved. Close the form?';
					|it = 'I dati immessi non sono salvati. Chiudere il form?';
					|pl = 'Wprowadzone dane nie zostały zapisane. Zamknąć formularz?';
					|tr = 'Girilen veriler yazılmadı. Form kapatılsın mı?'");
	CallbackDescription = New CallbackDescription("CloseFormConfirmed", ThisObject);
	Buttons = New ValueList;
	Buttons.Add("Close", NStr("vi = 'Đóng';
								|ru = 'Закрыть';
								|en = 'Close'; fa = 'بستن';
								|it = 'Chiudere';
								|pl = 'Zamknij';
								|tr = 'Kapat'"));
	Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Không đóng';
												|ru = 'Не закрывать';
												|en = 'Do not close'; fa = 'بسته نشود';
												|it = 'Non chiudere';
												|pl = 'Nie zamykaj';
												|tr = 'Kapatmayın'"));
	ShowQueryBox(CallbackDescription, QueryText, Buttons, , DialogReturnCode.Cancel, NStr("vi = 'Tài khoản thư';
																							|ru = 'Настройка почты';
																							|en = 'Account setup'; fa = 'Account setup';
																							|it = 'Impostazioni di posta';
																							|pl = 'Konfiguracja poczty';
																							|tr = 'E-posta ayarı'"));
	
EndProcedure

&AtClient
Procedure CloseFormConfirmed(QuestionResult, AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	FormClosingConfirmationRequired = False;
	Close(False);
	
EndProcedure

&AtClient
Procedure GotoNextPage(Command = Undefined)
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	CurrentPage = Items.Pages.CurrentPage;
	NextPage = Undefined;
	Cancel = False;
	
	If CurrentPage = Items.EmailAddressInput Then
		
		ValidationCompletedWithErrors = False;
		CheckMailAddressFilling(Cancel);
		
		If Not Cancel And Not SettingsFilled Then
			FillAccountSettings();
		EndIf;
		
		If Not Cancel Then
			
			SettingsAuthorizationOnMailServer = SettingsAuthorizationOnMailServer();
			AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
			
			FillInAssistantHeader();
			
			If Not ContextMode Then
				NextPage = Items.AccountSettings1;
			Else
				DefineAuthenticationOption(NextPage, AuthorizationSettings);
			EndIf;
			
		EndIf;
		
	ElsIf CurrentPage = Items.AccountSettings1 Then
		
		DefineAuthenticationOption(NextPage, AuthorizationSettings);
		
	ElsIf CurrentPage = Items.Authorization Then
		
		If IsWebClient() And Not IsMailServiceOpenAuthorizationPublished
			And Not ValueIsFilled(AuthorizationSettings.DeviceRegistrationAddress) Then
			
			If Not GetAccessKeysToMailServer(ConfirmationCode, AuthorizationSettings.KeyReceiptAddress, ClientApplication.GetShortCaption()) Then
				ValidationCompletedWithErrors = True;
			EndIf;
			
		EndIf;
		
		If OnlyAuthorization Then
			FormClosingConfirmationRequired = False;
			If Not ValidationCompletedWithErrors Then
				Close(WriteAuthorizationSettings());
				Return;
			EndIf;
		EndIf;
		
		If ValidationCompletedWithErrors Then
			NextPage = Items.ErrorsFoundOnCheck;
		Else
			NextPage = Items.ValidatingAccountSettings;
		EndIf;
		
	ElsIf CurrentPage = Items.AccountPasswordInput Then
		
		If IsBlankString(PasswordForReceivingEmails) Then
			CommonClient.MessageToUser(NStr("ru = 'Введите пароль учетной записи';
											|vi = 'Enter the account password';
											|en = 'Enter the account password'; fa = 'رمز عبور حساب را وارد کنید';
											|it = 'Enter the account password';
											|pl = 'Enter the account password';
											|tr = 'Hesap şifresini girin'"), , "Password");
			Return;
		EndIf;
		
		NextPage = Items.ValidatingAccountSettings;
		
	ElsIf CurrentPage = Items.ValidatingAccountSettings Then
		
		If Command = Undefined Then
			If ValidationCompletedWithErrors Then
				NextPage = Items.ErrorsFoundOnCheck;
				FillinExplanations();
			ElsIf CheckMissed And SetupMethod = AutoSetUp() Then
				OpenManualSettings();
				Return;
			Else
				NextPage = Items.AccountConfigured;
			EndIf;
			CheckMissed = False;
		Else
			CancelJobExecution(JobID);
			JobID = "";
			CheckMissed = True;
			GotoNextPage();
			Return;
		EndIf;
		
	ElsIf CurrentPage = Items.ErrorsFoundOnCheck Then
		NextPage = Items.ValidatingAccountSettings;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	If NextPage = Undefined Then
		Close(True);
	Else
		Items.Pages.CurrentPage = NextPage;
		SetCurrentPageItems();
	EndIf;
	
	If Items.Pages.CurrentPage = Items.ValidatingAccountSettings Then
		If SetupMethod = AutoSetUp() Then
			AttachIdleHandler("SetUpConnectionParametersAutomatically", 0.1, True);
		Else
			AttachIdleHandler("ExecuteSettingsCheck", 0.1, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DefineAuthenticationOption(NextPage, AuthorizationSettings)
	
	AppID = AuthorizationSettings.AppID;
	ApplicationPassword = AuthorizationSettings.ApplicationPassword;
	
	If AuthenticationOption = "OAuth" And ValueIsFilled(AppID) Then
		
		If IsWebClient() And Not IsMailServiceOpenAuthorizationPublished And Not AvailableAuthorizationByCode() Then
			AuthenticationOption = "Password";
			NextPage = Items.AccountPasswordInput;
			FillPasswordInputHint();
		Else
			
			NextPage = Items.Authorization;
			RedirectAddress = AuthorizationSettings.RedirectAddress;
			
			If IsWebClient() And Not IsMailServiceOpenAuthorizationPublished Then
				RedirectAddress = AuthorizationSettings.RedirectionAddressWebClient;
			EndIf;
			
			If Not ValueIsFilled(RedirectAddress) Then
				RedirectAddress = AuthorizationSettings.RedirectAddressDefault;
			EndIf;
			
			AttachIdleHandler("LoginAtMailServer", 0.1, True);
			
		EndIf
	Else
		AuthenticationOption = "Password";
		NextPage = Items.AccountPasswordInput;
		FillPasswordInputHint();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillPasswordInputHint();
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	If Not ValueIsFilled(AuthorizationSettings) Then
		Return;
	EndIf;
	
	If ValueIsFilled(AuthorizationSettings.PasswordInputHint) Then
		Items.Password.ExtendedTooltip.Title = AuthorizationSettings.PasswordInputHint;
	EndIf
	
EndProcedure

&AtClient
Procedure ExecuteSettingsCheck()
	
	ClosingNotification1 = New CallbackDescription("CheckSettingsPermissionRequestExecuted", ThisObject);
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		
		Query = CreateRequestToUseExternalResources();
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
			CommonClientServer.ValueInArray(Query), ThisObject, ClosingNotification1);
		
	Else
		RunCallback(ClosingNotification1, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckSettingsPermissionRequestExecuted(QueryResult, AdditionalParameters) Export
	
	If Not QueryResult = DialogReturnCode.OK Then
		Return;
	EndIf;
	
	ValidateAccountSettings();
	
	If ValueIsFilled(AccountRef) Then 
		CommonClient.NotifyObjectChanged(AccountRef);
	EndIf;
	
	GotoNextPage();
	
EndProcedure

&AtServer
Function CreateRequestToUseExternalResources()
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Return ModuleSafeModeManager.RequestToUseExternalResources(
		Permissions(), NewAccountRef);
	
EndFunction

&AtServer
Function Permissions()
	
	Result = New Array;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	If UseForSending Then
		Result.Add(
			ModuleSafeModeManager.PermissionToUseInternetResource(
				"SMTP",
				OutgoingMailServer,
				OutgoingMailServerPort,
				NStr("vi = 'E-mail.';
					|ru = 'Электронная почта.';
					|en = 'Email.'; fa = 'Email.';
					|it = 'Posta elettronica.';
					|pl = 'Poczta elektroniczna.';
					|tr = 'E-posta.'")));
	EndIf;
	
	If UseForReceiving Then
		Result.Add(
			ModuleSafeModeManager.PermissionToUseInternetResource(
				Protocol,
				IncomingMailServer,
				IncomingMailServerPort,
				NStr("vi = 'E-mail.';
					|ru = 'Электронная почта.';
					|en = 'Email.'; fa = 'Email.';
					|it = 'Posta elettronica.';
					|pl = 'Poczta elektroniczna.';
					|tr = 'E-posta.'")));
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure CheckMailAddressFilling(Cancel)
	
	ClearMessages();
	
	If IsBlankString(Email) Then
		CommonClient.MessageToUser(NStr("vi = 'Hãy nhập địa chỉ E-mail';
										|ru = 'Введите адрес электронной почты';
										|en = 'Email address required'; fa = 'Email address required';
										|it = 'Immettete l''indirizzo di posta elettronica';
										|pl = 'Podaj adres poczty elektronicznej';
										|tr = 'E-posta adresini girin'"), , "Email", , Cancel);
	ElsIf Not CommonClientServer.EmailAddressMeetsRequirements(Email, True) Then
		CommonClient.MessageToUser(NStr("vi = 'Đã nhập sai địa chỉ E-mail';
										|ru = 'Адрес электронной почты введен неверно';
										|en = 'Invalid email address'; fa = 'Invalid email address';
										|it = 'L''indirizzo di posta elettronica inserito non è corretto';
										|pl = 'Adres e-mail jest nieprawidłowy';
										|tr = 'E-posta adresi geçersizdir'"), , "Email", , Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCurrentPageItems()
	
	CurrentPage = Items.Pages.CurrentPage;
	
	If CurrentPage = Items.AccountConfigured Then
		If ContextMode Then
			ButtonNextTitle = NStr("vi = 'Tiếp theo >';
									|ru = 'Далее >';
									|en = 'Next >'; fa = 'بعدی >';
									|it = 'Avanti >';
									|pl = 'Dalej >';
									|tr = 'İleri >'");
		Else
			ButtonNextTitle = NStr("vi = 'Đóng';
									|ru = 'Закрыть';
									|en = 'Close'; fa = 'بستن';
									|it = 'Chiudere';
									|pl = 'Zamknij';
									|tr = 'Kapat'");
		EndIf;
	Else
		If CurrentPage = Items.ValidatingAccountSettings Then
			ButtonNextTitle = NStr("vi = 'Bỏ qua kiểm tra';
									|ru = 'Пропустить проверку';
									|en = 'Skip test'; fa = 'Skip test';
									|it = 'Saltare verifica';
									|pl = 'Pomiń sprawdzenie';
									|tr = 'Kontrolü atla'");
		Else
			ButtonNextTitle = NStr("vi = 'Tiếp theo >';
									|ru = 'Далее >';
									|en = 'Next >'; fa = 'بعدی >';
									|it = 'Avanti >';
									|pl = 'Dalej >';
									|tr = 'İleri >'");
		EndIf;
	EndIf;
	
	If Not ContextMode And CurrentPage = Items.AccountConfigured Then
		Items.GoToSettingsButton.Title = NStr("vi = 'Chuyển đến tùy chỉnh';
												|ru = 'Перейти к настройкам';
												|en = 'Settings'; fa = 'تنظیمات';
												|it = 'Accedere alle impostazioni';
												|pl = 'Przejdź do ustawień';
												|tr = 'Ayarlara git'");
	Else
		Items.GoToSettingsButton.Title = NStr("vi = 'Tùy chỉnh thủ công';
												|ru = 'Настроить вручную';
												|en = 'Manual setup'; fa = 'تنظیم دستی';
												|it = 'Impostare manualmente';
												|pl = 'Ustaw ręcznie';
												|tr = 'Manuel olarak ayarla'");
	EndIf;
	
	Items.NextButton.Title = ButtonNextTitle;
	Items.NextButton.DefaultButton = CurrentPage <> Items.ValidatingAccountSettings;
	Items.NextButton.Enabled = Not (CurrentPage = Items.ValidatingAccountSettings And CheckMissed);
	Items.NextButton.Visible = Not (CurrentPage = Items.ValidatingAccountSettings And SetupMethod = ManualSetting())
		And Not (CurrentPage = Items.Authorization And Not IsWebClient())
		And Not CurrentPage = Items.ErrorsFoundOnCheck;
	
	Items.BackButton.Visible = CurrentPage <> Items.EmailAddressInput
		And CurrentPage <> Items.AccountConfigured
		And CurrentPage <> Items.ValidatingAccountSettings
		And Not OnlyAuthorization;
	
	Items.CancelButton.Visible = CurrentPage <> Items.AccountConfigured;
	Items.GoToSettingsButton.Visible = Not UseSecurityProfiles
		And (CurrentPage = Items.ErrorsFoundOnCheck And ValidationCompletedWithErrors
			Or Not ContextMode And Not Reconfigure And CurrentPage = Items.AccountConfigured)
		And Not OnlyAuthorization;
	
	If CurrentPage = Items.AccountConfigured Then
		Items.AccountConfiguredLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thiết lập thư
				|%1 đã hoàn tất thành công.';
				|ru = 'Настройка почты
				|%1 успешно завершена.';
				|en = 'Email account
				|%1 is set up successfully.'; fa = 'Email account
				|%1 is set up successfully.';
				|it = 'Impostazioni di posta
				|%1 completate con successo.';
				|pl = 'Konfiguracja poczty
				|%1 została pomyślnie zakończona.';
				|tr = 'Posta kurulumu
				|%1 başarıyla tamamlandı.'"), Email);
	EndIf;
	
	If CurrentPage = Items.Authorization And Items.AuthorizationOptions.CurrentPage = Items.EmbeddedBrowser Then
		Activate();
		AttachIdleHandler("CheckAuthenticationResult", 5, True );
	EndIf;
	
	If CurrentPage <> Items.ErrorsFoundOnCheck Then
		HideNeedHelpSection();
	EndIf;
	
EndProcedure

&AtServer
Procedure HideNeedHelpSection()
	
	// StandardSubsystems.SupportRequests
	If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternal = Common.CommonModule(
		"SupportRequestsInternal");
		
		ModuleSupportRequestsInternal.HideNeedHelpSection(Items);
		
	EndIf;
	// End StandardSubsystems.SupportRequests
	
EndProcedure

&AtClient
Procedure FillAccountSettings()
	
	DefaultSettings = DefaultSettings(Email, PasswordForReceivingEmails);
	FillPropertyValues(ThisObject, DefaultSettings);
	
	If IsBlankString(AccountName) Then
		AccountName = Email;
	EndIf;
	
	SettingsFilled = True;
	
	EncryptOnSendMail = ?(UseSecureConnectionForOutgoingMail, "SSL", "Auto");
	EncryptOnReceiveMail = ?(UseSecureConnectionForIncomingMail, "SSL", "Auto");
	
	FillDefaultSettingsDescription(DefaultSettings);
	
EndProcedure

&AtServerNoContext
Function DefaultSettings(Email, Password)
	
	Position = StrFind(Email, "@");
	ServerNameInAccount = Mid(Email, Position + 1);
	
	Settings = New Structure;
	
	Settings.Insert("UsernameForReceivingEmails", Email);
	Settings.Insert("UsernameToSendMail", Email);
	
	Settings.Insert("PasswordForSendingEmails", Password);
	Settings.Insert("PasswordForReceivingEmails", Password);
	
	Settings.Insert("Protocol", "IMAP");
	Settings.Insert("IncomingMailServer", "imap." + ServerNameInAccount);
	Settings.Insert("IncomingMailServerPort", 993);
	Settings.Insert("UseSecureConnectionForIncomingMail", True);
	
	Settings.Insert("OutgoingMailServer", "smtp." + ServerNameInAccount);
	Settings.Insert("OutgoingMailServerPort", 587);
	Settings.Insert("UseSecureConnectionForOutgoingMail", False);
	
	Settings.Insert("ServerTimeout", 10);
	Settings.Insert("KeepEmailCopiesOnServer", True);
	Settings.Insert("KeepMailAtServerPeriod", 10);
	
	IMAPDefaultSettings = Catalogs.EmailAccounts.IMAPServerConnectionSettingsOptions(Email)[0];
	SMTPDefaultSettings = Catalogs.EmailAccounts.SMTPServerConnectionSettingsOptions(Email)[0];
	
	FillPropertyValues(Settings, IMAPDefaultSettings);
	FillPropertyValues(Settings, SMTPDefaultSettings);
	
	Return Settings;
	
EndFunction

&AtClient
Procedure FillDefaultSettingsDescription(DefaultSettings)
	
	DefaultSettingsDescriptionTemplate = NStr("ru = 'Используются настройки по умолчанию.
		|Протокол: %1
		|
		|Сервер входящей почты: %2
		|Порт сервера входящей почты: %3
		|Использовать SSL-соединение для входящей почты: %4
		|
		|Сервер исходящей почты: %5
		|Порт сервера исходящей почты: %6
		|Использовать SSL-соединение для исходящей почты: %7';
		|vi = 'Default settings are used.
		|Protocol: %1
		|
		|Incoming mail server: %2
		|Port of the incoming mail server: %3
		|Use SSL-connection for incoming mail: %4
		|
		|Outgoing mail server: %5
		|Port of outgoing mail server: %6
		|Use SSL-connection for outgoing mail: %7';
		|en = 'Default settings are used.
		|Protocol: %1
		|
		|Incoming mail server: %2
		|Port of the incoming mail server: %3
		|Use SSL-connection for incoming mail: %4
		|
		|Outgoing mail server: %5
		|Port of outgoing mail server: %6
		|Use SSL-connection for outgoing mail: %7'; fa = 'Default settings are used.
		|Protocol: %1
		|
		|Incoming mail server: %2
		|Port of the incoming mail server: %3
		|Use SSL-connection for incoming mail: %4
		|
		|Outgoing mail server: %5
		|Port of outgoing mail server: %6
		|Use SSL-connection for outgoing mail: %7';
		|it = 'Default settings are used.
		|Protocol: %1
		|
		|Incoming mail server: %2
		|Port of the incoming mail server: %3
		|Use SSL-connection for incoming mail: %4
		|
		|Outgoing mail server: %5
		|Port of outgoing mail server: %6
		|Use SSL-connection for outgoing mail: %7';
		|pl = 'Default settings are used.
		|Protocol: %1
		|
		|Incoming mail server: %2
		|Port of the incoming mail server: %3
		|Use SSL-connection for incoming mail: %4
		|
		|Outgoing mail server: %5
		|Port of outgoing mail server: %6
		|Use SSL-connection for outgoing mail: %7';
		|tr = 'Varsayılan ayarlar kullanılıyor. 
		| Protokol:%1
		|
		|Gelen posta sunucusu:%2
		|Gelen posta sunucusu portu: %3
		|Gelen posta için SSL bağlantısı kullan: %4
		|
		|Giden posta sunucusu: %5
		|Giden posta sunucusu portu: %6
		|Giden posta için SSL bağlantısı kullan: %7'");
	
	DefaultSettingsDescription = StringFunctionsClientServer.SubstituteParametersToString(
		DefaultSettingsDescriptionTemplate,
		DefaultSettings.Protocol,
		DefaultSettings.IncomingMailServer,
		DefaultSettings.IncomingMailServerPort,
		DefaultSettings.UseSecureConnectionForIncomingMail,
		DefaultSettings.OutgoingMailServer,
		DefaultSettings.OutgoingMailServerPort,
		DefaultSettings.UseSecureConnectionForOutgoingMail);
	
	Items.DefaultSettingsDescription.Title = DefaultSettingsDescription;
	
EndProcedure

&AtServer
Procedure ValidateAccountSettings()
	
	OutgoingMailProfile = Undefined;
	If UseForSending Then
		OutgoingMailProfile = InternetMailProfile(False);
	EndIf;
	
	IncomingMailProfile = Undefined;
	If UseForReceiving Then
		IncomingMailProfile = InternetMailProfile(True);
	EndIf;
	
	CheckResult = Catalogs.EmailAccounts.CheckProfilesSettings(
		OutgoingMailProfile, IncomingMailProfile, Email);
	
	ErrorsMessages = CheckResult.ConnectionErrors;
	ValidationCompletedWithErrors = ValueIsFilled(ErrorsMessages);
	
	If Not ValidationCompletedWithErrors And Not CheckMissed Then
		Try
			NewAccount1();
		Except
			ValidationCompletedWithErrors = True;
			ErrorsMessages = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
	EndIf;
	
	If ValidationCompletedWithErrors Then
		
		ErrorRegistrationTime = CurrentSessionDate();
		FillinExplanations();
		
		// StandardSubsystems.SupportRequests
		If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
			
			ModuleSupportRequestsInternal = Common.CommonModule(
				"SupportRequestsInternal");
			
			ModuleSupportRequestsInternal.ShowNeedHelpSection(Items);
			
		EndIf;
		// End StandardSubsystems.SupportRequests
		
	EndIf;
	
EndProcedure

&AtServer
Procedure NewAccount1()
	
	ConvertSettingsFromPunycode();
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	SystemAccount = Catalogs.EmailAccounts.SystemEmailAccount;
	SetUpSystemAccount = ContextMode And UserAccountKind = "Shared3"
		And Not EmailOperations.AccountSetUp(SystemAccount)
		And Catalogs.EmailAccounts.EditionAllowed(SystemAccount);
	
	If SetUpSystemAccount Then
		AccountRef = SystemAccount;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.EmailAccounts");
	If Not AccountRef.IsEmpty() Then
		LockItem.SetValue("Ref", AccountRef);
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Block.Lock();
		
		If AccountRef.IsEmpty() Then
			Account = Catalogs.EmailAccounts.CreateItem();
			Account.SetNewObjectRef(NewAccountRef);
		Else
			Account = AccountRef.GetObject();
		EndIf;
		
		FillPropertyValues(Account, ThisObject);
		Account.UserName = EmailSenderName;
		Account.User = UsernameForReceivingEmails;
		Account.SMTPUser = UsernameToSendMail;
		Account.Timeout = ServerTimeout;
		Account.KeepMessageCopiesAtServer = KeepEmailCopiesOnServer;
		Account.KeepMailAtServerPeriod = ?(KeepEmailCopiesOnServer And DeleteMailFromServer And Protocol = "POP", KeepMailAtServerPeriod, 0);
		Account.ProtocolForIncomingMail = Protocol;
		Account.Description = AccountName;
		Account.AuthorizationRequiredOnSendEmails = ValueIsFilled(Account.SMTPUser);
		
		If UserAccountKind = "Personal1" Then
			Account.AccountOwner = Users.CurrentUser();
		Else
			Account.AccountOwner = Catalogs.Users.EmptyRef();
		EndIf;
		
		If AuthenticationOption = "OAuth" Then
			Account.EmailServiceAuthorization = True;
			Account.EmailServiceName = AuthorizationSettings.InternetServiceName;
		EndIf;
		
		Account.AdditionalProperties.Insert("DoNotCheckSettingsForChanges");
		Account.Write();
		
		AccountRef = Account.Ref;
		FormClosingConfirmationRequired = False;
		
		SetPrivilegedMode(True);
		
		Common.DeleteDataFromSecureStorage(AccountRef);
		
		If AuthenticationOption = "OAuth" Then
			WriteAuthorizationSettings();
		Else
			Common.WriteDataToSecureStorage(AccountRef, PasswordForReceivingEmails);
			Common.WriteDataToSecureStorage(AccountRef, PasswordForSendingEmails, "SMTPPassword");
		EndIf;
		
		SetPrivilegedMode(False);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		WriteLogEvent(NStr("vi = 'Làm việc với E-mail';
							|ru = 'Работа с почтовыми сообщениями';
							|en = 'Email management'; fa = 'مدیریت ایمیل';
							|it = 'Lavoro con i messaggi postali';
							|pl = 'Praca z wiadomościami pocztowymi';
							|tr = 'E-posta işlemleri'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , AccountRef, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
		
	EndTry;
	
EndProcedure

&AtServer
Function WriteAuthorizationSettings()
	
	SetPrivilegedMode(True);
	
	Common.WriteDataToSecureStorage(AccountRef, AccessToken, "AccessToken");
	Common.WriteDataToSecureStorage(AccountRef, AccessTokenValidity, "AccessTokenValidity");
	Common.WriteDataToSecureStorage(AccountRef, UpdateToken, "UpdateToken");
	
	SetPrivilegedMode(False);
	
	Return Common.CheckSumString(AccessToken + UpdateToken);
	
EndFunction

&AtServer
Function InternetMailProfile(ForReceiving = False)
	
	Profile = New InternetMailProfile;
	
	If ForReceiving Or SignInBeforeSendingRequired Then
		If Protocol = "IMAP" Then
			Profile.IMAPServerAddress = IncomingMailServer;
			Profile.IMAPUseSSL = UseSecureConnectionForIncomingMail;
			Profile.IMAPPassword = PasswordForReceivingEmails;
			Profile.IMAPUser = UsernameForReceivingEmails;
			Profile.IMAPPort = IncomingMailServerPort;
		Else
			Profile.POP3ServerAddress = IncomingMailServer;
			Profile.POP3UseSSL = UseSecureConnectionForIncomingMail;
			Profile.Password = PasswordForReceivingEmails;
			Profile.User = UsernameForReceivingEmails;
			Profile.POP3Port = IncomingMailServerPort;
		EndIf;
	EndIf;
	
	If Not ForReceiving Then
		Profile.POP3BeforeSMTP = SignInBeforeSendingRequired;
		Profile.SMTPServerAddress = OutgoingMailServer;
		Profile.SMTPUseSSL = UseSecureConnectionForOutgoingMail;
		Profile.SMTPPassword = PasswordForSendingEmails;
		Profile.SMTPUser = UsernameToSendMail;
		Profile.SMTPPort = OutgoingMailServerPort;
	EndIf;
	
	Profile.Timeout = ServerTimeout;
	
	If AuthenticationOption = "OAuth" Then
		Profile.TokenAuthentication = UseInternetMailTokenAuthentication.Use;
		Profile.AccessToken = AccessToken;
	EndIf;
	
	Return Profile;
	
EndFunction

&AtClient
Procedure SetUpConnectionParametersAutomatically()
	
	ErrorsMessages = NStr("ru = 'Не удалось определить настройки подключения.
		|Настройте параметры подключения вручную.';
		|vi = 'Couldn''t configure email server settings.
		|Please provide settings manually.';
		|en = 'Couldn''t configure email server settings.
		|Please provide settings manually.'; fa = 'Couldn''t configure email server settings.
		|Please provide settings manually.';
		|it = 'Couldn''t configure email server settings.
		|Please provide settings manually.';
		|pl = 'Couldn''t configure email server settings.
		|Please provide settings manually.';
		|tr = 'Bağlantı ayarları belirlenemedi. 
		| Bağlantı parametrelerini manuel olarak yapılandırın.'");
	
	ValidationCompletedWithErrors = False;
	
	TimeConsumingOperation = StartSearchAccountSettings();
	JobID = TimeConsumingOperation.JobID;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	CallbackDescription = New CallbackDescription("OnCompleteSettingsSearch", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtServer
Function StartSearchAccountSettings()
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tìm kiếm tùy chỉnh máy chủ thư';
														|ru = 'Поиск настроек почтового сервера';
														|en = 'Look up mail server settings'; fa = 'Look up mail server settings';
														|it = 'Ricerca delle impostazioni di posta elettronica';
														|pl = 'Wyszukiwanie ustawień serwera pocztowego';
														|tr = 'Posta sunucusunun ayarlarını arama'");
	
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "Catalogs.EmailAccounts.DefineAccountSettings",
		Email, PasswordForReceivingEmails, UseForSending, UseForReceiving);
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure OnCompleteSettingsSearch(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		If Not CheckMissed And IsOpen() Then
			GotoNextPage();
		EndIf;
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		ValidationCompletedWithErrors = True;
		GotoNextPage();
		
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		
		Return;
	EndIf;
	
	FoundSettings = GetFromTempStorage(Result.ResultAddress);
	
	ValidationCompletedWithErrors = UseForSending And Not FoundSettings.ForSending 
		Or UseForReceiving And Not FoundSettings.ForReceiving;
		
	FillPropertyValues(ThisObject, FoundSettings);
	EncryptOnSendMail = ?(UseSecureConnectionForOutgoingMail, "SSL", "Auto");
	EncryptOnReceiveMail = ?(UseSecureConnectionForIncomingMail, "SSL", "Auto");
	
	If Not FoundSettings.SettingsCheckCompleted Then
		AttachIdleHandler("ExecuteSettingsCheck", 0.1, True);
		Return;
	EndIf;
	
	If Not ValidationCompletedWithErrors And Not CheckMissed Then
		Try
			NewAccount1();
		Except
			ValidationCompletedWithErrors = True;
			ErrorsMessages = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		If Not ValidationCompletedWithErrors Then
			CommonClient.NotifyObjectChanged(NewAccountRef);	
		EndIf;
	EndIf;
	
	GotoNextPage();
	
EndProcedure

&AtServerNoContext
Procedure CancelJobExecution(JobID)
	
	If ValueIsFilled(JobID) Then 
		TimeConsumingOperations.CancelJobExecution(JobID);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationByAddress(Val JumpAddr)
	
	AddressStructure1 = CommonClientServer.URIStructure(JumpAddr);
	
	If Not ValueIsFilled(AddressStructure1.Schema) Then
		JumpAddr = "http://" + JumpAddr;
	EndIf;
	
	If IsWebClient() Then
		FileSystemClient.OpenURL(JumpAddr);
		Return;
	EndIf;
	
	WebPage = 
	"<!DOCTYPE html>
	|<html>
	|	<body>
	|		<script language = 'javascript'>
	|			document.location.href='" + JumpAddr + "';
	|		</script>
	|		<p>Load...</p>
	|	</body>
	|</html>";
	
EndProcedure

&AtClient
Procedure LoginAtMailServer()
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	QueryAuthorizationString = QueryAuthorizationString();
	
	If IsWebClient() And Not IsMailServiceOpenAuthorizationPublished Then
		
		If ValueIsFilled(AuthorizationSettings.DeviceRegistrationAddress) Then
			If GetAuthorizationParametersInWebClient(AuthorizationSettings.DeviceRegistrationAddress) Then
				QueryAuthorizationString = UserAuthorizationAddress;
				If Not ValueIsFilled(QueryExecutionInterval) Then
					QueryExecutionInterval = 5;
				EndIf;
				AttachIdleHandler("GetAccessKeysWebClient", QueryExecutionInterval, True);
			Else
				FillinExplanations();
				GotoNextPage();
				Return;
			EndIf;
		EndIf;
		
		Items.ExplanationByConfirmationCode.Title = StringFunctionsClient.FormattedString(NStr(
			"vi = 'Hãy đăng ký trên <a href=""%1"">trang dịch vụ e-mail</a> và nhập mã đã nhận vào trường dưới đây:';
			|ru = 'Авторизуйтесь на <a href=""%1"">странице почтового сервиса</a> и введите полученный код в поле ниже:';
			|en = 'Authorize on the <a href=""%1"">email service page</a> and enter the received code in the field below:'; fa = 'Authorize on the <a href=""%1"">email service page</a> and enter the received code in the field below:';
			|it = 'Авторизуйтесь на <a href=""%1"">странице почтового сервиса</a> и введите полученный код в поле ниже:';
			|pl = 'Authorize on the <a href=""%1"">email service page</a> and enter the received code in the field below:';
			|tr = 'Posta hizmeti sayfasında oturum açınve alınan kodu aşağıdaki alana girin:'"),
			QueryAuthorizationString);
		
		Items.AuthorizationOptions.CurrentPage = Items.OperatingSystemBrowser;
		
	Else
		Items.AuthorizationOptions.CurrentPage = Items.EmbeddedBrowser;
		ExecuteNavigationByAddress(QueryAuthorizationString);
	EndIf;
	
EndProcedure

&AtServer
Function QueryAuthorizationString()
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	URIStructure = CommonClientServer.URIStructure(AuthorizationSettings.AuthorizationAddress);
	ServerAddress = URIStructure.Host;
	ResourceAddress = "/" + URIStructure.PathAtServer;
	
	QueryID = String(New UUID());
	VerificationCode = EmailOperationsInternal.GenerateVerificationCode();
	
	If IsWebClient() Then
		If Not ValueIsFilled(AuthorizationSettings.DeviceRegistrationAddress) Then
			DeviceID = String(New UUID());
		EndIf;
	EndIf;
	
	QueryOptions = ParametersAuthorizationRequest();
	HTTPRequest = EmailOperationsInternal.PrepareHTTPRequest(ResourceAddress, QueryOptions, False);
	
	QueryString = "https://" + ServerAddress + HTTPRequest.ResourceAddress;
	Return QueryString; 
	
EndFunction

&AtServer
Function ParametersAuthorizationRequest()
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	QueryOptions = New Structure;
	QueryOptions.Insert("client_id", AppID);
	QueryOptions.Insert("response_type", "code");
	QueryOptions.Insert("redirect_uri", RedirectAddress);
	
	If ValueIsFilled(AuthorizationSettings["PermissionsToRequest"]) Then
		QueryOptions.Insert("scope", AuthorizationSettings["PermissionsToRequest"]);
	EndIf;
	
	If IsMailServiceOpenAuthorizationPublished Then
		QueryOptions.Insert("state", EmbeddedRedirectionAddress());
	Else
		QueryOptions.Insert("state", QueryID);
	EndIf;
	
	QueryOptions.Insert("login_hint", Email);
	
	If AuthorizationSettings.UsePKCEAuthenticationKey Then
		QueryOptions.Insert("code_challenge", EmailOperationsInternal.EncodeStringMethodS256(VerificationCode));
		QueryOptions.Insert("code_challenge_method", "S256");
	EndIf;
	
	If ValueIsFilled(AuthorizationSettings["AdditionalAuthorizationParameters"]) Then
		For Each Item In StrSplit(AuthorizationSettings["AdditionalAuthorizationParameters"], " ", False) Do
			ParameterDetails = StrSplit(Item, "=", True);
			ParameterName = ParameterDetails[0];
			ParameterValue = "";
			If ParameterDetails.Count() = 2 Then
				ParameterValue = ParameterDetails[1];
			EndIf;
			QueryOptions.Insert(ParameterName, ParameterValue);
		EndDo;
	EndIf;
	
	If IsWebClient() Then
		If Not ValueIsFilled(AuthorizationSettings.DeviceRegistrationAddress) Then
			QueryOptions.Insert("device_name", NStr("vi = '1C:Enterprise';
													|ru = '1С:Предприятие';
													|en = '1C:Enterprise'; fa = '1C:Enterprise';
													|it = '1C:Enterprise';
													|pl = '1C:Enterprise';
													|tr = '1C:Enterprise'"));
		EndIf;
		QueryOptions.Insert("device_id", DeviceID);
	EndIf;
	
	Return QueryOptions;
	
EndFunction

&AtServer
Function EmbeddedRedirectionAddress()
	
	RedirectionEmbeddedAddressTemplate = "%1/hs/oauth2_mail/callback/?zone=%2&session=%3&request_id=%4&user_id=%5";
	EmbeddedRedirectionAddress = StringFunctionsClientServer.SubstituteParametersToString(
		RedirectionEmbeddedAddressTemplate,
		Common.InfobasePublicationURL(),
		XMLString(SessionSeparatorValue()),
		XMLString(InfoBaseSessionNumber()),
		QueryID,
		String(InfoBaseUsers.CurrentUser().UUID));
	
	Return EmbeddedRedirectionAddress;
	
EndFunction

&AtServerNoContext
Function SessionSeparatorValue()
	
	SessionSeparatorValue = 0;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionSeparatorValue = ModuleSaaSOperations.SessionSeparatorValue();
	EndIf;
	
	Return SessionSeparatorValue;
	
EndFunction

&AtClient
Procedure WebPageDocumentComplete(Item)
	
	CheckAuthenticationResult();
	
EndProcedure

&AtClient
Procedure CheckAuthenticationResult()
	
	If IsMailServiceOpenAuthorizationPublished Then
		ServerNotificationsClient.AttachServerNotificationReceiptCheckHandler(1, True);
		Return;
	EndIf;
	
#If Not WebClient Then
	DetachIdleHandler("CheckAuthenticationResult");
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	KeyReceiptAddress = AuthorizationSettings.KeyReceiptAddress;
	
	ServerResponse1 = "";
	If StrStartsWith(Lower(Items.WebPage.Document.URL), Lower(RedirectAddress)) Then
		ServerResponse1 = Items.WebPage.Document.URL;
	ElsIf StrStartsWith(WebPage, "{") And StrEndsWith(WebPage, "}") Then
		ServerResponse1 = WebPage;
	ElsIf Items.WebPage.Document.contentType = "application/json"
		And Items.WebPage.Document.body <> Undefined Then
		ServerResponse1 = Items.WebPage.Document.body.innerText;
	ElsIf Items.WebPage.Document.body <> Undefined 
		And StrFind(Items.WebPage.Document.body.innerText, RedirectAddress) Then
		StringParts1 = StrSplit(Items.WebPage.Document.body.innerText, " ", False);
		For Each RowPart In StringParts1 Do
			If StrStartsWith(RowPart, RedirectAddress) Then
				ServerResponse1 = RowPart;
				Break;
			EndIf;
		EndDo;
	Else
		If Items.Pages.CurrentPage = Items.Authorization Then
			AttachIdleHandler("CheckAuthenticationResult", 5, True);
		EndIf;
		Return;
	EndIf;
	
	OnReceiveMailServerResponse(ServerResponse1, KeyReceiptAddress);
	GotoNextPage();
#EndIf
	
EndProcedure

&AtServer
Procedure OnReceiveMailServerResponse(ParametersString1, KeyReceiptAddress)
	
	If StrStartsWith(ParametersString1, "{") Then
		Response = Common.JSONValue(ParametersString1);
	Else
		Response = ParametersFromStringURI(ParametersString1);
	EndIf;
	
	AuthorizationCode = Response["code"];
	ErrorCode = Response["error"];
	ErrorText = Response["error_description"];
	
	If ValueIsFilled(ErrorText) Then
		ErrorText = DecodeString(ErrorText, StringEncodingMethod.URLEncoding);
	EndIf;
	
	If ValueIsFilled(ErrorCode) Then
		ErrorsMessages = DescriptionErrorsMailServerAuthorization(ErrorCode, ErrorText);
		ValidationCompletedWithErrors = True;
	ElsIf QueryID <> Response["state"] Then
		ErrorsMessages = NStr("vi = 'Không thể đăng ký trên máy chủ e-mail. Sai tên định danh phản hồi.';
								|ru = 'Не удалось авторизоваться на почтовом сервере. Неверный идентификатор ответа.';
								|en = 'Cannot authorize on the mail server. Incorrect response ID.'; fa = 'Cannot authorize on the mail server. Incorrect response ID.';
								|it = 'Non è stato possibile ricevere l''autorizzazione per il servizio di posta. ID risposta non valido.';
								|pl = 'Nie udało się autoryzować się na serwerze pocztowym. Niepoprawny identyfikator odpowiedzi.';
								|tr = 'Posta sunucusunda kimlik doğrulanamadı. Yanıt Kimliği geçerli değil.'");
		ValidationCompletedWithErrors = True;
	ElsIf Not GetAccessKeysToMailServer(AuthorizationCode, KeyReceiptAddress) Then
		ValidationCompletedWithErrors = True;
	EndIf;
	
	If ValidationCompletedWithErrors Then
		
		ErrorRegistrationTime = CurrentSessionDate();
		FillinExplanations();
		
		// StandardSubsystems.SupportRequests
		If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
			
			ModuleSupportRequestsInternal = Common.CommonModule(
				"SupportRequestsInternal");
			
			ModuleSupportRequestsInternal.ShowNeedHelpSection(Items);
			
		EndIf;
		// End StandardSubsystems.SupportRequests
		
	EndIf;
	
EndProcedure

&AtServer
Function GetAccessKeysToMailServer(AuthorizationCode, KeyReceiptAddress, ApplicationCaption = "")
	
	URIStructure = CommonClientServer.URIStructure(KeyReceiptAddress);
	ServerAddress = URIStructure.Host;
	ResourceAddress = "/" + URIStructure.PathAtServer;
	
	QueryOptions = New Structure;
	QueryOptions.Insert("client_id", AppID);
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	If ValueIsFilled(AuthorizationSettings["PermissionsToRequest"]) Then
		QueryOptions.Insert("scope", AuthorizationSettings["PermissionsToRequest"]);
	EndIf;
	
	QueryOptions.Insert("code", AuthorizationCode);
	QueryOptions.Insert("redirect_uri", RedirectAddress);
	QueryOptions.Insert("grant_type", "authorization_code");
	
	If AuthorizationSettings.UsePKCEAuthenticationKey Then
		QueryOptions.Insert("code_verifier", VerificationCode);
	EndIf;
	
	If ValueIsFilled(ApplicationPassword) Then
		QueryOptions.Insert("client_secret", ApplicationPassword);
	EndIf;
	
	If IsWebClient() Then
		QueryOptions.Insert("device_id", DeviceID);
		QueryOptions.Insert("device_name", ApplicationCaption);
	EndIf;
	
	RequestTime = CurrentSessionDate();
	QueryResult = EmailOperationsInternal.ExecuteQuery(ServerAddress, ResourceAddress, QueryOptions);
	
	Try
		AnswerParameters = Common.JSONValue(QueryResult.ServerResponse1);
	Except
		AnswerParameters = New Map;
	EndTry;
	
	AccessToken = AnswerParameters["access_token"];
	AccessTokenValidity = AnswerParameters["expires_in"];
	UpdateToken = AnswerParameters["refresh_token"];
	ErrorCode = AnswerParameters["error"];
	ErrorText = AnswerParameters["error_description"];
	
	If ValueIsFilled(ErrorCode) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận khóa truy cập đến tài khoản e-mail %1 do nguyên nhân: 
			|%2';
			|ru = 'Не удалось получить ключи доступа к учетной записи почты %1 по причине:
			|%2';
			|en = 'Cannot get access keys to the %1 email account due to:
			|%2'; fa = 'Cannot get access keys to the %1 email account due to:
			|%2';
			|it = 'Non è stato possibile ricevere le chiavi di accesso all''account di posta %1 a causa di: 
			|%2';
			|pl = 'Nie udało się otrzymać kluczy dostępu do konta poczty %1 z powodu:
			|%2';
			|tr = 'Aşağıdaki nedenlerden dolayı posta%1 hesabına erişim anahtarları alınamadı:
			|%2'"), Email, ErrorText);
			
		TechnicalDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phản hồi của máy chủ:
			|%1';
			|ru = 'Ответ сервера:
			|%1';
			|en = 'Server response:
			|%1'; fa = 'Server response:
			|%1';
			|it = 'Report server:
			|%1';
			|pl = 'Odpowiedź serwera:
			|%1';
			|tr = 'Sunucu cevabı:
			|%1'"), QueryResult.ServerResponse1);
			
		WriteLogEvent(EmailOperationsInternal.EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText + Chars.LF + TechnicalDetails);
		ErrorsMessages = ErrorText;
		Return False;
	ElsIf Not QueryResult.QueryCompleted Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhận khóa truy cập đến tài khoản e-mail %1 do nguyên nhân:
			|Chưa thực hiện truy vấn.';
			|ru = 'Не удалось получить ключи доступа к учетной записи почты %1 по причине:
			|Запрос не выполнен.';
			|en = 'Cannot get access keys to the %1 email account due to:
			|Request failed.'; fa = 'Cannot get access keys to the %1 email account due to:
			|Request failed.';
			|it = 'Non è stato possibile ricevere la chiave di accesso all''account di posta %1 a causa di:
			| Richiesta non eseguita.';
			|pl = 'Nie udało się otrzymać kluczy dostępu do konta poczty %1 z powodu:
			|Zapytanie nie zostało wykonane.';
			|tr = 'Aşağıdaki nedenlerden dolayı posta%1 hesabına erişim anahtarları alınamadı: 
			|Sorgu gerçekleştirilmedi.'"), Email);
			
		TechnicalDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phản hồi của máy chủ:
			|%1';
			|ru = 'Ответ сервера:
			|%1';
			|en = 'Server response:
			|%1'; fa = 'Server response:
			|%1';
			|it = 'Report server:
			|%1';
			|pl = 'Odpowiedź serwera:
			|%1';
			|tr = 'Sunucu cevabı:
			|%1'"), QueryResult.ServerResponse1);
			
		WriteLogEvent(EmailOperationsInternal.EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText + Chars.LF + TechnicalDetails);
		ErrorsMessages = ErrorText;
		Return False;
	EndIf;
	
	If ValueIsFilled(AccessTokenValidity) Then
		AccessTokenValidity = RequestTime + AccessTokenValidity;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Function ParametersFromStringURI(URIString1)
	
	ParameterValues = New Map;
	URIStructure = CommonClientServer.URIStructure(URIString1);
	
	For Each RowPart In StrSplit(URIStructure.PathAtServer, "?&") Do
		ParameterFValue = StrSplit(RowPart, "=", True);
		ParameterName = ParameterFValue[0];
		If ParameterFValue.Count() > 1 Then
			ParameterValue = DecodeString(ParameterFValue[1], StringEncodingMethod.URLEncoding);
			ParameterValues.Insert(ParameterName, ParameterValue);
		EndIf;
	EndDo;
	
	Return ParameterValues;
	
EndFunction

&AtServerNoContext
Function DescriptionErrorsMailServerAuthorization(Val ErrorCode, Val ErrorText)
	
	Result = String(ErrorText) + Chars.LF + ErrorCode;
	Result = TrimAll(Result);
	
	Result = StringFunctionsClientServer.SubstituteParametersToString(NStr(
		"vi = 'Không thể đăng nhập vào máy chủ e-mail:
		|%1';
		|ru = 'Не удалось авторизоваться на почтовом сервере:
		|%1';
		|en = 'Authorization on the email server failed:
		|%1'; fa = 'Authorization on the email server failed:
		|%1';
		|it = 'Non è stato possibile ricevere l''autorizzazione al server di posta:
		|%1';
		|pl = 'Nie udało się autoryzować się na serwerze pocztowym:
		|%1';
		|tr = 'Posta sunucusunda oturum açılamadı:
		|%1'"), Result);
	
	Return Result;
	
EndFunction

// Returns:
//   See Catalogs.EmailAccounts.ConnectionSettingsByEmailAddress
//
&AtServer
Function ConnectionSettingsByEmailAddress()
	
	SetPrivilegedMode(True);
	Return Catalogs.EmailAccounts.ConnectionSettingsByEmailAddress(Email, PasswordForReceivingEmails);
	
EndFunction

// Returns:
//   See Catalogs.InternetServicesAuthorizationSettings.SettingsAuthorizationInternetService
//
&AtServer
Function SettingsAuthorizationOnMailServer()
	
	Return ConnectionSettingsByEmailAddress().AuthorizationSettings;
	
EndFunction

&AtClientAtServerNoContext
Function IsWebClient()
	
#If WebClient Then
	Return True;
#EndIf
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return Common.IsWebClient();
#EndIf
	
	Return False;
	
EndFunction

&AtServer
Function GetAuthorizationParametersInWebClient(KeyReceiptAddress)
	
	URIStructure = CommonClientServer.URIStructure(KeyReceiptAddress);
	ServerAddress = URIStructure.Host;
	ResourceAddress = "/" + URIStructure.PathAtServer;
	
	QueryOptions = New Structure;
	QueryOptions.Insert("client_id", AppID);
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	If ValueIsFilled(AuthorizationSettings["PermissionsToRequest"]) Then
		QueryOptions.Insert("scope", AuthorizationSettings["PermissionsToRequest"]);
	EndIf;
	
	RequestTime = CurrentSessionDate();
	QueryResult = EmailOperationsInternal.ExecuteQuery(ServerAddress, ResourceAddress, QueryOptions);
	
	Try
		AnswerParameters = Common.JSONValue(QueryResult.ServerResponse1);
	Except
		AnswerParameters = New Map;
	EndTry;
	
	DeviceID = AnswerParameters["device_code"];
	DeviceIdValidityTime = AnswerParameters["expires_in"];
	QueryExecutionInterval = AnswerParameters["interval"];
	ConfirmationCode = AnswerParameters["user_code"];
	
	UserAuthorizationAddress = AnswerParameters["verification_url"];
	If Not ValueIsFilled(UserAuthorizationAddress) Then
		UserAuthorizationAddress = AnswerParameters["verification_uri"];
	EndIf;
	
	ErrorCode = AnswerParameters["error"];
	ErrorText = AnswerParameters["error_description"];
	ErrorText = DescriptionErrorsMailServerAuthorization(ErrorCode, ErrorText);
	
	If ValueIsFilled(ErrorCode) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận khóa truy cập đến tài khoản e-mail %1 do nguyên nhân:
			|%2';
			|ru = 'Не удалось получить ключи доступа к учетной записи почты %1 по причине:
			|%2';
			|en = 'Cannot get access keys to the %1 email account due to:
			|%2'; fa = 'Cannot get access keys to the %1 email account due to:
			|%2';
			|it = 'Non è stato possibile ricevere le chiavi di accesso all''account di posta %1 a causa di: 
			|%2';
			|pl = 'Nie udało się otrzymać kluczy dostępu do konta poczty %1 z powodu:
			|%2';
			|tr = 'Aşağıdaki nedenlerden dolayı posta%1 hesabına erişim anahtarları alınamadı:
			|%2'"), Email, ErrorText);
			
		TechnicalDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phản hồi của máy chủ:
			|%1';
			|ru = 'Ответ сервера:
			|%1';
			|en = 'Server response:
			|%1'; fa = 'Server response:
			|%1';
			|it = 'Report server:
			|%1';
			|pl = 'Odpowiedź serwera:
			|%1';
			|tr = 'Sunucu cevabı:
			|%1'"), QueryResult.ServerResponse1);
			
		WriteLogEvent(EmailOperationsInternal.EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText + Chars.LF + TechnicalDetails);
		ErrorsMessages = ErrorText;
		ValidationCompletedWithErrors = True;
		Return False;
	ElsIf Not QueryResult.QueryCompleted Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhận khóa truy cập đến tài khoản e-mail %1 do nguyên nhân:
			|Chưa thực hiện truy vấn.';
			|ru = 'Не удалось получить ключи доступа к учетной записи почты %1 по причине:
			|Запрос не выполнен.';
			|en = 'Cannot get access keys to the %1 email account due to:
			|Request failed.'; fa = 'Cannot get access keys to the %1 email account due to:
			|Request failed.';
			|it = 'Non è stato possibile ricevere la chiave di accesso all''account di posta %1 a causa di:
			| Richiesta non eseguita.';
			|pl = 'Nie udało się otrzymać kluczy dostępu do konta poczty %1 z powodu:
			|Zapytanie nie zostało wykonane.';
			|tr = 'Aşağıdaki nedenlerden dolayı posta%1 hesabına erişim anahtarları alınamadı: 
			|Sorgu gerçekleştirilmedi.'"), Email);
			
		TechnicalDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phản hồi của máy chủ:
			|%1';
			|ru = 'Ответ сервера:
			|%1';
			|en = 'Server response:
			|%1'; fa = 'Server response:
			|%1';
			|it = 'Report server:
			|%1';
			|pl = 'Odpowiedź serwera:
			|%1';
			|tr = 'Sunucu cevabı:
			|%1'"), QueryResult.ServerResponse1);
			
		WriteLogEvent(EmailOperationsInternal.EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText + Chars.LF + TechnicalDetails);
		ErrorsMessages = ErrorText;
		ValidationCompletedWithErrors = True;
		Return False;
	EndIf;
	
	If ValueIsFilled(DeviceIdValidityTime) Then
		DeviceIdValidityTime = RequestTime + DeviceIdValidityTime;
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure GetAccessKeysWebClient()
	
	If GetDeviceAccessKey() = Undefined Then
		AttachIdleHandler("GetAccessKeysWebClient", QueryExecutionInterval, True);
		Return;
	EndIf;
	
	GotoNextPage();
	
EndProcedure

&AtServer
Function GetDeviceAccessKey()
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	URIStructure = CommonClientServer.URIStructure(AuthorizationSettings.KeyReceiptAddress);
	ServerAddress = URIStructure.Host;
	ResourceAddress = "/" + URIStructure.PathAtServer;
	
	QueryOptions = New Structure;
	QueryOptions.Insert("client_id", AppID);
	QueryOptions.Insert("client_secret", ApplicationPassword);
	QueryOptions.Insert("device_code", DeviceID);
	QueryOptions.Insert("grant_type", "urn:ietf:params:oauth:grant-type:device_code");
	
	RequestTime = CurrentSessionDate();
	QueryResult = EmailOperationsInternal.ExecuteQuery(ServerAddress, ResourceAddress, QueryOptions);
	
	Try
		AnswerParameters = Common.JSONValue(QueryResult.ServerResponse1);
	Except
		AnswerParameters = New Map;
	EndTry;
	
	AccessToken = AnswerParameters["access_token"];
	AccessTokenValidity = AnswerParameters["expires_in"];
	UpdateToken = AnswerParameters["refresh_token"];
	ErrorCode = AnswerParameters["error"];
	ErrorText = AnswerParameters["error_description"];
	
	If ErrorCode = "authorization_pending" Then
		Return Undefined;
	EndIf;
	
	If ValueIsFilled(ErrorCode) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận khóa truy cập đến tài khoản e-mail %1 do nguyên nhân:
			|%2';
			|ru = 'Не удалось получить ключи доступа к учетной записи почты %1 по причине:
			|%2';
			|en = 'Cannot get access keys to the %1 email account due to:
			|%2'; fa = 'Cannot get access keys to the %1 email account due to:
			|%2';
			|it = 'Non è stato possibile ricevere le chiavi di accesso all''account di posta %1 a causa di: 
			|%2';
			|pl = 'Nie udało się otrzymać kluczy dostępu do konta poczty %1 z powodu:
			|%2';
			|tr = 'Aşağıdaki nedenlerden dolayı posta%1 hesabına erişim anahtarları alınamadı:
			|%2'"), Email, ErrorText);
			
		TechnicalDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phản hồi của máy chủ:
			|%1';
			|ru = 'Ответ сервера:
			|%1';
			|en = 'Server response:
			|%1'; fa = 'Server response:
			|%1';
			|it = 'Report server:
			|%1';
			|pl = 'Odpowiedź serwera:
			|%1';
			|tr = 'Sunucu cevabı:
			|%1'"), QueryResult.ServerResponse1);
			
		WriteLogEvent(EmailOperationsInternal.EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText + Chars.LF + TechnicalDetails);
		ErrorsMessages = ErrorText;
		Return False;
	ElsIf Not QueryResult.QueryCompleted Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhận khóa truy cập đến tài khoản e-mail %1 do nguyên nhân:
			|Chưa thực hiện truy vấn.';
			|ru = 'Не удалось получить ключи доступа к учетной записи почты %1 по причине:
			|Запрос не выполнен.';
			|en = 'Cannot get access keys to the %1 email account due to:
			|Request failed.'; fa = 'Cannot get access keys to the %1 email account due to:
			|Request failed.';
			|it = 'Non è stato possibile ricevere la chiave di accesso all''account di posta %1 a causa di:
			| Richiesta non eseguita.';
			|pl = 'Nie udało się otrzymać kluczy dostępu do konta poczty %1 z powodu:
			|Zapytanie nie zostało wykonane.';
			|tr = 'Aşağıdaki nedenlerden dolayı posta%1 hesabına erişim anahtarları alınamadı: 
			|Sorgu gerçekleştirilmedi.'"), Email);
			
		TechnicalDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phản hồi của máy chủ:
			|%1';
			|ru = 'Ответ сервера:
			|%1';
			|en = 'Server response:
			|%1'; fa = 'Server response:
			|%1';
			|it = 'Report server:
			|%1';
			|pl = 'Odpowiedź serwera:
			|%1';
			|tr = 'Sunucu cevabı:
			|%1'"), QueryResult.ServerResponse1);
			
		WriteLogEvent(EmailOperationsInternal.EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText + Chars.LF + TechnicalDetails);
		ErrorsMessages = ErrorText;
		Return False;
	EndIf;
	
	If ValueIsFilled(AccessTokenValidity) Then
		AccessTokenValidity = RequestTime + AccessTokenValidity;
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Function AvailableAuthorizationByCode()
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	Return ValueIsFilled(AuthorizationSettings)
		And (ValueIsFilled(AuthorizationSettings.DeviceRegistrationAddress) 
		Or ValueIsFilled(AuthorizationSettings.RedirectionAddressWebClient));
	
EndFunction

&AtClient
Procedure AdjustCurrentPageElementsOnOpening()
	
	AuthorizationSettings = SettingsAuthorizationOnMailServer; // See SettingsAuthorizationOnMailServer
	
	If OnlyAuthorization Then
		
		If Not ValueIsFilled(AuthorizationSettings) Then
			Close(NStr("vi = 'Không tìm thấy tùy chỉnh đăng nhập đối với địa chỉ email đã chỉ định.
				|Hãy sử dụng đăng nhập theo tên đăng nhập và mật khẩu.';
				|ru = 'Не найдены настройки авторизации для указанного адреса электронной почты.
				|Используйте авторизацию по логину и паролю.';
				|en = 'Cannot find authorization settings for the specified email address.
				|Use username and password authorization.'; fa = 'Cannot find authorization settings for the specified email address.
				|Use username and password authorization.';
				|it = 'Non sono state trovate le impostazioni di autorizzazione per l''indirizzo indicato di posta elettronica.
				|Utilizzare l''autorizzazione per password e login.';
				|pl = 'Nie znaleziono ustawień autoryzacji dla podanego adresu poczty elektronicznej.
				|Używaj autoryzacji za pomocą loginu i hasła.';
				|tr = 'Belirtilen e-posta adresi için yetkilendirme ayarları bulunamadı
				|. Oturum açma ve parola doğrulamasını kullanın.'"));
			Return;
		EndIf;
		
		If Items.Pages.CurrentPage = Items.Authorization Then
			LoginAtMailServer();
		EndIf;
		
	EndIf;
	
	SetCurrentPageItems();
	
EndProcedure

&AtServer
Procedure FillinExplanations()
	
	ExplanationOnError = ExplanationOnError();
	
	PossibleReasons = EmailOperationsInternal.FormattedList(ExplanationOnError.PossibleReasons);
	MethodsToFixError = EmailOperationsInternal.FormattedList(ExplanationOnError.MethodsToFixError);
	
	Items.DecorationRecommendations.Title = String(MethodsToFixError);
	Items.DecorationPossibleReasons.Title = String(PossibleReasons);
	
	FillBriefErrorDetails();
	
EndProcedure

&AtServer
Function ExplanationOnError()
	
	ExplanationParameters = EmailOperationsInternal.ExplanationParameters();
	ExplanationParameters.ErrorText = ErrorsMessages;
	ExplanationParameters.Context = SetupMethod;
	ExplanationParameters.ServerNames = EmailOperationsInternal.ServersNamesForExplanation(IncomingMailServer, OutgoingMailServer);
	
	Return EmailOperationsInternal.ExplanationOnError(ExplanationParameters);
	
EndFunction

&AtServer
Procedure FillBriefErrorDetails()
	
	LengthLimitation = 150;
	
	If StrLen(ErrorsMessages) = LengthLimitation Then
		ErrorDescriptionBeginning = StrFind(ErrorsMessages, Chars.LF);
		BriefErrorDetails = Left(ErrorsMessages, ErrorDescriptionBeginning);
	Else
		BriefErrorDetails = ErrorsMessages;
	EndIf;
	
	If Not ValueIsFilled(BriefErrorDetails) Then
		BriefErrorDetails = NStr("ru = 'Не удалось авторизоваться на почтовом сервере.';
								|vi = 'Authorization in the email server failed.';
								|en = 'Authorization in the email server failed.'; fa = 'Authorization in the email server failed.';
								|it = 'Authorization in the email server failed.';
								|pl = 'Authorization in the email server failed.';
								|tr = 'E-posta sunucusunda yetkilendirme yapılamadı.'");
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAssistantHeader()
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Настройка %1';
																			|vi = '%1 setting';
																			|en = '%1 setting'; fa = '%1 setting';
																			|it = '%1 setting';
																			|pl = '%1 setting';
																			|tr = 'Ayar %1'"), Email);
	
EndProcedure

&AtServerNoContext
Function AutoSetUp()
	
	Return EmailOperationsInternal.ContextForExplanation().AutoSetUp;
	
EndFunction

&AtServerNoContext
Function ManualSetting()
	
	Return EmailOperationsInternal.ContextForExplanation().ManualSetting;
	
EndFunction

&AtServer
Procedure ConvertSettingsFromPunycode()
	
	IncomingMailServer = EmailOperationsInternal.PunycodeIntoString(IncomingMailServer);
	OutgoingMailServer = EmailOperationsInternal.PunycodeIntoString(OutgoingMailServer);
	UsernameToSendMail = EmailOperationsInternal.PunycodeIntoString(UsernameToSendMail);
	UsernameForReceivingEmails = EmailOperationsInternal.PunycodeIntoString(UsernameForReceivingEmails);
	
EndProcedure

&AtClient
Procedure AfterAccountManualSetting(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, Result);
	FillInAssistantHeader();
	
	PasswordForReceivingEmails = Result.Password;
	PasswordForSendingEmails = PasswordForReceivingEmails;
	
	CheckMissed = False;
	SetupMethod = ManualSetting();
	
	Items.Pages.CurrentPage = Items.AccountPasswordInput;
	GotoNextPage();
	
EndProcedure

&AtClient
Procedure CheckOpenAuthorizationServiceAvailability()
	
	IsMailServiceOpenAuthorizationPublished = IsMailServiceOpenAuthorizationPublished();
	
EndProcedure

&AtServerNoContext
Function IsMailServiceOpenAuthorizationPublished()
	
	Return EmailOperationsInternal.IsMailServiceOpenAuthorizationPublished();
	
EndFunction

&AtServer
Function AccountParameters1()
	
	AccountParameters1 = Catalogs.EmailAccounts.AccountParameters1();
	FillPropertyValues(AccountParameters1, ThisObject);
	
	AccountParameters1.Description = AccountName;
	AccountParameters1.Timeout =  ServerTimeout;
	AccountParameters1.UserName = EmailSenderName;
	AccountParameters1.KeepMessageCopiesAtServer = KeepEmailCopiesOnServer;
	
	StoragePeriod = ?(KeepEmailCopiesOnServer And DeleteMailFromServer And Protocol = "POP", KeepMailAtServerPeriod, 0);
	AccountParameters1.KeepMailAtServerPeriod = StoragePeriod;
	
	AccountParameters1.User = UsernameForReceivingEmails;
	AccountParameters1.SMTPUser = UsernameToSendMail;
	AccountParameters1.ProtocolForIncomingMail = Protocol;
	AccountParameters1.AuthorizationRequiredOnSendEmails = ValueIsFilled(UsernameToSendMail);
	
	If UserAccountKind = "Personal1" Then
		AccountParameters1.AccountOwner = Users.CurrentUser();
	Else
		AccountParameters1.AccountOwner = Catalogs.Users.EmptyRef();
	EndIf;
	
	If AuthenticationOption = "OAuth" Then
		AccountParameters1.EmailServiceAuthorization = True;
		AccountParameters1.EmailServiceName = SettingsAuthorizationOnMailServer.InternetServiceName;
	Else
		AccountParameters1.Password = PasswordForReceivingEmails;
	EndIf;
	
	AccountParameters1.AuthenticationOption = AuthenticationOption;
	AccountParameters1.CreatingAccountViaAssistant = True;
	
	Return AccountParameters1;
	
EndFunction

#EndRegion
