
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UserNotificationsOfEvents.CheckPrepareConnectionToInteractionSystem();
	
	BotAddress = Constants.AddressOfTelegramNotificationBot.Get();
	UseNotifications = GetFunctionalOption("UseUserNotificationsViaTelegram");
	IntegrationDetails = UserNotificationsOfEvents.FindExistingIntegration(BotAddress);
	BotAddress = "https://t.me/" + BotAddress;
	
	If Not ValueIsFilled(BotAddress)
		Or Not UseNotifications
		Or IntegrationDetails = Undefined
		Or Not IntegrationDetails.Use Then
		Raise NStr("ru = 'В системе не настроена интеграция с Telegram. Обратитесь к Администратору.';
					|vi = 'Integration with Telegram is not configured in the system. Contact the administrator.';
					|en = 'Integration with Telegram is not configured in the system. Contact the administrator.'; fa = 'Integration with Telegram is not configured in the system. Contact the administrator.';
					|it = 'Integration with Telegram is not configured in the system. Contact the administrator.';
					|pl = 'Integration with Telegram is not configured in the system. Contact the administrator.';
					|tr = 'Sistemde Telegram entegrasyonu yapılandırılmadı. Yöneticinizle iletişime geçin.'");
	EndIf;
	
	CurrentUser = Users.AuthorizedUser();
	
	NotificationAddress = UserNotificationsOfEvents.NotificationAddressByUser(
		CurrentUser,
		Enums.UserNotificationsMethods.Telegram);
	AddressIsSet = ValueIsFilled(NotificationAddress);
	
	Generate_QRCode(BotAddress);
	If AddressIsSet Then
		Items.ConnectionPages.CurrentPage = Items.IsAlreadyConnectedPage;
		Items.DecorationBotAddressDescription.Title = NStr("ru = 'Адрес бота для получения оповещений в Telegram.';
															|vi = 'Address of the bot for receiving notifications in Telegram.';
															|en = 'Address of the bot for receiving notifications in Telegram.'; fa = 'Address of the bot for receiving notifications in Telegram.';
															|it = 'Address of the bot for receiving notifications in Telegram.';
															|pl = 'Address of the bot for receiving notifications in Telegram.';
															|tr = 'Telegram''da bildirim almak için kullanılan bot adresi.'");
	Else
		Items.ConnectionPages.CurrentPage = Items.ConnectionPage;
		FillInTemporaryCode();
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Items.ConnectionPages.CurrentPage = Items.ConnectionPage Then
		AttachIdleHandler("Countdown", 1);
		ClientNotifications.AttachHandler("ConnectingTelegramUser", 
			New CallbackDescription("AfterUserConnecting", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	ClientNotifications.DetachHandler("ConnectingTelegramUser");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BotAddressClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	FileSystemClient.OpenURL(BotAddress);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GetCode(Command)
	
	FillInTemporaryCode();
	AttachIdleHandler("Countdown", 1);
	
EndProcedure

&AtClient
Async Procedure DeleteRegistration(Command)
	
	QueryText = NStr("ru = 'Оповещения перестанут направляться в Telegram.
		|Вы уверены, что хотите удалить регистрацию в боте Telegram?';
		|vi = 'Notifications will no longer be sent to Telegram.
		|Are you sure you want to unregister in the Telegram bot?';
		|en = 'Notifications will no longer be sent to Telegram.
		|Are you sure you want to unregister in the Telegram bot?'; fa = 'Notifications will no longer be sent to Telegram.
		|Are you sure you want to unregister in the Telegram bot?';
		|it = 'Notifications will no longer be sent to Telegram.
		|Are you sure you want to unregister in the Telegram bot?';
		|pl = 'Notifications will no longer be sent to Telegram.
		|Are you sure you want to unregister in the Telegram bot?';
		|tr = 'Telegram''da artık bildirim gönderilmeyecektir.
		|Telegram botundan kaydınızı silmek istediğinizden emin misiniz?'");
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo);
	If Response = DialogReturnCode.Yes Then
		DeleteUserRegistration();
		ShowUserNotification(NStr("ru = 'Удаление регистрации в боте Telegram.';
									|vi = 'Unregistering in the Telegram bot.';
									|en = 'Unregistering in the Telegram bot.'; fa = 'Unregistering in the Telegram bot.';
									|it = 'Unregistering in the Telegram bot.';
									|pl = 'Unregistering in the Telegram bot.';
									|tr = 'Telegram botundaki kaydın silinmesi.'"),,
			NStr("ru = 'Удаление регистрации в боте Telegram успешно завершено.';
				|vi = 'You are successfully unregistered in the Telegram bot.';
				|en = 'You are successfully unregistered in the Telegram bot.'; fa = 'You are successfully unregistered in the Telegram bot.';
				|it = 'You are successfully unregistered in the Telegram bot.';
				|pl = 'You are successfully unregistered in the Telegram bot.';
				|tr = 'Telegram botundaki kaydın silinmesi başarıyla tamamlandı.'"),
			PictureLib.Information32);
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Countdown()
	
	If Timer > Date(1,1,1) Then
		Timer = Timer - 1;
	Else
		SetVisibilityOfTimer(ThisObject, False);
		DetachIdleHandler("Countdown");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTemporaryCode()
	
	SetPrivilegedMode(True);
	CodeData = UserNotificationsOfEvents.TemporaryCodeForConnectingToTelegram(CurrentUser);
	SetPrivilegedMode(False);
	
	Code = CodeData.Code;
	Timer = Date(1,1,1) + CodeData.ExpirationDateInSeconds;
	
	SetVisibilityOfTimer(ThisObject, True);
	
EndProcedure

&AtServer
Procedure Generate_QRCode(BotAddress)
	
	BinaryQRCodeData = BarcodeGeneration.QRCodeData(BotAddress,3, 190);
	QRCode = PutToTempStorage(BinaryQRCodeData, UUID);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfTimer(Form, Enable)
	
	Items = Form.Items;
	
	If Enable Then
		Items.PageTimerGroup.CurrentPage = Items.TimerGroup;
		Items.GetCode.Enabled = False;
	Else
		Items.PageTimerGroup.CurrentPage = Items.TimerIsEmptyGroup;
		Items.GetCode.Enabled = True;
		Form.Code = "";
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteUserRegistration()
	
	UserNotificationsOfEvents.RecordMatchedMessengerUser(CurrentUser,
		"",
		Enums.UserNotificationsMethods.Telegram);
	
EndProcedure

&AtClient
Procedure AfterUserConnecting(NoticeData, AddlParameters = Undefined) Export
	If NoticeData.Property("User")
		And NoticeData.User = CurrentUser Then
		Close();
	EndIf;
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
