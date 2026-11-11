#Region Internal

// Complements the array of exceptions for notification sources.
// 
// Parameters:
//  Exceptions - Array of String - Sources of Alerts Exceptions
Procedure AddSourcesOfNotificationExceptions(Exceptions) Export
	
EndProcedure

// Complements the array with objects describing the types of alerts.
// 
// Parameters:
//  ObjectsArray - Array of String - Sources of Alerts Exceptions
Procedure AddObjectsWithDescriptionOfTypesOfNotifications(ObjectsArray) Export
	
	
EndProcedure

// Generates an array of objects with a description of the types of alerts.
// 
// Parameters:
//  GroupsOfNotificationKinds - See UserNotificationsOfEvents.GroupsOfNotificationKinds
Procedure AddGroupsOfNotificationKinds(GroupsOfNotificationKinds) Export
	
	GroupsOfNotificationKinds.Insert("ReconciliationService20",
		UserNotificationsOfEvents.DescriptionOfGroupOfNotificationKinds("abea65af-8fb9-4cdf-b32a-915f42fe6916", 
			NStr("ru = '1С:Сверка 2.0';
				|vi = '1C:Reconciliation 2.0';
				|en = '1C:Reconciliation 2.0'; fa = '1C:Reconciliation 2.0';
				|it = '1C:Reconciliation 2.0';
				|pl = '1C:Reconciliation 2.0';
				|tr = '1C: Mutabakat 2.0'", Common.DefaultLanguageCode()), True));
	
EndProcedure

#EndRegion