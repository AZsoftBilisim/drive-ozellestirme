#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.GoodsToBeRegisteredInReportsToConsignor.Name;
	NameOfChangeTable = "ChangesTableGoodsToBeRegisteredInReportsToConsignor"; 
	
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
	|	ValueAllowed(InventoryOwnerAttribute.Organization)
	|	AND ValueAllowed(InventoryOwnerAttribute.GoodsOwner)";

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
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.InversionOfRegisteredRecords = True;
	ReflectionParameters.PathToDataDivision = "ItemsLocationAttributes.Department";
	ReflectionParameters.DataPathCurrency = "Currency";
	ReflectionParameters.ManResources.Add("0");
	ReflectionParameters.ManResources.Add("RevenueAmountMan");
	ReflectionParameters.LocalResources.Add("0");
	ReflectionParameters.LocalResources.Add("RevenueAmountExclVATLocal");
	ReflectionParameters.ShaftResources.Add("RevenueAmount");
	ReflectionParameters.ResourcesQuantity.Add("Count");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Products;
	ReflectionParameters.DataPathDopSettingUpHouseholdOfOperation = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.ConsignmentSale)
		|		WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|			THEN CASE
		|				WHEN DataSourceAlias.DocumentSalesOfGoodsAndServices REFS Document.CustomerInvoice
		|					THEN CASE
		|						WHEN BEGINOFPERIOD(CAST(DataSourceAlias.DocumentSalesOfGoodsAndServices AS Document.CustomerInvoice).DATE, MONTH) < BEGINOFPERIOD(DataSourceAlias.Period, MONTH)
		|							THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
		|						ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
		|					END
		|				WHEN DataSourceAlias.DocumentSalesOfGoodsAndServices REFS Document.RetailSalesReport
		|					THEN CASE
		|						WHEN BEGINOFPERIOD(CAST(DataSourceAlias.DocumentSalesOfGoodsAndServices AS Document.RetailSalesReport).DATE, MONTH) < BEGINOFPERIOD(DataSourceAlias.Period, MONTH)
		|							THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
		|						ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
		|					END
		|				ELSE DataSourceAlias.BusinessTransactionSetting
		|			END
		|		ELSE DataSourceAlias.BusinessTransactionSetting
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	FinancialAccountingByFinancialRegisterData.UseLineNumberAsLineId(ReflectionParameters);
	Return ReflectionParameters;
	
EndFunction

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
	
	If Not DataForRegisteringTasks = Undefined Then
		Return DataForRegisteringTasks;
	EndIf;
	
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	
	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#EndRegion

#EndIf