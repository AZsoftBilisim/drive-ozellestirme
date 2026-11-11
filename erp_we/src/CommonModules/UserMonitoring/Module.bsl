///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the value of the setting "ShouldRegisterDataAccess"
// on the panel "UsersAndRightsSettings".
//
// Returns:
//  Boolean
//
Function ShouldRegisterDataAccess() Export
	
	Return UserMonitoringInternal.ShouldRegisterDataAccess();
	
EndFunction

// Sets a value of the setting "ShouldRegisterDataAccess"
// on the panel "UsersAndRightsSettings".
//
// Parameters:
//  ShouldRegisterDataAccess - Boolean
//
Procedure SetDataAccessRegistration(ShouldRegisterDataAccess) Export
	
	UserMonitoringInternal.SetDataAccessRegistration(ShouldRegisterDataAccess);
	
EndProcedure

// Returns logging settings available from the "Settings" link on the panel
// "UsersAndRightsSettings".
//
// Returns:
//  Structure:
//    * Content - Array of EventLogAccessEventUseDescription
//    * Comments - Map of KeyAndValue:
//        * Key     - String - Full table name followed by field name. For example, "Catalog.Individuals.DocumentNumber".
//        * Value - String - Arbitrary text
//    * GeneralComment - String - Arbitrary text
//   
Function RegistrationSettingsForDataAccessEvents() Export
	
	Return UserMonitoringInternal.RegistrationSettingsForDataAccessEvents();
	
EndFunction

// Sets logging settings available from the "Settings" link on the panel
// "UsersAndRightsSettings".
//
// Parameters:
//  Settings - See RegistrationSettingsForDataAccessEvents
//
Procedure SetRegistrationSettingsForDataAccessEvents(Settings) Export
	
	UserMonitoringInternal.SetRegistrationSettingsForDataAccessEvents(Settings);
	
EndProcedure

#EndRegion
