////////////////////////////////////////////////////////////////////////////////
// APPLICATION MANAGEMENT MESSAGE INTERFACE HANDLER
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the namespace of the current (used by the calling code) version of the message interface.
// Returns:
//	String - 
Function Package() Export
	
	Return "http://www.1c.ru/1cFresh/ManageApplication/Messages/1.0";
	
EndFunction

// Returns the current (used by the calling code) version of the message interface.
// Returns:
//	String - 
Function Version() Export
	
	Return "1.0.0.1";
	
EndFunction

// Returns the name of the message programming interface.
// Returns:
//	String - 
Function Public() Export
	
	Return "ManageApplicationMessages";
	
EndFunction

// Registers message handlers as message channel handlers.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  HandlersArray - Array - array of handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
	
EndProcedure

// Registers handlers for broadcast messages.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  HandlersArray - Array - array of handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
	
EndProcedure

// Returns the message type {http://www.1c.ru/1cFresh/ManageApplication/Messages/a.b.c.d} RevokeUserAccess.
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOValueType, XDTOObjectType - the type of message.
//
Function RevokeUserAccessMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "RevokeUserAccess");
	
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
