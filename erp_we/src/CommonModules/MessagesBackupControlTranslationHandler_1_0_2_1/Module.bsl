///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the version number that the handler is intended to broadcast from.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//   String - the original version.
//
Function SourceVersion() Export
EndFunction

// Returns the namespace of the version that the handler is intended to broadcast from.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//   String - the package of the original version.
//
Function SourceVersionPackage() Export
EndFunction

// Returns the version number that the handler is intended to translate to.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//   String - the resulting version.
//
Function ResultingVersion() Export
EndFunction

// Returns the namespace of the version that the handler is intended to translate to.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//   String - the package of the resulting version.
//
Function ResultingVersionPackage() Export
EndFunction

// Handler for checking the execution of standard translation processing.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  SourceMessage - XDTODataObject - broadcast message,
//  StandardProcessing - Boolean - to cancel the standard translation processing
//    , this parameter must be set to False within this procedure.
//    In this case, the function will be called instead of performing standard translation processing.
//    Broadcast messages () of the broadcast handler.
//
Procedure BeforeTranslate(Val SourceMessage, StandardProcessing) Export
EndProcedure

// Handler for performing an arbitrary message translation. Called only
//  if the value of the standard Processing parameter
//  was set to False when executing the procedure before Translation.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  SourceMessage - XDTODataObject - broadcast message.
//
// Returns:
//  XDTODataObject - the result of an arbitrary broadcast of the message.
//
Function MessageTranslation(Val SourceMessage) Export
EndFunction

#EndRegion



