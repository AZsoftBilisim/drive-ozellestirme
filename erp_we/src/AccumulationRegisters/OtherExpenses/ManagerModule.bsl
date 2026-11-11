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
	
	ReflectionParameters.DataPathConfigurationObject = "ExpenseItem.FinancialAccountingGroup";
	ReflectionParameters.DataPathAccountingLocation = "Department";
	ReflectionParameters.PathToDataLineOfBusiness = "LineOfBusiness";
	ReflectionParameters.PathToDataDivision = "Department";
	ReflectionParameters.ManResources.Add("SumMan");
	ReflectionParameters.LocalResources.Add("SumCompl");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.IncomeExpenses;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.IncomeAndExpenseItem.DataPath = "ExpenseItem";
	ReflectionParameters.StructureOfAnalytics.DimensionOfRevenue.Insert("Value", Undefined);
	ReflectionParameters.DataPathDopSettingUpHouseholdOfOperation = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfServices)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromVendorLocal)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfServicesPurchaseAgainstLocal)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.RegisterCCDThroughBroker)
		|			OR DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.RegisterCCDUnassisted)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.ExpensesForCustomsFeesFines)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.OtherCashIssue)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.OtherExpenses)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.ExpensingToProductionLots)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversion)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss)
		|		WHEN DataSourceAlias.Recorder REFS Document.SaleAdjustment
		|			THEN CASE
		|				WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer)
		|					OR DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.ARAPAdjustment)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.AccountsReceivableAdjustmentWithRecognionOfExpenses)
		|				ELSE DataSourceAlias.BusinessTransactionSetting
		|			END
		|		WHEN DataSourceAlias.Recorder REFS Document.AllocationOfOtherCosts
		|			OR DataSourceAlias.Recorder REFS Document.CostCalculationRecorder
		|			THEN CASE
		|				WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.ProductsRelease)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.TransitOfExpensesBetweenCostCenters)
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
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfIncomeExpenses,
		New Structure(SourceProperties, "HFCRevenueExpenditure"));
		
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
	Result.Insert(SourcesOfDirections.LineOfBusiness, "LineOfBusiness");

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
	ExtDimensionArray.Add("ExpenseItem");
	ExtDimensionArray.Add("DimensionOfExpenses");

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
    ArrayOfResources.Add(New Structure(ResourceProperties, "Sum", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "SumCompl", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "Sum", "CurrencyOfMan"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountIncludingVATMan, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	Return Indicators;
	
EndFunction

// Returns the query text with the model structure of the temporary table "Tichodromadidae".
//
// Parameters:
//  AdditionalFields	 - String	 - List of additional fields.
// 
// Returns:
//  String - The text of the request for the formation of a temporary table in the input data.
//
Function TextDescriptionTTInitialOtherExpenses(AdditionalFields = "") Export
	
	QueryText = "
	|SELECT TOP 0
	|	Rows.Period,
	|	Rows.RecordType,
	|	Rows.Organization,
	|	Rows.Department,
	|	Rows.ExpenseItem,
	|	Rows.DimensionOfExpenses,
	|	Rows.LineOfBusiness,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	Rows.BusinessOperation,
	|	Rows.ItemsLocationAttributes,
	|	
	|	Rows.FinRecordID         AS FinRecordID,
	|	Rows.BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|	,&AdditionalFields
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	AccumulationRegister.OtherExpenses AS Rows
	|";
	
	AddAdditionalFieldsToRequestText(AdditionalFields, QueryText);
	
	Return QueryText
	
EndFunction

// Forms the text of the query to build a temporary table of "Unproceeded".
//
// Parameters:
//  AdditionalFields	 - String	 - List of additional fields.
//  DifferentPeriodsInRegisteredRecordsArePossible - Boolean - specifies where the batch accounting parameters are stored, in the query parameters or in the temporary table vtparametersparty accounting for processing
// 
// Returns:
//  String - The text of the request for the formation of a temporary table in the process of spending.
//
Function QueryTextTableTTOtherExpenses_(AdditionalFields = "", DifferentPeriodsInRegisteredRecordsArePossible = False) Export
	
	// The conditions for filling in register resources are similar to the conditions in the function of the textspelling of expenditures, the selection of goods, the register, and the expenses() of the general module of the Batch account22
	QueryText = "
	|SELECT 
	|	TTInitialOtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	MAX(DocumentsRegistry.Organization) AS Organization
	|
	|INTO TTRegisterOfDocumentsOtherExpenses
	|FROM 
	|	TTInitialOtherExpenses AS TTInitialOtherExpenses
	|		INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			ON TTInitialOtherExpenses.DimensionOfExpenses = DocumentsRegistry.Ref
	|WHERE
	|	(DocumentsRegistry.Ref REFS Document.CustomerInvoiceServices
	|	OR DocumentsRegistry.Ref REFS Document.OBEntry
	|	OR DocumentsRegistry.Ref REFS Document.OBEntryOtherExpenses
	|
	|
	|
	|	OR DocumentsRegistry.Ref REFS Document.MaterialProviderOrder2_5
	|
	|
	|	OR DocumentsRegistry.Ref REFS Document.ProductionOrder2_2
	|
	|
	|	OR DocumentsRegistry.Ref REFS Document.SalesOrder
	|	OR DocumentsRegistry.Ref REFS Document.TransferOrder
	|	OR DocumentsRegistry.Ref REFS Document.ByAssemblyDisassemblyOrder
	|	OR DocumentsRegistry.Ref REFS Document.PurchaseOrder
	|	OR DocumentsRegistry.Ref REFS Document.RequestForReturnOfGoodsFromCustomer
	|	OR DocumentsRegistry.Ref REFS Document.VendorInvoice
	|	OR DocumentsRegistry.Ref REFS Document.CustomerInvoice
	|	OR DocumentsRegistry.Ref REFS Document.CustomerInvoiceServicesAndAssets
	|	OR DocumentsRegistry.Ref REFS Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany
	|	OR DocumentsRegistry.Ref REFS Document.AssemblyFromComponents)
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|
	|GROUP BY
	|	TTInitialOtherExpenses.DimensionOfExpenses
	|;
	|
	|SELECT
	|	Rows.Period AS Period,
	|	Rows.RecordType AS RecordType,
	|	Rows.Organization AS Organization,
	|	Rows.Department AS Department,
	|	Rows.ExpenseItem AS ExpenseItem,
	|	Rows.DimensionOfExpenses AS DimensionOfExpenses,
	|	Rows.VATActivityType AS VATActivityType,
	|	(CASE
	|		WHEN ISNULL(LinesOfBusiness.CostAccounting, FALSE)
	|			THEN Rows.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) END) AS LineOfBusiness,
	|
	|	Rows.AmountIncludingVAT AS Sum,
	// The conditions for the amount excluding VAT must match the conditions in:
	// - See CostCalculationCostAdjustment.AdjustInventoryWriteOffCosts
	// - and called methods. See CostCalculationCostAdjustment.AdjustCostOfRefundsFromPreviousPeriods.
	// - See CostCalculationCostAdjustment.
// -
// in the incoming Register Recorded.
	|	(CASE
	|		WHEN NOT AssetRef.CostAllocationOptionManag IN (
	|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
	|				VALUE(Enum.CostAllocationOptions.OnOtherAssets))
	|			THEN Rows.AmountExcludingVAT
	|		ELSE 0 END) AS AmountExcludingVAT,
	|	(CASE
	|		WHEN NOT &CompanyManagementAccounting AND NOT &ThisIsInputOfResidualsInH_2_4
	|			THEN 0
	|		WHEN Rows.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				AND (AssetRef.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.FromDocument)
	|					OR &SimplifiedTaxationSystem)
	|				AND NOT (&GenerateVATChargedWhenIncludingInCost
	|					OR &WriteOffVATByExpensesThatAreNotRecordedInTA
	|						AND NOT AssetRef.EnteredInTaxAccounting)
	|			THEN Rows.AmountExcludingVATMan + (Rows.AmountIncludingVAT - Rows.AmountExcludingVAT)
	|		ELSE Rows.AmountExcludingVATMan END) AS SumMan,
	// If the field calculation condition changes, then make changes to the rescheduled inventory and other expenditures in the register of other expenditures()
	
	|	(CASE 
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				AND NOT &VNAManagementIsUsed_2_4
	|			THEN 0
	|		WHEN Rows.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				AND (AssetRef.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.FromDocument)
	|					OR &SimplifiedTaxationSystem)
	|				AND NOT (&GenerateVATChargedWhenIncludingInCost
	|					OR &WriteOffVATByExpensesThatAreNotRecordedInTA
	|						AND NOT AssetRef.EnteredInTaxAccounting)
	|				AND NOT &BatchAccountingNotUsed
	|			THEN Rows.AmountIncludingVATCompl
	|		ELSE Rows.AmountExcludingVATCompl END) AS SumCompl,
	|
	|	(CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				AND NOT &VNAManagementIsUsed_2_4
	|			THEN 0
	|
	// In the "Trade Management" configuration, there should not be a permanent difference, because the cost allocation mechanisms
	// in this configuration do not support the distribution of a permanent difference.
	|		WHEN NOT AssetRef.EnteredInTaxAccounting AND (Rows.AmountIncludingVATCompl <> 0 OR Rows.CostTD <> 0) THEN
	|			(CASE WHEN Rows.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				AND (AssetRef.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.FromDocument)
	|					OR &SimplifiedTaxationSystem)
	|				AND NOT (&GenerateVATChargedWhenIncludingInCost
	|					OR &WriteOffVATByExpensesThatAreNotRecordedInTA
	|						AND NOT AssetRef.EnteredInTaxAccounting)
	|				AND NOT &BatchAccountingNotUsed
	|			THEN Rows.AmountIncludingVATCompl
	|			ELSE Rows.AmountExcludingVATCompl END)
	|			- Rows.CostTD
	|		ELSE Rows.PermanentDifference END) AS PermanentDifference,
	|	(CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting THEN 0
	|		ELSE Rows.CostTD END) AS CostTD,
	|	Rows.BusinessOperation,
	|	Rows.ItemsLocationAttributes,
	|
	|	CASE
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Catalog.Companies)
	|		 AND Rows.DimensionOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN Rows.DimensionOfExpenses
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Catalog.CostCenters)
	|			THEN CAST(Rows.DimensionOfExpenses AS Catalog.CostCenters).Organization
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
	|			THEN CAST(Rows.DimensionOfExpenses AS Catalog.ProductionLots).Organization
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Document.CustomerInvoiceIntercompany)
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.CustomerInvoiceIntercompany).CompanyRecipient
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Document.InventoryTransfer)
	|		 AND CAST(Rows.DimensionOfExpenses AS Document.InventoryTransfer).BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.InventoryTransfer).CompanyRecipient
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Document.InventoryTransfer)
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.InventoryTransfer).Organization
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Document.TransferOrder)
	|		 AND CAST(Rows.DimensionOfExpenses AS Document.TransferOrder).BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.TransferOrder).CompanyRecipient
	|		WHEN ISNULL(TTDocumentRegistry.Organization, VALUE(Catalog.Companies.EmptyRef)) 
	|				<> VALUE(Catalog.Companies.EmptyRef)
	|			THEN TTDocumentRegistry.Organization
	|		ELSE Rows.Organization
	|	END AS CompanyRecipient,
	|
	|	Rows.FinRecordID         AS FinRecordID,
	|	Rows.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|	,&AdditionalFields
	|
	|INTO TTOtherExpenses_
	|FROM
	|	TTInitialOtherExpenses AS Rows
	|	INNER JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
	|	ON
	|		AssetRef.Ref = Rows.ExpenseItem
	|
	|	LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
	|		ON LinesOfBusiness.Ref = Rows.LineOfBusiness
	|	LEFT JOIN Constants AS TableOfConstants_ ON TRUE
	|	LEFT JOIN TTRegisterOfDocumentsOtherExpenses AS TTDocumentRegistry
	|		ON Rows.DimensionOfExpenses = TTDocumentRegistry.DimensionOfExpenses
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	Rows.Period AS Period,
	|	Rows.RecordType AS RecordType,
	|	Rows.Organization AS Organization,
	|	Rows.Department AS Department,
	|	CASE
	|		WHEN &WriteOffVATByExpensesThatAreNotRecordedInTA
	|				AND NOT AssetRef.EnteredInTaxAccounting
	|			THEN &ExpenseItemVATWriteOff
	|		ELSE Rows.ExpenseItem 
	|	END AS ExpenseItem,
	|	CASE
	|		WHEN &WriteOffVATByExpensesThatAreNotRecordedInTA
	|				AND NOT AssetRef.EnteredInTaxAccounting
	|			THEN &ExpenseDimensionVATWriteOff
	|		ELSE Rows.DimensionOfExpenses 
	|	END AS DimensionOfExpenses,
	|	Rows.VATActivityType AS VATActivityType,
	|	(CASE
	|		WHEN ISNULL(LinesOfBusiness.CostAccounting, FALSE)
	|			THEN Rows.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) END) AS LineOfBusiness,
	|
	|	0 AS Sum,
	|	0 AS AmountExcludingVAT,
	|	(CASE
	|		WHEN NOT &CompanyManagementAccounting AND NOT &ThisIsInputOfResidualsInH_2_4
	|			THEN 0
	|		WHEN Rows.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				AND AssetRef.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.FromDocument)
	|				AND &GenerateVATChargedWhenIncludingInCost
	|				AND NOT &BatchAccountingNotUsed
	|					OR &WriteOffVATByExpensesThatAreNotRecordedInTA
	|				AND NOT AssetRef.EnteredInTaxAccounting
	|				AND NOT &BatchAccountingNotUsed
	|			THEN (Rows.AmountIncludingVAT - Rows.AmountExcludingVAT)
	|		ELSE 0 END) AS SumMan,
	// If the field calculation condition changes, then make changes to the rescheduled inventory and other expenditures in the register of other expenditures()
	
	|	(CASE 
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				AND NOT &VNAManagementIsUsed_2_4
	|			THEN 0
	|		WHEN Rows.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				AND AssetRef.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.FromDocument)
	|				AND NOT &BatchAccountingNotUsed
	|				AND &GenerateVATChargedWhenIncludingInCost
	|					OR &WriteOffVATByExpensesThatAreNotRecordedInTA
	|				AND NOT AssetRef.EnteredInTaxAccounting
	|				AND NOT &BatchAccountingNotUsed
	|			THEN Rows.AmountIncludingVATCompl - Rows.AmountExcludingVATCompl
	|		ELSE 0 END) AS SumCompl,
	|
	|	(CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				AND NOT &VNAManagementIsUsed_2_4
	|			THEN 0
	|		WHEN NOT AssetRef.EnteredInTaxAccounting AND (Rows.AmountIncludingVATCompl <> 0) THEN
	|			(CASE WHEN Rows.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				AND AssetRef.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.FromDocument)
	|				AND NOT &BatchAccountingNotUsed
	|				AND &GenerateVATChargedWhenIncludingInCost
	|					OR &WriteOffVATByExpensesThatAreNotRecordedInTA
	|				AND NOT AssetRef.EnteredInTaxAccounting
	|				AND NOT &BatchAccountingNotUsed
	|			THEN Rows.AmountIncludingVATCompl - Rows.AmountExcludingVATCompl
	|			ELSE 0 END)
	|		ELSE 0 END) AS PermanentDifference,
	|	0 AS CostTD,
	|	Rows.BusinessOperation,
	|	Rows.ItemsLocationAttributes,
	|
	|	CASE
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Catalog.Companies)
	|		 AND Rows.DimensionOfExpenses <> VALUE(Catalog.Companies.EmptyRef)
	|			THEN Rows.DimensionOfExpenses
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Catalog.CostCenters)
	|			THEN CAST(Rows.DimensionOfExpenses AS Catalog.CostCenters).Organization
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
	|			THEN CAST(Rows.DimensionOfExpenses AS Catalog.ProductionLots).Organization
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Document.CustomerInvoiceIntercompany)
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.CustomerInvoiceIntercompany).CompanyRecipient
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Document.InventoryTransfer)
	|		 AND CAST(Rows.DimensionOfExpenses AS Document.InventoryTransfer).BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.InventoryTransfer).CompanyRecipient
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Document.TransferOrder)
	|		 AND CAST(Rows.DimensionOfExpenses AS Document.TransferOrder).BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.TransferOrder).CompanyRecipient
	|		WHEN ISNULL(TTDocumentRegistry.Organization, VALUE(Catalog.Companies.EmptyRef)) 
	|				<> VALUE(Catalog.Companies.EmptyRef)
	|			THEN TTDocumentRegistry.Organization
	|		ELSE Rows.Organization
	|	END AS CompanyRecipient,
	|
	|	&Id AS FinRecordID,
	|	CASE
	|		WHEN &WriteOffVATByExpensesThatAreNotRecordedInTA
	|				AND NOT AssetRef.EnteredInTaxAccounting
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|	END AS BusinessTransactionSetting
	|
	|	,&AdditionalFields
	|
	|FROM
	|	TTInitialOtherExpenses AS Rows
	|	INNER JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
	|	ON
	|		AssetRef.Ref = Rows.ExpenseItem
	|
	|	LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
	|		ON LinesOfBusiness.Ref = Rows.LineOfBusiness
	|	LEFT JOIN Constants AS TableOfConstants_ ON TRUE
	|	LEFT JOIN TTRegisterOfDocumentsOtherExpenses AS TTDocumentRegistry
	|		ON Rows.DimensionOfExpenses = TTDocumentRegistry.DimensionOfExpenses
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|	AND(&GenerateVATChargedWhenIncludingInCost
	|		AND Rows.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|	OR &WriteOffVATByExpensesThatAreNotRecordedInTA
	|		AND NOT AssetRef.EnteredInTaxAccounting
	|		AND Rows.AmountIncludingVATCompl - Rows.AmountExcludingVATCompl <> 0)
	|";
	
	// If you change the logic for possible different period movements, you can also correct the calculation in the calculation of the costind.Change the text of the query and its costs.
	JoinText = "LEFT JOIN Constants AS TableOfConstants_ ON TRUE";
	
	If Not DifferentPeriodsInRegisteredRecordsArePossible Then
		
		QueryText = StrReplace(QueryText, JoinText, "");
		
	Else
		
		// Batch accounting parameters are stored not in the query parameters, but in the fields of the same name in the temporary table of the Batch Accounting parameters for the audit.
		QueryText = StrReplace(QueryText, JoinText,
			"INNER JOIN TTParametersOfBatchAccountingForConducting AS BatchAccountingParameters
			|	ON BatchAccountingParameters.Period = BEGINOFPERIOD(Rows.Period, MONTH)
			|	 AND BatchAccountingParameters.Organization = Rows.Organization");
		
		ParametersArray = New Array;
		ParametersArray.Add("UseAccountingOfOtherIncomeExpensesInLocalAccounting");
		ParametersArray.Add("UseAccountingOfOtherIncomeExpenses");
		ParametersArray.Add("CompanyManagementAccounting");
		ParametersArray.Add("ThisIsInputOfResidualsInH_2_4");
		ParametersArray.Add("VNAManagementIsUsed_2_4");
		ParametersArray.Add("GenerateVATChargedWhenIncludingInCost");
		ParametersArray.Add("WriteOffVATByExpensesThatAreNotRecordedInTA");
		ParametersArray.Add("ExpenseItemVATWriteOff");
		ParametersArray.Add("ExpenseDimensionVATWriteOff");
		ParametersArray.Add("SimplifiedTaxationSystem");
		
		ParametersArray.Add("BatchAccountingNotUsed");
		
		For Each CurrentParameter In ParametersArray Do
			QueryText = StrReplace(QueryText, "&" + CurrentParameter, "BatchAccountingParameters." + CurrentParameter);
		EndDo;
		
	EndIf;
	
	If StrFind(AdditionalFields, "RowID") <> 0 Then
		QueryText = StrReplace(QueryText, "&Id", "Rows.RowID");
	Else
		QueryText = StrReplace(QueryText, "&Id", "Rows.FinRecordID");
	EndIf;
	
	AddAdditionalFieldsToRequestText(AdditionalFields, QueryText);
	
	Return QueryText;
	
EndFunction

// Generates the request text for generating movements in the "other expenses" register.
//
// Parameters:
//  AdditionalFields	 - String	 - List of additional fields.
//  DifferentPeriodsInRegisteredRecordsArePossible - Boolean - specifies where the batch accounting parameters are stored, in the query parameters or in the temporary table vtparametersparty accounting for processing
// 
// Returns:
//  String - The text of the request for the formation of movements in the register of other expenses.
//
Function QueryTextTableOtherExpenses(AdditionalFields = "", DifferentPeriodsInRegisteredRecordsArePossible = False) Export
	
	QueryTextAITAccountingPolicy = CalculationOfCostLocalization.AITSettingsQueryText("TTOtherExpenses_", 
		"OtherExpenses_QueryTextTableOtherExpenses", 
		Undefined, 
		DifferentPeriodsInRegisteredRecordsArePossible);
	
	QueryTextOtherExpenses = "
	// Formation of a table for writing to the "Other Expenses" register.
	|SELECT
	|	Rows.Period AS Period,
	|	Rows.RecordType AS RecordType,
	|	Rows.Organization AS Organization,
	|	Rows.Department AS Department,
	|	Rows.ExpenseItem AS ExpenseItem,
	|	Rows.DimensionOfExpenses AS DimensionOfExpenses,
	|	CASE 
	|		WHEN ISNULL(LB.CostAccounting, FALSE) THEN
	|			Rows.LineOfBusiness
	|		ELSE
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|
	|	Rows.Sum AS Sum,
	|	Rows.AmountExcludingVAT AS AmountExcludingVAT,
	|	Rows.SumMan AS SumMan,
	|
	|	Rows.SumCompl AS SumCompl,
	|	Rows.PermanentDifference AS PermanentDifference,
	|	Rows.CostTD AS CostTD,
	|	&AITAmount AS AITAmount,
	|
	|	Rows.BusinessOperation,
	|	Rows.ItemsLocationAttributes,
	|
	|	Rows.FinRecordID AS FinRecordID,
	|	Rows.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|	,&AdditionalFields
	|
	|FROM
	|	TTOtherExpenses_ AS Rows
	|	LEFT JOIN Catalog.LinesOfBusiness AS LB
	|		ON LB.Ref = Rows.LineOfBusiness
	|	LEFT JOIN AITAccountingPolicyOtherExpenses AS AITAccountingPolicy
	|		ON Rows.Organization = AITAccountingPolicy.Organization
	|	LEFT JOIN Constants AS TableOfConstants_ ON TRUE
	|WHERE
	|	(Rows.Sum <> 0 OR Rows.AmountExcludingVAT <> 0 OR Rows.SumMan <> 0
	|	OR Rows.SumCompl <> 0 OR Rows.PermanentDifference <> 0 OR Rows.CostTD <> 0
	|	OR &ConditionAmountAIT
	|	)
	|
	// Reversal of expenses in upr. accounting with the source organization.
	|UNION ALL
	|SELECT
	|	Rows.Period AS Period,
	|	Rows.RecordType AS RecordType,
	|	Rows.Organization AS Organization,
	|	Rows.Department AS Department,
	|	Rows.ExpenseItem AS ExpenseItem,
	|	Rows.DimensionOfExpenses AS DimensionOfExpenses,
	|	CASE 
	|		WHEN ISNULL(LB.CostAccounting, FALSE) THEN
	|			Rows.LineOfBusiness
	|		ELSE
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	-Rows.Sum AS Sum,
	|	-Rows.AmountExcludingVAT AS AmountExcludingVAT,
	|	-Rows.SumMan AS SumMan,
	|	0 AS SumCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS AITAmount,
	|
	|	VALUE(Enum.BusinessTransactions.ExpenseReversalInManAccounting) AS BusinessOperation,
	|	Rows.ItemsLocationAttributes,
	|
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	Rows.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|	,&AdditionalFields
	|
	|FROM
	|	TTOtherExpenses_ AS Rows
	|	LEFT JOIN Catalog.LinesOfBusiness AS LB
	|		ON LB.Ref = Rows.LineOfBusiness
	|WHERE
	|	Rows.CompanyRecipient <> Rows.Organization
	|	AND Rows.CompanyRecipient <> VALUE(Catalog.Companies.EmptyRef)
	|	AND (Rows.Sum <> 0 OR Rows.AmountExcludingVAT <> 0 OR Rows.SumMan <> 0)
	|	AND Rows.BusinessOperation <> VALUE(Enum.BusinessTransactions.InternalExpenseReceipt)
	|
	// Registration of expenses in upr. accounting with the recipient organization.
	|UNION ALL
	|SELECT
	|	Rows.Period AS Period,
	|	Rows.RecordType AS RecordType,
	|	Rows.CompanyRecipient AS Organization,
	|	Rows.Department AS Department,
	|	Rows.ExpenseItem AS ExpenseItem,
	|	Rows.DimensionOfExpenses AS DimensionOfExpenses,
	|	CASE 
	|		WHEN ISNULL(LB.CostAccounting, FALSE) THEN
	|			Rows.LineOfBusiness
	|		ELSE
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	Rows.Sum AS Sum,
	|	Rows.AmountExcludingVAT AS AmountExcludingVAT,
	|	0 AS SumMan,
	|	0 AS SumCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS AITAmount,
	|
	|	VALUE(Enum.BusinessTransactions.ExpenseRegistrationInManAccounting) AS BusinessOperation,
	|	Rows.ItemsLocationAttributes,
	|
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	Rows.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|	,&AdditionalFields
	|
	|FROM
	|	TTOtherExpenses_ AS Rows
	|	LEFT JOIN Catalog.LinesOfBusiness AS LB
	|		ON LB.Ref = Rows.LineOfBusiness
	|WHERE
	|	Rows.CompanyRecipient <> Rows.Organization
	|	AND Rows.CompanyRecipient <> VALUE(Catalog.Companies.EmptyRef)
	|	AND (Rows.Sum <> 0 OR Rows.AmountExcludingVAT <> 0 OR Rows.SumMan <> 0)
	|	AND Rows.BusinessOperation <> VALUE(Enum.BusinessTransactions.InternalExpenseReceipt)
	|";
	
	QueryTexts = New Array;
	QueryTexts.Add(QueryTextAITAccountingPolicy);
	QueryTexts.Add(QueryTextOtherExpenses);
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	CalculationOfCostLocalization.ChangeQueryTextOtherExpenses(QueryText, 
		"Rows", 
		AdditionalFields, 
		DifferentPeriodsInRegisteredRecordsArePossible);
	
	QueryText = StrReplace(QueryText, "&AITAmount", "0");
	
	AddAdditionalFieldsToRequestText(AdditionalFields, QueryText);
	
	Return QueryText;
	
EndFunction

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.OtherExpenses.Name;
	NameOfChangeTable = "ChangesTableOtherExpenses"; 
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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)";

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

#Region ProcessingTransitionFromBatchRegisterOfOtherExpensesToRegisterOfOtherExpenses

// The procedure converts the records of the batch register of other expenditures by items of expenditure allocated to the cost
// of goods to the Other Expenses register.
// 
// Parameters:
// 	Recorder - DocumentRef.VendorInvoice - document Registrar
// 	Set - AccumulationRegisterRecordSet.ItemisedExpensesLots - a set of register entries to process
// 	RecordsSelection - QueryResultSelection - record the set with the calculated additional fields
// 
// Returns:
// 	AccumulationRegisterRecordSet.OtherExpenses - a set of new register entries
//
Function TransferDataFromOtherExpensesRegisterToOtherExpensesRegister(Recorder, Set, RecordsSelection) Export
	
	SetOtherExpenses = AccumulationRegisters.OtherExpenses.CreateRecordSet();
	SetOtherExpenses.DataExchange.Load = True;
	SetOtherExpenses.Filter.Recorder.Set(Recorder);
	SetOtherExpenses.Read();
	
	DialLineNumbers = Set.UnloadColumn("LineNumber");
	
	While RecordsSelection.Next() Do
		
		If Not RecordsSelection.TransferEntryToOtherLocalExpenses
			And Not RecordsSelection.TransferRecordToOtherExpensesOfMan Then
			Continue
		EndIf;
		
		RecordOtherExpenses = SetOtherExpenses.Add();
		FillPropertyValues(RecordOtherExpenses, RecordsSelection);

		If RecordsSelection.TransferEntryToOtherLocalExpenses Then
			
			If (RecordsSelection.VATActivityType = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT
				Or RecordsSelection.VATActivityType = Enums.VATTaxationTypes.SaleIsSubjectToUTII)
				And RecordsSelection.SeparateVATAccountingOption = Enums.SeparateVATAccountingOptions.FromDocument Then
				RecordOtherExpenses.SumCompl = RecordsSelection.LocalCost + RecordsSelection.VATLocal;
			Else
				RecordOtherExpenses.SumCompl = RecordsSelection.LocalCost;
			EndIf;
			
		EndIf;
		
		If RecordsSelection.TransferRecordToOtherExpensesOfMan Then
			
			If RecordsSelection.ExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent
			 And RecordsSelection.Cost = 0 Then
			 	RecordOtherExpenses.Sum = ?(RecordsSelection.VATManag <> 0, RecordsSelection.VATManag, RecordsSelection.VATLocal);
			Else
				RecordOtherExpenses.Sum = RecordsSelection.Cost;
			EndIf;
			RecordOtherExpenses.AmountExcludingVAT = RecordsSelection.CostExcludingVAT;
			
			If (RecordsSelection.VATActivityType = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT
				Or RecordsSelection.VATActivityType = Enums.VATTaxationTypes.SaleIsSubjectToUTII)
				And RecordsSelection.SeparateVATAccountingOption = Enums.SeparateVATAccountingOptions.FromDocument Then
				RecordOtherExpenses.SumMan = RecordsSelection.Cost;
			Else
				RecordOtherExpenses.SumMan = RecordsSelection.CostExcludingVAT;
			EndIf;
			
		EndIf;

		If RecordOtherExpenses.Sum = 0
			And RecordOtherExpenses.AmountExcludingVAT = 0
			And RecordOtherExpenses.SumCompl = 0
			And RecordOtherExpenses.SumMan = 0
			And RecordOtherExpenses.PermanentDifference = 0
			And RecordOtherExpenses.CostTD = 0 Then
			SetOtherExpenses.Delete(RecordOtherExpenses);
		EndIf;
		
	EndDo;
	
	Return SetOtherExpenses;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure AddAdditionalFieldsToRequestText(AdditionalFields, QueryText)

	If Not ValueIsFilled(AdditionalFields) Then
		QueryText = StrReplace(QueryText, ",&AdditionalFields", "");
		Return;
	EndIf; 
	
	TextAdditionalFields = "";
	
	FieldList = StrSplit(AdditionalFields, ",");
	For Each FieldName In FieldList Do
		TextAdditionalFields = TextAdditionalFields + "
		|	,Rows." + FieldName;
	EndDo; 
	
	QueryText = StrReplace(QueryText, ",&AdditionalFields", TextAdditionalFields); 

EndProcedure

#EndRegion

#EndIf
