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
	|	&BusinessOperation AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	&ReceiveGoodsAtCostTheyWereIssuedFromWarehouse AS ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END AS QuantityByGBRN,
	|	TableOfGoods.Price AS Price,
	|	TableOfGoods.PriceOffBalance AS PriceOffBalance,
	|	TableOfGoods.ForAssignment AS ForAssignment,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
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
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.BatchesIndicationStatus,
	|	TableOfGoods.ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived,
	|	TableOfGoods.Count,
	|	TableOfGoods.QuantityByGBRN,
	|	TableOfGoods.Price,
	|	TableOfGoods.PriceOffBalance,
	|	&Warehouse AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TableOfGoods.ForAssignment AS ForAssignment,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.Sum AS Sum,
	|	TableTypesOfStocks_.AmountOffBalance AS AmountOffBalance,
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
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.Sum AS Sum,
	|	TableTypesOfStocks_.AmountOffBalance AS AmountOffBalance,
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
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.ProductsRecordingAsReceived AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS TaxationOfOrganization,
	|	UNDEFINED AS GoodsOwner,
	|	VALUE(Catalog.TypesOfPrices.EmptyRef) AS PriceKind
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|		OR &RefillInventoryKinds
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
	Query.SetParameter("Posted", Posted);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("ReceiveGoodsAtCostTheyWereIssuedFromWarehouse", ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
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
//	TempTablesManager - TempTablesManager - temporary table Manager
//	that will contain the created table.
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
//  DocumentBasis	 - DocumentRef.InventoryRecount, DocumentRef.DamageNote - basis for filling in.
//
Procedure FillInTablePart(DocumentBasis = Undefined) Export

	Query = New Query;
	
	UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse);
	
	If UseWarehouseManagemantSystemForGoodsSurplusesShortages Then 

		Query.SetParameter("Ref", Ref);
		Query.SetParameter("Warehouse", Warehouse);
		Query.SetParameter("DocumentBasis", DocumentBasis);
		BasedOnRecalculation = TypeOf(DocumentBasis) = Type("DocumentRef.InventoryRecount");
		Query.SetParameter("BasedOnRecalculation", BasedOnRecalculation);
		BasedOnWarrant = TypeOf(DocumentBasis) = Type("DocumentRef.DamageNote");
		Query.SetParameter("BasedOnWarrant", BasedOnWarrant);
		
		Query.Text =
		"SELECT
		|	GoodsForRegistration.Products AS Products,
		|	GoodsForRegistration.Characteristic AS Characteristic,
		|	GoodsForRegistration.Series AS Series,
		|	GoodsForRegistration.Purpose AS Purpose,
		|	GoodsForRegistration.ToCertificateRegistrationBalance AS Count
		|INTO DefectiveGoodsTable
		|FROM
		|	(SELECT
		|		GoodsForRegistration.Products AS Products,
		|		GoodsForRegistration.Characteristic AS Characteristic,
		|		GoodsForRegistration.Series AS Series,
		|		GoodsForRegistration.Purpose AS Purpose,
		|		GoodsForRegistration.ToCertificateRegistrationBalance AS ToCertificateRegistrationBalance
		|	FROM
		|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Balance(, Warehouse = &Warehouse) AS GoodsForRegistration
		|	WHERE
		|		GoodsForRegistration.ToCertificateRegistrationBalance > 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsForRegistration.Products,
		|		GoodsForRegistration.Characteristic,
		|		GoodsForRegistration.Series,
		|		GoodsForRegistration.Purpose,
		|		GoodsForRegistration.ToCertificateRegistration
		|	FROM
		|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages AS GoodsForRegistration
		|	WHERE
		|		GoodsForRegistration.Recorder = &Ref
		|		AND GoodsForRegistration.Active = TRUE
		|		AND GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Expense)) AS GoodsForRegistration
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DefectiveGoodsTable.Products,
		|	DefectiveGoodsTable.Characteristic,
		|	ISNULL(CASE
		|		WHEN &BasedOnRecalculation
		|			THEN RecalculationOfGoods.Series
		|		WHEN &BasedOnWarrant
		|			THEN DamageNoteGoods.Series
		|		ELSE NULL
		|	END, DefectiveGoodsTable.Series) AS Series,
		|	DefectiveGoodsTable.Purpose AS Purpose,
		|	DefectiveGoodsTable.Count AS Count
		|INTO DefectiveGoodsTableWithFilter
		|FROM
		|	DefectiveGoodsTable AS DefectiveGoodsTable
		|		LEFT JOIN Document.InventoryRecount.Goods AS RecalculationOfGoods
		|		ON (&BasedOnRecalculation)
		|			AND DefectiveGoodsTable.Products = RecalculationOfGoods.Products
		|			AND DefectiveGoodsTable.Characteristic = RecalculationOfGoods.Characteristic
		|			AND DefectiveGoodsTable.Purpose = RecalculationOfGoods.Purpose
		|			AND (RecalculationOfGoods.BatchesIndicationStatus <> 14
		|				OR DefectiveGoodsTable.Series = RecalculationOfGoods.Series)
		|			AND (RecalculationOfGoods.Count <> RecalculationOfGoods.CountReal)
		|		LEFT JOIN Document.DamageNote.Goods AS DamageNoteGoods
		|		ON (&BasedOnWarrant)
		|			AND DefectiveGoodsTable.Products = DamageNoteGoods.ProductsRecordingAsReceived
		|			AND DefectiveGoodsTable.Characteristic = DamageNoteGoods.CharacteristicRecordingAsReceived
		|			AND (CASE
		|				WHEN DamageNoteGoods.ForAssignment
		|					THEN DefectiveGoodsTable.Purpose = DamageNoteGoods.Purpose
		|				ELSE DefectiveGoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			END)
		|			AND (DamageNoteGoods.BatchesIndicationStatus <> 14
		|				OR DefectiveGoodsTable.Series = DamageNoteGoods.Series)
		|WHERE
		|	(NOT &BasedOnRecalculation
		|			OR &BasedOnRecalculation
		|				AND NOT RecalculationOfGoods.Products IS NULL 
		|				AND RecalculationOfGoods.Ref = &DocumentBasis)
		|	AND (NOT &BasedOnWarrant
		|			OR &BasedOnWarrant
		|				AND NOT DamageNoteGoods.ProductsRecordingAsReceived IS NULL 
		|				AND DamageNoteGoods.Ref = &DocumentBasis)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsForRegistration.Products AS Products,
		|	GoodsForRegistration.Characteristic AS Characteristic,
		|	GoodsForRegistration.Series AS Series,
		|	GoodsForRegistration.Purpose AS Purpose,
		|	SUM(GoodsForRegistration.ToCertificateRegistrationBalance) AS Count
		|INTO TableOfOriginalProduct
		|FROM
		|	(SELECT
		|		GoodsForRegistration.Products AS Products,
		|		GoodsForRegistration.Characteristic AS Characteristic,
		|		GoodsForRegistration.Purpose AS Purpose,
		|		-GoodsForRegistration.ToCertificateRegistrationBalance AS ToCertificateRegistrationBalance,
		|		GoodsForRegistration.Series AS Series
		|	FROM
		|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Balance(, Warehouse = &Warehouse) AS GoodsForRegistration
		|	WHERE
		|		GoodsForRegistration.ToCertificateRegistrationBalance < 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsForRegistration.Products,
		|		GoodsForRegistration.Characteristic,
		|		GoodsForRegistration.Purpose,
		|		GoodsForRegistration.ToCertificateRegistration,
		|		GoodsForRegistration.Series
		|	FROM
		|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages AS GoodsForRegistration
		|	WHERE
		|		GoodsForRegistration.Recorder = &Ref
		|		AND GoodsForRegistration.Active = TRUE
		|		AND GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)) AS GoodsForRegistration
		|
		|GROUP BY
		|	GoodsForRegistration.Products,
		|	GoodsForRegistration.Characteristic,
		|	GoodsForRegistration.Purpose,
		|	GoodsForRegistration.Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TableOfOriginalProduct.Products,
		|	TableOfOriginalProduct.Characteristic,
		|	ISNULL(CASE
		|		WHEN &BasedOnRecalculation
		|			THEN RecalculationOfGoods.Series
		|		WHEN &BasedOnWarrant
		|			THEN DamageNoteGoods.Series
		|		ELSE NULL
		|	END, TableOfOriginalProduct.Series) AS Series,
		|	TableOfOriginalProduct.Purpose,
		|	TableOfOriginalProduct.Count AS Count
		|INTO SourceItemTableWithFilter
		|FROM
		|	TableOfOriginalProduct AS TableOfOriginalProduct
		|		LEFT JOIN Document.InventoryRecount.Goods AS RecalculationOfGoods
		|		ON (&BasedOnRecalculation)
		|			AND TableOfOriginalProduct.Products = RecalculationOfGoods.Products
		|			AND TableOfOriginalProduct.Characteristic = RecalculationOfGoods.Characteristic
		|			AND TableOfOriginalProduct.Purpose = RecalculationOfGoods.Purpose
		|			AND (RecalculationOfGoods.BatchesIndicationStatus <> 14
		|				OR TableOfOriginalProduct.Series = RecalculationOfGoods.Series)
		|		LEFT JOIN Document.DamageNote.Goods AS DamageNoteGoods
		|		ON (&BasedOnWarrant)
		|			AND TableOfOriginalProduct.Products = DamageNoteGoods.Products
		|			AND TableOfOriginalProduct.Characteristic = DamageNoteGoods.Characteristic
		|			AND TableOfOriginalProduct.Purpose = DamageNoteGoods.Purpose
		|			AND (DamageNoteGoods.BatchesIndicationStatus <> 14
		|				OR TableOfOriginalProduct.Series = DamageNoteGoods.Series)
		|WHERE
		|	(NOT &BasedOnRecalculation
		|			OR &BasedOnRecalculation
		|				AND NOT RecalculationOfGoods.Products IS NULL 
		|				AND RecalculationOfGoods.Ref = &DocumentBasis)
		|	AND (NOT &BasedOnWarrant
		|			OR &BasedOnWarrant
		|				AND NOT DamageNoteGoods.Products IS NULL 
		|				AND DamageNoteGoods.Ref = &DocumentBasis)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DefectiveGoodsTableWithFilter.Products AS ProductsRecordingAsReceived,
		|	DefectiveGoodsTableWithFilter.Characteristic AS CharacteristicRecordingAsReceived,
		|	DefectiveGoodsTableWithFilter.Purpose AS AssignmentGoodsReceipt,
		|	SourceItemTableWithFilter.Products AS Products,
		|	SourceItemTableWithFilter.Characteristic AS Characteristic,
		|	SourceItemTableWithFilter.Purpose AS Purpose,
		|	SourceItemTableWithFilter.Series AS Series
		|FROM
		|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
		|		INNER JOIN DefectiveGoodsTableWithFilter AS DefectiveGoodsTableWithFilter
		|		ON AnotherQualityGoods.OtherQualityGoods = DefectiveGoodsTableWithFilter.Products
		|		INNER JOIN SourceItemTableWithFilter AS SourceItemTableWithFilter
		|		ON AnotherQualityGoods.Products = SourceItemTableWithFilter.Products
		|WHERE
		|	NOT &BasedOnWarrant
		|	AND ISNULL(CAST(SourceItemTableWithFilter.Series AS Catalog.ItemsBatches).Description, """") = ISNULL(CAST(DefectiveGoodsTableWithFilter.Series AS Catalog.ItemsBatches).Description, """")
		|	AND ISNULL(CAST(SourceItemTableWithFilter.Characteristic AS Catalog.ItemsCharacteristics).Description, """") = ISNULL(CAST(DefectiveGoodsTableWithFilter.Characteristic AS Catalog.ItemsCharacteristics).Description, """")
		|	AND (ISNULL(CAST(SourceItemTableWithFilter.Purpose AS Catalog.Assignments).Description, """") = ISNULL(CAST(DefectiveGoodsTableWithFilter.Purpose AS Catalog.Assignments).Description, """")
		|			OR DefectiveGoodsTableWithFilter.Purpose = VALUE(Catalog.Assignments.EmptyRef))
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DamageNoteGoods.ProductsRecordingAsReceived,
		|	DamageNoteGoods.CharacteristicRecordingAsReceived,
		|	CASE
		|		WHEN DamageNoteGoods.ForAssignment
		|			THEN DamageNoteGoods.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END,
		|	DamageNoteGoods.Products,
		|	DamageNoteGoods.Characteristic,
		|	DamageNoteGoods.Purpose,
		|	DamageNoteGoods.Series
		|FROM
		|	Document.DamageNote.Goods AS DamageNoteGoods
		|		LEFT JOIN InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
		|		ON DamageNoteGoods.Products = AnotherQualityGoods.Products
		|			AND DamageNoteGoods.ProductsRecordingAsReceived = AnotherQualityGoods.OtherQualityGoods
		|WHERE
		|	&BasedOnWarrant
		|	AND NOT AnotherQualityGoods.Products IS NULL
		|	AND DamageNoteGoods.Ref = &DocumentBasis
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	Series,
		|	AssignmentGoodsReceipt DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DefectiveGoodsTableWithFilter.Products,
		|	DefectiveGoodsTableWithFilter.Characteristic,
		|	DefectiveGoodsTableWithFilter.Series,
		|	DefectiveGoodsTableWithFilter.Purpose,
		|	DefectiveGoodsTableWithFilter.Count
		|FROM
		|	DefectiveGoodsTableWithFilter AS DefectiveGoodsTableWithFilter
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SourceItemTableWithFilter.Products,
		|	SourceItemTableWithFilter.Characteristic,
		|	SourceItemTableWithFilter.Series,
		|	SourceItemTableWithFilter.Purpose,
		|	SourceItemTableWithFilter.Count
		|FROM
		|	SourceItemTableWithFilter AS SourceItemTableWithFilter";
		
		CorrespondenceTableNumber = 4;
		
	Else
		
		// There will only be a recalculation in the non-standard warehouse of the documentation
		Query.Text = 
		
		"SELECT
		|	DefectiveGoodsTable.Products AS Products,
		|	DefectiveGoodsTable.Characteristic AS Characteristic,
		|	DefectiveGoodsTable.Purpose AS Purpose,
		|	DefectiveGoodsTable.CountReal - DefectiveGoodsTable.Count AS Count,
		|	DefectiveGoodsTable.Series AS Series
		|INTO DefectiveGoodsTable
		|FROM
		|	Document.InventoryRecount.Goods AS DefectiveGoodsTable
		|WHERE
		|	DefectiveGoodsTable.Count - DefectiveGoodsTable.CountReal < 0
		|	AND DefectiveGoodsTable.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfOriginalProduct.Products AS Products,
		|	TableOfOriginalProduct.Characteristic AS Characteristic,
		|	TableOfOriginalProduct.Purpose AS Purpose,
		|	TableOfOriginalProduct.Count - TableOfOriginalProduct.CountReal AS Count,
		|	TableOfOriginalProduct.Series AS Series
		|INTO TableOfOriginalProduct
		|FROM
		|	Document.InventoryRecount.Goods AS TableOfOriginalProduct
		|WHERE
		|	TableOfOriginalProduct.Count - TableOfOriginalProduct.CountReal > 0
		|	AND TableOfOriginalProduct.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DefectiveGoodsTable.Products AS ProductsRecordingAsReceived,
		|	DefectiveGoodsTable.Characteristic AS CharacteristicRecordingAsReceived,
		|	DefectiveGoodsTable.Purpose AS AssignmentGoodsReceipt,
		|	TableOfOriginalProduct.Products AS Products,
		|	TableOfOriginalProduct.Characteristic AS Characteristic,
		|	TableOfOriginalProduct.Purpose AS Purpose,
		|	TableOfOriginalProduct.Series AS Series
		|FROM
		|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
		|		INNER JOIN DefectiveGoodsTable AS DefectiveGoodsTable
		|		ON AnotherQualityGoods.OtherQualityGoods = DefectiveGoodsTable.Products
		|		INNER JOIN TableOfOriginalProduct AS TableOfOriginalProduct
		|		ON AnotherQualityGoods.Products = TableOfOriginalProduct.Products
		|WHERE
		|	ISNULL(CAST(TableOfOriginalProduct.Series AS Catalog.ItemsBatches).Description, """") = ISNULL(CAST(DefectiveGoodsTable.Series AS Catalog.ItemsBatches).Description, """")
		|	AND ISNULL(CAST(TableOfOriginalProduct.Characteristic AS Catalog.ItemsCharacteristics).Description, """") = ISNULL(CAST(DefectiveGoodsTable.Characteristic AS Catalog.ItemsCharacteristics).Description, """")
		|	AND (ISNULL(CAST(TableOfOriginalProduct.Purpose AS Catalog.Assignments).Description, """") = ISNULL(CAST(DefectiveGoodsTable.Purpose AS Catalog.Assignments).Description, """")
		|			OR DefectiveGoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef))
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	Series,
		|	AssignmentGoodsReceipt DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DefectiveGoodsTable.Products,
		|	DefectiveGoodsTable.Characteristic,
		|	DefectiveGoodsTable.Purpose,
		|	DefectiveGoodsTable.Count,
		|	DefectiveGoodsTable.Series
		|FROM
		|	DefectiveGoodsTable AS DefectiveGoodsTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfOriginalProduct.Products,
		|	TableOfOriginalProduct.Characteristic,
		|	TableOfOriginalProduct.Purpose,
		|	TableOfOriginalProduct.Count,
		|	TableOfOriginalProduct.Series
		|FROM
		|	TableOfOriginalProduct AS TableOfOriginalProduct";
		
		Query.SetParameter("Ref", DocumentBasis);
		
		CorrespondenceTableNumber = 2;
		
	EndIf;
		
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	MapsTable = Result[CorrespondenceTableNumber].Unload();
	TableOfIncomingGoods = Result[CorrespondenceTableNumber + 1].Unload();
	TableOfDebitedProducts = Result[CorrespondenceTableNumber + 2].Unload();
	
	For Each ItemDebitedLine In TableOfDebitedProducts Do
		
		Filter = New Structure;
		Filter.Insert("Products", 		ItemDebitedLine.Products);
		Filter.Insert("Characteristic", 	ItemDebitedLine.Characteristic);
		Filter.Insert("Purpose", 		ItemDebitedLine.Purpose);
		Filter.Insert("Series", 			ItemDebitedLine.Series);
		ComplianceWithGoodsOfDifferentQuality = MapsTable.FindRows(Filter);
		
		For Each StringProductOfDifferentQuality In ComplianceWithGoodsOfDifferentQuality Do
			
			If ItemDebitedLine.Count = 0 Then
				Break;
			EndIf;
			
			Filter.Clear();
			Filter.Insert("Products", 		StringProductOfDifferentQuality.ProductsRecordingAsReceived);
			Filter.Insert("Characteristic", 	StringProductOfDifferentQuality.CharacteristicRecordingAsReceived);
			Filter.Insert("Purpose", 		StringProductOfDifferentQuality.AssignmentGoodsReceipt);
			Filter.Insert("Series", 			StringProductOfDifferentQuality.Series);
			ArrayOfIncomingGoods = TableOfIncomingGoods.FindRows(Filter);
			
			ArrayOfRowsOfItemsToDelete = New Array;
			
			For Each IncomingGoodsLine In ArrayOfIncomingGoods Do
				
				If ItemDebitedLine.Count = 0 Then
					Break;
				EndIf;
				
				NewRow = Goods.Add();
				NewRow.Products 				= ItemDebitedLine.Products;
				NewRow.Characteristic 				= ItemDebitedLine.Characteristic;
				NewRow.Purpose 					= ItemDebitedLine.Purpose;
				NewRow.Series 						= ItemDebitedLine.Series;
				NewRow.ProductsRecordingAsReceived 	= IncomingGoodsLine.Products;
				NewRow.CharacteristicRecordingAsReceived	= IncomingGoodsLine.Characteristic;
				NewRow.ForAssignment 				= ValueIsFilled(IncomingGoodsLine.Purpose);
				
				NewRow.Count = Min(IncomingGoodsLine.Count, ItemDebitedLine.Count);
				
				IncomingGoodsLine.Count = IncomingGoodsLine.Count - NewRow.Count;
				ItemDebitedLine.Count = ItemDebitedLine.Count - NewRow.Count;
				
				If IncomingGoodsLine.Count = 0 Then
					ArrayOfRowsOfItemsToDelete.Add(IncomingGoodsLine);
				EndIf;
				
			EndDo;
			
			DeleteRowsFromTable(TableOfIncomingGoods, ArrayOfRowsOfItemsToDelete);		
			
		EndDo;
		
		DeleteRowsFromTable(MapsTable, ComplianceWithGoodsOfDifferentQuality);
		
	EndDo;
		
	If Goods.Count() > 0 Then
		
		If ValueIsFilled(PriceKind) And Goods.Count() > 0 And Not ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
			
			ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
			OtherColumnNames = New Structure("ProductsRecordingAsReceived, CharacteristicRecordingAsReceived", "Products", "Characteristic");
			
			FillParameters = New Structure;
			FillParameters.Insert("Date",				Date);
			FillParameters.Insert("Organization",			Organization);
			FillParameters.Insert("Currency",				Currency);
			FillParameters.Insert("PriceKind",				PriceKind);
			FillParameters.Insert("ColumnsByValue",	ColumnsByValue);
			FillParameters.Insert("OtherColumnNames",	OtherColumnNames);
			
			EnterprisePricesFillingServer.FillInPrices(
				Goods, // Table part
				 , // Selected lines (fill in all lines)
				FillParameters);
		EndIf;
		
	ElsIf ValueIsFilled(DocumentBasis) Then
		
		MessageText = NStr("vi = 'Trong chứng từ ""%DocumentBasis%"" không có hàng hóa cần lập chứng từ hàng hỏng.';
							|ru = 'В документе ""%DocumentBasis%"" отсутствуют товары, по которым необходимо оформить порчу.';
							|en = 'Goods for which damage registration is required are absent in document ""%DocumentBasis%"".'; fa = 'Goods for which damage registration is required are absent in document ""%DocumentBasis%"".';
							|it = 'Nel documento ""%DocumentBasis%"" non ci sono prodotti per i quali è necessario formalizzare il danneggiamento.';
							|pl = 'W dokumencie ""%DocumentBasis%"" brak towarów, dla których należy wskazać uszkodzenie.';
							|tr = '""%DocumentBasis%"" belgesinde stok kalite düşüklüğü düzenlenmesi gereken ürünler mevcut değil.'");
		MessageText = StrReplace(MessageText, "%DocumentBasis%", DocumentBasis);
		Common.MessageToUser(MessageText, ThisObject);
		
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
//	DocumentObject - DocumentObject.GoodsDamage - the document for which parameters are initialized.
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
//	DocumentTables - See Documents.GoodsDamage.CollectionOfTabularPartsOfGoods.
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
	
	If TypeOf(FillingData) = Type("Structure")
			And FillingData.Property("Basis")
			And TypeOf(FillingData.Basis) = Type("DocumentRef.GoodsQualityControlCertificate") Then
		FillInCertificateOfQualityControl(FillingData);
		FillInTablePart = False;
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, FillingData);
		
		FillInTablePart = Not FillingData.Property("DoNotFillInWrongPart");
		
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
				MessageText = StrReplace(MessageText, "%DocumentAct%", Metadata.Documents.GoodsDamage.Synonym);
				MessageText = StrReplace(MessageText, "%StatusCompleted_%", Enums.InventoryRecountStatuses.Completed2);
				MessageText = StrReplace(MessageText, "%StatusOfRecalculation%", ResultingStructure.Status);
				Raise MessageText;
			EndIf;
			Warehouse = ResultingStructure.Warehouse;
			InventoryRecount = FillingData;
			
		ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsDamage") Then
			
			FillInTablePart = False;
			
			DocumentCorrection.FillInCorrection(ThisObject, FillingData);
			
		EndIf;
		
		If Not ValueIsFilled(Warehouse) Then
			Warehouse = Common.ObjectAttributeValue(FillingData, "Warehouse");
		EndIf;
		
		DocumentBasis = FillingData;
		
	EndIf;
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.GoodsDamage.ItemsAndDimensionsSelectionParameters(
										BusinessOperation, ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument(FillingData);
	
	If FillInTablePart Then 
		FillInTablePart(DocumentBasis);
	EndIf;
	
	GoodsDamageLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
														ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsDamage));
														
	If ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		For Each TableRow In Goods Do
			If TableRow.Price <> 0 Then
				TableRow.Price = 0;
			EndIf;
			If TableRow.PriceOffBalance <> 0 Then
				TableRow.PriceOffBalance = 0;
			EndIf;
		EndDo;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.GoodsDamage.ItemsAndDimensionsSelectionParameters(
										BusinessOperation, ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	GoodsDamageLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	GoodsDamageLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	Assignments = Goods.UnloadColumn("Purpose");
	AssignmentTypes = Common.ObjectsAttributeValue(Assignments, "AssignmentType");
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.FieldNamesWithSuffix.Insert("Products", "ProductsRecordingAsReceived");
	CheckParameters.FieldNamesWithSuffix.Insert("Characteristic", "CharacteristicRecordingAsReceived");
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsDamage),
												Cancel,
												NotCheckedAttributeArray);
	
	For Each RowOfTables In Goods Do
		ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa"".';
							|ru = 'в строке %LineNumber% списка ""Товары"".';
							|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
							|it = 'nella stringa %LineNumber% dell''elenco ""Merci"".';
							|pl = 'w wierszu %LineNumber% listy ""Towary"".';
							|tr = '%LineNumber% ""Ürünler"" listesinin satırında.'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", RowOfTables.LineNumber);
		
		If ValueIsFilled(RowOfTables.Products)
			And RowOfTables.Products = RowOfTables.ProductsRecordingAsReceived Then
			ErrorText = NStr("vi = 'Không thể chọn hàng hóa có chất lượng ban đầu. Hãy chọn hàng hóa có chất lượng khác';
							|ru = 'Нельзя выбирать товар исходного качества. Выберите товар другого качества';
							|en = 'You cannot select goods of the original quality. Select goods with another quality'; fa = 'You cannot select goods of the original quality. Select goods with another quality';
							|it = 'Non è possibile selezionare un prodotto di qualità originale. Selezionare un prodotto di qualità diversa';
							|pl = 'Nie możesz wybrać produktu o oryginalnej jakości. Wybierz produkt o innej jakości.';
							|tr = 'Orijinal kalitedeki ürün seçilmemeli. Uygun kalitede olmayan ürünler seç'");
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "ProductsRecordingAsReceived");
			Common.MessageToUser(ErrorText + " " + ErrorAddress,ThisObject,Field,,Cancel);
		EndIf;
		If AssignmentTypes.Get(RowOfTables.Purpose) = Enums.AssignmentTypes.Giveaway2_5
			And Not RowOfTables.ForAssignment Then
			
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "ForAssignment");
			ErrorText = NStr("vi = 'Trong trường hợp, hàng hỏng đã đặt riêng theo mục đích của người đặt gia công, cần nhập hàng ""Theo mục đích""';
							|ru = 'При порче товара, обособленного под назначение давальца, приход товара должен быть ""Под назначение""';
							|en = 'If an item assigned for the provider assignment has a stock quality change, the goods receipt must be ""For assignment""'; fa = 'If an item assigned for the provider assignment has a stock quality change, the goods receipt must be ""For assignment""';
							|it = 'In caso di usura della merce separata per assegnazione del fornitore, l''arrivo della merce deve essere ""Per assegnazione""';
							|pl = 'W przypadku uszkodzenia towaru, oddzielonego pod przeznaczenie właściciela surowców, przyjęcie towaru musi być ""Na przeznaczenie""';
							|tr = 'Ürün stok kalite değişikliği durumunda, müşterinin amacına uygun olarak ayrılması durumunda, ürünün girişi ""Atamaya uygun"" olmalıdır.'");
			Common.MessageToUser(ErrorText + " " + ErrorAddress,ThisObject,Field,,Cancel);
			
		EndIf;
	EndDo;
	
	ProductsServer.CheckTypeOfProductDescription(ThisObject,Cancel);
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.GoodsDamage.ItemsAndDimensionsSelectionParameters(
										BusinessOperation, ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes,
		ItemsAndDimensionsSelectionParameters);
	
	CheckVATRates(Cancel);
	
	GoodsDamageLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsDamageLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsDamageLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	
	InventoryKinds.Clear();
	
	InitializeDocument();
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "InventoryKinds");
	
	GoodsDamageLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInCertificateOfQualityControl(FillingData)
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Documents.GoodsQualityControlCertificate.GoodsToCreateBasedOn(
		Query,
		FillingData.Basis,
		FillingData.Warehouse,
		Enums.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange);
	
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
		|	Goods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
		|	Goods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
		|	Goods.ForAssignment AS ForAssignment,
		|	Goods.PackagingReceipt AS PackagingReceipt,
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
		|	Goods.ProductsRecordingAsReceived,
		|	Goods.CharacteristicRecordingAsReceived,
		|	Goods.PackagingReceipt,
		|	Goods.ForAssignment,
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
		ErrorText = NStr("vi = 'Chứng từ %Document% không có hàng hóa với thao tác ""Lập chứng từ hư hỏng"". Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Документ %Document% не содержит товаров c действием ""Оформить порчу"". Ввод на основании документа запрещен.';
						|en = 'The ""%Document%"" document does not have any goods with the ""Register stock quality change"" action. Generation from such base documents is not allowed.'; fa = 'The ""%Document%"" document does not have any goods with the ""Register stock quality change"" action. Generation from such base documents is not allowed.';
						|it = 'The ""%Document%"" document does not have any goods with the ""Register stock quality change"" action. Generation from such base documents is not allowed.';
						|pl = 'The ""%Document%"" document does not have any goods with the ""Register stock quality change"" action. Generation from such base documents is not allowed.';
						|tr = '%Document% belgesi ""Stok kalite düşüklüğü düzenle"" eylemine sahip ürün içermemektedir. Belgeye dayanarak giriş yapılması yasaktır.'");
		ErrorText = StrReplace(ErrorText, "%Document%", FillingData.Basis);
		Raise ErrorText;
	EndIf;
	
	FillPropertyValues(ThisObject, HeaderAttributes, "Organization,Department,ControlledLotReference");
	
	DocumentBasis = FillingData.Basis;
	Warehouse = FillingData.Warehouse;
	Goods.Load(BaseGoods);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)

	EmployeeResponsible = Users.CurrentUser();
	Author = Users.CurrentUser();

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
	If Not ValueIsFilled(Currency) Then
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(
			Catalogs.TypesOfPrices.GetPriceTypeDetails(
				?(PriceKind = Undefined, Catalogs.Warehouses.AccountingPriceType(Warehouse), PriceKind)).PriceCurrency);
	EndIf;
	
	If Not ValueIsFilled(VATActivityType) Then
		FillInTypeOfActivityVAT();
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

Procedure FillInTypeOfActivityVAT()
	
	FillParameters = Documents.GoodsDamage.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(VATActivityType, FillParameters);
	
EndProcedure

Procedure FillInInventoryTypeProductList(Cancel)
	
	TypesOfInventoryWriteOff = InventoryKinds.UnloadColumn("InventoryOwnerAttribute");
	TypesOfInventoryWriteOff = CommonClientServer.CollapseArray(TypesOfInventoryWriteOff);
	
	AttributesNames = New Array;
	AttributesNames.Add("InventoryType");
	AttributesNames.Add("SubjectToExcise");
	AttributesNames = StrConcat(AttributesNames, ",");
	
	InventoryWriteOffData	= Common.ObjectsAttributesValues(TypesOfInventoryWriteOff, AttributesNames);
	TransferredInventoryOwnerAttributes	= New Array;
	ExciseLines		= New Array;
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In Goods Do
		
		GoodsQuantity = RowOfGoods.Count;
		CurCurrentInventoryType = Enums.InventoryTypes.OwnGoods;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.ItemsLocationAttributesReceipt = RowOfGoods.ItemsLocationAttributesReceipt;
			
			CurrentInventoryData = InventoryWriteOffData.Get(NewRow.InventoryOwnerAttribute);
			
			If CurrentInventoryData.InventoryType = Enums.InventoryTypes.OwnGoods
				And Not CurrentInventoryData.SubjectToExcise
				Or CurrentInventoryData.InventoryType = Enums.InventoryTypes.ConsignedGoods Then
				
				NewRow.InventoryOwnerAttributeGoodsReceipt = RowOfGoods.InventoryOwnerAttribute;
				
			Else
				NewRow.InventoryOwnerAttributeGoodsReceipt	= NewRow.InventoryOwnerAttribute;
				CurCurrentInventoryType		= CurrentInventoryData.InventoryType;
				
				TransferredInventoryOwnerAttributes.Add(NewRow.InventoryOwnerAttribute);
				If CurrentInventoryData.SubjectToExcise Then
					ExciseLines.Add(RowOfGoods.LineNumber);
				EndIf;
			EndIf;
			
			NewRow.Sum					= ?(Not ReceiveGoodsAtCostTheyWereIssuedFromWarehouse,
													Count * RowOfGoods.Price,
													0);
			NewRow.AmountOffBalance			= ?(Not ReceiveGoodsAtCostTheyWereIssuedFromWarehouse,
													Count * RowOfGoods.PriceOffBalance,
													0);
			NewRow.Count				= Count;
			NewRow.QuantityByGBRN		= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			InventoryLine.Count = InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN = InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			
			// Checking the filling of prices is performed after selecting the types of stocks, as it depends on the selected type of stocks.
			If Not ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
				
				ErrorText= "";
				
				If Not ValueIsFilled(NewRow.AmountOffBalance)
					And Not ValueIsFilled(NewRow.Sum)
					And (CurCurrentInventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell
						Or CurCurrentInventoryType = Enums.InventoryTypes.MaterialOfMaterialProvider
						Or CurCurrentInventoryType = Enums.InventoryTypes.ProductsOfMaterialProvider
						Or False) Then
					
					Field = CommonClientServer.PathToTabularSection("Goods", RowOfGoods.LineNumber, "PriceOffBalance");
					ErrorText = NStr("vi = 'Trong dòng %1 đối với hàng hóa ""%2"", cần điền đơn giá kế toán.';
									|ru = 'В строке %1 для товара ""%2"" необходимо заполнить забалансовую цену.';
									|en = 'In line %1, fill the off-balance price for the ""%2"" item.'; fa = 'In line %1, fill the off-balance price for the ""%2"" item.';
									|it = 'В строке %1 для товара ""%2"" необходимо заполнить забалансовую цену.';
									|pl = 'In line %1, fill the off-balance price for the ""%2"" item.';
									|tr = '""%2"" ürünü için %1 satırda bilanço dışı fiyatı doldurmanız gerekmektedir.'");
					
					ErrorText =
						StrTemplate(
							ErrorText,
							RowOfGoods.LineNumber,
							ProductsClientServer.ProductPresentation(
								RowOfGoods.Products,
								RowOfGoods.Characteristic,,
								RowOfGoods.Series,
								RowOfGoods.Purpose));
					Common.MessageToUser(ErrorText, ThisObject, Field,, Cancel);
					
				EndIf;
				
				If ValueIsFilled(NewRow.Sum)
					And (CurCurrentInventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell
						Or CurCurrentInventoryType = Enums.InventoryTypes.MaterialOfMaterialProvider
						Or CurCurrentInventoryType = Enums.InventoryTypes.ProductsOfMaterialProvider
						Or False) Then
					
					Field = CommonClientServer.PathToTabularSection("Goods", RowOfGoods.LineNumber, "Price");
					ErrorText = NStr("vi = 'Trong dòng %1 đối với hàng hóa ""%2"", cần điền chỉ đơn giá ngoài bảng.';
									|ru = 'В строке %1 для товара ""%2"" необходимо заполнить только забалансовую цену.';
									|en = 'In line %1, fill only the off-balance price for the ""%2"" item.'; fa = 'In line %1, fill only the off-balance price for the ""%2"" item.';
									|it = 'Nella stringa %1 per la merce ""%2"" è necessario compilare solo il prezzo fuori bilancio.';
									|pl = 'W wierszu %1 dla towaru ""%2"" należy wypełnić tylko cenę pozabilansową.';
									|tr = '""%2"" malları için %1 satırda sadece bilanço dışı fiyatın doldurulması gerekmektedir.'");
					
					ErrorText =
						StrTemplate(
							ErrorText,
							RowOfGoods.LineNumber,
							ProductsClientServer.ProductPresentation(
								RowOfGoods.Products,
								RowOfGoods.Characteristic,,
								RowOfGoods.Series,
								RowOfGoods.Purpose));
					Common.MessageToUser(ErrorText, ThisObject, Field,, Cancel);
					
				EndIf;
				If CurCurrentInventoryType = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider
					And Not ValueIsFilled(NewRow.Sum)
					And Not ValueIsFilled(NewRow.AmountOffBalance) Then
					
					Field = CommonClientServer.PathToTabularSection("Goods", RowOfGoods.LineNumber, "LineNumber");
					ErrorText = NStr("vi = 'Trong dòng %1 đối với hàng hóa ""%2"", cần điền đơn giá kế toán hoặc đơn giá ngoài bảng.';
									|ru = 'В строке %1 для товара ""%2"" необходимо заполнить балансовую или забалансовую цену.';
									|en = 'In line %1, fill the book value or off-balance price for the ""%2"" item.'; fa = 'In line %1, fill the book value or off-balance price for the ""%2"" item.';
									|it = 'Nella stringa %1 per la merce ""%2"" è necessario compilare il prezzo in bilancio o fuori bilancio.';
									|pl = 'W wierszu %1 dla towaru ""%2"" należy wypełnić cenę bilansową lub pozabilansową.';
									|tr = '""%2"" malları için %1 satır bilançoya göre veya bilanço dışı fiyat ile doldurulmalıdır.'");
					
					ErrorText =
						StrTemplate(
							ErrorText,
							RowOfGoods.LineNumber,
							ProductsClientServer.ProductPresentation(
								RowOfGoods.Products,
								RowOfGoods.Characteristic,,
								RowOfGoods.Series,
								RowOfGoods.Purpose));
					Common.MessageToUser(ErrorText, ThisObject, Field,, Cancel);
					
				EndIf;
				If Not ValueIsFilled(NewRow.Sum)
					And Not ValueIsFilled(NewRow.AmountOffBalance)
					And Not CurCurrentInventoryType = Enums.InventoryTypes.MaterialOfMaterialProvider
					And Not CurCurrentInventoryType = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider
					And Not CurCurrentInventoryType = Enums.InventoryTypes.ProductsOfMaterialProvider
					And Not CurCurrentInventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell Then
					
					Field = CommonClientServer.PathToTabularSection("Goods", RowOfGoods.LineNumber, "Price");
					ErrorText = NStr("vi = 'Trong dòng %1 đối với hàng hóa ""%2"", cần điền đơn giá kế toán.';
									|ru = 'В строке %1 для товара ""%2"" необходимо заполнить балансовую цену.';
									|en = 'In line %1, fill the book value for the ""%2"" item.'; fa = 'In line %1, fill the book value for the ""%2"" item.';
									|it = 'В строке %1 для товара ""%2"" необходимо заполнить балансовую цену.';
									|pl = 'In line %1, fill the book value for the ""%2"" item.';
									|tr = '""%2"" ürünü için %1 satırda bilanço fiyatını doldurmanız gerekmektedir.'");
					
					ErrorText =
						StrTemplate(
							ErrorText,
							RowOfGoods.LineNumber,
							ProductsClientServer.ProductPresentation(
								RowOfGoods.Products,
								RowOfGoods.Characteristic,,
								RowOfGoods.Series,
								RowOfGoods.Purpose));
					Common.MessageToUser(ErrorText, ThisObject, Field,, Cancel);
					
				EndIf;
				
				If ValueIsFilled(NewRow.AmountOffBalance)
					And Not CurCurrentInventoryType = Enums.InventoryTypes.MaterialOfMaterialProvider
					And Not CurCurrentInventoryType = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider
					And Not CurCurrentInventoryType = Enums.InventoryTypes.ProductsOfMaterialProvider
					And Not CurCurrentInventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell Then
					
					Field = CommonClientServer.PathToTabularSection("Goods", RowOfGoods.LineNumber, "PriceOffBalance");
					ErrorText = NStr("vi = 'Trong dòng %1 đối với hàng hóa ""%2"", cần điền chỉ đơn giá kế toán.';
									|ru = 'В строке %1 для товара ""%2"" необходимо заполнить только балансовую цену.';
									|en = 'In line %1, fill only the book value for the ""%2"" item.'; fa = 'In line %1, fill only the book value for the ""%2"" item.';
									|it = 'Nella stringa %1 per la merce ""%2"" è necessario compilare solo il prezzo in bilancio.';
									|pl = 'W wierszu %1 dla towaru ""%2"" należy wypełnić tylko cenę bilansową.';
									|tr = '""%2"" malları için %1 satır sadece bilançoya göre doldurulmalıdır.'");
					
					ErrorText =
						StrTemplate(
							ErrorText,
							RowOfGoods.LineNumber,
							ProductsClientServer.ProductPresentation(
								RowOfGoods.Products,
								RowOfGoods.Characteristic,,
								RowOfGoods.Series,
								RowOfGoods.Purpose));
					Common.MessageToUser(ErrorText, ThisObject, Field,, Cancel);
					
				EndIf;
				
			EndIf;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	CheckCorrectnessOfIndicationOfExciseCategories(ExciseLines, Cancel);
	SynchronizePropertiesOfInventoryOwnerAttributesOfAccount(TransferredInventoryOwnerAttributes, Cancel);
	
EndProcedure

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager = TemporaryDocumentDataTables();
	
	InventoriesServer.FillStockTypesByDefault(TempTablesManager, Goods);
	
	RefillInventoryKinds = InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber", "Count, QuantityByGBRN");
		
		FillInInventoryTypeProductList(Cancel);
		
	EndIf;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.GoodsDamage.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.GoodsDamage.CollectionOfTabularPartsOfGoods();
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting =
		InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
			BusinessOperation,
			Warehouse,
			Department,
			Undefined);
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting);
	
	FieldTextDestination = 
	"CASE
	|	WHEN Collection.ForAssignment
	|	THEN Collection.Purpose
	|	ELSE VALUE(Catalog.Assignments.EmptyRef)
	|END";
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.ItemsLocationAttributes	= "ItemsLocationAttributesReceipt";
	FieldsNames.Products					= "ProductsRecordingAsReceived";
	FieldsNames.Characteristic				= "CharacteristicRecordingAsReceived";
	FieldsNames.Purpose					= New Structure("FieldText", FieldTextDestination);
	FieldsNames.Series						= "Series";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

Procedure SynchronizePropertiesOfInventoryOwnerAttributesOfAccount(TransferredInventoryOwnerAttributes, Cancel)
	
	If Cancel
		Or TransferredInventoryOwnerAttributes.Count() = 0
		Or Not GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups") Then
		
		Return;
		
	EndIf;
	
	TransferredInventoryOwnerAttributes = CommonClientServer.CollapseArray(TransferredInventoryOwnerAttributes);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributes,
	|	TableOfGoods.InventoryOwnerAttributeGoodsReceipt AS InventoryOwnerAttribute
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|INDEX BY
	|	InventoryOwnerAttribute,
	|	ItemsLocationAttributes
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	TableOfGoods.LineNumber		AS LineNumber,
	|	InventoryKinds.Ref				AS InventoryOwnerAttribute,
	|	&Organization					AS Organization,
	|	InventoryKinds.InventoryType			AS InventoryType,
	|	InventoryKinds.GoodsOwner		AS GoodsOwner,
	|	InventoryKinds.Counterparty			AS Counterparty,
	|	InventoryKinds.Contract				AS Contract,
	|	InventoryKinds.Terms			AS Terms,
	|	InventoryKinds.Currency				AS Currency,
	|	InventoryKinds.PriceKind				AS PriceKind,
	|	InventoryKinds.VATTaxation	AS VATTaxation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS TaxationOfOrganization,
	|	Keys.Products.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	InventoryKinds.ProductsGroup		AS ProductsGroup,
	|	InventoryKinds.SubjectToExcise	AS SubjectToExcise,
	|	InventoryKinds.BusinessUnitProduction AS BusinessUnitProduction,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier) AS BusinessTransactionStockType
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TableOfGoods.InventoryOwnerAttribute = InventoryKinds.Ref
	|		
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON TableOfGoods.ItemsLocationAttributes = Keys.Ref
	|WHERE
	|	TableOfGoods.InventoryOwnerAttribute IN(&VerifiableInventory)
	|	AND Keys.Products.FinancialAccountingGroup <> InventoryKinds.FinancialAccountingGroup
	|
	|ORDER BY
	|	LineNumber";
	
	NamesOfColumnsToUpload = "LineNumber, ItemsLocationAttributesReceipt, InventoryOwnerAttributeGoodsReceipt";
	
	Query.SetParameter("Organization",		Organization);
	Query.SetParameter("VerifiableInventory",	TransferredInventoryOwnerAttributes);
	Query.SetParameter("TableOfGoods",		InventoryKinds.Unload(, NamesOfColumnsToUpload));
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return
	EndIf;
	
	Selection = QueryResult.Select();
	InventoryOwnerAttributesGoodsReceipt = New Map;
	
	While Selection.Next() Do
		InventoryOwnerAttributeGoodsReceipt = Catalogs.InventoryKinds.DocumentInventoryView(
									Selection.Organization,
									Selection.BusinessTransactionStockType,
									Selection);
		InventoryOwnerAttributesGoodsReceipt.Insert(Selection.LineNumber, InventoryOwnerAttributeGoodsReceipt);
	EndDo;
	
	For Each InventoryLine In InventoryKinds Do
		InventoryOwnerAttributeGoodsReceipt = InventoryOwnerAttributesGoodsReceipt[InventoryLine.LineNumber];
		
		If InventoryOwnerAttributeGoodsReceipt = Undefined Then
			Continue;
		EndIf;
		
		InventoryLine.InventoryOwnerAttributeGoodsReceipt = InventoryOwnerAttributeGoodsReceipt;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckVATRates(Cancel)
	
	Products = Goods.UnloadColumn("Products");
	ProductsRecordingAsReceived = Goods.UnloadColumn("ProductsRecordingAsReceived");
	CommonClientServer.SupplementArray(Products, ProductsRecordingAsReceived, True);
	
	VATRates = VATAccountingERP.VATRatesByItemArray(Products, Organization, Date);
	
	For Each LineProducts_ In Goods Do
		If VATRates[LineProducts_.Products] <> VATRates[LineProducts_.ProductsRecordingAsReceived] Then
			Field = CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "Products");
			MessageText = NStr("vi = 'Không thể phản ánh hàng hỏng, vì mặt hàng kém chất lượng và mặt hàng ban đầu không trùng thuế suất thuế GTGT';
								|ru = 'Невозможно отразить порчу, т.к. у некачественной и исходной номенклатуры не равны ставки НДС';
								|en = 'Cannot record damage as spoiled and source products have different VAT rates'; fa = 'Cannot record damage as spoiled and source products have different VAT rates';
								|it = 'È impossibile riportare il danno, perché le aliquote IVA sono diverse per la nomenclatura di qualità carente e per quella originale';
								|pl = 'Nie można wyrazić uszkodzeń, ponieważ niejakościowe i oryginalne produkty nie są równe stawce VAT';
								|tr = 'Kalitesiz ve orijinal ürün gamı KDV oranlarına sahip olmadığı için stok kalite düşüklüğü muhasebeleştirilemez'");
			CommonClientServer.MessageToUser(MessageText, , Field, "Object", Cancel);
		EndIf;
	EndDo;
	
EndProcedure

Procedure DeleteRowsFromTable(Table, RowsArray)
	For Each String In RowsArray Do
		Table.Delete(String);
	EndDo;
EndProcedure

#EndRegion

#Region InventoryKinds

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Warehouse, ReceiveGoodsAtCostTheyWereIssuedFromWarehouse";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query("
	|////////////////////////////////////////////////////////////////////////////////
	|// Check the correspondence of the table parts of the Products and types of stocks
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|		TableOfGoods.Count AS Count,
	|		CAST(TableOfGoods.Count * TableOfGoods.Price AS NUMBER(31,2)) AS Sum,
	|		CAST(TableOfGoods.Count * TableOfGoods.PriceOffBalance AS NUMBER(31,2)) AS AmountOffBalance
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes,
	|		TableTypesOfStocks_.ItemsLocationAttributesReceipt,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.Sum AS Sum,
	|		-TableTypesOfStocks_.AmountOffBalance AS AmountOffBalance
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesReceipt
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.Sum) <> 0
	|	OR SUM(TableOfGoods.AmountOffBalance) <> 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|");
	Query.SetParameter("ArrivalAtCost", ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction 

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.VATTaxation = VATActivityType;
	FillParameters.ReversedDocument = ReversedDocument;
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Always");
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.MaterialOfMaterialProvider,     "Always");
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider, "Always");
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.ProductsOfMaterialProvider,    "Always");
	If GetFunctionalOption("UseExcisableGoods") Then
		FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
	EndIf;
	Return FillParameters;
	
EndFunction
Procedure CheckCorrectnessOfIndicationOfExciseCategories(ExciseLines, Cancel)
	
	If Cancel
		Or ExciseLines.Count() = 0
		Or Not GetFunctionalOption("UseExcisableGoods") Then
		
		Return;
		
	EndIf;
	
	StringsList = New Array;
	ExciseLines = CommonClientServer.CollapseArray(ExciseLines);
	
	For Each LineNumber In ExciseLines Do
		StringsList.Add(Goods[LineNumber - 1]);
	EndDo;
	
	ControlParameters = ExcisableGoodsAccounting.ControlParametersForFillingExcisableItems();
	ControlParameters.ErrorTextTemplate =
		NStr("vi = 'Có chênh lệch giữa các thể loại hàng hóa chịu thuế TTĐB %Products% (hàng ghi giảm) và %ProductsRecordingAsReceived% (hàng ghi tăng) trong dòng %LineNumber% danh sách ""%TabularSectionPresentation%""';
			|ru = 'Различаются категории подакцизных товаров %Products% (списываемый товар) и %ProductsRecordingAsReceived% (приходуемый товар) в строке %LineNumber% списка ""%TabularSectionPresentation%""';
			|en = 'The %Products% (goods to adjust) and %ProductsRecordingAsReceived% (stock surplus) excisable goods categories differ in line %LineNumber% of the ""%TabularSectionPresentation%"" list'; fa = 'The %Products% (goods to adjust) and %ProductsRecordingAsReceived% (stock surplus) excisable goods categories differ in line %LineNumber% of the ""%TabularSectionPresentation%"" list';
			|it = 'The %Products% (goods to adjust) and %ProductsRecordingAsReceived% (stock surplus) excisable goods categories differ in line %LineNumber% of the ""%TabularSectionPresentation%"" list';
			|pl = 'The %Products% (goods to adjust) and %ProductsRecordingAsReceived% (stock surplus) excisable goods categories differ in line %LineNumber% of the ""%TabularSectionPresentation%"" list';
			|tr = 'Tüketim vergisine tabi %Products% (silinen ürünler) ve %ProductsRecordingAsReceived% (stok fazlası ürünler) ürün kategorileri ""%TabularSectionPresentation%"" listesinin %LineNumber% satırında farklılık göstermektedir'");
	ControlParameters.StringsList = StringsList;
	
	ExcisableGoodsAccounting.ControlOfComplianceWithCategoryOfExcisableItems(ThisObject, ControlParameters, Cancel);
	
EndProcedure
#EndRegion

#EndRegion

#EndIf
