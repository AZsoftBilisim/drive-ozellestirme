
#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		DocumentType = TypeOf(Document);
		
		CorrectiveDocument = DocumentCorrection.ThisIsCorrectiveDocument(Document);
		
		If Not Properties.IsNew
				And (DocumentType = Type("DocumentObject.SalesOrder")
				Or DocumentType = Type("DocumentObject.RequestForReturnOfGoodsFromCustomer")
				Or DocumentType = Type("DocumentObject.SubcontractOrder2_5")
				Or DocumentType = Type("DocumentObject.MaterialProviderOrder2_5")
				Or DocumentType = Type("DocumentObject.ProductionStage2_2") And Document.ProductionByThirdParty
				Or False)
			Or Properties.WriteMode = DocumentWriteMode.Posting
				And (DocumentType = Type("DocumentObject.CustomerInvoiceServices")
				Or DocumentType = Type("DocumentObject.ReturnOfGoodsFromCustomer")
				Or DocumentType = Type("DocumentObject.RequestForReturnOfGoodsFromCustomer")
				Or DocumentType = Type("DocumentObject.ReceiptOfGoodsFromCustodian")
				Or DocumentType = Type("DocumentObject.CustomerInvoice")
				Or DocumentType = Type("DocumentObject.PurchasingReportToConsignorPrincipal")
				Or DocumentType = Type("DocumentObject.GoodsShipmentFromStorage")
				Or DocumentType = Type("DocumentObject.TransferOfGoodsToBailee")
				Or DocumentType = Type("DocumentObject.ReportToMaterialProvider2_5")
				Or False)
			Or (DocumentType = Type("DocumentObject.GoodsShipmentToCustomer")
				Or DocumentType = Type("DocumentObject.WriteOffOfShippedGoods")
				Or DocumentType = Type("DocumentObject.RecognitionOfStockSurplusShippedToCustomer")
				Or DocumentType = Type("DocumentObject.GoodsReceiptFromCustomer")
				Or DocumentType = Type("DocumentObject.CustomerInvoice")
					And Document.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods)
			
			Or CorrectiveDocument Then
			
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences);
			
		EndIf;
		
	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.RevenueAndCOGS);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.RevenueServicesAndAssets);
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;
	
	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.ShipmentAndReturnReferences;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
		
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export
	
	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("ChangesTableRevenueAndCOGS", 
		AccumulationRegisters.RevenueAndCOGS.RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of sales.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ShipmentAndReturnReferences");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "DeleteRequestsForReturnOfGoodsFromCustomers");
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList of String - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	#Region ShipmentAndReturnReferences
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsOfShipmentOrderUpdate") Then
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"(ReferenceOrder, Products, Characteristic) IN
			|		(SELECT
			|			Table.ReferenceOrder,
			|			Table.Products,
			|			Table.Characteristic
			|		FROM
			|			RegisteredRecordsOfShipmentOrderUpdate AS Table)";
		TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
		TableFormationParameters.Indicators =
			"ToRegister, Issued_1, ToShip, Shipped, ReceivedBeforeTransferOfTitleToGoods, WrittenOffBeforeTransferOfTitleToGoods,
			|RequestedForReturn, ToRegisterForReturns, RegisteredOnReturns, ForReceiving, Accepted, AcceptedOnReturns";
		TableFormationParameters.Resources = "Count";
		TableFormationParameters.TempTableName = "VT_ShipmentControlOrders";
		
		VT_ShipmentControlOrders =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		QueryTexts.Add(VT_ShipmentControlOrders);
		
		If GetFunctionalOption("UseAllowableDeviationOfMeasuringGoodsShipmentReceiving") Then
			
			TextOfTemporaryTableOfPermissibleDeviations =
			"SELECT
			|	AcceptableDeviations.ReferenceOrder AS ReferenceOrder,
			|	AcceptableDeviations.Products AS Products,
			|	AcceptableDeviations.Characteristic AS Characteristic,
			|	AcceptableDeviations.Warehouse AS Warehouse,
			|	AcceptableDeviations.Series AS Series,
			|	AcceptableDeviations.AcceptableDeviationToDesign AS AcceptableDeviationToDesign,
			|	AcceptableDeviations.AcceptableDeviationToBeShipped AS AcceptableDeviationToBeShipped,
			|	AcceptableDeviations.AcceptableDeviationToReturn AS AcceptableDeviationToReturn,
			|	AcceptableDeviations.AcceptableDeviationToAcceptance AS AcceptableDeviationToAcceptance
			|INTO TableOfPermissibleDeviations
			|FROM
			|	TTPermissibleDeviationsOfShipmentOrder AS AcceptableDeviations
			|WHERE
			|	VALUETYPE(AcceptableDeviations.ReferenceOrder) IN
			|	(TYPE(Document.SalesOrder),
			|	TYPE(Document.GoodsShipmentToCustomer),
			|	TYPE(Document.RequestForReturnOfGoodsFromCustomer),
			|	TYPE(Document.SaleAdjustment))
			|
			|INDEX BY
			|	ReferenceOrder,
			|	Products,
			|	Characteristic,
			|	Warehouse,
			|	Series";
			
			QueryTexts.Add(TextOfTemporaryTableOfPermissibleDeviations);
			
		Else
			
			TextOfTemporaryTableOfPermissibleDeviations =
			"SELECT
			|	UNDEFINED AS ReferenceOrder,
			|	UNDEFINED AS Products,
			|	UNDEFINED AS Characteristic,
			|	UNDEFINED AS Warehouse,
			|	UNDEFINED AS Series,
			|	0 AS AcceptableDeviationToDesign,
			|	0 AS AcceptableDeviationToBeShipped,
			|	0 AS AcceptableDeviationToReturn,
			|	0 AS AcceptableDeviationToAcceptance
			|INTO TableOfPermissibleDeviations";
			
			QueryTexts.Add(TextOfTemporaryTableOfPermissibleDeviations);
			
			TextOfTemporaryTableWarehousesSeries =
			"SELECT
			|	TableOfRevolutions.ReferenceOrder AS ReferenceOrder,
			|	TableOfRevolutions.RowCode AS RowCode,
			|	MAX(TableOfRevolutions.Warehouse) AS Warehouse,
			|	MAX(TableOfRevolutions.Series) AS Series
			|INTO TableSeriesWarehouses
			|FROM
			|	AccumulationRegister.ShipmentAndReturnReferences.Turnovers(,,, (ReferenceOrder, Products, Characteristic) IN
			|		(SELECT
			|			Table.ReferenceOrder,
			|			Table.Products,
			|			Table.Characteristic
			|		FROM
			|			RegisteredRecordsOfShipmentOrderUpdate AS Table)
			|	AND RowCode <> 0
			|	AND Factor IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
			|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
			|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))) AS TableOfRevolutions
			|GROUP BY
			|	TableOfRevolutions.ReferenceOrder,
			|	TableOfRevolutions.RowCode
			|
			|INDEX BY
			|	ReferenceOrder,
			|	RowCode";
			
			QueryTexts.Add(TextOfTemporaryTableWarehousesSeries);
			
		EndIf;
		
		QueryTextGroupingByMetrics =
		"SELECT
		|	Subquery.ReferenceOrder AS ReferenceOrder,
		|	Subquery.Products AS Products,
		|	Subquery.Characteristic AS Characteristic,
		|	Subquery.Warehouse AS Warehouse,
		|	Subquery.Series AS Series,
		|	SUM(Subquery.QuantityRequestedForReturnTurnover) AS QuantityRequestedForReturnTurnover,
		|	SUM(Subquery.ForRegistrationQuantityTurnover)
		|		- SUM(Subquery.RegisteredUpToPPSWithoutWarehouse)
		|		+ SUM(Subquery.DebitedToPPSWithoutWarehouse)
		|		+ SUM(Subquery.AcceptedWithoutStock) AS ForRegistrationQuantityTurnover,
		|	SUM(Subquery.IssuedQuantityTurnover)
		|		- SUM(Subquery.RegisteredUpToPPSWithoutWarehouse)
		|		+ SUM(Subquery.DebitedToPPSWithoutWarehouse)
		|		+ SUM(Subquery.AcceptedWithoutStock) AS IssuedQuantityTurnover,
		|	SUM(Subquery.IssuedQuantityTurnover) AS OnlyAmountOfTurnoverHasBeenIssued,
		|	SUM(Subquery.ForRegistrationOnReturnsQuantityTurnover) AS ForRegistrationOnReturnsQuantityTurnover,
		|	SUM(Subquery.IssuedByReturnsQuantityTurnover) AS IssuedByReturnsQuantityTurnover,
		|	SUM(Subquery.QuantityToBeShippedTurnover)
		|		+ SUM(Subquery.RegisteredToPPSWarehouse)
		|		- SUM(Subquery.WrittenOffToPPPWarehouse)
		|		- SUM(Subquery.AcceptedWarehouse) AS QuantityToBeShippedTurnover,
		|	SUM(Subquery.ShippedQuantityTurnover)
		|		+ SUM(Subquery.RegisteredToPPSWarehouse)
		|		- SUM(Subquery.WrittenOffToPPPWarehouse)
		|		- SUM(Subquery.AcceptedWarehouse) AS ShippedQuantityTurnover,
		|	SUM(Subquery.ShippedQuantityTurnover) OnlyShippedQuantityTurnover,
		|	SUM(Subquery.QuantityReadyForAcceptanceTurnover) AS QuantityReadyForAcceptanceTurnover,
		|	SUM(Subquery.QuantityAccepted_Turnover) AS QuantityAccepted_Turnover,
		|	SUM(Subquery.AcceptedOnReturnsQuantityTurnover) AS AcceptedOnReturnsQuantityTurnover
		|INTO VT_ShipmentOrdersControlWarehouses
		|FROM
		|	(SELECT
		|		TableOfRevolutions.ReferenceOrder AS ReferenceOrder,
		|		TableOfRevolutions.Products AS Products,
		|		TableOfRevolutions.Characteristic AS Characteristic,
		|		TableOfRevolutions.RowCode AS RowCode,
		|		CASE
		|			WHEN TableOfRevolutions.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|				THEN ISNULL(TableSeriesWarehouses.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))
		|			ELSE TableOfRevolutions.Warehouse
		|		END AS Warehouse,
		|		CASE
		|			WHEN TableOfRevolutions.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|				THEN ISNULL(TableSeriesWarehouses.Series, VALUE(Catalog.ItemsBatches.EmptyRef))
		|			ELSE TableOfRevolutions.Series
		|		END AS Series,
		|		TableOfRevolutions.QuantityRequestedForReturnTurnover AS QuantityRequestedForReturnTurnover,
		|		TableOfRevolutions.ForRegistrationQuantityTurnover AS ForRegistrationQuantityTurnover,
		|		TableOfRevolutions.IssuedQuantityTurnover AS IssuedQuantityTurnover,
		|		TableOfRevolutions.ForRegistrationOnReturnsQuantityTurnover AS ForRegistrationOnReturnsQuantityTurnover,
		|		TableOfRevolutions.IssuedByReturnsQuantityTurnover AS IssuedByReturnsQuantityTurnover,
		|		TableOfRevolutions.QuantityToBeShippedTurnover AS QuantityToBeShippedTurnover,
		|		TableOfRevolutions.ShippedQuantityTurnover AS ShippedQuantityTurnover,
		|		TableOfRevolutions.QuantityReadyForAcceptanceTurnover AS QuantityReadyForAcceptanceTurnover,
		|		TableOfRevolutions.QuantityAccepted_Turnover AS QuantityAccepted_Turnover,
		|		TableOfRevolutions.AcceptedOnReturnsQuantityTurnover AS AcceptedOnReturnsQuantityTurnover,
		|		CASE
		|			WHEN TableOfRevolutions.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|				THEN TableOfRevolutions.RegisteredUpToPPPQuantityTurnover
		|			ELSE 0
		|		END AS RegisteredUpToPPSWithoutWarehouse,
		|		CASE
		|			WHEN TableOfRevolutions.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|				THEN TableOfRevolutions.DeductedToPPPQuantityTurnover
		|			ELSE 0
		|		END AS DebitedToPPSWithoutWarehouse,
		|		CASE
		|			WHEN TableOfRevolutions.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|				THEN TableOfRevolutions.QuantityAccepted_Turnover
		|			ELSE 0
		|		END AS AcceptedWithoutStock,
		|		CASE
		|			WHEN TableOfRevolutions.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|				THEN TableOfRevolutions.RegisteredUpToPPPQuantityTurnover
		|			ELSE 0
		|		END AS RegisteredToPPSWarehouse,
		|		CASE
		|			WHEN TableOfRevolutions.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|				THEN TableOfRevolutions.DeductedToPPPQuantityTurnover
		|			ELSE 0
		|		END AS WrittenOffToPPPWarehouse,
		|		CASE
		|			WHEN TableOfRevolutions.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|				THEN TableOfRevolutions.QuantityAccepted_Turnover
		|			ELSE 0
		|		END AS AcceptedWarehouse
		|	FROM
		|		VT_ShipmentControlOrders AS TableOfRevolutions
		|			LEFT JOIN TableSeriesWarehouses AS TableSeriesWarehouses
		|			ON TableOfRevolutions.ReferenceOrder = TableSeriesWarehouses.ReferenceOrder
		|			AND TableOfRevolutions.RowCode = TableSeriesWarehouses.RowCode
		|			AND TableOfRevolutions.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)) AS Subquery
		|GROUP BY
		|	Subquery.ReferenceOrder,
		|	Subquery.Products,
		|	Subquery.Characteristic,
		|	Subquery.Warehouse,
		|	Subquery.Series
		|
		|INDEX BY
		|	ReferenceOrder,
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Series";
		
		QueryTexts.Add(QueryTextGroupingByMetrics);
		
		QueryTextDataSource =
		"SELECT
		|	SubqueryTurnover.ReferenceOrder AS ReferenceOrder,
		|	SubqueryTurnover.Products AS Products,
		|	SubqueryTurnover.Characteristic AS Characteristic,
		|	SubqueryTurnover.Warehouse AS Warehouse,
		|	SubqueryTurnover.Series AS Series,
		|	SUM(SubqueryTurnover.RequestedForReturn) AS RequestedForReturn,
		|	SUM(SubqueryTurnover.ToRegister) AS ToRegister,
		|	SUM(SubqueryTurnover.Issued_1) AS Issued_1,
		|	SUM(SubqueryTurnover.JustIssued) AS JustIssued,
		|	SUM(SubqueryTurnover.ToRegisterForReturns) AS ToRegisterForReturns,
		|	SUM(SubqueryTurnover.RegisteredOnReturns) AS RegisteredOnReturns,
		|	SUM(SubqueryTurnover.ToShip) AS ToShip,
		|	SUM(SubqueryTurnover.Shipped) AS Shipped,
		|	SUM(SubqueryTurnover.ShippedOnly) AS ShippedOnly,
		|	SUM(SubqueryTurnover.ForReceiving) AS ForReceiving,
		|	SUM(SubqueryTurnover.Accepted) AS Accepted,
		|	SUM(SubqueryTurnover.AcceptedOnReturns) AS AcceptedOnReturns,
		|	SUM(SubqueryTurnover.ToRegister)
		|		+ SUM(SubqueryTurnover.AcceptableDeviationToDesign) AS ToRegistrationWithDeviation,
		|	SUM(SubqueryTurnover.ToShip)
		|		+ SUM(SubqueryTurnover.AcceptableDeviationToBeShipped) AS ToBeShippedWithDeviation,
		|	SUM(SubqueryTurnover.RequestedForReturn)
		|		+ SUM(SubqueryTurnover.AcceptableDeviationToReturn) AS ReturnWithDeviationHasBeenRequested,
		|	SUM(SubqueryTurnover.ToRegisterForReturns)
		|		+ SUM(SubqueryTurnover.AcceptableDeviationToReturn) AS ForProcessingReturnsWithDeviation,
		|	SUM(SubqueryTurnover.ForReceiving)
		|		+ SUM(SubqueryTurnover.AcceptableDeviationToAcceptance) AS ForAcceptanceWithDeviation
		|INTO DataSource
		|FROM
		|	(SELECT
		|		TableOfRevolutions.ReferenceOrder AS ReferenceOrder,
		|		TableOfRevolutions.Products AS Products,
		|		TableOfRevolutions.Characteristic AS Characteristic,
		|		VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|		TableOfRevolutions.QuantityRequestedForReturnTurnover AS RequestedForReturn,
		|		TableOfRevolutions.ForRegistrationQuantityTurnover AS ToRegister,
		|		TableOfRevolutions.IssuedQuantityTurnover AS Issued_1,
		|		TableOfRevolutions.OnlyAmountOfTurnoverHasBeenIssued AS JustIssued,
		|		TableOfRevolutions.ForRegistrationOnReturnsQuantityTurnover AS ToRegisterForReturns,
		|		TableOfRevolutions.IssuedByReturnsQuantityTurnover AS RegisteredOnReturns,
		|		TableOfRevolutions.QuantityToBeShippedTurnover AS ToShip,
		|		TableOfRevolutions.ShippedQuantityTurnover AS Shipped,
		|		TableOfRevolutions.OnlyShippedQuantityTurnover AS ShippedOnly,
		|		TableOfRevolutions.QuantityReadyForAcceptanceTurnover AS ForReceiving,
		|		TableOfRevolutions.QuantityAccepted_Turnover AS Accepted,
		|		TableOfRevolutions.AcceptedOnReturnsQuantityTurnover AS AcceptedOnReturns,
		|		ISNULL(AcceptableDeviations.AcceptableDeviationToDesign, 0) AS AcceptableDeviationToDesign,
		|		ISNULL(AcceptableDeviations.AcceptableDeviationToBeShipped, 0) AS AcceptableDeviationToBeShipped,
		|		ISNULL(AcceptableDeviations.AcceptableDeviationToReturn, 0) AS AcceptableDeviationToReturn,
		|		ISNULL(AcceptableDeviations.AcceptableDeviationToAcceptance, 0) AS AcceptableDeviationToAcceptance
		|	FROM
		|		VT_ShipmentOrdersControlWarehouses AS TableOfRevolutions
		|			LEFT JOIN TableOfPermissibleDeviations AS AcceptableDeviations
		|			ON TableOfRevolutions.ReferenceOrder = AcceptableDeviations.ReferenceOrder
		|			AND TableOfRevolutions.Products = AcceptableDeviations.Products
		|			AND TableOfRevolutions.Characteristic = AcceptableDeviations.Characteristic
		|			AND TableOfRevolutions.Warehouse = AcceptableDeviations.Warehouse
		|			AND TableOfRevolutions.Series = AcceptableDeviations.Series) AS SubqueryTurnover
		|GROUP BY
		|	SubqueryTurnover.ReferenceOrder,
		|	SubqueryTurnover.Products,
		|	SubqueryTurnover.Characteristic,
		|	SubqueryTurnover.Warehouse,
		|	SubqueryTurnover.Series";
		
		QueryTexts.Add(QueryTextDataSource);
		
		QueryText =
		"SELECT
		|	BalanceTable.ReferenceOrder AS ReferenceOrder,
		|	BalanceTable.Products AS Products,
		|	ProductsTable.UnitOfMeasure AS UnitOfMeasure,
		|	BalanceTable.Characteristic AS Characteristic,
		|	BalanceTable.Warehouse AS Warehouse,
		|	BalanceTable.Series AS Series,
		|	CASE
		|		WHEN BalanceTable.ReturnWithDeviationHasBeenRequested < BalanceTable.RegisteredOnReturns
		|			THEN ""RequestedForReturn""
		|		WHEN BalanceTable.ToRegistrationWithDeviation < BalanceTable.Issued_1
		|			THEN ""ToRegister""
		|		WHEN BalanceTable.ForProcessingReturnsWithDeviation < BalanceTable.RegisteredOnReturns
		|			THEN ""ToRegisterForReturns""
		|		WHEN BalanceTable.ToBeShippedWithDeviation < BalanceTable.Shipped
		|			THEN ""ToShip""
		|		WHEN BalanceTable.ForAcceptanceWithDeviation < (BalanceTable.Accepted + BalanceTable.AcceptedOnReturns)
		|			THEN ""ForReceiving""
		//
		// Sales control formula:
		//
		// KOtgruzke + Oprichodovanodopps (with warehouse) - Write-OffsanoDoPPS (warehouse) - Accepted (warehouse) >=
		// Co-registration - Add-ONDOPP (without warehouse) + Write-OFFDOPP (without warehouse) + Accepted (without stock) >=
		// Shipped + OprihodovanoDoPPS (with warehouse) - Write-OffsanoDoPPS (warehouse) - Accepted (warehouse) >=
		// Formalized - Check-in ofanodopps (without warehouse) + Write-off ofanodopps (without warehouse) + Accepted (without warehouse)
		//
		// And
		//
		// COtgruzke >= Shipped >= KPriemke >= Accepted
		//
		|		WHEN BalanceTable.ToShip < BalanceTable.ToRegister
		|			THEN ""Sales_CShipment""
		|		WHEN BalanceTable.ToRegistrationWithDeviation < BalanceTable.Shipped
		|			THEN ""SalesByDesign""
		|		WHEN BalanceTable.Shipped < BalanceTable.Issued_1
		|			THEN ""Sales_Shipped""
		|		WHEN BalanceTable.JustIssued < 0
		|			THEN ""Sales_Completed""
		|		WHEN BalanceTable.ShippedOnly < BalanceTable.ForReceiving
		|			THEN ""Sales_KAcceptance""
		|	END AS ControlErrorCode,
		|	CASE
		|		WHEN BalanceTable.ReturnWithDeviationHasBeenRequested < BalanceTable.RegisteredOnReturns
		|			THEN BalanceTable.RegisteredOnReturns - BalanceTable.ReturnWithDeviationHasBeenRequested
		|		WHEN BalanceTable.ToRegistrationWithDeviation < BalanceTable.Issued_1
		|			THEN BalanceTable.Issued_1 - BalanceTable.ToRegistrationWithDeviation
		|		WHEN BalanceTable.ForProcessingReturnsWithDeviation < BalanceTable.RegisteredOnReturns
		|			THEN BalanceTable.RegisteredOnReturns - BalanceTable.ForProcessingReturnsWithDeviation
		|		WHEN BalanceTable.ToBeShippedWithDeviation < BalanceTable.Shipped
		|			THEN BalanceTable.Shipped - BalanceTable.ToBeShippedWithDeviation
		|		WHEN BalanceTable.ForAcceptanceWithDeviation < (BalanceTable.Accepted + BalanceTable.AcceptedOnReturns)
		|			THEN (BalanceTable.Accepted + BalanceTable.AcceptedOnReturns) - BalanceTable.ForAcceptanceWithDeviation
		|		WHEN BalanceTable.ToShip < BalanceTable.ToRegister
		|			THEN BalanceTable.ToRegister - BalanceTable.ToShip
		|		WHEN BalanceTable.ToRegistrationWithDeviation < BalanceTable.Shipped
		|			THEN BalanceTable.Shipped - BalanceTable.ToRegistrationWithDeviation
		|		WHEN BalanceTable.Shipped < BalanceTable.Issued_1
		|			THEN BalanceTable.Issued_1 - BalanceTable.Shipped
		|		WHEN BalanceTable.JustIssued < 0
		|			THEN BalanceTable.JustIssued
		|		WHEN BalanceTable.ShippedOnly < BalanceTable.ForReceiving
		|			THEN BalanceTable.ForReceiving - BalanceTable.ShippedOnly
		|		ELSE 0
		|	END AS SignificanceOfDiscrepancy
		|INTO TableOfControlErrors
		|FROM
		|	DataSource AS BalanceTable
		|		INNER JOIN Catalog.Products AS ProductsTable
		|		ON BalanceTable.Products = ProductsTable.Ref
		|WHERE
		|	VALUETYPE(BalanceTable.ReferenceOrder) = TYPE(Document.SalesOrder)
		|	OR VALUETYPE(BalanceTable.ReferenceOrder) = TYPE(Document.GoodsShipmentToCustomer)
		|	OR VALUETYPE(BalanceTable.ReferenceOrder) = TYPE(Document.SourceDocument)
		|		AND CAST(BalanceTable.ReferenceOrder AS Document.SourceDocument).SourceDocumentType =
		|			VALUE(Enum.SourceDocumentTypes.GoodsShipmentToCustomer)
		|
		|UNION ALL
		|
		|SELECT
		|	BalanceTable.ReferenceOrder AS ReferenceOrder,
		|	BalanceTable.Products AS Products,
		|	ProductsTable.UnitOfMeasure AS UnitOfMeasure,
		|	BalanceTable.Characteristic AS Characteristic,
		|	BalanceTable.Warehouse AS Warehouse,
		|	BalanceTable.Series AS Series,
		|	CASE
		|		WHEN BalanceTable.ReturnWithDeviationHasBeenRequested < BalanceTable.RegisteredOnReturns
		|			THEN ""RequestedForReturn""
		|		WHEN BalanceTable.ToRegistrationWithDeviation < BalanceTable.Issued_1
		|			THEN ""ToRegister""
		|		WHEN BalanceTable.ForProcessingReturnsWithDeviation < BalanceTable.RegisteredOnReturns
		|			THEN ""ToRegisterForReturns""
		|		WHEN BalanceTable.ToBeShippedWithDeviation < BalanceTable.Shipped
		|			THEN ""ToShip""
		|		WHEN BalanceTable.ForAcceptanceWithDeviation < (BalanceTable.Accepted + BalanceTable.AcceptedOnReturns)
		|			THEN ""ForReceiving""
		//
		// Refund control formula:
		//
		// Declared Refund >= Co-formalization to returns >= Acceptance >= Formalized Refund >= (Accepted + Accepted returns)
		//
		|		WHEN BalanceTable.RequestedForReturn < BalanceTable.ToRegisterForReturns
		|			THEN ""Returns_ReturnRequested""
		|		WHEN BalanceTable.ToRegisterForReturns < BalanceTable.ForReceiving
		|			THEN ""Returns_ToReturnProcessing""
		|		WHEN BalanceTable.ForAcceptanceWithDeviation < BalanceTable.RegisteredOnReturns
		|			THEN ""ReturnsOnAcceptance""
		|		WHEN BalanceTable.RegisteredOnReturns < (BalanceTable.Accepted + BalanceTable.AcceptedOnReturns)
		|			THEN ""Returns_IssuedForReturns""
		|		ELSE """"
		|	END AS ControlErrorCode,
		|	CASE
		|		WHEN BalanceTable.ReturnWithDeviationHasBeenRequested < BalanceTable.RegisteredOnReturns
		|			THEN BalanceTable.RegisteredOnReturns - BalanceTable.ReturnWithDeviationHasBeenRequested
		|		WHEN BalanceTable.ToRegistrationWithDeviation < BalanceTable.Issued_1
		|			THEN BalanceTable.Issued_1 - BalanceTable.ToRegistrationWithDeviation
		|		WHEN BalanceTable.ForProcessingReturnsWithDeviation < BalanceTable.RegisteredOnReturns
		|			THEN BalanceTable.RegisteredOnReturns - BalanceTable.ForProcessingReturnsWithDeviation
		|		WHEN BalanceTable.ToBeShippedWithDeviation < BalanceTable.Shipped
		|			THEN BalanceTable.Shipped - BalanceTable.ToBeShippedWithDeviation
		|		WHEN BalanceTable.ForAcceptanceWithDeviation < (BalanceTable.Accepted + BalanceTable.AcceptedOnReturns)
		|			THEN (BalanceTable.Accepted + BalanceTable.AcceptedOnReturns) - BalanceTable.ForAcceptanceWithDeviation
		|		WHEN BalanceTable.RequestedForReturn < BalanceTable.ToRegisterForReturns
		|			THEN BalanceTable.ToRegisterForReturns - BalanceTable.RequestedForReturn
		|		WHEN BalanceTable.ToRegisterForReturns < BalanceTable.ForReceiving
		|			THEN BalanceTable.ForReceiving - BalanceTable.ToRegisterForReturns
		|		WHEN BalanceTable.ForAcceptanceWithDeviation < BalanceTable.RegisteredOnReturns
		|			THEN BalanceTable.RegisteredOnReturns - BalanceTable.ForAcceptanceWithDeviation
		|		WHEN BalanceTable.RegisteredOnReturns < (BalanceTable.Accepted + BalanceTable.AcceptedOnReturns)
		|			THEN (BalanceTable.Accepted + BalanceTable.AcceptedOnReturns) - BalanceTable.RegisteredOnReturns
		|		ELSE 0
		|	END AS SignificanceOfDiscrepancy
		|FROM
		|	DataSource AS BalanceTable
		|		INNER JOIN Catalog.Products AS ProductsTable
		|		ON BalanceTable.Products = ProductsTable.Ref
		|WHERE
		|	VALUETYPE(BalanceTable.ReferenceOrder) IN
		|	(TYPE(Document.RequestForReturnOfGoodsFromCustomer), TYPE(Document.SaleAdjustment))
		|
		|UNION ALL
		|
		|SELECT
		|	BalanceTable.ReferenceOrder AS ReferenceOrder,
		|	BalanceTable.Products AS Products,
		|	ProductsTable.UnitOfMeasure AS UnitOfMeasure,
		|	BalanceTable.Characteristic AS Characteristic,
		|	BalanceTable.Warehouse AS Warehouse,
		|	BalanceTable.Series AS Series,
		|	CASE
		|		WHEN BalanceTable.ReturnWithDeviationHasBeenRequested < BalanceTable.RegisteredOnReturns
		|			THEN ""RequestedForReturn""
		|		WHEN BalanceTable.ToRegistrationWithDeviation < BalanceTable.Issued_1
		|			THEN ""ToRegister""
		|		WHEN BalanceTable.ForProcessingReturnsWithDeviation < BalanceTable.RegisteredOnReturns
		|			THEN ""ToRegisterForReturns""
		|		WHEN BalanceTable.ToBeShippedWithDeviation < BalanceTable.Shipped
		|			THEN ""ToShip""
		|		WHEN BalanceTable.ForAcceptanceWithDeviation < (BalanceTable.Accepted + BalanceTable.AcceptedOnReturns)
		|			THEN ""ForReceiving""
		//
		// Recycling control formula:
		//
		// Co-registration >= Formalized
		// And
		// KOtgruzke >= Shipped
		//
		|		ELSE """"
		|	END AS ControlErrorCode,
		|	CASE
		|		WHEN BalanceTable.ReturnWithDeviationHasBeenRequested < BalanceTable.RegisteredOnReturns
		|			THEN BalanceTable.RegisteredOnReturns - BalanceTable.ReturnWithDeviationHasBeenRequested
		|		WHEN BalanceTable.ToRegistrationWithDeviation < BalanceTable.Issued_1
		|			THEN BalanceTable.Issued_1 - BalanceTable.ToRegistrationWithDeviation
		|		WHEN BalanceTable.ForProcessingReturnsWithDeviation < BalanceTable.RegisteredOnReturns
		|			THEN BalanceTable.RegisteredOnReturns - BalanceTable.ForProcessingReturnsWithDeviation
		|		WHEN BalanceTable.ToBeShippedWithDeviation < BalanceTable.Shipped
		|			THEN BalanceTable.Shipped - BalanceTable.ToBeShippedWithDeviation
		|		WHEN BalanceTable.ForAcceptanceWithDeviation < (BalanceTable.Accepted + BalanceTable.AcceptedOnReturns)
		|			THEN (BalanceTable.Accepted + BalanceTable.AcceptedOnReturns) - BalanceTable.ForAcceptanceWithDeviation
		|		ELSE 0
		|	END AS SignificanceOfDiscrepancy
		|FROM
		|	DataSource AS BalanceTable
		|		INNER JOIN Catalog.Products AS ProductsTable
		|		ON BalanceTable.Products = ProductsTable.Ref
		|WHERE
		|	VALUETYPE(BalanceTable.ReferenceOrder) IN (
		|		TYPE(Document.MaterialProviderOrder2_5),
		|		TYPE(Document.SubcontractOrder2_5)
		|		)
		|";
		
		QueryTexts.Add(QueryText, "ErrorCodesTable");
		
		QueryText =
		"SELECT
		|	TableOfControlErrors.ReferenceOrder AS ReferenceOrder,
		|	TableOfControlErrors.Products AS Products,
		|	TableOfControlErrors.UnitOfMeasure AS UnitOfMeasure,
		|	TableOfControlErrors.Characteristic AS Characteristic,
		|	TableOfControlErrors.Series AS Series,
		|	TableOfControlErrors.ControlErrorCode AS ControlErrorCode,
		|	TableOfControlErrors.SignificanceOfDiscrepancy AS SignificanceOfDiscrepancy
		|FROM
		|	TableOfControlErrors AS TableOfControlErrors
		|WHERE
		|	TableOfControlErrors.SignificanceOfDiscrepancy <> 0";
		
		QueryTexts.Add(QueryText, "ShipmentOrderErrors");
		
	EndIf;
	
	#EndRegion
	
	#Region CompanyGoods
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "MovementOfGoodsOfOrganizationsChangeInSummary") Then
		
		QueryText =
		"SELECT
		|	CAST(BalanceTable.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Contract AS Contract,
		|	BalanceTable.Products AS Products,
		|	BalanceTable.Characteristic AS Characteristic,
		|	(BalanceTable.ForRegistrationOnReturnsQuantityTurnover -
		|		BalanceTable.IssuedByReturnsQuantityTurnover) AS Count
		|INTO VT_BalanceForProcessingByRequests
		|FROM
		|	#ShipmentOrdersTurnoverExpanded AS BalanceTable";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"(CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Contract, Products, Characteristic) IN
			|		(SELECT
			|				Table.Contract,
			|				Table.Products,
			|				Table.Characteristic
			|			FROM
			|				MovementOfGoodsOfOrganizationsChangeInSummary AS Table)";
		TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic";
		TableFormationParameters.Indicators = "ToRegisterForReturns, RegisteredOnReturns";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		QueryTexts.Add(QueryText);
		
		QueryTexts.Add(
			"SELECT
			|	Analysts.DimensionKey AS Ref
			|INTO VT_ProductAccountingAnalyst
			|FROM
			|	MovementOfGoodsOfOrganizationsChangeInSummary AS ApplicationBalances
			|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Analysts
			|		ON ApplicationBalances.Products = Analysts.Products
			|		AND ApplicationBalances.Characteristic = Analysts.Characteristic
			|		AND ApplicationBalances.Contract = Analysts.StorageLocation");
		
		QueryTexts.Add(
			"SELECT
			|	BalanceTable.ItemsLocationAttributes.Contract AS Contract,
			|	BalanceTable.ItemsLocationAttributes.Products AS Products,
			|	BalanceTable.ItemsLocationAttributes.Characteristic AS Characteristic,
			|	BalanceTable.CountBalance AS Count
			|INTO VT_BalanceForProductsOfOrganizations
			|FROM
			|	AccumulationRegister.CompanyGoods.Balance(, (ItemsLocationAttributes) IN
			|		(SELECT
			|			SelectionOfAnalysts.Ref
			|		FROM
			|			VT_ProductAccountingAnalyst AS SelectionOfAnalysts)) AS BalanceTable");
		
		QueryText =
			"SELECT
			|	BalanceTable.Contract AS Contract,
			|	BalanceTable.Products AS Products,
			|	CAST(BalanceTable.Products AS Catalog.Products).UnitOfMeasure AS UnitOfMeasure,
			|	BalanceTable.Characteristic AS Characteristic,
			|	SUM(BalanceTable.Count) AS Count
			|FROM
			|	(SELECT
			|		CompanyGoods.Contract AS Contract,
			|		CompanyGoods.Products AS Products,
			|		CompanyGoods.Characteristic AS Characteristic,
			|		CompanyGoods.Count AS Count
			|	FROM
			|		VT_BalanceForProductsOfOrganizations AS CompanyGoods
			|
			|	UNION ALL
			|
			|	SELECT
			|		RequestsForReturn.Contract AS Contract,
			|		RequestsForReturn.Products AS Products,
			|		RequestsForReturn.Characteristic AS Characteristic,
			|		-RequestsForReturn.Count AS Count
			|	FROM
			|		VT_BalanceForProcessingByRequests AS RequestsForReturn) AS BalanceTable
			|GROUP BY
			|	BalanceTable.Contract,
			|	BalanceTable.Products,
			|	BalanceTable.Characteristic,
			|	CAST(BalanceTable.Products AS Catalog.Products).UnitOfMeasure
			|HAVING
			|	SUM(BalanceTable.Count) < 0";
		
		QueryTexts.Add(QueryText, "ErrorsReturnOfGoodsFromCustodians");
		
	EndIf;
	
	#EndRegion
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	#Region ShipmentAndReturnReferences
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsOfShipmentOrderUpdate") Then
		
		TextsOfControlErrors = AccumulationRegisters.ShipmentAndReturnReferences.TextsOfTurnoverControlErrorsByIndicators();
		
		MessageTemplate = NStr("vi = 'Mặt hàng %1';
								|ru = 'Номенклатура %1';
								|en = '%1 item'; fa = '%1 item';
								|it = '%1 item';
								|pl = '%1 item';
								|tr = 'Öğe %1'");
		
		For Each ErrorString In ControlResults.ShipmentOrderErrors Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(
				ErrorString.Products,
				ErrorString.Characteristic);
			
			MessageTitle = StrTemplate(MessageTemplate,
				ProductPresentation);
				
			MessageText = MessageTitle
				+ Chars.LF
				+ StrTemplate(TextsOfControlErrors[ErrorString.ControlErrorCode],
					ErrorString.ReferenceOrder,
					ErrorString.SignificanceOfDiscrepancy,
					ErrorString.UnitOfMeasure);
			
			Common.MessageToUser(MessageText,
				Document,,,
				Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region CompanyGoods
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "MovementOfGoodsOfOrganizationsChangeInSummary") Then
		
		MessageTemplate = NStr("vi = 'Mặt hàng %1
			|Đã trả lại nhiều hơn số lượng đã chỉ ra theo tất cả đề nghị trả lại đã lập và tiếp nhận hàng hóa từ người cất giữ theo hợp đồng %2 là %3 %4';
			|ru = 'Номенклатура %1
			|Возвращено больше, чем указано по всем оформленным заявкам на возврат и поступлениям товаров от хранителя по договору %2, на %3 %4';
			|en = 'Items %1
			|Number of the returned ones exceeds the number of ones specified in all registered requests for return of goods and VMI returns under the %2 contract by %3 %4'; fa = 'Items %1
			|Number of the returned ones exceeds the number of ones specified in all registered requests for return of goods and VMI returns under the %2 contract by %3 %4';
			|it = 'Articolo%1
			| La quantità restituita è maggiore rispetto a quella di tutte le domande compilate dal custode dei trattati%2 circa il reso e l''arrivo delle merci, pari a %3%4';
			|pl = 'Nomenklatura %1
			| Zwrócono więcej niż wskazano dla wszystkich wydanych wniosków o zwrot i odbiór towarów od powiernika na podstawie umowy %2, dla %3 %4';
			|tr = 'Öğe %1
			|%2 sözleşmesi kapsamında, %3 %4 kadar emanetçiden tüm iade ve teslim talepleri için belirtilenden fazla iade ve irsaliye iade edildi'");
		
		For Each ErrorString In ControlResults.ErrorsReturnOfGoodsFromCustodians Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(
				ErrorString.Products, ErrorString.Characteristic);
			
			MessageText = StrTemplate(MessageTemplate, ProductPresentation,
				ErrorString.Contract, -ErrorString.Count, ErrorString.UnitOfMeasure);
			
			Common.MessageToUser(MessageText,
				Document,,,
				Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

#EndRegion

#Region SalesProfitabilityAssessment

Procedure AddDocumentDataToQueryTextsReturnOnSalesReport(TextAndDocumentData, AddendumTextSummaryCalculation) Export
	
	If GetFunctionalOption("UseCommercialProposalsForCustomers")
		And AccessRight("Read", Metadata.Documents.CommercialProposalForCustomer) Then
		
		TextAndDocumentData = "
			|UNION ALL" + "
			|
			|SELECT
			|	DocumentsTable.Ref,
			|	DocumentsTable.Date,
			|	DocumentsTable.Currency,
			|	CommercialOfferToClientGoods.LineNumber,
			|	CommercialOfferToClientGoods.Products,
			|	CommercialOfferToClientGoods.Characteristic,
			|	VALUE(Catalog.Warehouses.EmptyRef),
			|	CommercialOfferToClientGoods.UnitOfMeasure,
			|	CommercialOfferToClientGoods.PriceKind,
			|	CommercialOfferToClientGoods.Price,
			|	CommercialOfferToClientGoods.Sum,
			|	CommercialOfferToClientGoods.Count,
			|	CommercialOfferToClientGoods.PercentRateOfAutomaticDiscountMarkup,
			|	CommercialOfferToClientGoods.PercentRateOfManualDiscount,
			|	CommercialOfferToClientGoods.DiscountMarkupAmount,
			|	CommercialOfferToClientGoods.ManualDiscount,
			|	CommercialOfferToClientGoods.VATRate,
			|	CommercialOfferToClientGoods.VATAmount
			|FROM
			|	Document.CommercialProposalForCustomer.Goods AS CommercialOfferToClientGoods
			|		INNER JOIN Document.CommercialProposalForCustomer AS DocumentsTable
			|		ON DocumentsTable.Ref = &Document
			|		AND CommercialOfferToClientGoods.Ref = DocumentsTable.Ref
			|WHERE
			|	VALUETYPE(&Document) = TYPE(Document.CommercialProposalForCustomer)";
			
		AddendumTextSummaryCalculation = "
			|UNION ALL" + "
			|
			|SELECT
			|	DocumentsTable.Ref,
			|	DocumentsTable.Date,
			|	DocumentsTable.Currency,
			|	CommercialOfferToClientGoods.LineNumber,
			|	CommercialOfferToClientGoods.Products,
			|	CommercialOfferToClientGoods.Characteristic,
			|	VALUE(Catalog.Warehouses.EmptyRef),
			|	CommercialOfferToClientGoods.UnitOfMeasure,
			|	CommercialOfferToClientGoods.PriceKind,
			|	CommercialOfferToClientGoods.Price,
			|	CommercialOfferToClientGoods.Sum,
			|	CommercialOfferToClientGoods.Count,
			|	CommercialOfferToClientGoods.PercentRateOfAutomaticDiscountMarkup,
			|	CommercialOfferToClientGoods.PercentRateOfManualDiscount,
			|	CommercialOfferToClientGoods.DiscountMarkupAmount,
			|	CommercialOfferToClientGoods.ManualDiscount,
			|	CommercialOfferToClientGoods.VATRate,
			|	CommercialOfferToClientGoods.VATAmount
			|FROM
			|	Document.CommercialProposalForCustomer.Goods AS CommercialOfferToClientGoods
			|		INNER JOIN Document.CommercialProposalForCustomer AS DocumentsTable
			|		ON DocumentsTable.Ref = &Document
			|		AND CommercialOfferToClientGoods.Ref = DocumentsTable.Ref
			|WHERE
			|	VALUETYPE(&Document) = TYPE(Document.CommercialProposalForCustomer)";
		
	EndIf;
	
EndProcedure

// Configuring selection parameters based on the call context.
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	FormSettingsComposer - DataCompositionSettingsComposer
//
Procedure WhenSettingSelectionParametersByCallContext(Form, FormSettingsComposer) Export
	
	CommandParameterValue = Undefined;
	If Form.Parameters.Property("CommandParameter",CommandParameterValue) 
		And TypeOf(CommandParameterValue) = Type("DocumentRef.CommercialProposalForCustomer") 
		And Common.ObjectAttributeValue(CommandParameterValue,"BusinessOperation") = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer.Settings, "ChangingVolumeOfManualDiscounts");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SalesOrder

Procedure WhenProcessingCustomerOrderFilling(DocumentObject, FillingData, StandardProcessing) Export
	
	If TypeOf(FillingData) = Type("DocumentRef.CommercialProposalForCustomer") Then
		FillingCustomerSOrderBasedOnCommercialOfferToCustomer(DocumentObject, FillingData);
	EndIf;
	
EndProcedure
 
#EndRegion

#Region SalesWizard

Procedure WhenInitializingSalesAssistant(Object) Export
	
	If GetFunctionalOption("UseCommercialProposalsForCustomers") Then
		Object.CreateCommercialProposal = True;
		Object.PrintCommercialProposal = True;
	EndIf;
	
	Object.CommercialProposalStatus = Enums.StatusesOfCommercialProposalsForCustomers.Valid;
	
EndProcedure

// Initialization of options for processing sales documents.
// 
// Parameters:
// 	Form - ClientApplicationForm - shape.
//
Procedure WhenInitializingOptionsForProcessingSalesDocuments(Form) Export
	
	UseCommercialProposalsForCustomers = GetFunctionalOption("UseCommercialProposalsForCustomers");
	
	If UseCommercialProposalsForCustomers Then
		Form.Items.DocumentCreationOption.ChoiceList.Insert(0, Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal);
	EndIf;
	
EndProcedure

Procedure WhenSettingDefaultSalesPaperworkOption(Form) Export
	
	UseCommercialProposalsForCustomers = GetFunctionalOption("UseCommercialProposalsForCustomers");
	
	If Form.Object.CreateCommercialProposal
		And UseCommercialProposalsForCustomers Then
		
		Form.Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal;
		
	EndIf;
	
EndProcedure

Procedure WhenCreatingDocumentsSalesAssistant(Form, ArrayOfFoundDocuments, Cancel) Export
	
	If Not Cancel
		And Form.Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
			
			CreateDocumentCommercialOfferToClientSalesAssistant(Form, ArrayOfFoundDocuments, Cancel);
			
	EndIf;
		
EndProcedure

Procedure WhenDeterminingDocumentTypeOfDocumentBeingCreatedSalesAssistant(Form, EmptyDocumentLink) Export
	
	If Form.Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
		EmptyDocumentLink = Documents.CommercialProposalForCustomer.EmptyRef();
	EndIf;
	
EndProcedure

Procedure CheckAvailabilityOfAdditionalBankingDetails(Form) Export
	
	PropertiesSet = PropertyManagerInternal.GetObjectPropertySets(Documents.CommercialProposalForCustomer.EmptyRef());
	
	If PropertiesSet.Count() > 0 Then
		AdditionalAttributes = Common.ObjectAttributeValue(PropertiesSet[0].Set, "AdditionalAttributes"); // QueryResult
		If AdditionalAttributes <> Undefined
				And Not AdditionalAttributes.IsEmpty() > 0 Then
			Form.ThereAreAdditionalAttributesOfQuotation = True;
		EndIf;
	EndIf;
	
EndProcedure

Procedure WhenDeterminingNameOfLoadingTableOfAdditionalDetails(ValueSelected, TableName) Export
	
	If ValueSelected.DocumentType = "DocumentObject.CommercialProposalForCustomer" Then
		TableName = "AdditionalAttributesOfCommercialProposal";
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region SalesWizard

Function LockDocument_(DocumentRef) Export
	
	Try
		LockDataForEdit(DocumentRef);
	Except
		ErrorText = NStr("vi = 'Không thể khóa %Document%. %ErrorDescription%';
						|ru = 'Не удалось заблокировать %Document%. %ErrorDescription%';
						|en = 'Failed to lock %Document%. %ErrorDescription%'; fa = 'Failed to lock %Document%. %ErrorDescription%';
						|it = 'Non è stato possibile bloccare %Document%. %ErrorDescription%';
						|pl = 'Nie udało się zablokować %Document%, %ErrorDescription%';
						|tr = '%Document% engellenemedi. %ErrorDescription%'");
		ErrorText = StrReplace(ErrorText, "%Document%", DocumentRef);
		ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
		CommonClientServer.MessageToUser(ErrorText, DocumentRef);
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function FindCreatedDocumentByType(Form, DocumentType, ArrayOfFoundDocuments) Export
	
	For Each CurRow In Form.Object.Documents Do
		If TypeOf(CurRow.Document) = DocumentType
			And ArrayOfFoundDocuments.Find(CurRow.Document) = Undefined Then
			
			Return CurRow;
			
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Parameters:
// 	Form                     - ClientApplicationForm
// 	ManagerOfDocument         - DocumentManager
// 	DocumentType              - Type
// 	ArrayOfFoundDocuments - Array of DocumentRef
// 	NewDocumentIsCreated       - Boolean
// 	TableRow             - ValueTableRow
// Returns:
// 	DocumentObject
//
Function FindCreateDocument(Form, ManagerOfDocument, DocumentType, ArrayOfFoundDocuments, NewDocumentIsCreated, TableRow = Undefined) Export
	
	If Form.DocumentsAreCreated Then
		TableRow = FindCreatedDocumentByType(Form, DocumentType, ArrayOfFoundDocuments);
		
		If TableRow <> Undefined
			And LockDocument_(TableRow.Document) Then
			
			DocumentObject = TableRow.Document.GetObject();
			If Not DocumentObject = Undefined And DocumentObject.DeletionMark Then
				DocumentObject.SetDeletionMark(False);
			EndIf;
			
			ArrayOfFoundDocuments.Add(TableRow.Document);
			
		EndIf;
	EndIf;
	
	If DocumentObject = Undefined Then
		NewDocumentIsCreated = True;
		
		DocumentObject = ManagerOfDocument.CreateDocument();
		DocumentObject.Date = CurrentSessionDate();
	EndIf;
	
	Return DocumentObject;
	
EndFunction

Procedure AddRowToGeneratedDocumentsTable(Form, DocumentRef, Order, State = 0, Print = False) Export
	
	DocumentsTable = Form.Object.Documents; // TabularSection 
	
	NewRow = DocumentsTable.Add();
	
	FillPropertyValues(NewRow, DocumentRef);
	
	NewRow.Document  = DocumentRef;
	NewRow.State = State;
	NewRow.Order   = Order;
	NewRow.Print    = Print;
	
EndProcedure

Procedure UpdateRowInGeneratedDocumentsTable(TableRow, DocumentRef, Order, State = 0) Export
	
	FillPropertyValues(TableRow, DocumentRef);
	
	TableRow.State = State;
	TableRow.Order   = Order;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region SalesOrder

// Parameters:
// 	DocumentObject - DocumentObject.SalesOrder
// 	Basis - DocumentRef.CommercialProposalForCustomer
//
Procedure FillingCustomerSOrderBasedOnCommercialOfferToCustomer(DocumentObject, Val Basis)
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	CommercialProposalForCustomer.Ref AS DocumentBasis,
	|	CommercialProposalForCustomer.Client AS Partner,
	|	CommercialProposalForCustomer.Counterparty AS Counterparty,
	|	CommercialProposalForCustomer.ContactPerson AS ContactPerson,
	|	CommercialProposalForCustomer.SalesOpportunity AS SalesOpportunity,
	|	CommercialProposalForCustomer.Currency AS Currency,
	|	CommercialProposalForCustomer.DocumentAmount AS DocumentAmount,
	|	CommercialProposalForCustomer.Organization AS Organization,
	|	CommercialProposalForCustomer.PriceIncludesVAT AS PriceIncludesVAT,
	|	CommercialProposalForCustomer.Taxation AS VATTaxation,
	|	CommercialProposalForCustomer.BusinessOperation AS BusinessOperation,
	|	CommercialProposalForCustomer.Status AS DocumentStatus,
	|	CommercialProposalForCustomer.LoyaltyCard AS LoyaltyCard,
	|	NOT CommercialProposalForCustomer.Posted       AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN CommercialProposalForCustomer.Status = VALUE(Enum.StatusesOfCommercialProposalsForCustomers.Valid)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsStatus
	|FROM
	|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
	|WHERE
	|	CommercialProposalForCustomer.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CommercialOfferToClientGoods.LineNumber                          AS LineNumber,
	|	CommercialOfferToClientGoods.ConnectionKey                             AS ConnectionKey,
	|	CommercialOfferToClientGoods.Products                          AS Products,
	|	CommercialOfferToClientGoods.Products.DescriptionFull       AS FullNameOfProduct,
	|	CommercialOfferToClientGoods.Characteristic                        AS Characteristic,
	|	CommercialOfferToClientGoods.Characteristic.DescriptionFull     AS FullNameOfTheCharacteristic_3,
	|	CommercialOfferToClientGoods.Products.SaleRegistrationOption AS SaleRegistrationOption,
	|	CommercialOfferToClientGoods.UnitOfMeasure                      AS Package,
	|	CommercialOfferToClientGoods.Count                            AS NumberOfPackages,
	|	CommercialOfferToClientGoods.Count * CASE
	|		WHEN CommercialOfferToClientGoods.UnitOfMeasure = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END                                                     AS Count,
	|	CommercialOfferToClientGoods.PriceKind              AS PriceKind,
	|	CommercialOfferToClientGoods.Price                 AS Price,
	|	CommercialOfferToClientGoods.PercentRateOfManualDiscount  AS PercentRateOfManualDiscount,
	|	CommercialOfferToClientGoods.ManualDiscount    AS ManualDiscount,
	|	CommercialOfferToClientGoods.VATRate            AS VATRate,
	|	CommercialOfferToClientGoods.VATAmount             AS VATAmount,
	|	CommercialOfferToClientGoods.AmountIncludingVAT            AS AmountIncludingVAT,
	|	CommercialOfferToClientGoods.Sum                AS Sum,
	|	CommercialOfferToClientGoods.ProductsInSet   AS ProductsInSet,
	|	CommercialOfferToClientGoods.ItemVariantOfSet AS ItemVariantOfSet,
	|	CASE
	|		WHEN CommercialOfferToClientGoods.Ref.OptionToSpecifyDeliveryTerm = 1
	|			THEN CommercialOfferToClientGoods.DeliveryPeriodDays
	|		ELSE DATEDIFF(CAST(CommercialOfferToClientGoods.DeliveryPeriodDays AS DATE), &CurrentDate, DAY)
	|	END                                                     AS DeliveryPeriodDays
	|FROM
	|	Document.CommercialProposalForCustomer.Goods AS CommercialOfferToClientGoods
	|WHERE
	|	CommercialOfferToClientGoods.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CommercialProposalForCustomerDiscountsMarkups.ConnectionKey AS ConnectionKey,
	|	CommercialProposalForCustomerDiscountsMarkups.DiscountMarkup AS DiscountMarkup,
	|	CommercialProposalForCustomerDiscountsMarkups.Sum AS Sum
	|FROM
	|	Document.CommercialProposalForCustomer.DiscountsMarkups AS CommercialProposalForCustomerDiscountsMarkups
	|WHERE
	|	CommercialProposalForCustomerDiscountsMarkups.Ref = &Basis";

	Query.SetParameter("Basis",Basis);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	Query.Text = StrReplace(Query.Text,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CommercialOfferToClientGoods.UnitOfMeasure",
			"CommercialOfferToClientGoods.Products"));
	
	QueryResult = Query.ExecuteBatch();
	HeaderSelection = QueryResult[0].Select();
	HeaderSelection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfCommercialProposalsForCustomers.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.DocumentBasis,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(DocumentObject, HeaderSelection);
	DocumentObject.VATTaxation = 
		CommercialProposalsDocumentsClientServerTM.TaxationOfVATOnTaxationOfCommercialOffers(HeaderSelection.VATTaxation);
	DocumentObject.BusinessOperation = 
		CommercialProposalsDocumentsClientServerTM.BusinessTransactionOfDocumentCommercialOfferToClient(HeaderSelection.BusinessOperation);
	
	If GetFunctionalOption("ToUseTermsOfSales") Then
		FillInCustomerSOrderAgreementBasedOnStatistics(DocumentObject);
		If Not ValueIsFilled(DocumentObject.Terms) Then
			
			FilterParameters = New Structure;
			OperationArray = New Array;
			OperationArray.Add(DocumentObject.BusinessOperation);
			FilterParameters.Insert("BusinessTransactions",             OperationArray);
			FilterParameters.Insert("UseFirstSatisfying", True);
			DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(DocumentObject.Partner, FilterParameters);
			
			If TypeOf(DefaultSalesTerms) = Type("Structure")
				And DefaultSalesTerms.Property("Terms") Then
				DocumentObject.Terms = DefaultSalesTerms.Terms;
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(DocumentObject.Terms) Then
			SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(DocumentObject.Terms, True);
			DocumentObject.PaymentSchedule = SalesTermsAndConditions.PaymentSchedule;
		EndIf;
		
	EndIf;
	
	GoodsTable = QueryResult[1].Unload();
	GoodsTable.Sort("LineNumber Asc");
	
	For Each CurRow In GoodsTable Do
		
		NewRow = DocumentObject.Goods.Add();
		FillPropertyValues(NewRow, CurRow);
		
		If CurRow.SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoiceServices Then
			NewRow.Content = ProductsClientServer.PresentationOfProductsForPrinting(
				CurRow.FullNameOfProduct, 
				CurRow.FullNameOfTheCharacteristic_3);
		EndIf;
		
	EndDo;
	
	DocumentObject.Contract = SalesServer.GetDefaultContract(DocumentObject, DocumentObject.BusinessOperation, DocumentObject.Currency);
	
	SalesServer.FillInBankAccountsUnderAgreement(DocumentObject.Contract, DocumentObject.BankAccount, DocumentObject.CounterpartyBankAccount);
	
	If ValueIsFilled(DocumentObject.Contract) Then
		DocumentObject.FinancialAccountingGroup = Common.ObjectAttributeValue(DocumentObject.Contract, "FinancialAccountingGroup");
	EndIf;
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("ApplyToObject",                True);
	ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
	ParametersStructure1.Insert("RestoreManagedDiscounts", True);
	ParametersStructure1.Insert("ManagedDiscounts", New ValueList);
	
	DocumentObject.DiscountsMarkups.Load(QueryResult[2].Unload());
	DiscountsMarkupsServer.Calculate(DocumentObject, ParametersStructure1);
	
EndProcedure

Procedure FillInCustomerSOrderAgreementBasedOnStatistics(Object)
	
	AttributesDetails1 = New Structure;
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Currency, PriceIncludesVAT";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Terms", Parameters);
	ObjectsFillingByStatistics.FillObjectAttributes(Object, Undefined, AttributesDetails1);
	
EndProcedure

#EndRegion

#Region SalesWizard

// Parameters:
//  Form - ClientApplicationForm
//  ArrayOfFoundDocuments - Array of DocumentObject
//
Function CreateDocumentCommercialOfferToClientSalesAssistant(Form, ArrayOfFoundDocuments, Cancel)
	
	NewDocumentIsCreated = False;
	TableRow = Undefined;
	
	DocumentObject = Sales.FindCreateDocument(Form,
		                                          Documents.CommercialProposalForCustomer,
		                                          Type("DocumentRef.CommercialProposalForCustomer"),
		                                          ArrayOfFoundDocuments,
		                                          NewDocumentIsCreated,
		                                          TableRow);
	
	FillPropertyValues(DocumentObject, Form.Object, , "Date");
	DocumentObject.Client                              = Form.Object.Partner;
	DocumentObject.OptionToSpecifyDeliveryTerm        = Enums.DeliveryPeriodOptionsForCommercialProposals.NotisSpecified;
	DocumentObject.OtherAdditionalInformationText = Form.Object.AdditionalInformation;
	DocumentObject.Taxation                     = CommercialProposalsDocumentsClientServerTM.TaxationOfCommercialProposalsForVATTaxation(Form.Object.VATTaxation);
	DocumentObject.Status                              = Form.Object.CommercialProposalStatus;
	DocumentObject.DeliveryTermsText                = Form.Object.AdditionalDeliveryInformation;
	DocumentObject.BusinessOperation               = CommercialProposalsDocumentsClientServerTM.BusinessTransactionOfDocumentCommercialOfferToClient(Form.Object.BusinessOperation);
	DocumentObject.PartialSaleAllowed             = Not Form.Object.NotPartialSaleAllowed;
	DocumentObject.Status                              = Form.Object.CommercialProposalStatus;
	
	If Form.Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or Form.Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
		Then
		DocumentObject.BusinessOperation = Enums.KindsOfCommercialProposalProcedures.ConsignmentProcurement;
	Else
		DocumentObject.BusinessOperation = Enums.KindsOfCommercialProposalProcedures.PurchaseFromSupplier;
	EndIf;
	
	For Each LineProducts_ In Form.Object.Goods Do
		
		NewRow = DocumentObject.Goods.Add();
		FillPropertyValues(NewRow, LineProducts_);
		
		NewRow.Count      = LineProducts_.NumberOfPackages;
		NewRow.UnitOfMeasure = LineProducts_.Package;
		
	EndDo;
	DocumentObject.Goods.Load(Form.Object.Goods.Unload());
	
	DocumentObject.DiscountsMarkups.Load(Form.Object.DiscountsMarkups.Unload());
	DocumentObject.AdditionalAttributes.Load(Form.Object.AdditionalAttributesOfCommercialProposal.Unload());
	
	Try
		DocumentObject.Write(DocumentWriteMode.Posting);
		If NewDocumentIsCreated Then
			Sales.AddRowToGeneratedDocumentsTable(
				Form,
				DocumentObject.Ref,
				1,
				,
				False);
			ArrayOfFoundDocuments.Add(DocumentObject.Ref);
		ElsIf TableRow <> Undefined Then
			Sales.UpdateRowInGeneratedDocumentsTable(
				TableRow,
				DocumentObject.Ref,
				1);
		EndIf;
	Except
		Message = Undefined;
		CommonClientServer.AddUserError(Message,"Object",ErrorDescription(), "");
		CommonClientServer.ReportErrorsToUser(Message, Cancel);
		Cancel = True;
	EndTry;
	
	Return DocumentObject;
	
EndFunction

#EndRegion

#EndRegion
