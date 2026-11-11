#Region Public

// Returns the current (used by the calling code) version of the message interface.
// @skip-warning EmptyMethod - a feature of the implementation.
// Returns:
//	String - 
Function Version() Export
EndFunction

// Returns the namespace of the current (used by the calling code) version of the message interface.
// @skip-warning EmptyMethod - a feature of the implementation.
// Returns:
//	String - 
Function Package() Export
EndFunction

// Returns the name of the message programming interface.
// @skip-warning EmptyMethod - a feature of the implementation.
// Returns:
//	String - 
Function Public() Export
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

#EndRegion