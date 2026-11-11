//////////////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "Processing on the side"
// related to the economic operation "Return from the processor".
// 
//////////////////////////////////////////////////////////////////
//

#Region Public

#Region UnifiedMethods

#Region FillType

// Returns the sales condition
//
// Parameters:
//  Terms - CatalogRef.TermsOfSale - 
//
// Returns:
//  See SalesServer.GetTermsAndConditionsOfSale
//
Function GetTermsAndConditionsOfSale(Terms) Export

	Return SalesServer.GetTermsAndConditionsOfSale(Terms);

EndFunction

// Returns a list of details by which tables are compared when filling in orders/orders
// 
// Returns:
// 	String
//
Function KeyFieldsOfGoodsTable() Export
	
	Return "ReferenceOrder, Products, Characteristic, Purpose";
	
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
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
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
//  Object - FormDataStructure - table being processed
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
//   *Goods - See ProductsServer.ParametersForRoundingNumberOfUnitProducts
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

// Returns the text of the request for goods orders for registration
//
// Parameters:
//  TempTableName - String -
//  FilterByDimensions   - Map, Undefined -
//
// Returns:
//  String - request text
//
Function QueryTextRemnantsOfGoodsForRegistration(TempTableName, FilterByDimensions = Undefined) Export
	
	If FilterByDimensions = Undefined Then
		FilterByDimensions = New Map;
	EndIf;
	
	// Orders for the return from the processor are not kept in the System
	TMCommonUse.AddSelectionItemToCollection(
		FilterByDimensions,
		"TRUE",
		"FALSE",
		"=");
	
	QueryText =
		AccumulationRegisters.PurchaseOrders.QueryTextBalance(
			TempTableName,
			FilterByDimensions);
	
	QueryText = RequestSchemes.AddSelectionFieldToQuery(QueryText, "UNDEFINED", "Purpose");
	QueryText = RequestSchemes.AddSelectionFieldToQuery(QueryText, "UNDEFINED", "Series");
	
	QueryText = RequestSchemes.ChangeAliasOfSelectionFieldInRequest(QueryText, "PurchaseOrder", "ReferenceOrder");
	QueryText = RequestSchemes.ChangeAliasOfSelectionFieldInRequest(QueryText, "ToReceive", "ToRegister");
	
	Return QueryText;
	
EndFunction

#EndRegion

//Returns the text of the request data for input validation based on
//
// Returns:
//  String - 
//
Function QueryTextDataForInputValidationBasedOn() Export
	
	QueriesTexts = New Array;
	
	QueryText =
	"SELECT ALLOWED
	|	OrderData_2.Ref                AS Basis,
	|	UNDEFINED                             AS Status,
	|	FALSE                                     AS RegistrationViaRM,
	|	CASE
	|		WHEN OrderData_2.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE OrderData_2.Warehouse
	|	END                                    AS Warehouse,
	|	OrderData_2.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.TransferOfGoodsToBailee AS OrderData_2
	|WHERE
	|	OrderData_2.Ref IN(&References)
	|
	|UNION ALL
	|
	|SELECT
	|	OrderData_2.Ref                AS Basis,
	|	OrderData_2.Status                AS Status,
	|	FALSE                                     AS RegistrationViaRM,
	|	CASE
	|		WHEN OrderData_2.MaterialsWarehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE OrderData_2.MaterialsWarehouse
	|	END                                    AS Warehouse,
	|	OrderData_2.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.SubcontractOrder2_5 AS OrderData_2
	|WHERE
	|	OrderData_2.Ref IN(&References)
	|";
	
	QueriesTexts.Add(QueryText);
	
	QueryText =
	"SELECT ALLOWED TOP 1
	|	1
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS Products_From_Orders
	|WHERE
	|	Products_From_Orders.Ref IN(&References)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	Document.SubcontractOrder2_5 AS Products_From_Orders
	|WHERE
	|	Products_From_Orders.Ref IN(&References)
	|";
	
	QueriesTexts.Add(QueryText);
	
	QueryText =
	"SELECT ALLOWED
	|	DocumentTable.Ref AS ReferenceOrder,
	|	DocumentTable.Warehouse AS Warehouse
	|INTO TTBalancesForRegistration
	|FROM
	|	Document.TransferOfGoodsToBailee AS DocumentTable
	|WHERE
	|	FALSE
	|";
	
	QueriesTexts.Add(QueryText);
	
	QueryText =
	"SELECT ALLOWED
	|	Set.ReferenceOrder                    AS InstructionsForRegistration,
	|	COUNT(DISTINCT Set.Warehouse) > 1 AS DifferentWarehouses
	|FROM
	|	(SELECT
	|		RequirementsForRegistration_1.ReferenceOrder AS ReferenceOrder,
	|		RequirementsForRegistration_1.Warehouse        AS Warehouse
	|	FROM
	|		TTBalancesForRegistration AS RequirementsForRegistration_1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentTable.Ref AS ReferenceOrder,
	|		CASE
	|			WHEN DocumentTable.Warehouse.IsFolder
	|				THEN VALUE(Catalog.Warehouses.EmptyRef)
	|			ELSE DocumentTable.Warehouse
	|		END                   AS Warehouse
	|	FROM
	|		Document.TransferOfGoodsToBailee AS DocumentTable
	|	WHERE
	|		DocumentTable.Ref IN (&References)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentTable.Ref AS ReferenceOrder,
	|		CASE
	|			WHEN DocumentTable.MaterialsWarehouse.IsFolder
	|				THEN VALUE(Catalog.Warehouses.EmptyRef)
	|			ELSE DocumentTable.MaterialsWarehouse
	|		END                         AS Warehouse
	|	FROM
	|		Document.SubcontractOrder2_5 AS DocumentTable
	|	WHERE
	|		DocumentTable.Ref IN (&References)
	|	) AS Set
	|
	|GROUP BY
	|	Set.ReferenceOrder
	|";
	
	QueriesTexts.Add(QueryText);
	
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
	|	&BusinessOperation                  AS BusinessOperation,
	|	Transfer_.Ref.Organization             AS Organization,
	|	Transfer_.Ref.Department           AS Department,
	|	CASE
	|		WHEN Transfer_.Ref.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE Transfer_.Ref.Warehouse.IsFolder
	|	END                            AS Warehouse,
	|	Transfer_.Ref.SalesOpportunity                  AS SalesOpportunity,
	|	Transfer_.Ref.Partner                 AS Partner,
	|	Transfer_.Ref.Counterparty              AS Counterparty,
	|	Transfer_.Ref.Terms              AS Terms,
	|	Transfer_.Ref.Contract                 AS Contract,
	|	Transfer_.Ref.LineOfBusiness AS LineOfBusiness,
	|	Transfer_.Ref.Currency                  AS Currency,
	|	CASE
	|		WHEN COUNT(DISTINCT Transfer_.PriceKind) = 1
	|			THEN MAX(Transfer_.PriceKind)
	|		ELSE VALUE(Catalog.TypesOfPrices.EmptyRef)
	|	END                                           AS PriceKind
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS Transfer_
	|WHERE
	|	Transfer_.Ref = &OrderDocument
	|
	|GROUP BY
	|	Transfer_.Ref
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	&BusinessOperation           AS BusinessOperation,
	|	Transfer_.Organization             AS Organization,
	|	Transfer_.Department           AS Department,
	|	CASE
	|		WHEN Transfer_.MaterialsWarehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE Transfer_.MaterialsWarehouse
	|	END                            AS Warehouse,
	|	Transfer_.SalesOpportunity                  AS SalesOpportunity,
	|	Transfer_.Partner                 AS Partner,
	|	Transfer_.Counterparty              AS Counterparty,
	|	UNDEFINED                     AS Terms,
	|	Transfer_.Contract                 AS Contract,
	|	Transfer_.LineOfBusiness AS LineOfBusiness,
	|	Transfer_.Currency                  AS Currency,
	|	Transfer_.PriceKind                 AS PriceKind
	|FROM
	|	Document.SubcontractOrder2_5 AS Transfer_
	|WHERE
	|	Transfer_.Ref = &OrderDocument
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
	
	QueryText = Documents.SubcontractOrder2_5.QueryTextDocumentGoods(Filter, "SupplyWithMaterialsAndWorks");
	
	Return QueryText;
	
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
	|////////////////////////////////////////////////////////////////////////////////
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
	|	NOT InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.SubcontractorProducts)
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
	
	Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor;
	
EndFunction

// Returns the postfix of the name of the discrepancy report
//
// Returns:
//  String - 
//
Function ActNamePostfix() Export
	
	Return NStr("vi = 'sau khi nhận nguyên liệu trả lại từ người nhận gia công';
				|ru = 'после возврата сырья от переработчика';
				|en = 'after ""Goods return — Subcontracting services received""'; fa = 'after ""Goods return — Subcontracting services received""';
				|it = 'dopo la restituzione delle materie prima dall''elaboratore';
				|pl = 'po zwrocie surowców od przetwórcy';
				|tr = 'fason üretici tarafından hammadde iadesinden sonra'");
	
EndFunction

// Returns the title of the discrepancy report form when creating
//
// Returns:
//  String - 
//
Function TitleOfReportCreationForm() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi nhận nguyên liệu trả lại từ người nhận gia công (Tạo mới)';
				|ru = 'Акт о расхождениях после возврата сырья от переработчика (Создание)';
				|en = 'Discrepancy report following ""Goods return — Subcontracting services received"" (Create)'; fa = 'Discrepancy report following ""Goods return — Subcontracting services received"" (Create)';
				|it = 'Atto sulle discrepanze in seguito alla restituzione delle materie prime da parte dell''elaboratore (Creazione)';
				|pl = 'Protokół o odchyleniach po zwrocie surowców od przetwórcy (Tworzenie)';
				|tr = 'Fason üreticiden hammadde iadesinden sonraki tutarsızlık raporu (Oluşturma)'");
	
EndFunction

// Returns the title of the discrepancy report form
//
// Returns:
//  String - 
//
Function ReportFormHeader() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi nhận nguyên liệu trả lại từ người nhận gia công';
				|ru = 'Акт о расхождениях после возврата сырья от переработчика';
				|en = 'Discrepancy report following ""Goods return — Subcontracting services received""'; fa = 'Discrepancy report following ""Goods return — Subcontracting services received""';
				|it = 'Atto sulle discrepanze in seguito alla restituzione delle materie prime da parte dell''elaboratore';
				|pl = 'Protokół o odchyleniach po zwrocie surowców od przetwórcy';
				|tr = 'Fason üretici hammadde iadesinden sonraki tutarsızlık raporu'");
	
EndFunction

// Returns the hint of the agreement of the act of discrepancy
//
// Returns:
//  String - 
//
Function ReportAgreementHint() Export
	
	Return NStr("vi = 'Hợp đồng mà có lập chứng từ trả lại';
				|ru = 'Договор, в рамках которого оформлен возврат';
				|en = 'Contract under which the return is recorded'; fa = 'قراردادی که برگشت تحت آن ثبت می‌شود';
				|it = 'Il contratto in base al quale è stato formalizzato il reso';
				|pl = 'Kontrakt, w ramach którego sporządzony jest zwrot';
				|tr = 'İadenin düzenlenmesi kapsamındaki sözleşme'");
	
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
	
	Return NStr("vi = 'Nhận hàng gia công bị trả lại';
				|ru = 'Возврат от переработчика';
				|en = 'Materials pick-up from subcontractor'; fa = 'تحویل‌گیری مواد از پیمانکار فرعی';
				|it = 'Restituzione da subfornitore';
				|pl = 'Zwrot od przetwórcy';
				|tr = 'Malzemelerin fason üreticiden geri alınması'");
	
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
		Return NStr("vi = 'Khi nhận trả lại từ người nhận gia công';
					|ru = 'По возвратам от переработчика';
					|en = 'By picking up materials from subcontractor'; fa = 'By picking up materials from subcontractor';
					|it = 'Per restituzioni da parte dell''elaboratore';
					|pl = 'Wg zwrotów od przetwórcy';
					|tr = 'Fason üretici iadelerine göre'");
	Else
		Return NStr("vi = 'Khi nhận trả lại';
					|ru = 'По возвратам';
					|en = 'By returns'; fa = 'By returns';
					|it = 'Per i resi';
					|pl = 'Według zwrotów';
					|tr = 'İadelere göre'");
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
				|tr = 'fason üreticinin'");
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business operation of the document.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function BusinessOperation() Export
	
	Return Enums.BusinessTransactions.ReturnFromProcessingCompany2_5;
	
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
	
	Return False;
	
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
	
	Form.HeaderOfSubmittedProductSelectionForm = NStr("vi = 'Chọn nguyên liệu đã chuyển giao cho người nhận gia công';
														|ru = 'Подбор сырья, переданных переработчику';
														|en = 'Pick components transferred to subcontractor'; fa = 'Pick components transferred to subcontractor';
														|it = 'Selezione materie prime trasferite all''elaboratore';
														|pl = 'Wybór surowców, przekazanych przetwórcy';
														|tr = 'Fason üreticiye transfer edilen hammaddelerin seçimi'");
	
	Items.Partner.Title                         = NStr("vi = 'Bên nhận gia công';
														|ru = 'Переработчик';
														|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
														|it = 'Subfornitore';
														|pl = 'Subcontractor';
														|tr = 'Fason üretici'");
	Items.GoodsSelectTransferredGoods.Title = NStr("vi = 'Chọn nguyên liệu đã chuyển giao';
													|ru = 'Подобрать переданное сырье';
													|en = 'Pick transferred components'; fa = 'Pick transferred components';
													|it = 'Selezionare materie prime trasferite';
													|pl = 'Wybierz przekazane surowce';
													|tr = 'Transfer edilen hammaddeleri seç'");
	Items.PagesOrder.Visible                   = False;
	
	Items.Terms.Visible = ToUseTermsOfSales();
	
	Items.GoodsFillInCCDNumbers.Visible            = False;
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
	
	Return NStr("vi = 'Nhận trả lại nguyên liệu từ người nhận gia công';
				|ru = 'Возврат сырья от переработчика';
				|en = 'Goods return — Subcontracting services received'; fa = 'Goods return — Subcontracting services received';
				|it = 'Reso delle materie prime dal subfornitore';
				|pl = 'Zwrot surowca od przetwórcy';
				|tr = 'Fason üreticiden hammadde iadesi'");
	
EndFunction

#EndRegion

#Region CreatingHyperlinkInJournal

// Returns the hyperlink text for the transition from the document log to the design workspace.
// 
// Parameters:
// 	Parameters - Structure - parameters for forming the hyperlink text.
// Returns:
// 	FormattedString, Undefined - the text of the hyperlink of the transition to the workplace of the registration of transfers.
//
Function CreateHyperlinkToDesign(Parameters) Export
	
	HaveReadRights = GetFunctionalOption("UseWarehouseManagemantSystemForGoodsReceipt")
						And AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
		
	If Not HaveReadRights Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Nhận trả lại nguyên liệu';
						|ru = 'Возврат сырья';
						|en = 'Return of components'; fa = 'برگشت اجزا';
						|it = 'Reso delle materie prime';
						|pl = 'Zwrot surowców';
						|tr = 'Hammadde iadesi'");
	HyperlinkAnchorText = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices/RawMaterialReturnsPage";
	
	ThereAreDocumentsForRegistration = DataProcessors.DocumentsOfTransferToTollingAll2_5.ThereAreDocumentsForRegistration(
									Parameters, Enums.BusinessTransactions.ReturnFromProcessingCompany2_5);
	
	ColorOfHyperlink = ?(ThereAreDocumentsForRegistration, Undefined, StyleColors.EmptyTableField);
	
	Return New FormattedString(HyperlinkText,, ColorOfHyperlink,, HyperlinkAnchorText);
	
EndFunction

#EndRegion

#EndRegion

#EndRegion