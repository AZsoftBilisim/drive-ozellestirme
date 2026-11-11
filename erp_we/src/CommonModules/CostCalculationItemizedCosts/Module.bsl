// Procedures and functions of common modules are called:
//	- Calculation of the cost of the individual rhythms.
//	- Calculation of the cost of production

#Region Public
#Region DecryptionRequests_2_2

// Gets data for constructing a decoding of the base for allocating item-by-item expenses.
//
// Parameters:
//		Period - Date - the calculation period
//		CompanyArray - CatalogRef.Companies - array of organizations;
//		Recorder - DocumentRef.AllocationOfOtherCosts - the distribution document that the decryption is being built for
//		CostCalculationPerformed - Boolean - takes the value True if the cost calculation for the specified period was completed successfully.
//
// Returns:
//		TempTablesManager - tables for building a report.
//
Function DataForDecipheringSharesOfProductionCosts(Period, CompanyArray, Recorder, CostCalculationPerformed) Export
	
	CalculationParameters = CostCalculationProduction.InitializeDistributionDecryptionParameters(
		Period,
		CostCalculationAppliedAlgorithms.LinksOfOrganizationsUnderIntercampanyScheme(Period, CompanyArray),
		Recorder);
	
	StateOfCostCalculation = CostCalculationAppliedAlgorithms.CurStateOfCalculation(
		Period,
		CompanyArray,
		Catalogs.MonthEndClosingOperations.LotsAndCostCalculation);
	
	If StateOfCostCalculation = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully
	 Or StateOfCostCalculation = Enums.StatesOfMonthEndClosingOperations.NotRequired Then
		CalculationParameters.Insert("CostCalculationPerformed");
		CostCalculationPerformed = True;
	EndIf;
	
	DistributeSharesOfProductionCosts(CalculationParameters);
	
	Return CalculationParameters.TempTablesManager;
	
EndFunction

// Data for decoding direct production costs.
// 
// Parameters:
//		Period - Date - the calculation period
//		CompanyArray - CatalogRef.Companies - array of organizations;
//		Recorder - DocumentRef.AllocationOfOtherCosts - the distribution document that the decryption is being built for
//		CostCalculationPerformed - Boolean - takes the value True if the cost calculation for the specified period was completed successfully.
// 
// Returns: 
//		TempTablesManager - tables for building a report.
Function DataForDecodingDirectProductionCosts(Period, CompanyArray, Recorder, CostCalculationPerformed) Export
	
	CalculationParameters = CostCalculationProduction.InitializeDistributionDecryptionParameters(
		Period,
		CostCalculationAppliedAlgorithms.LinksOfOrganizationsUnderIntercampanyScheme(Period, CompanyArray),
		Recorder);
	
	StateOfCostCalculation = CostCalculationAppliedAlgorithms.CurStateOfCalculation(
		Period,
		CompanyArray,
		Catalogs.MonthEndClosingOperations.LotsAndCostCalculation);
	
	If StateOfCostCalculation = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully
	 Or StateOfCostCalculation = Enums.StatesOfMonthEndClosingOperations.NotRequired Then
		CalculationParameters.Insert("CostCalculationPerformed");
		CostCalculationPerformed = True;
	EndIf;
	
	DistributeDirectProductionCosts(CalculationParameters);
	
	Return CalculationParameters.TempTablesManager;
	
EndFunction

// Additional decryption data. expenses between Lot references of goods.
// 
// Parameters:
//		Period - Date - the calculation period
//		CompanyArray - CatalogRef.Companies - array of organizations;
//		Recorder - DocumentRef.AllocationOfOtherCosts - the distribution document that the decryption is being built for
//		CostCalculationPerformed - Boolean - takes the value True if the cost calculation for the specified period was completed successfully.
// 
// Returns: 
//		TempTablesManager - tables for building a report.
Function DataForDecodingAdditionalExpenseAmountBetweenShipmentsAndGoods(Period, CompanyArray, Recorder, CostCalculationPerformed) Export
	
	CalculationParameters = CostCalculationProduction.InitializeDistributionDecryptionParameters(
		Period,
		CostCalculationAppliedAlgorithms.LinksOfOrganizationsUnderIntercampanyScheme(Period, CompanyArray),
		Recorder);
	
	StateOfCostCalculation = CostCalculationAppliedAlgorithms.CurStateOfCalculation(
		Period, CompanyArray, Catalogs.MonthEndClosingOperations.LotsAndCostCalculation);
	
	If StateOfCostCalculation = Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully
	 Or StateOfCostCalculation = Enums.StatesOfMonthEndClosingOperations.NotRequired Then
		CalculationParameters.Insert("CostCalculationPerformed");
		CostCalculationPerformed = True;
	EndIf;
	
	DistributionOfAdditionalCostsBetweenPartiesAndGoods(CalculationParameters);
	
	Return CalculationParameters.TempTablesManager;
	
EndFunction

// Gets the data base of distribution of expenses for direct costs.
//
// Parameters:
//		Parameters - See Documents.AllocationOfOtherCosts.InitializeParametersOfDistributionOfExpensesForFinancial
//
// Returns:
//		TempTablesManager - table of the distribution base for direct costs.
//
Function PrepareCostBase(Parameters) Export
	
	CalculationParameters = Undefined;
	DebugParameters = Undefined;
	
	StartupParameters = New Structure(
		"Date, CompanyArray, GettingListOfParameters",
		Parameters.Period, Parameters.CompanyArray, True);
	
	CostCalculationAppliedAlgorithms.InitializeDebuggingOptions(DebugParameters, StartupParameters);
	CostCalculationAppliedAlgorithms.InitializeBatchCalculationParameters(StartupParameters, CalculationParameters, DebugParameters);
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text = 
		"SELECT TOP 0
		|	T.DocumentRegisterRecords				AS DocumentRegisterRecords,
		|	T.Period						AS Period,
		|
		|	T.Organization					AS Organization,
		|	T.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	T.AccountingSection					AS AccountingSection,
		|	T.Lot						AS Lot,
		|	T.LotVendorAttributes			AS LotVendorAttributes,
		|	T.FinancialAccountingDimension		AS FinancialAccountingDimension,
		|	T.VATActivityType			AS VATActivityType,
		|
		|	CAST(0 AS NUMBER (31, 10))	AS Cost,
		|	CAST(0 AS NUMBER (31, 10))	AS CostExcludingVAT,
		|	CAST(0 AS NUMBER (31, 10))	AS OffBalanceCost,
		|	CAST(0 AS NUMBER (31, 10))	AS AdditionalExpenseCost,
		|	CAST(0 AS NUMBER (31, 10))	AS AdditionalExpensesCostExcludingVAT,
		|	CAST(0 AS NUMBER (31, 10))	AS LaborCosts,
		|	CAST(0 AS NUMBER (31, 10))	AS ItemizedFixedCostsIncludingVAT,
		|	CAST(0 AS NUMBER (31, 10))	AS ItemizedFixedCostsExcludingVAT,
		|	CAST(0 AS NUMBER (31, 10))	AS ItemizedVariableCostsIncludingVAT,
		|	CAST(0 AS NUMBER (31, 10))	AS ItemizedVariableCostsExcludingVAT,
		|	CAST(0 AS NUMBER (31, 10))	AS LocalCost,
		|	CAST(0 AS NUMBER (31, 10))	AS OffBalanceCostLocal,
		|	CAST(0 AS NUMBER (31, 10))	AS CostInTaxAccounting,
		|	CAST(0 AS NUMBER (31, 10))	AS PermanentDifference,
		|	CAST(0 AS NUMBER (31, 10))	AS CostTD,
		|	CAST(0 AS NUMBER (31, 10))	AS CostOfPersonalIncomeTax,
		|	CAST(0 AS NUMBER (31, 10))	AS AddExpensesLocal,
		|	CAST(0 AS NUMBER (31, 10))	AS LaborCostsLocal,
		|	CAST(0 AS NUMBER (31, 10))	AS ItemizedFixedCostsCompl,
		|	CAST(0 AS NUMBER (31, 10))	AS ItemizedVariableCostsCompl,
		|	CAST(0 AS NUMBER (31, 10))	AS CostMan,
		|	CAST(0 AS NUMBER (31, 10))	AS AddExpensesMan,
		|	CAST(0 AS NUMBER (31, 10))	AS LaborCostsMan,
		|	CAST(0 AS NUMBER (31, 10))	AS ItemizedFixedCostsManag,
		|	CAST(0 AS NUMBER (31, 10))	AS ItemizedVariableCostsManag
		|INTO TTValueOfBatchesOfGoods
		|FROM
		|	AccumulationRegister.InventoryCost AS T";
	Query.Execute();
	
	CalculationParameters.Insert("CostCalculationPerformed", True);
	CalculationParameters.Insert("Recorder", Parameters.DocumentDistributions);
	
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters.TempTablesManager, "TTOvz") Then
		Query.Text = CostCalculationItemizedCosts.TextInTPOOvz();
		Query.Execute();
	EndIf;
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters.TempTablesManager, "TTAccountingPoliciesOfFinancialAccounting") Then
		AccountingPoliciesTaxSettings.SupplementTemporaryTableManagerWithCurrentParametersForAccountingPolicies(
			Metadata.InformationRegisters.FinancialAccountingPolicy.Name,
			CalculationParameters.TempTablesManager,
			CalculationParameters.PayrollPeriod.BeginOfPeriod,
			"TTAccountingPoliciesOfFinancialAccounting",
			CalculationParameters.CompanyArray);
	EndIf;
	
	Documents.AllocationOfOtherCosts.PrepareTablesForCalculation(CalculationParameters);
	ParametersForReceivingBatches = CostsServer.DescriptionOfParametersForReceivingActiveBatchesWithoutSpecifications();
	ParametersForReceivingBatches.BeginOfPeriod = CalculationParameters.PayrollPeriod.BeginOfPeriod;
	ParametersForReceivingBatches.PeriodEnding = CalculationParameters.PayrollPeriod.EndOfPeriod;
	ParametersForReceivingBatches.Companies = CalculationParameters.CompanyArray;
	
	CostsServer.FormActiveBatchesWithoutSpecifications(ParametersForReceivingBatches, CalculationParameters.TempTablesManager);
	// We will prepare a request.
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.SetParameter("CostCalculationPerformed", True);
	Query.SetParameter("DecodingDistribution", False);
	Query.SetParameter("IncludeProductionData21", True);
	Query.SetParameter("ConsiderFutureReleases", True);
	
	QueryText = ""
		+ CostCalculationFillingInformationAboutLots.TextCorrectedDocuments() + Common.QueryBatchSeparator() // CorrectedDocuments_
		+ TextIndicatorsOfDistributionByDivision()
		+ TextOfSelectionUnit(CalculationParameters)
		+ CostCalculationProduction.ProductionBatchText()
		+ CostCalculationProduction.TextEmptyBatchTableOfGNZPMaterials()
		+ CostCalculationProduction.TextOfShareOfCostByProduct()
		+ TextDataOnActualMaterialCosts(CalculationParameters)
		+ TextDataOnPreliminaryMaterialCosts(CalculationParameters)
		+ CostCalculationProduction.TextDataOnLaborCosts(CalculationParameters)
		+ TextDataOnLaborCostsCollapsed()
		+ CostCalculationProduction.TextOutputData()
		+ TextOutputDataCollapsed()
		+ TextBaseOfDistributionOfSharesByStages(CalculationParameters)
		+ TextCoefficientsOfBasesByStages()
		+ TextOfDatabaseByStagesIsSummarized();
		
	Query.Text = CostCalculationAppliedAlgorithms.InsertWeightAndVolumeTemplatesIntoQueryText(QueryText, "SN");
	
	For Each KeyAndValue In CalculationParameters.AdditionalStageRequestParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	Query.Execute();
	
	Return CalculationParameters;
	
EndFunction

#EndRegion
#Region CalculationStages

// Step 10.1 Distribution of deviations in value and differences in the adjustment of acquisitions of the previous period.
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure DistributeDeviationsInValue(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing
	 And Not CalculationParameters.DistributionOfAdditionalCostsBetweenPartiesAndGoods Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "DistributionOfDeviationsInCost");
	
	// Let's remember the existing temporary tables.
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	#Region RegisterRegisteredRecordsOfInventoryCosts
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		Undefined,
		Metadata.AccumulationRegisters.InventoryCost.Name);
	
	// 2. Getting the source data for the broadcast
	// 	- generates a temporary Data table.
	GetDataForDistributionOfDeviationsInValueCostOfGoods(CalculationParameters);
	
	// 3. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of cost of goods.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
	#EndRegion
	
	#Region RegisterRegisteredRecordsOfRevenueAndCostOfGoodsSold
	
	// 4. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		Undefined,
		Metadata.AccumulationRegisters.RevenueAndCOGS.Name);
	
	// 5. Getting the source data for the broadcast
	// 	- generates a temporary Data table.
	ObtainDataForDistributionOfDeviationsInCostRevenueAndCostOfSales(CalculationParameters);
	
	// 6. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of revenue and the value of sales.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
	#EndRegion
	
	#Region RegisterBasedRegisteredRecordsOtherExpenses
	
	// 7. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		Undefined,
		Metadata.AccumulationRegisters.OtherExpenses.Name);
	
	// 8. Getting the source data for the broadcast
	// 	- generates a temporary Data table.
	GetDataForDistributionOfDeviationsInCostOtherExpenses(CalculationParameters);
	
	// 9. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements by the register of other expenses.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
	#EndRegion
	
	#Region MovementsAccordingToRegisterOfPartyOfOtherExpenses
	
	// 7. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		Undefined,
		Metadata.AccumulationRegisters.ItemisedExpensesLots.Name);
	
	// 8. Getting the source data for the broadcast
	// 	- generates a temporary Data table.
	GetDataForDistributionOfDeviationsInCostOfBatchOfOtherExpenses(CalculationParameters);
	
	// 9. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of parties and other expenses.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
	#EndRegion
	
	#Region TrafficRegisteredRecordedByRegisteredRecordsItemIncomeExpenses
	
	// 10. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		Undefined,
		Metadata.AccumulationRegisters.RegisterRecordsProductsIncomeExpenses.Name);
	
	// 11. Getting the source data for the broadcast
	// 	- generates a temporary Data table.
	GetDataForDistributionOfDeviationsInCostProductsIncomeExpenses(CalculationParameters);
	
	// 12. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of movementnotable income expenses.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
	#EndRegion
	
	#Region RegisterRegisteredRecordsOtherAssetsLiabilities
	
	// Initializing the data structure for the calculation
	//	- forms the structure of the calculation parameters.The distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		Undefined,
		Metadata.AccumulationRegisters.OtherAssetsLiabilities.Name);
	
	// Getting the source data for the broadcast
	// 	- generates a temporary Data table.
	GetDataForDistributionOfDeviationsInValueOfOtherAssetsLiabilities(CalculationParameters);
	
	// Putting data into a receiver table and clearing auxiliary temporary tables.
	// 	- generates Registered Records for the register of other active arrays.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
	#EndRegion
	
	#Region RegisteredRecordsOfRegisteredRecordsOfOtherAssetsLiabilities
	
	// Initializing the data structure for the calculation
	//	- forms the structure of the calculation parameters.The distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		Undefined,
		Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
	
	// Getting the source data for the broadcast
	// 	- generates a temporary Data table.
	ToObtainDataForDistributionOfDeviationsInCostOfRegisteringRecordsForOtherAssetsLiabilities(CalculationParameters);
	
	// Putting data into a receiver table and clearing auxiliary temporary tables.
	// 	- generates Register Records by the register of movementprochim active arrays.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
	#EndRegion
	
	#Region Saving_IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods

	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text =
	"SELECT
	|	*
	|INTO IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriodsDeviationsInCost
	|FROM
	|	IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS T";
	
	Query.Execute();
	
	#EndRegion
	
	// We will destroy the auxiliary temporary tables created at this stage of the calculation.
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(
		CalculationParameters,
		ExistingTT + ", IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriodsDeviationsInCost");
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
EndProcedure

// Step 10.2 Allocation of item-by-item costs to the cost of goods.
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure DistributionOfAdditionalCostsBetweenPartiesAndGoods(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing
	 And Not CalculationParameters.DistributionOfAdditionalCostsBetweenPartiesAndGoods Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "DistributionOfAdditionalCostsBetweenPartiesAndGoods");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		TableForAllocationOfAdditionalCosts(CalculationParameters),
		, // RegisterName
		"SharesOfAdditionalExpenses",
		"Recorder", // IndexingFields
		"ProductReceivers, IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods");
	
	// 2. Obtaining the initial data for the calculation
	// 	- generates a temporary Data table.
	GetDataForAdditionalExpenses(CalculationParameters);
	
	// 3. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates a temporary table for additional expenses.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure

// Step 7 (Context: "Calculation of the total cost distributionprochichsatrats")
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure CalculationOfSharesOfDistributionOfOtherCosts(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "CalculationOfSharesOfDistributionOfOtherCosts");
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, 
		"TTShareOfDistributionOfOtherCosts");

	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	Query.Text = RequestTextForCalculatingSharesOfDistributionOfOtherCosts();
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);

EndProcedure


// Step 14.2 (Context: "Ovsyshcher")
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
// Generates temporary tables in the input data of the nodes of the transits of the inputs between the outputs and the transits of the outputs between the outputs.
//
Procedure CalculationOfHIATransits(CalculationParameters) Export
	
	If Not GetFunctionalOption("UseAccountingByExpenseObjects") Then
		Return;
	EndIf;

	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, 
		"TTInitialDataOfTransitNodesOfExpendituresBetweenHIA,TTTransitOfExpensesBetweenHIA");
		
	Query = New Query;
	
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text = TextValuesOfDistributionIndicatorsForHIA();
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True, "ValuesOfHIAIndicators");
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "CalculationOfHIATransits");
	
	RequestTextExData =
	"SELECT
	|	DD.Ref AS DocumentRegisterRecords,
	|	DD.ManagementAccounting AS ManagementAccounting,
	|	DD.LocalAccounting AS LocalAccounting,
	|	ISNULL(DD.Factor, &IndicatorField) AS Factor,
	|	CAST(DD.DimensionOfExpenses AS Catalog.CostCenters) AS ConstCenter,
	|	CAST(
	|		CASE 
	|			WHEN DD.AllocateToCostCenter AND DD.CostShareToCostCenters = 0 THEN 1 
	|			WHEN DD.AllocateToCostCenter THEN DD.CostShareToCostCenters 
	|			ELSE 0 
	|		END 
	|	AS NUMBER(28, 10)) AS ShareInHIA,
	|	CAST(
	|		CASE 
	|			WHEN DD.AllocateToExpenseItems THEN DD.CostShareToExpenseItems 
	|			ELSE 0 
	|		END 
	|	AS NUMBER(28, 10)) AS ShareOnArticles,
	|	CAST(
	|		CASE 
	|			WHEN DD.LeaveAsWIP THEN DD.CostShareOfWIP 
	|			ELSE 0 
	|		END 
	|	AS NUMBER(28, 10)) AS ShareInUnfinishedProduction,
	|	CAST(
	|		CASE 
	|			WHEN DD.AllocateToCostCenter AND DD.CostShareToCostCenters = 0 THEN 1 
	|			WHEN DD.AllocateToCostCenter THEN DD.CostShareToCostCenters 
	|			ELSE 0 
	|		END 
	|		+ CASE 
	|			WHEN DD.AllocateToExpenseItems THEN DD.CostShareToExpenseItems 
	|			ELSE 0 
	|		END 
	|		+ CASE 
	|			WHEN DD.LeaveAsWIP THEN DD.CostShareOfWIP 
	|			ELSE 0 
	|		END 
	|	AS NUMBER(28, 10)) AS AmountOfShares
	|INTO CurrentHIAData
	|FROM 
	|	TTOvz AS T
	|INNER JOIN
	|	Document.AllocationOfOtherCosts AS DD
	|ON
	|	DD.DimensionOfExpenses = T.ConstCenter
	|	AND DD.Organization = T.Organization
	|	AND DD.Department = T.Department
	|WHERE 
	|	&ConditionCurrentHIAData AND DD.Posted AND BEGINOFPERIOD(DD.Date, MONTH) = &BeginOfPeriod
	|;
	|
	|SELECT DISTINCT
	|	T.LineOfBusiness	AS LineOfBusiness,
	|	T.ExpenseItem			AS ExpenseItem
	|INTO PromTTCacheSetAnalyst
	|FROM
	|	TTCashSettlementBalancesOtherExpenses AS T
	|INNER JOIN
	|	TTOvz AS TTOvz
	|ON T.DimensionOfExpenses = TTOvz.ConstCenter
	|INNER JOIN
	|	ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|ON
	|	T.ExpenseItem = ARTICLES__.Ref
	|WHERE 
	|	&ConditionTTForAnalyticsSet
	|
	|UNION
	|
	|SELECT DISTINCT
	|	T.CorLineOfBusiness	AS LineOfBusiness,
	|	T.ExpenseItemOfWriteOff		AS ExpenseItem
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS T
	|INNER JOIN
	|	TTOvz AS TTOvz
	|ON T.DimensionOfExpenses = TTOvz.ConstCenter
	|INNER JOIN
	|	ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|ON
	|	T.ExpenseItemOfWriteOff = ARTICLES__.Ref
	|WHERE 
	|	T.BusinessOperation IN (VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand),
	|								VALUE(Enum.BusinessTransactions.GoodsConsumption))
	|	AND &ConditionTTForAnalyticsSet
	|;
	|
	|SELECT DISTINCT
	|	RECORDAUTONUMBER()			AS DataKey,
	|	T.LineOfBusiness	AS LineOfBusiness,
	|	T.ExpenseItem			AS ExpenseItem
	|INTO TTCacheAnalyst
	|FROM
	|	PromTTCacheSetAnalyst AS T
	|;
	|
	|SELECT 
	|	AnalyticsSuite.DataKey	AS DataKey,
	|	TTOvz.NodeNumber				AS NodeNumber
	|INTO TTExpensesForTransitBetweenHIAEx
	|FROM
	|	TTCashSettlementBalancesOtherExpenses AS T
	|INNER JOIN
	|	TTOvz AS TTOvz
	|ON T.DimensionOfExpenses = TTOvz.ConstCenter
	|INNER JOIN
	|	TTCacheAnalyst AS AnalyticsSuite
	|ON AnalyticsSuite.ExpenseItem = T.ExpenseItem
	|	AND AnalyticsSuite.LineOfBusiness = T.LineOfBusiness
	|
	|UNION
	|
	|SELECT DISTINCT 
	|	AnalyticsSuite.DataKey	AS DataKey,
	|	TTOvz.NodeNumber				AS NodeNumber
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS T
	|INNER JOIN
	|	TTOvz AS TTOvz
	|ON T.DimensionOfExpenses = TTOvz.ConstCenter
	|INNER JOIN
	|	TTCacheAnalyst AS AnalyticsSuite
	|ON AnalyticsSuite.ExpenseItem = T.ExpenseItemOfWriteOff
	|	AND AnalyticsSuite.LineOfBusiness = T.CorLineOfBusiness
	|
	|INDEX BY
	|	DataKey,
	|	NodeNumber
	|;
	|
	|SELECT 
	|	DD.DocumentRegisterRecords			AS DocumentRegisterRecords,
	|	DD.ConstCenter						AS OVZ_Source,
	|	Sources.NodeNumber			AS SourceNodeNumber_,
	|	T.ConstCenter						AS OVZ_Receiver,
	|	Destinations.NodeNumber			AS ReceiverNodeNumber_,
	|	T.IndicatorValue		AS Weight
	|INTO TTFullHIAGraph
	|FROM CurrentHIAData AS DD
	|	INNER JOIN ValuesOfHIAIndicators AS T
	|	ON DD.Factor = T.Factor
	|	INNER JOIN TTOvz AS Sources
	|	ON DD.ConstCenter = Sources.ConstCenter
	|	INNER JOIN TTOvz AS Destinations
	|	ON T.ConstCenter = Destinations.ConstCenter
	|WHERE Sources.Organization = Destinations.Organization
	|;
	|";
	
	TextOfGetTransitRequest = "
	|SELECT 
	|	T.IterationNumber,
	|	HIASettings.DocumentRegisterRecords,
	|	ExhOvz.Organization,
	|	ExhOvz.Department,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	ExhOvz.ConstCenter AS DimensionOfExpenses,
	|	CorOVZ.Organization AS CorCompany,
	|	CorOVZ.Department AS DebitBusinessUnit,
	|	CorOVZ.ConstCenter AS CorExpenditureDimension,
	|	ValuesOfHIAIndicators.IndicatorValue AS Weight,
	|	ValuesOfHIAIndicators.IndicatorValue*HIASettings.ShareInHIA AS LedWeight
	|INTO PromTTTransitCostsBetweenHIA
	|FROM TTCostRoutes AS T
	|LEFT JOIN
	|	TTCacheAnalyst AS DD
	|	ON DD.DataKey = T.DataKey
	|INNER JOIN
	|	TTOvz AS ExhOvz
	|	ON T.SourceNodeNumber_ = ExhOvz.NodeNumber
	|INNER JOIN
	|	TTOvz AS CorOVZ
	|	ON T.ReceiverNodeNumber_ = CorOVZ.NodeNumber
	|INNER JOIN
	|	CurrentHIAData AS HIASettings
	|	ON ExhOvz.ConstCenter = HIASettings.ConstCenter
	|INNER JOIN
	|	ValuesOfHIAIndicators AS ValuesOfHIAIndicators
	|	ON HIASettings.Factor = ValuesOfHIAIndicators.Factor
	|	AND CorOVZ.ConstCenter = ValuesOfHIAIndicators.ConstCenter
	|WHERE
	|	HIASettings.ShareInHIA <> 0
	|;
	|
	|SELECT
	|	DD.Organization,
	|	DD.Department,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	DD.Weight,
	|	DD.LedWeight
	|INTO PromTTInitialDataOfTransitNodesCostsBetweenHIA
	|FROM PromTTTransitCostsBetweenHIA AS DD
	|UNION ALL
	|SELECT
	|	DD.CorCompany,
	|	DD.DebitBusinessUnit,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.CorExpenditureDimension,
	|	0,
	|	0
	|FROM PromTTTransitCostsBetweenHIA AS DD
	|;
	|
	|SELECT
	|	DD.Organization,
	|	DD.Department,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	SUM(DD.Weight) AS Weight,
	|	SUM(DD.LedWeight) AS LedWeight
	|INTO TTInitialDataOfTransitNodesOfExpendituresBetweenHIA
	|FROM PromTTInitialDataOfTransitNodesCostsBetweenHIA AS DD
	|GROUP BY
	|	DD.Organization,
	|	DD.Department,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses
	|;
	|
	|SELECT
	|	DD.IterationNumber,
	|	DD.DocumentRegisterRecords,
	|	DD.Organization,
	|	DD.Department,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.CorCompany,
	|	DD.DebitBusinessUnit,
	|	DD.CorExpenditureDimension,
	|	DD.Weight,
	|	DD.LedWeight
	|INTO TTTransitOfExpensesBetweenHIA
	|FROM PromTTTransitCostsBetweenHIA AS DD
	|INDEX BY
	|	DocumentRegisterRecords,
	|	Organization,
	|	Department,
	|	LineOfBusiness,
	|	ExpenseItem,
	|	DimensionOfExpenses";
	
	GraphParameters = New Structure("InitialDataTable, RelationshipDataSourceTable, NameOfResultTable",
		New Structure("TableName, NameOfNodeNumberColumn, NameOfDataKeyColumn", 
			"TTExpensesForTransitBetweenHIAEx",
			"NodeNumber",
			"DataKey"),
		New Structure("TableName, ColumnNameOfSourceNodeNumber, ColumnNameOfReceiverNodeNumber", 
			"TTFullHIAGraph",
			"SourceNodeNumber_",
			"ReceiverNodeNumber_"),
		"TTCostRoutes");

	// Man
	QueryText = RequestTextExData;
	QueryText = StrReplace(QueryText, "&IndicatorField", "T.CostAllocationRuleManag");
	QueryText = StrReplace(QueryText, "&ConditionCurrentHIAData", "DD.ManagementAccounting");
	QueryText = StrReplace(QueryText, "&ConditionTTForAnalyticsSet",
		"TTOvz.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|	AND ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters)");
	Query.Text = QueryText;
	Query.Execute();
	
	CostCalculationAppliedAlgorithms.RoutingDataByGraph(Query.TempTablesManager, GraphParameters);
	
	QueryText = TextOfGetTransitRequest;
	QueryText = StrReplace(QueryText, "INTO TTInitialDataOfTransitNodesOfExpendituresBetweenHIA", 
		"INTO TTInitialDataOfTransitNodesOfExpendituresBetweenHIAMan");
	QueryText = StrReplace(QueryText, "INTO TTTransitOfExpensesBetweenHIA", 
		"INTO TTTransitCostsBetweenHIAMan");
	Query.Text = QueryText;
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True, 
		"TTTransitCostsBetweenHIAMan,TTInitialDataOfTransitNodesOfExpendituresBetweenHIAMan");
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"CurrentHIAData, TTFullHIAGraph, TTExpensesForTransitBetweenHIAEx, TTCostRoutes, TTCacheAnalyst, 
		|PromTTCacheSetAnalyst, PromTTTransitCostsBetweenHIA, PromTTInitialDataOfTransitNodesCostsBetweenHIA");
		
	// Compl
	QueryText = RequestTextExData;
	QueryText = StrReplace(QueryText, "&IndicatorField", "T.CostAllocationRuleLocal");
	QueryText = StrReplace(QueryText, "&ConditionCurrentHIAData", "DD.LocalAccounting");
	QueryText = StrReplace(QueryText, "&ConditionTTForAnalyticsSet",
		"TTOvz.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|	AND ARTICLES__.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCostCenters)");
	Query.Text = QueryText;
	Query.Execute();
	
	CostCalculationAppliedAlgorithms.RoutingDataByGraph(Query.TempTablesManager, GraphParameters);
	
	QueryText = TextOfGetTransitRequest;
	QueryText = StrReplace(QueryText, "INTO TTInitialDataOfTransitNodesOfExpendituresBetweenHIA", 
		"INTO TTRawDataOfTransitNodesCostsBetweenHIALocal");
	QueryText = StrReplace(QueryText, "INTO TTTransitOfExpensesBetweenHIA", 
		"INTO TTTransitCostsBetweenHIALocal");
	Query.Text = QueryText;
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True, 
		"TTTransitCostsBetweenHIALocal,TTRawDataOfTransitNodesCostsBetweenHIALocal");
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"TTFullHIAGraph, TTExpensesForTransitBetweenHIAEx, TTCostRoutes, TTCacheAnalyst, 
		|PromTTCacheSetAnalyst, PromTTTransitCostsBetweenHIA, PromTTInitialDataOfTransitNodesCostsBetweenHIA");
	
	Query.Text = CalculationOfCostLocalization.AITSettingsQueryText("", "CostCalculationItemByItemExpenses_TransitCalculationCostCenters", CalculationParameters);
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True, 
		"AITExpenseRecognitionSettings,");
	
	Query.Text = "
	|SELECT
	|	RECORDAUTONUMBER() AS NodeNumber,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	SUM(DD.Weight) AS Weight,
	|	SUM(DD.LocalWeight) AS LocalWeight,
	|	SUM(DD.LedWeight) AS LedWeight,
	|	SUM(DD.LocalWeightGiven) AS LocalWeightGiven,
	|	SUM(CASE
	|		WHEN SettingsForRecognitionOfLBExpensesByBusinessUnit.ExpenseRecognitionOption IS NULL
	|				AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ExpenseRecognitionOption IS NULL
	|			THEN 0
	|		ELSE DD.LocalWeight
	|	END) AS NDTWeight,
	|	SUM(CASE
	|		WHEN SettingsForRecognitionOfLBExpensesByBusinessUnit.ExpenseRecognitionOption IS NULL
	|				AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ExpenseRecognitionOption IS NULL
	|			THEN 0
	|		ELSE DD.LocalWeightGiven
	|	END) AS GivenWeightOfNDT
	|INTO TTInitialDataOfTransitNodesOfExpendituresBetweenHIA
	|FROM (
	|	SELECT
	|		DD.Organization,
	|		DD.Department,
	|		DD.LineOfBusiness,
	|		DD.ExpenseItem,
	|		DD.DimensionOfExpenses,
	|		DD.Weight AS Weight,
	|		0 AS LocalWeight,
	|		DD.LedWeight AS LedWeight,
	|		0 AS LocalWeightGiven
	|	FROM TTInitialDataOfTransitNodesOfExpendituresBetweenHIAMan AS DD
	|	UNION
	|	SELECT
	|		DD.Organization,
	|		DD.Department,
	|		DD.LineOfBusiness,
	|		DD.ExpenseItem,
	|		DD.DimensionOfExpenses,
	|		0 AS Weight,
	|		0 AS LocalWeight,
	|		DD.Weight*(T.ShareOnArticles + T.ShareInUnfinishedProduction) AS LedWeight,
	|		0 AS LocalWeightGiven
	|	FROM TTInitialDataOfTransitNodesOfExpendituresBetweenHIAMan AS DD
	|	LEFT JOIN CurrentHIAData AS T
	|	ON
	|		DD.DimensionOfExpenses = T.ConstCenter AND T.ManagementAccounting
	|	UNION
	|	SELECT
	|		DD.Organization,
	|		DD.Department,
	|		DD.LineOfBusiness,
	|		DD.ExpenseItem,
	|		DD.DimensionOfExpenses,
	|		0 AS Weight,
	|		DD.Weight AS LocalWeight,
	|		0 AS LedWeight,
	|		DD.LedWeight AS LocalWeightGiven
	|	FROM TTRawDataOfTransitNodesCostsBetweenHIALocal AS DD
	|	UNION
	|	SELECT
	|		DD.Organization,
	|		DD.Department,
	|		DD.LineOfBusiness,
	|		DD.ExpenseItem,
	|		DD.DimensionOfExpenses,
	|		0 AS Weight,
	|		0 AS LocalWeight,
	|		0 AS LedWeight,
	|		DD.Weight*(T.ShareOnArticles + T.ShareInUnfinishedProduction) AS LocalWeightGiven
	|	FROM TTRawDataOfTransitNodesCostsBetweenHIALocal AS DD
	|	LEFT JOIN CurrentHIAData AS T
	|	ON
	|		DD.DimensionOfExpenses = T.ConstCenter AND T.LocalAccounting
	|) AS DD
	|	
	|	LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesByBusinessUnit
	|	ON SettingsForRecognitionOfLBExpensesByBusinessUnit.ObjectOfSeparateAccountingAIT = DD.Department
	|		AND SettingsForRecognitionOfLBExpensesByBusinessUnit.Organization = DD.Organization
	|		AND SettingsForRecognitionOfLBExpensesByBusinessUnit.ExpensesAreIncludedInCost
	|
	|	LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfExpensesLBDpoLineOfBusiness
	|	ON SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ObjectOfSeparateAccountingAIT = DD.LineOfBusiness
	|		AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.Organization = DD.Organization
	|		AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ExpensesAreIncludedInCost
	|
	|GROUP BY
	|	DD.Organization,
	|	DD.Department,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses
	|INDEX BY
	|	Organization,
	|	Department,
	|	LineOfBusiness,
	|	ExpenseItem,
	|	DimensionOfExpenses
	|;
	|
	|SELECT
	|	DD.DocumentRegisterRecords AS DocumentRegisterRecords,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	DD.CorCompany AS CorCompany,
	|	DD.DebitBusinessUnit AS DebitBusinessUnit,
	|	DD.CorExpenditureDimension AS CorExpenditureDimension,
	|	SUM(DD.Weight) AS Weight, 
	|	SUM(DD.LocalWeight) AS LocalWeight,
	|	SUM(DD.LedWeight) AS LedWeight,
	|	SUM(DD.LocalWeightGiven) AS LocalWeightGiven,
	|	SUM(CASE
	|		WHEN SettingsForRecognitionOfLBExpensesByBusinessUnit.ExpenseRecognitionOption IS NULL
	|				AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ExpenseRecognitionOption IS NULL
	|			THEN 0
	|		ELSE DD.LocalWeight
	|	END) AS NDTWeight,
	|	SUM(CASE
	|		WHEN SettingsForRecognitionOfLBExpensesByBusinessUnit.ExpenseRecognitionOption IS NULL
	|				AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ExpenseRecognitionOption IS NULL
	|			THEN 0
	|		ELSE DD.LocalWeightGiven
	|	END) AS GivenWeightOfNDT
	|
	|INTO TTTransitOfExpensesBetweenHIA
	|FROM (
	|	SELECT
	|		DD.DocumentRegisterRecords,
	|		DD.Organization,
	|		DD.Department,
	|		DD.LineOfBusiness,
	|		DD.ExpenseItem,
	|		DD.DimensionOfExpenses,
	|		DD.CorCompany,
	|		DD.DebitBusinessUnit,
	|		DD.CorExpenditureDimension,
	|		DD.Weight AS Weight,
	|		0 AS LocalWeight,
	|		DD.LedWeight AS LedWeight,
	|		0 AS LocalWeightGiven
	|	FROM TTTransitCostsBetweenHIAMan AS DD
	|	UNION
	|	SELECT
	|		DD.DocumentRegisterRecords,
	|		DD.Organization,
	|		DD.Department,
	|		DD.LineOfBusiness,
	|		DD.ExpenseItem,
	|		DD.DimensionOfExpenses,
	|		DD.CorCompany,
	|		DD.DebitBusinessUnit,
	|		DD.CorExpenditureDimension,
	|		0,
	|		DD.Weight,
	|		0 AS LedWeight,
	|		DD.LedWeight AS LocalWeightGiven
	|	FROM TTTransitCostsBetweenHIALocal AS DD
	|) AS DD
	|	
	|	LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesByBusinessUnit
	|	ON SettingsForRecognitionOfLBExpensesByBusinessUnit.ObjectOfSeparateAccountingAIT = DD.Department
	|		AND SettingsForRecognitionOfLBExpensesByBusinessUnit.Organization = DD.Organization
	|		AND SettingsForRecognitionOfLBExpensesByBusinessUnit.ExpensesAreIncludedInCost
	|
	|	LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfExpensesLBDpoLineOfBusiness
	|	ON SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ObjectOfSeparateAccountingAIT = DD.LineOfBusiness
	|		AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.Organization = DD.Organization
	|		AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ExpensesAreIncludedInCost
	|
	|GROUP BY
	|	DD.DocumentRegisterRecords,
	|	DD.Organization,
	|	DD.Department,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.CorCompany,
	|	DD.DebitBusinessUnit,
	|	DD.CorExpenditureDimension
	|INDEX BY
	|	DocumentRegisterRecords,
	|	Organization,
	|	Department,
	|	LineOfBusiness,
	|	ExpenseItem,
	|	DimensionOfExpenses
	|";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True, 
		"TTInitialDataOfTransitNodesOfExpendituresBetweenHIA,TTTransitOfExpensesBetweenHIA");

	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"CurrentHIAData, TTExpensesForTransitBetweenHIAMan,TTInitialDataOfTransitNodesOfExpendituresBetweenHIAMan, 
		|TTCostsForTransitBetweenHIALocal,TTRawDataOfTransitNodesCostsBetweenHIALocal,ValuesOfHIAIndicators,
		|SettingsForRecognitionOfLBExpensesByBusinessUnit,SettingsForRecognitionOfExpensesLBDpoLineOfBusiness
		|");

EndProcedure
// Step 15 (Context: "Distribute the cost of production").
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure DistributeSharesOfProductionCosts(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "DistributeSharesOfProductionCosts");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		TableForDistributionOfSharesOfProductionCosts(CalculationParameters),
		,
		"SharesOfProductionCosts",
		"Organization, Department, ExpenseItem, DimensionOfExpenses",
		"DataOnMaterialCosts,DataOnLaborCosts,ProductData_6");
	
	// 2. Obtaining the initial data for the calculation
	// 	- generates a temporary Data table.
	GetDataForDistributionOfSharesOfProductionCosts(CalculationParameters);
	
	// 3. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates a temporary table of pre-production costs.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure
	
// Step 15.1 (Context: "Distribute the direct production costs").
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure DistributeDirectProductionCosts(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "DistributeDirectProductionCosts");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		TableForDistributionOfDirectProductionCosts(CalculationParameters),
		,
		"DirectProductionCosts");
	
	// 2. Obtaining the initial data for the calculation
	// 	- generates a temporary Data table.
	ObtainDataForDistributionOfDirectProductionCosts(CalculationParameters);
	
	// 3. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates a temporary table of direct production costs.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure
	
// Stage 16 (Context: "Distributionpostate expenditures for output products")
// PU 2.1: calculate the amount of expenditure (), the area of calculating the amount of expenditure for non-finished Production.
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure DistributionOfItemByItemExpensesForOutputProducts(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "DistributionOfItemByItemExpensesForOutputProducts");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		TableForDistributionOfOtherUnfinishedProductionCosts(CalculationParameters),
		,
		"TTOtherWorkInProgressExpenses__",
		"Recorder",
		"LotsForAttributingExpenses, ReductionCoefficients");
	
	// 2. Getting the source data for the broadcast
	// 	- generates a temporary Data table.
	GetDataForOtherExpensesOfUnfinishedProduction(CalculationParameters);
	
	// 3. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates a temporary table of the rest of the output of the completed production.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure

// Step 18.1 (Context: "Distribution of the cost of the sale")
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure DistributionOfItemByItemSalesExpenses(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing
	 And Not CalculationParameters.DistributionOfItemByItemSalesExpenses Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "DistributionOfItemByItemSalesExpenses");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		TableForDistributionOfSalesExpenses(CalculationParameters),
		,
		"TTDistributionOfSalesExpenses",
		,
		"TTSelectionOfSalesByImplementationsOfPreviousPeriods");
	
	// 2. Obtaining the initial data for the calculation
	// 	- generates a temporary Data table.
	GetDataForDistributionOfSalesExpenses(CalculationParameters);
	
	// 3. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates a temporary table in the distribution of sales expenses_Other expenses.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);

EndProcedure
		
// Stage of allocation of expenses for future periods.
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure AllocateExpensesForFuturePeriods(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "AllocateExpensesForFuturePeriods");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text = "
	|SELECT
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	DD.LineOfBusiness,
	|	MAX(CASE
	|		WHEN DD.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.ManagementAccounting
	|		 AND AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN TRUE
	|		ELSE FALSE END) AS DistributeMan,
	|	MAX(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.LocalAccounting
	|		 AND AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN TRUE
	|		ELSE FALSE END) AS DistributeLocal,
	|	MAX(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.TaxAccounting
	|		 AND AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN TRUE
	|		ELSE FALSE END) AS DistributeTa,
	|	MAX(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.AIT
	|		 AND AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN TRUE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.AIT
	|		 AND AssetRef.CostAllocationOptionTax IN (VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold),
	|													VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|													VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
	|		 AND AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN TRUE
	|		ELSE FALSE END) AS DistributePersonalIncomeTax,
	|	
	|	SUM(CASE
	|		WHEN DD.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|		 AND DD.ManagementAccounting
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareOfManSCost,
	|	SUM(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.LocalAccounting
	|		 AND AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareOfLocalValue,
	|	SUM(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.TaxAccounting
	|		 AND AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareValueTa,
	|	SUM(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.AIT
	|		 AND AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN Rows.CostShare
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.AIT
	|		 AND AssetRef.CostAllocationOptionTax IN (VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold),
	|													VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|													VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
	|		 AND AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareOfCostOfPersonalIncomeTax
	|
	|INTO TTDistributionRBP
	|FROM
	|	Document.DeferredExpensesAllocation AS DD
	|	INNER JOIN Document.DeferredExpensesAllocation.CostAllocation AS Rows
	|		ON Rows.Ref = DD.Ref
	|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
	|		ON AssetRef.Ref = DD.ExpenseItem
	|WHERE
	|	DD.Posted
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (DD.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		OR DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically))
	|GROUP BY
	|	DD.Organization,
	|	DD.Department,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.LineOfBusiness
	|
	|INDEX BY
	|	Organization,
	|	Department,
	|	DimensionOfExpenses
	|;
	|SELECT
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	MAX(CASE
	|		WHEN DD.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.ManagementAccounting
	|		 AND AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN TRUE
	|		ELSE FALSE END) AS DistributeMan,
	|	MAX(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.LocalAccounting
	|		 AND AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN TRUE
	|		ELSE FALSE END) AS DistributeLocal,
	|	MAX(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.TaxAccounting
	|		 AND AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN TRUE
	|		ELSE FALSE END) AS DistributeTa,
	|	MAX(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		AND DD.AIT
	|		AND AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN TRUE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		AND DD.AIT
	|		AND AssetRef.CostAllocationOptionTax IN
	|			(VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold),
	|			VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|			VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
	|		AND AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN TRUE
	|		ELSE FALSE END) AS DistributePersonalIncomeTax,
	|	
	|	SUM(CASE
	|		WHEN DD.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.ManagementAccounting
	|		 AND AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareOfManSCost,
	|	SUM(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.LocalAccounting
	|		 AND AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareOfLocalValue,
	|	SUM(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.TaxAccounting
	|		 AND AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareValueTa,
	|	SUM(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.AIT
	|		 AND AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN Rows.CostShare
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.AIT
	|		 AND AssetRef.CostAllocationOptionTax IN (VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold),
	|													VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|													VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
	|		 AND AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN Rows.CostShare
	|		ELSE 0
	|	END) AS ShareOfCostOfPersonalIncomeTax
	|
	|INTO TTDistributionRBPOVZ
	|FROM
	|	Document.DeferredExpensesAllocation AS DD
	|	INNER JOIN Document.DeferredExpensesAllocation.CostAllocation AS Rows
	|		ON Rows.Ref = DD.Ref
	|	INNER JOIN Catalog.CostCenters AS AssetRef
	|		ON AssetRef.Ref = DD.DimensionOfExpenses
	|WHERE
	|	DD.Posted
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (DD.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		OR DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically))
	|	AND DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|GROUP BY
	|	DD.Organization,
	|	DD.Department,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.LineOfBusiness
	|
	|INDEX BY
	|	Organization,
	|	Department,
	|	DimensionOfExpenses
	|;
	|
	|SELECT
	|	Expenses.Organization AS Organization,
	|	Expenses.Department AS Department,
	|	Expenses.ExpenseItem AS ExpenseItem,
	|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	Expenses.LineOfBusiness AS LineOfBusiness,
	|	SUM(Expenses.Sum) AS Sum,
	|	SUM(Expenses.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(Expenses.SumMan) AS SumMan,
	|	SUM(Expenses.SumCompl) AS SumCompl,
	|	SUM(Expenses.PermanentDifference) AS PermanentDifference,
	|	SUM(Expenses.CostTD) AS CostTD,
	|	SUM(Expenses.AITAmount) AS AITAmount
	|INTO TueExpensesRBPCDistribution
	|FROM
	|	TTCashEstimatedTurnoverOtherExpenses AS Expenses
	|	INNER JOIN TTDistributionRBP AS Allocation
	|		ON Allocation.Organization = Expenses.Organization
	|		AND Allocation.Department = Expenses.Department
	|		AND Allocation.ExpenseItem = Expenses.ExpenseItem
	|		AND Allocation.DimensionOfExpenses = Expenses.DimensionOfExpenses
	|		AND Allocation.LineOfBusiness = Expenses.LineOfBusiness
	|WHERE
	|	Expenses.OfficialTypeOfMovementParish
	|GROUP BY
	|	Expenses.Organization,
	|	Expenses.Department,
	|	Expenses.ExpenseItem,
	|	Expenses.DimensionOfExpenses,
	|	Expenses.LineOfBusiness
	|
	|UNION ALL
	|
	|SELECT
	|	Expenses.Organization AS Organization,
	|	Expenses.Department AS Department,
	|	Expenses.ExpenseItem AS ExpenseItem,
	|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	Expenses.LineOfBusiness AS LineOfBusiness,
	|	SUM(Expenses.Sum) AS Sum,
	|	SUM(Expenses.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(Expenses.SumMan) AS SumMan,
	|	SUM(Expenses.SumCompl) AS SumCompl,
	|	SUM(Expenses.PermanentDifference) AS PermanentDifference,
	|	SUM(Expenses.CostTD) AS CostTD,
	|	SUM(Expenses.AITAmount) AS AITAmount
	|FROM
	|	TTCashEstimatedTurnoverOtherExpenses AS Expenses
	|	INNER JOIN TTDistributionRBPOVZ AS Allocation
	|		ON Allocation.Organization = Expenses.Organization
	|		AND Allocation.Department = Expenses.Department
	|		AND Allocation.DimensionOfExpenses = Expenses.DimensionOfExpenses
	|WHERE
	|	Expenses.OfficialTypeOfMovementParish
	|GROUP BY
	|	Expenses.Organization,
	|	Expenses.Department,
	|	Expenses.ExpenseItem,
	|	Expenses.DimensionOfExpenses,
	|	Expenses.LineOfBusiness
	|
	|UNION ALL
	|
	|SELECT
	|	Data.Organization AS Organization,
	|	Data.Department AS Department,
	|	Data.ExpenseItem AS ExpenseItem,
	|	Data.DimensionOfExpenses AS DimensionOfExpenses,
	|	Data.LineOfBusiness AS LineOfBusiness,
	|	Data.SumBalance + Data.SumReceipt - Data.SumExpense AS Sum,
	|	Data.AmountExcludingVATBalance + Data.AmountExcludingVATReceipt - Data.AmountExcludingVATExpense AS AmountExcludingVAT,
	|	Data.SumManBalance + Data.SumManReceipt - Data.SumManExpense AS SumMan,
	|	Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense AS SumCompl,
	|	Data.PermanentDifferenceBalance + Data.PermanentDifferenceReceipt - Data.PermanentDifferenceExpense AS PermanentDifference,
	|	Data.CostTDBalance + Data.CostTDReceipt - Data.CostTDExpense AS CostTD,
	|	Data.AITAmountBalance + Data.AITAmountReceipt - Data.AITAmountExpense AS AITAmount
	|FROM
	|	(SELECT
	|		Data.Organization AS Organization,
	|		Data.Department AS Department,
	|		Data.ExpenseItem AS ExpenseItem,
	|		Data.DimensionOfExpenses AS DimensionOfExpenses,
	|		Data.LineOfBusiness AS LineOfBusiness,
	|		SUM(Data.SumReceipt) AS SumReceipt,
	|		SUM(Data.AmountExcludingVATReceipt) AS AmountExcludingVATReceipt,
	|		SUM(Data.SumManReceipt) AS SumManReceipt,
	|		SUM(Data.SumComplReceipt) AS SumComplReceipt,
	|		SUM(Data.PermanentDifferenceReceipt) AS PermanentDifferenceReceipt,
	|		SUM(Data.CostTDReceipt) AS CostTDReceipt,
	|		SUM(Data.AITAmountReceipt) AS AITAmountReceipt,
	|		SUM(Data.SumExpense) AS SumExpense,
	|		SUM(Data.AmountExcludingVATExpense) AS AmountExcludingVATExpense,
	|		SUM(Data.SumManExpense) AS SumManExpense,
	|		SUM(Data.SumComplExpense) AS SumComplExpense,
	|		SUM(Data.PermanentDifferenceExpense) AS PermanentDifferenceExpense,
	|		SUM(Data.CostTDExpense) AS CostTDExpense,
	|		SUM(Data.AITAmountExpense) AS AITAmountExpense,
	|		SUM(Data.SumBalance) AS SumBalance,
	|		SUM(Data.AmountExcludingVATBalance) AS AmountExcludingVATBalance,
	|		SUM(Data.SumManBalance) AS SumManBalance,
	|		SUM(Data.SumComplBalance) AS SumComplBalance,
	|		SUM(Data.PermanentDifferenceBalance) AS PermanentDifferenceBalance,
	|		SUM(Data.CostTDBalance) AS CostTDBalance,
	|		SUM(Data.AITAmountBalance) AS AITAmountBalance,
	|		SUM(Data.AmountBalanceTotal) AS AmountBalanceTotal,
	|		SUM(Data.VATExclusiveAmountBalanceTotal) AS VATExclusiveAmountBalanceTotal,
	|		SUM(Data.UprAmountBalanceTotal) AS UprAmountBalanceTotal,
	|		SUM(Data.AmountReglBalanceTotal) AS AmountReglBalanceTotal,
	|		SUM(Data.ConstantDifferenceRemainderTotal) AS ConstantDifferenceRemainderTotal,
	|		SUM(Data.TimeDifferenceRemainderTotal) AS TimeDifferenceRemainderTotal,
	|		SUM(Data.PersonalIncomeTaxAmountBalanceTotal) AS PersonalIncomeTaxAmountBalanceTotal,
	|		MAX(Data.WithoutManAmounts) AS WithoutManAmounts,
	|		MAX(Data.NoLocalAmounts) AS NoLocalAmounts,
	|		MAX(Data.WithoutSumsTa) AS WithoutSumsTa,
	|		MAX(Data.WithoutNDDAmounts) AS WithoutNDDAmounts
	|
	|	FROM
	|		&RBPSources AS Data
	|GROUP BY
	|	Data.Organization,
	|	Data.Department,
	|	Data.ExpenseItem,
	|	Data.DimensionOfExpenses,
	|	Data.LineOfBusiness) AS Data
	|	
	|LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfMan
	|	ON DistributionOfMan.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DistributionOfMan.ExpenseItem = Data.ExpenseItem
	|	AND DistributionOfMan.Posted
	|	AND DistributionOfMan.ManagementAccounting
	|	AND DistributionOfMan.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|	AND DistributionOfMan.Organization = Data.Organization
	|	AND DistributionOfMan.Department = Data.Department
	|	AND DistributionOfMan.DimensionOfExpenses = Data.DimensionOfExpenses
	|	AND DistributionOfMan.LineOfBusiness = Data.LineOfBusiness
	|LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfLocal
	|	ON DistributionOfLocal.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DistributionOfLocal.ExpenseItem = Data.ExpenseItem
	|	AND DistributionOfLocal.Posted
	|	AND DistributionOfLocal.LocalAccounting
	|	AND DistributionOfLocal.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|	AND DistributionOfLocal.Organization = Data.Organization
	|	AND DistributionOfLocal.Department = Data.Department
	|	AND DistributionOfLocal.DimensionOfExpenses = Data.DimensionOfExpenses
	|	AND DistributionOfLocal.LineOfBusiness = Data.LineOfBusiness
	|LEFT JOIN Document.DeferredExpensesAllocation AS TADistribution
	|	ON TADistribution.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND TADistribution.ExpenseItem = Data.ExpenseItem
	|	AND TADistribution.Posted
	|	AND TADistribution.TaxAccounting
	|	AND TADistribution.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|	AND TADistribution.Organization = Data.Organization
	|	AND TADistribution.Department = Data.Department
	|	AND TADistribution.DimensionOfExpenses = Data.DimensionOfExpenses
	|	AND TADistribution.LineOfBusiness = Data.LineOfBusiness
	|LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfPersonalIncomeTax
	|	ON TADistribution.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND TADistribution.ExpenseItem = Data.ExpenseItem
	|	AND TADistribution.Posted
	|	AND TADistribution.AIT
	|	AND TADistribution.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|	AND TADistribution.Organization = Data.Organization
	|	AND TADistribution.Department = Data.Department
	|	AND TADistribution.DimensionOfExpenses = Data.DimensionOfExpenses
	|	AND TADistribution.LineOfBusiness = Data.LineOfBusiness
	|
	|WHERE
	|	(Data.SumBalance + Data.SumReceipt - Data.SumExpense <> 0
	|		OR Data.SumManBalance + Data.SumManReceipt - Data.SumManExpense <> 0 
	|		OR Data.WithoutManAmounts) AND NOT DistributionOfMan.Ref IS NULL
	|	OR (Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense <> 0 
	|		OR Data.NoLocalAmounts) AND NOT DistributionOfLocal.Ref IS NULL
	|	OR (Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense 
	|			- (Data.PermanentDifferenceBalance + Data.PermanentDifferenceReceipt - Data.PermanentDifferenceExpense) 
	|			- (Data.CostTDBalance + Data.CostTDReceipt - Data.CostTDExpense) <> 0
	|		OR Data.WithoutSumsTa) AND NOT TADistribution.Ref IS NULL
	|	OR (Data.AITAmountBalance + Data.AITAmountReceipt - Data.AITAmountExpense <> 0 
	|		OR Data.WithoutNDDAmounts) AND NOT DistributionOfPersonalIncomeTax.Ref IS NULL
	|
	|INDEX BY
	|	Organization,
	|	Department,
	|	DimensionOfExpenses
	|;
	|
	|SELECT
	|	1 AS Order,
	|	Expenses.Organization AS Organization,
	|	Expenses.Department AS Department,
	|	Expenses.ExpenseItem AS ExpenseItem,
	|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	Expenses.LineOfBusiness AS LineOfBusiness,
	|	Expenses.Sum AS Sum,
	|	Expenses.AmountExcludingVAT AS AmountExcludingVAT,
	|	Expenses.SumMan AS SumMan,
	|	Expenses.SumCompl AS SumCompl,
	|	Expenses.PermanentDifference AS PermanentDifference,
	|	Expenses.CostTD AS CostTD,
	|	Expenses.AITAmount AS AITAmount,
	|
	|	UNDEFINED AS DocumentRegisterRecords,
	|	Allocation.ShareOfManSCost AS ShareOfManSCost,
	|	Allocation.ShareOfLocalValue AS ShareOfLocalValue,
	|	Allocation.ShareValueTa AS ShareValueTa,
	|	Allocation.ShareOfCostOfPersonalIncomeTax AS ShareOfCostOfPersonalIncomeTax,
	|	DATETIME(1,1,1) AS Period,
	|	UNDEFINED AS ReceivingBusinessUnit,
	|	UNDEFINED AS ExpenseItemRecipient,
	|	FALSE AS EnteredInTaxAccounting,
	|	UNDEFINED AS ExpensesDimensionRecipient,
	|	UNDEFINED AS CostAllocationOptionManag,
	|	UNDEFINED AS CostAllocationOptionLocal,
	|	UNDEFINED AS SeparateVATAccountingOption,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS FinRecordID,
	|	UNDEFINED AS BusinessTransactionSetting
	|FROM
	|	TueExpensesRBPCDistribution AS Expenses
	|	INNER JOIN TTDistributionRBP AS Allocation
	|		ON Allocation.Organization = Expenses.Organization
	|		AND Allocation.Department = Expenses.Department
	|		AND Allocation.DimensionOfExpenses = Expenses.DimensionOfExpenses
	|		AND Allocation.ExpenseItem = Expenses.ExpenseItem
	|		AND Allocation.LineOfBusiness = Expenses.LineOfBusiness
	|
	|UNION ALL
	|
	|SELECT
	|	1 AS Order,
	|	Expenses.Organization AS Organization,
	|	Expenses.Department AS Department,
	|	Expenses.ExpenseItem AS ExpenseItem,
	|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	Expenses.LineOfBusiness AS LineOfBusiness,
	|	Expenses.Sum AS Sum,
	|	Expenses.AmountExcludingVAT AS AmountExcludingVAT,
	|	Expenses.SumMan AS SumMan,
	|	Expenses.SumCompl AS SumCompl,
	|	Expenses.PermanentDifference AS PermanentDifference,
	|	Expenses.CostTD AS CostTD,
	|	Expenses.AITAmount AS AITAmount,
	|
	|	UNDEFINED AS DocumentRegisterRecords,
	|	Allocation.ShareOfManSCost AS ShareOfManSCost,
	|	Allocation.ShareOfLocalValue AS ShareOfLocalValue,
	|	Allocation.ShareValueTa AS ShareValueTa,
	|	Allocation.ShareOfCostOfPersonalIncomeTax AS ShareOfCostOfPersonalIncomeTax,
	|	DATETIME(1,1,1) AS Period,
	|	UNDEFINED AS ReceivingBusinessUnit,
	|	UNDEFINED AS ExpenseItemRecipient,
	|	FALSE AS EnteredInTaxAccounting,
	|	UNDEFINED AS ExpensesDimensionRecipient,
	|	UNDEFINED AS CostAllocationOptionManag,
	|	UNDEFINED AS CostAllocationOptionLocal,
	|	UNDEFINED AS SeparateVATAccountingOption,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS FinRecordID,
	|	UNDEFINED AS BusinessTransactionSetting
	|FROM
	|	TueExpensesRBPCDistribution AS Expenses
	|	INNER JOIN TTDistributionRBPOVZ AS Allocation
	|		ON Allocation.Organization = Expenses.Organization
	|		AND Allocation.Department = Expenses.Department
	|		AND Allocation.DimensionOfExpenses = Expenses.DimensionOfExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	2 AS Order,
	|	Expenses.Organization,
	|	Expenses.Department,
	|	Expenses.ExpenseItem,
	|	Expenses.DimensionOfExpenses,
	|	Expenses.LineOfBusiness,
	|	0 AS Sum,
	|	0 AS AmountExcludingVAT,
	|	0 AS SumMan,
	|	0 AS SumCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS AITAmount,
	|
	|	DD.Ref AS DocumentRegisterRecords,
	|	(CASE
	|		WHEN DD.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.ManagementAccounting
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareOfManSCost,
	|	(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.LocalAccounting
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareOfLocalValue,
	|	(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.TaxAccounting
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareValueTa,
	|	(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.AIT
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareOfCostOfPersonalIncomeTax,
	|	Rows.Date AS Period,
	|	Rows.Department AS ReceivingBusinessUnit,
	|	Rows.ExpenseItem AS ExpenseItemRecipient,
	|	Rows.ExpenseItem.EnteredInTaxAccounting AS EnteredInTaxAccounting,
	|	Rows.DimensionOfExpenses AS ExpensesDimensionRecipient,
	|	Rows.ExpenseItem.CostAllocationOptionManag AS CostAllocationOptionManag,
	|	Rows.ExpenseItem.CostAllocationOptionLocal AS CostAllocationOptionLocal,
	|	Rows.ExpenseItem.SeparateVATAccountingOption AS SeparateVATAccountingOption,
	|	VALUE(Enum.BusinessTransactions.DeferredExpenseAllocation) AS BusinessOperation,
	|	Rows.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DeferredExpenseAllocation) AS BusinessTransactionSetting
	|FROM
	|	TueExpensesRBPCDistribution AS Expenses
	|	INNER JOIN Document.DeferredExpensesAllocation AS DD
	|		ON DD.Organization = Expenses.Organization
	|		AND DD.Department = Expenses.Department
	|		AND DD.DimensionOfExpenses = Expenses.DimensionOfExpenses
	|	INNER JOIN Document.DeferredExpensesAllocation.CostAllocation AS Rows
	|		ON Rows.Ref = DD.Ref
	|WHERE
	|	DD.Posted
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (DD.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		OR DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically))
	|	AND DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	2 AS Order,
	|	DD.Organization,
	|	DD.Department,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.LineOfBusiness,
	|	0 AS Sum,
	|	0 AS AmountExcludingVAT,
	|	0 AS SumMan,
	|	0 AS SumCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS AITAmount,
	|
	|	DD.Ref AS DocumentRegisterRecords,
	|	(CASE
	|		WHEN DD.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.ManagementAccounting
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareOfManSCost,
	|	(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.LocalAccounting
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareOfLocalValue,
	|	(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.TaxAccounting
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareValueTa,
	|	(CASE
	|		WHEN DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		 AND DD.AIT
	|			THEN Rows.CostShare
	|		ELSE 0 END) AS ShareOfCostOfPersonalIncomeTax,
	|	Rows.Date AS Period,
	|	Rows.Department AS ReceivingBusinessUnit,
	|	Rows.ExpenseItem AS ExpenseItemRecipient,
	|	Rows.ExpenseItem.EnteredInTaxAccounting AS EnteredInTaxAccounting,
	|	Rows.DimensionOfExpenses AS ExpensesDimensionRecipient,
	|	Rows.ExpenseItem.CostAllocationOptionManag AS CostAllocationOptionManag,
	|	Rows.ExpenseItem.CostAllocationOptionLocal AS CostAllocationOptionLocal,
	|	Rows.ExpenseItem.SeparateVATAccountingOption AS SeparateVATAccountingOption,
	|	VALUE(Enum.BusinessTransactions.DeferredExpenseAllocation) AS BusinessOperation,
	|	Rows.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DeferredExpenseAllocation) AS BusinessTransactionSetting
	|FROM
	|	Document.DeferredExpensesAllocation AS DD
	|	INNER JOIN Document.DeferredExpensesAllocation.CostAllocation AS Rows
	|		ON Rows.Ref = DD.Ref
	|WHERE
	|	DD.Posted
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (DD.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|		OR DD.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically))
	|	AND NOT DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|
	|ORDER BY
	|	Organization,
	|	Department,
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	LineOfBusiness,
	|	Order ASC,
	|	DocumentRegisterRecords,
	|	Period ASC
	|";
	
	RBPSources = Documents.DeferredExpensesAllocation.RequestTextCostsForDistributionSources();
	RBPSources = StrReplace(RBPSources, "&Department", "VALUE(Catalog.BusinessStructure.EmptyRef)"); //@Query-part
	RBPSources = StrReplace(RBPSources, "&ByAllCompanies", "FALSE"); //@Query-part
	RBPSources = StrReplace(RBPSources, "&ByAllBusinessUnits", "TRUE"); //@Query-part
	RBPSources = StrReplace(RBPSources, "&Department", "VALUE(Catalog.BusinessStructure.EmptyRef)"); //@Query-part
	RBPSources = StrReplace(RBPSources, "Organization = &Organization", "Organization IN (&CompanyArray)"); //@Query-part
	Query.Text = StrReplace(Query.Text, "&RBPSources", "(" + RBPSources + ")");
	
	Selection = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True);
	
	RemainderLine = New Structure;
	SummaryResources = New Structure;
	
	For Each Column In Selection.Owner().Columns Do
		RemainderLine.Insert(Column.Name);
		If Column.ValueType.ContainsType(Type("Number")) Then
			SummaryResources.Insert(Column.Name);
		EndIf;
	EndDo;
	RemainderLine.Insert("AmountFA");
	SummaryResources.Insert("AmountFA");
	
	// Movements are formed by registers:
	// - Revenue and cost of sales
	While Selection.Next() Do
		
		If Selection.Order = 1 Then
			
			FillPropertyValues(RemainderLine, Selection);
			RemainderLine.AmountFA = RemainderLine.SumCompl - RemainderLine.PermanentDifference - RemainderLine.CostTD;
			If Selection.ShareOfManSCost = 0 Then
				RemainderLine.Sum = 0; 
				RemainderLine.AmountExcludingVAT = 0; 
				RemainderLine.SumMan = 0; 
			EndIf;
			If Selection.ShareOfLocalValue = 0 Then
				RemainderLine.SumCompl = 0; 
			EndIf;
			If Selection.ShareValueTa = 0 Then
				RemainderLine.AmountFA = 0; 
				RemainderLine.PermanentDifference = 0; 
			EndIf;
			If Selection.ShareOfCostOfPersonalIncomeTax = 0 Then
				RemainderLine.AITAmount = 0; 
			EndIf;
			
		ElsIf RemainderLine.Organization = Selection.Organization
		 And RemainderLine.Department = Selection.Department
		 And RemainderLine.ExpenseItem = Selection.ExpenseItem
		 And RemainderLine.DimensionOfExpenses = Selection.DimensionOfExpenses
		 And RemainderLine.LineOfBusiness = Selection.LineOfBusiness Then
		
		 	If RemainderLine.ShareOfManSCost <= Selection.ShareOfManSCost Then
			    FillPropertyValues(SummaryResources, RemainderLine, "Sum, AmountExcludingVAT, SumMan");
				RemainderLine.ShareOfManSCost = 0;
			Else
				If RemainderLine.ShareOfManSCost <> 0 Then
					SummaryResources.Sum = 
						Round(Selection.ShareOfManSCost * RemainderLine.Sum / RemainderLine.ShareOfManSCost, 2, 1);
					SummaryResources.AmountExcludingVAT = 
						Round(Selection.ShareOfManSCost * RemainderLine.AmountExcludingVAT / RemainderLine.ShareOfManSCost, 2, 1);
					SummaryResources.SumMan = 
						Round(Selection.ShareOfManSCost * RemainderLine.SumMan / RemainderLine.ShareOfManSCost, 2, 1);
				EndIf;
				RemainderLine.ShareOfManSCost = RemainderLine.ShareOfManSCost - Selection.ShareOfManSCost;
			EndIf;
				
			If RemainderLine.ShareOfLocalValue <= Selection.ShareOfLocalValue Then
				FillPropertyValues(SummaryResources, RemainderLine, "SumCompl");
				RemainderLine.ShareOfLocalValue = 0;
			Else	
				If RemainderLine.ShareOfLocalValue <> 0 Then
					SummaryResources.SumCompl = 
						Round(Selection.ShareOfLocalValue * RemainderLine.SumCompl / RemainderLine.ShareOfLocalValue, 2, 1);
				EndIf;
				RemainderLine.ShareOfLocalValue = RemainderLine.ShareOfLocalValue - Selection.ShareOfLocalValue;
			EndIf;
			
			If RemainderLine.ShareValueTa <= Selection.ShareValueTa Then
				FillPropertyValues(SummaryResources, RemainderLine, "AmountFA, PermanentDifference");
				RemainderLine.ShareValueTa = 0;
			Else	
				If RemainderLine.ShareValueTa <> 0 Then
					SummaryResources.PermanentDifference = 
						Round(Selection.ShareValueTa * RemainderLine.PermanentDifference / RemainderLine.ShareValueTa, 2, 1);
					SummaryResources.AmountFA = 
						Round(Selection.ShareValueTa * RemainderLine.AmountFA / RemainderLine.ShareValueTa, 2, 1);
				EndIf;
				RemainderLine.ShareValueTa = RemainderLine.ShareValueTa - Selection.ShareValueTa;
			EndIf;
			
			If RemainderLine.ShareOfCostOfPersonalIncomeTax <= Selection.ShareOfCostOfPersonalIncomeTax Then
				FillPropertyValues(SummaryResources, RemainderLine, "AITAmount");
				RemainderLine.ShareOfCostOfPersonalIncomeTax = 0;
			Else	
				If RemainderLine.ShareOfCostOfPersonalIncomeTax <> 0 Then
					SummaryResources.AITAmount = 
						Round(Selection.ShareOfCostOfPersonalIncomeTax * RemainderLine.AITAmount / RemainderLine.ShareOfCostOfPersonalIncomeTax, 2, 1);
				EndIf;
				RemainderLine.ShareOfCostOfPersonalIncomeTax = RemainderLine.ShareOfCostOfPersonalIncomeTax - Selection.ShareOfCostOfPersonalIncomeTax;
			EndIf;
			
			SummaryResources.CostTD = SummaryResources.SumCompl - SummaryResources.AmountFA - SummaryResources.PermanentDifference;
			
			RemainderLine.Sum = RemainderLine.Sum - SummaryResources.Sum;
			RemainderLine.AmountExcludingVAT = RemainderLine.AmountExcludingVAT - SummaryResources.AmountExcludingVAT;
			RemainderLine.SumMan = RemainderLine.SumMan - SummaryResources.SumMan;
			RemainderLine.SumCompl = RemainderLine.SumCompl - SummaryResources.SumCompl;
			RemainderLine.AmountFA = RemainderLine.AmountFA - SummaryResources.AmountFA;
			RemainderLine.PermanentDifference = RemainderLine.PermanentDifference - SummaryResources.PermanentDifference;
			RemainderLine.AITAmount = RemainderLine.AITAmount - SummaryResources.AITAmount;
			
			// Movements are generated by registers:
			// - Other expenses
			// - Lots of other expenses
			FormGeneralDistributionOfRBP(CalculationParameters, Selection, SummaryResources);
		EndIf;
		
	EndDo;
	
	ForDeletion = New Array;
	ForDeletion.Add("TTDistributionRBP");
	ForDeletion.Add("TTDistributionRBPOVZ");
	ForDeletion.Add("TueExpensesRBPCDistribution");
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, StrConcat(ForDeletion, ","));
	
	CostCalculationAppliedAlgorithms.CacheGeneratedRegisteredRecords(CalculationParameters);
	
EndProcedure

// Service, stage 4.5
Procedure FormGeneralDistributionOfRBP(CalculationParameters, MotionData, Amounts)
	
	// Other expenses
	RegisterName = Metadata.AccumulationRegisters.OtherExpenses.Name;
	
	CopiedFields = "Period, Organization, Department, ExpenseItem, DimensionOfExpenses, LineOfBusiness,
		|BusinessOperation, FinRecordID, BusinessTransactionSetting";

	// Let's add the flow movement and fill in its main properties
	RecordExpense = CostCalculationCostAdjustment.AddEntryToMovementTable(CalculationParameters, RegisterName, MotionData, CopiedFields);
	
	// Fill in the additional properties of the movement flow
	RecordExpense.RecordType = AccumulationRecordType.Expense;
	FillPropertyValues(RecordExpense, Amounts, "Sum, AmountExcludingVAT, SumMan, SumCompl, PermanentDifference, CostTD, AITAmount");
	RecordExpense.DebitBusinessUnit 	  = MotionData.ReceivingBusinessUnit;
	RecordExpense.CorExpenseItem    = MotionData.ExpenseItemRecipient;
	RecordExpense.CorExpenditureDimension = MotionData.ExpensesDimensionRecipient;
	
	// Let's add a movement a parish and fill in its main properties
	RecordReceipt = CostCalculationCostAdjustment.AddEntryToMovementTable(CalculationParameters, RegisterName, MotionData, CopiedFields);
	
	// Fill in the additional properties of the parish movement
	RecordReceipt.RecordType 	   = AccumulationRecordType.Receipt;
	RecordReceipt.Department 	   = MotionData.ReceivingBusinessUnit;
	RecordReceipt.ExpenseItem    = MotionData.ExpenseItemRecipient;
	RecordReceipt.DimensionOfExpenses = MotionData.ExpensesDimensionRecipient;
	RecordReceipt.DebitBusinessUnit 	  = MotionData.Department;
	RecordReceipt.CorExpenseItem    = MotionData.ExpenseItem;
	RecordReceipt.CorExpenditureDimension = MotionData.DimensionOfExpenses;
	
	FillPropertyValues(RecordReceipt, Amounts, "Sum, AmountExcludingVAT, SumMan, SumCompl, CostTD, AITAmount");
	RecordReceipt.PermanentDifference = ?(MotionData.EnteredInTaxAccounting, Amounts.PermanentDifference, Amounts.SumCompl - Amounts.CostTD);
		
	// Lots of other expenses
	If (MotionData.CostAllocationOptionManag = Enums.CostAllocationOptions.ToInventoryCost
	 Or MotionData.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToInventoryCost)
	 And (CalculationParameters.OrganizationsWithDetailedMaterialAndItemByItemCosts.Find(MotionData.Organization) <> Undefined
		) Then
		
		RegisterName = Metadata.AccumulationRegisters.ItemisedExpensesLots.Name;
		
		CopiedFields = "Period, Organization, Department, ExpenseItem, DimensionOfExpenses, LineOfBusiness,
			|BusinessOperation, FinRecordID, BusinessTransactionSetting";
		
		// Let's add a movement a parish and fill in its main properties
		RecordReceipt = CostCalculationCostAdjustment.AddEntryToMovementTable(CalculationParameters, RegisterName, MotionData, CopiedFields);
		
		// Fill in the additional properties of the parish movement
		RecordReceipt.RecordType 	   = AccumulationRecordType.Receipt;
		RecordReceipt.Department 	   = MotionData.ReceivingBusinessUnit;
		RecordReceipt.ExpenseItem    = MotionData.ExpenseItemRecipient;
		RecordReceipt.DimensionOfExpenses = MotionData.ExpensesDimensionRecipient;
		RecordReceipt.ExpenseReceiptDocument = MotionData.DocumentRegisterRecords;
		
		If MotionData.CostAllocationOptionManag = Enums.CostAllocationOptions.ToInventoryCost Then
			RecordReceipt.Cost = Amounts.Sum;
			RecordReceipt.CostExcludingVAT = Amounts.AmountExcludingVAT;
		EndIf;
		
		If MotionData.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToInventoryCost Then
			RecordReceipt.LocalCost = Amounts.SumCompl;
			RecordReceipt.PermanentDifference = Amounts.PermanentDifference;
			RecordReceipt.CostTD = Amounts.CostTD;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region StageProcedures_DistributeVariancesInCost

#Region Description_DistributeDeviationsInValue

// The stage of distribution of deviations in value distributes fixed amounts to disposals of goods in previous periods,
// or to the Balance of a batch of goods in other warehouses.
// The full text of the request is generated in the text allocation function of the value of the value and value of the goods().
// The initial data for the distribution is generated in the function of the text receiver of the value of the goods() and 
// stored in the temporary table of the receiver of the value of the goods() and stored in the temporary table of the receiver of the value of the goods() and stored in the temporary table of the receiver of the value of the goods() and stored in the temporary table of the receiver of the value of the goods() and stored in the temporary table of the receiver of the value of the goods() and stored in the temporary table of the receiver of the value of the goods() and stored in the temporary table of the receiver of the value of the goods().
// The distribution for the disposal of goods in past periods is determined by the Period of receipt field.
// 
// If there is no distribution base for deviations in the batch of the previous period, then such deviations should 
// to be written off to the expense item "Disposals of goods in previous periods" to exclude the hanging of total Balances.
//
// The formation of movements according to the register "Cost of goods" is described in the functions:
//	- The text of the movement of the right to bow down to the cost and cost of goods() - the formation of movements "Expense"
//	- The text of the movement of the right to bow down to the cost and cost of goods() - the formation of movements "Arrival" in the distribution
//		of deviations on the Balance of goods in other warehouses
//
// When writing off deviations to other expenses, movements should be generated according to the registers "Other expenses" and "Nomenclature Movements - Income/expenses".
// The formation of movements according to the register "Other expenses" is described in the function of the textmovement of the income and expenses()
// The formation of movements according to the register "Movements Nomenclature - Income/expenses" is described in the function of the textmovement of the income and expenses()

#EndRegion

// Sample data

Procedure GetDataForDistributionOfDeviationsInValueCostOfGoods(CalculationParameters)
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		TextOfDistributionOfDeviationsInValueCostOfGoods(),
		,
		False,
		Metadata.AccumulationRegisters.InventoryCost.Name);
	
EndProcedure

Procedure ObtainDataForDistributionOfDeviationsInCostRevenueAndCostOfSales(CalculationParameters)
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		TextOfDistributionOfDeviationsInValueRevenueAndCostOfSales(),
		,
		False,
		Metadata.AccumulationRegisters.RevenueAndCOGS.Name);
	
EndProcedure

Procedure GetDataForDistributionOfDeviationsInCostOtherExpenses(CalculationParameters)
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		TextOfDistributionOfDeviationsInValueOtherExpenses(CalculationParameters),
		,
		False,
		Metadata.AccumulationRegisters.OtherExpenses.Name);
	
EndProcedure

Procedure GetDataForDistributionOfDeviationsInCostOfBatchOfOtherExpenses(CalculationParameters)
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		TextOfDistributionOfDeviationsInCostOfLotOfOtherExpenses(CalculationParameters),
		,
		False,
		Metadata.AccumulationRegisters.OtherExpenses.Name);
	
EndProcedure

Procedure GetDataForDistributionOfDeviationsInCostProductsIncomeExpenses(CalculationParameters)
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		TextOfDistributionOfDeviationsInValueProductsIncomeExpenses(),
		,
		False,
		Metadata.AccumulationRegisters.RegisterRecordsProductsIncomeExpenses.Name);
	
EndProcedure

Procedure GetDataForDistributionOfDeviationsInValueOfOtherAssetsLiabilities(CalculationParameters)
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		TextOfDistributionOfDeviationsInValueOtherAssetsLiabilities(),
		,
		False,
		Metadata.AccumulationRegisters.OtherAssetsLiabilities.Name);
	
EndProcedure

Procedure ToObtainDataForDistributionOfDeviationsInCostOfRegisteringRecordsForOtherAssetsLiabilities(CalculationParameters)
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		TextOfDistributionOfDeviationsInCostOfRegisteringRecordsForOtherAssetsLiabilities(),
		,
		False,
		Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
	
EndProcedure


// Request texts

// ... general

Function TextOfDistributionOfDeviationsInValueCostOfGoods(CalculationParameters = Undefined) Export
	
	DataPreparationTexts = New Array;
	DataPreparationTexts.Add(TextOfAdjustmentOfGoodsInTransitPastPeriods());
	DataPreparationTexts.Add(TextAdditionalExpensesAmountWithoutQuantity());
	DataPreparationTexts.Add(TextReceiversForGoodsOfPastPeriodsDeviationsInValue());
	DataPreparationTexts.Add(IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods());
	
	QueryText = ""
		+ StrConcat(DataPreparationTexts, Common.QueryBatchSeparator())
		+ Common.QueryBatchSeparator()
		// Sample data
		+ TextDescriptionOfDataOnDistributionOfDeviationsInValueCostOfGoods()
		+ TMCommonUse.QuerySeparatorInJoin() + TextMovementExpenseDeviationsInValueCostOfGoods()
		+ TMCommonUse.QuerySeparatorInJoin() + TextMovementArrivalOfDeviationsInValueCostOfGoods()
		+ "";
	
	Return QueryText;
	
EndFunction

Function TextOfDistributionOfDeviationsInValueRevenueAndCostOfSales(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// Sample data
		+ TextDescriptionOfCostVarianceDistributionDataRevenueAndCostOfSales()
		+ TMCommonUse.QuerySeparatorInJoin() + TextMovementOfDeviationsInValueRevenueAndCostOfSales() // results of the distribution in W of the distribution of expenses
		+ "";
	
	Return QueryText;
	
EndFunction

Function TextOfDistributionOfDeviationsInValueOtherExpenses(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// Sample data
		+ CalculationOfCostLocalization.AITSettingsQueryText("", "CostCalculationItemByItemExpenses_TextRegisteredRecordedReceiptOfDeviationsInCostOtherExpenses", CalculationParameters)
		+ Common.QueryBatchSeparator()
		+ TextDescriptionOfCostVarianceDistributionDataOtherExpenses()
		+ TMCommonUse.QuerySeparatorInJoin() + TextMovementArrivalOfDeviationsInValueOtherExpenses() // results of the distribution in W of the distribution of expenses
		+ "";
	
	Return QueryText;
	
EndFunction

Function TextOfDistributionOfDeviationsInCostOfLotOfOtherExpenses(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// Sample data
		+ TextDescriptionOfDataOnDistributionOfDeviationsInCostOfBatchOfOtherExpenses()
		+ TMCommonUse.QuerySeparatorInJoin() + TextMovementArrivalOfDeviationsInValueOfLotOfOtherExpenses()
		+ "";
	
	Return QueryText;
	
EndFunction

Function TextOfDistributionOfDeviationsInValueProductsIncomeExpenses(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// Sample data
		+ TextDescriptionOfDataOnDistributionOfDeviationsInValueProductsIncomeExpenses()
		+ TMCommonUse.QuerySeparatorInJoin() + TextMovementOfDeviationsInValueProductsIncomeExpenses() // results of the distribution in W of the distribution of expenses
		+ "";
	
	Return QueryText;
	
EndFunction

Function TextOfDistributionOfDeviationsInValueOtherAssetsLiabilities(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// Sample data
		+ TextDescriptionOfDistributionDataOfDeviationsInValueOtherAssetsLiabilities()
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfRegisteredRecordReceiptOfDeviationsInValueOtherAssetsLiabilities() // results of the distribution in W of the distribution of expenses
		+ "";
	
	Return QueryText;
	
EndFunction

Function TextOfDistributionOfDeviationsInCostOfRegisteringRecordsForOtherAssetsLiabilities(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// Sample data
		+ TextDescriptionOfDataOnDistributionOfDeviationsInValueOfRegisteredRecordsForOtherAssetsLiabilities()
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfRegisteredRecordOfDeviationsInValueOfRegisteredRecordOfOtherAssetsLiabilities() // results of the distribution in W of the distribution of expenses
		+ "";
	
	Return QueryText;
	
EndFunction


// ... data descriptions

Function TextDescriptionOfDataOnDistributionOfDeviationsInValueCostOfGoods()
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80)) AS RequestSource,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.EntryType,
		|	DD.DocumentRegisterRecords,
		|	DD.DocumentSource,
		|
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	DD.AccountingDimensionByPartners,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.GLAccountSettings,
		|	DD.CorLineOfBusiness,
		|	DD.BusinessOperation,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|
		|	DD.CorCompany,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes,
		|	DD.CorAccountingSection,
		|	DD.CorLot,
		|	DD.LotVendorAttributesCorr,
		|
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS CostMan,
		|
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS AddExpensesLocal,
		|	0 AS AddExpensesMan,
		|	0 AS VATLocal,
		|	0 AS VATManag,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax
		|INTO Data
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|";
		
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

Function TextDescriptionOfCostVarianceDistributionDataRevenueAndCostOfSales()
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80))	AS RequestSource,
		|
		|	DD.Recorder					AS Recorder,
		|	DD.Period						AS Period,
		|	DD.DocumentRegisterRecords				AS DocumentRegisterRecords,
		|
		|	DD.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	DD.AccountingSection					AS AccountingSection,
		|	DD.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
		|	DD.Lot						AS Lot,
		|	DD.LotVendorAttributes			AS LotVendorAttributes,
		|	DD.FinancialAccountingDimension	AS FinancialAccountingDimension,
		|	DD.VATActivityType			AS VATActivityType,
		|
		|	DD.AccountingDimensionByPartners	AS AccountingDimensionByPartners,
		|	DD.SalesOrder					AS SalesOrder,
		|	DD.Department				AS Department,
		|	DD.BusinessOperation		AS BusinessOperation,
		|
		|	DD.Manager		AS Manager,
		|	DD.Warehouse		AS Warehouse,
		|	DD.Terms	AS Terms,
		|	DD.Contract		AS Contract,
		|	DD.InventoryType	AS InventoryType,
		|	DD.BusinessTransactionSetting	AS BusinessTransactionSetting,
		|	DD.FinRecordID			AS FinRecordID,
		|	DD.SourceOfProductFinancialAccountingGroup			AS SourceOfProductFinancialAccountingGroup,
		|	DD.SourceOfARAPFinancialAccountingGroup				AS SourceOfARAPFinancialAccountingGroup,
		|
		|	DD.CounterpartyLineOfBusiness	AS CounterpartyLineOfBusiness,
		|	DD.ProductLineOfBusiness	AS ProductLineOfBusiness,
		|
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS AddExpensesLocal,
		|	0 AS AddExpensesMan,
		|	0 AS VATLocal,
		|	0 AS VATManag,
		|	0 AS PermanentDifference,
		|	0 AS CostTD
		|INTO Data
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS DD
		|";
		
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
	
EndFunction

Function TextDescriptionOfCostVarianceDistributionDataOtherExpenses()
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80)) AS RequestSource,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Recorder AS DocumentRegisterRecords,
		|
		|	DD.Organization,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		
		|	DD.BusinessOperation,
		|	DD.ItemsLocationAttributes,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|
		|	0 AS Sum,
		|	0 AS AmountExcludingVAT,
		|	0 AS SumCompl,
		|	0 AS SumMan,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS AITAmount
		|INTO Data
		|FROM
		|	AccumulationRegister.OtherExpenses AS DD
		|";
		
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
	
EndFunction

Function TextDescriptionOfDataOnDistributionOfDeviationsInCostOfBatchOfOtherExpenses()
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80)) AS RequestSource,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Organization,
		|	DD.Department,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseReceiptDocument,
		|	DD.LotVendorAttributes,
		|	DD.LineOfBusiness,
		|	DD.VATActivityType,
		|
		|	DD.BusinessOperation,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS VATLocal,
		|	0 AS VATManag
		|INTO Data
		|FROM
		|	AccumulationRegister.ItemisedExpensesLots AS DD
		|";
		
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
	
EndFunction

Function TextDescriptionOfDataOnDistributionOfDeviationsInValueProductsIncomeExpenses()
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80)) AS RequestSource,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.DocumentRegisterRecords,
		|
		|	DD.BusinessOperation,
		|	DD.Organization,
		|	DD.Department,
		|	DD.ProductLineOfBusiness,
		|	DD.ItemsLocationAttributes,
		|	DD.Warehouse,
		|	DD.InventoryType,
		|	DD.InventoryOwnerAttribute,
		|	DD.IncomeAndExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.LineOfBusinessItems,
		|	DD.SourceOfProductFinancialAccountingGroup,
		|
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS AddExpensesLocal,
		|	0 AS AddExpensesMan,
		|	0 AS PermanentDifference,
		|	0 AS CostTD
		|INTO Data
		|FROM
		|	AccumulationRegister.RegisterRecordsProductsIncomeExpenses AS DD
		|";
		
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
	
EndFunction

Function TextDescriptionOfDistributionDataOfDeviationsInValueOtherAssetsLiabilities()
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80)) AS RequestSource,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Recorder AS DocumentRegisterRecords,
		|
		|	DD.Organization,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.AssetRef,
		|	DD.Dimension,
		|
		|	DD.SourceKind,
		|
		|	0 AS Sum
		|
		|INTO Data
		|FROM
		|	AccumulationRegister.OtherAssetsLiabilities AS DD
		|";
		
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
	
EndFunction

Function TextDescriptionOfDataOnDistributionOfDeviationsInValueOfRegisteredRecordsForOtherAssetsLiabilities()
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80)) AS RequestSource,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Recorder AS DocumentRegisterRecords,
		|
		|	DD.Organization,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.AssetRef,
		|	DD.Dimension,
		|	DD.GLAccountSettings,
		|	DD.DebitCredit,
		|
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|
		|	0 AS AmountExcludingVAT,
		|	0 AS AmountIncludingVAT,
		|	0 AS SumCompl,
		|	0 AS SumMan,
		|	0 AS PermanentDifference,
		|	0 AS CostTD
		|
		|INTO Data
		|FROM
		|	AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS DD
		|";
		
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
	
EndFunction


// ... data samples

Function TextOfAdjustmentOfGoodsInTransitPastPeriods()
	
	QueryText = 
	"SELECT DISTINCT
	|	DD.Organization AS Organization,
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DD.AccountingSection AS AccountingSection,
	|	DD.Lot AS Lot,
	|	DD.LotVendorAttributes AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	DD.VATActivityType AS VATActivityType
	|INTO TTRemnantsOfGoodsInTransit
	|FROM
	|	TTCashSettlementBalancesCostOfGoods AS DD
	|WHERE
	|	&AllocationOfAdditionalExpensesByDisposedGoods
	|	AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|	AND DD.Count <> 0
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Recorder AS Recorder,
	|	DD.Period AS Period,
	|	DD.Organization AS Organization,
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DD.AccountingSection AS AccountingSection,
	|	DD.Lot AS Lot,
	|	DD.LotVendorAttributes AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	DD.VATActivityType AS VATActivityType,
	|	DD.BusinessOperation AS BusinessOperation,
	|	DD.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	DD.Department AS Department,
	|	DD.RowID AS RowID,
	|	DD.FinRecordID AS FinRecordID,
	|	DD.DocumentSource AS DocumentSource,
	|	DD.EntryType AS EntryType,
	|	DD.AccountingDimensionByPartners,
	|	DD.DimensionOfExpenses,
	|	DD.ExpenseItemOfWriteOff,
	|
	|	DD.AddExpensesForGoods AS AddExpensesForGoods,
	|	DD.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
	|	DD.AddExpensesLocal AS AddExpensesLocal,
	|	DD.AddExpensesMan AS AddExpensesMan,
	|	DD.VATLocal AS VATLocal,
	|	DD.VATManag AS VATManag,
	|	DD.PermanentDifference AS PermanentDifference,
	|	DD.CostTD AS CostTD,
	|	DD.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax
	|INTO TTAdjustmentsOfGoodsInTransitPastPeriods
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS DD
	|		LEFT JOIN TTRemnantsOfGoodsInTransit AS Balance
	|		ON DD.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|			AND DD.Organization = Balance.Organization
	|			AND DD.Lot = Balance.Lot
	|			AND DD.AccountingSection = Balance.AccountingSection
	|			AND DD.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|			AND DD.LotVendorAttributes = Balance.LotVendorAttributes
	|			AND DD.FinancialAccountingDimension = Balance.FinancialAccountingDimension
	|			AND DD.VATActivityType = Balance.VATActivityType
	|WHERE
	|	&AllocationOfAdditionalExpensesByDisposedGoods
	|	AND DD.OfficialTypeOfMovementParish
	|	AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|	AND DD.EntryType IN (
	|		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
	|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
	|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
	|		VALUE(Enum.LotRecordTypes.AdditionalExpensesReverseTransaction))
	|	AND DD.Count = 0
	|	AND Balance.Organization IS NULL
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdjustingEntries.Recorder AS Recorder,
	|	DD.Recorder AS DocumentInflow,
	|	AdjustingEntries.Period AS Period,
	|	AdjustingEntries.Organization AS Organization,
	|	DD.CorItemsLocationAttributes AS ItemsLocationAttributes,
	|	DD.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DD.CorAccountingSection AS AccountingSection,
	|	DD.CorLot AS Lot,
	|	DD.LotVendorAttributesCorr AS LotVendorAttributes,
	|	DD.CorControllingAttributes AS FinancialAccountingDimension,
	|	DD.CorVATActivityTypes AS VATActivityType,
	|	AdjustingEntries.BusinessOperation AS BusinessOperation,
	|	AdjustingEntries.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	AdjustingEntries.Department AS Department,
	|	AdjustingEntries.FinRecordID AS FinRecordID,
	|	AdjustingEntries.DocumentSource AS DocumentSource,
	|	AdjustingEntries.EntryType AS EntryType,
	|	AdjustingEntries.ItemsLocationAttributes AS CorItemsLocationAttributes,
	|	AdjustingEntries.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	AdjustingEntries.Lot AS CorLot,
	|	AdjustingEntries.LotVendorAttributes AS LotVendorAttributesCorr,
	|	AdjustingEntries.VATActivityType AS CorVATActivityTypes,
	|	AdjustingEntries.FinancialAccountingDimension AS CorControllingAttributes,
	|	AdjustingEntries.AccountingSection AS CorAccountingSection,
	|	AdjustingEntries.AccountingDimensionByPartners,
	|	AdjustingEntries.DimensionOfExpenses,
	|	AdjustingEntries.ExpenseItemOfWriteOff,
	|
	|	AdjustingEntries.AddExpensesForGoods AS AddExpensesForGoods,
	|	AdjustingEntries.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
	|	AdjustingEntries.AddExpensesLocal AS AddExpensesLocal,
	|	AdjustingEntries.AddExpensesMan AS AddExpensesMan,
	|	AdjustingEntries.VATLocal AS VATLocal,
	|	AdjustingEntries.VATManag AS VATManag,
	|	AdjustingEntries.PermanentDifference AS PermanentDifference,
	|	AdjustingEntries.CostTD AS CostTD,
	|	AdjustingEntries.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax
	|INTO TTReceiptOfGoodsInTransitPastPeriods
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|		INNER JOIN Document.ReceiptOfGoodsToWarehouse AS Inflow
	|		ON DD.Recorder = Inflow.Ref
	|		INNER JOIN TTAdjustmentsOfGoodsInTransitPastPeriods AS AdjustingEntries
	|		ON DD.ItemsLocationAttributes = AdjustingEntries.ItemsLocationAttributes
	|			AND DD.AccountingSection = AdjustingEntries.AccountingSection
	|			AND DD.InventoryOwnerAttribute = AdjustingEntries.InventoryOwnerAttribute
	|			AND DD.Organization = AdjustingEntries.Organization
	|			AND DD.Lot = AdjustingEntries.Lot
	|			AND DD.LotVendorAttributes = AdjustingEntries.LotVendorAttributes
	|			AND DD.FinancialAccountingDimension = AdjustingEntries.FinancialAccountingDimension
	|			AND DD.VATActivityType = AdjustingEntries.VATActivityType
	|WHERE
	|	&AllocationOfAdditionalExpensesByDisposedGoods
	|	AND DD.Period < &BeginOfPeriod
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|	AND DD.Count <> 0
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot,
	|	Recorder";
	
	Return QueryText;
	
EndFunction

Function TextAdditionalExpensesAmountWithoutQuantity()
	
	QueryText = 
	"SELECT
	|	T.Recorder AS Recorder,
	|	T.Organization,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.AccountingSection,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.FinancialAccountingDimension,
	|	T.VATActivityType,
	|	MAX(CASE WHEN T.Organization IN (&OrganizationsIncludingVATLotsVersion22)
	|		THEN T.DocumentSource
	|		ELSE UNDEFINED
	|	END) AS DocumentSource,
	|	MAX(T.LotVendorAttributesCorr) AS LotVendorAttributesCorr
	|INTO TTAdditionalExpensesAmountWithoutQuantity
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS T
	|WHERE
	|	T.EntryType IN (
	|		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
	|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
	|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified))
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND NOT T.ReversingEntry
	|	AND VALUETYPE(T.Recorder) IN (
	|		TYPE(Document.ApplicationForImportationOfGoods),
	|		TYPE(Document.CCDImport))
	|GROUP BY
	|	T.Recorder,
	|	T.Organization,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.AccountingSection,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.FinancialAccountingDimension,
	|	T.VATActivityType
	|";
	
	Return QueryText;
	
EndFunction

Function TextReceiversForGoodsOfPastPeriodsDeviationsInValue()
	
	QueryText = "
		|SELECT TOP 0
		|	DD.Recorder,
		|	DD.Period,
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|	0 AS QuantityToDistribution,
		|	0 AS CostToDistribution,
		|	0 AS CostWithoutNDSKDistribution,
		|	0 AS CostLocalToDistribution,
		|	0 AS ManSCostToDistribution,
		|
		|	0 AS AdditionalCostsSNDSKDistribution,
		|	0 AS AdditionalExpensesWithoutNDSKDISTRIBUTION,
		|	0 AS AdditionalExpensesOfLocalNDSKDistribution,
		|	0 AS AdditionalExpensesOfManNDSKDistribution,
		|	0 AS VATLocalToDistribution,
		|	0 AS VATManForDistribution,
		|	0 AS ConstantDifferenceToDistribution,
		|	0 AS TemporalDifferenceToDistribution,
		|	0 AS CostOfPersonalIncomeTaxDistribution,
		|
		|	DD.Period AS ReceiptPeriod,
		|	VALUE(Enum.InventoryValuationMethods.EmptyRef) AS InventoryValuationMethod
		|
		|INTO ReceiversForProductsOfPastPeriods
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|
		|UNION ALL
		|
		|SELECT
		|	DD.Recorder,
		|	DD.Period,
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|	DD.QuantityToDistribution,
		|	DD.CostToDistribution,
		|	DD.CostWithoutNDSKDistribution,
		|	DD.CostLocalToDistribution,
		|	DD.ManSCostToDistribution,
		|
		|	DD.AdditionalCostsSNDSKDistribution,
		|	DD.AdditionalExpensesWithoutNDSKDISTRIBUTION,
		|	DD.AdditionalExpensesOfLocalNDSKDistribution,
		|	DD.AdditionalExpensesOfManNDSKDistribution,
		|	DD.VATLocalToDistribution,
		|	DD.VATManForDistribution,
		|	DD.ConstantDifferenceToDistribution,
		|	DD.TemporalDifferenceToDistribution,
		|	DD.CostOfPersonalIncomeTaxDistribution,
		|
		|	DD.ReceiptPeriod,
		|	ValuationMethods.InventoryValuationMethod AS InventoryValuationMethod
		|FROM
		|	(
		|SELECT
		|	Source.Recorder,
		|	Source.Period,
		|	Source.EntryType,
		|	Source.ItemsLocationAttributes,
		|	Source.AccountingSection,
		|	Source.InventoryOwnerAttribute,
		|	Source.Organization,
		|	CASE
		|		WHEN Source.Lot <> UNDEFINED
		|			THEN Source.Lot
		// For records, the Reverse Lot reference is filled in according to the source document.
		|		WHEN Source.DocumentSource <> UNDEFINED AND Source.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND Source.ReversingEntry
		|			THEN Source.DocumentSource
		|		ELSE UNDEFINED
		|	END AS Lot,
		|	CASE
		|		WHEN Source.Lot <> UNDEFINED THEN Source.LotVendorAttributes
		|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|	END AS LotVendorAttributes,
		|	Source.FinancialAccountingDimension,
		|	Source.VATActivityType,
		|	MAX(CASE
		|		WHEN Source.BusinessOperation = VALUE(Enum.BusinessTransactions.DebitNoteForPreviousPeriod)
		// In case of correction of the previous period for additional the source of expenses is a line that can correspond to
		//mutual settlements, so for this case we take the line identifier (it is used for warehouse operations).
		|		THEN Source.RowID
		|		ELSE Source.FinRecordID
		|	END) AS FinRecordID,
		|	Source.BusinessTransactionSetting,
		|	0 AS QuantityToDistribution,
		|
		|	SUM(CASE WHEN Source.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
		|		THEN Source.Cost ELSE 0 END) AS CostToDistribution,
		|	SUM(CASE WHEN Source.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
		|		THEN Source.CostExcludingVAT ELSE 0 END) AS CostWithoutNDSKDistribution,
		|	SUM(CASE WHEN Source.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
		|		THEN Source.LocalCost ELSE 0 END) AS CostLocalToDistribution,
		|	SUM(CASE WHEN Source.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
		|		THEN Source.CostMan ELSE 0 END) AS ManSCostToDistribution,
		|
		|	SUM(Source.AddExpensesForGoods) AS AdditionalCostsSNDSKDistribution,
		|	SUM(Source.AdditionalExpensesExcludingVAT) AS AdditionalExpensesWithoutNDSKDISTRIBUTION,
		|	SUM(Source.AddExpensesLocal) AS AdditionalExpensesOfLocalNDSKDistribution,
		|	SUM(Source.AddExpensesMan) AS AdditionalExpensesOfManNDSKDistribution,
		|	SUM(Source.VATLocal) AS VATLocalToDistribution,
		|	SUM(Source.VATManag) AS VATManForDistribution,
		|	SUM(Source.PermanentDifference) AS ConstantDifferenceToDistribution,
		|	SUM(Source.CostTD) AS TemporalDifferenceToDistribution,
		|	SUM(Source.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTaxDistribution,
		|
		// The condition for connecting to the document registry must match the condition in the Template text functionThe primary document acceptor_3
		|	MIN(BEGINOFPERIOD(
		|		CASE
		|			WHEN Register3.IBDocumentDate IS NULL
		|				THEN Source.Period
		|			WHEN Register3.IBDocumentDate < &DateOfMigrationToBatchAccounting22
		|				THEN &DateOfMigrationToBatchAccounting22
		|			ELSE Register3.IBDocumentDate
		|		END, MONTH)) AS ReceiptPeriod
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS Source
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON Source.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
		|		ON Register3.Ref = CASE
		// The additional expenses reflected in the customs declaration for import always relate to the current period, 
		// except for the FIFO valuation method, since goods are available for disposal only after the customs declaration is entered.
		// With FIFO, the input of the document "Reverse" according to the customs declaration of the previous period and the input of a new
		// customs declaration is supported, because the value of disposals in previous periods can be distributed by batch.
		// Exclusion of the section "Own goods in transit (from suppliers)", because the document of receipt of goods to the warehouse
		// can be entered before the customs declaration. 
		|			WHEN VALUETYPE(Source.Recorder) = TYPE(Document.CCDImport)
		|			 AND Source.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|			 AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.FIFORollingValuation)
		|				THEN NULL
		|			WHEN Source.Lot <> UNDEFINED THEN Source.Lot
		|			WHEN Source.DocumentSource <> UNDEFINED THEN Source.DocumentSource
		// For the correct calculation of deviations in the cost of the average for unfactured deliveries, we focus on
		// cost analytics, since for them the Lot reference is stored in this Attribute, the source document itself is not filled in.
		|			WHEN Source.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
		|				AND Source.BusinessOperation IN
		|					(VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
		|			THEN Source.DimensionOfExpenses
		|			ELSE NULL END
		|		AND NOT Register3.AdditionalRecord
		|WHERE
		// Deviations in cost are always distributed to the disposals of goods in past periods, so checking the functional 
		// option of the distribution of used goods is not required.
		// If the functional option of distribution of used goods is turned off and there are no Balances at the beginning of the month
		// according to analytics corresponding to deviations in cost, the deviations will be 
		// attributed to the expense item "Disposals of goods in past periods. 
		// " See the request for the formation of the time table of the receiver of used goods before the previous periods of moving cost.
		|	Source.OfficialTypeOfMovementParish
		// For the "Unfactated deliveries" section, deviations are distributed at the stage of invoicing deliveries in the procedure to fill in the estimated Delivery Invoice part().
		|	AND Source.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND Source.EntryType IN
		|		(VALUE(Enum.LotRecordTypes.CostVariance),
		|		 VALUE(Enum.LotRecordTypes.CostAdjustment),
		|		 VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|		 VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|		 VALUE(Enum.LotRecordTypes.AdditionalExpensesReverseTransaction),
		|		 VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|		 VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|	AND (Source.VATLocal <> 0
		|		OR Source.VATManag <> 0
		|		OR Source.AddExpensesForGoods <> 0
		|		OR Source.AdditionalExpensesExcludingVAT <> 0
		|		OR Source.AddExpensesLocal <> 0
		|		OR Source.AddExpensesMan <> 0
		|		OR (Source.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
		|			AND (Source.LocalCost <> 0
		|				OR Source.CostMan <> 0
		|				OR Source.Cost <> 0
		|				OR Source.CostExcludingVAT <> 0))
		// The amount of the permanent and temporary difference is distributed only if they are formed by the amount of additional expenses,
		// or only the amount of the permanent and temporary difference with zero additional amount is distributed. expenses.
		// if the permanent and temporary difference is formed by the Local cost, they do not need to be distributed, 
		// because the Local cost is not distributed by this stage.
		|		OR Source.PermanentDifference <> 0
		|			AND Source.LocalCost = 0
		|		OR Source.CostTD <> 0
		|			AND Source.LocalCost = 0
		|		OR Source.CostOfPersonalIncomeTax <> 0
		|		)
		// Deviations of past periods are distributed in the general module for 
		// calculating the cost of a decision, but at the stage of preparing the data for a decision, the calculation of the cost of the previous periods is carried out.
		|	AND NOT (Source.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|		AND Source.VariancePeriod < &BeginOfPeriod) 
		|
		|GROUP BY
		|	Source.Recorder,
		|	Source.Period,
		|	Source.EntryType,
		|	Source.ItemsLocationAttributes,
		|	Source.AccountingSection,
		|	Source.InventoryOwnerAttribute,
		|	Source.Organization,
		|	CASE
		|		WHEN Source.Lot <> UNDEFINED
		|			THEN Source.Lot
		|		WHEN Source.DocumentSource <> UNDEFINED AND Source.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND Source.ReversingEntry
		|			THEN Source.DocumentSource
		|		ELSE UNDEFINED
		|	END,
		|	CASE
		|		WHEN Source.Lot <> UNDEFINED THEN Source.LotVendorAttributes
		|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|	END,
		|	Source.FinancialAccountingDimension,
		|	Source.VATActivityType,
		|	Source.BusinessTransactionSetting
		|) AS DD
		|	INNER JOIN TTMethodsOfEstimatingValueOfOrganizationsByPeriod AS ValuationMethods
		|		ON DD.Organization = ValuationMethods.Organization
		|		AND DD.ReceiptPeriod >= ValuationMethods.BeginOfPeriod
		|		AND DD.ReceiptPeriod < ValuationMethods.EndOfPeriod
		|
		|WHERE
		|	DD.ReceiptPeriod < &BeginOfPeriod
		|
		|INDEX BY
		|	ItemsLocationAttributes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Balance.AccountingSection,
		|	Balance.InventoryOwnerAttribute,
		|	Balance.Organization,
		|	Balance.Lot,
		|	Balance.LotVendorAttributes,
		|	Balance.FinancialAccountingDimension,
		|	Balance.VATActivityType
		|
		|INTO BalancesOnReceiversOfPreviousPeriods
		|FROM
		|	AccumulationRegister.InventoryCost.Balance(
		|		&BorderEndOfPreviousPeriod,
		|			NOT &AllocationOfAdditionalExpensesByDisposedGoods
		|			AND (ItemsLocationAttributes, AccountingSection, InventoryOwnerAttribute, Organization) IN (
		|			SELECT
		|				Destinations.ItemsLocationAttributes,
		|				Destinations.AccountingSection,
		|				Destinations.InventoryOwnerAttribute,
		|				Destinations.Organization
		|			FROM
		|				ReceiversForProductsOfPastPeriods AS Destinations
		|			)
		|	) AS Balance
		|
		|INDEX BY
		|	ItemsLocationAttributes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Recorder,
		|	DD.Period,
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|	DD.QuantityToDistribution,
		|	DD.CostToDistribution,
		|	DD.CostWithoutNDSKDistribution,
		|	DD.CostLocalToDistribution,
		|	DD.ManSCostToDistribution,
		|
		|	DD.AdditionalCostsSNDSKDistribution,
		|	DD.AdditionalExpensesWithoutNDSKDISTRIBUTION,
		|	DD.AdditionalExpensesOfLocalNDSKDistribution,
		|	DD.AdditionalExpensesOfManNDSKDistribution,
		|	DD.VATLocalToDistribution,
		|	DD.VATManForDistribution,
		|	DD.ConstantDifferenceToDistribution,
		|	DD.TemporalDifferenceToDistribution,
		|	DD.CostOfPersonalIncomeTaxDistribution,
		|
		|	DD.ReceiptPeriod
		|
		|INTO ReceiversForGoodsOfPastPeriodsWithoutRegisteringRecordedCost
		|FROM
		|	ReceiversForProductsOfPastPeriods AS DD
		|	LEFT JOIN AccumulationRegister.InventoryCost AS RegisterRecords
		|		ON RegisterRecords.Period BETWEEN DD.ReceiptPeriod AND &EndOfPeriod
		|		AND RegisterRecords.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|		AND RegisterRecords.AccountingSection = DD.AccountingSection
		|		AND RegisterRecords.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|		AND RegisterRecords.Organization = DD.Organization
		|		AND RegisterRecords.Lot = DD.Lot
		|		AND (DD.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) OR RegisterRecords.LotVendorAttributes = DD.LotVendorAttributes)
		|		AND RegisterRecords.Count <> 0
		|		AND RegisterRecords.Active
		|WHERE
		|	&AllocationOfAdditionalExpensesByDisposedGoods
		|	AND RegisterRecords.Organization IS NULL
		|	AND DD.ReceiptPeriod < &BeginOfPeriod
		|
		|UNION ALL
		|
		|SELECT
		|	DD.Recorder,
		|	DD.Period,
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|	DD.QuantityToDistribution,
		|	DD.CostToDistribution,
		|	DD.CostWithoutNDSKDistribution,
		|	DD.CostLocalToDistribution,
		|	DD.ManSCostToDistribution,
		|
		|	DD.AdditionalCostsSNDSKDistribution,
		|	DD.AdditionalExpensesWithoutNDSKDISTRIBUTION,
		|	DD.AdditionalExpensesOfLocalNDSKDistribution,
		|	DD.AdditionalExpensesOfManNDSKDistribution,
		|	DD.VATLocalToDistribution,
		|	DD.VATManForDistribution,
		|	DD.ConstantDifferenceToDistribution,
		|	DD.TemporalDifferenceToDistribution,
		|	DD.CostOfPersonalIncomeTaxDistribution,
		|
		|	DD.ReceiptPeriod
		|FROM
		|	ReceiversForProductsOfPastPeriods AS DD
		|	LEFT JOIN BalancesOnReceiversOfPreviousPeriods AS Balance
		|		ON Balance.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|		AND Balance.AccountingSection = DD.AccountingSection
		|		AND Balance.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|		AND Balance.Organization = DD.Organization
		|		AND Balance.Lot = DD.Lot
		|		AND Balance.LotVendorAttributes = DD.LotVendorAttributes
		|WHERE
		|	NOT &AllocationOfAdditionalExpensesByDisposedGoods
		|	AND Balance.ItemsLocationAttributes IS NULL
		|
		|INDEX BY
		|	ItemsLocationAttributes
		|";

	Return QueryText;
	
EndFunction

Function TextMovementExpenseDeviationsInValueCostOfGoods()
	Return 
		"SELECT
		|	""TextMovementExpenseDeviationsInValueCostOfGoods"" AS RequestSource,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.EntryType,
		|	DD.Recorder AS DocumentRegisterRecords,
		|	DD.DocumentSource,
		|
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	DD.AccountingDimensionByPartners,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.GLAccountSettings,
		|	DD.CorLineOfBusiness,
		|	DD.BusinessOperation,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|
		|	CASE WHEN DD.Organization = DD.CorCompany
		|		THEN VALUE(Catalog.Companies.EmptyRef)
		|		ELSE DD.CorCompany
		|	END AS CorCompany,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes,
		|	DD.CorAccountingSection,
		|	DD.CorLot,
		|	DD.LotVendorAttributesCorr,
		|
		|	SUM(DD.CostInclVAT) 	AS Cost,
		|	SUM(DD.CostExcludingVAT) 	AS CostExcludingVAT,
		|	SUM(DD.LocalCost) 	AS LocalCost,
		|	SUM(DD.CostMan) 		AS CostMan,
		|	SUM(DD.AddExpensesForGoods)        AS AddExpensesForGoods,
		|	SUM(DD.AdditionalExpensesExcludingVAT)  AS AdditionalExpensesExcludingVAT,
		|	SUM(DD.AddExpensesLocal)    AS AddExpensesLocal,
		|	SUM(DD.AddExpensesMan)     AS AddExpensesMan,
		|	SUM(DD.VATLocal)           AS VATLocal,
		|	SUM(DD.VATManag)            AS VATManag,
		|	SUM(DD.PermanentDifference) AS PermanentDifference,
		|	SUM(DD.CostTD)  AS CostTD,
		|	SUM(DD.CostOfPersonalIncomeTax)  	AS CostOfPersonalIncomeTax
		|FROM
		|	(SELECT
		|		DD.Recorder,
		|		DD.Period,
		|		(CASE
		|			WHEN NOT DD.ThisIsOutlier THEN DD.EntryType
		|			ELSE VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods) END) AS EntryType,
		|
		|		ISNULL(GoodsInTransit.CorItemsLocationAttributes, DD.ItemsLocationAttributes) AS ItemsLocationAttributes,
		|		ISNULL(GoodsInTransit.CorAccountingSection, DD.AccountingSection) AS AccountingSection,
		|		ISNULL(GoodsInTransit.CorInventoryOwnerAttribute, DD.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
		|		DD.Organization,
		|		DD.CorCompany,
		|		ISNULL(GoodsInTransit.CorLot, DD.Lot) AS Lot,
		|		ISNULL(GoodsInTransit.LotVendorAttributesCorr, DD.LotVendorAttributes) AS LotVendorAttributes,
		|		ISNULL(GoodsInTransit.CorControllingAttributes, DD.FinancialAccountingDimension) AS FinancialAccountingDimension,
		|		ISNULL(GoodsInTransit.CorVATActivityTypes, DD.VATActivityType) AS VATActivityType,
		|
		|		DD.AccountingDimensionByPartners,
		|		DD.Department,
		|		DD.DimensionOfExpenses,
		|		DD.ItemOfExpenditureWriteOffMan AS ExpenseItemOfWriteOff,
		|		DD.AssetAndLiabilityItem,
		|		DD.AssetsLiabilitiesDimension,
		|		DD.GLAccountSettings,
		|		DD.CorLineOfBusiness,
		|		DD.BusinessOperation,
		|		DD.FinRecordID,
		|		DD.BusinessTransactionSetting,
		|
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN UNDEFINED
		|			 ELSE ISNULL(GoodsInTransit.ItemsLocationAttributes, DD.CorItemsLocationAttributes)
		|		END AS CorItemsLocationAttributes,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN UNDEFINED
		|			 ELSE ISNULL(GoodsInTransit.InventoryOwnerAttribute, DD.CorInventoryOwnerAttribute)
		|		END AS CorInventoryOwnerAttribute,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN UNDEFINED
		|			 ELSE ISNULL(GoodsInTransit.FinancialAccountingDimension, DD.CorControllingAttributes)
		|		END AS CorControllingAttributes,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN DD.TypeOfActivityVATDisposals
		|			 ELSE ISNULL(GoodsInTransit.VATActivityType, DD.CorVATActivityTypes)
		|		END AS CorVATActivityTypes,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN UNDEFINED
		|			 ELSE ISNULL(GoodsInTransit.AccountingSection, DD.CorAccountingSection)
		|		END AS CorAccountingSection,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN UNDEFINED
		|			 ELSE ISNULL(GoodsInTransit.Lot, DD.CorLot)
		|		END AS CorLot,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN ISNULL(AdditionalExpensesAmountWithoutQuantity.LotVendorAttributesCorr, DD.LotVendorAttributesCorr)
		|			 ELSE ISNULL(GoodsInTransit.LotVendorAttributes, DD.LotVendorAttributesCorr)
		|		END AS LotVendorAttributesCorr,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN ISNULL(AdditionalExpensesAmountWithoutQuantity.DocumentSource, UNDEFINED)
		|			 ELSE UNDEFINED
		|		END AS DocumentSource,
		|
		|		DD.CostInclVAT	AS CostInclVAT,
		|		DD.CostExcludingVAT	AS CostExcludingVAT,
		|		0					AS LocalCost,
		|		DD.CostMan		AS CostMan,
		|		DD.AdditionalExpensesIncludingVAT   AS AddExpensesForGoods,
		|		DD.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
		|		0                   AS AddExpensesLocal,
		|		DD.AddExpensesMan    AS AddExpensesMan,
		|		0                   AS VATLocal,
		|		DD.VATManag           AS VATManag,
		|		0                   AS PermanentDifference,
		|		0                   AS CostTD,
		|		0                   AS CostOfPersonalIncomeTax
		|	FROM
		|		IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|		LEFT JOIN TTReceiptOfGoodsInTransitPastPeriods AS GoodsInTransit
		|		ON DD.ItemsLocationAttributes = GoodsInTransit.ItemsLocationAttributes
		|			AND DD.Organization = GoodsInTransit.Organization
		|			AND DD.Lot = GoodsInTransit.Lot
		|			AND DD.Recorder = GoodsInTransit.Recorder
		|			AND DD.AccountingSection = GoodsInTransit.AccountingSection
		|			AND DD.InventoryOwnerAttribute = GoodsInTransit.InventoryOwnerAttribute
		|			AND DD.LotVendorAttributes = GoodsInTransit.LotVendorAttributes
		|			AND DD.FinancialAccountingDimension = GoodsInTransit.FinancialAccountingDimension
		|			AND DD.VATActivityType = GoodsInTransit.VATActivityType
		|		LEFT JOIN TTAdditionalExpensesAmountWithoutQuantity AS AdditionalExpensesAmountWithoutQuantity
		|		ON (AdditionalExpensesAmountWithoutQuantity.Recorder = DD.Recorder)
		|			AND (AdditionalExpensesAmountWithoutQuantity.Lot = DD.Lot)
		|			AND (AdditionalExpensesAmountWithoutQuantity.Organization = DD.Organization)
		|			AND (AdditionalExpensesAmountWithoutQuantity.ItemsLocationAttributes = DD.ItemsLocationAttributes)
		|			AND (AdditionalExpensesAmountWithoutQuantity.AccountingSection = DD.AccountingSection)
		|			AND (AdditionalExpensesAmountWithoutQuantity.InventoryOwnerAttribute = DD.InventoryOwnerAttribute)
		|			AND (AdditionalExpensesAmountWithoutQuantity.LotVendorAttributes = DD.LotVendorAttributes)
		|			AND (AdditionalExpensesAmountWithoutQuantity.VATActivityType = DD.VATActivityType)
		|			AND (AdditionalExpensesAmountWithoutQuantity.FinancialAccountingDimension = DD.FinancialAccountingDimension)
		|
		|	UNION ALL
		|
		|	SELECT
		|		DD.Recorder,
		|		DD.Period,
		|		(CASE
		|			WHEN NOT DD.ThisIsOutlier THEN DD.EntryType
		|			ELSE VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods) END) AS EntryType,
		|
		|		ISNULL(GoodsInTransit.CorItemsLocationAttributes, DD.ItemsLocationAttributes) AS ItemsLocationAttributes,
		|		ISNULL(GoodsInTransit.CorAccountingSection, DD.AccountingSection) AS AccountingSection,
		|		ISNULL(GoodsInTransit.CorInventoryOwnerAttribute, DD.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
		|		DD.Organization,
		|		DD.CorCompany,
		|		ISNULL(GoodsInTransit.CorLot, DD.Lot) AS Lot,
		|		ISNULL(GoodsInTransit.LotVendorAttributesCorr, DD.LotVendorAttributes) AS LotVendorAttributes,
		|		ISNULL(GoodsInTransit.CorControllingAttributes, DD.FinancialAccountingDimension) AS FinancialAccountingDimension,
		|		ISNULL(GoodsInTransit.CorVATActivityTypes, DD.VATActivityType) AS VATActivityType,
		|
		|		DD.AccountingDimensionByPartners,
		|		DD.Department,
		|		DD.DimensionOfExpenses,
		|		DD.LocalDepreciationExpenseItem AS ExpenseItemOfWriteOff,
		|		DD.AssetAndLiabilityItem,
		|		DD.AssetsLiabilitiesDimension,
		|		DD.GLAccountSettings,
		|		DD.CorLineOfBusiness,
		|		DD.BusinessOperation,
		|		DD.FinRecordID,
		|		DD.BusinessTransactionSetting,
		|
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN UNDEFINED
		|			 ELSE ISNULL(GoodsInTransit.ItemsLocationAttributes, DD.CorItemsLocationAttributes)
		|		END AS CorItemsLocationAttributes,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN UNDEFINED
		|			 ELSE ISNULL(GoodsInTransit.InventoryOwnerAttribute, DD.CorInventoryOwnerAttribute)
		|		END AS CorInventoryOwnerAttribute,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN UNDEFINED
		|			 ELSE ISNULL(GoodsInTransit.FinancialAccountingDimension, DD.CorControllingAttributes)
		|		END AS CorControllingAttributes,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN DD.TypeOfActivityVATDisposals
		|			 ELSE ISNULL(GoodsInTransit.VATActivityType, DD.CorVATActivityTypes)
		|		END AS CorVATActivityTypes,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN UNDEFINED
		|			 ELSE ISNULL(GoodsInTransit.AccountingSection, DD.CorAccountingSection)
		|		END AS CorAccountingSection,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN UNDEFINED
		|			 ELSE ISNULL(GoodsInTransit.Lot, DD.CorLot)
		|		END AS CorLot,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN ISNULL(AdditionalExpensesAmountWithoutQuantity.LotVendorAttributesCorr, DD.LotVendorAttributesCorr)
		|			 ELSE ISNULL(GoodsInTransit.LotVendorAttributes, DD.LotVendorAttributesCorr)
		|		END AS LotVendorAttributesCorr,
		|		CASE
		|			WHEN DD.ThisIsOutlier THEN ISNULL(AdditionalExpensesAmountWithoutQuantity.DocumentSource, UNDEFINED)
		|			 ELSE UNDEFINED
		|		END AS DocumentSource,
		|
		|		0 AS CostInclVAT,
		|		0 AS CostExcludingVAT,
		|		DD.LocalCost AS LocalCost,
		|		0 AS CostMan,
		|		0 AS AddExpensesForGoods,
		|		0 AS AdditionalExpensesExcludingVAT,
		|		DD.AddExpensesLocal,
		|		0 AS AddExpensesMan,
		|		DD.VATLocal,
		|		0 AS VATManag,
		|		(CASE
		|			WHEN DD.ThisIsOutlier THEN 0
		|			ELSE DD.PermanentDifference END) AS PermanentDifference,
		|		(CASE
		|			WHEN DD.ThisIsOutlier THEN 0
		|			ELSE DD.CostTD END) AS CostTD,
		|		DD.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax
		|	FROM
		|		IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|		LEFT JOIN TTReceiptOfGoodsInTransitPastPeriods AS GoodsInTransit
		|		ON DD.ItemsLocationAttributes = GoodsInTransit.ItemsLocationAttributes
		|			AND DD.Organization = GoodsInTransit.Organization
		|			AND DD.Lot = GoodsInTransit.Lot
		|			AND DD.Recorder = GoodsInTransit.Recorder
		|			AND DD.AccountingSection = GoodsInTransit.AccountingSection
		|			AND DD.InventoryOwnerAttribute = GoodsInTransit.InventoryOwnerAttribute
		|			AND DD.LotVendorAttributes = GoodsInTransit.LotVendorAttributes
		|			AND DD.FinancialAccountingDimension = GoodsInTransit.FinancialAccountingDimension
		|			AND DD.VATActivityType = GoodsInTransit.VATActivityType
		|		LEFT JOIN TTAdditionalExpensesAmountWithoutQuantity AS AdditionalExpensesAmountWithoutQuantity
		|		ON (AdditionalExpensesAmountWithoutQuantity.Recorder = DD.Recorder)
		|			AND (AdditionalExpensesAmountWithoutQuantity.Lot = DD.Lot)
		|			AND (AdditionalExpensesAmountWithoutQuantity.Organization = DD.Organization)
		|			AND (AdditionalExpensesAmountWithoutQuantity.ItemsLocationAttributes = DD.ItemsLocationAttributes)
		|			AND (AdditionalExpensesAmountWithoutQuantity.AccountingSection = DD.AccountingSection)
		|			AND (AdditionalExpensesAmountWithoutQuantity.InventoryOwnerAttribute = DD.InventoryOwnerAttribute)
		|			AND (AdditionalExpensesAmountWithoutQuantity.LotVendorAttributes = DD.LotVendorAttributes)
		|			AND (AdditionalExpensesAmountWithoutQuantity.VATActivityType = DD.VATActivityType)
		|			AND (AdditionalExpensesAmountWithoutQuantity.FinancialAccountingDimension = DD.FinancialAccountingDimension)
		|
		// If there is no distribution base for deviations in the batch of the previous period, then such deviations should 
		// be written off to the expense item "Disposals of goods in previous periods".
		// For such deviations, the "Access period" field must be earlier than the beginning of the period.
		// The conditions for data sampling must be the same in the textsfunctions of the textmovementsreferences in the cost and cost of goods(),
		// The text of the movement of the right to bow down in the cost of your expenses() and the text of the movement of the right to bow down in the cost of the nomenclature of income expenses()
		|	UNION ALL
		|
		|	SELECT
		|		DD.Recorder,
		|		DD.Period,
		|		VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods) AS EntryType,
		|
		|		DD.ItemsLocationAttributes,
		|		DD.AccountingSection,
		|		DD.InventoryOwnerAttribute,
		|		DD.Organization,
		|		DD.Organization AS CorCompany,
		|		DD.Lot,
		|		DD.LotVendorAttributes,
		|		DD.FinancialAccountingDimension,
		|		DD.VATActivityType,
		|
		|		UNDEFINED AS AccountingDimensionByPartners,
		|		(CASE
		|			WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|				THEN Dimension.Department
		|			ELSE Dimension.WarehouseArea.Department END) AS Department,
		|		Dimension.Products AS DimensionOfExpenses,
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods) AS ExpenseItemOfWriteOff,
		|		UNDEFINED AS AssetAndLiabilityItem,
		|		UNDEFINED AS AssetsLiabilitiesDimension,
		|		UNDEFINED AS GLAccountSettings,
		|		ISNULL(Dimension.Purpose.LineOfBusiness, UNDEFINED) AS CorLineOfBusiness,
		|		DD.BusinessTransactionSetting.BusinessOperation AS BusinessOperation,
		|		DD.FinRecordID,
		|		DD.BusinessTransactionSetting,
		|
		|		UNDEFINED AS CorItemsLocationAttributes,
		|		UNDEFINED AS CorInventoryOwnerAttribute,
		|		UNDEFINED AS CorControllingAttributes,
		|		UNDEFINED AS CorVATActivityTypes,
		|		UNDEFINED AS CorAccountingSection,
		|		UNDEFINED AS CorLot,
		|		ISNULL(AdditionalExpensesAmountWithoutQuantity.LotVendorAttributesCorr, DD.LotVendorAttributes) AS LotVendorAttributesCorr,
		|		ISNULL(AdditionalExpensesAmountWithoutQuantity.DocumentSource, UNDEFINED) AS DocumentSource,
		|
		|		DD.CostToDistribution AS CostInclVAT,
		|		DD.CostWithoutNDSKDistribution AS CostExcludingVAT,
		|		DD.CostLocalToDistribution AS LocalCost,
		|		DD.ManSCostToDistribution AS CostMan,
		|		DD.AdditionalCostsSNDSKDistribution AS AddExpensesForGoods,
		|		DD.AdditionalExpensesWithoutNDSKDISTRIBUTION AS AdditionalExpensesExcludingVAT,
		|		DD.AdditionalExpensesOfLocalNDSKDistribution AS AddExpensesLocal,
		|		DD.AdditionalExpensesOfManNDSKDistribution AS AddExpensesMan,
		|		DD.VATLocalToDistribution AS VATLocal,
		|		DD.VATManForDistribution AS VATManag,
		|		DD.ConstantDifferenceToDistribution AS PermanentDifference,
		|		DD.TemporalDifferenceToDistribution AS CostTD,
		|		DD.CostOfPersonalIncomeTaxDistribution AS CostOfPersonalIncomeTax
		|	FROM
		|		ReceiversForGoodsOfPastPeriodsWithoutRegisteringRecordedCost AS DD
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|			ON Dimension.Ref = DD.ItemsLocationAttributes
		|		LEFT JOIN TTAdditionalExpensesAmountWithoutQuantity AS AdditionalExpensesAmountWithoutQuantity
		|		ON (AdditionalExpensesAmountWithoutQuantity.Recorder = DD.Recorder)
		|			AND (AdditionalExpensesAmountWithoutQuantity.Lot = DD.Lot)
		|			AND (AdditionalExpensesAmountWithoutQuantity.Organization = DD.Organization)
		|			AND (AdditionalExpensesAmountWithoutQuantity.ItemsLocationAttributes = DD.ItemsLocationAttributes)
		|			AND (AdditionalExpensesAmountWithoutQuantity.AccountingSection = DD.AccountingSection)
		|			AND (AdditionalExpensesAmountWithoutQuantity.InventoryOwnerAttribute = DD.InventoryOwnerAttribute)
		|			AND (AdditionalExpensesAmountWithoutQuantity.LotVendorAttributes = DD.LotVendorAttributes)
		|			AND (AdditionalExpensesAmountWithoutQuantity.VATActivityType = DD.VATActivityType)
		|			AND (AdditionalExpensesAmountWithoutQuantity.FinancialAccountingDimension = DD.FinancialAccountingDimension)
		|
		|	UNION ALL
		|
		|	SELECT
		|		DD.Recorder,
		|		DD.Period,
		|		VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods) AS EntryType,
		|
		|		ISNULL(GoodsInTransit.CorItemsLocationAttributes, DD.ItemsLocationAttributes) AS ItemsLocationAttributes,
		|		ISNULL(GoodsInTransit.CorAccountingSection, DD.AccountingSection) AS AccountingSection,
		|		ISNULL(GoodsInTransit.CorInventoryOwnerAttribute, DD.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
		|		DD.Organization,
		|		DD.CorCompany,
		|		ISNULL(GoodsInTransit.CorLot, DD.Lot) AS Lot,
		|		ISNULL(GoodsInTransit.LotVendorAttributesCorr, DD.LotVendorAttributes) AS LotVendorAttributes,
		|		ISNULL(GoodsInTransit.CorControllingAttributes, DD.FinancialAccountingDimension) AS FinancialAccountingDimension,
		|		ISNULL(GoodsInTransit.CorVATActivityTypes, DD.VATActivityType) AS VATActivityType,
		|
		|		DD.AccountingDimensionByPartners,
		|		DD.Department,
		|		DD.ItemsLocationAttributes.Products AS DimensionOfExpenses,
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.GoodsValueVariance) AS ExpenseItemOfWriteOff,
		|		UNDEFINED AS AssetAndLiabilityItem,
		|		UNDEFINED AS AssetsLiabilitiesDimension,
		|		UNDEFINED AS GLAccountSettings,
		|		DD.CorLineOfBusiness,
		|		VALUE(Enum.BusinessTransactions.GoodsValueVarianceExpenses) AS BusinessOperation,
		|		MAX(DD.FinRecordID) AS FinRecordID,
		|		VALUE(Catalog.BusinessTransactionsSettings.GoodsValueVarianceExpenses) AS BusinessTransactionSetting,
		|
		|		UNDEFINED AS CorItemsLocationAttributes,
		|		UNDEFINED AS CorInventoryOwnerAttribute,
		|		UNDEFINED AS CorControllingAttributes,
		|		UNDEFINED AS CorVATActivityTypes,
		|		UNDEFINED AS CorAccountingSection,
		|		UNDEFINED AS CorLot,
		|		ISNULL(AdditionalExpensesAmountWithoutQuantity.LotVendorAttributesCorr, DD.LotVendorAttributes) AS LotVendorAttributesCorr,
		|		ISNULL(AdditionalExpensesAmountWithoutQuantity.DocumentSource, UNDEFINED) AS DocumentSource,
		|
		|		0 AS CostInclVAT,
		|		0 AS CostExcludingVAT,
		|		0 AS LocalCost,
		|		0 AS CostMan,
		|		0 AS AddExpensesForGoods,
		|		0 AS AdditionalExpensesExcludingVAT,
		|		0 AS AddExpensesLocal,
		|		0 AS AddExpensesMan,
		|		0 AS VATLocal,
		|		0 AS VATManag,
		|		SUM(DD.PermanentDifference) AS PermanentDifference,
		|		SUM(DD.CostTD) AS CostTD,
		|		0 AS CostOfPersonalIncomeTax
		|	FROM
		|		IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|		LEFT JOIN TTReceiptOfGoodsInTransitPastPeriods AS GoodsInTransit
		|		ON DD.ItemsLocationAttributes = GoodsInTransit.ItemsLocationAttributes
		|			AND DD.Organization = GoodsInTransit.Organization
		|			AND DD.Lot = GoodsInTransit.Lot
		|			AND DD.Recorder = GoodsInTransit.Recorder
		|			AND DD.AccountingSection = GoodsInTransit.AccountingSection
		|			AND DD.InventoryOwnerAttribute = GoodsInTransit.InventoryOwnerAttribute
		|			AND DD.LotVendorAttributes = GoodsInTransit.LotVendorAttributes
		|			AND DD.FinancialAccountingDimension = GoodsInTransit.FinancialAccountingDimension
		|			AND DD.VATActivityType = GoodsInTransit.VATActivityType
		|		LEFT JOIN TTAdditionalExpensesAmountWithoutQuantity AS AdditionalExpensesAmountWithoutQuantity
		|		ON (AdditionalExpensesAmountWithoutQuantity.Recorder = DD.Recorder)
		|			AND (AdditionalExpensesAmountWithoutQuantity.Lot = DD.Lot)
		|			AND (AdditionalExpensesAmountWithoutQuantity.Organization = DD.Organization)
		|			AND (AdditionalExpensesAmountWithoutQuantity.ItemsLocationAttributes = DD.ItemsLocationAttributes)
		|			AND (AdditionalExpensesAmountWithoutQuantity.AccountingSection = DD.AccountingSection)
		|			AND (AdditionalExpensesAmountWithoutQuantity.InventoryOwnerAttribute = DD.InventoryOwnerAttribute)
		|			AND (AdditionalExpensesAmountWithoutQuantity.LotVendorAttributes = DD.LotVendorAttributes)
		|			AND (AdditionalExpensesAmountWithoutQuantity.VATActivityType = DD.VATActivityType)
		|			AND (AdditionalExpensesAmountWithoutQuantity.FinancialAccountingDimension = DD.FinancialAccountingDimension)
		|	WHERE
		|		DD.ThisIsOutlier
		|		AND (DD.PermanentDifference <> 0 OR DD.CostTD <> 0)
		|
		|	GROUP BY
		|		DD.Recorder,
		|		DD.Period,
		|		DD.EntryType,
		|
		|		ISNULL(GoodsInTransit.CorItemsLocationAttributes, DD.ItemsLocationAttributes),
		|		ISNULL(GoodsInTransit.CorAccountingSection, DD.AccountingSection),
		|		ISNULL(GoodsInTransit.CorInventoryOwnerAttribute, DD.InventoryOwnerAttribute),
		|		DD.Organization,
		|		DD.CorCompany,
		|		ISNULL(GoodsInTransit.CorLot, DD.Lot),
		|		ISNULL(GoodsInTransit.LotVendorAttributesCorr, DD.LotVendorAttributes),
		|		ISNULL(GoodsInTransit.CorControllingAttributes, DD.FinancialAccountingDimension),
		|		ISNULL(GoodsInTransit.CorVATActivityTypes, DD.VATActivityType),
		|
		|		DD.AccountingDimensionByPartners,
		|		DD.Department,
		|		DD.ItemsLocationAttributes.Products,
		|		DD.CorLineOfBusiness,
		|		ISNULL(AdditionalExpensesAmountWithoutQuantity.LotVendorAttributesCorr, DD.LotVendorAttributes),
		|		ISNULL(AdditionalExpensesAmountWithoutQuantity.DocumentSource, UNDEFINED)
		|
		|	) AS DD
		|WHERE
		|	NOT (DD.ItemsLocationAttributes = DD.CorItemsLocationAttributes
		|		AND DD.AccountingSection = DD.CorAccountingSection
		|		AND DD.InventoryOwnerAttribute = DD.CorInventoryOwnerAttribute
		|		AND DD.Lot = DD.CorLot
		|		AND DD.LotVendorAttributes = DD.LotVendorAttributesCorr
		|		AND DD.FinancialAccountingDimension = DD.CorControllingAttributes
		|		AND DD.VATActivityType = DD.CorVATActivityTypes)
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.Period,
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	CASE WHEN DD.Organization = DD.CorCompany
		|		THEN VALUE(Catalog.Companies.EmptyRef)
		|		ELSE DD.CorCompany
		|	END,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.LotVendorAttributesCorr,
		|	DD.DocumentSource,
		|	DD.AccountingDimensionByPartners,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.GLAccountSettings,
		|	DD.CorLineOfBusiness,
		|	DD.BusinessOperation,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorControllingAttributes,
		|	DD.CorLot,
		|	DD.CorVATActivityTypes,
		|	DD.CorAccountingSection";
		
EndFunction

Function TextMovementArrivalOfDeviationsInValueCostOfGoods()
	Return "
		|SELECT
		|	""TextMovementArrivalOfDeviationsInValueCostOfGoods"" AS RequestSource,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.EntryType,
		|	DD.Recorder AS DocumentRegisterRecords,
		|	UNDEFINED AS DocumentSource,
		|
		|	DD.CorItemsLocationAttributes AS ItemsLocationAttributes,
		|	DD.CorAccountingSection AS AccountingSection,
		|	DD.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.CorCompany AS Organization,
		|	DD.CorLot AS Lot,
		|	DD.LotVendorAttributesCorr AS LotVendorAttributes,
		|	DD.CorControllingAttributes AS FinancialAccountingDimension,
		|	DD.CorVATActivityTypes AS VATActivityType,
		|
		|	UNDEFINED AS AccountingDimensionByPartners,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS ExpenseItemOfWriteOff,
		|	UNDEFINED AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS GLAccountSettings,
		|	UNDEFINED AS CorLineOfBusiness,
		|	DD.BusinessOperation,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|
		|	UNDEFINED AS CorCompany,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	UNDEFINED AS CorControllingAttributes,
		|	UNDEFINED AS CorVATActivityTypes,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS LotVendorAttributesCorr,
		|
		|	SUM(DD.CostInclVAT) 	AS Cost,
		|	SUM(DD.CostExcludingVAT) 	AS CostExcludingVAT,
		|	SUM(DD.LocalCost) 	AS LocalCost,
		|	SUM(DD.CostMan) 		AS CostMan,
		|	SUM(DD.AdditionalExpensesIncludingVAT)    AS AddExpensesForGoods,
		|	SUM(DD.AdditionalExpensesExcludingVAT)  AS AdditionalExpensesExcludingVAT,
		|	SUM(DD.AddExpensesLocal)    AS AddExpensesLocal,
		|	SUM(DD.AddExpensesMan)     AS AddExpensesMan,
		|	SUM(DD.VATLocal)           AS VATLocal,
		|	SUM(DD.VATManag)            AS VATManag,
		|	SUM(DD.PermanentDifference) AS PermanentDifference,
		|	SUM(DD.CostTD)  AS CostTD,
		|	SUM(DD.CostOfPersonalIncomeTax)  	AS CostOfPersonalIncomeTax
		|FROM
		|	IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|WHERE
		|	NOT DD.ThisIsOutlier
		|	AND NOT (DD.ItemsLocationAttributes = DD.CorItemsLocationAttributes
		|		AND DD.AccountingSection = DD.CorAccountingSection
		|		AND DD.InventoryOwnerAttribute = DD.CorInventoryOwnerAttribute
		|		AND DD.Lot = DD.CorLot
		|		AND DD.LotVendorAttributes = DD.LotVendorAttributesCorr
		|		AND DD.FinancialAccountingDimension = DD.CorControllingAttributes
		|		AND DD.VATActivityType = DD.CorVATActivityTypes)
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.Period,
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorLot,
		|	DD.LotVendorAttributesCorr,
		|	DD.BusinessOperation,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes";
		
EndFunction

Function TextMovementOfDeviationsInValueRevenueAndCostOfSales()
	Return "
		|SELECT
		|	""TextMovementOfDeviationsInValueRevenueAndCostOfSales"" AS RequestSource,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Recorder AS DocumentRegisterRecords,
		|
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.BusinessOperation,
		|
		|	DD.Manager,
		|	DD.Warehouse,
		|	DD.Terms,
		|	DD.Contract,
		|	DD.InventoryType,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.SourceOfProductFinancialAccountingGroup,
		|	DD.SourceOfARAPFinancialAccountingGroup,
		|
		|	DD.CounterpartyLineOfBusiness,
		|	DD.ProductLineOfBusiness,
		|
		|	SUM(DD.CostInclVAT) 	AS Cost,
		|	SUM(DD.CostExcludingVAT) 	AS CostExcludingVAT,
		|	SUM(DD.LocalCost) 	AS LocalCost,
		|	SUM(DD.CostMan) 		AS CostMan,
		|	SUM(DD.AdditionalExpensesIncludingVAT)    AS AddExpensesForGoods,
		|	SUM(DD.AdditionalExpensesExcludingVAT)  AS AdditionalExpensesExcludingVAT,
		|	SUM(DD.AddExpensesLocal)    AS AddExpensesLocal,
		|	SUM(DD.AddExpensesMan)     AS AddExpensesMan,
		|	SUM(DD.VATLocal)           AS VATLocal,
		|	SUM(DD.VATManag)            AS VATManag,
		|	0                           AS PermanentDifference,
		|	0                           AS CostTD
		|FROM
		|	IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|WHERE
		|	DD.ThisIsOutlier
		|   AND VALUETYPE(DD.AccountingDimensionByPartners) = TYPE(Catalog.DimensionKeysOfAccountingByPartners)
		|   AND DD.AccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.Period,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.BusinessOperation,
		|	DD.Manager,
		|	DD.Warehouse,
		|	DD.Terms,
		|	DD.Contract,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.InventoryType,
		|	DD.SourceOfProductFinancialAccountingGroup,
		|	DD.SourceOfARAPFinancialAccountingGroup,
		|	DD.CounterpartyLineOfBusiness,
		|	DD.ProductLineOfBusiness
		|";
EndFunction

Function TextMovementArrivalOfDeviationsInValueOtherExpenses() Export
	// The conditions for filling in register resources are similar to the conditions in the function textquestionsatablicautproceeds() of the register manager module Other inputs
	Return "
		|SELECT
		|	""TextMovementArrivalOfDeviationsInValueOtherExpenses"" AS RequestSource,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Recorder AS DocumentRegisterRecords,
		|
		|	DD.Organization,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|
		|	DD.BusinessOperation,
		|	DD.ItemsLocationAttributes,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|
		|	SUM(DD.Sum)             AS Sum,
		|	SUM(DD.AmountExcludingVAT)       AS AmountExcludingVAT,
		|	SUM(DD.SumCompl)         AS SumCompl,
		|	SUM(DD.SumMan)          AS SumMan,
		|	SUM(DD.PermanentDifference) AS PermanentDifference,
		|	SUM(DD.CostTD)  AS CostTD,
		|	SUM(CASE
		|			WHEN AITAccountingPolicy.Organization IS NOT NULL
		|				THEN DD.AITAmount
		|			ELSE 0
		|		END) AS AITAmount
		|FROM
		|	(SELECT
		|		DD.Period,
		|		DD.Recorder,
		|
		|		DD.Organization,
		|		DD.Department,
		|		DD.CorLineOfBusiness AS LineOfBusiness,
		|		DD.ItemOfExpenditureWriteOffMan AS ExpenseItem,
		|		DD.DimensionOfExpenses,
		|
		|		DD.BusinessOperation,
		|		DD.ItemsLocationAttributes,
		|		DD.FinRecordID,
		|		DD.BusinessTransactionSetting,
		|
		|		DD.CostInclVAT + DD.AdditionalExpensesIncludingVAT AS Sum,
		|		(CASE
		|			WHEN NOT ExpenseItems.CostAllocationOptionManag IN (
		|					VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|					VALUE(Enum.CostAllocationOptions.OnOtherAssets))
		|				THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT
		|			ELSE 0 END) AS AmountExcludingVAT,
		|		0 AS SumCompl,
		|		DD.CostMan + DD.AddExpensesMan AS SumMan,
		|		0 AS PermanentDifference,
		|		0 AS CostTD,
		|		0 AS AITAmount
		|	FROM
		|		IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|			ON DD.ItemOfExpenditureWriteOffMan = ExpenseItems.Ref
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS CatDimensionOfProductItem
		|			ON DD.ItemsLocationAttributes = CatDimensionOfProductItem.Ref
		|		LEFT JOIN Catalog.Assignments AS CatAssignments
		|			ON CatDimensionOfProductItem.Purpose = CatAssignments.Ref
		|
		|	UNION ALL
		|
		|	SELECT
		|		DD.Period,
		|		DD.Recorder,
		|
		|		DD.Organization,
		|		DD.Department,
		|		DD.CorLineOfBusiness AS LineOfBusiness,
		|		DD.LocalDepreciationExpenseItem AS ExpenseItem,
		|		DD.DimensionOfExpenses,
		|
		|		DD.BusinessOperation,
		|		DD.ItemsLocationAttributes,
		|		DD.FinRecordID,
		|		DD.BusinessTransactionSetting,
		|
		|		0 AS Sum,
		|		0 AS AmountExcludingVAT,
		|		CASE 
		|			WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
		|				THEN 0
		|			WHEN ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
		|				THEN 0
		|			WHEN ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
		|				AND NOT &VNAManagementIsUsed_2_4
		|				THEN 0
		|			ELSE DD.LocalCost + DD.AddExpensesLocal END AS SumCompl,
		|		0 AS SumMan,
		|		0 AS PermanentDifference,
		|		0 AS CostTD,
		|		0 AS AITAmount
		|	FROM
		|		IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|			ON DD.LocalDepreciationExpenseItem = ExpenseItems.Ref
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS CatDimensionOfProductItem
		|			ON DD.ItemsLocationAttributes = CatDimensionOfProductItem.Ref
		|		LEFT JOIN Catalog.Assignments AS CatAssignments
		|			ON CatDimensionOfProductItem.Purpose = CatAssignments.Ref
		|
		|
		|UNION ALL  
		|
		|	SELECT
		|		DD.Period,
		|		DD.Recorder,
		|
		|		DD.Organization,
		|		DD.Department,
		|		DD.CorLineOfBusiness AS LineOfBusiness,
		|		DD.ItemOfExpenditureWriteOffMan AS ExpenseItem,
		|		DD.DimensionOfExpenses,
		|
		|		VALUE(Enum.BusinessTransactions.InclusionExclusionOfVATInCost),
		|		DD.ItemsLocationAttributes,
		|		DD.FinRecordID,
		|		VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses),
		|
		|		0 AS Sum,
		|		0 AS AmountExcludingVAT,
		|		0 AS SumCompl,
		|		CASE
		|			WHEN DD.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
		|		 	 AND DD.TypeOfActivityVATDisposals IN (&TypesOfTaxationVATIsIncludedInCost)
		|				THEN DD.VATManag
		|			WHEN DD.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|		 	 AND DD.TypeOfActivityVATDisposals IN (&TypesOfTaxationVATIsNotIncludedInCost)
		|				THEN -DD.VATManag
		|			ELSE 0
		|		END AS SumMan,
		|		0 AS PermanentDifference,
		|		0 AS CostTD,
		|		0 AS AITAmount
		|	FROM
		|		IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|			ON DD.ItemOfExpenditureWriteOffMan = ExpenseItems.Ref
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS CatDimensionOfProductItem
		|			ON DD.ItemsLocationAttributes = CatDimensionOfProductItem.Ref
		|		LEFT JOIN Catalog.Assignments AS CatAssignments
		|			ON CatDimensionOfProductItem.Purpose = CatAssignments.Ref
		|		LEFT JOIN InformationRegister.SourceDocumentsData AS SourceDocumentsData
		|			ON SourceDocumentsData.Organization = DD.Organization
		|			AND SourceDocumentsData.Document = DD.Recorder
		|	WHERE
		|		DD.VATActivityType <> DD.TypeOfActivityVATDisposals
		|		AND DD.VATManag <> 0
		|		AND NOT DD.Organization IN(&OrganizationsIncludingVATLotsVersion22)
		|
		|UNION ALL
		|
		|	SELECT
		|		DD.Period,
		|		DD.Recorder,
		|
		|		DD.Organization,
		|		DD.Department,
		|		DD.CorLineOfBusiness AS LineOfBusiness,
		|		DD.LocalDepreciationExpenseItem AS ExpenseItem,
		|		DD.DimensionOfExpenses,
		|
		|		VALUE(Enum.BusinessTransactions.InclusionExclusionOfVATInCost),
		|		DD.ItemsLocationAttributes,
		|		DD.FinRecordID,
		|		VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses),
		|
		|		0 AS Sum,
		|		0 AS AmountExcludingVAT,
		|		CASE
		|			WHEN DD.VATActivityType IN (&TypesOfTaxationVATIsNotIncludedInCost)
		|		 	 AND DD.TypeOfActivityVATDisposals IN (&TypesOfTaxationVATIsIncludedInCost)
		|				THEN DD.VATLocal
		|			WHEN DD.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|		 	 AND DD.TypeOfActivityVATDisposals IN (&TypesOfTaxationVATIsNotIncludedInCost)
		|				THEN -DD.VATLocal
		|			ELSE 0
		|		END AS SumCompl,
		|		0 AS SumMan,
		|		0 AS PermanentDifference,
		|		0 AS CostTD,
		|		0 AS AITAmount
		|	FROM
		|		IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|			ON DD.LocalDepreciationExpenseItem = ExpenseItems.Ref
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS CatDimensionOfProductItem
		|			ON DD.ItemsLocationAttributes = CatDimensionOfProductItem.Ref
		|		LEFT JOIN Catalog.Assignments AS CatAssignments
		|			ON CatDimensionOfProductItem.Purpose = CatAssignments.Ref
		|		LEFT JOIN InformationRegister.SourceDocumentsData AS SourceDocumentsData
		|			ON SourceDocumentsData.Organization = DD.Organization
		|			AND SourceDocumentsData.Document = DD.Recorder
		|	WHERE
		|		DD.VATActivityType <> DD.TypeOfActivityVATDisposals
		|		AND DD.VATLocal <> 0
		|		AND NOT DD.Organization IN(&OrganizationsIncludingVATLotsVersion22)
		|
		// If there is no distribution base for deviations in the batch of the previous period, then such deviations should 
		// be written off to the expense item "Disposals of goods in previous periods".
		// For such deviations, the "Access period" field must be earlier than the beginning of the period.
		// The conditions for data sampling must be the same in the textsfunctions of the textmovementsreferences in the cost and cost of goods(),
		// The text of the movement of the right to bow down in the cost of your expenses() and the text of the movement of the right to bow down in the cost of the nomenclature of income expenses()
		|	UNION ALL
		|
		|	SELECT
		|		DD.Period,
		|		DD.Recorder,
		|
		|		DD.Organization,
		|		(CASE
		|			WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|				THEN Dimension.Department
		|			ELSE Dimension.WarehouseArea.Department END) AS Department,
		|		ISNULL(Dimension.Purpose.LineOfBusiness, UNDEFINED) AS LineOfBusiness,
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods) AS ExpenseItem,
		|		Dimension.Products AS DimensionOfExpenses,
		|
		|		DD.BusinessTransactionSetting.BusinessOperation AS BusinessOperation,
		|		DD.ItemsLocationAttributes,
		|		DD.FinRecordID,
		|		DD.BusinessTransactionSetting,
		|
		|		DD.CostToDistribution + DD.AdditionalCostsSNDSKDistribution AS Sum,
		|		(CASE
		|			WHEN NOT ExpenseItems.CostAllocationOptionManag IN (
		|					VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|					VALUE(Enum.CostAllocationOptions.OnOtherAssets))
		|				THEN DD.CostWithoutNDSKDistribution + DD.AdditionalExpensesWithoutNDSKDISTRIBUTION
		|			ELSE 0 END) AS AmountExcludingVAT,
		|		(CASE 
		|			WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
		|				THEN 0
		|			WHEN ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
		|				THEN 0
		|			WHEN ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
		|				AND NOT &VNAManagementIsUsed_2_4
		|				THEN 0
		|			ELSE DD.CostLocalToDistribution + DD.AdditionalExpensesOfLocalNDSKDistribution END) AS SumCompl,
		|		DD.ManSCostToDistribution + DD.AdditionalExpensesOfManNDSKDistribution AS SumMan,
		|		DD.ConstantDifferenceToDistribution AS PermanentDifference,
		|		DD.TemporalDifferenceToDistribution AS CostTD,
		|		DD.CostOfPersonalIncomeTaxDistribution AS AITAmount
		|	FROM
		|		ReceiversForGoodsOfPastPeriodsWithoutRegisteringRecordedCost AS DD
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|			ON ExpenseItems.Ref = VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods)
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|			ON Dimension.Ref = DD.ItemsLocationAttributes
		|
		|	UNION ALL
		|
		|	SELECT
		|		DD.Period,
		|		DD.Recorder,
		|
		|		DD.Organization,
		|		DD.Department,
		|		DD.CorLineOfBusiness AS LineOfBusiness,
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.GoodsValueVariance) AS ExpenseItem,
		|		DD.ItemsLocationAttributes.Products AS DimensionOfExpenses,
		|
		|		VALUE(Enum.BusinessTransactions.GoodsValueVarianceExpenses) AS BusinessOperation,
		|		UNDEFINED AS ItemsLocationAttributes,
		|		MAX(DD.FinRecordID) AS FinRecordID,
		|		VALUE(Catalog.BusinessTransactionsSettings.GoodsValueVarianceExpenses) AS BusinessTransactionSetting,
		|
		|		0 AS Sum,
		|		0 AS AmountExcludingVAT,
		|		0 AS SumCompl,
		|		0 AS SumMan,
		|		SUM(DD.PermanentDifference) AS PermanentDifference,
		|		SUM(DD.CostTD)  AS CostTD,
		|		SUM(DD.CostOfPersonalIncomeTax) AS AITAmount
		|	FROM
		|		IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|	WHERE
		|		DD.ThisIsOutlier
		|		AND (DD.PermanentDifference <> 0 OR DD.CostTD <> 0
		|		OR DD.CostOfPersonalIncomeTax <> 0
		|		)
		|
		|	GROUP BY
		|		DD.Period,
		|		DD.Recorder,
		|		DD.Organization,
		|		DD.Department,
		|		DD.CorLineOfBusiness,
		|		DD.ItemsLocationAttributes.Products) AS DD
		|
		|	LEFT JOIN AITAccountingPolicy AS AITAccountingPolicy
		|		ON DD.Organization = AITAccountingPolicy.Organization
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Organization,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.BusinessOperation,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|	DD.ItemsLocationAttributes";
		
EndFunction

Function TextMovementArrivalOfDeviationsInValueOfLotOfOtherExpenses()
	// The conditions for filling in register resources are similar to the conditions in the Text Query function for the Automatic Batch and Other Expenses() module of the Batch and Other Expenses register manager
	Return "
		|SELECT
		|	""TextMovementArrivalOfDeviationsInValueOfLotOfOtherExpenses"" AS RequestSource,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Organization,
		|	DD.Department,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.Recorder AS ExpenseReceiptDocument,
		|	DD.LotVendorAttributes,
		|	DD.LineOfBusiness,
		|	DD.VATActivityType,
		|
		|	DD.BusinessOperation,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|
		|	SUM(DD.Cost)         AS Cost,
		|	SUM(DD.CostExcludingVAT)   AS CostExcludingVAT,
		|	SUM(DD.LocalCost)		AS LocalCost,
		|	SUM(DD.VATLocal)          	AS VATLocal,
		|	SUM(DD.VATManag) 			AS VATManag
		|FROM
		|	(SELECT
		|		DD.Period,
		|		DD.Recorder,
		|
		|		DD.Organization,
		|		DD.Department,
		|		DD.ItemOfExpenditureWriteOffMan AS ExpenseItem,
		|		DD.DimensionOfExpenses,
		|		DD.LotVendorAttributes,
		|		DD.CorLineOfBusiness AS LineOfBusiness,
		|		DD.TypeOfActivityVATDisposals AS VATActivityType,
		|
		|		DD.BusinessOperation,
		|		DD.FinRecordID,
		|		DD.BusinessTransactionSetting,
		|
		|		CASE WHEN ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			THEN DD.CostInclVAT + DD.AdditionalExpensesIncludingVAT
		|			ELSE 0
		|		END AS Cost,
		|		CASE WHEN ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT
		|			ELSE 0
		|		END AS CostExcludingVAT,
		|		0 AS LocalCost,
		|		0 AS VATLocal,
		|		CASE
		|			WHEN &CompanyManagementAccounting
		|				AND (ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|				  )
		|			THEN DD.VATManag
		|			ELSE 0
		|		END AS VATManag
		|	FROM
		|		IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|			ON DD.ItemOfExpenditureWriteOffMan = ExpenseItems.Ref
		|
		|	UNION ALL
		|
		|	SELECT
		|		DD.Period,
		|		DD.Recorder,
		|
		|		DD.Organization,
		|		DD.Department,
		|		DD.LocalDepreciationExpenseItem AS ExpenseItem,
		|		DD.DimensionOfExpenses,
		|		DD.LotVendorAttributes,
		|		DD.CorLineOfBusiness AS LineOfBusiness,
		|		DD.TypeOfActivityVATDisposals AS VATActivityType,
		|
		|		DD.BusinessOperation,
		|		DD.FinRecordID,
		|		DD.BusinessTransactionSetting,
		|
		|		0 AS Cost,
		|		0 AS CostExcludingVAT,
		|		CASE 
		|			WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting THEN 0
		|			WHEN ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			THEN DD.LocalCost + DD.AddExpensesLocal
		|			ELSE 0
		|		END AS LocalCost,
		|		CASE
		|			WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting THEN 0
		|			WHEN ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			THEN DD.VATLocal
		|			ELSE 0
		|		END AS VATLocal,
		|		0 AS VATManag
		|	FROM
		|		IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|			ON DD.LocalDepreciationExpenseItem = ExpenseItems.Ref
		|
		|	) AS DD
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Organization,
		|	DD.Department,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.LotVendorAttributes,
		|	DD.LineOfBusiness,
		|	DD.VATActivityType,
		|
		|	DD.BusinessOperation,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting
		|";
		
EndFunction

Function TextMovementOfDeviationsInValueProductsIncomeExpenses()
	Return "
		|SELECT
		|	""TextMovementOfDeviationsInValueProductsIncomeExpenses"" AS RequestSource,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Recorder AS DocumentRegisterRecords,
		|
		|	DD.BusinessOperation,
		|	DD.Organization,
		|	DD.Department,
		|	DD.ProductLineOfBusiness,
		|	DD.ItemsLocationAttributes,
		|	DD.Warehouse,
		|	DD.InventoryType,
		|	DD.InventoryOwnerAttribute,
		|	DD.IncomeAndExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.LineOfBusinessItems,
		|	DD.SourceOfProductFinancialAccountingGroup,
		|
		|	SUM(DD.CostInclVAT) 	AS Cost,
		|	SUM(DD.CostExcludingVAT) 	AS CostExcludingVAT,
		|	SUM(DD.LocalCost) 	AS LocalCost,
		|	SUM(DD.CostMan) 		AS CostMan,
		|	SUM(DD.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(DD.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(DD.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(DD.AddExpensesMan) AS AddExpensesMan,
		|	SUM(DD.PermanentDifference) AS PermanentDifference,
		|	SUM(DD.CostTD)  AS CostTD
		|FROM
		|	(SELECT
		|		DD.Recorder,
		|		DD.Period,
		|
		|		DD.BusinessOperation,
		|		DD.Organization,
		|		DD.Department,
		|		ISNULL(CatAssignments.LineOfBusiness,
		|			VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS ProductLineOfBusiness,
		|		DD.ItemsLocationAttributes,
		|		CatDimensionOfProductItem.StorageLocation AS Warehouse,
		|		DD.InventoryType,
		|		DD.InventoryOwnerAttribute,
		|		DD.ItemOfExpenditureWriteOffMan AS IncomeAndExpenseItem,
		|		DD.DimensionOfExpenses,
		|		DD.CorLineOfBusiness AS LineOfBusinessItems, 
		|		DD.SourceOfProductFinancialAccountingGroup,
		|
		|		DD.CostInclVAT 	AS CostInclVAT,
		|		DD.CostExcludingVAT 	AS CostExcludingVAT,
		|		0 					AS LocalCost,
		|		DD.CostMan 	AS CostMan,
		|		DD.AdditionalExpensesIncludingVAT   AS AddExpensesForGoods,
		|		DD.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
		|		0                   AS AddExpensesLocal,
		|		DD.AddExpensesMan    AS AddExpensesMan,
		|		0                   AS PermanentDifference,
		|		0                   AS CostTD
		|	FROM
		|		IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|			ON DD.ItemOfExpenditureWriteOffMan = ExpenseItems.Ref
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS CatDimensionOfProductItem
		|			ON DD.ItemsLocationAttributes = CatDimensionOfProductItem.Ref
		|		LEFT JOIN Catalog.Assignments AS CatAssignments
		|			ON CatDimensionOfProductItem.Purpose = CatAssignments.Ref
		|
		|	UNION ALL
		|
		|	SELECT
		|		DD.Recorder,
		|		DD.Period,
		|
		|		DD.BusinessOperation,
		|		DD.Organization,
		|		DD.Department,
		|		ISNULL(CatAssignments.LineOfBusiness,
		|			VALUE(Catalog.LinesOfBusiness.EmptyRef)),
		|		DD.ItemsLocationAttributes,
		|		CatDimensionOfProductItem.StorageLocation,
		|		DD.InventoryType,
		|		DD.InventoryOwnerAttribute,
		|		DD.LocalDepreciationExpenseItem,
		|		DD.DimensionOfExpenses,
		|		DD.CorLineOfBusiness AS LineOfBusinessItems,
		|		DD.SourceOfProductFinancialAccountingGroup,
		|
		|		0 AS CostInclVAT,
		|		0 AS CostExcludingVAT,
		|		DD.LocalCost AS LocalCost,
		|		0 AS CostMan,
		|		0,
		|		0,
		|		DD.AddExpensesLocal,
		|		0,
		|		DD.PermanentDifference,
		|		DD.CostTD
		|	FROM
		|		IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|			ON DD.LocalDepreciationExpenseItem = ExpenseItems.Ref
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS CatDimensionOfProductItem
		|			ON DD.ItemsLocationAttributes = CatDimensionOfProductItem.Ref
		|		LEFT JOIN Catalog.Assignments AS CatAssignments
		|			ON CatDimensionOfProductItem.Purpose = CatAssignments.Ref
		|
		// If there is no distribution base for deviations in the batch of the previous period, then such deviations should 
		// be written off to the expense item "Disposals of goods in previous periods".
		// For such deviations, the "Access period" field must be earlier than the beginning of the period.
		// The conditions for data sampling must be the same in the textsfunctions of the textmovementsreferences in the cost and cost of goods(),
		// The text of the movement of the right to bow down in the cost of your expenses() and the text of the movement of the right to bow down in the cost of the nomenclature of income expenses()
		|	UNION ALL
		|
		|	SELECT
		|		DD.Recorder,
		|		DD.Period,
		|
		|		DD.BusinessTransactionSetting.BusinessOperation AS BusinessOperation,
		|		DD.Organization,
		|		(CASE
		|			WHEN Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|				THEN Dimension.Department
		|			ELSE Dimension.WarehouseArea.Department END) AS Department,
		|		ISNULL(Dimension.Purpose.LineOfBusiness, UNDEFINED) AS ProductLineOfBusiness,
		|		DD.ItemsLocationAttributes,
		|		Dimension.StorageLocation AS Warehouse,
		|		DD.InventoryOwnerAttribute.InventoryType AS InventoryType,
		|		DD.InventoryOwnerAttribute,
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods) AS IncomeAndExpenseItem,
		|		Dimension.Products AS DimensionOfExpenses,
		|		ISNULL(Dimension.Purpose.LineOfBusiness, UNDEFINED) AS LineOfBusinessItems,
		|		UNDEFINED AS SourceOfProductFinancialAccountingGroup,
		|
		|		DD.CostToDistribution 		 AS CostInclVAT,
		|		DD.CostWithoutNDSKDistribution AS CostExcludingVAT,
		|		DD.CostLocalToDistribution 	 AS LocalCost,
		|		DD.ManSCostToDistribution 	 AS CostMan,

		|		DD.AdditionalCostsSNDSKDistribution AS AddExpensesForGoods,
		|		DD.AdditionalExpensesWithoutNDSKDISTRIBUTION AS AdditionalExpensesExcludingVAT,
		|		DD.AdditionalExpensesOfLocalNDSKDistribution AS AddExpensesLocal,
		|		DD.AdditionalExpensesOfManNDSKDistribution AS AddExpensesMan,
		|		DD.ConstantDifferenceToDistribution AS PermanentDifference,
		|		DD.TemporalDifferenceToDistribution AS CostTD
		|	FROM
		|		ReceiversForGoodsOfPastPeriodsWithoutRegisteringRecordedCost AS DD
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|			ON Dimension.Ref = DD.ItemsLocationAttributes
		|
		|	) AS DD
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.Period,
		|	DD.BusinessOperation,
		|	DD.Organization,
		|	DD.Department,
		|	DD.ProductLineOfBusiness,
		|	DD.ItemsLocationAttributes,
		|	DD.Warehouse,
		|	DD.InventoryType,
		|	DD.InventoryOwnerAttribute,
		|	DD.IncomeAndExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.LineOfBusinessItems,
		|	DD.SourceOfProductFinancialAccountingGroup";
		
EndFunction

Function TextOfRegisteredRecordReceiptOfDeviationsInValueOtherAssetsLiabilities()
	Return "
		|SELECT
		|	""TextOfRegisteredRecordReceiptOfDeviationsInValueOtherAssetsLiabilities"" AS RequestSource,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Recorder AS DocumentRegisterRecords,
		|
		|	DD.Organization,
		|	DD.Department,
		|	DD.CorLineOfBusiness AS LineOfBusiness,
		|	DD.AssetAndLiabilityItem AS AssetRef,
		|	DD.AssetsLiabilitiesDimension AS Dimension,
		|
		|	VALUE(Enum.MovementSourcesKinds.EmptyRef) AS SourceKind,
		|
		|	SUM(DD.CostInclVAT + DD.AdditionalExpensesIncludingVAT)  AS Sum
		|FROM
		|	IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|	INNER JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS ARTICLES__
		|		ON ARTICLES__.Ref = DD.AssetAndLiabilityItem
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Organization,
		|	DD.Department,
		|	DD.CorLineOfBusiness,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension
		|";
		
EndFunction

Function TextOfRegisteredRecordOfDeviationsInValueOfRegisteredRecordOfOtherAssetsLiabilities()
	Return "
		|SELECT
		|	""TextOfRegisteredRecordOfDeviationsInValueOfRegisteredRecordOfOtherAssetsLiabilities"" AS RequestSource,
		|
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Recorder AS DocumentRegisterRecords,
		|
		|	DD.Organization,
		|	DD.Department,
		|	DD.CorLineOfBusiness AS LineOfBusiness,
		|	DD.AssetAndLiabilityItem AS AssetRef,
		|	DD.AssetsLiabilitiesDimension AS Dimension,
		|	DD.GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
		|
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|
		|	SUM(DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT) AS AmountExcludingVAT,
		|	SUM(DD.CostInclVAT + DD.AdditionalExpensesIncludingVAT) AS AmountIncludingVAT,
		|	SUM(DD.LocalCost + DD.AddExpensesLocal) AS SumCompl,
		|	SUM(DD.CostMan + DD.AddExpensesMan) AS SumMan,
		|	SUM(DD.PermanentDifference) AS PermanentDifference,
		|	SUM(DD.CostTD) AS CostTD
		|FROM
		|	IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS DD
		|	INNER JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS ARTICLES__
		|		ON ARTICLES__.Ref = DD.AssetAndLiabilityItem
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Organization,
		|	DD.Department,
		|	DD.CorLineOfBusiness,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.GLAccountSettings,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID
		|";
		
EndFunction

#EndRegion

#Region ProceduresOfStep10_AllocationOfAdditionalCostsBetweenBatchesAndGoods

#Region Description_DistributionOfAdditionalCostsBetweenPartiesAndGoods

// The stage of distribution of additional expenses between batches of goods prepares the distribution base and generates
// temporary tables for additional expenses.
// The output data of the stage is generated in the function of the text Additional expenses() depending on the attribute of this part of the previous period.
// The attribute of this part of the past period is defined in the source data sampling functions:
// 	- The template text of the primary receivers...
// For the batch of the Cur period, the distribution base is stored in the temporary table of the receiver to the goods.
// For a batch of the previous period, the distribution base is stored in a temporary table of indicators of the base of distribution of receivers of the past periods.
//
// Auxiliary temporary tables are formed for the distribution of expenses:
// - AnalyticiZakazov - table of analysts for the selection of movements of the cost of goods, because in the movements of the cost of goods
//	there is no information about orders.
//	The table is generated by several queries:
//	1) Purchases of goods ordered by the supplier, except for purchases of goods for which receipts to the warehouse have been registered.
//		The data of the movements "Expense" is used according to the register of the order to the suppliers.
//		The availability of completed receipts of goods to the warehouse is determined by the movements of the "Expense" according to the register of goods
//		with the completed quantity in the resource of the Co-form of access to the distribution.
//		If the constant distribution of the cost of goods is enabled in the way of suppliers, then the check for the availability of goods to the warehouse
//		is not performed. In this case, distribution analysts should be determined only by purchases of goods in request 3.
//	2) Purchases of goods for all orders to suppliers of the Cur period, if the cost analysis does not specify an order to the supplier.
//		The selection of collisions is performed similarly to query 1.
//	3) Receipts for goods in transit from suppliers.
//		The data of the "Expense" movements are used according to the register of goods with the completed quantity 
//		in the resource of the Co-formalization of access to the distribution and selection for business operations of the purchase of goods in transit.
//		The data is selected only if the constant of the distribution of the costs of the suppliers is disabled.
//		When the constant distribution of the cost of goods is enabled, the data is selected in queries 1 and 2. 
//	4) Receipt of goods for unfactured deliveries.
//		The data of the "Expense" movements are used according to the register of goods with the completed quantity 
//		in the resource of the Co-formalization of access to the distribution and selection for business operations of the invoice of delivery.
//	5) Moving orders by moving order
//		The data of the "Expense" movements according to the order register is used.
//	6) Movement of goods for the Cur period, if the cost analysis does not specify a transfer order.
//		The data of the "Expense" movements according to the order register is used.
//	7) Assembly/disassembly of goods on assembly orders
//		The data of the movements "Consumption" according to the register of the order for assembly according to the type of assembly "Receipt" is used.
//	8) Assembly/disassembly of goods of the Cur period, if the cost analysis does not specify an assembly order
//		The data of the movements "Expense" according to the register of the order for assembly according to the type of assembly "Receipt" is used
//	
// The source data for the distribution base is selected in different functions depending on the type of cost analytics value.
// 1) Cost analytics "Order to supplier", "Transfer order", "Assembly order"
//	The selection is described in the Template Text functionThe primary receivers of orders()
//	The selection of data is performed according to the temporary table of order analyticsreferences
//	The batch of the previous period is determined by the presence of movements in the cost of goods for the specified order in the previous period. 
//
// 2) Cost analysis "Customs declaration for spoilage"
//	The sample is described in the Template Text functionThe primary receivers of declarations()
//
// 3) Cost analytics "Purchase of goods and services" and other documents other than the customs declaration for imports and orders
//	The sample is described in the Template Text functionThe primary receivers of the documents()
//	Previously, movements from the "Cost of goods" register are selected in the temporary table of movements of the highest value of the documents
//	The batches of the Cur period include receipts of documents that are either batches or reflect the movement
//	of goods between analysts. Such movements can have record types: Batch, Move, or Move separately
//	Features of obtaining data on individual analysts:
//		- For additional expenses for documents "Purchase of goods and services (invoicing of delivery)" the distribution base
//		is selected from the movements of documents in the accounting section "Unfactated deliveries", but the distribution analytics
//		is taken from the Attributes of the "Cor..." movements to reflect the invoice
//
// 4) Cost analytics "Warehouse", "Nomenclature" and other Catalogs, except for the Catalog "Other expenses"
//	The sample is described in the Template Text functionThe primary receivers for helpers ()
//
// 5) Cost Analytics Catalog "Other expenses". This analytics is enabled only on specific implementations and will be used
//	to set an arbitrary distribution base through DCS selections
//	The selection is described in the Template text functionThe primary receivers and their inputs()
//
// 6) Cost analysis "Contract of the counterparty" and the goods are with the processor.
//	The sample is described in the Template text function of the primary receivers in processing()
//
// The distribution base for disposals of goods in past periods and for the Balance of batches is formed by queries described in 
// the indicator function of the base for the distribution of receivers of past periods().
// The distribution algorithm for disposals in past periods is described in the:
// 	Description_Indicators of the base distributionreception of past periods
//  

#EndRegion

Function TableForAllocationOfAdditionalCosts(CalculationParameters)
	
	Return CostCalculationAppliedAlgorithms.TableForDistributionOfLots(CalculationParameters,
		TextDescriptionOfDataForAllocationOfAdditionalCosts());
	
EndFunction

Function TextDescriptionOfDataForAllocationOfAdditionalCosts() Export
	
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80)) AS RequestSource,
		|	Cost_.Recorder AS Recorder,
		// Receiver of the cost of goods
		|	Cost_.Period AS ReceiptPeriod,
		|	Cost_.Period AS AdjustmentPeriod_,
		|	Cost_.AccountingSection AS CorAccountingSection,
		|	Cost_.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	Cost_.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	Cost_.Organization AS CorCompany,
		|	Cost_.Lot AS CorLot,
		|	Cost_.LotVendorAttributes AS LotVendorAttributesCorr,
		|	Cost_.FinancialAccountingDimension AS CorControllingAttributes,
		|	Cost_.VATActivityType AS CorVATActivityTypes,
		|	Cost_.VATActivityType AS VATTaxationPartySTypeOfActivity,
		|	Cost_.VATActivityType AS TypeOfActivityVATDisposals,
		|	Cost_.BusinessOperation,
		|	Cost_.EntryType,
		|	Cost_.FinRecordID,
		// Receiver Other expenses/Other assets
		|	OtherExpenses.ExpenseItem AS CorExpenseItem,
		|	OtherExpenses.DimensionOfExpenses AS CorExpenditureDimension,
		|	OtherAssetsLiabilities.AssetRef AS CorArticleOfAssetsLiabilities,
		|	OtherAssetsLiabilities.Dimension AS CorDimensionOfAssetsLiabilities,
		|	Cost_.GLAccountSettings AS CorSettingUpAccountingAccounts,
		|	OtherExpenses.Department AS DebitBusinessUnit,
		|	OtherExpenses.LineOfBusiness AS CorLineOfBusiness,
		//Receiver Revenue and cost
		|	RevenueAndCOGS.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	RevenueAndCOGS.SalesOrder AS SalesOrder,
		|	RevenueAndCOGS.Manager AS Manager,
		|	RevenueAndCOGS.Warehouse AS Warehouse,
		|	RevenueAndCOGS.Terms AS Terms,
		|	RevenueAndCOGS.Contract AS Contract,
		|	RevenueAndCOGS.InventoryType AS InventoryType,
		|	RevenueAndCOGS.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
		|	RevenueAndCOGS.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup,
		|	RevenueAndCOGS.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
		// Receiver indicators
		|	Cost_.Count AS Count,
		|	0 AS CostShare,
		|	0 AS ShareOfValueWithoutVAT,
		|	0 AS ShareOfLocalValue,
		|	0 AS ShareValueTa,
		|	0 AS ShareOfCostOfPersonalIncomeTax,
		|	0 AS ShareOfManSCost
		|INTO Data
		|FROM
		|	AccumulationRegister.InventoryCost AS Cost_
		|		LEFT JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
		|		ON TRUE
		|		LEFT JOIN AccumulationRegister.OtherAssetsLiabilities AS OtherAssetsLiabilities
		|		ON TRUE
		|		LEFT JOIN AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
		|		ON TRUE";
		
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
	
EndFunction

// Data sampling and movement formation

Procedure GetDataForAdditionalExpenses(CalculationParameters) Export
	
	ToDecrypt = CostCalculationAppliedAlgorithms.CalculationCalledForDecryption(CalculationParameters);
	
	AddlParameters = CalculationParameters.AdditionalStageRequestParameters;
	AddlParameters.Insert("CostCalculationPerformed",  CalculationParameters.Property("CostCalculationPerformed"));
	AddlParameters.Insert("DecodingDistribution", 	  ToDecrypt);
	
	PrepareAdditionalCostsForDistribution(CalculationParameters);
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForAllocationOfAdditionalCosts(CalculationParameters),
		,
		Not ToDecrypt);
	
EndProcedure

Procedure PrepareAdditionalCostsForDistribution(CalculationParameters)
	
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	Query.SetParameter("CostAllocationOptions", 
		TMCommonUseClientServer.Array(Enums.CostAllocationOptions.ToInventoryCost));
	Query.SetParameter("Recorder",
		?(CalculationParameters.Property("Recorder"), CalculationParameters.Recorder, Undefined));
	
	Query.Text = Documents.AllocationOfOtherCosts.QueryTextReceivedOtherExpenses(, False);
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, 
		,,,NStr("vi = 'Nhận chi phí bổ sung để phân bổ.';
				|ru = 'Получение дополнительных расходов для распределения.';
				|en = 'Getting additional expenses for allocation.'; fa = 'Getting additional expenses for allocation.';
				|it = 'Acquisizione di spese aggiuntive da allocare.';
				|pl = 'Otrzymanie dodatkowych rozchodów do przydzielenia.';
				|tr = 'Dağıtım için ek giderlerin elde edilmesi.'"));

	Query.Text = 
		"SELECT
		|	DD.Ref,
		|	DD.Organization,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses AS DimensionOfExpenses,
		|	DD.AssignAllocationSetting,
		|	DD.AllocationDirection,
		|	DD.BaseOfAllocationByLots,
		|	DD.SettingsOfBaseOfAllocationByLots,
		|	DD.ManagementAccounting,
		|	DD.LocalAccounting,
		|	DD.TaxAccounting,
		|	DD.AIT
		|INTO Recorders
		|FROM
		|	Document.AllocationOfOtherCosts AS DD
		|		INNER JOIN ExpenseForAllocation AS T
		|		ON (T.Organization = DD.Organization)
		|			AND (T.Department = DD.Department)
		|			AND (T.ExpenseItem = DD.ExpenseItem)
		|			AND (T.DimensionOfExpenses = DD.DimensionOfExpenses)
		|			AND (T.LineOfBusiness = DD.LineOfBusiness)
		|WHERE
		|	&UseAccountingOfOtherIncomeExpenses
		|	AND DD.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnInventoryCosts)
		|	AND DD.Date BETWEEN &BeginOfPeriod AND ENDOFPERIOD(&EndOfPeriod, MONTH)
		|	AND DD.Organization IN(&CompanyArray)
		|	AND DD.Posted
		|	AND (DD.Ref = &Recorder
		|			OR &Recorder = UNDEFINED)
		|
		|INDEX BY
		|	DimensionOfExpenses";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query,
		,,,NStr("vi = 'Khởi tạo bảng hệ thống để phân bổ chi phí.';
				|ru = 'Инициализация служебных таблиц для распределения затрат.';
				|en = 'Initializing internal tables for cost allocation.'; fa = 'Initializing internal tables for cost allocation.';
				|it = 'Inizializzazione di tabelle di servizio per la ripartizione delle spese.';
				|pl = 'Inicjacja tabel służbowych do podziału rozchodów.';
				|tr = 'Maliyet dağıtımı için özel tablolarının başlatılması.'"));
	
	// We will destroy the auxiliary temporary tables.
	NewTT = "Recorders,
	|ExpenseForAllocation,ExpensesForDistributionAreSummarized
	|,AITArticleDistributionSettings,SettingsForDistributionOfAITArticlesByCostCenter
	|";
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, 
		CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters,
			CostCalculationUniversalAlgorithms.ConnectLines(ExistingTT, NewTT)));
	
EndProcedure

// Request texts

// ... for the table of estimated partyin order to get the data for the expenses()

Function RequestTextForAllocationOfAdditionalCosts(CalculationParameters)
	
	DataPreparationTexts = New Array;
	DataPreparationTexts.Add(OrderAnalysisText());
	DataPreparationTexts.Add(TextOfAcquisitionOfCustomsDeclarations());
	DataPreparationTexts.Add(TextPrimaryReceiversOfAdditionalCosts(CalculationParameters));
	DataPreparationTexts.Add(TextAnalyticsWithoutCost());
	DataPreparationTexts.Add(TextCalculatedCostOfLotReferencesOfGoods());
	DataPreparationTexts.Add(TextPrimaryReceiversWithCost());
	DataPreparationTexts.Add(TextCoefficientsOfReductionOfBaseOfDistributionOfAdditionalExpenses());
	DataPreparationTexts.Add(TextPrimaryReceiversGiven());
	DataPreparationTexts.Add(AdjustmentOfReceiversByRegistrars());
	DataPreparationTexts.Add(TextReceiversForGoodsOfPastPeriodsOfAdditionalExpenses());
	DataPreparationTexts.Add(IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods());	
	DataPreparationTexts.Add(CostCalculationAppliedAlgorithms.InsertWeightAndVolumeTemplatesIntoQueryText(
		TextOfItemAccountingAnalysisWithVolumeAndWeights(), "SN"));
	
	DataSampleTexts = New Array;
	DataSampleTexts.Add(TextDescriptionOfDataForAllocationOfAdditionalCosts());
	DataSampleTexts.Add(TextOfShareOfAdditionalCosts());
	
	QueriesTexts = New Array;
	QueriesTexts.Add(MergeTexts(DataPreparationTexts, Common.QueryBatchSeparator()));
	QueriesTexts.Add(MergeTexts(DataSampleTexts));
	
	Return MergeTexts(QueriesTexts, Common.QueryBatchSeparator());
	
EndFunction

Function TextOfItemAccountingAnalysisWithVolumeAndWeights()
	Return "
	|SELECT DISTINCT
	|	Indicators.CorItemsLocationAttributes AS ItemsLocationAttributes
	|INTO UsedAUN
	|FROM
	|	IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS Indicators
	|
	|UNION
	|
	|SELECT
	|	SourceDatabase.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	// Comment 4761. The selection and connection conditions must match the request for textdidditional costs - Textdidditional costs_3.
	|	Recorders AS DD
	|        INNER JOIN AccumulationRegister.OtherExpenses AS SourceDatabase
	|        ON DD.DimensionOfExpenses = SourceDatabase.Recorder
	|            AND (SourceDatabase.RecordType = VALUE(AccumulationRecordType.Receipt))
	|            AND (SourceDatabase.Period <= &EndOfPeriod)
	|            AND (NOT SourceDatabase.CalculationOfCost)
	|
	|UNION
	|
	|SELECT
	|	ProductReceivers.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	// Comment 4774. The selection and connection conditions must match the request for textdidditional costs - Textdidditional Costs_1.
	// One exception in the current request is that left connections are not needed.
	// We select only those item accounting analysts that should be processed.
	|	Recorders AS Recorders
	|		INNER JOIN ProductReceivers AS ProductReceivers
	|		ON Recorders.Ref = ProductReceivers.Recorder
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UsedAUN.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	SN.Ref AS Products,
	|	SN.ItemsType AS ItemsType,
	|	&Weight AS Weight,
	|	&VolumeM3 AS VolumeM3
	|INTO ItemAccountingAnalystsWithVolumeAndWeights
	|FROM
	|	UsedAUN AS UsedAUN
	|		LEFT JOIN Catalog.Products AS SN
	|		ON (SN.Ref = UsedAUN.ItemsLocationAttributes.Products)
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP UsedAUN
	|";
EndFunction

Function OrderAnalysisText()
	
	QueryText = 
		"SELECT DISTINCT
		|	DD.CostLogger,
		|	DD.DimensionOfExpenses,
		|	DD.Organization,
		|	DD.Products,
		|	DD.Characteristic,
		|	(CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments THEN DD.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef) END) AS Purpose,
		|	DD.Warehouse
		|INTO OrderAnalytics
		|FROM (
		// 1. Purchases of goods ordered by the supplier, except for purchases of goods for which receipts to the warehouse have been issued.
		|	SELECT
		|		DD.Recorder AS CostLogger,
		|		Recorders.DimensionOfExpenses AS DimensionOfExpenses,
		|		Recorders.Organization,
		|		DD.Products,
		|		DD.Characteristic,
		|		DocumentGoods.Purpose,
		|		(CASE
		|			WHEN OrderDocument.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit))
		|				THEN OrderDocument.Contract
		|			ELSE DD.Warehouse END) AS Warehouse
		|	FROM
		|		Recorders AS Recorders
		|			INNER JOIN AccumulationRegister.PurchaseOrders AS DD
		|			ON Recorders.DimensionOfExpenses = DD.PurchaseOrder
		|		
		|			INNER JOIN Document.PurchaseOrder AS OrderDocument
		|			ON OrderDocument.Ref = DD.PurchaseOrder
		|			
		|			INNER JOIN Document.PurchaseOrder.Goods AS DocumentGoods
		|			ON DocumentGoods.Ref = DD.PurchaseOrder
		|				AND DocumentGoods.RowCode = DD.RowCode
		|				AND Recorders.LineOfBusiness = 
		|					ISNULL(DocumentGoods.Purpose.LineOfBusiness,
		|						VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|
		|			LEFT JOIN AccumulationRegister.GoodsToReceive AS MovementTowardsAdmission
		|			ON MovementTowardsAdmission.DocumentInflow = OrderDocument.Ref
		|				AND MovementTowardsAdmission.Period <= &EndOfPeriod
		|				AND MovementTowardsAdmission.Active
		|				AND MovementTowardsAdmission.RecordType = VALUE(AccumulationRecordType.Expense)
		|				AND MovementTowardsAdmission.ToRegisterReceiptsByReference <> 0
		|				AND MovementTowardsAdmission.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit))
		|				AND NOT &AllocationOfAdditionalExpensesOnGoodsInTransitFromVendors
		|	WHERE
		|		DD.Period <= &EndOfPeriod
		|		AND DD.Active
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND MovementTowardsAdmission.Recorder IS NULL
		|
		|	UNION ALL
		|
		// 2. purchases of goods for all orders to suppliers of the Cur period, if the cost analysis does not specify an order to the supplier.
		|	SELECT
		|		DD.Recorder,
		|		Recorders.DimensionOfExpenses,
		|		Recorders.Organization,
		|		DD.Products,
		|		DD.Characteristic,
		|		DocumentGoods.Purpose,
		|		(CASE
		|			WHEN OrderDocument.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit))
		|				THEN OrderDocument.Contract
		|			ELSE DD.Warehouse END)
		|	FROM
		|		AccumulationRegister.PurchaseOrders AS DD
		|		INNER JOIN Document.PurchaseOrder AS OrderDocument
		|			ON OrderDocument.Ref = DD.PurchaseOrder
		|		INNER JOIN Document.PurchaseOrder.Goods AS DocumentGoods
		|			ON DD.PurchaseOrder = DocumentGoods.Ref
		|			AND DD.RowCode = DocumentGoods.RowCode
		|		INNER JOIN Recorders AS Recorders
		|			ON Recorders.DimensionOfExpenses = VALUE(Document.PurchaseOrder.EmptyRef)
		|			AND Recorders.Organization = OrderDocument.Organization
		|			AND Recorders.LineOfBusiness = 
		|				ISNULL(DocumentGoods.Purpose.LineOfBusiness,
		|					VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		LEFT JOIN AccumulationRegister.GoodsToReceive AS MovementTowardsAdmission
		|			ON MovementTowardsAdmission.DocumentInflow = OrderDocument.Ref
		|			AND MovementTowardsAdmission.Period <= &EndOfPeriod
		|			AND MovementTowardsAdmission.Active
		|			AND MovementTowardsAdmission.RecordType = VALUE(AccumulationRecordType.Expense)
		|			AND MovementTowardsAdmission.ToRegisterReceiptsByReference <> 0
		|			AND MovementTowardsAdmission.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|				VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit))
		|				AND NOT &AllocationOfAdditionalExpensesOnGoodsInTransitFromVendors
		|	WHERE
		|		DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND DD.Active
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND MovementTowardsAdmission.Recorder IS NULL
		|
		|	UNION ALL
		|
		// 3. Receipts for goods in transit from suppliers.
		|	SELECT
		|		DD.Recorder,
		|		Recorders.DimensionOfExpenses,
		|		Recorders.Organization,
		|		DD.Products,
		|		DD.Characteristic,
		|		DD.Purpose,
		|		DD.Warehouse
		|	FROM
		|		Recorders AS Recorders
		|		INNER JOIN AccumulationRegister.GoodsToReceive AS DD
		|			ON Recorders.DimensionOfExpenses = DD.DocumentInflow
		|			AND Recorders.LineOfBusiness =
		|				ISNULL(DD.Purpose.LineOfBusiness,
		|					VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		INNER JOIN Document.PurchaseOrder AS OrderDocument
		|			ON OrderDocument.Ref = DD.DocumentInflow
		|	WHERE
		|		DD.Period <= &EndOfPeriod
		|		AND DD.Active
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND DD.ToRegisterReceiptsByReference <> 0
		|		AND OrderDocument.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit))
		|		AND NOT &AllocationOfAdditionalExpensesOnGoodsInTransitFromVendors
		|
		// 4. Receipt of goods for unfactured deliveries.
		|	UNION ALL
		|
		|	SELECT
		|		DD.Recorder,
		|		Recorders.DimensionOfExpenses,
		|		Recorders.Organization,
		|		DD.Products,
		|		DD.Characteristic,
		|		DD.Purpose,
		|		DD.Warehouse
		|	FROM
		|		Recorders AS Recorders
		|		INNER JOIN AccumulationRegister.GoodsToReceive AS DD
		|			ON Recorders.DimensionOfExpenses = DD.DocumentInflow
		|			AND Recorders.LineOfBusiness =
		|				ISNULL(DD.Purpose.LineOfBusiness,
		|					VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		INNER JOIN Document.PurchaseOrder AS OrderDocument
		|			ON OrderDocument.Ref = DD.DocumentInflow
		|	WHERE
		|		DD.Period <= &EndOfPeriod
		|		AND DD.Active
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND DD.ToRegisterReceiptsByReference <> 0
		|		AND OrderDocument.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
		|
		// 5. Moving goods on orders to move
		|	UNION ALL
		|
		|	SELECT
		|		DD.Recorder,
		|		Recorders.DimensionOfExpenses,
		|		CASE
		|			WHEN OrderDocument.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
		|				THEN OrderDocument.CompanyRecipient
		|			ELSE Recorders.Organization
		|		END AS Organization,
		|		DD.Products,
		|		DD.Characteristic,
		|		DocumentGoods.Purpose,
		|		OrderDocument.DestinationWarehouse
		|	FROM
		|		Recorders AS Recorders
		|			INNER JOIN AccumulationRegister.TransferOrders AS DD
		|			ON Recorders.DimensionOfExpenses = DD.TransferOrder
		|
		|			INNER JOIN Document.TransferOrder AS OrderDocument
		|			ON OrderDocument.Ref = DD.TransferOrder
		|
		|			INNER JOIN Document.TransferOrder.Goods AS DocumentGoods
		|			ON DD.TransferOrder = DocumentGoods.Ref
		|				AND DD.RowCode = DocumentGoods.RowCode
		|				AND Recorders.LineOfBusiness =
		|						ISNULL(DocumentGoods.Purpose.LineOfBusiness,
		|							VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|	WHERE
		|		DD.Period <= &EndOfPeriod
		|		AND DD.Active
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|
		|	UNION ALL
		|
		// 6. moving goods of the Cur period, if the cost analysis does not specify a moving order.
		|	SELECT
		|		DD.Recorder,
		|		Recorders.DimensionOfExpenses,
		|		Recorders.Organization,
		|		DD.Products,
		|		DD.Characteristic,
		|		DocumentGoods.Purpose,
		|		OrderDocument.DestinationWarehouse
		|	FROM
		|		AccumulationRegister.TransferOrders AS DD
		|		INNER JOIN Document.TransferOrder AS OrderDocument
		|			ON OrderDocument.Ref = DD.TransferOrder
		|		INNER JOIN Document.TransferOrder.Goods AS DocumentGoods
		|			ON DD.TransferOrder = DocumentGoods.Ref
		|			AND DD.RowCode = DocumentGoods.RowCode
		|		INNER JOIN Recorders AS Recorders
		|			ON Recorders.DimensionOfExpenses = VALUE(Document.TransferOrder.EmptyRef)
		|			AND Recorders.Organization = OrderDocument.Organization
		|			AND Recorders.LineOfBusiness = 
		|				ISNULL(DocumentGoods.Purpose.LineOfBusiness,
		|					VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|	WHERE
		|		DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND DD.Active
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|
		|	UNION ALL
		|
		// 7. Assembly/disassembly of goods on assembly orders
		|	SELECT
		|		DD.Recorder,
		|		Recorders.DimensionOfExpenses,
		|		Recorders.Organization,
		|		DD.Products,
		|		DD.Characteristic,
		|		(CASE
		|			WHEN OrderDocument.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|				THEN OrderDocument.Purpose
		|			ELSE OrderingProducts.Purpose END) AS Purpose,
		|		OrderDocument.Warehouse AS Warehouse
		|	FROM
		|		Recorders AS Recorders
		|			INNER JOIN AccumulationRegister.AssemblyOrders AS DD
		|			ON Recorders.DimensionOfExpenses = DD.ByAssemblyDisassemblyOrder
		|
		|			INNER JOIN Document.ByAssemblyDisassemblyOrder AS OrderDocument
		|			ON OrderDocument.Ref = DD.ByAssemblyDisassemblyOrder
		|
		|			LEFT JOIN Document.ByAssemblyDisassemblyOrder.Goods AS OrderingProducts
		|			ON OrderingProducts.Ref = DD.ByAssemblyDisassemblyOrder
		|				AND OrderingProducts.RowCode = DD.RowCode
		|				AND Recorders.LineOfBusiness =
		|					(CASE
		|						WHEN OrderDocument.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|							THEN ISNULL(OrderDocument.Purpose.LineOfBusiness,
		|									VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|						ELSE
		|							ISNULL(OrderingProducts.Purpose.LineOfBusiness,
		|								VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|					END)
		|	WHERE
		|		DD.Period <= &EndOfPeriod
		|		AND DD.Active
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND DD.AssemblyType = VALUE(Enum.InventoryMovementTypes.Inpayment)
		|
		|	UNION ALL
		|
		// 8. Assembly/ disassembly of goods, if the cost analysis does not specify an assembly order
		|	SELECT
		|		DD.Recorder,
		|		Recorders.DimensionOfExpenses,
		|		Recorders.Organization,
		|		DD.Products,
		|		DD.Characteristic,
		|		(CASE
		|			WHEN OrderDocument.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|				THEN OrderDocument.Purpose
		|			ELSE OrderingProducts.Purpose END),
		|		OrderDocument.Warehouse
		|	FROM
		|		AccumulationRegister.AssemblyOrders AS DD
		|		INNER JOIN Document.ByAssemblyDisassemblyOrder AS OrderDocument
		|			ON OrderDocument.Ref = DD.ByAssemblyDisassemblyOrder
		|		LEFT JOIN Document.ByAssemblyDisassemblyOrder.Goods AS OrderingProducts
		|			ON OrderingProducts.Ref = DD.ByAssemblyDisassemblyOrder
		|			AND OrderingProducts.RowCode = DD.RowCode
		|		INNER JOIN Recorders AS Recorders
		|			ON Recorders.DimensionOfExpenses = VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef)
		|			AND Recorders.Organization = OrderDocument.Organization
		|			AND Recorders.LineOfBusiness = 
		|			(CASE
		|				WHEN OrderDocument.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|					THEN ISNULL(OrderDocument.Purpose.LineOfBusiness,
		|						VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|				ELSE
		|					ISNULL(OrderingProducts.Purpose.LineOfBusiness,
		|						VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|				END)
		|	WHERE
		|		DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND DD.Active
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND DD.AssemblyType = VALUE(Enum.InventoryMovementTypes.Inpayment)
		|) AS DD
		|
		|INDEX BY
		|	DimensionOfExpenses";
		
	Return QueryText;
		
EndFunction

Function TextOfAcquisitionOfCustomsDeclarations()
	
	QueryText =
		"SELECT
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN CompanyGoods.ItemsLocationAttributes
		|		ELSE AnalyticsWithoutAssignment.DimensionKey
		|	END AS ItemsLocationAttributes,
		|	CompanyGoods.Organization AS Organization,
		|	CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	CompanyGoods.Recorder AS Recorder,
		|	SUM(CompanyGoods.Count) AS Count
		|INTO GoodsOfOrganizationsByDeclarations
		|FROM
		|	AccumulationRegister.CompanyGoods AS CompanyGoods
		|	INNER JOIN Document.CCDImport AS Filter
		|		ON CompanyGoods.Recorder = Filter.Ref
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = CompanyGoods.ItemsLocationAttributes
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
		|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
		|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
		|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
		|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
		|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
		|		AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
		|WHERE
		|	CompanyGoods.Period <= &EndOfPeriod
		|	AND CompanyGoods.Active
		|GROUP BY
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN CompanyGoods.ItemsLocationAttributes
		|		ELSE AnalyticsWithoutAssignment.DimensionKey
		|	END,
		|	CompanyGoods.Organization,
		|	CompanyGoods.InventoryOwnerAttribute,
		|	CompanyGoods.Recorder
		|INDEX BY
		|	Recorder,
		|	ItemsLocationAttributes,
		|	Organization,
		|	InventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.Recorder
		|INTO VTSelectionOfRegistrarsOfDeclarations
		|FROM
		|	GoodsOfOrganizationsByDeclarations AS T
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InventoryCost.Period AS Period,
		|	InventoryCost.Recorder AS Recorder,
		|	InventoryCost.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	InventoryCost.AccountingSection AS AccountingSection,
		|	InventoryCost.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	InventoryCost.Organization AS Organization,
		|	InventoryCost.Lot AS Lot,
		|	InventoryCost.LotVendorAttributes AS LotVendorAttributes,
		|	InventoryCost.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	InventoryCost.VATActivityType AS VATActivityType,
		|	InventoryCost.AddExpensesForGoods AS AddExpensesForGoods,
		|	InventoryCost.DocumentSource AS DocumentSource
		|INTO TTOfRegisteredRecordedInventoryCostsOfDeclarations
		|FROM
		|	VTSelectionOfRegistrarsOfDeclarations AS Filter
		|		INNER JOIN AccumulationRegister.InventoryCost AS InventoryCost
		|		ON InventoryCost.Recorder = Filter.Recorder
		|			AND InventoryCost.Period <= &EndOfPeriod
		|			AND InventoryCost.Active
		|
		|INDEX BY
		|	Recorder,
		|	Period,
		|	ItemsLocationAttributes
		|;
		|
		|SELECT
		|	Declarations.Ref AS Declaration,
		|	DeclarationItems.DocumentInflow AS VendorInvoice,
		|	DeclarationItems.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	SUM(DeclarationItems.Count) AS Count
		|
		|INTO DeclarationsWithoutVATZeroCustomsDuty
		|FROM
		|	Document.CCDImport AS Declarations
		|		INNER JOIN VTSelectionOfRegistrarsOfDeclarations AS Filter
		|		ON (Filter.Recorder = Declarations.Ref)
		|		INNER JOIN Document.CCDImport.Goods AS DeclarationItems
		|		ON (DeclarationItems.Ref = Declarations.Ref)
		|			AND (DeclarationItems.DocumentInflow <> VALUE(Document.VendorInvoice.EmptyRef))
		|		LEFT JOIN TTOfRegisteredRecordedInventoryCostsOfDeclarations AS Cost_
		|		ON Cost_.Recorder = Declarations.Ref
		|			AND Cost_.Period = Declarations.Date
		|			AND Cost_.ItemsLocationAttributes = DeclarationItems.ItemsLocationAttributes
		|WHERE
		|	Cost_.Recorder IS NULL
		|GROUP BY
		|	Declarations.Ref,
		|	DeclarationItems.DocumentInflow,
		|	DeclarationItems.ItemsLocationAttributes
		|
		|INDEX BY
		|	VendorInvoice,
		|	ItemsLocationAttributes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Recorder AS Recorder,
		|	T.ItemsLocationAttributes,
		|	T.Organization,
		|	T.InventoryOwnerAttribute,
		|	T.DocumentSource,
		|	T.AccountingSection,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	T.Period,
		|	SUM(T.AddExpensesForGoods) AS AddExpensesForGoods,
		|	0 AS QuantityWithoutCost
		|
		|INTO TUEOfCostPriceMovementAccordingToDeclarations
		|FROM
		|	TTOfRegisteredRecordedInventoryCostsOfDeclarations AS T
		|WHERE
		|	T.Period < &BeginOfPeriod
		|
		|GROUP BY
		|	T.Recorder,
		|	T.DocumentSource,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	T.Period
		|
		|UNION ALL
		|
		|SELECT
		|	T.Recorder AS Recorder,
		|	T.ItemsLocationAttributes,
		|	T.Organization,
		|	T.InventoryOwnerAttribute,
		|	T.DocumentSource,
		|	T.AccountingSection,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	T.Period,
		|	SUM(T.AddExpensesForGoods) AS AddExpensesForGoods,
		|	0 AS QuantityWithoutCost
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN VTSelectionOfRegistrarsOfDeclarations AS Filter
		|		ON T.Recorder = Filter.Recorder
		|GROUP BY
		|	T.Recorder,
		|	T.DocumentSource,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	T.Period
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DD.Declaration AS Recorder,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Organization AS Organization,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.VendorInvoice AS DocumentSource,
		|	T.AccountingSection AS AccountingSection,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|	T.Period,
		|	0 AS AddExpensesForGoods,
		|	DD.Count AS QuantityWithoutCost
		|FROM
		|	DeclarationsWithoutVATZeroCustomsDuty AS DD
		|		INNER JOIN AccumulationRegister.InventoryCost AS T
		|		ON (T.Recorder = DD.VendorInvoice)
		|			AND (T.ItemsLocationAttributes = DD.ItemsLocationAttributes)
		|			AND (T.Period <= &EndOfPeriod)
		|
		|INDEX BY
		|	Recorder,
		|	ItemsLocationAttributes,
		|	Organization,
		|	InventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Recorder AS Recorder,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Organization AS Organization,
		|	SUM(T.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(T.QuantityWithoutCost) AS QuantityWithoutCost,
		|	MAX(ISNULL(GoodsOfOrganizationsByDeclarations.Count, 0)) AS Count
		|INTO TTCostPriceRegisteredRecordsOnDeclarationsAreCollapsed
		|FROM
		|	TUEOfCostPriceMovementAccordingToDeclarations AS T
		|	LEFT JOIN GoodsOfOrganizationsByDeclarations AS GoodsOfOrganizationsByDeclarations
		|	ON T.ItemsLocationAttributes = GoodsOfOrganizationsByDeclarations.ItemsLocationAttributes
		|		AND T.Organization = GoodsOfOrganizationsByDeclarations.Organization
		|		AND T.InventoryOwnerAttribute = GoodsOfOrganizationsByDeclarations.InventoryOwnerAttribute
		|		AND T.Recorder = GoodsOfOrganizationsByDeclarations.Recorder
		|GROUP BY
		|	T.Recorder,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.Organization
		|INDEX BY
		|	Recorder,
		|	ItemsLocationAttributes,
		|	Organization,
		|	InventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Recorder AS Recorder,
		|	T.DocumentSource,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Organization AS Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	BEGINOFPERIOD(T.Period, MONTH) AS MonthPeriod,
		|	CAST(CASE
		|		WHEN RegisteredRecordsAreCollapsed.AddExpensesForGoods = 0 AND RegisteredRecordsAreCollapsed.QuantityWithoutCost = 0
		|			THEN RegisteredRecordsAreCollapsed.Count
		|		WHEN RegisteredRecordsAreCollapsed.AddExpensesForGoods = 0
		|			THEN RegisteredRecordsAreCollapsed.Count * T.QuantityWithoutCost / RegisteredRecordsAreCollapsed.QuantityWithoutCost
		|		ELSE RegisteredRecordsAreCollapsed.Count * T.AddExpensesForGoods / RegisteredRecordsAreCollapsed.AddExpensesForGoods
		|	END AS NUMBER (15,3)) AS Count
		|INTO TUEOfCostPriceMovementOnDeclarationsWithQuantity
		|FROM
		|	TUEOfCostPriceMovementAccordingToDeclarations AS T
		|	LEFT JOIN TTCostPriceRegisteredRecordsOnDeclarationsAreCollapsed AS RegisteredRecordsAreCollapsed
		|	ON T.ItemsLocationAttributes = RegisteredRecordsAreCollapsed.ItemsLocationAttributes
		|		AND T.Organization = RegisteredRecordsAreCollapsed.Organization
		|		AND T.InventoryOwnerAttribute = RegisteredRecordsAreCollapsed.InventoryOwnerAttribute
		|		AND T.Recorder = RegisteredRecordsAreCollapsed.Recorder
		|INDEX BY
		|	Recorder,
		|	MonthPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GoodsAccordingToDeclarations.Declaration AS Declaration,
		|	GoodsAccordingToDeclarations.CostLogger AS CostLogger,
		|	GoodsAccordingToDeclarations.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GoodsAccordingToDeclarations.AccountingSection AS AccountingSection,
		|	GoodsAccordingToDeclarations.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	GoodsAccordingToDeclarations.Organization AS Organization,
		|	GoodsAccordingToDeclarations.Lot AS Lot,
		|	GoodsAccordingToDeclarations.LotVendorAttributes AS LotVendorAttributes,
		|	GoodsAccordingToDeclarations.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	GoodsAccordingToDeclarations.VATActivityType AS VATActivityType,
		|	GoodsAccordingToDeclarations.Count AS Count
		|INTO AcquisitionsByDeclarations
		|FROM
		|	(SELECT
		|		DD.DimensionOfExpenses AS Declaration,
		|		Cost_.DocumentSource AS CostLogger,
		|		Cost_.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		Cost_.AccountingSection AS AccountingSection,
		|		Cost_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		Cost_.Organization AS Organization,
		|		Cost_.Lot AS Lot,
		|		Cost_.LotVendorAttributes AS LotVendorAttributes,
		|		Cost_.FinancialAccountingDimension AS FinancialAccountingDimension,
		|		Cost_.VATActivityType AS VATActivityType,
		|		Cost_.Count AS Count
		|	FROM
		|		Recorders AS DD
		|		INNER JOIN TUEOfCostPriceMovementOnDeclarationsWithQuantity AS Cost_
		|			ON DD.DimensionOfExpenses = Cost_.Recorder
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DD.DimensionOfExpenses,
		|		Cost_.DocumentSource,
		|		Cost_.ItemsLocationAttributes,
		|		Cost_.AccountingSection,
		|		Cost_.InventoryOwnerAttribute,
		|		Cost_.Organization,
		|		Cost_.Lot,
		|		Cost_.LotVendorAttributes,
		|		Cost_.FinancialAccountingDimension,
		|		Cost_.VATActivityType,
		|		Cost_.Count
		|	FROM
		|		Recorders AS DD
		|		INNER JOIN TUEOfCostPriceMovementOnDeclarationsWithQuantity AS Cost_
		|			ON DD.Organization = Cost_.Organization
		|			AND Cost_.MonthPeriod = &BeginOfPeriod
		|	WHERE
		|		DD.DimensionOfExpenses = VALUE(Document.CCDImport.EmptyRef)
		|
		|	) AS GoodsAccordingToDeclarations
		|
		|INDEX BY SETS
		|(
		|	(CostLogger, ItemsLocationAttributes),
		|	(Declaration)
		|)
		|";
		
	Return QueryText;
	
EndFunction

Function TextTemplatePrimaryReceiversOfAdditionalCosts(TypeOfExpenseAnalytics, UsedTemplates, NumberOfGroup)
	
	If TypeOfExpenseAnalytics = Type("Undefined") Then
		Template = "";
		
	ElsIf TypeOfExpenseAnalytics = Type("DocumentRef.PurchaseOrder")
		Or TypeOfExpenseAnalytics = Type("DocumentRef.ByAssemblyDisassemblyOrder")
		Or TypeOfExpenseAnalytics = Type("DocumentRef.TransferOrder") Then
		Template = TextTemplatePrimaryReceiversByOrders();
		UsedTemplates.ByOrders.Add(NumberOfGroup);
		
	ElsIf TypeOfExpenseAnalytics = Type("DocumentRef.CCDImport") Then
		Template = TextTemplatePrimaryReceiversByDeclarations();
		UsedTemplates.ByDeclarations.Add(NumberOfGroup);

	ElsIf CostCalculationUniversalAlgorithms.DescriptionOfDocumentTypes().ContainsType(TypeOfExpenseAnalytics) Then
		
		Template = TextTemplatePrimaryReceiversByDocuments();
		Template = StrReplace(Template, "&EmptyValue", 
			"VALUE(Document." + Metadata.FindByType(TypeOfExpenseAnalytics).Name + ".EmptyRef)");
		UsedTemplates.ByDocuments.Add(NumberOfGroup);
		
	ElsIf TypeOfExpenseAnalytics = Type("CatalogRef.Products") Then
		
		Template = TextTemplatePrimaryReceiversInCatalogs();
		Template = StrReplace(Template, "&EmptyValue", "VALUE(Catalog.Products.EmptyRef)");
		Template = StrReplace(Template, "&SourceField_", "SourceDatabase.ItemsLocationAttributes.Products");
		UsedTemplates.ByReferenceBooks.Add(NumberOfGroup);

	ElsIf TypeOfExpenseAnalytics = Type("CatalogRef.Warehouses") Then
		
		Template = TextTemplatePrimaryReceiversInCatalogs();
		Template = StrReplace(Template, "&EmptyValue", "VALUE(Catalog.Warehouses.EmptyRef)");
		Template = StrReplace(Template, "&SourceField_", "SourceDatabase.ItemsLocationAttributes.StorageLocation");
		UsedTemplates.ByReferenceBooks.Add(NumberOfGroup);
		
	ElsIf TypeOfExpenseAnalytics = Type("CatalogRef.Partners") Then
		
		Template = TextTemplatePrimaryRecyclingReceivers();
		Template = StrReplace(Template, "&EmptyValue", "VALUE(Catalog.Partners.EmptyRef)");
		Template = StrReplace(Template, "&SourceField_", "SourceDatabase.ItemsLocationAttributes.Partner");
		UsedTemplates.ByRecycling.Add(NumberOfGroup);

	ElsIf TypeOfExpenseAnalytics = Type("CatalogRef.CounterpartyContracts") Then
		
		Template = TextTemplatePrimaryRecyclingReceivers();
		Template = StrReplace(Template, "&EmptyValue", "VALUE(Catalog.CounterpartyContracts.EmptyRef)");
		Template = StrReplace(Template, "&SourceField_", "SourceDatabase.ItemsLocationAttributes.Contract");
		UsedTemplates.ByRecycling.Add(NumberOfGroup);
		
	Else
		Template = TextTemplatePrimaryReceiversOtherExpenses();
		UsedTemplates.ByOtherExpenses.Add(NumberOfGroup);

	EndIf;

	Return Template;
	
EndFunction

Function TextTemplatePrimaryReceiversByOrders()
	
	Template = 
		"SELECT
		|	""TextTemplatePrimaryReceiversByOrders_1"" AS RequestSource,
		|	DD.Ref AS Recorder,
		// With a sliding average, the distribution of disposals in past periods is performed according to the data 
		// of the register "Deviations in the cost of goods". 
		// Requests for the indicator function of the base of the receivers of the past periods should not be executed.
		|	(CASE
		|		WHEN SourceDatabase.Organization IN (&MediumSlipOrganizations)
		|			THEN FALSE
		|		ELSE TRUE END)                    AS ThisIsPartyOfPastPeriod,
		|	SourceDatabase.AccountingSection                   AS AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	SourceDatabase.Lot                        AS Lot,
		|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	MAX(CASE WHEN SourceDatabase.RowID <> """"
		|		THEN SourceDatabase.RowID
		|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,	
		|	SUM(SourceDatabase.Count) AS Count,
		|	SUM(SourceDatabase.Cost) AS Cost,
		|	SUM(SourceDatabase.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(SourceDatabase.LocalCost) AS LocalCost,
		|	SUM(SourceDatabase.CostMan) AS CostMan,
		|	SUM(SourceDatabase.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|	SUM(SourceDatabase.LocalCost) AS CostInTaxAccounting,
		|	
		|	MIN(BEGINOFPERIOD(SourceDatabase.Period, MONTH)) AS ReceiptPeriod
		|INTO DataTable
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|
		|		INNER JOIN OrderAnalytics AS OrderAnalytics
		|		ON DD.DimensionOfExpenses = OrderAnalytics.DimensionOfExpenses
		|
		|		INNER JOIN AccumulationRegister.InventoryCost AS SourceDatabase
		|		ON OrderAnalytics.CostLogger = SourceDatabase.Recorder
		|			AND OrderAnalytics.Products = SourceDatabase.ItemsLocationAttributes.Products
		|			AND OrderAnalytics.Characteristic = SourceDatabase.ItemsLocationAttributes.Characteristic
		|			AND OrderAnalytics.Purpose = SourceDatabase.ItemsLocationAttributes.Purpose
		|			AND OrderAnalytics.Warehouse = SourceDatabase.ItemsLocationAttributes.StorageLocation
		|			AND SourceDatabase.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND SourceDatabase.Period < &BeginOfPeriod
		|			AND SourceDatabase.Organization = DD.Organization
		|
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.DimensionKey
		|
		|WHERE
		// The conditions for selecting Registered Records must match the request for the highest-value movementdocuments1
		|	(SourceDatabase.Count <> 0
		|		OR SourceDatabase.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.Lot),
		|			VALUE(Enum.LotRecordTypes.Consumption),
		|			VALUE(Enum.LotRecordTypes.CostAdjustment),
		|			VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|			VALUE(Enum.LotRecordTypes.Move),
		|			VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis)))
		|	AND (&ConnectionCondition)
		|
		|GROUP BY
		|	DD.Ref,
		|	(CASE
		|		WHEN SourceDatabase.Organization IN (&MediumSlipOrganizations)
		|			THEN FALSE
		|		ELSE TRUE END), // ThisIsPartyOfPastPeriod
		|	SourceDatabase.AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute,
		|	SourceDatabase.Organization,
		|	SourceDatabase.Lot,
		|	SourceDatabase.LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType
		|
		|UNION ALL
		|
		|SELECT
		|	""TextTemplatePrimaryReceiversByOrders_2"" AS RequestSource,
		|	DD.Ref AS Recorder,
		|	FALSE                                       AS ThisIsPartyOfPastPeriod,
		|	SourceDatabase.AccountingSection                   AS AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	SourceDatabase.Lot                        AS Lot,
		|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	MAX(CASE WHEN SourceDatabase.RowID <> """"
		|		THEN SourceDatabase.RowID
		|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
		|	SUM(SourceDatabase.Count)             AS Count,
		|	SUM(SourceDatabase.Cost)              AS Cost,
		|	SUM(SourceDatabase.CostExcludingVAT)        AS CostExcludingVAT,
		|	SUM(SourceDatabase.LocalCost)          AS LocalCost,
		|	SUM(SourceDatabase.CostMan)           AS CostMan,
		|	SUM(SourceDatabase.CostOfPersonalIncomeTax)           AS CostOfPersonalIncomeTax,
		|	SUM(SourceDatabase.LocalCost)          AS CostInTaxAccounting,
		|	
		|	MIN(BEGINOFPERIOD(CASE
		|		WHEN DocumentRegistry.IBDocumentDate IS NULL OR DocumentRegistry.IBDocumentDate < &DateOfMigrationToBatchAccounting22
		|		THEN &DateOfMigrationToBatchAccounting22
		|		ELSE DocumentRegistry.IBDocumentDate
		|	END, MONTH)) AS ReceiptPeriod
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|
		|		INNER JOIN OrderAnalytics AS OrderAnalytics
		|		ON DD.DimensionOfExpenses = OrderAnalytics.DimensionOfExpenses
		|
		|		INNER JOIN TTCashEstimatedTurnoverCostOfGoods AS SourceDatabase
		|		ON OrderAnalytics.CostLogger = SourceDatabase.Recorder
		|			AND OrderAnalytics.Products = SourceDatabase.ItemsLocationAttributes.Products
		|			AND OrderAnalytics.Characteristic = SourceDatabase.ItemsLocationAttributes.CHARACTERISTIC
		|			AND OrderAnalytics.Purpose = SourceDatabase.ItemsLocationAttributes.Purpose
		|			AND OrderAnalytics.Warehouse = SourceDatabase.ItemsLocationAttributes.StorageLocation
		|			AND SourceDatabase.OfficialTypeOfMovementParish
		|			AND OrderAnalytics.Organization = SourceDatabase.Organization
		|
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.DimensionKey
		|
		// The condition for connecting to the register of documents for batches must match the condition in the request for the formation
		// of a temporary table for the movement of the highest value of documents.
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentRegistry
		|		ON DocumentRegistry.Ref = CASE
		|				WHEN SourceDatabase.Lot <> UNDEFINED THEN SourceDatabase.Lot
		|				WHEN SourceDatabase.DocumentSource <> UNDEFINED THEN SourceDatabase.DocumentSource
		|				ELSE OrderAnalytics.DimensionOfExpenses END
		|			AND NOT DocumentRegistry.AdditionalRecord
		|WHERE
		|	NOT SourceDatabase.Count = 0
		|	AND (&ConnectionCondition)
		|
		|GROUP BY
		|	DD.Ref,
		|	SourceDatabase.AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute,
		|	SourceDatabase.Organization,
		|	SourceDatabase.Lot,
		|	SourceDatabase.LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType
		|";
	
	Return Template;
	
EndFunction

Function TextTemplatePrimaryReceiversByDeclarations()
	
	Template = 
		"SELECT
		|	""textdistributionadditional spending_1"" AS RequestSource,
		|	DD.Ref AS Recorder,
		// With a sliding average, the distribution of disposals in past periods is performed according to the data 
		// of the register "Deviations in the cost of goods". 
		// Requests for the indicator function of the base of the receivers of the past periods should not be executed.
		|	(CASE
		|		WHEN SourceDatabase.Organization IN (&MediumSlipOrganizations)
		|			THEN FALSE
		|		ELSE TRUE END)                    AS ThisIsPartyOfPastPeriod,
		|	SourceDatabase.AccountingSection                   AS AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	SourceDatabase.Lot                        AS Lot,
		|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	MAX(CASE WHEN SourceDatabase.RowID <> """"
		|		THEN SourceDatabase.RowID
		|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
		|	SUM(Acquisitions.Count) AS Count,
		|	SUM(SourceDatabase.Cost 
		|		* CASE
		|			WHEN SourceDatabase.Count = 0
		|				THEN 1
		|			ELSE Acquisitions.Count / SourceDatabase.Count
		|		END
		|	) AS Cost,
		|	SUM(SourceDatabase.CostExcludingVAT 
		|		* CASE
		|			WHEN SourceDatabase.Count = 0
		|				THEN 1
		|			ELSE Acquisitions.Count / SourceDatabase.Count
		|		END
		|	) AS CostExcludingVAT,
		|	SUM(SourceDatabase.LocalCost 
		|		* CASE
		|			WHEN SourceDatabase.Count = 0
		|				THEN 1
		|			ELSE Acquisitions.Count / SourceDatabase.Count
		|		END
		|	) AS LocalCost,
		|	SUM(SourceDatabase.CostMan 
		|		* CASE
		|			WHEN SourceDatabase.Count = 0
		|				THEN 1
		|			ELSE Acquisitions.Count / SourceDatabase.Count
		|		END
		|	) AS CostMan,
		|	SUM(SourceDatabase.CostOfPersonalIncomeTax 
		|		* CASE
		|			WHEN SourceDatabase.Count = 0
		|				THEN 1
		|			ELSE Acquisitions.Count / SourceDatabase.Count
		|		END
		|	) AS CostOfPersonalIncomeTax,
		|	SUM(SourceDatabase.LocalCost
		|		* CASE
		|			WHEN SourceDatabase.Count = 0
		|				THEN 1
		|			ELSE Acquisitions.Count / SourceDatabase.Count
		|		END
		|	) AS CostInTaxAccounting,
		|	
		|	MIN(BEGINOFPERIOD(SourceDatabase.Period, MONTH)) AS ReceiptPeriod
		|INTO DataTable
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|
		|		INNER JOIN AcquisitionsByDeclarations AS Acquisitions
		|		ON DD.DimensionOfExpenses = Acquisitions.Declaration
		|
		|		INNER JOIN AccumulationRegister.InventoryCost AS SourceDatabase
		|		ON Acquisitions.CostLogger = SourceDatabase.Recorder
		|			AND Acquisitions.ItemsLocationAttributes = SourceDatabase.ItemsLocationAttributes
		|			AND Acquisitions.AccountingSection = SourceDatabase.AccountingSection
		|			AND Acquisitions.InventoryOwnerAttribute = SourceDatabase.InventoryOwnerAttribute
		|			AND Acquisitions.Organization = SourceDatabase.Organization
		|			AND Acquisitions.Lot = SourceDatabase.Lot
		|			AND Acquisitions.LotVendorAttributes = SourceDatabase.LotVendorAttributes
		|			AND Acquisitions.FinancialAccountingDimension = SourceDatabase.FinancialAccountingDimension
		|			AND Acquisitions.VATActivityType = SourceDatabase.VATActivityType
		|			AND SourceDatabase.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND SourceDatabase.Period < &BeginOfPeriod
		|
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.DimensionKey
		|
		|WHERE
		|	NOT SourceDatabase.Count = 0
		|	AND (&ConnectionCondition)
		|
		|GROUP BY
		|	DD.Ref,
		// With a sliding average, the distribution of disposals in past periods is performed according to the data 
		// of the register "Deviations in the cost of goods". 
		// Requests for the indicator function of the base of the receivers of the past periods should not be executed.
		|	(CASE
		|		WHEN SourceDatabase.Organization IN (&MediumSlipOrganizations)
		|			THEN FALSE
		|		ELSE TRUE END), // ThisIsPartyOfPastPeriod
		|	SourceDatabase.AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute,
		|	SourceDatabase.Organization,
		|	SourceDatabase.Lot,
		|	SourceDatabase.LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType
		|
		|UNION ALL
		|
		|SELECT
		|	""textdistributionadditional spending_2"" AS RequestSource,
		|	DD.Ref AS Recorder,
		|	FALSE                                       AS ThisIsPartyOfPastPeriod,
		|	SourceDatabase.AccountingSection                   AS AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	SourceDatabase.Lot                        AS Lot,
		|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	MAX(CASE WHEN SourceDatabase.RowID <> """"
		|		THEN SourceDatabase.RowID
		|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
		|	SUM(Acquisitions.Count)             AS Count,
		|	SUM(SourceDatabase.Cost 
		|		* CASE
		|			WHEN SourceDatabase.Count = 0
		|				THEN 1
		|			ELSE Acquisitions.Count / SourceDatabase.Count
		|		END) AS Cost,
		|	SUM(SourceDatabase.CostExcludingVAT 
		|		* CASE
		|			WHEN SourceDatabase.Count = 0
		|				THEN 1
		|			ELSE Acquisitions.Count / SourceDatabase.Count
		|		END) AS CostExcludingVAT,
		|	SUM(SourceDatabase.LocalCost 
		|		* CASE
		|			WHEN SourceDatabase.Count = 0
		|				THEN 1
		|			ELSE Acquisitions.Count / SourceDatabase.Count
		|		END) AS LocalCost,
		|	SUM(SourceDatabase.CostMan 
		|		* CASE
		|			WHEN SourceDatabase.Count = 0
		|				THEN 1
		|			ELSE Acquisitions.Count / SourceDatabase.Count
		|		END) AS CostMan,
		|	SUM(SourceDatabase.CostOfPersonalIncomeTax 
		|		* CASE
		|			WHEN SourceDatabase.Count = 0
		|				THEN 1
		|			ELSE Acquisitions.Count / SourceDatabase.Count
		|		END) AS CostOfPersonalIncomeTax,
		|	SUM(SourceDatabase.LocalCost
		|		* CASE
		|			WHEN SourceDatabase.Count = 0
		|				THEN 1
		|			ELSE Acquisitions.Count / SourceDatabase.Count
		|		END) AS CostInTaxAccounting,
		|	
		|	MIN(BEGINOFPERIOD(CASE
		|		WHEN DocumentRegistry.IBDocumentDate IS NULL OR DocumentRegistry.IBDocumentDate < &DateOfMigrationToBatchAccounting22
		|		THEN &DateOfMigrationToBatchAccounting22
		|		ELSE DocumentRegistry.IBDocumentDate
		|	END, MONTH)) AS ReceiptPeriod
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|
		|		INNER JOIN AcquisitionsByDeclarations AS Acquisitions
		|		ON DD.DimensionOfExpenses = Acquisitions.Declaration
		|
		|		INNER JOIN TTCashEstimatedTurnoverCostOfGoods AS SourceDatabase
		|		ON Acquisitions.CostLogger = SourceDatabase.Recorder
		|			AND Acquisitions.ItemsLocationAttributes = SourceDatabase.ItemsLocationAttributes
		|			AND Acquisitions.AccountingSection = SourceDatabase.AccountingSection
		|			AND Acquisitions.InventoryOwnerAttribute = SourceDatabase.InventoryOwnerAttribute
		|			AND Acquisitions.Organization = SourceDatabase.Organization
		|			AND Acquisitions.Lot = SourceDatabase.Lot
		|			AND Acquisitions.LotVendorAttributes = SourceDatabase.LotVendorAttributes
		|			AND Acquisitions.FinancialAccountingDimension = SourceDatabase.FinancialAccountingDimension
		|			AND Acquisitions.VATActivityType = SourceDatabase.VATActivityType
		|			AND SourceDatabase.OfficialTypeOfMovementParish
		|
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.DimensionKey
		|
		// The condition for connecting to the register of documents for batches must match the condition in the request for the formation
		// of a temporary table for the movement of the highest value of documents.
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentRegistry
		|		ON DocumentRegistry.Ref = CASE
		|				WHEN SourceDatabase.Lot <> UNDEFINED THEN SourceDatabase.Lot
		|				WHEN SourceDatabase.DocumentSource <> UNDEFINED THEN SourceDatabase.DocumentSource
		|				ELSE Acquisitions.Declaration END
		|			AND NOT DocumentRegistry.AdditionalRecord
		|WHERE
		|	NOT SourceDatabase.Count = 0
		|	AND (&ConnectionCondition)
		|
		|GROUP BY
		|	DD.Ref,
		|	SourceDatabase.AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute,
		|	SourceDatabase.Organization,
		|	SourceDatabase.Lot,
		|	SourceDatabase.LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType
		|";
	
	Return Template;
	
EndFunction

Function TextTemplatePrimaryReceiversByDocuments()
	
	Template = 
		"SELECT
		|	""TextTemplatePrimaryReceiversByDocuments_1,2"" AS RequestSource,
		|	DD.Ref AS Recorder,
		// With a sliding average, the distribution of disposals in past periods is performed according to the data 
		// of the register "Deviations in the cost of goods". 
		// Requests for the indicator function of the base of the receivers of the past periods should not be executed.
		|	(CASE
		|		WHEN SourceDatabase.Organization IN (&MediumSlipOrganizations)
		|			THEN FALSE
		|		ELSE SourceDatabase.ThisIsPartyOfPastPeriod END) AS ThisIsPartyOfPastPeriod,
		|	(CASE
		|		WHEN SourceDatabase.UseCorPart
		|			THEN SourceDatabase.CorAccountingSection
		|		ELSE SourceDatabase.AccountingSection END)  AS AccountingSection,
		|	(CASE
		|		WHEN SourceDatabase.UseCorPart
		|			THEN SourceDatabase.CorItemsLocationAttributes
		|		ELSE SourceDatabase.ItemsLocationAttributes END)  AS ItemsLocationAttributes,
		|	(CASE
		|		WHEN SourceDatabase.UseCorPart
		|			THEN SourceDatabase.CorInventoryOwnerAttribute
		|		ELSE SourceDatabase.InventoryOwnerAttribute END)   AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	(CASE
		|		WHEN SourceDatabase.UseCorPart
		|			THEN SourceDatabase.CorLot
		|		ELSE SourceDatabase.Lot END)       AS Lot,
		|	(CASE
		|		WHEN SourceDatabase.UseCorPart
		|			THEN SourceDatabase.LotVendorAttributesCorr
		|		ELSE SourceDatabase.LotVendorAttributes END) AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	SourceDatabase.FinRecordID        AS FinRecordID,
		|	SourceDatabase.Count                    AS Count,
		|	SourceDatabase.Cost                     AS Cost,
		|	SourceDatabase.CostExcludingVAT               AS CostExcludingVAT,
		|	SourceDatabase.LocalCost                 AS LocalCost,
		|	SourceDatabase.CostMan                  AS CostMan,
		|	SourceDatabase.CostOfPersonalIncomeTax                  AS CostOfPersonalIncomeTax,
		|	SourceDatabase.CostInTaxAccounting                   AS CostInTaxAccounting,
		|	SourceDatabase.ReceiptPeriod             AS ReceiptPeriod
		|INTO DataTable
		|FROM
		|	Recorders AS DD
		|	INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|		AND Group.NumberOfGroup = &NumberOfGroup
		|	INNER JOIN TUEOfCostPriceMovementAccordingToDocuments AS SourceDatabase
		|		ON SourceDatabase.SourceDocument_ = DD.DimensionOfExpenses
		|		AND SourceDatabase.Organization = DD.Organization
		|	INNER JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.DimensionKey
		|WHERE
		|	(&ConnectionCondition)
		|
		|UNION ALL
		|
		|SELECT
		|	""TextTemplatePrimaryReceiversByDocuments_3"" AS RequestSource,
		|	DD.Ref AS Recorder,
		|	(CASE
		|		WHEN SourceDatabase.Organization IN (&MediumSlipOrganizations)
		|			THEN FALSE
		// With the full version of the distribution of expenses for disposals in the previous period, the batch date is not taken into account.
		// If the source document of the database is reflected in the current period, then the expenses relate to the current period.
		|		WHEN SourceDatabase.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|			THEN FALSE
		|		WHEN NOT PartyRegister.IBDocumentDate IS NULL AND PartyRegister.IBDocumentDate < &BeginOfPeriod
		|			THEN TRUE
		|		ELSE FALSE END) 					   AS ThisIsPartyOfPastPeriod,
		|	(CASE
		|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorAccountingSection
		|		ELSE SourceDatabase.AccountingSection END)  AS AccountingSection,
		|	(CASE
		|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorItemsLocationAttributes
		|		ELSE SourceDatabase.ItemsLocationAttributes END)  AS ItemsLocationAttributes,
		|	(CASE
		|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorInventoryOwnerAttribute
		|		ELSE SourceDatabase.InventoryOwnerAttribute END)   AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	(CASE
		|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorLot
		|		ELSE SourceDatabase.Lot END)       AS Lot,
		|	(CASE
		|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.LotVendorAttributesCorr
		|		ELSE SourceDatabase.LotVendorAttributes END) AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	MAX(CASE WHEN SourceDatabase.RowID <> """"
		|		THEN SourceDatabase.RowID
		|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
		|	SUM(SourceDatabase.Count)             AS Count,
		|	SUM(SourceDatabase.Cost)              AS Cost,
		|	SUM(SourceDatabase.CostExcludingVAT)        AS CostExcludingVAT,
		|	SUM(SourceDatabase.LocalCost)          AS LocalCost,
		|	SUM(SourceDatabase.CostMan)           AS CostMan,
		|	SUM(SourceDatabase.CostOfPersonalIncomeTax)           AS CostOfPersonalIncomeTax,
		|	SUM(SourceDatabase.LocalCost)          AS CostInTaxAccounting,
		|	
		// The Additional expense amount with empty analytics always refers to the current period.
		|	&BeginOfPeriod AS ReceiptPeriod
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|
		|		INNER JOIN TTCashEstimatedTurnoverCostOfGoods AS SourceDatabase
		|		ON DD.Organization = SourceDatabase.Organization
		|			AND SourceDatabase.OfficialTypeOfMovementParish
		|
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
		|		ON Register3.Ref = SourceDatabase.Recorder
		|			AND (NOT Register3.AdditionalRecord OR Register3.RefType IN (&DocumentsWithTwoOrganizations))
		|			AND Register3.ReverseTransactionCorrection
		|
		|		LEFT JOIN Document.PurchaseAdjustment AS Adjusting
		|		ON Adjusting.Ref = SourceDatabase.Recorder
		|
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.DimensionKey
		|
		// The condition for connecting to the register of documents for batches must match the condition in the request for the formation
		// of a temporary table for the movement of the highest value of documents.
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS PartyRegister
		|		ON PartyRegister.Ref = CASE
		|			WHEN SourceDatabase.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.Lot),
		|					VALUE(Enum.LotRecordTypes.Move),
		|					VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|				THEN NULL
		|			WHEN SourceDatabase.ReversingEntry AND NOT SourceDatabase.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.PurchaseAdjustment),
		|					VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer),
		|					VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|					VALUE(Enum.LotRecordTypes.ReverseOfPreviousPeriodsReturn))
		|				THEN NULL
		|			WHEN SourceDatabase.Lot <> UNDEFINED THEN SourceDatabase.Lot
		|			WHEN SourceDatabase.DocumentSource <> UNDEFINED THEN SourceDatabase.DocumentSource
		|			WHEN SourceDatabase.DimensionOfExpenses <> UNDEFINED THEN SourceDatabase.DimensionOfExpenses
		|			ELSE NULL END
		|		AND NOT PartyRegister.AdditionalRecord
		|
		// The condition for connecting to the register of documents for batches must match the condition in the request for the formation
		// of a temporary table for the movement of the highest value of documents.
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentRegistry
		|		ON DocumentRegistry.Ref = CASE
		|				WHEN SourceDatabase.Lot <> UNDEFINED THEN SourceDatabase.Lot
		|				WHEN SourceDatabase.DocumentSource <> UNDEFINED THEN SourceDatabase.DocumentSource
		|				WHEN SourceDatabase.DimensionOfExpenses <> UNDEFINED THEN SourceDatabase.DimensionOfExpenses
		|				ELSE SourceDatabase.Recorder END
		|			AND NOT DocumentRegistry.AdditionalRecord
		|WHERE
		|	DD.DimensionOfExpenses = &EmptyValue
		// The sample from the accounting section "Unfactured deliveries" is used to obtain a distribution base
		// for the documents "Purchase of goods and services (delivery invoice)".
		|	AND NOT SourceDatabase.AccountingSection IN (
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|	AND (NOT SourceDatabase.AccountingSection IN (&OffBalanceSheetAccountingSections)
		// Additional expenses on goods can be distributed to the semi-finished product of the giver, because the semi-finished product of the giver 
		// may have a book value,
		// but should not be distributed to the giver's products, because the giver's products cannot have a book value and
		// must be transferred to the giver. 
		|		OR SourceDatabase.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider) 
		|		)
		|	AND (VALUETYPE(SourceDatabase.Recorder) = VALUETYPE(DD.DimensionOfExpenses)
		|		OR VALUETYPE(Register3.ReversedDocument) = VALUETYPE(DD.DimensionOfExpenses) 
		|		OR VALUETYPE(Register3.CorrectedDocument) = VALUETYPE(DD.DimensionOfExpenses)
		|		OR VALUETYPE(Adjusting.DocumentBasis) = VALUETYPE(DD.DimensionOfExpenses)
		|		)
		|	AND (NOT VALUETYPE(SourceDatabase.Recorder) IN (
		|		TYPE(Document.BackflushProduction)
		|		, TYPE(Document.ProductionStage2_2)
		|		)
		|		OR SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|			AND NOT VALUETYPE(SourceDatabase.Lot) = TYPE(Catalog.ProductionLots))
		|	AND NOT SourceDatabase.Count = 0
		// We exclude from the database the documents of the reverse Cur period, which reverse the documents of the previous period, and
		// purchase adjustments to reduce the number of documents of the previous period.
		// Otherwise, there will be no base for distribution.
		|	AND NOT (VALUETYPE(SourceDatabase.Recorder) = TYPE(Document.ReversingEntry)
		|			AND ISNULL(PartyRegister.IBDocumentDate, &BeginOfPeriod) < &BeginOfPeriod)
		|	AND NOT (SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			AND SourceDatabase.Count < 0
		|			AND ISNULL(PartyRegister.IBDocumentDate, &BeginOfPeriod) < &BeginOfPeriod)
		// Additional costs should not be allocated to services.
		// Services can be in the accounting section "Unfactured deliveries".
		|	AND DimensionOfSelection.Products.ItemsType <> VALUE(Enum.ItemsTypes.OperationService)
		// Additional expenses should not be allocated to the work in the "Unfactured deliveries" section
		// if the work is written off as expenses.
		|	AND NOT (DimensionOfSelection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		AND SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		AND SourceDatabase.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef))
		|	AND (ISNULL(DimensionOfSelection.Purpose.LineOfBusiness,
		|	 VALUE(Catalog.LinesOfBusiness.EmptyRef)) = DD.LineOfBusiness
		|		OR DD.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
		// In the case of a medium-slip sample of Registered Records from the accounting section "Unfactated deliveries" is performed by a separate request,
		// because Registered Records of delivery invoices are generated for the document "Cost Calculation Registrar".
		|	AND NOT (SourceDatabase.Organization IN (&MediumSlipOrganizations)
		|		AND SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
		|	AND (&ConnectionCondition)
		|
		|GROUP BY
		|	DD.Ref,
		|	CASE
		|		WHEN SourceDatabase.Organization IN (&MediumSlipOrganizations)
		|			THEN FALSE
		|		WHEN SourceDatabase.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|			THEN FALSE
		|		WHEN NOT PartyRegister.IBDocumentDate IS NULL AND PartyRegister.IBDocumentDate < &BeginOfPeriod
		|			THEN TRUE
		|		ELSE FALSE END, // ThisIsPartyOfPastPeriod
		|	(CASE
		|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorAccountingSection
		|		ELSE SourceDatabase.AccountingSection END),
		|	(CASE
		|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorItemsLocationAttributes
		|		ELSE SourceDatabase.ItemsLocationAttributes END),
		|	(CASE
		|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorInventoryOwnerAttribute
		|		ELSE SourceDatabase.InventoryOwnerAttribute END),
		|	SourceDatabase.Organization,
		|	(CASE
		|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorLot
		|		ELSE SourceDatabase.Lot END),
		|	(CASE
		|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.LotVendorAttributesCorr
		|		ELSE SourceDatabase.LotVendorAttributes END),
		|	SourceDatabase.FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType
		|
		|UNION ALL
		|
		// The base of distribution according to invoices of deliveries at the average sliding (current month).
		|SELECT
		|	""TextTemplatePrimaryReceiversByDocuments_4"" AS RequestSource,
		|	DD.Ref AS Recorder,
		|	FALSE AS ThisIsPartyOfPastPeriod,
		|	(CASE
		|		WHEN SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorAccountingSection
		|		ELSE SourceDatabase.AccountingSection END)  AS AccountingSection,
		|	(CASE
		|		WHEN SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorItemsLocationAttributes
		|		ELSE SourceDatabase.ItemsLocationAttributes END)  AS ItemsLocationAttributes,
		|	(CASE
		|		WHEN SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorInventoryOwnerAttribute
		|		ELSE SourceDatabase.InventoryOwnerAttribute END)   AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	(CASE
		|		WHEN SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorLot
		|		ELSE SourceDatabase.Lot END)       AS Lot,
		|	(CASE
		|		WHEN SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.LotVendorAttributesCorr
		|		ELSE SourceDatabase.LotVendorAttributes END) AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	MAX(CASE WHEN SourceDatabase.RowID <> """"
		|		THEN SourceDatabase.RowID
		|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
		|	SUM(SourceDatabase.Count)             AS Count,
		|	SUM(SourceDatabase.Cost)              AS Cost,
		|	SUM(SourceDatabase.CostExcludingVAT)        AS CostExcludingVAT,
		|	SUM(SourceDatabase.LocalCost)          AS LocalCost,
		|	SUM(SourceDatabase.CostMan)           AS CostMan,
		|	SUM(SourceDatabase.CostOfPersonalIncomeTax)           AS CostOfPersonalIncomeTax,
		|	SUM(SourceDatabase.LocalCost - SourceDatabase.PermanentDifference - SourceDatabase.CostTD) AS CostInTaxAccounting,
		|	
		// The Additional expense amount with empty analytics always refers to the current period.
		|	&BeginOfPeriod AS ReceiptPeriod
		|FROM
		|	Recorders AS DD
		|
		|	INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|	ON DD.Ref = Group.Object
		|		AND Group.NumberOfGroup = &NumberOfGroup
		|
		|	INNER JOIN TTCashEstimatedTurnoverCostOfGoods AS SourceDatabase
		|	ON DD.Organization = SourceDatabase.Organization
		|		AND SourceDatabase.OfficialTypeOfMovementParish
		|
		|	INNER JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfSelection
		|	ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.DimensionKey
		|
		// The condition for connecting to the register of documents for batches must match the condition in the request for the formation
		// of a temporary table for the movement of the highest value of the documents - Additional tables for receivers of documentation_3
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS PartyRegister
		|	ON PartyRegister.Ref = SourceDatabase.Lot
		|		AND NOT PartyRegister.AdditionalRecord
		|
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentRegistry
		|	ON DocumentRegistry.Ref = SourceDatabase.Lot
		|		AND NOT DocumentRegistry.AdditionalRecord
		|WHERE
		|	DD.DimensionOfExpenses = &EmptyValue
		|	AND VALUETYPE(SourceDatabase.CorLot) = VALUETYPE(DD.DimensionOfExpenses)
		|	AND SourceDatabase.Count <> 0
		// The data sample catch must match the request for additional tables for the acceptors_3 documents.
		|	AND SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|	AND VALUETYPE(SourceDatabase.Recorder) = TYPE(Document.CostCalculationRecorder)
		|	AND SourceDatabase.Organization IN (&MediumSlipOrganizations)
		// Additional costs should not be allocated to services.
		// Services can be in the accounting section "Unfactured deliveries".
		|	AND DimensionOfSelection.Products.ItemsType <> VALUE(Enum.ItemsTypes.OperationService)
		// Additional expenses should not be allocated to the work in the "Unfactured deliveries" section
		// if the work is written off as expenses.
		|	AND NOT (DimensionOfSelection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		AND SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		AND SourceDatabase.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef))
		|	AND (ISNULL(DimensionOfSelection.Purpose.LineOfBusiness,
		|	 VALUE(Catalog.LinesOfBusiness.EmptyRef)) = DD.LineOfBusiness
		|		OR DD.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|	AND (&ConnectionCondition)
		|
		|GROUP BY
		|	DD.Ref,
		|	(CASE
		|		WHEN SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorAccountingSection
		|		ELSE SourceDatabase.AccountingSection END),
		|	(CASE
		|		WHEN SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorItemsLocationAttributes
		|		ELSE SourceDatabase.ItemsLocationAttributes END),
		|	(CASE
		|		WHEN SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorInventoryOwnerAttribute
		|		ELSE SourceDatabase.InventoryOwnerAttribute END),
		|	SourceDatabase.Organization,
		|	(CASE
		|		WHEN SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.CorLot
		|		ELSE SourceDatabase.Lot END),
		|	(CASE
		|		WHEN SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN SourceDatabase.LotVendorAttributesCorr
		|		ELSE SourceDatabase.LotVendorAttributes END),
		|	SourceDatabase.FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType
		|";
	
	Return Template;
	
EndFunction

Function TextTemplatePrimaryReceiversInCatalogs()
	
	Template = 
		"SELECT
		|	""TextTemplatePrimaryReceiversInCatalogs_1"" AS RequestSource,
		|	DD.Ref AS Recorder,
		|	FALSE                                       AS ThisIsPartyOfPastPeriod,
		|	SourceDatabase.AccountingSection                   AS AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	SourceDatabase.Lot                        AS Lot,
		|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	MAX(CASE WHEN SourceDatabase.RowID <> """"
		|		THEN SourceDatabase.RowID
		|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
		|	SUM(SourceDatabase.Count)                AS Count,
		|	SUM(SourceDatabase.Cost)                 AS Cost,
		|	SUM(SourceDatabase.CostExcludingVAT)           AS CostExcludingVAT,
		|	SUM(SourceDatabase.LocalCost)             AS LocalCost,
		|	SUM(SourceDatabase.CostMan)              AS CostMan,
		|	SUM(SourceDatabase.CostOfPersonalIncomeTax)              AS CostOfPersonalIncomeTax,
		|	SUM(SourceDatabase.LocalCost)             AS CostInTaxAccounting,
		|	
		|	&BeginOfPeriod AS ReceiptPeriod
		|INTO DataTable
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|
		|		INNER JOIN TTCashEstimatedTurnoverCostOfGoods AS SourceDatabase
		|		ON DD.Organization = SourceDatabase.Organization
		|			AND SourceDatabase.OfficialTypeOfMovementParish
		|			AND DD.DimensionOfExpenses = &SourceField_
		|
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.Ref
		|
		|		LEFT JOIN Catalog.Warehouses AS WarehouseDetails
		|		ON DimensionOfSelection.StorageLocation = WarehouseDetails.Ref
		|WHERE
		|	(SourceDatabase.EntryType IN (
		|		VALUE(Enum.LotRecordTypes.Lot),
		|		VALUE(Enum.LotRecordTypes.PurchaseAdjustment),
		|		VALUE(Enum.LotRecordTypes.CostAdjustment),
		|		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		|		OR SourceDatabase.Recorder REFS Document.ReceiptOfGoodsFromCustodian
		|		OR SourceDatabase.Recorder REFS Document.ReceiptOfGoodsToWarehouse
		|		)
		|	AND NOT SourceDatabase.Count = 0
		|	AND NOT VALUETYPE(SourceDatabase.Recorder) = TYPE(Document.InventoryTransfer)
		|	AND SourceDatabase.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		// We exclude distribution to off-balance sheet goods, except for semi-finished dvalets, it may have a book cost.
		|	AND (NOT SourceDatabase.AccountingSection IN (&OffBalanceSheetAccountingSections)
		|		OR ISNULL(SourceDatabase.InventoryOwnerAttribute.InventoryType, UNDEFINED) = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider))
		|	AND NOT (SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
		|			AND DimensionOfSelection.StorageType = VALUE(Enum.StorageLocationTypes.Partner))
		|	AND (ISNULL(DimensionOfSelection.Purpose.LineOfBusiness,
		|	 VALUE(Catalog.LinesOfBusiness.EmptyRef)) = DD.LineOfBusiness
		|		OR DD.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|   AND (&ConnectionCondition)
		|
		|GROUP BY
		|	DD.Ref,
		|	SourceDatabase.AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute,
		|	SourceDatabase.Organization,
		|	SourceDatabase.Lot,
		|	SourceDatabase.LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType
		|
		|UNION ALL
		|
		|SELECT
		|	""TextTemplatePrimaryReceiversInCatalogs_2"" AS RequestSource,
		|	DD.Ref AS Recorder,
		|	FALSE                                       AS ThisIsPartyOfPastPeriod,
		|	SourceDatabase.AccountingSection                   AS AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	SourceDatabase.Lot                        AS Lot,
		|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	MAX(CASE WHEN SourceDatabase.RowID <> """"
		|		THEN SourceDatabase.RowID
		|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
		|	SUM(SourceDatabase.Count)                AS Count,
		|	SUM(SourceDatabase.Cost)                 AS Cost,
		|	SUM(SourceDatabase.CostExcludingVAT)           AS CostExcludingVAT,
		|	SUM(SourceDatabase.LocalCost)             AS LocalCost,
		|	SUM(SourceDatabase.CostMan)              AS CostMan,
		|	SUM(SourceDatabase.CostOfPersonalIncomeTax)              AS CostOfPersonalIncomeTax,
		|	SUM(SourceDatabase.LocalCost)             AS CostInTaxAccounting,
		|	
		|	&BeginOfPeriod AS ReceiptPeriod
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|
		|		INNER JOIN TTCashEstimatedTurnoverCostOfGoods AS SourceDatabase
		|		ON DD.Organization = SourceDatabase.Organization
		|			AND SourceDatabase.OfficialTypeOfMovementParish
		|
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.Ref
		|
		|		LEFT JOIN Catalog.Warehouses AS WarehouseDetails
		|		ON DimensionOfSelection.StorageLocation = WarehouseDetails.Ref
		|WHERE
		|	DD.DimensionOfExpenses = &EmptyValue
		|	AND NOT SourceDatabase.Count = 0
		|	AND (SourceDatabase.EntryType IN (
		|		VALUE(Enum.LotRecordTypes.Lot),
		|		VALUE(Enum.LotRecordTypes.PurchaseAdjustment),
		|		VALUE(Enum.LotRecordTypes.CostAdjustment),
		|		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		|		OR SourceDatabase.Recorder REFS Document.ReceiptOfGoodsFromCustodian
		|		OR SourceDatabase.Recorder REFS Document.ReceiptOfGoodsToWarehouse
		// In the distribution base, we include the transfer of finished products to the warehouse, because the output of products to the division or
		// workshop pantry is not included in the distribution base according to the condition for the Accounting section of production costs. 
		|		OR SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.Move)
		|			AND SourceDatabase.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
		|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction))
		|		)
		|	AND NOT SourceDatabase.Count = 0
		|	AND NOT VALUETYPE(SourceDatabase.Recorder) = TYPE(Document.InventoryTransfer)
		|	AND SourceDatabase.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		// We exclude distribution to off-balance sheet goods, except for semi-finished dvalets, it may have a book cost.
		|	AND (NOT SourceDatabase.AccountingSection IN (&OffBalanceSheetAccountingSections)
		|		OR ISNULL(SourceDatabase.InventoryOwnerAttribute.InventoryType, UNDEFINED) = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider))
		|	AND NOT (SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
		|			AND DimensionOfSelection.StorageType = VALUE(Enum.StorageLocationTypes.Partner))
		|	AND (ISNULL(DimensionOfSelection.Purpose.LineOfBusiness,
		|	 VALUE(Catalog.LinesOfBusiness.EmptyRef)) = DD.LineOfBusiness
		|		OR DD.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|	AND (DimensionOfSelection.Products.ProductKind.ItemsType = VALUE(Enum.ItemsTypes.Work_5) 
		|		OR SourceDatabase.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts))
		|	AND (&ConnectionCondition)
		|
		|GROUP BY
		|	DD.Ref,
		|	SourceDatabase.AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute,
		|	SourceDatabase.Organization,
		|	SourceDatabase.Lot,
		|	SourceDatabase.LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType
		|
		|UNION ALL
		|
		|SELECT
		|	""TextTemplatePrimaryReceiversInCatalogs_3"" AS RequestSource,
		|	DD.Ref AS Recorder,
		|	FALSE                                       AS ThisIsPartyOfPastPeriod,
		|	SourceDatabase.AccountingSection                   AS AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	SourceDatabase.Lot                        AS Lot,
		|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	""""                                       AS FinRecordID,
		|	SourceDatabase.CountBalance             AS Count,
		|	SourceDatabase.CostBalance              AS Cost,
		|	SourceDatabase.CostExcludingVATBalance        AS CostExcludingVAT,
		|	SourceDatabase.LocalCostBalance          AS LocalCost,
		|	SourceDatabase.CostManBalance           AS CostMan,
		|	SourceDatabase.CostOfPersonalIncomeTaxBalance           AS CostOfPersonalIncomeTax,
		|	SourceDatabase.LocalCostBalance          AS CostInTaxAccounting,
		|	
		|	&BeginOfPeriod AS ReceiptPeriod
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|
		|		INNER JOIN AccumulationRegister.InventoryCost.Balance(&BorderStartOfPeriod,
		|			Organization IN (&CompanyArray)
		|			AND AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		// We exclude distribution to off-balance sheet goods, except for semi-finished dvalets, it may have a book cost.
		|			AND (NOT AccountingSection IN (&OffBalanceSheetAccountingSections)
		|				OR ISNULL(InventoryOwnerAttribute.InventoryType, UNDEFINED) = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)) 
		|			AND (AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
		|				AND NOT ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
		|			OR AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|				AND (VALUETYPE(ItemsLocationAttributes.StorageLocation) = TYPE(Catalog.Warehouses)
		|					OR ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)))) AS SourceDatabase
		|		ON DD.Organization = SourceDatabase.Organization
		|			AND DD.DimensionOfExpenses = &SourceField_
		|
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.DimensionKey
		|WHERE
		|	NOT SourceDatabase.CountBalance = 0
		|	AND (ISNULL(DimensionOfSelection.Purpose.LineOfBusiness,
		|	 VALUE(Catalog.LinesOfBusiness.EmptyRef)) = DD.LineOfBusiness
		|		OR DD.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|	AND (&ConnectionCondition)";
	
	Return Template;
	
EndFunction

Function TextTemplatePrimaryReceiversOtherExpenses()
	
	Template = 
		"SELECT
		|	""TextTemplatePrimaryReceiversOtherExpenses"" AS RequestSource,
		|	DD.Ref AS Recorder,
		|	FALSE                                       AS ThisIsPartyOfPastPeriod,
		|	SourceDatabase.AccountingSection                   AS AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	SourceDatabase.Lot                        AS Lot,
		|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	SourceDatabase.FinRecordID        AS FinRecordID,
		|	SourceDatabase.Count                    AS Count,
		|	SourceDatabase.Cost                     AS Cost,
		|	SourceDatabase.CostExcludingVAT               AS CostExcludingVAT,
		|	SourceDatabase.LocalCost                 AS LocalCost,
		|	SourceDatabase.CostMan                  AS CostMan,
		|	SourceDatabase.CostOfPersonalIncomeTax                  AS CostOfPersonalIncomeTax,
		|	SourceDatabase.CostInTaxAccounting                   AS CostInTaxAccounting,
		|	
		|	&BeginOfPeriod AS ReceiptPeriod
		|INTO DataTable
		|FROM
		|	Recorders AS DD
		|	INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|		AND Group.NumberOfGroup = &NumberOfGroup
		|	INNER JOIN TUEOfMovementOfCostOfOtherExpenses AS SourceDatabase
		|		ON DD.Organization = SourceDatabase.Organization
		|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.Ref
		|WHERE
		|   (&ConnectionCondition)
		|";
	
	Return Template;
	
EndFunction

Function TextTemplatePrimaryRecyclingReceivers()
	
	Template = 
		"SELECT
		|	""TextTemplatePrimaryRecyclingReceivers_1"" AS RequestSource,
		|	DD.Ref AS Recorder,
		|	FALSE                                       AS ThisIsPartyOfPastPeriod,
		|	SourceDatabase.AccountingSection                   AS AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	SourceDatabase.Lot                        AS Lot,
		|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	"""" AS FinRecordID,
		|	SUM(SourceDatabase.CountBalance)      AS Count,
		|	SUM(SourceDatabase.CostBalance)       AS Cost,
		|	SUM(SourceDatabase.CostExcludingVATBalance) AS CostExcludingVAT,
		|	SUM(SourceDatabase.LocalCostBalance)   AS LocalCost,
		|	SUM(SourceDatabase.CostManBalance)    AS CostMan,
		|	SUM(SourceDatabase.CostOfPersonalIncomeTaxBalance)    AS CostOfPersonalIncomeTax,
		|	SUM(SourceDatabase.LocalCostBalance)   AS CostInTaxAccounting,
		|	
		|	MIN(BEGINOFPERIOD(CASE
		|		WHEN DocumentRegistry.IBDocumentDate IS NULL OR DocumentRegistry.IBDocumentDate < &DateOfMigrationToBatchAccounting22
		|		THEN &DateOfMigrationToBatchAccounting22
		|		ELSE DocumentRegistry.IBDocumentDate
		|	END, MONTH)) AS ReceiptPeriod
		|
		|INTO DataTable
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|
		|		INNER JOIN AccumulationRegister.InventoryCost.Balance(&BorderStartOfPeriod,
		|			Organization IN (&CompanyArray) AND 
		|			AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
		|				AND ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|		) AS SourceDatabase
		|		ON DD.Organization = SourceDatabase.Organization
		|			AND DD.DimensionOfExpenses = &SourceField_
		|
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.DimensionKey
		|
		// The condition for connecting to the register of documents for batches must match the condition in the request for the formation
		// of a temporary table for the movement of the highest value of documents.
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentRegistry
		|		ON DocumentRegistry.Ref = CASE
		|			WHEN SourceDatabase.Lot <> UNDEFINED THEN SourceDatabase.Lot
		|			ELSE NULL END
		|		AND NOT DocumentRegistry.AdditionalRecord
		|WHERE
		|	NOT SourceDatabase.CountBalance = 0
		|	AND (&ConnectionCondition)
		|
		|GROUP BY
		|	DD.Ref,
		|	SourceDatabase.AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute,
		|	SourceDatabase.Organization,
		|	SourceDatabase.Lot,
		|	SourceDatabase.LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType
		|
		|UNION ALL
		|
		|SELECT
		|	""TextTemplatePrimaryRecyclingReceivers_2"" AS RequestSource,
		|	DD.Ref AS Recorder,
		|	FALSE                                       AS ThisIsPartyOfPastPeriod,
		|	SourceDatabase.AccountingSection                   AS AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	SourceDatabase.Lot                        AS Lot,
		|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	MAX(CASE WHEN SourceDatabase.RowID <> """"
		|		THEN SourceDatabase.RowID
		|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
		|	SUM(SourceDatabase.Count)             AS Count,
		|	SUM(SourceDatabase.Cost)              AS Cost,
		|	SUM(SourceDatabase.CostExcludingVAT)        AS CostExcludingVAT,
		|	SUM(SourceDatabase.LocalCost)          AS LocalCost,
		|	SUM(SourceDatabase.CostMan)           AS CostMan,
		|	SUM(SourceDatabase.CostOfPersonalIncomeTax)           AS CostOfPersonalIncomeTax,
		|	SUM(SourceDatabase.LocalCost)          AS CostInTaxAccounting,
		|	
		|	MIN(BEGINOFPERIOD(CASE
		|		WHEN DocumentRegistry.IBDocumentDate IS NULL OR DocumentRegistry.IBDocumentDate < &DateOfMigrationToBatchAccounting22
		|		THEN &DateOfMigrationToBatchAccounting22
		|		ELSE DocumentRegistry.IBDocumentDate
		|	END, MONTH)) AS ReceiptPeriod
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|
		|		INNER JOIN TTCashEstimatedTurnoverCostOfGoods AS SourceDatabase
		|		ON DD.Organization = SourceDatabase.Organization
		|			AND SourceDatabase.OfficialTypeOfMovementParish
		|			AND DD.DimensionOfExpenses = &SourceField_
		|
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.Ref
		|
		|		LEFT JOIN Catalog.Warehouses AS WarehouseDetails
		|		ON DimensionOfSelection.StorageLocation = WarehouseDetails.Ref
		|
		// The condition for connecting to the register of documents for batches must match the condition in the request for the formation
		// of a temporary table for the movement of the highest value of documents.
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentRegistry
		|		ON DocumentRegistry.Ref = CASE
		|				WHEN SourceDatabase.Lot <> UNDEFINED THEN SourceDatabase.Lot
		|				WHEN SourceDatabase.DocumentSource <> UNDEFINED THEN SourceDatabase.DocumentSource
		|				WHEN SourceDatabase.DimensionOfExpenses <> UNDEFINED THEN SourceDatabase.DimensionOfExpenses
		|				ELSE NULL END
		|			AND NOT DocumentRegistry.AdditionalRecord
		|WHERE
		|	SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.Move)
		|	AND NOT SourceDatabase.Count = 0
		|	AND (SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
		|		AND DimensionOfSelection.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract))
		|	AND (&ConnectionCondition)
		|
		|GROUP BY
		|	DD.Ref,
		|	SourceDatabase.AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute,
		|	SourceDatabase.Organization,
		|	SourceDatabase.Lot,
		|	SourceDatabase.LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType
		|
		|UNION ALL
		|
		|SELECT
		|	""TextTemplatePrimaryRecyclingReceivers_3"" AS RequestSource,
		|	DD.Ref AS Recorder,
		|	FALSE                                       AS ThisIsPartyOfPastPeriod,
		|	SourceDatabase.AccountingSection                   AS AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
		|	SourceDatabase.Organization                   AS Organization,
		|	SourceDatabase.Lot                        AS Lot,
		|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType            AS VATActivityType,
		|	MAX(CASE WHEN SourceDatabase.RowID <> """"
		|		THEN SourceDatabase.RowID
		|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
		|	SUM(SourceDatabase.Count)             AS Count,
		|	SUM(SourceDatabase.Cost)              AS Cost,
		|	SUM(SourceDatabase.CostExcludingVAT)        AS CostExcludingVAT,
		|	SUM(SourceDatabase.LocalCost)          AS LocalCost,
		|	SUM(SourceDatabase.CostMan)           AS CostMan,
		|	SUM(SourceDatabase.CostOfPersonalIncomeTax)           AS CostOfPersonalIncomeTax,
		|	SUM(SourceDatabase.LocalCost)          AS CostInTaxAccounting,
		|	
		|	MIN(BEGINOFPERIOD(CASE
		|		WHEN DocumentRegistry.IBDocumentDate IS NULL OR DocumentRegistry.IBDocumentDate < &DateOfMigrationToBatchAccounting22
		|		THEN &DateOfMigrationToBatchAccounting22
		|		ELSE DocumentRegistry.IBDocumentDate
		|	END, MONTH)) AS ReceiptPeriod
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN GroupsOfAdditionalExpenseItems AS Group
		|		ON DD.Ref = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|
		|		INNER JOIN TTCashEstimatedTurnoverCostOfGoods AS SourceDatabase
		|		ON DD.Organization = SourceDatabase.Organization
		|			AND SourceDatabase.OfficialTypeOfMovementParish
		|
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfSelection
		|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.Ref
		|
		|		LEFT JOIN Catalog.Warehouses AS WarehouseDetails
		|		ON DimensionOfSelection.StorageLocation = WarehouseDetails.Ref
		|
		// The condition for connecting to the register of documents for batches must match the condition in the request for the formation
		// of a temporary table for the movement of the highest value of documents.
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentRegistry
		|		ON DocumentRegistry.Ref = CASE
		|				WHEN SourceDatabase.Lot <> UNDEFINED THEN SourceDatabase.Lot
		|				WHEN SourceDatabase.DocumentSource <> UNDEFINED THEN SourceDatabase.DocumentSource
		|				WHEN SourceDatabase.DimensionOfExpenses <> UNDEFINED THEN SourceDatabase.DimensionOfExpenses
		|				ELSE NULL END
		|			AND NOT DocumentRegistry.AdditionalRecord
		|WHERE
		|	DD.DimensionOfExpenses = &EmptyValue
		|	AND NOT SourceDatabase.Count = 0
		|	AND SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.Move)
		|	AND NOT SourceDatabase.Count = 0
		|	AND SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
		|		AND DimensionOfSelection.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|	AND (&ConnectionCondition)
		|
		|GROUP BY
		|	DD.Ref,
		|	SourceDatabase.AccountingSection,
		|	SourceDatabase.ItemsLocationAttributes,
		|	SourceDatabase.InventoryOwnerAttribute,
		|	SourceDatabase.Organization,
		|	SourceDatabase.Lot,
		|	SourceDatabase.LotVendorAttributes,
		|	SourceDatabase.FinancialAccountingDimension,
		|	SourceDatabase.VATActivityType
		|	";
	
	Return Template;
	
EndFunction

Function AdditionalTablesForDocumentReceivers()
	
	QueryText = 
	"SELECT DISTINCT
	|	T.DimensionOfExpenses AS Ref
	|INTO VTDocumentsInExpenseAnalytics
	|FROM
	|	Recorders AS T
	|	INNER JOIN GroupsOfAdditionalExpenseItems AS Group
	|		ON T.Ref = Group.Object
	|WHERE
	|	T.DimensionOfExpenses <> UNDEFINED
	|	AND (&SelectionByGroupsByDocuments)
	|INDEX BY
	|	Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT DISTINCT
	|	T.Ref,
	|	T.SourceDocument_
	|INTO TUEOfCommunicationOfDocumentsOfCostAnalysis
	|FROM
	|(SELECT
	|	T.Ref AS Ref,
	|	T.Ref AS SourceDocument_
	|FROM
	|	VTDocumentsInExpenseAnalytics AS T
	|	INNER JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON T.Ref = Register3.Ref
	|			AND NOT Register3.AdditionalRecord
	|
	|UNION ALL
	|
	|SELECT
	|	Adjusting.Ref AS Ref,
	|	T.Ref AS SourceDocument_
	|FROM
	|	VTDocumentsInExpenseAnalytics AS T
	|	INNER JOIN Document.PurchaseAdjustment AS Adjusting
	|		ON T.Ref = Adjusting.DocumentBasis
	|
	|UNION ALL
	|
	|SELECT
	|	Register3.Ref AS Ref,
	|	T.Ref AS SourceDocument_
	|FROM
	|	VTDocumentsInExpenseAnalytics AS T
	|	INNER JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON T.Ref = Register3.ReversedDocument
	|			AND NOT Register3.AdditionalRecord
	|			AND Register3.ReverseTransactionCorrection
	|
	|UNION ALL
	|
	|SELECT
	|	Register3.Ref AS Ref,
	|	T.Ref AS SourceDocument_
	|FROM
	|	VTDocumentsInExpenseAnalytics AS T
	|	INNER JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON T.Ref = Register3.CorrectedDocument
	|			AND NOT Register3.AdditionalRecord
	|			AND Register3.ReverseTransactionCorrection
	|
	|UNION ALL
	|
	// Additional expenses for the lots transferred to the branch according to the documents of the previous period.
	// Such parties are reflected by the "Parish" movement in the household. operations "Internal receipt of works" and "Internal receipt of goods".
	|SELECT DISTINCT
	|	T.Recorder AS Ref,
	|	T.Lot AS SourceDocument_
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|	INNER JOIN InformationRegister.DocumentsRegistry AS Register3
	|	ON Register3.Ref = T.Lot
	|		AND NOT Register3.AdditionalRecord
	|WHERE
	|	T.Organization IN (&CompanyArray)
	|	AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND T.Period BETWEEN BEGINOFPERIOD(Register3.IBDocumentDate, MONTH) AND &BeginOfPeriod
	|	AND T.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.InternalWorkReceipt),
	|		VALUE(Enum.BusinessTransactions.InternalGoodsReceipt))
	|
	|UNION ALL
	|
	// Additional expenses for the lots transferred to the branch according to the documents of the Cur period.
	|SELECT DISTINCT
	|	T.Recorder AS Ref,
	|	T.Lot AS SourceDocument_
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS T
	|WHERE
	|	T.OfficialTypeOfMovementParish
	|	AND T.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.InternalWorkReceipt),
	|		VALUE(Enum.BusinessTransactions.InternalGoodsReceipt))
	|) AS T
	|INDEX BY
	|	Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SourceDatabase.Period AS Period,
	|	SourceDatabase.Recorder AS Recorder,
	|	SourceDatabase.RowID,
	|	SourceDatabase.FinRecordID
	|
	|INTO TTWriteOffsForExpenses
	|FROM
	|	AccumulationRegister.InventoryCost AS SourceDatabase
	|	INNER JOIN TUEOfCommunicationOfDocumentsOfCostAnalysis AS Filter
	|		ON SourceDatabase.Recorder = Filter.Ref
	|WHERE
	|	SourceDatabase.Organization IN (&CompanyArray)
	|	AND SourceDatabase.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND SourceDatabase.Period <= &EndOfPeriod
	|	AND SourceDatabase.Count <> 0
	|	AND SourceDatabase.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets)
	|	AND SourceDatabase.BusinessOperation <> VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost)
	|INDEX BY
	|	Period,
	|	Recorder
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	""TUEOfCostPriceMovementAccordingToDocuments_1"" AS RequestSource,
	|	SourceDatabase.Recorder,
	|	Filter.SourceDocument_ AS SourceDocument_,
	|	TRUE AS ThisIsPartyOfPastPeriod,
	|	CASE WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|	  AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS UseCorPart,
	|	SourceDatabase.Organization,
	|	SourceDatabase.AccountingSection,
	|	SourceDatabase.CorAccountingSection,
	|	SourceDatabase.ItemsLocationAttributes,
	|	SourceDatabase.CorItemsLocationAttributes,
	|	SourceDatabase.InventoryOwnerAttribute,
	|	SourceDatabase.CorInventoryOwnerAttribute,
	|	SourceDatabase.Lot,
	|	SourceDatabase.CorLot,
	|	SourceDatabase.LotVendorAttributes,
	|	SourceDatabase.LotVendorAttributesCorr,
	|	SourceDatabase.FinancialAccountingDimension,
	|	(CASE
	|		WHEN SourceDatabase.Organization IN (&MediumSlipOrganizations)
	|			THEN SourceDatabase.DocumentVATActivityType
	|		ELSE SourceDatabase.VATActivityType END) AS VATActivityType,
	|	MAX(CASE WHEN SourceDatabase.RowID <> """"
	|		THEN SourceDatabase.RowID
	|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
	|	SUM(SourceDatabase.Count) AS Count,
	|	SUM(SourceDatabase.Cost + SourceDatabase.AddExpensesForGoods) AS Cost,
	|	SUM(SourceDatabase.CostExcludingVAT + SourceDatabase.AdditionalExpensesExcludingVAT) AS CostExcludingVAT,
	|	SUM(SourceDatabase.LocalCost + SourceDatabase.AddExpensesLocal) AS LocalCost,
	|	SUM(SourceDatabase.CostMan + SourceDatabase.AddExpensesMan) AS CostMan,
	|	SUM(SourceDatabase.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
	|	SUM(SourceDatabase.LocalCost + SourceDatabase.AddExpensesLocal) AS CostInTaxAccounting,
	|	MIN(BEGINOFPERIOD(SourceDatabase.Period, MONTH)) AS ReceiptPeriod
	|
	|INTO TUEOfCostPriceMovementAccordingToDocuments
	|FROM
	|	AccumulationRegister.InventoryCost AS SourceDatabase
	|	INNER JOIN TUEOfCommunicationOfDocumentsOfCostAnalysis AS Filter
	|		ON SourceDatabase.Recorder = Filter.Ref
	|	LEFT JOIN TTWriteOffsForExpenses AS WriteOffsForExpenses
	|		ON WriteOffsForExpenses.Period = SourceDatabase.Period
	|		AND WriteOffsForExpenses.Recorder = SourceDatabase.Recorder
	|		AND WriteOffsForExpenses.RowID = SourceDatabase.RowID
	|		AND WriteOffsForExpenses.FinRecordID = SourceDatabase.FinRecordID
	|WHERE
	|	SourceDatabase.Organization IN (&CompanyArray)
	|	AND SourceDatabase.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND SourceDatabase.Period < &BeginOfPeriod
	// The Registered Recorded sample conditions must match the Template text's request for the primary acceptorposacazam_1
	|	AND (SourceDatabase.Count <> 0
	|		OR SourceDatabase.EntryType IN (
	|			VALUE(Enum.LotRecordTypes.Lot),
	|			VALUE(Enum.LotRecordTypes.Consumption),
	|			VALUE(Enum.LotRecordTypes.CostAdjustment),
	|			VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
	|			VALUE(Enum.LotRecordTypes.Move),
	|			VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis)))
	// The sample from the accounting section "Unfactured deliveries" is used to obtain a distribution base
	// for documents "Purchase of goods and services (invoicing of delivery)", except for organizations on a medium-slip.
	// The base of distribution according to invoices for deliveries with a medium-slip is formed in the request for the movement of the highest value of the document_4.
	|	AND NOT (SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND SourceDatabase.Organization IN (&MediumSlipOrganizations))
	|	AND NOT SourceDatabase.AccountingSection IN (
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|	AND (NOT SourceDatabase.AccountingSection IN (&OffBalanceSheetAccountingSections)
	// Additional expenses on goods can be distributed to the semi-finished product of the giver, because the semi-finished product of the giver 
	// may have a book value,
	// but should not be distributed to the giver's products, because the giver's products cannot have a book value and
	// must be transferred to the giver. 
	|			OR SourceDatabase.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider) 
	|		)
	|
	// According to the documents of production, the distribution database should only include 
	|	AND (NOT VALUETYPE(SourceDatabase.Recorder) IN (
	|		TYPE(Document.BackflushProduction)
	|		, TYPE(Document.ProductionStage2_2)
	|		)
	|		OR SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|			AND NOT VALUETYPE(SourceDatabase.Lot) = TYPE(Catalog.ProductionLots)
	|		OR SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|			AND NOT WriteOffsForExpenses.Recorder IS NULL
	|	)
	// Additional costs should not be allocated to services.
	// Services can be in the accounting section "Unfactured deliveries".
	|	AND SourceDatabase.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.OperationService)
	// Additional expenses should not be allocated to the work in the "Unfactured deliveries" section
	// if the work is written off as expenses.
	|	AND NOT (SourceDatabase.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND SourceDatabase.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef))
	// Expenses with the "Acquisition Adjustment" analytics are allocated only to positive receipts.
	|	AND NOT (VALUETYPE(Filter.SourceDocument_) = TYPE(Document.PurchaseAdjustment)
	|		AND SourceDatabase.Count < 0)
	// For the batch moved to the branch, we additionally check the compliance of the batch and expense analytics.
	|	AND NOT (SourceDatabase.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.InternalWorkReceipt),
	|			VALUE(Enum.BusinessTransactions.InternalGoodsReceipt))
	|		AND SourceDatabase.Lot <> UNDEFINED
	|		AND SourceDatabase.Lot <> Filter.SourceDocument_
	// We exclude the original documents Recorders of Registered Records from the check. These may be documents for the movement of goods.
	|		AND SourceDatabase.Recorder <> Filter.SourceDocument_
	|	)
	|
	|GROUP BY
	|	SourceDatabase.Recorder,
	|	Filter.SourceDocument_,
	|	CASE
	|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|			AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		THEN TRUE ELSE FALSE
	|	END,
	|	SourceDatabase.Organization,
	|	SourceDatabase.AccountingSection,
	|	SourceDatabase.CorAccountingSection,
	|	SourceDatabase.ItemsLocationAttributes,
	|	SourceDatabase.CorItemsLocationAttributes,
	|	SourceDatabase.InventoryOwnerAttribute,
	|	SourceDatabase.CorInventoryOwnerAttribute,
	|	SourceDatabase.Lot,
	|	SourceDatabase.CorLot,
	|	SourceDatabase.LotVendorAttributes,
	|	SourceDatabase.LotVendorAttributesCorr,
	|	SourceDatabase.FinancialAccountingDimension,
	|	(CASE
	|		WHEN SourceDatabase.Organization IN (&MediumSlipOrganizations)
	|			THEN SourceDatabase.DocumentVATActivityType
	|		ELSE SourceDatabase.VATActivityType END) // VATActivityType
	|
	|UNION ALL
	|
	|SELECT
	|	""TUEOfCostPriceMovementAccordingToDocuments_2"" AS RequestSource,
	|	SourceDatabase.Recorder,
	|	Filter.SourceDocument_ AS SourceDocument_,
	|	CASE
	// With the full version of the distribution of expenses for disposals in the previous period, the batch date is not taken into account.
	// If the source document of the database is reflected in the current period, then the expenses relate to the current period.
	|		WHEN SourceDatabase.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
	|			THEN FALSE
	|		WHEN NOT PartyRegister.IBDocumentDate IS NULL AND PartyRegister.IBDocumentDate < &BeginOfPeriod
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsPartyOfPastPeriod,
	|	CASE WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|	  AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS UseCorPart,
	|	SourceDatabase.Organization,
	|	SourceDatabase.AccountingSection,
	|	SourceDatabase.CorAccountingSection,
	|	SourceDatabase.ItemsLocationAttributes,
	|	SourceDatabase.CorItemsLocationAttributes,
	|	SourceDatabase.InventoryOwnerAttribute,
	|	SourceDatabase.CorInventoryOwnerAttribute,
	|	SourceDatabase.Lot,
	|	SourceDatabase.CorLot,
	|	SourceDatabase.LotVendorAttributes,
	|	SourceDatabase.LotVendorAttributesCorr,
	|	SourceDatabase.FinancialAccountingDimension,
	|	(CASE
	|		WHEN SourceDatabase.Organization IN (&MediumSlipOrganizations)
	|			THEN SourceDatabase.DocumentVATActivityType
	|		ELSE SourceDatabase.VATActivityType END) AS VATActivityType,
	|	MAX(CASE WHEN SourceDatabase.RowID <> """"
	|		THEN SourceDatabase.RowID
	|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
	|	SUM(SourceDatabase.Count) AS Count,
	|	SUM(SourceDatabase.Cost + SourceDatabase.AddExpensesForGoods) AS Cost,
	|	SUM(SourceDatabase.CostExcludingVAT + SourceDatabase.AdditionalExpensesExcludingVAT) AS CostExcludingVAT,
	|	SUM(SourceDatabase.LocalCost + SourceDatabase.AddExpensesLocal) AS LocalCost,
	|	SUM(SourceDatabase.CostMan + SourceDatabase.AddExpensesMan) AS CostMan,
	|	SUM(SourceDatabase.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
	|	SUM(SourceDatabase.LocalCost + SourceDatabase.AddExpensesLocal) AS CostInTaxAccounting,
	|	
	|	MIN(BEGINOFPERIOD(CASE
	// With the full version of the distribution of expenses for disposals in the previous period, the batch date is not taken into account.
	// If the source document of the database is reflected in the current period, then the expenses relate to the current period.
	|		WHEN SourceDatabase.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
	|			THEN SourceDatabase.Period
	|		WHEN DocumentRegistry.IBDocumentDate IS NULL OR DocumentRegistry.IBDocumentDate < &DateOfMigrationToBatchAccounting22
	|			THEN &DateOfMigrationToBatchAccounting22
	|		ELSE DocumentRegistry.IBDocumentDate
	|	END, MONTH)) AS ReceiptPeriod
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS SourceDatabase
	|	INNER JOIN TUEOfCommunicationOfDocumentsOfCostAnalysis AS Filter
	|		ON SourceDatabase.Recorder = Filter.Ref
	// The condition for connecting to the document registry for batches must match the condition in the Template text functionThe primary document acceptor_3
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS PartyRegister
	|		ON PartyRegister.Ref = CASE
	|			WHEN SourceDatabase.EntryType IN (
	|					VALUE(Enum.LotRecordTypes.Lot),
	|					VALUE(Enum.LotRecordTypes.Move),
	// Lines from the batch registry are not selected for transfers between organizations (moving separately),
	// because otherwise it will pick up the batch according to the sending organization and the batch of the previous period may come across. For the recipient organization, this is a Cur-period operation.
	|					VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
	|				THEN NULL
	// For reverse entries (all except for the previous period), lines from the batch registry are not selected,
	// because otherwise it will select a batch based on a non-existent record (already closed in the Cur period).
	|			WHEN SourceDatabase.ReversingEntry AND NOT SourceDatabase.EntryType IN (
	|					VALUE(Enum.LotRecordTypes.PurchaseAdjustment),
	|					VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer),
	|					VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
	|					VALUE(Enum.LotRecordTypes.ReverseOfPreviousPeriodsReturn),
	|					VALUE(Enum.LotRecordTypes.PurchaseAdjustment))
	|				THEN NULL
	|			WHEN SourceDatabase.Lot <> UNDEFINED THEN SourceDatabase.Lot
	|			WHEN SourceDatabase.DocumentSource <> UNDEFINED THEN SourceDatabase.DocumentSource
	|			WHEN SourceDatabase.DimensionOfExpenses <> UNDEFINED THEN SourceDatabase.DimensionOfExpenses
	|			ELSE NULL END
	|		AND NOT PartyRegister.AdditionalRecord
	// The condition for connecting to the document registry for batches must match the condition in the textreceiver function of the past periodsadditional expenses
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentRegistry
	|		ON DocumentRegistry.Ref = CASE
	|				WHEN SourceDatabase.Lot <> UNDEFINED THEN SourceDatabase.Lot
	|				WHEN SourceDatabase.DocumentSource <> UNDEFINED THEN SourceDatabase.DocumentSource
	|				WHEN SourceDatabase.DimensionOfExpenses <> UNDEFINED THEN SourceDatabase.DimensionOfExpenses
	|				ELSE Filter.Ref END
	|			AND NOT DocumentRegistry.AdditionalRecord
	|
	|	LEFT JOIN TTWriteOffsForExpenses AS WriteOffsForExpenses
	|		ON WriteOffsForExpenses.Period = SourceDatabase.Period
	|		AND WriteOffsForExpenses.Recorder = SourceDatabase.Recorder
	|		AND WriteOffsForExpenses.RowID = SourceDatabase.RowID
	|		AND WriteOffsForExpenses.FinRecordID = SourceDatabase.FinRecordID
	|WHERE
	|	SourceDatabase.OfficialTypeOfMovementParish
	|	AND (SourceDatabase.Count <> 0
	|		OR SourceDatabase.EntryType IN (
	|			VALUE(Enum.LotRecordTypes.Lot),
	|			VALUE(Enum.LotRecordTypes.CostAdjustment),
	|			VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
	|		))
	// The sample from the accounting section "Unfactured deliveries" is used to obtain a distribution base
	// for the documents "Purchase of goods and services (delivery invoice)".
	|	AND NOT SourceDatabase.AccountingSection IN (
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|	AND (NOT SourceDatabase.AccountingSection IN (&OffBalanceSheetAccountingSections)
	// Additional expenses on goods can be distributed to the semi-finished product of the giver, because the semi-finished product of the giver 
	// may have a book value,
	// but should not be distributed to the giver's products, because the giver's products cannot have a book value and
	// must be transferred to the giver. 
	|			OR SourceDatabase.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider) 
	|		)
	|	AND (NOT VALUETYPE(SourceDatabase.Recorder) IN (
	|		TYPE(Document.BackflushProduction)
	|		, TYPE(Document.ProductionStage2_2)
	|		)
	|		OR SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|			AND NOT VALUETYPE(SourceDatabase.Lot) = TYPE(Catalog.ProductionLots)
	|		OR SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|			AND NOT WriteOffsForExpenses.Recorder IS NULL
	|	)
	// Additional costs should not be allocated to services.
	// Services can be in the accounting section "Unfactured deliveries".
	|	AND SourceDatabase.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.OperationService)
	// Additional expenses should not be allocated to the work in the "Unfactured deliveries" section
	// if the work is written off as expenses.
	|	AND NOT (SourceDatabase.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND SourceDatabase.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef))
	// Expenses with the "Acquisition Adjustment" analytics are allocated only to positive receipts.
	|	AND NOT (VALUETYPE(Filter.SourceDocument_) = TYPE(Document.PurchaseAdjustment)
	|		AND SourceDatabase.Count < 0)
	// We exclude from the database the documents of the reverse Cur period, which reverse the documents of the previous period, and
	// purchase adjustments to reduce the number of documents of the previous period.
	// Otherwise, there will be no base for distribution.
	|	AND NOT (VALUETYPE(SourceDatabase.Recorder) = TYPE(Document.ReversingEntry)
	|			AND ISNULL(PartyRegister.IBDocumentDate, &BeginOfPeriod) < &BeginOfPeriod)
	|	AND NOT (SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
	|			AND SourceDatabase.Count < 0
	|			AND ISNULL(PartyRegister.IBDocumentDate, &BeginOfPeriod) < &BeginOfPeriod)
	// For the batch moved to the branch, we additionally check the compliance of the batch and expense analytics.
	|	AND NOT (SourceDatabase.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.InternalWorkReceipt),
	|			VALUE(Enum.BusinessTransactions.InternalGoodsReceipt))
	|		AND SourceDatabase.Lot <> UNDEFINED
	|		AND SourceDatabase.Lot <> Filter.SourceDocument_
	// We exclude the original documents Recorders of Registered Records from the check. These may be documents for the movement of goods.
	|		AND SourceDatabase.Recorder <> Filter.SourceDocument_
	|	)
	// In the case of a medium-slip sample of Registered Records from the accounting section "Unfactated deliveries" is performed by a separate request,
	// because Registered Records of delivery invoices are generated for the document "Cost Calculation Registrar".
	|	AND NOT (SourceDatabase.Organization IN (&MediumSlipOrganizations)
	|		AND SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
	|
	|GROUP BY
	|	SourceDatabase.Recorder,
	|	Filter.SourceDocument_,
	|	CASE
	|		WHEN SourceDatabase.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
	|			THEN FALSE
	|		WHEN NOT PartyRegister.IBDocumentDate IS NULL AND PartyRegister.IBDocumentDate < &BeginOfPeriod
	|			THEN TRUE
	|		ELSE FALSE
	|	END, // ThisIsPartyOfPastPeriod
	|	CASE
	|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|			AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		THEN TRUE ELSE FALSE
	|	END,
	|	SourceDatabase.Organization,
	|	SourceDatabase.AccountingSection,
	|	SourceDatabase.CorAccountingSection,
	|	SourceDatabase.ItemsLocationAttributes,
	|	SourceDatabase.CorItemsLocationAttributes,
	|	SourceDatabase.InventoryOwnerAttribute,
	|	SourceDatabase.CorInventoryOwnerAttribute,
	|	SourceDatabase.Lot,
	|	SourceDatabase.CorLot,
	|	SourceDatabase.LotVendorAttributes,
	|	SourceDatabase.LotVendorAttributesCorr,
	|	SourceDatabase.FinancialAccountingDimension,
	|	(CASE
	|		WHEN SourceDatabase.Organization IN (&MediumSlipOrganizations)
	|			THEN SourceDatabase.DocumentVATActivityType
	|		ELSE SourceDatabase.VATActivityType END) // VATActivityType
	|
	|UNION ALL
	|
	// The base of distribution according to invoices of deliveries at the average sliding (current month).
	|SELECT
	|	""TUEOfCostPriceMovementAccordingToDocuments_3"" AS RequestSource,
	|	SourceDatabase.Recorder,
	|	Filter.SourceDocument_ AS SourceDocument_,
	|	CASE WHEN NOT PartyRegister.IBDocumentDate IS NULL AND PartyRegister.IBDocumentDate < &BeginOfPeriod
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsPartyOfPastPeriod,
	|	CASE WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|	  AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS UseCorPart,
	|	SourceDatabase.Organization,
	|	SourceDatabase.AccountingSection,
	|	SourceDatabase.CorAccountingSection,
	|	SourceDatabase.ItemsLocationAttributes,
	|	SourceDatabase.CorItemsLocationAttributes,
	|	SourceDatabase.InventoryOwnerAttribute,
	|	SourceDatabase.CorInventoryOwnerAttribute,
	|	SourceDatabase.Lot,
	|	SourceDatabase.CorLot,
	|	SourceDatabase.LotVendorAttributes,
	|	SourceDatabase.LotVendorAttributesCorr,
	|	SourceDatabase.FinancialAccountingDimension,
	|	SourceDatabase.DocumentVATActivityType AS VATActivityType,
	|	MAX(CASE WHEN SourceDatabase.RowID <> """"
	|		THEN SourceDatabase.RowID
	|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
	|	SUM(SourceDatabase.Count) AS Count,
	|	SUM(SourceDatabase.Cost + SourceDatabase.AddExpensesForGoods) AS Cost,
	|	SUM(SourceDatabase.CostExcludingVAT + SourceDatabase.AdditionalExpensesExcludingVAT) AS CostExcludingVAT,
	|	SUM(SourceDatabase.LocalCost + SourceDatabase.AddExpensesLocal) AS LocalCost,
	|	SUM(SourceDatabase.CostMan + SourceDatabase.AddExpensesMan) AS CostMan,
	|	SUM(SourceDatabase.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
	|	SUM(SourceDatabase.LocalCost + SourceDatabase.AddExpensesLocal - SourceDatabase.PermanentDifference - SourceDatabase.CostTD) AS CostInTaxAccounting,
	|	
	|	MIN(BEGINOFPERIOD(CASE
	|		WHEN DocumentRegistry.IBDocumentDate IS NULL OR DocumentRegistry.IBDocumentDate < &DateOfMigrationToBatchAccounting22
	|		THEN &DateOfMigrationToBatchAccounting22
	|		ELSE DocumentRegistry.IBDocumentDate
	|	END, MONTH)) AS ReceiptPeriod
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS SourceDatabase
	|	INNER JOIN TUEOfCommunicationOfDocumentsOfCostAnalysis AS Filter
	|		ON SourceDatabase.CorLot = Filter.Ref
	// The condition for connecting to the document registry for batches must match the condition in the Template text functionThe primary document acceptor_4
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS PartyRegister
	|		ON PartyRegister.Ref = SourceDatabase.Lot
	|		AND NOT PartyRegister.AdditionalRecord
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentRegistry
	|		ON DocumentRegistry.Ref = SourceDatabase.Lot
	|			AND NOT DocumentRegistry.AdditionalRecord
	|WHERE
	|	SourceDatabase.OfficialTypeOfMovementParish
	|	AND SourceDatabase.Count <> 0
	// The data selection criteria must match the Template text's request for the Primary document acceptor_4.
	|	AND SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|	AND SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|	AND VALUETYPE(SourceDatabase.Recorder) = TYPE(Document.CostCalculationRecorder)
	|	AND SourceDatabase.Organization IN (&MediumSlipOrganizations)
	
	// Additional costs should not be allocated to services.
	// Services can be in the accounting section "Unfactured deliveries".
	|	AND SourceDatabase.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.OperationService)
	// Additional expenses should not be allocated to the work in the "Unfactured deliveries" section
	// if the work is written off as expenses.
	|	AND NOT (SourceDatabase.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND SourceDatabase.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef))
	|
	|GROUP BY
	|	SourceDatabase.Recorder,
	|	Filter.SourceDocument_,
	|	CASE WHEN NOT PartyRegister.IBDocumentDate IS NULL AND PartyRegister.IBDocumentDate < &BeginOfPeriod
	|		THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|			AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		THEN TRUE ELSE FALSE
	|	END,
	|	SourceDatabase.Organization,
	|	SourceDatabase.AccountingSection,
	|	SourceDatabase.CorAccountingSection,
	|	SourceDatabase.ItemsLocationAttributes,
	|	SourceDatabase.CorItemsLocationAttributes,
	|	SourceDatabase.InventoryOwnerAttribute,
	|	SourceDatabase.CorInventoryOwnerAttribute,
	|	SourceDatabase.Lot,
	|	SourceDatabase.CorLot,
	|	SourceDatabase.LotVendorAttributes,
	|	SourceDatabase.LotVendorAttributesCorr,
	|	SourceDatabase.FinancialAccountingDimension,
	|	SourceDatabase.DocumentVATActivityType
	|
	|UNION ALL
	|
	// The base of distribution according to invoices of deliveries at the average sliding (last month).
	|SELECT
	|	""TUEOfCostPriceMovementAccordingToDocuments_4"" AS RequestSource,
	|	SourceDatabase.Recorder,
	|	Filter.SourceDocument_ AS SourceDocument_,
	|	TRUE AS ThisIsPartyOfPastPeriod,
	|	CASE WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|	  AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS UseCorPart,
	|	SourceDatabase.Organization,
	|	SourceDatabase.AccountingSection,
	|	SourceDatabase.CorAccountingSection,
	|	SourceDatabase.ItemsLocationAttributes,
	|	SourceDatabase.CorItemsLocationAttributes,
	|	SourceDatabase.InventoryOwnerAttribute,
	|	SourceDatabase.CorInventoryOwnerAttribute,
	|	SourceDatabase.Lot,
	|	SourceDatabase.CorLot,
	|	SourceDatabase.LotVendorAttributes,
	|	SourceDatabase.LotVendorAttributesCorr,
	|	SourceDatabase.FinancialAccountingDimension,
	|	SourceDatabase.DocumentVATActivityType AS VATActivityType,
	|	MAX(CASE WHEN SourceDatabase.RowID <> """"
	|		THEN SourceDatabase.RowID
	|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
	|	SUM(SourceDatabase.Count) AS Count,
	|	SUM(SourceDatabase.Cost + SourceDatabase.AddExpensesForGoods) AS Cost,
	|	SUM(SourceDatabase.CostExcludingVAT + SourceDatabase.AdditionalExpensesExcludingVAT) AS CostExcludingVAT,
	|	SUM(SourceDatabase.LocalCost + SourceDatabase.AddExpensesLocal) AS LocalCost,
	|	SUM(SourceDatabase.CostMan + SourceDatabase.AddExpensesMan) AS CostMan,
	|	SUM(SourceDatabase.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
	|	SUM(SourceDatabase.LocalCost + SourceDatabase.AddExpensesLocal - SourceDatabase.PermanentDifference - SourceDatabase.CostTD) AS CostInTaxAccounting,
	|	
	|	MIN(BEGINOFPERIOD(CASE
	|		WHEN DocumentRegistry.IBDocumentDate IS NULL OR DocumentRegistry.IBDocumentDate < &DateOfMigrationToBatchAccounting22
	|		THEN &DateOfMigrationToBatchAccounting22
	|		ELSE DocumentRegistry.IBDocumentDate
	|	END, MONTH)) AS ReceiptPeriod
	|FROM
	|	AccumulationRegister.InventoryCost AS SourceDatabase
	|	INNER JOIN TUEOfCommunicationOfDocumentsOfCostAnalysis AS Filter
	|		ON SourceDatabase.CorLot = Filter.Ref
	// The condition for connecting to the document registry for batches must match the condition in the Template text functionThe primary document acceptor_3
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS PartyRegister
	|		ON PartyRegister.Ref = SourceDatabase.Lot
	|		AND NOT PartyRegister.AdditionalRecord
	// The condition for connecting to the document registry for batches must match the condition in the textreceiver function of the past periodsadditional expenses
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentRegistry
	|		ON DocumentRegistry.Ref = CASE
	|				WHEN SourceDatabase.Lot <> UNDEFINED THEN SourceDatabase.Lot
	|				WHEN SourceDatabase.DocumentSource <> UNDEFINED THEN SourceDatabase.DocumentSource
	|				WHEN SourceDatabase.DimensionOfExpenses <> UNDEFINED THEN SourceDatabase.DimensionOfExpenses
	|				ELSE Filter.Ref END
	|			AND NOT DocumentRegistry.AdditionalRecord
	|WHERE
	|	SourceDatabase.Organization IN (&MediumSlipOrganizations)
	|	AND SourceDatabase.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND SourceDatabase.Period < &BeginOfPeriod
	|	AND SourceDatabase.Count <> 0
	|	AND SourceDatabase.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|	AND VALUETYPE(SourceDatabase.Recorder) = TYPE(Document.CostCalculationRecorder)
	
	// Additional costs should not be allocated to services.
	// Services can be in the accounting section "Unfactured deliveries".
	|	AND SourceDatabase.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.OperationService)
	// Additional expenses should not be allocated to the work in the "Unfactured deliveries" section
	// if the work is written off as expenses.
	|	AND NOT (SourceDatabase.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND SourceDatabase.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef))
	|
	|GROUP BY
	|	SourceDatabase.Recorder,
	|	Filter.SourceDocument_,
	|	CASE WHEN NOT PartyRegister.IBDocumentDate IS NULL AND PartyRegister.IBDocumentDate < &BeginOfPeriod
	|		THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|			AND SourceDatabase.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		THEN TRUE ELSE FALSE
	|	END,
	|	SourceDatabase.Organization,
	|	SourceDatabase.AccountingSection,
	|	SourceDatabase.CorAccountingSection,
	|	SourceDatabase.ItemsLocationAttributes,
	|	SourceDatabase.CorItemsLocationAttributes,
	|	SourceDatabase.InventoryOwnerAttribute,
	|	SourceDatabase.CorInventoryOwnerAttribute,
	|	SourceDatabase.Lot,
	|	SourceDatabase.CorLot,
	|	SourceDatabase.LotVendorAttributes,
	|	SourceDatabase.LotVendorAttributesCorr,
	|	SourceDatabase.FinancialAccountingDimension,
	|	SourceDatabase.DocumentVATActivityType
	|
	|INDEX BY
	|	SourceDocument_
	|";
	
	Return QueryText;
	
EndFunction

Function AdditionalTablesForReceiversForOtherExpenses()
	
	QueryText = 
	"SELECT
	|	SourceDatabase.AccountingSection                   AS AccountingSection,
	|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
	|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	SourceDatabase.Organization                   AS Organization,
	|	SourceDatabase.Lot                        AS Lot,
	|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
	|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
	|	SourceDatabase.VATActivityType            AS VATActivityType,
	|	MAX(SourceDatabase.FinRecordID) AS FinRecordID,
	|	SUM(SourceDatabase.Count)             AS Count,
	|	SUM(SourceDatabase.Cost)              AS Cost,
	|	SUM(SourceDatabase.CostExcludingVAT)        AS CostExcludingVAT,
	|	SUM(SourceDatabase.LocalCost)          AS LocalCost,
	|	SUM(SourceDatabase.CostMan)           AS CostMan,
	|	SUM(SourceDatabase.CostOfPersonalIncomeTax)           AS CostOfPersonalIncomeTax,
	|	SUM(SourceDatabase.CostInTaxAccounting)            AS CostInTaxAccounting
	|
	|INTO TUEOfMovementOfCostOfOtherExpenses
	|FROM
	|(SELECT
	|	SourceDatabase.AccountingSection                   AS AccountingSection,
	|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
	|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	SourceDatabase.Organization                   AS Organization,
	|	SourceDatabase.Lot                        AS Lot,
	|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
	|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
	|	SourceDatabase.VATActivityType            AS VATActivityType,
	|	(CASE WHEN SourceDatabase.RowID <> """"
	|		THEN SourceDatabase.RowID
	|		ELSE SourceDatabase.FinRecordID END) AS FinRecordID,
	|	SourceDatabase.Count                    AS Count,
	|	SourceDatabase.Cost                     AS Cost,
	|	SourceDatabase.CostExcludingVAT               AS CostExcludingVAT,
	|	SourceDatabase.LocalCost                 AS LocalCost,
	|	SourceDatabase.CostMan                  AS CostMan,
	|	SourceDatabase.CostOfPersonalIncomeTax                  AS CostOfPersonalIncomeTax,
	|	SourceDatabase.LocalCost                 AS CostInTaxAccounting
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS SourceDatabase
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfSelection
	|		ON SourceDatabase.ItemsLocationAttributes = DimensionOfSelection.Ref
	|	LEFT JOIN Catalog.Warehouses AS WarehouseDetails
	|		ON DimensionOfSelection.StorageLocation = WarehouseDetails.Ref
	|WHERE
	|	SourceDatabase.OfficialTypeOfMovementParish
	|	AND SourceDatabase.Count <> 0
	|	AND (SourceDatabase.EntryType IN (
	|		VALUE(Enum.LotRecordTypes.Lot),
	|		VALUE(Enum.LotRecordTypes.PurchaseAdjustment),
	|		VALUE(Enum.LotRecordTypes.CostAdjustment),
	|		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
	|		)
	|	AND NOT VALUETYPE(SourceDatabase.Recorder) = TYPE(Document.InventoryTransfer)
	|	AND NOT VALUETYPE(SourceDatabase.Recorder) = TYPE(Document.AssemblyFromComponents)
	|	AND NOT VALUETYPE(SourceDatabase.Recorder) = TYPE(Document.CustomerInvoiceIntercompany)
	|	AND (SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		OR SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		OR SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		AND (DimensionOfSelection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			OR ISNULL(WarehouseDetails.ShopFloorStockroom, FALSE)
	|			OR VALUETYPE(SourceDatabase.Recorder) = TYPE(Document.ProductionStage2_2)
	|			OR VALUETYPE(SourceDatabase.Recorder) = TYPE(Document.BackflushProduction)
	|			))
	|	AND NOT (SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|			AND DimensionOfSelection.StorageType = VALUE(Enum.StorageLocationTypes.Partner))
	|
	|UNION ALL
	|
	|SELECT
	|	SourceDatabase.AccountingSection                   AS AccountingSection,
	|	SourceDatabase.ItemsLocationAttributes    AS ItemsLocationAttributes,
	|	SourceDatabase.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	SourceDatabase.Organization                   AS Organization,
	|	SourceDatabase.Lot                        AS Lot,
	|	SourceDatabase.LotVendorAttributes          AS LotVendorAttributes,
	|	SourceDatabase.FinancialAccountingDimension     AS FinancialAccountingDimension,
	|	SourceDatabase.VATActivityType            AS VATActivityType,
	|	""""                                       AS FinRecordID,
	|	SourceDatabase.CountBalance             AS Count,
	|	SourceDatabase.CostBalance              AS Cost,
	|	SourceDatabase.CostExcludingVATBalance        AS CostExcludingVAT,
	|	SourceDatabase.LocalCostBalance          AS LocalCost,
	|	SourceDatabase.CostManBalance           AS CostMan,
	|	SourceDatabase.CostOfPersonalIncomeTaxBalance           AS CostOfPersonalIncomeTax,
	|	SourceDatabase.LocalCostBalance          AS CostInTaxAccounting
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(&BorderStartOfPeriod,
	|		Organization IN (&CompanyArray) AND 
	|		(AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|			AND NOT ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|		OR AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			AND (VALUETYPE(ItemsLocationAttributes.StorageLocation) = TYPE(Catalog.Warehouses)
	|				OR ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)))) AS SourceDatabase
	|WHERE
	|	SourceDatabase.CountBalance <> 0
	|) AS SourceDatabase
	|
	|GROUP BY
	|	SourceDatabase.AccountingSection,
	|	SourceDatabase.ItemsLocationAttributes,
	|	SourceDatabase.InventoryOwnerAttribute,
	|	SourceDatabase.Organization,
	|	SourceDatabase.Lot,
	|	SourceDatabase.LotVendorAttributes,
	|	SourceDatabase.FinancialAccountingDimension,
	|	SourceDatabase.VATActivityType
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|";
	
	Return QueryText;
	
EndFunction

Function TextPrimaryReceiversOfAdditionalCosts(CalculationParameters)
	
	NameOfTemporaryObjectGroupTable = "GroupsOfAdditionalExpenseItems";
	GettingObjectText = 
		"SELECT
		|	Recorders.Ref,
		|	Recorders.BaseOfAllocationByLots AS AllocationBaseType,
		|	Recorders.SettingsOfBaseOfAllocationByLots AS SchemaSettings,
		|	VALUETYPE(Recorders.DimensionOfExpenses) AS TypeOfExpenseAnalytics
		|FROM
		|	Recorders AS Recorders";

	DescriptionOfGroups = GetDescriptionOfObjectGroupsBySelectionSettings(GettingObjectText, CalculationParameters, NameOfTemporaryObjectGroupTable);
	
	ReadyQueryTexts = New Array;
	ReadyQueryTexts.Add(TextForPlacingGroupOfObjectsInTemporaryTable(NameOfTemporaryObjectGroupTable));
	TextDescriptionOfData =
		"SELECT TOP 0
		|	""TextDescriptionOfDataForAllocationOfAdditionalCosts"" AS RequestSource,
		|	DD.Recorder                   AS Recorder,
		|	FALSE                             AS ThisIsPartyOfPastPeriod,
		|	DD.AccountingSection                   AS AccountingSection,
		|	DD.ItemsLocationAttributes    AS ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
		|	DD.Organization                   AS Organization,
		|	DD.Lot                        AS Lot,
		|	DD.LotVendorAttributes          AS LotVendorAttributes,
		|	DD.FinancialAccountingDimension     AS FinancialAccountingDimension,
		|	DD.VATActivityType            AS VATActivityType,
		|	DD.FinRecordID        AS FinRecordID,
		|	0                                AS Count,
		|	0                                AS Cost,
		|	0                                AS CostExcludingVAT,
		|	0                                AS LocalCost,
		|	0                                AS CostMan,
		|	0                                AS CostOfPersonalIncomeTax,
		|	0                                AS CostInTaxAccounting,
		|	
		|	DATETIME(1,1,1) AS ReceiptPeriod
		|INTO DataDetails
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|WHERE
		|	FALSE";
	ReadyQueryTexts.Add(TextDescriptionOfData);
	AddTextsDescribingGroups(ReadyQueryTexts, DescriptionOfGroups, NameOfTemporaryObjectGroupTable);
	
	// Let's combine all the tables of data(x) in groups by the number of tables in the query into intermediate tables of primary receivers(y)
	// Then combine all the primary receivers (y) into the final Primary receivers table and delete all the data tables (x) and primary receivers(y)
	ArrayDeletition = New Array;
	ArrayOfSources = New Array;
	ArrayOfSources.Add("DataDetails");
	
	For Each GroupDetails In DescriptionOfGroups Do
		If Not GroupDetails.Used Then
			Continue
		EndIf;
		ArrayOfSources.Add(StrTemplate("DataTable%1", Format(GroupDetails.NumberOfGroup, "NZ=0; NG=0")));
	EndDo;
	
	SourceCounter 		 = -1;
	NumberOfTablesInQuery = 254;
	NumberOfRequests_ 		 = ArrayOfSources.Count() / NumberOfTablesInQuery;
	NumberOfRequests_ 		 = Int(NumberOfRequests_) + ?(NumberOfRequests_ = Int(NumberOfRequests_), 0, 1);
	
	QueryTextTemplate2 = 
	"SELECT
	|	T.RequestSource,
	|	T.Recorder,
	|	T.ThisIsPartyOfPastPeriod,
	|	T.AccountingSection,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Organization,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.FinancialAccountingDimension,
	|	T.VATActivityType,
	|	T.FinRecordID,
	|	T.Count,
	|	T.Cost,
	|	T.CostExcludingVAT,
	|	T.LocalCost,
	|	T.CostMan,
	|	T.CostOfPersonalIncomeTax,
	|	T.CostInTaxAccounting,
	|	
	|	T.ReceiptPeriod AS ReceiptPeriod
	|INTO PrimaryReceiversEx
	|FROM
	|	DataDetails AS T";
	
	For QueryNumber = 1 To NumberOfRequests_ Do
		
		If QueryNumber = 1 And NumberOfRequests_ = 1 Then
			IntermediateTableName = "PrimaryReceiversEx";
		Else
			IntermediateTableName = "PrimaryReceivers" + Format(QueryNumber, "NZ=0; NG=0");
			ArrayDeletition.Add(IntermediateTableName);
		EndIf;
		
		ArrayOfSubqueriesTexts = New Array;
		
		For TableNumber = 1 To NumberOfTablesInQuery Do
			
			SourceCounter = SourceCounter + 1;
			If SourceCounter > ArrayOfSources.Count() - 1 Then
				Break;
			EndIf;
			
			If TableNumber = 1 Then
				TextOfCurrentRequest = StrReplace(QueryTextTemplate2, "PrimaryReceiversEx", IntermediateTableName);
			Else
				TextOfCurrentRequest = StrReplace(QueryTextTemplate2, "INTO PrimaryReceiversEx", "");
			EndIf;
			
			TextOfCurrentRequest = StrReplace(TextOfCurrentRequest, "DataDetails", ArrayOfSources[SourceCounter]);
			
			ArrayOfSubqueriesTexts.Add(TextOfCurrentRequest);
			ArrayDeletition.Add(ArrayOfSources[SourceCounter]);
			
		EndDo;
		
		ReadyQueryTexts.Add(MergeTexts(ArrayOfSubqueriesTexts)); // Data tables(x) + Data tables(x+1) + ... -> Primary receivers(y)
		
	EndDo;
	
	If NumberOfRequests_ > 1 Then
		
		ArrayOfSubqueriesTexts = New Array;
		
		For QueryNumber = 1 To NumberOfRequests_ Do
			
			IntermediateTableName = "PrimaryReceiversEx" + Format(QueryNumber, "NZ=0; NG=0");
			
			If QueryNumber = 1 Then
				TextOfCurrentRequest = QueryTextTemplate2;
			Else
				TextOfCurrentRequest = StrReplace(QueryTextTemplate2, "INTO PrimaryReceiversEx", "");
			EndIf;
			
			TextOfCurrentRequest = StrReplace(TextOfCurrentRequest, "DataDetails", IntermediateTableName);
			
			ArrayOfSubqueriesTexts.Add(TextOfCurrentRequest);
			
		EndDo;
		
		ReadyQueryTexts.Add(MergeTexts(ArrayOfSubqueriesTexts)); // Primary receivers(x) + Primary receivers(x+1) + ... -> Primary receivers
		
	EndIf;
	
	For Each TableName In ArrayDeletition Do
		ReadyQueryTexts.Add("DROP" + " " + TableName);
	EndDo;
	
	TextPrimaryReceivers = 
		"SELECT
		|	T.Recorder AS Recorder,
		|	T.ThisIsPartyOfPastPeriod AS ThisIsPartyOfPastPeriod,
		|	T.AccountingSection AS AccountingSection,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Organization AS Organization,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|	MAX(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Count) AS Count,
		|	SUM(T.Cost) AS Cost,
		|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(T.LocalCost) AS LocalCost,
		|	SUM(T.CostMan) AS CostMan,
		|	SUM(T.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|	SUM(T.CostInTaxAccounting) AS CostInTaxAccounting,
		|	
		|	MIN(T.ReceiptPeriod) AS ReceiptPeriod
		|INTO PrimaryReceivers
		|FROM
		|	PrimaryReceiversEx AS T
		|
		|GROUP BY
		|	T.Recorder,
		|	T.ThisIsPartyOfPastPeriod,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	AccountingSection,
		|	InventoryOwnerAttribute,
		|	Organization,
		|	Lot,
		|	LotVendorAttributes,
		|	FinancialAccountingDimension,
		|	VATActivityType";
	
	ReadyQueryTexts.Add(TextPrimaryReceivers);
	
	Return MergeTexts(ReadyQueryTexts, Common.QueryBatchSeparator());
	
EndFunction

Function TextAnalyticsWithoutCost()
	
	QueryText = "
	|SELECT DISTINCT
	|	Source.ItemsLocationAttributes,
	|	Source.AccountingSection,
	|	Source.InventoryOwnerAttribute,
	|	Source.Organization,
	|	Source.Lot,
	|	Source.LotVendorAttributes,
	|	Source.FinancialAccountingDimension,
	|	Source.VATActivityType
	|
	|INTO AnalyticsWithoutCost
	|FROM
	|	PrimaryReceivers AS Source
	|WHERE
	|	&DecodingDistribution
	|	AND NOT Source.ThisIsPartyOfPastPeriod
	|	AND (Source.Cost = 0
	|		OR Source.CostExcludingVAT = 0
	|		OR Source.LocalCost = 0
	|		OR Source.CostMan = 0)
	|";
	
	Return QueryText;
	
EndFunction

Function TextCalculatedCostOfLotReferencesOfGoods()
	
	QueryText = "
	|SELECT
	|	Cost_.ItemsLocationAttributes,
	|	Cost_.AccountingSection,
	|	Cost_.InventoryOwnerAttribute,
	|	Cost_.Organization,
	|	Cost_.Lot,
	|	Cost_.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType,
	|	SUM(Cost_.Count) AS Count,
	|	SUM(Cost_.Cost) AS Cost,
	|	SUM(Cost_.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(Cost_.LocalCost) AS LocalCost,
	|	SUM(Cost_.CostMan) AS CostMan,
	|	SUM(Cost_.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax
	|
	|INTO CalculatedCostOfLotReferenceGoods
	|FROM
	|	AccumulationRegister.InventoryCost AS Cost_
	|WHERE
	|	&DecodingDistribution
	|	AND Cost_.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Cost_.Active
	|	AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|	AND (Organization, ItemsLocationAttributes, InventoryOwnerAttribute, AccountingSection, 
	|			Lot, LotVendorAttributes, FinancialAccountingDimension, VATActivityType) IN
	|		(SELECT
	|			Analysts.Organization,
	|			Analysts.ItemsLocationAttributes,
	|			Analysts.InventoryOwnerAttribute,
	|			Analysts.AccountingSection,
	|			Analysts.Lot,
	|			Analysts.LotVendorAttributes,
	|			Analysts.FinancialAccountingDimension,
	|			Analysts.VATActivityType
	|		FROM
	|			AnalyticsWithoutCost AS Analysts
	|		)
	|GROUP BY
	|	Cost_.ItemsLocationAttributes,
	|	Cost_.AccountingSection,
	|	Cost_.InventoryOwnerAttribute,
	|	Cost_.Organization,
	|	Cost_.Lot,
	|	Cost_.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType
	|";
	
	Return QueryText;
	
EndFunction

Function TextPrimaryReceiversWithCost() // TT Primary receptionreferences
	
	QueryText = "
	|SELECT
	|	Source.Recorder,
	|	Source.ThisIsPartyOfPastPeriod,
	|	Source.ItemsLocationAttributes,
	|	Source.AccountingSection,
	|	Source.InventoryOwnerAttribute,
	|	Source.Organization,
	|	Source.Lot,
	|	Source.LotVendorAttributes,
	|	Source.FinancialAccountingDimension,
	|	Source.VATActivityType,
	|	Source.FinRecordID,
	|	Source.ReceiptPeriod,
	|	Source.Count AS Count,
	|	(CASE 
	|		WHEN Source.Cost <> 0 THEN Source.Cost
	|		WHEN ISNULL(CostOfLotReferences.Cost, 0) <> 0
	|			THEN Source.Count * (CostOfLotReferences.Cost / CostOfLotReferences.Count)
	|		ELSE Source.Count * ISNULL(Prices.Cost, 0) END) AS Cost,
	|	(CASE 
	|		WHEN Source.CostExcludingVAT <> 0 THEN Source.CostExcludingVAT
	|		WHEN ISNULL(CostOfLotReferences.CostExcludingVAT, 0) <> 0
	|			THEN Source.Count * (CostOfLotReferences.CostExcludingVAT / CostOfLotReferences.Count)
	|		ELSE Source.Count * ISNULL(Prices.CostExcludingVAT, 0) END) AS CostExcludingVAT,
	|	(CASE 
	|		WHEN Source.LocalCost <> 0 THEN Source.LocalCost
	|		WHEN ISNULL(CostOfLotReferences.LocalCost, 0) <> 0
	|			THEN Source.Count * (CostOfLotReferences.LocalCost / CostOfLotReferences.Count)
	|		ELSE Source.Count * ISNULL(Prices.LocalCost, 0) END) AS LocalCost,
	|	(CASE 
	|		WHEN Source.CostMan <> 0 THEN Source.CostMan
	|		WHEN ISNULL(CostOfLotReferences.CostMan, 0) <> 0
	|			THEN Source.Count * (CostOfLotReferences.CostMan / CostOfLotReferences.Count)
	|		ELSE Source.Count * ISNULL(Prices.CostMan, 0) END) AS CostMan,
	|	(CASE 
	|		WHEN Source.CostOfPersonalIncomeTax <> 0 THEN Source.CostOfPersonalIncomeTax
	|		WHEN ISNULL(CostOfLotReferences.CostOfPersonalIncomeTax, 0) <> 0
	|			THEN Source.Count * (CostOfLotReferences.CostOfPersonalIncomeTax / CostOfLotReferences.Count)
	|		ELSE Source.Count * ISNULL(Prices.CostOfPersonalIncomeTax, 0) END) AS CostOfPersonalIncomeTax,
	|	(CASE 
	|		WHEN Source.CostInTaxAccounting <> 0 THEN Source.CostInTaxAccounting
	|		WHEN ISNULL(CostOfLotReferences.LocalCost, 0) <> 0
	|			THEN Source.Count * (CostOfLotReferences.LocalCost / CostOfLotReferences.Count)
	|		ELSE Source.Count * ISNULL(Prices.LocalCost, 0) END) AS CostInTaxAccounting
	|
	|INTO PrimaryReceiversWithCost
	|FROM
	|	PrimaryReceivers AS Source
	|
	|	LEFT JOIN TTValueOfBatchesOfGoods AS Prices
	|	ON Prices.Organization = Source.Organization
	|		AND Prices.Period = BEGINOFPERIOD(&BeginOfPeriod, MONTH)
	|		AND Prices.ItemsLocationAttributes = Source.ItemsLocationAttributes
	|		AND Prices.InventoryOwnerAttribute = Source.InventoryOwnerAttribute
	|		AND Prices.AccountingSection = Source.AccountingSection
	|		AND Prices.Lot = Source.Lot
	|		AND Prices.LotVendorAttributes = Source.LotVendorAttributes
	|		AND Prices.FinancialAccountingDimension = Source.FinancialAccountingDimension
	|		AND Prices.VATActivityType = Source.VATActivityType
	|
	|
	|	LEFT JOIN CalculatedCostOfLotReferenceGoods AS CostOfLotReferences
	|	ON CostOfLotReferences.Organization = Source.Organization
	|		AND CostOfLotReferences.ItemsLocationAttributes = Source.ItemsLocationAttributes
	|		AND CostOfLotReferences.InventoryOwnerAttribute = Source.InventoryOwnerAttribute
	|		AND CostOfLotReferences.AccountingSection = Source.AccountingSection
	|		AND CostOfLotReferences.Lot = Source.Lot
	|		AND CostOfLotReferences.LotVendorAttributes = Source.LotVendorAttributes
	|		AND CostOfLotReferences.FinancialAccountingDimension = Source.FinancialAccountingDimension
	|		AND CostOfLotReferences.VATActivityType = Source.VATActivityType
	|		AND CostOfLotReferences.Count <> 0
	|";
	
	Return QueryText;
	
EndFunction

Function TextCoefficientsOfReductionOfBaseOfDistributionOfAdditionalExpenses()
	
	QueryText = 
		"SELECT
		|	DD.Recorder,
		// To correctly calculate the price, the total amount of the distribution base should not exceed 1,000
		// , the calculation is performed as follows: when distributing 100 rubles, the price must contain all decimal places.
		|	CASE
		|		WHEN SUM(DD.Cost) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.Cost) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.Cost) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.Cost) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.Cost) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.Cost) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS ZoomRatio,
		|	CASE
		|		WHEN SUM(DD.CostExcludingVAT) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.CostExcludingVAT) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.CostExcludingVAT) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.CostExcludingVAT) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.CostExcludingVAT) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.CostExcludingVAT) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS CoefficientWithoutVAT,
		|	CASE
		|		WHEN SUM(DD.LocalCost) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.LocalCost) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.LocalCost) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.LocalCost) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.LocalCost) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.LocalCost) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS LocalCoefficient,
		|	CASE
		|		WHEN SUM(DD.CostMan) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.CostMan) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.CostMan) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.CostMan) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.CostMan) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.CostMan) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS ManSCoefficient,
		|	CASE
		|		WHEN SUM(DD.CostInTaxAccounting) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.CostInTaxAccounting) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.CostInTaxAccounting) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.CostInTaxAccounting) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.CostInTaxAccounting) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.CostInTaxAccounting) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS CoefficientIsTA,
		|	CASE
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS NDTCoefficient
		|INTO CoefficientsOfReductionOfDistributionBase
		|FROM
		|	PrimaryReceiversWithCost AS DD
		|WHERE
		|	NOT &DecodingDistribution
		|
		|GROUP BY
		|	DD.Recorder
		|";

	Return QueryText;
		
EndFunction

Function TextPrimaryReceiversGiven()
	
	QueryText = "
	|SELECT
	|	Source.Recorder,
	|	Source.ThisIsPartyOfPastPeriod,
	|	Source.ItemsLocationAttributes,
	|	Source.AccountingSection,
	|	Source.InventoryOwnerAttribute,
	|	Source.Organization,
	|	Source.Lot,
	|	Source.LotVendorAttributes,
	|	Source.FinancialAccountingDimension,
	|	Source.VATActivityType,
	|	Source.FinRecordID,
	|	Source.ReceiptPeriod,
	|	Source.Count AS Count,
	|	CAST(Source.Cost / ISNULL(ReductionCoefficients.ZoomRatio, 1) AS NUMBER (23,10)) AS Cost,
	|	CAST(Source.CostExcludingVAT / ISNULL(ReductionCoefficients.CoefficientWithoutVAT, 1) AS NUMBER (23,10)) AS CostExcludingVAT,
	|	CAST(Source.LocalCost / ISNULL(ReductionCoefficients.LocalCoefficient, 1) AS NUMBER (23,10)) AS LocalCost,
	|	CAST(Source.CostMan / ISNULL(ReductionCoefficients.ManSCoefficient, 1) AS NUMBER (23,10)) AS CostMan,
	|	CAST(Source.CostOfPersonalIncomeTax / ISNULL(ReductionCoefficients.NDTCoefficient, 1) AS NUMBER (23,10)) AS CostOfPersonalIncomeTax,
	|	CAST(Source.CostInTaxAccounting / ISNULL(ReductionCoefficients.CoefficientIsTA, 1) AS NUMBER (23,10)) AS CostInTaxAccounting
	|
	|INTO PrimaryReceiversOfReduced
	|FROM
	|	PrimaryReceiversWithCost AS Source
	|	LEFT JOIN CoefficientsOfReductionOfDistributionBase AS ReductionCoefficients
	|		ON Source.Recorder = ReductionCoefficients.Recorder
	|";
	
	Return QueryText;
	
EndFunction

Function AdjustmentOfReceiversByRegistrars()
	
	QueryText =
		"SELECT
		|	T.Recorder,
		|	T.ThisIsPartyOfPastPeriod,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	MAX(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Count) AS Count,
		|	SUM(T.Cost) AS Cost,
		|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(T.LocalCost) AS LocalCost,
		|	SUM(T.CostMan) AS CostMan,
		|	SUM(T.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|	SUM(T.CostInTaxAccounting) AS CostInTaxAccounting,
		|	
		|	MIN(T.ReceiptPeriod) AS ReceiptPeriod
		|
		|INTO ProductReceivers
		|FROM
		|	(SELECT
		|		Source.Recorder,
		|		Source.ThisIsPartyOfPastPeriod,
		|		Source.ItemsLocationAttributes,
		|		Source.AccountingSection,
		|		Source.InventoryOwnerAttribute,
		|		Source.Organization,
		|		Source.Lot,
		|		Source.LotVendorAttributes,
		|		Source.FinancialAccountingDimension,
		|		Source.VATActivityType,
		|		Source.FinRecordID,
		|		Source.Count AS Count,
		|		Source.Cost AS Cost,
		|		Source.CostExcludingVAT AS CostExcludingVAT,
		|		Source.LocalCost AS LocalCost,
		|		Source.CostMan AS CostMan,
		|		Source.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax,
		|		Source.CostInTaxAccounting AS CostInTaxAccounting,
		|		Source.ReceiptPeriod AS ReceiptPeriod
		|	FROM
		|		PrimaryReceiversOfReduced AS Source
		|	WHERE
		|		NOT Source.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		OR &AllocationOfAdditionalExpensesOnGoodsInTransitFromVendors
		|
		|	UNION ALL
		|
		|	SELECT
		|		Source.Recorder,
		|		(Data.Period < &BeginOfPeriod),
		|		Data.CorItemsLocationAttributes,
		|		Data.CorAccountingSection,
		|		Data.CorInventoryOwnerAttribute,
		|		CASE
		|			WHEN Data.CorCompany = VALUE(Catalog.Companies.EmptyRef)
		|				THEN Data.Organization
		|			ELSE
		|				Data.CorCompany
		|		END,
		|		Data.CorLot,
		|		Data.LotVendorAttributesCorr,
		|		Data.CorControllingAttributes,
		|		Data.CorVATActivityTypes,
		|		Data.FinRecordID,
		|		Data.Count,
		// Quantity coefficients are needed to reduce the base if the quantity in the receipt to the warehouse is less
		// than in the document of purchase of goods and services.
		|		CASE
		|			WHEN Source.Count = 0
		|				THEN 0
		|			ELSE Source.Cost * (Data.Count / Source.Count)
		|		END AS Cost,
		|		CASE
		|			WHEN Source.Count = 0
		|				THEN 0
		|			ELSE Source.Cost * (Data.Count / Source.Count)
		|		END AS CostExcludingVAT,
		|		CASE
		|			WHEN Source.Count = 0
		|				THEN 0
		|			ELSE Source.Cost * (Data.Count / Source.Count)
		|		END AS LocalCost,
		|		CASE
		|			WHEN Source.Count = 0
		|				THEN 0
		|			ELSE Source.Cost * (Data.Count / Source.Count)
		|		END AS CostMan,
		|		CASE
		|			WHEN Source.Count = 0
		|				THEN 0
		|			ELSE Source.Cost * (Data.Count / Source.Count)
		|		END AS CostOfPersonalIncomeTax,
		|		CASE
		|			WHEN Source.Count = 0
		|				THEN 0
		|			ELSE Source.Cost * (Data.Count / Source.Count)
		|		END AS CostInTaxAccounting,
		|		Source.ReceiptPeriod AS ReceiptPeriod
		|	FROM
		|		PrimaryReceiversOfReduced AS Source
		|			LEFT JOIN AccumulationRegister.InventoryCost AS Data
		|			ON Source.ItemsLocationAttributes = Data.ItemsLocationAttributes
		|				AND Source.AccountingSection = Data.AccountingSection
		|				AND Source.InventoryOwnerAttribute = Data.InventoryOwnerAttribute
		|				AND Source.Organization = Data.Organization
		|				AND Source.Lot = Data.Lot
		|				AND Source.LotVendorAttributes = Data.LotVendorAttributes
		|				AND Source.FinancialAccountingDimension = Data.FinancialAccountingDimension
		|				AND Source.VATActivityType = Data.VATActivityType
		|				AND Data.RecordType = VALUE(AccumulationRecordType.Expense)
		|				AND Data.Period < &BeginOfPeriod
		|	WHERE
		|		Source.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		AND NOT &AllocationOfAdditionalExpensesOnGoodsInTransitFromVendors
		|
		|	UNION ALL
		|
		|	SELECT
		|		Source.Recorder,
		|		(Data.Period < &BeginOfPeriod),
		|		Data.CorItemsLocationAttributes,
		|		Data.CorAccountingSection,
		|		Data.CorInventoryOwnerAttribute,
		|		CASE
		|			WHEN Data.CorCompany = VALUE(Catalog.Companies.EmptyRef)
		|				THEN Data.Organization
		|			ELSE
		|				Data.CorCompany
		|		END,
		|		Data.CorLot,
		|		Data.LotVendorAttributesCorr,
		|		Data.CorControllingAttributes,
		|		Data.CorVATActivityTypes,
		|		Data.FinRecordID,
		|		Data.Count,
		// Quantity coefficients are needed to reduce the base if the quantity in the receipt to the warehouse is less
		// than in the document of purchase of goods and services.
		|		CASE
		|			WHEN Source.Count = 0
		|				THEN 0
		|			ELSE Source.Cost * (Data.Count / Source.Count)
		|		END AS Cost,
		|		CASE
		|			WHEN Source.Count = 0
		|				THEN 0
		|			ELSE Source.Cost * (Data.Count / Source.Count)
		|		END AS CostExcludingVAT,
		|		CASE
		|			WHEN Source.Count = 0
		|				THEN 0
		|			ELSE Source.Cost * (Data.Count / Source.Count)
		|		END AS LocalCost,
		|		CASE
		|			WHEN Source.Count = 0
		|				THEN 0
		|			ELSE Source.Cost * (Data.Count / Source.Count)
		|		END AS CostMan,
		|		CASE
		|			WHEN Source.Count = 0
		|				THEN 0
		|			ELSE Source.Cost * (Data.Count / Source.Count)
		|		END AS CostOfPersonalIncomeTax,
		|		CASE
		|			WHEN Source.Count = 0
		|				THEN 0
		|			ELSE Source.Cost * (Data.Count / Source.Count)
		|		END AS CostInTaxAccounting,
		|		Source.ReceiptPeriod AS ReceiptPeriod
		|	FROM
		|		PrimaryReceiversOfReduced AS Source
		|			LEFT JOIN TTCashEstimatedTurnoverCostOfGoods AS Data
		|			ON Source.ItemsLocationAttributes = Data.ItemsLocationAttributes
		|				AND Source.AccountingSection = Data.AccountingSection
		|				AND Source.InventoryOwnerAttribute = Data.InventoryOwnerAttribute
		|				AND Source.Organization = Data.Organization
		|				AND Source.Lot = Data.Lot
		|				AND Source.LotVendorAttributes = Data.LotVendorAttributes
		|				AND Source.FinancialAccountingDimension = Data.FinancialAccountingDimension
		|				AND Source.VATActivityType = Data.VATActivityType
		|				AND NOT Data.OfficialTypeOfMovementParish
		|				AND Data.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|	WHERE
		|		Source.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		AND NOT &AllocationOfAdditionalExpensesOnGoodsInTransitFromVendors
		|	) AS T
		|
		|GROUP BY
		|	T.Recorder,
		|	T.ThisIsPartyOfPastPeriod,
		|	T.AccountingSection,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType
		|
		|INDEX BY
		|	Recorder";
	
	Return QueryText;

EndFunction

Function TextReceiversForGoodsOfPastPeriodsOfAdditionalExpenses()
	
	QueryText =
		"SELECT
		|	DD.Recorder,
		|	DD.Period,
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting,
		|	DD.QuantityToDistribution,
		|	DD.CostToDistribution,
		|	DD.CostWithoutNDSKDistribution,
		|	DD.CostLocalToDistribution,
		|	DD.ManSCostToDistribution,
		|
		|	DD.AdditionalCostsSNDSKDistribution,
		|	DD.AdditionalExpensesWithoutNDSKDISTRIBUTION,
		|	DD.AdditionalExpensesOfLocalNDSKDistribution,
		|	DD.AdditionalExpensesOfManNDSKDistribution,
		|	DD.VATLocalToDistribution,
		|	DD.VATManForDistribution,
		|	DD.ConstantDifferenceToDistribution,
		|	DD.TemporalDifferenceToDistribution,
		|	DD.CostOfPersonalIncomeTaxDistribution,
		|
		|	DD.ReceiptPeriod,
		|	ValuationMethods.InventoryValuationMethod AS InventoryValuationMethod
		|INTO ReceiversForProductsOfPastPeriods
		|FROM
		|	(
		|SELECT
		|	Source.Recorder,
		|	Attributes.Date AS Period,
		|	VALUE(Enum.LotRecordTypes.EmptyRef) AS EntryType,
		|	Source.ItemsLocationAttributes,
		|	Source.AccountingSection,
		|	Source.InventoryOwnerAttribute,
		|	Source.Organization,
		|	Source.Lot,
		|	Source.LotVendorAttributes,
		|	Source.FinancialAccountingDimension,
		|	Source.VATActivityType,
		|	UNDEFINED AS FinRecordID,
		|	UNDEFINED AS BusinessTransactionSetting,
		|	Source.Count AS QuantityToDistribution,
		|	Source.Cost AS CostToDistribution,
		|	Source.CostExcludingVAT AS CostWithoutNDSKDistribution,
		|	Source.LocalCost AS CostLocalToDistribution,
		|	Source.CostMan AS ManSCostToDistribution,
		|
		|	0 AS AdditionalCostsSNDSKDistribution,
		|	0 AS AdditionalExpensesWithoutNDSKDISTRIBUTION,
		|	0 AS AdditionalExpensesOfLocalNDSKDistribution,
		|	0 AS AdditionalExpensesOfManNDSKDistribution,
		|	0 AS VATLocalToDistribution,
		|	0 AS VATManForDistribution,
		|	0 AS ConstantDifferenceToDistribution,
		|	0 AS TemporalDifferenceToDistribution,
		|	Source.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTaxDistribution,
		|	
		|	MIN(BEGINOFPERIOD(
		|		CASE WHEN Register3.IBDocumentDate IS NULL OR Register3.IBDocumentDate < &DateOfMigrationToBatchAccounting22
		|			THEN &DateOfMigrationToBatchAccounting22
		|			ELSE Register3.IBDocumentDate
		|		END, MONTH)) AS ReceiptPeriod
		|FROM
		|	ProductReceivers AS Source
		|		INNER JOIN Document.AllocationOfOtherCosts AS Attributes
		|		ON Source.Recorder = Attributes.Ref
		|
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
		|		ON Register3.Ref = CASE
		|			WHEN Source.Lot <> UNDEFINED THEN Source.Lot
		|			WHEN Attributes.DimensionOfExpenses <> UNDEFINED THEN Attributes.DimensionOfExpenses
		|			ELSE NULL END
		|		AND NOT Register3.AdditionalRecord
		|WHERE
		|	Source.ThisIsPartyOfPastPeriod
		|	AND NOT Source.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		// Expenses with empty analytics should not be allocated for the disposal of goods of past periods.
		|	AND NOT Register3.Ref IS NULL
		|
		|GROUP BY
		|	Source.Recorder,
		|	Attributes.Date,
		|	Source.ItemsLocationAttributes,
		|	Source.AccountingSection,
		|	Source.InventoryOwnerAttribute,
		|	Source.Organization,
		|	Source.Lot,
		|	Source.LotVendorAttributes,
		|	Source.FinancialAccountingDimension,
		|	Source.VATActivityType,
		|	Source.Count,
		|	Source.Cost,
		|	Source.CostExcludingVAT,
		|	Source.LocalCost,
		|	Source.CostMan,
		|	Source.CostOfPersonalIncomeTax
		|) AS DD
		|	INNER JOIN TTMethodsOfEstimatingValueOfOrganizationsByPeriod AS ValuationMethods
		|		ON DD.Organization = ValuationMethods.Organization
		|		AND DD.ReceiptPeriod >= ValuationMethods.BeginOfPeriod
		|		AND DD.ReceiptPeriod < ValuationMethods.EndOfPeriod
		|
		|INDEX BY
		|	ItemsLocationAttributes
		|";
		
	Return QueryText;
	
EndFunction

#Region LongDesc_IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods

// All disposals of goods in past periods are divided into the following areas:
// - Implementation
// - Write-off for expenses
// - Write-off of assets/liabilities
// - Write–off for production batches - attribution to the item "Production costs of past periods"
// - Other disposals
//		- Movements with changes in the nomenclature or characteristics (assembly/disassembly, spoilage, re-sorting, etc.)
//		- Transfer to a partner (transfer to a commission 2.4, transfer to a processor 2.4)
//		- Transfer to a branch (using the "Average monthly" valuation method)
// - Write-off of low-value Inventory in the month of purchase 
//		(the cost is written off for expenses in accounting and in Man accounting of organizations, in TA a temporary difference is formed)
// - Moving to another storage location (if the goods are left on the Balance in another warehouse, division or Contract)
//
// Movements at the cost of goods are not classified as disposals if the item accounting analysis changes, but without 
// changing the item, characteristics, batch and batch accounting analysis. In addition to the transfer to the partner (if 
// the partner is specified in the inventory accounting analytics), because in the transactions for the distribution of additional expenses for the Balance of such goods 
// , you need to fill in the counterparty and the Contract, and there is no such data in the Balance.
//
// Distribution when using the FIFO assessment method:
// Data selections for FIFO accounting are performed by fields: "Party", "Party accounting analytics", "Nomenclature" and "Characteristics".
// Warehouse, destination and series are not taken into account, because they may change. If goods with different series or different purposes are reflected within the same batch 
// , then a separate batch accounting analysis is generated for each line of the document. Therefore, the availability of batch selection and 
// batch accounting analytics is sufficient for an accurate sample of disposals.
// We do not take into account the organization, because the batch can be transferred to a branch.
//
// Distribution when using the "Monthly Average" estimation method:
// A simplified distribution algorithm is applied. Additional expenses related to disposals of the previous period are always attributed 
// to the predetermined item "Disposals of goods in previous periods" in the proportion:
//	(quantity in purchase - Balance at the beginning of the period) / quantity in purchase
// Priority additional expenses will remain in the Balance, if there is a Balance at the beginning of the period.
//
// Features of distribution when changing the cost estimation method:
// The distribution of additional expenses is performed taking into account the cost estimation method that was in effect during the period of reflection 
// of the purchase of goods and services (indicated in the cost analysis).
//
// Peculiarities of distribution to the Balance of goods shipped without transfer of ownership:
// When using the FIFO method for shipment without transfer of ownership, the batch changes – 
// the shipment document ("Sale of goods and services") becomes the batch, therefore, Balances shipped without transfer of ownership cannot be immediately found for a batch of goods 
// and sales of shipped goods cannot be found. 
// Therefore, a table of correspondence of batches of goods and shipment documents is formed without transfer of ownership. 
// And then, according to this table, a sample of Balances and a sample of sales of shipped goods are performed.
//
// Features of distribution to delivery invoice documents:
// When using non-invoice deliveries using the FIFO method, the batch is a document of receipt of goods to the warehouse. 
// Therefore, additional costs for goods, reflected with the indication of the document of purchase of goods and services (for invoicing delivery), 
// must be distributed to the batch of goods received to the warehouse for which invoices have been completed.
// 
// Features of distribution for goods in transit from suppliers:
// The distribution of additional costs for goods in transit from suppliers depends on the functional option "Distribution of additional 
// costs for goods in transit from suppliers".
// If the functional option is enabled, then the distribution is performed both for Balances in the accounting section "Own goods in transit (from suppliers)"
// and for Balances and disposals of goods received at the warehouse from goods in transit from suppliers.
// If the functional option is disabled, then the distribution is performed only for Balances and disposals of goods that arrived 
// at the warehouse from goods in transit from suppliers.
//  
// Description of the distribution algorithm
// The initial data for the distribution are in the time table of the receiver of the last periods.
// 1) A table of Balances is being formed at the beginning of the period - the second statistic is the highest value.
//		It is used in the formation of variable tables of vtfifoostatkisebostostoy and VTS averageostatkisebostostoy
//	
// Queries executed using the FIFO cost estimation method:
// 2) An auxiliary table is being formed for selection according to the section of accounting for unfactated deliveries - the second receipt of last periods to the registrar
//		Used when forming the temporary table of the second account.
// 3) An auxiliary table is being formed for the selection of movements - the second selection of the recipients of the last periods of the Party
//		It is used in the formation of a temporary table of vtfiforealization without the transition of ownership
// 4) A table of implementations with delayed transfer of ownership is being formed - vtfiforealizationifrealizationifrealizationfrom the transfer of ownership
//		It is used in the formation of temporary tables of vtfifoitogirealization without transition of ownership and VTTBORFIFO
// 5) A table is formed with the total amount for implementation documents with deferred transfer of ownership - 
//	VTFIFOITOGIREALIZATION without transfer of ownership
//		Used when forming the temporary table of the second account.
// 6) A table is formed for the selection of Balances and movements when using FIFO - Second FIFO
//		It is used in the formation of temporary tables of VTFIFOOstatkiSebestability, vtfiforealizationand past periods, vtfifospisaniyaproch events
// 7) A table of Balances is being formed for which additional expenses will be allocated - vtfifoostatkisebostost
//		Used when forming a temporary vtfifodetally table
// 8) A table of implementations of the previous period is being formed - vtfiforealizations of the past periods
//		Used when forming a temporary vtfifodetally table
// 9) A table of other disposals is being formed - vtfifospisaniyaproch disposals
//		Used when forming a temporary vtfifodetally table
// 10) A general table of disposals of the previous period is formed - vtfifodetally
//		It is used in the formation of temporary tables of VT and indicators of the base of the distribution of receivers of past periods
// 11) A summary table of disposals of the previous period is being formed - VTFIFOSvodno
//		Used in the formation of a temporary table of indicators of the base distribution of receivers of past periods
//	
// Queries executed using the Monthly Average cost estimation method:
// 12) Tables are being formed for the selection of acquisitions - the second Board of access documentation is average and the second Board of access documentation is average
// 		In the first table, data is selected from the receiver of the last product periods for which the original purchase document can be set:
// 		 - for the document the distribution of the total costs, which indicates the cost analysis
// 		 - for other documents with the completed Document Source field in the movements at cost
// 		For the data in this table, you can accurately determine the initial purchase amount.
// 		In the second table, all other data is selected from the receiver of the previous periods that did not fall into the first table.
// 		For the data in this table, the number of purchases is calculated in total for all cost analysts.       
//		Are used in the formation of the temporary table of the VTS average of the acquisition.
//		Based on the second Board Access documentationthe average is formed by the second board Access documentationthe average is expanded
// 13) A table is formed for the selection of Balances - the second average
//		It is used when forming a temporary table of the average cost of the average cost.
// 14) A table of Balances is being formed, according to which additional expenses are reflected - the average cost of the cost is
//		It is used when forming a temporary table VTS averagely.
// 15) An acquisition table is formed. Contains analytics and quantity for each acquisition - VTS average of the acquisition
//		For the formation of the table, intermediate tables are used vtsrednayapriobreniyaneotakturovka and VTSrednayApriobreniyaPredvaritelnaya
//		It is used when forming a temporary table VTS averagely.
// 16) A table of correspondence between the amount of acquisition and the amount of Balance is formed - VTS averagely
//		It is used when forming a temporary table of VTS averages in detail.
// 17) The table of disposals of the previous period is formed - VTS AVEragelyAdetally
//		If the Balance is greater than or equal to the purchase, additional costs are allocated to the Balance of the goods.
//		If the Balance is less than the purchase, then the additional costs are distributed between the retired quantity (purchase quantity minus the Balance)
//		and the Balance in the warehouse. 
//		The amount of disposal relates to the expense item "Disposal of goods in past periods" regardless of the direction of disposal of goods.
//		Used in the formation of a temporary table of indicators of the base distribution of receivers of past periods 
//	
// 18) A table of the distribution base is formed - indicators of the base of distribution of receivers of the past periods
//		Used in the request for the text of additional expenses() and in requests for the formation of movements by registers.

#EndRegion

Function IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods()
	
	QueriesTexts = New Array;
	
	// Preparation of general tables for FIFO and for the Average.
	//
	// Let's prepare a general table of Balances.
	#Region TTCostBalancePreliminary
	
	QueryTextTTCostBalancesPreliminary = "
		|SELECT
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.ItemsLocationAttributes.Products AS Products,
		|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	T.AccountingSection AS AccountingSection,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Organization AS Organization,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|	T.CountBalance AS Count
		|INTO TTCostBalancePreliminary
		|FROM
		|	AccumulationRegister.InventoryCost.Balance(
		|		&BorderEndOfPreviousPeriod, 
		|		Organization IN (&CompanyArray)
		|		AND NOT Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|		AND NOT AccountingSection IN (&OffBalanceSheetAccountingSections)
		// The Additional expense amounts and deviations are not allocated to the Balance of goods from the partner, because when allocating Additional expense
		// amounts to such Balances in the transaction for accounting, the counterparty and the Contract cannot be filled in (there is no such information in the Balance sheets).
		|		AND ItemsLocationAttributes.StorageType <> VALUE(Enum.StorageLocationTypes.Partner)
		|	) AS T
		|WHERE
		|	T.CountBalance > 0
		|
		|INDEX BY
		|	Lot
		|";
	QueriesTexts.Add(QueryTextTTCostBalancesPreliminary);
	
	#EndRegion
	
	// Preparation of data for the FIFO assessment method
	//
	// Let's prepare a FIFO selection table for the accounting section for unfactured deliveries
	#Region TTSelectionOfFIFOReceiversOfPreviousPeriodsByRegistrar
	
	QueryTextTTSelectionOfFIFOReceiversOfPreviousPeriodsByRegistrar = "
		|SELECT DISTINCT
		|	T.Recorder AS Recorder,
		|	Filter.Products AS Products,
		|	Filter.Characteristic AS Characteristic
		|INTO TTSelectionOfFIFOReceiversOfPreviousPeriodsByRegistrar
		|FROM
		|	ReceiversForProductsOfPastPeriods AS T
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Filter
		|		ON T.ItemsLocationAttributes = Filter.Ref
		|WHERE
		|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.FIFORollingValuation)
		|INDEX BY
		|	Recorder
		|";
	QueriesTexts.Add(QueryTextTTSelectionOfFIFOReceiversOfPreviousPeriodsByRegistrar);
		
	#EndRegion
	
	// Let's prepare a FIFO selection table for households. Implementation of operations without the transition of ownership.
	#Region TTSelectionOfFIFOReceiversOfPreviousPeriodsByBatch
	
	QueryTextTTSelectionOfFIFOReceiversOfPreviousPeriodsByBatch = "
		|SELECT DISTINCT
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	Filter.Products AS Products,
		|	Filter.Characteristic AS Characteristic
		|INTO TTSelectionOfFIFOReceiversOfPreviousPeriodsByBatch
		|FROM
		|	ReceiversForProductsOfPastPeriods AS T
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Filter
		|		ON T.ItemsLocationAttributes = Filter.Ref
		|WHERE
		|	T.Lot <> UNDEFINED
		|	AND T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.FIFORollingValuation)
		|INDEX BY
		|	Lot
		|";
	QueriesTexts.Add(QueryTextTTSelectionOfFIFOReceiversOfPreviousPeriodsByBatch);
		
	#EndRegion
	
	// Let's prepare the table implementation without transfer of ownership.
	#Region TTFIFOOfImplementationWithoutTransferOfOwnership
	
	QueryTextOfTTFIFOImplementationWithoutTransferOfOwnership = "
		|SELECT
		|	T.Organization AS Organization,
		|	T.Recorder AS Recorder,
		|	T.CorLot AS Lot, // Implementation document Lot reference
		|	T.LotVendorAttributesCorr AS LotVendorAttributes,
		|	T.Lot AS CorLot, // source Lot reference
		|	T.LotVendorAttributes AS LotVendorAttributesCorr,
		|	FilterProducts.Products AS Products,
		|	FilterProducts.Characteristic AS Characteristic,
		|	SUM(T.Count) AS Count
		|INTO TTFIFOOfImplementationWithoutTransferOfOwnership
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS FilterProducts
		|		ON (T.ItemsLocationAttributes = FilterProducts.Ref)
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS StornoRegistry
		|	ON StornoRegistry.ReversedDocument = T.Recorder
		|		AND NOT StornoRegistry.AdditionalRecord
		|		AND StornoRegistry.IBDocumentDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND StornoRegistry.Posted
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				TTSelectionOfFIFOReceiversOfPreviousPeriodsByBatch AS FilterLot
		|			WHERE
		|				T.Lot = FilterLot.Lot
		|				AND T.LotVendorAttributes = FilterLot.LotVendorAttributes
		|				AND FilterProducts.Products = FilterLot.Products
		|				AND FilterProducts.Characteristic = FilterLot.Characteristic)
		|	AND T.Period < &BeginOfPeriod
		|	AND T.CorLot <> UNDEFINED
		|	AND T.Count > 0
		|	AND T.Active
		|	AND NOT T.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
		|
		// Checking for the presence of a reverse in the Cur period.
		|	AND StornoRegistry.Ref IS NULL
		|GROUP BY
		|	T.Organization,
		|	T.Recorder,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	FilterProducts.Products,
		|	FilterProducts.Characteristic
		|
		|INDEX BY
		|	Lot,
		|	Products
		|";
	QueriesTexts.Add(QueryTextOfTTFIFOImplementationWithoutTransferOfOwnership);
		
	#EndRegion
		
	// Let's prepare the final table for implementations without transfer of ownership
	#Region TTFIFOResultsOfImplementationWithoutTransferOfOwnership
	
	QueryTextTTFIFOResultsOfImplementationWithoutTransferOfOwnership = "
		|SELECT
		|	T.Recorder AS Recorder,
		|	T.Lot AS Lot, // Implementation document Lot reference
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	SUM(T.Count) AS Count
		|INTO TTFIFOResultsOfImplementationWithoutTransferOfOwnership
		|FROM
		|	TTFIFOOfImplementationWithoutTransferOfOwnership AS T
		|GROUP BY
		|	T.Recorder,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.Products,
		|	T.Characteristic
		|INDEX BY
		|	Lot,
		|	Products
		|";
	QueriesTexts.Add(QueryTextTTFIFOResultsOfImplementationWithoutTransferOfOwnership);
		
	#EndRegion
	
	// We will prepare a general FIFO selection table.
	#Region TTFIFOSelection
	
	QueryTextTTFIFOSelection = "
		// There are enough selectable fields to accurately determine all the directions of additional disposal. expenses
		// The Corporate Party and Corporate Party account fields are needed for implementation without transfer of ownership,
		// because in this operation the original Lot reference, which includes additional. expenses, changes to the Lot reference of the implementation document.
		// In this case, the Coefficient field indicates which part of the original Lot reference is included in the Lot reference of the implementation document.
		|SELECT DISTINCT
		|	T.Organization AS Organization,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.Lot AS CorLot,
		|	T.LotVendorAttributes AS LotVendorAttributesCorr,
		|	Filter.Products AS Products,
		|	Filter.Characteristic AS Characteristic,
		|	1 AS ZoomRatio
		|INTO TTFIFOSelection
		|FROM
		|	ReceiversForProductsOfPastPeriods AS T
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Filter
		|		ON T.ItemsLocationAttributes = Filter.Ref
		|WHERE
		|	T.Lot <> UNDEFINED
		|	AND T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.FIFORollingValuation)
		|
		|UNION 
		|
		|SELECT DISTINCT
		|	T.Organization AS Organization,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.Lot AS CorLot,
		|	T.LotVendorAttributes AS LotVendorAttributesCorr,
		|	FilterProducts.Products AS Products,
		|	FilterProducts.Characteristic AS Characteristic,
		|	1 AS ZoomRatio
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS FilterProducts
		|		ON T.ItemsLocationAttributes = FilterProducts.Ref
		|	INNER JOIN TTSelectionOfFIFOReceiversOfPreviousPeriodsByRegistrar AS FilterRecorder
		|		ON T.Recorder = FilterRecorder.Recorder
		|		AND FilterProducts.Products = FilterRecorder.Products
		|		AND FilterProducts.Characteristic = FilterRecorder.Characteristic
		|WHERE
		|	T.Lot <> UNDEFINED
		|	AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND T.Active
		|	AND NOT T.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|
		|UNION
		|
		|SELECT
		|	T.Organization AS Organization,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.CorLot AS CorLot,
		|	T.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	CAST(T.Count / TTTotals.Count AS NUMBER(31,10)) AS Count
		|FROM
		|	TTFIFOOfImplementationWithoutTransferOfOwnership AS T
		|	INNER JOIN TTFIFOResultsOfImplementationWithoutTransferOfOwnership AS TTTotals
		|		ON T.Lot = TTTotals.Lot
		|		AND T.LotVendorAttributes = TTTotals.LotVendorAttributes
		|		AND T.Products = TTTotals.Products
		|		AND T.Characteristic = TTTotals.Characteristic
		|
		|INDEX BY
		|	Lot
		|";
	QueriesTexts.Add(QueryTextTTFIFOSelection);
		
	#EndRegion
	
	// Let's prepare a table of FIFO Balances.
	#Region TTFIFOCostBalance
	
	QueryTextTTFIFOCostBalance = "
		|SELECT
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.AccountingSection AS AccountingSection,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Organization AS Organization,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|	FilterLots.CorLot AS CorLot,
		|	FilterLots.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	CAST(T.Count * FilterLots.ZoomRatio AS NUMBER (15, 3)) AS Count
		|INTO TTFIFOCostBalance
		|FROM
		|	TTCostBalancePreliminary AS T
		|	INNER JOIN TTFIFOSelection AS FilterLots
		|		ON T.Lot = FilterLots.Lot
		|		AND T.LotVendorAttributes = FilterLots.LotVendorAttributes
		|		AND T.Products = FilterLots.Products
		|		AND T.Characteristic = FilterLots.Characteristic
		|WHERE
		// You don't need to use the distribution parameter
		// for overspending goods so that you can always distribute additional items. Expenses for goods in transit from suppliers
		// see the condition in the text of the receipt of the goods of the past periodsreferences
		|	T.Lot <> UNDEFINED
		// The conditions below must correspond to the conditions for the selection of disposals in vtfifospisaniyaproch disposals
		|	AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|	AND T.ItemsLocationAttributes.StorageType <> VALUE(Enum.StorageLocationTypes.Partner)
		|
		|UNION ALL
		|
		// On changes in the cost estimation method, the Balances at the beginning of the period will be with an empty batch.
		|SELECT
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.AccountingSection AS AccountingSection,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Organization AS Organization,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|	FilterLots.CorLot AS CorLot,
		|	FilterLots.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	CAST(T.Count * FilterLots.ZoomRatio AS NUMBER (15, 3)) AS Count
		|FROM
		|	TTCostBalancePreliminary AS T
		|	INNER JOIN TTFIFOSelection AS FilterLots
		|		ON T.Organization = FilterLots.Organization
		|		AND T.Products = FilterLots.Products
		|		AND T.Characteristic = FilterLots.Characteristic
		|WHERE
		// You don't need to use the distribution parameter
		// for overspending goods so that you can always distribute additional items. Expenses for goods in transit from suppliers
		// see the condition in the text of the receipt of the goods of the past periodsreferences
		|	T.Lot = UNDEFINED
		|	AND NOT T.Organization IN (&SFIFOOrganizationsSliding)
		// The conditions below must correspond to the conditions for the selection of disposals in vtfifospisaniyaproch disposals
		|	AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|	AND T.ItemsLocationAttributes.StorageType <> VALUE(Enum.StorageLocationTypes.Partner)
		|
		|INDEX BY
		|	Lot
		|";
	QueriesTexts.Add(QueryTextTTFIFOCostBalance);
		
	#EndRegion
	
	// Let's prepare a table of implementations of past FIFO periods.
	#Region TTFIFOOfImplementationOfPastPeriods
	
	QueryTextTTFIFOOfImplementationOfPastPeriods = "
		|SELECT
		|	T.Recorder,
		|	T.Period,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	FilterProducts.Products,
		|	FilterProducts.Characteristic,
		|	T.AccountingSection AS AccountingSection,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.AccountingDimensionByPartners.Organization AS Organization,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|	FilterLots.CorLot AS CorLot,
		|	FilterLots.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|
		|	T.VATTaxation AS CorVATActivityTypes,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.SalesOrder AS SalesOrder,
		|	T.Department AS Department,
		|	T.Manager AS Manager,
		|	T.Warehouse AS Warehouse,
		|	T.Terms AS Terms,
		|	T.Contract AS Contract,
		|	T.InventoryType AS InventoryType,
		|	T.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
		|	T.ProductLineOfBusiness AS ProductLineOfBusiness,
		|	T.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup,
		|	T.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
		|	T.FinRecordID AS FinRecordID,
		|
		|	SUM(CAST(T.Count * FilterLots.ZoomRatio AS NUMBER (15, 3))) AS Count
		|INTO TTFIFOOfImplementationOfPastPeriods
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS T
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS FilterProducts
		|		ON T.ItemsLocationAttributes = FilterProducts.Ref
		|	INNER JOIN TTFIFOSelection AS FilterLots
		|		ON T.Lot = FilterLots.Lot
		|		AND T.LotVendorAttributes = FilterLots.LotVendorAttributes
		|		AND FilterProducts.Products = FilterLots.Products
		|		AND FilterProducts.Characteristic = FilterLots.Characteristic
		|WHERE
		|	&AllocationOfAdditionalExpensesByDisposedGoods
		|	AND T.Period < &BeginOfPeriod
		|	AND NOT VALUETYPE(T.Recorder) = TYPE(Document.RegisterAdjustment)
		|	AND NOT T.AccountingDimensionByPartners.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|	AND T.Active
		// The conditions below must correspond to the conditions for the selection of disposals in vtfifospisaniyaproch disposals
		|	AND FilterProducts.StorageType <> VALUE(Enum.StorageLocationTypes.Partner)
		|GROUP BY
		|	T.Recorder,
		|	T.Period,
		|	T.ItemsLocationAttributes,
		|	FilterProducts.Products,
		|	FilterProducts.Characteristic,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.AccountingDimensionByPartners.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	FilterLots.CorLot,
		|	FilterLots.LotVendorAttributesCorr,
		|	T.VATTaxation,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.Department,
		|	T.Manager,
		|	T.Warehouse,
		|	T.Terms,
		|	T.Contract,
		|	T.InventoryType,
		|	T.CounterpartyLineOfBusiness,
		|	T.ProductLineOfBusiness,
		|	T.SourceOfProductFinancialAccountingGroup,
		|	T.SourceOfARAPFinancialAccountingGroup,
		|	T.FinRecordID
		|HAVING
		|	SUM(T.Count) > 0
		|INDEX BY
		|	Lot
		|";
	QueriesTexts.Add(QueryTextTTFIFOOfImplementationOfPastPeriods);
		
	#EndRegion
	
	// We will prepare a table of write-off and other FIFO disposals:
	// - an expense item or an asset/liability item is indicated
	// - the Attribute "Business of operation" indicates the value "Write-off for expenses of low-value Inventory in the month of purchase"
	// - the Attribute "Cor accounting section" indicates "Work in progress"
	// - the Attribute "Cor analytics accounting nomenclature" indicates a nomenclature or characteristic other than the field "Analytics accounting nomenclature"
	// - the Attribute "Cor analytics the type of storage location "Partner" is indicated
	// - the Attribute of the Corporation differs from the Batch (in the documents of re-sorting, spoilage, assembly/disassembly of goods).
	#Region TTFIFOWriteOffsAndOtherDisposals
	
	QueryTextTTFIFOWriteOffsAndOtherDisposals = "
		|SELECT DISTINCT
		|	DD.ProductionLot
		|INTO ProductionBatchesForDistribution
		|FROM
		|	ProductionBatchesAreSummarized AS DD
		|INDEX BY
		|	ProductionLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Recorder,
		|	T.Period,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	FilterProducts.Products,
		|	FilterProducts.Characteristic,
		|	T.AccountingSection AS AccountingSection,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Organization AS Organization,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|
		|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.CorAccountingSection AS CorAccountingSection,
		|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	T.CorCompany AS CorCompany,
		|	T.CorLot AS CorLot,
		|	T.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	T.CorControllingAttributes AS CorControllingAttributes,
		|	T.CorVATActivityTypes AS CorVATActivityTypes,
		|	(CASE
		|		WHEN T.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|		 AND (T.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				OR T.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef))
		|			THEN T.Department
		|		WHEN T.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageLocation REFS Catalog.BusinessStructure
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageLocation REFS Catalog.CounterpartyContracts
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		WHEN NOT Register3.Department IS NULL
		|			THEN Register3.Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END) AS Department,
		|	CASE
		|		WHEN FALSE
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		// If the batch of production is indicated as the analytics of expenses, for which there are no Balances and turnover in the current period,
		// then the write-off should be made to the predefined item "Production expenses of past periods",
		// because according to the specified analytics, the distribution of expenses will not be performed due to the lack of a distribution base.
		// In this case, we leave the analytics of expenses empty.
		|		WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
		|		  AND T.DimensionOfExpenses <> VALUE(Catalog.ProductionLots.EmptyRef)
		|		  AND ProductionLots.ProductionLot IS NULL
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods)
		|			ELSE T.ExpenseItemOfWriteOff
		|	END AS ExpenseItemOfWriteOff,
		|	CASE
		|		WHEN FALSE
		|			THEN UNDEFINED
		|		WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
		|		  AND T.DimensionOfExpenses <> VALUE(Catalog.ProductionLots.EmptyRef)
		|		  AND ProductionLots.ProductionLot IS NULL
		|			THEN UNDEFINED
		|			ELSE T.DimensionOfExpenses
		|	END AS DimensionOfExpenses,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.GLAccountSettings,
		|	CASE
		|		WHEN FALSE THEN T.CorLineOfBusiness
		|		WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
		|		  AND T.DimensionOfExpenses <> VALUE(Catalog.ProductionLots.EmptyRef)
		|		  AND ProductionLots.ProductionLot IS NULL
		|		  AND VALUETYPE(T.CorLot) = TYPE(Catalog.ProductionLots)
		|			THEN ISNULL(CAST(T.CorLot AS Catalog.ProductionLots).Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness, T.CorLineOfBusiness)
		|	END AS CorLineOfBusiness,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	SUM(T.Count) AS Count
		|INTO TTFIFOWriteOffsAndOtherDisposals
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS FilterProducts
		|		ON T.ItemsLocationAttributes = FilterProducts.Ref
		|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS FilterCorNomenclature
		|		ON T.CorItemsLocationAttributes = FilterCorNomenclature.Ref
		|	INNER JOIN TTFIFOSelection AS FilterLots
		|		ON T.Lot = FilterLots.Lot
		|		AND T.LotVendorAttributes = FilterLots.LotVendorAttributes
		|		AND FilterProducts.Products = FilterLots.Products
		|		AND FilterProducts.Characteristic = FilterLots.Characteristic
		|	LEFT JOIN ProductionBatchesForDistribution AS ProductionLots
		|		ON T.DimensionOfExpenses = ProductionLots.ProductionLot
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
		|		ON Register3.Ref = T.Recorder
		|		AND NOT Register3.AdditionalRecord
		|WHERE
		|	&AllocationOfAdditionalExpensesByDisposedGoods
		|	AND T.Period < &BeginOfPeriod
		|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND NOT VALUETYPE(T.Recorder) = TYPE(Document.RegisterAdjustment)
		|	AND T.Count <> 0
		|	AND T.Active
		|	AND NOT T.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		// The selection conditions for cost measurements should also be specified in the VTFIFOOSTATKIS cost and VT Fforealization of the past periods (with the condition NOT)
		// in order to exclude the same of operation from entering the distribution database several times
		|	AND (T.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|		OR T.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
		|		OR T.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffLowCostInventoryAsExpensesInThePurchaseMonth)
		|		OR T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|		OR (T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		    AND NOT T.Organization IN (&SFIFOOrganizationsSliding))
		|		OR (T.CorLot <> UNDEFINED
		|			AND T.CorLot <> T.Lot
		|			AND T.BusinessOperation IN
		|			 (VALUE(Enum.BusinessTransactions.AssemblyFromComponents),
		|			  VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents),
		|			  VALUE(Enum.BusinessTransactions.GoodsMisgrading),
		|			  VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation),
		|			  VALUE(Enum.BusinessTransactions.GoodsDamage),
		|			  VALUE(Enum.BusinessTransactions.GoodsDamageRevaluation))
		|			)
		|		OR (NOT FilterCorNomenclature.Ref IS NULL
		|			  AND (FilterCorNomenclature.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
		|				OR FilterProducts.Products <> FilterCorNomenclature.Products
		|				OR FilterProducts.Characteristic <> FilterCorNomenclature.Characteristic)
		|			)
		|	  )
		|GROUP BY
		|	T.Recorder,
		|	T.Period,
		|	T.ItemsLocationAttributes,
		|	FilterProducts.Products,
		|	FilterProducts.Characteristic,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|	(CASE
		|		WHEN T.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|		 AND (T.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				OR T.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef))
		|			THEN T.Department
		|		WHEN T.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageLocation REFS Catalog.BusinessStructure
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageLocation REFS Catalog.CounterpartyContracts
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		WHEN NOT Register3.Department IS NULL
		|			THEN Register3.Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END), // Department
		|	CASE
		|		WHEN FALSE
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|		WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
		|		  AND T.DimensionOfExpenses <> VALUE(Catalog.ProductionLots.EmptyRef)
		|		  AND ProductionLots.ProductionLot IS NULL
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods)
		|			ELSE T.ExpenseItemOfWriteOff
		|	END, // ExpenseItemOfWriteOff
		|	CASE
		|		WHEN FALSE
		|			THEN UNDEFINED
		|		WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
		|		  AND T.DimensionOfExpenses <> VALUE(Catalog.ProductionLots.EmptyRef)
		|		  AND ProductionLots.ProductionLot IS NULL
		|			THEN UNDEFINED
		|			ELSE T.DimensionOfExpenses
		|	END, // DimensionOfExpenses
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.GLAccountSettings,
		|	CASE 
		|		WHEN FALSE THEN T.CorLineOfBusiness
		|		WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
		|		  AND T.DimensionOfExpenses <> VALUE(Catalog.ProductionLots.EmptyRef)
		|		  AND ProductionLots.ProductionLot IS NULL
		|		  AND VALUETYPE(T.CorLot) = TYPE(Catalog.ProductionLots)
		|			THEN ISNULL(CAST(T.CorLot AS Catalog.ProductionLots).Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness, T.CorLineOfBusiness)
		|	END, // CorLineOfBusiness
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID
		|HAVING
		|	SUM(T.Count) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	T.Recorder,
		|	T.Period,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	FilterProducts.Products,
		|	FilterProducts.Characteristic,
		|	T.AccountingSection AS AccountingSection,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Organization AS Organization,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|
		|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.CorAccountingSection AS CorAccountingSection,
		|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	T.CorCompany AS CorCompany,
		|	T.CorLot AS CorLot,
		|	T.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	T.CorControllingAttributes AS CorControllingAttributes,
		|	T.CorVATActivityTypes AS CorVATActivityTypes,
		|	(CASE
		|		WHEN T.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|		 AND (T.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				OR T.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef))
		|			THEN T.Department
		|		WHEN T.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageLocation REFS Catalog.BusinessStructure
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageLocation REFS Catalog.CounterpartyContracts
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		WHEN NOT Register3.Department IS NULL
		|			THEN Register3.Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END) AS Department,
		|	CASE
		|		WHEN FALSE
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		// If the batch of production is indicated as the analytics of expenses, for which there are no Balances and turnover in the current period,
		// then the write-off should be made to the predefined item "Production expenses of past periods",
		// because according to the specified analytics, the distribution of expenses will not be performed due to the lack of a distribution base.
		// In this case, we leave the analytics of expenses empty.
		|		WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
		|		  AND T.DimensionOfExpenses <> VALUE(Catalog.ProductionLots.EmptyRef)
		|		  AND ProductionLots.ProductionLot IS NULL
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods)
		|			ELSE T.ExpenseItemOfWriteOff
		|	END AS ExpenseItemOfWriteOff,
		|	CASE
		|		WHEN FALSE
		|			THEN UNDEFINED
		|		WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
		|		  AND T.DimensionOfExpenses <> VALUE(Catalog.ProductionLots.EmptyRef)
		|		  AND ProductionLots.ProductionLot IS NULL
		|			THEN UNDEFINED
		|			ELSE T.DimensionOfExpenses
		|	END AS DimensionOfExpenses,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.GLAccountSettings,
		|	CASE
		|		WHEN FALSE THEN T.CorLineOfBusiness
		|		WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
		|		  AND T.DimensionOfExpenses <> VALUE(Catalog.ProductionLots.EmptyRef)
		|		  AND ProductionLots.ProductionLot IS NULL
		|		  AND VALUETYPE(T.CorLot) = TYPE(Catalog.ProductionLots)
		|			THEN ISNULL(CAST(T.CorLot AS Catalog.ProductionLots).Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness, T.CorLineOfBusiness)
		|	END AS CorLineOfBusiness,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	SUM(-T.Count) AS Count
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS FilterProducts
		|		ON T.ItemsLocationAttributes = FilterProducts.Ref
		|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS FilterCorNomenclature
		|		ON T.CorItemsLocationAttributes = FilterCorNomenclature.Ref
		|	INNER JOIN TTFIFOSelection AS FilterLots
		|		ON T.Lot = FilterLots.Lot
		|		AND T.LotVendorAttributes = FilterLots.LotVendorAttributes
		|		AND FilterProducts.Products = FilterLots.Products
		|		AND FilterProducts.Characteristic = FilterLots.Characteristic
		|	LEFT JOIN ProductionBatchesForDistribution AS ProductionLots
		|		ON T.DimensionOfExpenses = ProductionLots.ProductionLot
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
		|		ON Register3.Ref = T.Recorder
		|		AND NOT Register3.AdditionalRecord
		|WHERE
		|	&AllocationOfAdditionalExpensesByDisposedGoods
		|	AND T.Period < &BeginOfPeriod
		|	AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND NOT VALUETYPE(T.Recorder) = TYPE(Document.RegisterAdjustment)
		|	AND T.Count <> 0
		|	AND T.Active
		|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
		|GROUP BY
		|	T.Recorder,
		|	T.Period,
		|	T.ItemsLocationAttributes,
		|	FilterProducts.Products,
		|	FilterProducts.Characteristic,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|	(CASE
		|		WHEN T.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|		 AND (T.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				OR T.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef))
		|			THEN T.Department
		|		WHEN T.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageLocation REFS Catalog.BusinessStructure
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageLocation REFS Catalog.CounterpartyContracts
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		WHEN NOT Register3.Department IS NULL
		|			THEN Register3.Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END), // Department
		|	CASE
		|		WHEN FALSE
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|		WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
		|		  AND T.DimensionOfExpenses <> VALUE(Catalog.ProductionLots.EmptyRef)
		|		  AND ProductionLots.ProductionLot IS NULL
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods)
		|			ELSE T.ExpenseItemOfWriteOff
		|	END, // ExpenseItemOfWriteOff
		|	CASE
		|		WHEN FALSE
		|			THEN UNDEFINED
		|		WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
		|		  AND T.DimensionOfExpenses <> VALUE(Catalog.ProductionLots.EmptyRef)
		|		  AND ProductionLots.ProductionLot IS NULL
		|			THEN UNDEFINED
		|			ELSE T.DimensionOfExpenses
		|	END, // DimensionOfExpenses
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.GLAccountSettings,
		|	CASE
		|		WHEN FALSE THEN T.CorLineOfBusiness
		|		WHEN VALUETYPE(T.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
		|		  AND T.DimensionOfExpenses <> VALUE(Catalog.ProductionLots.EmptyRef)
		|		  AND ProductionLots.ProductionLot IS NULL
		|		  AND VALUETYPE(T.CorLot) = TYPE(Catalog.ProductionLots)
		|			THEN ISNULL(CAST(T.CorLot AS Catalog.ProductionLots).Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness, T.CorLineOfBusiness)
		|	END, // CorLineOfBusiness
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID
		|HAVING
		|	SUM(T.Count) <> 0
		|
		|INDEX BY
		|	Lot,
		|	ItemsLocationAttributes
		|";
	QueriesTexts.Add(QueryTextTTFIFOWriteOffsAndOtherDisposals);
		
	#EndRegion
	
	// We will prepare a combined detailed table of all FIFO disposal areas (Balances, sales, write-off and other disposals).
	#Region TTFIFOInDetail
	
	QueryTextOfTTFIFOInDetail = "
		|SELECT
		|	""1"" AS RequestSource,
		|	TRUE AS ThisIsOutlier,
		|	T.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffLowCostInventoryAsExpensesInThePurchaseMonth) AS WriteOffForExpensesOfLowValueGoodsAndMaterials,
		|	FALSE AS ThisIsImplementation,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.Characteristic,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	SUM(T.Count) AS Count,
		|
		|	T.CorVATActivityTypes,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.Department,
		|	CASE
		|		WHEN T.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods)
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN UNDEFINED
		|		WHEN ExpenseItems.Ref IS NULL
		|		  OR ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods)
		|			ELSE T.ExpenseItemOfWriteOff
		|	END AS LocalDepreciationExpenseItem,
		|	CASE
		|		WHEN T.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods)
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN UNDEFINED
		|		WHEN ExpenseItems.Ref IS NULL
		|		  OR ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods)
		|			ELSE T.ExpenseItemOfWriteOff
		|	END AS ItemOfExpenditureWriteOffMan,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN UNDEFINED
		|		WHEN ExpenseItems.Ref IS NULL
		|		 OR ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|		 OR ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			THEN T.Products
		|			ELSE T.DimensionOfExpenses
		|	END AS DimensionOfExpenses,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN T.AssetAndLiabilityItem
		|			ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
		|	END AS AssetAndLiabilityItem,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN T.AssetsLiabilitiesDimension
		|			ELSE UNDEFINED
		|	END AS AssetsLiabilitiesDimension,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN T.GLAccountSettings
		|			ELSE UNDEFINED
		|	END AS GLAccountSettings,
		|	T.CorLineOfBusiness,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Manager,
		|	UNDEFINED AS Warehouse,
		|	UNDEFINED AS Terms,
		|	UNDEFINED AS Contract,
		|	UNDEFINED AS InventoryType,
		|	UNDEFINED AS CounterpartyLineOfBusiness,
		|	UNDEFINED AS ProductLineOfBusiness,
		|	UNDEFINED AS SourceOfProductFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	DATETIME(1,1,1) AS AdjustmentPeriod_
		|
		|INTO TTFIFOInDetail
		|FROM
		|	TTFIFOWriteOffsAndOtherDisposals AS T
		|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|		ON T.ExpenseItemOfWriteOff = ExpenseItems.Ref
		|	LEFT JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
		|		ON T.AssetAndLiabilityItem = AssetLiabilityItems.Ref
		|GROUP BY
		|	T.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffLowCostInventoryAsExpensesInThePurchaseMonth),
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.Characteristic,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	T.CorVATActivityTypes,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.Department,
		|	CASE
		|		WHEN T.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods)
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN UNDEFINED
		|		WHEN ExpenseItems.Ref IS NULL
		|		  OR ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods)
		|			ELSE T.ExpenseItemOfWriteOff
		|	END,
		|	CASE
		|		WHEN T.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods)
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN UNDEFINED
		|		WHEN ExpenseItems.Ref IS NULL
		|		  OR ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods)
		|			ELSE T.ExpenseItemOfWriteOff
		|	END,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN UNDEFINED
		|		WHEN ExpenseItems.Ref IS NULL
		|		 OR ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|		 OR ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			THEN T.Products
		|			ELSE T.DimensionOfExpenses
		|	END,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN T.AssetAndLiabilityItem
		|			ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
		|	END,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN T.AssetsLiabilitiesDimension
		|			ELSE UNDEFINED
		|	END,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN T.GLAccountSettings
		|			ELSE UNDEFINED
		|	END,
		|	T.CorLineOfBusiness,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID
		|HAVING
		|	SUM(T.Count) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	""2"" AS RequestSource,
		|	TRUE AS ThisIsOutlier,
		|	FALSE AS WriteOffForExpensesOfLowValueGoodsAndMaterials,
		|	TRUE AS ThisIsImplementation,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.Characteristic,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	T.Count,
		|
		|	T.CorVATActivityTypes AS CorVATActivityTypes,
		|	T.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.AccountingSection AS CorAccountingSection,
		|	T.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	T.Organization AS CorCompany,
		|	T.CorLot AS CorLot,
		|	T.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	T.FinancialAccountingDimension AS CorControllingAttributes,
		|	T.Department AS Department,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS LocalDepreciationExpenseItem,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ItemOfExpenditureWriteOffMan,
		|	UNDEFINED AS DimensionOfExpenses,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS GLAccountSettings,
		|	UNDEFINED AS CorLineOfBusiness,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.Manager,
		|	T.Warehouse,
		|	T.Terms,
		|	T.Contract,
		|	T.InventoryType,
		|	T.CounterpartyLineOfBusiness,
		|	T.ProductLineOfBusiness,
		|	T.SourceOfProductFinancialAccountingGroup,
		|	T.SourceOfARAPFinancialAccountingGroup,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	BEGINOFPERIOD(T.Period, MONTH) AS AdjustmentPeriod_
		|FROM
		|	TTFIFOOfImplementationOfPastPeriods AS T
		|
		|UNION ALL
		|
		|SELECT
		|	""3"" AS RequestSource,
		|	FALSE AS ThisIsOutlier,
		|	FALSE AS WriteOffForExpensesOfLowValueGoodsAndMaterials,
		|	FALSE AS ThisIsImplementation,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.Characteristic,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	T.Count,
		|
		|	UNDEFINED AS CorVATActivityTypes,
		|	T.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.AccountingSection AS CorAccountingSection,
		|	T.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	T.Organization AS CorCompany,
		|	T.CorLot AS CorLot,
		|	T.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	T.FinancialAccountingDimension AS CorControllingAttributes,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS LocalDepreciationExpenseItem,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ItemOfExpenditureWriteOffMan,
		|	UNDEFINED AS DimensionOfExpenses,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS GLAccountSettings,
		|	UNDEFINED AS CorLineOfBusiness,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Manager,
		|	UNDEFINED AS Warehouse,
		|	UNDEFINED AS Terms,
		|	UNDEFINED AS Contract,
		|	UNDEFINED AS InventoryType,
		|	UNDEFINED AS CounterpartyLineOfBusiness,
		|	UNDEFINED AS ProductLineOfBusiness,
		|	UNDEFINED AS SourceOfProductFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		|	VALUE(Enum.BusinessTransactions.InventoryTransfer) AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.InventoryTransfer) AS BusinessTransactionSetting,
		|	UNDEFINED AS FinRecordID,
		|	DATETIME(1,1,1) AS AdjustmentPeriod_
		|FROM
		|	TTFIFOCostBalance AS T
		|INDEX BY
		|	Lot
		|";
	QueriesTexts.Add(QueryTextOfTTFIFOInDetail);
		
	#EndRegion
	
	// We will prepare a summary table of all FIFO disposal areas (to determine the proportion of each detailed disposal).
	// The fields of the pivot table must correspond to all the fields of its relationship in the indicator base of the receivers of the past periods.
	#Region TTFIFOSummary
	
	QueryTextOfTTFIFOIsSummarized = "
		|SELECT
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	SUM(T.Count) AS Count
		|INTO TTFIFOSummary
		|FROM
		|	(SELECT
		|		T.Organization,
		|		T.Products,
		|		T.Characteristic,
		|		T.Lot AS Lot,
		|		T.LotVendorAttributes AS LotVendorAttributes,
		|		T.Count
		|	FROM
		|		TTFIFOInDetail AS T
		|	
		|	UNION ALL
		|
		|	SELECT
		|		T.Organization,
		|		T.Products,
		|		T.Characteristic,
		|		T.CorLot AS Lot,
		|		T.LotVendorAttributesCorr AS LotVendorAttributes,
		|		T.Count
		|	FROM
		|		TTFIFOInDetail AS T
		|	WHERE
		|		(T.ThisIsImplementation OR NOT T.ThisIsOutlier)
		|		AND T.Lot <> T.CorLot
		|	) AS T
		|GROUP BY
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.Lot,
		|	T.LotVendorAttributes
		|HAVING
		|	SUM(T.Count) > 0
		|INDEX BY
		|	Lot
		|";
	QueriesTexts.Add(QueryTextOfTTFIFOIsSummarized);
		
	#EndRegion

	#Region OnAverage
	
	QueryTextOnAverage =
		"SELECT DISTINCT
		|	WriteOffs.ItemsLocationAttributes,
		|	WriteOffs.AccountingSection,
		|	WriteOffs.InventoryOwnerAttribute,
		|	WriteOffs.Organization,
		|	WriteOffs.Lot,
		|	WriteOffs.LotVendorAttributes,
		|	WriteOffs.FinancialAccountingDimension,
		|	WriteOffs.VATActivityType,
		|
		|	WriteOffs.Department,
		|	WriteOffs.ExpenseItemOfWriteOff,
		|	WriteOffs.DimensionOfExpenses AS DimensionOfExpenses,
		|	WriteOffs.CorLineOfBusiness,
		|	WriteOffs.BusinessOperation,
		|	WriteOffs.FinRecordID,
		|	WriteOffs.BusinessTransactionSetting
		|INTO RegisteredRecordsTTAreWrittenOffForExpensesOfLowValueInventory
		|FROM
		|	AccumulationRegister.InventoryCost AS WriteOffs
		|	INNER JOIN TTMethodsOfEstimatingValueOfOrganizationsByPeriod AS ValuationMethods
		|	ON ValuationMethods.Organization = WriteOffs.Organization
		|		AND &EndOfPreviousPeriod >= ValuationMethods.BeginOfPeriod
		|		AND &EndOfPreviousPeriod < ValuationMethods.EndOfPeriod
		|		AND ValuationMethods.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.AveragePerMonth)
		|WHERE
		|	WriteOffs.Period = &EndOfPreviousPeriod
		|	AND WriteOffs.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffLowCostInventoryAsExpensesInThePurchaseMonth)
		|	AND NOT WriteOffs.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|
		|INDEX BY
		|	Lot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE WHEN WriteOffs.ItemsLocationAttributes IS NULL THEN FALSE ELSE TRUE END AS ThereIsWriteOff,
		|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	WriteOffs.Department,
		|	WriteOffs.ExpenseItemOfWriteOff,
		|	WriteOffs.DimensionOfExpenses,
		|	WriteOffs.CorLineOfBusiness,
		|	WriteOffs.BusinessOperation,
		|	WriteOffs.FinRecordID,
		|	WriteOffs.BusinessTransactionSetting,
		|
		|	DD.Count AS Count
		|INTO TT_InventoryCostsBalanceOfPreviousPeriodWithWriteOffOfLowValueInventory
		|FROM
		|	TTCostBalancePreliminary AS DD
		|	LEFT JOIN RegisteredRecordsTTAreWrittenOffForExpensesOfLowValueInventory AS WriteOffs
		|		ON WriteOffs.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|		AND WriteOffs.AccountingSection = DD.AccountingSection
		|		AND WriteOffs.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|		AND WriteOffs.Organization = DD.Organization
		|		AND WriteOffs.Lot = DD.Lot
		|		AND WriteOffs.LotVendorAttributes = DD.LotVendorAttributes
		|		AND WriteOffs.FinancialAccountingDimension = DD.FinancialAccountingDimension
		|		AND WriteOffs.VATActivityType = DD.VATActivityType
		|
		|INDEX BY
		|	ItemsLocationAttributes
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Organization AS Organization,
		|	DD.Lot AS Lot,
		|	DD.LotVendorAttributes AS LotVendorAttributes,
		|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.ItemsLocationAttributes.Products AS Products,
		|	DD.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	DD.ItemsLocationAttributes.Series AS Series,
		|	MIN(DD.ReceiptPeriod) AS ReceiptPeriod
		|INTO TTSelectionOfAnalyticsForMovingBetweenOrganizations
		|FROM
		|	ReceiversForProductsOfPastPeriods AS DD
		|WHERE
		|	DD.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.AveragePerMonth)
		|	
		|GROUP BY
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.ItemsLocationAttributes.Products,
		|	DD.ItemsLocationAttributes.CHARACTERISTIC,
		|	DD.ItemsLocationAttributes.Series
		|INDEX BY
		|	Lot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		// With the "Monthly Average" cost estimation method, you need to check for movements in changing analytics.
		// When distributing goods to disposals in the past period, you need to take into account the presence of changes in analytics.
		// If there were no changes to the analytics, additional costs should be allocated only to the original analytics of the acquisition document. 
		|SELECT DISTINCT
		|	DD.Organization AS Organization,
		|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.ItemsLocationAttributes AS ItemsLocationAttributes
		|
		|INTO TUEThereAreMovesBetweenAnalysts
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|	INNER JOIN ReceiversForProductsOfPastPeriods AS Filter
		|		ON Filter.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|		AND Filter.Organization = DD.Organization
		|		AND Filter.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|		AND Filter.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.AveragePerMonth)
		|WHERE
		|	&AllocationOfAdditionalExpensesByDisposedGoods
		|	AND DD.Period BETWEEN Filter.ReceiptPeriod AND &EndOfPreviousPeriod
		|	AND DD.Organization IN(&CompanyArray)
		|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND DD.Lot = UNDEFINED
		|	AND DD.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|	AND (DD.AccountingSection = DD.CorAccountingSection
		|		OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
		|		OR DD.CorAccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners))
		|		)
		|	AND DD.CorItemsLocationAttributes.StorageType <> VALUE(Enum.StorageLocationTypes.Partner)
		|	AND DD.ItemsLocationAttributes.Products = DD.CorItemsLocationAttributes.Products
		|	AND DD.ItemsLocationAttributes.Characteristic = DD.CorItemsLocationAttributes.Characteristic
		|	AND NOT DD.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|;
		|////////////////////////////////////////////////////////////////////////////////
		// With the "Monthly Average" cost estimation method, it is necessary to check for movements to change the activity type of VAT.
		// When allocating goods for disposal in the past period, it is necessary to take into account the presence of changes in the activity type of VAT.
		// If there have been no changes to the activity type, add. expenses should be allocated only to the initial activity type of VAT. 
		|SELECT DISTINCT
		|	DD.Organization AS Organization,
		|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.ItemsLocationAttributes AS ItemsLocationAttributes
		|
		|INTO TTChangesInVATActivityType
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|	INNER JOIN ReceiversForProductsOfPastPeriods AS Filter
		|		ON Filter.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.AveragePerMonth)
		|		AND Filter.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|		AND Filter.Organization = DD.Organization
		|		AND Filter.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|WHERE
		|	&AllocationOfAdditionalExpensesByDisposedGoods
		|	AND DD.Period BETWEEN Filter.ReceiptPeriod AND &EndOfPreviousPeriod
		|	AND DD.Organization IN(&CompanyArray)
		|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND DD.Lot = UNDEFINED
		|	AND DD.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|	AND (DD.AccountingSection = DD.CorAccountingSection
		|		OR DD.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		OR DD.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)
		|		OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller))
		|	AND DD.CorVATActivityTypes <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	AND DD.VATActivityType <> DD.CorVATActivityTypes
		|	AND NOT DD.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|
		|INDEX BY
		|	Organization,
		|	InventoryOwnerAttribute,
		|	ItemsLocationAttributes
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT DISTINCT
		|	""1"" AS RequestSource,
		|	DD.Organization AS Organization,
		|	DD.Lot AS OriginalBatch,
		|	DD.LotVendorAttributes AS LottingVendorAttributeIsInitialOne,
		|	DD.CorLot AS Lot,
		|	DD.LotVendorAttributesCorr AS LotVendorAttributes,
		|	DD.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.CorItemsLocationAttributes.Products AS Products,
		|	DD.CorItemsLocationAttributes.Characteristic AS Characteristic,
		|	DD.CorItemsLocationAttributes.Series AS Series
		|INTO TTMovementBetweenOrganizations
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|	INNER JOIN Document.ReceiptOfGoodsToWarehouse AS Inflow
		|		ON DD.Recorder = Inflow.Ref
		|	INNER JOIN TTSelectionOfAnalyticsForMovingBetweenOrganizations AS Filter
		|		ON DD.Lot = Filter.Lot
		|		AND DD.LotVendorAttributes = Filter.LotVendorAttributes
		|		AND DD.ItemsLocationAttributes.Products = Filter.Products
		|		AND DD.ItemsLocationAttributes.Characteristic = Filter.Characteristic
		|		AND (DD.ItemsLocationAttributes.Series = Filter.Series
		|			OR DD.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
		|		AND DD.ItemsLocationAttributes.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
		|WHERE
		|	DD.Period BETWEEN Filter.ReceiptPeriod AND &EndOfPreviousPeriod
		|	AND DD.Organization IN (&OrganizationsMonthlyAverage)
		|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|	AND NOT DD.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|
		|UNION
		|
		|SELECT DISTINCT
		|	""2"" AS RequestSource,
		|	DD.Organization AS Organization,
		|	DD.Lot AS OriginalBatch,
		|	DD.LotVendorAttributes AS LottingVendorAttributeIsInitialOne,
		|	DD.CorLot AS Lot,
		|	DD.LotVendorAttributesCorr AS LotVendorAttributes,
		|	DD.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.CorItemsLocationAttributes.Products AS Products,
		|	DD.CorItemsLocationAttributes.Characteristic AS Characteristic,
		|	DD.CorItemsLocationAttributes.Series AS Series
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|	INNER JOIN Document.ReceiptOfGoodsFromCustodian AS Inflow
		|		ON DD.Recorder = Inflow.Ref
		|	INNER JOIN TTSelectionOfAnalyticsForMovingBetweenOrganizations AS Filter
		|		ON DD.Lot = Filter.Lot
		|		AND DD.LotVendorAttributes = Filter.LotVendorAttributes
		|		AND DD.ItemsLocationAttributes.Products = Filter.Products
		|		AND DD.ItemsLocationAttributes.Characteristic = Filter.Characteristic
		|		AND (DD.ItemsLocationAttributes.Series = Filter.Series
		|			OR DD.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
		|		AND DD.ItemsLocationAttributes.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
		|WHERE
		|	DD.Period BETWEEN Filter.ReceiptPeriod AND &EndOfPreviousPeriod
		|	AND DD.Organization IN (&OrganizationsMonthlyAverage)
		|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
		|	AND DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SubcontractorProducts)
		|	AND NOT DD.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|
		|UNION
		|
		|SELECT DISTINCT
		|	""3"" AS RequestSource,
		|	DD.Organization AS Organization,
		|	DD.Lot AS OriginalBatch,
		|	DD.LotVendorAttributes AS LottingVendorAttributeIsInitialOne,
		|	DD.CorLot AS Lot,
		|	DD.LotVendorAttributesCorr AS LotVendorAttributes,
		|	DD.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.CorItemsLocationAttributes.Products AS Products,
		|	DD.CorItemsLocationAttributes.Characteristic AS Characteristic,
		|	DD.CorItemsLocationAttributes.Series AS Series
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|	INNER JOIN TTSelectionOfAnalyticsForMovingBetweenOrganizations AS Filter
		|		ON DD.Lot = Filter.Lot
		|		AND DD.LotVendorAttributes = Filter.LotVendorAttributes
		|		AND DD.Organization = Filter.Organization
		|		AND DD.ItemsLocationAttributes.Products = Filter.Products
		|		AND DD.ItemsLocationAttributes.Characteristic = Filter.Characteristic
		|		AND (DD.ItemsLocationAttributes.Series = Filter.Series
		|			OR DD.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
		|WHERE
		|	DD.Period BETWEEN Filter.ReceiptPeriod AND &EndOfPreviousPeriod
		|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND DD.EntryType = VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod)
		|	AND NOT DD.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		
		|
		|UNION
		|
		|SELECT DISTINCT
		|	""4"" AS RequestSource,
		|	DD.Organization AS Organization,
		|	DD.Lot AS OriginalBatch,
		|	DD.LotVendorAttributes AS LottingVendorAttributeIsInitialOne,
		|	DD.Lot AS Lot,
		|	DD.LotVendorAttributes AS LotVendorAttributes,
		|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.Products AS Products,
		|	DD.Characteristic AS Characteristic,
		|	DD.Series AS Series
		|FROM
		|	TTSelectionOfAnalyticsForMovingBetweenOrganizations AS DD
		|
		|INDEX BY
		|	Products,
		|	Lot,
		|	Characteristic
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Dimension.Products,
		|	Dimension.Characteristic,
		|	Dimension.Series,
		|	Dimension.Ref AS ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot AS OriginalBatch,
		|	(CASE
		|		WHEN DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 OR DD.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
		|		 OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		 OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|			THEN DD.Lot
		|		ELSE UNDEFINED END) AS Lot,
		|	(CASE
		|		WHEN DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 OR DD.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
		|		 OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		 OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|			THEN DD.LotVendorAttributes
		|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) END) AS LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	MIN(DD.ReceiptPeriod) AS ReceiptPeriod
		|
		|INTO ReceiversForGoodsOfPreviousPeriodsWithNomenclature
		|FROM
		|	ReceiversForProductsOfPastPeriods AS DD
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = DD.ItemsLocationAttributes
		|WHERE
		|	DD.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.AveragePerMonth)
		|
		|GROUP BY
		|	Dimension.Products,
		|	Dimension.Characteristic,
		|	Dimension.Series,
		|	Dimension.Ref,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	(CASE
		|		WHEN DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 OR DD.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
		|		 OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		 OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|			THEN DD.Lot
		|		ELSE UNDEFINED END),
		|	(CASE
		|		WHEN DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 OR DD.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
		|		 OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		 OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|			THEN DD.LotVendorAttributes
		|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) END),
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType
		|
		|INDEX BY
		|	Products,
		|	OriginalBatch,
		|	Characteristic
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	DD.Products,
		|	DD.Characteristic,
		|	DD.Series,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.OriginalBatch,
		|	DD.Lot AS Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	Transfers.Organization AS OrganizationOfMovement,
		|	Transfers.InventoryOwnerAttribute AS TypeOfMovementStocks,
		|	Transfers.Lot AS LotTransfer,
		|	Transfers.LotVendorAttributes AS LotsVendorAttributeOfMoveIsAnalysisOfAccountingOfParties,
		|	(CASE
		|		WHEN DD.OriginalBatch = UNDEFINED AND WThereAreMovements.Organization IS NULL THEN FALSE
		|		ELSE TRUE END) AS ThereAreInventoryTransfer,
		|
		|	DD.ReceiptPeriod
		|
		|INTO ReceiversForGoodsOfPreviousPeriodsWithMovements
		|FROM
		|	ReceiversForGoodsOfPreviousPeriodsWithNomenclature AS DD
		|	INNER JOIN TTMovementBetweenOrganizations AS Transfers
		|		ON Transfers.Products = DD.Products
		|		AND (Transfers.OriginalBatch = DD.OriginalBatch
		|			OR Transfers.OriginalBatch = UNDEFINED)
		|		AND Transfers.Characteristic = DD.Characteristic
		|		AND (Transfers.Series = DD.Series
		|			OR Transfers.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|			OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|			OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller))
		|	LEFT JOIN TUEThereAreMovesBetweenAnalysts AS WThereAreMovements
		|		ON WThereAreMovements.Organization = DD.Organization
		|		AND WThereAreMovements.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|		AND WThereAreMovements.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|		AND DD.OriginalBatch = UNDEFINED
		|WHERE
		|	NOT (Transfers.OriginalBatch = UNDEFINED AND Transfers.Organization <> DD.Organization)
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	DD.Products,
		|	DD.Characteristic,
		|	DD.Series,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.OriginalBatch,
		|	DD.Lot AS Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.OrganizationOfMovement,
		|	DD.TypeOfMovementStocks,
		|	DD.LotTransfer,
		|	DD.LotsVendorAttributeOfMoveIsAnalysisOfAccountingOfParties,
		|	DD.InventoryOwnerAttribute AS TypeOfReceiverStocks,
		|	DD.ThereAreInventoryTransfer,
		|	DD.ReceiptPeriod
		|INTO ReceiversForProductsOfPreviousPeriodsAugmented
		|FROM
		|	ReceiversForGoodsOfPreviousPeriodsWithMovements AS DD
		|
		|UNION ALL
		|
		|SELECT
		|	DD.Products,
		|	DD.Characteristic,
		|	DD.Series,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.OriginalBatch,
		|	DD.Lot AS Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.OrganizationOfMovement,
		|	DD.TypeOfMovementStocks,
		|	DD.LotTransfer,
		|	DD.LotsVendorAttributeOfMoveIsAnalysisOfAccountingOfParties,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS TypeOfReceiverStocks,
		|	DD.ThereAreInventoryTransfer,
		|	DD.ReceiptPeriod
		|FROM
		|	ReceiversForGoodsOfPreviousPeriodsWithMovements AS DD
		|WHERE
		|	 DD.InventoryOwnerAttribute <> VALUE(Catalog.InventoryKinds.EmptyRef)
		|
		|INDEX BY
		|	LotTransfer
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	RegisterRecords.EntryType <> VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod) AS ThisIsOutlier,
		|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.TypeOfReceiverStocks AS InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot AS Lot,
		|	DD.LotVendorAttributes AS LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	RegisterRecords.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	RegisterRecords.AccountingSection AS CorAccountingSection,
		|	RegisterRecords.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	RegisterRecords.Organization AS CorCompany,
		|	CASE WHEN RegisterRecords.EntryType = VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod)
		|		THEN RegisterRecords.CorVATActivityTypes
		|		ELSE RegisterRecords.VATActivityType
		|	END AS CorVATActivityTypes,
		|	CASE WHEN RegisterRecords.EntryType = VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod)
		|		THEN RegisterRecords.CorLot
		|		ELSE RegisterRecords.Lot
		|	END AS CorLot,
		|	CASE WHEN RegisterRecords.EntryType = VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod)
		|		THEN RegisterRecords.LotVendorAttributesCorr
		|		ELSE RegisterRecords.LotVendorAttributes
		|	END AS LotVendorAttributesCorr,
		|
		|	MIN(DD.ReceiptPeriod) AS ReceiptPeriod
		|
		|INTO PossibleReceiverAnalyticsForProductsOfPastPeriods
		|FROM
		|	ReceiversForProductsOfPreviousPeriodsAugmented AS DD
		|	INNER JOIN AccumulationRegister.InventoryCost AS RegisterRecords
		|		ON RegisterRecords.Period BETWEEN DD.ReceiptPeriod AND &EndOfPreviousPeriod
		// The conditions for the accounting section must be the same as the function of the template text, the primary acceptor of the documents().
		|		AND NOT RegisterRecords.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing))
		|		AND (NOT RegisterRecords.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping) 
		|				OR RegisterRecords.InventoryOwnerAttribute.InventoryType IN (
		|				VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider), 
		|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)))
		|		AND RegisterRecords.Lot = DD.LotTransfer
		// When accounting for the average for goods in transit and for non-processing, the batch and batch accounting analytics are empty
		|		AND (RegisterRecords.LotVendorAttributes = DD.LotsVendorAttributeOfMoveIsAnalysisOfAccountingOfParties
		|			OR (DD.LotTransfer = UNDEFINED
		|				AND RegisterRecords.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)))
		|		AND RegisterRecords.Organization = DD.OrganizationOfMovement
		|		AND RegisterRecords.InventoryOwnerAttribute = DD.TypeOfMovementStocks
		// When selecting the analysts of the nomenclature, we do not take into account the warehouse - we connect with analysts for all warehouses.
		|		AND RegisterRecords.ItemsLocationAttributes.Products = DD.Products
		|		AND RegisterRecords.ItemsLocationAttributes.Characteristic = DD.Characteristic
		|		AND (RegisterRecords.ItemsLocationAttributes.Series = DD.Series
		|			OR RegisterRecords.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|			OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		// Deviations in the accounting section "Own goods in transit (from suppliers)" should be distributed only to movements
		// with the same Product accounting analytics.
		|		AND NOT (RegisterRecords.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|			AND RegisterRecords.ItemsLocationAttributes <> DD.ItemsLocationAttributes)
		// In the absence of movements (changes in analytics), additional expenses are allocated only to the original analytics of the acquisition document.
		|		AND (DD.ThereAreInventoryTransfer
		|			OR DD.ItemsLocationAttributes = RegisterRecords.ItemsLocationAttributes)
		// Deviations in the cost and additional expenses reflected in the transaction are allocated to the disposal of goods under the same transaction,
		// except for the transfer to production, because there is no accounting for transactions in production.
		// For other types of financial accounting analytics, we do not support the distribution taking into account analytics, because such analytics may change when moving between warehouses.
		|		AND (VALUETYPE(RegisterRecords.FinancialAccountingDimension) = TYPE(Catalog.SalesOpportunitiesToCustomer) AND RegisterRecords.FinancialAccountingDimension = DD.FinancialAccountingDimension
		|			OR RegisterRecords.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			OR VALUETYPE(RegisterRecords.FinancialAccountingDimension) <> TYPE(Catalog.SalesOpportunitiesToCustomer))
		|WHERE
		|	CASE
		|		WHEN NOT &Constant_KeepRecordsOfInventoryCostByAssignments
		|		  OR DD.ReceiptPeriod < &Constant_CostAccountingByAssignmentValidFrom
		|			THEN RegisterRecords.ItemsLocationAttributes.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			ELSE TRUE
		|	END
		|
		|GROUP BY
		|	RegisterRecords.EntryType <> VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod),
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.TypeOfReceiverStocks,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	RegisterRecords.ItemsLocationAttributes,
		|	RegisterRecords.AccountingSection,
		|	RegisterRecords.InventoryOwnerAttribute,
		|	RegisterRecords.Organization,
		|	CASE WHEN RegisterRecords.EntryType = VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod)
		|		THEN RegisterRecords.CorVATActivityTypes
		|		ELSE RegisterRecords.VATActivityType
		|	END,
		|	CASE WHEN RegisterRecords.EntryType = VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod)
		|		THEN RegisterRecords.CorLot
		|		ELSE RegisterRecords.Lot
		|	END,
		|	CASE WHEN RegisterRecords.EntryType = VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod)
		|		THEN RegisterRecords.LotVendorAttributesCorr
		|		ELSE RegisterRecords.LotVendorAttributes
		|	END
		|
		|UNION ALL
		|
		|SELECT
		|	FALSE AS ThisIsOutlier,
		|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	Balance.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	Balance.AccountingSection AS CorAccountingSection,
		|	Balance.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	Balance.Organization AS CorCompany,
		|	Balance.VATActivityType AS CorVATActivityTypes,
		|	Balance.Lot AS CorLot,
		|	Balance.LotVendorAttributes AS LotVendorAttributesCorr,
		|
		|	&EndOfPreviousPeriod AS ReceiptPeriod
		|FROM
		|	ReceiversForProductsOfPreviousPeriodsAugmented AS DD
		|	INNER JOIN TTCostBalancePreliminary AS Balance
		|		ON Balance.Organization = DD.OrganizationOfMovement
		|		AND Balance.Lot = DD.LotTransfer
		// When accounting for the average of goods in transit and non-invoicing, the batch and batch accounting analytics are empty
		|		AND (Balance.LotVendorAttributes = DD.LotsVendorAttributeOfMoveIsAnalysisOfAccountingOfParties
		|			OR (DD.LotTransfer = UNDEFINED
		|				AND Balance.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)))
		|		AND Balance.InventoryOwnerAttribute = DD.TypeOfMovementStocks
		// The conditions for the accounting section must be the same as the function of the template text, the primary acceptor of the documents().
		|		AND NOT Balance.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing))
		// We Exclude The Balances Of Goods transferred To the processor during Processing 2.4, because Such Balances Are Reflected by The partner and
		// it is Not possible to Fill out the counterparty in the accounting entries for the distribution of Additional Codes.
		|		AND NOT (Balance.AccountingSection  = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
		|			AND Balance.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner))
		|		AND (NOT Balance.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping) 
		|				OR Balance.InventoryOwnerAttribute.InventoryType IN (
		|				VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider), 
		|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)))
		// When selecting the analysts of the nomenclature, we do not take into account the warehouse - we connect with analysts for all warehouses.
		|		AND Balance.ItemsLocationAttributes.Products = DD.Products
		|		AND Balance.ItemsLocationAttributes.CHARACTERISTIC = DD.Characteristic
		|		AND (Balance.ItemsLocationAttributes.Series = DD.Series
		|			OR Balance.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|			OR DD.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|			OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		// Deviations in the accounting section "Own goods in transit (from suppliers)" should be distributed only to Balances
		// with the same Product accounting analytics.
		|		AND NOT (Balance.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|			AND Balance.ItemsLocationAttributes <> DD.ItemsLocationAttributes)
		// In the absence of movements (changes in analytics), additional expenses are allocated only to the original analytics of the acquisition document.
		|		AND (DD.ThereAreInventoryTransfer
		|			OR DD.ItemsLocationAttributes = Balance.ItemsLocationAttributes)
		|WHERE
		|	(DD.TypeOfReceiverStocks <> VALUE(Catalog.InventoryKinds.EmptyRef)
		|		OR DD.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
		|	AND CASE
		|		WHEN NOT &Constant_KeepRecordsOfInventoryCostByAssignments
		|		  OR DD.ReceiptPeriod < &Constant_CostAccountingByAssignmentValidFrom
		|			THEN Balance.ItemsLocationAttributes.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			ELSE TRUE
		|	END
		|
		|GROUP BY
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	Balance.ItemsLocationAttributes,
		|	Balance.AccountingSection,
		|	Balance.InventoryOwnerAttribute,
		|	Balance.Organization,
		|	Balance.VATActivityType,
		|	Balance.Lot,
		|	Balance.LotVendorAttributes
		|
		|INDEX BY
		|	ItemsLocationAttributes
		|;
		|
		|SELECT
		|	Analysts.CorItemsLocationAttributes AS ItemsLocationAttributes,
		|	Analysts.CorAccountingSection AS AccountingSection,
		|	Analysts.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Analysts.CorCompany AS Organization,
		|	Analysts.CorLot AS Lot,
		|	Analysts.LotVendorAttributesCorr AS LotVendorAttributes,
		|
		|	MIN(Analysts.ReceiptPeriod) AS ReceiptPeriod
		|INTO ReceiverAnalyticsForProductsOfPastPeriods
		|FROM
		|	PossibleReceiverAnalyticsForProductsOfPastPeriods AS Analysts
		|
		|GROUP BY
		|	Analysts.CorItemsLocationAttributes,
		|	Analysts.CorAccountingSection,
		|	Analysts.CorInventoryOwnerAttribute,
		|	Analysts.CorCompany,
		|	Analysts.CorLot,
		|	Analysts.LotVendorAttributesCorr
		|
		|INDEX BY
		|	ItemsLocationAttributes
		|;
		
		// Description of the formation of a temporary table of past sales of goods when accounting "On average.
		// The tables of past product releases contain a base for the distribution of additional costs and deviations in value
		// if the goods were disposed of in the previous period. 
		// A disposal is considered an expense from the register of the Cost of goods that is not related to a change in the accounting analysis of the nomenclature.
		// Is not considered a disposal:
		//	- Movement of goods between warehouses, except for movement between branches when accounting for the average cost,
		//		because when accounting for the average cost, it is not possible to track the movement of goods by branches
		//	- Change of destination of goods
		//	- Transfer and return of materials to production (to the workshop pantry or to the division)
		//	- Transfer of products from production (from the workshop pantry or VT division)
		//	- Transmission for response. Storage and return with storage response
		//	
		// Initial data for past disposals of goods:
		// Balance sections of accounting:
		//	- Inventory items - all disposals, except transfers between analysts
		//	- The goods transferred by the commission are not included in the distribution base, 
		//		because it is not yet supported in Local accounting in terms of generating buh transactions for attributing deviations
		//	- Production costs - all disposals, except movements between analysts
		//	- Goods transferred to the processor - all disposals, except movements between analysts
		//	- Goods halfway - all disposals
		//	- Incomplete production - is not included in the distribution base, 
		//		because the distribution to production lots is considered to be a disposal
		//	- Own goods on the way - is not included in the distribution base, because there are no disposals from this section, 
		//		there is only a receipt to the warehouse (moving between analysts)
		//	- Unfactated deliveries - are not included in the distribution base, because there are no disposals from this section
		//	- Own goods transferred to partners - all disposals, except returns to the warehouse
		//	- Goods transferred by way of commission - all disposals, except returns to the warehouse
		// Off-balance sheet accounting sections are not included in the distribution database
		//	Goods received by Commission, materials received by processing, goods stored in the right sales
		//	The goods have been received, the goods have been stored and the goods have been properly sold to the partners, the goods have been stored and the goods have been properly sold.,
		// 	The goods are accepted by the Commission at the way
		//
		|SELECT
		|	DD.Recorder AS Recorder,
		|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization AS Organization,
		|	DD.Lot AS Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.CorVATActivityTypes,
		|	DD.BusinessOperation,
		|	MAX(DD.FinRecordID) AS FinRecordID,
		|	DD.BusinessTransactionSetting,
		|
		|	CASE
		|		WHEN DD.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN DD.Department
		|		WHEN DD.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.BusinessStructure
		|			THEN DD.CorItemsLocationAttributes.StorageLocation
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses
		|			THEN CAST(DD.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.Partners
		|			THEN CAST(DD.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.CounterpartyContracts
		|			THEN CAST(DD.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|			ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS Department,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.DimensionOfExpenses,
		|	CASE
		|		WHEN FALSE THEN DD.CorLineOfBusiness
		|		WHEN VALUETYPE(DD.CorLot) = TYPE(Catalog.ProductionLots)
		|			THEN ISNULL(CAST(DD.CorLot AS Catalog.ProductionLots).Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE ISNULL(DD.CorItemsLocationAttributes.Purpose.LineOfBusiness, DD.CorLineOfBusiness)
		|	END AS CorLineOfBusiness,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.GLAccountSettings,
		|	SUM(DD.Count) AS Count
		|
		|INTO PastDisposalsOfGoods
		|FROM
		|	ReceiverAnalyticsForProductsOfPastPeriods AS Analysts
		|		INNER JOIN AccumulationRegister.InventoryCost AS DD
		|		ON Analysts.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|			AND Analysts.AccountingSection = DD.AccountingSection
		|			AND Analysts.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|			AND Analysts.Organization = DD.Organization
		|			AND Analysts.Lot = DD.Lot
		|			AND Analysts.LotVendorAttributes = DD.LotVendorAttributes
		|
		|WHERE
		|	&AllocationOfAdditionalExpensesByDisposedGoods
		|	AND DD.Period BETWEEN Analysts.ReceiptPeriod AND &EndOfPreviousPeriod
		|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND NOT DD.AccountingSection IN (&OffBalanceSheetAccountingSections)
		// We exclude balance sections of accounting from which there are no disposals.
		|	AND NOT DD.AccountingSection IN (
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
		// We exclude the implementation with a delayed transfer of ownership.
		|	AND NOT (DD.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)
		|		AND DD.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract))
		|	AND NOT DD.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.TransferToProduction),
		|		VALUE(Enum.BusinessTransactions.ReturnFromProduction),
		|		VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction))
		|	AND (NOT DD.Recorder REFS Document.InventoryTransfer 
		|		OR (DD.Recorder REFS Document.InventoryTransfer
		|				AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)))
		|	AND NOT DD.Recorder REFS Document.InventoryAssignmentAdjustment
		|	AND NOT DD.Recorder REFS Document.TransferOfGoodsToBailee
		|	AND NOT DD.Recorder REFS Document.ReceiptOfGoodsFromCustodian
		|	AND NOT DD.Recorder REFS Document.RegisterAdjustment
		|	AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.EmptyRef)
		|	AND NOT DD.Recorder REFS Document.MovementOfProductsAndMaterials
		|	AND DD.Active
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.CorVATActivityTypes,
		|	DD.BusinessOperation,
		|	DD.BusinessTransactionSetting,
		|	CASE
		|		WHEN DD.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN DD.Department
		|		WHEN DD.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.BusinessStructure
		|			THEN DD.CorItemsLocationAttributes.StorageLocation
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses
		|			THEN CAST(DD.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.Partners
		|			THEN CAST(DD.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.CounterpartyContracts
		|			THEN CAST(DD.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|			ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.DimensionOfExpenses,
		|	CASE
		|		WHEN FALSE THEN DD.CorLineOfBusiness
		|		WHEN VALUETYPE(DD.CorLot) = TYPE(Catalog.ProductionLots)
		|			THEN ISNULL(CAST(DD.CorLot AS Catalog.ProductionLots).Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE ISNULL(DD.CorItemsLocationAttributes.Purpose.LineOfBusiness, DD.CorLineOfBusiness)
		|	END, // CorLineOfBusiness
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.GLAccountSettings
		|
		|HAVING
		|	NOT SUM(DD.Count) = 0
		|
		|UNION ALL
		|
		|SELECT
		|	DD.Recorder,
		|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization AS Organization,
		|	DD.Lot AS Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.CorVATActivityTypes,
		|	DD.BusinessOperation,
		|	MAX(DD.FinRecordID) AS FinRecordID,
		|	DD.BusinessTransactionSetting,
		|
		|	CASE
		|		WHEN DD.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN DD.Department
		|		WHEN DD.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.BusinessStructure
		|			THEN DD.CorItemsLocationAttributes.StorageLocation
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses
		|			THEN CAST(DD.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.Partners
		|			THEN CAST(DD.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.CounterpartyContracts
		|			THEN CAST(DD.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|			ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS Department,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.DimensionOfExpenses,
		|	DD.CorLineOfBusiness,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.GLAccountSettings,
		|	SUM(-DD.Count) AS Count
		|FROM
		|	ReceiverAnalyticsForProductsOfPastPeriods AS Analysts
		|		INNER JOIN AccumulationRegister.InventoryCost AS DD
		|		ON Analysts.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|			AND Analysts.AccountingSection = DD.AccountingSection
		|			AND Analysts.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|			AND Analysts.Organization = DD.Organization
		|			AND Analysts.Lot = DD.Lot
		|			AND Analysts.LotVendorAttributes = DD.LotVendorAttributes
		|
		|WHERE
		|	&AllocationOfAdditionalExpensesByDisposedGoods
		|	AND DD.Period BETWEEN Analysts.ReceiptPeriod AND &EndOfPreviousPeriod
		|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND DD.AccountingSection IN (
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts))
		|	AND DD.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent),
		|		VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
		|		VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods))
		|	AND DD.Active
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.CorVATActivityTypes,
		|	DD.BusinessOperation,
		|	DD.BusinessTransactionSetting,
		|	CASE
		|		WHEN DD.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN DD.Department
		|		WHEN DD.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.BusinessStructure
		|			THEN DD.CorItemsLocationAttributes.StorageLocation
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses
		|			THEN CAST(DD.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.Partners
		|			THEN CAST(DD.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN DD.CorItemsLocationAttributes.StorageLocation REFS Catalog.CounterpartyContracts
		|			THEN CAST(DD.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|			ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.DimensionOfExpenses,
		|	DD.CorLineOfBusiness,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.GLAccountSettings
		|
		|HAVING
		|	NOT SUM(DD.Count) = 0
		|
		|INDEX BY
		|	Recorder
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	TRUE AS ThisIsOutlier,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.CorVATActivityTypes,
		|
		|	DD.Department,
		|	CASE WHEN Revenue.Recorder IS NULL AND (ExpenseItems.Ref IS NULL
		|		OR ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
		|		AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods)
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods)
		|		ELSE DD.ExpenseItemOfWriteOff
		|	END AS LocalDepreciationExpenseItem,
		|	CASE WHEN Revenue.Recorder IS NULL AND (ExpenseItems.Ref IS NULL
		|		OR ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
		|		AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods)
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods)
		|		ELSE DD.ExpenseItemOfWriteOff
		|	END AS ItemOfExpenditureWriteOffMan,
		|	(CASE
		|		WHEN Revenue.Recorder IS NULL AND (ExpenseItems.Ref IS NULL
		|		 OR ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|		 OR ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
		|			THEN DD.ItemsLocationAttributes.Products
		|		ELSE DD.DimensionOfExpenses
		|	END) AS DimensionOfExpenses,
		|	DD.CorLineOfBusiness AS CorLineOfBusiness,
		|	DD.BusinessOperation,
		|	MAX(DD.FinRecordID) AS FinRecordID,
		|	DD.BusinessTransactionSetting,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN DD.AssetAndLiabilityItem
		|			ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
		|	END AS AssetAndLiabilityItem,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN DD.AssetsLiabilitiesDimension
		|			ELSE UNDEFINED
		|	END AS AssetsLiabilitiesDimension,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN DD.GLAccountSettings
		|			ELSE UNDEFINED
		|	END AS GLAccountSettings,
		|
		|	ISNULL(Revenue.AccountingDimensionByPartners, VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)) AS AccountingDimensionByPartners,
		|	ISNULL(Revenue.SalesOrder, UNDEFINED) AS SalesOrder,
		|	ISNULL(Revenue.Manager, UNDEFINED) AS Manager,
		|	ISNULL(Revenue.Warehouse, UNDEFINED) AS Warehouse,
		|	ISNULL(Revenue.Terms, UNDEFINED) AS Terms,
		|	ISNULL(Revenue.Contract, UNDEFINED) AS Contract,
		|	ISNULL(Revenue.InventoryType, UNDEFINED) AS InventoryType,
		|	ISNULL(Revenue.SourceOfProductFinancialAccountingGroup, UNDEFINED) AS SourceOfProductFinancialAccountingGroup,
		|	ISNULL(Revenue.SourceOfARAPFinancialAccountingGroup, UNDEFINED) AS SourceOfARAPFinancialAccountingGroup,
		|	ISNULL(Revenue.CounterpartyLineOfBusiness, UNDEFINED) AS CounterpartyLineOfBusiness,
		|	ISNULL(Revenue.ProductLineOfBusiness, UNDEFINED) AS ProductLineOfBusiness,
		|	ISNULL(BEGINOFPERIOD(Revenue.Period, MONTH), DATETIME(1,1,1)) AS AdjustmentPeriod_,
		|	FALSE AS WriteOffForExpensesOfLowValueGoodsAndMaterials,
		|
		|	SUM(ISNULL(Revenue.Count, DD.Count)) AS Count
		|
		|INTO PastDisposalsOfGoodsDetailed
		|FROM
		|	PastDisposalsOfGoods AS DD
		|	LEFT JOIN AccumulationRegister.RevenueAndCOGS AS Revenue
		|		ON DD.Recorder = Revenue.Recorder
		|		AND DD.ItemsLocationAttributes = Revenue.ItemsLocationAttributes
		|		AND DD.AccountingSection = Revenue.AccountingSection
		|		AND DD.InventoryOwnerAttribute = Revenue.InventoryOwnerAttribute
		|		AND DD.Lot = Revenue.Lot
		|		AND DD.LotVendorAttributes = Revenue.LotVendorAttributes
		|		AND DD.Organization = Revenue.AccountingDimensionByPartners.Organization
		|	LEFT JOIN TTPartnerAnalyticsSelection AS Filter
		|		ON Revenue.AccountingDimensionByPartners = Filter.DimensionKey
		|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|		ON DD.ExpenseItemOfWriteOff = ExpenseItems.Ref
		|	LEFT JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
		|		ON DD.AssetAndLiabilityItem = AssetLiabilityItems.Ref
		|WHERE
		|	Revenue.Recorder IS NULL
		|	OR NOT Filter.DimensionKey IS NULL
		|
		|GROUP BY
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.CorVATActivityTypes,
		|	DD.Department,
		|	CASE WHEN Revenue.Recorder IS NULL AND (ExpenseItems.Ref IS NULL
		|		OR ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
		|		AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods)
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods)
		|		ELSE DD.ExpenseItemOfWriteOff
		|	END,
		|	CASE WHEN Revenue.Recorder IS NULL AND (ExpenseItems.Ref IS NULL
		|		OR ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
		|		AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods)
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostOfPreviousPeriods)
		|		ELSE DD.ExpenseItemOfWriteOff
		|	END,
		|	(CASE
		|		WHEN Revenue.Recorder IS NULL AND (ExpenseItems.Ref IS NULL
		|		 OR ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|		 OR ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
		|			THEN DD.ItemsLocationAttributes.Products
		|		ELSE DD.DimensionOfExpenses
		|	END), // DimensionOfExpenses
		|	DD.CorLineOfBusiness,
		|	DD.BusinessOperation,
		|	DD.BusinessTransactionSetting,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN DD.AssetAndLiabilityItem
		|			ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
		|	END,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN DD.AssetsLiabilitiesDimension
		|			ELSE UNDEFINED
		|	END,
		|	CASE
		|		WHEN NOT AssetLiabilityItems.Ref IS NULL
		|			THEN DD.GLAccountSettings
		|			ELSE UNDEFINED
		|	END,
		|	ISNULL(Revenue.AccountingDimensionByPartners, VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)),
		|	ISNULL(Revenue.SalesOrder, UNDEFINED),
		|	ISNULL(Revenue.Manager, UNDEFINED),
		|	ISNULL(Revenue.Warehouse, UNDEFINED),
		|	ISNULL(Revenue.Terms, UNDEFINED),
		|	ISNULL(Revenue.Contract, UNDEFINED),
		|	ISNULL(Revenue.InventoryType, UNDEFINED),
		|	ISNULL(Revenue.SourceOfProductFinancialAccountingGroup, UNDEFINED),
		|	ISNULL(Revenue.SourceOfARAPFinancialAccountingGroup, UNDEFINED),
		|	ISNULL(Revenue.CounterpartyLineOfBusiness, UNDEFINED),
		|	ISNULL(Revenue.ProductLineOfBusiness, UNDEFINED),
		|	ISNULL(BEGINOFPERIOD(Revenue.Period, MONTH), DATETIME(1,1,1))
		|HAVING
		|	SUM(ISNULL(Revenue.Count, DD.Count)) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	FALSE AS ThisIsOutlier,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	UNDEFINED AS CorVATActivityTypes,
		|
		|	UNDEFINED AS Department,
		|	UNDEFINED AS LocalDepreciationExpenseItem,
		|	UNDEFINED AS ItemOfExpenditureWriteOffMan,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS CorLineOfBusiness,
		|	VALUE(Enum.BusinessTransactions.InventoryTransfer) AS BusinessOperation,
		|	UNDEFINED AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.InventoryTransfer) AS BusinessTransactionSetting,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS GLAccountSettings,
		|
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Manager,
		|	UNDEFINED AS Warehouse,
		|	UNDEFINED AS Terms,
		|	UNDEFINED AS Contract,
		|	UNDEFINED AS InventoryType,
		|	UNDEFINED AS SourceOfProductFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		|	UNDEFINED AS CounterpartyLineOfBusiness,
		|	UNDEFINED AS ProductLineOfBusiness,
		|	DATETIME(1,1,1) AS AdjustmentPeriod_,
		|	DD.ThereIsWriteOff AS WriteOffForExpensesOfLowValueGoodsAndMaterials,
		|
		|	DD.Count AS Count
		|FROM
		|	TT_InventoryCostsBalanceOfPreviousPeriodWithWriteOffOfLowValueInventory AS DD
		|	INNER JOIN ReceiverAnalyticsForProductsOfPastPeriods AS T
		|		ON DD.ItemsLocationAttributes = T.ItemsLocationAttributes
		|		AND DD.AccountingSection = T.AccountingSection
		|		AND DD.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND DD.Organization = T.Organization
		|		AND DD.Lot = T.Lot
		|		AND DD.LotVendorAttributes = T.LotVendorAttributes
		|
		|UNION ALL
		|
		|SELECT
		|	TRUE AS ThisIsOutlier,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	UNDEFINED AS CorVATActivityTypes,
		|
		|	DD.Department AS Department,
		|	DD.ExpenseItemOfWriteOff AS LocalDepreciationExpenseItem,
		|	DD.ExpenseItemOfWriteOff AS ItemOfExpenditureWriteOffMan,
		|	DD.DimensionOfExpenses AS DimensionOfExpenses,
		|	DD.CorLineOfBusiness AS CorLineOfBusiness,
		|	DD.BusinessOperation AS BusinessOperation,
		|	DD.FinRecordID AS FinRecordID,
		|	DD.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS GLAccountSettings,
		|
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Manager,
		|	UNDEFINED AS Warehouse,
		|	UNDEFINED AS Terms,
		|	UNDEFINED AS Contract,
		|	UNDEFINED AS InventoryType,
		|	UNDEFINED AS SourceOfProductFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		|	UNDEFINED AS CounterpartyLineOfBusiness,
		|	UNDEFINED AS ProductLineOfBusiness,
		|	DATETIME(1,1,1) AS AdjustmentPeriod_,
		|	TRUE AS WriteOffForExpensesOfLowValueGoodsAndMaterials,
		|
		|	DD.Count AS Count
		|FROM
		|	TT_InventoryCostsBalanceOfPreviousPeriodWithWriteOffOfLowValueInventory AS DD
		|	INNER JOIN ReceiverAnalyticsForProductsOfPastPeriods AS T
		|		ON DD.ItemsLocationAttributes = T.ItemsLocationAttributes
		|		AND DD.AccountingSection = T.AccountingSection
		|		AND DD.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND DD.Organization = T.Organization
		|		AND DD.Lot = T.Lot
		|		AND DD.LotVendorAttributes = T.LotVendorAttributes
		|WHERE
		|	DD.ThereIsWriteOff
		|;
		|
		|SELECT DISTINCT
		|	T.Recorder,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType
		|INTO ReceiversForGoodsOfPreviousPeriodsCollapsed
		|FROM
		|	ReceiversForProductsOfPastPeriods AS T
		|WHERE
		|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.AveragePerMonth)
		|
		|INDEX BY
		|	ItemsLocationAttributes
		|;
		|
		|SELECT
		|	Source.Recorder,
		|	Source.ItemsLocationAttributes,
		|	Source.AccountingSection,
		|	Source.InventoryOwnerAttribute,
		|	Source.Organization,
		|	Source.Lot,
		|	Source.LotVendorAttributes,
		|	Source.FinancialAccountingDimension,
		|	Source.VATActivityType,
		|
		|	SUM(DisposalOfAssets.Count) AS Count
		|
		|INTO DisposalSummary
		|FROM
		|	ReceiversForGoodsOfPreviousPeriodsCollapsed AS Source
		|
		|		INNER JOIN PossibleReceiverAnalyticsForProductsOfPastPeriods AS PossibleAnalysts
		|		ON Source.ItemsLocationAttributes   = PossibleAnalysts.ItemsLocationAttributes
		|			AND Source.AccountingSection               = PossibleAnalysts.AccountingSection
		|			AND Source.Organization               = PossibleAnalysts.Organization
		|			AND Source.Lot                    = PossibleAnalysts.Lot
		|			AND Source.LotVendorAttributes      = PossibleAnalysts.LotVendorAttributes
		|			AND Source.FinancialAccountingDimension = PossibleAnalysts.FinancialAccountingDimension
		|			AND Source.VATActivityType        = PossibleAnalysts.VATActivityType
		|			AND Source.InventoryOwnerAttribute                = PossibleAnalysts.InventoryOwnerAttribute
		|
		|		INNER JOIN PastDisposalsOfGoodsDetailed AS DisposalOfAssets
		|		ON PossibleAnalysts.CorItemsLocationAttributes = DisposalOfAssets.ItemsLocationAttributes
		|			AND PossibleAnalysts.CorAccountingSection = DisposalOfAssets.AccountingSection
		|			AND PossibleAnalysts.CorInventoryOwnerAttribute = DisposalOfAssets.InventoryOwnerAttribute
		|			AND PossibleAnalysts.CorCompany = DisposalOfAssets.Organization
		|			AND PossibleAnalysts.CorLot = DisposalOfAssets.Lot
		|			AND PossibleAnalysts.LotVendorAttributesCorr = DisposalOfAssets.LotVendorAttributes
		|			AND PossibleAnalysts.ThisIsOutlier = DisposalOfAssets.ThisIsOutlier
		|			AND (DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|				OR NOT DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials)
		|
		|		LEFT JOIN TTChangesInVATActivityType AS VATActivityTypeChange
		|		ON Source.Organization = VATActivityTypeChange.Organization
		|			AND Source.InventoryOwnerAttribute = VATActivityTypeChange.InventoryOwnerAttribute
		|			AND Source.ItemsLocationAttributes = VATActivityTypeChange.ItemsLocationAttributes
		|WHERE
		// The activity type must be the same, except for the cases when the activity type of VAT changes.
		|	(CASE WHEN Source.Organization IN (&MediumSlipOrganizations)
		|		THEN PossibleAnalysts.CorVATActivityTypes
		|		ELSE PossibleAnalysts.VATActivityType END = DisposalOfAssets.VATActivityType
		|		OR NOT VATActivityTypeChange.ItemsLocationAttributes IS NULL)
		|
		|GROUP BY
		|	Source.Recorder,
		|	Source.ItemsLocationAttributes,
		|	Source.AccountingSection,
		|	Source.InventoryOwnerAttribute,
		|	Source.Organization,
		|	Source.Lot,
		|	Source.LotVendorAttributes,
		|	Source.FinancialAccountingDimension,
		|	Source.VATActivityType
		|
		|HAVING
		|	NOT SUM(DisposalOfAssets.Count) = 0
		|";
	
	QueriesTexts.Add(QueryTextOnAverage);
	
	#EndRegion
	
	// Let's prepare the final table of indicators of the base of the distribution of receivers of the past periods for FIFO and for the average.
	#Region IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods
	
	QueryTextIndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods = "
		|SELECT
		|	DisposalOfAssets.ThisIsOutlier AS ThisIsOutlier,
		|
		|	Source.Recorder AS Recorder,
		|	Source.Period,
		|	Source.EntryType,
		// With the FIFO valuation method, the receipt period is filled in with the beginning of the current period, because with FIFO 
		// , the distribution base includes disposal directions in past periods.
		// The Access period field is used when forming Registered Records for the register "Deviations in the cost of items"
		// in the procedure for forming a movement of declination of the value of goods with an additional request().
		|	&BeginOfPeriod AS ReceiptPeriod,
		// Analysis of the distribution of deviations in value, distribution of discarded goods.
		// It is not applicable for additional expenses, because the source of additional expenses is expenses.
		|	CASE WHEN Attributes.Ref IS NULL
		|		THEN Source.ItemsLocationAttributes
		|		ELSE UNDEFINED
		|	END AS ItemsLocationAttributes,
		|	CASE WHEN Attributes.Ref IS NULL
		|		THEN Source.AccountingSection
		|		ELSE UNDEFINED
		|	END AS AccountingSection,
		|	CASE WHEN Attributes.Ref IS NULL
		|		THEN Source.InventoryOwnerAttribute
		|		ELSE UNDEFINED
		|	END AS InventoryOwnerAttribute,
		|	CASE WHEN Attributes.Ref IS NULL
		|		THEN Source.Organization
		|		ELSE UNDEFINED
		|	END AS Organization,
		|	CASE WHEN Attributes.Ref IS NULL
		|		THEN Source.Lot
		|		ELSE UNDEFINED
		|	END AS Lot,
		|	CASE WHEN Attributes.Ref IS NULL
		|		THEN Source.LotVendorAttributes
		|		ELSE UNDEFINED
		|	END AS LotVendorAttributes,
		|	CASE WHEN Attributes.Ref IS NULL
		|		THEN Source.FinancialAccountingDimension
		|		ELSE UNDEFINED
		|	END AS FinancialAccountingDimension,
		|	CASE WHEN Attributes.Ref IS NULL
		|		THEN Source.VATActivityType
		|		ELSE UNDEFINED
		|	END AS VATActivityType,
		|
		|	DisposalOfAssets.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	DisposalOfAssets.AccountingSection AS CorAccountingSection,
		|	DisposalOfAssets.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	DisposalOfAssets.Organization AS CorCompany,
		|	DisposalOfAssets.Lot AS CorLot,
		|	DisposalOfAssets.LotVendorAttributes AS LotVendorAttributesCorr,
		|	DisposalOfAssets.FinancialAccountingDimension AS CorControllingAttributes,
		// When allocating goods to disposals in previous periods, additional expenses are reflected by type of activity of VAT disposals
		// in order to correctly reflect the inclusion/exclusion of VAT in the cost.
		// The inclusion/exclusion of VAT in the cost will be reflected by the movement of goods in warehouses, and not by movement in the direction
		// of the disposal of goods to reduce the number of movements in registers.
		|	(CASE
		|		WHEN DisposalOfAssets.CorVATActivityTypes <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		 AND DisposalOfAssets.CorVATActivityTypes <> UNDEFINED
		|		 AND NOT Source.Organization IN (&MediumSlipOrganizations)
		|			THEN DisposalOfAssets.CorVATActivityTypes
		|		ELSE DisposalOfAssets.VATActivityType END) AS CorVATActivityTypes,
		|	DisposalOfAssets.VATActivityType AS VATTaxationPartySTypeOfActivity,
		|	DisposalOfAssets.CorVATActivityTypes AS TypeOfActivityVATDisposals,
        |
		|	DisposalOfAssets.Department AS Department,
		|	DisposalOfAssets.LocalDepreciationExpenseItem AS LocalDepreciationExpenseItem,
		|	DisposalOfAssets.ItemOfExpenditureWriteOffMan AS ItemOfExpenditureWriteOffMan,
		|	DisposalOfAssets.DimensionOfExpenses AS DimensionOfExpenses,
		|	DisposalOfAssets.AssetAndLiabilityItem AS AssetAndLiabilityItem,
		|	DisposalOfAssets.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	DisposalOfAssets.GLAccountSettings AS GLAccountSettings,
		|	DisposalOfAssets.CorLineOfBusiness AS CorLineOfBusiness,
		|	DisposalOfAssets.BusinessOperation AS BusinessOperation,
		|	CASE
		|		WHEN DisposalOfAssets.FinRecordID = UNDEFINED
		|			THEN Source.FinRecordID
		|		ELSE DisposalOfAssets.FinRecordID
		|	END AS FinRecordID,
		|	CASE
		|		WHEN Source.AdditionalExpensesOfLocalNDSKDistribution <> 0
		|			AND Source.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
		|		THEN VALUE(Catalog.BusinessTransactionsSettings.ExpenseAllocationToCost)
		|		ELSE DisposalOfAssets.BusinessTransactionSetting
		|	END AS BusinessTransactionSetting,
		|	DisposalOfAssets.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DisposalOfAssets.SalesOrder AS SalesOrder,
		|	DisposalOfAssets.Manager AS Manager,
		|	DisposalOfAssets.Warehouse AS Warehouse,
		|	DisposalOfAssets.Terms AS Terms,
		|	DisposalOfAssets.Contract AS Contract,
		|	DisposalOfAssets.InventoryType AS InventoryType,
		|	DisposalOfAssets.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
		|	DisposalOfAssets.ProductLineOfBusiness AS ProductLineOfBusiness,
		|	DisposalOfAssets.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup,
		|	DisposalOfAssets.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
		|	DisposalOfAssets.AdjustmentPeriod_ AS AdjustmentPeriod_,
		|	Source.InventoryValuationMethod AS InventoryValuationMethod,
		|	
		|	ISNULL(DisposalOfAssets.Count, 0) AS NumberOfDetails,
		|	ISNULL(DroppedOutSummary.Count, 0) AS NumberIsSummarized,
		|	CAST(Source.CostToDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(ISNULL(DisposalOfAssets.Count, 0) AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10))
		|		END AS NUMBER(31,2)) AS CostInclVAT,
		|	CAST(Source.CostWithoutNDSKDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(ISNULL(DisposalOfAssets.Count, 0) AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10))
		|		END AS NUMBER(31,2)) AS CostExcludingVAT,
		// For low-value goods and materials, the cost of regl and upr is written off as expenses.
		|	CAST(Source.CostLocalToDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(ISNULL(DisposalOfAssets.Count, 0) AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10))
		|		END AS NUMBER(31,2)) AS LocalCost,
		|	CAST(Source.ManSCostToDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(DisposalOfAssets.Count / DroppedOutSummary.Count AS NUMBER (28, 10))
		|		END AS NUMBER(31,2)) AS CostMan,
		|	Source.QuantityToDistribution
		|		* CAST(CAST(ISNULL(DisposalOfAssets.Count, 0) AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) AS Count,
		|	CAST(Source.AdditionalCostsSNDSKDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(ISNULL(DisposalOfAssets.Count, 0) AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10))
		|		END AS NUMBER(31,2)) AS AdditionalExpensesIncludingVAT,
		|	CAST(Source.AdditionalExpensesWithoutNDSKDISTRIBUTION
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(ISNULL(DisposalOfAssets.Count, 0) AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS AdditionalExpensesExcludingVAT,
		|	CAST(Source.AdditionalExpensesOfLocalNDSKDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(ISNULL(DisposalOfAssets.Count, 0) AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS AddExpensesLocal,
		|	CAST(Source.AdditionalExpensesOfManNDSKDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(ISNULL(DisposalOfAssets.Count, 0) AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS AddExpensesMan,
		|	CAST(Source.VATLocalToDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(ISNULL(DisposalOfAssets.Count, 0) AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS VATLocal,
		|	CAST(Source.VATManForDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(ISNULL(DisposalOfAssets.Count, 0) AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS VATManag,
		|	CAST(Source.ConstantDifferenceToDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(ISNULL(DisposalOfAssets.Count, 0) AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS PermanentDifference,
		|	CAST(CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND DisposalOfAssets.ThisIsOutlier
		|			THEN -(Source.CostLocalToDistribution + Source.AdditionalExpensesOfLocalNDSKDistribution)
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN Source.CostLocalToDistribution + Source.AdditionalExpensesOfLocalNDSKDistribution
		|		ELSE Source.TemporalDifferenceToDistribution END
		|		* CAST(CAST(ISNULL(DisposalOfAssets.Count, 0) AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) AS NUMBER(31,2)) AS CostTD,
		|	CAST(Source.CostOfPersonalIncomeTaxDistribution
		|	 * CASE
		|		WHEN ISNULL(DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials, FALSE) AND NOT ISNULL(DisposalOfAssets.ThisIsOutlier, FALSE)
		|			THEN 0
		|		ELSE CAST(ISNULL(DisposalOfAssets.Count, 0) / DroppedOutSummary.Count AS NUMBER (28, 10)) 
		|		END AS NUMBER(31,2)) AS CostOfPersonalIncomeTax
		|	
		|INTO IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods
		|FROM
		|	ReceiversForProductsOfPastPeriods AS Source
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
		|			ON Source.ItemsLocationAttributes = DimensionOfProductItem.Ref
		|		LEFT JOIN Document.AllocationOfOtherCosts AS Attributes
		|			ON Source.Recorder = Attributes.Ref
		|
		|		INNER JOIN TTFIFOSummary AS DroppedOutSummary
		|			ON Source.Lot						= DroppedOutSummary.Lot
		|			AND Source.LotVendorAttributes			= DroppedOutSummary.LotVendorAttributes
		|			AND DimensionOfProductItem.Products	= DroppedOutSummary.Products
		|			AND DimensionOfProductItem.Characteristic	= DroppedOutSummary.Characteristic
		|			AND (Source.Organization					= DroppedOutSummary.Organization
		|				OR DroppedOutSummary.Lot <> UNDEFINED)
		|
		|		INNER JOIN TTFIFOInDetail AS DisposalOfAssets
		|			ON (Source.Lot						= DisposalOfAssets.Lot
		// For implementation without transfer of ownership, the Lot reference may have already been implemented or may still be in Balance on the way
		// In this case, the source table should be linked to the table of disposals by cor. Lot references
		|				OR ((DisposalOfAssets.ThisIsImplementation OR NOT DisposalOfAssets.ThisIsOutlier)
		|					AND Source.Lot				= DisposalOfAssets.CorLot))
		|			AND (Source.LotVendorAttributes		= DisposalOfAssets.LotVendorAttributes
		|				OR ((DisposalOfAssets.ThisIsImplementation OR NOT DisposalOfAssets.ThisIsOutlier)
		|					AND Source.LotVendorAttributes	= DisposalOfAssets.LotVendorAttributesCorr))
		|			AND DimensionOfProductItem.Products	= DisposalOfAssets.Products
		|			AND DimensionOfProductItem.Characteristic	= DisposalOfAssets.Characteristic
		|			AND DroppedOutSummary.Organization				= DisposalOfAssets.Organization
		|WHERE
		|	Source.Lot <> UNDEFINED
		|	AND Source.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.FIFORollingValuation)
		|
		|UNION ALL
		|
		|SELECT
		|	DisposalOfAssets.ThisIsOutlier AS ThisIsOutlier,
		|
		|	Source.Recorder,
		|	Source.Period,
		|	Source.EntryType,
		// With the "Monthly Average" assessment method, the receipt period is filled in with the beginning of the current period, because with FIFO 
		// , the distribution base includes disposal directions in past periods.
		// The Access period field is used when forming Registered Records for the "Deviations in the value of goods"
		// register in the procedure for forming a movement of declination of the value of goods with an additional request().
		|	&BeginOfPeriod AS ReceiptPeriod,
		// Analysis of the distribution of deviations in value, distribution of discarded goods.
		// It is not applicable for additional expenses, because the source of additional expenses is expenses.
		|	CASE
		|		WHEN Attributes.Ref IS NULL
		|			THEN Source.ItemsLocationAttributes
		|		ELSE
		|			UNDEFINED
		|	END AS ItemsLocationAttributes,
		|	CASE
		|		WHEN Attributes.Ref IS NULL
		|			THEN Source.AccountingSection
		|		ELSE
		|			UNDEFINED
		|	END AS AccountingSection,
		|	CASE
		|		WHEN Attributes.Ref IS NULL
		|			THEN Source.InventoryOwnerAttribute
		|		ELSE
		|			UNDEFINED
		|	END AS InventoryOwnerAttribute,
		|	CASE
		|		WHEN Attributes.Ref IS NULL
		|			THEN Source.Organization
		|		ELSE
		|			UNDEFINED
		|	END AS Organization,
		|	CASE
		|		WHEN Attributes.Ref IS NULL
		|			THEN Source.Lot
		|		ELSE
		|			UNDEFINED
		|	END AS Lot,
		|	CASE
		|		WHEN Attributes.Ref IS NULL
		|			THEN Source.LotVendorAttributes
		|		ELSE
		|			UNDEFINED
		|	END AS LotVendorAttributes,
		|	CASE
		|		WHEN Attributes.Ref IS NULL
		|			THEN Source.FinancialAccountingDimension
		|		ELSE
		|			UNDEFINED
		|	END AS FinancialAccountingDimension,
		|	CASE
		|		WHEN Attributes.Ref IS NULL
		|			THEN Source.VATActivityType
		|		ELSE
		|			UNDEFINED
		|	END AS VATActivityType,
		|
		|	DisposalOfAssets.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	DisposalOfAssets.AccountingSection AS CorAccountingSection,
		|	DisposalOfAssets.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	DisposalOfAssets.Organization AS CorCompany,
		|	DisposalOfAssets.Lot AS CorLot,
		|	DisposalOfAssets.LotVendorAttributes AS LotVendorAttributesCorr,
		|	DisposalOfAssets.FinancialAccountingDimension AS CorControllingAttributes,
		|	(CASE
		|		WHEN DisposalOfAssets.CorVATActivityTypes <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		 AND DisposalOfAssets.CorVATActivityTypes <> UNDEFINED
		|		 AND NOT Source.Organization IN (&MediumSlipOrganizations)
		|			THEN DisposalOfAssets.CorVATActivityTypes
		|		ELSE DisposalOfAssets.VATActivityType END) AS CorVATActivityTypes,
		|	DisposalOfAssets.VATActivityType AS VATTaxationPartySTypeOfActivity,
		|	DisposalOfAssets.CorVATActivityTypes AS TypeOfActivityVATDisposals,
		|
		|	DisposalOfAssets.Department AS Department,
		|	DisposalOfAssets.LocalDepreciationExpenseItem AS LocalDepreciationExpenseItem,
		|	DisposalOfAssets.ItemOfExpenditureWriteOffMan AS ItemOfExpenditureWriteOffMan,
		|	DisposalOfAssets.DimensionOfExpenses AS DimensionOfExpenses,
		|	DisposalOfAssets.AssetAndLiabilityItem AS AssetAndLiabilityItem,
		|	DisposalOfAssets.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	DisposalOfAssets.GLAccountSettings AS GLAccountSettings,
		|	DisposalOfAssets.CorLineOfBusiness AS CorLineOfBusiness,
		|	DisposalOfAssets.BusinessOperation AS BusinessOperation,
		|	(CASE
		|		WHEN DisposalOfAssets.FinRecordID = UNDEFINED
		|			THEN Source.FinRecordID
		|		ELSE DisposalOfAssets.FinRecordID END) AS FinRecordID,
		|	DisposalOfAssets.BusinessTransactionSetting AS BusinessTransactionSetting,
		|
		|	DisposalOfAssets.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DisposalOfAssets.SalesOrder AS SalesOrder,
		|	DisposalOfAssets.Manager AS Manager,
		|	DisposalOfAssets.Warehouse AS Warehouse,
		|	DisposalOfAssets.Terms AS Terms,
		|	DisposalOfAssets.Contract AS Contract,
		|	DisposalOfAssets.InventoryType AS InventoryType,
		|	DisposalOfAssets.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
		|	DisposalOfAssets.ProductLineOfBusiness AS ProductLineOfBusiness,
		|	DisposalOfAssets.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup,
		|	DisposalOfAssets.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
		|	DisposalOfAssets.AdjustmentPeriod_ AS AdjustmentPeriod_,
		|	Source.InventoryValuationMethod AS InventoryValuationMethod,
		|	
		|	ISNULL(DisposalOfAssets.Count, 0) AS NumberOfDetails,
		|	ISNULL(DroppedOutSummary.Count, 0) AS NumberIsSummarized,
		|	CAST(Source.CostToDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10))
		|		END AS NUMBER(31,2)) AS CostInclVAT,
		|	CAST(Source.CostWithoutNDSKDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS CostExcludingVAT,
		// For low-value goods and materials, the cost of regl and upr is written off as expenses.
		|	CAST(Source.CostLocalToDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS LocalCost,
		|	CAST(Source.ManSCostToDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS CostMan,
		|	Source.QuantityToDistribution
		|		* CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) AS Count,
		|	CAST(Source.AdditionalCostsSNDSKDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS AdditionalExpensesIncludingVAT,
		|	CAST(Source.AdditionalExpensesWithoutNDSKDISTRIBUTION
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS AdditionalExpensesExcludingVAT,
		|	CAST(Source.AdditionalExpensesOfLocalNDSKDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS AddExpensesLocal,
		|	CAST(Source.AdditionalExpensesOfManNDSKDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS AddExpensesMan,
		|	CAST(Source.VATLocalToDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS VATLocal,
		|	CAST(Source.VATManForDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS VATManag,
		|	CAST(Source.ConstantDifferenceToDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) 
		|		END AS NUMBER(31,2)) AS PermanentDifference,
		|	CAST(CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND DisposalOfAssets.ThisIsOutlier
		|			THEN -(Source.CostLocalToDistribution + Source.AdditionalExpensesOfLocalNDSKDistribution)
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN Source.CostLocalToDistribution + Source.AdditionalExpensesOfLocalNDSKDistribution
		|		ELSE Source.TemporalDifferenceToDistribution END
		|		* CAST(CAST(DisposalOfAssets.Count AS NUMBER(28,10))
		|			/ CAST(DroppedOutSummary.Count AS NUMBER(28,10)) AS NUMBER(28,10)) AS NUMBER(31,2)) AS CostTD,
		|	CAST(Source.CostOfPersonalIncomeTaxDistribution
		|	 * CASE
		|		WHEN DisposalOfAssets.WriteOffForExpensesOfLowValueGoodsAndMaterials AND NOT DisposalOfAssets.ThisIsOutlier
		|			THEN 0
		|		ELSE CAST(DisposalOfAssets.Count / DroppedOutSummary.Count AS NUMBER (28, 10)) 
		|		END AS NUMBER(31,2)) AS CostOfPersonalIncomeTax
		|	
		|FROM
		|	ReceiversForProductsOfPastPeriods AS Source
		|
		|		INNER JOIN DisposalSummary AS DroppedOutSummary
		|		ON Source.Recorder                  = DroppedOutSummary.Recorder
		|			AND Source.ItemsLocationAttributes   = DroppedOutSummary.ItemsLocationAttributes
		|			AND Source.AccountingSection               = DroppedOutSummary.AccountingSection
		|			AND Source.InventoryOwnerAttribute                = DroppedOutSummary.InventoryOwnerAttribute
		|			AND Source.Organization               = DroppedOutSummary.Organization
		|			AND Source.Lot                    = DroppedOutSummary.Lot
		|			AND Source.LotVendorAttributes      = DroppedOutSummary.LotVendorAttributes
		|			AND Source.FinancialAccountingDimension = DroppedOutSummary.FinancialAccountingDimension
		|			AND Source.VATActivityType        = DroppedOutSummary.VATActivityType
		|
		|		INNER JOIN PossibleReceiverAnalyticsForProductsOfPastPeriods AS PossibleAnalysts
		|		ON Source.ItemsLocationAttributes   = PossibleAnalysts.ItemsLocationAttributes
		|			AND Source.AccountingSection               = PossibleAnalysts.AccountingSection
		|			AND Source.Organization               = PossibleAnalysts.Organization
		|			AND Source.Lot                    = PossibleAnalysts.Lot
		|			AND Source.LotVendorAttributes      = PossibleAnalysts.LotVendorAttributes
		|			AND Source.FinancialAccountingDimension = PossibleAnalysts.FinancialAccountingDimension
		|			AND Source.VATActivityType        = PossibleAnalysts.VATActivityType
		|			AND Source.InventoryOwnerAttribute                = PossibleAnalysts.InventoryOwnerAttribute
		|
		|		INNER JOIN PastDisposalsOfGoodsDetailed AS DisposalOfAssets
		|		ON PossibleAnalysts.CorItemsLocationAttributes = DisposalOfAssets.ItemsLocationAttributes
		|			AND PossibleAnalysts.CorAccountingSection = DisposalOfAssets.AccountingSection
		|			AND PossibleAnalysts.CorInventoryOwnerAttribute = DisposalOfAssets.InventoryOwnerAttribute
		|			AND PossibleAnalysts.CorCompany = DisposalOfAssets.Organization
		|			AND PossibleAnalysts.CorLot = DisposalOfAssets.Lot
		|			AND PossibleAnalysts.LotVendorAttributesCorr = DisposalOfAssets.LotVendorAttributes
		|			AND PossibleAnalysts.ThisIsOutlier = DisposalOfAssets.ThisIsOutlier
		|
		|		LEFT JOIN Document.AllocationOfOtherCosts AS Attributes
		|		ON Source.Recorder = Attributes.Ref
		|
		|		LEFT JOIN TTChangesInVATActivityType AS VATActivityTypeChange
		|		ON Source.Organization = VATActivityTypeChange.Organization
		|			AND Source.InventoryOwnerAttribute = VATActivityTypeChange.InventoryOwnerAttribute
		|			AND Source.ItemsLocationAttributes = VATActivityTypeChange.ItemsLocationAttributes
		|
		|WHERE
		|	Source.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.AveragePerMonth)
		// The activity type must be the same, except for the cases when the activity type of VAT changes.
		|	AND (CASE WHEN Source.Organization IN (&MediumSlipOrganizations)
		|		THEN PossibleAnalysts.CorVATActivityTypes
		|		ELSE PossibleAnalysts.VATActivityType END = DisposalOfAssets.VATActivityType
		|		OR NOT VATActivityTypeChange.ItemsLocationAttributes IS NULL)
		|
		|UNION ALL
		|
		|SELECT
		|	FALSE AS ThisIsOutlier,
		|	Source.Recorder,
		|	Source.Period,
		|	Source.EntryType,
		|	Source.ReceiptPeriod,
		|	Source.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Source.AccountingSection AS AccountingSection,
		|	Source.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Source.Organization AS Organization,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
		|
		|	Source.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	Source.AccountingSection AS CorAccountingSection,
		|	Source.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	Source.Organization AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATTaxationPartySBusinessType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS TypeOfActivityVATDisposals,
		|
		|	UNDEFINED AS Department,
		|	UNDEFINED AS LocalDepreciationExpenseItem,
		|	UNDEFINED AS ItemOfExpenditureWriteOffMan,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS GLAccountSettings,
		|	UNDEFINED AS CorLineOfBusiness,
		|	UNDEFINED AS BusinessOperation,
		|	Source.FinRecordID AS FinRecordID,
		|	UNDEFINED AS BusinessTransactionSetting,
		|
		|	UNDEFINED AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Manager,
		|	UNDEFINED AS Warehouse,
		|	UNDEFINED AS Terms,
		|	UNDEFINED AS Contract,
		|	UNDEFINED AS InventoryType,
		|	UNDEFINED AS CounterpartyLineOfBusiness,
		|	UNDEFINED AS ProductLineOfBusiness,
		|	UNDEFINED AS SourceOfProductFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		|	DATETIME(1,1,1) AS AdjustmentPeriod_,
		|	Source.InventoryValuationMethod AS InventoryValuationMethod,
		|
		|	0 AS NumberOfDetails,
		|	0 AS NumberIsSummarized,
		|	Source.CostToDistribution AS CostInclVAT,
		|	Source.CostWithoutNDSKDistribution AS CostExcludingVAT,
		|	Source.CostLocalToDistribution AS LocalCost,
		|	Source.ManSCostToDistribution AS CostMan,
		|	Source.QuantityToDistribution AS Count,
		|	Source.AdditionalCostsSNDSKDistribution AS AdditionalExpensesIncludingVAT,
		|	Source.AdditionalExpensesWithoutNDSKDISTRIBUTION AS AdditionalExpensesExcludingVAT,
		|	Source.AdditionalExpensesOfLocalNDSKDistribution AS AddExpensesLocal,
		|	Source.AdditionalExpensesOfManNDSKDistribution AS AddExpensesMan,
		|	Source.VATLocalToDistribution AS VATLocal,
		|	Source.VATManForDistribution AS VATManag,
		|	Source.ConstantDifferenceToDistribution AS PermanentDifference,
		|	Source.TemporalDifferenceToDistribution AS CostTD,
		|	Source.CostOfPersonalIncomeTaxDistribution AS CostOfPersonalIncomeTax
		|FROM
		|	ReceiversForProductsOfPastPeriods AS Source
		|WHERE
		|	Source.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		
		|INDEX BY
		|	Recorder
		|";
	QueriesTexts.Add(QueryTextIndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods);
		
	#EndRegion
		
	Return MergeTexts(QueriesTexts, Common.QueryBatchSeparator());
		
EndFunction

Function TextOfShareOfAdditionalCosts()
	
	QueryText =
		"SELECT
		|	""TextOfShareOfAdditionalCosts_1"" AS RequestSource,
		|	Recorders.Ref AS Recorder,
		// Receiver of the cost of goods
		|	ProductReceivers.ReceiptPeriod AS ReceiptPeriod,
		|	DATETIME(1,1,1) AS AdjustmentPeriod_,
		|	ProductReceivers.AccountingSection AS CorAccountingSection,
		|	ProductReceivers.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	ProductReceivers.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	ProductReceivers.Organization AS CorCompany,
		// When using a medium-sized batch measurement, the batch measurements should be empty.
		|	(CASE
		|		WHEN ProductReceivers.Organization IN (&MediumSlipOrganizations)
		|			THEN UNDEFINED
		|		ELSE ProductReceivers.Lot END) AS CorLot,
		|	(CASE
		|		WHEN ProductReceivers.Organization IN (&MediumSlipOrganizations)
		|			THEN VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|		ELSE ProductReceivers.LotVendorAttributes END) AS LotVendorAttributesCorr,
		|	(CASE
		|		WHEN ProductReceivers.Organization IN (&MediumSlipOrganizations)
		|			THEN UNDEFINED
		|		ELSE ProductReceivers.FinancialAccountingDimension END) AS CorControllingAttributes,
		|	ProductReceivers.VATActivityType AS CorVATActivityTypes,
		|	UNDEFINED AS VATTaxationPartySTypeOfActivity,
		|	UNDEFINED AS TypeOfActivityVATDisposals,
		|	VALUE(Enum.BusinessTransactions.ExpenseAllocationToCost),
		|	VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
		|	ProductReceivers.FinRecordID AS FinRecordID,
		// Receiver Other expenses/Other assets
		|	UNDEFINED AS CorExpenseItem,
		|	UNDEFINED AS CorExpenditureDimension,
		|	UNDEFINED AS CorArticleOfAssetsLiabilities,
		|	UNDEFINED AS CorDimensionOfAssetsLiabilities,
		|	UNDEFINED AS CorSettingUpAccountingAccounts,
		|	UNDEFINED AS DebitBusinessUnit,
		|	UNDEFINED AS CorLineOfBusiness,
		//Receiver Revenue and cost
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Manager,
		|	UNDEFINED AS Warehouse,
		|	UNDEFINED AS Terms,
		|	UNDEFINED AS Contract,
		|	UNDEFINED AS InventoryType,
		|	UNDEFINED AS CounterpartyLineOfBusiness,
		|	ProductReceivers.InventoryOwnerAttribute AS SourceOfProductFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		// Receiver indicators
		|	ProductReceivers.Count AS Count,
		|	CASE
		|		WHEN NOT Recorders.ManagementAccounting THEN 0
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|		 OR Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN ProductReceivers.Cost
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN ProductReceivers.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * ProductReceivers.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * ProductReceivers.Count
		|		ELSE
		|			0
		|	END AS CostShare,
		|	CASE
		|		WHEN NOT Recorders.ManagementAccounting THEN 0
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|		 OR Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN ProductReceivers.CostExcludingVAT
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN ProductReceivers.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * ProductReceivers.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * ProductReceivers.Count
		|		ELSE
		|			0
		|	END AS ShareOfValueWithoutVAT,
		|	CASE
		|		WHEN NOT Recorders.LocalAccounting THEN 0
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|		 OR Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN ProductReceivers.LocalCost
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN ProductReceivers.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * ProductReceivers.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * ProductReceivers.Count
		|		ELSE
		|			0
		|	END AS ShareOfLocalValue,
		|
		|	CASE
		|		WHEN NOT Recorders.TaxAccounting AND NOT Recorders.LocalAccounting THEN 0
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|		 OR Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN ProductReceivers.CostInTaxAccounting
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN ProductReceivers.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * ProductReceivers.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * ProductReceivers.Count
		|		ELSE
		|			0
		|	END AS ShareValueTa,
		|
		|	CASE
		|		WHEN NOT Recorders.AIT THEN 0
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|		 OR Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN (CASE 
		|				WHEN ProductReceivers.CostOfPersonalIncomeTax <> 0
		|					THEN ProductReceivers.CostOfPersonalIncomeTax
		|				WHEN ProductReceivers.LocalCost <> 0
		|					THEN ProductReceivers.LocalCost
		|				ELSE 0 END)
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN ProductReceivers.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * ProductReceivers.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * ProductReceivers.Count
		|		ELSE
		|			0
		|	END AS ShareOfCostOfPersonalIncomeTax,
		|
		|	CASE
		|		WHEN NOT Recorders.ManagementAccounting THEN 0
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|		 OR Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN ProductReceivers.CostMan
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN ProductReceivers.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * ProductReceivers.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * ProductReceivers.Count
		|		ELSE
		|			0
		|	END AS ShareOfManSCost
		|FROM
		// Comment 4774. The selection and connection conditions must match the request of the textanalyticsaccountable nomenclatesreferences
		|	Recorders AS Recorders
		|		LEFT JOIN ProductReceivers AS ProductReceivers
		|		ON Recorders.Ref = ProductReceivers.Recorder
		|			
		|		LEFT JOIN ItemAccountingAnalystsWithVolumeAndWeights AS AUN_VolumeWeight
		|		ON AUN_VolumeWeight.ItemsLocationAttributes = ProductReceivers.ItemsLocationAttributes
		|WHERE
		|	NOT ProductReceivers.ThisIsPartyOfPastPeriod
		|	OR ProductReceivers.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|
		|UNION ALL
		|
		|SELECT
		|	""TextOfShareOfAdditionalCosts_2"" AS RequestSource,
		|	Indicators.Recorder AS Recorder,
		// Receiver of the cost of goods
		|	Indicators.ReceiptPeriod AS ReceiptPeriod,
		|	Indicators.AdjustmentPeriod_ AS AdjustmentPeriod_,
		|	Indicators.CorAccountingSection AS CorAccountingSection,
		|	Indicators.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	Indicators.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	Indicators.CorCompany AS CorCompany,
		|	Indicators.CorLot AS CorLot,
		|	Indicators.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	Indicators.CorControllingAttributes AS CorControllingAttributes,
		|	Indicators.CorVATActivityTypes AS CorVATActivityTypes,
		|	Indicators.VATTaxationPartySTypeOfActivity AS VATTaxationPartySTypeOfActivity,
		|	Indicators.TypeOfActivityVATDisposals AS TypeOfActivityVATDisposals,
		|	(CASE
		|		WHEN NOT Indicators.ThisIsOutlier
		|			THEN VALUE(Enum.BusinessTransactions.ExpenseAllocationToCost)
		|		ELSE Indicators.BusinessOperation END) AS BusinessOperation,
		|	(CASE
		|		WHEN NOT Indicators.ThisIsOutlier
		|			THEN VALUE(Enum.LotRecordTypes.AddExpensesForGoods)
		|		ELSE VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods) END) AS EntryType,
		|	"""" AS FinRecordID,
		// Receiver Other expenses/Other assets
		|	Indicators.LocalDepreciationExpenseItem AS CorExpenseItem,
		|	Indicators.DimensionOfExpenses AS CorExpenditureDimension,
		|	Indicators.AssetAndLiabilityItem AS CorArticleOfAssetsLiabilities,
		|	Indicators.AssetsLiabilitiesDimension AS CorDimensionOfAssetsLiabilities,
		|	Indicators.GLAccountSettings AS CorSettingUpAccountingAccounts,
		|	Indicators.Department AS DebitBusinessUnit,
		|	Indicators.CorLineOfBusiness AS CorLineOfBusiness,
		//Receiver Revenue and cost
		|	Indicators.AccountingDimensionByPartners,
		|	Indicators.SalesOrder,
		|	Indicators.Manager,
		|	Indicators.Warehouse,
		|	Indicators.Terms,
		|	Indicators.Contract,
		|	Indicators.InventoryType,
		|	Indicators.CounterpartyLineOfBusiness,
		|	Indicators.SourceOfProductFinancialAccountingGroup,
		|	Indicators.SourceOfARAPFinancialAccountingGroup,
		// Receiver indicators
		|	Indicators.Count AS Count,
		|	CASE
		|		WHEN NOT Recorders.ManagementAccounting THEN 0
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			OR Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN Indicators.CostInclVAT
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN Indicators.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * Indicators.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * Indicators.Count
		|		ELSE
		|			0
		|	END AS CostShare,
		|	CASE
		|		WHEN NOT Recorders.ManagementAccounting THEN 0
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			OR Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN Indicators.CostExcludingVAT
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN Indicators.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * Indicators.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * Indicators.Count
		|		ELSE
		|			0
		|	END AS ShareOfValueWithoutVAT,
		|	CASE
		|		WHEN NOT Recorders.LocalAccounting THEN 0
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			OR Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN Indicators.LocalCost
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN Indicators.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * Indicators.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * Indicators.Count
		|		ELSE
		|			0
		|	END AS ShareOfLocalValue,
		|
		|	CASE
		|		WHEN NOT Recorders.TaxAccounting THEN 0
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			OR Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN Indicators.LocalCost - Indicators.PermanentDifference - Indicators.CostTD
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN Indicators.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * Indicators.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * Indicators.Count
		|		ELSE
		|			0
		|	END AS ShareValueTa,
		|
		|	CASE
		|		WHEN NOT Recorders.AIT THEN 0
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			OR Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN Indicators.CostOfPersonalIncomeTax
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN Indicators.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * Indicators.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * Indicators.Count
		|		ELSE
		|			0
		|	END AS ShareOfCostOfPersonalIncomeTax,
		|
		|	CASE
		|		WHEN NOT Recorders.ManagementAccounting THEN 0
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			OR Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN Indicators.CostMan
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN Indicators.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * Indicators.Count
		|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * Indicators.Count
		|		ELSE
		|			0
		|	END AS ShareOfManSCost
		|FROM
		|	IndicatorsOfBaseOfDistributionOfReceiversOfPastPeriods AS Indicators
		|		INNER JOIN Recorders AS Recorders
		|		ON Indicators.Recorder = Recorders.Ref
		|		LEFT JOIN ItemAccountingAnalystsWithVolumeAndWeights AS AUN_VolumeWeight
		|		ON AUN_VolumeWeight.ItemsLocationAttributes = Indicators.CorItemsLocationAttributes
		|
		|UNION ALL
		|
		|SELECT
		|	""TextOfShareOfAdditionalCosts_3"" AS RequestSource,
		|	DD.Ref AS Recorder,
		// Receiver Cost of goods
		|	BEGINOFPERIOD(SourceDatabase.Period, DAY) AS ReceiptPeriod,
		|	DATETIME(1,1,1) AS AdjustmentPeriod_,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	SourceDatabase.Organization AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	UNDEFINED AS CorVATActivityTypes,
		|	UNDEFINED AS VATTaxationPartySTypeOfActivity,
		|	UNDEFINED AS TypeOfActivityVATDisposals,
		|	CASE WHEN DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|		THEN VALUE(Enum.BusinessTransactions.VATIsAccruedByTaxAgent)
		|		ELSE SourceDatabase.BusinessOperation
		|	END AS BusinessOperation,
		|	VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
		|	SourceDatabase.FinRecordID AS FinRecordID,
		// Receiver Other expenses/Other assets
		|	SourceDatabase.ExpenseItem                                         AS CorExpenseItem,
		|	SourceDatabase.DimensionOfExpenses                                      AS CorExpenditureDimension,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) AS CorArticleOfAssetsLiabilities,
		|	UNDEFINED                                                        AS CorDimensionOfAssetsLiabilities,
		|	UNDEFINED                                                        AS CorSettingUpAccountingAccounts,
		|	SourceDatabase.Department                                          AS DebitBusinessUnit,
		|	SourceDatabase.LineOfBusiness                                AS CorLineOfBusiness,
		//Receiver Revenue and cost
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Manager,
		|	UNDEFINED AS Warehouse,
		|	UNDEFINED AS Terms,
		|	UNDEFINED AS Contract,
		|	UNDEFINED AS InventoryType,
		|	UNDEFINED AS CounterpartyLineOfBusiness,
		|	UNDEFINED AS SourceOfProductFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		// Receiver indicators
		|	CASE WHEN DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|		THEN 0
		|		ELSE ISNULL(Purchase.Count, Transfer_.Count)
		|	END AS Count,
		|	CASE
		|		WHEN NOT DD.ManagementAccounting THEN 0
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			OR DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN SourceDatabase.Sum
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN ISNULL(Purchase.Count, Transfer_.Count)
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * ISNULL(Purchase.Count, Transfer_.Count)
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * ISNULL(Purchase.Count, Transfer_.Count)
		|		ELSE
		|			0
		|	END AS CostShare,
		|	CASE
		|		WHEN NOT DD.ManagementAccounting THEN 0
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|		 OR DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN SourceDatabase.AmountExcludingVAT
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN ISNULL(Purchase.Count, Transfer_.Count)
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * ISNULL(Purchase.Count, Transfer_.Count)
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * ISNULL(Purchase.Count, Transfer_.Count)
		|		ELSE
		|			0
		|	END AS ShareOfValueWithoutVAT,
		|	CASE
		|		WHEN NOT DD.LocalAccounting THEN 0
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|		 OR DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN SourceDatabase.SumCompl
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN ISNULL(Purchase.Count, Transfer_.Count)
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * ISNULL(Purchase.Count, Transfer_.Count)
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * ISNULL(Purchase.Count, Transfer_.Count)
		|		ELSE
		|			0
		|	END AS ShareOfLocalValue,
		|	CASE
		|		WHEN NOT DD.TaxAccounting AND NOT DD.LocalAccounting THEN 0
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|		 OR DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN SourceDatabase.SumCompl
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN ISNULL(Purchase.Count, Transfer_.Count)
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * ISNULL(Purchase.Count, Transfer_.Count)
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * ISNULL(Purchase.Count, Transfer_.Count)
		|		ELSE
		|			0
		|	END AS ShareValueTa,
		|	CASE
		|		WHEN NOT DD.AIT THEN 0
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|		 OR DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN SourceDatabase.AITAmount
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN ISNULL(Purchase.Count, Transfer_.Count)
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * ISNULL(Purchase.Count, Transfer_.Count)
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * ISNULL(Purchase.Count, Transfer_.Count)
		|		ELSE
		|			0
		|	END AS ShareOfCostOfPersonalIncomeTax,
		|	CASE
		|		WHEN NOT DD.ManagementAccounting THEN 0
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|		 OR DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|			THEN SourceDatabase.SumMan
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN ISNULL(Purchase.Count, Transfer_.Count)
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * ISNULL(Purchase.Count, Transfer_.Count)
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * ISNULL(Purchase.Count, Transfer_.Count)
		|		ELSE
		|			0
		|	END AS ShareOfManSCost
		|FROM
		// Comment 4761. The selection and connection conditions must match the request of the textanalyticsaccountable nomenclatesreferences.
		|	Recorders AS DD
		|		INNER JOIN AccumulationRegister.OtherExpenses AS SourceDatabase
		|			ON DD.DimensionOfExpenses = SourceDatabase.Recorder
		|			AND SourceDatabase.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND SourceDatabase.Period <= &EndOfPeriod
		|			AND NOT SourceDatabase.CalculationOfCost
		|		LEFT JOIN Document.VendorInvoice.Goods AS Purchase
		|			ON SourceDatabase.Recorder = Purchase.Ref
		|			AND SourceDatabase.RowID = Purchase.RowID
		|			AND Purchase.ToExpenseAs
		|		LEFT JOIN Document.CustomerInvoiceIntercompany.InventoryKinds AS Transfer_
		|			ON SourceDatabase.Recorder = Transfer_.Ref
		|			AND SourceDatabase.RowID = Transfer_.RowID
		|			AND Transfer_.ToExpenseAs
		|		LEFT JOIN ItemAccountingAnalystsWithVolumeAndWeights AS AUN_VolumeWeight
		|			ON AUN_VolumeWeight.ItemsLocationAttributes = SourceDatabase.ItemsLocationAttributes
		|WHERE
		|	DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|	OR (SourceDatabase.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff)
		|			AND SourceDatabase.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
		|			AND SourceDatabase.Recorder <> SourceDatabase.DimensionOfExpenses
		|			AND NOT AUN_VolumeWeight.Products IS NULL
		|			AND AUN_VolumeWeight.ItemsType <> VALUE(Enum.ItemsTypes.OperationService)
		|			AND (NOT Purchase.Ref IS NULL OR NOT Transfer_.Ref IS NULL))
		|
		|UNION ALL
		|
		|SELECT
		|	""TextOfShareOfAdditionalCosts_4"" AS RequestSource,
		|	DD.Ref AS Recorder,
		// Receiver Cost of goods
		|	&BeginOfPeriod AS ReceiptPeriod,
		|	DATETIME(1,1,1) AS AdjustmentPeriod_,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	SourceDatabase.Organization AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	UNDEFINED AS CorVATActivityTypes,
		|	UNDEFINED AS VATTaxationPartySTypeOfActivity,
		|	UNDEFINED AS TypeOfActivityVATDisposals,
		|	VALUE(Enum.BusinessTransactions.VATIsAccruedByTaxAgent) AS BusinessOperation,
		|	VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
		|	"""" AS FinRecordID,
		// Receiver Other expenses/Other assets
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS CorExpenseItem,
		|	UNDEFINED                                                 AS CorExpenditureDimension,
		|	SourceDatabase.AssetRef                                          AS CorArticleOfAssetsLiabilities,
		|	SourceDatabase.Dimension                                       AS CorDimensionOfAssetsLiabilities,
		|	UNDEFINED                                                 AS CorSettingUpAccountingAccounts,
		|	SourceDatabase.Department                                   AS DebitBusinessUnit,
		|	SourceDatabase.LineOfBusiness                         AS CorLineOfBusiness,
		//Receiver Revenue and cost
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Manager,
		|	UNDEFINED AS Warehouse,
		|	UNDEFINED AS Terms,
		|	UNDEFINED AS Contract,
		|	UNDEFINED AS InventoryType,
		|	UNDEFINED AS CounterpartyLineOfBusiness,
		|	UNDEFINED AS SourceOfProductFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		// Receiver indicators
		|	0 AS Count,
		|	SourceDatabase.Sum AS CostShare,
		|	SourceDatabase.Sum AS ShareOfValueWithoutVAT,
		|	SourceDatabase.Sum AS ShareOfLocalValue,
		|	SourceDatabase.Sum AS ShareValueTa,
		|	SourceDatabase.Sum AS ShareOfCostOfPersonalIncomeTax,
		|	SourceDatabase.Sum AS ShareOfManSCost
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN AccumulationRegister.OtherAssetsLiabilities AS SourceDatabase
		|		ON DD.DimensionOfExpenses = SourceDatabase.Recorder
		|			AND SourceDatabase.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND SourceDatabase.Period <= &EndOfPeriod
		|			AND SourceDatabase.SourceKind = VALUE(Enum.MovementSourcesKinds.EmptyRef)
		|			AND NOT SourceDatabase.CalculationOfCost
		|WHERE
		|	DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|
		|UNION ALL
		|
		|SELECT
		|	""TextOfShareOfAdditionalCosts_5"" AS RequestSource,
		|	DD.Ref AS Recorder,
		// Receiver Otherexpenses
		|	&BeginOfPeriod AS ReceiptPeriod,
		|	DATETIME(1,1,1) AS AdjustmentPeriod_,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	SourceDatabase.Organization AS CorCompany,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	UNDEFINED AS CorVATActivityTypes,
		|	UNDEFINED AS VATTaxationPartySTypeOfActivity,
		|	UNDEFINED AS TypeOfActivityVATDisposals,
		|	CASE WHEN DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|		THEN VALUE(Enum.BusinessTransactions.VATIsAccruedByTaxAgent)
		|		ELSE SourceDatabase.BusinessOperation
		|	END AS BusinessOperation,
		|	VALUE(Enum.LotRecordTypes.AddExpensesForGoods),
		|	SourceDatabase.FinRecordID AS FinRecordID,
		// Receiver Other expenses/Other assets
		|	SourceDatabase.ExpenseItemOfWriteOff                                 AS CorExpenseItem,
		|	SourceDatabase.DimensionOfExpenses                                      AS CorExpenditureDimension,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) AS CorArticleOfAssetsLiabilities,
		|	UNDEFINED                                                        AS CorDimensionOfAssetsLiabilities,
		|	UNDEFINED                                                        AS CorSettingUpAccountingAccounts,
		|	SourceDatabase.Department                                          AS DebitBusinessUnit,
		|	SourceDatabase.CorLineOfBusiness                             AS CorLineOfBusiness,
		//Receiver Revenue and cost
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Manager,
		|	UNDEFINED AS Warehouse,
		|	UNDEFINED AS Terms,
		|	UNDEFINED AS Contract,
		|	UNDEFINED AS InventoryType,
		|	UNDEFINED AS CounterpartyLineOfBusiness,
		|	UNDEFINED AS SourceOfProductFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		// Receiver indicators
		|	SourceDatabase.Count AS Count,
		|	CASE
		|		WHEN NOT DD.ManagementAccounting THEN 0
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			THEN SourceDatabase.Cost
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN SourceDatabase.Count
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * SourceDatabase.Count
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * SourceDatabase.Count
		|		ELSE
		|			0
		|	END AS CostShare,
		|	CASE
		|		WHEN NOT DD.ManagementAccounting THEN 0
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			THEN SourceDatabase.CostExcludingVAT
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN SourceDatabase.Count
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * SourceDatabase.Count
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * SourceDatabase.Count
		|		ELSE
		|			0
		|	END AS ShareOfValueWithoutVAT,
		|	CASE
		|		WHEN NOT DD.LocalAccounting THEN 0
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			THEN SourceDatabase.LocalCost
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN SourceDatabase.Count
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * SourceDatabase.Count
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * SourceDatabase.Count
		|		ELSE
		|			0
		|	END AS ShareOfLocalValue,
		|	CASE
		|		WHEN NOT DD.TaxAccounting AND NOT DD.LocalAccounting THEN 0
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			THEN SourceDatabase.LocalCost
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN SourceDatabase.Count
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * SourceDatabase.Count
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * SourceDatabase.Count
		|		ELSE
		|			0
		|	END AS ShareValueTa,
		|	CASE
		|		WHEN NOT DD.AIT THEN 0
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			THEN SourceDatabase.CostOfPersonalIncomeTax
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN SourceDatabase.Count
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * SourceDatabase.Count
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * SourceDatabase.Count
		|		ELSE
		|			0
		|	END AS ShareOfCostOfPersonalIncomeTax,
		|	CASE
		|		WHEN NOT DD.ManagementAccounting THEN 0
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.InventoryCost)
		|			THEN SourceDatabase.CostMan
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
		|			THEN SourceDatabase.Count
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsVolume)
		|			THEN ISNULL(AUN_VolumeWeight.VolumeM3, 0) * SourceDatabase.Count
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.GoodsWeight)
		|			THEN ISNULL(AUN_VolumeWeight.Weight, 0) * SourceDatabase.Count
		|		ELSE
		|			0
		|	END AS ShareOfManSCost
		|FROM
		|	Recorders AS DD
		|		INNER JOIN AccumulationRegister.InventoryCost AS SourceDatabase
		|			ON DD.DimensionOfExpenses = SourceDatabase.Recorder
		|			AND SourceDatabase.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND SourceDatabase.Period <= &EndOfPeriod
		|			AND SourceDatabase.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|			AND NOT SourceDatabase.LotCalculation
		|			AND NOT SourceDatabase.CalculationOfCost
		|		LEFT JOIN Catalog.Products AS SN
		|			ON SN.Ref = SourceDatabase.ItemsLocationAttributes.Products
		|		LEFT JOIN ItemAccountingAnalystsWithVolumeAndWeights AS AUN_VolumeWeight
		|			ON AUN_VolumeWeight.ItemsLocationAttributes = SourceDatabase.ItemsLocationAttributes
		|WHERE
		|	DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent)
		|	AND SourceDatabase.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|";
		
	Return QueryText;
	
EndFunction

#EndRegion

#Region ProceduresOfStep7_CalculationOfSharesOfDistributionOfOtherCosts

Function RequestTextForCalculatingSharesOfDistributionOfOtherCosts()
	Return "SELECT
	|	DD.Ref,
	|	DD.Ref AS Document,
	|	DD.Date,
	|	DD.Organization,
	|	DD.Department,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.ManagementAccounting,
	|	DD.LocalAccounting,
	|	DD.TaxAccounting,
	|	DD.AIT,
	|	DD.AssignAllocationSetting,
	|	DD.ProductCostElement,
	|	DD.AllocateByLots,
	|	DD.AllocateToCostCenter,
	|	DD.AllocateToExpenseItems,
	|	DD.LeaveAsWIP,
	|	CASE 
	|		WHEN DD.AllocateByLots AND DD.CostShareForProduction = 0 THEN 1
	|		WHEN DD.AllocateByLots THEN DD.CostShareForProduction	
	|		ELSE 0 
	|	END AS CostShareForProduction,
	|	CASE 
	|		WHEN DD.AllocateToCostCenter AND DD.CostShareToCostCenters = 0 THEN 1
	|		WHEN DD.AllocateToCostCenter THEN DD.CostShareToCostCenters	
	|		ELSE 0 
	|	END AS CostShareToCostCenters,
	|	CASE 
	|		WHEN DD.AllocateToExpenseItems THEN DD.CostShareToExpenseItems	
	|		ELSE 0 
	|	END AS CostShareToExpenseItems,
	|	CASE 
	|		WHEN DD.LeaveAsWIP THEN DD.CostShareOfWIP
	|		ELSE 0 
	|	END AS CostShareOfWIP,
	|	CASE 
	|		WHEN DD.AllocateByLots AND DD.CostShareForProduction = 0 THEN 1
	|		WHEN DD.AllocateByLots THEN DD.CostShareForProduction	
	|		ELSE 0 
	|	END +
	|	CASE 
	|		WHEN DD.AllocateToCostCenter AND DD.CostShareToCostCenters = 0 THEN 1
	|		WHEN DD.AllocateToCostCenter THEN DD.CostShareToCostCenters	
	|		ELSE 0 
	|	END +
	|	CASE 
	|		WHEN DD.AllocateToExpenseItems THEN DD.CostShareToExpenseItems	
	|		ELSE 0 
	|	END +
	|	CASE 
	|		WHEN DD.LeaveAsWIP THEN DD.CostShareOfWIP
	|		ELSE 0 
	|	END AS TotalCostShare_
	|INTO TTShareOfDistributionOfOtherCosts
	|FROM Document.AllocationOfOtherCosts AS DD
	|WHERE
	|	DD.Posted
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Organization IN(&CompanyArray)
	|	AND NOT DD.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits)
	|
	|INDEX BY
	|	Document";
EndFunction

Function TextDescriptionOfDataForCalculationOfSharesOfDistributionOfOtherCosts() Export
	
	QueryText = 
	"SELECT TOP 0
	|	DD.Ref,
	|	DD.Ref AS Document,
	|	DD.Date,
	|	DD.Organization,
	|	DD.Department,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	DD.ManagementAccounting,
	|	DD.LocalAccounting,
	|	DD.TaxAccounting,
	|	DD.AIT,
	|	DD.AssignAllocationSetting,
	|	DD.ProductCostElement,
	|	DD.AllocateByLots,
	|	DD.AllocateToCostCenter,
	|	DD.AllocateToExpenseItems,
	|	DD.LeaveAsWIP,
	|	0 AS CostShareForProduction,
	|	0 AS CostShareToCostCenters,
	|	0 AS CostShareToExpenseItems,
	|	0 AS CostShareOfWIP,
	|	0 AS TotalCostShare_
	|INTO Data
	|FROM Document.AllocationOfOtherCosts AS DD
	|";
	
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

#EndRegion

#Region ProceduresOfStep15_DistributionOfSharesOfProductionCosts

Function TableForDistributionOfSharesOfProductionCosts(CalculationParameters)
	
	Return CostCalculationAppliedAlgorithms.TableForDistributionOfLots(CalculationParameters,
		TextDescriptionOfDataForDistributionOfProductionCostShares());
	
EndFunction

// Sample data

Procedure GetDataForDistributionOfSharesOfProductionCosts(CalculationParameters)
	
	ToDecrypt = CostCalculationAppliedAlgorithms.CalculationCalledForDecryption(CalculationParameters);
	
	AddlParameters = CalculationParameters.AdditionalStageRequestParameters;
	AddlParameters.Insert("CostCalculationPerformed",  CalculationParameters.Property("CostCalculationPerformed"));
	AddlParameters.Insert("DecodingDistribution", 	  ToDecrypt);
	AddlParameters.Insert("IncludeProductionData21", True);
	AddlParameters.Insert("ConsiderFutureReleases", 	  True);
	If ToDecrypt Then
			
		ParametersForReceivingBatches = CostsServer.DescriptionOfParametersForReceivingActiveBatchesWithoutSpecifications();
		ParametersForReceivingBatches.BeginOfPeriod = CalculationParameters.PayrollPeriod.BeginOfPeriod;
		ParametersForReceivingBatches.PeriodEnding = CalculationParameters.PayrollPeriod.EndOfPeriod;
		ParametersForReceivingBatches.Companies = CalculationParameters.CompanyArray;
		
		CostsServer.FormActiveBatchesWithoutSpecifications(ParametersForReceivingBatches, CalculationParameters.TempTablesManager);
		
	EndIf;
	PrepareProductionCostsForDistribution(CalculationParameters);
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForDistributionOfProductionCostShares(CalculationParameters),
		,
		Not ToDecrypt);
	
EndProcedure

// Request texts

// ... general

Function RequestTextForDistributionOfProductionCostShares(CalculationParameters) Export
	
	ToDecrypt = CostCalculationAppliedAlgorithms.CalculationCalledForDecryption(CalculationParameters);
	
	QueryText = ""
		+ TextIndicatorsOfDistributionByDivision()
		+ TextOfSelectionUnit(CalculationParameters)
		+ CostCalculationFillingInformationAboutLots.TextCorrectedDocuments() + Common.QueryBatchSeparator() // CorrectedDocuments_
		
		+ ?(ToDecrypt, CostCalculationProduction.ProductionBatchText(),"")
		+ ?(ToDecrypt, CostCalculationProduction.TextEmptyBatchTableOfGNZPMaterials(),"")
		+ ?(ToDecrypt, CostCalculationProduction.TextOfShareOfCostByProduct(),"")
		
		+ TextDataOnActualMaterialCosts(CalculationParameters)
		+ TextDataOnPreliminaryMaterialCosts(CalculationParameters)
		+ CostCalculationProduction.TextDataOnLaborCosts(CalculationParameters)
		+ TextDataOnLaborCostsCollapsed()
		+ CostCalculationProduction.TextOutputData()
		+ TextOutputDataCollapsed()
		+ TextBaseOfDistributionOfSharesByStages(CalculationParameters)
		+ TextCoefficientsOfBasesByStages()
		+ TextOfDatabaseByStagesIsSummarized()
		+ TextResultsOfDatabaseByStages()
		+ TextBaseOfDistributionOfSharesByDivisions(CalculationParameters)
		+ TextBaseByDivisionSummary()
		+ TextBaseResultsByDivision()
		+ TextDistributionBetweenPartiesPreliminary()
		// Sample data
		+ TextDescriptionOfDataForDistributionOfProductionCostShares()
		+ TMCommonUse.QuerySeparatorInJoin() + TextDistributionBetweenParties()
		+ TMCommonUse.QuerySeparatorInJoin() + TextLinksToOtherArticles()
		+ TMCommonUse.QuerySeparatorInJoin() + TextUnallocatedShares()
		+ "";
		
	Return CostCalculationAppliedAlgorithms.InsertWeightAndVolumeTemplatesIntoQueryText(QueryText, "SN");
	
EndFunction

// ... data descriptions

Function TextDescriptionOfDataForDistributionOfProductionCostShares() Export
	
	QueryText = 
	"SELECT TOP 0
	|	""TextDescriptionOfDataForDistributionOfProductionCostShares""    AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.EmptyRef)                   AS EntryType,
	|	FALSE                                                                    AS CalculationIsCompleted,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)    AS AccountingSection,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	DD.Period                                                               AS Period,
	|	DD.Recorder                                                          AS Recorder,
	|	DD.Organization                                                          AS Organization,
	|	DD.Department                                                        AS Department,
	|	DD.LineOfBusiness                                              AS LineOfBusiness,
	|	DD.ExpenseItem                                                       AS ExpenseItem,
	|	DD.DimensionOfExpenses                                                    AS DimensionOfExpenses,
	|	DD.BusinessOperation                                                AS BusinessOperation,
	|	DD.ProductsGroup                                                      AS ProductsGroup,
	|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef)            AS RuleOfCostAllocatingToProductionLots,
	|	0                                                                       AS CostShare,
	|	0                                                                       AS ShareOfValueWithoutVAT,
	|	0                                                                       AS ShareOfLocalValue,
	|	0                                                                       AS ShareValueTa,
	|	0                                                                       AS ShareOfManSCost,
	|	0                                                                       AS ShareOfCostOfPersonalIncomeTax,
	|	DD.CorExpenseItem                                                    AS CorExpenseItem,
	|	DD.CorExpenditureDimension                                                 AS CorExpenditureDimension,
	|	AP.AssetRef                                                               AS CorArticleOfAssetsLiabilities,
	|	AP.Dimension                                                            AS CorDimensionOfAssetsLiabilities,
	|	DD.DebitBusinessUnit                                                     AS DebitBusinessUnit,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)               AS CorLineOfBusiness,
	|	UnfinishedProduction.ProductionLot                                                  AS ProductionLot,
	|	UnfinishedProduction.ProductionOrder                                                 AS ProductionOrder,
	|	UnfinishedProduction.RowCodeProducts                                                  AS RowCodeProducts,
	|	DD.CorCostElement                                                 AS ProductCostElement,
	|	DD.RowID                                                  AS RowID
	|INTO Data
	|FROM
	|	AccumulationRegister.OtherExpenses AS DD
	|		LEFT JOIN AccumulationRegister.OtherWorkInProgressExpenses AS UnfinishedProduction
	|		ON TRUE
	|		LEFT JOIN AccumulationRegister.OtherAssetsLiabilities AS AP
	|		ON TRUE
	|";
	
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
	
EndFunction

// ... formation of temporary tables

Procedure PrepareProductionCostsForDistribution(CalculationParameters)
	
	// Let's remember the composition of temporary tables.
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	Query.SetParameter("CostAllocationOptions", 
		TMCommonUseClientServer.Array(Enums.CostAllocationOptions.ToProductionCosts));
	Query.SetParameter("Recorder",
		?(CalculationParameters.Property("Recorder"), CalculationParameters.Recorder, Undefined));
	
	Query.Text = Documents.AllocationOfOtherCosts.QueryTextReceivedOtherExpenses(?(CalculationParameters.Property("Recorder"),Undefined,"ActualCalculation"), False);
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, 
		,,,NStr("vi = 'Nhận chi phí theo từng giai đoạn để phân bổ.';
				|ru = 'Получение постатейных затрат для распределения.';
				|en = 'Receiving itemized costs for allocation.'; fa = 'Receiving itemized costs for allocation.';
				|it = 'Ottenimento di spese dettagliate per la ripartizione.';
				|pl = 'Otrzymanie kosztów wg pozycji dla podziału.';
				|tr = 'Dağıtım için kalemlere ayrılmış maliyetlerin elde edilmesi.'"));

	Query.Text = 
		"SELECT DISTINCT
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|	T.LineOfBusiness
		|INTO ItemsOfExpenditureOnHIA
		|FROM ExpenseForAllocation AS T
		|WHERE T.ThisIsExpenseOfHIA
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Ref AS Recorder,
		|	DD.Date AS Date,
		|	DD.AssignAllocationSetting,
		|	DD.Organization,
		|	DD.AllocationDirection,
		|	DD.BaseOfAllocationByBusinessUnits,
		|	DD.BaseOfAllocationByLots,
		|	DD.Department,
		|	CASE 
		|		WHEN T.ThisIsExpenseOfHIA THEN T.LineOfBusiness 
		|		ELSE DD.LineOfBusiness 
		|	END AS LineOfBusiness,
		|	ISNULL(T.ExpenseItem, DD.ExpenseItem) AS ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	T.ThisIsExpenseOfHIA,
		|	CASE 
		|		WHEN T.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters) 
		|			AND NOT TTOvz.CostAllocationOptionManag IS NULL 
		|		THEN TTOvz.CostAllocationOptionManag 
		|		ELSE T.ExpenseItem.CostAllocationOptionManag
		|	END AS CostAllocationOptionManag,
		|	CASE 
		|		WHEN T.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCostCenters) 
		|			AND NOT TTOvz.CostAllocationOptionLocal IS NULL 
		|		THEN TTOvz.CostAllocationOptionLocal 
		|		ELSE T.ExpenseItem.CostAllocationOptionLocal
		|	END AS CostAllocationOptionLocal,
		|	CASE 
		|		WHEN T.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToCostCenters) 
		|			AND NOT TTOvz.CostAllocationOptionTax IS NULL 
		|		THEN TTOvz.CostAllocationOptionTax 
		|		ELSE T.ExpenseItem.CostAllocationOptionTax
		|	END AS CostAllocationOptionTax,
		|	(CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN NOT SettingsForDistributionOfAITArticlesByCostCenter.AITCostAllocationOption IS NULL
		|			THEN SettingsForDistributionOfAITArticlesByCostCenter.AITCostAllocationOption
		|		WHEN NOT AITArticleDistributionSettings.AITCostAllocationOption IS NULL
		|			THEN AITArticleDistributionSettings.AITCostAllocationOption
		|		ELSE VALUE(Enum.CostAllocationOptions.EmptyRef) END) AS AITCostAllocationOption,
		|	DD.Factor,
		|	DD.ToAnyLinesOfBusiness,
		|	DD.ProductCostElement,
		|	DD.AllocateByLots,
		|	DD.AllocateToBusinessUnits,
		|	DD.AllocateToExpenseItems,
		|	DD.LeaveAsWIP,
		|	DD.ForReleaseOfCurrentMonth,
		|	DD.LotsAreSpecifiedManually,
		|	DD.BusinessUnitsAreSpecifiedManually,
		|	DD.LocalAccounting,
		|	DD.TaxAccounting,
		|	DD.ManagementAccounting,
		|	DD.AIT,
		|	DD.CostShareForProduction,
		|	DD.CostShareOfWIP,
		|	DD.CostShareToExpenseItems,
		|	DD.TotalCostShares,
		|	DD.AllocateToCostCenter,
		|	DD.CostShareToCostCenters,
		|	CASE 
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
		|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts)
		|		WHEN DD.BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses),
		|												VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds),
		|												VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel))
		|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByLaborCosts)
		|		WHEN DD.BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount),
		|												VALUE(Enum.TypesOfCostAllocatingBase.StandardMaterialConsumption),
		|												VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials),
		|												VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials),
		|												VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials))
		|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts)
		|		WHEN DD.BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantity),
		|												VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeight),
		|												VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolume),
		|												VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCost))
		|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByProducts)
		|		WHEN DD.BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases),
		|												VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases),
		|												VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases),
		|												VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases))
		|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases)
		|	END AS RuleOfCostAllocatingToProductionLots
		|INTO Recorders
		|FROM
		|	Document.AllocationOfOtherCosts AS DD
		|		LEFT JOIN TTOvz AS TTOvz
		|		ON DD.DimensionOfExpenses = TTOvz.ConstCenter
		|			AND DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|		LEFT JOIN ExpenseForAllocation AS T
		|		ON (T.Organization = DD.Organization)
		|			AND (T.Department = DD.Department)
		|			AND (T.ThisIsExpenseOfHIA OR T.ExpenseItem = DD.ExpenseItem)
		|			AND (T.DimensionOfExpenses = DD.DimensionOfExpenses)
		|			AND (T.ThisIsExpenseOfHIA OR T.LineOfBusiness = DD.LineOfBusiness)
		|		LEFT JOIN AITArticleDistributionSettings AS AITArticleDistributionSettings
		|		ON DD.ExpenseItem = AITArticleDistributionSettings.ExpenseItem
		|			AND &DD_ObjectOfSeparateAccountingAIT = AITArticleDistributionSettings.ObjectOfSeparateAccountingAIT
		|			AND DD.Organization = AITArticleDistributionSettings.Organization
		|		LEFT JOIN SettingsForDistributionOfAITArticlesByCostCenter AS SettingsForDistributionOfAITArticlesByCostCenter
		|		ON DD.DimensionOfExpenses = SettingsForDistributionOfAITArticlesByCostCenter.ConstCenter
		|WHERE
		|	DD.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots)
		|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DD.Organization IN(&CompanyArray)
		|	AND DD.Posted
		|	AND (DD.Ref = &Recorder
		|			OR &Recorder = UNDEFINED)
		|	AND (T.ExpenseItem IS NOT NULL
		|		OR DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostsReverseTransaction))
		|
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DD.Ref AS Recorder,
		|	DD.Date,
		|	DD.Organization,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.Factor,
		|	DD.AllocationDirection AS AllocationDirection,
		|	DD.AllocationDirection = VALUE(Enum.AllocationDirectionByBusinessUnits.Subordinate) AS DistributionToLowerLevelDivision,
		|	DD.ProductCostElement AS ProductCostElement,
		|	DD.BaseOfAllocationByBusinessUnits AS BaseOfAllocationByBusinessUnits,
		|	DD.BaseOfAllocationByLots AS BaseOfAllocationByLots,
		|	DD.CostShareForProduction AS CostShare,
		|	DD.BusinessUnitsAreSpecifiedManually,
		|	Recorders.CostAllocationOptionManag,
		|	Recorders.CostAllocationOptionLocal,
		|	Recorders.CostAllocationOptionTax,
		|	Recorders.AITCostAllocationOption
		|INTO DistributeByDivisions
		|FROM
		|	Document.AllocationOfOtherCosts AS DD
		|		INNER JOIN Recorders AS Recorders
		|		ON (Recorders.Recorder = DD.Ref)
		|WHERE
		|	DD.AllocateToBusinessUnits
		|
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Recorder,
		|	DD.Date,
		|	DD.Organization,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.BaseOfAllocationByLots AS BaseOfAllocationByLots,
		|	DD.CostAllocationOptionManag,
		|	DD.CostAllocationOptionLocal,
		|	DD.CostAllocationOptionTax,
		|	DD.AITCostAllocationOption
		|INTO DistributeByStages
		|FROM
		|	Recorders AS DD
		|WHERE
		|	DD.AllocateByLots
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DD.Recorder,
		|	DD.Date,
		|	DD.Organization,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.CostAllocationOptionManag,
		|	DD.CostAllocationOptionLocal,
		|	DD.CostAllocationOptionTax,
		|	DD.AITCostAllocationOption,
		|
		// Cor. part
		|	WriteOff.RowID 		AS RowID,
		|	WriteOff.LineOfBusiness 	AS CorLineOfBusiness,
		|	WriteOff.Department 				AS DebitBusinessUnit,
		|	WriteOff.ExpenseItem 			AS CorExpenseItem,
		|	WriteOff.DimensionOfExpenses 			AS CorExpenditureDimension,
		|	WriteOff.AssetsLiabilitiesDimension 	AS CorDimensionOfAssetsLiabilities,
		// Calculation of the cost share.
		// The calculation formula assumes bringing to a single denominator the share of write-off for expenses
		// and the distribution base by batch.
		// In cases where there is no distribution by parties, then the cost shares
		// already have a common denominator, and it is not necessary to give it.
		|	WriteOff.CostShare / CASE 
		|		WHEN NOT DD.AllocateByLots THEN
		|			1
		|		ELSE
		|			DD.CostShareForProduction
		|	END AS CostShare
		|INTO DistributeToOtherArticles
		|FROM
		|	Recorders AS DD
		|		INNER JOIN Document.AllocationOfOtherCosts.WriteOff AS WriteOff
		|		ON DD.Recorder = WriteOff.Ref
		|
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DD.Recorder,
		|	DD.Date,
		|	DD.Organization,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.CostAllocationOptionManag,
		|	DD.CostAllocationOptionLocal,
		|	DD.CostAllocationOptionTax,
		|	DD.AITCostAllocationOption,
		|	CASE WHEN DD.AllocateByLots AND DD.CostShareForProduction = 0
		|		THEN 0
		|		ELSE DD.CostShareOfWIP / CASE 
		|			WHEN NOT DD.AllocateByLots THEN
		|				1
		|			ELSE
		|				DD.CostShareForProduction
		|			END
		|	END AS CostShare
		|INTO LeaveAsWIP
		|FROM
		|	Recorders AS DD
		|WHERE
		|	DD.LeaveAsWIP
		|
		|INDEX BY
		|	Recorder";
	
	CalculationOfCostLocalization.SubstituteAITTypeOfSeparateAccountingObjectInRequest(Query.Text, "DD_ObjectOfSeparateAccountingAIT");
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query,
		,,,NStr("vi = 'Khởi tạo bảng hệ thống để phân bổ chi phí.';
				|ru = 'Инициализация служебных таблиц для распределения затрат.';
				|en = 'Initializing internal tables for cost allocation.'; fa = 'Initializing internal tables for cost allocation.';
				|it = 'Inizializzazione di tabelle di servizio per la ripartizione delle spese.';
				|pl = 'Inicjacja tabel służbowych do podziału rozchodów.';
				|tr = 'Maliyet dağıtımı için özel tablolarının başlatılması.'"));
		
	PrepareDataOnDistributionDirectionsByDivisions(Query, CalculationParameters);
	
	// We will destroy the auxiliary temporary tables.
	NewTT = "Recorders,
	|DistributeByDivisions,DistributeToOtherArticles,DistributeByStages,LeaveAsWIP
	|,AITArticleDistributionSettings,SettingsForDistributionOfAITArticlesByCostCenter
	|,VTDivisionsWithDistributionDirection
	|";
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, 
		CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters,
			CostCalculationUniversalAlgorithms.ConnectLines(ExistingTT, NewTT)));
	
EndProcedure

// Creates a temporary table for the divisions of the distribution direction,
// in which the divisions are filled in according to the structure of subordination, according to the established distribution directions.
// Parameters:
//	Query - Query - Request from the existing MWW to distribute to divisions
//	CalculationParameters - Structure - cost calculation parameters
Procedure PrepareDataOnDistributionDirectionsByDivisions(Query, CalculationParameters)
	
	Query.Text = "SELECT TOP 0
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS DivisionOfGroup,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Enum.AllocationDirectionByBusinessUnits.EmptyRef) AS AllocationDirection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RPP.AllocationDirection AS AllocationDirection,
	|	RPP.Department AS Department
	|FROM
	|	DistributeByDivisions AS RPP
	|WHERE
	|	RPP.DistributionToLowerLevelDivision";
	
	RequestResultPackage = Query.ExecuteBatch();
	DivisionsWithDistributionDirection = RequestResultPackage[0].Unload();
	PrimaryDataByDivision = RequestResultPackage[1].Select();
	
	DirectionOfDistributionOfTechDivision = Enums.AllocationDirectionByBusinessUnits.CurrentBusinessUnit;
	While PrimaryDataByDivision.Next() Do
		If PrimaryDataByDivision.AllocationDirection = DirectionOfDistributionOfTechDivision Then
			NewRow = DivisionsWithDistributionDirection.Add();
			FillPropertyValues(NewRow, PrimaryDataByDivision);
			Continue;
		EndIf;
		
		SuitableDivisions = Documents.AllocationOfOtherCosts.DivisionsByDirection(
			PrimaryDataByDivision.Department,
			PrimaryDataByDivision.AllocationDirection
		);
			
		For Each SuitableDivision In SuitableDivisions Do
			NewRow = DivisionsWithDistributionDirection.Add();
			NewRow.DivisionOfGroup = PrimaryDataByDivision.Department;
			NewRow.AllocationDirection = PrimaryDataByDivision.AllocationDirection;
			NewRow.Department = SuitableDivision;	
		EndDo;
	EndDo;
	
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
		CalculationParameters, 
		"VTDivisionsWithDistributionDirection", DivisionsWithDistributionDirection, 
		"%1DivisionOfGroup, %1Department, %1AllocationDirection",
		"DivisionOfGroup, Department, AllocationDirection"
	);
	
EndProcedure

Function SelectionTextTemplateByDivision(OptimizationEnabled)
	
	QueryText = "
		|SELECT DISTINCT
		|	Group.NumberOfGroup,
		|	SourceDatabase.Ref AS Department
		|INTO DataTable
		|FROM
		|	GroupsOfObjectsByDistributionDirection AS Group
		|		INNER JOIN Catalog.BusinessStructure AS SourceDatabase
		|		ON &ConnectionCondition
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|";
	If OptimizationEnabled Then
		QueryText = StrReplace(QueryText, "INTO DataTable", "");
	EndIf;
	Return QueryText;

EndFunction

Function TextOfSelectionUnit(CalculationParameters)

	NameOfTemporaryObjectGroupTable = "GroupsOfObjectsByDistributionDirection";
	GettingObjectText = 
		"SELECT
		|	Attributes.Ref AS Ref,
		|	Attributes.Department AS Department,
		|	Attributes.Department.Parent AS ParentDivision,
		|	Attributes.DimensionOfExpenses AS DimensionOfExpenses,
		|	Attributes.AllocationDirection AS AllocationBaseType,
		|	Attributes.AllocationDirectionSettings AS SchemaSettings
		|FROM
		|	Document.AllocationOfOtherCosts AS Attributes
		|WHERE
		|	Attributes.AllocationDirectionSettingsChanged
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				Recorders AS Recorders
		|			WHERE
		|				Attributes.Ref = Recorders.Recorder)";

	DescriptionOfGroups = GetDescriptionOfObjectGroupsBySelectionSettings(GettingObjectText, CalculationParameters, 
		NameOfTemporaryObjectGroupTable, Undefined, True);
	
	GroupDescriptionEqualityCondition = New ValueTable;
	TypesArray = New Array;
	TypesArray.Add(Type("Number"));
	KCH = New NumberQualifiers(15, 0);
	GroupDescriptionEqualityCondition.Columns.Add("NumberOfGroup", New TypeDescription(TypesArray, , , KCH));
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.BusinessStructure"));
	GroupDescriptionEqualityCondition.Columns.Add("Department", New TypeDescription(TypesArray));

	GroupDescriptionDifficultConditions = DescriptionOfGroups.CopyColumns();

	For Each GroupDetails In DescriptionOfGroups Do
		If GroupDetails.EqualityCondition Then
			NewRow = GroupDescriptionEqualityCondition.Add();
			NewRow.NumberOfGroup = GroupDetails.NumberOfGroup;
			NewRow.Department = GroupDetails.CurrentDepartment;
		Else
			FillPropertyValues(GroupDescriptionDifficultConditions.Add(), GroupDetails);
		EndIf;
	EndDo;
	
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
		CalculationParameters.TempTablesManager, "GroupDescriptionEqualityCondition", GroupDescriptionEqualityCondition,
		"NumberOfGroup,Department");

	QueryTextDataDetails = 
		"SELECT
		|	-1 AS NumberOfGroup,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department
		|INTO DataDetails
		|WHERE
		|	FALSE";
	
	ReadyQueryTexts = New Array;
	ReadyQueryTexts.Add(TextForPlacingGroupOfObjectsInTemporaryTable(NameOfTemporaryObjectGroupTable));
	ReadyQueryTexts.Add(QueryTextDataDetails);
	
	TextsOfFormationOfFinalTable = New Array;
	TextOfDivisionByGroups = 
		"SELECT
		|	T.NumberOfGroup,
		|	T.Department
		|INTO DivisionsByGroup
		|FROM
		|	DataDetails AS T";
	TextsOfFormationOfFinalTable.Add(TextOfDivisionByGroups);
	AddTextsDescribingGroups(TextsOfFormationOfFinalTable, GroupDescriptionDifficultConditions,
		NameOfTemporaryObjectGroupTable, True);
	
	TextDescriptionOfGroupsEqualityCondition = "
		|SELECT DISTINCT
		|	T.NumberOfGroup AS NumberOfGroup,
		|	T.Department AS Department
		|FROM GroupsOfObjectsByDistributionDirection AS Group
		|	INNER JOIN GroupDescriptionEqualityCondition AS T
		|	ON Group.NumberOfGroup = T.NumberOfGroup
		|";
	
	TextsOfFormationOfFinalTable.Add(TextDescriptionOfGroupsEqualityCondition);
			
	ReadyQueryTexts.Add(MergeTexts(TextsOfFormationOfFinalTable));
	
	ReadyQueryTexts.Add("DROP DataDetails");
	ReadyQueryTexts.Add("DROP GroupDescriptionEqualityCondition");
	
	// Divisions specified manually, according to the indicator.
	ManualDivisionText =
		"SELECT DISTINCT
		|	DistributeByDivisions.Recorder,
		|	ISNULL(T.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department
		|INTO DivisionsSpecifiedManually
		|FROM
		|	DistributeByDivisions AS DistributeByDivisions
		|		LEFT JOIN Document.AllocationOfOtherCosts.ByInfobase AS T
		|		ON T.Ref = DistributeByDivisions.Recorder
		|WHERE
		|	DistributeByDivisions.BusinessUnitsAreSpecifiedManually
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DistributeByDivisions.Recorder,
		|	ISNULL(IndicatorValues.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department
		|FROM
		|	DistributeByDivisions AS DistributeByDivisions
		|		LEFT JOIN IndicatorValues AS IndicatorValues
		|		ON IndicatorValues.Factor = DistributeByDivisions.Factor
		|WHERE
		|	DistributeByDivisions.BaseOfAllocationByBusinessUnits IN (
		|		VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand),
		|		VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis))";

	ReadyQueryTexts.Add(ManualDivisionText);
	
	QueryText = MergeTexts(ReadyQueryTexts, Common.QueryBatchSeparator())
		+ Common.QueryBatchSeparator();
		
	Return QueryText;
EndFunction

// Tables: Dataofacticalmaterialsreferences
Function TextDataOnActualMaterialCosts(CalculationParameters = Undefined)
	
	CostCalculationPerformed = CostCalculationAppliedAlgorithms.CostCalculationIsPerformedForDecryption(CalculationParameters);
	DecodingDistribution = CostCalculationAppliedAlgorithms.CalculationCalledForDecryption(CalculationParameters);
	If Not CostCalculationPerformed
		And DecodingDistribution Then
		Return "";
	EndIf;
	
	QueriesTexts = New Array;
	
	// Production materials version 2.2: stages, production without orders, reports.
	QueryText = 
		"SELECT
		|	DD.Organization,
		|	DD.Lot,
		|	DD.CorLot,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorAccountingSection,
		|	DD.Count,
		|	DD.Cost,
		|	DD.AddExpensesForGoods,
		|	DD.CostExcludingVAT,
		|	DD.AdditionalExpensesExcludingVAT,
		|	DD.LocalCost,
		|	DD.AddExpensesLocal,
		|	DD.CostMan,
		|	DD.AddExpensesMan,
		|	DD.PermanentDifference,
		|	DD.CostTD,
		|	DD.CostOfPersonalIncomeTax
		|INTO TTCacheEstimatedTurnoverCost_Indexes
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|	ON CorrectedDocuments_.ReversedDocument = DD.Recorder
		|WHERE
		|	(&CostCalculationPerformed OR NOT &DecodingDistribution)
		|	AND DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DD.Organization IN(&CompanyArray)
		|	AND (DD.CorCompany IN (DD.Organization, VALUE(Catalog.Companies.EmptyRef), UNDEFINED))
		|	AND NOT DD.OfficialTypeOfMovementParish
		|	AND (NOT DD.Count = 0 
		|		OR NOT (DD.Cost + DD.AddExpensesForGoods) = 0
		|		OR NOT (DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT) = 0
		|		OR NOT (DD.LocalCost + DD.AddExpensesLocal) = 0
		|		OR NOT (DD.CostMan + DD.AddExpensesMan) = 0
		|		OR NOT DD.CostOfPersonalIncomeTax = 0
		|		)
		|	AND VALUETYPE(DD.CorItemsLocationAttributes) = TYPE(Catalog.InventoryLocationAttributeKeys)
		|	AND DD.CorItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
		|	AND VALUETYPE(DD.CorLot) = TYPE(Catalog.ProductionLots)
		|	AND DD.CorLot <> VALUE(Catalog.ProductionLots.EmptyRef)
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	AND CorrectedDocuments_.ReversedDocument IS NULL
		|
		|INDEX BY
		|	CorItemsLocationAttributes,
		|	Organization,
		|	CorLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Organization                                           AS Organization,
		|	
		|	ISNULL(DimensionContract.Department, Dimension.StorageLocation) AS Department,
		|	Dimension.ProductCostElement                              AS ProductCostElement,
		|	Dimension.Products                                   AS Material,
		|	CASE
		|		WHEN DD.CorControllingAttributes = UNDEFINED
		|			THEN VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
		|		ELSE DD.CorControllingAttributes
		|	END                                                    AS ProductsGroup,
		|	VALUETYPE(DD.Lot) IN (
		|		TYPE(Document.ProductionStage2_2),
		|		TYPE(Document.BackflushProduction))                 AS ThisIsSemiFinishedProductOfItsOwn,
		|	VALUETYPE(DD.Lot) IN (
		|		TYPE(Document.SubcontractorReport2_5))                 AS ItIsSemiFinishedProcessor,
		|	DD.CorLot                                             AS ProductionLot,
		|	UNDEFINED                                             AS ProductionOrder,
		|	0                                                        AS RowCodeProducts,
		|	ProductionLots.LineOfBusiness               AS LineOfBusiness,
		|
		|	CAST(SUM((CASE
		|		WHEN DD.Cost + DD.AddExpensesForGoods <> 0 OR &CostCalculationPerformed
		|			THEN DD.Cost + DD.AddExpensesForGoods
		|		ELSE DD.Count *
		|			(ISNULL(Prices.Cost, 0) + ISNULL(Prices.AdditionalExpenseCost, 0))
		|		END)) AS NUMBER(31, 10))                           AS Cost,
		|	CAST(SUM((CASE
		|		WHEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT <> 0 OR &CostCalculationPerformed
		|			THEN DD.CostExcludingVAT + DD.AdditionalExpensesExcludingVAT
		|		ELSE DD.Count *
		|			(ISNULL(Prices.CostExcludingVAT, 0) + ISNULL(Prices.AdditionalExpensesCostExcludingVAT, 0))
		|		END)) AS NUMBER(31, 10))                           AS CostExcludingVAT,
		|	CAST(SUM((CASE
		|		WHEN DD.LocalCost + DD.AddExpensesLocal <> 0 OR &CostCalculationPerformed
		|			THEN DD.LocalCost + DD.AddExpensesLocal
		|		ELSE DD.Count *
		|			(ISNULL(Prices.LocalCost, 0) + ISNULL(Prices.AddExpensesLocal, 0))
		|		END)) AS NUMBER(31, 10))                           AS LocalCost,
		
		|	CAST(SUM((CASE
		|		WHEN DD.CostMan + DD.AddExpensesMan <> 0 OR &CostCalculationPerformed
		|			THEN DD.CostMan + DD.AddExpensesMan
		|		ELSE DD.Count *
		|			(ISNULL(Prices.CostMan, 0) + ISNULL(Prices.AddExpensesMan, 0))
		|		END)) AS NUMBER(31, 10))                           AS CostMan,
		|	CAST(SUM((CASE
		|			WHEN DD.CostOfPersonalIncomeTax <> 0 OR &CostCalculationPerformed
		|				THEN DD.CostOfPersonalIncomeTax
		|			ELSE DD.Count *
		|				ISNULL(Prices.CostOfPersonalIncomeTax, 0)
		|		END)) AS NUMBER(31, 10))                           AS CostOfPersonalIncomeTax,
		|	SUM(DD.Count)                                     AS Count,
		|	SUM(&VolumeM3 * DD.Count)                            AS VolumeM3,
		|	SUM(&Weight * DD.Count)                              AS Weight
		|INTO DataOnMaterialCosts
		|FROM
		|	TTCacheEstimatedTurnoverCost_Indexes AS DD
		|
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON (Dimension.Ref = DD.CorItemsLocationAttributes)
		|
		|		INNER JOIN Catalog.Products AS SN
		|		ON SN.Ref = Dimension.Products
		|
		|		INNER JOIN ProductionBatchesAreSummarized AS ProductionLots
		|		ON ProductionLots.ProductionLot = DD.CorLot
		|		AND ProductionLots.Organization = DD.Organization
		|		AND ProductionLots.CostAllocationForIssue
		|
		|		LEFT JOIN Catalog.CounterpartyContracts AS DimensionContract
		|		ON DimensionContract.Ref = Dimension.StorageLocation
		|
		|		LEFT JOIN TTValueOfBatchesOfGoods AS Prices
		|		ON Prices.Organization = DD.Organization
		|			AND Prices.Lot = DD.CorLot
		|			AND Prices.LotVendorAttributes = DD.LotVendorAttributesCorr
		|			AND Prices.FinancialAccountingDimension = DD.CorControllingAttributes
		|			AND Prices.VATActivityType = DD.CorVATActivityTypes
		|			AND Prices.ItemsLocationAttributes = DD.CorItemsLocationAttributes
		|			AND Prices.InventoryOwnerAttribute = DD.CorInventoryOwnerAttribute
		|			AND Prices.AccountingSection = DD.CorAccountingSection
		|
		|GROUP BY
		|	DD.Organization,
		|	ISNULL(DimensionContract.Department, Dimension.StorageLocation), // Department
		|	Dimension.ProductCostElement,
		|	Dimension.Products,
		|	DD.CorControllingAttributes,
		|	DD.CorLot,
		|	VALUETYPE(DD.Lot) IN (
		|		TYPE(Document.ProductionStage2_2),
		|		TYPE(Document.BackflushProduction)),
		|	VALUETYPE(DD.Lot) IN (
		|		TYPE(Document.SubcontractorReport2_5)),
		|	ProductionLots.LineOfBusiness";
	
	QueriesTexts.Add(QueryText);
	CalculationOfCostLocalization.SupplementRequestWithActualMaterialCosts(QueriesTexts);
	
	QueryText = MergeTexts(QueriesTexts)
		 + "
		|INDEX BY SETS
		|(
		|	(ProductionLot,
		|	Department,
		|	Organization),
		|	(Organization, Department,
		|	LineOfBusiness, ProductsGroup)
		|)"
		+ Common.QueryBatchSeparator();
	
	If CostCalculationPerformed Then
		QueryText = StrReplace(QueryText,
			"TTCashEstimatedTurnoverCostOfGoods",
			"AccumulationRegister.InventoryCost");
		QueryText = StrReplace(QueryText,
			"NOT DD.OfficialTypeOfMovementParish",
			"DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Active");
		QueryText = StrReplace(QueryText,
			"DD.OfficialTypeOfMovementParish",
			"DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Active");
	EndIf;
	
	QueryText = QueryText + "
	|DROP TTCacheEstimatedTurnoverCost_Indexes
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	Return QueryText;
	
EndFunction

// Tables: Dataofacticalmaterialsreferences
Function TextDataOnPreliminaryMaterialCosts(CalculationParameters)
	
	CostCalculationPerformed = CostCalculationAppliedAlgorithms.CostCalculationIsPerformedForDecryption(CalculationParameters);
	DecodingDistribution = CostCalculationAppliedAlgorithms.CalculationCalledForDecryption(CalculationParameters);

	If Not DecodingDistribution
		Or CostCalculationPerformed Then
		Return "";
	EndIf;

	QueriesTexts = New Array;
	QueryText = 
		"SELECT
		|	DD.Organization                        AS Organization,
		|	Dimension.ProductCostElement           AS ProductCostElement,
		|	Dimension.Products                AS Products,
		|	Dimension.Characteristic              AS Characteristic,
		|	Dimension.StorageLocation               AS Warehouse,
		|	Dimension.Purpose                  AS Purpose,
		|	DD.AccountingSection                        AS AccountingSection,
		|	AVG(DD.Cost)                 AS Cost,
		|	AVG(DD.AdditionalExpenseCost)       AS AdditionalExpenseCost,
		|	AVG(DD.CostExcludingVAT)           AS CostExcludingVAT,
		|	AVG(DD.AdditionalExpensesCostExcludingVAT) AS AdditionalExpensesCostExcludingVAT,
		|	AVG(DD.LocalCost)             AS LocalCost,
		|	AVG(DD.AddExpensesLocal)            AS AddExpensesLocal,
		|	AVG(DD.CostMan)              AS CostMan,
		|	AVG(DD.AddExpensesMan)             AS AddExpensesMan,
		|	AVG(DD.CostOfPersonalIncomeTax)              AS CostOfPersonalIncomeTax
		|INTO TTAverageCost
		|FROM
		|	InformationRegister.GoodsCost.SliceLast(&EndOfPeriod, ) AS DD
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON DD.ItemsLocationAttributes = Dimension.Ref
		|WHERE
		|	(&DecodingDistribution AND NOT &CostCalculationPerformed)
		|
		|GROUP BY
		|	DD.Organization,
		|	DD.AccountingSection,
		|	Dimension.ProductCostElement,
		|	Dimension.Products,
		|	Dimension.Characteristic,
		|	Dimension.StorageLocation,
		|	Dimension.Purpose
		|
		|;
		|
		// production version 2.2, distribution of materials, production without orders
		|SELECT
		|	DD.Organization                                 AS Organization,
		|	Dimension.StorageLocation                        AS Department,
		|	Dimension.ProductCostElement                    AS ProductCostElement,
		|	Dimension.Products                         AS Material,
		|	CASE
		|		WHEN DD.CorControllingAttributes = UNDEFINED
		|			THEN VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
		|		ELSE DD.CorControllingAttributes
		|	END                                          AS ProductsGroup,
		|	VALUETYPE(DD.Lot) IN (
		|		TYPE(Document.ProductionStage2_2),
		|		TYPE(Document.BackflushProduction))       AS ThisIsSemiFinishedProductOfItsOwn,
		|	VALUETYPE(DD.Lot) IN (
		|		TYPE(Document.SubcontractorReport2_5))       AS ItIsSemiFinishedProcessor,
		|	DD.CorLot                                   AS ProductionLot,
		|	UNDEFINED                                   AS ProductionOrder,
		|	0                                              AS RowCodeProducts,
		|	ProductionLots.LineOfBusiness     AS LineOfBusiness,
		|
		|	SUM(DD.Count *
		|		(ISNULL(Prices.Cost, 0) + ISNULL(Prices.AdditionalExpenseCost, 0))) AS Cost,
		|	SUM(DD.Count *
		|		(ISNULL(Prices.CostExcludingVAT, 0) + ISNULL(Prices.AdditionalExpensesCostExcludingVAT, 0))) AS CostExcludingVAT,
		|	SUM(DD.Count *
		|		(ISNULL(Prices.LocalCost, 0) + ISNULL(Prices.AddExpensesLocal, 0))) AS LocalCost,
		|	SUM(DD.Count *
		|		(ISNULL(Prices.CostMan, 0) + ISNULL(Prices.AddExpensesMan, 0))) AS CostMan,
		|	SUM(DD.Count *
		|			ISNULL(Prices.CostOfPersonalIncomeTax, 0)) AS CostOfPersonalIncomeTax,
		|	SUM(DD.Count)                AS Count,
		|	SUM(&VolumeM3 * DD.Count)       AS VolumeM3,
		|	SUM(&Weight * DD.Count)         AS Weight
		|INTO DataOnMaterialCosts
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON (Dimension.Ref = DD.CorItemsLocationAttributes)
		|
		|		INNER JOIN Catalog.Products AS SN
		|		ON SN.Ref = Dimension.Products
		|
		|		INNER JOIN ProductionBatchesAreSummarized AS ProductionLots
		|		ON ProductionLots.ProductionLot = DD.CorLot
		|		AND ProductionLots.Organization = DD.Organization
		|		AND ProductionLots.CostAllocationForIssue
		|
		|		LEFT JOIN TTAverageCost AS Prices
		|		ON Prices.Organization = DD.Organization
		|			AND Prices.AccountingSection = DD.CorAccountingSection
		|			AND Prices.Products = Dimension.Products
		|			AND Prices.Characteristic = Dimension.Characteristic
		|			AND Prices.Warehouse = Dimension.StorageLocation
		|			AND Prices.Purpose = Dimension.Purpose
		|
		|WHERE
		|	(&DecodingDistribution AND NOT &CostCalculationPerformed)
		|	AND DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DD.Organization IN(&CompanyArray)
		|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND NOT DD.LotCalculation
		|	AND NOT DD.CalculationOfCost
		|	AND DD.Active
		|	AND DD.Count > 0
		|
		|GROUP BY
		|	DD.Organization,
		|	Dimension.ProductCostElement,
		|	Dimension.StorageLocation,
		|	Dimension.Products,
		|	VALUETYPE(DD.Lot) IN (
		|		TYPE(Document.ProductionStage2_2),
		|		TYPE(Document.BackflushProduction)),
		|	VALUETYPE(DD.Lot) IN (
		|		TYPE(Document.SubcontractorReport2_5)),
		|	DD.CorControllingAttributes,
		|	DD.CorLot,
		|	ProductionLots.LineOfBusiness";
	
	QueriesTexts.Add(QueryText);
	CalculationOfCostLocalization.SupplementRequestWithPreliminaryMaterialCosts(QueriesTexts);
	
	QueryText = MergeTexts(QueriesTexts)
		 + "
		|INDEX BY
		|	ProductionLot,
		|	Department,
		|	Organization"
		+ Common.QueryBatchSeparator();
	
	Return MergeTexts(QueriesTexts)
		+ Common.QueryBatchSeparator();
		
EndFunction

// W values of Indicators
Function TextIndicatorsOfDistributionByDivision() 
	Return "
	|SELECT
	|	DD.Factor
	|INTO ConstantIndicators
	|FROM
	|	DistributeByDivisions AS DD
	|		INNER JOIN Catalog.CostAllocationRules AS Rules
	|		ON DD.Factor = Rules.Ref
	|		AND Rules.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand)
	|
	|INDEX BY
	|	DD.Factor
	|;
	|
	|SELECT
	|	T.Factor,
	|	T.Department,
	|	VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand) AS AllocationBase,
	|	T.IndicatorValue
	|INTO IndicatorValues
	|FROM
	|	InformationRegister.IndicatorValuesToAllocateCosts.SliceLast(
	|			&BeginOfPeriod,
	|			Factor IN
	|				(SELECT
	|					DD.Factor
	|				FROM
	|					ConstantIndicators AS DD)) AS T
	|WHERE
	|	T.IndicatorValue > 0
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Factor,
	|	T.Department,
	|	VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis) AS AllocationBase,
	|	T.IndicatorValue
	|FROM
	|	DistributeByDivisions AS DD
	|		INNER JOIN Catalog.CostAllocationRules AS Rules
	|		ON Rules.Ref = DD.Factor	
	|		AND Rules.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis)
	|		INNER JOIN InformationRegister.IndicatorValuesToAllocateCosts AS T
	|		ON DD.Factor = T.Factor
	|		AND T.Period = &BeginOfPeriod
	|WHERE
	|	T.IndicatorValue > 0
	|
	|INDEX BY
	|	Factor
	|////////////////////////////////////////////////////////////////////////////////
	|;
	|";
	
EndFunction

Function BatchDistributionDatabaseTextTemplate(DistributionBaseIndicator)
	
	DatabaseParameters = DistributionBaseParameters(DistributionBaseIndicator);
	
	Template = 
		"SELECT DISTINCT
		|	DD.Organization
		|INTO AvailableCompanies
		|FROM
		|	Recorders AS DD
		|		INNER JOIN GroupsOfObjectsDistributedByBatch AS Group
		|		ON DD.Recorder = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|;
		|
		|SELECT DISTINCT
		|	SourceDatabase.Department AS Department,
		|	SourceDatabase.LineOfBusiness AS LineOfBusiness
		|INTO InitialDivisionsAndAreasOfActivity
		|FROM
		|	AvailableCompanies AS AvailableCompanies
		|		INNER JOIN NameOfDatabaseTable AS SourceDatabase
		|		ON SourceDatabase.Organization = AvailableCompanies.Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Recorder AS Recorder,
		|	SourceAnalytics_.Department AS Department,
		|	SourceAnalytics_.LineOfBusiness AS LineOfBusiness
		|INTO AvailableDivisionsAndAreasOfActivity
		|FROM
		|	Recorders AS DD
		|		LEFT JOIN GroupsOfObjectsByDistributionDirection AS HPGroup
		|		ON DD.Recorder = HPGroup.Object
		|		LEFT JOIN DivisionsByGroup AS GroupDivisions
		|		ON (HPGroup.NumberOfGroup = GroupDivisions.NumberOfGroup)
		|		LEFT JOIN DivisionsSpecifiedManually AS DivisionsSpecifiedManually
		|		ON DD.Recorder = DivisionsSpecifiedManually.Recorder
		|			AND (GroupDivisions.Department IS NULL
		|				OR GroupDivisions.Department = DivisionsSpecifiedManually.Department)
		|		INNER JOIN InitialDivisionsAndAreasOfActivity AS SourceAnalytics_
		|		ON (DD.AllocationDirection = VALUE(Enum.AllocationDirectionByBusinessUnits.EmptyRef)
		|					AND DivisionsSpecifiedManually.Recorder IS NULL 
		|					AND GroupDivisions.Department IS NULL
		|				OR DD.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult)
		|				OR ISNULL(DivisionsSpecifiedManually.Department, GroupDivisions.Department) = SourceAnalytics_.Department)
		|			AND (DD.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|				OR DD.ToAnyLinesOfBusiness
		|				OR DD.LineOfBusiness = SourceAnalytics_.LineOfBusiness)
		|INDEX BY
		|	Recorder,
		|	Department,
		|	LineOfBusiness
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Recorder							AS Recorder,
		|	DD.Date									AS Date,
		|	DD.ProductCostElement					AS ProductCostElement,
		|	SourceDatabase.Department				AS Department,
		|	SourceDatabase.ProductionLot			AS ProductionLot,
		|	SourceDatabase.ProductionOrder		AS ProductionOrder,
		|	SourceDatabase.RowCodeProducts			AS RowCodeProducts,
		|	SourceDatabase.LineOfBusiness	AS LineOfBusiness,
		|	SourceDatabase.ProductsGroup			AS ProductsGroup,
		|	DD.RuleOfCostAllocatingToProductionLots				AS RuleOfCostAllocatingToProductionLots,
		|	CASE
		|		WHEN &DecodingDistribution
		|			THEN &IndicatorKind
		|		ELSE
		|			UNDEFINED
		|	END									AS IndicatorKind,
		|	CASE
		|		WHEN &DecodingDistribution
		|			THEN SourceDatabase.Factor
		|		ELSE
		|			UNDEFINED
		|	END									AS Factor,
		|	CAST(SUM(&ValueWithVAT) AS NUMBER(31,10))		AS Cost,
		|	CAST(SUM(&ValueWithoutVAT) AS NUMBER(31,10))	AS CostExcludingVAT,
		|	CAST(SUM(&LocalValue) AS NUMBER(31,10))		AS LocalCost,
		|	CAST(SUM(&ValueOfMan) AS NUMBER(31,10))		AS CostMan,
		|	CAST(SUM(&NDTValue) AS NUMBER(31,10))		AS CostOfPersonalIncomeTax
		|INTO DataTable
		|FROM
		|	GroupsOfObjectsDistributedByBatch AS Group
		|		INNER JOIN Recorders AS DD
		|		ON DD.Recorder = Group.Object
		|
		|		INNER JOIN AvailableDivisionsAndAreasOfActivity AS Filter
		|		ON DD.Recorder = Filter.Recorder
		|
		|		INNER JOIN NameOfDatabaseTable AS SourceDatabase
		|		ON SourceDatabase.Organization = DD.Organization
		|			AND SourceDatabase.Department = Filter.Department
		|			AND SourceDatabase.LineOfBusiness = Filter.LineOfBusiness
		|			AND (&ConnectionCondition)
		|WHERE
		|	Group.NumberOfGroup = &NumberOfGroup
		|	AND (&QueryCondition)
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.Date,
		|	DD.ProductCostElement,
		|	DD.RuleOfCostAllocatingToProductionLots,
		|	SourceDatabase.Department,
		|	SourceDatabase.ProductionLot,
		|	SourceDatabase.ProductionOrder,
		|	SourceDatabase.RowCodeProducts,
		|	SourceDatabase.LineOfBusiness,
		|	CASE
		|		WHEN &DecodingDistribution
		|			THEN &IndicatorKind
		|		ELSE
		|			UNDEFINED
		|	END,
		|	CASE
		|		WHEN &DecodingDistribution
		|			THEN SourceDatabase.Factor
		|		ELSE
		|			UNDEFINED
		|	END,
		|	SourceDatabase.ProductsGroup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP InitialDivisionsAndAreasOfActivity
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP AvailableDivisionsAndAreasOfActivity
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP AvailableCompanies";

	Template = StrReplace(Template, "&IndicatorKind", """" + DatabaseParameters.IndicatorKind + """");
	Template = StrReplace(Template, "SourceDatabase.Factor", StrTemplate("SourceDatabase.%1", DatabaseParameters.IndicatorKind));
	Template = StrReplace(Template, "NameOfDatabaseTable", DatabaseParameters.NameOfDatabaseTable);
	Template = StrReplace(Template, "&ValueWithVAT", DatabaseParameters.ValueWithVAT);
	Template = StrReplace(Template,
		"&ValueWithoutVAT",
		?(DatabaseParameters.Property("ValueWithoutVAT"), DatabaseParameters.ValueWithoutVAT, DatabaseParameters.ValueWithVAT));
	Template = StrReplace(Template,
		"&LocalValue",
		?(DatabaseParameters.Property("LocalValue"), DatabaseParameters.LocalValue, DatabaseParameters.ValueWithVAT));
	Template = StrReplace(Template,
		"&ValueOfMan",
		?(DatabaseParameters.Property("ValueOfMan"), DatabaseParameters.ValueOfMan, DatabaseParameters.ValueWithVAT));
	Template = StrReplace(Template,
		"&NDTValue",
		?(DatabaseParameters.Property("NDTValue"), DatabaseParameters.NDTValue, DatabaseParameters.ValueWithVAT));
	Template = StrReplace(Template, 
		"&QueryCondition", 
		?(DatabaseParameters.Property("QueryCondition"), DatabaseParameters.QueryCondition, "TRUE"));
	
	Return Template;
	
EndFunction

// TT basapoetapamdetally, BasaPoEtapam,
// Uses to distribute by stages, data on pharmaceutical material costs, data on labor costs, data on products, selection of bases.
//
// Parameters:
//	CalculationParameters - Structure - calculation execution parameters
//			For more information, see explanations in the calculation code of the highest values of the individual algorithms.initializationparameterscountparties.
// 
// Returns:
// 	String - Query text
//
Function TextBaseOfDistributionOfSharesByStages(CalculationParameters) Export
	
	NameOfTemporaryObjectGroupTable = "GroupsOfObjectsDistributedByBatch";
	GettingObjectText = 
		"SELECT
		|	DistributionDetails.Ref,
		|	CASE
		|		WHEN DistributionDetails.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
		|			THEN VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount)
		|		ELSE
		|			DistributionDetails.BaseOfAllocationByLots
		|	END AS AllocationBaseType,
		|	DistributionDetails.SettingsOfBaseOfAllocationByLots AS SchemaSettings
		|FROM
		|	Document.AllocationOfOtherCosts AS DistributionDetails
		|WHERE
		|	NOT DistributionDetails.LotsAreSpecifiedManually
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				DistributeByStages AS DistributeByStages
		|			WHERE
		|				DistributionDetails.Ref = DistributeByStages.Recorder)
		|
		|UNION ALL
		|
		|SELECT
		|	DistributionDetails.Ref,
		|	VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses) AS AllocationBaseType,
		|	DistributionDetails.SettingsOfBaseOfAllocationByLots AS SchemaSettings
		|FROM
		|	Document.AllocationOfOtherCosts AS DistributionDetails
		|WHERE
		|	DistributionDetails.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				DistributeByStages AS DistributeByStages
		|			WHERE
		|				DistributionDetails.Ref = DistributeByStages.Recorder)";

	DescriptionOfGroups = GetDescriptionOfObjectGroupsBySelectionSettings(GettingObjectText, CalculationParameters, NameOfTemporaryObjectGroupTable);
	
	QueryTextDataDetails = 
		"SELECT
		|	VALUE(Document.AllocationOfOtherCosts.EmptyRef)			AS Recorder,
		|	DATETIME(1, 1, 1)													AS Date,
		|	VALUE(Catalog.ProductCostElements.EmptyRef)					AS ProductCostElement,
		|	VALUE(Catalog.BusinessStructure.EmptyRef)				AS Department,
		|	VALUE(Catalog.ProductionLots.EmptyRef)				AS ProductionLot,
		|	UNDEFINED														AS ProductionOrder,
		|	0																	AS RowCodeProducts,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef)			AS LineOfBusiness,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef)		AS RuleOfCostAllocatingToProductionLots,
		|	UNDEFINED														AS IndicatorKind,
		|	UNDEFINED														AS Factor,
		|	0																	AS Cost,
		|	0																	AS CostExcludingVAT,
		|	0																	AS LocalCost,
		|	0																	AS CostMan,
		|	0																	AS CostOfPersonalIncomeTax
		|INTO DataDetails
		|WHERE
		|	FALSE";
	
	ReadyQueryTexts = New Array;
	ReadyQueryTexts.Add(CalculationOfCostLocalization.AITSettingsQueryText("", "CostCalculationItemByItemExpenses_TextBaseOfDistributionOfSharesByStages"));
	ReadyQueryTexts.Add(TextForPlacingGroupOfObjectsInTemporaryTable(NameOfTemporaryObjectGroupTable));
	ReadyQueryTexts.Add(QueryTextDataDetails);
	AddTextsDescribingGroups(ReadyQueryTexts, DescriptionOfGroups, NameOfTemporaryObjectGroupTable);
	
	// Combine all the data tables(x) in groups by the number of tables in the query into intermediate tables basepoetapamdetally(y)
	// Then combine all the basepoetapamdetally(y) into the final table basepoetapamdetally and delete all the data tables(x) and basepoetapamdetally(y)
	ArrayDeletition = New Array;
	ArrayOfSources = New Array;
	ArrayOfSources.Add("DataDetails");

	For Each GroupDetails In DescriptionOfGroups Do
		If Not GroupDetails.Used Then
			Continue
		EndIf;
		ArrayOfSources.Add(StrTemplate("DataTable%1", Format(GroupDetails.NumberOfGroup, "NZ=0; NG=0")));
	EndDo;
	
	SourceCounter 		 = -1;
	NumberOfTablesInQuery = 254;
	NumberOfRequests_ 		 = ArrayOfSources.Count() / NumberOfTablesInQuery;
	NumberOfRequests_ 		 = Int(NumberOfRequests_) + ?(NumberOfRequests_ = Int(NumberOfRequests_), 0, 1);
	
	QueryTextTemplate2 = 
		"SELECT
		|	T.Recorder,
		|	T.Date,
		|	T.ProductCostElement,
		|	T.Department,
		|	T.ProductionLot,
		|	T.ProductionOrder,
		|	T.RowCodeProducts,
		|	T.LineOfBusiness,
		|	T.ProductsGroup,
		|	T.RuleOfCostAllocatingToProductionLots,
		|	T.IndicatorKind,
		|	T.Factor,
		|	T.Cost,
		|	T.CostExcludingVAT,
		|	T.LocalCost,
		|	T.CostMan,
		|	CASE
		|		WHEN AITExpenseRecognitionSettings.ExpenseRecognitionOption IS NOT NULL
		|			THEN T.CostOfPersonalIncomeTax
		|		ELSE 0
		|	END AS CostOfPersonalIncomeTax
		|INTO DatabaseByStagesInDetail
		|FROM
		|	DataDetails AS T
		|	LEFT JOIN Catalog.ProductionLots AS ProductionLots
		|		ON ProductionLots.Ref = T.ProductionLot
		|	LEFT JOIN AITExpenseRecognitionSettings AS AITExpenseRecognitionSettings
		|		ON ProductionLots.Organization = AITExpenseRecognitionSettings.Organization
		|		AND &T_ObjectOfSeparateAccountingAIT = AITExpenseRecognitionSettings.ObjectOfSeparateAccountingAIT
		|		AND AITExpenseRecognitionSettings.ExpensesAreIncludedInCost
		|";
		
	CalculationOfCostLocalization.SubstituteAITTypeOfSeparateAccountingObjectInRequest(QueryTextTemplate2, "T_ObjectOfSeparateAccountingAIT");
	
	// Request texts "for manual batches".
	TextDistributedManually = 
		"SELECT
		|	DD.Recorder AS Recorder,
		|	DD.Date AS Date,
		|	Data.ProductCostElement AS ProductCostElement,
		|	Data.Department AS Department,
		|	Data.ProductionLot AS ProductionLot,
		|	UNDEFINED AS ProductionOrder,
		|	0 AS RowCodeProducts,
		|	Analysts.LineOfBusiness AS LineOfBusiness,
		|	Analysts.FinancialAccountingDimension AS ProductsGroup,
		|	CASE WHEN DD.ForReleaseOfCurrentMonth THEN
		|		VALUE(Enum.RulesOfCostAllocationToProductCost.ByProducts)
		|	ELSE
		|		VALUE(Enum.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases)
		|	END AS RuleOfCostAllocatingToProductionLots,
		|	UNDEFINED AS IndicatorKind,
		|	UNDEFINED AS Factor,
		|	Data.CostShare AS Cost,
		|	Data.CostShare AS CostExcludingVAT,
		|	Data.CostShare AS LocalCost,
		|	Data.CostShare AS CostMan,
		|	
		// According to AIT, it is necessary to check the recognition settings and reset the database if expenses are not included in the cost according to the recognition settings
		|	CASE
		|		WHEN AITExpenseRecognitionSettings.ExpenseRecognitionOption IS NOT NULL
		|			THEN Data.CostShare
		|		ELSE 0
		|	END AS CostOfPersonalIncomeTax
		|
		|FROM
		|	Document.AllocationOfOtherCosts.ProductionLots AS Data
		|	INNER JOIN Recorders AS DD
		|		ON DD.Recorder = Data.Ref
		|		AND DD.LotsAreSpecifiedManually
		|	
		|	INNER JOIN ProductionBatchesAreSummarized AS Analysts
		|	ON DD.Organization = Analysts.Organization
		|	AND Data.ProductionLot = Analysts.ProductionLot
		|	AND Analysts.CostAllocationForIssue
		|	
		|	LEFT JOIN AITExpenseRecognitionSettings AS AITExpenseRecognitionSettings
		|		ON Analysts.Organization = AITExpenseRecognitionSettings.Organization
		|		AND &TableSource_ObjectOfSeparateAccountingAIT = AITExpenseRecognitionSettings.ObjectOfSeparateAccountingAIT
		|		AND AITExpenseRecognitionSettings.ExpensesAreIncludedInCost
		|";
	
	CalculationOfCostLocalization.SubstituteAITTypeOfSeparateAccountingObjectInRequest(TextDistributedManually, "", "Data", "Analysts");
	
	For QueryNumber = 1 To NumberOfRequests_ Do
		
		If QueryNumber = 1 And NumberOfRequests_ = 1 Then
			IntermediateTableName = "DatabaseByStagesInDetail";
		Else
			IntermediateTableName = "DatabaseByStagesInDetail" + Format(QueryNumber, "NZ=0; NG=0");
			ArrayDeletition.Add(IntermediateTableName);
		EndIf;
		
		ArrayOfSubqueriesTexts = New Array;
		
		For TableNumber = 1 To NumberOfTablesInQuery Do
			
			SourceCounter = SourceCounter + 1;
			If SourceCounter > ArrayOfSources.Count() - 1 Then
				Break;
			EndIf;
			
			If TableNumber = 1 Then
				TextOfCurrentRequest = StrReplace(QueryTextTemplate2, "DatabaseByStagesInDetail", IntermediateTableName);
			Else
				TextOfCurrentRequest = StrReplace(QueryTextTemplate2, "INTO DatabaseByStagesInDetail", "");
			EndIf;
			
			TextOfCurrentRequest = StrReplace(TextOfCurrentRequest, "DataDetails", ArrayOfSources[SourceCounter]);
			
			ArrayOfSubqueriesTexts.Add(TextOfCurrentRequest);
			ArrayDeletition.Add(ArrayOfSources[SourceCounter]);
			
			// After describing the data, add the distribution manually
			If TableNumber = 1 Then
				ArrayOfSubqueriesTexts.Add(TextDistributedManually);
				CalculationOfCostLocalization.SupplementRequestWithDatabasesForDistributionOfSharesByStages(ArrayOfSubqueriesTexts);
			EndIf;
			
		EndDo;
		
		ReadyQueryTexts.Add(MergeTexts(ArrayOfSubqueriesTexts)); // Data tables(x) + Data tables(x+1) + ... -> basepoetapamdetally(y)
		
	EndDo;
	
	If NumberOfRequests_ > 1 Then
		
		ArrayOfSubqueriesTexts = New Array;
		
		For QueryNumber = 1 To NumberOfRequests_ Do
			
			IntermediateTableName = "DatabaseByStagesInDetail" + Format(QueryNumber, "NZ=0; NG=0");
			
			If QueryNumber = 1 Then
				TextOfCurrentRequest = QueryTextTemplate2;
			Else
				TextOfCurrentRequest = StrReplace(QueryTextTemplate2, "INTO DatabaseByStagesInDetail", "");
			EndIf;
			
			TextOfCurrentRequest = StrReplace(TextOfCurrentRequest, "DataDetails", IntermediateTableName);
			
			ArrayOfSubqueriesTexts.Add(TextOfCurrentRequest);
			
		EndDo;
		
		CalculationOfCostLocalization.SupplementRequestWithDatabasesForDistributionOfSharesByStages(ArrayOfSubqueriesTexts);
		
		ReadyQueryTexts.Add(MergeTexts(ArrayOfSubqueriesTexts)); // Basapoetapamdetalno(x) + basapoetapamdetalno(x+1) + ... -> basapoetapamdetalno
		
	EndIf;
	
	For Each TableName In ArrayDeletition Do
		ReadyQueryTexts.Add("DROP" + " " + TableName);
	EndDo;

	Return MergeTexts(ReadyQueryTexts, Common.QueryBatchSeparator())
		+ Common.QueryBatchSeparator();
	
EndFunction

Function TextCoefficientsOfBasesByStages()
	
	QueryText = 
		"SELECT
		|	DD.Recorder,
		// To correctly calculate the price, the total amount of the distribution base should not exceed 1,000
		// , the calculation is performed as follows: when distributing 100 rubles, the price must contain all decimal places.
		|	CASE
		|		WHEN SUM(DD.Cost) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.Cost) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.Cost) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.Cost) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.Cost) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.Cost) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS ZoomRatio,
		|	CASE
		|		WHEN SUM(DD.CostExcludingVAT) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.CostExcludingVAT) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.CostExcludingVAT) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.CostExcludingVAT) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.CostExcludingVAT) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.CostExcludingVAT) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS CoefficientWithoutVAT,
		|	CASE
		|		WHEN SUM(DD.LocalCost) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.LocalCost) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.LocalCost) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.LocalCost) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.LocalCost) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.LocalCost) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS LocalCoefficient,
		|	CASE
		|		WHEN SUM(DD.CostMan) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.CostMan) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.CostMan) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.CostMan) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.CostMan) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.CostMan) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS ManSCoefficient,
		|	CASE
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS NDTCoefficient
		|INTO CoefficientsOfReductionOfDistributionBase
		|FROM
		|	DatabaseByStagesInDetail AS DD
		|
		|GROUP BY
		|	DD.Recorder";

	Return QueryText
		+ Common.QueryBatchSeparator();
		
EndFunction

Function TextOfDatabaseByStagesIsSummarized()
	
	QueryText = 
		"SELECT
		|	DD.Recorder,
		|	DD.Date,
		|	DD.ProductCostElement,
		|	DD.Department,
		|	DD.ProductionLot,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts,
		|	DD.LineOfBusiness,
		|	DD.ProductsGroup,
		|	DD.RuleOfCostAllocatingToProductionLots,
		|	CAST(SUM(DD.Cost) / MAX(ReductionCoefficients.ZoomRatio) AS NUMBER (23,10)) AS Cost,
		|	CAST(SUM(DD.CostExcludingVAT) / MAX(ReductionCoefficients.CoefficientWithoutVAT) AS NUMBER (23,10)) AS CostExcludingVAT,
		|	CAST(SUM(DD.LocalCost) / MAX(ReductionCoefficients.LocalCoefficient) AS NUMBER (23,10)) AS LocalCost,
		|	CAST(SUM(DD.CostMan) / MAX(ReductionCoefficients.ManSCoefficient) AS NUMBER (23,10)) AS CostMan,
		|	CAST(SUM(DD.CostOfPersonalIncomeTax) / MAX(ReductionCoefficients.NDTCoefficient) AS NUMBER (23,10)) AS CostOfPersonalIncomeTax
		|INTO BaseByStages
		|FROM
		|	DatabaseByStagesInDetail AS DD
		|	LEFT JOIN CoefficientsOfReductionOfDistributionBase AS ReductionCoefficients
		|		ON DD.Recorder = ReductionCoefficients.Recorder
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.Date,
		|	DD.ProductCostElement,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.ProductionLot,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts,
		|	DD.ProductsGroup,
		|	DD.RuleOfCostAllocatingToProductionLots
		|
		|INDEX BY
		|	DD.Recorder,
		|	DD.Department";
	
	Return QueryText
		+ Common.QueryBatchSeparator();

EndFunction

// In totals of basepoetapes, totals of basepoetapes of all Divisions,
// uses Basepoetapes.
Function TextResultsOfDatabaseByStages()
	Return "
	|SELECT
	|	DD.Recorder,
	|	DD.Department,
	|	UNDEFINED AS LineOfBusiness,
	|	SUM(DD.Cost) AS Cost,
	|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(DD.LocalCost) AS LocalCost,
	|	SUM(DD.CostMan) AS CostMan,
	|	SUM(DD.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax
	|INTO ResultsOfBaseByStagesOfDivisions
	|FROM
	|	BaseByStages AS DD
	|GROUP BY
	|	DD.Recorder,
	|	DD.Department
	|
	|HAVING
	|	SUM(DD.Cost) > 0
	|	OR SUM(DD.CostExcludingVAT) > 0
	|	OR SUM(DD.LocalCost) > 0
	|	OR SUM(DD.CostMan) > 0
	|	OR SUM(DD.CostOfPersonalIncomeTax) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Recorder,
	|	DD.Department,
	|	DD.LineOfBusiness,
	|	SUM(DD.Cost) AS Cost,
	|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(DD.LocalCost) AS LocalCost,
	|	SUM(DD.CostMan) AS CostMan,
	|	SUM(DD.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax
	|FROM
	|	BaseByStages AS DD
	|	INNER JOIN Recorders
	|	ON DD.Recorder = Recorders.Recorder AND NOT Recorders.LotsAreSpecifiedManually
	|GROUP BY
	|	DD.Recorder,
	|	DD.Department,
	|	DD.LineOfBusiness
	|
	|HAVING
	|	SUM(DD.Cost) > 0
	|	OR SUM(DD.CostExcludingVAT) > 0
	|	OR SUM(DD.LocalCost) > 0
	|	OR SUM(DD.CostMan) > 0
	|	OR SUM(DD.CostOfPersonalIncomeTax) > 0
	|
	|INDEX BY
	|	Recorder,
	|	Department,
	|	LineOfBusiness
	|;
	|
	|SELECT
	|	DD.Recorder,
	|	SUM(DD.Cost) AS Cost,
	|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(DD.LocalCost) AS LocalCost,
	|	SUM(DD.CostMan) AS CostMan,
	|	SUM(DD.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax
	|INTO ResultsOfDatabaseByStagesOfAllDivisions
	|FROM
	|	BaseByStages AS DD
	|GROUP BY
	|	DD.Recorder
	|
	|INDEX BY
	|	Recorder
	|;
	|";
EndFunction

Function TemplateOfTextOfDistributionBaseByDivisions(DistributionBaseIndicator)
	
	DatabaseParameters = DistributionBaseParameters(DistributionBaseIndicator);
	
	Template = 
		"SELECT
		|	DD.Recorder							AS Recorder,
		|	DD.ProductCostElement					AS ProductCostElement,
		|	SourceDatabase.Department					AS DebitBusinessUnit,
		|	SourceDatabase.ProductionLot				AS ProductionLot,
		|	SourceDatabase.ProductionOrder			AS ProductionOrder,
		|	SourceDatabase.RowCodeProducts				AS RowCodeProducts,
		|	SourceDatabase.ProductsGroup				AS ProductsGroup,
		|	CASE
		|		WHEN &DecodingDistribution
		|			THEN SourceDatabase.Factor
		|		ELSE
		|			UNDEFINED
		|	END									AS Factor,
		|	CAST(SUM(&ValueWithVAT) AS NUMBER(31,10))	 AS Cost,
		|	CAST(SUM(&ValueWithoutVAT) AS NUMBER(31,10)) AS CostExcludingVAT,
		|	CAST(SUM(&LocalValue) AS NUMBER(31,10))	 AS LocalCost,
		|	CAST(SUM(&ValueOfMan) AS NUMBER(31,10))	 AS CostMan,
		|	CAST(SUM(&NDTValue) AS NUMBER(31,10))	 AS CostOfPersonalIncomeTax
		|INTO DataTable
		|FROM
		|	Recorders AS DD
		|
		|		INNER JOIN GroupsOfObjectsDistributedByDivision AS Group
		|		ON DD.Recorder = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|		
		|		LEFT JOIN GroupsOfObjectsByDistributionDirection AS HPGroup
		|		ON DD.Recorder = HPGroup.Object
		|
		|		LEFT JOIN DivisionsByGroup AS GroupDivisions
		|		ON HPGroup.NumberOfGroup = GroupDivisions.NumberOfGroup
		|
		|		INNER JOIN NameOfDatabaseTable AS SourceDatabase
		|		ON SourceDatabase.Organization = DD.Organization
		|			AND &ConnectionCondition
		|			AND (GroupDivisions.Department IS NULL
		|				OR GroupDivisions.Department = SourceDatabase.Department)
		|			AND (DD.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|				OR DD.ToAnyLinesOfBusiness
		|				OR DD.LineOfBusiness = SourceDatabase.LineOfBusiness)
		|WHERE
		|	&QueryCondition
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.Date,
		|	DD.ProductCostElement,
		|	DD.RuleOfCostAllocatingToProductionLots,
		|	SourceDatabase.Department,
		|	SourceDatabase.ProductionLot,
		|	SourceDatabase.ProductionOrder,
		|	SourceDatabase.RowCodeProducts,
		|	SourceDatabase.LineOfBusiness,
		|	CASE
		|		WHEN &DecodingDistribution
		|			THEN &IndicatorKind
		|		ELSE
		|			UNDEFINED
		|	END,
		|	CASE
		|		WHEN &DecodingDistribution
		|			THEN SourceDatabase.Factor
		|		ELSE
		|			UNDEFINED
		|	END,
		|	SourceDatabase.ProductsGroup";

	Template = StrReplace(Template, "&IndicatorKind", """" + DatabaseParameters.IndicatorKind + """");
	Template = StrReplace(Template, ".Factor", StrTemplate(".%1", DatabaseParameters.IndicatorKind));
	Template = StrReplace(Template, "NameOfDatabaseTable", DatabaseParameters.NameOfDatabaseTable);
	Template = StrReplace(Template, "&ValueWithVAT", 
		StrReplace(DatabaseParameters.ValueWithVAT, "BaseOfAllocationByLots", "BaseOfAllocationByBusinessUnits"));
	Template = StrReplace(Template,
		"&ValueWithoutVAT",
		StrReplace(?(DatabaseParameters.Property("ValueWithoutVAT"),
			DatabaseParameters.ValueWithoutVAT,
			DatabaseParameters.ValueWithVAT), "BaseOfAllocationByLots", "BaseOfAllocationByBusinessUnits"));
	Template = StrReplace(Template,
		"&LocalValue",
		StrReplace(?(DatabaseParameters.Property("LocalValue"), 
			DatabaseParameters.LocalValue,
			DatabaseParameters.ValueWithVAT), "BaseOfAllocationByLots", "BaseOfAllocationByBusinessUnits"));
	Template = StrReplace(Template,
		"&ValueOfMan",
		StrReplace(?(DatabaseParameters.Property("ValueOfMan"),
			DatabaseParameters.ValueOfMan,
			DatabaseParameters.ValueWithVAT), "BaseOfAllocationByLots", "BaseOfAllocationByBusinessUnits"));
	Template = StrReplace(Template,
		"&NDTValue",
		StrReplace(?(DatabaseParameters.Property("NDTValue"),
			DatabaseParameters.NDTValue,
			DatabaseParameters.ValueWithVAT), "BaseOfAllocationByLots", "BaseOfAllocationByBusinessUnits"));
	Template = StrReplace(Template, 
		"&QueryCondition", 
		?(DatabaseParameters.Property("QueryCondition"), DatabaseParameters.QueryCondition, "TRUE"));
	
	Return Template;
	
EndFunction

Function DistributionBaseParameters(DistributionBaseIndicator)
	
	Parameters = New Structure;
	
	If DistributionBaseIndicator = "MaterialCosts" Then
		
		Parameters.Insert("IndicatorKind", "Material");
		Parameters.Insert("NameOfDatabaseTable", "DataOnMaterialCosts");
		Parameters.Insert("ValueWithVAT", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount)
											|		THEN SourceDatabase.Cost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.Cost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials)
											|		THEN SourceDatabase.Weight
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials)
											|		THEN SourceDatabase.VolumeM3
											|END");
		Parameters.Insert("ValueWithoutVAT", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount)
											|		THEN SourceDatabase.CostExcludingVAT
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.CostExcludingVAT
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials)
											|		THEN SourceDatabase.Weight
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials)
											|		THEN SourceDatabase.VolumeM3
											|END");
		Parameters.Insert("LocalValue", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount)
											|		THEN SourceDatabase.LocalCost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.LocalCost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials)
											|		THEN SourceDatabase.Weight
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials)
											|		THEN SourceDatabase.VolumeM3
											|END");
		Parameters.Insert("ValueOfMan", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount)
											|		THEN SourceDatabase.CostMan
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.CostMan
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials)
											|		THEN SourceDatabase.Weight
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials)
											|		THEN SourceDatabase.VolumeM3
											|END");
		Parameters.Insert("NDTValue", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount)
											|		THEN SourceDatabase.CostOfPersonalIncomeTax
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.CostOfPersonalIncomeTax
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials)
											|		THEN SourceDatabase.Weight
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials)
											|		THEN SourceDatabase.VolumeM3
											|END");
		
	ElsIf DistributionBaseIndicator = "LaborCosts" Then
		
		Parameters.Insert("IndicatorKind", "WorkKind");
		Parameters.Insert("NameOfDatabaseTable", "DataOnLaborCostsCollapsed");
		Parameters.Insert("ValueWithVAT", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses)
											|		THEN SourceDatabase.Cost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.Cost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel)
											|		THEN SourceDatabase.StandardCost
											|END");
		Parameters.Insert("LocalValue", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses)
											|		THEN SourceDatabase.LocalCost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.LocalCost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel)
											|		THEN SourceDatabase.StandardCost
											|END");
		Parameters.Insert("NDTValue", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses)
											|		THEN SourceDatabase.CostOfPersonalIncomeTax
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.CostOfPersonalIncomeTax
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel)
											|		THEN SourceDatabase.StandardCost
											|END");
		
	ElsIf DistributionBaseIndicator = "ManufacturedProduct" Then
		
		
		Parameters.Insert("IndicatorKind", "ManufacturedProduct");
		Parameters.Insert("NameOfDatabaseTable", "ProductDataCollapsed");
		Parameters.Insert("ValueWithVAT", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantity)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolume)
											|		THEN SourceDatabase.VolumeM3
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeight)
											|		THEN SourceDatabase.Weight
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCost)
											|		THEN SourceDatabase.Cost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases)
											|		THEN SourceDatabase.CountPlan + SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases)
											|		THEN SourceDatabase.ScopePlan + SourceDatabase.VolumeM3
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases)
											|		THEN SourceDatabase.WeightPlan + SourceDatabase.Weight
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases)
											|		THEN SourceDatabase.CostPlan + SourceDatabase.Cost
											|END");
		
		Parameters.Insert("QueryCondition", 
			"(DD.BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantity),
			|									VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolume),
			|									VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeight),
			|									VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCost))
			|	AND SourceDatabase.ProductionDate BETWEEN &BeginOfPeriod AND &EndOfPeriod)
			|   OR DD.BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases),
			|										VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases),
			|										VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases),
			|										VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases))");

	EndIf;
	
	Return Parameters;
	
EndFunction

// W Baseboardtableentry, Butaperazine,
// Uses Basepoints, Distributesdistribution, Datesofacticalmaterialsattributes,
// Data On Labor Costs, Values Of Indicators.
Function TextBaseOfDistributionOfSharesByDivisions(CalculationParameters)
		
	NameOfTemporaryObjectGroupTable = "GroupsOfObjectsDistributedByDivision";
	GettingObjectText = 
		"SELECT
		|	DistributionDetails.Ref,
		|	CASE
		|		WHEN DistributionDetails.BaseOfAllocationByBusinessUnits = VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
		|			THEN VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount)
		|		ELSE
		|			DistributionDetails.BaseOfAllocationByBusinessUnits
		|	END AS AllocationBaseType,
		|	DistributionDetails.SettingsOfBaseOfAllocationByLots AS SchemaSettings
		|FROM
		|	Document.AllocationOfOtherCosts AS DistributionDetails
		|WHERE
		|	DistributionDetails.BaseOfAllocationByBusinessUnits IN (
		|		VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts),
		|		VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount),
		|		VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses))
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				DistributeByDivisions AS DistributeByDivisions
		|			WHERE
		|				DistributionDetails.Ref = DistributeByDivisions.Recorder)
		|
		|UNION ALL
		|
		|SELECT
		|	DistributionDetails.Ref,
		|	VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses) AS AllocationBaseType,
		|	DistributionDetails.SettingsOfBaseOfAllocationByLots AS SchemaSettings
		|FROM
		|	Document.AllocationOfOtherCosts AS DistributionDetails
		|WHERE
		|	DistributionDetails.BaseOfAllocationByBusinessUnits = VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				DistributeByDivisions AS DistributeByDivisions
		|			WHERE
		|				DistributionDetails.Ref = DistributeByDivisions.Recorder)";

	UnavailableFields = New Array;
	UnavailableFields.Add("Material");
	UnavailableFields.Add("WorkKind");
	UnavailableFields.Add("ManufacturedProduct");
	DescriptionOfGroups = GetDescriptionOfObjectGroupsBySelectionSettings(GettingObjectText, CalculationParameters,
		NameOfTemporaryObjectGroupTable, UnavailableFields);
		
	QueryTextDataDetails = 
		"SELECT
		|	VALUE(Document.AllocationOfOtherCosts.EmptyRef)			AS Recorder,
		|	VALUE(Catalog.ProductCostElements.EmptyRef)					AS ProductCostElement,
		|	VALUE(Catalog.BusinessStructure.EmptyRef)				AS DebitBusinessUnit,
		|	VALUE(Catalog.ProductionLots.EmptyRef)				AS ProductionLot,
		|	UNDEFINED														AS ProductionOrder,
		|	0																	AS RowCodeProducts,
		|	UNDEFINED														AS ProductsGroup,
		|	UNDEFINED														AS Factor,
		|	0																	AS Cost,
		|	0																	AS CostExcludingVAT,
		|	0																	AS LocalCost,
		|	0																	AS CostMan,
		|	0																	AS CostOfPersonalIncomeTax
		|INTO DataDetails
		|WHERE
		|	FALSE";
	
	ReadyQueryTexts = New Array;
	ReadyQueryTexts.Add(TextForPlacingGroupOfObjectsInTemporaryTable(NameOfTemporaryObjectGroupTable));
	ReadyQueryTexts.Add(QueryTextDataDetails);
	AddTextsDescribingGroups(ReadyQueryTexts, DescriptionOfGroups, NameOfTemporaryObjectGroupTable);
	
	TextsOfFormationOfFinalTable = New Array;
	TextBaseByDivisionInDetail = 
		"SELECT
		|	T.Recorder,
		|	T.ProductCostElement,
		|	T.DebitBusinessUnit,
		|	T.ProductionLot,
		|	T.ProductionOrder,
		|	T.RowCodeProducts,
		|	T.ProductsGroup,
		|	T.Factor,
		|	T.Cost,
		|	T.CostExcludingVAT,
		|	T.LocalCost,
		|	T.CostMan,
		|	T.CostOfPersonalIncomeTax
		|INTO DatabaseByDivisionsInDetail
		|FROM
		|	DataDetails AS T";
	TextsOfFormationOfFinalTable.Add(TextBaseByDivisionInDetail);
	
	TextBaseByDivisionInDetail = StrReplace(TextBaseByDivisionInDetail, "INTO DatabaseByDivisionsInDetail", "");
	For Each GroupDetails In DescriptionOfGroups Do
		TextsOfFormationOfFinalTable.Add(
			StrReplace(TextBaseByDivisionInDetail, 
				"DataDetails", StrTemplate("DataTable%1",
				Format(GroupDetails.NumberOfGroup, "NZ=0; NG=0"))));
	EndDo;
			
	// The texts of requests distributed manually.
	TextDistributedManually = 
		"SELECT
		|	DD.Recorder              AS Recorder,
		|	Data.ProductCostElement    AS ProductCostElement,
		|	Data.Department        AS DebitBusinessUnit,
		|	VALUE(Catalog.ProductionLots.EmptyRef) AS ProductionLot,
		|	UNDEFINED                AS ProductionOrder,
		|	0                           AS RowCodeProducts,
		|	UNDEFINED                AS ProductsGroup,
		|	UNDEFINED                AS MaterialTypeOfWork,
		|	Data.CostShare 		AS Cost,
		|	Data.CostShare 		AS CostExcludingVAT,
		|	Data.CostShare 		AS LocalCost,
		|	Data.CostShare 		AS CostMan,
		|	Data.CostShare 		AS CostOfPersonalIncomeTax
		|FROM
		|	DistributeByDivisions AS DD
		|		INNER JOIN Document.AllocationOfOtherCosts.ByInfobase AS Data
		|		ON Data.Ref = DD.Recorder
		|WHERE
		|	DD.BusinessUnitsAreSpecifiedManually";
	TextsOfFormationOfFinalTable.Add(TextDistributedManually);
	
	// By indicators.
	TextByIndicators = 
		"SELECT
		|	DD.Recorder				AS Recorder,
		|	DD.ProductCostElement		AS ProductCostElement,
		|	Data.Department		AS DebitBusinessUnit,
		|	VALUE(Catalog.ProductionLots.EmptyRef) AS ProductionLot,
		|	UNDEFINED				AS ProductionOrder,
		|	0							AS RowCodeProducts,
		|	UNDEFINED				AS ProductsGroup,
		|	UNDEFINED				AS MaterialTypeOfWork,
		|	Data.IndicatorValue	AS Cost,
		|	Data.IndicatorValue	AS CostExcludingVAT,
		|	Data.IndicatorValue	AS LocalCost,
		|	Data.IndicatorValue	AS CostMan,
		|	Data.IndicatorValue	AS CostOfPersonalIncomeTax
		|FROM
		|	DistributeByDivisions AS DD
		|		LEFT JOIN GroupsOfObjectsByDistributionDirection AS HPGroup
		|		ON DD.Recorder = HPGroup.Object
		|
		|		LEFT JOIN DivisionsByGroup AS GroupDivisions
		|		ON HPGroup.NumberOfGroup = GroupDivisions.NumberOfGroup
		|		
		|		LEFT JOIN IndicatorValues AS Data
		|		ON Data.Factor = DD.Factor
		|			AND (GroupDivisions.Department IS NULL
		|				OR GroupDivisions.Department = Data.Department)
		|
		|		LEFT JOIN VTDivisionsWithDistributionDirection AS CW
		|		ON DD.DistributionToLowerLevelDivision
		|			AND DD.AllocationDirection = CW.AllocationDirection
		|			AND Data.Department = CW.Department
		|			AND DD.Department = CW.DivisionOfGroup
		|
		|WHERE
		|	NOT Data.IndicatorValue IS NULL
		|	AND (DD.BaseOfAllocationByBusinessUnits = VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand)
		|		OR DD.BaseOfAllocationByBusinessUnits = VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis))
		|	AND (NOT DD.DistributionToLowerLevelDivision OR NOT CW.Department IS NULL)";
		
	TextsOfFormationOfFinalTable.Add(TextByIndicators);
	
	ReadyQueryTexts.Add(MergeTexts(TextsOfFormationOfFinalTable));
	ReadyQueryTexts.Add("DROP DataDetails");
	For Each GroupDetails In DescriptionOfGroups Do
		ReadyQueryTexts.Add(
			StrTemplate("DROP DataTable%1",
				Format(GroupDetails.NumberOfGroup, "NZ=0; NG=0")));
	EndDo;
	
	Return MergeTexts(ReadyQueryTexts, Common.QueryBatchSeparator())
		+ Common.QueryBatchSeparator();
	
EndFunction

Function TextBaseByDivisionSummary()
	
	QueryText =
		"SELECT
		|	DD.Recorder,
		|	CASE
		|		WHEN SUM(DD.Cost) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.Cost) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.Cost) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.Cost) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.Cost) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.Cost) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS ZoomRatio,
		|	CASE
		|		WHEN SUM(DD.CostExcludingVAT) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.CostExcludingVAT) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.CostExcludingVAT) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.CostExcludingVAT) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.CostExcludingVAT) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.CostExcludingVAT) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS CoefficientWithoutVAT,
		|	CASE
		|		WHEN SUM(DD.LocalCost) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.LocalCost) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.LocalCost) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.LocalCost) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.LocalCost) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.LocalCost) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS LocalCoefficient,
		|	CASE
		|		WHEN SUM(DD.CostMan) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.CostMan) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.CostMan) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.CostMan) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.CostMan) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.CostMan) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS ManSCoefficient,
		|	CASE
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS NDTCoefficient
		|INTO CoefficientsOfReductionOfBaseByDivisions
		|FROM
		|	DatabaseByDivisionsInDetail AS DD
		|		INNER JOIN ResultsOfBaseByStagesOfDivisions AS ResultsByStages
		|			ON DD.Recorder = ResultsByStages.Recorder
		|			AND DD.DebitBusinessUnit = ResultsByStages.Department
		|			AND ResultsByStages.LineOfBusiness = UNDEFINED
		|
		|GROUP BY
		|	DD.Recorder
		|
		|INDEX BY
		|	DD.Recorder
		|;
		|
		|SELECT
		|	DD.Recorder				AS Recorder,
		|	DD.DebitBusinessUnit			AS DebitBusinessUnit,
		|	DD.ProductCostElement		AS ProductCostElement,
		|
		|	SUM(DD.Cost) / MAX(Coefficients.ZoomRatio)				AS Cost,
		|	SUM(DD.CostExcludingVAT) / MAX(Coefficients.CoefficientWithoutVAT)	AS CostExcludingVAT,
		|	SUM(DD.LocalCost) / MAX(Coefficients.LocalCoefficient)		AS LocalCost,
		|	SUM(DD.CostMan) / MAX(Coefficients.ManSCoefficient)			AS CostMan,
		|	SUM(DD.CostOfPersonalIncomeTax) / MAX(Coefficients.NDTCoefficient)			AS CostOfPersonalIncomeTax
		|INTO DatabaseByDivision
		|FROM
		|	DatabaseByDivisionsInDetail AS DD
		// A division is included in the database only if there is a base for distribution by stages of this division.
		|		INNER JOIN ResultsOfBaseByStagesOfDivisions AS ResultsByStages
		|		ON DD.Recorder = ResultsByStages.Recorder
		|			AND DD.DebitBusinessUnit = ResultsByStages.Department
		|			AND ResultsByStages.LineOfBusiness = UNDEFINED
		|		INNER JOIN CoefficientsOfReductionOfBaseByDivisions AS Coefficients
		|		ON DD.Recorder = Coefficients.Recorder
		|
		|GROUP BY
		|	DD.Recorder,
		|	DD.DebitBusinessUnit,
		|	DD.ProductCostElement
		|
		|HAVING
		|	SUM(DD.Cost) > 0
		|	OR SUM(DD.CostExcludingVAT) > 0
		|	OR SUM(DD.LocalCost) > 0
		|	OR SUM(DD.CostMan) > 0
		|	OR SUM(DD.CostOfPersonalIncomeTax) > 0
		|
		|INDEX BY
		|	Recorder,
		|	DebitBusinessUnit";
	
	Return QueryText
		+ Common.QueryBatchSeparator();
		
EndFunction
// Wt Totalbazypod Divisions
// Uses Butaperazine.
Function TextBaseResultsByDivision()
	Return "
	|SELECT
	|	DD.Recorder,
	|	SUM(DD.Cost) 		AS Cost,
	|	SUM(DD.CostExcludingVAT) 	AS CostExcludingVAT,
	|	SUM(DD.LocalCost) 	AS LocalCost,
	|	SUM(DD.CostMan) 		AS CostMan,
	|	SUM(DD.CostOfPersonalIncomeTax) 		AS CostOfPersonalIncomeTax
	|INTO BaseResultsByDivision
	|FROM
	|	DatabaseByDivision AS DD
	|GROUP BY
	|	DD.Recorder
	|
	|INDEX BY
	|	Recorder
	|;
	|";
EndFunction

// Table: Dnieperdonetsk
Function TextDataOnLaborCostsCollapsed()
	
	Return "
	|SELECT
	|	DD.Organization						AS Organization,
	|	DD.Department					AS Department,
	|	DD.ProductCostElement				AS ProductCostElement,
	|	DD.WorkKind                         AS WorkKind,
	|	DD.ProductsGroup					AS ProductsGroup,
	|	DD.ProductionLot               AS ProductionLot,
	|	DD.ProductionOrder              AS ProductionOrder,
	|	DD.RowCodeProducts				AS RowCodeProducts,
	|	DD.LineOfBusiness          AS LineOfBusiness,
	|	SUM(DD.Count)				AS Count,
	|	SUM(DD.StandardCost)		AS StandardCost,
	|	SUM(DD.Cost)					AS Cost,
	|	SUM(DD.LocalCost)				AS LocalCost,
	|	SUM(DD.CostOfPersonalIncomeTax)				AS CostOfPersonalIncomeTax
	|INTO DataOnLaborCostsCollapsed
	|FROM
	|	DataOnLaborCosts AS DD
	|
	|GROUP BY
	|	DD.Organization,
	|	DD.Department,
	|	DD.ProductCostElement,
	|	DD.WorkKind,
	|	DD.ProductsGroup,
	|	DD.ProductionLot,
	|	DD.ProductionOrder,
	|	DD.RowCodeProducts,
	|	DD.LineOfBusiness
	|
	|;
	|";
	
EndFunction

// Table: Anniepopokios
Function TextOutputDataCollapsed()
	
	Return "
	|SELECT
	|	DD.Organization                  AS Organization,
	|	BEGINOFPERIOD(DD.ProductionDate, MONTH) AS ProductionDate,
	|	DD.Department                AS Department,
	|	DD.ProductCostElement            AS ProductCostElement,
	|	DD.ManufacturedProduct                    AS ManufacturedProduct,
	|	DD.ProductsGroup              AS ProductsGroup,
	|	DD.ProductionLot           AS ProductionLot,
	|	DD.LineOfBusiness      AS LineOfBusiness,
	|	DD.ProductionOrder          AS ProductionOrder,
	|	DD.RowCodeProducts           AS RowCodeProducts,
	|	SUM(DD.Count)            AS Count,
	|	SUM(DD.CountPlan)        AS CountPlan,
	|	SUM(DD.VolumeM3)                 AS VolumeM3,
	|	SUM(DD.ScopePlan)             AS ScopePlan,
	|	SUM(DD.Weight)                   AS Weight,
	|	SUM(DD.WeightPlan)               AS WeightPlan,
	|	SUM(DD.Cost)             AS Cost,
	|	SUM(DD.CostPlan)         AS CostPlan
	|INTO ProductDataCollapsed
	|FROM
	|	ProductData_6 AS DD
	|
	|GROUP BY
	|	DD.Organization,
	|	BEGINOFPERIOD(DD.ProductionDate, MONTH),
	|	DD.ProductCostElement,
	|	DD.Department,
	|	DD.ManufacturedProduct,
	|	DD.ProductsGroup,
	|	DD.ProductionLot,
	|	DD.LineOfBusiness,
	|	DD.ProductionOrder,
	|	DD.RowCodeProducts
	|;
	|";
	
EndFunction


Function TextDistributionBetweenPartiesPreliminary()
	
	Return "
	|SELECT DISTINCT
	|	ByBatches.Date,
	|	ByBatches.Recorder AS Recorder,
	|	ByBatches.Organization,
	|	ByBatches.Department,
	|	ByBatches.LineOfBusiness,
	|	ByBatches.ExpenseItem,
	|	ByBatches.DimensionOfExpenses,
	|	ByBatches.CostAllocationOptionManag,
	|	ByBatches.CostAllocationOptionLocal,
	|	ByBatches.CostAllocationOptionTax,
	|	ByBatches.AITCostAllocationOption,
	|	Recorders.ManagementAccounting,
	|	Recorders.LocalAccounting,
	|	Recorders.TaxAccounting,
	|	Recorders.AIT,
	|	Recorders.LotsAreSpecifiedManually,
	|	Recorders.ToAnyLinesOfBusiness,
	|	CASE
	|		WHEN ByBatches.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		  OR Recorders.LotsAreSpecifiedManually
	|		  OR Recorders.ToAnyLinesOfBusiness
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS WithoutRegardToDirection
	|INTO DistributeByStagesWithRecorders
	|FROM
	|	DistributeByStages AS ByBatches
	|	INNER JOIN Recorders AS Recorders
	|		ON	Recorders.Organization = ByBatches.Organization
	|		AND	Recorders.Recorder = ByBatches.Recorder
	|		AND	Recorders.ExpenseItem = ByBatches.ExpenseItem
	|		AND	Recorders.LineOfBusiness = ByBatches.LineOfBusiness
	|
	|INDEX BY
	|	Recorder
	|;
	|////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	ByBatches.Date,
	|	ByBatches.Recorder AS Recorder,
	|	ByBatches.Organization,
	|	ByBatches.Department AS Department,
	|	ByBatches.LineOfBusiness AS LineOfBusiness,
	|	ByBatches.ExpenseItem,
	|	ByBatches.DimensionOfExpenses,
	|	ByBatches.CostAllocationOptionManag,
	|	ByBatches.CostAllocationOptionLocal,
	|	ByBatches.CostAllocationOptionTax,
	|	ByBatches.AITCostAllocationOption,
	|	ByBatches.ManagementAccounting,
	|	ByBatches.LocalAccounting,
	|	ByBatches.TaxAccounting,
	|	ByBatches.AIT,
	|	ByBatches.LotsAreSpecifiedManually,
	|	ByBatches.ToAnyLinesOfBusiness,
	|
	|	BaseByStages.ProductsGroup,
	|	BaseByStages.RuleOfCostAllocatingToProductionLots,
	|	BaseByStages.Department AS DebitBusinessUnit,
	|	BaseByStages.LineOfBusiness AS CorLineOfBusiness,
	|	BaseByStages.ProductionLot,
	|	BaseByStages.ProductionOrder,
	|	BaseByStages.RowCodeProducts,
	|	BaseByStages.ProductCostElement,
	|
	|	CASE
			// lots are specified manually, the total of the database is used without taking into account the areas of activity (LB)
	|	  WHEN ByBatches.LotsAreSpecifiedManually
			// the document states "For parties of any line of activity", the result of the database is used without taking into account LB
	|		OR NOT ByBatches.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|			AND ByBatches.ToAnyLinesOfBusiness 
			// the distributed expense has an empty LB, the total of the database is used without taking into account the LB
	|		OR ByBatches.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|			THEN TRUE
	|			ELSE FALSE
	|	END AS WithoutRegardToDirection,
	|
	|	SUM(BaseByStages.Cost) AS Cost,
	|	SUM(BaseByStages.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(BaseByStages.LocalCost) AS LocalCost,
	|	SUM(BaseByStages.CostMan) AS CostMan
	|INTO DistributeByStagesWithBase
	|FROM
	|	DistributeByStagesWithRecorders AS ByBatches
	|	INNER JOIN BaseByStages AS BaseByStages
	|		ON	ByBatches.Recorder = BaseByStages.Recorder
	|			AND (ByBatches.WithoutRegardToDirection
	|				OR ByBatches.LineOfBusiness = BaseByStages.LineOfBusiness)
	|GROUP BY
	|	ByBatches.Date,
	|	ByBatches.Recorder,
	|	ByBatches.Organization,
	|	ByBatches.Department,
	|	ByBatches.LineOfBusiness,
	|	ByBatches.ExpenseItem,
	|	ByBatches.DimensionOfExpenses,
	|	ByBatches.CostAllocationOptionManag,
	|	ByBatches.CostAllocationOptionLocal,
	|	ByBatches.CostAllocationOptionTax,
	|	ByBatches.AITCostAllocationOption,
	|	ByBatches.ManagementAccounting,
	|	ByBatches.LocalAccounting,
	|	ByBatches.TaxAccounting,
	|	ByBatches.AIT,
	|	ByBatches.LotsAreSpecifiedManually,
	|	ByBatches.ToAnyLinesOfBusiness,
	|
	|	BaseByStages.ProductsGroup,
	|	BaseByStages.RuleOfCostAllocatingToProductionLots,
	|	BaseByStages.Department,
	|	BaseByStages.LineOfBusiness,
	|	BaseByStages.ProductionLot,
	|	BaseByStages.ProductionOrder,
	|	BaseByStages.RowCodeProducts,
	|	BaseByStages.ProductCostElement,
	|	CASE
	|	  WHEN ByBatches.LotsAreSpecifiedManually
	|		OR NOT ByBatches.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|			AND ByBatches.ToAnyLinesOfBusiness 
	|		OR ByBatches.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|			THEN TRUE
	|			ELSE FALSE
	|	END
	|
	|INDEX BY
	|	Recorder,
	|	DebitBusinessUnit,
	|	LineOfBusiness
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	ByBatches.Date,
	|	ByBatches.Recorder AS Recorder,
	|	ByBatches.Organization,
	|	ByBatches.Department,
	|	ByBatches.LineOfBusiness,
	|	ByBatches.ExpenseItem,
	|	ByBatches.DimensionOfExpenses,
	|	ByBatches.CostAllocationOptionManag,
	|	ByBatches.CostAllocationOptionLocal,
	|	ByBatches.CostAllocationOptionTax,
	|	ByBatches.AITCostAllocationOption,
	|	ByBatches.ManagementAccounting,
	|	ByBatches.LocalAccounting,
	|	ByBatches.TaxAccounting,
	|	ByBatches.AIT,
	|	ByBatches.LotsAreSpecifiedManually,
	|	ByBatches.ToAnyLinesOfBusiness,
	|
	|	ByBatches.ProductsGroup,
	|	ByBatches.RuleOfCostAllocatingToProductionLots,
	|	ByBatches.DebitBusinessUnit AS DebitBusinessUnit,
	|	ByBatches.CorLineOfBusiness,
	|	ByBatches.ProductionLot,
	|	ByBatches.ProductionOrder,
	|	ByBatches.RowCodeProducts,
	|	ByBatches.ProductCostElement,
	|
	|	ByBatches.Cost,
	|	ByBatches.CostExcludingVAT,
	|	ByBatches.LocalCost,
	|	ByBatches.CostMan,
	|
	|	SUM(CAST(CASE 
	|		WHEN ResultsOfBaseByStagesOfDivisions.Cost = 0
	|			THEN 0
	|		ELSE
	|			CAST(ByBatches.Cost AS NUMBER(28, 10)) / CAST(ResultsOfBaseByStagesOfDivisions.Cost AS NUMBER(28, 10))
	|	END AS NUMBER (28, 10))) AS CostShare,
	|	SUM(CAST(CASE 
	|		WHEN ResultsOfBaseByStagesOfDivisions.CostExcludingVAT = 0
	|			THEN 0
	|		ELSE
	|			CAST(ByBatches.CostExcludingVAT AS NUMBER(28, 10)) / CAST(ResultsOfBaseByStagesOfDivisions.CostExcludingVAT AS NUMBER(28, 10))
	|	END AS NUMBER (28, 10))) AS ShareOfValueWithoutVAT,
	|	SUM(CAST(CASE 
	|		WHEN ResultsOfBaseByStagesOfDivisions.LocalCost = 0
	|			THEN 0
	|		ELSE
	|			CAST(ByBatches.LocalCost AS NUMBER(28, 10)) / CAST(ResultsOfBaseByStagesOfDivisions.LocalCost AS NUMBER(28, 10))
	|	END AS NUMBER (28, 10))) AS ShareOfLocalValue,
	|	SUM(CAST(CASE 
	|		WHEN ResultsOfBaseByStagesOfDivisions.CostMan = 0
	|			THEN 0
	|		ELSE
	|			CAST(ByBatches.CostMan AS NUMBER(28, 10)) / CAST(ResultsOfBaseByStagesOfDivisions.CostMan AS NUMBER(28, 10))
	|	END AS NUMBER (28, 10))) AS ShareOfManSCost
	|INTO DistributeByStagesWithBaseOfDivisions
	|FROM
	|	DistributeByStagesWithBase AS ByBatches
	|		INNER JOIN ResultsOfBaseByStagesOfDivisions AS ResultsOfBaseByStagesOfDivisions
	|		ON ByBatches.Recorder = ResultsOfBaseByStagesOfDivisions.Recorder
	|			AND ByBatches.DebitBusinessUnit = ResultsOfBaseByStagesOfDivisions.Department
	|			AND (
	|				ByBatches.WithoutRegardToDirection AND ResultsOfBaseByStagesOfDivisions.LineOfBusiness = UNDEFINED 
					// the distributed expense has a non-empty LB, the total of the base is used taking into account the LB
	|				OR NOT ByBatches.WithoutRegardToDirection 
	|					AND ByBatches.LineOfBusiness = ResultsOfBaseByStagesOfDivisions.LineOfBusiness)
	|
	|GROUP BY
	|	ByBatches.Date,
	|	ByBatches.Recorder,
	|	ByBatches.Organization,
	|	ByBatches.Department,
	|	ByBatches.LineOfBusiness,
	|	ByBatches.ExpenseItem,
	|	ByBatches.DimensionOfExpenses,
	|	ByBatches.CostAllocationOptionManag,
	|	ByBatches.CostAllocationOptionLocal,
	|	ByBatches.CostAllocationOptionTax,
	|	ByBatches.AITCostAllocationOption,
	|	ByBatches.ManagementAccounting,
	|	ByBatches.LocalAccounting,
	|	ByBatches.TaxAccounting,
	|	ByBatches.AIT,
	|	ByBatches.LotsAreSpecifiedManually,
	|	ByBatches.ToAnyLinesOfBusiness,
	|
	|	ByBatches.ProductsGroup,
	|	ByBatches.RuleOfCostAllocatingToProductionLots,
	|	ByBatches.DebitBusinessUnit,
	|	ByBatches.CorLineOfBusiness,
	|	ByBatches.ProductionLot,
	|	ByBatches.ProductionOrder,
	|	ByBatches.RowCodeProducts,
	|	ByBatches.ProductCostElement,
	|
	|	ByBatches.Cost,
	|	ByBatches.CostExcludingVAT,
	|	ByBatches.LocalCost,
	|	ByBatches.CostMan
    |
	|INDEX BY
	|	Recorder,
	|	DebitBusinessUnit
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

// ... data samples

Function TextUnallocatedShares() // Uses to leave the WNZP, the totals of the basepoints of all the divisions
	Return "
	|SELECT
	|	""TextUnallocatedShares""                                           AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.UnfinishedProduction)                            AS EntryType,
	|	TRUE                                                                  AS CalculationIsCompleted,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)    AS AccountingSection,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	DD.Date                                                                 AS Period,
	|	DD.Recorder                                                          AS Recorder,
	|	DD.Organization                                                          AS Organization,
	|	DD.Department                                                        AS Department,
	|	DD.LineOfBusiness                                              AS LineOfBusiness,
	|	DD.ExpenseItem                                                       AS ExpenseItem,
	|	DD.DimensionOfExpenses                                                    AS DimensionOfExpenses,
	|	UNDEFINED                                                            AS BusinessOperation,
	|	UNDEFINED                                                            AS ProductsGroup,
	|	UNDEFINED                                                            AS RuleOfCostAllocatingToProductionLots,
	|	CASE 
	|		WHEN NOT DD.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT Recorders.ManagementAccounting
	|			THEN 0
	|		ELSE 
		// If there is no distribution base, then an integer is stored in the cost fraction,
		// which cannot be affected by the unit in any way.
	|			CAST(DD.CostShare 
	|				* ISNULL(BaseResultsByDivision.Cost, 
	|					ISNULL(ResultsOfDatabaseByStages.Cost, 1)) AS NUMBER(28, 10))
	|	END																	AS CostShare,
	|	CASE 
	|		WHEN NOT DD.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT Recorders.ManagementAccounting
	|			THEN 0
	|		ELSE 
	|			CAST(DD.CostShare 
	|				* ISNULL(BaseResultsByDivision.CostExcludingVAT, 
	|					ISNULL(ResultsOfDatabaseByStages.CostExcludingVAT, 1)) AS NUMBER(28, 10))
	|	END																	AS ShareOfValueWithoutVAT,
	|	CASE 
	|		WHEN NOT DD.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT Recorders.LocalAccounting
	|			THEN 0
	|		ELSE 
	|			CAST(DD.CostShare 
	|				* ISNULL(BaseResultsByDivision.LocalCost, 
	|					ISNULL(ResultsOfDatabaseByStages.LocalCost, 1)) AS NUMBER(28, 10))
	|	END																	AS ShareOfLocalValue,
	|	CASE 
	|		WHEN NOT DD.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT Recorders.TaxAccounting
	|			THEN 0
	|		ELSE 
	|			CAST(DD.CostShare 
	|				* ISNULL(BaseResultsByDivision.LocalCost, 
	|					ISNULL(ResultsOfDatabaseByStages.LocalCost, 1)) AS NUMBER(28, 10))
	|	END																	AS ShareValueTa,
	|	CASE 
	|		WHEN NOT DD.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT Recorders.ManagementAccounting
	|			THEN 0
	|		ELSE 
	|			CAST(DD.CostShare 
	|				* ISNULL(BaseResultsByDivision.CostMan, 
	|					ISNULL(ResultsOfDatabaseByStages.CostMan, 1)) AS NUMBER(28, 10))
	|	END																	AS ShareOfManSCost,
	// The share of the cost for AIT is calculated on the basis of the distribution of regulated accounting.
	|	CASE 
	|		WHEN NOT DD.AITCostAllocationOption = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT Recorders.AIT
	|			THEN 0
	// If AIT expenses are not included in the cost according to the recognition settings, then we reset the database.
	|		WHEN SettingsForRecognitionOfLBExpensesByBusinessUnits.ExpenseRecognitionOption IS NULL
	|				AND SettingsForRecognitionOfLBExpensesInAreasOfActivity.ExpenseRecognitionOption IS NULL
	|			THEN 0
	|		ELSE 
	|			CAST(DD.CostShare 
	|				* ISNULL(BaseResultsByDivision.LocalCost, 
	|					ISNULL(ResultsOfDatabaseByStages.LocalCost, 1)) AS NUMBER(28, 10))
	|	END																	AS ShareOfCostOfPersonalIncomeTax,
	|	UNDEFINED                                                            AS CorExpenseItem,
	|	UNDEFINED                                                            AS CorExpenditureDimension,
	|	UNDEFINED                                                            AS CorArticleOfAssetsLiabilities,
	|	UNDEFINED                                                            AS CorDimensionOfAssetsLiabilities,
	|	UNDEFINED                                                        	AS DebitBusinessUnit,
	|	UNDEFINED                                                            AS CorLineOfBusiness,
	|	VALUE(Catalog.ProductionLots.EmptyRef)                    AS ProductionLot,
	|	UNDEFINED                                                            AS ProductionOrder,
	|	0                                                                       AS RowCodeProducts,
	|	UNDEFINED                                                            AS ProductCostElement,
	|	UNDEFINED                                                            AS RowID
	|FROM
	|	LeaveAsWIP AS DD
	|		INNER JOIN Recorders AS Recorders
	|		ON Recorders.Recorder = DD.Recorder
	|			AND Recorders.ExpenseItem = DD.ExpenseItem
	|			AND Recorders.DimensionOfExpenses = DD.DimensionOfExpenses
	|		
	|		LEFT JOIN ResultsOfDatabaseByStagesOfAllDivisions AS ResultsOfDatabaseByStages
	|		ON ResultsOfDatabaseByStages.Recorder = DD.Recorder
	|		LEFT JOIN BaseResultsByDivision AS BaseResultsByDivision
	|		ON BaseResultsByDivision.Recorder = DD.Recorder
	|
	|		LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesByBusinessUnits
	|		ON DD.Department = SettingsForRecognitionOfLBExpensesByBusinessUnits.ObjectOfSeparateAccountingAIT
	|			AND DD.Organization = SettingsForRecognitionOfLBExpensesByBusinessUnits.Organization
	|			AND SettingsForRecognitionOfLBExpensesByBusinessUnits.ExpensesAreIncludedInCost
	|
	|		LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesInAreasOfActivity
	|		ON DD.LineOfBusiness = SettingsForRecognitionOfLBExpensesInAreasOfActivity.ObjectOfSeparateAccountingAIT
	|			AND DD.Organization = SettingsForRecognitionOfLBExpensesInAreasOfActivity.Organization
	|			AND SettingsForRecognitionOfLBExpensesInAreasOfActivity.ExpensesAreIncludedInCost
	|";
	
EndFunction

Function TextDistributionBetweenParties()
	
	Return "
	|SELECT
	|	""TextDistributionBetweenParties""                             		AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.EmptyRef)		            AS EntryType,
	|	TRUE                                                                  AS CalculationIsCompleted,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)    AS AccountingSection,
	|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
	|	ByBatches.Date                                                          AS Period,
	|	ByBatches.Recorder                                                   AS Recorder,
	|	ByBatches.Organization                                                   AS Organization,
	|	ByBatches.Department                                              	AS Department,
	|	ByBatches.LineOfBusiness                                    	AS LineOfBusiness,
	|	ByBatches.ExpenseItem                                                AS ExpenseItem,
	|	ByBatches.DimensionOfExpenses                                             AS DimensionOfExpenses,
	|	VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots) AS BusinessOperation,
	|	ByBatches.ProductsGroup                                            	AS ProductsGroup,
	|	ByBatches.RuleOfCostAllocatingToProductionLots                                   	AS RuleOfCostAllocatingToProductionLots,
	|	CAST(CASE 
	|		WHEN NOT ByBatches.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT ByBatches.ManagementAccounting
	|			THEN 0
	|		WHEN ByBatches.CostShare = 0
	|			OR BaseResultsByDivision.Cost = 0
	// The base by division will be equal to 0 only if there is really no distribution base.
	// If there is no division distribution, the total for the base by division will be NULL.
	|			THEN 0
	|		WHEN ByBusinessUnits.Recorder IS NULL
	// It is not distributed among divisions.
	|			THEN ByBatches.Cost
	|		ELSE
	|			CAST(ISNULL(DatabaseByDivision.Cost, 0) AS NUMBER(28, 10)) 
	|			* ByBatches.CostShare
	|	END AS NUMBER(28, 10)) AS CostShare,
	|	CAST(CASE 
	|		WHEN NOT ByBatches.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT ByBatches.ManagementAccounting
	|			THEN 0
	|		WHEN ByBatches.ShareOfValueWithoutVAT = 0
	|			OR BaseResultsByDivision.CostExcludingVAT = 0
	|			THEN 0
	|		WHEN ByBusinessUnits.Recorder IS NULL
	|			THEN ByBatches.CostExcludingVAT
	|		ELSE
	|			CAST(ISNULL(DatabaseByDivision.CostExcludingVAT, 0) AS NUMBER(28, 10)) 
	|			* ByBatches.ShareOfValueWithoutVAT
	|	END AS NUMBER(28, 10)) AS ShareOfValueWithoutVAT,
	|	CAST(CASE 
	|		WHEN NOT (ByBatches.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|				AND ByBatches.LocalAccounting)
	|			THEN 0
	|		WHEN ByBatches.ShareOfLocalValue = 0
	|			OR BaseResultsByDivision.LocalCost = 0
	|			THEN 0
	|		WHEN ByBusinessUnits.Recorder IS NULL
	|			THEN ByBatches.LocalCost
	|		ELSE
	|			CAST(ISNULL(DatabaseByDivision.LocalCost, 0) AS NUMBER(28, 10)) 
	|			* ByBatches.ShareOfLocalValue
	|	END AS NUMBER(28, 10)) AS ShareOfLocalValue,
	|	CAST(CASE 
	|		WHEN NOT (ByBatches.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|				AND ByBatches.TaxAccounting)
	|			THEN 0
	|		WHEN ByBatches.LocalCost = 0
	|			OR BaseResultsByDivision.LocalCost = 0
	|			THEN 0
	|		WHEN ByBusinessUnits.Recorder IS NULL
	|			THEN ByBatches.LocalCost
	|		ELSE
	|			CAST(ISNULL(DatabaseByDivision.LocalCost, 0) AS NUMBER(28, 10)) 
	|			* ByBatches.ShareOfLocalValue
	|	END AS NUMBER(28, 10)) AS ShareValueTa,
	|	CAST(CASE 
	|		WHEN NOT ByBatches.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT ByBatches.ManagementAccounting
	|			THEN 0
	|		WHEN ByBatches.ShareOfManSCost = 0
	|			OR BaseResultsByDivision.CostMan = 0
	|			THEN 0
	|		WHEN ByBusinessUnits.Recorder IS NULL
	|			THEN ByBatches.CostMan
	|		ELSE
	|			CAST(ISNULL(DatabaseByDivision.CostMan, 0) AS NUMBER(28, 10)) 
	|			* ByBatches.ShareOfManSCost
	|	END AS NUMBER(28, 10)) AS ShareOfManSCost,
	|	CAST(
	// The share of the cost for AIT is calculated on the basis of the distribution of regulated accounting.
	|	CASE 
	|		WHEN NOT (
	|			ByBatches.AITCostAllocationOption = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|				AND ByBatches.AIT
	|			)
	|			THEN 0
	// If AIT expenses are not included in the cost according to the recognition settings, then we reset the database.
	|		WHEN SettingsForRecognitionOfLBExpensesByBusinessUnits.ExpenseRecognitionOption IS NULL
	|				AND SettingsForRecognitionOfLBExpensesInAreasOfActivity.ExpenseRecognitionOption IS NULL
	|			THEN 0
	|		WHEN ByBatches.ShareOfLocalValue = 0
	|			OR BaseResultsByDivision.LocalCost = 0
	|			THEN 0
	|		WHEN ByBusinessUnits.Recorder IS NULL
	|			THEN ByBatches.LocalCost
	|		ELSE
	|			CAST(ISNULL(DatabaseByDivision.LocalCost, 0) AS NUMBER(28, 10)) 
	|			* ByBatches.ShareOfLocalValue
	|	END AS NUMBER(28, 10)) AS ShareOfCostOfPersonalIncomeTax,
	|
	|	UNDEFINED                                                            AS CorExpenseItem,
	|	UNDEFINED                                                            AS CorExpenditureDimension,
	|	UNDEFINED                                                            AS CorArticleOfAssetsLiabilities,
	|	UNDEFINED                                                            AS CorDimensionOfAssetsLiabilities,
	|	ByBatches.DebitBusinessUnit                                              AS DebitBusinessUnit,
	|	ByBatches.CorLineOfBusiness                                    AS CorLineOfBusiness,
	|	ByBatches.ProductionLot                                         	AS ProductionLot,
	|	ByBatches.ProductionOrder                                        	AS ProductionOrder,
	|	ByBatches.RowCodeProducts                                         	AS RowCodeProducts,
	|	CASE
	|		WHEN NOT ByBusinessUnits.Recorder IS NULL THEN
	|			DatabaseByDivision.ProductCostElement
	|		ELSE
	|			ByBatches.ProductCostElement
	|	END AS ProductCostElement,
	|	UNDEFINED                                                            AS RowID
	|FROM
	|	DistributeByStagesWithBaseOfDivisions AS ByBatches
	|	LEFT JOIN DistributeByDivisions AS ByBusinessUnits
	|		ON ByBatches.Recorder = ByBusinessUnits.Recorder
	|	LEFT JOIN DatabaseByDivision AS DatabaseByDivision
	|		ON ByBatches.Recorder = DatabaseByDivision.Recorder
	|			AND ByBatches.DebitBusinessUnit = DatabaseByDivision.DebitBusinessUnit
	|	LEFT JOIN BaseResultsByDivision AS BaseResultsByDivision
	|		ON BaseResultsByDivision.Recorder = ByBusinessUnits.Recorder
	|
	|		LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesByBusinessUnits
	|		ON ByBatches.DebitBusinessUnit = SettingsForRecognitionOfLBExpensesByBusinessUnits.ObjectOfSeparateAccountingAIT
	|			AND ByBatches.Organization = SettingsForRecognitionOfLBExpensesByBusinessUnits.Organization
	|			AND SettingsForRecognitionOfLBExpensesByBusinessUnits.ExpensesAreIncludedInCost
	|
	|		LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesInAreasOfActivity
	|		ON ByBatches.CorLineOfBusiness = SettingsForRecognitionOfLBExpensesInAreasOfActivity.ObjectOfSeparateAccountingAIT
	|			AND ByBatches.Organization = SettingsForRecognitionOfLBExpensesInAreasOfActivity.Organization
	|			AND SettingsForRecognitionOfLBExpensesInAreasOfActivity.ExpensesAreIncludedInCost
	|";
	
EndFunction

Function TextLinksToOtherArticles() // Uses the apportionment of other states, totals of the basepoints of all divisions
	Return "
	|SELECT
	|	""Textdolicrasdistributionnadrugesstatesreferences""                               AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.ExpenseAs)              AS EntryType,
	|	TRUE                                                                  AS CalculationIsCompleted,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)    AS AccountingSection,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	DD.Date                                                                 AS Period,
	|	DD.Recorder                                                          AS Recorder,
	|	DD.Organization                                                          AS Organization,
	|	DD.Department                                                        AS Department,
	|	DD.LineOfBusiness                                              AS LineOfBusiness,
	|	DD.ExpenseItem                                                       AS ExpenseItem,
	|	DD.DimensionOfExpenses                                                    AS DimensionOfExpenses,
	|	VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)     AS BusinessOperation,
	|	UNDEFINED                                                            AS ProductsGroup,
	|	UNDEFINED                                                            AS RuleOfCostAllocatingToProductionLots,
	|	CASE 
	|		WHEN NOT DD.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT Recorders.ManagementAccounting
	|			THEN 0
	|		ELSE 
		// If there is no distribution base, then an integer is stored in the cost fraction,
		// which cannot be affected by the unit in any way.
	|			CAST(DD.CostShare 
	|				* ISNULL(BaseResultsByDivision.Cost, 
	|					ISNULL(ResultsOfDatabaseByStages.Cost, 1)) AS NUMBER(28, 10))
	|	END																	AS CostShare,
	|	CASE 
	|		WHEN NOT DD.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT Recorders.ManagementAccounting
	|			THEN 0
	|		ELSE 
	|			CAST(DD.CostShare 
	|				* ISNULL(BaseResultsByDivision.CostExcludingVAT, 
	|					ISNULL(ResultsOfDatabaseByStages.CostExcludingVAT, 1)) AS NUMBER(28, 10))
	|	END																	AS ShareOfValueWithoutVAT,
	|	CASE 
	|		WHEN NOT DD.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT Recorders.LocalAccounting
	|			THEN 0
	|		ELSE 
	|			CAST(DD.CostShare 
	|				* ISNULL(BaseResultsByDivision.LocalCost, 
	|					ISNULL(ResultsOfDatabaseByStages.LocalCost, 1)) AS NUMBER(28, 10))
	|	END																	AS ShareOfLocalValue,
	|	CASE 
	|		WHEN NOT DD.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT Recorders.TaxAccounting
	|			THEN 0
	|		ELSE 
	|			CAST(DD.CostShare 
	|				* ISNULL(BaseResultsByDivision.LocalCost, 
	|					ISNULL(ResultsOfDatabaseByStages.LocalCost, 1)) AS NUMBER(28, 10))
	|	END																	AS ShareValueTa,
	|	CASE 
	|		WHEN NOT DD.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT Recorders.ManagementAccounting
	|			THEN 0
	|		ELSE 
	|			CAST(DD.CostShare 
	|				* ISNULL(BaseResultsByDivision.CostMan, 
	|					ISNULL(ResultsOfDatabaseByStages.CostMan, 1)) AS NUMBER(28, 10))
	|	END																	AS ShareOfManSCost,
	// The share of the cost for AIT is calculated on the basis of the distribution of regulated accounting.
	|	CASE 
	|		WHEN NOT DD.AITCostAllocationOption = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|			OR NOT Recorders.AIT
	|			THEN 0
	// If AIT expenses are not included in the cost according to the recognition settings, then we reset the database.
	|		WHEN SettingsForRecognitionOfLBExpensesByBusinessUnits.ExpenseRecognitionOption IS NULL
	|				AND SettingsForRecognitionOfLBExpensesInAreasOfActivity.ExpenseRecognitionOption IS NULL
	|			THEN 0
	|		ELSE 
	|			CAST(DD.CostShare 
	|				* ISNULL(BaseResultsByDivision.LocalCost, 
	|					ISNULL(ResultsOfDatabaseByStages.LocalCost, 1)) AS NUMBER(28, 10))
	|	END																	AS ShareOfCostOfPersonalIncomeTax,
	|	CASE
	|		WHEN DD.CorExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|			THEN DD.CorExpenseItem
	|		ELSE UNDEFINED
	|	END                                                                   AS CorExpenseItem,
	|	DD.CorExpenditureDimension                                             	AS CorExpenditureDimension,
	|	CASE
	|		WHEN DD.CorExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			THEN DD.CorExpenseItem
	|		ELSE UNDEFINED
	|	END                                                                   AS CorArticleOfAssetsLiabilities,
	|	DD.CorDimensionOfAssetsLiabilities                                          AS CorDimensionOfAssetsLiabilities,
	|	DD.DebitBusinessUnit                                                     AS DebitBusinessUnit,
	|	DD.CorLineOfBusiness                                          	AS CorLineOfBusiness,
	|	UNDEFINED                                                            AS ProductionLot,
	|	UNDEFINED                                                            AS ProductionOrder,
	|	0                                                                       AS RowCodeProducts,
	|	UNDEFINED                                                            AS ProductCostElement,
	|	DD.RowID                                              	AS RowID
	|FROM
	|	DistributeToOtherArticles AS DD
	|		INNER JOIN Recorders AS Recorders
	|		ON Recorders.Recorder = DD.Recorder
	|			AND Recorders.ExpenseItem = DD.ExpenseItem
	|			AND Recorders.LineOfBusiness = DD.LineOfBusiness
	|		
	|		LEFT JOIN ResultsOfDatabaseByStagesOfAllDivisions AS ResultsOfDatabaseByStages
	|		ON ResultsOfDatabaseByStages.Recorder = DD.Recorder
	|		LEFT JOIN BaseResultsByDivision AS BaseResultsByDivision
	|		ON BaseResultsByDivision.Recorder = DD.Recorder
	|
	|		LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesByBusinessUnits
	|		ON DD.Department = SettingsForRecognitionOfLBExpensesByBusinessUnits.ObjectOfSeparateAccountingAIT
	|			AND DD.Organization = SettingsForRecognitionOfLBExpensesByBusinessUnits.Organization
	|			AND SettingsForRecognitionOfLBExpensesByBusinessUnits.ExpensesAreIncludedInCost
	|
	|		LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesInAreasOfActivity
	|		ON DD.LineOfBusiness = SettingsForRecognitionOfLBExpensesInAreasOfActivity.ObjectOfSeparateAccountingAIT
	|			AND DD.Organization = SettingsForRecognitionOfLBExpensesInAreasOfActivity.Organization
	|			AND SettingsForRecognitionOfLBExpensesInAreasOfActivity.ExpensesAreIncludedInCost
	|";
	
EndFunction

#EndRegion

#Region ProceduresOfStep15_1_AllocationOfDirectProductionCosts

Function TableForDistributionOfDirectProductionCosts(CalculationParameters)
	
	Return CostCalculationAppliedAlgorithms.TableForDistributionOfLots(CalculationParameters,
		TextDescriptionOfDataForAllocationOfDirectProductionCosts());
	
EndFunction

// Sample data

Procedure ObtainDataForDistributionOfDirectProductionCosts(CalculationParameters)
	
	ToDecrypt = CostCalculationAppliedAlgorithms.CalculationCalledForDecryption(CalculationParameters);
	
	AddlParameters = CalculationParameters.AdditionalStageRequestParameters;
	AddlParameters.Insert("CostCalculationPerformed",  CalculationParameters.Property("CostCalculationPerformed"));
	AddlParameters.Insert("DecodingDistribution", 	  ToDecrypt);
	AddlParameters.Insert("IncludeProductionData21", True);
	AddlParameters.Insert("ConsiderFutureReleases", 	  True);
	
	PrepareDirectCostsForDistribution(CalculationParameters);
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForAllocationOfDirectProductionCosts(CalculationParameters),
		,
		Not ToDecrypt);
	
EndProcedure

// Request texts

// ... general

Function TextOfRequestForDistributionOfDirectProductionCosts() Export
	
	QueryText = "
	|SELECT
	|	DD.Organization AS Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount) AS BaseOfAllocationByLots,
	|	T.Department AS Department,
	|	DD.DistributionGroup AS DistributionGroup,
	|	DD.ProductionLot AS ProductionLot,
	|	T.ProductionOrder AS ProductionOrder,
	|	T.RowCodeProducts AS RowCodeProducts,
	|	T.ProductsGroup AS ProductsGroup,
	|	T.Material AS Factor,
	|	T.Cost AS Cost,
	|	T.CostExcludingVAT AS CostExcludingVAT,
	|	T.LocalCost AS LocalCost,
	|	T.CostMan AS CostMan,
	|	T.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax
	|INTO TTBasesOfDirectExpensesInDetail
	|FROM TTDistributionGroups AS DD
	|INNER JOIN DataOnMaterialCosts AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses),
	|	T.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	T.ProductionOrder,
	|	T.RowCodeProducts,
	|	T.ProductsGroup,
	|	T.WorkKind,
	|	T.Cost AS Cost,
	|	T.Cost AS CostExcludingVAT,
	|	T.LocalCost AS LocalCost,
	|	T.Cost AS CostMan,
	|	T.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax
	|FROM TTDistributionGroups AS DD
	|INNER JOIN DataOnLaborCosts AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel),
	|	T.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	T.ProductionOrder,
	|	T.RowCodeProducts,
	|	T.ProductsGroup,
	|	T.WorkKind,
	|	T.StandardCost AS Cost,
	|	T.StandardCost AS CostExcludingVAT,
	|	T.StandardCost AS LocalCost,
	|	T.StandardCost AS CostMan,
	|	T.StandardCost AS CostOfPersonalIncomeTax
	|FROM TTDistributionGroups AS DD
	|INNER JOIN DataOnLaborCosts AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts),
	|	T.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	T.ProductionOrder,
	|	T.RowCodeProducts,
	|	T.ProductsGroup,
	|	T.Material,
	|	T.Cost AS Cost,
	|	T.CostExcludingVAT AS CostExcludingVAT,
	|	T.LocalCost AS LocalCost,
	|	T.CostMan AS CostMan,
	|	T.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax
	|FROM TTDistributionGroups AS DD
	|INNER JOIN DataOnMaterialCosts AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts),
	|	T.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	T.ProductionOrder,
	|	T.RowCodeProducts,
	|	T.ProductsGroup,
	|	T.WorkKind,
	|	T.Cost AS Cost,
	|	T.Cost AS CostExcludingVAT,
	|	T.LocalCost	AS LocalCost,
	|	T.Cost AS CostMan,
	|	T.Cost AS CostOfPersonalIncomeTax
	|FROM TTDistributionGroups AS DD
	|INNER JOIN DataOnLaborCosts AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantity),
	|	T.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	T.ProductionOrder,
	|	T.RowCodeProducts,
	|	T.ProductsGroup,
	|	T.ManufacturedProduct,
	|	T.Count AS Cost,
	|	T.Count AS CostExcludingVAT,
	|	T.Count AS LocalCost,
	|	T.Count AS CostMan,
	|	T.Count AS CostOfPersonalIncomeTax
	|FROM TTDistributionGroups AS DD
	|INNER JOIN ProductData_6 AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases),
	|	T.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	T.ProductionOrder,
	|	T.RowCodeProducts,
	|	T.ProductsGroup,
	|	T.ManufacturedProduct,
	|	T.Count + T.CountPlan AS Cost,
	|	T.Count + T.CountPlan AS CostExcludingVAT,
	|	T.Count + T.CountPlan AS LocalCost,
	|	T.Count + T.CountPlan AS CostMan,
	|	T.Count + T.CountPlan AS CostOfPersonalIncomeTax
	|FROM TTDistributionGroups AS DD
	|INNER JOIN ProductData_6 AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeight),
	|	T.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	T.ProductionOrder,
	|	T.RowCodeProducts,
	|	T.ProductsGroup,
	|	T.ManufacturedProduct,
	|	T.Weight AS Cost,
	|	T.Weight AS CostExcludingVAT,
	|	T.Weight AS LocalCost,
	|	T.Weight AS CostMan,
	|	T.Weight AS CostOfPersonalIncomeTax
	|FROM TTDistributionGroups AS DD
	|INNER JOIN ProductData_6 AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases),
	|	T.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	T.ProductionOrder,
	|	T.RowCodeProducts,
	|	T.ProductsGroup,
	|	T.ManufacturedProduct,
	|	T.Weight + T.WeightPlan AS Cost,
	|	T.Weight + T.WeightPlan AS CostExcludingVAT,
	|	T.Weight + T.WeightPlan AS LocalCost,
	|	T.Weight + T.WeightPlan AS CostMan,
	|	T.Weight + T.WeightPlan AS CostOfPersonalIncomeTax
	|FROM TTDistributionGroups AS DD
	|INNER JOIN ProductData_6 AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolume),
	|	T.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	T.ProductionOrder,
	|	T.RowCodeProducts,
	|	T.ProductsGroup,
	|	T.ManufacturedProduct,
	|	T.VolumeM3 AS Cost,
	|	T.VolumeM3 AS CostExcludingVAT,
	|	T.VolumeM3 AS LocalCost,
	|	T.VolumeM3 AS CostMan,
	|	T.VolumeM3 AS CostOfPersonalIncomeTax
	|FROM TTDistributionGroups AS DD
	|INNER JOIN ProductData_6 AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases),
	|	T.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	T.ProductionOrder,
	|	T.RowCodeProducts,
	|	T.ProductsGroup,
	|	T.ManufacturedProduct,
	|	T.VolumeM3 + T.ScopePlan AS Cost,
	|	T.VolumeM3 + T.ScopePlan AS CostExcludingVAT,
	|	T.VolumeM3 + T.ScopePlan AS LocalCost,
	|	T.VolumeM3 + T.ScopePlan AS CostMan,
	|	T.VolumeM3 + T.ScopePlan AS CostOfPersonalIncomeTax
	|FROM TTDistributionGroups AS DD
	|INNER JOIN ProductData_6 AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|UNION ALL
	|
	|SELECT 
	|	DD.Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCost),
	|	T.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	T.ProductionOrder,
	|	T.RowCodeProducts,
	|	T.ProductsGroup,
	|	T.ManufacturedProduct,
	|	T.Cost AS Cost,
	|	T.Cost AS CostExcludingVAT,
	|	T.Cost AS LocalCost,
	|	T.Cost AS CostMan,
	|	T.Cost AS CostOfPersonalIncomeTax
	|FROM TTDistributionGroups AS DD
	|INNER JOIN ProductData_6 AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|UNION ALL
	|
	|SELECT 
	|	DD.Organization,
	|	VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases),
	|	T.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	T.ProductionOrder,
	|	T.RowCodeProducts,
	|	T.ProductsGroup,
	|	T.ManufacturedProduct,
	|	T.Cost + T.CostPlan AS Cost,
	|	T.Cost + T.CostPlan AS CostExcludingVAT,
	|	T.Cost + T.CostPlan AS LocalCost,
	|	T.Cost + T.CostPlan AS CostMan,
	|	T.Cost + T.CostPlan AS CostOfPersonalIncomeTax
	|FROM TTDistributionGroups AS DD
	|INNER JOIN ProductData_6 AS T
	|ON 
	|	DD.ProductionLot = T.ProductionLot
	|	AND DD.Department = T.Department
	|	AND DD.Organization = T.Organization
	|
	|INDEX BY
	|	Organization,
	|	ProductionLot,
	|	DistributionGroup,
	|	BaseOfAllocationByLots,
	|	Department;
	|
	|SELECT
	|	DD.Organization AS Organization,
	|	DD.BaseOfAllocationByLots,
	|	DD.Department,
	|	DD.DistributionGroup,
	// To correctly calculate the price, the total amount of the distribution base should not exceed 1,000
	// , the calculation is performed as follows: when distributing 100 rubles, the price must contain all decimal places.
	|	CASE
	|		WHEN SUM(DD.Cost) > 1000000000
	|	 		THEN 1000000
	|		WHEN SUM(DD.Cost) > 100000000
	|	 		THEN 100000
	|		WHEN SUM(DD.Cost) > 10000000
	|	 		THEN 10000
	|		WHEN SUM(DD.Cost) > 1000000
	|	 		THEN 1000
	|		WHEN SUM(DD.Cost) > 100000
	|	 		THEN 100
	|		WHEN SUM(DD.Cost) > 10000
	|	 		THEN 10
	|		ELSE 1
	|	END AS ZoomRatio,
	|	CASE
	|		WHEN SUM(DD.CostExcludingVAT) > 1000000000
	|	 		THEN 1000000
	|		WHEN SUM(DD.CostExcludingVAT) > 100000000
	|	 		THEN 100000
	|		WHEN SUM(DD.CostExcludingVAT) > 10000000
	|	 		THEN 10000
	|		WHEN SUM(DD.CostExcludingVAT) > 1000000
	|	 		THEN 1000
	|		WHEN SUM(DD.CostExcludingVAT) > 100000
	|	 		THEN 100
	|		WHEN SUM(DD.CostExcludingVAT) > 10000
	|	 		THEN 10
	|		ELSE 1
	|	END AS CoefficientWithoutVAT,
	|	CASE
	|		WHEN SUM(DD.LocalCost) > 1000000000
	|	 		THEN 1000000
	|		WHEN SUM(DD.LocalCost) > 100000000
	|	 		THEN 100000
	|		WHEN SUM(DD.LocalCost) > 10000000
	|	 		THEN 10000
	|		WHEN SUM(DD.LocalCost) > 1000000
	|	 		THEN 1000
	|		WHEN SUM(DD.LocalCost) > 100000
	|	 		THEN 100
	|		WHEN SUM(DD.LocalCost) > 10000
	|	 		THEN 10
	|		ELSE 1
	|	END AS LocalCoefficient,
	|	CASE
	|		WHEN SUM(DD.CostMan) > 1000000000
	|	 		THEN 1000000
	|		WHEN SUM(DD.CostMan) > 100000000
	|	 		THEN 100000
	|		WHEN SUM(DD.CostMan) > 10000000
	|	 		THEN 10000
	|		WHEN SUM(DD.CostMan) > 1000000
	|	 		THEN 1000
	|		WHEN SUM(DD.CostMan) > 100000
	|	 		THEN 100
	|		WHEN SUM(DD.CostMan) > 10000
	|	 		THEN 10
	|		ELSE 1
	|	END AS ManSCoefficient,
	|	CASE
	|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 1000000000
	|	 		THEN 1000000
	|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 100000000
	|	 		THEN 100000
	|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 10000000
	|	 		THEN 10000
	|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 1000000
	|	 		THEN 1000
	|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 100000
	|	 		THEN 100
	|		WHEN SUM(DD.CostOfPersonalIncomeTax) > 10000
	|	 		THEN 10
	|		ELSE 1
	|	END AS NDTCoefficient
	|INTO CoefficientsOfReductionOfDistributionBase
	|FROM
	|	TTBasesOfDirectExpensesInDetail AS DD
	|
	|GROUP BY
	|	DD.Organization,
	|	DD.BaseOfAllocationByLots,
	|	DD.Department,
	|	DD.DistributionGroup
	|INDEX BY
	|	Organization,
	|	DistributionGroup,
	|	BaseOfAllocationByLots,
	|	Department;
	|
	|SELECT
	|	DD.Organization AS Organization,
	|	DD.BaseOfAllocationByLots,
	|	DD.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot,
	|	CAST(SUM(DD.Cost) / MAX(ReductionCoefficients.ZoomRatio) AS NUMBER (23,10)) AS Base,
	|	CAST(SUM(DD.CostExcludingVAT) / MAX(ReductionCoefficients.CoefficientWithoutVAT) AS NUMBER (23,10)) AS DatabaseWithoutVAT,
	|	CAST(SUM(DD.LocalCost) / MAX(ReductionCoefficients.LocalCoefficient) AS NUMBER (23,10)) AS BaseLocal,
	|	CAST(SUM(DD.CostMan) / MAX(ReductionCoefficients.ManSCoefficient) AS NUMBER (23,10)) AS ManBase,
	|	CAST(SUM(DD.CostOfPersonalIncomeTax) / MAX(ReductionCoefficients.NDTCoefficient) AS NUMBER (23,10)) AS NDDDatabase
	|INTO TTDirectExpenseBase
	|FROM TTBasesOfDirectExpensesInDetail AS DD
	|	LEFT JOIN CoefficientsOfReductionOfDistributionBase AS ReductionCoefficients
	|		ON DD.Organization = ReductionCoefficients.Organization
	|		AND DD.BaseOfAllocationByLots = ReductionCoefficients.BaseOfAllocationByLots
	|		AND DD.Department = ReductionCoefficients.Department
	|		AND DD.DistributionGroup = ReductionCoefficients.DistributionGroup
	|GROUP BY
	|	DD.Organization,
	|	DD.BaseOfAllocationByLots,
	|	DD.Department,
	|	DD.DistributionGroup,
	|	DD.ProductionLot
	|INDEX BY
	|	DD.Organization,
	|	DD.BaseOfAllocationByLots,
	|	DD.DistributionGroup,
	|	DD.Department;
	|";
	
	Return QueryText;
	
EndFunction
	
Function RequestTextForAllocationOfDirectProductionCosts(CalculationParameters) Export
	
	QueryText = ""
		+ TextOfRequestForDistributionOfDirectProductionCosts()
		// Sample data
		+ TextDescriptionOfDataForAllocationOfDirectProductionCosts()
		+ "
		|UNION ALL
		|" + "
		|SELECT
		|	""RequestTextForAllocationOfDirectProductionCosts1""           AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.EmptyRef)                   AS EntryType,
		|	TRUE                                                                  AS CalculationIsCompleted,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)    AS AccountingSection,
		|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
		|	&EndOfPeriod                                                           AS Period,
		|	DD.Recorder                                                          AS Recorder,
		|	DD.Organization                                                          AS Organization,
		|	DD.Department                                                        AS Department,
		|	DD.LineOfBusiness                                              AS LineOfBusiness,
		|	DD.ExpenseItem                                                       AS ExpenseItem,
		|	DD.DimensionOfExpenses                                                    AS DimensionOfExpenses,
		|	VALUE(Enum.BusinessTransactions.ExpenseAllocationToProductionCost) AS BusinessOperation,
		|	Lots.ProductsGroup                                                  AS ProductsGroup,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases) AS RuleOfCostAllocatingToProductionLots,
		|	CASE 
		|		WHEN NOT DD.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
		|			THEN 0
		|		ELSE
		|			1
		|	END AS CostShare,
		|	CASE 
		|		WHEN NOT DD.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
		|			THEN 0
		|		ELSE
		|			1
		|	END AS ShareOfValueWithoutVAT,
		|	CASE 
		|		WHEN NOT DD.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
		|			THEN 0
		|		ELSE
		|			1
		|	END AS ShareOfLocalValue,
		|	CASE 
		|		WHEN NOT DD.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
		|			THEN 0
		|		ELSE
		|			1
		|	END AS ShareValueTa,
		|	CASE 
		|		WHEN NOT DD.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
		|			THEN 0
		|		ELSE
		|			1
		|	END AS ShareOfManSCost,
		|	CASE 
		|		WHEN NOT DD.AITCostAllocationOption = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
		|			THEN 0
		|		ELSE
		|			1
		|	END AS ShareOfCostOfPersonalIncomeTax,
		|	UNDEFINED                                                            AS CorExpenseItem,
		|	UNDEFINED                                                            AS CorExpenditureDimension,
		|	UNDEFINED                                                            AS CorArticleOfAssetsLiabilities,
		|	UNDEFINED                                                            AS CorDimensionOfAssetsLiabilities,
		|	DD.Department                                                        AS DebitBusinessUnit,
		|	Lots.LineOfBusiness                                          AS CorLineOfBusiness,
		|	Lots.Ref                                                           AS ProductionLot,
		|	UNDEFINED                                                            AS ProductionOrder,
		|	0                                                                       AS RowCodeProducts,
		|	DD.ProductCostElement                                                    AS ProductCostElement,
		|	UNDEFINED                                                            AS RowID
		|FROM
		|	DirectCostsToDistribution AS DD
		|		INNER JOIN Catalog.ProductionLots AS Lots
		|			ON	Lots.Ref = DD.DimensionOfExpenses
		|			AND	(DD.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|				OR Lots.LineOfBusiness = DD.LineOfBusiness)
		|			AND DD.DimensionOfExpenses REFS Catalog.ProductionLots
		|		INNER JOIN TTProductionBatchSelection AS Filter
		|			ON Lots.Ref = Filter.ProductionLot
		|		LEFT JOIN Catalog.ProductionLots.Companies AS ProductionLotsCompanies
		|		ON Lots.InternalSubcontracting
		|		AND Lots.Ref = ProductionLotsCompanies.Ref
		|WHERE
		|	CASE
		|		WHEN ProductionLotsCompanies.Organization IS NOT NULL
		|			THEN ProductionLotsCompanies.Organization
		|		WHEN TRUE
		|			THEN Lots.Organization
		|	END = DD.Organization
		|
		|UNION ALL
		|
		|SELECT
		|	""RequestTextForAllocationOfDirectProductionCosts2""           AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.EmptyRef)                   AS EntryType,
		|	TRUE                                                                  AS CalculationIsCompleted,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)    AS AccountingSection,
		|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
		|	&EndOfPeriod                                                           AS Period,
		|	DD.Recorder                                                          AS Recorder,
		|	DD.Organization                                                          AS Organization,
		|	DD.Department                                                        AS Department,
		|	DD.LineOfBusiness                                              AS LineOfBusiness,
		|	DD.ExpenseItem                                                       AS ExpenseItem,
		|	DD.DimensionOfExpenses                                                    AS DimensionOfExpenses,
		|	VALUE(Enum.BusinessTransactions.ExpenseAllocationToProductionCost) AS BusinessOperation,
		|	Lots.ProductsGroup                                                  AS ProductsGroup,
		|	DD.RuleOfCostAllocatingToProductionLots                                             AS RuleOfCostAllocatingToProductionLots,
		|	CASE 
		|		WHEN NOT DD.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
		|			THEN 0
		|		ELSE
		|			CAST(ISNULL(Bases.Base, 0) AS NUMBER(28, 10))
		|	END AS CostShare,
		|	CASE 
		|		WHEN NOT DD.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
		|			THEN 0
		|		ELSE
		|			CAST(ISNULL(Bases.DatabaseWithoutVAT, 0) AS NUMBER(28, 10))
		|	END AS ShareOfValueWithoutVAT,
		|	CASE 
		|		WHEN NOT DD.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
		|			THEN 0
		|		ELSE
		|			CAST(ISNULL(Bases.BaseLocal, 0) AS NUMBER(28, 10))
		|	END AS ShareOfLocalValue,
		|	CASE 
		|		WHEN NOT DD.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
		|			THEN 0
		|		ELSE
		|			CAST(ISNULL(Bases.BaseLocal, 0) AS NUMBER(28, 10))
		|	END AS ShareValueTa,
		|	CASE 
		|		WHEN NOT DD.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
		|			THEN 0
		|		ELSE
		|			CAST(ISNULL(Bases.ManBase, 0) AS NUMBER(28, 10))
		|	END AS ShareOfManSCost,
		|	CASE 
		|		WHEN NOT DD.AITCostAllocationOption = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
		|			THEN 0
		|		ELSE
		|			CAST(ISNULL(Bases.NDDDatabase, 0) AS NUMBER(28, 10))
		|	END AS ShareOfCostOfPersonalIncomeTax,
		|	UNDEFINED                                                            AS CorExpenseItem,
		|	UNDEFINED                                                            AS CorExpenditureDimension,
		|	UNDEFINED                                                            AS CorArticleOfAssetsLiabilities,
		|	UNDEFINED                                                            AS CorDimensionOfAssetsLiabilities,
		|	Bases.Department                                                      AS DebitBusinessUnit,
		|	Lots.LineOfBusiness                                          AS CorLineOfBusiness,
		|	Bases.ProductionLot                                                 AS ProductionLot,
		|	UNDEFINED                                                            AS ProductionOrder,
		|	0                                                                       AS RowCodeProducts,
		|	DD.ProductCostElement                                                    AS ProductCostElement,
		|	UNDEFINED                                                            AS RowID
		|FROM
		|	DirectCostsToDistribution AS DD 
		|		INNER JOIN TTDirectExpenseBase AS Bases
		|			ON	DD.Organization = Bases.Organization
		|				AND DD.BaseOfAllocationByLots = Bases.BaseOfAllocationByLots
		|				AND DD.DimensionOfExpenses = Bases.DistributionGroup
		|				AND DD.Department = Bases.Department
		|				AND NOT DD.DimensionOfExpenses REFS Catalog.ProductionLots
		|		INNER JOIN Catalog.ProductionLots AS Lots
		|			ON	Lots.Ref = Bases.ProductionLot
		|			AND	(DD.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|				OR Lots.LineOfBusiness = DD.LineOfBusiness)
		|		LEFT JOIN Catalog.ProductionLots.Companies AS ProductionLotsCompanies
		|		ON Lots.InternalSubcontracting
		|		AND Lots.Ref = ProductionLotsCompanies.Ref
		|WHERE
		|	CASE
		|		WHEN ProductionLotsCompanies.Organization IS NOT NULL
		|			THEN ProductionLotsCompanies.Organization
		|		WHEN TRUE
		|			THEN Lots.Organization
		|	END = DD.Organization
		|";
		
	Return CostCalculationAppliedAlgorithms.InsertWeightAndVolumeTemplatesIntoQueryText(QueryText, "SN");
	
EndFunction

// ... data descriptions

Function TextDescriptionOfDataForAllocationOfDirectProductionCosts() Export
	
	QueryText = "
	|SELECT TOP 0
	|	""TextDescriptionOfDataForAllocationOfDirectProductionCosts""     AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.EmptyRef)                   AS EntryType,
	|	FALSE                                                                    AS CalculationIsCompleted,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)    AS AccountingSection,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	DD.Period                                                               AS Period,
	|	DD.Recorder                                                          AS Recorder,
	|	DD.Organization                                                          AS Organization,
	|	DD.Department                                                        AS Department,
	|	DD.LineOfBusiness                                              AS LineOfBusiness,
	|	DD.ExpenseItem                                                       AS ExpenseItem,
	|	DD.DimensionOfExpenses                                                    AS DimensionOfExpenses,
	|	DD.BusinessOperation                                                AS BusinessOperation,
	|	DD.ProductsGroup                                                      AS ProductsGroup,
	|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef)            AS RuleOfCostAllocatingToProductionLots,
	|	0                                                                       AS CostShare,
	|	0                                                                       AS ShareOfValueWithoutVAT,
	|	0                                                                       AS ShareOfLocalValue,
	|	0                                                                       AS ShareValueTa,
	|	0                                                                       AS ShareOfManSCost,
	|	0                                                                       AS ShareOfCostOfPersonalIncomeTax,
	|	DD.CorExpenseItem                                                    AS CorExpenseItem,
	|	DD.CorExpenditureDimension                                                 AS CorExpenditureDimension,
	|	AP.AssetRef                                                               AS CorArticleOfAssetsLiabilities,
	|	AP.Dimension                                                            AS CorDimensionOfAssetsLiabilities,
	|	DD.DebitBusinessUnit                                                     AS DebitBusinessUnit,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)               AS CorLineOfBusiness,
	|	UnfinishedProduction.ProductionLot                                                  AS ProductionLot,
	|	UnfinishedProduction.ProductionOrder                                                 AS ProductionOrder,
	|	UnfinishedProduction.RowCodeProducts                                                  AS RowCodeProducts,
	|	DD.CorCostElement                                                 AS ProductCostElement,
	|	DD.RowID                                                  AS RowID
	|INTO Data
	|FROM
	|	AccumulationRegister.OtherExpenses AS DD
	|		LEFT JOIN AccumulationRegister.OtherWorkInProgressExpenses AS UnfinishedProduction
	|		ON TRUE
	|		LEFT JOIN AccumulationRegister.OtherAssetsLiabilities AS AP
	|		ON TRUE
	|";
	
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);
	
	Return QueryText;
	
EndFunction

// ... formation of temporary tables

Procedure PrepareDirectCostsForDistribution(CalculationParameters)
	
	// Let's remember the composition of temporary tables.
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	ToDecrypt = CostCalculationAppliedAlgorithms.CalculationCalledForDecryption(CalculationParameters);
	
	InitializeHIATable(CalculationParameters);
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);

	If ToDecrypt Then
		
		For Each KeyAndValue In CalculationParameters.AdditionalStageRequestParameters Do
			Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
		ParametersForReceivingBatches = CostsServer.DescriptionOfParametersForReceivingActiveBatchesWithoutSpecifications();
		ParametersForReceivingBatches.BeginOfPeriod = CalculationParameters.PayrollPeriod.BeginOfPeriod;
		ParametersForReceivingBatches.PeriodEnding = CalculationParameters.PayrollPeriod.EndOfPeriod;
		ParametersForReceivingBatches.Companies = CalculationParameters.CompanyArray;
		
		CostsServer.FormActiveBatchesWithoutSpecifications(ParametersForReceivingBatches, CalculationParameters.TempTablesManager);
		Query.Text = "SELECT TOP 0
		|	Attributes.Ref AS Recorder,
		|	Attributes.Date AS Date,
		|	Attributes.AssignAllocationSetting,
		|	Attributes.AllocationDirection,
		|	Attributes.BaseOfAllocationByLots,
		|	Attributes.ToAnyLinesOfBusiness,
		|	Attributes.BaseOfAllocationByBusinessUnits,
		|	Attributes.Factor,
		|	Attributes.ProductCostElement,
		|	Attributes.AllocateByLots,
		|	Attributes.AllocateToBusinessUnits,
		|	Attributes.AllocateToExpenseItems,
		|	Attributes.LeaveAsWIP,
		|	Attributes.ForReleaseOfCurrentMonth,
		|	Attributes.LotsAreSpecifiedManually,
		|	Attributes.BusinessUnitsAreSpecifiedManually,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef) AS RuleOfCostAllocatingToProductionLots,
		|	FALSE AS ThisIsOVZ,
		|	Attributes.Organization AS Organization,
		|	Attributes.Department AS Department,
		|	Attributes.ExpenseItem AS ExpenseItem,
		|	Attributes.DimensionOfExpenses AS DimensionOfExpenses,
		|	Attributes.LineOfBusiness AS LineOfBusiness,
		|	FALSE AS DistributionRequired,
		|	Attributes.ManagementAccounting AS ManagementAccounting,
		|	Attributes.LocalAccounting AS LocalAccounting,
		|	Attributes.TaxAccounting AS TaxAccounting
		|INTO Recorders
		|FROM
		|	Document.AllocationOfOtherCosts AS Attributes;
		|";
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
		QueryText = ""
			+ CostCalculationFillingInformationAboutLots.TextCorrectedDocuments() + Common.QueryBatchSeparator() // CorrectedDocuments_
			+ ?(ToDecrypt, CostCalculationProduction.ProductionBatchText(),"")
			+ ?(ToDecrypt, CostCalculationProduction.TextEmptyBatchTableOfGNZPMaterials(),"")
			+ ?(ToDecrypt, CostCalculationProduction.TextOfShareOfCostByProduct(),"")
			
			+ TextDataOnActualMaterialCosts(CalculationParameters)
			+ TextDataOnPreliminaryMaterialCosts(CalculationParameters)
			+ CostCalculationProduction.TextDataOnLaborCosts(CalculationParameters)
			+ TextDataOnLaborCostsCollapsed()
			
			+ CostCalculationProduction.TextOutputData()
			+ TextOutputDataCollapsed()
			+ "";
			
		Query.Text = CostCalculationAppliedAlgorithms.InsertWeightAndVolumeTemplatesIntoQueryText(QueryText, "SN");
		CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	EndIf;

	Query.SetParameter("CostAllocationOptions", 
		TMCommonUseClientServer.Array(Enums.CostAllocationOptions.ToProductionCostDirect));
	Query.SetParameter("Recorder",
		?(CalculationParameters.Property("Recorder"), CalculationParameters.Recorder, Undefined));
	
	Query.Text = Documents.AllocationOfOtherCosts.QueryTextReceivedOtherExpenses("ActualCalculation", False);
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, 
		,,,NStr("vi = 'Nhận chi phí theo từng giai đoạn của chi phí trực tiếp để phân bổ.';
				|ru = 'Получение постатейных затрат прямых расходов для распределения.';
				|en = 'Getting itemized direct expenses for allocation.'; fa = 'Getting itemized direct expenses for allocation.';
				|it = 'Acquisizione di spese dirette dettagliate da allocare.';
				|pl = 'Otrzymanie rozchodów wg pozycji bezpośrednich rozchodów do przydzielenia.';
				|tr = 'Dağıtım için direkt giderlerin kalemlere ayrılmış giderlerin elde edilmesi.'"));

	Query.Text = 
		"SELECT DISTINCT
		|	T.ProductionLot
		|INTO TTProductionBatchSelection
		|FROM
		|	ProductionBatchesAreSummarized AS T
		|
		|WHERE
		|	T.CostAllocationForIssue
		|
		|INDEX BY
		|	ProductionLot
		|;
		|
		|SELECT
		|	DD.Ref AS Recorder,
		|	DD.Date AS Date,
		|	DD.AssignAllocationSetting,
		|	DD.Organization,
		|	DD.AllocationDirection,
		|	DD.BaseOfAllocationByLots,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	CASE WHEN DD.ManagementAccounting THEN 
		|		DD.ExpenseItem.CostAllocationOptionManag 
		|	ELSE
		|		VALUE(Enum.CostAllocationOptions.EmptyRef)
		|	END AS CostAllocationOptionManag,
		|	CASE WHEN DD.LocalAccounting THEN 
		|		DD.ExpenseItem.CostAllocationOptionLocal 
		|	ELSE
		|		VALUE(Enum.CostAllocationOptions.EmptyRef)
		|	END AS CostAllocationOptionLocal,
		|	CASE WHEN DD.TaxAccounting THEN 
		|		DD.ExpenseItem.CostAllocationOptionTax 
		|	ELSE
		|		VALUE(Enum.CostAllocationOptions.EmptyRef)
		|	END AS CostAllocationOptionTax,
		|	CASE WHEN DD.AIT THEN 
		|		ISNULL(AITArticleDistributionSettings.AITCostAllocationOption, VALUE(Enum.CostAllocationOptions.EmptyRef))
		|	ELSE
		|		VALUE(Enum.CostAllocationOptions.EmptyRef)
		|	END AS AITCostAllocationOption,
		|	DD.ProductCostElement,
		|	CASE 
		|		WHEN DD.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
		|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts)
		|		WHEN DD.BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses),
		|												VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds),
		|												VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel))
		|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByLaborCosts)
		|		WHEN DD.BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount),
		|												VALUE(Enum.TypesOfCostAllocatingBase.StandardMaterialConsumption),
		|												VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials),
		|												VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials),
		|												VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials))
		|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts)
		|		WHEN DD.BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantity),
		|												VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeight),
		|												VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolume),
		|												VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCost))
		|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByProducts)
		|		WHEN DD.BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases),
		|												VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases),
		|												VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases),
		|												VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases))
		|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases)
		|	END AS RuleOfCostAllocatingToProductionLots
		|INTO DirectCostsToDistribution
		|FROM
		|	Document.AllocationOfOtherCosts AS DD
		|		INNER JOIN ExpenseForAllocation AS T
		|		ON (T.Organization = DD.Organization)
		|			AND (T.Department = DD.Department)
		|			AND (T.ExpenseItem = DD.ExpenseItem)
		|			AND (T.DimensionOfExpenses = DD.DimensionOfExpenses)
		|			AND (T.LineOfBusiness = DD.LineOfBusiness)
		|		LEFT JOIN AITArticleDistributionSettings AS AITArticleDistributionSettings
		|		ON DD.ExpenseItem = AITArticleDistributionSettings.ExpenseItem
		|			AND &DD_ObjectOfSeparateAccountingAIT = AITArticleDistributionSettings.ObjectOfSeparateAccountingAIT
		|			AND DD.Organization = AITArticleDistributionSettings.Organization
		|
		|WHERE
		|	DD.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost)
		|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DD.Organization IN(&CompanyArray)
		|	AND DD.Posted
		|	AND (DD.Ref = &Recorder
		|			OR &Recorder = UNDEFINED)
		|
		|INDEX BY
		|	DD.DimensionOfExpenses,
		|	DD.Organization,
		|	Recorder,
		|	DD.BaseOfAllocationByLots
		|;
		|
		|SELECT DISTINCT
		|	DD.BaseOfAllocationByLots AS BaseOfAllocationByLots,
		|	DD.DimensionOfExpenses AS DistributionGroup,
		|	DD.Department AS Department,
		|	CASE
		|		WHEN ProductionLotsCompanies.Organization IS NOT NULL
		|			THEN ProductionLotsCompanies.Organization
		|		WHEN TRUE
		|			THEN T.Organization
		|	END AS Organization,
		|	T.Ref AS ProductionLot
		|INTO TTDistributionGroupsPreliminary
		|FROM DirectCostsToDistribution AS DD
		|	INNER JOIN Catalog.ProductionLots AS T
		|		ON T.Ref = DD.DimensionOfExpenses
		|	LEFT JOIN Catalog.ProductionLots.Companies AS ProductionLotsCompanies
		|	ON T.InternalSubcontracting
		|	AND T.Ref = ProductionLotsCompanies.Ref
		|WHERE
		|	CASE
		|		WHEN ProductionLotsCompanies.Organization IS NOT NULL
		|			THEN ProductionLotsCompanies.Organization
		|		WHEN TRUE
		|			THEN T.Organization
		|	END = DD.Organization
		|
		|UNION
		|
		|SELECT DISTINCT
		|	DD.BaseOfAllocationByLots,
		|	DD.DimensionOfExpenses,
		|	DD.Department AS Department,
		|	CASE
		|		WHEN ProductionLotsCompanies.Organization IS NOT NULL
		|			THEN ProductionLotsCompanies.Organization
		|		WHEN TRUE
		|			THEN T.Organization
		|	END AS Organization,
		|	T.Ref
		|FROM DirectCostsToDistribution AS DD
		|	INNER JOIN Catalog.ProductionLots AS T
		|		ON T.MainProductProducts = DD.DimensionOfExpenses
		|			AND VALUETYPE(DD.DimensionOfExpenses) = TYPE(Catalog.Products)
		|	LEFT JOIN Catalog.ProductionLots.Companies AS ProductionLotsCompanies
		|	ON T.InternalSubcontracting
		|	AND T.Ref = ProductionLotsCompanies.Ref
		|WHERE
		|	CASE
		|		WHEN ProductionLotsCompanies.Organization IS NOT NULL
		|			THEN ProductionLotsCompanies.Organization
		|		WHEN TRUE
		|			THEN T.Organization
		|	END = DD.Organization
		|
		|UNION
		|
		|SELECT DISTINCT
		|	DD.BaseOfAllocationByLots,
		|	DD.DimensionOfExpenses,
		|	DD.Department AS Department,
		|	CASE
		|		WHEN ProductionLotsCompanies.Organization IS NOT NULL
		|			THEN ProductionLotsCompanies.Organization
		|		WHEN TRUE
		|			THEN T.Organization
		|	END AS Organization,
		|	T.Ref
		|FROM DirectCostsToDistribution AS DD
		|	INNER JOIN Catalog.ProductionLots AS T
		|		ON T.ProductsGroup = DD.DimensionOfExpenses
		|			AND VALUETYPE(DD.DimensionOfExpenses) = TYPE(Catalog.AnalyticalInventoryGroups)
		|	LEFT JOIN Catalog.ProductionLots.Companies AS ProductionLotsCompanies
		|		ON T.InternalSubcontracting
		|			AND T.Ref = ProductionLotsCompanies.Ref
		|WHERE
		|	CASE
		|		WHEN ProductionLotsCompanies.Organization IS NOT NULL
		|			THEN ProductionLotsCompanies.Organization
		|		WHEN TRUE
		|			THEN T.Organization
		|	END = DD.Organization
		|
		|UNION
		|
		|SELECT DISTINCT
		|	DD.BaseOfAllocationByLots,
		|	DD.DimensionOfExpenses,
		|	DD.Department AS Department,
		|	ISNULL(ProductionLotsCompanies.Organization, T.Organization) AS Organization,
		|	T.Ref
		|FROM DirectCostsToDistribution AS DD
		|	INNER JOIN Catalog.ProductionLots AS T
		|		ON T.Document = DD.DimensionOfExpenses
		|			AND VALUETYPE(DD.DimensionOfExpenses) = TYPE(Document.ProductionOrder2_2)
		|	LEFT JOIN Catalog.ProductionLots.Companies AS ProductionLotsCompanies
		|		ON T.InternalSubcontracting
		|			AND T.Ref = ProductionLotsCompanies.Ref
		|WHERE
		|	ISNULL(ProductionLotsCompanies.Organization, T.Organization) = DD.Organization
		|
		|INDEX BY
		|	ProductionLot
		|;
		|
		|SELECT
		|	T.BaseOfAllocationByLots,
		|	T.DistributionGroup,
		|	T.Department AS Department,
		|	T.Organization AS Organization,
		|	T.ProductionLot
		|INTO TTDistributionGroups
		|FROM
		|	TTDistributionGroupsPreliminary AS T
		|	INNER JOIN TTProductionBatchSelection AS Filter
		|		ON T.ProductionLot = Filter.ProductionLot
		|INDEX BY 
		|	T.ProductionLot,
		|	Department,
		|	Organization;";
	
	CalculationOfCostLocalization.SubstituteAITTypeOfSeparateAccountingObjectInRequest(Query.Text, "DD_ObjectOfSeparateAccountingAIT");
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query,
		,,,NStr("vi = 'Khởi tạo bảng để phân bổ chi phí.';
				|ru = 'Инициализация таблиц для распределения затрат.';
				|en = 'Initializing tables for cost allocation.'; fa = 'Initializing tables for cost allocation.';
				|it = 'Inizializzazione di tabelle per allocazione delle spese.';
				|pl = 'Inicjowane tabel do przydzielenia rozchodów.';
				|tr = 'Maliyet dağıtımı için tabloların başlatılması.'"));
	
	// We will destroy the auxiliary temporary tables.
	NewTT = "Recorders,
	|DirectCostsToDistribution,TTDistributionGroups,TTProductionBatchSelection,
	|AITArticleDistributionSettings,SettingsForDistributionOfAITArticlesByCostCenter
	|";
	AdditionalNewTT = "";
	If ToDecrypt Then
		AdditionalNewTT = "DataOnMaterialCosts,DataOnLaborCosts,ProductData_6";
	EndIf;
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, 
		CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters,
			CostCalculationUniversalAlgorithms.ConnectLines(ExistingTT, NewTT, AdditionalNewTT)));
	
EndProcedure

#EndRegion

#Region ProceduresOfStep16_AllocationOfCostsForOutputProducts

// Data Initialization

Function TableForDistributionOfOtherUnfinishedProductionCosts(CalculationParameters)
	
	Return CostCalculationAppliedAlgorithms.TableForDistributionOfLots(CalculationParameters,
		TextDescriptionOfDataForOtherUnfinishedProductionExpenses());
	
EndFunction

// Sample data

Procedure GetDataForOtherExpensesOfUnfinishedProduction(CalculationParameters)
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForOtherExpensesOfUnfinishedProduction(CalculationParameters));
	
EndProcedure

// Request texts

// ... general

Function RequestTextForOtherExpensesOfUnfinishedProduction(CalculationParameters = Undefined) Export

	TextForCreatingTemporaryTables = ""
		// preparation of temporary tables
		+ CostCalculationFillingInformationAboutLots.TextCorrectedDocuments() + Common.QueryBatchSeparator() // CorrectedDocuments_
		+ BatchTextForAttributingExpenses(CalculationParameters)
		+ TextMaterialCostsOfUnfinishedProduction()
		+ TextLaborCostsOfUnfinishedProduction()
		+ TextMaterialCostsAndLaborCostsUnfinishedProduction()
		+ TextReleasedProducts()
		+ TextOtherExpensesUnfinishedProductionInitialization()
		+ CalculationOfCostLocalization.AddServiceTablesToQuery()
		+ TextRemainsOfDistributionBases()
		+ TextConversionFactors();

	DataSampleTexts = New Array;
	DataSampleTexts.Add(TextDescriptionOfDataForOtherUnfinishedProductionExpenses());
	DataSampleTexts.Add(TextReceiptsOfOtherExpensesUnfinishedProduction());
	DataSampleTexts.Add(TextReceiptsOfOtherExpensesOfUnfinishedProductionOnCostOfProduction());
	DataSampleTexts.Add(TextExpensesOtherExpensesUnfinishedProductionOnMaterials());
	DataSampleTexts.Add(TextExpensesOtherExpensesUnfinishedProductionOnLaborCosts());
	DataSampleTexts.Add(TextExpensesOfOtherExpensesOfUnfinishedProductionOnMaterialAndLaborCosts());
	DataSampleTexts.Add(TextExpensesOtherExpensesUnfinishedProductionOnProducts());
	CalculationOfCostLocalization.AddLocalizedDataToRequestForUnfinishedProductionExpenses(DataSampleTexts);

	DataSampleTexts = MergeTexts(DataSampleTexts);

	Return TextForCreatingTemporaryTables
		+ DataSampleTexts;

EndFunction

// ... data descriptions

Function TextDescriptionOfDataForOtherUnfinishedProductionExpenses() Export
	QueryText = 
 	"SELECT TOP 0
	|	""TextDescriptionOfDataForOtherUnfinishedProductionExpenses""								AS RequestSource,
	|	0 																		AS Priority,
	|	VALUE(Enum.LotRecordTypes.EmptyRef)					AS EntryType,
	|	FALSE 																	AS CalculationIsCompleted,
	|	DD.RecordType 															AS RecordType,
	|	DD.Period 																AS Period,
	|	DD.Recorder 															AS Recorder,
	|	DD.Organization 															AS Organization,
	|	DD.Department 														AS Department,
	|	DD.ProductionLot													AS ProductionLot,
	|	DD.ReleaseLotDimension												AS ReleaseLotDimension,
	|	DD.ProductionOrder 													AS ProductionOrder,
	|	DD.RowCodeProducts 													AS RowCodeProducts,
	|	DD.LineOfBusiness												AS LineOfBusiness,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef) 				AS BillOfMaterials,
	|	DD.Stage 												 				AS Stage,
	|	DD.ProductCostElement 													AS ProductCostElement,
	|	DD.ExpenseItem 														AS ExpenseItem,
	|	DD.DimensionOfExpenses 													AS DimensionOfExpenses,
	|	DD.ProductsGroup 														AS ProductsGroup,
	|	DD.RuleOfCostAllocatingToProductionLots												AS RuleOfCostAllocatingToProductionLots,
	|	DD.ProductsAccountingDimension 												AS ProductsAccountingDimension,
	|	DD.LotVendorAttributesCorr												AS LotVendorAttributesCorr,
	|	DD.LineOfBusiness												AS CorLineOfBusiness,
	|	0 																		AS Denominator,
	|	DD.ProductsQuantity													AS ProductsQuantity,
	|	0																		AS CostShare,
	|	DD.Cost 															AS Cost,
	|	DD.CostExcludingVAT 														AS CostExcludingVAT,
	|	DD.LocalCost 														AS LocalCost,
	|	DD.PermanentDifference 													AS PermanentDifference,
	|	DD.CostTD 													AS CostTD,
	|	DD.CostOfPersonalIncomeTax 														AS CostOfPersonalIncomeTax,
	|	DD.IndicatorOfAllocationToLot											AS IndicatorOfAllocationToIssue,
	|	DD.IndicatorOfAllocationToLotExcludingVAT									AS IndicatorOfAttributionToOutputWithoutVAT,
	|	DD.IndicatorOfAllocationToLotCompl										AS LocalIssueAttributionRate,
	|	DD.IndicatorOfAllocationToLotCompl										AS IndicatorOfAttributionToIssueIsTA,
	|	DD.IndicatorOfAllocationToLotManag										AS IndicatorOfAssignmentToIssueOfMan,
	|	0																		AS IndicatorOfAttributionToIssueOfPersonalIncomeTax,
	|	DD.IndicatorOfAllocationToLot											AS IndicatorOfAllocationToLot,
	|	DD.IndicatorOfAllocationToLotExcludingVAT									AS IndicatorOfAllocationToLotExcludingVAT,
	|	DD.IndicatorOfAllocationToLotCompl										AS IndicatorOfAllocationToLotCompl,
	|	DD.IndicatorOfAllocationToLotCompl										AS RateOfAssignmentToBatchIsTA,
	|	DD.IndicatorOfAllocationToLotManag										AS IndicatorOfAllocationToLotManag,
	|	0																		AS IndicatorOfAttributionToPartyNDD,
	|	FALSE 																	AS Primary,
	|	VALUE(Enum.BusinessTransactions.EmptyRef) 				AS BusinessOperation,
	|	DD.AccountingSection 															AS AccountingSection,
	|	DD.InventoryOwnerAttribute 															AS InventoryOwnerAttribute,
	|	UNDEFINED 															AS VATActivityType,
	|	DD.DocumentRegisterRecords 													AS DocumentRegisterRecords,
	|	VALUE(Catalog.Assignments.EmptyRef) 							AS Purpose,
	|	DD.DocumentSource 													AS DocumentSource,
	|	DD.DocumentOfProductionIssue 														AS DocumentOfProductionIssue,
	|	DD.ManufacturedProduct 															AS ManufacturedProduct,
	|	DD.ItemVariant 												AS ItemVariant
	|INTO Data
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses AS DD
	|";
	
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
	
EndFunction

Function TextDescriptionOfDataForExpenseAllocationParties() Export
	QueryText = 
 	"SELECT TOP 0
	|	DD.Organization                                 AS Organization,
	|	DD.Department                               AS Department,
	|	DD.ProductionLot                          AS ProductionLot,
	|	DD.ReleaseLotDimension                      AS ReleaseLotDimension,
	|	DD.ProductionOrder                         AS ProductionOrder,
	|	DD.RowCodeProducts                          AS RowCodeProducts,
	|	DD.LineOfBusiness                     AS LineOfBusiness,
	|	DD.Stage                                        AS Stage,
	|	DD.ProductCostElement                           AS ProductCostElement,
	|	DD.ExpenseItem                              AS ExpenseItem,
	|	DD.DimensionOfExpenses                           AS DimensionOfExpenses,
	|	DD.ProductsGroup                             AS ProductsGroup,
	|	DD.RuleOfCostAllocatingToProductionLots                    AS RuleOfCostAllocatingToProductionLots,
	|	DD.IndicatorOfAllocationToLot                 AS FactorBalance,
	|	DD.DocumentSource                            AS DocumentSource,
	|	DD.DocumentOfProductionIssue                             AS DocumentOfProductionIssue
	|INTO Data
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses AS DD
	|";
	
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

// ... formation of temporary tables

Function BatchTextForAttributingExpenses(CalculationParameters = Undefined) Export
	
	QueryTextTTLotsForAttributingExpenses = "
		|SELECT
		|	DD.Organization                                 AS Organization,
		|	DD.Department                               AS Department,
		|	DD.ProductionLot                          AS ProductionLot,
		|	DD.ProductionOrder                         AS ProductionOrder,
		|	DD.RowCodeProducts                          AS RowCodeProducts,
		|	DD.LineOfBusiness                     AS LineOfBusiness,
		|	DD.Stage                                        AS Stage,
		|	DD.ProductCostElement                           AS ProductCostElement,
		|	DD.ExpenseItem                              AS ExpenseItem,
		|	DD.DimensionOfExpenses                           AS DimensionOfExpenses,
		|	DD.ProductsGroup                             AS ProductsGroup,
		|	DD.RuleOfCostAllocatingToProductionLots                    AS RuleOfCostAllocatingToProductionLots,
		|	SUM(DD.CostShareBalance)                 AS CostShareBalance
		|INTO TTLotsForAttributingExpenses
		|FROM
		|	(SELECT
		|		Shares.Organization                                 AS Organization,
		|		Shares.DebitBusinessUnit                            AS Department,
		|		Shares.ProductionLot                          AS ProductionLot,
		|		Shares.ProductionOrder                         AS ProductionOrder,
		|		Shares.RowCodeProducts                          AS RowCodeProducts,
		|		Shares.CorLineOfBusiness                  AS LineOfBusiness,
		|		VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
		|		Shares.ProductCostElement                           AS ProductCostElement,
		|		Shares.ExpenseItem                              AS ExpenseItem,
		|		Shares.DimensionOfExpenses                           AS DimensionOfExpenses,
		|		Shares.ProductsGroup                             AS ProductsGroup,
		|		Shares.RuleOfCostAllocatingToProductionLots                    AS RuleOfCostAllocatingToProductionLots,
		|		0                                                AS CostShareBalance
		|	FROM
		|		SharesOfProductionCosts AS Shares
		|	WHERE
		|		NOT (Shares.CostShare = 0
		|			AND Shares.ShareOfValueWithoutVAT = 0
		|			AND Shares.ShareOfLocalValue = 0
		|			AND Shares.ShareOfManSCost = 0
		|			AND Shares.ShareOfCostOfPersonalIncomeTax = 0
		|			)
		|
		|	UNION ALL
		|
		|	SELECT
		|		Shares.Organization                                 AS Organization,
		|		Shares.DebitBusinessUnit                            AS Department,
		|		Shares.ProductionLot                          AS ProductionLot,
		|		Shares.ProductionOrder                         AS ProductionOrder,
		|		Shares.RowCodeProducts                          AS RowCodeProducts,
		|		Shares.CorLineOfBusiness                  AS LineOfBusiness,
		|		VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
		|		Shares.ProductCostElement                           AS ProductCostElement,
		|		Shares.ExpenseItem                              AS ExpenseItem,
		|		Shares.DimensionOfExpenses                           AS DimensionOfExpenses,
		|		Shares.ProductsGroup                             AS ProductsGroup,
		|		Shares.RuleOfCostAllocatingToProductionLots                    AS RuleOfCostAllocatingToProductionLots,
		|		0                                                AS CostShareBalance
		|	FROM
		|		DirectProductionCosts AS Shares
		|	WHERE
		|		NOT (Shares.CostShare = 0
		|			AND Shares.ShareOfValueWithoutVAT = 0
		|			AND Shares.ShareOfLocalValue = 0
		|			AND Shares.ShareOfManSCost = 0
		|			AND Shares.ShareOfCostOfPersonalIncomeTax = 0
		|			)
		|
		|	UNION ALL
		|
		// To type fields in a temporary table.
		|	SELECT TOP 0
		|		DD.Organization                                 AS Organization,
		|		DD.Department                               AS Department,
		|		DD.ProductionLot                          AS ProductionLot,
		|		DD.ProductionOrder                         AS ProductionOrder,
		|		DD.RowCodeProducts                          AS RowCodeProducts,
		|		DD.LineOfBusiness                     AS LineOfBusiness,
		|		DD.Stage                                        AS Stage,
		|		DD.ProductCostElement                           AS ProductCostElement,
		|		DD.ExpenseItem                              AS ExpenseItem,
		|		DD.DimensionOfExpenses                           AS DimensionOfExpenses,
		|		DD.ProductsGroup                             AS ProductsGroup,
		|		DD.RuleOfCostAllocatingToProductionLots                    AS RuleOfCostAllocatingToProductionLots,
		|		DD.CostShare                               AS CostShareBalance
		|	FROM
		|		AccumulationRegister.OtherWorkInProgressExpenses AS DD
		|
		|	UNION ALL
		|
		|	SELECT
		|		DD.Organization                                 AS Organization,
		|		DD.Department                               AS Department,
		|		DD.ProductionLot                          AS ProductionLot,
		|		DD.ProductionOrder                         AS ProductionOrder,
		|		DD.RowCodeProducts                          AS RowCodeProducts,
		|		DD.LineOfBusiness                     AS LineOfBusiness,
		|		DD.Stage                                        AS Stage,
		|		DD.ProductCostElement                           AS ProductCostElement,
		|		DD.ExpenseItem                              AS ExpenseItem,
		|		DD.DimensionOfExpenses                           AS DimensionOfExpenses,
		|		DD.ProductsGroup                             AS ProductsGroup,
		|		DD.RuleOfCostAllocatingToProductionLots                    AS RuleOfCostAllocatingToProductionLots,
		|		DD.CostShareBalance                        AS CostShareBalance
		|	FROM
		|		AccumulationRegister.OtherWorkInProgressExpenses.Balance(
		|			&BorderEndOfPreviousPeriod,
		|			(Organization, ProductionLot) IN(
		|				SELECT
		|					T.Organization,
		|					T.ProductionLot
		|				FROM
		|					ProductionBatchesAreSummarized AS T)) AS DD
		|	WHERE
		|		ISNULL(DD.CostBalance,0) <> 0
		|		OR ISNULL(DD.CostExcludingVATBalance,0) <> 0
		|		OR ISNULL(DD.CostManBalance,0) <> 0
		|		OR ISNULL(DD.LocalCostBalance,0) <> 0
		|		OR ISNULL(DD.PermanentDifferenceBalance,0) <> 0
		|		OR ISNULL(DD.CostTDBalance,0) <> 0
		|		OR ISNULL(DD.CostOfPersonalIncomeTaxBalance,0) <> 0
		|
		|	UNION ALL
		|
		|	SELECT
		|		DD.Organization                                 AS Organization,
		|		DD.Department                               AS Department,
		|		DD.ProductionLot                          AS ProductionLot,
		|		DD.ProductionOrder                         AS ProductionOrder,
		|		DD.RowCodeProducts                          AS RowCodeProducts,
		|		DD.LineOfBusiness                     AS LineOfBusiness,
		|		DD.Stage                                        AS Stage,
		|		DD.ProductCostElement                           AS ProductCostElement,
		|		DD.ExpenseItem                              AS ExpenseItem,
		|		DD.DimensionOfExpenses                           AS DimensionOfExpenses,
		|		DD.ProductsGroup                             AS ProductsGroup,
		|		DD.RuleOfCostAllocatingToProductionLots                    AS RuleOfCostAllocatingToProductionLots,
		|		DD.CostShare                               AS CostShareBalance
		|	FROM
		|		TTCashEstimatedTurnoverOtherWorkInProgressExpenses AS DD
		|		INNER JOIN Document.WIPOpeningBalancesByProductionLots AS InitialResiduals
		|			ON InitialResiduals.Ref = DD.Recorder
		|	WHERE
		|		DD.Cost <> 0
		|		OR DD.CostExcludingVAT <> 0
		|		OR DD.CostMan <> 0
		|		OR DD.LocalCost <> 0
		|		OR DD.PermanentDifference <> 0
		|		OR DD.CostTD <> 0
		|		OR DD.CostOfPersonalIncomeTax <> 0
		|
		|	UNION ALL
		|
		// We also take storno corrections in the current period into account.
		|	SELECT
		|		DD.Organization                                 AS Organization,
		|		DD.Department                               AS Department,
		|		DD.ProductionLot                          AS ProductionLot,
		|		DD.ProductionOrder                         AS ProductionOrder,
		|		DD.RowCodeProducts                          AS RowCodeProducts,
		|		DD.LineOfBusiness                     AS LineOfBusiness,
		|		DD.Stage                                        AS Stage,
		|		DD.ProductCostElement                           AS ProductCostElement,
		|		DD.ExpenseItem                              AS ExpenseItem,
		|		DD.DimensionOfExpenses                           AS DimensionOfExpenses,
		|		DD.ProductsGroup                             AS ProductsGroup,
		|		DD.RuleOfCostAllocatingToProductionLots                    AS RuleOfCostAllocatingToProductionLots,
		|		DD.CostShare                               AS CostShareBalance
		|	FROM
		|		AccumulationRegister.OtherWorkInProgressExpenses AS DD
		|	
		|		INNER JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.ReversedDocument = DD.Recorder
		|		
		|		INNER JOIN ProductionBatchesAreSummarized AS Lots
		|		ON DD.ProductionLot = Lots.ProductionLot
		|		AND DD.Organization = Lots.Organization
		|	WHERE
		|		DD.Period < &BeginOfPeriod
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND DD.Active
		|		AND NOT DD.ReversingEntry
		|		AND &MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|		AND (DD.Cost <> 0
		|			OR DD.CostExcludingVAT <> 0
		|			OR DD.CostMan <> 0
		|			OR DD.LocalCost <> 0
		|			OR DD.PermanentDifference <> 0
		|			OR DD.CostTD <> 0
		|			OR DD.CostOfPersonalIncomeTax <> 0)
		|	) AS DD
		|
		|GROUP BY
		|	DD.Organization,
		|	DD.Department,
		|	DD.ProductionLot,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts,
		|	DD.LineOfBusiness,
		|	DD.Stage,
		|	DD.ProductCostElement,
		|	DD.ExpenseItem,
		|	DD.DimensionOfExpenses,
		|	DD.ProductsGroup,
		|	DD.RuleOfCostAllocatingToProductionLots
		|";
		
		QueryTextBatchIDs = "
		|SELECT DISTINCT
		|	DD.ProductionLot                          AS ProductionLot,
		|	DD.ProductionOrder                         AS ProductionOrder,
		|	DD.RowCodeProducts                          AS RowCodeProducts,
		|	DD.ProductionLot                          AS DocumentOfProductionIssue,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ReleaseLotDimension
		|INTO BatchIDs
		|FROM
		|	TTLotsForAttributingExpenses AS DD
		|
		|WHERE
		|	DD.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
		|";
		
		QueryTextForSettingUpAITExpenseRecognitionByItem = CalculationOfCostLocalization.AITSettingsQueryText("TTLotsForAttributingExpenses", 
			"CostCalculationItemByItemExpenses_BatchTextForAttributionOfExpenses",
			CalculationParameters);
		
		QueryTextLotsForAttributingExpenses = "
		|SELECT DISTINCT
		|	DD.Organization                                 AS Organization,
		|	DD.Department                               AS Department,
		|	DD.ProductionLot                          AS ProductionLot,
		|	DD.ProductionOrder                         AS ProductionOrder,
		|	DD.RowCodeProducts                          AS RowCodeProducts,
		|	DD.LineOfBusiness                     AS LineOfBusiness,
		|	DD.Stage                                        AS Stage,
		|	DD.ProductCostElement                           AS ProductCostElement,
		|	DD.ExpenseItem 							   AS ExpenseItem,
		|	CASE 
		|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|		THEN TTOvz.CostAllocationOptionManag
		|		ELSE AssetRef.CostAllocationOptionManag
		|	END AS CostAllocationOptionManag,
		|	CASE 
		|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|		THEN TTOvz.CostAllocationOptionLocal
		|		ELSE AssetRef.CostAllocationOptionLocal
		|	END AS CostAllocationOptionLocal,
		|	CASE 
		|		WHEN AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|		THEN TTOvz.CostAllocationOptionTax
		|		ELSE AssetRef.CostAllocationOptionTax
		|	END AS CostAllocationOptionTax,
		|	ISNULL(SettingsForDistributionOfAITArticlesByCostCenter.AITCostAllocationOption, 
		|		ISNULL(AITArticleDistributionSettings.AITCostAllocationOption, VALUE(Enum.CostAllocationOptions.EmptyRef))) AS AITCostAllocationOption,
		|	ISNULL(AITExpenseRecognitionSettings.ExpensesAreIncludedInCost, FALSE) AS AITExpensesAreIncludedInCost,
		|	DD.DimensionOfExpenses                           AS DimensionOfExpenses,
		|	DD.ProductsGroup                             AS ProductsGroup,
		|	DD.RuleOfCostAllocatingToProductionLots                    AS RuleOfCostAllocatingToProductionLots,
		|	DD.CostShareBalance                        AS CostShareBalance,
		|	IDs.DocumentOfProductionIssue                 AS DocumentOfProductionIssue,
		|	IDs.ReleaseLotDimension          AS ReleaseLotDimension
		|INTO LotsForAttributingExpenses
		|FROM
		|	TTLotsForAttributingExpenses AS DD
		|	LEFT JOIN BatchIDs AS IDs
		|		ON DD.ProductionLot = IDs.ProductionLot
		|		AND DD.ProductionOrder = IDs.ProductionOrder
		|		AND DD.RowCodeProducts = IDs.RowCodeProducts
		|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
		|		ON DD.ExpenseItem = AssetRef.Ref
		|	LEFT JOIN TTOvz AS TTOvz
		|		ON DD.DimensionOfExpenses = TTOvz.ConstCenter
		|	LEFT JOIN AITArticleDistributionSettings AS AITArticleDistributionSettings
		|		ON DD.ExpenseItem = AITArticleDistributionSettings.ExpenseItem
		|		AND &DD_ObjectOfSeparateAccountingAIT = AITArticleDistributionSettings.ObjectOfSeparateAccountingAIT
		|		AND DD.Organization = AITArticleDistributionSettings.Organization
		|		AND AITArticleDistributionSettings.ExpensesAreIncludedInCost
		|	LEFT JOIN SettingsForDistributionOfAITArticlesByCostCenter AS SettingsForDistributionOfAITArticlesByCostCenter
		|		ON DD.DimensionOfExpenses = SettingsForDistributionOfAITArticlesByCostCenter.ConstCenter
		|		AND SettingsForDistributionOfAITArticlesByCostCenter.ExpensesAreIncludedInCost
		|	LEFT JOIN AITExpenseRecognitionSettings AS AITExpenseRecognitionSettings
		|		ON &DD_ObjectOfSeparateAccountingAIT = AITExpenseRecognitionSettings.ObjectOfSeparateAccountingAIT
		|		AND DD.Organization = AITExpenseRecognitionSettings.Organization
		|		AND AITExpenseRecognitionSettings.ExpensesAreIncludedInCost
		|;
		|DROP AITExpenseRecognitionSettings
		|;
		|DROP AITArticleDistributionSettings
		|;
		|DROP SettingsForDistributionOfAITArticlesByCostCenter
		|
		|";
		
		QueryTextPartiesForAttributingExpensesInSummary = "
		|SELECT DISTINCT
		|	DD.Organization                                 AS Organization,
		|	DD.Department                               AS Department,
		|	DD.ProductionLot                          AS ProductionLot,
		|	DD.ProductionOrder                         AS ProductionOrder,
		|	DD.RowCodeProducts                          AS RowCodeProducts,
		|	DD.RuleOfCostAllocatingToProductionLots 				   AS RuleOfCostAllocatingToProductionLots
		|INTO PartiesForAttributingExpensesInSummary
		|FROM
		|	TTLotsForAttributingExpenses AS DD
		|
		|INDEX BY
		|	Organization,
		|	Department,
		|	ProductionLot,
		|	ProductionOrder,
		|	RowCodeProducts,
		|	RuleOfCostAllocatingToProductionLots
		|;
		|
		|////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DD.ProductionLot AS ProductionLot
		|INTO BatchesOfManufacturedProducts
		|FROM
		|	PartiesForAttributingExpensesInSummary AS DD
		|WHERE
		|	DD.RuleOfCostAllocatingToProductionLots IN (
		|		VALUE(Enum.RulesOfCostAllocationToProductCost.ByProducts),
		|		VALUE(Enum.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases))
		|INDEX BY
		|	ProductionLot";
	
	QueryTexts = New Array; // Array of String
	QueryTexts.Add(QueryTextTTLotsForAttributingExpenses);
	QueryTexts.Add(QueryTextBatchIDs);
	QueryTexts.Add(QueryTextForSettingUpAITExpenseRecognitionByItem);
	QueryTexts.Add(QueryTextLotsForAttributingExpenses);
	QueryTexts.Add(QueryTextPartiesForAttributingExpensesInSummary);
	
	QueryText = StrConcat(QueryTexts, TMCommonUse.RequestSeparatorInPacket_());
	
	CalculationOfCostLocalization.SubstituteAITTypeOfSeparateAccountingObjectInRequest(QueryText, "DD_ObjectOfSeparateAccountingAIT");
	
	Return QueryText
		+ Common.QueryBatchSeparator();
		
EndFunction

Function TextMaterialCostsOfUnfinishedProduction()
	
	QueriesTexts = New Array;
	
	QueryText =
		"SELECT
		|	DD.Organization                   AS Organization,
		|	ISNULL(DimensionContract.Department, DD.ItemsLocationAttributes.StorageLocation) AS Department,
		|	DD.Recorder                   AS ExpenseLogger,
		|	DD.Period                        AS ProductionDate,
		|	DD.Lot                        AS ProductionLot,
		|	UNDEFINED                     AS ProductionOrder,
		|	0                                AS RowCodeProducts,
		|	DD.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute                 AS CorInventoryOwnerAttribute,
		|	DD.LotVendorAttributesCorr       AS LotVendorAttributesCorr,
		|	DD.CorAccountingSection                AS CorAccountingSection,
		|	SUM(CAST(DD.Count *
		|		(ISNULL(Prices.Cost, 0)
		|		+ ISNULL(Prices.AdditionalExpenseCost, 0)
		|		+ ISNULL(Prices.OffBalanceCost, 0)) AS NUMBER(31, 10)))     AS Cost,
		|	SUM(CAST(DD.Count *
		|		(ISNULL(Prices.CostExcludingVAT, 0)
		|		+ ISNULL(Prices.AdditionalExpensesCostExcludingVAT, 0)
		|		+ ISNULL(Prices.OffBalanceCost, 0)) AS NUMBER(31, 10)))     AS CostExcludingVAT,
		|	SUM(CAST(DD.Count *
		|		(ISNULL(Prices.LocalCost, 0)
		|		+ ISNULL(Prices.AddExpensesLocal, 0)
		|		+ ISNULL(Prices.OffBalanceCostLocal, 0)) AS NUMBER(31, 10))) AS LocalCost,
		|	SUM(CAST(DD.Count *
		|		(ISNULL(Prices.CostMan, 0)
		|		+ ISNULL(Prices.AddExpensesMan, 0)
		|		+ ISNULL(Prices.OffBalanceCost, 0)) AS NUMBER(31, 10)))     AS CostMan,
		|	SUM(DD.Count *
		|		(ISNULL(Prices.CostOfPersonalIncomeTax, 0)))                                  AS CostOfPersonalIncomeTax
		|INTO MaterialCostsOfProduction
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	
		|	INNER JOIN ProductionBatchesAreSummarized AS ProductionBatchesAreSummarized
		|	ON ProductionBatchesAreSummarized.ProductionLot = DD.Lot
		|	AND ProductionBatchesAreSummarized.Organization = DD.Organization
		|	
		|	LEFT JOIN Catalog.CounterpartyContracts AS DimensionContract
		|	ON DimensionContract.Ref = DD.ItemsLocationAttributes.StorageLocation
		|	
		|	LEFT JOIN TTValueOfBatchesOfGoods AS Prices
		|	ON Prices.Organization = DD.Organization
		|	AND Prices.Lot = DD.Lot
		|	AND Prices.LotVendorAttributes = DD.LotVendorAttributes
		|	AND Prices.FinancialAccountingDimension = DD.FinancialAccountingDimension
		|	AND Prices.VATActivityType = DD.VATActivityType
		|	AND Prices.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|	AND Prices.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|	AND Prices.AccountingSection = DD.AccountingSection
		|	
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|	ON CorrectedDocuments_.ReversedDocument = DD.Recorder
		|	
		|WHERE
		|	DD.ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
		|	AND NOT DD.OfficialTypeOfMovementParish
		|	AND DD.Count > 0
		|	AND ProductionBatchesAreSummarized.CostAllocationForIssue
		// We exclude the Receipt of the services of an external processor
		|	AND NOT TRUE IN(
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTCashEstimatedTurnoverCostOfGoods AS SubcontractorServices
		|		WHERE
		|			SubcontractorServices.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|			AND SubcontractorServices.AccountingSection = DD.AccountingSection
		|			AND SubcontractorServices.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|			AND SubcontractorServices.Organization = DD.Organization
		|			AND SubcontractorServices.Lot = DD.Lot
		|			AND SubcontractorServices.LotVendorAttributes = DD.LotVendorAttributes
		|			AND SubcontractorServices.FinancialAccountingDimension = DD.FinancialAccountingDimension
		|			AND SubcontractorServices.VATActivityType = DD.VATActivityType
		|			AND SubcontractorServices.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier))
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	AND CorrectedDocuments_.ReversedDocument IS NULL
		|
		|GROUP BY
		|	DD.Organization,
		|	ISNULL(DimensionContract.Department, DD.ItemsLocationAttributes.StorageLocation), // Department
		|	DD.Recorder,
		|	DD.Period,
		|	DD.Lot,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorAccountingSection
		|";
	
	QueriesTexts.Add(QueryText);
	CalculationOfCostLocalization.SupplementRequestWithMaterialCostsOfUnfinishedProduction(QueriesTexts);
	
	QueryText = MergeTexts(QueriesTexts);
	QueryText = QueryText + "
		|
		|INDEX BY
		|	Organization,
		|	Department,
		|	ProductionLot,
		|	ProductionOrder,
		|	RowCodeProducts";
	
	Return QueryText
		+ Common.QueryBatchSeparator();
		
EndFunction

Function TextLaborCostsOfUnfinishedProduction()
		
	QueriesTexts = New Array;
	
	QueryText =
		"SELECT
		|	DD.Organization                                          AS Organization,
		|	DD.Department                                        AS Department,
		|	DD.Recorder                                          AS ExpenseLogger,
		|	DD.Period                                               AS ProductionDate,
		|	DD.ProductionLot                                   AS ProductionLot,
		|	UNDEFINED                                            AS ProductionOrder,
		|	0                                                       AS RowCodeProducts,
		|	DD.CorDimensionOfProductsAccounting                           AS CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttributesOfProducts                               AS CorInventoryOwnerAttribute,
		|	DD.LotVendorAttributesCorr                              AS LotVendorAttributesCorr,
		|	DD.CorAccountingSection                                       AS CorAccountingSection,
		|	CAST(CASE
		|		WHEN SUM(DD.Cost) = 0
		|			THEN SUM(DD.StandardCost)
		|		ELSE SUM(DD.Cost)
		|	END AS NUMBER(23,10))                                 AS Cost,
		|	CAST(CASE
		|		WHEN SUM(DD.Cost) = 0
		|			THEN SUM(DD.StandardCost)
		|		ELSE SUM(DD.Cost)
		|	END AS NUMBER(23,10))                                 AS CostExcludingVAT,
		|	CAST(CASE
		|		WHEN SUM(DD.LocalCost) = 0
		|			THEN SUM(DD.StandardCost)
		|		ELSE SUM(DD.LocalCost)
		|	END AS NUMBER(23,10))                                 AS LocalCost,
		|	CAST(CASE
		|		WHEN NOT &CompanyManagementAccounting
		|			THEN 0
		|		WHEN SUM(DD.Cost) = 0
		|			THEN SUM(DD.StandardCost)
		|		ELSE SUM(DD.Cost)
		|	END AS NUMBER(23,10))                                 AS CostMan,
		|	CAST(CASE
		|		WHEN NOT &CompanyManagementAccounting
		|			THEN 0
		|		WHEN SUM(DD.Cost) = 0
		|			THEN SUM(DD.StandardCost)
		|		ELSE SUM(DD.Cost)
		|	END AS NUMBER(23,10))                                 AS CostOfPersonalIncomeTax
		|INTO LaborCostsOfProduction
		|FROM
		|	TTCashEstimatedTurnoverWorkInProgress AS DD
		|	
		|	INNER JOIN ProductionBatchesAreSummarized AS ProductionBatchesAreSummarized
		|	ON ProductionBatchesAreSummarized.ProductionLot = DD.ProductionLot
		|	AND ProductionBatchesAreSummarized.Organization = DD.Organization
		|	
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|	ON CorrectedDocuments_.ReversedDocument = DD.Recorder
		|
		|WHERE
		|	NOT DD.OfficialTypeOfMovementParish
		|	AND NOT DD.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
		|	AND ProductionBatchesAreSummarized.CostAllocationForIssue
		|	AND NOT DD.ReversingEntry
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	AND CorrectedDocuments_.ReversedDocument IS NULL
		|
		|GROUP BY
		|	DD.Organization,
		|	DD.Department,
		|	DD.Recorder,
		|	DD.Period,
		|	DD.ProductionLot,
		|	DD.CorDimensionOfProductsAccounting,
		|	DD.CorInventoryOwnerAttributesOfProducts,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorAccountingSection";
	
	QueriesTexts.Add(QueryText);
	CalculationOfCostLocalization.SupplementRequestWithUnfinishedProductionLaborCosts(QueriesTexts);

	QueryText = MergeTexts(QueriesTexts);
	QueryText = QueryText + "
		|
		|INDEX BY
		|	Organization,
		|	Department,
		|	ProductionLot,
		|	ProductionOrder,
		|	RowCodeProducts";
	
	Return QueryText
		+ Common.QueryBatchSeparator();
		
EndFunction

Function TextMaterialCostsAndLaborCostsUnfinishedProduction()
	
	QueryText = 
		"SELECT
		|	DD.Organization                           AS Organization,
		|	DD.Department                         AS Department,
		|	DD.ExpenseLogger                    AS ExpenseLogger,
		|	DD.ProductionDate                      AS ProductionDate,
		|	DD.ProductionLot                    AS ProductionLot,
		|	DD.ProductionOrder                   AS ProductionOrder,
		|	DD.RowCodeProducts                    AS RowCodeProducts,
		|	DD.CorItemsLocationAttributes         AS CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute                         AS CorInventoryOwnerAttribute,
		|	DD.LotVendorAttributesCorr               AS LotVendorAttributesCorr,
		|	DD.CorAccountingSection                        AS CorAccountingSection,
		|	CAST(SUM(DD.Cost) AS NUMBER(23,10)) 			AS Cost,
		|	CAST(SUM(DD.CostExcludingVAT) AS NUMBER(23,10))    AS CostExcludingVAT,
		|	CAST(SUM(DD.LocalCost) AS NUMBER(23,10))      AS LocalCost,
		|	CAST(SUM(DD.CostMan) AS NUMBER(23,10))       AS CostMan,
		|	CAST(SUM(DD.CostOfPersonalIncomeTax) AS NUMBER(23,10))       AS CostOfPersonalIncomeTax
		|INTO MaterialAndLaborCostsOfProduction
		|FROM
		|	(SELECT
		|		DD.Organization                           AS Organization,
		|		DD.Department                         AS Department,
		|		DD.ExpenseLogger                    AS ExpenseLogger,
		|		DD.ProductionDate                      AS ProductionDate,
		|		DD.ProductionLot                    AS ProductionLot,
		|		DD.ProductionOrder                   AS ProductionOrder,
		|		DD.RowCodeProducts                    AS RowCodeProducts,
		|		DD.CorItemsLocationAttributes         AS CorItemsLocationAttributes,
		|		DD.CorInventoryOwnerAttribute                         AS CorInventoryOwnerAttribute,
		|		DD.LotVendorAttributesCorr               AS LotVendorAttributesCorr,
		|		DD.CorAccountingSection                        AS CorAccountingSection,
		|		DD.Cost                             AS Cost,
		|		DD.CostExcludingVAT                       AS CostExcludingVAT,
		|		DD.LocalCost                         AS LocalCost,
		|		DD.CostMan                          AS CostMan,
		|		DD.CostOfPersonalIncomeTax                          AS CostOfPersonalIncomeTax
		|	FROM MaterialCostsOfProduction AS DD
		|
		|UNION ALL
		|
		|	SELECT
		|		DD.Organization                           AS Organization,
		|		DD.Department                         AS Department,
		|		DD.ExpenseLogger                    AS ExpenseLogger,
		|		DD.ProductionDate                      AS ProductionDate,
		|		DD.ProductionLot                    AS ProductionLot,
		|		DD.ProductionOrder                   AS ProductionOrder,
		|		DD.RowCodeProducts                    AS RowCodeProducts,
		|		DD.CorItemsLocationAttributes         AS CorItemsLocationAttributes,
		|		DD.CorInventoryOwnerAttribute                         AS CorInventoryOwnerAttribute,
		|		DD.LotVendorAttributesCorr               AS LotVendorAttributesCorr,
		|		DD.CorAccountingSection                        AS CorAccountingSection,
		|		DD.Cost                             AS Cost,
		|		DD.CostExcludingVAT                       AS CostExcludingVAT,
		|		DD.LocalCost                         AS LocalCost,
		|		DD.CostMan                          AS CostMan,
		|		DD.CostOfPersonalIncomeTax                          AS CostOfPersonalIncomeTax
		|	FROM LaborCostsOfProduction AS DD) AS DD
		|
		|GROUP BY
		|	DD.Organization,
		|	DD.Department,
		|	DD.ExpenseLogger,
		|	DD.ProductionDate,
		|	DD.ProductionLot,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorAccountingSection
		|
		|INDEX BY
		|	Organization,
		|	Department,
		|	ProductionLot,
		|	ProductionOrder,
		|	RowCodeProducts";
	
	Return QueryText
		+ Common.QueryBatchSeparator();
		
EndFunction

Function TextReleasedProducts()
		
	QueriesTexts = New Array;
	
	QueryText =
		// Manufactured products without orders (goods and traceable works).
		"SELECT
		|	""TextReleasedProducts_1""	AS RequestSource,
		|	DD.Ref						AS ExpenseLogger,
		|	Attributes.Date					AS ProductionDate,
		|	CatProductionLots.Ref	AS ProductionLot,
		|	Attributes.Department			AS Department,
		|	UNDEFINED					AS ProductionOrder,
		|	0								AS RowCodeProducts,
		|	InventoryLocationAttributeKeys.Ref											AS CorItemsLocationAttributes,
		|	ISNULL(CatInventoryKinds.Ref, VALUE(Catalog.InventoryKinds.EmptyRef))	AS CorInventoryOwnerAttribute,
		|	CASE
		|		WHEN DD.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN ISNULL(BatchAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
		|		ELSE ISNULL(AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
		|	END							AS LotVendorAttributesCorr,
		|	CASE
		|		WHEN CatInventoryKinds.InventoryType IS NULL
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		WHEN CatInventoryKinds.InventoryType IN
		|				(VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|	END                                                   AS CorAccountingSection,
		|	CAST(SUM(CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count - ISNULL(LotsOfGNZPMaterials.Count, 0)
		|			ELSE DD.CostShare
		|					- ISNULL(LotsOfGNZPMaterials.Count, 0)
		|						* DD.CostShare
		|						/ DD.Count
		|		END) AS NUMBER(23,10))                            AS Cost,
		|	CAST(SUM(
		|		CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|		END) AS NUMBER(23,10))                            AS FullValue,
		|	0                                                       AS PlannedProductionQuantity,
		|	CatInventoryKinds.Organization                              AS Organization
		|INTO IssuedProducts
		|FROM
		|	Document.BackflushProduction.InventoryOwnerAttributesFinishedProducts AS DD
		|
		|	INNER JOIN Document.BackflushProduction AS Attributes
		|		ON DD.Ref = Attributes.Ref
		|			AND Attributes.Posted
		|
		|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
		|		ON CatProductionLots.Document =
		|			CASE
		|				WHEN Attributes.Patch
		|					AND Attributes.CorrectionSavesProductionLots
		|					THEN Attributes.CorrectedDocument
		|				ELSE Attributes.Ref
		|			END
		|			AND CatProductionLots.Code = DD.CostGroupNumber
		|			AND NOT CatProductionLots.DeletionMark
		|	
		|	INNER JOIN Catalog.InventoryKinds AS CatInventoryKinds
		|		ON DD.InventoryOwnerAttribute = CatInventoryKinds.Ref
		|			AND CatInventoryKinds.Organization IN (&CompanyArray)
		|
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON CatInventoryKinds.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		|	LEFT JOIN InformationRegister.LotVendorAttributes AS AnalysisOfAccountingOfBatchesOfGoods_
		|		ON AnalysisOfAccountingOfBatchesOfGoods_.FinancialAccountingGroup = VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
		|			AND AnalysisOfAccountingOfBatchesOfGoods_.Vendor           = VALUE(Catalog.Partners.EmptyRef)
		|			AND AnalysisOfAccountingOfBatchesOfGoods_.Counterparty          = UNDEFINED
		|			AND AnalysisOfAccountingOfBatchesOfGoods_.VATRate           = VALUE(Catalog.VATRates.EmptyRef)
		|			AND AnalysisOfAccountingOfBatchesOfGoods_.VATTaxation  = VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			AND AnalysisOfAccountingOfBatchesOfGoods_.AssetTaxClass         = VALUE(Enum.AssetKinds.Goods)
		|			AND AnalysisOfAccountingOfBatchesOfGoods_.RowCode           = DD.RowCode
		|			AND CatInventoryKinds.Organization IN (&SFIFOOrganizationsSliding)
		|
		|	LEFT JOIN InformationRegister.LotVendorAttributes AS BatchAccountingAnalysts
		|		ON BatchAccountingAnalysts.FinancialAccountingGroup = VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
		|			AND BatchAccountingAnalysts.Vendor           = VALUE(Catalog.Partners.EmptyRef)
		|			AND BatchAccountingAnalysts.Counterparty          = UNDEFINED
		|			AND BatchAccountingAnalysts.VATRate           = VALUE(Catalog.VATRates.EmptyRef)
		|			AND BatchAccountingAnalysts.VATTaxation  = VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			AND BatchAccountingAnalysts.AssetTaxClass         = VALUE(Enum.AssetKinds.OtherWorksAndServices)
		|			AND BatchAccountingAnalysts.RowCode           = DD.RowCode
		|			AND CatInventoryKinds.Organization IN (&SFIFOOrganizationsSliding)
		|
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DocumentAnalysisWithoutAssignment
		|		ON DocumentAnalysisWithoutAssignment.Products = DD.ItemsLocationAttributes.Products
		|			AND DocumentAnalysisWithoutAssignment.Characteristic = DD.ItemsLocationAttributes.Characteristic
		|			AND DocumentAnalysisWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND DocumentAnalysisWithoutAssignment.ProductCostElement = DD.ItemsLocationAttributes.ProductCostElement
		|			AND DocumentAnalysisWithoutAssignment.StorageLocation = DD.ItemsLocationAttributes.StorageLocation
		|			AND DocumentAnalysisWithoutAssignment.Series = DD.ItemsLocationAttributes.Series
		|
		|	LEFT JOIN Catalog.Warehouses AS CatWarehouses
		|		ON CatWarehouses.Ref = DD.ItemsLocationAttributes.StorageLocation
		|
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByBusinessUnit
		|		ON DD.ItemsLocationAttributes.Products = DimensionByBusinessUnit.Products
		|			AND DD.ItemsLocationAttributes.Characteristic = DimensionByBusinessUnit.Characteristic
		|			AND DD.ItemsLocationAttributes.Series = DimensionByBusinessUnit.Series
		|			AND Attributes.Department = DimensionByBusinessUnit.StorageLocation
		|			AND DD.ItemsLocationAttributes.Purpose = DimensionByBusinessUnit.Purpose
		|			AND DD.ItemsLocationAttributes.ProductCostElement = DimensionByBusinessUnit.ProductCostElement
		|
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsByDivisionWithoutAssignment
		|		ON DimensionByBusinessUnit.Products = AnalyticsByDivisionWithoutAssignment.Products
		|			AND DimensionByBusinessUnit.Characteristic = AnalyticsByDivisionWithoutAssignment.Characteristic
		|			AND DimensionByBusinessUnit.Series = AnalyticsByDivisionWithoutAssignment.Series
		|			AND DimensionByBusinessUnit.StorageLocation = AnalyticsByDivisionWithoutAssignment.StorageLocation
		|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsByDivisionWithoutAssignment.Purpose
		|			AND DimensionByBusinessUnit.ProductCostElement = AnalyticsByDivisionWithoutAssignment.ProductCostElement
		|
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|		ON InventoryLocationAttributeKeys.Ref = CASE
		|				WHEN &KeepRecordsOfInventoryCostByAssignments
		|					AND NOT CatWarehouses.ShopFloorStockroom
		|					THEN DimensionByBusinessUnit.DimensionKey
		|				WHEN NOT &KeepRecordsOfInventoryCostByAssignments
		|					AND NOT CatWarehouses.ShopFloorStockroom
		|					THEN AnalyticsByDivisionWithoutAssignment.DimensionKey
		|				WHEN &KeepRecordsOfInventoryCostByAssignments
		|					THEN DD.ItemsLocationAttributes
		|				ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|			END
		|
		|	LEFT JOIN LotsOfGNZPMaterials AS LotsOfGNZPMaterials
		|		ON LotsOfGNZPMaterials.ProductionLot = CatProductionLots.Ref
		|			AND LotsOfGNZPMaterials.BatchOfMaterial = DD.Ref
		|			AND (LotsOfGNZPMaterials.LotVendorAttributes = AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey
		|				OR LotsOfGNZPMaterials.LotVendorAttributes = BatchAccountingAnalysts.DimensionKey)
		|			AND CatInventoryKinds.Organization = LotsOfGNZPMaterials.Organization
		|
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|	ON CorrectedDocuments_.ReversedDocument = DD.Ref
		|
		|WHERE
		|	Attributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	AND CorrectedDocuments_.ReversedDocument IS NULL
		|
		|GROUP BY
		|	CatProductionLots.Ref,
		|	DD.Ref,
		|	Attributes.Date,
		|	Attributes.Department,
		|	InventoryLocationAttributeKeys.Ref,
		|	CatInventoryKinds.Ref,
		|	CASE
		|		WHEN CatInventoryKinds.InventoryType IS NULL
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		WHEN CatInventoryKinds.InventoryType IN
		|				(VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|	END,
		|	CASE
		|		WHEN DD.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN ISNULL(BatchAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
		|		ELSE ISNULL(AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
		|	END,
		|	CatInventoryKinds.Organization
		|
		|UNION ALL
		|
		// Released products without orders (work).
		|SELECT
		|	""TextReleasedProducts_2""                          AS RequestSource,
		|	DD.Ref                                               AS ExpenseLogger,
		|	Attributes.Date                                          AS ProductionDate,
		|	CatProductionLots.Ref                            AS ProductionLot,
		|	Attributes.Department                                 AS Department,
		|	UNDEFINED                                            AS ProductionOrder,
		|	0                                                       AS RowCodeProducts,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END                                                   AS CorItemsLocationAttributes,
		|	VALUE(Catalog.InventoryKinds.EmptyRef)           AS CorInventoryOwnerAttribute,
		|	CASE
		|		WHEN CatCompanies.Ref IN (&SFIFOOrganizationsSliding)
		|			THEN PartyAccountingAnalysts.DimensionKey
		|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|	END                                                   AS LotVendorAttributesCorr,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS CorAccountingSection,
		|	CAST(SUM(CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count - ISNULL(LotsOfGNZPMaterials.Count, 0)
		|			ELSE DD.CostShare
		|				- ISNULL(LotsOfGNZPMaterials.Count, 0)
		|					* DD.CostShare
		|					/ DD.Count
		|		END) AS NUMBER(23,10))                            AS Cost,
		|	CAST(SUM(
		|		CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|		END) AS NUMBER(23,10))                            AS FullValue,
		|	0                                                       AS PlannedProductionQuantity,
		|	CatCompanies.Ref                                   AS Organization
		|FROM
		|	Document.BackflushProduction.ManufacturedProducts AS DD
		|
		|	INNER JOIN Document.BackflushProduction AS Attributes
		|		ON DD.Ref = Attributes.Ref
		|
		|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
		|		ON CatProductionLots.Document =
		|			CASE
		|				WHEN Attributes.Patch
		|					AND Attributes.CorrectionSavesProductionLots
		|					THEN Attributes.CorrectedDocument
		|				ELSE Attributes.Ref
		|			END
		|		AND CatProductionLots.Code = DD.CostGroupNumber
		|		AND NOT CatProductionLots.DeletionMark
		|
		|	INNER JOIN Catalog.Companies AS CatCompanies
		|	ON CASE
		|		WHEN CatProductionLots.InternalSubcontracting
		|			THEN CatCompanies.Ref = DD.MaterialProviderCompany
		|		WHEN TRUE
		|			THEN CatCompanies.Ref = Attributes.Organization
		|		END
		|		AND CatCompanies.Ref IN (&CompanyArray)
		|
		|	LEFT JOIN InformationRegister.LotVendorAttributes AS PartyAccountingAnalysts
		|		ON PartyAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
		|		AND PartyAccountingAnalysts.Vendor				= VALUE(Catalog.Partners.EmptyRef)
		|		AND PartyAccountingAnalysts.Counterparty				= UNDEFINED
		|		AND PartyAccountingAnalysts.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
		|		AND PartyAccountingAnalysts.VATTaxation 		= VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		AND PartyAccountingAnalysts.AssetTaxClass				= VALUE(Enum.AssetKinds.OtherWorksAndServices)
		|		AND PartyAccountingAnalysts.RowCode				= DD.RowCode
		|
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DocumentAnalysisWithoutAssignment
		|		ON DocumentAnalysisWithoutAssignment.Products = DD.ItemsLocationAttributes.Products
		|		AND DocumentAnalysisWithoutAssignment.Characteristic = DD.ItemsLocationAttributes.Characteristic
		|		AND DocumentAnalysisWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|		AND DocumentAnalysisWithoutAssignment.ProductCostElement = DD.ItemsLocationAttributes.ProductCostElement
		|		AND DocumentAnalysisWithoutAssignment.StorageLocation = DD.ItemsLocationAttributes.StorageLocation
		|		AND DocumentAnalysisWithoutAssignment.Series = DD.ItemsLocationAttributes.Series
		|
		|	LEFT JOIN LotsOfGNZPMaterials AS LotsOfGNZPMaterials
		|		ON LotsOfGNZPMaterials.ProductionLot = CatProductionLots.Ref
		|		AND LotsOfGNZPMaterials.BatchOfMaterial = DD.Ref
		|		AND LotsOfGNZPMaterials.LotVendorAttributes = PartyAccountingAnalysts.DimensionKey
		|		AND CatCompanies.Ref = LotsOfGNZPMaterials.Organization
		|
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|	ON CorrectedDocuments_.ReversedDocument = DD.Ref
		|
		|WHERE
		|	Attributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Attributes.Posted
		|	AND DD.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|	AND NOT DD.Products.TracedGoods
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	AND CorrectedDocuments_.ReversedDocument IS NULL
		|
		|GROUP BY
		|	CatProductionLots.Ref,
		|	DD.Ref,
		|	Attributes.Date,
		|	Attributes.Department,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END,
		|	CASE
		|		WHEN CatCompanies.Ref IN (&SFIFOOrganizationsSliding)
		|			THEN PartyAccountingAnalysts.DimensionKey
		|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|	END,
		|	CatCompanies.Ref
		|
		|UNION ALL
		|
		// Manufactured products according to individual reports of processors 2.5.
		|SELECT
		|	""TextReleasedProducts_4""                          AS RequestSource,
		|	DD.Ref                                               AS ExpenseLogger,
		|	Attributes.Date                                          AS ProductionDate,
		|	CatProductionLots.Ref                            AS ProductionLot,
		|	Attributes.Department                                 AS Department,
		|	UNDEFINED                                            AS ProductionOrder,
		|	0                                                       AS RowCodeProducts,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END                                                   AS CorItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute           								AS CorInventoryOwnerAttribute,
		|	ISNULL(PartyAccountingAnalysts.DimensionKey,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)) AS LotVendorAttributesCorr,
		|	CASE
		|		WHEN DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners)
		|		WHEN DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
		|		  OR DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners)
		|		WHEN DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
		|	END AS CorAccountingSection,
		|	CAST(SUM(
		|		CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|		END) AS NUMBER(23,10)) AS Cost,
		|	CAST(SUM(
		|		CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|		END) AS NUMBER(23,10)) AS FullValue,
		|	0,
		|	Attributes.Organization AS Organization
		|FROM
		|	Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS DD
		|
		|		INNER JOIN Document.SubcontractorReport2_5 AS Attributes
		|		ON DD.Ref = Attributes.Ref
		|
		|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
		|		ON CatProductionLots.Document = DD.Ref
		|			AND CatProductionLots.Code = DD.CostGroupNumber
		|			AND NOT CatProductionLots.DeletionMark
		|
		|		LEFT JOIN InformationRegister.LotVendorAttributes AS PartyAccountingAnalysts
		|		ON PartyAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
		|			AND PartyAccountingAnalysts.Vendor			= VALUE(Catalog.Partners.EmptyRef)
		|			AND PartyAccountingAnalysts.Counterparty			= UNDEFINED
		|			AND PartyAccountingAnalysts.VATRate			= VALUE(Catalog.VATRates.EmptyRef)
		|			AND PartyAccountingAnalysts.VATTaxation	= VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			AND PartyAccountingAnalysts.AssetTaxClass			= VALUE(Enum.AssetKinds.Goods)
		|			AND PartyAccountingAnalysts.RowCode			= DD.RowCodeProducts
		|			AND Attributes.Organization IN (&SFIFOOrganizationsSliding)
		|
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DocumentAnalysisWithoutAssignment
		|		ON DocumentAnalysisWithoutAssignment.Products 		= DD.ItemsLocationAttributes.Products
		|			AND DocumentAnalysisWithoutAssignment.Characteristic 	= DD.ItemsLocationAttributes.Characteristic
		|			AND DocumentAnalysisWithoutAssignment.Purpose 		= VALUE(Catalog.Assignments.EmptyRef)
		|			AND DocumentAnalysisWithoutAssignment.ProductCostElement = DD.ItemsLocationAttributes.ProductCostElement
		|			AND DocumentAnalysisWithoutAssignment.StorageLocation 	= DD.ItemsLocationAttributes.StorageLocation
		|			AND DocumentAnalysisWithoutAssignment.Series 			= DD.ItemsLocationAttributes.Series
		|
		|WHERE
		|	Attributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Attributes.Posted
		|	AND Attributes.Organization IN(&CompanyArray)
		|	AND Attributes.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
		|	AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
		|
		|GROUP BY
		|	Attributes.Date,
		|	DD.Ref,
		|	CatProductionLots.Ref,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END,
		|	DD.InventoryOwnerAttribute,
		|	Attributes.Department,
		|	ISNULL(PartyAccountingAnalysts.DimensionKey,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)),
		|	Attributes.Organization
		|
		|UNION ALL
		|
		// Published works on individual reports of processors 2.5.
		|SELECT
		|	""TextReleasedProducts_5""                          AS RequestSource,
		|	DD.Ref                                               AS ExpenseLogger,
		|	Attributes.Date                                          AS ProductionDate,
		|	CatProductionLots.Ref                            AS ProductionLot,
		|	Attributes.Department                                 AS Department,
		|	UNDEFINED                                            AS ProductionOrder,
		|	0                                                       AS RowCodeProducts,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END                                                   AS CorItemsLocationAttributes,
		|	VALUE(Catalog.InventoryKinds.EmptyRef)           AS CorInventoryOwnerAttribute,
		|	ISNULL(PartyAccountingAnalysts.DimensionKey,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)) AS LotVendorAttributesCorr,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS CorAccountingSection,
		|	CAST(SUM(
		|		CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|		END) AS NUMBER(23,10)) AS Cost,
		|	CAST(SUM(
		|		CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|		END) AS NUMBER(23,10)) AS FullValue,
		|	0,
		|	Attributes.Organization AS Organization
		|FROM
		|	Document.SubcontractorReport2_5.ManufacturedProducts AS DD
		|
		|		INNER JOIN Document.SubcontractorReport2_5 AS Attributes
		|		ON DD.Ref = Attributes.Ref
		|
		|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
		|		ON CatProductionLots.Document = DD.Ref
		|			AND CatProductionLots.Code = DD.CostGroupNumber
		|			AND NOT CatProductionLots.DeletionMark
		|
		|		LEFT JOIN InformationRegister.LotVendorAttributes AS PartyAccountingAnalysts
		|		ON PartyAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
		|			AND PartyAccountingAnalysts.Vendor			= VALUE(Catalog.Partners.EmptyRef)
		|			AND PartyAccountingAnalysts.Counterparty			= UNDEFINED
		|			AND PartyAccountingAnalysts.VATRate			= VALUE(Catalog.VATRates.EmptyRef)
		|			AND PartyAccountingAnalysts.VATTaxation	= VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			AND PartyAccountingAnalysts.AssetTaxClass			= VALUE(Enum.AssetKinds.Goods)
		|			AND PartyAccountingAnalysts.RowCode			= DD.RowCodeProducts
		|			AND Attributes.Organization IN (&SFIFOOrganizationsSliding)
		|
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DocumentAnalysisWithoutAssignment
		|		ON DocumentAnalysisWithoutAssignment.Products 		= DD.ItemsLocationAttributes.Products
		|			AND DocumentAnalysisWithoutAssignment.Characteristic 	= DD.ItemsLocationAttributes.Characteristic
		|			AND DocumentAnalysisWithoutAssignment.Purpose 		= VALUE(Catalog.Assignments.EmptyRef)
		|			AND DocumentAnalysisWithoutAssignment.ProductCostElement = DD.ItemsLocationAttributes.ProductCostElement
		|			AND DocumentAnalysisWithoutAssignment.StorageLocation 	= DD.ItemsLocationAttributes.StorageLocation
		|			AND DocumentAnalysisWithoutAssignment.Series 			= DD.ItemsLocationAttributes.Series
		|
		|WHERE
		|	Attributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Attributes.Posted
		|	AND Attributes.Organization IN(&CompanyArray)
		|	AND Attributes.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
		|	AND DD.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|	AND NOT DD.Products.TracedGoods
		|
		|GROUP BY
		|	Attributes.Date,
		|	DD.Ref,
		|	CatProductionLots.Ref,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END,
		|	Attributes.Department,
		|	ISNULL(PartyAccountingAnalysts.DimensionKey,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)),
		|	Attributes.Organization
		|";
	
	QueriesTexts.Add(QueryText);
	QueryText = 
		// Manufactured products on orders (manufactured goods and traceable works).
		"SELECT
		|	""TextReleasedProducts_6""			AS RequestSource,
		|	Attributes.Ref						AS ExpenseLogger,
		|	DD.DateOfTransaction							AS ProductionDate,
		|	Attributes.ProductionLot			AS ProductionLot,
		|	DD.Department						AS Department,
		|	UNDEFINED							AS ProductionOrder,
		|	0										AS RowCodeProducts,
		|	InventoryLocationAttributeKeys.Ref	AS CorItemsLocationAttributes,
		|	ISNULL(CatInventoryKinds.Ref, VALUE(Catalog.InventoryKinds.EmptyRef))	AS CorInventoryOwnerAttribute,
		|	CASE
		|		WHEN DD.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN ISNULL(BatchAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
		|		ELSE ISNULL(AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
		|	END									AS LotVendorAttributesCorr,
		|	CASE
		|		WHEN CatInventoryKinds.InventoryType IN
		|				(VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|	END								AS CorAccountingSection,
		|	SUM(
		|		CASE
		|			WHEN DD.DateOfTransaction BETWEEN &BeginOfPeriod AND &EndOfPeriod 
		|				THEN CASE
		|					WHEN DD.CostShare = 0
		|						THEN DD.Count - ISNULL(LotsOfGNZPMaterials.Count, 0)
		|					ELSE DD.CostShare - ISNULL(LotsOfGNZPMaterials.Count, 0) * DD.CostShare / DD.Count
		|				END
		|		ELSE 0
		|	END)								AS Cost,
		|	SUM(
		|		CASE
		|			WHEN DD.DateOfTransaction BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|				THEN CASE
		|					WHEN DD.CostShare = 0
		|						THEN DD.Count
		|					ELSE DD.CostShare
		|				END
		|		ELSE 0
		|	END)								AS FullValue,
		|	SUM(
		|		CASE 
		|			WHEN DD.DateOfTransaction <= &EndOfPeriod
		|				THEN 0
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|	END)								AS PlannedProductionQuantity,
		|	CatCompanies.Ref				AS Organization
		|FROM
		|	Document.ProductionStage2_2.InventoryOwnerAttributesProducts AS DD
		|
		|	INNER JOIN Document.ProductionStage2_2 AS Attributes
		|	ON DD.Ref = Attributes.Ref
		|		AND Attributes.Posted
		|		AND NOT Attributes.ProductionByThirdParty
		|
		|	INNER JOIN Catalog.Companies AS CatCompanies
		|	ON CASE WHEN Attributes.InternalSubcontracting
		|			THEN CatCompanies.Ref = Attributes.MaterialProviderCompany
		|			ELSE CatCompanies.Ref = Attributes.Organization
		|		END
		|		AND CatCompanies.Ref IN (&CompanyArray)
		|
		|	INNER JOIN BatchesOfManufacturedProducts AS ProductionLots
		|	ON ProductionLots.ProductionLot = Attributes.ProductionLot
		|
		|	LEFT JOIN Catalog.InventoryKinds AS CatInventoryKinds
		|	ON DD.InventoryOwnerAttribute = CatInventoryKinds.Ref
		|		AND CatInventoryKinds.Organization = CatCompanies.Ref
		|
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DocumentAnalysisWithoutAssignment
		|	ON DocumentAnalysisWithoutAssignment.Products = DD.ItemsLocationAttributes.Products
		|		AND DocumentAnalysisWithoutAssignment.Characteristic = DD.ItemsLocationAttributes.Characteristic
		|		AND DocumentAnalysisWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|		AND DocumentAnalysisWithoutAssignment.ProductCostElement = DD.ItemsLocationAttributes.ProductCostElement
		|		AND DocumentAnalysisWithoutAssignment.StorageLocation = DD.ItemsLocationAttributes.StorageLocation
		|		AND DocumentAnalysisWithoutAssignment.Series = DD.ItemsLocationAttributes.Series
		|
		|	LEFT JOIN InformationRegister.LotVendorAttributes AS AnalysisOfAccountingOfBatchesOfGoods_
		|	ON AnalysisOfAccountingOfBatchesOfGoods_.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
		|		AND AnalysisOfAccountingOfBatchesOfGoods_.Vendor					= VALUE(Catalog.Partners.EmptyRef)
		|		AND AnalysisOfAccountingOfBatchesOfGoods_.Counterparty				= UNDEFINED
		|		AND AnalysisOfAccountingOfBatchesOfGoods_.VATRate					= VALUE(Catalog.VATRates.EmptyRef)
		|		AND AnalysisOfAccountingOfBatchesOfGoods_.VATTaxation 		= VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		AND AnalysisOfAccountingOfBatchesOfGoods_.AssetTaxClass				= VALUE(Enum.AssetKinds.Goods)
		|		AND AnalysisOfAccountingOfBatchesOfGoods_.RowCode					= DD.RowCode
		|		AND CatCompanies.Ref IN (&SFIFOOrganizationsSliding)
		|
		|	LEFT JOIN InformationRegister.LotVendorAttributes AS BatchAccountingAnalysts
		|	ON BatchAccountingAnalysts.FinancialAccountingGroup = VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
		|		AND BatchAccountingAnalysts.Vendor           = VALUE(Catalog.Partners.EmptyRef)
		|		AND BatchAccountingAnalysts.Counterparty          = UNDEFINED
		|		AND BatchAccountingAnalysts.VATRate           = VALUE(Catalog.VATRates.EmptyRef)
		|		AND BatchAccountingAnalysts.VATTaxation  = VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		AND BatchAccountingAnalysts.AssetTaxClass         = VALUE(Enum.AssetKinds.OtherWorksAndServices)
		|		AND BatchAccountingAnalysts.RowCode           = DD.RowCode
		|		AND CatCompanies.Ref IN (&SFIFOOrganizationsSliding)
		|
		|	LEFT JOIN LotsOfGNZPMaterials AS LotsOfGNZPMaterials
		|	ON LotsOfGNZPMaterials.ProductionLot = Attributes.ProductionLot
		|		AND LotsOfGNZPMaterials.BatchOfMaterial = DD.Ref
		|		AND (LotsOfGNZPMaterials.LotVendorAttributes = AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey
		|			OR LotsOfGNZPMaterials.LotVendorAttributes = BatchAccountingAnalysts.DimensionKey)
		|		AND LotsOfGNZPMaterials.Organization = CatCompanies.Ref
		|
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
		|	ON InventoryLocationAttributeKeys.Ref = CASE
		|				WHEN &KeepRecordsOfInventoryCostByAssignments
		|					THEN DD.ItemsLocationAttributes
		|				ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|			END
		|
		|
		|WHERE
		|	DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
		|
		|GROUP BY
		|	Attributes.Ref,
		|	DD.DateOfTransaction,
		|	Attributes.ProductionLot,
		|	DD.Department,
		|	InventoryLocationAttributeKeys.Ref,
		|	CatInventoryKinds.Ref,
		|	CASE
		|		WHEN CatInventoryKinds.InventoryType IN
		|				(VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|	END,
		|	CASE
		|		WHEN DD.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN ISNULL(BatchAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
		|		ELSE ISNULL(AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
		|	END,
		|	CatCompanies.Ref
		|
		|UNION ALL
		|
		// Released products on orders (not released goods, works).
		|SELECT
		|	""TextReleasedProducts_7""                  AS RequestSource,
		|	Attributes.Ref								AS ExpenseLogger,
		|	DD.ProductionDate								AS ProductionDate,
		|	Attributes.ProductionLot					AS ProductionLot,
		|	DD.Department								AS Department,
		|	UNDEFINED									AS ProductionOrder,
		|	0												AS RowCodeProducts,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END											AS CorItemsLocationAttributes,
		|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS CorInventoryOwnerAttribute,
		|	CASE
		|		WHEN DD.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN ISNULL(BatchAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
		|		ELSE ISNULL(AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
		|	END											AS LotVendorAttributesCorr,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)	AS CorAccountingSection,
		|	SUM(
		|		CASE
		|			WHEN DD.Manufactured
		|				AND DD.ProductionDate BETWEEN &BeginOfPeriod AND &EndOfPeriod 
		|				THEN CASE
		|					WHEN DD.CostShare = 0
		|						THEN DD.Count - ISNULL(LotsOfGNZPMaterials.Count, 0)
		|					ELSE DD.CostShare - ISNULL(LotsOfGNZPMaterials.Count, 0) * DD.CostShare / DD.Count
		|				END
		|		ELSE 0
		|	END)											AS Cost,
		|	SUM(
		|		CASE
		|			WHEN DD.Manufactured
		|				AND DD.ProductionDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|				THEN CASE
		|					WHEN DD.CostShare = 0
		|						THEN DD.Count
		|					ELSE DD.CostShare
		|				END
		|		ELSE 0
		|	END)											AS FullValue,
		|	SUM(
		|		CASE 
		|			WHEN DD.Manufactured
		|				AND DD.ProductionDate <= &EndOfPeriod
		|				THEN 0
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|	END)											AS PlannedProductionQuantity,
		|	CatCompanies.Ref							AS Organization
		|FROM
		|	Document.ProductionStage2_2.ManufacturedProducts AS DD
		|
		|	INNER JOIN Document.ProductionStage2_2 AS Attributes
		|		ON DD.Ref = Attributes.Ref
		|		AND Attributes.Posted
		|		AND NOT Attributes.ProductionByThirdParty
		|
		|	INNER JOIN Catalog.Companies AS CatCompanies
		|	ON CASE WHEN Attributes.InternalSubcontracting
		|			THEN CatCompanies.Ref = Attributes.MaterialProviderCompany
		|			ELSE CatCompanies.Ref = Attributes.Organization
		|		END
		|		AND CatCompanies.Ref IN (&CompanyArray)
		|
		|	INNER JOIN BatchesOfManufacturedProducts AS ProductionLots
		|		ON ProductionLots.ProductionLot = Attributes.ProductionLot
		|
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DocumentAnalysisWithoutAssignment
		|	ON DocumentAnalysisWithoutAssignment.Products = DD.ItemsLocationAttributes.Products
		|	AND DocumentAnalysisWithoutAssignment.Characteristic = DD.ItemsLocationAttributes.Characteristic
		|	AND DocumentAnalysisWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|	AND DocumentAnalysisWithoutAssignment.ProductCostElement = DD.ItemsLocationAttributes.ProductCostElement
		|	AND DocumentAnalysisWithoutAssignment.StorageLocation = DD.ItemsLocationAttributes.StorageLocation
		|	AND DocumentAnalysisWithoutAssignment.Series = DD.ItemsLocationAttributes.Series
		|
		|	LEFT JOIN InformationRegister.LotVendorAttributes AS AnalysisOfAccountingOfBatchesOfGoods_
		|	ON AnalysisOfAccountingOfBatchesOfGoods_.FinancialAccountingGroup = VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
		|	AND AnalysisOfAccountingOfBatchesOfGoods_.Vendor				= VALUE(Catalog.Partners.EmptyRef)
		|	AND AnalysisOfAccountingOfBatchesOfGoods_.Counterparty			= UNDEFINED
		|	AND AnalysisOfAccountingOfBatchesOfGoods_.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
		|	AND AnalysisOfAccountingOfBatchesOfGoods_.VATTaxation 	= VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	AND AnalysisOfAccountingOfBatchesOfGoods_.AssetTaxClass			= VALUE(Enum.AssetKinds.Goods)
		|	AND AnalysisOfAccountingOfBatchesOfGoods_.RowCode				= DD.RowCode
		|	AND CatCompanies.Ref IN (&SFIFOOrganizationsSliding)
		|
		|	LEFT JOIN InformationRegister.LotVendorAttributes AS BatchAccountingAnalysts
		|	ON BatchAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
		|	AND BatchAccountingAnalysts.Vendor				= VALUE(Catalog.Partners.EmptyRef)
		|	AND BatchAccountingAnalysts.Counterparty				= UNDEFINED
		|	AND BatchAccountingAnalysts.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
		|	AND BatchAccountingAnalysts.VATTaxation		= VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	AND BatchAccountingAnalysts.AssetTaxClass				= VALUE(Enum.AssetKinds.OtherWorksAndServices)
		|	AND BatchAccountingAnalysts.RowCode				= DD.RowCode
		|	AND CatCompanies.Ref IN (&SFIFOOrganizationsSliding)
		|
		|	LEFT JOIN LotsOfGNZPMaterials AS LotsOfGNZPMaterials
		|	ON LotsOfGNZPMaterials.ProductionLot = Attributes.ProductionLot
		|	AND LotsOfGNZPMaterials.BatchOfMaterial = DD.Ref
		|	AND (LotsOfGNZPMaterials.LotVendorAttributes = AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey
		|		OR LotsOfGNZPMaterials.LotVendorAttributes = BatchAccountingAnalysts.DimensionKey)
		|	AND LotsOfGNZPMaterials.Organization = CatCompanies.Ref
		|
		|WHERE
		|	Attributes.Posted
		|	AND NOT DD.Canceled
		|	AND (DD.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		AND NOT DD.Products.TracedGoods
		|		OR NOT DD.Manufactured)
		|
		|GROUP BY
		|	Attributes.Ref,
		|	DD.ProductionDate,
		|	Attributes.ProductionLot,
		|	DD.Department,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END,
		|	CASE
		|		WHEN DD.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN ISNULL(BatchAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
		|		ELSE ISNULL(AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
		|	END,
		|	CatCompanies.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	""TextReleasedProducts_9""                          AS RequestSource,
		|	ReportDetails_.Ref                                  AS ExpenseLogger,
		|	ReportDetails_.Date                                    AS ProductionDate,
		|	StageDetails.ProductionLot                       AS ProductionLot,
		|	ReportDetails_.Department                           AS Department,
		|	UNDEFINED                                            AS ProductionOrder,
		|	0                                                       AS RowCodeProducts,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END                                                   AS CorItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute           								AS CorInventoryOwnerAttribute,
		|	ISNULL(PartyAccountingAnalysts.DimensionKey,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)) AS LotVendorAttributesCorr,
		|	CASE
		|		WHEN DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners)
		|		WHEN DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
		|		  OR DD.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners)
		|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
		|	END AS CorAccountingSection,
		|	CAST(SUM(
		|		DD.Count *
		|		CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|		END / DD.Count) AS NUMBER(23,10))  AS Cost,
		|	CAST(SUM(
		|		DD.Count *
		|		CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|		END / DD.Count) AS NUMBER(23,10))	AS FullValue,
		|	0,
		|	ReportDetails_.Organization						AS Organization
		|FROM
		|	Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS DD
		|
		|		INNER JOIN Document.SubcontractorReport2_5 AS ReportDetails_
		|		ON DD.Ref = ReportDetails_.Ref
		|
		|		INNER JOIN Document.ProductionStage2_2 AS StageDetails
		|		ON DD.ProductionStage = StageDetails.Ref
		|
		|		LEFT JOIN InformationRegister.LotVendorAttributes AS PartyAccountingAnalysts
		|		ON PartyAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
		|			AND PartyAccountingAnalysts.Vendor				= VALUE(Catalog.Partners.EmptyRef)
		|			AND PartyAccountingAnalysts.Counterparty				= UNDEFINED
		|			AND PartyAccountingAnalysts.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
		|			AND PartyAccountingAnalysts.VATTaxation		= VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			AND PartyAccountingAnalysts.AssetTaxClass				= VALUE(Enum.AssetKinds.Goods)
		|			AND PartyAccountingAnalysts.RowCode				= DD.RowCodeProducts
		|			AND ReportDetails_.Organization IN (&SFIFOOrganizationsSliding)
		|
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DocumentAnalysisWithoutAssignment
		|		ON DocumentAnalysisWithoutAssignment.Products = DD.ItemsLocationAttributes.Products
		|			AND DocumentAnalysisWithoutAssignment.Characteristic = DD.ItemsLocationAttributes.Characteristic
		|			AND DocumentAnalysisWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND DocumentAnalysisWithoutAssignment.ProductCostElement = DD.ItemsLocationAttributes.ProductCostElement
		|			AND DocumentAnalysisWithoutAssignment.StorageLocation = DD.ItemsLocationAttributes.StorageLocation
		|			AND DocumentAnalysisWithoutAssignment.Series = DD.ItemsLocationAttributes.Series
		|
		|WHERE
		|	ReportDetails_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND ReportDetails_.Posted
		|	AND ReportDetails_.Organization IN(&CompanyArray)
		|	AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
		|
		|GROUP BY
		|	StageDetails.ProductionLot,
		|	ReportDetails_.Ref,
		|	ReportDetails_.Date,
		|	StageDetails.Ref,
		|	ReportDetails_.Department,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END,
		|	DD.InventoryOwnerAttribute,
		|	ISNULL(PartyAccountingAnalysts.DimensionKey,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)),
		|	ReportDetails_.Organization
		|
		|UNION ALL
		|
		|SELECT
		|	""TextReleasedProducts_10""                         AS RequestSource,
		|	ReportDetails_.Ref                                  AS ExpenseLogger,
		|	ReportDetails_.Date                                    AS ProductionDate,
		|	StageDetails.ProductionLot                       AS ProductionLot,
		|	ReportDetails_.Department                           AS Department,
		|	UNDEFINED                                            AS ProductionOrder,
		|	0                                                       AS RowCodeProducts,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END                                                   AS CorItemsLocationAttributes,
		|	VALUE(Catalog.InventoryKinds.EmptyRef)           AS CorInventoryOwnerAttribute,
		|	ISNULL(PartyAccountingAnalysts.DimensionKey,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)) AS LotVendorAttributesCorr,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS CorAccountingSection,
		|	CAST(SUM(
		|		DD.Count *
		|		CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|		END / DD.Count) AS NUMBER(23,10))  AS Cost,
		|	CAST(SUM(
		|		DD.Count *
		|		CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|		END / DD.Count) AS NUMBER(23,10))	AS FullValue,
		|	0,
		|	ReportDetails_.Organization						AS Organization
		|FROM
		|	Document.SubcontractorReport2_5.ManufacturedProducts AS DD
		|
		|		INNER JOIN Document.SubcontractorReport2_5 AS ReportDetails_
		|		ON DD.Ref = ReportDetails_.Ref
		|
		|		INNER JOIN Document.ProductionStage2_2 AS StageDetails
		|		ON DD.ProductionStage = StageDetails.Ref
		|
		|		LEFT JOIN InformationRegister.LotVendorAttributes AS PartyAccountingAnalysts
		|		ON PartyAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
		|			AND PartyAccountingAnalysts.Vendor				= VALUE(Catalog.Partners.EmptyRef)
		|			AND PartyAccountingAnalysts.Counterparty				= UNDEFINED
		|			AND PartyAccountingAnalysts.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
		|			AND PartyAccountingAnalysts.VATTaxation		= VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			AND PartyAccountingAnalysts.AssetTaxClass				= VALUE(Enum.AssetKinds.Goods)
		|			AND PartyAccountingAnalysts.RowCode				= DD.RowCodeProducts
		|			AND ReportDetails_.Organization IN (&SFIFOOrganizationsSliding)
		|
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DocumentAnalysisWithoutAssignment
		|		ON DocumentAnalysisWithoutAssignment.Products = DD.ItemsLocationAttributes.Products
		|			AND DocumentAnalysisWithoutAssignment.Characteristic = DD.ItemsLocationAttributes.Characteristic
		|			AND DocumentAnalysisWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND DocumentAnalysisWithoutAssignment.ProductCostElement = DD.ItemsLocationAttributes.ProductCostElement
		|			AND DocumentAnalysisWithoutAssignment.StorageLocation = DD.ItemsLocationAttributes.StorageLocation
		|			AND DocumentAnalysisWithoutAssignment.Series = DD.ItemsLocationAttributes.Series
		|
		|WHERE
		|	ReportDetails_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND ReportDetails_.Posted
		|	AND ReportDetails_.Organization IN(&CompanyArray)
		|	AND DD.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|
		|GROUP BY
		|	StageDetails.ProductionLot,
		|	ReportDetails_.Ref,
		|	ReportDetails_.Date,
		|	StageDetails.Ref,
		|	ReportDetails_.Department,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END,
		|	ISNULL(PartyAccountingAnalysts.DimensionKey,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)),
		|	ReportDetails_.Organization
		|
		|UNION ALL
		|
		|SELECT
		|	""TextReleasedProducts_11""	AS RequestSource,
		|	ReportDetails_.Ref			AS ExpenseLogger,
		|	ReportDetails_.Date			AS ProductionDate,
		|	DD.ProductionLot			AS ProductionLot,
		|	ReportDetails_.Department	AS Department,
		|	UNDEFINED					AS ProductionOrder,
		|	0								AS RowCodeProducts,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN Dimension.Ref
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END																			AS CorItemsLocationAttributes,
		|	VALUE(Catalog.InventoryKinds.EmptyRef)									AS CorInventoryOwnerAttribute,
		|	ISNULL(T.LotVendorAttributesCorr,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))				AS LotVendorAttributesCorr,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)	AS CorAccountingSection,
		|	CAST(SUM(
		|		DD.Count *
		|		CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|		END / DD.Count) AS NUMBER(23, 10))		AS Cost,
		|	CAST(SUM(
		|		DD.Count *
		|		CASE
		|			WHEN DD.CostShare = 0
		|				THEN DD.Count
		|			ELSE DD.CostShare
		|		END / DD.Count) AS NUMBER(23, 10))		AS FullValue,
		|	0													AS PlannedProductionQuantity,
		|	ReportDetails_.Organization							AS Organization
		|FROM
		|	Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS DD
		|
		|		INNER JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS ReportDetails_
		|		ON DD.Ref = ReportDetails_.Ref
		|		
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON DD.ItemsLocationAttributes = Dimension.Ref
		|		
		|		LEFT JOIN AccumulationRegister.InventoryCost AS T
		|		ON T.Recorder = ReportDetails_.Ref
		|			AND T.RowID = DD.RowID
		|			AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
		|			AND NOT T.LotCalculation 
		|			AND NOT T.CalculationOfCost
		|			AND ReportDetails_.Organization IN (&SFIFOOrganizationsSliding)
		|
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DocumentAnalysisWithoutAssignment
		|		ON DocumentAnalysisWithoutAssignment.Products = Dimension.Products
		|			AND DocumentAnalysisWithoutAssignment.Characteristic = Dimension.Characteristic
		|			AND DocumentAnalysisWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND DocumentAnalysisWithoutAssignment.ProductCostElement = Dimension.ProductCostElement
		|			AND DocumentAnalysisWithoutAssignment.StorageLocation = Dimension.StorageLocation
		|			AND DocumentAnalysisWithoutAssignment.Series = Dimension.Series
		|
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|		LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.ReversedDocument = DD.Ref
		|WHERE
		|	ReportDetails_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND ReportDetails_.Posted
		|	AND ReportDetails_.Organization IN(&CompanyArray)
		|	AND NOT DD.Products.TracedGoods
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	AND CorrectedDocuments_.ReversedDocument IS NULL
		|
		|GROUP BY
		|	DD.ProductionLot,
		|	ReportDetails_.Ref,
		|	ReportDetails_.Date,
		|	ReportDetails_.Department,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN Dimension.Ref
		|		ELSE DocumentAnalysisWithoutAssignment.DimensionKey
		|	END,
		|	ISNULL(T.LotVendorAttributesCorr,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)),
		|	ReportDetails_.Organization
		|";
		
	QueriesTexts.Add(QueryText);
	CalculationOfCostLocalization.SupplementRequestWithReleasedProducts(QueriesTexts);
	
	QueryText = MergeTexts(QueriesTexts);
	QueryText = QueryText + "
		|
		|INDEX BY
		|	Organization,
		|	ProductionLot,
		|	ProductionOrder,
		|	RowCodeProducts,
		|	Department";
	
	Return QueryText
		+ Common.QueryBatchSeparator();
		
EndFunction

Function TextOtherExpensesUnfinishedProductionInitialization()
	
	QueriesTexts = New Array;
	
	QueryText =
		"
		|SELECT
		|	DD.Organization,
		|	DD.ProductionLot,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts,
		|	DD.RuleOfCostAllocatingToProductionLots,
		|	SUM(DD.IndicatorOfAllocationToIssue),
		|	SUM(DD.IndicatorOfAttributionToOutputWithoutVAT),
		|	SUM(DD.LocalIssueAttributionRate),
		|	SUM(DD.IndicatorOfAssignmentToIssueOfMan),
		
		|	SUM(DD.IndicatorOfAttributionToIssueOfPersonalIncomeTax)
		|INTO ProductionCosts_
		|FROM
		|	(SELECT
		|		DD.Organization AS Organization,
		|		DD.ProductionLot AS ProductionLot,
		|		DD.ProductionOrder AS ProductionOrder,
		|		DD.RowCodeProducts AS RowCodeProducts,
		|		DD.RuleOfCostAllocatingToProductionLots AS RuleOfCostAllocatingToProductionLots,
		|		SUM(Costs.Cost) AS IndicatorOfAllocationToIssue,
		|		SUM(Costs.CostExcludingVAT) AS IndicatorOfAttributionToOutputWithoutVAT,
		|		SUM(Costs.LocalCost) AS LocalIssueAttributionRate,
		|		SUM(Costs.CostMan) AS IndicatorOfAssignmentToIssueOfMan,
		|		SUM(Costs.CostOfPersonalIncomeTax) AS IndicatorOfAttributionToIssueOfPersonalIncomeTax
		|	FROM
		|		PartiesForAttributingExpensesInSummary AS DD
		|			INNER JOIN MaterialCostsOfProduction AS Costs
		|			ON (Costs.Organization = DD.Organization)
		|				AND (Costs.Department = DD.Department)
		|				AND (Costs.ProductionLot = DD.ProductionLot)
		|				AND (Costs.ProductionOrder = DD.ProductionOrder)
		|				AND (Costs.RowCodeProducts = DD.RowCodeProducts)
		|	WHERE
		|		DD.RuleOfCostAllocatingToProductionLots = VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts)
		|	
		|	GROUP BY
		|		DD.Organization,
		|		DD.ProductionLot,
		|		DD.ProductionOrder,
		|		DD.RowCodeProducts,
		|		DD.RuleOfCostAllocatingToProductionLots
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DD.Organization,
		|		DD.ProductionLot,
		|		DD.ProductionOrder,
		|		DD.RowCodeProducts,
		|		DD.RuleOfCostAllocatingToProductionLots,
		|		SUM(Costs.Cost),
		|		SUM(Costs.CostExcludingVAT),
		|		SUM(Costs.LocalCost),
		|		SUM(Costs.CostMan),
		|		SUM(Costs.CostOfPersonalIncomeTax)
		|	FROM
		|		PartiesForAttributingExpensesInSummary AS DD
		|			INNER JOIN LaborCostsOfProduction AS Costs
		|			ON (Costs.Organization = DD.Organization)
		|				AND (Costs.Department = DD.Department)
		|				AND (Costs.ProductionLot = DD.ProductionLot)
		|				AND (Costs.ProductionOrder = DD.ProductionOrder)
		|				AND (Costs.RowCodeProducts = DD.RowCodeProducts)
		|	WHERE
		|		DD.RuleOfCostAllocatingToProductionLots = VALUE(Enum.RulesOfCostAllocationToProductCost.ByLaborCosts)
		|	
		|	GROUP BY
		|		DD.Organization,
		|		DD.ProductionLot,
		|		DD.ProductionOrder,
		|		DD.RowCodeProducts,
		|		DD.RuleOfCostAllocatingToProductionLots
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DD.Organization,
		|		DD.ProductionLot,
		|		DD.ProductionOrder,
		|		DD.RowCodeProducts,
		|		DD.RuleOfCostAllocatingToProductionLots,
		|		SUM(Costs.Cost),
		|		SUM(Costs.CostExcludingVAT),
		|		SUM(Costs.LocalCost),
		|		SUM(Costs.CostMan),
		|		SUM(Costs.CostOfPersonalIncomeTax)
		|	FROM
		|		PartiesForAttributingExpensesInSummary AS DD
		|			INNER JOIN MaterialAndLaborCostsOfProduction AS Costs
		|			ON (Costs.Organization = DD.Organization)
		|				AND (Costs.Department = DD.Department)
		|				AND (Costs.ProductionLot = DD.ProductionLot)
		|				AND (Costs.ProductionOrder = DD.ProductionOrder)
		|				AND (Costs.RowCodeProducts = DD.RowCodeProducts)
		|	WHERE
		|		DD.RuleOfCostAllocatingToProductionLots = VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts)
		|	
		|	GROUP BY
		|		DD.Organization,
		|		DD.ProductionLot,
		|		DD.ProductionOrder,
		|		DD.RowCodeProducts,
		|		DD.RuleOfCostAllocatingToProductionLots
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DD.Organization,
		|		DD.ProductionLot,
		|		DD.ProductionOrder,
		|		DD.RowCodeProducts,
		|		DD.RuleOfCostAllocatingToProductionLots,
		|		SUM(Costs.Cost),
		|		SUM(Costs.Cost),
		|		SUM(Costs.Cost),
		|		SUM(Costs.Cost),
		|		SUM(Costs.Cost)
		|	FROM
		|		PartiesForAttributingExpensesInSummary AS DD
		|			INNER JOIN IssuedProducts AS Costs
		|			ON (Costs.Organization = DD.Organization)
		|				AND (Costs.ProductionLot = DD.ProductionLot)
		|				AND (Costs.ProductionOrder = DD.ProductionOrder)
		|				AND (Costs.RowCodeProducts = DD.RowCodeProducts)
		|				AND CASE
		|					WHEN DD.RowCodeProducts > 0
		|						THEN Costs.Department = DD.Department
		|					ELSE
		|						TRUE
		|				END
		|	WHERE
		|		DD.RuleOfCostAllocatingToProductionLots IN (VALUE(Enum.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases),
		|										VALUE(Enum.RulesOfCostAllocationToProductCost.ByProducts),
		|										VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef))
		|	
		|	GROUP BY
		|		DD.Organization,
		|		DD.ProductionLot,
		|		DD.ProductionOrder,
		|		DD.RowCodeProducts,
		|		DD.RuleOfCostAllocatingToProductionLots
		|
		|	UNION ALL
		|	
		|	SELECT
		|		SharesOfProductionCosts.Organization,
		|		SharesOfProductionCosts.ProductionLot,
		|		SharesOfProductionCosts.ProductionOrder,
		|		SharesOfProductionCosts.RowCodeProducts,
		|		SharesOfProductionCosts.RuleOfCostAllocatingToProductionLots,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0
		|	FROM
		|		SharesOfProductionCosts AS SharesOfProductionCosts
		|	WHERE
		|		SharesOfProductionCosts.RuleOfCostAllocatingToProductionLots IN (VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts), 
		|																VALUE(Enum.RulesOfCostAllocationToProductCost.ByLaborCosts), 
		|																VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts))
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DirectProductionCosts.Organization,
		|		DirectProductionCosts.ProductionLot,
		|		DirectProductionCosts.ProductionOrder,
		|		DirectProductionCosts.RowCodeProducts,
		|		DirectProductionCosts.RuleOfCostAllocatingToProductionLots,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0
		|	FROM
		|		DirectProductionCosts AS DirectProductionCosts
		|	WHERE
		|		DirectProductionCosts.RuleOfCostAllocatingToProductionLots IN (VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts), 
		|																VALUE(Enum.RulesOfCostAllocationToProductCost.ByLaborCosts), 
		|																VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts))
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		OtherWorkInProgressExpensesBalance.Organization,
		|		OtherWorkInProgressExpensesBalance.ProductionLot,
		|		OtherWorkInProgressExpensesBalance.ProductionOrder,
		|		OtherWorkInProgressExpensesBalance.RowCodeProducts,
		|		OtherWorkInProgressExpensesBalance.RuleOfCostAllocatingToProductionLots,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0
		|	FROM
		|		AccumulationRegister.OtherWorkInProgressExpenses.Balance(&BeginOfPeriod, ) AS OtherWorkInProgressExpensesBalance
		|	WHERE
		|		(OtherWorkInProgressExpensesBalance.CostBalance <> 0
		|			OR OtherWorkInProgressExpensesBalance.CostExcludingVATBalance <> 0
		|			OR OtherWorkInProgressExpensesBalance.LocalCostBalance <> 0)) AS DD
		|
		|GROUP BY
		|	DD.Organization,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts,
		|	DD.RuleOfCostAllocatingToProductionLots,
		|	DD.ProductionLot";
		
	QueriesTexts.Add(QueryText);
	QueryText =
		"SELECT DISTINCT
		|	DD.Organization,
		|	DD.ProductionLot
		|INTO RecipientsOfItemByItemExpenses22
		|FROM
		|	ProductionCosts_ AS DD
		|WHERE
		|	DD.RuleOfCostAllocatingToProductionLots IN (VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts),
		|								VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts))
		|	AND NOT DD.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
		|
		|INDEX BY
		|	DD.Organization,
		|	DD.ProductionLot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DD.Organization,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts,
		|	DD.ProductionLot
		|INTO RecipientsOfArticleByArticleLaborCosts
		|FROM
		|	ProductionCosts_ AS DD
		|WHERE
		|	DD.RuleOfCostAllocatingToProductionLots IN (VALUE(Enum.RulesOfCostAllocationToProductCost.ByLaborCosts),
		|								VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts))";
	
	QueriesTexts.Add(QueryText);
	QueryText = MergeTexts(QueriesTexts, 
		Common.QueryBatchSeparator());
		
	Return QueryText
		+ Common.QueryBatchSeparator();
		
EndFunction

Function TextRemainsOfDistributionBases()
	
	QueriesTexts = New Array;
	
	QueryText =
		"SELECT
		|	Lots.Organization AS Organization,
		|	Dimension.StorageLocation AS Department,
		|	DD.Lot AS ProductionLot,
		|	UNDEFINED AS ProductionOrder,
		|	0 AS RowCodeProducts,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts) AS RuleOfCostAllocatingToProductionLots,
		|	CAST(SUM(DD.Count * (ISNULL(Prices.Cost, 0) + ISNULL(Prices.AdditionalExpenseCost, 0) + ISNULL(Prices.OffBalanceCost, 0))) AS NUMBER(23, 10)) AS Balance,
		|	CAST(SUM(DD.Count * (ISNULL(Prices.CostExcludingVAT, 0) + ISNULL(Prices.AdditionalExpensesCostExcludingVAT, 0) + ISNULL(Prices.OffBalanceCost, 0))) AS NUMBER(23, 10)) AS BalanceWithoutVAT,
		|	CAST(SUM(DD.Count * (ISNULL(Prices.LocalCost, 0) + ISNULL(Prices.AddExpensesLocal, 0) + ISNULL(Prices.OffBalanceCostLocal, 0))) AS NUMBER(23, 10)) AS RemainderOfLocal,
		|	CAST(SUM(DD.Count * (ISNULL(Prices.CostMan, 0) + ISNULL(Prices.AddExpensesMan, 0) + ISNULL(Prices.OffBalanceCost, 0))) AS NUMBER(23, 10)) AS BalanceMan,
		|	CAST(SUM(DD.Count * (ISNULL(Prices.CostOfPersonalIncomeTax, 0))) AS NUMBER(23, 10)) AS PersonalIncomeTaxBalance
		|INTO RemnantsOfDistributionBases
		|FROM
		|	TTCashSettlementBalancesCostOfGoods AS DD
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
		|		ON DD.ItemsLocationAttributes = Dimension.DimensionKey
		|		INNER JOIN RecipientsOfItemByItemExpenses22 AS Lots
		|		ON DD.Organization = Lots.Organization
		|		AND DD.Lot = Lots.ProductionLot
		|		LEFT JOIN TTValueOfBatchesOfGoods AS Prices
		|		ON (Prices.Organization = DD.Organization)
		|			AND (Prices.Lot = DD.Lot)
		|			AND (Prices.LotVendorAttributes = DD.LotVendorAttributes)
		|			AND (Prices.FinancialAccountingDimension = DD.FinancialAccountingDimension)
		|			AND (Prices.VATActivityType = DD.VATActivityType)
		|			AND (Prices.ItemsLocationAttributes = DD.ItemsLocationAttributes)
		|			AND (Prices.InventoryOwnerAttribute = DD.InventoryOwnerAttribute)
		|			AND (Prices.AccountingSection = DD.AccountingSection)
		|WHERE
		|	DD.Count > 0
		|
		|GROUP BY
		|	Lots.Organization,
		|	Dimension.StorageLocation,
		|	DD.Lot
		|
		|UNION ALL
		|
		|SELECT
		|	DD.Organization,
		|	ISNULL(Balance.Department, VALUE(Catalog.BusinessStructure.EmptyRef)),
		|	DD.ProductionLot,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.ByLaborCosts),
		|	SUM(CASE
		|			WHEN ISNULL(Balance.Cost, 0) = 0
		|				THEN ISNULL(Balance.StandardCost, 0)
		|			ELSE Balance.Cost
		|		END),
		|	SUM(CASE
		|			WHEN ISNULL(Balance.Cost, 0) = 0
		|				THEN ISNULL(Balance.StandardCost, 0)
		|			ELSE Balance.Cost
		|		END),
		|	SUM(CASE
		|			WHEN ISNULL(Balance.LocalCost, 0) = 0
		|				THEN ISNULL(Balance.StandardCost, 0)
		|			ELSE Balance.LocalCost
		|		END),
		|	SUM(CASE
		|			WHEN ISNULL(Balance.Cost, 0) = 0
		|				THEN ISNULL(Balance.StandardCost, 0)
		|			ELSE Balance.Cost
		|		END),
		|	SUM(CASE
		|			WHEN ISNULL(Balance.CostOfPersonalIncomeTax, 0) = 0
		|				THEN ISNULL(Balance.StandardCost, 0)
		|			ELSE Balance.Cost
		|		END)
		|FROM
		|	RecipientsOfArticleByArticleLaborCosts AS DD
		|		LEFT JOIN TTCashEstimatedBalancesWorkInProgress AS Balance
		|		ON DD.Organization = Balance.Organization
		|			AND DD.ProductionLot = Balance.ProductionLot
		|			AND DD.ProductionOrder = Balance.ProductionOrder
		|			AND DD.RowCodeProducts = Balance.RowCodeProducts
		|WHERE
		|	NOT DD.ProductionOrder = UNDEFINED
		|
		|GROUP BY
		|	DD.Organization,
		|	ISNULL(Balance.Department, VALUE(Catalog.BusinessStructure.EmptyRef)),
		|	DD.ProductionLot,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts
		|
		|UNION ALL
		|
		|SELECT
		|	DD.Organization,
		|	ISNULL(Balance.Department, VALUE(Catalog.BusinessStructure.EmptyRef)),
		|	DD.ProductionLot,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.ByLaborCosts),
		|	SUM(CASE
		|			WHEN ISNULL(Balance.Cost, 0) = 0
		|				THEN ISNULL(Balance.StandardCost, 0)
		|			ELSE Balance.Cost
		|		END),
		|	SUM(CASE
		|			WHEN ISNULL(Balance.Cost, 0) = 0
		|				THEN ISNULL(Balance.StandardCost, 0)
		|			ELSE Balance.Cost
		|		END),
		|	SUM(CASE
		|			WHEN ISNULL(Balance.LocalCost, 0) = 0
		|				THEN ISNULL(Balance.StandardCost, 0)
		|			ELSE Balance.LocalCost
		|		END),
		|	SUM(CASE
		|			WHEN ISNULL(Balance.Cost, 0) = 0
		|				THEN ISNULL(Balance.StandardCost, 0)
		|			ELSE Balance.Cost
		|		END),
		|	SUM(CASE
		|			WHEN ISNULL(Balance.CostOfPersonalIncomeTax, 0) = 0
		|				THEN ISNULL(Balance.StandardCost, 0)
		|			ELSE Balance.CostOfPersonalIncomeTax
		|		END)
		|FROM
		|	RecipientsOfArticleByArticleLaborCosts AS DD
		|		LEFT JOIN TTCashEstimatedBalancesWorkInProgress AS Balance
		|		ON DD.Organization = Balance.Organization
		|		AND DD.ProductionLot = Balance.ProductionLot
		|WHERE
		|	DD.ProductionOrder = UNDEFINED
		|
		|GROUP BY
		|	DD.Organization,
		|	ISNULL(Balance.Department, VALUE(Catalog.BusinessStructure.EmptyRef)),
		|	DD.ProductionLot,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts
		|
		|UNION ALL
		|
		|SELECT
		|	DD.Organization,
		|	VALUE(Catalog.BusinessStructure.EmptyRef),
		|	DD.ProductionLot,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts,
		|	DD.RuleOfCostAllocatingToProductionLots,
		|	SUM(Balance.PlannedProductionQuantity),
		|	SUM(Balance.PlannedProductionQuantity),
		|	SUM(Balance.PlannedProductionQuantity),
		|	SUM(Balance.PlannedProductionQuantity),
		|	SUM(Balance.PlannedProductionQuantity)
		|FROM
		|	ProductionCosts_ AS DD
		|		LEFT JOIN IssuedProducts AS Balance
		|		ON DD.Organization = Balance.Organization
		|			AND DD.ProductionLot = Balance.ProductionLot
		|			AND DD.ProductionOrder = Balance.ProductionOrder
		|			AND DD.RowCodeProducts = Balance.RowCodeProducts
		|WHERE
		|	DD.RuleOfCostAllocatingToProductionLots IN (VALUE(Enum.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases),
		|									VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef))
		|
		|GROUP BY
		|	DD.Organization,
		|	DD.ProductionLot,
		|	DD.ProductionOrder,
		|	DD.RowCodeProducts,
		|	DD.RuleOfCostAllocatingToProductionLots";
	
	QueriesTexts.Add(QueryText);
	CalculationOfCostLocalization.SupplementRequestWithRestOfDistributionBases(QueriesTexts);
	
	QueryText = MergeTexts(QueriesTexts) + "
		|
		|INDEX BY
		|	Organization,
		|	Department,
		|	ProductionLot,
		|	ProductionOrder,
		|	RowCodeProducts,
		|	RuleOfCostAllocatingToProductionLots";
	
	Return QueryText
		+ Common.QueryBatchSeparator();
	
EndFunction
Function TextConversionFactors()
	
	QueryText =
		"SELECT
		|	DD.Organization AS Organization,
		|	DD.ProductionLot,
		|	DD.ProductionOrder,
		|	DD.RuleOfCostAllocatingToProductionLots,
		|	CASE
		|		WHEN SUM(DD.IndicatorOfAllocationToIssue) > 1000000000
		|			THEN 1000000
		|		WHEN SUM(DD.IndicatorOfAllocationToIssue) > 100000000
		|			THEN 100000
		|		WHEN SUM(DD.IndicatorOfAllocationToIssue) > 10000000
		|			THEN 10000
		|		WHEN SUM(DD.IndicatorOfAllocationToIssue) > 1000000
		|			THEN 1000
		|		WHEN SUM(DD.IndicatorOfAllocationToIssue) > 100000
		|			THEN 100
		|		WHEN SUM(DD.IndicatorOfAllocationToIssue) > 10000
		|			THEN 10
		|		ELSE 1
		|	END AS ZoomRatio,
		|	CASE
		|		WHEN SUM(DD.IndicatorOfAttributionToOutputWithoutVAT) > 1000000000
		|			THEN 1000000
		|		WHEN SUM(DD.IndicatorOfAttributionToOutputWithoutVAT) > 100000000
		|			THEN 100000
		|		WHEN SUM(DD.IndicatorOfAttributionToOutputWithoutVAT) > 10000000
		|			THEN 10000
		|		WHEN SUM(DD.IndicatorOfAttributionToOutputWithoutVAT) > 1000000
		|			THEN 1000
		|		WHEN SUM(DD.IndicatorOfAttributionToOutputWithoutVAT) > 100000
		|			THEN 100
		|		WHEN SUM(DD.IndicatorOfAttributionToOutputWithoutVAT) > 10000
		|			THEN 10
		|		ELSE 1
		|	END AS CoefficientWithoutVAT,
		|	CASE
		|		WHEN SUM(DD.LocalIssueAttributionRate) > 1000000000
		|			THEN 1000000
		|		WHEN SUM(DD.LocalIssueAttributionRate) > 100000000
		|			THEN 100000
		|		WHEN SUM(DD.LocalIssueAttributionRate) > 10000000
		|			THEN 10000
		|		WHEN SUM(DD.LocalIssueAttributionRate) > 1000000
		|			THEN 1000
		|		WHEN SUM(DD.LocalIssueAttributionRate) > 100000
		|			THEN 100
		|		WHEN SUM(DD.LocalIssueAttributionRate) > 10000
		|			THEN 10
		|		ELSE 1
		|	END AS LocalCoefficient,
		|	CASE
		|		WHEN SUM(DD.IndicatorOfAssignmentToIssueOfMan) > 1000000000
		|			THEN 1000000
		|		WHEN SUM(DD.IndicatorOfAssignmentToIssueOfMan) > 100000000
		|			THEN 100000
		|		WHEN SUM(DD.IndicatorOfAssignmentToIssueOfMan) > 10000000
		|			THEN 10000
		|		WHEN SUM(DD.IndicatorOfAssignmentToIssueOfMan) > 1000000
		|			THEN 1000
		|		WHEN SUM(DD.IndicatorOfAssignmentToIssueOfMan) > 100000
		|			THEN 100
		|		WHEN SUM(DD.IndicatorOfAssignmentToIssueOfMan) > 10000
		|			THEN 10
		|		ELSE 1
		|	END AS ManSCoefficient,
		|	CASE
		|		WHEN SUM(DD.IndicatorOfAttributionToIssueOfPersonalIncomeTax) > 1000000000
		|			THEN 1000000
		|		WHEN SUM(DD.IndicatorOfAttributionToIssueOfPersonalIncomeTax) > 100000000
		|			THEN 100000
		|		WHEN SUM(DD.IndicatorOfAttributionToIssueOfPersonalIncomeTax) > 10000000
		|			THEN 10000
		|		WHEN SUM(DD.IndicatorOfAttributionToIssueOfPersonalIncomeTax) > 1000000
		|			THEN 1000
		|		WHEN SUM(DD.IndicatorOfAttributionToIssueOfPersonalIncomeTax) > 100000
		|			THEN 100
		|		WHEN SUM(DD.IndicatorOfAttributionToIssueOfPersonalIncomeTax) > 10000
		|			THEN 10
		|		ELSE 1
		|	END AS NDTCoefficient
		|INTO ReductionCoefficients
		|FROM
		|	(SELECT
		|		ProductionCosts_.Organization AS Organization,
		|		ProductionCosts_.ProductionLot AS ProductionLot,
		|		ProductionCosts_.ProductionOrder AS ProductionOrder,
		|		ProductionCosts_.RuleOfCostAllocatingToProductionLots AS RuleOfCostAllocatingToProductionLots,
		|		ProductionCosts_.IndicatorOfAllocationToIssue AS IndicatorOfAllocationToIssue,
		|		ProductionCosts_.IndicatorOfAttributionToOutputWithoutVAT AS IndicatorOfAttributionToOutputWithoutVAT,
		|		ProductionCosts_.LocalIssueAttributionRate AS LocalIssueAttributionRate,
		|		ProductionCosts_.IndicatorOfAssignmentToIssueOfMan AS IndicatorOfAssignmentToIssueOfMan,
		|		ProductionCosts_.IndicatorOfAttributionToIssueOfPersonalIncomeTax AS IndicatorOfAttributionToIssueOfPersonalIncomeTax
		|	FROM
		|		ProductionCosts_ AS ProductionCosts_
		|
		|	UNION ALL
		|	
		|	SELECT
		|		RemnantsOfDistributionBases.Organization,
		|		RemnantsOfDistributionBases.ProductionLot,
		|		RemnantsOfDistributionBases.ProductionOrder,
		|		RemnantsOfDistributionBases.RuleOfCostAllocatingToProductionLots,
		|		RemnantsOfDistributionBases.Balance,
		|		RemnantsOfDistributionBases.BalanceWithoutVAT,
		|		RemnantsOfDistributionBases.RemainderOfLocal,
		|		RemnantsOfDistributionBases.BalanceMan,
		|		RemnantsOfDistributionBases.PersonalIncomeTaxBalance
		|	FROM
		|		RemnantsOfDistributionBases AS RemnantsOfDistributionBases
		|) AS DD
		|
		|GROUP BY
		|	DD.Organization,
		|	DD.ProductionOrder,
		|	DD.ProductionLot,
		|	DD.RuleOfCostAllocatingToProductionLots";
		
	Return QueryText
		+ Common.QueryBatchSeparator();
		
EndFunction

Function TextDescriptionOfDataForReductionFactors() Export
	QueryText = 
		"SELECT
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	VALUE(Catalog.ProductionLots.EmptyRef) AS ProductionLot,
		|	UNDEFINED AS ProductionOrder,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef) AS RuleOfCostAllocatingToProductionLots,
		|	1 AS ZoomRatio,
		|	1 AS CoefficientWithoutVAT,
		|	1 AS LocalCoefficient,
		|	1 AS ManSCoefficient
		|INTO Data
		|";
		
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
	
EndFunction

Function TextDescriptionOfDataForBalancesOfDistributionBases() Export
	QueryText = 
		"SELECT
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	VALUE(Catalog.ProductionLots.EmptyRef) AS ProductionLot,
		|	UNDEFINED AS ProductionOrder,
		|	0 AS RowCodeProducts,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef) AS RuleOfCostAllocatingToProductionLots,
		|	0 AS Balance,
		|	0 AS BalanceWithoutVAT,
		|	0 AS RemainderOfLocal,
		|	0 AS BalanceMan
		|INTO Data
		|";
		
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

// ... data samples

Function TextReceiptsOfOtherExpensesUnfinishedProduction()
	Return "
		|SELECT
		|	""TextReceiptsOfOtherExpensesUnfinishedProduction""                   AS RequestSource,
		|	10                                                  AS Priority,
		|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
		|	TRUE                                              AS CalculationIsCompleted,
		|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
		|	DD.Period                                           AS Period,
		|	DD.Recorder                                      AS Recorder,
		|	DD.Organization                                      AS Organization,
		|	DD.DebitBusinessUnit                                 AS Department,
		|	DD.ProductionLot                               AS ProductionLot,
		|	PartiesInSummary.ReleaseLotDimension                 AS ReleaseLotDimension,
		|	DD.ProductionOrder                              AS ProductionOrder,
		|	DD.RowCodeProducts                               AS RowCodeProducts,
		|	DD.CorLineOfBusiness						AS LineOfBusiness,
		|	UNDEFINED                                        AS BillOfMaterials,
		|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
		|	DD.ProductCostElement                                AS ProductCostElement,
		|	DD.ExpenseItem                                   AS ExpenseItem,
		|	DD.DimensionOfExpenses                                AS DimensionOfExpenses,
		|	DD.ProductsGroup                                  AS ProductsGroup,
		|	DD.RuleOfCostAllocatingToProductionLots                         AS RuleOfCostAllocatingToProductionLots,
		|	UNDEFINED                                        AS ProductsAccountingDimension,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	DD.LineOfBusiness							AS CorLineOfBusiness,
		|	0                                                   AS Denominator,
		|	0                                                   AS ProductsQuantity,
		|	0                                                   AS CostShare,
		|	0                                                   AS Cost,
		|	0                                                   AS CostExcludingVAT,
		|	0                                                   AS LocalCost,
		|	0                                                   AS PermanentDifference,
		|	0                                                   AS CostTD,
		|	0				 									AS CostOfPersonalIncomeTax,
		|	0													AS IndicatorOfAllocationToIssue,
		|	0													AS IndicatorOfAttributionToOutputWithoutVAT,
		|	0													AS LocalIssueAttributionRate,
		|	0													AS IndicatorOfAttributionToIssueIsTA,
		|	0													AS IndicatorOfAssignmentToIssueOfMan,
		|	0													AS IndicatorOfAttributionToIssueOfPersonalIncomeTax,
		|	DD.CostShare									AS IndicatorOfAllocationToLot,
		|	DD.ShareOfValueWithoutVAT								AS IndicatorOfAllocationToLotExcludingVAT,
		|	DD.ShareOfLocalValue								AS IndicatorOfAllocationToLotCompl,
		|	DD.ShareValueTa									AS RateOfAssignmentToBatchIsTA,
		|	DD.ShareOfManSCost									AS IndicatorOfAllocationToLotManag,
		|	CASE
		|		WHEN PartiesInSummary.AITExpensesAreIncludedInCost
		|			THEN DD.ShareOfCostOfPersonalIncomeTax
		|		ELSE 0
		|	END												AS IndicatorOfAttributionToPartyNDD,
		|	TRUE                                              AS Primary,
		|	UNDEFINED                                        AS BusinessOperation,
		|	UNDEFINED                                        AS AccountingSection,
		|	UNDEFINED                                        AS InventoryOwnerAttribute,
		|	UNDEFINED                                        AS VATActivityType,
		|	UNDEFINED                                        AS DocumentRegisterRecords,
		|	UNDEFINED                                        AS Purpose,
		|	UNDEFINED                                        AS DocumentSource,
		|	PartiesInSummary.DocumentOfProductionIssue                        AS DocumentOfProductionIssue,
		|	UNDEFINED                                        AS ManufacturedProduct,
		|	UNDEFINED                                        AS ItemVariant
		|FROM
		|	SharesOfProductionCosts AS DD
		|	LEFT JOIN LotsForAttributingExpenses AS PartiesInSummary
		|		ON PartiesInSummary.Organization = DD.Organization
		|		AND PartiesInSummary.Department = DD.DebitBusinessUnit
		|		AND PartiesInSummary.ProductionLot = DD.ProductionLot
		|		AND PartiesInSummary.ProductionOrder = DD.ProductionOrder
		|		AND PartiesInSummary.RowCodeProducts = DD.RowCodeProducts
		|		AND PartiesInSummary.ProductCostElement = DD.ProductCostElement
		|		AND PartiesInSummary.ExpenseItem = DD.ExpenseItem
		|		AND PartiesInSummary.DimensionOfExpenses = DD.DimensionOfExpenses
		|		AND PartiesInSummary.ProductsGroup = DD.ProductsGroup
		|		AND PartiesInSummary.RuleOfCostAllocatingToProductionLots = DD.RuleOfCostAllocatingToProductionLots
		|		AND PartiesInSummary.LineOfBusiness = DD.CorLineOfBusiness
		|WHERE
		|	DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots)
		|";
EndFunction

Function TextReceiptsOfOtherExpensesOfUnfinishedProductionOnCostOfProduction()
	Return "
		|SELECT
		|	""TextReceiptsOfOtherExpensesOfUnfinishedProductionOnCostOfProduction"" AS RequestSource,
		|	10                                                  AS Priority,
		|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
		|	TRUE                                              AS CalculationIsCompleted,
		|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
		|	DD.Period                                           AS Period,
		|	DD.Recorder                                      AS Recorder,
		|	DD.Organization                                      AS Organization,
		|	DD.DebitBusinessUnit                                 AS Department,
		|	DD.ProductionLot                               AS ProductionLot,
		|	PartiesInSummary.ReleaseLotDimension                 AS ReleaseLotDimension,
		|	DD.ProductionOrder                              AS ProductionOrder,
		|	DD.RowCodeProducts                               AS RowCodeProducts,
		|	DD.CorLineOfBusiness						AS LineOfBusiness,
		|	UNDEFINED                                        AS BillOfMaterials,
		|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
		|	DD.ProductCostElement                                AS ProductCostElement,
		|	DD.ExpenseItem                                   AS ExpenseItem,
		|	DD.DimensionOfExpenses                                AS DimensionOfExpenses,
		|	DD.ProductsGroup                                  AS ProductsGroup,
		|	DD.RuleOfCostAllocatingToProductionLots                         AS RuleOfCostAllocatingToProductionLots,
		|	UNDEFINED                                        AS ProductsAccountingDimension,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	DD.LineOfBusiness							AS CorLineOfBusiness,
		|	0                                                   AS Denominator,
		|	0                                                   AS ProductsQuantity,
		|	0                                                   AS CostShare,
		|	0                                                   AS Cost,
		|	0                                                   AS CostExcludingVAT,
		|	0                                                   AS LocalCost,
		|	0                                                   AS PermanentDifference,
		|	0                                                   AS CostTD,
		|	0													AS CostOfPersonalIncomeTax,
		|	0													AS IndicatorOfAllocationToIssue,
		|	0													AS IndicatorOfAttributionToOutputWithoutVAT,
		|	0													AS LocalIssueAttributionRate,
		|	0													AS IndicatorOfAttributionToIssueIsTA,
		|	0													AS IndicatorOfAssignmentToIssueOfMan,
		|	0													AS IndicatorOfAttributionToIssueOfPersonalIncomeTax,
		|	DD.CostShare									AS IndicatorOfAllocationToLot,
		|	DD.ShareOfValueWithoutVAT								AS IndicatorOfAllocationToLotExcludingVAT,
		|	DD.ShareOfLocalValue								AS IndicatorOfAllocationToLotCompl,
		|	DD.ShareValueTa									AS RateOfAssignmentToBatchIsTA,
		|	DD.ShareOfManSCost									AS IndicatorOfAllocationToLotManag,
		|	CASE
		|		WHEN PartiesInSummary.AITExpensesAreIncludedInCost
		|			THEN DD.ShareOfLocalValue
		|		ELSE 0
		|	END												AS IndicatorOfAttributionToPartyNDD,
		|	TRUE                                              AS Primary,
		|	UNDEFINED                                        AS BusinessOperation,
		|	UNDEFINED                                        AS AccountingSection,
		|	UNDEFINED                                        AS InventoryOwnerAttribute,
		|	UNDEFINED                                        AS VATActivityType,
		|	UNDEFINED                                        AS DocumentRegisterRecords,
		|	UNDEFINED                                        AS Purpose,
		|	UNDEFINED                                        AS DocumentSource,
		|	PartiesInSummary.DocumentOfProductionIssue                        AS DocumentOfProductionIssue,
		|	UNDEFINED                                        AS ManufacturedProduct,
		|	UNDEFINED                                        AS ItemVariant
		|FROM
		|	DirectProductionCosts AS DD
		|	LEFT JOIN LotsForAttributingExpenses AS PartiesInSummary
		|		ON PartiesInSummary.Organization = DD.Organization
		|		AND PartiesInSummary.Department = DD.DebitBusinessUnit
		|		AND PartiesInSummary.ProductionLot = DD.ProductionLot
		|		AND PartiesInSummary.ProductionOrder = DD.ProductionOrder
		|		AND PartiesInSummary.RowCodeProducts = DD.RowCodeProducts
		|		AND PartiesInSummary.ProductCostElement = DD.ProductCostElement
		|		AND PartiesInSummary.ExpenseItem = DD.ExpenseItem
		|		AND PartiesInSummary.DimensionOfExpenses = DD.DimensionOfExpenses
		|		AND PartiesInSummary.ProductsGroup = DD.ProductsGroup
		|		AND PartiesInSummary.RuleOfCostAllocatingToProductionLots = DD.RuleOfCostAllocatingToProductionLots
		|";
EndFunction

Function TextExpensesOtherExpensesUnfinishedProductionOnMaterials() // Uses the party for the allocation of expenses, material costs of production, the remainder of the expenses, the work of the customer
	Return "
	|SELECT
	|	""TextExpensesOtherExpensesUnfinishedProductionOnMaterials""       AS RequestSource,
	|	10                                                  AS Priority,
	|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
	|	TRUE                                              AS CalculationIsCompleted,
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	Material_.ProductionDate                       AS Period,
	|	Material_.ExpenseLogger                     AS Recorder,
	|	DD.Organization                                      AS Organization,
	|	DD.Department                                    AS Department,
	|	DD.ProductionLot                               AS ProductionLot,
	|	DD.ReleaseLotDimension                           AS ReleaseLotDimension,
	|	DD.ProductionOrder                              AS ProductionOrder,
	|	DD.RowCodeProducts                               AS RowCodeProducts,
	|	DD.LineOfBusiness                          AS LineOfBusiness,
	|	UNDEFINED                                        AS BillOfMaterials,
	|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
	|	DD.ProductCostElement                                AS ProductCostElement,
	|	DD.ExpenseItem                                   AS ExpenseItem,
	|	DD.DimensionOfExpenses                                AS DimensionOfExpenses,
	|	DD.ProductsGroup                                  AS ProductsGroup,
	|	DD.RuleOfCostAllocatingToProductionLots                         AS RuleOfCostAllocatingToProductionLots,
	|	CASE
	|		WHEN TRUE
	|			THEN Material_.CorItemsLocationAttributes
	|	END                                               AS ProductsAccountingDimension,
	|	Material_.LotVendorAttributesCorr                AS LotVendorAttributesCorr,
	|	DD.LineOfBusiness                          AS CorLineOfBusiness,
	|	0                                                   AS Denominator,
	|	0                                                   AS ProductsQuantity,
	|	0                                                   AS CostShare,
	|	0                                                   AS Cost,
	|	0                                                   AS CostExcludingVAT,
	|	0                                                   AS LocalCost,
	|	0                                                   AS PermanentDifference,
	|	0                                                   AS CostTD,
	|	0													AS CostOfPersonalIncomeTax,
	// We calculate the index of allocation to output for expenditure items by any distribution option,
	// because it is necessary to distribute all the amounts previously allocated to production batches to the output.
	|	CAST(Material_.Cost / ISNULL(Coefficients.ZoomRatio, 1) AS NUMBER (23, 10)) AS IndicatorOfAllocationToIssue,
	|	CAST(Material_.CostExcludingVAT / ISNULL(Coefficients.CoefficientWithoutVAT, 1) AS NUMBER (23, 10)) AS IndicatorOfAttributionToOutputWithoutVAT,
	|	CAST(Material_.LocalCost / ISNULL(Coefficients.LocalCoefficient, 1) AS NUMBER (23, 10)) AS LocalIssueAttributionRate,
	|	CAST(Material_.LocalCost / ISNULL(Coefficients.LocalCoefficient, 1) AS NUMBER (23, 10)) AS IndicatorOfAttributionToIssueIsTA,
	|	CAST(Material_.CostMan / ISNULL(Coefficients.ManSCoefficient, 1) AS NUMBER (23, 10)) AS IndicatorOfAssignmentToIssueOfMan,
	// AIT distribution is performed on the basis of regulated accounting.
	|	CASE
	|		WHEN NOT DD.AITExpensesAreIncludedInCost
	|			THEN 0
	|		ELSE
	|			CAST(Material_.LocalCost / ISNULL(Coefficients.LocalCoefficient, 1) AS NUMBER (23, 10))
	|	END AS IndicatorOfAttributionToIssueOfPersonalIncomeTax,
	|	0                                                   AS IndicatorOfAllocationToLot,
	|	0                                                   AS IndicatorOfAllocationToLotExcludingVAT,
	|	0                                                   AS IndicatorOfAllocationToLotCompl,
	|	0                                                   AS RateOfAssignmentToBatchIsTA,
	|	0                                                   AS IndicatorOfAllocationToLotManag,
	|	0                                                   AS IndicatorOfAttributionToPartyNDD,
	|	TRUE                                              AS Primary,
	|	UNDEFINED                                        AS BusinessOperation,
	|	CASE
	|		WHEN TRUE
	|			THEN Material_.CorAccountingSection
	|	END                                               AS AccountingSection,
	|	CASE
	|		WHEN TRUE
	|			THEN Material_.CorInventoryOwnerAttribute
	|	END                                               AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN UNDEFINED
	|		ELSE
	|			ISNULL(
	|				CAST(DD.ReleaseLotDimension AS Catalog.InventoryLocationAttributeKeys).Purpose.VATActivityType, UNDEFINED)
	|	END 												AS VATActivityType,
	|	UNDEFINED                                        AS DocumentRegisterRecords,
	|	UNDEFINED                                        AS Purpose,
	|	UNDEFINED                                        AS DocumentSource,
	|	DD.DocumentOfProductionIssue                                  AS DocumentOfProductionIssue,
	|	UNDEFINED                                        AS ManufacturedProduct,
	|	UNDEFINED                                        AS ItemVariant
	|FROM
	|	LotsForAttributingExpenses AS DD
	// expense for each issue analytics
	|	INNER JOIN MaterialCostsOfProduction AS Material_
	|		ON DD.Organization = Material_.Organization
	|		AND Material_.Department = DD.Department
	|		AND Material_.ProductionLot = DD.ProductionLot
	|		AND Material_.ProductionOrder = DD.ProductionOrder
	|		AND Material_.RowCodeProducts = DD.RowCodeProducts
	|
	|	LEFT JOIN ReductionCoefficients AS Coefficients
	|		ON Coefficients.Organization = DD.Organization
	|		AND Coefficients.ProductionLot = DD.ProductionLot
	|		AND Coefficients.ProductionOrder = DD.ProductionOrder
	|		AND Coefficients.RuleOfCostAllocatingToProductionLots = DD.RuleOfCostAllocatingToProductionLots
	|WHERE
	|	DD.RuleOfCostAllocatingToProductionLots = VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts)
	|";
EndFunction

Function TextExpensesOtherExpensesUnfinishedProductionOnLaborCosts() // Uses the part for the allocation of expenses, labor costs of production, the remainder of the input costs, the work of the customer
	Return "
	|SELECT
	|	""TextExpensesOtherExpensesUnfinishedProductionOnLaborCosts""    AS RequestSource,
	|	10                                                  AS Priority,
	|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
	|	TRUE                                              AS CalculationIsCompleted,
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	LaborCosts.ProductionDate                       AS Period,
	|	LaborCosts.ExpenseLogger                     AS Recorder,
	|	DD.Organization                                      AS Organization,
	|	DD.Department                                    AS Department,
	|	DD.ProductionLot                               AS ProductionLot,
	|	DD.ReleaseLotDimension                           AS ReleaseLotDimension,
	|	DD.ProductionOrder                              AS ProductionOrder,
	|	DD.RowCodeProducts                               AS RowCodeProducts,
	|	DD.LineOfBusiness                          AS LineOfBusiness,
	|	UNDEFINED                                        AS BillOfMaterials,
	|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
	|	DD.ProductCostElement                                AS ProductCostElement,
	|	DD.ExpenseItem                                   AS ExpenseItem,
	|	DD.DimensionOfExpenses                                AS DimensionOfExpenses,
	|	DD.ProductsGroup                                  AS ProductsGroup,
	|	DD.RuleOfCostAllocatingToProductionLots                         AS RuleOfCostAllocatingToProductionLots,
	|	CASE
	|		WHEN TRUE
	|			THEN LaborCosts.CorItemsLocationAttributes
	|	END                                               AS ProductsAccountingDimension,
	|	LaborCosts.LotVendorAttributesCorr                AS LotVendorAttributesCorr,
	|	DD.LineOfBusiness                          AS CorLineOfBusiness,
	|	0                                                   AS Denominator,
	|	0                                                   AS ProductsQuantity,
	|	0                                                   AS CostShare,
	|	0                                                   AS Cost,
	|	0                                                   AS CostExcludingVAT,
	|	0                                                   AS LocalCost,
	|	0                                                   AS PermanentDifference,
	|	0                                                   AS CostTD,
	|	0													AS CostOfPersonalIncomeTax,
	// We calculate the index of allocation to output for expenditure items by any distribution option,
	// because it is necessary to distribute all the amounts previously allocated to production batches to the output.
	|	CAST(LaborCosts.Cost / ISNULL(Coefficients.ZoomRatio, 1) AS NUMBER (23, 10)) AS IndicatorOfAllocationToIssue,
	|	CAST(LaborCosts.CostExcludingVAT / ISNULL(Coefficients.CoefficientWithoutVAT, 1) AS NUMBER (23, 10)) AS IndicatorOfAttributionToOutputWithoutVAT,
	|	CAST(LaborCosts.LocalCost / ISNULL(Coefficients.LocalCoefficient, 1) AS NUMBER (23, 10)) AS LocalIssueAttributionRate,
	|	CAST(LaborCosts.LocalCost / ISNULL(Coefficients.LocalCoefficient, 1) AS NUMBER (23, 10)) AS IndicatorOfAttributionToIssueIsTA,
	|	CAST(LaborCosts.CostMan / ISNULL(Coefficients.ManSCoefficient, 1) AS NUMBER (23, 10)) AS IndicatorOfAssignmentToIssueOfMan,
	// AIT distribution is performed on the basis of regulated accounting.
	|	CASE 
	|		WHEN NOT DD.AITExpensesAreIncludedInCost
	|			THEN 0
	|		ELSE
	|			CAST(LaborCosts.LocalCost / ISNULL(Coefficients.LocalCoefficient, 1) AS NUMBER (23, 10))
	|	END AS IndicatorOfAttributionToIssueOfPersonalIncomeTax,
	|	0                                                   AS IndicatorOfAllocationToLot,
	|	0                                                   AS IndicatorOfAllocationToLotExcludingVAT,
	|	0                                                   AS IndicatorOfAllocationToLotCompl,
	|	0                                                   AS RateOfAssignmentToBatchIsTA,
	|	0                                                   AS IndicatorOfAllocationToLotManag,
	|	0                                                   AS IndicatorOfAttributionToPartyNDD,
	|	TRUE                                              AS Primary,
	|	UNDEFINED                                        AS BusinessOperation,
	|	CASE
	|		WHEN TRUE
	|			THEN LaborCosts.CorAccountingSection
	|	END                                               AS AccountingSection,
	|	CASE
	|		WHEN TRUE
	|			THEN LaborCosts.CorInventoryOwnerAttribute
	|	END                                               AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN UNDEFINED
	|		ELSE
	|			ISNULL(
	|				CAST(DD.ReleaseLotDimension AS Catalog.InventoryLocationAttributeKeys).Purpose.VATActivityType, UNDEFINED)
	|	END                                               AS VATActivityType,
	|	UNDEFINED                                        AS DocumentRegisterRecords,
	|	UNDEFINED                                        AS Purpose,
	|	UNDEFINED                                        AS DocumentSource,
	|	DD.DocumentOfProductionIssue                                  AS DocumentOfProductionIssue,
	|	UNDEFINED                                        AS ManufacturedProduct,
	|	UNDEFINED                                        AS ItemVariant
	|FROM
	|	LotsForAttributingExpenses AS DD
	// expense for each issue analytics
	|	INNER JOIN LaborCostsOfProduction AS LaborCosts
	|		ON LaborCosts.Organization = DD.Organization
	|		AND LaborCosts.Department = DD.Department
	|		AND LaborCosts.ProductionLot = DD.ProductionLot
	|		AND LaborCosts.ProductionOrder = DD.ProductionOrder
	|		AND LaborCosts.RowCodeProducts = DD.RowCodeProducts
	|	LEFT JOIN ReductionCoefficients AS Coefficients
	|		ON Coefficients.Organization = DD.Organization
	|		AND Coefficients.ProductionLot = DD.ProductionLot
	|		AND Coefficients.ProductionOrder = DD.ProductionOrder
	|		AND Coefficients.RuleOfCostAllocatingToProductionLots = DD.RuleOfCostAllocatingToProductionLots
	|WHERE
	|	DD.RuleOfCostAllocatingToProductionLots = VALUE(Enum.RulesOfCostAllocationToProductCost.ByLaborCosts)
	|";
EndFunction

Function TextExpensesOfOtherExpensesOfUnfinishedProductionOnMaterialAndLaborCosts() // Uses the party for the allocation of expenses, material labor costs of production, the remainder of the expenses, the work of the customer
	Return "
	|SELECT
	|	""TextExpensesOfOtherExpensesOfUnfinishedProductionOnMaterialAndLaborCosts"" AS RequestSource,
	|	10                                                  AS Priority,
	|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
	|	TRUE                                              AS CalculationIsCompleted,
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	Costs.ProductionDate                            AS Period,
	|	Costs.ExpenseLogger                          AS Recorder,
	|	DD.Organization                                      AS Organization,
	|	DD.Department                                    AS Department,
	|	DD.ProductionLot                               AS ProductionLot,
	|	DD.ReleaseLotDimension                           AS ReleaseLotDimension,
	|	DD.ProductionOrder                              AS ProductionOrder,
	|	DD.RowCodeProducts                               AS RowCodeProducts,
	|	DD.LineOfBusiness                          AS LineOfBusiness,
	|	UNDEFINED                                        AS BillOfMaterials,
	|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
	|	DD.ProductCostElement                                AS ProductCostElement,
	|	DD.ExpenseItem                                   AS ExpenseItem,
	|	DD.DimensionOfExpenses                                AS DimensionOfExpenses,
	|	DD.ProductsGroup                                  AS ProductsGroup,
	|	DD.RuleOfCostAllocatingToProductionLots                         AS RuleOfCostAllocatingToProductionLots,
	|	CASE
	|		WHEN TRUE
	|			THEN Costs.CorItemsLocationAttributes
	|	END                                               AS ProductsAccountingDimension,
	|	Costs.LotVendorAttributesCorr                     AS LotVendorAttributesCorr,
	|	DD.LineOfBusiness                          AS CorLineOfBusiness,
	|	0                                                   AS Denominator,
	|	0                                                   AS ProductsQuantity,
	|	0                                                   AS CostShare,
	|	0                                                   AS Cost,
	|	0                                                   AS CostExcludingVAT,
	|	0                                                   AS LocalCost,
	|	0                                                   AS PermanentDifference,
	|	0                                                   AS CostTD,
	|	0													AS CostOfPersonalIncomeTax,
	// We calculate the index of allocation to output for expenditure items by any distribution option,
	// because it is necessary to distribute all the amounts previously allocated to production batches to the output.
	|	CAST(Costs.Cost / ISNULL(Coefficients.ZoomRatio, 1) AS NUMBER (23, 10)) AS IndicatorOfAllocationToIssue,
	|	CAST(Costs.CostExcludingVAT / ISNULL(Coefficients.CoefficientWithoutVAT, 1) AS NUMBER (23, 10)) AS IndicatorOfAttributionToOutputWithoutVAT,
	|	CAST(Costs.LocalCost / ISNULL(Coefficients.LocalCoefficient, 1) AS NUMBER (23, 10)) AS LocalIssueAttributionRate,
	|	CAST(Costs.LocalCost / ISNULL(Coefficients.LocalCoefficient, 1) AS NUMBER (23, 10)) AS IndicatorOfAttributionToIssueIsTA,
	|	CAST(Costs.CostMan / ISNULL(Coefficients.ManSCoefficient, 1) AS NUMBER (23, 10)) AS IndicatorOfAssignmentToIssueOfMan,
	// AIT distribution is performed on the basis of regulated accounting.
	|	CASE 
	|		WHEN NOT DD.AITExpensesAreIncludedInCost
	|			THEN 0
	|		ELSE
	|			CAST(Costs.LocalCost / ISNULL(Coefficients.LocalCoefficient, 1) AS NUMBER (23, 10))
	|	END AS IndicatorOfAttributionToIssueOfPersonalIncomeTax,
	|	0                                                   AS IndicatorOfAllocationToLot,
	|	0                                                   AS IndicatorOfAllocationToLotExcludingVAT,
	|	0                                                   AS IndicatorOfAllocationToLotCompl,
	|	0                                                   AS RateOfAssignmentToBatchIsTA,
	|	0                                                   AS IndicatorOfAllocationToLotManag,
	|	0                                                   AS IndicatorOfAttributionToPartyNDD,
	|	TRUE                                              AS Primary,
	|	UNDEFINED                                        AS BusinessOperation,
	|	CASE
	|		WHEN TRUE
	|			THEN Costs.CorAccountingSection
	|	END                                               AS AccountingSection,
	|	CASE
	|		WHEN TRUE
	|			THEN Costs.CorInventoryOwnerAttribute
	|	END                                               AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN UNDEFINED
	|		ELSE
	|			ISNULL(
	|				CAST(DD.ReleaseLotDimension AS Catalog.InventoryLocationAttributeKeys).Purpose.VATActivityType, UNDEFINED)
	|	END 												AS VATActivityType,
	|	UNDEFINED                                        AS DocumentRegisterRecords,
	|	UNDEFINED                                        AS Purpose,
	|	UNDEFINED                                        AS DocumentSource,
	|	DD.DocumentOfProductionIssue                                  AS DocumentOfProductionIssue,
	|	UNDEFINED                                        AS ManufacturedProduct,
	|	UNDEFINED                                        AS ItemVariant
	|FROM
	|	LotsForAttributingExpenses AS DD
	// expense for each issue analytics
	|	INNER JOIN MaterialAndLaborCostsOfProduction AS Costs
	|		ON DD.Organization = Costs.Organization
	|		AND Costs.Department = DD.Department
	|		AND Costs.ProductionLot = DD.ProductionLot
	|		AND Costs.ProductionOrder = DD.ProductionOrder
	|		AND Costs.RowCodeProducts = DD.RowCodeProducts
	|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
	|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
	|	LEFT JOIN TTCostCalculationRecorders AS CalculationLoggers
	|	ON CalculationLoggers.Organization = DD.Organization
	|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	LEFT JOIN ReductionCoefficients AS Coefficients
	|		ON Coefficients.Organization = DD.Organization
	|		AND Coefficients.ProductionLot = DD.ProductionLot
	|		AND Coefficients.ProductionOrder = DD.ProductionOrder
	|		AND Coefficients.RuleOfCostAllocatingToProductionLots = DD.RuleOfCostAllocatingToProductionLots
	|WHERE
	|	DD.RuleOfCostAllocatingToProductionLots = VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts)
	|";
EndFunction

Function TextExpensesOtherExpensesUnfinishedProductionOnProducts() // Uses the partyreferences of expenditures, released products, worksreferences
	Return "
			|SELECT
			|	""TextExpensesOtherExpensesUnfinishedProductionOnProducts""        AS RequestSource,
			|	10                                                  AS Priority,
			|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
			|	TRUE                                              AS CalculationIsCompleted,
			|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
			|	ManufacturedProduct.ProductionDate                          AS Period,
			|	ISNULL(CalculationLoggers.Ref, ManufacturedProduct.ExpenseLogger) AS Recorder,
			|	DD.Organization                                      AS Organization,
			|	DD.Department                                    AS Department,
			|	DD.ProductionLot                               AS ProductionLot,
			|	DD.ReleaseLotDimension                           AS ReleaseLotDimension,
			|	DD.ProductionOrder                              AS ProductionOrder,
			|	DD.RowCodeProducts                               AS RowCodeProducts,
			|	DD.LineOfBusiness                          AS LineOfBusiness,
			|	UNDEFINED                                        AS BillOfMaterials,
			|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
			|	DD.ProductCostElement                                AS ProductCostElement,
			|	DD.ExpenseItem                                   AS ExpenseItem,
			|	DD.DimensionOfExpenses                                AS DimensionOfExpenses,
			|	DD.ProductsGroup                                  AS ProductsGroup,
			|	DD.RuleOfCostAllocatingToProductionLots                         AS RuleOfCostAllocatingToProductionLots,
			|	CASE
			|		WHEN TRUE
			|			THEN ManufacturedProduct.CorItemsLocationAttributes
			|	END                                               AS ProductsAccountingDimension,
			|	CASE
			|		WHEN TRUE
			|			THEN ManufacturedProduct.LotVendorAttributesCorr
			|	END                                               AS LotVendorAttributesCorr,
			|	DD.LineOfBusiness							AS CorLineOfBusiness,
			|	0                                                   AS Denominator,
			|	0                                                   AS ProductsQuantity,
			|	0                                                   AS CostShare,
			|	0                                                   AS Cost,
			|	0                                                   AS CostExcludingVAT,
			|	0                                                   AS LocalCost,
			|	0                                                   AS PermanentDifference,
			|	0                                                   AS CostTD,
			|	0													AS CostOfPersonalIncomeTax,
			// We calculate the index of allocation to output for expenditure items by any distribution option,
			// because it is necessary to distribute all the amounts previously allocated to production batches to the output.
			|	CAST(ManufacturedProduct.Cost / ISNULL(Coefficients.ZoomRatio, 1) AS NUMBER (23, 10)) AS IndicatorOfAllocationToIssue,
			|	CAST(ManufacturedProduct.Cost / ISNULL(Coefficients.ZoomRatio, 1) AS NUMBER (23, 10)) AS IndicatorOfAttributionToOutputWithoutVAT,
			|	CAST(ManufacturedProduct.Cost / ISNULL(Coefficients.ZoomRatio, 1) AS NUMBER (23, 10)) AS LocalIssueAttributionRate,
			|	CAST(ManufacturedProduct.Cost / ISNULL(Coefficients.ZoomRatio, 1) AS NUMBER (23, 10)) AS IndicatorOfAttributionToIssueIsTA,
			|	CAST(ManufacturedProduct.Cost / ISNULL(Coefficients.ZoomRatio, 1) AS NUMBER (23, 10)) AS IndicatorOfAssignmentToIssueOfMan,
			// AIT distribution is performed on the basis of regulated accounting.
			|	CASE 
			|		WHEN NOT DD.AITExpensesAreIncludedInCost
			|			THEN 0
			|		ELSE CAST(ManufacturedProduct.Cost / ISNULL(Coefficients.ZoomRatio, 1) AS NUMBER (23, 10))
			|	END												AS IndicatorOfAttributionToIssueOfPersonalIncomeTax,
			|	0                                                   AS IndicatorOfAllocationToLot,
			|	0                                                   AS IndicatorOfAllocationToLotExcludingVAT,
			|	0                                                   AS IndicatorOfAllocationToLotCompl,
			|	0                                                   AS RateOfAssignmentToBatchIsTA,
			|	0                                                   AS IndicatorOfAllocationToLotManag,
			|	0                                                   AS IndicatorOfAttributionToPartyNDD,
			|	TRUE                                              AS Primary,
			|	UNDEFINED                                        AS BusinessOperation,
			|	CASE
			|		WHEN TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
			|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
			|		ELSE ManufacturedProduct.CorAccountingSection
			|	END                                               AS AccountingSection,
			|	CASE
			|		WHEN TRUE
			|			THEN ManufacturedProduct.CorInventoryOwnerAttribute
			|	END                                               AS InventoryOwnerAttribute,
			|	CASE
			|		WHEN &KeepRecordsOfInventoryCostByAssignments
			|			THEN UNDEFINED
			|		ELSE
			|			ISNULL(
			|				CAST(DD.ReleaseLotDimension AS Catalog.InventoryLocationAttributeKeys).Purpose.VATActivityType, UNDEFINED)
			|	END 												AS VATActivityType,
			|	UNDEFINED                                        AS DocumentRegisterRecords,
			|	UNDEFINED                                        AS Purpose,
			|	UNDEFINED                                        AS DocumentSource,
			|	DD.DocumentOfProductionIssue                                  AS DocumentOfProductionIssue,
			|	UNDEFINED                                        AS ManufacturedProduct,
			|	UNDEFINED                                        AS ItemVariant
			|FROM
			|	LotsForAttributingExpenses AS DD
			|	INNER JOIN IssuedProducts AS ManufacturedProduct
			|		ON ManufacturedProduct.Organization = DD.Organization
			|		AND ManufacturedProduct.ProductionLot = DD.ProductionLot
			|		AND ManufacturedProduct.ProductionOrder = DD.ProductionOrder
			|		AND ManufacturedProduct.RowCodeProducts = DD.RowCodeProducts
			|		AND CASE
			|			WHEN ManufacturedProduct.RowCodeProducts > 0
			|				THEN ManufacturedProduct.Department = DD.Department
			|			ELSE
			|				TRUE
			|		END
			|
			|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
			|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
			|
			|	LEFT JOIN TTCostCalculationRecorders AS CalculationLoggers
			|	ON CalculationLoggers.Organization = DD.Organization
			|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
			|	LEFT JOIN ReductionCoefficients AS Coefficients
			|		ON Coefficients.Organization = DD.Organization
			|		AND Coefficients.ProductionLot = DD.ProductionLot
			|		AND Coefficients.ProductionOrder = DD.ProductionOrder
			|		AND Coefficients.RuleOfCostAllocatingToProductionLots = DD.RuleOfCostAllocatingToProductionLots
			|
			|WHERE
			|	DD.RuleOfCostAllocatingToProductionLots IN (VALUE(Enum.RulesOfCostAllocationToProductCost.ByProducts),
			|									VALUE(Enum.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases))
			|	AND ManufacturedProduct.ProductionDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
			|";
EndFunction

#EndRegion

#Region ProceduresOfStage18_DistributionToSales

#Region Description_DistributionForSales

// The stage of distribution of sales expenses will perform the distribution of a fixed amount of expenses for the cost of the shelf
// resources "Sales expenses" in the accumulation register "Revenue and cost of sales".

// The full text of the request is generated in the function textquestiondistribution of sales expenses().
// The initial data for distribution are the Balances of the "Other expenses" register - the temporary table of the cash settlement statistics of sales expenses.
// The following temporary tables are formed to select the distribution base:
// - Second Sale to a partner - expenses with the "Partner" type of analytics
// - Second Sale Order - expenses with the types of analytics documents "Report of completed works", "Sale of goods and services",
// 		"Report to the giver (2.5)" and "Customer order" in the Status "Under approval" if the order is used as an invoice.
// - Second Sale of sales of the past periods - expenses with the types of analytics documents "Act of completed works",
// 		"Sale of goods and services" and "Customer order" in the Status "Not agreed", if the date of the document refers to the previous period.
// - Second Sale sale - expenses with the type of analytics "Transactions with customers"
// - Non-filled-in analysis of expenses - expenses with unfilled analytics
//
// The distribution base is formed in the function of the text request for the distribution of sales expenses().
// The data of the Cur period are selected from the temporary table of the cash settlement turnaround hand and the value of sales
// with selection according to the temporary tables of the second sale by partner, Second Sale by order, Second Sale by sale, and the unfilled analysis of the costs
// The data of the previous period are selected from the movements of the Accumulation register "Revenue and cost of sales"
// with selection according to the temporary table of the second round of sales sales of the past periods.
//
// The distribution base is stored in the following temporary taboits:
// - vtbasdistributionsold data - detailed records of the distribution database
// - vtbasdistributionsprovided - grouped records of the distribution database
// - VTBAZAREALLOCATION of sales Sums - totals of the distribution base for each cost analysis, organization and line of business
// - VTBAZARASDISTRIBUTIONSALES - the final table of the distribution base with distribution shares
//		is formed according to the tables vtbazarasdistributionsold and vtbazarasdistributionsold sums.
//		The shares for distribution are calculated using the formulas:
//		- Revenue share = Revenue / Total revenue - separately for Man and Local accounting
//		- Share quantity = Quantity / The total number
//		- Share cost = Cost / The final cost price is separately for Man and Local accounting
//		- Share weight = Weight / Total weight
//		- Share of objectm = Objectm / Total volume
//
// The distribution base for expenses on customer orders is formed in the function of the text request for the allocation of spending on orders().
// To select the distribution base, a temporary table is formed for the selection of the customer's order.
// The distribution base is stored in the following temporary taboits:
// - In-order Planfactual data - detailed planned and actual data on customer orders. It is formed according to the movements 
//		of the Accumulation register "Customer orders".
// - VtPlanFactPoZakazu - planned and actual data grouped by orders
// - VtDoliPoZakazu - shares of distribution. The following formulas are generated according to the data of the temporary tables in the order and in the Actual order
//		according to the following formulas:
//		- Share quantity = Quantity Fact / Quantity Plan
//		- Share weight = Weight fact / Weight plan
//		- Share volume = Volume Fact / Volume Plan
//		- Share Amount = Fact Amount / Plan Amount
// - VTBASDISTRIBUTION of the client's order - the final base of distribution with distribution shares
//		The shares for distribution are calculated using the formulas:
//		- Revenue share = (Revenue / Order amount) * Share amount
//		- Share quantity = (Quantity / Quantity per order) * Share quantity
//		- Share weight = (Quantity / Quantity on order) * Proportion of weight
//		- Share volume = (Quantity / Quantity per order) * Share volume
//
// The initial data for the distribution is generated in the function of the text request for the preparation of the Sales spending data().
// Includes the following temporary tables:
// - Items of distribution for sale - items of expenses with the option of distribution "To the cost of sales"
// - Balance of expenditures by orders - expenses, with analytics "Customer order" with selection by items of expenses from the temporary 
//		table of items of distribution for sale.
// - Distribution expenses for sale - the amount of expenses to be distributed. 
//	Generated according to the following sources:
//	- Balances of expenses from the temporary table of VTKASHCOUNTABLE statistics and expenses for items with the option 
//		of distribution "To the cost of sales" in any of the types of accounting - Balances of expenses at the end of the period
//	- Movements of "Expense" from the register of "Other expenses" of past periods with households. by the operation of
//		allocating expenses to the highest value of sales by items with Customer order analytics and unallocated Balances at the end of the period - distribution of expenses in previous periods
//
// , the distribution of expenses for customer orders is performed in the function of a text request for selecting the distribution of expenses for the customer's order().
// Data for distribution is taken from the Sales distribution table.
// The base of the distribution is taken from the table of the vtbasdistribution of the client's order.
// The result is stored in the temporary distribution table of the client's order.
//
// The distribution of expenses for all other analysts is performed in the function Textsampling the distribution of sales expenses().
// The data for distribution is taken from the table of sales distribution expenses.
// The base of distribution is taken from the table of vtbazarasdistributionsales.
// The result of the distribution is supplemented by the results of the distribution of costs for orders from the distribution table of the customer's order.
//
// The result of the distribution is saved to a temporary table in the distribution of sales expenditures.

#EndRegion

Function TableForDistributionOfSalesExpenses(CalculationParameters)
	
	Return CostCalculationAppliedAlgorithms.TableForDistributionOfLots(CalculationParameters,
		TextDescriptionOfDataForAllocationOfSalesExpenses());
	
EndFunction

// Sample data

Procedure GetDataForDistributionOfSalesExpenses(CalculationParameters)
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextDistributionOfSalesExpenses(CalculationParameters));
	
EndProcedure

Function RequestTextDistributionOfSalesExpenses(CalculationParameters) Export
	
	Return RequestTextSalesCostAllocationBase()
		+ RequestTextPreparingSalesCostAllocationData()
		+ RequestTextOrderCostAllocationBase()
		+ RequestTextSelectionAllocationOfExpensesForClientSOrder()
		+ TextDescriptionOfDataForAllocationOfSalesExpenses()
		+ TMCommonUse.QuerySeparatorInJoin() + QueryTextSelectionDistributionOfSalesExpenses()
	
EndFunction

Function RequestTextSalesCostAllocationBase()
	
	ArrayOfRequestPackageTexts = New Array;
	
	#Region TTSalesSelectionByPartner
	QueryText =
	"SELECT DISTINCT
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness
	|INTO TTSalesSelectionByPartner
	|FROM
	|	TTCashSettlementBalancesOtherExpenses AS OtherExpenses
	|WHERE
	|	OtherExpenses.Organization IN (&CompanyArray)
	|	AND OtherExpenses.DimensionOfExpenses REFS Catalog.Partners
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	Organization";
	ArrayOfRequestPackageTexts.Add(QueryText);
	#EndRegion
	
	#Region TTSelectionOfSalesByOrder
	QueryText =
	"SELECT DISTINCT
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|	ISNULL(DocumentsRegistry.IBDocumentDate, &BeginOfPeriod) < &BeginOfPeriod AS PreviousPeriod,
	|	DocumentsRegistry.Ref IS NULL AS EmptyRef,
	|	NOT OtherExpenses.DimensionOfExpenses REFS Document.GoodsShipmentToCustomer AS DimensionDocumentSales
	|INTO TTSelectionOfSalesByOrder
	|FROM
	|	TTCashSettlementBalancesOtherExpenses AS OtherExpenses
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	ON DocumentsRegistry.Ref = OtherExpenses.DimensionOfExpenses
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	OtherExpenses.Organization IN (&CompanyArray)
	|	AND (OtherExpenses.DimensionOfExpenses REFS Document.CustomerInvoiceServices
	|	OR OtherExpenses.DimensionOfExpenses REFS Document.CustomerInvoice
	|	OR OtherExpenses.DimensionOfExpenses REFS Document.GoodsShipmentToCustomer
	|	OR OtherExpenses.DimensionOfExpenses REFS Document.ReportToMaterialProvider2_5
	|	OR OtherExpenses.DimensionOfExpenses REFS Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany
	|	)
	|
	|UNION ALL
	|
	// Customer orders used as an invoice will be distributed according to the actual data.
	// Such orders do not have movements in the "Customer Orders" register.
	|SELECT DISTINCT
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|	OrderDocument.Date < &BeginOfPeriod AS PreviousPeriod,
	|	FALSE AS EmptyRef,
	|	FALSE AS DimensionDocumentSales
	|FROM
	|	TTCashSettlementBalancesOtherExpenses AS OtherExpenses
	|	INNER JOIN Document.SalesOrder AS OrderDocument
	|		ON OrderDocument.Ref = OtherExpenses.DimensionOfExpenses
	|		AND OrderDocument.Status = VALUE(Enum.SalesOrderStatuses.NotApproved)
	|WHERE
	|	OtherExpenses.Organization IN (&CompanyArray)
	|	AND OtherExpenses.DimensionOfExpenses REFS Document.SalesOrder
	|
	|
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|	OrderDocument.Date < &BeginOfPeriod AS PreviousPeriod,
	|	FALSE AS EmptyRef,
	|	FALSE AS DimensionDocumentSales
	|FROM
	|	TTCashSettlementBalancesOtherExpenses AS OtherExpenses
	|	INNER JOIN Document.MaterialProviderOrder2_5 AS OrderDocument
	|		ON OrderDocument.Ref = OtherExpenses.DimensionOfExpenses
	|		AND OrderDocument.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.NotApproved)
	|WHERE
	|	OtherExpenses.Organization IN (&CompanyArray)
	|	AND OtherExpenses.DimensionOfExpenses REFS Document.MaterialProviderOrder2_5
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	Organization";
	ArrayOfRequestPackageTexts.Add(QueryText);
	#EndRegion
	
	#Region TTSelectionOfSalesByImplementationsOfPreviousPeriods
	QueryText =
	"SELECT
	|	Filter.Organization AS Organization,
	|	Filter.DimensionOfExpenses AS DimensionOfExpenses,
	|	Filter.LineOfBusiness AS LineOfBusiness,
	|	Filter.DimensionDocumentSales AS DimensionDocumentSales
	|INTO TTSelectionOfSalesByImplementationsOfPreviousPeriods
	|FROM
	|	TTSelectionOfSalesByOrder AS Filter
	|WHERE
	|	Filter.PreviousPeriod
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	Organization";
	ArrayOfRequestPackageTexts.Add(QueryText);
	#EndRegion
	
	#Region TTSelectionOfSalesByTransaction
	QueryText =
	"SELECT DISTINCT
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness
	|INTO TTSelectionOfSalesByTransaction
	|FROM
	|	TTCashSettlementBalancesOtherExpenses AS OtherExpenses
	|WHERE
	|	OtherExpenses.Organization IN (&CompanyArray)
	|	AND OtherExpenses.DimensionOfExpenses REFS Catalog.SalesOpportunitiesToCustomer
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	Organization";
	ArrayOfRequestPackageTexts.Add(QueryText);
	#EndRegion
	
	#Region TTUnfilledExpenseAnalytics
	QueryText =
	"SELECT 
	|	Filter.Organization AS Organization,
	|	Filter.DimensionOfExpenses AS DimensionOfExpenses,
	|	Filter.LineOfBusiness AS LineOfBusiness
	|INTO TTUnfilledExpenseAnalytics
	|FROM TTSalesSelectionByPartner AS Filter
	|WHERE
	|	Filter.DimensionOfExpenses = VALUE(Catalog.Partners.EmptyRef)
	|
	|UNION
	|
	|SELECT 
	|	Filter.Organization,
	|	Filter.DimensionOfExpenses,
	|	Filter.LineOfBusiness AS LineOfBusiness
	|FROM TTSelectionOfSalesByTransaction AS Filter
	|WHERE
	|	Filter.DimensionOfExpenses = VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|
	|UNION
	|
	|SELECT 
	|	Filter.Organization,
	|	Filter.DimensionOfExpenses,
	|	Filter.LineOfBusiness AS LineOfBusiness
	|FROM TTSelectionOfSalesByOrder AS Filter
	|WHERE
	|	Filter.EmptyRef
	|INDEX BY
	|	Organization";
	ArrayOfRequestPackageTexts.Add(QueryText);
	#EndRegion
	
	#Region TTSalesDistributionBaseExData
	
	ArrayOfRequestTexts = New Array;
	
	#Region FilterByPartner
	QueryText =
	"SELECT
	|	""FilterByPartner"" AS RequestSource,
	|	Filter.DimensionOfExpenses AS DimensionOfExpenses,
	|	Filter.LineOfBusiness AS LineOfBusiness,
	|	Filter.Organization AS Organization,
	|	RevenueAndCOGS.Period AS Period,
	|	RevenueAndCOGS.Recorder AS Recorder,
	|	RevenueAndCOGS.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	RevenueAndCOGS.SalesOrder AS SalesOrder,
	|	RevenueAndCOGS.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	RevenueAndCOGS.Department AS Department,
	|	RevenueAndCOGS.InventoryType AS InventoryType,
	|	RevenueAndCOGS.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	RevenueAndCOGS.AccountingSection AS AccountingSection,
	|	RevenueAndCOGS.Lot AS Lot,
	|	RevenueAndCOGS.LotVendorAttributes AS LotVendorAttributes,
	|	RevenueAndCOGS.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	RevenueAndCOGS.VATActivityType AS VATActivityType,
	|	RevenueAndCOGS.Manager AS Manager,
	|	RevenueAndCOGS.Warehouse AS Warehouse,
	|	RevenueAndCOGS.Terms AS Terms,
	|	RevenueAndCOGS.Contract AS Contract,
	|	RevenueAndCOGS.SetAccountingDimension AS SetAccountingDimension,
	|	RevenueAndCOGS.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|	RevenueAndCOGS.ProductLineOfBusiness AS ProductLineOfBusiness,
	|	RevenueAndCOGS.ReversingEntry,
	|	RevenueAndCOGS.VATRate,
	|	RevenueAndCOGS.RevenueAmount
	|		- RevenueAndCOGS.ExciseAmountInCurrencyMgmt AS ManSRevenue,
	|	RevenueAndCOGS.RevenueAmountExclVATLocal
	|		- RevenueAndCOGS.ExciseAmountInCurrencyLocal AS RevenueCompl,
	|	RevenueAndCOGS.Cost
	|		+ RevenueAndCOGS.AddExpensesForGoods
	|		+ RevenueAndCOGS.LaborCosts
	|		+ RevenueAndCOGS.ItemizedFixedCostsIncludingVAT
	|		+ RevenueAndCOGS.ItemizedVariableCostsIncludingVAT AS ManagementCost,
	|	RevenueAndCOGS.LocalCost
	|		+ RevenueAndCOGS.AddExpensesLocal
	|		+ RevenueAndCOGS.LaborCostsLocal
	|		+ RevenueAndCOGS.ItemizedFixedCostsCompl
	|		+ RevenueAndCOGS.ItemizedVariableCostsCompl AS CostLocal,
	|	RevenueAndCOGS.Count AS Count,
	|	&Weight * RevenueAndCOGS.Count AS Weight,
	|	&VolumeM3 * RevenueAndCOGS.Count AS VolumeM3,
	|	RevenueAndCOGS.VATTaxation AS VATTaxation,
	|	RevenueAndCOGS.ARAPCurrency AS ARAPCurrency,
	|	RevenueAndCOGS.DocumentCurrency AS DocumentCurrency,
	|	RevenueAndCOGS.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup
	|INTO TTSalesDistributionBaseExData
	|FROM
	|	TTCashEstimatedTurnoverRevenueAndCostOfSales AS RevenueAndCOGS
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			ON RevenueAndCOGS.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|		INNER JOIN TTSalesSelectionByPartner AS Filter
	|			ON DimensionKeysOfAccountingByPartners.Partner = Filter.DimensionOfExpenses
	|			AND DimensionKeysOfAccountingByPartners.Organization = Filter.Organization
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON RevenueAndCOGS.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts
	|			ON InventoryLocationAttributeKeys.Products = CatProducts.Ref
	|WHERE
	|	RevenueAndCOGS.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DimensionKeysOfAccountingByPartners.Organization IN (&CompanyArray)
	|	AND NOT Filter.DimensionOfExpenses = VALUE(Catalog.Partners.EmptyRef)
	|	AND (RevenueAndCOGS.CounterpartyLineOfBusiness = Filter.LineOfBusiness
	|		OR Filter.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		)
	// The Registered Records for the distribution of expenses on the basis of the previous period are not included in the base of the distribution of sales expenses.
	|	AND VALUETYPE(RevenueAndCOGS.Recorder) <> TYPE(Document.CostCalculationRecorder)
	|";
	ArrayOfRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region FilterByOrder
	QueryText =
	"SELECT
	|	""FilterByOrder"" AS RequestSource,
	|	Filter.DimensionOfExpenses AS DimensionOfExpenses,
	|	Filter.LineOfBusiness AS LineOfBusiness,
	|	Filter.Organization AS Organization,
	|	RevenueAndCOGS.Period AS Period,
	|	RevenueAndCOGS.Recorder,
	|	RevenueAndCOGS.ItemsLocationAttributes,
	|	RevenueAndCOGS.SalesOrder,
	|	RevenueAndCOGS.AccountingDimensionByPartners,
	|	RevenueAndCOGS.Department,
	|	RevenueAndCOGS.InventoryType,
	|	RevenueAndCOGS.InventoryOwnerAttribute,
	|	RevenueAndCOGS.AccountingSection,
	|	RevenueAndCOGS.Lot,
	|	RevenueAndCOGS.LotVendorAttributes,
	|	RevenueAndCOGS.FinancialAccountingDimension,
	|	RevenueAndCOGS.VATActivityType,
	|	RevenueAndCOGS.Manager,
	|	RevenueAndCOGS.Warehouse,
	|	RevenueAndCOGS.Terms,
	|	RevenueAndCOGS.Contract,
	|	RevenueAndCOGS.SetAccountingDimension,
	|	RevenueAndCOGS.CounterpartyLineOfBusiness,
	|	RevenueAndCOGS.ProductLineOfBusiness,
	|	RevenueAndCOGS.ReversingEntry,
	|	RevenueAndCOGS.VATRate,
	|	RevenueAndCOGS.RevenueAmount
	|		- RevenueAndCOGS.ExciseAmountInCurrencyMgmt AS ManSRevenue,
	|	RevenueAndCOGS.RevenueAmountExclVATLocal
	|		- RevenueAndCOGS.ExciseAmountInCurrencyLocal AS RevenueCompl,
	|	RevenueAndCOGS.Cost
	|		+ RevenueAndCOGS.AddExpensesForGoods
	|		+ RevenueAndCOGS.LaborCosts
	|		+ RevenueAndCOGS.ItemizedFixedCostsIncludingVAT
	|		+ RevenueAndCOGS.ItemizedVariableCostsIncludingVAT AS ManagementCost,
	|	RevenueAndCOGS.LocalCost
	|		+ RevenueAndCOGS.AddExpensesLocal
	|		+ RevenueAndCOGS.LaborCostsLocal
	|		+ RevenueAndCOGS.ItemizedFixedCostsCompl
	|		+ RevenueAndCOGS.ItemizedVariableCostsCompl AS CostLocal,
	|	RevenueAndCOGS.Count AS Count,
	|	&Weight * RevenueAndCOGS.Count AS Weight,
	|	&VolumeM3 * RevenueAndCOGS.Count AS VolumeM3,
	|	RevenueAndCOGS.VATTaxation,
	|	RevenueAndCOGS.ARAPCurrency,
	|	RevenueAndCOGS.DocumentCurrency,
	|	RevenueAndCOGS.SourceOfProductFinancialAccountingGroup
	|FROM
	|	TTSelectionOfSalesByOrder AS Filter
	|		INNER JOIN TTCashEstimatedTurnoverRevenueAndCostOfSales AS RevenueAndCOGS
	|			ON RevenueAndCOGS.SalesOrder = Filter.DimensionOfExpenses
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			ON RevenueAndCOGS.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|			AND DimensionKeysOfAccountingByPartners.Organization = Filter.Organization
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON RevenueAndCOGS.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts
	|			ON InventoryLocationAttributeKeys.Products = CatProducts.Ref
	|WHERE
	|	RevenueAndCOGS.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DimensionKeysOfAccountingByPartners.Organization IN (&CompanyArray)
	|	AND NOT Filter.EmptyRef
	|	AND (RevenueAndCOGS.CounterpartyLineOfBusiness = Filter.LineOfBusiness
	|		OR Filter.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	// The Registered Records for the distribution of expenses on the basis of the previous period are not included in the base of the distribution of sales expenses.
	|	AND VALUETYPE(RevenueAndCOGS.Recorder) <> TYPE(Document.CostCalculationRecorder)
	|";
	ArrayOfRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region SelectionByRegistrars
	QueryText =
	"SELECT
	|	""SelectionByRegistrars"" AS RequestSource,
	|	Filter.DimensionOfExpenses AS DimensionOfExpenses,
	|	Filter.LineOfBusiness AS LineOfBusiness,
	|	Filter.Organization AS Organization,
	|	RevenueAndCOGS.Period AS Period,
	|	RevenueAndCOGS.Recorder,
	|	RevenueAndCOGS.ItemsLocationAttributes,
	|	RevenueAndCOGS.SalesOrder,
	|	RevenueAndCOGS.AccountingDimensionByPartners,
	|	RevenueAndCOGS.Department,
	|	RevenueAndCOGS.InventoryType,
	|	RevenueAndCOGS.InventoryOwnerAttribute,
	|	RevenueAndCOGS.AccountingSection,
	|	RevenueAndCOGS.Lot,
	|	RevenueAndCOGS.LotVendorAttributes,
	|	RevenueAndCOGS.FinancialAccountingDimension,
	|	RevenueAndCOGS.VATActivityType,
	|	RevenueAndCOGS.Manager,
	|	RevenueAndCOGS.Warehouse,
	|	RevenueAndCOGS.Terms,
	|	RevenueAndCOGS.Contract,
	|	RevenueAndCOGS.SetAccountingDimension,
	|	RevenueAndCOGS.CounterpartyLineOfBusiness,
	|	RevenueAndCOGS.ProductLineOfBusiness,
	|	RevenueAndCOGS.ReversingEntry,
	|	RevenueAndCOGS.VATRate,
	|	RevenueAndCOGS.RevenueAmount AS ManSRevenue,
	|	RevenueAndCOGS.RevenueAmountExclVATLocal AS RevenueCompl,
	|	RevenueAndCOGS.Cost
	|		+ RevenueAndCOGS.AddExpensesForGoods
	|		+ RevenueAndCOGS.LaborCosts
	|		+ RevenueAndCOGS.ItemizedFixedCostsIncludingVAT
	|		+ RevenueAndCOGS.ItemizedVariableCostsIncludingVAT AS ManagementCost,
	|	RevenueAndCOGS.LocalCost
	|		+ RevenueAndCOGS.AddExpensesLocal
	|		+ RevenueAndCOGS.LaborCostsLocal
	|		+ RevenueAndCOGS.ItemizedFixedCostsCompl
	|		+ RevenueAndCOGS.ItemizedVariableCostsCompl AS CostLocal,
	|	RevenueAndCOGS.Count AS Count,
	|	&Weight * RevenueAndCOGS.Count AS Weight,
	|	&VolumeM3 * RevenueAndCOGS.Count AS VolumeM3,
	|	RevenueAndCOGS.VATTaxation,
	|	RevenueAndCOGS.ARAPCurrency,
	|	RevenueAndCOGS.DocumentCurrency,
	|	RevenueAndCOGS.SourceOfProductFinancialAccountingGroup
	|FROM
	|	TTSelectionOfSalesByOrder AS Filter
	|		INNER JOIN TTCashEstimatedTurnoverRevenueAndCostOfSales AS RevenueAndCOGS
	|			ON RevenueAndCOGS.Recorder = Filter.DimensionOfExpenses
	|			AND RevenueAndCOGS.SalesOrder <> RevenueAndCOGS.Recorder
	|			AND NOT RevenueAndCOGS.LotCalculation AND Filter.DimensionDocumentSales
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			ON RevenueAndCOGS.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|			AND DimensionKeysOfAccountingByPartners.Organization = Filter.Organization
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON RevenueAndCOGS.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts
	|			ON InventoryLocationAttributeKeys.Products = CatProducts.Ref
	|WHERE
	|	RevenueAndCOGS.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DimensionKeysOfAccountingByPartners.Organization IN (&CompanyArray)
	|	AND NOT Filter.EmptyRef
	|	AND (RevenueAndCOGS.CounterpartyLineOfBusiness = Filter.LineOfBusiness
	|		OR Filter.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	AND (RevenueAndCOGS.RevenueAmount <> 0
	|		OR RevenueAndCOGS.RevenueAmountExclVATLocal <> 0
	|		OR RevenueAndCOGS.Cost + RevenueAndCOGS.AddExpensesForGoods + RevenueAndCOGS.LaborCosts
	|		+ RevenueAndCOGS.ItemizedFixedCostsIncludingVAT + RevenueAndCOGS.ItemizedVariableCostsIncludingVAT <> 0
	|		OR RevenueAndCOGS.LocalCost + RevenueAndCOGS.AddExpensesLocal + RevenueAndCOGS.LaborCostsLocal
	|		+ RevenueAndCOGS.ItemizedFixedCostsCompl + RevenueAndCOGS.ItemizedVariableCostsCompl <> 0)
	// The Registered Records for the distribution of expenses on the basis of the previous period are not included in the base of the distribution of sales expenses.
	|	AND VALUETYPE(RevenueAndCOGS.Recorder) <> TYPE(Document.CostCalculationRecorder)
	|";
	ArrayOfRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region SelectionBasedOnOrdersFromPreviousPeriods
	QueryText =
	"SELECT
	|	""SelectionBasedOnOrdersFromPreviousPeriods"" AS RequestSource,
	|	Filter.DimensionOfExpenses AS DimensionOfExpenses,
	|	Filter.LineOfBusiness AS LineOfBusiness,
	|	Filter.Organization AS Organization,
	|	&EndOfPeriod AS Period,
	|	RevenueAndCOGS.Recorder,
	|	RevenueAndCOGS.ItemsLocationAttributes,
	|	RevenueAndCOGS.SalesOrder,
	|	RevenueAndCOGS.AccountingDimensionByPartners,
	|	RevenueAndCOGS.Department,
	|	RevenueAndCOGS.InventoryType,
	|	RevenueAndCOGS.InventoryOwnerAttribute,
	|	RevenueAndCOGS.AccountingSection,
	|	RevenueAndCOGS.Lot,
	|	RevenueAndCOGS.LotVendorAttributes,
	|	RevenueAndCOGS.FinancialAccountingDimension,
	|	RevenueAndCOGS.VATActivityType,
	|	RevenueAndCOGS.Manager,
	|	RevenueAndCOGS.Warehouse,
	|	RevenueAndCOGS.Terms,
	|	RevenueAndCOGS.Contract,
	|	RevenueAndCOGS.SetAccountingDimension,
	|	RevenueAndCOGS.CounterpartyLineOfBusiness,
	|	RevenueAndCOGS.ProductLineOfBusiness,
	|	RevenueAndCOGS.ReversingEntry,
	|	RevenueAndCOGS.VATRate,
	|	RevenueAndCOGS.RevenueAmount
	|		- RevenueAndCOGS.ExciseAmountInCurrencyMgmt AS ManSRevenue,
	|	RevenueAndCOGS.RevenueAmountExclVATLocal
	|		- RevenueAndCOGS.ExciseAmountInCurrencyLocal AS RevenueCompl,
	|	RevenueAndCOGS.Cost
	|		+ RevenueAndCOGS.AddExpensesForGoods
	|		+ RevenueAndCOGS.LaborCosts
	|		+ RevenueAndCOGS.ItemizedFixedCostsIncludingVAT
	|		+ RevenueAndCOGS.ItemizedVariableCostsIncludingVAT AS ManagementCost,
	|	RevenueAndCOGS.LocalCost
	|		+ RevenueAndCOGS.AddExpensesLocal
	|		+ RevenueAndCOGS.LaborCostsLocal
	|		+ RevenueAndCOGS.ItemizedFixedCostsCompl
	|		+ RevenueAndCOGS.ItemizedVariableCostsCompl AS CostLocal,
	|	RevenueAndCOGS.Count AS Count,
	|	&Weight * RevenueAndCOGS.Count AS Weight,
	|	&VolumeM3 * RevenueAndCOGS.Count AS VolumeM3,
	|	RevenueAndCOGS.VATTaxation,
	|	RevenueAndCOGS.ARAPCurrency,
	|	RevenueAndCOGS.DocumentCurrency,
	|	RevenueAndCOGS.SourceOfProductFinancialAccountingGroup
	|FROM
	|	TTSelectionOfSalesByImplementationsOfPreviousPeriods AS Filter
	|		INNER JOIN AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|		ON RevenueAndCOGS.SalesOrder = Filter.DimensionOfExpenses
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|		ON RevenueAndCOGS.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|			AND DimensionKeysOfAccountingByPartners.Organization = Filter.Organization
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON RevenueAndCOGS.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts
	|			ON InventoryLocationAttributeKeys.Products = CatProducts.Ref
	|WHERE
	|	RevenueAndCOGS.Period < &BeginOfPeriod
	|	AND RevenueAndCOGS.Active
	|	AND DimensionKeysOfAccountingByPartners.Organization IN (&CompanyArray)
	|	AND (RevenueAndCOGS.CounterpartyLineOfBusiness = Filter.LineOfBusiness
	|		OR Filter.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	)
	// The Registered Records for the distribution of expenses on the basis of the previous period are not included in the base of the distribution of sales expenses.
	|	AND VALUETYPE(RevenueAndCOGS.Recorder) <> TYPE(Document.CostCalculationRecorder)
	|";
	ArrayOfRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region SelectionByRegistrarsOfPreviousPeriods
	QueryText =
	"SELECT
	|	""SelectionByRegistrarsOfPreviousPeriods"" AS RequestSource,
	|	Filter.DimensionOfExpenses AS DimensionOfExpenses,
	|	Filter.LineOfBusiness AS LineOfBusiness,
	|	Filter.Organization AS Organization,
	|	&EndOfPeriod AS Period,
	|	RevenueAndCOGS.Recorder,
	|	RevenueAndCOGS.ItemsLocationAttributes,
	|	RevenueAndCOGS.SalesOrder,
	|	RevenueAndCOGS.AccountingDimensionByPartners,
	|	RevenueAndCOGS.Department,
	|	RevenueAndCOGS.InventoryType,
	|	RevenueAndCOGS.InventoryOwnerAttribute,
	|	RevenueAndCOGS.AccountingSection,
	|	RevenueAndCOGS.Lot,
	|	RevenueAndCOGS.LotVendorAttributes,
	|	RevenueAndCOGS.FinancialAccountingDimension,
	|	RevenueAndCOGS.VATActivityType,
	|	RevenueAndCOGS.Manager,
	|	RevenueAndCOGS.Warehouse,
	|	RevenueAndCOGS.Terms,
	|	RevenueAndCOGS.Contract,
	|	RevenueAndCOGS.SetAccountingDimension,
	|	RevenueAndCOGS.CounterpartyLineOfBusiness,
	|	RevenueAndCOGS.ProductLineOfBusiness,
	|	RevenueAndCOGS.ReversingEntry,
	|	RevenueAndCOGS.VATRate,
	|	RevenueAndCOGS.RevenueAmount
	|		- RevenueAndCOGS.ExciseAmountInCurrencyMgmt AS ManSRevenue,
	|	RevenueAndCOGS.RevenueAmountExclVATLocal
	|		- RevenueAndCOGS.ExciseAmountInCurrencyLocal AS RevenueCompl,
	|	RevenueAndCOGS.Cost
	|		+ RevenueAndCOGS.AddExpensesForGoods
	|		+ RevenueAndCOGS.LaborCosts
	|		+ RevenueAndCOGS.ItemizedFixedCostsIncludingVAT
	|		+ RevenueAndCOGS.ItemizedVariableCostsIncludingVAT AS ManagementCost,
	|	RevenueAndCOGS.LocalCost
	|		+ RevenueAndCOGS.AddExpensesLocal
	|		+ RevenueAndCOGS.LaborCostsLocal
	|		+ RevenueAndCOGS.ItemizedFixedCostsCompl
	|		+ RevenueAndCOGS.ItemizedVariableCostsCompl AS CostLocal,
	|	RevenueAndCOGS.Count AS Count,
	|	&Weight * RevenueAndCOGS.Count AS Weight,
	|	&VolumeM3 * RevenueAndCOGS.Count AS VolumeM3,
	|	RevenueAndCOGS.VATTaxation,
	|	RevenueAndCOGS.ARAPCurrency,
	|	RevenueAndCOGS.DocumentCurrency,
	|	RevenueAndCOGS.SourceOfProductFinancialAccountingGroup
	|FROM
	|	TTSelectionOfSalesByImplementationsOfPreviousPeriods AS Filter
	|		INNER JOIN AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|		ON RevenueAndCOGS.Recorder = Filter.DimensionOfExpenses
	|			AND RevenueAndCOGS.SalesOrder <> RevenueAndCOGS.Recorder
	|			AND NOT RevenueAndCOGS.LotCalculation AND Filter.DimensionDocumentSales
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|		ON RevenueAndCOGS.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|			AND DimensionKeysOfAccountingByPartners.Organization = Filter.Organization
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON RevenueAndCOGS.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts
	|			ON InventoryLocationAttributeKeys.Products = CatProducts.Ref
	|WHERE
	|	RevenueAndCOGS.Period < &BeginOfPeriod
	|	AND RevenueAndCOGS.Active
	|	AND DimensionKeysOfAccountingByPartners.Organization IN (&CompanyArray)
	|	AND (RevenueAndCOGS.CounterpartyLineOfBusiness = Filter.LineOfBusiness
	|		OR Filter.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	)
	|	AND (RevenueAndCOGS.RevenueAmount <> 0
	|		OR RevenueAndCOGS.RevenueAmountExclVATLocal <> 0
	|		OR RevenueAndCOGS.Cost + RevenueAndCOGS.AddExpensesForGoods + RevenueAndCOGS.LaborCosts
	|		+ RevenueAndCOGS.ItemizedFixedCostsIncludingVAT + RevenueAndCOGS.ItemizedVariableCostsIncludingVAT <> 0
	|		OR RevenueAndCOGS.LocalCost + RevenueAndCOGS.AddExpensesLocal + RevenueAndCOGS.LaborCostsLocal
	|		+ RevenueAndCOGS.ItemizedFixedCostsCompl + RevenueAndCOGS.ItemizedVariableCostsCompl <> 0)
	// The Registered Records for the distribution of expenses on the basis of the previous period are not included in the base of the distribution of sales expenses.
	|	AND VALUETYPE(RevenueAndCOGS.Recorder) <> TYPE(Document.CostCalculationRecorder)
	|";
	ArrayOfRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region SelectionByTransaction
	QueryText =
	"SELECT
	|	""SelectionByTransaction"" AS RequestSource,
	|	Filter.DimensionOfExpenses AS DimensionOfExpenses,
	|	Filter.LineOfBusiness AS LineOfBusiness,
	|	Filter.Organization AS Organization,
	|	RevenueAndCOGS.Period AS Period,
	|	RevenueAndCOGS.Recorder,
	|	RevenueAndCOGS.ItemsLocationAttributes,
	|	RevenueAndCOGS.SalesOrder,
	|	RevenueAndCOGS.AccountingDimensionByPartners,
	|	RevenueAndCOGS.Department,
	|	RevenueAndCOGS.InventoryType,
	|	RevenueAndCOGS.InventoryOwnerAttribute,
	|	RevenueAndCOGS.AccountingSection,
	|	RevenueAndCOGS.Lot,
	|	RevenueAndCOGS.LotVendorAttributes,
	|	RevenueAndCOGS.FinancialAccountingDimension,
	|	RevenueAndCOGS.VATActivityType,
	|	RevenueAndCOGS.Manager,
	|	RevenueAndCOGS.Warehouse,
	|	RevenueAndCOGS.Terms,
	|	RevenueAndCOGS.Contract,
	|	RevenueAndCOGS.SetAccountingDimension,
	|	RevenueAndCOGS.CounterpartyLineOfBusiness,
	|	RevenueAndCOGS.ProductLineOfBusiness,
	|	RevenueAndCOGS.ReversingEntry,
	|	RevenueAndCOGS.VATRate,
	|	RevenueAndCOGS.RevenueAmount
	|		- RevenueAndCOGS.ExciseAmountInCurrencyMgmt AS ManSRevenue,
	|	RevenueAndCOGS.RevenueAmountExclVATLocal
	|		- RevenueAndCOGS.ExciseAmountInCurrencyLocal AS RevenueCompl,
	|	RevenueAndCOGS.Cost
	|		+ RevenueAndCOGS.AddExpensesForGoods
	|		+ RevenueAndCOGS.LaborCosts
	|		+ RevenueAndCOGS.ItemizedFixedCostsIncludingVAT
	|		+ RevenueAndCOGS.ItemizedVariableCostsIncludingVAT AS ManagementCost,
	|	RevenueAndCOGS.LocalCost
	|		+ RevenueAndCOGS.AddExpensesLocal
	|		+ RevenueAndCOGS.LaborCostsLocal
	|		+ RevenueAndCOGS.ItemizedFixedCostsCompl
	|		+ RevenueAndCOGS.ItemizedVariableCostsCompl AS CostLocal,
	|	RevenueAndCOGS.Count AS Count,
	|	&Weight * RevenueAndCOGS.Count AS Weight,
	|	&VolumeM3 * RevenueAndCOGS.Count AS VolumeM3,
	|	RevenueAndCOGS.VATTaxation,
	|	RevenueAndCOGS.ARAPCurrency,
	|	RevenueAndCOGS.DocumentCurrency,
	|	RevenueAndCOGS.SourceOfProductFinancialAccountingGroup
	|FROM
	|	TTCashEstimatedTurnoverRevenueAndCostOfSales AS RevenueAndCOGS
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON RevenueAndCOGS.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts
	|			ON InventoryLocationAttributeKeys.Products = CatProducts.Ref
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			ON RevenueAndCOGS.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|		INNER JOIN TTSelectionOfSalesByTransaction AS Filter
	|			ON ISNULL(RevenueAndCOGS.SalesOrder.SalesOpportunity, VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)) = Filter.DimensionOfExpenses
	|			AND DimensionKeysOfAccountingByPartners.Organization = Filter.Organization
	|WHERE
	|	RevenueAndCOGS.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DimensionKeysOfAccountingByPartners.Organization IN (&CompanyArray)
	|	AND NOT Filter.DimensionOfExpenses = VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	AND (RevenueAndCOGS.CounterpartyLineOfBusiness = Filter.LineOfBusiness
	|		OR Filter.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	)
	// The Registered Records for the distribution of expenses on the basis of the previous period are not included in the base of the distribution of sales expenses.
	|	AND VALUETYPE(RevenueAndCOGS.Recorder) <> TYPE(Document.CostCalculationRecorder)
	|";
	ArrayOfRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region SelectionByBlankAnalysts
	QueryText =
	"SELECT
	|	""SelectionByBlankAnalysts"" AS RequestSource,
	|	Filter.DimensionOfExpenses AS DimensionOfExpenses,
	|	Filter.LineOfBusiness AS LineOfBusiness,
	|	Filter.Organization AS Organization,
	|	RevenueAndCOGS.Period AS Period,
	|	RevenueAndCOGS.Recorder,
	|	RevenueAndCOGS.ItemsLocationAttributes,
	|	RevenueAndCOGS.SalesOrder,
	|	RevenueAndCOGS.AccountingDimensionByPartners,
	|	RevenueAndCOGS.Department,
	|	RevenueAndCOGS.InventoryType,
	|	RevenueAndCOGS.InventoryOwnerAttribute,
	|	RevenueAndCOGS.AccountingSection,
	|	RevenueAndCOGS.Lot,
	|	RevenueAndCOGS.LotVendorAttributes,
	|	RevenueAndCOGS.FinancialAccountingDimension,
	|	RevenueAndCOGS.VATActivityType,
	|	RevenueAndCOGS.Manager,
	|	RevenueAndCOGS.Warehouse,
	|	RevenueAndCOGS.Terms,
	|	RevenueAndCOGS.Contract,
	|	RevenueAndCOGS.SetAccountingDimension,
	|	RevenueAndCOGS.CounterpartyLineOfBusiness,
	|	RevenueAndCOGS.ProductLineOfBusiness,
	|	RevenueAndCOGS.ReversingEntry,
	|	RevenueAndCOGS.VATRate,
	|	RevenueAndCOGS.RevenueAmount
	|		- RevenueAndCOGS.ExciseAmountInCurrencyMgmt AS ManSRevenue,
	|	RevenueAndCOGS.RevenueAmountExclVATLocal
	|		- RevenueAndCOGS.ExciseAmountInCurrencyLocal AS RevenueCompl,
	|	RevenueAndCOGS.Cost
	|		+ RevenueAndCOGS.AddExpensesForGoods
	|		+ RevenueAndCOGS.LaborCosts
	|		+ RevenueAndCOGS.ItemizedFixedCostsIncludingVAT
	|		+ RevenueAndCOGS.ItemizedVariableCostsIncludingVAT AS ManagementCost,
	|	RevenueAndCOGS.LocalCost
	|		+ RevenueAndCOGS.AddExpensesLocal
	|		+ RevenueAndCOGS.LaborCostsLocal
	|		+ RevenueAndCOGS.ItemizedFixedCostsCompl
	|		+ RevenueAndCOGS.ItemizedVariableCostsCompl AS CostLocal,
	|	RevenueAndCOGS.Count AS Count,
	|	&Weight * RevenueAndCOGS.Count AS Weight,
	|	&VolumeM3 * RevenueAndCOGS.Count AS VolumeM3,
	|	RevenueAndCOGS.VATTaxation,
	|	RevenueAndCOGS.ARAPCurrency,
	|	RevenueAndCOGS.DocumentCurrency,
	|	RevenueAndCOGS.SourceOfProductFinancialAccountingGroup
	|FROM
	|	TTCashEstimatedTurnoverRevenueAndCostOfSales AS RevenueAndCOGS
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON RevenueAndCOGS.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts
	|			ON InventoryLocationAttributeKeys.Products = CatProducts.Ref
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			ON RevenueAndCOGS.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|		INNER JOIN TTUnfilledExpenseAnalytics AS Filter
	|			ON DimensionKeysOfAccountingByPartners.Organization = Filter.Organization
	|WHERE
	|	RevenueAndCOGS.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DimensionKeysOfAccountingByPartners.Organization IN (&CompanyArray)
	|	AND RevenueAndCOGS.SalesOrder <> UNDEFINED
	|	AND DimensionKeysOfAccountingByPartners.Partner <> VALUE(Catalog.Partners.EmptyRef)
	|	AND (RevenueAndCOGS.CounterpartyLineOfBusiness = Filter.LineOfBusiness
	|		OR Filter.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	)
	// The Registered Records for the distribution of expenses on the basis of the previous period are not included in the base of the distribution of sales expenses.
	|	AND VALUETYPE(RevenueAndCOGS.Recorder) <> TYPE(Document.CostCalculationRecorder)
	|";
	ArrayOfRequestTexts.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin()) + "
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	Organization";
	ArrayOfRequestPackageTexts.Add(QueryText);
	#EndRegion
	
	#Region TTSalesDistributionDatabaseData
	QueryText =
	"SELECT
	|	Data.LineOfBusiness,
	|	Data.DimensionOfExpenses,
	|	Data.Organization,
	|	Data.Period,
	|	Data.Recorder,
	|	Data.ItemsLocationAttributes,
	|	Data.SalesOrder,
	|	Data.AccountingDimensionByPartners,
	|	Data.Department,
	|	Data.InventoryType,
	|	Data.InventoryOwnerAttribute,
	|	Data.AccountingSection,
	|	Data.Lot,
	|	Data.LotVendorAttributes,
	|	Data.FinancialAccountingDimension,
	|	Data.VATActivityType,
	|	Data.Manager,
	|	Data.Warehouse,
	|	Data.Terms,
	|	Data.Contract,
	|	Data.SetAccountingDimension,
	|	Data.CounterpartyLineOfBusiness,
	|	Data.ProductLineOfBusiness,
	|	Data.VATTaxation,
	|	Data.ARAPCurrency,
	|	Data.DocumentCurrency,
	|	Data.SourceOfProductFinancialAccountingGroup,
	|	Data.ReversingEntry,
	|	Data.VATRate,
	|	SUM(Data.Count) AS Count,
	|	SUM(Data.Weight) AS Weight,
	|	SUM(Data.VolumeM3) AS VolumeM3,
	|	SUM(Data.ManSRevenue) AS ManSRevenue,
	|	SUM(Data.RevenueCompl) AS RevenueCompl,
	|	SUM(Data.ManagementCost) AS ManagementCost,
	|	SUM(Data.CostLocal) AS CostLocal
	|INTO TTSalesDistributionDatabaseData
	|FROM
	|	TTSalesDistributionBaseExData AS Data
	|GROUP BY
	|	Data.LineOfBusiness,
	|	Data.DimensionOfExpenses,
	|	Data.Organization,
	|	Data.Period,
	|	Data.Recorder,
	|	Data.ItemsLocationAttributes,
	|	Data.SalesOrder,
	|	Data.AccountingDimensionByPartners,
	|	Data.Department,
	|	Data.InventoryType,
	|	Data.InventoryOwnerAttribute,
	|	Data.AccountingSection,
	|	Data.Lot,
	|	Data.LotVendorAttributes,
	|	Data.FinancialAccountingDimension,
	|	Data.VATActivityType,
	|	Data.Manager,
	|	Data.Warehouse,
	|	Data.Terms,
	|	Data.Contract,
	|	Data.SetAccountingDimension,
	|	Data.CounterpartyLineOfBusiness,
	|	Data.ProductLineOfBusiness,
	|	Data.VATTaxation,
	|	Data.ARAPCurrency,
	|	Data.DocumentCurrency,
	|	Data.SourceOfProductFinancialAccountingGroup,
	|	Data.ReversingEntry,
	|	Data.VATRate";
	ArrayOfRequestPackageTexts.Add(QueryText);
	#EndRegion
	
	#Region TTSalesDistributionBaseAmounts
	QueryText =
	"SELECT
	|	TTSalesDistributionBaseExData.LineOfBusiness AS LineOfBusiness,
	|	TTSalesDistributionBaseExData.DimensionOfExpenses AS DimensionOfExpenses,
	|	TTSalesDistributionBaseExData.Organization AS Organization,
	|	SUM(TTSalesDistributionBaseExData.ManSRevenue) AS ManSRevenue,
	|	SUM(TTSalesDistributionBaseExData.RevenueCompl) AS RevenueCompl,
	|	SUM(TTSalesDistributionBaseExData.ManagementCost) AS ManagementCost,
	|	SUM(TTSalesDistributionBaseExData.CostLocal) AS CostLocal,
	|	SUM(TTSalesDistributionBaseExData.Count) AS Count,
	|	SUM(TTSalesDistributionBaseExData.Weight) AS Weight,
	|	SUM(TTSalesDistributionBaseExData.VolumeM3) AS VolumeM3
	|INTO TTSalesDistributionBaseAmounts
	|FROM
	|	TTSalesDistributionBaseExData AS TTSalesDistributionBaseExData
	|GROUP BY
	|	TTSalesDistributionBaseExData.LineOfBusiness,
	|	TTSalesDistributionBaseExData.DimensionOfExpenses,
	|	TTSalesDistributionBaseExData.Organization
	|
	|INDEX BY
	|	DimensionOfExpenses";
	ArrayOfRequestPackageTexts.Add(QueryText);
	#EndRegion
	
	#Region TTDistributionBaseForSales
	QueryText =
	"SELECT
	|	TTSalesDistributionBaseExData.LineOfBusiness AS LineOfBusiness,
	|	TTSalesDistributionBaseExData.DimensionOfExpenses AS DimensionOfExpenses,
	|	TTSalesDistributionBaseExData.Period AS Period,
	|	TTSalesDistributionBaseExData.Organization AS Organization,
	|	TTSalesDistributionBaseExData.Recorder AS Recorder,
	|	TTSalesDistributionBaseExData.ItemsLocationAttributes,
	|	TTSalesDistributionBaseExData.SalesOrder,
	|	TTSalesDistributionBaseExData.AccountingDimensionByPartners,
	|	TTSalesDistributionBaseExData.Department,
	|	TTSalesDistributionBaseExData.InventoryType,
	|	TTSalesDistributionBaseExData.InventoryOwnerAttribute,
	|	TTSalesDistributionBaseExData.AccountingSection,
	|	TTSalesDistributionBaseExData.Lot,
	|	TTSalesDistributionBaseExData.LotVendorAttributes,
	|	TTSalesDistributionBaseExData.FinancialAccountingDimension,
	|	TTSalesDistributionBaseExData.VATActivityType,
	|	TTSalesDistributionBaseExData.Manager,
	|	TTSalesDistributionBaseExData.Warehouse,
	|	TTSalesDistributionBaseExData.Terms,
	|	TTSalesDistributionBaseExData.Contract,
	|	TTSalesDistributionBaseExData.SetAccountingDimension,
	|	TTSalesDistributionBaseExData.CounterpartyLineOfBusiness,
	|	TTSalesDistributionBaseExData.ProductLineOfBusiness,
	|	TTSalesDistributionBaseExData.ReversingEntry,
	|	TTSalesDistributionBaseExData.VATRate,
	|	CASE
	|		WHEN ISNULL(TTSalesDistributionBaseAmounts.ManSRevenue, 0) = 0
	|			THEN 0
	|		ELSE TTSalesDistributionBaseExData.ManSRevenue / TTSalesDistributionBaseAmounts.ManSRevenue
	|	END AS ShareRevenueMan,
	|	CASE
	|		WHEN ISNULL(TTSalesDistributionBaseAmounts.RevenueCompl, 0) = 0
	|			THEN 0
	|		ELSE TTSalesDistributionBaseExData.RevenueCompl / TTSalesDistributionBaseAmounts.RevenueCompl
	|	END AS ShareRevenueLocal,
	|	CASE
	|		WHEN ISNULL(TTSalesDistributionBaseAmounts.ManagementCost, 0) = 0
	|			THEN 0
	|		ELSE TTSalesDistributionBaseExData.ManagementCost / TTSalesDistributionBaseAmounts.ManagementCost
	|	END AS ShareCostOfMan,
	|	CASE
	|		WHEN ISNULL(TTSalesDistributionBaseAmounts.CostLocal, 0) = 0
	|			THEN 0
	|		ELSE TTSalesDistributionBaseExData.CostLocal / TTSalesDistributionBaseAmounts.CostLocal
	|	END AS ShareCostOfLocal,
	|	CASE
	|		WHEN ISNULL(TTSalesDistributionBaseAmounts.Count, 0) = 0
	|			THEN 0
	|		ELSE CAST(TTSalesDistributionBaseExData.Count AS NUMBER(28, 10)) 
	|				/ CAST(TTSalesDistributionBaseAmounts.Count AS NUMBER(28, 10))
	|	END AS ShareQuantity,
	|	CASE
	|		WHEN ISNULL(TTSalesDistributionBaseAmounts.Weight, 0) = 0
	|			THEN 0
	|		ELSE CAST(TTSalesDistributionBaseExData.Weight AS NUMBER(28, 10)) 
	|				/ CAST(TTSalesDistributionBaseAmounts.Weight AS NUMBER(28, 10))
	|	END AS ShareWeight,
	|	CASE
	|		WHEN ISNULL(TTSalesDistributionBaseAmounts.VolumeM3, 0) = 0
	|			THEN 0
	|		ELSE CAST(TTSalesDistributionBaseExData.VolumeM3 AS NUMBER(28, 10)) 
	|				/ CAST(TTSalesDistributionBaseAmounts.VolumeM3 AS NUMBER(28, 10))
	|	END AS ShareVolume,
	|	TTSalesDistributionBaseExData.VATTaxation,
	|	TTSalesDistributionBaseExData.ARAPCurrency,
	|	TTSalesDistributionBaseExData.DocumentCurrency,
	|	TTSalesDistributionBaseExData.SourceOfProductFinancialAccountingGroup
	|INTO TTDistributionBaseForSales
	|FROM
	|	TTSalesDistributionDatabaseData AS TTSalesDistributionBaseExData
	|		LEFT JOIN TTSalesDistributionBaseAmounts AS TTSalesDistributionBaseAmounts
	|		ON TTSalesDistributionBaseExData.DimensionOfExpenses = TTSalesDistributionBaseAmounts.DimensionOfExpenses
	|			AND TTSalesDistributionBaseExData.Organization = TTSalesDistributionBaseAmounts.Organization
	|			AND TTSalesDistributionBaseExData.LineOfBusiness = TTSalesDistributionBaseAmounts.LineOfBusiness
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	Organization,
	|	LineOfBusiness";
	ArrayOfRequestPackageTexts.Add(QueryText);
	#EndRegion
	
	ArrayOfRequestPackageTexts.Add("");
	
	QueryText = StrConcat(ArrayOfRequestPackageTexts, Common.QueryBatchSeparator());
	
	Return CostCalculationAppliedAlgorithms.InsertWeightAndVolumeTemplatesIntoQueryText(QueryText);
	
EndFunction

Function RequestTextOrderCostAllocationBase()
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DD.Organization AS Organization,
	|	OrderDocument.Ref AS DimensionOfExpenses,
	|	OrderDocument.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	OrderDocument.LineOfBusiness AS LineOfBusiness,
	|	GoodsFromOrder.Products AS Products,
	|	GoodsFromOrder.Characteristic AS Characteristic,
	|	GoodsFromOrder.Series AS Series,
	|	GoodsFromOrder.Warehouse AS Warehouse,
	|	GoodsFromOrder.RowCode AS RowCode,
	|	GoodsFromOrder.BatchesIndicationStatus IN (14, 18) AS BatchIsSpecified
	|INTO TTSelectionAccordingToCustomerSOrderInDetail
	|FROM
	|	TTCashSettlementBalancesOtherExpenses AS DD
	|
	|	INNER JOIN Document.SalesOrder AS OrderDocument
	|	ON OrderDocument.Ref = DD.DimensionOfExpenses
	|
	|	INNER JOIN Document.SalesOrder.Goods AS GoodsFromOrder
	|	ON GoodsFromOrder.Ref = DD.DimensionOfExpenses
	|
	// We exclude orders that are taken into account in the temporary table of the second sale by order.
	// The costs of such orders have already been distributed. 
	|	LEFT JOIN TTSelectionOfSalesByOrder AS TTSelectionOfSalesByOrder
	|	ON TTSelectionOfSalesByOrder.Organization = DD.Organization
	|		AND TTSelectionOfSalesByOrder.DimensionOfExpenses = DD.DimensionOfExpenses
	|		AND TTSelectionOfSalesByOrder.LineOfBusiness = DD.LineOfBusiness
	|WHERE
	|	DD.Organization IN (&CompanyArray)
	|	AND TTSelectionOfSalesByOrder.DimensionOfExpenses IS NULL
	|
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DD.Organization AS Organization,
	|	GoodsFromOrder.Ref AS DimensionOfExpenses,
	|	FALSE AS ToReturnReusablePackage,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	GoodsFromOrder.Products AS Products,
	|	GoodsFromOrder.Characteristic AS Characteristic,
	|	GoodsFromOrder.Series AS Series,
	|	GoodsFromOrder.Warehouse AS Warehouse,
	|	GoodsFromOrder.RowCode AS RowCode,
	|	GoodsFromOrder.BatchesIndicationStatus IN (14, 18) AS BatchIsSpecified
	|FROM
	|	TTCashSettlementBalancesOtherExpenses AS DD
	|
	|	INNER JOIN Document.MaterialProviderOrder2_5.ManufacturedProduct AS GoodsFromOrder
	|	ON GoodsFromOrder.Ref = DD.DimensionOfExpenses
	|
	// We exclude orders that are taken into account in the temporary table of the second sale by order.
	// The costs of such orders have already been distributed. 
	|	LEFT JOIN TTSelectionOfSalesByOrder AS TTSelectionOfSalesByOrder
	|	ON TTSelectionOfSalesByOrder.Organization = DD.Organization
	|		AND TTSelectionOfSalesByOrder.DimensionOfExpenses = DD.DimensionOfExpenses
	|		AND TTSelectionOfSalesByOrder.LineOfBusiness = DD.LineOfBusiness
	|WHERE
	|	DD.Organization IN (&CompanyArray)
	|	AND TTSelectionOfSalesByOrder.DimensionOfExpenses IS NULL
	|INDEX BY
	|	DimensionOfExpenses,
	|	Organization
	|;
	|
	|SELECT DISTINCT
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	DD.Products AS Products,
	|	DD.Characteristic AS Characteristic,
	|	DD.Series AS Series,
	|	DD.Warehouse AS Warehouse,
	|	DD.Organization AS Organization,
	|	DD.BatchIsSpecified AS BatchIsSpecified
	|INTO TTSelectionByCustomerSOrderIsMinimized
	|FROM
	|	TTSelectionAccordingToCustomerSOrderInDetail AS DD
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Series,
	|	Organization,
	|	BatchIsSpecified
	|;
	|
	|SELECT DISTINCT
	|	TTSelectionAccordingToCustomerSOrderInDetail.Organization AS Organization,
	|	TTSelectionAccordingToCustomerSOrderInDetail.DimensionOfExpenses AS DimensionOfExpenses,
	|	TTSelectionAccordingToCustomerSOrderInDetail.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	TTSelectionAccordingToCustomerSOrderInDetail.LineOfBusiness AS LineOfBusiness
	|INTO TTSelectionAccordingToCustomerSOrder
	|FROM
	|	TTSelectionAccordingToCustomerSOrderInDetail AS TTSelectionAccordingToCustomerSOrderInDetail
	|INDEX BY
	|	DimensionOfExpenses,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS SourceCode,
	|	DD.Recorder AS Recorder,
	|	DD.ReferenceOrder.Organization AS Organization,
	|	DD.ReferenceOrder AS SalesOrder,
	|	TTSelectionAccordingToCustomerSOrder.LineOfBusiness AS LineOfBusiness,
	|	DD.Products AS Products,
	|	DD.Characteristic AS Characteristic,
	|	DD.RowCode AS RowCode,
	|	DD.Warehouse AS Warehouse,
	|	CASE
	|		WHEN TTSelectionAccordingToCustomerSOrder.BatchIsSpecified
	|		THEN DD.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	DD.Period AS Period,
	|	DD.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped) AS Real,
	|	CASE
	|		WHEN DD.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|			THEN DD.Count
	|		ELSE 0
	|	END AS CountReal,
	|	CASE
	|		WHEN DD.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered)
	|			THEN DD.Count
	|		ELSE 0
	|	END AS CountPlan,
	|	CASE
	|		WHEN DD.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|			THEN &Weight * DD.Count
	|		ELSE 0
	|	END AS WeightFact,
	|	CASE
	|		WHEN DD.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered)
	|			THEN &Weight * DD.Count
	|		ELSE 0
	|	END AS WeightPlan,
	|	CASE
	|		WHEN DD.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|			THEN &VolumeM3 * DD.Count
	|		ELSE 0
	|	END AS VolumeFact,
	|	CASE
	|		WHEN DD.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered)
	|			THEN &VolumeM3 * DD.Count
	|		ELSE 0
	|	END AS ScopePlan,
	|	CASE
	|		WHEN DD.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|			THEN DD.Sum
	|		ELSE 0
	|	END AS SumReal,
	|	CASE
	|		WHEN DD.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered)
	|			THEN DD.Sum
	|		ELSE 0
	|	END AS SumPlan,
	|	0 AS QuantitySold,
	|	0 AS CostWithVAT,
	|	0 AS CostExcludingVAT_,
	|	0 AS CostLocal,
	|	0 AS ManagementCost
	|
	|INTO TTOrdersPlanFactInitialData
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences AS DD
	|		INNER JOIN TTSelectionAccordingToCustomerSOrderInDetail AS TTSelectionAccordingToCustomerSOrder
	|		ON DD.ReferenceOrder = TTSelectionAccordingToCustomerSOrder.DimensionOfExpenses
	|			AND DD.ReferenceOrder.Organization = TTSelectionAccordingToCustomerSOrder.Organization
	|			AND DD.Products = TTSelectionAccordingToCustomerSOrder.Products
	|			AND DD.Characteristic = TTSelectionAccordingToCustomerSOrder.Characteristic
	|			AND DD.Series = TTSelectionAccordingToCustomerSOrder.Series
	|			AND DD.Warehouse = TTSelectionAccordingToCustomerSOrder.Warehouse
	|			AND DD.RowCode = TTSelectionAccordingToCustomerSOrder.RowCode
	|		INNER JOIN Catalog.Products AS CatProducts
	|			ON DD.Products = CatProducts.Ref
	|WHERE
	|	DD.Active
	|	AND DD.Period <= &EndOfPeriod
	|	AND DD.RowCode <> 0
	|	AND DD.Factor IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
	|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|	AND NOT (TTSelectionAccordingToCustomerSOrder.ToReturnReusablePackage AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT VALUETYPE(DD.Recorder) = TYPE(Document.GoodsShipmentToCustomer)
	|
	|UNION ALL
	|
	// Cost of goods sold of the previous period and sales adjustments.
	|SELECT
	|	2 AS SourceCode,
	|	DD.Recorder AS Recorder,
	|	DD.AccountingDimensionByPartners.Organization AS Organization,
	|	DD.SalesOrder AS SalesOrder,
	|	TTSelectionAccordingToCustomerSOrder.LineOfBusiness AS LineOfBusiness,
	|	DD.ItemsLocationAttributes.Products AS Products,
	|	DD.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	0 AS RowCode,
	|	(CASE
	|		WHEN DD.ItemsLocationAttributes.Products.ItemsType IN (
	|				VALUE(Enum.ItemsTypes.OperationService),
	|				VALUE(Enum.ItemsTypes.Work_5))
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE DD.Warehouse END) AS Warehouse,
	|	DD.ItemsLocationAttributes.Series AS Series,
	|	MAX(DD.Period) AS Period,
	|	TRUE AS Real,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|		 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN DD.Count
	|		ELSE 0 END) AS CountReal,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|			THEN DD.Count
	|		ELSE 0 END) AS CountPlan,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|		 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN &Weight * DD.Count
	|		ELSE 0 END) AS WeightFact,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|			THEN &Weight * DD.Count
	|		ELSE 0 END) AS WeightPlan,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|		 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN &VolumeM3 * DD.Count
	|		ELSE 0 END) AS VolumeFact,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|			THEN &VolumeM3 * DD.Count
	|		ELSE 0 END) AS ScopePlan,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|		 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN DD.RevenueAmount
	|		ELSE 0 END) AS SumReal,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|			THEN DD.RevenueAmount
	|		ELSE 0 END) AS SumPlan,
	|	SUM(DD.Count) AS QuantitySold,
	|	SUM(DD.Cost
	|		+ DD.AddExpensesForGoods
	|		+ DD.LaborCosts
	|		+ DD.ItemizedFixedCostsIncludingVAT
	|		+ DD.ItemizedVariableCostsIncludingVAT) AS CostWithVAT,
	|	SUM(DD.CostExcludingVAT
	|		+ DD.AdditionalExpensesExcludingVAT
	|		+ DD.LaborCosts
	|		+ DD.ItemizedFixedCostsExcludingVAT
	|		+ DD.ItemizedVariableCostsExcludingVAT) AS CostExcludingVAT_,
	|	SUM(DD.LocalCost
	|		+ DD.AddExpensesLocal
	|		+ DD.LaborCostsLocal
	|		+ DD.ItemizedFixedCostsCompl
	|		+ DD.ItemizedVariableCostsCompl) AS CostLocal,
	|	SUM(DD.CostMan
	|		+ DD.AddExpensesMan
	|		+ DD.LaborCostsMan
	|		+ DD.ItemizedFixedCostsManag
	|		+ DD.ItemizedVariableCostsManag) AS ManagementCost
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS DD
	|
	|	INNER JOIN TTSelectionAccordingToCustomerSOrder AS TTSelectionAccordingToCustomerSOrder
	|	ON TTSelectionAccordingToCustomerSOrder.DimensionOfExpenses = DD.SalesOrder
	|		AND TTSelectionAccordingToCustomerSOrder.Organization = DD.AccountingDimensionByPartners.Organization
	|
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|	ON DD.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		
	|	LEFT JOIN TTSelectionByCustomerSOrderIsMinimized AS TTSelectionByCustomerSOrderIsMinimized
	|	ON TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses = DD.SalesOrder
	|		AND TTSelectionByCustomerSOrderIsMinimized.Organization = DD.AccountingDimensionByPartners.Organization
	|		AND TTSelectionByCustomerSOrderIsMinimized.Products = InventoryLocationAttributeKeys.Products
	|		AND TTSelectionByCustomerSOrderIsMinimized.Characteristic = InventoryLocationAttributeKeys.Characteristic
	|		AND TTSelectionByCustomerSOrderIsMinimized.Warehouse = InventoryLocationAttributeKeys.StorageLocation
	|		AND (TTSelectionByCustomerSOrderIsMinimized.Series = InventoryLocationAttributeKeys.Series
	|			OR NOT TTSelectionByCustomerSOrderIsMinimized.BatchIsSpecified)
	|
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON DD.ItemsLocationAttributes.Products = CatProducts.Ref
	|WHERE
	|	DD.Active
	|	AND DD.Period < &BeginOfPeriod
	|
	|GROUP BY
	|	DD.Recorder,
	|	DD.AccountingDimensionByPartners.Organization,
	|	DD.SalesOrder,
	|	TTSelectionAccordingToCustomerSOrder.LineOfBusiness,
	|	DD.ItemsLocationAttributes.Products,
	|	DD.ItemsLocationAttributes.Characteristic,
	|	(CASE
	|		WHEN DD.ItemsLocationAttributes.Products.ItemsType IN (
	|				VALUE(Enum.ItemsTypes.OperationService),
	|				VALUE(Enum.ItemsTypes.Work_5))
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE DD.Warehouse END), // Warehouse
	|	DD.ItemsLocationAttributes.Series
	|
	|UNION ALL
	|
	// Cost of goods sold for the current period and sales adjustments.
	|SELECT
	|	3 AS SourceCode,
	|	DD.Recorder AS Recorder,
	|	DD.AccountingDimensionByPartners.Organization AS Organization,
	|	DD.SalesOrder AS SalesOrder,
	|	TTSelectionAccordingToCustomerSOrder.LineOfBusiness AS LineOfBusiness,
	|	DD.ItemsLocationAttributes.Products AS Products,
	|	DD.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	0 AS RowCode,
	|	(CASE
	|		WHEN DD.ItemsLocationAttributes.Products.ItemsType IN (
	|				VALUE(Enum.ItemsTypes.OperationService),
	|				VALUE(Enum.ItemsTypes.Work_5))
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE DD.Warehouse END) AS Warehouse,
	|	DD.ItemsLocationAttributes.Series AS Series,
	|	MAX(DD.Period) AS Period,
	|	TRUE AS Real,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|		 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN DD.Count
	|		ELSE 0 END) AS CountReal,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|			THEN DD.Count
	|		ELSE 0 END) AS CountPlan,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|		 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN &Weight * DD.Count
	|		ELSE 0 END) AS WeightFact,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|			THEN &Weight * DD.Count
	|		ELSE 0 END) AS WeightPlan,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|		 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN &VolumeM3 * DD.Count
	|		ELSE 0 END) AS VolumeFact,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|			THEN &VolumeM3 * DD.Count
	|		ELSE 0 END) AS ScopePlan,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|		 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN DD.RevenueAmount
	|		ELSE 0 END) AS SumReal,
	|	SUM(CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.SaleAdjustment)
	|		 OR TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses IS NULL
	|			THEN DD.RevenueAmount
	|		ELSE 0 END) AS SumPlan,
	|	SUM(DD.Count) AS QuantitySold,
	|	SUM(DD.Cost
	|		+ DD.AddExpensesForGoods
	|		+ DD.LaborCosts
	|		+ DD.ItemizedFixedCostsIncludingVAT
	|		+ DD.ItemizedVariableCostsIncludingVAT) AS CostWithVAT,
	|	SUM(DD.CostExcludingVAT
	|		+ DD.AdditionalExpensesExcludingVAT
	|		+ DD.LaborCosts
	|		+ DD.ItemizedFixedCostsExcludingVAT
	|		+ DD.ItemizedVariableCostsExcludingVAT) AS CostExcludingVAT_,
	|	SUM(DD.LocalCost
	|		+ DD.AddExpensesLocal
	|		+ DD.LaborCostsLocal
	|		+ DD.ItemizedFixedCostsCompl
	|		+ DD.ItemizedVariableCostsCompl) AS CostLocal,
	|	SUM(DD.CostMan
	|		+ DD.AddExpensesMan
	|		+ DD.LaborCostsMan
	|		+ DD.ItemizedFixedCostsManag
	|		+ DD.ItemizedVariableCostsManag) AS ManagementCost
	|FROM
	|	TTCashEstimatedTurnoverRevenueAndCostOfSales AS DD
	|
	|	INNER JOIN TTSelectionAccordingToCustomerSOrder AS TTSelectionAccordingToCustomerSOrder
	|	ON TTSelectionAccordingToCustomerSOrder.DimensionOfExpenses = DD.SalesOrder
	|		AND TTSelectionAccordingToCustomerSOrder.Organization = DD.AccountingDimensionByPartners.Organization
	|
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|	ON DD.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		
	|	LEFT JOIN TTSelectionByCustomerSOrderIsMinimized AS TTSelectionByCustomerSOrderIsMinimized
	|	ON TTSelectionByCustomerSOrderIsMinimized.DimensionOfExpenses = DD.SalesOrder
	|		AND TTSelectionByCustomerSOrderIsMinimized.Organization = DD.AccountingDimensionByPartners.Organization
	|		AND TTSelectionByCustomerSOrderIsMinimized.Products = InventoryLocationAttributeKeys.Products
	|		AND TTSelectionByCustomerSOrderIsMinimized.Characteristic = InventoryLocationAttributeKeys.Characteristic
	|		AND TTSelectionByCustomerSOrderIsMinimized.Warehouse = InventoryLocationAttributeKeys.StorageLocation
	|		AND (TTSelectionByCustomerSOrderIsMinimized.Series = InventoryLocationAttributeKeys.Series
	|			OR NOT TTSelectionByCustomerSOrderIsMinimized.BatchIsSpecified)
	|
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON DD.ItemsLocationAttributes.Products = CatProducts.Ref
	|WHERE
	|	VALUETYPE(DD.Recorder) <> TYPE(Document.CostCalculationRecorder)
	|
	|GROUP BY
	|	DD.Recorder,
	|	DD.AccountingDimensionByPartners.Organization,
	|	DD.SalesOrder,
	|	TTSelectionAccordingToCustomerSOrder.LineOfBusiness,
	|	DD.ItemsLocationAttributes.Products,
	|	DD.ItemsLocationAttributes.CHARACTERISTIC,
	|	(CASE
	|		WHEN DD.ItemsLocationAttributes.Products.ItemsType IN (
	|				VALUE(Enum.ItemsTypes.OperationService),
	|				VALUE(Enum.ItemsTypes.Work_5))
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE DD.Warehouse END), // Warehouse
	|	DD.ItemsLocationAttributes.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.SalesOrder				AS SalesOrder,
	|	DD.LineOfBusiness	AS LineOfBusiness,
	|	DD.Organization				AS Organization,
	|	MAX(DD.Period)			AS Period,
	|	(CASE
	|		WHEN SUM(DD.QuantitySold) > SUM(DD.CountReal) THEN SUM(DD.QuantitySold)
	|		ELSE SUM(DD.CountReal)
	|	END)						AS CountReal,
	|	SUM(DD.WeightFact)			AS WeightFact,
	|	SUM(DD.VolumeFact)			AS VolumeFact,
	|	SUM(DD.SumReal)			AS SumReal,
	|	(CASE
	|		WHEN SUM(DD.QuantitySold) > SUM(DD.CountReal) THEN SUM(DD.QuantitySold)
	|		ELSE SUM(DD.CountPlan)
	|	END)						AS CountPlan,
	|	SUM(DD.WeightPlan)			AS WeightPlan,
	|	SUM(DD.ScopePlan)			AS ScopePlan,
	|	CASE 
	|		WHEN SUM(DD.SumReal) > SUM(DD.SumPlan)
	|			THEN SUM(DD.SumReal)
	|		ELSE SUM(DD.SumPlan)
	|	END						AS SumPlan,
	|	SUM(DD.CostWithVAT)	AS CostWithVAT,
	|	SUM(DD.CostExcludingVAT_) AS CostExcludingVAT_,
	|	SUM(DD.CostLocal)	AS CostLocal,
	|	SUM(DD.ManagementCost)	AS ManagementCost,
	|	(CASE
	|		WHEN SUM(DD.QuantitySold) = 0 THEN 0
	|		WHEN SUM(DD.CountPlan) = 0 THEN SUM(DD.CostWithVAT)
	// If there are refunds (sold less than the fact), we use the cost data without recalculation.
	|		WHEN SUM(DD.CountReal) > SUM(DD.QuantitySold)
	|			THEN SUM(DD.CostWithVAT)
	|		WHEN SUM(DD.QuantitySold) >= SUM(DD.CountPlan)
	|			THEN SUM(DD.CostWithVAT)
	|		ELSE (SUM(DD.CostWithVAT) / SUM(DD.QuantitySold)) * SUM(DD.CountPlan)
	|	END) AS CostWithVATPlan,
	|	(CASE
	|		WHEN SUM(DD.QuantitySold) = 0 THEN 0
	|		WHEN SUM(DD.CountPlan) = 0 THEN SUM(DD.CostExcludingVAT_)
	|		WHEN SUM(DD.CountReal) > SUM(DD.QuantitySold)
	|			THEN SUM(DD.CostExcludingVAT_)
	|		WHEN SUM(DD.QuantitySold) >= SUM(DD.CountPlan)
	|			THEN SUM(DD.CostExcludingVAT_)
	|		ELSE (SUM(DD.CostExcludingVAT_) / SUM(DD.QuantitySold)) * SUM(DD.CountPlan)
	|	END) AS CostWithoutVATPlan,
	|	(CASE
	|		WHEN SUM(DD.QuantitySold) = 0 THEN 0
	|		WHEN SUM(DD.CountPlan) = 0 THEN SUM(DD.CostLocal)
	|		WHEN SUM(DD.CountReal) > SUM(DD.QuantitySold)
	|			THEN SUM(DD.CostLocal)
	|		WHEN SUM(DD.QuantitySold) >= SUM(DD.CountPlan)
	|			THEN SUM(DD.CostLocal)
	|		ELSE SUM(DD.CostLocal) / SUM(DD.QuantitySold) * SUM(DD.CountPlan)
	|	END) AS LocalPlanCostOfProduction,
	|	(CASE
	|		WHEN SUM(DD.QuantitySold) = 0 THEN 0
	|		WHEN SUM(DD.CountPlan) = 0 THEN SUM(DD.ManagementCost)
	|		WHEN SUM(DD.CountReal) > SUM(DD.QuantitySold)
	|			THEN SUM(DD.ManagementCost)
	|		WHEN SUM(DD.QuantitySold) >= SUM(DD.CountPlan)
	|			THEN SUM(DD.ManagementCost)
	|		ELSE SUM(DD.ManagementCost) / SUM(DD.QuantitySold) * SUM(DD.CountPlan)
	|	 END) AS CostOfManPlan
	|
	|INTO TTPlanFactByOrder
	|FROM
	|	TTOrdersPlanFactInitialData AS DD
	|
	|GROUP BY
	|	DD.Organization,
	|	DD.SalesOrder,
	|	DD.LineOfBusiness
	|
	|INDEX BY
	|	SalesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Recorder AS Recorder,
	|	DD.SalesOrder AS SalesOrder,
	|	DD.LineOfBusiness	AS LineOfBusiness,
	|	DD.Products AS Products,
	|	DD.Characteristic AS Characteristic,
	|	DD.Warehouse AS Warehouse,
	|	DD.Series AS Series,
	|	(CASE
	|		WHEN SUM(DD.QuantitySold) > SUM(DD.CountReal) THEN SUM(DD.QuantitySold)
	|		ELSE SUM(DD.CountReal)
	|	END) AS Count,
	|	SUM(DD.SumReal) AS Sum,
	|	CASE
	|		WHEN MAX(PlanFact.CountPlan) = 0 THEN 0 
	|		WHEN SUM(DD.QuantitySold) > SUM(DD.CountReal)
	|			THEN CAST(SUM(DD.QuantitySold) AS NUMBER(28,10)) / MAX(PlanFact.CountPlan)
	|		ELSE CAST(SUM(DD.CountReal) AS NUMBER(28,10)) / MAX(PlanFact.CountPlan)
	|	END AS NumberOfShares,
	|	CASE
	|		WHEN MAX(PlanFact.WeightPlan) = 0 THEN 0
	|		ELSE CAST(SUM(DD.WeightFact) AS NUMBER(28,10)) / MAX(PlanFact.WeightPlan)
	|	END AS WeightFraction,
	|	CASE WHEN MAX(PlanFact.ScopePlan) = 0 THEN 0
	|		ELSE CAST(SUM(DD.VolumeFact) AS NUMBER(28,10)) / MAX(PlanFact.ScopePlan)
	|	END AS VolumeShare,
	|	CASE WHEN MAX(PlanFact.SumPlan) = 0 THEN 0
	|		ELSE CAST(SUM(DD.SumReal) AS NUMBER(28,10)) / MAX(PlanFact.SumPlan)
	|	END AS AmountShare,
	|	SUM(DD.CostWithVAT)	AS CostWithVAT,
	|	SUM(DD.CostExcludingVAT_) AS CostExcludingVAT_,
	|	SUM(DD.CostLocal)	AS CostLocal,
	|	SUM(DD.ManagementCost)	AS ManagementCost,
	|	CASE
	|		WHEN MAX(PlanFact.CostWithVATPlan) = 0 THEN 0
	|		ELSE CAST(SUM(DD.CostWithVAT) AS NUMBER(28,10)) / MAX(PlanFact.CostWithVATPlan)
	|	END AS CostWithVATShare,
	|	CASE
	|		WHEN MAX(PlanFact.CostWithoutVATPlan) = 0 THEN 0
	|		ELSE CAST(SUM(DD.CostExcludingVAT_) AS NUMBER(28,10)) / MAX(PlanFact.CostWithoutVATPlan)
	|	END AS CostWithoutVATShare,
	|	CASE
	|		WHEN MAX(PlanFact.LocalPlanCostOfProduction) = 0 THEN 0
	|		ELSE CAST(SUM(DD.CostLocal) AS NUMBER(28,10)) / MAX(PlanFact.LocalPlanCostOfProduction)
	|	END AS CostOfLocalShare,
	|	CASE
	|		WHEN MAX(PlanFact.CostOfManPlan) = 0 THEN 0
	|		ELSE CAST(SUM(DD.ManagementCost) AS NUMBER(28,10)) / MAX(PlanFact.CostOfManPlan)
	|	END AS CostOfManSShare
	|
	|INTO TTSharesOnRequest
	|FROM
	|	TTOrdersPlanFactInitialData AS DD
	|	INNER JOIN TTPlanFactByOrder AS PlanFact
	|		ON DD.SalesOrder = PlanFact.SalesOrder
	|		AND DD.LineOfBusiness = PlanFact.LineOfBusiness
	|WHERE
	|	DD.Real
	// When using the full distribution option for disposals in past periods, selling expenses
	// are distributed only if there is a distribution base in the current month.
	// For past periods, the distribution is performed at the stage of preparing data for the resolution of the_accounting_the values of the previous periods.
	|	AND NOT (PlanFact.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
	|		AND PlanFact.Period < &BeginOfPeriod)
	|
	|GROUP BY
	|	DD.Recorder,
	|	DD.SalesOrder,
	|	DD.LineOfBusiness,
	|	DD.Products,
	|	DD.Characteristic,
	|	DD.Warehouse,
	|	DD.Series
	|
	|INDEX BY
	|	SalesOrder,
	|	Products,
	|	Characteristic,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Distribution according to the data of the previous period.
	|SELECT
	|	1 AS SourceCode,
	|	DD.Period AS Period,
	|	DD.Recorder AS Recorder,
	|	Shares.LineOfBusiness AS LineOfBusiness,
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DD.SalesOrder AS SalesOrder,
	|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	DimensionKeysOfAccountingByPartners.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.InventoryType AS InventoryType,
	|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DD.AccountingSection AS AccountingSection,
	|	DD.Lot AS Lot,
	|	DD.LotVendorAttributes AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	DD.VATActivityType AS VATActivityType,
	|	DD.Manager AS Manager,
	|	DD.Warehouse AS Warehouse,
	|	DD.Terms AS Terms,
	|	DD.Contract AS Contract,
	|	DD.BusinessOperation AS BusinessOperation,
	|	DD.SetAccountingDimension AS SetAccountingDimension,
	|	DD.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|	DD.ProductLineOfBusiness AS ProductLineOfBusiness,
	|	DD.VATTaxation AS VATTaxation,
	|	DD.ARAPCurrency AS ARAPCurrency,
	|	DD.DocumentCurrency AS DocumentCurrency,
	|	DD.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup,
	|	DD.DocumentRegisterRecords AS DocumentRegisterRecords,
	|	DD.CalculationOfCost AS CalculationOfCost,
	|	DD.LotCalculation AS LotCalculation,
	|	DD.FinRecordID AS FinRecordID,
	|	DD.MonthEndClosingMode AS MonthEndClosingMode,
	|	DD.ReversingEntry AS ReversingEntry,
	|	DD.VATRate AS VATRate,
	|	(CASE
	|		WHEN Shares.Count = 0 THEN 0
	|		ELSE (DD.Count / Shares.Count) * Shares.NumberOfShares
	|	END) AS NumberOfShares,
	|	(CASE
	|		WHEN Shares.Count = 0 THEN 0
	|		ELSE (DD.Count / Shares.Count) * Shares.WeightFraction
	|	END) AS WeightFraction,
	|	(CASE
	|		WHEN Shares.Count = 0 THEN 0
	|		ELSE (DD.Count / Shares.Count) * Shares.VolumeShare
	|	END) AS VolumeShare,
	|	(CASE
	|		WHEN Shares.Sum = 0 OR DD.AmountInARAPCurrency = 0 THEN 0
	|		ELSE (DD.AmountInARAPCurrency / Shares.Sum) * Shares.AmountShare
	|	END) AS AmountShare,
	|	(CASE
	|		WHEN Shares.CostWithVAT = 0 THEN 0
	|		ELSE ((DD.Cost
	|			+ DD.AddExpensesForGoods
	|			+ DD.LaborCosts
	|			+ DD.ItemizedFixedCostsIncludingVAT
	|			+ DD.ItemizedVariableCostsIncludingVAT)
	|			/ Shares.CostWithVAT) * Shares.CostWithVATShare END) AS CostWithVATShare,
	|	(CASE
	|		WHEN Shares.CostExcludingVAT_ = 0 THEN 0
	|		ELSE ((DD.CostExcludingVAT
	|			+ DD.AdditionalExpensesExcludingVAT
	|			+ DD.LaborCosts
	|			+ DD.ItemizedFixedCostsExcludingVAT
	|			+ DD.ItemizedVariableCostsExcludingVAT)
	|			/ Shares.CostExcludingVAT_) * Shares.CostWithoutVATShare END) AS CostWithoutVATShare,
	|	(CASE
	|		WHEN Shares.CostLocal = 0 THEN 0
	|		ELSE ((DD.LocalCost
	|			+ DD.AddExpensesLocal
	|			+ DD.LaborCostsLocal
	|			+ DD.ItemizedFixedCostsCompl
	|			+ DD.ItemizedVariableCostsCompl)
	|			/ Shares.CostLocal) * Shares.CostOfLocalShare END) AS CostOfLocalShare,
	|	(CASE
	|		WHEN Shares.ManagementCost = 0 THEN 0
	|		ELSE ((DD.CostMan
	|			+ DD.AddExpensesMan
	|			+ DD.LaborCostsMan
	|			+ DD.ItemizedFixedCostsManag
	|			+ DD.ItemizedVariableCostsManag)
	|			/ Shares.ManagementCost) * Shares.CostOfManSShare END) AS CostOfManSShare
	|
	|INTO TTDistributionBaseAccordingToCustomerSOrder
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS DD
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON DD.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			ON DD.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|		INNER JOIN TTSharesOnRequest AS Shares
	|		ON DD.SalesOrder = Shares.SalesOrder
	|			AND DD.Recorder = Shares.Recorder
	|			AND (Shares.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|				OR DD.CounterpartyLineOfBusiness = Shares.LineOfBusiness)
	|			AND (Shares.Warehouse = VALUE(Catalog.Warehouses.EmptyRef) OR DD.Warehouse = Shares.Warehouse)
	|			AND InventoryLocationAttributeKeys.Products = Shares.Products
	|			AND InventoryLocationAttributeKeys.Characteristic = Shares.Characteristic
	|			AND InventoryLocationAttributeKeys.Series = Shares.Series
	|WHERE
	|	DD.Active
	|	AND DD.Period < &BeginOfPeriod
	|	AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.ExpenseAllocationOnCostOfGoodsSold)
	|
	|UNION ALL
	|
	// distribution according to the Cur period data.
	|SELECT
	|	2 AS SourceCode,
	|	DD.Period AS Period,
	|	DD.Recorder AS Recorder,
	|	Shares.LineOfBusiness AS LineOfBusiness,
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DD.SalesOrder AS SalesOrder,
	|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	DimensionKeysOfAccountingByPartners.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.InventoryType AS InventoryType,
	|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DD.AccountingSection AS AccountingSection,
	|	DD.Lot AS Lot,
	|	DD.LotVendorAttributes AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	DD.VATActivityType AS VATActivityType,
	|	DD.Manager AS Manager,
	|	DD.Warehouse AS Warehouse,
	|	DD.Terms AS Terms,
	|	DD.Contract AS Contract,
	|	DD.BusinessOperation AS BusinessOperation,
	|	DD.SetAccountingDimension AS SetAccountingDimension,
	|	DD.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|	DD.ProductLineOfBusiness AS ProductLineOfBusiness,
	|	DD.VATTaxation AS VATTaxation,
	|	DD.ARAPCurrency AS ARAPCurrency,
	|	DD.DocumentCurrency AS DocumentCurrency,
	|	DD.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup,
	|	DD.DocumentRegisterRecords AS DocumentRegisterRecords,
	|	DD.CalculationOfCost AS CalculationOfCost,
	|	DD.LotCalculation AS LotCalculation,
	|	DD.FinRecordID AS FinRecordID,
	|	DD.MonthEndClosingMode AS MonthEndClosingMode,
	|	DD.ReversingEntry AS ReversingEntry,
	|	DD.VATRate AS VATRate,
	|	(CASE
	|		WHEN Shares.Count = 0 THEN 0
	|		ELSE (DD.Count / Shares.Count) * Shares.NumberOfShares
	|	END) AS NumberOfShares,
	|	(CASE
	|		WHEN Shares.Count = 0 THEN 0
	|		ELSE (DD.Count / Shares.Count) * Shares.WeightFraction
	|	END) AS WeightFraction,
	|	(CASE
	|		WHEN Shares.Count = 0 THEN 0
	|		ELSE (DD.Count / Shares.Count) * Shares.VolumeShare
	|	END) AS VolumeShare,
	|	(CASE
	|		WHEN Shares.Sum = 0 OR DD.AmountInARAPCurrency = 0 THEN 0
	|		ELSE (DD.AmountInARAPCurrency / Shares.Sum) * Shares.AmountShare
	|	END) AS AmountShare,
	|	(CASE
	|		WHEN Shares.CostWithVAT = 0 THEN 0
	|		ELSE ((DD.Cost
	|			+ DD.AddExpensesForGoods
	|			+ DD.LaborCosts
	|			+ DD.ItemizedFixedCostsIncludingVAT
	|			+ DD.ItemizedVariableCostsIncludingVAT)
	|			/ Shares.CostWithVAT) * Shares.CostWithVATShare END) AS CostWithVATShare,
	|	(CASE
	|		WHEN Shares.CostExcludingVAT_ = 0 THEN 0
	|		ELSE ((DD.CostExcludingVAT
	|			+ DD.AdditionalExpensesExcludingVAT
	|			+ DD.LaborCosts
	|			+ DD.ItemizedFixedCostsExcludingVAT
	|			+ DD.ItemizedVariableCostsExcludingVAT)
	|			/ Shares.CostExcludingVAT_) * Shares.CostWithoutVATShare END) AS CostWithoutVATShare,
	|	(CASE
	|		WHEN Shares.CostLocal = 0 THEN 0
	|		ELSE ((DD.LocalCost
	|			+ DD.AddExpensesLocal
	|			+ DD.LaborCostsLocal
	|			+ DD.ItemizedFixedCostsCompl
	|			+ DD.ItemizedVariableCostsCompl)
	|			/ Shares.CostLocal) * Shares.CostOfLocalShare END) AS CostOfLocalShare,
	|	(CASE
	|		WHEN Shares.ManagementCost = 0 THEN 0
	|		ELSE ((DD.CostMan
	|			+ DD.AddExpensesMan
	|			+ DD.LaborCostsMan
	|			+ DD.ItemizedFixedCostsManag
	|			+ DD.ItemizedVariableCostsManag)
	|			/ Shares.ManagementCost) * Shares.CostOfManSShare END) AS CostOfManSShare
	|
	|FROM
	|	TTCashEstimatedTurnoverRevenueAndCostOfSales AS DD
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			ON DD.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			ON DD.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|		INNER JOIN TTSharesOnRequest AS Shares
	|		ON DD.SalesOrder = Shares.SalesOrder
	|			AND DD.Recorder = Shares.Recorder
	|			AND (Shares.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|				OR DD.CounterpartyLineOfBusiness = Shares.LineOfBusiness)
	|			AND (Shares.Warehouse = VALUE(Catalog.Warehouses.EmptyRef) OR DD.Warehouse = Shares.Warehouse)
	|			AND InventoryLocationAttributeKeys.Products = Shares.Products
	|			AND InventoryLocationAttributeKeys.Characteristic = Shares.Characteristic
	|			AND InventoryLocationAttributeKeys.Series = Shares.Series
	|WHERE
	|	DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.ExpenseAllocationOnCostOfGoodsSold)
	|
	|INDEX BY
	|	SalesOrder,
	|	LineOfBusiness,
	|	Organization
	|;";
	
	Return CostCalculationAppliedAlgorithms.InsertWeightAndVolumeTemplatesIntoQueryText(QueryText);
	
EndFunction

Function RequestTextPreparingSalesCostAllocationData() 
	
	QueryText = "SELECT 
	|	T.Ref AS ExpenseItem,
	|	T.CostAllocationOptionManag AS CostAllocationOptionManag,
	|	T.CostAllocationOptionLocal AS CostAllocationOptionLocal,
	|	T.CostAllocationOptionTax AS CostAllocationOptionTax,
	|	T.CostAllocationRuleToCostOfGoodsSoldMan AS CostAllocationRuleToCostOfGoodsSoldMan,
	|	T.CostAllocationRuleToCostOfGoodsSoldLocal AS CostAllocationRuleToCostOfGoodsSoldLocal,
	|	T.EnteredInTaxAccounting AS EnteredInTaxAccounting
	|	
	|INTO ItemsToBeDistributedForSale
	|
	|FROM ChartOfCharacteristicTypes.ExpenseItems AS T
	|
	|WHERE
	|	T.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|	OR
	|		T.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|		
	|INDEX BY ExpenseItem;
	|
	|SELECT
    |	Expenses.Organization AS Organization,
    |	Expenses.Department AS Department,
    |	Expenses.LineOfBusiness AS LineOfBusiness,
    |	Expenses.ExpenseItem AS ExpenseItem,
    |	Expenses.DimensionOfExpenses AS DimensionOfExpenses
	|INTO BalanceOfExpensesOnOrders
	|
    |FROM
	|	TTCashSettlementBalancesOtherExpenses AS Expenses
	|		INNER JOIN ItemsToBeDistributedForSale AS T
	|		ON Expenses.ExpenseItem = T.ExpenseItem
	|
    |WHERE
    |	Expenses.DimensionOfExpenses REFS Document.SalesOrder
	|
	|UNION ALL
	|
	|SELECT
	|	Expenses.Organization AS Organization,
	|	Expenses.Department AS Department,
	|	Expenses.LineOfBusiness AS LineOfBusiness,
	|	Expenses.ExpenseItem AS ExpenseItem,
	|	Expenses.DimensionOfExpenses AS DimensionOfExpenses
	|FROM
	|	TTCashSettlementBalancesOtherExpenses AS Expenses
	|		INNER JOIN ItemsToBeDistributedForSale AS T
	|		ON Expenses.ExpenseItem = T.ExpenseItem
	|WHERE
	|	VALUETYPE(Expenses.DimensionOfExpenses) = TYPE(Document.MaterialProviderOrder2_5)
	|
	|INDEX BY
	|	Organization,
	|	Department,
	|	LineOfBusiness,
	|	ExpenseItem,
	|	DimensionOfExpenses;
	|
	|SELECT
	|	Expenses.Organization,
	|	Expenses.Department,
	|	Expenses.LineOfBusiness,
	|	Expenses.ExpenseItem,
	|	Expenses.DimensionOfExpenses,
	|	MAX(CASE
	|		WHEN T.CostAllocationRuleToCostOfGoodsSoldMan = 
	|				VALUE(Enum.RulesOfAllocationToCostOfGoodsSold.InProportionToItemCost)
	|			THEN 1
	|		ELSE 0
	|	END) AS ManSRevenueRatio,
	|	MAX(CASE
	|		WHEN T.CostAllocationRuleToCostOfGoodsSoldMan = 
	|				VALUE(Enum.RulesOfAllocationToCostOfGoodsSold.InProportionToProductCost)
	|			THEN 1
	|		ELSE 0
	|	END) AS ManCostRatio,
	|	MAX(CASE
	|		WHEN T.CostAllocationRuleToCostOfGoodsSoldMan = 
	|				VALUE(Enum.RulesOfAllocationToCostOfGoodsSold.InProportionToProductQuantity)
	|			THEN 1
	|		ELSE 0
	|	END) AS CoefficientForNumberOfMen,
	|	MAX(CASE
	|		WHEN T.CostAllocationRuleToCostOfGoodsSoldMan = 
	|				VALUE(Enum.RulesOfAllocationToCostOfGoodsSold.InProportionToItemsWeight)
	|			THEN 1
	|		ELSE 0
	|	END) AS ManSWeightRatio,
	|	MAX(CASE
	|		WHEN T.CostAllocationRuleToCostOfGoodsSoldMan = 
	|				VALUE(Enum.RulesOfAllocationToCostOfGoodsSold.InProportionToItemsVolume)
	|			THEN 1
	|		ELSE 0
	|	END) AS ManSVolumeCoefficient,
	|	MAX(CASE
	|		WHEN T.CostAllocationRuleToCostOfGoodsSoldLocal = 
	|				VALUE(Enum.RulesOfAllocationToCostOfGoodsSold.InProportionToItemCost)
	|			THEN 1
	|		ELSE 0
	|	END) AS LocalRevenueCoefficient,
	|	MAX(CASE
	|		WHEN T.CostAllocationRuleToCostOfGoodsSoldLocal = 
	|				VALUE(Enum.RulesOfAllocationToCostOfGoodsSold.InProportionToProductCost)
	|			THEN 1
	|		ELSE 0
	|	END) AS LocalCostRatio,
	|	MAX(CASE
	|		WHEN T.CostAllocationRuleToCostOfGoodsSoldLocal = 
	|				VALUE(Enum.RulesOfAllocationToCostOfGoodsSold.InProportionToProductQuantity)
	|			THEN 1
	|		ELSE 0
	|	END) AS CoefficientForNumberOfLocal,
	|	MAX(CASE
	|		WHEN T.CostAllocationRuleToCostOfGoodsSoldLocal = 
	|				VALUE(Enum.RulesOfAllocationToCostOfGoodsSold.InProportionToItemsWeight)
	|			THEN 1
	|		ELSE 0
	|	END) AS LocalWeightRatio,
	|	MAX(CASE
	|		WHEN T.CostAllocationRuleToCostOfGoodsSoldLocal = 
	|				VALUE(Enum.RulesOfAllocationToCostOfGoodsSold.InProportionToItemsVolume)
	|			THEN 1
	|		ELSE 0
	|	END) AS LocalVolumeCoefficient,
	|	SUM(CASE
	|		WHEN T.CostAllocationOptionManag = 
	|				VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|			THEN Expenses.Sum
	|		ELSE 0
	|	END) AS Sum,
	|	SUM(CASE
	|		WHEN T.CostAllocationOptionManag = 
	|				VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|			THEN Expenses.AmountExcludingVAT
	|		ELSE 0
	|	END) AS AmountExcludingVAT,
	|	SUM(CASE
	|		WHEN T.CostAllocationOptionManag = 
	|				VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|			THEN Expenses.SumMan
	|		ELSE 0
	|	END) AS SumMan,
	|	SUM(CASE
	|		WHEN T.CostAllocationOptionLocal = 
	|				VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|			THEN Expenses.SumCompl
	|		ELSE 0
	|	END) AS SumCompl,
	|	SUM(CASE
	|			WHEN T.CostAllocationOptionTax = 
	|					VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|				THEN Expenses.PermanentDifference
	|			WHEN T.CostAllocationOptionLocal = 
	|					VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|					AND NOT T.EnteredInTaxAccounting
	|				THEN Expenses.SumCompl
	|			ELSE 0
	|		END) AS PermanentDifference,
	|	SUM(CASE
	|			WHEN T.CostAllocationOptionTax = 
	|					VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|				THEN Expenses.CostTD
	|			WHEN T.CostAllocationOptionLocal = 
	|					VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|					AND T.EnteredInTaxAccounting
	|				THEN Expenses.SumCompl
	|			ELSE 0
	|		END) AS CostTD
	|
	|INTO ExpensesToBeDistributedForSale
	|
	|FROM
	|	&SourcesOfExpenses AS Expenses
	|		INNER JOIN ItemsToBeDistributedForSale AS T
	|		ON Expenses.ExpenseItem = T.ExpenseItem
	|
	|GROUP BY
	|	Expenses.Organization,
	|	Expenses.Department,
	|	Expenses.LineOfBusiness,
	|	Expenses.ExpenseItem,
	|	Expenses.DimensionOfExpenses
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	Organization
	|;";
	
	ArrayOfSources = New Array;
	QueryTextSource1 = "
	|SELECT
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	DD.Sum AS Sum,
	|	DD.AmountExcludingVAT AS AmountExcludingVAT,
	|	DD.SumCompl AS SumCompl,
	|	DD.PermanentDifference AS PermanentDifference,
	|	DD.CostTD AS CostTD,
	|	DD.SumMan AS SumMan
	|FROM
	|	TTCashSettlementBalancesOtherExpenses AS DD
	|WHERE
	|	TRUE IN (
	|		SELECT TOP 1 TRUE FROM ItemsToBeDistributedForSale AS T
	|		WHERE DD.ExpenseItem = T.ExpenseItem
	|	)";
	ArrayOfSources.Add(QueryTextSource1);
	QueryTextSource1 = "
	|SELECT
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.LineOfBusiness AS LineOfBusiness,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	DD.Sum AS Sum,
	|	DD.AmountExcludingVAT AS AmountExcludingVAT,
	|	DD.SumCompl AS SumCompl,
	|	DD.PermanentDifference AS PermanentDifference,
	|	DD.CostTD AS CostTD,
	|	DD.SumMan AS SumMan
	|FROM
	|	AccumulationRegister.OtherExpenses AS DD
	|WHERE
	|	DD.Period < &BeginOfPeriod
	|	AND DD.Active
	|	AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpenseAllocationOnCostOfGoodsSold)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND TRUE IN (SELECT TOP 1 TRUE FROM BalanceOfExpensesOnOrders AS Balance
	|		WHERE	DD.Organization = Balance.Organization
	|			AND DD.Department = Balance.Department
	|			AND DD.LineOfBusiness = Balance.LineOfBusiness
	|			AND DD.ExpenseItem = Balance.ExpenseItem
	|			AND DD.DimensionOfExpenses = Balance.DimensionOfExpenses)";
	ArrayOfSources.Add(QueryTextSource1);
	
	QueryText = StrReplace(QueryText, "&SourcesOfExpenses", "("+MergeTexts(ArrayOfSources)+")");
	Return QueryText;
	
EndFunction

Function RequestTextSelectionAllocationOfExpensesForClientSOrder() 
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Expenses.Organization,
	|	Expenses.Department AS ExpensesBusinessUnit,
	|	Expenses.LineOfBusiness,
	|	Expenses.ExpenseItem,
	|	Expenses.DimensionOfExpenses,
	|	&EndOfPeriod AS Period,
	|	Base.Recorder,
	|	Base.ItemsLocationAttributes,
	|	Base.SalesOrder,
	|	Base.AccountingDimensionByPartners,
	|	Base.Department AS RevenueDivision,
	|	Base.InventoryType,
	|	Base.InventoryOwnerAttribute,
	|	Base.AccountingSection,
	|	Base.Lot,
	|	Base.LotVendorAttributes,
	|	Base.FinancialAccountingDimension,
	|	Base.VATActivityType,
	|	Base.Manager,
	|	Base.Warehouse,
	|	Base.Terms,
	|	Base.Contract,
	|	Base.SetAccountingDimension,
	|	Base.CounterpartyLineOfBusiness,
	|	Base.ProductLineOfBusiness,
	|	Base.VATTaxation,
	|	Base.ARAPCurrency,
	|	Base.DocumentCurrency,
	|	Base.SourceOfProductFinancialAccountingGroup,
	|	Base.ReversingEntry,
	|	Base.VATRate,
	|	CAST(Expenses.Sum * (Expenses.ManSRevenueRatio * Base.AmountShare + Expenses.CoefficientForNumberOfMen * Base.NumberOfShares
	|		+ Expenses.ManSWeightRatio * Base.WeightFraction + Expenses.ManSVolumeCoefficient * Base.VolumeShare
	|		+ Expenses.ManCostRatio * Base.CostWithVATShare) AS NUMBER(31,2)) AS Sum,
	|	CAST(Expenses.AmountExcludingVAT * (Expenses.ManSRevenueRatio * Base.AmountShare + Expenses.CoefficientForNumberOfMen * Base.NumberOfShares
	|		+ Expenses.ManSWeightRatio * Base.WeightFraction + Expenses.ManSVolumeCoefficient * Base.VolumeShare
	|		+ Expenses.ManCostRatio * Base.CostWithoutVATShare) AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	CAST(Expenses.SumMan * (Expenses.ManSRevenueRatio * Base.AmountShare + Expenses.CoefficientForNumberOfMen * Base.NumberOfShares
	|		+ Expenses.ManSWeightRatio * Base.WeightFraction + Expenses.ManSVolumeCoefficient * Base.VolumeShare
	|		+ Expenses.ManCostRatio * Base.CostOfManSShare) AS NUMBER(31,2)) AS SumMan,
	|	CAST(Expenses.SumCompl * (Expenses.LocalRevenueCoefficient * Base.AmountShare + Expenses.CoefficientForNumberOfLocal * Base.NumberOfShares
	|		+ Expenses.LocalWeightRatio * Base.WeightFraction + Expenses.LocalVolumeCoefficient * Base.VolumeShare
	|		+ Expenses.LocalCostRatio * Base.CostOfLocalShare) AS NUMBER(31,2)) AS SumCompl,
	|	CAST(Expenses.PermanentDifference * (Expenses.LocalRevenueCoefficient * Base.AmountShare + Expenses.CoefficientForNumberOfLocal * Base.NumberOfShares
	|		+ Expenses.LocalWeightRatio * Base.WeightFraction + Expenses.LocalVolumeCoefficient * Base.VolumeShare
	|		+ Expenses.LocalCostRatio * Base.CostOfLocalShare) AS NUMBER(31,2)) AS PermanentDifference,
	|	CAST(Expenses.CostTD * (Expenses.LocalRevenueCoefficient * Base.AmountShare + Expenses.CoefficientForNumberOfLocal * Base.NumberOfShares
	|		+ Expenses.LocalWeightRatio * Base.WeightFraction + Expenses.LocalVolumeCoefficient * Base.VolumeShare
	|		+ Expenses.LocalCostRatio * Base.CostOfLocalShare) AS NUMBER(31,2)) AS CostTD
	|INTO DistributionToCustomerOrder
	|FROM
	|	ExpensesToBeDistributedForSale AS Expenses
	|		INNER JOIN TTDistributionBaseAccordingToCustomerSOrder AS Base
	|		ON	Expenses.DimensionOfExpenses = Base.SalesOrder
	|			AND Expenses.Organization = Base.Organization
	|			AND Expenses.LineOfBusiness IN (
	|				Base.CounterpartyLineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT
	|	Expenses.Organization,
	|	Expenses.Department AS ExpensesBusinessUnit,
	|	Expenses.LineOfBusiness,
	|	Expenses.ExpenseItem,
	|	Expenses.DimensionOfExpenses,
	|	&EndOfPeriod,
	|	DD.Recorder,
	|	DD.ItemsLocationAttributes,
	|	DD.SalesOrder,
	|	DD.AccountingDimensionByPartners,
	|	DD.Department AS RevenueDivision,
	|	DD.InventoryType,
	|	DD.InventoryOwnerAttribute,
	|	DD.AccountingSection,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.FinancialAccountingDimension,
	|	DD.VATActivityType,
	|	DD.Manager,
	|	DD.Warehouse,
	|	DD.Terms,
	|	DD.Contract,
	|	DD.SetAccountingDimension,
	|	DD.CounterpartyLineOfBusiness,
	|	DD.ProductLineOfBusiness,
	|	DD.VATTaxation,
	|	DD.ARAPCurrency,
	|	DD.DocumentCurrency,
	|	DD.SourceOfProductFinancialAccountingGroup,
	|	DD.ReversingEntry,
	|	DD.VATRate,
	|	-DD.SellingExpensesIncludingVAT AS SellingExpensesIncludingVAT,
	|	-DD.SellingExpensesExcludingVAT AS SellingExpensesExcludingVAT,
	|	-DD.SellingExpensesMan AS SellingExpensesMan,
	|	-DD.SellingExpensesLocal AS SellingExpensesLocal,
	|	-DD.PermanentDifference AS PermanentDifference,
	|	-DD.CostTD AS CostTD
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS DD
	|		INNER JOIN TTSelectionAccordingToCustomerSOrder AS TTSelectionAccordingToCustomerSOrder
	|		ON DD.SalesOrder = TTSelectionAccordingToCustomerSOrder.DimensionOfExpenses
	|			AND DD.SalesOrder.Organization = TTSelectionAccordingToCustomerSOrder.Organization
	|		INNER JOIN AccumulationRegister.OtherExpenses AS Expenses
	|		ON DD.ItemsLocationAttributes = Expenses.ItemsLocationAttributes
	|			AND DD.SalesOrder = Expenses.DimensionOfExpenses
	|			AND DD.Recorder = Expenses.Recorder
	|			AND DD.FinRecordID = Expenses.FinRecordID
	|			AND DD.BusinessTransactionSetting = Expenses.BusinessTransactionSetting
	|		INNER JOIN ExpensesToBeDistributedForSale AS ExpenseForAllocation
	|			ON ExpenseForAllocation.Organization = Expenses.Organization
	|			AND ExpenseForAllocation.Department = Expenses.Department
	|			AND ExpenseForAllocation.LineOfBusiness = Expenses.LineOfBusiness
	|			AND ExpenseForAllocation.ExpenseItem = Expenses.ExpenseItem
	|			AND ExpenseForAllocation.DimensionOfExpenses = Expenses.DimensionOfExpenses
	|WHERE
	|	DD.Active
	|	AND DD.Period < &BeginOfPeriod
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTDistributionBaseAccordingToCustomerSOrder AS Base
	|			WHERE
	|				Expenses.DimensionOfExpenses = Base.SalesOrder
	|				AND Expenses.Organization = Base.Organization
	|				AND Expenses.LineOfBusiness IN (
	|					Base.CounterpartyLineOfBusiness,
	|					VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|			)
	|;
	|
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextSelectionDistributionOfSalesExpenses() 
	
	QueryText = "
	|SELECT
	|	1 AS SourceCode,
	|	Expenses.Organization,
	|	Expenses.Department AS ExpensesBusinessUnit,
	|	Expenses.LineOfBusiness,
	|	Expenses.ExpenseItem,
	|	Expenses.DimensionOfExpenses,
	|	Base.Period,
	|	Base.Recorder,
	|	Base.ItemsLocationAttributes,
	|	Base.SalesOrder,
	|	Base.AccountingDimensionByPartners,
	|	Base.Department AS RevenueDivision,
	|	Base.InventoryType,
	|	Base.InventoryOwnerAttribute,
	|	Base.AccountingSection,
	|	Base.Lot,
	|	Base.LotVendorAttributes,
	|	Base.FinancialAccountingDimension,
	|	Base.VATActivityType,
	|	Base.Manager,
	|	Base.Warehouse,
	|	Base.Terms,
	|	Base.Contract,
	|	Base.SetAccountingDimension,
	|	Base.CounterpartyLineOfBusiness,
	|	Base.ProductLineOfBusiness,
	|	Base.VATTaxation,
	|	Base.ARAPCurrency,
	|	Base.DocumentCurrency,
	|	Base.SourceOfProductFinancialAccountingGroup,
	|	Base.ReversingEntry,
	|	Base.VATRate,
	|	CAST(Expenses.Sum * (Expenses.ManSRevenueRatio * Base.ShareRevenueMan + Expenses.ManCostRatio *
	|		Base.ShareCostOfMan + Expenses.CoefficientForNumberOfMen * Base.ShareQuantity + Expenses.ManSWeightRatio * Base.ShareWeight +
	|		Expenses.ManSVolumeCoefficient * Base.ShareVolume) AS NUMBER(31,2)) AS Sum,
	|	CAST(Expenses.AmountExcludingVAT * (Expenses.ManSRevenueRatio * Base.ShareRevenueMan + Expenses.ManCostRatio *
	|		Base.ShareCostOfMan + Expenses.CoefficientForNumberOfMen * Base.ShareQuantity + Expenses.ManSWeightRatio * Base.ShareWeight +
	|		Expenses.ManSVolumeCoefficient * Base.ShareVolume) AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	CAST(Expenses.SumMan * (Expenses.ManSRevenueRatio * Base.ShareRevenueMan + Expenses.ManCostRatio *
	|		Base.ShareCostOfMan + Expenses.CoefficientForNumberOfMen * Base.ShareQuantity + Expenses.ManSWeightRatio * Base.ShareWeight +
	|		Expenses.ManSVolumeCoefficient * Base.ShareVolume) AS NUMBER(31,2)) AS SumMan,
	|	CAST(Expenses.SumCompl * (Expenses.LocalRevenueCoefficient * Base.ShareRevenueLocal + Expenses.LocalCostRatio *
	|		Base.ShareCostOfLocal + Expenses.CoefficientForNumberOfLocal * Base.ShareQuantity + Expenses.LocalWeightRatio * Base.ShareWeight +
	|		Expenses.LocalVolumeCoefficient * Base.ShareVolume) AS NUMBER(31,2)) AS SumCompl,
	|	CAST(Expenses.PermanentDifference * (Expenses.LocalRevenueCoefficient * Base.ShareRevenueLocal + Expenses.LocalCostRatio *
	|		Base.ShareCostOfLocal + Expenses.CoefficientForNumberOfLocal * Base.ShareQuantity + Expenses.LocalWeightRatio * Base.ShareWeight +
	|		Expenses.LocalVolumeCoefficient * Base.ShareVolume) AS NUMBER(31,2)) AS PermanentDifference,
	|	CAST(Expenses.CostTD * (Expenses.LocalRevenueCoefficient * Base.ShareRevenueLocal + Expenses.LocalCostRatio *
	|		Base.ShareCostOfLocal + Expenses.CoefficientForNumberOfLocal * Base.ShareQuantity + Expenses.LocalWeightRatio * Base.ShareWeight +
	|		Expenses.LocalVolumeCoefficient * Base.ShareVolume) AS NUMBER(31,2)) AS CostTD
	|FROM
	|	ExpensesToBeDistributedForSale AS Expenses
	|		INNER JOIN TTDistributionBaseForSales AS Base
	|		ON	Expenses.DimensionOfExpenses = Base.DimensionOfExpenses
	|			AND Expenses.Organization = Base.Organization
	|			AND Expenses.LineOfBusiness = Base.LineOfBusiness
	|
	|UNION ALL
	|
	|SELECT
	|	2 AS SourceCode,
	|	DD.Organization,
	|	DD.ExpensesBusinessUnit,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	CASE 
	|		WHEN DD.Recorder.DATE < &BeginOfPeriod THEN DD.Period
	|		ELSE DD.Recorder.DATE
	|	END,
	|	DD.Recorder,
	|	DD.ItemsLocationAttributes,
	|	DD.SalesOrder,
	|	DD.AccountingDimensionByPartners,
	|	DD.RevenueDivision,
	|	DD.InventoryType,
	|	DD.InventoryOwnerAttribute,
	|	DD.AccountingSection,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.FinancialAccountingDimension,
	|	DD.VATActivityType,
	|	DD.Manager,
	|	DD.Warehouse,
	|	DD.Terms,
	|	DD.Contract,
	|	DD.SetAccountingDimension,
	|	DD.CounterpartyLineOfBusiness,
	|	DD.ProductLineOfBusiness,
	|	DD.VATTaxation,
	|	DD.ARAPCurrency,
	|	DD.DocumentCurrency,
	|	DD.SourceOfProductFinancialAccountingGroup,
	|	DD.ReversingEntry,
	|	DD.VATRate,
	|	CAST(SUM(DD.Sum) AS NUMBER(31,2)) AS Sum,
	|	CAST(SUM(DD.AmountExcludingVAT) AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	CAST(SUM(DD.SumMan) AS NUMBER(31,2)) AS SumMan,
	|	CAST(SUM(DD.SumCompl) AS NUMBER(31,2)) AS SumCompl,
	|	CAST(SUM(DD.PermanentDifference) AS NUMBER(31,2)) AS PermanentDifference,
	|	CAST(SUM(DD.CostTD) AS NUMBER(31,2)) AS CostTD
	|FROM
	|	DistributionToCustomerOrder AS DD
	|GROUP BY
	|	DD.Organization,
	|	DD.ExpensesBusinessUnit,
	|	DD.LineOfBusiness,
	|	DD.ExpenseItem,
	|	DD.DimensionOfExpenses,
	|	CASE 
	|		WHEN DD.Recorder.DATE < &BeginOfPeriod THEN DD.Period
	|		ELSE DD.Recorder.DATE
	|	END,
	|	DD.Recorder,
	|	DD.ItemsLocationAttributes,
	|	DD.SalesOrder,
	|	DD.AccountingDimensionByPartners,
	|	DD.RevenueDivision,
	|	DD.InventoryType,
	|	DD.InventoryOwnerAttribute,
	|	DD.AccountingSection,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.FinancialAccountingDimension,
	|	DD.VATActivityType,
	|	DD.Manager,
	|	DD.Warehouse,
	|	DD.Terms,
	|	DD.Contract,
	|	DD.SetAccountingDimension,
	|	DD.CounterpartyLineOfBusiness,
	|	DD.ProductLineOfBusiness,
	|	DD.VATTaxation,
	|	DD.ARAPCurrency,
	|	DD.DocumentCurrency,
	|	DD.SourceOfProductFinancialAccountingGroup,
	|	DD.ReversingEntry,
	|	DD.VATRate";
	
	Return QueryText;
	
EndFunction

Function TextDescriptionOfDataForAllocationOfSalesExpenses()
	
	QueryText = "
	|SELECT TOP 0
	|	0 AS SourceCode,
	|	Expenses.Organization,
	|	Expenses.Department AS ExpensesBusinessUnit,
	|	Expenses.LineOfBusiness,
	|	Expenses.ExpenseItem,
	|	Expenses.DimensionOfExpenses,
	|	DD.Period,
	|	DD.Recorder,
	|	DD.ItemsLocationAttributes,
	|	DD.SalesOrder,
	|	DD.AccountingDimensionByPartners,
	|	DD.Department AS RevenueDivision,
	|	DD.InventoryType,
	|	DD.InventoryOwnerAttribute,
	|	DD.AccountingSection,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.FinancialAccountingDimension,
	|	DD.VATActivityType,
	|	DD.Manager,
	|	DD.Warehouse,
	|	DD.Terms,
	|	DD.Contract,
	|	DD.SetAccountingDimension,
	|	DD.CounterpartyLineOfBusiness,
	|	DD.ProductLineOfBusiness,
	|	DD.VATTaxation,
	|	DD.ARAPCurrency,
	|	DD.DocumentCurrency,
	|	DD.SourceOfProductFinancialAccountingGroup,
	|	DD.ReversingEntry,
	|	DD.VATRate,
	|	0 AS Sum,
	|	0 AS AmountExcludingVAT,
	|	0 AS SumMan,
	|	0 AS SumCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD
	|INTO Data
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS DD
	|	LEFT JOIN AccumulationRegister.OtherExpenses AS Expenses
	|	ON TRUE
	|";
	
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region StageProcedures_General

#Region ProceduresForSupportingWorkThroughHIA

Procedure InitializeHIATable(CalculationParameters) Export

	If CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters.TempTablesManager, "TTOvz") Then
		Return; // TUE for HIA has already been initialized earlier
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "InitializeHIATable");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	Query.Text = TextInTPOOvz();
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(Query.TempTablesManager, "ValuesOfHIAIndicators") Then
		Query.Text = Query.Text + CostCalculationItemizedCosts.TextValuesOfDistributionIndicatorsForHIA();
	EndIf;
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True, "TTOvz");
	
EndProcedure

Function TextInTPOOvz() Export

	QueryText = CostCalculationItemizedCosts.TextDescriptionOfDataForHIA();
	
	QueryText = CostCalculationAppliedAlgorithms.ChangeDataDescriptionRequestReceiver(QueryText, "TTOvz");
	Return QueryText + ";
	|";

EndFunction

Function TextValuesOfDistributionIndicatorsForHIA() Export

	QueryText = 
	"SELECT TOP 0
	|	UNDEFINED	AS Factor,
	|	UNDEFINED	AS ConstCenter,
	|	UNDEFINED	AS AllocationBase,
	|	UNDEFINED	AS IndicatorValue
	|INTO ValuesOfHIAIndicators;
	|";
	If GetFunctionalOption("UseAccountingByExpenseObjects") Then
	QueryText = "
		|SELECT DISTINCT
		|	Rules.Ref AS Factor
		|INTO ConstantIndicatorsOfHIA
		|FROM
		|	Catalog.CostAllocationRules AS Rules
		|WHERE Rules.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand)
		|		AND Rules.AssignRule = VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationToCostCenter)
		|
		|INDEX BY
		|	Factor
		|;
		|
		|SELECT
		|	T.Factor,
		|	T.ConstCenter,
		|	VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand) AS AllocationBase,
		|	T.IndicatorValue
		|INTO ValuesOfHIAIndicators
		|FROM
		|	InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects.SliceLast(
		|			&BeginOfPeriod,
		|			Factor IN
		|				(SELECT
		|					DD.Factor
		|				FROM
		|					ConstantIndicatorsOfHIA AS DD)) AS T
		|WHERE
		|	T.IndicatorValue > 0
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	T.Factor,
		|	T.ConstCenter,
		|	VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis) AS AllocationBase,
		|	T.IndicatorValue
		|FROM
		|	Catalog.CostAllocationRules AS Rules
		|		INNER JOIN InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects AS T
		|		ON Rules.Ref = T.Factor
		|		AND T.Period = &BeginOfPeriod
		|WHERE
		|	T.IndicatorValue > 0
		|	AND Rules.AllocationBase IN (VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis), VALUE(Enum.TypesOfCostAllocatingBase.AutofillOnMonthlyBasis))
		|	AND Rules.AssignRule = VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationToCostCenter)
		|
		|INDEX BY
		|	Factor,
		|	ConstCenter
		|////////////////////////////////////////////////////////////////////////////////
		|;
		|
		|DROP ConstantIndicatorsOfHIA;
		|";
	EndIf;
	Return QueryText;

EndFunction

Function TextDescriptionOfDataForHIA() Export
	
	QueryText = 
	"SELECT TOP 0
	|	0																	AS NodeNumber,
	|	UNDEFINED														AS ConstCenter,
	|	VALUE(Catalog.Companies.EmptyRef)						AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)				AS Department,
	|	VALUE(Enum.CostAllocationOptions.EmptyRef)	AS CostAllocationOptionManag,
	|	VALUE(Enum.CostAllocationOptions.EmptyRef)	AS CostAllocationOptionLocal,
	|	VALUE(Enum.CostAllocationOptions.EmptyRef)	AS CostAllocationOptionTax,
	|	VALUE(Catalog.CostAllocationRules.EmptyRef)		AS CostAllocationRuleManag,
	|	VALUE(Catalog.CostAllocationRules.EmptyRef)		AS CostAllocationRuleLocal,
	|	VALUE(Catalog.CostAllocationRules.EmptyRef)		AS CostAllocationRuleTax,
	|	FALSE																AS NotUsed,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)		AS EmptyExpenseItem,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)			AS EmptyLineOfBusiness,
	|	TRUE																AS ThisIsOVZ
	|INTO Data
	|";
	If GetFunctionalOption("UseAccountingByExpenseObjects") Then
		QueryText = "
		|SELECT
		|	RECORDAUTONUMBER() AS NodeNumber,
		|	T.Ref AS ConstCenter,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.CostAllocationOptionManag AS CostAllocationOptionManag,
		|	T.CostAllocationOptionLocal AS CostAllocationOptionLocal,
		|	T.CostAllocationOptionTax AS CostAllocationOptionTax,
		|	T.CostAllocationRuleManag AS CostAllocationRuleManag,
		|	T.CostAllocationRuleLocal AS CostAllocationRuleLocal,
		|	T.CostAllocationRuleTax AS CostAllocationRuleTax,
		|	T.NotUsed AS NotUsed,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS EmptyExpenseItem,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS EmptyLineOfBusiness,
		|	TRUE AS ThisIsOVZ
		|INTO Data
		|FROM
		|	Catalog.CostCenters AS T
		|
		|INDEX BY
		|	ConstCenter,
		|	Department,
		|	Organization
		|";
	EndIf;
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

Function TextDescriptionOfDataForTransitCostsBetweenHIA() Export
	
	QueryText = "
	|SELECT TOP 0
	|	UNDEFINED													AS DocumentRegisterRecords,
	|	VALUE(Catalog.Companies.EmptyRef)					AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)			AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)		AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)	AS ExpenseItem,
	|	UNDEFINED													AS DimensionOfExpenses,
	|	VALUE(Catalog.Companies.EmptyRef)					AS CorCompany,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)			AS DebitBusinessUnit,
	|	UNDEFINED													AS CorExpenditureDimension,
	|	0																AS Weight, 
	|	0																AS LocalWeight,
	|	0																AS LedWeight, 
	|	0																AS LocalWeightGiven,
	|	0																AS GivenWeightOfNDT
	|INTO Data
	|";
	
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

Function TextDescriptionOfDataForInitialTransitDataOfExpendituresBetweenHIA() Export
	
	QueryText = "
	|SELECT TOP 0
	|	RECORDAUTONUMBER()												AS NodeNumber,
	|	VALUE(Catalog.Companies.EmptyRef)					AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)			AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)		AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)	AS ExpenseItem,
	|	UNDEFINED													AS DimensionOfExpenses,
	|	0																AS Weight,
	|	0																AS LocalWeight,
	|	0																AS LedWeight, 
	|	0																AS LocalWeightGiven,
	|	0																AS GivenWeightOfNDT
	|INTO Data
	|";
	
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

#EndRegion

#EndRegion

#Region SelectionSettingsParameters

Function GetDescriptionOfObjectGroupsBySelectionSettings(GettingObjectText, CalculationParameters,
	NameOfTemporaryObjectGroupTable, UnavailableSelectionFields = Undefined, OptimizationEnabled = False) Export
	
	ArrayOfObjectTypes = New Array;
	ArrayOfObjectTypes.Add(Type("DocumentRef.AllocationOfOtherCosts")); // to close the period.
	ArrayOfObjectTypes.Add(Type("Number")); // for cases when the procedure is called from the outside.
	
	ObjectGroups_ = New ValueTable;
	ObjectGroups_.Columns.Add("NumberOfGroup", New TypeDescription("Number"));
	ObjectGroups_.Columns.Add("Object", New TypeDescription(ArrayOfObjectTypes));
	
	DescriptionOfGroups = New ValueTable;
	DescriptionOfGroups.Columns.Add("NumberOfGroup", New TypeDescription("Number"));
	DescriptionOfGroups.Columns.Add("Used", New TypeDescription("Boolean"));
	DescriptionOfGroups.Columns.Add("ConditionText", New TypeDescription("String"));
	DescriptionOfGroups.Columns.Add("QueryOptions", New TypeDescription("Structure"));
	DescriptionOfGroups.Columns.Add("ParametersCount", New TypeDescription("Number"));
	DescriptionOfGroups.Columns.Add("EqualityCondition", New TypeDescription("Boolean"));
	
	If CalculationParameters = Undefined Then
		Return DescriptionOfGroups;
	EndIf;
	
	IndexedFields = "ConditionText, ParametersCount";
	
	Query = New Query;
	Query.TempTablesManager = CalculationParameters.TempTablesManager;
	Query.Text = GettingObjectText;
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	GroupsFormedSuccessfully = True;
	
	While Selection.Next() Do
		
		FilterParameters = DefineSelectionParameters(Selection, UnavailableSelectionFields);
		
		If FilterParameters = Undefined Then
			GroupsFormedSuccessfully = False;
			CompanyAttribute1 = Common.ObjectAttributeValue(Selection.Ref, "Organization");
			CostCalculationAppliedAlgorithms.RegisterCalculationExecutionProblem(CalculationParameters, CompanyAttribute1,
			NStr("vi = 'Sai điều kiện lọc';
				|ru = 'Некорректные условия отбора';
				|en = 'Incorrect filter criteria'; fa = 'Incorrect filter criteria';
				|it = 'Condizioni di filtro errate';
				|pl = 'Niepoprawne warunki filtru';
				|tr = 'Yanlış filtre koşulları'"), 
			NStr("vi = 'Trong điều kiện lọc không hỗ trợ sử dụng các mục tin bổ sung';
				|ru = 'В условиях отбора не поддерживается использование дополнительных реквизитов';
				|en = 'Additional attributes are not supported in the filter criteria'; fa = 'Additional attributes are not supported in the filter criteria';
				|it = 'Nelle condizioni di filtro non è supportato l''utilizzo di attributi aggiuntivi';
				|pl = 'W warunkach filtru nie jest obsługiwane użycie dodatkowych atrybutów';
				|tr = 'Filtre koşullarında ek özniteliklerin kullanımı desteklenmemektedir'"),
			Selection.Ref);
			Continue;
		EndIf;
		
		NumberOfGroup = DefineGroup(FilterParameters, DescriptionOfGroups);
		
		NewObject = ObjectGroups_.Add();
		NewObject.NumberOfGroup = NumberOfGroup;
		NewObject.Object = Selection.Ref;
		
		If NumberOfGroup < DescriptionOfGroups.Count() Then
			Continue;
		EndIf;
		
		If FilterParameters.QueryOptions.Count()>0 Then
			For Each QueryParameter In FilterParameters.QueryOptions Do
				If DescriptionOfGroups.Columns.Find(QueryParameter.Key) = Undefined Then
					DescriptionOfGroups.Columns.Add(QueryParameter.Key);
					IndexedFields = StrTemplate("%1, %2", IndexedFields, QueryParameter.Key);
					DescriptionOfGroups.Indexes.Add(IndexedFields);
				EndIf;
			EndDo;
		EndIf;
		
		GroupDetails = DescriptionOfGroups.Add();
		GroupDetails.NumberOfGroup = NumberOfGroup;
		GroupDetails.Used = True;
		GroupDetails.ConditionText = FilterParameters.ConditionText;
		GroupDetails.QueryOptions = FilterParameters.QueryOptions;
		GroupDetails.ParametersCount = FilterParameters.QueryOptions.Count();
		FillPropertyValues(GroupDetails, FilterParameters.QueryOptions);
		GroupDetails.EqualityCondition = GroupDetails.ConditionText = "SourceDatabase.Ref = &CurrentDepartment"
			And GroupDetails.DistributionBaseIndicator = "AllocationDirection"
			And GroupDetails.ParametersCount = 4;

		If Not (OptimizationEnabled And GroupDetails.EqualityCondition) Then
			For Each Parameter In FilterParameters.QueryOptions Do
				
				If Parameter.Key = "DistributionBaseIndicator" Then
					Continue;
				EndIf;
				
				ParameterName = GenerateParameterName(Parameter.Key, NumberOfGroup, NameOfTemporaryObjectGroupTable);
				CalculationParameters.AdditionalStageRequestParameters.Insert(ParameterName, Parameter.Value);
				
			EndDo;
		EndIf;
		
	EndDo;

	If Not GroupsFormedSuccessfully Then
		Raise NStr("vi = 'Trong bộ lọc chứng từ phân bổ đã đặt có các điều kiện không được hỗ trợ.
									|Đã ghi nhận lỗi hạch toán.';
									|ru = 'В заданных отборах документов распределения обнаружены неподдерживаемые условия.
									|Зарегистрированы ошибки расчета.';
									|en = 'Unsupported criteria is found in the specified filters of allocation documents.
									|Calculation errors are registered.'; fa = 'Unsupported criteria is found in the specified filters of allocation documents.
									|Calculation errors are registered.';
									|it = 'Nei filtri dati dei documenti di distribuzione sono stati rilevati condizioni non supportabili.
									|Sono registrati errori di calcolo.';
									|pl = 'W zadanych filtrach dokumentów podziału wykryto nieobsługiwane warunki.
									|Zarejestrowano błędy rozliczenia.';
									|tr = 'Belirtilen dağıtım belgeleri seçimlerinde desteklenmeyen koşullar tespit edildi.
									|Hesaplama hataları kaydedildi.'");
	EndIf;
	
	DescriptionOfGroups.Indexes.Clear();
	CalculationParameters.AdditionalStageRequestParameters.Insert(NameOfTemporaryObjectGroupTable, ObjectGroups_);
	
	Return DescriptionOfGroups;
	
EndFunction

Function DefineSelectionParameters(Selection, FieldsNotAvailableForSelection = Undefined)

	SchemaName = AllocationRulesCached.NameOfDistributionBaseSchema(Selection.AllocationBaseType);
	
	FilterParameters = New Structure("ConditionText, QueryOptions", "", New Structure);
	FilterParameters.QueryOptions.Insert("DistributionBaseIndicator", SchemaName);
	If SchemaName = "Goods" Then
		FilterParameters.QueryOptions.Insert("TypeOfExpenseAnalytics", Selection.TypeOfExpenseAnalytics);
	EndIf;
	
	SelectingSchemaSettings = Selection.SchemaSettings; // ValueStorage
	DataCompositionSettings = SelectingSchemaSettings.Get(); // DataCompositionSettings
	If DataCompositionSettings = Undefined Then
		// Selections are not set.
		Return FilterParameters;
	EndIf;
	
	If Not FieldsNotAvailableForSelection = Undefined Then
		
		For Each UnavailableField In FieldsNotAvailableForSelection Do
			ClearUnavailableFieldsFromSelection(DataCompositionSettings.Filter.Items, UnavailableField);
		EndDo;
		
	EndIf;
	
	RemoveIncorrectValuesFromSelection(DataCompositionSettings.Filter.Items);
	
	XMLWriter = New XMLWriter();
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, DataCompositionSettings);
	XMLDataLayoutSettings = XMLWriter.Close();
	
	CompositionTemplate = AllocationRulesCached.DataCompositionTemplate(SchemaName,
		Selection.AllocationBaseType, XMLDataLayoutSettings);
	
	If Not CompositionTemplate.DataSets.Count() Then
		Return FilterParameters;
	EndIf;
	
	QueryText = CompositionTemplate.DataSets[0].Query;
	
	PrefixLength = StrLen("WHERE");
	StartOfCondition = StrFind(QueryText, "WHERE") + PrefixLength;
	If StartOfCondition = PrefixLength Then
		FilterParameters.ConditionText = "";
	Else
		FilterParameters.ConditionText = ConditionTextWithoutFormatting(
			TrimAll(Mid(QueryText, StartOfCondition)));
	EndIf;
	
	If StrFind(FilterParameters.ConditionText, "AdditionalAttributes.") <> 0 Then
		Return Undefined;
	EndIf;
	
	Aliases = Undefined;
	If SchemaName = "AllocationDirection" Then
		
		Aliases = New Map();
		Aliases.Insert("Department", "Ref");
		
	EndIf;
	
	ReplaceEmptyValuesWithAliases(FilterParameters.ConditionText,
		QueryText,
		Aliases);
	If SchemaName = "AllocationDirection" Then
		// Adding predefined parameters.
		FilterParameters.QueryOptions.Insert("CurrentDepartment", Undefined);
		FilterParameters.QueryOptions.Insert("ValueOfCostAnalytics", Undefined);
		FilterParameters.QueryOptions.Insert("SuperiorDepartment", Undefined);
	EndIf;
	
	TextsOfExclusionOfSemiFinishedProducts = New Array;
	For Each Parameter In CompositionTemplate.ParameterValues Do
		If Parameter.Name = "CurrentDepartment" And SchemaName = "AllocationDirection" Then
			If StrFind(FilterParameters.ConditionText, StrTemplate("&%1", Parameter.Name)) > 0 Then
				FilterParameters.QueryOptions.Insert(Parameter.Name, Selection.Department);
			EndIf;
		ElsIf Parameter.Name = "OperatingUnitExpenseDimensions" And SchemaName = "AllocationDirection" Then
			If StrFind(FilterParameters.ConditionText, StrTemplate("&%1", Parameter.Name)) > 0 Then
				// The "&Sub-unit of the analysis of the inputs" in the condition is replaced by "&Value of the analysis of the outputs" 
				// in order to avoid coincidence with the scheme parameter "&N" during subsequent replacement
				FilterParameters.ConditionText = 
					StrReplace(FilterParameters.ConditionText, "OperatingUnitExpenseDimensions", "ValueOfCostAnalytics");
				FilterParameters.QueryOptions.Insert("ValueOfCostAnalytics", Selection.DimensionOfExpenses);
			EndIf;
		ElsIf Parameter.Name = "SuperiorDepartment" And SchemaName = "AllocationDirection" Then
			If StrFind(FilterParameters.ConditionText, StrTemplate("&%1", Parameter.Name)) > 0 Then
				FilterParameters.QueryOptions.Insert(Parameter.Name, Selection.ParentDivision);
			EndIf;
		Else
				FilterParameters.QueryOptions.Insert(Parameter.Name, Parameter.Value);
		EndIf;
		If Parameter.Name = "ExcludeSemiFinishedProductsOwn" And Parameter.Value
			And SchemaName = "MaterialCosts" Then
			TextsOfExclusionOfSemiFinishedProducts.Add("NOT SourceDatabase.ThisIsSemiFinishedProductOfItsOwn");
		ElsIf Parameter.Name = "ExcludeSemiFinishedProductsOfProcessor" And Parameter.Value
			And SchemaName = "MaterialCosts" Then
			TextsOfExclusionOfSemiFinishedProducts.Add("NOT SourceDatabase.ItIsSemiFinishedProcessor");
		EndIf;
	EndDo;
	TextOfSemiFinishedProductsExclusion = StrConcat(TextsOfExclusionOfSemiFinishedProducts, " And ");
	If Not IsBlankString(TextOfSemiFinishedProductsExclusion) Then
		FilterParameters.ConditionText = StrTemplate("%1 AND (%2)",
			TextOfSemiFinishedProductsExclusion,
			?(IsBlankString(FilterParameters.ConditionText), "TRUE", FilterParameters.ConditionText));
	EndIf;
	Return FilterParameters;
	
EndFunction

Procedure RemoveIncorrectValuesFromSelection(CollectionOfSelectionElements)
	
	IndexOf = CollectionOfSelectionElements.Count() - 1;
	While IndexOf >= 0 Do
		
		FilterElement = CollectionOfSelectionElements[IndexOf];
		IndexOf = IndexOf - 1;
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") 
				And FilterElement.ComparisonType = DataCompositionComparisonType.InList 
				And TypeOf(FilterElement.RightValue) = Type("ValueList") Then
			
			ListIndex = FilterElement.RightValue.Count() - 1;
			While ListIndex >= 0 Do
				If Not ValueIsFilled(FilterElement.RightValue[ListIndex].Value) Then 
					FilterElement.RightValue.Delete(ListIndex);
				EndIf;
				ListIndex = ListIndex - 1;
			EndDo;
			
			If FilterElement.RightValue.Count() = 0 Then
				CollectionOfSelectionElements.Delete(FilterElement);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ClearUnavailableFieldsFromSelection(CollectionOfSelectionElements, FieldName)
	
	IndexOf = CollectionOfSelectionElements.Count() - 1;
	While IndexOf >= 0 Do
		
		FilterElement = CollectionOfSelectionElements[IndexOf];
		IndexOf = IndexOf - 1;
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			
			ClearUnavailableFieldsFromSelection(FilterElement.Items, FieldName);
			
			If FilterElement.Items.Count() = 0 Then
				CollectionOfSelectionElements.Delete(FilterElement);
			EndIf;
			
			Continue;
			
		EndIf;
		
		If StrStartsWith(FilterElement.LeftValue, FieldName) Then
			CollectionOfSelectionElements.Delete(FilterElement);
		EndIf;
		
	EndDo;
	
EndProcedure

Function DefineGroup(NewParameters, DescriptionOfGroups)
	
	// -4 number of initial columns in the table.
	If DescriptionOfGroups.Columns.Count() - 4 < NewParameters.QueryOptions.Count() Then
		Return DescriptionOfGroups.Count();
	EndIf;
	
	SearchKey = New Structure("ConditionText, ParametersCount",
		NewParameters.ConditionText, NewParameters.QueryOptions.Count());
	ThereAreListsOfValues = False;
	AllParametersAreSet = True;
	For Each QueryParameter In NewParameters.QueryOptions Do
		
		If TypeOf(QueryParameter.Key) = Type("ValueList") Then
			
			ThereAreListsOfValues = True;
			Continue;
			
		EndIf;
		
		If DescriptionOfGroups.Columns.Find(QueryParameter.Key) = Undefined Then
			
			AllParametersAreSet = False;
			Break;
			
		EndIf;
		
		SearchKey.Insert(QueryParameter.Key, QueryParameter.Value);
		
	EndDo;	
	
	If Not AllParametersAreSet Then
		Return DescriptionOfGroups.Count();
	EndIf;
	
	ConditionGroups = DescriptionOfGroups.FindRows(SearchKey);
	If ConditionGroups.Count() = 0 Then
		Return DescriptionOfGroups.Count();
	EndIf;
	
	If Not ThereAreListsOfValues And ConditionGroups.Count() = 1 Then
		Return ConditionGroups[0].NumberOfGroup;
	EndIf;
	
	NumberOfGroup = DescriptionOfGroups.Count();
	For Each GroupDetails In ConditionGroups Do
		
		GroupCorrespondsTo = True;
		ParameterIndex = 0;
		While GroupCorrespondsTo And ParameterIndex < NewParameters.QueryOptions.Count() Do
			
			NewParameter1 = NewParameters.QueryOptions[ParameterIndex];
			If Not TypeOf(NewParameter1.Value) = Type("ValueList") Then
				// The search for fields of the reference type was performed earlier.
				ParameterIndex = ParameterIndex + 1;
				Continue;
			EndIf;
			
			GroupParameter = GroupDetails[NewParameter1.Key];
			If Not TypeOf(GroupParameter) = TypeOf(NewParameter1.Value) Then
				GroupCorrespondsTo = False;
			Else
				
				NewParameter1.Value.SortByValue();
				GroupCorrespondsTo = (GroupParameter.Count() = NewParameter1.Value.Count());
				
				ElementIndex = 0;
				While ElementIndex < GroupParameter.Count()
					And GroupCorrespondsTo Do
					
					GroupCorrespondsTo = (GroupParameter[ElementIndex].Value = NewParameter1.Value[ElementIndex].Value);
					ElementIndex = ElementIndex + 1;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
		If GroupCorrespondsTo Then
			
			NumberOfGroup = GroupDetails.NumberOfGroup;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return NumberOfGroup;
	
EndFunction

Function ConditionTextWithoutFormatting(Text)
	
	SymbolsToReplace = New Array;
	SymbolsToReplace.Add(Chars.CR);
	SymbolsToReplace.Add(Chars.VTab);
	SymbolsToReplace.Add(Chars.NBSp);
	SymbolsToReplace.Add(Chars.LF);
	SymbolsToReplace.Add(Chars.FF);
	SymbolsToReplace.Add(Chars.Tab);
	
	For Each SymbolToReplace In SymbolsToReplace Do
		Text = StrReplace(Text, SymbolToReplace, " ");
	EndDo;
	
	While StrFind(Text, "  ") > 0 Do
		Text = StrReplace(Text, "  ", " ");
	EndDo;
	
	Return Text;
	
EndFunction

Procedure ReplaceEmptyValuesWithAliases(ConditionText, Val QueryText, Aliases = Undefined)
	
	Determinant = "VALUE(";
	
	While StrFind(ConditionText, Determinant) > 0 Do
		
		StartOfEmptyValue = StrFind(ConditionText, Determinant);
		EmptyValue = Mid(ConditionText, 
			StartOfEmptyValue,
			StrFind(ConditionText, ")",, StartOfEmptyValue) - StartOfEmptyValue + 1);
			
		CommaPosition = StrFind(QueryText, ",", , StrFind(QueryText, EmptyValue));
		AliasStartPosition = StrFind(QueryText, " ", SearchDirection.FromEnd, CommaPosition) + 1;
		
		If CommaPosition - AliasStartPosition <= 0 Then
			Continue;
		EndIf;
		
		Alias = Mid(QueryText, 
			AliasStartPosition,
			CommaPosition - AliasStartPosition);

		If Not Aliases = Undefined
			And Not Aliases.Get(Alias) = Undefined Then
			Alias = Aliases.Get(Alias);
		EndIf;
		
		ConditionText = StrReplace(ConditionText, EmptyValue, 
			StrTemplate("%1.%2", "SourceDatabase", Alias));
		
	EndDo;
	
EndProcedure

Function GenerateParameterName(OriginalName, NumberOfGroup, Stage)
	
	Return StrTemplate("%1_%2_%3", OriginalName, Format(NumberOfGroup, "NZ=; NG=0"), Stage);
	
EndFunction

// Complements the texts of the requests for new texts for description of groups.
// Parameters:
//	QueriesTexts - Array - texts of requests for the distribution database in the context of cost distribution documents.
//	DescriptionOfGroups - Structure -
//	TemplateSource - String - where to get the request text template.
Procedure AddTextsDescribingGroups(QueriesTexts, DescriptionOfGroups, TemplateSource, OptimizationEnabled = False) Export
	
	UsedTemplates = New Structure;
	UsedTemplates.Insert("ByOrders", 		 New Array);
	UsedTemplates.Insert("ByDeclarations", 	 New Array);
	UsedTemplates.Insert("ByDocuments", 	 New Array);
	UsedTemplates.Insert("ByReferenceBooks", 	 New Array);
	UsedTemplates.Insert("ByOtherExpenses", New Array);
	UsedTemplates.Insert("ByRecycling", 	 New Array);
	
	AddedTemplates = New Structure;
	
	For Each GroupDetails In DescriptionOfGroups Do
		
		QueryTemplate = "";
		If TemplateSource = "GroupsOfAdditionalExpenseItems" Then
			
			GroupDetails.ConditionText = StrReplace(GroupDetails.ConditionText, "SourceDatabase.Warehouse", "DimensionOfSelection.StorageLocation");
			GroupDetails.ConditionText = StrReplace(GroupDetails.ConditionText, "SourceDatabase.", "DimensionOfSelection.");
			GroupDetails.ConditionText = StrReplace(GroupDetails.ConditionText, "DimensionOfSelection.Lot", "SourceDatabase.Lot");
			QueryTemplate = TextTemplatePrimaryReceiversOfAdditionalCosts(GroupDetails.QueryOptions.TypeOfExpenseAnalytics, UsedTemplates, GroupDetails.NumberOfGroup);
		ElsIf TemplateSource = "GroupsOfObjectsDistributedByBatch" Then
			QueryTemplate = BatchDistributionDatabaseTextTemplate(
				GroupDetails.DistributionBaseIndicator);
		ElsIf TemplateSource = "GroupsOfObjectsDistributedByDivision" Then
			QueryTemplate = TemplateOfTextOfDistributionBaseByDivisions(
				GroupDetails.DistributionBaseIndicator);
		ElsIf TemplateSource = "GroupsOfObjectsByDistributionDirection" Then
			QueryTemplate = SelectionTextTemplateByDivision(OptimizationEnabled);
		Else
			
			Manager = Common.ObjectManagerByFullName(TemplateSource);
			QueryTemplate = Manager.DatabaseTextTemplate(
				GroupDetails.DistributionBaseIndicator);
			
		EndIf;

		If ValueIsFilled(QueryTemplate) Then
			
			If ValueIsFilled(UsedTemplates.ByDocuments) And Not AddedTemplates.Property("ByDocuments") Then
				
				QueriesTexts.Add(AdditionalTablesForDocumentReceivers());
				AddedTemplates.Insert("ByDocuments", QueriesTexts.Count() - 1);
				
			ElsIf ValueIsFilled(UsedTemplates.ByOtherExpenses) And Not AddedTemplates.Property("ByOtherExpenses") Then
				
				QueriesTexts.Add(AdditionalTablesForReceiversForOtherExpenses());
				AddedTemplates.Insert("ByOtherExpenses", QueriesTexts.Count() - 1);
				
			EndIf;
			
			QueriesTexts.Add(
				GenerateTextOfSelectionRequest(
					QueryTemplate, 
					GroupDetails,
					StrReplace(TemplateSource, ".", "")));
			
		Else
			GroupDetails.Used = False;
		EndIf;
				
	EndDo;
	
	If ValueIsFilled(UsedTemplates.ByDocuments) Then
		
		GroupsNumbers = "";
		For Each NumberOfGroup In UsedTemplates.ByDocuments Do
			GroupsNumbers = GroupsNumbers + ?(GroupsNumbers = "", "", ", ") + Format(NumberOfGroup, "NZ=0; NG=");
		EndDo;
		
		QueriesTexts[AddedTemplates.ByDocuments] = StrReplace(
			QueriesTexts[AddedTemplates.ByDocuments], "&SelectionByGroupsByDocuments", "Group.NumberOfGroup IN (" + GroupsNumbers + ")");
		
	EndIf;
	
EndProcedure

Function TextForPlacingGroupOfObjectsInTemporaryTable(TempTableName) Export

	QueryText = 
		"SELECT DISTINCT
		|	T.NumberOfGroup,
		|	T.Object
		|INTO TempTableName
		|FROM
		|	&TempTableName AS T
		|INDEX BY
		|	NumberOfGroup";
	
	Return StrReplace(QueryText, "TempTableName", TempTableName);
	
EndFunction

Function GenerateTextOfSelectionRequest(QueryTemplate, GroupDetails, ParameterPostfix)

	RequestText_1 = StrReplace(QueryTemplate, "&NumberOfGroup", Format(GroupDetails.NumberOfGroup, "NZ=0; NG=0"));
	RequestText_1 = StrReplace(RequestText_1, "DataTable",
		StrTemplate("DataTable%1", Format(GroupDetails.NumberOfGroup, "NZ=0; NG=0")));
	If Not ValueIsFilled(TrimAll(GroupDetails.ConditionText)) Then
		Return StrReplace(RequestText_1, "&ConnectionCondition", "TRUE");
	EndIf;
	
	GroupCondition_ = GroupDetails.ConditionText;

	ParametersArray = New Array;
	For Each Column In GroupDetails.Owner().Columns Do
		
		If Column.Name = "NumberOfGroup"
			Or Column.Name = "ConditionText"
			Or Column.Name = "ParametersCount"
			Or Column.Name = "SourcesOfAdditionalDetails" Then
			Continue;
		EndIf;
		
		ParametersArray.Add(Column.Name);
		
	EndDo;
	
	ParameterPositions = New ValueList;

	IndexOf = ParametersArray.UBound();
	While IndexOf >= 0 Do
		
		ParameterName = StrTemplate("&%1", ParametersArray[IndexOf]);
		NewParameterName = GenerateParameterName(ParameterName, GroupDetails.NumberOfGroup, ParameterPostfix);
		
		StartPosition = StrFind(GroupCondition_, ParameterName);

		While StartPosition > 0 Do
			
			If Not ParameterPositions.FindByValue(StartPosition) = Undefined Then
				
				If StartPosition + StrLen(ParameterName) > StrLen(GroupCondition_) Then
					StartPosition = 0;
				Else
					StartPosition = StrFind(GroupCondition_, ParameterName, , StartPosition + StrLen(ParameterName));
				EndIf;
				
				Continue;
				
			EndIf;
			
			NewPosition = ParameterPositions.Add(StartPosition);
			
			GroupCondition_ = Left(GroupCondition_, StartPosition - 1) + NewParameterName
				+ Mid(GroupCondition_, StartPosition + StrLen(ParameterName));

			ParameterPositions.SortByValue();
			PositionIndex = ParameterPositions.IndexOf(NewPosition) + 1;
			While PositionIndex < ParameterPositions.Count() Do
				ParameterPositions[PositionIndex].Value = ParameterPositions[PositionIndex].Value
					+ StrLen(NewParameterName) - StrLen(ParameterName);
				PositionIndex = PositionIndex + 1;
			EndDo;
			
			StartPosition = StrFind(GroupCondition_, ParameterName, , StartPosition + StrLen(NewParameterName) - 1);
			
		EndDo;
		
		IndexOf = IndexOf - 1;
		
	EndDo;
	
	Return StrReplace(RequestText_1, "&ConnectionCondition", GroupCondition_);
	
EndFunction

#EndRegion

#Region StageProcedures_Contextual

// Used for all calls to fill in the billing batch.
//
Procedure FillInSettlementBatch(CalculationParameters, Context, SettlementBatch, Expense, Receipt, BatchIsFull) Export
	
	Return;
	
EndProcedure

#EndRegion

#Region Testing

// Completes the list of calculation stages.
// 
// Parameters:
// 	StageList - ValueList - 
//
Procedure SupplementStagesWithDistributionOfBatches(StageList) Export
	
	// The stage of distribution of expenses between the goods and the goods is implemented on non-standard mechanics.
	Return;
	
EndProcedure

// Completes the list of calculation stages.
// 
// Parameters:
// 	StageList - ValueList - 
//
Procedure AddStagesWithBatchTranslation(StageList) Export
	
	StageList.Add("DistributionOfDeviationsInCost"); // so far, debugging is only possible for the 1st step out of 4
	StageList.Add("DistributionOfAdditionalCostsBetweenPartiesAndGoods"); // so far, debugging is only possible for the 1st step out of 4
	StageList.Add("DistributeSharesOfProductionCosts");
	StageList.Add("DistributeDirectProductionCosts");
	StageList.Add("DistributionOfItemByItemExpensesForOutputProducts");
	StageList.Add("DistributionOfItemByItemSalesExpenses");
	
EndProcedure

Procedure RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText) Export
	
	If StageName_ = "DistributionOfDeviationsInCost" Then
		QueryText = TextOfDistributionOfDeviationsInValueCostOfGoods(CalculationParameters);
	ElsIf StageName_ = "DistributionOfAdditionalCostsBetweenPartiesAndGoods" Then
		QueryText = RequestTextForAllocationOfAdditionalCosts(CalculationParameters) + "
			|;
			|" + StrReplace(AdditionalTablesForDocumentReceivers(), "&SelectionByGroupsByDocuments", "TRUE") + "
			|;
			|" + AdditionalTablesForReceiversForOtherExpenses();
	ElsIf StageName_ = "DistributeSharesOfProductionCosts" Then
		QueryText = RequestTextForDistributionOfProductionCostShares(CalculationParameters);
	ElsIf StageName_ = "DistributeDirectProductionCosts" Then
		QueryText = RequestTextForAllocationOfDirectProductionCosts(CalculationParameters);
		
	ElsIf StageName_ = "DistributeDirectProductionCosts" Then
		QueryText = RequestTextForAllocationOfDirectProductionCosts(CalculationParameters);
		
	ElsIf StageName_ = "DistributionOfItemByItemExpensesForOutputProducts" Then
		QueryText = RequestTextForOtherExpensesOfUnfinishedProduction(CalculationParameters);
	ElsIf StageName_ = "DistributionOfItemByItemSalesExpenses" Then
		QueryText = RequestTextDistributionOfSalesExpenses(CalculationParameters);
	EndIf;
	
EndProcedure

#EndRegion

Function MergeTexts(QueriesTexts, Separator = "")
	
	If IsBlankString(Separator) Then
		Separator = TMCommonUse.QuerySeparatorInJoin();
	EndIf;
	
	Return StrConcat(QueriesTexts, Separator);
	
EndFunction


#EndRegion
