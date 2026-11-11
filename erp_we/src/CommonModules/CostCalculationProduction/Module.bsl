
// Procedures and functions of common modules are called:
//	- Calculation of the cost of the individual rhythms.

#Region Public

#Region Initialize

// Before starting decryption, it fills in all the necessary parameters and initializes all data structures used by the calculation algorithm.
//
// Parameters:
//	Date - Date - period of the distribution document
//	CompanyArray - Array - Companies
//	Recorder - DocumentRef - expense allocation document
//
// Returns:
//	Structure - parameters used in the calculation.
//
Function InitializeDistributionDecryptionParameters(Date, CompanyArray, Recorder) Export
	
	CalculationParameters = Undefined;
	DebugParameters = Undefined;
	
	StartupParameters = New Structure(
		"Date, CompanyArray, DecodingDistribution",
		Date, CompanyArray, True);
	
	CostCalculationAppliedAlgorithms.InitializeDebuggingOptions(DebugParameters, StartupParameters);
	CostCalculationAppliedAlgorithms.InitializeBatchCalculationParameters(StartupParameters, CalculationParameters, DebugParameters);
	
	CalculationParameters.Insert("Recorder", Recorder);
	
	Return CalculationParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region StepProcedures_1_2_3_4_5

// W Stages, Participantstatus, Participantstype, Raspredelennymi,
// videoportraits, unproductive, vidalita, Products of Drivepack.
//
// Returns:
// 	String - Query text
Function ProductionBatchText() Export
	
	QueryText = "
	// Selects data for the organization specified in the Attributes of the document
	// when it is not internal processing
	|SELECT
	|	Attributes.Ref AS Stage,
	|	Attributes.Organization AS Organization,
	|	Attributes.ProductionLot AS ProductionLot,
	|	Attributes.ProductionProcessType
	|INTO StagesOfCurPeriod
	|FROM
	|	Document.ProductionStage2_2 AS Attributes
	|WHERE
	|	NOT Attributes.InternalSubcontracting
	|	AND Attributes.Organization IN(&CompanyArray)
	|	AND NOT Attributes.ProductionByThirdParty
	|	AND Attributes.Posted
	|	AND Attributes.ActualStageStart <= &EndOfPeriod
	|	AND (Attributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
	|		OR Attributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|			AND Attributes.ActualStageEnd >= &BeginOfPeriod)
	|
	|UNION ALL
	|
	// Selects data for the giver's organization if it is internal processing
	|SELECT
	|	Attributes.Ref AS Stage,
	|	Attributes.MaterialProviderCompany AS Organization,
	|	Attributes.ProductionLot AS ProductionLot,
	|	Attributes.ProductionProcessType
	|FROM
	|	Document.ProductionStage2_2 AS Attributes
	|WHERE
	|	Attributes.InternalSubcontracting
	|	AND Attributes.MaterialProviderCompany IN (&CompanyArray)
	|	AND NOT Attributes.ProductionByThirdParty
	|	AND Attributes.Posted
	|	AND Attributes.ActualStageStart <= &EndOfPeriod
	|	AND (Attributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
	|		OR Attributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|			AND Attributes.ActualStageEnd >= &BeginOfPeriod)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PartyDocuments.Organization               AS Organization,
	|	PartyDocuments.ProductionLot        AS ProductionLot,
	|	MAX(PartyDocuments.Stage)            AS Stage,
	|	PartyDocuments.DocumentLots            AS DocumentLots,
	|	PartyDocuments.CostGroupNumber         AS CostGroupNumber,
	|	PartyDocuments.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	PartyDocuments.Products              AS Products,
	|	PartyDocuments.Purpose                AS Purpose,
	|	PartyDocuments.VATActivityType        AS VATActivityType,
	|	PartyDocuments.LineOfBusiness   AS LineOfBusiness,
	// The flag indicates the ability to allocate expenses, including fixed ones, for the production of products.
	// If the production of products is not reflected in the period of attribution of expenses and is not planned in the future,
	// then such expenses will be written off to the item "Storno of production expenses".
	|	MAX(PartyDocuments.CostAllocationForIssue) AS CostAllocationForIssue
	|INTO DocumentsOfProductionBatchesWithoutOrder
	|FROM
	|	(
	// Production Lot references for which the issue was issued in the current period
	|	SELECT
	|		PartyDocuments.Organization                       AS Organization,
	|		CatProductionLots.Ref                      AS ProductionLot,
	|		PartyDocuments.Ref                            AS Stage,
	|		CatProductionLots.Document                    AS DocumentLots,
	|		CatProductionLots.Code                         AS CostGroupNumber,
	|		CASE
	|			WHEN NOT CatProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CatProductionLots.ProductsGroup
	|			ELSE UNDEFINED
	|		END                                             AS FinancialAccountingDimension,
	|		CatProductionLots.MainProductProducts AS Products,
	|		CatProductionLots.Purpose                  AS Purpose,
	|		CatProductionLots.VATActivityType          AS VATActivityType,
	|		CatProductionLots.LineOfBusiness     AS LineOfBusiness,
	|		TRUE                                            AS CostAllocationForIssue
	|	FROM
	|		(SELECT
	|			DocumentAttributes.Ref            AS Ref,
	|			DocumentAttributes.Organization       AS Organization,
	|			CASE
	|				WHEN DocumentAttributes.Patch
	|					AND DocumentAttributes.CorrectionSavesProductionLots
	|					THEN DocumentAttributes.CorrectedDocument
	|				ELSE DocumentAttributes.Ref
	|			END                                AS DocumentProductionLots,
	|			TableOfGoods.CostGroupNumber     AS CostGroupNumber
	|		FROM
	|			Document.BackflushProduction.ManufacturedProducts AS TableOfGoods
	|		
	|			INNER JOIN Document.BackflushProduction AS DocumentAttributes
	|			ON DocumentAttributes.Ref = TableOfGoods.Ref
	|		
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|			LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
	|			ON CorrectedDocuments_.ReversedDocument = DocumentAttributes.Ref
	|		
	|		WHERE
	|			DocumentAttributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND DocumentAttributes.Posted
	|			AND DocumentAttributes.Organization IN (&CompanyArray)
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|			AND CorrectedDocuments_.ReversedDocument IS NULL
	|			AND NOT TableOfGoods.InternalSubcontracting
	|		
	|		UNION ALL
	|		
	// We add a release on the side of the giver during internal processing.
	|		SELECT
	|			DocumentAttributes.Ref            AS Ref,
	|			TableOfGoods.MaterialProviderCompany    AS Organization,
	|			CASE
	|				WHEN DocumentAttributes.Patch
	|					AND DocumentAttributes.CorrectionSavesProductionLots
	|					THEN DocumentAttributes.CorrectedDocument
	|				ELSE DocumentAttributes.Ref
	|			END                                AS DocumentProductionLots,
	|			TableOfGoods.CostGroupNumber     AS CostGroupNumber
	|		FROM
	|			Document.BackflushProduction.ManufacturedProducts AS TableOfGoods
	|		
	|			INNER JOIN Document.BackflushProduction AS DocumentAttributes
	|			ON DocumentAttributes.Ref = TableOfGoods.Ref
	|		
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|			LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
	|			ON CorrectedDocuments_.ReversedDocument = DocumentAttributes.Ref
	|		
	|		WHERE
	|			DocumentAttributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND DocumentAttributes.Posted
	|			AND TableOfGoods.InternalSubcontracting
	|			AND TableOfGoods.MaterialProviderCompany IN (&CompanyArray)
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|			AND CorrectedDocuments_.ReversedDocument IS NULL
	|		) AS PartyDocuments
	|		
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = PartyDocuments.DocumentProductionLots
	|		AND CatProductionLots.Code = PartyDocuments.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|
	|	UNION ALL
	|
	// We add Lot references of production, the issue of which is issued by reports to the giver between organizations
	|	SELECT
	|		DocumentAttributes.Organization                    AS Organization,
	|		CatProductionLots.Ref                      AS ProductionLot,
	|		DocumentAttributes.Ref                         AS Stage,
	|		CatProductionLots.Document                    AS DocumentLots,
	|		CatProductionLots.Code                         AS CostGroupNumber,
	|		CASE
	|			WHEN NOT CatProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CatProductionLots.ProductsGroup
	|			ELSE UNDEFINED
	|		END                                             AS FinancialAccountingDimension,
	|		CatProductionLots.MainProductProducts AS Products,
	|		CatProductionLots.Purpose                  AS Purpose,
	|		CatProductionLots.VATActivityType          AS VATActivityType,
	|		CatProductionLots.LineOfBusiness     AS LineOfBusiness,
	|		TRUE                                            AS CostAllocationForIssue
	|	FROM
	|		Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS TableOfGoods
	|
	|		INNER JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentAttributes
	|		ON DocumentAttributes.Ref = TableOfGoods.Ref
	|
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = TableOfGoods.ProductionLot
	|		AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|		LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
	|		ON CorrectedDocuments_.ReversedDocument = TableOfGoods.Ref
	|	WHERE
	|		DocumentAttributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND DocumentAttributes.Organization IN(&CompanyArray)
	|		AND DocumentAttributes.Posted
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|		AND CorrectedDocuments_.ReversedDocument IS NULL
	|
	|	UNION ALL
	|
	// We add Lot references of production on the giver, the issue of which is issued by reports to the giver between organizations.
	// For such Lot references, the giver may not have a release document.
	|	SELECT
	|		DocumentAttributes.MaterialProvider                        AS Organization,
	|		CatProductionLots.Ref                      AS ProductionLot,
	|		UNDEFINED                                      AS Stage,
	|		CatProductionLots.Document                    AS DocumentLots,
	|		CatProductionLots.Code                         AS CostGroupNumber,
	|		CASE
	|			WHEN NOT CatProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CatProductionLots.ProductsGroup
	|			ELSE UNDEFINED
	|		END                                             AS FinancialAccountingDimension,
	|		CatProductionLots.MainProductProducts AS Products,
	|		CatProductionLots.Purpose                  AS Purpose,
	|		CatProductionLots.VATActivityType          AS VATActivityType,
	|		CatProductionLots.LineOfBusiness     AS LineOfBusiness,
	|		FALSE                                              AS CostAllocationForIssue
	|	FROM
	|		Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS TableOfGoods
	|
	|		INNER JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentAttributes
	|		ON DocumentAttributes.Ref = TableOfGoods.Ref
	|
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = TableOfGoods.ProductionLot
	|		AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|		LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
	|		ON CorrectedDocuments_.ReversedDocument = TableOfGoods.Ref
	|	WHERE
	|		DocumentAttributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND DocumentAttributes.Organization IN(&CompanyArray)
	|		AND DocumentAttributes.Posted
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|		AND CorrectedDocuments_.ReversedDocument IS NULL
	|	
	|	UNION ALL
	|	
	// We add Lot references of production, for which there was a correction of Receipts into the boiler.
	|	SELECT
	|		PartyDocuments.Organization                       AS Organization,
	|		CatProductionLots.Ref                      AS ProductionLot,
	|		UNDEFINED                                      AS Stage,
	|		CatProductionLots.Document                    AS DocumentLots,
	|		CatProductionLots.Code                         AS CostGroupNumber,
	|		CASE
	|			WHEN NOT CatProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CatProductionLots.ProductsGroup
	|			ELSE UNDEFINED
	|		END                                             AS FinancialAccountingDimension,
	|		CatProductionLots.MainProductProducts AS Products,
	|		CatProductionLots.Purpose                  AS Purpose,
	|		CatProductionLots.VATActivityType          AS VATActivityType,
	|		CatProductionLots.LineOfBusiness     AS LineOfBusiness,
	|		FALSE                                              AS CostAllocationForIssue
	|	FROM
	|		(
	// Reversed nomenclature expenses. The Registered Records of the correction document.
	|		SELECT
	|			StornoOfRegisteredRecords.Organization AS Organization,
	|			StornoOfRegisteredRecords.Lot      AS ProductionLot
	|		FROM
	|			CorrectedDocuments_ AS CorrectedDocuments_
	|			
	|			INNER JOIN AccumulationRegister.InventoryCost AS StornoOfRegisteredRecords
	|			ON StornoOfRegisteredRecords.Recorder = CorrectedDocuments_.Recorder
	|			AND VALUETYPE(StornoOfRegisteredRecords.Lot) = TYPE(Catalog.ProductionLots)
	|			AND StornoOfRegisteredRecords.ReversingEntry
	|		WHERE
	|			NOT StornoOfRegisteredRecords.Count = 0
	|		
	|		UNION ALL
	|		
	// Reversed nomenclature expenses. The Registered Records of the document being corrected.
	|		SELECT
	|			StornoOfRegisteredRecords.Organization AS Organization,
	|			StornoOfRegisteredRecords.Lot      AS ProductionLot
	|		FROM
	|			CorrectedDocuments_ AS CorrectedDocuments_
	|			
	|			INNER JOIN AccumulationRegister.InventoryCost AS StornoOfRegisteredRecords
	|			ON StornoOfRegisteredRecords.Recorder = CorrectedDocuments_.ReversedDocument
	|			AND VALUETYPE(StornoOfRegisteredRecords.Lot) = TYPE(Catalog.ProductionLots)
	|		WHERE
	|			NOT StornoOfRegisteredRecords.Count = 0
	|		
	|		UNION ALL
	|		
	// Reversed item-by-item expenses. The Registered Records of the correction document.
	|		SELECT
	|			StornoOfRegisteredRecords.Organization        AS Organization,
	|			StornoOfRegisteredRecords.ProductionLot AS ProductionLot
	|		FROM
	|			CorrectedDocuments_ AS CorrectedDocuments_
	|			
	|			INNER JOIN AccumulationRegister.OtherWorkInProgressExpenses AS StornoOfRegisteredRecords
	|			ON StornoOfRegisteredRecords.Recorder = CorrectedDocuments_.Recorder
	|			AND VALUETYPE(StornoOfRegisteredRecords.ProductionLot) = TYPE(Catalog.ProductionLots)
	|			AND StornoOfRegisteredRecords.ReversingEntry
	|		WHERE
	|			NOT StornoOfRegisteredRecords.Cost = 0
	|			OR NOT StornoOfRegisteredRecords.CostExcludingVAT = 0
	|			OR NOT StornoOfRegisteredRecords.LocalCost = 0
	|			OR NOT StornoOfRegisteredRecords.PermanentDifference = 0
	|			OR NOT StornoOfRegisteredRecords.CostTD = 0
	|			OR NOT StornoOfRegisteredRecords.CostMan = 0
	|			OR NOT StornoOfRegisteredRecords.CostOfPersonalIncomeTax = 0
	|		
	|		UNION ALL
	|		
	// Reversed item-by-item expenses. The Registered Records of the document being corrected.
	|		SELECT
	|			StornoOfRegisteredRecords.Organization        AS Organization,
	|			StornoOfRegisteredRecords.ProductionLot AS ProductionLot
	|		FROM
	|			CorrectedDocuments_ AS CorrectedDocuments_
	|			
	|			INNER JOIN AccumulationRegister.OtherWorkInProgressExpenses AS StornoOfRegisteredRecords
	|			ON StornoOfRegisteredRecords.Recorder = CorrectedDocuments_.ReversedDocument
	|			AND VALUETYPE(StornoOfRegisteredRecords.ProductionLot) = TYPE(Catalog.ProductionLots)
	|		WHERE
	|			NOT StornoOfRegisteredRecords.Cost = 0
	|			OR NOT StornoOfRegisteredRecords.CostExcludingVAT = 0
	|			OR NOT StornoOfRegisteredRecords.LocalCost = 0
	|			OR NOT StornoOfRegisteredRecords.PermanentDifference = 0
	|			OR NOT StornoOfRegisteredRecords.CostTD = 0
	|			OR NOT StornoOfRegisteredRecords.CostMan = 0
	|			OR NOT StornoOfRegisteredRecords.CostOfPersonalIncomeTax = 0
	|		
	|		UNION ALL
	|		
	// Reversed labor costs. The Registered Records of the correction document.
	|		SELECT
	|			StornoOfRegisteredRecords.Organization        AS Organization,
	|			StornoOfRegisteredRecords.ProductionLot AS ProductionLot
	|		FROM
	|			CorrectedDocuments_ AS CorrectedDocuments_
	|			
	|			INNER JOIN AccumulationRegister.WIPLaborCosts AS StornoOfRegisteredRecords
	|			ON StornoOfRegisteredRecords.Recorder = CorrectedDocuments_.Recorder
	|			AND VALUETYPE(StornoOfRegisteredRecords.ProductionLot) = TYPE(Catalog.ProductionLots)
	|			AND StornoOfRegisteredRecords.ReversingEntry
	|		WHERE
	|			NOT StornoOfRegisteredRecords.Count = 0
	|				OR NOT StornoOfRegisteredRecords.StandardCost = 0
	|				OR NOT StornoOfRegisteredRecords.Cost = 0
	|				OR NOT StornoOfRegisteredRecords.LocalCost = 0
	|				OR NOT StornoOfRegisteredRecords.PermanentDifference = 0
	|				OR NOT StornoOfRegisteredRecords.CostTD = 0
	|				OR NOT StornoOfRegisteredRecords.CostOfPersonalIncomeTax = 0
	|		
	|		UNION ALL
	|		
	// Reversed labor costs. The Registered Records of the document being corrected.
	|		SELECT
	|			StornoOfRegisteredRecords.Organization        AS Organization,
	|			StornoOfRegisteredRecords.ProductionLot AS ProductionLot
	|		FROM
	|			CorrectedDocuments_ AS CorrectedDocuments_
	|			
	|			INNER JOIN AccumulationRegister.WIPLaborCosts AS StornoOfRegisteredRecords
	|			ON StornoOfRegisteredRecords.Recorder = CorrectedDocuments_.ReversedDocument
	|			AND VALUETYPE(StornoOfRegisteredRecords.ProductionLot) = TYPE(Catalog.ProductionLots)
	|		WHERE
	|			NOT StornoOfRegisteredRecords.Count = 0
	|				OR NOT StornoOfRegisteredRecords.StandardCost = 0
	|				OR NOT StornoOfRegisteredRecords.Cost = 0
	|				OR NOT StornoOfRegisteredRecords.LocalCost = 0
	|				OR NOT StornoOfRegisteredRecords.PermanentDifference = 0
	|				OR NOT StornoOfRegisteredRecords.CostTD = 0
	|				OR NOT StornoOfRegisteredRecords.CostOfPersonalIncomeTax = 0
	|		) AS PartyDocuments
	|		
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = PartyDocuments.ProductionLot
	|		AND VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|		AND NOT CatProductionLots.DeletionMark
	|	) AS PartyDocuments
	|
	|GROUP BY
	|	PartyDocuments.Organization,
	|	PartyDocuments.ProductionLot,
	|	PartyDocuments.DocumentLots,
	|	PartyDocuments.CostGroupNumber,
	|	PartyDocuments.FinancialAccountingDimension,
	|	PartyDocuments.Products,
	|	PartyDocuments.Purpose,
	|	PartyDocuments.VATActivityType,
	|	PartyDocuments.LineOfBusiness
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// The table contains all Lot references of production, including corrected Lot references of backflushed production.
	// For corrected Lot references backflushed production for which there is no release and no planned release,
	// the Stage is stored Indefinitely in the field.
	|SELECT
	|	DD.ProductionLot			AS ProductionLot,
	|	DD.DocumentLots				AS DocumentLots,
	|	DD.CostGroupNumber			AS CostGroupNumber,
	|	DD.FinancialAccountingDimension	AS FinancialAccountingDimension,
	|	DD.Stage							AS Stage,
	|	DD.Organization					AS Organization,
	|	DD.Products					AS Products,
	|	DD.Purpose					AS Purpose,
	|	DD.VATActivityType			AS VATActivityType,
	|	DD.LineOfBusiness		AS LineOfBusiness,
	|	DD.CostAllocationForIssue	AS CostAllocationForIssue
	|INTO ProductionBatchesByStages
	|FROM
	|	(
	// Backflushed production 2.2.
	|	SELECT
	|		DocumentsOfProductionBatchesWithoutOrder.ProductionLot          AS ProductionLot,
	|		DocumentsOfProductionBatchesWithoutOrder.DocumentLots              AS DocumentLots,
	|		DocumentsOfProductionBatchesWithoutOrder.CostGroupNumber           AS CostGroupNumber,
	|		DocumentsOfProductionBatchesWithoutOrder.FinancialAccountingDimension   AS FinancialAccountingDimension,
	|		DocumentsOfProductionBatchesWithoutOrder.Stage                        AS Stage,
	|		DocumentsOfProductionBatchesWithoutOrder.Organization                 AS Organization,
	|		DocumentsOfProductionBatchesWithoutOrder.Products                AS Products,
	|		DocumentsOfProductionBatchesWithoutOrder.Purpose                  AS Purpose,
	|		DocumentsOfProductionBatchesWithoutOrder.VATActivityType          AS VATActivityType,
	|		DocumentsOfProductionBatchesWithoutOrder.LineOfBusiness     AS LineOfBusiness,
	|		DocumentsOfProductionBatchesWithoutOrder.CostAllocationForIssue AS CostAllocationForIssue
	|	FROM
	|		DocumentsOfProductionBatchesWithoutOrder AS DocumentsOfProductionBatchesWithoutOrder
	|
	|UNION ALL
	|
	// Production without bill of materials.
	|	SELECT
	|		ActiveBatchesWithoutSpecifications.ProductionLot         AS ProductionLot,
	|		PPDetails.Document                                     AS DocumentLots,
	|		PPDetails.Code                                          AS CostGroupNumber,
	|		CASE
	|			WHEN NOT PPDetails.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN PPDetails.ProductsGroup
	|			ELSE UNDEFINED
	|		END                                                    AS FinancialAccountingDimension,
	|		ISNULL(Stages.Stage,
	|			VALUE(Document.ProductionStage2_2.EmptyRef)) AS Stage,
	|		ISNULL(Stages.Organization,
	|			ProductionOrder.Organization)                     AS Organization,
	|		PPDetails.MainProductProducts                  AS Products,
	|		PPDetails.Purpose                                   AS Purpose,
	|		PPDetails.VATActivityType                           AS VATActivityType,
	|		ISNULL(PPDetails.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|		TRUE                                                   AS CostAllocationForIssue
	|	FROM
	|		ActiveBatchesWithoutSpecifications AS ActiveBatchesWithoutSpecifications
	|		
	|		INNER JOIN Document.ProductionOrder2_2 AS ProductionOrder
	|		ON ActiveBatchesWithoutSpecifications.ProductionLot = ProductionOrder.ProductionLot
	|		
	|		INNER JOIN Catalog.ProductionLots AS PPDetails
	|		ON PPDetails.Ref = ActiveBatchesWithoutSpecifications.ProductionLot
	|		
	|		LEFT JOIN StagesOfCurPeriod AS Stages
	|		ON ActiveBatchesWithoutSpecifications.ProductionLot = Stages.ProductionLot
	|		AND Stages.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
	|	
	|	UNION ALL
	|	
	// production by order 2.2
	|	SELECT
	|		CatProductionLots.Ref				AS ProductionLot,
	|		CatProductionLots.Document				AS DocumentLots,
	|		CatProductionLots.Code					AS CostGroupNumber,
	|		CASE
	|			WHEN NOT CatProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CatProductionLots.ProductsGroup
	|			ELSE UNDEFINED
	|		END										AS FinancialAccountingDimension,
	|		StagesOfCurPeriod.Stage					AS Stage,
	|		StagesOfCurPeriod.Organization			AS Organization,
	|		CatProductionLots.MainProductProducts AS Products,
	|		CatProductionLots.Purpose			AS Purpose,
	|		CatProductionLots.VATActivityType	AS VATActivityType,
	|		ISNULL(CatProductionLots.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))	AS LineOfBusiness,
	|		TRUE                                      AS CostAllocationForIssue
	|	FROM
	|		StagesOfCurPeriod AS StagesOfCurPeriod
	|
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = StagesOfCurPeriod.ProductionLot
	|	WHERE
	|		NOT StagesOfCurPeriod.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
	|	
	|	UNION ALL
	|	
	// processors' reports 2.5 without stages
	|	SELECT
	|		CatProductionLots.Ref				AS ProductionLot,
	|		CatProductionLots.Document				AS DocumentLots,
	|		CatProductionLots.Code					AS CostGroupNumber,
	|		CASE
	|			WHEN NOT CatProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CatProductionLots.ProductsGroup
	|			ELSE UNDEFINED
	|		END										AS FinancialAccountingDimension,
	|		ReportDetails_.Ref						AS Stage,
	|		ReportDetails_.Organization					AS Organization,
	|		CatProductionLots.MainProductProducts AS Products,
	|		CatProductionLots.Purpose			AS Purpose,
	|		CatProductionLots.VATActivityType	AS VATActivityType,
	|		ISNULL(CatProductionLots.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|		TRUE                                      AS CostAllocationForIssue
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS TableOfGoods
	|
	|			INNER JOIN Document.SubcontractorReport2_5 AS ReportDetails_
	|			ON ReportDetails_.Ref = TableOfGoods.Ref
	|
	|			INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|			ON CatProductionLots.Document = TableOfGoods.Ref
	|				AND CatProductionLots.Code = TableOfGoods.CostGroupNumber
	|				AND NOT CatProductionLots.DeletionMark
	|
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|		LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
	|			ON CorrectedDocuments_.ReversedDocument = TableOfGoods.Ref
	|
	|	WHERE
	|		ReportDetails_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ReportDetails_.Organization IN(&CompanyArray)
	|		AND ReportDetails_.Posted
	|		AND NOT ReportDetails_.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|		AND CorrectedDocuments_.ReversedDocument IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CatProductionLots.Ref				AS ProductionLot,
	|		CatProductionLots.Document				AS DocumentLots,
	|		CatProductionLots.Code					AS CostGroupNumber,
	|		CASE
	|			WHEN NOT CatProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CatProductionLots.ProductsGroup
	|			ELSE UNDEFINED
	|		END										AS FinancialAccountingDimension,
	|		StageDetails.Ref						AS Stage,
	|		ReportDetails_.Organization					AS Organization,
	|		CatProductionLots.MainProductProducts AS Products,
	|		CatProductionLots.Purpose			AS Purpose,
	|		CatProductionLots.VATActivityType	AS VATActivityType,
	|		ISNULL(CatProductionLots.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|		TRUE                                      AS CostAllocationForIssue
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS TableOfGoods
	|
	|			INNER JOIN Document.SubcontractorReport2_5 AS ReportDetails_
	|			ON ReportDetails_.Ref = TableOfGoods.Ref
	|
	|			INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|			ON StageDetails.Ref = TableOfGoods.ProductionStage
	|
	|			INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|			ON CatProductionLots.Ref = StageDetails.ProductionLot
	|
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|		LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
	|		ON CorrectedDocuments_.ReversedDocument = TableOfGoods.Ref
	|	WHERE
	|		ReportDetails_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND ReportDetails_.Organization IN(&CompanyArray)
	|		AND ReportDetails_.Posted
	|		AND ReportDetails_.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|		AND CorrectedDocuments_.ReversedDocument IS NULL
	|
	|	UNION ALL
	|
	// Report to giver between organizations by stages
	|	SELECT
	|		CatProductionLots.Ref				AS ProductionLot,
	|		CatProductionLots.Document				AS DocumentLots,
	|		CatProductionLots.Code					AS CostGroupNumber,
	|		CASE
	|			WHEN NOT CatProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CatProductionLots.ProductsGroup
	|			ELSE UNDEFINED
	|		END										AS FinancialAccountingDimension,
	|		DocumentAttributes.Ref					AS Stage,
	|		DocumentAttributes.Organization				AS Organization,
	|		CatProductionLots.MainProductProducts	AS Products,
	|		CatProductionLots.Purpose					AS Purpose,
	|		CatProductionLots.VATActivityType			AS VATActivityType,
	|		ISNULL(CatProductionLots.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))	AS LineOfBusiness,
	|		TRUE                                      AS CostAllocationForIssue
	|	FROM
	|		Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS TableOfGoods
	|
	|		INNER JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS DocumentAttributes
	|		ON DocumentAttributes.Ref = TableOfGoods.Ref
	|
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = TableOfGoods.ProductionLot
	|		AND NOT VALUETYPE(CatProductionLots.Document) = TYPE(Document.BackflushProduction)
	|
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|		LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
	|		ON CorrectedDocuments_.ReversedDocument = TableOfGoods.Ref
	|	WHERE
	|		DocumentAttributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND DocumentAttributes.Organization IN(&CompanyArray)
	|		AND DocumentAttributes.Posted
	// We exclude documents for which an adjustment or reversal has been introduced in the current period
	|		AND CorrectedDocuments_.ReversedDocument IS NULL
	|	) AS DD
	|
	|GROUP BY
	|	DD.ProductionLot,
	|	DD.DocumentLots,
	|	DD.CostGroupNumber,
	|	DD.FinancialAccountingDimension,
	|	DD.Stage,
	|	DD.Organization,
	|	DD.Products,
	|	DD.Purpose,
	|	DD.VATActivityType,
	|	DD.LineOfBusiness,
	|	DD.CostAllocationForIssue
	|
	|INDEX BY
	|	Stage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.ProductionLot                    AS ProductionLot,
	|	DD.DocumentLots                        AS DocumentLots,
	|	DD.CostGroupNumber                     AS CostGroupNumber,
	|	DD.LineOfBusiness               AS LineOfBusiness,
	|	DD.FinancialAccountingDimension             AS FinancialAccountingDimension,
	|	DD.Organization                           AS Organization,
	|	DD.Products                          AS Products,
	|	DD.Purpose                            AS Purpose,
	|	DD.VATActivityType                    AS VATActivityType,
	|	CASE
	|		WHEN VALUETYPE(DD.DocumentLots) = TYPE(Document.ProductionOrder2_2)
	|			THEN TRUE
	|		WHEN TRUE
	|			THEN FALSE
	|	END                                    AS LongTermProduction,
	|	MAX(DD.CostAllocationForIssue) AS CostAllocationForIssue
	|INTO ProductionBatchesAreSummarized
	|FROM
	|	ProductionBatchesByStages AS DD
	|
	|GROUP BY
	|	DD.ProductionLot,
	|	DD.DocumentLots,
	|	DD.CostGroupNumber,
	|	DD.LineOfBusiness,
	|	DD.FinancialAccountingDimension,
	|	DD.Organization,
	|	DD.Products,
	|	DD.Purpose,
	|	DD.VATActivityType
	|
	|INDEX BY
	|	ProductionLot,
	|	Organization
	|;";
	
	Return QueryText
	
EndFunction

// TT Partiidavalchesky production
//
// Returns:
// 	String - Query text
Function TextOfBatchOfTollProduction() Export
	
	Return "
	|SELECT
	|	ProductionOrder2_2.Partner              AS Partner,
	|	ProductionOrder2_2.Contract              AS Contract,
	|	ProductionBatchesAreSummarized.ProductionLot AS ProductionLot
	|INTO PartiesOfTollProduction
	|FROM
	|	ProductionBatchesAreSummarized AS ProductionBatchesAreSummarized
	|	
	|	INNER JOIN Document.ProductionOrder2_2 AS ProductionOrder2_2
	|	ON ProductionBatchesAreSummarized.DocumentLots = ProductionOrder2_2.Ref
	|
	|WHERE
	|	ProductionOrder2_2.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.TollManufacturing2_5))
	|
	|GROUP BY
	|	ProductionOrder2_2.Partner,
	|	ProductionOrder2_2.Contract,
	|	ProductionBatchesAreSummarized.ProductionLot
	|
	|INDEX BY
	|	Partner,
	|	Contract
	|;";
	
EndFunction
Function TextOfRemainingBatchesOfGNZPMaterials() Export
	Return "
	// Initial balances
	|SELECT
	|	""1"" AS RequestSource,
	|	DD.Organization					AS Organization,
	|	DD.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	DD.Lot						AS ProductionLot,
	|	DD.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DD.AccountingSection					AS AccountingSection,
	|	DD.LotVendorAttributes			AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension	AS FinancialAccountingDimension,
	|	DD.VATActivityType			AS VATActivityType,
	|	CASE
	|		WHEN DD.ItemsLocationAttributes.ProductCostElement.ExpenseType = VALUE(Enum.CostTypes.RecyclableWaste)
	|			THEN TRUE
	|		ELSE FALSE
	|	END							AS SideProduct,
	|	DD.CountBalance			AS Count,
	|	DD.CostBalance AS Cost,
	|	DD.CostExcludingVATBalance AS CostExcludingVAT,
	|	DD.OffBalanceCostBalance AS OffBalanceCost,
	|	DD.LocalCostBalance AS LocalCost,
	|	DD.OffBalanceCostLocalBalance AS OffBalanceCostLocal,
	|	DD.CostManBalance AS CostMan
	|
	|INTO BalanceOfMaterialsInDetail
	|	FROM
	|		AccumulationRegister.InventoryCost.Balance(
	|			&BorderEndOfPreviousPeriod,
	|			(Organization, Lot) IN(
	|				SELECT
	|					T.Organization,
	|					T.ProductionLot
	|				FROM
	|					ProductionBatchesAreSummarized AS T)) AS DD
	|
	|UNION ALL
	|
	// We also take storno corrections of the current period into account.
	|SELECT
	|	""2"" AS RequestSource,
	|	DD.Organization					AS Organization,
	|	DD.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	DD.Lot						AS ProductionLot,
	|	DD.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DD.AccountingSection					AS AccountingSection,
	|	DD.LotVendorAttributes			AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension	AS FinancialAccountingDimension,
	|	DD.VATActivityType			AS VATActivityType,
	|	CASE
	|		WHEN DD.ItemsLocationAttributes.ProductCostElement.ExpenseType = VALUE(Enum.CostTypes.RecyclableWaste)
	|			THEN TRUE
	|		ELSE FALSE
	|	END							AS SideProduct,
	|	DD.Count					AS Count,
	|	DD.Cost AS Cost,
	|	DD.CostExcludingVAT AS CostExcludingVAT,
	|	DD.OffBalanceCost AS OffBalanceCost,
	|	DD.LocalCost AS LocalCost,
	|	DD.OffBalanceCostLocal AS OffBalanceCostLocal,
	|	DD.CostMan AS CostMan
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|	
	|	INNER JOIN CorrectedDocuments_ AS CorrectedDocuments_
	|		ON CorrectedDocuments_.ReversedDocument = DD.Recorder
	|		
	|	INNER JOIN ProductionBatchesAreSummarized AS Lots
	|		ON DD.Lot = Lots.ProductionLot
	|		AND DD.Organization = Lots.Organization
	|	
	|WHERE
	|	DD.Period < &BeginOfPeriod
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND DD.Active
	|	AND DD.LotCalculation
	|	AND NOT DD.ReversingEntry
	|
	|UNION ALL
	|
	// Receipts of the current period, including Storno
	|SELECT
	|	""3"" AS RequestSource,
	|	DD.Organization					AS Organization,
	|	DD.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	DD.Lot						AS ProductionLot,
	|	DD.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DD.AccountingSection					AS AccountingSection,
	|	DD.LotVendorAttributes			AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension	AS FinancialAccountingDimension,
	|	DD.VATActivityType			AS VATActivityType,
	|	CASE
	|		WHEN DD.ItemsLocationAttributes.ProductCostElement.ExpenseType = VALUE(Enum.CostTypes.RecyclableWaste)
	|			THEN TRUE
	|		ELSE FALSE
	|	END							AS SideProduct,
	|	DD.Count					AS Count,
	|	DD.Cost AS Cost,
	|	DD.CostExcludingVAT AS CostExcludingVAT,
	|	DD.OffBalanceCost AS OffBalanceCost,
	|	DD.LocalCost AS LocalCost,
	|	DD.OffBalanceCostLocal AS OffBalanceCostLocal,
	|	DD.CostMan AS CostMan
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS DD
	|		
	|	INNER JOIN ProductionBatchesAreSummarized AS Lots
	|		ON DD.Lot = Lots.ProductionLot
	|		AND DD.Organization = Lots.Organization
	|
	|WHERE
	|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Organization IN (&CompanyArray)
	|	AND DD.OfficialTypeOfMovementParish
	|	AND (NOT DD.LotCalculation
	|		OR DD.ReversingEntry)
	
	|	AND (
	// We exclude the reverse of the processor's reports
	|		VALUETYPE(DD.Recorder) <> TYPE(Document.ReversingEntry)
	|		OR VALUETYPE(DD.DocumentSource) = TYPE(Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
	|		OR VALUETYPE(DD.DocumentSource) = TYPE(Document.PurchaseAdjustment))
	|
	|UNION ALL
	|
	|SELECT
	|	""4"" AS RequestSource,
	|	DD.Organization					AS Organization,
	|	DD.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	DD.Lot						AS ProductionLot,
	|	DD.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DD.AccountingSection					AS AccountingSection,
	|	DD.LotVendorAttributes			AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension	AS FinancialAccountingDimension,
	|	DD.VATActivityType			AS VATActivityType,
	|	CASE
	|		WHEN DD.ItemsLocationAttributes.ProductCostElement.ExpenseType = VALUE(Enum.CostTypes.RecyclableWaste)
	|			THEN TRUE
	|		ELSE FALSE
	|	END							AS SideProduct,
	|	DD.Count					AS Count,
	|	DD.Cost AS Cost,
	|	DD.CostExcludingVAT AS CostExcludingVAT,
	|	DD.OffBalanceCost AS OffBalanceCost,
	|	DD.LocalCost AS LocalCost,
	|	DD.OffBalanceCostLocal AS OffBalanceCostLocal,
	|	DD.CostMan AS CostMan
	|FROM
	|	TTProductionCostsCostOfGoods AS DD
	|		
	|	INNER JOIN ProductionBatchesAreSummarized AS ProductionBatchesAreSummarized
	|		ON DD.Lot = ProductionBatchesAreSummarized.ProductionLot
	|		AND DD.Organization = ProductionBatchesAreSummarized.Organization
	|
	|WHERE
	|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Organization IN (&CompanyArray)
	|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|;
	|SELECT
	|	DD.Organization						AS Organization,
	|	DD.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	DD.ProductionLot				AS ProductionLot,
	|	DD.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DD.AccountingSection						AS AccountingSection,
	|	DD.LotVendorAttributes				AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension		AS FinancialAccountingDimension,
	|	DD.VATActivityType				AS VATActivityType,
	|	DD.SideProduct					AS SideProduct,
	|	CASE
	|		WHEN SUM(DD.Count) < 0
	|			THEN -1
	|		ELSE 1
	|	END								AS ReductionRatio,
	|	SUM(DD.Count)				AS Count,
	|	SUM(CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		THEN DD.Cost
	|		ELSE 0
	|	END) AS Cost,
	|	SUM(CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		THEN DD.CostExcludingVAT
	|		ELSE 0
	|	END) AS CostExcludingVAT,
	|	SUM(CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		THEN DD.OffBalanceCost
	|		ELSE 0
	|	END) AS OffBalanceCost,
	|	SUM(CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		THEN DD.LocalCost
	|		ELSE 0
	|	END) AS LocalCost,
	|	SUM(CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		THEN DD.OffBalanceCostLocal
	|		ELSE 0
	|	END) AS OffBalanceCostLocal,
	|	SUM(CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		THEN DD.CostMan
	|		ELSE 0
	|	END) AS CostMan
	|INTO RemainingMaterials
	|FROM
	|	BalanceOfMaterialsInDetail AS DD
	|	
	|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
	|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
	|
	|GROUP BY
	|	DD.Organization,
	|	DD.ItemsLocationAttributes,
	|	DD.ProductionLot,
	|	DD.InventoryOwnerAttribute,
	|	DD.AccountingSection,
	|	DD.LotVendorAttributes,
	|	DD.FinancialAccountingDimension,
	|	DD.VATActivityType,
	|	DD.SideProduct
	|;
	|	
	|SELECT
	|	Balance.Organization					AS Organization,
	|	Balance.ProductionLot			AS ProductionLot,
	|	Balance.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	DD.Lot							AS BatchOfMaterial,
	|	DD.LotVendorAttributes				AS LotVendorAttributes,
	|	SUM(CAST(DD.Count AS NUMBER(15,3))) AS Count
	|INTO LotsOfGNZPMaterials
	|FROM
	|	RemainingMaterials AS Balance
	|
	|		INNER JOIN TTCashEstimatedTurnoverCostOfGoods AS DD
	|		ON Balance.ProductionLot = DD.CorLot
	|			AND Balance.ItemsLocationAttributes = DD.CorItemsLocationAttributes
	|
	|WHERE
	|	DD.Period <= &EndOfPeriod
	|	AND NOT DD.OfficialTypeOfMovementParish
	|	AND NOT DD.Lot = UNDEFINED
	|
	|GROUP BY
	|	Balance.Organization,
	|	Balance.ProductionLot,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	Balance.ItemsLocationAttributes
	|;";
	
EndFunction

Function TextEmptyBatchTableOfGNZPMaterials() Export
	
	Return "
	|SELECT TOP 0
	|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
	|	VALUE(Catalog.ProductionLots.EmptyRef) AS ProductionLot,
	|	UNDEFINED AS BatchOfMaterial,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS LotVendorAttributes,
	|	CAST(0 AS NUMBER(15,3)) AS Count
	|INTO LotsOfGNZPMaterials
	|;";
	
EndFunction

Function TextOfShareOfCostByProduct() Export
	
	// the share of processing and the actual quantity of products
	#Region TextvtSharesForProcessing
	TextvtSharesForProcessing = "
	|SELECT DISTINCT
	|	DD.ProductionLot		AS ProductionLot,
	|	DD.Products				AS Products,
	|	DD.Characteristic			AS Characteristic,
	|	DD.RowCode				AS RowCode,
	|	SUM(DD.CountPlan)	AS CountPlan,
	|	SUM(DD.CountReal)	AS CountReal,
	|	SUM(DD.ShareCostPlan)	AS ShareCostPlan
	|INTO TTShareProcessing
	|FROM
	|	(
	|	SELECT
	|		StageDetails.ProductionLot	AS ProductionLot,
	|		TableOfGoods.Products			AS Products,
	|		TableOfGoods.Characteristic		AS Characteristic,
	|		TableOfGoods.RowCode			AS RowCode,
	|		TableOfGoods.Count			AS CountPlan,
	|		0									AS CountReal,
	|		CASE
	|			WHEN TableOfGoods.CostShare = 0
	|				THEN TableOfGoods.Count
	|			ELSE TableOfGoods.CostShare
	|		END								AS ShareCostPlan
	|	FROM
	|		ProductionBatchesAreSummarized AS ProductionLots
	|
	|			INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|			ON ProductionLots.ProductionLot = StageDetails.ProductionLot
	|
	|			INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS TableOfGoods
	|			ON TableOfGoods.Ref = StageDetails.Ref
	|
	|	WHERE
	|		StageDetails.ProductionByThirdParty
	|		AND StageDetails.Posted
	|		AND NOT TableOfGoods.Canceled
	|		AND ProductionLots.CostAllocationForIssue
	|
	|	UNION ALL
	|
	// InternalSubcontracting
	|	SELECT
	|		StageDetails.ProductionLot	AS ProductionLot,
	|		TableOfGoods.Products			AS Products,
	|		TableOfGoods.Characteristic		AS Characteristic,
	|		TableOfGoods.RowCode			AS RowCode,
	|		TableOfGoods.Count			AS CountPlan,
	|		0									AS CountReal,
	|		CASE
	|			WHEN TableOfGoods.CostShare = 0
	|				THEN TableOfGoods.Count
	|			ELSE TableOfGoods.CostShare
	|		END								AS ShareCostPlan
	|	FROM
	|		ProductionBatchesAreSummarized AS ProductionLots
	|
	|			INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|			ON ProductionLots.ProductionLot = StageDetails.ProductionLot
	|
	|			INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS TableOfGoods
	|			ON TableOfGoods.Ref = StageDetails.Ref
	|
	|	WHERE
	|		StageDetails.InternalSubcontracting
	|		AND StageDetails.Posted
	|		AND NOT TableOfGoods.Canceled
	|		AND ProductionLots.CostAllocationForIssue
	|
	|	UNION ALL
	|
	|	SELECT
	|		ProductionLots.ProductionLot	AS ProductionLot,
	|		TableOfGoods.Products				AS Products,
	|		TableOfGoods.Characteristic			AS Characteristic,
	|		TableOfGoods.RowCode				AS RowCode,
	|		TableOfGoods.Count				AS CountPlan,
	|		0										AS CountReal,
	|		CASE
	|			WHEN TableOfGoods.CostShare = 0
	|				THEN TableOfGoods.Count
	|			ELSE TableOfGoods.CostShare
	|		END								AS ShareCostPlan
	|	FROM
	|		ProductionBatchesByStages AS ProductionLots
	|		
	|		INNER JOIN Document.BackflushProduction AS AttributesOfBackflushedProduction
	|		ON ProductionLots.Stage = AttributesOfBackflushedProduction.Ref
	|		AND AttributesOfBackflushedProduction.Posted
	|		
	|		INNER JOIN Document.BackflushProduction.ManufacturedProducts AS TableOfGoods
	|		ON TableOfGoods.Ref = AttributesOfBackflushedProduction.Ref
	|		AND ProductionLots.CostGroupNumber = TableOfGoods.CostGroupNumber
	|		AND TableOfGoods.InternalSubcontracting
	|	WHERE
	|		ProductionLots.CostAllocationForIssue
	|	
	|	
	|	UNION ALL
	|
	|	SELECT
	|		StageDetails.ProductionLot	AS ProductionLot,
	|		TableOfGoods.Products			AS Products,
	|		TableOfGoods.Characteristic		AS Characteristic,
	|		TableOfGoods.RowCode			AS RowCode,
	|		0									AS CountPlan,
	|		TableOfGoods.Count			AS CountReal,
	|		0									AS ShareCostPlan
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS TableOfGoods
	|
	|			INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|			ON StageDetails.Ref = TableOfGoods.ProductionStage
	|
	|			INNER JOIN ProductionBatchesAreSummarized AS ProductionLots
	|			ON StageDetails.ProductionLot = ProductionLots.ProductionLot
	|			AND ProductionLots.CostAllocationForIssue
	|
	|	WHERE
	|		TableOfGoods.Ref.Posted
	|		AND TableOfGoods.Ref.Date <= &EndOfPeriod
	|	) AS DD
	|
	|GROUP BY
	|	DD.ProductionLot,
	|	DD.Products,
	|	DD.Characteristic,
	|	DD.RowCode
	|
	|INDEX BY
	|	DD.ProductionLot,
	|	DD.Products,
	|	DD.Characteristic,
	|	DD.RowCode";
	#EndRegion
	
	// Data description
	#Region TextvtManufacturedProducts_DataDescription
	TextvtManufacturedProducts_DataDescription = "
	|SELECT TOP 0
	|	VALUE(Enum.BusinessTransactions.EmptyRef)
	|													AS BusinessOperation,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|													AS AccountingSection,
	|	VALUE(Catalog.ProductionLots.EmptyRef)
	|													AS ProductionLot,
	|	UNDEFINED									AS ReleaseParty,
	|	DATETIME(1,1,1)								AS ProductionDate,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|													AS LotVendorAttributes,
	|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|													AS FinancialAccountingDimension,
	|	VALUE(Catalog.Companies.EmptyRef)
	|													AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)
	|													AS Department,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)
	|													AS VATActivityType,
	|	VALUE(Catalog.Products.EmptyRef)
	|													AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|													AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef)
	|													AS Series,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|													AS BillOfMaterials,
	|	CAST("""" AS STRING(36))						AS RowID,
	|	CAST("""" AS STRING(36))						AS FinRecordID,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)
	|													AS InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|													AS ItemsLocationAttributes,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|													AS ExpenseItemOfWriteOff,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|													AS AssetAndLiabilityItem,
	|	UNDEFINED									AS DimensionOfExpenses,
	|	UNDEFINED									AS AssetsLiabilitiesDimension,
	|	CAST(0 AS NUMBER(15, 3))					AS Real,
	|	CAST(0 AS NUMBER(15, 3))					AS Plan,
	|	CAST(0 AS NUMBER(15, 3))					AS ProductsQuantity,
	|	CAST(0 AS NUMBER(23, 10))					AS ShareCostFact,
	|	CAST(0 AS NUMBER(23, 10))					AS CostShare,
	|	CAST(0 AS NUMBER(23, 10))					AS FullShareOfValue
	|INTO TTManufacturedProduct";
	#EndRegion
	
	// plan and fact for production without orders - goods
	#Region TextttManufacturedProducts_PBZ_Items_I_TraceableWorks
	TextvtManufacturedProducts_PBZ_Goods = "
	|SELECT
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	CASE
	|		WHEN CatInventoryKinds.InventoryType IS NULL
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			OR CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|				THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|	END											AS AccountingSection,
	|	ProductionLots.ProductionLot			AS ProductionLot,
	|	DocumentAttributes.Ref						AS ReleaseParty,
	|	DocumentAttributes.Date							AS ProductionDate,
	|	CASE
	|		WHEN GoodsTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN ISNULL(BatchAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
	|		ELSE ISNULL(AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
	|	END											AS LotVendorAttributes,
	|	ProductionLots.FinancialAccountingDimension	AS FinancialAccountingDimension,
	|	ProductionLots.Organization					AS Organization,
	|	DocumentAttributes.Department				AS Department,
	|	DocumentAttributes.ProductionIssueForActivity		AS VATActivityType,
	|	AnalyticsByRecipient.Products				AS Products,
	|	AnalyticsByRecipient.Characteristic			AS Characteristic,
	|	AnalyticsByRecipient.Series						AS Series,
	|	GoodsTable.BillOfMaterials						AS BillOfMaterials,
	|	GoodsTable.RowID				AS RowID,
	|	GoodsTable.FinRecordID			AS FinRecordID,
	|	CatInventoryKinds.Ref							AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|		 AND NOT CatWarehouses.ShopFloorStockroom
	|		 AND NOT DimensionByBusinessUnit.DimensionKey IS NULL
	|			THEN DimensionByBusinessUnit.DimensionKey
	|		WHEN NOT &KeepRecordsOfInventoryCostByAssignments
	|		 AND NOT DimensionByBusinessUnit.DimensionKey IS NULL
	|		 AND NOT CatWarehouses.ShopFloorStockroom
	|			THEN AnalyticsByDivisionWithoutAssignment.DimensionKey
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE AnalyticsByRecipientWithoutAssignment.DimensionKey
	|	END											AS ItemsLocationAttributes,
	|	CASE
	|		WHEN VALUETYPE(GoodsTable.Recipient) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN GoodsTable.Recipient
	|		ELSE UNDEFINED
	|	END											AS ExpenseItemOfWriteOff,
	|	CASE
	|		WHEN VALUETYPE(GoodsTable.Recipient) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN GoodsTable.Recipient
	|		ELSE UNDEFINED
	|	END											AS AssetAndLiabilityItem,
	|	GoodsTable.DimensionOfExpenses					AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	SUM(GoodsTable.Count)					AS Real,
	|	SUM(GoodsTable.Count)					AS Plan,
	|	SUM(GoodsTable.Count)					AS ProductsQuantity,
	|	SUM(CASE
	|			WHEN GoodsTable.CostShare = 0
	|				THEN GoodsTable.Count
	|			ELSE GoodsTable.CostShare
	|		END)										AS ShareCostFact,
	|	SUM(CAST(CASE
	|			WHEN GoodsTable.CostShare = 0
	|				THEN GoodsTable.Count - ISNULL(LotsOfGNZPMaterials.Count, 0)
	|			ELSE GoodsTable.CostShare
	|				- ISNULL(LotsOfGNZPMaterials.Count, 0)
	|					* GoodsTable.CostShare
	|					/ GoodsTable.Count
	|		END AS NUMBER(23, 10)))					AS CostShare,
	|	SUM(CASE
	|			WHEN GoodsTable.CostShare = 0
	|				THEN GoodsTable.Count
	|			ELSE GoodsTable.CostShare
	|		END)										AS FullShareOfValue
	|FROM
	|	ProductionBatchesByStages AS ProductionLots
	|
	|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
	|		ON ProductionLots.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
	|
	|		INNER JOIN Document.BackflushProduction AS DocumentAttributes
	|		ON DocumentAttributes.Ref = ProductionLots.Stage
	|
	|		INNER JOIN Document.BackflushProduction.InventoryOwnerAttributesFinishedProducts AS GoodsTable
	|		ON GoodsTable.Ref = DocumentAttributes.Ref
	|		AND GoodsTable.CostGroupNumber = ProductionLots.CostGroupNumber
	|		
	|		INNER JOIN Catalog.InventoryKinds AS CatInventoryKinds
	|		ON GoodsTable.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|		AND ProductionLots.Organization = CatInventoryKinds.Organization
	|
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS AnalyticsByRecipient
	|		ON AnalyticsByRecipient.Ref = GoodsTable.ItemsLocationAttributes
	|
	|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = AnalyticsByRecipient.StorageLocation
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsByRecipientWithoutAssignment
	|		ON AnalyticsByRecipientWithoutAssignment.Products = AnalyticsByRecipient.Products
	|			AND AnalyticsByRecipientWithoutAssignment.Characteristic = AnalyticsByRecipient.Characteristic
	|			AND AnalyticsByRecipientWithoutAssignment.Series = AnalyticsByRecipient.Series
	|			AND AnalyticsByRecipientWithoutAssignment.StorageLocation = AnalyticsByRecipient.StorageLocation
	|			AND AnalyticsByRecipientWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			AND AnalyticsByRecipientWithoutAssignment.ProductCostElement = AnalyticsByRecipient.ProductCostElement
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByBusinessUnit
	|		ON AnalyticsByRecipient.Products = DimensionByBusinessUnit.Products
	|			AND AnalyticsByRecipient.Characteristic = DimensionByBusinessUnit.Characteristic
	|			AND AnalyticsByRecipient.Series = DimensionByBusinessUnit.Series
	|			AND DocumentAttributes.Department = DimensionByBusinessUnit.StorageLocation
	|			AND AnalyticsByRecipient.Purpose = DimensionByBusinessUnit.Purpose
	|			AND AnalyticsByRecipient.ProductCostElement = DimensionByBusinessUnit.ProductCostElement
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsByDivisionWithoutAssignment
	|		ON DimensionByBusinessUnit.Products = AnalyticsByDivisionWithoutAssignment.Products
	|			AND DimensionByBusinessUnit.Characteristic = AnalyticsByDivisionWithoutAssignment.Characteristic
	|			AND DimensionByBusinessUnit.Series = AnalyticsByDivisionWithoutAssignment.Series
	|			AND DimensionByBusinessUnit.StorageLocation = AnalyticsByDivisionWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsByDivisionWithoutAssignment.Purpose
	|			AND DimensionByBusinessUnit.ProductCostElement = AnalyticsByDivisionWithoutAssignment.ProductCostElement
	|
	|		LEFT JOIN InformationRegister.LotVendorAttributes AS AnalysisOfAccountingOfBatchesOfGoods_
	|		ON AnalysisOfAccountingOfBatchesOfGoods_.FinancialAccountingGroup = VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.Vendor           = VALUE(Catalog.Partners.EmptyRef)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.Counterparty          = UNDEFINED
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.VATRate           = VALUE(Catalog.VATRates.EmptyRef)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.VATTaxation  = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.AssetTaxClass         = VALUE(Enum.AssetKinds.Goods)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.RowCode           = GoodsTable.RowCode
	|			AND DocumentAttributes.Organization IN (&SFIFOOrganizationsSliding)
	|
	|		LEFT JOIN InformationRegister.LotVendorAttributes AS BatchAccountingAnalysts
	|		ON BatchAccountingAnalysts.FinancialAccountingGroup = VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|			AND BatchAccountingAnalysts.Vendor           = VALUE(Catalog.Partners.EmptyRef)
	|			AND BatchAccountingAnalysts.Counterparty          = UNDEFINED
	|			AND BatchAccountingAnalysts.VATRate           = VALUE(Catalog.VATRates.EmptyRef)
	|			AND BatchAccountingAnalysts.VATTaxation  = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			AND BatchAccountingAnalysts.AssetTaxClass         = VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|			AND BatchAccountingAnalysts.RowCode           = GoodsTable.RowCode
	|			AND DocumentAttributes.Organization IN (&SFIFOOrganizationsSliding)
	|
	|		LEFT JOIN LotsOfGNZPMaterials AS LotsOfGNZPMaterials
	|		ON LotsOfGNZPMaterials.ProductionLot = ProductionLots.ProductionLot
	|			AND LotsOfGNZPMaterials.BatchOfMaterial = ProductionLots.DocumentLots
	|			AND (LotsOfGNZPMaterials.LotVendorAttributes = AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey
	|				OR LotsOfGNZPMaterials.LotVendorAttributes = BatchAccountingAnalysts.DimensionKey)
	|			AND LotsOfGNZPMaterials.Organization = CatInventoryKinds.Organization
	|
	|WHERE
	|	DocumentAttributes.Posted
	|	AND DocumentAttributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ProductionLots.CostAllocationForIssue
	|
	|GROUP BY
	|	CatInventoryKinds.Ref,
	|	CatInventoryKinds.InventoryType,
	|	CASE
	|		WHEN CatInventoryKinds.InventoryType IS NULL
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			OR CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|				THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|	END,
	|	ProductionLots.ProductionLot,
	|	DocumentAttributes.Ref,
	|	DocumentAttributes.Date,
	|	CASE
	|		WHEN GoodsTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN ISNULL(BatchAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
	|		ELSE ISNULL(AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
	|	END,
	|	ProductionLots.FinancialAccountingDimension,
	|	ProductionLots.Organization,
	|	DocumentAttributes.Department,
	|	DocumentAttributes.ProductionIssueForActivity,
	|	AnalyticsByRecipient.Products,
	|	AnalyticsByRecipient.Characteristic,
	|	AnalyticsByRecipient.Series,
	|	GoodsTable.BillOfMaterials,
	|	GoodsTable.RowID,
	|	GoodsTable.FinRecordID,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|		 AND NOT CatWarehouses.ShopFloorStockroom
	|		 AND NOT DimensionByBusinessUnit.DimensionKey IS NULL
	|			THEN DimensionByBusinessUnit.DimensionKey
	|		WHEN NOT &KeepRecordsOfInventoryCostByAssignments
	|		 AND NOT DimensionByBusinessUnit.DimensionKey IS NULL
	|		 AND NOT CatWarehouses.ShopFloorStockroom
	|			THEN AnalyticsByDivisionWithoutAssignment.DimensionKey
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE AnalyticsByRecipientWithoutAssignment.DimensionKey
	|	END,
	|	GoodsTable.Recipient,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension";
	#EndRegion
	
	// plan and fact for production without orders - work
	#Region TextvtManufacturedProducts_PBZ_Works
	TextvtManufacturedProducts_PBZ_Works = "
	|SELECT
	|	VALUE(Enum.BusinessTransactions.ProductsRelease)					AS BusinessOperation,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)	AS AccountingSection,
	|	ProductionLots.ProductionLot			AS ProductionLot,
	|	DocumentAttributes.Ref						AS ReleaseParty,
	|	DocumentAttributes.Date							AS ProductionDate,
	|	ISNULL(PartyAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)) AS LotVendorAttributes,
	|	ProductionLots.FinancialAccountingDimension	AS FinancialAccountingDimension,
	|	ProductionLots.Organization					AS Organization,
	|	DocumentAttributes.Department				AS Department,
	|	DocumentAttributes.ProductionIssueForActivity		AS VATActivityType,
	|	AnalyticsByRecipient.Products				AS Products,
	|	AnalyticsByRecipient.Characteristic			AS Characteristic,
	|	AnalyticsByRecipient.Series						AS Series,
	|	GoodsTable.BillOfMaterials						AS BillOfMaterials,
	|	GoodsTable.RowID				AS RowID,
	|	GoodsTable.RowID				AS FinRecordID,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsByRecipientWithoutAssignment.DimensionKey
	|	END											AS ItemsLocationAttributes,
	|	CASE
	|		WHEN VALUETYPE(GoodsTable.Recipient) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN GoodsTable.Recipient
	|		ELSE UNDEFINED
	|	END											AS ExpenseItemOfWriteOff,
	|	CASE
	|		WHEN VALUETYPE(GoodsTable.Recipient) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN GoodsTable.Recipient
	|		ELSE UNDEFINED
	|	END											AS AssetAndLiabilityItem,
	|	GoodsTable.DimensionOfExpenses					AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	SUM(GoodsTable.Count)					AS Real,
	|	SUM(GoodsTable.Count)					AS Plan,
	|	SUM(GoodsTable.Count)					AS ProductsQuantity,
	|	SUM(CASE
	|			WHEN GoodsTable.CostShare = 0
	|				THEN GoodsTable.Count
	|			ELSE GoodsTable.CostShare
	|		END)										AS ShareCostFact,
	|	SUM(CAST(CASE
	|			WHEN GoodsTable.CostShare = 0
	|				THEN GoodsTable.Count - ISNULL(LotsOfGNZPMaterials.Count, 0)
	|			ELSE GoodsTable.CostShare
	|					- ISNULL(LotsOfGNZPMaterials.Count, 0)
	|						* GoodsTable.CostShare
	|						/ GoodsTable.Count
	|		END AS NUMBER(23, 10)))					AS CostShare,
	|	SUM(CASE
	|			WHEN GoodsTable.CostShare = 0
	|				THEN GoodsTable.Count
	|			ELSE GoodsTable.CostShare
	|		END)										AS FullShareOfValue
	|FROM
	|	ProductionBatchesByStages AS ProductionLots
	|
	|		INNER JOIN Document.BackflushProduction AS DocumentAttributes
	|		ON DocumentAttributes.Ref = ProductionLots.Stage
	|
	|		INNER JOIN Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|		ON GoodsTable.Ref = DocumentAttributes.Ref
	|			AND GoodsTable.CostGroupNumber = ProductionLots.CostGroupNumber
	|			AND CASE
	|				WHEN GoodsTable.InternalSubcontracting
	|					THEN GoodsTable.MaterialProviderCompany = ProductionLots.Organization
	|				WHEN TRUE
	|					THEN DocumentAttributes.Organization = ProductionLots.Organization
	|			END
	|
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS AnalyticsByRecipient
	|		ON AnalyticsByRecipient.Ref = GoodsTable.ItemsLocationAttributes
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsByRecipientWithoutAssignment
	|		ON AnalyticsByRecipientWithoutAssignment.Products = AnalyticsByRecipient.Products
	|			AND AnalyticsByRecipientWithoutAssignment.Characteristic = AnalyticsByRecipient.Characteristic
	|			AND AnalyticsByRecipientWithoutAssignment.Series = AnalyticsByRecipient.Series
	|			AND AnalyticsByRecipientWithoutAssignment.StorageLocation = AnalyticsByRecipient.StorageLocation
	|			AND AnalyticsByRecipientWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			AND AnalyticsByRecipientWithoutAssignment.ProductCostElement = AnalyticsByRecipient.ProductCostElement
	|
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = GoodsTable.Products
	|
	|		LEFT JOIN InformationRegister.LotVendorAttributes AS PartyAccountingAnalysts
	|		ON PartyAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|			AND PartyAccountingAnalysts.Vendor				= VALUE(Catalog.Partners.EmptyRef)
	|			AND PartyAccountingAnalysts.Counterparty				= UNDEFINED
	|			AND PartyAccountingAnalysts.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
	|			AND PartyAccountingAnalysts.VATTaxation 		= VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			AND PartyAccountingAnalysts.AssetTaxClass				= VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|			AND PartyAccountingAnalysts.RowCode				= GoodsTable.RowCode
	|			AND DocumentAttributes.Organization IN (&SFIFOOrganizationsSliding)
	|
	|		LEFT JOIN LotsOfGNZPMaterials AS LotsOfGNZPMaterials
	|		ON LotsOfGNZPMaterials.ProductionLot = ProductionLots.ProductionLot
	|			AND LotsOfGNZPMaterials.BatchOfMaterial = ProductionLots.DocumentLots
	|			AND LotsOfGNZPMaterials.LotVendorAttributes = PartyAccountingAnalysts.DimensionKey
	|			AND LotsOfGNZPMaterials.Organization = DocumentAttributes.Organization
	|
	|WHERE
	|	CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT CatProducts.TracedGoods
	|	AND DocumentAttributes.Posted
	|	AND DocumentAttributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ProductionLots.CostAllocationForIssue
	|
	|GROUP BY
	|	ProductionLots.ProductionLot,
	|	DocumentAttributes.Ref,
	|	DocumentAttributes.Date,
	|	ISNULL(PartyAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)),
	|	ProductionLots.FinancialAccountingDimension,
	|	ProductionLots.Organization,
	|	DocumentAttributes.Department,
	|	DocumentAttributes.ProductionIssueForActivity,
	|	AnalyticsByRecipient.Products,
	|	AnalyticsByRecipient.Characteristic,
	|	AnalyticsByRecipient.Series,
	|	GoodsTable.BillOfMaterials,
	|	GoodsTable.RowID,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsByRecipientWithoutAssignment.DimensionKey
	|	END,
	|	GoodsTable.Recipient,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension";
	#EndRegion
	
	// plan and fact by stages (released goods)
	#Region TextvtManufacturedProducts_Stages_Goods_And_TraceableWorks
	TextvtManufacturedProducts_Stages_Goods = "
	|SELECT
	|	VALUE(Enum.BusinessTransactions.ProductsRelease)		AS BusinessOperation,
	|	CASE
	|		WHEN CatInventoryKinds.InventoryType IS NULL 
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		ELSE
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|	END																AS AccountingSection,
	|	ProductionLots.ProductionLot								AS ProductionLot,
	|	StageDetails.Ref												AS ReleaseParty,
	|	InventoryKinds.DateOfTransaction											AS ProductionDate,
	|	CASE
	|		WHEN InventoryKinds.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN ISNULL(BatchAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
	|		ELSE ISNULL(AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
	|	END																AS LotVendorAttributes,
	|	ProductionLots.FinancialAccountingDimension						AS FinancialAccountingDimension,
	|	ProductionLots.Organization										AS Organization,
	|	InventoryKinds.Department											AS Department,
	|	StageDetails.ProductionIssueForActivity								AS VATActivityType,
	|	InventoryKinds.ItemsLocationAttributes.Products					AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic				AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Series						AS Series,
	|	StageDetails.BillOfMaterials											AS BillOfMaterials,
	|	InventoryKinds.RowID										AS RowID,
	|	InventoryKinds.FinRecordID									AS FinRecordID,
	|	CatInventoryKinds.Ref												AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END																AS ItemsLocationAttributes,
	|	CASE
	|		WHEN VALUETYPE(InventoryKinds.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN InventoryKinds.ExpenseItem
	|		ELSE UNDEFINED
	|	END																AS ExpenseItemOfWriteOff,
	|	CASE
	|		WHEN VALUETYPE(InventoryKinds.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN InventoryKinds.ExpenseItem
	|		ELSE UNDEFINED
	|	END																AS AssetAndLiabilityItem,
	|	InventoryKinds.DimensionOfExpenses										AS DimensionOfExpenses,
	|	InventoryKinds.AssetsLiabilitiesDimension								AS AssetsLiabilitiesDimension,
	|	SUM(CASE
	|			WHEN InventoryKinds.DateOfTransaction <= &EndOfPeriod
	|				THEN InventoryKinds.Count
	|			ELSE 0
	|		END)															AS Real,
	|	SUM(InventoryKinds.Count)										AS Plan,
	|	SUM(CASE
	|			WHEN InventoryKinds.DateOfTransaction BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|				THEN InventoryKinds.Count
	|			ELSE 0
	|		END)															AS ProductsQuantity,
	|	SUM(CASE
	|			WHEN InventoryKinds.DateOfTransaction <= &EndOfPeriod
	|				THEN CASE
	|						WHEN InventoryKinds.CostShare = 0
	|							THEN InventoryKinds.Count
	|						ELSE InventoryKinds.CostShare
	|					END
	|			ELSE 0
	|		END)															AS ShareCostFact,
	|	SUM(CAST(CASE
	|			WHEN InventoryKinds.CostShare = 0
	|				THEN InventoryKinds.Count - ISNULL(LotsOfGNZPMaterials.Count, 0)
	|			ELSE InventoryKinds.CostShare
	|					- ISNULL(LotsOfGNZPMaterials.Count, 0)
	|						* InventoryKinds.CostShare
	|						/ InventoryKinds.Count
	|		END AS NUMBER(23, 10)))										AS CostShare,
	|	SUM(CASE
	|			WHEN InventoryKinds.CostShare = 0
	|				THEN InventoryKinds.Count
	|			ELSE InventoryKinds.CostShare
	|		END)															AS FullShareOfValue
	|FROM
	|	ProductionBatchesAreSummarized AS ProductionLots
	|
	|		INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|		ON StageDetails.ProductionLot = ProductionLots.ProductionLot
	|
	|		INNER JOIN Document.ProductionStage2_2.InventoryOwnerAttributesProducts AS InventoryKinds
	|		ON InventoryKinds.Ref = StageDetails.Ref
	|			AND InventoryKinds.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|
	|		INNER JOIN Catalog.InventoryKinds AS CatInventoryKinds
	|		ON InventoryKinds.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|			AND CatInventoryKinds.Organization = ProductionLots.Organization
	|
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON Dimension.Ref = InventoryKinds.ItemsLocationAttributes
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|
	|		LEFT JOIN InformationRegister.LotVendorAttributes AS AnalysisOfAccountingOfBatchesOfGoods_
	|		ON AnalysisOfAccountingOfBatchesOfGoods_.FinancialAccountingGroup = VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.Vendor				= VALUE(Catalog.Partners.EmptyRef)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.Counterparty			= UNDEFINED
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.VATTaxation	= VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.AssetTaxClass			= VALUE(Enum.AssetKinds.Goods)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.RowCode				= InventoryKinds.RowCode
	|			AND StageDetails.Organization IN (&SFIFOOrganizationsSliding)
	|
	|		LEFT JOIN InformationRegister.LotVendorAttributes AS BatchAccountingAnalysts
	|		ON BatchAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|			AND BatchAccountingAnalysts.Vendor				= VALUE(Catalog.Partners.EmptyRef)
	|			AND BatchAccountingAnalysts.Counterparty				= UNDEFINED
	|			AND BatchAccountingAnalysts.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
	|			AND BatchAccountingAnalysts.VATTaxation		= VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			AND BatchAccountingAnalysts.AssetTaxClass				= VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|			AND BatchAccountingAnalysts.RowCode				= InventoryKinds.RowCode
	|			AND StageDetails.Organization IN (&SFIFOOrganizationsSliding)
	|
	|		LEFT JOIN LotsOfGNZPMaterials AS LotsOfGNZPMaterials
	|		ON LotsOfGNZPMaterials.ProductionLot = ProductionLots.ProductionLot
	|			AND LotsOfGNZPMaterials.BatchOfMaterial = StageDetails.Ref
	|			AND (LotsOfGNZPMaterials.LotVendorAttributes = AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey
	|				OR LotsOfGNZPMaterials.LotVendorAttributes = BatchAccountingAnalysts.DimensionKey)
	|			AND LotsOfGNZPMaterials.Organization = CatInventoryKinds.Organization
	|
	|WHERE
	|	NOT StageDetails.ProductionByThirdParty
	|	AND StageDetails.Posted
	|	AND InventoryKinds.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|	AND ProductionLots.CostAllocationForIssue
	|
	|GROUP BY
	|	CatInventoryKinds.Ref,
	|	CatInventoryKinds.InventoryType,
	|	CASE
	|		WHEN CatInventoryKinds.InventoryType IS NULL 
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		ELSE
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|	END,
	|	ProductionLots.ProductionLot,
	|	StageDetails.Ref,
	|	InventoryKinds.DateOfTransaction,
	|	CASE
	|		WHEN InventoryKinds.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN ISNULL(BatchAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
	|		ELSE ISNULL(AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
	|	END,
	|	ProductionLots.FinancialAccountingDimension,
	|	ProductionLots.Organization,
	|	InventoryKinds.Department,
	|	StageDetails.ProductionIssueForActivity,
	|	InventoryKinds.ItemsLocationAttributes.Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Series,
	|	StageDetails.BillOfMaterials,
	|	InventoryKinds.RowID,
	|	InventoryKinds.FinRecordID,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END,
	|	InventoryKinds.ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses,
	|	InventoryKinds.AssetsLiabilitiesDimension";
	#EndRegion
	
	// plan and fact by stages (unreleased goods, works)
	#Region TextvtManufacturedProducts_Stages_OfWork
	TextvtManufacturedProducts_Stages_OfWork = "
	|SELECT
	|	VALUE(Enum.BusinessTransactions.ProductsRelease)	AS BusinessOperation,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
	|	ProductionLots.ProductionLot							AS ProductionLot,
	|	StageDetails.Ref											AS ReleaseParty,
	|	GoodsTable.ProductionDate									AS ProductionDate,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN ISNULL(BatchAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
	|		ELSE ISNULL(AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
	|	END															AS LotVendorAttributes,
	|	ProductionLots.FinancialAccountingDimension					AS FinancialAccountingDimension,
	|	ProductionLots.Organization									AS Organization,
	|	GoodsTable.Department										AS Department,
	|	StageDetails.ProductionIssueForActivity							AS VATActivityType,
	|	GoodsTable.Products										AS Products,
	|	GoodsTable.Characteristic									AS Characteristic,
	|	GoodsTable.Series												AS Series,
	|	StageDetails.BillOfMaterials										AS BillOfMaterials,
	|	GoodsTable.RowID								AS RowID,
	|	GoodsTable.RowID								AS FinRecordID,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)					AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END															AS ItemsLocationAttributes,
	|	CASE
	|		WHEN VALUETYPE(GoodsTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN GoodsTable.ExpenseItem
	|		ELSE UNDEFINED
	|	END															AS ExpenseItemOfWriteOff,
	|	CASE
	|		WHEN VALUETYPE(GoodsTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN GoodsTable.ExpenseItem
	|		ELSE UNDEFINED
	|	END															AS AssetAndLiabilityItem,
	|	GoodsTable.DimensionOfExpenses									AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension							AS AssetsLiabilitiesDimension,
	|	SUM(CASE
	|			WHEN GoodsTable.Manufactured
	|				AND GoodsTable.ProductionDate <= &EndOfPeriod
	|				THEN GoodsTable.Count
	|			ELSE 0
	|		END)														AS Real,
	|	SUM(GoodsTable.Count)									AS Plan,
	|	SUM(CASE
	|			WHEN GoodsTable.Manufactured
	|				AND GoodsTable.ProductionDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|				THEN GoodsTable.Count
	|			ELSE 0
	|		END)														AS ProductsQuantity,
	|	SUM(CASE
	|			WHEN GoodsTable.Manufactured
	|				AND GoodsTable.ProductionDate <= &EndOfPeriod
	|				THEN CASE
	|						WHEN GoodsTable.CostShare = 0
	|							THEN GoodsTable.Count
	|						ELSE GoodsTable.CostShare
	|					END
	|			ELSE 0
	|		END)														AS ShareCostFact,
	|	SUM(CAST(CASE
	|			WHEN GoodsTable.CostShare = 0
	|				THEN GoodsTable.Count - ISNULL(LotsOfGNZPMaterials.Count, 0)
	|			ELSE GoodsTable.CostShare
	|					- ISNULL(LotsOfGNZPMaterials.Count, 0)
	|						* GoodsTable.CostShare
	|						/ GoodsTable.Count
	|		END AS NUMBER(23, 10)))									AS CostShare,
	|	SUM(CASE
	|			WHEN GoodsTable.CostShare = 0
	|				THEN GoodsTable.Count
	|			ELSE GoodsTable.CostShare
	|		END)														AS FullShareOfValue
	|FROM
	|	ProductionBatchesAreSummarized AS ProductionLots
	|
	|		INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|		ON StageDetails.ProductionLot = ProductionLots.ProductionLot
	|			AND CASE
	|					WHEN StageDetails.InternalSubcontracting
	|						THEN StageDetails.MaterialProviderCompany
	|					ELSE StageDetails.Organization
	|				END = ProductionLots.Organization
	|
	|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS GoodsTable
	|		ON GoodsTable.Ref = StageDetails.Ref
	|
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON Dimension.Ref = GoodsTable.ItemsLocationAttributes
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|
	|		LEFT JOIN InformationRegister.LotVendorAttributes AS AnalysisOfAccountingOfBatchesOfGoods_
	|		ON AnalysisOfAccountingOfBatchesOfGoods_.FinancialAccountingGroup = VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.Vendor				= VALUE(Catalog.Partners.EmptyRef)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.Counterparty			= UNDEFINED
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.VATTaxation 	= VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.AssetTaxClass			= VALUE(Enum.AssetKinds.Goods)
	|			AND AnalysisOfAccountingOfBatchesOfGoods_.RowCode				= GoodsTable.RowCode
	|			AND StageDetails.Organization IN (&SFIFOOrganizationsSliding)
	|
	|		LEFT JOIN InformationRegister.LotVendorAttributes AS BatchAccountingAnalysts
	|		ON BatchAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|			AND BatchAccountingAnalysts.Vendor				= VALUE(Catalog.Partners.EmptyRef)
	|			AND BatchAccountingAnalysts.Counterparty				= UNDEFINED
	|			AND BatchAccountingAnalysts.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
	|			AND BatchAccountingAnalysts.VATTaxation		= VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			AND BatchAccountingAnalysts.AssetTaxClass				= VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|			AND BatchAccountingAnalysts.RowCode				= GoodsTable.RowCode
	|			AND StageDetails.Organization IN (&SFIFOOrganizationsSliding)
	|
	|		LEFT JOIN LotsOfGNZPMaterials AS LotsOfGNZPMaterials
	|		ON LotsOfGNZPMaterials.ProductionLot = ProductionLots.ProductionLot
	|			AND LotsOfGNZPMaterials.BatchOfMaterial = StageDetails.Ref
	|			AND (LotsOfGNZPMaterials.LotVendorAttributes = AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey
	|				OR LotsOfGNZPMaterials.LotVendorAttributes = BatchAccountingAnalysts.DimensionKey)
	|			AND LotsOfGNZPMaterials.Organization = StageDetails.Organization
	|
	|WHERE
	|	NOT StageDetails.ProductionByThirdParty
	|	AND StageDetails.Posted
	|	AND NOT GoodsTable.Canceled
	|	AND ProductionLots.CostAllocationForIssue
	|	AND (GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND NOT GoodsTable.Products.TracedGoods
	|		OR NOT GoodsTable.Manufactured)
	|
	|
	|GROUP BY
	|	ProductionLots.ProductionLot,
	|	StageDetails.Ref,
	|	GoodsTable.ProductionDate,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN ISNULL(BatchAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
	|		ELSE ISNULL(AnalysisOfAccountingOfBatchesOfGoods_.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))
	|	END,
	|	ProductionLots.FinancialAccountingDimension,
	|	ProductionLots.Organization,
	|	GoodsTable.Department,
	|	StageDetails.ProductionIssueForActivity,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	StageDetails.BillOfMaterials,
	|	GoodsTable.RowID,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END,
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension";
	#EndRegion

	
	// plan and fact according to the reports of processors 2.5 by stages (work)
	#Region TextvtManufacturedProducts_ReportsOfProcessors25ByStages_OfWork
	TextvtManufacturedProducts_ReportsOfProcessors25ByStages_OfWork = "
	|SELECT
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
	|	ProductionLots.ProductionLot			AS ProductionLot,
	|	ReportDetails_.Ref							AS ReleaseParty,
	|	ReportDetails_.Date							AS ProductionDate,
	|	ISNULL(PartyAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)) AS LotVendorAttributes,
	|	ProductionLots.FinancialAccountingDimension	AS FinancialAccountingDimension,
	|	ReportDetails_.Organization						AS Organization,
	|	ReportDetails_.Department					AS Department,
	|	ReportDetails_.PurchaseForActivity			AS VATActivityType,
	|	GoodsTable.Products						AS Products,
	|	GoodsTable.Characteristic					AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	StageDetails.BillOfMaterials						AS BillOfMaterials,
	|	GoodsTable.RowID				AS RowID,
	|	GoodsTable.RowID				AS FinRecordID,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END											AS ItemsLocationAttributes,
	|	UNDEFINED									AS ExpenseItemOfWriteOff,
	|	UNDEFINED									AS AssetAndLiabilityItem,
	|	UNDEFINED									AS DimensionOfExpenses,
	|	UNDEFINED									AS AssetsLiabilitiesDimension,
	|	SUM(CASE
	|			WHEN ReportDetails_.Date <= &EndOfPeriod
	|				THEN GoodsTable.Count
	|			ELSE 0
	|		END)										AS Real,
	|	CASE
	|		WHEN MAX(ProcessingShares.CountReal) = 0 THEN 0
	|		ELSE 
	|			SUM(CASE
	|					WHEN ReportDetails_.Date <= &EndOfPeriod
	|						THEN GoodsTable.Count
	|					ELSE 0
	|				END) / MAX(ProcessingShares.CountReal) *
	|			MAX(ProcessingShares.CountPlan) 
	|	END AS Plan,
	|	SUM(CASE
	|			WHEN ReportDetails_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|				THEN GoodsTable.Count
	|			ELSE 0
	|		END)										AS ProductsQuantity,
	|	SUM(CASE
	|			WHEN ReportDetails_.Date <= &EndOfPeriod
	|				THEN CASE
	|						WHEN GoodsTable.CostShare = 0
	|							THEN GoodsTable.Count
	|						ELSE GoodsTable.CostShare
	|					END
	|			ELSE 0
	|	END)											AS ShareCostFact,
	|	MAX(ProcessingShares.ShareCostPlan)	AS CostShare,
	|	MAX(ProcessingShares.ShareCostPlan)	AS FullShareOfValue
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|
	|		INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|		ON StageDetails.Ref = GoodsTable.ProductionStage
	|
	|		INNER JOIN ProductionBatchesAreSummarized AS ProductionLots
	|		ON ProductionLots.ProductionLot = StageDetails.ProductionLot
	|
	|		INNER JOIN Document.SubcontractorReport2_5 AS ReportDetails_
	|		ON ReportDetails_.Ref = GoodsTable.Ref
	|		AND ReportDetails_.Posted
	|
	|		INNER JOIN TTShareProcessing AS ProcessingShares
	|		ON ProcessingShares.ProductionLot = ProductionLots.ProductionLot
	|			AND ProcessingShares.Products = GoodsTable.Products
	|			AND ProcessingShares.Characteristic = GoodsTable.Characteristic
	|			AND ProcessingShares.RowCode = GoodsTable.RowCode
	|
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|
	|		LEFT JOIN InformationRegister.LotVendorAttributes AS PartyAccountingAnalysts
	|		ON PartyAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|			AND PartyAccountingAnalysts.Vendor				= VALUE(Catalog.Partners.EmptyRef)
	|			AND PartyAccountingAnalysts.Counterparty				= UNDEFINED
	|			AND PartyAccountingAnalysts.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
	|			AND PartyAccountingAnalysts.VATTaxation		= VALUE(Enum.VATTaxationTypes.EmptyRef) // in case of PU 2.2 taxation, the application form is not filled in
	|			AND PartyAccountingAnalysts.AssetTaxClass				= VALUE(Enum.AssetKinds.Goods)
	|			AND PartyAccountingAnalysts.RowCode				= GoodsTable.RowCodeProducts
	|			AND ReportDetails_.Organization IN (&SFIFOOrganizationsSliding)
	|
	|WHERE
	|	GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND ProductionLots.CostAllocationForIssue
	|	AND NOT GoodsTable.Products.TracedGoods
	|
	|GROUP BY
	|	ProductionLots.ProductionLot,
	|	ReportDetails_.Ref,
	|	ReportDetails_.Date,
	|	ISNULL(PartyAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)),
	|	ProductionLots.FinancialAccountingDimension,
	|	ReportDetails_.Organization,
	|	ReportDetails_.Department,
	|	ReportDetails_.PurchaseForActivity,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	StageDetails.BillOfMaterials,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END,
	|	GoodsTable.RowID";
	#EndRegion
	
	// plan and fact according to the reports of processors 2.5 by stages for goods
	#Region TextvtManufacturingProducts_ReportsOf25ProcessorsByStages_Goods
	TextvtManufacturingProducts_ReportsOf25ProcessorsByStages_Goods = "
	|SELECT
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	CASE
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners)
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		  OR GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners)
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|	END AS AccountingSection,
	|	ProductionLots.ProductionLot			AS ProductionLot,
	|	ReportDetails_.Ref							AS ReleaseParty,
	|	ReportDetails_.Date							AS ProductionDate,
	|	ISNULL(PartyAccountingAnalysts.DimensionKey,
	|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)) AS LotVendorAttributes,
	|	ProductionLots.FinancialAccountingDimension	AS FinancialAccountingDimension,
	|	ReportDetails_.Organization						AS Organization,
	|	ReportDetails_.Department					AS Department,
	|	ReportDetails_.PurchaseForActivity			AS VATActivityType,
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	StageDetails.BillOfMaterials						AS BillOfMaterials,
	|	GoodsTable.RowID				AS RowID,
	|	GoodsTable.FinRecordID			AS FinRecordID,
	|	GoodsTable.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END											AS ItemsLocationAttributes,
	|	UNDEFINED									AS ExpenseItemOfWriteOff,
	|	UNDEFINED									AS AssetAndLiabilityItem,
	|	UNDEFINED									AS DimensionOfExpenses,
	|	UNDEFINED									AS AssetsLiabilitiesDimension,
	|	SUM(CASE
	|			WHEN ReportDetails_.Date <= &EndOfPeriod
	|				THEN GoodsTable.Count
	|			ELSE 0
	|		END)										AS Real,
	|	CASE
	|		WHEN MAX(ProcessingShares.CountReal) = 0 THEN 0
	|		ELSE 
	|			SUM(CASE
	|					WHEN ReportDetails_.Date <= &EndOfPeriod
	|						THEN GoodsTable.Count
	|					ELSE 0
	|				END) / MAX(ProcessingShares.CountReal) *
	|			MAX(ProcessingShares.CountPlan)
	|	END AS Plan,
	|	SUM(CASE
	|			WHEN ReportDetails_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|				THEN GoodsTable.Count
	|			ELSE 0
	|		END)										AS ProductsQuantity,
	|	SUM(CASE
	|			WHEN ReportDetails_.Date <= &EndOfPeriod
	|				THEN CASE
	|						WHEN GoodsTable.CostShare = 0
	|							THEN GoodsTable.Count
	|						ELSE GoodsTable.CostShare
	|					END
	|			ELSE 0
	|	END)											AS ShareCostFact,
	|	MAX(ProcessingShares.ShareCostPlan)	AS CostShare,
	|	MAX(ProcessingShares.ShareCostPlan)	AS FullShareOfValue
	|FROM
	|	Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS GoodsTable
	|
	|		INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|		ON StageDetails.Ref = GoodsTable.ProductionStage
	|
	|		INNER JOIN ProductionBatchesAreSummarized AS ProductionLots
	|		ON ProductionLots.ProductionLot = StageDetails.ProductionLot
	|
	|		INNER JOIN Document.SubcontractorReport2_5 AS ReportDetails_
	|		ON ReportDetails_.Ref = GoodsTable.Ref
	|		AND ReportDetails_.Posted
	|
	|		INNER JOIN Document.SubcontractorReport2_5.ManufacturedProducts AS TSManufacturedProducts
	|		ON GoodsTable.Ref = TSManufacturedProducts.Ref
	|			AND GoodsTable.RowCodeProducts = TSManufacturedProducts.RowCodeProducts
	|
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|
	|		INNER JOIN TTShareProcessing AS ProcessingShares
	|		ON ProcessingShares.ProductionLot = ProductionLots.ProductionLot
	|			AND ProcessingShares.Products = Dimension.Products
	|			AND ProcessingShares.Characteristic = Dimension.Characteristic
	|			AND ProcessingShares.RowCode = TSManufacturedProducts.RowCode
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|
	|		LEFT JOIN InformationRegister.LotVendorAttributes AS PartyAccountingAnalysts
	|		ON PartyAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|			AND PartyAccountingAnalysts.Vendor				= VALUE(Catalog.Partners.EmptyRef)
	|			AND PartyAccountingAnalysts.Counterparty				= UNDEFINED
	|			AND PartyAccountingAnalysts.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
	|			AND PartyAccountingAnalysts.VATTaxation		= VALUE(Enum.VATTaxationTypes.EmptyRef) // in case of PU 2.2 taxation, the application form is not filled in
	|			AND PartyAccountingAnalysts.AssetTaxClass				= VALUE(Enum.AssetKinds.Goods)
	|			AND PartyAccountingAnalysts.RowCode				= GoodsTable.RowCodeProducts
	|			AND ReportDetails_.Organization IN (&SFIFOOrganizationsSliding)
	|WHERE
	|	NOT GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|	AND ProductionLots.CostAllocationForIssue
	|
	|GROUP BY
	|	CASE
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners)
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		  OR GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners)
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|	END,
	|	ProductionLots.ProductionLot,
	|	ReportDetails_.Ref,
	|	ReportDetails_.Date,
	|	ISNULL(PartyAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)),
	|	ProductionLots.FinancialAccountingDimension,
	|	ReportDetails_.Organization,
	|	ReportDetails_.Department,
	|	ReportDetails_.PurchaseForActivity,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	GoodsTable.InventoryOwnerAttribute,
	|	StageDetails.BillOfMaterials,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END,
	|	GoodsTable.RowID,
	|	GoodsTable.FinRecordID";
	#EndRegion
	
	
	// plan and fact according to the reports of processors 2.5 without work stages
	#Region TextvtManufacturedProducts_ReportsOfProcessors25WithoutStages_OfWork
	TextvtManufacturedProducts_ReportsOfProcessors25WithoutStages_OfWork = "
	|SELECT
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
	|	ProductionLots.ProductionLot			AS ProductionLot,
	|	ReportDetails_.Ref							AS ReleaseParty,
	|	ReportDetails_.Date							AS ProductionDate,
	|	ISNULL(PartyAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)) AS LotVendorAttributes,
	|	ProductionLots.FinancialAccountingDimension	AS FinancialAccountingDimension,
	|	ReportDetails_.Organization						AS Organization,
	|	ReportDetails_.Department					AS Department,
	|	ReportDetails_.PurchaseForActivity			AS VATActivityType,
	|	TableOfGoods.Products						AS Products,
	|	TableOfGoods.Characteristic					AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	TableOfGoods.BillOfMaterials						AS BillOfMaterials,
	|	TableOfGoods.RowID				AS RowID,
	|	TableOfGoods.RowID				AS FinRecordID,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableOfGoods.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END											AS ItemsLocationAttributes,
	|	UNDEFINED									AS ExpenseItemOfWriteOff,
	|	UNDEFINED									AS AssetAndLiabilityItem,
	|	UNDEFINED									AS DimensionOfExpenses,
	|	UNDEFINED									AS AssetsLiabilitiesDimension,
	|	SUM(TableOfGoods.Count)				AS Real,
	|	SUM(TableOfGoods.Count)				AS Plan,
	|	SUM(TableOfGoods.Count)				AS ProductsQuantity,
	|	SUM(CASE
	|			WHEN TableOfGoods.CostShare = 0
	|				THEN TableOfGoods.Count
	|			ELSE TableOfGoods.CostShare
	|		END)										AS ShareCostFact,
	|	SUM(CASE
	|			WHEN TableOfGoods.CostShare = 0
	|				THEN TableOfGoods.Count
	|			ELSE TableOfGoods.CostShare
	|		END)										AS CostShare,
	|	SUM(CASE
	|			WHEN TableOfGoods.CostShare = 0
	|				THEN TableOfGoods.Count
	|			ELSE TableOfGoods.CostShare
	|		END)										AS FullShareOfValue
	|FROM
	|	ProductionBatchesAreSummarized AS ProductionLots
	|
	|		INNER JOIN Document.SubcontractorReport2_5.ManufacturedProducts AS TableOfGoods
	|		ON ProductionLots.DocumentLots = TableOfGoods.Ref
	|			AND ProductionLots.CostGroupNumber = TableOfGoods.CostGroupNumber
	|
	|		INNER JOIN Document.SubcontractorReport2_5 AS ReportDetails_
	|		ON ReportDetails_.Ref = TableOfGoods.Ref
	|		AND ReportDetails_.Posted
	|
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|
	|		LEFT JOIN InformationRegister.LotVendorAttributes AS PartyAccountingAnalysts
	|		ON PartyAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|			AND PartyAccountingAnalysts.Vendor				= VALUE(Catalog.Partners.EmptyRef)
	|			AND PartyAccountingAnalysts.Counterparty				= UNDEFINED
	|			AND PartyAccountingAnalysts.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
	|			AND PartyAccountingAnalysts.VATTaxation		= VALUE(Enum.VATTaxationTypes.EmptyRef) // in case of PU 2.2 taxation, the application form is not filled in
	|			AND PartyAccountingAnalysts.AssetTaxClass				= VALUE(Enum.AssetKinds.Goods)
	|			AND PartyAccountingAnalysts.RowCode				= TableOfGoods.RowCodeProducts
	|			AND ProductionLots.Organization IN (&SFIFOOrganizationsSliding)
	|
	|WHERE
	|	TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND ProductionLots.CostAllocationForIssue
	|	AND NOT TableOfGoods.Products.TracedGoods
	|
	|GROUP BY
	|	ProductionLots.ProductionLot,
	|	ReportDetails_.Ref,
	|	ReportDetails_.Date,
	|	ISNULL(PartyAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)),
	|	ProductionLots.FinancialAccountingDimension,
	|	ReportDetails_.Organization,
	|	ReportDetails_.Department,
	|	ReportDetails_.PurchaseForActivity,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.BillOfMaterials,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableOfGoods.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END,
	|	TableOfGoods.RowID";
	#EndRegion
	
	// plan and fact according to the reports of processors 2.5 without stages for goods
	#Region TextvtManufacturedProducts_ReportsOfProcessors25WithoutStages_Goods
	TextvtManufacturedProducts_ReportsOfProcessors25WithoutStages_Goods = "
	|SELECT
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	CASE
	|		WHEN TableOfGoods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners)
	|		WHEN TableOfGoods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		  OR TableOfGoods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners)
	|		WHEN TableOfGoods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|	END AS AccountingSection,
	|	ProductionLots.ProductionLot			AS ProductionLot,
	|	ReportDetails_.Ref							AS ReleaseParty,
	|	ReportDetails_.Date							AS ProductionDate,
	|	ISNULL(PartyAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)) AS LotVendorAttributes,
	|	ProductionLots.FinancialAccountingDimension	AS FinancialAccountingDimension,
	|	ReportDetails_.Organization						AS Organization,
	|	ReportDetails_.Department					AS Department,
	|	ReportDetails_.PurchaseForActivity			AS VATActivityType,
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
	|	TableOfGoods.RowID				AS RowID,
	|	TableOfGoods.FinRecordID			AS FinRecordID,
	|	TableOfGoods.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableOfGoods.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END											AS ItemsLocationAttributes,
	|	UNDEFINED									AS ExpenseItemOfWriteOff,
	|	UNDEFINED									AS AssetAndLiabilityItem,
	|	UNDEFINED									AS DimensionOfExpenses,
	|	UNDEFINED									AS AssetsLiabilitiesDimension,
	|	SUM(TableOfGoods.Count)				AS Real,
	|	SUM(TableOfGoods.Count)				AS Plan,
	|	SUM(TableOfGoods.Count)				AS ProductsQuantity,
	|	SUM(CASE
	|			WHEN TableOfGoods.CostShare = 0
	|				THEN TableOfGoods.Count
	|			ELSE TableOfGoods.CostShare
	|		END)										AS ShareCostFact,
	|	SUM(CASE
	|			WHEN TableOfGoods.CostShare = 0
	|				THEN TableOfGoods.Count
	|			ELSE TableOfGoods.CostShare
	|		END)										AS CostShare,
	|	SUM(CASE
	|			WHEN TableOfGoods.CostShare = 0
	|				THEN TableOfGoods.Count
	|			ELSE TableOfGoods.CostShare
	|		END)										AS FullShareOfValue
	|FROM
	|	ProductionBatchesAreSummarized AS ProductionLots
	|
	|		INNER JOIN Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS TableOfGoods
	|		ON ProductionLots.DocumentLots = TableOfGoods.Ref
	|			AND ProductionLots.CostGroupNumber = TableOfGoods.CostGroupNumber
	|
	|		INNER JOIN Document.SubcontractorReport2_5 AS ReportDetails_
	|		ON ReportDetails_.Ref = TableOfGoods.Ref
	|		AND ReportDetails_.Posted
	|
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|
	|		LEFT JOIN InformationRegister.LotVendorAttributes AS PartyAccountingAnalysts
	|		ON PartyAccountingAnalysts.FinancialAccountingGroup	= VALUE(Catalog.InventoryAccountingGroups.EmptyRef)
	|			AND PartyAccountingAnalysts.Vendor				= VALUE(Catalog.Partners.EmptyRef)
	|			AND PartyAccountingAnalysts.Counterparty				= UNDEFINED
	|			AND PartyAccountingAnalysts.VATRate				= VALUE(Catalog.VATRates.EmptyRef)
	|			AND PartyAccountingAnalysts.VATTaxation		= VALUE(Enum.VATTaxationTypes.EmptyRef) // in case of PU 2.2 taxation, the application form is not filled in
	|			AND PartyAccountingAnalysts.AssetTaxClass				= VALUE(Enum.AssetKinds.Goods)
	|			AND PartyAccountingAnalysts.RowCode				= TableOfGoods.RowCodeProducts
	|			AND ProductionLots.Organization IN (&SFIFOOrganizationsSliding)
	|
	|WHERE
	|	NOT TableOfGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|	AND ProductionLots.CostAllocationForIssue
	|
	|GROUP BY
	|	CASE
	|		WHEN TableOfGoods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners)
	|		WHEN TableOfGoods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		  OR TableOfGoods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners)
	|		WHEN TableOfGoods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|	END,
	|	ProductionLots.ProductionLot,
	|	ReportDetails_.Ref,
	|	ReportDetails_.Date,
	|	ISNULL(PartyAccountingAnalysts.DimensionKey, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)),
	|	ProductionLots.FinancialAccountingDimension,
	|	ReportDetails_.Organization,
	|	ReportDetails_.Department,
	|	ReportDetails_.PurchaseForActivity,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	TableOfGoods.InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableOfGoods.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END,
	|	TableOfGoods.RowID,
	|	TableOfGoods.FinRecordID";
	#EndRegion
	
	
	// Plan and fact Report to giver between organizations on untraceable works
	#Region TextvtManufacturedProducts_ReportToGiverBetweenOrganizations_Work
	
	TextvtManufacturedProducts_ReportToGiverBetweenOrganizations_Work = "
	|SELECT
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
	|	ProductionLots.ProductionLot			AS ProductionLot,
	|	ReportDetails_.Ref							AS ReleaseParty,
	|	ReportDetails_.Date							AS ProductionDate,
	|	ISNULL(T.LotVendorAttributesCorr,
	|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)) AS LotVendorAttributes,
	|	ProductionLots.FinancialAccountingDimension	AS FinancialAccountingDimension,
	|	ReportDetails_.Organization						AS Organization,
	|	ReportDetails_.Department					AS Department,
	|	ProductionLots.VATActivityType			AS VATActivityType,
	|	Dimension.Products										AS Products,
	|	Dimension.Characteristic									AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef)			AS Series,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)		AS BillOfMaterials,
	|	GoodsTable.RowID				AS RowID,
	|	GoodsTable.RowID				AS FinRecordID,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END											AS ItemsLocationAttributes,
	|	UNDEFINED									AS ExpenseItemOfWriteOff,
	|	UNDEFINED									AS AssetAndLiabilityItem,
	|	UNDEFINED									AS DimensionOfExpenses,
	|	UNDEFINED									AS AssetsLiabilitiesDimension,
	|	SUM(CASE
	|			WHEN ReportDetails_.Date <= &EndOfPeriod
	|				THEN GoodsTable.Count
	|			ELSE 0
	|		END)										AS Real,
	|	SUM(CASE
	|			WHEN ReportDetails_.Date <= &EndOfPeriod
	|				THEN GoodsTable.Count
	|			ELSE 0
	|		END)										AS Plan,
	|	SUM(CASE
	|			WHEN ReportDetails_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|				THEN GoodsTable.Count
	|			ELSE 0
	|		END)										AS ProductsQuantity,
	|	SUM(CASE
	|			WHEN ReportDetails_.Date <= &EndOfPeriod
	|				THEN CASE
	|						WHEN GoodsTable.CostShare = 0
	|							THEN GoodsTable.Count
	|						ELSE GoodsTable.CostShare
	|					END
	|			ELSE 0
	|		END)										AS ShareCostFact,
	|	SUM(CASE
	|			WHEN GoodsTable.CostShare = 0
	|				THEN GoodsTable.Count
	|			ELSE GoodsTable.CostShare
	|		END)										AS CostShare,
	|	SUM(CASE
	|			WHEN GoodsTable.CostShare = 0
	|				THEN GoodsTable.Count
	|			ELSE GoodsTable.CostShare
	|		END)										AS FullShareOfValue
	|FROM
	|	ProductionBatchesByStages AS ProductionLots
	|		
	|		INNER JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany AS ReportDetails_
	|		ON ReportDetails_.Ref = ProductionLots.Stage
	|		AND ReportDetails_.Organization = ProductionLots.Organization
	|		AND ReportDetails_.Posted
	|		AND NOT ReportDetails_.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|		
	|		INNER JOIN Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Goods AS GoodsTable
	|		ON GoodsTable.Ref = ReportDetails_.Ref
	|		AND GoodsTable.ProductionLot = ProductionLots.ProductionLot
	|
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|
	|		LEFT JOIN AccumulationRegister.InventoryCost AS T
	|		ON T.Recorder = ReportDetails_.Ref
	|			AND T.RowID = GoodsTable.RowID
	|			AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|			AND NOT T.LotCalculation 
	|			AND NOT T.CalculationOfCost
	|			AND ReportDetails_.Organization IN (&SFIFOOrganizationsSliding)
	|
	|	WHERE
	|		ProductionLots.CostAllocationForIssue
	|		AND NOT Dimension.Products.TracedGoods
	|
	|GROUP BY
	|	ReportDetails_.Organization,
	|	ProductionLots.ProductionLot,
	|	ReportDetails_.Ref,
	|	ReportDetails_.Date,
	|	ISNULL(T.LotVendorAttributesCorr, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)),
	|	ProductionLots.FinancialAccountingDimension,
	|	ReportDetails_.Department,
	|	ProductionLots.VATActivityType,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE
	|			AnalyticsWithoutAssignment.DimensionKey
	|	END,
	|	GoodsTable.RowID
	|";
	#EndRegion
	IndexvtManufacturedProducts = "
	|INDEX BY
	|	ProductionLot";
	
	#Region TextvtSharesTotal
	TextvtSharesTotal = "
	// The results of the distribution shares by production lots 
	// (except recycling on side 2.5)
	|SELECT
	|	DD.ProductionLot				AS ProductionLot,
	|	DD.Organization						AS Organization,
	|	SUM(
	|		CASE
	|			WHEN DD.CostShare < 0
	|				THEN 0
	|			ELSE DD.CostShare
	|		END)							AS AmountOfSharesByStage,
	|	SUM(
	|		CASE
	|			WHEN DD.FullShareOfValue < 0
	|				THEN 0
	|			ELSE DD.FullShareOfValue
	|		END)							AS SumOfTotalSharesByStage,
	|	MIN(CASE
	|		WHEN DD.Real <> DD.Plan
	|			THEN FALSE
	|		ELSE TRUE
	|	END)								AS ProductionCompleted
	|INTO TTSharesTotal
	|FROM
	|	TTManufacturedProduct AS DD
	|WHERE
	|	NOT DD.ReleaseParty REFS Document.SubcontractorReport2_5
	|
	|GROUP BY
	|	DD.ProductionLot,
	|	DD.Organization
	|
	|UNION ALL
	|
	// The results of the distribution shares by production batches performed by the processor on the 2.5 side 
	// (the summation of the shares is not applied for them, because the initial data will already delay the sum of the shares from the processing)
	|SELECT
	|	DD.ProductionLot				AS ProductionLot,
	|	DD.Organization						AS Organization,
	|	MIN(
	|		CASE
	|			WHEN DD.CostShare < 0 
	|				THEN 0 
	|			ELSE DD.CostShare 
	|		END)							AS AmountOfSharesByStage,
	|	MIN(
	|		CASE
	|			WHEN DD.FullShareOfValue < 0 
	|				THEN 0 
	|			ELSE DD.FullShareOfValue 
	|		END)							AS SumOfTotalSharesByStage,
	|	MIN(CASE
	|		WHEN DD.Real <> DD.Plan
	|			THEN FALSE
	|		ELSE TRUE
	|	END)								AS ProductionCompleted
	|FROM
	|	TTManufacturedProduct AS DD
	|WHERE
	|	DD.ReleaseParty REFS Document.SubcontractorReport2_5
	|
	|GROUP BY
	|	DD.ProductionLot,
	|	DD.Organization
	|
	|INDEX BY
	|	Organization,
	|	ProductionLot";
	#EndRegion
	
	#Region TextProducts_
	TextProducts_ = "
	|SELECT
	|	DD.BusinessOperation			AS BusinessOperation,
	|	(CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		ELSE DD.AccountingSection END) AS AccountingSection,
	|	DD.ProductionLot				AS ProductionLot,
	|	DD.ReleaseParty					AS ReleaseParty,
	|	DD.ProductionDate					AS ProductionDate,
	|	DD.LotVendorAttributes				AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension		AS FinancialAccountingDimension,
	|	DD.Organization						AS Organization,
	|	DD.VATActivityType				AS VATActivityType,
	|	DD.Department					AS Department,
	|	DD.Products						AS Products,
	|	DD.Characteristic					AS Characteristic,
	// When pricing 2.5, it is not supported to indicate the planned price in the context of packages.
	// The value will be determined by the price for the storage unit.
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	DD.Series							AS Series,
	|	DD.BillOfMaterials						AS BillOfMaterials,
	|	DD.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DD.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	DD.ProductsQuantity				AS ProductsQuantity,
	|	DD.ExpenseItemOfWriteOff			AS ExpenseItemOfWriteOff,
	|	DD.DimensionOfExpenses				AS DimensionOfExpenses,
	|	DD.AssetAndLiabilityItem			AS AssetAndLiabilityItem,
	|	DD.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	DD.RowID				AS RowID,
	|	DD.FinRecordID			AS FinRecordID,
	|	DD.Real								AS Real,
	|	DD.Plan								AS Plan,
	|	DD.CostShare					AS CostShare,
	|	DD.FullShareOfValue				AS FullShareOfValue,
	|	CASE
	|		WHEN TotalShares_.SumOfTotalSharesByStage = 0
	|			OR DD.Plan = 0
	|			THEN 0
	|		ELSE CAST(DD.FullShareOfValue / TotalShares_.SumOfTotalSharesByStage * (DD.Real / DD.Plan) AS NUMBER(23,10))
	|	END								AS FullShareOfTotalName,
	|	CASE
	|		WHEN TotalShares_.SumOfTotalSharesByStage = 0
	|			OR DD.Plan = 0
	|			THEN 0
	|		ELSE CAST(DD.FullShareOfValue / TotalShares_.SumOfTotalSharesByStage * (DD.ProductsQuantity / DD.Plan) AS NUMBER(23,10))
	|	END								AS FullShareOfMonthName,
	|	CASE
	|		WHEN TotalShares_.AmountOfSharesByStage = 0
	|			OR DD.Plan = 0
	|			THEN 0
	|		ELSE CAST(DD.CostShare / TotalShares_.AmountOfSharesByStage * (DD.Real / DD.Plan) AS NUMBER(23,10))
	|	END								AS ShareOfTotalName,
	|	CASE
	|		WHEN TotalShares_.AmountOfSharesByStage = 0 
	|			OR DD.Plan = 0
	|			THEN 0
	|		ELSE CAST(DD.CostShare / TotalShares_.AmountOfSharesByStage * (DD.ProductsQuantity / DD.Plan) AS NUMBER(23,10))
	|	END								AS ShareOfMonthName,
	|	TotalShares_.ProductionCompleted		AS ProductionCompleted
	|INTO ManufacturedProduct
	|FROM
	|	TTManufacturedProduct AS DD
	|
	|	INNER JOIN TTSharesTotal AS TotalShares_
	|	ON DD.ProductionLot = TotalShares_.ProductionLot
	|		AND DD.Organization = TotalShares_.Organization
	|
	|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
	|		ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
	|
	|INDEX BY
	|	ProductionLot";
	#EndRegion
	
	#Region TextOfIssueShare
	TextOfIssueShare = "
	|SELECT
	|	DD.ProductionLot					AS ProductionLot,
	|	DD.ProductionCompleted				AS ProductionCompleted,
	|	DD.Organization							AS Organization,
	|	SUM(DD.ShareOfTotalName)			AS ShareOfTotalOutput,
	|	SUM(DD.ShareOfMonthName)		AS ShareOfIssueOfMonth
	|INTO ReleaseShares
	|FROM
	|	ManufacturedProduct AS DD
	|
	|GROUP BY
	|	DD.ProductionLot,
	|	DD.ProductionCompleted,
	|	DD.Organization
	|
	|INDEX BY
	|	Organization,
	|	ProductionLot";
	#EndRegion
	
	#Region TextClosedParties
	TextClosedParties = "
	|SELECT
	|	LotsOfGNZPMaterials.ProductionLot			AS ProductionLot,
	|	ManufacturedProduct.ReleaseParty							AS ReleaseParty,
	|	LotsOfGNZPMaterials.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	SUM(LotsOfGNZPMaterials.Count)			AS Count
	|INTO ClosedParties
	|FROM
	|	LotsOfGNZPMaterials AS LotsOfGNZPMaterials
	|	INNER JOIN ManufacturedProduct AS ManufacturedProduct
	|		ON LotsOfGNZPMaterials.ProductionLot = ManufacturedProduct.ProductionLot
	|		AND LotsOfGNZPMaterials.BatchOfMaterial = ManufacturedProduct.ReleaseParty
	|		AND LotsOfGNZPMaterials.LotVendorAttributes = ManufacturedProduct.LotVendorAttributes
	|		AND LotsOfGNZPMaterials.Organization = ManufacturedProduct.Organization
	|
	|GROUP BY
	|	LotsOfGNZPMaterials.ProductionLot,
	|	ManufacturedProduct.ReleaseParty,
	|	LotsOfGNZPMaterials.ItemsLocationAttributes";
	#EndRegion	
	
	TextyvtManufacturingProducts = New Array;
	TextyvtManufacturingProducts.Add(TextvtManufacturedProducts_DataDescription);
	TextyvtManufacturingProducts.Add(TextvtManufacturedProducts_PBZ_Goods);
	TextyvtManufacturingProducts.Add(TextvtManufacturedProducts_PBZ_Works);
	TextyvtManufacturingProducts.Add(TextvtManufacturedProducts_Stages_Goods);
	TextyvtManufacturingProducts.Add(TextvtManufacturedProducts_Stages_OfWork);
	TextyvtManufacturingProducts.Add(TextvtManufacturingProducts_ReportsOf25ProcessorsByStages_Goods);
	TextyvtManufacturingProducts.Add(TextvtManufacturedProducts_ReportsOfProcessors25ByStages_OfWork);
	TextyvtManufacturingProducts.Add(TextvtManufacturedProducts_ReportsOfProcessors25WithoutStages_OfWork);
	TextyvtManufacturingProducts.Add(TextvtManufacturedProducts_ReportsOfProcessors25WithoutStages_Goods);
	TextyvtManufacturingProducts.Add(TextvtManufacturedProducts_ReportToGiverBetweenOrganizations_Work);
	TextvtManufacturedProducts = 
		StrConcat(TextyvtManufacturingProducts, TMCommonUse.QuerySeparatorInJoin()) + IndexvtManufacturedProducts;

	QueryTexts = New Array;
	QueryTexts.Add(TextvtSharesForProcessing);
	QueryTexts.Add(TextvtManufacturedProducts);
	QueryTexts.Add(TextvtSharesTotal);
	QueryTexts.Add(TextProducts_);
	QueryTexts.Add(TextOfIssueShare);
	QueryTexts.Add(TextClosedParties);
	QueryTexts.Add("");

	Return StrConcat(QueryTexts, TMCommonUse.RequestSeparatorInPacket_());
	
EndFunction

// Tables: Dataproducts
// 
// Returns:
// 	String - Query text
Function TextOutputData() Export
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	QueriesTexts = New Array;
	
	QueryText = "
	|SELECT
	|	TableOfGoods.ProductionDate					AS ProductionDate,
	|	TableOfGoods.Organization						AS Organization,
	|	TableOfGoods.Department					AS Department,
	|	TableOfGoods.Products						AS Products,
	|	TableOfGoods.Characteristic					AS Characteristic,
	|	ProductionLots.FinancialAccountingDimension	AS ProductsGroup,
	|	TableOfGoods.ProductionLot				AS ProductionLot,
	|	ProductionLots.VATActivityType			AS VATActivityType,
	|	ProductionLots.Purpose					AS Purpose,
	|	ProductionLots.LineOfBusiness		AS LineOfBusiness,
	|	UNDEFINED									AS ProductionOrder,
	|	0												AS RowCodeProducts,
	|	&PricingFields,
	|	TableOfGoods.ProductsQuantity				AS Count,
	|	TableOfGoods.Plan - TableOfGoods.Real		AS CountPlan
	|INTO ProductDataWithoutPrices
	|FROM
	|	ManufacturedProduct AS TableOfGoods
	|	
	|	INNER JOIN ProductionBatchesAreSummarized AS ProductionLots
	|	ON ProductionLots.ProductionLot = TableOfGoods.ProductionLot
	|	AND ProductionLots.Organization = TableOfGoods.Organization
	|	
	|	LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|	ON ItemKinds.Ref = TableOfGoods.Products.ProductKind
	|	
	|WHERE
	|	TableOfGoods.FullShareOfMonthName > 0 OR &ConsiderFutureReleases";
	
	PricingSettings = PriceManagementSystemClientServer.SettingsForTemporaryTableWithAdditionForPricing();
	PricingSettings.SourceOfGoods = "TableOfGoods";
	ReplacementText = PriceManagementSystemClientServer.TextOfFieldsForPricing(PricingSettings);
	If ValueIsFilled(ReplacementText) Then
		QueryText = StrReplace(QueryText, "&PricingFields", ReplacementText);
	Else
		QueryText = StrReplace(QueryText, "&PricingFields,", "");
	EndIf;
		
	QueriesTexts.Add(QueryText);
	

	
	TT_ProductDataWithoutPrices = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin()) 
		+ Common.QueryBatchSeparator();
		
	QueryText = "
	|SELECT
	|	DD.ProductionDate									AS ProductionDate,
	|	DD.Organization										AS Organization,
	|	DD.Department									AS Department,
	|	VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement,
	|	DD.Products										AS ManufacturedProduct,
	|	DD.ProductsGroup												AS ProductsGroup,
	|	DD.ProductionLot								AS ProductionLot,
	|	DD.VATActivityType								AS VATActivityType,
	|	DD.Purpose										AS Purpose,
	|	DD.LineOfBusiness							AS LineOfBusiness,
	|	DD.ProductionOrder								AS ProductionOrder,
	|	DD.RowCodeProducts								AS RowCodeProducts,
	|	DD.Count										AS Count,
	|	&VolumeM3 * DD.Count								AS VolumeM3,
	|	&Weight * DD.Count								AS Weight,
	|	ISNULL(ItemsPrices.Price, 0) 
	|		* DD.Count									AS Cost,
	|	DD.CountPlan									AS CountPlan,
	|	&VolumeM3 * DD.CountPlan							AS ScopePlan,
	|	&Weight * DD.CountPlan							AS WeightPlan,
	|	ISNULL(ItemsPrices.Price, 0) 
	|		* DD.CountPlan								AS CostPlan
	|INTO ProductData_6
	|FROM
	|	ProductDataWithoutPrices AS DD
	|		INNER JOIN Catalog.Products AS SN
	|			ON (SN.Ref = DD.Products)
	|		LEFT JOIN Catalog.ItemsCharacteristics AS SH
	|			ON SH.Ref = DD.Characteristic
	|		LEFT JOIN
	|			&ItemsPrices AS ItemsPrices
	|		ON 
	|			&ItemPriceConnectionCondition
	|";
	
	QueryText = StrReplace(QueryText,
		"&ItemsPrices",
		PriceManagementSystemClientServer.QueryTextInformationRegisterItemsPrices(
			"ProductDataWithoutPrices",
			"&EndOfPeriod",
			New Structure("Parameter", "&TypeOfPlannedPrices"),
			UsePriceManagementSystem25)
	);
	QueryText = StrReplace(QueryText,
		"&ItemPriceConnectionCondition",
		PriceManagementSystemClientServer.RequestTextInformationRegisterItemPricesConnectionCondition(
			"DD",
			"ItemsPrices",
			,
			UsePriceManagementSystem25)
	);
	
	Return TT_ProductDataWithoutPrices 
		+ QueryText
		+ Common.QueryBatchSeparator();
	
EndFunction

// Tables: Data On Labor Costs
// 
// Parameters:
// 	CalculationParameters - Structure - Calculation parameters
// Returns:
// 	String - Query text
Function TextDataOnLaborCosts(CalculationParameters = Undefined) Export
	
	ToDecrypt 				= CostCalculationAppliedAlgorithms.CalculationCalledForDecryption(CalculationParameters);
	CostCalculationPerformed = CostCalculationAppliedAlgorithms.CostCalculationIsPerformedForDecryption(CalculationParameters);
	
	// Data on labor costs are selected in one table because the data sources for the plan and the fact are the same.
	// The exception is releases without an order 2.1, for which data is selected from production documents without orders.
	Text = "
	|SELECT
	|	DD.Organization,
	|	DD.Department,
	|	DD.ProductCostElement,
	|	DD.WorkKind,
	|	SUM(DD.Count) AS Count,
	|	SUM(DD.Cost) AS Cost,
	|	SUM(DD.LocalCost) AS LocalCost,
	|	SUM(DD.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax
	|INTO CurLaborCostsOfUnfinishedProduction
	|FROM
	|	TTCashEstimatedTurnoverWorkInProgress AS DD
	|WHERE
	|	DD.ProductionLot = VALUE(Catalog.ProductionLots.EmptyRef)
	|	AND DD.OfficialTypeOfMovementParish
	|
	|GROUP BY
	|	DD.Organization,
	|	DD.Department,
	|	DD.ProductCostElement,
	|	DD.WorkKind
	|
	|INDEX BY
	|	Organization,
	|	Department,
	|	ProductCostElement,
	|	WorkKind
	|;
	// production 2.2
	|SELECT
	|	DD.Organization								AS Organization,
	|	DD.Department							AS Department,
	|	DD.ProductCostElement						AS ProductCostElement,
	|	DD.WorkKind									AS WorkKind,
	|	ProductionLots.FinancialAccountingDimension AS ProductsGroup,
	|	ProductionLots.Purpose				AS Purpose,
	|	DD.ProductionLot						AS ProductionLot,
	|	ProductionLots.VATActivityType		AS VATActivityType,
	|	UNDEFINED								AS ProductionOrder,
	|	0											AS RowCodeProducts,
	|	ProductionLots.LineOfBusiness	AS LineOfBusiness,
	|	SUM(CASE
	|			WHEN DD.OfficialTypeOfMovementParish
	|				THEN DD.Count
	|			ELSE -DD.Count
	|		END)						AS Count,
	|	SUM(CASE
	|			WHEN DD.OfficialTypeOfMovementParish
	|				THEN DD.StandardCost
	|			ELSE -DD.StandardCost
	|		END)				AS StandardCost,
	|	SUM(CASE
	|			WHEN DD.OfficialTypeOfMovementParish
	|				THEN DD.Cost
	|			ELSE -DD.Cost
	|		END)							AS Cost,
	|	SUM(CASE
	|			WHEN DD.OfficialTypeOfMovementParish
	|				THEN DD.LocalCost
	|			ELSE -DD.LocalCost
	|		END)						AS LocalCost,
	|	SUM(CASE
	|			WHEN DD.OfficialTypeOfMovementParish
	|				THEN DD.CostOfPersonalIncomeTax
	|			ELSE -DD.CostOfPersonalIncomeTax
	|		END)						AS CostOfPersonalIncomeTax
	|INTO DataOnLaborCosts
	|FROM
	|	TTCashEstimatedTurnoverWorkInProgress AS DD
	|	
	|	INNER JOIN ProductionBatchesAreSummarized AS ProductionLots
	|	ON ProductionLots.ProductionLot = DD.ProductionLot
	|	AND ProductionLots.Organization = DD.Organization
	|	AND ProductionLots.CostAllocationForIssue
	|
	|WHERE
	|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (NOT DD.LotCalculation
	// Adding storno-Registered Records of the current period.
	|		OR DD.ReversingEntry)
	|
	|GROUP BY
	|	DD.Department,
	|	DD.ProductCostElement,
	|	DD.WorkKind,
	|	ProductionLots.Purpose,
	|	ProductionLots.VATActivityType,
	|	ProductionLots.LineOfBusiness,
	|	DD.Organization,
	|	DD.ProductionLot,
	|	ProductionLots.FinancialAccountingDimension
	|";
	
	CalculationOfCostLocalization.SupplementRequestWithDataOnLaborCosts(Text);
	
	Text = Text + ";";
	
	If CostCalculationPerformed Or ToDecrypt Then
		Text = StrReplace(Text,
			"TTCashEstimatedTurnoverWorkInProgress",
			"AccumulationRegister.WIPLaborCosts");
		Text = StrReplace(Text,
			"DD.OfficialTypeOfMovementParish",
			"DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Active");
	EndIf;
	
	Return Text;
	
EndFunction

Function MaterialSelectionHierarchy(CalculationParameters) Export
	
	Context = CalculationParameters.DistributionOfParties.RegisterRecordsDetails.Context;
	
	UsedMaterials = New ValueTable;
	UsedMaterials.Columns.Add("Recorder", CostCalculationUniversalAlgorithms.DescriptionOfDocumentTypes());
	UsedMaterials.Columns.Add("Material",    New TypeDescription("CatalogRef.Products"));
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	If Context = "DistributionOfProductsForProduction"
		Or Context = "DistributionOfMaterialsAndWorksOnBase" Then
		
		// Stage 2
		Query.Text =
		"SELECT DISTINCT
		|	D.Ref AS Recorder,
		|	TS.Material AS Material,
		|	TS.Material.IsFolder AS IsFolder
		|FROM
		|	Document.ProductionCostAllocation.FilterByMaterials AS TS
		|	INNER JOIN Document.ProductionCostAllocation AS D
		|		ON TS.Ref = D.Ref
		|
		|WHERE
		|	D.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND D.Organization IN (&CompanyArray)
		|	AND D.Posted
		|	AND D.QuantityToAllocateAccordingToRule <> 0
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	D.Ref AS Recorder,
		|	TS.Material AS Material,
		|	TS.Material.IsFolder AS IsFolder
		|FROM
		|	Document.RecyclableWasteAllocation.FilterByMaterials AS TS
		|	INNER JOIN Document.RecyclableWasteAllocation AS D
		|		ON TS.Ref = D.Ref
		|
		|WHERE
		|	D.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND D.Organization IN (&CompanyArray)
		|	AND D.Posted
		|	AND D.QuantityAccordingToRule <> 0
		|";
		
	ElsIf Context = "OtherExpensesOfUnfinishedProductionOnBasisOf_TowardsDistribution"
	 Or Context = "OtherExpensesOfUnfinishedProductionOnBasisOf_ByDivision" 
	 Or Context = "OtherExpensesOfUnfinishedProductionOnBasisOf_ByStages" Then
		
		// Stage15
		Query.Text =
		"SELECT DISTINCT
		|	D.Ref AS Recorder,
		|	TS.Material AS Material,
		|	TS.Material.IsFolder AS IsFolder
		|FROM
		|	Document.AllocationOfOtherCosts.FilterByMaterials AS TS
		|	INNER JOIN Document.AllocationOfOtherCosts AS D
		|		ON TS.Ref = D.Ref
		|
		|WHERE
		|	D.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND D.Organization IN (&CompanyArray)
		|	AND D.Posted";
		
	Else
		
		ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối với ngữ cảnh %1 không xem xét lọc theo nguyên vật liệu có phân nhánh';
				|ru = 'Для контекста %1 не предусмотрено формирование отбора по материалам с иерархией';
				|en = 'Generation of filter by materials with hierarchy is not available for context %1'; fa = 'Generation of filter by materials with hierarchy is not available for context %1';
				|it = 'Il contesto %1 non prevede la creazione della selezione secondo i materiali con gerarchia';
				|pl = 'Dla kontekstu %1 nie jest przewidziane tworzenie selekcji wg materiałów z hierarchią';
				|tr = '%1 bağlamı için hiyerarşiye sahip malzemeler üzerinde bir filtre oluşturmak öngörülmedi'", Common.DefaultLanguageCode()),
			Context);
		
		CostCalculationProtocol.FixCalculationError(
			CalculationParameters,
			Enums.TypesOfLotAccountingAndCostErrors.ErrorOccurredDuringLotAlocation,
			ProtocolText_);
			
		Raise CostCalculationAppliedAlgorithms.TextExceptionToLogProblem(ProtocolText_);
		
	EndIf;

	Result = Query.Execute().Select();
	
	QueryHierarchy = New Query;
	QueryHierarchy.Text =
	"SELECT
	|	N.Ref AS Material
	|FROM
	|	Catalog.Products AS N
	|WHERE
	|	N.Ref IN HIERARCHY(&Products)
	|	AND NOT N.IsFolder";
		
	While Result.Next() Do
		
		If Result.IsFolder Then
			
			QueryHierarchy.SetParameter("Products", Result.Material);
			
			ResultHierarchy = QueryHierarchy.Execute().Select();
			
			While ResultHierarchy.Next() Do
				
				NewRow = UsedMaterials.Add();
				NewRow.Recorder = Result.Recorder;
				NewRow.Material 	= ResultHierarchy.Material;
				
			EndDo;
			
		Else
			
			NewRow = UsedMaterials.Add();
			FillPropertyValues(NewRow, Result);
			
		EndIf;
		
	EndDo;
	
	Return UsedMaterials;
	
EndFunction

Function TextUnpackingSets(SourceOfSpecificationList) Export // vt materials and servicespecifications
	
	QueriesTexts = New Array;
	
	QueryText = 
	"SELECT DISTINCT
	|	SourceOfSpecificationList.BillOfMaterials AS BillOfMaterials
	|INTO TTSpecifications
	|FROM
	|	&SourceOfSpecificationList AS SourceOfSpecificationList
	|
	|INDEX BY
	|	BillOfMaterials";
	QueryText = StrReplace(QueryText, "&SourceOfSpecificationList", SourceOfSpecificationList);
	QueriesTexts.Add(QueryText);
	
	QueriesTexts.Add(
		Catalogs.BillsOfMaterials.RequestTextSpecificationMaterialsIncludingKitComposition("TTSpecifications"));
	
	QueryText =
		"DROP TTSpecifications";
	QueriesTexts.Add(QueryText);
	
	Return StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
EndFunction

#EndRegion

#EndRegion