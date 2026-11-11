///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead, use "AddInsServer.AddInInformation". 
// Returns the information about an add-in by its ID and version.
//
// Parameters:
//  Id - String - Add-in identification code.
//  Version - String - Add-in version. 
//
// Returns:
//  Structure:
//      * Exists - Boolean - Add-in absence flag.
//      * EditingAvailable - Boolean - indicates that the area administrator can change the add-in.
//      * ErrorDescription - String - brief error message.
//      * Id - String - the add-in identification code.
//      * Version - String - Add-in version.
//      * Description - String - Add-in description and brief details.
//
// Example:
//
//  Result = AddInServerCall.InformationOnAddIn("InputDevice", "8.1.7.10");
//
//  If Result.Exists Then
//      ID = Result.ID;
//      Version        = Result.Version;
//      Description = Result.Description;
//  Else
//      CommonClientServer.MessageToUser(Result.ErrorDetails);
//  EndIf;
//
Function AddInInformation(Val Id, Val Version = Undefined) Export
	
	Return AddInsServer.AddInInformation(Id, Version);
	
EndFunction

#EndRegion

#EndRegion
