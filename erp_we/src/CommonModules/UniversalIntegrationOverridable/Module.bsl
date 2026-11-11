#Region Public

// Allows you to add or change data before sending it to the service manager.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  RuleID - String - ID of the rule. 
//  Data - Structure - the data to be sent. 
//
Procedure ProcessDataBeforeSending(RuleID, Data) Export
EndProcedure

// The procedure for processing notifications about object changes according to the broadcast rule. 
// Called after receiving object data, before saving the object to secure storage.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  RuleID - String - ID of the broadcast rule.
//  ObjectKey - String - the object key. 
//  Data - Structure - object data.
//
Procedure ProcessChangeNotification(RuleID, ObjectKey, Data) Export
EndProcedure

// The procedure for processing notifications about object changes.
// It is called after receiving an alert, before being saved to a secure vault.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  ObjectType - String - object type.
//  ObjectKey - String - the object key. 
//
Procedure ProcessObjectChangeNotification(ObjectType, ObjectKey) Export
EndProcedure
 
#EndRegion 
