///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the namespace of the message interface version.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//	String - package name.
//
Function Package() Export
EndFunction

// Returns the version of the message interface served by the handler.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//	String - package version.
//
Function Version() Export
EndFunction

// Returns the base type for version messages.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//	XDTOObjectType - the basic type of message bodies in the service model.
//
Function BaseType() Export
EndFunction

// Processes incoming messages from the service model.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  Message - XDTODataObject - incoming message,
//  Sender - ExchangePlanRef.MessagesExchange - the exchange plan node that corresponds to the sender of the message.
//  MessageProcessed - Boolean - flag for successful message processing. The value of this parameter must
//    be set to True if the message was successfully read in this handler.
//
Procedure ProcessSaaSMessage(Val Message, Val Sender, MessageProcessed) Export
EndProcedure

#EndRegion
