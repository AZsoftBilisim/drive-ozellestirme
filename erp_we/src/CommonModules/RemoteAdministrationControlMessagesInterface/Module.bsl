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
//  HandlersArray - Array - message handler.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
EndProcedure

// Registers handlers for broadcast messages.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  HandlersArray - Array - message handler.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
EndProcedure

// Returns the message type {http://www.1c.ru/SaaS/RemoteAdministration/Control/a.b.c.d }ApplicationPrepared.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOValueType, XDTOObjectType - the type of message.
//
Function MessageDataAreaPrepared(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/RemoteAdministration/Control/a.b.c.d }ApplicationDeleted.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOValueType, XDTOObjectType - the type of message.
//
Function MessageDataAreaDeleted(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/RemoteAdministration/Control/a.b.c.d }ApplicationPrepareFailed.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOValueType, XDTOObjectType - the type of message.
//
Function DataAreaPreparationErrorMessage(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/RemoteAdministration/Control/a.b.c.d}ApplicationPrepareFailedConversionRequired
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOValueType, XDTOObjectType - the type of message.
//
Function ErrorMessagePreparingDataAreaConversionRequired(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/RemoteAdministration/Control/a.b.c.d }ApplicationDeleteFailed.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOValueType, XDTOObjectType - the type of message.
//
Function MessageErrorDeletingDataArea(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/RemoteAdministration/Control/a.b.c.d }ApplicationReady.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOValueType, XDTOObjectType - the type of message.
//
Function MessageDataAreaIsReadyForUse(Val PackageToUse = Undefined) Export
EndFunction

#EndRegion