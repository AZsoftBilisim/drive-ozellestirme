
#Region Public

// When adding notification handlers for BTS users.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//  NotificationsHandlers - Map - Key, ID of the notification type,
//  	Value, a client module containing a method to process a message 
//  	with the user's notification parameter. The method of this module will be called when an alert
//  	is received with the specified identifier of the alert type.
//  	
// Example:
//  Processor Module = General purpose Client.Public Module("Notificationusers of news");
//  Annunciation handlers.Insert(
//		"Newswosting Site",
//		The Processors Module);
//		
//  The User Notification module contains the following code:
//		Procedure to process the notification(User Notification) Export
//	
//			If the user is notified.Video Announcements = "Newswosting Site Alerts" Then
//				Process a new Website call (User Notification); - a procedure that implements the processing logic
//			The end if;
//			
//		The end of the procedure.
//		
Procedure OnAddUserNotificationHandlersCTL(NotificationsHandlers) Export 
EndProcedure

#EndRegion