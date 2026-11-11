#Region Public

// To process manufactured products according to the order.
// The basic procedure for the manufacture product identification is based on the dynamic structure of production orders.
// 
// Parameters:
//	CalculationParameters - Structure - The parameter structure contains, among other things:
//		* TypeOfPricePlannedCostOfInventory - CatalogRef.TypesOfPrices - Price type of the planned cost of the shopping center.
//		* CurrencyOfPriceOfPlannedCostOfInventory - CatalogRef.Currencies - The currency of the planned value of the shopping center.
//		* BaseCurrency - CatalogRef.Currencies - The base currency in the database.
//		* PCDetails - Structure - contains including:
//			** Date - Date - The date of the product standard cost.
//			** BeginningOfMonthOfCalculationDate - Date - The beginning of the Product standard cost month.
//			** ProductionDispatcherBusinessUnit - CatalogRef.BusinessStructure
//			** PriceKind - CatalogRef.TypesOfPrices - The price type of the Product standard cost.
//			** Organization - CatalogRef.Companies - The company in the planned calculation.
//		* StructureOfData - Structure - Contains keys:
//			** Multipliers - ValueTable - Multipliers.
//			** RegisterRecords - RegisterRecordsCollection - The Registered Records of the document Product standard cost.
//			** TempTablesManager - TempTablesManager - Manager of the transmitted temporary tables for queries.
Procedure ProcessProductsByOrder(CalculationParameters) Export
	
	If InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.ThereWasCancellationOfEvent(CalculationParameters.StandardCostEstimate) Then
		Return;
	EndIf;
		
	StructureOfData = CalculationParameters.StructureOfData;
	
	LinesToUnify = New Array();
	For Each Multiplier In StructureOfData.Multipliers Do
		If Multiplier.CalculationIsCompleted Then 
			Continue 
		EndIf;
		
		If (TypeOf(Multiplier.LotProductBOM) = Type("DocumentRef.ProductionStage2_2")
				And Not ValueIsFilled(Multiplier.LotSemiFinishedProductBOM))
			Or (TypeOf(Multiplier.LotProductBOM) = Type("DocumentRef.ProductionStage2_2")
				And TypeOf(Multiplier.LotSemiFinishedProductBOM) = Type("DocumentRef.ProductionStage2_2"))
				
			// A sign of dean. Structure Order = -1024 cm. Planned articulation2_2.The textsatablecamnotablepartiyipolufabricates
			Or Multiplier.Order = -1024 Then
				LinesToUnify.Add(Multiplier);
				Multiplier.CalculationIsCompleted = True;
		EndIf
	EndDo;
	
	PermanentTemporaryTables = New Array();
	For Each TempTable In StructureOfData.TempTablesManager.Tables Do
		PermanentTemporaryTables.Add(TempTable.FullName);
	EndDo;

	CurrencySet = Constants.CreateSet("LocalAccountingCurrency, ManagementAccountingCurrency");
	CurrencySet.Read();
	
	Query = New Query;
	Query.TempTablesManager = StructureOfData.TempTablesManager;
	Query.SetParameter("StandardCostEstimate", CalculationParameters.StandardCostEstimate);
	Query.TempTablesManager = StructureOfData.TempTablesManager;
	Query.SetParameter("StandardCostEstimate", CalculationParameters.StandardCostEstimate);
	Query.SetParameter("EmptyUID", CalculationParameters.EmptyUID);
	Query.SetParameter("EmptyUIDString", CalculationParameters.EmptyUIDString);
	Query.SetParameter("Organization", CalculationParameters.PCDetails.Organization);
	Query.SetParameter("TypeOfPricePlannedCostOfInventory", CalculationParameters.TypeOfPricePlannedCostOfInventory);
	Query.SetParameter("CalculationDate", CalculationParameters.PCDetails.CalculationDate);
	Query.SetParameter("Date", CalculationParameters.PCDetails.Date);
	Query.SetParameter("Currency", CalculationParameters.CurrencyOfPriceOfPlannedCostOfInventory);
	Query.SetParameter("BaseCurrency", CalculationParameters.BaseCurrency);
	Query.SetParameter("KeepRecordsOfInventoryCostByAssignments",
		CalculationParameters.KeepRecordsOfInventoryCostByAssignments);
	Query.SetParameter("PeriodNotCalculatedForOrganization", CalculationParameters.PeriodNotCalculatedForOrganization);
	
	NameOfRowNumberColumn = "K";
	TMCommonUse.NumberValueTable(StructureOfData.Multipliers, NameOfRowNumberColumn);
	StructureOfData.Multipliers.Indexes.Add(NameOfRowNumberColumn);
	ColumnNamesOfMultipliersTable = StrTemplate("%1,%2,%3",
		CalculationParameters.Multipliers_GroupingColumns,
		CalculationParameters.Multipliers_SummationColumns,
		NameOfRowNumberColumn);
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"Multipliers", StructureOfData.Multipliers.Copy(LinesToUnify),
		ColumnNamesOfMultipliersTable,
		"CalculationIsCompleted,LotIsReleased,KeyLot");
	// There are lines in the multipliers with the order -1, these are write-offs, 
	// after placing the table in temporary, we will delete these lines, they will not be written to the register.
	RowFilter = New Structure("Order", -1);
	LinesToDelete = StructureOfData.Multipliers.FindRows(RowFilter);
	For Each RowToDelete In LinesToDelete Do
		StructureOfData.Multipliers.Delete(RowToDelete);
	EndDo;
	
	#Region QueryText
	Query.Text = "SELECT DISTINCT
	|	ProductionOrderDetails.Ref AS ProductionOrder,
	|	ProductionOrderDetails.EarliestStartDate AS EarliestStartDate,
	|	ProductionOrderDetails.Status AS Status
	|INTO TTOrdersForProduction
	|FROM
	|	Document.StandardCosting2_2.CostObjects AS DD
	|		INNER JOIN Document.ProductionOrder2_2 AS ProductionOrderDetails
	|		ON DD.Object = ProductionOrderDetails.Ref
	|WHERE
	|	DD.Ref = &StandardCostEstimate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////	
	|SELECT
	|	ProductionOrders.ProductionOrder AS ProductionOrder,
	|	DD.Ref AS ProductionLot,
	|	DD.Organization AS Organization
	|INTO ProductionLots
	|FROM
	|	TTOrdersForProduction AS ProductionOrders
	|		INNER JOIN Catalog.ProductionLots AS DD
	|		ON ProductionOrders.ProductionOrder = DD.Document
	|			AND DD.Organization = &Organization
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|	
	|SELECT DISTINCT
	|	ProductionLots.ProductionOrder AS ProductionOrder,
	|	DD.Ref						AS StageLink,
	|	DD.ProductionLot			AS ProductionLot,
	|	ProductionLots.Organization	AS Organization,
	|	DD.ProductionByThirdParty OR DD.ProductionByThirdParty2_5 OR DD.InternalSubcontracting AS ProductionByThirdParty,
	|	DD.NextStageNo			AS NextStageNo
	|INTO AllStagesOfProductionLotREFERENCES
	|FROM
	|	ProductionLots AS ProductionLots
	|		INNER JOIN Document.ProductionStage2_2 AS DD
	|		ON ProductionLots.ProductionLot = DD.ProductionLot
	|			AND DD.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllStagesOfProductionLotREFERENCES.ProductionOrder AS ProductionOrder,
	|	Assignments.Ref AS DestinationLink,
	|	AllStagesOfProductionLotREFERENCES.ProductionLot AS ProductionLot
	|
	|INTO AssignmentsForStagesOfProductionOrder
	|FROM Catalog.Assignments AS Assignments
	|	INNER JOIN AllStagesOfProductionLotREFERENCES AS AllStagesOfProductionLotREFERENCES
	|	ON Assignments.OrderDocument = AllStagesOfProductionLotREFERENCES.StageLink
	|
	|INDEX BY
	|	ProductionOrder,
	|	DestinationLink
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|	
	|SELECT
	|	DD.StageLink					AS ReleasingStage,
	|	DD.ProductionLot			AS ProductionLot,
	|	DD.Organization					AS Organization,
	|	DD.ProductionByThirdParty		AS ProductionByThirdParty
	|INTO ReleasingStages
	|FROM
	|	AllStagesOfProductionLotREFERENCES AS DD
	|WHERE
	|	DD.NextStageNo = 0
	|
	|INDEX BY
	|	ProductionLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// We collect the Attributes of all stages involved in the Lot references of production
	|SELECT
	// Comment 211. The release stage is the final stage in the chain that produces products or semi-finished products.
	|	ReleasingStages.ReleasingStage		AS ReleasingStage,
	|	ReleasingStages.ProductionByThirdParty	AS ProductionByThirdParty,
	|	ItemInstanceDetails.ReferenceOrder		AS ProductionOrder,
	|	ItemInstanceDetails.ProductionLot	AS ProductionLot,
	|	ItemInstanceDetails.Purpose			AS Purpose,
	|	ItemInstanceDetails.Stage				AS StageOfResourceBillOfMaterials,
	// Comment 218. The stage is the current stage, according to which we can, for example, receive used PF or Materials.
	|	ItemInstanceDetails.Ref				AS Stage,
	|	ItemInstanceDetails.Date				AS Date,
	|	ItemInstanceDetails.Currency				AS Currency,
	|	ItemInstanceDetails.Organization			AS Organization,
	|	ItemInstanceDetails.Department		AS Department,
	|	ItemInstanceDetails.NotShipInInstallments	AS ShipInOneDay,
	|	CASE
	|		WHEN ItemInstanceDetails.DateOfShipment = DATETIME(1, 1, 1)
	|			THEN ItemInstanceDetails.Date
	|		ELSE ItemInstanceDetails.DateOfShipment
	|	END									AS DateOfShipment,
	|	ItemInstanceDetails.WorkPerformanceAsOneDay	AS WorkPerformanceAsOneDay,
	|	ItemInstanceDetails.WorkExecutionDate			AS WorkExecutionDate,
	|	ItemInstanceDetails.ProductionInOneDay		AS ProductionInOneDay,
	|	CASE
	|		WHEN ItemInstanceDetails.ProductionDate = DATETIME(1, 1, 1)
	|			THEN ItemInstanceDetails.Date
	|		ELSE ItemInstanceDetails.ProductionDate
	|	END									AS ProductionDate,
	|	ItemInstanceDetails.BillOfMaterials				AS BillOfMaterials,
	|	ItemInstanceDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed) AS TheStepIsCompleted,
	|	ItemInstanceDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated) AS StageIsBeingFormed,
	|	ItemInstanceDetails.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|		AND CASE WHEN ItemInstanceDetails.ProductionInOneDay
	|			THEN ItemInstanceDetails.ProductionDate <= &CalculationDate
	|				AND ItemInstanceDetails.ProductionDate < &PeriodNotCalculatedForOrganization
	|		ELSE
	|			ItemInstanceDetails.ActualStageEnd <= &CalculationDate
	|			AND ItemInstanceDetails.ActualStageEnd < &PeriodNotCalculatedForOrganization
	|	END									AS LotIsReleased,
	|	ItemInstanceDetails.NextStageNo = 0	AS ThisIsAProductionIssueStage,
	|	ItemInstanceDetails.ActualStageEnd	AS ActualStageEnd
	|	
	|INTO DetailsOfStagesOfParties
	|FROM
	|	ReleasingStages AS ReleasingStages
	|		INNER JOIN Document.ProductionStage2_2 AS ItemInstanceDetails
	|		ON ReleasingStages.ProductionLot = ItemInstanceDetails.ProductionLot
	|			AND ItemInstanceDetails.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.ProductionDate AS Period,
	|	DD.ProductionOrder AS ProductionOrder,
	|	DD.Department AS Department,
	|	DD.ReleasingStage AS ReleasingStage,
	|	Stages.Ref AS StageLink,
	|	DD.Purpose AS Purpose,
	|	TSSubcontractorServices.Products AS Products,
	|	TSSubcontractorServices.Characteristic AS Characteristic,
	|	TSSubcontractorServices.Count AS QuantityPerReleaseLotUnit,
	|	TSSubcontractorServices.ProductCostElement AS ProductCostElement
	|
	|INTO ProductionOnSideInIntermediateStages
	|FROM
	|	DetailsOfStagesOfParties AS DD
	|		INNER JOIN Catalog.ProductionStages AS Stages
	|		ON (DD.StageOfResourceBillOfMaterials = Stages.Ref)
	|			AND (NOT Stages.DeletionMark)
	|			AND (Stages.ProductionByThirdParty)
	|			AND (NOT DD.ProductionByThirdParty)
	|		INNER JOIN Catalog.ProductionStages.SubcontractorServices AS TSSubcontractorServices
	|		ON (Stages.Ref = TSSubcontractorServices.Ref)
	|
	|INDEX BY
	|	ReleasingStage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.ProductionOrder AS ProductionOrder
	|FROM
	|	TTOrdersForProduction AS DD
	|";
	
	ResultsArray = Query.ExecuteBatch();
	LastQueryIndex = ResultsArray.Count() - 1;
	SamplingOfProductionOrders = ResultsArray[LastQueryIndex].Select();
	ProductionOrders = New Array();
	While SamplingOfProductionOrders.Next() Do
		ProductionOrders.Add(SamplingOfProductionOrders.ProductionOrder);
	EndDo;
	StructureOfData.Insert("ProductionOrders", ProductionOrders);
	
	Query.Text = "SELECT
	|	DD.ProductionOrder		AS ProductionOrder,
	|	DD.ProductionByThirdParty	AS ProductionByThirdParty,
	|	DD.Department 		AS Department,
	|	Products_1.Products	AS Products,
	|	Products_1.Characteristic	AS Characteristic,
	|	Products_1.Purpose		AS Purpose,
	|	Products_1.Purpose.OrderDocument AS OrderingFromDestination,
	|	Products_1.Series			AS Series,
	|	DD.BillOfMaterials			AS BillOfMaterials,
	|	CASE
	|		WHEN DD.ProductionInOneDay
	|				OR Products_1.ProductionDate = DATETIME(1, 1, 1)
	|			THEN DD.ProductionDate
	|		ELSE Products_1.ProductionDate
	|	END					AS ProductionDate,
	|	Products_1.Ref			AS ReleasingStage,
	|	DD.ProductionLot	AS ProductionLot,
	|	Products_1.Manufactured		AS FinishedproductHasBeenProduced,
	|	Products_1.Count		AS QuantityRelease,
	|	CASE
	|		WHEN Products_1.CostShare = 0
	|			THEN Products_1.Count
	|		ELSE Products_1.CostShare
	|	END						AS CostShare,
	|	Products_1.ToExpenseAs	AS ToExpenseAs,
	|	DD.LotIsReleased
	|		OR Products_1.Manufactured
	|			AND CASE WHEN DD.ProductionInOneDay
	|					OR Products_1.ProductionDate = DATETIME(1, 1, 1)
	|				THEN DD.ProductionDate <= &CalculationDate
	|					AND DD.ProductionDate < &PeriodNotCalculatedForOrganization
	|				ELSE Products_1.ProductionDate <= &CalculationDate
	|					AND Products_1.ProductionDate < &PeriodNotCalculatedForOrganization
	|			END				AS LotIsReleased
	|
	|INTO OutputFinishedProductsInAdvance
	|FROM
	|	DetailsOfStagesOfParties AS DD
	|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS Products_1
	|		ON DD.Stage = Products_1.Ref
	|			AND NOT Products_1.Canceled
	//			AND NOT FINISHED Products.To correctly calculate the entire structure of the production order, 
	//			the written-off finishedproducts must pass through the entire chain and be excluded only before the final recording of the multipliers.
	|
	|INDEX BY
	|	ReleasingStage,
	|	ToExpenseAs
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.ReleasingStage					AS ReleasingStage,
	// As long as the Lot reference is not released, the expenses are considered according to the TS of the software,
	// therefore we consider the denominator as the total share of the cost of both issued and unreleased Lots reference.
	|	SUM(DD.CostShare)				AS CommonDenominator,
	|	SUM(CASE WHEN DD.LotIsReleased
	|		THEN DD.CostShare
	|		ELSE 0
	|	END)								AS DenominatorLotReferenceReleased
	|INTO OutputFinishedProductsCostShareTotals
	|FROM
	|	OutputFinishedProductsInAdvance AS DD
	|
	|GROUP BY
	|	DD.ReleasingStage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RECORDAUTONUMBER()			AS RowID,
	|	DD.ToExpenseAs			AS ToExpenseAs,
	|	DD.ProductionOrder		AS ProductionOrder,
	|	DD.ProductionByThirdParty	AS ProductionByThirdParty,
	|	DD.Department			AS Department,
	|	DD.Products				AS Products,
	|	DD.Characteristic			AS Characteristic,
	|	DD.Purpose				AS Purpose,
	|	DD.Series					AS Series,
	|	DD.OrderingFromDestination = DD.ProductionOrder
	|		OR DD.Purpose = VALUE(Catalog.Assignments.EmptyRef) AS AssignmentIsEmpty,
	|	DD.OrderingFromDestination		AS OrderingFromDestination,
	|	DD.BillOfMaterials			AS BillOfMaterials,
	|	DD.ProductionDate		AS ProductionDate,
	|	DD.ReleasingStage		AS ReleasingStage,
	|	DD.ProductionLot	AS ProductionLot,
	|	DD.FinishedproductHasBeenProduced	AS FinishedproductHasBeenProduced,
	|	DD.QuantityRelease		AS QuantityRelease,
	|
	|	CASE WHEN DD.LotIsReleased
	|		THEN 
	|			CASE WHEN IDC_.DenominatorLotReferenceReleased = DD.CostShare
	|				THEN 1
	|				ELSE IDC_.DenominatorLotReferenceReleased
	|			END
	|		ELSE
	|			CASE WHEN IDC_.CommonDenominator = DD.CostShare
	|				THEN 1
	|				ELSE IDC_.CommonDenominator
	|			END
	|	END AS Denominator,
	|
	|	CASE WHEN DD.LotIsReleased
	|		THEN
	|			CASE WHEN DD.CostShare = IDC_.DenominatorLotReferenceReleased
	|				THEN 1
	|				ELSE DD.CostShare
	|			END
	|		ELSE
	|			CASE WHEN DD.CostShare = IDC_.CommonDenominator
	|				THEN 1
	|				ELSE DD.CostShare
	|			END
	|	END AS Numerator,
	|
	|	DD.LotIsReleased AS LotIsReleased
	|
	|INTO ManufacturedProducts
	|FROM OutputFinishedProductsInAdvance AS DD
	|		INNER JOIN OutputFinishedProductsCostShareTotals AS IDC_
	|		ON DD.ReleasingStage = IDC_.ReleasingStage
	|
	|INDEX BY
	|	ProductionOrder,
	|	ReleasingStage,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// In planned, labor, material and other expenses, there is no cut of the Order for production,
	// so there is no column in this TT.
	|
	|SELECT
	|	DD.Products AS Products,
	|	DD.Characteristic AS Characteristic,
	|	DD.BillOfMaterials AS BillOfMaterials,
	|	DD.ToPlan
	|		AND DD.SupplyType = VALUE(Enum.SupplyTypes.Production)
	// The side output should not have a flag Produced = TRUE
	|		AND TRUE IN (SELECT TOP 1 TRUE
	|					FROM Catalog.BillsOfMaterials.ManufacturedProducts AS RSV
	|					WHERE RSV.Ref = DD.BillOfMaterials
	|						AND RSV.Products = DD.Products
	|						AND (RSV.Characteristic = DD.Characteristic
	|							OR RSV.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|					)
	|		AS Produced
	|INTO OrderTTCacheOfNSIStructurePreliminary
	|FROM TTOrdersForProduction AS TTOrdersForProduction
	|		INNER JOIN InformationRegister.CacheOfOrderStructureMasterData AS DD
	|		ON TTOrdersForProduction.ProductionOrder = DD.ProductionOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Products AS Products,
	|	DD.Characteristic AS Characteristic,
	|	MAX(DD.BillOfMaterials) AS BillOfMaterials,
	|	MAX(DD.Produced) AS Produced
	|INTO OrderTTCacheOfNSIStructure
	|FROM OrderTTCacheOfNSIStructurePreliminary AS DD
	|
	|GROUP BY
	|	DD.Products,
	|	DD.Characteristic
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OrderTTCacheOfNSIStructurePreliminary
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTOrdersForProduction.EarliestStartDate AS Period,
	|	DD.WorkKind AS WorkKind,
	|	DD.ProductionOrder AS ProductionOrder,
	|	DD.KeyLot AS KeyLotReferenceUID,
	|	CAST("""" AS STRING(36)) AS KeyLot,
	|	DD.Stage AS Stage,
	|	DD.BillOfMaterials AS BillOfMaterials,
	|	DD.Department AS Department,
	|	DD.ProductCostElement AS ProductCostElement,
	|	DD.Count AS Count
	|
	|FROM TTOrdersForProduction AS TTOrdersForProduction
	|		INNER JOIN InformationRegister.OrderStructureLaborCosts AS DD
	|		ON TTOrdersForProduction.ProductionOrder = DD.ProductionOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Attributes.ProductionOrder AS ProductionOrder,
	|	Attributes.Department AS Department,
	|	Multipliers.Period AS Period,
	|	Attributes.ProductionByThirdParty AS ProductionByThirdParty,
	|	Multipliers.ManufacturedProduct AS ManufacturedProduct,
	|	Multipliers.ItemVariant AS ItemVariant,
	|	UUID(Multipliers.ItemVariant) AS ItemVariantsOfUid,
	|	CAST("""" AS STRING(36)) AS ItemVariantsOfUidString,
	|	Multipliers.Purpose AS AssignmentOfProducts,
	|	Multipliers.LotProductBOM AS LotProductBOM,
	|	Attributes.BillOfMaterials AS BillOfMaterials,
	|
	|	Multipliers.SemiFinishedProduct AS SemiFinishedProduct,
	|	Multipliers.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
	|
	|	Multipliers.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
	|	Multipliers.Numerator AS Numerator,
	|	Multipliers.Denominator AS Denominator,
	|	Multipliers.Order = -1 AS ToExpenseAs
	|
	|FROM Multipliers AS Multipliers
	|	INNER JOIN DetailsOfStagesOfParties AS Attributes
	|	ON Multipliers.LotProductBOM = Attributes.Stage
	|
	|WHERE
	|	VALUETYPE(Multipliers.LotProductBOM) = TYPE(Document.ProductionStage2_2)
	|	AND NOT Multipliers.LotIsReleased
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderStructure.Warehouse				AS Warehouse,
	|	OrderStructure.Products		AS Products,
	|	OrderStructure.Characteristic		AS Characteristic,
	|	ISNULL(NSICache.Produced, FALSE)	AS ThisIsASemiFinishedProduct,
	// There is no order for unsecured work in Vtkashnsistructure, we get it from the Catalog.
	|	TRUE IN (SELECT TOP 1 TRUE
	|				FROM Catalog.Products AS CatProducts
	|				WHERE CatProducts.Ref = OrderStructure.Products
	|					AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			) AS ThisIsWork,
	|	OrderStructure.Purpose			AS Purpose,
	|	OrderStructure.ProductionOrder	AS ProductionOrder,
	|	OrderStructure.KeyProducts	AS KeyProducts,
	|	OrderStructure.KeyLot			AS KeyLotReferenceUID,
	|	CAST("""" AS STRING (36))		AS KeyLot,
	|	OrderStructure.LineKind			AS LineKind, 
	|	OrderStructure.Stage				AS Stage,
	|	CASE
	|		WHEN VALUETYPE(OrderStructure.Stage) = TYPE(Document.ProductionStage2_2)
	|			THEN TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						Document.ProductionStage2_2 AS DS
	|					WHERE
	|						DS.Ref = OrderStructure.Stage
	|						AND DS.ProductionByThirdParty)
	|		ELSE TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.ProductionStages AS DS
	|				WHERE
	|					DS.Ref = OrderStructure.Stage
	|					AND DS.ProductionByThirdParty)
	|	END								AS ProductionByThirdParty,
	|	CASE
	|		WHEN OrderStructure.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|				AND OrderStructure.LineKind IN
	|									(VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved),
	|									VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
	|			THEN ISNULL(ProductionStageAsReceiptOrder.BillOfMaterials, 
	|					ISNULL(NSICache.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef)))
	|		ELSE OrderStructure.BillOfMaterials
	|	END AS BillOfMaterials,
	|	OrderStructure.Department		AS Department,
	|	OrderStructure.ProductCostElement	AS ProductCostElement,
	|	CASE WHEN OrderStructure.DateOfReceipt = DATETIME(1,1,1)
	|		THEN TTOrdersForProduction.EarliestStartDate
	|		ELSE OrderStructure.DateOfReceipt
	|	END										AS Period,
	|	OrderStructure.NotProvide				AS NotProvide,
	|
	|	CASE
	|		WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
	|				AND OrderStructure.SemiFinishedProductBOM = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|			THEN ISNULL(ProductionStageAsReceiptOrder.BillOfMaterials,
	|					ISNULL(NSICache.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef)))
	|		ELSE OrderStructure.SemiFinishedProductBOM
	|	END AS SemiFinishedProductBOM,
	|
	|	OrderStructure.ToSupply + OrderStructure.Ordered - OrderStructure.Replaced	AS Required2,
	|	OrderStructure.Scheduled						AS Scheduled,
	|	OrderStructure.AllocatedFromAvailableInventoryWithAssignment	AS AllocatedFromAvailableInventoryWithAssignment,
	|	OrderStructure.AllocatedFromAvailableInventory				AS AllocatedFromAvailableInventory,
	|	OrderStructure.AllocatedInAssignedProductionLots		AS AllocatedInAssignedProductionLots,
	|	OrderStructure.AllocatedInFreeProductionLots				AS AllocatedInFreeProductionLots,
	|	OrderStructure.Launched							AS Launched,
	|	OrderStructure.Done								AS Done
	|
	|
	|FROM
	|	TTOrdersForProduction AS TTOrdersForProduction
	|		INNER JOIN InformationRegister.OrderStructure AS OrderStructure
	|		ON TTOrdersForProduction.ProductionOrder = OrderStructure.ProductionOrder
	|
	|		LEFT JOIN Document.ProductionStage2_2 AS ProductionStageAsReceiptOrder
	|		ON (OrderStructure.ReceiptOrder = ProductionStageAsReceiptOrder.Ref)
	|			AND OrderStructure.LineKind IN
	|									(VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved),
	|									VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
	|
	|		LEFT JOIN OrderTTCacheOfNSIStructure AS NSICache
	|		ON NSICache.Products = OrderStructure.Products
	|			AND NSICache.Characteristic = OrderStructure.Characteristic
	|";
	
	ResultsArray = Query.ExecuteBatch();
	LastQueryIndex = ResultsArray.UBound();
	
	#Region ConvertingLotReferenceKeyToString
	
	// TTCacheStructureOrderPreliminary
	TTCacheStructureOrderPreliminary = ResultsArray[LastQueryIndex].Unload();
	For Each CurrentRow In TTCacheStructureOrderPreliminary Do
		CurrentRow.KeyLot = String(CurrentRow.KeyLotReferenceUID);
	EndDo;
	
	TemporaryTableColumns = "Warehouse, Products, Characteristic, ThisIsASemiFinishedProduct, ThisIsWork, Purpose, ProductionOrder,
		| KeyProducts, KeyLot, LineKind, Stage, ProductionByThirdParty, BillOfMaterials, Department,
		| ProductCostElement, Period, NotProvide, SemiFinishedProductBOM, Required2, Scheduled,
		| AllocatedFromAvailableInventoryWithAssignment, AllocatedFromAvailableInventory, AllocatedInAssignedProductionLots, AllocatedInFreeProductionLots,
		| Launched, Done"; //@Query-part
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"TTCacheStructureOrderPreliminary", TTCacheStructureOrderPreliminary, TemporaryTableColumns); //@Query-part
	
	// ManufacturedProductsHaveNotBeenReleasedInStagesOfLotReference
	ManufacturedProductsHaveNotBeenReleasedInStagesOfLotReference = ResultsArray[LastQueryIndex - 1].Unload();
	For Each CurrentRow In ManufacturedProductsHaveNotBeenReleasedInStagesOfLotReference Do
		CurrentRow.ItemVariantsOfUidString = String(CurrentRow.ItemVariantsOfUid);
	EndDo;
	TemporaryTableColumns = "ProductionOrder, Department, Period, ProductionByThirdParty, ManufacturedProduct,
		| ItemVariant, ItemVariantsOfUidString, AssignmentOfProducts,
		| LotProductBOM, BillOfMaterials, SemiFinishedProduct, ItemVariantsOfIntermediateProduct,
		| QuantityOfSemiFinishedProduct, Numerator, Denominator, ToExpenseAs"; //@Query-part
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"ManufacturedProductsHaveNotBeenReleasedInStagesOfLotReference", ManufacturedProductsHaveNotBeenReleasedInStagesOfLotReference, TemporaryTableColumns); //@Query-part
	
	// TTCacheLaborCostsOfOrderStructure
	TTCacheLaborCostsOfOrderStructure = ResultsArray[LastQueryIndex - 2].Unload();
	For Each CurrentRow In TTCacheLaborCostsOfOrderStructure Do
		CurrentRow.KeyLot = String(CurrentRow.KeyLotReferenceUID);
	EndDo;
	TemporaryTableColumns = "Period, WorkKind, ProductionOrder, KeyLot, Stage, BillOfMaterials, Department,
		| ProductCostElement, Count"; //@Query-part
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"TTCacheLaborCostsOfOrderStructure", TTCacheLaborCostsOfOrderStructure, TemporaryTableColumns); //@Query-part
	
	#EndRegion
	
	QueryText = "
	|SELECT
	|	OrderStructure.Warehouse				AS Warehouse,
	|	OrderStructure.Products		AS Products,
	|	OrderStructure.Characteristic		AS Characteristic,
	|	MAX(OrderStructure.ThisIsASemiFinishedProduct) AS ThisIsASemiFinishedProduct,
	|	MAX(OrderStructure.ThisIsWork) AS ThisIsWork,
	|	OrderStructure.Purpose			AS Purpose,
	|	OrderStructure.ProductionOrder	AS ProductionOrder,
	|	OrderStructure.KeyProducts	AS KeyProducts,
	|	OrderStructure.KeyLot			AS KeyLot,
	|	OrderStructure.LineKind			AS LineKind, 
	|	OrderStructure.Stage				AS Stage,
	|	OrderStructure.ProductionByThirdParty	AS ProductionByThirdParty,
	|	OrderStructure.BillOfMaterials			AS BillOfMaterials,
	|	OrderStructure.Department			AS Department,
	|	OrderStructure.ProductCostElement		AS ProductCostElement,
	|	OrderStructure.Period					AS Period,
	|	OrderStructure.NotProvide				AS NotProvide,
	|	OrderStructure.SemiFinishedProductBOM	AS SemiFinishedProductBOM,
	|
	|	SUM(OrderStructure.Required2)							AS Required2,
	|	SUM(OrderStructure.Scheduled)						AS Scheduled,
	|	SUM(OrderStructure.AllocatedFromAvailableInventoryWithAssignment)		AS AllocatedFromAvailableInventoryWithAssignment,
	|	SUM(OrderStructure.AllocatedFromAvailableInventory)				AS AllocatedFromAvailableInventory,
	|	SUM(OrderStructure.AllocatedInAssignedProductionLots)		AS AllocatedInAssignedProductionLots,
	|	SUM(OrderStructure.AllocatedInFreeProductionLots)					AS AllocatedInFreeProductionLots,
	|	SUM(OrderStructure.Launched)								AS Launched,
	|	SUM(OrderStructure.Done)								AS Done
	|
	|INTO TTCacheStructureOrder
	|FROM TTCacheStructureOrderPreliminary AS OrderStructure
	// In the PC structure, the order for identical measurements in resources can have positive and negative numbers,
	// Grouping, the calculation works only with positive numbers.
	|
	|GROUP BY
	|	OrderStructure.Warehouse,
	|	OrderStructure.Products,
	|	OrderStructure.Characteristic,
	|	OrderStructure.Purpose,
	|	OrderStructure.ProductionOrder,
	|	OrderStructure.KeyProducts,
	|	OrderStructure.KeyLot,
	|	OrderStructure.LineKind,
	|	OrderStructure.Stage,
	|	OrderStructure.ProductionByThirdParty,
	|	OrderStructure.BillOfMaterials,
	|	OrderStructure.Department,
	|	OrderStructure.ProductCostElement,
	|	OrderStructure.Period,
	|	OrderStructure.NotProvide,
	|	OrderStructure.SemiFinishedProductBOM
	|
	|INDEX BY
	|	LineKind,
	|	KeyProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTCacheStructureOrderPreliminary
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Comment 636.
	// For a batch key, it may be planned to exceed the number of PF issues over the required amount.
	// For example, if the specification specifies the minimum number of launches more than necessary at the moment.
	// In order to further display correctly the amount of necessary material for the release of the required number of PF,
	// we will create a temporary table with these cases.
	|SELECT
	|	VZ.KeyLot AS KeyLot,
	|	VZ.Products AS Products,
	|	VZ.Characteristic AS Characteristic,
	|	SUM(VZ.Scheduled + VZ.Excess) AS TotalQuantity,
	|	SUM(VZ.Scheduled) AS Scheduled,
	|	SUM(VZ.Excess) AS Excess
	|INTO SideIssuePF
	|FROM
	|	(SELECT
	|		DD.KeyLot AS KeyLot,
	|		DD.Products AS Products,
	|		DD.Characteristic AS Characteristic,
	|		DD.Scheduled AS Scheduled,
	|		0 AS Excess
	|	FROM
	|		TTCacheStructureOrder AS DD
	|	WHERE
	|		DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DD.KeyLot,
	|		DD.Products AS Products,
	|		DD.Characteristic AS Characteristic,
	|		0,
	|		DD.Scheduled
	|	FROM
	|		TTCacheStructureOrder AS DD
	|	WHERE
	|		DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.AvailableRelease)) AS VZ
	|
	|GROUP BY
	|	VZ.KeyLot,
	|	VZ.Products,
	|	VZ.Characteristic
	|
	|HAVING
	|	SUM(VZ.Scheduled) <> 0 AND
	|	SUM(VZ.Excess) <> 0
	|
	|INDEX BY
	|	KeyLot,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.KeyLot AS KeyLot,
	|	SUM(DD.Launched) AS Launched
	|INTO TTCacheOrderStructure_LaunchedByLotReferenceKeys
	|FROM TTCacheStructureOrder AS DD
	|WHERE
	|	DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Launched)
	|GROUP BY
	|	DD.KeyLot
	|INDEX BY
	|	KeyLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.KeyLot AS KeyLot,
	|	SUM(DD.Scheduled) AS Scheduled
	|INTO PlannedByKeyBatches
	|FROM
	|	TTCacheStructureOrder AS DD
	|WHERE
	|	DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct)
	|
	|GROUP BY
	|	DD.KeyLot
	|
	|INDEX BY
	|	KeyLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationQueue.LotProductBOM	AS LotProductBOM,
	|	DD.Products								AS Products,
	|	DD.Characteristic							AS Characteristic,
	|	DD.Purpose								AS Purpose,
	|	DD.ProductionOrder						AS ProductionOrder,
	|	DD.KeyProducts							AS KeyProducts,
	|	DD.KeyLot								AS KeyLot
	|INTO OrderProducts_
	|FROM
	|	TTCacheStructureOrder AS DD
	|		INNER JOIN CalculationQueue AS CalculationQueue
	|		ON DD.Products = CalculationQueue.ManufacturedProduct
	|			AND DD.Characteristic = CalculationQueue.ItemVariant
	|			AND DD.Purpose = CalculationQueue.Purpose
	|WHERE
	|	DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct)
	// If the Lot reference bill of Materials or Stage is a link to the document of the production2_2 stage, we process it according to the stat scenario. Production order
	|	AND DD.Stage REFS Catalog.ProductionStages
	|	AND CalculationQueue.LotProductBOM REFS Catalog.BillsOfMaterials
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DD.BillOfMaterials AS BillOfMaterials
	|INTO SpecificationsUsed
	|FROM
	|	TTCacheStructureOrder AS DD
	|WHERE
	|	DD.LineKind IN (VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|					VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
	|	OR (DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.AvailableRelease)
	|		AND DD.Scheduled > 0)
	|
	|INDEX BY
	|	BillOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BillOfMaterialsRecyclableWaste.Ref AS BillOfMaterials,
	|	BillOfMaterialsRecyclableWaste.Products AS Products,
	|	BillOfMaterialsRecyclableWaste.Characteristic AS Characteristic
	|INTO DinStructureSideOutputBillOfMaterials
	|FROM SpecificationsUsed AS SpecificationsUsed
	// Duplication of lines is prohibited in the resource specification for Nomenclature, Characteristics.
	|		INNER JOIN Catalog.BillsOfMaterials.RecyclableWaste AS BillOfMaterialsRecyclableWaste
	|		ON SpecificationsUsed.BillOfMaterials = BillOfMaterialsRecyclableWaste.Ref
	|
	|INDEX BY
	|	BillOfMaterials,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BillOfMaterialsOfOutputProducts.Ref AS BillOfMaterials,
	|	BillOfMaterialsOfOutputProducts.Products AS Products,
	|	BillOfMaterialsOfOutputProducts.Characteristic AS Characteristic,
	|	CASE WHEN BillOfMaterialsOfOutputProducts.CostShare = 0
	|		THEN BillOfMaterialsOfOutputProducts.NumberOfPackages
	|		ELSE BillOfMaterialsOfOutputProducts.CostShare
	|	END AS CostShare
	|INTO CostSharesAccordingToBillOfMaterials
	|FROM
	|	SpecificationsUsed AS SpecificationsUsed
	// Duplication of lines is prohibited in the resource specification for Nomenclature, Characteristics.
	|		INNER JOIN Catalog.BillsOfMaterials.ManufacturedProducts AS BillOfMaterialsOfOutputProducts
	|		ON SpecificationsUsed.BillOfMaterials = BillOfMaterialsOfOutputProducts.Ref
	|
	|INDEX BY
	|	BillOfMaterials,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.BillOfMaterials AS BillOfMaterials,
	|	SUM(DD.CostShare) AS TotalCostShare
	|INTO TotalCostSharesAccordingToBillOfMaterials
	|FROM
	|	CostSharesAccordingToBillOfMaterials AS DD
	|GROUP BY
	|	DD.BillOfMaterials
	|INDEX BY
	|	BillOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Comment 680.
	// There may be a side issue in the order if the specification allows the choice of a specification for side output products,
	// while the main manufactured products can also be produced according to the same specification and batch key.
	// In order to avoid false uncoupling, we remove the side issue from the multipliers.
	// The side issue should have a fixed price, and should not be unearthed.
	// Let's add a side output with a negative amount as material.
	|SELECT
	|	DD.ProductionOrder			AS ProductionOrder,
	|	DD.Stage							AS Stage,
	|	DD.Period						AS Period,
	|	DD.Department				AS Department,
	|	DD.ProductCostElement			AS ProductCostElement,
	|	DD.BillOfMaterials					AS BillOfMaterials,
	|	OrderProducts_.Products	AS Products,
	|	OrderProducts_.Characteristic	AS Characteristic,
	|	OrderProducts_.Purpose		AS Purpose,
	|	DD.KeyLot					AS KeyLot,
	|	Multipliers.K						AS K,
	|	Multipliers.LotProductBOM	AS LotProductBOM,
	|	- Multipliers.QuantityOfSemiFinishedProduct		AS Required2,
	|	FALSE									AS ThisIsASemiFinishedProduct
	|
	|INTO SideOutputInProductionOrder
	|FROM
	|	OrderProducts_ AS OrderProducts_
	|		INNER JOIN TTCacheStructureOrder AS DD
	|		ON (DD.KeyProducts = OrderProducts_.KeyProducts)
	|			AND (DD.BillOfMaterials = OrderProducts_.LotProductBOM)
	|			AND (DD.Stage REFS Catalog.ProductionStages)
	|		INNER JOIN Multipliers AS Multipliers
	|		ON (DD.KeyLot = Multipliers.KeyLot)
	|			AND (Multipliers.CalculationIsCompleted)
	|			AND (NOT Multipliers.LotIsReleased)
	|			AND (VALUETYPE(Multipliers.LotProductBOM) = TYPE(Catalog.BillsOfMaterials))
	|			AND (Multipliers.LotSemiFinishedProductBOM = UNDEFINED)
	|			AND OrderProducts_.Products = Multipliers.ManufacturedProduct
	|			AND OrderProducts_.Characteristic = Multipliers.ItemVariant
	|			AND OrderProducts_.Purpose = Multipliers.Purpose
	|
	|WHERE
	|	TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM DinStructureSideOutputBillOfMaterials AS DinStructureSideOutputBillOfMaterials
	|				WHERE DD.BillOfMaterials = DinStructureSideOutputBillOfMaterials.BillOfMaterials
	|					AND DD.Products = DinStructureSideOutputBillOfMaterials.Products
	|					AND DD.Characteristic = DinStructureSideOutputBillOfMaterials.Characteristic
	|			)
	|
	|INDEX BY KeyLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Period					AS Period,
	|	DD.BillOfMaterials				AS LotProductBOM,
	|	DD.Stage						AS LotSemiFinishedProductBOM,
	|	DD.ProductionByThirdParty	AS ProductionByThirdParty,
	|	DD.Products			AS ManufacturedProduct,
	|	DD.Characteristic		AS ItemVariant,
	|	DD.Purpose			AS AssignmentOfProducts,
	|	DD.ProductionOrder	AS ProductionOrder,
	|	DD.KeyProducts		AS KeyProducts,
	|	DD.KeyLot			AS KeyLot,
	|	1						AS NumberIsRunning,
	|	1						AS RequiredNumber,
	|	1						AS QuantityByLotReferenceBillOfMaterials,
	|	DD.Scheduled		AS Scheduled,
	|
	|	DD.Required2 - DD.AllocatedFromAvailableInventoryWithAssignment - DD.AllocatedFromAvailableInventory
	|		- DD.AllocatedInAssignedProductionLots - DD.AllocatedInFreeProductionLots		AS Balance,
	|
	|	CostSharesAccordingToBillOfMaterials.CostShare
	|		/ TotalCostSharesAccordingToBillOfMaterials.TotalCostShare	AS CostShareRatio,
	|	CostSharesAccordingToBillOfMaterials.CostShare					AS Numerator,
	|	TotalCostSharesAccordingToBillOfMaterials.TotalCostShare		AS Denominator
	|
	|INTO ManufactureOfProducts
	|FROM
	|	TTCacheStructureOrder AS DD
	|		INNER JOIN OrderProducts_ AS OrderProducts_
	|		ON DD.KeyProducts = OrderProducts_.KeyProducts
	|			AND DD.BillOfMaterials = OrderProducts_.LotProductBOM
	|			AND DD.Stage REFS Catalog.ProductionStages
	|		
	|		INNER JOIN TotalCostSharesAccordingToBillOfMaterials AS TotalCostSharesAccordingToBillOfMaterials
	|		ON DD.BillOfMaterials = TotalCostSharesAccordingToBillOfMaterials.BillOfMaterials
	|
	|		INNER JOIN CostSharesAccordingToBillOfMaterials AS CostSharesAccordingToBillOfMaterials
	|		ON DD.BillOfMaterials = CostSharesAccordingToBillOfMaterials.BillOfMaterials
	|			AND DD.Products = CostSharesAccordingToBillOfMaterials.Products
	|			AND (DD.Characteristic = CostSharesAccordingToBillOfMaterials.Characteristic
	|				OR CostSharesAccordingToBillOfMaterials.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|	
	|WHERE
	|	DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts)
	// Comment 695.
	// If, in the specification, several product items are indicated in the tabular part of the output products,
	// and only a part of them
	// are indicated in the production order, the items of the nomenclature not specified in the order go as a side issue and will be added to the tabular part
	// of the production stages being created, to the tabular part of the output products.
	|	OR (DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.AvailableRelease)
	|		AND DD.Scheduled > 0)
	|	
	|INDEX BY
	|	ManufacturedProduct,
	|	ItemVariant,
	|	AssignmentOfProducts,
	|	KeyLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ManufactureOfProducts.Period AS Period,
	|	ManufactureOfProducts.ProductionOrder AS ProductionOrder,
	|	Stages.Ref AS StageLink,
	|	ManufactureOfProducts.AssignmentOfProducts AS Purpose,
	|	ManufactureOfProducts.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|	ManufactureOfProducts.LotProductBOM AS BillOfMaterials,
	|	Stages.Department AS Department,
	|	ManufactureOfProducts.ManufacturedProduct AS ManufacturedProduct,
	|	ManufactureOfProducts.KeyLot AS KeyLot,
	|	TSSubcontractorServices.Products AS Products,
	|	TSSubcontractorServices.Characteristic AS Characteristic,
	|	TSSubcontractorServices.Count * ManufactureOfProducts.Scheduled AS Count,
	|	TSSubcontractorServices.Count AS QuantityPerReleaseLotUnit,
	|	TSSubcontractorServices.ProductCostElement AS ProductCostElement
	|
	|INTO DinStructureProductionOnSideInIntermediateStages
	|FROM
	|	ManufactureOfProducts AS ManufactureOfProducts
	|		INNER JOIN Catalog.ProductionStages AS Stages
	|		ON (ManufactureOfProducts.LotProductBOM = Stages.Owner)
	|			AND (NOT Stages.DeletionMark)
	|			AND (Stages.ProductionByThirdParty)
	|			AND (NOT ManufactureOfProducts.ProductionByThirdParty)
	|		INNER JOIN Catalog.ProductionStages.SubcontractorServices AS TSSubcontractorServices
	|		ON (Stages.Ref = TSSubcontractorServices.Ref)
	|
	|INDEX BY
	|	KeyLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SpecificationsUsed
	|";
	
	QueriesTexts = New Array();
	QueriesTexts.Add(QueryText);
	QueriesTexts.Add(QueryText_ConsumptionOfMaterialsAndSemiFinishedProducts("ManufactureOfProducts")); //@Query-part
	
	QueryText = "
	|SELECT
	|	DD.ReleasingStage			AS ReleasingStage,
	|	DD.ProductionOrder		AS ProductionOrder,
	|	DD.ProductionByThirdParty	AS ProductionByThirdParty,
	|	DD.Products				AS Products,
	|	DD.Characteristic			AS Characteristic,
	|	DD.Purpose				AS Purpose,
	|	DD.BillOfMaterials				AS BillOfMaterials,
	|
	|	SUM(DD.QuantityRelease)	AS QuantityRelease,
	|	SUM(DD.Numerator)			AS Numerator
	|
	|INTO OutputFinishedProductsSummaryData
	|FROM ManufacturedProducts AS DD
	|
	|GROUP BY
	|	DD.ReleasingStage,
	|	DD.ProductionOrder,
	|	DD.ProductionByThirdParty,
	|	DD.Products,
	|	DD.Characteristic,
	|	DD.Purpose,
	|	DD.BillOfMaterials
	|
	|INDEX BY
	|	ReleasingStage,
	|	Products,
	|	Characteristic,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.LotProductBOM AS BillOfMaterials,
	|	DD.KeyLot AS KeyLot,
	|	SUM(DD.Numerator) AS Denominator
	|INTO DenominatorOfUsedProductsSpecifications
	|FROM ManufactureOfProducts AS DD
	|
	|GROUP BY
	|	DD.LotProductBOM,
	|	DD.KeyLot
	|
	|INDEX BY
	|	KeyLot,
	|	BillOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.RowID AS RowID,
	|	DD.ReleasingStage AS ReleasingStage,
	|	DD.ProductionDate AS ProductionDate,
	|	DD.BillOfMaterials	AS BillOfMaterials,
	|	DD.Products AS Products,
	|	DD.Characteristic AS Characteristic,
	|	DD.Purpose AS Purpose,
	|	DD.ProductionOrder AS ProductionOrder,
	|	DD.Department AS Department,
	|	DD.ProductionByThirdParty AS ProductionByThirdParty,
	|	DD.LotIsReleased AS LotIsReleased,
	|	DD.AssignmentIsEmpty AS AssignmentIsEmpty,
	|	DD.QuantityRelease AS QuantityRelease,
	|	DD.QuantityRelease AS QuantityReleaseBalance,
	|	DD.Denominator AS Denominator,
	|	DD.Numerator AS Numerator,
	|	VISD.QuantityRelease AS NumberOfTotalWithinStage,
	|	VISD.Numerator AS NumeratorOfTotalWithinStage
	|FROM
	|	ManufacturedProducts AS DD
	|		INNER JOIN OutputFinishedProductsSummaryData AS VISD
	|		ON DD.ReleasingStage = VISD.ReleasingStage
	|			AND DD.Products = VISD.Products
	|			AND DD.Characteristic = VISD.Characteristic
	|			AND DD.Purpose = VISD.Purpose
	|
	|ORDER BY
	|	DD.ProductionDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// The manufactured products of the order are made on the side, the request for changing the principle of uncoupling through the specification, see 1391
	|SELECT
	|	Multipliers.K AS K
	|FROM
	|	ManufactureOfProducts AS ManufactureOfProducts
	|		INNER JOIN Multipliers AS Multipliers
	|		ON (ManufactureOfProducts.KeyLot = Multipliers.KeyLot)
	|			AND (ManufactureOfProducts.ProductionByThirdParty)
	|			AND (Multipliers.CalculationIsCompleted)
	|			AND (NOT Multipliers.LotIsReleased)
	|			AND (VALUETYPE(Multipliers.LotProductBOM) = TYPE(Catalog.BillsOfMaterials))
	|			AND (Multipliers.LotSemiFinishedProductBOM = UNDEFINED)
	|
	|			AND ManufactureOfProducts.ManufacturedProduct = Multipliers.ManufacturedProduct
	|			AND ManufactureOfProducts.ItemVariant = Multipliers.ItemVariant
	|			AND ManufactureOfProducts.AssignmentOfProducts = Multipliers.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Comment 781
	// Within the framework of one specification, there can be an arbitrary number of manufactured products,
	// It is necessary to set the numerator and denominator based on the cost fractions specified in the specification.
	|SELECT
	|	Multipliers.K AS K,
	|	ManufactureOfProducts.Numerator AS Numerator,
	|	ISNULL(DenominatorOfUsedProductsSpecifications.Denominator, ManufactureOfProducts.Denominator) AS Denominator
	|
	|FROM ManufactureOfProducts AS ManufactureOfProducts
	|		INNER JOIN Multipliers AS Multipliers
	|		ON (ManufactureOfProducts.KeyLot = Multipliers.KeyLot)
	|			AND (ManufactureOfProducts.CostShareRatio <> 1)
	|			AND (Multipliers.CalculationIsCompleted)
	|			AND (NOT Multipliers.LotIsReleased)
	|			AND (VALUETYPE(Multipliers.LotProductBOM) = TYPE(Catalog.BillsOfMaterials))
	|			AND (Multipliers.LotSemiFinishedProductBOM = UNDEFINED)
	|
	|			AND ManufactureOfProducts.ManufacturedProduct = Multipliers.ManufacturedProduct
	|			AND ManufactureOfProducts.ItemVariant = Multipliers.ItemVariant
	|			AND ManufactureOfProducts.AssignmentOfProducts = Multipliers.Purpose
	|		
	|		LEFT JOIN DenominatorOfUsedProductsSpecifications AS DenominatorOfUsedProductsSpecifications
	|		ON ManufactureOfProducts.KeyLot = DenominatorOfUsedProductsSpecifications.KeyLot
	|			AND Multipliers.LotProductBOM = DenominatorOfUsedProductsSpecifications.BillOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// DenominatorOfUsedProductsSpecifications
	|SELECT
	|	DD.BillOfMaterials AS BillOfMaterials,
	|	DD.KeyLot AS KeyLot,
	|	DD.Denominator AS Denominator
	|FROM DenominatorOfUsedProductsSpecifications AS DD
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// See 680.
	// Removing side-by-side outputs of multipliers
	|SELECT
	|	DD.K AS K
	|
	|FROM SideOutputInProductionOrder AS DD
	|";
	
	QueriesTexts.Add(QueryText);	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	#EndRegion
	
	ResultsArray = Query.ExecuteBatch();
	LastQueryIndex = ResultsArray.UBound();
	
	// See 680.
	RemovingSideOutputFromMultipliers =  ResultsArray[LastQueryIndex].Select();
	While RemovingSideOutputFromMultipliers.Next() Do
		ReplacementStringKeyLotReference = StructureOfData.Multipliers.Find(RemovingSideOutputFromMultipliers.K, "K");
		StructureOfData.Multipliers.Delete(ReplacementStringKeyLotReference);
	EndDo;
	
	StructureOfData.Insert("DenominatorOfUsedProductsSpecifications",
		ResultsArray[LastQueryIndex - 1].Unload());
		
	// See Comment 781.
	ChangingNumeratorAndDenominator = ResultsArray[LastQueryIndex - 2].Select();
	While ChangingNumeratorAndDenominator.Next() Do
		LineOfChangingNumeratorDenominator = StructureOfData.Multipliers.Find(ChangingNumeratorAndDenominator.K, "K");
		LineOfChangingNumeratorDenominator.Numerator = ChangingNumeratorAndDenominator.Numerator;
		LineOfChangingNumeratorDenominator.Denominator = ChangingNumeratorAndDenominator.Denominator;
	EndDo;
	
	//	See Comment 1391.
	// If the manufactured products are made on the side, we remove the check mark The calculation is complete,
	// the uncoupling should take place according to the resource specification.
	ProductionOfProductsOnSide = ResultsArray[LastQueryIndex - 3].Select();
	While ProductionOfProductsOnSide.Next() Do
		ProductionLineOnSide = StructureOfData.Multipliers.Find(ProductionOfProductsOnSide.K, "K");
		ProductionLineOnSide.CalculationIsCompleted = False;
	EndDo;
	
	StructureOfData.Insert("ManufacturedProducts", ResultsArray[LastQueryIndex - 4].Unload());
	StructureOfData.ManufacturedProducts.Indexes.Add("RowID");
	
	If CostCalculationAppliedAlgorithms.TemporaryTableSize(Query.TempTablesManager,
		"ConsumptionOfMaterialsAndSemiFinishedProducts") > 0 Then
		DistributePFConsumptionByPossibleReleases(Query, CalculationParameters, False);
	EndIf;
	
	DistributePFConsumptionByPossibleReleases(Query, CalculationParameters, True);
	
	ToPlaceUsedSemiFinishedProductsOfIWT(Query.TempTablesManager,
		CalculationParameters.StructureOfData.UsedSemiFinishedProducts);
	
	CalculationParameters.Insert("QueryTextForGettingDataAtCurrentLevel", QueryText_PlannedMaterialCosts());
		
	QueriesTexts = New Array();
	QueriesTexts.Add(QueryText_SemiFinishedProducts(CalculationParameters));
	QueriesTexts.Add(CalculationParameters.QueryTextForGettingDataAtCurrentLevel);
	// 14 Planned labor costs
	QueriesTexts.Add(QueryText_PlannedLaborCosts());
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query.TempTablesManager, 
		"DenominatorOfUsedProductsSpecifications"); //@Query-part
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
		Query.TempTablesManager,
		"DenominatorOfUsedProductsSpecifications",
		CalculationParameters.StructureOfData.DenominatorOfUsedProductsSpecifications,
		"BillOfMaterials,KeyLot,Denominator",
		"KeyLot,BillOfMaterials");
	
	ResultsArray = Query.ExecuteBatch();
	LastQueryIndex = ResultsArray.UBound();
	
	// 10 Multipliers for semi-finished products produced by the process.
	SamplingMultipliers = ResultsArray[LastQueryIndex - 2].Select();
	While SamplingMultipliers.Next() Do
		FillPropertyValues(StructureOfData.Multipliers.Add(), SamplingMultipliers);
	EndDo;
	
	StructureOfData.Insert("Order", 1);
	
	// 15 Issue of the Order frame
	StructureOfData.Insert("PFIssuesWithinOrder");
	TransferDataFromQueryResultToValuesTable(StructureOfData.PFIssuesWithinOrder,
		ResultsArray[LastQueryIndex - 3], False);
	
	TransferDataFromQueryResults(ResultsArray, CalculationParameters);
	
	CalculationParameters.Insert("QueryText_disclosureOfSemiFinishedProductsDinStructure",
		QueryText_disclosureOfSemiFinishedProductsDinStructure(CalculationParameters));

	CalculationParameters.Insert("QueryText_SemiFinishedProducts", QueryText_SemiFinishedProducts(CalculationParameters));
	ToFindOutPFProducedInProcess(Query, CalculationParameters);

	If StructureOfData.PFIssuesWithinOrder.Count() > 0 Then
		StructureOfData.PFIssuesWithinOrder.GroupBy("ToExpenseAs,GPVStage,OutputFinishedProducts_ID,
			|ReleasingStage,ConsumingStage,ProductionOrder,KeyLot,
			|Period,ManufacturedProduct,ItemVariant,AssignmentOfProducts,LotProductBOM,SemiFinishedProduct,ItemVariantsOfIntermediateProduct,
			|LotSemiFinishedProductBOM,SemiFinishedProductBOM,LotIsReleased", "RequiredNumber");
		PlacePFIssuesWithinFrameworkOfIWTOrder(Query, StructureOfData.PFIssuesWithinOrder);
		SeparationOfStagesForProduction(Query, CalculationParameters);
	EndIf;
	
	StructureOfData.Multipliers.FillValues(CalculationParameters.StandardCostEstimate, "StandardCostEstimate");
	
	// Folding by identical denominators
	// Bringing to a common denominator will happen here multiplicitypartiyipolufabrikat.Let's visit the Common signifier
	InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.CollapseMultipliersWithinVT(StructureOfData.Multipliers,
		CalculationParameters);
	
	StructureOfData.Multipliers.Columns.Add("Department",
		New TypeDescription("CatalogRef.BusinessStructure"));
	StructureOfData.Multipliers.FillValues(CalculationParameters.PCDetails.ProductionDispatcherBusinessUnit, "Department");
	
	// We delete the data necessary only for this level of calculation
	StructureOfData.Delete("PFIssuesWithinOrder");
	StructureOfData.Delete("ReleasingStagesForLotReferenceKeys");
	StructureOfData.Delete("UsedSemiFinishedProducts");
	
	CalculationParameters.Delete("QueryTextForGettingDataAtCurrentLevel");
	CalculationParameters.Delete("QueryText_disclosureOfSemiFinishedProductsDinStructure");
	CalculationParameters.Delete("QueryText_StageSeparation");
	CalculationParameters.Delete("QueryText_SemiFinishedProducts");
	
	// We will destroy all temporary tables that are not in the array of permanent temporary tables
	TextsOfDestructionOfTemporaryTables = New Array();
	For Each TempTable In StructureOfData.TempTablesManager.Tables Do
		If PermanentTemporaryTables.Find(TempTable.FullName) = Undefined Then
			TextsOfDestructionOfTemporaryTables.Add("DROP " + TempTable.FullName); //@Query-part
		EndIf;
		PermanentTemporaryTables.Add();
	EndDo;
	
	If TextsOfDestructionOfTemporaryTables.Count() > 0 Then
		Query.Text = StrConcat(TextsOfDestructionOfTemporaryTables,
			Common.QueryBatchSeparator());
		Query.Execute();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Move data from the query result to the values table.
// 
// Parameters:
//  ReceiverValueTable - ValueTable - Receiver Value Table
//  ResultOfSourceRequest - QueryResult - Result Of The Source Request
//  ReturnArrayOfAddedRows - Boolean - It is necessary to pass true if it is necessary to work with strings, after adding.
Function TransferDataFromQueryResultToValuesTable(ReceiverValueTable, ResultOfSourceRequest,
	ReturnArrayOfAddedRows = False)
	
	ArrayOfAddedRows = New Array();
	If ReceiverValueTable = Undefined Then
		ReceiverValueTable = ResultOfSourceRequest.Unload();
		If ReturnArrayOfAddedRows Then
			For Each Page1 In ReceiverValueTable Do
				ArrayOfAddedRows.Add(Page1);
			EndDo;
		EndIf;
	Else
		QueryBackup = ResultOfSourceRequest.Select();
		While QueryBackup.Next() Do
			NewRow = ReceiverValueTable.Add();
			FillPropertyValues(NewRow, QueryBackup);
			If ReturnArrayOfAddedRows Then
				ArrayOfAddedRows.Add(NewRow);
			EndIf;
		EndDo;
	EndIf;
	
	Return ?(ReturnArrayOfAddedRows, ArrayOfAddedRows, Undefined);
EndFunction

// Transfer data from query results.
// 
// Parameters:
//	ResultsArray - Array of QueryResult - Array of query results.
//	CalculationParameters - Structure - Contains keys:
//		* TypeOfPricePlannedCostOfInventory - CatalogRef.TypesOfPrices - Price type of the planned cost of the shopping center.
//		* CurrencyOfPriceOfPlannedCostOfInventory - CatalogRef.Currencies - The currency of the planned value of the shopping center.
//		* BaseCurrency - CatalogRef.Currencies - The base currency in the database.
//		* PCDetails - Structure - Contains keys:
//			* Date - Date - The date of the product standard cost.
//			* BeginningOfMonthOfCalculationDate - Date - The beginning of the Product standard cost month.
//			* ProductionDispatcherBusinessUnit - CatalogRef.BusinessStructure
//			* PriceKind - CatalogRef.TypesOfPrices - The price type of the Product standard cost.
//			* Organization - CatalogRef.Companies - The company in the planned calculation.
//		* StructureOfData - Structure - Contains keys:
//			* RegisterRecords - RegisterRecordsCollection - The Registered Records of the document Product standard cost.
Procedure TransferDataFromQueryResults(ResultsArray, CalculationParameters)
	StructureOfData = CalculationParameters.StructureOfData;
	
	LastQueryIndex = ResultsArray.Count() - 1;

	// 13 Planned material costs
	PlannedMaterialCosts = ResultsArray[LastQueryIndex - 1].Select();
	While PlannedMaterialCosts.Next() Do
		FillPropertyValues(StructureOfData.RegisterRecords.PlannedMaterialCosts.Add(),
			PlannedMaterialCosts);
	EndDo;
	
	// 14 Planned labor costs
	PlannedLaborCosts = ResultsArray[LastQueryIndex].Select();
	While PlannedLaborCosts.Next() Do
		FillPropertyValues(StructureOfData.RegisterRecords.PlannedLaborCosts.Add(), PlannedLaborCosts);
	EndDo;
	
EndProcedure

Function QueryText_SemiFinishedProducts(CalculationParameters)
	QueriesTexts = New Array();
	QueryText = "SELECT
	|	DD.GPVStage								AS GPVStage,
	|	DD.ProductionOrder					AS ProductionOrder,
	|	DD.Period								AS Period,
	|	DD.ManufacturedProduct							AS ManufacturedProduct,
	|	DD.ItemVariant				AS ItemVariant,
	|	DD.AssignmentOfProducts					AS AssignmentOfProducts,
	|	DD.LotProductBOM			AS LotProductBOM,
	|	DD.ProductionByThirdParty				AS ProductionByThirdParty,
	|	DD.SemiFinishedProduct							AS SemiFinishedProduct,
	|	DD.ItemVariantsOfIntermediateProduct			AS ItemVariantsOfIntermediateProduct,
	|	DD.SemiFinishedProductBOM			AS SemiFinishedProductBOM,
	|	DD.SemiFinishedProductBOM			AS LotSemiFinishedProductBOM,
	|	DD.KeyLot							AS KeyLot,
	// To unravel the Din structure, we take only the planned amount
	|	SUM(DD.Scheduled)					AS RequiredNumber,
	|	SUM(DD.NumberIsRunning)			AS NumberIsRunning,
	|	SUM(DD.QuantityFromBillOfMaterials)		AS QuantityByLotReferenceBillOfMaterials,
	|	SUM(DD.AllocatedFromAvailableInventory)			AS AllocatedFromAvailableInventory,
	|	MAX(DD.CostShareRatio)	AS CostShareRatio,
	|	SUM(DD.Numerator)						AS Numerator,
	|	DD.Denominator							AS Denominator
	|
	|INTO PFRaznozlovkaByDinStructure
	|FROM
	|	UsedSemiFinishedProducts AS DD
	|WHERE
	|	(DD.QuantityFromBillOfMaterials > 0
	// see comment 1155.
	|		OR DD.AllocatedFromAvailableInventory > 0)
	|	AND NOT DD.GPVStage
	|
	|GROUP BY
	|	DD.GPVStage,
	|	DD.ProductionOrder,
	|	DD.Period,
	|	DD.ManufacturedProduct,
	|	DD.ItemVariant,
	|	DD.AssignmentOfProducts,
	|	DD.LotProductBOM,
	|	DD.ProductionByThirdParty,
	|	DD.SemiFinishedProduct,
	|	DD.ItemVariantsOfIntermediateProduct,
	|	DD.SemiFinishedProductBOM,
	|	DD.LotSemiFinishedProductBOM,
	|	DD.KeyLot,
	|	DD.Denominator
	|
	|INDEX BY
	|	ProductionByThirdParty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 15 Issue of the Order frame
	// In this table we collect all the expected releases of PF within the order, according to which in the din. the structure has no uncoupling.
	|SELECT
	|	DD.ToExpenseAs					AS ToExpenseAs,
	|	DD.GPVStage							AS GPVStage,
	|	DD.Source_ID						AS OutputFinishedProducts_ID,
	|	DD.LotSemiFinishedProductBOM	AS ReleasingStage,
	|	DD.ConsumingStage					AS ConsumingStage,
	|	DD.ProductionOrder				AS ProductionOrder,
	|	DD.KeyLot						AS KeyLot,
	|	DD.Period							AS Period,
	|	
	|	DD.ManufacturedProduct						AS ManufacturedProduct,
	|	DD.ItemVariant			AS ItemVariant,
	|	DD.AssignmentOfProducts				AS AssignmentOfProducts,
	|	DD.LotProductBOM		AS LotProductBOM,
	|
	|	DD.SemiFinishedProduct						AS SemiFinishedProduct,
	|	DD.ItemVariantsOfIntermediateProduct		AS ItemVariantsOfIntermediateProduct,
	|
	|	DD.QuantityFromStage				AS RequiredNumber,
	|	DD.LotSemiFinishedProductBOM	AS LotSemiFinishedProductBOM,
	|	DD.SemiFinishedProductBOM		AS SemiFinishedProductBOM,
	|	DD.LotIsReleased					AS LotIsReleased
	|
	|FROM UsedSemiFinishedProducts AS DD
	|
	|WHERE
	|	DD.QuantityFromStage > 0
	//	see comment 1391
	|	AND NOT DD.ProductionByThirdParty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 10 Multipliers for semi-finished products produced by the process.
	|SELECT
	|	DD.ProductionOrder				AS ProductionOrder,
	|	DD.Period							AS Period,
	|	DD.ManufacturedProduct 						AS ManufacturedProduct,
	|	DD.ItemVariant			AS ItemVariant,
	|	DD.AssignmentOfProducts				AS Purpose,
	|	DD.LotProductBOM		AS LotProductBOM,
	|	DD.ProductionByThirdParty			AS ProductionByThirdParty,
	|	DD.SemiFinishedProduct 					AS SemiFinishedProduct,
	|	DD.ItemVariantsOfIntermediateProduct		AS ItemVariantsOfIntermediateProduct,
	|	CASE
	|		WHEN DD.ProductionByThirdParty
	//			see comment 1391
	|			THEN DD.SemiFinishedProductBOM
	|		ELSE DD.LotSemiFinishedProductBOM
	|	END								AS LotSemiFinishedProductBOM,
	|	DD.QuantityByLotReferenceBillOfMaterials	AS QuantityOfSemiFinishedProduct,
	//	see comment 1391
	|	NOT DD.ProductionByThirdParty				AS CalculationIsCompleted,
	|	FALSE 									AS LotIsReleased,
	|	1										AS Order,
	|	DD.Numerator							AS Numerator,
	|	ISNULL(DenominatorOfUsedProductsSpecifications.Denominator, 1) AS Denominator,
	|	""MultipliersOfPFProducedInProcess"" AS Comment,
	|
	|	&EmptyUID AS KeyProducts,
	|	DD.KeyLot AS KeyLot
	|FROM
	|	PFRaznozlovkaByDinStructure AS DD
	|	LEFT JOIN DenominatorOfUsedProductsSpecifications AS DenominatorOfUsedProductsSpecifications
	|	ON DD.KeyLot = DenominatorOfUsedProductsSpecifications.KeyLot
	|		AND &ConnectionCondition
	|WHERE
	|	DD.QuantityByLotReferenceBillOfMaterials > 0
	|
	|UNION ALL
	|
	|SELECT
	|	DD.ProductionOrder				AS ProductionOrder,
	|	DD.Period							AS Period,
	|	DD.ManufacturedProduct 						AS ManufacturedProduct,
	|	DD.ItemVariant			AS ItemVariant,
	|	DD.AssignmentOfProducts				AS Purpose,
	|	DD.LotProductBOM		AS LotProductBOM,
	|	DD.ProductionByThirdParty			AS ProductionByThirdParty,
	|	DD.SemiFinishedProduct 					AS SemiFinishedProduct,
	|	DD.ItemVariantsOfIntermediateProduct		AS ItemVariantsOfIntermediateProduct,
	|	CASE
	|		WHEN DD.ProductionByThirdParty
	//			see comment 1391
	|			THEN DD.SemiFinishedProductBOM
	|		ELSE DD.LotSemiFinishedProductBOM
	|	END								AS LotSemiFinishedProductBOM,
	|	DD.AllocatedFromAvailableInventory			AS QuantityOfSemiFinishedProduct,
	|	FALSE								AS CalculationIsCompleted,
	|	FALSE 									AS LotIsReleased,
	|	1										AS Order,
	|	DD.Numerator							AS Numerator,
	|	ISNULL(DenominatorOfUsedProductsSpecifications.Denominator, 1) AS Denominator,
	|	""MultipliersOfPFProducedInProcess""	AS Comment,
	|
	|	&EmptyUID AS KeyProducts,
	|	DD.KeyLot AS KeyLot
	|FROM
	|	PFRaznozlovkaByDinStructure AS DD
	|	LEFT JOIN DenominatorOfUsedProductsSpecifications AS DenominatorOfUsedProductsSpecifications
	|	ON DD.KeyLot = DenominatorOfUsedProductsSpecifications.KeyLot
	|		AND &ConnectionCondition
	|WHERE
	// Comment 1155.
	// The uncoupling of the semi-finished product, when distributed from stocks, occurs according to the specification.
	|	DD.AllocatedFromAvailableInventory > 0
	|";
	
	ConnectionCondition = "(
	|			CASE
	|				WHEN DD.ProductionByThirdParty
	//					see comment 1391
	|					THEN DD.SemiFinishedProductBOM
	|			ELSE DD.LotSemiFinishedProductBOM
	|			END = DenominatorOfUsedProductsSpecifications.BillOfMaterials
	|)"; //@Query-part
	
	QueryText = StrReplace(QueryText, "&ConnectionCondition", ConnectionCondition); //@Query-part
	
	QueriesTexts.Add(QueryText);
	Return StrConcat(QueriesTexts, Common.QueryBatchSeparator());
EndFunction

Function QueryText_PlannedMaterialCosts()
	QueryText = "
	|
	// 13 Planned material costs
	|SELECT
	|	DD.ProductionOrder	AS ProductionOrder,
	|
	|	DD.Period				AS Period,
	|	&StandardCostEstimate 			AS StandardCostEstimate,
	|	CASE
	|		WHEN VALUETYPE(DD.LotSemiFinishedProductBOM) = TYPE(Document.ProductionStage2_2)
	|			THEN DD.LotSemiFinishedProductBOM
	|		ELSE DD.BillOfMaterials
	|	END					AS LotBOM,
	|	DD.KeyLot			AS KeyLot,
	|	DD.Department 		AS Department,
	|	DD.ProductCostElement	AS ProductCostElement,
	|	DD.Products 		AS Products,
	|	DD.Characteristic 		AS Characteristic,
	|
	|	DD.Required2							AS Count,
	|	0										AS Cost,
	|	0										AS CostExcludingVAT,
	|	0										AS LocalCost,
	|	0										AS OffBalanceCost,
	|	0										AS OffBalanceCostLocal,
	|	
	|	""PlannedMaterialCosts""		AS Comment,
	|	BEGINOFPERIOD(DD.Period, MONTH)		AS CostPeriod,
	|	DD.ThisIsASemiFinishedProduct					AS ThisIsASemiFinishedProduct
	|FROM
	|	ConsumptionOfMaterialsAndSemiFinishedProducts AS DD
	|";
	
	Return QueryText;
EndFunction

#Region DecouplingOfPFByDinStructure

Function QueryText_disclosureOfSemiFinishedProductsDinStructure(CalculationParameters)
	QueriesTexts = New Array();
	QueriesTexts.Add("DROP PFManufacturedProductsPreliminary"); //@Query-part
	QueriesTexts.Add("DROP ConsumptionOfMaterialsAndSemiFinishedProducts"); //@Query-part
	QueriesTexts.Add(QueryText_ConsumptionOfMaterialsAndSemiFinishedProducts("PFRaznozlovkaByDinStructure")); //@Query-part
	QueriesTexts.Add(CalculationParameters.QueryTextForGettingDataAtCurrentLevel);
	// 14 Planned labor costs
	QueriesTexts.Add(QueryText_PlannedLaborCosts());
	Return StrConcat(QueriesTexts, Common.QueryBatchSeparator());
EndFunction

Procedure ToFindOutPFProducedInProcess(Query, CalculationParameters)
	StructureOfData = CalculationParameters.StructureOfData;
	StructureOfData.Order = StructureOfData.Order + 1;
	
	Query.Text = CalculationParameters.QueryText_disclosureOfSemiFinishedProductsDinStructure;
	ResultsArray = Query.ExecuteBatch();
	
	TransferDataFromQueryResults(ResultsArray, CalculationParameters);
	
	TemporaryTableNames = "PFRaznozlovkaByDinStructure, UsedSemiFinishedProducts, DenominatorOfUsedProductsSpecifications"; //@Query-part
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query.TempTablesManager, TemporaryTableNames);
	
	DistributePFConsumptionByPossibleReleases(Query, CalculationParameters, False);
	ToPlaceUsedSemiFinishedProductsOfIWT(Query.TempTablesManager,
		CalculationParameters.StructureOfData.UsedSemiFinishedProducts);
		
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
		Query.TempTablesManager,
		"DenominatorOfUsedProductsSpecifications",
		CalculationParameters.StructureOfData.DenominatorOfUsedProductsSpecifications,
		"BillOfMaterials,KeyLot,Denominator",
		"KeyLot,BillOfMaterials");
		
	Query.Text = CalculationParameters.QueryText_SemiFinishedProducts;
	
	ResultsArray = Query.ExecuteBatch();
	LastQueryIndex = ResultsArray.Count() - 1;
	
	// 15 Issue of the Order frame
	TransferDataFromQueryResultToValuesTable(StructureOfData.PFIssuesWithinOrder,
		ResultsArray[LastQueryIndex - 1], False);

	If ResultsArray[LastQueryIndex].IsEmpty() Then
		Return;
	EndIf;
	
	// 10 Multipliers for semi-finished products produced by the process.
	SamplingMultipliers = ResultsArray[LastQueryIndex].Select();
	While SamplingMultipliers.Next() Do
		NewMultiplier = StructureOfData.Multipliers.Add();
		FillPropertyValues(NewMultiplier, SamplingMultipliers);
		NewMultiplier.Order = StructureOfData.Order;
	EndDo;
	
	ToFindOutPFProducedInProcess(Query, CalculationParameters);
	
EndProcedure

// In this procedure, it is determined how the PF will be located.
// In the case of the presence of a launched, incl. completed production of PF, the uncoupling will take place through the stages.
// The amount that will be unearthed through the stages is distributed according to the residual principle.
// The number of over stages is determined through bill of materials.
// It should be borne in mind that one PF required at different levels can be partially launched at different stages.
Procedure DistributePFConsumptionByPossibleReleases(Query, CalculationParameters, DistributeGPVStagesLotReferenceNotReleased)
	
	If DistributeGPVStagesLotReferenceNotReleased Then
		QueryText = "
		|SELECT
		|	PEPNV.ToExpenseAs										AS ToExpenseAs,
		|	TRUE														AS ThereIsNoUncouplingInStructure,
		|	RECORDAUTONUMBER()											AS RowID,
		|	TRUE														AS GPVStage,
		|	PEPNV.Department											AS Department,
		|	PEPNV.ProductionOrder									AS ProductionOrder,
		|	PEPNV.Period												AS Period,
		|	PEPNV.ManufacturedProduct												AS ManufacturedProduct,
		|	PEPNV.ItemVariant								AS ItemVariant,
		|	PEPNV.AssignmentOfProducts									AS AssignmentOfProducts,
		|	PEPNV.LotProductBOM							AS LotProductBOM,
		|	PEPNV.ProductionByThirdParty									AS ProductionByThirdParty,
		|
		|	PEPNV.SemiFinishedProduct											AS SemiFinishedProduct,
		|	PEPNV.ItemVariantsOfIntermediateProduct							AS ItemVariantsOfIntermediateProduct,
		|
		|	PEPNV.BillOfMaterials											AS SemiFinishedProductBOM,
		|	PEPNV.LotProductBOM							AS LotSemiFinishedProductBOM,
		|
		|	TRUE														AS ThereIsCreatedStageForReleaseOfPF,
		|	PEPNV.ItemVariantsOfUidString						AS KeyLot,
		|	0								AS NumberIsRunning,
		|	0								AS RequiredNumber,
		|	0								AS Balance,
		|	0								AS Scheduled,
		|	PEPNV.QuantityOfSemiFinishedProduct	AS AllocatedInAssignedProductionLots,
		|	0								AS AllocatedFromAvailableInventoryWithAssignment,
		|	0								AS AllocatedFromAvailableInventory,
		|	
		|	CAST(0.0 AS NUMBER(15, 3))	AS QuantityFromStage,
		|	CAST(0.0 AS NUMBER(15, 3))	AS QuantityFromBillOfMaterials,
		|	1 AS Numerator,
		|	1 AS Denominator
		|
		|INTO UsedSemiFinishedProductsPreliminary_1
		|FROM
		|	ManufacturedProductsHaveNotBeenReleasedInStagesOfLotReference AS PEPNV
		|;
		|";
	Else
		QueryText = "
		|SELECT
		|	FALSE																AS ToExpenseAs,
		|	RECORDAUTONUMBER()													AS RowID,
		|	FALSE																AS GPVStage,
		|	DD.ProductionOrder												AS ProductionOrder,
		|	DD.Department													AS Department,
		|	DD.Period															AS Period,
		|	DD.ManufacturedProduct														AS ManufacturedProduct,
		|	DD.ItemVariant											AS ItemVariant,
		|	DD.AssignmentOfProducts												AS AssignmentOfProducts,
		|	DD.LotProductBOM										AS LotProductBOM,
		|	ISNULL(ManufactureSemiFinishedProduct.ProductionByThirdParty, FALSE)		AS ProductionByThirdParty,
		|	DD.Products														AS SemiFinishedProduct,
		|	DD.Characteristic													AS ItemVariantsOfIntermediateProduct,
		|	NOT ManufactureSemiFinishedProduct.Stage IS NULL
		|		AND VALUETYPE(ManufactureSemiFinishedProduct.Stage) = TYPE(Document.ProductionStage2_2)
		|																		AS ThereIsCreatedStageForReleaseOfPF,
		|	CASE
		|		WHEN ISNULL(ManufactureSemiFinishedProduct.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef)) <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|			THEN ManufactureSemiFinishedProduct.BillOfMaterials
		|		WHEN ISNULL(ConsumptionOfSemiFinishedProducts.SemiFinishedProductBOM, VALUE(Catalog.BillsOfMaterials.EmptyRef)) <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|			THEN ConsumptionOfSemiFinishedProducts.SemiFinishedProductBOM
		|		ELSE ISNULL(CacheReserved.SemiFinishedProductBOM, VALUE(Catalog.BillsOfMaterials.EmptyRef))
		|	END																AS SemiFinishedProductBOM,
		|
		// If there is no PF production in the structure, then we take the bill of materials from the consumption line
		|	CASE
		|		WHEN VALUETYPE(ManufactureSemiFinishedProduct.Stage) = TYPE(Document.ProductionStage2_2)
		|			THEN ManufactureSemiFinishedProduct.Stage
		|		WHEN ISNULL(ManufactureSemiFinishedProduct.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef)) <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|			THEN ManufactureSemiFinishedProduct.BillOfMaterials
		|		WHEN ISNULL(ConsumptionOfSemiFinishedProducts.SemiFinishedProductBOM, VALUE(Catalog.BillsOfMaterials.EmptyRef)) <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|			THEN ConsumptionOfSemiFinishedProducts.SemiFinishedProductBOM
		|		ELSE ISNULL(CacheReserved.SemiFinishedProductBOM, VALUE(Catalog.BillsOfMaterials.EmptyRef))
		|	END																	AS LotSemiFinishedProductBOM,
		|
		|	ManufactureSemiFinishedProduct.KeyProducts								AS KeyProducts,
		|	ISNULL(ManufactureSemiFinishedProduct.KeyLot, &EmptyUIDString)		AS KeyLot,
		|
		|	DD.Required2 - DD.AllocatedFromAvailableInventoryWithAssignment - DD.AllocatedFromAvailableInventory 
		|		- DD.AllocatedInAssignedProductionLots - DD.AllocatedInFreeProductionLots
		|		- ISNULL(ManufactureSemiFinishedProduct.AllocatedInAssignedProductionLots, 0) AS Balance,
		|	ConsumptionOfSemiFinishedProducts.Required2										AS RequiredNumber,
		|	ISNULL(ProductionOfSemiFinishedProductHasBeenLaunched.Launched, 0)					AS NumberIsRunning,
		|	ManufactureSemiFinishedProduct.KeyProducts IS NULL
		|		OR VALUETYPE(ManufactureSemiFinishedProduct.Stage) = TYPE(Document.ProductionStage2_2) AS ThereIsNoUncouplingInStructure,
		// The production of one PF (one nomenclature key) can be partially launched.
		// It is distributed separately, for cases when the production of a semi-factory.The stage of the link to the document is an explicit reference from which stage the PF is expected,
		// but if the PF is released, then there will no longer be a link to the Stage and the number of stocks distributed separately remains, but it does not give a 100% guarantee that the PF is released under this order,
		// for such cases it is necessary to search in subordinate stages whether there is a PF release, if that is, to find out through these releases, if not, then find out through the specification.
		// It is also necessary to take into account that 
		// Based on the description above, the phased distribution will be implemented according to the residual principle.
		|	ISNULL(ManufactureSemiFinishedProduct.Scheduled, 0) 					* DD.Numerator / DD.Denominator	AS Scheduled,
		|	ISNULL(ManufactureSemiFinishedProduct.AllocatedInAssignedProductionLots, 0)	* DD.Numerator / DD.Denominator	AS AllocatedInAssignedProductionLots,
		|	ISNULL(CacheReserved.AllocatedFromAvailableInventoryWithAssignment, 0) 		* DD.Numerator / DD.Denominator	AS AllocatedFromAvailableInventoryWithAssignment,
		|	ISNULL(CacheReserved.AllocatedFromAvailableInventory, 0) 					* DD.Numerator / DD.Denominator	AS AllocatedFromAvailableInventory,
		|
		|	DD.Numerator
		|		* ISNULL(SideIssuePF.Scheduled, 1) / ISNULL(SideIssuePF.TotalQuantity, 1)
		|		* CASE WHEN ISNULL(PlannedByKeyBatches.Scheduled, 1) = 0  
		|			THEN 1
		|			ELSE ISNULL(ManufactureSemiFinishedProduct.Scheduled, 1) / ISNULL(PlannedByKeyBatches.Scheduled, 1)
		|		END AS Numerator,
		|	DD.Denominator AS Denominator
		|
		|INTO UsedSemiFinishedProductsPreliminary_1
		|FROM
		|	ConsumptionOfMaterialsAndSemiFinishedProducts AS DD
		|		LEFT JOIN TTCacheStructureOrder AS ManufactureSemiFinishedProduct
		|		ON (DD.KeyProducts = ManufactureSemiFinishedProduct.KeyProducts)
		|			AND (ManufactureSemiFinishedProduct.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
		|
		|		LEFT JOIN TTCacheStructureOrder AS ConsumptionOfSemiFinishedProducts
		|		ON (DD.KeyProducts = ConsumptionOfSemiFinishedProducts.KeyProducts)
		|			AND (ConsumptionOfSemiFinishedProducts.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
		|		
		|		LEFT JOIN TTCacheOrderStructure_LaunchedByLotReferenceKeys AS ProductionOfSemiFinishedProductHasBeenLaunched
		|		ON (ManufactureSemiFinishedProduct.KeyLot = ProductionOfSemiFinishedProductHasBeenLaunched.KeyLot)
		|
		|		LEFT JOIN TTCacheStructureOrder AS CacheReserved
		|		ON DD.KeyProducts = CacheReserved.KeyProducts
		|			AND DD.KeyLot = CacheReserved.KeyLot
		|			AND CacheReserved.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
		|
		// See Comment 636.
		|		LEFT JOIN SideIssuePF AS SideIssuePF
		|		ON ManufactureSemiFinishedProduct.KeyLot = SideIssuePF.KeyLot
		|			AND DD.Products = SideIssuePF.Products
		|			AND DD.Characteristic = SideIssuePF.Characteristic
		|
		|		LEFT JOIN PlannedByKeyBatches AS PlannedByKeyBatches
		|		ON PlannedByKeyBatches.KeyLot = ManufactureSemiFinishedProduct.KeyLot
		|
		|WHERE
		|	DD.ThisIsASemiFinishedProduct
		|	AND (ISNULL(ManufactureSemiFinishedProduct.Scheduled, 0) <> 0
		|		OR ISNULL(ManufactureSemiFinishedProduct.AllocatedInAssignedProductionLots, 0) <> 0
		|		OR ISNULL(CacheReserved.AllocatedFromAvailableInventoryWithAssignment, 0) <> 0
		|		OR ISNULL(CacheReserved.AllocatedFromAvailableInventory, 0) <> 0
		|	)
		|;
		|";
	EndIf;
	
	QueryText = QueryText + "
	|SELECT
	|	DD.ToExpenseAs						AS ToExpenseAs,
	|	-1										AS Source_ID,
	|	DD.RowID					AS RowID,
	|	DD.GPVStage								AS GPVStage,
	|	DATETIME(1, 1, 1)						AS ProductionDate,
	|	VALUE(Document.ProductionStage2_2.EmptyRef) AS ReleasingStage,
	|	VALUE(Document.ProductionStage2_2.EmptyRef) AS ConsumingStage,
	|	FALSE									AS LotIsReleased,
	|	DD.ThereIsNoUncouplingInStructure				AS ThereIsNoUncouplingInStructure,
	|	DD.Department						AS Department,
	|	DD.ProductionOrder					AS ProductionOrder,
	|	DD.Period								AS Period,
	|	DD.ManufacturedProduct							AS ManufacturedProduct,
	|	DD.ItemVariant				AS ItemVariant,
	|	DD.AssignmentOfProducts					AS AssignmentOfProducts,
	|	DD.LotProductBOM			AS LotProductBOM,
	|	DD.ProductionByThirdParty				AS ProductionByThirdParty,
	|	DD.SemiFinishedProduct							AS SemiFinishedProduct,
	|	DD.ItemVariantsOfIntermediateProduct			AS ItemVariantsOfIntermediateProduct,
	|	DD.SemiFinishedProductBOM			AS SemiFinishedProductBOM,
	|	DD.ThereIsCreatedStageForReleaseOfPF			AS ThereIsCreatedStageForReleaseOfPF,
	|	DD.LotSemiFinishedProductBOM		AS LotSemiFinishedProductBOM,
	|	DD.KeyLot							AS KeyLot,
	|
	|	DD.NumberIsRunning					AS NumberIsRunning,
	|	DD.RequiredNumber					AS RequiredNumber,
	|	DD.Balance								AS Balance,
	|
	|	DD.Scheduled						AS Scheduled,
	|	DD.AllocatedInAssignedProductionLots		AS AllocatedInAssignedProductionLots,
	|	DD.AllocatedFromAvailableInventoryWithAssignment		AS AllocatedFromAvailableInventoryWithAssignment,
	|	DD.AllocatedFromAvailableInventory				AS AllocatedFromAvailableInventory,
	|	CAST(0.0 AS NUMBER(15, 3))			AS QuantityFromStage,
	|	CAST(0.0 AS NUMBER(15, 3))			AS QuantityFromBillOfMaterials,
	|	
	|	ISNULL(CostSharesAccordingToBillOfMaterials.CostShare, 1) * DD.Numerator / DD.Denominator
	|		/ ISNULL(TotalCostSharesAccordingToBillOfMaterials.TotalCostShare, 1)					AS CostShareRatio,
	|	ISNULL(CostSharesAccordingToBillOfMaterials.CostShare, 1) * DD.Numerator / DD.Denominator	AS Numerator,
	|	ISNULL(TotalCostSharesAccordingToBillOfMaterials.TotalCostShare, 1)						AS Denominator
	|INTO UsedSemiFinishedProductsPreliminary_2
	|FROM
	|	UsedSemiFinishedProductsPreliminary_1 AS DD
	|		LEFT JOIN TotalCostSharesAccordingToBillOfMaterials AS TotalCostSharesAccordingToBillOfMaterials
	|		ON DD.SemiFinishedProductBOM = TotalCostSharesAccordingToBillOfMaterials.BillOfMaterials
	|
	|		LEFT JOIN CostSharesAccordingToBillOfMaterials AS CostSharesAccordingToBillOfMaterials
	|		ON DD.SemiFinishedProductBOM = CostSharesAccordingToBillOfMaterials.BillOfMaterials
	|			AND DD.SemiFinishedProduct = CostSharesAccordingToBillOfMaterials.Products
	|			AND (DD.ItemVariantsOfIntermediateProduct = CostSharesAccordingToBillOfMaterials.Characteristic
	|				OR CostSharesAccordingToBillOfMaterials.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// DenominatorOfUsedProductsSpecifications
	|SELECT
	|	DD.SemiFinishedProductBOM AS BillOfMaterials,
	|	DD.KeyLot AS KeyLot,
	|	FALSE AS ThisIsOutput_,
	|	SUM(DD.Numerator) AS Denominator
	|
	|FROM UsedSemiFinishedProductsPreliminary_2 AS DD
	|
	|GROUP BY
	|	DD.SemiFinishedProductBOM,
	|	DD.KeyLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExternalSrc.RowID AS Source_ID,
	|	DD.RowID AS Receiver_ID
	|
	|FROM
	|	UsedSemiFinishedProductsPreliminary_1 AS DD
	|		INNER JOIN ManufacturedProducts AS ExternalSrc
	|		ON
	|			CASE WHEN DD.ThereIsCreatedStageForReleaseOfPF
	|				THEN DD.LotSemiFinishedProductBOM = ExternalSrc.ReleasingStage
	|			ELSE
	|				DD.SemiFinishedProductBOM = ExternalSrc.BillOfMaterials
	|			END
	|
	|			AND DD.ProductionOrder = ExternalSrc.ProductionOrder
	|			AND DD.Department = ExternalSrc.Department
	|
	|			AND CASE WHEN DD.GPVStage THEN
	|				DD.ManufacturedProduct = ExternalSrc.Products
	|				AND DD.ItemVariant = ExternalSrc.Characteristic
	|				AND NOT ExternalSrc.LotIsReleased
	|			ELSE
	|				DD.SemiFinishedProduct = ExternalSrc.Products
	|				AND DD.ItemVariantsOfIntermediateProduct = ExternalSrc.Characteristic
	|			END
	|
	|			AND ((DD.AssignmentOfProducts = VALUE(Catalog.Assignments.EmptyRef)
	|					AND ExternalSrc.AssignmentIsEmpty)
	|				OR (DD.AssignmentOfProducts = ExternalSrc.Purpose)
	|			)
	|			AND DD.ProductionByThirdParty = ExternalSrc.ProductionByThirdParty
	|			AND DD.ToExpenseAs = ExternalSrc.ToExpenseAs
	|
	|WHERE
	//	see comment 1391
	|	NOT DD.ProductionByThirdParty
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.ToExpenseAs						AS ToExpenseAs,
	|	DD.Source_ID 							AS Source_ID,
	|	DD.RowID					AS RowID,
	|	DD.GPVStage								AS GPVStage,
	|	DD.ProductionDate						AS ProductionDate,
	|	DD.ReleasingStage						AS ReleasingStage,
	|	DD.ConsumingStage						AS ConsumingStage,
	|	DD.LotIsReleased						AS LotIsReleased,
	|	DD.ThereIsNoUncouplingInStructure				AS ThereIsNoUncouplingInStructure,
	|	DD.Department						AS Department,
	|	DD.ProductionOrder					AS ProductionOrder,
	|	DD.Period								AS Period,
	|	DD.ManufacturedProduct							AS ManufacturedProduct,
	|	DD.ItemVariant				AS ItemVariant,
	|	DD.AssignmentOfProducts					AS AssignmentOfProducts,
	|	DD.LotProductBOM			AS LotProductBOM,
	|	DD.ProductionByThirdParty				AS ProductionByThirdParty,
	|	DD.SemiFinishedProduct							AS SemiFinishedProduct,
	|	DD.ItemVariantsOfIntermediateProduct			AS ItemVariantsOfIntermediateProduct,
	|	DD.SemiFinishedProductBOM			AS SemiFinishedProductBOM,
	|	DD.ThereIsCreatedStageForReleaseOfPF			AS ThereIsCreatedStageForReleaseOfPF,
	|	DD.LotSemiFinishedProductBOM		AS LotSemiFinishedProductBOM,
	|	DD.KeyLot							AS KeyLot,
	|
	|	DD.NumberIsRunning					AS NumberIsRunning,
	|	DD.RequiredNumber					AS RequiredNumber,
	|	DD.Balance								AS Balance,
	|
	|	DD.Scheduled						AS Scheduled,
	|	DD.AllocatedInAssignedProductionLots		AS AllocatedInAssignedProductionLots,
	|	DD.AllocatedFromAvailableInventoryWithAssignment		AS AllocatedFromAvailableInventoryWithAssignment,
	|	DD.AllocatedFromAvailableInventory				AS AllocatedFromAvailableInventory,
	|	DD.QuantityFromStage					AS QuantityFromStage,
	|	DD.QuantityFromBillOfMaterials				AS QuantityFromBillOfMaterials,
	|	
	|	DD.CostShareRatio				AS CostShareRatio,
	|	DD.Numerator							AS Numerator,
	|	DD.Denominator							AS Denominator
	|FROM
	|	UsedSemiFinishedProductsPreliminary_2 AS DD
	|
	|ORDER BY
	// First, we will take the amount of manufactured PF from the explicitly specified stages.
	|	DD.ThereIsCreatedStageForReleaseOfPF DESC,
	|	DD.Period
	|";
	
	Query.Text = QueryText;
	QueryResults = Query.ExecuteBatch();
	LastQueryIndex = QueryResults.Count() - 1;
	UsedSemiFinishedProductsPreliminary = QueryResults[LastQueryIndex].Unload();
	SourcesReceivers = QueryResults[LastQueryIndex - 1].Unload();
	SourcesReceivers.Indexes.Add("Receiver_ID");
	
	DenominatorOfUsedProductsSpecifications = QueryResults[LastQueryIndex - 2].Select();
	While DenominatorOfUsedProductsSpecifications.Next() Do
		NewRow = CalculationParameters.StructureOfData.DenominatorOfUsedProductsSpecifications.Add();
		FillPropertyValues(NewRow, DenominatorOfUsedProductsSpecifications);
	EndDo;
	
	If CalculationParameters.StructureOfData.Property("UsedSemiFinishedProducts") Then
		UsedSemiFinishedProducts = CalculationParameters.StructureOfData.UsedSemiFinishedProducts;
	Else
		UsedSemiFinishedProducts = UsedSemiFinishedProductsPreliminary.CopyColumns("ToExpenseAs,
			|Source_ID,
			|RowID,GPVStage,
			|ProductionDate,ReleasingStage,LotIsReleased,ThereIsNoUncouplingInStructure,Department,
			|ProductionOrder,Period,ProductionByThirdParty,ThereIsCreatedStageForReleaseOfPF,KeyLot,
			|NumberIsRunning,RequiredNumber,Balance,Scheduled,AllocatedInAssignedProductionLots,
			|AllocatedFromAvailableInventoryWithAssignment,AllocatedFromAvailableInventory,
			|QuantityFromStage,QuantityFromBillOfMaterials,
			|CostShareRatio,Numerator,Denominator");
	
		// At the first call, the columns may not have suitable or not all the necessary types,
		// so we define part of the columns explicitly.
		ArrayOfTypesLotReferencesBillOfMaterials = New Array();
		ArrayOfTypesLotReferencesBillOfMaterials.Add(Type("CatalogRef.BillsOfMaterials"));
		ArrayOfTypesLotReferencesBillOfMaterials.Add(Type("DocumentRef.ProductionStage2_2"));
		DescriptionOfLotReferenceTypeBillOfMaterials = New TypeDescription(ArrayOfTypesLotReferencesBillOfMaterials);
		
		UsedSemiFinishedProducts.Columns.Add("ManufacturedProduct", New TypeDescription("CatalogRef.Products"));
		UsedSemiFinishedProducts.Columns.Add("ItemVariant",
			New TypeDescription("CatalogRef.ItemsCharacteristics"));
		UsedSemiFinishedProducts.Columns.Add("AssignmentOfProducts",
			New TypeDescription("CatalogRef.Assignments"));
		UsedSemiFinishedProducts.Columns.Add("LotProductBOM", DescriptionOfLotReferenceTypeBillOfMaterials);
		UsedSemiFinishedProducts.Columns.Add("SemiFinishedProduct", New TypeDescription("CatalogRef.Products"));
		UsedSemiFinishedProducts.Columns.Add("ItemVariantsOfIntermediateProduct",
			New TypeDescription("CatalogRef.ItemsCharacteristics"));
		UsedSemiFinishedProducts.Columns.Add("SemiFinishedProductBOM",
			New TypeDescription("CatalogRef.BillsOfMaterials"));
		UsedSemiFinishedProducts.Columns.Add("LotSemiFinishedProductBOM", DescriptionOfLotReferenceTypeBillOfMaterials);
		UsedSemiFinishedProducts.Columns.Add("ConsumingStage",
			New TypeDescription("DocumentRef.ProductionStage2_2"));
		
		CalculationParameters.StructureOfData.Insert("UsedSemiFinishedProducts", UsedSemiFinishedProducts);
	EndIf;

	For Each Page1 In UsedSemiFinishedProductsPreliminary Do
		
		QuantityNeeded = Page1.Scheduled + Page1.AllocatedInAssignedProductionLots + Page1.AllocatedFromAvailableInventoryWithAssignment;
		// The upper level can pick up the amount for the lower level from the stage,
		// whereas in the upper level there can be a de-lock on the din structure, and the lower level is found out only by stages, 
		// in this case, the upper level is lost because the lower level has another key Lot reference and there is a loss of expenses of materials (including PF) and labor costs.
		QuantityIsRequiredFromStage = QuantityNeeded - Page1.Scheduled;
		
		SuitableSources = SourcesReceivers.FindRows(New Structure("Receiver_ID", Page1.RowID));
		
		If SuitableSources.Count() = 0 Then
			// There is no suitable release of PF, we find out through the specification.
			SpecificationLine = UsedSemiFinishedProducts.Add();
			FillPropertyValues(SpecificationLine, Page1);
			SpecificationLine.QuantityFromBillOfMaterials = QuantityNeeded;
			If SpecificationLine.ThereIsCreatedStageForReleaseOfPF Then
				SpecificationLine.ThereIsCreatedStageForReleaseOfPF = False;
				SpecificationLine.LotSemiFinishedProductBOM = SpecificationLine.SemiFinishedProductBOM;
			EndIf;
			
			Continue;
		EndIf;
		
		For Each Source In SuitableSources Do
			RemainderLine = CalculationParameters.StructureOfData.ManufacturedProducts.Find(Source.Source_ID, "RowID");
			QuantityFromStage = Min(RemainderLine.QuantityReleaseBalance, QuantityIsRequiredFromStage);
			
			If QuantityFromStage = 0 Then
				Continue;
			EndIf;
			
			StageString_ = UsedSemiFinishedProducts.Add();
			FillPropertyValues(StageString_, Page1);
			StageString_.QuantityFromStage = QuantityFromStage;
			StageString_.Source_ID = Source.Source_ID;
			
			RemainderLine.QuantityReleaseBalance = RemainderLine.QuantityReleaseBalance - StageString_.QuantityFromStage;
			QuantityNeeded = QuantityNeeded - StageString_.QuantityFromStage;
			QuantityIsRequiredFromStage = QuantityIsRequiredFromStage - StageString_.QuantityFromStage;
			
			If StageString_.QuantityFromStage > 0 Then
				StageString_.LotIsReleased = RemainderLine.LotIsReleased;
				StageString_.ProductionDate = RemainderLine.ProductionDate;
				StageString_.ReleasingStage = RemainderLine.ReleasingStage;
				If Not Page1.ThereIsCreatedStageForReleaseOfPF Then
					// A suitable stage for the release of the necessary PF has been found
					StageString_.ThereIsCreatedStageForReleaseOfPF = True;
					StageString_.LotSemiFinishedProductBOM = StageString_.ReleasingStage;
				EndIf;
			EndIf;
			
			If QuantityNeeded = 0 Or QuantityIsRequiredFromStage = 0 Then
				Break;
			EndIf;
		EndDo;
		
		If QuantityNeeded > 0 Then
			SpecificationLine = UsedSemiFinishedProducts.Add();
			FillPropertyValues(SpecificationLine, Page1);
			SpecificationLine.QuantityFromBillOfMaterials = QuantityNeeded;
			SpecificationLine.ThereIsCreatedStageForReleaseOfPF = False;
			SpecificationLine.LotSemiFinishedProductBOM = Page1.SemiFinishedProductBOM;
		EndIf;
	EndDo;
	
	Query.Text = "DROP UsedSemiFinishedProductsPreliminary_1;
	|DROP UsedSemiFinishedProductsPreliminary_2";
	Query.Execute();
	
EndProcedure

Procedure ToPlaceUsedSemiFinishedProductsOfIWT(TempTablesManager, UsedSemiFinishedProducts)
	
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(TempTablesManager,
		"UsedSemiFinishedProducts", UsedSemiFinishedProducts,
		"ToExpenseAs,Source_ID,GPVStage,ProductionDate,ReleasingStage,ConsumingStage,
		|LotIsReleased,ThereIsNoUncouplingInStructure,Department,
		|ProductionOrder,Period,ManufacturedProduct,ItemVariant,AssignmentOfProducts,LotProductBOM,
		|ProductionByThirdParty,SemiFinishedProduct,ItemVariantsOfIntermediateProduct,SemiFinishedProductBOM,
		|ThereIsCreatedStageForReleaseOfPF,LotSemiFinishedProductBOM,KeyLot,NumberIsRunning,RequiredNumber,
		|Balance,Scheduled,AllocatedInAssignedProductionLots,AllocatedFromAvailableInventoryWithAssignment,AllocatedFromAvailableInventory,
		|QuantityFromStage,QuantityFromBillOfMaterials,CostShareRatio,Numerator,Denominator");
	UsedSemiFinishedProducts.Clear();

EndProcedure

Function QueryText_PlannedLaborCosts()
	QueryText = "
	|SELECT
	|	DD.ProductionOrder			AS ProductionOrder,
	|	CASE
	|		WHEN VALUETYPE(PP.LotSemiFinishedProductBOM) = TYPE(Document.ProductionStage2_2)
	|			THEN PP.LotSemiFinishedProductBOM
	|		ELSE DD.BillOfMaterials
	|	END							AS LotBOM,
	|	DD.KeyLot					AS KeyLot,
	|	DD.Period						AS Period,
	|	DD.Department				AS Department,
	|	DD.ProductCostElement			AS ProductCostElement,
	|	DD.WorkKind						AS WorkKind,
	// PF can be produced for 2 or more levels in one stage.
	// To correctly calculate the amount of labor required for a certain level,
	// it is necessary to calculate them as a ratio of the amount of PF for tech. level, to the number of PF for all levels.
	|	CASE
	|		WHEN PP.NumberIsRunning = 0
	|			THEN DD.Count
	|		ELSE DD.Count * PP.QuantityByLotReferenceBillOfMaterials / PP.NumberIsRunning 
	|	END * PP.Numerator / PP.Denominator	AS Count,
	|	BEGINOFPERIOD(DD.Period, MONTH)			AS CostPeriod,
	|	""LaborCosts""						AS Comment
	|FROM
	|	PFManufacturedProductsPreliminary AS PP
	|		INNER JOIN TTCacheLaborCostsOfOrderStructure AS DD
	|		ON PP.KeyLot = DD.KeyLot
	|";
	
	Return QueryText;
EndFunction

// Generates temporary tables for the preparation of consumable materials and PF when unifying din. structures, data are prepared for each level of nodulation.
// Parameters:
//  PFManufacturingProductTTName - String - A string defining the data source,
//    at the first level the data source is TT "Productionproducts",
//    at the next levels "Pfrazuzlovka Substructure".
Function QueryText_ConsumptionOfMaterialsAndSemiFinishedProducts(PFManufacturingProductTTName)
	
	QueryText = "
	|SELECT
	|	PFManufacturedProducts.LotSemiFinishedProductBOM 		AS LotSemiFinishedProductBOM,
	|	PFManufacturedProducts.LotProductBOM				AS LotProductBOM,
	|	PFManufacturedProducts.ManufacturedProduct								AS ManufacturedProduct,
	|	PFManufacturedProducts.ItemVariant					AS ItemVariant,
	|	PFManufacturedProducts.AssignmentOfProducts						AS AssignmentOfProducts,
	|	PFManufacturedProducts.KeyLot								AS KeyLot,
	|	PFManufacturedProducts.ProductionByThirdParty					AS ProductionByThirdParty,
	|	SUM(PFManufacturedProducts.NumberIsRunning)				AS NumberIsRunning,
	|	SUM(PFManufacturedProducts.QuantityByLotReferenceBillOfMaterials)	AS QuantityByLotReferenceBillOfMaterials,
	|	MAX(PFManufacturedProducts.CostShareRatio)		AS CostShareRatio,
	|	SUM(PFManufacturedProducts.Numerator)						AS Numerator,
	|	PFManufacturedProducts.Denominator								AS Denominator
	|INTO PFManufacturedProductsPreliminary
	|FROM
	|	ManufactureOfProducts AS PFManufacturedProducts
	|
	|WHERE
	//	see comment 1391
	|	NOT PFManufacturedProducts.ProductionByThirdParty
	|
	|GROUP BY
	|	PFManufacturedProducts.LotSemiFinishedProductBOM,
	|	PFManufacturedProducts.LotProductBOM,
	|	PFManufacturedProducts.ManufacturedProduct,
	|	PFManufacturedProducts.ItemVariant,
	|	PFManufacturedProducts.AssignmentOfProducts,
	|	PFManufacturedProducts.KeyLot,
	|	PFManufacturedProducts.ProductionByThirdParty,
	|	PFManufacturedProducts.Denominator
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Warehouse									AS Warehouse,
	|	DD.Period									AS Period,
	|	DD.Stage										AS Stage,
	|	PFManufacturedProducts.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|	DD.BillOfMaterials								AS BillOfMaterials,
	|	DD.Department							AS Department,
	|	PFManufacturedProducts.LotProductBOM		AS LotProductBOM,
	|	PFManufacturedProducts.ManufacturedProduct						AS ManufacturedProduct,
	|	PFManufacturedProducts.ItemVariant			AS ItemVariant,
	|	PFManufacturedProducts.AssignmentOfProducts				AS AssignmentOfProducts,
	|	DD.ThisIsASemiFinishedProduct		AS ThisIsASemiFinishedProduct,
	|	DD.ProductCostElement	AS ProductCostElement,
	|	DD.Products			AS Products,
	|	DD.Characteristic		AS Characteristic,
	|	DD.Purpose			AS Purpose,
	|	DD.ProductionOrder	AS ProductionOrder,
	|	DD.KeyProducts		AS KeyProducts,
	|	DD.KeyLot			AS KeyLot,
	|	CASE WHEN DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.AvailableRelease)
	|		THEN - DD.Scheduled
	|		ELSE (DD.Required2 + DD.Done)
	// There are 2 types of work:
	//		* Detached, then provided under the order.
	//		* Not isolated works, not secured, quantity in unsecured.
	|			+ CASE WHEN DD.ThisIsWork AND NOT DD.ThisIsASemiFinishedProduct
	|					THEN DD.NotProvide
	|				ELSE 0
	|			END
	|	END
	// Commentary 1877.
	// PF can be produced for 2 or more levels in one stage.
	// To correctly calculate the amount of materials needed for a certain level,
	// it is necessary to calculate them as the ratio of the amount of PF for current. level, to the number of PF for all levels.
	|		* CASE
	|			WHEN PFManufacturedProducts.NumberIsRunning = 0
	|				THEN 1
	|			ELSE PFManufacturedProducts.QuantityByLotReferenceBillOfMaterials / PFManufacturedProducts.NumberIsRunning
	|		END								
	|		* PFManufacturedProducts.Numerator / PFManufacturedProducts.Denominator	AS Required2,
	|	DD.AllocatedFromAvailableInventoryWithAssignment						AS AllocatedFromAvailableInventoryWithAssignment,
	|	DD.AllocatedFromAvailableInventory								AS AllocatedFromAvailableInventory,
	|	DD.AllocatedInAssignedProductionLots						AS AllocatedInAssignedProductionLots,
	|	DD.AllocatedInFreeProductionLots									AS AllocatedInFreeProductionLots,
	|	PFManufacturedProducts.CostShareRatio					AS CostShareRatio,
	|	PFManufacturedProducts.Numerator									AS Numerator,
	|	PFManufacturedProducts.Denominator									AS Denominator
	|
	|INTO ConsumptionOfMaterialsAndSemiFinishedProducts
	|FROM
	|	PFManufacturedProductsPreliminary AS PFManufacturedProducts
	|		INNER JOIN TTCacheStructureOrder AS DD
	|		ON DD.KeyLot = PFManufacturedProducts.KeyLot
	|		
	|WHERE
	|	DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|	OR (DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.AvailableRelease)
	|			AND DD.Scheduled > 0
				// Addition to comment 695:
				//  Items that are in the PM specification are output products, but are not included in the production order,
				//  in the vtkashstructure of the order have the form of a line = Side issue.
				//  In order not to perceive these lines as a side output of the current key party,
				//  we check that within the current specification this is really a side output.
	|			AND TRUE IN (
	|						SELECT TOP 1
	|							TRUE
	|						FROM DinStructureSideOutputBillOfMaterials AS DinStructureSideOutputBillOfMaterials
	|						WHERE DD.BillOfMaterials = DinStructureSideOutputBillOfMaterials.BillOfMaterials
	|							AND DD.Products = DinStructureSideOutputBillOfMaterials.Products
	|							AND DD.Characteristic = DinStructureSideOutputBillOfMaterials.Characteristic
	|						)
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.Warehouses.EmptyRef)	AS Warehouse,
	|	DD.Period									AS Period,
	|	DD.StageLink								AS Stage,
	|	PFManufacturedProducts.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|	DD.BillOfMaterials								AS BillOfMaterials,
	|	DD.Department							AS Department,
	|	PFManufacturedProducts.LotProductBOM		AS LotProductBOM,
	|	PFManufacturedProducts.ManufacturedProduct						AS ManufacturedProduct,
	|	PFManufacturedProducts.ItemVariant			AS ItemVariant,
	|	PFManufacturedProducts.AssignmentOfProducts				AS AssignmentOfProducts,
	|	FALSE					AS ThisIsASemiFinishedProduct,
	|	DD.ProductCostElement	AS ProductCostElement,
	|	DD.Products			AS Products,
	|	DD.Characteristic		AS Characteristic,
	|	DD.Purpose			AS Purpose,
	|	DD.ProductionOrder	AS ProductionOrder,
	|	&EmptyUID				AS KeyProducts,
	|	DD.KeyLot			AS KeyLot,
	|
	|	DD.Count
	// see 1877.
	|		* CASE
	|			WHEN PFManufacturedProducts.NumberIsRunning = 0
	|				THEN 1
	|			ELSE PFManufacturedProducts.QuantityByLotReferenceBillOfMaterials / PFManufacturedProducts.NumberIsRunning
	|		END								
	|		* PFManufacturedProducts.Numerator / PFManufacturedProducts.Denominator AS Required2,
	|
	|	0 AS AllocatedFromAvailableInventoryWithAssignment,
	|	0 AS AllocatedFromAvailableInventory,
	|	0 AS AllocatedInAssignedProductionLots,
	|	0 AS AllocatedInFreeProductionLots,
	|	PFManufacturedProducts.CostShareRatio	AS CostShareRatio,
	|	PFManufacturedProducts.Numerator					AS Numerator,
	|	PFManufacturedProducts.Denominator					AS Denominator
	|
	|FROM
	|	PFManufacturedProductsPreliminary AS PFManufacturedProducts
	|		INNER JOIN DinStructureProductionOnSideInIntermediateStages AS DD
	|		ON DD.KeyLot = PFManufacturedProducts.KeyLot
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.Warehouses.EmptyRef)	AS Warehouse,
	|	DD.Period									AS Period,
	|	DD.Stage										AS Stage,
	|	PFManufacturedProducts.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|	DD.BillOfMaterials								AS BillOfMaterials,
	|	DD.Department							AS Department,
	|	PFManufacturedProducts.LotProductBOM		AS LotProductBOM,
	|	PFManufacturedProducts.ManufacturedProduct						AS ManufacturedProduct,
	|	PFManufacturedProducts.ItemVariant			AS ItemVariant,
	|	PFManufacturedProducts.AssignmentOfProducts				AS AssignmentOfProducts,
	|	DD.ThisIsASemiFinishedProduct		AS ThisIsASemiFinishedProduct,
	|	DD.ProductCostElement	AS ProductCostElement,
	|	DD.Products			AS Products,
	|	DD.Characteristic		AS Characteristic,
	|	DD.Purpose			AS Purpose,
	|	DD.ProductionOrder	AS ProductionOrder,
	|	&EmptyUID				AS KeyProducts,
	|	DD.KeyLot			AS KeyLot,
	|
	|	DD.Required2
	// see 1877.
	|		* CASE
	|			WHEN PFManufacturedProducts.NumberIsRunning = 0
	|				THEN 1
	|			ELSE PFManufacturedProducts.QuantityByLotReferenceBillOfMaterials / PFManufacturedProducts.NumberIsRunning
	|		END								
	|		* PFManufacturedProducts.Numerator / PFManufacturedProducts.Denominator AS Required2,
	|
	|	0 AS AllocatedFromAvailableInventoryWithAssignment,
	|	0 AS AllocatedFromAvailableInventory,
	|	0 AS AllocatedInAssignedProductionLots,
	|	0 AS AllocatedInFreeProductionLots,
	|	PFManufacturedProducts.CostShareRatio	AS CostShareRatio,
	|	PFManufacturedProducts.Numerator					AS Numerator,
	|	PFManufacturedProducts.Denominator					AS Denominator
	|
	|FROM
	|	PFManufacturedProductsPreliminary AS PFManufacturedProducts
	|		INNER JOIN SideOutputInProductionOrder AS DD
	|		ON DD.KeyLot = PFManufacturedProducts.KeyLot
	|
	|";
	
	If PFManufacturingProductTTName <> "ManufactureOfProducts" Then //@Query-part
		QueryText = StrReplace(QueryText, "ManufactureOfProducts", PFManufacturingProductTTName); //@Query-part
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region SeparationOfStagesForProduction

Procedure SeparationOfStagesForProduction(Query, CalculationParameters)
	
	Query.Text = QueryText_PrimaryDataForStages();
	
	Query.Execute();
	CalculationParameters.Insert("QueryText_StageSeparation", QueryText_StageSeparation());
	
	ReleasingStagesForLotReferenceKeys = New ValueTable();
	ReleasingStagesForLotReferenceKeys.Columns.Add("KeyLot",
		New TypeDescription("String", New StringQualifiers(36)));
	ReleasingStagesForLotReferenceKeys.Columns.Add("ReleasingStage",
		New TypeDescription("DocumentRef.ProductionStage2_2"));
	ReleasingStagesForLotReferenceKeys.Columns.Add("Numerator",
		Common.TypeDescriptionNumber(31, 6, AllowedSign.Nonnegative));
	ReleasingStagesForLotReferenceKeys.Columns.Add("Denominator",
		Common.TypeDescriptionNumber(31, 6, AllowedSign.Nonnegative));
	ReleasingStagesForLotReferenceKeys.Columns.Add("QuantityOfSemiFinishedProduct",
		Common.TypeDescriptionNumber(22, 7, AllowedSign.Nonnegative));
	CalculationParameters.StructureOfData.Insert("ReleasingStagesForLotReferenceKeys", ReleasingStagesForLotReferenceKeys);
	ToFindOutStagesForProduction(Query, CalculationParameters, True);
	
	ReleasingStagesForLotReferenceKeys.GroupBy("KeyLot, ReleasingStage, Denominator", "Numerator, QuantityOfSemiFinishedProduct");
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"ReleasingStagesForLotReferenceKeys", ReleasingStagesForLotReferenceKeys,
		"KeyLot, ReleasingStage, Numerator, Denominator, QuantityOfSemiFinishedProduct", "ReleasingStage");
	
	// We fill in the data on expenses from all the releasing stages
	Query.Text = "
	// 13 Planned material costs
	|SELECT
	|	DD.CostPeriod				AS Period,
	|	DD.CostPeriod				AS CostPeriod,
	|	&StandardCostEstimate				AS StandardCostEstimate,
	|	DD.ReleasingStage			AS LotBOM,
	|	DD.Department			AS Department,
	|	DD.ProductCostElement		AS ProductCostElement,
	|	VEKP.KeyLot				AS KeyLot,
	|	DD.Products				AS Products,
	|	DD.Characteristic			AS Characteristic,
	|	DD.ProducedInProcess AND NOT DD.SideProduct AS ThisIsASemiFinishedProduct,
	|	DD.Plan
	// Commentary 1574.
	// We are processing a partial release, the Lot reference has been released, within the framework of one stage.
	// All the expenses of materials and labor costs in this case will be collected here by multiplicationpartiyipolufabrikat.Calculate the multiplicitypofactical data
	// To exclude an error on materials, on unreleased Lot references,
	// we take materials by the coefficient - The number of total output / The number of Lot references NOT released.
	|		* VEKP.Numerator / VEKP.Denominator AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS OffBalanceCost,
	|	0 AS OffBalanceCostLocal,
	|	
	|	""PlannedMaterialCosts"" AS Comment
	|FROM
	|	ReleasingStagesForLotReferenceKeys AS VEKP
	|		INNER JOIN MaterialPlan AS DD
	|			ON DD.ReleasingStage = VEKP.ReleasingStage
	|WHERE
	// See comment 3145.
	|	NOT DD.IntermediateOutput
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Period					AS Period,
	|	DD.Period					AS CostPeriod,
	|	&StandardCostEstimate				AS StandardCostEstimate,
	|	DD.ReleasingStage			AS LotBOM,
	|	DD.Department			AS Department,
	|	DD.ProductCostElement		AS ProductCostElement,
	|	VEKP.KeyLot				AS KeyLot,
	|	DD.Products				AS Products,
	|	DD.Characteristic			AS Characteristic,
	|	FALSE						AS ThisIsASemiFinishedProduct,
	|	VEKP.QuantityOfSemiFinishedProduct * DD.QuantityPerReleaseLotUnit
		// See 1574.
	|		* VEKP.Numerator / VEKP.Denominator AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS OffBalanceCost,
	|	0 AS OffBalanceCostLocal,
	|	
	|	""PlannedMaterialCosts"" AS Comment
	|
	|FROM ReleasingStagesForLotReferenceKeys AS VEKP
	|		INNER JOIN ProductionOnSideInIntermediateStages AS DD
	|			ON DD.ReleasingStage = VEKP.ReleasingStage
	|;
	|////////////////////////////////////////////////////////////////////////////////
	// 14 Planned labor costs
	|SELECT
	|	CASE
	|		WHEN NOT LaborCosts.Completed2
	|			THEN DocumentStage.Date
	|		WHEN DocumentStage.WorkPerformanceAsOneDay
	|			THEN DocumentStage.WorkExecutionDate
	|		ELSE LaborCosts.ExecutionDate
	|	END								AS Period,
	|	DocumentStage.ReleasingStage		AS LotBOM,
	|	LaborCosts.Department			AS Department,
	|	LaborCosts.ProductCostElement		AS ProductCostElement,
	|	VEKP.KeyLot						AS KeyLot,
	|	LaborCosts.WorkKind				AS WorkKind,
	// Plan
	|	LaborCosts.Count * VEKP.Numerator / VEKP.Denominator AS Count,
	|	CASE
	|		WHEN NOT LaborCosts.Completed2
	|			THEN DocumentStage.Date
	|		WHEN DocumentStage.WorkPerformanceAsOneDay
	|			THEN DocumentStage.WorkExecutionDate
	|		ELSE LaborCosts.ExecutionDate
	|	END								AS CostPeriod,
	|	""LaborCosts""					AS Comment
	|
	|FROM
	|	ReleasingStagesForLotReferenceKeys AS VEKP
	|	
	|		INNER JOIN DetailsOfStagesOfParties AS DocumentStage
	|		ON DocumentStage.ReleasingStage = VEKP.ReleasingStage
	|		
	|		INNER JOIN Document.ProductionStage2_2.LaborCosts AS LaborCosts
	|		ON (DocumentStage.Stage = LaborCosts.Ref)
	|			AND NOT LaborCosts.Canceled
	|			AND NOT DocumentStage.LotIsReleased
	|		
	|";
	
	ResultsArray = Query.ExecuteBatch();
	TransferDataFromQueryResults(ResultsArray, CalculationParameters);
	ReCalculateDenominatorsForUnreleasedLotReferences(CalculationParameters);
	AddMultipliersForPossibleSemiFinishedProducts(CalculationParameters);
	
EndProcedure

// For the correct calculation of values for unreleased Lot references, it is necessary to recalculate the denominators.
Procedure ReCalculateDenominatorsForUnreleasedLotReferences(CalculationParameters)
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"Multipliers", CalculationParameters.StructureOfData.Multipliers,
		CalculationParameters.Multipliers_GroupingColumns + ", "+ CalculationParameters.Multipliers_SummationColumns,
		"CalculationIsCompleted,LotIsReleased"
	);
	Query.Text = "
		|SELECT
		|	DD.LotIsReleased AS LotIsReleased,
		|	CASE WHEN DD.LotSemiFinishedProductBOM = UNDEFINED
		|		THEN DD.LotProductBOM
		|		ELSE UNDEFINED
		|	END AS LotProductBOM,
		|	DD.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	SUM(DD.Numerator) AS Denominator,
		|	MAX(DD.Order) AS Order,
		|	DD.KeyLot
		|INTO CommonDenominators
		|FROM
		|	Multipliers AS DD
		|WHERE
		|	NOT DD.LotIsReleased
		|	AND CASE
		|		WHEN DD.LotSemiFinishedProductBOM = UNDEFINED
		|			THEN VALUETYPE(DD.LotProductBOM) <> TYPE(Catalog.BillsOfMaterials)
		|		ELSE
		|			VALUETYPE(DD.LotSemiFinishedProductBOM) <> TYPE(Catalog.BillsOfMaterials)
		|		END
		|
		|GROUP BY
		|	DD.LotIsReleased,
		|	CASE WHEN DD.LotSemiFinishedProductBOM = UNDEFINED
		|		THEN DD.LotProductBOM
		|		ELSE UNDEFINED
		|	END,
		|	DD.LotSemiFinishedProductBOM,
		|	DD.KeyLot
		|
		|INDEX BY
		|	LotIsReleased,
		|	LotProductBOM,
		|	LotSemiFinishedProductBOM,
		|	KeyLot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Multipliers.Period AS Period,
		|	Multipliers.StandardCostEstimate AS StandardCostEstimate,
		|	Multipliers.LotProductBOM AS LotProductBOM,
		|	Multipliers.ManufacturedProduct AS ManufacturedProduct,
		|	Multipliers.ItemVariant AS ItemVariant,
		|	Multipliers.Purpose AS Purpose,
		|	Multipliers.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	Multipliers.KeyLot AS KeyLot,
		|	Multipliers.SemiFinishedProduct AS SemiFinishedProduct,
		|	Multipliers.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	ISNULL(CommonDenominators.Order, Multipliers.Order) AS Order,
		|	ISNULL(CommonDenominators.Denominator, Multipliers.Denominator) AS Denominator,
		|	Multipliers.CalculationIsCompleted AS CalculationIsCompleted,
		|	Multipliers.LotIsReleased AS LotIsReleased,
		|	Multipliers.Numerator AS Numerator,
		|	Multipliers.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
		|	Multipliers.Cost AS Cost,
		|	Multipliers.CostExcludingVAT AS CostExcludingVAT,
		|	Multipliers.LocalCost AS LocalCost,
		|	Multipliers.LaborCosts AS LaborCosts,
		|	Multipliers.LaborCostsLocal AS LaborCostsLocal,
		|	Multipliers.ItemizedFixed AS ItemizedFixed,
		|	Multipliers.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
		|	Multipliers.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
		|	Multipliers.ItemizedVariable AS ItemizedVariable,
		|	Multipliers.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
		|	Multipliers.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
		|	Multipliers.OffBalanceCost AS OffBalanceCost,
		|	Multipliers.OffBalanceCostLocal AS OffBalanceCostLocal
		|FROM
		|	Multipliers AS Multipliers
		|		LEFT JOIN CommonDenominators AS CommonDenominators
		|		ON Multipliers.LotIsReleased = CommonDenominators.LotIsReleased
		|			AND Multipliers.LotSemiFinishedProductBOM = CommonDenominators.LotSemiFinishedProductBOM
		|			AND Multipliers.KeyLot = CommonDenominators.KeyLot
		|			AND (CommonDenominators.LotProductBOM = UNDEFINED
		|				OR Multipliers.LotProductBOM = CommonDenominators.LotProductBOM)";
	
	CalculationParameters.StructureOfData.Multipliers = Query.Execute().Unload();
	
EndProcedure

Procedure AddMultipliersForPossibleSemiFinishedProducts(CalculationParameters)
	
	StructureOfData = CalculationParameters.StructureOfData;
	
	If StructureOfData.RegisterRecords.PlannedMaterialCosts.Count() = 0 Then
		Return;
	EndIf;
		
	PlannedMaterialCosts = StructureOfData.RegisterRecords.PlannedMaterialCosts;
	PlannedMaterialCosts.Columns.Add("TheIndexOfTheData", New TypeDescription("Number"));
	TMCommonUse.NumberValueTable(PlannedMaterialCosts, "TheIndexOfTheData");

	PossiblePF = StructureOfData.RegisterRecords.PlannedMaterialCosts.FindRows(
		New Structure("ThisIsASemiFinishedProduct", False));
	UsedMaterials = StructureOfData.RegisterRecords.PlannedMaterialCosts.Copy(PossiblePF);
	UsedMaterials.GroupBy("Products, Characteristic");
	UsedMaterials.Columns.Add("ProductionByThirdParty", New TypeDescription("Boolean"));
	UsedMaterials.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	UsedMaterials.FillValues(CalculationParameters.PCDetails.ProductionDispatcherBusinessUnit, "Department");

	OrderData = New Structure("ProductionDispatcherBusinessUnit", CalculationParameters.PCDetails.ProductionDispatcherBusinessUnit);
	MethodsOfObtainingMaterials = ProductionSupply.DefaultMethodsForGettingMaterials(
			OrderData, UsedMaterials, , Enums.ProductionSupplyFillingVariants.BySupplySchemes);
	MethodsOfObtainingMaterials.Columns.Add("ProductionStart", New TypeDescription("Date"));
	MethodsOfObtainingMaterials.FillValues(CalculationParameters.PCDetails.Date, "ProductionStart");
	MethodsOfObtainingMaterials.Columns.Add("TheIndexOfTheData", New TypeDescription("Number"));
	TMCommonUse.NumberValueTable(MethodsOfObtainingMaterials, "TheIndexOfTheData");

	AllPFSpecifications = InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.GetProductSpecifications(
			MethodsOfObtainingMaterials.Copy(New Structure("ToPlan", True)));
			
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"MethodsOfObtainingMaterials", MethodsOfObtainingMaterials,
		"TheIndexOfTheData,Products,Characteristic,ToPlan",
		"ToPlan");
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"PlannedMaterialCosts", PlannedMaterialCosts,
		"TheIndexOfTheData,Products,Characteristic,LotBOM,Department,ThisIsASemiFinishedProduct,Count",
		"Products,Characteristic");
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"AllPFSpecifications", AllPFSpecifications,
		"TheIndexOfTheData,BillOfMaterials",
		"TheIndexOfTheData");
	Multipliers_GroupingColumns = ?(StructureOfData.Multipliers.Columns.Find("Priority") = Undefined,
		CalculationParameters.Multipliers_GroupingColumnsWithoutPriority,
		CalculationParameters.Multipliers_GroupingColumns);
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"Multipliers", StructureOfData.Multipliers,
		Multipliers_GroupingColumns + ",Numerator",
		"LotProductBOM");
	
	Query.Text = "
	|SELECT
	|	PlannedMaterialCosts.Department AS Department,
	|	PlannedMaterialCosts.TheIndexOfTheData AS ID_PlannedMaterials,
	|	DD.Products AS SemiFinishedProduct,
	|	DD.Characteristic AS ItemVariantsOfIntermediateProduct,
	|	AllPFSpecifications.BillOfMaterials AS SemiFinishedProductBOM,
	|	PlannedMaterialCosts.LotBOM AS LotBOM,
	|	PlannedMaterialCosts.Count AS QuantityOfSemiFinishedProduct
	|INTO MultipliersOfSemiFinishedProducts
	|FROM
	|	MethodsOfObtainingMaterials AS DD
	|		INNER JOIN AllPFSpecifications AS AllPFSpecifications
	|		ON (DD.ToPlan)
	|			AND (DD.TheIndexOfTheData = AllPFSpecifications.TheIndexOfTheData)
	|		INNER JOIN PlannedMaterialCosts AS PlannedMaterialCosts
	|		ON (NOT PlannedMaterialCosts.ThisIsASemiFinishedProduct)
	|			AND (PlannedMaterialCosts.Products = DD.Products)
	|			AND (PlannedMaterialCosts.Characteristic = DD.Characteristic)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MultipliersOfSemiFinishedProducts.ID_PlannedMaterials AS ID_PlannedMaterials,
	// The type-to-string conversion will be performed automatically when processing the selection.
	|	UUID(MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct) AS KeyLot
	|FROM
	|	MultipliersOfSemiFinishedProducts AS MultipliersOfSemiFinishedProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Multipliers.Period AS Period,
	|	Multipliers.StandardCostEstimate AS StandardCostEstimate,
	|	MultipliersOfSemiFinishedProducts.Department AS Department,
	|	Multipliers.LotProductBOM AS LotProductBOM,
	|	Multipliers.ManufacturedProduct AS ManufacturedProduct,
	|	Multipliers.ItemVariant AS ItemVariant,
	|	Multipliers.Purpose AS Purpose,
	|	Multipliers.Order + 1 AS Order,
	|	MultipliersOfSemiFinishedProducts.SemiFinishedProduct AS SemiFinishedProduct,
	|	MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
	// The type-to-string conversion will be performed automatically when processing the selection.
	|	UUID(MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct) AS KeyLot,
	|	MultipliersOfSemiFinishedProducts.SemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|	MultipliersOfSemiFinishedProducts.QuantityOfSemiFinishedProduct * Multipliers.Numerator / Multipliers.Denominator AS QuantityOfSemiFinishedProduct,
	|	1 AS Numerator,
	|	1 AS Denominator,
	|	0 AS Priority,
	|	FALSE AS LotIsReleased,
	|	FALSE CalculationIsCompleted
	|FROM
	|	MultipliersOfSemiFinishedProducts AS MultipliersOfSemiFinishedProducts
	|		INNER JOIN Multipliers AS Multipliers
	|		ON MultipliersOfSemiFinishedProducts.LotBOM = Multipliers.LotProductBOM
	|			AND NOT Multipliers.LotIsReleased
	|
	|UNION ALL
	|
	|SELECT
	|	Multipliers.Period AS Period,
	|	Multipliers.StandardCostEstimate AS StandardCostEstimate,
	|	MultipliersOfSemiFinishedProducts.Department AS Department,
	|	Multipliers.LotProductBOM AS LotProductBOM,
	|	Multipliers.ManufacturedProduct AS ManufacturedProduct,
	|	Multipliers.ItemVariant AS ItemVariant,
	|	Multipliers.Purpose AS Purpose,
	|	Multipliers.Order + 1 AS Order,
	|	MultipliersOfSemiFinishedProducts.SemiFinishedProduct AS SemiFinishedProduct,
	|	MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
	// The type-to-string conversion will be performed automatically when processing the selection.
	|	UUID(MultipliersOfSemiFinishedProducts.ItemVariantsOfIntermediateProduct) AS KeyLot,
	|	MultipliersOfSemiFinishedProducts.SemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|	MultipliersOfSemiFinishedProducts.QuantityOfSemiFinishedProduct * Multipliers.Numerator / Multipliers.Denominator AS QuantityOfSemiFinishedProduct,
	|	1 AS Numerator,
	|	1 AS Denominator,
	|	0 AS Priority,
	|	FALSE AS LotIsReleased,
	|	FALSE CalculationIsCompleted
	|FROM
	|	MultipliersOfSemiFinishedProducts AS MultipliersOfSemiFinishedProducts
	|		INNER JOIN Multipliers AS Multipliers
	|		ON MultipliersOfSemiFinishedProducts.LotBOM = Multipliers.LotSemiFinishedProductBOM
	|			AND NOT Multipliers.LotIsReleased
	|";
	
	QueryResults = Query.ExecuteBatch();
	MaterialsSemiFinishedProducts = QueryResults[1].Select();
	NewMultipliersOfSemiFinishedProducts = QueryResults[2].Select();
	
	While MaterialsSemiFinishedProducts.Next() Do
		PlannedMaterialCosts[MaterialsSemiFinishedProducts.ID_PlannedMaterials].ThisIsASemiFinishedProduct = True;
	EndDo;
	
	While NewMultipliersOfSemiFinishedProducts.Next() Do
		FillPropertyValues(StructureOfData.Multipliers.Add(), NewMultipliersOfSemiFinishedProducts);
	EndDo;
	
EndProcedure

Procedure PrepareDataForStagesOfDecoupling(Query, CalculationParameters, FirstStep)
	
	Query.Text = "SELECT
	|	DD.ConsumingStage				AS ConsumingStage,
	|	DD.ToExpenseAs				AS ToExpenseAs,
	|	DD.OutputFinishedProducts_ID			AS OutputFinishedProducts_ID,
	|	RECORDAUTONUMBER()				AS RowID,
	|	DD.GPVStage						AS GPVStage,
	|	DD.OutputFinishedProducts_ID			AS ID,
	|	DD.SemiFinishedProductBOM	AS BillOfMaterials,
	|	DD.ProductionOrder			AS ProductionOrder,
	|	DD.Period						AS Period,
	|	DD.ManufacturedProduct					AS ManufacturedProduct,
	|	DD.ItemVariant		AS ItemVariant,
	|	DD.AssignmentOfProducts			AS AssignmentOfProducts,
	|	DD.LotProductBOM	AS LotProductBOM,
	|	DD.SemiFinishedProduct					AS SemiFinishedProduct,
	|	DD.ItemVariantsOfIntermediateProduct	AS ItemVariantsOfIntermediateProduct,
	|	DD.LotSemiFinishedProductBOM	AS LotSemiFinishedProductBOM,
	|	DD.RequiredNumber			AS QuantityOfSemiFinishedProduct,
	|	DD.KeyLot					AS KeyLot
	|
	|INTO MultipliersOfPFProducedInProcessPreliminary
	|FROM
	|	PFIssuesWithinOrder AS DD
	|
	|WHERE
	|	DD.RequiredNumber > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ManufacturedProducts.RowID	AS Source_ID,
	|	DD.RowID				AS Receiver_ID
	|FROM
	|	MultipliersOfPFProducedInProcessPreliminary AS DD
	//		In the table of output products, we are trying to find the PF release that was added to the uncoupling at the previous recursion step
	|		INNER JOIN ManufacturedProducts AS ManufacturedProducts
	|		ON
	|			CASE
	|				WHEN VALUETYPE(DD.LotSemiFinishedProductBOM) = TYPE(Document.ProductionStage2_2)
	|					THEN DD.LotSemiFinishedProductBOM = ManufacturedProducts.ReleasingStage
	|					ELSE DD.BillOfMaterials = ManufacturedProducts.BillOfMaterials
	|							AND DD.ProductionOrder = ManufacturedProducts.ProductionOrder
	|			END
	|
	|			AND CASE WHEN DD.GPVStage THEN
	|				(DD.ManufacturedProduct = ManufacturedProducts.Products)
	|				AND (DD.ItemVariant = ManufacturedProducts.Characteristic)
	|				AND NOT ManufacturedProducts.LotIsReleased
	|			ELSE
	|				(DD.SemiFinishedProduct = ManufacturedProducts.Products)
	|				AND (DD.ItemVariantsOfIntermediateProduct = ManufacturedProducts.Characteristic)
	|			END
	|
	|			AND ((DD.AssignmentOfProducts = VALUE(Catalog.Assignments.EmptyRef)
	|					AND ManufacturedProducts.AssignmentIsEmpty)
	|				OR (DD.AssignmentOfProducts = ManufacturedProducts.Purpose)
	|				OR (DD.ConsumingStage = ManufacturedProducts.OrderingFromDestination)
	|				)
	|			AND DD.ToExpenseAs = ManufacturedProducts.ToExpenseAs
	|WHERE
	|	DD.OutputFinishedProducts_ID = -1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.ToExpenseAs				AS ToExpenseAs,
	|	DD.OutputFinishedProducts_ID			AS OutputFinishedProducts_ID,
	|	DD.RowID			AS RowID,
	|	DD.GPVStage						AS GPVStage,
	|	DD.ID							AS ID,
	|	VALUE(Document.ProductionStage2_2.EmptyRef) AS ReleasingStage,
	|	FALSE							AS ProductionByThirdParty,
	|	DD.BillOfMaterials					AS BillOfMaterials,
	|	DD.ProductionOrder			AS ProductionOrder,
	|	DD.Period						AS Period,
	|	DD.ManufacturedProduct					AS ManufacturedProduct,
	|	DD.ItemVariant		AS ItemVariant,
	|	DD.AssignmentOfProducts			AS AssignmentOfProducts,
	|	DD.LotProductBOM	AS LotProductBOM,
	|	DD.SemiFinishedProduct					AS SemiFinishedProduct,
	|	DD.ItemVariantsOfIntermediateProduct	AS ItemVariantsOfIntermediateProduct,
	|	DD.LotSemiFinishedProductBOM	AS LotSemiFinishedProductBOM,
	|	DD.QuantityOfSemiFinishedProduct			AS QuantityOfSemiFinishedProduct,
	|	1								AS Numerator,
	|	1								AS Denominator,
	|	FALSE							AS LotIsReleased,
	// During the uncoupling of the stages, you can meet a PF for which there is no releasing stage in the current. the structure of the order for production
	// In that case, for now, the unraveling is through the bill of Materials.
	|	FALSE							AS ThereIsReleaseStage,
	|	DD.KeyLot					AS KeyLot
	|FROM
	|	MultipliersOfPFProducedInProcessPreliminary AS DD
	|
	|ORDER BY
	|	DD.Period
	|";
	
	QueryResults = Query.ExecuteBatch();
	LastQueryIndex = QueryResults.Count() - 1;
	MultipliersOfPFProducedInProcessPreliminary = QueryResults[LastQueryIndex].Unload();
	SourcesReceivers = QueryResults[LastQueryIndex - 1].Unload();
	SourcesReceivers.Indexes.Add("Receiver_ID");
	
	MultipliersOfPFProducedInProcess = MultipliersOfPFProducedInProcessPreliminary.CopyColumns();
	For Each Page1 In MultipliersOfPFProducedInProcessPreliminary Do
		
		If Page1.OutputFinishedProducts_ID = -1 Then
			QuantityNeeded = Page1.QuantityOfSemiFinishedProduct;
			SuitableSources = SourcesReceivers.FindRows(New Structure("Receiver_ID", Page1.RowID));
			If SuitableSources.Count() = 0 Then
				// There is no suitable release of PF, we find out through the specification.
				SpecificationLine = MultipliersOfPFProducedInProcess.Add();
				FillPropertyValues(SpecificationLine, Page1);
				SpecificationLine.QuantityOfSemiFinishedProduct = QuantityNeeded;
				SpecificationLine.LotSemiFinishedProductBOM = Page1.BillOfMaterials;
				
				Continue;
			EndIf;
			
			For Each Source In SuitableSources Do
				RemainderLine = CalculationParameters.StructureOfData.ManufacturedProducts.Find(Source.Source_ID,
					"RowID");
				
				QuantityFromStage = Min(RemainderLine.QuantityReleaseBalance, QuantityNeeded);
				RemainderLine.QuantityReleaseBalance = RemainderLine.QuantityReleaseBalance - QuantityFromStage;
				QuantityNeeded = QuantityNeeded - QuantityFromStage;
				
				If QuantityFromStage > 0 Then
					LineForStage = MultipliersOfPFProducedInProcess.Add();
					FillPropertyValues(LineForStage, Page1);
					
					LineForStage.QuantityOfSemiFinishedProduct = QuantityFromStage;
					LineForStage.Denominator = RemainderLine.Denominator;
					LineForStage.Numerator = QuantityFromStage * RemainderLine.Numerator / RemainderLine.QuantityRelease;
					
					// In the Row, all the values are for the option when there is no stage, so we change to the values of the row of the Balance of the Lot reference.
					LineForStage.LotIsReleased = RemainderLine.LotIsReleased;
					LineForStage.ThereIsReleaseStage = True;
					LineForStage.LotSemiFinishedProductBOM = RemainderLine.ReleasingStage;
					LineForStage.ProductionByThirdParty = RemainderLine.ProductionByThirdParty;
					LineForStage.BillOfMaterials = RemainderLine.BillOfMaterials;
				EndIf;
				
				If QuantityNeeded = 0 Then
					Break;
				EndIf;
			EndDo;
		Else
			// The release of the order frame is initially formed when the Din is unearthed. structures.
			// The output product ID is defined, so the Lot reference has already been selected.
			// The amount consumed has already been written off from the Balance of the Lot reference.
			RemainderLine = CalculationParameters.StructureOfData.ManufacturedProducts.Find(Page1.OutputFinishedProducts_ID,
					"RowID");
			
			QuantityFromStage = Page1.QuantityOfSemiFinishedProduct;
			QuantityNeeded = 0;
			
			LineForStage = MultipliersOfPFProducedInProcess.Add();
			FillPropertyValues(LineForStage, Page1);
					
			LineForStage.QuantityOfSemiFinishedProduct = QuantityFromStage;
			LineForStage.Denominator = RemainderLine.Denominator;
			LineForStage.Numerator = QuantityFromStage * RemainderLine.Numerator / RemainderLine.QuantityRelease;
			
			LineForStage.LotIsReleased = RemainderLine.LotIsReleased;
			LineForStage.ThereIsReleaseStage = True;
			LineForStage.LotSemiFinishedProductBOM = RemainderLine.ReleasingStage;
			LineForStage.ProductionByThirdParty = RemainderLine.ProductionByThirdParty;
			LineForStage.BillOfMaterials = RemainderLine.BillOfMaterials;
		EndIf;
		
		If QuantityNeeded > 0 Then
			// The amount in the sources is not enough, the Balance is uncoupled through the specification.
			SpecificationLine = MultipliersOfPFProducedInProcess.Add();
			FillPropertyValues(SpecificationLine, Page1);
			SpecificationLine.QuantityOfSemiFinishedProduct = QuantityNeeded;
			SpecificationLine.LotSemiFinishedProductBOM = Page1.BillOfMaterials;
		EndIf;
	EndDo;
	
	Query.SetParameter("MultipliersOfPFProducedInProcess", MultipliersOfPFProducedInProcess);
	Query.Text = "
	|DROP MultipliersOfPFProducedInProcessPreliminary
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.ToExpenseAs				AS ToExpenseAs,
	|	DD.ReleasingStage				AS ReleasingStage,
	|	DD.GPVStage						AS GPVStage,
	|	DD.ProductionByThirdParty		AS ProductionByThirdParty,
	|	DD.BillOfMaterials					AS BillOfMaterials,
	|	DD.ProductionOrder			AS ProductionOrder,
	|	DD.Period						AS Period,
	|	DD.ManufacturedProduct					AS ManufacturedProduct,
	|	DD.ItemVariant		AS ItemVariant,
	|	DD.AssignmentOfProducts			AS AssignmentOfProducts,
	|	DD.LotProductBOM	AS LotProductBOM,
	|	DD.SemiFinishedProduct					AS SemiFinishedProduct,
	|	DD.ItemVariantsOfIntermediateProduct	AS ItemVariantsOfIntermediateProduct,
	|	DD.LotSemiFinishedProductBOM	AS LotSemiFinishedProductBOM,
	|	DD.QuantityOfSemiFinishedProduct			AS QuantityOfSemiFinishedProduct,
	|	DD.Numerator						AS Numerator,
	|	DD.Denominator						AS Denominator,
	|	DD.LotIsReleased					AS LotIsReleased,
	|	DD.ThereIsReleaseStage				AS ThereIsReleaseStage,
	|	DD.KeyLot						AS KeyLot
	|
	|INTO MultipliersOfPFProducedInProcess
	|FROM &MultipliersOfPFProducedInProcess AS DD
	|";
	
	Query.Execute();
	
EndProcedure

Procedure ToFindOutStagesForProduction(Query, CalculationParameters, FirstStep)
	
	StructureOfData = CalculationParameters.StructureOfData;
	StructureOfData.Order = StructureOfData.Order + 1;
	
	PrepareDataForStagesOfDecoupling(Query, CalculationParameters, FirstStep);
	Query.Text = CalculationParameters.QueryText_StageSeparation;
	
	ResultsArray = Query.ExecuteBatch();
	LastQueryIndex = ResultsArray.Count() - 1;
	
	// 10 Multipliers for semi-finished products produced by the process.
	SamplingMultipliers = ResultsArray[LastQueryIndex].Select();
	While SamplingMultipliers.Next() Do

		// If the order's manufacturingproducts are already in the created stage, the line is in the multipliers VT, you don't need to add another one.
		If Not SamplingMultipliers.GPVStage Then
			NewMultiplier = StructureOfData.Multipliers.Add();
			FillPropertyValues(NewMultiplier, SamplingMultipliers);
			NewMultiplier.Order = StructureOfData.Order;
		EndIf;
		
		If SamplingMultipliers.ProductionByThirdParty And Not SamplingMultipliers.LotIsReleased Then
			// 1391 If there is a release of PF through processing, we find out through the bill of materials,
			// because in the stage only materials that are transferred to the processor and there are no processing services,
			// the price of which should include possible materials of the processor.
			// If there is no bill of materials for this PF, then the prices of the nomenclature should be entered.
			NewMultiplier.CalculationIsCompleted = False;
			NewMultiplier.LotSemiFinishedProductBOM = SamplingMultipliers.SemiFinishedProductBOM;
		Else
			If SamplingMultipliers.LotIsReleased Then
				NewMultiplier.Order = -100;
			Else
				// To get the primary expenses (not PF), add a stage to the table of releasing stages.
				NewVEKP = StructureOfData.ReleasingStagesForLotReferenceKeys.Add();
				NewVEKP.ReleasingStage = SamplingMultipliers.LotSemiFinishedProductBOM;
				NewVEKP.KeyLot = SamplingMultipliers.KeyLot;
				NewVEKP.Numerator = SamplingMultipliers.Numerator;
				NewVEKP.Denominator = SamplingMultipliers.Denominator;
				NewVEKP.QuantityOfSemiFinishedProduct = SamplingMultipliers.QuantityOfSemiFinishedProduct;
			EndIf;
		EndIf;
	EndDo;
	
	StructureOfData = CalculationParameters.StructureOfData;
	StructureOfData.PFIssuesWithinOrder.Clear();
	// 15 Issue of PF Order frames The use of PF In the production Stages
	PFVProvidingStages = ResultsArray[LastQueryIndex - 1].Select();
	While PFVProvidingStages.Next() Do
		If ValueIsFilled(PFVProvidingStages.ReleasingStage) Then
			FillPropertyValues(StructureOfData.PFIssuesWithinOrder.Add(), PFVProvidingStages);
		Else
			// If the PF is not issued as part of the order
			// , then the unraveling through the specification here is the multiplicator of the partypolufabrikat.Unravel product specificationsreferences
			NewMultiplier = StructureOfData.Multipliers.Add();
			FillPropertyValues(NewMultiplier, PFVProvidingStages);
			NewMultiplier.CalculationIsCompleted = False;
			NewMultiplier.Numerator = 1;
			NewMultiplier.Denominator = 1;
			NewMultiplier.QuantityOfSemiFinishedProduct = PFVProvidingStages.RequiredNumber;
		EndIf;
	EndDo;
	
	If StructureOfData.PFIssuesWithinOrder.Count() = 0 Then
		Return;
	EndIf;
	
	Query.Text = "DROP PFIssuesWithinOrder";
	Query.Execute();
	
	PlacePFIssuesWithinFrameworkOfIWTOrder(Query, StructureOfData.PFIssuesWithinOrder);
	
	Query.Text = "DROP MultipliersOfPFProducedInProcess";
	Query.Execute();
	
	ToFindOutStagesForProduction(Query, CalculationParameters, False);
	
EndProcedure

Procedure PlacePFIssuesWithinFrameworkOfIWTOrder(Query, PFIssuesWithinOrder)
	
	Query.SetParameter("Table", PFIssuesWithinOrder);
	Query.Text = "
	|SELECT
	|	T.ToExpenseAs					AS ToExpenseAs,
	|	T.GPVStage							AS GPVStage,
	|	T.OutputFinishedProducts_ID				AS OutputFinishedProducts_ID,
	|	T.ProductionOrder				AS ProductionOrder,
	|	T.ReleasingStage					AS ReleasingStage,
	|	T.ConsumingStage					AS ConsumingStage,
	|	T.ManufacturedProduct							AS ManufacturedProduct,
	|	T.ItemVariant			AS ItemVariant,
	|	T.AssignmentOfProducts				AS AssignmentOfProducts,
	|	T.LotProductBOM		AS LotProductBOM,
	|	T.SemiFinishedProduct						AS SemiFinishedProduct,
	|	T.ItemVariantsOfIntermediateProduct		AS ItemVariantsOfIntermediateProduct,
	|	T.LotSemiFinishedProductBOM	AS LotSemiFinishedProductBOM,
	|	T.SemiFinishedProductBOM			AS SemiFinishedProductBOM,
	|	T.KeyLot						AS KeyLot,
	|	T.LotIsReleased					AS LotIsReleased,
	|
	|	T.Period							AS Period,
	|	T.RequiredNumber				AS RequiredNumber
	|INTO PFIssuesWithinOrder
	|FROM
	|	&Table AS T";
	
	Query.Execute();
	
EndProcedure

Function QueryText_PrimaryDataForStages()
	Return "
	// Materials and waste plan
	|SELECT
	|	DD.CostPeriod				AS CostPeriod,
	|	DD.ReleasingStage			AS ReleasingStage,
	|	DD.Stage						AS ConsumingStage,
	|	MAX(DD.ProductionByThirdParty) AS ConsumingStage_ProductionOnSide,
	|	DD.Organization				AS Organization,
	|	DD.ProductionLot		AS ProductionLot,
	|	DD.Products				AS Products,
	|	DD.ProducedInProcess	AS ProducedInProcess,
	|	DD.IntermediateOutput		AS IntermediateOutput,
	|	DD.SideProduct			AS SideProduct,
	|	DD.BillOfMaterials				AS BillOfMaterials,
	|	DD.Characteristic			AS Characteristic,
	|	DD.Department			AS Department,
	|	DD.Purpose				AS Purpose,
	|	DD.ProductCostElement		AS ProductCostElement,
	|	SUM(DD.Plan * DD.ReductionRatio) AS Plan
	|INTO PreliminaryPlanOfMaterials
	|FROM
	|	(
	// stage materials plan
	|	SELECT
	|		CASE WHEN DD.ShipInOneDay THEN
	|			DD.DateOfShipment
	|		ELSE
	|			Supply.DateOfShipment
	|		END										AS CostPeriod,
	|		DD.ReleasingStage							AS ReleasingStage,
	|		DD.Stage										AS Stage,
	|		DD.ProductionByThirdParty					AS ProductionByThirdParty,
	|		DD.Organization								AS Organization,
	|		DD.ProductionLot						AS ProductionLot,
	|		Supply.Products					AS Products,
	|		Supply.Characteristic					AS Characteristic,
	|		Supply.Department					AS Department,
	|		CASE
	|			WHEN &KeepRecordsOfInventoryCostByAssignments
	|				THEN Supply.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END										AS Purpose,
	|		Supply.ProductCostElement				AS ProductCostElement,
	|		Supply.Count						AS Plan,
	|		1											AS ReductionRatio,
	|		Supply.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef) AS ProducedInProcess,
	|		FALSE										AS IntermediateOutput,
	|		FALSE										AS SideProduct,
	|		Supply.BillOfMaterials					AS BillOfMaterials
	|	FROM
	|		DetailsOfStagesOfParties AS DD
	|			INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Supply
	|			ON DD.Stage = Supply.Ref
	|
	|	WHERE
	// The processing data of the releasing stage on the side is excluded, because the movements are formed by a report without distribution.
	|		NOT DD.ProductionByThirdParty
	|		AND NOT Supply.Canceled
	|		AND NOT (DD.ThisIsAProductionIssueStage AND DD.LotIsReleased)
	|
	|	UNION ALL
	|
	// the plan of materials of the stages performed on the side (processing 2.5 by stages)
	|	SELECT
	|		CASE WHEN DD.ShipInOneDay THEN
	|			DD.DateOfShipment
	|		ELSE
	|			Supply.DateOfShipment
	|		END													AS CostPeriod,
	|		DD.ReleasingStage										AS ReleasingStage,
	|		DD.Stage													AS Stage,
	|		DD.ProductionByThirdParty								AS ProductionByThirdParty,
	|		DD.Organization											AS Organization,
	|		DD.ProductionLot									AS ProductionLot,
	|		Supply.Products								AS Products,
	|		Supply.Characteristic								AS Characteristic,
	|		VALUE(Catalog.BusinessStructure.EmptyRef)	AS Department,
	|		CASE
	|			WHEN &KeepRecordsOfInventoryCostByAssignments
	|				THEN Supply.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END													AS Purpose,
	|		Supply.ProductCostElement							AS ProductCostElement,
	|		Supply.Count									AS Plan,
	|		1														AS ReductionRatio,
	|		Supply.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef) AS ProducedInProcess,
	|		FALSE													AS IntermediateOutput,
	|		FALSE													AS SideProduct,
	|		Supply.BillOfMaterials								AS BillOfMaterials
	|	FROM
	|		DetailsOfStagesOfParties AS DD
	|			INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Supply
	|			ON DD.Stage = Supply.Ref
	|
	|	WHERE
	|		Supply.Ref.ProductionByThirdParty2_5
	|		AND NOT Supply.Canceled
	|		AND NOT (DD.ThisIsAProductionIssueStage AND DD.LotIsReleased)
	|
	|	UNION ALL
	|
	|
	// waste plan of the chain stages
	|	SELECT
	|		CASE
	|			WHEN DD.ProductionInOneDay
	|					OR GoodsTable.ProductionDate = DATETIME(1, 1, 1)
	|				THEN DD.ProductionDate
	|			ELSE GoodsTable.ProductionDate
	|		END							AS CostPeriod,
	|		DD.ReleasingStage				AS ReleasingStage,
	|		DD.Stage							AS Stage,
	|		DD.ProductionByThirdParty		AS ProductionByThirdParty,
	|		DD.Organization					AS Organization,
	|		DD.ProductionLot			AS ProductionLot,
	|		GoodsTable.Products		AS Products,
	|		GoodsTable.Characteristic	AS Characteristic,
	|		GoodsTable.Department		AS Department,
	|		CASE
	|			WHEN &KeepRecordsOfInventoryCostByAssignments
	|				THEN GoodsTable.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END							AS Purpose,
	|		GoodsTable.ProductCostElement	AS ProductCostElement,
	|		GoodsTable.Count		AS Plan,
	|		-1								AS ReductionRatio,
	|		TRUE							AS ProducedInProcess,
	|		&KeepRecordsOfInventoryCostByAssignments
	|			AND TRUE IN (SELECT TOP 1 TRUE
	|								FROM AssignmentsForStagesOfProductionOrder AS NEZP
	|								WHERE NEZP.ProductionOrder = DD.ProductionOrder
	|									AND NEZP.DestinationLink = GoodsTable.Purpose) AS IntermediateOutput,
	|		TRUE							AS SideProduct,
	|			
	|		GoodsTable.BillOfMaterials		AS BillOfMaterials
	|	FROM
	|		DetailsOfStagesOfParties AS DD
	|			INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS GoodsTable
	|			ON DD.Stage = GoodsTable.Ref
	|
	|	WHERE
	// The processing data of the releasing stage on the side is excluded, because the movements are formed by a report without distribution.
	|		NOT DD.ProductionByThirdParty
	|		AND NOT GoodsTable.Canceled
	|		AND NOT (DD.ThisIsAProductionIssueStage AND DD.LotIsReleased)
	|
	|	UNION ALL
	|
	// waste plan for the stages of other chains
	|	SELECT
	|		CASE
	|			WHEN DD.ProductionInOneDay
	|					OR GoodsTable.ProductionDate = DATETIME(1, 1, 1)
	|				THEN DD.ProductionDate
	|			ELSE GoodsTable.ProductionDate
	|		END							AS CostPeriod,
	|		DD.ReleasingStage				AS ReleasingStage,
	|		DD.Stage							AS Stage,
	|		DD.ProductionByThirdParty		AS ProductionByThirdParty,
	|		DD.Organization					AS Organization,
	|		DD.ProductionLot			AS ProductionLot,
	|		GoodsTable.Products		AS Products,
	|		GoodsTable.Characteristic	AS Characteristic,
	|		GoodsTable.Department		AS Department,
	|		CASE
	|			WHEN &KeepRecordsOfInventoryCostByAssignments
	|				THEN GoodsTable.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END							AS Purpose,
	|		GoodsTable.ProductCostElement	AS ProductCostElement,
	|		GoodsTable.Count		AS Plan,
	|		-1								AS ReductionRatio,
	|		TRUE							AS ProducedInProcess,
	|		&KeepRecordsOfInventoryCostByAssignments
	|			AND TRUE IN (SELECT TOP 1 TRUE
	|									FROM AssignmentsForStagesOfProductionOrder AS NEZP
	|									WHERE NEZP.ProductionOrder = DD.ProductionOrder
	|										AND NEZP.DestinationLink = GoodsTable.Purpose) AS IntermediateOutput,
	|		TRUE							AS SideProduct,
	|		GoodsTable.BillOfMaterials		AS BillOfMaterials
	|	FROM
	|		DetailsOfStagesOfParties AS DD
	|
	|			INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS GoodsTable
	|			ON DD.Stage = GoodsTable.StageConsumer
	|
	|			INNER JOIN Document.ProductionStage2_2 AS StagesOfOtherChains
	|			ON StagesOfOtherChains.Ref = GoodsTable.Ref
	|
	|	WHERE
	// The processing data of the releasing stage on the side is excluded, because the movements are formed by a report without distribution.
	|		NOT DD.ProductionByThirdParty
	|		AND NOT GoodsTable.Canceled
	|		AND NOT DD.ProductionLot = StagesOfOtherChains.ProductionLot
	|		AND NOT (DD.ThisIsAProductionIssueStage AND DD.LotIsReleased)
	|	
	|) AS DD
	|
	|GROUP BY
	|	DD.CostPeriod,
	|	DD.ReleasingStage,
	|	DD.Stage,
	|	DD.Organization,
	|	DD.ProductionLot,
	|	DD.Products,
	|	DD.ProducedInProcess,
	|	DD.SideProduct,
	|	DD.IntermediateOutput,
	|	DD.BillOfMaterials,
	|	DD.Characteristic,
	|	DD.Department,
	|	DD.Purpose,
	|	DD.ProductCostElement
	|
	|INDEX BY
	|	ReleasingStage,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	IntermediateOutput
	|;
	|
	|SELECT
	|	DD.CostPeriod			AS CostPeriod,
	// See comment 211.
	|	DD.ReleasingStage		AS ReleasingStage,
	// See comment 218.
	|	DD.ConsumingStage		AS ConsumingStage,
	|	DD.ConsumingStage_ProductionOnSide AS ConsumingStage_ProductionOnSide,
	|	DD.Organization			AS Organization,
	|	DD.ProductionLot	AS ProductionLot,
	|	DD.Products			AS Products,
	|	DD.ProducedInProcess OR ISNULL(NSICache.Produced, FALSE) AS ProducedInProcess,
	|	DD.SideProduct		AS SideProduct,
	|	DD.IntermediateOutput
	// Comment 3145.
	// To determine and exclude from the materials, the intermediate output in TS for the provision of materials and works,
	// we will search for nomenclature, characteristics, with a certain fact of intermediate output and the same purpose.
	// At the same time, in order to exclude the PF produced in the process from the intermediate output, we add a filter NOT produced in the process.
	|		OR (NOT (DD.ProducedInProcess OR ISNULL(NSICache.Produced, FALSE))
	|				AND TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						PreliminaryPlanOfMaterials AS PPM_
	|					WHERE
	|						PPM_.ReleasingStage = DD.ReleasingStage
	|						AND PPM_.Products = DD.Products
	|						AND PPM_.Characteristic = DD.Characteristic
	|						AND PPM_.Purpose = DD.Purpose
	|						AND PPM_.IntermediateOutput)
	|			) AS IntermediateOutput,
	|
	// The bill of Materials specified in the production stages has a higher priority
	|	CASE WHEN
	|		DD.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|		THEN ISNULL(NSICache.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef))
	|		ELSE DD.BillOfMaterials
	|	END								AS BillOfMaterials,
	|	DD.Characteristic					AS Characteristic,
	|	DD.Department					AS Department,
	|	DD.Purpose						AS Purpose,
	|	DD.ProductCostElement				AS ProductCostElement,
	|	DD.Plan								AS Plan,
	|	&EmptyUIDString					AS KeyLot
	|
	|INTO MaterialPlan
	|FROM PreliminaryPlanOfMaterials AS DD
	|		LEFT JOIN OrderTTCacheOfNSIStructure AS NSICache
	|		ON DD.Products = NSICache.Products
	|			AND DD.Characteristic = NSICache.Characteristic
	|
	|INDEX BY
	|	ReleasingStage,
	|	ProducedInProcess,
	|	ConsumingStage_ProductionOnSide
	|;";
EndFunction

Function QueryText_StageSeparation()
	Return "
	// 15 Issue of PF Order frames The use of PF In the production Stages
	// We collect PF that are necessary for the release of current PF and GP.
	|SELECT
	|	MPF.ToExpenseAs									AS ToExpenseAs,
	|	-1														AS OutputFinishedProducts_ID,
	|	FALSE													GPVStage,
	|	MaterialPlan.ReleasingStage							AS ReleasingStage,
	|	MaterialPlan.ConsumingStage							AS ConsumingStage,
	|	MPF.ProductionByThirdParty								AS ProductionByThirdParty,
	|	MPF.ProductionOrder									AS ProductionOrder,
	|	MaterialPlan.CostPeriod								AS Period,
	|	MPF.ManufacturedProduct											AS ManufacturedProduct,
	|	MPF.ItemVariant								AS ItemVariant,
	|	MPF.AssignmentOfProducts									AS AssignmentOfProducts,
	|	MPF.LotProductBOM							AS LotProductBOM,
	|	MaterialPlan.Products								AS SemiFinishedProduct,
	|	MaterialPlan.Characteristic							AS ItemVariantsOfIntermediateProduct,
	|	MaterialPlan.Plan * MPF.Numerator / MPF.Denominator	AS RequiredNumber,
	|	MaterialPlan.ProductCostElement						AS ProductCostElement,
	|	MaterialPlan.BillOfMaterials								AS SemiFinishedProductBOM,
	// The type-to-string conversion will be performed automatically when processing the selection.
	|	UUID(MaterialPlan.Characteristic)	AS KeyLot,
	// The value of the batch column released is determined when selecting the Lot reference to be written off.
	|	MPF.LotIsReleased										AS LotIsReleased
	|FROM
	|	MaterialPlan AS MaterialPlan
	|		INNER JOIN MultipliersOfPFProducedInProcess AS MPF
	// MPF.The batch specification of the half-factory in this condition is the stage that consumes PF, for the release of another PF.
	|		ON MaterialPlan.ReleasingStage = MPF.LotSemiFinishedProductBOM
	|			AND (MPF.ThereIsReleaseStage)
	|			AND (MaterialPlan.ProducedInProcess)
	//			See Comment 1391.
	|			AND (NOT MaterialPlan.ConsumingStage_ProductionOnSide)
	//			The expenses for the issued Lot references are collected when unraveling the cost tree
	|			AND NOT MPF.LotIsReleased
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 10 Multipliers for semi-finished products produced by the process.
	|SELECT
	|	DD.Period AS Period,
	|	DD.GPVStage AS GPVStage,
	|	DD.ProductionByThirdParty AS ProductionByThirdParty,
	|	DD.ManufacturedProduct AS ManufacturedProduct,
	|	DD.ItemVariant AS ItemVariant,
	|	DD.AssignmentOfProducts AS Purpose,
	|	DD.LotProductBOM AS LotProductBOM,
	|	DD.SemiFinishedProduct AS SemiFinishedProduct,
	|	DD.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
	|	DD.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|	DD.BillOfMaterials AS SemiFinishedProductBOM,
	|	DD.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
	|	DD.ThereIsReleaseStage AS CalculationIsCompleted,
	|	DD.ThereIsReleaseStage AS ThereIsReleaseStage,
	|	CASE WHEN DD.LotIsReleased
	|		THEN -100
	|		ELSE 0
	|	END AS Order,
	|	DD.Numerator AS Numerator,
	|	DD.Denominator AS Denominator,
	|	""MultipliersOfPFProducedInProcess"" AS Comment,
	|	&EmptyUID AS KeyProducts,
	|	DD.KeyLot AS KeyLot,
	|	DD.LotIsReleased AS LotIsReleased
	|FROM
	|	MultipliersOfPFProducedInProcess AS DD
	|WHERE
	|	NOT DD.ToExpenseAs
	|";
EndFunction

#EndRegion

#EndRegion
