#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.GoodsMisgrading - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes());
	
EndProcedure

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
//
Procedure FillInProductTrackingForm() Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.GoodsMisgrading.CollectionOfTabularPartsOfGoods.
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
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.InventoryRecount") Then
		ResultingStructure = Common.ObjectAttributesValues(FillingData, "Status, Warehouse");
		If ResultingStructure.Status <> Enums.InventoryRecountStatuses.Completed2 Then 
			MessageText = NStr("vi = 'Chứng từ ""%DocumentRecalculate%"" đang có trạng thái ""%StatusOfRecalculation%"". Cho phép nhập chứng từ ""%DocumentAct%"" trên cơ sở chỉ đối với trạng thái ""%StatusCompleted_%"".';
								|ru = 'Документ ""%DocumentRecalculate%"" находится в статусе ""%StatusOfRecalculation%"". Ввод документа ""%DocumentAct%"" на основании разрешен только в статусе ""%StatusCompleted_%"".';
								|en = 'Document ""%DocumentRecalculate%"" is in status ""%StatusOfRecalculation%"".  ""%DocumentAct%"" can only be generated from base documents in status ""%StatusCompleted_%"".'; fa = 'Document ""%DocumentRecalculate%"" is in status ""%StatusOfRecalculation%"".  ""%DocumentAct%"" can only be generated from base documents in status ""%StatusCompleted_%"".';
								|it = 'Il documento ""%DocumentRecalculate%"" è nello stato ""%StatusOfRecalculation%"". Immissione del documento ""%DocumentAct%"" in base alla casuale è consentita solo nello stato di ""%StatusCompleted_%"".';
								|pl = 'Dokument ""%DocumentRecalculate%"" ma status ""%StatusOfRecalculation%"". Wprowadzenie dokumentu ""%DocumentAct%"" na podstawie jest dozwolony tylko ze statusem ""%StatusCompleted_%"".';
								|tr = '""%DocumentRecalculate%"" belgesi ""%StatusOfRecalculation%"" durumundadır. ""%DocumentAct%"" esaslı belge girişine yalnız ""%StatusCompleted_%"" durumunda izin verildi.'");
			MessageText = StrReplace(MessageText, "%DocumentRecalculate%", FillingData);
			MessageText = StrReplace(MessageText, "%DocumentAct%", Metadata.Documents.GoodsMisgrading.Synonym);
			MessageText = StrReplace(MessageText, "%StatusCompleted_%", Enums.InventoryRecountStatuses.Completed2);
			MessageText = StrReplace(MessageText, "%StatusOfRecalculation%", ResultingStructure.Status);
			Raise MessageText;
		EndIf;
		
		FillPropertyValues(ThisObject, ResultingStructure, "Warehouse"); 
		InventoryRecount = FillingData;
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsMisgradingNote") Then
		FillInBasedOnOrderToReflectResortment(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsMisgrading") Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	EndIf;
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.GoodsMisgrading.ItemsAndDimensionsSelectionParameters(
										ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument(FillingData);
	
	RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
							ThisObject);
	
	FieldNamesWithSuffix = RecalculationParameters.FieldNamesWithSuffix;
	FieldNamesWithSuffix.Insert("Products",	"ProductsRecordingAsReceived");
	FieldNamesWithSuffix.Insert("Characteristic",	"CharacteristicRecordingAsReceived");
	
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	
	GoodsMisgradingLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ClearDataOnImportedGoods();
	
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
	
	ProductsServer.ClearUnusedSeries(ThisObject,
													ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsMisgrading));
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.GoodsMisgrading.ItemsAndDimensionsSelectionParameters(
										ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	GoodsMisgradingLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	GoodsMisgradingLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.FieldNamesWithSuffix.Insert("Products", "ProductsRecordingAsReceived");
	CheckParameters.FieldNamesWithSuffix.Insert("Characteristic", "CharacteristicRecordingAsReceived");
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	
	For Each RowOfTables In Goods Do
		
		ErrorAddress = NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa"".';
							|ru = 'в строке %LineNumber% списка ""Товары"".';
							|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
							|it = 'nella stringa %LineNumber% dell''elenco ""Merci"".';
							|pl = 'w wierszu %LineNumber% listy ""Towary"".';
							|tr = '%LineNumber% ""Ürünler"" listesinin satırında.'");
		ErrorAddress =  StrReplace(ErrorAddress, "%LineNumber%", RowOfTables.LineNumber);
		
		If ValueIsFilled(RowOfTables.Products)
			And RowOfTables.Products = RowOfTables.ProductsRecordingAsReceived
			And RowOfTables.Characteristic = RowOfTables.CharacteristicRecordingAsReceived 
			And RowOfTables.Series = RowOfTables.BatchReceipt
			And RowOfTables.Purpose = RowOfTables.AssignmentGoodsReceipt Then
				
			Field = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "LineNumber");
			ErrorText = NStr("vi = 'Hàng hóa ghi giảm trùng với hàng hóa tiếp nhận';
							|ru = 'Списываемый товар совпадает с приходуемым';
							|en = 'Goods to adjust match the goods recorded as received'; fa = 'Goods to adjust match the goods recorded as received';
							|it = 'La merce in fase di storno coincide a quella in fase della registrazione in contabilità';
							|pl = 'Spisany na straty towar pokrywa się z przyjmowanym';
							|tr = 'Zarara yazılan ürün envanter girişi yapılan ile eşleşiyor'");
			Common.MessageToUser(ErrorText + " " + ErrorAddress,ThisObject,Field,,Cancel);
			
		EndIf;
		
	EndDo;
	CheckCompletionOfAppointments(Cancel);
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods,
																								Date,
																								"ProductsRecordingAsReceived");
	
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	If ThisIsTraceableDocument
		Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers") Then
		
		CheckParameters = InventoriesServer.ParametersForCheckingFillingInOfCCDNumbers();
		CheckParameters.CheckingReSortingOfGoods = True;
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel, CheckParameters);
		
	EndIf;
	
	If ThisIsTraceableDocument Then
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject,
																						Goods,
																						Date,
																						"Goods",
																						"ProductsRecordingAsReceived");
	EndIf;
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsMisgrading),
												Cancel,
												NotCheckedAttributeArray);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	QualityControl.ProcessingVerificationOfFillingInSurplusDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Goods'; fa = 'کالاها';
			|it = 'Goods';
			|pl = 'Goods';
			|tr = 'Ürünler'"));
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.GoodsMisgrading.ItemsAndDimensionsSelectionParameters(
										ReceiveGoodsAtCostTheyWereIssuedFromWarehouse,
										True);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes,
		ItemsAndDimensionsSelectionParameters);
	
	GoodsMisgradingLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsMisgradingLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsMisgradingLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	
	InventoryKinds.Clear();
	
	InitializeDocument();
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "InventoryKinds");
	
	RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
							ThisObject);

	FieldNamesWithSuffix = RecalculationParameters.FieldNamesWithSuffix;
	FieldNamesWithSuffix.Insert("Products",	"ProductsRecordingAsReceived");
	FieldNamesWithSuffix.Insert("Characteristic",	"CharacteristicRecordingAsReceived");

	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	
	GoodsMisgradingLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInBasedOnOrderToReflectResortment(DocumentBasis)
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	GoodsOfOrder.Products   AS Products,
	|	GoodsOfOrder.Characteristic AS Characteristic,
	|	GoodsOfOrder.Purpose     AS Purpose,
	|	PackagingOfGoods.Ref      AS Package,
	|	GoodsOfOrder.Series          AS Series
	|INTO ProductLocationsOfOrder
	|FROM
	|	Document.GoodsMisgradingNote.Goods AS GoodsOfOrder
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagingOfGoods
	|		ON GoodsOfOrder.Products.PackagingGroup = PackagingOfGoods.Owner
	|WHERE
	|	GoodsOfOrder.Ref = &DocumentBasis
	|	AND NOT PackagingOfGoods.DeletionMark
	|	AND PackagingOfGoods.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	GoodsOfOrder.Products,
	|	GoodsOfOrder.Characteristic,
	|	GoodsOfOrder.Purpose,
	|	PackagingOfGoods.Ref,
	|	GoodsOfOrder.Series
	|FROM
	|	Document.GoodsMisgradingNote.Goods AS GoodsOfOrder
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagingOfGoods
	|		ON GoodsOfOrder.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|			AND GoodsOfOrder.Products = PackagingOfGoods.Owner
	|WHERE
	|	PackagingOfGoods.Ref = &DocumentBasis
	|	AND NOT PackagingOfGoods.DeletionMark
	|	AND PackagingOfGoods.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	ProductLocations.Products                  AS Products,
	|	ProductLocations.Characteristic                AS Characteristic,
	|	ProductLocations.Purpose                    AS Purpose,
	|	ProductLocations.Package                      AS Package,
	|	ProductLocations.Series                         AS Series,
	|	SUM(ISNULL(GoodsOfOrder.Count, 0)) AS Count
	|INTO TTProductLocationsOrders
	|FROM
	|	ProductLocationsOfOrder AS ProductLocations
	|		LEFT JOIN Document.GoodsMisgradingNote.Goods AS GoodsOfOrder
	|		ON GoodsOfOrder.Ref = &DocumentBasis
	|		AND ProductLocations.Products = GoodsOfOrder.Products
	|		AND ProductLocations.Characteristic = GoodsOfOrder.Characteristic
	|		AND ProductLocations.Purpose = GoodsOfOrder.Purpose
	|		AND ProductLocations.Package = GoodsOfOrder.Package
	|		AND ProductLocations.Series = GoodsOfOrder.Series
	|
	|GROUP BY
	|	ProductLocations.Products,
	|	ProductLocations.Characteristic,
	|	ProductLocations.Purpose,
	|	ProductLocations.Package,
	|	ProductLocations.Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	GoodsOfOrder.Products   AS Products,
	|	GoodsOfOrder.Characteristic AS Characteristic,
	|	GoodsOfOrder.Purpose     AS Purpose,
	|	GoodsOfOrder.Series          AS Series,
	|	MIN(CASE
	|		WHEN GoodsOfOrder.Count - CAST(GoodsOfOrder.Count AS NUMBER(15, 0)) >= 0
	|			THEN CAST(GoodsOfOrder.Count AS NUMBER(15, 0))
	|		ELSE
	|			CAST(GoodsOfOrder.Count AS NUMBER(15, 0)) - 1
	|	END)                      AS Count
	|INTO GoodsOfOrderInCommodityPlaces
	|FROM
	|	TTProductLocationsOrders AS GoodsOfOrder
	|
	|GROUP BY
	|	GoodsOfOrder.Products,
	|	GoodsOfOrder.Characteristic,
	|	GoodsOfOrder.Purpose,
	|	GoodsOfOrder.Series
	|
	|HAVING
	|	MIN(CASE
	|		WHEN GoodsOfOrder.Count - CAST(GoodsOfOrder.Count AS NUMBER(15, 0)) >= 0
	|			THEN CAST(GoodsOfOrder.Count AS NUMBER(15, 0))
	|		ELSE
	|			CAST(GoodsOfOrder.Count AS NUMBER(15, 0)) - 1
	|	END) > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	GoodsOfOrder.Products                AS Products,
	|	GoodsOfOrder.Characteristic              AS Characteristic,
	|	GoodsOfOrder.Purpose                  AS Purpose,
	|	CASE
	|		WHEN GoodsOfOrder.BatchesIndicationStatus = 14
	|			THEN GoodsOfOrder.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                                    AS Series,
	|	GoodsOfOrder.ProductsRecordingAsReceived   AS ProductsRecordingAsReceived,
	|	GoodsOfOrder.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	GoodsOfOrder.AssignmentGoodsReceipt     AS AssignmentGoodsReceipt,
	|	CASE
	|		WHEN GoodsOfOrder.BatchesIndicationStatusReceipt = 14
	|			THEN GoodsOfOrder.BatchReceipt
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                                    AS BatchReceipt,
	|	GoodsOfOrder.Count                  AS Count
	|INTO ResortableGoods
	|FROM
	|	Document.GoodsMisgradingNote.Goods AS GoodsOfOrder
	|WHERE
	|	GoodsOfOrder.Ref = &DocumentBasis
	|	AND (GoodsOfOrder.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		OR GoodsOfOrder.Package.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ProductLocations.Products,
	|	ProductLocations.Characteristic,
	|	ProductLocations.Purpose,
	|	CASE
	|		WHEN GoodsOfOrder.BatchesIndicationStatus = 14
	|			THEN GoodsOfOrder.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	GoodsOfOrder.ProductsRecordingAsReceived,
	|	GoodsOfOrder.CharacteristicRecordingAsReceived,
	|	GoodsOfOrder.AssignmentGoodsReceipt,
	|	CASE
	|		WHEN GoodsOfOrder.BatchesIndicationStatusReceipt = 14
	|			THEN GoodsOfOrder.BatchReceipt
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	ProductLocations.Count
	|FROM
	|	Document.GoodsMisgradingNote.Goods AS GoodsOfOrder
	|		INNER JOIN GoodsOfOrderInCommodityPlaces AS ProductLocations
	|		ON GoodsOfOrder.Products = ProductLocations.Products
	|			AND GoodsOfOrder.Characteristic = ProductLocations.Characteristic
	|			AND GoodsOfOrder.Purpose = ProductLocations.Purpose
	|			AND GoodsOfOrder.Series = ProductLocations.Series
	|WHERE
	|	GoodsOfOrder.Ref = &DocumentBasis
	|	AND GoodsOfOrder.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	ResortableGoods.Products                AS Products,
	|	ResortableGoods.Characteristic              AS Characteristic,
	|	ResortableGoods.Purpose                  AS Purpose,
	|	ResortableGoods.Series                       AS Series,
	|	ResortableGoods.ProductsRecordingAsReceived   AS ProductsRecordingAsReceived,
	|	ResortableGoods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	ResortableGoods.AssignmentGoodsReceipt     AS AssignmentGoodsReceipt,
	|	ResortableGoods.BatchReceipt          AS BatchReceipt,
	|	ResortableGoods.Count                  AS Count
	|FROM
	|	ResortableGoods AS ResortableGoods
	|
	|ORDER BY
	|	ResortableGoods.Products.Description,
	|	ResortableGoods.Characteristic.Description,
	|	ResortableGoods.Purpose.Description,
	|	ResortableGoods.Series.Description
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	DocumentHeader.Warehouse         AS Warehouse,
	|	DocumentHeader.EmployeeResponsible AS EmployeeResponsible
	|FROM
	|	Document.GoodsMisgradingNote AS DocumentHeader
	|WHERE
	|	DocumentHeader.Ref = &DocumentBasis
	|";
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResult = Query.ExecuteBatch();
	
	DocumentAttributes = QueryResult[5].Select();
	DocumentAttributes.Next();
	
	FillPropertyValues(ThisObject, DocumentAttributes);
	
	Goods.Load(QueryResult[4].Unload());
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
		
	If Not ValueIsFilled(VATActivityType) Then
		FillInTypeOfActivityVAT();
	EndIf;
	
	If Not ValueIsFilled(PriceKind) Then
		PriceKind = Catalogs.Warehouses.AccountingPriceType(Warehouse);
	EndIf;
	If Not ValueIsFilled(Currency) Then
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(
			Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind).PriceCurrency);
	EndIf;
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

Procedure FillInTypeOfActivityVAT()
	
	FillParameters = Documents.GoodsMisgrading.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(VATActivityType, FillParameters);
	
EndProcedure

#EndRegion

#Region InventoryKinds

// This function generates temporary document data.
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
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableOfGoods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	TableOfGoods.AssignmentGoodsReceipt AS AssignmentGoodsReceipt,
	|	TableOfGoods.BatchReceipt AS BatchReceipt,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfGoods.Count AS Count,
	|	0 AS QuantityByGBRN,
	|	TableOfGoods.Price AS Price,
	|	TableOfGoods.PriceOffBalance AS PriceOffBalance,
	|	&FieldTextTableOfGoodsCCDNumberWriteOff_ AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableOfGoods.ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived,
	|	TableOfGoods.AssignmentGoodsReceipt,
	|	TableOfGoods.BatchReceipt,
	|	TableOfGoods.InventoryOwnerAttribute,
	|	TableOfGoods.Count,
	|	TableOfGoods.QuantityByGBRN,
	|	TableOfGoods.Price,
	|	TableOfGoods.PriceOffBalance,
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
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt AS InventoryOwnerAttributeGoodsReceipt,
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
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	DimensionRecordingAsReceived.Products AS ProductsRecordingAsReceived,
	|	DimensionRecordingAsReceived.Characteristic AS CharacteristicRecordingAsReceived,
	|	DimensionRecordingAsReceived.Series AS BatchReceipt,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt AS InventoryOwnerAttributeGoodsReceipt,
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
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionRecordingAsReceived
	|		ON TableTypesOfStocks_.ItemsLocationAttributesReceipt = DimensionRecordingAsReceived.Ref
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
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		TableOfGoods,
		Query.Text,
		"&FieldTextTableOfGoodsCCDNumberWriteOff_",
		"TableOfGoods",
		"CCDNumberWriteOff",
		"TableOfGoods.CCDNumberWriteOff",
		"VALUE(Catalog.CCDNumbers.EmptyRef)");
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

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

Procedure FillInInventoryTypeProductList(Cancel)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableOfGoods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT DISTINCT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ProductData_1.KeepRecordsByCCD AS KeepRecordsByCCD,
	|	ProductData_1.TracedGoods AS TracedGoods,
	|	ProductData_1.FEACNUnitOfMeasure AS FEACNUnitOfMeasure
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|
	|UNION
	|
	|SELECT DISTINCT
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributes,
	|	ProductData_1.KeepRecordsByCCD AS KeepRecordsByCCD,
	|	ProductData_1.TracedGoods AS TracedGoods,
	|	ProductData_1.FEACNUnitOfMeasure AS FEACNUnitOfMeasure
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.ProductsRecordingAsReceived = ProductData_1.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT DISTINCT
	|	CatalogInventoryKinds.Ref		AS InventoryOwnerAttribute,
	|	CatalogInventoryKinds.SubjectToExcise AS SubjectToExcise,
	|	CatalogInventoryKinds.InventoryType	AS InventoryType
	|FROM
	|	Catalog.InventoryKinds AS CatalogInventoryKinds
	|WHERE
	|	CatalogInventoryKinds.Ref IN(&WriteOffInventory)";
	
	UnloadedColumns = "ItemsLocationAttributes, Products, ItemsLocationAttributesReceipt,
							|ProductsRecordingAsReceived, InventoryOwnerAttribute";
	
	Query.SetParameter("TableOfGoods",		Goods.Unload(, UnloadedColumns));
	Query.SetParameter("WriteOffInventory",	InventoryKinds.UnloadColumn("InventoryOwnerAttribute"));
	
	QueryResult = Query.ExecuteBatch();
	
	ProductDataDocuments			= QueryResult[1].Unload();
	PropertiesNames					= "KeepRecordsByCCD, TracedGoods, FEACNUnitOfMeasure";
	DataFromInventoryAccountingAnalysts = New Map;
	
	For Each DataString1 In ProductDataDocuments Do
		DimensionProperties = New Structure(PropertiesNames);
		FillPropertyValues(DimensionProperties, DataString1);
		
		DataFromInventoryAccountingAnalysts.Insert(DataString1.ItemsLocationAttributes, DimensionProperties);
	EndDo;
	
	TypesOfInventoryWriteOff	= QueryResult[2].Unload();
	InventoryTypes			= New Map;
	
	TransferredInventoryOwnerAttributes = New Array;
	ExciseLines = New Array;
	ExciseTaxableInventoryOwnerAttributes = New Map;
	For Each DataString1 In TypesOfInventoryWriteOff Do
		InventoryTypes.Insert(DataString1.InventoryOwnerAttribute, DataString1.InventoryType);
		If DataString1.SubjectToExcise Then
			ExciseTaxableInventoryOwnerAttributes.Insert(DataString1.InventoryOwnerAttribute, True);
		EndIf;
	EndDo;
	
	RowFilter = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In Goods Do
		
		GoodsQuantity = RowOfGoods.Count;
		QuantityOfGoodsAccordingToRPT = RowOfGoods.QuantityByGBRN;
		
		DisplayErrorMessages = True;
		DistributeBalanceOfQuantityAccordingToProductBatchIDOfGoods = QuantityOfGoodsAccordingToRPT > 0;
		CurCurrentInventoryType = Enums.InventoryTypes.OwnGoods;
		
		AnalyticsData = DataFromInventoryAccountingAnalysts.Get(RowOfGoods.ItemsLocationAttributes);
		AnalyticsDataLogging = DataFromInventoryAccountingAnalysts.Get(RowOfGoods.ItemsLocationAttributesReceipt);
		
		FillPropertyValues(RowFilter, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(RowFilter) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			CurStockType = InventoryTypes.Get(InventoryLine.InventoryOwnerAttribute);
			ExcisableItems = ExciseTaxableInventoryOwnerAttributes.Get(InventoryLine.InventoryOwnerAttribute);
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.ItemsLocationAttributesReceipt = RowOfGoods.ItemsLocationAttributesReceipt;
			
			If CurStockType = Enums.InventoryTypes.OwnGoods
				And ExcisableItems <> True
				Or CurStockType = Enums.InventoryTypes.ConsignedGoods Then
				
				NewRow.InventoryOwnerAttributeGoodsReceipt = RowOfGoods.InventoryOwnerAttribute;
				
			Else
				NewRow.InventoryOwnerAttributeGoodsReceipt	= NewRow.InventoryOwnerAttribute;
				CurCurrentInventoryType		= CurStockType;
				
				TransferredInventoryOwnerAttributes.Add(NewRow.InventoryOwnerAttribute);
				If ExcisableItems = True Then
					ExciseLines.Add(RowOfGoods.LineNumber);
				EndIf;
			EndIf;
			
			NewRow.Sum =
				?(Not ReceiveGoodsAtCostTheyWereIssuedFromWarehouse,
					Count * RowOfGoods.Price,
					0);
			
			NewRow.AmountOffBalance           =
				?(Not ReceiveGoodsAtCostTheyWereIssuedFromWarehouse,
					Count * RowOfGoods.PriceOffBalance,
					0);
			
			NewRow.Count			= Count;
			NewRow.QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			If ValueIsFilled(RowOfGoods.CCDNumber) Then
				
				NewRow.CCDNumberRegistration = RowOfGoods.CCDNumber;
				NewRow.QuantityByRNPTReceipt = Count * RowOfGoods.QuantityByGBRN / RowOfGoods.Count;
				
			ElsIf (AnalyticsData.KeepRecordsByCCD
					And AnalyticsDataLogging.KeepRecordsByCCD)
				Or (AnalyticsData.TracedGoods
					And AnalyticsDataLogging.TracedGoods) Then
				
				NewRow.CCDNumberRegistration = NewRow.CCDNumber;
				NewRow.QuantityByRNPTReceipt = NewRow.QuantityByGBRN;
				
			EndIf;
			
			InventoryLine.Count = InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN = InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			
			If DistributeBalanceOfQuantityAccordingToProductBatchIDOfGoods Then
				QuantityOfGoodsAccordingToRPT = QuantityOfGoodsAccordingToRPT - NewRow.QuantityByRNPTReceipt;
			EndIf;
			
			// Checking the filling of prices is performed after selecting the types of stocks, as it depends on the selected type of stocks.
			If Not ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
				
				If DisplayErrorMessages
					And Not ValueIsFilled(NewRow.AmountOffBalance)
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
				
				If DisplayErrorMessages
					And ValueIsFilled(NewRow.Sum)
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
				If DisplayErrorMessages
					And CurCurrentInventoryType = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider
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
				If DisplayErrorMessages
					And Not ValueIsFilled(NewRow.Sum)
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
				
				If DisplayErrorMessages
					And ValueIsFilled(NewRow.AmountOffBalance)
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
				If QuantityOfGoodsAccordingToRPT > 0 Then
					NewRow.QuantityByRNPTReceipt = NewRow.QuantityByRNPTReceipt + QuantityOfGoodsAccordingToRPT;
				EndIf;
				
				Break;
			EndIf;
			
			DisplayErrorMessages = False;
			
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

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.GoodsMisgrading.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.GoodsMisgrading.CollectionOfTabularPartsOfGoods();
		
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
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.ItemsLocationAttributes	= "ItemsLocationAttributesReceipt";
	FieldsNames.Products					= "ProductsRecordingAsReceived";
	FieldsNames.Characteristic				= "CharacteristicRecordingAsReceived";
	FieldsNames.Purpose					= "AssignmentGoodsReceipt";
	FieldsNames.Series						= "BatchReceipt";
	FieldsNames.BatchesIndicationStatus			= "BatchesIndicationStatusReceipt";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
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

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Warehouse";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query("
	|////////////////////////////////////////////////////////////////////////////////
	|// Check the correspondence of the table parts of the Products and types of stocks
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived,
	|	TableOfGoods.BatchReceipt
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|		TableOfGoods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|		TableOfGoods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|		TableOfGoods.BatchReceipt AS BatchReceipt,
	|		TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttributeGoodsReceipt,
	|		TableOfGoods.Count AS Count,
	|		CAST(TableOfGoods.Count * TableOfGoods.Price AS NUMBER(31,2)) AS Sum,
	|		CAST(TableOfGoods.Count * TableOfGoods.PriceOffBalance AS NUMBER(31,2)) AS AmountOffBalance
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|		TableTypesOfStocks_.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|		TableTypesOfStocks_.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|		TableTypesOfStocks_.BatchReceipt AS BatchReceipt,
	|		TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt AS InventoryOwnerAttributeGoodsReceipt,
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
	|	TableOfGoods.ItemsLocationAttributesReceipt,
	|	TableOfGoods.ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived,
	|	TableOfGoods.BatchReceipt,
	|	TableOfGoods.InventoryOwnerAttributeGoodsReceipt
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.Sum) <> 0
	|	OR SUM(TableOfGoods.AmountOffBalance) <> 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|");
	
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
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
Procedure CheckCompletionOfAppointments(Cancel)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Goods.LineNumber             AS LineNumber,
	|	Goods.Purpose              AS Purpose,
	|	Goods.AssignmentGoodsReceipt AS AssignmentGoodsReceipt
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber               AS LineNumber,
	|	""AssignmentGoodsReceipt""      AS FieldName,
	|	&ErrorTextNotFilledInCorrectly AS ErrorText
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|	AND CAST(Goods.Purpose AS Catalog.Assignments).AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
	|	AND (NOT CAST(Goods.Purpose AS Catalog.Assignments).Partner =
	|				ISNULL(CAST(Goods.AssignmentGoodsReceipt AS Catalog.Assignments).Partner, VALUE(Catalog.Partners.EmptyRef))
	|		OR NOT CAST(Goods.Purpose AS Catalog.Assignments).Contract =
	|				ISNULL(CAST(Goods.AssignmentGoodsReceipt AS Catalog.Assignments).Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef)))
	|
	|ORDER BY
	|	LineNumber
	|";
	
	Query.SetParameter("Goods", Goods.Unload(, "LineNumber, Purpose, AssignmentGoodsReceipt"));
	
	Query.SetParameter(
		"ErrorTextNotFilledInCorrectly",
		NStr("vi = 'Trong dòng %1 của danh sách ""Hàng hóa"", cần đặt riêng hàng hóa được ghi tăng theo mục đích của người đặt gia công mà trong đó bạn hàng/hợp đồng khác với bạn hàng/hợp đồng ban đầu.';
			|ru = 'В строке %1 списка ""Товары"" приходуемый товар должен обосабливаться под назначение давальца, в котором партнер/договор не отличается от исходного.';
			|en = 'In line %1 of the ""Goods"" list, the stock surplus must be assigned for the provider assignment, in which the partner/contract is different from the initial one.'; fa = 'In line %1 of the ""Goods"" list, the stock surplus must be assigned for the provider assignment, in which the partner/contract is different from the initial one.';
			|it = 'Nella riga %1 dell''elenco ""Merci"", la merce in arrivo deve essere divisa per assegnazione del fornitore, in cui il partner/contratto non differisce da quello originario.';
			|pl = 'W wierszu %1 listy ""Towary"" rejestrowany towar powinien być oddzielony pod przeznaczenie właściciela surowców, w którym partner/umowa nie różni się od źródłowego.';
			|tr = '""Ürünler"" listesinin %1satırında, stok fazlası mallar, iş ortağının/sözleşmenin orijinalinden farklı olmadığı durumlarda, sağlayıcının atamasına uyarlanmalıdır.'"));
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		Common.MessageToUser(
			StrTemplate(Selection.ErrorText, Selection.LineNumber),
			ThisObject,
			CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, Selection.FieldName),,
			Cancel);
		
	EndDo;
	
EndProcedure
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

Procedure ClearDataOnImportedGoods()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SourceTable.LineNumber					AS LineNumber,
	|	SourceTable.Products				AS Products,
	|	SourceTable.ProductsRecordingAsReceived	AS ProductsRecordingAsReceived,
	|	SourceTable.CCDNumber					AS CCDNumber,
	|	SourceTable.QuantityByGBRN			AS QuantityByGBRN
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS SourceTable
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	ISNULL(MAX(TableOfGoods.ClearCCDNumber), FALSE) AS ClearCCDNumber,
	|	ISNULL(MAX(TableOfGoods.ClearAmountByProductBatchID), FALSE) AS ClearAmountByProductBatchID
	|FROM
	|	(SELECT
	|		GoodsTable.LineNumber	AS LineNumber,
	|		TRUE						AS ClearCCDNumber,
	|		FALSE						AS ClearAmountByProductBatchID
	|	FROM
	|		GoodsTable AS GoodsTable
	|			INNER JOIN Catalog.Products AS ItemDataForWriteOff
	|			ON GoodsTable.Products = ItemDataForWriteOff.Ref
	|		
	|			INNER JOIN Catalog.Products AS ItemDataEntry
	|			ON GoodsTable.ProductsRecordingAsReceived = ItemDataEntry.Ref
	|	
	|	WHERE
	|		GoodsTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|		AND ItemDataEntry.KeepRecordsByCCD
	|		AND ((ItemDataForWriteOff.KeepRecordsByCCD
	|				AND NOT ItemDataEntry.TracedGoods
	|				AND ItemDataEntry.TracedGoods = ItemDataForWriteOff.TracedGoods)
	|			OR (ItemDataEntry.TracedGoods
	|				AND ItemDataEntry.TracedGoods = ItemDataForWriteOff.TracedGoods
	|				AND ItemDataEntry.FEACNUnitOfMeasure = ItemDataForWriteOff.FEACNUnitOfMeasure))
	|	
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTable.LineNumber	AS LineNumber,
	|		FALSE						AS ClearCCDNumber,
	|		TRUE						AS ClearAmountByProductBatchID
	|	FROM
	|		GoodsTable AS GoodsTable
	|			INNER JOIN Catalog.Products AS ItemDataForWriteOff
	|			ON GoodsTable.Products = ItemDataForWriteOff.Ref
	|		
	|			INNER JOIN Catalog.Products AS ItemDataEntry
	|			ON GoodsTable.ProductsRecordingAsReceived = ItemDataEntry.Ref
	|	WHERE
	|		GoodsTable.QuantityByGBRN <> 0
	|		AND ItemDataEntry.TracedGoods
	|		AND ItemDataEntry.TracedGoods = ItemDataForWriteOff.TracedGoods
	|		AND ItemDataEntry.FEACNUnitOfMeasure = ItemDataForWriteOff.FEACNUnitOfMeasure
	|	
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.LineNumber
	|
	|HAVING
	|	ISNULL(MAX(TableOfGoods.ClearCCDNumber), FALSE)
	|	OR ISNULL(MAX(TableOfGoods.ClearAmountByProductBatchID), FALSE)
	|
	|ORDER BY
	|	LineNumber";
	
	UnloadedColumns = "LineNumber, Products, ProductsRecordingAsReceived, CCDNumber, QuantityByGBRN";
	
	Query.SetParameter("GoodsTable", Goods.Unload(, UnloadedColumns));
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		If Selection.ClearCCDNumber Then
			Goods[Selection.LineNumber - 1].CCDNumber = Undefined;
		EndIf;
		
		If Selection.ClearAmountByProductBatchID Then
			Goods[Selection.LineNumber - 1].QuantityByGBRN = 0;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
