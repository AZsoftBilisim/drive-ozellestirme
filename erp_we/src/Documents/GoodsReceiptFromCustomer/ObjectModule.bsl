#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region SalesTermsAndConditions

// Fills in the sales conditions for the receipt of goods from the client.
//
// Parameters:
//	SalesTermsAndConditions - Structure - data to fill in.
//
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Currency) Then
		Currency = SalesTermsAndConditions.Currency;
	EndIf;
	LineOfBusiness = SalesTermsAndConditions.LineOfBusiness;
	
	If ValueIsFilled(SalesTermsAndConditions.Organization) Then
		Organization = SalesTermsAndConditions.Organization;
	EndIf;
	
	If SalesTermsAndConditions.Standard_ <> Undefined And Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.Counterparty) Then
			Counterparty = SalesTermsAndConditions.Counterparty;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	Contract = Documents.GoodsReceiptFromCustomer.GetDefaultContract(ThisObject);
	ContractDetails_ = New Structure("Currency, LineOfBusiness, Department", "ARAPCurrency");
	Catalogs.CounterpartyContracts.FillInDocumentDetails(ThisObject, Contract, ContractDetails_);
	
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Warehouse) Then
		Warehouse = SalesTermsAndConditions.Warehouse;
	EndIf;
	
EndProcedure

// Fills in the default sales conditions in the receipt of goods from the customer.
//
Procedure FillInDefaultSalesConditions() Export
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	If ValueIsFilled(Partner)
		Or Not ToUseTermsOfSales Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.GoodsReceiptFromCustomer.EmptyRef());
		FilterParameters.Insert("ConsiderWarehouseGroups", True);
		FilterParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
		FilterParameters.Insert("BusinessTransactions",
			Documents.GoodsReceiptFromCustomer.ContractBusinessTransaction());
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
										Partner, FilterParameters);
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales
				Or (Terms <> DefaultSalesTerms.Terms
					And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				
				If ToUseTermsOfSales Then
					FillInPricesBySalesConditions();
				EndIf;
				
			Else
				Terms = DefaultSalesTerms.Terms;
				
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			EndIf;
			
		Else
			Terms = Undefined;
			
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the terms of sale under the agreement in receipt of goods from the client.
//
// Parameters:
//	RecalculatePrices_ - Boolean - To recalculate prices under the agreement.
//
Procedure FillInTermsOfSalesUnderAgreement(RecalculatePrices_ = True) Export
	
	If Not ValueIsFilled(Terms) Then
		Return;
	EndIf;
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
	
	FillIn_TermsOfSales(SalesTermsAndConditions);
	If RecalculatePrices_ = True Then
		FillInPricesBySalesConditions();
	EndIf;
	
EndProcedure

#EndRegion

// Generates temporary tables with document data.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	QueryText = 
	"SELECT
	|	&Date        AS Date,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	TableOfGoods.LineNumber         AS LineNumber,
	|	TableOfGoods.Products        AS Products,
	|	TableOfGoods.ItemsLocationAttributes AS BasicAnalytics,
	|	TableOfGoods.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic      AS Characteristic,
	|	TableOfGoods.Purpose          AS Purpose,
	|	TableOfGoods.ProductsRecordingAsReceived   AS ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	TableOfGoods.Series               AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Count          AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	&Contract                           AS Warehouse,
	|	TableOfGoods.CCDNumber            AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	TableOfGoods.LineNumber            AS LineNumber,
	|	TableOfGoods.Products           AS Products,
	|	TableOfGoods.BasicAnalytics      AS BasicAnalytics,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic         AS Characteristic,
	|	TableOfGoods.Purpose             AS Purpose,
	|	TableOfGoods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	TableOfGoods.Series                  AS Series,
	|	TableOfGoods.BatchesIndicationStatus	  AS BatchesIndicationStatus,
	|	TableOfGoods.Count             AS Count,
	|	TableOfGoods.QuantityByGBRN       AS QuantityByGBRN,
	|	TableOfGoods.Warehouse                  AS Warehouse,
	|	TableOfGoods.CCDNumber               AS CCDNumber,
	|	TRUE                                AS SelectTypesOfStocks
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS BasicAnalytics,
	|	TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ProductsRecordingAsReceived AS ProductsRecordingAsReceived, 
	|	TableTypesOfStocks_.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	TableTypesOfStocks_.InventoryOwnerAttribute  AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count  AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END                          AS QuantityByGBRN,
	|	TableTypesOfStocks_.CCDNumber    AS CCDNumber
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|///////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	TableTypesOfStocks_.LineNumber       AS LineNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttribute        AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.BasicAnalytics AS BasicAnalytics,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products               AS Products,
	|	Dimension.Characteristic             AS Characteristic,
	|	TableTypesOfStocks_.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	TableTypesOfStocks_.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	TableTypesOfStocks_.Count        AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN  AS QuantityByGBRN,
	|	TableTypesOfStocks_.CCDNumber          AS CCDNumber,
	|	&InventoryOwnerAttributesAreSpecifiedManually           AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("TableOfGoods",        Goods);
	Query.SetParameter("TableTypesOfStocks_",    InventoryKinds);
	Query.SetParameter("Ref",                Ref);
	Query.SetParameter("Date",                  Date);
	Query.SetParameter("Partner",               Partner);
	Query.SetParameter("Counterparty",            Counterparty);
	Query.SetParameter("Contract",               Contract);
	Query.SetParameter("Organization",           Organization);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("Warehouse",                 Warehouse);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return Query.TempTablesManager;
	
EndFunction

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.GoodsReceiptFromCustomer - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode) Export
	
	FillParameters = ParametersForFillingInventoryTypes();
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillParameters.DocumentMakesBothArrivalAndExpenditure = False;
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	EndIf;
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.GoodsReceiptFromCustomer.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	FillStockTypes(Cancel);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NotCheckedAttributeArray.Add("Goods.ProductsRecordingAsReceived");
	
	QuantityVerificationParameters = Documents.GoodsReceiptFromCustomer.TSParametersForRounding(Warehouse);
	
	ProductsServer.CheckQuantityFilling(
		ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters["Goods"]);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsReceiptFromCustomer);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.FieldNamesWithSuffix.Insert("Products", "ProductsRecordingAsReceived");
	CheckParameters.FieldNamesWithSuffix.Insert("Characteristic", "CharacteristicRecordingAsReceived");
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		CheckParameters);

	ProductsServer.CheckTypeOfProductDescription(ThisObject,Cancel);

	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date);
	
	If (GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers")
			Or ThisIsTraceableDocument) Then
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel);
	EndIf;
	
	For Each TSRow In Goods Do
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'в строке %LineNumber% списка ""Товары""';
									|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'w wierszu %LineNumber% listy ""Towary""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress =  StrReplace(ErrorAddress, "%LineNumber%", TSRow.LineNumber);
		
		ProductDescriptionField = CommonClientServer.PathToTabularSection(
			"Goods",
			TSRow.LineNumber,
			"ProductsRecordingAsReceived");
		
		If TSRow.Damage Then
			
			If Not ValueIsFilled(TSRow.ProductsRecordingAsReceived) Then
			
				ErrorText = NStr("vi = 'Cột ""mặt hàng (đăng)"" không được điền';
								|ru = 'Не заполнена колонка ""Номенклатура (оприходование)""';
								|en = 'Column ""Items (recording as received)"" is not filled in'; fa = 'Column ""Items (recording as received)"" is not filled in';
								|it = 'La colonna ""Articolo (registrazione in contabilità)"" non è compilata';
								|pl = 'Nie wypełniono kolumny ""Номенклатура (оприходование)""';
								|tr = '""Öğe (Envanter)"" sütunu eksik'");
				Common.MessageToUser(ErrorText + ErrorAddress,
															ThisObject,
															ProductDescriptionField,
															,
															Cancel);
			
			ElsIf TSRow.Products = TSRow.ProductsRecordingAsReceived Then
			
				ErrorText = NStr("vi = 'Hàng hóa có chất lượng ban đầu trùng với hàng hóa có chất lượng khác';
								|ru = 'Товар исходного качества совпадает с товаром другого качества';
								|en = 'Goods of original quality matches with goods of different quality'; fa = 'Goods of original quality matches with goods of different quality';
								|it = 'Il prodotto della qualità originale coincide con il prodotto di una qualità diversa';
								|pl = 'Towar oryginalnej jakości zbiega się z towarem innej jakości';
								|tr = 'Orijinal kalitedeki ürün uygun kalitede olmayan ürünle eşleşmektedir'");
				Common.MessageToUser(ErrorText + ErrorAddress,
															ThisObject,
															ProductDescriptionField,
															,
															Cancel);
			
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(ReferenceOrder)
			And Not ValueIsFilled(TSRow.ReferenceOrder) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Lệnh"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'Не заполнено поле ""Распоряжение"" в строке %LineNumber% списка ""Товары""';
							|en = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list'; fa = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list';
							|it = 'Campo ""Disposizione"" non compilato nella riga %LineNumber% dell''elenco ""Articoli""';
							|pl = 'Pole ""Zamówienie"" w wierszu %LineNumber% listy ""Towary""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Emir"" alanı doldurulmamış'");
			ErrorText =  StrReplace(ErrorText, "%LineNumber%", TSRow.LineNumber);
			ErrorField  = CommonClientServer.PathToTabularSection("Goods",
																			TSRow.LineNumber,
																			"ReferenceOrder");
			
			Common.MessageToUser(ErrorText, ThisObject, ErrorField, Undefined, Cancel);
			
		EndIf;
		
	EndDo;
	
	QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Wiersze pozycji';
			|tr = 'Ürünler'"),
		"DateOfReceipt");
	
	QualityControl.ProcessingVerificationOfCorrectnessOfConnectionWithBatches(
		ThisObject,
		SeriesSpecificationParameters.LinkFields,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Wiersze pozycji';
			|tr = 'Ürünler'"),
		Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		
		Cancel = True;
		
	EndIf;
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	
	GoodsReceiptFromCustomerLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	FilledInBasedOnDocument = False;
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("DiscrepancyCertificate") Then
			FillInDocumentBasedOnDiscrepancyReport(FillingData);
			FilledInBasedOnDocument = True;
		
		ElsIf FillingData.Property("DocumentBasis") Then
			
			DocBasis = FillingData.DocumentBasis;
			ArrayOfBases = Undefined;
			If ValueIsFilled(DocBasis) Then
				If TypeOf(DocBasis) = Type("Array") Then
					ArrayOfBases = DocBasis;
				Else
					ArrayOfBases = CommonClientServer.ValueInArray(DocBasis);
				EndIf;
			EndIf;
			
			If ValueIsFilled(ArrayOfBases) Then
				FillInDocumentOnOrders(ArrayOfBases);
				FilledInBasedOnDocument = True;
			EndIf;
		EndIf;
	
	ElsIf FillInDataType = Type("Array") And FillingData.Count() > 0 Then

		FillInDocumentOnOrders(FillingData);
	
	ElsIf FillInDataType = Type("DocumentRef.GoodsReceiptFromCustomer") Then

		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		FilledInBasedOnDocument = True;

	EndIf;
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	If Not ToUseTermsOfSales
		And Not FilledInBasedOnDocument Then
		FillInDefaultSalesConditions();
	EndIf;
	
	InitializeDocument(FillingData);
	
	CalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
						ThisObject,
						"Contract");
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(CalculationParameters, Goods);
	
	GoodsReceiptFromCustomerLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueIsFilled(ReferenceOrder) Then
		For Each CurRow In Goods Do
			If Not ValueIsFilled(CurRow.ReferenceOrder) Then
				CurRow.ReferenceOrder = ReferenceOrder;
			EndIf;
		EndDo;
	EndIf;
	
	If ValueIsFilled(Warehouse) Then
		
		WarehouseGroup_ = Common.ObjectAttributeValue(Warehouse, "IsFolder");
		
		If Not WarehouseGroup_ Then
			For Each CurRow In Goods Do
				If Not ValueIsFilled(CurRow.Warehouse) Then
					CurRow.Warehouse = Warehouse;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	RoundingParameters = Documents.GoodsReceiptFromCustomer.TSParametersForRounding(Warehouse);
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode,
		RoundingParameters["Goods"]);
	
	DocumentAmount         = GetDocumentAmount();
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject,
		Documents.GoodsReceiptFromCustomer);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	ReceiptAgainstOrder = False;
	
	For Each RowOfGoods In Goods Do
		If TypeOf(RowOfGoods) <> Type("DocumentRef.SaleAdjustment") Then
			ReceiptAgainstOrder = True;
			
			Break;
		EndIf;
	EndDo;
	
	If Not ReceiptAgainstOrder
		And ReduceShipmentByReference Then
		
		ReduceShipmentByReference = False;
		
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	KeyAttributes = QualityControl.DetailsOfDeterminingNeedForLotReferenceInDocument(Warehouse, BusinessOperation);
	QualityControl.FillInControlledLotReferenceBeforeWritingDocument(ThisObject, KeyAttributes);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	GoodsReceiptFromCustomerLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateUpdateControlledLotReferenceWhenWritingDocument(ThisObject);
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	Documents.GoodsReceiptFromCustomer.AddAdditionalPropertyToControlWhenConducting(ThisObject);
	
	GoodsReceiptFromCustomerLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.Posting);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsReceiptFromCustomerLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.UndoPosting);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsReceiptFromCustomerLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	DocumentBasis = Undefined;
	ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	
	For Each CurRow In Goods Do
		CurRow.RowID = "";
	EndDo;
	
	SetOfSeries.Clear();
	InventoryKinds.Clear();
	
	InitializeDocument();
	
	CalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
						ThisObject,
						"Contract");
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(CalculationParameters, Goods);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	GoodsReceiptFromCustomerLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocumentBeforeFillingItOut()
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Author         = Users.CurrentUser();
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	Department = SettingsValueCached.UserDivision(Manager, Department);
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, Goods, False);
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Procedure FillInDocumentOnOrders(ReferenceArray)
	
	OrderToFillIn = ReferenceArray[0];
	
	OrderOperation = Undefined;
	If TypeOf(OrderToFillIn) = Type("DocumentRef.SaleAdjustment") Then
		
		BasisOfAdjustment =
			Common.ObjectAttributeValue(OrderToFillIn, "DocumentBasis");
		
		BusinessTransactionGroundsForAdjustment =
			Documents.SaleAdjustment.EconomicOperationOfFoundationDocument(BasisOfAdjustment);
		
		If ConsignmentSalesServer.SalesViaCommissionAgent(BusinessTransactionGroundsForAdjustment) Then
			OrderOperation = BusinessTransactionGroundsForAdjustment;
		EndIf;
		
	EndIf;
	
	If OrderOperation = Undefined Then 
		OrderOperation =
			Common.ObjectAttributeValue(OrderToFillIn, "BusinessOperation");
	EndIf;
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOnOperation(OrderToFillIn,
									Metadata().Name,
									OrderOperation);
	
	HeaderAttributes = New Structure();
	SalesServerCall.GenerateImplementationFillInData(ReferenceArray, Metadata().Name, HeaderAttributes);
	
	FillPropertyValues(ThisObject, HeaderAttributes);
	Currency = HeaderAttributes.ARAPCurrency;
	BusinessOperation = Enums.BusinessTransactions.GoodsReceiptFromCustomer;
	
	QueryText =
	"SELECT DISTINCT
	|	CASE
	|		WHEN GoodsTable.SalesOrder REFS Document.SalesOrder
	|				AND CAST(GoodsTable.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|				AND GoodsTable.Ref.Patch
	|			THEN GoodsTable.Ref.CorrectedDocument
	|		WHEN GoodsTable.SalesOrder REFS Document.SalesOrder
	|				AND CAST(GoodsTable.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|			THEN GoodsTable.Ref
	|		WHEN GoodsTable.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|				AND CAST(GoodsTable.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|				AND GoodsTable.Ref.Patch
	|			THEN GoodsTable.Ref.CorrectedDocument
	|		WHEN GoodsTable.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|				AND CAST(GoodsTable.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|			THEN GoodsTable.Ref
	|		ELSE
	|			GoodsTable.SalesOrder
	|	END AS ReferenceOrder
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&ReferenceArray)
	|	AND GoodsTable.Ref.ShipmentByOrders
	|	AND NOT GoodsTable.SalesOrder IN(
	|	                  VALUE(Document.SalesOrder.EmptyRef),
	|	                  VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                  VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                  UNDEFINED
	|	                  )
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CASE
	|		WHEN GoodsTable.Ref.Patch
	|			THEN GoodsTable.Ref.CorrectedDocument
	|		ELSE
	|			GoodsTable.Ref
	|	END AS ReferenceOrder
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&ReferenceArray)
	|	AND NOT GoodsTable.Ref.ShipmentByOrders
	|	AND GoodsTable.SalesOrder IN(
	|	                  VALUE(Document.SalesOrder.EmptyRef),
	|	                  VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                  VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                  UNDEFINED
	|	                  )
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS ReferenceOrder
	|FROM
	|	Document.SalesOrder AS Table
	|WHERE
	|	Table.Ref IN (&ReferenceArray)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS ReferenceOrder
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS Table
	|WHERE
	|	Table.Ref IN (&ReferenceArray)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS ReferenceOrder
	|FROM
	|	Document.SourceDocument AS Table
	|WHERE
	|	Table.Ref IN (&ReferenceArray)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS ReferenceOrder
	|FROM
	|	Document.SaleAdjustment AS Table
	|WHERE
	|	Table.Ref IN (&ReferenceArray)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("ReferenceArray", ReferenceArray);
	
	References = Query.Execute().Unload().UnloadColumn("ReferenceOrder");
	
	InvoiceManager = Documents.GoodsReceiptFromCustomer;
	
	DocumentFillingParameters = InvoiceManager.DocumentFillingParameters();
	InvoiceManager.InitializeFillingParameters(DocumentFillingParameters,
		HeaderAttributes, References);
	
	InvoiceTable = InvoiceManager.TableDataAndDocument(Ref);
	
	InvoiceManager.FillInByOrdersOrders(InvoiceTable,
		Undefined, DocumentFillingParameters);
	
	TableColumn2 = InvoiceTable.Columns.Count; // ValueTableColumn
	TableColumn2.Name = "QuantityBeforeChange_";
	
	TableColumn2 = InvoiceTable.Columns.QuantityInOrder; // ValueTableColumn
	TableColumn2.Name = "Count";

	Goods.Load(InvoiceTable);

	Actions = New Structure("RecalculateNumberOfPackages");
	BatchProcessingOfTablePartServer.TreatTS(Goods, Actions);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, InvoiceManager);
		
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters, False);
	
EndProcedure

Procedure FillInDocumentBasedOnDiscrepancyReport(FillingData)

	DiscrepancyCertificate = FillingData.DiscrepancyCertificate;
	BaseDocumentForDiscrepancyReport = FillingData.BasisOfAct;
	ReduceShipmentByReference = FillingData.ReduceShipmentByReference;
	
	FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer();
	
	QueryText =
	"SELECT ALLOWED DISTINCT
	|	MAX(Table.Ref) AS DocumentShipments,
	|	MAX(Table.Ref.Warehouse) AS WarehouseInHeader,
	|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
	|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
	|	SalesOfGoodsServicesGoods.Products AS Products,
	|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose AS Purpose
	|INTO ShipmentDocumentsInAdvance
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS Table
	|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|		ON Table.Products = SalesOfGoodsServicesGoods.Products
	|			AND Table.Characteristic = SalesOfGoodsServicesGoods.Characteristic
	|			AND Table.RowCode = SalesOfGoodsServicesGoods.RowCode
	|			AND Table.Ref = SalesOfGoodsServicesGoods.SalesOrder
	|WHERE
	|	Table.Ref.Posted
	|	AND SalesOfGoodsServicesGoods.Ref = &BaseDocumentForDiscrepancyReport
	|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
	|	AND SalesOfGoodsServicesGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|
	|GROUP BY
	|	SalesOfGoodsServicesGoods.SalesOrder,
	|	SalesOfGoodsServicesGoods.RowCode,
	|	SalesOfGoodsServicesGoods.Products,
	|	SalesOfGoodsServicesGoods.Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(Table.Ref) AS DocumentShipments,
	|	MAX(Table.Ref.Warehouse) AS WarehouseInHeader,
	|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
	|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
	|	SalesOfGoodsServicesGoods.Products AS Products,
	|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose AS Purpose
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS Table
	|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|		ON Table.Products = SalesOfGoodsServicesGoods.Products
	|			AND Table.Characteristic = SalesOfGoodsServicesGoods.Characteristic
	|			AND Table.RowCode = SalesOfGoodsServicesGoods.RowCode
	|			AND Table.Ref.CorrectedDocument = SalesOfGoodsServicesGoods.SalesOrder
	|WHERE
	|	Table.Ref.Posted
	|	AND SalesOfGoodsServicesGoods.Ref = &BaseDocumentForDiscrepancyReport
	|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
	|	AND SalesOfGoodsServicesGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|
	|GROUP BY
	|	SalesOfGoodsServicesGoods.SalesOrder,
	|	SalesOfGoodsServicesGoods.RowCode,
	|	SalesOfGoodsServicesGoods.Products,
	|	SalesOfGoodsServicesGoods.Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(Table.Ref) AS DocumentShipments,
	|	MAX(Table.Ref.Warehouse) AS WarehouseInHeader,
	|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
	|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
	|	SalesOfGoodsServicesGoods.Products AS Products,
	|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose AS Purpose
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS Table
	|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|		ON Table.Products = SalesOfGoodsServicesGoods.Products
	|			AND Table.Characteristic = SalesOfGoodsServicesGoods.Characteristic
	|			AND Table.RowCode = SalesOfGoodsServicesGoods.RowCode
	|			AND Table.SalesOrder = SalesOfGoodsServicesGoods.SalesOrder
	|WHERE
	|	Table.Ref.Posted
	|	AND SalesOfGoodsServicesGoods.Ref = &BaseDocumentForDiscrepancyReport
	|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
	|	AND SalesOfGoodsServicesGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|
	|GROUP BY
	|	SalesOfGoodsServicesGoods.SalesOrder,
	|	SalesOfGoodsServicesGoods.RowCode,
	|	SalesOfGoodsServicesGoods.Products,
	|	SalesOfGoodsServicesGoods.Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(Table.Ref) AS DocumentShipments,
	|	MAX(Table.Ref.Warehouse) AS WarehouseInHeader,
	|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
	|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
	|	SalesOfGoodsServicesGoods.Products AS Products,
	|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose AS Purpose
	|FROM
	|	Document.OBEntryGoods AS Table
	|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|		ON Table.Lot = SalesOfGoodsServicesGoods.SalesOrder
	|WHERE
	|	Table.Posted
	|	AND SalesOfGoodsServicesGoods.Ref = &BaseDocumentForDiscrepancyReport
	|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
	|	AND SalesOfGoodsServicesGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|
	|GROUP BY
	|	SalesOfGoodsServicesGoods.SalesOrder,
	|	SalesOfGoodsServicesGoods.RowCode,
	|	SalesOfGoodsServicesGoods.Products,
	|	SalesOfGoodsServicesGoods.Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ShipmentDocumentsInAdvance.DocumentShipments AS DocumentShipments,
	|	ShipmentDocumentsInAdvance.WarehouseInHeader AS WarehouseInHeader,
	|	ShipmentDocumentsInAdvance.SalesOrder AS SalesOrder,
	|	ShipmentDocumentsInAdvance.RowCode AS RowCode,
	|	ShipmentDocumentsInAdvance.Products AS Products,
	|	ShipmentDocumentsInAdvance.Characteristic AS Characteristic,
	|	ShipmentDocumentsInAdvance.Purpose AS Purpose
	|INTO ShippingDocuments
	|FROM
	|	ShipmentDocumentsInAdvance AS ShipmentDocumentsInAdvance
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON ShipmentDocumentsInAdvance.DocumentShipments = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	DocumentsRegistry.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Partner                 AS Partner,
	|	Table.Counterparty              AS Counterparty,
	|	Table.Terms              AS Terms,
	|	VALUE(Enum.BusinessTransactions.GoodsReceiptFromCustomer) AS BusinessOperation,
	|	Table.Organization             AS Organization,
	|	Table.Contract                 AS Contract,
	|	Table.Warehouse                   AS Warehouse,
	|	Table.Currency                  AS Currency,
	|	Table.SalesOpportunity                  AS SalesOpportunity,
	|	Table.Department           AS Department,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|	TRUE                          AS ByReferences,
	|	Table.Ref                  AS BaseDocumentForDiscrepancyReport
	|FROM
	|	Document.GoodsShipmentToCustomer AS Table
	|WHERE
	|	Table.Ref = &BaseDocumentForDiscrepancyReport
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Partner                 AS Partner,
	|	Table.Counterparty              AS Counterparty,
	|	Table.Terms              AS Terms,
	|	VALUE(Enum.BusinessTransactions.GoodsReceiptFromCustomer) AS BusinessOperation,
	|	Table.Organization             AS Organization,
	|	Table.Contract                 AS Contract,
	|	Table.Warehouse                   AS Warehouse,
	|	Table.Currency                  AS Currency,
	|	Table.SalesOpportunity                  AS SalesOpportunity,
	|	Table.Department           AS Department,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|	TRUE                          AS ByReferences,
	|	Table.Ref                  AS BaseDocumentForDiscrepancyReport
	|FROM
	|	Document.CustomerInvoice AS Table
	|WHERE
	|	Table.Ref = &BaseDocumentForDiscrepancyReport
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ActOfDiscrepancies.Products       AS Products,
	|	ActOfDiscrepancies.Characteristic     AS Characteristic,
	|	ActOfDiscrepancies.RowCode          AS RowCode,
	|	ActOfDiscrepancies.Warehouse              AS Warehouse,
	|	ActOfDiscrepancies.Purpose         AS Purpose,
	|	CASE
	|		WHEN ActOfDiscrepancies.Action IN (
	|					VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|					VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|					)
	|			THEN ActOfDiscrepancies.CountByDocument - ActOfDiscrepancies.Count
	|		ELSE
	|			ActOfDiscrepancies.Count - ActOfDiscrepancies.CountByDocument
	|	END                                     AS Count,
	|	ActOfDiscrepancies.NumberOfPackages AS NumberOfPackages,
	|	ActOfDiscrepancies.Price               AS Price,
	|	CASE
	|		WHEN ShipmentDocumentsByOrder.WarehouseInHeader IS NOT NULL
	|			THEN ShipmentDocumentsByOrder.WarehouseInHeader
	|		WHEN ShipmentDocumentsForImplementation.WarehouseInHeader IS NOT NULL
	|			THEN ShipmentDocumentsForImplementation.WarehouseInHeader
	|		ELSE
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|	END                                     AS WarehouseInHeader,
	|	ActOfDiscrepancies.Series              AS Series,
	|	CASE
	|		WHEN ActOfDiscrepancies.SalesOrder IN (
	|				VALUE(Document.SalesOrder.EmptyRef),
	|				VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|				VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|				UNDEFINED
	|				)
	|			THEN ActOfDiscrepancies.SaleOfGoodsAndServices
	|		ELSE
	|			ActOfDiscrepancies.SalesOrder
	|	END                                     AS ReferenceOrder,
	|	ActOfDiscrepancies.Package           AS Package,
	|	&ReduceShipmentByReference          AS ReduceShipmentByReference
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS ActOfDiscrepancies
	|	LEFT JOIN ShippingDocuments AS ShipmentDocumentsByOrder
	|		ON ActOfDiscrepancies.RowCode = ShipmentDocumentsByOrder.RowCode
	|			AND ActOfDiscrepancies.Products = ShipmentDocumentsByOrder.Products
	|			AND ActOfDiscrepancies.Characteristic = ShipmentDocumentsByOrder.Characteristic
	|			AND ActOfDiscrepancies.Purpose = ShipmentDocumentsByOrder.Purpose
	|			AND ActOfDiscrepancies.SalesOrder = ShipmentDocumentsByOrder.SalesOrder
	|	LEFT JOIN ShippingDocuments AS ShipmentDocumentsForImplementation
	|		ON ActOfDiscrepancies.RowCode = ShipmentDocumentsForImplementation.RowCode
	|			AND ActOfDiscrepancies.Products = ShipmentDocumentsForImplementation.Products
	|			AND ActOfDiscrepancies.Characteristic = ShipmentDocumentsForImplementation.Characteristic
	|			AND ActOfDiscrepancies.Purpose = ShipmentDocumentsForImplementation.Purpose
	|			AND ActOfDiscrepancies.SaleOfGoodsAndServices = ShipmentDocumentsForImplementation.SalesOrder
	|WHERE
	|	ActOfDiscrepancies.Ref = &DiscrepancyCertificate
	|	AND ActOfDiscrepancies.SaleOfGoodsAndServices = &BaseDocumentForDiscrepancyReport
	|	AND CASE
	|		WHEN ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.CustomerInvoice
	|			AND &ReduceShipmentByReference
	|			AND ActOfDiscrepancies.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_)
	|			THEN ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|					AND (ActOfDiscrepancies.SalesOrder REFS Document.SalesOrder
	|						OR ActOfDiscrepancies.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer)
	|		WHEN ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.CustomerInvoice
	|			AND NOT &ReduceShipmentByReference
	|			AND ActOfDiscrepancies.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_)
	|			THEN ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)
	|				OR ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|					AND NOT ActOfDiscrepancies.SalesOrder REFS Document.SalesOrder
	|					AND NOT ActOfDiscrepancies.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|		WHEN ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.GoodsShipmentToCustomer
	|			AND &ReduceShipmentByReference
	|			AND ActOfDiscrepancies.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_)
	|			THEN ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|					AND (ActOfDiscrepancies.SalesOrder REFS Document.SalesOrder
	|						OR ActOfDiscrepancies.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer)
	|		WHEN ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.GoodsShipmentToCustomer
	|			AND NOT &ReduceShipmentByReference
	|			AND (ActOfDiscrepancies.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_)
	|				OR ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered))
	|			THEN ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)
	|				OR ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|				OR ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|					AND NOT ActOfDiscrepancies.SalesOrder REFS Document.SalesOrder
	|					AND NOT ActOfDiscrepancies.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|	END
	|";

	Query = New Query(QueryText);
	Query.SetParameter("DiscrepancyCertificate", DiscrepancyCertificate);
	Query.SetParameter("BaseDocumentForDiscrepancyReport", BaseDocumentForDiscrepancyReport);
	Query.SetParameter("ItemsTypes", FilterByProductType);
	Query.SetParameter("ReduceShipmentByReference", ReduceShipmentByReference);
	
	QueryResults = Query.ExecuteBatch();
	
	HeaderSelection = QueryResults[QueryResults.UBound()-1].Select();
	GoodsTable = QueryResults[QueryResults.UBound()].Unload();
	
	// Fill in the header
	HeaderSelection.Next();
	FillPropertyValues(ThisObject, HeaderSelection);
	
	If GoodsTable.Count() > 0 And ValueIsFilled(GoodsTable[0].WarehouseInHeader) Then
		Warehouse = GoodsTable[0].WarehouseInHeader;
	EndIf;
	
	// Fill in the tabular part of Goods
	Goods.Load(GoodsTable);
	Documents.GoodsReceiptFromCustomer.UpdateDependentDetailsOfTablePart(Goods, New Structure);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject,
		Documents.GoodsReceiptFromCustomer);
		
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters, False);

EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager = TemporaryDocumentDataTables();
	
	If Not Posted
		Or InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber",
							"Count, NumberOfPackages, QuantityByGBRN");
		
		If Not Cancel Then
			FillInAdditionalStockTypeColumns();
			FillInInventoryTypeProductList();
		EndIf;
		
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Date, Organization, BusinessOperation, Partner, Contract";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.ProductsRecordingAsReceived	AS ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived	AS CharacteristicRecordingAsReceived
	|FROM
	|	(SELECT
	|		TableOfGoods.BasicAnalytics	AS ItemsLocationAttributes,
	|		TableOfGoods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|		TableOfGoods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|		TableOfGoods.Count			AS Count,
	|		TableOfGoods.QuantityByGBRN		AS QuantityByGBRN,
	|		TableOfGoods.CCDNumber				AS CCDNumber
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.BasicAnalytics	AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|		TableTypesOfStocks_.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|		-TableTypesOfStocks_.Count			AS Count,
	|		-TableTypesOfStocks_.QuantityByGBRN	AS QuantityByGBRN,
	|		TableTypesOfStocks_.CCDNumber				AS CCDNumber
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.QuantityByGBRN) <> 0";
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return Not Result_Query.IsEmpty();
	
EndFunction

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.ReversedDocument = ReversedDocument;
	FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
	
	FillParameters.SelectionOfStockTypes_.Organization = Organization;
	If GetFunctionalOption("UseExcisableGoods") Then
		FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear()
	EndIf;
	Return FillParameters;
	
EndFunction

Procedure FillInAdditionalStockTypeColumns()
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In Goods Do
		
		GoodsQuantity = RowOfGoods.Count;
		
		TheStructureOfTheSearch.ItemsLocationAttributes = RowOfGoods.ItemsLocationAttributesGoodsAtPartners;
		
		FoundRows = InventoryKinds.FindRows(TheStructureOfTheSearch);
		
		For Each InventoryLine In FoundRows Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			FillableProperties = "ItemsLocationAttributes, ItemsLocationAttributesGoodsAtPartners";
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			FillPropertyValues(NewRow, RowOfGoods, FillableProperties);
			
			NewRow.Count = Count;
			NewRow.QuantityByGBRN = Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	FilterParameters = New Structure("Count", 0);
	LinesToDelete = InventoryKinds.FindRows(FilterParameters);
	
	For Each TableRow In LinesToDelete Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure FillInInventoryTypeProductList()
	
	If ReturnOfSpoiledGoods Then
		
		RowFilter	= New Structure("Damage", True);
		LinesOfSpoilage	= Goods.FindRows(RowFilter);
		
		TheStructureOfTheSearch	= New Structure("ItemsLocationAttributes");
		
		For Each RowOfGoods In LinesOfSpoilage Do
			
			GoodsQuantity = RowOfGoods.Count;
			
			FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
			
			For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
				
				If InventoryLine.Count = 0 Then
					Continue;
				EndIf;
				
				Count = Min(GoodsQuantity, InventoryLine.Count);
				
				NewRow = InventoryKinds.Add();
				FillPropertyValues(NewRow, InventoryLine);
				
				NewRow.ProductsRecordingAsReceived	= RowOfGoods.ProductsRecordingAsReceived;
				NewRow.CharacteristicRecordingAsReceived	= RowOfGoods.CharacteristicRecordingAsReceived;
				
				NewRow.Count = Count;
				
				InventoryLine.Count = InventoryLine.Count - NewRow.Count;
				
				GoodsQuantity = GoodsQuantity - NewRow.Count;
				
				If GoodsQuantity = 0 Then
					Break;
				EndIf;
			
			EndDo;
			
		EndDo;
		
		FilterParameters = New Structure("Count", 0);
		LinesToDelete = InventoryKinds.FindRows(FilterParameters);
		
		For Each TableRow In LinesToDelete Do
			InventoryKinds.Delete(TableRow);
		EndDo;
		
	EndIf;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.GoodsReceiptFromCustomer.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.GoodsReceiptFromCustomer.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(Undefined,
																		Warehouse,
																		Department,
																		Partner,
																		Contract);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.BatchesIndicationStatus = "BatchesIndicationStatusInWarehouses";
	
	// If the Warehouse is a group, then we take the warehouse from the PM for inventory accounting analytics.
	WarehouseDetails = Common.ObjectAttributesValues(Warehouse, "IsFolder, SelectGroup");
	
	If ValueIsFilled(Warehouse)
		And WarehouseDetails.IsFolder
		And WarehouseDetails.SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
		
		FieldsNames.Insert("Arbitrary", "Warehouse");
		
	EndIf;
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
	PlacesOfRegistrationWithPartners = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																					Contract,
																					Department,
																					Partner,
																					Contract);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.ItemsLocationAttributes = "ItemsLocationAttributesGoodsAtPartners";
	FieldsNames.BatchesIndicationStatus        = "BatchesIndicationStatusOfGoodsTransferred";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfRegistrationWithPartners, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInPricesBySalesConditions()
	
	FillParameters = New Structure();
	FillParameters.Insert("PopulationFields", "Price");
	FillParameters.Insert("Date",           Date);
	FillParameters.Insert("Organization",    Organization);
	FillParameters.Insert("Currency",         Currency);
	FillParameters.Insert("Terms",     Terms);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount",     "NumberOfPackages");
	
	EnterprisePricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, StructureOfActions);
	
EndProcedure

Function GetDocumentAmount()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Sum    AS Sum
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SUM(Goods.Sum), 0) AS Sum
	|FROM
	|	Goods AS Goods";
	
	DocumentGoods = Goods.Unload(,"Products, Sum");
	
	Query.SetParameter("Goods", DocumentGoods);
	
	QueryResult = Query.Execute().Unload();
	TotalAmount__       = QueryResult[0].Sum; // DefinedType.MonetaryAmountPositiveNegative - 
	
	Return TotalAmount__;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
