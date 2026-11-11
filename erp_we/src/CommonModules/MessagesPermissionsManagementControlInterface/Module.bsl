////////////////////////////////////////////////////////////////////////////////
// PERMISSION CONTROL MESSAGE INTERFACE HANDLER
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the namespace of the current (used by the calling code) version of the message interface.
//
// Returns:
//	String - 
Function Package() Export
	
	Return "http://www.1c.ru/1cFresh/Application/Permissions/Control/" + Version(); // @Non-NLS-1
	
EndFunction

// Returns the current (used by the calling code) version of the message interface.
//
// Returns:
//	String - 
Function Version() Export
	
	Return "1.0.0.1";
	
EndFunction

// Returns the name of the message programming interface.
//
// Returns:
//	String - 
Function Public() Export
	
	Return "ApplicationPermissionsControl";
	
EndFunction

// Registers message handlers as message channel handlers.
//
// Parameters:
//  HandlersArray - Array - array of handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
	
	HandlersArray.Add(MessagesPermissionsManagementControlMessageHandler_1_0_0_1);
	
EndProcedure

// Registers handlers for broadcast messages.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  HandlersArray - Array - array of handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
EndProcedure

// Returns the message type{http://www.1c.ru/1cFresh/Application/Permissions/Control/a.b.c.d}InfoBasePermissionsRequestProcessed
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOValueType, XDTOObjectType - the type of message.
//
Function MessageInformationBasePermissionRequestProcessed(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "InfoBasePermissionsRequestProcessed");
	
EndFunction

// Returns the message type{http://www.1c.ru/1cFresh/Application/Permissions/Control/a.b.c.d}ApplicationPermissionsRequestProcessed
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOValueType, XDTOObjectType - the type of message.
//
Function MessageProcessedRequestForDataAreaPermissions(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ApplicationPermissionsRequestProcessed");
	
EndFunction

// Dictionary of converting the elements of the enumeration scheme
// {http://www.1c.ru/1cFresh/Application/Permissions/Control/1.0.0.1} PermissionRequestProcessingResultTypes
// in the enumeration elements of the resultsprocessingrequestsuse of external resources in the service model.
//
// Returns:
//	FixedStructure - With Fields:
//	* Approved - EnumRef.ExternalResourcesUsageQueriesProcessingResultsSaaS - approved.
//	* Rejected - EnumRef.ExternalResourcesUsageQueriesProcessingResultsSaaS - rejected.
Function DictionaryOfQueryResultTypes() Export
	
	Result = New Structure();
	
	Result.Insert("Approved", Enums.ExternalResourcesUsageQueriesProcessingResultsSaaS.RequestApproved);
	Result.Insert("Rejected", Enums.ExternalResourcesUsageQueriesProcessingResultsSaaS.RequestRejected);
	
	Return New FixedStructure(Result);
	
EndFunction

#EndRegion

#Region Private

Function GenerateMessageType(Val PackageToUse, Val Type)
	
	If PackageToUse = Undefined Then
		PackageToUse = Package();
	EndIf;
	
	Return XDTOFactory.Type(PackageToUse, Type);
	
EndFunction

#EndRegion
