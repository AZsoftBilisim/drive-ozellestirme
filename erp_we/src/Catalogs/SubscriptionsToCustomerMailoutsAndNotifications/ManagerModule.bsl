#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This flag is Valid for an array of subscriptions. 
//
// Parameters:
//  Subscriptions  - Array - array of canceled subscriptions.
//
Procedure UnsubscribeForArray(Subscriptions) Export
	
	For Each Subscription In Subscriptions Do
		
		CancelYourSubscription(Subscription);
		
	EndDo;
	
EndProcedure

// Subscribes to an array of subscriptions. If the subscription exists, it sets the "Valid"flag.
// If the subscription does not exist, a new one is created.
//
// Parameters:
//  Subscriptions  - Array, - array of existing subscriptions or structures containing the subscriber and group.
//
Procedure SubscribeToArrayOfExistingAndNewSubscriptions(Subscriptions) Export

	ExistingSubscriptions = New Array;
	NewSubscriptions        = New Array;
	
	For Each Subscription In Subscriptions Do
	
		If TypeOf(Subscription) = Type("CatalogRef.SubscriptionsToCustomerMailoutsAndNotifications") Then
			ExistingSubscriptions.Add(Subscription);
		ElsIf TypeOf(Subscription) = Type("Structure") Then
			NewSubscriptions.Add(Subscription);
		EndIf;
	
	EndDo;
	
	If ExistingSubscriptions.Count() > 0 Then
		SubscribeToArrayOfExistingOnes(ExistingSubscriptions);
	EndIf;
	
	If NewSubscriptions.Count() Then
		SubscribeToArrayOfNewOnes(NewSubscriptions);
	EndIf;

EndProcedure

// Subscribes to an array of existing subscriptions. The "Valid" flag is set.
//
// Parameters:
//  ArrayOfSubscriptions  - Array, - array of existing subscriptions.
//
Procedure SubscribeToArrayOfExistingOnes(ArrayOfSubscriptions) Export

	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	SubscriptionsToCustomerMailoutsAndNotifications.Ref,
	|	SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid,
	|	GroupsOfMailoutsAndNotifications.Forced,
	|	GroupsOfMailoutsAndNotifications.DesignedForEmails,
	|	GroupsOfMailoutsAndNotifications.DesignedForSMSMessage,
	|	GroupsOfMailoutsAndNotifications.PartnerSContactDetailsKindForEmails,
	|	GroupsOfMailoutsAndNotifications.PartnerSContactDetailsKindForSMSMessage,
	|	CASE
	|		WHEN SubscriptionsToCustomerMailoutsAndNotifications.SendToAContactPersonOfANotificationObject
	|				OR SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
	|				OR SubscriptionsToCustomerMailoutsAndNotifications.NumberOfAddresseesContactPersons > 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS RecipientsConfigured
	|FROM
	|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
	|		INNER JOIN Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|		ON SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref
	|WHERE
	|	SubscriptionsToCustomerMailoutsAndNotifications.Ref IN(&ArrayOfSubscriptions)
	|	AND NOT SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid";
	
	Query.SetParameter("ArrayOfSubscriptions", ArrayOfSubscriptions);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
	
		ObjectSubscription = Selection.Ref.GetObject(); // CatalogObject.SubscriptionsToCustomerMailoutsAndNotifications
		ObjectSubscription.SubscriptionIsValid =  True;
		
		ObjectSubscription.Write();
	
	EndDo;
	
EndProcedure

// Subscribes to an array of new subscriptions.
//
// Parameters:
//  ArrayOfSubscriptions  - Array, - array of structures containing the subscriber and group.
//
Procedure SubscribeToArrayOfNewOnes(ArrayOfSubscriptions) Export

	SubscriptionTable = New ValueTable;
	SubscriptionTable.Columns.Add("Subscriber",New TypeDescription("CatalogRef.Partners"));
	SubscriptionTable.Columns.Add("GroupOfMailoutsAndNotifications",New TypeDescription("CatalogRef.GroupsOfMailoutsAndNotifications"));
	
	For Each ArrayElement In ArrayOfSubscriptions Do
		NewRow = SubscriptionTable.Add();
		FillPropertyValues(NewRow, ArrayElement);
	EndDo;
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	SubscriptionTable.Subscriber,
	|	SubscriptionTable.GroupOfMailoutsAndNotifications
	|INTO NewSubscriptions
	|FROM
	|	&SubscriptionTable AS SubscriptionTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.Ref, VALUE(Catalog.SubscriptionsToCustomerMailoutsAndNotifications.EmptyRef)) AS CurSubscription,
	|	NewSubscriptions.GroupOfMailoutsAndNotifications,
	|	NewSubscriptions.Subscriber,
	|	GroupsOfMailoutsAndNotifications.DesignedForEmails,
	|	GroupsOfMailoutsAndNotifications.DesignedForSMSMessage,
	|	GroupsOfMailoutsAndNotifications.PartnerSContactDetailsKindForEmails,
	|	GroupsOfMailoutsAndNotifications.PartnerSContactDetailsKindForSMSMessage,
	|	CASE
	|		WHEN SubscriptionsToCustomerMailoutsAndNotifications.Ref IS NULL 
	|			THEN FALSE
	|		ELSE CASE
	|				WHEN ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer, FALSE)
	|						OR ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.SendToAContactPersonOfANotificationObject, FALSE)
	|						OR ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.NumberOfAddresseesContactPersons, 0) > 0
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END AS RecipientsConfigured
	|FROM
	|	NewSubscriptions AS NewSubscriptions
	|		LEFT JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
	|		ON (SubscriptionsToCustomerMailoutsAndNotifications.Owner = NewSubscriptions.Subscriber)
	|			AND (SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = NewSubscriptions.GroupOfMailoutsAndNotifications)
	|			AND (NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark)
	|		INNER JOIN Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|		ON NewSubscriptions.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref
	|			AND (NOT GroupsOfMailoutsAndNotifications.DeletionMark)
	|WHERE
	|	NOT ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid, FALSE)";
	
	Query.SetParameter("SubscriptionTable", SubscriptionTable);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
	
		If Selection.CurSubscription.IsEmpty() Then
			ObjectSubscription = Catalogs.SubscriptionsToCustomerMailoutsAndNotifications.CreateItem();
			ObjectSubscription.Owner                  = Selection.Subscriber;
			ObjectSubscription.GroupOfMailoutsAndNotifications = Selection.GroupOfMailoutsAndNotifications;
		Else
			ObjectSubscription = Selection.CurSubscription.GetObject();
		EndIf;
		
		ObjectSubscription.SubscriptionIsValid =  True;
		ConfigureDefaultDestination(Selection, ObjectSubscription);
		
		ObjectSubscription.Write();
		
	EndDo;

EndProcedure

// Removes the Active for subscription flag. 
//
// Parameters:
//  Subscription  - CatalogRef.SubscriptionsToCustomerMailoutsAndNotifications - a subscription that is being canceled.
//
Procedure CancelYourSubscription(Subscription) Export
	
	ObjectSubscription = Subscription.GetObject();
	If ObjectSubscription.SubscriptionIsValid Then
		ObjectSubscription.SubscriptionIsValid = False;
		ObjectSubscription.Write();
	EndIf;
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Owner)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Owner
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

Procedure ConfigureDefaultDestination(Selection, ObjectSubscription)
	
	If Not Selection.RecipientsConfigured Then
		ObjectSubscription.SendToCustomer = True;
		If Selection.DesignedForEmails Then
			ObjectSubscription.PartnerContactDetailsKindForMails = Selection.PartnerSContactDetailsKindForEmails;
		EndIf;
		If Selection.DesignedForSMSMessage Then
			ObjectSubscription.PartnerContactDetailsKindForSMSMessage = Selection.PartnerSContactDetailsKindForSMSMessage;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
