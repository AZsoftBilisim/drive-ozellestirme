///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the namespace of the current (used by the calling code) version of the message interface.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//  String - package name.
//
Function Package() Export
EndFunction

// Returns the current (used by the calling code) version of the message interface.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//  String - package version.
//
Function Version() Export
EndFunction

// Returns the name of the message programming interface.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//  String - ID of the program interface.
//
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

// Returns the message type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d }PlanZoneBackup.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTODataObject - message.
//
Function MessagePlanAreaArchiving(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d }CancelZoneBackup.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTODataObject - message.
//
Function CancelAreaArchivingMessage(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d }UpdateScheduledZoneBackupSettings
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTODataObject - message.
//
Function MessageUpdatePeriodicBackupSettings(Val PackageToUse = Undefined) Export
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d }CancelScheduledZoneBackup
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  PackageToUse - String - namespace of the message interface version for which the message type is obtained.
//
// Returns:
//  XDTODataObject - message.
//
Function CancelPeriodicBackupMessage(Val PackageToUse = Undefined) Export
EndFunction

#EndRegion
