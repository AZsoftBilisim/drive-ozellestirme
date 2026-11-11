#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	See DocumentsPosting.RequestTextTemplateBanDateControl
Function RequestTextMonitoringBanDate(Query) Export
	
	RegisterName = Metadata.AccumulationRegisters.GoodsCostVariances.Name;
	NameOfChangeTable = "ChangesTableGoodsCostVariances"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
	
	Return StructureOfQueryTexts_;

EndFunction

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

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Filling in access restrictions.
// 
// Parameters:
// 	Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

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
	
	ReflectionParameters.PathToDataLineOfBusiness = "LineOfBusiness";
	ReflectionParameters.PathToDataDivision = "Department";
	ReflectionParameters.DataPathConfigurationObject = "Products.FinancialAccountingGroup";
	ReflectionParameters.DataPathAccountingLocation = "StorageLocation";
	ReflectionParameters.ManResources.Add("CostVariancesMgmt");
	ReflectionParameters.ManResources.Add("AddExpensesMan");
	ReflectionParameters.ManResources.Add("VATManag");
	ReflectionParameters.LocalResources.Add("CostVariancesLocal");
	ReflectionParameters.LocalResources.Add("AddExpensesLocal");
	ReflectionParameters.LocalResources.Add("VATLocal");
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Products;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(
		DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.Products.DataPath = "Products";
	ReflectionParameters.StructureOfAnalytics.Warehouse.DataPath = "StorageLocation";
	IdentifyIndicators(ReflectionParameters);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

// Defines register indicators
//
// Parameters:
//  ReflectionParameters - See ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Procedure IdentifyIndicators(ReflectionParameters)
	
	// Additional expenses Amount
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("CostVariancesMgmt");
	IndicatorReflectionParameters.ManResources.Add("AddExpensesMan");
	IndicatorReflectionParameters.LocalResources.Add("CostVariancesLocal");
	IndicatorReflectionParameters.LocalResources.Add("AddExpensesLocal");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditExpenseAmount, IndicatorReflectionParameters);
	
	// Additional expensed amount excluding VAT
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("CostVariancesExcludingVAT");
	IndicatorReflectionParameters.ManResources.Add("AdditionalExpensesExcludingVAT");
	IndicatorReflectionParameters.LocalResources.Add("0");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT, IndicatorReflectionParameters);
	
	// VAT amount of the Additional expense amount
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("CostVariancesIncludingVAT");
	IndicatorReflectionParameters.ManResources.Add("AdditionalExpensesIncludingVAT");
	IndicatorReflectionParameters.ManResources.Add("-CostVariancesExcludingVAT");
	IndicatorReflectionParameters.ManResources.Add("-AdditionalExpensesExcludingVAT");
	IndicatorReflectionParameters.LocalResources.Add("0");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense, IndicatorReflectionParameters);
	
	// amount of VAT
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("VATManag");
	IndicatorReflectionParameters.LocalResources.Add("VATLocal");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATAmount, IndicatorReflectionParameters);
	
EndProcedure


#EndRegion

#EndRegion

#EndIf
