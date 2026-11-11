#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
//	DocumentTables - See Documents.RetailSalesReport.CollectionOfTabularPartsOfGoods.
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

Procedure OnCopy(CopiedObject)
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	
	InventoryKinds.Clear();
	SetOfSeries.Clear();
	
	DiscountsMarkupsFillingServer.CancelDiscounts(ThisObject, "Goods", False);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount",);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds,PaymentWithPaymentCards,GiftCertificates");
	
	RetailSalesReportLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillInSelectionDocument(FillingData);
		
	Else
		
		CashRegister = Catalogs.CashRegisters.OfflineCashRegisterCashRegisterByDefault();
		If CashRegister <> Undefined Then
			FillInDocumentAtCashRegister(CashRegister);
		EndIf;
		
	EndIf;
	
	InitializeDocument(FillingData);
	
	RetailSalesReportLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure // Processing of the filling()

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	GiftCertificatesServer.FillInAmountInCertificateCurrencyInTablePart(GiftCertificates, Organization, Date, Currency);
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Goods, PriceIncludesVAT);
	
	ClearUnusedImplementationDocuments();
	
	ProductsServer.ClearUnusedSeries(ThisObject,
													ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RetailSalesReport));
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
		FillInCalculationObject();
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
		
		For Each TSRow In GiftCertificates Do
			TSRow.ARAPObject = Undefined;
		EndDo;
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds,PaymentWithPaymentCards,GiftCertificates");
	
	RetailSalesReportLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ChangesTable = VATAccountingERP.NewCalculationChangeTable();
	ChangesRow = ChangesTable.Add();
	ChangesRow.Document = Ref;
	ChangesRow.Period = Date;
	VATAccountingERP.ReflectChangesInSettlementsWithCustomersInVATAccounting(ChangesTable);
	
	RetailSalesReportLocalization.OnWrite(ThisObject, Cancel);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RetailSalesReportLocalization.Posting(ThisObject, Cancel, PostingMode);

EndProcedure

Procedure UndoPosting(Cancel)
	
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes());
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RetailSalesReportLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	DataKey = ThisObject;
	If AdditionalProperties.Property("SoftwareFilling") And AdditionalProperties.SoftwareFilling = True Then
		DataKey = Undefined;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RetailSalesReport),
												Cancel,
												NotCheckedAttributeArray);
	
	If Not ByPhysicalCountResults Then
		ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	Else
		
		NotCheckedAttributeArray.Add("Goods.Count");
		NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
		
		Query = New Query(
		"SELECT
		|	VTProducts_0.Products,
		|	VTProducts_0.LineNumber
		|INTO VTProducts_0
		|FROM
		|	&VTProducts_0 AS VTProducts_0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	VTProducts_0.Products,
		|	VTProducts_0.LineNumber
		|FROM
		|	VTProducts_0 AS VTProducts_0
		|WHERE
		|	VTProducts_0.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)");
		
		Query.SetParameter("VTProducts_0", Goods.Unload(,"Products, LineNumber"));
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		While Selection.Next() Do
		
			ErrorText = StrTemplate(NStr("vi = 'Trong cơ chế điền chứng từ ""Theo kết quả kiểm kê"", trong danh sách ""Hàng hóa"" không được có dịch vụ.
										|Đã tìm thấy dịch vụ trong dòng %1 của danh sách ""Hàng hóa""';
										|ru = 'В режиме заполнения документа ""По результатам инвентаризации"" услуг в списке ""Товары"" быть не должно.
										|Обнаружена услуга в строке %1 списка ""Товары""';
										|en = 'Services are prohibited in the Item list in the ""By physical inventory count results"" document fill mode. 
										|Service is found in line %1 of the Item list'; fa = 'Services are prohibited in the Item list in the ""By physical inventory count results"" document fill mode. 
										|Service is found in line %1 of the Item list';
										|it = 'Nella modalità di compilazione del documento ""Secondo i risultati dell''inventario"" nell''elenco ""Merci"" non ci devono essere i servizi.
										|Un servizio è stato rilevato nella riga %1 dell''elenco ""Merci""';
										|pl = 'W trybie wypełniania dokumentu ""Zgodnie z wynikami inwentaryzacji"" usługi na liście ""Wiersze pozycji"" być nie powinno. 
										|Usługa została wykryta w wierszu %1 listy ""Wiersze pozycji""';
										|tr = '""Envanter sonuçlarına ilişkin"" belgesi doldurulurken ""Ürünler"" listesinde hiçbir hizmet olmamalıdır.
										| ""Ürünler"" listesinin %1 satırında hizmet tespit edildi'"), Selection.LineNumber);
			
			Common.MessageToUser(
				ErrorText,
				DataKey,
				?(DataKey = Undefined, "", CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "Products")),
				,
				Cancel);
		
		EndDo;
		
	EndIf;
		
	If ByPhysicalCountResults Then
		
		KeyAttributes = New Array;
		KeyAttributes.Add("Products");
		KeyAttributes.Add("Characteristic");
		TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "Goods", KeyAttributes, Cancel);
		
	EndIf;

	If Not WarehousesServer.UseWarerooms(Warehouse,Date) Then
		NotCheckedAttributeArray.Add("Goods.Premise");
	EndIf;
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;
	
	For Each LineAccrualOfBonusPoints In BonusPointAccrual Do
		If ValueIsFilled(LineAccrualOfBonusPoints.AccrualDate)
			And ValueIsFilled(LineAccrualOfBonusPoints.DateOfDeduction) Then
			
			If LineAccrualOfBonusPoints.DateOfDeduction < LineAccrualOfBonusPoints.AccrualDate Then
				
				ErrorText = NStr("vi = 'Ngày ghi giảm điểm thưởng ít hơn ngày tích lũy';
								|ru = 'Дата списания бонусных баллов меньше даты начисления';
								|en = 'The write-off date of bonus points is earlier than the date of accrual'; fa = 'The write-off date of bonus points is earlier than the date of accrual';
								|it = 'La data di cancellazione dei punti bonus è inferiore alla data di accreditamento';
								|pl = 'Data naliczenia punktów bonusowych jest mniejsza niż data naliczenia';
								|tr = 'Bonus puanların düşüldüğü tarihin, yatırıldıkları tarihten daha önce olması'");
				LineNumber = LineAccrualOfBonusPoints.LineNumber;
				
				Common.MessageToUser(
					ErrorText,
					DataKey,
					?(DataKey = Undefined, "", CommonClientServer.PathToTabularSection("BonusPointAccrual", LineNumber, "DateOfDeduction")),
					,
					Cancel);
				
			EndIf;
			
		EndIf;
	EndDo;
	
	RetailSales.CheckPaymentCompletionWithPaymentCards(ThisObject, Cancel);

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	RetailSalesReportLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure // Processing of the Fill check()

#EndRegion

#Region Private

#Region InitializationAndFilling

// Initializes the document
//
Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse = SettingsValueCached.GetDefaultRetailWarehouse(Warehouse);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	
	If Not ValueIsFilled(Department) Then
		Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	EndIf;
	
	FillParameters = Documents.RetailSalesReport.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure // Initialize the document()

// Fills in the retail sales report according to the selection.
//
// Parameters:
//  FillingData - Structure with selection values.
//
Procedure FillInSelectionDocument(FillingData)
	
	If FillingData.Property("CashRegister") Then
		
		FillInDocumentAtCashRegister(FillingData.CashRegister);
		
	EndIf;
	
EndProcedure // Fill in the Sampling document()

// Fills in the document for the cash register of the KKM
//
Procedure FillInDocumentAtCashRegister(CashRegister)
	
	CashRegisterDetails = Catalogs.CashRegisters.CashRegisterDetails(CashRegister);
	FillPropertyValues(ThisObject, CashRegisterDetails);
	
EndProcedure // Fill in the Documentpokassekkm()

#EndRegion

#Region InventoryKinds

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
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperation,
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
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON BusinessStructure.Ref = &Department
	|
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	&FieldTextTableOfGoodsQuantityByGBRN_ AS QuantityByGBRN,
	|	TableOfGoods.Partner AS Partner,
	|	TableOfGoods.Seller AS Seller,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Sum AS Sum,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.ManualDiscount AS ManualDiscount,
	|	TableOfGoods.ByCorrectionReceipt AS ByCorrectionReceipt,
	|	TableOfGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
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
	|	&Warehouse AS Warehouse,
	|	TableOfGoods.Partner AS Partner,
	|	TableOfGoods.Seller AS Seller,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Sum + TableOfGoods.VATAmount * &PriceIncludesVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.ManualDiscount AS ManualDiscount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TRUE AS SelectTypesOfStocks,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber,
	|	TableOfGoods.ByCorrectionReceipt AS ByCorrectionReceipt,
	|	TableOfGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	CatalogProducts.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|											VALUE(Enum.ItemsTypes.ReusablePackage))
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
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END AS QuantityByGBRN,
	|	Dimension.StorageLocation AS Warehouse,
	|	TableOfGoods.Partner AS Partner,
	|	TableOfGoods.Seller AS Seller,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Sum + TableOfGoods.VATAmount * &PriceIncludesVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.ManualDiscount AS ManualDiscount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TRUE AS SelectTypesOfStocks,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber,
	|	TableOfGoods.ByCorrectionReceipt AS ByCorrectionReceipt,
	|	TableOfGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatalogProducts
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
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	&Warehouse AS Warehouse,
	|	TableTypesOfStocks_.Partner AS Partner,
	|	TableTypesOfStocks_.Seller AS Seller,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.ManualDiscount AS ManualDiscount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.ByCorrectionReceipt AS ByCorrectionReceipt,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices	
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
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.Partner AS Partner,
	|	TableTypesOfStocks_.Seller AS Seller,
	|	TableTypesOfStocks_.SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.CommissionAmount AS CommissionAmount,
	|	TableTypesOfStocks_.AmountVATRemuneration AS AmountVATRemuneration,
	|	TableTypesOfStocks_.ManualDiscount AS ManualDiscount,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.ByCorrectionReceipt AS ByCorrectionReceipt,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices	
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes
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
	Query.SetParameter("Manager", EmployeeResponsible);
	Query.SetParameter("Department", Department);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("PriceIncludesVAT", ?(PriceIncludesVAT, 0, 1));
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers", GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
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
	|	DocumentDataTable.Department,
	|	DocumentDataTable.Manager,
	|	TableOfGoods.Purpose AS Purpose,
	|
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&VATTaxation AS VATTaxation,
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
	|	TableOfGoods.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|");
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Warehouse, VATTaxation";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate AS VATRate,
	|		TableOfGoods.Partner AS Partner,
	|		TableOfGoods.Seller AS Seller,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.ManualDiscount AS ManualDiscount
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		TableTypesOfStocks_.Partner AS Partner,
	|		TableTypesOfStocks_.Seller AS Seller,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount AS VATAmount,
	|		-TableTypesOfStocks_.ManualDiscount AS ManualDiscount
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.Partner,
	|	TableOfGoods.Seller
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.ManualDiscount) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure FillInAdditionalStockTypes() Export
	
	NamesOfGroupingColumns		= "ItemsLocationAttributes, SetAccountingDimension, DocumentSalesOfGoodsAndServices, ByCorrectionReceipt, Partner, Seller, VATRate";
	NamesOfSummationColumns	= "Count, Sum, VATAmount, ManualDiscount";
	UnloadedColumns			= NamesOfGroupingColumns + ", " + NamesOfSummationColumns;
	
	GoodsTable = Goods.Unload(, UnloadedColumns);
	GoodsTable.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, Partner");
	
	For Each RowOfGoods In GoodsTable Do
		
		GoodsQuantity = RowOfGoods.Count;
		
		AmountIncludingVAT			= ?(PriceIncludesVAT, RowOfGoods.Sum, RowOfGoods.Sum + RowOfGoods.VATAmount);
		VATAmount			= RowOfGoods.VATAmount;
		ManualDiscount	= RowOfGoods.ManualDiscount;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		TheStructureOfTheSearch.Partner = Catalogs.Partners.EmptyRef();
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.SetAccountingDimension = RowOfGoods.SetAccountingDimension;
			NewRow.Partner				= RowOfGoods.Partner;
			NewRow.Seller			= RowOfGoods.Seller;
			NewRow.DocumentSalesOfGoodsAndServices	= RowOfGoods.DocumentSalesOfGoodsAndServices;
			NewRow.ByCorrectionReceipt		= RowOfGoods.ByCorrectionReceipt;
			
			NewRow.Count			= Count;
			NewRow.QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			If Count >= GoodsQuantity Then
				NewRow.AmountIncludingVAT	= AmountIncludingVAT;
				NewRow.VATAmount	= VATAmount;
			ElsIf InventoryLine.Count <> 0 Then
				NewRow.AmountIncludingVAT	= Min(AmountIncludingVAT, Count * InventoryLine.AmountIncludingVAT / InventoryLine.Count);
				NewRow.VATAmount	= Min(VATAmount, Count * InventoryLine.VATAmount / InventoryLine.Count);
			EndIf;
			
			NewRow.ManualDiscount = ?(GoodsQuantity <> 0,
												Count * ManualDiscount / GoodsQuantity,
												0);
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.AmountIncludingVAT			= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount			= InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.ManualDiscount	= InventoryLine.ManualDiscount - NewRow.ManualDiscount;
			
			GoodsQuantity	= GoodsQuantity - NewRow.Count;
			AmountIncludingVAT			= AmountIncludingVAT - NewRow.AmountIncludingVAT;
			VATAmount			= VATAmount - NewRow.VATAmount;
			ManualDiscount	= ManualDiscount - NewRow.ManualDiscount;
			
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
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, VATRate",
							"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount");
		
		FillInAdditionalStockTypes();
		
	EndIf;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.RetailSalesReport.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.RetailSalesReport.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(Undefined, Warehouse, Department, Undefined);
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Purpose = "";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	InformationRegisters.SetAccountingDimension.FillInCollection(GoodsTable);
	
EndProcedure

#EndRegion

#Region Other

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.SelectionOfStockTypes_.VATTaxation = VATTaxation;
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	
	VATAccountingERP.SetParametersForFillingInventoryTypesForCommissionSales(FillParameters);
	
	Return FillParameters;
	
EndFunction

Procedure ClearUnusedImplementationDocuments()
	
	For Each RowGoods In Goods.FindRows(New Structure("ByCorrectionReceipt", False)) Do
		If ValueIsFilled(RowGoods.DocumentSalesOfGoodsAndServices) Then
			RowGoods.DocumentSalesOfGoodsAndServices = Documents.RetailSalesReport.EmptyRef();	
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInCalculationObject()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GiftCertificates.LineNumber AS LineNumber,
	|	CAST(GiftCertificates.GiftCertificate AS Catalog.GiftCertificates) AS GiftCertificate
	|INTO GiftCertificates
	|FROM
	|	&GiftCertificates AS GiftCertificates
	|;
	|/////////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.LineNumber AS LineNumber,
	|	GiftCertificates.GiftCertificate AS GiftCertificate,
	|	ARAPObjects.Ref AS ARAPObject
	|FROM
	|	GiftCertificates AS GiftCertificates
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Object = GiftCertificates.GiftCertificate
	|		AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	GiftCertificates.GiftCertificate.Owner.GiftCardAccounting25
	|";
	Query.SetParameter("GiftCertificates", GiftCertificates.Unload());
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		IndexOf = Selection.LineNumber - 1;
		GiftCertificates[IndexOf].ARAPObject = Selection.ARAPObject;
		GiftCertificates[IndexOf].AmountARAP = GiftCertificates[IndexOf].Sum;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
