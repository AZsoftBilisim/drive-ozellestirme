#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not GetFunctionalOption("UseUserNotificationsViaTelegram") Then
		Raise NStr("ru = 'В системе не включено использование интеграции оповещений с Telegram.';
					|vi = 'Telegram notification integration is not enabled in the system.';
					|en = 'Telegram notification integration is not enabled in the system.'; fa = 'Telegram notification integration is not enabled in the system.';
					|it = 'Telegram notification integration is not enabled in the system.';
					|pl = 'Telegram notification integration is not enabled in the system.';
					|tr = 'Sistemde Telegram ile bildirim entegrasyonu etkinleştirilmedi.'");
	EndIf;
	
	UserNotificationsOfEvents.CheckPrepareConnectionToInteractionSystem();
	
	BotAddress = Constants.AddressOfTelegramNotificationBot.Get();
	If ValueIsFilled(BotAddress) Then
		IntegrationDetails = UserNotificationsOfEvents.FindExistingIntegration(BotAddress);
		FillInExistingIntegration(IntegrationDetails);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Async Procedure ActivateBot(Command)
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Description = TrimAll(Description);
	ClearRecipientSettings = False;
	If ValueIsFilled(BotAddress) And TrimAll(Description) <> BotAddress Then
		QueryText = NStr("ru = 'Наименование бота отличается от сохраненного ранее.
		|После изменения бота все существующие интеграции будут удалены. Продолжить?';
		|vi = 'The bot name differs from the one saved earlier.
		|After changing the bot, all existing integrations will be deleted. Continue?';
		|en = 'The bot name differs from the one saved earlier.
		|After changing the bot, all existing integrations will be deleted. Continue?'; fa = 'The bot name differs from the one saved earlier.
		|After changing the bot, all existing integrations will be deleted. Continue?';
		|it = 'The bot name differs from the one saved earlier.
		|After changing the bot, all existing integrations will be deleted. Continue?';
		|pl = 'The bot name differs from the one saved earlier.
		|After changing the bot, all existing integrations will be deleted. Continue?';
		|tr = 'Bot adı, daha önce kaydedilenden farklı.
		|Bot adı değiştirildikten sonra, mevcut tüm entegrasyonlar silinecektir. Devam edilsin mi?'");
		
		Result = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.OKCancel);
		If Result = DialogReturnCode.OK Then
			ClearRecipientSettings = True;
		ElsIf Result = DialogReturnCode.Cancel Then
			Return
		EndIf;
	EndIf;
	
	SetAsActiveServer(ClearRecipientSettings);
	Close(True);
	
EndProcedure

&AtClient
Procedure Disconnect(Command)
	
	DisconnectServer();
	Close(True);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetAsActiveServer(ClearRecipientSettings)
	
	IntegrationDetails = UserNotificationsOfEvents.FindExistingIntegration(Description);
	If IntegrationDetails <> Undefined Then
		Id = IntegrationDetails.ID;
	EndIf;
	
	IntegrationParameters = ConversationsInternal.IntegrationParameters();
	IntegrationParameters.Id = Id;
	IntegrationParameters.Key = Description;
	IntegrationParameters.Type = ConversationsInternalClientServer.ExternalSystemsTypes().Telegram;
	IntegrationParameters.Attendees = MandatoryParticipants();
	IntegrationParameters.token = Token;
	
	Try
		Bot = UserNotificationsOfEvents.GetCreateCollaborationSystem();
		
		IntegrationParameters.Attendees.Add(Bot.User);
		UserNotificationsOfEvents.CreateChangeIntegration(IntegrationParameters);
		
		Constants.AddressOfTelegramNotificationBot.Set(Description);
		
		If ClearRecipientSettings Then
			UserNotificationsOfEvents.ClearSettingsForNotificationRecipients(
				Enums.UserNotificationsMethods.Telegram);
			BotAddress = Description;
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		WriteLogEvent(ConversationsInternal.EventLogEvent(),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("ru = 'Не удалось записать настройки бота по причине:';
				|vi = 'Cannot save the bot settings. Reason:';
				|en = 'Cannot save the bot settings. Reason:'; fa = 'Cannot save the bot settings. Reason:';
				|it = 'Cannot save the bot settings. Reason:';
				|pl = 'Cannot save the bot settings. Reason:';
				|tr = 'Bot ayarları şu nedenle kaydedilemedi:'"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	
EndProcedure

&AtServer
Procedure DisconnectServer()
	
	Try
		ConversationsInternal.DisableIntegration(Id);
		UserNotificationsOfEvents.DeleteCollaborationSystemBots();
		UserNotificationsOfEvents.ClearSettingsForNotificationRecipients(Enums.UserNotificationsMethods.Telegram);
	Except
		ErrorInfo = ErrorInfo();
		WriteLogEvent(ConversationsInternal.EventLogEvent(),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("ru = 'Не удалось записать настройки бота по причине:';
				|vi = 'Cannot save the bot settings. Reason:';
				|en = 'Cannot save the bot settings. Reason:'; fa = 'Cannot save the bot settings. Reason:';
				|it = 'Cannot save the bot settings. Reason:';
				|pl = 'Cannot save the bot settings. Reason:';
				|tr = 'Bot ayarları şu nedenle kaydedilemedi:'"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	
EndProcedure

&AtServer
Function MandatoryParticipants()
	
	Attendees = New Array();
	
	NewParticipant = UserNotificationsOfEventsCached.CollaborationSystemUserIDNotificationsAuthor();
	Attendees.Add(NewParticipant);
	
	Return Attendees;
	
EndFunction

&AtServer
Procedure FillInExistingIntegration(IntegrationDetails)
	
	If IntegrationDetails <> Undefined Then
		Description = IntegrationDetails.Presentation;
		Token = IntegrationDetails.ExternalSystemParameters.Get("token");
		Id = IntegrationDetails.ID;
	
		If IntegrationDetails.Use Then
			Items.Close.Title = NStr("vi = 'Ghi lại và đóng';
									|ru = 'Записать и закрыть';
									|en = 'Save and close'; fa = 'ذخیره و بستن';
									|it = 'Salvare e chiudere';
									|pl = 'Zapisz i zamknij';
									|tr = 'Kaydet ve kapat'");
			Items.Disconnect.Visible = True;
		Else
			Items.Close.Title = NStr("ru = 'Активировать';
									|vi = 'Activate';
									|en = 'Activate'; fa = 'فعال‌سازی';
									|it = 'Activate';
									|pl = 'Activate';
									|tr = 'Etkinleştir'");
			Items.Disconnect.Visible = False;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

