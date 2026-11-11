#Region Public

// Returns the Cur version number of the software interface.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//   String   - Interface version number
//
Function Version() Export
EndFunction

// Returns the namespace of the current (used by the calling code) version of the message interface.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//   String   - Interface namespace
//
Function Package() Export
EndFunction

// Returns the name of the message programming interface.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//   String   - Interface name
//
Function Public() Export
EndFunction

// Registers message handlers as message channel handlers.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	HandlersArray - Array - Channel handlers. 
//
Procedure MessagesChannelsHandlers(HandlersArray) Export
EndProcedure

// Registers handlers for broadcast messages.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	HandlersArray - Array - Channel handlers.
//
Procedure MessagesTranslationHandlers(HandlersArray) Export
EndProcedure

#EndRegion