#Region Public

// Handler for clicking a button in the system interaction message panel.
// 
// Parameters:
//  Message - CollaborationSystemMessage - the message being processed.
//  Button - CollaborationSystemMessageButtonPanelButton - the pressed button.
Procedure OnCollaborationSystemMessageButtonPanelButtonClick(Message, Button) Export
	
	If Button.ActionName = "GoToListFormWithFilter" Then
		ReferencesArrray = New Array;
		For Each FilterValue In Button.Data.RefsMap Do
			For Each MapValue In FilterValue.Value Do
				ReferencesArrray.Add(MapValue);
			EndDo;
		EndDo;
		StructureFilter = New Structure("Ref", ReferencesArrray);
		OpeningParameters = New Structure("Filter", StructureFilter);
		OpenForm(Button.Data.FormName, OpeningParameters);
	ElsIf Button.ActionName = "GoToFollowLinksForm" Then
		OpeningParameters = New Structure("RefsMap", Button.Data.RefsMap);
		OpenForm(Button.Data.FormName, OpeningParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

Procedure OnStart(Parameters) Export
	
	CommandsGenerationHandler = New CallbackDescription("OnGenerateInteractionSystemCommands", ThisObject);
	CollaborationSystem.AttachGenerateCommandsHandler(CommandsGenerationHandler);
	
EndProcedure

Procedure SetUpNotifications(AdditionalParameters) Export
	
	If AdditionalParameters.CommandID = "ConfigureAllAlerts" Then
		OpeningParameters = New Structure("NotificationKind", AdditionalParameters.NotificationKind);
		OpenForm("InformationRegister.DisabledUserNotificationSettings.Form.PersonalSettings", OpeningParameters);
	ElsIf AdditionalParameters.CommandID = "DisableAllAlerts" Then
		UserNotificationsOfEventsServerCall.SetMessageDisplayMode(
			AdditionalParameters.ConversationID,
			True);
		ShowNotification(NStr("vi = 'Đã tắt tất cả thông báo về đối tượng này.';
								|ru = 'Отключены все оповещения по объекту.';
								|en = 'All notifications on the object are disabled.'; fa = 'All notifications on the object are disabled.';
								|it = 'All notifications on the object are disabled.';
								|pl = 'All notifications on the object are disabled.';
								|tr = 'Nesneyle ilgili tüm bildirimler devre dışı bırakıldı.'"));
	ElsIf AdditionalParameters.CommandID = "SubscribeToAlertsOnlyForMe" Then
		UserNotificationsOfEventsServerCall.SetMessageDisplayMode(
			AdditionalParameters.ConversationID,
			False,
			False);
		ShowNotification(NStr("vi = 'Đã đăng ký nhận tất cả thông báo về đối tượng này được gửi đến tôi.';
								|ru = 'Установлена подписка на все оповещения по объекту, адресованные мне.';
								|en = 'You are subscribed to all notifications on the object addressed to you.'; fa = 'You are subscribed to all notifications on the object addressed to you.';
								|it = 'You are subscribed to all notifications on the object addressed to you.';
								|pl = 'You are subscribed to all notifications on the object addressed to you.';
								|tr = 'Bana gönderilen, nesneyle ilgili tüm bildirimlere abonelik ayarlandı.'"));
	ElsIf AdditionalParameters.CommandID = "SubscribeToAllAlerts" Then
		UserNotificationsOfEventsServerCall.SetMessageDisplayMode(
			AdditionalParameters.ConversationID,
			False,
			True);
		ShowNotification(NStr("vi = 'Đã đăng ký nhận tất cả thông báo về đối tượng.';
								|ru = 'Установлена подписка на все оповещения по объекту.';
								|en = 'You are subscribed to all notifications on the object.'; fa = 'You are subscribed to all notifications on the object.';
								|it = 'You are subscribed to all notifications on the object.';
								|pl = 'You are subscribed to all notifications on the object.';
								|tr = 'Nesneyle ilgili tüm bildirimler için abonelik ayarlandı.'"));
	ElsIf AdditionalParameters.CommandID = "DisableCurrentAlert" Then
		UserNotificationsOfEventsServerCall.DisableNotificationByNotificationKind(
			AdditionalParameters.NotificationKind);
		ShowNotification(NStr("vi = 'Đã tắt thông báo dạng này.';
								|ru = 'Отключены оповещения данного вида.';
								|en = 'Notifications of this kind are disabled.'; fa = 'Notifications of this kind are disabled.';
								|it = 'Notifications of this kind are disabled.';
								|pl = 'Notifications of this kind are disabled.';
								|tr = 'Bu tür bildirimler devre dışı bırakıldı.'"));
	ElsIf AdditionalParameters.CommandID = "SubscribeToCurrentNotification" Then
		UserNotificationsOfEventsServerCall.SubscribeToNotificationtByNotificationKind(
			AdditionalParameters.NotificationKind);
		ShowNotification(NStr("vi = 'Đã đăng ký nhận thông báo dạng này.';
								|ru = 'Установлена подписка на оповещения данного вида.';
								|en = 'You are subscribed to notifications of this kind.'; fa = 'You are subscribed to notifications of this kind.';
								|it = 'You are subscribed to notifications of this kind.';
								|pl = 'You are subscribed to notifications of this kind.';
								|tr = 'Bu tür bildirimlere abonelik ayarlandı.'"));
	EndIf;
	
EndProcedure

// The handler that will be called when the left or right mouse button is clicked on a hyperlink in the message text, 
// on an attachment, on an action hyperlink, or when the right mouse button is clicked on a message. 
// The default list of commands is passed to the handler. You can create your own commands in the handler.
//
// Parameters:
//	CommandsParameters - CollaborationSystemGenerateCommandParameters - describes the parameters of the handler call.
//	Commands - Array of CollaborationSystemCommandDescription - sets the list of commands for the menu. When called, the list is filled with default menu commands.
//	DefaultCommand - CollaborationSystemCommandDescription, Undefined - defines the default command by the value from the list of commands.
//	AdditionalParameters - Structure, Undefined - the value that was specified when creating the message Description object.
Procedure OnGenerateInteractionSystemCommands(CommandsParameters, Commands, DefaultCommand, AdditionalParameters) Export
	
	If TypeOf(CommandsParameters.Message) <> Type("CollaborationSystemMessage") Then
		Return;
	EndIf;
	
	MessageData = CommandsParameters.Message.Data;
	If TypeOf(MessageData) <> Type("Structure")
		Or TypeOf(MessageData) = Type("Structure") And Not MessageData.Property("NotificationKind") 
		Or UsersClient.IsExternalUserSession() Then
			Return;
	EndIf;
	
	NonContextualDiscussion = CommandsParameters.Conversation.ConversationContext = Undefined;
	
	NotificationCommands = New CollaborationSystemCommandDescription(New Array, NStr("vi = 'Tùy chỉnh';
																					|ru = 'Настроить';
																					|en = 'Set up'; fa = 'تنظیم';
																					|it = 'Set up';
																					|pl = 'Set up';
																					|tr = 'Ayarla'"));
	NotificationCommands.Picture = PictureLib.Setting;
	
	AddCommand(NotificationCommands.Command, CommandsParameters, "DisableCurrentAlert", NStr("vi = 'Hủy đăng ký nhận thông báo này';
																							|ru = 'Отписаться от текущего оповещения';
																							|en = 'Unsubscribe from the current notification'; fa = 'Unsubscribe from the current notification';
																							|it = 'Unsubscribe from the current notification';
																							|pl = 'Unsubscribe from the current notification';
																							|tr = 'Mevcut bildirimden aboneliği iptal et'"));
	If NonContextualDiscussion Then
		AddCommand(NotificationCommands.Command, CommandsParameters, "DisableAllAlerts", NStr("vi = 'Hủy đăng ký tất cả';
																								|ru = 'Отписаться от всех';
																								|en = 'Unsubscribe from all'; fa = 'Unsubscribe from all';
																								|it = 'Unsubscribe from all';
																								|pl = 'Unsubscribe from all';
																								|tr = 'Tüm abonelikleri iptal et'"));
	Else
		AddCommand(NotificationCommands.Command, CommandsParameters, "DisableAllAlerts", NStr("vi = 'Hủy đăng ký tất cả (theo đối tượng)';
																								|ru = 'Отписаться от всех (по объекту)';
																								|en = 'Unsubscribe from all (by object)'; fa = 'Unsubscribe from all (by object)';
																								|it = 'Unsubscribe from all (by object)';
																								|pl = 'Unsubscribe from all (by object)';
																								|tr = 'Tüm abonelikleri iptal et (nesneye göre)'"));
	EndIf;
	AddSeparator(NotificationCommands.Command);
	AddCommand(NotificationCommands.Command, CommandsParameters, "SubscribeToCurrentNotification", NStr("vi = 'Đăng ký nhận thông báo hiện tại';
																										|ru = 'Подписаться на текущее оповещение';
																										|en = 'Subscribe to the current notification'; fa = 'Subscribe to the current notification';
																										|it = 'Subscribe to the current notification';
																										|pl = 'Subscribe to the current notification';
																										|tr = 'Mevcut bildirime abone ol'"));
	AddCommand(NotificationCommands.Command, CommandsParameters, "SubscribeToAlertsOnlyForMe", NStr("vi = 'Đăng ký nhận thông báo gửi cho tôi';
																									|ru = 'Подписаться на оповещения, адресованные мне';
																									|en = 'Subscribe to notifications addressed to you'; fa = 'Subscribe to notifications addressed to you';
																									|it = 'Subscribe to notifications addressed to you';
																									|pl = 'Subscribe to notifications addressed to you';
																									|tr = 'Bana gönderilen bildirimlere abone ol'"));
	If NonContextualDiscussion Then
		AddCommand(NotificationCommands.Command, CommandsParameters, "SubscribeToAllAlerts", NStr("vi = 'Đăng ký tất cả';
																									|ru = 'Подписаться на все';
																									|en = 'Subscribe to all'; fa = 'Subscribe to all';
																									|it = 'Subscribe to all';
																									|pl = 'Subscribe to all';
																									|tr = 'Tümüne abone ol'"));
	Else
		AddCommand(NotificationCommands.Command, CommandsParameters, "SubscribeToAllAlerts", NStr("vi = 'Đăng ký tất cả (theo đối tượng)';
																									|ru = 'Подписаться на все (по объекту)';
																									|en = 'Subscribe to all (by object)'; fa = 'Subscribe to all (by object)';
																									|it = 'Subscribe to all (by object)';
																									|pl = 'Subscribe to all (by object)';
																									|tr = 'Tümüne abone ol (nesneye göre)'"));
	EndIf;
	AddSeparator(NotificationCommands.Command);
	AddCommand(NotificationCommands.Command, CommandsParameters, "ConfigureAllAlerts", NStr("vi = 'Tất cả thông báo...';
																							|ru = 'Все оповещения...';
																							|en = 'All notifications...'; fa = 'All notifications...';
																							|it = 'All notifications...';
																							|pl = 'All notifications...';
																							|tr = 'Tüm bildirimler...'"));
	
	Commands.Add(NotificationCommands);
EndProcedure

#EndRegion

#Region Private

// Parameters:
//	SubmenuCommands - Array of CollaborationSystemCommandDescription - Submenu commands.
//	MessageParameters - CollaborationSystemGenerateCommandParameters - Message parameters.
//	CommandID - String - command ID.
//	Presentation - String - Performance.
Procedure AddCommand(SubmenuCommands, MessageParameters, CommandID, Presentation)
	
	CommandParameters = New Structure;
	CommandParameters.Insert("MessageText", MessageParameters.Message.Text);
	CommandParameters.Insert("MessageID", MessageParameters.Message.ID);
	CommandParameters.Insert("CommandID", CommandID);
	CommandParameters.Insert("ConversationID", MessageParameters.Conversation.ID);
	CommandParameters.Insert("NotificationKind", MessageParameters.Message.Data.NotificationKind);
	
	SetUpAlertsCommand = New CollaborationSystemCommandDescription(
		New CallbackDescription("SetUpNotifications", ThisObject, CommandParameters), Presentation);
	SubmenuCommands.Add(SetUpAlertsCommand);
	
EndProcedure

// Parameters:
//	SubmenuCommands - Array of CollaborationSystemCommandDescription - Submenu commands.
Procedure AddSeparator(SubmenuCommands)
	Separator = New CollaborationSystemCommandDescription(Undefined);
	SubmenuCommands.Add(Separator);
EndProcedure

Procedure ShowNotification(NotificationText1)
	ShowUserNotification(
		NStr("vi = 'Tùy chỉnh thông báo:';
			|ru = 'Настройки оповещений:';
			|en = 'Notification settings:'; fa = 'Notification settings:';
			|it = 'Notification settings:';
			|pl = 'Notification settings:';
			|tr = 'Bildirim ayarları:'"),,
		NotificationText1,
		PictureLib.Information32);
EndProcedure

#EndRegion
