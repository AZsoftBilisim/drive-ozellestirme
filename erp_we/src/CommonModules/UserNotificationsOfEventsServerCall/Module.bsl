#Region Internal

// Set the message display mode.
// 
// Parameters:
//  Conversation - See UserNotificationsOfEvents.SetMessageDisplayMode.Conversation
//  DontDisturb - See UserNotificationsOfEvents.SetMessageDisplayMode.DontDisturb
//  WatchMode - See UserNotificationsOfEvents.SetMessageDisplayMode.WatchMode
//  User - See UserNotificationsOfEvents.SetMessageDisplayMode.User
Procedure SetMessageDisplayMode(Conversation, DontDisturb, WatchMode = Undefined, User = Undefined) Export
	UserNotificationsOfEvents.SetMessageDisplayMode(Conversation,
		DontDisturb,
		WatchMode,
		User);
EndProcedure

// Subscribe to an alert by type of alert.
// 
// Parameters:
//  NotificationKind - CatalogRef.UserNotificationKinds - Type of notification
//  User - Undefined, CatalogRef.Users - User
Procedure SubscribeToNotificationtByNotificationKind(NotificationKind, User = Undefined) Export
	If Not Common.RefExists(NotificationKind) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(User) Then
		User = Users.AuthorizedUser();
	EndIf;
	
	RecordSet = InformationRegisters.DisabledUserNotificationSettings.CreateRecordSet();
	NewRecord = RecordSet.Add();
	NewRecord.User = User;
	NewRecord.NotificationKind = NotificationKind;
	
	SetPrivilegedMode(True);
	RecordSet.Write(ReplacementMode.Delete);
	SetPrivilegedMode(False);
EndProcedure

// Disable notification by type of notification.
// 
// Parameters:
//  NotificationKind - CatalogRef.UserNotificationKinds - Type of notification
//  User - Undefined, CatalogRef.Users - User
Procedure DisableNotificationByNotificationKind(NotificationKind, User = Undefined) Export
	If Not Common.RefExists(NotificationKind) Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(User) Then
		User = Users.AuthorizedUser();
	EndIf;
	
	RecordSet = InformationRegisters.DisabledUserNotificationSettings.CreateRecordSet();
	RecordSet.Filter.NotificationKind.Set(NotificationKind);
	RecordSet.Filter.User.Set(User);
	
	NewRecord = RecordSet.Add();
	NewRecord.User = User;
	NewRecord.NotificationKind = NotificationKind;
	
	SetPrivilegedMode(True);
	RecordSet.Write(ReplacementMode.Replace);
	SetPrivilegedMode(False);
EndProcedure

// See UserNotificationsOfEvents.CollaborationSystemMessageProcessing
Procedure CollaborationSystemMessageProcessing(Message, AdditionalParameters) Export
	
	UserNotificationsOfEvents.CollaborationSystemMessageProcessing(Message, AdditionalParameters);
	
EndProcedure

#EndRegion

