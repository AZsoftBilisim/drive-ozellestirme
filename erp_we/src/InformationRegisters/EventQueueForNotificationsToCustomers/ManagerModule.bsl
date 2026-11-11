
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Writes to the register.
//
// Parameters:
//  NotificationKind                         - CatalogRef.CustomerNotificationKinds - type of notification.
//  Subscriber                             - CatalogRef.Partners - the subscriber of the alert.
//  NotificationSource                    - Arbitrary - source of the alert.
//  DateSent                          - Date - The date on which the notification should be sent.
//  EmailSendingRelevanceDate              - Date - The date before which it makes sense to send the notification.
//
Procedure ExecuteRecordToRegister(NotificationKind, 
	                              Subscriber, 
	                              NotificationSource, 
	                              DateSent, 
	                              EmailSendingRelevanceDate) Export

	SetPrivilegedMode(True);
	
	Record = InformationRegisters.EventQueueForNotificationsToCustomers.CreateRecordManager();
	Record.Period                   = CurrentSessionDate();
	Record.NotificationKind            = NotificationKind;
	Record.Subscriber                = Subscriber;
	Record.NotificationSource       = NotificationSource;
	Record.DateSent             = DateSent;
	Record.EmailSendingRelevanceDate = EmailSendingRelevanceDate;
	
	Record.Write(True);

EndProcedure

// Deletes entries from the queue by type of notification earlier than the date of processing.
//
// Parameters:
//  NotificationKind  - CatalogRef.CustomerNotificationKinds - type of notification that events should be deleted for.
//  DateDeleted  - Date - The date before which notifications are removed from the queue.
//
Procedure DeleteEntriesByNotificationTypeFromQueue(NotificationKind, DateDeleted) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "SELECT
	|	EventQueueForNotificationsToCustomers.Period,
	|	EventQueueForNotificationsToCustomers.NotificationKind,
	|	EventQueueForNotificationsToCustomers.NotificationSource
	|FROM
	|	InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
	|WHERE
	|	EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
	|	AND EventQueueForNotificationsToCustomers.Period < &DateDeleted";
	
	Query.SetParameter("NotificationKind", NotificationKind);
	Query.SetParameter("DateDeleted", DateDeleted);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		RecordSet = InformationRegisters.EventQueueForNotificationsToCustomers.CreateRecordSet();
		RecordSet.Filter.Period.Set(Selection.Period);
		RecordSet.Filter.NotificationKind.Set(Selection.NotificationKind);
		RecordSet.Filter.NotificationSource.Set(Selection.NotificationSource);
		RecordSet.Write(True);
	EndDo;
	
EndProcedure

#EndRegion

#EndIf