// Procedures and functions of common modules are called:
//	- Calculation of the cost of the individual rhythms.
//	- Calculation of the cost of production

#Region Public

// Stage 1B (Context: "Raspredelitelnaya")
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure DistributionOfLaborCostsForGraduation(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "DistributionOfLaborCostsForGraduation");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchDistribution(
		CalculationParameters,
		TableForDistributionOfLaborCosts_(CalculationParameters),
		DescriptionOfChainsDistributionOfLaborCostsForRelease(CalculationParameters),
		DescriptionOfMechanismsOfDistributionOfLaborCostsForOutput(CalculationParameters),
		DescriptionOfUnrecordedDistributionsOfOutputLaborCosts(CalculationParameters));

	// 2. Obtaining the initial data for the calculation
	// 	- generates a temporary Data table.
	GetDataForDistributionOfLaborCostsPerIssue(CalculationParameters);
	
	// 3. Getting chains from source data
	// 	- generates temporary tables of Sources and Receivers.
	CostCalculationAppliedAlgorithms.BuildChainsOfRegisteredRecords(CalculationParameters);
	
	// 4. Filling in batches in chains
	// 	- fills in the Calculation parameters table.Distribution of parties.Settlement parties.
	CostCalculationAppliedAlgorithms.CalculateBatchesByChains(CalculationParameters);
	
	// 5. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the labor cost register of the perfect production.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure

// Stage 9a (Context: "transfer of labor Costs")
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure TransferOfLaborCosts(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "TransferOfLaborCosts");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchDistribution(
		CalculationParameters,
		TableForDistributionOfLaborCosts(CalculationParameters),
		DescriptionOfLaborCostChains(CalculationParameters),
		DescriptionOfLaborCostRegisteredRecords(CalculationParameters),
		DescriptionOfNonWritableTypesCostOfLabor(CalculationParameters));
	
	// 2. Obtaining the initial data for the calculation
	// 	- generates a temporary Data table.
	GetDataForLaborCost(CalculationParameters);
	
	// 3. Getting chains from source data
	// 	- generates temporary tables of Sources and Receivers.
	CostCalculationAppliedAlgorithms.BuildChainsOfRegisteredRecords(CalculationParameters);
	
	// 4. Filling in batches in chains
	// 	- fills in the Calculation parameters table.Distribution of parties.Settlement parties.
	CostCalculationAppliedAlgorithms.CalculateBatchesByChains(CalculationParameters);
	
	// 5. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of cost of goods.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
		
EndProcedure

#EndRegion

#Region Private

#Region ProceduresOfStage1b_DistributionOfLaborCostsForRelease

// Data Initialization

Function FieldsOfConsumptionDistributionOfLaborCostsForOutput(CalculationParameters)
	
	Return "Organization, ProductionLot";
	
EndFunction

Function DescriptionOfChainsDistributionOfLaborCostsForRelease(CalculationParameters)
	
	DescriptionOfChains = New Map;
	ConsumptionFields	= FieldsOfConsumptionDistributionOfLaborCostsForOutput(CalculationParameters);
	
	// Labor costs <- Estimated
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.LaborCosts, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.LaborCosts,
		Enums.LotRecordTypes.Estimated, ConsumptionFields);
	
	// Addition <- (<without sources - for generating records based on request data>)
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.Supplement);
	
	Return DescriptionOfChains;
	
EndFunction

Function DescriptionOfMechanismsOfDistributionOfLaborCostsForOutput(CalculationParameters)
	
	DistributionTableColumns = TableForDistributionOfLaborCosts_(CalculationParameters).Columns;
	
	RegisterRecordsDetails = CostCalculationAppliedAlgorithms.RegisterRecordsDetails();
	RegisterRecordsDetails.Insert("Context", "DistributionOfLaborCostsForGraduation");
	RegisterRecordsDetails.Insert("RegisterName", Metadata.AccumulationRegisters.WIPLaborCosts.Name);
	RegisterRecordsDetails.Insert("CalculationFields", CostCalculationAppliedAlgorithms.ListOfFields(DistributionTableColumns));
	RegisterRecordsDetails.Insert("ComparisonKeys",	FieldsOfConsumptionDistributionOfLaborCostsForOutput(CalculationParameters));
	RegisterRecordsDetails.Insert("Indicators",	"Count, StandardCost, Cost, LocalCost, CostTD, PermanentDifference, CostOfPersonalIncomeTax");
	RegisterRecordsDetails.Insert("ExceptionsIndicators", "Denominator, ProductsQuantity");
	RegisterRecordsDetails.Insert("BasisOfArrival", "Denominator");
	RegisterRecordsDetails.Insert("BasisOfConsumption", "Denominator");
	RegisterRecordsDetails.Insert("ExpenseKey", "DocumentSource");
	RegisterRecordsDetails.Insert("OrderField_", "Period");
	RegisterRecordsDetails.Insert("SortFields",	"ProductsGroup");
		
	RegisterRecordsDetails.Insert("SummationFields", "Count, StandardCost, Cost, LocalCost, CostTD, PermanentDifference, CostOfPersonalIncomeTax");
	RegisterRecordsDetails.Insert("SummationFieldExceptions", "Denominator, ProductsQuantity");
	RegisterRecordsDetails.Insert("GroupFields", 
		CostCalculationAppliedAlgorithms.ListOfFields(DistributionTableColumns, RegisterRecordsDetails.SummationFields));
	
	RegisterRecordsDetails.Insert(
		"TemporaryTablesForFollowingSteps",
		"RemainingMaterials, ReleaseShares, LotsOfGNZPMaterials, ManufacturedProduct, ClosedParties");
	
	Return RegisterRecordsDetails;
	
EndFunction

Function DescriptionOfUnrecordedDistributionsOfOutputLaborCosts(CalculationParameters)
	
	UnrecordedRecordTypes = New Map;
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.Estimated, True);
	
	UnwrittenPartitions = New Map;
	UnwrittenPartitions.Insert(Enums.SectionsOfInventoryCostAccounting.EmptyRef(), True);
	
	Return CostCalculationAppliedAlgorithms.DescriptionOfNonWritableData(False, UnrecordedRecordTypes, UnwrittenPartitions);
	
EndFunction

Function TableForDistributionOfLaborCosts_(CalculationParameters) Export
	
	Return CostCalculationAppliedAlgorithms.TableForDistributionOfLots(CalculationParameters,
		TextDescriptionOfDataForUnfinishedProductionLaborCosts());
	
EndFunction

// Sample data

Procedure GetDataForDistributionOfLaborCostsPerIssue(CalculationParameters)
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"Organization", // Separator
		"Denominator, ProductsQuantity, Count, StandardCost, Cost, LocalCost, CostOfPersonalIncomeTax", // Resources
		"Organization, Period, Recorder, Priority"); // Order
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		TextOfRequestForDistributionOfLaborCostsForIssue(CalculationParameters),
		NumberingParameters);
	
EndProcedure

// Request texts

// ... general

Function TextOfRequestForDistributionOfLaborCostsForIssue(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// preparation of temporary tables
		+ CostCalculationFillingInformationAboutLots.TextCorrectedDocuments() + Common.QueryBatchSeparator() // CorrectedDocuments_
		+ CostCalculationProduction.TextOfRemainingBatchesOfGNZPMaterials() // Residencymaterials, partiematerialovnzp
		+ CostCalculationProduction.TextOfShareOfCostByProduct() // ManufacturedProduct
		+ CalculationOfCostLocalization.AITSettingsQueryText(
				"", 
				"CalculationOfCostOfLaborCosts_QueryTextForDistributionOfLaborCostsForIssue", 
				CalculationParameters)
		+ Common.QueryBatchSeparator()
		+ TextLaborCostsUnfinishedProductionInitialization()
		+ Common.QueryBatchSeparator()
		// Sample data
		+ TextDescriptionOfDataForUnfinishedProductionLaborCosts()
		+ TMCommonUse.QuerySeparatorInJoin() + TextInitialLaborCostsForDistribution2_2()
		+ TMCommonUse.QuerySeparatorInJoin() + TextOtherLaborCostsForDistribution2_2()
		+ TMCommonUse.QuerySeparatorInJoin() + TextSuspendedLaborCostsForDistribution2_2()
		+ TMCommonUse.QuerySeparatorInJoin() + TextDistributionOfLaborCostsByProduct2_2()
		+ TMCommonUse.QuerySeparatorInJoin() + TextStornoOfLaborCostsOfCorrectedDocumentsOfPreviousPeriod2_2()
		+ "";
	
	Return QueryText;
	
EndFunction

// ... data descriptions

Function TextDescriptionOfDataForUnfinishedProductionLaborCosts() Export
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80))			  				 			 AS RequestSource,
		|	0 													  				 AS Priority,
		|	VALUE(Enum.LotRecordTypes.EmptyRef) 				 AS EntryType,
		|	FALSE 												  				 AS CalculationIsCompleted,
		|
		|	DD.RecordType 				  				 						 AS RecordType,
		|	DD.Period 										 					 AS Period,
		|	DD.Recorder 														 AS Recorder,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		|	DD.Organization 														 AS Organization,
		|	DD.Department 													 AS Department,
		|	DD.ProductionLot												 AS ProductionLot,
		|	DD.ProductionOrder 												 AS ProductionOrder,
		|	0 																	 AS RowCodeProducts,
		|	DD.ContributionsFundKind 													 AS ContributionsFundKind,
		|	VALUE(Catalog.BillsOfMaterials.EmptyRef)				 AS BillOfMaterials,
		|	DD.Stage 															 AS Stage,
		|	DD.ProductCostElement					 							 AS ProductCostElement,
		|	DD.WorkKind 														 AS WorkKind,
		|	DD.ProductsGroup 													 AS ProductsGroup,
		|	0 													 				 AS Denominator,
		|	DD.ProductsQuantity								 				 AS ProductsQuantity,
		|	DD.Count										 				 AS Count,
		|	DD.StandardCost								 				 AS StandardCost,
		|	DD.Cost										 				 AS Cost,
		|	DD.LocalCost									 				 AS LocalCost,
		|	DD.CostTD									 				 AS CostTD,
		|	DD.PermanentDifference									 			 AS PermanentDifference,
		|	DD.CostOfPersonalIncomeTax									 					 AS CostOfPersonalIncomeTax,
		|	FALSE 													 			 AS Primary,
		|	VALUE(Enum.BusinessTransactions.EmptyRef)			 AS BusinessOperation,
		|	DD.Employee 												 		 AS Employee,
		|	DD.CorDimensionOfProductsAccounting 										 AS CorDimensionOfProductsAccounting,
		|	DD.CorAccountingSection 												 	 AS CorAccountingSection,
		|	DD.CorInventoryOwnerAttributesOfProducts 											 AS CorInventoryOwnerAttributesOfProducts,
		|	DD.LotVendorAttributesCorr											 AS LotVendorAttributesCorr,
		|	DD.ProductCostElementWithoutOrder 										 AS ProductCostElementWithoutOrder,
		|	DD.DocumentOfProductionIssue 												 	 AS DocumentOfProductionIssue,
		|	0 												 					 AS RowCode,
		|	DD.Recorder 												 		 AS DocumentSource,
		|	DD.ManufacturedProduct 												 		 AS ManufacturedProduct,
		|	DD.ItemVariant 											 AS ItemVariant,
		|	VALUE(Catalog.Assignments.EmptyRef) 						 AS Purpose,
		|	DD.BusinessTransactionSetting									 AS BusinessTransactionSetting,
		|	DD.FinRecordID											 AS FinRecordID,
		|	FALSE																 AS ReversingEntry
		|INTO Data
		|FROM
		|	AccumulationRegister.WIPLaborCosts AS DD
		|";

	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

// ... data samples

Function TextLaborCostsUnfinishedProductionInitialization()
	Return
		"SELECT
		|	LaborCostsOfUnfinishedProduction.Organization,
		|	LaborCostsOfUnfinishedProduction.Department,
		|	LaborCostsOfUnfinishedProduction.ProductionLot,
		|	LaborCostsOfUnfinishedProduction.ProductCostElement,
		|	LaborCostsOfUnfinishedProduction.WorkKind,
		|	LaborCostsOfUnfinishedProduction.ProductsGroup,
		|	LaborCostsOfUnfinishedProduction.ContributionsFundKind,
		|	SUM(LaborCostsOfUnfinishedProduction.Count),
		|	SUM(LaborCostsOfUnfinishedProduction.StandardCost),
		|	SUM(LaborCostsOfUnfinishedProduction.Cost),
		|	SUM(LaborCostsOfUnfinishedProduction.LocalCost),
		|	SUM(LaborCostsOfUnfinishedProduction.CostTD),
		|	SUM(LaborCostsOfUnfinishedProduction.PermanentDifference),
		|	SUM(LaborCostsOfUnfinishedProduction.CostOfPersonalIncomeTax)
		|INTO InitialRemnantsOfUnfinishedProductionLaborCosts
		|FROM
		|	(SELECT
		|		T.Organization                 AS Organization,
		|		T.Department               AS Department,
		|		T.ProductionLot          AS ProductionLot,
		|		T.ProductCostElement           AS ProductCostElement,
		|		T.WorkKind                    AS WorkKind,
		|		T.ProductsGroup             AS ProductsGroup,
		|		T.ContributionsFundKind             AS ContributionsFundKind,
		|		T.CountBalance           AS Count,
		|		T.StandardCostBalance AS StandardCost,
		|		T.CostBalance            AS Cost,
		|		T.LocalCostBalance        AS LocalCost,
		|		T.CostTDBalance     AS CostTD,
		|		T.PermanentDifferenceBalance    AS PermanentDifference,
		|		T.CostOfPersonalIncomeTaxBalance         AS CostOfPersonalIncomeTax
		|	FROM
		|		AccumulationRegister.WIPLaborCosts.Balance(
		|			&BorderStartOfPeriod,
		|			(Organization, ProductionLot) IN(
		|				SELECT
		|					ProductionBatchesAreSummarized.Organization,
		|					ProductionBatchesAreSummarized.ProductionLot
		|				FROM
		|					ProductionBatchesAreSummarized AS ProductionBatchesAreSummarized
		|				WHERE
		|					ProductionBatchesAreSummarized.CostAllocationForIssue)) AS T
		|	
		|	UNION ALL
		|	
		// We also take storno corrections in the current period into account.
		|	SELECT
		|		DD.Organization          AS Organization,
		|		DD.Department        AS Department,
		|		DD.ProductionLot   AS ProductionLot,
		|		DD.ProductCostElement    AS ProductCostElement,
		|		DD.WorkKind             AS WorkKind,
		|		DD.ProductsGroup      AS ProductsGroup,
		|		DD.ContributionsFundKind      AS ContributionsFundKind,
		|		DD.Count           AS Count,
		|		DD.StandardCost AS StandardCost,
		|		DD.Cost            AS Cost,
		|		DD.LocalCost        AS LocalCost,
		|		DD.CostTD     AS CostTD,
		|		DD.PermanentDifference    AS PermanentDifference,
		|		DD.CostOfPersonalIncomeTax         AS CostOfPersonalIncomeTax
		|	FROM
		|		AccumulationRegister.WIPLaborCosts AS DD
		|	
		|		INNER JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.ReversedDocument = DD.Recorder
		|		
		|		INNER JOIN ProductionBatchesAreSummarized AS Lots
		|		ON DD.ProductionLot = Lots.ProductionLot
		|		AND DD.Organization = Lots.Organization
		|	
		|	WHERE
		|		DD.Period < &BeginOfPeriod
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND DD.Active
		|		AND DD.LotCalculation
		|		AND NOT DD.ReversingEntry
		|		AND Lots.CostAllocationForIssue
		|	) AS LaborCostsOfUnfinishedProduction
		|
		|GROUP BY
		|	LaborCostsOfUnfinishedProduction.ProductionLot,
		|	LaborCostsOfUnfinishedProduction.Organization,
		|	LaborCostsOfUnfinishedProduction.ProductCostElement,
		|	LaborCostsOfUnfinishedProduction.ContributionsFundKind,
		|	LaborCostsOfUnfinishedProduction.ProductsGroup,
		|	LaborCostsOfUnfinishedProduction.WorkKind,
		|	LaborCostsOfUnfinishedProduction.Department
		|;
		|
		|
		|////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	LaborCostsByStages.Organization,
		|	LaborCostsByStages.Department,
		|	LaborCostsByStages.ProductionLot,
		|	LaborCostsByStages.ProductCostElement,
		|	LaborCostsByStages.WorkKind,
		|	LaborCostsByStages.ProductsGroup,
		|	LaborCostsByStages.ContributionsFundKind,
		|	SUM(LaborCostsByStages.Count) AS Count,
		|	SUM(LaborCostsByStages.StandardCost) AS StandardCost,
		|	SUM(LaborCostsByStages.Cost) AS Cost,
		|	SUM(LaborCostsByStages.LocalCost) AS LocalCost,
		|	SUM(LaborCostsByStages.CostTD) AS CostTD,
		|	SUM(LaborCostsByStages.PermanentDifference) AS PermanentDifference,
		|	SUM(CASE
		|			WHEN FALSE THEN 0 // for easy tag placement
		|			WHEN ISNULL(SettingsForRecognitionOfLBExpensesByBusinessUnits.ExpensesAreIncludedInCost, FALSE)
		|				THEN LaborCostsByStages.CostOfPersonalIncomeTax
		|			WHEN ISNULL(SettingsForRecognitionOfLBExpensesInAreasOfActivity.ExpensesAreIncludedInCost, FALSE)
		|				THEN LaborCostsByStages.CostOfPersonalIncomeTax
		|			ELSE 0 
		|		END) AS CostOfPersonalIncomeTax
		|INTO LaborCostsByStages
		|FROM
		|	(SELECT
		|		Balance.Organization          AS Organization,
		|		Balance.Department        AS Department,
		|		Balance.ProductionLot   AS ProductionLot,
		|		Balance.ProductCostElement    AS ProductCostElement,
		|		Balance.WorkKind             AS WorkKind,
		|		Balance.ProductsGroup      AS ProductsGroup,
		|		Balance.ContributionsFundKind      AS ContributionsFundKind,
		|		Balance.Count           AS Count,
		|		Balance.StandardCost AS StandardCost,
		|		Balance.Cost            AS Cost,
		|		Balance.LocalCost        AS LocalCost,
		|		Balance.CostTD     AS CostTD,
		|		Balance.PermanentDifference    AS PermanentDifference,
		|		Balance.CostOfPersonalIncomeTax         AS CostOfPersonalIncomeTax
		|	FROM
		|		InitialRemnantsOfUnfinishedProductionLaborCosts AS Balance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DD.Organization          AS Organization,
		|		DD.Department        AS Department,
		|		DD.ProductionLot   AS ProductionLot,
		|		DD.ProductCostElement    AS ProductCostElement,
		|		DD.WorkKind             AS WorkKind,
		|		DD.ProductsGroup      AS ProductsGroup,
		|		DD.ContributionsFundKind      AS ContributionsFundKind,
		|		DD.Count           AS Count,
		|		DD.StandardCost AS StandardCost,
		|		DD.Cost            AS Cost,
		|		DD.LocalCost        AS LocalCost,
		|		DD.CostTD     AS CostTD,
		|		DD.PermanentDifference    AS PermanentDifference,
		|		DD.CostOfPersonalIncomeTax         AS CostOfPersonalIncomeTax
		|	FROM
		|		AccumulationRegister.WIPLaborCosts AS DD
		|		
		|		INNER JOIN ProductionBatchesAreSummarized AS Lots
		|		ON DD.ProductionLot = Lots.ProductionLot
		|		AND DD.Organization = Lots.Organization
		|	WHERE
		|		DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND DD.Organization IN(&CompanyArray)
		|		AND Lots.CostAllocationForIssue
		|	) AS LaborCostsByStages
		|
		|	LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesByBusinessUnits
		|	ON SettingsForRecognitionOfLBExpensesByBusinessUnits.Organization = LaborCostsByStages.Organization
		|		AND SettingsForRecognitionOfLBExpensesByBusinessUnits.ObjectOfSeparateAccountingAIT = LaborCostsByStages.Department
		|
		|	LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesInAreasOfActivity
		|	ON SettingsForRecognitionOfLBExpensesInAreasOfActivity.Organization = LaborCostsByStages.Organization
		|		AND SettingsForRecognitionOfLBExpensesInAreasOfActivity.ObjectOfSeparateAccountingAIT
		|			= LaborCostsByStages.ProductionLot.LineOfBusiness
		|
		|GROUP BY
		|	LaborCostsByStages.ProductionLot,
		|	LaborCostsByStages.Organization,
		|	LaborCostsByStages.ProductCostElement,
		|	LaborCostsByStages.ContributionsFundKind,
		|	LaborCostsByStages.ProductsGroup,
		|	LaborCostsByStages.WorkKind,
		|	LaborCostsByStages.Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Organization,
		|	DD.Department,
		|	DD.ProductionLot,
		|	DD.ProductsGroup,
		|	DD.WorkKind,
		|	DD.ProductCostElement,
		|	SUM(DD.Count) AS Count
		|INTO ListOfTypesOfWorkByStages
		|FROM
		|	LaborCostsByStages AS DD
		|
		|GROUP BY
		|	DD.Organization,
		|	DD.Department,
		|	DD.WorkKind,
		|	DD.ProductCostElement,
		|	DD.ProductionLot,
		|	DD.ProductsGroup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Organization AS Organization,
		|	DD.Department AS Department,
		|	DD.ProductionLot AS ProductionLot,
		|	DD.ProductsGroup AS ProductsGroup,
		|	DD.WorkKind AS WorkKind,
		|	DD.ProductCostElement AS ProductCostElement,
		|	SUM(DD.Plan) AS Plan,
		|	SUM(DD.Real) AS Real
		|INTO PlanOfReductionOfLaborCostsByStages
		|FROM
		|	(SELECT
		|		BackflushProduction.Organization AS Organization,
		|		ActivityKinds.Department AS Department,
		|		DD.ProductionLot AS ProductionLot,
		|		CASE
		|			WHEN DD.FinancialAccountingDimension = UNDEFINED
		|				THEN VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
		|			ELSE
		|				DD.FinancialAccountingDimension
		|		END AS ProductsGroup,
		|		ActivityKinds.WorkKind AS WorkKind,
		|		ActivityKinds.ProductCostElement AS ProductCostElement,
		|		ActivityKinds.Count AS Plan,
		|		0 AS Real
		|	FROM
		|		ProductionBatchesByStages AS DD
		|		
		|		INNER JOIN Document.BackflushProduction.LaborCosts AS ActivityKinds
		|		ON DD.Stage = ActivityKinds.Ref
		|		
		|		INNER JOIN Document.BackflushProduction AS BackflushProduction
		|		ON DD.Stage = BackflushProduction.Ref
		|		AND DD.Organization = BackflushProduction.Organization
		|		
		|	WHERE
		|		BackflushProduction.ReferenceOrderForLaborCosts
		|		AND DD.CostAllocationForIssue
		|
		|	UNION ALL
		|
		|	SELECT
		|		DocumentStage.Organization AS Organization,
		|		ActivityKinds.Department AS Department,
		|		DD.ProductionLot AS ProductionLot,
		|		CASE
		|			WHEN DD.FinancialAccountingDimension = UNDEFINED
		|				THEN VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
		|			ELSE
		|				DD.FinancialAccountingDimension
		|		END AS ProductsGroup,
		|		ActivityKinds.WorkKind AS WorkKind,
		|		ActivityKinds.ProductCostElement AS ProductCostElement,
		|		ActivityKinds.Count AS Plan,
		|		0 AS Real
		|	FROM
		|		ProductionBatchesAreSummarized AS DD
		|
		|			INNER JOIN Document.ProductionStage2_2 AS DocumentStage
		|			ON DD.ProductionLot = DocumentStage.ProductionLot
		|				AND DD.Organization = DocumentStage.Organization
		|
		|			INNER JOIN Document.ProductionStage2_2.LaborCosts AS ActivityKinds
		|			ON DocumentStage.Ref = ActivityKinds.Ref
		|	WHERE
		|		NOT ActivityKinds.Canceled
		|		AND DD.CostAllocationForIssue
		|
		|	UNION ALL
		|
		|	SELECT
		|		RegisterRecords.Organization AS Organization,
		|		RegisterRecords.Department AS Department,
		|		RegisterRecords.ProductionLot AS ProductionLot,
		|		RegisterRecords.ProductsGroup AS ProductsGroup,
		|		RegisterRecords.WorkKind AS WorkKind,
		|		RegisterRecords.ProductCostElement AS ProductCostElement,
		|		0 AS Plan,
		|		RegisterRecords.Count AS Real
		|	FROM
		|		ProductionBatchesAreSummarized AS DD
		|		
		|		INNER JOIN AccumulationRegister.WIPLaborCosts AS RegisterRecords
		|		ON DD.ProductionLot = RegisterRecords.ProductionLot
		|		AND DD.Organization = RegisterRecords.Organization
		|		
		|	WHERE
		|		RegisterRecords.Period <= &EndOfPeriod
		|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND NOT RegisterRecords.Count = 0
		|		AND DD.CostAllocationForIssue
		|	) AS DD
		|
		|GROUP BY
		|	DD.Organization,
		|	DD.Department,
		|	DD.ProductionLot,
		|	DD.ProductsGroup,
		|	DD.WorkKind,
		|	DD.ProductCostElement
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Expenses.ProductionLot,
		|	Expenses.ProductsGroup,
		|	Expenses.Department,
		|	Expenses.WorkKind,
		|	Expenses.ProductCostElement,
		|	Expenses.CountExpense AS Count
		|INTO TTWrittenOffInPreviousMonths
		|FROM
		|	AccumulationRegister.WIPLaborCosts.Turnovers(, DATEADD(&BeginOfPeriod, SECOND, -1),,
		|		ProductionLot IN(
		|			SELECT
		|				ProductionBatchesAreSummarized.ProductionLot
		|			FROM
		|				ProductionBatchesAreSummarized AS ProductionBatchesAreSummarized
		|			WHERE
		|				ProductionBatchesAreSummarized.LongTermProduction
		|				AND ProductionBatchesAreSummarized.CostAllocationForIssue)
		|		) AS Expenses
		|
		|INDEX BY
		|	ProductionLot,
		|	Department,
		|	WorkKind,
		|	ProductCostElement,
		|	ProductsGroup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Organization,
		|	DD.ProductionLot,
		|	DD.ProductsGroup,
		|	DD.Department,
		|	DD.WorkKind,
		|	DD.ProductCostElement,
		|	CASE
		|		WHEN DD.Plan > DD.Real
		|			THEN DD.Plan
		|		ELSE DD.Real
		|	END * ReleaseShares.ShareOfTotalOutput - ISNULL(WrittenOff.Count, 0) AS EstimatedQuantity,
		|	ReleaseShares.ProductionCompleted
		|INTO TTEstimatedQuantity
		|FROM
		|	PlanOfReductionOfLaborCostsByStages AS DD
		|		INNER JOIN ReleaseShares AS ReleaseShares
		|		ON DD.ProductionLot = ReleaseShares.ProductionLot
		|		AND DD.Organization = ReleaseShares.Organization
		|
		|		LEFT JOIN TTWrittenOffInPreviousMonths AS WrittenOff
		|		ON DD.ProductionLot = WrittenOff.ProductionLot
		|		AND DD.Department = WrittenOff.Department
		|		AND DD.WorkKind = WrittenOff.WorkKind
		|		AND DD.ProductCostElement = WrittenOff.ProductCostElement
		|		AND DD.ProductsGroup = WrittenOff.ProductsGroup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Organization,
		|	DD.ProductionLot,
		|	DD.ProductsGroup,
		|	DD.Department,
		|	DD.WorkKind,
		|	DD.ProductCostElement,
		|	Balance.Count AS Count,
		|	CASE
		|		WHEN DD.ProductionCompleted
		|			THEN ISNULL(Balance.Count, 0)
		|		WHEN DD.EstimatedQuantity > ISNULL(Balance.Count, 0)
		|			THEN ISNULL(Balance.Count, 0)
		|		ELSE DD.EstimatedQuantity
		|	END AS EstimatedQuantity
		|INTO Estimated
		|FROM
		|	TTEstimatedQuantity AS DD
		|		LEFT JOIN ListOfTypesOfWorkByStages AS Balance
		|		ON DD.Organization = Balance.Organization
		|			AND DD.ProductionLot = Balance.ProductionLot
		|			AND DD.Department = Balance.Department
		|			AND DD.WorkKind = Balance.WorkKind
		|			AND DD.ProductCostElement = Balance.ProductCostElement
		|			AND DD.ProductsGroup = Balance.ProductsGroup
		|WHERE
		|	CASE
		|		WHEN DD.ProductionCompleted
		|			THEN ISNULL(Balance.Count, 0)
		|		WHEN DD.EstimatedQuantity > ISNULL(Balance.Count, 0)
		|			THEN ISNULL(Balance.Count, 0)
		|		ELSE DD.EstimatedQuantity
		|	END <> 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// Estimated quantity without calculation items. It is used for the distribution of contributions and salary amounts
		// accrued under calculation items other than quantity calculation items. That is, the estimated amount for calculating the amounts accrued
		// under the calculation items are distributed in the context of calculation items, and the estimated amount for accruals under other calculation items in contributions (with zero amount)
		// is calculated based on the total number of types of work for all calculation items.
		|SELECT
		|	DD.Organization,
		|	DD.ProductionLot,
		|	DD.ProductsGroup,
		|	DD.Department,
		|	DD.WorkKind,
		|	SUM(DD.Count),
		|	SUM(DD.EstimatedQuantity)
		|INTO CalculatedSummary
		|FROM
		|	Estimated AS DD
		|
		|GROUP BY
		|	DD.Organization,
		|	DD.ProductionLot,
		|	DD.ProductsGroup,
		|	DD.Department,
		|	DD.WorkKind
		|";
EndFunction

Function TextInitialLaborCostsForDistribution2_2() // Uses labor input by steps, topping up, Calculated
	Return
		"SELECT
		|	""TextInitialLaborCostsForDistribution2_2"" AS RequestSource,
		|	0 AS Priority,
		|	VALUE(Enum.LotRecordTypes.Estimated) AS EntryType,
		|	TRUE AS CalculationIsCompleted,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	&EndOfPeriod AS Period,
		|	UNDEFINED AS Recorder,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS AccountingSection,
		|	DD.Organization,
		|	DD.Department AS Department,
		|	DD.ProductionLot AS ProductionLot,
		|	UNDEFINED AS ProductionOrder,
		|	0 AS RowCodeProducts,
		|	DD.ContributionsFundKind AS ContributionsFundKind,
		|	UNDEFINED AS BillOfMaterials,
		|	UNDEFINED AS Stage,
		|	DD.ProductCostElement AS ProductCostElement,
		|	DD.WorkKind AS WorkKind,
		|	DD.ProductsGroup AS ProductsGroup,
		|	Total.ShareOfIssueOfMonth AS Denominator,
		|	0 AS ProductsQuantity,
		|	Estimated.EstimatedQuantity AS Count,
		|	DD.StandardCost * Estimated.EstimatedQuantity / DD.Count AS StandardCost,
		|	DD.Cost * Estimated.EstimatedQuantity / DD.Count AS Cost,
		|	DD.LocalCost * Estimated.EstimatedQuantity / DD.Count AS LocalCost,
		|	DD.CostTD * Estimated.EstimatedQuantity / DD.Count AS CostTD,
		|	DD.PermanentDifference * Estimated.EstimatedQuantity / DD.Count AS PermanentDifference,
		|	DD.CostOfPersonalIncomeTax * Estimated.EstimatedQuantity / DD.Count AS CostOfPersonalIncomeTax,
		|	FALSE AS Primary,
		|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
		|	UNDEFINED AS Employee,
		|	UNDEFINED AS CorDimensionOfProductsAccounting,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorInventoryOwnerAttributesOfProducts,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	UNDEFINED AS ProductCostElementWithoutOrder,
		|	UNDEFINED AS DocumentOfProductionIssue,
		|	0 AS RowCode,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS ManufacturedProduct,
		|	UNDEFINED AS ItemVariant,
		|	UNDEFINED AS Purpose,
		|	UNDEFINED AS BusinessTransactionSetting,
		|	"""" AS FinRecordID,
		|	FALSE AS ReversingEntry
		|FROM
		|	LaborCostsByStages AS DD
		|		INNER JOIN ReleaseShares AS Total
		|		ON DD.ProductionLot = Total.ProductionLot
		|		AND DD.Organization = Total.Organization
		|
		|		INNER JOIN Estimated AS Estimated
		|		ON DD.ProductionLot = Estimated.ProductionLot
		|			AND DD.Department = Estimated.Department
		|			AND DD.WorkKind = Estimated.WorkKind
		|			AND DD.ProductCostElement = Estimated.ProductCostElement
		|			AND DD.ProductsGroup = Estimated.ProductsGroup
		|WHERE
		|	DD.Count <> 0";

EndFunction

Function TextOtherLaborCostsForDistribution2_2() // Uses labor input by steps, topping up, settlement by water  
	Return
		"SELECT
		|	""TextOtherLaborCostsForDistribution2_2"" AS RequestSource,
		|	0 AS Priority,
		|	VALUE(Enum.LotRecordTypes.Estimated) AS EntryType,
		|	TRUE AS CalculationIsCompleted,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	&EndOfPeriod AS Period,
		|	UNDEFINED AS Recorder,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS AccountingSection,
		|	DD.Organization,
		|	DD.Department AS Department,
		|	DD.ProductionLot AS ProductionLot,
		|	UNDEFINED AS ProductionOrder,
		|	0 AS RowCodeProducts,
		|	DD.ContributionsFundKind AS ContributionsFundKind,
		|	UNDEFINED AS BillOfMaterials,
		|	UNDEFINED AS Stage,
		|	DD.ProductCostElement AS ProductCostElement,
		|	DD.WorkKind AS WorkKind,
		|	DD.ProductsGroup AS ProductsGroup,
		|	Total.ShareOfIssueOfMonth AS Denominator,
		|	0 AS ProductsQuantity,
		|	0 AS Count,
		|	0 AS StandardCost,
		|	CASE
		|		WHEN CalculatedSummary.Count = 0
		|			THEN DD.Cost
		|		ELSE DD.Cost * CalculatedSummary.EstimatedQuantity / CalculatedSummary.Count
		|	END AS Cost,
		|	CASE
		|		WHEN CalculatedSummary.Count = 0
		|			THEN DD.LocalCost
		|		ELSE DD.LocalCost * CalculatedSummary.EstimatedQuantity / CalculatedSummary.Count
		|	END AS LocalCost,
		|	CASE
		|		WHEN CalculatedSummary.Count = 0
		|			THEN DD.CostTD
		|		ELSE DD.CostTD * CalculatedSummary.EstimatedQuantity / CalculatedSummary.Count
		|	END AS CostTD,
		|	CASE
		|		WHEN CalculatedSummary.Count = 0
		|			THEN DD.PermanentDifference
		|		ELSE DD.PermanentDifference * CalculatedSummary.EstimatedQuantity / CalculatedSummary.Count
		|	END AS PermanentDifference,
		|	CASE
		|		WHEN CalculatedSummary.Count = 0
		|			THEN DD.CostOfPersonalIncomeTax
		|		ELSE DD.CostOfPersonalIncomeTax * CalculatedSummary.EstimatedQuantity / CalculatedSummary.Count
		|	END AS CostOfPersonalIncomeTax,
		|	FALSE AS Primary,
		|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
		|	UNDEFINED AS Employee,
		|	UNDEFINED AS CorDimensionOfProductsAccounting,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorInventoryOwnerAttributesOfProducts,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	UNDEFINED AS ProductCostElementWithoutOrder,
		|	UNDEFINED AS DocumentOfProductionIssue,
		|	0 AS RowCode,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS ManufacturedProduct,
		|	UNDEFINED AS ItemVariant,
		|	UNDEFINED AS Purpose,
		|	UNDEFINED AS BusinessTransactionSetting,
		|	"""" AS FinRecordID,
		|	FALSE AS ReversingEntry
		|FROM
		|	LaborCostsByStages AS DD
		|		INNER JOIN ReleaseShares AS Total
		|		ON DD.ProductionLot = Total.ProductionLot
		|		AND DD.Organization = Total.Organization
		|
		|		INNER JOIN CalculatedSummary AS CalculatedSummary
		|		ON DD.ProductionLot = CalculatedSummary.ProductionLot
		|			AND DD.Department = CalculatedSummary.Department
		|			AND DD.WorkKind = CalculatedSummary.WorkKind
		|			AND DD.ProductsGroup = CalculatedSummary.ProductsGroup
		|WHERE
		|	DD.Count = 0";

EndFunction

Function TextSuspendedLaborCostsForDistribution2_2() // Uses labor input by steps, topping up, settlement by water
	
	Return
		// The reflection of wages may not cover the totals for the corrected labor costs of Lot references of production,
		// for which there is no quantity for distribution. Such expenses relate to the products in full.
		"SELECT
		|	""TextSuspendedLaborCostsForDistribution2_2"" AS RequestSource,
		|	0 AS Priority,
		|	VALUE(Enum.LotRecordTypes.Estimated) AS EntryType,
		|	TRUE AS CalculationIsCompleted,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	&EndOfPeriod AS Period,
		|	UNDEFINED AS Recorder,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS AccountingSection,
		|	DD.Organization,
		|	DD.Department AS Department,
		|	DD.ProductionLot AS ProductionLot,
		|	UNDEFINED AS ProductionOrder,
		|	0 AS RowCodeProducts,
		|	DD.ContributionsFundKind AS ContributionsFundKind,
		|	UNDEFINED AS BillOfMaterials,
		|	UNDEFINED AS Stage,
		|	DD.ProductCostElement AS ProductCostElement,
		|	DD.WorkKind AS WorkKind,
		|	DD.ProductsGroup AS ProductsGroup,
		|	Total.ShareOfIssueOfMonth AS Denominator,
		|	0 AS ProductsQuantity,
		|	0 AS Count,
		|	0 AS StandardCost,
		|	DD.Cost AS Cost,
		|	DD.LocalCost AS LocalCost,
		|	DD.CostTD AS CostTD,
		|	DD.PermanentDifference AS PermanentDifference,
		|	DD.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax,
		|	FALSE AS Primary,
		|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
		|	UNDEFINED AS Employee,
		|	UNDEFINED AS CorDimensionOfProductsAccounting,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorInventoryOwnerAttributesOfProducts,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	UNDEFINED AS ProductCostElementWithoutOrder,
		|	UNDEFINED AS DocumentOfProductionIssue,
		|	0 AS RowCode,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS ManufacturedProduct,
		|	UNDEFINED AS ItemVariant,
		|	UNDEFINED AS Purpose,
		|	UNDEFINED AS BusinessTransactionSetting,
		|	"""" AS FinRecordID,
		|	FALSE AS ReversingEntry
		|FROM
		|	LaborCostsByStages AS DD
		|	
		|	INNER JOIN ReleaseShares AS Total
		|	ON DD.ProductionLot = Total.ProductionLot
		|	AND DD.Organization = Total.Organization
		|	
		|	LEFT JOIN CalculatedSummary AS CalculatedSummary
		|	ON DD.ProductionLot = CalculatedSummary.ProductionLot
		|	AND DD.Department = CalculatedSummary.Department
		|	AND DD.WorkKind = CalculatedSummary.WorkKind
		|	AND DD.ProductsGroup = CalculatedSummary.ProductsGroup
		|WHERE
		|	DD.Count = 0
		|	AND CalculatedSummary.ProductionLot IS NULL
		|";

EndFunction
	
Function TextDistributionOfLaborCostsByProduct2_2() // uses Products
	
	Return "
	|SELECT
	|	""TextDistributionOfLaborCostsByProduct2_2"" AS RequestSource,
	|	0 AS Priority,
	|	VALUE(Enum.LotRecordTypes.LaborCosts) AS EntryType,
	|	FALSE AS CalculationIsCompleted,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DD.ProductionDate AS Period,
	|	ISNULL(CalculationLoggers.Ref, DD.ReleaseParty) AS Recorder,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS AccountingSection,
	|	DD.Organization,
	|	DD.Department AS Department,
	|	DD.ProductionLot AS ProductionLot,
	|	UNDEFINED AS ProductionOrder,
	|	0 AS RowCodeProducts,
	|	UNDEFINED AS ContributionsFundKind,
	|	UNDEFINED AS BillOfMaterials,
	|	UNDEFINED AS Stage,
	|	UNDEFINED AS ProductCostElement,
	|	UNDEFINED AS WorkKind,
	|	UNDEFINED AS ProductsGroup,
	|	SUM(DD.ShareOfMonthName) AS Denominator,
	|	SUM(DD.ProductsQuantity) AS ProductsQuantity,
	|	0 AS Count,
	|	0 AS StandardCost,
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostTD,
	|	0 AS PermanentDifference,
	|	0 AS CostOfPersonalIncomeTax,
	|	FALSE AS Primary,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	UNDEFINED AS Employee,
	|	CASE
	|		WHEN TRUE
	|			THEN DD.ItemsLocationAttributes
	|	END AS CorDimensionOfProductsAccounting,
	|	CASE
	|		WHEN TRUE
	|			THEN DD.AccountingSection
	|	END AS CorAccountingSection,
	|	CASE
	|		WHEN TRUE
	|			THEN DD.InventoryOwnerAttribute
	|	END AS CorInventoryOwnerAttributesOfProducts,
	|	CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.FIFORollingValuation)
	|			THEN DD.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END AS LotVendorAttributesCorr,
	|	UNDEFINED AS ProductCostElementWithoutOrder,
	|	UNDEFINED AS DocumentOfProductionIssue,
	|	0 AS RowCode,
	|	UNDEFINED AS DocumentSource,
	|	UNDEFINED AS ManufacturedProduct,
	|	UNDEFINED AS ItemVariant,
	|	UNDEFINED AS Purpose,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseLaborCosts) AS BusinessTransactionSetting,
	|	MAX(DD.FinRecordID) AS FinRecordID,
	|	FALSE AS ReversingEntry
	|FROM
	|	ManufacturedProduct AS DD
	|		LEFT JOIN Document.BackflushProduction AS BackflushProduction
	|		ON BackflushProduction.Ref = DD.ReleaseParty
	|
	|
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|
	|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
	|		ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
	|		LEFT JOIN TTCostCalculationRecorders AS CalculationLoggers
	|		ON CalculationLoggers.Organization = DD.Organization
	|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	
	|WHERE
	|	((ISNULL(BackflushProduction.ReferenceOrderForLaborCosts, FALSE)
	|		AND DD.Organization = BackflushProduction.Organization)
	|		OR VALUETYPE(CatProductionLots.Document) = TYPE(Document.ProductionOrder2_2)
	|		OR VALUETYPE(DD.ReleaseParty) = TYPE(Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
	|	)
	|	AND DD.ShareOfMonthName > 0
	|	
	|GROUP BY
	|	DD.ProductionDate,
	|	ISNULL(CalculationLoggers.Ref, DD.ReleaseParty),
	|	DD.Organization,
	|	DD.Department,
	|	DD.ProductionLot,
	|	CASE
	|		WHEN TRUE
	|			THEN DD.ItemsLocationAttributes
	|	END,
	|	CASE
	|		WHEN TRUE
	|			THEN DD.AccountingSection
	|	END,
	|	CASE
	|		WHEN TRUE
	|			THEN DD.InventoryOwnerAttribute
	|	END,
	|	CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.FIFORollingValuation)
	|			THEN DD.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN CalculationLoggers.Ref IS NULL
	|		THEN DD.FinRecordID
	|		ELSE UNDEFINED
	|	END
	|";
	
EndFunction

Function TextStornoOfLaborCostsOfCorrectedDocumentsOfPreviousPeriod2_2() // uses Products
	
	Return
	"SELECT
	|	""TextStornoOfLaborCostsOfCorrectedDocumentsOfPreviousPeriod2_2"" AS RequestSource,
	|	0                                                         AS Priority,
	|	VALUE(Enum.LotRecordTypes.Supplement)       AS EntryType,
	|	TRUE                                                    AS CalculationIsCompleted,
	|
	|	DD.RecordType                                            AS RecordType,
	|	CorrectedDocuments_.Period                              AS Period,
	|	CorrectedDocuments_.Recorder                         AS Recorder,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS AccountingSection,
	|
	// Measurements.
	|	DD.Organization                                            AS Organization,
	|	DD.Department                                          AS Department,
	|	DD.ProductionLot                                     AS ProductionLot,
	|	DD.ProductionOrder                                    AS ProductionOrder,
	|	DD.RowCodeProducts                                     AS RowCodeProducts,
	|	DD.ContributionsFundKind                                        AS ContributionsFundKind,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)   AS BillOfMaterials,
	|	DD.Stage                                                   AS Stage,
	|	DD.ProductCostElement                                      AS ProductCostElement,
	|	DD.WorkKind                                               AS WorkKind,
	|	DD.ProductsGroup                                        AS ProductsGroup,
	|
	|	1                                                         AS Denominator,
	|
	// Resources.
	|	SUM(DD.ProductsQuantity)                             AS ProductsQuantity,
	|	SUM(-DD.Count)                                     AS Count,
	|	SUM(-DD.StandardCost)                           AS StandardCost,
	|	SUM(-DD.Cost)                                      AS Cost,
	|	SUM(-DD.LocalCost)                                  AS LocalCost,
	|	SUM(-DD.CostTD)                               AS CostTD,
	|	SUM(-DD.PermanentDifference)                              AS PermanentDifference,
	|	SUM(-DD.CostOfPersonalIncomeTax)                                   AS CostOfPersonalIncomeTax,
	|
	|	FALSE                                                      AS Primary,
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
	|
	// Attributes
	|	DD.Employee                                              AS Employee,
	|	DD.CorDimensionOfProductsAccounting                             AS CorDimensionOfProductsAccounting,
	|	DD.CorAccountingSection                                         AS CorAccountingSection,
	|	DD.CorInventoryOwnerAttributesOfProducts                                 AS CorInventoryOwnerAttributesOfProducts,
	|	DD.LotVendorAttributesCorr                                AS LotVendorAttributesCorr,
	|	DD.ProductCostElementWithoutOrder                             AS ProductCostElementWithoutOrder,
	|	DD.DocumentOfProductionIssue                                        AS DocumentOfProductionIssue,
	|	DD.RowCode                                              AS RowCode,
	|	DD.Recorder                                            AS DocumentSource,
	|	DD.ManufacturedProduct                                              AS ManufacturedProduct,
	|	DD.ItemVariant                                AS ItemVariant,
	|	VALUE(Catalog.Assignments.EmptyRef)              AS Purpose,
	|	DD.BusinessTransactionSetting                         AS BusinessTransactionSetting,
	|	DD.FinRecordID                                 AS FinRecordID,
	|	TRUE                                                    AS ReversingEntry
	|FROM
	|	AccumulationRegister.WIPLaborCosts AS DD
	|	
	|	INNER JOIN CorrectedDocuments_ AS CorrectedDocuments_
	|	ON CorrectedDocuments_.ReversedDocument = DD.Recorder
	|	
	|WHERE
	|	DD.Organization IN (&CompanyArray)
	|	AND DD.Period < &BeginOfPeriod
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND DD.Active
	|	AND DD.LotCalculation
	|	AND NOT DD.ReversingEntry
	|	AND NOT (&BatchAccountingWasUsedBeforeSwitchingToVersion22 = TRUE // the parameter value can be UNDEFINED
	|		AND DD.Period < &DateOfMigrationToBatchAccounting22)
	|
	|GROUP BY
	|	DD.RecordType,
	|	CorrectedDocuments_.Period,
	|	CorrectedDocuments_.Recorder,
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.Department,
	|	DD.ProductionLot,
	|	DD.ProductionOrder,
	|	DD.RowCodeProducts,
	|	DD.ContributionsFundKind,
	|	DD.Stage,
	|	DD.ProductCostElement,
	|	DD.WorkKind,
	|	DD.ProductsGroup,
	|	DD.BusinessTransactionSetting,
	|	DD.FinRecordID,
	|	DD.Employee,
	|	DD.CorDimensionOfProductsAccounting,
	|	DD.CorAccountingSection,
	|	DD.CorInventoryOwnerAttributesOfProducts,
	|	DD.LotVendorAttributesCorr,
	|	DD.ProductCostElementWithoutOrder,
	|	DD.DocumentOfProductionIssue,
	|	DD.RowCode,
	|	DD.ManufacturedProduct,
	|	DD.ItemVariant
	|
	|HAVING
	|	NOT SUM(DD.Count) = 0
	|	OR NOT SUM(DD.StandardCost) = 0
	|	OR NOT SUM(DD.Cost) = 0
	|	OR NOT SUM(DD.LocalCost) = 0
	|	OR NOT SUM(DD.PermanentDifference) = 0
	|	OR NOT SUM(DD.CostTD) = 0
	|	OR NOT SUM(DD.CostOfPersonalIncomeTax) = 0
	|";

EndFunction

// Filling out the payment batch
Procedure FillInEstimatedBatchDistributionOfLaborCostsForRelease(CalculationParameters, SettlementBatch, Expense, Receipt)
	
	FillPropertyValues(SettlementBatch, Expense);
	
	If Receipt.Denominator = 0 Then
		Return;
	EndIf;
	
	// the calculated batch is filled with the largest total deductible
	WriteOffDenominator = Min(Expense.Denominator, Receipt.Denominator);
	
	// we fill in the indicators of the settlement batch
	SettlementBatch.Count 			 = Round(WriteOffDenominator * Receipt.Count / Receipt.Denominator, 3);
	SettlementBatch.StandardCost = Round(WriteOffDenominator * Receipt.StandardCost / Receipt.Denominator, 2);
	SettlementBatch.Cost 			 = Round(WriteOffDenominator * Receipt.Cost / Receipt.Denominator, 2);
	SettlementBatch.LocalCost 		 = Round(WriteOffDenominator * Receipt.LocalCost / Receipt.Denominator, 2);
	SettlementBatch.CostTD 	 = Round(WriteOffDenominator * Receipt.CostTD / Receipt.Denominator, 2);
	SettlementBatch.PermanentDifference 	 = Round(WriteOffDenominator * Receipt.PermanentDifference / Receipt.Denominator, 2);
	SettlementBatch.CostOfPersonalIncomeTax 		 = Round(WriteOffDenominator * Receipt.CostOfPersonalIncomeTax / Receipt.Denominator, 2);
	
	// adjusting the calculation base in the parish
	Receipt.Count 			= Receipt.Count - SettlementBatch.Count;
	Receipt.StandardCost = Receipt.StandardCost - SettlementBatch.StandardCost;
	Receipt.Cost 			= Receipt.Cost - SettlementBatch.Cost;
	Receipt.LocalCost 		= Receipt.LocalCost - SettlementBatch.LocalCost;
	Receipt.CostTD 	= Receipt.CostTD - SettlementBatch.CostTD;
	Receipt.PermanentDifference 	= Receipt.PermanentDifference - SettlementBatch.PermanentDifference;
	Receipt.CostOfPersonalIncomeTax 		= Receipt.CostOfPersonalIncomeTax - SettlementBatch.CostOfPersonalIncomeTax;
	Receipt.Denominator 			= Receipt.Denominator - WriteOffDenominator;
	
	// We fill in the batch identification in the settlement batch
	If Not ValueIsFilled(SettlementBatch.DocumentSource) Then
		SettlementBatch.DocumentSource = Receipt.Recorder;
	EndIf;
	
	If Not ValueIsFilled(SettlementBatch.Recorder) Then
		SettlementBatch.Recorder = Receipt.Recorder;
	EndIf;
	
	If Not ValueIsFilled(SettlementBatch.ProductCostElementWithoutOrder) Then
		SettlementBatch.ProductCostElementWithoutOrder = Receipt.ProductCostElementWithoutOrder;
	EndIf;
	
	SettlementBatch.Department 	  = Receipt.Department;
	SettlementBatch.ContributionsFundKind   = Receipt.ContributionsFundKind;
	SettlementBatch.WorkKind 		  = Receipt.WorkKind;
	SettlementBatch.ProductsGroup   = Receipt.ProductsGroup;
	SettlementBatch.ProductCostElement = Receipt.ProductCostElement;
	
	SettlementBatch.CalculationIsCompleted 	  = Receipt.CalculationIsCompleted;
	
EndProcedure

#EndRegion

#Region ProceduresOfStep9_TransferOfLaborCosts

// Data Initialization

Function FieldsOfConsumptionAndLaborCosts(CalculationParameters)
	
	Return "ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection";
	
EndFunction

Function DescriptionOfLaborCostChains(CalculationParameters)
	
	DescriptionOfChains = New Map;
	
	// Issue <- Labor costs
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ProductionIssue, 				"Recorder, CorItemsLocationAttributes, CorInventoryOwnerAttribute, LotVendorAttributesCorr");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ProductionIssue,
		Enums.LotRecordTypes.LaborCosts, 		"Recorder, CorItemsLocationAttributes, CorInventoryOwnerAttribute, LotVendorAttributesCorr");	
	
	Return DescriptionOfChains;
	
EndFunction

Function DescriptionOfLaborCostRegisteredRecords(CalculationParameters)
	
	DistributionTableColumns = TableForDistributionOfLaborCosts(CalculationParameters).Columns;
	
	RegisterRecordsDetails = CostCalculationAppliedAlgorithms.RegisterRecordsDetails();
	RegisterRecordsDetails.Insert("Context", "TransferOfLaborCosts");
	RegisterRecordsDetails.Insert("RegisterName", Metadata.AccumulationRegisters.InventoryCost.Name);
	RegisterRecordsDetails.Insert("CalculationFields", CostCalculationAppliedAlgorithms.ListOfFields(DistributionTableColumns));
	RegisterRecordsDetails.Insert("ComparisonKeys",	FieldsOfConsumptionAndLaborCosts(CalculationParameters));
	RegisterRecordsDetails.Insert("Indicators", "Denominator, Count, Cost, CostExcludingVAT, AddExpensesForGoods, AdditionalExpensesExcludingVAT,
		|LocalCost, PermanentDifference, CostTD, CostOfPersonalIncomeTax,
		|OffBalanceCost, LaborCosts, ItemizedFixedCostsIncludingVAT, ItemizedFixedCostsExcludingVAT,
		|ItemizedVariableCostsIncludingVAT, ItemizedVariableCostsExcludingVAT,
		|CostMan, AddExpensesMan, LaborCostsMan, ItemizedFixedCostsManag, ItemizedVariableCostsManag,
		|OffBalanceCostLocal, AddExpensesLocal, LaborCostsLocal,
		|ItemizedFixedCostsCompl, ItemizedVariableCostsCompl");
	RegisterRecordsDetails.Insert("BasisOfArrival", "Count");
	RegisterRecordsDetails.Insert("BasisOfConsumption", "Count");
	RegisterRecordsDetails.Insert("ExpenseKey", "DocumentSource");
	RegisterRecordsDetails.Insert("OrderField_", "Period");
	RegisterRecordsDetails.Insert("SortFields", "Lot, VATActivityType, FinancialAccountingDimension"); 
	RegisterRecordsDetails.Insert("SortingByCondition", True);	
	
	Return RegisterRecordsDetails;
	
EndFunction

Function DescriptionOfNonWritableTypesCostOfLabor(CalculationParameters)
	
	UnrecordedRecordTypes = New Map;
	For Each CurItem In CalculationParameters.UnreadableRecordTypes Do
		UnrecordedRecordTypes.Insert(CurItem, True);
	EndDo;
	
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.LaborCosts, True);
	
	UnwrittenPartitions = New Map;
	UnwrittenPartitions.Insert(Enums.SectionsOfInventoryCostAccounting.EmptyRef(), True);
	
	Return CostCalculationAppliedAlgorithms.DescriptionOfNonWritableData(True, UnrecordedRecordTypes, UnwrittenPartitions);
	
EndFunction

Function TableForDistributionOfLaborCosts(CalculationParameters)
	
	Return CostCalculationAppliedAlgorithms.TableForDistributionOfLots(CalculationParameters,
		TextDescriptionOfDataForLaborCost());
	
EndFunction

// Sample data

Procedure GetDataForLaborCost(CalculationParameters)
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"ItemsLocationAttributes", // Separator
		"Denominator, Count,
			|Cost, CostExcludingVAT, OffBalanceCost, AddExpensesForGoods, AdditionalExpensesExcludingVAT, LaborCosts,
			|ItemizedFixedCostsIncludingVAT, ItemizedFixedCostsExcludingVAT,
			|ItemizedVariableCostsIncludingVAT, ItemizedVariableCostsExcludingVAT,
			|CostMan, AddExpensesMan, LaborCostsMan, ItemizedFixedCostsManag, ItemizedVariableCostsManag,
			|LocalCost, OffBalanceCostLocal, PermanentDifference, CostTD, CostOfPersonalIncomeTax,
			|AddExpensesLocal, LaborCostsLocal, ItemizedFixedCostsCompl, ItemizedVariableCostsCompl", // Resources
		"Products DESC, Priority ASC, Period, Organization, InventoryOwnerAttribute,
			|Lot, LotVendorAttributes, Recorder, RecordType DESC"); // Order
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForLaborCosts(CalculationParameters),
		NumberingParameters);
	
EndProcedure

// Request texts

// ... general

Function RequestTextForLaborCosts(CalculationParameters = Undefined) Export
	
	QueryText = ""
		+ CostCalculationFillingInformationAboutLots.TextCorrectedDocuments() + Common.QueryBatchSeparator() // CorrectedDocuments_
		+ TextDescriptionOfDataForLaborCost()
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurProductReleases()
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurCostsLaborCostsUnfinishedProduction()
		+ "";
	
	Return QueryText;
	
EndFunction

// ... data descriptions

Function TextDescriptionOfDataForLaborCost() Export
	QueryText = 
		"SELECT TOP 0 // 76 FIELDS
		|	CAST("""" AS STRING(80)) 					AS RequestSource,
		|	T.EntryType										AS EntryType,
		|	FALSE											AS ThisIsExactlyCalculatedMovement,
		|	FALSE											AS ReversingEntry,
		|	0 												AS Priority,
		|	0 												AS Denominator,
		|	FALSE 											AS CalculationIsCompleted,
		|	VALUE(Catalog.Products.EmptyRef)  AS Products,
		|	T.LotVendorAttributes.VATTaxation 		AS TaxationOfParty,
		|	T.Period										AS Period,
		|	T.Period										AS ReceiptPeriod,
		|	T.Recorder									AS Recorder,
		|	T.RecordType 									AS RecordType,
		|
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.Lot AS ProductionOrder,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|
		|	T.Count,
		|	T.Cost,
		|	T.CostExcludingVAT,
		|	T.OffBalanceCost,
		|	T.CostMan,
		|	T.AddExpensesMan,
		|	T.ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedVariableCostsExcludingVAT,
		|	T.LaborCostsMan,
		|	T.ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManag,
		|	T.AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.LaborCosts,
		|	T.ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVAT,
		|	T.LocalCost,
		|	T.OffBalanceCostLocal,
		|	T.PermanentDifference,
		|	T.CostTD,
		|	T.CostOfPersonalIncomeTax,
		|	T.AddExpensesLocal,
		|	T.LaborCostsLocal,
		|	T.ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsCompl,
		|
		|	T.BusinessOperation,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.Department,
		|	T.DimensionOfExpenses,
		|	T.ExpenseItemOfWriteOff,
		|	T.IncomeItem,
		|	T.DimensionOfRevenue,
		|	T.SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.DocumentRegisterRecords,
		|	T.RowID,
		|	T.ProductsGroup,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|	T.CorVATActivityTypes AS DocumentVATActivityType,
		|	T.VATManag,
		|	T.VATLocal,
		|	T.ProductCostElement,
		|	T.DocumentSource,
		|	T.CorLineOfBusiness,
		|	T.RowCode,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID
		|INTO Data
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|";

	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

Function TextCurProductReleases()
	Return 
		"SELECT
		|	""TextCurProductReleases"" 	      				AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.ProductionIssue) 		AS EntryType,
		|	FALSE													AS ThisIsExactlyCalculatedMovement,
		|	FALSE													AS ReversingEntry,
		|	99 										  				AS Priority,
		|	0 										  				AS Denominator,
		|	FALSE 													AS CalculationIsCompleted,
		|	VALUE(Catalog.Products.EmptyRef) 			AS Products,
		|	UNDEFINED                              				AS TaxationOfParty,
		|
		|	DD.Period,
		|	DD.Period AS ReceiptPeriod,
		|	ISNULL(CalculationLoggers.Ref, DD.Recorder) AS Recorder,
		|	UNDEFINED AS RecordType,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		|	UNDEFINED AS InventoryOwnerAttribute,
		|	DD.Organization,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	UNDEFINED AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	UNDEFINED AS VATActivityType,
		|
		|	DD.Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|
		|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
		|	DD.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	DD.AccountingSection AS CorAccountingSection,
		|	DD.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	UNDEFINED AS CorCompany,
		|	0 AS CorGrossInitialCostENT,
		|	AnalyticsGiver.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS ExpenseItemOfWriteOff,
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS SalePeriod,
		|	UNDEFINED AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	ISNULL(CalculationLoggers.Ref, DD.Recorder) AS DocumentRegisterRecords,
		|	"""" AS RowID,
		|	UNDEFINED AS ProductsGroup,
		|	DD.Lot AS CorLot,
		|	DD.LotVendorAttributes AS LotVendorAttributesCorr,
		|	DD.FinancialAccountingDimension AS CorControllingAttributes,
		|	DD.VATActivityType AS CorVATActivityTypes,
		|	DD.VATActivityType AS DocumentVATActivityType,
		|	0 AS VATManag,
		|	0 AS VATLocal,
		|	UNDEFINED AS ProductCostElement,
		|	UNDEFINED AS DocumentSource,
		|	DD.CorLineOfBusiness,
		|	UNDEFINED,
		|	DD.BusinessTransactionSetting,
		|	MAX(DD.FinRecordID)
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = DD.ItemsLocationAttributes
		|	LEFT JOIN TTAccountingAnalyticsForPartnersFromGiverReports AS AnalyticsGiver
		|		ON AnalyticsGiver.Recorder = DD.Recorder
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|	LEFT JOIN TTCostCalculationRecorders AS CalculationLoggers
		|		ON CalculationLoggers.Organization = DD.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|	ON CorrectedDocuments_.ReversedDocument = DD.Recorder
		|WHERE
		|	DD.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ProductsRelease),
		|		VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
		|		VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
		|	AND DD.OfficialTypeOfMovementParish
		|	AND NOT DD.ReversingEntry
		// We exclude documents for which an adjustment or reversal has been introduced in the current period
		|	AND CorrectedDocuments_.ReversedDocument IS NULL
		|	
		|GROUP BY
		|	DD.Period,
		|	ISNULL(CalculationLoggers.Ref, DD.Recorder),
		|	DD.Organization,
		|	DD.Count,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	AnalyticsGiver.AccountingDimensionByPartners,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.CorLineOfBusiness,
		|	DD.BusinessTransactionSetting,
		|	CASE
		|		WHEN CalculationLoggers.Ref IS NULL
		|		THEN DD.FinRecordID
		|		ELSE UNDEFINED
		|	END
		|";
EndFunction

Function TextCurCostsLaborCostsUnfinishedProduction()
	Return 
		"SELECT
		|	""TextCurCostsLaborCostsUnfinishedProduction""					AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.LaborCosts)	AS EntryType,
		|	FALSE													AS ThisIsExactlyCalculatedMovement,
		|	FALSE													AS ReversingEntry,
		|	45														AS Priority,
		|	0														AS Denominator,
		|	TRUE 													AS CalculationIsCompleted,
		|	UNDEFINED											AS Products,
		|	UNDEFINED											AS TaxationOfParty,
		|
		|	DD.Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.Recorder,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	UNDEFINED AS AccountingSection,
		|	UNDEFINED AS InventoryOwnerAttribute,
		|	DD.Organization,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	UNDEFINED AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	UNDEFINED AS VATActivityType,
		|
		|	MAX(DD.ProductsQuantity) AS Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	SUM(CASE
		|		WHEN &CompanyManagementAccounting THEN DD.Cost
		|		ELSE 0 END) AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	SUM(DD.Cost) AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	SUM(DD.PermanentDifference) AS PermanentDifference,
		|	SUM(DD.CostTD) AS CostTD,
		|	SUM(DD.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	SUM(DD.LocalCost) AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|
		|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
		|	DD.CorDimensionOfProductsAccounting AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorAccountingSection,
		|	DD.CorInventoryOwnerAttributesOfProducts AS CorInventoryOwnerAttribute,
		|	UNDEFINED AS CorCompany,
		|	0 AS CorGrossInitialCostENT,
		|	UNDEFINED AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	DD.Department,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS ExpenseItemOfWriteOff,
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS SalePeriod,
		|	UNDEFINED AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	DD.Recorder AS DocumentRegisterRecords,
		|	"""" AS RowID,
		|	DD.ProductsGroup,
		|	UNDEFINED AS CorLot,
		|	DD.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	UNDEFINED AS CorVATActivityTypes,
		|	UNDEFINED AS DocumentVATActivityType,
		|	0 AS VATManag,
		|	0 AS VATLocal,
		|	DD.ProductCostElement,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS CorLineOfBusiness,
		|	UNDEFINED,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID
		|FROM
		|	TTCashEstimatedTurnoverWorkInProgress AS DD
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = DD.CorDimensionOfProductsAccounting
		|WHERE
		|	NOT DD.OfficialTypeOfMovementParish
		|	AND NOT DD.ReversingEntry
		|	AND (VALUETYPE(DD.Recorder) IN (TYPE(Document.BackflushProduction)
		|		,TYPE(Document.ProductionStage2_2)
		|		,TYPE(Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
		|	
		|		,TYPE(Document.SubcontractorReport2_5)
		|		,TYPE(Document.CostCalculationRecorder)
		|		))
		|GROUP BY
		|	DD.Period,
		|	DD.Recorder,
		|	DD.Organization,
		|	DD.CorDimensionOfProductsAccounting,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttributesOfProducts,
		|	DD.Department,
		|	DD.ProductsGroup,
		|	DD.ProductCostElement,
		|	DD.LotVendorAttributesCorr,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID
		|";
EndFunction

// Filling out the payment batch

Procedure FillInEstimatedBatchLaborCost(CalculationParameters, SettlementBatch, Expense, Receipt)
	
	SummaryResources = New Structure(
	"Cost, CostExcludingVAT, AddExpensesForGoods, AdditionalExpensesExcludingVAT,
	|CostMan, AddExpensesMan, LaborCostsMan, ItemizedFixedCostsManag, ItemizedVariableCostsManag,
	|LocalCost, PermanentDifference, CostTD, CostOfPersonalIncomeTax,
	|OffBalanceCost, LaborCosts, ItemizedFixedCostsIncludingVAT, ItemizedFixedCostsExcludingVAT,
	|ItemizedVariableCostsIncludingVAT, ItemizedVariableCostsExcludingVAT,
	|VATLocal, VATManag,
	|OffBalanceCostLocal, AddExpensesLocal, LaborCostsLocal, ItemizedFixedCostsCompl, ItemizedVariableCostsCompl");
	
	FillPropertyValues(SettlementBatch, Expense);
	
	// Filling in the batch identification in the settlement batch
	FillPropertyValues(SettlementBatch, Receipt, "RecordType, VATActivityType, AccountingDimensionByPartners, Lot, LotVendorAttributes, 
		|TaxationOfParty, FinancialAccountingDimension, DocumentSource, BusinessTransactionSetting, FinRecordID");
	
	
	// Filling in the indicators of the settlement batch.
	SettlementBatch.Count = 0;	
	For Each ResourceName In SummaryResources Do
		
		SettlementBatch[ResourceName.Key] = Receipt[ResourceName.Key];
		
		// Adjustment of the calculation base in the parish.
		Receipt[ResourceName.Key] = Receipt[ResourceName.Key] - SettlementBatch[ResourceName.Key];
		
	EndDo;
	
	If Not ValueIsFilled(SettlementBatch.AccountingSection) Then
		SettlementBatch.AccountingSection = Receipt.AccountingSection;
	EndIf;
	
	If Not ValueIsFilled(SettlementBatch.InventoryOwnerAttribute) And ValueIsFilled(Receipt.InventoryOwnerAttribute) Then
		SettlementBatch.InventoryOwnerAttribute = Receipt.InventoryOwnerAttribute;
	EndIf;
	
	SettlementBatch.AccountingSection = Expense.CorAccountingSection;
	SettlementBatch.InventoryOwnerAttribute = Expense.CorInventoryOwnerAttribute;
	SettlementBatch.ItemsLocationAttributes = Expense.CorItemsLocationAttributes;
	SettlementBatch.Lot = Expense.CorLot;
	SettlementBatch.LotVendorAttributes = Expense.LotVendorAttributesCorr;
	SettlementBatch.FinancialAccountingDimension = Expense.CorControllingAttributes;
	SettlementBatch.VATActivityType = Expense.CorVATActivityTypes;
	SettlementBatch.CorInventoryOwnerAttribute = Undefined;
	SettlementBatch.CorItemsLocationAttributes = Undefined;
	SettlementBatch.CorControllingAttributes = Undefined;
	SettlementBatch.CorAccountingSection = Undefined;
	SettlementBatch.DocumentRegisterRecords = Receipt.DocumentRegisterRecords;
	SettlementBatch.ProductsGroup = Receipt.ProductsGroup;
	SettlementBatch.Department = Receipt.Department;
	SettlementBatch.ProductCostElement = Receipt.ProductCostElement;
	SettlementBatch.RowID = Receipt.RowID;
	SettlementBatch.RowCode = Receipt.RowCode;
	
	If SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.ProductStock 
	 And SettlementBatch.RecordType = AccumulationRecordType.Receipt
	 And CalculationParameters.AccountingPolicies.FIFOSliding.UsedInCurPeriod.Find(SettlementBatch.Organization) = Undefined Then
		
		SettlementBatch.Lot = Undefined;
		SettlementBatch.LotVendorAttributes = Undefined;
		
	EndIf;
	
	SettlementBatch.CalculationIsCompleted = Receipt.CalculationIsCompleted;
		
EndProcedure

#EndRegion

#Region StageProcedures_Contextual

// Used for all calls to fill in the billing batch.
//
Procedure FillInSettlementBatch(CalculationParameters, Context, SettlementBatch, Expense, Receipt, BatchIsFull) Export
	
	If Context = "DistributionOfLaborCosts" Then
		// Stage 1
		CalculationOfCostLocalization.FillInEstimatedBatchDistributionOfLaborCosts(CalculationParameters, SettlementBatch, Expense, Receipt);
		BatchIsFull = True;
	ElsIf Context = "DistributionOfLaborCostsForGraduation" Then
		// Stage 3
		FillInEstimatedBatchDistributionOfLaborCostsForRelease(CalculationParameters, SettlementBatch, Expense, Receipt);		
		BatchIsFull = True;
	ElsIf Context = "DistributionOfLaborCostsForProduction21" Then
		// Stage 3
		CalculationOfCostLocalization.FillInEstimatedBatchDistributionOfLaborCostsForRelease(CalculationParameters, SettlementBatch, Expense, Receipt);		
		BatchIsFull = True;
	ElsIf Context = "TransferOfLaborCosts" Then
		// Stage 9
		FillInEstimatedBatchLaborCost(CalculationParameters, SettlementBatch, Expense, Receipt);
		BatchIsFull = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Testing


// Completes the list of calculation stages.
// 
// Parameters:
// 	StageList - ValueList - 
//
Procedure SupplementStagesWithDistributionOfBatches(StageList) Export
	
	StageList.Add("DistributionOfLaborCosts");
	StageList.Add("DistributionOfLaborCostsForGraduation");
	StageList.Add("DistributionOfLaborCostsForProduction21");
	StageList.Add("TransferOfLaborCosts");
	
EndProcedure

Procedure RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText) Export
	
	If StageName_ = "DistributionOfLaborCostsForGraduation" Then
		QueryText = TextOfRequestForDistributionOfLaborCostsForIssue(CalculationParameters);
		
	ElsIf StageName_ = "TransferOfLaborCosts" Then
		QueryText = RequestTextForLaborCosts(CalculationParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
