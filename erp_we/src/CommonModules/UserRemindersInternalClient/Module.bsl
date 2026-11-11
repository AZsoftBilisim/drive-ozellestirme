///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure HandleOpenOfNotification(Context) Export
	
	If ValueIsFilled(Context.Source) 
		Or UserRemindersClientServer.IsMessageURL(Context.URL) Then
		ReminderParameters = UserRemindersClientServer.ReminderDetails(Context);
		
		ReminderKey = UserRemindersServerCall.GetRecordKeyAndDisableReminder(ReminderParameters);
		
		UserRemindersClient.DeleteRecordFromNotificationsCache(ReminderParameters);
		Notify("Write_UserReminders", New Structure, ReminderKey);
		NotifyChanged(Type("InformationRegisterRecordKey.UserReminders"));
		FileSystemClient.OpenURL(Context.URL);
	Else
		OpenForm("InformationRegister.UserReminders.Form.Reminder", New Structure("KeyData", Context));	
	EndIf;
	
EndProcedure

Procedure Remind(Ref, Parameters) Export
	FormParameters = New Structure("Source", Ref);
	OpenForm("InformationRegister.UserReminders.Form.Reminder", 
		FormParameters, Parameters.Form);
EndProcedure

#Region Conversations

Procedure AddConversationsCommands(CommandsParameters, Commands, DefaultCommand) Export
	
	If TypeOf(CommandsParameters.Message) <> Type("CollaborationSystemMessage") Then
		Return;
	EndIf;
	
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	If Not ClientRunParameters.UsedUserReminders Then
		Return;
	EndIf;
		
	RemindersCommands = New CollaborationSystemCommandDescription(New Array, NStr("vi = 'Nhắc việc...';
																					|ru = 'Напомнить...';
																					|en = 'Remind…'; fa = 'یادآوری…';
																					|it = 'Напомнить...';
																					|pl = 'Remind…';
																					|tr = 'Hatırlat...'"));
	RemindersCommands.Picture = ?(ClientRunParameters.ShouldShowRemindersInNotificationCenter, 
		PictureLib.NotificationCenter, PictureLib.Reminder);
	
	AddCommand(RemindersCommands.Command, CommandsParameters, "RemindIn1Hour", NStr("vi = 'Sau 1 giờ';
																					|ru = 'Через час';
																					|en = 'In 1 hour'; fa = 'In 1 hour';
																					|it = 'Через час';
																					|pl = 'In 1 hour';
																					|tr = 'Bir saat sonra'"));
	AddCommand(RemindersCommands.Command, CommandsParameters, "RemindIn2Hours", NStr("vi = 'Sau 2 giờ';
																					|ru = 'Через 2 часа';
																					|en = 'In 2 hours'; fa = 'In 2 hours';
																					|it = 'Через 2 часа';
																					|pl = 'In 2 hours';
																					|tr = 'İki saat sonra'"));
	AddCommand(RemindersCommands.Command, CommandsParameters, "RemindIn3Hours", NStr("vi = 'Sau 4 giờ';
																					|ru = 'Через 4 часа';
																					|en = 'In 4 hours'; fa = 'In 4 hours';
																					|it = 'Через 4 часа';
																					|pl = 'In 4 hours';
																					|tr = 'Dört saat sonra'"));
	AddCommand(RemindersCommands.Command, CommandsParameters, "RemindTomorrowMorning", NStr("vi = 'Sáng mai';
																							|ru = 'Завтра утром';
																							|en = 'Next morning'; fa = 'Next morning';
																							|it = 'Завтра утром';
																							|pl = 'Next morning';
																							|tr = 'Yarın sabahleyin'"));
	AddCommand(RemindersCommands.Command, CommandsParameters, "RemindAtBeginningOfNextWeek", NStr("vi = 'Bắt đầu tuần tiếp theo';
																									|ru = 'Начало следующей недели';
																									|en = 'Start of next week'; fa = 'Start of next week';
																									|it = 'Начало следующей недели';
																									|pl = 'Start of next week';
																									|tr = 'Bir sonraki haftanın başlangıcı'"));
	AddSeparator(RemindersCommands.Command);
	AddCommand(RemindersCommands.Command, CommandsParameters, "ReminderSettings", NStr("vi = 'Tùy chỉnh...';
																						|ru = 'Настройки...';
																						|en = 'Settings…'; fa = 'تنظیمات…';
																						|it = 'Настройки...';
																						|pl = 'Settings…';
																						|tr = 'Ayarlar...'"));
	
	Commands.Add(RemindersCommands);

EndProcedure

Procedure CreateReminder(AdditionalParameters) Export
	
	If AdditionalParameters.CommandID = "ReminderSettings" Then
		UserRemindersClient.OpenSettings();
		Return;
	EndIf;
	
	ReminderAlarmTime = CommonClient.SessionDate();
	If AdditionalParameters.CommandID = "RemindIn1Hour" Then
		ReminderAlarmTime = ReminderAlarmTime + 60*60;
	ElsIf AdditionalParameters.CommandID = "RemindIn2Hours" Then
		ReminderAlarmTime = ReminderAlarmTime + 2*60*60;
	ElsIf AdditionalParameters.CommandID = "RemindIn3Hours" Then
		ReminderAlarmTime = ReminderAlarmTime + 3*60*60;
	ElsIf AdditionalParameters.CommandID = "RemindTomorrowMorning" Then
		ReminderAlarmTime = EndOfDay(ReminderAlarmTime) + 9*60*60;
	ElsIf AdditionalParameters.CommandID = "RemindAtBeginningOfNextWeek" Then
		ReminderAlarmTime = EndOfWeek(ReminderAlarmTime) + 9*60*60;
	EndIf;           
	
	UserRemindersClient.RemindInSpecifiedTime(NStr("vi = 'Nhắc việc về thông báo bị hoãn';
													|ru = 'Напоминание об отложенном сообщении';
													|en = 'Deferred message reminder'; fa = 'Deferred message reminder';
													|it = 'Напоминание об отложенном сообщении';
													|pl = 'Deferred message reminder';
													|tr = 'Ertelenen mesaj hatırlatması'"), 
		ReminderAlarmTime, , "e1ccs/data/msg?id=" + AdditionalParameters.MessageID);
		
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure AddCommand(SubmenuCommands, MessageParameters, CommandID, Presentation)
	
	CommandParameters = New Structure;
	CommandParameters.Insert("MessageText", MessageParameters.Message.Text);
	CommandParameters.Insert("MessageID", MessageParameters.Message.Id);
	CommandParameters.Insert("CommandID", CommandID);
	ReminderCommand = New CollaborationSystemCommandDescription(
		New CallbackDescription("CreateReminder", ThisObject, CommandParameters), Presentation);
	SubmenuCommands.Add(ReminderCommand);
	
EndProcedure

Procedure AddSeparator(SubmenuCommands)
	Separator = New CollaborationSystemCommandDescription(Undefined);
	SubmenuCommands.Add(Separator);
EndProcedure

#EndRegion