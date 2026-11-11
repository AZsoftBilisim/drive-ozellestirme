#Region Public

#Region CalculationStages


// The stage of "Preparing data for accounting and case_spend"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfDataForAccountingLBSiUSN_AdditionalExpensesAmount(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparationOfDataForAccountingLBSiUSN_AdditionalExpensesAmount");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchDistribution(
		CalculationParameters,
		TableForDistributionOfVATBatches(CalculationParameters),
		DescriptionOfChainsOfVATShipments(CalculationParameters),
		DescriptionOfRegisteredRecordsOfPartiesOfNDS_AdditionalExpensesAmount(CalculationParameters),
		DescriptionOfUnrecordedVATShipments(CalculationParameters));
		
	// 2. Obtaining the initial data for the calculation
	// 	- generates a temporary Data table.
	ToGetDataForBatchesOfNDS_AdditionalExpenseAmount(CalculationParameters);

	
	// 5. Putting the data into the receiver table and clearing the auxiliary temp tables.
	//	- generates a temp table for the details of the product partyreferencesexternal links
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure


// Stage "Party distributionsfifo-sliding"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure DistributionOfPartiesNdsfifoMoving(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "DistributionOfPartiesNdsfifoMoving");
	
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"GoodsReceiptsVAT2_4, TTAdditionalExpenseRatios, CompletelyRetiredGoodsTT, ArrivalsOfGoodsNDS2_4_ForSolvingCase, TTAdjustmentOfPricesOfBalancesOfUnfinishedProduction, PeriodOfPreviousCalculatedPeriod");
		
	InitializeTablesForBalanceEntryDocuments(CalculationParameters);
	
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextPreparationOfVATDistributionData(CalculationParameters));
		
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	DistributeVATAtCost(CalculationParameters, "ArrivalsOfGoodsNDS2_4_ForSolvingCase");
	
	// We will destroy unnecessary temporary tables.
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(
		CalculationParameters,
		ExistingTT + ", GoodsReceiptsVAT2_4, TTAdditionalExpenseRatios, CompletelyRetiredGoodsTT, PeriodOfPreviousCalculatedPeriod");
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
	GenerateValueOfVATLotsAtEndOfPeriod(CalculationParameters, 1);
	
EndProcedure

// The stage of "Party allocation of additional expenses"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure DistributionOfVATLotsAccordingToAdditionalExpenseAmounts(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "DistributionOfVATLotsAccordingToAdditionalExpenseAmounts");
	
	#Region DistributionOfAdditionalExpensesAmountOnDatabase
	
	If ValueIsFilled(CalculationParameters) Then
		ThereIsTableOfAdditionalExpenses = CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters, "TTAdditionalCostsForDistribution");
	Else
		ThereIsTableOfAdditionalExpenses = False;
	EndIf;
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TheseAdditionalExpensesAmountForDistribution, BaseAdditionalExpensesAmountForDistribution,
		|TTAdditionalExpensesAmountForDistributionExtended"
			+ ?(ThereIsTableOfAdditionalExpenses, "", ", TTAdditionalCostsForDistribution"));

	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextForDistributionOfVATBatchesByAdditionalExpenseAMOUNT(CalculationParameters));
		
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	// We will distribute the additional . expenses on the database by the method of reduced Balance
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	// Initializing the distribution
	DistributionParameters = CostCalculationUniversalAlgorithms.InitializeDistributionParametersUsingReducedRemainderMethod(
		"TheseAdditionalExpensesAmountForDistribution",
		"BaseAdditionalExpensesAmountForDistribution",
		"Organization, Department, LineOfBusiness, ExpenseItemAssets, DimensionOfExpenses, LocalAccnting, ThereAreSums");
	DistributionParameters.NegativeBasesArePossible = True;
		
	CostCalculationUniversalAlgorithms.InitializeNumericalDistributionFieldsUsingReducedRemainderMethod(
		DistributionParameters,
		"CostInclVAT, CostExcludingVAT, CostExcludingVATLocal, VATLocal, CostExcludingVATMan, VATManag",
		"Denominator",
		"Denominator");
		
	CostCalculationUniversalAlgorithms.InitializeOtherDistributionFieldsUsingReducedRemainderMethod(
		DistributionParameters,
		"DocumentInflow, LotVendorAttributesOfReceiptDocument, ExpenseItemAssets, DimensionOfExpenses,
			|DimensionVATWriteOff, Department, CorVATActivityTypes, LocalAccnting, ThereAreSums
			|,ProductCostElement, ProductsGroup, RuleOfCostAllocatingToProductionLots
			|",
		"ThisIsReverseTransaction, ReversingEntry, Period, ReceiptPeriod, Recorder, RecordType, Organization, ItemsLocationAttributes, InventoryOwnerAttribute,
			|CorItemsLocationAttributes, CorInventoryOwnerAttribute, Lot, LotVendorAttributes, VATActivityType, LineOfBusiness,
			|ForDisposal, BusinessOperation, CorCompany, CorLot, LotVendorAttributesCorr, CorLineOfBusiness,
			|DimensionOfAssets, CorExpenseItem, CorExpenditureDimension, DebitBusinessUnit,  VATWriteOffItem, AccountingSection, FinancialAccountingDimension, FinRecordID",
		, // DonTIncludeSourceFields
		, // DoNotIncludeDatabaseFields
		"DenominatorForSorting, FinRecordID" // DatabaseSortingFields
		);
		
	// We distribute
	CostCalculationAppliedAlgorithms.DistributeByMethodOfReducedResidueWithTimeMeasurement(
		CalculationParameters,
		DistributionParameters,
		"DistributeUsingReducedRemainderMethod",
		"DistributionOfVATLotsAccordingToAdditionalExpenseAmounts");
		
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, "TheseAdditionalExpensesAmountForDistribution, BaseAdditionalExpensesAmountForDistribution");
	
	#EndRegion

	#Region PreparationOfVATDistributionData
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.SetParameter("ThisIsLocalizedVersion", CalculationParameters.ThisIsLocalizedVersion);
	
	Query.Text =
	"SELECT
	|	T.Organization,
	|	T.VATAccountingOptionOnActivityTypeChange,
	|	T.ExpenseItemVATExempt,
	|	T.ExpenseDimensionVATExempt,
	|	T.ExpenceItemUTII,
	|	T.VATDebitingDimensionBySalesSubjectToUTIIActivityType
	|INTO TTVATAccountingSettingsONChangesInTypeOfActivity
	|FROM
	|	InformationRegister.VATAccountingSettings.SliceLast(&BeginOfPeriod, Organization IN (&CompanyArray)) AS T
	|WHERE
	|	T.VATAccountingOptionOnActivityTypeChange IN
	|		(VALUE(Enum.VATAccountingOptionsOnChangingActivityTypeToNonTaxableOne.IncludeInOtherExpenses),
	|		 VALUE(Enum.VATAccountingOptionsOnChangingActivityTypeToNonTaxableOne.IncludeCostOrCostDependingOnPeriod))
	|	AND NOT &ThisIsLocalizedVersion
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization,
	|	T.Department,
	|	T.LineOfBusiness,
	|	T.ExpenseItemAssets,
	|	T.DimensionOfExpenses,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.ProductCostElement,
	|	T.ProductsGroup,
	|	T.RuleOfCostAllocatingToProductionLots,
	|	T.ThisIsReverseTransaction,
	|	T.ReversingEntry,
	|	T.Period,
	|	T.ReceiptPeriod,
	|	T.Recorder,
	|	T.RecordType,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.AccountingSection,
	|	T.FinancialAccountingDimension,
	|	T.ForDisposal,
	|	T.BusinessOperation,
	|	T.CorVATActivityTypes,
	|	T.CorCompany,
	|	T.CorLot,
	|	T.LotVendorAttributesCorr,
	|	T.CorLineOfBusiness,
	|	T.DimensionOfAssets,
	|	T.CorExpenseItem,
	|	T.CorExpenditureDimension,
	|	T.DebitBusinessUnit,
	|	CASE
	|		WHEN VATSettings.VATAccountingOptionOnActivityTypeChange IS NULL
	|			THEN T.VATWriteOffItem
	|		WHEN VATSettings.VATAccountingOptionOnActivityTypeChange = VALUE(Enum.VATAccountingOptionsOnChangingActivityTypeToNonTaxableOne.IncludeInOtherExpenses)
	|			THEN
	|				CASE
	|					WHEN T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|					  AND T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|						THEN CASE WHEN T.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|								THEN VATSettings.ExpenseItemVATExempt
	|								ELSE VATSettings.ExpenceItemUTII
	|							END
	|						ELSE T.VATWriteOffItem
	|				END
	|			ELSE
	|				CASE
	|					WHEN ISNULL(Register3.IBDocumentDate, &BeginOfPeriod) < &BeginOfPeriod
	|					  AND T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|					  AND T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|						THEN CASE WHEN T.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|								THEN VATSettings.ExpenseItemVATExempt
	|								ELSE VATSettings.ExpenceItemUTII
	|							END
	|						ELSE T.VATWriteOffItem
	|				END
	|	END AS VATWriteOffItem,
	|	CASE
	|		WHEN VATSettings.VATAccountingOptionOnActivityTypeChange IS NULL
	|			THEN T.DimensionVATWriteOff
	|		WHEN VATSettings.VATAccountingOptionOnActivityTypeChange = VALUE(Enum.VATAccountingOptionsOnChangingActivityTypeToNonTaxableOne.IncludeInOtherExpenses)
	|			THEN
	|				CASE
	|					WHEN T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|					  AND T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|						THEN CASE WHEN T.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|								THEN VATSettings.ExpenseDimensionVATExempt
	|								ELSE VATSettings.VATDebitingDimensionBySalesSubjectToUTIIActivityType
	|							END
	|						ELSE T.DimensionVATWriteOff
	|				END
	|			ELSE
	|				CASE
	|					WHEN ISNULL(Register3.IBDocumentDate, &BeginOfPeriod) < &BeginOfPeriod
	|					  AND T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|					  AND T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|						THEN CASE WHEN T.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|								THEN VATSettings.ExpenseDimensionVATExempt
	|								ELSE VATSettings.VATDebitingDimensionBySalesSubjectToUTIIActivityType
	|							END
	|						ELSE T.DimensionVATWriteOff
	|				END
	|	END AS DimensionVATWriteOff,
	|	T.FinRecordID,
	|	VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified) AS EntryType,
	|	UNDEFINED AS DocumentSource,
	|
	|	T.CostInclVAT,
	|	T.CostExcludingVAT,
	|	T.CostExcludingVATLocal,
	|	T.CostExcludingVATMan,
	|
	|	CASE
	|		WHEN VATSettings.VATAccountingOptionOnActivityTypeChange IS NULL
	|			THEN T.VATLocal
	|		WHEN VATSettings.VATAccountingOptionOnActivityTypeChange = VALUE(Enum.VATAccountingOptionsOnChangingActivityTypeToNonTaxableOne.IncludeInOtherExpenses)
	|			THEN
	|				CASE
	|					WHEN T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|					  AND T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|						THEN 0
	|						ELSE T.VATLocal
	|				END
	|			ELSE
	|				CASE
	|					WHEN ISNULL(Register3.IBDocumentDate, &BeginOfPeriod) < &BeginOfPeriod
	|					  AND T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|					  AND T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|						THEN 0
	|						ELSE T.VATLocal
	|				END
	|	END AS VATLocal,
	|	CASE
	|		WHEN VATSettings.VATAccountingOptionOnActivityTypeChange IS NULL
	|			THEN T.VATManag
	|		WHEN VATSettings.VATAccountingOptionOnActivityTypeChange = VALUE(Enum.VATAccountingOptionsOnChangingActivityTypeToNonTaxableOne.IncludeInOtherExpenses)
	|			THEN
	|				CASE
	|					WHEN T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|					  AND T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|						THEN 0
	|						ELSE T.VATManag
	|				END
	|			ELSE
	|				CASE
	|					WHEN ISNULL(Register3.IBDocumentDate, &BeginOfPeriod) < &BeginOfPeriod
	|					  AND T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|					  AND T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|						THEN 0
	|						ELSE T.VATManag
	|				END
	|	END AS VATManag
	|INTO TTAdditionalCostsForItemByItemCosts
	|FROM
	|	TTDistributionResult AS T
	|	LEFT JOIN TTVATAccountingSettingsONChangesInTypeOfActivity AS VATSettings
	|		ON T.Organization = VATSettings.Organization
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Register3.Ref = T.DocumentInflow
	|		AND NOT Register3.AdditionalRecord
	|		AND Register3.Ref <> UNDEFINED
	|		AND NOT &ThisIsLocalizedVersion
	|WHERE
	|	T.CostInclVAT <> 0
	|		OR T.CostExcludingVAT <> 0
	|		OR T.CostExcludingVATLocal <> 0
	|		OR T.VATLocal <> 0
	|		OR T.CostExcludingVATMan <> 0
	|		OR T.VATManag <> 0
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder,
	// VAT Batch Analysts
	|	T.ItemsLocationAttributes AS InventoryLocationAttributesOfReceiptDocument,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	// Cost Analysts
	|	T.Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	// Other fields
	|	T.ExpenseItemAssets AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|
	// Resources
	|	SUM(CAST(ISNULL(Coefficients.ZoomRatio, 1) * T.CostInclVAT AS NUMBER(31,2))) AS CostInclVAT,
	|	SUM(CAST(ISNULL(Coefficients.ZoomRatio, 1) * T.CostExcludingVAT AS NUMBER(31,2))) AS CostExcludingVAT,
	|	SUM(CAST(ISNULL(Coefficients.ZoomRatio, 1) * T.CostExcludingVATLocal AS NUMBER(31,2))) AS CostExcludingVATLocal,
	|	SUM(CAST(ISNULL(Coefficients.ZoomRatio, 1) * 
	|		CASE WHEN T.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0 
	|		ELSE T.VATLocal END AS NUMBER(31,2))) AS VATLocal,
	|	SUM(CAST(ISNULL(Coefficients.ZoomRatio, 1) * T.CostExcludingVATMan AS NUMBER(31,2))) AS CostExcludingVATMan,
	|	SUM(CAST(ISNULL(Coefficients.ZoomRatio, 1) * 
	|		CASE WHEN T.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|		ELSE T.VATManag END AS NUMBER(31,2))) AS VATManag,
	|
	|	ISNULL(Retirements.FullDisposal, FALSE) AND ISNULL(Coefficients.ZoomRatio, 1) = 0 AS FullDisposal,
	|	ISNULL(Retirements.Count, 0) AS Count,
	|	SUM(CASE WHEN ISNULL(Retirements.FullDisposal, FALSE) AND ISNULL(Retirements.Count, 0) <> 0
	|			THEN CAST(T.CostInclVAT / Retirements.Count AS NUMBER (28, 10))
	|			ELSE 0
	|		  END) AS RetirementCostWithVAT,
	|	SUM(CASE WHEN ISNULL(Retirements.FullDisposal, FALSE) AND ISNULL(Retirements.Count, 0) <> 0
	|			THEN CAST(T.CostExcludingVAT / Retirements.Count AS NUMBER (28, 10))
	|			ELSE 0
	|		  END) AS RetirementCostExclVAT,
	|	SUM(CASE WHEN ISNULL(Retirements.FullDisposal, FALSE) AND ISNULL(Retirements.Count, 0) <> 0
	|			THEN CAST(T.CostExcludingVATLocal / Retirements.Count AS NUMBER (28, 10))
	|			ELSE 0
	|		  END) AS RetirementCostExclVATLocal,
	|	SUM(CASE WHEN ISNULL(Retirements.FullDisposal, FALSE) AND ISNULL(Retirements.Count, 0) <> 0
	|		  AND T.VATActivityType <> VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN CAST(T.VATLocal / Retirements.Count AS NUMBER (28, 10))
	|			ELSE 0
	|		  END) AS RetirementOfVATLocal,
	|	SUM(CASE WHEN ISNULL(Retirements.FullDisposal, FALSE) AND ISNULL(Retirements.Count, 0) <> 0
	|			THEN CAST(T.CostExcludingVATMan / Retirements.Count AS NUMBER (28, 10))
	|			ELSE 0
	|		  END) AS RetirementCostExclVATMan,
	|	SUM(CASE WHEN ISNULL(Retirements.FullDisposal, FALSE) AND ISNULL(Retirements.Count, 0) <> 0
	|		  AND T.VATActivityType <> VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN CAST(T.VATManag / Retirements.Count AS NUMBER (28, 10))
	|			ELSE 0
	|		  END) AS RetirementOfVATMan
	|INTO TTAdditionalExpensesVAT2_4
	|FROM
	|	TTAdditionalCostsForItemByItemCosts AS T
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Filter
	|		ON T.ItemsLocationAttributes = Filter.Ref
	|	LEFT JOIN TTAdditionalExpenseRatios AS Coefficients
	|		ON T.Organization = Coefficients.Organization
	|		AND T.AccountingSection = Coefficients.AccountingSection
	|		AND T.ItemsLocationAttributes = Coefficients.ItemsLocationAttributes
	|		AND T.InventoryOwnerAttribute = Coefficients.InventoryOwnerAttribute
	|		AND T.Lot = Coefficients.Lot
	|		AND T.LotVendorAttributes = Coefficients.LotVendorAttributes
	|		AND T.VATActivityType = Coefficients.VATActivityType
	|		AND T.FinancialAccountingDimension = Coefficients.FinancialAccountingDimension
	|		AND T.Recorder = Coefficients.Recorder
	|	LEFT JOIN CompletelyRetiredGoodsTT AS Retirements
	|		ON T.Organization = Retirements.Organization
	|		AND T.AccountingSection = Retirements.AccountingSection
	|		AND T.ItemsLocationAttributes = Retirements.ItemsLocationAttributes
	|		AND T.InventoryOwnerAttribute = Retirements.InventoryOwnerAttribute
	|		AND T.Lot = Retirements.Lot
	|		AND T.LotVendorAttributes = Retirements.LotVendorAttributes
	|		AND T.VATActivityType = Retirements.VATActivityType
	|		AND T.FinancialAccountingDimension = Retirements.FinancialAccountingDimension
	|		AND T.Recorder = Retirements.Recorder
	|WHERE
	|	T.EntryType IN (VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified))
	|	AND T.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|GROUP BY
	|	T.Recorder,
	|	T.Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	|	T.ExpenseItemAssets,
	|	T.DimensionOfExpenses,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	ISNULL(Retirements.FullDisposal, FALSE) AND ISNULL(Coefficients.ZoomRatio, 1) = 0,
	|	ISNULL(Retirements.Count, 0)
	|
	|INDEX BY
	|	FullDisposal,
	|	Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	// If additional . expenses relate to the batch of the previous period, then these are variable add-ons. expenses
	|	CASE
	|		WHEN ISNULL(PartyRegistry.IBDocumentDate, &EndOfPreviousPeriod) < &BeginOfPeriod
	|			THEN TRUE
	|			ELSE FALSE
	|	END AS TheseAreVariableAdditionalCosts,
	// VAT Batch Analysts
	|	DD.InventoryLocationAttributesOfReceiptDocument,
	|	CASE WHEN VALUETYPE(DD.DocumentInflow) IN (&TypesOfBatchDocuments)
	|		THEN DD.DocumentInflow
	|		ELSE UNDEFINED
	|	END AS DocumentInflow,
	|	CASE WHEN VALUETYPE(DD.DocumentInflow) IN (&TypesOfBatchDocuments)
	|		THEN DD.LotVendorAttributesOfReceiptDocument
	|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|	END AS LotVendorAttributesOfReceiptDocument,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	
	// Cost Analysts
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Resources
	|	SUM(DD.CostInclVAT) AS CostInclVAT,
	|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(DD.CostExcludingVATLocal) AS CostExcludingVATLocal,
	|	SUM(DD.VATLocal) AS VATLocal,
	|	SUM(DD.CostExcludingVATMan) AS CostExcludingVATMan,
	|	SUM(DD.VATManag) AS VATManag
	|INTO ReceiptsOfAdditionalExpensesAmountOfNDS2_4_ToSolveCasePreliminary
	|FROM
	|	TTAdditionalExpensesVAT2_4 AS DD
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS PartyRegistry
	|		ON PartyRegistry.Ref = DD.Lot
	|		AND NOT PartyRegistry.AdditionalRecord
	|		AND PartyRegistry.Ref <> UNDEFINED
	|WHERE
	|	NOT DD.FullDisposal
	|GROUP BY
	|	CASE
	|		WHEN ISNULL(PartyRegistry.IBDocumentDate, &EndOfPreviousPeriod) < &BeginOfPeriod
	|			THEN TRUE
	|			ELSE FALSE
	|	END,
	|	DD.InventoryLocationAttributesOfReceiptDocument,
	|	CASE WHEN VALUETYPE(DD.DocumentInflow) IN (&TypesOfBatchDocuments)
	|		THEN DD.DocumentInflow
	|		ELSE UNDEFINED
	|	END,
	|	CASE WHEN VALUETYPE(DD.DocumentInflow) IN (&TypesOfBatchDocuments)
	|		THEN DD.LotVendorAttributesOfReceiptDocument
	|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|	END,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALSE AS TheseAreLeftovers,
	|	FALSE AS TheseAreRemainingArticleByArticleVariables,
	|	FALSE AS TheseRemaindersAreArticleByArticleConstants,
	// VAT Batch Analysts
	|	DD.InventoryLocationAttributesOfReceiptDocument,
	|	DD.DocumentInflow,
	|	DD.LotVendorAttributesOfReceiptDocument,
	|	FALSE AS PreviousRedistributionCosts,
	|	TRUE AS ThisIsAdditionalExpense,
	|	DD.TheseAreVariableAdditionalCosts AS TheseAreVariableAdditionalCosts,
	|	
	// Cost Analysts
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Other fields
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|
	// Resources
	|	CASE WHEN DD.CostInclVAT < 0 THEN -1 ELSE 1 END AS SignCostWithVAT,
	|	CASE WHEN DD.CostExcludingVAT < 0 THEN -1 ELSE 1 END AS SignCostWithoutVAT,
	|	CASE WHEN DD.CostExcludingVATLocal < 0 THEN -1 ELSE 1 END AS SignValueWithoutVATLocal,
	|	CASE WHEN DD.VATLocal < 0 THEN -1 ELSE 1 END AS LocalVATSign,
	|	CASE WHEN DD.CostExcludingVATMan < 0 THEN -1 ELSE 1 END AS SignCostWithoutVATMan,
	|	CASE WHEN DD.VATManag < 0 THEN -1 ELSE 1 END AS VATSignMan,
	|
	|	CASE WHEN DD.CostInclVAT < 0 THEN -DD.CostInclVAT ELSE DD.CostInclVAT END AS CostInclVAT,
	|	CASE WHEN DD.CostExcludingVAT < 0 THEN -DD.CostExcludingVAT ELSE DD.CostExcludingVAT END AS CostExcludingVAT,
	|	CASE WHEN DD.CostExcludingVATLocal < 0 THEN -DD.CostExcludingVATLocal ELSE DD.CostExcludingVATLocal END AS CostExcludingVATLocal,
	|	CASE WHEN DD.VATLocal < 0 THEN -DD.VATLocal ELSE DD.VATLocal END AS VATLocal,
	|	CASE WHEN DD.CostExcludingVATMan < 0 THEN -DD.CostExcludingVATMan ELSE DD.CostExcludingVATMan END AS CostExcludingVATMan,
	|	CASE WHEN DD.VATManag < 0 THEN -DD.VATManag ELSE DD.VATManag END AS VATManag
	|INTO ReceiptsOfAdditionalExpensesVAT2_4_ToSolveLinearSystems
	|FROM
	|	ReceiptsOfAdditionalExpensesAmountOfNDS2_4_ToSolveCasePreliminary AS DD
	|WHERE
	|	DD.CostInclVAT <> 0
	|	OR DD.CostExcludingVAT <> 0
	|	OR DD.CostExcludingVATLocal <> 0
	|	OR DD.VATLocal <> 0
	|	OR DD.CostExcludingVATMan <> 0
	|	OR DD.VATManag <> 0
	|
	// Indexes must correspond to the property of the index register from the description of the cost register
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ReceiptsOfAdditionalExpensesAmountOfNDS2_4_ToSolveCasePreliminary
	|";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	#EndRegion
	
	DistributeVATAtCost(CalculationParameters, "ReceiptsOfAdditionalExpensesVAT2_4_ToSolveLinearSystems");
	
	If Not CostCalculationAppliedAlgorithms.EmptyTempTable(CalculationParameters, "ReceiptsOfAdditionalExpensesVAT2_4_ToSolveLinearSystems") Then
		GenerateValueOfVATLotsAtEndOfPeriod(CalculationParameters, 2);
	EndIf;
	
	// We will destroy unnecessary temporary tables.
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(
		CalculationParameters,
		ExistingTT + ", TTAdditionalCostsForItemByItemCosts");
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
	If CalculationParameters.ThisIsLocalizedVersion Then
		
		OrganizationsForCalculatingDeviations = 
			TMCommonUseClientServer.IntersectionOfArrays(
				CalculationParameters.OrganizationsUseWriteOffOfDeviationsForSales,
				CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion24.UsedInCurPeriod); // Array
		
		// Recording of generated Registered Records by VAT party registers
		WriteRegisters = New Array;
		If OrganizationsForCalculatingDeviations.Count() = 0 Then
			// If the array of organizations is not empty, then the register will be recorded in the calculation of the declinationreferencesfurther reading
			WriteRegisters.Add(Metadata.InformationRegisters.ItemizeGoodsLotCost.FullName());
		EndIf;
		WriteRegisters.Add(Metadata.InformationRegisters.ItemizeLotCostItemizedAndOtherCosts.FullName());
		WriteRegisters.Add(Metadata.InformationRegisters.ItemizeGoodsCostItemizedAndOtherCosts.FullName());

		
		CostCalculationAppliedAlgorithms.PreliminaryRecordingOfGeneratedRegisteredRecorded(CalculationParameters, WriteRegisters);
		
	EndIf;
	
EndProcedure


// The stage of "Calculation of the declination of the release of the anti-slip"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure CalculationOfDeviationOfFIFOIssueMovingAverage(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "CalculationOfDeviationOfFIFOIssueMovingAverage");
	
	OrganizationsForCalculatingDeviations = 
		TMCommonUseClientServer.IntersectionOfArrays(
			CalculationParameters.OrganizationsUseWriteOffOfDeviationsForSales,
			CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion24.UsedInCurPeriod); // Array
	
	If OrganizationsForCalculatingDeviations.Count() = 0 Then
		Return;
	EndIf;
	
	If CalculationParameters.BatchCalculationStarted Then
		CostCalculationAppliedAlgorithms.CostCalculationMechanismIsPerformed(CalculationParameters, False);
	EndIf;
	
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTCorrectionOfReleaseDeviations");
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextCorrectionOfIssueDeviations(CalculationParameters));
		
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	#Region PreservationOfRegisteredRecords_DetailingCostOfBatchOfGoods
	
	If Not CostCalculationAppliedAlgorithms.EmptyTempTable(CalculationParameters, "TTCorrectionOfReleaseDeviations") Then
		
		MatchingTemporaryMovementTables = New Map;
		
		RegisterName = Metadata.InformationRegisters.ItemizeGoodsLotCost.Name;
		ReceiverDescription = CalculationParameters.RegisterRecords[RegisterName];
		TempTableName = "TTAdjustmentOfCostOfBatchOfGoods";
		
		CopiedFields = CostCalculationAppliedAlgorithms.GetColumnNamesAsString(
			CostCalculationAppliedAlgorithms.UnloadTemporaryTable(CalculationParameters, "TTCorrectionOfReleaseDeviations", 0));
		
		CopiedFields = StringFunctionsClientServer.SubstituteParametersToString(CopiedFields, "");
		
		FieldDescriptionTable = CostCalculationAppliedAlgorithms.GenerateDescriptionOfRequestFields(ReceiverDescription.Table);
		CostCalculationAppliedAlgorithms.CopyRequestFields(FieldDescriptionTable, CopiedFields);
		
		CostCalculationAppliedAlgorithms.MakeRequestForFieldDescriptions(
			CalculationParameters,
			FieldDescriptionTable,
			RegisterName,
			"TTCorrectionOfReleaseDeviations",
			TempTableName);
		
		MatchingTemporaryMovementTables.Insert(TempTableName, RegisterName);
		
		CostCalculationAppliedAlgorithms.CacheGeneratedRegisteredRecordsFromTemporaryTables(CalculationParameters, MatchingTemporaryMovementTables, True);
		
	EndIf;
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, "TTCorrectionOfReleaseDeviations");
	
	#EndRegion
	
	// Recording of generated Registered Records by VAT party registers
	WriteRegisters = New Array;
	WriteRegisters.Add(Metadata.InformationRegisters.ItemizeGoodsLotCost.FullName());

	CostCalculationAppliedAlgorithms.PreliminaryRecordingOfGeneratedRegisteredRecorded(CalculationParameters, WriteRegisters);
	
	If CalculationParameters.BatchCalculationStarted Then
		CostCalculationAppliedAlgorithms.CostCalculationMechanismIsPerformed(CalculationParameters, True);
	EndIf;
	
EndProcedure

// The stage of "Preparing the data for inclusion and exclusion of expenses in the cost24"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfDataForInclusionExclusionOfVATAdditionalExpensesInCost24(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparationOfDataForInclusionExclusionOfVATAdditionalExpensesInCost24");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		Undefined,
		Metadata.AccumulationRegisters.InventoryCost.Name);
	
	// 2. Getting the source data for the broadcast
	// 	- generates a temporary Data table.
	GetDataForInclusionExclusionOfVATAdditionalExpenses(CalculationParameters);
	
	// 3. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of cost of goods.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure


// The stage of "Preparation for the Party of other expenses"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfDataForBatchesOfOtherExpenses(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparationOfDataForBatchesOfOtherExpenses");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		Undefined,
		Metadata.AccumulationRegisters.ItemisedExpensesLots.Name);
	
	// 2. Getting the source data for the broadcast
	// 	- generates a temporary Data table.
	GetDataForBatchesOfOtherExpenses(CalculationParameters);
	
	// 3. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of parties and other expenses.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure


#EndRegion


#EndRegion

#Region Private

#Region Initialize

Procedure InitializeTableForSelectingBatchAccountingAnalystsNDS2_4(TempTablesManager) Export
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(TempTablesManager, "TTSelectionOfPartyAccountingAnalyticsNDS2_4");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = TableQueryTextForSelectingBatchAccountingAnalystsNDS2_4();
	Query.Execute();
	
EndProcedure

Function TableQueryTextForSelectingBatchAccountingAnalystsNDS2_4() Export
	
	Return 
		"SELECT
		|	T.Ref AS Ref,
		|	CASE
		|		WHEN NOT T.Counterparty IN (VALUE(Catalog.Companies.EmptyRef), VALUE(Catalog.Counterparties.EmptyRef), UNDEFINED)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ExternalCounterparty_,
		|	CASE
		|		WHEN T.RowCode <> 0
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS LineCodeFilledIn
		|INTO TTSelectionOfPartyAccountingAnalyticsNDS2_4
		|FROM
		|	Catalog.KeysForLotVendorAttributes AS T
		|WHERE
		|	NOT T.Counterparty IN (VALUE(Catalog.Companies.EmptyRef), VALUE(Catalog.Counterparties.EmptyRef), UNDEFINED)
		|	OR T.RowCode <> 0
		|";
	
EndFunction

#EndRegion

#Region ProceduresOfStage_CalculationOfBatchesOfNDS_AreGeneral

// Data Initialization

Function VATBatchConsumptionFields(CalculationParameters)
	
	Return "ItemsLocationAttributes, Organization, AccountingSection, InventoryOwnerAttribute, VATTaxationOfCostOfActivity, FinancialAccountingDimension";
	
EndFunction

Function DescriptionOfChainsOfVATShipments(CalculationParameters) Export
	
	DescriptionOfChains = New Map;
	ConsumptionFields	= VATBatchConsumptionFields(CalculationParameters);
	
	#Region GroupedStock
	
	// Ostatox Grouped <- Balance, Additional expenses, Additional expenses by party, Cost adjustment, acquisition adjustment of the previous period, 
	// Deviations of cost, remaining for distribution 
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.GroupedStock, ConsumptionFields + ", Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedStock,
		Enums.LotRecordTypes.Balance, ConsumptionFields + ", Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedStock,
		Enums.LotRecordTypes.AddExpensesForGoods, ConsumptionFields + ", Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedStock,
		Enums.LotRecordTypes.AddExpensesLotIsSpecified, ConsumptionFields + ", Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedStock,
		Enums.LotRecordTypes.CostAdjustment, ConsumptionFields + ", Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedStock,
		Enums.LotRecordTypes.DebitNoteForPreviousPeriod, ConsumptionFields + ", Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedStock,
		Enums.LotRecordTypes.CostVariance, ConsumptionFields + ", Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedStock,
		Enums.LotRecordTypes.BalanceForAllocation, ConsumptionFields + ", Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedStock,
		Enums.LotRecordTypes.BaseAdditionalExpensesLocal, ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedStock,
		Enums.LotRecordTypes.BaseAdditionalExpensesMan, ConsumptionFields + ", DocumentSource");
	
	#EndRegion
		
	// Ostatocdistribution <- Additional spending by the Party
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.BalanceForAllocation, ConsumptionFields + ", Recorder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.BalanceForAllocation,
		Enums.LotRecordTypes.AddExpensesLotIsNotSpecified, ConsumptionFields + ", DocumentSource");
	
	#Region GroupedLot
	
	// Partiyagrouped <- Party, Additional expenses, Additional expenses by Party, Additional expenses by party, Cost adjustment, 
	// Deviations of cost, Release, Relocation, Base costsregl, Base COSTSUPR, Partiyidistribution, Partiyway
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.GroupedLot, ConsumptionFields + ", Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedLot,
		Enums.LotRecordTypes.Lot, ConsumptionFields + ", Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedLot,
		Enums.LotRecordTypes.AddExpensesForGoods, ConsumptionFields + ", Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedLot,
		Enums.LotRecordTypes.AddExpensesLotIsNotSpecified, ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedLot,
		Enums.LotRecordTypes.AddExpensesLotIsSpecified, ConsumptionFields + ", Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedLot,
		Enums.LotRecordTypes.CostAdjustment, ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedLot,
		Enums.LotRecordTypes.CostVariance, ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedLot,
		Enums.LotRecordTypes.ProductionIssue, ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedLot,
		Enums.LotRecordTypes.Move, ConsumptionFields + ", Recorder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedLot,
		Enums.LotRecordTypes.BaseAdditionalExpensesLocal, ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedLot,
		Enums.LotRecordTypes.BaseAdditionalExpensesMan, ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedLot,
		Enums.LotRecordTypes.LotsToAllocate, ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedLot,
		Enums.LotRecordTypes.LotsInTransit, ConsumptionFields + ", DocumentSource");
	
	#EndRegion
	
	#Region Consumption_ConsumptionOfGoodsInTransit_AutoConsumption
		
	// Consumption <- (Remaining grouped, Party, Additional expenses, Additional expenses by Party, Additional expenses by Party,
	// Adjusting the acquisition of the past period, Moving, moving separately, Storno, Return, consumption,
	// Return of past periods, return of source documentation, correction of past period).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.Consumption, ConsumptionFields + ", DocumentSourceOfCost");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.GroupedStock,		ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.GroupedLot,		ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.DebitNoteForPreviousPeriod, ConsumptionFields + ", DocumentSourceOfCost");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.Move, ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.ReversingEntry, 		ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.ReturnReverseTransaction, ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.ConsumptionReverseTransaction, ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.PreviousPeriodReturn, ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.PreviousPeriodCorrections, ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.ReturnWithoutSourceDocument, ConsumptionFields + ", CostLogger");
		
	// Consumeretovaryway <- (Movementetovaryway, Moving).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ConsumptionGoodsInTransit, ConsumptionFields + ", DocumentSourceOfCost");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, 
		Enums.LotRecordTypes.ConsumptionGoodsInTransit, Enums.LotRecordTypes.TransferGoodsInTransit,
		ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, 
		Enums.LotRecordTypes.ConsumptionGoodsInTransit, Enums.LotRecordTypes.Move, 
		ConsumptionFields + ", CostLogger");
	
	// Consummentauto <- (Remaining grouped, Batch Grouped, Moving, Moving apart, Storno, Return,
	// Reverse consumption, additional expenses).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ConsumptionLotCalculation, 		ConsumptionFields + ", DocumentSourceOfCost");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.GroupedStock,				ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.GroupedLot,		ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.Move, 		ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, 		ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.ReversingEntry, 				ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.ReturnReverseTransaction, 		ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.ConsumptionReverseTransaction,	ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.AddExpensesForGoods,			ConsumptionFields + ", DocumentSourceOfCost");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.PreviousPeriodCorrections, ConsumptionFields + ", CostLogger");	
	
	#EndRegion
	
	#Region WriteOffToOtherParties_StornoWriteOffToOtherParties
		
	// Write-off of other parties <- (Remaining grouped, Party, Additional charges, additional charges byparty, additional charges byparty,
	// Adjusting the acquisition of the past period, Moving, moving separately, Storno, Return, consumption,
	// Return of past periods)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ExpensesToOtherProductionLots, ConsumptionFields + ", DocumentSourceOfCost");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.GroupedStock,		ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.GroupedLot,		ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.DebitNoteForPreviousPeriod, ConsumptionFields + ", DocumentSourceOfCost");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.Move, ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.ReversingEntry, 		ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.ReturnReverseTransaction, ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.ConsumptionReverseTransaction, ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.PreviousPeriodReturn, ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.PreviousPeriodCorrections, ConsumptionFields + ", CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.ReverseOfCostAllocationToOtherLots, ConsumptionFields + ", CostLogger");
		
	// Write-offs of other parties <- (Write-offs of other parties)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReverseOfCostAllocationToOtherLots, ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReverseOfCostAllocationToOtherLots,
		Enums.LotRecordTypes.ExpensesToOtherProductionLots, ConsumptionFields + ", Recorder");	
	
	#EndRegion
	
	#Region PurchaseAdjustment
	
	// Acquisition adjustment <- (Remaining grouped, Batch Grouped, Return past periods, Move)	
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.PurchaseAdjustment, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.PurchaseAdjustment,
		Enums.LotRecordTypes.GroupedStock, 				 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.PurchaseAdjustment,
		Enums.LotRecordTypes.GroupedLot,			 	 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.PurchaseAdjustment,
		Enums.LotRecordTypes.PreviousPeriodReturn,	 ConsumptionFields);	
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.PurchaseAdjustment,
		Enums.LotRecordTypes.Move, ConsumptionFields);
	
	#EndRegion
	
	#Region CorrectPreviousPeriodTransfer
		
	// Correction of the displacement of the past period <- (Remaining grouped, batch grouped, return of past periods)	
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.CorrectPreviousPeriodTransfer, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CorrectPreviousPeriodTransfer,
		Enums.LotRecordTypes.GroupedStock, 				 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CorrectPreviousPeriodTransfer,
		Enums.LotRecordTypes.GroupedLot,			 	 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CorrectPreviousPeriodTransfer,
		Enums.LotRecordTypes.PreviousPeriodReturn,	 ConsumptionFields);	
	
	#EndRegion
		
	#Region ReversingEntry_ConsumptionReverseTransaction_ReturnReverseTransaction_ReturnToAnotherWarehouseReverseTransaction
		
	// Storno <- (Consumption, Consumerauto, Past)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReversingEntry, 		"DocumentSource, CorItemsLocationAttributes, CorInventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReversingEntry,
		Enums.LotRecordTypes.Consumption, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReversingEntry,
		Enums.LotRecordTypes.ConsumptionLotCalculation, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReversingEntry,
		Enums.LotRecordTypes.Previous, 	"Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
		
	// Stornopotrebleniya <- (Consumption)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ConsumptionReverseTransaction, "DocumentSource, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionReverseTransaction,
		Enums.LotRecordTypes.Consumption, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
	
	// StornoVozvrata <- (Storno, Stornovozvrata another way)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReturnReverseTransaction,	"DocumentSource, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnReverseTransaction,
		Enums.LotRecordTypes.ReversingEntry, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnReverseTransaction,
		Enums.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
		
	// The return of another deposit <- (Consumption, consumptionauthor, Past)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction,	"DocumentSource, CorItemsLocationAttributes, CorInventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction,
		Enums.LotRecordTypes.Consumption,					"Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction,
		Enums.LotRecordTypes.ConsumptionLotCalculation,				"Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction,
		Enums.LotRecordTypes.Previous,						"Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
		
	#EndRegion
		
	// Return of the document from the source <- (Consumption)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReturnWithoutSourceDocument, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnWithoutSourceDocument,
		Enums.LotRecordTypes.Consumption, 				 ConsumptionFields);
	
	#Region WriteOffOfBalanceWithoutBatch_StornoWriteOffOfBalanceWithoutBatch
		
	// write-offs of the party's statistics <- (consumption, Balance, write-offs of the party's statistics, correction of the past period)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot,
		Enums.LotRecordTypes.Consumption, 				 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot,
		Enums.LotRecordTypes.Balance, 					 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot,
		Enums.LotRecordTypes.StornoOfWriteOffOfBalanceWithoutLot, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot,
		Enums.LotRecordTypes.PreviousPeriodCorrections,	 ConsumptionFields);
		
	// Write-offsostat of the Non-Party <- (Write-offsostat of the Non-party)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.StornoOfWriteOffOfBalanceWithoutLot, 	"DocumentSource, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.StornoOfWriteOffOfBalanceWithoutLot,
		Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
	
	#EndRegion
	
	#Region ReturnToAnotherWarehouse
	
	// Return to another order <- (Reverse return to another order, reverse return)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReturnToAnotherWarehouse,
		"Recorder, ItemsLocationAttributes, Organization, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnToAnotherWarehouse,
		Enums.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction,
		"Recorder, ItemsLocationAttributes, Organization, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnToAnotherWarehouse,
		Enums.LotRecordTypes.ReturnReverseTransaction,
		"Recorder, ItemsLocationAttributes, Organization, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension");
		
	#EndRegion
		
	#Region Allocation
		
	// Distribution <- (Moving, Moving apart, Remaining grouped, Batch grouped, Return past periods, Distribution)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.Allocation,
		"ItemsLocationAttributes, Organization, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension, VATTaxationOfCostOfActivity, DocumentSourceOfCost");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Allocation,
		Enums.LotRecordTypes.Move,
		"ItemsLocationAttributes, Organization, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension, VATTaxationOfCostOfActivity, CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Allocation,
		Enums.LotRecordTypes.TransferOnAssignmentBasis,
		"ItemsLocationAttributes, Organization, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension, VATTaxationOfCostOfActivity, CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Allocation,
		Enums.LotRecordTypes.GroupedStock,
		"ItemsLocationAttributes, Organization, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension, VATTaxationOfCostOfActivity, CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Allocation,
		Enums.LotRecordTypes.GroupedLot,
		"ItemsLocationAttributes, Organization, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension, VATTaxationOfCostOfActivity, CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Allocation,
		Enums.LotRecordTypes.PreviousPeriodReturn,
		"ItemsLocationAttributes, Organization, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension, VATTaxationOfCostOfActivity, CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Allocation,
		Enums.LotRecordTypes.Allocation,
		"ItemsLocationAttributes, Organization, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension, VATTaxationOfCostOfActivity, CostLogger");
		
	#EndRegion
		
	#Region Move
 	
	// Moving <- (Consumption, Consumerauto, Consumerproduction, return of another deposit, write-off of another party).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.Move,
		"Recorder, Lot, ItemsLocationAttributes, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Move,
		Enums.LotRecordTypes.Consumption,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Move,
		Enums.LotRecordTypes.ConsumptionLotCalculation,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Move,
		Enums.LotRecordTypes.ConsumptionProduction,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Move,
		Enums.LotRecordTypes.ReturnToAnotherWarehouse,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Move,
		Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes, Organization");
		
	#EndRegion
		
	#Region TransferGoodsInTransit
	
	// The movement of the wayway <- (Consumption of the wayway, Consumption).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.TransferGoodsInTransit,
		"Recorder, Lot, ItemsLocationAttributes, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, 
		Enums.LotRecordTypes.TransferGoodsInTransit,
		Enums.LotRecordTypes.ConsumptionGoodsInTransit,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute,
		|CorControllingAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, 
		Enums.LotRecordTypes.TransferGoodsInTransit,
		Enums.LotRecordTypes.Consumption,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute,
		|CorControllingAttributes, Organization");
		
	#EndRegion
		
	// Moving apart <- (Consumption)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.TransferOnAssignmentBasis,
		"Recorder, Lot, ItemsLocationAttributes, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferOnAssignmentBasis,
		Enums.LotRecordTypes.Consumption,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes, CorCompany");
	
	#Region TransferAuto
		
	// Moving Auto <- (Consumption, Consumptionproduction, ConsumptionAuto, Distribution).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.TransferAuto,
		"Recorder, Lot, ItemsLocationAttributes, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferAuto,
		Enums.LotRecordTypes.Consumption,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferAuto,
		Enums.LotRecordTypes.ConsumptionProduction,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferAuto,
		Enums.LotRecordTypes.ConsumptionLotCalculation,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferAuto,
		Enums.LotRecordTypes.Allocation,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferAuto,
		Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes");
		
	#EndRegion
	
	// Displacement of the state <- (Consumption)
	// The type of record of the movementthe state has no receivers, it forms the Balance at the end of the month.
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.TransferToBalance, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferToBalance,
		Enums.LotRecordTypes.Consumption, "Recorder, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
	
	#Region CostAllocationToProductionLots
		
	// Write-off Issues <- (Move, Move separately, Move alone, Batch grouped, Remaining grouped).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.CostAllocationToProductionLots, ConsumptionFields + ",Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAllocationToProductionLots,
		Enums.LotRecordTypes.Move, ConsumptionFields + ",Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAllocationToProductionLots,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, ConsumptionFields + ",Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAllocationToProductionLots,
		Enums.LotRecordTypes.TransferAuto, ConsumptionFields + ",Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAllocationToProductionLots,
		Enums.LotRecordTypes.GroupedLot, ConsumptionFields + ",Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAllocationToProductionLots,
		Enums.LotRecordTypes.GroupedStock, ConsumptionFields + ",Lot");
		
	#EndRegion
		
	#Region ProductionIssue
		
	// Issue <- (Write-offs, Issue, Consumption)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ProductionIssue,
		"Recorder, Lot, ItemsLocationAttributes, AccountingSection, InventoryOwnerAttribute, FinancialAccountingDimension");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ProductionIssue,
		Enums.LotRecordTypes.CostAllocationToProductionLots,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ProductionIssue,
		Enums.LotRecordTypes.Consumption,
		"Recorder, CorLot, CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorControllingAttributes"); // This link is also used in the textmovement of the highest value of goods()
		
	#EndRegion
	
	#Region ConsumptionProduction
		
	// Consumptionproduction <- (Batch grouped, Moving, Moving separately, remaining grouped)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ConsumptionProduction, "ItemsLocationAttributes, Organization, AccountingSection, DocumentSourceOfCost");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionProduction,
		Enums.LotRecordTypes.GroupedLot,   "ItemsLocationAttributes, Organization, AccountingSection, CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionProduction,
		Enums.LotRecordTypes.Move, 		"ItemsLocationAttributes, Organization, AccountingSection, CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionProduction,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, "ItemsLocationAttributes, Organization, AccountingSection, CostLogger");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionProduction,
		Enums.LotRecordTypes.GroupedStock, "ItemsLocationAttributes, Organization, AccountingSection, CostLogger");
		
	#EndRegion
		
	// Write-offsend <- (Batch grouped)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ExpenseAs, ConsumptionFields + ", DocumentSourceOfCost");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpenseAs,
		Enums.LotRecordTypes.GroupedLot, ConsumptionFields + ", CostLogger");
		
	// Return of Past periods <- (Past)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.PreviousPeriodReturn, "DocumentSource, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization, AccountingSection");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.PreviousPeriodReturn,
		Enums.LotRecordTypes.Previous, 			   "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection");
		
	// Reversal of past periods <- (Return of past periods)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReverseOfPreviousPeriodsReturn, "DocumentSource, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization, AccountingSection");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReverseOfPreviousPeriodsReturn,
		Enums.LotRecordTypes.PreviousPeriodReturn, 		  "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection");
		
	// Correction of the current period <- (Move)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.CurrentPeriodCorrections, "DocumentSource, ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CurrentPeriodCorrections,
		Enums.LotRecordTypes.Move, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection");	
	
	#Region Additions
		
	// Addition, Cost deviations, distribution of items that have been added, and repositionupr <- (<without sources - for generating records based on
	// request data>).
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.Supplement);
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.AdditionLotsCalculation);
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.InclusionExclusionOfVATInCost);
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.CostVariance);
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.AllocationByDisposedGoods);
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferMan);
	
	#EndRegion
	
	#Region BaseAdditionalExpensesLocal
	
	Sources = New Map;
	Sources.Insert(Enums.LotRecordTypes.AdditionalExpensesForAllocationLocal);
	
	CostCalculationAppliedAlgorithms.AddReceiverDescription(
		DescriptionOfChains,
		Enums.LotRecordTypes.BaseAdditionalExpensesLocal,
		"Organization, ExpenseItemAssets, DimensionOfExpenses, Department, LineOfBusiness",
		Sources);
	
	#EndRegion
	
	#Region BaseAdditionalExpensesMan
	
	Sources = New Map;
	Sources.Insert(Enums.LotRecordTypes.AdditionalExpensesForAllocationMan);
	
	CostCalculationAppliedAlgorithms.AddReceiverDescription(
		DescriptionOfChains,
		Enums.LotRecordTypes.BaseAdditionalExpensesMan,
		"Organization, ExpenseItemAssets, DimensionOfExpenses, Department, LineOfBusiness",
		Sources);
	
	#EndRegion
	
	#Region LotsToAllocate
	
	Sources = New Map;
	Sources.Insert(Enums.LotRecordTypes.BaseAdditionalExpensesLocal);
	Sources.Insert(Enums.LotRecordTypes.BaseAdditionalExpensesMan);
	Sources.Insert(Enums.LotRecordTypes.ItemizedExpencesAllocationToProductionLots);
	Sources.Insert(Enums.LotRecordTypes.ProductionIssue);
	
	CostCalculationAppliedAlgorithms.AddReceiverDescription(
		DescriptionOfChains,
		Enums.LotRecordTypes.LotsToAllocate,
		ConsumptionFields + ", Recorder",
		Sources,
		ConsumptionFields + ", DocumentSource");
		
	#EndRegion
	
	#Region LotsInTransit
	
	Sources = New Map;
	Sources.Insert(Enums.LotRecordTypes.BaseAdditionalExpensesLocal);
	Sources.Insert(Enums.LotRecordTypes.BaseAdditionalExpensesMan);
	
	CostCalculationAppliedAlgorithms.AddReceiverDescription(
		DescriptionOfChains,
		Enums.LotRecordTypes.LotsInTransit,
		"CorItemsLocationAttributes, Organization, CorAccountingSection, CorInventoryOwnerAttribute, CorVATActivityTypes, CorControllingAttributes",
		Sources,
		ConsumptionFields);
		
	#EndRegion
	
	Return DescriptionOfChains;
	
EndFunction


Function DescriptionOfUnrecordedVATShipments(CalculationParameters)
	
	UnrecordedRecordTypes = New Map;
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.Balance,   True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.Previous,   True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.GroupedStock, True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.GroupedLot, True);
	
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.BaseAdditionalExpensesLocal, 	  		  True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.BaseAdditionalExpensesMan, 		  	  True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.AdditionalExpensesForAllocationLocal, True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.AdditionalExpensesForAllocationMan,  True);
	
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.ItemizedExpencesAllocationToProductionLots,  True);
	
	UnwrittenPartitions = New Map;
	
	Return CostCalculationAppliedAlgorithms.DescriptionOfNonWritableData(False, UnrecordedRecordTypes, UnwrittenPartitions);
	
EndFunction

Function TableForDistributionOfVATBatches(CalculationParameters)
	
	Return CostCalculationAppliedAlgorithms.TableForDistributionOfLots(CalculationParameters, TextDescriptionOfDataForLBSiUSNBatches());
	
EndFunction

// ... data descriptions

Function TextDescriptionOfDataForLBSiUSNBatches()
	
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80)) 					AS RequestSource,
		|	DD.EntryType 									AS EntryType,
		|	FALSE											AS ThisIsReverseTransaction,
		|	0 												AS Priority,
		|	0 												AS Denominator,
		|	0 												AS DenominatorForSources,
		|	FALSE 											AS CalculationIsCompleted,
		|	VALUE(Catalog.Products.EmptyRef) 	AS Products,
		|	DD.LotVendorAttributes.VATTaxation 		AS TaxationOfParty,
		|	
		|	DD.Period,
		|	DD.Recorder,
		|	DD.Recorder AS CostLogger,
		|	DD.RecordType,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.VATActivityType AS VATTaxationOfCostOfActivity,
		|	DD.LotVendorAttributes,
		|	DD.Lot AS DocumentInflow,
		|
		|	DD.Count,
		|	DD.CostExcludingVAT,
		|	DD.CostExcludingVAT AS VAT,
		|	DD.CostExcludingVAT AS CostExcludingVATMan,
		|	DD.CostExcludingVAT AS VATManag,
		|
		|	DD.BusinessOperation,
		|	DD.CorVATActivityTypes,
		|	DD.AccountingSection AS CorAccountingSection,
		|	DD.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	DD.Organization AS CorCompany,
		|	DD.Lot AS CorLot,
		|	DD.CorControllingAttributes,
		|	DD.Department,
		|	OtherLots.ExpenseItem AS ExpenseItemAssets,
		|	DD.DimensionOfExpenses,
		|	OtherLots.AssetsLiabilitiesDimension AS DimensionOfAssets,
		|	DD.ExpenseItemOfWriteOff AS CorExpenseItem,
		|	DD.DimensionOfExpenses AS CorExpenditureDimension,
		|	DD.Department AS DebitBusinessUnit,
		|	DD.DocumentSource,
		|	DD.DocumentSource AS DocumentSourceOfCost,
		|	DD.ExpenseItemOfWriteOff AS VATWriteOffItem,
		|	DD.DimensionOfExpenses AS DimensionVATWriteOff,
		|	DD.CorLineOfBusiness AS LineOfBusiness,
		|	DD.CorLineOfBusiness,
		|	DD.VATActivityType AS DocumentVATActivityType,
		|	DD.GLAccountSettings,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.ReversingEntry,
		|	DD.FinRecordID AS FinRecordID
		|INTO Data
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|	LEFT JOIN AccumulationRegister.ItemisedExpensesLots AS OtherLots
		|	ON FALSE
		|";
	
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);
	
	Return QueryText;
	 
EndFunction

// ... formation of temporary tables

Function TextOfAnalyticsOfAccountingOfBatchesOfCustomsDeclarations() // TTChangeInTypeOfActivityAdditionalExpenseAMOUNT
	Return "
		|SELECT
		|	DD.Period,
		|	DD.Recorder,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	CAST(DD.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.CorControllingAttributes,
		|	DD.VATActivityType,
		|	DD.CorVATActivityTypes,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorLineOfBusiness,
		|	DD.BusinessOperation,
		|	DD.DocumentSource,
		|	SUM(DD.VATLocal) AS VATLocal,
		|	SUM(DD.VATManag) AS VATManag,
		|	MAX(DD.FinRecordID) AS FinRecordID
		|INTO TTChangeInTypeOfActivityAdditionalExpenseAMOUNTPreliminary
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion22)
		|	AND DD.VATActivityType <> DD.CorVATActivityTypes
		|	AND DD.CorVATActivityTypes <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	AND (DD.VATLocal <> 0 OR DD.VATManag <> 0)
		|	AND DD.EntryType IN (
		|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified))
		|	AND NOT DD.ReversingEntry
		|GROUP BY
		|	DD.Period,
		|	DD.Recorder,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	CAST(DD.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys),
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.CorControllingAttributes,
		|	DD.VATActivityType,
		|	DD.CorVATActivityTypes,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorLineOfBusiness,
		|	DD.BusinessOperation,
		|	DD.DocumentSource
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Period,
		|	DD.Recorder,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.CorControllingAttributes,
		|	DD.VATActivityType,
		|	DD.CorVATActivityTypes,
		|	MAX(ISNULL(PartyAnalysts_.LotVendorAttributesCorr, DD.LotVendorAttributesCorr)) AS LotVendorAttributesCorr,
		|	DD.CorLineOfBusiness,
		|	DD.BusinessOperation,
		|	DD.DocumentSource,
		|	DD.VATLocal,
		|	DD.VATManag,
		|	MAX(DD.FinRecordID) AS FinRecordID
		|INTO TTChangeInTypeOfActivityAdditionalExpenseAMOUNT
		|FROM
		|	TTChangeInTypeOfActivityAdditionalExpenseAMOUNTPreliminary AS DD
		|	LEFT JOIN TTCashEstimatedTurnoverCostOfGoods AS PartyAnalysts_
		|		ON DD.Recorder = PartyAnalysts_.Recorder
		|		AND DD.Organization = PartyAnalysts_.Organization
		|		AND DD.AccountingSection = PartyAnalysts_.AccountingSection
		|		AND DD.ItemsLocationAttributes = PartyAnalysts_.ItemsLocationAttributes
		|		AND DD.InventoryOwnerAttribute = PartyAnalysts_.InventoryOwnerAttribute
		|		AND DD.Lot = PartyAnalysts_.Lot
		|		AND DD.VATActivityType = PartyAnalysts_.VATActivityType
		|		AND DD.FinancialAccountingDimension = PartyAnalysts_.FinancialAccountingDimension
		|		AND DD.LotVendorAttributesCorr = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|		AND NOT PartyAnalysts_.LotCalculation 
		|		AND NOT PartyAnalysts_.CalculationOfCost
		|GROUP BY
		|	DD.Period,
		|	DD.Recorder,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.CorControllingAttributes,
		|	DD.VATActivityType,
		|	DD.CorVATActivityTypes,
		|	DD.CorLineOfBusiness,
		|	DD.BusinessOperation,
		|	DD.DocumentSource,
		|	DD.VATLocal,
		|	DD.VATManag
		|
	    |";
EndFunction

Function TextInitializationOfVATBatchesTotal() // TT Write-offsreferences
	Return
		"SELECT
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	CASE WHEN DD.Organization IN (&MediumSlipOrganizations)
		|		THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType
		|	END AS VATActivityType,
		|	SUM(DD.AddExpensesLocal)	AS AddExpensesLocal,
		|	SUM(DD.VATLocal)			AS VATLocal,
		|	SUM(DD.AddExpensesMan)		AS AddExpensesMan,
		|	SUM(DD.VATManag)			AS VATManag
		|INTO WriteOffOfCostDeviations
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion22)
		|	AND DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
		|	AND NOT DD.OfficialTypeOfMovementParish
		|	AND NOT DD.ReversingEntry
		|GROUP BY
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	CASE WHEN DD.Organization IN (&MediumSlipOrganizations)
		|		THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType
		|	END
		|";
EndFunction

Function TextCorrectedVATDocuments() // TT fixed documentsreferences
	Return "	
		|SELECT
		|	Register3.ReversedDocument AS DocumentSource,
		|	SourceRegistry.IBDocumentDate AS DateOfSourceDocument,
		|	MAX(CASE WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|		THEN TRUE
		|		ELSE FALSE
		|	END) AS CorrectionOfDisplacement,
		|	DD.Period,
		|	DD.Recorder
		|INTO CorrectedVATDocuments
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|
		|	INNER JOIN InformationRegister.DocumentsRegistry AS Register3
		|		ON Register3.Ref = DD.Recorder
		|		AND (NOT Register3.AdditionalRecord OR Register3.RefType IN (&DocumentsWithTwoOrganizations))
		|		AND Register3.Ref <> UNDEFINED
		|	INNER JOIN InformationRegister.DocumentsRegistry AS SourceRegistry
		|		ON SourceRegistry.Ref = Register3.ReversedDocument
		|		AND (NOT SourceRegistry.AdditionalRecord OR SourceRegistry.RefType IN (&DocumentsWithTwoOrganizations))
		|		AND SourceRegistry.Ref <> UNDEFINED
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion22)
		|	AND DD.ReversingEntry
		|	AND DD.DocumentSource <> DD.Recorder
		|GROUP BY
		|	Register3.ReversedDocument,
		|	SourceRegistry.IBDocumentDate,
		|	DD.Period,
		|	DD.Recorder
		|";
EndFunction

Function TextOfCorrectionBeforeEnteringBalance()

	Return "
	|SELECT
	|	DD.Recorder AS Recorder,
	|	DD.FinRecordID
	|INTO AdjustmentsBeforeEnteringBalancesPreliminary
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS DD
	|	INNER JOIN Document.SaleAdjustment AS Adjusting
	|		ON DD.Recorder = Adjusting.Ref
	|WHERE
	|	DD.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|	AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AdjustBeforeEnteringBalance)
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|SELECT
	|	DD.Recorder AS Recorder,
	|	DD.FinRecordID,
	|	VATRegisterRecords.AmountExcludingVAT
	|INTO AdjustmentsBeforeEnteringBalances
	|FROM
	|	AdjustmentsBeforeEnteringBalancesPreliminary AS DD
	|	INNER JOIN AccumulationRegister.VATRegisterRecords AS VATRegisterRecords
	|		ON DD.Recorder = VATRegisterRecords.Recorder
	|		AND DD.FinRecordID = VATRegisterRecords.FinRecordID
	|
	|INDEX BY
	|	Recorder
	|
	|";
	
EndFunction

Function TextGoodsReceiptsVAT() // TT parishes, uses corrected documentsinds
	Return "
		|SELECT
		|	(CASE
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			THEN VALUE(Enum.LotRecordTypes.Lot)
		|		WHEN NOT DD.OfficialTypeOfMovementParish
		|			AND DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
		|			THEN VALUE(Enum.LotRecordTypes.Supplement)
		|		ELSE DD.EntryType END) AS EntryType,
		|	FALSE AS ThisIsReverseTransaction,
		|	SUM(DD.Count) AS Denominator,
		|	DD.ItemsLocationAttributes.Products AS Products,
		|	DD.LotVendorAttributes.VATTaxation AS TaxationOfParty,
		|	
		|	DD.Period,
		|	DD.Recorder AS Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		 THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END AS RecordType,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	(CASE
		|		WHEN NOT CorrectedDocuments_.DocumentSource IS NULL
		// For the correction of production without an order, the batch document and the cost receipt document are a new document
		|		  AND VALUETYPE(CorrectedDocuments_.DocumentSource) <> TYPE(Document.BackflushProduction)
		|			THEN CorrectedDocuments_.DocumentSource
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
		|		  AND VALUETYPE(DD.Recorder) = TYPE(Document.ApplicationForImportationOfGoods)
		|		  AND VALUETYPE(DD.DimensionOfExpenses) = TYPE(Document.ReceiptOfGoodsToWarehouse)
		|		  AND DD.DimensionOfExpenses <> VALUE(Document.ReceiptOfGoodsToWarehouse.EmptyRef)
		|			THEN DD.DimensionOfExpenses
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
		|		 AND DD.BusinessOperation IN
		|		  (VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|		   VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
		|			THEN DD.DimensionOfExpenses
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|		  AND VALUETYPE(DD.Recorder) = TYPE(Document.ApplicationForImportationOfGoods)
		|		  AND DD.DocumentSource <> UNDEFINED
		|			THEN DD.DocumentSource
		|		WHEN DD.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.CostAdjustment),
		|				VALUE(Enum.LotRecordTypes.CostVariance))
		|			THEN CASE
		|				WHEN VALUETYPE(DD.DocumentSource) = TYPE(Document.OBEntryGoods)
		|					THEN ISNULL(OBEntryGoods.Lot,
		|						ISNULL(AdditionalExpensesAmountAdjustment.DocumentBasis, DD.DocumentSource))
		|				ELSE ISNULL(OBEntry.Lot,
		|					ISNULL(AdditionalExpensesAmountAdjustment.DocumentBasis, DD.DocumentSource))
		|			END
		|		WHEN NOT Adjusting.DocumentBasis IS NULL
		|			THEN Adjusting.DocumentBasis
		|		WHEN DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|			THEN DD.Lot
		|		ELSE DD.Recorder END) AS Lot,
		|	DD.FinancialAccountingDimension,
		|	CASE WHEN DD.Organization IN (&MediumSlipOrganizations)
		|		THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType
		|	END AS VATActivityType,
		|	CASE WHEN DD.Organization IN (&MediumSlipOrganizations)
		|		THEN DD.DocumentVATActivityType
		|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	END AS DocumentVATActivityType,
		|
		|	(CASE
		|		WHEN DD.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods))
		|		AND DD.OfficialTypeOfMovementParish
		|			THEN DD.LotVendorAttributesCorr
		|		WHEN DD.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|			THEN DD.LotVendorAttributesCorr
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.Lot) AND DD.Count = 0
		|		 AND DD.LotVendorAttributesCorr <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|			THEN DD.LotVendorAttributesCorr
		|		ELSE DD.LotVendorAttributes END) AS LotVendorAttributes,
		|	(CASE
		|		WHEN NOT CorrectedDocuments_.DocumentSource IS NULL
		// For the correction of production without an order, the batch document and the cost receipt document are a new document
		|		  AND VALUETYPE(CorrectedDocuments_.DocumentSource) <> TYPE(Document.BackflushProduction)
		|			THEN CorrectedDocuments_.DocumentSource
		|		WHEN NOT Adjusting.AdjustmentKind IS NULL
		|		 AND Adjusting.AdjustmentKind <> VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
		|			THEN Adjusting.DocumentBasis
		|		ELSE DD.Recorder END) AS DocumentInflow,
		|
		|	SUM(DD.Count) AS Count,
		|	SUM(CASE
		|		WHEN DD.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.ByCorRecord)
		|			THEN 0
		|		WHEN NOT AdjustmentsBeforeEnteringBalances.Recorder IS NULL
		|			THEN AdjustmentsBeforeEnteringBalances.AmountExcludingVAT
		|		ELSE
		|		CASE WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
		|		 AND DD.VATLocal = 0
		|			THEN 0
		|			ELSE DD.LocalCost + DD.AddExpensesLocal END
		|		+ CASE
		|			WHEN NOT DD.Organization IN (&MediumSlipOrganizations)
		|			 AND DD.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|				THEN -DD.VATLocal
		|			ELSE 0
		|	END - ISNULL(WriteOffDeviations.AddExpensesLocal, 0) END) AS CostExcludingVAT,
		|	SUM(DD.VATLocal - ISNULL(WriteOffDeviations.VATLocal, 0)) AS VAT,
		|	SUM(CASE
		|		WHEN DD.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.ByCorRecord)
		|			THEN 0
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
		|		 AND DD.VATManag = 0
		|			THEN 0
		|		WHEN NOT &CompanyManagementAccounting
		|			THEN 0
		|			ELSE DD.CostMan + DD.AddExpensesMan END
		|		+ CASE
		|			WHEN NOT DD.Organization IN (&MediumSlipOrganizations)
		|			 AND DD.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|				THEN -DD.VATManag
		|			ELSE 0
		|	END - ISNULL(WriteOffDeviations.AddExpensesMan, 0)) AS CostExcludingVATMan,
		|	SUM(CASE
		|		WHEN &CompanyManagementAccounting
		|			THEN DD.VATManag - ISNULL(WriteOffDeviations.VATManag, 0)
		|		ELSE 0
		|	END) AS VATManag,
		|
		|	DD.BusinessOperation,
		|	DD.CorVATActivityTypes,
		|	DD.CorAccountingSection,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorLot,
		|	DD.CorControllingAttributes,
		|	DD.Department,
		|	(CASE
		|		WHEN DD.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|		 AND DD.ExpenseItemOfWriteOff <> UNDEFINED
		|			THEN DD.ExpenseItemOfWriteOff
		|		WHEN DD.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
		|			THEN DD.AssetAndLiabilityItem
		|		ELSE UNDEFINED END) AS ExpenseItemAssets,
		|	DD.DimensionOfExpenses,
		|	DD.AssetsLiabilitiesDimension AS DimensionOfAssets,
		|	(CASE
		|		WHEN NOT DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND Register3.IBDocumentDate < &BeginOfPeriod
		|			THEN UNDEFINED
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
		|		  AND VALUETYPE(DD.Recorder) = TYPE(Document.ApplicationForImportationOfGoods)
		|		  AND VALUETYPE(DD.DimensionOfExpenses) = TYPE(Document.ReceiptOfGoodsToWarehouse)
		|		  AND DD.DimensionOfExpenses <> VALUE(Document.ReceiptOfGoodsToWarehouse.EmptyRef)
		|			THEN DD.DimensionOfExpenses
		|		WHEN DD.Lot <> UNDEFINED
		|		 AND DD.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.CostVariance))
		|			THEN DD.Lot
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN RecordersMediumSlip.Ref
		|		ELSE DD.DocumentSource END) AS DocumentSource,
		|	DD.GLAccountSettings,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.ReversingEntry,
		|	MAX(DD.FinRecordID) AS FinRecordID
		|INTO GoodsReceiptsVAT
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	LEFT JOIN TTCostCalculationRecorders AS RecordersMediumSlip
		|		ON DD.Organization = RecordersMediumSlip.Organization
		|	LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS AnalysisOfCalculations
		|		ON AnalysisOfCalculations.Ref = DD.AccountingDimensionByPartners
		|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
		|		ON Contracts.Ref = AnalysisOfCalculations.Contract
		|	LEFT JOIN Document.PurchaseAdjustment AS Adjusting
		|		ON Adjusting.Ref = DD.Recorder
		|	LEFT JOIN Document.PurchaseAdjustment AS AdditionalExpensesAmountAdjustment
		|		ON AdditionalExpensesAmountAdjustment.Ref = DD.DocumentSource
		|	LEFT JOIN Document.OBEntry AS OBEntry
		|		ON OBEntry.Ref = DD.DocumentSource
		|	LEFT JOIN Document.OBEntryGoods AS OBEntryGoods
		|		ON OBEntryGoods.Ref = DD.DocumentSource
		|	LEFT JOIN WriteOffOfCostDeviations AS WriteOffDeviations
		|		ON WriteOffDeviations.Organization = DD.Organization
		|		AND WriteOffDeviations.AccountingSection = DD.AccountingSection
		|		AND WriteOffDeviations.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|		AND WriteOffDeviations.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|		AND WriteOffDeviations.Lot = DD.Lot
		|		AND WriteOffDeviations.FinancialAccountingDimension = DD.FinancialAccountingDimension
		|		AND WriteOffDeviations.VATActivityType = CASE WHEN DD.Organization IN (&MediumSlipOrganizations) THEN DD.DocumentVATActivityType ELSE DD.VATActivityType END
		|		AND DD.OfficialTypeOfMovementParish
		|		AND DD.EntryType <> VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
		|		ON Register3.Ref = DD.DocumentSource
		|		AND NOT Register3.AdditionalRecord
		|		AND Register3.Ref <> UNDEFINED
		|	LEFT JOIN CorrectedVATDocuments AS CorrectedDocuments_
		|		ON CorrectedDocuments_.Recorder = DD.Recorder
		|	LEFT JOIN AdjustmentsBeforeEnteringBalances AS AdjustmentsBeforeEnteringBalances
		|		ON AdjustmentsBeforeEnteringBalances.Recorder = DD.Recorder
		|		AND AdjustmentsBeforeEnteringBalances.FinRecordID = DD.FinRecordID
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion22)
		|	AND (DD.OfficialTypeOfMovementParish
		|		OR DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
		|		OR DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|		OR DD.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		|	AND NOT DD.EntryType = VALUE(Enum.LotRecordTypes.InclusionExclusionOfVATInCost)
		// We exclude the cumulative adjustment of the acquisition if the corrected document refers to a period with batch accounting turned off.
		|	AND NOT (
		|		DD.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
		|   	AND DD.OfficialTypeOfMovementParish
		|		AND DD.Count = 0
		|		AND Register3.IBDocumentDate < &DateOfMigrationToBatchAccounting22
		|		AND &BatchAccountingWasUsedBeforeSwitchingToVersion22 = FALSE)
		// If records are kept according to the USN, then all batches are needed, regardless of the presence of VAT in them.
		// Otherwise, you need to limit the selection of data:
		// - select batches with VAT
		// - also choose batches without VAT, but with quantity, because in the future they may be charged with VAT costs
		|	AND (DD.VATLocal <> 0
		|		OR DD.VATManag <> 0
		|		OR &UseVATDeclarationSection7Filling
		|		OR DD.Recorder REFS Document.AssemblyFromComponents
		|		OR DD.Recorder REFS Document.CCDImport
		|		OR DD.Recorder REFS Document.GoodsDamage
		|		OR DD.Recorder REFS Document.GoodsMisgrading
		|		OR DD.Recorder REFS Document.InventorySurplusRecognition
		|		OR ISNULL(Contracts.CompanyActsAsAVATTaxAgent, FALSE)
		|		OR DD.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEU),
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|			VALUE(Enum.BusinessTransactions.PurchaseByImport),
		|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|		OR VALUETYPE(DD.Recorder) = TYPE(Document.SubcontractorReport2_5)
		|		OR VALUETYPE(DD.Recorder) = TYPE(Document.BackflushProduction)
		|		OR VALUETYPE(DD.Recorder) = TYPE(Document.ProductionStage2_2)
		|		OR VALUETYPE(DD.Recorder) = TYPE(Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
		|		OR VALUETYPE(DD.Recorder) = TYPE(Document.ReceiptOfGoodsToWarehouse)
		|		)
		// We exclude the Registered Records for the release of products to the warehouse.
		|	AND NOT (DD.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|			AND DD.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
		|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost)))
		|	AND DD.EntryType IN (
		|		VALUE(Enum.LotRecordTypes.Lot),
		|		VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
		|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|		VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
		|		VALUE(Enum.LotRecordTypes.CostVariance),
		|		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|		VALUE(Enum.LotRecordTypes.CostAdjustment),
		|		VALUE(Enum.LotRecordTypes.Supplement))
		|	AND CASE WHEN DD.Organization IN (&MediumSlipOrganizations) THEN DD.DocumentVATActivityType ELSE DD.VATActivityType END <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	AND (DD.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|		OR VALUETYPE(DD.Recorder) IN(
		|				TYPE(Document.SubcontractorReport2_5))
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
		|		)
		|	AND NOT DD.AccountingSection IN (
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInStorageWithRightOfSaleToRegisterWriteOff),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
		|	AND (CASE
		|		WHEN DD.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods))
		|		AND DD.OfficialTypeOfMovementParish
		|			THEN DD.LotVendorAttributesCorr
		|		WHEN DD.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|			THEN DD.LotVendorAttributesCorr
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.Lot) AND DD.Count = 0
		|		 AND DD.LotVendorAttributesCorr <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|			THEN DD.LotVendorAttributesCorr
		|		ELSE DD.LotVendorAttributes END) <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|	AND NOT DD.Recorder REFS Document.PurchaseInvoiceConsignmentStockLost
		|	AND NOT ((DD.Recorder REFS Document.OBEntry
		|				AND NOT CAST(DD.Recorder AS Document.OBEntry).OBEntry22)
		|			OR DD.Recorder REFS Document.OBEntryGoods)
		|	AND NOT DD.ReversingEntry
		|GROUP BY
		|	(CASE
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			THEN VALUE(Enum.LotRecordTypes.Lot)
		|		WHEN NOT DD.OfficialTypeOfMovementParish
		|			AND DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
		|			THEN VALUE(Enum.LotRecordTypes.Supplement)
		|		ELSE DD.EntryType END),
		|	DD.ItemsLocationAttributes.Products,
		|	DD.LotVendorAttributes.VATTaxation,
		|	DD.Period,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		 THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	(CASE
		|		WHEN NOT CorrectedDocuments_.DocumentSource IS NULL
		|		  AND VALUETYPE(CorrectedDocuments_.DocumentSource) <> TYPE(Document.BackflushProduction)
		|			THEN CorrectedDocuments_.DocumentSource
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
		|		  AND VALUETYPE(DD.Recorder) = TYPE(Document.ApplicationForImportationOfGoods)
		|		  AND VALUETYPE(DD.DimensionOfExpenses) = TYPE(Document.ReceiptOfGoodsToWarehouse)
		|		  AND DD.DimensionOfExpenses <> VALUE(Document.ReceiptOfGoodsToWarehouse.EmptyRef)
		|			THEN DD.DimensionOfExpenses
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
		|		 AND DD.BusinessOperation IN
		|		  (VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|		   VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
		|			THEN DD.DimensionOfExpenses
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|		  AND VALUETYPE(DD.Recorder) = TYPE(Document.ApplicationForImportationOfGoods)
		|		  AND DD.DocumentSource <> UNDEFINED
		|			THEN DD.DocumentSource
		|		WHEN DD.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.CostAdjustment),
		|				VALUE(Enum.LotRecordTypes.CostVariance))
		|			THEN CASE
		|				WHEN VALUETYPE(DD.DocumentSource) = TYPE(Document.OBEntryGoods)
		|					THEN ISNULL(OBEntryGoods.Lot,
		|						ISNULL(AdditionalExpensesAmountAdjustment.DocumentBasis, DD.DocumentSource))
		|				ELSE ISNULL(OBEntry.Lot,
		|					ISNULL(AdditionalExpensesAmountAdjustment.DocumentBasis, DD.DocumentSource))
		|			END
		|		WHEN NOT Adjusting.DocumentBasis IS NULL
		|			THEN Adjusting.DocumentBasis
		|		WHEN DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|			THEN DD.Lot
		|		ELSE DD.Recorder END),
		|	DD.FinancialAccountingDimension,
		|	CASE WHEN DD.Organization IN (&MediumSlipOrganizations)
		|		THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType
		|	END,
		|	CASE WHEN DD.Organization IN (&MediumSlipOrganizations)
		|		THEN DD.DocumentVATActivityType
		|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	END,
		|	(CASE
		|		WHEN DD.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods))
		|		AND DD.OfficialTypeOfMovementParish
		|			THEN DD.LotVendorAttributesCorr
		|		WHEN DD.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|			THEN DD.LotVendorAttributesCorr
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.Lot) AND DD.Count = 0
		|		 AND DD.LotVendorAttributesCorr <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|			THEN DD.LotVendorAttributesCorr
		|		ELSE DD.LotVendorAttributes END),
		|	(CASE
		|		WHEN NOT CorrectedDocuments_.DocumentSource IS NULL
		|		  AND VALUETYPE(CorrectedDocuments_.DocumentSource) <> TYPE(Document.BackflushProduction)
		|			THEN CorrectedDocuments_.DocumentSource
		|		WHEN NOT Adjusting.AdjustmentKind IS NULL
		|		 AND Adjusting.AdjustmentKind <> VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
		|			THEN Adjusting.DocumentBasis
		|		ELSE DD.Recorder END), // DocumentInflow
		|	DD.BusinessOperation,
		|	DD.CorVATActivityTypes,
		|	DD.CorAccountingSection,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorLot,
		|	DD.CorControllingAttributes,
		|	DD.Department,
		|	(CASE
		|		WHEN DD.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|		 AND DD.ExpenseItemOfWriteOff <> UNDEFINED
		|			THEN DD.ExpenseItemOfWriteOff
		|		WHEN DD.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
		|			THEN DD.AssetAndLiabilityItem
		|		ELSE UNDEFINED END),
		|	DD.DimensionOfExpenses,
		|	DD.AssetsLiabilitiesDimension,
		|	(CASE
		|		WHEN NOT DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND Register3.IBDocumentDate < &BeginOfPeriod
		|			THEN UNDEFINED
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
		|		  AND VALUETYPE(DD.Recorder) = TYPE(Document.ApplicationForImportationOfGoods)
		|		  AND VALUETYPE(DD.DimensionOfExpenses) = TYPE(Document.ReceiptOfGoodsToWarehouse)
		|		  AND DD.DimensionOfExpenses <> VALUE(Document.ReceiptOfGoodsToWarehouse.EmptyRef)
		|			THEN DD.DimensionOfExpenses
		|		WHEN DD.Lot <> UNDEFINED
		|		 AND DD.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.CostVariance))
		|			THEN DD.Lot
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN RecordersMediumSlip.Ref
		|		ELSE DD.DocumentSource END),
		|	DD.GLAccountSettings,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.ReversingEntry
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
		|	FALSE AS ThisIsReverseTransaction,
		|	SUM(DD.Count) AS Denominator,
		|	DD.ItemsLocationAttributes.Products AS Products,
		|	DD.LotVendorAttributes.VATTaxation AS TaxationOfParty,
		|	
		|	DD.Period,
		|	CASE WHEN DD.Organization IN (&MediumSlipOrganizations)
		|		THEN RecordersMediumSlip.Ref
		|		ELSE DD.Recorder
		|	END AS Recorder,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	CASE WHEN DD.Organization IN (&MediumSlipOrganizations)
		|		THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE DD.VATActivityType
		|	END AS VATActivityType,
		|	CASE WHEN DD.Organization IN (&MediumSlipOrganizations)
		|		THEN DD.DocumentVATActivityType
		|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	END AS DocumentVATActivityType,
		|
		|	(CASE
		|		WHEN DD.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|			THEN DD.LotVendorAttributesCorr
		|		ELSE DD.LotVendorAttributes END) AS LotVendorAttributes,
		|	DD.Recorder AS DocumentInflow,
		|
		|	SUM(DD.Count) AS Count,
		|	SUM(WriteOffDeviations.AddExpensesLocal
		|		+ CASE
		|			WHEN DD.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|				THEN -WriteOffDeviations.VATLocal
		|			ELSE 0
		|	END) AS CostExcludingVAT,
		|	SUM(WriteOffDeviations.VATLocal) AS VAT,
		|	SUM(CASE
		|		WHEN &CompanyManagementAccounting
		|			THEN WriteOffDeviations.AddExpensesMan
		|		+ CASE
		|			WHEN DD.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|				THEN -WriteOffDeviations.VATManag
		|			ELSE 0
		|		END
		|			ELSE 0
		|		END) AS CostExcludingVATMan,
		|	SUM(CASE
		|		WHEN &CompanyManagementAccounting
		|			THEN WriteOffDeviations.VATManag
		|		ELSE 0
		|	END) AS VATManag,
		|
		|	DD.BusinessOperation,
		|	DD.CorVATActivityTypes,
		|	DD.CorAccountingSection,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorLot,
		|	DD.CorControllingAttributes,
		|	DD.Department,
		|	UNDEFINED AS ExpenseItemAssets,
		|	DD.DimensionOfExpenses,
		|	DD.AssetsLiabilitiesDimension AS DimensionOfAssets,
		|	(CASE
		|		WHEN DD.Lot <> UNDEFINED
		|			THEN DD.Lot
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN RecordersMediumSlip.Ref
		|		ELSE DD.DocumentSource END) AS DocumentSource,
		|	DD.GLAccountSettings,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.ReversingEntry,
		|	MAX(DD.FinRecordID) AS FinRecordID
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	LEFT JOIN TTCostCalculationRecorders AS RecordersMediumSlip
		|		ON DD.Organization = RecordersMediumSlip.Organization
		|	INNER JOIN WriteOffOfCostDeviations AS WriteOffDeviations
		|		ON WriteOffDeviations.Organization = DD.Organization
		|		AND WriteOffDeviations.AccountingSection = DD.AccountingSection
		|		AND WriteOffDeviations.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|		AND WriteOffDeviations.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|		AND WriteOffDeviations.Lot = DD.Lot
		|		AND WriteOffDeviations.FinancialAccountingDimension = DD.FinancialAccountingDimension
		|		AND WriteOffDeviations.VATActivityType = DD.VATActivityType
		|		AND DD.OfficialTypeOfMovementParish
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion22)
		|	AND DD.OfficialTypeOfMovementParish
		|	AND DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
		|	AND CASE WHEN DD.Organization IN (&MediumSlipOrganizations) THEN DD.DocumentVATActivityType ELSE DD.VATActivityType END
		|		<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	AND DD.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND (CASE
		|		WHEN DD.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|			THEN DD.LotVendorAttributesCorr
		|		ELSE DD.LotVendorAttributes END) <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|	AND NOT DD.ReversingEntry
		|GROUP BY
		|	DD.ItemsLocationAttributes.Products,
		|	DD.LotVendorAttributes.VATTaxation,
		|	DD.Period,
		|	CASE WHEN DD.Organization IN (&MediumSlipOrganizations)
		|		THEN RecordersMediumSlip.Ref
		|		ELSE DD.Recorder
		|	END,
		|	DD.Recorder,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	CASE WHEN DD.Organization IN (&MediumSlipOrganizations)
		|		THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE DD.VATActivityType
		|	END,
		|	CASE WHEN DD.Organization IN (&MediumSlipOrganizations)
		|		THEN DD.DocumentVATActivityType
		|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	END,
		|	(CASE
		|		WHEN DD.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|			THEN DD.LotVendorAttributesCorr
		|		ELSE DD.LotVendorAttributes END),
		|	DD.BusinessOperation,
		|	DD.CorVATActivityTypes,
		|	DD.CorAccountingSection,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorLot,
		|	DD.CorControllingAttributes,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.AssetsLiabilitiesDimension,
		|	(CASE
		|		WHEN DD.Lot <> UNDEFINED
		|			THEN DD.Lot
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN RecordersMediumSlip.Ref
		|		ELSE DD.DocumentSource END),
		|	DD.GLAccountSettings,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.ReversingEntry
		|
		|UNION ALL
		|
		// Cost adjustments using the "Medium-slip" valuation method. The amount of adjustments is selected 
		// from the "Deviations in the cost of goods" register.
		|SELECT
		|	DD.EntryType AS EntryType,
		|	FALSE AS ThisIsReverseTransaction,
		|	0 AS Denominator,
		|	DD.ItemsLocationAttributes.Products AS Products,
		|	DD.LotVendorAttributes.VATTaxation AS TaxationOfParty,
		|	
		|	DD.Period,
		|	DD.Recorder AS Recorder,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	(CASE
		|		WHEN NOT Adjusting.DocumentBasis IS NULL
		|			THEN Adjusting.DocumentBasis
		|		ELSE DD.Lot END) AS Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.DocumentVATActivityType AS VATActivityType,
		|	DD.DocumentVATActivityType AS DocumentVATActivityType,
		|
		|	(CASE
		|		WHEN DD.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|			THEN DD.LotVendorAttributesCorr
		|		ELSE DD.LotVendorAttributes END) AS LotVendorAttributes,
		|	(CASE
		|		WHEN NOT Adjusting.AdjustmentKind IS NULL
		|		 AND Adjusting.AdjustmentKind <> VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
		|			THEN Adjusting.DocumentBasis
		|		ELSE DD.Recorder END) AS DocumentInflow,
		|
		|	0 AS Count,
		|	SUM(Variances.CostVariancesLocal) AS CostExcludingVAT,
		|	0 AS VAT,
		|	SUM(Variances.CostVariancesMgmt) AS CostExcludingVATMan,
		|	0 AS VATManag,
		|
		|	DD.BusinessOperation,
		|	DD.CorVATActivityTypes,
		|	DD.CorAccountingSection,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorLot,
		|	DD.CorControllingAttributes,
		|	DD.Department,
		|	UNDEFINED AS ExpenseItemAssets,
		|	DD.DimensionOfExpenses,
		|	DD.AssetsLiabilitiesDimension AS DimensionOfAssets,
		|	RecordersMediumSlip.Ref AS DocumentSource,
		|	DD.GLAccountSettings,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.ReversingEntry,
		|	MAX(DD.FinRecordID) AS FinRecordID
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	LEFT JOIN TTCostCalculationRecorders AS RecordersMediumSlip
		|		ON DD.Organization = RecordersMediumSlip.Organization
		|	INNER JOIN TTCacheEstimatedTurnoverDeviationsInCostOfGoods AS Variances
		|		ON Variances.Recorder = DD.Recorder
		|		AND Variances.Period = DD.Period
		|		AND Variances.OfficialTypeOfMovementParish
		|		AND Variances.Organization = DD.Organization
		|		AND Variances.BusinessOperation = DD.BusinessOperation
		|		AND Variances.BusinessTransactionSetting = DD.BusinessTransactionSetting
		|		AND Variances.FinRecordID = DD.FinRecordID
		|	LEFT JOIN Document.PurchaseAdjustment AS Adjusting
		|		ON Adjusting.Ref = DD.Recorder
		|WHERE
		|	DD.Organization IN (&MediumSlipOrganizations)
		|	AND DD.OfficialTypeOfMovementParish
		|	AND DD.Count = 0
		|	AND NOT DD.ReversingEntry
		|
		|GROUP BY
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes.Products,
		|	DD.LotVendorAttributes.VATTaxation,
		|	DD.Period,
		|	DD.Recorder,
		|	DD.Recorder,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	(CASE
		|		WHEN NOT Adjusting.DocumentBasis IS NULL
		|			THEN Adjusting.DocumentBasis
		|		ELSE DD.Lot END), // Lot
		|	DD.FinancialAccountingDimension,
		|	DD.DocumentVATActivityType,
		|	(CASE
		|		WHEN DD.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|			THEN DD.LotVendorAttributesCorr
		|		ELSE DD.LotVendorAttributes END),
		|	(CASE
		|		WHEN NOT Adjusting.AdjustmentKind IS NULL
		|		 AND Adjusting.AdjustmentKind <> VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
		|			THEN Adjusting.DocumentBasis
		|		ELSE DD.Recorder END), // DocumentInflow
		|	DD.BusinessOperation,
		|	DD.CorVATActivityTypes,
		|	DD.CorAccountingSection,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorLot,
		|	DD.CorControllingAttributes,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.AssetsLiabilitiesDimension,
		|	RecordersMediumSlip.Ref, // DocumentSource
		|	DD.GLAccountSettings,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.ReversingEntry
		|
		|";
EndFunction

#EndRegion


#Region ProceduresOfStage_CalculationOfBatchesOfNDS_AdditionalExpensesAmount

Function DescriptionOfRegisteredRecordsOfPartiesOfNDS_AdditionalExpensesAmount(CalculationParameters)
	
	DistributionTableColumns = TableForDistributionOfVATBatches(CalculationParameters).Columns;
	
	RegisterRecordsDetails = CostCalculationAppliedAlgorithms.RegisterRecordsDetails();
	RegisterRecordsDetails.Insert("Context", "PreparationOfDataForAccountingLBSiUSN_AdditionalExpensesAmount");
	RegisterRecordsDetails.Insert("TempTableName", "TTDetailingOfGoodsBatchesForLBSiUSN_AdditionalExpensesAmount");
	RegisterRecordsDetails.Insert("TemporaryTablesForFollowingSteps", "TTDetailingOfGoodsBatchesForLBSiUSN_AdditionalExpensesAmount,
		|TTAdditionalCostsForDistribution, TTBaseOfDistributionOfAdditionalExpensesInSummary, TTBaseOfAllocationOfAdditionalExpenses");
	
	RegisterRecordsDetails.Insert("CalculationFields", CostCalculationAppliedAlgorithms.ListOfFields(DistributionTableColumns));
	RegisterRecordsDetails.Insert("ComparisonKeys",	VATBatchConsumptionFields(CalculationParameters));
	RegisterRecordsDetails.Insert("Indicators", "Denominator, DenominatorForSources, Count, CostExcludingVAT, VAT, CostExcludingVATMan, VATManag");
	RegisterRecordsDetails.Insert("BasisOfArrival", "Denominator");
	RegisterRecordsDetails.Insert("BasisOfConsumption", "Denominator");
	RegisterRecordsDetails.Insert("ExpenseKey", "DocumentSource");
	RegisterRecordsDetails.Insert("OrderField_", "Period");
	RegisterRecordsDetails.Insert("SortFields", "Lot");
	RegisterRecordsDetails.Insert("SortingByCondition", True);

	RegisterRecordsDetails.Insert("SummationFields", "Count, CostExcludingVAT, VAT, CostExcludingVATMan, VATManag");
	RegisterRecordsDetails.Insert("SummationFieldExceptions", "Denominator, DenominatorForSources");
	RegisterRecordsDetails.Insert("GroupFields", 
		CostCalculationAppliedAlgorithms.ListOfFields(DistributionTableColumns, RegisterRecordsDetails.SummationFields));
	RegisterRecordsDetails.Insert("ThereIsStorno", True);
	RegisterRecordsDetails.Insert("ThereAreFixes", True);
	RegisterRecordsDetails.Insert("ReducingBasis", True);
	RegisterRecordsDetails.Insert("DeleteRowsWithoutSources", True);
	
	Return RegisterRecordsDetails;
	
EndFunction

// Sample data

Procedure ToGetDataForBatchesOfNDS_AdditionalExpenseAmount(CalculationParameters)
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"ItemsLocationAttributes", // Separator
		"Denominator, Count, CostExcludingVAT, VAT, VATManag", // Resources
		"ItemsLocationAttributes, Period, Priority ASC, AccountingSection, Organization, ItemsLocationAttributes, Lot, Recorder"); // Order
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		QueryTextForBatchesOfPersonalIncomeTax_AdditionalExpenseAmount(CalculationParameters),
		NumberingParameters);
	
EndProcedure

// ... data samples

Function QueryTextForBatchesOfPersonalIncomeTax_AdditionalExpenseAmount(CalculationParameters)
	
	ArrayOfRequestTexts = New Array();
	
	If ValueIsFilled(CalculationParameters) Then
		ThereIsTableReceiptsOfGoodsVAT = CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters, "GoodsReceiptsVAT");
	Else
		ThereIsTableReceiptsOfGoodsVAT = False;
	EndIf;

	// Preparation of temp tables.
	If Not ThereIsTableReceiptsOfGoodsVAT Then
		ArrayOfRequestTexts.Add(TextInitializationOfVATBatchesTotal());
		ArrayOfRequestTexts.Add(TextCorrectedVATDocuments());
		ArrayOfRequestTexts.Add(TextOfCorrectionBeforeEnteringBalance());
		ArrayOfRequestTexts.Add(TextGoodsReceiptsVAT());
	EndIf;
	ArrayOfRequestTexts.Add(TextOfAnalyticsOfAccountingOfBatchesOfCustomsDeclarations()); // TTChangeInTypeOfActivityAdditionalExpenseAMOUNT
	ArrayOfRequestTexts.Add(TextAllocationOfAdditionalCosts());
	ArrayOfRequestTexts.Add(TextOfShareOfAdditionalExpensesGiven()); // Uses up to additional expenses
	ArrayOfRequestTexts.Add(TextTTBaseForDistributionOfAdditionalExpenseAmountsWithoutBatches()); // Uses up to the following additional costsreferences
	ArrayOfRequestTexts.Add(TextTTBaseForDistributionOfAdditionalExpenseAmounts()); // Uses vtbasdistributionspendingparty
	ArrayOfRequestTexts.Add(TextTTBaseOfDistributionOfAdditionalExpensesAmountInSummary()); // uses vtbasdistribution of expenses
	QueryText = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	
	ArrayOfRequestTexts = New Array();
	
	// TT Data.
	ArrayOfRequestTexts.Add(TextDescriptionOfDataForLBSiUSNBatches());
	
	
	ArrayOfRequestTexts.Add(TextReceiptsOfCostOfGoodsForAdditionalExpensesAmount()); // uses parishadsresults
	ArrayOfRequestTexts.Add(TextCustomsDeclarationsChangeActivitiesVAT()); // Uses in changing the type of activity and expenses
	ArrayOfRequestTexts.Add(TextAdditionalExpensesAmountAverageForDistributionOfLocal()); // Uses high spending for distribution, vtbasdistribution of high spending
	ArrayOfRequestTexts.Add(TextBaseAdditionalExpensesAmountAverageLocal()); // uses vtbasdistribution of expenses
	ArrayOfRequestTexts.Add(TextAdditionalExpensesAmountAverageForDistributionOfMan()); // Uses high spending for distribution, vtbasdistribution of high spending
	ArrayOfRequestTexts.Add(TextBaseAdditionalExpensesAmountAverageMan()); // uses vtbasdistribution of expenses


	QueryText = QueryText
		+ Common.QueryBatchSeparator()
		+ StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	Return QueryText;
EndFunction

Function TextOfShareOfAdditionalExpensesGiven() // Up to the additional costsreduced, uses up to the additional cost
	Return "
	|SELECT
	|	T.Recorder,
	|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	T.CorAccountingSection,
	|	T.CorInventoryOwnerAttribute,
	|	T.CorCompany AS CorCompany,
	|	T.CorLot AS CorLot,
	|	T.LotVendorAttributesCorr,
	|	T.CorControllingAttributes,
	|	T.CorVATActivityTypes,
	|	T.BusinessOperation,
	|	T.EntryType,
	|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ISNULL(T.SalesOrder, UNDEFINED) AS SalesOrder,
	|	T.Count,
	|	CAST(T.Count / SUM(Totals.Count) AS NUMBER(31,10)) AS ZoomRatio
	|INTO SharesOfAdditionalExpensesGiven
	|FROM
	|	SharesOfAdditionalExpenses AS T
	|	INNER JOIN SharesOfAdditionalExpenses AS Totals
	|		ON T.Recorder = Totals.Recorder
	|		AND T.CorItemsLocationAttributes = Totals.CorItemsLocationAttributes
	|		AND T.CorAccountingSection = Totals.CorAccountingSection
	|		AND T.CorInventoryOwnerAttribute = Totals.CorInventoryOwnerAttribute
	|		AND T.CorCompany = Totals.CorCompany
	|		AND T.CorLot = Totals.CorLot
	|		AND T.LotVendorAttributesCorr = Totals.LotVendorAttributesCorr
	|		AND T.CorControllingAttributes = Totals.CorControllingAttributes
	|		AND T.CorVATActivityTypes = Totals.CorVATActivityTypes
	|		AND T.EntryType = Totals.EntryType
	|		AND T.AccountingDimensionByPartners = Totals.AccountingDimensionByPartners
	|		AND T.SalesOrder = Totals.SalesOrder
	|GROUP BY
	|	T.Recorder,
	|	T.CorItemsLocationAttributes,
	|	T.CorAccountingSection,
	|	T.CorInventoryOwnerAttribute,
	|	T.CorCompany,
	|	T.CorLot,
	|	T.LotVendorAttributesCorr,
	|	T.CorControllingAttributes,
	|	T.CorVATActivityTypes,
	|	T.BusinessOperation,
	|	T.EntryType,
	|	T.AccountingDimensionByPartners,
	|	ISNULL(T.SalesOrder, UNDEFINED),
	|	T.Count
	|
	|HAVING
	|    SUM(Totals.Count) <> 0
	|INDEX BY
	|	CorItemsLocationAttributes,
	|	CorCompany,
	|	CorLot
	|";
EndFunction

Function TextTTBaseForDistributionOfAdditionalExpenseAmountsWithoutBatches() // VTBASDISTRIBUTION of non-party spending, uses up to additional spending
	Return "
	|SELECT
	|	1 AS RequestSource,
	|	CASE WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods) THEN TRUE ELSE FALSE END AS ForDisposal,
	|	DD.Period,
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.AccountingSection,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.FinancialAccountingDimension,
	|	DD.VATActivityType,
	|	DD.EntryType,
	|	UNDEFINED AS CorExpenseItem,
	|	UNDEFINED AS CorExpenditureDimension,
	|	UNDEFINED AS DebitBusinessUnit,
	|	ISNULL(DD.ItemsLocationAttributes.Purpose.LineOfBusiness, UNDEFINED) AS CorLineOfBusiness,
	|	DocumentDistributions.Department,
	|	DocumentDistributions.ExpenseItem,
	|	DocumentDistributions.DimensionOfExpenses,
	|	DocumentDistributions.LineOfBusiness,
	|	DD.FinRecordID,
	|	Shares.BusinessOperation,
	|	(CASE
	|		WHEN Register3.Ref IS NULL THEN FALSE
	|		ELSE TRUE END) AS SpecifiedDocumentInExpenseAnalytics,			
	|	
	|	CAST(SUM(CASE
	|		WHEN DD.AddExpensesLocal <> 0 THEN DD.AddExpensesLocal
	|		WHEN DD.AdditionalExpensesExcludingVAT <> 0 THEN DD.AdditionalExpensesExcludingVAT
	|		ELSE DD.AddExpensesForGoods END * ISNULL(Shares.ZoomRatio, 1)) AS NUMBER(31,2)) AS LocalDenominator,
	|	CAST(SUM(CASE
	|		WHEN DD.AddExpensesMan <> 0 THEN DD.AddExpensesMan
	|		WHEN DD.AdditionalExpensesExcludingVAT <> 0 THEN DD.AdditionalExpensesExcludingVAT
	|		ELSE DD.AddExpensesForGoods END * ISNULL(Shares.ZoomRatio, 1)) AS NUMBER(31,2)) AS DenominatorOfMan,
	|	SUM(ISNULL(Shares.Count, 1)) AS Count
	|INTO TTBaseOfDistributionOfAdditionalExpensesWithoutLots
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS DD
	|	INNER JOIN Document.AllocationOfOtherCosts AS DocumentDistributions
	|		ON DD.Recorder = DocumentDistributions.Ref
	|	INNER JOIN TTOrganizationsForAllocationOfVATSurcharges AS Companies
	|		ON DD.Organization = Companies.Ref
	|	LEFT JOIN SharesOfAdditionalExpensesGiven AS Shares
	|		ON Shares.Recorder = DD.Recorder
	|		AND Shares.CorItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND Shares.CorAccountingSection = DD.AccountingSection
	|		AND Shares.CorInventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|		AND Shares.CorCompany = DD.Organization
	|		AND Shares.CorLot = DD.Lot
	|		AND Shares.LotVendorAttributesCorr = DD.LotVendorAttributes
	|		AND Shares.CorControllingAttributes = DD.FinancialAccountingDimension
	|		AND Shares.CorVATActivityTypes = DD.VATActivityType
	|		AND Shares.AccountingDimensionByPartners = DD.AccountingDimensionByPartners
	|		AND Shares.SalesOrder = DD.SalesOrder
	|		AND (Shares.EntryType = DD.EntryType
	|			OR DD.EntryType = VALUE(Enum.LotRecordTypes.Supplement))
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Register3.Ref = DD.DimensionOfExpenses
	|		AND NOT Register3.AdditionalRecord
	|WHERE
	|	DD.OfficialTypeOfMovementParish
	|	AND DD.EntryType IN (
	|		VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
	|		VALUE(Enum.LotRecordTypes.Supplement),
	|		VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods))
	|
	|GROUP BY
	|	CASE WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods) THEN TRUE ELSE FALSE END,
	|	DD.Period,
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.AccountingSection,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.FinancialAccountingDimension,
	|	DD.VATActivityType,
	|	DD.EntryType,
	|	ISNULL(DD.ItemsLocationAttributes.Purpose.LineOfBusiness, UNDEFINED),
	|	DocumentDistributions.Department,
	|	DocumentDistributions.ExpenseItem,
	|	DocumentDistributions.DimensionOfExpenses,
	|	DocumentDistributions.LineOfBusiness,
	|	DD.FinRecordID,
	|	Shares.BusinessOperation,
	|	(CASE
	|		WHEN Register3.Ref IS NULL THEN FALSE
	|		ELSE TRUE END)
	|
	|UNION ALL
	|
	// The distribution base, if the cost of additional expenses includes only item-by-item costs.
	|SELECT
	|	2 AS RequestSource,
	|	CASE
	|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
	|			THEN TRUE
	|		ELSE FALSE END AS ForDisposal,
	|	DocumentDistributions.Date AS Period,
	|	DD.Recorder,
	|	DocumentDistributions.Organization,
	|	DD.CorItemsLocationAttributes AS ItemsLocationAttributes,
	|	DD.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DD.CorAccountingSection AS AccountingSection,
	|	DD.CorLot AS Lot,
	|	DD.LotVendorAttributesCorr AS LotVendorAttributes,
	|	DD.CorControllingAttributes AS FinancialAccountingDimension,
	|	DD.CorVATActivityTypes AS VATActivityType,
	|	DD.EntryType,
	|	UNDEFINED AS CorExpenseItem,
	|	UNDEFINED AS CorExpenditureDimension,
	|	UNDEFINED AS DebitBusinessUnit,
	|	ISNULL(DD.CorItemsLocationAttributes.Purpose.LineOfBusiness, UNDEFINED) AS CorLineOfBusiness,
	|	DocumentDistributions.Department,
	|	DocumentDistributions.ExpenseItem,
	|	DocumentDistributions.DimensionOfExpenses,
	|	DocumentDistributions.LineOfBusiness,
	|	"""" AS FinRecordID,
	|	DD.BusinessOperation,
	|	(CASE
	|		WHEN Register3.Ref IS NULL THEN FALSE
	|		ELSE TRUE END) AS SpecifiedDocumentInExpenseAnalytics,			
	|	
	|	DD.ShareOfLocalValue AS LocalDenominator,
	|	DD.ShareOfManSCost AS DenominatorOfMan,
	|	DD.Count AS Count
	|FROM
	|	SharesOfAdditionalExpenses AS DD
	|	INNER JOIN Document.AllocationOfOtherCosts AS DocumentDistributions
	|		ON DD.Recorder = DocumentDistributions.Ref
	|	INNER JOIN TTOrganizationsForAllocationOfVATSurcharges AS Companies
	|		ON DocumentDistributions.Organization = Companies.Ref
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Register3.Ref = DocumentDistributions.DimensionOfExpenses
	|		AND NOT Register3.AdditionalRecord
	|	LEFT JOIN TTCashEstimatedTurnoverCostOfGoods AS Cost_
	|		ON Cost_.Recorder = DD.Recorder
	|WHERE
	|	DD.EntryType IN (
	|		VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
	|		VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods))
	|	AND DocumentDistributions.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
	|	AND (DD.CorExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		OR DD.CorExpenseItem = UNDEFINED)
	|	AND Cost_.Recorder IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	3 AS RequestSource,
	|	FALSE AS ForDisposal,
	|	DD.Period,
	|	DD.Recorder,
	|	DD.Organization,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
	|	UNDEFINED AS Lot,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	UNDEFINED AS FinancialAccountingDimension,
	|	CASE WHEN CorItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|		THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		ELSE ISNULL(UninvoicedReceipt.PurchaseForActivity, ReceiptOfServices.PurchaseForActivity)
	|	END AS VATActivityType,
	|	VALUE(Enum.LotRecordTypes.AddExpensesForGoods) AS EntryType,
	|	DD.CorExpenseItem AS CorExpenseItem,
	|	DD.CorExpenditureDimension AS CorExpenditureDimension,
	|	DD.DebitBusinessUnit AS DebitBusinessUnit,
	|	DD.CorLineOfBusiness AS CorLineOfBusiness,
	|	DocumentDistributions.Department,
	|	DocumentDistributions.ExpenseItem,
	|	DocumentDistributions.DimensionOfExpenses,
	|	DocumentDistributions.LineOfBusiness,
	|	DD.FinRecordID,
	|	UNDEFINED AS BusinessOperation,
	|	(CASE
	|		WHEN Register3.Ref IS NULL THEN FALSE
	|		ELSE TRUE END) AS SpecifiedDocumentInExpenseAnalytics,
	|	
	|	SUM(CASE
	|		WHEN DD.SumCompl <> 0 THEN DD.SumCompl
	|		ELSE DD.Sum END) AS LocalDenominator,
	|	SUM(CASE
	|		WHEN DD.SumMan <> 0 THEN DD.SumMan
	|		ELSE DD.Sum END) AS DenominatorOfMan,
	|	SUM(ISNULL(CASE WHEN Shares.ShareOfLocalValue = 0 THEN Shares.ShareOfManSCost ELSE Shares.ShareOfLocalValue END, 0)) AS Count
	|FROM
	|	TTCashEstimatedTurnoverOtherExpenses AS DD
	|	INNER JOIN Document.AllocationOfOtherCosts AS DocumentDistributions
	|		ON DD.Recorder = DocumentDistributions.Ref
	|	INNER JOIN TTOrganizationsForAllocationOfVATSurcharges AS Companies
	|		ON DD.Organization = Companies.Ref
	|	LEFT JOIN SharesOfAdditionalExpenses AS Shares
	|		ON Shares.Recorder = DD.Recorder
	|		AND Shares.CorExpenseItem = DD.CorExpenseItem
	|		AND Shares.CorExpenditureDimension = DD.CorExpenditureDimension
	|		AND Shares.DebitBusinessUnit = DD.DebitBusinessUnit
	|		AND Shares.CorLineOfBusiness = DD.CorLineOfBusiness
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Register3.Ref = DD.DimensionOfExpenses
	|		AND NOT Register3.AdditionalRecord
	|	LEFT JOIN Document.VendorInvoice AS UninvoicedReceipt
	|		ON UninvoicedReceipt.Ref = DocumentDistributions.DimensionOfExpenses
	|	LEFT JOIN Document.VendorInvoiceServicesAndAssets AS ReceiptOfServices
	|		ON ReceiptOfServices.Ref = DocumentDistributions.DimensionOfExpenses
	|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS CorItem
	|		ON CorItem.Ref = DD.CorExpenseItem
	|WHERE
	|	NOT DD.OfficialTypeOfMovementParish
	|	AND (DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
	|		OR DD.CorExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))
	|
	|GROUP BY
	|	DD.Period,
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.CorExpenseItem,
	|	DD.CorExpenditureDimension,
	|	DD.DebitBusinessUnit,
	|	DD.CorLineOfBusiness,
	|	CASE WHEN CorItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|		THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		ELSE ISNULL(UninvoicedReceipt.PurchaseForActivity, ReceiptOfServices.PurchaseForActivity)
	|	END, // VATActivityType
	|	DocumentDistributions.Department,
	|	DocumentDistributions.ExpenseItem,
	|	DocumentDistributions.DimensionOfExpenses,
	|	DocumentDistributions.LineOfBusiness,
	|	DD.FinRecordID,
	|	(CASE
	|		WHEN Register3.Ref IS NULL THEN FALSE
	|		ELSE TRUE END)
	|
	|UNION ALL
	|
	|SELECT
	|	4 AS RequestSource,
	|	TRUE AS ForDisposal,
	|	DD.Period,
	|	DD.Recorder,
	|	DD.Organization,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
	|	UNDEFINED AS Lot,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	UNDEFINED AS FinancialAccountingDimension,
	|	CASE WHEN ExpenseItems.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|		THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		ELSE ISNULL(UninvoicedReceipt.PurchaseForActivity, ReceiptOfServices.PurchaseForActivity)
	|	END AS VATActivityType,
	|	VALUE(Enum.LotRecordTypes.AddExpensesForGoods) AS EntryType,
	|	DD.CorExpenseItem AS CorExpenseItem,
	|	DD.CorExpenditureDimension AS CorExpenditureDimension,
	|	DD.DebitBusinessUnit AS DebitBusinessUnit,
	|	DD.CorLineOfBusiness AS CorLineOfBusiness,
	|	DD.Department,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.LineOfBusiness,
	|	DD.FinRecordID,
	|	DD.BusinessOperation,
	|	CASE WHEN Register3.Ref IS NULL
	|		THEN FALSE
	|		ELSE TRUE
	|	END AS SpecifiedDocumentInExpenseAnalytics,
	|	
	|	SUM(CASE
	|		WHEN DD.SumCompl <> 0 THEN DD.SumCompl
	|		ELSE DD.Sum END) AS LocalDenominator,
	|	SUM(CASE
	|		WHEN DD.SumMan <> 0 THEN DD.SumMan
	|		ELSE DD.Sum END) AS DenominatorOfMan,
	|	SUM(CASE
	|		WHEN DD.SumCompl > 0 THEN DD.SumCompl
	|		WHEN DD.SumCompl < 0 THEN -DD.SumCompl
	|		WHEN DD.SumMan > 0 THEN DD.SumMan
	|		WHEN DD.SumMan < 0 THEN -DD.SumMan
	|		WHEN DD.Sum > 0 THEN DD.Sum
	|		ELSE -DD.Sum END) AS Count
	|FROM
	|	TTCashEstimatedTurnoverOtherExpenses AS DD
	|	INNER JOIN TTOrganizationsForAllocationOfVATSurcharges AS Companies
	|		ON DD.Organization = Companies.Ref
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Register3.Ref = DD.DimensionOfExpenses
	|		AND NOT Register3.AdditionalRecord
	|	INNER JOIN TTAnalyticsOfDistributionOfPastPeriods AS AnalystsOfPastPeriods
	|		ON DD.Organization = AnalystsOfPastPeriods.Organization
	|			AND DD.Department = AnalystsOfPastPeriods.Department
	|			AND DD.LineOfBusiness = AnalystsOfPastPeriods.LineOfBusiness
	|			AND DD.ExpenseItem = AnalystsOfPastPeriods.ExpenseItem
	|			AND DD.DimensionOfExpenses = AnalystsOfPastPeriods.DimensionOfExpenses
	|	LEFT JOIN Document.VendorInvoice AS UninvoicedReceipt
	|		ON UninvoicedReceipt.Ref = DD.DimensionOfExpenses
	|	LEFT JOIN Document.VendorInvoiceServicesAndAssets AS ReceiptOfServices
	|		ON ReceiptOfServices.Ref = DD.DimensionOfExpenses
	|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Ref = DD.ExpenseItem
	|WHERE
	|	NOT DD.OfficialTypeOfMovementParish
	|	AND DD.Recorder REFS Document.CostCalculationRecorder
	|	AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.WriteOffVariancesToAllocate)
	|
	|GROUP BY
	|	DD.Period,
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.CorExpenseItem,
	|	DD.CorExpenditureDimension,
	|	DD.DebitBusinessUnit,
	|	DD.CorLineOfBusiness,
	|	CASE WHEN ExpenseItems.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|		THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		ELSE ISNULL(UninvoicedReceipt.PurchaseForActivity, ReceiptOfServices.PurchaseForActivity)
	|	END, // VATActivityType
	|	DD.Department,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.LineOfBusiness,
	|	DD.FinRecordID,
	|	DD.BusinessOperation,
	|	CASE WHEN Register3.Ref IS NULL
	|		THEN FALSE
	|		ELSE TRUE
	|	END
	|";
EndFunction

Function TextTTBaseForDistributionOfAdditionalExpenseAmounts() // vtbazaradistributionspend, uses vtbazaradistributionspendsparties
	Return "
	|SELECT
	|	DD.ForDisposal,
	|	DD.Period,
	|	DD.Recorder,
	|	DD.Organization AS Organization,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.AccountingSection,
	|	DD.FinancialAccountingDimension,
	|	DD.VATActivityType,
	|	DD.CorExpenseItem,
	|	DD.CorExpenditureDimension,
	|	DD.DebitBusinessUnit,
	|	DD.CorLineOfBusiness,
	|	DD.Department AS Department,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.SpecifiedDocumentInExpenseAnalytics,
	|	CASE WHEN FALSE THEN UNDEFINED // for easy tag placement
	|		WHEN DD.Organization IN (&OrganizationsIncludingVATLotsVersion22) AND NOT Lots.Lot IS NULL
	|			THEN Lots.Lot
	|		WHEN DD.Organization IN (&OrganizationsIncludingVATLotsVersion22) AND DD.SpecifiedDocumentInExpenseAnalytics
	|			THEN DD.DimensionOfExpenses
	|		ELSE DD.Lot
	|	END AS Lot,
	|	CASE WHEN FALSE THEN UNDEFINED // for easy tag placement
	|		WHEN DD.Organization IN (&OrganizationsIncludingVATLotsVersion22)
	|			THEN ISNULL(Lots.LotVendorAttributes, DD.LotVendorAttributes)
	|		ELSE DD.LotVendorAttributes
	|	END AS LotVendorAttributes,
	|	DD.EntryType,
	|	DD.FinRecordID,
	|	DD.BusinessOperation,
	|	
	|	CAST(CASE WHEN DD.LocalDenominator < 0 THEN -DD.LocalDenominator ELSE DD.LocalDenominator END AS NUMBER(31,3)) AS LocalDenominator,
	|	CAST(CASE WHEN DD.DenominatorOfMan < 0 THEN -DD.DenominatorOfMan ELSE DD.DenominatorOfMan END AS NUMBER(31,3)) AS DenominatorOfMan,
	|	CASE WHEN DD.LocalDenominator < 0 THEN -1 ELSE 1 END AS SignLocal,
	|	CASE WHEN DD.DenominatorOfMan < 0 THEN -1 ELSE 1 END AS SignMan,
	|	CAST(DD.Count AS NUMBER(31,3)) AS Count
	|INTO TTBaseOfAllocationOfAdditionalExpenses
	|FROM
	|	TTBaseOfDistributionOfAdditionalExpensesWithoutLots AS DD
	|	LEFT JOIN GoodsReceiptsVAT AS Lots
	|		ON DD.DimensionOfExpenses = Lots.Recorder
	|		AND DD.ItemsLocationAttributes = Lots.ItemsLocationAttributes
	|		AND DD.InventoryOwnerAttribute = Lots.InventoryOwnerAttribute
	|		AND DD.Organization = Lots.Organization
	|";
EndFunction

Function TextTTBaseOfDistributionOfAdditionalExpensesAmountInSummary() // vtbazarasdistributionspendings, uses VTBazaRasdistributiOnsPendings
	Return "
	|SELECT
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	SUM(DD.SignLocal * DD.LocalDenominator) AS LocalDenominator,
	|	SUM(DD.SignMan * DD.DenominatorOfMan) AS DenominatorOfMan,
	|	MAX(DD.FinRecordID) AS FinRecordID
	|INTO TTBaseOfDistributionOfAdditionalExpensesInSummary
	|FROM
	|	TTBaseOfAllocationOfAdditionalExpenses AS DD
	|GROUP BY
	|	DD.Organization,
	|	DD.Department,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.LineOfBusiness
	|INDEX BY
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	Department,
	|	Organization,
	|	LineOfBusiness
	|";
EndFunction

Function TextReceiptsOfCostOfGoodsForAdditionalExpensesAmount() // uses parishadsresults
	Return
		"SELECT
		|	""TextReceiptsOfCostOfGoodsForAdditionalExpensesAmount"" AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.LotsToAllocate) AS EntryType,
		|	MAX(CASE
		|		WHEN DD.Count < 0 THEN TRUE
		|		ELSE FALSE END) AS ThisIsReverseTransaction,
		|	0 AS Priority,
		|	MAX(DD.Count) AS Denominator,
		|	0 AS DenominatorForSources,
		|	FALSE AS CalculationIsCompleted,
		|	DD.Products,
		|	UNDEFINED AS TaxationOfParty,
		|	
		|	DD.Period AS Period,
		|	UNDEFINED AS Recorder,
		|	VALUE(Document.CostCalculationRecorder.EmptyRef) AS CostLogger,
		|	UNDEFINED AS RecordType,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE DD.VATActivityType END) AS VATTaxationOfCostOfActivity,
		|
		|	UNDEFINED AS LotVendorAttributes,
		|	UNDEFINED AS DocumentInflow,
		|
		|	0 AS Count,
		|	0 AS CostExcludingVAT,
		|	0 AS VAT,
		|	0 AS CostExcludingVATMan,
		|	0 AS VATManag,
		|
		|	UNDEFINED AS BusinessOperation,
		|	UNDEFINED AS CorVATActivityTypes,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	UNDEFINED AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS CorControllingAttributes,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS ExpenseItemAssets,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS DimensionOfAssets,
		|	UNDEFINED AS CorExpenseItem,
		|	UNDEFINED AS CorExpenditureDimension,
		|	UNDEFINED AS DebitBusinessUnit,
		|	DD.Lot AS DocumentSource,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.Lot END) AS DocumentSourceOfCost,
		|	UNDEFINED AS VATWriteOffItem,
		|	UNDEFINED AS DimensionVATWriteOff,
		|	UNDEFINED AS LineOfBusiness,
		|	UNDEFINED AS CorLineOfBusiness,
		|	DD.DocumentVATActivityType,
		|	DD.GLAccountSettings,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.ReversingEntry,
		|	MAX(DD.FinRecordID) AS FinRecordID
		|FROM
		|	GoodsReceiptsVAT AS DD
		|WHERE
		|	DD.Count <> 0
		|GROUP BY
		|	DD.Products,
		|	DD.Period,
		|	DD.RecordType,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE DD.VATActivityType END), // VATTaxationOfCostOfActivity
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.Lot END), // DocumentSourceOfCost
		|	DD.DocumentVATActivityType,
		|	DD.GLAccountSettings,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.ReversingEntry
		|";
EndFunction

Function TextCustomsDeclarationsChangeActivitiesVAT()
	Return
		"SELECT
		|	""TextCustomsDeclarationsChangeActivitiesVAT"" AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.InclusionExclusionOfVATInCost) AS EntryType,
		|	FALSE AS ThisIsReverseTransaction,
		|	0 AS Priority,
		|	0 AS Denominator,
		|	0 AS DenominatorForSources,
		|	TRUE AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products AS Products,
		|	UNDEFINED AS TaxationOfParty,
		|	
		|	DD.Period,
		|	DD.Recorder,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.Recorder END) AS CostLogger,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	(CASE
		|		WHEN DD.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN DD.Lot
		|		ELSE DD.DocumentSource END) AS Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.CorVATActivityTypes AS VATActivityType,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE DD.CorVATActivityTypes END) AS VATTaxationOfCostOfActivity,
		|
		|	DD.LotVendorAttributesCorr AS LotVendorAttributes,
		|	DD.Recorder AS DocumentInflow,
		|
		|	0 AS Count,
		|	0 AS CostExcludingVAT,
		|	DD.VATLocal AS VAT,
		|	0 AS CostExcludingVATMan,
		|	(CASE
		|		WHEN &CompanyManagementAccounting THEN DD.VATManag
		|		ELSE 0 END) AS VATManag,
		|
		|	DD.BusinessOperation,
		|	UNDEFINED AS CorVATActivityTypes,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	UNDEFINED AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS CorControllingAttributes,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS ExpenseItemAssets,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS DimensionOfAssets,
		|	UNDEFINED AS CorExpenseItem,
		|	UNDEFINED AS CorExpenditureDimension,
		|	UNDEFINED AS DebitBusinessUnit,
		|	DD.DocumentSource,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.DocumentSource END) AS DocumentSourceOfCost,
		|	UNDEFINED AS VATWriteOffItem,
		|	UNDEFINED AS DimensionVATWriteOff,
		|	UNDEFINED AS LineOfBusiness,
		|	UNDEFINED AS CorLineOfBusiness,
		|	DD.VATActivityType AS DocumentVATActivityType,
		|	UNDEFINED AS GLAccountSettings,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	FALSE AS ReversingEntry,
		|	DD.FinRecordID AS FinRecordID
		|FROM
		|	TTChangeInTypeOfActivityAdditionalExpenseAMOUNT AS DD
		|
		|UNION ALL
		|
		|SELECT
		|	""TextCustomsDeclarationsChangeActivitiesVAT"" AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.InclusionExclusionOfVATInCost) AS EntryType,
		|	FALSE AS ThisIsReverseTransaction,
		|	0 AS Priority,
		|	0 AS Denominator,
		|	0 AS DenominatorForSources,
		|	TRUE AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products AS Products,
		|	UNDEFINED AS TaxationOfParty,
		|	
		|	DD.Period,
		|	DD.Recorder,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.Recorder END) AS CostLogger,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	(CASE
		|		WHEN DD.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN DD.Lot
		|		ELSE DD.DocumentSource END) AS Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.CorVATActivityTypes AS VATActivityType,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE DD.CorVATActivityTypes END) AS VATTaxationOfCostOfActivity,
		|
		|	DD.LotVendorAttributesCorr AS LotVendorAttributes,
		|	DD.Recorder AS DocumentInflow,
		|
		|	0 AS Count,
		|	0 AS CostExcludingVAT,
		|	DD.VATLocal AS VAT,
		|	0 AS CostExcludingVATMan,
		|	(CASE
		|		WHEN &CompanyManagementAccounting THEN DD.VATManag
		|		ELSE 0 END) AS VATManag,
		|
		|	DD.BusinessOperation,
		|	DD.VATActivityType AS CorVATActivityTypes,
		|	DD.AccountingSection AS CorAccountingSection,
		|	DD.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	DD.Organization AS CorCompany,
		|	DD.Lot AS CorLot,
		|	DD.CorControllingAttributes,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS ExpenseItemAssets,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS DimensionOfAssets,
		|	UNDEFINED AS CorExpenseItem,
		|	UNDEFINED AS CorExpenditureDimension,
		|	UNDEFINED AS DebitBusinessUnit,
		|	DD.DocumentSource,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.DocumentSource END) AS DocumentSourceOfCost,
		|	UNDEFINED AS VATWriteOffItem,
		|	UNDEFINED AS DimensionVATWriteOff,
		|	UNDEFINED AS LineOfBusiness,
		|	DD.CorLineOfBusiness,
		|	DD.VATActivityType AS DocumentVATActivityType,
		|	UNDEFINED AS GLAccountSettings,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	FALSE AS ReversingEntry,
		|	DD.FinRecordID AS FinRecordID
		|FROM
		|	TTChangeInTypeOfActivityAdditionalExpenseAMOUNT AS DD
		|";
EndFunction

Function TextAdditionalExpensesAmountAverageForDistributionOfLocal() // Uses high spending for distribution, vtbasdistribution of high spending
	Return
		"SELECT
		|	""TextAdditionalExpensesAmountAverageForDistributionOfLocal"" AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.AdditionalExpensesForAllocationLocal) AS EntryType,
		|	CASE WHEN MAX(Base.LocalDenominator) < 0 THEN TRUE ELSE FALSE END AS ThisIsReverseTransaction,
		|	0 											AS Priority,
		|	MAX(Base.LocalDenominator) 				AS Denominator,
		|	0											AS DenominatorForSources,
		|	TRUE 										AS CalculationIsCompleted,
		|	
		|	UNDEFINED 								AS Products,
		|	UNDEFINED 								AS TaxationOfParty,
		|
		|	CASE WHEN SUM(DD.LocalDenominator) < 0 THEN &EndOfPreviousPeriod ELSE DD.Period END AS Period,
		|	DD.Recorder,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.Recorder END) AS CostLogger,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DD.Organization,
		|	UNDEFINED AS AccountingSection,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	UNDEFINED AS InventoryOwnerAttribute,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	DD.VATActivityType AS VATActivityType,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE DD.VATActivityType END) AS VATTaxationOfCostOfActivity,
		|	DD.LotVendorAttributesOfReceiptDocument AS LotVendorAttributes,
		|	DD.DocumentInflow,
		|
		|	0 AS Count,
		|	DD.LocalCost AS CostExcludingVAT,
		|	DD.VATLocal AS VAT,
		|	CASE WHEN DD.VATManag = 0 THEN DD.CostExcludingVATMan ELSE 0 END AS CostExcludingVATMan,
		|	0 AS VATManag,
		|
		|	DD.BusinessOperation,
		|	DD.VATActivityType AS CorVATActivityTypes,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS CorControllingAttributes,
		|	DD.Department AS Department,
		|	DD.ExpenseItem AS ExpenseItemAssets,
		|	DD.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS DimensionOfAssets,
		|	UNDEFINED AS CorExpenseItem,
		|	UNDEFINED AS CorExpenditureDimension,
		|	UNDEFINED AS DebitBusinessUnit,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS DocumentSourceOfCost,
		|	UNDEFINED AS VATWriteOffItem,
		|	UNDEFINED AS DimensionVATWriteOff,
		|	DD.LineOfBusiness,
		|	DD.LineOfBusiness AS CorLineOfBusiness,
		|	DD.VATActivityType AS DocumentVATActivityType,
		|	UNDEFINED AS GLAccountSettings,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	FALSE AS ReversingEntry,
		|	MAX(Base.FinRecordID) AS FinRecordID
		|FROM
		|	TTAdditionalCostsForDistribution AS DD
		|	INNER JOIN TTBaseOfDistributionOfAdditionalExpensesInSummary AS Base
		|		ON DD.Organization = Base.Organization
		|		AND DD.Department = Base.Department
		|		AND DD.LineOfBusiness = Base.LineOfBusiness
		|		AND DD.ExpenseItem = Base.ExpenseItem
		|		AND DD.DimensionOfExpenses = Base.DimensionOfExpenses
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion22)
		|	AND Base.LocalDenominator <> 0
		|	AND (DD.LocalCost <> 0 OR DD.VATLocal <> 0)
		|
		|GROUP BY
		|	DD.Period,
		|	DD.Recorder,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.Recorder END), // CostLogger
		|	DD.Organization,
		|	DD.VATActivityType,
		|	DD.DocumentInflow,
		|	DD.LotVendorAttributesOfReceiptDocument,
		|	DD.LineOfBusiness,
		|	DD.LocalCost,
		|	DD.VATLocal,
		|	CASE WHEN DD.VATManag = 0 THEN DD.CostExcludingVATMan ELSE 0 END,
		|	DD.BusinessOperation,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.Department
		|";
EndFunction

Function TextBaseAdditionalExpensesAmountAverageLocal()
	Return
		"SELECT
		|	""TextBaseAdditionalExpensesAmountAverageLocal"" AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.BaseAdditionalExpensesLocal) AS EntryType,
		|	FALSE AS ThisIsReverseTransaction,
		|	CASE WHEN DD.SignLocal = -1 THEN 0 ELSE 10 END AS Priority,
		|	SUM(DD.Count)						AS Denominator,
		|	SUM(DD.LocalDenominator)					AS DenominatorForSources,
		|	FALSE 										AS CalculationIsCompleted,
		|	
		|	CAST(DD.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products AS Products,
		|	CAST(DD.LotVendorAttributes AS Catalog.KeysForLotVendorAttributes).VATTaxation 		AS TaxationOfParty,
		|
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.Recorder END) AS CostLogger,
		|	UNDEFINED AS RecordType,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot AS Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType AS VATActivityType,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE DD.VATActivityType END) AS VATTaxationOfCostOfActivity,
		|	DD.LotVendorAttributes,
		|	UNDEFINED AS DocumentInflow,
		|
		|	0 AS Count,
		|	0 AS CostExcludingVAT,
		|	0 AS VAT,
		|	0 AS CostExcludingVATMan,
		|	0 AS VATManag,
		|
		|	CASE WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|	 AND DD.BusinessOperation <> UNDEFINED
		|	 AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.EmptyRef)
		|			THEN DD.BusinessOperation
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|			THEN VALUE(Enum.BusinessTransactions.ExpenseAllocationToCost)
		|		ELSE UNDEFINED
		|	END AS BusinessOperation,
		|	UNDEFINED AS CorVATActivityTypes,
		|	DD.AccountingSection AS CorAccountingSection,
		|	DD.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS CorControllingAttributes,
		|	DD.Department AS Department,
		|	DD.ExpenseItem AS ExpenseItemAssets,
		|	DD.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS DimensionOfAssets,
		|	DD.CorExpenseItem,
		|	DD.CorExpenditureDimension,
		|	DD.DebitBusinessUnit,
		|	(CASE
		|		WHEN DD.SpecifiedDocumentInExpenseAnalytics THEN DD.DimensionOfExpenses
		|		ELSE UNDEFINED END) AS DocumentSource,
		|	(CASE
		|		WHEN DD.SpecifiedDocumentInExpenseAnalytics THEN DD.DimensionOfExpenses
		|		ELSE UNDEFINED END) AS DocumentSourceOfCost,
		|	UNDEFINED AS VATWriteOffItem,
		|	UNDEFINED AS DimensionVATWriteOff,
		|	DD.LineOfBusiness,
		|	DD.CorLineOfBusiness,
		|	DD.VATActivityType AS DocumentVATActivityType,
		|	UNDEFINED AS GLAccountSettings,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	FALSE AS ReversingEntry,
		|	MAX(DD.FinRecordID) AS FinRecordID
		|FROM
		|	TTBaseOfAllocationOfAdditionalExpenses AS DD
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion22)
		|	AND DD.LocalDenominator <> 0
		|GROUP BY
		|	DD.Period,
		|	DD.Recorder,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.Recorder END), // CostLogger
		|	CASE WHEN DD.SignLocal = -1 THEN 0 ELSE 10 END,
		|	CAST(DD.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products,
		|	CAST(DD.LotVendorAttributes AS Catalog.KeysForLotVendorAttributes).VATTaxation,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE DD.VATActivityType END), // VATTaxationOfCostOfActivity
		|	DD.LotVendorAttributes,
		|	CASE WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|	 AND DD.BusinessOperation <> UNDEFINED
		|	 AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.EmptyRef)
		|			THEN DD.BusinessOperation
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|			THEN VALUE(Enum.BusinessTransactions.ExpenseAllocationToCost)
		|		ELSE UNDEFINED
		|	END,
		|	DD.Department,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.CorExpenseItem,
		|	DD.CorExpenditureDimension,
		|	DD.DebitBusinessUnit,
		|	(CASE
		|		WHEN DD.SpecifiedDocumentInExpenseAnalytics THEN DD.DimensionOfExpenses
		|		ELSE UNDEFINED END),
		|	DD.LineOfBusiness,
		|	DD.CorLineOfBusiness
		|";
EndFunction

Function TextAdditionalExpensesAmountAverageForDistributionOfMan() // Uses high spending for distribution, vtbasdistribution of high spending
	Return
		"SELECT
		|	""TextAdditionalExpensesAmountAverageForDistributionOfMan"" AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.AdditionalExpensesForAllocationMan) AS EntryType,
		|	CASE WHEN MAX(Base.DenominatorOfMan) < 0 THEN TRUE ELSE FALSE END AS ThisIsReverseTransaction,
		|	0 											AS Priority,
		|	MAX(Base.DenominatorOfMan) 				AS Denominator,
		|	0											AS DenominatorForSources,
		|	TRUE 										AS CalculationIsCompleted,
		|	
		|	UNDEFINED 								AS Products,
		|	UNDEFINED 								AS TaxationOfParty,
		|
		|	CASE WHEN SUM(DD.DenominatorOfMan) < 0 THEN &EndOfPreviousPeriod ELSE DD.Period END AS Period,
		|	DD.Recorder,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.Recorder END) AS CostLogger,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DD.Organization,
		|	UNDEFINED AS AccountingSection,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	UNDEFINED AS InventoryOwnerAttribute,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	DD.VATActivityType AS VATActivityType,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE DD.VATActivityType END) AS VATTaxationOfCostOfActivity,
		|	DD.LotVendorAttributesOfReceiptDocument AS LotVendorAttributes,
		|	DD.DocumentInflow,
		|
		|	0 AS Count,
		|	0 AS CostExcludingVAT,
		|	0 AS VAT,
		|	DD.CostExcludingVATMan AS CostExcludingVATMan,
		|	DD.VATManag AS VATManag,
		|
		|	DD.BusinessOperation,
		|	DD.VATActivityType AS CorVATActivityTypes,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS CorControllingAttributes,
		|	DD.Department AS Department,
		|	DD.ExpenseItem AS ExpenseItemAssets,
		|	DD.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS DimensionOfAssets,
		|	UNDEFINED AS CorExpenseItem,
		|	UNDEFINED AS CorExpenditureDimension,
		|	UNDEFINED AS DebitBusinessUnit,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS DocumentSourceOfCost,
		|	UNDEFINED AS VATWriteOffItem,
		|	UNDEFINED AS DimensionVATWriteOff,
		|	DD.LineOfBusiness,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
		|	DD.VATActivityType AS DocumentVATActivityType,
		|	UNDEFINED AS GLAccountSettings,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	FALSE AS ReversingEntry,
		|	MAX(Base.FinRecordID) AS FinRecordID
		|FROM
		|	TTAdditionalCostsForDistribution AS DD
		|	INNER JOIN TTBaseOfDistributionOfAdditionalExpensesInSummary AS Base
		|		ON DD.Organization = Base.Organization
		|		AND DD.Department = Base.Department
		|		AND DD.LineOfBusiness = Base.LineOfBusiness
		|		AND DD.ExpenseItem = Base.ExpenseItem
		|		AND DD.DimensionOfExpenses = Base.DimensionOfExpenses
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion22)
		|	AND Base.DenominatorOfMan <> 0
		|	AND (DD.CostExcludingVATMan <> 0 OR DD.VATManag <> 0)
		|
		|GROUP BY
		|	DD.VATActivityType,
		|	DD.Period,
		|	DD.Recorder,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.Recorder END), // CostLogger
		|	DD.Organization,
		|	DD.DocumentInflow,
		|	DD.LotVendorAttributesOfReceiptDocument,
		|	DD.LineOfBusiness,
		|	DD.CostExcludingVATMan,
		|	DD.VATManag,
		|	DD.BusinessOperation,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.Department
		|";
EndFunction

Function TextBaseAdditionalExpensesAmountAverageMan()
	Return
		"SELECT
		|	""TextBaseAdditionalExpensesAmountAverageMan"" AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.BaseAdditionalExpensesMan) AS EntryType,
		|	FALSE AS ThisIsReverseTransaction,
		|	CASE WHEN DD.SignMan = -1 THEN 0 ELSE 10 END AS Priority,
		|	SUM(DD.Count)						AS Denominator,
		|	SUM(DD.DenominatorOfMan)					AS DenominatorForSources,
		|	FALSE 										AS CalculationIsCompleted,
		|	
		|	CAST(DD.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products AS Products,
		|	CAST(DD.LotVendorAttributes AS Catalog.KeysForLotVendorAttributes).VATTaxation 		AS TaxationOfParty,
		|
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.Recorder END) AS CostLogger,
		|	UNDEFINED AS RecordType,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot AS Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType AS VATActivityType,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE DD.VATActivityType END) AS VATTaxationOfCostOfActivity,
		|	DD.LotVendorAttributes,
		|	UNDEFINED AS DocumentInflow,
		|
		|	0 AS Count,
		|	0 AS CostExcludingVAT,
		|	0 AS VAT,
		|	0 AS CostExcludingVATMan,
		|	0 AS VATManag,
		|
		|	CASE WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|	 AND DD.BusinessOperation <> UNDEFINED
		|	 AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.EmptyRef)
		|			THEN DD.BusinessOperation
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|			THEN VALUE(Enum.BusinessTransactions.ExpenseAllocationToCost)
		|		ELSE UNDEFINED
		|	END AS BusinessOperation,
		|	UNDEFINED AS CorVATActivityTypes,
		|	DD.AccountingSection AS CorAccountingSection,
		|	DD.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS CorControllingAttributes,
		|	DD.Department AS Department,
		|	DD.ExpenseItem AS ExpenseItemAssets,
		|	DD.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS DimensionOfAssets,
		|	DD.CorExpenseItem,
		|	DD.CorExpenditureDimension,
		|	DD.DebitBusinessUnit,
		|	(CASE
		|		WHEN DD.SpecifiedDocumentInExpenseAnalytics THEN DD.DimensionOfExpenses
		|		ELSE UNDEFINED END) AS DocumentSource,
		|	(CASE
		|		WHEN DD.SpecifiedDocumentInExpenseAnalytics THEN DD.DimensionOfExpenses
		|		ELSE UNDEFINED END) AS DocumentSourceOfCost,
		|	UNDEFINED AS VATWriteOffItem,
		|	UNDEFINED AS DimensionVATWriteOff,
		|	DD.LineOfBusiness,
		|	DD.CorLineOfBusiness,
		|	DD.VATActivityType AS DocumentVATActivityType,
		|	UNDEFINED AS GLAccountSettings,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	FALSE AS ReversingEntry,
		|	MAX(DD.FinRecordID) AS FinRecordID
		|FROM
		|	TTBaseOfAllocationOfAdditionalExpenses AS DD
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion22)
		|	AND DD.DenominatorOfMan <> 0
		|GROUP BY
		|	DD.Period,
		|	DD.Recorder,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Document.CostCalculationRecorder.EmptyRef)
		|		ELSE DD.Recorder END), // CostLogger
		|	CASE WHEN DD.SignMan = -1 THEN 0 ELSE 10 END,
		|	CAST(DD.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products,
		|	CAST(DD.LotVendorAttributes AS Catalog.KeysForLotVendorAttributes).VATTaxation,
		|	DD.Organization,
		|	DD.AccountingSection,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	(CASE
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE DD.VATActivityType END), // VATTaxationOfCostOfActivity
		|	DD.LotVendorAttributes,
		|	CASE WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|	 AND DD.BusinessOperation <> UNDEFINED
		|	 AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.EmptyRef)
		|			THEN DD.BusinessOperation
		|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|			THEN VALUE(Enum.BusinessTransactions.ExpenseAllocationToCost)
		|		ELSE UNDEFINED
		|	END,
		|	DD.Department,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.CorExpenseItem,
		|	DD.CorExpenditureDimension,
		|	DD.DebitBusinessUnit,
		|	(CASE
		|		WHEN DD.SpecifiedDocumentInExpenseAnalytics THEN DD.DimensionOfExpenses
		|		ELSE UNDEFINED END),
		|	DD.LineOfBusiness,
		|	DD.CorLineOfBusiness
		|";
EndFunction


#EndRegion


#Region StageProcedures_CalculationOfBatchesNDS2_4

// Forms a temporary table for the movement of the water units.
//
Procedure InitializeTablesForBalanceEntryDocuments(CalculationParameters)
	
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text =
	"SELECT TOP 0
	|	Cost_.ItemsLocationAttributes,
	|	T.Organization,
	|	T.Lot,
	|	T.InventoryOwnerAttribute,
	|	Cost_.AccountingSection,
	|	T.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument AS AnalysisOfReceiptDocumentAccounting,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemAssets,
	|	0 AS Count,
	|	0 AS CostExcludingVAT,
	|	0 AS VAT,
	|	0 AS CostExcludingVATMan,
	|	0 AS VATManag
	|INTO TTRegisteredRecordsOfEnteringBalances0
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS T
	|	LEFT JOIN AccumulationRegister.InventoryCost AS Cost_
	|		ON FALSE
	|;
	|SELECT
	|	T.Date,
	|	T.Ref
	|FROM
	|	Document.OBEntryGoods AS T
	|WHERE
	|	T.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND T.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI),
	|		VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors)
	|		)
	|	AND T.Posted
	|
	|
	|ORDER BY
	|	Date
	|";
	
	Selection = Query.Execute().Select();
	
	TemporaryTableNames = "TTRegisteredRecordsOfEnteringBalances0";
	DocumentNumber = 0;
	
	While Selection.Next() Do
		
		DocumentNumber = DocumentNumber + 1;
		NameOfCurTT = "TTRegisteredRecordsOfEnteringBalances" + Format(DocumentNumber, "NG=");
		TemporaryTableNames = TemporaryTableNames + ", " + NameOfCurTT;
		
		QueryTexts = New ValueList;
		DocumentRequest_ = New Query;
		DocumentRequest_.SetParameter(CostCalculationAppliedAlgorithms.NameOfObjectSServiceAdditionalProperty(), True);
		DocumentRequest_.SetParameter("NameOfTemporaryBatchTableNDS2_4", NameOfCurTT);
		
			Documents.OBEntryGoods.FillInInitializationParameters(DocumentRequest_, Selection.Ref);
			Documents.OBEntryGoods.QueryTextTableDetailsOfBatchesOfGoodsForLBSiUSN2_4(DocumentRequest_, QueryTexts, "");
		
		DocumentRequest_.TempTablesManager = CalculationParameters.TempTablesManager;
		DocumentRequest_.Text = StrConcat(QueryTexts.UnloadValues(), Chars.LF + ";" + Chars.LF);
		
		DocumentRequest_.Execute();
		
		NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(
			CalculationParameters,
			ExistingTT + ", " + TemporaryTableNames);
		
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
		
	EndDo;
	
	ColumnsNames = CostCalculationAppliedAlgorithms.GetColumnNamesAsString(
		CostCalculationAppliedAlgorithms.UnloadTemporaryTable(CalculationParameters, "TTRegisteredRecordsOfEnteringBalances0"));
		
	CostCalculationAppliedAlgorithms.MergeTemporaryTables(
		CalculationParameters,
		TemporaryTableNames,
		"TTRegisteredRecordsOfEnteringBalances",
		ColumnsNames,
		"Count, CostExcludingVAT, VAT, CostExcludingVATMan, VATManag",
		"DocumentInflow",
		True);
	
	// We will destroy unnecessary temporary tables.
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(
		CalculationParameters,
		ExistingTT + ", TTRegisteredRecordsOfEnteringBalances");
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
	If CostCalculationAppliedAlgorithms.EmptyTempTable(CalculationParameters, "TTRegisteredRecordsOfEnteringBalances") Then
		
		// Let's add the field this is variable expenses in the movement of the output
		Query.Text =
		"SELECT
		|	T.DocumentInflow,
		|	T.AnalysisOfReceiptDocumentAccounting,
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.VATActivityType,
		|	T.FinancialAccountingDimension,
		|	T.ExpenseItemAssets,
		|	T.CostExcludingVATMan,
		|	T.VATManag,
		|	T.CostExcludingVAT,
		|	T.VAT,
		|	T.Count,
		|	FALSE AS TheseAreVariableAdditionalCosts
		|INTO TTRegisteredRecordsOfEnteringBalancesNew
		|FROM
		|	TTRegisteredRecordsOfEnteringBalances AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTRegisteredRecordsOfEnteringBalances
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	*
		|INTO TTRegisteredRecordsOfEnteringBalances
		|FROM
		|	TTRegisteredRecordsOfEnteringBalancesNew AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTRegisteredRecordsOfEnteringBalancesNew
		|";
		
		Query.Execute();
		
		Return;
		
	EndIf;
	
	// If the movements of entering balances according to analysts from the analytics of the water supply are found more than once in the current period or were in previous periods,
	// then such movements should be placed in the periodic register of batches.
	Query.Text =
	"SELECT
	|	T.DocumentInflow,
	|	T.AnalysisOfReceiptDocumentAccounting,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	SUM(1) AS RecordsCount
	|INTO TTBalanceEntryAnalytics
	|FROM
	|	TTRegisteredRecordsOfEnteringBalances AS T
	|
	|GROUP BY
	|	T.DocumentInflow,
	|	T.AnalysisOfReceiptDocumentAccounting,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.ItemsLocationAttributes.Products,
	|	T.ItemsLocationAttributes.CHARACTERISTIC
	|
	|INDEX BY
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.DocumentInflow,
	|	T.AnalysisOfReceiptDocumentAccounting,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|	SUM(T.CostExcludingVATLocal) AS CostExcludingVATLocal,
	|	SUM(T.VATLocal) AS VATLocal,
	|	SUM(T.CostExcludingVATMan) AS CostExcludingVATMan,
	|	SUM(T.VATManag) AS VATManag
	|INTO TTBatchVariables
	|FROM
	|(SELECT
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument AS AnalysisOfReceiptDocumentAccounting,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	T.CostExcludingVATLocal,
	|	T.VATLocal,
	|	T.CostExcludingVATMan,
	|	T.VATManag
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS T
	|	INNER JOIN TTBalanceEntryAnalytics AS Filter
	|		ON T.DocumentInflow = Filter.DocumentInflow
	|		AND T.LotVendorAttributesOfReceiptDocument = Filter.AnalysisOfReceiptDocumentAccounting
	|		AND T.Lot = Filter.Lot
	|		AND T.LotVendorAttributes = Filter.LotVendorAttributes
	|		AND T.Organization = Filter.Organization
	|		AND T.InventoryOwnerAttribute = Filter.InventoryOwnerAttribute
	|		AND T.Products = Filter.Products
	|		AND T.Characteristic = Filter.Characteristic
	|WHERE
	|	T.RegistrationPeriod < &BeginOfPeriod
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument AS AnalysisOfReceiptDocumentAccounting,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	T.CostExcludingVATLocal,
	|	T.VATLocal,
	|	T.CostExcludingVATMan,
	|	T.VATManag
	|FROM
	|	InformationRegister.ItemizeGoodsCostItemizedAndOtherCosts AS T
	|	INNER JOIN TTBalanceEntryAnalytics AS Filter
	|		ON T.DocumentInflow = Filter.DocumentInflow
	|		AND T.LotVendorAttributesOfReceiptDocument = Filter.AnalysisOfReceiptDocumentAccounting
	|		AND T.Lot = Filter.Lot
	|		AND T.LotVendorAttributes = Filter.LotVendorAttributes
	|		AND T.Organization = Filter.Organization
	|		AND T.InventoryOwnerAttribute = Filter.InventoryOwnerAttribute
	|		AND T.ItemsLocationAttributes.Products = Filter.Products
	|		AND T.ItemsLocationAttributes.Characteristic = Filter.Characteristic
	|WHERE
	|	T.Period < &BeginOfPeriod
	|
	|UNION ALL
	|
	|SELECT
	|	T.DocumentInflow,
	|	T.AnalysisOfReceiptDocumentAccounting,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	TTBalanceEntryAnalytics AS T
	|WHERE
	|	T.RecordsCount > 1
	|) AS T
	|GROUP BY
	|	T.DocumentInflow,
	|	T.AnalysisOfReceiptDocumentAccounting,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic
	|
	|INDEX BY
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|	COUNT(DISTINCT T.DocumentInflow) AS DocumentsCount,
	|	COUNT(DISTINCT T.AnalysisOfReceiptDocumentAccounting) AS NumberOfAnalysts
	|INTO TTReceiptDocumentsAreVariable
	|FROM
	|	TTBalanceEntryAnalytics AS T
	|WHERE
	|	T.RecordsCount = 1
	|GROUP BY
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic
	|HAVING
	|	COUNT(DISTINCT T.DocumentInflow) > 1
	|	OR COUNT(DISTINCT T.AnalysisOfReceiptDocumentAccounting) > 1
	|
	|INDEX BY
	|	Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.DocumentInflow,
	|	T.AnalysisOfReceiptDocumentAccounting,
	|	T.Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	|	T.ExpenseItemAssets,
	|	T.CostExcludingVATMan - T.Count * ISNULL(Lots.CostExcludingVATMan, 0) AS CostExcludingVATMan,
	|	T.VATManag - T.Count * ISNULL(Lots.VATManag, 0) AS VATManag,
	|	T.CostExcludingVAT - T.Count * ISNULL(Lots.CostExcludingVATLocal, 0) AS CostExcludingVAT,
	|	T.VAT - T.Count * ISNULL(Lots.VATLocal, 0) AS VAT,
	|	T.Count,
	|	CASE WHEN Lots.DocumentInflow IS NULL
	|	  AND ReceiptDocuments.Lot IS NULL
	|		THEN FALSE
	|		ELSE TRUE
	|	END AS TheseAreVariableAdditionalCosts
	|INTO TTRegisteredRecordsOfEnteringBalancesNew
	|FROM
	|	TTRegisteredRecordsOfEnteringBalances AS T
	|	LEFT JOIN TTBatchVariables AS Lots
	|		ON T.DocumentInflow = Lots.DocumentInflow
	|		AND T.AnalysisOfReceiptDocumentAccounting = Lots.AnalysisOfReceiptDocumentAccounting
	|		AND T.Lot = Lots.Lot
	|		AND T.LotVendorAttributes = Lots.LotVendorAttributes
	|		AND T.Organization = Lots.Organization
	|		AND T.InventoryOwnerAttribute = Lots.InventoryOwnerAttribute
	|		AND T.ItemsLocationAttributes.Products = Lots.Products
	|		AND T.ItemsLocationAttributes.CHARACTERISTIC = Lots.Characteristic
	|	LEFT JOIN TTReceiptDocumentsAreVariable AS ReceiptDocuments
	|		ON T.Lot = ReceiptDocuments.Lot
	|		AND T.LotVendorAttributes = ReceiptDocuments.LotVendorAttributes
	|		AND T.Organization = ReceiptDocuments.Organization
	|		AND T.InventoryOwnerAttribute = ReceiptDocuments.InventoryOwnerAttribute
	|		AND T.ItemsLocationAttributes.Products = ReceiptDocuments.Products
	|		AND T.ItemsLocationAttributes.CHARACTERISTIC = ReceiptDocuments.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTRegisteredRecordsOfEnteringBalances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.DocumentInflow,
	|	T.AnalysisOfReceiptDocumentAccounting,
	|	T.Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	|	T.ExpenseItemAssets,
	|	T.CostExcludingVATMan,
	|	T.VATManag,
	|	T.CostExcludingVAT,
	|	T.VAT,
	|	T.Count,
	|	T.TheseAreVariableAdditionalCosts
	|INTO TTRegisteredRecordsOfEnteringBalances
	|FROM
	|	TTRegisteredRecordsOfEnteringBalancesNew AS T
	|
	|INDEX BY
	|	ExpenseItemAssets
	|";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(
		CalculationParameters,
		ExistingTT + ", TTRegisteredRecordsOfEnteringBalances");
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
EndProcedure

Procedure DistributeVATAtCost(CalculationParameters, DataTableName)
	
	NameOfDataTableSource = DataTableName;
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	#Region DataPreparation
	
	AdvancedCostAccountingForVATLots = ValueIsFilled(CalculationParameters.OrganizationsWithDetailedMaterialAndItemByItemCosts);
	
	If Query.Parameters.OrganizationsWithDetailedMaterialAndItemByItemCosts.Count() <>
	 Query.Parameters.OrganizationsIncludingVATLotsVersion24.Count() Then
		
		Query.Text =
		"SELECT
		|	T.TheseAreRemainingArticleByArticleVariables,
		|	T.TheseRemaindersAreArticleByArticleConstants,
		// VAT Batch Analysts
		|	T.InventoryLocationAttributesOfReceiptDocument,
		|	CASE WHEN T.Organization IN (&OrganizationsWithoutDetailsBeforeReceiptDocuments)
		|			AND NOT T.TheseAreLeftovers AND (T.VATLocal = 0 AND T.VATManag = 0)
		|		THEN UNDEFINED
		|		ELSE T.DocumentInflow
		|	END AS DocumentInflow,
		|	CASE WHEN T.Organization IN (&OrganizationsWithoutDetailsBeforeReceiptDocuments)
		|			AND NOT T.TheseAreLeftovers AND (T.VATLocal = 0 AND T.VATManag = 0)
		|		THEN VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|		ELSE T.LotVendorAttributesOfReceiptDocument
		|	END AS LotVendorAttributesOfReceiptDocument,
		|	T.PreviousRedistributionCosts,
		|	T.ThisIsAdditionalExpense,
		|	T.TheseAreVariableAdditionalCosts,
		|	
		// Cost Analysts
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.VATActivityType,
		|	T.FinancialAccountingDimension,
		|
		// Other fields
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|
		// Resources
		|	1 AS SignCostWithVAT,
		|	1 AS SignCostWithoutVAT,
		|	CASE WHEN SUM(T.SignValueWithoutVATLocal * T.CostExcludingVATLocal) < 0 THEN -1 ELSE 1 END AS SignValueWithoutVATLocal,
		|	CASE WHEN SUM(T.LocalVATSign * T.VATLocal) < 0 THEN -1 ELSE 1 END AS LocalVATSign,
		|	CASE WHEN SUM(T.SignCostWithoutVATMan * T.CostExcludingVATMan) < 0 THEN -1 ELSE 1 END AS SignCostWithoutVATMan,
		|	CASE WHEN SUM(T.VATSignMan * T.VATManag) < 0 THEN -1 ELSE 1 END AS VATSignMan,
		|
		|	0 AS CostInclVAT,
		|	0 AS CostExcludingVAT,
		|	CASE WHEN SUM(T.SignValueWithoutVATLocal * T.CostExcludingVATLocal) < 0 THEN -SUM(T.SignValueWithoutVATLocal * T.CostExcludingVATLocal) ELSE SUM(T.SignValueWithoutVATLocal * T.CostExcludingVATLocal) END AS CostExcludingVATLocal,
		|	CASE WHEN SUM(T.LocalVATSign * T.VATLocal) < 0 THEN -SUM(T.LocalVATSign * T.VATLocal) ELSE SUM(T.LocalVATSign * T.VATLocal) END AS VATLocal,
		|	CASE WHEN SUM(T.SignCostWithoutVATMan * T.CostExcludingVATMan) < 0 THEN -SUM(T.SignCostWithoutVATMan * T.CostExcludingVATMan) ELSE SUM(T.SignCostWithoutVATMan * T.CostExcludingVATMan) END AS CostExcludingVATMan,
		|	CASE WHEN SUM(T.VATSignMan * T.VATManag) < 0 THEN -SUM(T.VATSignMan * T.VATManag) ELSE SUM(T.VATSignMan * T.VATManag) END AS VATManag
		|INTO DataForCalculationIsAbbreviated
		|FROM
		|	DataTableName AS T
		|WHERE
		|	NOT T.Organization IN (&OrganizationsWithDetailedMaterialAndItemByItemCosts)
		|	AND (T.VATLocal <> 0 OR T.VATManag <> 0
		|		OR (&UseVATDeclarationSection7Filling
		|			AND ISNULL(T.LotVendorAttributesOfReceiptDocument.Vendor, VALUE(Catalog.Partners.EmptyRef)) <> VALUE(Catalog.Partners.EmptyRef))
		|
		|		)
		|	AND T.LotVendorAttributesOfReceiptDocument <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|GROUP BY
		|	T.TheseAreRemainingArticleByArticleVariables,
		|	T.TheseRemaindersAreArticleByArticleConstants,
		|	T.InventoryLocationAttributesOfReceiptDocument,
		|	CASE WHEN T.Organization IN (&OrganizationsWithoutDetailsBeforeReceiptDocuments)
		|			AND NOT T.TheseAreLeftovers AND (T.VATLocal = 0 AND T.VATManag = 0)
		|		THEN UNDEFINED
		|		ELSE T.DocumentInflow
		|	END,
		|	CASE WHEN T.Organization IN (&OrganizationsWithoutDetailsBeforeReceiptDocuments)
		|			AND NOT T.TheseAreLeftovers AND (T.VATLocal = 0 AND T.VATManag = 0)
		|		THEN VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|		ELSE T.LotVendorAttributesOfReceiptDocument
		|	END,
		|	T.PreviousRedistributionCosts,
		|	T.ThisIsAdditionalExpense,
		|	T.TheseAreVariableAdditionalCosts,
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.VATActivityType,
		|	T.FinancialAccountingDimension,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses
		|
		|UNION ALL
		|
		|SELECT
		|	T.TheseAreRemainingArticleByArticleVariables,
		|	T.TheseRemaindersAreArticleByArticleConstants,
		// VAT Batch Analysts
		|	T.InventoryLocationAttributesOfReceiptDocument,
		|	CASE WHEN T.Organization IN (&OrganizationsWithoutDetailsBeforeReceiptDocuments)
		|			AND NOT T.TheseAreLeftovers AND (T.VATLocal = 0 AND T.VATManag = 0)
		|		THEN UNDEFINED
		|		ELSE T.DocumentInflow
		|	END AS DocumentInflow,
		|	CASE WHEN T.Organization IN (&OrganizationsWithoutDetailsBeforeReceiptDocuments)
		|			AND NOT T.TheseAreLeftovers AND (T.VATLocal = 0 AND T.VATManag = 0)
		|		THEN VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|		ELSE T.LotVendorAttributesOfReceiptDocument
		|	END AS LotVendorAttributesOfReceiptDocument,
		|	T.PreviousRedistributionCosts,
		|	T.ThisIsAdditionalExpense,
		|	T.TheseAreVariableAdditionalCosts,
		|	
		// Cost Analysts
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.VATActivityType,
		|	T.FinancialAccountingDimension,
		|
		// Other fields
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|
		// Resources
		|	CASE WHEN SUM(T.SignCostWithVAT * T.CostInclVAT) < 0 THEN -1 ELSE 1 END AS SignCostWithVAT,
		|	CASE WHEN SUM(T.SignCostWithoutVAT * T.CostExcludingVAT) < 0 THEN -1 ELSE 1 END AS SignCostWithoutVAT,
		|	CASE WHEN SUM(T.SignValueWithoutVATLocal * T.CostExcludingVATLocal) < 0 THEN -1 ELSE 1 END AS SignValueWithoutVATLocal,
		|	CASE WHEN SUM(T.LocalVATSign * T.VATLocal) < 0 THEN -1 ELSE 1 END AS LocalVATSign,
		|	CASE WHEN SUM(T.SignCostWithoutVATMan * T.CostExcludingVATMan) < 0 THEN -1 ELSE 1 END AS SignCostWithoutVATMan,
		|	CASE WHEN SUM(T.VATSignMan * T.VATManag) < 0 THEN -1 ELSE 1 END AS VATSignMan,
		|
		|	CASE WHEN SUM(T.SignCostWithVAT * T.CostInclVAT) < 0 THEN -SUM(T.SignCostWithVAT * T.CostInclVAT) ELSE SUM(T.SignCostWithVAT * T.CostInclVAT) END AS CostInclVAT,
		|	CASE WHEN SUM(T.SignCostWithoutVAT * T.CostExcludingVAT) < 0 THEN -SUM(T.SignCostWithoutVAT * T.CostExcludingVAT) ELSE SUM(T.SignCostWithoutVAT * T.CostExcludingVAT) END AS CostExcludingVAT,
		|	CASE WHEN SUM(T.SignValueWithoutVATLocal * T.CostExcludingVATLocal) < 0 THEN -SUM(T.SignValueWithoutVATLocal * T.CostExcludingVATLocal) ELSE SUM(T.SignValueWithoutVATLocal * T.CostExcludingVATLocal) END AS CostExcludingVATLocal,
		|	CASE WHEN SUM(T.LocalVATSign * T.VATLocal) < 0 THEN -SUM(T.LocalVATSign * T.VATLocal) ELSE SUM(T.LocalVATSign * T.VATLocal) END AS VATLocal,
		|	CASE WHEN SUM(T.SignCostWithoutVATMan * T.CostExcludingVATMan) < 0 THEN -SUM(T.SignCostWithoutVATMan * T.CostExcludingVATMan) ELSE SUM(T.SignCostWithoutVATMan * T.CostExcludingVATMan) END AS CostExcludingVATMan,
		|	CASE WHEN SUM(T.VATSignMan * T.VATManag) < 0 THEN -SUM(T.VATSignMan * T.VATManag) ELSE SUM(T.VATSignMan * T.VATManag) END AS VATManag
		|FROM
		|	DataTableName AS T
		|WHERE
		|	T.Organization IN (&OrganizationsWithDetailedMaterialAndItemByItemCosts)
		|GROUP BY
		|	T.TheseAreRemainingArticleByArticleVariables,
		|	T.TheseRemaindersAreArticleByArticleConstants,
		|	T.InventoryLocationAttributesOfReceiptDocument,
		|	CASE WHEN T.Organization IN (&OrganizationsWithoutDetailsBeforeReceiptDocuments)
		|			AND NOT T.TheseAreLeftovers AND (T.VATLocal = 0 AND T.VATManag = 0)
		|		THEN UNDEFINED
		|		ELSE T.DocumentInflow
		|	END,
		|	CASE WHEN T.Organization IN (&OrganizationsWithoutDetailsBeforeReceiptDocuments)
		|			AND NOT T.TheseAreLeftovers AND (T.VATLocal = 0 AND T.VATManag = 0)
		|		THEN VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|		ELSE T.LotVendorAttributesOfReceiptDocument
		|	END,
		|	T.PreviousRedistributionCosts,
		|	T.ThisIsAdditionalExpense,
		|	T.TheseAreVariableAdditionalCosts,
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.VATActivityType,
		|	T.FinancialAccountingDimension,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses
		|
		// Indexes must correspond to the property of the index register from the description of the cost register
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|";
		
		Query.Text = StrReplace(Query.Text, "DataTableName", DataTableName);
		
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
		
		DataTableName = "DataForCalculationIsAbbreviated";
		
	ElsIf ValueIsFilled(CalculationParameters.OrganizationsWithoutDetailsBeforeReceiptDocuments) Then
		
		Query.Text =
		"SELECT
		|	T.TheseAreRemainingArticleByArticleVariables,
		|	T.TheseRemaindersAreArticleByArticleConstants,
		// VAT Batch Analysts
		|	T.InventoryLocationAttributesOfReceiptDocument,
		|	CASE WHEN T.Organization IN (&OrganizationsWithoutDetailsBeforeReceiptDocuments)
		|			AND NOT T.TheseAreLeftovers AND (T.VATLocal = 0 AND T.VATManag = 0)
		|		THEN UNDEFINED
		|		ELSE T.DocumentInflow
		|	END AS DocumentInflow,
		|	CASE WHEN T.Organization IN (&OrganizationsWithoutDetailsBeforeReceiptDocuments)
		|			AND NOT T.TheseAreLeftovers AND (T.VATLocal = 0 AND T.VATManag = 0)
		|		THEN VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|		ELSE T.LotVendorAttributesOfReceiptDocument
		|	END AS LotVendorAttributesOfReceiptDocument,
		|	T.PreviousRedistributionCosts,
		|	T.ThisIsAdditionalExpense,
		|	T.TheseAreVariableAdditionalCosts,
		|	
		// Cost Analysts
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.VATActivityType,
		|	T.FinancialAccountingDimension,
		|
		// Other fields
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|
		// Resources
		|	CASE WHEN SUM(T.SignCostWithVAT * T.CostInclVAT) < 0 THEN -1 ELSE 1 END AS SignCostWithVAT,
		|	CASE WHEN SUM(T.SignCostWithoutVAT * T.CostExcludingVAT) < 0 THEN -1 ELSE 1 END AS SignCostWithoutVAT,
		|	CASE WHEN SUM(T.SignValueWithoutVATLocal * T.CostExcludingVATLocal) < 0 THEN -1 ELSE 1 END AS SignValueWithoutVATLocal,
		|	CASE WHEN SUM(T.LocalVATSign * T.VATLocal) < 0 THEN -1 ELSE 1 END AS LocalVATSign,
		|	CASE WHEN SUM(T.SignCostWithoutVATMan * T.CostExcludingVATMan) < 0 THEN -1 ELSE 1 END AS SignCostWithoutVATMan,
		|	CASE WHEN SUM(T.VATSignMan * T.VATManag) < 0 THEN -1 ELSE 1 END AS VATSignMan,
		|
		|	CASE WHEN SUM(T.SignCostWithVAT * T.CostInclVAT) < 0 THEN -SUM(T.SignCostWithVAT * T.CostInclVAT) ELSE SUM(T.SignCostWithVAT * T.CostInclVAT) END AS CostInclVAT,
		|	CASE WHEN SUM(T.SignCostWithoutVAT * T.CostExcludingVAT) < 0 THEN -SUM(T.SignCostWithoutVAT * T.CostExcludingVAT) ELSE SUM(T.SignCostWithoutVAT * T.CostExcludingVAT) END AS CostExcludingVAT,
		|	CASE WHEN SUM(T.SignValueWithoutVATLocal * T.CostExcludingVATLocal) < 0 THEN -SUM(T.SignValueWithoutVATLocal * T.CostExcludingVATLocal) ELSE SUM(T.SignValueWithoutVATLocal * T.CostExcludingVATLocal) END AS CostExcludingVATLocal,
		|	CASE WHEN SUM(T.LocalVATSign * T.VATLocal) < 0 THEN -SUM(T.LocalVATSign * T.VATLocal) ELSE SUM(T.LocalVATSign * T.VATLocal) END AS VATLocal,
		|	CASE WHEN SUM(T.SignCostWithoutVATMan * T.CostExcludingVATMan) < 0 THEN -SUM(T.SignCostWithoutVATMan * T.CostExcludingVATMan) ELSE SUM(T.SignCostWithoutVATMan * T.CostExcludingVATMan) END AS CostExcludingVATMan,
		|	CASE WHEN SUM(T.VATSignMan * T.VATManag) < 0 THEN -SUM(T.VATSignMan * T.VATManag) ELSE SUM(T.VATSignMan * T.VATManag) END AS VATManag
		|INTO DataForCalculationIsAbbreviated
		|FROM
		|	DataTableName AS T
		|GROUP BY
		|	T.TheseAreRemainingArticleByArticleVariables,
		|	T.TheseRemaindersAreArticleByArticleConstants,
		|	T.InventoryLocationAttributesOfReceiptDocument,
		|	CASE WHEN T.Organization IN (&OrganizationsWithoutDetailsBeforeReceiptDocuments)
		|			AND NOT T.TheseAreLeftovers AND (T.VATLocal = 0 AND T.VATManag = 0)
		|		THEN UNDEFINED
		|		ELSE T.DocumentInflow
		|	END,
		|	CASE WHEN T.Organization IN (&OrganizationsWithoutDetailsBeforeReceiptDocuments)
		|			AND NOT T.TheseAreLeftovers AND (T.VATLocal = 0 AND T.VATManag = 0)
		|		THEN VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|		ELSE T.LotVendorAttributesOfReceiptDocument
		|	END,
		|	T.PreviousRedistributionCosts,
		|	T.ThisIsAdditionalExpense,
		|	T.TheseAreVariableAdditionalCosts,
		|	T.Organization,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.VATActivityType,
		|	T.FinancialAccountingDimension,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses
		|
		// Indexes must correspond to the property of the index register from the description of the cost register
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|";
		
		Query.Text = StrReplace(Query.Text, "DataTableName", DataTableName);
		
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
		
		DataTableName = "DataForCalculationIsAbbreviated";
		
	EndIf;
	
	ThereAreArticleByArticle = CalculationOfCostCached.AllocateItemByItemExpensesRecursively()
		And CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters, "SLEConnections_ItemByItemExpensesOfOrganizations");
	
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters, "TTConnectionOfCostAdjustmentNodesWithVATWriteOff") Then
	 
		Query.Text =
		"SELECT DISTINCT
		|	T.NodeNumber,
		|	CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS SourceOfVATWriteOff,
		|	CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS VATDeductionReceiver,
		|	CASE WHEN FALSE THEN FALSE // for easy tag placement
		|		ELSE FALSE
		|	END AS VATWriteOffDependsOnPeriodOfReceiptDocument
		|INTO TTCostAdjustmentNodesForVATWriteOff
		|FROM
		|	TTCostAdjustmentUnits AS T
		|WHERE
		|	FALSE
		|INDEX BY
		|	NodeNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.SourceNodeNumber AS SourceNodeNumber,
		|	T.ReceiverNodeNumber AS ReceiverNodeNumber,
		|	T.Weight,
		|	0 AS ManSWeight,
		|	CASE WHEN ISNULL(SourceNodes.SourceOfVATWriteOff, FALSE)
		|	  AND ISNULL(ReceiverNodes_.VATDeductionReceiver, FALSE)
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS ChangingTypeOfVATActivity,
		|	ISNULL(SourceNodes.VATWriteOffDependsOnPeriodOfReceiptDocument, FALSE) AS VATWriteOffDependsOnPeriodOfReceiptDocument
		|INTO TTConnectionOfCostAdjustmentNodesWithVATWriteOff
		|FROM
		|	TTCommunicationNodesCostAdjustment AS T
		|	LEFT JOIN TTCostAdjustmentNodesForVATWriteOff AS SourceNodes
		|		ON SourceNodes.NodeNumber = T.SourceNodeNumber
		|	LEFT JOIN TTCostAdjustmentNodesForVATWriteOff AS ReceiverNodes_
		|		ON ReceiverNodes_.NodeNumber = T.ReceiverNodeNumber
		|
		|INDEX BY
		|	SourceNodeNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.SourceNodeNumber AS SourceNodeNumber,
		|	T.ReceiverNodeNumber AS ReceiverNodeNumber
		|INTO TTConnectionOfCostAdjustmentNodesWithBatchChange
		|FROM
		|	TTCommunicationNodesCostAdjustment AS T
		|	LEFT JOIN TTCostAdjustmentUnits AS SourceNodes
		|		ON SourceNodes.NodeNumber = T.SourceNodeNumber
		|	LEFT JOIN TTCostAdjustmentUnits AS ReceiverNodes_
		|		ON ReceiverNodes_.NodeNumber = T.ReceiverNodeNumber
		|WHERE
		|	SourceNodes.Lot <> ReceiverNodes_.Lot
		|INDEX BY
		|	SourceNodeNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.SourceNodeNumber AS SourceNodeNumber,
		|	T.ReceiverNodeNumber AS ReceiverNodeNumber
		|INTO TTCommunicationNodesCostAdjustmentNetInitialCostLocal
		|FROM
		|	TTCommunicationNodesCostAdjustment AS T
		|WHERE
		|	T.DoNotMoveNetInitialCostLOCAL
		|INDEX BY
		|	SourceNodeNumber
		|";
		
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
		
	EndIf;
	
	If ThereAreArticleByArticle Then
		
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
			"TTConnectionOfCostAdjustmentNodesWithVATWriteOff, TTConnectionOfCostAdjustmentNodesWithBatchChange, TTWeightsOfNodesAreArticleByArticle, TTUnfinishedProductionAdjustmentNodes");
		
		Query.Text =
		"SELECT DISTINCT
		|	T.SourceNodeNumber AS SourceNodeNumber,
		|	T.ReceiverNodeNumber AS ReceiverNodeNumber,
		|	-T.ArcWeightLocal AS Weight,
		|	-T.ArcWeightMan AS ManSWeight,
		|	CASE WHEN ISNULL(SourceNodes.SourceOfVATWriteOff, FALSE)
		|	  AND ISNULL(ReceiverNodes_.VATDeductionReceiver, FALSE)
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS ChangingTypeOfVATActivity,
		|	ISNULL(SourceNodes.VATWriteOffDependsOnPeriodOfReceiptDocument, FALSE) AS VATWriteOffDependsOnPeriodOfReceiptDocument
		|INTO TTConnectionOfCostAdjustmentNodesWithVATWriteOff
		|FROM
		|	SLEConnections_ItemByItemExpensesOfOrganizations AS T
		|	LEFT JOIN TTCostAdjustmentNodesForVATWriteOff AS SourceNodes
		|		ON SourceNodes.NodeNumber = T.SourceNodeNumber
		|	LEFT JOIN TTCostAdjustmentNodesForVATWriteOff AS ReceiverNodes_
		|		ON ReceiverNodes_.NodeNumber = T.ReceiverNodeNumber
		|WHERE
		|	T.SourceNodeNumber <> T.ReceiverNodeNumber
		|
		|INDEX BY
		|	SourceNodeNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.SourceNodeNumber AS NodeNumber,
		|	T.ArcWeightLocal AS Weight,
		|	T.ArcWeightMan AS ManSWeight
		|INTO TTWeightsOfNodesAreArticleByArticle
		|FROM
		|	SLEConnections_ItemByItemExpensesOfOrganizations AS T
		|WHERE
		|	T.SourceNodeNumber = T.ReceiverNodeNumber
		|
		|INDEX BY
		|	NodeNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.SourceNodeNumber AS SourceNodeNumber,
		|	T.ReceiverNodeNumber AS ReceiverNodeNumber
		|INTO TTConnectionOfCostAdjustmentNodesWithBatchChange
		|FROM
		|	SLEConnections_ItemByItemExpensesOfOrganizations AS T
		|	LEFT JOIN TTCostAdjustmentUnits AS SourceNodes
		|		ON SourceNodes.NodeNumber = T.SourceNodeNumber
		|	LEFT JOIN TTCostAdjustmentUnits AS ReceiverNodes_
		|		ON ReceiverNodes_.NodeNumber = T.ReceiverNodeNumber
		|WHERE
		|	T.SourceNodeNumber <> T.ReceiverNodeNumber
		|	AND (SourceNodes.Lot IS NULL
		|		OR ReceiverNodes_.Lot IS NULL
		|		OR SourceNodes.Lot <> ReceiverNodes_.Lot)
		|INDEX BY
		|	SourceNodeNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.NodeNumber,
		|	T.Organization,
		|	T.Lot,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|	T.ProductCostElement,
		|	T.ProductsGroup,
		|	T.RuleOfCostAllocatingToProductionLots,
		|	T.WeightArticleByArticleLocal AS Weight
		|INTO TTUnfinishedProductionAdjustmentNodes
		|FROM
		|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS T
		|WHERE
		|	T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|INDEX BY
		|	NodeNumber
		|";
		
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
		
	EndIf;
	
	Query.Text =
	"SELECT TOP 1
	|	TRUE 
	|FROM
	|	TTCostAdjustmentNodesForVATWriteOff AS T
	|WHERE
	|	T.VATWriteOffDependsOnPeriodOfReceiptDocument";
	
	PossibleToWriteOffVATByPeriods = Not Query.Execute().IsEmpty();
	Query.SetParameter("PossibleToWriteOffVATByPeriods", PossibleToWriteOffVATByPeriods);
	
	Query.Text =
	"SELECT
	|	T.TheseAreRemainingArticleByArticleVariables,
	|	T.TheseRemaindersAreArticleByArticleConstants,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.PreviousRedistributionCosts,
	|	T.ThisIsAdditionalExpense,
	|	T.TheseAreVariableAdditionalCosts,
	|	CASE WHEN NOT &PossibleToWriteOffVATByPeriods // in this case, the document period is not important - for optimal grouping of VAT nodes, we will assume the value TRUE for all nodes
	|	  OR BEGINOFPERIOD(ISNULL(SourceDocumentsData.RecorderDate, DATETIME(1,1,1)), MONTH) = &BeginOfPeriod
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS DocumentReceiptsInCurPeriod
	|INTO NumberingData
	|FROM
	|	DataTableName AS T
	|	LEFT JOIN InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|		ON SourceDocumentsData.Organization = T.Organization
	|		AND SourceDocumentsData.Document = T.DocumentInflow
	|WHERE
	|	(T.CostInclVAT <> 0
	|		OR T.CostExcludingVAT <> 0
	|		OR T.CostExcludingVATLocal <> 0
	|		OR T.VATLocal <> 0
	|		OR T.CostExcludingVATMan <> 0
	|		OR T.VATManag <> 0)
	|	AND T.Lot <> UNDEFINED
	|GROUP BY
	|	T.TheseAreRemainingArticleByArticleVariables,
	|	T.TheseRemaindersAreArticleByArticleConstants,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.PreviousRedistributionCosts,
	|	T.ThisIsAdditionalExpense,
	|	T.TheseAreVariableAdditionalCosts,
	|	CASE WHEN NOT &PossibleToWriteOffVATByPeriods
	|	  OR BEGINOFPERIOD(ISNULL(SourceDocumentsData.RecorderDate, DATETIME(1,1,1)), MONTH) = &BeginOfPeriod
	|		THEN TRUE
	|		ELSE FALSE
	|	END
	|";
	
	Query.Text = StrReplace(Query.Text, "DataTableName", DataTableName);
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	NumberOfVATLots = CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "NumberingData");
	
	If NumberOfVATLots = 0 Then
		
		AddDetailsOfVATShipments(CalculationParameters, NameOfDataTableSource);
	
		// We will destroy unnecessary temporary tables.
		NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(
			CalculationParameters,
			ExistingTT);
		
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
		Return;
		
	EndIf;
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"InventoryLocationAttributesOfReceiptDocument", // Separator
		"", // Resources
		"DocumentInflow, LotVendorAttributesOfReceiptDocument, InventoryLocationAttributesOfReceiptDocument, ExpenseItem", // Order
		"NodeNumber",
		"DocumentInflow, LotVendorAttributesOfReceiptDocument,
		|ExpenseItem, DimensionOfExpenses, InventoryLocationAttributesOfReceiptDocument, PreviousRedistributionCosts, 
		|TheseAreRemainingArticleByArticleVariables, TheseRemaindersAreArticleByArticleConstants, ThisIsAdditionalExpense, TheseAreVariableAdditionalCosts");
	
	CostCalculationAppliedAlgorithms.FillInTemporaryTableRowNumbers(
		CalculationParameters,
		NumberingParameters,
		"NumberingData",
		"TTLotVAT");
	
	Query.Text =
	"SELECT
	|	Nodes.NodeNumber,
	|	Nodes.Organization AS Organization,
	|	Nodes.AccountingSection,
	|	Nodes.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Nodes.InventoryOwnerAttribute,
	|	Nodes.Lot AS Lot,
	|	Nodes.LotVendorAttributes,
	|	Nodes.VATActivityType,
	|	Nodes.FinancialAccountingDimension,
	|	ISNULL(NodesWhereVATIsDebited.VATWriteOffDependsOnPeriodOfReceiptDocument, FALSE) AS VATWriteOffDependsOnPeriodOfReceiptDocument
	|INTO TTCOSTADJUSTMENTSubAssetsWithWriteOffOfVAT
	|FROM
	|	TTCostAdjustmentUnits AS Nodes
	|	LEFT JOIN TTCostAdjustmentNodesForVATWriteOff AS NodesWhereVATIsDebited
	|		ON Nodes.NodeNumber = NodesWhereVATIsDebited.NodeNumber
	// Indexes must correspond to the property of the index register from the description of the cost register
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Nodes.NodeNumber AS NodeNumber,
	|	Nodes.Organization AS Organization,
	|	Nodes.AccountingSection,
	|	Nodes.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CAST(Nodes.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products AS Products,
	|	CAST(Nodes.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Characteristic AS Characteristic,
	|	Nodes.InventoryOwnerAttribute,
	|	Nodes.Lot AS Lot,
	|	Nodes.LotVendorAttributes,
	|	Nodes.VATActivityType,
	|	Nodes.FinancialAccountingDimension,
	|	Nodes.VATWriteOffDependsOnPeriodOfReceiptDocument,
	|	ISNULL(CostBalances.Count, 0) AS LotQuantity
	|INTO TTCOSTAdjustmentSubAssetsWithBATCHBalances
	|FROM
	|	TTCOSTADJUSTMENTSubAssetsWithWriteOffOfVAT AS Nodes
	|		LEFT JOIN TTCashSettlementBalancesCostOfGoods AS CostBalances
	|			ON CostBalances.ItemsLocationAttributes = Nodes.ItemsLocationAttributes
	|			AND CostBalances.Organization = Nodes.Organization
	|			AND CostBalances.Lot = Nodes.Lot
	|			AND CostBalances.AccountingSection = Nodes.AccountingSection
	|			AND CostBalances.InventoryOwnerAttribute = Nodes.InventoryOwnerAttribute
	|			AND CostBalances.LotVendorAttributes = Nodes.LotVendorAttributes
	|			AND CostBalances.VATActivityType = Nodes.VATActivityType
	|			AND CostBalances.FinancialAccountingDimension = Nodes.FinancialAccountingDimension
	|INDEX BY
	|	NodeNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Nodes.NodeNumber AS CostNodeNumber,
	|	Nodes.VATWriteOffDependsOnPeriodOfReceiptDocument AS VATWriteOffDependsOnPeriodOfReceiptDocument,
	|
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.PreviousRedistributionCosts,
	|	T.TheseAreRemainingArticleByArticleVariables,
	|	T.TheseRemaindersAreArticleByArticleConstants,
	|	T.ThisIsAdditionalExpense,
	|	T.TheseAreVariableAdditionalCosts,
	|
	|	T.SignCostWithVAT,
	|	T.SignCostWithoutVAT,
	|	T.SignValueWithoutVATLocal,
	|	T.LocalVATSign,
	|	T.SignCostWithoutVATMan,
	|	T.VATSignMan,
	|	T.CostInclVAT AS CostInclVAT,
	|	T.CostExcludingVAT AS CostExcludingVAT,
	|	T.CostExcludingVATLocal AS CostExcludingVATLocal,
	|	T.VATLocal AS VATLocal,
	|	T.CostExcludingVATMan AS CostExcludingVATMan,
	|	T.VATManag AS VATManag
	|INTO TTINITIALCOSTSubAssetsExcludingVAT
	|FROM
	|	DataTableName AS T
	|	INNER JOIN TTCOSTADJUSTMENTSubAssetsWithWriteOffOfVAT AS Nodes
	|		ON Nodes.ItemsLocationAttributes = T.ItemsLocationAttributes
	|		AND Nodes.Organization = T.Organization
	|		AND Nodes.Lot = T.Lot
	|		AND Nodes.AccountingSection = T.AccountingSection
	|		AND Nodes.InventoryOwnerAttribute = T.InventoryOwnerAttribute
	|		AND Nodes.LotVendorAttributes = T.LotVendorAttributes
	|		AND Nodes.VATActivityType = T.VATActivityType
	|		AND Nodes.FinancialAccountingDimension = T.FinancialAccountingDimension
	|WHERE
	|	T.CostInclVAT <> 0
	|	OR T.CostExcludingVAT <> 0
	|	OR T.CostExcludingVATLocal <> 0
	|	OR T.VATLocal <> 0
	|	OR T.CostExcludingVATMan <> 0
	|	OR T.VATManag <> 0
	|
	|INDEX BY
	|	DocumentInflow,
	|	LotVendorAttributesOfReceiptDocument,
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	InventoryLocationAttributesOfReceiptDocument,
	|	PreviousRedistributionCosts,
	|	TheseAreRemainingArticleByArticleVariables,
	|	TheseRemaindersAreArticleByArticleConstants,
	|	ThisIsAdditionalExpense,
	|	TheseAreVariableAdditionalCosts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.CostNodeNumber,
	|	VATNodes.NodeNumber AS VATNodeNumber,
	|
	|	T.VATWriteOffDependsOnPeriodOfReceiptDocument,
	|	VATNodes.DocumentReceiptsInCurPeriod,
	|
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	CASE WHEN NOT (VALUETYPE(T.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|		AND T.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))
	|	  AND NOT ISNULL(T.ThisIsAdditionalExpense, FALSE)
	|	  AND NOT ISNULL(T.TheseAreRemainingArticleByArticleVariables, FALSE)
	|	  AND NOT ISNULL(T.TheseRemaindersAreArticleByArticleConstants, FALSE)
	|		THEN T.InventoryLocationAttributesOfReceiptDocument
	|		ELSE VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|	END AS InventoryLocationAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.PreviousRedistributionCosts,
	|	T.TheseAreRemainingArticleByArticleVariables,
	|	T.TheseRemaindersAreArticleByArticleConstants,
	|	T.ThisIsAdditionalExpense,
	|	T.TheseAreVariableAdditionalCosts,
	|
	|	T.SignCostWithVAT,
	|	T.SignCostWithoutVAT,
	|	T.SignValueWithoutVATLocal,
	|	T.LocalVATSign,
	|	T.SignCostWithoutVATMan,
	|	T.VATSignMan,
	|	SUM(T.CostInclVAT) AS CostInclVAT,
	|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(T.CostExcludingVATLocal) AS CostExcludingVATLocal,
	|	SUM(T.VATLocal) AS VATLocal,
	|	SUM(T.CostExcludingVATMan) AS CostExcludingVATMan,
	|	SUM(T.VATManag) AS VATManag
	|INTO TTInitialCostNodesAndVATPreliminary
	|FROM
	|	TTINITIALCOSTSubAssetsExcludingVAT AS T
	|	INNER JOIN TTLotVAT AS VATNodes
	|		ON VATNodes.DocumentInflow = T.DocumentInflow
	|		AND VATNodes.LotVendorAttributesOfReceiptDocument = T.LotVendorAttributesOfReceiptDocument
	|		AND VATNodes.ExpenseItem = T.ExpenseItem
	|		AND VATNodes.DimensionOfExpenses = T.DimensionOfExpenses
	|		AND VATNodes.InventoryLocationAttributesOfReceiptDocument = T.InventoryLocationAttributesOfReceiptDocument
	|		AND VATNodes.PreviousRedistributionCosts = T.PreviousRedistributionCosts
	|		AND VATNodes.TheseAreRemainingArticleByArticleVariables = T.TheseAreRemainingArticleByArticleVariables
	|		AND VATNodes.TheseRemaindersAreArticleByArticleConstants = T.TheseRemaindersAreArticleByArticleConstants
	|		AND VATNodes.ThisIsAdditionalExpense = T.ThisIsAdditionalExpense
	|		AND VATNodes.TheseAreVariableAdditionalCosts = T.TheseAreVariableAdditionalCosts
	|GROUP BY
	|	T.CostNodeNumber,
	|	VATNodes.NodeNumber,
	|	T.VATWriteOffDependsOnPeriodOfReceiptDocument,
	|	VATNodes.DocumentReceiptsInCurPeriod,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	CASE WHEN NOT (VALUETYPE(T.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|		AND T.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))
	|	  AND NOT ISNULL(T.ThisIsAdditionalExpense, FALSE)
	|	  AND NOT ISNULL(T.TheseAreRemainingArticleByArticleVariables, FALSE)
	|	  AND NOT ISNULL(T.TheseRemaindersAreArticleByArticleConstants, FALSE)
	|		THEN T.InventoryLocationAttributesOfReceiptDocument
	|		ELSE VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|	END, //InventoryLocationAttributesOfReceiptDocument
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.PreviousRedistributionCosts,
	|	T.TheseAreRemainingArticleByArticleVariables,
	|	T.TheseRemaindersAreArticleByArticleConstants,
	|	T.ThisIsAdditionalExpense,
	|	T.TheseAreVariableAdditionalCosts,
	|	T.SignCostWithVAT,
	|	T.SignCostWithoutVAT,
	|	T.SignValueWithoutVATLocal,
	|	T.LocalVATSign,
	|	T.SignCostWithoutVATMan,
	|	T.VATSignMan
	|
	|INDEX BY
	|	CostNodeNumber,
	|	DocumentReceiptsInCurPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.CostNodeNumber,
	|	T.DocumentReceiptsInCurPeriod,
	|
	|	SUM(T.CostInclVAT) AS CostInclVAT,
	|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(T.CostExcludingVATLocal) AS CostExcludingVATLocal,
	|	SUM(T.VATLocal) AS VATLocal,
	|	SUM(T.CostExcludingVATMan) AS CostExcludingVATMan,
	|	SUM(T.VATManag) AS VATManag
	|INTO TTInitialCostNodesAndVATGrouped
	|FROM
	|	TTInitialCostNodesAndVATPreliminary AS T
	|GROUP BY
	|	T.CostNodeNumber,
	|	T.DocumentReceiptsInCurPeriod
	|INDEX BY
	|	CostNodeNumber,
	|	DocumentReceiptsInCurPeriod
	|";
	
	Query.Text = StrReplace(Query.Text, "DataTableName", DataTableName);
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, "TTCOSTADJUSTMENTSubAssetsWithWriteOffOfVAT, TTINITIALCOSTSubAssetsExcludingVAT");
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"InventoryLocationAttributesOfReceiptDocument", // Separator
		"CostInclVAT, CostExcludingVAT, CostExcludingVATLocal, VATLocal, CostExcludingVATMan, VATManag", // Resources
		"CostNodeNumber, DocumentReceiptsInCurPeriod", // Order
		"NodeNumberVATGroup", // new line number field
		"CostNodeNumber, DocumentReceiptsInCurPeriod"); // Indexes
	
	CostCalculationAppliedAlgorithms.FillInTemporaryTableRowNumbers(
		CalculationParameters,
		NumberingParameters,
		"TTInitialCostNodesAndVATGrouped");
		
	Query.Text =
	"SELECT
	|	T.CostNodeNumber,
	|	T.VATNodeNumber,
	|	NodesAreGrouped.NodeNumberVATGroup AS NodeNumberVATGroup,
	|
	|	T.VATWriteOffDependsOnPeriodOfReceiptDocument,
	|	T.DocumentReceiptsInCurPeriod,
	|
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.PreviousRedistributionCosts,
	|	T.TheseAreRemainingArticleByArticleVariables,
	|	T.TheseRemaindersAreArticleByArticleConstants,
	|	T.ThisIsAdditionalExpense,
	|	T.TheseAreVariableAdditionalCosts,
	|
	|	T.CostInclVAT AS CostInclVAT,
	|	T.CostExcludingVAT AS CostExcludingVAT,
	|	T.CostExcludingVATLocal AS CostExcludingVATLocal,
	|	T.VATLocal AS VATLocal,
	|	T.CostExcludingVATMan AS CostExcludingVATMan,
	|	T.VATManag AS VATManag,
	|
	|	 T.SignCostWithVAT * NodesAreGrouped.CostInclVAT 				AS TotalCostWithVAT,
	|	 T.SignCostWithoutVAT * NodesAreGrouped.CostExcludingVAT 			AS TotalCostWithoutVAT,
	|	 T.SignValueWithoutVATLocal * NodesAreGrouped.CostExcludingVATLocal 	AS BottomLineCostWithoutVATIsLocal,
	|	 T.LocalVATSign * NodesAreGrouped.VATLocal 							AS SummaryNdseg,
	|	 T.SignCostWithoutVATMan * NodesAreGrouped.CostExcludingVATMan 		AS BottomLineCostWithoutVATMan,
	|	 T.VATSignMan * NodesAreGrouped.VATManag 								AS TotalVATMan,
	|
	| 	CAST(CASE WHEN NodesAreGrouped.CostInclVAT <> 0
	|		THEN T.SignCostWithVAT * T.CostInclVAT / NodesAreGrouped.CostInclVAT
	|		ELSE 0
	|	END AS NUMBER(31,10)) AS ShareCostWithVAT,
	| 	CAST(CASE WHEN NodesAreGrouped.CostExcludingVAT <> 0
	|		THEN T.SignCostWithoutVAT * T.CostExcludingVAT / NodesAreGrouped.CostExcludingVAT
	|		ELSE 0
	|	END AS NUMBER(31,10)) AS ShareCostWithoutVAT,
	| 	CAST(CASE WHEN NodesAreGrouped.CostExcludingVATLocal <> 0
	|		THEN T.SignValueWithoutVATLocal * T.CostExcludingVATLocal / NodesAreGrouped.CostExcludingVATLocal
	|		ELSE 0
	|	END AS NUMBER(31,10)) AS ShareValueExcludingVATLocal,
	| 	CAST(CASE WHEN NodesAreGrouped.VATLocal <> 0
	|		THEN T.LocalVATSign * T.VATLocal / NodesAreGrouped.VATLocal
	|		ELSE 0
	|	END AS NUMBER(31,10)) AS LocalVATShare,
	| 	CAST(CASE WHEN NodesAreGrouped.CostExcludingVATMan <> 0
	|		THEN T.SignCostWithoutVATMan * T.CostExcludingVATMan / NodesAreGrouped.CostExcludingVATMan
	|		ELSE 0
	|	END AS NUMBER(31,10)) AS ShareCostWithoutVATMan,
	| 	CAST(CASE WHEN NodesAreGrouped.VATManag <> 0
	|		THEN  T.VATSignMan * T.VATManag / NodesAreGrouped.VATManag
	|		ELSE 0
	|	END AS NUMBER(31,10)) AS ShareOfVATMan
	|INTO TTInitialCostNodesAndVAT
	|FROM
	|	TTInitialCostNodesAndVATPreliminary AS T
	|	INNER JOIN TTInitialCostNodesAndVATGrouped AS NodesAreGrouped
	|		ON NodesAreGrouped.CostNodeNumber = T.CostNodeNumber
	|	 	AND NodesAreGrouped.DocumentReceiptsInCurPeriod = T.DocumentReceiptsInCurPeriod
	|WHERE
	|	T.CostInclVAT <> 0
	|	OR T.CostExcludingVAT <> 0
	|	OR T.CostExcludingVATLocal <> 0
	|	OR T.VATLocal <> 0
	|	OR T.CostExcludingVATMan <> 0
	|	OR T.VATManag <> 0
	|
	|INDEX BY
	|	NodeNumberVATGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.CostNodeNumber AS CostNodeNumber,
	|	T.NodeNumberVATGroup AS VATNodeNumber,
	|
	|	T.VATWriteOffDependsOnPeriodOfReceiptDocument,
	|	T.DocumentReceiptsInCurPeriod,
	|
	|	SUM(T.CostInclVAT) AS CostInclVAT,
	|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(T.CostExcludingVATLocal) AS CostExcludingVATLocal,
	|	SUM(T.VATLocal) AS VATLocal,
	|	SUM(T.CostExcludingVATMan) AS CostExcludingVATMan,
	|	SUM(T.VATManag) AS VATManag
	|INTO ValueOfBatchesVAT
	|FROM
	|	TTInitialCostNodesAndVAT AS T
	|
	|GROUP BY
	|	T.CostNodeNumber,
	|	T.NodeNumberVATGroup,
	|	T.VATWriteOffDependsOnPeriodOfReceiptDocument,
	|	T.DocumentReceiptsInCurPeriod
	|
	|INDEX BY
	|	VATNodeNumber,
	|	CostNodeNumber
	|";
		
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"TTInitialCostNodesAndVATPreliminary, TTInitialCostNodesAndVATGrouped");
	
	#EndRegion
	
	#Region RegisteredRecordsWithoutCost
	
	Query.Text =
	"SELECT DISTINCT
	|	-1 						  AS SourceNode,
	|	T.CostNodeNumber  AS ReceiverNode,
	|	T.VATNodeNumber 			  AS VATNodeNumber,
	|	FALSE												AS ChangingTypeOfVATActivity,
	|	T.DocumentReceiptsInCurPeriod 			  	AS DocumentReceiptsInCurPeriod,
	|	T.VATWriteOffDependsOnPeriodOfReceiptDocument 	AS VATWriteOffDependsOnPeriodOfReceiptDocument
	|INTO TTNodesStepSources_0
	|FROM
	|	ValueOfBatchesVAT AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.SourceNode,
	|	T.ReceiverNode,
	|	T.VATNodeNumber,
	|	T.ChangingTypeOfVATActivity,
	|	T.DocumentReceiptsInCurPeriod,
	|	T.VATWriteOffDependsOnPeriodOfReceiptDocument
	|INTO TTNodesWithDistributionFields_0
	|FROM
	|	TTNodesStepSources_0 AS T
	|
	|INDEX BY
	|	ReceiverNode
	|";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True, "TTNodesWithDistributionFields_0");
	
	NodeTableName = "TTNodesStepSources_0";
	RelationshipTableName = "TTNodesWithDistributionFields_0";
	
	NumberOfSourceNodes = CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "TTNodesStepSources_0");
	NumberOfLinksProcessed = CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "TTNodesWithDistributionFields_0");
	NumberOfLinksProcessedInPreviousStep = NumberOfLinksProcessed;
	
	IterationNumber = 0;
	ContinueTraversingGraph = (NumberOfSourceNodes > 0);
	
	While ContinueTraversingGraph Do
	
		IterationNumber = IterationNumber + 1;
		
		Query.Text =
		"SELECT DISTINCT
		|	ReceiverNodes_.SourceNodeNumber AS SourceNode,
		|	ReceiverNodes_.ReceiverNodeNumber AS ReceiverNode,
		|	SourceNodes.VATNodeNumber,
		|	ReceiverNodes_.ChangingTypeOfVATActivity,
		|	SourceNodes.DocumentReceiptsInCurPeriod,
		|	SourceNodes.VATWriteOffDependsOnPeriodOfReceiptDocument
		|INTO TTNodesStepSources_1
		|FROM
		|	TTConnectionOfCostAdjustmentNodesWithVATWriteOff AS ReceiverNodes_
		|	INNER JOIN TTNodesStepSources_0 AS SourceNodes
		|		ON ReceiverNodes_.SourceNodeNumber = SourceNodes.ReceiverNode
		|
		|INDEX BY
		|	ReceiverNode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.SourceNode,
		|	T.ReceiverNode,
		|	T.VATNodeNumber,
		|	T.ChangingTypeOfVATActivity,
		|	T.DocumentReceiptsInCurPeriod,
		|	T.VATWriteOffDependsOnPeriodOfReceiptDocument
		|INTO TTNodesWithDistributionFields_1
		|FROM
		|	TTNodesWithDistributionFields_0 AS T
		|
		|UNION
		|
		|SELECT
		|	T.SourceNode,
		|	T.ReceiverNode,
		|	T.VATNodeNumber,
		|	T.ChangingTypeOfVATActivity,
		|	T.DocumentReceiptsInCurPeriod,
		|	T.VATWriteOffDependsOnPeriodOfReceiptDocument
		|FROM
		|	TTNodesStepSources_1 AS T
		|
		|INDEX BY
		|	VATNodeNumber,
		|	ReceiverNode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTNodesStepSources_0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTNodesWithDistributionFields_0
		|";
		
		NodeTableName = "TTNodesStepSources_" + Format(IterationNumber, "NZ=0; NG=");
		RelationshipTableName = "TTNodesWithDistributionFields_" + Format(IterationNumber, "NZ=0; NG=");
		
		Query.Text = StrReplace(Query.Text, "TTNodesStepSources_1", NodeTableName);
		Query.Text = StrReplace(Query.Text, "TTNodesStepSources_0", "TTNodesStepSources_" + Format(IterationNumber - 1, "NZ=0; NG="));
		Query.Text = StrReplace(Query.Text, "TTNodesWithDistributionFields_1", RelationshipTableName);
		Query.Text = StrReplace(Query.Text, "TTNodesWithDistributionFields_0", "TTNodesWithDistributionFields_" + Format(IterationNumber - 1, "NZ=0; NG="));
		
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True, RelationshipTableName);
		
		NumberOfLinksProcessed = CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, RelationshipTableName);
		
		ContinueTraversingGraph = (NumberOfLinksProcessed > NumberOfLinksProcessedInPreviousStep);
		NumberOfLinksProcessedInPreviousStep = NumberOfLinksProcessed;
		
	EndDo; 
	
	StageDescription = NStr("vi = 'Đã thực hiện tích hợp phân bổ lô hàng - %1,
	|	kích thước bảng liên kết - %2';
	|ru = 'Выполнено итераций распределения партий - %1,
	|	размер таблицы связей - %2';
	|en = 'Lot allocation iterations completed - %1,
	|	link table size - %2'; fa = 'Lot allocation iterations completed - %1,
	|	link table size - %2';
	|it = 'È stata eseguita l''iterazione della distribuzione dei lotti - %1,
	|	dimensione della tabella dei collegamenti - %2';
	|pl = 'Wykonano iteracji podziału partii - %1,
	|	rozmiar tabeli powiązań - %2';
	|tr = 'Gerçekleştirilen lot dağıtım yineleme sayısı - %1,
	|	 bağlantı tablosu boyutu - %2'");
	
	StageDescription = StringFunctionsClientServer.SubstituteParametersToString(
		StageDescription,
		CostCalculationProtocol.ValuePresentation(IterationNumber + 1),
		CostCalculationProtocol.ValuePresentation(NumberOfLinksProcessed));
	
	CostCalculationProtocol.AdditionalInformation(CalculationParameters, StageDescription);
	
	#EndRegion
	
	#Region DataForSolvingSLS
	
	Query.Text =
	"SELECT
	|	T.SourceNode,
	|	T.ReceiverNode,
	|	T.VATNodeNumber,
	|	T.ChangingTypeOfVATActivity,
	|	T.DocumentReceiptsInCurPeriod,
	|	T.VATWriteOffDependsOnPeriodOfReceiptDocument
	|INTO TTLinksTable
	|FROM
	|	RelationshipTableName AS T
	|
	|INDEX BY
	|	VATNodeNumber,
	|	ReceiverNode
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RelationshipTableName
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP NodeTableName
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.SourceNode AS NodeNumber,
	|	T.VATNodeNumber AS VATNodeNumber
	|INTO NumberingData
	|FROM
	|	TTLinksTable AS T
	|WHERE
	|	T.SourceNode <> -1
	|
	|UNION
	|
	|SELECT DISTINCT
	|	T.ReceiverNode,
	|	T.VATNodeNumber
	|FROM
	|	TTLinksTable AS T";
	
	Query.Text = StrReplace(Query.Text, "RelationshipTableName", RelationshipTableName);
	Query.Text = StrReplace(Query.Text, "NodeTableName",  NodeTableName);
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"", // Separator
		"", // Resources
		"NodeNumber, VATNodeNumber", // Order
		"NewNodeNumber",
		"VATNodeNumber, NodeNumber");
	
	CostCalculationAppliedAlgorithms.FillInTemporaryTableRowNumbers(
		CalculationParameters,
		NumberingParameters,
		"NumberingData",
		"TTNewNodes");
		
	Query.Text =
	"SELECT
	|	T.SourceNode AS SourceNode,
	|	T.ReceiverNode AS ReceiverNode,
	|	T.VATNodeNumber AS VATNodeNumber,
	|	NewReceiverNodes.NewNodeNumber AS NewReceiverNode,
	|
	|	CASE WHEN T.ChangingTypeOfVATActivity
	|	  AND (NOT T.VATWriteOffDependsOnPeriodOfReceiptDocument OR NOT T.DocumentReceiptsInCurPeriod)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS DeductVAT,
	|
	|	Costs_2.CostInclVAT,
	|	Costs_2.CostExcludingVAT,
	|	Costs_2.CostExcludingVATLocal,
	|	Costs_2.VATLocal,
	|	Costs_2.CostExcludingVATMan,
	|	Costs_2.VATManag
	|INTO TTCalculationResultIsPreliminaryWithoutSources
	|FROM
	|	TTLinksTable AS T
	|		LEFT JOIN ValueOfBatchesVAT AS Costs_2
	|			ON T.VATNodeNumber = Costs_2.VATNodeNumber
	|			AND T.ReceiverNode = Costs_2.CostNodeNumber
	|			AND (T.SourceNode = -1)
	|		LEFT JOIN TTNewNodes AS NewReceiverNodes
	|			ON T.VATNodeNumber = NewReceiverNodes.VATNodeNumber
	|			AND T.ReceiverNode = NewReceiverNodes.NodeNumber
	|INDEX BY
	|	VATNodeNumber,
	|	SourceNode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.SourceNode AS SourceNode,
	|	T.ReceiverNode AS ReceiverNode,
	|	T.VATNodeNumber AS VATNodeNumber,
	|	ISNULL(NewSourceNodes.NewNodeNumber, -1) AS NewSourceNode,
	|	T.NewReceiverNode AS NewReceiverNode,
	|
	|	T.DeductVAT,
	|
	|	T.CostInclVAT,
	|	T.CostExcludingVAT,
	|	T.CostExcludingVATLocal,
	|	T.VATLocal,
	|	T.CostExcludingVATMan,
	|	T.VATManag
	|INTO TTCalculationResultPreliminary
	|FROM
	|	TTCalculationResultIsPreliminaryWithoutSources AS T
	|		LEFT JOIN TTNewNodes AS NewSourceNodes
	|			ON T.VATNodeNumber = NewSourceNodes.VATNodeNumber
	|			AND T.SourceNode = NewSourceNodes.NodeNumber
	|
	|INDEX BY
	|	SourceNode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTCalculationResultIsPreliminaryWithoutSources
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTLinksTable";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	#EndRegion
	
	#Region SolutionOfSLU
	
	ExplanationForMeasurement = NStr("vi = 'Giải pháp cho các lô hàng thuế GTGT';
									|ru = 'Решение для партий НДС';
									|en = 'Solution for VAT lots'; fa = 'Solution for VAT lots';
									|it = 'Soluzione per i lotti IVA';
									|pl = 'Decyzja dla partii VAT';
									|tr = 'KDV lotları için çözüm'", Common.DefaultLanguageCode());
	
	Query.Text =
	"SELECT
	|	COUNT(DISTINCT T.NewReceiverNode) AS Count
	|FROM
	|	TTCalculationResultPreliminary AS T
	|";
	
	Selection = Query.Execute().Select();
	Selection.Next();
	NodeCount = Selection.Count;
	
	Query.Text =
	"SELECT
	|	COUNT(*) AS Count
	|FROM
	|	(SELECT DISTINCT
	|		T.NewSourceNode AS Source,
	|		T.NewReceiverNode AS Receiver
	|	FROM
	|		TTCalculationResultPreliminary AS T
	|	WHERE
	|		T.NewSourceNode <> -1
	|	) AS T
	|";
	
	Selection = Query.Execute().Select();
	Selection.Next();
	LinkCount = Selection.Count;
	
	ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Nút hệ phương trình tuyến tính: %1, liên kết hệ phương trình tuyến tính: %2';
			|ru = 'Узлов СЛУ: %1, связей СЛУ: %2';
			|en = 'LES nodes:%1, LES links:%2'; fa = 'LES nodes:%1, LES links:%2';
			|it = 'Di nodi SLE: %1, di collegamenti SLE: %2';
			|pl = 'Węzłów URL: %1, powiązań URL: %2';
			|tr = 'DDS üniteleri: %1, DDS bağlantıları: %2'"),
		NodeCount,
		LinkCount);
		
	CostCalculationProtocol.AdditionalInformation(CalculationParameters, ProtocolText_, ProtocolText_);
	
	ThereIsWriteOffOfVAT = False;
	
	Query.Text =
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	TTCommunicationNodesCostAdjustmentNetInitialCostLocal AS T";
	
	ThereIsZeroingOfNetInitialCostLocal = Not Query.Execute().IsEmpty();
	
	RequestNodes = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(RequestNodes, CalculationParameters);
	
	RequestNodes.Text = QueryTextVATNodes();
	
	CommunicationRequest = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(CommunicationRequest, CalculationParameters);
	
	CommunicationRequest.Text = TextOfVATConnectionRequest(ThereAreArticleByArticle);
	
	// adjusting the cost of nodes with zero weight
	SLEFieldStructure = New Structure;
	SLEFieldStructure.Insert("Weight", "CostInclVAT, CostExcludingVAT, CostExcludingVATLocal, VATLocal, CostExcludingVATMan, VATManag");
	SLEFieldStructure.Insert("VATWeight", "VATDeduction_");
	SLEFieldStructure.Insert("WeightConversion", "Initial_Cost");
	SLEFieldStructure.Insert("WeightTransferNettingInitialCostLOCAL", "TransferOfNettedInitialCostLocal");
	
	CalculationParameters.Insert("OptimizeSLE", False);
	
	CostCalculationAppliedAlgorithms.AdjustCostOfNodesSLEFromQueries(
		CalculationParameters,
		RequestNodes,
		"NodeNumber",
		CommunicationRequest,
		"Source, Receiver",
		SLEFieldStructure,
		ExplanationForMeasurement);
		
	CalculationParameters.Insert("OptimizeSLE", True);
	
	MatrixOfNodes  = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, RequestNodes,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'nút';
																																													|ru = 'узлы';
																																													|en = 'nodes'; fa = 'nodes';
																																													|it = 'nodi';
																																													|pl = 'węzły';
																																													|tr = 'üniteler'", Common.DefaultLanguageCode()));
	RelationshipMatrix = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, CommunicationRequest,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'liên kết';
																																																|ru = 'связи';
																																																|en = 'links'; fa = 'links';
																																																|it = 'collegamenti';
																																																|pl = 'powiązania';
																																																|tr = 'bağlantılar'", Common.DefaultLanguageCode()));
	
	CostCalculationProtocol.StartOfCodeSnippetExecution(CalculationParameters, "SolveSystemOfLinearEquations", ExplanationForMeasurement);
	SystemOfLinearEquationsCalculation = CostCalculationLESSolution.GetComponentToSolveSLU(CalculationParameters);
	
	SystemOfLinearEquationsCalculation.NodeDataSource = MatrixOfNodes;
	SystemOfLinearEquationsCalculation.RelationDataSource = RelationshipMatrix;
	
	// description of key columns
	SystemOfLinearEquationsCalculation.EquationsInNodesColumn = "NodeNumber";
	SystemOfLinearEquationsCalculation.EquationsInRelationsColumn = "Receiver";
	SystemOfLinearEquationsCalculation.VariablesInRelationsColumn = "Source";
	
	// description of the system
	SolutionColumnNames = ""; // The order of the fields must match the names of the columns of the nodes in the system description calls.Add()
	
	If AdvancedCostAccountingForVATLots Then
		
		SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
		SystemDetails.FactorsInNodesColumn = "CostInclVAT";
		SystemDetails.FactorsInRelationsColumn = "Weight";
		
		SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
		SystemDetails.FactorsInNodesColumn = "CostExcludingVAT";
		SystemDetails.FactorsInRelationsColumn = "Weight";
		
		SolutionColumnNames = SolutionColumnNames + ?(SolutionColumnNames = "", "", ", ") + "CostInclVAT, CostExcludingVAT";
		
	EndIf;
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostExcludingVATLocal";
	SystemDetails.FactorsInRelationsColumn = "Weight";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "VATLocal";
	SystemDetails.FactorsInRelationsColumn = "Weight";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostExcludingVATMan";
	SystemDetails.FactorsInRelationsColumn = "Weight";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "VATManag";
	SystemDetails.FactorsInRelationsColumn = "Weight";
	
	SolutionColumnNames = SolutionColumnNames + ?(SolutionColumnNames = "", "", ", ") + "CostExcludingVATLocal, VATLocal, CostExcludingVATMan, VATManag";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "Initial_Cost";
	SystemDetails.FactorsInRelationsColumn = "WeightConversion";
	
	SolutionColumnNames = SolutionColumnNames + ?(SolutionColumnNames = "", "", ", ") + "Initial_Cost";
	
	If ThereIsWriteOffOfVAT Then
		
		SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
		SystemDetails.FactorsInNodesColumn = "VATDeduction_";
		SystemDetails.FactorsInRelationsColumn = "VATWeight";
		
		SolutionColumnNames = SolutionColumnNames + ?(SolutionColumnNames = "", "", ", ") + "VATDeduction_";
		
	EndIf;
	
	If ThereIsZeroingOfNetInitialCostLocal Then
		
		SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
		SystemDetails.FactorsInNodesColumn = "TransferOfNettedInitialCostLocal";
		SystemDetails.FactorsInRelationsColumn = "WeightTransferNettingInitialCostLOCAL";
		
		SolutionColumnNames = SolutionColumnNames + ?(SolutionColumnNames = "", "", ", ") + "TransferOfNettedInitialCostLocal";
		
	EndIf;
	
	// Decision
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);

	CostCalculationProtocol.EndOfCodeSnippetExecution(CalculationParameters);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(SolutionColumnNames);
	SLULoadingParameters.NumberOfDigits = 31;
	SLULoadingParameters.ConsiderZeroSolutions = False;
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
	
	DecisionTable = Undefined;
	
	#EndRegion
	
	#Region PreparationOfNationalVATRegisters
	
	Query.Text = "
	|SELECT
	|	T.NewNodeNumber,
	|   T.NodeNumber,
	|	T.VATNodeNumber
	|INTO TTNewNodesIndexed
	|FROM
	|	TTNewNodes AS T
	|INDEX BY
	|	NewNodeNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|   T.NodeNumber,
	|	T.VATNodeNumber,
	|	CASE WHEN Decisions.Initial_Cost <> 0 THEN TRUE ELSE FALSE END AS Initial_Cost,
	|	CASE WHEN &FieldTransfersNetInitialCostLocal <> 0 THEN TRUE ELSE FALSE END AS TransferOfNettedInitialCostLocal,
	| 	SUM(&CostFieldWithVAT) AS CostInclVAT,
	| 	SUM(&CostFieldExcludingVAT) AS CostExcludingVAT,
	| 	SUM(Decisions.CostExcludingVATLocal) AS CostExcludingVATLocal,
	| 	SUM(Decisions.VATLocal) AS VATLocal,
	| 	SUM(Decisions.CostExcludingVATMan) AS CostExcludingVATMan,
	| 	SUM(Decisions.VATManag) AS VATManag
	|INTO SolutionsTableExpanded
	|FROM
	|	TTNewNodesIndexed AS T
	|	INNER JOIN DecisionTable AS Decisions
	|		ON T.NewNodeNumber = Decisions.NodeNumber
	|GROUP BY
	|   T.NodeNumber,
	|	T.VATNodeNumber,
	|	CASE WHEN Decisions.Initial_Cost <> 0 THEN TRUE ELSE FALSE END,
	|	CASE WHEN &FieldTransfersNetInitialCostLocal <> 0 THEN TRUE ELSE FALSE END
	|
	|INDEX BY
	|	VATNodeNumber
	|";
	
	If AdvancedCostAccountingForVATLots Then
		Query.Text = StrReplace(Query.Text, "&CostFieldWithVAT",	 "Decisions.CostInclVAT");
		Query.Text = StrReplace(Query.Text, "&CostFieldExcludingVAT", "Decisions.CostExcludingVAT");
	Else
		Query.SetParameter("CostFieldWithVAT",	 0);
		Query.SetParameter("CostFieldExcludingVAT", 0);
	EndIf;
	
	If ThereIsWriteOffOfVAT Then
		Query.Text = StrReplace(Query.Text, "&VATDeductionField", "Decisions.VATDeduction_");
	Else
		Query.SetParameter("VATDeductionField", 1);
	EndIf;
	
	If ThereIsZeroingOfNetInitialCostLocal Then
		Query.Text = StrReplace(Query.Text, "&FieldTransfersNetInitialCostLocal", "Decisions.TransferOfNettedInitialCostLocal");
	Else
		Query.SetParameter("FieldTransfersNetInitialCostLocal", 1);
	EndIf;
	
	Query.SetParameter("RoundingErrorOfSolutionIs", 0.00000001);
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, "DecisionTable");
	
	Query.Text = "
	|SELECT
	|	T.NodeNumber AS NodeNumber,
	|	VATNodes.TheseAreRemainingArticleByArticleVariables AS TheseAreRemainingArticleByArticleVariables,
	|	VATNodes.TheseRemaindersAreArticleByArticleConstants AS TheseRemaindersAreArticleByArticleConstants,
	|	VATNodes.ThisIsAdditionalExpense AS ThisIsAdditionalExpense,
	|	VATNodes.TheseAreVariableAdditionalCosts AS TheseAreVariableAdditionalCosts,
	|	VATNodes.ExpenseItem AS ExpenseItem,
	|	VATNodes.DimensionOfExpenses AS DimensionOfExpenses,
	|	VATNodes.DocumentInflow AS DocumentInflow,
	|	VATNodes.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	VATNodes.InventoryLocationAttributesOfReceiptDocument AS InventoryLocationAttributesOfReceiptDocument,
	|	(T.Initial_Cost AND NOT VATNodes.PreviousRedistributionCosts) AS Initial_Cost,
	|	T.TransferOfNettedInitialCostLocal,
	| 	SUM(CAST(CASE WHEN VATNodes.ShareCostWithVAT = 0 OR VATNodes.ShareCostWithVAT = 1 OR VATNodes.ShareCostWithVAT = -1
	|			THEN T.CostInclVAT * VATNodes.ShareCostWithVAT
	|			ELSE T.CostInclVAT * VATNodes.CostInclVAT / VATNodes.TotalCostWithVAT
	|		END AS NUMBER(31,10))) AS CostInclVAT,
	| 	SUM(CAST(CASE WHEN VATNodes.ShareCostWithoutVAT = 0 OR VATNodes.ShareCostWithoutVAT = 1 OR VATNodes.ShareCostWithoutVAT = -1
	|			THEN T.CostExcludingVAT * VATNodes.ShareCostWithoutVAT
	|			ELSE T.CostExcludingVAT * VATNodes.CostExcludingVAT / VATNodes.TotalCostWithoutVAT
	|		END AS NUMBER(31,10))) AS CostExcludingVAT,
	| 	SUM(CAST(CASE WHEN VATNodes.ShareValueExcludingVATLocal = 0 OR VATNodes.ShareValueExcludingVATLocal = 1 OR VATNodes.ShareValueExcludingVATLocal = -1
	|			THEN T.CostExcludingVATLocal * VATNodes.ShareValueExcludingVATLocal
	|			ELSE T.CostExcludingVATLocal * VATNodes.CostExcludingVATLocal / VATNodes.BottomLineCostWithoutVATIsLocal
	|		END AS NUMBER(31,10))) AS CostExcludingVATLocal,
	| 	SUM(CAST(CASE WHEN VATNodes.LocalVATShare = 0 OR VATNodes.LocalVATShare = 1 OR VATNodes.LocalVATShare = -1
	|			THEN T.VATLocal * VATNodes.LocalVATShare
	|			ELSE T.VATLocal * VATNodes.VATLocal / VATNodes.SummaryNdseg
	|		END AS NUMBER(31,10))) AS VATLocal,
	| 	SUM(CAST(CASE WHEN VATNodes.ShareCostWithoutVATMan = 0 OR VATNodes.ShareCostWithoutVATMan = 1 OR VATNodes.ShareCostWithoutVATMan = -1
	|			THEN T.CostExcludingVATMan * VATNodes.ShareCostWithoutVATMan
	|			ELSE T.CostExcludingVATMan * VATNodes.CostExcludingVATMan / VATNodes.BottomLineCostWithoutVATMan
	|		END AS NUMBER(31,10))) AS CostExcludingVATMan,
	| 	SUM(CAST(CASE WHEN VATNodes.ShareOfVATMan = 0 OR VATNodes.ShareOfVATMan = 1 OR VATNodes.ShareOfVATMan = -1
	|			THEN T.VATManag * VATNodes.ShareOfVATMan
	|			ELSE T.VATManag * VATNodes.VATManag / VATNodes.TotalVATMan
	|		END AS NUMBER(31,10))) AS VATManag
	|INTO TableOfSolutionsInDetail
	|FROM
	|	SolutionsTableExpanded AS T
	|	INNER JOIN TTInitialCostNodesAndVAT AS VATNodes
	|		ON T.VATNodeNumber = VATNodes.NodeNumberVATGroup
	|
	|GROUP BY
	|	T.NodeNumber,
	|	VATNodes.TheseAreRemainingArticleByArticleVariables,
	|	VATNodes.TheseRemaindersAreArticleByArticleConstants,
	|	VATNodes.ThisIsAdditionalExpense,
	|	VATNodes.TheseAreVariableAdditionalCosts,
	|	VATNodes.ExpenseItem,
	|	VATNodes.DimensionOfExpenses,
	|	VATNodes.DocumentInflow,
	|	VATNodes.LotVendorAttributesOfReceiptDocument,
	|	VATNodes.InventoryLocationAttributesOfReceiptDocument,
	|	(T.Initial_Cost AND NOT VATNodes.PreviousRedistributionCosts),
	|	T.TransferOfNettedInitialCostLocal
	|
	|INDEX BY
	|	NodeNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.NodeNumber,
	|	T.TheseAreRemainingArticleByArticleVariables,
	|	T.TheseRemaindersAreArticleByArticleConstants,
	|	T.ThisIsAdditionalExpense,
	|	T.TheseAreVariableAdditionalCosts,
	|
	|	&BeginOfPeriod AS Period,
	|	CostNodes.Organization AS Organization,
	|	CostNodes.AccountingSection,
	|	CostNodes.ItemsLocationAttributes,
	|	CostNodes.Products AS Products,
	|	CostNodes.Characteristic,
	|	CostNodes.InventoryOwnerAttribute,
	|	CostNodes.Lot AS Lot,
	|	CostNodes.LotVendorAttributes,
	|	CostNodes.VATActivityType,
	|	CostNodes.FinancialAccountingDimension,
	|	CASE WHEN CostNodes.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		THEN CostNodes.ItemsLocationAttributes
	|		ELSE VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|	END AS WIPInventoryLocationAttributes,
	|	CostNodes.LotQuantity AS LotQuantity,
	|
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|
	|	T.Initial_Cost AS Initial_Cost,
	|	T.TransferOfNettedInitialCostLocal,
	|	CAST(
	|		CASE WHEN T.CostInclVAT - CAST(T.CostInclVAT AS NUMBER(31,4)) BETWEEN -&RoundingErrorOfSolutionIs AND &RoundingErrorOfSolutionIs
	|			THEN CAST(T.CostInclVAT AS NUMBER(31,4))
	|			ELSE T.CostInclVAT
	|		END AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(
	|		CASE WHEN T.CostExcludingVAT - CAST(T.CostExcludingVAT AS NUMBER(31,4)) BETWEEN -&RoundingErrorOfSolutionIs AND &RoundingErrorOfSolutionIs
	|			THEN CAST(T.CostExcludingVAT AS NUMBER(31,4))
	|			ELSE T.CostExcludingVAT
	|		END AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(
	|		CASE WHEN T.CostExcludingVATLocal - CAST(T.CostExcludingVATLocal AS NUMBER(31,4)) BETWEEN -&RoundingErrorOfSolutionIs AND &RoundingErrorOfSolutionIs
	|			THEN CAST(T.CostExcludingVATLocal AS NUMBER(31,4))
	|			ELSE T.CostExcludingVATLocal
	|		END AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(
	|		CASE WHEN T.VATLocal - CAST(T.VATLocal AS NUMBER(31,4)) BETWEEN -&RoundingErrorOfSolutionIs AND &RoundingErrorOfSolutionIs
	|			THEN CAST(T.VATLocal AS NUMBER(31,4))
	|			ELSE T.VATLocal
	|		END AS NUMBER(31,10)) AS VATLocal,
	|	CAST(
	|		CASE WHEN T.CostExcludingVATMan - CAST(T.CostExcludingVATMan AS NUMBER(31,4)) BETWEEN -&RoundingErrorOfSolutionIs AND &RoundingErrorOfSolutionIs
	|			THEN CAST(T.CostExcludingVATMan AS NUMBER(31,4))
	|			ELSE T.CostExcludingVATMan
	|		END AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(
	|		CASE WHEN T.VATManag - CAST(T.VATManag AS NUMBER(31,4)) BETWEEN -&RoundingErrorOfSolutionIs AND &RoundingErrorOfSolutionIs
	|			THEN CAST(T.VATManag AS NUMBER(31,4))
	|			ELSE T.VATManag
	|		END AS NUMBER(31,10)) AS VATManag
	|INTO TTNodePricesInDetail
	|FROM
	|	TableOfSolutionsInDetail AS T
	|	LEFT JOIN TTCOSTAdjustmentSubAssetsWithBATCHBalances AS CostNodes
	|		ON CostNodes.NodeNumber = T.NodeNumber
	|WHERE
	|	CostNodes.Lot <> UNDEFINED
	|	AND
	|	(CAST(
	|		CASE WHEN T.CostInclVAT - CAST(T.CostInclVAT AS NUMBER(31,4)) BETWEEN -&RoundingErrorOfSolutionIs AND &RoundingErrorOfSolutionIs
	|			THEN CAST(T.CostInclVAT AS NUMBER(31,4))
	|			ELSE T.CostInclVAT
	|		END AS NUMBER(31,10)) <> 0
	|	OR CAST(
	|		CASE WHEN T.CostExcludingVAT - CAST(T.CostExcludingVAT AS NUMBER(31,4)) BETWEEN -&RoundingErrorOfSolutionIs AND &RoundingErrorOfSolutionIs
	|			THEN CAST(T.CostExcludingVAT AS NUMBER(31,4))
	|			ELSE T.CostExcludingVAT
	|		END AS NUMBER(31,10)) <> 0
	|	OR CAST(
	|		CASE WHEN T.CostExcludingVATLocal - CAST(T.CostExcludingVATLocal AS NUMBER(31,4)) BETWEEN -&RoundingErrorOfSolutionIs AND &RoundingErrorOfSolutionIs
	|			THEN CAST(T.CostExcludingVATLocal AS NUMBER(31,4))
	|			ELSE T.CostExcludingVATLocal
	|		END AS NUMBER(31,10)) <> 0
	|	OR CAST(
	|		CASE WHEN T.VATLocal - CAST(T.VATLocal AS NUMBER(31,4)) BETWEEN -&RoundingErrorOfSolutionIs AND &RoundingErrorOfSolutionIs
	|			THEN CAST(T.VATLocal AS NUMBER(31,4))
	|			ELSE T.VATLocal
	|		END AS NUMBER(31,10)) <> 0
	|	OR CAST(
	|		CASE WHEN T.CostExcludingVATMan - CAST(T.CostExcludingVATMan AS NUMBER(31,4)) BETWEEN -&RoundingErrorOfSolutionIs AND &RoundingErrorOfSolutionIs
	|			THEN CAST(T.CostExcludingVATMan AS NUMBER(31,4))
	|			ELSE T.CostExcludingVATMan
	|		END AS NUMBER(31,10)) <> 0
	|	OR CAST(
	|		CASE WHEN T.VATManag - CAST(T.VATManag AS NUMBER(31,4)) BETWEEN -&RoundingErrorOfSolutionIs AND &RoundingErrorOfSolutionIs
	|			THEN CAST(T.VATManag AS NUMBER(31,4))
	|			ELSE T.VATManag
	|		END AS NUMBER(31,10)) <> 0)
	|	
	|INDEX BY
	|	ExpenseItem
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Organization AS Organization,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses
	|INTO TTCostAnalysisAndVAT
	|FROM
	|	TTNodePricesInDetail AS T
	|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
	|		ON AssetRef.Ref = T.ExpenseItem
	|WHERE
	|	T.DimensionOfExpenses <> UNDEFINED
	|	AND (VALUETYPE(T.DimensionOfExpenses) IN (&TypesOfBatchDocuments)
	|		OR VALUETYPE(T.DimensionOfExpenses) IN (&TypesOfVariableCostAnalysts))
	|	AND (AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		OR AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|	AND NOT T.TheseAreRemainingArticleByArticleVariables
	|	AND NOT T.TheseRemaindersAreArticleByArticleConstants
	|INDEX BY
	|	Organization,
	|	DimensionOfExpenses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Formation of a data selection table for movements according to the register "Detailing the cost of goods and the cost of money".
	// Additional expenses are included in the register of "Details of the cost of goods and State expenses".:
	// - related to the party of the previous period
	// - movements of goods distributed on the document
	// - distributed to the warehouse or to the nomenclature (such additional expenses are distributed to the balances and receipts of goods)
	// 	 distributed to other expenses
	|SELECT
	|	T.Organization AS Organization,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses
	|INTO TTSelectionOfCostAnalysisAndVATVariables
	|FROM
	|	TTCostAnalysisAndVAT AS T
	|	LEFT JOIN InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|		ON SourceDocumentsData.Organization = T.Organization
	|		AND SourceDocumentsData.Document = T.DimensionOfExpenses
	|WHERE
	|	(SourceDocumentsData.RecorderDate IS NOT NULL
	|		AND BEGINOFPERIOD(ISNULL(SourceDocumentsData.RecorderDate, &BeginOfPeriod), MONTH) < &BeginOfPeriod)
	|	OR VALUETYPE(T.DimensionOfExpenses) IN (&TypesOfVariableCostAnalysts)
	|INDEX BY
	|	Organization,
	|	DimensionOfExpenses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic
	|INTO TTPartySelection
	|FROM
	|	TTNodePricesInDetail AS T
	|INDEX BY
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALSE AS ThereAreRegisteredRecords,
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|
	|	NOT T.Initial_Cost AS PreviousRedistributionCosts,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|
	|	MAX(T.CostInclVAT) AS CostInclVAT,
	|	MAX(T.CostExcludingVAT) AS CostExcludingVAT,
	|	MAX(T.CostExcludingVATLocal) AS CostExcludingVATLocal,
	|	MAX(T.VATLocal) AS VATLocal,
	|	MAX(T.CostExcludingVATMan) AS CostExcludingVATMan,
	|	MAX(T.VATManag) AS VATManag
	|INTO TTNodePricesAreConstantPreliminary
	|FROM
	|	TTNodePricesInDetail AS T
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON T.ExpenseItem = ExpenseItems.Ref
	|WHERE
	|	ExpenseItems.Ref IS NULL
	|	AND NOT T.ThisIsAdditionalExpense
	|	AND NOT T.TheseAreRemainingArticleByArticleVariables
	|	AND NOT T.TheseRemaindersAreArticleByArticleConstants		
	|	AND NOT (VALUETYPE(T.Lot) = TYPE(Catalog.ProductionLots)
	|		AND VALUETYPE(T.DocumentInflow) = TYPE(Document.ProductionStage2_2)
	|		AND T.Lot = CAST(T.DocumentInflow AS Document.ProductionStage2_2).ProductionLot
	|		AND NOT T.Initial_Cost
	|		AND CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products = CAST(T.InventoryLocationAttributesOfReceiptDocument AS Catalog.InventoryLocationAttributeKeys).Products
	|		AND CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Characteristic = CAST(T.InventoryLocationAttributesOfReceiptDocument AS Catalog.InventoryLocationAttributeKeys).Characteristic
	|		)
	|GROUP BY
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|	NOT T.Initial_Cost,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE AS ThereAreRegisteredRecords,
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|
	|	T.PreviousRedistributionCosts,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS T
	|	INNER JOIN TTPartySelection AS Filter
	|		ON T.Lot = Filter.Lot
	|		AND T.LotVendorAttributes = Filter.LotVendorAttributes
	|		AND T.Organization = Filter.Organization
	|		AND T.InventoryOwnerAttribute = Filter.InventoryOwnerAttribute
	|		AND T.Products = Filter.Products
	|		AND T.Characteristic = Filter.Characteristic
	|WHERE
	|	T.RegistrationPeriod < &BeginOfPeriod
    |
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BeginOfPeriod AS RegistrationPeriod,
	|
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|
	|	T.PreviousRedistributionCosts,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|
	|	SUM(T.CostInclVAT) AS CostInclVAT,
	|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(T.CostExcludingVATLocal) AS CostExcludingVATLocal,
	|	SUM(T.VATLocal) AS VATLocal,
	|	SUM(T.CostExcludingVATMan) AS CostExcludingVATMan,
	|	SUM(T.VATManag) AS VATManag
	|INTO TTNodePricesAreConstant
	|FROM
	|	TTNodePricesAreConstantPreliminary AS T
	|GROUP BY
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|	T.PreviousRedistributionCosts,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument
	|HAVING
	|	MAX(T.ThereAreRegisteredRecords) = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTNodePricesAreConstantPreliminary
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALSE AS ThereAreRegisteredRecords,
	|	CASE WHEN T.TheseAreRemainingArticleByArticleVariables AND NOT T.TheseAreVariableAdditionalCosts THEN TRUE ELSE FALSE END AS InclusionOfVariablesInCost,
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|
	|	NOT T.Initial_Cost AS PreviousRedistributionCosts,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|
	|	MAX(T.CostInclVAT) AS CostInclVAT,
	|	MAX(T.CostExcludingVAT) AS CostExcludingVAT,
	|	MAX(T.CostExcludingVATLocal) AS CostExcludingVATLocal,
	|	MAX(T.VATLocal) AS VATLocal,
	|	MAX(T.CostExcludingVATMan) AS CostExcludingVATMan,
	|	MAX(T.VATManag) AS VATManag
	|INTO TTNodePricesArticleByArticleConstantPreliminary
	|FROM
	|	TTNodePricesInDetail AS T
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON T.ExpenseItem = ExpenseItems.Ref
	|WHERE
	|	(NOT ExpenseItems.Ref IS NULL
	|		OR (T.ThisIsAdditionalExpense AND NOT T.TheseAreVariableAdditionalCosts)
	// A condition for import customs declarations with additional expenses for the receipt document of the previous period, transferred to another batch.
	// These expenses are reclassified from variable to constant.
	|		OR (T.ThisIsAdditionalExpense AND T.TheseAreVariableAdditionalCosts AND NOT T.Initial_Cost)
	|		OR (T.TheseAreRemainingArticleByArticleVariables AND NOT T.Initial_Cost)
	|		OR T.TheseRemaindersAreArticleByArticleConstants)
	// A condition for import customs declarations with additional expenses for the receipt document of the previous period, which are both additional expenses and variable additional expenses at the same time
	|	AND NOT (T.ThisIsAdditionalExpense AND T.TheseAreVariableAdditionalCosts AND T.Initial_Cost)
	|	AND (NOT T.TheseAreRemainingArticleByArticleVariables OR NOT T.Initial_Cost)
	|	AND (NOT T.Initial_Cost
	|		OR NOT (TRUE IN (SELECT TOP 1 TRUE
	|						  FROM TTSelectionOfCostAnalysisAndVATVariables AS Filter
	|						  WHERE 
	|							T.Organization = Filter.Organization
	|							AND T.DimensionOfExpenses = Filter.DimensionOfExpenses
	|							AND T.ExpenseItem = Filter.ExpenseItem)))
	|GROUP BY
	|	CASE WHEN T.TheseAreRemainingArticleByArticleVariables AND NOT T.TheseAreVariableAdditionalCosts THEN TRUE ELSE FALSE END,
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|	NOT T.Initial_Cost,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE AS ThereAreRegisteredRecords,
	|	FALSE AS InclusionOfVariablesInCost,
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|
	|	T.PreviousRedistributionCosts,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	InformationRegister.ItemizeLotCostItemizedAndOtherCosts AS T
	|	INNER JOIN TTPartySelection AS Filter
	|		ON T.Lot = Filter.Lot
	|		AND T.LotVendorAttributes = Filter.LotVendorAttributes
	|		AND T.Organization = Filter.Organization
	|		AND T.InventoryOwnerAttribute = Filter.InventoryOwnerAttribute
	|		AND T.Products = Filter.Products
	|		AND T.Characteristic = Filter.Characteristic
	|WHERE
	|	T.RegistrationPeriod < &BeginOfPeriod
    |
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BeginOfPeriod AS RegistrationPeriod,
	|
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|
	|	T.PreviousRedistributionCosts,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|
	|	SUM(T.CostInclVAT) AS CostInclVAT,
	|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(T.CostExcludingVATLocal) AS CostExcludingVATLocal,
	|	SUM(T.VATLocal) AS VATLocal,
	|	SUM(T.CostExcludingVATMan) AS CostExcludingVATMan,
	|	SUM(T.VATManag) AS VATManag
	|INTO TTNodePricesArticleByArticleConstant
	|FROM
	|	TTNodePricesArticleByArticleConstantPreliminary AS T
	|GROUP BY
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic,
	|	T.PreviousRedistributionCosts,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument
	|HAVING
	|	MAX(T.ThereAreRegisteredRecords) = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTNodePricesArticleByArticleConstantPreliminary
	|";
	
	TypesOfVariableCostAnalysts = New Array;
	TypesOfVariableCostAnalysts.Add(Type("DocumentRef.InventoryTransfer"));
	TypesOfVariableCostAnalysts.Add(Type("DocumentRef.ReceiptOfGoodsFromCustodian"));
	
	TypesOfVariableCostAnalysts.Add(Type("CatalogRef.Warehouses"));
	TypesOfVariableCostAnalysts.Add(Type("CatalogRef.Products"));
	TypesOfVariableCostAnalysts.Add(Type("CatalogRef.OtherExpenses"));
	TypesOfVariableCostAnalysts.Add(Type("CatalogRef.Partners"));
	TypesOfVariableCostAnalysts.Add(Type("CatalogRef.CounterpartyContracts"));
	
	Query.SetParameter("TypesOfVariableCostAnalysts", TypesOfVariableCostAnalysts);
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, "DecisionTable");
	
	#EndRegion

	#Region AdditionOfRegisterRecordsOfUnfinishedProductionRegisters
	
	If ThereAreArticleByArticle Then
		
		Query.Text =
		"SELECT
		|	CostNodes.NodeNumber,
		|	CostNodes.Organization,
		|	CostNodes.Lot,
		|	CostNodes.Department,
		|	CostNodes.LineOfBusiness,
		|	CostNodes.ExpenseItem,
		|	CostNodes.DimensionOfExpenses,
		|	CostNodes.ProductCostElement,
		|	CostNodes.ProductsGroup,
		|	CostNodes.RuleOfCostAllocatingToProductionLots,
		|	T.DocumentInflow,
		|	T.LotVendorAttributesOfReceiptDocument,
		|
		|	CAST(T.CostInclVAT * CostNodes.Weight AS NUMBER(31,10)) AS CostInclVAT,
		|	CAST(T.CostExcludingVAT * CostNodes.Weight AS NUMBER(31,10)) AS CostExcludingVAT,
		|	CAST(T.CostExcludingVATLocal * CostNodes.Weight AS NUMBER(31,10)) AS CostExcludingVATLocal,
		|	CAST(T.VATLocal * CostNodes.Weight AS NUMBER(31,10)) AS VATLocal,
		|	CAST(T.CostExcludingVATMan * CostNodes.Weight AS NUMBER(31,10)) AS CostExcludingVATMan,
		|	CAST(T.VATManag * CostNodes.Weight AS NUMBER(31,10)) AS VATManag
		|INTO TTAmountsInUnfinishedProductionNodes
		|FROM
		|	TableOfSolutionsInDetail AS T
		|	INNER JOIN TTUnfinishedProductionAdjustmentNodes AS CostNodes
		|		ON CostNodes.NodeNumber = T.NodeNumber
		|	
		|INDEX BY
		|	ExpenseItem";
		
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
		
		If CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "TTAmountsInUnfinishedProductionNodes") > 0 Then
			
			Query.Text =
			"SELECT
			|	T.ThereIsPrice,
			|	T.EntryType,
			|	T.Period,
			|	T.Recorder,
			|	T.RecordType,
			|	T.Organization,
			|	T.ItemsLocationAttributes,
			|	T.InventoryOwnerAttribute,
			|	T.CorItemsLocationAttributes,
			|	T.CorInventoryOwnerAttribute,
			|	T.Lot,
			|	T.LotVendorAttributes,
			|	T.VATActivityType,
			|	T.DocumentInflow,
			|	T.DocumentReceiptsInCurPeriod,
			|	T.LotVendorAttributesOfReceiptDocument,
			|	T.LineOfBusiness,
			|	T.ProductCostElement,
			|	T.ProductsGroup,
			|	T.RuleOfCostAllocatingToProductionLots,
			|	T.BusinessOperation,
			|	T.CorVATActivityTypes,
			|	T.CorAccountingSection,
			|	T.CorLineOfBusiness,
			|	T.Department,
			|	T.ExpenseItemAssets,
			|	T.DimensionOfExpenses,
			|	T.DebitBusinessUnit,
			|	T.VATWriteOffItem,
			|	T.DimensionVATWriteOff,
			|	T.AccountingSection,
			|	T.FinancialAccountingDimension,
			|
			|	T.CostInclVAT,
			|	T.CostExcludingVAT,
			|	T.CostExcludingVATLocal,
			|	T.VATLocal,
			|	T.CostExcludingVATMan,
			|	T.VATManag
			|INTO TTWriteOffOfItemByItemCostsAugmented 
			|FROM
			|	TTWriteOffOfItemByItemCosts AS T
			|WHERE
			|	T.ThereIsPrice 
			|
			|UNION ALL
			|
			|SELECT
			|	TRUE AS ThereIsPrice,
			|	T.EntryType,
			|	T.Period,
			|	T.Recorder,
			|	T.RecordType,
			|	T.Organization,
			|	T.ItemsLocationAttributes,
			|	T.InventoryOwnerAttribute,
			|	T.CorItemsLocationAttributes,
			|	T.CorInventoryOwnerAttribute,
			|	T.Lot,
			|	T.LotVendorAttributes,
			|	T.VATActivityType,
			|	CostNodes.DocumentInflow,
			|	TRUE AS DocumentReceiptsInCurPeriod,
			|	CostNodes.LotVendorAttributesOfReceiptDocument,
			|	T.LineOfBusiness,
			|	T.ProductCostElement,
			|	T.ProductsGroup,
			|	T.RuleOfCostAllocatingToProductionLots,
			|	T.BusinessOperation,
			|	T.CorVATActivityTypes,
			|	T.CorAccountingSection,
			|	T.CorLineOfBusiness,
			|	T.Department,
			|	T.ExpenseItemAssets,
			|	T.DimensionOfExpenses,
			|	T.DebitBusinessUnit,
			|	T.VATWriteOffItem,
			|	T.DimensionVATWriteOff,
			|	T.AccountingSection,
			|	T.FinancialAccountingDimension,
			|
			// Let's replace the conditional price taken in the textpartition of other expenses for the distribution of the Control order(), with the calculated one.
			|	CAST(CostNodes.CostInclVAT * CASE WHEN T.CostInclVAT = 0 THEN 0 ELSE 1 END AS NUMBER (31,10)) AS CostInclVAT,
			|	CAST(CostNodes.CostExcludingVAT * CASE WHEN T.CostExcludingVAT = 0 THEN 0 ELSE 1 END AS NUMBER (31,10)) AS CostExcludingVAT,
			|	CAST(CostNodes.CostExcludingVATLocal * CASE WHEN T.CostExcludingVATLocal = 0 THEN 0 ELSE 1 END AS NUMBER (31,10)) AS CostExcludingVATLocal,
			|	CAST(CostNodes.VATLocal * CASE WHEN T.VATLocal = 0 THEN 0 ELSE 1 END AS NUMBER (31,10)) AS VATLocal,
			|	CAST(CostNodes.CostExcludingVATMan * CASE WHEN T.CostExcludingVATMan = 0 THEN 0 ELSE 1 END AS NUMBER (31,10)) AS CostExcludingVATMan,
			|	CAST(CostNodes.VATManag * CASE WHEN T.VATManag = 0 THEN 0 ELSE 1 END AS NUMBER (31,10)) AS VATManag
			|FROM
			|	TTWriteOffOfItemByItemCosts AS T
			|	INNER JOIN TTAmountsInUnfinishedProductionNodes AS CostNodes
			|		ON T.Organization = CostNodes.Organization
			|		 AND T.Lot = CostNodes.Lot
			|		 AND T.Department = CostNodes.Department
			|		 AND T.LineOfBusiness = CostNodes.LineOfBusiness
			|		 AND T.ExpenseItemAssets = CostNodes.ExpenseItem
			|		 AND T.DimensionOfExpenses = CostNodes.DimensionOfExpenses
			|		 AND T.ProductCostElement = CostNodes.ProductCostElement
			|		 AND T.ProductsGroup = CostNodes.ProductsGroup
			|		 AND T.RuleOfCostAllocatingToProductionLots = CostNodes.RuleOfCostAllocatingToProductionLots
			|WHERE
			|	NOT T.ThereIsPrice 
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP TTWriteOffOfItemByItemCosts
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	T.ThereIsPrice,
			|	T.EntryType,
			|	T.Period,
			|	T.Recorder,
			|	T.RecordType,
			|	T.Organization,
			|	T.ItemsLocationAttributes,
			|	T.InventoryOwnerAttribute,
			|	T.CorItemsLocationAttributes,
			|	T.CorInventoryOwnerAttribute,
			|	T.Lot,
			|	T.LotVendorAttributes,
			|	T.VATActivityType,
			|	T.DocumentInflow,
			|	T.DocumentReceiptsInCurPeriod,
			|	T.LotVendorAttributesOfReceiptDocument,
			|	T.LineOfBusiness,
			|	T.ProductCostElement,
			|	T.ProductsGroup,
			|	T.RuleOfCostAllocatingToProductionLots,
			|	T.BusinessOperation,
			|	T.CorVATActivityTypes,
			|	T.CorAccountingSection,
			|	T.CorLineOfBusiness,
			|	T.Department,
			|	T.ExpenseItemAssets,
			|	T.DimensionOfExpenses,
			|	T.DebitBusinessUnit,
			|	T.VATWriteOffItem,
			|	T.DimensionVATWriteOff,
			|	T.AccountingSection,
			|	T.FinancialAccountingDimension,
			|
			|	T.CostInclVAT,
			|	T.CostExcludingVAT,
			|	T.CostExcludingVATLocal,
			|	T.VATLocal,
			|	T.CostExcludingVATMan,
			|	T.VATManag
			|INTO TTWriteOffOfItemByItemCosts
			|FROM
			|	TTWriteOffOfItemByItemCostsAugmented AS T
			|
			|INDEX BY
			|	Recorder
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP TTWriteOffOfItemByItemCostsAugmented
			|";
		
			CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
			
		EndIf;
		
	EndIf;

	#EndRegion
	
	MatchingTemporaryMovementTables = New Map;
	
	#Region PreservationOfRegisteredRecords_DetailingCostOfBatchOfGoods
	
	RegisterName = Metadata.InformationRegisters.ItemizeGoodsLotCost.Name;
	
	ReceiverDescription = CalculationParameters.RegisterRecords[RegisterName];
	
	TempTableName = "TTDetailingCostOfBatchOfGoods";
	
	CopiedFields = CostCalculationAppliedAlgorithms.GetColumnNamesAsString(
		CostCalculationAppliedAlgorithms.UnloadTemporaryTable(CalculationParameters, "TTNodePricesAreConstant", 0));
	
	CopiedFields = StringFunctionsClientServer.SubstituteParametersToString(CopiedFields, "");
	
	FieldDescriptionTable = CostCalculationAppliedAlgorithms.GenerateDescriptionOfRequestFields(ReceiverDescription.Table);
	CostCalculationAppliedAlgorithms.CopyRequestFields(FieldDescriptionTable, CopiedFields);
	
	CostCalculationAppliedAlgorithms.MakeRequestForFieldDescriptions(
		CalculationParameters,
		FieldDescriptionTable,
		RegisterName,
		"TTNodePricesAreConstant",
		TempTableName);
	
	MatchingTemporaryMovementTables.Insert(TempTableName, RegisterName);
	
	#EndRegion
	
	#Region PreservationOfRegisteredRecords_DetailingCostOfBatchOfGoodsItemByItemCosts
	
	RegisterName = Metadata.InformationRegisters.ItemizeLotCostItemizedAndOtherCosts.Name;
	
	ReceiverDescription = CalculationParameters.RegisterRecords[RegisterName];
	
	TempTableName = "TTDetailingCostOfBatchOfGoodsItemByItemCosts";
	
	CopiedFields = CostCalculationAppliedAlgorithms.GetColumnNamesAsString(
		CostCalculationAppliedAlgorithms.UnloadTemporaryTable(CalculationParameters, "TTNodePricesArticleByArticleConstant", 0));
	
	CopiedFields = StringFunctionsClientServer.SubstituteParametersToString(CopiedFields, "");
	
	FieldDescriptionTable = CostCalculationAppliedAlgorithms.GenerateDescriptionOfRequestFields(ReceiverDescription.Table);
	CostCalculationAppliedAlgorithms.CopyRequestFields(FieldDescriptionTable, CopiedFields);
	
	CostCalculationAppliedAlgorithms.MakeRequestForFieldDescriptions(
		CalculationParameters,
		FieldDescriptionTable,
		RegisterName,
		"TTNodePricesArticleByArticleConstant",
		TempTableName);
	
	MatchingTemporaryMovementTables.Insert(TempTableName, RegisterName);
	
	#EndRegion
	
	#Region PreservationOfRegisteredRecords_DetailingCostOfGoodsItemByItemCosts
	
	RegisterName = Metadata.InformationRegisters.ItemizeGoodsCostItemizedAndOtherCosts.Name;
	
	ReceiverDescription = CalculationParameters.RegisterRecords[RegisterName];
	
	TempTableName = "TTDetailingCostOfGoodsItemByItemCosts";
	
	CopiedFields = CostCalculationAppliedAlgorithms.GetColumnNamesAsString(
		CostCalculationAppliedAlgorithms.UnloadTemporaryTable(CalculationParameters, "TTNodePricesInDetail", 0));
	
	CopiedFields = StringFunctionsClientServer.SubstituteParametersToString(CopiedFields, "");
	
	FieldDescriptionTable = CostCalculationAppliedAlgorithms.GenerateDescriptionOfRequestFields(ReceiverDescription.Table);
	CostCalculationAppliedAlgorithms.CopyRequestFields(FieldDescriptionTable, CopiedFields);
	
	ConditionWHERE = "(TheseAreRemainingArticleByArticleVariables
		|	OR TheseAreVariableAdditionalCosts
		|	OR (Organization, ExpenseItem, DimensionOfExpenses) IN (
		|	SELECT
		|		Organization, ExpenseItem, DimensionOfExpenses
		|	FROM TTSelectionOfCostAnalysisAndVATVariables AS Filter))
		|	AND Initial_Cost
		|	AND NOT TheseRemaindersAreArticleByArticleConstants
		|";
	
	If CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters, "TTAdjustmentOfPricesOfBalancesOfUnfinishedProduction") Then
		
		ConditionWHERE = ConditionWHERE + "
			|   AND NOT ((Organization, AccountingSection, ItemsLocationAttributes, InventoryOwnerAttribute,
			|		   Lot, LotVendorAttributes, VATActivityType, FinancialAccountingDimension,
			|		   DocumentInflow, LotVendorAttributesOfReceiptDocument, ExpenseItem, DimensionOfExpenses) IN
			|			(SELECT 
			| 			    Organization, AccountingSection, ItemsLocationAttributes, InventoryOwnerAttribute,
			|				Lot, LotVendorAttributes, VATActivityType, FinancialAccountingDimension,
			|		  		DocumentInflow, LotVendorAttributesOfReceiptDocument, ExpenseItem, DimensionOfExpenses
			|			 FROM TTAdjustmentOfPricesOfBalancesOfUnfinishedProduction))
			|";
		
	EndIf;
	
	CostCalculationAppliedAlgorithms.MakeRequestForFieldDescriptions(
		CalculationParameters,
		FieldDescriptionTable,
		RegisterName,
		"TTNodePricesInDetail",
		TempTableName,
		ConditionWHERE);
	
	MatchingTemporaryMovementTables.Insert(TempTableName, RegisterName);

	#EndRegion
	
	CostCalculationAppliedAlgorithms.CacheGeneratedRegisteredRecordsFromTemporaryTables(CalculationParameters, MatchingTemporaryMovementTables, True);
	
	AddDetailsOfVATShipments(CalculationParameters, NameOfDataTableSource);
	
	// We will destroy unnecessary temporary tables.
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(
		CalculationParameters,
		ExistingTT);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
EndProcedure

Procedure AddDetailsOfVATShipments(CalculationParameters, NameOfDataTableSource)
	
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	RegisterName = Metadata.InformationRegisters.ItemizeGoodsCostItemizedAndOtherCosts.Name;
	ReceiverDescription = CalculationParameters.RegisterRecords[RegisterName];
	
	MatchingTemporaryMovementTables = New Map;
	
	If NameOfDataTableSource = "ArrivalsOfGoodsNDS2_4_ForSolvingCase" Then
		#Region AdjustmentOfAmountsWhenAdjustingBalancesOfUnfinishedProduction
		
		// Adjustment of amounts in WIP balances
		TempTableName = "TUEDetailingCostOfGoodsItemByItemCostsAdjustmentOfWIP";
		
		CopiedFields = CostCalculationAppliedAlgorithms.GetColumnNamesAsString(
			CostCalculationAppliedAlgorithms.UnloadTemporaryTable(CalculationParameters, "TTAdjustmentOfPricesOfBalancesOfUnfinishedProduction", 0));
		
		CopiedFields = StringFunctionsClientServer.SubstituteParametersToString(CopiedFields, "");
		
		FieldDescriptionTable = CostCalculationAppliedAlgorithms.GenerateDescriptionOfRequestFields(ReceiverDescription.Table);
		CostCalculationAppliedAlgorithms.CopyRequestFields(FieldDescriptionTable, CopiedFields);
		
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostInclVAT", 		"CostInclVAT");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVAT", 		"CostExcludingVAT");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVATLocal", 	"CostExcludingVATLocal");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVATMan", 	"CostExcludingVATMan");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "VATLocal", 				"VATLocal");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "VATManag", 				"VATManag");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "LotQuantity", 		"Count");

		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "Period", 				"&BeginOfPeriod");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "EntryType",				"VALUE(Enum.LotRecordTypes.EmptyRef)");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "DocumentInflow",
			"CASE WHEN VALUETYPE(DocumentInflow) IN (&TypesOfBatchDocuments)
			|		THEN DocumentInflow
			|		ELSE UNDEFINED
			|END");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "LotVendorAttributesOfReceiptDocument",
			"CASE WHEN VALUETYPE(DocumentInflow) IN (&TypesOfBatchDocuments)
			|		THEN LotVendorAttributesOfReceiptDocument
			|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
			|END");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "ExpenseItem",
			"CASE WHEN VALUETYPE(ExpenseItem) <> TYPE(ChartOfCharacteristicTypes.ExpenseItems)
			|		THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|		ELSE ExpenseItem
			|END");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "DimensionOfExpenses",
			"CASE WHEN VALUETYPE(ExpenseItem) <> TYPE(ChartOfCharacteristicTypes.ExpenseItems)
			|		THEN UNDEFINED
			|		ELSE DimensionOfExpenses
			|END");
		
		CostCalculationAppliedAlgorithms.MakeRequestForFieldDescriptions(
			CalculationParameters,
			FieldDescriptionTable,
			RegisterName,
			"TTAdjustmentOfPricesOfBalancesOfUnfinishedProduction",
			TempTableName);
		
		MatchingTemporaryMovementTables.Insert(TempTableName, RegisterName);
		
		#EndRegion
		#Region AdjustmentOfAmountsWhenAdjustingPurchase
		
		// Adjusting the amounts for purchase adjustments by the amount of the balance
		TempTableName = "TTDetailingCostOfGoodsItemByItemExpensesPurchaseAdjustments";
		
		CopiedFields = CostCalculationAppliedAlgorithms.GetColumnNamesAsString(
			CostCalculationAppliedAlgorithms.UnloadTemporaryTable(CalculationParameters, "GoodsReceiptsVAT2_4", 0));
		
		CopiedFields = StringFunctionsClientServer.SubstituteParametersToString(CopiedFields, "");
		
		FieldDescriptionTable = CostCalculationAppliedAlgorithms.GenerateDescriptionOfRequestFields(ReceiverDescription.Table);
		CostCalculationAppliedAlgorithms.CopyRequestFields(FieldDescriptionTable, CopiedFields);
		
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostInclVAT", 		"CostInclVAT");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVAT", 		"CostExcludingVAT");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVATLocal", 	"CostExcludingVATLocal");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVATMan", 	"CostExcludingVATMan");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "VATLocal", 				"VATLocal");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "VATManag", 				"VATManag");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "LotQuantity",
			"CASE WHEN Count < 0 THEN -Count ELSE Count END");

		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "Period", 				"&BeginOfPeriod");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "EntryType",				"VALUE(Enum.LotRecordTypes.EmptyRef)");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "DocumentInflow",
			"CASE WHEN VALUETYPE(DocumentInflow) IN (&TypesOfBatchDocuments)
			|		THEN DocumentInflow
			|		ELSE UNDEFINED
			|END");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "LotVendorAttributesOfReceiptDocument",
			"CASE WHEN VALUETYPE(DocumentInflow) IN (&TypesOfBatchDocuments)
			|		THEN LotVendorAttributesOfReceiptDocument
			|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
			|END");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "ExpenseItem",
			"CASE WHEN VALUETYPE(ExpenseItemAssets) <> TYPE(ChartOfCharacteristicTypes.ExpenseItems)
			|		THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|		ELSE ExpenseItemAssets
			|END");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "DimensionOfExpenses",
			"CASE WHEN VALUETYPE(ExpenseItemAssets) <> TYPE(ChartOfCharacteristicTypes.ExpenseItems)
			|		THEN UNDEFINED
			|		ELSE AssetExpenseAnalytics
			|END");
		
		ConditionWHERE = "EntryType = VALUE(Enum.LotRecordTypes.Balance)";
		
		CostCalculationAppliedAlgorithms.MakeRequestForFieldDescriptions(
			CalculationParameters,
			FieldDescriptionTable,
			RegisterName,
			"GoodsReceiptsVAT2_4",
			TempTableName,
			ConditionWHERE);
		
		MatchingTemporaryMovementTables.Insert(TempTableName, RegisterName);
		
		#EndRegion
		
		#Region CostDeviationsInCaseOfFullRetirement
		
		// Deviations of value in case of complete disposal of goods in previous periods
		TempTableName = "TTDetailingCostOfGoodsItemByItemExpensesDeviationsOnRetirementsInPreviousPeriods";
		
		CopiedFields = CostCalculationAppliedAlgorithms.GetColumnNamesAsString(
			CostCalculationAppliedAlgorithms.UnloadTemporaryTable(CalculationParameters, "GoodsReceiptsVAT2_4", 0));
		
		CopiedFields = StringFunctionsClientServer.SubstituteParametersToString(CopiedFields, "");
		
		FieldDescriptionTable = CostCalculationAppliedAlgorithms.GenerateDescriptionOfRequestFields(ReceiverDescription.Table);
		CostCalculationAppliedAlgorithms.CopyRequestFields(FieldDescriptionTable, CopiedFields);
		
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostInclVAT",
			"CAST(CostInclVAT / Count AS NUMBER (28,10))");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVAT",
			"CAST(CostExcludingVAT / Count AS NUMBER (28,10))");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVATLocal",
			"CAST(CostExcludingVATLocal / Count AS NUMBER (28,10))");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVATMan",
			"CAST(CostExcludingVATMan / Count AS NUMBER (28,10))");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "VATLocal",
			"CAST(VATLocal / Count AS NUMBER (28,10))");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "VATManag",
			"CAST(VATManag / Count AS NUMBER (28,10))");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "LotQuantity",		"Count");

		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "Period", 				"&BeginOfPeriod");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "EntryType",				"VALUE(Enum.LotRecordTypes.EmptyRef)");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "DocumentInflow",
			"CASE WHEN VALUETYPE(DocumentInflow) IN (&TypesOfBatchDocuments)
			|		THEN DocumentInflow
			|		ELSE UNDEFINED
			|END");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "LotVendorAttributesOfReceiptDocument",
			"CASE WHEN VALUETYPE(DocumentInflow) IN (&TypesOfBatchDocuments)
			|		THEN LotVendorAttributesOfReceiptDocument
			|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
			|END");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "ExpenseItem",
			"CASE WHEN VALUETYPE(ExpenseItemAssets) <> TYPE(ChartOfCharacteristicTypes.ExpenseItems)
			|		THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|		ELSE ExpenseItemAssets
			|END");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "DimensionOfExpenses",
			"CASE WHEN VALUETYPE(ExpenseItemAssets) <> TYPE(ChartOfCharacteristicTypes.ExpenseItems)
			|		THEN UNDEFINED
			|		ELSE AssetExpenseAnalytics
			|END");
		
		ConditionWHERE = "EntryType = VALUE(Enum.LotRecordTypes.GroupedStock) AND Count <> 0";
		
		CostCalculationAppliedAlgorithms.MakeRequestForFieldDescriptions(
			CalculationParameters,
			FieldDescriptionTable,
			RegisterName,
			"GoodsReceiptsVAT2_4",
			TempTableName,
			ConditionWHERE);
		
		MatchingTemporaryMovementTables.Insert(TempTableName, RegisterName);
		
		#EndRegion
		
		#Region AdjustmentOfLocalAndManAccountingAmounts
		
		If CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters, "TTNodePricesInDetail") Then
		
			TempTableName = "TTDetailingOfInventoryCostsItemByItemExpensesAdjustmentOfLocalManAmounts";
		
			CopiedFields = CostCalculationAppliedAlgorithms.GetColumnNamesAsString(
				CostCalculationAppliedAlgorithms.UnloadTemporaryTable(CalculationParameters, "TTNodePricesInDetail", 0));
			
			CopiedFields = StringFunctionsClientServer.SubstituteParametersToString(CopiedFields, "");
			
			FieldDescriptionTable = CostCalculationAppliedAlgorithms.GenerateDescriptionOfRequestFields(ReceiverDescription.Table);
			CostCalculationAppliedAlgorithms.CopyRequestFields(FieldDescriptionTable, CopiedFields);
			
			CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostInclVAT", 		"0");
			CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVAT", 		"0");
			CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVATLocal", 	"-CostExcludingVATLocal");
			CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVATMan", 	"-CostExcludingVATMan");
			CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "VATLocal", 				"0");
			CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "VATManag", 				"0");
			
			ConditionWHERE = "NOT TransferOfNettedInitialCostLocal AND (CostExcludingVATLocal <> 0 OR CostExcludingVATMan <> 0)";
			
			CostCalculationAppliedAlgorithms.MakeRequestForFieldDescriptions(
				CalculationParameters,
				FieldDescriptionTable,
				RegisterName,
				"TTNodePricesInDetail",
				TempTableName,
				ConditionWHERE);
			
			MatchingTemporaryMovementTables.Insert(TempTableName, RegisterName);
		
		EndIf;
		
		#EndRegion
		
	ElsIf NameOfDataTableSource = "ReceiptsOfAdditionalExpensesVAT2_4_ToSolveLinearSystems" Then
		
		#Region AdditionalExpensesAmountInCaseOfFullRetirement
		
		// Additional expenses in case of full disposal of goods in previous periods
		TempTableName = "TTDetailingCostOfGoodsItemByItemExpensesAdditionalExpensesAmountForRetirementsInPreviousPeriods";
		
		CopiedFields = CostCalculationAppliedAlgorithms.GetColumnNamesAsString(
			CostCalculationAppliedAlgorithms.UnloadTemporaryTable(CalculationParameters, "TTAdditionalExpensesVAT2_4", 0));
		
		CopiedFields = StringFunctionsClientServer.SubstituteParametersToString(CopiedFields, "");
		
		FieldDescriptionTable = CostCalculationAppliedAlgorithms.GenerateDescriptionOfRequestFields(ReceiverDescription.Table);
		CostCalculationAppliedAlgorithms.CopyRequestFields(FieldDescriptionTable, CopiedFields);
		
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostInclVAT", 		"RetirementCostWithVAT");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVAT", 		"RetirementCostExclVAT");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVATLocal", 	"RetirementCostExclVATLocal");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CostExcludingVATMan", 	"RetirementCostExclVATMan");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "VATLocal", 				"RetirementOfVATLocal");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "VATManag", 				"RetirementOfVATMan");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "LotQuantity",		"Count");
		
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "Period", 				"&BeginOfPeriod");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "EntryType",				"VALUE(Enum.LotRecordTypes.EmptyRef)");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "DocumentInflow",
			"CASE WHEN VALUETYPE(DocumentInflow) IN (&TypesOfBatchDocuments)
			|		THEN DocumentInflow
			|		ELSE UNDEFINED
			|END");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "LotVendorAttributesOfReceiptDocument",
			"CASE WHEN VALUETYPE(DocumentInflow) IN (&TypesOfBatchDocuments)
			|		THEN LotVendorAttributesOfReceiptDocument
			|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
			|END");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "ExpenseItem",
			"CASE WHEN VALUETYPE(ExpenseItem) <> TYPE(ChartOfCharacteristicTypes.ExpenseItems)
			|		THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|		ELSE ExpenseItem
			|END");
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "DimensionOfExpenses",
			"CASE WHEN VALUETYPE(ExpenseItem) <> TYPE(ChartOfCharacteristicTypes.ExpenseItems)
			|		THEN UNDEFINED
			|		ELSE DimensionOfExpenses
			|END");
		
		ConditionWHERE = "FullDisposal";
		
		CostCalculationAppliedAlgorithms.MakeRequestForFieldDescriptions(
			CalculationParameters,
			FieldDescriptionTable,
			RegisterName,
			"TTAdditionalExpensesVAT2_4",
			TempTableName,
			ConditionWHERE);
		
		MatchingTemporaryMovementTables.Insert(TempTableName, RegisterName);

		#EndRegion
		
	EndIf;
	
	CostCalculationAppliedAlgorithms.CacheGeneratedRegisteredRecordsFromTemporaryTables(CalculationParameters, MatchingTemporaryMovementTables, True);
	
	// We will destroy unnecessary temporary tables.
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(
		CalculationParameters,
		ExistingTT);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
EndProcedure

Procedure GenerateValueOfVATLotsAtEndOfPeriod(CalculationParameters, CallNumber)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "GenerateValueOfVATLotsAtEndOfPeriod");
	
	NameOfResultTable = "TTTurnoverValueOfBatchesVAT"; 
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NameOfResultTable);
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		NameOfResultTable);
		
	AddlParameters = CalculationParameters.AdditionalStageRequestParameters;
	AddlParameters.Insert("CallNumber", CallNumber);
	
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextTTTurnoverCostOfBatchesVAT(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
EndProcedure

Function QueryTextTTTurnoverCostOfBatchesVAT(CalculationParameters)
	
	QueryText =
	"SELECT
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.Products AS Products,
	|	T.Characteristic,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.AccountingSection AS AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.ProductionCostType,
	|
	|	MAX(T.CostInclVAT) AS CostInclVAT,
	|	MAX(T.CostExcludingVAT) AS CostExcludingVAT,
	|	MAX(T.CostExcludingVATLocal) AS CostExcludingVATLocal,
	|	MAX(T.VATLocal) AS VATLocal,
	|	MAX(T.CostExcludingVATMan) AS CostExcludingVATMan,
	|	MAX(T.VATManag) AS VATManag
	|INTO TTBalancesOfVariableCosts
	|FROM
	|(SELECT
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.AccountingSection AS AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	CASE WHEN NOT ArticlesOnProduction.Ref IS NULL
	|		THEN T.ExpenseItem.ProductionCostType
	|		ELSE UNDEFINED
	|	END AS ProductionCostType,
	|
	|	T.CostInclVAT,
	|	T.CostExcludingVAT,
	|	T.CostExcludingVATLocal,
	|	T.VATLocal,
	|	T.CostExcludingVATMan,
	|	T.VATManag
	|FROM
	|	InformationRegister.ItemizeGoodsCostItemizedAndOtherCosts AS T
	|	INNER JOIN PeriodOfPreviousCalculatedPeriod AS RegisterRecordsPeriod
	|		ON T.Period = RegisterRecordsPeriod.Period
	|	LEFT JOIN TTProductionCostItems AS ArticlesOnProduction
	|		ON ArticlesOnProduction.Ref = T.ExpenseItem
	|WHERE
	|	T.Organization IN(&OrganizationsIncludingVATLotsVersion24)
	|	AND NOT T.EntryType IN (&TypesOfDataConversionRecords)
	|	AND (&CallNumber = 1 OR T.VATLocal <> 0 OR T.VATManag <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.AccountingSection AS AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	CASE WHEN NOT ArticlesOnProduction.Ref IS NULL
	|		THEN T.ExpenseItem.ProductionCostType
	|		ELSE UNDEFINED
	|	END AS ProductionCostType,
	|
	|	T.CostInclVAT,
	|	T.CostExcludingVAT,
	|	T.CostExcludingVATLocal,
	|	T.VATLocal,
	|	T.CostExcludingVATMan,
	|	T.VATManag
	|FROM
	|	TTCashDetailingCostOfGoodsItemByItemCosts AS T
	|	LEFT JOIN TTProductionCostItems AS ArticlesOnProduction
	|		ON ArticlesOnProduction.Ref = T.ExpenseItem
	|WHERE
	|	T.Organization IN(&OrganizationsIncludingVATLotsVersion24)
	|	AND NOT T.EntryType IN (&TypesOfDataConversionRecords)
	|	AND (&CallNumber = 1 OR T.VATLocal <> 0 OR T.VATManag <> 0)
	|) AS T
	|GROUP BY
	|	T.Organization,
	|	T.ItemsLocationAttributes,
	|	T.Products,
	|	T.Characteristic,
	|	T.InventoryOwnerAttribute,
	|	T.AccountingSection,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.FinancialAccountingDimension,
	|	T.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.ProductionCostType
	|
	|INDEX BY
	|	Lot,
	|	LotVendorAttributes,
	|	Products,
	|	Characteristic,
	|	InventoryOwnerAttribute,
	|	Organization,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Ref AS Ref,
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	T.ItemsLocationAttributes.Series AS Series
	|INTO TUETransfersWithoutVAT
	|FROM
	|	Document.CustomerInvoiceIntercompany.InventoryKinds AS T
	|	INNER JOIN Document.CustomerInvoiceIntercompany AS Transfers_
	|		ON T.Ref = Transfers_.Ref
	|WHERE
	|	Transfers_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Transfers_.Organization IN (&CompanyArray)
	|	AND Transfers_.Posted
	|	AND T.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Period,
	|	T.OfficialTypeOfMovementParish,
	|	T.Recorder,
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.AccountingSection AS AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.AssetAndLiabilityItem,
	|	T.AssetsLiabilitiesDimension,
	|	(CASE
	|		WHEN T.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		 AND T.ExpenseItemOfWriteOff <> UNDEFINED
	|			THEN T.ExpenseItemOfWriteOff
	|		WHEN T.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN T.AssetAndLiabilityItem
	|		ELSE UNDEFINED END) AS ExpenseItemAssets,
	|	(CASE
	|		WHEN T.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		 AND T.ExpenseItemOfWriteOff <> UNDEFINED
	|			THEN T.DimensionOfExpenses
	|		WHEN T.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN T.AssetsLiabilitiesDimension
	|		ELSE UNDEFINED END) AS AssetExpenseAnalytics,
	|
	|	CASE
	|		WHEN NOT TransferTypesOfStocks.Ref IS NULL AND NOT T.OfficialTypeOfMovementParish
	|		 AND Transfer_.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN NOT Transfer_.Ref IS NULL AND NOT T.OfficialTypeOfMovementParish
	|			THEN Transfer_.VATTaxation
	|		WHEN NOT Return.Ref IS NULL AND T.OfficialTypeOfMovementParish
	|			THEN Return.VATTaxation
	|		ELSE T.CorVATActivityTypes
	|	END AS CorVATActivityTypes,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.Department,
	|	T.EntryType,
	|	T.ReversingEntry,
	|	T.FinRecordID,
	|
	|	ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	(CASE
	|		WHEN T.CorLineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			THEN T.CorLineOfBusiness
	|		ELSE
	|			ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) 
	|		END) AS CorLineOfBusiness,
	|	T.ProductsGroup AS CorGroupOfManufacturedProducts,
	|	T.BusinessOperation AS BusinessOperation,
	|	T.Count
	|INTO TTCostPriceForValueOfBatchesVATPreliminary
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS T
	|	LEFT JOIN Document.CustomerInvoiceIntercompany AS Transfer_
	|		ON Transfer_.Ref = T.Recorder
	|	LEFT JOIN TUETransfersWithoutVAT AS TransferTypesOfStocks
	|		ON TransferTypesOfStocks.Ref = T.Recorder
	|			AND TransferTypesOfStocks.Products = T.ItemsLocationAttributes.Products
	|			AND TransferTypesOfStocks.Characteristic = T.ItemsLocationAttributes.CHARACTERISTIC
	|			AND TransferTypesOfStocks.Series = T.ItemsLocationAttributes.Series
	|	LEFT JOIN Document.IntercompanyGoodsReturn AS Return
	|		ON Return.Ref = T.Recorder
	|WHERE
	|	T.Organization IN(&OrganizationsIncludingVATLotsVersion24)
	|	AND (T.EntryType <> VALUE(Enum.LotRecordTypes.Supplement)
	|		OR T.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))
	|	AND T.Count <> 0
	|
	|INDEX BY
	|	ExpenseItemOfWriteOff
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Recorder AS Recorder
	|INTO TTRevenueRegistrars
	|FROM
	|	TTCashEstimatedTurnoverRevenueAndCostOfSales AS T
	|WHERE
	|	&CallNumber = 3
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Period,
	|	T.OfficialTypeOfMovementParish,
	|	T.Recorder,
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension,
	|	T.VATActivityType,
	|
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.AssetAndLiabilityItem,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseItemAssets,
	|	T.AssetExpenseAnalytics,
	|
	|	T.CorVATActivityTypes,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.Department,
	|	T.EntryType,
	|	T.ReversingEntry,
	|	T.FinRecordID,
	|	T.LineOfBusiness,
	|	T.CorLineOfBusiness,
	|	T.CorGroupOfManufacturedProducts,
	|	T.BusinessOperation,
	|	T.VATCanBeDebited,
	|	T.Count
	|INTO TTCostPriceForValueOfBatchesVAT
	|FROM
	|(SELECT
	|	T.Period,
	|	T.OfficialTypeOfMovementParish,
	|	T.Recorder,
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes,
	|	T.Products,
	|	T.Characteristic,
	|	T.InventoryOwnerAttribute,
	|	T.AccountingSection,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.FinancialAccountingDimension,
	|	T.VATActivityType,
	|
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.AssetAndLiabilityItem,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseItemAssets,
	|	T.AssetExpenseAnalytics,
	|
	|	T.CorVATActivityTypes,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.Department,
	|	T.EntryType,
	|	T.ReversingEntry,
	|	T.FinRecordID,
	|	T.LineOfBusiness,
	|	T.CorLineOfBusiness,
	|	T.CorGroupOfManufacturedProducts,
	|	T.BusinessOperation,
	|
	|	CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|	  AND T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS VATCanBeDebited,
	// Filling in the field This data to include exclusionyand must meet the conditions in Include Exclude Value 24(), include Exclude Value Sales24() 
	|	CASE WHEN
	|	  (&CallNumber <> 3
	|		OR NOT RevenueRecorders.Recorder IS NULL)
	|		OR T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|	  		AND T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|		OR T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|	  		AND T.CorVATActivityTypes IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|	  AND (T.VATActivityType <> T.CorVATActivityTypes
	|		)
	|	  AND T.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	  AND T.CorVATActivityTypes <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	  AND (NOT T.OfficialTypeOfMovementParish
	|		OR T.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn))
	|	  AND NOT (T.ReversingEntry
	|			AND T.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections))
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsDataToEnableVATExclusion,
	// Filling in the This Data for Expenses field must match the conditions in the textdisspend for distributionsextended()
	|	CASE WHEN &CallNumber = 1
	|	  AND NOT Cost_Items.Ref IS NULL
	|	  AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost)
	|	  AND NOT T.OfficialTypeOfMovementParish
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsDataForAdditionalExpenses,
	|
	|	T.Count
	|FROM
	|	TTCostPriceForValueOfBatchesVATPreliminary AS T
	|	LEFT JOIN TTRevenueRegistrars AS RevenueRecorders
	|		ON RevenueRecorders.Recorder = T.Recorder
	|	LEFT JOIN TTCostItems AS Cost_Items
	|		ON &CallNumber = 1
	|		AND Cost_Items.Ref = T.ExpenseItemOfWriteOff
	|	) AS T
	|WHERE
	|	T.ThisIsDataToEnableVATExclusion
	|	OR T.ThisIsDataForAdditionalExpenses
	|
	|INDEX BY
	|	Lot,
	|	LotVendorAttributes,
	|	Products,
	|	Characteristic,
	|	InventoryOwnerAttribute,
	|	Organization,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic
	|INTO TTFilterOfBatchForPrices
	|FROM
	|	TTCostPriceForValueOfBatchesVAT AS T
	|INDEX BY
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.Products,
	|	T.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Lot,
	|	T.Organization,
	|	T.Products,
	|	T.Characteristic,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	FALSE AS ItemByItemCosts,
	|	UNDEFINED AS ProductionCostType,
	|	CAST(T.CostInclVAT AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(T.CostExcludingVAT AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(T.CostExcludingVATLocal AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(T.VATLocal AS NUMBER(31,10)) AS VATLocal,
	|	CAST(T.CostExcludingVATMan AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(T.VATManag AS NUMBER(31,10)) AS VATManag
	|INTO TTPricesOfVATBatchesCurrent
	|FROM
	|	TTDetailingCostOfBatchOfGoods_ AS T
	|WHERE
	|	NOT T.EntryType IN (&TypesOfDataConversionRecords)
	|
	|UNION ALL
	|
	|SELECT
	|	T.Lot,
	|	T.Organization,
	|	T.Products,
	|	T.Characteristic,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	FALSE AS ItemByItemCosts,
	|	UNDEFINED AS ProductionCostType,
	|	CAST(T.CostInclVAT AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(T.CostExcludingVAT AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(T.CostExcludingVATLocal AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(T.VATLocal AS NUMBER(31,10)) AS VATLocal,
	|	CAST(T.CostExcludingVATMan AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(T.VATManag AS NUMBER(31,10)) AS VATManag
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS T
	|	INNER JOIN TTFilterOfBatchForPrices AS Filter
	|		ON T.Lot = Filter.Lot
	|		AND T.LotVendorAttributes = Filter.LotVendorAttributes
	|		AND T.Organization = Filter.Organization
	|		AND T.InventoryOwnerAttribute = Filter.InventoryOwnerAttribute
	|		AND T.Products = Filter.Products
	|		AND T.Characteristic = Filter.Characteristic
	|		AND T.RegistrationPeriod < &BeginOfPeriod
	|
	|UNION ALL
	|
	|SELECT
	|	T.Lot,
	|	T.Organization,
	|	T.Products,
	|	T.Characteristic,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	CASE WHEN T.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) THEN FALSE ELSE TRUE END AS ItemByItemCosts,
	|	CASE WHEN NOT ArticlesOnProduction.Ref IS NULL
	|		THEN T.ExpenseItem.ProductionCostType
	|		ELSE UNDEFINED
	|	END AS ProductionCostType,
	|	CAST(T.CostInclVAT AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(T.CostExcludingVAT AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(T.CostExcludingVATLocal AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(T.VATLocal AS NUMBER(31,10)) AS VATLocal,
	|	CAST(T.CostExcludingVATMan AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(T.VATManag AS NUMBER(31,10)) AS VATManag
	|FROM
	|	TTCashDetailingCostOfBatchOfGoodsItemByItemCosts AS T
	|	LEFT JOIN TTProductionCostItems AS ArticlesOnProduction
	|		ON ArticlesOnProduction.Ref = T.ExpenseItem
	|WHERE
	|	NOT T.EntryType IN (&TypesOfDataConversionRecords)
	|
	|UNION ALL
	|
	|SELECT
	|	T.Lot,
	|	T.Organization,
	|	T.Products,
	|	T.Characteristic,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.WIPInventoryLocationAttributes,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	CASE WHEN T.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) THEN FALSE ELSE TRUE END AS ItemByItemCosts,
	|	CASE WHEN NOT ArticlesOnProduction.Ref IS NULL
	|		THEN T.ExpenseItem.ProductionCostType
	|		ELSE UNDEFINED
	|	END AS ProductionCostType,
	|	CAST(T.CostInclVAT AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(T.CostExcludingVAT AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(T.CostExcludingVATLocal AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(T.VATLocal AS NUMBER(31,10)) AS VATLocal,
	|	CAST(T.CostExcludingVATMan AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(T.VATManag AS NUMBER(31,10)) AS VATManag
	|FROM
	|	InformationRegister.ItemizeLotCostItemizedAndOtherCosts AS T
	|	INNER JOIN TTFilterOfBatchForPrices AS Filter
	|		ON T.Lot = Filter.Lot
	|		AND T.LotVendorAttributes = Filter.LotVendorAttributes
	|		AND T.Organization = Filter.Organization
	|		AND T.InventoryOwnerAttribute = Filter.InventoryOwnerAttribute
	|		AND T.Products = Filter.Products
	|		AND T.Characteristic = Filter.Characteristic
	|		AND T.RegistrationPeriod < &BeginOfPeriod
	|	LEFT JOIN TTProductionCostItems AS ArticlesOnProduction
	|		ON ArticlesOnProduction.Ref = T.ExpenseItem
	|
	|INDEX BY
	|	Lot,
	|	LotVendorAttributes,
	|	Products,
	|	Characteristic,
	|	InventoryOwnerAttribute,
	|	Organization,
	|	WIPInventoryLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Second, the party's promotional value for optimization is divided into separate samples with further integration.
	// On large databases, simultaneous sampling with pooling takes 2-3 times longer.
	|SELECT
	|	T.Period,
	|	T.OfficialTypeOfMovementParish,
	|	T.Recorder,
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.AccountingSection AS AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.AssetAndLiabilityItem,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseItemAssets,
	|	T.AssetExpenseAnalytics,
	|
	|	T.CorVATActivityTypes,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.Department,
	|	T.EntryType,
	|	T.ReversingEntry,
	|	T.FinRecordID,
	|	Prices.ItemByItemCosts,
	|	FALSE AS ItemByItemCostsOfUnfinishedProduction,
	|	Prices.ProductionCostType,
	|
	|	T.VATCanBeDebited,
	|
	|	T.LineOfBusiness,
	|	T.CorLineOfBusiness,
	|	T.CorGroupOfManufacturedProducts,
	|	T.BusinessOperation,
	|
	|	Prices.DocumentInflow AS DocumentInflow,
	|	Prices.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|
	|	CAST(CAST(Prices.CostInclVAT AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS CostInclVAT,
	|	CAST(CAST(Prices.CostExcludingVAT AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS CostExcludingVAT,
	|	CAST(CAST(Prices.CostExcludingVATLocal AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS CostExcludingVATLocal,
	|	CAST(CAST(Prices.VATLocal AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS VATLocal,
	|	CAST(CAST(Prices.CostExcludingVATMan AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS CostExcludingVATMan,
	|	CAST(CAST(Prices.VATManag AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS VATManag,
	|	T.Count
	|INTO TTTurnoverValueOfBatchesVATPreliminary1
	|FROM
	|	TTCostPriceForValueOfBatchesVAT AS T
	|		INNER JOIN TTPricesOfVATBatchesCurrent AS Prices
	|		ON (Prices.Lot = T.Lot)
	|			AND (Prices.LotVendorAttributes = T.LotVendorAttributes)
	|			AND (Prices.Products = T.Products)
	|			AND (Prices.Characteristic = T.Characteristic)
	|			AND (Prices.InventoryOwnerAttribute = T.InventoryOwnerAttribute)
	|			AND (Prices.Organization = T.Organization)
	|			AND (Prices.WIPInventoryLocationAttributes = T.ItemsLocationAttributes)
	|WHERE
	|	(&CallNumber = 1
	|		OR CAST(CAST(Prices.VATLocal AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER(31,2)) <> 0
	|		OR CAST(CAST(Prices.VATManag AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER(31,2)) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Period,
	|	T.OfficialTypeOfMovementParish,
	|	T.Recorder,
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.AccountingSection AS AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.AssetAndLiabilityItem,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseItemAssets,
	|	T.AssetExpenseAnalytics,
	|
	|	T.CorVATActivityTypes,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.Department,
	|	T.EntryType,
	|	T.ReversingEntry,
	|	T.FinRecordID,
	|	Prices.ItemByItemCosts,
	|	FALSE AS ItemByItemCostsOfUnfinishedProduction,
	|	Prices.ProductionCostType,
	|
	|	T.VATCanBeDebited,
	|
	|	T.LineOfBusiness,
	|	T.CorLineOfBusiness,
	|	T.CorGroupOfManufacturedProducts,
	|	T.BusinessOperation,
	|
	|	Prices.DocumentInflow AS DocumentInflow,
	|	Prices.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|
	|	CAST(CAST(Prices.CostInclVAT AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS CostInclVAT,
	|	CAST(CAST(Prices.CostExcludingVAT AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS CostExcludingVAT,
	|	CAST(CAST(Prices.CostExcludingVATLocal AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS CostExcludingVATLocal,
	|	CAST(CAST(Prices.VATLocal AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS VATLocal,
	|	CAST(CAST(Prices.CostExcludingVATMan AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS CostExcludingVATMan,
	|	CAST(CAST(Prices.VATManag AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS VATManag,
	|	T.Count
	|INTO TTTurnoverValueOfBatchesVATPreliminary2
	|FROM
	|	TTCostPriceForValueOfBatchesVAT AS T
	|		INNER JOIN TTPricesOfVATBatchesCurrent AS Prices
	|		ON (Prices.Lot = T.Lot)
	|			AND (Prices.LotVendorAttributes = T.LotVendorAttributes)
	|			AND (Prices.Products = T.Products)
	|			AND (Prices.Characteristic = T.Characteristic)
	|			AND (Prices.InventoryOwnerAttribute = T.InventoryOwnerAttribute)
	|			AND (Prices.Organization = T.Organization)
	|WHERE
	|	T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AND
	|	(&CallNumber = 1
	|		OR CAST(CAST(Prices.VATLocal AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER(31,2)) <> 0
	|		OR CAST(CAST(Prices.VATManag AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER(31,2)) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Period,
	|	T.OfficialTypeOfMovementParish,
	|	T.Recorder,
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.AccountingSection AS AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.AssetAndLiabilityItem,
	|	T.AssetsLiabilitiesDimension,
	|	(CASE
	|		WHEN T.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		 AND T.ExpenseItemOfWriteOff <> UNDEFINED
	|			THEN T.ExpenseItemOfWriteOff
	|		WHEN T.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN T.AssetAndLiabilityItem
	|		ELSE UNDEFINED END) AS ExpenseItemAssets,
	|	(CASE
	|		WHEN T.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		 AND T.ExpenseItemOfWriteOff <> UNDEFINED
	|			THEN T.DimensionOfExpenses
	|		WHEN T.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|			THEN T.AssetsLiabilitiesDimension
	|		ELSE UNDEFINED END) AS AssetExpenseAnalytics,
	|
	|	T.CorVATActivityTypes,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.Department,
	|	T.EntryType,
	|	T.ReversingEntry,
	|	T.FinRecordID,
	|	CASE WHEN Prices.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) THEN FALSE ELSE TRUE END AS ItemByItemCosts,
	|	FALSE AS ItemByItemCostsOfUnfinishedProduction,
	|	Prices.ProductionCostType,
	|
	|	CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|	  AND T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS VATCanBeDebited,
	|
	|	T.LineOfBusiness,
	|	T.CorLineOfBusiness,
	|	T.CorGroupOfManufacturedProducts,
	|	T.BusinessOperation,
	|
	|	Prices.DocumentInflow AS DocumentInflow,
	|	Prices.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|
	|	CAST(CAST(Prices.CostInclVAT AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS CostInclVAT,
	|	CAST(CAST(Prices.CostExcludingVAT AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS CostExcludingVAT,
	|	CAST(CAST(Prices.CostExcludingVATLocal AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS CostExcludingVATLocal,
	|	CAST(CAST(Prices.VATLocal AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS VATLocal,
	|	CAST(CAST(Prices.CostExcludingVATMan AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS CostExcludingVATMan,
	|	CAST(CAST(Prices.VATManag AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER (31,10)) AS VATManag,
	|	T.Count
	|INTO TTTurnoverValueOfBatchesVATPreliminary3
	|FROM
	|	TTCostPriceForValueOfBatchesVAT AS T
	|		INNER JOIN TTBalancesOfVariableCosts AS Prices
	|		ON (Prices.Lot = T.Lot)
	|			AND (Prices.LotVendorAttributes = T.LotVendorAttributes)
	|			AND (Prices.Products = T.Products)
	|			AND (Prices.Characteristic = T.Characteristic)
	|			AND (Prices.InventoryOwnerAttribute = T.InventoryOwnerAttribute)
	|			AND (Prices.Organization = T.Organization)
	|			AND (Prices.ItemsLocationAttributes = T.ItemsLocationAttributes)
	|			AND (Prices.AccountingSection = T.AccountingSection)
	|			AND (Prices.VATActivityType = T.VATActivityType)
	|			AND (Prices.FinancialAccountingDimension = T.FinancialAccountingDimension)
	|WHERE
	|	NOT T.EntryType IN (VALUE(Enum.LotRecordTypes.Supplement))
	|	AND (&CallNumber = 1
	|		OR CAST(CAST(Prices.VATLocal AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER(31,2)) <> 0
	|		OR CAST(CAST(Prices.VATManag AS NUMBER(31,10)) * CAST(T.Count AS NUMBER(15,3)) AS NUMBER(31,2)) <> 0)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Period,
	|	T.OfficialTypeOfMovementParish,
	|	T.Recorder,
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.AccountingSection AS AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.AssetAndLiabilityItem,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseItemAssets,
	|	T.AssetExpenseAnalytics,
	|
	|	T.CorVATActivityTypes,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.Department,
	|	T.EntryType,
	|	T.ReversingEntry,
	|	T.FinRecordID,
	|	T.ItemByItemCosts,
	|	T.ItemByItemCostsOfUnfinishedProduction AS ItemByItemCostsOfUnfinishedProduction,
	|	T.ProductionCostType,
	|
	|	T.VATCanBeDebited,
	|
	|	T.LineOfBusiness,
	|	T.CorLineOfBusiness,
	|	T.CorGroupOfManufacturedProducts,
	|	T.BusinessOperation,
	|
	|	T.DocumentInflow AS DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|
	|	T.CostInclVAT AS CostInclVAT,
	|	T.CostExcludingVAT AS CostExcludingVAT,
	|	T.CostExcludingVATLocal AS CostExcludingVATLocal,
	|	T.VATLocal AS VATLocal,
	|	T.CostExcludingVATMan AS CostExcludingVATMan,
	|	T.VATManag AS VATManag,
	|	T.Count
	|INTO TTTurnoverValueOfBatchesVATPreliminary
	|FROM
	|	TTTurnoverValueOfBatchesVATPreliminary1 AS T
	|
	|UNION ALL
	|
	|SELECT
	|	T.Period,
	|	T.OfficialTypeOfMovementParish,
	|	T.Recorder,
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.AccountingSection AS AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.AssetAndLiabilityItem,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseItemAssets,
	|	T.AssetExpenseAnalytics,
	|
	|	T.CorVATActivityTypes,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.Department,
	|	T.EntryType,
	|	T.ReversingEntry,
	|	T.FinRecordID,
	|	T.ItemByItemCosts,
	|	T.ItemByItemCostsOfUnfinishedProduction AS ItemByItemCostsOfUnfinishedProduction,
	|	T.ProductionCostType,
	|
	|	T.VATCanBeDebited,
	|
	|	T.LineOfBusiness,
	|	T.CorLineOfBusiness,
	|	T.CorGroupOfManufacturedProducts,
	|	T.BusinessOperation,
	|
	|	T.DocumentInflow AS DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|
	|	T.CostInclVAT AS CostInclVAT,
	|	T.CostExcludingVAT AS CostExcludingVAT,
	|	T.CostExcludingVATLocal AS CostExcludingVATLocal,
	|	T.VATLocal AS VATLocal,
	|	T.CostExcludingVATMan AS CostExcludingVATMan,
	|	T.VATManag AS VATManag,
	|	T.Count
	|FROM
	|	TTTurnoverValueOfBatchesVATPreliminary2 AS T
	|
	|UNION ALL
	|
	|SELECT
	|	T.Period,
	|	T.OfficialTypeOfMovementParish,
	|	T.Recorder,
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.AccountingSection AS AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.AssetAndLiabilityItem,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseItemAssets,
	|	T.AssetExpenseAnalytics,
	|
	|	T.CorVATActivityTypes,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.Department,
	|	T.EntryType,
	|	T.ReversingEntry,
	|	T.FinRecordID,
	|	T.ItemByItemCosts,
	|	T.ItemByItemCostsOfUnfinishedProduction AS ItemByItemCostsOfUnfinishedProduction,
	|	T.ProductionCostType,
	|
	|	T.VATCanBeDebited,
	|
	|	T.LineOfBusiness,
	|	T.CorLineOfBusiness,
	|	T.CorGroupOfManufacturedProducts,
	|	T.BusinessOperation,
	|
	|	T.DocumentInflow AS DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|
	|	T.CostInclVAT AS CostInclVAT,
	|	T.CostExcludingVAT AS CostExcludingVAT,
	|	T.CostExcludingVATLocal AS CostExcludingVATLocal,
	|	T.VATLocal AS VATLocal,
	|	T.CostExcludingVATMan AS CostExcludingVATMan,
	|	T.VATManag AS VATManag,
	|	T.Count
	|FROM
	|	TTTurnoverValueOfBatchesVATPreliminary3 AS T
	|
	|INDEX BY
	|	Organization,
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Organization,
	|	T.DocumentInflow,
	|	T.BusinessOperation
	|INTO TTVATReceiptDocuments
	|FROM
	|	TTTurnoverValueOfBatchesVATPreliminary AS T
	|WHERE
	|	T.VATCanBeDebited
	|INDEX BY
	|	Organization,
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 0
	|	T.Organization,
	|	T.DocumentInflow AS DocumentInflow,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemVATExempt,
	|	UNDEFINED AS ExpenseDimensionVATExempt,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenceItemUTII,
	|	UNDEFINED AS VATDebitingDimensionBySalesSubjectToUTIIActivityType
	|
	|INTO TTDocumentsForVATWriteOff
	|FROM
	|	TTVATReceiptDocuments AS T
	|
	|INDEX BY
	|	Organization,
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	T.Period AS Period,
	|	T.OfficialTypeOfMovementParish AS OfficialTypeOfMovementParish,
	|	T.Recorder AS Recorder,
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.AccountingSection AS AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|	T.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.AssetAndLiabilityItem AS AssetAndLiabilityItem,
	|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN T.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN ISNULL(VATDeduction_.ExpenseItemVATExempt, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))
	|		ELSE ISNULL(VATDeduction_.ExpenceItemUTII, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))
	|	END AS VATWriteOffItem,
	|	CASE
	|		WHEN T.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN ISNULL(VATDeduction_.ExpenseDimensionVATExempt, UNDEFINED)
	|		ELSE ISNULL(VATDeduction_.VATDebitingDimensionBySalesSubjectToUTIIActivityType, UNDEFINED)
	|	END AS DimensionVATWriteOff,
	|	T.ExpenseItemAssets AS ExpenseItemAssets,
	|	T.AssetExpenseAnalytics AS AssetExpenseAnalytics,
	|	CASE
	|		WHEN FALSE THEN UNDEFINED
	|		ELSE T.CorVATActivityTypes
	|	END AS CorVATActivityTypes,
	|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	T.Department AS Department,
	|	T.EntryType AS EntryType,
	|	T.ReversingEntry AS ReversingEntry,
	|	T.FinRecordID,
	|	T.ItemByItemCosts AS ItemByItemCosts,
	|	T.ItemByItemCostsOfUnfinishedProduction AS ItemByItemCostsOfUnfinishedProduction,
	|	T.ProductionCostType,
	|	CASE WHEN T.VATCanBeDebited AND NOT VATDeduction_.Organization IS NULL
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS VATCanBeDebited,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.CorLineOfBusiness AS CorLineOfBusiness,
	|	T.CorGroupOfManufacturedProducts AS CorGroupOfManufacturedProducts,
	|	CASE
	|		WHEN FALSE THEN UNDEFINED // for easy tag placement
	|		ELSE T.BusinessOperation
	|	END AS BusinessOperation,
	|	T.DocumentInflow AS DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|
	|	CASE
	|		WHEN CAST(T.CostInclVAT AS NUMBER (31,2)) > T.CostInclVAT
	|		 AND T.CostInclVAT > 0
	|		 AND MST.TaxationSystem IS NOT NULL
	|			THEN CAST(T.CostInclVAT AS NUMBER (31,2)) - 0.01
	|		WHEN CAST(T.CostInclVAT AS NUMBER (31,2)) < T.CostInclVAT
	|		 AND T.CostInclVAT < 0
	|		 AND MST.TaxationSystem IS NOT NULL
	|			THEN CAST(T.CostInclVAT AS NUMBER (31,2)) + 0.01
	|		ELSE CAST(T.CostInclVAT AS NUMBER (31,2))
	|	END AS CostInclVAT,
	|	CASE
	|		WHEN CAST(T.CostExcludingVAT AS NUMBER (31,2)) > T.CostExcludingVAT
	|		 AND T.CostExcludingVAT > 0
	|		 AND MST.TaxationSystem IS NOT NULL
	|			THEN CAST(T.CostExcludingVAT AS NUMBER (31,2)) - 0.01
	|		WHEN CAST(T.CostExcludingVAT AS NUMBER (31,2)) < T.CostExcludingVAT
	|		 AND T.CostExcludingVAT < 0
	|		 AND MST.TaxationSystem IS NOT NULL
	|			THEN CAST(T.CostExcludingVAT AS NUMBER (31,2)) + 0.01
	|		ELSE CAST(T.CostExcludingVAT AS NUMBER (31,2))
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN CAST(T.CostExcludingVATLocal AS NUMBER (31,2)) > T.CostExcludingVATLocal
	|		 AND T.CostExcludingVATLocal > 0
	|		 AND MST.TaxationSystem IS NOT NULL
	|			THEN CAST(T.CostExcludingVATLocal AS NUMBER (31,2)) - 0.01
	|		WHEN CAST(T.CostExcludingVATLocal AS NUMBER (31,2)) < T.CostExcludingVATLocal
	|		 AND T.CostExcludingVATLocal < 0
	|		 AND MST.TaxationSystem IS NOT NULL
	|			THEN CAST(T.CostExcludingVATLocal AS NUMBER (31,2)) + 0.01
	|		ELSE CAST(T.CostExcludingVATLocal AS NUMBER (31,2))
	|	END AS CostExcludingVATLocal,
	|	CASE
	|		WHEN CAST(T.VATLocal AS NUMBER (31,2)) > T.VATLocal
	|		 AND T.VATLocal > 0
	|		 AND MST.TaxationSystem IS NOT NULL
	|			THEN CAST(T.VATLocal AS NUMBER (31,2)) - 0.01
	|		WHEN CAST(T.VATLocal AS NUMBER (31,2)) < T.VATLocal
	|		 AND T.VATLocal < 0
	|		 AND MST.TaxationSystem IS NOT NULL
	|			THEN CAST(T.VATLocal AS NUMBER (31,2)) + 0.01
	|		ELSE CAST(T.VATLocal AS NUMBER (31,2))
	|	END AS VATLocal,
	|	CASE 
	|		WHEN CAST(T.CostExcludingVATMan AS NUMBER (31,2)) > T.CostExcludingVATMan
	|		 AND T.CostExcludingVATMan > 0
	|		 AND MST.TaxationSystem IS NOT NULL
	|			THEN CAST(T.CostExcludingVATMan AS NUMBER (31,2)) - 0.01
	|		WHEN CAST(T.CostExcludingVATMan AS NUMBER (31,2)) < T.CostExcludingVATMan
	|		 AND T.CostExcludingVATMan < 0
	|		 AND MST.TaxationSystem IS NOT NULL
	|			THEN CAST(T.CostExcludingVATMan AS NUMBER (31,2)) + 0.01
	|		ELSE CAST(T.CostExcludingVATMan AS NUMBER (31,2))
	|	END AS CostExcludingVATMan,
	|	CASE
	|		WHEN CAST(T.VATManag AS NUMBER (31,2)) > T.VATManag
	|		 AND T.VATManag > 0
	|		 AND MST.TaxationSystem IS NOT NULL
	|			THEN CAST(T.VATManag AS NUMBER (31,2)) - 0.01
	|		WHEN CAST(T.VATManag AS NUMBER (31,2)) < T.VATManag
	|		 AND T.VATManag < 0
	|		 AND MST.TaxationSystem IS NOT NULL
	|			THEN CAST(T.VATManag AS NUMBER (31,2)) + 0.01
	|		ELSE CAST(T.VATManag AS NUMBER (31,2))
	|	END AS VATManag,
	|	T.Count AS Count
	|INTO TTTurnoverCostOfBatchesOfVATWithoutVATAdjustments
	|FROM
	|	TTTurnoverValueOfBatchesVATPreliminary AS T
	|	LEFT JOIN TTDocumentsForVATWriteOff AS VATDeduction_
	|		ON VATDeduction_.Organization = T.Organization
	|		AND VATDeduction_.DocumentInflow = T.DocumentInflow
	|		AND T.VATCanBeDebited
	|	LEFT JOIN TTAccountingPoliciesOfOrganizations AS MST
	|		ON MST.Organization = T.Organization
	|		AND MST.TaxationSystem = VALUE(Enum.TaxationSystems.Shared3)
	|
	|INDEX BY
	|	RecNo
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 9999999999999
	|	RECORDAUTONUMBER() AS RecNo,
	|	T.DocumentInflow,
	|	T.Organization,
	|	T.RecNo AS RecordNumberOriginal,
	|	T.CostExcludingVATLocal,
	|	T.VATLocal,
	|	T.VATManag
	|INTO TueReceiptDocumentsPreliminary
	|FROM
	|	TTTurnoverCostOfBatchesOfVATWithoutVATAdjustments AS T
	|WHERE
	// VAT is included in the cost
	|	T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
	|	AND T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|	AND T.VATWriteOffItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	AND (NOT T.OfficialTypeOfMovementParish
	|		OR VALUETYPE(T.Recorder) = TYPE(Document.AllocationOfOtherCosts))
	|
	// The order of the fields and the further logic of adjusting the kopecks should be identical to the text of the request for detailationparticipants()
	|ORDER BY
	|	Recorder,
	|	Period,
	|	OfficialTypeOfMovementParish,
	|	Lot,
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	Organization,
	|	FinancialAccountingDimension,
	|	VATActivityType,
	|	CorItemsLocationAttributes,
	|	Count
	|
	|INDEX BY
	|	RecNo
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(T.RecNo) AS RecNo,
	|	T.DocumentInflow,
	|	T.Organization,
	|	SUM(T.CostExcludingVATLocal) AS CostExcludingVAT,
	|	SUM(T.VATLocal) AS VAT,
	|	SUM(T.VATManag) AS VATManag
	|INTO TTReceiptDocumentsAdjustmentNodes
	|FROM
	|	TueReceiptDocumentsPreliminary AS T
	|GROUP BY
	|	T.DocumentInflow,
	|	T.Organization
	|
	|INDEX BY
	|	RecNo
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.RecordNumberOriginal AS RecNo,
	|	AdjustingEntries.DocumentInflow AS DocumentInflow,
	|	AdjustingEntries.Organization,
	|	AdjustingEntries.CostExcludingVAT,
	|	AdjustingEntries.VAT,
	|	AdjustingEntries.VATManag
	|INTO TueReceiptDocuments
	|FROM
	|	TueReceiptDocumentsPreliminary AS T
	|	INNER JOIN TTReceiptDocumentsAdjustmentNodes AS AdjustingEntries
	|		ON T.RecNo = AdjustingEntries.RecNo
	|INDEX BY
	|	DocumentInflow
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.TaxInvoice AS DocumentInflow,
	|	T.Organization AS Organization,
	|	SUM(T.AmountExcludingVATTurnover) AS CostExcludingVAT,
	|	SUM(T.VATTurnover) AS VAT,
	|	SUM(T.VATManagTurnover) AS VATManag
	|INTO TTRegisteredRecordedVATTurnover
	|FROM
	|	AccumulationRegister.VATRegisterRecords.Turnovers(, DATEADD(&BeginOfPeriod, SECOND, -1), ,
	|		TaxInvoice IN (SELECT Filter.DocumentInflow FROM TueReceiptDocuments AS Filter)) AS T	
	|GROUP BY
	|	T.TaxInvoice,
	|	T.Organization
	|
	|INDEX BY
	|	DocumentInflow
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.DocumentInflow AS DocumentInflow,
	|	T.Organization AS Organization,
	|	T.RecNo AS RecNo,
	|	CASE WHEN TurnoverVAT.CostExcludingVAT - T.CostExcludingVAT <> 0
	|		AND TurnoverVAT.CostExcludingVAT - T.CostExcludingVAT <= &VATRoundingErrorsWriteOffThreshold
	|		AND TurnoverVAT.CostExcludingVAT - T.CostExcludingVAT >= -&VATRoundingErrorsWriteOffThreshold
	|	  THEN TurnoverVAT.CostExcludingVAT - T.CostExcludingVAT
	|	  ELSE 0
	|	END AS CostExcludingVAT,
	|	CASE WHEN TurnoverVAT.VAT - T.VAT <> 0
	|		AND TurnoverVAT.VAT - T.VAT <= &VATRoundingErrorsWriteOffThreshold
	|		AND TurnoverVAT.VAT - T.VAT >= -&VATRoundingErrorsWriteOffThreshold
	|	  THEN TurnoverVAT.VAT - T.VAT
	|	  ELSE 0
	|	END AS VAT,
	|	CASE WHEN TurnoverVAT.VATManag - T.VATManag <> 0
	|		AND TurnoverVAT.VATManag - T.VATManag <= &VATRoundingErrorsWriteOffThreshold
	|		AND TurnoverVAT.VATManag - T.VATManag >= -&VATRoundingErrorsWriteOffThreshold
	|	  THEN TurnoverVAT.VATManag - T.VATManag
	|	  ELSE 0
	|	END AS VATManag
	|INTO VATTTAdjustments
	|FROM
	|	TueReceiptDocuments AS T
	|	INNER JOIN TTRegisteredRecordedVATTurnover AS TurnoverVAT
	|		ON T.DocumentInflow = TurnoverVAT.DocumentInflow
	|		AND T.Organization = TurnoverVAT.Organization
	|WHERE
	|	CASE WHEN TurnoverVAT.CostExcludingVAT - T.CostExcludingVAT <> 0
	|		AND TurnoverVAT.CostExcludingVAT - T.CostExcludingVAT <= &VATRoundingErrorsWriteOffThreshold
	|		AND TurnoverVAT.CostExcludingVAT - T.CostExcludingVAT >= -&VATRoundingErrorsWriteOffThreshold
	|	  THEN TurnoverVAT.CostExcludingVAT - T.CostExcludingVAT
	|	  ELSE 0
	|	END  <> 0
	|	OR CASE WHEN TurnoverVAT.VAT - T.VAT <> 0
	|		AND TurnoverVAT.VAT - T.VAT <= &VATRoundingErrorsWriteOffThreshold
	|		AND TurnoverVAT.VAT - T.VAT >= -&VATRoundingErrorsWriteOffThreshold
	|	  THEN TurnoverVAT.VAT - T.VAT
	|	  ELSE 0
	|	END  <> 0
	|	OR CASE WHEN TurnoverVAT.VATManag - T.VATManag <> 0
	|		AND TurnoverVAT.VATManag - T.VATManag <= &VATRoundingErrorsWriteOffThreshold
	|		AND TurnoverVAT.VATManag - T.VATManag >= -&VATRoundingErrorsWriteOffThreshold
	|	  THEN TurnoverVAT.VATManag - T.VATManag
	|	  ELSE 0
	|	END  <> 0
	|INDEX BY
	|	RecNo
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Period,
	|	T.OfficialTypeOfMovementParish,
	|	T.Recorder,
	|	T.Organization,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.AccountingSection,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.FinancialAccountingDimension,
	|	T.VATActivityType,
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.AssetAndLiabilityItem,
	|	T.AssetsLiabilitiesDimension,
	|	T.VATWriteOffItem,
	|	T.DimensionVATWriteOff,
	|	T.ExpenseItemAssets,
	|	T.AssetExpenseAnalytics,
	|	T.CorVATActivityTypes,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.Department,
	|	T.EntryType,
	|	T.ReversingEntry,
	|	T.FinRecordID,
	|	T.ItemByItemCosts,
	|	T.ItemByItemCostsOfUnfinishedProduction,
	|	T.ProductionCostType,
	|	T.VATCanBeDebited,
	|	T.LineOfBusiness,
	|	T.CorLineOfBusiness,
	|	T.CorGroupOfManufacturedProducts,
	|	T.BusinessOperation,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|
	|	T.CostInclVAT,
	|	T.CostExcludingVAT,
	|	CAST(T.CostExcludingVATLocal + ISNULL(VATAdjustments.CostExcludingVAT, 0) AS NUMBER(31, 2)) AS CostExcludingVATLocal,
	|	CAST(T.VATLocal + ISNULL(VATAdjustments.VAT, 0) AS NUMBER(31, 2)) AS VATLocal,
	|	T.CostExcludingVATMan,
	|	CAST(T.VATManag + ISNULL(VATAdjustments.VATManag, 0) AS NUMBER(31, 2)) AS VATManag,
	|	T.Count
	|INTO TTTurnoverValueOfBatchesVAT
	|FROM
	|	TTTurnoverCostOfBatchesOfVATWithoutVATAdjustments AS T
	|	LEFT JOIN VATTTAdjustments AS VATAdjustments
	|		ON VATAdjustments.RecNo = T.RecNo
	|		AND VATAdjustments.DocumentInflow = T.DocumentInflow
	|		AND VATAdjustments.Organization = T.Organization
	|
	|INDEX BY
	|	Recorder
	|";
	
	
	Return QueryText;
	
EndFunction

Function QueryTextVATNodes(WithDecryptionOfFields = False)
	
	QueryText =
	"SELECT
	|	T.NewReceiverNode AS NodeNumber,
	|	MAX(CASE WHEN T.SourceNode = -1
	|		THEN 1
	|		ELSE 0
	|	END) AS Initial_Cost,
	|	MAX(T.CostInclVAT) AS CostInclVAT,
	|	MAX(T.CostExcludingVAT) AS CostExcludingVAT,
	|	MAX(T.CostExcludingVATLocal) AS CostExcludingVATLocal,
	|	MAX(T.VATLocal) AS VATLocal,
	|	MAX(T.CostExcludingVATMan) AS CostExcludingVATMan,
	|	MAX(T.VATManag) AS VATManag,
	|	MAX(CASE WHEN T.VATLocal <> 0 OR T.VATManag <> 0 THEN 1 ELSE 0 END) AS VATDeduction_,
	|	MAX(CASE WHEN T.CostExcludingVATLocal <> 0 OR T.CostExcludingVATMan <> 0  THEN 1 ELSE 0 END) AS TransferOfNettedInitialCostLocal
	|INTO TTNodesVATForSolvingSLS
	|FROM
	|	TTCalculationResultPreliminary AS T
	|
	|GROUP BY
	|	T.NewReceiverNode";
	
	If Not WithDecryptionOfFields Then
		QueryText = StrReplace(QueryText, "INTO TTNodesVATForSolvingSLS", "");
		Return QueryText;
	EndIf;
	
	QueryText = QueryText + "
	|;
	|" + "
	|SELECT
	|	T.NodeNumber AS NodeNumber,
	|	NewNodes.NodeNumber AS CostNodeNumber,
	|	NewNodes.VATNodeNumber AS VATNodeNumber,
	|
	|	CostNodes.Organization AS Organization,
	|	CostNodes.AccountingSection,
	|	CostNodes.ItemsLocationAttributes,
	|	CostNodes.InventoryOwnerAttribute,
	|	CostNodes.Lot,
	|	CostNodes.LotVendorAttributes,
	|	CostNodes.VATActivityType,
	|	CostNodes.FinancialAccountingDimension,
	|
	|	VATNodes.InventoryLocationAttributesOfReceiptDocument,
	|	VATNodes.ExpenseItem AS ExpenseItem,
	|	VATNodes.DimensionOfExpenses AS DimensionOfExpenses,
	|	VATNodes.DocumentInflow,
	|	VATNodes.LotVendorAttributesOfReceiptDocument,
	|
	|	ISNULL(VATNodes.TheseAreRemainingArticleByArticleVariables, FALSE) AS TheseAreRemainingArticleByArticleVariables,
	|	ISNULL(VATNodes.TheseRemaindersAreArticleByArticleConstants, FALSE) AS TheseRemaindersAreArticleByArticleConstants,
	|	ISNULL(VATNodes.ThisIsAdditionalExpense, FALSE) AS ThisIsAdditionalExpense,
	|	ISNULL(VATNodes.TheseAreVariableAdditionalCosts, FALSE) AS TheseAreVariableAdditionalCosts,
	|
	|	CostNodes.LotQuantity AS LotQuantity,
	|	T.Initial_Cost,
	|	VATNodes.CostInclVAT,
	|	VATNodes.CostExcludingVAT,
	|	VATNodes.CostExcludingVATLocal,
	|	VATNodes.VATLocal,
	|	VATNodes.CostExcludingVATMan,
	|	VATNodes.VATManag,
	|	CASE WHEN T.VATLocal <> 0 OR T.VATManag <> 0 THEN 1 ELSE 0 END AS VATDeduction_,
	|	CASE WHEN T.CostExcludingVATLocal <> 0 OR T.CostExcludingVATMan <> 0 THEN 1 ELSE 0 END AS TransferOfNettedInitialCostLocal
	|FROM
	|	TTNewNodes AS NewNodes
	|	INNER JOIN TTNodesVATForSolvingSLS AS T
	|		ON T.NodeNumber = NewNodes.NewNodeNumber
	|	LEFT JOIN TTInitialCostNodesAndVAT AS VATNodes
	|		ON NewNodes.VATNodeNumber = VATNodes.NodeNumberVATGroup
	|	LEFT JOIN TTCOSTAdjustmentSubAssetsWithBATCHBalances AS CostNodes
	|		ON CostNodes.NodeNumber = NewNodes.NodeNumber
	|
	|ORDER BY
	|	NodeNumber
	|";
	
	Return QueryText;
	
EndFunction

Function TextOfVATConnectionRequest(ThereAreArticleByArticle = False)
	
	QueryText =
	"SELECT
	|	T.NewSourceNode AS Source,
	|	T.NewReceiverNode AS Receiver,
	|	MAX(ISNULL(-CostNodeConnections.Weight, 0)) AS Weight,
	|	MAX(CASE WHEN T.DeductVAT
	|		THEN 0
	|		ELSE ISNULL(-CostNodeConnections.Weight, 0)
	|	END) AS VATWeight,
	|	MAX(CASE WHEN ConnectionsOfRedistributionNodes.SourceNodeNumber IS NOT NULL
	|		THEN 0
	|		ELSE ISNULL(-CostNodeConnections.Weight, 0)
	|	END) AS WeightConversion,
	|	MAX(CASE WHEN ConnectionsNettingInitialCostLOCAL.SourceNodeNumber IS NOT NULL
	|		THEN 0
	|		ELSE ISNULL(-CostNodeConnections.Weight, 0)
	|	END) AS WeightTransferNettingInitialCostLOCAL
	|FROM
	|	TTCalculationResultPreliminary AS T
	|		LEFT JOIN TTConnectionOfCostAdjustmentNodesWithVATWriteOff AS CostNodeConnections
	|			ON T.SourceNode = CostNodeConnections.SourceNodeNumber
	|			AND T.ReceiverNode = CostNodeConnections.ReceiverNodeNumber
	|		LEFT JOIN TTConnectionOfCostAdjustmentNodesWithBatchChange AS ConnectionsOfRedistributionNodes
	|			ON T.SourceNode = ConnectionsOfRedistributionNodes.SourceNodeNumber
	|			AND T.ReceiverNode = ConnectionsOfRedistributionNodes.ReceiverNodeNumber
	|		LEFT JOIN TTCommunicationNodesCostAdjustmentNetInitialCostLocal AS ConnectionsNettingInitialCostLOCAL
	|			ON T.SourceNode = ConnectionsNettingInitialCostLOCAL.SourceNodeNumber
	|			AND T.ReceiverNode = ConnectionsNettingInitialCostLOCAL.ReceiverNodeNumber
	|WHERE
	|	T.NewSourceNode <> -1
	|
	|GROUP BY
	|	T.NewSourceNode,
	|	T.NewReceiverNode
	|
	|UNION ALL
	|
	|SELECT
	|	T.NewReceiverNode,
	|	T.NewReceiverNode,
	|	MAX(CostNodes.Weight),
	|	MAX(CASE WHEN T.DeductVAT
	|		THEN 0
	|		ELSE CostNodes.Weight
	|	END) AS VATWeight,
	|	MAX(CostNodes.Weight) AS WeightConversion,
	|	MAX(CostNodes.Weight) AS WeightTransferNettingInitialCostLOCAL
	|FROM
	|	TTCalculationResultPreliminary AS T
	|		LEFT JOIN TTCostAdjustmentUnits AS CostNodes
	|			ON T.ReceiverNode = CostNodes.NodeNumber
	|
	|GROUP BY
	|	T.NewReceiverNode";
	
	If ThereAreArticleByArticle Then
		QueryText = StrReplace(QueryText, "TTCostAdjustmentUnits", "TTWeightsOfNodesAreArticleByArticle");
		
	EndIf;
	
	Return QueryText;
	
EndFunction

Function DataForSolvingSLUNDS(CalculationParameters) Export
	
	Result = New Structure("Nodes, Links, ErrorText");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
		
	Try
		
		Query.Text = QueryTextVATNodes(True);
		Result.Nodes = Query.Execute().Unload();
		
		Query.Text = TextOfVATConnectionRequest();
		Result.Links = Query.Execute().Unload();
		
	Except
		
		Result.ErrorText = DetailErrorDescription(ErrorInfo());
		
	EndTry;
	
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters, NewTT);
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
	Return Result;
	
EndFunction

Function QueryTextPreparationOfVATDistributionData(CalculationParameters = Undefined) Export
	
	QueryText =
	"SELECT
	|	BEGINOFPERIOD(MAX(T.Period), MONTH) AS Period
	|INTO PeriodOfPreviousCalculatedPeriod
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|WHERE
	|	T.Period < &BeginOfPeriod
	|	AND T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|INDEX BY
	|	Period
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DD.Organization,
	|	CAST(DD.Recorder AS Document.ReversingEntry) AS ReversingEntry,
	|	CAST(DD.Recorder AS Document.ReversingEntry).ReversedDocument AS ReversedDocument
	|INTO TTDocumentsStornoPreliminary
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS DD
	|WHERE
	|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND VALUETYPE(DD.Recorder) = TYPE(Document.ReversingEntry)
	|
	|INDEX BY
	|	ReversedDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Organization,
	|	DD.ReversingEntry,
	|	DD.ReversedDocument,
	|	CASE WHEN ISNULL(StornoDates.RecorderDate, &BeginOfPeriod) < &BeginOfPeriod
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ReverseOfPreviousPeriod
	|INTO TTDocumentsStorno
	|FROM
	|	TTDocumentsStornoPreliminary AS DD
	|	LEFT JOIN InformationRegister.SourceDocumentsData AS StornoDates
	|		ON StornoDates.Organization = DD.Organization
	|		AND StornoDates.Document = DD.ReversedDocument
	|INDEX BY
	|	ReversingEntry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.FinRecordID,
	|	MAX(T.LotVendorAttributesCorr) AS LotVendorAttributesOfReceiptDocument
	|INTO TTAnalyticsOfAccountingOfBatchesOfAdditionalExpenses
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS T
	|WHERE
	|	T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND T.OfficialTypeOfMovementParish
	|	AND T.LotVendorAttributesCorr <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|	AND T.FinRecordID <> &IDOfUnusedFinRecord
	|	AND (VALUETYPE(T.Recorder) = TYPE(Document.CCDImport)
	|		OR VALUETYPE(T.Recorder) = TYPE(Document.ApplicationForImportationOfGoods))
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|GROUP BY
	|	T.Recorder,
	|	T.FinRecordID
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder,
	|	T.Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	|	(T.AddExpensesForGoods - T.AdditionalExpensesWriteOff) / T.AddExpensesForGoods AS ZoomRatio
	|INTO TTAdditionalExpenseRatios
	|FROM
	|	(SELECT
	|		T.Recorder,
	|		T.Organization,
	|		T.AccountingSection,
	|		T.ItemsLocationAttributes,
	|		T.InventoryOwnerAttribute,
	|		T.Lot,
	|		T.LotVendorAttributes,
	|		T.VATActivityType,
	|		T.FinancialAccountingDimension,
	|  		SUM(T.AddExpensesLocal) AS AddExpensesForGoods,
	|   	SUM(CASE WHEN T.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
	|			THEN T.AddExpensesLocal
	|			ELSE 0
	|		END) AS AdditionalExpensesWriteOff
	|	FROM
	|		TTCashEstimatedTurnoverCostOfGoods AS T
	|	WHERE
	|		T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|		AND T.Recorder REFS Document.AllocationOfOtherCosts
	|		AND T.OfficialTypeOfMovementParish
	|		AND T.EntryType IN (VALUE(Enum.LotRecordTypes.AddExpensesForGoods), VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods))
	|		AND T.AddExpensesLocal <> 0
	|	GROUP BY
	|		T.Recorder,
	|		T.Organization,
	|		T.AccountingSection,
	|		T.ItemsLocationAttributes,
	|		T.InventoryOwnerAttribute,
	|		T.Lot,
	|		T.LotVendorAttributes,
	|		T.VATActivityType,
	|		T.FinancialAccountingDimension
	|	) AS T
	|WHERE
	|	T.AdditionalExpensesWriteOff <> 0
	|	AND T.AddExpensesForGoods <> 0
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|	SUM(DD.Count) AS Count,
	|	SUM(DD.CostInclVAT) AS CostInclVAT,
	|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT
	|INTO TTCostBalancesForVATLots
	|FROM
	|(SELECT
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|	DD.CountBalance AS Count,
	|	DD.CostBalance AS CostInclVAT,
	|	DD.CostExcludingVATBalance AS CostExcludingVAT
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(&BorderEndOfPreviousPeriod,
	|		Organization IN (&OrganizationsIncludingVATLotsVersion24)) AS DD
	|		
	|UNION ALL
	|		
	|SELECT
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|	CASE WHEN DD.OfficialTypeOfMovementParish THEN 1 ELSE -1 END * DD.Count AS Count,
	|	CASE WHEN DD.OfficialTypeOfMovementParish THEN 1 ELSE -1 END * DD.Cost AS CostInclVAT,
	|	CASE WHEN DD.OfficialTypeOfMovementParish THEN 1 ELSE -1 END * DD.CostExcludingVAT AS CostExcludingVAT
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS DD
	|WHERE
	|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND DD.ReversingEntry
	|	AND ((NOT DD.OfficialTypeOfMovementParish
	|			AND DD.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections))
	|		OR
	|	   (DD.OfficialTypeOfMovementParish
	|			AND DD.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer))
	|	  )
	|) AS DD
	|GROUP BY
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension
	|HAVING
	|	SUM(DD.Count) <> 0
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.ItemsLocationAttributes.Products AS Products,
	|	DD.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|	DD.Count,
	|	DD.CostInclVAT,
	|	DD.CostExcludingVAT
	|INTO CostBalancesWithNomenclatureForVATBatchesTT
	|FROM
	|	TTCostBalancesForVATLots AS DD
	|INDEX BY
	|	Lot,
	|	LotVendorAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	Products,
	|	Characteristic,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Organization AS Organization,
	|	T.AccountingSection AS AccountingSection,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.VATActivityType AS VATActivityType,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension 
	|INTO TUEWriteOffOfLowValueMC
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|	INNER JOIN Document.InventoryCostCalculation AS Filter
	|		ON T.Recorder = Filter.Ref
	|WHERE
	|	T.Period BETWEEN &BeginningOfPreviousPeriod AND &EndOfPreviousPeriod
	|	AND T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffLowCostInventoryAsExpensesInThePurchaseMonth)
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization AS Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	|	Balance.Count
	|INTO TUEAdjustmentsWriteOffOfLowValueMC
	|FROM
	|	TUEWriteOffOfLowValueMC AS T
	|	INNER JOIN TTCostBalancesForVATLots AS Balance
	|		ON T.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|		AND T.Organization = Balance.Organization
	|		AND T.Lot = Balance.Lot
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.AccountingSection = Balance.AccountingSection
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND T.FinancialAccountingDimension = Balance.FinancialAccountingDimension
	|		AND T.VATActivityType = Balance.VATActivityType
	|
	|INDEX BY
	|	Lot,
	|	LotVendorAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization,
	|	T.AccountingSection AS AccountingSection,
	|	T.VATActivityType AS VATActivityType,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|
	// Cor. Cost Analysis
	|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	T.CorLot AS CorLot,
	|	T.LotVendorAttributesCorr AS LotVendorAttributesCorr,
	|	T.CorVATActivityTypes AS CorVATActivityTypes,
	|	T.CorControllingAttributes AS CorControllingAttributes,
	|
	// Other fields
	|	T.Period AS Period,
	|	T.Recorder AS Recorder,
	|	T.EntryType AS EntryType,
	|	T.Department AS Department,
	|	T.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.ReversingEntry AS ReversingEntry,
	|	T.SalePeriod AS SalePeriod,
	|	T.DocumentSource AS DocumentSource,
	|	T.OfficialTypeOfMovementParish AS OfficialTypeOfMovementParish,
	|	T.BusinessOperation AS BusinessOperation, 
	|
	// Resources
	|	SUM(T.Count) AS Count,
	|	SUM(T.Cost) AS Cost,
	|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(T.LocalCost) AS LocalCost,
	|	SUM(T.VATLocal) AS VATLocal,
	|	SUM(T.CostMan) AS CostMan,
	|	SUM(T.VATManag) AS VATManag
	|INTO TTCacheEstimatedTurnoverOfInventoryCosts_Indexes
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS T
	|WHERE
	|	T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|GROUP BY
	|	T.ItemsLocationAttributes,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Organization,
	|	T.AccountingSection,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.CorLot,
	|	T.LotVendorAttributesCorr,
	|	T.CorVATActivityTypes,
	|	T.CorControllingAttributes,
	|	T.Period,
	|	T.Recorder,
	|	T.EntryType,
	|	T.Department,
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.ReversingEntry,
	|	T.SalePeriod,
	|	T.DocumentSource,
	|	T.OfficialTypeOfMovementParish,
	|	T.BusinessOperation
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	CASE WHEN Balance.Organization IS NULL THEN FALSE ELSE TRUE END AS IsBalance,
	// Cost Analysts
	|	DD.Organization AS Organization,
	|	DD.AccountingSection AS AccountingSection,
	|	CAST(DD.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Cor. Cost Analysis
	|	DD.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	DD.CorInventoryOwnerAttribute,
	|	DD.CorLot AS CorLot,
	|	DD.LotVendorAttributesCorr,
	|	DD.CorVATActivityTypes,
	|	DD.CorControllingAttributes,
	|
	// Other fields
	|	DD.Period,
	|	DD.Recorder,
	|	DD.EntryType,
	|	DD.Department,
	|	DD.ReversingEntry,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemAssets,
	|	UNDEFINED AS AssetExpenseAnalytics,
	|	BEGINOFPERIOD(DD.SalePeriod, MONTH) AS SalePeriod,
	|	DD.DocumentSource AS SaleOfGoodsAndServices,
	|
	// Resources
	|	DD.Count AS Count
	|INTO TTRefundsFromPreviousPeriods
	|FROM
	|	TTCacheEstimatedTurnoverOfInventoryCosts_Indexes AS DD
	|	LEFT JOIN TTCostBalancesForVATLots AS Balance
	|		ON DD.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|		AND DD.Organization = Balance.Organization
	|		AND DD.Lot = Balance.Lot
	|		AND DD.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND DD.AccountingSection = Balance.AccountingSection
	|		AND DD.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND DD.FinancialAccountingDimension = Balance.FinancialAccountingDimension
	|		AND DD.VATActivityType = Balance.VATActivityType
	|WHERE
	|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND DD.Lot <> UNDEFINED
	|   AND DD.OfficialTypeOfMovementParish
	|	AND DD.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
	|	AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnPackageFromCustomerOfPreviousPeriods)
	|	AND DD.Count <> 0
	|
	|INDEX BY
	|	SaleOfGoodsAndServices,
	|	CorItemsLocationAttributes,
	|	Organization,
	|	CorLot,
	|	CorInventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributesCorr,
	|	CorControllingAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.RecNo,
	|	DD.IsBalance,
	// Cost Analysts
	|	DD.Organization AS Organization,
	|	DD.AccountingSection AS AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Cor. Cost Analysis
	|	DD.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	DD.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	DD.CorLot AS CorLot,
	|	DD.LotVendorAttributesCorr AS LotVendorAttributesCorr,
	|	DD.CorVATActivityTypes AS CorVATActivityTypes,
	|	DD.CorControllingAttributes AS CorControllingAttributes,
	|
	// Other fields
	|	DD.Period,
	|	DD.Recorder,
	|	DD.EntryType,
	|	DD.Department,
	|	DD.ReversingEntry,
	|	DD.ExpenseItemAssets,
	|	DD.AssetExpenseAnalytics,
	|	DD.SalePeriod,
	|	DD.SaleOfGoodsAndServices,
	|
	// Resources
	|	DD.Count AS Count
	|INTO TT_ReturnsOfPreviousPeriods_Indexes
	|FROM
	|	TTRefundsFromPreviousPeriods AS DD
	|
	|INDEX BY
	|	SalePeriod,
	|	CorItemsLocationAttributes,
	|	Organization,
	|	CorLot,
	|	CorInventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributesCorr,
	|	CorControllingAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.RecNo,
	|	DD.IsBalance,
	// Cost Analysts
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.ItemsLocationAttributes.Products AS Products,
	|	DD.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Cor. Cost Analysis
	|	DD.CorItemsLocationAttributes,
	|	DD.CorInventoryOwnerAttribute,
	|	DD.CorLot,
	|	DD.LotVendorAttributesCorr,
	|	DD.CorVATActivityTypes,
	|	DD.CorControllingAttributes,
	|
	// Other fields
	|	DD.Period,
	|	DD.Recorder,
	|	DD.EntryType,
	|	DD.Department,
	|	DD.ReversingEntry,
	|	DD.ExpenseItemAssets,
	|	DD.AssetExpenseAnalytics,
	|	DD.SalePeriod,
	|	DD.SaleOfGoodsAndServices,
	|
	// Resources
	|	DD.Count
	|INTO TTReturnsOfPreviousPeriodsWithNomenclature
	|FROM
	|	TTRefundsFromPreviousPeriods AS DD
	|
	|INDEX BY
	|	Lot,
	|	LotVendorAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.SaleOfGoodsAndServices AS SaleOfGoodsAndServices
	|INTO TUEOfImplementationOfRefunds
	|FROM
	|	TTRefundsFromPreviousPeriods AS T
	|WHERE
	|	T.SaleOfGoodsAndServices <> UNDEFINED
	|INDEX BY
	|	SaleOfGoodsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Returns.RecNo,
	|	0 AS SourceNumber,
	|	Returns.Recorder AS Recorder,
	|	Returns.EntryType,
	|	Returns.Department,
	|	Returns.ReversingEntry,
	|	Returns.ExpenseItemAssets,
	|	Returns.AssetExpenseAnalytics,
	|	Returns.SalePeriod AS Period,
	|	Returns.Organization,
	|	Returns.ItemsLocationAttributes,
	|	Returns.InventoryOwnerAttribute,
	|	Returns.AccountingSection,
	|	Returns.Lot,
	|	Returns.LotVendorAttributes,
	|	Returns.FinancialAccountingDimension,
	|	Returns.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.PreviousRedistributionCosts,
	|	T.CostInclVAT AS CostInclVAT,
	|	T.CostExcludingVAT AS CostExcludingVAT,
	|	T.CostExcludingVATLocal AS CostExcludingVATLocal,
	|	T.VATLocal AS VATLocal,
	|	T.CostExcludingVATMan AS CostExcludingVATMan,
	|	T.VATManag AS VATManag,
	|	Returns.Count AS Count
	|INTO TUEBatchPricesVATRefunds
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS T
	|	INNER JOIN TTReturnsOfPreviousPeriodsWithNomenclature AS Returns
	|		ON T.Products = Returns.Products 
	|		AND T.Lot = Returns.Lot
	|		AND T.LotVendorAttributes = Returns.LotVendorAttributes
	|		AND T.Organization = Returns.Organization
	|		AND T.InventoryOwnerAttribute = Returns.InventoryOwnerAttribute
	|		AND T.Characteristic = Returns.Characteristic
	|WHERE
	|	T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND NOT T.EntryType IN (&TypesOfDataConversionRecords)
	|	AND T.RegistrationPeriod < &BeginOfPeriod
	//  if there are Balances for the refund batch, then the refund prices for all vat batch registers will come from the table in the price of party goods of the same period
	|	AND NOT Returns.IsBalance
	|
	|
	|INDEX BY
	|	RecNo,
	|	SourceNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.RecNo,
	|	MIN(T.SourceNumber) AS SourceNumber
	|INTO SourcesOfRefundPrices
	|FROM
	|	TUEBatchPricesVATRefunds AS T
	|GROUP BY
	|	T.RecNo
	|INDEX BY
	|	RecNo,
	|	SourceNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALSE AS TheseAreArticleByArticleVariables,
	|	FALSE AS TheseAreArticleByArticleConstants,
	|	&BeginningOfPreviousPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Balance.AccountingSection AS AccountingSection,
	|	Balance.Lot AS Lot,
	|	Balance.LotVendorAttributes AS LotVendorAttributes,
	|	Balance.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Balance.VATActivityType AS VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.PreviousRedistributionCosts,
	|	CAST(SUM(T.CostInclVAT) AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(SUM(T.CostExcludingVAT) AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(SUM(T.CostExcludingVATLocal) AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(SUM(T.VATLocal) AS NUMBER(31,10)) AS VATLocal,
	|	CAST(SUM(T.CostExcludingVATMan) AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(SUM(T.VATManag) AS NUMBER(31,10)) AS VATManag,
	|	SUM(Balance.Count) AS LotQuantity
	|INTO TTPricesOfBatchesOfGoodsAtBeginningOfPeriod
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS T
	|	INNER JOIN CostBalancesWithNomenclatureForVATBatchesTT AS Balance
	|		ON T.Lot = Balance.Lot
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND T.Organization = Balance.Organization
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.Products = Balance.Products
	|		AND T.Characteristic = Balance.Characteristic
	|		AND T.WIPInventoryLocationAttributes = Balance.ItemsLocationAttributes
	|WHERE
	|	T.RegistrationPeriod < &BeginOfPeriod
	|	AND T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND Balance.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|GROUP BY
	|	Balance.Organization,
	|	Balance.ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.AccountingSection,
	|	Balance.Lot,
	|	Balance.LotVendorAttributes,
	|	Balance.FinancialAccountingDimension,
	|	Balance.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.PreviousRedistributionCosts
	|
	|UNION ALL
	|
	|SELECT
	|	FALSE AS TheseAreArticleByArticleVariables,
	|	FALSE AS TheseAreArticleByArticleConstants,
	|	&BeginningOfPreviousPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.AccountingSection,
	|	Balance.Lot AS Lot,
	|	Balance.LotVendorAttributes,
	|	Balance.FinancialAccountingDimension,
	|	Balance.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.PreviousRedistributionCosts,
	|	CAST(SUM(T.CostInclVAT) AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(SUM(T.CostExcludingVAT) AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(SUM(T.CostExcludingVATLocal) AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(SUM(T.VATLocal) AS NUMBER(31,10)) AS VATLocal,
	|	CAST(SUM(T.CostExcludingVATMan) AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(SUM(T.VATManag) AS NUMBER(31,10)) AS VATManag,
	|	SUM(Balance.Count) AS LotQuantity
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS T
	|	INNER JOIN CostBalancesWithNomenclatureForVATBatchesTT AS Balance
	|		ON T.Lot = Balance.Lot
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND T.Organization = Balance.Organization
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.Products = Balance.Products
	|		AND T.Characteristic = Balance.Characteristic
	|WHERE
	|	T.RegistrationPeriod < &BeginOfPeriod
	|	AND T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND Balance.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|GROUP BY
	|	Balance.Organization,
	|	Balance.ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.AccountingSection,
	|	Balance.Lot,
	|	Balance.LotVendorAttributes,
	|	Balance.FinancialAccountingDimension,
	|	Balance.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.PreviousRedistributionCosts
	|
	|UNION ALL
	|
	|SELECT
	|	FALSE AS TheseAreArticleByArticleVariables,
	|	TRUE AS TheseAreArticleByArticleConstants,
	|	&BeginningOfPreviousPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.AccountingSection,
	|	Balance.Lot AS Lot,
	|	Balance.LotVendorAttributes,
	|	Balance.FinancialAccountingDimension,
	|	Balance.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS InventoryLocationAttributesOfReceiptDocument,
	|	T.PreviousRedistributionCosts,
	|	CAST(SUM(T.CostInclVAT) AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(SUM(T.CostExcludingVAT) AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(SUM(T.CostExcludingVATLocal) AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(SUM(T.VATLocal) AS NUMBER(31,10)) AS VATLocal,
	|	CAST(SUM(T.CostExcludingVATMan) AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(SUM(T.VATManag) AS NUMBER(31,10)) AS VATManag,
	|	SUM(Balance.Count) AS LotQuantity
	|FROM
	|	InformationRegister.ItemizeLotCostItemizedAndOtherCosts AS T
	|	INNER JOIN CostBalancesWithNomenclatureForVATBatchesTT AS Balance
	|		ON T.Lot = Balance.Lot
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND T.Organization = Balance.Organization
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.Products = Balance.Products
	|		AND T.Characteristic = Balance.Characteristic
	|		AND T.WIPInventoryLocationAttributes = Balance.ItemsLocationAttributes
	|WHERE
	|	T.RegistrationPeriod < &BeginOfPeriod
	|	AND T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND Balance.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|GROUP BY
	|	Balance.Organization,
	|	Balance.ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.AccountingSection,
	|	Balance.Lot,
	|	Balance.LotVendorAttributes,
	|	Balance.FinancialAccountingDimension,
	|	Balance.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.PreviousRedistributionCosts
	|
	|UNION ALL
	|
	|SELECT
	|	FALSE AS TheseAreArticleByArticleVariables,
	|	TRUE AS TheseAreArticleByArticleConstants,
	|	&BeginningOfPreviousPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.AccountingSection,
	|	Balance.Lot AS Lot,
	|	Balance.LotVendorAttributes,
	|	Balance.FinancialAccountingDimension,
	|	Balance.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS InventoryLocationAttributesOfReceiptDocument,
	|	T.PreviousRedistributionCosts,
	|	CAST(SUM(T.CostInclVAT) AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(SUM(T.CostExcludingVAT) AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(SUM(T.CostExcludingVATLocal) AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(SUM(T.VATLocal) AS NUMBER(31,10)) AS VATLocal,
	|	CAST(SUM(T.CostExcludingVATMan) AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(SUM(T.VATManag) AS NUMBER(31,10)) AS VATManag,
	|	SUM(Balance.Count) AS LotQuantity
	|FROM
	|	InformationRegister.ItemizeLotCostItemizedAndOtherCosts AS T
	|	INNER JOIN CostBalancesWithNomenclatureForVATBatchesTT AS Balance
	|		ON T.Lot = Balance.Lot
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND T.Organization = Balance.Organization
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.Products = Balance.Products
	|		AND T.Characteristic = Balance.Characteristic
	|WHERE
	|	T.RegistrationPeriod < &BeginOfPeriod
	|	AND T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND Balance.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|GROUP BY
	|	Balance.Organization,
	|	Balance.ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.AccountingSection,
	|	Balance.Lot,
	|	Balance.LotVendorAttributes,
	|	Balance.FinancialAccountingDimension,
	|	Balance.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.PreviousRedistributionCosts
	|
	|UNION ALL
	|
	|SELECT
	|	FALSE AS TheseAreArticleByArticleVariables,
	|	TRUE AS TheseAreArticleByArticleConstants,
	|	T.RegistrationPeriod,
	|	Returns.Organization,
	|	Returns.ItemsLocationAttributes,
	|	Returns.InventoryOwnerAttribute,
	|	Returns.AccountingSection,
	|	Returns.Lot,
	|	Returns.LotVendorAttributes,
	|	Returns.FinancialAccountingDimension,
	|	Returns.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS InventoryLocationAttributesOfReceiptDocument,
	|	T.PreviousRedistributionCosts,
	|	CAST(SUM(T.CostInclVAT) AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(SUM(T.CostExcludingVAT) AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(SUM(T.CostExcludingVATLocal) AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(SUM(T.VATLocal) AS NUMBER(31,10)) AS VATLocal,
	|	CAST(SUM(T.CostExcludingVATMan) AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(SUM(T.VATManag) AS NUMBER(31,10)) AS VATManag,
	|	SUM(Returns.Count) AS LotQuantity
	|FROM
	|	InformationRegister.ItemizeLotCostItemizedAndOtherCosts AS T
	|	INNER JOIN TTReturnsOfPreviousPeriodsWithNomenclature AS Returns
	|		ON T.Lot = Returns.Lot 
	|		AND T.LotVendorAttributes = Returns.LotVendorAttributes
	|		AND T.Organization = Returns.Organization
	|		AND T.InventoryOwnerAttribute = Returns.InventoryOwnerAttribute
	|		AND T.Products = Returns.Products
	|		AND T.Characteristic = Returns.Characteristic
	|WHERE
	|	T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND T.RegistrationPeriod < &BeginOfPeriod
	|GROUP BY
	|	T.RegistrationPeriod,
	|	Returns.Organization,
	|	Returns.ItemsLocationAttributes,
	|	Returns.InventoryOwnerAttribute,
	|	Returns.AccountingSection,
	|	Returns.Lot,
	|	Returns.LotVendorAttributes,
	|	Returns.FinancialAccountingDimension,
	|	Returns.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.PreviousRedistributionCosts
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE AS TheseAreArticleByArticleVariables,
	|	FALSE AS TheseAreArticleByArticleConstants,
	|	T.Period,
	|	T.Organization,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.AccountingSection,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.FinancialAccountingDimension,
	|	T.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	FALSE AS PreviousRedistributionCosts,
	|	CAST(SUM(T.CostInclVAT) AS NUMBER(31,10)) 		AS CostInclVAT,
	|	CAST(SUM(T.CostExcludingVAT) AS NUMBER(31,10)) 	AS CostExcludingVAT,
	|	CAST(SUM(T.CostExcludingVATLocal) AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(SUM(T.VATLocal) AS NUMBER(31,10)) 			AS VATLocal,
	|	CAST(SUM(T.CostExcludingVATMan) AS NUMBER(31,10)) 	AS CostExcludingVATMan,
	|	CAST(SUM(T.VATManag) AS NUMBER(31,10)) 				AS VATManag,
	|	SUM(T.LotQuantity) 								AS LotQuantity
	|FROM
	|	InformationRegister.ItemizeGoodsCostItemizedAndOtherCosts AS T
	|	INNER JOIN PeriodOfPreviousCalculatedPeriod AS RegisterRecordsPeriod
	|		ON T.Period = RegisterRecordsPeriod.Period
	|	INNER JOIN TTCostBalancesForVATLots AS Balance
	|		ON T.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|		AND T.Organization = Balance.Organization
	|		AND T.Lot = Balance.Lot
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.AccountingSection = Balance.AccountingSection
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND T.FinancialAccountingDimension = Balance.FinancialAccountingDimension
	|		AND T.VATActivityType = Balance.VATActivityType
	|WHERE
	|	T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|GROUP BY
	|	T.Period,
	|	T.Organization,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.AccountingSection,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.FinancialAccountingDimension,
	|	T.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.InventoryLocationAttributesOfReceiptDocument
	|
	|INDEX BY
	|	Period,
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.TheseAreArticleByArticleVariables,
	|	T.TheseAreArticleByArticleConstants,
	|	T.Period,
	|	T.Organization,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.AccountingSection,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes,
	|	T.FinancialAccountingDimension,
	|	T.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.PreviousRedistributionCosts,
	|	T.CostInclVAT,
	|	T.CostExcludingVAT,
	|	T.CostExcludingVATLocal,
	|	T.VATLocal,
	|	T.CostExcludingVATMan,
	|	T.VATManag,
	|	T.LotQuantity
	|INTO TT_PricesOfBatchesOfGoodsAtBeginningOfPeriod_Indices
	|FROM
	|	TTPricesOfBatchesOfGoodsAtBeginningOfPeriod AS T
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BeginningOfPreviousPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Balance.AccountingSection AS AccountingSection,
	|	Balance.Lot AS Lot,
	|	Balance.LotVendorAttributes AS LotVendorAttributes,
	|	Balance.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Balance.VATActivityType AS VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	CAST(SUM(T.CostExcludingVATLocal) AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(SUM(T.CostExcludingVATMan) AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	MAX(Balance.Count) AS LotQuantity
	|INTO TUEPricesOfLotsOfGoodsWriteOffOfMC
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS T
	|	INNER JOIN TUEAdjustmentsWriteOffOfLowValueMC AS Balance
	|		ON T.Lot = Balance.Lot
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND T.Organization = Balance.Organization
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.Products = Balance.Products
	|		AND T.Characteristic = Balance.Characteristic
	|WHERE
	|	T.RegistrationPeriod < &BeginOfPeriod
	|	AND T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|GROUP BY
	|	Balance.Organization,
	|	Balance.ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.AccountingSection,
	|	Balance.Lot,
	|	Balance.LotVendorAttributes,
	|	Balance.FinancialAccountingDimension,
	|	Balance.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginningOfPreviousPeriod AS Period,
	|	Balance.Organization AS Organization,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Balance.AccountingSection AS AccountingSection,
	|	Balance.Lot AS Lot,
	|	Balance.LotVendorAttributes AS LotVendorAttributes,
	|	Balance.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Balance.VATActivityType AS VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	CAST(SUM(T.CostExcludingVATLocal) AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(SUM(T.CostExcludingVATMan) AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	MAX(Balance.Count) AS LotQuantity
	|FROM
	|	InformationRegister.ItemizeLotCostItemizedAndOtherCosts AS T
	|	INNER JOIN TUEAdjustmentsWriteOffOfLowValueMC AS Balance
	|		ON T.Lot = Balance.Lot
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND T.Organization = Balance.Organization
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.Products = Balance.Products
	|		AND T.Characteristic = Balance.Characteristic
	|WHERE
	|	T.RegistrationPeriod < &BeginOfPeriod
	|	AND T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|GROUP BY
	|	Balance.Organization,
	|	Balance.ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.AccountingSection,
	|	Balance.Lot,
	|	Balance.LotVendorAttributes,
	|	Balance.FinancialAccountingDimension,
	|	Balance.VATActivityType,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses
	|
	|HAVING
	|	MAX(Balance.Count) > 0
	|	AND (CAST(SUM(T.CostExcludingVATLocal) AS NUMBER(31,10)) <> 0
	|		OR CAST(SUM(T.CostExcludingVATMan) AS NUMBER(31,10)) <> 0)
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////

	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	|	SUM(T.CountBalance) AS Count,
	|	SUM(T.CostBalance) AS CostInclVAT,
	|	SUM(T.CostExcludingVATBalance) AS CostExcludingVAT,
	|	SUM(T.LocalCostBalance) AS LocalCost,
	|	SUM(CASE WHEN &CompanyManagementAccounting
	|		THEN T.CostManBalance
	|		ELSE 0
	|	END) AS CostMan
	|INTO TTBalancesForAdjustments
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(&BeginOfPeriod, Organization IN (&OrganizationsIncludingVATLotsVersion24)) AS T
	|GROUP BY
	|	T.Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension
	|HAVING
	|	SUM(T.CountBalance) <> 0
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder,
	|	T.Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	|
	|	T.NumberIsSummarized AS Count,
	|	CASE WHEN SUM(CASE WHEN T.ThisIsOutlier THEN T.NumberOfDetails ELSE 0 END) = T.NumberIsSummarized THEN TRUE ELSE FALSE END AS FullDisposal
	|INTO CompletelyRetiredGoodsTT
	|FROM
	|	IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriodsDeviationsInCost AS T
	|WHERE
	|	T.NumberIsSummarized <> 0
	|
	|GROUP BY
	|	T.Recorder,
	|	T.Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	|   T.NumberIsSummarized
	|
	|UNION ALL
	|
	|SELECT
	|	T.Recorder,
	|	T.CorCompany,
	|	T.CorAccountingSection,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.CorLot,
	|	T.LotVendorAttributesCorr,
	|	T.CorVATActivityTypes,
	|	T.CorControllingAttributes,
	|
	|	T.NumberIsSummarized AS Count,
	|	CASE WHEN SUM(CASE WHEN T.ThisIsOutlier THEN T.NumberOfDetails ELSE 0 END) = T.NumberIsSummarized THEN TRUE ELSE FALSE END AS FullDisposal
	|FROM
	|	IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS T
	|WHERE
	|	T.NumberIsSummarized <> 0
	|	
	|GROUP BY
	|	T.Recorder,
	|	T.CorCompany,
	|	T.CorAccountingSection,
	|	T.CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute,
	|	T.CorLot,
	|	T.LotVendorAttributesCorr,
	|	T.CorVATActivityTypes,
	|	T.CorControllingAttributes,
	|   T.NumberIsSummarized
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(DocumentsStorno.ReversedDocument, T.Recorder) AS Recorder,
	|	T.Organization AS Organization,
	|	T.AccountingSection AS AccountingSection,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.VATActivityType AS VATActivityType,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.Count AS Count,
	|	Balance.Count AS CountBalance,
	|	CASE WHEN (CASE WHEN T.OfficialTypeOfMovementParish THEN -1 ELSE 1 END * T.Count) >= Balance.Count
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsReverseTransaction,
	|	CASE WHEN (CASE WHEN T.OfficialTypeOfMovementParish THEN -1 ELSE 1 END * T.Count) >= Balance.Count
	|		THEN T.Cost
	|		ELSE T.Cost - CAST(T.Count * Balance.CostInclVAT / Balance.Count AS NUMBER(31,2))
	|	END AS CostInclVAT,
	|	CASE WHEN (CASE WHEN T.OfficialTypeOfMovementParish THEN -1 ELSE 1 END * T.Count) >= Balance.Count
	|		THEN T.CostExcludingVAT
	|		ELSE T.CostExcludingVAT - CAST(T.Count * Balance.CostExcludingVAT / Balance.Count AS NUMBER(31,2))
	|	END AS CostExcludingVAT,
	|	CASE WHEN (CASE WHEN T.OfficialTypeOfMovementParish THEN -1 ELSE 1 END * T.Count) >= Balance.Count
	|		THEN T.LocalCost
	|		ELSE T.LocalCost - CAST(T.Count * Balance.LocalCost / Balance.Count AS NUMBER(31,2))
	|	END AS LocalCost,
	|	CASE WHEN (CASE WHEN T.OfficialTypeOfMovementParish THEN -1 ELSE 1 END * T.Count) >= Balance.Count
	|			THEN T.VATLocal
	|		WHEN T.LocalCost <> 0
	|			THEN T.VATLocal * (T.LocalCost - CAST(T.Count * Balance.LocalCost / Balance.Count AS NUMBER(31,2))) / T.LocalCost
	|		ELSE 0
	|	END AS VATLocal,
	|	CASE WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN (CASE WHEN T.OfficialTypeOfMovementParish THEN -1 ELSE 1 END * T.Count) >= Balance.Count
	|			THEN T.CostMan
	|		ELSE T.CostMan - CAST(T.Count * Balance.CostMan / Balance.Count AS NUMBER(31,2))
	|	END AS CostMan,
	|	CASE WHEN NOT &CompanyManagementAccounting OR T.CostMan = 0
	|			THEN 0
	|		WHEN (CASE WHEN T.OfficialTypeOfMovementParish THEN -1 ELSE 1 END * T.Count) >= Balance.Count
	|			THEN T.VATManag
	|			ELSE T.VATManag * (T.CostMan - CAST(T.Count * Balance.CostMan / Balance.Count AS NUMBER(31,2))) / T.CostMan
	|	END AS VATManag
	|INTO TTAcquisitionAdjustmentsPreliminary
	|FROM
	|	TTCacheEstimatedTurnoverOfInventoryCosts_Indexes AS T
	|	INNER JOIN TTBalancesForAdjustments AS Balance
	|		ON T.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|		AND T.Organization = Balance.Organization
	|		AND T.Lot = Balance.Lot
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.AccountingSection = Balance.AccountingSection
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND T.FinancialAccountingDimension = Balance.FinancialAccountingDimension
	|		AND T.VATActivityType = Balance.VATActivityType
	|	LEFT JOIN TTDocumentsStorno AS DocumentsStorno
	|		ON DocumentsStorno.ReversingEntry = T.Recorder
	|WHERE
	|	T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND (VALUETYPE(T.Recorder) = TYPE(Document.PurchaseAdjustment)
	|		OR VALUETYPE(T.Recorder) = TYPE(Document.ReceiptOfServicesToBusinessUnit)
	|		OR VALUETYPE(T.Recorder) = TYPE(Document.InventorySurplusRecognition)
	|		OR NOT DocumentsStorno.ReversingEntry IS NULL)
	|	AND T.EntryType IN (VALUE(Enum.LotRecordTypes.PurchaseAdjustment))
	|	AND NOT T.AccountingSection IN (
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent),
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing),
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTCacheEstimatedTurnoverOfInventoryCosts_Indexes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALSE AS TheseAreArticleByArticleExpenses,
	|	T.ThisIsReverseTransaction,
	|	CASE WHEN VALUETYPE(T.Recorder) IN(TYPE(Document.OBEntry), TYPE(Document.OBEntryGoods))
	|	  AND VALUETYPE(T.Lot) = TYPE(Document.SourceDocument)
	|		THEN T.Lot
	|		ELSE T.Recorder
	|	END AS DocumentInflow,
	|	T.LotVendorAttributes AS LotVendorAttributesOfReceiptDocument,
	|	T.ItemsLocationAttributes AS InventoryLocationAttributesOfReceiptDocument,
	|
	|	T.Organization AS Organization,
	|	T.AccountingSection AS AccountingSection,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.VATActivityType AS VATActivityType,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.Count,
	|	T.CostInclVAT,
	|	T.CostExcludingVAT,
	|	T.LocalCost,
	|	T.VATLocal,
	|	T.CostMan,
	|	T.VATManag
	|INTO TTAcquisitionAdjustments
	|FROM
	|	TTAcquisitionAdjustmentsPreliminary AS T
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE AS TheseAreArticleByArticleExpenses,
	|	T.ThisIsReverseTransaction,
	|	Balance.DocumentInflow AS DocumentInflow,
	|	Balance.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS InventoryLocationAttributesOfReceiptDocument,
	|
	|	T.Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	|
	|	Balance.ExpenseItem,
	|	Balance.DimensionOfExpenses,
	|	T.Count,
	|	CAST(-T.Count * Balance.CostInclVAT AS NUMBER(31,2)) AS CostInclVAT,
	|	CAST(-T.Count * Balance.CostExcludingVAT AS NUMBER(31,2)) AS CostExcludingVAT,
	|	CAST(-T.Count * Balance.CostExcludingVATLocal AS NUMBER(31,2)) AS LocalCost,
	|	CAST(-T.Count * Balance.VATLocal AS NUMBER(31,2)) AS VATLocal,
	|	CAST(-T.Count * Balance.CostExcludingVATMan AS NUMBER(31,2)) AS CostMan,
	|	CAST(-T.Count * Balance.VATManag AS NUMBER(31,2)) AS VATManag
	|FROM
	|	TTAcquisitionAdjustmentsPreliminary AS T
	|	INNER JOIN TT_PricesOfBatchesOfGoodsAtBeginningOfPeriod_Indices AS Balance
	|		ON T.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|		AND T.Organization = Balance.Organization
	|		AND T.Lot = Balance.Lot
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.AccountingSection = Balance.AccountingSection
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND T.FinancialAccountingDimension = Balance.FinancialAccountingDimension
	|		AND T.VATActivityType = Balance.VATActivityType
	|WHERE
	|	(Balance.TheseAreArticleByArticleVariables
	|		AND Balance.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))
	|	OR Balance.TheseAreArticleByArticleConstants
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	// Cost Analysts
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot AS Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Cor. Cost Analysis
	|	DD.LotVendorAttributesCorr,
	|	DD.CorVATActivityTypes,
	|
	// Other fields
	|	DD.Period,
	|	DD.Recorder,
	|	DD.OfficialTypeOfMovementParish,
	|	DD.EntryType,
	|	DD.BusinessOperation,
	|	DD.Department,
	|	DD.ReversingEntry,
	|	DD.ExpenseItemOfWriteOff,
	|	DD.AssetAndLiabilityItem,
	|	DD.DimensionOfExpenses,
	|	DD.AssetsLiabilitiesDimension,
	|	DD.AccountingDimensionByPartners,
	|	DD.DocumentSource,
	|	DD.FinRecordID,
	|
	// Resources
	|	DD.Count,
	|	DD.Cost,
	|	DD.CostExcludingVAT,
	|	DD.AddExpensesForGoods,
	|	DD.AdditionalExpensesExcludingVAT,
	|	DD.LocalCost,
	|	DD.AddExpensesLocal,
	|	DD.VATLocal,
	|	DD.CostMan,
	|	DD.AddExpensesMan,
	|	DD.VATManag
	|INTO TT_CacheEstimatedTurnoverOfInventoryCosts_Selection
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS DD
	|WHERE
	|	DD.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND DD.Lot <> UNDEFINED
	|   AND (DD.OfficialTypeOfMovementParish
	|		OR DD.EntryType IN (
	|			VALUE(Enum.LotRecordTypes.CostVariance),
	|			VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
	|			VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
	|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
	|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
	|			VALUE(Enum.LotRecordTypes.CostAdjustment),
	|			VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
	|		OR (DD.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|			AND VALUETYPE(DD.Recorder) = TYPE(Document.CostCalculationRecorder))
	|	  )
	// We exclude returnable waste that is not a batch (for example, written off for expenses), except for work-in-progress.
	|	AND NOT (
	|		DD.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|		AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|		AND DD.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		)
	// We exclude the production of products at the planned cost
	|	AND NOT (
	|		DD.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|		AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|		AND DD.Count <> 0
	|		AND DD.LocalCost <> 0
	|		)
	|	AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
	|	AND NOT (
	|		VALUETYPE(DD.Recorder) = TYPE(Document.BackflushProduction)
	|		AND ((DD.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|			AND DD.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost)))
	|		  OR
	|		  (DD.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)))
	|		AND DD.Count <> 0
	|		AND DD.LocalCost <> 0
	|		)
	|	AND (DD.EntryType IN (
	|		VALUE(Enum.LotRecordTypes.Lot),
	|		VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
	|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
	|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
	|		VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
	|		VALUE(Enum.LotRecordTypes.CostVariance),
	|		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
	|		VALUE(Enum.LotRecordTypes.CostAdjustment),
	|		VALUE(Enum.LotRecordTypes.Supplement))
	|		OR (DD.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
	|			AND VALUETYPE(DD.Recorder) IN (
	|				TYPE(Document.ReceiptOfGoodsToWarehouse),
	|				TYPE(Document.ReceiptOfServicesToBusinessUnit),
	|				TYPE(Document.InventorySurplusRecognition),
	|				TYPE(Document.PurchaseAdjustment)))
	|		OR DD.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|			AND DD.Count = 0
	|			AND VALUETYPE(DD.Recorder) IN(
	|				TYPE(Document.SubcontractorReport2_5))
	|		)
	|	AND DD.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	AND (DD.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|
	
	// Services for processing the processor's report 2.5
	|		OR VALUETYPE(DD.Recorder) = TYPE(Document.SubcontractorReport2_5)
	|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	// Correction of the processor's report 2.5
	|		OR VALUETYPE(DD.Recorder) = TYPE(Document.PurchaseAdjustment)
	|		  AND VALUETYPE(DD.DocumentSource) = TYPE(Document.SubcontractorReport2_5)
	|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		OR DD.OfficialTypeOfMovementParish
	|			AND DD.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost),
	|				VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
	|			)
	|		)
	|	AND NOT DD.AccountingSection IN (
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent),
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing),
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
	|	AND NOT DD.Recorder REFS Document.OBEntry
	|	AND NOT DD.Recorder REFS Document.OBEntryGoods
	|	AND VALUETYPE(DD.Recorder) <> TYPE(Document.AllocationOfOtherCosts)
	|
	|INDEX BY SETS
	|	((ItemsLocationAttributes,
	|		Organization,
	|		Lot,
	|		InventoryOwnerAttribute,
	|		AccountingSection,
	|		LotVendorAttributes,
	|		FinancialAccountingDimension,
	|		VATActivityType),
	|	(Recorder))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	|	DD.Count AS Count
	|INTO WTSelectionOfRemainingWIP
	|FROM
	|	TTCostBalancesForVATLots AS DD
	|WHERE
	|	DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|	AND VALUETYPE(DD.Lot) = TYPE(Catalog.ProductionLots)
	|	AND VALUETYPE(CAST(DD.Lot AS Catalog.ProductionLots).Document) = TYPE(Document.ProductionOrder2_2)
	|	AND DD.Count <> 0
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Organization AS Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot AS Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	|	Balance.Count AS CountBalance,
	|	SUM(DD.Count) AS CountReceipt
	|INTO WChangeInWIPBalancesPreliminary
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS DD
	|	INNER JOIN WTSelectionOfRemainingWIP AS Balance
	|		ON DD.Organization = Balance.Organization
	|		AND DD.AccountingSection = Balance.AccountingSection
	|		AND DD.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|		AND DD.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND DD.Lot = Balance.Lot
	|		AND DD.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND DD.VATActivityType = Balance.VATActivityType
	|		AND DD.FinancialAccountingDimension = Balance.FinancialAccountingDimension
	|WHERE
	|   DD.OfficialTypeOfMovementParish
	|	AND DD.Count <> 0
	|GROUP BY
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|	Balance.Count
	|
	|HAVING
	|	SUM(DD.Count) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 0
	|	DD.Organization AS Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot AS Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	|	1 AS ZoomRatio,
	|	0 AS Count
	|INTO WChangeInWIPBalances
	|FROM
	|	TTCostBalancesForVATLots AS DD
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// The coefficient by which to reduce the price of the batch in the WIP, if the WIP balance has changed in the current period (there was a receipt in the WIP)
	// This data should be placed in the details of the cost of the goods and the cost of the goods
	|	CASE WHEN DD.CountBalance + DD.CountReceipt = 0
	|		THEN -1
	|		ELSE CAST(-(1 - DD.CountBalance / (DD.CountBalance + DD.CountReceipt)) AS NUMBER(31,10))
	|	END AS ZoomRatio,
	|	DD.CountBalance + DD.CountReceipt AS Count
	|FROM
	|	WChangeInWIPBalancesPreliminary AS DD
	|WHERE
	|	DD.CountBalance + DD.CountReceipt <> 0
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	// VAT Batch Analysts
	|	Prices.DocumentInflow,
	|	Prices.LotVendorAttributesOfReceiptDocument,
	|	Prices.InventoryLocationAttributesOfReceiptDocument,
	|	
	// Cost Analysts
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Other fields
	|	Prices.ExpenseItem,
	|	Prices.DimensionOfExpenses,
	|
	// Resources
	|	SUM(CAST(CAST(Prices.CostInclVAT AS NUMBER(31,10))
	|		* CAST(RemnantsOfUnfinishedProduction.ZoomRatio + CASE WHEN Prices.TheseAreArticleByArticleVariables THEN 1 ELSE 0 END AS NUMBER(31,10)) AS NUMBER(31,10))) AS CostInclVAT,
	|	SUM(CAST(CAST(Prices.CostExcludingVAT AS NUMBER(31,10))
	|		* CAST(RemnantsOfUnfinishedProduction.ZoomRatio + CASE WHEN Prices.TheseAreArticleByArticleVariables THEN 1 ELSE 0 END AS NUMBER(31,10)) AS NUMBER(31,10))) AS CostExcludingVAT,
	|	SUM(CAST(CAST(Prices.CostExcludingVATLocal AS NUMBER(31,10))
	|		* CAST(RemnantsOfUnfinishedProduction.ZoomRatio + CASE WHEN Prices.TheseAreArticleByArticleVariables THEN 1 ELSE 0 END AS NUMBER(31,10)) AS NUMBER(31,10))) AS CostExcludingVATLocal,
	|	SUM(CAST(CAST(Prices.VATLocal AS NUMBER(31,10))
	|		* CAST(RemnantsOfUnfinishedProduction.ZoomRatio + CASE WHEN Prices.TheseAreArticleByArticleVariables THEN 1 ELSE 0 END AS NUMBER(31,10)) AS NUMBER(31,10))) AS VATLocal,
	|	SUM(CAST(CAST(Prices.CostExcludingVATMan AS NUMBER(31,10))
	|		* CAST(RemnantsOfUnfinishedProduction.ZoomRatio + CASE WHEN Prices.TheseAreArticleByArticleVariables THEN 1 ELSE 0 END AS NUMBER(31,10)) AS NUMBER(31,10))) AS CostExcludingVATMan,
	|	SUM(CAST(CAST(Prices.VATManag AS NUMBER(31,10))
	|		* CAST(RemnantsOfUnfinishedProduction.ZoomRatio + CASE WHEN Prices.TheseAreArticleByArticleVariables THEN 1 ELSE 0 END AS NUMBER(31,10)) AS NUMBER(31,10))) AS VATManag,
	|	RemnantsOfUnfinishedProduction.Count AS Count
	|INTO TTAdjustmentOfPricesOfBalancesOfUnfinishedProduction
	|FROM
	|	TTCostBalancesForVATLots AS DD
	|	INNER JOIN TTPricesOfBatchesOfGoodsAtBeginningOfPeriod AS Prices
	|		ON Prices.Organization = DD.Organization
	|		AND Prices.AccountingSection = DD.AccountingSection
	|		AND Prices.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND Prices.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|		AND Prices.Lot = DD.Lot
	|		AND Prices.LotVendorAttributes = DD.LotVendorAttributes
	|		AND Prices.VATActivityType = DD.VATActivityType
	|		AND Prices.FinancialAccountingDimension = DD.FinancialAccountingDimension
	|	INNER JOIN WChangeInWIPBalances AS RemnantsOfUnfinishedProduction
	|		ON RemnantsOfUnfinishedProduction.Organization = DD.Organization
	|		AND RemnantsOfUnfinishedProduction.AccountingSection = DD.AccountingSection
	|		AND RemnantsOfUnfinishedProduction.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND RemnantsOfUnfinishedProduction.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|		AND RemnantsOfUnfinishedProduction.Lot = DD.Lot
	|		AND RemnantsOfUnfinishedProduction.LotVendorAttributes = DD.LotVendorAttributes
	|		AND RemnantsOfUnfinishedProduction.VATActivityType = DD.VATActivityType
	|		AND RemnantsOfUnfinishedProduction.FinancialAccountingDimension = DD.FinancialAccountingDimension
	|WHERE
	|	Prices.LotQuantity > 0
	|	AND (Prices.CostInclVAT <> 0
	|		OR Prices.CostExcludingVAT <> 0
	|		OR Prices.CostExcludingVATLocal <> 0
	|		OR Prices.VATLocal <> 0
	|		OR Prices.CostExcludingVATMan <> 0
	|		OR Prices.VATManag <> 0)
	|GROUP BY
	|	Prices.DocumentInflow,
	|	Prices.LotVendorAttributesOfReceiptDocument,
	|	Prices.InventoryLocationAttributesOfReceiptDocument,
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|	Prices.ExpenseItem,
	|	Prices.DimensionOfExpenses,
	|	RemnantsOfUnfinishedProduction.Count
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS SourceCode,
	|	FALSE AS TheseAreLeftovers,
	|	FALSE AS TheseAreRemainingArticleByArticleVariables,
	|	FALSE AS TheseRemaindersAreArticleByArticleConstants,
	|	CASE WHEN DD.OfficialTypeOfMovementParish
	|		 THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	// VAT Batch Analysts
	|	DD.ItemsLocationAttributes AS InventoryLocationAttributesOfReceiptDocument,
	|	CASE
	|		WHEN NOT Adjusting.AdjustmentKind IS NULL
	|		 AND (Adjusting.AdjustmentKind <> VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|			OR DD.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment))
	|			THEN Adjusting.DocumentBasis
	|		WHEN NOT DocumentsStorno.ReversingEntry IS NULL
	|			THEN DocumentsStorno.ReversedDocument
	|		ELSE DD.Recorder
	|	END AS DocumentInflow,
	|	CASE
	|		WHEN NOT AnalysisOfAccountingOfBatchesOfAdditionalExpenses.LotVendorAttributesOfReceiptDocument IS NULL
	|			THEN AnalysisOfAccountingOfBatchesOfAdditionalExpenses.LotVendorAttributesOfReceiptDocument
	|		WHEN DD.EntryType IN (
	|				VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
	|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
	|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
	|				VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods))
	|			THEN DD.LotVendorAttributesCorr
	|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
	|		  AND DD.LotVendorAttributesCorr <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|			THEN DD.LotVendorAttributesCorr
	|		WHEN DD.EntryType IN (
	|				VALUE(Enum.LotRecordTypes.CostAdjustment),
	|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
	|		 AND DD.Count = 0
	|		 AND DD.LotVendorAttributesCorr <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|			THEN DD.LotVendorAttributesCorr
	|		WHEN DD.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|			THEN DD.LotVendorAttributesCorr
	|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.Lot) AND DD.Count = 0
	|		 AND DD.LotVendorAttributesCorr <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|			THEN DD.LotVendorAttributesCorr
	|		WHEN DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		 AND DD.LotVendorAttributesCorr <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|			THEN DD.LotVendorAttributesCorr
	|		ELSE DD.LotVendorAttributes
	|	END AS LotVendorAttributesOfReceiptDocument,
	|	
	// Cost Analysts
	|	DD.Organization AS Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot AS Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Other fields
	|	DD.Period,
	|	DD.Recorder,
	// For customs declarations with expenses for the receipt document of the previous period, in order to further establish the sign "These are variable expenses" in the TRUTH
	// The same should be done for the document Reversing the document of the previous period
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.CCDImport)
	|				AND ISNULL(PartyRegistry.IBDocumentDate, &EndOfPreviousPeriod) < &BeginOfPeriod
	|			THEN VALUE(Enum.LotRecordTypes.Estimated)
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.ReceiptOfServicesToBusinessUnit)
	|				AND ISNULL(PartyRegistry.IBDocumentDate, &EndOfPreviousPeriod) < &BeginOfPeriod
	|			THEN VALUE(Enum.LotRecordTypes.Estimated)
	|		WHEN NOT DocumentsStorno.ReversingEntry IS NULL AND DocumentsStorno.ReverseOfPreviousPeriod
	|			THEN VALUE(Enum.LotRecordTypes.Estimated)
	|		WHEN ISNULL(Retirements.FullDisposal, FALSE)
	|			THEN VALUE(Enum.LotRecordTypes.GroupedStock)
	|		ELSE DD.EntryType
	|	END AS EntryType,
	|	DD.Department,
	|	DD.ReversingEntry,
	|	CASE
	|		WHEN DD.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		 AND DD.ExpenseItemOfWriteOff <> UNDEFINED
	|		 AND DD.EntryType <> VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
	|			THEN DD.ExpenseItemOfWriteOff
	|		WHEN DD.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|		 AND DD.EntryType <> VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
	|			THEN DD.AssetAndLiabilityItem
	|		ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) END AS ExpenseItemAssets,
	|	CASE
	|		WHEN DD.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		 AND DD.ExpenseItemOfWriteOff <> UNDEFINED
	|		 AND DD.EntryType <> VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
	|			THEN DD.DimensionOfExpenses
	|		WHEN DD.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|		 AND DD.EntryType <> VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
	|			THEN DD.AssetsLiabilitiesDimension
	|		ELSE UNDEFINED END AS AssetExpenseAnalytics,
	|	FALSE AS PreviousRedistributionCosts,
	|	(CASE
	|		WHEN DD.AddExpensesLocal <> 0 THEN TRUE
	|		WHEN DD.LocalCost = 0 AND DD.VATLocal <> 0 THEN TRUE
	|		WHEN NOT DocumentsStorno.ReversingEntry IS NULL AND DocumentsStorno.ReverseOfPreviousPeriod THEN TRUE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.ReceiptOfServicesToBusinessUnit)
	|				AND ISNULL(PartyRegistry.IBDocumentDate, &EndOfPreviousPeriod) < &BeginOfPeriod
	|			THEN TRUE
	|		WHEN ISNULL(Retirements.FullDisposal, FALSE) THEN TRUE
	|		ELSE FALSE END) AS ThisIsAdditionalExpense,
	|
	// Resources
	|	SUM(DD.Cost + DD.AddExpensesForGoods) AS CostInclVAT,
	|	SUM(DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT) AS CostExcludingVAT,
	|	SUM(DD.LocalCost + DD.AddExpensesLocal
	|		+ CASE
	|			WHEN DD.LocalCost + DD.AddExpensesLocal = 0
	|				THEN 0
	|			WHEN DD.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN -DD.VATLocal
	|			WHEN DD.Recorder REFS Document.CCDImport
	|			 AND DD.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN -DD.VATLocal
	|			ELSE 0
	|	END) AS CostExcludingVATLocal,
	|	SUM(DD.VATLocal) AS VATLocal,
	|	SUM(CASE WHEN &CompanyManagementAccounting
	|		THEN DD.CostMan + DD.AddExpensesMan
	|		+ CASE
	|			WHEN DD.CostMan + DD.AddExpensesMan = 0
	|				THEN 0
	|			WHEN DD.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN -DD.VATManag
	|			WHEN DD.Recorder REFS Document.CCDImport
	|			 AND DD.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN -DD.VATLocal
	|			ELSE 0
	|			END
	|		ELSE 0
	|	END) AS CostExcludingVATMan,
	|	SUM(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN DD.VATManag
	|		ELSE 0
	|	END) AS VATManag,
	|	SUM(CASE WHEN ISNULL(Retirements.FullDisposal, FALSE) THEN Retirements.Count ELSE DD.Count END) AS Count
	|
	|INTO GoodsReceiptsVAT2_4
	|FROM
	|	TT_CacheEstimatedTurnoverOfInventoryCosts_Selection AS DD
	|	LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS AnalysisOfCalculations
	|		ON AnalysisOfCalculations.Ref = DD.AccountingDimensionByPartners
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON Contracts.Ref = AnalysisOfCalculations.Contract
	|	LEFT JOIN Document.PurchaseAdjustment AS Adjusting
	|		ON Adjusting.Ref = DD.Recorder
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Register3.Ref = DD.DocumentSource
	|		AND NOT Register3.AdditionalRecord
	|		AND Register3.Ref <> UNDEFINED
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS PartyRegistry
	|		ON PartyRegistry.Ref = DD.Lot
	|		AND NOT PartyRegistry.AdditionalRecord
	|		AND PartyRegistry.Ref <> UNDEFINED
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS RegistryAdjustment
	|		ON RegistryAdjustment.Ref = Adjusting.DocumentBasis
	|		AND NOT RegistryAdjustment.AdditionalRecord
	|		AND RegistryAdjustment.Ref <> UNDEFINED
	|		AND NOT Adjusting.Ref IS NULL
	|	LEFT JOIN TTBalancesForAdjustments AS Balance
	|		ON DD.Organization = Balance.Organization
	|		AND DD.AccountingSection = Balance.AccountingSection
	|		AND DD.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|		AND DD.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND DD.Lot = Balance.Lot
	|		AND DD.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND DD.VATActivityType = Balance.VATActivityType
	|		AND DD.FinancialAccountingDimension = Balance.FinancialAccountingDimension
	|	LEFT JOIN CompletelyRetiredGoodsTT AS Retirements
	|		ON DD.Organization = Retirements.Organization
	|		AND DD.AccountingSection = Retirements.AccountingSection
	|		AND DD.ItemsLocationAttributes = Retirements.ItemsLocationAttributes
	|		AND DD.InventoryOwnerAttribute = Retirements.InventoryOwnerAttribute
	|		AND DD.Lot = Retirements.Lot
	|		AND DD.LotVendorAttributes = Retirements.LotVendorAttributes
	|		AND DD.VATActivityType = Retirements.VATActivityType
	|		AND DD.FinancialAccountingDimension = Retirements.FinancialAccountingDimension
	|		AND DD.Recorder = Retirements.Recorder
	|	LEFT JOIN TTDocumentsStorno AS DocumentsStorno
	|		ON DocumentsStorno.ReversingEntry = DD.Recorder
	|	LEFT JOIN TTAnalyticsOfAccountingOfBatchesOfAdditionalExpenses AS AnalysisOfAccountingOfBatchesOfAdditionalExpenses
	|		ON AnalysisOfAccountingOfBatchesOfAdditionalExpenses.Recorder = DD.Recorder
	|		AND AnalysisOfAccountingOfBatchesOfAdditionalExpenses.FinRecordID = DD.FinRecordID
	|WHERE
	// We exclude the cumulative adjustment of the acquisition if the corrected document refers to a period with batch accounting turned off.
	|	NOT (
	|		DD.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
	|		AND DD.OfficialTypeOfMovementParish
	|		AND DD.Count = 0
	|		AND ISNULL(Register3.IBDocumentDate, RegistryAdjustment.IBDocumentDate) < &DateOfMigrationToBatchAccounting22
	|		AND &BatchAccountingWasUsedBeforeSwitchingToVersion22 = FALSE)
	// We exclude the data included in the table in the correction and acquisition table.
	|	AND NOT ((VALUETYPE(DD.Recorder) = TYPE(Document.PurchaseAdjustment)
	|			OR VALUETYPE(DD.Recorder) = TYPE(Document.ReceiptOfServicesToBusinessUnit)
	|			OR NOT DocumentsStorno.ReversingEntry IS NULL)
	|		AND DD.EntryType IN (VALUE(Enum.LotRecordTypes.PurchaseAdjustment))
	|		AND NOT Balance.Organization IS NULL)
	// We exclude complete disposals of goods
	|	AND (ISNULL(Retirements.FullDisposal, FALSE) AND DD.OfficialTypeOfMovementParish
	|		OR NOT ISNULL(Retirements.FullDisposal, FALSE))
	|GROUP BY
	|	CASE WHEN DD.OfficialTypeOfMovementParish
	|		 THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END,
	|	CASE
	|		WHEN NOT AnalysisOfAccountingOfBatchesOfAdditionalExpenses.LotVendorAttributesOfReceiptDocument IS NULL
	|			THEN AnalysisOfAccountingOfBatchesOfAdditionalExpenses.LotVendorAttributesOfReceiptDocument
	|		WHEN DD.EntryType IN (
	|				VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
	|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
	|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
	|				VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods))
	|			THEN DD.LotVendorAttributesCorr
	|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
	|		  AND DD.LotVendorAttributesCorr <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|			THEN DD.LotVendorAttributesCorr
	|		WHEN DD.EntryType IN (
	|				VALUE(Enum.LotRecordTypes.CostAdjustment),
	|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
	|		 AND DD.Count = 0
	|		 AND DD.LotVendorAttributesCorr <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|			THEN DD.LotVendorAttributesCorr
	|		WHEN DD.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|			THEN DD.LotVendorAttributesCorr
	|		WHEN DD.EntryType = VALUE(Enum.LotRecordTypes.Lot) AND DD.Count = 0
	|		 AND DD.LotVendorAttributesCorr <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|			THEN DD.LotVendorAttributesCorr
	|		WHEN DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		 AND DD.LotVendorAttributesCorr <> VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|			THEN DD.LotVendorAttributesCorr
	|		ELSE DD.LotVendorAttributes
	|	END,
	|	CASE
	|		WHEN NOT Adjusting.AdjustmentKind IS NULL
	|		 AND (Adjusting.AdjustmentKind <> VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|			OR DD.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment))
	|			THEN Adjusting.DocumentBasis
	|		WHEN NOT DocumentsStorno.ReversingEntry IS NULL
	|			THEN DocumentsStorno.ReversedDocument
	|		ELSE DD.Recorder
	|	END,
	|	
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|	DD.Period,
	|	DD.Recorder,
	|	DD.Department,
	|	DD.ReversingEntry,
	|	CASE
	|		WHEN DD.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		 AND DD.ExpenseItemOfWriteOff <> UNDEFINED
	|		 AND DD.EntryType <> VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
	|			THEN DD.ExpenseItemOfWriteOff
	|		WHEN DD.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|		 AND DD.EntryType <> VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
	|			THEN DD.AssetAndLiabilityItem
	|		ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) END,
	|	CASE
	|		WHEN DD.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		 AND DD.ExpenseItemOfWriteOff <> UNDEFINED
	|		 AND DD.EntryType <> VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
	|			THEN DD.DimensionOfExpenses
	|		WHEN DD.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|		 AND DD.EntryType <> VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
	|			THEN DD.AssetsLiabilitiesDimension
	|		ELSE UNDEFINED END,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.CCDImport)
	|				AND ISNULL(PartyRegistry.IBDocumentDate, &EndOfPreviousPeriod) < &BeginOfPeriod
	|			THEN VALUE(Enum.LotRecordTypes.Estimated)
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.ReceiptOfServicesToBusinessUnit)
	|				AND ISNULL(PartyRegistry.IBDocumentDate, &EndOfPreviousPeriod) < &BeginOfPeriod
	|			THEN VALUE(Enum.LotRecordTypes.Estimated)
	|		WHEN NOT DocumentsStorno.ReversingEntry IS NULL AND DocumentsStorno.ReverseOfPreviousPeriod
	|			THEN VALUE(Enum.LotRecordTypes.Estimated)
	|		WHEN ISNULL(Retirements.FullDisposal, FALSE)
	|			THEN VALUE(Enum.LotRecordTypes.GroupedStock)
	|		ELSE DD.EntryType
	|	END, // EntryType
	|	(CASE
	|		WHEN DD.AddExpensesLocal <> 0 THEN TRUE
	|		WHEN DD.LocalCost = 0 AND DD.VATLocal <> 0 THEN TRUE
	|		WHEN NOT DocumentsStorno.ReversingEntry IS NULL AND DocumentsStorno.ReverseOfPreviousPeriod THEN TRUE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.ReceiptOfServicesToBusinessUnit)
	|				AND ISNULL(PartyRegistry.IBDocumentDate, &EndOfPreviousPeriod) < &BeginOfPeriod
	|			THEN TRUE
	|		WHEN ISNULL(Retirements.FullDisposal, FALSE) THEN TRUE
	|		ELSE FALSE END) // HOW ARE THESE EXPENSES
	|
	|
	|UNION ALL
	|
	// Cost balances at the prices of the new register
	|SELECT
	|	3 AS SourceCode,
	|	TRUE AS TheseAreLeftovers,
	|	Prices.TheseAreArticleByArticleVariables AS TheseAreRemainingArticleByArticleVariables,
	|	Prices.TheseAreArticleByArticleConstants AS TheseRemaindersAreArticleByArticleConstants,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	// VAT Batch Analysts
	|	Prices.InventoryLocationAttributesOfReceiptDocument,
	|	Prices.DocumentInflow,
	|	Prices.LotVendorAttributesOfReceiptDocument,
	|	
	// Cost Analysts
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Other fields
	|	&BeginOfPeriod,
	|	UNDEFINED,
	|	VALUE(Enum.LotRecordTypes.Previous) AS EntryType,
	|	UNDEFINED,
	|	FALSE AS ReversingEntry,
	|	Prices.ExpenseItem AS ExpenseItemAssets,
	|	Prices.DimensionOfExpenses AS AssetExpenseAnalytics,
	|	Prices.PreviousRedistributionCosts,
	|	Prices.TheseAreArticleByArticleVariables OR Prices.TheseAreArticleByArticleConstants AS ThisIsAdditionalExpense,
	|
	// Resources
	|	CAST(Prices.CostInclVAT * (DD.Count + ISNULL(AdjustingEntries.Count, 0)) AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(Prices.CostExcludingVAT * (DD.Count + ISNULL(AdjustingEntries.Count, 0)) AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(Prices.CostExcludingVATLocal * (DD.Count + ISNULL(AdjustingEntries.Count, 0)) AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(Prices.VATLocal * (DD.Count + ISNULL(AdjustingEntries.Count, 0)) AS NUMBER(31,10)) AS VATLocal,
	|	CAST(Prices.CostExcludingVATMan * (DD.Count + ISNULL(AdjustingEntries.Count, 0)) AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(Prices.VATManag * (DD.Count + ISNULL(AdjustingEntries.Count, 0)) AS NUMBER(31,10)) AS VATManag,
	|	DD.Count + ISNULL(AdjustingEntries.Count, 0) AS Count
	|FROM
	|	TTCostBalancesForVATLots AS DD
	|	INNER JOIN TT_PricesOfBatchesOfGoodsAtBeginningOfPeriod_Indices AS Prices
	|		ON Prices.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND Prices.Organization = DD.Organization
	|		AND Prices.Lot = DD.Lot
	|		AND Prices.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|		AND Prices.AccountingSection = DD.AccountingSection
	|		AND Prices.LotVendorAttributes = DD.LotVendorAttributes
	|		AND Prices.FinancialAccountingDimension = DD.FinancialAccountingDimension
	|		AND Prices.VATActivityType = DD.VATActivityType
	|	LEFT JOIN TTAcquisitionAdjustments AS AdjustingEntries
	|		ON AdjustingEntries.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND AdjustingEntries.Organization = DD.Organization
	|		AND AdjustingEntries.Lot = DD.Lot
	|		AND AdjustingEntries.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|		AND AdjustingEntries.AccountingSection = DD.AccountingSection
	|		AND AdjustingEntries.LotVendorAttributes = DD.LotVendorAttributes
	|		AND AdjustingEntries.FinancialAccountingDimension = DD.FinancialAccountingDimension
	|		AND AdjustingEntries.VATActivityType = DD.VATActivityType
	|		AND NOT AdjustingEntries.TheseAreArticleByArticleExpenses
	|WHERE
	|	Prices.LotQuantity > 0
	|	AND (Prices.CostInclVAT <> 0
	|		OR Prices.CostExcludingVAT <> 0
	|		OR Prices.CostExcludingVATLocal <> 0
	|		OR Prices.VATLocal <> 0
	|		OR Prices.CostExcludingVATMan <> 0
	|		OR Prices.VATManag <> 0)
	|
	|UNION ALL
	|
	// Returns of implementations of past periods (based on data from old registers or material from a new register)
	|SELECT
	|	4 AS SourceCode,
	|	TRUE AS TheseAreLeftovers,
	|	FALSE AS TheseAreRemainingArticleByArticleVariables,
	|	FALSE AS TheseRemaindersAreArticleByArticleConstants,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	// VAT Batch Analysts
	|	T.InventoryLocationAttributesOfReceiptDocument,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	
	// Cost Analysts
	|	T.Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	|
	// Other fields
	|	T.Period,
	|	T.Recorder,
	|	T.EntryType,
	|	T.Department,
	|	T.ReversingEntry,
	|	T.ExpenseItemAssets,
	|	T.AssetExpenseAnalytics,
	|	T.PreviousRedistributionCosts,
	|	FALSE AS ThisIsAdditionalExpense,
	|
	// Resources
	|	CAST(T.CostInclVAT * T.Count AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(T.CostExcludingVAT * T.Count AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(T.CostExcludingVATLocal * T.Count AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(T.VATLocal * T.Count AS NUMBER(31,10)) AS VATLocal,
	|	CAST(T.CostExcludingVATMan * T.Count AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(T.VATManag * T.Count AS NUMBER(31,10)) AS VATManag,
	|	T.Count AS Count
	|FROM
	|	TUEBatchPricesVATRefunds AS T
	|	INNER JOIN SourcesOfRefundPrices AS Returns
	|		ON T.RecNo = Returns.RecNo
	|		AND T.SourceNumber = Returns.SourceNumber
	|WHERE
	|	T.CostInclVAT <> 0
	|		OR T.CostExcludingVAT <> 0
	|		OR T.CostExcludingVATLocal <> 0
	|		OR T.VATLocal <> 0
	|		OR T.CostExcludingVATMan <> 0
	|		OR T.VATManag <> 0
	|
	|UNION ALL
	|
	// Provisions for impairment
	|SELECT
	|	5 AS SourceCode,
	|	FALSE AS TheseAreLeftovers,
	|	FALSE AS TheseAreRemainingArticleByArticleVariables,
	|	FALSE AS TheseRemaindersAreArticleByArticleConstants,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	// VAT Batch Analysts
	|	AdjustmentNodes.ItemsLocationAttributes AS InventoryLocationAttributesOfReceiptDocument,
	|	UNDEFINED AS DocumentInflow,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesOfReceiptDocument,
	|	
	// Cost Analysts
	|	AdjustmentNodes.Organization,
	|	AdjustmentNodes.AccountingSection,
	|	AdjustmentNodes.ItemsLocationAttributes,
	|	AdjustmentNodes.InventoryOwnerAttribute,
	|	AdjustmentNodes.Lot,
	|	AdjustmentNodes.LotVendorAttributes,
	|	AdjustmentNodes.VATActivityType,
	|	AdjustmentNodes.FinancialAccountingDimension,
	|
	// Other fields
	|	&BeginOfPeriod AS Period,
	|	UNDEFINED AS Recorder,
	|	VALUE(Enum.LotRecordTypes.Estimated) AS EntryType,
	|	UNDEFINED AS Department,
	|	FALSE AS ReversingEntry,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemAssets,
	|	UNDEFINED AS AssetExpenseAnalytics,
	|	FALSE AS PreviousRedistributionCosts,
	|	TRUE AS ThisIsAdditionalExpense,
	// Resources
	|	0 					AS CostInclVAT,
	|	0 					AS CostExcludingVAT,
	|	CAST(Costs_2.ProvisionForImpairmentLocal * ReserveConnections.ArcWeight AS NUMBER(31,2)) AS CostExcludingVATLocal,
	|	0  					AS VATLocal,
	|	CAST(Costs_2.ProvisionForImpairmentMan * ReserveConnections.ArcWeight AS NUMBER(31,2))  AS CostExcludingVATMan,
	|	0  					AS VATManag,
	|	1 					AS Count
	|FROM
	|	ConnectionsOfNodesOfReservesUnderImpairmentOfStocks AS ReserveConnections
	|		INNER JOIN TTAdjustmentNodes AS AdjustmentNodes
	|		ON ReserveConnections.ReceiverNodeNumber = AdjustmentNodes.NodeNumber
	|		INNER JOIN TTValueOfBatchesOfGoods AS Costs_2
	|		ON ReserveConnections.SourceNodeNumber = Costs_2.NodeNumber
	|WHERE
	|	NOT ReserveConnections.TransferReserve
	|
	|UNION ALL
	|
	// Enter the remnants of the goods
	|SELECT
	|	6 AS SourceCode,
	|	FALSE AS TheseAreLeftovers,
	|	FALSE AS TheseAreRemainingArticleByArticleVariables,
	|	FALSE AS TheseRemaindersAreArticleByArticleConstants,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	// VAT Batch Analysts
	|	DD.ItemsLocationAttributes AS InventoryLocationAttributesOfReceiptDocument,
	|	DD.DocumentInflow,
	|	DD.AnalysisOfReceiptDocumentAccounting AS LotVendorAttributesOfReceiptDocument,
	|	
	// Cost Analysts
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Other fields
	|	&BeginOfPeriod AS Period,
	|	UNDEFINED AS Recorder,
	|	CASE WHEN DD.TheseAreVariableAdditionalCosts
	|		THEN VALUE(Enum.LotRecordTypes.Estimated)
	|		ELSE UNDEFINED
	|	END AS EntryType,
	|	UNDEFINED AS Department,
	|	FALSE AS ReversingEntry,
	|	ISNULL(DD.ExpenseItemAssets, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) AS ExpenseItemAssets,
	|	UNDEFINED AS AssetExpenseAnalytics,
	|	FALSE AS PreviousRedistributionCosts,
	|	DD.TheseAreVariableAdditionalCosts AS ThisIsAdditionalExpense,
	|
	// Resources
	|	CASE WHEN &CompanyManagementAccounting
	|		THEN CASE
	|				WHEN DD.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN DD.CostExcludingVATMan
	|				ELSE DD.CostExcludingVATMan + DD.VATManag
	|			  END
	|		ELSE 0
	|	END 					AS CostInclVAT,
	|	CASE WHEN &CompanyManagementAccounting
	|		THEN DD.CostExcludingVATMan
	|		ELSE 0
	|	END 					AS CostExcludingVAT,
	|	DD.CostExcludingVAT  	AS CostExcludingVATLocal,
	|	DD.VAT  				AS VATLocal,
	|	DD.CostExcludingVATMan  	AS CostExcludingVATMan,
	|	DD.VATManag  				AS VATManag,
	|	CASE WHEN DD.Count = 0 THEN 1 ELSE DD.Count END AS Count
	|FROM
	|	TTRegisteredRecordsOfEnteringBalances AS DD
	|WHERE
	|	(DD.CostExcludingVAT <> 0
	|		OR DD.VAT <> 0
	|		OR DD.CostExcludingVATMan <> 0
	|		OR DD.VATManag <> 0)
	|
	|UNION ALL
	|
	// Adjustment of the cost of low-value MC
	|SELECT
	|	7 AS SourceCode,
	|	FALSE AS TheseAreLeftovers,
	|	FALSE AS TheseAreRemainingArticleByArticleVariables,
	|	FALSE AS TheseRemaindersAreArticleByArticleConstants,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	// VAT Batch Analysts
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS InventoryLocationAttributesOfReceiptDocument,
	|	Prices.DocumentInflow,
	|	Prices.LotVendorAttributesOfReceiptDocument,
	|	
	// Cost Analysts
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Other fields
	|	&BeginOfPeriod,
	|	UNDEFINED,
	|	VALUE(Enum.LotRecordTypes.Estimated),
	|	UNDEFINED,
	|	FALSE AS ReversingEntry,
	|	Prices.ExpenseItem AS ExpenseItemAssets,
	|	Prices.DimensionOfExpenses AS AssetExpenseAnalytics,
	|	FALSE AS PreviousRedistributionCosts,
	|	TRUE AS ThisIsAdditionalExpense,
	|
	// Resources
	|	0 AS CostInclVAT,
	|	0 AS CostExcludingVAT,
	|	CAST(-Prices.CostExcludingVATLocal * DD.Count AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	0 AS VATLocal,
	|	CAST(-Prices.CostExcludingVATMan * DD.Count AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	0 AS VATManag,
	|	DD.Count AS Count
	|FROM
	|	TTCostBalancesForVATLots AS DD
	|	INNER JOIN TUEPricesOfLotsOfGoodsWriteOffOfMC AS Prices
	|		ON Prices.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND Prices.Organization = DD.Organization
	|		AND Prices.Lot = DD.Lot
	|		AND Prices.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|		AND Prices.AccountingSection = DD.AccountingSection
	|		AND Prices.LotVendorAttributes = DD.LotVendorAttributes
	|		AND Prices.FinancialAccountingDimension = DD.FinancialAccountingDimension
	|		AND Prices.VATActivityType = DD.VATActivityType
	|
	|
	|UNION ALL
	|
	// Purchase adjustments - deviation from the old value
	|SELECT
	|	8 AS SourceCode,
	|	TRUE AS TheseAreLeftovers,
	|	TRUE AS TheseAreRemainingArticleByArticleVariables,
	|	FALSE AS TheseRemaindersAreArticleByArticleConstants,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	// VAT Batch Analysts
	|	T.InventoryLocationAttributesOfReceiptDocument AS InventoryLocationAttributesOfReceiptDocument,
	|	T.DocumentInflow AS DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	
	// Cost Analysts
	|	T.Organization,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.FinancialAccountingDimension,
	|
	// Other fields
	|	&BeginOfPeriod,
	|	UNDEFINED,
	|	CASE WHEN T.ThisIsReverseTransaction
	|		THEN VALUE(Enum.LotRecordTypes.Balance)
	|		ELSE VALUE(Enum.LotRecordTypes.Estimated)
	|	END AS EntryType,
	|	UNDEFINED,
	|	FALSE AS ReversingEntry,
	|	T.ExpenseItemOfWriteOff AS ExpenseItemAssets,
	|	T.DimensionOfExpenses AS AssetExpenseAnalytics,
	|	FALSE AS PreviousRedistributionCosts,
	|	TRUE AS ThisIsAdditionalExpense,
	|
	// Resources
	|	CAST(T.CostInclVAT / CASE WHEN T.ThisIsReverseTransaction THEN -T.Count ELSE 1 END AS NUMBER (31,2)) AS CostInclVAT,
	|	CAST(T.CostExcludingVAT / CASE WHEN T.ThisIsReverseTransaction THEN -T.Count ELSE 1 END AS NUMBER (31,2)) AS CostExcludingVAT,
	|	CAST((T.LocalCost
	|			+ CASE
	|				WHEN NOT T.TheseAreArticleByArticleExpenses AND T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|					THEN -T.VATLocal
	|				ELSE 0
	|			  END) / CASE WHEN T.ThisIsReverseTransaction THEN -T.Count ELSE 1 END
	|		AS NUMBER (31,2)) AS CostExcludingVATLocal,
	|	CAST(T.VATLocal / CASE WHEN T.ThisIsReverseTransaction THEN -T.Count ELSE 1 END AS NUMBER (31,2)) AS VATLocal,
	|	CAST((T.CostMan
	|			+ CASE
	|				WHEN NOT T.TheseAreArticleByArticleExpenses AND T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|					THEN -T.VATManag
	|				ELSE 0
	|			  END) / CASE WHEN T.ThisIsReverseTransaction THEN -T.Count ELSE 1 END
	|		AS NUMBER (31,2)) AS CostExcludingVATMan,
	|	CAST(T.VATManag / CASE WHEN T.ThisIsReverseTransaction THEN -T.Count ELSE 1 END AS NUMBER (31,2)) AS VATManag,
	|	T.Count AS Count
	|FROM
	|	TTAcquisitionAdjustments AS T
	|WHERE
	|	T.CostInclVAT <> 0
	|	OR T.CostExcludingVAT <> 0
	|	OR T.LocalCost <> 0
	|	OR T.VATLocal <> 0
	|	OR T.CostMan <> 0
	|	OR T.VATManag <> 0
	|
	|UNION ALL
	|
	// Refunds of past period implementations
	|SELECT
	|	9 AS SourceCode,
	|	TRUE AS TheseAreLeftovers,
	|	Prices.TheseAreArticleByArticleVariables AS TheseAreRemainingArticleByArticleVariables,
	|	Prices.TheseAreArticleByArticleConstants AS TheseRemaindersAreArticleByArticleConstants,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	// VAT Batch Analysts
	|	Prices.InventoryLocationAttributesOfReceiptDocument,
	|	Prices.DocumentInflow,
	|	Prices.LotVendorAttributesOfReceiptDocument,
	|	
	// Cost Analysts
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Other fields
	|	&BeginOfPeriod,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	FALSE AS ReversingEntry,
	|	Prices.ExpenseItem AS ExpenseItemAssets,
	|	Prices.DimensionOfExpenses AS AssetExpenseAnalytics,
	|	Prices.PreviousRedistributionCosts AS PreviousRedistributionCosts,
	|	Prices.TheseAreArticleByArticleVariables OR Prices.TheseAreArticleByArticleConstants AS ThisIsAdditionalExpense,
	|
	// Resources
	|	CAST(Prices.CostInclVAT * DD.Count AS NUMBER(31,10)) AS CostInclVAT,
	|	CAST(Prices.CostExcludingVAT * DD.Count AS NUMBER(31,10)) AS CostExcludingVAT,
	|	CAST(Prices.CostExcludingVATLocal * DD.Count AS NUMBER(31,10)) AS CostExcludingVATLocal,
	|	CAST(Prices.VATLocal * DD.Count AS NUMBER(31,10)) AS VATLocal,
	|	CAST(Prices.CostExcludingVATMan * DD.Count AS NUMBER(31,10)) AS CostExcludingVATMan,
	|	CAST(Prices.VATManag * DD.Count AS NUMBER(31,10)) AS VATManag,
	|	DD.Count AS Count
	|FROM
	|	TT_ReturnsOfPreviousPeriods_Indexes AS DD
	|	INNER JOIN TTPricesOfBatchesOfGoodsAtBeginningOfPeriod AS Prices
	|		ON Prices.Period = DD.SalePeriod
	|		AND Prices.ItemsLocationAttributes = DD.CorItemsLocationAttributes
	|		AND Prices.Organization = DD.Organization
	|		AND Prices.Lot = DD.CorLot
	|		AND Prices.InventoryOwnerAttribute = DD.CorInventoryOwnerAttribute
	|		AND Prices.AccountingSection = DD.AccountingSection
	|		AND Prices.LotVendorAttributes = DD.LotVendorAttributesCorr
	|		AND Prices.FinancialAccountingDimension = DD.CorControllingAttributes
	|
	|INDEX BY
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_ReturnsOfPreviousPeriods_Indexes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_PricesOfBatchesOfGoodsAtBeginningOfPeriod_Indices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_CacheEstimatedTurnoverOfInventoryCosts_Selection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.TheseAreLeftovers,
	|	DD.TheseAreRemainingArticleByArticleVariables,
	|	DD.TheseRemaindersAreArticleByArticleConstants,
	// VAT Batch Analysts
	|	DD.InventoryLocationAttributesOfReceiptDocument,
	|	DD.DocumentInflow,
	|	DD.LotVendorAttributesOfReceiptDocument,
	|	DD.PreviousRedistributionCosts,
	|	DD.ThisIsAdditionalExpense,
	|	DD.TheseAreVariableAdditionalCosts,
	|	
	// Cost Analysts
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Other fields
	|	DD.ExpenseItemAssets AS ExpenseItem,
	|	DD.AssetExpenseAnalytics AS DimensionOfExpenses,
	|
	// Resources
	|	CASE WHEN DD.CostInclVAT < 0 THEN -1 ELSE 1 END AS SignCostWithVAT,
	|	CASE WHEN DD.CostExcludingVAT < 0 THEN -1 ELSE 1 END AS SignCostWithoutVAT,
	|	CASE WHEN DD.CostExcludingVATLocal < 0 THEN -1 ELSE 1 END AS SignValueWithoutVATLocal,
	|	CASE WHEN DD.VATLocal < 0 THEN -1 ELSE 1 END AS LocalVATSign,
	|	CASE WHEN DD.CostExcludingVATMan < 0 THEN -1 ELSE 1 END AS SignCostWithoutVATMan,
	|	CASE WHEN DD.VATManag < 0 THEN -1 ELSE 1 END AS VATSignMan,
	|
	|	CASE WHEN DD.CostInclVAT < 0 THEN -DD.CostInclVAT ELSE DD.CostInclVAT END AS CostInclVAT,
	|	CASE WHEN DD.CostExcludingVAT < 0 THEN -DD.CostExcludingVAT ELSE DD.CostExcludingVAT END AS CostExcludingVAT,
	|	CASE WHEN DD.CostExcludingVATLocal < 0 THEN -DD.CostExcludingVATLocal ELSE DD.CostExcludingVATLocal END AS CostExcludingVATLocal,
	|	CASE WHEN DD.VATLocal < 0 THEN -DD.VATLocal ELSE DD.VATLocal END AS VATLocal,
	|	CASE WHEN DD.CostExcludingVATMan < 0 THEN -DD.CostExcludingVATMan ELSE DD.CostExcludingVATMan END AS CostExcludingVATMan,
	|	CASE WHEN DD.VATManag < 0 THEN -DD.VATManag ELSE DD.VATManag END AS VATManag
	|INTO ArrivalsOfGoodsNDS2_4_ForSolvingCase
	|FROM
	|(SELECT
	|	DD.TheseAreLeftovers,
	|	DD.TheseAreRemainingArticleByArticleVariables,
	|	DD.TheseRemaindersAreArticleByArticleConstants,
	// VAT Batch Analysts
	|	DD.InventoryLocationAttributesOfReceiptDocument,
	|	CASE WHEN VALUETYPE(DD.DocumentInflow) IN (&TypesOfBatchDocuments)
	|		THEN DD.DocumentInflow
	|		ELSE UNDEFINED
	|	END AS DocumentInflow,
	|	CASE WHEN VALUETYPE(DD.DocumentInflow) IN (&TypesOfBatchDocuments)
	|		THEN DD.LotVendorAttributesOfReceiptDocument
	|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|	END AS LotVendorAttributesOfReceiptDocument,
	|	CASE WHEN VALUETYPE(DD.ExpenseItemAssets) <> TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|		THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		ELSE DD.ExpenseItemAssets
	|	END AS ExpenseItemAssets,
	|	CASE WHEN VALUETYPE(DD.ExpenseItemAssets) <> TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|		THEN UNDEFINED
	|		ELSE DD.AssetExpenseAnalytics
	|	END AS AssetExpenseAnalytics,
	|	DD.PreviousRedistributionCosts,
	|	DD.ThisIsAdditionalExpense,
	|	CASE WHEN DD.ThisIsAdditionalExpense
	|	 AND DD.EntryType IN
	|	  (VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
	|	   VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
	|	   VALUE(Enum.LotRecordTypes.Estimated))
	|			THEN TRUE
	|		WHEN DD.ThisIsAdditionalExpense
	|	 	AND DD.EntryType <> VALUE(Enum.LotRecordTypes.Previous)
	|		 AND VALUETYPE(DD.DocumentInflow) IN (&TypesOfBatchDocuments)
	|		 AND ISNULL(Register3.IBDocumentDate, &BeginOfPeriod) < &BeginOfPeriod
	|			THEN TRUE
	|		WHEN DD.ThisIsAdditionalExpense
	|		 AND DD.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|		 AND VALUETYPE(DD.Recorder) = TYPE(Document.CostCalculationRecorder)
	|			THEN TRUE
	|			ELSE FALSE
	|	END AS TheseAreVariableAdditionalCosts,
	|	
	// Cost Analysts
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension,
	|
	// Resources
	|	SUM(DD.CostInclVAT * CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) THEN -1 ELSE 1 END) AS CostInclVAT,
	|	SUM(DD.CostExcludingVAT * CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) THEN -1 ELSE 1 END) AS CostExcludingVAT,
	|	SUM(DD.CostExcludingVATLocal * CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) THEN -1 ELSE 1 END) AS CostExcludingVATLocal,
	|	SUM(DD.VATLocal * CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) THEN -1 ELSE 1 END) AS VATLocal,
	|	SUM(DD.CostExcludingVATMan * CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) THEN -1 ELSE 1 END) AS CostExcludingVATMan,
	|	SUM(DD.VATManag * CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) THEN -1 ELSE 1 END) AS VATManag
	|FROM
	|	GoodsReceiptsVAT2_4 AS DD
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Register3.Ref = DD.DocumentInflow
	|		AND NOT Register3.AdditionalRecord
	|		AND Register3.Ref <> UNDEFINED
	|WHERE
	|	DD.EntryType <> VALUE(Enum.LotRecordTypes.WIPStock)
	|	AND DD.EntryType <> VALUE(Enum.LotRecordTypes.Balance)
	|	AND DD.EntryType <> VALUE(Enum.LotRecordTypes.GroupedStock)
	|GROUP BY
	|	DD.TheseAreLeftovers,
	|	DD.TheseAreRemainingArticleByArticleVariables,
	|	DD.TheseRemaindersAreArticleByArticleConstants,
	|	DD.InventoryLocationAttributesOfReceiptDocument,
	|	CASE WHEN VALUETYPE(DD.DocumentInflow) IN (&TypesOfBatchDocuments)
	|		THEN DD.DocumentInflow
	|		ELSE UNDEFINED
	|	END,
	|	CASE WHEN VALUETYPE(DD.DocumentInflow) IN (&TypesOfBatchDocuments)
	|		THEN DD.LotVendorAttributesOfReceiptDocument
	|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|	END,
	|	CASE WHEN VALUETYPE(DD.ExpenseItemAssets) <> TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|		THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		ELSE DD.ExpenseItemAssets
	|	END,
	|	CASE WHEN VALUETYPE(DD.ExpenseItemAssets) <> TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|		THEN UNDEFINED
	|		ELSE DD.AssetExpenseAnalytics
	|	END,
	|	DD.PreviousRedistributionCosts,
	|	DD.ThisIsAdditionalExpense,
	|	CASE WHEN DD.ThisIsAdditionalExpense
	|	 AND DD.EntryType IN
	|	  (VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
	|	   VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
	|	   VALUE(Enum.LotRecordTypes.Estimated))
	|			THEN TRUE
	|		WHEN DD.ThisIsAdditionalExpense
	|	 	AND DD.EntryType <> VALUE(Enum.LotRecordTypes.Previous)
	|		 AND VALUETYPE(DD.DocumentInflow) IN (&TypesOfBatchDocuments)
	|		 AND ISNULL(Register3.IBDocumentDate, &BeginOfPeriod) < &BeginOfPeriod
	|			THEN TRUE
	|		WHEN DD.ThisIsAdditionalExpense
	|		 AND DD.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|		 AND VALUETYPE(DD.Recorder) = TYPE(Document.CostCalculationRecorder)
	|			THEN TRUE
	|			ELSE FALSE
	|	END,
	|	DD.Organization,
	|	DD.AccountingSection,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.VATActivityType,
	|	DD.FinancialAccountingDimension
	|) AS DD
	|WHERE
	|	DD.CostInclVAT <> 0
	|	OR DD.CostExcludingVAT <> 0
	|	OR DD.CostExcludingVATLocal <> 0
	|	OR DD.VATLocal <> 0
	|	OR DD.CostExcludingVATMan <> 0
	|	OR DD.VATManag <> 0
	|
	// Indexes must correspond to the property of the index register from the description of the cost register
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region ProceduresOfStage_CalculationOfBatchesNDS2_4ForAdditionalExpenses

// Request texts

// ... general

Function QueryTextForDistributionOfVATBatchesByAdditionalExpenseAMOUNT(CalculationParameters) Export
	
	QueryText = "";
	
	If ValueIsFilled(CalculationParameters) Then
		ThereIsTableOfAdditionalExpenses = CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters, "TTAdditionalCostsForDistribution");
		ThereIsTableReceiptsOfGoodsVAT = CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters, "GoodsReceiptsVAT");
	Else
		ThereIsTableOfAdditionalExpenses = False;
		ThereIsTableReceiptsOfGoodsVAT = False;
	EndIf;
	
	// Sample data
	If Not ThereIsTableReceiptsOfGoodsVAT Then
	 	QueryText = QueryText + TextInitializationOfVATBatchesTotal() + Common.QueryBatchSeparator();
	 	QueryText = QueryText + TextCorrectedVATDocuments() + Common.QueryBatchSeparator();
	 	QueryText = QueryText + TextOfCorrectionBeforeEnteringBalance() + Common.QueryBatchSeparator();
	 	QueryText = QueryText + TextGoodsReceiptsVAT() + Common.QueryBatchSeparator();
	EndIf;
	If Not ThereIsTableOfAdditionalExpenses Then
	 	QueryText = QueryText + TextAllocationOfAdditionalCosts() + Common.QueryBatchSeparator();
	EndIf;
	
	QueryText = QueryText
		+ TextAdditionalExpensesAmountForDistributionExtended()
		+ Common.QueryBatchSeparator()
		+ TextAdditionalCostsForLocalDistribution()
		+ TMCommonUse.QuerySeparatorInJoin() + TextAdditionalCostsForManDistribution()
		+ Common.QueryBatchSeparator()
		+ TextDOPLocalDatabase()
		+ TMCommonUse.QuerySeparatorInJoin() + TextBaseOfAdditionalMan()
		+ "";
		
	Return QueryText;
	
EndFunction

Function TextAllocationOfAdditionalCosts()
	
	Return "
	|SELECT
	|	T.Ref
	|INTO TTOrganizationsForAllocationOfVATSurcharges
	|FROM
	|	Catalog.Companies AS T
	|WHERE
	|	T.Ref IN(&OrganizationsIncludingLotsOfVATAdditionalExpensesAmount)
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses
	|INTO TTAnalyticsOfDistributionOfPastPeriods
	|FROM
	|	TTCashEstimatedTurnoverOtherExpenses AS T
	|	INNER JOIN Document.CostCalculationRecorder AS RegistrarOfCalculation
	|		ON RegistrarOfCalculation.Ref = T.Recorder
	|	INNER JOIN TTOrganizationsForAllocationOfVATSurcharges AS Companies
	|		ON T.Organization = Companies.Ref
	|	INNER JOIN TTCostItems AS ARTICLES__
	|		ON T.ExpenseItem = ARTICLES__.Ref
	|WHERE
	|	NOT T.OfficialTypeOfMovementParish
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.ExpenseReceiptDocument AS DocumentInflow,
	|	T.LotVendorAttributes AS LotVendorAttributesOfReceiptDocument,
	|	T.VATActivityType AS VATActivityType,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.BusinessOperation AS BusinessOperation,
	|	FALSE AS LotCalculation,
	|	TRUE AS ThisIsLotOfOtherExpensesMaterialOverheadsForAllocation,
	|	SUM(T.LocalCost * ARTICLES__.LocalCoefficient) AS LocalCost,
	|	SUM(T.VATLocal * ARTICLES__.LocalCoefficient) AS VATLocal,
	|	SUM(T.Cost * ARTICLES__.ManSCoefficient) AS Cost,
	|	SUM(T.CostExcludingVAT * ARTICLES__.ManSCoefficient) AS CostExcludingVAT,
	|	SUM(T.VATManag * ARTICLES__.ManSCoefficient) AS VATManag,
	|	SUM(CASE
	|		WHEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATLocal
	|				ELSE 0
	|			  END + T.LocalCost <> 0 
	|			THEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATLocal
	|				ELSE 0
	|			  END + T.LocalCost
	|		ELSE T.VATLocal END
	|		* ARTICLES__.LocalCoefficient) AS LocalDenominator,
	|	SUM(CASE
	|		WHEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATLocal
	|				ELSE 0
	|			  END + T.CostExcludingVAT <> 0
	|		THEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATLocal
	|				ELSE 0
	|			  END + T.CostExcludingVAT
	|		ELSE T.VATManag END
	|		* ARTICLES__.ManSCoefficient) AS DenominatorOfMan
	|INTO TTAdditionalCostsForDistributionPreliminary
	|FROM
	|	TTCashEstimatedTurnoverAndOtherExpenses AS T
	|	INNER JOIN TTOrganizationsForAllocationOfVATSurcharges AS Companies
	|		ON T.Organization = Companies.Ref
	|	INNER JOIN TTCostItems AS ARTICLES__
	|		ON T.ExpenseItem = ARTICLES__.Ref
	|WHERE
	|	T.OfficialTypeOfMovementParish
	|
	|GROUP BY
	|	T.Recorder,
	|	T.Period,
	|	T.Organization,
	|	T.Department,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.VATActivityType,
	|	T.ExpenseReceiptDocument,
	|	T.LotVendorAttributes,
	|	T.LineOfBusiness,
	|	T.BusinessOperation
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED AS Recorder,
	|	&BeginOfPeriod AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.ExpenseReceiptDocument AS DocumentInflow,
	|	T.LotVendorAttributes AS LotVendorAttributesOfReceiptDocument,
	|	T.VATActivityType AS VATActivityType,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS BusinessOperation,
	|	FALSE AS LotCalculation,
	|	TRUE AS ThisIsLotOfOtherExpensesMaterialOverheadsForAllocation,
	|	SUM(T.LocalCostBalance * ARTICLES__.LocalCoefficient) AS LocalCost,
	|	SUM(T.VATLocalBalance * ARTICLES__.LocalCoefficient) AS VATLocal,
	|	SUM(T.CostBalance * ARTICLES__.ManSCoefficient) AS Cost,
	|	SUM(T.CostExcludingVATBalance * ARTICLES__.ManSCoefficient) AS CostExcludingVAT,
	|	SUM(T.VATManagBalance * ARTICLES__.ManSCoefficient) AS VATManag,
	|	SUM(CASE
	|		WHEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATLocalBalance
	|				ELSE 0
	|			  END + T.LocalCostBalance <> 0 
	|		THEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATLocalBalance
	|				ELSE 0
	|			  END + T.LocalCostBalance
	|		ELSE T.VATLocalBalance END) AS LocalDenominator,
	|	SUM(CASE
	|		WHEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATManagBalance
	|				ELSE 0
	|			  END + T.CostExcludingVATBalance <> 0 
	|		THEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATManagBalance
	|				ELSE 0
	|			  END + T.CostExcludingVATBalance
	|		ELSE T.VATManagBalance END) AS DenominatorOfMan
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots.Balance(&BorderEndOfPreviousPeriod,
	|		Organization IN(SELECT T.Ref FROM TTOrganizationsForAllocationOfVATSurcharges AS T)
	|	) AS T
	|	INNER JOIN TTCostItems AS ARTICLES__
	|		ON T.ExpenseItem = ARTICLES__.Ref
	|
	|GROUP BY
	|	T.Organization,
	|	T.Department,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.VATActivityType,
	|	T.ExpenseReceiptDocument,
	|	T.LotVendorAttributes,
	|	T.LineOfBusiness
	|
	|UNION ALL
	|
	// Attribution of deviations in the cost of goods to items of expenditure allocated to the cost of goods.
	// Movements in the register of "Lots of other expenses" for such expenses are formed at the stage of "Preparing the data for the Party's other expenses"
	// the procedure for text access to the Party's other expenses is to write down the nomenclature of the Party's other expenses ().
	// The data sample must correspond to the procedure for the formation of the movement of deviations in the cost of products() #The area of deviation in the cost of products
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.Period AS Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.ExpenseItemOfWriteOff AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.Recorder AS DocumentInflow,
	|	T.LotVendorAttributes AS LotVendorAttributesOfReceiptDocument,
	|	T.VATActivityType AS VATActivityType,
	|	T.CorLineOfBusiness AS LineOfBusiness,
	|	T.BusinessOperation AS BusinessOperation,
	|	T.LotCalculation AS LotCalculation,
	|	FALSE AS ThisIsLotOfOtherExpensesMaterialOverheadsForAllocation,
	|	SUM(T.LocalCost * ARTICLES__.LocalCoefficient) AS LocalCost,
	|	SUM(T.VATLocal * ARTICLES__.LocalCoefficient) AS VATLocal,
	|	SUM(T.Cost * ARTICLES__.ManSCoefficient) AS Cost,
	|	SUM(T.CostExcludingVAT * ARTICLES__.ManSCoefficient) AS CostExcludingVAT,
	|	SUM(T.VATManag * ARTICLES__.ManSCoefficient) AS VATManag,
	|	SUM(CASE
	|		WHEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATLocal
	|				ELSE 0
	|			  END + T.LocalCost <> 0 
	|		THEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATLocal
	|				ELSE 0
	|			  END + T.LocalCost
	|		ELSE T.VATLocal END) AS LocalDenominator,
	|	SUM(CASE
	|		WHEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATManag
	|				ELSE 0
	|			  END + T.CostExcludingVAT <> 0 
	|		THEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATManag
	|				ELSE 0
	|			  END + T.CostExcludingVAT
	|		ELSE T.VATManag END) AS DenominatorOfMan
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS T
	|	INNER JOIN TTOrganizationsForAllocationOfVATSurcharges AS Companies
	|		ON T.Organization = Companies.Ref
	|	INNER JOIN TTCostItems AS ARTICLES__
	|		ON T.ExpenseItemOfWriteOff = ARTICLES__.Ref
	|WHERE
	|	T.EntryType = VALUE(Enum.LotRecordTypes.GoodsCostVarianceForOtherExpenses)
	|	AND T.LotCalculation
	|	AND NOT T.ReversingEntry
	|
	|GROUP BY
	|	T.Recorder,
	|	T.Period,
	|	T.Organization,
	|	T.Department,
	|	T.ExpenseItemOfWriteOff,
	|	T.DimensionOfExpenses,
	|	T.VATActivityType,
	|	T.LotVendorAttributes,
	|	T.CorLineOfBusiness,
	|	T.BusinessOperation,
	|	T.LotCalculation
	|
	|INDEX BY
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	Department,
	|	Organization,
	|	LineOfBusiness
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.DocumentInflow
	|INTO TUEDocumentsOfReceiptOfExpenses
	|FROM
	|	TTAdditionalCostsForDistributionPreliminary AS T
	|WHERE
	|	T.DocumentInflow <> UNDEFINED
	|INDEX BY
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Recorder
	|INTO TUEExpenseRegistrars
	|FROM
	|	TTAdditionalCostsForDistributionPreliminary AS T
	|WHERE
	|	T.Recorder <> UNDEFINED
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.Department,
	|	T.Organization,
	|	T.LineOfBusiness,
	|	MAX(CASE WHEN T.SumMan <> 0 THEN TRUE ELSE FALSE END) AS ThereIsSumOfUpr
	|INTO TTOtherExpenses
	|FROM
	|	AccumulationRegister.OtherExpenses AS T
	|	INNER JOIN TTCostItems AS ARTICLES__
	|		ON T.ExpenseItem = ARTICLES__.Ref
	|	LEFT JOIN TUEDocumentsOfReceiptOfExpenses AS ReceiptDocuments
	|		ON T.Recorder = ReceiptDocuments.DocumentInflow
	|	LEFT JOIN TUEExpenseRegistrars AS Recorders
	|		ON T.Recorder = Recorders.Recorder
	|WHERE
	|	T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND T.Period <= &EndOfPeriod
	|	AND (NOT ReceiptDocuments.DocumentInflow IS NULL
	|		OR NOT Recorders.Recorder IS NULL)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|GROUP BY
	|	T.Recorder,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.Department,
	|	T.Organization,
	|	T.LineOfBusiness
	|INDEX BY
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	Department,
	|	Organization,
	|	LineOfBusiness
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Recorder,
	|	T.Period,
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.DocumentInflow,
	|	T.LotVendorAttributesOfReceiptDocument,
	|	T.VATActivityType,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.BusinessOperation,
	|	T.LotCalculation,
	|	T.ThisIsLotOfOtherExpensesMaterialOverheadsForAllocation,
	|	T.LocalCost,
	|	T.VATLocal,
	|	T.Cost,
	|	T.CostExcludingVAT,
	|	CASE WHEN ISNULL(OtherExpenses.ThereIsSumOfUpr, TRUE) THEN T.CostExcludingVAT ELSE 0 END AS CostExcludingVATMan,
	|	T.VATManag,
	|	CASE WHEN T.LocalCost <> 0
	|	  OR T.Cost <> 0
	|	  OR T.CostExcludingVAT <> 0
	|	  OR CASE WHEN ISNULL(OtherExpenses.ThereIsSumOfUpr, TRUE) THEN T.CostExcludingVAT ELSE 0 END <> 0
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreSums,
	|	T.LocalDenominator,
	|	T.DenominatorOfMan
	|INTO TTAdditionalCostsForDistribution
	|FROM
	|	TTAdditionalCostsForDistributionPreliminary AS T
	|	LEFT JOIN TTOtherExpenses AS OtherExpenses
	|		ON T.ExpenseItem = OtherExpenses.ExpenseItem
	|		AND T.DimensionOfExpenses = OtherExpenses.DimensionOfExpenses
	|		AND T.Department = OtherExpenses.Department
	|		AND T.Organization = OtherExpenses.Organization
	|		AND T.LineOfBusiness = OtherExpenses.LineOfBusiness
	|		AND (T.DocumentInflow = OtherExpenses.Recorder
	|			OR T.Recorder = OtherExpenses.Recorder)
	|INDEX BY
	|	Organization
	|";
EndFunction

Function TextAdditionalExpensesAmountForDistributionExtended() // VTD Overspending for distributiondisexpanded, uses VTD overspending for distribution
	Return 
		"SELECT
		|	1 AS Source,
		|	T.Recorder AS Recorder,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.DocumentInflow AS DocumentInflow,
		|	T.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
		|	T.VATActivityType AS VATActivityType,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	UNDEFINED AS FinRecordID,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.LotCalculation,
		|	T.ThisIsLotOfOtherExpensesMaterialOverheadsForAllocation,
		|	T.LocalCost,
		|	T.VATLocal,
		|	T.Cost,
		|	T.CostExcludingVAT,
		|	T.CostExcludingVATMan,
		|	T.VATManag,
		|	T.ThereAreSums,
		|	T.LocalDenominator,
		|	T.DenominatorOfMan
		|INTO TTAdditionalExpensesAmountForDistributionExtended
		|FROM
		|	TTAdditionalCostsForDistribution AS T
		|WHERE
		|	T.Organization IN (&OrganizationsIncludingLotsOfVATAdditionalExpensesAmount)
		|
		|UNION ALL
		|
		|SELECT
		|	2 AS Source,
		|	T.Recorder AS Recorder,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.ExpenseItemOfWriteOff AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.DocumentInflow AS DocumentInflow,
		|	T.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
		|	T.CorVATActivityTypes AS VATActivityType,
		|	T.CorLineOfBusiness AS LineOfBusiness,
		|	T.FinRecordID,
		|	T.BusinessOperation AS BusinessOperation,
		|	FALSE AS LotCalculation,
		|	FALSE AS ThisIsLotOfOtherExpensesMaterialOverheadsForAllocation,
		|	SUM(CAST(T.CostExcludingVATLocal * ARTICLES__.LocalCoefficient AS NUMBER (31,2))) AS LocalCost,
		|	SUM(CAST(T.VATLocal * ARTICLES__.LocalCoefficient AS NUMBER (31,2))) AS VATLocal,
		|	SUM(CAST(T.CostInclVAT * ARTICLES__.ManSCoefficient AS NUMBER (31,2))) AS Cost,
		|	SUM(CAST(T.CostExcludingVAT * ARTICLES__.ManSCoefficient AS NUMBER (31,2))) AS CostExcludingVAT,
		|	SUM(CAST(T.CostExcludingVATMan * ARTICLES__.ManSCoefficient AS NUMBER (31,2))) AS CostExcludingVATMan,
		|	SUM(CAST(T.VATManag * ARTICLES__.ManSCoefficient AS NUMBER (31,2))) AS VATManag,
		|	CASE WHEN SUM(CAST(T.CostExcludingVATLocal * ARTICLES__.LocalCoefficient AS NUMBER (31,2))) <> 0
		|	  OR SUM(CAST(T.CostInclVAT * ARTICLES__.ManSCoefficient AS NUMBER (31,2))) <> 0
		|	  OR SUM(CAST(T.CostExcludingVAT * ARTICLES__.ManSCoefficient AS NUMBER (31,2))) <> 0
		|	  OR SUM(CAST(T.CostExcludingVATMan * ARTICLES__.ManSCoefficient AS NUMBER (31,2))) <> 0
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS ThereAreSums,
		|	SUM(CASE
		|		WHEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|				THEN T.VATLocal
		|				ELSE 0
		|			  END + T.CostExcludingVATLocal <> 0 
		|		THEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|				THEN T.VATLocal
		|				ELSE 0
		|			  END + T.CostExcludingVATLocal
		|		ELSE T.VATLocal END) AS LocalDenominator,
		|	SUM(CASE
		|		WHEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|				THEN T.VATManag
		|				ELSE 0
		|			  END + T.CostExcludingVAT <> 0 
		|		THEN CASE WHEN T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|				THEN T.VATManag
		|				ELSE 0
		|			  END + T.CostExcludingVAT
		|		ELSE T.VATManag END) AS DenominatorOfMan
		|FROM
		|	TTTurnoverValueOfBatchesVAT AS T
		|	INNER JOIN TTCostItems AS ARTICLES__
		|		ON ARTICLES__.Ref = T.ExpenseItemOfWriteOff
		|WHERE
		|	T.Organization IN (&OrganizationsIncludingLotsOfVATAdditionalExpensesAmount)
		|	AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost)
		|	AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND NOT T.OfficialTypeOfMovementParish
		|
		|GROUP BY
		|	T.Recorder,
		|	T.Period,
		|	T.Organization,
		|	T.Department,
		|	T.ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses,
		|	T.DocumentInflow,
		|	T.LotVendorAttributesOfReceiptDocument,
		|	T.CorVATActivityTypes,
		|	T.CorLineOfBusiness,
		|	T.FinRecordID,
		|	T.BusinessOperation
		|
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department,
		|	Organization,
		|	LineOfBusiness
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|	T.ThereAreSums,
		|	CAST(SUM(T.LocalDenominator) AS NUMBER(31,2)) AS LocalDenominator,
		|	CAST(SUM(T.DenominatorOfMan) AS NUMBER(31,2)) AS DenominatorOfMan
		|
		|INTO TTAdditionalExpensesAmountForDistributionInSummary
		|FROM
		|	TTAdditionalExpensesAmountForDistributionExtended AS T
		|GROUP BY
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|	T.Department,
		|	T.Organization,
		|	T.LineOfBusiness,
		|	T.ThereAreSums
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department,
		|	Organization,
		|	LineOfBusiness
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.ThereAreSums,
		|	CASE WHEN T.LocalDenominator < 0 THEN -1 ELSE 1 END AS SignAdditionalExpensesLocal,
		|	CASE WHEN T.DenominatorOfMan < 0 THEN -1 ELSE 1 END AS SignOfAdditionalExpensesManags,
		|	CASE WHEN Base.LocalDenominator < 0 THEN -1 ELSE 1 END AS SignBaseLocal,
		|	CASE WHEN Base.DenominatorOfMan < 0 THEN -1 ELSE 1 END AS SignBaseMan,
		|	CASE WHEN Base.LocalDenominator = 0 THEN 0
		|		ELSE CAST(T.LocalDenominator / Base.LocalDenominator AS NUMBER(31,10)) END AS LocalCoefficient,
		|	CASE WHEN Base.DenominatorOfMan = 0 THEN 0
		|		ELSE CAST(T.DenominatorOfMan / Base.DenominatorOfMan AS NUMBER(31,10)) END AS ManSCoefficient
		|
		|INTO TTCoefficientsOfBase
		|FROM
		|	TTAdditionalExpensesAmountForDistributionInSummary AS T
		|	INNER JOIN TTBaseOfDistributionOfAdditionalExpensesInSummary AS Base
		|		ON T.Organization = Base.Organization
		|		AND T.Department = Base.Department
		|		AND T.LineOfBusiness = Base.LineOfBusiness
		|		AND T.ExpenseItem = Base.ExpenseItem
		|		AND T.DimensionOfExpenses = Base.DimensionOfExpenses
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department,
		|	Organization,
		|	LineOfBusiness
		|"
EndFunction

Function TextAdditionalCostsForLocalDistribution() // Uses VT overspending for distributionextended
	Return
		"SELECT
		|	""TextAdditionalCostsForLocalDistribution"" AS RequestSource,
		|	TRUE AS LocalAccnting,
		|	VALUE(Enum.LotRecordTypes.AdditionalExpensesForAllocationLocal) AS EntryType,
		|	CASE WHEN SUM(DD.LocalDenominator) < 0 THEN TRUE ELSE FALSE END AS ThisIsReverseTransaction,
		|	SUM(Base.SignAdditionalExpensesLocal * DD.LocalDenominator) AS Denominator,
		|	
		|	DD.Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.Recorder,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DD.Organization,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	UNDEFINED AS InventoryOwnerAttribute,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	UNDEFINED AS Lot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
		|	DD.VATActivityType AS VATActivityType,
		|	DD.DocumentInflow,
		|	DD.LotVendorAttributesOfReceiptDocument,
		|	DD.LineOfBusiness,
		|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef) AS RuleOfCostAllocatingToProductionLots,
		|
		|	0 AS CostInclVAT,
		|	0 AS CostExcludingVAT,
		|	SUM(DD.LocalCost) AS CostExcludingVATLocal,
		|	SUM(DD.VATLocal) AS VATLocal,
		|	0 AS CostExcludingVATMan,
		|	0 AS VATManag,
		|	DD.ThereAreSums AS ThereAreSums,
		|
		|	FALSE AS ForDisposal,
		|	DD.BusinessOperation,
		|	DD.VATActivityType AS CorVATActivityTypes,
		|	VALUE(Catalog.Companies.EmptyRef) AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
		|	DD.Department AS Department,
		|	DD.ExpenseItem AS ExpenseItemAssets,
		|	DD.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS DimensionOfAssets,
		|	UNDEFINED AS CorExpenseItem,
		|	UNDEFINED AS CorExpenditureDimension,
		|	UNDEFINED AS DebitBusinessUnit,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS VATWriteOffItem,
		|	UNDEFINED AS DimensionVATWriteOff,
		|	UNDEFINED AS AccountingSection,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	UNDEFINED AS FinRecordID,
		|	FALSE AS ReversingEntry
		|INTO TheseAdditionalExpensesAmountForDistribution
		|FROM
		|	TTAdditionalExpensesAmountForDistributionExtended AS DD
		|	INNER JOIN TTCoefficientsOfBase AS Base
		|		ON DD.Organization = Base.Organization
		|		AND DD.Department = Base.Department
		|		AND DD.LineOfBusiness = Base.LineOfBusiness
		|		AND DD.ExpenseItem = Base.ExpenseItem
		|		AND DD.DimensionOfExpenses = Base.DimensionOfExpenses
		|		AND DD.ThereAreSums = Base.ThereAreSums
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingLotsOfVATAdditionalExpensesAmount)
		|	AND Base.LocalCoefficient <> 0
		|	AND (DD.LocalCost <> 0 OR DD.VATLocal <> 0)
		|
		|GROUP BY
		|	DD.Period,
		|	DD.Recorder,
		|	DD.Organization,
		|	DD.VATActivityType,
		|	DD.DocumentInflow,
		|	DD.LotVendorAttributesOfReceiptDocument,
		|	DD.LineOfBusiness,
		|	DD.ThereAreSums,
		|	DD.BusinessOperation,
		|	DD.Department,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses
		|";
EndFunction

Function TextDOPLocalDatabase()
	Return
		"SELECT
		|	""TextDOPLocalDatabase"" AS RequestSource,
		|	TRUE AS LocalAccnting,
		|	VALUE(Enum.LotRecordTypes.BaseAdditionalExpensesLocal) AS EntryType,
		|	CASE WHEN DD.SignLocal = -1 THEN TRUE ELSE FALSE END AS ThisIsReverseTransaction,
		|	Coefficients.SignBaseLocal * DD.SignLocal * DD.LocalDenominator * Coefficients.LocalCoefficient AS Denominator,
		|	Coefficients.SignBaseLocal * DD.SignLocal * DD.LocalDenominator * Coefficients.LocalCoefficient AS DenominatorForSorting,
		|	
		|	DD.Period AS Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.Recorder AS Recorder,
		|	UNDEFINED AS RecordType,
		|	DD.Organization,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	DD.Lot AS Lot,
		|	DD.LotVendorAttributes,
		|	DD.VATActivityType AS VATActivityType,
		|	UNDEFINED AS DocumentInflow,
		|	UNDEFINED AS LotVendorAttributesOfReceiptDocument,
		|	DD.LineOfBusiness,
		|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef) AS RuleOfCostAllocatingToProductionLots,
		|
		|	0 AS CostInclVAT,
		|	0 AS CostExcludingVAT,
		|	0 AS CostExcludingVATLocal,
		|	0 AS VATLocal,
		|	0 AS CostExcludingVATMan,
		|	0 AS VATManag,
		|	Coefficients.ThereAreSums AS ThereAreSums,
		|
		|	DD.ForDisposal,
		|	UNDEFINED AS BusinessOperation,
		|	UNDEFINED AS CorVATActivityTypes,
		|	VALUE(Catalog.Companies.EmptyRef) AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	DD.CorLineOfBusiness,
		|	DD.Department,
		|	DD.ExpenseItem AS ExpenseItemAssets,
		|	DD.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS DimensionOfAssets,
		|	DD.CorExpenseItem,
		|	DD.CorExpenditureDimension,
		|	DD.DebitBusinessUnit,
		|	UNDEFINED AS DocumentSource,
		// If the "Write off VAT on expenses that are not accepted for TA" checkbox is checked in the VAT accounting setting and the expense
		// item that is not accepted for income tax is indicated, then such expenses are written off to the item and expense analytics 
		// from the VAT accounting setting if VAT was not included in the price of the product.
		|	CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		ELSE UNDEFINED
		|	END AS VATWriteOffItem,
		|	CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		ELSE UNDEFINED
		|	END AS DimensionVATWriteOff,
		|	DD.AccountingSection,
		|	DD.FinancialAccountingDimension,
		|	DD.FinRecordID,
		|	FALSE AS ReversingEntry
		|INTO BaseAdditionalExpensesAmountForDistribution
		|FROM
		|	TTBaseOfAllocationOfAdditionalExpenses AS DD
		|	INNER JOIN TTCoefficientsOfBase AS Coefficients
		|		ON DD.Organization = Coefficients.Organization
		|		AND DD.Department = Coefficients.Department
		|		AND DD.LineOfBusiness = Coefficients.LineOfBusiness
		|		AND DD.ExpenseItem = Coefficients.ExpenseItem
		|		AND DD.DimensionOfExpenses = Coefficients.DimensionOfExpenses
		|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|		ON ExpenseItems.Ref = DD.ExpenseItem
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingLotsOfVATAdditionalExpensesAmount)
		|	AND Coefficients.LocalCoefficient <> 0
		|";
EndFunction

Function TextAdditionalCostsForManDistribution() // Uses VT overspending for distributionextended
	Return
		"SELECT
		|	""TextAdditionalCostsForManDistribution"" AS RequestSource,
		|	FALSE AS LocalAccnting,
		|	VALUE(Enum.LotRecordTypes.AdditionalExpensesForAllocationMan) AS EntryType,
		|	CASE WHEN SUM(DD.DenominatorOfMan) < 0 THEN TRUE ELSE FALSE END AS ThisIsReverseTransaction,
		|	SUM(Base.SignOfAdditionalExpensesManags * DD.DenominatorOfMan) AS Denominator,
		|	
		|	DD.Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.Recorder,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DD.Organization,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	UNDEFINED AS InventoryOwnerAttribute,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	UNDEFINED AS Lot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
		|	DD.VATActivityType AS VATActivityType,
		|	DD.DocumentInflow,
		|	DD.LotVendorAttributesOfReceiptDocument,
		|	DD.LineOfBusiness,
		|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef) AS RuleOfCostAllocatingToProductionLots,
		|
		|	SUM(DD.Cost) AS CostInclVAT,
		|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
		|	0 AS CostExcludingVATLocal,
		|	0 AS VATLocal,
		|	SUM(DD.CostExcludingVATMan) AS CostExcludingVATMan,
		|	SUM(DD.VATManag) AS VATManag,
		|	DD.ThereAreSums AS ThereAreSums,
		|
		|	FALSE AS ForDisposal,
		|	DD.BusinessOperation,
		|	DD.VATActivityType AS CorVATActivityTypes,
		|	VALUE(Catalog.Companies.EmptyRef) AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
		|	DD.Department AS Department,
		|	DD.ExpenseItem AS ExpenseItemAssets,
		|	DD.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS DimensionOfAssets,
		|	UNDEFINED AS CorExpenseItem,
		|	UNDEFINED AS CorExpenditureDimension,
		|	UNDEFINED AS DebitBusinessUnit,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS VATWriteOffItem,
		|	UNDEFINED AS DimensionVATWriteOff,
		|	UNDEFINED AS AccountingSection,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	UNDEFINED AS FinRecordID,
		|	FALSE AS ReversingEntry
		|FROM
		|	TTAdditionalExpensesAmountForDistributionExtended AS DD
		|	INNER JOIN TTCoefficientsOfBase AS Base
		|		ON DD.Organization = Base.Organization
		|		AND DD.Department = Base.Department
		|		AND DD.LineOfBusiness = Base.LineOfBusiness
		|		AND DD.ExpenseItem = Base.ExpenseItem
		|		AND DD.DimensionOfExpenses = Base.DimensionOfExpenses
		|		AND DD.ThereAreSums = Base.ThereAreSums
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingLotsOfVATAdditionalExpensesAmount)
		|	AND Base.ManSCoefficient <> 0
		|	AND (DD.Cost <> 0 OR DD.CostExcludingVAT <> 0 OR DD.CostExcludingVATMan <> 0 OR DD.VATManag <> 0)
		|
		|GROUP BY
		|	DD.Period,
		|	DD.Recorder,
		|	DD.Organization,
		|	DD.VATActivityType,
		|	DD.DocumentInflow,
		|	DD.LotVendorAttributesOfReceiptDocument,
		|	DD.LineOfBusiness,
		|	DD.ThereAreSums,
		|	DD.BusinessOperation,
		|	DD.Department,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses
		|";
EndFunction

Function TextBaseOfAdditionalMan()
	Return
		"SELECT
		|	""TextBaseOfAdditionalMan"" AS RequestSource,
		|	FALSE AS LocalAccnting,
		|	VALUE(Enum.LotRecordTypes.BaseAdditionalExpensesMan) AS EntryType,
		|	CASE WHEN DD.SignMan = -1 THEN TRUE ELSE FALSE END AS ThisIsReverseTransaction,
		|	Coefficients.SignBaseMan * DD.SignMan * DD.DenominatorOfMan * Coefficients.ManSCoefficient AS Denominator,
		|	Coefficients.SignBaseMan * DD.SignMan * DD.DenominatorOfMan * Coefficients.ManSCoefficient AS DenominatorForSorting,
		|	
		|	DD.Period AS Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.Recorder AS Recorder,
		|	UNDEFINED AS RecordType,
		|	DD.Organization,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	DD.Lot AS Lot,
		|	DD.LotVendorAttributes,
		|	DD.VATActivityType AS VATActivityType,
		|	UNDEFINED AS DocumentInflow,
		|	UNDEFINED AS LotVendorAttributesOfReceiptDocument,
		|	DD.LineOfBusiness,
		|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef) AS RuleOfCostAllocatingToProductionLots,
		|
		|	0 AS CostInclVAT,
		|	0 AS CostExcludingVAT,
		|	0 AS CostExcludingVATLocal,
		|	0 AS VATLocal,
		|	0 AS CostExcludingVATMan,
		|	0 AS VATManag,
		|	Coefficients.ThereAreSums AS ThereAreSums,
		|
		|	DD.ForDisposal,
		|	UNDEFINED AS BusinessOperation,
		|	UNDEFINED AS CorVATActivityTypes,
		|	VALUE(Catalog.Companies.EmptyRef) AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	DD.CorLineOfBusiness,
		|	DD.Department,
		|	DD.ExpenseItem AS ExpenseItemAssets,
		|	DD.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS DimensionOfAssets,
		|	DD.CorExpenseItem,
		|	DD.CorExpenditureDimension,
		|	DD.DebitBusinessUnit,
		|	UNDEFINED AS DocumentSource,
		// If the "Write off VAT on expenses that are not accepted for TA" checkbox is checked in the VAT accounting setting and the expense
		// item that is not accepted for income tax is indicated, then such expenses are written off to the item and expense analytics 
		// from the VAT accounting setting if VAT was not included in the price of the product.
		|	CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		ELSE UNDEFINED
		|	END AS VATWriteOffItem,
		|	CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		ELSE UNDEFINED
		|	END AS DimensionVATWriteOff,
		|	DD.AccountingSection,
		|	DD.FinancialAccountingDimension,
		|	DD.FinRecordID,
		|	FALSE AS ReversingEntry
		|FROM
		|	TTBaseOfAllocationOfAdditionalExpenses AS DD
		|	INNER JOIN TTCoefficientsOfBase AS Coefficients
		|		ON DD.Organization = Coefficients.Organization
		|		AND DD.Department = Coefficients.Department
		|		AND DD.LineOfBusiness = Coefficients.LineOfBusiness
		|		AND DD.ExpenseItem = Coefficients.ExpenseItem
		|		AND DD.DimensionOfExpenses = Coefficients.DimensionOfExpenses
		|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|		ON ExpenseItems.Ref = DD.ExpenseItem
		|WHERE
		|	DD.Organization IN (&OrganizationsIncludingLotsOfVATAdditionalExpensesAmount)
		|	AND Coefficients.ManSCoefficient <> 0
		|";
EndFunction

#EndRegion

#Region StageProcedures_CalculationOfBatchesOfNDS2_4ForBatchesOfOtherExpenses

//
// ... data descriptions

Function TextDescriptionOfDataForDistributionOfVATLotsByLotsOfOtherExpenses() Export
	QueryText = 
		"SELECT TOP 0
		|	FALSE 														 AS ThereIsPrice, 
		|	Cost_.EntryType 									 AS EntryType,
		|	FALSE														 AS PartiallyLeaveAtUnfinishedProduction,
		|	0 															 AS Denominator,
		|	0 															 AS DenominatorOfMan,
		|	0 															 AS DenominatorForSources,
		|	0 															 AS DenominatorForUprSources,
		|	
		|	Cost_.Period,
		|	Cost_.Recorder,
		|	Cost_.RecordType,
		|	DD.Organization,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) 				      AS InventoryOwnerAttribute,
		|	Cost_.CorItemsLocationAttributes,
		|	Cost_.CorInventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	Cost_.VATActivityType,
		|	DD.DocumentInflow,
		|	DD.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|
		|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef) AS RuleOfCostAllocatingToProductionLots,
		|
		|	0 AS CostInclVAT,
		|	0 AS CostExcludingVAT,
		|	0 AS CostExcludingVATLocal,
		|	0 AS VATLocal,
		|	0 AS VATManag,
		|
		|	Cost_.FinRecordID,
		|	Cost_.BusinessOperation,
		|	Cost_.CorVATActivityTypes,
		|	Cost_.CorAccountingSection,
		|	DD.Lot AS CorLot,
		|	DD.LotVendorAttributes AS LotVendorAttributesCorr,
		|	Cost_.CorLineOfBusiness,
		|	Cost_.Department,
		|	ItemisedExpensesLots.ExpenseItem AS ExpenseItemAssets,
		|	ItemisedExpensesLots.DimensionOfExpenses,
		|	Cost_.Department DebitBusinessUnit,
		|	Cost_.ExpenseItemOfWriteOff AS VATWriteOffItem,
		|	Cost_.DimensionOfExpenses AS DimensionVATWriteOff,
		|	Cost_.AccountingSection,
		|	Cost_.FinancialAccountingDimension
		|INTO Data
		|FROM
		|	InformationRegister.ItemizeGoodsLotCost AS DD
		|	LEFT JOIN AccumulationRegister.InventoryCost AS Cost_
		|		ON FALSE
		|	LEFT JOIN AccumulationRegister.ItemisedExpensesLots AS ItemisedExpensesLots
		|		ON FALSE
		|";

	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction


#EndRegion

#Region ProceduresOfStage_CalculationOfDeviationOfFIFORollingRelease

Function QueryTextCorrectionOfIssueDeviations(CalculationParameters) Export
	Return
		"SELECT
		|	T.Organization,
		|	T.CorLot AS Lot,
		|	T.LotVendorAttributesCorr AS LotVendorAttributes,
		|	T.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.CorItemsLocationAttributes AS InventoryLocationAttributesOfReceiptDocument,
		|	T.Recorder AS DocumentInflow,
		|
		|	SUM(T.Count) AS Count,
		|	SUM(CASE WHEN T.CalculationOfCost THEN -1 ELSE 1 END
		|	  * (T.LocalCost + T.AddExpensesLocal + T.ItemizedFixedCostsCompl + T.ItemizedVariableCostsCompl)) AS CostExcludingVATLocal,
		|	SUM(CASE WHEN T.CalculationOfCost THEN -1 ELSE 1 END
		|	  * (T.CostMan + T.AddExpensesMan + T.ItemizedFixedCostsManag + T.ItemizedVariableCostsManag)) AS CostExcludingVATMan
		|INTO TTCorrectionOfReleaseDeviationsPreliminary
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|WHERE
		|	T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
		|	AND T.Organization IN (&OrganizationsUseWriteOffOfDeviationsForSales)
		|	AND NOT T.OfficialTypeOfMovementParish
		|	AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|	AND T.CorLot <> UNDEFINED
		|	AND NOT T.ReversingEntry
		|GROUP BY
		|	T.Organization,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorItemsLocationAttributes,
		|	T.Recorder
		|HAVING
		|	MAX(T.CalculationOfCost) = TRUE
		|	AND MIN(T.CalculationOfCost) = FALSE
		|
		|INDEX BY
		|	InventoryLocationAttributesOfReceiptDocument
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	&BeginOfPeriod AS RegistrationPeriod,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.InventoryOwnerAttribute,
		|	DimensionKeys.Products AS Products,
		|	DimensionKeys.Characteristic AS Characteristic,
		|
		|	FALSE AS PreviousRedistributionCosts,
		|	T.InventoryLocationAttributesOfReceiptDocument,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS WIPInventoryLocationAttributes,
		|	T.DocumentInflow,
		|	T.LotVendorAttributes AS LotVendorAttributesOfReceiptDocument,
		|
		|	CAST(T.CostExcludingVATLocal / T.Count AS NUMBER (31,10)) AS CostExcludingVATLocal,
		|	CAST(T.CostExcludingVATMan / T.Count AS NUMBER (31,10)) AS CostExcludingVATMan
		|INTO TTCorrectionOfReleaseDeviations
		|FROM
		|	TTCorrectionOfReleaseDeviationsPreliminary AS T
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
		|		ON T.InventoryLocationAttributesOfReceiptDocument = DimensionKeys.Ref
		|WHERE
		|	T.Count <> 0
		|	AND (T.CostExcludingVATLocal <> 0
		|		OR T.CostExcludingVATMan <> 0)
		|";
	
EndFunction

#EndRegion

#Region StageProcedures_PreparationOfDataForInclusionExclusionOfVATAdditionalExpensesInCost24

// Sample data

Procedure GetDataForInclusionExclusionOfVATAdditionalExpenses(CalculationParameters)
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForInclusionExclusionOfVATAdditionalExpenses(CalculationParameters));
	
EndProcedure

// Request texts

// ... general

Function RequestTextForInclusionExclusionOfVATAdditionalExpenses(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// Sample data
		+ TextDescriptionOfDataForInclusionExclusionOfVATAdditionalExpenses() // w Data
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfInclusionExclusionOfVATAdditionalExpenses()
		+ "";
	
	Return QueryText;
	
EndFunction

// ... data descriptions

Function TextDescriptionOfDataForInclusionExclusionOfVATAdditionalExpenses()
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80)) AS RequestSource,
		|	0 AS Priority,
		|	FALSE AS CalculationIsCompleted,
		|	T.EntryType AS EntryType,
		|	T.FinRecordID AS FinRecordID,
		|	T.RecordType AS RecordType,
		|	T.Period AS Period,
		|	T.Recorder AS Recorder,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.AccountingSection AS AccountingSection,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Organization AS Organization,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.VATActivityType AS VATActivityType,
		|	T.CorVATActivityTypes AS CorVATActivityTypes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	0 AS LocalCost,
		|	0 AS CostMan
		|INTO Data
		|FROM
		|	AccumulationRegister.InventoryCost AS T";

	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

// ... data samples

Function TextOfInclusionExclusionOfVATAdditionalExpenses()
	Return "
		|SELECT
		|	""TextOfInclusionExclusionOfVATAdditionalExpenses"" AS RequestSource,
		|	10 AS Priority,
		|	TRUE AS CalculationIsCompleted,
		|	VALUE(Enum.LotRecordTypes.InclusionExclusionOfVATInCost) AS EntryType,
		|	T.FinRecordID AS FinRecordID,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	T.Period AS Period,
		|	T.Recorder AS Recorder,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.AccountingSection AS AccountingSection,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Organization AS Organization,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.VATActivityType AS VATActivityType,
		|	T.CorVATActivityTypes AS CorVATActivityTypes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	VALUE(Enum.BusinessTransactions.InclusionExclusionOfVATInCost) AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses) AS BusinessTransactionSetting,
		|	CASE
		|		WHEN T.CorVATActivityTypes IN (&TypesOfTaxationVATIsNotIncludedInCost)
		|		 AND T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|			THEN T.VATLocal
		|		WHEN T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
		|		 AND T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
		|			THEN -T.VATLocal
		|		ELSE 0
		|	END AS LocalCost,
		|	CASE
		|		WHEN T.CorVATActivityTypes IN (&TypesOfTaxationVATIsNotIncludedInCost)
		|		 AND T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|			THEN T.VATManag
		|		WHEN T.CorVATActivityTypes IN (&TypesOfTaxationVATIsIncludedInCost)
		|		 AND T.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
		|			THEN -T.VATManag
		|		ELSE 0
		|	END AS CostMan
		|FROM
		|	TTAdditionalCostsForItemByItemCosts AS T
		|	LEFT JOIN InformationRegister.SourceDocumentsData AS SourceDocumentsData
		|		ON SourceDocumentsData.Organization = T.Organization
		|		AND SourceDocumentsData.Document = T.DocumentInflow
		|WHERE
		|	T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
		|	AND T.VATActivityType <> T.CorVATActivityTypes
		|	AND T.CorVATActivityTypes <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	AND T.CorVATActivityTypes <> UNDEFINED
		|	AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|	AND T.AccountingSection <> UNDEFINED
		|	AND T.EntryType = VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified)
		|	AND T.VATWriteOffItem = UNDEFINED
		|	AND (T.VATLocal <> 0 OR T.VATManag <> 0)
		|";
EndFunction


#EndRegion


#Region StageProcedures_PreparationOfDataForBatchesOfOtherExpenses

#Region Description_PreparationOfDataForBatchesOfOtherExpenses

// The documents of receipt of item-by-item expenses during the process form incoming online movements by parties of other expenses
//
// At this stage, offline movements are formed by batches of other expenses
//
// Production articles:
// 3. receipt of production costs when the Product item is written off to the item of expenditure
//		- if the Attribute of the item of expenditure is filled in in the cost movement, then this is the write-off of the Product item to the item
//		- for this Product, there may be costs in 3 vat batch registers
//		- these costs should be transferred from the cost price to the batch of other expenses to the item specified in the item of expenditure
// 2. The receipt of costs when writing off the cost item "at cost" to the cost item "for production"
//		Occurs in the following scenarios:
//		- receipt of material in the last period, and release is made from it
//			- additional payments were received in the next period. expenses for this batch of material
//			- these expenses will be attributed to the predetermined item "Production expenses of past periods"
// 		- receipt of expenses for the production item with the type of activity VAT "VAT Tax agent"
//			- VAT on these costs will be attributed to the item "VAT of the tax agent" and then transferred to the original production item
// 1. Disposal of production costs in work-in-progress
//		- when the costs come to the batch of production (in the cost of Work-in-progress section) they are removed from the register of lots of other expenses
//		- at such costs, the expenditure movement is formed
//  	- the arrival of these costs - or online movement, if the amount of costs is in the document, or clause 2
// is done. If you add up the online arrivals for production costs, movements from clauses 2 and 3, and subtract the costs of clause 1 from them, then the register of other parties should close at 0
//
// Articles "on prime cost"
// 3. receipt of costs "at cost" when the Product is written off as an expense item (similar to clause 2)
// 4. write-off of costs by documents distribution
//		- of costs - all costs "at cost" are written off: both generated online and offline
// If you add up the online receipts for "cost", movements from item 3 and subtract the costs of item 4 from them, then the register of other batches should close at 0
// 

#EndRegion

// Sample data

Procedure GetDataForBatchesOfOtherExpenses(CalculationParameters)
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForLotsOfOtherExpenses(CalculationParameters));
	
EndProcedure

// Request texts

// ... general

Function RequestTextForLotsOfOtherExpenses(CalculationParameters = Undefined) Export
	
	QueryText = ""

		// Sample data
		+ TextDescriptionOfDataForBatchesOfOtherExpenses() // w Data
		
		+ TMCommonUse.QuerySeparatorInJoin() + TextReceiptOfLotsOfOtherExpensesWhenWritingOffNomenclatureForAdditionalFIFOExpenses()
		+ TMCommonUse.QuerySeparatorInJoin() + TextWriteOffOfLotsOfOtherExpensesForAdditionalExpensesAmount()
		+ "";
	
	Return QueryText;
	
EndFunction

	
// ... data descriptions

Function TextDescriptionOfDataForBatchesOfOtherExpenses()
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80)) AS RequestSource,
		|	0 AS Priority,
		|	VALUE(Enum.LotRecordTypes.EmptyRef) AS EntryType,
		|	FALSE AS CalculationIsCompleted,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DATETIME(1, 1, 1, 0, 0, 0) AS Period,
		|	DD.Recorder,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.ExpenseReceiptDocument,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
		|	DD.CorExpenseItem,
		|	DD.CorExpenditureDimension,
		|	DD.DebitBusinessUnit,
		|	DD.CorLineOfBusiness,
		|	DD.CorGroupOfManufacturedProducts,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS VATLocal,
		|	0 AS VATManag,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.ReversingEntry
		|INTO Data
		|FROM
		|	AccumulationRegister.ItemisedExpensesLots AS DD 
		|";

	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

// ... data samples


// A similar function for accounting for the average text access of the party and other expenses for writing the nomenclature of the nomenclature for average monthly expenses
//
Function TextReceiptOfLotsOfOtherExpensesWhenWritingOffNomenclatureForAdditionalFIFOExpenses()
	Return "
		|SELECT
		|	""TextReceiptOfLotsOfOtherExpensesWhenWritingOffNomenclatureForAdditionalFIFOExpenses"" AS RequestSource,
		|	10 AS Priority,
		|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
		|	TRUE AS CalculationIsCompleted,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DD.Period,
		|	DD.Recorder AS Recorder,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		|	DD.Organization,
		|	DD.Department,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	DD.DocumentInflow AS ExpenseReceiptDocument,
		|	DD.LotVendorAttributesOfReceiptDocument AS LotVendorAttributes,
		|	DD.LineOfBusiness,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	DD.VATActivityType AS VATActivityType,
		|	UNDEFINED AS CorExpenseItem,
		|	UNDEFINED AS CorExpenditureDimension,
		|	UNDEFINED AS DebitBusinessUnit,
		|	UNDEFINED AS CorLineOfBusiness,
		|	UNDEFINED AS CorGroupOfManufacturedProducts,
		|	SUM(DD.Cost) AS Cost,
		|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(DD.LocalCost) AS LocalCost,
		|	SUM(CASE
		|		WHEN TRUE
		|		THEN DD.VATLocal
		|		ELSE 0
		|	END) AS VATLocal,
		|	SUM(CASE
		|		WHEN TRUE
		|		THEN DD.VATManag
		|		ELSE 0
		|	END) AS VATManag,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	UNDEFINED AS VATTaxation,
		|	UNDEFINED AS BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	FALSE AS ReversingEntry
		|FROM
		|	TTAdditionalExpensesAmountForDistributionExtended AS DD
		|	LEFT JOIN Document.CustomerInvoiceIntercompany AS Transfer_
		|		ON DD.Recorder = Transfer_.Ref
		|		AND DD.Organization = Transfer_.Organization
		|	LEFT JOIN Document.PurchaseAdjustment AS Adjusting
		|		ON DD.Recorder = Adjusting.Ref
		|	LEFT JOIN Document.ReverseVATAccrual AS ReverseVATAccrual
		|		ON DD.Recorder = ReverseVATAccrual.Ref
		|	LEFT JOIN Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServices
		|		ON ReceiptOfServices.Ref = DD.Recorder
		|	LEFT JOIN Document.OBEntryOtherExpenses AS OBEntry
		|		ON DD.Recorder = OBEntry.Ref
		|WHERE
		// We exclude additional expenses that were in the balances of the register ""Lots of other expenses""
		|	DD.Recorder <> UNDEFINED
		// we exclude additional expenses for which there are already receipts to the register of ""lots of other expenses"" in the Cur period.
		|	AND (DD.Recorder <> DD.DocumentInflow
		|		OR DD.LotCalculation
		|		OR (DD.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand),
		|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|			AND NOT DD.ThisIsLotOfOtherExpensesMaterialOverheadsForAllocation)
		|		)
		|	AND DD.DocumentInflow <> UNDEFINED
		|	AND ISNULL(Adjusting.Ref, DD.DocumentInflow) = DD.DocumentInflow
		|	AND (ISNULL(ReceiptOfServices.CorrectedDocument, UNDEFINED) <> DD.DocumentInflow
		|		OR DD.LotCalculation)
		|	AND ISNULL(ReverseVATAccrual.DocumentBasis, UNDEFINED) <> DD.DocumentInflow
		|	AND ISNULL(OBEntry.ReversedDocument, UNDEFINED) <> DD.DocumentInflow
		|	AND ISNULL(OBEntry.CorrectedDocument, UNDEFINED) <> DD.DocumentInflow
		|	AND VALUETYPE(DD.Recorder) <> TYPE(Document.ReversingEntry)
		// We exclude additional expenses from the sending organization - they are taken into account only by the receiving organization
		|	AND Transfer_.Ref IS NULL
		|	AND (DD.Cost <> 0 OR DD.CostExcludingVAT <> 0
		|		OR DD.LocalCost <> 0 OR DD.VATLocal <> 0 OR DD.VATManag <> 0)
		|
		|GROUP BY
		|	DD.Period,
		|	DD.Recorder,
		|	DD.Organization,
		|	DD.Department,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.DocumentInflow,
		|	DD.LotVendorAttributesOfReceiptDocument,
		|	DD.LineOfBusiness,
		|	DD.VATActivityType,
		|	DD.FinRecordID
		|";
EndFunction

Function TextWriteOffOfLotsOfOtherExpensesForAdditionalExpensesAmount()
	Return "
		|SELECT
		|	""TextWriteOffOfLotsOfOtherExpensesForAdditionalExpensesAmount"" AS RequestSource,
		|	10 AS Priority,
		|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
		|	TRUE AS CalculationIsCompleted,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	DD.Period,
		|	DD.Recorder,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		|	DD.Organization,
		|	DD.Department,
		|	DD.ExpenseItemAssets AS ExpenseItem,
		|	DD.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	DD.DocumentInflow AS ExpenseReceiptDocument,
		|	DD.LotVendorAttributesOfReceiptDocument AS LotVendorAttributes,
		|	DD.LineOfBusiness,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	DD.CorVATActivityTypes AS VATActivityType,
		|	DD.CorExpenseItem,
		|	DD.CorExpenditureDimension,
		|	DD.DebitBusinessUnit,
		|	DD.CorLineOfBusiness,
		|	UNDEFINED AS CorGroupOfManufacturedProducts,
		|	SUM(DD.CostInclVAT) AS Cost,
		|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(DD.CostExcludingVATLocal) AS LocalCost,
		|	SUM(CASE
		|		WHEN TRUE
		|		THEN DD.VATLocal
		|		ELSE 0
		|	END) AS VATLocal,
		|	SUM(CASE
		|		WHEN TRUE
		|		THEN DD.VATManag
		|		ELSE 0
		|	END) AS VATManag,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	DD.VATActivityType AS VATTaxation,
		|	(CASE
		// The conditions for filling in the business transaction settings must correspond to the conditions
		// in the textexclusionexclusionand Expenses() function.
		|		WHEN DD.VATActivityType <> DD.CorVATActivityTypes
		|		 AND DD.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		 AND DD.VATActivityType <> UNDEFINED
		|		 AND DD.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 AND DD.AccountingSection <> UNDEFINED
		|		 AND (DD.VATWriteOffItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				OR DD.VATWriteOffItem = UNDEFINED)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
		|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExpenseAllocationToCost)
		|		END) AS BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.ReversingEntry
		|FROM
		|	TTAdditionalCostsForItemByItemCosts AS DD
		|WHERE
		|	DD.EntryType IN (VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified))
		|	AND (DD.CostInclVAT <> 0 OR DD.CostExcludingVAT <> 0
		|		OR DD.CostExcludingVATLocal <> 0 OR DD.VATLocal <> 0
		|		OR DD.CostExcludingVATMan <> 0 OR DD.VATManag <> 0)
		|
		|GROUP BY
		|	DD.Period,
		|	DD.Recorder,
		|	DD.Organization,
		|	DD.Department,
		|	DD.ExpenseItemAssets,
		|	DD.DimensionOfExpenses,
		|	DD.DocumentInflow,
		|	DD.LotVendorAttributesOfReceiptDocument,
		|	DD.LineOfBusiness,
		|	DD.VATActivityType,
		|	DD.CorVATActivityTypes,
		|	(CASE
		|		WHEN DD.VATActivityType <> DD.CorVATActivityTypes
		|		 AND DD.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		 AND DD.VATActivityType <> UNDEFINED
		|		 AND DD.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 AND DD.AccountingSection <> UNDEFINED
		|		 AND (DD.VATWriteOffItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				OR DD.VATWriteOffItem = UNDEFINED)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
		|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ExpenseAllocationToCost)
		|		END), // BusinessTransactionSetting
		|	DD.FinRecordID,
		|	DD.ReversingEntry,
		|	DD.CorExpenseItem,
		|	DD.CorExpenditureDimension,
		|	DD.DebitBusinessUnit,
		|	DD.CorLineOfBusiness
		|";
EndFunction


#EndRegion


#Region StageProcedures_Contextual

// Used for all calls to fill in the billing batch.
//
Procedure FillInSettlementBatch(CalculationParameters, Context, SettlementBatch, Expense, Receipt, BatchIsFull) Export
	
	
EndProcedure

// This Data preparation for accounting and Accounting is necessary to verify the entry of the current stage
// into the group of data preparation stages for accounting and accounting.
// 
// Parameters:
//	Context - String - The context of the current stage.
//	
// Returns:
//  Boolean - True if the Context of the current stage is included in the group of data preparation stages for accounting and Accounting.
Function ThisIsPreparationOfDataForAccountingLBSiUSN(Context) Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction

#EndRegion


#Region CalculationSequences


// Sets whether it is necessary to distribute VAT and generate purchase/sales book entries in the specified period.
//
Procedure CreateTasksForVATAccountingMechanismsBatchAccounting22(CalculationParameters) Export
	
	If CalculationParameters.CalculationOption <> Enums.LotAndCostCalculationOptions.LotsAndCost Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CalculationParameters.SamplingRestrictions.NumberOfGnzRecords) Then
		// For debugging - calculation without changing the IB data
		Return;
	EndIf;
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text =
	"SELECT DISTINCT
	|	T.Organization AS Organization,
	|	T.VATActivityType AS VATActivityType,
	|	CASE
	|		WHEN NOT ISNULL(ExpenseItems.EnteredInTaxAccounting, TRUE) AND ISNULL(VATAccountingSettings.WriteOffVATByExpensesThatAreNotRecordedInTA, FALSE)
	|			AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|		THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE T.CorVATActivityTypes
	|	END AS CorVATActivityTypes,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products AS Products,
	|	CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Characteristic AS Characteristic
	|INTO TTCostOfGeneratingTasks
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS T
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Ref = T.ExpenseItemOfWriteOff
	|	LEFT JOIN TTVATAccountingSettings AS VATAccountingSettings
	|		ON VATAccountingSettings.Organization = T.Organization
	|INDEX BY
	|	Lot,
	|	LotVendorAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Prices.Lot AS Lot,
	|	Prices.Products AS Products,
	|	Prices.LotVendorAttributes AS LotVendorAttributes,
	|	Prices.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Prices.Characteristic AS Characteristic,
	|	Prices.Organization AS Organization,
	|	Prices.DocumentInflow AS DocumentInflow
	|INTO TT_CacheDetailingCostOfBatchOfGoods_Indexes
	|FROM
	|	TTDetailingCostOfBatchOfGoods_ AS Prices
	|WHERE
	|	(Prices.CostExcludingVATLocal <> 0
	|			OR Prices.VATLocal <> 0
	|			OR Prices.VATManag <> 0)
	|
	|INDEX BY
	|	Lot,
	|	LotVendorAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Prices.Lot AS Lot,
	|	Prices.Products AS Products,
	|	Prices.LotVendorAttributes AS LotVendorAttributes,
	|	Prices.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Prices.Characteristic AS Characteristic,
	|	Prices.Organization AS Organization,
	|	Prices.DocumentInflow AS DocumentInflow
	|INTO TT_CacheDetailingCostOfBatchOfGoodsItemByItemExpenses_Indexes
	|FROM
	|	TTCashDetailingCostOfBatchOfGoodsItemByItemCosts AS Prices
	|WHERE
	|	(Prices.CostExcludingVATLocal <> 0
	|			OR Prices.VATLocal <> 0
	|			OR Prices.VATManag <> 0)
	|
	|INDEX BY
	|	Lot,
	|	LotVendorAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization,
	|	T.AccountingSection AS AccountingSection,
	|	T.VATActivityType AS VATActivityType,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.CorVATActivityTypes AS CorVATActivityTypes
	|INTO TT_CacheEstimatedTurnoverOfInventoryCosts_Indexes
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS T
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Lot,
	|	LotVendorAttributes,
	|	InventoryOwnerAttribute,
	|	Organization,
	|	AccountingSection,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Prices.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Prices.Lot AS Lot,
	|	Prices.LotVendorAttributes AS LotVendorAttributes,
	|	Prices.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Prices.Organization AS Organization,
	|	Prices.AccountingSection AS AccountingSection,
	|	Prices.VATActivityType AS VATActivityType,
	|	Prices.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Prices.DocumentInflow AS DocumentInflow
	|INTO TT_CacheDetailsOfInventoryCostsItemByItemExpenses_Indexes
	|FROM
	|	TTCashDetailingCostOfGoodsItemByItemCosts AS Prices
	|WHERE
	|	(Prices.CostExcludingVATLocal <> 0
	|			OR Prices.VATLocal <> 0
	|			OR Prices.VATManag <> 0)
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Lot,
	|	LotVendorAttributes,
	|	InventoryOwnerAttribute,
	|	Organization,
	|	AccountingSection,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	&BeginOfPeriod AS Period,
	|	T.Organization AS Organization,
	|	T.VATActivityType AS VATActivityType,
	|	T.CorVATActivityTypes AS CorVATActivityTypes,
	|	T.TaxInvoice AS TaxInvoice
	|INTO TTBatchChange
	|FROM
	|	(
	|	SELECT DISTINCT
	|		T.Organization,
	|		T.VATActivityType,
	|		T.CorVATActivityTypes,
	|		Prices.DocumentInflow AS TaxInvoice
	|	FROM
	|		TTCostOfGeneratingTasks AS T
	|		INNER JOIN TT_CacheDetailingCostOfBatchOfGoods_Indexes AS Prices
	|		ON (Prices.Lot = T.Lot)
	|			AND (Prices.LotVendorAttributes = T.LotVendorAttributes)
	|			AND (Prices.Organization = T.Organization)
	|			AND (Prices.InventoryOwnerAttribute = T.InventoryOwnerAttribute)
	|			AND (Prices.Products = T.Products)
	|			AND (Prices.Characteristic = T.Characteristic)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		T.Organization,
	|		T.VATActivityType,
	|		T.CorVATActivityTypes,
	|		Prices.DocumentInflow
	|	FROM
	|		TTCostOfGeneratingTasks AS T
	|		INNER JOIN InformationRegister.ItemizeGoodsLotCost AS Prices
	|		ON (Prices.Lot = T.Lot)
	|			AND (Prices.LotVendorAttributes = T.LotVendorAttributes)
	|			AND (Prices.Organization = T.Organization)
	|			AND (Prices.InventoryOwnerAttribute = T.InventoryOwnerAttribute)
	|			AND (Prices.Products = T.Products)
	|			AND (Prices.Characteristic = T.Characteristic)
	|			AND (Prices.RegistrationPeriod < &BeginOfPeriod)
	|	WHERE
	|		(Prices.CostExcludingVATLocal <> 0 OR Prices.VATLocal <> 0 OR Prices.VATManag <> 0)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		T.Organization,
	|		T.VATActivityType,
	|		T.CorVATActivityTypes,
	|		Prices.DocumentInflow
	|	FROM
	|		TTCostOfGeneratingTasks AS T
	|		INNER JOIN TT_CacheDetailingCostOfBatchOfGoodsItemByItemExpenses_Indexes AS Prices
	|		ON (Prices.Lot = T.Lot)
	|			AND (Prices.LotVendorAttributes = T.LotVendorAttributes)
	|			AND (Prices.Organization = T.Organization)
	|			AND (Prices.InventoryOwnerAttribute = T.InventoryOwnerAttribute)
	|			AND (Prices.Products = T.Products)
	|			AND (Prices.Characteristic = T.Characteristic)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		T.Organization,
	|		T.VATActivityType,
	|		T.CorVATActivityTypes,
	|		Prices.DocumentInflow
	|	FROM
	|		TTCostOfGeneratingTasks AS T
	|		INNER JOIN InformationRegister.ItemizeLotCostItemizedAndOtherCosts AS Prices
	|		ON (Prices.Lot = T.Lot)
	|			AND (Prices.LotVendorAttributes = T.LotVendorAttributes)
	|			AND (Prices.Organization = T.Organization)
	|			AND (Prices.InventoryOwnerAttribute = T.InventoryOwnerAttribute)
	|			AND (Prices.Products = T.Products)
	|			AND (Prices.Characteristic = T.Characteristic)
	|			AND (Prices.RegistrationPeriod < &BeginOfPeriod)
	|	WHERE
	|		(Prices.CostExcludingVATLocal <> 0 OR Prices.VATLocal <> 0 OR Prices.VATManag <> 0)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		T.Organization,
	|		T.VATActivityType,
	|		T.CorVATActivityTypes,
	|		Prices.DocumentInflow
	|	FROM
	|		TT_CacheEstimatedTurnoverOfInventoryCosts_Indexes AS T
	|		INNER JOIN TT_CacheDetailsOfInventoryCostsItemByItemExpenses_Indexes AS Prices
	|		ON (Prices.ItemsLocationAttributes = T.ItemsLocationAttributes)
	|			AND (Prices.Lot = T.Lot)
	|			AND (Prices.LotVendorAttributes = T.LotVendorAttributes)
	|			AND (Prices.InventoryOwnerAttribute = T.InventoryOwnerAttribute)
	|			AND (Prices.Organization = T.Organization)
	|			AND (Prices.AccountingSection = T.AccountingSection)
	|			AND (Prices.FinancialAccountingDimension = T.FinancialAccountingDimension)
	|			AND (Prices.VATActivityType = T.VATActivityType)
	|	

	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		T.Organization,
	|		ISNULL(T.LotVendorAttributes.VATTaxation, VALUE(Enum.VATTaxationTypes.EmptyRef)),
	|		T.VATTaxation,
	|		T.ExpenseReceiptDocument
	|	FROM
	|		TTCashAndOtherExpenses AS T
	|	WHERE
	|		T.LocalCost <> 0 OR T.VATLocal <> 0 OR T.VATManag <> 0
	|
	|	) AS T
	|INDEX BY
	|	Organization,
	|	TaxInvoice,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_CacheDetailingCostOfBatchOfGoods_Indexes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_CacheDetailingCostOfBatchOfGoodsItemByItemExpenses_Indexes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_CacheEstimatedTurnoverOfInventoryCosts_Indexes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_CacheDetailsOfInventoryCostsItemByItemExpenses_Indexes
	|";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	If Not CostCalculationAppliedAlgorithms.EmptyTempTable(Query, "TTBatchChange") Then
		
		
		AccountingReflectionParameters = CostCalculationAppliedAlgorithms.InitializeReflectionParametersInAccounting(
			CalculationParameters,
			NStr("vi = 'Phản ánh vào sổ mua hàng và bán hàng';
				|ru = 'Отражение в книге покупок и продаж';
				|en = 'Recording in the purchase and sales ledger'; fa = 'Recording in the purchase and sales ledger';
				|it = 'Rilevazione nel libro di acquisti e vendite';
				|pl = 'Odzwierciedlenie w księdze zakupu i sprzedaży';
				|tr = 'Satın alma ve satış defterine yansıma'", Common.DefaultLanguageCode()),
			"VATAccountingLocalization.CreateTasksForCreatingBookOfPurchasesSales",
			"TTBatchChange",
			False,
			"Organization, TaxInvoice, Period");
			
		CostCalculationAppliedAlgorithms.ReflectDocumentsInAccounting(CalculationParameters, AccountingReflectionParameters);
		
	EndIf;
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(
		CalculationParameters,
		"TTCostOfGeneratingTasks, TTOldDataForVATAccountingMechanisms, TTBatchChange");
	
EndProcedure

#EndRegion


#Region SystemStateAnalysis

// Fills in checks that are performed as part of the batch and cost calculation.
//
// Parameters:
//	TableOfChecks - See AuditOfSystemState.SystemStateCheckTable
//
Procedure FillOutChecksForRegistration(TableOfChecks) Export
	
	// The correspondence of the balances in the registers of the cost of goods and the details of the party of goods in the country.
	// Technological verification for autotests, see the technological parameter "Check for compliance with the requirements of the Parties".
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"ComplianceOfCostRegistersAndVATLots",
		Catalogs.MonthEndClosingOperations.LotsAndCostCalculation,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.AfterCalculation,
		"VATCostCalculation.VerificationOfComplianceOfCostRegistersAndVATLots",
		Enums.AccountingIssueSeverity.Error);
	
	VerificationDescription.CanEditImportance = True;
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Tương ứng giữa số dư trong biểu ghi giá vốn và lô hàng gồm thuế GTGT.';
			|ru = 'Соответствие остатков в регистрах себестоимости и партий НДС.';
			|en = 'Correspondence of balance in the cost and VAT lots registers.'; fa = 'Correspondence of balance in the cost and VAT lots registers.';
			|it = 'Corrispondenza dei saldi nei registri del prezzo di costo e lotti IVA.';
			|pl = 'Zgodność z saldami w rejestrach kosztów i partiami VAT.';
			|tr = 'Maliyet kayıtları ve KDV lotlarındaki bakiyelerin uygunluğu.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Số dư theo biểu ghi ""Chi tiết lô hàng đối với thuế GTGT và ThGL"" cần tương ứng với số dư theo biểu ghi ""Giá vốn hàng hóa"":
			|- số dư theo số lượng trong biểu ghi lô hàng gồm thuế GTGT không được vượt quá số dư theo số lượng trong biểu ghi giá vốn
			|- không nên có số dư theo số tiền quy định. (Giá vốn không gồm thuế GTGT + thuế GTGT) trong biểu ghi lô hàng gồm thuế GTGT khi không có số dư theo số tiền quy định trong biểu ghi giá vốn (Giá vốn quy định + Chi phí bổ sung quy định)
			|- không nên có số dư theo số tiền quản trị trong biểu ghi lô hàng gồm thuế GTGT (thuế GTGT quản trị) khi không có số dư theo số tiền quản trị trong biểu ghi giá vốn (Giá vốn quản trị + Chi phí bổ sung quản trị)';
			|ru = 'Остатки по регистру ""Детализация партий товаров для НДС и УСН"" должны соответствовать остаткам по регистру ""Себестоимость товаров"":
			|- остатки по количеству в регистре партий НДС не должны превышать остатки по количеству в регистре себестоимости
			|- не должно быть остатков по суммам регл. (Стоимость без НДС + НДС) в регистре партий НДС при отсутствии остатков по суммам регл. в регистре себестоимости (Стоимость регл + Доп расходы регл)
			|- не должно быть остатков по суммам упр. в регистре партий НДС (НДС упр) при отсутствии остатков по суммам упр. в регистре себестоимости (Стоимость упр + Доп расходы упр)';
			|en = 'Balance in the ""Goods lot details for VAT and STS"" register must match the balance in the ""Inventory cost"" register:
			|- quantity balance in the VAT lot register must not exceed the quantity balance in the cost register
			|- the VAT lot register must not include the amount balance local (Cost excl. VAT + VAT) if the cost register does not include the amount balance local (Net initial cost, local + Additional expenses (local))
			|- the VAT lot register (VAT mgmt) must not include the amount balance mgmt if the cost register (Net initial cost, co. + Additional expenses (mgmt)) does not include the amount balance mgmt'; fa = 'Balance in the ""Goods lot details for VAT and STS"" register must match the balance in the ""Inventory cost"" register:
			|- quantity balance in the VAT lot register must not exceed the quantity balance in the cost register
			|- the VAT lot register must not include the amount balance local (Cost excl. VAT + VAT) if the cost register does not include the amount balance local (Net initial cost, local + Additional expenses (local))
			|- the VAT lot register (VAT mgmt) must not include the amount balance mgmt if the cost register (Net initial cost, co. + Additional expenses (mgmt)) does not include the amount balance mgmt';
			|it = 'I saldi da registro ""Specificazione lotti articoli per IVA e Sistema Fiscale Semplificato"" devono corrispondere ai saldi da registro ""Prezzo di costo degli articoli"":
			|La quantità di saldi nel registro lotti IVA non deve essere superiore ai saldi per quantità nel registro del prezzo di costo
			|- non devono esserci saldi da importi reg. (Costo IVA esclusa + IVA) nel registro lotti IVA in caso di assenza di saldi per importi reg. nel registro del prezzo di costo (Costo reg. + spese aggiuntive reg.)
			|- non devono esserci saldi da importi gest. nel registro del prezzo di costo (Costo gest + Spese aggiuntive gest)';
			|pl = 'Salda według rejestru ""Wyszczególnienie partii towarów dla VAT i uproszczonego systemu opodatkowania"" muszą być zgodne z saldami według rejestru ""Koszty własne towarów"":
			|- salda według ilości w rejestrze partii VAT nie powinny przekraczać sald według ilości w rejestrze kosztów własnych
			|- nie powinno być sald według kwot regl (Wartość netto + VAT) w rejestrze partii VAT w przypadku braku sald według kwot regl. w rejestrze kosztów własnych (Wartość regl + Rozchody dod. regl)
			|- nie powinno być sald według kwot zarz.. w rejestrze partii VAT (VAT zarz) w przypadku braku sald według kwot zarz. w rejestrze kosztów własnych (Wartość zarz. + Rozchody dod. zarz.)';
			|tr = '""KDV ve BVS için ürün gruplarının ayrıntısı"" kaydındaki bakiyeler, ""Stok maliyeti"" kaydındaki bakiyelere karşılık gelmelidir: 
			|- KDV gruplarının kaydındaki miktar bakiyeleri, malların maliyeti kaydındaki miktar bakiyelerini aşmamalıdır
			|- yerel muhasebe miktarlarında bakiye olmamalıdır. Maliyet kayıtlarında (Maliyet yerel + Ek giderler (yerel))
			| kontrol tutarlarının bakiyelerinin olmaması durumunda KDV lotlarının kaydında (KDV''siz maliyet + KDV) maliyet kayıtlarında (Maliyet yönetim + Ek giderler (yönetim)) kontrol tutarlarının bakiyelerinin olmaması durumunda KDV lotlarının kaydında (KDV kontrolü) kontrol tutarlarının bakiyelerinin olmaması gerekir'", Common.DefaultLanguageCode()));
	
	// Correspondence of balances in the registers of other expenses and lots of other expenses.
	// Technological verification for autotests, see the technological parameter "Check for the corresponding part of the total expenses".
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"ComplianceWithRegistersOtherExpensesAndLotsOfOtherExpenses",
		Catalogs.MonthEndClosingOperations.LotsAndCostCalculation,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.AfterCalculation,
		"VATCostCalculation.VerificationOfComplianceWithRegistersOtherExpensesAndOtherExpenses",
		Enums.AccountingIssueSeverity.Error);
	
	VerificationDescription.CanEditImportance = True;
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Đối chiếu giữa số dư trong biểu ghi chi phí khác và lô hàng trong chi phí khác.';
			|ru = 'Соответствие остатков в регистрах прочие расходы и партии прочих расходов.';
			|en = 'Correspondence of balance in the other expenses and material overheads for allocation registers.'; fa = 'Correspondence of balance in the other expenses and material overheads for allocation registers.';
			|it = 'Corrispondenza dei saldi nei registri altre spese e lotti di altre spese.';
			|pl = 'Zgodność sald w rejestrach inne koszty i partie innych kosztów.';
			|tr = 'Diğer giderler kayıtlarındaki ve diğer giderler lotlarındaki bakiyelerin uygunluğu.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Số dư theo biểu ghi ""Lô hàng của chi phí khác"" phải tương ứng với số dư theo biểu ghi ""Chi phí khác"":
			|- không nên có số dư trong biểu ghi lô hàng của chi phí khác khi không có số dư trong biểu ghi chi phí khác';
			|ru = 'Остатки по регистру ""Партии прочих расходов"" должны соответствовать остаткам по регистру ""Прочие расходы"":
			|- не должно быть остатков в регистре партий прочих расходов при отсутствии остатков по в регистре прочих расходов';
			|en = 'Balance in the ""Material overheads for allocation"" register must match the balance of the ""Other expenses"" register:
			|- the ""Material overheads for allocation"" register must not have balance if the ""Other expenses"" register does not have balance'; fa = 'Balance in the ""Material overheads for allocation"" register must match the balance of the ""Other expenses"" register:
			|- the ""Material overheads for allocation"" register must not have balance if the ""Other expenses"" register does not have balance';
			|it = 'I saldi del registro ""Lotti di altre spese"" devono corrispondere ai saldi del registro ""Altre spese"":
			|- non devono esserci saldi nel registro dei lotti di altre spese in caso di assenza di saldi nel registro altre spese';
			|pl = 'Salda według rejestru ""Partie innych rozchodów"" powinny być zgodne z saldami według rejestru ""Inne rozchody"":
			|- nie powinno być sald w rejestrze partii innych rozchodów w przypadku braku sald w rejestrze innych rozchodów';
			|tr = '""Diğer gider lotları"" kaydındaki bakiyeler ""Diğer giderler"" kaydındaki bakiyelere karşılık gelmelidir:
			|- diğer giderler kaydında bakiye yoksa diğer gider lotları kaydında da bakiye olmamalıdır'", Common.DefaultLanguageCode()));
	
EndProcedure

// The procedure is a handler for checking the status of the system "Compliance with the register of the highest values of the Parties".
//
// Parameters:
//	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
//
Procedure VerificationOfComplianceOfCostRegistersAndVATLots(CheckParameters) Export
	
	If CheckParameters.AdditionalParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	
	ParameterValues = CalculationOfCostCached.ValuesOfTechnologicalParameters();
	
	AutoTesting = MonthEndTransactionsServer.ValueOfAdditionalVerificationParameter(
		CheckParameters,
		"AutoTesting",
		False);
	
	// The check is performed if the corresponding technological parameters are explicitly enabled.
	If Not ParameterValues.CheckComplianceOfCostPriceAndVATBatches
	 And Not ParameterValues.CheckComplianceOfCostAndBatchesOfNdsfifoSliding
	 And Not AutoTesting Then
		Return;
	EndIf;
	
	QueryText =
	TableQueryTextForSelectingBatchAccountingAnalystsNDS2_4() + "
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|" + "
	|
	|SELECT TOP 0
	|	T.Ref
	|INTO TTProductionCostItems
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS T
	|INDEX BY
	|	Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	T.AccountingSection AS AccountingSection,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.CountBalance AS Count,
	|	T.LocalCostBalance + T.AddExpensesLocalBalance AS LocalCost,
	|	T.CostManBalance + T.AddExpensesManBalance AS CostMan
	|INTO TTCostPrice
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(
	|		&BorderEndOfPeriod,
	|		Organization IN (&CompanyArray)
	|		AND &BatchAccountingVersion22
	|		AND NOT Lot REFS Catalog.ProductionLots
	|		AND NOT Lot REFS Document.ProductionStage2_2
	|		AND NOT AccountingSection IN (
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
	|	) AS T
	|INDEX BY
	|	Lot,
	|	Organization,
	|	Products
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	T.AccountingSection AS AccountingSection,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.Count AS Count,
	|	T.LocalCost + T.AddExpensesLocal AS LocalCost,
	|	T.CostMan + T.AddExpensesMan AS CostMan
	|INTO TUEWriteOffOfLowValueMC
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|	INNER JOIN Document.InventoryCostCalculation AS Filter
	|		ON T.Recorder = Filter.Ref
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffLowCostInventoryAsExpensesInThePurchaseMonth)
	|
	|INDEX BY
	|	Lot,
	|	Organization,
	|	Products
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization AS Organization,
	|	MAX(T.RegistrationPeriod) AS RegistrationPeriod
	|INTO TransitionPeriod
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS T
	|WHERE
	|	T.RegistrationPeriod <= &BeginOfPeriod
	|	AND T.EntryType IN
	|		(VALUE(Enum.LotRecordTypes.InternalMigrationToDetailingCostOfGoodsRegister),
	|		 VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod))
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Organization IN (&SFIFOOrganizationsSliding)
	|	AND &BatchAccountingVersion22
	|	AND &CheckComplianceOfCostAndBatchesOfNdsfifoSliding
	|GROUP BY
	|	T.Organization
	|INDEX BY
	|	Organization
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Organization AS Organization,
	|	T.DocumentInflow AS DocumentInflow
	|INTO OldReceiptDocuments
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS T
	|	INNER JOIN TransitionPeriod AS Filter
	|		ON T.Organization = Filter.Organization
	|		AND T.RegistrationPeriod <= Filter.RegistrationPeriod
	|
	|UNION
	|
	|SELECT DISTINCT
	|	T.Organization,
	|	T.DocumentInflow
	|FROM
	|	InformationRegister.ItemizeGoodsCostItemizedAndOtherCosts AS T
	|	INNER JOIN TransitionPeriod AS Filter
	|		ON T.Organization = Filter.Organization
	|		AND T.Period <= Filter.RegistrationPeriod
	|INDEX BY
	|	DocumentInflow,
	|	Organization
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS RegisterNumber,
	|	T.Organization AS Organization,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	Balance.VATActivityType AS VATActivityType,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	T.DocumentInflow AS DocumentInflow,
	|	Balance.Count AS Count,
	|	CAST((T.CostExcludingVATLocal
	|		+ CASE
	|			WHEN Balance.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATLocal
	|			ELSE 0
	|		END) * Balance.Count AS NUMBER (31,2)) AS LocalCost,
	|	CAST((T.CostExcludingVATMan
	|		+ CASE
	|			WHEN Balance.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATManag
	|			ELSE 0
	|		END) * Balance.Count AS NUMBER (31,2)) AS CostMan
	|INTO TTPartyNDS2_4
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS T
	|	INNER JOIN TTCostPrice AS Balance
	|		ON T.Organization = Balance.Organization
	|		AND T.Products = Balance.Products
	|		AND T.Characteristic = Balance.Characteristic
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.Lot = Balance.Lot
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND (Balance.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|			OR Balance.ItemsLocationAttributes = T.WIPInventoryLocationAttributes)
	|WHERE
	|	T.RegistrationPeriod <= &BeginOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Organization IN (&CompaniesWithDetailedCosts)
	|	AND &BatchAccountingVersion22
	|	AND &CheckComplianceOfCostAndBatchesOfNdsfifoSliding
	|
	|UNION ALL
	|
	|SELECT
	|	2 AS RegisterNumber,
	|	T.Organization AS Organization,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	Balance.VATActivityType AS VATActivityType,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	T.DocumentInflow AS DocumentInflow,
	|	Balance.Count AS Count,
	|	CAST((T.CostExcludingVATLocal
	|		+ CASE
	|			WHEN Balance.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATLocal
	|			ELSE 0
	|		END) * Balance.Count AS NUMBER (31,2)) AS LocalCost,
	|	CAST((T.CostExcludingVATMan
	|		+ CASE
	|			WHEN Balance.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATManag
	|			ELSE 0
	|		END) * Balance.Count AS NUMBER (31,2)) AS CostMan
	|FROM
	|	InformationRegister.ItemizeLotCostItemizedAndOtherCosts AS T
	|	INNER JOIN TTCostPrice AS Balance
	|		ON T.Organization = Balance.Organization
	|		AND T.Products = Balance.Products
	|		AND T.Characteristic = Balance.Characteristic
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.Lot = Balance.Lot
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND (Balance.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|			OR Balance.ItemsLocationAttributes = T.WIPInventoryLocationAttributes)
	|	LEFT JOIN TTProductionCostItems AS ARTICLES__
	|		ON T.ExpenseItem = ARTICLES__.Ref
	|WHERE
	|	T.RegistrationPeriod <= &BeginOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Organization IN (&CompaniesWithDetailedCosts)
	|	AND ARTICLES__.Ref IS NULL
	|	AND &BatchAccountingVersion22
	|	AND &CheckComplianceOfCostAndBatchesOfNdsfifoSliding
	|
	|UNION ALL
	|
	|SELECT
	|	3 AS RegisterNumber,
	|	T.Organization AS Organization,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	Balance.VATActivityType AS VATActivityType,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	T.DocumentInflow AS DocumentInflow,
	|	Balance.Count AS Count,
	|	CAST((T.CostExcludingVATLocal
	|		+ CASE
	|			WHEN Balance.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATLocal
	|			ELSE 0
	|		END) * Balance.Count AS NUMBER (31,2)) AS LocalCost,
	|	CAST((T.CostExcludingVATMan
	|		+ CASE
	|			WHEN Balance.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN T.VATManag
	|			ELSE 0
	|		END) * Balance.Count AS NUMBER (31,2)) AS CostMan
	|FROM
	|	InformationRegister.ItemizeGoodsCostItemizedAndOtherCosts AS T
	|	INNER JOIN TTCostPrice AS Balance
	|		ON T.Organization = Balance.Organization
	|		AND T.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|		AND T.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND T.Lot = Balance.Lot
	|		AND T.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND T.AccountingSection = Balance.AccountingSection
	|		AND T.FinancialAccountingDimension = Balance.FinancialAccountingDimension
	|		AND T.VATActivityType = Balance.VATActivityType
	|	LEFT JOIN TTProductionCostItems AS ARTICLES__
	|		ON T.ExpenseItem = ARTICLES__.Ref
	|WHERE
	|	T.Period = &BeginOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Organization IN (&CompaniesWithDetailedCosts)
	|	AND ARTICLES__.Ref IS NULL
	|	AND T.EntryType = VALUE(Enum.LotRecordTypes.EmptyRef)
	|	AND &BatchAccountingVersion22
	|	AND &CheckComplianceOfCostAndBatchesOfNdsfifoSliding
	|INDEX BY
	|	DocumentInflow,
	|	Organization
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	SUM(T.QuantityCostPrice) AS QuantityCostPrice,
	|	SUM(T.CostLocalCost) AS CostLocalCost,
	|	SUM(T.CostOfManCost) AS CostOfManCost,
	|	SUM(T.CostOfLocalBatchVAT) AS CostOfLocalBatchVAT,
	|	SUM(T.CostOfManPartyVAT) AS CostOfManPartyVAT
	|INTO TTDivergenceOfCostsAndLotsNDS2_4
	|FROM
	|	(SELECT
	|		T.Organization,
	|		T.Lot,
	|		ISNULL(PartyAccountingAnalysts.Ref, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)) AS LotVendorAttributes,
	|		T.VATActivityType,
	|		T.ItemsLocationAttributes,
	|		T.InventoryOwnerAttribute,
	|		T.Count AS QuantityCostPrice,
	|		T.LocalCost AS CostLocalCost,
	|		T.CostMan AS CostOfManCost,
	|		0 AS CostOfLocalBatchVAT,
	|		0 AS CostOfManPartyVAT
	|	FROM
	|		TTCostPrice AS T
	|		LEFT JOIN TTSelectionOfPartyAccountingAnalyticsNDS2_4 AS PartyAccountingAnalysts
	|			ON T.LotVendorAttributes = PartyAccountingAnalysts.Ref
	|	WHERE
	|		&CheckComplianceOfCostAndBatchesOfNdsfifoSliding
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T.Organization,
	|		T.Lot,
	|		ISNULL(PartyAccountingAnalysts.Ref, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)) AS LotVendorAttributes,
	|		T.VATActivityType,
	|		T.ItemsLocationAttributes,
	|		T.InventoryOwnerAttribute,
	|		0 AS QuantityCostPrice,
	|		T.LocalCost AS CostLocalCost,
	|		T.CostMan AS CostOfManCost,
	|		0 AS CostOfLocalBatchVAT,
	|		0 AS CostOfManPartyVAT
	|	FROM
	|		TUEWriteOffOfLowValueMC AS T
	|		LEFT JOIN TTSelectionOfPartyAccountingAnalyticsNDS2_4 AS PartyAccountingAnalysts
	|			ON T.LotVendorAttributes = PartyAccountingAnalysts.Ref
	|	WHERE
	|		&CheckComplianceOfCostAndBatchesOfNdsfifoSliding
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T.Organization,
	|		T.Lot,
	|		T.LotVendorAttributes,
	|		T.VATActivityType,
	|		T.ItemsLocationAttributes,
	|		T.InventoryOwnerAttribute,
	|		0 AS QuantityCostPrice,
	|		0 AS CostLocalCost,
	|		0 AS CostOfManCost,
	|		T.LocalCost AS CostOfLocalBatchVAT,
	|		T.CostMan AS CostOfManPartyVAT
	|	FROM
	|		TTPartyNDS2_4 AS T
	|		LEFT JOIN OldReceiptDocuments AS Filter
	|			ON T.DocumentInflow = Filter.DocumentInflow
	|			AND T.Organization = Filter.Organization
	|	WHERE
	|		&CheckComplianceOfCostAndBatchesOfNdsfifoSliding
	|		AND Filter.DocumentInflow IS NULL) AS T
	|
	|GROUP BY
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.VATActivityType,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute
	|
	|HAVING
	|	(SUM(T.QuantityCostPrice) > 0
	|		AND SUM(T.CostLocalCost) >= 0
	|		AND SUM(T.CostLocalCost) + &ErrorValueCostLocal < SUM(T.CostOfLocalBatchVAT))
	|	OR
	|	(SUM(T.QuantityCostPrice) > 0
	|		AND SUM(T.CostOfManCost) >= 0
	|		AND SUM(T.CostOfManCost) + &ErrorValueCostOfMan < SUM(T.CostOfManPartyVAT))
	|;
	|";
	
	// Registration of discrepancies in quantity between cost registers and VAT batches 2.4.
	FieldList = New ValueList;
	FieldList.Add("Organization", 				NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Azienda';
														|pl = 'Organizacja';
														|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Lot",						NStr("vi = 'Lô hàng';
													|ru = 'Партия';
													|en = 'Lot'; fa = 'بچ';
													|it = 'Lotto';
													|pl = 'Partia';
													|tr = 'Lot'", Common.DefaultLanguageCode()));
	FieldList.Add("LotVendorAttributes",		NStr("vi = 'Đối tượng phân tích lô hàng';
													|ru = 'Аналитика партий';
													|en = 'Lot dimension'; fa = 'بُعد بچ';
													|it = 'Analisi dei lotti';
													|pl = 'Analityka partii';
													|tr = 'Lot boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("VATActivityType",			NStr("vi = 'Dạng hoạt động thuế GTGT';
													|ru = 'Вид деятельности НДС';
													|en = 'VAT activity type'; fa = 'نوع فعالیت مالیات بر ارزش افزوده';
													|it = 'Tipo di attività IVA';
													|pl = 'Rodzaj działalności VAT';
													|tr = 'Faaliyet türü KDV'", Common.DefaultLanguageCode()));
	FieldList.Add("ItemsLocationAttributes",	NStr("vi = 'Đối tượng phân tích kế toán mặt hàng';
													|ru = 'Аналитика учета номенклатуры';
													|en = 'Inventory location attributes'; fa = 'ویژگی‌های محل موجودی';
													|it = 'Analitica della registrazione degli articoli';
													|pl = 'Analityka ewidencji nomenklatury';
													|tr = 'Stok konum öznitelikleri'", Common.DefaultLanguageCode()));
	FieldList.Add("InventoryOwnerAttribute",					NStr("vi = 'Dạng vật tư';
																	|ru = 'Вид запасов';
																	|en = 'Inventory owner attributes'; fa = 'ویژگی‌های مالک موجودی';
																	|it = 'Tipologia di scorte';
																	|pl = 'Rodzaj pozycji';
																	|tr = 'Stok sahibinin öznitelikleri'", Common.DefaultLanguageCode()));
	FieldList.Add("CostLocalCost",	NStr("vi = 'Giá vốn tài chính (giá vốn)';
											|ru = 'Стоимость регл. (себестоимость)';
											|en = 'Local cost'; fa = 'بهای محلی';
											|it = 'Costo reg. (prezzo di costo)';
											|pl = 'Wartość regl. (koszt własny)';
											|tr = 'Net başlangıç maliyeti, yerel. (maliyet)'", Common.DefaultLanguageCode()));
	FieldList.Add("CostOfManCost",	NStr("vi = 'Giá vốn quản trị (giá vốn)';
											|ru = 'Стоимость упр. (себестоимость)';
											|en = 'Mgmt cost'; fa = 'بهای مدیریت';
											|it = 'Costo gest. (prezzo di costo)';
											|pl = 'Wartość zarz. (koszt własny)';
											|tr = 'Net başlangıç maliyeti, yönetim. (maliyet)'", Common.DefaultLanguageCode()));
	FieldList.Add("CostOfLocalBatchVAT",		NStr("vi = 'Giá vốn tài chính (lô hàng gồm thuế GTGT)';
													|ru = 'Стоимость регл. (партии НДС)';
													|en = 'Local cost (VAT lots)'; fa = 'Local cost (VAT lots)';
													|it = 'Costo reg. (lotti IVA)';
													|pl = 'Wartość regl. (partie VAT)';
													|tr = 'Net başlangıç maliyeti, yerel. (KDV lotları)'", Common.DefaultLanguageCode()));
	FieldList.Add("CostOfManPartyVAT",		NStr("vi = 'Giá vốn quản trị (lô hàng gồm thuế GTGT)';
													|ru = 'Стоимость упр. (партии НДС)';
													|en = 'Mgmt cost (VAT lots)'; fa = 'Mgmt cost (VAT lots)';
													|it = 'Costo gest. (lotti IVA)';
													|pl = 'Wartość zarz. (partie VAT)';
													|tr = 'Net başlangıç maliyeti, yönetim. (KDV lotları)'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTDivergenceOfCostsAndLotsNDS2_4",
		NStr("vi = 'Đã tìm thấy sự chênh lệch trong số tiền giữa biểu ghi giá vốn và chi tiết giá vốn lô hàng theo doanh nghiệp ""%1"" vào cuối kỳ %2';
			|ru = 'Обнаружены расхождения в суммах между регистрами себестоимости и детализации себестоимости партий товаров по организации ""%1"" на конец периода %2';
			|en = 'Discrepancies in amounts between the cost register and the goods lot cost details are detected in %1 company as of the %2 period end'; fa = 'Discrepancies in amounts between the cost register and the goods lot cost details are detected in %1 company as of the %2 period end';
			|it = 'Sono stati rilevati discrepanze tra gli importi dei registri del prezzo di costo e la specificazione del prezzo di costo dei lotti di articoli per l''azienda ""%1"" alla fine del periodo %2';
			|pl = 'Wykryto odchylenia w kwotach między rejestrami kosztów własnych i wyszczególnieniem kosztów własnych partii towarów według firmy ""%1"" na koniec okresu %2';
			|tr = '""%1"" iş yeri için %2 döneminin sonunda maliyet kayıtları ile parti mallar için kalemlere ayrılmış maliyet kayıtları arasında tutarsızlıklar bulunmuştur'", Common.DefaultLanguageCode()),
		FieldList,
		,
		Metadata.InformationRegisters.ItemizeGoodsLotCost.FullName());
	
		
	// Registration of problems.
	AddlParameters = New Structure;
	AddlParameters.Insert("TypesOfTaxationVATIsIncludedInCost", VATAccountingERP.ActivitiesVATIsIncludedInCost());
	AddlParameters.Insert("ErrorValueCostLocal", 		 ParameterValues.ErrorValueCostLocal);
	AddlParameters.Insert("ErrorValueCostOfMan", 		 ParameterValues.ErrorValueCostOfMan);
	AddlParameters.Insert("CheckComplianceOfCostPriceAndVATBatches", ParameterValues.CheckComplianceOfCostPriceAndVATBatches);
	If AutoTesting Then
		AddlParameters.Insert("CheckComplianceOfCostAndBatchesOfNdsfifoSliding", True);
	Else
		AddlParameters.Insert("CheckComplianceOfCostAndBatchesOfNdsfifoSliding", ParameterValues.CheckComplianceOfCostAndBatchesOfNdsfifoSliding);
	EndIf;
	
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters,
		QueryText,
		AddlParameters);
	
EndProcedure

// The procedure is a handler for checking the status of the system "Compliance with the registers of the expenses of the parties of the expenses".
//
// Parameters:
//	CheckParameters - Structure - verification parameters, See AuditOfSystemState.InitializeVerificationParameters.
//
Procedure VerificationOfComplianceWithRegistersOtherExpensesAndOtherExpenses(CheckParameters) Export
	
	If CheckParameters.AdditionalParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	
	ParameterValues = CalculationOfCostCached.ValuesOfTechnologicalParameters();
	
	// The check is performed if the corresponding technological parameter is explicitly enabled.
	If Not ParameterValues.VerifyComplianceOfOtherExpensesAndBatchesOfOtherExpenses Then
		Return;
	EndIf;
	
	QueryText = TextOfRequestForComplianceOtherExpensesAndLotsOfOtherExpenses();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TakeIntoAccountAdjustments", False);
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 			NStr("vi = 'Doanh nghiệp';
													|ru = 'Организация';
													|en = 'Company'; fa = 'Company';
													|it = 'Azienda';
													|pl = 'Organizacja';
													|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Department",			NStr("vi = 'Bộ phận';
												|ru = 'Подразделение';
												|en = 'Business unit'; fa = 'Business unit';
												|it = 'Reparto';
												|pl = 'Dział';
												|tr = 'Departman'", Common.DefaultLanguageCode()));
	FieldList.Add("LineOfBusiness",	NStr("vi = 'Lĩnh vực hoạt động';
											|ru = 'Направление деятельности';
											|en = 'Line of business'; fa = 'خط کسب‌وکار';
											|it = 'Settore di attività';
											|pl = 'Rodzaj działalności';
											|tr = 'İş kolu'", Common.DefaultLanguageCode()));
	FieldList.Add("ExpenseItem",			NStr("vi = 'Dạng chi phí';
												|ru = 'Статья расходов';
												|en = 'Expense item'; fa = 'قلم هزینه';
												|it = 'Voce di spese';
												|pl = 'Rodzaj kosztu';
												|tr = 'Gider kalemi'", Common.DefaultLanguageCode()));
	FieldList.Add("DimensionOfExpenses",		NStr("vi = 'Đối tượng phân tích chi phí';
													|ru = 'Аналитика расходов';
													|en = 'Expense dimension'; fa = 'بُعد هزینه';
													|it = 'Analitica delle uscite';
													|pl = 'Analityka kosztów';
													|tr = 'Gider boyutu'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTBalancesOfLotsOfOtherExpenses",
		NStr("vi = 'Đã tìm thấy số dư trong biểu ghi lô hàng có chi phí khác theo doanh nghiệp ""%1"" vào cuối kỳ %2';
			|ru = 'Обнаружены остатки в регистре партий прочих расходов по организации ""%1"" на конец периода %2';
			|en = 'Balance is detected in the material overheads for allocation register in %1 company as of the %2 period end'; fa = 'Balance is detected in the material overheads for allocation register in %1 company as of the %2 period end';
			|it = 'Sono stati rilevati saldi nel registro dei lotti di altre spese per l''azienda ""%1"" alla fine del periodo %2';
			|pl = 'Wykryto salda w rejestrze partii innych rozchodów według firmy ""%1"" na koniec okresu %2';
			|tr = 'Dönem %2sonunda ""%1"" iş yeri için diğer giderler partilerinin kaydında tespit edilen bakiyeler'", Common.DefaultLanguageCode()),
		FieldList,
		,
		Metadata.AccumulationRegisters.ItemisedExpensesLots.FullName());
		
	// Registration of problems.
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters,
		QueryText,
		AdditionalParameters);
	
EndProcedure

// Returns the text of the request for compliance with other expenses and lots of other expenses.
// 
// Returns:
//  String - Query text
//
Function TextOfRequestForComplianceOtherExpensesAndLotsOfOtherExpenses() Export
	
	QueryText = "
	|SELECT
	|	T.Ref AS Ref,
	|	CASE 
	|		WHEN T.CostAllocationOptionLocal IN (
	|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|				VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|			THEN 1
	|			ELSE 0
	|	END AS LocalCoefficient,
	|	CASE 
	|		WHEN T.CostAllocationOptionManag IN (
	|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|				VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|			THEN 1
	|			ELSE 0
	|	END AS ManSCoefficient
	|INTO TTSelectionOfItemOfMaterialOverheadsForALLOCATION
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS T
	|WHERE
	|	T.CostAllocationOptionManag IN (
	|		VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|		VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|	  AND T.SeparateVATAccountingOption <> VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|	OR T.CostAllocationOptionLocal IN (
	|		VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|		VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|	  AND T.SeparateVATAccountingOption <> VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|INDEX BY
	|	Ref
	|;
	|//////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument,
	|	T.LotVendorAttributes,
	|	T.ItemsLocationAttributes,
	|	T.VATActivityType,
	|	Filter.LocalCoefficient * T.LocalCostBalance AS LocalCost,
	|	Filter.LocalCoefficient * T.VATLocalBalance AS VATLocal,
	|	Filter.ManSCoefficient * T.VATManagBalance AS VATManag
	|INTO TTLotsOfOtherExpensesPreliminary
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots.Balance(
	|		&BorderEndOfPeriod,
	|		Organization IN (&CompanyArray)
	|		AND &BatchAccountingVersion22
	|	) AS T
	|	INNER JOIN TTSelectionOfItemOfMaterialOverheadsForALLOCATION AS Filter
	|		ON T.ExpenseItem = Filter.Ref
	|
	|UNION ALL
	|
	// To diagnose the Cur period, it is necessary to exclude the results of the procedure to adjust the initial statistics of the party and other expenses of the next period 
	// For the procedure to adjust the initial statistics of the party and other expenses, it is not necessary to take into account the results of the adjustment of the next period
	|SELECT
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument,
	|	T.LotVendorAttributes,
	|	T.ItemsLocationAttributes,
	|	T.VATActivityType,
	|	-Filter.LocalCoefficient * T.LocalCost AS LocalCost,
	|	-Filter.LocalCoefficient * T.VATLocal AS VATLocal,
	|	-Filter.ManSCoefficient * T.VATManag AS VATManag
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots AS T
	|	INNER JOIN TTSelectionOfItemOfMaterialOverheadsForALLOCATION AS Filter
	|		ON T.ExpenseItem = Filter.Ref
	|WHERE
	|	T.Period = &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.EntryType = VALUE(Enum.LotRecordTypes.InternalAdjustmentOfBalanceOfMaterialOverheadsForAllocation)
	|	AND NOT &TakeIntoAccountAdjustments
	|	AND &BatchAccountingVersion22
	|
	|UNION ALL
	|
	// To diagnose the Cur period, you need "real" Balances at the beginning of the period
	// For the procedure to adjust the initial statistics of the party and other expenses, it is necessary to obtain the Balances without taking into account the result of the previous adjustment of the Cur period
	|SELECT
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument,
	|	T.LotVendorAttributes,
	|	T.ItemsLocationAttributes,
	|	T.VATActivityType,
	|	-Filter.LocalCoefficient * T.LocalCost AS LocalCost,
	|	-Filter.LocalCoefficient * T.VATLocal AS VATLocal,
	|	-Filter.ManSCoefficient * T.VATManag AS VATManag
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots AS T
	|	INNER JOIN TTSelectionOfItemOfMaterialOverheadsForALLOCATION AS Filter
	|		ON T.ExpenseItem = Filter.Ref
	|WHERE
	|	T.Period = DATEADD(&BeginOfPeriod, SECOND, -1)
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.EntryType = VALUE(Enum.LotRecordTypes.InternalAdjustmentOfBalanceOfMaterialOverheadsForAllocation)
	|	AND &TakeIntoAccountAdjustments
	|	AND &BatchAccountingVersion22
	|
	|INDEX BY
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	Department,
	|	Organization,
	|	LineOfBusiness
	|;
	|//////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument,
	|	T.LotVendorAttributes,
	|	T.ItemsLocationAttributes,
	|	T.VATActivityType,
	|	SUM(T.LocalCost) AS LocalCost,
	|	SUM(T.VATLocal) AS VATLocal,
	|	SUM(T.VATManag) AS VATManag
	|INTO TTLotsOfOtherExpenses
	|FROM
	|	TTLotsOfOtherExpensesPreliminary AS T
	|GROUP BY
	|	T.Organization,
	|	T.Department,
	|	T.LineOfBusiness,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument,
	|	T.LotVendorAttributes,
	|	T.ItemsLocationAttributes,
	|	T.VATActivityType
	|HAVING
	|	SUM(T.LocalCost) <> 0
	|	OR SUM(T.VATLocal) <> 0
	|	OR SUM(T.VATManag) <> 0
	|
	|INDEX BY
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	Department,
	|	Organization,
	|	LineOfBusiness
	|;
	|//////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	Filter.LocalCoefficient * T.SumBalance AS Sum,
	|	Filter.LocalCoefficient * T.SumComplBalance AS SumCompl,
	|	Filter.ManSCoefficient * T.SumManBalance AS SumMan
	|INTO TTOtherExpenses_
	|FROM
	|	AccumulationRegister.OtherExpenses.Balance(
	|		&BorderEndOfPeriod,
	|		Organization IN (&CompanyArray)
	|		AND &BatchAccountingVersion22
	|		AND (Organization, Department, LineOfBusiness, ExpenseItem, DimensionOfExpenses) IN (
	|			SELECT
	|				Organization,
	|				Department,
	|				LineOfBusiness,
	|				ExpenseItem,
	|				DimensionOfExpenses
	|			FROM
	|				TTLotsOfOtherExpenses)
	|	) AS T
	|	INNER JOIN TTSelectionOfItemOfMaterialOverheadsForALLOCATION AS Filter
	|		ON T.ExpenseItem = Filter.Ref
	|INDEX BY
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	Department,
	|	Organization,
	|	LineOfBusiness
	|;
	|//////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization,
	|	T.Department,
	|	T.LineOfBusiness,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension,
	|	T.ExpenseReceiptDocument,
	|	T.LotVendorAttributes,
	|	T.ItemsLocationAttributes,
	|	T.VATActivityType,
	|	T.LocalCost,
	|	T.VATLocal,
	|	T.VATManag
	|INTO TTBalanceOfLotsOfOtherExpensesDetailed
	|FROM
	|	TTLotsOfOtherExpenses AS T
	|	LEFT JOIN TTOtherExpenses_ AS Filter
	|		ON T.ExpenseItem = Filter.ExpenseItem
	|		 AND T.DimensionOfExpenses = Filter.DimensionOfExpenses
	|		 AND T.Department = Filter.Department
	|		 AND T.Organization = Filter.Organization
	|		 AND T.LineOfBusiness = Filter.LineOfBusiness
	|WHERE
	|	((T.LocalCost <> 0 OR T.VATLocal <> 0) AND ISNULL(Filter.SumCompl, 0) = 0 AND ISNULL(Filter.Sum, 0) = 0)
	|	OR (T.VATManag <> 0 AND ISNULL(Filter.SumMan, 0) = 0 AND ISNULL(Filter.Sum, 0) = 0)
	|;
	|//////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization AS Organization,
	|	T.Department AS Department,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	SUM(T.LocalCost) AS LocalCost,
	|	SUM(T.VATLocal) AS VATLocal,
	|	SUM(T.VATManag) AS VATManag
	|
	|INTO TTBalancesOfLotsOfOtherExpenses
	|FROM
	|	TTBalanceOfLotsOfOtherExpensesDetailed AS T
	|GROUP BY
	|	T.Organization,
	|	T.Department,
	|	T.LineOfBusiness,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses
	|
	|INDEX BY
	|	Organization,
	|	ExpenseItem
	|";
	
	Return QueryText;
	
EndFunction


#EndRegion

#Region Testing

// Completes the list of calculation stages.
// 
// Parameters:
// 	StageList - ValueList - 
//
Procedure SupplementStagesWithDistributionOfBatches(StageList) Export
	
	StageList.Add("PreparationOfDataForAccountingLBSiUSN_AdditionalExpensesAmount");
	
EndProcedure

// Completes the list of calculation stages.
// 
// Parameters:
// 	StageList - ValueList - 
//
Procedure AddStagesWithBatchTranslation(StageList) Export
	
	StageList.Add("PreparationOfDataForBatchesOfOtherExpenses");

	
EndProcedure

// Completes the list of calculation stages.
// 
// Parameters:
// 	StageList - ValueList - 
//
Procedure ComplementStepsWithDataPreparationForFollowingSteps(StageList) Export
	
	StageList.Add("DistributionOfPartiesNdsfifoMoving");
	StageList.Add("GenerateValueOfVATLotsAtEndOfPeriod");
	StageList.Add("DistributionOfVATLotsAccordingToAdditionalExpenseAmounts");
	StageList.Add("IncludeExcludePersonalIncomeTaxCostAveragePerMonth");
	StageList.Add("IncludeExcludeNDSVCostMediumSlip");
	StageList.Add("IncludeExcludePersonalIncomeTaxCostAverageMoving_WriteOffForExpenses");
	
EndProcedure

Procedure RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText) Export
	
	If StageName_ = "PreparationOfDataForBatchesOfOtherExpenses" Then
		QueryText = RequestTextForLotsOfOtherExpenses(CalculationParameters);
		
	ElsIf StageName_ = "DistributionOfPartiesNdsfifoMoving" Then
		QueryText = QueryTextPreparationOfVATDistributionData(CalculationParameters);
		
	ElsIf StageName_ = "GenerateValueOfVATLotsAtEndOfPeriod" Then
		QueryText = QueryTextTTTurnoverCostOfBatchesVAT(CalculationParameters);
		
	ElsIf StageName_ = "DistributionOfVATLotsAccordingToAdditionalExpenseAmounts" Then
		QueryText = QueryTextForDistributionOfVATBatchesByAdditionalExpenseAMOUNT(CalculationParameters);
		
	ElsIf StageName_ = "CalculationOfDeviationOfFIFOIssueMovingAverage" Then
		QueryText = QueryTextCorrectionOfIssueDeviations(CalculationParameters);
		
	ElsIf StageName_ = "PreparationOfDataForAccountingLBSiUSN_AdditionalExpensesAmount" Then
		QueryText = QueryTextForBatchesOfPersonalIncomeTax_AdditionalExpenseAmount(CalculationParameters)
		
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
