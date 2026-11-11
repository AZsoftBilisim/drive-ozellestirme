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
//	DocumentTables - See Documents.RetailReturnsReport.CollectionOfTabularPartsOfGoods.
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
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds,PaymentWithPaymentCards");
	
	RetailReturnsReportLocalization.OnCopy(ThisObject, CopiedObject);

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
	
	RetailReturnsReportLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure // Processing of the filling()

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
		
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Goods, PriceIncludesVAT);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
													ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RetailReturnsReport));
	
	AccountingForTraceableGoodsLocalization.ClearGTDUNumbersOfTraceableWorks(ThisObject);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;

	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds,PaymentWithPaymentCards");
	
	RetailReturnsReportLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

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

	RetailReturnsReportLocalization.OnWrite(ThisObject, Cancel);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RetailReturnsReportLocalization.Posting(ThisObject, Cancel, PostingMode);

EndProcedure

Procedure UndoPosting(Cancel)
	
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes());
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RetailReturnsReportLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	DataKey = ThisObject;
	If AdditionalProperties.Property("SoftwareFilling") And AdditionalProperties.SoftwareFilling = True Then
		DataKey = Undefined;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	CheckedAttributes.Clear();
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RetailReturnsReport),
												Cancel,
												NotCheckedAttributeArray);
	
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	If GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers") Then
		FilterForSearch = New Structure;
		FilterForSearch.Insert("ByCorrectionReceipt", False);
		FilterForSearch.Insert("CostDefiningMethod", Enums.WaysToCalculateReturnCost.FromCurrentDocument);
		LinesToCheck = Goods.FindRows(FilterForSearch);
		If LinesToCheck.Count() Then
			ParametersForCheckingFillingInOfCCDNumbers = InventoriesServer.ParametersForCheckingFillingInOfCCDNumbers();
			ParametersForCheckingFillingInOfCCDNumbers.PresentationOfTS = Metadata().TabularSections[ParametersForCheckingFillingInOfCCDNumbers.TSName].Synonym;
			ObjectForCheck = New Structure;
			ObjectForCheck.Insert("Date", Date);
			ObjectForCheck.Insert("Ref", Ref);
			ObjectForCheck.Insert("Goods", Goods.Unload(LinesToCheck));
			InventoriesServer.CheckFillingOfCCDNumbers(ObjectForCheck, Cancel, ParametersForCheckingFillingInOfCCDNumbers);
		EndIf;
	EndIf;

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
										|en = 'Services are prohibited in the Item list in the ""By physical inventory count results"" document fill mode. Service is found in line %1 of the Item list
										|'; fa = 'Services are prohibited in the Item list in the ""By physical inventory count results"" document fill mode. Service is found in line %1 of the Item list
										|';
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
				
				ErrorText = NStr("vi = 'Ngày ghi giảm điểm thưởng nhỏ hơn ngày tính điểm';
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
	
	RetailReturnsReportLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

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
	
	FillParameters = Documents.RetailReturnsReport.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	If Not ValueIsFilled(Department) Then
		Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	EndIf;
	
EndProcedure // Initialize the document()

// Fills in the retail sales report according to the selection.
//
// Parameters:
//	FillingData - Structure - collection of selection values.
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

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.RetailReturnsReport - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes);
	
EndProcedure

// This function generates temporary document data.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables(SelectionByMethodOfDeterminingCost = "All") Export
	
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
	|	VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer) AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|
	|	CASE WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|		AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|	THEN
	|		&Department
	|	ELSE
	|		VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|
	|	CASE WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|		AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|	THEN
	|		&Manager
	|	ELSE
	|		VALUE(Catalog.Users.EmptyRef)
	|	END AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|
	|	LEFT JOIN
	|		Catalog.BusinessStructure AS BusinessStructure
	|	ON
	|		BusinessStructure.Ref = &Department
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.ProductsInSet AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet AS ItemVariantOfSet,
	|	TableOfGoods.SetAccountingDimension AS SetAccountingDimension,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|	TableOfGoods.ByCorrectionReceipt AS ByCorrectionReceipt,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Sum AS Sum,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.ManualDiscount AS ManualDiscount,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.Partner AS Partner,
	|	TableOfGoods.Seller AS Seller
	|INTO TTProducts_1
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	
	|	TableOfGoods.ProductsInSet AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet AS ItemVariantOfSet,	
	|	TableOfGoods.SetAccountingDimension AS SetAccountingDimension,	
	|	
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN (NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart)
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	
	|	&Warehouse AS Warehouse,
	|	CASE
	|		WHEN TableOfGoods.DocumentSalesOfGoodsAndServices = VALUE(Document.RetailSalesReport.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TableOfGoods.DocumentSalesOfGoodsAndServices
	|	END AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|	TableOfGoods.ByCorrectionReceipt AS ByCorrectionReceipt,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Sum AS Sum,	
	|	TableOfGoods.Sum + (TableOfGoods.VATAmount * &PriceIncludesVAT) AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.ManualDiscount AS ManualDiscount,	
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.Partner AS Partner,
	|	TableOfGoods.Seller AS Seller
	|	
	|INTO TTTableOfGoods
	|FROM
	|	TTProducts_1 AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|
	|WHERE
	|	CatalogProducts.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|												VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND (&NoFilter
	|		OR (TableOfGoods.CostDefiningMethod IN (&CostDefiningMethods)
	|			AND TableOfGoods.ByCorrectionReceipt = &ByCorrectionReceipt))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	
	|	TableOfGoods.ProductsInSet AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet AS ItemVariantOfSet,	
	|	TableOfGoods.SetAccountingDimension AS SetAccountingDimension,	
	|	
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN (NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart)
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	
	|	Dimension.StorageLocation AS Warehouse,
	|	CASE
	|		WHEN TableOfGoods.DocumentSalesOfGoodsAndServices = VALUE(Document.RetailSalesReport.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TableOfGoods.DocumentSalesOfGoodsAndServices
	|	END AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|	TableOfGoods.ByCorrectionReceipt AS ByCorrectionReceipt,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Sum AS Sum,	
	|	TableOfGoods.Sum + (TableOfGoods.VATAmount * &PriceIncludesVAT) AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.ManualDiscount AS ManualDiscount,	
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.Partner AS Partner,
	|	TableOfGoods.Seller AS Seller
	|	
	|FROM
	|	TTProducts_1 AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
	|	AND (&NoFilter
	|		OR (TableOfGoods.CostDefiningMethod IN (&CostDefiningMethods)
	|			AND TableOfGoods.ByCorrectionReceipt = &ByCorrectionReceipt))
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ProductsInSet AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet AS ItemVariantOfSet,	
	|	TableOfGoods.SetAccountingDimension AS SetAccountingDimension,	
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,	
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|	TableOfGoods.ByCorrectionReceipt AS ByCorrectionReceipt,	
	|	TableOfGoods.SalesOpportunity AS SalesOpportunity,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Sum AS Sum,	
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.ManualDiscount AS ManualDiscount,	
	|	TableOfGoods.CommissionAmount AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration AS AmountVATRemuneration,
	|	TRUE AS SelectTypesOfStocks,	
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.Partner AS Partner,
	|	TableOfGoods.Seller AS Seller	
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment AS ItemsLocationAttributesShipment,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.CostDefiningMethod AS CostDefiningMethod,
	|	TableTypesOfStocks_.ByCorrectionReceipt AS ByCorrectionReceipt,	
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
	|	TableTypesOfStocks_.Partner AS Partner,
	|	TableTypesOfStocks_.Seller AS Seller	
	|
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|WHERE
	|	&NoFilter
	|	OR (TableTypesOfStocks_.CostDefiningMethod IN (&CostDefiningMethods)
	|		AND TableTypesOfStocks_.ByCorrectionReceipt = &ByCorrectionReceipt)
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment AS ItemsLocationAttributesShipment,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	UNDEFINED AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	ISNULL(DimensionShipments.StorageLocation, VALUE(Catalog.Warehouses.EmptyRef)) AS OriginWarehouse,
	|	Dimension.StorageLocation AS Warehouse,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.CostDefiningMethod AS CostDefiningMethod,
	|	TableTypesOfStocks_.ByCorrectionReceipt AS ByCorrectionReceipt,	
	|	TableTypesOfStocks_.SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.ManualDiscount AS ManualDiscount,	
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.Partner AS Partner,
	|	TableTypesOfStocks_.Seller AS Seller	
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionShipments
	|		ON TableTypesOfStocks_.ItemsLocationAttributesShipment = DimensionShipments.Ref
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
	
	Query.SetParameter("Manager", EmployeeResponsible);
	Query.SetParameter("Department", Department);
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers", GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("Warehouse", Warehouse);
	
	Query.SetParameter("PriceIncludesVAT", ?(PriceIncludesVAT, 0, 1));
	
	BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer;
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds);
	
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	
	Query.SetParameter("NoFilter", True);
	Query.SetParameter("CostDefiningMethods", Undefined);
	Query.SetParameter("ByCorrectionReceipt", False);

	If SelectionByMethodOfDeterminingCost = "RefundsForSalesDocument" Then
		Query.SetParameter("NoFilter", False);
		Query.SetParameter("CostDefiningMethods", Enums.WaysToCalculateReturnCost.FromSalesDocument);
		Query.SetParameter("ByCorrectionReceipt", False);
	ElsIf SelectionByMethodOfDeterminingCost = "CorrectionForSalesDocument" Then
		Query.SetParameter("NoFilter", False);		
		Query.SetParameter("CostDefiningMethods", Enums.WaysToCalculateReturnCost.FromSalesDocument);
		Query.SetParameter("ByCorrectionReceipt", True);
	ElsIf SelectionByMethodOfDeterminingCost = "RefundsWithoutSalesDocument" Then
		Query.SetParameter("NoFilter", False);		
		CostDefiningMethods = New Array;
		CostDefiningMethods.Add(Enums.WaysToCalculateReturnCost.Manually);
		CostDefiningMethods.Add(Enums.WaysToCalculateReturnCost.FromCurrentDocument);
		CostDefiningMethods.Add(Enums.WaysToCalculateReturnCost.EmptyRef());
		Query.SetParameter("CostDefiningMethods", CostDefiningMethods);
		Query.SetParameter("ByCorrectionReceipt", False);		
	EndIf;
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
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
	|	DocumentDataTable.Purpose AS Purpose,
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
	|		TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|		TableOfGoods.ByCorrectionReceipt AS ByCorrectionReceipt,
	|		TableOfGoods.CCDNumber AS CCDNumber,
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
	|		TableTypesOfStocks_.CostDefiningMethod AS CostDefiningMethod,
	|		TableTypesOfStocks_.ByCorrectionReceipt AS ByCorrectionReceipt,
	|		TableTypesOfStocks_.CCDNumber AS CCDNumber,
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
	|	TableOfGoods.Seller,
	|	TableOfGoods.CostDefiningMethod,
	|	TableOfGoods.ByCorrectionReceipt,
	|	TableOfGoods.CCDNumber
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

Procedure FillInAdditionalStockTypes(PreparedTableOfProducts = Undefined, MappingParameters = Undefined) Export
	
	If PreparedTableOfProducts = Undefined Then
		GoodsTable = Goods.Unload(, "ItemsLocationAttributes, DocumentSalesOfGoodsAndServices, CostDefiningMethod, ByCorrectionReceipt, Partner, Seller, SetAccountingDimension, Count, QuantityByGBRN, Sum, VATRate, VATAmount, ManualDiscount");
	Else
		GoodsTable = PreparedTableOfProducts;
	EndIf;
	
 	GoodsTable.GroupBy("ItemsLocationAttributes, DocumentSalesOfGoodsAndServices, CostDefiningMethod, ByCorrectionReceipt, Partner, Seller, SetAccountingDimension, VATRate",
		"Count, QuantityByGBRN, Sum, VATAmount, ManualDiscount");
	
	If MappingParameters = Undefined Then
		TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	Else	
		TheStructureOfTheSearch = MappingParameters;
	EndIf;
	
	For Each RowOfGoods In GoodsTable Do

		GoodsQuantity = RowOfGoods.Count;
		AmountIncludingVAT = ?(PriceIncludesVAT, RowOfGoods.Sum, RowOfGoods.Sum + RowOfGoods.VATAmount);
		VATAmount = RowOfGoods.VATAmount;
		ManualDiscount = RowOfGoods.ManualDiscount;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do

			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);

			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.SetAccountingDimension = RowOfGoods.SetAccountingDimension;
			
			NewRow.Partner = RowOfGoods.Partner;
			NewRow.Seller = RowOfGoods.Seller;
			NewRow.CostDefiningMethod = RowOfGoods.CostDefiningMethod;
			NewRow.ByCorrectionReceipt = RowOfGoods.ByCorrectionReceipt;
			
			NewRow.Count = Count;
			NewRow.QuantityByGBRN = Count * InventoryLine.QuantityByGBRN
															/ InventoryLine.Count;
			
			If Count >= GoodsQuantity Then
				NewRow.AmountIncludingVAT = AmountIncludingVAT;
				NewRow.VATAmount = VATAmount;
			ElsIf InventoryLine.Count <> 0 Then
				NewRow.AmountIncludingVAT = Min(AmountIncludingVAT, Count * InventoryLine.AmountIncludingVAT / InventoryLine.Count);
				NewRow.VATAmount = Min(VATAmount, Count * InventoryLine.VATAmount / InventoryLine.Count);
			EndIf;
			
			NewRow.ManualDiscount = ?(GoodsQuantity <> 0, Count * ManualDiscount / GoodsQuantity, 0);

			InventoryLine.Count = InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN = InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;			
			InventoryLine.AmountIncludingVAT = InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount = InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.ManualDiscount = InventoryLine.ManualDiscount - NewRow.ManualDiscount;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			AmountIncludingVAT = AmountIncludingVAT - NewRow.AmountIncludingVAT;
			VATAmount = VATAmount - NewRow.VATAmount;
			ManualDiscount = ManualDiscount - NewRow.ManualDiscount;

			If GoodsQuantity = 0 Then
				Break;
			EndIf;

		EndDo;
		
	EndDo;
	
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(New Structure("Count", 0));
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	RefundsForSalesDocuments = Goods.FindRows(New Structure("CostDefiningMethod, ByCorrectionReceipt", Enums.WaysToCalculateReturnCost.FromSalesDocument, False));
	StornoOnSaleDocuments = Goods.FindRows(New Structure("CostDefiningMethod, ByCorrectionReceipt", Enums.WaysToCalculateReturnCost.FromSalesDocument, True));
	
	ThereAreRefundsForSaleDocuments  = RefundsForSalesDocuments.Count() > 0;
	ThereIsStornoOnSaleDocuments  = StornoOnSaleDocuments.Count() > 0;
	ThereAreReturnsWithoutDocuments = (RefundsForSalesDocuments.Count() + StornoOnSaleDocuments.Count()) <> Goods.Count();
	
	If ThereAreRefundsForSaleDocuments Then
		TempTablesManager = TemporaryDocumentDataTables("RefundsForSalesDocument");
		If Not Posted
			Or InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckProductChanges_(TempTablesManager) Then
			
			If ThereAreReturnsWithoutDocuments 
				Or ThereIsStornoOnSaleDocuments Then
				
				TypesOfStocksWithoutSaleDocuments = InventoryKinds.Unload(New Structure("CostDefiningMethod, ByCorrectionReceipt",
																			Enums.WaysToCalculateReturnCost.Manually, False));
				TMCommonUse.AddRowsToTable(TypesOfStocksWithoutSaleDocuments, InventoryKinds.Unload(New Structure("CostDefiningMethod, ByCorrectionReceipt",
																			Enums.WaysToCalculateReturnCost.FromCurrentDocument, False)));																			
				TMCommonUse.AddRowsToTable(TypesOfStocksWithoutSaleDocuments, InventoryKinds.Unload(New Structure("CostDefiningMethod, ByCorrectionReceipt",
				                                                            Enums.WaysToCalculateReturnCost.EmptyRef(), False)));
				
				TypesOfStocksStornoOnDocumentOfSale = InventoryKinds.Unload(New Structure("CostDefiningMethod, ByCorrectionReceipt",
																			Enums.WaysToCalculateReturnCost.FromSalesDocument, True));
				InventoryKinds.Clear();																
			EndIf;
			
			FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
			FillParameters.SelectTypesOfStocksForIntercampany = False;
			FillParameters.ReportFillingErrors = True;
			FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
			Filters = FillParameters.SelectionOfStockTypes_;
			Filters.Organization = Organization;
			Filters.VATTaxation = VATTaxation;
			
			VATAccountingERP.ParametersForFillingTypesOfStocksForTaxation(FillParameters.SelectionOfStockTypes_, Organization, Date, VATTaxation);
			InventoriesServer.ToSupplementSelectionOfInventoryOwnerAttributesByTypeOfInventory(FillParameters.SelectionOfStockTypes_,
																Enums.InventoryTypes.Work_5);
			
			FillParameters.NameOfRemainderTable = "SoldGoods";
			InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject, TempTablesManager, Cancel, FillParameters);
			
			InventoryKinds.GroupBy("ItemsLocationAttributes, ItemsLocationAttributesShipment, DocumentSalesOfGoodsAndServices, InventoryOwnerAttribute, InventoryOwnerAttributeShipment, CCDNumber, VATRate",
								"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount");
			
			PreparedTableOfProducts = TMCommonUse.ShowTemporaryTable(TempTablesManager, "TableOfGoods");
			
			MappingParameters = New Structure("ItemsLocationAttributes,DocumentSalesOfGoodsAndServices");		
			FillInAdditionalStockTypes(PreparedTableOfProducts, MappingParameters);
			
			If ThereAreReturnsWithoutDocuments Then
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStocksWithoutSaleDocuments);
			EndIf;
			If ThereIsStornoOnSaleDocuments Then
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStocksStornoOnDocumentOfSale);
			EndIf;
			
		EndIf;
	EndIf;
		
 	If ThereAreReturnsWithoutDocuments Then
		TempTablesManager = TemporaryDocumentDataTables("RefundsWithoutSalesDocument");
		If Not Posted
			Or InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckProductChanges_(TempTablesManager) Then
			
			If ThereAreRefundsForSaleDocuments
				Or ThereIsStornoOnSaleDocuments Then
				
				TypesOfStocksAccordingToSaleDocuments = InventoryKinds.Unload(New Structure("CostDefiningMethod",
																			Enums.WaysToCalculateReturnCost.FromSalesDocument));
				InventoryKinds.Clear();
			EndIf;
			
			FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
			FillParameters.SelectTypesOfStocksForIntercampany = False;
			FillParameters.ReportFillingErrors = False;
			FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = True;
			Filters = FillParameters.SelectionOfStockTypes_;
			Filters.Organization = Organization;
			Filters.VATTaxation = VATTaxation;
			
			VATAccountingERP.ParametersForFillingTypesOfStocksForTaxation(FillParameters.SelectionOfStockTypes_, Organization, Date, VATTaxation);
			InventoriesServer.ToSupplementSelectionOfInventoryOwnerAttributesByTypeOfInventory(FillParameters.SelectionOfStockTypes_,
																Enums.InventoryTypes.Work_5);
			
			FillParameters.NameOfRemainderTable = "TableTypesOfStocks_";
			InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject, TempTablesManager, Cancel, FillParameters);
						
			InventoryKinds.GroupBy("ItemsLocationAttributes, ItemsLocationAttributesShipment, InventoryOwnerAttribute, InventoryOwnerAttributeShipment, CCDNumber, VATRate",
								"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount");
			
			PreparedTableOfProducts = TMCommonUse.ShowTemporaryTable(TempTablesManager, "TableOfGoods");
			
			FillInAdditionalStockTypes(PreparedTableOfProducts);
			
			If ThereAreRefundsForSaleDocuments
				Or ThereIsStornoOnSaleDocuments Then
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStocksAccordingToSaleDocuments);
			EndIf;
			
		EndIf;	
	EndIf;
	
	If ThereIsStornoOnSaleDocuments Then
		TempTablesManager = TemporaryDocumentDataTables("CorrectionForSalesDocument");
		If Not Posted
			Or InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckProductChanges_(TempTablesManager) Then
			
			If ThereAreReturnsWithoutDocuments 
				Or ThereAreRefundsForSaleDocuments Then
				
				TypesOfInventoryForReturns = InventoryKinds.Unload(New Structure("ByCorrectionReceipt", False));
				
				InventoryKinds.Clear();
			EndIf;
			
			FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
			FillParameters.NameOfRemainderTable = "SoldGoods";
			FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
			FillParameters.WithoutSelectionByCCDNumbers = True;
			FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
			
			InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																	TempTablesManager,
																	Cancel,
																	FillParameters);
																	
			InventoryKinds.GroupBy("ItemsLocationAttributes, ItemsLocationAttributesShipment, DocumentSalesOfGoodsAndServices, InventoryOwnerAttribute, InventoryOwnerAttributeShipment, CCDNumber, VATRate",
								"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount");
			
			PreparedTableOfProducts = TMCommonUse.ShowTemporaryTable(TempTablesManager, "TableOfGoods");
			
			MappingParameters = New Structure("ItemsLocationAttributes,DocumentSalesOfGoodsAndServices");		
			FillInAdditionalStockTypes(PreparedTableOfProducts, MappingParameters);
			
			If ThereAreRefundsForSaleDocuments Or ThereAreReturnsWithoutDocuments Then
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfInventoryForReturns);
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.RetailReturnsReport.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.RetailReturnsReport.CollectionOfTabularPartsOfGoods();
		
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
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	
	Return FillParameters; 
EndFunction

#EndRegion

#EndRegion

#EndIf
