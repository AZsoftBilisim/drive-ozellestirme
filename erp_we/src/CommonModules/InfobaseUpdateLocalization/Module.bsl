#Region LibraryOrConfigurationInformation

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
//   * DeferredHandlersExecutionMode - String - "Sequentially" - deferred update handlers are executed
//                                    sequentially in the range from the version number of the information database to
//                                    the configuration version number inclusive, or "in Parallel" - the deferred
//                                    handler passes control to the next handler after processing the first batch of data, and after
//                                    the last handler is executed, the cycle repeats again.
//
Procedure OnAddSubsystem(LongDesc) Export
	
	LongDesc.Name    = "Localization" + ?(StandardSubsystemsServer.IsBaseConfigurationVersion(), "Basic", "");
	LongDesc.Version = "2.5.27.61";
	LongDesc.DeferredHandlersExecutionMode = "Parallel";
	
EndProcedure

// See InfobaseUpdateOverridable.OnDefineSettings
Procedure OnDefineSettings(Parameters) Export
	
		
EndProcedure

#EndRegion

#Region InfobaseUpdateHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	
EndProcedure

// Allows you to redefine the queue of deferred update handlers running in
// parallel mode. This may be necessary when deferred library handlers
// process the same data as the main configuration handlers.
// For example, there are library and configuration handlers that process the directory
// Contractors, and the configuration handler must be executed earlier for the data
// to be updated correctly. In this case, in this procedure, you need to specify a new queue number
// for the library handler, which will be greater than that of the configuration handler.
//
// Parameters:
//  HandlerAndQueue - Map - Where:
//    * Key     - String - full name of the update handler.
//    * Value - Number  - the queue number to set for the handler.
//
Procedure WhenCreatingQueuesForDeferredHandlers(HandlerAndQueue) Export

	Return;

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
//   OutputUpdatesDetails - Boolean - (return value) if set to True,
//                                a form describing updates will be displayed. By default, True.
//   ExclusiveMode           - Boolean - True if the update was performed in exclusive mode.
//
// Example of bypassing executed update handlers:
//
//	For Each Version Of The Executed processors.Lines Cycle
//		
//		If The Version.Version = "*" Then
//			A handler that can be executed every time the version is changed.
//		Otherwise
//			A handler that is executed for a specific version.
//		The end if;
//		
//		For Each Handler From The Version.The lines of the Cycle
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
//            See the general Template description of the system changes.
//
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
	
EndProcedure
// Adds transition handler procedures from another program (with a different configuration name) to the list.
// For example, to switch between different but related configurations: basic - > Prof. - > Corp.
// Called before starting updating the information security data.
//
// Parameters:
//  Handlers - ValueTable - with columns:
//    * PreviousConfigurationName - String - name of the configuration to be migrated from;
//    * Procedure                 - String - the full name of the procedure that handles the transition from the previous configuration programname. 
//                                  For example, "Updating the information database.Fill out Accounting policy"
//                                  It must be export.
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Previous Configuration Name = "Trade Management";
//  Handler.Procedure = "Updating the information database.Fill out Accounting policy";
//
Procedure WhenAddingTrafficHandlers(Handlers) Export
	
	
EndProcedure
// Adds transition handler procedures from another program (with a different configuration name) to the list.
// For example, to switch between different but related configurations: basic - > Prof. - > Corp.
// Called before starting updating the information security data.
//
// Parameters:
//  Handlers - ValueTable - with columns:
//    * PreviousConfigurationName - String - name of the configuration to be migrated from;
//    * Procedure                 - String - the full name of the procedure that handles the transition from the previous configuration programname. 
//                                  For example, "Updating the information database.Fill out Accounting policy"
//                                  It must be export.
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Previous Configuration Name = "Trade Management";
//  Handler.Procedure = "Updating the information database.Fill out Accounting policy";
//
Procedure WhenAddingClickThroughHandlers(Handlers) Export
	
	
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
Procedure OnCompleteApplicationMigration(Val PreviousConfigurationName, 
	Val PreviousConfigurationVersion, Parameters) Export
	
	
EndProcedure

// See InfobaseUpdateOverridable.OnPopulateObjectsPlannedForDeletion
//
Procedure OnPopulateObjectsPlannedForDeletion(Objects) Export
	
	
EndProcedure

#EndRegion

#Region RenamedMetadataObjects

// Fills in renaming metadata objects (subsystems and roles).
// More detailed See CommonOverridable.OnAddMetadataObjectsRenaming.
// 
// Parameters:
//   Total	- Structure - passed to the procedure by the basic Functionality subsystem.
//
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	SubsystemDetails = New Structure("Name, Version, DeferredHandlersExecutionMode");
	OnAddSubsystem(SubsystemDetails);
	
		
EndProcedure

#EndRegion

#Region Private

#Region FillingInEmptyIB

// Handler for the first launch of the up (ERP).
//
Procedure FirstRun() Export
	
	
EndProcedure
Procedure UpgradeUTToKa() Export
	
	
EndProcedure

Procedure UpdatingUTToERP() Export
	
	
EndProcedure

Procedure UpgradingKaToERP() Export
	
	
EndProcedure

#EndRegion

#Region Other


#EndRegion

#EndRegion
