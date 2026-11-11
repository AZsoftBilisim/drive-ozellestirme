
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
	ReflectionParameters.DataPathOrganization = "AccountingDimensionByPartners.Organization";
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.DataPathConfigurationObject = "ARAPObject.FinancialAccountingGroup";
	ReflectionParameters.PathToDataLineOfBusiness = "ARAPObject.LineOfBusiness";
	ReflectionParameters.PathToDataDivision = "ARAPObject.Department";
	ReflectionParameters.DataPathCurrency = "Currency";
	ReflectionParameters.ManResources.Add("DiscountingAmountMan");
	ReflectionParameters.LocalResources.Add("DiscountingAmountCompl");
	ReflectionParameters.ShaftResources.Add("DiscountingAmount");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Counterparties;
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

// For selection by type in queries
// 
// Returns:
//  Array - types of documents for which discounting is applicable
//
Function GetTypesOfDocumentsInvolvedInDiscounting() Export 
	
	DocumentTypes = New Array;
	DocumentTypes.Add(Type("DocumentRef.VendorInvoice"));
	DocumentTypes.Add(Type("DocumentRef.VendorInvoiceServicesAndAssets"));
	DocumentTypes.Add(Type("DocumentRef.PurchaseAdjustment"));
	DocumentTypes.Add(Type("DocumentRef.OBEntryARAP"));
	DocumentTypes.Add(Type("DocumentRef.SourceDocument"));
	DocumentTypes.Add(Type("DocumentRef.ReversingEntry"));
	
	Return DocumentTypes;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN InformationRegister.AccountingDimensionByPartners AS T1 
	|	ON T.AccountingDimensionByPartners = T1.DimensionKey
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(T1.Organization)
	|	AND ValueAllowed(T1.Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region BackdateJobQueue

// Data for the formation of tasks for non-operational document verification.
// Called when writing a set of register entries.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - Undefined, TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
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
	TempTablesManager = Undefined, DataForRegisteringTasks = Undefined) Export
	
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	
	If Not TempTablesManager = Undefined 
		And TempTablesManager.Tables.Find("QueueDataForAdditionalDocuments") <> Undefined Then
		
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.Text = "
		|SELECT DISTINCT
		|	CatalogAccountingDimensionByPartners.Organization AS Organization,
		|	ChangedData.TaskPeriod AS TaskPeriod,
		|	ChangedData.Document AS Document,
		|	ChangedData.DiscountingAmountMan AS DiscountingAmountMan
		|FROM
		|	QueueDataForAdditionalDocuments AS ChangedData
		|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS CatalogAccountingDimensionByPartners
		|		ON ChangedData.AccountingDimensionByPartners = CatalogAccountingDimensionByPartners.Ref";

		DataForProcessing_ = Query.Execute().Unload();

		For Each Record In DataForProcessing_ Do

			For Each CurrentTypeOfTask In KindsOfTasks Do

				If CurrentTypeOfTask = Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords Then
					
					If Record.DiscountingAmountMan <> 0 Then
						NewRow = DataTable.Add();
						FillPropertyValues(NewRow, Record);
						NewRow.JobKind = CurrentTypeOfTask;
					EndIf;

				EndIf;

				If CurrentTypeOfTask = Catalogs.BackdateJobKinds.UpdateCounterpartyCounterpartyRegisterRecords Then

					If TypeOf(Record.Document) = Type("DocumentRef.CalculationOfDiscountInterestExpenses") Then
						Continue;
					EndIf;

					NewRow = DataTable.Add();
					FillPropertyValues(NewRow, Record);
					NewRow.JobKind = CurrentTypeOfTask;

				EndIf;

			EndDo;

		EndDo;
		
	EndIf;
	
	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
