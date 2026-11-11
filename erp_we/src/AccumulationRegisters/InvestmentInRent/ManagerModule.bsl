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
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.DataPathConfigurationObject = "FinancialAccountingGroup";
	ReflectionParameters.DataPathAccountingLocation = "Contract.Department";
	ReflectionParameters.PathToDataLineOfBusiness = "Contract.LineOfBusiness";
	ReflectionParameters.PathToDataDivision = "Contract.Department";
	ReflectionParameters.DataPathCurrency = "Currency";
	ReflectionParameters.ManResources.Add("RentalPaymentsManag");
	ReflectionParameters.ManResources.Add("NonGuaranteedResidualValueManag");
	ReflectionParameters.ManResources.Add("InterestDiscountMan");
	ReflectionParameters.LocalResources.Add("RentalPaymentsLocal");
	ReflectionParameters.LocalResources.Add("NonGuaranteedResidualValueLocal");
	ReflectionParameters.LocalResources.Add("InterestDiscountLocal");
	ReflectionParameters.ShaftResources.Add("RentalPayments");
	ReflectionParameters.ShaftResources.Add("InterestDiscount");
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.OtherAssetsLiabilities;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.AssetAndLiabilityItem.Insert("Value", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceInvestmentInRent);
	ReflectionParameters.StructureOfAnalytics.AssetsLiabilitiesDimension.DataPath = "FixedAsset";
	ReflectionParameters.StructureOfAnalytics.Counterparty.DataPath = "Contract.Counterparty";
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
//
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.InvestmentInRent.Name;
	NameOfChangeTable = "ChangesTableInvestmentInRent"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
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
	|	ValueAllowed(Organization)";

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
	
	If Not DataForRegisteringTasks = Undefined Then
		Return DataForRegisteringTasks;
	EndIf;
	
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	
	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
