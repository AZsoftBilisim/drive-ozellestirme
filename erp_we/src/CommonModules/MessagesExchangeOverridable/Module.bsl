
#Region Public

// Gets a list of message handlers that this information system processes.
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  Handlers - ValueTable - with columns:
//    * Canal - String - Message channel.
//    * Handler - CommonModule - Message handler.
//
Procedure GetMessagesChannelsHandlers(Handlers) Export	
EndProcedure

// Handler for getting a dynamic list of message endpoints.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  MessagesChannel - String - The channel ID of the message for which you want to define 
//   endpoint.
//  Recipients - Array - The array of endpoints to which the message should be addressed
//                            should be filled with elements of the planemainlink type.Exchange of messages.
//                            This parameter must be defined in the handler body.
//
Procedure MessageRecipients(Val MessagesChannel, Recipients) Export
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers for sending and receiving messages.

// Event handler when sending a message.
// The handler for this event is called before the message is placed in the XML stream.
// The handler is called for each message sent.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  MessagesChannel - String - ID of the message channel that the message is being sent to.
//  Body - Arbitrary - body of the message being sent. In the event handler, the message body
//                                can be changed, for example, supplemented with information.
//
Procedure OnSendMessage(MessagesChannel, Body) Export	
EndProcedure

// Event handler when a message is received.
// The handler for this event is called when a message is received from an XML stream.
// The handler is called for each message received.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  MessagesChannel - String - ID of the message channel from which the message was received.
//  Body - Arbitrary - The body of the received message. In the event handler, the message body
//                                 can be changed, for example, supplemented with information.
//
Procedure OnMessage(MessagesChannel, Body) Export	
EndProcedure

// See MessagesExchangeInner.
// @skip-check module-empty-method - a feature of the implementation.
Procedure OnMessageProcessingAttemptsExhausting(MessagesChannel, Body, Sender, DetailErrorDescription) Export
EndProcedure

#EndRegion
