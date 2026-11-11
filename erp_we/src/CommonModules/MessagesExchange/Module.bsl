
#Region Public

// Sends a message to the addressable message channel.
// Corresponds to the sending type "Endpoint/The end point."
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  MessagesChannel - String - ID of the address message channel.
//  Body - Arbitrary - The body of the message you want to send.
//  Recipient - Undefined - the recipient of the message is not specified. The message will be sent 
//  							    to the endpoints that are determined by the settings of the Cur information system:
//                              in the message interchange handler.The recipient of the message 
//                              (programmatically) and in 
//                              the Sender's Settings information register (system settings).
//             - ExchangePlanRef.MessagesExchange - the node of the exchange plan that corresponds 
//                                                   to the endpoint for which the message is intended. 
//                                                   The message will be sent only 
//                                                   to this endpoint.
//             - Array - array of recipients of the message; array elements must 
//             				have the type planobmainlink.Exchange of messages.
//                        	The message will be sent to all endpoints specified in the array.
//
Procedure SendMessage(MessagesChannel, Body = Undefined, Recipient = Undefined) Export
EndProcedure

// Sends a message to the addressable message channel.
// Corresponds to the sending type "Endpoint/The end point."
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  MessagesChannel - String - ID of the address message channel.
//  Body - Arbitrary - The body of the message you want to send.
//  Recipient - Undefined - the recipient of the message is not specified. The message will be sent 
//  							    to the endpoints that are determined by the settings of the current 
//                              information system: in the handler 
//                              The exchange of messages is undetectable.The recipient of the message (programmatically) and 
//                              in the Sender Settings information register (system settings).
//             - ExchangePlanRef.MessagesExchange - the node of the exchange plan that corresponds 
//                                                   to the endpoint for which 
//                                                   the message is intended. The message will be sent
//                                                   only to this endpoint.
//             - Array - array of recipients of the message; array elements must 
//                        have the type planobmainlink.Exchange of messages. The message will be sent 
//                        to all endpoints specified in the array.
//
Procedure SendMessageNow(MessagesChannel, Body = Undefined, Recipient = Undefined) Export
EndProcedure

// Sends a message to the broadcast message channel.
// Corresponds to the type of submission "Publication/Subscription".
// The message will be delivered to the endpoints that are subscribed to the broadcast channel.
// The setup of broadcast channel subscriptions is performed through the register of subscriber information.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  MessagesChannel - String - ID of the message broadcast channel.
//  Body - Arbitrary - The body of the message you want to send.
//
Procedure SendMessageToSubscribers(MessagesChannel, Body = Undefined) Export
EndProcedure

// Sends a quick message to the broadcast message channel.
// Corresponds to the type of submission "Publication/Subscription".
// The message will be delivered to the endpoints that are subscribed to the broadcast channel.
// The setup of broadcast channel subscriptions is performed through the register of subscriber information.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  MessagesChannel - String - ID of the message broadcast channel.
//  Body - Arbitrary - The body of the message you want to send.
//
Procedure SendMessageToSubscribersNow(MessagesChannel, Body = Undefined) Export	
EndProcedure

// Performs immediate sending of quick messages from the general message queue.
// Sending messages is performed in a loop until 
// all fast messages have been sent from the message queue.
// For the time of sending messages, the immediate sending of messages from other sessions is blocked.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure DeliverMessages() Export
EndProcedure

// Connects an endpoint.
// Before connecting the endpoint 
// , the sender-to-receiver and receiver-to-sender connection is checked. 
// It is also checked that the recipient's connection settings point to the Cur sender.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  Cancel - Boolean - Operation execution flag; raised in case of errors 
//   when connecting the endpoint.
//  SenderConnectionSettings - Structure - Sender's connection parameters. Contains properties: 
//   For initialization, the Sent Server function is used.Parameter structurews. 
//    * WSWebServiceURL   - String - The web address of the connected endpoint.
//    * WSUserName  - String - A user for authentication at the connected endpoint
//                          when working through a web service of the messaging subsystem.
//    * WSPassword - String - The password of the user at the connected endpoint.
//  RecipientConnectionSettings - Structure - Connection parameters of the recipient. Contains properties:
//   For initialization, the Sent Server function is used.Parameter structuresws. 
//    * WSWebServiceURL   - String - The web address of this information base from the 
//    	connected endpoint.
//    * WSUserName - String - The user for authentication in this information base 
//                          when working through the web service of the messaging subsystem.
//    * WSPassword - String - The password of the user in this information base.
//  Endpoint - ExchangePlanRef.MessagesExchange, Undefined - If 
//		the endpoint connection is successful, this parameter returns a link to the exchange plan node
//     that corresponds to the connected endpoint.
//     If the endpoint failed to connect, it returns Undefined.
//  RecipientEndpointName - String - Name of the connected endpoint. 
//     If the value is omitted, the name is used as a synonym
//     for the configuration of the connected endpoint.
//  SenderEndpointName - String - Name of the endpoint that corresponds
//     to this information base. If the value is omitted, the
//     name is used as a synonym for the configuration of this information base.
//
Procedure ConnectEndpoint(Cancel, SenderConnectionSettings, RecipientConnectionSettings,
	Endpoint = Undefined, RecipientEndpointName = "", 
	SenderEndpointName = "") Export	
EndProcedure

// Updates connection settings for the endpoint.
// The settings for connecting this information base to the specified endpoint
// and the settings for connecting the endpoint to this information base are updated.
// Before applying the settings, the connection is checked to ensure that the settings are set correctly.
// It is also checked that the recipient's connection settings point to the Cur sender.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  Cancel - Boolean - Operation execution flag; raised in case of errors.
//  Endpoint - ExchangePlanRef.MessagesExchange - A reference to the exchange plan node 
//   that corresponds to the endpoint.
//   
//  SenderConnectionSettings - Structure - Sender's connection parameters. Contains properties:
//   For initialization, the Sent Server function is used.Parameter structurews. 
//    * WSWebServiceURL   - String - The web address of the connected endpoint.
//    * WSUserName - String - A user for authentication at the connected endpoint
//                          when working through a web service of the messaging subsystem.
//    * WSPassword - String - The password of the user at the connected endpoint.
//  RecipientConnectionSettings - Structure - Connection parameters of the recipient. Contains properties: 
//   For initialization, the Sent Server function is used.Parameter structuresws. 
//    * WSWebServiceURL   - String - The web address of this information base from the connected 
//    		endpoint.
//    * WSUserName - String - The user for authentication in this information base 
//                          when working through the web service of the messaging subsystem.
//    * WSPassword - String - The password of the user in this information base.
//
Procedure UpdateEndpointConnectionSettings(Cancel, Endpoint,
	SenderConnectionSettings, RecipientConnectionSettings) Export
EndProcedure

#EndRegion

