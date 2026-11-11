///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Enables or disables reminders to update the bank classifier.
//
// Parameters:
//  ShowWarning - Boolean - if False, do not show warnings.
//
Procedure OnDetermineIfOutdatedClassifierWarningRequired(ShowWarning) Export
	
EndProcedure

// Determines the Bank classifier import parameters.
//
// Parameters:
//  Settings - Structure:
//   * ShouldProcessDataAreas - Boolean - Enables OnProcessDataArea procedure execution
//                                          during classifier update.
//
Procedure OnDefineBankClassifiersImportSettings(Settings) Export
	
EndProcedure

// Intended for separated mode only. It is called after the classifier is imported to run additional actions in data areas.
// The procedure execution must be enabled in "OnDefineSettings" (it's disabled by default).
//
Procedure OnProcessDataArea() Export
	
EndProcedure

#EndRegion
