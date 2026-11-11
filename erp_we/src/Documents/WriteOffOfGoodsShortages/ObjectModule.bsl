#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function creates temporary tables with document data.
// Used for filling in inventory types.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Organization AS Organization,
	|	&Date AS Date,
	|	&Warehouse AS Warehouse,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	&VATActivityType AS VATTaxation,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.Users.EmptyRef) AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Enum.BusinessTransactions.GoodsConsumption) AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END AS QuantityByGBRN,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber,
	|	TableOfGoods.Products,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count,
	|	TableOfGoods.QuantityByGBRN,
	|	&Warehouse AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.ExciseTaxAmount AS ExciseTaxAmount,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	&Warehouse AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.ExciseTaxAmount AS ExciseTaxAmount,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Dimension.Products,
	|	Dimension.Characteristic,
	|	Dimension.Series
	|";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("VATActivityType", VATActivityType);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		TableOfGoods,
		Query.Text,
		"&FieldTextTableOfGoodsQuantityByGBRN_",
		"TableOfGoods",
		"QuantityByGBRN",
		"TableOfGoods.QuantityByGBRN",
		"0");
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		TableOfGoods,
		Query.Text,
		"&FieldTextTableOfGoodsCCDNumber_",
		"TableOfGoods",
		"CCDNumber",
		"TableOfGoods.CCDNumber",
		"VALUE(Catalog.CCDNumbers.EmptyRef)");
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

// The procedure creates a temporary table of products with separate accounting Analytics.
//
// Parameters:
//  TempTablesManager	 - TempTablesManager	 - temporary table Manager that will contain the created table.
//
Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus = 14
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfGoods.Warehouse,
	|
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.Users.EmptyRef) AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableOfGoods.Purpose AS Purpose,
	|
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|
	|	TableOfGoods.Count AS Count
	|	
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|
	|	LEFT JOIN
	|		DocumentDataTable AS DocumentDataTable
	|	ON
	|		TRUE
	|;
	|");
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

// The procedure fills in the tabular part of the document for the remainder of the registration of surpluses and shortages.
//
// Parameters:
//  DocumentBasis	 - DocumentRef.InventoryRecount, DocumentRef.GoodsShortageNote - basis for filling in.
//
Procedure FillInTablePart(DocumentBasis = Undefined) Export
	
	Query = New Query;
	
	UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse);
	
	If UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
		
		If TypeOf(DocumentBasis) = Type("DocumentRef.InventoryRecount") Then
			
			Query.Text =
			"SELECT
			|	BaseGoods.Recorder				AS Ref,
			|	BaseGoods.Products			AS Products,
			|	BaseGoods.Characteristic			AS Characteristic,
			|	BaseGoods.Purpose				AS Purpose,
			|	BaseGoods.Series					AS Series,
			|	SUM(BaseGoods.ToCertificateRegistration)	AS Count
			|INTO GoodsReadyForRegistration
			|FROM
			|	AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages AS BaseGoods
			|
			|WHERE
			|	BaseGoods.Active
			|	AND BaseGoods.Recorder = &DocumentBasis
			|	AND BaseGoods.RecordType = VALUE(AccumulationRecordType.Expense)
			|
			|GROUP BY
			|	BaseGoods.Recorder,
			|	BaseGoods.Products,
			|	BaseGoods.Characteristic,
			|	BaseGoods.Purpose,
			|	BaseGoods.Series
			|
			|INDEX BY
			|	Ref,
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	Series
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 1
			|SELECT DISTINCT
			|	CompletedDocuments_4.Ref AS Ref
			|INTO CompletedDocuments_4
			|FROM
			|	Document.WriteOffOfGoodsShortages.Goods AS DecoratedProducts
			|		INNER JOIN Document.WriteOffOfGoodsShortages AS CompletedDocuments_4
			|		ON DecoratedProducts.Ref = CompletedDocuments_4.Ref
			|
			|WHERE
			|	CompletedDocuments_4.Posted
			|	AND CompletedDocuments_4.Ref <> &CurrentDocument
			|	AND (CompletedDocuments_4.InventoryRecount, DecoratedProducts.Products, DecoratedProducts.Characteristic,
			|		DecoratedProducts.Purpose, DecoratedProducts.Series) IN
			|			(SELECT
			|				GoodsForRegistration.Ref			AS Ref,
			|				GoodsForRegistration.Products		AS Products,
			|				GoodsForRegistration.Characteristic	AS Characteristic,
			|				GoodsForRegistration.Purpose		AS Purpose,
			|				GoodsForRegistration.Series				AS Series
			|			FROM
			|				GoodsReadyForRegistration AS GoodsForRegistration)
			|
			|INDEX BY
			|	Ref
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 2
			|SELECT DISTINCT
			|	DecoratedProducts.Products					AS Products,
			|	DecoratedProducts.Characteristic				AS Characteristic,
			|	DecoratedProducts.Purpose					AS Purpose,
			|	DecoratedProducts.Series							AS Series,
			|	SUM(DecoratedProducts.ToCertificateRegistrationReceipt)	AS Count
			|INTO DecoratedProducts
			|FROM
			|	AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Turnovers(,
			|			,
			|			Recorder,
			|			Warehouse = &Warehouse
			|				AND (Products, Characteristic, Purpose, Series) IN
			|						(SELECT
			|							GoodsForRegistration.Products		AS Products,
			|							GoodsForRegistration.Characteristic	AS Characteristic,
			|							GoodsForRegistration.Purpose		AS Purpose,
			|							GoodsForRegistration.Series				AS Series
			|						FROM
			|							GoodsReadyForRegistration AS GoodsForRegistration)
			|	
			|	) AS DecoratedProducts
			|
			|WHERE
			|	DecoratedProducts.Recorder IN
			|			(SELECT
			|				CompletedDocuments_4.Ref AS Ref
			|			FROM
			|				CompletedDocuments_4 AS CompletedDocuments_4)
			|
			|GROUP BY
			|	DecoratedProducts.Products,
			|	DecoratedProducts.Characteristic,
			|	DecoratedProducts.Purpose,
			|	DecoratedProducts.Series
			|
			|HAVING
			|	SUM(DecoratedProducts.ToCertificateRegistrationReceipt) > 0
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	Series
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 3
			|SELECT
			|	BaseGoods.Products	AS Products,
			|	BaseGoods.Characteristic	AS Characteristic,
			|	BaseGoods.Purpose		AS Purpose,
			|	BaseGoods.Series			AS Series,
			|	BaseGoods.Count - ISNULL(DecoratedProducts.Count, 0) AS Count
			|INTO BalanceOfGoodsToBeProcessed
			|FROM
			|	GoodsReadyForRegistration AS BaseGoods
			|		LEFT JOIN DecoratedProducts AS DecoratedProducts
			|		ON BaseGoods.Products = DecoratedProducts.Products
			|			AND BaseGoods.Characteristic = DecoratedProducts.Characteristic
			|			AND BaseGoods.Purpose = DecoratedProducts.Purpose
			|			AND BaseGoods.Series = DecoratedProducts.Series
			|
			|WHERE
			|	BaseGoods.Count - ISNULL(DecoratedProducts.Count, 0) > 0
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	Series
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 4
			|SELECT
			|	GoodsForRegistration.Products		AS Products,
			|	GoodsForRegistration.Characteristic	AS Characteristic,
			|	GoodsForRegistration.Purpose		AS Purpose,
			|	GoodsForRegistration.Series				AS Series,
			|	SUM(GoodsForRegistration.Count)	AS Count
			|INTO GoodsForRegistration
			|FROM
			|	(SELECT
			|		GoodsForRegistration.Products				AS Products,
			|		GoodsForRegistration.Characteristic			AS Characteristic,
			|		GoodsForRegistration.Purpose				AS Purpose,
			|		GoodsForRegistration.Series						AS Series,
			|		-GoodsForRegistration.ToCertificateRegistrationBalance	AS Count
			|	FROM
			|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Balance(,
			|				Warehouse = &Warehouse
			|					AND (Products, Characteristic, Purpose, Series) IN
			|							(SELECT
			|								GoodsForRegistration.Products		AS Products,
			|								GoodsForRegistration.Characteristic	AS Characteristic,
			|								GoodsForRegistration.Purpose		AS Purpose,
			|								GoodsForRegistration.Series				AS Series
			|							FROM
			|								BalanceOfGoodsToBeProcessed AS GoodsForRegistration)) AS GoodsForRegistration
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsForRegistration.Products		AS Products,
			|		GoodsForRegistration.Characteristic	AS Characteristic,
			|		GoodsForRegistration.Purpose		AS Purpose,
			|		GoodsForRegistration.Series				AS Series,
			|		GoodsForRegistration.ToCertificateRegistration	AS Count
			|	FROM
			|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages AS GoodsForRegistration
			|	
			|	WHERE
			|		GoodsForRegistration.Active
			|		AND GoodsForRegistration.Recorder = &CurrentDocument) AS GoodsForRegistration
			|
			|GROUP BY
			|	GoodsForRegistration.Products,
			|	GoodsForRegistration.Characteristic,
			|	GoodsForRegistration.Purpose,
			|	GoodsForRegistration.Series
			|
			|HAVING
			|	SUM(GoodsForRegistration.Count) > 0
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	Series
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 5
			|SELECT
			|	GoodsForRegistration.Products		AS Products,
			|	GoodsForRegistration.Characteristic	AS Characteristic,
			|	GoodsForRegistration.Series				AS Series,
			|	GoodsForRegistration.Purpose		AS Purpose,
			|	CASE
			|		WHEN GoodsForRegistration.Count > BalanceOfGoodsToBeProcessed.Count
			|			THEN BalanceOfGoodsToBeProcessed.Count
			|		ELSE GoodsForRegistration.Count
			|	END								AS Count
			|FROM
			|	GoodsForRegistration AS GoodsForRegistration
			|		INNER JOIN BalanceOfGoodsToBeProcessed AS BalanceOfGoodsToBeProcessed
			|		ON GoodsForRegistration.Products = BalanceOfGoodsToBeProcessed.Products
			|			AND GoodsForRegistration.Characteristic = BalanceOfGoodsToBeProcessed.Characteristic
			|			AND GoodsForRegistration.Purpose = BalanceOfGoodsToBeProcessed.Purpose
			|			AND GoodsForRegistration.Series = BalanceOfGoodsToBeProcessed.Series";
			
		Else
			
			Query.Text =
			"SELECT
			|	GoodsForRegistration.Products		AS Products,
			|	GoodsForRegistration.Characteristic	AS Characteristic,
			|	GoodsForRegistration.Purpose		AS Purpose,
			|	GoodsForRegistration.Series				AS Series,
			|	SUM(GoodsForRegistration.Count)	AS Count
			|INTO GoodsForRegistration
			|FROM
			|	(SELECT
			|		GoodsForRegistration.Products				AS Products,
			|		GoodsForRegistration.Characteristic			AS Characteristic,
			|		GoodsForRegistration.Purpose				AS Purpose,
			|		GoodsForRegistration.Series						AS Series,
			|		-GoodsForRegistration.ToCertificateRegistrationBalance	AS Count
			|	FROM
			|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Balance(, Warehouse = &Warehouse) AS GoodsForRegistration
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsForRegistration.Products		AS Products,
			|		GoodsForRegistration.Characteristic	AS Characteristic,
			|		GoodsForRegistration.Purpose		AS Purpose,
			|		GoodsForRegistration.Series				AS Series,
			|		GoodsForRegistration.ToCertificateRegistration	AS Count
			|	FROM
			|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages AS GoodsForRegistration
			|	
			|	WHERE
			|		GoodsForRegistration.Active
			|		AND GoodsForRegistration.Recorder = &CurrentDocument) AS GoodsForRegistration
			|
			|GROUP BY
			|	GoodsForRegistration.Products,
			|	GoodsForRegistration.Characteristic,
			|	GoodsForRegistration.Purpose,
			|	GoodsForRegistration.Series
			|
			|HAVING
			|	SUM(GoodsForRegistration.Count) > 0
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	Series
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 1
			|SELECT DISTINCT
			|	GoodsForRegistration.Products		AS Products,
			|	GoodsForRegistration.Characteristic	AS Characteristic,
			|	GoodsForRegistration.Series				AS Series,
			|	GoodsForRegistration.Purpose		AS Purpose,
			|	GoodsForRegistration.Count		AS Count
			|FROM
			|	GoodsForRegistration AS GoodsForRegistration
			|		LEFT JOIN AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages AS BaseGoods
			|		ON BaseGoods.Active
			|			AND BaseGoods.Recorder = &DocumentBasis
			|			AND GoodsForRegistration.Products = BaseGoods.Products
			|			AND GoodsForRegistration.Characteristic = BaseGoods.Characteristic
			|			AND GoodsForRegistration.Purpose = BaseGoods.Purpose
			|			AND GoodsForRegistration.Series = BaseGoods.Series
			|
			|WHERE
			|	NOT BaseGoods.Products IS NULL";
			
		EndIf;
		
		Query.SetParameter("Warehouse", Warehouse);
		Query.SetParameter("CurrentDocument", Ref);
		
	Else
		
		// There will only be a recalculation in an irregular warehouse.
		Query.Text = 
		"SELECT
		|	ConversionProducts.Products	AS Products,
		|	ConversionProducts.Characteristic	AS Characteristic,
		|	ConversionProducts.Series			AS Series,
		|	ConversionProducts.Purpose		AS Purpose,
		|	SUM(ConversionProducts.Count - ConversionProducts.CountReal)	AS Count
		|FROM
		|	Document.InventoryRecount.Goods AS ConversionProducts
		|
		|WHERE
		|	ConversionProducts.Ref = &DocumentBasis
		|
		|GROUP BY
		|	ConversionProducts.Products,
		|	ConversionProducts.Characteristic,
		|	ConversionProducts.Purpose,
		|	ConversionProducts.Series
		|
		|HAVING
		|	SUM(ConversionProducts.Count - ConversionProducts.CountReal) > 0";
		
	EndIf;
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	If Not Result.IsEmpty() Then
		Goods.Load(Result.Unload());
	ElsIf ValueIsFilled(DocumentBasis) Then
		MessageText = NStr("vi = 'Trong chứng từ ""%DocumentBasis%"" không có hàng hóa cần lập chứng từ ghi giảm.';
							|ru = 'В документе ""%DocumentBasis%"" отсутствуют товары, по которым необходимо оформить списание.';
							|en = 'Goods for which write-off registration is required are absent in document ""%DocumentBasis%"".'; fa = 'Goods for which write-off registration is required are absent in document ""%DocumentBasis%"".';
							|it = 'Nel documento ""%DocumentBasis%"" mancano le merci, in base alle quali deve essere formato lo storno.';
							|pl = 'W dokumencie ""%DocumentBasis%"" brak towarów, dla których należy wykonać wyksięgowanie.';
							|tr = '""%DocumentBasis%"" belgesinde iptal edilmesi gereken hiçbir ürün mevcut değil.'");
		MessageText = StrReplace(MessageText, "%DocumentBasis%", DocumentBasis);
		
		CommonClientServer.MessageToUser(MessageText, ThisObject);
	EndIf;
	
EndProcedure

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
//
Procedure FillInProductTrackingForm() Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();

EndProcedure

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.WriteOffOfGoodsShortages - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes());
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.WriteOffOfGoodsShortages.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	If DocumentTables <> Undefined Then
		FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables);
		AdditionalProperties.Insert("TablesOfFillingOfTypesOfStocksAtExchange", DocumentTables);
	EndIf;
	
	FillStockTypes(Cancel);
	AdditionalProperties.Delete("TablesOfFillingOfTypesOfStocksAtExchange");
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	DocumentBasis = Undefined;
	FillInTablePart = True;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("Basis")
				And TypeOf(FillingData.Basis) = Type("DocumentRef.GoodsQualityControlCertificate") Then
			FillInCertificateOfQualityControl(FillingData);
		ElsIf FillingData.Property("DiscrepancyCertificate")
			And FillingData.Property("BasisOfAct") Then
			
			If TypeOf(FillingData.DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
				FillInDocumentOnBasisOfAcceptanceCertificate(FillingData);
			ElsIf TypeOf(FillingData.DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
				FillInDocumentOnBasisOfActOfShipment(FillingData);
			ElsIf TypeOf(FillingData.DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
				FillInDocumentOnMovementActBasis(FillingData);
			EndIf;
			DocumentBasis = FillingData.DiscrepancyCertificate;
			FillInTablePart = False;

		ElsIf Documents.ReconcileOpeningBalancesByWarehouses.FillInWriteOffOfShortageOfGoodsBasedOnReconciliation(ThisObject, FillingData) Then
			
			FillInTablePart = False;
			
		Else
			
			FillPropertyValues(ThisObject,FillingData);
			FillInTablePart = Not FillingData.Property("DoNotFillInWrongPart");
			
		EndIf;
	
	ElsIf TypeOf(FillingData) = Type("DocumentRef.WriteOffOfGoodsShortages") Then
		
		FillInTablePart = False;
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	ElsIf Documents.AllRefsType().ContainsType(TypeOf(FillingData))
		And FillingData <> Undefined Then 	
		If TypeOf(FillingData) = Type("DocumentRef.InventoryRecount") Then 
			ResultingStructure = Common.ObjectAttributesValues(FillingData, "Status, Warehouse");
			If ResultingStructure.Status <> Enums.InventoryRecountStatuses.Completed2 Then 
				MessageText = NStr("vi = 'Chứng từ ""%DocumentRecalculate%"" đang có trạng thái ""%StatusOfRecalculation%"". Cho phép nhập chứng từ ""%DocumentAct%"" trên cơ sở chỉ đối với trạng thái ""%StatusCompleted_%"".';
									|ru = 'Документ ""%DocumentRecalculate%"" находится в статусе ""%StatusOfRecalculation%"". Ввод документа ""%DocumentAct%"" на основании разрешен только в статусе ""%StatusCompleted_%"".';
									|en = 'Document ""%DocumentRecalculate%"" is in status ""%StatusOfRecalculation%"".  ""%DocumentAct%"" can only be generated from base documents in status ""%StatusCompleted_%"".'; fa = 'Document ""%DocumentRecalculate%"" is in status ""%StatusOfRecalculation%"".  ""%DocumentAct%"" can only be generated from base documents in status ""%StatusCompleted_%"".';
									|it = 'Il documento ""%DocumentRecalculate%"" è nello stato ""%StatusOfRecalculation%"". Immissione del documento ""%DocumentAct%"" in base alla casuale è consentita solo nello stato di ""%StatusCompleted_%"".';
									|pl = 'Dokument ""%DocumentRecalculate%"" ma status ""%StatusOfRecalculation%"". Wprowadzenie dokumentu ""%DocumentAct%"" na podstawie jest dozwolony tylko ze statusem ""%StatusCompleted_%"".';
									|tr = '""%DocumentRecalculate%"" belgesi ""%StatusOfRecalculation%"" durumundadır. ""%DocumentAct%"" esaslı belge girişine yalnız ""%StatusCompleted_%"" durumunda izin verildi.'");
				MessageText = StrReplace(MessageText, "%DocumentRecalculate%", FillingData);
				MessageText = StrReplace(MessageText, "%DocumentAct%", Metadata.Documents.WriteOffOfGoodsShortages.Synonym);
				MessageText = StrReplace(MessageText, "%StatusCompleted_%", Enums.InventoryRecountStatuses.Completed2);
				MessageText = StrReplace(MessageText, "%StatusOfRecalculation%", ResultingStructure.Status);
				Raise MessageText;
			EndIf;
			Warehouse = ResultingStructure.Warehouse;
			InventoryRecount = FillingData;
		EndIf;
				
		If Not ValueIsFilled(Warehouse) And Common.HasObjectAttribute("Warehouse", FillingData.Metadata()) Then
			Warehouse = Common.ObjectAttributeValue(FillingData, "Warehouse");
		EndIf;
		
		DocumentBasis = FillingData;
	
	EndIf;
	
	WriteOffOfGoodsShortagesLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffOfGoodsShortages.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument(FillingData);
	
	If FillInTablePart Then 
		FillInTablePart(DocumentBasis);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
														ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.WriteOffOfGoodsShortages));

	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.WriteOffOfGoodsShortages.AccountingAccountSettings_());
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffOfGoodsShortages.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	WriteOffOfGoodsShortagesLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	WriteOffOfGoodsShortagesLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.WriteOffOfGoodsShortages),
												Cancel,
												NotCheckedAttributeArray);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffOfGoodsShortages.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes,
		ItemsAndDimensionsSelectionParameters);
	
	WriteOffOfGoodsShortagesLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	WriteOffOfGoodsShortagesLocalization.Posting(ThisObject, Cancel, PostingMode);
	If Not Cancel Then
		ExcisableGoodsAccounting.CreateTaskToRecordAmountOfExciseTax(ThisObject);
		OtherAssetsLiabilitiesServer.CreateTaskForNonOperationalDocumentExecution(ThisObject);
	EndIf;
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	WriteOffOfGoodsShortagesLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	InitializeDocument();
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	
	If InventoryKinds.Count() > 0 Then
		InventoryKinds.Clear();
	EndIf;
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "InventoryKinds");
	
	WriteOffOfGoodsShortagesLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	Author         = Users.CurrentUser();
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	If Not ValueIsFilled(SourseOfInformationAboutPricesForPrinting) Then 
		SourseOfInformationAboutPricesForPrinting = Common.ObjectAttributeValue(Warehouse, "SourseOfInformationAboutPricesForPrinting");
		If Not ValueIsFilled(SourseOfInformationAboutPricesForPrinting) And Not GetFunctionalOption("UseSeveralPriceTypes") Then
			SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost;
		EndIf;
		If SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost Then
			PriceKind = Undefined;
		Else
			PriceKind = Catalogs.Warehouses.AccountingPriceType(Warehouse);
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(FillingData) And TypeOf(Basis) = Type("DocumentRef.ReconcileOpeningBalancesByWarehouses") Then
		Basis = Undefined;
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(VATActivityType) Then
		FillInTypeOfActivityVAT();
	EndIf;
	
EndProcedure

Procedure FillInTypeOfActivityVAT()
	
	FillParameters = Documents.WriteOffOfGoodsShortages.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(VATActivityType, FillParameters);
	
EndProcedure

Procedure FillInCertificateOfQualityControl(FillingData)
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Documents.GoodsQualityControlCertificate.GoodsToCreateBasedOn(
		Query,
		FillingData.Basis,
		FillingData.Warehouse,
		Enums.ActionsOnGoodsInQualityControlCertificate.MakeDebit);
	
	Query.SetParameter("DocumentBasis", FillingData.Basis);
	Query.Text =
		"SELECT
		|	Header.Organization AS Organization,
		|	Header.Department AS Department,
		|	Header.ControlledLotReference AS ControlledLotReference,
		|	Header.Status AS Status
		|FROM
		|	Document.GoodsQualityControlCertificate AS Header
		|WHERE
		|	Header.Ref = &DocumentBasis
		|;
		|
		|////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	CASE
		|		WHEN Goods.BatchesIndicationStatus = 14
		|			THEN Goods.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	Goods.Package AS Package,
		|	SUM(Goods.Count) AS Count,
		|	SUM(Goods.NumberOfPackages) AS NumberOfPackages
		|FROM
		|	Goods AS Goods
		|GROUP BY
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	CASE
		|		WHEN Goods.BatchesIndicationStatus = 14
		|			THEN Goods.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END,
		|	Goods.Package";
		
	ResultsPackage = Query.ExecuteBatch();
	HeaderAttributes = ResultsPackage[0].Select();
	HeaderAttributes.Next();
	QualityControl.RaiseExceptionWhenCreatingBasedOnAct(HeaderAttributes);
	BaseGoods = ResultsPackage[1].Unload();
	
	If BaseGoods.Count() = 0 Then
		ErrorText = NStr("vi = 'Chứng từ %Document% không có hàng hóa với thao tác ""Lập chứng từ ghi giảm"". Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Документ %Document% не содержит товаров c действием ""Оформить списание"". Ввод на основании документа запрещен.';
						|en = 'The ""%Document%"" document does not have any goods with the ""Register write-off"" action. Generation from such base documents is not allowed.'; fa = 'The ""%Document%"" document does not have any goods with the ""Register write-off"" action. Generation from such base documents is not allowed.';
						|it = 'The ""%Document%"" document does not have any goods with the ""Register write-off"" action. Generation from such base documents is not allowed.';
						|pl = 'The ""%Document%"" document does not have any goods with the ""Register write-off"" action. Generation from such base documents is not allowed.';
						|tr = '%Document% belgesi ""Stoktan düş düzenle"" eylemine sahip ürün içermemektedir. Belgeye dayanarak giriş yapılması yasaktır.'");
		ErrorText = StrReplace(ErrorText, "%Document%", FillingData.Basis);
		Raise ErrorText;
	EndIf;
	
	FillPropertyValues(ThisObject, HeaderAttributes, "Organization,Department");
	Basis = FillingData.Basis;
	Warehouse = FillingData.Warehouse;
	
	BaseGoods.Columns.Add("ControlledLotReference");
	If Not WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse) Then
		BaseGoods.FillValues(HeaderAttributes.ControlledLotReference, "ControlledLotReference");
	EndIf;
	Goods.Load(BaseGoods);
	
EndProcedure

Procedure FillInDocumentOnBasisOfAcceptanceCertificate(FillingData)

	UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(FillingData.Warehouse);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DiscrepancyReportFollowingReceipt.Organization AS Organization,
	|	DiscrepancyReportFollowingReceipt.Manager AS EmployeeResponsible,
	|	DiscrepancyReportFollowingReceipt.Department AS Department,
	|	&Warehouse AS Warehouse,
	|	&Basis AS Basis
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|;";
	
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	Query.SetParameter("Warehouse",            FillingData.Warehouse);
	Query.SetParameter("Basis",        FillingData.BasisOfAct);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	HeaderSelection = QueryResult.Select();
	If HeaderSelection.Next() Then
		FillPropertyValues(ThisObject, HeaderSelection);
	EndIf;
	
	// Filling in PM
	
	Query.Text = "
		|SELECT
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count AS Count,
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series,
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatus
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
		|WHERE
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &Ref
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = &Basis
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count > 0
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse = &Warehouse
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses)
		|
		|ORDER BY
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.LineNumber";
		
	Query.SetParameter("Warehouse", FillingData.Warehouse);
	Query.SetParameter("Basis", FillingData.BasisOfAct);
	Query.SetParameter("Ref", FillingData.DiscrepancyCertificate);

	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	If Not Result.IsEmpty() Then

		Goods.Load(Result.Unload());
		
	ElsIf ValueIsFilled(FillingData.DiscrepancyCertificate) Then  

		MessageText = NStr("vi = 'Trong chứng từ ""%DocumentBasis%"" không có hàng hóa cần lập chứng từ ghi giảm.';
							|ru = 'В документе ""%DocumentBasis%"" отсутствуют товары, по которым необходимо оформить списание.';
							|en = 'Goods for which write-off registration is required are absent in document ""%DocumentBasis%"".'; fa = 'Goods for which write-off registration is required are absent in document ""%DocumentBasis%"".';
							|it = 'Nel documento ""%DocumentBasis%"" mancano le merci, in base alle quali deve essere formato lo storno.';
							|pl = 'W dokumencie ""%DocumentBasis%"" brak towarów, dla których należy wykonać wyksięgowanie.';
							|tr = '""%DocumentBasis%"" belgesinde iptal edilmesi gereken hiçbir ürün mevcut değil.'");
		MessageText = StrReplace(MessageText, "%DocumentBasis%", FillingData.DiscrepancyCertificate);
		CommonClientServer.MessageToUser(MessageText, ThisObject);
		
	EndIf;

EndProcedure

Procedure FillInDocumentOnBasisOfActOfShipment(FillingData)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DiscrepancyReportFollowingShipment.Organization   AS Organization,
	|	DiscrepancyReportFollowingShipment.Manager      AS EmployeeResponsible,
	|	DiscrepancyReportFollowingShipment.Department AS Department,
	|	&Warehouse                                      AS Warehouse,
	|	&Basis                                  AS BaseDocumentForDiscrepancyReport,
	|	DiscrepancyReportFollowingShipment.Status        AS StatusAct,
	|	NOT DiscrepancyReportFollowingShipment.Posted   AS ThereAreMistakesActWasCarriedOut,
	|	NOT DiscrepancyReportFollowingShipment.Status IN (
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion)) AS ThereAreErrorsStatusReport
	|FROM
	|	Document.DiscrepancyReportFollowingShipment AS DiscrepancyReportFollowingShipment
	|WHERE
	|	DiscrepancyReportFollowingShipment.Ref = &DiscrepancyCertificate
	|
	|;
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Count AS Count,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.BatchesIndicationStatus
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &Basis
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Count > 0
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse = &Warehouse
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off)
	|
	|ORDER BY
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.LineNumber";
	
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	Query.SetParameter("Warehouse",            FillingData.Warehouse);
	Query.SetParameter("Basis",        FillingData.BasisOfAct);
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	HeaderSelection = QueryBatch[0].Select();
	HeaderSelection.Next();
	
	// According to the act of discrepancies after shipment.
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.Status                   = HeaderSelection.StatusAct;
	CheckParameters.ThereAreErrorsPosted       = HeaderSelection.ThereAreMistakesActWasCarriedOut;
	CheckParameters.ThereAreErrorsStatus         = HeaderSelection.ThereAreErrorsStatusReport;
	CheckParameters.ArrayOfValidStatuses = DiscrepanciesServer.ArrayOfAcceptableStatusesOfReportsOfDiscrepanciesWhenCreatedBasedOn();
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(FillingData.DiscrepancyCertificate, CheckParameters); 
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	QueryResultGoods = QueryBatch[1];
	If Not QueryResultGoods.IsEmpty() Then
		
		Goods.Load(QueryResultGoods.Unload());
		
	ElsIf ValueIsFilled(FillingData.DiscrepancyCertificate) Then  
		
		MessageText = NStr("vi = 'Trong chứng từ ""%SaleOfGoodsAndServices%"" không có hàng hóa cần lập chứng từ ghi giảm.';
							|ru = 'В документе ""%SaleOfGoodsAndServices%"" отсутствуют товары, по которым необходимо оформить списание.';
							|en = 'Goods for which write-off registration is required are absent in the ""%SaleOfGoodsAndServices%"" document.'; fa = 'Goods for which write-off registration is required are absent in the ""%SaleOfGoodsAndServices%"" document.';
							|it = 'Goods for which write-off registration is required are absent in the ""%SaleOfGoodsAndServices%"" document.';
							|pl = 'Goods for which write-off registration is required are absent in the ""%SaleOfGoodsAndServices%"" document.';
							|tr = '""%SaleOfGoodsAndServices%"" belgesinde stoktan düşülmesi gereken ürün bulunmamaktadır.'");
		MessageText = StrReplace(MessageText, "%SaleOfGoodsAndServices%", FillingData.DiscrepancyCertificate);
		CommonClientServer.MessageToUser(MessageText, ThisObject);
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnMovementActBasis(FillingData)

	UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(FillingData.Warehouse);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DiscrepancyReportFollowingReceipt.Organization AS Organization,
	|	DiscrepancyReportFollowingReceipt.Manager AS EmployeeResponsible,
	|	DiscrepancyReportFollowingReceipt.Department AS Department,
	|	&Warehouse AS Warehouse,
	|	&Basis AS Basis
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer AS DiscrepancyReportFollowingReceipt
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|;";
	
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	Query.SetParameter("Warehouse",            FillingData.Warehouse);
	Query.SetParameter("Basis",        FillingData.BasisOfAct);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	HeaderSelection = QueryResult.Select();
	If HeaderSelection.Next() Then
		FillPropertyValues(ThisObject, HeaderSelection);
	EndIf;
	
	// Filling in PM
	
	Query.Text = "
		|SELECT
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count AS Count,
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series,
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatus
		|FROM
		|	Document.DiscrepancyReportFollowingTransfer.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
		|WHERE
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &Ref
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = &Basis
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count > 0
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref.DestinationWarehouse = &Warehouse
		|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)
		|
		|ORDER BY
		|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.LineNumber";
		
	Query.SetParameter("Warehouse", FillingData.Warehouse);
	Query.SetParameter("Basis", FillingData.BasisOfAct);
	Query.SetParameter("Ref", FillingData.DiscrepancyCertificate);

	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	If Not Result.IsEmpty() Then

		Goods.Load(Result.Unload());
		
	ElsIf ValueIsFilled(FillingData.DiscrepancyCertificate) Then  

		MessageText = NStr("vi = 'Trong chứng từ ""%DocumentBasis%"" không có hàng hóa cần lập chứng từ ghi giảm.';
							|ru = 'В документе ""%DocumentBasis%"" отсутствуют товары, по которым необходимо оформить списание.';
							|en = 'Goods for which write-off registration is required are absent in document ""%DocumentBasis%"".'; fa = 'Goods for which write-off registration is required are absent in document ""%DocumentBasis%"".';
							|it = 'Nel documento ""%DocumentBasis%"" mancano le merci, in base alle quali deve essere formato lo storno.';
							|pl = 'W dokumencie ""%DocumentBasis%"" brak towarów, dla których należy wykonać wyksięgowanie.';
							|tr = '""%DocumentBasis%"" belgesinde iptal edilmesi gereken hiçbir ürün mevcut değil.'");
		MessageText = StrReplace(MessageText, "%DocumentBasis%", FillingData.DiscrepancyCertificate);
		CommonClientServer.MessageToUser(MessageText, ThisObject);
		
	EndIf;

EndProcedure

Procedure FillStockTypes(Cancel)
	
	If TypeOf(Basis) = Type("DocumentRef.ReconcileOpeningBalancesByWarehouses") Then
		Return; // the tabular part is filled in according to the data of the foundation document
	EndIf;
	
	SetPrivilegedMode(True);
	
	TempTablesManager		= TemporaryDocumentDataTables();
	RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or InventoriesServer.CheckProductChangesByQuantity(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		NamesOfSummationColumns = "Count, QuantityByGBRN";
		AdditionalProperties.Insert("WriteDownAmountOfExciseTax", FillParameters.CalculateAmountOfExciseTax);
		NamesOfSummationColumns = NamesOfSummationColumns + ", ExciseTaxAmount";
		ExcisableGoodsAccounting.CalculateAmountOfExciseTax(ThisObject, FillParameters, , Cancel);
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber", NamesOfSummationColumns);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InventoryKinds

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Warehouse";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.VATTaxation = VATActivityType;
	FillParameters.ReversedDocument = ReversedDocument;
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "ByAgreementSettings");
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.MaterialOfMaterialProvider, "ByAgreementSettings");
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider, "ByAgreementSettings");
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.ProductsOfMaterialProvider, "ByAgreementSettings");
	If GetFunctionalOption("UseExcisableGoods") Then
		FillParameters.CalculateAmountOfExciseTax = True;
		FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
	EndIf;
	Return FillParameters;
	
EndFunction

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.WriteOffOfGoodsShortages.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.WriteOffOfGoodsShortages.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.GoodsConsumption,
					Warehouse,
					Department,
					Undefined);
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
