#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.RevenueServicesAndAssets.Name;
	NameOfChangeTable = "ChangesTableRevenueServicesAndAssets"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
	Return StructureOfQueryTexts_

EndFunction

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
EndProcedure

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
	
	ReflectionParameters.DataPathAccountingLocation = "Department";
	ReflectionParameters.DataPathConfigurationObject = "IncomeItem.FinancialAccountingGroup";
	ReflectionParameters.PathToDataLineOfBusiness = "LineOfBusiness";
	ReflectionParameters.PathToDataDivision = "Department";
	ReflectionParameters.ManResources.Add("RevenueExcludingVATManag");
	ReflectionParameters.ManResources.Add("VATManag");
	ReflectionParameters.LocalResources.Add("RevenueExcludingVATLocal");
	ReflectionParameters.LocalResources.Add("VATLocal");
	ReflectionParameters.ResourcesQuantity.Add("Count");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.IncomeExpenses;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.IncomeAndExpenseItem.DataPath = "IncomeItem";
	ReflectionParameters.StructureOfAnalytics.DimensionOfExpenses.Insert("Value", Undefined);
	ReflectionParameters.DataPathDopSettingUpHouseholdOfOperation = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.Recorder REFS Document.SaleAdjustment
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccountsReceivableAdjustmentWithRecognionOfOtherIncome)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.OtherServicesSale)
		|		ELSE DataSourceAlias.BusinessTransactionSetting
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	IdentifyIndicators(ReflectionParameters);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion	

#EndRegion

#Region Private

// Defines register indicators
//
// Parameters:
//  ReflectionParameters - See ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Procedure IdentifyIndicators(ReflectionParameters)
	
	// The amount of revenue excluding VAT
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("RevenueExcludingVATManag");
	IndicatorReflectionParameters.LocalResources.Add("RevenueExcludingVATLocal");
	IndicatorReflectionParameters.ResourcesQuantity.Add("Count");
	IndicatorReflectionParameters.ExpressionIsDebit = "&ThisIsReverseTransaction";
	IndicatorReflectionParameters.ExpressionIsLoan = "NOT &ThisIsReverseTransaction";
	IndicatorReflectionParameters.DataPathRecordFinID = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|			THEN DataSourceAlias.ARAPObject.UUID
		|		ELSE DataSourceAlias.FinRecordID
		|	END",
		"DataSourceAlias",
		FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
	IndicatorReflectionParameters.DataPathRowId = "FinRecordID";
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name);
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.FinancialInstrumentsARAP.Name);
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT, IndicatorReflectionParameters);
	
EndProcedure

#EndRegion


#EndIf
