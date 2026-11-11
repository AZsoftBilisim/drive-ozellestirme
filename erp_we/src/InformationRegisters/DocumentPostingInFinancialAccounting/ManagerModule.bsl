#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CreatingTasksInNonOperationalQueue

// Creation of non-operational queue jobs when writing data sets of source registers.
// 
// Parameters:
//  RegisterManager - AccumulationRegisterManager, InformationRegisterManager - Source register manager.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                      According to this list, new tasks must be registered according to the recorded register data.
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  TempTablesManager - Undefined, TempTablesManager - Temporary table data is used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
//
Procedure CreateJobs(RegisterManager, KindsOfTasks, RecordSet, TempTablesManager = Undefined,
	DataForRegisteringTasks = Undefined) Export

	If KindsOfTasks.Count() = 0 Then
		Return;
	EndIf;

	TableOfDocumentsToBeReflected = RegisterManager.DataForFormationOfTasksForNonOperationalDocumentVerification(
		RecordSet, KindsOfTasks, TempTablesManager, DataForRegisteringTasks);

	FinancialAccountingPostingServer.ReturnDocumentsToReflection(TableOfDocumentsToBeReflected);

EndProcedure

// Table of documents to be reflected in international accounting.
// 
// Returns:
//  ValueTable - Table Of Documents To Be Reflected In International Accounting:
// * Document - DocumentRef - Document to be reflected
// * Organization - CatalogRef.Companies - Organization
// * DateRecord - Date - Date of reflection
// * Period - Date - Reflection period
// 
Function TableOfDocumentsToBeReflectedInInternationalAccounting() Export
	
	DocumentsTable = New ValueTable();
	DocumentsTable.Columns.Add("Document", Documents.AllRefsType());
	DocumentsTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	DocumentsTable.Columns.Add("DateRecord", Common.DateTypeDetails(DateFractions.DateTime));
	DocumentsTable.Columns.Add("Period", Common.DateTypeDetails(DateFractions.DateTime));
	
	Return DocumentsTable;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf
