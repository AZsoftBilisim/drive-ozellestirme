////////////////////////////////////////////////////////////////////////////////
// Updating of the information database: Service Technology Library (BTS).
// BTS procedures and functions.
//
////////////////////////////////////////////////////////////////////////////////
//


#Region Public

// See InfobaseUpdateSSL.OnAddSubsystem
// Parameters:
//	LongDesc - See InfobaseUpdateSSL.OnAddSubsystem.LongDesc
Procedure OnAddSubsystem(LongDesc) Export
	
	LongDesc.Name    = "CloudTechnologyLibrary";
	LongDesc.Version = CloudTechnology.LibraryVersion();
	
	// A library of standard subsystems is required.
	LongDesc.RequiredSubsystems1.Add("StandardSubsystems");
	
	LongDesc.OnlineSupportID = "SMTL";
	
EndProcedure

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
//  Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
// Example:
//  Adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version = "1.0.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_0_0_0";
//  Handler.Monopoly Mode = False;
//  Handler.Optional = True;
// 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	// Mandatory subsystems
	CloudTechnology.RegisterUpdateHandlers(Handlers);
	
	// Optional subsystems
	
	If Common.SubsystemExists("CloudTechnology.ExportImportData") Then
		ModuleExportImportDataInternal = Common.CommonModule("ExportImportDataInternal");
		ModuleExportImportDataInternal.RegisterUpdateHandlers(Handlers);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.InformationCenter") Then
		ModuleInformationCenterInternal = Common.CommonModule("InformationCenterInternal");
		ModuleInformationCenterInternal.RegisterUpdateHandlers(Handlers);
	EndIf;
	
	If SaaSOperations.DataSeparationEnabled()
		And Common.SubsystemExists("CloudTechnology.QualityControlCenter") Then
		ModuleQCCIncidentsInternal = Common.CommonModule("IncidentsQCCInternal");
		ModuleQCCIncidentsInternal.RegisterUpdateHandlers(Handlers);
	EndIf;
	
	SaaSOperationsCTL.OnAddUpdateHandlers(Handlers);
	CTLSubsystemsIntegration.OnAddCTLUpdateHandlers(Handlers);
	
	If Common.SubsystemExists("CloudTechnology.ExtensionsSaaS") Then
		ModuleExtensionsSaaS = Common.CommonModule("ExtensionsSaaS");
		ModuleExtensionsSaaS.OnAddUpdateHandlers(Handlers);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.TariffsManagement") Then
		ModuleTariffication = Common.CommonModule("Tariffication");
		ModuleTariffication.OnAddUpdateHandlers(Handlers);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.JobsQueueExternalInterface") Then
		TaskQueueModuleExternalInterface = Common.CommonModule("JobsQueueExternalInterface");
		TaskQueueModuleExternalInterface.OnAddUpdateHandlers(Handlers);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.ApplicationsMigration") Then
		ApplicationMigrationModule = Common.CommonModule("ApplicationsMigration");
		ApplicationMigrationModule.OnAddUpdateHandlers(Handlers);
	EndIf;
	
	SaaSOperations.OnAddUpdateHandlers(Handlers);
	JobsQueueInternalDataSeparation.OnAddUpdateHandlers(Handlers);
	MessagesExchangeInner.OnAddUpdateHandlers(Handlers);
	JobsQueueInternal.OnAddUpdateHandlers(Handlers);
	
EndProcedure

// Called before procedures that handle updating is data.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure BeforeUpdateInfobase() Export
EndProcedure

// Called after the is data update is complete.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//   PreviousVersion - String - version before update. "0.0.0.0" for "empty" is.
//   CurrentVersion - String - version after the update.
//   CompletedHandlers - ValueTree - a list of completed update handler procedures,
//		grouped by version number.
//   OutputUpdatesDetails - Boolean - (return value) if set to True
//		it will be given form with the description of the updates. By default, True.
//   ExclusiveMode - Boolean - True if the update was performed in exclusive mode.
//   
// Example:
// 
//	Bypassing completed update handlers.
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
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//   Template - SpreadsheetDocument - description of updating all libraries and configurations.
//           The Template can be supplemented or replaced.
//            See also the general Template for the description of system changes.
//
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
EndProcedure

// Adds transition handler procedures from another program (with a different configuration name) to the list.
// For example, to switch between different but related configurations: basic - > Prof. - > Corp.
// Called before starting updating the information security data.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//  Handlers - ValueTable - with columns:
//    * PreviousConfigurationName - String - name of the configuration to be migrated from;
//    * Procedure                 - String - the full name of the procedure that handles the transition from the program to the previous configuration name. 
//                                  For example, "Updating the information database".Fill out the accounting policy"
//                                  It must be exported.
//                                  
// Example:
//  Handler = Handlers.Add();
//  Handler.Previous Configuration Name = "Trade Management";
//  Handler.Procedure = "Updating the information database.Fill out Accounting policy";
//
Procedure OnAddApplicationMigrationHandlers(Handlers) Export
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
	
	StandardProcessing = False;
	DataUpdateMode = "VersionUpdate";
	
EndProcedure 

// Called after all transition handler procedures have been executed from another program (with a different configuration name),
// and before the start of updating the is data.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  PreviousConfigurationName    - String - name of the configuration before the transition.
//  PreviousConfigurationVersion - String - name of the previous configuration (before the transition).
//  Parameters                    - Structure - with properties: 
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
