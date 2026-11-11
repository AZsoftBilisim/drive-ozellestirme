
// Procedures and functions of common modules are called:
//	- Calculation of the cost of the individual rhythms.
//	- Calculation of the cost of production

#Region Public

// Gets data for building a decoding database for the distribution of materials and works.
//
// Parameters:
//		Period - Date - the calculation period
//		CompanyArray - CatalogRef.Companies - array of organizations;
//		Recorder - DocumentRef.ProductionCostAllocation - the distribution document that the decryption is being built for.
//
// Returns:
//		TempTablesManager - tables for building a report.
//
Function DataForDecipheringDistributionOfProductsForProduction(Period, CompanyArray, Recorder) Export
	
	CalculationParameters = CostCalculationProduction.InitializeDistributionDecryptionParameters(
		Period,
		CostCalculationAppliedAlgorithms.LinksOfOrganizationsUnderIntercampanyScheme(Period, CompanyArray),
		Recorder);
	
	DistributionOfProductsForProduction(CalculationParameters);
	
	Return CalculationParameters.TempTablesManager;
	
EndFunction

#Region CalculationStages

// Stage 4 (Context: "Distributionof nomenclatureproduction")
// PU 2.1: calculate the distribution of labor Materials (), the area of distribution of labor Materials.
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure DistributionOfProductsForProduction(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "DistributionOfProductsForProduction");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchDistribution(
		CalculationParameters,
		TableForDistributionOfProductsForProduction(CalculationParameters),
		DescriptionOfChainsOfDistributionOfProductsForProduction(CalculationParameters),
		DescriptionOfDistributionOfProductsForProduction(CalculationParameters),
		DescriptionOfUnrecordedDistributionOfProductsForProduction(CalculationParameters));
		
	// 2. Obtaining the initial data for the calculation
	// 	- generates a temporary Data table.
	GetDataForDistributionOfProductsForProduction(CalculationParameters);
	
	// 3. Getting chains from source data
	// 	- generates temporary tables of Sources and Receivers.
	CostCalculationAppliedAlgorithms.BuildChainsOfRegisteredRecords(CalculationParameters);
	
	// 4. Filling in batches in chains
	// 	- fills in the Calculation parameters table.Distribution of parties.Settlement parties.
	CostCalculationAppliedAlgorithms.CalculateBatchesByChains(CalculationParameters);
	
	// 5. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- adds entries to the temporary table for the production cost of the cost of goods.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure

// Stage 5 (Context: "Distribution of nomenclature issue")
// PU 2.1: calculate the Partyinzp (), the area of calculating the partyreferences.
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure DistributionOfProductsForRelease(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "DistributionOfProductsForRelease");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchDistribution(
		CalculationParameters,
		TableForDistributionOfProductsPerIssue(CalculationParameters),
		DescriptionOfDistributionChainsOfProductsForRelease(CalculationParameters),
		DescriptionOfProductDistributionRegisteredRecords(CalculationParameters),
		DescriptionOfUnrecordedProductDistributionsPerIssue(CalculationParameters));
	
	// 2. Obtaining the initial data for the calculation
	// 	- generates a temporary Data table.
	GetDataForProductDistributionPerIssue(CalculationParameters);
	
	// 3. Getting chains from source data
	// 	- generates temporary tables of Sources and Receivers.
	CostCalculationAppliedAlgorithms.BuildChainsOfRegisteredRecords(CalculationParameters);
	
	// 4. Filling in batches in chains
	// 	- fills in the Calculation parameters table.Distribution of parties.Settlement parties.
	CostCalculationAppliedAlgorithms.CalculateBatchesByChains(CalculationParameters);
	
	// 5. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- adds entries to the inventory cost register
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ProceduresOfStage4_DistributionOfProductsForProduction

// Data Initialization

Function ConsumptionFieldsOfProductDistributionForProduction(CalculationParameters)
	
	Return "Recorder, InventoryOwnerAttribute";
	
EndFunction

Function DescriptionOfChainsOfDistributionOfProductsForProduction(CalculationParameters)
	
	DescriptionOfChains = New Map;
	ConsumptionFields = ConsumptionFieldsOfProductDistributionForProduction(CalculationParameters);
	
	Lot                  = Enums.LotRecordTypes.Lot;
	ConsumptionLotCalculation         = Enums.LotRecordTypes.ConsumptionLotCalculation;
	TransferAuto         = Enums.LotRecordTypes.TransferAuto;
	
	// Consumption <- (Batch)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains, ConsumptionLotCalculation, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, ConsumptionLotCalculation, Lot, ConsumptionFields);
	
	// Moving <- (Consumption)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains, TransferAuto, "Recorder, InventoryOwnerAttribute, Lot");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, TransferAuto, ConsumptionLotCalculation, "Recorder, InventoryOwnerAttribute, CorLot");
	
	Return DescriptionOfChains;
	
EndFunction

Function DescriptionOfDistributionOfProductsForProduction(CalculationParameters)
	
	DistributionTableColumns = TableForDistributionOfProductsForProduction(CalculationParameters).Columns;
	
	RegisterRecordsDetails = CostCalculationAppliedAlgorithms.RegisterRecordsDetails();
	RegisterRecordsDetails.Insert("Context", "DistributionOfProductsForProduction");
	RegisterRecordsDetails.Insert("CalculationFields", CostCalculationAppliedAlgorithms.ListOfFields(DistributionTableColumns));
	RegisterRecordsDetails.Insert("ComparisonKeys",	ConsumptionFieldsOfProductDistributionForProduction(CalculationParameters));
	RegisterRecordsDetails.Insert("BasisOfArrival", "Denominator");
	RegisterRecordsDetails.Insert("BasisOfConsumption", "Denominator");
	RegisterRecordsDetails.Insert("OrderField_", "Period");
	
	RegisterRecordsDetails.Insert("TempTableName", "TTProductionCostsCostOfGoods");
	RegisterRecordsDetails.Insert(
		"TemporaryTablesForFollowingSteps",
		"ProductionBatchesByStages,
		|ProductionBatchesAreSummarized");
	
	Return RegisterRecordsDetails;
	
EndFunction

Function DescriptionOfUnrecordedDistributionOfProductsForProduction(CalculationParameters)
	
	UnrecordedRecordTypes = New Map;
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.Lot, True);
	
	Return CostCalculationAppliedAlgorithms.DescriptionOfNonWritableData(False, UnrecordedRecordTypes);
	
EndFunction

Function TableForDistributionOfProductsForProduction(CalculationParameters)
	
	Return CostCalculationAppliedAlgorithms.TableForDistributionOfLots(CalculationParameters,
		TextDescriptionOfDataForDistributionOfProductsForProduction());
	
EndFunction

// Sample data

Procedure GetDataForDistributionOfProductsForProduction(CalculationParameters)
	
	ToDecrypt = CostCalculationAppliedAlgorithms.CalculationCalledForDecryption(CalculationParameters);
	
	AddlParameters = CalculationParameters.AdditionalStageRequestParameters;
	AddlParameters.Insert("IncludeProductionData21", False);
	AddlParameters.Insert("CostCalculationPerformed",  False);
	AddlParameters.Insert("DecodingDistribution", 	  False);
	AddlParameters.Insert("ConsiderFutureReleases", 	  False);
	AddlParameters.Insert("MaterialSelectionHierarchy",    CostCalculationProduction.MaterialSelectionHierarchy(CalculationParameters));
	
	AddlParameters.Insert("Recorder",
		?(CalculationParameters.Property("Recorder"),CalculationParameters.Recorder, Undefined));
	ParametersForReceivingBatches = CostsServer.DescriptionOfParametersForReceivingActiveBatchesWithoutSpecifications();
	ParametersForReceivingBatches.BeginOfPeriod = CalculationParameters.PayrollPeriod.BeginOfPeriod;
	ParametersForReceivingBatches.PeriodEnding = CalculationParameters.PayrollPeriod.EndOfPeriod;
	ParametersForReceivingBatches.Companies = CalculationParameters.CompanyArray;
	
	CostsServer.FormActiveBatchesWithoutSpecifications(ParametersForReceivingBatches, CalculationParameters.TempTablesManager);
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"Organization", // Separator
		"Count, Denominator", // Resources
		"Period, Recorder, EntryType"); // Order
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForDistributionOfProductsForProduction(CalculationParameters),
		NumberingParameters,
		Not ToDecrypt);
	
EndProcedure

// Request texts

// ... general

Function RequestTextForDistributionOfProductsForProduction(CalculationParameters = Undefined) Export
	
	ToDecrypt = CostCalculationAppliedAlgorithms.CalculationCalledForDecryption(CalculationParameters);
	
	QueryText = ""
		// preparation of temporary tables
		+ CostCalculationFillingInformationAboutLots.TextCorrectedDocuments() + Common.QueryBatchSeparator() // CorrectedDocuments_
		+ CostCalculationProduction.ProductionBatchText() // TT products
		+ CostCalculationProduction.TextOfBatchOfTollProduction() // TT Partiidavalchesky production
		+ CostCalculationProduction.TextEmptyBatchTableOfGNZPMaterials()
		+ CostCalculationProduction.TextOfShareOfCostByProduct()		
		+ TextOfDistributionOfProductsForProductionInitialization() // TUE Registrars, Distribute
		+ TextDataOnMaterialCosts(ToDecrypt) // tue data for material costs
		+ CostCalculationProduction.TextOutputData() //tue dataproducts
		+ CostCalculationProduction.TextDataOnLaborCosts() //tue data for labor costs
		+ CostCalculationProduction.TextUnpackingSets("ManufacturedProduct") + Common.QueryBatchSeparator()// vt materials and servicespecifications
		+ TextDataOnMaterialStandards() //TT dataponormatives of material consumption
		+ TextOfAssignmentOfTollingMaterials() //TT assignationsavalchesky materials
		+ TextBaseOfDistributionOfProductsForProduction() // vt bazarasdistributiondetally, bazarasdistribution
		+ TextOfSumOfProductDistributionIndicatorsForProduction() // uses
		// the distribution database, in general totals of data sampling
		+ TextDescriptionOfDataForDistributionOfProductsForProduction()
		+ TMCommonUse.QuerySeparatorInJoin() + RequirementsForDistributionOfProductsForProduction() // uses to distribute, common sums
		+ TMCommonUse.QuerySeparatorInJoin() + TextCostOfProductionCosts() // Uses bazarasdistribution
		+ TMCommonUse.QuerySeparatorInJoin() + TextCostOfProductionReceipts() // Uses bazarasdistribution
		+ "";
		
	Return CostCalculationAppliedAlgorithms.InsertWeightAndVolumeTemplatesIntoQueryText(QueryText, "SN");
	
EndFunction

// ... data descriptions

Function TextDescriptionOfDataForDistributionOfProductsForProduction()
	
	QueryText = 
	"SELECT TOP 0
	|	CAST("""" AS STRING(80))       									AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.EmptyRef)                   AS EntryType,
	|	FALSE                                                                    AS CalculationIsCompleted,
	|	DD.RecordType                                                          AS RecordType,
	|	DD.Period                                                               AS Period,
	|	DD.Recorder                                                          AS Recorder,
	|	DD.ItemsLocationAttributes                                           AS ItemsLocationAttributes,
	|	DD.AccountingSection                                                          AS AccountingSection,
	|	DD.InventoryOwnerAttribute                                                           AS InventoryOwnerAttribute,
	|	DD.Organization                                                          AS Organization,
	|	DD.Lot                                                               AS Lot,
	|	DD.LotVendorAttributes                                                 AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension                                            AS FinancialAccountingDimension,
	|	DD.VATActivityType                                                   AS VATActivityType,
	|	0                                                                       AS Denominator,
	|	DD.Count                                                           AS Count,
	|	DD.Cost                                                            AS Cost,
	|	DD.LocalCost                                                        AS LocalCost,
	|	DD.CostExcludingVAT                                                      AS CostExcludingVAT,
	|	DD.CostMan                                                         AS CostMan,
	|	DD.OffBalanceCost                                                AS OffBalanceCost,
	|	DD.OffBalanceCostLocal                                            AS OffBalanceCostLocal,
	|	DD.PermanentDifference                                                    AS PermanentDifference,
	|	DD.BusinessOperation                                                AS BusinessOperation,
	|	DD.CorAccountingSection                                                       AS CorAccountingSection,
	|	DD.CorItemsLocationAttributes                                        AS CorItemsLocationAttributes,
	|	DD.CorInventoryOwnerAttribute                                                        AS CorInventoryOwnerAttribute,
	|	DD.CorLot                                                            AS CorLot,
	|	DD.CorVATActivityTypes                                                AS CorVATActivityTypes,
	|	DD.CorControllingAttributes                                         AS CorControllingAttributes,
	|	DD.AccountingDimensionByPartners                                            AS AccountingDimensionByPartners,
	|	DD.RowID                                                  AS RowID,
	
	|	DD.ExpenseItemOfWriteOff                                               AS ExpenseItemOfWriteOff,
	|	DD.DimensionOfExpenses                                                    AS DimensionOfExpenses,
	|	DD.AssetAndLiabilityItem                                                AS AssetAndLiabilityItem,
	|	DD.AssetsLiabilitiesDimension                                             AS AssetsLiabilitiesDimension,
	
	|	KK.Products                                                         AS Products,
	|	KK.Characteristic                                                       AS Characteristic,
	|	KK.Series                                                                AS Series,
	|	KK.StorageLocation														AS Warehouse,
	|	KK.Purpose                                                           AS Purpose,
	|	KK.ProductCostElement                                                    AS ProductCostElement,
	|	DD.BusinessTransactionSetting                                       AS BusinessTransactionSetting,
	|	DD.FinRecordID                                               AS FinRecordID,
	|	DD.CostDefiningMethod                                       AS CostDefiningMethod
	|
	|INTO Data
	|FROM
	|	AccumulationRegister.InventoryCost AS DD,
	|		Catalog.InventoryLocationAttributeKeys AS KK
	|";

	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

// ... formation of temporary tables

// Table: totracestring, Registrars, Distribute
Function TextOfDistributionOfProductsForProductionInitialization()
	
	QueryText = 
	"SELECT
	|	DD.Recorder AS Recorder,
	|	DD.Material AS Material
	|INTO TTSelectionBasedOnMaterials
	|FROM
	|	&MaterialSelectionHierarchy AS DD
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Ref AS Recorder
	|INTO Recorders
	|FROM
	|	Document.ProductionCostAllocation AS DD
	|	
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
	|	ON CorrectedDocuments_.ReversedDocument = DD.Ref
	|WHERE
	|	DD.Posted
	|	AND DD.Organization IN(&CompanyArray)
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.QuantityToAllocateAccordingToRule <> 0
	|	AND (&Recorder = DD.Ref OR &Recorder = UNDEFINED)
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|	AND CorrectedDocuments_.ReversedDocument IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Ref AS Recorder
	|FROM
	|	Document.RecyclableWasteAllocation AS DD
	|	
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
	|	ON CorrectedDocuments_.ReversedDocument = DD.Ref
	|
	|WHERE
	|	DD.Posted
	|	AND DD.Organization IN(&CompanyArray)
	|	AND DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.QuantityAccordingToRule <> 0
	|	AND (&Recorder = DD.Ref
	|		OR &Recorder = UNDEFINED)
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|	AND CorrectedDocuments_.ReversedDocument IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Recorders.Recorder,
	|	RegisterRecords.ItemsLocationAttributes,
	|	RegisterRecords.InventoryOwnerAttribute,
	|	RegisterRecords.FinRecordID,
	|	SUM(RegisterRecords.Cost) AS Cost,
	|	SUM(RegisterRecords.LocalCost) AS LocalCost,
	|	SUM(RegisterRecords.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(RegisterRecords.CostMan) AS CostMan,
	|	SUM(RegisterRecords.OffBalanceCost) AS OffBalanceCost,
	|	SUM(RegisterRecords.OffBalanceCostLocal) AS OffBalanceCostLocal,
	|	SUM(RegisterRecords.PermanentDifference) AS PermanentDifference
	|INTO TotalCostIN
	|FROM
	|	Recorders AS Recorders
	|		INNER JOIN Document.RecyclableWasteAllocation AS Attributes
	|		ON Recorders.Recorder = Attributes.Ref
	|
	|		INNER JOIN TTCashEstimatedTurnoverCostOfGoods AS RegisterRecords
	|		ON Recorders.Recorder = RegisterRecords.Recorder
	|			AND RegisterRecords.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			AND RegisterRecords.Count > 0
	|
	|		LEFT JOIN Document.RecyclableWasteAllocation.InventoryKinds AS TabularSection
	|		ON TabularSection.Ref = Attributes.Ref
	|			AND TabularSection.FinRecordID = RegisterRecords.FinRecordID
	|			AND TabularSection.ExpenseItem = UNDEFINED
	|			AND TabularSection.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
	|WHERE
	|	NOT TabularSection.Ref IS NULL
	// For works distributed according to the rule, the document ID is written in the RegisterRecords.
	|	OR Attributes.DocumentID = RegisterRecords.FinRecordID
	|
	|GROUP BY
	|	Recorders.Recorder,
	|	RegisterRecords.ItemsLocationAttributes,
	|	RegisterRecords.InventoryOwnerAttribute,
	|	RegisterRecords.FinRecordID
	|
	|UNION ALL
	|
	|SELECT
	|	Recorders.Recorder,
	|	RegisterRecords.ItemsLocationAttributes,
	|	RegisterRecords.InventoryOwnerAttribute,
	|	RegisterRecords.FinRecordID,
	|	SUM(RegisterRecords.Cost) AS Cost,
	|	SUM(RegisterRecords.LocalCost) AS LocalCost,
	|	SUM(RegisterRecords.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(RegisterRecords.CostMan) AS CostMan,
	|	SUM(RegisterRecords.OffBalanceCost) AS OffBalanceCost,
	|	SUM(RegisterRecords.OffBalanceCostLocal) AS OffBalanceCostLocal,
	|	0 AS PermanentDifference
	|FROM
	|	Recorders AS Recorders
	|		INNER JOIN Document.ProductionCostAllocation AS Attributes
	|		ON Recorders.Recorder = Attributes.Ref
	|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
	|		ON Attributes.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
	|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		INNER JOIN TTCashEstimatedTurnoverCostOfGoods AS RegisterRecords
	|		ON Recorders.Recorder = RegisterRecords.Recorder
	|			AND RegisterRecords.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots)
	|			AND RegisterRecords.Count > 0
	|
	|GROUP BY
	|	Recorders.Recorder,
	|	RegisterRecords.ItemsLocationAttributes,
	|	RegisterRecords.InventoryOwnerAttribute,
	|	RegisterRecords.FinRecordID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Ref                            AS Recorder,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN DD.ItemsLocationAttributes
	|		ELSE AnalyticsWithoutAssignment.DimensionKey
	|	END AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
	|	CommitteeKeys.DimensionKey         AS CommitteeAnalytics,
	|	AnalysisOfSettlementsWithCommittee.DimensionKey AS AccountingDimensionByPartners,
	|	DD.Products                      AS Products,
	|	DD.Characteristic                    AS Characteristic,
	|	DD.Series                             AS Series,
	|	DD.Purpose                        AS Purpose,
	|	DD.Organization                       AS Organization,
	|	DD.Department                     AS Department,
	|	DD.AllocatedAccordingToRule              AS AllocatedAccordingToRule,
	|	DD.AllocationBase                 AS AllocationBase,
	|	DD.ProductCostElement                 AS ProductCostElement,
	|	Inventories.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	Inventories.RecipientInventoryOwnerAttribute          AS RecipientInventoryOwnerAttribute,
	|	CatInventoryKinds.InventoryType            AS InventoryType,
	|	SUM(Inventories.Count)             AS Count,
	|	SUM(ISNULL(TotalCostIN.Cost, 0)) AS Cost,
	|	SUM(ISNULL(TotalCostIN.LocalCost, 0)) AS LocalCost,
	|	SUM(ISNULL(TotalCostIN.CostExcludingVAT, 0)) AS CostExcludingVAT,
	|	SUM(ISNULL(TotalCostIN.CostMan, 0)) AS CostMan,
	|	SUM(ISNULL(TotalCostIN.OffBalanceCost, 0)) AS OffBalanceCost,
	|	SUM(ISNULL(TotalCostIN.OffBalanceCostLocal, 0)) AS OffBalanceCostLocal,
	|	0 AS PermanentDifference,
	|	ISNULL(TTSelectionBasedOnMaterials.Material, UNDEFINED) AS Material,
	|	ISNULL(TTSelectionByTypeOfWork.WorkKind, UNDEFINED) AS WorkKind,
	|	ISNULL(TTSelectionByProductGroups.ProductsGroup, UNDEFINED) AS ProductsGroup,
	|	TTSelectionByProductGroups.ProductsGroup IS NULL AS ForAllProductGroups,
	|	Inventories.FinRecordID AS FinRecordID
	|INTO Allocate
	|FROM
	|	Document.ProductionCostAllocation AS DD
	|
	|	INNER JOIN Document.ProductionCostAllocation.InventoryKinds AS Inventories
	|		ON DD.Ref = Inventories.Ref
	|
	|	INNER JOIN
	|		Catalog.InventoryKinds AS CatInventoryKinds
	|	ON
	|		Inventories.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|	
	|	INNER JOIN Recorders AS Recorders
	|		ON Recorders.Recorder = DD.Ref
	|
	|	LEFT JOIN TotalCostIN AS TotalCostIN
	|	ON DD.Ref = TotalCostIN.Recorder
	|		AND Inventories.InventoryOwnerAttribute = TotalCostIN.InventoryOwnerAttribute
	|		AND Inventories.ItemsLocationAttributes = TotalCostIN.ItemsLocationAttributes
	|		AND Inventories.FinRecordID = TotalCostIN.FinRecordID
	|	
	|	LEFT JOIN TTSelectionBasedOnMaterials AS TTSelectionBasedOnMaterials
	|		ON TTSelectionBasedOnMaterials.Recorder = DD.Ref
	|	
	|	LEFT JOIN Document.ProductionCostAllocation.FilterByProductsGroups AS TTSelectionByProductGroups
	|		ON TTSelectionByProductGroups.Ref = DD.Ref
	|	
	|	LEFT JOIN Document.ProductionCostAllocation.FilterByActivityKind AS TTSelectionByTypeOfWork
	|		ON TTSelectionByTypeOfWork.Ref = DD.Ref
	|
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DD.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON
	|		Dimension.Products = AnalyticsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS CommitteeKeys
	|	ON
	|		DD.Products = CommitteeKeys.Products
	|		AND DD.Characteristic = CommitteeKeys.Characteristic
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeKeys.ProductCostElement
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeKeys.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeKeys.Series
	|		AND CatInventoryKinds.GoodsOwner = CommitteeKeys.StorageLocation
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfSettlementsWithCommittee
	|		ON DD.Organization = AnalysisOfSettlementsWithCommittee.Organization
	|		AND CatInventoryKinds.GoodsOwner = AnalysisOfSettlementsWithCommittee.Partner
	|		AND CatInventoryKinds.Counterparty = AnalysisOfSettlementsWithCommittee.Counterparty
	|		AND CatInventoryKinds.Contract = AnalysisOfSettlementsWithCommittee.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = AnalysisOfSettlementsWithCommittee.LineOfBusiness
	|	
	|WHERE
	|	Inventories.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots)
	|
	|GROUP BY
	|	DD.Ref,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN DD.ItemsLocationAttributes
	|		ELSE AnalyticsWithoutAssignment.DimensionKey
	|	END,
	|	AnalyticsWithoutAssignment.DimensionKey,
	|	CommitteeKeys.DimensionKey,
	|	AnalysisOfSettlementsWithCommittee.DimensionKey,
	|	DD.Products,
	|	DD.Characteristic,
	|	DD.Series,
	|	DD.Purpose,
	|	DD.Organization,
	|	DD.Department,
	|	DD.AllocatedAccordingToRule,
	|	DD.AllocationBase,
	|	DD.ProductCostElement,
	|	Inventories.InventoryOwnerAttribute,
	|	Inventories.RecipientInventoryOwnerAttribute,
	|	CatInventoryKinds.InventoryType,
	|	ISNULL(TTSelectionBasedOnMaterials.Material, UNDEFINED),
	|	ISNULL(TTSelectionByTypeOfWork.WorkKind, UNDEFINED),
	|	ISNULL(TTSelectionByProductGroups.ProductsGroup, UNDEFINED),
	|	TTSelectionByProductGroups.ProductsGroup IS NULL,
	|	Inventories.FinRecordID
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Ref                            AS Recorder,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN DD.ItemsLocationAttributes
	|		ELSE AnalyticsWithoutAssignment.DimensionKey
	|	END AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CommitteeAnalytics,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS AccountingDimensionByPartners,
	|	DD.Products                      AS Products,
	|	DD.Characteristic                    AS Characteristic,
	|	DD.Series                             AS Series,
	|	DD.Purpose                        AS Purpose,
	|	DD.Organization                       AS Organization,
	|	DD.Department                     AS Department,
	|	DD.AllocatedAccordingToRule              AS AllocatedAccordingToRule,
	|	DD.AllocationBase                 AS AllocationBase,
	|	DD.ProductCostElement                 AS ProductCostElement,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS RecipientInventoryOwnerAttribute,
	|	VALUE(Enum.InventoryTypes.EmptyRef) AS InventoryType,
	|	DD.QuantityToAllocateAccordingToRule AS Count,
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	0 AS CostExcludingVAT,
	|	0 AS CostMan,
	|	0 AS OffBalanceCost,
	|	0 AS OffBalanceCostLocal,
	|	0 AS PermanentDifference,
	|	ISNULL(TTSelectionBasedOnMaterials.Material, UNDEFINED) AS Material,
	|	ISNULL(TTSelectionByTypeOfWork.WorkKind, UNDEFINED) AS WorkKind,
	|	ISNULL(TTSelectionByProductGroups.ProductsGroup, UNDEFINED) AS ProductsGroup,
	|	TTSelectionByProductGroups.ProductsGroup IS NULL AS ForAllProductGroups,
	|	"""" AS FinRecordID
	|FROM
	|	Document.ProductionCostAllocation AS DD
	|
	|	INNER JOIN Recorders AS Recorders
	|		ON Recorders.Recorder = DD.Ref
	|	
	|	LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DD.Products
	|	
	|	LEFT JOIN TTSelectionBasedOnMaterials AS TTSelectionBasedOnMaterials
	|		ON TTSelectionBasedOnMaterials.Recorder = DD.Ref
	|	
	|	LEFT JOIN Document.ProductionCostAllocation.FilterByProductsGroups AS TTSelectionByProductGroups
	|		ON TTSelectionByProductGroups.Ref = DD.Ref
	|	
	|	LEFT JOIN Document.ProductionCostAllocation.FilterByActivityKind AS TTSelectionByTypeOfWork
	|		ON TTSelectionByTypeOfWork.Ref = DD.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON
	|		DD.Products = AnalyticsWithoutAssignment.Products
	|		AND DD.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND DD.Series = AnalyticsWithoutAssignment.Series
	|		AND DD.Department = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|WHERE
	|	CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT DD.Products.TracedGoods
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Ref AS Recorder,
	|	TotalCostIN.ItemsLocationAttributes,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef),
	|	TotalCostIN.ItemsLocationAttributes,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef),
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef),
	|	DD.Products,
	|	DD.Characteristic,
	|	DD.Series,
	|	DD.Purpose,
	|	DD.Organization,
	|	DD.Department,
	|	DD.AllocatedAccordingToRule,
	|	DD.AllocationBase,
	|	DD.ProductCostElement,
	|	TotalCostIN.InventoryOwnerAttribute,
	|	TotalCostIN.InventoryOwnerAttribute,
	|	ISNULL(InventoryTypeDetails.InventoryType, 
	|		VALUE(Enum.InventoryTypes.EmptyRef)),
	|	-DD.QuantityAccordingToRule				AS Count,
	|	-TotalCostIN.Cost			AS Cost,
	|	-TotalCostIN.LocalCost		AS LocalCost,
	|	-TotalCostIN.CostExcludingVAT	AS CostExcludingVAT,
	|	-TotalCostIN.CostMan		AS CostMan,
	|	-TotalCostIN.OffBalanceCost		AS OffBalanceCost,
	|	-TotalCostIN.OffBalanceCostLocal	AS OffBalanceCostLocal,
	|	-TotalCostIN.PermanentDifference AS PermanentDifference,
	|	ISNULL(TTSelectionBasedOnMaterials.Material, UNDEFINED) AS Material,
	|	ISNULL(TTSelectionByTypeOfWork.WorkKind, UNDEFINED) AS WorkKind,
	|	ISNULL(TTSelectionByProductGroups.ProductsGroup, UNDEFINED) AS ProductsGroup,
	|	TTSelectionByProductGroups.ProductsGroup IS NULL AS ForAllProductGroups,
	|	TotalCostIN.FinRecordID
	|FROM
	|	Document.RecyclableWasteAllocation AS DD
	|		INNER JOIN Recorders AS Recorders
	|		ON Recorders.Recorder = DD.Ref
	|
	|		INNER JOIN TotalCostIN AS TotalCostIN
	|		ON DD.Ref = TotalCostIN.Recorder
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryTypeDetails
	|		ON DD.Ref = InventoryTypeDetails.Ref
	|		
	|		LEFT JOIN TTSelectionBasedOnMaterials AS TTSelectionBasedOnMaterials
	|		ON TTSelectionBasedOnMaterials.Recorder = DD.Ref
	|	
	|		LEFT JOIN Document.RecyclableWasteAllocation.FilterByProductsGroups AS TTSelectionByProductGroups
	|		ON TTSelectionByProductGroups.Ref = DD.Ref
	|	
	|		LEFT JOIN Document.RecyclableWasteAllocation.FilterByActivityKind AS TTSelectionByTypeOfWork
	|		ON TTSelectionByTypeOfWork.Ref = DD.Ref
	|;
	|";
	
	Return QueryText
	
EndFunction

// Tables: Data On Material Costs
Function TextDataOnMaterialCosts(ToDecrypt)
	
	// To decipher the report, the initial data are the documents of stage production
	// and movement at cost for production without orders.
	// For the closing of the month, the data are the results of the calculation of the previous stages.
	If ToDecrypt Then
		
		Return "
		|SELECT
		|	DD.Organization,
		|	DD.Department,
		|	DD.Material,
		|	DD.Purpose,
		|	DD.ProductsGroup,
		|	DD.ProductionLot,
		|	DD.VATActivityType,
		|	DD.LineOfBusiness,
		|	SUM(ISNULL(Prices.Price, 0) * DD.Count) AS Cost,
		|	SUM(DD.Count) AS Count,
		|	SUM(DD.VolumeM3) AS VolumeM3,
		|	SUM(DD.Weight) AS Weight
		|INTO DataOnMaterialCosts
		|FROM
		// Production without an order
		|	(SELECT
		|		DD.Organization								AS Organization,
		|		Dimension.StorageLocation						AS Department,
		|		Dimension.Products						AS Material,
		|		Dimension.Characteristic					AS Characteristic,
		|		ProductionBatchesAreSummarized.Purpose			AS Purpose,
		|		DD.FinancialAccountingDimension				AS ProductsGroup,
		|		DD.Lot									AS ProductionLot,
		|		ProductionBatchesAreSummarized.VATActivityType	AS VATActivityType,
		|		ProductionBatchesAreSummarized.LineOfBusiness AS LineOfBusiness,
		|		SUM(DD.Count)						AS Count,
		|		SUM(&VolumeM3 * DD.Count)				AS VolumeM3,
		|		SUM(&Weight * DD.Count)					AS Weight
		|	FROM
		|		AccumulationRegister.InventoryCost AS DD
		|
		|			INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|			ON Dimension.Ref = DD.ItemsLocationAttributes
		|
		|			INNER JOIN ProductionBatchesAreSummarized AS ProductionBatchesAreSummarized
		|			ON ProductionBatchesAreSummarized.ProductionLot = DD.Lot
		|			AND ProductionBatchesAreSummarized.Organization = DD.Organization
		|
		|			LEFT JOIN Catalog.Products AS SN
		|			ON SN.Ref = Dimension.Products
		|
		|	WHERE
		|		DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND DD.Organization IN(&CompanyArray)
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND DD.Count > 0
		|		AND DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
		|										VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots),
		|										VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
		|		AND VALUETYPE(ProductionBatchesAreSummarized.DocumentLots) = TYPE(Document.BackflushProduction)
		|		AND ProductionBatchesAreSummarized.CostAllocationForIssue
		// We will exclude from the database the movement of distribution documents, because at the time of cost calculation they are not yet available
		|		AND VALUETYPE(DD.Recorder) <> TYPE(Document.ProductionCostAllocation)
		|	
		|	GROUP BY
		|		DD.Organization,
		|		Dimension.StorageLocation,
		|		Dimension.Products,
		|		Dimension.Characteristic,
		|		ProductionBatchesAreSummarized.Purpose,
		|		DD.FinancialAccountingDimension,
		|		DD.Lot,
		|		ProductionBatchesAreSummarized.VATActivityType,
		|		ProductionBatchesAreSummarized.LineOfBusiness
		|	
		|	UNION ALL
		|	
		// Stages
		|	SELECT
		|		ProductionLots.Organization AS Organization,
		|		Dimension.StorageLocation AS Department,
		|		Dimension.Products AS Material,
		|		Dimension.Characteristic AS Characteristic,
		|		ProductionLots.Purpose AS Purpose,
		|		ProductionLots.FinancialAccountingDimension AS ProductsGroup,
		|		ProductionLots.ProductionLot AS ProductionLot,
		|		ProductionLots.VATActivityType AS VATActivityType,
		|		ProductionLots.LineOfBusiness AS LineOfBusiness,
		|		SUM(DD.Count) AS Count,
		|		SUM(&VolumeM3 * DD.Count) AS VolumeM3,
		|		SUM(&Weight * DD.Count) AS Weight
		|	FROM
		|		Document.ProductionStage2_2.MaterialsAndWorksConsumption AS DD
		|
		|			INNER JOIN ProductionBatchesByStages AS ProductionLots
		|			ON ProductionLots.Stage = DD.Ref
		|
		|			INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|			ON Dimension.Ref = DD.ItemsLocationAttributes
		|
		|			LEFT JOIN Catalog.Products AS SN
		|			ON SN.Ref = Dimension.Products
		|
		|	WHERE
		|		NOT DD.Ref.ProductionByThirdParty
		|		AND ProductionLots.CostAllocationForIssue
		|	
		|	GROUP BY
		|		ProductionLots.Organization,
		|		Dimension.StorageLocation,
		|		Dimension.Products,
		|		Dimension.Characteristic,
		|		ProductionLots.Purpose,
		|		ProductionLots.FinancialAccountingDimension,
		|		ProductionLots.ProductionLot,
		|		ProductionLots.VATActivityType,
		|		ProductionLots.LineOfBusiness
		|	) AS DD
		|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(&EndOfPeriod) AS Prices
		|		ON (DD.Material = Prices.Products)
		|		AND (DD.Characteristic = Prices.Characteristic)
		|		AND (&PriceKindOfPlannedCostOfMaterialsAndWorks = Prices.PriceKind)
		|
		|GROUP BY
		|	DD.Organization,
		|	DD.Department,
		|	DD.LineOfBusiness,
		|	DD.Material,
		|	DD.Purpose,
		|	DD.ProductsGroup,
		|	DD.VATActivityType,
		|	DD.ProductionLot
		|;
		|";
		
	Else
		
		Return "
		|SELECT
		|	DD.Organization,
		|	Dimension.StorageLocation AS Department,
		|	Dimension.Products AS Material,
		|	ProductionBatchesAreSummarized.Purpose AS Purpose,
		|	DD.CorControllingAttributes AS ProductsGroup,
		|	DD.CorLot AS ProductionLot,
		|	ProductionBatchesAreSummarized.VATActivityType AS VATActivityType,
		|	SUM(DD.Cost) AS Cost,
		|	SUM(DD.Count) AS Count,
		|	SUM(&VolumeM3 * DD.Count) AS VolumeM3,
		|	SUM(&Weight * DD.Count) AS Weight
		|INTO DataOnMaterialCosts
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON (Dimension.Ref = DD.CorItemsLocationAttributes)
		|		
		|		INNER JOIN ProductionBatchesAreSummarized AS ProductionBatchesAreSummarized
		|		ON ProductionBatchesAreSummarized.ProductionLot = DD.CorLot
		|		AND ProductionBatchesAreSummarized.Organization = DD.Organization
		|		
		|		LEFT JOIN Catalog.Products AS SN
		|		ON SN.Ref = Dimension.Products
		|
		|WHERE
		|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DD.Organization IN(&CompanyArray)
		|	AND NOT DD.OfficialTypeOfMovementParish
		|	AND DD.Count <> 0
		|	AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|	AND NOT DD.AccountingSection IN(
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners))
		|	AND VALUETYPE(ProductionBatchesAreSummarized.DocumentLots) IN(
		|			TYPE(Document.ProductionOrder2_2),
		|			TYPE(Document.BackflushProduction))
		|	AND ProductionBatchesAreSummarized.CostAllocationForIssue
		|	
		|GROUP BY
		|	DD.Organization,
		|	Dimension.StorageLocation,
		|	Dimension.Products,
		|	ProductionBatchesAreSummarized.Purpose,
		|	DD.CorControllingAttributes,
		|	ProductionBatchesAreSummarized.VATActivityType,
		|	DD.CorLot
		|;
		|";
	EndIf;
	
EndFunction

// Tables: tcoefficents, dataonormativamaterial Costs
Function TextDataOnMaterialStandards()
	
	QueryText = "
	|SELECT
	|	DD.ProductionLot AS ProductionLot,
	|	SUM(CASE WHEN (RS_.NumberOfPackages * ISNULL(&QueryTextPackagingFactor1, 1)) = 0
	|		THEN 0
	|	ELSE
	|		DD.ProductsQuantity/(RS_.NumberOfPackages * ISNULL(&QueryTextPackagingFactor1, 1))
	|	END) AS ZoomRatio
	|INTO TTCoefficients
	|FROM
	|	ManufacturedProduct AS DD
	|	INNER JOIN Catalog.BillsOfMaterials.ManufacturedProducts AS RS_
	|		ON DD.BillOfMaterials = RS_.Ref
	|		AND CASE
	|			WHEN RS_.Products = VALUE(Catalog.Products.EmptyRef)
	|				THEN TRUE
	|			ELSE
	|				DD.Products = RS_.Products
	|		END
	|
	|WHERE
	|	RS_.LineNumber = 1
	|	AND DD.ShareOfMonthName > 0
	|GROUP BY
	|	DD.ProductionLot
	|;
	|
	|SELECT DISTINCT
	|	DD.Organization                   AS Organization,
	|	RS_.Stage.Department            AS Department,
	|	RS_.Products                  AS Material,
	|	DD.FinancialAccountingDimension     AS ProductsGroup,
	|	CatProductionLots.Purpose AS Purpose,
	|	DD.ProductionLot            AS ProductionLot,
	|	DD.VATActivityType            AS VATActivityType,
	|	CAST(RS_.Count * CF.ZoomRatio AS NUMBER(15,3))   AS Count
	|INTO DataOnMaterialConsumptionStandards
	|FROM
	|	ManufacturedProduct AS DD
	|	INNER JOIN TTCoefficients AS CF
	|		ON DD.ProductionLot = CF.ProductionLot
	|	INNER JOIN MaterialsAndServicesSpecifications AS RS_
	|		ON DD.BillOfMaterials = RS_.Ref
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DD.Organization                   AS Organization,
	|	RS_.Stage.Department            AS Department,
	|	RS_.Products                  AS Material,
	|	DD.FinancialAccountingDimension     AS ProductsGroup,
	|	CatProductionLots.Purpose AS Purpose,
	|	DD.ProductionLot            AS ProductionLot,
	|	DD.VATActivityType            AS VATActivityType,
	|	CAST(RS_.NumberOfPackages * ISNULL(&QueryTextPackagingFactor2, 1) * CF.ZoomRatio AS NUMBER(15,3)) AS Count
	|FROM
	|	ManufacturedProduct AS DD
	|	INNER JOIN TTCoefficients AS CF
	|		ON DD.ProductionLot = CF.ProductionLot
	|	INNER JOIN Catalog.BillsOfMaterials.RecyclableWaste AS RS_
	|		ON DD.BillOfMaterials = RS_.Ref
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = DD.ProductionLot
	|;
	|";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"RS_.Package",
			"DD.Products"));
			
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"RS_.Package",
			"RS_.Products"));
			
	Return QueryText;
	
EndFunction

// Tables: Assignments of commercial materials
Function TextOfAssignmentOfTollingMaterials()
	
	Return "
	|SELECT
	|	AssignmentsOfMaterials.Ref AS PurposeOfMaterial,
	|	AssignmentsOfMaterials.Partner AS Partner,
	|	AssignmentsOfMaterials.Contract AS Contract
	|INTO AssignmentsOfTollingMaterials
	|FROM
	|	Catalog.Assignments AS AssignmentsOfMaterials
	|WHERE
	|	AssignmentsOfMaterials.AssignmentType IN (
	|		VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|	AND TRUE IN 
	|		(SELECT TOP 1 TRUE FROM Allocate AS DD WHERE DD.Purpose = AssignmentsOfMaterials.Ref)
	|INDEX BY 
	|	PurposeOfMaterial
	|;
	|";
	
EndFunction

// Table: Lazarusdrealamant, Lazaraspaste
Function TextBaseOfDistributionOfProductsForProduction()
	
	Return "
	// according to the specified materials
	|SELECT
	|	DD.Recorder              AS Recorder,
	|	DD.Organization              AS Organization,
	|	DD.InventoryOwnerAttribute               AS InventoryOwnerAttribute,
	|	DD.InventoryType               AS InventoryType,
	|	DD.AllocationBase        AS AllocationBase,
	|	Data.Department        AS Department,
	|	Data.ProductionLot   AS ProductionLot,
	|	Data.VATActivityType   AS VATActivityType,
	|	Data.ProductsGroup      AS FinancialAccountingDimension,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT DD.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN DD.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END                       AS CorControllingAttributes,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.CorItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END                       AS CorItemsLocationAttributes,
	|	Data.Purpose           AS Purpose,
	|	Data.Material             AS Material,
	|	UNDEFINED                AS ManufacturedProduct,
	|	Data.ProductsGroup      AS ProductsGroup,
	|	UNDEFINED                AS WorkKind,
	|	SUM(CASE DD.AllocationBase
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials) THEN Data.Count
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials) THEN Data.VolumeM3
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials) THEN Data.Weight
	|	END)                      AS Denominator,
	|	""Material""                AS IndicatorKind
	|INTO DistributionBaseDetails
	|FROM
	|	Allocate AS DD
	|
	|	INNER JOIN DataOnMaterialCosts AS Data
	|		ON Data.Organization = DD.Organization
	|		AND Data.Department = DD.Department
	|		AND Data.Material = DD.Material
	|		AND (Data.ProductsGroup = DD.ProductsGroup OR DD.ForAllProductGroups)
	|	
	|	LEFT JOIN PartiesOfTollProduction AS PartiesOfGivers
	|	ON Data.ProductionLot = PartiesOfGivers.ProductionLot
	|
	|WHERE
	|	(DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials)
	|	OR DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials)
	|	OR DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials))
	|	AND ((Data.Purpose = DD.Purpose
	|		OR CAST(Data.Purpose AS Catalog.Assignments).LineOfBusiness = DD.Purpose.LineOfBusiness)
	|			AND PartiesOfGivers.ProductionLot IS NULL
	|		OR DD.Purpose = VALUE(Catalog.Assignments.EmptyRef))
	|
	|GROUP BY
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.InventoryOwnerAttribute,
	|	DD.InventoryType,
	|	DD.AllocationBase,
	|	Data.Department,
	|	Data.ProductionLot,
	|	Data.VATActivityType,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT DD.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN DD.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.CorItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END,
	|	Data.Purpose,
	|	Data.Material,
	|	Data.ProductsGroup
	|
	// by products, by products, taking into account the purposes of the tolling scheme
	|UNION ALL
	|
	|SELECT
	|	DD.Recorder                   AS Recorder,
	|	DD.Organization                   AS Organization,
	|	DD.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	DD.InventoryType                    AS InventoryType,
	|	DD.AllocationBase             AS AllocationBase,
	|	Data.Department             AS Department,
	|	Data.ProductionLot        AS ProductionLot,
	|	Data.VATActivityType        AS VATActivityType,
	|	Data.ProductsGroup           AS FinancialAccountingDimension,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT DD.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN DD.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END                            AS CorControllingAttributes,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.CorItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END                            AS CorItemsLocationAttributes,
	|	Data.Purpose                AS Purpose,
	|	UNDEFINED                     AS Material,
	|	Data.ManufacturedProduct                 AS ManufacturedProduct,
	|	Data.ProductsGroup           AS ProductsGroup,
	|	UNDEFINED                     AS WorkKind,
	|	SUM(CASE DD.AllocationBase
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantity) THEN Data.Count
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolume) THEN Data.VolumeM3
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeight) THEN Data.Weight
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCost) THEN Data.Cost
	|	END)                           AS Denominator,
	|	""ManufacturedProduct""                    AS IndicatorKind
	|FROM
	|	Allocate AS DD
	|
	|	INNER JOIN ProductData_6 AS Data
	|		ON Data.Organization = DD.Organization
	|		AND Data.Department = DD.Department
	|		AND (Data.ProductsGroup = DD.ProductsGroup OR DD.ForAllProductGroups)
	|
	|	LEFT JOIN Catalog.Assignments AS ProductAssignments_
	|		ON Data.Purpose = ProductAssignments_.Ref
	|
	|
	|	LEFT JOIN AssignmentsOfTollingMaterials AS AssignmentsOfMaterials
	|		ON (AssignmentsOfMaterials.PurposeOfMaterial = DD.Purpose
	|			OR AssignmentsOfMaterials.Partner = DD.Purpose.Partner
	|				AND AssignmentsOfMaterials.Contract = DD.Purpose.Contract)
	|	LEFT JOIN PartiesOfTollProduction AS PartiesOfGivers
	|		ON AssignmentsOfMaterials.Partner = PartiesOfGivers.Partner
	|			AND AssignmentsOfMaterials.Contract = PartiesOfGivers.Contract		
	|WHERE
	|	(DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantity)
	|		OR DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolume)
	|		OR DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeight)
	|		OR DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCost)
	|	)
	|	AND (
	|		Data.ProductionLot = PartiesOfGivers.ProductionLot
	|		OR
	|		(
	|			(Data.Purpose = DD.Purpose
	|				OR Data.LineOfBusiness = ISNULL(DD.Purpose.LineOfBusiness, UNDEFINED)
	|				OR ProductAssignments_.LineOfBusiness = ISNULL(DD.Purpose.LineOfBusiness, UNDEFINED)
	|				OR DD.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			)
	|			AND VALUETYPE(Data.ProductionLot.Document) IN (
	|													TYPE(Document.ProductionOrder2_2),
	|													TYPE(Document.BackflushProduction)
	|													)
	|		)
	|	)
	// If the giving materials do not have an appointment, then the conditions above work according to the appointments
	|	AND (AssignmentsOfMaterials.PurposeOfMaterial IS NULL
	|		OR DD.InventoryType <> VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
			// If the giving materials have a purpose, then it must coincide with the purpose of the product data, in terms of the partner and the contract 
	|		OR AssignmentsOfMaterials.Partner 		= ProductAssignments_.Partner
	|				AND AssignmentsOfMaterials.Contract 	= ProductAssignments_.Contract)
	|
	|GROUP BY
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.InventoryOwnerAttribute,
	|	DD.InventoryType,
	|	DD.AllocationBase,
	|	Data.Department,
	|	Data.ProductionLot,
	|	Data.VATActivityType,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT DD.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN DD.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.CorItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END,
	|	Data.Purpose,
	|	Data.ManufacturedProduct,
	|	Data.ProductsGroup
	|
	// according to the specified labor costs
	|UNION ALL
	|
	|SELECT
	|	DD.Recorder             AS Recorder,
	|	DD.Organization             AS Organization,
	|	DD.InventoryOwnerAttribute              AS InventoryOwnerAttribute,
	|	DD.InventoryType              AS InventoryType,
	|	DD.AllocationBase       AS AllocationBase,
	|	Data.Department       AS Department,
	|	Data.ProductionLot  AS ProductionLot,
	|	Data.VATActivityType  AS VATActivityType,
	|	Data.ProductsGroup     AS FinancialAccountingDimension,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT DD.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN DD.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END                      AS CorControllingAttributes,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.CorItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END                      AS CorItemsLocationAttributes,
	|	Data.Purpose          AS Purpose,
	|	UNDEFINED               AS Material,
	|	UNDEFINED               AS ManufacturedProduct,
	|	Data.ProductsGroup     AS ProductsGroup,
	|	Data.WorkKind            AS WorkKind,
	|	SUM(CASE DD.AllocationBase
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds) THEN Data.Count
	|	END)                     AS Denominator,
	|	""WorkKind""               AS IndicatorKind
	|FROM
	|	Allocate AS DD
	|
	|	INNER JOIN DataOnLaborCosts AS Data
	|		ON Data.Organization = DD.Organization
	|		AND Data.Department = DD.Department
	|		AND Data.WorkKind = DD.WorkKind
	|		AND (Data.ProductsGroup = DD.ProductsGroup OR DD.ForAllProductGroups)
	|		AND (Data.Purpose = DD.Purpose
	|			OR Data.LineOfBusiness = ISNULL(DD.Purpose.LineOfBusiness, UNDEFINED)
	|			OR CAST(Data.Purpose AS Catalog.Assignments).LineOfBusiness = DD.Purpose.LineOfBusiness
	|			OR DD.Purpose = VALUE(Catalog.Assignments.EmptyRef))
	|
	|WHERE
	|	DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds)
	|
	|GROUP BY
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.InventoryOwnerAttribute,
	|	DD.InventoryType,
	|	DD.AllocationBase,
	|	Data.Department,
	|	Data.ProductionLot,
	|	Data.VATActivityType,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT DD.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN DD.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.CorItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END,
	|	Data.Purpose,
	|	Data.WorkKind,
	|	Data.ProductsGroup
	|
	// according to the standards
	|UNION ALL
	|
	|SELECT
	|	DD.Recorder             AS Recorder,
	|	DD.Organization             AS Organization,
	|	DD.InventoryOwnerAttribute              AS InventoryOwnerAttribute,
	|	DD.InventoryType              AS InventoryType,
	|	DD.AllocationBase       AS AllocationBase,
	|	Data.Department       AS Department,
	|	Data.ProductionLot  AS ProductionLot,
	|	Data.VATActivityType  AS VATActivityType,
	|	Data.ProductsGroup     AS FinancialAccountingDimension,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT DD.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN DD.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END                      AS CorControllingAttributes,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.CorItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END                      AS CorItemsLocationAttributes,
	|	Data.Purpose          AS Purpose,
	|	Data.Material            AS Material,
	|	UNDEFINED               AS ManufacturedProduct,
	|	Data.ProductsGroup     AS ProductsGroup,
	|	UNDEFINED               AS WorkKind,
	|	SUM(CASE DD.AllocationBase
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.StandardMaterialConsumption) THEN Data.Count
	|	END)                     AS Denominator,
	|	""Material""               AS IndicatorKind
	|FROM
	|	Allocate AS DD
	|
	|	INNER JOIN DataOnMaterialConsumptionStandards AS Data
	|		ON Data.Organization = DD.Organization
	|		AND Data.Department = DD.Department
	|		AND Data.Material = DD.Products
	|		AND (Data.ProductsGroup = DD.ProductsGroup OR DD.ForAllProductGroups)
	|	
	|	LEFT JOIN PartiesOfTollProduction AS PartiesOfGivers
	|	ON Data.ProductionLot = PartiesOfGivers.ProductionLot
	|
	|WHERE
	|	DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.StandardMaterialConsumption)
	|	AND VALUETYPE(Data.ProductionLot.Document) IN (
	|														TYPE(Document.ProductionOrder2_2),
	|														TYPE(Document.BackflushProduction)
	|														)
	|	AND ((Data.Purpose = DD.Purpose
	|		OR CAST(Data.Purpose AS Catalog.Assignments).LineOfBusiness = DD.Purpose.LineOfBusiness)
	|			AND PartiesOfGivers.ProductionLot IS NULL
	|		OR DD.Purpose = VALUE(Catalog.Assignments.EmptyRef))
	|
	|GROUP BY
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.InventoryOwnerAttribute,
	|	DD.InventoryType,
	|	DD.AllocationBase,
	|	Data.Department,
	|	Data.ProductionLot,
	|	Data.VATActivityType,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT DD.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN DD.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.CorItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END,
	|	Data.Purpose,
	|	Data.Material,
	|	Data.ProductsGroup
	|
	// according to the specified materials, taking into account the purposes of the tolling scheme
	|UNION ALL
	|
	|SELECT
	|	DD.Recorder              AS Recorder,
	|	DD.Organization              AS Organization,
	|	DD.InventoryOwnerAttribute               AS InventoryOwnerAttribute,
	|	DD.InventoryType               AS InventoryType,
	|	DD.AllocationBase        AS AllocationBase,
	|	Data.Department        AS Department,
	|	Data.ProductionLot   AS ProductionLot,
	|	Data.VATActivityType   AS VATActivityType,
	|	Data.ProductsGroup      AS FinancialAccountingDimension,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT DD.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN DD.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END                       AS CorControllingAttributes,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.CorItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END                       AS CorItemsLocationAttributes,
	|	Data.Purpose           AS Purpose,
	|	Data.Material             AS Material,
	|	UNDEFINED                AS ManufacturedProduct,
	|	Data.ProductsGroup      AS ProductsGroup,
	|	UNDEFINED                AS WorkKind,
	|	SUM(CASE DD.AllocationBase
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials) THEN Data.Count
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials) THEN Data.VolumeM3
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials) THEN Data.Weight
	|	END)                      AS Denominator,
	|	""Material""                AS IndicatorKind
	|FROM
	|	Allocate AS DD
	|
	|	INNER JOIN AssignmentsOfTollingMaterials AS AssignmentsOfMaterials
	|		ON (AssignmentsOfMaterials.PurposeOfMaterial = DD.Purpose
	|			OR AssignmentsOfMaterials.Partner = DD.Purpose.Partner
	|				AND AssignmentsOfMaterials.Contract = DD.Purpose.Contract)
	|	INNER JOIN PartiesOfTollProduction AS PartiesOfGivers
	|		ON AssignmentsOfMaterials.Partner = PartiesOfGivers.Partner
	|		AND AssignmentsOfMaterials.Contract = PartiesOfGivers.Contract
	|	INNER JOIN DataOnMaterialCosts AS Data
	|		ON Data.Organization = DD.Organization
	|		AND Data.Department = DD.Department
	|		AND Data.Material = DD.Material
	|		AND Data.ProductionLot = PartiesOfGivers.ProductionLot
	|		AND (Data.ProductsGroup = DD.ProductsGroup OR DD.ForAllProductGroups)
	|
	|WHERE
	|	DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials)
	|	OR DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials)
	|	OR DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials)
	|
	|GROUP BY
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.InventoryOwnerAttribute,
	|	DD.InventoryType,
	|	DD.AllocationBase,
	|	Data.Department,
	|	Data.ProductionLot,
	|	Data.VATActivityType,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT DD.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN DD.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.CorItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END,
	|	Data.Purpose,
	|	Data.Material,
	|	Data.ProductsGroup
	|
	// according to the standards, taking into account the assignments of the tolling scheme
	|UNION ALL
	|
	|SELECT
	|	DD.Recorder             AS Recorder,
	|	DD.Organization             AS Organization,
	|	DD.InventoryOwnerAttribute              AS InventoryOwnerAttribute,
	|	DD.InventoryType              AS InventoryType,
	|	DD.AllocationBase       AS AllocationBase,
	|	Data.Department       AS Department,
	|	Data.ProductionLot  AS ProductionLot,
	|	Data.VATActivityType  AS VATActivityType,
	|	Data.ProductsGroup     AS FinancialAccountingDimension,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT DD.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN DD.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END                      AS CorControllingAttributes,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.CorItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END                      AS CorItemsLocationAttributes,
	|	Data.Purpose          AS Purpose,
	|	Data.Material            AS Material,
	|	UNDEFINED               AS ManufacturedProduct,
	|	Data.ProductsGroup     AS ProductsGroup,
	|	UNDEFINED               AS WorkKind,
	|	SUM(CASE DD.AllocationBase
	|		WHEN VALUE(Enum.TypesOfCostAllocatingBase.StandardMaterialConsumption) THEN Data.Count
	|	END)                     AS Denominator,
	|	""Material""               AS IndicatorKind
	|FROM
	|	Allocate AS DD
	|
	|	INNER JOIN AssignmentsOfTollingMaterials AS AssignmentsOfMaterials
	|		ON (AssignmentsOfMaterials.PurposeOfMaterial = DD.Purpose
	|			OR AssignmentsOfMaterials.Partner = DD.Purpose.Partner
	|				AND AssignmentsOfMaterials.Contract = DD.Purpose.Contract)
	|	INNER JOIN PartiesOfTollProduction AS PartiesOfGivers
	|		ON AssignmentsOfMaterials.Partner = PartiesOfGivers.Partner
	|		AND AssignmentsOfMaterials.Contract = PartiesOfGivers.Contract
	|	INNER JOIN DataOnMaterialConsumptionStandards AS Data
	|		ON Data.Organization = DD.Organization
	|		AND Data.Department = DD.Department
	|		AND Data.Material = DD.Products
	|		AND Data.ProductionLot = PartiesOfGivers.ProductionLot
	|		AND (Data.ProductsGroup = DD.ProductsGroup OR DD.ForAllProductGroups)
	|
	|WHERE
	|	DD.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.StandardMaterialConsumption)
	|
	|GROUP BY
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.InventoryOwnerAttribute,
	|	DD.InventoryType,
	|	DD.AllocationBase,
	|	Data.Department,
	|	Data.ProductionLot,
	|	Data.VATActivityType,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT DD.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN DD.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.CorItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END,
	|	Data.Purpose,
	|	Data.Material,
	|	Data.ProductsGroup
	|;
	|
	|SELECT
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.InventoryOwnerAttribute,
	|	DD.InventoryType,
	|	DD.AllocationBase,
	|	DD.Department,
	|	DD.ProductionLot,
	|	DD.VATActivityType,
	|	(CASE
	|		WHEN DD.FinancialAccountingDimension = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE DD.FinancialAccountingDimension END) AS FinancialAccountingDimension,
	|	DD.CorControllingAttributes,
	|	DD.CorItemsLocationAttributes,
	|	DD.Purpose,
	|	SUM(DD.Denominator)
	|INTO AllocationBase
	|FROM
	|	DistributionBaseDetails AS DD
	|
	|GROUP BY
	|	DD.Recorder,
	|	DD.Organization,
	|	DD.InventoryOwnerAttribute,
	|	DD.InventoryType,
	|	DD.AllocationBase,
	|	DD.Department,
	|	DD.ProductionLot,
	|	DD.VATActivityType,
	|	(CASE
	|		WHEN DD.FinancialAccountingDimension = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE DD.FinancialAccountingDimension END), // FinancialAccountingDimension
	|	DD.CorControllingAttributes,
	|	DD.CorItemsLocationAttributes,
	|	DD.Purpose
	|;
	|";
	
EndFunction

// Tables: General Sums
Function TextOfSumOfProductDistributionIndicatorsForProduction() // TT Total sums
	Return "
	|SELECT
	|	DD.Recorder        AS Recorder,
	|	DD.InventoryOwnerAttribute         AS InventoryOwnerAttribute,
	|	SUM(DD.Denominator) AS Denominator
	|INTO TotalAmounts
	|FROM
	|	AllocationBase AS DD
	|GROUP BY
	|	DD.Recorder,
	|	DD.InventoryOwnerAttribute
	|;
	|";
	
EndFunction

// ... data samples

Function RequirementsForDistributionOfProductsForProduction() // uses to distribute, common sums
	
	Return "
	|SELECT DISTINCT
	|	""RequirementsForDistributionOfProductsForProduction""                      AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.Lot)                        AS EntryType,
	|	TRUE                                                                 AS CalculationIsCompleted,
	|	UNDEFINED                                                           AS RecordType,
	|	&EndOfPeriod                                                          AS Period,
	|	DD.Recorder                                                         AS Recorder,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN DD.ItemsLocationAttributes
	|		WHEN DD.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN DD.CommitteeAnalytics
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN DD.ItemsLocationAttributes
	|		ELSE DD.AnalysisOfAccountingForProductsWithoutAssignment
	|	END                                                                  AS ItemsLocationAttributes,
	|	CASE
	|		WHEN DD.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|		WHEN DD.InventoryType IN (
	|				VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		WHEN DD.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		WHEN DD.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|	END                                                                  AS AccountingSection,
	|	CASE
	|		WHEN DD.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN UNDEFINED
	|		ELSE DD.InventoryOwnerAttribute
	|	END                                                                  AS InventoryOwnerAttribute,
	|	DD.Organization                                                         AS Organization,
	|	UNDEFINED                                                           AS Lot,
	|	UNDEFINED                                                           AS LotVendorAttributes,
	|	UNDEFINED                                                           AS FinancialAccountingDimension,
	|	UNDEFINED                                                           AS VATActivityType,
	|	Total.Denominator                                                       AS Denominator,
	|	DD.Count                                                          AS Count,
	|	DD.Cost                                                           AS Cost,
	|	DD.LocalCost                                                       AS LocalCost,
	|	DD.CostExcludingVAT                                                     AS CostExcludingVAT,
	|	DD.CostMan                                                        AS CostMan,
	|	DD.OffBalanceCost                                               AS OffBalanceCost,
	|	DD.OffBalanceCostLocal                                           AS OffBalanceCostLocal,
	|	DD.PermanentDifference                                                   AS PermanentDifference,
	|	CASE
	|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			ELSE
	|				VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots)
	|	END 																   AS BusinessOperation,
	|	UNDEFINED                                                           AS CorAccountingSection,
	|	UNDEFINED                                                           AS CorItemsLocationAttributes,
	|	DD.RecipientInventoryOwnerAttribute                                                AS CorInventoryOwnerAttribute,
	|	UNDEFINED                                                           AS CorLot,
	|	UNDEFINED                                                           AS CorVATActivityTypes,
	|	UNDEFINED                                                           AS CorControllingAttributes,
	|	DD.AccountingDimensionByPartners                                           AS AccountingDimensionByPartners,
	|	UNDEFINED                                                           AS RowID,
	|	UNDEFINED                                                           AS ExpenseItemOfWriteOff,
	|	UNDEFINED                                                           AS DimensionOfExpenses,
	|	UNDEFINED                                                           AS AssetAndLiabilityItem,
	|	UNDEFINED                                                           AS AssetsLiabilitiesDimension,
	|	DD.Products                                                        AS Products,
	|	DD.Characteristic                                                      AS Characteristic,
	|	DD.Series                                                               AS Series,
	|	DD.Department                                                       AS Warehouse,
	|	UNDEFINED                                                           AS Purpose,
	|	DD.ProductCostElement                                                   AS ProductCostElement,
	|	SettingUpBusinessTransaction.Ref                                            AS BusinessTransactionSetting,
	|	DD.FinRecordID                                              AS FinRecordID,
	|	VALUE(Enum.WaysToCalculateInventoryCost.EmptyRef) AS CostDefiningMethod
	|FROM
	|	Allocate AS DD
	|	INNER JOIN TotalAmounts AS Total
	|		ON Total.Recorder = DD.Recorder
	|		AND Total.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS SettingUpBusinessTransaction
	|		ON SettingUpBusinessTransaction.BusinessOperation = 
	|		(CASE WHEN VALUETYPE(DD.Recorder) = TYPE(Document.RecyclableWasteAllocation)
	|			THEN VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|			ELSE VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots) END)
	|";
	
EndFunction

Function TextCostOfProductionCosts() // Uses bazarasdistribution
	
	Return "
	|SELECT
	|	""TextCostOfProductionCosts""                            AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.ConsumptionLotCalculation)               AS EntryType,
	|	FALSE                                                                   AS CalculationIsCompleted,
	|	VALUE(AccumulationRecordType.Expense)                                 AS RecordType,
	|	&EndOfPeriod                                                          AS Period,
	|	DD.Recorder                                                         AS Recorder,
	|	UNDEFINED                                                           AS ItemsLocationAttributes,
	|	UNDEFINED                                                           AS AccountingSection,
	|	CASE
	|		WHEN DD.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN UNDEFINED
	|		ELSE DD.InventoryOwnerAttribute
	|	END                                                                  AS InventoryOwnerAttribute,
	|	UNDEFINED                                                           AS Organization,
	|	UNDEFINED                                                           AS Lot,
	|	UNDEFINED                                                           AS LotVendorAttributes,
	|	UNDEFINED                                                           AS FinancialAccountingDimension,
	|	UNDEFINED                                                           AS VATActivityType,
	|	DD.Denominator                                                         AS Denominator,
	|	0                                                                      AS Count,
	|	0                                                                      AS Cost,
	|	0                                                                      AS LocalCost,
	|	0                                                                      AS CostExcludingVAT,
	|	0                                                                      AS CostMan,
	|	0                                                                      AS OffBalanceCost,
	|	0                                                                      AS OffBalanceCostLocal,
	|	0                                                                      AS PermanentDifference,
	|	UNDEFINED                                                           AS BusinessOperation,
	|	UNDEFINED                                                           AS CorAccountingSection,
	|	UNDEFINED                                                           AS CorItemsLocationAttributes,
	|	UNDEFINED                                                           AS CorInventoryOwnerAttribute,
	|	DD.ProductionLot                                                  AS CorLot,
	|	DD.VATActivityType                                                  AS CorVATActivityTypes,
	|	DD.FinancialAccountingDimension                                           AS CorControllingAttributes,
	|	UNDEFINED                                                           AS AccountingDimensionByPartners,
	|	UNDEFINED                                                           AS RowID,
	|	UNDEFINED                                                           AS ExpenseItemOfWriteOff,
	|	UNDEFINED                                                           AS DimensionOfExpenses,
	|	UNDEFINED                                                           AS AssetAndLiabilityItem,
	|	UNDEFINED                                                           AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                                           AS Products,
	|	UNDEFINED                                                           AS Characteristic,
	|	UNDEFINED                                                           AS Series,
	|	DD.Department                                                       AS Warehouse,
	|	DD.Purpose                                                          AS Purpose,
	|	UNDEFINED                                                           AS ProductCostElement,
	|	UNDEFINED                                                           AS BusinessTransactionSetting,
	|	""""                                                                   AS FinRecordID,
	|	(CASE
	|		WHEN DD.Organization IN (&MediumSlipOrganizations)
	|			THEN VALUE(Enum.WaysToCalculateInventoryCost.ByMovingAverage)
	|		ELSE VALUE(Enum.WaysToCalculateInventoryCost.EmptyRef) END) AS CostDefiningMethod
	|FROM
	|	AllocationBase AS DD
	|";
	
EndFunction

Function TextCostOfProductionReceipts() // Uses bazarasdistribution
	
	Return "
	|SELECT
	|	""TextCostOfProductionReceipts""                            AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.TransferAuto)               AS EntryType,
	|	FALSE                                                                   AS CalculationIsCompleted,
	|	VALUE(AccumulationRecordType.Receipt)                                 AS RecordType,
	|	&EndOfPeriod                                                          AS Period,
	|	DD.Recorder                                                         AS Recorder,
	|	UNDEFINED                                                           AS ItemsLocationAttributes,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS AccountingSection,
	|	CASE
	|		WHEN DD.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN UNDEFINED
	|		ELSE DD.InventoryOwnerAttribute
	|	END                                                                  AS InventoryOwnerAttribute,
	|	UNDEFINED                                                           AS Organization,
	|	DD.ProductionLot                                                  AS Lot,
	|	UNDEFINED                                                           AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension                                           AS FinancialAccountingDimension,
	|	DD.VATActivityType                                                  AS VATActivityType,
	|	DD.Denominator                                                         AS Denominator,
	|	0                                                                      AS Count,
	|	0                                                                      AS Cost,
	|	0                                                                      AS LocalCost,
	|	0                                                                      AS CostExcludingVAT,
	|	0                                                                      AS CostMan,
	|	0                                                                      AS OffBalanceCost,
	|	0                                                                      AS OffBalanceCostLocal,
	|	0                                                                      AS PermanentDifference,
	|	UNDEFINED                                                           AS BusinessOperation,
	|	UNDEFINED                                                           AS CorAccountingSection,
	|	DD.CorItemsLocationAttributes                                       AS CorItemsLocationAttributes,
	|	UNDEFINED                                                           AS CorInventoryOwnerAttribute,
	|	UNDEFINED                                                           AS CorLot,
	|	UNDEFINED                                                           AS CorVATActivityTypes,
	|	DD.CorControllingAttributes                                        AS CorControllingAttributes,
	|	UNDEFINED                                                           AS AccountingDimensionByPartners,
	|	UNDEFINED                                                           AS RowID,
	
	|	UNDEFINED                                                           AS ExpenseItemOfWriteOff,
	|	UNDEFINED                                                           AS DimensionOfExpenses,
	|	UNDEFINED                                                           AS AssetAndLiabilityItem,
	|	UNDEFINED                                                           AS AssetsLiabilitiesDimension,
	
	|	UNDEFINED                                                           AS Products,
	|	UNDEFINED                                                           AS Characteristic,
	|	UNDEFINED                                                           AS Series,
	|	DD.Department                                                       AS Warehouse,
	|	DD.Purpose                                                          AS Purpose,
	|	UNDEFINED                                                           AS ProductCostElement,
	|	UNDEFINED                                                           AS BusinessTransactionSetting,
	|	""""                                                                   AS FinRecordID,
	|	VALUE(Enum.WaysToCalculateInventoryCost.EmptyRef) AS CostDefiningMethod
	|FROM
	|	AllocationBase AS DD
	|";
	
EndFunction

// Filling out the payment batch

Procedure FillInEstimatedBatchOfDistributionOfProductsForProduction(CalculationParameters, SettlementBatch, Expense, Receipt)
	
	FillPropertyValues(SettlementBatch, Expense);
	
	If Receipt.Denominator = 0 Then
		Return;
	EndIf;
	
	If SettlementBatch.EntryType = Enums.LotRecordTypes.ConsumptionLotCalculation Then
		
		// the calculated batch is filled with the largest total deductible
		WriteOffDenominator = Min(Expense.Denominator, Receipt.Denominator);
		
		// we fill in the indicators of the settlement batch
		If WriteOffDenominator = Receipt.Denominator Then

			SettlementBatch.Count = Receipt.Count;
			SettlementBatch.Cost = Receipt.Cost;
			SettlementBatch.LocalCost = Receipt.LocalCost;
			SettlementBatch.CostExcludingVAT = Receipt.CostExcludingVAT;
			SettlementBatch.CostMan = Receipt.CostMan;
			SettlementBatch.OffBalanceCost = Receipt.OffBalanceCost;
			SettlementBatch.OffBalanceCostLocal = Receipt.OffBalanceCostLocal;
			SettlementBatch.PermanentDifference = Receipt.PermanentDifference;
			
		Else
			
			SettlementBatch.Count = Round(WriteOffDenominator * Receipt.Count / Receipt.Denominator, 3);
			SettlementBatch.Cost = Round(WriteOffDenominator * Receipt.Cost / Receipt.Denominator, 2);
			SettlementBatch.LocalCost = Round(WriteOffDenominator * Receipt.LocalCost / Receipt.Denominator, 2);
			SettlementBatch.CostExcludingVAT = Round(WriteOffDenominator * Receipt.CostExcludingVAT / Receipt.Denominator, 2);
			SettlementBatch.CostMan = Round(WriteOffDenominator * Receipt.CostMan / Receipt.Denominator, 2);
			SettlementBatch.OffBalanceCost = Round(WriteOffDenominator * Receipt.OffBalanceCost / Receipt.Denominator, 2);
			SettlementBatch.OffBalanceCostLocal = Round(WriteOffDenominator * Receipt.OffBalanceCostLocal / Receipt.Denominator, 2);
			SettlementBatch.PermanentDifference = Round(WriteOffDenominator * Receipt.PermanentDifference / Receipt.Denominator, 2);
			
		EndIf;
		
		// adjusting the calculation base in the parish
		Receipt.Denominator = Receipt.Denominator - WriteOffDenominator;
		Receipt.Count  = Receipt.Count - SettlementBatch.Count;
		Receipt.Cost   = Receipt.Cost - SettlementBatch.Cost;
		Receipt.LocalCost = Receipt.LocalCost - SettlementBatch.LocalCost;
		Receipt.CostExcludingVAT = Receipt.CostExcludingVAT - SettlementBatch.CostExcludingVAT;
		Receipt.CostMan = Receipt.CostMan - SettlementBatch.CostMan;
		Receipt.OffBalanceCost = Receipt.OffBalanceCost - SettlementBatch.OffBalanceCost;
		Receipt.OffBalanceCostLocal = Receipt.OffBalanceCostLocal - SettlementBatch.OffBalanceCostLocal;
		Receipt.PermanentDifference = Receipt.PermanentDifference - SettlementBatch.PermanentDifference;
		
		FillPropertyValues(SettlementBatch, Receipt, 
			"CalculationIsCompleted, AccountingSection, Organization, ItemsLocationAttributes, AccountingDimensionByPartners, Products, 
			|Characteristic, ProductCostElement, Series, InventoryOwnerAttribute, CorInventoryOwnerAttribute, BusinessOperation,
			|BusinessTransactionSetting, FinRecordID");
		
		If SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.ProductionCosts
			Or SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.ProductStock
			Or SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale Then
			SettlementBatch.CorAccountingSection = Enums.SectionsOfInventoryCostAccounting.WorkInProgress;
		ElsIf SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping Then
			SettlementBatch.CorAccountingSection = Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping;
		ElsIf SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing Then
			SettlementBatch.CorAccountingSection = Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing;
		EndIf;
		
		If TypeOf(SettlementBatch.Recorder) = Type("DocumentRef.RecyclableWasteAllocation") Then
			SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.EmptyRef();
		EndIf;
		
		If Not CalculationParameters.KeepRecordsOfInventoryCostByAssignments Then
			SettlementBatch.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
		
		SettlementBatch.CorItemsLocationAttributes = InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(SettlementBatch);
		If Not ValueIsFilled(SettlementBatch.FinRecordID) Then
			SettlementBatch.FinRecordID = String(New UUID);
		EndIf;
		If Not ValueIsFilled(SettlementBatch.BusinessTransactionSetting) Then
			SettlementBatch.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.ExpensingToProductionLots;
		EndIf;
		
	Else
		
		FillPropertyValues(SettlementBatch, Receipt, "CalculationIsCompleted, Organization, BusinessOperation, 
			|BusinessTransactionSetting, FinRecordID,
			|Count, Cost, LocalCost, 
			|CostExcludingVAT, CostMan, OffBalanceCost, OffBalanceCostLocal, PermanentDifference");
		
		SettlementBatch.ItemsLocationAttributes    = Receipt.CorItemsLocationAttributes;
		SettlementBatch.InventoryOwnerAttribute                    = Receipt.CorInventoryOwnerAttribute;
		SettlementBatch.AccountingSection                   = Receipt.CorAccountingSection;
		
		Receipt.Denominator = 0;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresOfStep5_DistributionOfProductsForRelease

// Data Initialization

Function ConsumptionFieldsOfProductDistributionForOutput(CalculationParameters)
	
	Return "Organization, Lot, Products, Characteristic, Department, Purpose, ProductCostElement,
		| SideProduct";
	
EndFunction

Function DescriptionOfDistributionChainsOfProductsForRelease(CalculationParameters)
	
	DescriptionOfChains = New Map;
	ConsumptionFields = ConsumptionFieldsOfProductDistributionForOutput(CalculationParameters);
	
	Lot          = Enums.LotRecordTypes.Lot;
	Estimated       = Enums.LotRecordTypes.Estimated;
	CostAllocationToProductionLots = Enums.LotRecordTypes.CostAllocationToProductionLots;
	
	// Settlement <- Batch
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains, Estimated, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Estimated, Lot, ConsumptionFields);
	
	// Movementauto <- Calculated
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains, CostAllocationToProductionLots,
		"Lot, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, CostAllocationToProductionLots, Estimated,
		"Lot, Organization");
	
	// Addition <- (<without sources - for generating records based on request data>)
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.Supplement);
	
	Return DescriptionOfChains;
	
EndFunction

Function DescriptionOfProductDistributionRegisteredRecords(CalculationParameters)
	
	DistributionTableColumns = TableForDistributionOfProductsPerIssue(CalculationParameters).Columns;
	
	RegisterRecordsDetails = CostCalculationAppliedAlgorithms.RegisterRecordsDetails();
	RegisterRecordsDetails.Insert("Context", "DistributionOfProductsForRelease");
	RegisterRecordsDetails.Insert("RegisterName", Metadata.AccumulationRegisters.InventoryCost.Name);
	RegisterRecordsDetails.Insert("CalculationFields", CostCalculationAppliedAlgorithms.ListOfFields(DistributionTableColumns));
	RegisterRecordsDetails.Insert("ComparisonKeys",	ConsumptionFieldsOfProductDistributionForOutput(CalculationParameters));
	RegisterRecordsDetails.Insert("Indicators", "Count");
	RegisterRecordsDetails.Insert("BasisOfArrival", "Denominator");
	RegisterRecordsDetails.Insert("BasisOfConsumption", "Denominator");
	RegisterRecordsDetails.Insert("OrderField_", "Period");
	
	Return RegisterRecordsDetails;
	
EndFunction

Function DescriptionOfUnrecordedProductDistributionsPerIssue(CalculationParameters)
	
	UnrecordedRecordTypes = New Map;
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.Lot, True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.Estimated, True);
	
	Return CostCalculationAppliedAlgorithms.DescriptionOfNonWritableData(False, UnrecordedRecordTypes);
	
EndFunction

Function TableForDistributionOfProductsPerIssue(CalculationParameters)
	
	Return CostCalculationAppliedAlgorithms.TableForDistributionOfLots(CalculationParameters,
		TextDescriptionOfDataForDistributionOfProductsPerIssue());
	
EndFunction

// Sample data

Procedure GetDataForProductDistributionPerIssue(CalculationParameters)
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"Organization", // Separator
		"Denominator, Count", // Resources
		"Organization, Lot, ItemsLocationAttributes"); // Order
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForProductAllocation(),
		NumberingParameters);
	
EndProcedure

// Request texts

// ... general

Function RequestTextForProductAllocation() Export
	
	QueryText = ""
		// preparation of temporary tables
		+ TextEstimatedDistributionOfProductsPerIssue() // Material residuals, Calculated
		// data sampling
		+ TextDescriptionOfDataForDistributionOfProductsPerIssue()
		+ TMCommonUse.QuerySeparatorInJoin() + TextLoopedProductsPerIssue()
		+ TMCommonUse.QuerySeparatorInJoin() + TextProductsForDistributionForRelease() // uses the rest of the materials, topping up the issue
		+ TMCommonUse.QuerySeparatorInJoin() + TextEstimatedQuantityToDistribution() // uses the Calculated
		+ TMCommonUse.QuerySeparatorInJoin() + TextDistributionOfProductsForOutputByProduct() // uses Products
		+ "";
	
	Return QueryText;
	
EndFunction

// ... data descriptions

Function TextDescriptionOfDataForDistributionOfProductsPerIssue()
	
	QueryText = 
	"SELECT TOP 0
	|	CAST("""" AS STRING(80))          								 AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.EmptyRef)                AS EntryType,
	|	FALSE                                                                 AS CalculationIsCompleted,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
	|	DD.RecordType                                                       AS RecordType,
	|	DD.Period                                                            AS Period,
	|	DD.Recorder                                                       AS Recorder,
	|	DD.ItemsLocationAttributes                                        AS ItemsLocationAttributes,
	|	DD.ItemsLocationAttributes.Products                           AS Products,
	|	DD.ItemsLocationAttributes.Characteristic                         AS Characteristic,
	|	DD.ItemsLocationAttributes.Department                          AS Department,
	|	DD.ItemsLocationAttributes.Purpose                             AS Purpose,
	|	DD.ProductCostElement                                                 AS ProductCostElement,
	|	DD.InventoryOwnerAttribute                                                        AS InventoryOwnerAttribute,
	|	DD.Organization                                                       AS Organization,
	|	DD.Lot                                                            AS Lot,
	|	DD.LotVendorAttributes                                              AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension                                         AS FinancialAccountingDimension,
	|	DD.VATActivityType                                                AS VATActivityType,
	|	0                                                                    AS Denominator,
	|	0                                                                    AS ShareOfOutput,
	|	0                                                                    AS Count,
	|	FALSE                                                                 AS SideProduct,
	|	DD.Cost                                                         AS Cost,
	|	DD.CostExcludingVAT                                                   AS CostExcludingVAT,
	|	DD.OffBalanceCost                                             AS OffBalanceCost,
	|	DD.LocalCost                                                     AS LocalCost,
	|	DD.OffBalanceCostLocal                                         AS OffBalanceCostLocal,
	|	DD.CostMan                                                      AS CostMan,
	|	DD.BusinessOperation                                             AS BusinessOperation,
	|	DD.CorItemsLocationAttributes                                     AS CorItemsLocationAttributes,
	|	DD.CorAccountingSection                                                    AS CorAccountingSection,
	|	DD.CorInventoryOwnerAttribute                                                     AS CorInventoryOwnerAttribute,
	|	DD.ExpenseItemOfWriteOff                                            AS ExpenseItemOfWriteOff,
	|	DD.DimensionOfExpenses                                                 AS DimensionOfExpenses,
	|	DD.AssetAndLiabilityItem                                             AS AssetAndLiabilityItem,
	|	DD.AssetsLiabilitiesDimension                                          AS AssetsLiabilitiesDimension,
	|	DD.CorLot                                                         AS CorLot,
	|	DD.LotVendorAttributesCorr                                           AS LotVendorAttributesCorr,
	|	DD.CorVATActivityTypes                                             AS CorVATActivityTypes,
	|	DD.CorControllingAttributes                                      AS CorControllingAttributes,
	|	DD.DocumentVATActivityType                                       AS DocumentVATActivityType,
	|	DD.RowID                                               AS RowID,
	|	DD.DocumentSource                                                  AS DocumentSource,
	|	DD.BusinessTransactionSetting                                    AS BusinessTransactionSetting,
	|	DD.FinRecordID                                            AS FinRecordID
	|INTO Data
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|";
	
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;

EndFunction

// ... formation of temporary tables

// Table: vestedinterest, Studymaterials, Studymaterials, tplanpicture,
//          Perfectmail, whspecialeducation, strassenkarte Settlement.
Function TextEstimatedDistributionOfProductsPerIssue()
	
	QueryText =
	"SELECT
	|	DD.Organization                                  AS Organization,
	|	DD.ItemsLocationAttributes.Products      AS Products,
	|	DD.ItemsLocationAttributes.Characteristic    AS Characteristic,
	|	DD.ItemsLocationAttributes.Department     AS Department,
	|	DD.ItemsLocationAttributes.Purpose        AS Purpose,
	|	DD.ItemsLocationAttributes.ProductCostElement AS ProductCostElement,
	|	DD.ProductionLot                           AS ProductionLot,
	|	CASE
	|		WHEN DD.Count < 0
	|			THEN -1
	|		ELSE 1
	|	END                                           AS ReductionRatio,
	|	DD.SideProduct                              AS SideProduct,
	|	SUM(DD.Count)                            AS Count
	|INTO RemainsOfMaterialsAreSummarized
	|FROM
	|	RemainingMaterials AS DD
	|
	|GROUP BY
	|	DD.Organization,
	|	DD.ItemsLocationAttributes.Products,
	|	DD.ItemsLocationAttributes.CHARACTERISTIC,
	|	DD.ItemsLocationAttributes.Department,
	|	DD.ItemsLocationAttributes.Purpose,
	|	DD.ItemsLocationAttributes.ProductCostElement,
	|	DD.ProductionLot,
	|	CASE
	|		WHEN DD.Count < 0
	|			THEN -1
	|		ELSE 1
	|	END,
	|	DD.SideProduct
	|
	|INDEX BY
	|	ProductionLot,
	|	Products,
	|	Characteristic,
	|	Department,
	|	Purpose,
	|	ProductCostElement,
	|	Organization,
	|	ReductionRatio
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlanOfProductionOfMaterials.Organization           AS Organization,
	|	PlanOfProductionOfMaterials.ProductionLot    AS ProductionLot,
	|	PlanOfProductionOfMaterials.Products          AS Products,
	|	PlanOfProductionOfMaterials.Characteristic        AS Characteristic,
	|	PlanOfProductionOfMaterials.Department         AS Department,
	|	PlanOfProductionOfMaterials.Purpose            AS Purpose,
	|	PlanOfProductionOfMaterials.ProductCostElement     AS ProductCostElement,
	|	CASE
	|		WHEN SUM(PlanOfProductionOfMaterials.Real) < 0
	|			THEN -1
	|		ELSE 1
	|	END                                    AS ReductionRatio,
	|	PlanOfProductionOfMaterials.SideProduct       AS SideProduct,
	|	SUM(PlanOfProductionOfMaterials.Plan)           AS Plan,
	|	CASE
	|		WHEN SUM(PlanOfProductionOfMaterials.Real) < 0
	|			THEN -1 * SUM(PlanOfProductionOfMaterials.Real)
	|		ELSE SUM(PlanOfProductionOfMaterials.Real)
	|	END                                                  AS Real
	|INTO PlanOfProductionOfMaterials
	|FROM
	|	(
	// the fact of materials and waste of the current period
	|	SELECT
	|		UsedMaterials.Organization                                  AS Organization,
	|		UsedMaterials.Lot                                       AS ProductionLot,
	|		UsedMaterials.ItemsLocationAttributes.Products      AS Products,
	|		UsedMaterials.ItemsLocationAttributes.Characteristic    AS Characteristic,
	|		UsedMaterials.ItemsLocationAttributes.Department     AS Department,
	|		UsedMaterials.ItemsLocationAttributes.Purpose        AS Purpose,
	|		UsedMaterials.ItemsLocationAttributes.ProductCostElement AS ProductCostElement,
	|		0                                                      AS Plan,
	|		UsedMaterials.Count                                   AS Real,
	|		CASE
	|			WHEN UsedMaterials.ItemsLocationAttributes.ProductCostElement.ExpenseType = VALUE(Enum.CostTypes.RecyclableWaste)
	|				THEN TRUE
	|			ELSE FALSE
	|		END                                                  AS SideProduct
	|	FROM
	|		ProductionBatchesAreSummarized AS DD
	|		
	|		INNER JOIN TTCashEstimatedTurnoverCostOfGoods AS UsedMaterials
	|		ON DD.ProductionLot = UsedMaterials.Lot
	|		AND DD.Organization = UsedMaterials.Organization
	|		
	|	WHERE
	|		DD.CostAllocationForIssue
	|		AND UsedMaterials.OfficialTypeOfMovementParish
	// We exclude storno, as the initial Registered Records of past periods will be obtained
	|		AND NOT UsedMaterials.ReversingEntry
	|
	|	UNION ALL
	|
		// the fact of materials and waste distributed according to the rules
	|	SELECT
	|		UsedMaterials.Organization                                  AS Organization,
	|		UsedMaterials.Lot                                       AS ProductionLot,
	|		UsedMaterials.ItemsLocationAttributes.Products      AS Products,
	|		UsedMaterials.ItemsLocationAttributes.Characteristic    AS Characteristic,
	|		UsedMaterials.ItemsLocationAttributes.Department     AS Department,
	|		UsedMaterials.ItemsLocationAttributes.Purpose        AS Purpose,
	|		UsedMaterials.ItemsLocationAttributes.ProductCostElement AS ProductCostElement,
	|		0                                                      AS Plan,
	|		UsedMaterials.Count                                   AS Real,
	|		CASE
	|			WHEN UsedMaterials.ItemsLocationAttributes.ProductCostElement.ExpenseType = VALUE(Enum.CostTypes.RecyclableWaste)
	|				THEN TRUE
	|			ELSE FALSE
	|		END                                                  AS SideProduct
	|	FROM
	|		ProductionBatchesAreSummarized AS DD
	|			INNER JOIN TTProductionCostsCostOfGoods AS UsedMaterials
	|			ON DD.ProductionLot = UsedMaterials.Lot
	|			AND DD.Organization = UsedMaterials.Organization
	|	WHERE
	|		UsedMaterials.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|	UNION ALL
	|
		// stage materials plan
	|	SELECT
	|		DD.Organization                AS Organization,
	|		DD.ProductionLot         AS ProductionLot,
	|		Supply.Products      AS Products,
	|		Supply.Characteristic    AS Characteristic,
	|		Supply.Department     AS Department,
	|		CASE
	|			WHEN &KeepRecordsOfInventoryCostByAssignments
	|				THEN Supply.Ref.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END                         AS Purpose,
	|		Supply.ProductCostElement AS ProductCostElement,
	|		Supply.Count        AS Plan,
	|		0                             AS Real,
	|		FALSE                          AS SideProduct
	|	FROM
	|		ProductionBatchesAreSummarized AS DD
	|			INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Supply
	|			ON DD.ProductionLot = Supply.Ref.ProductionLot
	|
	|	WHERE
	|		DD.CostAllocationForIssue
		// The processing data of the releasing stage on the side is excluded, because the movements are formed by a report without distribution.
	|		AND NOT Supply.Ref.ProductionByThirdParty
	|		AND NOT Supply.Canceled
	|
	|	UNION ALL
	|
		// the plan of materials of the stages performed on the side (processing 2.5 by stages)
	|	SELECT
	|		DD.Organization                AS Organization,
	|		DD.ProductionLot         AS ProductionLot,
	|		Supply.Products      AS Products,
	|		Supply.Characteristic    AS Characteristic,
	|		VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|		CASE
	|			WHEN &KeepRecordsOfInventoryCostByAssignments
	|				THEN DD.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END                         AS Purpose,
	|		Supply.ProductCostElement AS ProductCostElement,
	|		Supply.Count        AS Plan,
	|		0                             AS Real,
	|		FALSE                          AS SideProduct
	|	FROM
	|		ProductionBatchesByStages AS DD
	|			INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Supply
	|			ON DD.Stage = Supply.Ref
	|
	|	WHERE
	|		DD.CostAllocationForIssue
	|		AND Supply.Ref.ProductionByThirdParty2_5
	|		AND NOT Supply.Canceled
	|
	|	UNION ALL
	|
		// the plan of processing services in the orders of the processor (processing 2.5 by stages)
	|	SELECT
	|		DD.Organization           AS Organization,
	|		DD.ProductionLot    AS ProductionLot,
	|		Services.Products      AS Products,
	|		Services.Characteristic    AS Characteristic,
	|		VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|		CASE
	|			WHEN &KeepRecordsOfInventoryCostByAssignments
	|				THEN DD.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END                    AS Purpose,
	|		Services.ProductCostElement AS ProductCostElement,
	|		Services.Count        AS Plan,
	|		0                        AS Real,
	|		FALSE                     AS SideProduct
	|	FROM
	|		ProductionBatchesByStages AS DD
	|			INNER JOIN Document.SubcontractOrder2_5.Services AS Services
	|			ON DD.Stage = Services.Ref.ReferenceOrder
	|
	|	WHERE
	|		DD.CostAllocationForIssue
	|		AND NOT Services.Canceled
	|
	|	UNION ALL
	|
		// waste plan of the chain stages
	|	SELECT
	|		DD.Organization                  AS Organization,
	|		DD.ProductionLot           AS ProductionLot,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		GoodsTable.Department     AS Department,
	|		CASE
	|			WHEN &KeepRecordsOfInventoryCostByAssignments
	|				THEN GoodsTable.Ref.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END                           AS Purpose,
	|		GoodsTable.ProductCostElement AS ProductCostElement,
	|		GoodsTable.Count        AS Plan,
	|		0                               AS Real,
	|		TRUE                          AS SideProduct
	|	FROM
	|		ProductionBatchesAreSummarized AS DD
	|			INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS GoodsTable
	|			ON DD.ProductionLot = GoodsTable.Ref.ProductionLot
	|
	|	WHERE
	|		DD.CostAllocationForIssue
			// The processing data of the releasing stage on the side is excluded, because the movements are formed by a report without distribution.
	|		AND NOT GoodsTable.Ref.ProductionByThirdParty
	|		AND NOT GoodsTable.Canceled
	|
	|	UNION ALL
	|
	// waste plan for the stages of other chains
	|	SELECT
	|		DD.Organization                  AS Organization,
	|		DD.ProductionLot           AS ProductionLot,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		GoodsTable.Department     AS Department,
	|		CASE
	|			WHEN &KeepRecordsOfInventoryCostByAssignments
	|				THEN GoodsTable.Ref.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END                           AS Purpose,
	|		GoodsTable.ProductCostElement AS ProductCostElement,
	|		GoodsTable.Count        AS Plan,
	|		0                               AS Real,
	|		TRUE                          AS SideProduct
	|	FROM
	|		ProductionBatchesAreSummarized AS DD
	|			INNER JOIN Document.ProductionStage2_2 AS ChainStages
	|			ON DD.ProductionLot = ChainStages.ProductionLot
	|
	|			INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS GoodsTable
	|			ON ChainStages.Ref = GoodsTable.StageConsumer
	|
	|			INNER JOIN Document.ProductionStage2_2 AS StagesOfOtherChains
	|			ON StagesOfOtherChains.Ref = GoodsTable.Ref
	|
	|	WHERE
	|		DD.CostAllocationForIssue
	// The processing data of the releasing stage on the side is excluded, because the movements are formed by a report without distribution.
	|		AND NOT GoodsTable.Ref.ProductionByThirdParty
	|		AND NOT GoodsTable.Canceled
	|		AND NOT ChainStages.ProductionLot = StagesOfOtherChains.ProductionLot
	|
	|	UNION ALL
	|
	// the fact of materials and waste for past periods
	|	SELECT
	|		UsedMaterials.Organization                                  AS Organization,
	|		UsedMaterials.Lot                                       AS ProductionLot,
	|		UsedMaterials.ItemsLocationAttributes.Products      AS Products,
	|		UsedMaterials.ItemsLocationAttributes.Characteristic    AS Characteristic,
	|		UsedMaterials.ItemsLocationAttributes.Department     AS Department,
	|		UsedMaterials.ItemsLocationAttributes.Purpose        AS Purpose,
	|		UsedMaterials.ItemsLocationAttributes.ProductCostElement AS ProductCostElement,
	|		0                                                      AS Plan,
	|		UsedMaterials.Count                                   AS Real,
	|		CASE
	|			WHEN UsedMaterials.ItemsLocationAttributes.ProductCostElement.ExpenseType = VALUE(Enum.CostTypes.RecyclableWaste)
	|				THEN TRUE
	|			ELSE FALSE
	|		END                                                  AS SideProduct
	|	FROM
	|		ProductionBatchesAreSummarized AS DD
	|		
	|		INNER JOIN AccumulationRegister.InventoryCost AS UsedMaterials
	|		ON DD.ProductionLot = UsedMaterials.Lot
	|		AND DD.Organization = UsedMaterials.Organization
	|		
	|	WHERE
	|		DD.CostAllocationForIssue
	|		AND UsedMaterials.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND UsedMaterials.Period < &BeginOfPeriod
	|) AS PlanOfProductionOfMaterials
	|
	|GROUP BY
	|	PlanOfProductionOfMaterials.Organization,
	|	PlanOfProductionOfMaterials.ProductionLot,
	|	PlanOfProductionOfMaterials.Products,
	|	PlanOfProductionOfMaterials.Characteristic,
	|	PlanOfProductionOfMaterials.Department,
	|	PlanOfProductionOfMaterials.Purpose,
	|	PlanOfProductionOfMaterials.ProductCostElement,
	|	PlanOfProductionOfMaterials.SideProduct
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Expenses.Lot                                       AS ProductionLot,
	|	Expenses.ItemsLocationAttributes.Products      AS Products,
	|	Expenses.ItemsLocationAttributes.Characteristic    AS Characteristic,
	|	Expenses.ItemsLocationAttributes.Department     AS Department,
	|	Expenses.ItemsLocationAttributes.Purpose        AS Purpose,
	|	Expenses.ItemsLocationAttributes.ProductCostElement AS ProductCostElement,
	|	SUM(Expenses.CountExpense)                      AS Count
	|INTO TTWrittenOffInPreviousMonths
	|FROM
	|	AccumulationRegister.InventoryCost.Turnovers(,
	|		DATEADD(&BeginOfPeriod, SECOND, - 1),,
	|		Lot IN (SELECT
	|					T.ProductionLot
	|				FROM
	|					ProductionBatchesAreSummarized AS T
	|				WHERE
	|					T.LongTermProduction
	|					AND T.CostAllocationForIssue)
	|		) AS Expenses
	|GROUP BY
	|	Expenses.Lot,
	|	Expenses.ItemsLocationAttributes.Products,
	|	Expenses.ItemsLocationAttributes.Characteristic,
	|	Expenses.ItemsLocationAttributes.Department,
	|	Expenses.ItemsLocationAttributes.Purpose,
	|	Expenses.ItemsLocationAttributes.ProductCostElement
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Organization                      AS Organization,
	|	DD.ProductionLot               AS ProductionLot,
	|	DD.Products                     AS Products,
	|	DD.Characteristic                   AS Characteristic,
	|	DD.Department                    AS Department,
	|	DD.Purpose                       AS Purpose,
	|	DD.ProductCostElement                AS ProductCostElement,
	|	DD.ReductionRatio            AS ReductionRatio,
	|	DD.SideProduct                  AS SideProduct,
	|	CASE
	|		WHEN DD.Plan > DD.Real
	|			THEN DD.Plan
	|		ELSE DD.Real
	|	END * ReleaseShares.ShareOfTotalOutput
	|		- DD.ReductionRatio * ISNULL(WrittenOff.Count, 0) AS EstimatedQuantity,
	|	ReleaseShares.ProductionCompleted   AS ProductionCompleted,
	// additional fields for decryption
	|	DD.Plan                             AS Plan,
	|	DD.Real                             AS Real,
	|	ReleaseShares.ShareOfTotalOutput        AS ShareOfTotalOutput,
	|	ReleaseShares.ShareOfIssueOfMonth       AS ShareOfIssueOfMonth,
	|	WrittenOff.Count                  AS AmountWrittenOffInPastMonths
	|INTO TTEstimatedQuantity
	|FROM
	|	PlanOfProductionOfMaterials AS DD
	|		INNER JOIN ReleaseShares AS ReleaseShares
	|		ON DD.ProductionLot = ReleaseShares.ProductionLot
	|		AND DD.Organization = ReleaseShares.Organization
	|
	|		LEFT JOIN TTWrittenOffInPreviousMonths AS WrittenOff
	|		ON DD.ProductionLot = WrittenOff.ProductionLot
	|			AND DD.Products = WrittenOff.Products
	|			AND DD.Characteristic = WrittenOff.Characteristic
	|			AND DD.Department = WrittenOff.Department
	|			AND DD.Purpose = WrittenOff.Purpose
	|			AND DD.ProductCostElement = WrittenOff.ProductCostElement
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Organization                      AS Organization,
	|	DD.ProductionLot               AS ProductionLot,
	|	DD.Products                     AS Products,
	|	DD.Characteristic                   AS Characteristic,
	|	DD.Department                    AS Department,
	|	DD.Purpose                       AS Purpose,
	|	DD.ProductCostElement                AS ProductCostElement,
	|	DD.SideProduct                  AS SideProduct,
	|	CASE
	|		WHEN DD.ProductionCompleted
	|			THEN
	|				CASE
	|					WHEN ISNULL(Balance.Count, 0) = 0
	|						THEN DD.EstimatedQuantity
	|					ELSE
	|						Balance.Count
	|				END
	|		WHEN DD.EstimatedQuantity > ISNULL(Balance.Count, 0) * DD.ReductionRatio
	|			THEN ISNULL(Balance.Count, 0)
	|		ELSE DD.ReductionRatio * DD.EstimatedQuantity
	|	END                               AS EstimatedQuantity,
	// additional fields for decryption
	|	DD.Plan                             AS NumberOfTotalPlan,
	|	DD.Real                             AS TotalQuantityIsFact,
	|	DD.ShareOfTotalOutput                 AS ShareOfTotalOutput,
	|	DD.ShareOfIssueOfMonth                AS ShareOfIssueOfMonth,
	|	DD.AmountWrittenOffInPastMonths AS AmountWrittenOffInPastMonths
	|INTO Estimated
	|FROM
	|	TTEstimatedQuantity AS DD
	|		LEFT JOIN RemainsOfMaterialsAreSummarized AS Balance
	|		ON DD.ProductionLot = Balance.ProductionLot
	|			AND DD.Products = Balance.Products
	|			AND DD.Characteristic = Balance.Characteristic
	|			AND DD.Department = Balance.Department
	|			AND DD.Purpose = Balance.Purpose
	|			AND DD.ProductCostElement = Balance.ProductCostElement
	|			AND DD.ReductionRatio = Balance.ReductionRatio
	|;
	|";
	
	Return QueryText
	
EndFunction

// ... data samples

Function TextProductsForDistributionForRelease() // uses the rest of the materials, topping up the issue
	
	Return "
	|SELECT DISTINCT
	|	""TextProductsForDistributionForRelease""                          AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.Lot)                      AS EntryType,
	|	TRUE                                                               AS CalculationIsCompleted,
	|	DD.AccountingSection                                                       AS AccountingSection,
	|	VALUE(AccumulationRecordType.Expense)                               AS RecordType,
	|	&EndOfPeriod                                                        AS Period,
	|	ClosedParties.ReleaseParty                                        AS Recorder,
	|	DD.ItemsLocationAttributes                                        AS ItemsLocationAttributes,
	|	DD.ItemsLocationAttributes.Products                           AS Products,
	|	DD.ItemsLocationAttributes.Characteristic                         AS Characteristic,
	|	DD.ItemsLocationAttributes.Department                          AS Department,
	|	DD.ItemsLocationAttributes.Purpose                             AS Purpose,
	|	DD.ItemsLocationAttributes.ProductCostElement                      AS ProductCostElement,
	|	DD.InventoryOwnerAttribute                                                        AS InventoryOwnerAttribute,
	|	DD.Organization                                                       AS Organization,
	|	DD.ProductionLot                                                AS Lot,
	|	DD.LotVendorAttributes                                              AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension                                         AS FinancialAccountingDimension,
	|	DD.VATActivityType                                                AS VATActivityType,
	|	CAST(
	|		DD.ReductionRatio
	|		* (DD.Count
	|			- ISNULL(ClosedParties.Count, 0)) AS NUMBER(23,10)) AS Denominator,
	|	Total.ShareOfIssueOfMonth                                               AS ShareOfOutput,
	|	DD.Count - ISNULL(ClosedParties.Count, 0)              AS Count,
	|	DD.SideProduct                                                   AS SideProduct,
	|	DD.Cost AS Cost,
	|	DD.CostExcludingVAT AS CostExcludingVAT,
	|	DD.OffBalanceCost AS OffBalanceCost,
	|	DD.LocalCost AS LocalCost,
	|	DD.OffBalanceCostLocal AS OffBalanceCostLocal,
	|	DD.CostMan AS CostMan,
	|	UNDEFINED                                                         AS BusinessOperation,
	|	UNDEFINED                                                         AS CorItemsLocationAttributes,
	|	UNDEFINED                                                         AS CorAccountingSection,
	|	UNDEFINED                                                         AS CorInventoryOwnerAttribute,
	|	UNDEFINED                                                         AS ExpenseItemOfWriteOff,
	|	UNDEFINED                                                         AS DimensionOfExpenses,
	|	UNDEFINED                                                         AS AssetAndLiabilityItem,
	|	UNDEFINED                                                         AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                                         AS CorLot,
	|	UNDEFINED                                                         AS LotVendorAttributesCorr,
	|	UNDEFINED                                                         AS CorVATActivityTypes,
	|	UNDEFINED                                                         AS CorControllingAttributes,
	|	UNDEFINED                                                         AS DocumentVATActivityType,
	|	UNDEFINED                                                         AS RowID,
	|	UNDEFINED                                                         AS DocumentSource,
	|	UNDEFINED                                                         AS BusinessTransactionSetting,
	|	""""                                                                 AS FinRecordID
	|FROM
	|	RemainingMaterials AS DD
	|	INNER JOIN ReleaseShares AS Total
	|		ON Total.ProductionLot = DD.ProductionLot
	|		AND DD.Organization = Total.Organization
	|
	|	LEFT JOIN ClosedParties AS ClosedParties
	|		ON ClosedParties.ProductionLot = DD.ProductionLot
	|		AND ClosedParties.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|";
	
EndFunction

Function TextLoopedProductsPerIssue()
	
	Return "
	|SELECT DISTINCT
	|	""Cycles""                                                            AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.Supplement)                  AS EntryType,
	|	TRUE                                                               AS CalculationIsCompleted,
	|	DD.AccountingSection                                                       AS AccountingSection,
	|	VALUE(AccumulationRecordType.Expense)                               AS RecordType,
	|	&EndOfPeriod                                                        AS Period,
	|	ManufacturedProduct.ReleaseParty                                              AS Recorder,
	|	DD.ItemsLocationAttributes                                        AS ItemsLocationAttributes,
	|	DD.ItemsLocationAttributes.Products                           AS Products,
	|	DD.ItemsLocationAttributes.Characteristic                         AS Characteristic,
	|	DD.ItemsLocationAttributes.Department                          AS Department,
	|	DD.ItemsLocationAttributes.Purpose                             AS Purpose,
	|	DD.ItemsLocationAttributes.ProductCostElement                      AS ProductCostElement,
	|	DD.InventoryOwnerAttribute                                                        AS InventoryOwnerAttribute,
	|	DD.Organization                                                       AS Organization,
	|	DD.ProductionLot                                                AS Lot,
	|	DD.LotVendorAttributes                                              AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension                                         AS FinancialAccountingDimension,
	|	DD.VATActivityType                                                AS VATActivityType,
	|	0                                                                    AS Denominator,
	|	0                                                                    AS ShareOfOutput,
	|	LotsOfGNZPMaterials.Count                                      AS Count,
	|	DD.SideProduct                                                   AS SideProduct,
	|	0                                                                    AS Cost,
	|	0                                                                    AS CostExcludingVAT,
	|	0                                                                    AS OffBalanceCost,
	|	0                                                                    AS LocalCost,
	|	0                                                                    AS OffBalanceCostLocal,
	|	0                                                                    AS CostMan,
	|	ManufacturedProduct.BusinessOperation                                      AS BusinessOperation,
	|	ManufacturedProduct.ItemsLocationAttributes                                 AS CorItemsLocationAttributes,
	|	ManufacturedProduct.AccountingSection                                                AS CorAccountingSection,
	|	ManufacturedProduct.InventoryOwnerAttribute                                                 AS CorInventoryOwnerAttribute,
	|	UNDEFINED                                                         AS ExpenseItemOfWriteOff,
	|	UNDEFINED                                                         AS DimensionOfExpenses,
	|	UNDEFINED                                                         AS AssetAndLiabilityItem,
	|	UNDEFINED                                                         AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|				AND ManufacturedProduct.Organization IN (&SFIFOOrganizationsSliding)
	|			THEN ManufacturedProduct.ReleaseParty
	|		ELSE UNDEFINED
	|	END                                                                AS CorLot,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|				AND ManufacturedProduct.Organization IN (&SFIFOOrganizationsSliding)
	|			THEN ManufacturedProduct.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END                                                                AS LotVendorAttributesCorr,
	|	ISNULL(RegisterRecords.VATActivityType, ManufacturedProduct.VATActivityType)  AS CorVATActivityTypes,
	|	ISNULL(RegisterRecords.FinancialAccountingDimension, ManufacturedProduct.FinancialAccountingDimension) AS CorControllingAttributes,
	|	ISNULL(RegisterRecords.VATActivityType, ManufacturedProduct.VATActivityType)  AS DocumentVATActivityType,
	|	ManufacturedProduct.RowID                                        AS RowID,
	|	RegisterRecords.Recorder                                                 AS DocumentSource,
	|	UNDEFINED                                                         AS BusinessTransactionSetting,
	|	""""                                                                 AS FinRecordID
	|FROM
	|	RemainingMaterials AS DD
	|	INNER JOIN LotsOfGNZPMaterials AS LotsOfGNZPMaterials
	|		ON LotsOfGNZPMaterials.ProductionLot = DD.ProductionLot
	|		AND LotsOfGNZPMaterials.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND LotsOfGNZPMaterials.Organization = DD.Organization
	|	INNER JOIN ManufacturedProduct AS ManufacturedProduct
	|		ON LotsOfGNZPMaterials.ProductionLot = ManufacturedProduct.ProductionLot
	|		AND LotsOfGNZPMaterials.BatchOfMaterial = ManufacturedProduct.ReleaseParty
	|		AND LotsOfGNZPMaterials.LotVendorAttributes = ManufacturedProduct.LotVendorAttributes
	|		AND ManufacturedProduct.Organization = DD.Organization
	|
	|	LEFT JOIN AccumulationRegister.InventoryCost AS RegisterRecords
	|	ON RegisterRecords.Recorder = ManufacturedProduct.ReleaseParty
	|		AND RegisterRecords.RowID = ManufacturedProduct.RowID
	|		AND ManufacturedProduct.RowID <> """"
	|		AND RegisterRecords.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|		AND NOT RegisterRecords.LotCalculation
	|		AND NOT RegisterRecords.CalculationOfCost
	// exclusion of work movements for the giver
	|		AND RegisterRecords.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|";
	
EndFunction

Function TextEstimatedQuantityToDistribution() // uses the Calculated
	
	Return "
	|SELECT DISTINCT
	|	""TextEstimatedQuantityToDistribution""                           AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.Estimated)                   AS EntryType,
	|	FALSE                                                                 AS CalculationIsCompleted,
	|	UNDEFINED                                                         AS AccountingSection,
	|	VALUE(AccumulationRecordType.Expense)                               AS RecordType,
	|	&EndOfPeriod                                                        AS Period,
	|	ClosedParties.ReleaseParty                                        AS Recorder,
	|	UNDEFINED                                                         AS ItemsLocationAttributes,
	|	DD.Products                                                      AS Products,
	|	DD.Characteristic                                                    AS Characteristic,
	|	DD.Department                                                     AS Department,
	|	DD.Purpose                                                        AS Purpose,
	|	DD.ProductCostElement                                                 AS ProductCostElement,
	|	UNDEFINED                                                         AS InventoryOwnerAttribute,
	|	DD.Organization                                                       AS Organization,
	|	DD.ProductionLot                                                AS Lot,
	|	UNDEFINED                                                         AS LotVendorAttributes,
	|	UNDEFINED                                                         AS FinancialAccountingDimension,
	|	UNDEFINED                                                         AS VATActivityType,
	|	CAST(CASE
	|		WHEN DD.EstimatedQuantity - ISNULL(ClosedParties.Count, 0) < 0
	|			THEN (-1)*(DD.EstimatedQuantity - ISNULL(ClosedParties.Count, 0))
	|		ELSE DD.EstimatedQuantity - ISNULL(ClosedParties.Count, 0)
	|	END AS NUMBER(23,10))                                              AS Denominator,
	|	0                                                                    AS ShareOfOutput,
	|	DD.EstimatedQuantity - ISNULL(ClosedParties.Count, 0)     AS Count,
	|	DD.SideProduct                                                   AS SideProduct,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS OffBalanceCost,
	|	0 AS LocalCost,
	|	0 AS OffBalanceCostLocal,
	|	0 AS CostMan,
	|	UNDEFINED                                                         AS BusinessOperation,
	|	UNDEFINED                                                         AS CorItemsLocationAttributes,
	|	UNDEFINED                                                         AS CorAccountingSection,
	|	UNDEFINED                                                         AS CorInventoryOwnerAttribute,
	|	UNDEFINED                                                         AS ExpenseItemOfWriteOff,
	|	UNDEFINED                                                         AS DimensionOfExpenses,
	|	UNDEFINED                                                         AS AssetAndLiabilityItem,
	|	UNDEFINED                                                         AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                                         AS CorLot,
	|	UNDEFINED                                                         AS LotVendorAttributesCorr,
	|	UNDEFINED                                                         AS CorVATActivityTypes,
	|	UNDEFINED                                                         AS CorControllingAttributes,
	|	UNDEFINED                                                         AS DocumentVATActivityType,
	|	UNDEFINED                                                         AS RowID,
	|	UNDEFINED                                                         AS DocumentSource,
	|	UNDEFINED                                                         AS BusinessTransactionSetting,
	|	""""                                                                 AS FinRecordID
	|FROM
	|	Estimated AS DD
	|	LEFT JOIN ClosedParties AS ClosedParties
	|		ON ClosedParties.ProductionLot = DD.ProductionLot
	|		AND ClosedParties.ItemsLocationAttributes.Products = DD.Products
	|		AND ClosedParties.ItemsLocationAttributes.CHARACTERISTIC = DD.Characteristic
	|		AND ClosedParties.ItemsLocationAttributes.Department = DD.Department
	|		AND ClosedParties.ItemsLocationAttributes.Purpose = DD.Purpose
	|		AND ClosedParties.ItemsLocationAttributes.ProductCostElement = DD.ProductCostElement
	|";
	
EndFunction

Function TextDistributionOfProductsForOutputByProduct() // uses Products
	
	Return "
	|SELECT
	|	""TextDistributionOfProductsForOutputByProduct""                AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.CostAllocationToProductionLots)            AS EntryType,
	|	FALSE                                                                 AS CalculationIsCompleted,
	|	UNDEFINED                                                         AS AccountingSection,
	|	VALUE(AccumulationRecordType.Expense)                               AS RecordType,
	|	DD.ProductionDate                                                  AS Period,
	|	ISNULL(CalculationLoggers.Ref, DD.ReleaseParty)               AS Recorder,
	|	UNDEFINED                                                         AS ItemsLocationAttributes,
	|	UNDEFINED                                                         AS Products,
	|	UNDEFINED                                                         AS Characteristic,
	|	UNDEFINED                                                         AS Department,
	|	UNDEFINED                                                         AS Purpose,
	|	UNDEFINED                                                         AS ProductCostElement,
	|	UNDEFINED                                                         AS InventoryOwnerAttribute,
	|	DD.Organization                                                       AS Organization,
	|	DD.ProductionLot                                                AS Lot,
	|	UNDEFINED                                                         AS LotVendorAttributes,
	|	UNDEFINED                                                         AS FinancialAccountingDimension,
	|	UNDEFINED                                                         AS VATActivityType,
	|	DD.ShareOfMonthName                                            AS Denominator,
	|	0                                                                    AS ShareOfOutput,
	|	0                                                                    AS Count,
	|	FALSE                                                                 AS SideProduct,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS OffBalanceCost,
	|	0 AS LocalCost,
	|	0 AS OffBalanceCostLocal,
	|	0 AS CostMan,
	|	DD.BusinessOperation                                             AS BusinessOperation,
	|	DD.ItemsLocationAttributes                                        AS CorItemsLocationAttributes,
	|	DD.AccountingSection                                                       AS CorAccountingSection,
	|	DD.InventoryOwnerAttribute                                                        AS CorInventoryOwnerAttribute,
	|	UNDEFINED                                                         AS ExpenseItemOfWriteOff,
	|	UNDEFINED                                                         AS DimensionOfExpenses,
	|	UNDEFINED                                                         AS AssetAndLiabilityItem,
	|	UNDEFINED                                                         AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN NOT RegisterRecords.Lot IS NULL
	|			THEN RegisterRecords.Lot
	|		WHEN &BatchAccountingVersion22
	|				AND DD.Organization IN (&SFIFOOrganizationsSliding)
	|			THEN DD.ReleaseParty
	|		ELSE UNDEFINED
	|	END                                                                AS CorLot,
	|	CASE
	|		WHEN NOT RegisterRecords.LotVendorAttributes IS NULL
	|			THEN RegisterRecords.LotVendorAttributes
	|		WHEN &BatchAccountingVersion22
	|				AND DD.Organization IN (&SFIFOOrganizationsSliding)
	|			THEN DD.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END                                                                AS LotVendorAttributesCorr,
	|	CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE ISNULL(RegisterRecords.VATActivityType, DD.VATActivityType)
	|	END AS CorVATActivityTypes,
	|	CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|			THEN UNDEFINED
	|		ELSE ISNULL(RegisterRecords.FinancialAccountingDimension, DD.FinancialAccountingDimension)
	|	END AS CorControllingAttributes,
	|	ISNULL(RegisterRecords.VATActivityType, DD.VATActivityType)         AS DocumentVATActivityType,
	|	DD.RowID                                               AS RowID,
	|	ISNULL(RegisterRecords.Recorder, DD.ReleaseParty)                     AS DocumentSource,
	|	SettingUpBusinessTransaction.Ref                                          AS BusinessTransactionSetting,
	|	MAX(DD.FinRecordID) AS FinRecordID
	|FROM
	|	ManufacturedProduct AS DD
	|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
	|		ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
	|		INNER JOIN Catalog.ProductionLots AS ProductionPartyDetails
	|		ON DD.ProductionLot = ProductionPartyDetails.Ref
	|
	|		LEFT JOIN AccumulationRegister.InventoryCost AS RegisterRecords
	|		ON TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|			AND DD.ReleaseParty = RegisterRecords.Recorder
	|			AND DD.RowID = RegisterRecords.RowID
	|			AND DD.RowID <> """"
	|			AND RegisterRecords.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|			AND NOT RegisterRecords.LotCalculation
	|			AND NOT RegisterRecords.CalculationOfCost
	// exclusion of work movements for the giver
	|		AND RegisterRecords.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|		AND NOT RegisterRecords.ReversingEntry
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS SettingUpBusinessTransaction
	|		ON SettingUpBusinessTransaction.BusinessOperation = DD.BusinessOperation
	|
	|		LEFT JOIN TTCostCalculationRecorders AS CalculationLoggers
	|		ON CalculationLoggers.Organization = DD.Organization
	|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|WHERE
	|	DD.ShareOfMonthName > 0
	|	
	|GROUP BY
	|	DD.ProductionDate,
	|	ISNULL(CalculationLoggers.Ref, DD.ReleaseParty),
	|	DD.Organization,
	|	DD.ProductionLot,
	|	DD.ShareOfMonthName,
	|	DD.BusinessOperation,
	|	DD.ItemsLocationAttributes,
	|	DD.AccountingSection,
	|	DD.InventoryOwnerAttribute,
	|	CASE
	|		WHEN NOT RegisterRecords.Lot IS NULL
	|			THEN RegisterRecords.Lot
	|		WHEN &BatchAccountingVersion22
	|				AND DD.Organization IN (&SFIFOOrganizationsSliding)
	|			THEN DD.ReleaseParty
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN NOT RegisterRecords.LotVendorAttributes IS NULL
	|			THEN RegisterRecords.LotVendorAttributes
	|		WHEN &BatchAccountingVersion22
	|				AND DD.Organization IN (&SFIFOOrganizationsSliding)
	|			THEN DD.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		ELSE ISNULL(RegisterRecords.VATActivityType, DD.VATActivityType)
	|	END, // CorVATActivityTypes
	|	CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|			THEN UNDEFINED
	|		ELSE ISNULL(RegisterRecords.FinancialAccountingDimension, DD.FinancialAccountingDimension)
	|	END, // CorControllingAttributes
	|	ISNULL(RegisterRecords.VATActivityType, DD.VATActivityType), // DocumentVATActivityType
	|	DD.RowID,
	|	ISNULL(RegisterRecords.Recorder, DD.ReleaseParty), // DocumentSource
	|	SettingUpBusinessTransaction.Ref,
	|	CASE
	|		WHEN CalculationLoggers.Ref IS NULL
	|		THEN DD.FinRecordID
	|		ELSE UNDEFINED
	|	END
	|";
	
EndFunction

// Filling out the payment batch

Procedure FillInEstimatedBatchDistributionOfProductsForRelease(CalculationParameters, SettlementBatch, Expense, Receipt)
	
	FillPropertyValues(SettlementBatch, Expense);
	
	If Expense.EntryType = Enums.LotRecordTypes.Estimated Then
		
		If Receipt.Denominator = 0 Then
			Return;
		EndIf;
		
		WriteOffDenominator = Min(Expense.Denominator, Receipt.Denominator);
		
		If Expense.Count < 0 Then
			NumberOfDebits = Max(Expense.Count, Receipt.Count);
		Else
			NumberOfDebits = Min(Expense.Count, Receipt.Count);
		EndIf;
		
		// we fill in the indicators of the settlement batch
		SettlementBatch.Count = NumberOfDebits;
		
		// adjusting the calculation base in the expense
		Receipt.Count = Receipt.Count - SettlementBatch.Count;
		Expense.Count = Expense.Count - SettlementBatch.Count;
		
		Receipt.Denominator = Receipt.Denominator - WriteOffDenominator;
		
		SettlementBatch.Denominator = Receipt.ShareOfOutput;
		
		FillPropertyValues(SettlementBatch, Receipt, "CalculationIsCompleted,InventoryOwnerAttribute,LotVendorAttributes,
			|FinancialAccountingDimension,VATActivityType,AccountingSection,ItemsLocationAttributes,Organization");
		
	Else
		
		If Receipt.Denominator = 0 Then
			Return;
		EndIf;
		
		// the calculated batch is filled with the largest total deductible
		WriteOffDenominator = Min(Expense.Denominator, Receipt.Denominator);
		
		// we fill in the indicators of the settlement batch
		If Receipt.Denominator - WriteOffDenominator = 0 Then
			SettlementBatch.Count = Receipt.Count;
		Else
			SettlementBatch.Count = Round(WriteOffDenominator * Receipt.Count / Receipt.Denominator, 3);
		EndIf;
		
		// adjusting the calculation bases
		Receipt.Denominator = Receipt.Denominator - WriteOffDenominator;
		Receipt.Count  = Receipt.Count - SettlementBatch.Count;
		
		FillPropertyValues(SettlementBatch, Receipt, "CalculationIsCompleted,ProductCostElement,InventoryOwnerAttribute,LotVendorAttributes,
			|FinancialAccountingDimension,VATActivityType,ItemsLocationAttributes,AccountingSection,Organization");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region StageProcedures_Contextual

// Used for all calls to fill in the billing batch.
//
Procedure FillInSettlementBatch(CalculationParameters, Context, SettlementBatch, Expense, Receipt, BatchIsFull) Export
	
	// It is called from the procedure of calculating the value of the individual rhythms.Fill out the Accounting Party()
	
	If Context = "DistributionOfProductsForProduction" Then
		// Stage 4
		FillInEstimatedBatchOfDistributionOfProductsForProduction(CalculationParameters, SettlementBatch, Expense, Receipt);
		BatchIsFull = True;
	ElsIf Context = "DistributionOfProductsForRelease" Then
		// Stage 5
		FillInEstimatedBatchDistributionOfProductsForRelease(CalculationParameters, SettlementBatch, Expense, Receipt);
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
	
	StageList.Add("DistributionOfProductsForProduction");
	StageList.Add("DistributionOfProductsForRelease");
	
EndProcedure

Procedure RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText) Export
	
	If StageName_ = "DistributionOfProductsForProduction" Then
		QueryText = RequestTextForDistributionOfProductsForProduction(CalculationParameters);
		
	ElsIf StageName_ = "DistributionOfProductsForRelease" Then
		QueryText = RequestTextForProductAllocation();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion