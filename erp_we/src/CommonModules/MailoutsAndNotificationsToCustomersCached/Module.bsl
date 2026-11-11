
////////////////////////////////////////////////////////////////////////////////
// Subsystem "Mailing lists and notifications to clients".
//
////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
//  Contains functions that return repeated values during the session
//  to work with the functionality of mailings and notifications to clients.
// 
#Region Public

// Determines whether the event type is used in at least one type of alert.
//
// Parameters:
//  EventType  -  EnumRef.NotificationEventTypes - the type of event for which usage is checked.
//
// Returns:
//   Boolean   - True if used. False if not used.
//
Function EventTypeUsed(EventType) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	CustomerNotificationKinds.Ref
	|FROM
	|	Catalog.CustomerNotificationKinds AS CustomerNotificationKinds
	|WHERE
	|	CustomerNotificationKinds.EventType = &EventType
	|	AND NOT CustomerNotificationKinds.DeletionMark";
	
	Query.SetParameter("EventType", EventType);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

// Defines active types of notifications by event type.
//
// Parameters:
//  EventType  -  EnumRef.NotificationEventTypes - the type of event to search for types of notifications for.
//
// Returns:
//   Array   - alerts that are valid for the type of event.
//
Function CurrentNotificationKindsByEventType(EventType) Export

	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	CustomerNotificationKinds.Ref
	|FROM
	|	Catalog.CustomerNotificationKinds AS CustomerNotificationKinds
	|WHERE
	|	CustomerNotificationKinds.EventType = &EventType
	|	AND NOT CustomerNotificationKinds.DeletionMark";
	
	Query.SetParameter("EventType", EventType);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");

EndFunction

#EndRegion
