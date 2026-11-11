
#Region Public

// Returns a new message.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  MessageBodyType - XDTOObjectType - type the message body you want to create.
//
// Returns:
//  XDTODataObject - an object of the required type.
//  
Function NewMessage(Val MessageBodyType) Export
EndFunction

// Send messages
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  Message - XDTODataObject - message.
//  Recipient - ExchangePlanRef.MessagesExchange - message recipient.
//  Now - Boolean - send messages via the quick message mechanism.
//
Procedure SendMessage(Val Message, Val Recipient = Undefined,
		Val Now = False) Export
EndProcedure

// Retrieves a list of message handlers by namespace.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//  Handlers - ValueTable - with columns:
//    * Canal - String - Message channel.
//    * Handler - CommonModule - Message handler.
//  Namespace - String - uri of the namespace where message body types are defined.
//  CommonModule - CommonModule - A General module that contains message handlers.
// 
Procedure GetMessagesChannelsHandlers(Val Handlers,
		Val Namespace, Val CommonModule) Export
EndProcedure

// Delivers quick messages.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure DeliverQuickMessages() Export
EndProcedure

// Returns the type that is the base type for all message body types in the service model.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//  XDTOObjectType - the basic type of message bodies in the service model.
//
Function TypeBody() Export
EndFunction

#EndRegion

#Region Internal

// @skip-warning EmptyMethod - a feature of the implementation.
Procedure SetAreaKeyWhenRestoringFromUpload(Message) Export	
EndProcedure

// Reads a message from an untyped message body.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  UntypedBody - String - untyped message body.
//
// Returns:
//  XDTODataObject - {http://www.1c.ru/SaaS/Messages }Message - message.
//
Function ReadMessageFromUntypedBody(Val UntypedBody) Export
EndFunction

// Returns the name of the message channel corresponding to the message type.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  MessageType - XDTOObjectType - type of remote administration message.
//
// Returns:
//  String - the name of the message channel corresponding to the transmitted message type.
//
Function ChannelNameByMessageType(Val MessageType) Export	
EndFunction

#EndRegion

