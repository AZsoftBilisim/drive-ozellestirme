#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.InventoryConsumption - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes);
	
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
//	DocumentTables - See Documents.InventoryConsumption.CollectionOfTabularPartsOfGoods.
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

// Sets the status for the document object
//
// Parameters:
// 		NewStatus - String - Name of the status that will be set for orders
// 		AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
// 		Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	Status = Enums.InternalConsumptionStatuses[NewStatus];
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryConsumption);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	Return CheckFilling();
	
EndFunction

// This function generates temporary document data.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Warehouse AS Warehouse,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	&Currency AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	&VATTaxation AS ConsumptionForActivity,
	|	VALUE(Enum.BusinessTransactions.AssemblyFromComponents) AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END AS Manager,
	|	CASE
	|		WHEN ISNULL(SalesOpportunitiesToCustomer.EnabledGoodsAssignmentInSalesOpportunity, FALSE)
	|				AND &GenerateInventoryOwnerAttributesBySalesOpportunities
	|			THEN &SalesOpportunity
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END AS SalesOpportunity,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON BusinessStructure.Ref = &Department
	|		
	|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		ON SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatusSender AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END AS QuantityByGBRN,
	|	TableOfGoods.ExpenseItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings AS GLAccountSettings,
	|	TableOfGoods.Individual AS Individual,
	|	TableOfGoods.RowID AS RowID,
	|	TableOfGoods.InventoryConsumptionOrder AS OrderDocument,
	|	TableOfGoods.RowCode AS RowCode,
	|	TableOfGoods.ProductsGroup,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	&Warehouse AS Warehouse,
	|	&SalesOpportunity AS SalesOpportunity,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TableOfGoods.ExpenseItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings AS GLAccountSettings,
	|	TableOfGoods.Individual AS Individual,
	|	TableOfGoods.RowID AS RowID,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ProductsGroup,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	CatalogProducts.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|												VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	Dimension.StorageLocation AS Warehouse,
	|	&SalesOpportunity AS SalesOpportunity,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TableOfGoods.ExpenseItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings AS GLAccountSettings,
	|	TableOfGoods.Individual AS Individual,
	|	TableOfGoods.RowID AS RowID,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ProductsGroup,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
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
	|	&SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.GLAccountSettings AS GLAccountSettings,
	|	TableTypesOfStocks_.Individual AS Individual,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.ProductsGroup AS ProductsGroup,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.ExciseTaxAmount AS ExciseTaxAmount,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse,
	|	Dimension.StorageLocation AS Warehouse,
	|	TableTypesOfStocks_.SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.GLAccountSettings AS GLAccountSettings,
	|	TableTypesOfStocks_.Individual AS Individual,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.ProductsGroup AS ProductsGroup,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes";
	
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
	Query.SetParameter("Currency", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("Manager", EmployeeResponsible);
	Query.SetParameter("Department", Department);
	Query.SetParameter("SalesOpportunity", SalesOpportunity);
	Query.SetParameter("ConsumptionByOrders", ConsumptionByOrders);
	Query.SetParameter("VATTaxation", ConsumptionForActivity);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers", GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities", GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	
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

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);

	InventoryConsumptionLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	If BusinessOperation = Enums.BusinessTransactions.TransferToProduction And Not DeletionMark Then
		MessageText = NStr("vi = 'Cấm ghi lại chứng từ, bởi vì giao dịch ""Chuyển giao vào sản xuất"" vẫn chưa được sử dụng.
								|Đang tạo chuyển giao nguyên vật liệu trong biểu mẫu ""Sản xuất - Nhận và trả lại nguyên vật liệu"".';
								|ru = 'Запись документа запрещена, т.к. операция ""Передача в производство"" больше не используется.
								|Передача материалов оформляется в форме ""Производство - Получение и возврат материалов"".';
								|en = 'It is prohibited to save the document because operation ""Transfer to production"" is not used.
								|Material transfer is recorded in form ""Production — Receipt and return of materials"".'; fa = 'It is prohibited to save the document because operation ""Transfer to production"" is not used.
								|Material transfer is recorded in form ""Production — Receipt and return of materials"".';
								|it = 'La scrittura di un documento è vietata, perché l''operazione ""Trasferimento in produzione"" non viene più utilizzata.
								|Il trasferimento dei materiali viene formalizzato sotto forma ""Produzione - Ricevimento e restituzione dei materiali"".';
								|pl = 'Zapisywanie dokumentu jest zabronione, ponieważ operacja ""Передача в производство"" więcej nie jest obsługiwana.
								|Przekazanie materiałów jest rejestrowane w formularzu ""Производство - Получение и возврат материалов"".';
								|tr = '""Üretime aktar"" işlemi artık kullanılmadığı için belge kaydı yasaktır.
								| Malzemelerin aktarımı ""Üretim - Malzemelerin teslim alınması ve iadesi"" şeklinde gerçekleştirilir.'");
		Common.MessageToUser(MessageText, Ref,,, Cancel);
	EndIf;

	InventoryInOperationServer.InventoryConsumption_BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	For Each RowData In Goods Do
		
		If Not ExpenseLineOfBusinessIsSpecifiedInList Then
			RowData.LineOfBusiness = LineOfBusiness;
		EndIf;
		
		If ConsumptionByOrders 
			And ValueIsFilled(InventoryConsumptionOrder) 
			And Not ValueIsFilled(RowData.InventoryConsumptionOrder) Then
		
			// If the transfer is on order, then you need to fill in an empty order
			RowData.InventoryConsumptionOrder = InventoryConsumptionOrder;
			
		ElsIf Not ValueIsFilled(RowData.InventoryConsumptionOrder)
			And RowData.InventoryConsumptionOrder <> Undefined Then
			
			RowData.InventoryConsumptionOrder = Undefined;
			
		EndIf;
		
	EndDo;
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	ProductsServer.ClearUnusedSeries(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryConsumption));
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.InventoryConsumption.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);

	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventoryConsumption.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods");
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.InventoryConsumption.AccountingAccountSettings_(BusinessOperation));
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	InventoryConsumptionLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.VendorInvoice") 
		Or TypeOf(FillingData) = Type("Structure")
			And FillingData.Property("DocumentBasis")
			And TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
		
		FillInBasedOnReceipt(FillingData);
	
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ApplicationForCollateral") Then
		FillInDocumentBasedOnSupplyRequest(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.RMRequest") Then
		
		DocumentBasis = FillingData;
	ElsIf TypeOf(FillingData) = Type("Structure") And FillingData.Property("Goods") Then
		
		If FillingData.Property("HeaderAttributes") Then
			FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
		Else
			FillPropertyValues(ThisObject, FillingData);
		EndIf;
		If TypeOf(FillingData.Goods) = Type("Array") Then
			UploadProducts(FillingData.Goods);
		Else
			Goods.Load(FillingData.Goods.Unload());
		EndIf;
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryConsumption);
		ProductsServer.FillInSeriesByFEFO(ThisObject,SeriesSpecificationParameters, False);
	
	ElsIf TypeOf(FillingData) = Type("DocumentRef.InventoryConsumption") Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	Else // Filling in by order(s).

		If TypeOf(FillingData) = Type("Structure") And FillingData.Property("AnArrayOfOrders") Then
			
			FillingStructure = FillingData;
			
		Else
			
			BusinessOperation = Metadata().Attributes.BusinessOperation.FillValue;
			Status = Metadata().Attributes.Status.FillValue;
			If TypeOf(FillingData) = Type("Structure") Then
				FillPropertyValues(ThisObject, FillingData);
			EndIf;
			
		EndIf;
		
		If FillingStructure <> Undefined Then
			
			FillInFromOrder(FillingStructure);
			
		EndIf;
	EndIf;
	
	InventoryConsumptionLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventoryConsumption.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.InventoryConsumption.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	// Checking the quantity including goods.
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);

	// Checking the characteristics, including goods.
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	
	// Checking the filling of the series, including the series.
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryConsumption),
		Cancel,
		NotCheckedAttributeArray);
	InventoryInOperationServer.CheckTransferIntoOperation(ThisObject, NotCheckedAttributeArray, Cancel);
	WarehouseIsRequired          = BusinessOperation = Enums.BusinessTransactions.TransferToOperation;
	ItemsTypes         = New Map;
	
	For CurIndex__ = 0 To Goods.Count()-1 Do
		
		If ConsumptionByOrders
			And Not ValueIsFilled(InventoryConsumptionOrder)
			And Not ValueIsFilled(Goods[CurIndex__].InventoryConsumptionOrder) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Lệnh"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'Не заполнено поле ""Распоряжение"" в строке %LineNumber% списка ""Товары""';
							|en = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list'; fa = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list';
							|it = 'Campo ""Disposizione"" non compilato nella riga %LineNumber% dell''elenco ""Articoli""';
							|pl = 'Pole ""Zamówienie"" w wierszu %LineNumber% listy ""Towary""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Emir"" alanı doldurulmamış'");
			ErrorText =  StrReplace(ErrorText, "%LineNumber%", Goods[CurIndex__].LineNumber);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", Goods[CurIndex__].LineNumber, "InventoryConsumptionOrder"),
				,
				Cancel);
			
		EndIf;
		
		// A subdivision is required if the work is specified in the document.
		// A warehouse is required if there are goods/containers in the document.
		If BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand
			And Not WarehouseIsRequired Then
			
			ItemsType = ItemsTypes.Get(Goods[CurIndex__].Products);
			If ItemsType = Undefined Then
				ItemsType = Common.ObjectAttributeValue(Goods[CurIndex__].Products, "ItemsType");
				ItemsTypes.Insert(Goods[CurIndex__].Products, ItemsType);
			EndIf;
			
			If Not ItemsType = Enums.ItemsTypes.Work_5 Then
				WarehouseIsRequired = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Not WarehouseIsRequired Then
		NotCheckedAttributeArray.Add("Warehouse");
	EndIf;
	
	DepartmentMandatory =
		GetFunctionalOption("UseProduction")
		Or GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers")
		Or BusinessOperation = Enums.BusinessTransactions.TransferToOperation;
	
	If Not DepartmentMandatory Then
		NotCheckedAttributeArray.Add("Department");
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.RowCode");
	If ConsumptionByOrders And Not UserRightsCached.InventoryConsumptionInExcessOfOrder() Then
		
		ErrorTemplate = NStr("vi = 'Không có quyền lập chứng từ tiêu dùng nội bộ vượt quá đơn hàng (dòng %1 trong danh sách ""Hàng hóa"")';
							|ru = 'Нет доступа для оформления внутреннего потребления сверхзаказа (строка %1 списка ""Товары"")';
							|en = 'No access for registration of the extra order internal consumption (the %1 line of the ""Goods"" list)'; fa = 'No access for registration of the extra order internal consumption (the %1 line of the ""Goods"" list)';
							|it = 'Non c''è l''accesso per generare il consumo interno surplus (riga %1 dell''elenco ""Merci"")';
							|pl = 'Brak dostępu do rejestracji wewnętrznego zużycia ponad-zamówienia (wiersz %1 listy „Wiersze pozycji”)';
							|tr = 'İç tüketim aşırı emri için erişim yok (""Ürünler"" listesinin %1 satırı)'");
		For Each String In Goods Do
			
			If String.RowCode = 0 Then
				DataPath = CommonClientServer.PathToTabularSection("Goods", String.LineNumber, "LineNumber");
				ErrorText = StrTemplate(ErrorTemplate, String.LineNumber);
				Common.MessageToUser(ErrorText, ThisObject, DataPath, , Cancel);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	CheckArticlesAndAnalytics = True;
	CheckArticlesAndAnalytics = (BusinessOperation <> Enums.BusinessTransactions.TransferToOperation);
	If CheckArticlesAndAnalytics Then
		ItemsAndDimensionsSelectionParameters = Documents.InventoryConsumption.ItemsAndDimensionsSelectionParameters(BusinessOperation);
		IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	EndIf;
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName = "Goods";
	CheckParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	CheckParameters.DetailsNameItemOfAssetsLiabilities = "ExpenseItem";
	CheckParameters.NameOfAssetLiabilityAnalystDetails = "AssetsLiabilitiesDimension";
	
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject,
		ConsumptionForActivity,
		CheckParameters,
		Cancel);
	
	InventoryConsumptionLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	InventoryConsumptionLocalization.Posting(ThisObject, Cancel, PostingMode);
	If Not Cancel Then
		ExcisableGoodsAccounting.CreateTaskToRecordAmountOfExciseTax(ThisObject);
		OtherAssetsLiabilitiesServer.CreateTaskForNonOperationalDocumentExecution(ThisObject);
	EndIf;
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	InventoryConsumptionLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Status = Enums.InternalConsumptionStatuses.Shipped;

	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	InventoryConsumptionOrder = Documents.InventoryConsumptionOrder.EmptyRef();
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	ConsumptionByOrders = False;
	ThereAreProductsMarkedWithSPMS = False;
	DocumentBasis = Undefined;
	InventoryOwnerAttributesAreSpecifiedManually = False;
	
	InventoryKinds.Clear();
	SetOfSeries.Clear();

	For Each TSRow In Goods Do
		TSRow.RowCode                    = 0;
		TSRow.InventoryConsumptionOrder = Documents.InventoryConsumptionOrder.EmptyRef();
		TSRow.RowID          = "";
		TSRow.Lot = Catalogs.LotsOfInventoryInOperation.EmptyRef();
		TSRow.AssetID = "";
	EndDo;
	
	DefaultAssignment = LinesOfBusinessServer.PushingAssignment(LineOfBusiness);
	InvoicesServer.FillInAssignmentsInTablePart(Goods, DefaultAssignment);
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	InventoryConsumptionLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

// Parameters:
//    Table - See AccessManagement.AccessValuesSetsTable
Procedure FillAccessValuesSets(Table) Export
	
	TabRow = Table.Add();
	TabRow.AccessValue = Organization;
	
	TabRow = Table.Add();
	TabRow.AccessValue = Warehouse;
	
	TabRow = Table.Add();
	TabRow.AccessValue = Department;
	
EndProcedure

Procedure FillInFromOrder(FillingStructure)
	
	AnArrayOfOrders = FillingStructure.AnArrayOfOrders;
	
	FillParameters = Documents.InventoryConsumption.DocumentFillingParameters();
	FillPropertyValues(FillParameters, FillingStructure);
	Documents.InventoryConsumption.InitializeFillingParameters(FillParameters,
		FillingStructure.HeaderAttributes, AnArrayOfOrders);
	
	InvoiceTable = Documents.InventoryConsumption.TableDataAndDocument(Ref);
	
	Documents.InventoryConsumption.FillInByOrdersOrders(InvoiceTable, Ref, FillParameters, PackageBarcodes);
	
	If FillParameters.FillByWarehouseDocument Then
		InvoiceTable.Columns.Count.Name        = "QuantityBeforeChange_";
		InvoiceTable.Columns.NoteQuantity.Name = "Count";
	Else
		InvoiceTable.Columns.Count.Name        = "QuantityBeforeChange_";
		InvoiceTable.Columns.QuantityInOrder.Name = "Count";
	EndIf;
	
	InvoicesServer.DeleteEmptyLines(InvoiceTable, "Count");
	
	Goods.Load(InvoiceTable);
	
	Documents.InventoryConsumption.FillInHeaderOfOrderDocument(ThisObject, FillParameters, FillingStructure.AnArrayOfOrders);
	
	Documents.InventoryConsumption.ProcessDocumentAfterAddingLines(ThisObject);
	
	// Filling in the series.
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryConsumption);
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters, False);
	
	Documents.InventoryConsumption.UpdateDependentDetailsOfTablePart(Goods, FillParameters);
	
EndProcedure

Procedure FillInBasedOnReceipt(FillingData)
	
	Query = New Query(
		"SELECT
		|	VendorInvoice.Organization AS Organization,
		|	VendorInvoice.Warehouse AS Warehouse,
		|	NOT VendorInvoice.Posted AS ThereAreErrorsPosted,
		|	VendorInvoice.Ref AS DocumentBasis,
		|	VendorInvoice.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Document.VendorInvoice AS VendorInvoice
		|WHERE
		|	VendorInvoice.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PurchaseOfGoodsServicesGoods.Products AS Products,
		|	PurchaseOfGoodsServicesGoods.Characteristic AS Characteristic,
		|	PurchaseOfGoodsServicesGoods.Package AS Package,
		|	PurchaseOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackages,
		|	PurchaseOfGoodsServicesGoods.Count AS Count,
		|	PurchaseOfGoodsServicesGoods.Warehouse AS Warehouse,
		|	CASE
		|		WHEN (PurchaseOfGoodsServicesGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|				OR PurchaseOfGoodsServicesGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage))
		|				AND NOT PurchaseOfGoodsServicesGoods.ToExpenseAs
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS WarehouseIsRequired,
		|	PurchaseOfGoodsServicesGoods.Series AS Series,
		|	PurchaseOfGoodsServicesGoods.Purpose AS Purpose
		|FROM
		|	Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
		|WHERE
		|	PurchaseOfGoodsServicesGoods.Ref = &Ref
		|	AND PurchaseOfGoodsServicesGoods.Products.ItemsType IN 
		|		(VALUE(Enum.ItemsTypes.OwnGoods), 
		|		 VALUE(Enum.ItemsTypes.Work_5))
		|	AND NOT PurchaseOfGoodsServicesGoods.ToExpenseAs
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PurchaseOfGoodsServicesSeries.Series AS Series,
		|	PurchaseOfGoodsServicesSeries.Count AS Count,
		|	PurchaseOfGoodsServicesSeries.Products AS Products,
		|	PurchaseOfGoodsServicesSeries.Characteristic AS Characteristic,
		|	PurchaseOfGoodsServicesSeries.Purpose AS Purpose
		|FROM
		|	Document.VendorInvoice.SetOfSeries AS PurchaseOfGoodsServicesSeries
		|WHERE
		|	PurchaseOfGoodsServicesSeries.Ref = &Ref
		|	AND PurchaseOfGoodsServicesSeries.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods))");
	
	Query.SetParameter("Ref", FillingData.DocumentBasis);
	
	QueryResult = Query.ExecuteBatch();
	
	SampleBankingDetails = QueryResult[0].Select();
	If Not SampleBankingDetails.Next() Then
		Return;
	EndIf;

	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		FillingData.DocumentBasis,,
		SampleBankingDetails.ThereAreErrorsPosted,);
		
	If QueryResult[1].IsEmpty() Then
		ErrorText = NStr("vi = 'Tiếp nhận không chứa hàng hóa. Không thể nhập trên cơ sở.';
						|ru = 'Поступление не содержит товаров. Ввод на основании невозможен.';
						|en = 'Receipt does not contain any goods. Cannot generate any documents from it.'; fa = 'Receipt does not contain any goods. Cannot generate any documents from it.';
						|it = 'L''arrivo non contiene merci. L''immissione in base alla causale non è possibile.';
						|pl = 'Wpływ nie zawiera towarów. Wprowadzanie na podstawie nie jest możliwe.';
						|tr = 'Makbuz, ürün içermemektedir. Temele dayalı giriş mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	
	FillPropertyValues(ThisObject, SampleBankingDetails);
	
	GoodsTable = QueryResult[1].Unload();
	Goods.Load(GoodsTable);
	SetOfSeries.Load(QueryResult[2].Unload());
	
	TableWarehouses_ = GoodsTable.Copy(GoodsTable.FindRows(New Structure("WarehouseIsRequired", True)), "Warehouse");	
	WarehouseArray = TMCommonUse.DeleteDuplicateElementsFromArray(TableWarehouses_.UnloadColumn("Warehouse"));
	If WarehouseArray.Count() = 1 Then
		Warehouse = WarehouseArray[0];
	ElsIf WarehouseArray.Count() > 0 Then
		ErrorText = NStr("vi = 'Không hỗ trợ nhập trên cơ sở tiếp nhận tại nhiều kho khác nhau.';
						|ru = 'Ввод на основании поступления на разные склады не поддерживается.';
						|en = 'Generation of documents from receipts to different warehouses is not supported.'; fa = 'Generation of documents from receipts to different warehouses is not supported.';
						|it = 'L''immissione in base agli arrivi ai magazzini diversi non è supportata.';
						|pl = 'Wprowadzenie na podstawie wpływów do różnych magazynów nie jest obsługiwane.';
						|tr = 'Farklı depolara makbuza dayalı giriş desteklenmez.'");
		Raise ErrorText;
	EndIf;
	
	BusinessOperation = FillingData.BusinessOperation;
	
	If Not LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(LineOfBusiness) Then
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
	EndIf;
	
	AssignmentToFillIn = LinesOfBusinessServer.PushingAssignment(LineOfBusiness);
	For Each String In Goods Do
		If String.Purpose <> AssignmentToFillIn Then
			String.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	For Each String In SetOfSeries Do
		If String.Purpose <> AssignmentToFillIn Then
			String.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	
	// Filling in the series indication statuses
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryConsumption);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Procedure FillInDocumentBasedOnSupplyRequest(ApplicationForCollateral)
	
	ReceivingParameters = Documents.ApplicationForCollateral.ParametersForReceivingFillInDataBasedOn();
	ReceivingParameters.ItemsType = ProductsServer.SupportedDocumentItemTypes(Ref);
	FillingData = Documents.ApplicationForCollateral.FillingDataBasedOn(
		ApplicationForCollateral,
		ReceivingParameters);
	
	// Safe filling of the header:
	HeaderProperties = New Structure;
	HeaderProperties.Insert("Organization");
	HeaderProperties.Insert("Warehouse");
	HeaderProperties.Insert("Department");
	HeaderProperties.Insert("LineOfBusiness");
	FillPropertyValues(HeaderProperties, FillingData.Header);
	FillPropertyValues(ThisObject, HeaderProperties);
	
	DocumentBasis = ApplicationForCollateral;
	
	// Filling PM:
	Goods.Load(FillingData.Goods);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	If Not LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(LineOfBusiness) Then
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
	EndIf;
	
	EmployeeResponsible    = Users.CurrentUser();
	Department    = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	PriceKind          = Catalogs.Warehouses.AccountingPriceType(Warehouse);
	
	If Not GetFunctionalOption("UseInventoryConsumptionStatuses")
		Or Patch 
		Or BusinessOperation <> Enums.BusinessTransactions.TransferToOperation Then
		Status = Enums.InternalConsumptionStatuses.Accepted;
	EndIf;
	
	FillParameters = Documents.InventoryConsumption.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(ConsumptionForActivity, FillParameters);
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
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
	|	DocumentDataTable.Department,
	|	DocumentDataTable.Manager,
	|	DocumentDataTable.SalesOpportunity,
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
	|WHERE
	|	TableOfGoods.Products.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|													VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.InventoryConsumption.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.InventoryConsumption.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Warehouse,
																		Department,
																		Undefined);
																		
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.BatchesIndicationStatus = "BatchesIndicationStatusSender";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager		= TemporaryDocumentDataTables();
	RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
	
		NamesOfSummationColumns = "Count, QuantityByGBRN";
		NamesOfSummationColumns = NamesOfSummationColumns + ", ExciseTaxAmount";
		ExcisableGoodsAccounting.CalculateAmountOfExciseTax(ThisObject, FillParameters, , Cancel);
		AdditionalProperties.Insert("WriteDownAmountOfExciseTax", FillParameters.CalculateAmountOfExciseTax);
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, Series", NamesOfSummationColumns);
		
		FillInExpenseItemOfInventoryTypes();
	ElsIf GetFunctionalOption("UseExcisableGoods")
		And LineOfBusiness <> Common.ObjectAttributeValue(Ref, "LineOfBusiness") Then
		AdditionalProperties.Insert("WriteDownAmountOfExciseTax", True);
	EndIf;
	
	If Not Cancel Then
		FillInRecipientSInventoryType();
		
		TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	EndIf;
	
EndProcedure

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	FillParameters.ReversedDocument = ReversedDocument;
	
	SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
	SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
	If GetFunctionalOption("UseExcisableGoods") Then
		FillParameters.CalculateAmountOfExciseTax = True;
		SelectionOfStockTypes_.SubjectToExcise.Clear();
	EndIf;
	Return FillParameters;
	
EndFunction

#EndRegion

#Region Other

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Date, Organization, Warehouse, ConsumptionForActivity";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

// The function checks for changes in the "Products" table part relative to the "inventory Types" table part of the document.
//
// Parameters:
//	TempTablesManager - TempTablesManager - temporary table manager.
//
// Returns:
//	Boolean - The truth is that the goods have been changed
//           False - the products are not changed.
//
Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.ExpenseItem AS ExpenseItem,
	|		TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|		TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|		TableOfGoods.GLAccountSettings AS GLAccountSettings,
	|		TableOfGoods.RowID AS RowID,
	|		TableOfGoods.Purpose AS Purpose,
	|		TableOfGoods.ProductsGroup AS ProductsGroup,
	|		TableOfGoods.Individual AS Individual,
	|		TableOfGoods.Count AS Count
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|		TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|		TableTypesOfStocks_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|		TableTypesOfStocks_.GLAccountSettings AS GLAccountSettings,
	|		TableTypesOfStocks_.RowID AS RowID,
	|		TableTypesOfStocks_.Purpose AS Purpose,
	|		TableTypesOfStocks_.ProductsGroup AS ProductsGroup,
	|		TableTypesOfStocks_.Individual AS Individual,
	|		-TableTypesOfStocks_.Count AS Count
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings,
	|	TableOfGoods.RowID,
	|	TableOfGoods.Purpose,
	|	TableOfGoods.ProductsGroup,
	|	TableOfGoods.Individual
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

// The procedure fills in the item and expense analysis of the document's inventory types.
//
Procedure FillInExpenseItemOfInventoryTypes()
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In Goods Do
		
		GoodsQuantity = RowOfGoods.Count;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.ExpenseItem				= RowOfGoods.ExpenseItem;
			NewRow.DimensionOfExpenses			= RowOfGoods.DimensionOfExpenses;
			NewRow.AssetsLiabilitiesDimension	= RowOfGoods.AssetsLiabilitiesDimension;
			NewRow.Individual				= RowOfGoods.Individual;
			NewRow.Purpose					= RowOfGoods.Purpose;
			NewRow.LineOfBusiness     = RowOfGoods.LineOfBusiness;
			NewRow.Count					= Count;
			NewRow.QuantityByGBRN			= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			NewRow.ProductsGroup				= RowOfGoods.ProductsGroup;
			NewRow.RowID			= RowOfGoods.RowID;
			NewRow.GLAccountSettings		= RowOfGoods.GLAccountSettings;
			NewRow.ExciseTaxAmount					= Count * InventoryLine.ExciseTaxAmount / InventoryLine.Count;
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.ExciseTaxAmount		= InventoryLine.ExciseTaxAmount - NewRow.ExciseTaxAmount;
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			
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
	
EndProcedure

Procedure FillInRecipientSInventoryType()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Inventories.LineNumber								AS LineNumber,
	|	Inventories.ProductsGroup							AS ProductsGroup,
	|	VALUE(Catalog.Assignments.EmptyRef)	AS Purpose,
	|	Inventories.InventoryOwnerAttribute								AS InventoryOwnerAttribute
	|INTO Inventories
	|FROM
	|	&InventoryKinds AS Inventories
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inventories.LineNumber			AS LineNumber,
	|	InventoryKinds.Ref			AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryType		AS InventoryType,
	|	InventoryKinds.GoodsOwner	AS GoodsOwner,
	|	InventoryKinds.Counterparty		AS Counterparty,
	|	InventoryKinds.Contract			AS Contract,
	|	InventoryKinds.Terms		AS Terms,
	|	InventoryKinds.Currency			AS Currency,
	|	CASE
	|		WHEN &ConsumptionForActivity <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|				AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|			THEN &ConsumptionForActivity
	|		ELSE InventoryKinds.VATTaxation
	|	END						AS VATTaxation,
	|	&TaxationOfOrganization	AS TaxationOfOrganization,
	|	InventoryKinds.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Inventories.ProductsGroup		AS ProductsGroup,
	|	UNDEFINED				AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	InventoryKinds.SubjectToExcise AS SubjectToExcise,
	|	InventoryKinds.BusinessUnitProduction AS BusinessUnitProduction,
	|	CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|				AND InventoryKinds.Contract.ContractType = VALUE(Enum.ContractTypes.ReceiptForTolling2_5)
	|			THEN VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|				AND InventoryKinds.Contract.ContractType = VALUE(Enum.ContractTypes.ReceiptForTolling2_5)
	|			THEN VALUE(Enum.BusinessTransactions.TollManufacturing2_5)
	|		ELSE
	|			VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|	END						AS BusinessTransactionStockType
	|FROM
	|	Inventories AS Inventories
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON InventoryKinds.Ref = Inventories.InventoryOwnerAttribute
	|WHERE
	|	(InventoryKinds.VATTaxation <> &ConsumptionForActivity
	|		AND &ConsumptionForActivity <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|	)
	|	OR InventoryKinds.ProductsGroup <> Inventories.ProductsGroup";
	
	TaxationOfOrganization = VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales;
	
	Query.SetParameter("ConsumptionForActivity", ConsumptionForActivity);
	Query.SetParameter("TaxationOfOrganization", TaxationOfOrganization);
	Query.SetParameter("InventoryKinds", InventoryKinds.Unload(, "LineNumber, ProductsGroup, InventoryOwnerAttribute"));
	
	Selection = Query.Execute().Select();
	
	TypesOfStocksOfRecipient = New Map;
	
	While Selection.Next() Do
		RecipientInventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(Organization,
																			Selection.BusinessTransactionStockType,
																			Selection);
		TypesOfStocksOfRecipient.Insert(Selection.LineNumber, RecipientInventoryOwnerAttribute);
	EndDo;
	
	For Each Inventory In InventoryKinds Do
		RecipientInventoryOwnerAttribute = TypesOfStocksOfRecipient[Inventory.LineNumber];
		If Not ValueIsFilled(RecipientInventoryOwnerAttribute)
			And Not ValueIsFilled(Inventory.RecipientInventoryOwnerAttribute) Then
			
			Inventory.RecipientInventoryOwnerAttribute = Inventory.InventoryOwnerAttribute;
			
		ElsIf ValueIsFilled(RecipientInventoryOwnerAttribute) Then
			Inventory.RecipientInventoryOwnerAttribute = RecipientInventoryOwnerAttribute;
		EndIf;
	EndDo;
	
EndProcedure

Procedure UploadProducts(Source)
	
	Goods.Clear();
	For Each String In Source Do
		FillPropertyValues(Goods.Add(), String);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
