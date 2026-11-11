
////////////////////////////////////////////////////////////////////////////////
// Subsystem "Mailing lists and notifications to clients".
//
////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
//  It contains a software interface for working with the functionality of mailings and notifications to clients.
//  Contains procedures that process client code requests on the server.
//

#Region Public

// Gets a subscription for a subscriber and a group of newsletters and notifications
//
// Parameters:
//  Subscriber     - CatalogRef.Partners - the partner for which the subscription is obtained.
//  GroupOfMailoutsAndNotifications  - CatalogRef.GroupsOfMailoutsAndNotifications - the group for which the subscription is obtained.
//
// Returns:
//   CatalogRef.SubscriptionsToCustomerMailoutsAndNotifications   - a subscription configured for a subscriber and a group.
//
Function SubscriptionForSubscriber(Subscriber, GroupOfMailoutsAndNotifications) Export
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	|	SubscriptionsToCustomerMailoutsAndNotifications.Ref
	|FROM
	|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
	|WHERE
	|	SubscriptionsToCustomerMailoutsAndNotifications.Owner = &Subscriber
	|	AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications
	|	AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark";
	
	Query.SetParameter("Subscriber", Subscriber);
	Query.SetParameter("GroupOfMailoutsAndNotifications", GroupOfMailoutsAndNotifications);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Catalogs.SubscriptionsToCustomerMailoutsAndNotifications.EmptyRef();
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.Ref;
	
EndFunction

// Defines groups of mailings and notifications that contain types of notifications by event type. 
//
// Parameters:
//  EventType  - Array, EnumRef.NotificationEventTypes - types of events that are being searched for.
//
// Returns:
//   Array   - found groups of mailings and notifications.
//
Function AvailableNotificationGroupsByEventType(EventType) Export

	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	CustomerNotificationKinds.GroupOfMailoutsAndNotifications AS GroupOfMailoutsAndNotifications
	|FROM
	|	Catalog.CustomerNotificationKinds AS CustomerNotificationKinds
	|WHERE
	|	CustomerNotificationKinds.EventType IN (&TypesOfEvents)
	|	AND NOT CustomerNotificationKinds.DeletionMark
	|	AND NOT CustomerNotificationKinds.GroupOfMailoutsAndNotifications.DeletionMark
	|";
	
	If TypeOf(EventType) = Type("Array") Then
		TypesOfEvents = EventType;
	Else
		TypesOfEvents = New Array();
		TypesOfEvents.Add(EventType);
	EndIf;
	
	Query.SetParameter("TypesOfEvents", TypesOfEvents);
	Query.SetParameter("EventType", EventType);
	
	Return Query.Execute().Unload().UnloadColumn("GroupOfMailoutsAndNotifications");

EndFunction

// You must show subscriptions in the object if the client does not have subscriptions
// for the event type and at least one subscription for the event type is available to the client.
//
// Parameters:
//  Partner     - CatalogRef.Partners - the partner that the subscription will be configured for.
//  EventType  - Array, EnumRef.NotificationEventTypes - types of events to subscribe to.
//
// Returns:
//   Boolean   - True if shown, False in the opposite case.
//
Function ShowSubscriptionsToAlertsInMapItem(Partner, EventType) Export
	
	If Not AccessRight("Update", Metadata.Catalogs.SubscriptionsToCustomerMailoutsAndNotifications) Then
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(Partner) Or Not ValueIsFilled(EventType) Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	CustomerNotificationKinds.GroupOfMailoutsAndNotifications AS GroupOfMailoutsAndNotifications
	|INTO
	|	CustomerNotificationKinds
	|FROM
	|	Catalog.CustomerNotificationKinds AS CustomerNotificationKinds
	|WHERE
	|	CustomerNotificationKinds.EventType IN (&TypesOfEvents)
	|	AND NOT CustomerNotificationKinds.DeletionMark
	|	AND NOT CustomerNotificationKinds.GroupOfMailoutsAndNotifications.DeletionMark
	|;
	|SELECT
	|	CustomerNotificationKinds.GroupOfMailoutsAndNotifications AS GroupOfMailoutsAndNotifications
	|FROM
	|	CustomerNotificationKinds AS CustomerNotificationKinds
	|;
	|SELECT DISTINCT
	|	SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications AS GroupOfMailoutsAndNotifications
	|FROM
	|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
	|WHERE
	|	SubscriptionsToCustomerMailoutsAndNotifications.Owner = &Partner
	|	AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
	|	AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications IN (
	|		SELECT
	|			CustomerNotificationKinds.GroupOfMailoutsAndNotifications
	|		FROM
	|			CustomerNotificationKinds AS CustomerNotificationKinds 
	|	)
	|;
	|";
	
	If TypeOf(EventType) = Type("Array") Then
		TypesOfEvents = EventType;
	Else
		TypesOfEvents = New Array();
		TypesOfEvents.Add(EventType);
	EndIf;
	
	Query.SetParameter("TypesOfEvents", TypesOfEvents);
	Query.SetParameter("Partner", Partner);
	Result = Query.ExecuteBatch();
	
	QueryResult1 = Result[1]; // QueryResult
	QueryResult2 = Result[2]; // QueryResult

	Selection1 = QueryResult1.Select();
	Selection2 = QueryResult2.Select();
	
	Return Selection1.Count() > 0 And Selection2.Count() = 0;
	
EndFunction

#EndRegion

