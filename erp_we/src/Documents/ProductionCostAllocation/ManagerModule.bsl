#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses"); // for the formation of Registered Records of medium-slip
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	
	ProductionCostAllocationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ProductionCostAllocation") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		ProductionCostAllocationLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Department,Warehouse,Date,NewProduction";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
//	Parameters:
//		Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//	Returns:
//		See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.ProductionCostAllocation";
	
	If Object.NewProduction Then
		SeriesSpecificationParameters.WarehouseFieldName = "Warehouse";
		SeriesParameters_ = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	Else
		SeriesSpecificationParameters.WarehouseFieldName = "Department";
		SeriesParameters_ = WarehousesServer.UsingSeriesInDivision(Object.Department);
	EndIf;
	
	SeriesSpecificationParameters.UseItemsBatch = SeriesParameters_.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = SeriesParameters_.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.AllocationForCosts);
	SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	
	SeriesSpecificationParameters.ProductInHeader = True;
	SeriesSpecificationParameters.NameTSGoods = "";
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.RegisterSeries = False;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	SUM(TableOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS TableOfSeries
	|
	|GROUP BY
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS StatusOfSpecifyingSeriesIsOld,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyUponAllocatingCostsToProductionLots
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.StatusOfSpecifyingSeriesIsOld
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

// Returns the text of the request to fill in the workplace for the distribution of materials and work for the cost of production.
//
//	Parameters:
//		ToTemporaryTable - Boolean - indicates whether the result is placed in a temporary table.
//		ChooseFirst - Number - The number of records to select.
//
//	Returns:
//		String - query text.
//
Function RequestTextForMaterialsAndWorksInStorerooms(ToTemporaryTable = False, ChooseFirst = 0) Export
	
	QueryText =
	"SELECT ALLOWED
	|	RemainingMaterials.Organization AS Organization,
	|	Dimension.WarehouseArea.Department AS Department,
	|	Dimension.WarehouseArea AS Warehouse,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose,
	|	RemainingMaterials.ItemsLocationAttributes,
	|	RemainingMaterials.CountBalance AS OpeningBalance,
	|	0 AS Received,
	|	0 AS Passed
	|INTO TTMovementOfMaterials
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|			&BeginOfPeriod,
	|			(Organization IN (&Companies)
	|					OR &AllCompanies)
	|				AND (ItemsLocationAttributes.WarehouseArea.Department IN (&Departments)
	|					OR &AllDepartments)
	|				AND ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|				AND ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom) AS RemainingMaterials
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON RemainingMaterials.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	(Dimension.Products.ItemsType = &ItemsType
	|			OR &AllTypesOfProducts)
	|	AND (RemainingMaterials.ItemsLocationAttributes = &ItemsLocationAttributes
	|			OR &AllAnalysts)
	|
	|UNION ALL
	|
	|SELECT
	|	ReceiptOfMaterials.Organization,
	|	Dimension.WarehouseArea.Department,
	|	Dimension.WarehouseArea,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Series,
	|	Dimension.Purpose,
	|	ReceiptOfMaterials.ItemsLocationAttributes,
	|	0,
	|	ReceiptOfMaterials.CountReceipt,
	|	0
	|FROM
	|	AccumulationRegister.CompanyGoods.Turnovers(
	|			&BeginOfPeriod,
	|			&BorderEndOfPeriod_,
	|			,
	|			(Organization IN (&Companies)
	|					OR &AllCompanies)
	|				AND (ItemsLocationAttributes.WarehouseArea.Department IN (&Departments)
	|					OR &AllDepartments)
	|				AND ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|				AND ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom) AS ReceiptOfMaterials
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON ReceiptOfMaterials.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	(Dimension.Products.ItemsType = &ItemsType
	|			OR &AllTypesOfProducts)
	|	AND (ReceiptOfMaterials.ItemsLocationAttributes = &ItemsLocationAttributes
	|			OR &AllAnalysts)
	|
	|UNION ALL
	|
	|SELECT
	|	MaterialTransfers.Organization,
	|	Dimension.WarehouseArea.Department,
	|	Dimension.WarehouseArea,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Series,
	|	Dimension.Purpose,
	|	MaterialTransfers.ItemsLocationAttributes,
	|	0,
	|	0,
	|	MaterialTransfers.Count
	|FROM
	|	AccumulationRegister.CompanyGoods AS MaterialTransfers
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON MaterialTransfers.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	(MaterialTransfers.Organization IN (&Companies)
	|		OR &AllCompanies)
	|	AND (Dimension.WarehouseArea.Department IN (&Departments)
	|		OR &AllDepartments)
	|	AND Dimension.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|	AND Dimension.WarehouseArea.ShopFloorStockroom
	|	AND MaterialTransfers.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND MaterialTransfers.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND NOT MaterialTransfers.Recorder REFS Document.ProductionCostAllocation
	|	AND (Dimension.Products.ItemsType = &ItemsType
	|			OR &AllTypesOfProducts)
	|	AND (MaterialTransfers.ItemsLocationAttributes = &ItemsLocationAttributes
	|			OR &AllAnalysts)
	|
	|UNION ALL
	|
	|SELECT
	|	RemainsOfWorks.Organization,
	|	Dimension.StorageLocation,
	|	VALUE(Catalog.Warehouses.EmptyRef),
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Series,
	|	Dimension.Purpose,
	|	Dimension.DimensionKey,
	|	RemainsOfWorks.CountBalance,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.MaterialsAndWorksInProduction.Balance(
	|			&BeginOfPeriod,
	|			(Organization IN (&Companies)
	|					OR &AllCompanies)
	|				AND (Department IN (&Departments)
	|					OR &AllDepartments)) AS RemainsOfWorks
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON RemainsOfWorks.Products = Dimension.Products
	|			AND RemainsOfWorks.Characteristic = Dimension.Characteristic
	|			AND RemainsOfWorks.Department = Dimension.StorageLocation
	|			AND RemainsOfWorks.Purpose = Dimension.Purpose
	|			AND (Dimension.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	(Dimension.Products.ItemsType = &ItemsType
	|			OR &AllTypesOfProducts)
	|	AND Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND (Dimension.DimensionKey = &ItemsLocationAttributes
	|			OR &AllAnalysts)
	|
	|UNION ALL
	|
	|SELECT
	|	WorkInProduction.Organization,
	|	Dimension.StorageLocation,
	|	VALUE(Catalog.Warehouses.EmptyRef),
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Series,
	|	Dimension.Purpose,
	|	Dimension.DimensionKey,
	|	0,
	|	CASE 
	|		WHEN WorkInProduction.RecordType = VALUE(AccumulationRecordType.Receipt) AND NOT WorkInProduction.ReversingEntry
	|			THEN WorkInProduction.Count
	|		WHEN WorkInProduction.RecordType = VALUE(AccumulationRecordType.Expense) AND WorkInProduction.ReversingEntry
	|			THEN -WorkInProduction.Count
	|		ELSE
	|			0
	|	END,
	|	CASE 
	|		WHEN WorkInProduction.RecordType = VALUE(AccumulationRecordType.Expense) AND NOT WorkInProduction.ReversingEntry
	|			THEN WorkInProduction.Count
	|		WHEN WorkInProduction.RecordType = VALUE(AccumulationRecordType.Receipt) AND WorkInProduction.ReversingEntry
	|			THEN -WorkInProduction.Count
	|		ELSE
	|			0
	|	END
	|FROM
	|	AccumulationRegister.MaterialsAndWorksInProduction AS WorkInProduction
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON WorkInProduction.Products = Dimension.Products
	|			AND WorkInProduction.Characteristic = Dimension.Characteristic
	|			AND WorkInProduction.Department = Dimension.StorageLocation
	|			AND WorkInProduction.Purpose = Dimension.Purpose
	|			AND (Dimension.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	(WorkInProduction.Organization IN(&Companies)
	|			OR &AllCompanies)
	|	AND (WorkInProduction.Department IN (&Departments)
	|			OR &AllDepartments)
	|	AND WorkInProduction.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND NOT WorkInProduction.Recorder REFS Document.ProductionCostAllocation
	|	AND (Dimension.Products.ItemsType = &ItemsType
	|			OR &AllTypesOfProducts)
	|	AND Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND (Dimension.DimensionKey = &ItemsLocationAttributes
	|			OR &AllAnalysts)
	|
	// Traceable works are recorded in the register "Items of organizations".
	|UNION ALL
	|
	|SELECT
	|	RemainsOfWorks.Organization AS Organization,
	|	Dimension.StorageLocation AS Department,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose,
	|	RemainsOfWorks.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	RemainsOfWorks.CountBalance AS OpeningBalance,
	|	0 AS Received,
	|	0 AS Passed
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|			&BeginOfPeriod,
	|			(Organization IN (&Companies)
	|				OR &AllCompanies)
	|			AND ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND (ItemsLocationAttributes.Department IN (&Departments)
	|				OR &AllDepartments)
	|	) AS RemainsOfWorks
	|
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON Dimension.Ref = RemainsOfWorks.ItemsLocationAttributes
	|WHERE
	|	(Dimension.Products.ItemsType = &ItemsType
	|			OR &AllTypesOfProducts)
	|	AND Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND (RemainsOfWorks.ItemsLocationAttributes = &ItemsLocationAttributes
	|			OR &AllAnalysts)
	|
	|UNION ALL
	|
	|SELECT
	|	WorkInProduction.Organization,
	|	Dimension.StorageLocation AS Department,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose,
	|	WorkInProduction.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	0 AS OpeningBalance,
	|	CASE 
	|		WHEN WorkInProduction.RecordType = VALUE(AccumulationRecordType.Receipt) AND NOT WorkInProduction.ReversingEntry
	|			THEN WorkInProduction.Count
	|		WHEN WorkInProduction.RecordType = VALUE(AccumulationRecordType.Expense) AND WorkInProduction.ReversingEntry
	|			THEN -WorkInProduction.Count
	|		ELSE
	|			0
	|	END AS Received,
	|	CASE 
	|		WHEN WorkInProduction.RecordType = VALUE(AccumulationRecordType.Expense) AND NOT WorkInProduction.ReversingEntry
	|			THEN WorkInProduction.Count
	|		WHEN WorkInProduction.RecordType = VALUE(AccumulationRecordType.Receipt) AND WorkInProduction.ReversingEntry
	|			THEN -WorkInProduction.Count
	|		ELSE
	|			0
	|	END AS Passed
	|FROM
	|	AccumulationRegister.CompanyGoods AS WorkInProduction
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON Dimension.Ref = WorkInProduction.ItemsLocationAttributes
	|WHERE
	|	(WorkInProduction.Organization IN(&Companies)
	|		OR &AllCompanies)
	|	AND (Dimension.Department IN (&Departments)
	|		OR &AllDepartments)
	|	AND WorkInProduction.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND NOT WorkInProduction.Recorder REFS Document.ProductionCostAllocation
	|	AND (Dimension.Products.ItemsType = &ItemsType
	|		OR &AllTypesOfProducts)
	|	AND Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND (WorkInProduction.ItemsLocationAttributes = &ItemsLocationAttributes
	|		OR &AllAnalysts)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTMovementOfMaterials.Organization,
	|	TTMovementOfMaterials.Department,
	|	TTMovementOfMaterials.Warehouse,
	|	TTMovementOfMaterials.Products,
	|	TTMovementOfMaterials.Characteristic,
	|	TTMovementOfMaterials.Series,
	|	TTMovementOfMaterials.Purpose,
	|	TTMovementOfMaterials.ItemsLocationAttributes,
	|	SUM(TTMovementOfMaterials.OpeningBalance) AS OpeningBalance,
	|	SUM(TTMovementOfMaterials.Received) AS Received,
	|	SUM(TTMovementOfMaterials.Passed) AS Passed
	|INTO MovementOfMaterials
	|FROM
	|	TTMovementOfMaterials AS TTMovementOfMaterials
	|
	|GROUP BY
	|	TTMovementOfMaterials.ItemsLocationAttributes,
	|	TTMovementOfMaterials.Organization,
	|	TTMovementOfMaterials.Warehouse,
	|	TTMovementOfMaterials.Purpose,
	|	TTMovementOfMaterials.Products,
	|	TTMovementOfMaterials.Characteristic,
	|	TTMovementOfMaterials.Series,
	|	TTMovementOfMaterials.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Allocation.Ref,
	|	Allocation.Organization,
	|	Allocation.Warehouse,
	|	Allocation.Products,
	|	Allocation.Characteristic,
	|	Allocation.Series,
	|	Allocation.Purpose,
	|	Allocation.ItemsLocationAttributes,
	|	Allocation.Count AS Allocated,
	|	Allocation.Allocate,
	|	Allocation.Department,
	|	Allocation.NewProduction
	|INTO Distributions
	|FROM
	|	Document.ProductionCostAllocation AS Allocation
	|WHERE
	|	Allocation.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND Allocation.Posted
	|	AND (Allocation.NewProduction OR Allocation.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
	|	AND (Allocation.Organization IN(&Companies)
	|			OR &AllCompanies)
	|	AND (Allocation.Products.ItemsType = &ItemsType
	|			OR &AllTypesOfProducts)
	|	AND (Allocation.Department IN (&Departments)
	|			OR &AllDepartments)
	|	AND (Allocation.ItemsLocationAttributes = &ItemsLocationAttributes
	|			OR &AllAnalysts)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED &ChooseFirst,
	|	ISNULL(Distributions.Ref, VALUE(Document.ProductionCostAllocation.EmptyRef)) AS Ref,
	|	ISNULL(Distributions.NewProduction, TRUE) AS NewProduction,
	|	MovementOfMaterials.Organization,
	|	MovementOfMaterials.Department AS Department,
	|	MovementOfMaterials.ItemsLocationAttributes,
	|	MovementOfMaterials.Warehouse,
	|	MovementOfMaterials.Products,
	|	CatProducts.UnitOfMeasure,
	|	MovementOfMaterials.Characteristic,
	|	CASE
	|		WHEN CatProducts.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE CASE
	|				WHEN MovementOfMaterials.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|					THEN FALSE
	|				ELSE TRUE
	|			END
	|	END AS ItemVariantsAreUsed,
	|	MovementOfMaterials.Purpose,
	|	MovementOfMaterials.Series,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.CostAccountingByBatches)
	|			THEN CASE
	|					WHEN MovementOfMaterials.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.BatchesBalancesManagement)
	|			THEN 9
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.BatchesBalancesFEFOManagement)
	|			THEN 5
	|		ELSE 0
	|	END AS BatchesIndicationStatus,
	|	MovementOfMaterials.OpeningBalance,
	|	MovementOfMaterials.Received,
	|	MovementOfMaterials.Passed,
	|	MovementOfMaterials.OpeningBalance + MovementOfMaterials.Received - MovementOfMaterials.Passed AS IncomingBalance,
	|	MovementOfMaterials.OpeningBalance + MovementOfMaterials.Received - MovementOfMaterials.Passed - ISNULL(Distributions.Allocate, 0) - ISNULL(Distributions.Allocated, 0) AS Existence,
	|	ISNULL(Distributions.Allocate, 0) AS Allocate,
	|	ISNULL(Distributions.Allocated, 0) AS Allocated,
	|	(ISNULL(Distributions.Allocate, 0) <> 0) AS AllocationIsRequired,
	|	CatProducts.ItemsType,
	|	CatProducts.SaleRegistrationOption AS SaleRegistrationOption,
	|	CatProducts.DescriptionFull AS ProductFullName,
	|	CatCharacteristics.DescriptionFull AS CharacteristicFullName
	|INTO MaterialsAndWorks
	|FROM
	|	MovementOfMaterials AS MovementOfMaterials
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON MovementOfMaterials.Products = CatProducts.Ref
	|		LEFT JOIN Distributions AS Distributions
	|		ON MovementOfMaterials.Organization = Distributions.Organization
	|			AND MovementOfMaterials.Department = Distributions.Department
	|			AND MovementOfMaterials.Products = Distributions.Products
	|			AND MovementOfMaterials.Characteristic = Distributions.Characteristic
	|			AND MovementOfMaterials.Series = Distributions.Series
	|			AND MovementOfMaterials.Purpose = Distributions.Purpose
	|			AND (MovementOfMaterials.Warehouse = Distributions.Warehouse 
	|				OR CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
	|		LEFT JOIN Catalog.ItemsCharacteristics AS CatCharacteristics
	|		ON MovementOfMaterials.Characteristic = CatCharacteristics.Ref
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON (BatchAccountingPolicies.Warehouse = MovementOfMaterials.Warehouse)
	|			AND (BatchAccountingPolicies.Ref = MovementOfMaterials.Products.ProductKind)
	|WHERE
	|	MovementOfMaterials.OpeningBalance + MovementOfMaterials.Received + MovementOfMaterials.Passed + ISNULL(Distributions.Allocate, 0) + ISNULL(Distributions.Allocated, 0) <> 0
	// all or requiring distribution
	|	AND (&AllRegisteredRecords
	|		OR ISNULL(Distributions.Allocate, 0) <> 0)
	// exclude from the sample lines with revolutions and zero balances
	|	AND (MovementOfMaterials.OpeningBalance + MovementOfMaterials.Received - MovementOfMaterials.Passed <> 0
	|		OR ISNULL(Distributions.Allocate, 0) <> 0
	|		OR ISNULL(Distributions.Allocated, 0) <> 0)
	|
	|UNION ALL
	|
	|SELECT &ChooseFirst,
	|	Allocation.Ref,
	|	Allocation.NewProduction,
	|	Allocation.Organization,
	|	Allocation.Department,
	|	Allocation.ItemsLocationAttributes,
	|	Allocation.Warehouse,
	|	Allocation.Products,
	|	CatProducts.UnitOfMeasure,
	|	Allocation.Characteristic,
	|	CASE
	|		WHEN CatProducts.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE CASE
	|				WHEN Allocation.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|					THEN FALSE
	|				ELSE TRUE
	|			END
	|	END,
	|	Allocation.Purpose,
	|	Allocation.Series,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.CostAccountingByBatches)
	|			THEN CASE
	|					WHEN Allocation.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.BatchesBalancesManagement)
	|			THEN 9
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.BatchesBalancesFEFOManagement)
	|			THEN 5
	|		ELSE 0
	|	END,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	Allocation.Allocate,
	|	Allocation.Allocated,
	|	FALSE,
	|	CatProducts.ItemsType,
	|	CatProducts.SaleRegistrationOption AS SaleRegistrationOption,
	|	CatProducts.DescriptionFull AS ProductFullName,
	|	CatCharacteristics.DescriptionFull AS CharacteristicFullName
	|FROM
	|	Distributions AS Allocation
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON Allocation.Products = CatProducts.Ref
	|		LEFT JOIN TTMovementOfMaterials AS DataTable
	|		ON (DataTable.Organization = Allocation.Organization)
	|			AND (DataTable.Department = Allocation.Department)
	|			AND (DataTable.Products = Allocation.Products)
	|			AND (DataTable.Characteristic = Allocation.Characteristic)
	|			AND (DataTable.Series = Allocation.Series)
	|			AND (DataTable.Purpose = Allocation.Purpose)
	|			AND (DataTable.Warehouse = Allocation.Warehouse 
	|				OR CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
	|		LEFT JOIN Catalog.ItemsCharacteristics AS CatCharacteristics
	|		ON Allocation.Characteristic = CatCharacteristics.Ref
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON (BatchAccountingPolicies.Warehouse = Allocation.Warehouse)
	|			AND (BatchAccountingPolicies.Ref = Allocation.Products.ProductKind)
	|WHERE
	|	DataTable.Products IS NULL
	|	AND Allocation.Allocated + Allocation.Allocate > 0
	|	AND &AllRegisteredRecords
	|;";
	
	If ChooseFirst > 0 Then
		QueryText = StrReplace(QueryText, "&ChooseFirst,", "TOP " + String(ChooseFirst));  //@Query-part-2
	Else
		QueryText = StrReplace(QueryText, "&ChooseFirst,", "");
	EndIf;
	
	If Not ToTemporaryTable Then
		QueryText = StrReplace(QueryText, "INTO MaterialsAndWorks", ""); //@Query-part-1
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the text of the request to fill in the workplace for the distribution of materials and work for the cost of production.
//
//	Returns:
//		String - Query text
//
Function RequestTextFillInProductionCosts(ToTemporaryTable = False) Export
	
	QueryText =  "
	|SELECT
	|	RemainingRevolutions.Organization,
	|	RemainingRevolutions.Products,
	|	RemainingRevolutions.Characteristic,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.CostAccountingByBatches)
	|			THEN RemainingRevolutions.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	RemainingRevolutions.Department,
	|	SUM(RemainingRevolutions.OpeningBalance) AS OpeningBalance,
	|	SUM(RemainingRevolutions.Received) AS Received,
	|	SUM(RemainingRevolutions.NormativeStandard) AS NormativeStandard,
	|	SUM(RemainingRevolutions.Deviation) AS Deviation,
	|	SUM(RemainingRevolutions.ClosingBalance) AS ClosingBalance,
	|	SUM(RemainingRevolutions.Implemented) AS Implemented,
	|	SUM(RemainingRevolutions.Passed) AS Passed,
	|	RemainingRevolutions.Purpose
	|INTO TTRpm
	|FROM
	|	(SELECT
	|		OpeningBalance.Organization,
	|		OpeningBalance.Products,
	|		OpeningBalance.Characteristic,
	|		OpeningBalance.Series,
	|		OpeningBalance.Department,
	|		OpeningBalance.CountBalance AS OpeningBalance,
	|		0 AS Received,
	|		0 AS NormativeStandard,
	|		0 AS Deviation,
	|		0 AS ClosingBalance,
	|		0 AS Implemented,
	|		0 AS Passed,
	|		OpeningBalance.Purpose AS Purpose
	|	FROM
	|		AccumulationRegister.MaterialsAndWorksInProduction.Balance(
	|				&BeginOfPeriod,
	|				Organization IN (&Organization)
	|					AND (Department IN (&Departments)
	|						OR &AllDepartments)) AS OpeningBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ClosingBalance.Organization,
	|		ClosingBalance.Products,
	|		ClosingBalance.Characteristic,
	|		ClosingBalance.Series,
	|		ClosingBalance.Department,
	|		0,
	|		0,
	|		0,
	|		0,
	|		ClosingBalance.CountBalance,
	|		0,
	|		0,
	|		ClosingBalance.Purpose
	|	FROM
	|		AccumulationRegister.MaterialsAndWorksInProduction.Balance(
	|				&BorderEndOfPeriod_,
	|				Organization IN (&Organization)
	|					AND (Department IN (&Departments)
	|						OR &AllDepartments)) AS ClosingBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CostsTurnover.Organization,
	|		CostsTurnover.Products,
	|		CostsTurnover.Characteristic,
	|		CostsTurnover.Series,
	|		CostsTurnover.Department,
	|		0,
	|		SUM(CostsTurnover.CountReceipt),
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		CostsTurnover.Purpose
	|	FROM
	|		AccumulationRegister.MaterialsAndWorksInProduction.Turnovers(
	|				&BeginOfPeriod,
	|				&PeriodEnding,
	|				Recorder,
	|				Organization IN (&Organization)
	|					AND (Department IN (&Departments)
	|						OR &AllDepartments)) AS CostsTurnover
	|	WHERE
	|		(CostsTurnover.CountReceipt > 0
	|)
	|	
	|	GROUP BY
	|		CostsTurnover.Organization,
	|		CostsTurnover.Products,
	|		CostsTurnover.Characteristic,
	|		CostsTurnover.Series,
	|		CostsTurnover.Department,
	|		CostsTurnover.Purpose
	|	
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Costs.Organization,
	|		Costs.Products,
	|		Costs.Characteristic,
	|		Costs.Series,
	|		Costs.Department,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		SUM(Costs.Count),
	|		0,
	|		Costs.Purpose
	|	FROM
	|		AccumulationRegister.MaterialsAndWorksInProduction AS Costs
	|	WHERE
	|		Costs.Organization IN (&Organization)
	|		AND (Costs.Department IN (&Departments)
	|				OR &AllDepartments)
	|		AND Costs.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Costs.ProductionOrder = UNDEFINED
	|		AND Costs.ProductsAccountingDimension = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|		AND (Costs.ExpenseItem = UNDEFINED
	|				OR Costs.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))
	|		AND Costs.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
	|		AND NOT Costs.Recorder REFS Document.ProductionCostAllocation
	|		AND (Costs.Count > 0
	|				OR Costs.Count < 0
	|					AND Costs.Recorder REFS Document.SaleAdjustment)
	|		AND Costs.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND Costs.Active
	|	
	|	GROUP BY
	|		Costs.Organization,
	|		Costs.Products,
	|		Costs.Characteristic,
	|		Costs.Series,
	|		Costs.Department,
	|		Costs.Purpose
	|	) AS RemainingRevolutions
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON (BatchAccountingPolicies.Warehouse = RemainingRevolutions.Department)
	|			AND (BatchAccountingPolicies.Ref = RemainingRevolutions.Products.ProductKind)
	|
	|WHERE
	|	RemainingRevolutions.Department REFS Catalog.BusinessStructure
	|
	|GROUP BY
	|	RemainingRevolutions.Organization,
	|	RemainingRevolutions.Products,
	|	RemainingRevolutions.Characteristic,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.CostAccountingByBatches)
	|			THEN RemainingRevolutions.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	RemainingRevolutions.Department,
	|	RemainingRevolutions.Purpose
	|
	|INDEX BY
	|	Organization,
	|	Products,
	|	Characteristic,
	|	Series,
	|	Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentDistributions.Organization AS Organization,
	|	DocumentDistributions.Products AS Products,
	|	DocumentDistributions.Characteristic AS Characteristic,
	|	DocumentDistributions.Series AS Series,
	|	DocumentDistributions.Department AS Department,
	|	DocumentDistributions.Ref AS Document,
	|	DocumentDistributions.CountReal AS RealBalance,
	|	DocumentDistributions.QuantityToAllocateAccordingToRule AS DistributedAcrossDatabase,
	|	SUM(ISNULL(TSProductionScheduleStages.Count, 0)) AS AllocatedToProduction,
	|	SUM(0) AS WrittenOffAsExpenses,
	|	DocumentDistributions.NewProduction,
	|	DocumentDistributions.Purpose
	|INTO TTDistributionDocument
	|FROM
	|	Document.ProductionCostAllocation AS DocumentDistributions
	|		LEFT JOIN Document.ProductionCostAllocation.ProductionScheduleStages AS TSProductionScheduleStages
	|		ON DocumentDistributions.Ref = TSProductionScheduleStages.Ref
	|WHERE
	|	DocumentDistributions.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND DocumentDistributions.Organization IN (&Organization)
	|	AND (DocumentDistributions.Department IN (&Departments)
	|			OR &AllDepartments)
	|	AND DocumentDistributions.Posted
	|
	|GROUP BY
	|	DocumentDistributions.Organization,
	|	DocumentDistributions.Products,
	|	DocumentDistributions.Characteristic,
	|	DocumentDistributions.Series,
	|	DocumentDistributions.Department,
	|	DocumentDistributions.Ref,
	|	DocumentDistributions.CountReal,
	|	DocumentDistributions.QuantityToAllocateAccordingToRule,
	|	DocumentDistributions.NewProduction,
	|	DocumentDistributions.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDistributions.Organization,
	|	DocumentDistributions.Products,
	|	DocumentDistributions.Characteristic,
	|	DocumentDistributions.Series,
	|	DocumentDistributions.Department,
	|	DocumentDistributions.Ref,
	|	DocumentDistributions.CountReal,
	|	DocumentDistributions.QuantityToAllocateAccordingToRule,
	|	SUM(ISNULL(TSProductionIssueWithoutReferences.Count, 0)),
	|	SUM(0),
	|	DocumentDistributions.NewProduction,
	|	DocumentDistributions.Purpose
	|FROM
	|	Document.ProductionCostAllocation AS DocumentDistributions
	|		LEFT JOIN Document.ProductionCostAllocation.ProductionIssueWithoutReferences AS TSProductionIssueWithoutReferences
	|		ON DocumentDistributions.Ref = TSProductionIssueWithoutReferences.Ref
	|WHERE
	|	DocumentDistributions.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND DocumentDistributions.Organization IN (&Organization)
	|	AND (DocumentDistributions.Department IN (&Departments)
	|			OR &AllDepartments)
	|	AND DocumentDistributions.Posted
	|
	|GROUP BY
	|	DocumentDistributions.Organization,
	|	DocumentDistributions.Products,
	|	DocumentDistributions.Characteristic,
	|	DocumentDistributions.Series,
	|	DocumentDistributions.Department,
	|	DocumentDistributions.Ref,
	|	DocumentDistributions.CountReal,
	|	DocumentDistributions.QuantityToAllocateAccordingToRule,
	|	DocumentDistributions.NewProduction,
	|	DocumentDistributions.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDistributions.Organization,
	|	DocumentDistributions.Products,
	|	DocumentDistributions.Characteristic,
	|	DocumentDistributions.Series,
	|	DocumentDistributions.Department,
	|	DocumentDistributions.Ref,
	|	DocumentDistributions.CountReal,
	|	DocumentDistributions.QuantityToAllocateAccordingToRule,
	|	SUM(0),
	|	SUM(ISNULL(TSOtherExpenses.Count, 0)),
	|	DocumentDistributions.NewProduction,
	|	DocumentDistributions.Purpose
	|FROM
	|	Document.ProductionCostAllocation AS DocumentDistributions
	|		LEFT JOIN Document.ProductionCostAllocation.OtherExpenses AS TSOtherExpenses
	|		ON DocumentDistributions.Ref = TSOtherExpenses.Ref
	|WHERE
	|	DocumentDistributions.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND DocumentDistributions.Organization IN (&Organization)
	|	AND (DocumentDistributions.Department IN (&Departments)
	|			OR &AllDepartments)
	|	AND DocumentDistributions.Posted
	|
	|GROUP BY
	|	DocumentDistributions.Organization,
	|	DocumentDistributions.Products,
	|	DocumentDistributions.Characteristic,
	|	DocumentDistributions.Series,
	|	DocumentDistributions.Department,
	|	DocumentDistributions.Ref,
	|	DocumentDistributions.CountReal,
	|	DocumentDistributions.QuantityToAllocateAccordingToRule,
	|	DocumentDistributions.NewProduction,
	|	DocumentDistributions.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDistributionDocument.Organization AS Organization,
	|	TTDistributionDocument.Products AS Products,
	|	TTDistributionDocument.Characteristic AS Characteristic,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.CostAccountingByBatches)
	|			THEN TTDistributionDocument.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TTDistributionDocument.Department AS Department,
	|	TTDistributionDocument.Document,
	|	TTDistributionDocument.RealBalance,
	|	SUM(TTDistributionDocument.AllocatedToProduction)
	|			   + TTDistributionDocument.DistributedAcrossDatabase AS AllocatedToProduction,
	|	SUM(TTDistributionDocument.WrittenOffAsExpenses) AS WrittenOffAsExpenses,
	|	TTDistributionDocument.NewProduction,
	|	TTDistributionDocument.Purpose
	|INTO DocumentDistributions
	|FROM
	|	TTDistributionDocument AS TTDistributionDocument
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON (BatchAccountingPolicies.Warehouse = TTDistributionDocument.Department)
	|			AND (BatchAccountingPolicies.Ref = TTDistributionDocument.Products.ProductKind)
	|WHERE
	|	NOT TTDistributionDocument.NewProduction OR TTDistributionDocument.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|GROUP BY
	|	TTDistributionDocument.Organization,
	|	TTDistributionDocument.Products,
	|	TTDistributionDocument.Characteristic,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.CostAccountingByBatches)
	|			THEN TTDistributionDocument.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	TTDistributionDocument.Department,
	|	TTDistributionDocument.Document,
	|	TTDistributionDocument.RealBalance,
	|	TTDistributionDocument.DistributedAcrossDatabase,
	|	TTDistributionDocument.NewProduction,
	|	TTDistributionDocument.Purpose
	|
	|HAVING 
	|	SUM(TTDistributionDocument.WrittenOffAsExpenses) + TTDistributionDocument.RealBalance + SUM(TTDistributionDocument.AllocatedToProduction) + TTDistributionDocument.DistributedAcrossDatabase <> 0
	|	OR TTDistributionDocument.DistributedAcrossDatabase <> 0
	|
	|INDEX BY
	|	Organization,
	|	Products,
	|	Characteristic,
	|	Series,
	|	Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RemainingRevolutions.Organization AS Organization,
	|	RemainingRevolutions.Products AS Products,
	|	RemainingRevolutions.Characteristic AS Characteristic,
	|	RemainingRevolutions.Products.ProductKind AS ProductKind,
	|	RemainingRevolutions.Series AS Series,
	|	RemainingRevolutions.Department AS Department,
	|	ISNULL(DocumentDistributions.Document, VALUE(Document.ProductionCostAllocation.EmptyRef)) AS Document,
	|	ISNULL(DocumentDistributions.NewProduction, FALSE) AS NewProduction,
	|	RemainingRevolutions.OpeningBalance,
	|	RemainingRevolutions.Received AS Received,
	|	RemainingRevolutions.NormativeStandard AS NormativeStandard,
	|	RemainingRevolutions.Deviation AS Deviation,
	|	RemainingRevolutions.Implemented AS Implemented,
	|	RemainingRevolutions.Passed AS Passed,
	|	RemainingRevolutions.ClosingBalance AS ClosingBalance,
	|	ISNULL(DocumentDistributions.RealBalance, 0) AS RealBalance,
	|	ISNULL(DocumentDistributions.WrittenOffAsExpenses, 0) AS WrittenOffAsExpenses,
	|	ISNULL(DocumentDistributions.AllocatedToProduction, 0) AS AllocatedToProduction,
	|	RemainingRevolutions.Purpose
	|INTO TTDataTable
	|FROM
	|	TTRpm AS RemainingRevolutions
	|		LEFT JOIN DocumentDistributions AS DocumentDistributions
	|		ON RemainingRevolutions.Organization = DocumentDistributions.Organization
	|			AND RemainingRevolutions.Products = DocumentDistributions.Products
	|			AND RemainingRevolutions.Characteristic = DocumentDistributions.Characteristic
	|			AND RemainingRevolutions.Series = DocumentDistributions.Series
	|			AND RemainingRevolutions.Department = DocumentDistributions.Department
	|			AND RemainingRevolutions.Purpose = DocumentDistributions.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDistributions.Organization,
	|	DocumentDistributions.Products,
	|	DocumentDistributions.Characteristic,
	|	DocumentDistributions.Products.ProductKind,
	|	DocumentDistributions.Series,
	|	DocumentDistributions.Department,
	|	DocumentDistributions.Document,
	|	DocumentDistributions.NewProduction,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	DocumentDistributions.RealBalance,
	|	DocumentDistributions.WrittenOffAsExpenses,
	|	DocumentDistributions.AllocatedToProduction,
	|	DocumentDistributions.Purpose
	|FROM
	|	DocumentDistributions AS DocumentDistributions
	|		LEFT JOIN TTRpm AS RemainingRevolutions
	|		ON DocumentDistributions.Organization = RemainingRevolutions.Organization
	|			AND DocumentDistributions.Products = RemainingRevolutions.Products
	|			AND DocumentDistributions.Characteristic = RemainingRevolutions.Characteristic
	|			AND DocumentDistributions.Series = RemainingRevolutions.Series
	|			AND DocumentDistributions.Department = RemainingRevolutions.Department
	|			AND DocumentDistributions.Purpose = RemainingRevolutions.Purpose
	|WHERE
	|	RemainingRevolutions.Products IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataTable.Document AS Ref,
	|	DataTable.Document AS Document,
	|	DataTable.NewProduction AS NewProduction,
	|	DataTable.Products AS Products,
	|	CatProducts.ItemsType AS ItemsType,
	|	CASE
	|		WHEN CatProducts.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|															VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|															VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE CASE
	|				WHEN DataTable.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|					THEN FALSE
	|				ELSE TRUE
	|			END
	|	END AS ItemVariantsAreUsed,
	|	DataTable.Characteristic AS Characteristic,
	|	DataTable.Series AS Series,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.CostAccountingByBatches)
	|			THEN CASE
	|					WHEN DataTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.BatchesBalancesManagement)
	|			THEN 9
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.BatchesBalancesFEFOManagement)
	|			THEN 5
	|		ELSE 0
	|	END AS BatchesIndicationStatus,
	|	DataTable.Purpose,
	|	DataTable.Organization AS Organization,
	|	DataTable.Department AS Department,
	|	DataTable.OpeningBalance AS OpeningBalance,
	|	DataTable.Received AS Received,
	|	DataTable.NormativeStandard AS NormativeStandard,
	|	DataTable.Deviation AS Deviation,
	|	DataTable.Implemented AS Implemented,
	|	DataTable.WrittenOffAsExpenses AS WrittenOffAsExpenses,
	|	DataTable.Passed AS Passed,
	|	DataTable.AllocatedToProduction AS AllocatedToProduction,
	|	DataTable.RealBalance AS RealBalance,
	|	DataTable.ClosingBalance - DataTable.RealBalance AS IsInProcessing,
	|	ISNULL(DataTable.Received + DataTable.OpeningBalance - DataTable.NormativeStandard - DataTable.Deviation - DataTable.RealBalance - DataTable.Implemented - DataTable.Passed - DataTable.WrittenOffAsExpenses - DataTable.AllocatedToProduction, 0) AS NotAllocated
	|INTO DataTable
	|FROM
	|	TTDataTable AS DataTable
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON DataTable.Products = CatProducts.Ref
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON (BatchAccountingPolicies.Warehouse = DataTable.Department)
	|			AND (BatchAccountingPolicies.Ref = DataTable.ProductKind)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataTable.Document,
	|	DataTable.NewProduction,
	|	DataTable.Products,
	|	DataTable.ItemsType,
	|	DataTable.ItemVariantsAreUsed,
	|	DataTable.Characteristic,
	|	DataTable.Series,
	|	DataTable.BatchesIndicationStatus,
	|	DataTable.Purpose,
	|	DataTable.Organization,
	|	DataTable.Department,
	|	DataTable.OpeningBalance,
	|	DataTable.Received,
	|	DataTable.NormativeStandard,
	|	DataTable.Deviation,
	|	DataTable.Implemented,
	|	DataTable.WrittenOffAsExpenses,
	|	DataTable.Passed,
	|	DataTable.AllocatedToProduction,
	|	DataTable.RealBalance,
	|	DataTable.IsInProcessing,
	|	DataTable.LimitInProcessing,
	|	DataTable.NotAllocated,
	|	CASE
	|		WHEN DataTable.NotAllocated < 0
	|			THEN DataTable.NotAllocated
	|		WHEN DataTable.NotAllocated > DataTable.LimitInProcessing
	|			THEN DataTable.NotAllocated - DataTable.LimitInProcessing
	|		ELSE 0
	|	END AS ForAllocation,
	|	CASE
	|		WHEN DataTable.NotAllocated < 0
	|				OR DataTable.NotAllocated - DataTable.LimitInProcessing > 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS State
	|INTO MaterialsAndWorks
	|FROM
	|	DataTable AS DataTable
	|;
	|";
	
	If Not ToTemporaryTable Then
		QueryText = StrReplace(QueryText, "INTO MaterialsAndWorks", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

// Fills in the table of details that depend on the business transaction
//
// Parameters:
//	Parameters - Structure - Document parameters
//	ArrayOfAllProps - Array - Bank details that do not depend on the business transaction
//	ArrayOfOperationDetails - Array - Bank details that depend on the business transaction.
//
Procedure FillInNamesOfDetailsByDocumentProperties(Parameters, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("Warehouse");
	
	// form elements
	ArrayOfAllProps.Add("PageIssuesWithoutOrders");
	ArrayOfAllProps.Add("PageStages");
	ArrayOfAllProps.Add("ProductionBatchPage");
	ArrayOfAllProps.Add("ActualBalance");
	ArrayOfAllProps.Add("HeaderGroup");
	ArrayOfAllProps.Add("DecorationDataForTheDistributionDatabase");
	
	ArrayOfOperationDetails = New Array;
	If Parameters.NewProduction Then
		If Parameters.ItemsType <> Enums.ItemsTypes.Work_5 Then
			ArrayOfOperationDetails.Add("Warehouse");
		EndIf;
		ArrayOfOperationDetails.Add("ProductionBatchPage");
		ArrayOfOperationDetails.Add("HeaderGroup");
	Else
		ArrayOfOperationDetails.Add("PageIssuesWithoutOrders");
		ArrayOfOperationDetails.Add("ActualBalance");
		ArrayOfOperationDetails.Add("DecorationDataForTheDistributionDatabase");
		
		If Not GetFunctionalOption("ComplexAutomation") Then
			ArrayOfOperationDetails.Add("PageStages");
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns parameters for setting up accounting accounts in the document.
//  
// Returns:
//	See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	
	SetupParameters.AvailabilityByOperation 	= True;
	SetupParameters.DataPath   			= "Object.OtherExpenses";
	SetupParameters.ArticleType     			= "ArticleType";
	SetupParameters.Organization 				= "Object.Organization";
	
	SetupParameters.FormItems.Add("OtherExpensesTransactionRecordingPresentation");
	
	Return SetupParameters;
	
EndFunction

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
//	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters() Export 
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.OtherExpenses";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	ChoiceParameters.ArticleType   = "ArticleType";
	
	ChoiceParameters.DimensionOfExpenses 		 = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	
	OptionsArray = New Array;
	OptionsArray.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	OptionsArray.Add(Enums.CostAllocationOptions.ToDeferredExpenses);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCosts);
	OptionsArray.Add(Enums.CostAllocationOptions.ToNonCurrentAssetCost);
	OptionsArray.Add(Enums.CostAllocationOptions.DoNotAllocate);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCostCenters);
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
	OptionsArray.Add(Enums.CostAllocationOptions.ToInventoryCost);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCostOfGoodsSold);
	
	ChoiceParameters.SelectionOfExpenditureItems.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	ChoiceParameters.SelectionOfExpenditureItems.CostAllocationOption = OptionsArray;
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	
	ChoiceParameters.FormItems.AssetRef.Add("OtherExpensesExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("OtherExpensesDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("OtherExpensesAssetsLiabilitiesDimension");
	
	Return ChoiceParameters;
	
EndFunction

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Array - the elements of which is the structure (See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand)
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	Return DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();;
	
EndFunction

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#Region InterfaceImplementation

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	TemplateOfPresentation = NStr("vi = 'Phân bổ chi phí nguyên vật liệu (nhân công) ""%1"" cho %2 (số %3)';
									|ru = 'Распределение материала (работы) ""%1"" за %2 (№%3)';
									|en = 'Allocation of material (work) ""%1"" for %2 (No.%3)'; fa = 'Allocation of material (work) ""%1"" for %2 (No.%3)';
									|it = 'Distribuzione di materiale (lavoro) ""%1"" del %2 (№%3)';
									|pl = ' Przydział materiałów (prac) ""%1"" za %2 (nr %3)';
									|tr = 'Malzemelerin (işlerin) dağıtımı ""%1"" %2 boyunca (%3 numaralı)'");
	
	PresentationOfMaterial = ProductsClientServer.ProductPresentation(Data.Products, Data.Characteristic, Data.Series);
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfPresentation,
		PresentationOfMaterial,
		Format(Data.Date,NStr("vi = 'ДФ=''ММММ гггг''';
								|ru = 'ДФ=''ММММ гггг''';
								|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
								|it = 'ДФ=''ММММ гггг''';
								|pl = 'DF=''MMMM yyyy''';
								|tr = 'DF=''MMMM yyyy'''")), Data.Number);
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Products");
	Fields.Add("Characteristic");
	Fields.Add("Series");
	Fields.Add("Warehouse");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.Products AS Products,
	|	DocumentData.Products.TracedGoods AS TracedGoods,
	|	DocumentData.Characteristic AS Characteristic,
	|	DocumentData.Series AS Series,
	|	DocumentData.Purpose AS Purpose,
	|	DocumentData.Purpose.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Purpose.RecordsInWarehouseRegisters AS RecordsInWarehouseRegisters,
	|	DocumentData.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DocumentData.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	DocumentData.Products.ItemsType AS ItemsType,
	|	DocumentData.NewProduction AS NewProduction,
	|	DocumentData.Count AS Count,
	|	DocumentData.CountReal AS CountReal,
	|	CASE
	|		WHEN DocumentData.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Work_5,
	|	DocumentData.EmployeeResponsible,
	|	DocumentData.Comment
	|FROM
	|	Document.ProductionCostAllocation AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("Warehouse",                ?(ValueIsFilled(Attributes.Warehouse), Attributes.Warehouse, Attributes.Department));
	Query.SetParameter("EmptyAssignment",     Catalogs.Assignments.EmptyRef());
	
	Query.SetParameter("AnalyticalAccountingByProductsGroups", GetFunctionalOption("AnalyticalAccountingByProductsGroups"));
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	Query.SetParameter("MetadataIdentifier",
		Common.MetadataObjectID(Type("DocumentRef.ProductionCostAllocation")));

	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.ExpensingToProductionLots);
	
	
EndProcedure

Procedure InitializeProductAnalysisKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	MaterialAnalysis.Products   AS Products,
	|	MaterialAnalysis.Characteristic AS Characteristic,
	|	MaterialAnalysis.Warehouse          AS Warehouse,
	|	MaterialAnalysis.Series          AS Series,
	|	MaterialAnalysis.Purpose     AS Purpose,
	|	MaterialAnalysis.ProductCostElement AS ProductCostElement
	|FROM
	|	(SELECT
	|		Dimension.Products AS Products,
	|		Dimension.Characteristic AS Characteristic,
	|		Dimension.StorageLocation AS Warehouse,
	|		Dimension.Series AS Series,
	|		&EmptyAssignment AS Purpose,
	|		Dimension.ProductCostElement AS ProductCostElement
	|	FROM
	|		Document.ProductionCostAllocation.InventoryKinds AS InventoryKinds
	|			INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|				ON InventoryKinds.ItemsLocationAttributes = Dimension.Ref
	|	WHERE
	|		InventoryKinds.Ref = &Ref
	|	
	|	UNION ALL
	|
	|	SELECT
	|		Dimension.Products AS Products,
	|		Dimension.Characteristic AS Characteristic,
	|		Dimension.StorageLocation AS Warehouse,
	|		Dimension.Series AS Series,
	|		&EmptyAssignment AS Purpose,
	|		Dimension.ProductCostElement AS ProductCostElement
	|	FROM
	|		Document.ProductionCostAllocation.InventoryKinds AS InventoryKinds
	|			INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|				ON InventoryKinds.CorItemsLocationAttributes = Dimension.Ref
	|	WHERE
	|		InventoryKinds.Ref = &Ref
	|	
	|	UNION ALL
	|
	|	SELECT
	|		Dimension.Products AS Products,
	|		Dimension.Characteristic AS Characteristic,
	|		Dimension.StorageLocation AS Warehouse,
	|		Dimension.Series AS Series,
	|		&EmptyAssignment AS Purpose,
	|		Dimension.ProductCostElement AS ProductCostElement
	|	FROM
	|		Document.ProductionCostAllocation.ProductionLots AS Lots
	|			INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|				ON Lots.ItemsLocationAttributes = Dimension.Ref
	|	WHERE
	|		Lots.Ref = &Ref
	|
	|	) AS MaterialAnalysis
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON  MaterialAnalysis.Products   = Dimension.Products
	|		  AND MaterialAnalysis.Characteristic = Dimension.Characteristic
	|		  AND MaterialAnalysis.Warehouse          = Dimension.StorageLocation
	|		  AND MaterialAnalysis.Series          = Dimension.Series
	|		  AND MaterialAnalysis.Purpose     = Dimension.Purpose
	|		  AND MaterialAnalysis.ProductCostElement = Dimension.ProductCostElement
	|WHERE
	|	Dimension.Products IS NULL ";
	
	QueryAnalyst.SetParameter("Ref",           Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	InitializeProductAnalysisKeys(Query);
	
	
	QueryText =
	// movement of works for new production
	"SELECT
	|	0 AS Order,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	0 AS LineNumber,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Products AS Products,
	|	&Characteristic AS Characteristic,
	|	UNDEFINED AS Series,
	|	&Purpose AS Purpose,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	DocumentData.Count AS Count,
	|	UNDEFINED AS ProductCostElement,
	|	UNDEFINED AS ProductionOrder,
	|	UNDEFINED AS RowCodeProducts,
	|	UNDEFINED AS Stage,
	|	UNDEFINED AS ProductsAccountingDimension,
	|	UNDEFINED AS BillOfMaterials,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS ReceivingBusinessUnit,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS RowID
	|FROM
	|	Document.ProductionCostAllocation AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &NewProduction
	|	AND &Work_5
	|	AND NOT DocumentData.Count = 0
	|	AND NOT &TracedGoods
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTypesOfStocksAndWork(Query, QueryTexts)
	
	RegisterName = "TypesOfStocksAndWork";
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	Dimension.Products.ItemsType        AS ItemsType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	CatInventoryKinds.InventoryType                     AS InventoryType,
	|	CatInventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner            AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	CatInventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey          AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	Dimension.Products                        AS Products,
	|	Dimension.Characteristic                      AS Characteristic,
	|	Dimension.StorageLocation						  AS Warehouse,
	|	Dimension.Purpose                          AS Purpose,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityByGBRN,
	|	TableTypesOfStocks_.BusinessOperation      AS BusinessOperation,
	|	UNDEFINED                                  AS VATTaxation,
	|	TableTypesOfStocks_.ExpenseItem             AS ExpenseItem,
	|	TableTypesOfStocks_.Department              AS ExpenseRecipientDivision,
	|	TableTypesOfStocks_.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.GLAccountSettings       AS GLAccountSettings,
	|	TableTypesOfStocks_.ProductionLot         AS ProductionLot,
	|	CASE
	|		WHEN NOT CatProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN CatProductionLots.ProductsGroup
	|		ELSE
	|			UNDEFINED
	|	END                                         AS FinancialAccountingDimension,
	// Tolling materials and semi-finished products are always on a separate accounting section
	// for their own accounting section are production costs.
	|	CASE
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|	END                                         AS AccountingSection,
	|	CASE
	|		WHEN TableTypesOfStocks_.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand) THEN
	|			UNDEFINED
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|		WHEN CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		ELSE
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|	END                                         AS RecipientAccountingSection,
	|	CASE
	|		WHEN TableTypesOfStocks_.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand) THEN
	|			UNDEFINED
	|		ELSE
	|			TableTypesOfStocks_.RecipientInventoryOwnerAttribute
	|	END                                         AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	CorAnalyticsWithoutAssignment.DimensionKey       AS CorAnalysisOfAccountingForProductsWithoutAssignment,
	|	TableTypesOfStocks_.RowID        AS RowID,
	|	CommitteeKeys.DimensionKey                  AS CommitteeAnalytics,
	|	AnalysisOfSettlementsWithCommittee.DimensionKey    AS AccountingDimensionByPartners,
	|	CatProductionLots.VATActivityType      AS CorVATActivityTypes,
	|	TableTypesOfStocks_.FinRecordID     AS FinRecordID,
	|	ISNULL(BusinessTransactionsSettings.Ref, &BusinessTransactionSetting) AS BusinessTransactionSetting
	|
	|INTO TypesOfStocksAndWork
	|FROM
	|	Document.ProductionCostAllocation.InventoryKinds AS TableTypesOfStocks_
	|
	|	INNER JOIN Catalog.InventoryKinds AS CatInventoryKinds
	|	ON TableTypesOfStocks_.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND &EmptyAssignment = AnalyticsWithoutAssignment.Purpose
	|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CorDimension
	|	ON TableTypesOfStocks_.CorItemsLocationAttributes = CorDimension.Ref
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS CorAnalyticsWithoutAssignment
	|	ON CorDimension.Products = CorAnalyticsWithoutAssignment.Products
	|		AND CorDimension.Characteristic = CorAnalyticsWithoutAssignment.Characteristic
	|		AND &EmptyAssignment = CorAnalyticsWithoutAssignment.Purpose
	|		AND CorDimension.Series = CorAnalyticsWithoutAssignment.Series
	|		AND CorDimension.StorageLocation = CorAnalyticsWithoutAssignment.StorageLocation
	|		AND CorDimension.ProductCostElement = CorAnalyticsWithoutAssignment.ProductCostElement
	|	
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Ref = TableTypesOfStocks_.ProductionLot
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeKeys
	|	ON Dimension.Products = CommitteeKeys.Products
	|		AND Dimension.Characteristic = CommitteeKeys.Characteristic
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeKeys.ProductCostElement
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeKeys.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeKeys.Series
	|		AND CatInventoryKinds.GoodsOwner = CommitteeKeys.StorageLocation
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfSettlementsWithCommittee
	|	ON &Organization = AnalysisOfSettlementsWithCommittee.Organization
	|		AND CatInventoryKinds.GoodsOwner = AnalysisOfSettlementsWithCommittee.Partner
	|		AND CatInventoryKinds.Counterparty = AnalysisOfSettlementsWithCommittee.Counterparty
	|		AND CatInventoryKinds.Contract = AnalysisOfSettlementsWithCommittee.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = AnalysisOfSettlementsWithCommittee.LineOfBusiness
	|
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON TableTypesOfStocks_.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|	
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DistributionToParties.LineNumber             AS LineNumber,
	|	Dimension.Products.ItemsType        AS ItemsType,
	|	UNDEFINED                                  AS InventoryOwnerAttribute,
	|	UNDEFINED                                  AS InventoryType,
	|	UNDEFINED                                  AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	FALSE                                          AS SaleOfAnotherCompanyInventory,
	|	UNDEFINED                                  AS CCDNumber,
	|	Attributes.ItemsLocationAttributes          AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey          AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	Dimension.Products                        AS Products,
	|	Dimension.Characteristic                      AS Characteristic,
	|	Dimension.StorageLocation                       AS Warehouse,
	|	Dimension.Purpose                          AS Purpose,
	|	DistributionToParties.Count              AS Count,
	|	0                                             AS QuantityByGBRN,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS BusinessOperation,
	|	UNDEFINED                                  AS VATTaxation,
	|	UNDEFINED                                  AS ExpenseItem,
	|	UNDEFINED                                  AS ExpenseRecipientDivision,
	|	UNDEFINED                                  AS DimensionOfExpenses,
	|	UNDEFINED                                  AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                  AS GLAccountSettings,
	|	DistributionToParties.ProductionLot      AS ProductionLot,
	|	CASE
	|		WHEN NOT CatProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN CatProductionLots.ProductsGroup
	|		ELSE
	|			UNDEFINED
	|	END                                         AS FinancialAccountingDimension,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS RecipientAccountingSection,
	|	UNDEFINED                                     AS RecipientInventoryOwnerAttribute,
	|	DistributionToParties.ItemsLocationAttributes AS CorItemsLocationAttributes,
	|	RecipientAnalyticsWithoutAssignment.DimensionKey   AS CorAnalysisOfAccountingForProductsWithoutAssignment,
	|	UNDEFINED                                     AS RowID,
	|	UNDEFINED                                     AS CommitteeAnalytics,
	|	UNDEFINED                                     AS AccountingDimensionByPartners,
	|	CatProductionLots.VATActivityType         AS CorVATActivityTypes,
	|	DistributionToParties.RowID        AS FinRecordID,
	|	&BusinessTransactionSetting                  AS BusinessTransactionSetting 
	|FROM
	|	Document.ProductionCostAllocation.ProductionLots AS DistributionToParties
	|
	|	INNER JOIN
	|		Document.ProductionCostAllocation AS Attributes
	|	ON
	|		DistributionToParties.Ref = Attributes.Ref
	|
	|	INNER JOIN
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		Attributes.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON
	|		Dimension.Products = AnalyticsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND &EmptyAssignment = AnalyticsWithoutAssignment.Purpose
	|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|	
	|	INNER JOIN
	|		Catalog.InventoryLocationAttributeKeys AS RecipientAnalytics
	|	ON
	|		DistributionToParties.ItemsLocationAttributes = RecipientAnalytics.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS RecipientAnalyticsWithoutAssignment
	|	ON
	|		RecipientAnalytics.Products = RecipientAnalyticsWithoutAssignment.Products
	|		AND RecipientAnalytics.Characteristic = RecipientAnalyticsWithoutAssignment.Characteristic
	|		AND &EmptyAssignment = RecipientAnalyticsWithoutAssignment.Purpose
	|		AND RecipientAnalytics.Series = RecipientAnalyticsWithoutAssignment.Series
	|		AND RecipientAnalytics.StorageLocation = RecipientAnalyticsWithoutAssignment.StorageLocation
	|		AND RecipientAnalytics.ProductCostElement = RecipientAnalyticsWithoutAssignment.ProductCostElement
	|	
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Ref = DistributionToParties.ProductionLot
	|	
	|WHERE
	|	DistributionToParties.Ref = &Ref
	|	AND Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT &TracedGoods
	|
	|UNION ALL
	|
	|SELECT
	|	AllocationToExpenses.LineNumber            AS LineNumber,
	|	Dimension.Products.ItemsType        AS ItemsType,
	|	UNDEFINED                                  AS InventoryOwnerAttribute,
	|	UNDEFINED                                  AS InventoryType,
	|	UNDEFINED                                  AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	FALSE                                          AS SaleOfAnotherCompanyInventory,
	|	UNDEFINED                                  AS CCDNumber,
	|	Attributes.ItemsLocationAttributes          AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey          AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	Dimension.Products                        AS Products,
	|	Dimension.Characteristic                      AS Characteristic,
	|	Dimension.StorageLocation						  AS Warehouse,
	|	Dimension.Purpose                          AS Purpose,
	|	AllocationToExpenses.Count             AS Count,
	|	0                                             AS QuantityByGBRN,
	|	VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand) AS BusinessOperation,
	|	UNDEFINED                                  AS VATTaxation,
	|	AllocationToExpenses.ExpenseItem         AS ExpenseItem,
	|	CASE
	|		WHEN AllocationToExpenses.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN &Department
	|		ELSE AllocationToExpenses.Department
	|	END                                            AS ExpenseRecipientDivision,
	|	AllocationToExpenses.DimensionOfExpenses         AS DimensionOfExpenses,
	|	AllocationToExpenses.AssetsLiabilitiesDimension  AS AssetsLiabilitiesDimension,
	|	AllocationToExpenses.GLAccountSettings      AS GLAccountSettings,
	|	VALUE(Catalog.ProductionLots.EmptyRef) AS ProductionLot,
	|	UNDEFINED                                     AS FinancialAccountingDimension,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
	|	UNDEFINED                                     AS RecipientAccountingSection,
	|	UNDEFINED                                     AS RecipientInventoryOwnerAttribute,
	|	UNDEFINED                                     AS CorItemsLocationAttributes,
	|	UNDEFINED                                     AS CorAnalysisOfAccountingForProductsWithoutAssignment,
	|	AllocationToExpenses.RowID       AS RowID,
	|	UNDEFINED                                     AS CommitteeAnalytics,
	|	UNDEFINED                                     AS AccountingDimensionByPartners,
	|	UNDEFINED                                     AS CorVATActivityTypes,
	|	AllocationToExpenses.RowID       AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand) AS BusinessTransactionsSetting
	|FROM
	|	Document.ProductionCostAllocation.OtherExpenses AS AllocationToExpenses
	|
	|	INNER JOIN
	|		Document.ProductionCostAllocation AS Attributes
	|	ON
	|		AllocationToExpenses.Ref = Attributes.Ref
	|
	|	INNER JOIN
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		Attributes.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON
	|		Dimension.Products = AnalyticsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND &EmptyAssignment = AnalyticsWithoutAssignment.Purpose
	|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|	
	|WHERE
	|	AllocationToExpenses.Ref = &Ref
	|	AND Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT &TracedGoods
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TypesOfStocksAndWork", QueryTexts) Then
		QueryTextTypesOfStocksAndWork(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	// Consumption of materials from the warehouse
	//   - written off for expenses
	//   - manually distributed
	//   - distributed according to the rules.
	|SELECT
	|	1                                              AS Order,
	|	InventoryKinds.LineNumber                        AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)         AS RecordType,
	|	&Period                                        AS Period,
	|	InventoryKinds.ItemsLocationAttributes         AS ItemsLocationAttributes,
	|	&Organization                                   AS ShipmentCompany,
	|	CASE WHEN InventoryKinds.SaleOfAnotherCompanyInventory THEN
	|		InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|	ELSE
	|		&Organization
	|	END                                          AS Organization,
	|	InventoryKinds.InventoryOwnerAttribute                         AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber                           AS CCDNumber,
	|	SUM(InventoryKinds.Count)                  AS Count,
	|	SUM(InventoryKinds.QuantityByGBRN)            AS QuantityByGBRN,
	|	InventoryKinds.BusinessOperation              AS BusinessOperation
	|FROM
	|	TypesOfStocksAndWork AS InventoryKinds
	|
	|WHERE
	|	&NewProduction
	|	AND NOT (InventoryKinds.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND NOT &TracedGoods)
	|
	|GROUP BY
	|	InventoryKinds.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	CASE WHEN InventoryKinds.SaleOfAnotherCompanyInventory THEN
	|		InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|	ELSE
	|		&Organization
	|	END,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.BusinessOperation
	|
	|ORDER BY
	|	Order,
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TypesOfStocksAndWork", QueryTexts) Then
		QueryTextTypesOfStocksAndWork(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)				AS RecordType,
	|	&Period												AS Period,
	|	&Organization 										AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CommitteeAnalytics				AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency				AS Currency,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	0													AS Count,
	|	0													AS RevenueAmount,
	|	0													AS RevenueAmountExclVATLocal,
	|	0													AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count						AS QuantityConsumed,
	|	0													AS QuantityToRegister,
	|	0													AS QuantityForRegistrationByProductBatchID,
	|	0													AS RevenueAmountToRegister,
	|	TableTypesOfStocks_.Count				AS QuantityConsumedForIncoiceRegistration,
	|	TableTypesOfStocks_.QuantityByGBRN			AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	TableTypesOfStocks_.Products						AS Products,
	|	TableTypesOfStocks_.Characteristic					AS Characteristic,
	|	TableTypesOfStocks_.BusinessOperation			AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID			AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting	AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID				AS RowID
	|FROM
	|	TypesOfStocksAndWork AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ArrangeShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest =
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	DocumentGoods.Date				AS Period,
	|	UNDEFINED						AS OrderDocument,
	|	DocumentGoods.Ref				AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	DocumentGoods.Department		AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	FALSE								AS ShipmentByOrder
	|FROM
	|	Document.ProductionCostAllocation AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.NewProduction
	|	AND DocumentGoods.BatchesIndicationStatus <> 10";
	
	WarehousesServer.ArrangeShipmentOfGoods(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										Metadata.Documents.ProductionCostAllocation,
										"SetOfSeries");
	
	TextOfDocumentDataRequest =
	"SELECT
	|	DocumentGoods.Ref			AS Ref,
	|	HeaderData_.Date				AS Period,
	|	UNDEFINED					AS OrderDocument,
	|	HeaderData_.Ref				AS Invoice,
	|	FALSE							AS Patch,
	|	UNDEFINED					AS CorrectedDocument,
	|	HeaderData_.Department		AS Recipient,
	|	HeaderData_.Warehouse				AS Warehouse,
	|	DocumentGoods.Products	AS Products,
	|	DocumentGoods.Characteristic	AS Characteristic,
	|	DocumentGoods.Purpose		AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series			AS Series,
	|	HeaderData_.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count		AS Count,
	|	FALSE							AS ExceedingOrder,
	|	FALSE							AS ShipmentByOrder
	|FROM
	|	Document.ProductionCostAllocation.SetOfSeries AS DocumentGoods
	|		INNER JOIN Document.ProductionCostAllocation AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|			AND DocumentGoods.Products = HeaderData_.Products
	|			AND DocumentGoods.Characteristic = HeaderData_.Characteristic
	|			AND DocumentGoods.Purpose = HeaderData_.Purpose
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.NewProduction
	|	AND HeaderData_.BatchesIndicationStatus = 10";
	
	WarehousesServer.ArrangeShipmentOfGoods(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										Metadata.Documents.ProductionCostAllocation,
										"SetOfSeries");
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	Attributes.Ref				AS Ref,
	|	Attributes.Date					AS Period,
	|	UNDEFINED					AS OrderDocument,
	|	Attributes.Ref				AS Invoice,
	|	FALSE							AS Patch,
	|	UNDEFINED					AS CorrectedDocument,
	|	Attributes.Department			AS Recipient,
	|	Attributes.Warehouse					AS Warehouse,
	|	Attributes.Products			AS Products,
	|	Attributes.Characteristic		AS Characteristic,
	|	Attributes.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	Attributes.Series					AS Series,
	|	Attributes.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	Attributes.Count			AS Count,
	|	FALSE							AS ExceedingOrder,
	|	FALSE							AS Canceled,
	|	TRUE							AS ThisIsAnInvoice,
	|	FALSE							AS ShipmentByOrder
	|FROM
	|	Document.ProductionCostAllocation AS Attributes
	|WHERE
	|	Attributes.Ref IN(&Ref)
	|	AND Attributes.NewProduction
	|	AND Attributes.BatchesIndicationStatus <> 10";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref			AS Ref,
	|	HeaderData_.Date				AS Period,
	|	UNDEFINED					AS OrderDocument,
	|	HeaderData_.Ref				AS Invoice,
	|	FALSE							AS Patch,
	|	UNDEFINED					AS CorrectedDocument,
	|	HeaderData_.Department		AS Recipient,
	|	HeaderData_.Warehouse				AS Warehouse,
	|	DocumentGoods.Products	AS Products,
	|	DocumentGoods.Characteristic	AS Characteristic,
	|	DocumentGoods.Purpose		AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series			AS Series,
	|	HeaderData_.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count		AS Count,
	|	FALSE							AS ExceedingOrder,
	|	FALSE							AS Canceled,
	|	TRUE							AS ThisIsAnInvoice,
	|	FALSE							AS ShipmentByOrder
	|FROM
	|	Document.ProductionCostAllocation.SetOfSeries AS DocumentGoods
	|		INNER JOIN Document.ProductionCostAllocation AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|			AND DocumentGoods.Products = HeaderData_.Products
	|			AND DocumentGoods.Characteristic = HeaderData_.Characteristic
	|			AND DocumentGoods.Purpose = HeaderData_.Purpose
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.NewProduction
	|	AND HeaderData_.BatchesIndicationStatus = 10";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	&Products        AS Products,
	|	&Characteristic      AS Characteristic,
	|	&Purpose          AS Purpose,
	|	&Series               AS Series,
	|	&Count          AS Count,
	|	&Department       AS Sender,
	|	UNDEFINED         AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.AllocationForCosts) AS WarehouseOperation,
	|	&Ref              AS Document,
	|	&Period              AS Period,
	|	TRUE               AS ThisIsWarehouseRecord
	|WHERE
	|	&Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	&Products           AS Products,
	|	&Characteristic         AS Characteristic,
	|	&Purpose             AS Purpose,
	|	SeriesTable.Series      AS Series,
	|	SeriesTable.Count AS Count,
	|	&Department          AS Sender,
	|	UNDEFINED            AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.AllocationForCosts) AS WarehouseOperation,
	|	&Ref                 AS Document,
	|	&Period                 AS Period,
	|	TRUE                  AS ThisIsWarehouseRecord
	|FROM
	|	Document.ProductionCostAllocation.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction


Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TypesOfStocksAndWork", QueryTexts) Then
		QueryTextTypesOfStocksAndWork(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	TableExpenses.ExpenseItem AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	TableExpenses.FinRecordID AS FinRecordID,
	|	TableExpenses.BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|INTO TTInitialOtherExpenses
	|FROM
	|	TypesOfStocksAndWork AS TableExpenses
	|WHERE
	|	TableExpenses.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RegisterRecordsProductsIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TypesOfStocksAndWork", QueryTexts) Then
		QueryTextTypesOfStocksAndWork(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	CASE
	|		WHEN Rows.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|				AND Rows.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN
	|				CASE 
	|					WHEN Rows.ExpenseItem.VATAssetTaxClass IN (
	|							VALUE(Enum.AssetKinds.FA),
	|							VALUE(Enum.AssetKinds.ConstructionInProgressObjects))
	|						THEN VALUE(Enum.BusinessTransactions.TransferToFixedAssets)
	|					WHEN Rows.ExpenseItem.VATAssetTaxClass = VALUE(Enum.AssetKinds.IA)
	|						THEN VALUE(Enum.BusinessTransactions.TransferToIntangibleAssetsAndRD)
	|				END
	|		WHEN Rows.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|				AND Rows.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN VALUE(Enum.BusinessTransactions.TransferForOtherPurposes)
	|		WHEN Rows.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			THEN VALUE(Enum.BusinessTransactions.TransferForOtherPurposes)
	|		ELSE
	|			Rows.BusinessOperation
	|	END AS BusinessOperation,
	|	&Organization AS Organization,
	|	Rows.ExpenseRecipientDivision AS Department,
	|
	|	CASE WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			Rows.CommitteeAnalytics
	|		ELSE
	|			CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
	|				THEN Rows.ItemsLocationAttributes
	|				ELSE Rows.AnalysisOfAccountingForProductsWithoutAssignment
	|			END
	|	END AS ItemsLocationAttributes,
	|	CASE WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		Rows.CommitteeAnalytics.StorageLocation
	|	ELSE
	|		&Warehouse
	|	END AS Warehouse,
	|
	|	CASE
	|		WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			UNDEFINED
	|		ELSE
	|			Rows.InventoryOwnerAttribute
	|		END AS InventoryOwnerAttribute,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|
	|	Rows.ExpenseItem AS IncomeAndExpenseItem,
	|	Rows.DimensionOfExpenses AS DimensionOfExpenses,
	|	Rows.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|	CASE WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			InventoryKinds.Contract.LineOfBusiness
	|		ELSE
	|			Rows.Purpose.LineOfBusiness
	|	END AS ProductLineOfBusiness,
	|	&LineOfBusiness AS LineOfBusinessItems,
	|
	|	Rows.Count AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		Rows.InventoryOwnerAttribute
	|	ELSE
	|		Rows.Products
	|	END AS SourceOfProductFinancialAccountingGroup
	|
	|FROM
	|	TypesOfStocksAndWork AS Rows
	|	LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|	ON Rows.InventoryOwnerAttribute = InventoryKinds.Ref
	|WHERE
	|	Rows.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)";
		
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref						AS Ref,
	|	UNDEFINED				AS RecordSeparator,
	|	&Period						AS IBDocumentDate,
	|	&Number						AS IBDocumentNumber,
	|	&MetadataIdentifier	AS RefType,
	|	&Organization				AS Organization,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS BusinessOperation,
	|	&LineOfBusiness	AS LineOfBusiness,
	|	&Department				AS Department,
	|	&EmployeeResponsible				AS EmployeeResponsible,
	|	&Comment				AS Comment,
	|	0							AS Sum,
	|	&Posted					AS Posted,
	|	&DeletionMark			AS DeletionMark,
	|	FALSE						AS AdditionalRecord,
	|	""""						AS More,
	|	&Period						AS SourceDocumentDate,
	|	&NumberForPrinting				AS SourceDocumentNumber,
	|	&Department				AS StorageLocation,
	|	&Period						AS RecordingInAccountingDate,
	|	UNDEFINED                AS Priority
	|FROM
	|	Document.ProductionCostAllocation AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.ProductionCostAllocation";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("Work_5",
		"DocumentData.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)");
	RedefiningParameterCalculation.Insert("RecordsInWarehouseRegisters",
		"DocumentData.Purpose.RecordsInWarehouseRegisters");
	RedefiningParameterCalculation.Insert("LineOfBusiness",
		"DocumentData.Purpose.LineOfBusiness");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydına göre hareketlerin düzenlenmesi talebinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
		QueryText,
		FullDocumentName,
		SynonymForDocumentTable,
		RequestHasSource,
		RedefiningParameterCalculation);
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.ProductionCostAllocation AS TabPart
		|WHERE
		|	TabPart.NewProduction
		|	OR TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	
	If Query <> Undefined Then
		// There are no additional parameters.
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TypesOfStocksAndWork");
	AdditionalTables.Add("TTOtherExpenses_");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTypesOfStocksAndWork(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTableTTOtherExpenses_(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region WriteOffToOtherLots_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					 	AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 	AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CorVATActivityTypes		 	AS VATActivityType,
	|	TableTypesOfStocks_.CorVATActivityTypes			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED										AS CorCompany,
	|	TableTypesOfStocks_.ProductionLot              	AS CorLot,
	|	TableTypesOfStocks_.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute				AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED											AS SalesOpportunity,
	|	UNDEFINED                            				AS Department,
	|	UNDEFINED											AS Manager,
	|	TableTypesOfStocks_.ProductionLot.ProductsGroup 	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	TableTypesOfStocks_.BusinessOperation									AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID									AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting							AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ProductionCostAllocation AS DocumentTable
	|	INNER JOIN TypesOfStocksAndWork AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND &NewProduction
	|	AND (TableTypesOfStocks_.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|	OR TableTypesOfStocks_.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots)
	|	AND &MovingAverage AND DocumentTable.QuantityToAllocateAccordingToRule <> 0)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExpensesToOtherProductionLots,
		QueryText);
		
	#EndRegion
	
	#Region WriteOffForExpensesAssets_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CorVATActivityTypes		AS VATActivityType,
	|	TableTypesOfStocks_.CorVATActivityTypes		AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	ISNULL(TTOtherExpenses_.CompanyRecipient, UNDEFINED) AS CorCompany,
	|	TableTypesOfStocks_.CorItemsLocationAttributes 			AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute		    			AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ExpenseItem 			    			AS ExpenseItemAssets,
	|	CASE WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|		THEN TableTypesOfStocks_.DimensionOfExpenses                
	|		ELSE TableTypesOfStocks_.AssetsLiabilitiesDimension
	|	END    						  			    			AS AssetExpenseAnalytics,
	|	TableTypesOfStocks_.Purpose.LineOfBusiness		AS CorLineOfBusiness,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED											AS SalesOpportunity,
	|	TableTypesOfStocks_.ExpenseRecipientDivision		AS Department,
	|	UNDEFINED											AS Manager,
	|	TableTypesOfStocks_.ProductionLot.ProductsGroup 	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 		AS Count,
	|
	// Other fields
	|	TableTypesOfStocks_.GLAccountSettings                 					AS GLAccountSettings,
	|	TableTypesOfStocks_.BusinessOperation									AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	 									AS RowID,
	|	TableTypesOfStocks_.FinRecordID									AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting							AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ProductionCostAllocation AS DocumentTable
	|	INNER JOIN TypesOfStocksAndWork AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN TTOtherExpenses_ AS TTOtherExpenses_
	|		ON TTOtherExpenses_.ExpenseItem = TableTypesOfStocks_.ExpenseItem
	|		AND TTOtherExpenses_.DimensionOfExpenses = TableTypesOfStocks_.DimensionOfExpenses
	|		AND TTOtherExpenses_.Department = TableTypesOfStocks_.ExpenseRecipientDivision
	|		AND TTOtherExpenses_.FinRecordID = TableTypesOfStocks_.FinRecordID
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND &NewProduction
	|	AND TableTypesOfStocks_.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#Region ConductingLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return ProductionCostAllocationLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
// Returns:
//	See ProductionCostAllocationLocalization.RequestTextTTReflectedInLocalAccounting
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ProductionCostAllocationLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "SelectionTask");
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"NewProduction",
														True,
														ComparisonType.Equal);
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfInventoryOfMaterialsAndSemiFinishedProducts") Then
		
		SpreadsheetDocument = CreateInventoryReportOfMaterialsAndSemiFinishedProducts(PrintParameters, PrintObjects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
									PrintFormsCollection, 
									"ActOfInventoryOfMaterialsAndSemiFinishedProducts",
									NStr("vi = 'Biên bản kiểm kê nguyên vật liệu và bán thành phẩm trong xưởng';
										|ru = 'Акт инвентаризации материалов и полуфабрикатов в цехе';
										|en = 'Physical inventory count report for materials and semi-finished products for shop floor'; fa = 'گزارش شمارش فیزیکی موجودی مواد و محصولات نیمه‌ساخته برای کارگاه';
										|it = 'L''atto di inventario di materiali e prodotti semilavorati in officina';
										|pl = 'Protokół inwentaryzacji materiałów i półproduktów w wydziale';
										|tr = 'Üretim atölyesinde malzeme ve yarı mamul fiziksel stok sayımı tutanağı'"),
									SpreadsheetDocument);
	EndIf;
	
EndProcedure

Function CreateInventoryReportOfMaterialsAndSemiFinishedProducts(PrintParameters, PrintObjects)
	
	Query = New Query;
	
	If PrintParameters.Property("NewProduction") Then
		
		Template = PrintManagement.PrintFormTemplate("Document.ProductionCostAllocation.PF_MXL_ActOfInventoryOfMaterialsAndSemiFinishedProducts2_2");
		
		QueryText =
			"SELECT
			|	CAST(Costs.Department AS Catalog.BusinessStructure) AS Department,
			|	CAST(Costs.Products AS Catalog.Products) AS Products,
			|	CAST(Costs.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
			|	Costs.IncomingBalance AS IncomingBalance,
			|	Costs.Existence AS Existence,
			|	Costs.Allocate AS Allocate,
			|	Costs.Allocated AS Allocated,
			|	Costs.LineNumber AS LineNumber
			|INTO Costs
			|FROM
			|	&Costs AS Costs
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	&Organization AS Organization,
			|	CAST(&Organization AS Catalog.Companies).AbbreviatedDescription AS OrganizationPresentation,
			|	Costs.Department AS Department,
			|	CAST(Costs.Department.Description AS STRING(150)) AS DepartmentPresentation,
			|	Costs.Products AS Products,
			|	Costs.Characteristic AS Characteristic,
			|	Costs.Products.UnitOfMeasure AS UnitOfMeasure,
			|	Costs.Products.Presentation AS ProductsPresentation,
			|	Costs.Characteristic.Presentation AS CharacteristicPresentation,
			|	Costs.Products.Code AS ProductsCode,
			|	Costs.Products.SKU AS ProductsSKU,
			|	Costs.IncomingBalance AS IncomingBalance,
			|	Costs.Existence AS Existence,
			|	Costs.Allocate AS Allocate,
			|	Costs.Allocated AS Allocated,
			|	Costs.LineNumber AS LineNumber
			|FROM
			|	Costs AS Costs
			|WHERE
			|	NOT Costs.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
			|
			|ORDER BY
			|	LineNumber
			|TOTALS
			|	MAX(OrganizationPresentation),
			|	MAX(DepartmentPresentation)
			|BY
			|	Department";
		
	Else
		
		Template = PrintManagement.PrintFormTemplate("Document.ProductionCostAllocation.PF_MXL_ActOfInventoryOfMaterialsAndSemiFinishedProducts");
		QueryText =
			"SELECT
			|	CAST(Costs.Department AS Catalog.BusinessStructure) AS Department,
			|	CAST(Costs.Products AS Catalog.Products) AS Products,
			|	CAST(Costs.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
			|	Costs.IsInProcessing + Costs.RealBalance AS AccountingBalance,
			|	Costs.RealBalance AS FactBalanceInStock,
			|	Costs.NotAllocated AS FactRemainingWIP,
			|	Costs.ForAllocation AS ForAllocation,
			|	Costs.LineNumber AS LineNumber
			|INTO Costs
			|FROM
			|	&Costs AS Costs
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	&Organization AS Organization,
			|	CAST(&Organization AS Catalog.Companies).AbbreviatedDescription AS OrganizationPresentation,
			|	Costs.Department AS Department,
			|	CAST(Costs.Department.Presentation AS STRING(150)) AS DepartmentPresentation,
			|	Costs.Products AS Products,
			|	Costs.Characteristic AS Characteristic,
			|	Costs.Products.UnitOfMeasure AS UnitOfMeasure,
			|	Costs.Products.Presentation AS ProductsPresentation,
			|	Costs.Characteristic.Presentation AS CharacteristicPresentation,
			|	Costs.Products.Code AS ProductsCode,
			|	Costs.Products.SKU AS ProductsSKU,
			|	Costs.AccountingBalance AS AccountingBalance,
			|	Costs.FactBalanceInStock AS FactBalanceInStock,
			|	Costs.FactRemainingWIP AS FactRemainingWIP,
			|	Costs.FactBalanceInStock + Costs.FactRemainingWIP AS FactRemainderOfEverything,
			|	Costs.ForAllocation AS ForAllocation,
			|	Costs.LineNumber AS LineNumber
			|FROM
			|	Costs AS Costs
			|WHERE
			|	NOT Costs.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
			|
			|ORDER BY
			|	LineNumber
			|TOTALS
			|	MAX(OrganizationPresentation),
			|	MAX(DepartmentPresentation)
			|BY
			|	Department";
		
	EndIf;
	
	Query.Text = QueryText;
	TableCosts = GetFromTempStorage(PrintParameters.Costs); // ValueTable
	TableCosts.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers(10, 0)));
	
	LineNumber = 1;
	For Each RowData In TableCosts Do
		RowData.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
	EndDo;
	
	Query.SetParameter("Costs", TableCosts);
	Query.SetParameter("Organization", PrintParameters.Organization);
	
	Result = Query.Execute();
	SelectionByDivision = Result.Select(QueryResultIteration.ByGroups);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.LeftMargin = 5;
	SpreadsheetDocument.RightMargin = 5;
	SpreadsheetDocument.HeaderSize = 0;
	SpreadsheetDocument.FooterSize = 0;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ActOfInventoryOfMaterialsAndSemiFinishedProducts";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	HeaderArea_ = Template.GetArea("Title");
	If OutputCodes Then
		Area_TableHeader = Template.GetArea("TableHeader_Code");
		TemplateArea       = Template.GetArea("String_Code");
	Else
		Area_TableHeader = Template.GetArea("TableHeader");
		TemplateArea       = Template.GetArea("String");
	EndIf;
	
	TableBasementArea = Template.GetArea("Footer");
	
	If OutputCodes Then
		Area_TableHeader.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
	EndIf; 
	
	FirstDocument = True;
	
	While SelectionByDivision.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		HeaderParameters = New Structure("OrganizationPresentation,DepartmentPresentation");
		FillPropertyValues(HeaderParameters, SelectionByDivision);
		HeaderParameters.Insert("DocumentDate", Format(EndOfMonth(PrintParameters.Period), "DLF=D"));
		
		HeaderArea_.Parameters.Fill(HeaderParameters);
		
		SpreadsheetDocument.Put(HeaderArea_);

		PageNumber = 1;
		LineNumber = 0;
		
		// Creating an array to check the output
		ArrayOfOutputAreas = New Array;
		
		PrintData = SelectionByDivision.Select();
		While PrintData.Next() Do
			
			LineNumber = LineNumber + 1;
			
			TemplateArea.Parameters.Fill(PrintData);
			
			If LineNumber = 1 Then
				
				SpreadsheetDocument.Put(Area_TableHeader);
				
			Else
			
				ArrayOfOutputAreas.Clear();
				ArrayOfOutputAreas.Add(TemplateArea);
				
				If LineNumber <> 1 And Not SpreadsheetDocument.CheckPut(ArrayOfOutputAreas) Then
					
					PageNumber = PageNumber + 1;
					SpreadsheetDocument.PutHorizontalPageBreak();
					
					SpreadsheetDocument.Put(Area_TableHeader);
					
				EndIf;
				
			EndIf;
			
			// We use the structure to fill in the parameters, because the layout can be changed by the user.
			AdditionalParametersTemplateArea = New Structure;
			AdditionalParametersTemplateArea.Insert("LineNumber", LineNumber);
			If OutputCodes Then
				AdditionalParametersTemplateArea.Insert("SKU", PrintData["Products" + NameOfCodeColumn]);
			EndIf;
			
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			ProductsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
										PrintData.ProductsPresentation, 
										PrintData.CharacteristicPresentation,
										,
										,
										AdditionalParametersProductPresentation);
											
			AdditionalParametersTemplateArea.Insert("ProductsPresentation", ProductsPresentation);
			TemplateArea.Parameters.Fill(AdditionalParametersTemplateArea);
			
			SpreadsheetDocument.Put(TemplateArea);
					
		EndDo;
		
		SpreadsheetDocument.Put(TableBasementArea);
		
		LabelArea = Template.GetArea("Signatures");
		SpreadsheetDocument.Put(LabelArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDivision.Department);
	
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Returns the text of the request for information about the contents of the tabular parts of the document for printing the Task for selecting
// (placing) products.
//
// Returns:
//	String - the text of the request for information about the contents of the tabular parts of the document for printing the Task for selecting (placing) goods.
//
Function TextOfGoodsRequestDocumentForPrintingTaskForSelectingPlacingGoods() Export
	
	RequestText_1 =
	"SELECT
	|	DocumentData.Ref			AS Ref,
	|	1								AS LineNumber,
	|	DocumentData.Warehouse			AS Warehouse,
	|	&Premise						AS Premise,
	|	DocumentData.Products	AS Products,
	|	DocumentData.Characteristic	AS Characteristic,
	|	DocumentData.Series			AS Series
	|INTO DocumentGoods
	|FROM
	|	Document.ProductionCostAllocation AS DocumentData
	|		INNER JOIN Catalog.Products AS Goods
	|		ON DocumentData.Products = Goods.Ref
	|
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND DocumentData.NewProduction
	|	AND NOT Goods.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	RequestText_1 = StrReplace(RequestText_1, "&Premise", "VALUE(Catalog.Warerooms.EmptyRef)");
	
	Return RequestText_1;
	
EndFunction

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.MaterialAndLaborAllocationBase.AddReportCommand(ReportsCommands);
	
	ProductionCostAllocationLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#EndRegion

#Region CreatingHyperlinkInProductionLog

Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not AccessRight("Update", Metadata.Documents.ProductionCostAllocation) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text = RequestTextForMaterialsAndWorksInStorerooms(, 1);
	Query.SetParameter("AllRegisteredRecords",             False);
	Query.SetParameter("BeginOfPeriod",  	     '00010101');
	Query.SetParameter("PeriodEnding",  	     EndOfMonth(CurrentSessionDate()));
	Query.SetParameter("BorderEndOfPeriod_", New Boundary(EndOfMonth(CurrentSessionDate()), BoundaryType.Including));
	Query.SetParameter("AllCompanies",       	 Not ValueIsFilled(Parameters.Organization));
	Query.SetParameter("Companies",       	     Parameters.Organization);
	Query.SetParameter("AllDepartments",  	     Not ValueIsFilled(Parameters.Department));
	Query.SetParameter("Departments",     	     Parameters.Department);
	Query.SetParameter("AllTypesOfProducts",     True);
	Query.SetParameter("ItemsType",         Undefined);
	Query.SetParameter("AllAnalysts",	           True);
	Query.SetParameter("ItemsLocationAttributes",Undefined);
	
	HyperlinkText = NStr("vi = 'Phân bổ chi phí nguyên vật liệu và nhân công';
						|ru = 'Распределение материалов и работ';
						|en = 'Material and labor allocation'; fa = 'تسهیم مواد و دستمزد';
						|it = 'Distribuzione di materiali e lavori';
						|pl = 'Rozdział materiałów i prac';
						|tr = 'Malzeme ve iş dağıtımı'");
	If Query.Execute().IsEmpty() Then
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			"Document.ProductionCostAllocation.Form.MaterialAndLaborAllocationForm");
	Else
		Return New FormattedString(HyperlinkText,,,,
			"Document.ProductionCostAllocation.Form.MaterialAndLaborAllocationForm");
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
