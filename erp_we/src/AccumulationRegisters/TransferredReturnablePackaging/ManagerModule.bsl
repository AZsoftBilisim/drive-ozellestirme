#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.TransferredReturnablePackaging.Name;
	NameOfChangeTable = "RegisteredRecordsTransferredReturnPackagingChange"; 
	
	QueryText =
	"SELECT
	|	Table.Period AS Period,
	|	UNDEFINED AS Organization,
	|	&RegisterName AS RegisterName,
	|	&Section AS SectionClosingDates
	|FROM
	|	&NameOfChangeTable AS Table
	|";
	
	ParameterNameRegisterName = "RegisterName" + RegisterName;
	NameOfSectionParameter = "Section" + RegisterName;
	
	QueryText = StrReplace(QueryText,"&RegisterName", "&" + ParameterNameRegisterName);
	QueryText = StrReplace(QueryText,"&Section", "&" + NameOfSectionParameter);
	QueryText = StrReplace(QueryText,"&NameOfChangeTable", NameOfChangeTable);
	
	Query.SetParameter(ParameterNameRegisterName, RegisterName);
	Query.SetParameter(NameOfSectionParameter, "FinancialOutline");
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_

EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(DocumentTransfers_.Organization)
	|	AND ValueAllowed(DocumentTransfers_.Warehouse)
	|	AND ValueAllowed(Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

// Fills in the parameters for reflecting register movements in financial accounting
//
// Parameters:
//  RegisterMetadata - MetadataObjectAccumulationRegister - Metadata of the accumulation register
//  RegistrationForReflection - Boolean - Flag for getting parameters to register for accounting
//
// Returns:
// 	See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Function ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegisterMetadata = Undefined, RegistrationForReflection = False) Export
	
	ReflectionParameters = FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegistrationForReflection);
	ReflectionParameters.DataPathOrganization = "Recorder.Organization";
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.DataPathCurrency = "DocumentTransfers_.Currency";
	ReflectionParameters.ShaftResources.Add("Sum");
	ReflectionParameters.ResourcesQuantity.Add("Count");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Products;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.Products.DataPath = "Products";
	ReflectionParameters.StructureOfAnalytics.Warehouse.DataPath = "Partner";
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

//
#EndRegion

#Region BackdateJobQueue

// Data for the formation of tasks for non-operational document verification.
// Called when writing a set of register entries.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
// 
// Returns:
//  ValueTable - Data For The Formation Of Tasks For Non-Operational Document Verification:
// * Organization - CatalogRef.Companies - The organization for which the new task will be generated.
// * TaskPeriod  - Date - The task period. Coincides with the period of the recorded data in the register.
// * Document - DocumentRef - Link to the document for which the task will be registered.
// * JobKind - CatalogRef.BackdateJobKinds - Type of registered task.
//
Function DataForFormationOfTasksForNonOperationalDocumentVerification(RecordSet, KindsOfTasks,
	TempTablesManager, DataForRegisteringTasks = Undefined) Export
	
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	
	If KindsOfTasks.Find(Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords) <> Undefined Then

		Query = New Query;
		Query.TempTablesManager = TempTablesManager;

		Query.Text = "
		|SELECT DISTINCT
		|	DataForProcessing_.TaskPeriod AS TaskPeriod,
		|	DataForProcessing_.Document AS Document,
		|	CASE
		|		WHEN DataForProcessing_.DocumentTransfers_ REFS Document.CustomerInvoice
		|			THEN CAST(DataForProcessing_.DocumentTransfers_ AS Document.CustomerInvoice).Organization
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS Organization,
		|	VALUE(Catalog.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords) AS JobKind
		|FROM
		|	QueueDataForAdditionalDocumentsManBalance AS DataForProcessing_
		|WHERE
		|	CASE
		|		WHEN DataForProcessing_.DocumentTransfers_ REFS Document.CustomerInvoice
		|			THEN CAST(DataForProcessing_.DocumentTransfers_ AS Document.CustomerInvoice).Organization
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END <> VALUE(Catalog.Companies.EmptyRef)";
		
		DataTable = Query.Execute().Unload();
		
		For Each CurrentTypeOfTask In KindsOfTasks Do

			If CurrentTypeOfTask = Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords Then

				Return DataTable;

			EndIf;

		EndDo;
		
	EndIf;
	
	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion
	
#EndIf
