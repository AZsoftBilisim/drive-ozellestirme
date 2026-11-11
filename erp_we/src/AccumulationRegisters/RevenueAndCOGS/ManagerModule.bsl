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
	
	ReflectionParameters.DataPathConfigurationObject =
		FinancialAccountingByBalanceSheetRegisterData.HFCProductSampleField(ReflectionParameters.DataSourceAlias);
	ReflectionParameters.DataPathAccountingLocation = "Department";
	ReflectionParameters.PathToDataLineOfBusiness = "CounterpartyLineOfBusiness";
	ReflectionParameters.PathToDataDivision = "Department";
	ReflectionParameters.ManResources.Add("RevenueAmount");
	ReflectionParameters.ManResources.Add("RevenueAmountExcludingVAT");
	ReflectionParameters.ManResources.Add("CostMan");
	ReflectionParameters.ManResources.Add("AddExpensesMan");
	ReflectionParameters.ManResources.Add("LaborCostsMan");
	ReflectionParameters.ManResources.Add("ItemizedFixedCostsManag");
	ReflectionParameters.ManResources.Add("ItemizedVariableCostsManag");
	ReflectionParameters.ManResources.Add("SellingExpensesMan");
	ReflectionParameters.ManResources.Add("ProvisionForImpairmentMan");
	ReflectionParameters.ManResources.Add("ExciseAmountInCurrencyMgmt");
	ReflectionParameters.LocalResources.Add("RevenueAmountIncludingVATLocal");
	ReflectionParameters.LocalResources.Add("RevenueAmountExclVATLocal");
	ReflectionParameters.LocalResources.Add("LocalCost");
	ReflectionParameters.LocalResources.Add("AddExpensesLocal");
	ReflectionParameters.LocalResources.Add("LaborCostsLocal");
	ReflectionParameters.LocalResources.Add("ItemizedFixedCostsCompl");
	ReflectionParameters.LocalResources.Add("ItemizedVariableCostsCompl");
	ReflectionParameters.LocalResources.Add("SellingExpensesLocal");
	ReflectionParameters.LocalResources.Add("ProvisionForImpairmentLocal");
	ReflectionParameters.LocalResources.Add("ExciseAmountInCurrencyLocal");
	ReflectionParameters.ResourcesQuantity.Add("Count");
	ReflectionParameters.ContainsUnbalancedData = True;
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Products;
	ReflectionParameters.DataPathDopSettingUpHouseholdOfOperation = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.WriteOffOfVariancesToCostOfGoodsSold)
		|		WHEN DataSourceAlias.Recorder REFS Document.SaleAdjustment
		|			THEN CASE
		|				WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
		|				WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReturnViaCommissionAgentOfPreviousPeriods)
		|				WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.ReverseOfSale)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
		|				ELSE DataSourceAlias.BusinessTransactionSetting
		|			END
		|		WHEN DataSourceAlias.Recorder REFS Document.PurchaseAdjustment
		|			AND CAST(DataSourceAlias.Recorder AS Document.PurchaseAdjustment).AdjustingEntryType <> VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.DebitNoteForPreviousPeriod)
		|		WHEN DataSourceAlias.Recorder REFS Document.ConsignmentReportFromCustomer
		|			THEN CASE
		|				WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|					AND (DataSourceAlias.SellingExpensesMan <> 0 OR DataSourceAlias.SellingExpensesLocal <> 0)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.AccountSalesFromCommissionAgentCommissionFee)
		|				ELSE DataSourceAlias.BusinessTransactionSetting
		|			END
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

// Determines the sources to clarify the account is available in the register and their properties.
//
//
// Parameters:
//  SourceProperties - String - "Field name" - the name of the attribute of the accumulation register, from which you plan to get the source
//                               of account refinement.
//
// Returns:
//  Map - The key is the name of the source of the invoice refinement. 
//                 Value - the structure of the properties of the invoice refinement source.
//
Function SourcesOfInvoiceRefinement(SourceProperties) Export
	
	SourcesOfInvoiceRefinement = New Map;
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfProducts,
		New Structure(SourceProperties, "HFCProducts"));
		
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfARAP,
		New Structure(SourceProperties, "HFCCalculations"));
		
	Return SourcesOfInvoiceRefinement;
	
EndFunction

// Defines the sources of register divisions and their properties.
//
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDivisions() Export

	SourcesOfDivisions = New Map;
	
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.BusinessOperation, "Department");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.ItemsLocationAttributes, "WarehouseDivision");
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.OrderDocument, "OrderDivision");

	Return SourcesOfDivisions;

EndFunction

// Defines the sources of register directions and their properties.
//
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDirections() Export

	Result = New Map;
	
	SourcesOfDirections = Enums.SourceOfLinesOfBusinessOfAnalyticalRegister;
	Result.Insert(SourcesOfDirections.CounterpartyLineOfBusiness, "CounterpartyLineOfBusiness");
	Result.Insert(SourcesOfDirections.ProductLineOfBusiness, "ProductLineOfBusiness");

	Return Result;

EndFunction

// Defines the sources of sub-content filling.
//
//
// Returns:
//  Array - array of register attributes.
//
Function SourcesOfExtdimension() Export

	ExtDimensionArray = New Array;
	ExtDimensionArray.Add("Products");
	ExtDimensionArray.Add("Characteristic");
	ExtDimensionArray.Add("Warehouse");
	ExtDimensionArray.Add("InventoryType");
	ExtDimensionArray.Add("InventoryOwnerAttribute");
	ExtDimensionArray.Add("Partner");
	ExtDimensionArray.Add("Counterparty");
	ExtDimensionArray.Add("Vendor");
	ExtDimensionArray.Add("Terms");
	ExtDimensionArray.Add("Contract");
	ExtDimensionArray.Add("SalesOrder");
	ExtDimensionArray.Add("HFCProducts");
	ExtDimensionArray.Add("ItemsType");
	ExtDimensionArray.Add("Custodian");

	Return New Structure("ExtDimensionDr, ExtDimensionCr", ExtDimensionArray, ExtDimensionArray);
	
EndFunction

// Identifies indicators in the currency of the register.
//
//
// Parameters:
//  PropertiesOfIndicators - String - "Sourcecurrency" - the currency source for the register indicator.
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function IndicatorsInCurrency(PropertiesOfIndicators) Export

	IndicatorsInCurrency = New Map;
	
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInARAPCurrency, New Structure(PropertiesOfIndicators, "ARAPCurrency"));
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInDocumentCurrency, New Structure(PropertiesOfIndicators, "DocumentCurrency"));
	
	Return IndicatorsInCurrency;

EndFunction

// Identifies indicators in the currency of the register.
//
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function QuantityIndicators() Export

	QuantityIndicators = New Map;
	
	QuantityIndicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Count, "Count");
	
	Return QuantityIndicators;

EndFunction

// Defines register metrics.
//
//
// Parameters:
//  Properties - Structure - containing the keys of the properties of Indicators, properties of Resources.
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function Indicators(Properties) Export

	Indicators = New Map;
	
	PropertiesOfIndicators = Properties.PropertiesOfIndicators;
	ResourceProperties = Properties.ResourceProperties;
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "RevenueAmount", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "RevenueAmountIncludingVATLocal", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountInARAPCurrency", "ARAPCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountInDocumentCurrency", "DocumentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "RevenueAmountExcludingVAT", "CurrencyOfMan"));
    ArrayOfResources.Add(New Structure(ResourceProperties, "RevenueAmountExclVATLocal", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountExcludingVATInARAPCurrency", "ARAPCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountExcludingVATInDocumentCurrency", "DocumentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmount", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmountCompl", "ComplCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AmountOfNDSInCurrencyOfMutualSettlements", "ARAPCurrency"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "NDSAmountInDocumentCurrency", "DocumentCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATAmount, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "CostMan", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "LocalCost", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Cost, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "ManagementCost", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "CostLocal", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Cost_, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "CostExcludingVAT", "CurrencyOfMan"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.CostExcludingVAT, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "CostExcludingVAT_", "CurrencyOfMan"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.CostExcludingVAT_, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "LocalCost", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.LocalCost, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "CostLocal", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.CostLocal, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AddExpensesMan", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "AddExpensesLocal", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditExpenseAmount, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "AdditionalExpensesExcludingVAT", "CurrencyOfMan"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "VATAmountOfAdditionalExpenses", "CurrencyOfMan"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "ProvisionForImpairmentMan", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "ProvisionForImpairmentLocal", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.ProvisionForImpairment, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "SellingExpensesMan", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "SellingExpensesLocal", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountSalesExpenses, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "SellingExpensesExcludingVAT", "CurrencyOfMan"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.TAmountSalesExpensesWithoutVAT, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	Return Indicators;
	
EndFunction

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.RevenueAndCOGS.Name;
	NameOfChangeTable = "ChangesTableRevenueAndCOGS"; 
	
	QueryText =
	"SELECT
	|	Table.Period AS Period,
	|	PartnerAccountingAnalyticsKeys.Organization AS Organization,
	|	&RegisterName AS RegisterName,
	|	&Section AS SectionClosingDates
	|FROM
	|	&NameOfChangeTable AS Table
	|	INNER JOIN
	|		InformationRegister.AccountingDimensionByPartners AS PartnerAccountingAnalyticsKeys
	|	ON
	|		Table.AccountingDimensionByPartners = PartnerAccountingAnalyticsKeys.DimensionKey
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

#EndRegion

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
	|	AND ValueAllowed(T1.Partner)
	|	AND ValueAllowed(T.Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

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

// Defines register indicators
//
// Parameters:
//  ReflectionParameters - See ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Procedure IdentifyIndicators(ReflectionParameters)
	
	// The amount of revenue excluding VAT
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("RevenueAmountExcludingVAT");
	IndicatorReflectionParameters.LocalResources.Add("RevenueAmountExclVATLocal");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	IndicatorReflectionParameters.ExpressionIsDebit = "&ThisIsReverseTransaction";
	IndicatorReflectionParameters.ExpressionIsLoan = "NOT &ThisIsReverseTransaction";
	IndicatorReflectionParameters.DataPathRecordFinID = StrReplace(
			"CASE
			|		WHEN DataSourceAlias.SourceOfARAPFinancialAccountingGroup <> VALUE(Catalog.ARAPObjects.EmptyRef)
			|			THEN DataSourceAlias.SourceOfARAPFinancialAccountingGroup.UUID
			|		ELSE DataSourceAlias.FinRecordID
			|	END",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
	IndicatorReflectionParameters.DataPathRowId = "FinRecordID";
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name);
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountExcludingVAT, IndicatorReflectionParameters);
	
	// Cost
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("CostMan");
	IndicatorReflectionParameters.LocalResources.Add("LocalCost");
	IndicatorReflectionParameters.ExpressionIsDebit = "NOT &ThisIsReverseTransaction";
	IndicatorReflectionParameters.ExpressionIsLoan = "&ThisIsReverseTransaction";
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.InventoryCost.Name);
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.GoodsCostVariances.Name);
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Cost, IndicatorReflectionParameters);
	
	// Cost excl.VAT
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("CostExcludingVAT");
	IndicatorReflectionParameters.LocalResources.Add("0");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	IndicatorReflectionParameters.ExpressionIsDebit = "NOT &ThisIsReverseTransaction";
	IndicatorReflectionParameters.ExpressionIsLoan = "&ThisIsReverseTransaction";
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.CostExcludingVAT, IndicatorReflectionParameters);
	
	// Cost VAT
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("Cost");
	IndicatorReflectionParameters.ManResources.Add("-CostExcludingVAT");
	IndicatorReflectionParameters.LocalResources.Add("0");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	IndicatorReflectionParameters.ExpressionIsDebit = "NOT &ThisIsReverseTransaction";
	IndicatorReflectionParameters.ExpressionIsLoan = "&ThisIsReverseTransaction";
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATCostAmount, IndicatorReflectionParameters);
	
	// Additional expenses Amount
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("AddExpensesMan");
	IndicatorReflectionParameters.ManResources.Add("LaborCostsMan");
	IndicatorReflectionParameters.ManResources.Add("ItemizedFixedCostsManag");
	IndicatorReflectionParameters.ManResources.Add("ItemizedVariableCostsManag");
	IndicatorReflectionParameters.ManResources.Add("ExciseAmountInCurrencyMgmt");
	IndicatorReflectionParameters.LocalResources.Add("AddExpensesLocal");
	IndicatorReflectionParameters.LocalResources.Add("LaborCostsLocal");
	IndicatorReflectionParameters.LocalResources.Add("ItemizedFixedCostsCompl");
	IndicatorReflectionParameters.LocalResources.Add("ItemizedVariableCostsCompl");
	IndicatorReflectionParameters.LocalResources.Add("ExciseAmountInCurrencyLocal");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	IndicatorReflectionParameters.ExpressionIsDebit = "NOT &ThisIsReverseTransaction";
	IndicatorReflectionParameters.ExpressionIsLoan = "&ThisIsReverseTransaction";
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.InventoryCost.Name);
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.RegisterRecordsByExcises.Name);
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.GoodsCostVariances.Name);
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditExpenseAmount, IndicatorReflectionParameters);
	
	// Additional expensed amount excluding VAT
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("AdditionalExpensesExcludingVAT");
	IndicatorReflectionParameters.ManResources.Add("LaborCosts");
	IndicatorReflectionParameters.ManResources.Add("ItemizedFixedCostsExcludingVAT");
	IndicatorReflectionParameters.ManResources.Add("ItemizedVariableCostsExcludingVAT");
	IndicatorReflectionParameters.LocalResources.Add("0");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	IndicatorReflectionParameters.ExpressionIsDebit = "NOT &ThisIsReverseTransaction";
	IndicatorReflectionParameters.ExpressionIsLoan = "&ThisIsReverseTransaction";
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT, IndicatorReflectionParameters);
	
	// VAT amount of the Additional expense amount
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("AddExpensesForGoods");
	IndicatorReflectionParameters.ManResources.Add("ItemizedFixedCostsIncludingVAT");
	IndicatorReflectionParameters.ManResources.Add("ItemizedVariableCostsIncludingVAT");
	IndicatorReflectionParameters.ManResources.Add("-AdditionalExpensesExcludingVAT");
	IndicatorReflectionParameters.ManResources.Add("-ItemizedFixedCostsExcludingVAT");
	IndicatorReflectionParameters.ManResources.Add("-ItemizedVariableCostsExcludingVAT");
	IndicatorReflectionParameters.LocalResources.Add("0");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	IndicatorReflectionParameters.ExpressionIsDebit = "NOT &ThisIsReverseTransaction";
	IndicatorReflectionParameters.ExpressionIsLoan = "&ThisIsReverseTransaction";
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense, IndicatorReflectionParameters);
	
	// Reserve for impairment
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("ProvisionForImpairmentMan");
	IndicatorReflectionParameters.LocalResources.Add("ProvisionForImpairmentLocal");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	IndicatorReflectionParameters.ExpressionIsDebit = "NOT &ThisIsReverseTransaction";
	IndicatorReflectionParameters.ExpressionIsLoan = "&ThisIsReverseTransaction";
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.InventoryCost.Name);
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.ProvisionForImpairment, IndicatorReflectionParameters);
	
	// Selling Expenses
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("SellingExpensesMan");
	IndicatorReflectionParameters.LocalResources.Add("SellingExpensesLocal");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	IndicatorReflectionParameters.ExpressionIsDebit = "NOT &ThisIsReverseTransaction";
	IndicatorReflectionParameters.ExpressionIsLoan = "&ThisIsReverseTransaction";
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Name);
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.OtherExpenses.Name);
	IndicatorReflectionParameters.CorDataSources.Add(Metadata.AccumulationRegisters.VATInvoiced.Name);
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountSalesExpenses, IndicatorReflectionParameters);
	
EndProcedure

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.RevenueAndCOGS.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.49";
	Handler.ExecutionMode = "Deferred";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Id = New UUID("e467bbda-d110-42a4-8d52-c96c4dd0688e");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.RevenueAndCOGS.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("ru = 'Заполняет реквизит ""Ставка НДС"".';
							|vi = 'Fills in the ""VAT rate"" attribute.';
							|en = 'Fills in the ""VAT rate"" attribute.'; fa = 'Fills in the ""VAT rate"" attribute.';
							|it = 'Fills in the ""VAT rate"" attribute.';
							|pl = 'Fills in the ""VAT rate"" attribute.';
							|tr = '""KDV oranı"" özniteliğini doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.RevenueAndCOGS.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.DocumentAmountsInAccountingCurrency.FullName());

	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");

	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.RevenueAndCOGS.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName	= "AccumulationRegister.RevenueAndCOGS";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.Text =    
	"SELECT DISTINCT
	|	RevenueAndCOGS.Recorder AS Ref
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|		INNER JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
	|		ON RevenueAndCOGS.Recorder = DocumentAmountsInAccountingCurrency.Recorder
	|			AND RevenueAndCOGS.FinRecordID = DocumentAmountsInAccountingCurrency.RowID
	|WHERE
	|	NOT RevenueAndCOGS.VATRate = DocumentAmountsInAccountingCurrency.VATRate
	|	AND RevenueAndCOGS.VATRate = VALUE(Catalog.VATRates.EmptyRef)";
	
	Recorders = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure
                                                                                                 
// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = Metadata.AccumulationRegisters.RevenueAndCOGS.FullName();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsRegisterRecords = True;
	AdditionalParameters.FullRegisterName = FullRegisterName;

	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	DocumentAmountsInAccountingCurrency.Recorder AS Recorder,
	|	DocumentAmountsInAccountingCurrency.RowID AS RowID,
	|	DocumentAmountsInAccountingCurrency.VATRate AS VATRate
	|FROM
	|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
	|WHERE
	|	DocumentAmountsInAccountingCurrency.Recorder = &Recorder";      
	
	BadData = New Array;
	ObjectsProcessed = 0;
	For Each String In UpdatedData Do
			
		BeginTransaction();
		
		Try 
			Recorder = String.Recorder;
			ExceptionReason = "Block";
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.RevenueAndCOGS.RecordSet");
			LockItem.SetValue("Recorder", Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			
			LockItem = Block.Add("InformationRegister.DocumentAmountsInAccountingCurrency.RecordSet");
			LockItem.SetValue("Recorder", Recorder);
			LockItem.Mode = DataLockMode.Shared;
			
			Block.Lock();

			Recommendation = NStr("vi = 'Hãy kết chuyển lại chứng từ một cách thủ công.';
									|ru = 'Перепроведите документ вручную.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Перепроведите документ вручную.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
			
			ExceptionReason = "BadData";

			RecordSet = AccumulationRegisters.RevenueAndCOGS.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Recorder);
			RecordSet.Read();
			If RecordSet.Count() > 0 Then
				Query.SetParameter("Recorder", Recorder);
				AmountsInAccountingCurrencies = Query.Execute().Unload();
				AmountsInAccountingCurrencies.Indexes.Add("RowID");
				For Each Record In RecordSet Do
					If ValueIsFilled(Record.VATRate) Then
						Continue;
					EndIf;
					TheStructureOfTheSearch = New Structure("RowID",
												Record.FinRecordID);
					TableRows = AmountsInAccountingCurrencies.FindRows(TheStructureOfTheSearch);
					If TableRows.Count() > 0 Then
						Record.VATRate = TableRows[0].VATRate;
					EndIf;
				EndDo;
			EndIf;

			ExceptionReason = "Record";
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			InfobaseUpdate.MarkProcessingCompletion(Recorder);
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			RollbackTransaction();
		
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Recorder);
			If ExceptionReason = "BadData" Then
				DataProblem = InfobaseUpdateTM.DataProblem(Recorder, Recommendation, ErrorInfo());
				BadData.Add(DataProblem);
			ElsIf ExceptionReason <> "Block" Then
				InfobaseUpdateTM.RecordBadData(BadData, ObjectsProcessed, Parameters,);
				Raise ErrorDescription();
			EndIf;
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed > 0 Then
		RecordBadData(BadData, ObjectsProcessed)
	EndIf;

	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName);
	
EndProcedure

Procedure RecordBadData(BadData, ObjectsProcessed)
	If ObjectsProcessed > 0 Then
		For Each DataProblem In BadData Do
			RepresentationOfTheReference = String(DataProblem.ObjectReference);
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось заполнить реквизиты ""%1"" по причине:
						|%2.
						|%3';
						|vi = 'Cannot fill in the ""%1"" attributes due to:
						|%2.
						|%3';
						|en = 'Cannot fill in the ""%1"" attributes due to:
						|%2.
						|%3'; fa = 'Cannot fill in the ""%1"" attributes due to:
						|%2.
						|%3';
						|it = 'Cannot fill in the ""%1"" attributes due to:
						|%2.
						|%3';
						|pl = 'Cannot fill in the ""%1"" attributes due to:
						|%2.
						|%3';
						|tr = '""%1"" öznitelikleri şu nedenle doldurulamadı:
						|%2.
						|%3'"), 
					RepresentationOfTheReference, ErrorProcessing.DetailErrorDescription(DataProblem.ErrorInfo),
					DataProblem.Recommendation);
			InfobaseUpdate.FileIssueWithData(DataProblem, MessageText);
			InfobaseUpdate.MarkProcessingCompletion(DataProblem.ObjectReference);
		EndDo;
	EndIf;
EndProcedure

#EndRegion 

#EndRegion

#EndIf
