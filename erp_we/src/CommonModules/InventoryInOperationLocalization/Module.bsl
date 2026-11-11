////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the TMC subsystem in operation.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public


#Region Other

//  See AccessManagementOverridable.OnFillListsWithAccessRestriction 
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure AddParametersForDocument(Parameters, Document, Properties) Export
	
	
EndProcedure

// The procedure of formation of movements on the slave registers of settlements.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions.
//
Procedure CustomizeReportsOptions(Settings) Export


EndProcedure

// Defines configuration objects whose manager modules have a procedure for adding Report commands
// describing commands for opening contextual reports.
// For the syntax of the Add Report Commands procedure, see the documentation.
//
// Parameters:
//   Objects - Array - metadata objects (metadata Objects) with report commands.
//
Procedure DefineObjectsWithReportCommands(Objects) Export
	
	
EndProcedure

// Adds roles to the profile that allow you to work in the VNA subsystem with change rights.
// 
// Parameters:
// 	ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
Procedure AddRolesToAccessSubsystemForModification(ProfileDetails) Export
	

EndProcedure

Procedure SupplementBusinessOperationsAndDocuments(BusinessTransactionsAndDocuments) Export

	
EndProcedure

Procedure WhenRecordingTMTSVRegisterOfOperation(Recorder, TempTablesManager) Export
	

EndProcedure


#EndRegion
