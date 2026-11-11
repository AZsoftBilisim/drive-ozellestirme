//////////////////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "Processing on the side"
// related to the economic operation "Receipt from the processor".
// 
//////////////////////////////////////////////////////////////////////
//

#Region Public

#Region UnifiedMethods

#Region FillType

// Returns the sales condition
//
// Parameters:
//  Terms - CatalogRef.TermsOfSale, Undefined - 
//
// Returns:
//  Undefined -
//
Function GetTermsAndConditionsOfSale(Terms = Undefined) Export

	Return Undefined;

EndFunction

// Returns a list of details that can be used to group orders within a single invoice.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function KeyFieldsOfHeader() Export
	
	KeyFields = "Organization, Partner, Counterparty, Contract, ManufacturedProductsWarehouse, SalesOpportunity,
			|Department, LineOfBusiness, GoodsReceiptOption";
	
	Return KeyFields;
	
EndFunction

// Returns a list of details by which tables are compared when filling in orders/orders
// 
// Returns:
// 	String
//
Function KeyFieldsOfGoodsTable() Export
	
	Return "ReferenceOrder, Products, Characteristic, Purpose, Series";
	
EndFunction

// Returns parameters for filling in the document for refund requests and receipt orders.
//
// Returns:
//	Structure - Parameters for filling in the document.
//
Function DocumentFillingParameters() Export
	
	Return Documents.ReceiptOfGoodsFromCustodian.DocumentFillingParameters();
	
EndFunction

// Initializes parameters populate the document according to the document.
//
// Parameters:
//	FillParameters	 - Structure	 - the fill settings of the default document.
//	HeaderAttributes		 - Structure	 - document data that will be used for filling in parameters.
//	AnArrayOfOrders		 - Array		 - links to applications that will be filled in.
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.AnArrayOfOrders		  = AnArrayOfOrders;
	FillParameters.HeaderAttributes		  = HeaderAttributes;
	FillParameters.Organization			  = HeaderAttributes.Organization;
	FillParameters.BusinessOperation = HeaderAttributes.BusinessOperation;
	FillParameters.Department		  = HeaderAttributes.Department;
	
	If Not ValueIsFilled(FillParameters.Warehouse) Then
		FillParameters.Warehouse = HeaderAttributes.Warehouse;
	EndIf;
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(HeaderAttributes.BusinessOperation);
	FillParameters.KeyFields = Handler.KeyFieldsOfGoodsTable();
	
EndProcedure

// Creates a structure for creating the receipt of goods from the custodian.
//
// Parameters:
//  ReferencesArrray - Array - contains a link to a request for the return of goods from the client
//  OrderProperties_ - Structure - service structure for common mechanisms
//
// Returns:
//  Structure - Details of the header for filling in the receipt of goods from the custodian.
//
Function InvoiceFillingData(ReferencesArrray, Val OrderProperties_ = Undefined) Export
	
	If OrderProperties_ = Undefined Then
		OrderProperties_ = New Structure;
	EndIf;
	
	OrderProperties_.Insert(
		"EconomicOperationOfBillOfLading",
		Enums.BusinessTransactions.ReceiptFromToller2_5);
	
	HeaderAttributes = Documents.ReceiptOfGoodsFromCustodian.InvoiceFillingData(ReferencesArrray, OrderProperties_);
	
	Return HeaderAttributes;
	
EndFunction

#EndRegion

#Region Posting

// Returns parameters for filling in inventory types for the document "Receipt of goods from the custodian".
//
// Parameters:
//  Object - DocumentObject.ReceiptOfGoodsFromCustodian
//
// Returns:
//  See InventoriesServer.ParametersForFillingInventoryTypes
//
Function ParametersForFillingInventoryTypes(Object) Export
	
	Var FillParameters;
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	FillParameters.ReversedDocument = Object.ReversedDocument;
	
	FillParameters.SelectionOfStockTypes_.Organization = Object.Organization;
	
	FillParameters.SelectionOfStockTypes_.InventoryType  = New Array;
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SubcontractorProducts);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	FillParameters.ProductOwnerInHeader = False;
	FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault =
		UserRightsCached.DisableProductTransferControlByTheSubcontractor();
	
	FillParameters.TableOfDetailsOfStockTypesByDefault = TableOfDetailsOfStockTypesByDefault(Object);
	
	Return FillParameters;

EndFunction

// Adds an additional property for monitoring when conducting
// 
// Parameters:
//  Object - DocumentObject.ReceiptOfGoodsFromCustodian - 
//
Procedure AddAdditionalPropertyToControlWhenConducting(Object) Export
	
	Return;
	
EndProcedure

#EndRegion

#Region Rounding

// Fills in the Shopbill and need to Round attributes in the table rows
// 
// Parameters:
//  Object - FormDataStructure - 
//  
Procedure FillInShopPantryAttributeInTable(Object) Export
	
	ProductionServer.FillInShopPantryAttributeInTable(Object.Goods,, Object.Warehouse);
	
EndProcedure

// Recalculates the number of units
//
// Parameters:
//  Object - FormDataStructure - 
//
Procedure RecalculateNumberOfUnits(Object) Export
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	AddActionRecalculateNumberOfUnits(StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
EndProcedure

// Adds the actions "Fill in the sign of the checkbook"
//
// Parameters:
//  StructureOfActions - Structure - 
//  Warehouse - CatalogRef.Warehouses - 
//
Procedure AddFillInActionForShopPantryAttribute(StructureOfActions, Warehouse) Export
	
	StructureOfActions.Insert("FillInShopPantryAttribute", New Structure("WarehouseValue_", Warehouse));
	
EndProcedure

// Adds the action "Recalculate the number of units"
//
// Parameters:
//  StructureOfActions - Structure - 
//
Procedure AddActionRecalculateNumberOfUnits(StructureOfActions) Export
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits());
	
EndProcedure

// Returns the parameters for recalculating the client units
//
// Returns:
//  Structure - See ProductionClientServer.ParametersForRecalculatingNumberOfUnits
//
Function ParametersForRecalculatingNumberOfUnits() Export
	
	Return ProductionClientServer.ParametersForRecalculatingNumberOfUnits();
	
EndFunction

// Returns the parameters for rounding
// 
// Parameters:
//  Warehouse - CatalogRef.Warehouses - 
// 
// Returns:
// 	Structure - the elements contain a structure of rounding parameters:
//   *Goods - See ProductsServer.ParametersForRoundingNumberOfUnitProducts.
//
Function TSParametersForRounding(Warehouse) Export
	
	TSParameters = New Structure;
	
	TSName = "Goods";
	WarehouseFieldName = "Warehouse";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].AdditionalFields.Insert(WarehouseFieldName, "&" + WarehouseFieldName);
	TSParameters[TSName].ConditionForSelectingRowsByAdditionalFields = 
			ProductionServer.ConditionForSelectingRowsForRounding(TSName, WarehouseFieldName);
	TSParameters[TSName].QueryOptions.Insert(WarehouseFieldName, Warehouse);
	
	Return TSParameters;
	
EndFunction

#EndRegion

#Region QueriesTexts

#Region TextsOfRequestsToFillInListOfOrders

// Returns the text of the request for orders available in the invoice.
// 
// Parameters:
//  RequestTextParameters - See TMCommonUse.ParametersOfRequestTextForOrdersInvoices
//
// Returns:
//  String - request text
//
Function QueryTextWaybillOrders(RequestTextParameters) Export
	
	TMCommonUse.AddSelectionItemToCollection(
		RequestTextParameters.Filter,
		"TRUE",
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	Document.SubcontractOrder2_5.ManufacturedProducts AS OutputProductTable
		|WHERE
		|	OutputProductTable.Ref = TableOfOrders.Ref
		|	AND OutputProductTable.Recipient IN HIERARCHY (&Warehouse)
		|
		|UNION ALL
		|
		|SELECT
		|	TRUE
		|FROM
		|	Document.SubcontractOrder2_5.SideAndIntermediateRelease AS TableOfByProducts
		|WHERE
		|	TableOfByProducts.Ref = TableOfOrders.Ref
		|	AND TableOfByProducts.Recipient IN HIERARCHY (&Warehouse)
		|
		|UNION ALL
		|
		|SELECT
		|	TRUE
		|FROM
		|	Document.ProductionStage2_2.ManufacturedProducts AS OutputProductTable
		|WHERE
		|	OutputProductTable.Ref.SubcontractOrder = TableOfOrders.Ref
		|	AND OutputProductTable.Recipient IN HIERARCHY (&Warehouse)
		|
		|UNION ALL
		|
		|SELECT
		|	TRUE
		|FROM
		|	Document.ProductionStage2_2.SideAndIntermediateRelease AS TableOfByProducts
		|WHERE
		|	TableOfByProducts.Ref.SubcontractOrder = TableOfOrders.Ref
		|	AND TableOfByProducts.Recipient IN HIERARCHY (&Warehouse)
		|",
		"In");
	
	Return Documents.SubcontractOrder2_5.RequestTextForOrdersInvoices(RequestTextParameters);
	
EndFunction

// Returns the text of the request for instructions for registration
//
// Returns:
//  String - request text
//
Function QueryTextInstructionsForRegistration() Export

	Return AccumulationRegisters.PurchaseOrders.QueryTextInstructionsForRegistration("ToReceive");

EndFunction

// Returns the text of the request for goods orders for registration
//
// Parameters:
//  TempTableName - String -
//  FilterByDimensions   - Map -
//
// Returns:
//  String - request text
//
Function QueryTextRemnantsOfGoodsForRegistration(TempTableName, FilterByDimensions = Undefined) Export
	
	If FilterByDimensions = Undefined Then
		FilterByDimensions = New Map;
	EndIf;
	
	QueriesTexts = New Array;
	QueriesTexts.Add(
		AccumulationRegisters.PurchaseOrders.QueryTextBalance(
			"BalancesOfSupplierOrders",
			FilterByDimensions,
			"ToReceive > 0"));
	
	QueryText =
	"SELECT ALLOWED
	|	DataOfAccounting.PurchaseOrder AS ReferenceOrder,
	|	DataOfAccounting.Products    AS Products,
	|	DataOfAccounting.Characteristic  AS Characteristic,
	|	DataOfAccounting.RowCode       AS RowCode,
	|	DataOfAccounting.Warehouse           AS Warehouse,
	|	ProductTable.Purpose AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	DataOfAccounting.Ordered        AS Ordered,
	|	DataOfAccounting.ToReceive    AS ToRegister,
	|	DataOfAccounting.Sum           AS Sum
	|INTO TableName
	|FROM
	|	BalancesOfSupplierOrders AS DataOfAccounting
	|	
	|	INNER JOIN Document.SubcontractOrder2_5.ManufacturedProducts AS ProductTable
	|	ON ProductTable.Ref = DataOfAccounting.PurchaseOrder
	|	AND ProductTable.RowCode = DataOfAccounting.RowCode
	|
	|UNION ALL
	|
	|SELECT
	|	DataOfAccounting.PurchaseOrder AS ReferenceOrder,
	|	DataOfAccounting.Products    AS Products,
	|	DataOfAccounting.Characteristic  AS Characteristic,
	|	DataOfAccounting.RowCode       AS RowCode,
	|	DataOfAccounting.Warehouse           AS Warehouse,
	|	ProductTable.Purpose AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	DataOfAccounting.Ordered        AS Ordered,
	|	DataOfAccounting.ToReceive    AS ToRegister,
	|	DataOfAccounting.Sum           AS Sum
	|FROM
	|	BalancesOfSupplierOrders AS DataOfAccounting
	|	
	|	INNER JOIN Document.SubcontractOrder2_5.SideAndIntermediateRelease AS ProductTable
	|	ON ProductTable.Ref = DataOfAccounting.PurchaseOrder
	|	AND ProductTable.RowCode = DataOfAccounting.RowCode
	|
	|UNION ALL
	|
	|SELECT
	|	DataOfAccounting.PurchaseOrder AS ReferenceOrder,
	|	DataOfAccounting.Products    AS Products,
	|	DataOfAccounting.Characteristic  AS Characteristic,
	|	DataOfAccounting.RowCode       AS RowCode,
	|	DataOfAccounting.Warehouse           AS Warehouse,
	|	ProductTable.Purpose AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	DataOfAccounting.Ordered        AS Ordered,
	|	DataOfAccounting.ToReceive    AS ToRegister,
	|	DataOfAccounting.Sum           AS Sum
	|FROM
	|	BalancesOfSupplierOrders AS DataOfAccounting
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|	ON StageDetails.SubcontractOrder = DataOfAccounting.PurchaseOrder
	|	
	|	INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS ProductTable
	|	ON ProductTable.Ref = StageDetails.Ref
	|	AND ProductTable.RowCode = DataOfAccounting.RowCode
	|
	|UNION ALL
	|
	|SELECT
	|	DataOfAccounting.PurchaseOrder AS ReferenceOrder,
	|	DataOfAccounting.Products    AS Products,
	|	DataOfAccounting.Characteristic  AS Characteristic,
	|	DataOfAccounting.RowCode       AS RowCode,
	|	DataOfAccounting.Warehouse           AS Warehouse,
	|	ProductTable.Purpose AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	DataOfAccounting.Ordered        AS Ordered,
	|	DataOfAccounting.ToReceive    AS ToRegister,
	|	DataOfAccounting.Sum           AS Sum
	|FROM
	|	BalancesOfSupplierOrders AS DataOfAccounting
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|	ON StageDetails.SubcontractOrder = DataOfAccounting.PurchaseOrder
	|	
	|	INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS ProductTable
	|	ON ProductTable.Ref = StageDetails.Ref
	|	AND ProductTable.RowCode = DataOfAccounting.RowCode
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|";
	
	QueryText = StrReplace(QueryText, "INTO TableName", "INTO " + TempTableName);
	QueriesTexts.Add(QueryText);
	
	Return StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
EndFunction

#EndRegion

//Returns the text of the request data for input validation based on
//
// Returns:
//  String - 
//
Function QueryTextDataForInputValidationBasedOn() Export
	
	QueriesTexts = New Array;
	QueriesTexts.Add(
	"SELECT ALLOWED
	|	OrderData_2.Basis             AS Basis,
	|	OrderData_2.Status                AS Status,
	|	COUNT(DISTINCT OrderData_2.Warehouse) > 1 AS RegistrationViaRM,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData_2.Warehouse) = 1
	|			THEN MAX(OrderData_2.Warehouse)
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END                                    AS Warehouse,
	|	OrderData_2.BusinessOperation AS BusinessOperation
	|FROM
	|	(SELECT
	|		OrderData_2.Ref                AS Basis,
	|		OrderData_2.GroupCosts     AS GroupCosts,
	|		OrderData_2.Status                AS Status,
	|		ProductTable_.Recipient                AS Warehouse,
	|		OrderData_2.BusinessOperation AS BusinessOperation
	|	FROM
	|		Document.SubcontractOrder2_5 AS OrderData_2
	|		
	|		INNER JOIN Document.SubcontractOrder2_5.ManufacturedProducts AS ProductTable_
	|		ON ProductTable_.Ref = OrderData_2.Ref
	
	|	WHERE
	|		OrderData_2.Ref IN(&References)
	|		AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|		AND NOT ProductTable_.ToExpenseAs
	|		AND NOT ProductTable_.Canceled
	|		AND NOT OrderData_2.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|	UNION ALL
	|
	|	SELECT
	|		OrderData_2.Ref                AS Basis,
	|		OrderData_2.GroupCosts     AS GroupCosts,
	|		OrderData_2.Status                AS Status,
	|		ProductTable_.Recipient                AS Warehouse,
	|		OrderData_2.BusinessOperation AS BusinessOperation
	|	FROM
	|		Document.SubcontractOrder2_5 AS OrderData_2
	|		
	|		INNER JOIN Document.SubcontractOrder2_5.SideAndIntermediateRelease AS ProductTable_
	|		ON ProductTable_.Ref = OrderData_2.Ref
	
	|	WHERE
	|		OrderData_2.Ref IN(&References)
	|		AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|		AND NOT ProductTable_.ToExpenseAs
	|		AND NOT ProductTable_.Canceled
	|		AND NOT OrderData_2.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|	UNION ALL
	|
	|	SELECT
	|		OrderData_2.Ref                AS Basis,
	|		OrderData_2.GroupCosts     AS GroupCosts,
	|		OrderData_2.Status                AS Status,
	|		ProductTable_.Recipient                AS Warehouse,
	|		OrderData_2.BusinessOperation AS BusinessOperation
	|	FROM
	|		Document.SubcontractOrder2_5 AS OrderData_2
	|	
	|		INNER JOIN Document.ProductionStage2_2 AS ProductionStages
	|		ON ProductionStages.SubcontractOrder = OrderData_2.Ref
	|	
	|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS ProductTable_
	|		ON ProductTable_.Ref = ProductionStages.Ref
	|	
	|	WHERE
	|		OrderData_2.Ref IN(&References)
	|		AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|		AND NOT ProductTable_.ToExpenseAs
	|		AND NOT ProductTable_.Canceled
	|		AND OrderData_2.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|	UNION ALL
	|
	|	SELECT
	|		OrderData_2.Ref                AS Basis,
	|		OrderData_2.GroupCosts     AS GroupCosts,
	|		OrderData_2.Status                AS Status,
	|		ProductTable_.Recipient                AS Warehouse,
	|		OrderData_2.BusinessOperation AS BusinessOperation
	|	FROM
	|		Document.SubcontractOrder2_5 AS OrderData_2
	|	
	|		INNER JOIN Document.ProductionStage2_2 AS ProductionStages
	|		ON ProductionStages.SubcontractOrder = OrderData_2.Ref
	|	
	|		INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS ProductTable_
	|		ON ProductTable_.Ref = ProductionStages.Ref
	|	
	|	WHERE
	|		OrderData_2.Ref IN(&References)
	|		AND NOT ProductTable_.ToExpenseAs
	|		AND NOT ProductTable_.Canceled
	|		AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|		AND OrderData_2.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE
	|			WHEN OrderData_2.ByOrders
	|				THEN OrderData_2.SubcontractOrder
	|			ELSE OrderData_2.Ref
	|		END                                    AS Basis,
	|		OrderData_2.GroupCosts     AS GroupCosts,
	|		CASE
	|			WHEN OrderData_2.ByOrders
	|				THEN OrderData_2.SubcontractOrder.Status
	|			ELSE UNDEFINED
	|		END                                    AS Status,
	|		VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|		OrderData_2.BusinessOperation AS BusinessOperation
	|	FROM
	|		Document.SubcontractorReport2_5 AS OrderData_2
	|	WHERE
	|		OrderData_2.Ref IN(&References)
	|	) AS OrderData_2
	|
	|GROUP BY
	|	OrderData_2.Basis,
	|	OrderData_2.Status,
	|	OrderData_2.BusinessOperation
	|");
	
	QueriesTexts.Add(
	"SELECT ALLOWED TOP 1
	|	1
	|FROM
	|	Document.SubcontractOrder2_5.ManufacturedProducts AS ProductTable_
	|WHERE
	|	ProductTable_.Ref IN(&References)
	|	AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT ProductTable_.ToExpenseAs
	|	AND NOT ProductTable_.Canceled
	|	AND NOT ProductTable_.Ref.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	Document.SubcontractOrder2_5.SideAndIntermediateRelease AS ProductTable_
	|WHERE
	|	ProductTable_.Ref IN(&References)
	|	AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT ProductTable_.ToExpenseAs
	|	AND NOT ProductTable_.Canceled
	|	AND NOT ProductTable_.Ref.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	Document.SubcontractorReport2_5 AS ProcessorReports
	|	
	|	INNER JOIN Document.SubcontractOrder2_5.ManufacturedProducts AS ProductTable_
	|	ON ProductTable_.Ref = ProcessorReports.SubcontractOrder
	|
	|WHERE
	|	ProcessorReports.Ref IN(&References)
	|	AND ProcessorReports.ByOrders
	|	AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT ProductTable_.ToExpenseAs
	|	AND NOT ProductTable_.Canceled
	|	AND NOT ProductTable_.Ref.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	Document.SubcontractorReport2_5 AS ProcessorReports
	|	
	|	INNER JOIN Document.SubcontractOrder2_5.SideAndIntermediateRelease AS ProductTable_
	|	ON ProductTable_.Ref = ProcessorReports.SubcontractOrder
	|
	|WHERE
	|	ProcessorReports.Ref IN(&References)
	|	AND ProcessorReports.ByOrders
	|	AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT ProductTable_.ToExpenseAs
	|	AND NOT ProductTable_.Canceled
	|	AND NOT ProductTable_.Ref.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	Document.SubcontractOrder2_5 AS OrderData_2
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS ProductionStages
	|	ON ProductionStages.SubcontractOrder = OrderData_2.Ref
	|	
	|	INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS ProductTable_
	|	ON ProductTable_.Ref = ProductionStages.Ref
	|	
	|WHERE
	|	OrderData_2.Ref IN(&References)
	|	AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT ProductTable_.ToExpenseAs
	|	AND NOT ProductTable_.Canceled
	|	AND OrderData_2.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	Document.SubcontractOrder2_5 AS OrderData_2
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS ProductionStages
	|	ON ProductionStages.SubcontractOrder = OrderData_2.Ref
	|	
	|	INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS ProductTable_
	|	ON ProductTable_.Ref = ProductionStages.Ref
	|	
	|WHERE
	|	OrderData_2.Ref IN(&References)
	|	AND NOT ProductTable_.ToExpenseAs
	|	AND NOT ProductTable_.Canceled
	|	AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|	AND OrderData_2.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	Document.SubcontractorReport2_5 AS ProcessorReports
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS ProductionStages
	|	ON ProductionStages.SubcontractOrder = ProcessorReports.SubcontractOrder
	|	
	|	INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS ProductTable_
	|	ON ProductTable_.Ref = ProductionStages.Ref
	|	
	|WHERE
	|	ProcessorReports.Ref IN(&References)
	|	AND ProcessorReports.ByOrders
	|	AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT ProductTable_.ToExpenseAs
	|	AND NOT ProductTable_.Canceled
	|	AND ProcessorReports.SubcontractOrder.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	Document.SubcontractorReport2_5 AS ProcessorReports
	|	
	|	INNER JOIN Document.ProductionStage2_2 AS ProductionStages
	|	ON ProductionStages.SubcontractOrder = ProcessorReports.SubcontractOrder
	|	
	|	INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS ProductTable_
	|	ON ProductTable_.Ref = ProductionStages.Ref
	|	
	|WHERE
	|	ProcessorReports.Ref IN(&References)
	|	AND ProcessorReports.ByOrders
	|	AND NOT ProductTable_.ToExpenseAs
	|	AND NOT ProductTable_.Canceled
	|	AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|	AND ProcessorReports.SubcontractOrder.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS OrderData_2
	|WHERE
	|	OrderData_2.Ref IN(&References)
	|	AND OrderData_2.RowCode = 0
	|	AND NOT OrderData_2.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT OrderData_2.ToExpenseAs
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS OrderData_2
	|WHERE
	|	OrderData_2.Ref IN(&References)
	|	AND OrderData_2.RowCode = 0
	|	AND NOT OrderData_2.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT OrderData_2.ToExpenseAs
	|");
	
	FilterByDimensions = New Map;
	TMCommonUse.AddSelectionItemToCollection(
		FilterByDimensions,
		"PurchaseOrder",
		"SELECT
		|	OrderData_2.Ref
		|FROM
		|	Document.SubcontractOrder2_5 AS OrderData_2
		|WHERE
		|	OrderData_2.Ref IN(&References)
		|
		|UNION ALL
		|
		|SELECT
		|	OrderData_2.SubcontractOrder
		|FROM
		|	Document.SubcontractorReport2_5 AS OrderData_2
		|WHERE
		|	OrderData_2.Ref IN(&References)
		|	AND OrderData_2.ByOrders
		|",
		"In");
	
	QueriesTexts.Add(
		QueryTextRemnantsOfGoodsForRegistration("TTBalancesForRegistration", FilterByDimensions));
	
	QueriesTexts.Add(
	"SELECT ALLOWED
	|	Set.ReferenceOrder AS InstructionsForRegistration
	|FROM
	|	(SELECT
	|		RequirementsForRegistration_1.ReferenceOrder AS ReferenceOrder
	|	FROM
	|		TTBalancesForRegistration AS RequirementsForRegistration_1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OrderData_2.Ref AS ReferenceOrder
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS OrderData_2
	|	WHERE
	|		OrderData_2.Ref IN(&References)
	|		AND OrderData_2.RowCode = 0
	|		AND NOT OrderData_2.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND NOT OrderData_2.ToExpenseAs
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OrderData_2.Ref AS ReferenceOrder
	|	FROM
	|		Document.SubcontractorReport2_5.SideAndIntermediateRelease AS OrderData_2
	|	WHERE
	|		OrderData_2.Ref IN(&References)
	|		AND OrderData_2.RowCode = 0
	|		AND NOT OrderData_2.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND NOT OrderData_2.ToExpenseAs
	|	) AS Set
	|
	|GROUP BY
	|	Set.ReferenceOrder
	|");
	
	Return StrConcat(QueriesTexts, Common.QueryBatchSeparator());

EndFunction

//Returns the request text invoice filling data
//
// Returns:
//  String - 
//
Function QueryTextInvoiceFillingData() Export
	
	QueryText =
	"SELECT
	|	&BusinessOperation                                 AS BusinessOperation,
	|	OrderDocument.Organization                                      AS Organization,
	|	OrderDocument.Department                                    AS Department,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderDocument.Warehouse) = 1
	|			THEN MAX(OrderDocument.Warehouse)
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END                                                  AS Warehouse,
	|	OrderDocument.SalesOpportunity                                           AS SalesOpportunity,
	|	OrderDocument.Partner                                          AS Partner,
	|	OrderDocument.Counterparty                                       AS Counterparty,
	|	VALUE(Catalog.TermsOfSale.EmptyRef) AS Terms,
	|	OrderDocument.Contract                                          AS Contract,
	|	OrderDocument.LineOfBusiness                          AS LineOfBusiness,
	|	OrderDocument.PriceIncludesVAT                                  AS PriceIncludesVAT,
	|	OrderDocument.Currency                                           AS Currency,
	|	OrderDocument.PriceKind                                          AS PriceKind
	|FROM
	|	(SELECT
	|		OrderDocument.Organization                                      AS Organization,
	|		OrderDocument.Department                                    AS Department,
	|		ProductTable_.Recipient                              AS Warehouse,
	|		OrderDocument.SalesOpportunity                                           AS SalesOpportunity,
	|		OrderDocument.Partner                                          AS Partner,
	|		OrderDocument.Counterparty                                       AS Counterparty,
	|		VALUE(Catalog.TermsOfSale.EmptyRef) AS Terms,
	|		OrderDocument.Contract                                          AS Contract,
	|		OrderDocument.LineOfBusiness                          AS LineOfBusiness,
	|		OrderDocument.PriceIncludesVAT                                  AS PriceIncludesVAT,
	|		OrderDocument.Currency                                           AS Currency,
	|		OrderDocument.PriceKind                                          AS PriceKind
	|	FROM
	|		Document.SubcontractOrder2_5 AS OrderDocument
	|		
	|		INNER JOIN Document.SubcontractOrder2_5.ManufacturedProducts AS ProductTable_
	|		ON ProductTable_.Ref = OrderDocument.Ref
	|		
	|	WHERE
	|		OrderDocument.Ref = &OrderDocument
	|		AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|		AND NOT ProductTable_.Canceled
	|		AND NOT OrderDocument.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OrderDocument.Organization                                      AS Organization,
	|		OrderDocument.Department                                    AS Department,
	|		ProductTable_.Recipient                              AS Warehouse,
	|		OrderDocument.SalesOpportunity                                           AS SalesOpportunity,
	|		OrderDocument.Partner                                          AS Partner,
	|		OrderDocument.Counterparty                                       AS Counterparty,
	|		VALUE(Catalog.TermsOfSale.EmptyRef) AS Terms,
	|		OrderDocument.Contract                                          AS Contract,
	|		OrderDocument.LineOfBusiness                          AS LineOfBusiness,
	|		OrderDocument.PriceIncludesVAT                                  AS PriceIncludesVAT,
	|		OrderDocument.Currency                                           AS Currency,
	|		OrderDocument.PriceKind                                          AS PriceKind
	|	FROM
	|		Document.SubcontractOrder2_5 AS OrderDocument
	|		
	|		INNER JOIN Document.SubcontractOrder2_5.SideAndIntermediateRelease AS ProductTable_
	|		ON ProductTable_.Ref = OrderDocument.Ref
	|		
	|	WHERE
	|		OrderDocument.Ref = &OrderDocument
	|		AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|		AND NOT ProductTable_.Canceled
	|		AND NOT OrderDocument.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OrderDocument.Organization                                      AS Organization,
	|		OrderDocument.Department                                    AS Department,
	|		ProductTable_.Recipient                              AS Warehouse,
	|		OrderDocument.SalesOpportunity                                           AS SalesOpportunity,
	|		OrderDocument.Partner                                          AS Partner,
	|		OrderDocument.Counterparty                                       AS Counterparty,
	|		VALUE(Catalog.TermsOfSale.EmptyRef) AS Terms,
	|		OrderDocument.Contract                                          AS Contract,
	|		OrderDocument.LineOfBusiness                          AS LineOfBusiness,
	|		OrderDocument.PriceIncludesVAT                                  AS PriceIncludesVAT,
	|		OrderDocument.Currency                                           AS Currency,
	|		OrderDocument.PriceKind                                          AS PriceKind
	|	FROM
	|		Document.SubcontractOrder2_5 AS OrderDocument
	|		
	|		INNER JOIN Document.ProductionStage2_2 AS ProductionStage
	|		ON ProductionStage.SubcontractOrder = OrderDocument.Ref
	|		
	|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS ProductTable_
	|		ON ProductTable_.Ref = ProductionStage.Ref
	|		
	|	WHERE
	|		OrderDocument.Ref = &OrderDocument
	|		AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|		AND NOT ProductTable_.Canceled
	|		AND OrderDocument.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OrderDocument.Organization                                      AS Organization,
	|		OrderDocument.Department                                    AS Department,
	|		ProductTable_.Recipient                              AS Warehouse,
	|		OrderDocument.SalesOpportunity                                           AS SalesOpportunity,
	|		OrderDocument.Partner                                          AS Partner,
	|		OrderDocument.Counterparty                                       AS Counterparty,
	|		VALUE(Catalog.TermsOfSale.EmptyRef) AS Terms,
	|		OrderDocument.Contract                                          AS Contract,
	|		OrderDocument.LineOfBusiness                          AS LineOfBusiness,
	|		OrderDocument.PriceIncludesVAT                                  AS PriceIncludesVAT,
	|		OrderDocument.Currency                                           AS Currency,
	|		OrderDocument.PriceKind                                          AS PriceKind
	|	FROM
	|		Document.SubcontractOrder2_5 AS OrderDocument
	|		
	|		INNER JOIN Document.ProductionStage2_2 AS ProductionStage
	|		ON ProductionStage.SubcontractOrder = OrderDocument.Ref
	|		
	|		INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS ProductTable_
	|		ON ProductTable_.Ref = ProductionStage.Ref
	|		
	|	WHERE
	|		OrderDocument.Ref = &OrderDocument
	|		AND VALUETYPE(ProductTable_.Recipient) = TYPE(Catalog.Warehouses)
	|		AND NOT ProductTable_.Canceled
	|		AND OrderDocument.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OrderDocument.Organization                                      AS Organization,
	|		OrderDocument.Department                                    AS Department,
	|		VALUE(Catalog.Warehouses.EmptyRef)               AS Warehouse,
	|		OrderDocument.SalesOpportunity                                           AS SalesOpportunity,
	|		OrderDocument.Partner                                          AS Partner,
	|		OrderDocument.Counterparty                                       AS Counterparty,
	|		VALUE(Catalog.TermsOfSale.EmptyRef) AS Terms,
	|		OrderDocument.Contract                                          AS Contract,
	|		OrderDocument.LineOfBusiness                          AS LineOfBusiness,
	|		OrderDocument.PriceIncludesVAT                                  AS PriceIncludesVAT,
	|		OrderDocument.Currency                                           AS Currency,
	|		OrderDocument.PriceKind                                          AS PriceKind
	|	FROM
	|		Document.SubcontractorReport2_5 AS OrderDocument
	|	WHERE
	|		OrderDocument.Ref = &OrderDocument
	|	) AS OrderDocument
	|
	|GROUP BY
	|	OrderDocument.Organization,
	|	OrderDocument.Department,
	|	OrderDocument.SalesOpportunity,
	|	OrderDocument.Partner,
	|	OrderDocument.Counterparty,
	|	OrderDocument.Contract,
	|	OrderDocument.LineOfBusiness,
	|	OrderDocument.PriceIncludesVAT,
	|	OrderDocument.Currency,
	|	OrderDocument.PriceKind
	|";

	Return QueryText;
	
EndFunction

//Returns the text of the goods request of the order document
//
// Parameters:
//  Filter - Map - 
//  SupplementSeriesTable - Boolean -
//
// Returns:
//  String - Query text
//
Function RequestTextAndOrderDocument(Filter, SupplementSeriesTable = False) Export
	
	QueriesTexts = New Array;
	QueriesTexts.Add(Documents.SubcontractOrder2_5.QueryTextDocumentGoods(Filter, "ManufacturedProducts"));
	QueriesTexts.Add(Documents.SubcontractOrder2_5.QueryTextDocumentGoods(Filter, "SideAndIntermediateRelease"));
	
	Return StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	
EndFunction

//Returns the text of the request for the transferred goods
//
// Returns:
//  String - 
//
Function QueryTextGoodsTransferred() Export
	
	QueryText =
	"SELECT
	|	InvoiceGoods.LineNumber AS LineNumber,
	|	InvoiceGoods.Products AS Products,
	|	InvoiceGoods.Characteristic AS Characteristic,
	|	InvoiceGoods.Series AS Series,
	|	InvoiceGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	InvoiceGoods.Purpose AS Purpose,
	|	InvoiceGoods.CCDNumber AS CCDNumber,
	|	InvoiceGoods.Count AS Count
	|INTO TTGoodsWaybill
	|FROM
	|	&Goods AS InvoiceGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	MIN(TTGoodsWaybill.LineNumber) AS LineNumber,
	|	TTGoodsWaybill.Products,
	|	TTGoodsWaybill.Characteristic,
	|	CASE
	|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
	|			AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|					AND NOT TTSeriesAccountingPolicies.BatchesAccountingInDepositedGoods
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|					AND NOT TTSeriesAccountingPolicies.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|				OR &BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|												VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5))
	|					AND NOT TTSeriesAccountingPolicies.SeriesAccountingOfGoodsTransferredToSubcontractor)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE TTGoodsWaybill.Series
	|	END AS Series,
	|	CASE
	|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
	|			AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|					AND NOT TTSeriesAccountingPolicies.BatchesAccountingInDepositedGoods
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|					AND NOT TTSeriesAccountingPolicies.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|				OR &BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|												VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5))
	|					AND NOT TTSeriesAccountingPolicies.SeriesAccountingOfGoodsTransferredToSubcontractor)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS DifferentSeriesAccounting,
	|	TTGoodsWaybill.Purpose,
	|	TTGoodsWaybill.CCDNumber,
	|	SUM(TTGoodsWaybill.Count) AS Count
	|INTO InvoiceGoods
	|FROM
	|	TTGoodsWaybill AS TTGoodsWaybill
	|		LEFT JOIN Catalog.Products AS TT_Products
	|		ON TTGoodsWaybill.Products = TT_Products.Ref
	|		LEFT JOIN Catalog.ItemKinds AS TTTypesOfNomenclature
	|		ON TT_Products.ProductKind = TTTypesOfNomenclature.Ref
	|		LEFT JOIN Catalog.BatchAccountingPolicies AS TTSeriesAccountingPolicies
	|		ON TTTypesOfNomenclature.BatchAccountingPolicy = TTSeriesAccountingPolicies.Ref
	|	
	|GROUP BY
	|	TTGoodsWaybill.Products,
	|	TTGoodsWaybill.Characteristic,
	|	CASE
	|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
	|			AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|					AND NOT TTSeriesAccountingPolicies.BatchesAccountingInDepositedGoods
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|					AND NOT TTSeriesAccountingPolicies.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|				OR &BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|												VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5))
	|					AND NOT TTSeriesAccountingPolicies.SeriesAccountingOfGoodsTransferredToSubcontractor)
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE TTGoodsWaybill.Series
	|	END,
	|	CASE
	|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
	|			AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|					AND NOT TTSeriesAccountingPolicies.BatchesAccountingInDepositedGoods
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|					AND NOT TTSeriesAccountingPolicies.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|				OR &BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|												VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5))
	|					AND NOT TTSeriesAccountingPolicies.SeriesAccountingOfGoodsTransferredToSubcontractor)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	TTGoodsWaybill.Purpose,
	|	TTGoodsWaybill.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DimensionKeys.Ref AS Ref
	|INTO DimensionKeys
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|WHERE
	|	DimensionKeys.StorageLocation = &Contract
	|
	|INDEX BY
	|	Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	InventoryKinds.Ref AS Ref
	|INTO InventoryKinds
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.SubcontractorProducts),
	|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider))
	|
	|INDEX BY
	|	Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsTransferred.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTransferred.CCDNumber                   AS CCDNumber,
	|	SUM(GoodsTransferred.CountBalance)   AS CountBalance
	|INTO GoodsTransferred
	|FROM
	|	(SELECT
	|		GoodsTransferredBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		GoodsTransferredBalance.CCDNumber                   AS CCDNumber,
	|		GoodsTransferredBalance.CountBalance          AS CountBalance
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(&Period, ItemsLocationAttributes IN
	|			(SELECT
	|				DimensionKeys.Ref AS Ref
	|			FROM
	|				DimensionKeys AS DimensionKeys)
	|			AND Organization = &Organization
	|			AND InventoryOwnerAttribute IN
	|			(SELECT
	|				InventoryKinds.Ref AS Ref
	|			FROM
	|				InventoryKinds AS InventoryKinds)) AS GoodsTransferredBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTransferredToRegistrar.ItemsLocationAttributes,
	|		GoodsTransferredToRegistrar.CCDNumber,
	|		GoodsTransferredToRegistrar.Count
	|	FROM
	|		AccumulationRegister.CompanyGoods AS GoodsTransferredToRegistrar
	|	WHERE
	|		GoodsTransferredToRegistrar.Recorder = &Recorder
	|		AND GoodsTransferredToRegistrar.Active
	|		AND ItemsLocationAttributes IN
	|			(SELECT
	|				DimensionKeys.Ref AS Ref
	|			FROM
	|				DimensionKeys AS DimensionKeys)
	|		AND Organization = &Organization
	|		AND InventoryOwnerAttribute IN
	|			(SELECT
	|				InventoryKinds.Ref AS Ref
	|			FROM
	|				InventoryKinds AS InventoryKinds)) AS GoodsTransferred
	|	
	|GROUP BY
	|	GoodsTransferred.ItemsLocationAttributes,
	|	GoodsTransferred.CCDNumber
	|	
	|HAVING
	|	SUM(GoodsTransferred.CountBalance) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DimensionKeys.Products                   AS Products,
	|	DimensionKeys.Characteristic                 AS Characteristic,
	|	CASE
	|		WHEN Goods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE DimensionKeys.Purpose
	|	END                                         AS Purpose,
	|	DimensionKeys.Series                          AS Series,
	|	GoodsTransferred.CCDNumber                     AS CCDNumber,
	|	GoodsTransferred.CCDNumber.OriginCountry AS OriginCountry,
	|	SUM(GoodsTransferred.CountBalance)     AS CountBalance
	|INTO GoodsTransferredGrouping
	|FROM
	|	GoodsTransferred AS GoodsTransferred
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON GoodsTransferred.ItemsLocationAttributes = DimensionKeys.Ref
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON DimensionKeys.Products = Goods.Ref
	|GROUP BY
	|	DimensionKeys.Products,
	|	DimensionKeys.Characteristic,
	|	CASE
	|		WHEN Goods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE DimensionKeys.Purpose
	|	END,
	|	DimensionKeys.Series,
	|	GoodsTransferred.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTransferredGrouping.Products AS Products,
	|	GoodsTransferredGrouping.Characteristic AS Characteristic,
	|	GoodsTransferredGrouping.Purpose AS Purpose,
	|	GoodsTransferredGrouping.Series AS Series,
	|	ISNULL(InvoiceGoods.DifferentSeriesAccounting, FALSE) AS DifferentSeriesAccounting,
	|	GoodsTransferredGrouping.CCDNumber AS CCDNumber,
	|	GoodsTransferredGrouping.OriginCountry AS OriginCountry,
	|	GoodsTransferredGrouping.CountBalance AS CountBalance,
	|	GoodsTransferredGrouping.CountBalance - ISNULL(InvoiceGoods.Count, 0) AS LeftToSelect,
	|	ISNULL(InvoiceGoods.Count, 0) AS QuantityIsSelected,
	|	ISNULL(InvoiceGoods.Count, 0) AS QuantityInInvoice
	|
	|FROM
	|	GoodsTransferredGrouping AS GoodsTransferredGrouping
	|		LEFT JOIN InvoiceGoods AS InvoiceGoods
	|		ON GoodsTransferredGrouping.Products = InvoiceGoods.Products
	|		AND GoodsTransferredGrouping.Characteristic = InvoiceGoods.Characteristic
	|		AND GoodsTransferredGrouping.Purpose = InvoiceGoods.Purpose
	|		AND GoodsTransferredGrouping.Series = InvoiceGoods.Series
	|		AND GoodsTransferredGrouping.CCDNumber = InvoiceGoods.CCDNumber
	|
	|ORDER BY
	|	ISNULL(InvoiceGoods.LineNumber, 99999),
	|	GoodsTransferredGrouping.Products,
	|	GoodsTransferredGrouping.Characteristic,
	|	GoodsTransferredGrouping.Purpose,
	|	GoodsTransferredGrouping.Series
	|";
	
	Return QueryText;
	
	
EndFunction

#EndRegion

#Region ReferenceOrder

// Returns an array of order types
//
// Returns:
//  Array of Type -
//
Function TypesOfProducts_() Export
	
	TypesArray = New Array;
	TypesArray.Add(Type("DocumentRef.SubcontractOrder2_5"));
	
	Return TypesArray;
	
EndFunction

// Returns the name of the order register
//
// Returns:
//  String - 
//
Function RegisterNameOrder() Export
	
	Return "PurchaseOrders";
	
EndFunction

// Returns the name of the dimension of the remainder register that is used as an order
//
// Returns:
//  String - 
//
Function NameDimensionOrder() Export
	
	Return "PurchaseOrder";
	
EndFunction

// Returns the use of string code attribute
//
// Returns:
//  Boolean - 
//
Function UseLineCode() Export
	
	Return True;
	
EndFunction

// Returns the synonym of the order.
//
// Returns:
//  String - synonym of the order.
//
Function SynonymForOrder() Export
	
	Return NStr("vi = 'Đơn đặt hàng gia công';
				|ru = 'Заказ переработчику';
				|en = 'Subcontracting purchase order'; fa = 'سفارش خرید پیمانکاری فرعی';
				|it = 'Ordine al subfornitore';
				|pl = 'Zamówienie do przetwórcy';
				|tr = 'Fason satın alma siparişi'");
	
EndFunction

#EndRegion

#Region DiscrepancyCertificate

// Returns the type of the basis of the act of discrepancy
//
// Returns:
//  EnumRef.TypesOfBaseDocumentsForDiscrepancyReport
//
Function TypeOfBasisOfAct() Export
	
	Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor;
	
EndFunction

// Returns the postfix of the name of the discrepancy report
//
// Returns:
//  String - 
//
Function ActNamePostfix() Export
	
	Return NStr("vi = 'sau khi tiếp nhận từ người nhận gia công';
				|ru = 'после поступления от переработчика';
				|en = 'after ""Goods receipt — Subcontracting services received""'; fa = 'after ""Goods receipt — Subcontracting services received""';
				|it = 'dopo la ricezione dall''elaboratore';
				|pl = 'po wpływie od przetwórcy';
				|tr = 'fason üreticiden giriş sonrasında'");
	
EndFunction

// Returns the title of the discrepancy report form when creating
//
// Returns:
//  String - 
//
Function TitleOfReportCreationForm() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận nguyên liệu từ người nhận gia công (Tạo mới)';
				|ru = 'Акт о расхождениях после поступления от переработчика (Создание)';
				|en = 'Discrepancy report following ""Goods receipt — Subcontracting services received"" (Create)'; fa = 'Discrepancy report following ""Goods receipt — Subcontracting services received"" (Create)';
				|it = 'Atto sulle discrepanze dopo la ricezione dall''elaboratore (Creazione)';
				|pl = 'Protokół o odchyleniach po wpływie od przetwórcy (Tworzenie)';
				|tr = 'Fason üreticiden alınan stok farkları raporu (Oluşturma)'");
	
EndFunction

// Returns the title of the discrepancy report form
//
// Returns:
//  String - 
//
Function ReportFormHeader() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận từ gia công';
				|ru = 'Акт о расхождениях после поступления от переработчика';
				|en = 'Discrepancy report following ""Goods receipt — Subcontracting services received""'; fa = 'Discrepancy report following ""Goods receipt — Subcontracting services received""';
				|it = 'Atto sulle discrepanze dopo la ricezione dall''elaboratore';
				|pl = 'Protokół o odchyleniach po otrzymaniu od przetwórcy';
				|tr = 'Fason üreticiden alınan stok farkları raporu'");
	
EndFunction

// Returns the hint of the agreement of the act of discrepancy
//
// Returns:
//  String - 
//
Function ReportAgreementHint() Export
	
	Return NStr("vi = 'Hợp đồng mà có lập chứng từ tiếp nhận';
				|ru = 'Договор, в рамках которого оформлено поступление';
				|en = 'Contract under which the receiving is registered'; fa = 'Contract under which the receiving is registered';
				|it = 'Accordo in base al quale è stata formalizzata la ricezione';
				|pl = 'Umowa, w której wydano zezwolenie';
				|tr = 'Girişin düzenlenmesi kapsamındaki sözleşme'");
	
EndFunction

// Returns a hint of the agreement of the act of discrepancy
//
// Returns:
//  String - 
//
Function ActAgreementHint() Export
	
	Return "";
	
EndFunction

// Returns the title of the document base
//
// Returns:
//  String - 
//
Function TitleOfDocumentGroundsOfAct() Export
	
	Return NStr("vi = 'Tiếp nhận từ người nhận gia công';
				|ru = 'Поступление от переработчика';
				|en = 'Goods receipt — External subcontracting'; fa = 'رسید انبار — پیمانکاری فرعی خارجی';
				|it = 'Ricezione dal subfornitore';
				|pl = 'Wpływ od przetwórcy';
				|tr = 'Fason üretici gelen ürünleri teslim alma'");
	
EndFunction

// Returns the title based on
//
// Parameters:
//  AddPartner - Boolean -
//
// Returns:
//  String - 
//
Function HeadlineOnGrounds(AddPartner = True) Export
	
	If AddPartner Then
		Return NStr("vi = 'Theo tiếp nhận từ bên nhận gia công';
					|ru = 'По поступлениям от переработчика';
					|en = 'By Goods receipts — Subcontracting services received'; fa = 'By Goods receipts — Subcontracting services received';
					|it = 'Per ricezione dall''elaboratore';
					|pl = 'Po wpływach od przetwórców';
					|tr = 'Fason üreticiden girişe göre'");
	Else
		Return NStr("vi = 'Theo tiếp nhận';
					|ru = 'По поступлениям';
					|en = 'By receipts'; fa = 'بر اساس دریافت‌ها';
					|it = 'Secondo gli arrivi';
					|pl = 'Wg wpływów';
					|tr = 'Girişe göre'");
	EndIf;
	
EndFunction

//Returns a description of the field with comments
//
// Returns:
//  String - 
//
Function BasementVendorComment() Export
	
	Return NStr("vi = 'Ghi chú của bên nhận gia công về chênh lệch tại dòng';
				|ru = 'Комментарии переработчика по расхождениям в строке';
				|en = 'Subcontractor comments on line discrepancies'; fa = 'Subcontractor comments on line discrepancies';
				|it = 'Commento dell''elaboratore per le discrepanze nella riga';
				|pl = 'Uwagi przetwórcy odnośnie do odchylenia w wierszu';
				|tr = 'Satırdaki tutarsızlıklara ilişkin fason üretici yorumları'");
	
EndFunction

//Returns the name of the column, who gives the comment
//
// Returns:
//  String - 
//
Function CustomerComment() Export
	
	Return NStr("vi = 'bên nhận gia công';
				|ru = 'переработчика';
				|en = 'subcontractor'; fa = 'subcontractor';
				|it = 'elaboratore';
				|pl = 'subcontractor';
				|tr = 'fason üretici'");
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business operation of the document.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function BusinessOperation() Export
	
	Return Enums.BusinessTransactions.ReceiptFromToller2_5;
	
EndFunction

// Returns the business transaction of the contract See ProcessingByThirdParties.ContractBusinessTransaction.
//
// Returns:
//  See ProcessingByThirdParties.ContractBusinessTransaction
// 
Function ContractBusinessTransaction() Export
	
	Return ProcessingByThirdParties.ContractBusinessTransaction();
	
EndFunction

#EndRegion

#Region FunctionalOptions

// Returns a sign of the applicability of agreements with suppliers
//
// Returns:
//  Boolean - 
//
Function AgreementsWithSuppliersAreApplicable() Export
	
	Return ProcessingByThirdParties.AgreementsWithSuppliersAreApplicable();
	
EndFunction

// Returns a sign of the applicability of agreements with clients
//
// Returns:
//  Boolean - 
//
Function CustomerAgreementsAreApplicable() Export
	
	Return ProcessingByThirdParties.CustomerAgreementsAreApplicable();
	
EndFunction

// Returns the use of agreements with clients attribute
//
// Returns:
//  Boolean -
//
Function ToUseTermsOfSales() Export
	
	Return ProcessingByThirdParties.ToUseTermsOfSales();

EndFunction

// Returns the use of a request for the return of goods from customers attribute
//
// Returns:
//  Boolean -
//
Function UseOrders() Export
	
	Return GetFunctionalOption("UseSubcontractOrders2_5");

EndFunction

// Returns the attribute using receipts for multiple orders.
//
// Returns:
//  Boolean -
//
Function UseReceiptForMultipleOrders() Export

	Return True;

EndFunction

// Returns the attribute using the advanced features of the customer's order
//
// Returns:
//  Boolean -
//
Function UseAdvancedFeaturesOfSalesOrder() Export
	
	Return True;
	
EndFunction

#EndRegion

#Region Form

//Gets the default contract.
//
// Parameters:
//  Object - FormDataStructure, DocumentObject - 
//  CurrencySelection_2 - Boolean - 
//  FilterByLineOfBusiness - Boolean - 
//
// Returns:
//  CatalogRef.CounterpartyContracts - 
//
Function GetDefaultContract(Object, CurrencySelection_2 = True, FilterByLineOfBusiness = True) Export
	
	Return ProcessingByThirdParties.GetDefaultContract(Object);
	
EndFunction

// Sets the availability of the contract element.
//
// Parameters:
//  Form - ClientApplicationForm -
//  Object - FormDataStructure -
//  Contract - CatalogRef.CounterpartyContracts, Undefined -
//
Procedure SetContractAvailability(Form, Object, Contract = Undefined) Export
	
	ProcessingByThirdParties.SetContractAvailability(Form, Object, Contract);
	
EndProcedure

// Adjusts the form.
//
// Parameters:
//  Form - ClientApplicationForm - Contains:
//           * Items - FormAllItems - Contains:
//              ** Partner - TextBox - Contains:
//                  *** Title - String -
//              ** GoodsSelectTransferredGoods - FormCommand - Contains:
//                  *** Title - String -
//              ** CloseRequest - FormCommand - Contains:
//                  *** Title - String -
//  Number - Number - 
//  Date  - Date - 
//
Procedure CustomizeForm(Form, Number, Date) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	
	Form.AutoTitle = False;
	Form.Title     = DocumentFormHeader(Not ValueIsFilled(Parameters.Key), Number, Date);
	
	Form.HeaderOfSubmittedProductSelectionForm = NStr("vi = 'Chọn sản phẩm do người nhận gia công sản xuất';
														|ru = 'Подбор продукции, произведенной переработчиком';
														|en = 'Pick products produced by subcontractor'; fa = 'Pick products produced by subcontractor';
														|it = 'Selezione di produzione prodotta dall''elaboratore';
														|pl = 'Wybór produkcji, wyprodukowanej przez przetwórców';
														|tr = 'Fason üretici tarafından üretilen ürünlerin seçimi'");
	
	Items.Partner.Title                         = NStr("vi = 'Bên nhận gia công';
														|ru = 'Переработчик';
														|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
														|it = 'Subfornitore';
														|pl = 'Subcontractor';
														|tr = 'Fason üretici'");
	
	Items.GoodsSelectTransferredGoods.Title = NStr("vi = 'Chọn thành phẩm của người nhận gia công';
													|ru = 'Подобрать продукцию переработчика';
													|en = 'Pick subcontractor products'; fa = 'Pick subcontractor products';
													|it = 'Selezionare produzione dell''elaboratore';
													|pl = 'Wybierz produkcję przetwórcy';
													|tr = 'Fason üreticinin imal edilen ürünlerini seç'");
	Items.PagesOrder.Visible                   = True;
	Items.ByReference.Title                  = NStr("vi = 'Theo đơn hàng';
													|ru = 'По заказу';
													|en = 'Against order'; fa = 'در مقابل سفارش';
													|it = 'Per ordine';
													|pl = 'Wg umowy';
													|tr = 'Siparişe göre'");
	Items.ByReferences.Title                 = NStr("vi = 'Theo đơn hàng';
													|ru = 'По заказам';
													|en = 'Order for prepayment and invoice'; fa = 'سفارش برای پیش‌پرداخت و فاکتور';
													|it = 'Per ordini';
													|pl = 'Wg zamówień';
													|tr = 'Siparişlere göre'");
	Items.CloseRequest.Title                   = NStr("vi = 'Đóng đơn hàng';
														|ru = 'Закрыть заказ';
														|en = 'Close order'; fa = 'بستن سفارش';
														|it = 'Chiudi l''ordine';
														|pl = 'Zamknij zamówienie';
														|tr = 'Emri kapat'");
	Items.CloseApplications.Title                   = NStr("vi = 'Đóng đơn hàng';
															|ru = 'Закрыть заказы';
															|en = 'Close orders'; fa = 'بستن سفارش‌ها';
															|it = 'Chiudi gli ordini';
															|pl = 'Zamknij zamówienia';
															|tr = 'Emirleri kapat'");
	
	Items.Terms.Visible = ToUseTermsOfSales();
	
	Items.PriceKind.Visible                      = False;
	Items.GoodsSetIndex.Visible           = False;
	Items.GoodsGroupSet.Visible            = False;
	Items.GoodsPrice.Visible                   = False;
	Items.GoodsSum.Visible                  = False;
	Items.GoodsFillInPricesByPriceKind.Visible = False;
	Items.GroupInTotal.Visible                  = False;
	Items.GoodsSetComposition.Visible           = False;
	Items.GoodsFillInCCDNumbers.Visible     = False;
	Items.ReusablePackageReturn.Visible = False;
	Items.GoodsAddReusablePackage.Visible  = False;
	
	Items.GoodsFillInPricesUnderAgreement.Visible = False;
	
EndProcedure

// Configures the parameters of the selection and the relationship of the parameters of the selection of the details of the form.
//
// Parameters:
//  Form  - ClientApplicationForm -
//  Object - FormDataStructure -
//
Procedure AdjustItemSelectionSettings(Form, Object) Export
	
	ProcessingByThirdParties.AdjustItemSelectionSettings(Form, Object);
	
	Items = Form.Items;
	
	// Type of price
	If Not Items.Find("PriceKind") = Undefined Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.UseForIssuingProductsWorksAndServicesAtFixedCost", True));
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.StatusesOfPriceTypeValidity.Valid));
		
		Items.PriceKind.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	EndIf;
	
EndProcedure

// Returns the title of the document form transfer of goods to the custodian.
//
// Parameters:
//  NewDocument - Boolean - 
//  Number - Number - 
//  Date - Date - 
//
// Returns:
//  String - 
//
Function DocumentFormHeader(NewDocument, Number, Date) Export
	
	If NewDocument Then
		Title = StrTemplate(NStr("vi = '%1 (tạo mới)';
								|ru = '%1 (создание)';
								|en = '%1 (Create)'; fa = '%1 (Create)';
								|it = '%1 (creazione)';
								|pl = '%1 (utworzenie)';
								|tr = '%1 (oluşturma)'"), ObjectPresentation());
	Else
		Title = StrTemplate(NStr("vi = '%1 %2 ngày %3';
								|ru = '%1 %2 от %3';
								|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
								|it = '%1 %2 del %3';
								|pl = '%1 %2 z dnia %3';
								|tr = '%3 tarihli %1 %2'"), ObjectPresentation(), Number, Date);
	EndIf;
	
	Return Title;
	
EndFunction

// Returns a representation of the document receipt of goods from the custodian.
//
// Returns:
//  String - 
//
Function ObjectPresentation() Export
	
	Return NStr("vi = 'Tiếp nhận từ người nhận gia công';
				|ru = 'Поступление от переработчика';
				|en = 'Goods receipt — External subcontracting'; fa = 'رسید انبار — پیمانکاری فرعی خارجی';
				|it = 'Ricezione dal subfornitore';
				|pl = 'Wpływ od przetwórcy';
				|tr = 'Fason üreticiden gelen ürünleri teslim alma'");
	
EndFunction

#EndRegion

#Region CreatingHyperlinkInJournal

// Returns the hyperlink text for the transition from the document log to the design workspace.
//
// Parameters:
//  Parameters - Structure - parameters for forming the hyperlink text.
//
// Returns:
//  FormattedString - the text of the hyperlink of the transition to the workplace of the registration of transfers.
//
Function CreateHyperlinkToDesign(Parameters) Export
	
	HaveReadRights = AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
	
	If Not HaveReadRights Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Tiếp nhận thành phẩm';
						|ru = 'Поступление продукции';
						|en = 'Product receipt'; fa = 'رسید محصول';
						|it = 'Prodotti in arrivo';
						|pl = 'Wpływ produkcji';
						|tr = 'İmal edilen ürün girişi'");
	HyperlinkAnchorText = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices/PageReceipts";
	
	ThereAreDocumentsForRegistration =
		DataProcessors.DocumentsOfTransferToTollingAll2_5.ThereAreDocumentsForRegistration(
			Parameters,
			Enums.BusinessTransactions.ReceiptFromToller2_5);
	
	ColorOfHyperlink = ?(ThereAreDocumentsForRegistration, Undefined, StyleColors.EmptyTableField);
	
	Return New FormattedString(HyperlinkText,, ColorOfHyperlink,, HyperlinkAnchorText);
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region Private

// Returns a table of details of stock types by default
//
// Parameters:
//  Object - DocumentObject.ReceiptOfGoodsFromCustodian - 
//
// Returns:
//  ValueTable - 
//
Function TableOfDetailsOfStockTypesByDefault(Object)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.LineNumber                AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Purpose                 AS Purpose
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber                    AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes     AS ItemsLocationAttributes,
	|	&Organization                                  AS Organization,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)   AS CCDNumber,
	|	CASE
	|		WHEN CatAssignments.AssignmentType IN (
	|								VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|								VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN CatAssignments.Partner
	|		WHEN TRUE
	|			THEN &Organization
	|	END                                         AS GoodsOwner,
	|	CASE
	|		WHEN CatAssignments.Contract IS NOT NULL
	|			THEN CatAssignments.Contract.Counterparty
	|		WHEN TRUE
	|			THEN VALUE(Catalog.Counterparties.EmptyRef)
	|	END                                         AS Counterparty,
	|	CASE
	|		WHEN CatAssignments.Contract IS NOT NULL
	|			THEN CatAssignments.Contract
	|		WHEN TRUE
	|			THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|	END                                         AS Contract,
	|	CASE
	|		WHEN CatAssignments.AssignmentType IN (
	|								VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|								VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		WHEN TRUE
	|			THEN VALUE(Enum.InventoryTypes.SubcontractorProducts)
	|	END                                         AS InventoryType
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|	
	|	LEFT JOIN Catalog.Assignments AS CatAssignments
	|	ON CatAssignments.Ref = TableOfGoods.Purpose
	|";
	
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter(
		"TableOfGoods", Object.Goods.Unload(, "LineNumber, ItemsLocationAttributes, Purpose"));
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion