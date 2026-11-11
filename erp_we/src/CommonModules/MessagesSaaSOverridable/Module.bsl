
#Region Public

// Event handler when a message is received.
// The handler for this event is called when a message is received from an XML stream.
// The handler is called for each message received.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  MessagesChannel - String - ID of the message channel from which the message was received.
//  Body - Arbitrary - Body of the received message. In the event handler 
//   , the message body can be changed, for example, supplemented with information.
//  MessageObject1 - Arbitrary - The object of the received message.
//
Procedure OnMessage(MessagesChannel, Body, MessageObject1) Export
EndProcedure

// Event handler when sending a message.
// The handler for this event is called before the message is placed in the XML stream.
// The handler is called for each message sent.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  MessagesChannel - String - ID of the message channel that the message is being sent to.
//  Body - Arbitrary - body of the message being sent. In the event handler, the message body
//    can be changed, for example, supplemented with information.
//  MessageObject1 - Arbitrary - The object of the message being sent.
//
Procedure OnSendMessage(MessagesChannel, Body, MessageObject1) Export
EndProcedure

// The procedure is called when processing an incoming message begins.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Message - XDTODataObject - incoming message,
//  Sender - ExchangePlanRef.MessagesExchange - node of the exchange plan corresponding
//    to the information base that sent the message.
//
Procedure OnMessageProcessingStart(Val Message, Val Sender) Export
EndProcedure

// The procedure is called after processing an incoming message.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Message - XDTODataObject - incoming message,
//  Sender - ExchangePlanRef.MessagesExchange - exchange plan node corresponding
//    to the information base that sent the message,
//  MessageProcessed - Boolean - Flag indicating that the message was successfully processed. If the value
//    is set to False, an exception will be thrown after executing this procedure. In this
//    procedure, the value of this parameter can be changed.
//
Procedure AfterProcessingMessage(Val Message, Val Sender, MessageProcessed) Export
EndProcedure

// The procedure is called when a message processing error occurs.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Message - XDTODataObject - incoming message,
//  Sender - ExchangePlanRef.MessagesExchange - node of the exchange plan corresponding
//    to the information base that sent the message.
//
Procedure OnMessageProcessingError(Val Message, Val Sender) Export
EndProcedure

#EndRegion
