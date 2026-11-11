
#Region Public

// Returns object data from the Service Manager according to the broadcast rule.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters: 
//  RuleID - String - ID of the translation rule with the "Read" type.
//  ObjectKey - String, Number - the object key defined in the rule.
// 
// Returns: 
//  Structure -- object data or Undefined if no data is received:
// * Field - Arbitrary - arbitrary composition of fields.
Function GetObjectDataByRule(RuleID, ObjectKey) Export
EndFunction 

// Sends data to the Service Manager.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  RuleID - String - ID of the broadcast rule with the "upload" type. 
//  Data - Structure - data to send to the service manager:
//   * Field - Arbitrary - an arbitrary composition of fields defined in a universal object.
// 
// Returns:
//  Structure - The result of the query:
//  * StatusCode - Number - response status code.
//  * ResponseBody - String - response body as a string.
//  * ResponseData - Undefined, Structure - object data or Undefined if no data is received:
//    ** Field - Arbitrary - arbitrary composition of fields, if the response contains
//    						   the "Content-Type: application/json" header, the Structure is returned.
Function SendObjectDataByRule(RuleID, Data = Undefined) Export
EndFunction

// Changes an object in the Service Manager according to the broadcast rule.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  RuleID - String - ID of the broadcast rule with the "upload" type. 
//  ObjectKey - String, Number - the object key defined in the rule.
//  Data - Structure - data to send to the service manager. 
//   * Field-Arbitrary - the arbitrary composition of fields defined in the universal object.
// 
// Returns:
//  Structure - Response Data:
//  * StatusCode - Number - response status code.
//  * ResponseBody - String - response body.
//  * ResponseData - Undefined, Structure - object data or Undefined if no data is received:
//    ** Field - Arbitrary - arbitrary composition of fields, if the response contains
//    						   the "Content-Type: application/json" header, the Structure is returned.
Function ChangeObjectDataByRule(RuleID, ObjectKey, Data = Undefined) Export
EndFunction

// This method allows you to subscribe to notifications about changes in objects in the service manager according to the broadcast rules.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  RuleID - String - ID of the broadcast rule. 
//  ObjectKey - String - key of the integration object that we subscribe to for updates.
//
Procedure SubscribeToChangeAlerts(RuleID, ObjectKey) Export
EndProcedure

// This method allows you to unsubscribe from notifications about changes to objects in the service manager according to the broadcast rules.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  RuleID - String - id of the broadcast rule
//  ObjectKey - String - key of the object that we use to unsubscribe from notifications about updates.
//
Procedure UnsubscribeFromChangeNotifications(RuleID, ObjectKey) Export
EndProcedure

// The function allows you to read the received object data by the key of the received data.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  RuleID - String - ID of the broadcast rule.
//  ObjectKey - String - the object key.
// 
// Returns:
//   Structure - read received object data:
//   * Field - Arbitrary - an arbitrary composition of fields defined in a universal object.
//
Function ReadReceivedObjectData(RuleID, ObjectKey) Export
EndFunction

// This method allows you to subscribe to notifications about changes to objects in the service manager.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  ObjectType - String 
//  ObjectID - UUID
Procedure SubscribeToNotificationsAboutObjectChanges(ObjectType, ObjectID) Export
EndProcedure

// This method allows you to unsubscribe from notifications about changes to objects in the service manager according to the broadcast rules.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  ObjectType - String
//  ObjectID - UUID
Procedure UnsubscribeFromObjectChangeNotifications(ObjectType, ObjectID) Export
EndProcedure            

// This function allows you to check whether an object has changed by type and object ID.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  ObjectType - String
//  ObjectID - UUID
//
// Returns:
//  Boolean - indicates whether the object has changed after the last subscription to the change.
Function ReceivedNotificationAboutObjectChanges(ObjectType, ObjectID) Export
EndFunction
 
#EndRegion

#Region Internal

// The procedure allows you to record or initialize the received object data in advance
// using the key of the received data.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  RuleID - String -id of the broadcast rule
//  ObjectKey - String - the object key.
//  Data - Structure - save the resulting data object.
//
Procedure RecordReceivedObjectData(RuleID, ObjectKey, Data) Export
EndProcedure

#EndRegion 
