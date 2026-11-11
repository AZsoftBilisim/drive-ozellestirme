///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var FixingMethodID;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.FormContinue.Visible = False;
	
	If Parameters.CreatingAccountViaAssistant Then
		FillPropertyValues(Object, Parameters);
		CanReceiveEmails = Parameters.UseForReceiving;
		Password = Parameters.Password;
		SetPropertiesOnCreateViaAssistant();
	Else
		If Not IsEmailServiceAuthorizationAvailable() Then
			Items.AuthenticationMethodMailService.Enabled = False;
			AuthenticationOption = "Password";
		EndIf;
	EndIf;
	
	If Parameters.LockOwner Then
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Object.UseForSending = True;
		Object.UseForReceiving = CanReceiveEmails;
		FillSettings();
	EndIf;
	
	Items.UseAccount.ShowTitle = CanReceiveEmails;
	Items.ForReceiving.Visible = CanReceiveEmails;
	
	If Not CanReceiveEmails Then
		Items.ForSending.Title = NStr("vi = 'Sử dụng để gửi thư';
										|ru = 'Использовать для отправки писем';
										|en = 'Use this account to send mail'; fa = 'Use this account to send mail';
										|it = 'Utilizzare per l''invio della posta';
										|pl = 'Używaj do wysyłania wiadomości';
										|tr = 'E-posta göndermek için kullan'");
	EndIf;
	
	Items.AccountAvailabilityGroup.Enabled = Users.IsFullUser();
	
	AttributesRequiringPasswordToChange = Catalogs.EmailAccounts.AttributesRequiringPasswordToChange();
	
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	
	HighlightColor = StyleColors.ErrorNoteText;
	PatchID = Parameters.PatchID;
	
	If Common.IsMobileClient() Then
		Items.AuthenticationMethodMailService.Visible = False;
		
		Items.AuthenticationPassword.ChoiceList.Clear();
		Items.AuthenticationPassword.ChoiceList.Add("OAuth", NStr("vi = 'Đăng nhập vào dịch vụ e-mail';
																	|ru = 'Авторизация на почтовом сервисе';
																	|en = 'Authorize in the email service'; fa = 'احراز مجوز در سرویس ایمیل';
																	|it = 'Autorizzazione su servizio di posta';
																	|pl = 'Autoryzacja na serwisie pocztowym';
																	|tr = 'E-posta hizmetine giriş'"));
		Items.AuthenticationPassword.ChoiceList.Add("Password", NStr("vi = 'Sử dụng mật khẩu';
																	|ru = 'Использовать пароль';
																	|en = 'Use password'; fa = 'Use password';
																	|it = 'Utilizzare password';
																	|pl = 'Używaj hasła';
																	|tr = 'Şifre kullanmak'"));
		
		Items.Password.HorizontalStretch = True;
		Items.Password.TitleLocation = FormItemTitleLocation.Auto;
		
		Items.Password.Visible = Not Object.EmailServiceAuthorization;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If PasswordChanged Then
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(CurrentObject.Ref, Password);
		Common.WriteDataToSecureStorage(CurrentObject.Ref, Password, "SMTPPassword");
		SetPrivilegedMode(False);
	EndIf;
	
	EmailOperationsInternal.UpdateMailRecoveryServerSettings(CurrentObject.Ref);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If UserAccountKind = "Personal1" And Not ValueIsFilled(Object.AccountOwner) Then 
		Cancel = True;
		MessageText = NStr("vi = 'Chưa chọn đối tượng chủ của thư.';
							|ru = 'Не выбран владелец почты.';
							|en = 'Select the account owner.'; fa = 'Select the account owner.';
							|it = 'Не выбран владелец почты.';
							|pl = 'Select the account owner.';
							|tr = 'Posta sahibi seçilmedi.'");
		Common.MessageToUser(MessageText, , "Object.AccountOwner");
	EndIf;
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	CurrentObject.SMTPUser = ?(CurrentObject.AuthorizationRequiredOnSendEmails And Not Object.SignInBeforeSendingRequired, CurrentObject.User, "");
	CurrentObject.SignInBeforeSendingRequired = CurrentObject.SignInBeforeSendingRequired And CurrentObject.AuthorizationRequiredOnSendEmails;
	CurrentObject.AdditionalProperties.Insert("Password", PasswordCheck);
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	CallbackDescription = New CallbackDescription("BeforeCloseConfirmationReceived", ThisObject);
	CommonClient.ShowFormClosingConfirmation(CallbackDescription, Cancel, Exit);
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FillObjectAttributes();
	
	HandlersBeforeWrite = New Array;
	HandlersBeforeWrite.Add(New CallbackDescription("CheckFillingBeforeWrite", ThisObject, WriteParameters));
	HandlersBeforeWrite.Add(New CallbackDescription("ValidatePermissionsBeforeWrite", ThisObject, WriteParameters));
	HandlersBeforeWrite.Add(New CallbackDescription("CheckPasswordBeforeWrite", ThisObject, WriteParameters));
	
	AttachHandlersBeforeWrite(HandlersBeforeWrite, ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	CommonClient.NotifyObjectChanged(Object.Ref);
	
	If WriteParameters.Property("WriteAndClose") Then
		Close();
	EndIf;
	
	If WriteParameters.Property("CheckSettings") Then
		AttachIdleHandler("ExecuteSettingsCheck", 0.1, True);
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetKeepEmailsAtServerSettingKind();
	
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	
	If ValueIsFilled(PatchID) Then
		ShowCorrectionMethod(PatchID);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	FillSettings();
	
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = Common.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtClient
Procedure ShowCorrectionMethod(WayFix)

	If WayFix = "b186a13d-a8b1-4a30-acf3-f1a09f104deb" Then
		CommonClient.MessageToUser(NStr("vi = 'Hãy bật đăng nhập vào máy chủ thư đi.';
										|ru = 'Включите авторизацию на сервере исходящей почты.';
										|en = 'Enable authorization on the outgoing mail server.'; fa = 'Enable authorization on the outgoing mail server.';
										|it = 'Attivare autorizzazione al server di posta in uscita.';
										|pl = 'Włącz autoryzację na serwerze poczty wychodzącej.';
										|tr = 'Giden posta sunucusunda yetkilendirmeyi etkinleştirin.'"),
			Object.Ref, , "Object.AuthorizationRequiredOnSendEmails");
	ElsIf WayFix = "00aae216-28f1-4b32-8ac5-d2a104368df5" Then 
		CommonClient.MessageToUser(NStr("vi = 'Để tùy chỉnh lại thư, hãy nhấn nút ""Tùy chỉnh lại"".';
										|ru = 'Для перенастройки почты нажмите на кнопку ""Перенастроить"".';
										|en = 'To reconfigure your account, click ""Reconfigure"".'; fa = 'To reconfigure your account, click ""Reconfigure"".';
										|it = 'Per reimpostare la posta, cliccare sul pulsante ""Reimpostare"".';
										|pl = 'Aby ponownie ustawić pocztę naciśnij przycisk ""Ponownie ustaw"".';
										|tr = 'Postayı yeniden yapılandırmak için ""Yeniden Yapılandır"" düğmesine tıklayın.'"),
			Object.Ref);
	ElsIf WayFix = "bf66cd93-d8d0-419a-afc0-09ca83d93436" Then
		CommonClient.MessageToUser(NStr("vi = 'Hãy chuyển mã hóa sang STARTTLS (đối với thư đến).';
										|ru = 'Переключите шифрование на STARTTLS (для входящей почты).';
										|en = 'Switch encryption to STARTTLS (for incoming emails).'; fa = 'Switch encryption to STARTTLS (for incoming emails).';
										|it = 'Attivare crittografia su STARTTLS (per la posta in entrata).';
										|pl = 'Przełącz szyfrowanie na STARTTLS (dla poczty wchodzącej).';
										|tr = 'Şifrelemeyi STARTTLS olarak değiştirin (gelen posta için).'"),
			Object.Ref, "EncryptOnReceiveMail");
	ElsIf WayFix = "5788b71c-7d93-41dd-9061-4c515cd6c4b2" Then
		CommonClient.MessageToUser(NStr("vi = 'Thử xóa và nhập lại tên đăng nhập.';
										|ru = 'Попробуйте очистить и ввести заново логин.';
										|en = 'Try clearing and entering a username again.'; fa = 'Try clearing and entering a username again.';
										|it = 'Provare a cancellare e inserire nuovamente il login.';
										|pl = 'Spróbuj wyczyścić i wprowadź ponownie login.';
										|tr = 'Giriş bilgilerinizi silip yeniden girmeyi deneyin.'"),
			Object.Ref, , "Object.User");
	ElsIf WayFix = "374cae78-09b2-4384-810c-185a82e8e595" Then
		CommonClient.MessageToUser(NStr("vi = 'Hãy nhập mật khẩu.';
										|ru = 'Введите пароль.';
										|en = 'Enter your password'; fa = 'Enter your password';
										|it = 'Inserire password.';
										|pl = 'Wprowadź hasło.';
										|tr = 'Şifre girin.'"),
			Object.Ref, "Password");
	ElsIf WayFix = "a34d21d8-a673-4ee3-be7e-e8bd217b1fd2" Then
		CommonClient.MessageToUser(NStr("vi = 'Kiểm tra địa chỉ e-mail.';
										|ru = 'Проверьте адрес почты.';
										|en = 'Check email address.'; fa = 'Check email address.';
										|it = 'Verificare l''indirizzo di posta.';
										|pl = 'Sprawdź adres poczty.';
										|tr = 'E-posta adresinizi kontrol edin.'"),
			Object.Ref, "Object.Email");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProtocolOnChange(Item)
	
	If IsBlankString(Object.ProtocolForIncomingMail) Then
		Object.ProtocolForIncomingMail = "IMAP";
	EndIf;
	
	If Object.ProtocolForIncomingMail = "IMAP" Then
		If StrStartsWith(Object.IncomingMailServer, "pop.") Then
			Object.IncomingMailServer = "imap." + Mid(Object.IncomingMailServer, 5);
		EndIf
	Else
		If StrStartsWith(Object.IncomingMailServer, "imap.") Then
			Object.IncomingMailServer = "pop." + Mid(Object.IncomingMailServer, 6);
		EndIf;
	EndIf;
	
	Items.IncomingMailServer.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Máy chủ %1';
			|ru = 'Сервер %1';
			|en = '%1 server'; fa = '%1 server';
			|it = 'Server %1';
			|pl = 'Serwer%1';
			|tr = 'Sunucu %1'"), Object.ProtocolForIncomingMail);
	
	POPIsUsed = Object.ProtocolForIncomingMail = "POP";
	Items.KeepMessagesOnServer.Visible = POPIsUsed And CanReceiveEmails;
	
	SetGroupTypeAuthorizationRequired(ThisObject, POPIsUsed);
	
	ConnectIncomingMailPort();
	SetKeepEmailsAtServerSettingKind();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetGroupTypeAuthorizationRequired(Form, POPIsUsed)
	
	If POPIsUsed Then
		Form.Items.AuthorizationRequiredOnSendMail.Title = NStr("vi = 'Khi gửi thư, cần đăng nhập';
																|ru = 'При отправке писем требуется авторизация';
																|en = 'Outgoing server (POP) requires authentication'; fa = 'Outgoing server (POP) requires authentication';
																|it = 'Bisogna accedere per inviare le lettere';
																|pl = 'Podczas wysyłania e-maili jest wymagana autoryzacja';
																|tr = 'E-posta gönderirken yetkilendirme gerekiyor'");
	Else
		Form.Items.AuthorizationRequiredOnSendMail.Title = NStr("vi = 'Khi gửi thư, cần đăng nhập vào máy chủ thư đi (SMTP)';
																|ru = 'При отправке писем требуется авторизация на сервере исходящей почты (SMTP)';
																|en = 'Outgoing server (SMTP) requires authentication'; fa = 'Outgoing server (SMTP) requires authentication';
																|it = 'Per l''invio di mail è necessaria l''autorizzazione dal server della posta in uscita (SMTP)';
																|pl = 'Podczas wysyłania listów wymagana jest autoryzacja na serwerze poczty wychodzącej (SMTP)';
																|tr = 'E-posta gönderirken, giden posta sunucusunda (SMTP) yetkilendirme gereklidir.'");
	EndIf;

	Form.Items.AuthorizationOnSendMail.Visible = POPIsUsed;
	
EndProcedure

&AtClient
Procedure IncomingMailServerOnChange(Item)
	Object.IncomingMailServer = TrimAll(Lower(Object.IncomingMailServer));
EndProcedure

&AtClient
Procedure OutgoingMailServerOnChange(Item)
	Object.OutgoingMailServer = TrimAll(Lower(Object.OutgoingMailServer));
EndProcedure

&AtClient
Procedure EmailOnChange(Item)
	Object.Email = TrimAll(Object.Email);
EndProcedure

&AtClient
Procedure KeepEmailCopiesOnServerOnChange(Item)
	SetKeepEmailsAtServerSettingKind();
EndProcedure

&AtClient
Procedure DeleteMailFromServerOnChange(Item)
	SetKeepEmailsAtServerSettingKind();
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	PasswordChanged = True;
EndProcedure

&AtClient
Procedure PasswordEditTextChange(Item, Text, StandardProcessing)
	Items.Password.ChoiceButton = True;
EndProcedure

&AtClient
Procedure PasswordStartChoice(Item, ChoiceData, StandardProcessing)
	EmailOperationsClient.PasswordFieldStartChoice(Item, StandardProcessing);
EndProcedure

&AtClient
Procedure AccountAvailabilityOnChange(Item)
	Items.AccountUser.Enabled = UserAccountKind = "Personal1";
	NotifyOfChangesAccountOwner();
EndProcedure

&AtClient
Procedure AccountUserOnChange(Item)
	NotifyOfChangesAccountOwner();
EndProcedure

&AtClient
Procedure AuthorizationRequiredOnSendMailOnChange(Item)
	Items.AuthorizationOnSendMail.Enabled = Object.AuthorizationRequiredOnSendEmails;
	Items.AuthorizationOnSendMail.Visible = Object.ProtocolForIncomingMail = "POP";
EndProcedure

&AtClient
Procedure EncryptOnSendMailOnChange(Item)
	Object.UseSecureConnectionForOutgoingMail = EncryptOnSendMail = "SSL";
	ConnectOutgoingMailPort();
EndProcedure

&AtClient
Procedure EncryptOnReceiveMailOnChange(Item)
	Object.UseSecureConnectionForIncomingMail = EncryptOnReceiveMail = "SSL";
	ConnectIncomingMailPort();
EndProcedure

&AtClient
Procedure AuthorizationMethodOnSendMailOnChange(Item)
	Object.SignInBeforeSendingRequired = ?(AuthorizationMethodOnSendMail = "POP", True, False);
	SetKeepEmailsAtServerSettingKind();
EndProcedure

&AtClient
Procedure UseOnChange(Item)
	Items.FormCheckSettings.Enabled = Object.UseForSending Or Object.UseForReceiving;
EndProcedure

&AtClient
Procedure AuthenticationModeOnChange(Item)
	
	Object.EmailServiceAuthorization = AuthenticationOption = "OAuth";
	
#If MobileClient Then
	Items.Password.Visible = Not Object.EmailServiceAuthorization;
#Else
	Items.Password.Enabled = Not Object.EmailServiceAuthorization;
#EndIf
	
	If Object.EmailServiceAuthorization Then
		OpenHelpFormSettings(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_UpdateCommands()
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	EndIf;
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	Write(New Structure("WriteAndClose"));
	
EndProcedure

&AtClient
Procedure CheckSettings(Command)
	ExecuteSettingsCheck();
EndProcedure

&AtClient
Procedure OpenSetupWizard(Command)
	
	OpenHelpFormSettings();
	
EndProcedure

&AtClient
Procedure ContinueSetup(Command)
	
	If AuthenticationOption = "Password" And IsBlankString(Password) Then
		CommonClient.MessageToUser(NStr("ru = 'Введите пароль учетной записи';
										|vi = 'Enter the account password';
										|en = 'Enter the account password'; fa = 'رمز عبور حساب را وارد کنید';
										|it = 'Enter the account password';
										|pl = 'Enter the account password';
										|tr = 'Hesap şifresini girin'"), , "Password");
		Return;
	EndIf;
	
	Modified = False;
	
	AccountParameters1 = AccountParameters1();
	FillPropertyValues(AccountParameters1, Object);
	AccountParameters1.Password = Password;
	AccountParameters1.AuthenticationOption = AuthenticationOption;
	
	Close(AccountParameters1);
	
EndProcedure

&AtServerNoContext
Function AccountParameters1()
	
	Return Catalogs.EmailAccounts.AccountParameters1();
	
EndFunction

#EndRegion

#Region Private

&AtServer
Procedure SetPropertiesOnCreateViaAssistant()
	
	Items.IncomingMailServer.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Сервер %1';
			|vi = '%1 server';
			|en = '%1 server'; fa = '%1 server';
			|it = 'Server %1';
			|pl = 'Serwer%1';
			|tr = 'Sunucu %1'"), Object.ProtocolForIncomingMail);
	
	If ValueIsFilled(Object.AccountOwner) Then
		UserAccountKind = "Personal1";
	Else
		UserAccountKind = "Shared3";
	EndIf;
	
	Items.AuthenticationMethodMailService.Visible = False;
	Items.AuthenticationPassword.Visible = False;
	
	AuthenticationOption = "Password";
	Object.EmailServiceAuthorization = False;
	
	Items.Password.Enabled = Not Object.EmailServiceAuthorization;
	Items.Password.TitleLocation = FormItemTitleLocation.Auto;
	
	Items.FormWriteAndClose.Visible = False;
	Items.FormWrite.Visible = False;
	Items.FormCheckSettings.Visible = False;
	Items.FormOpenSetupWizard.Visible = False;
	
	Items.FormContinue.Visible = True;
	Items.FormContinue.DefaultButton = True;
	
	POPIsUsed = Object.ProtocolForIncomingMail = "POP";
	SetGroupTypeAuthorizationRequired(ThisObject, POPIsUsed);
	
	Items.KeepMessagesOnServer.Visible = POPIsUsed And CanReceiveEmails;
	Items.MailRetentionPeriodSetup.Enabled = Object.KeepMessageCopiesAtServer;
	Items.KeepMailAtServerPeriod.Enabled = DeleteMailFromServer;
	
EndProcedure

&AtClient
Procedure SetKeepEmailsAtServerSettingKind()
	
	POPIsUsed = Object.ProtocolForIncomingMail = "POP";
	Items.KeepMessagesOnServer.Visible = POPIsUsed And CanReceiveEmails;
	Items.MailRetentionPeriodSetup.Enabled = Object.KeepMessageCopiesAtServer;
	Items.KeepMailAtServerPeriod.Enabled = DeleteMailFromServer;
	
EndProcedure

&AtClient
Procedure ConnectIncomingMailPort()
	If Object.ProtocolForIncomingMail = "IMAP" Then
		If Object.IncomingMailServerPort = 995 Then
			Object.IncomingMailServerPort = 993;
		EndIf;
	Else
		If Object.IncomingMailServerPort = 993 Then
			Object.IncomingMailServerPort = 995;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ConnectOutgoingMailPort()
	If Object.UseSecureConnectionForOutgoingMail Then
		If Object.OutgoingMailServerPort = 587 Then
			Object.OutgoingMailServerPort = 465;
		EndIf;
	Else
		If Object.OutgoingMailServerPort = 465 Then
			Object.OutgoingMailServerPort = 587;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure BeforeCloseConfirmationReceived(QuestionResult, AdditionalParameters) Export
	Write(New Structure("WriteAndClose"));
EndProcedure

&AtClient
Procedure NotifyOfChangesAccountOwner()
	Notify("OnChangeEmailAccountKind", UserAccountKind = "Personal1", ThisObject);
EndProcedure

&AtClient
Procedure FillObjectAttributes()
	
	If Not DeleteMailFromServer Then
		Object.KeepMailAtServerPeriod = 0;
	EndIf;
	
	If Object.ProtocolForIncomingMail = "IMAP" Then
		Object.KeepMessageCopiesAtServer = True;
		Object.KeepMailAtServerPeriod = 0;
	EndIf;
	
	If UserAccountKind = "Shared3" And ValueIsFilled(Object.AccountOwner) Then
		Object.AccountOwner = Undefined;
	EndIf;

EndProcedure

&AtClient
Procedure CheckFillingBeforeWrite(Cancel, WriteParameters) Export
	
	If Not CheckFilling() Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ValidatePermissionsBeforeWrite(Cancel, WriteParameters) Export
	
	Cancel = True;
	CallbackDescription = New CallbackDescription("AfterCheckPermissions", ThisObject, WriteParameters);
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
			RequestsForPermissionToUseExternalResources(), ThisObject, CallbackDescription);
	Else
		RunCallback(CallbackDescription, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckPasswordBeforeWrite(Cancel, WriteParameters) Export
	
	If Not PasswordCheckExecuted(WriteParameters) Then
		Cancel = True;
		PasswordCheck = "";
		CallbackDescription = New CallbackDescription("AfterPasswordEnter", ThisObject, WriteParameters);
		
		If Object.EmailServiceAuthorization Then
			OpenHelpFormSettings(True, CallbackDescription);
		Else
			OpenForm("Catalog.EmailAccounts.Form.CheckAccountAccess", , ThisObject, , , , CallbackDescription);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function RequestsForPermissionToUseExternalResources()
	
	Query = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		Query = ModuleSafeModeManager.RequestToUseExternalResources(Permissions(), Object.Ref);
	EndIf;
	
	Return CommonClientServer.ValueInArray(Query);
	
EndFunction

&AtServer
Function Permissions()
	
	Result = New Array;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	If Object.UseForSending Then
		Result.Add(
			ModuleSafeModeManager.PermissionToUseInternetResource(
				"SMTP",
				Object.OutgoingMailServer,
				Object.OutgoingMailServerPort,
				NStr("vi = 'Email.';
					|ru = 'Электронная почта.';
					|en = 'Email.'; fa = 'Email.';
					|it = 'Posta elettronica.';
					|pl = 'Poczta elektroniczna.';
					|tr = 'E-posta.'")));
	EndIf;
	
	If Object.UseForReceiving Then
		Result.Add(
			ModuleSafeModeManager.PermissionToUseInternetResource(
				Object.ProtocolForIncomingMail,
				Object.IncomingMailServer,
				Object.IncomingMailServerPort,
				NStr("vi = 'Email.';
					|ru = 'Электронная почта.';
					|en = 'Email.'; fa = 'Email.';
					|it = 'Posta elettronica.';
					|pl = 'Poczta elektroniczna.';
					|tr = 'E-posta.'")));
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure AfterCheckPermissions(Result, WriteParameters) Export
	
	If Result = DialogReturnCode.OK Then
		WriteParameters.Insert("PermissionsGranted");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Function PasswordCheckExecuted(WriteParameters)
	
	If Not WriteParameters.Property("PasswordEntered") Then
		AttributesValuesBeforeWrite = New Structure(AttributesRequiringPasswordToChange);
		FillPropertyValues(AttributesValuesBeforeWrite, Object);
		Return Not PasswordCheckIsRequired(Object.Ref, AttributesValuesBeforeWrite);
	EndIf;
	
	Return True;
	
EndFunction

&AtServerNoContext
Function PasswordCheckIsRequired(Ref, AttributesValues)
	Return Catalogs.EmailAccounts.PasswordCheckIsRequired(Ref, AttributesValues);
EndFunction

&AtClient
Procedure AfterPasswordEnter(Password, WriteParameters) Export
	
	If TypeOf(Password) = Type("String") Then
		PasswordCheck = Password;
		WriteParameters.Insert("PasswordEntered");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteSettingsCheck()
	If Modified Then
		Write(New Structure("CheckSettings"));
	Else
		CallbackDescription = New CallbackDescription("OnCompleteSettingsCheck", ThisObject);
		OpeningParameters = New Structure("Account", Object.Ref);
		OpenForm("Catalog.EmailAccounts.Form.ValidatingAccountSettings",
			OpeningParameters, ThisObject, , , , CallbackDescription);
	EndIf;
EndProcedure

&AtClient
Procedure OnCompleteSetup(Result, OnlyAuthorization) Export
		
	If OnlyAuthorization Then
		If Not ValueIsFilled(Result) Then
			Object.EmailServiceAuthorization = False;
			AuthenticationOption = "Password";
#If MobileClient Then
			Items.Password.Visible = Not Object.EmailServiceAuthorization;
#Else
			Items.Password.Enabled = Not Object.EmailServiceAuthorization;
#EndIf
			WarningText = NStr("vi = 'Không thể đăng nhập vào dịch vụ e-mail.';
								|ru = 'Не удалось авторизоваться на почтовом сервисе.';
								|en = 'Authorization in the email service failed.'; fa = 'Authorization in the email service failed.';
								|it = 'Non è stato possibile ricevere l''autorizzazione su servizio di posta.';
								|pl = 'Nie udało się autoryzować się w serwisie pocztowym.';
								|tr = 'Posta hizmetinde oturum açılamadı.'");
			If TypeOf(Result) = Type("String") Then
				WarningText = WarningText + Chars.LF + Result;
			EndIf;
			ShowMessageBox(Undefined, WarningText);
		EndIf;
		Return;
	EndIf;
	
	Read();
	
EndProcedure

&AtServer
Procedure FillSettings()
	
	CanReceiveEmails = EmailOperationsInternal.SubsystemSettings().CanReceiveEmails;
	ShouldUsePOP3Protocol = EmailOperationsInternal.SubsystemSettings().ShouldUsePOP3Protocol;
	If Not ShouldUsePOP3Protocol And (Object.ProtocolForIncomingMail = "IMAP" Or Object.Ref.IsEmpty()) Then
		Object.ProtocolForIncomingMail = "IMAP";
		Items.Protocol.Visible = False;
	EndIf;
	Items.KeepMessagesOnServer.Visible = Object.ProtocolForIncomingMail = "POP" And CanReceiveEmails;
	
	Items.IncomingMailServer.Title = StringFunctionsClientServer.SubstituteParametersToString(
	NStr("vi = 'Máy chủ %1';
		|ru = 'Сервер %1';
		|en = '%1 server'; fa = '%1 server';
		|it = 'Server %1';
		|pl = 'Serwer%1';
		|tr = 'Sunucu %1'"), Object.ProtocolForIncomingMail);
	
	DeleteMailFromServer = Object.KeepMailAtServerPeriod > 0;
	If Not DeleteMailFromServer Then
		Object.KeepMailAtServerPeriod = 10;
	EndIf;
	
	If Not Object.Ref.IsEmpty() Then
		SetPrivilegedMode(True);
		PasswordIsSet = Common.ReadDataFromSecureStorage(Object.Ref) <> "";
		SetPrivilegedMode(False);
		Password = ?(PasswordIsSet, UUID, "");
		PasswordChanged = False;
		EmailOperationsInternal.CheckoutPasswordField(Items.Password);
		
		If Not Catalogs.EmailAccounts.EditionAllowed(Object.Ref) Then
			ReadOnly = True;
		EndIf;
	EndIf;
	
	Items.FormWriteAndClose.Enabled = Not ReadOnly;
	
	IsPersonalAccount = ValueIsFilled(Object.AccountOwner);
	Items.AccountUser.Enabled = IsPersonalAccount;
	UserAccountKind = ?(IsPersonalAccount, "Personal1", "Shared3");
	
	POPIsUsed = Object.ProtocolForIncomingMail = "POP";
	Items.AuthorizationOnSendMail.Enabled = Object.AuthorizationRequiredOnSendEmails;
	SetGroupTypeAuthorizationRequired(ThisObject, POPIsUsed);
	
	EncryptOnSendMail = ?(Object.UseSecureConnectionForOutgoingMail, "SSL", "Auto");
	EncryptOnReceiveMail = ?(Object.UseSecureConnectionForIncomingMail, "SSL", "Auto");
	
	AuthorizationMethodOnSendMail = ?(Object.SignInBeforeSendingRequired, "POP", "SMTP");
	Items.FormCheckSettings.Enabled = Object.UseForSending Or Object.UseForReceiving;
	Items.FormOpenSetupWizard.Enabled = Not Object.Ref.IsEmpty() And Not ReadOnly;
	
	If Object.EmailServiceAuthorization Then
		AuthenticationOption = "OAuth";
	Else
		AuthenticationOption = "Password";
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.Password.Visible = Not Object.EmailServiceAuthorization;
	Else
		Items.Password.Enabled = Not Object.EmailServiceAuthorization;
	EndIf;
	
EndProcedure

// Sequentially calls the specified handlers in the BeforeWrite event via the idle handler.
&AtClient
Procedure AttachHandlersBeforeWrite(Handlers, Form, Cancel, WriteParameters)
	
	If Not WriteParameters.Property("HandlersBeforeWrite") Then
		WriteParameters.Insert("HandlersBeforeWrite", New Structure)
	EndIf;
	
	For Each Handler In Handlers Do
		If Not WriteParameters.HandlersBeforeWrite.Property(Handler.ProcedureName) Then
			WriteParameters.HandlersBeforeWrite.Insert(Handler.ProcedureName, False);
		EndIf;
	EndDo;
	
	For Each Validation In WriteParameters.HandlersBeforeWrite Do
		If Validation.Value = False Then
			Cancel = True;
			CallbackDescription = New CallbackDescription(Validation.Key, Form, WriteParameters);
			
			ParameterName = "StandardSubsystems.IdleHandlerBeforeWriteInForm";
			If ApplicationParameters[ParameterName] = Undefined Then
				ApplicationParameters.Insert(ParameterName, New Array);
			EndIf;
			IdleHandlerBeforeWriteInForm = ApplicationParameters[ParameterName]; // Array
			IdleHandlerBeforeWriteInForm.Add(CallbackDescription);
			
			AttachIdleHandler("ExecuteCheckBeforeWriteInForm", 0.1, True);
			Return;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ExecuteCheckBeforeWriteInForm()
	
	ParameterName = "StandardSubsystems.IdleHandlerBeforeWriteInForm";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Array);
	EndIf;
	IdleHandlers = ApplicationParameters[ParameterName];
	
	If IdleHandlers.Count() > 0 Then
		CallbackDescription = IdleHandlers[0];
		ProcedureName = IdleHandlers[0].ProcedureName;
		Form = IdleHandlers[0].Module; // ManagedFormExtensionForCatalogs
		WriteParameters = IdleHandlers[0].AdditionalParameters;
		IdleHandlers.Delete(0);
		WriteParameters.HandlersBeforeWrite[ProcedureName] = True;
		Cancel = False;
		RunCallback(CallbackDescription, Cancel);
		If Not Cancel Then
			Form.Write(WriteParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenHelpFormSettings(Val OnlyAuthorization = False, Val CallbackDescription = Undefined)
	
	If CallbackDescription = Undefined Then
		CallbackDescription = New CallbackDescription("OnCompleteSetup", ThisObject, OnlyAuthorization);
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Key", Object.Ref);
	If OnlyAuthorization Then
		OpeningParameters.Insert("OnlyAuthorization", True);
	Else
		OpeningParameters.Insert("Reconfigure", True);
	EndIf;
	
	OpenForm("Catalog.EmailAccounts.Form.AccountSetupWizard", 
		OpeningParameters, , , , , CallbackDescription);
		
	EndProcedure
	
&AtClient
Procedure OnCompleteSettingsCheck(WayFix, AdditionalParameters = Undefined) Export
	
	If ValueIsFilled(WayFix) Then
		FixingMethodID = WayFix;
		AttachIdleHandler("GoToFix", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToFix()
	
	ShowCorrectionMethod(FixingMethodID);
	FixingMethodID = Undefined;
	
EndProcedure

&AtServer
Function IsEmailServiceAuthorizationAvailable()
	
	If Not ValueIsFilled(Object.Email) Then
		Return False;
	EndIf;
	
	Return ValueIsFilled(SettingsAuthorizationOnMailServer().Ref);
	
EndFunction

// Returns:
//   See Catalogs.InternetServicesAuthorizationSettings.SettingsAuthorizationInternetService
//
&AtServer
Function SettingsAuthorizationOnMailServer()
	
	Return ConnectionSettingsByEmailAddress().AuthorizationSettings;
	
EndFunction

// Returns:
//   See Catalogs.EmailAccounts.ConnectionSettingsByEmailAddress
//
&AtServer
Function ConnectionSettingsByEmailAddress()
	
	SetPrivilegedMode(True);
	
	Return Catalogs.EmailAccounts.ConnectionSettingsByEmailAddress(
		Object.Email,
		Password);
	
EndFunction

#EndRegion
