///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Prompts the user to confirm that the update is received legally and
// closes the application if the update is received illegally
// (see the "TerminateApplication" parameter).
//
// Parameters:
//  Notification             - CallbackDescription - Contains the handler that is called following
//                                    the software license confirmation.
//  TerminateApplication - Boolean - Exit the app if the user selected that their software is unlicensed.
//                                    
//
Procedure ShowLegitimateSoftwareCheck(Notification, TerminateApplication = False) Export
	
	If StandardSubsystemsClient.IsBaseConfigurationVersion() Then
		RunCallback(Notification, True);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowRestartWarning", TerminateApplication);
	FormParameters.Insert("OpenProgrammatically", True);
	
	OpenForm("DataProcessor.LegitimateSoftware.Form", FormParameters,,,,, Notification);
	
EndProcedure

#EndRegion

#Region Internal

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart(Parameters) Export
	
	// Check the software license on startup.
	// The procedure should run before the infobase update.
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If Not ClientParameters.Property("CheckLegitimateSoftware") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New CallbackDescription(
		"LegitimateSoftwareCheckInteractiveHandler", ThisObject);
	
EndProcedure

// For internal use only. Continues the CheckLegitimateSoftwareOnStart procedure.
Procedure LegitimateSoftwareCheckInteractiveHandler(Parameters, Context) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("OpenProgrammatically", True);
	FormParameters.Insert("ShowRestartWarning", True);
	FormParameters.Insert("SkipRestart", True);
	
	OpenForm("DataProcessor.LegitimateSoftware.Form", FormParameters, , , , ,
		New CallbackDescription("AfterCloseLegitimateSoftwareCheckFormOnStart",
			ThisObject, Parameters));
	
EndProcedure

#EndRegion

#Region Private

// For internal use only. Continues the CheckLegitimateSoftwareOnStart procedure.
Procedure AfterCloseLegitimateSoftwareCheckFormOnStart(Result, Parameters) Export
	
	If Result <> True Then
		Parameters.Cancel = True;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

#EndRegion
