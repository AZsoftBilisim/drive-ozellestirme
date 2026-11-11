
///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Fills in basic information about the library or main configuration.
// A library whose name matches the name of the configuration in the metadata is defined as the main configuration.
// 
// Parameters:
//  LongDesc - Structure - information about the library:
//
//   * Name                 - String - name of the library, for example, "standard Subsystems".
//   * Version              - String - version in 4-digit format, for example, "2.1.3.1".
//
//   * RequiredSubsystems1 - Array - names of other libraries (String) that this library depends on.
//                                    Update handlers for such libraries must be called earlier
//                                    than the update handlers for this library.
//                                    If there are cyclic dependencies or, on the contrary, there are no dependencies,
//                                    the order of calling update handlers is determined by the order of adding modules
//                                    in the procedure for adding General module Subsystems
//                                    Configuration subsystems are undefined.
//
Procedure OnAddSubsystem(LongDesc) Export
	
	LongDesc.Name    = "LoyaltyServerLibrary";
	LongDesc.Version = CommonLoyaltyServerClientServer.LibraryVersion();
	
EndProcedure

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
//  Handlers - ValueTable - for a description of the fields, see the procedure.
//                Updating the information database.The new Update processing table.
//
// Example:
//  Handler = Handlers.Add();
//  Handler.Version = "1.1.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_1_0_0";
//  Handler.Execution mode = "Monopoly".
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
EndProcedure

// Called before procedures that handle updating is data.
//
Procedure BeforeUpdateInfobase() Export
	
EndProcedure

// Called after the is data update is complete.
// 
// Parameters:
//   PreviousVersion       - String - version before update. "0.0.0.0" for "empty" is.
//   CurrentVersion          - String - version after the update.
//   CompletedHandlers - ValueTree - a list of completed update handler procedures,
//                                             grouped by version number.
//   OutputUpdatesDetails - Boolean - if set to True, a form
//                                with a description of updates will be displayed. By default, True.
//                                Returned value.
//   ExclusiveMode           - Boolean - True if the update was performed in exclusive mode.
//
// Example:
//  Example of bypassing executed update handlers:
//	For Each Version Of The Executed processors.Lines Cycle
//		
//		If The Version.Version = "*" Then
//			A handler that can be executed every time the version is changed.
//		Otherwise
//			A handler that is executed for a specific version.
//		The end if;
//		
//		For Each Handler From The Version.The lines are a Cycle
//			...
//		the end of the cycle;
//		
//	The end of the cycle;
//
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	
EndProcedure

// Called when preparing a table document describing changes in the program.
//
// Parameters:
//   Template - SpreadsheetDocument - description of updating all libraries and configurations.
//           The Template can be supplemented or replaced.
//            See also the general Template for the description of system changes.
//
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
	
EndProcedure

// Allows you to override the data update mode of the information database.
// For use in rare (non-standard) cases of transition that are not provided for in
// the standard procedure for determining the update mode.
//
// Parameters:
//   DataUpdateMode - String - in the handler, you can assign one of the values:
//              "Initial filling" - if this is the first launch of an empty database (data area);
//              "Version update" - if the first launch is performed after updating the database configuration;
//              "Transition to another program" - if the first run is performed after updating the database configuration 
//                                          in which the name of the main configuration has changed.
//
//   StandardProcessing  - Boolean - if set to False, the standard procedure
//                                    for determining the update mode is not performed, 
//                                    but the value of the data update Mode is used.
//
Procedure OnDefineDataUpdateMode(DataUpdateMode, StandardProcessing) Export
 
EndProcedure

// Adds transition handler procedures from another program (with a different configuration name) to the list.
// For example, to switch between different but related configurations: basic - > Prof. - > Corp.
// Called before starting updating the information security data.
//
// Parameters:
//  Handlers - ValueTable - with columns:
//    * PreviousConfigurationName - String - name of the configuration to be migrated from;
//                                           or " * " if you want to perform it when switching from any configuration.
//    * Procedure                 - String - the full name of the procedure that handles the transition from the program to the previous configuration name. 
//                                  For example, "Updating the information database".Fill out the accounting policy"
//                                  It must be exported.
//
// Example:
//  Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Previous Configuration Name = "Trade Management";
//  Handler.Procedure = "Updating the information database.Fill out the accounting policy."
//
Procedure OnAddApplicationMigrationHandlers(Handlers) Export
 
EndProcedure

// Called after all transition handler procedures have been executed from another program (with a different configuration name),
// and before the start of updating the is data.
//
// Parameters:
//  PreviousConfigurationName    - String - name of the configuration before the transition.
//  PreviousConfigurationVersion - String - name of the previous configuration (before the transition).
//  Parameters                    - Structure:
//    * ExecuteUpdateFromVersion   - Boolean - by default, True. If set to False, 
//        only the required update handlers (with the "* " version) will be executed.
//    * ConfigurationVersion           - String - version number after the transition. 
//        By default, it is equal to the value of the configuration version in the metadata properties.
//        To run, for example, all update handlers from the previous configuration Version, 
//        set the parameter value to previous configuration Version.
//        To run all update handlers at all, set the value to "0.0.0.1".
//    * ClearPreviousConfigurationInfo - Boolean - by default, True. 
//        If the previous configuration matches the name of the subsystem in the current configuration,
//        specify False.
//
Procedure OnCompleteApplicationMigration(Val PreviousConfigurationName, Val PreviousConfigurationVersion, Parameters) Export
 
EndProcedure

#EndRegion
