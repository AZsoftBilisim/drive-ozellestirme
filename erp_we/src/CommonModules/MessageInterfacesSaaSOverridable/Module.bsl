// @strict-types

#Region Public

// Fills the transmitted array with common modules that are handlers for the interfaces of received messages.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  HandlersArray - Array of CommonModule - The array elements are shared modules.
//
Procedure FillInReceivedMessageHandlers(HandlersArray) Export	
EndProcedure

// Fills the transmitted array with common modules that are handlers of the interfaces of the sent messages.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  HandlersArray - Array of CommonModule - The array elements are shared modules.
//
Procedure FillInHandlersForSendingMessages(HandlersArray) Export
EndProcedure

// The procedure is called when determining the version of the message interface supported by both the information security correspondent 
// and the Cur information security. This procedure is supposed to implement mechanisms to support backward compatibility with 
// older versions of information security correspondents.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  MessageInterface - String - Name of the program interface of the message that the version is defined for.
//  ConnectionParameters - Structure - Parameters for connecting to an IB correspondent.
//  RecipientPresentation1 - String - Representation of the IB correspondent.
//  Result - String - the designated version. The value of this parameter can be changed in this procedure.
//
Procedure OnDefineCorrespondentInterfaceVersion(Val MessageInterface, Val ConnectionParameters, Val RecipientPresentation1, Result) Export	
EndProcedure

#EndRegion
