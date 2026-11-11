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
	
	If Not AccessRight("CollaborationSystemInfoBaseRegistration", Metadata) Then 
		Cancel = True;
		Return;
	EndIf;
	
	If Common.AccessToInternetServicesAllowed() Then
		InstallDefaultCollaborationServer(ThisObject);
		Items.GroupCommentAccessToInternetServicesAllowed.Visible = False;
	Else
		CollaborationServerChoice = 1;
		Items.CollaborationServerChoiceDialog.Enabled = False;
		Items.GroupCommentAccessToInternetServicesAllowed.Visible = True;
		UpdateServerChoiceItems(ThisObject);
		Items.CollaborationServerChoiceGroup.Show();
	EndIf;

	InfobaseName = Constants.SystemTitle.Get();
	If Not ValueIsFilled(InfobaseName) Then
		InfobaseName = Metadata.BriefInformation;
	EndIf;
	RegistrationState = CurrentRegistrationState();
	
	OnChangeFormState(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConstantsSet" And Source = "AllowAccessToInternetServices" Then
		OnChangeInternetServicesAccessPermissions();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CreateAdministratorRequiredNoteURLProcessing(Item, 
	FormattedStringURL, StandardProcessing)
	
	Close();
	
EndProcedure

&AtClient
Procedure CollaborationServerChoiceDialogOnChange(Item)
	InstallDefaultCollaborationServer(ThisObject);
	UpdateServerChoiceItems(ThisObject);
EndProcedure

&AtClient
Procedure CollaborationServerChoiceLocallyOnChange(Item)
	UpdateServerChoiceItems(ThisObject);
EndProcedure

&AtClient
Procedure CollaborationServerAddressOnChange(Item)
	CollaborationServer = CollaborationServerAddress;
	UpdateServerChoiceItems(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateAccount(Command)
	
	If RegistrationState = "UnlockRequired" Then 
		OnUnlock();
	ElsIf RegistrationState = "NotRegistered1" Then 
		OnReceiveRegistrationCode();
	ElsIf RegistrationState = "WaitForConfirmationCodeInput" Then 
		OnRegister();
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If RegistrationState = "WaitForConfirmationCodeInput" Then 
		OnRejectConfirmationCodeInput();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region PrivateEventHandlers

&AtClient
Procedure OnUnlock()
	
	ConversationsInternalServerCall.Unlock();
	
	RegistrationState = "Registered1";
	OnChangeFormState(ThisObject);
	Notify("ConversationsEnabled", True);
	RefreshInterface();
	
EndProcedure

&AtClient
Procedure OnReceiveRegistrationCode()
	
	If CollaborationServerChoice = 0 Then
		ErrorText = AccessToInternetServicesAllowed();
		If Not IsBlankString(ErrorText) Then
			ShowMessageBox(, ErrorText);
			Return;
		EndIf;
	EndIf;
	
	If IsBlankString(Email) Then 
		ShowMessageBox(, NStr("vi = 'Chưa điền địa chỉ thư';
								|ru = 'Адрес электронной почты не заполнен';
								|en = 'Email address is not filled in'; fa = 'Email address is not filled in';
								|it = 'Indirizzo di posta elettronica non compilato';
								|pl = 'Adres e-mail nie jest wypełniony';
								|tr = 'E-posta adresi doldurulmadı'"));
		Return;
	EndIf;
	
	If Not CommonClientServer.EmailAddressMeetsRequirements(Email) Then 
		ShowMessageBox(, NStr("vi = 'Địa chỉ email bị lỗi';
								|ru = 'Адрес электронной почты содержит ошибки';
								|en = 'The email address contains errors'; fa = 'The email address contains errors';
								|it = 'L''indirizzo di posta elettronica contiene degli errori';
								|pl = 'Adres poczty elektronicznej zawiera błędy';
								|tr = 'E-posta adresi hata içeriyor.'"));
		Return;
	EndIf;
	
	If CollaborationServerChoice = 1 And IsBlankString(CollaborationServerAddress) Then
		ShowMessageBox(, NStr("vi = 'Địa chỉ của máy chủ giao tiếp cục bộ không được chỉ định';
								|ru = 'Не указан адрес локального сервера взаимодействия';
								|en = 'URL of local collaboration server is not specified'; fa = 'URL of local collaboration server is not specified';
								|it = 'Non è indicato l''indirizzo del server di collaborazione locale';
								|pl = 'Nie podano adresu lokalnego serwera interakcji';
								|tr = 'Yerel ortak çalışma sunucusunun adresi belirtilmedi'"));
		Return;
	EndIf;
		
	RegistrationParameters = New CollaborationSystemInfoBaseRegistrationParameters;
	RegistrationParameters.ServerAddress = CollaborationServer;
	RegistrationParameters.Email = Email;
	RegistrationParameters.InfoBaseName = InfobaseName;
	If CollaborationServerChoice = 1 Then
		RegistrationParameters.ActivationCode = Format(CommonClient.SessionDate(), NStr("ru = 'ДФ=''yyyMMddHHmmss''';
																						|vi = 'DF=''yyyMMddHHmmss''';
																						|en = 'DF=''yyyMMddHHmmss'''; fa = 'DF=''yyyMMddHHmmss''';
																						|it = 'DF=''yyyMMddHHmmss''';
																						|pl = 'DF=''yyyMMddHHmmss''';
																						|tr = 'DF=''yyyMMddHHmmss'''"));
	EndIf;
	
	Notification = New CallbackDescription("AfterReceiveRegistrationCodeSuccessfully", ThisObject,,
		"OnProcessGetRegistrationCodeError", ThisObject);
	CollaborationSystem.BeginInfoBaseRegistration(Notification, RegistrationParameters);
	
	RegistrationState = "WaitForCollaborationServerResponse";
	OnChangeFormState(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterReceiveRegistrationCodeSuccessfully(RegistrationCompleted, MessageText, Context) Export
	
	If ValueIsFilled(MessageText) Then
		ShowMessageBox(, MessageText);
	EndIf;
	
	RegistrationState = "WaitForConfirmationCodeInput";
	OnChangeFormState(ThisObject);
	
EndProcedure

&AtClient
Procedure OnProcessGetRegistrationCodeError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	StandardSubsystemsClient.OutputErrorInfo(ErrorInfo);
	
	RegistrationState = "NotRegistered1";
	OnChangeFormState(ThisObject);
	
EndProcedure

&AtClient
Procedure OnRegister()
	
	If IsBlankString(RegistrationCode) Then 
		ShowMessageBox(, NStr("vi = 'Chưa điền mã Quỹ hưu';
								|ru = 'Код регистрации не заполнен';
								|en = 'Registration code is required'; fa = 'Registration code is required';
								|it = 'Il codice di registrazione non è compilato.';
								|pl = 'Kod rejestracji nie jest wypełniony';
								|tr = 'Kayıt kodu doldurulmadı'"));
		Return;
	EndIf;
	
	RegistrationParameters = New CollaborationSystemInfoBaseRegistrationParameters;
	RegistrationParameters.ServerAddress = CollaborationServer;
	RegistrationParameters.Email = Email;
	RegistrationParameters.InfoBaseName = InfobaseName;
	RegistrationParameters.ActivationCode = TrimAll(RegistrationCode);
	
	Notification = New CallbackDescription("AfterRegisterSuccessfully", ThisObject,,
		"OnProcessRegistrationError", ThisObject);
	
	CollaborationSystem.BeginInfoBaseRegistration(Notification, RegistrationParameters);
	
	RegistrationState = "WaitForCollaborationServerResponse";
	OnChangeFormState(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterRegisterSuccessfully(RegistrationCompleted, MessageText, Context) Export
	
	If RegistrationCompleted Then 
		Notify("ConversationsEnabled", True);
		RegistrationState = "Registered1";
	Else 
		ShowMessageBox(, MessageText);
		RegistrationState = "WaitForConfirmationCodeInput";
	EndIf;
	
	OnChangeFormState(ThisObject);
	
EndProcedure

&AtClient
Procedure OnProcessRegistrationError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	StandardSubsystemsClient.OutputErrorInfo(ErrorInfo);
	
	RegistrationState = "WaitForConfirmationCodeInput";
	OnChangeFormState(ThisObject);
	
EndProcedure

&AtClient
Procedure OnRejectConfirmationCodeInput()
	
	Notification = New CallbackDescription("AfterConfirmRefuseToEnterConfirmationCode", ThisObject);
	ShowQueryBox(Notification, 
		NStr("vi = 'Nếu bạn từ chối nhập, mã được gửi qua e-mail sẽ trở nên không hợp lệ.
		           |Chỉ có thể tiếp tục khi yêu cầu mã mới.';
		           |ru = 'При отказе от ввода высланный на электронную почту код станет недействительным.
		           |Продолжение будет возможно только с запросом нового кода.';
		           |en = 'If not entered, the code sent to your email will be invalid.
		           |You can continue only after a new code is requested.'; fa = 'If not entered, the code sent to your email will be invalid.
		           |You can continue only after a new code is requested.';
		           |it = 'Al rifiuto di inserire, il codice inviato via e-mail non sarà più valido.
		           |La continuazione sarà possibile solo con una richiesta di un nuovo codice.';
		           |pl = 'W przypadku rezygnacji z wprowadzania wysłany na e-mail kod zostanie unieważniony.
		           |Kontynuacja będzie możliwa tylko z zapytaniem o nowy kod.';
		           |tr = 'E-postanıza gönderilen kodu girmezseniz kod geçersiz hale gelir.
		           |Yalnızca yeni bir kod talep ederek devam edebilirsiniz.'"), 
		QuestionDialogMode.OKCancel,, DialogReturnCode.Cancel);
	
EndProcedure

&AtClient
Procedure AfterConfirmRefuseToEnterConfirmationCode(QuestionResult, Context) Export 
	
	If QuestionResult = DialogReturnCode.OK Then 
		RegistrationState = "NotRegistered1";
		OnChangeFormState(ThisObject);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure OnChangeFormState(Form) 
	
	RegistrationState = Form.RegistrationState;
	
	If RegistrationState = "WaitForConfirmationCodeInput" Then
		Form.RegistrationCode = "";
	EndIf;
	
	SetPage(Form);
	RefreshCommandBarButtonsVisibility(Form);
	UpdateServerChoiceItems(Form);
	
EndProcedure

#EndRegion

#Region PresentationModel

// Returns:
//   String - "CreateAdministratorRequired",
//   "NotRegistered",
//   "Registered",
//   "WaitForConfirmationCodeInput",
//   "WaitForCollaborationServerResponse".
//
&AtServerNoContext
Function CurrentRegistrationState()
	
	CurrentUser = InfoBaseUsers.CurrentUser();
	
	If IsBlankString(CurrentUser.Name) Then 
		Return "CreateAdministratorRequired";
	EndIf;
	
	If ConversationsInternal.Locked2() Then 
		Return "UnlockRequired";
	EndIf;
	
	Return ?(CollaborationSystem.InfoBaseRegistered(),
		"Registered1", "NotRegistered1");
	
EndFunction

&AtClientAtServerNoContext
Procedure InstallDefaultCollaborationServer(Form)
	Form.CollaborationServer = "wss://1cdialog.com:443";
EndProcedure

#EndRegion

#Region Presentations

&AtClientAtServerNoContext
Procedure SetPage(Form)
	
	RegistrationState = Form.RegistrationState;
	Items = Form.Items;
	
	If RegistrationState = "CreateAdministratorRequired" Then 
		Items.Pages.CurrentPage = Items.CreateAdministratorRequired;
	ElsIf RegistrationState = "UnlockRequired" Then 
		Items.Pages.CurrentPage = Items.UnlockRequired;
	ElsIf RegistrationState = "NotRegistered1" Then 
		Items.Pages.CurrentPage = Items.OfferRegistration;
	ElsIf RegistrationState = "WaitForConfirmationCodeInput" Then 
		Items.Pages.CurrentPage = Items.EnterRegistrationCode;
	ElsIf RegistrationState = "WaitForCollaborationServerResponse" Then
		Items.Pages.CurrentPage = Items.TimeConsumingOperation;
	ElsIf RegistrationState = "Registered1" Then
		Items.Pages.CurrentPage = Items.RegistrationComplete;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshCommandBarButtonsVisibility(Form)
	
	RegistrationState = Form.RegistrationState;
	
	If RegistrationState = "CreateAdministratorRequired" Then 
		Form.Items.CreateAccount.Visible = False;
		Form.Items.Back.Visible = False;
	ElsIf RegistrationState = "UnlockRequired" Then 
		Form.Items.CreateAccount.Visible = True;
		Form.Items.CreateAccount.Title = NStr("vi = 'Phục hồi kết nối';
												|ru = 'Восстановить подключение';
												|en = 'Restore connection'; fa = 'Restore connection';
												|it = 'Ripristinare la connessione';
												|pl = 'Przywrócić połączenie';
												|tr = 'Bağlantıyı geri yükle'");
		Form.Items.Back.Visible = False;
	ElsIf RegistrationState = "NotRegistered1" Then 
		Form.Items.CreateAccount.Visible = True;
		Form.Items.Back.Visible = False;
	ElsIf RegistrationState = "WaitForConfirmationCodeInput" Then 
		Form.Items.CreateAccount.Visible = True;
		Form.Items.Back.Visible = True;
	ElsIf RegistrationState = "WaitForCollaborationServerResponse" Then 
		Form.Items.CreateAccount.Visible = False;
		Form.Items.Back.Visible = False;
	ElsIf RegistrationState = "Registered1" Then 
		Form.Items.CreateAccount.Visible = False;
		Form.Items.Back.Visible = False;
		Form.Items.Close.DefaultButton = True;
		Form.Items.Close.Title = NStr("vi = 'Đồng ý';
										|ru = 'Готово';
										|en = 'Finish'; fa = 'پایان';
										|it = 'Fine';
										|pl = 'Finish';
										|tr = 'Bitiş'");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateServerChoiceItems(Form)
	CollaborationServerPresentation = ?(Form.CollaborationServerChoice = 0, 
		NStr("vi = '1C: Đối thoại';
			|ru = '1С:Диалог';
			|en = '1C:Dialog'; fa = '1C:Dialog';
			|it = '1C:Dialog';
			|pl = '1С:Dialog';
			|tr = '1C:Dialog'"),
		Form.CollaborationServer);
	CaptionPresentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kết nối với %1';
			|ru = 'Подключаться к %1';
			|en = 'Connect to %1'; fa = 'Connect to %1';
			|it = 'Collegarsi a %1';
			|pl = 'Podłącz do %1';
			|tr = '%1 bağlan'"),
		CollaborationServerPresentation);
			
	CommonClientServer.SetFormItemProperty(
		Form.Items,
		"LocalCollaborationServerGroup",
		"Title",
		CaptionPresentation);
	CommonClientServer.SetFormItemProperty(
		Form.Items,
		"LocalCollaborationServerGroup",
		"Enabled",
		Form.CollaborationServerChoice <> 0);
EndProcedure

&AtServerNoContext
Function AccessToInternetServicesAllowed()
	If Not Common.AccessToInternetServicesAllowed() Then
		Return Common.AccessToInternetServicesDeniedMessageText();
	EndIf;
	Return "";
EndFunction

&AtServer
Procedure OnChangeInternetServicesAccessPermissions()
	AccessToInternetServicesAllowed = Common.AccessToInternetServicesAllowed();
	Items.CollaborationServerChoiceDialog.Enabled = AccessToInternetServicesAllowed;
	Items.GroupCommentAccessToInternetServicesAllowed.Visible = Not AccessToInternetServicesAllowed;
EndProcedure

#EndRegion

#EndRegion