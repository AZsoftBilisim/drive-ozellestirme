#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region SalesTermsAndConditions

// Fills in the terms of sale in the receipt of goods from the custodian.
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
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperation);
	
	Contract = Handler.GetDefaultContract(ThisObject);
	ContractDetails_ = New Structure("Currency, LineOfBusiness, Department", "ARAPCurrency");
	Catalogs.CounterpartyContracts.FillInDocumentDetails(ThisObject, Contract, ContractDetails_);
	
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Warehouse) Then
		Warehouse = SalesTermsAndConditions.Warehouse;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.PricesKind) Then
		PriceKind = SalesTermsAndConditions.PricesKind;
	EndIf;
	
EndProcedure

// Fills in the default sales terms in the receipt of goods from the custodian.
//
Procedure FillInDefaultSalesConditions() Export
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperation);
	
	ToUseTermsOfSales = Handler.ToUseTermsOfSales();
	
	If ValueIsFilled(Partner)
		Or Not ToUseTermsOfSales Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.ReceiptOfGoodsFromCustodian.EmptyRef());
		FilterParameters.Insert("BusinessTransactions", Handler.ContractBusinessTransaction());
		FilterParameters.Insert("ConsignmentSales25", BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent);
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
										Partner, FilterParameters, Handler.CustomerAgreementsAreApplicable());
		
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

// Fills in the terms of sale under the agreement in receipt of goods from the custodian.
//
// Parameters:
//	RecalculatePrices_ - Boolean - To recalculate prices under the agreement.
//
Procedure FillInTermsOfSalesUnderAgreement(RecalculatePrices_ = True) Export
	
	If Not ValueIsFilled(Terms) Then
		Return;
	EndIf;
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperation);
	
	SalesTermsAndConditions = Handler.GetTermsAndConditionsOfSale(Terms);
	
	FillIn_TermsOfSales(SalesTermsAndConditions);
	If RecalculatePrices_ = True Then
		FillInPricesBySalesConditions();
	EndIf;
	
EndProcedure

#EndRegion

// This function generates temporary document data.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	QueryText = 
	"SELECT
	|	&Date                  AS Date,
	|	&Partner               AS Partner,
	|	&Counterparty            AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization           AS Organization,
	|	&Warehouse                 AS Warehouse,
	|	&Contract               AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	FALSE                   AS ThereAreTransactionsInTablePart,
	|	&InventoryType            AS InventoryType
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
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatusOfGoodsTransferred = 18
	|				OR (TableOfGoods.BatchesIndicationStatusOfGoodsTransferred = 0
	|					AND TableOfGoods.BatchesIndicationStatusInWarehouses = 14)
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                              AS Series,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatusOfGoodsTransferred = 18
	|			THEN TableOfGoods.BatchesIndicationStatusOfGoodsTransferred
	|		WHEN TableOfGoods.BatchesIndicationStatusOfGoodsTransferred = 0
	|				AND TableOfGoods.BatchesIndicationStatusInWarehouses = 14
	|			THEN TableOfGoods.BatchesIndicationStatusInWarehouses
	|		ELSE 0
	|	END                              AS BatchesIndicationStatus,
	|	TableOfGoods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	TableOfGoods.Count          AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	&Contract                           AS Warehouse,
	|	TableOfGoods.CCDNumber            AS CCDNumber,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	0                                  AS CommissionAmount,
	|	0                                  AS AmountVATRemuneration
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
	|	TableOfGoods.SalesOpportunity                 AS SalesOpportunity,
	|	TableOfGoods.CommissionAmount    AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration AS AmountVATRemuneration,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND &ReusablePackageReturn
	|			THEN FALSE
	|		ELSE TRUE
	|	END                              AS SelectTypesOfStocks,
	|	LogInAnalytics.DimensionKey AS AnalysisOfAccountingForProductList
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON TableOfGoods.Products = CatProducts.Ref
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS LogInAnalytics
	|		ON TableOfGoods.ProductsRecordingAsReceived = LogInAnalytics.Products
	|			AND TableOfGoods.CharacteristicRecordingAsReceived = LogInAnalytics.Characteristic
	|			AND TableOfGoods.Purpose = LogInAnalytics.Purpose
	|			AND TableOfGoods.Series = LogInAnalytics.Series
	|			AND TableOfGoods.Warehouse = LogInAnalytics.StorageLocation
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	TableTypesOfStocks_.LineNumber      AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS BasicAnalytics,
	|	TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	TableTypesOfStocks_.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	TableTypesOfStocks_.InventoryOwnerAttribute       AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count       AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.CCDNumber         AS CCDNumber,
	|	TableTypesOfStocks_.Series            AS Series
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
	|	Dimension.Series                      AS Series,
	|	TableTypesOfStocks_.Count        AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN  AS QuantityByGBRN,
	|	UNDEFINED                         AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber          AS CCDNumber,
	|	Dimension.StorageLocation              AS Warehouse,
	|	0                                    AS CommissionAmount,
	|	0                                    AS AmountVATRemuneration,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
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
	Query.SetParameter("InventoryType",            Enums.InventoryTypes.OwnGoods);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("ReusablePackageReturn", ReusablePackageReturn);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return Query.TempTablesManager;
	
EndFunction

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.ReceiptOfGoodsFromCustodian - the document for which parameters are initialized.
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
//	DocumentTables - See Documents.ReceiptOfGoodsFromCustodian.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	FillStockTypes(Cancel);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperation);

	QuantityVerificationParameters = Handler.TSParametersForRounding(Warehouse);
	
	NotCheckedAttributeArray.Add("Goods.ProductsRecordingAsReceived");
	
	ProductsServer.CheckQuantityFilling(
		ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters["Goods"]);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReceiptOfGoodsFromCustodian);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.FieldNamesWithSuffix.Insert("Products", "ProductsRecordingAsReceived");
	CheckParameters.FieldNamesWithSuffix.Insert("Characteristic", "CharacteristicRecordingAsReceived");
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date);
	
	If (GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers")
			Or ThisIsTraceableDocument)
		And Not BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
		And Not BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5
		And Not BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel);
		
	EndIf;
	
	If Not Handler.CustomerAgreementsAreApplicable() Then
		NotCheckedAttributeArray.Add("Terms");
	EndIf;
	
	If ByReferences Then
		
		For Each CurrentData In Goods Do
			
			If Not ValueIsFilled(ReferenceOrder)
				And Not ValueIsFilled(CurrentData.ReferenceOrder) Then
				
				ErrorText = NStr("vi = 'Chưa điền trường ""Lệnh"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Распоряжение"" в строке %LineNumber% списка ""Товары""';
								|en = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list'; fa = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list';
								|it = 'Campo ""Disposizione"" non compilato nella riga %LineNumber% dell''elenco ""Articoli""';
								|pl = 'Pole ""Zamówienie"" w wierszu %LineNumber% listy ""Towary""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Emir"" alanı doldurulmamış'");
				ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentData.LineNumber);
				
				Common.MessageToUser(
					ErrorText,
					ThisObject,
					CommonClientServer.PathToTabularSection("Goods",
						CurrentData.LineNumber,
						"ReferenceOrder"),,
					Cancel);
					
			EndIf;
			
		EndDo;
		
	EndIf;
	
	For Each CurrentData In Goods Do
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'в строке %LineNumber% списка ""Товары""';
									|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'w wierszu %LineNumber% listy ""Towary""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress =  StrReplace(ErrorAddress, "%LineNumber%", CurrentData.LineNumber);
		
		ProductDescriptionField = CommonClientServer.PathToTabularSection("Goods",
			CurrentData.LineNumber,
			"ProductsRecordingAsReceived");
		
		If CurrentData.Damage Then
			
			ErrorText = "";
			
			If Not ValueIsFilled(CurrentData.ProductsRecordingAsReceived) Then
				ErrorText = NStr("vi = 'Cột ""mặt hàng (đăng)"" không được điền';
								|ru = 'Не заполнена колонка ""Номенклатура (оприходование)""';
								|en = 'Column ""Items (recording as received)"" is not filled in'; fa = 'Column ""Items (recording as received)"" is not filled in';
								|it = 'La colonna ""Articolo (registrazione in contabilità)"" non è compilata';
								|pl = 'Nie wypełniono kolumny ""Номенклатура (оприходование)""';
								|tr = '""Öğe (Envanter)"" sütunu eksik'");
			ElsIf CurrentData.Products = CurrentData.ProductsRecordingAsReceived Then
				ErrorText = NStr("vi = 'Hàng hóa có chất lượng ban đầu trùng với hàng hóa có chất lượng khác';
								|ru = 'Товар исходного качества совпадает с товаром другого качества';
								|en = 'Goods of original quality matches with goods of different quality'; fa = 'Goods of original quality matches with goods of different quality';
								|it = 'Il prodotto della qualità originale coincide con il prodotto di una qualità diversa';
								|pl = 'Towar oryginalnej jakości zbiega się z towarem innej jakości';
								|tr = 'Orijinal kalitedeki ürün uygun kalitede olmayan ürünle eşleşmektedir'");
			EndIf;
			
			If ValueIsFilled(ErrorText) Then
				
				Common.MessageToUser(ErrorText + ErrorAddress,
					ThisObject,
					ProductDescriptionField,,
					Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	PartnersAndCounterparties.CheckPartnerContent(ThisObject, NotCheckedAttributeArray, Cancel);
	
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
	
	ReceiptOfGoodsFromCustodianLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	FillInDataType = TypeOf(FillingData);
	FilledInBasedOnDocument = False;
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("AnArrayOfOrders")
		And FillingData.AnArrayOfOrders.Count() > 0 Then
		
		OrderToFillIn = FillingData.AnArrayOfOrders[0];
		
		OrderOperation = Common.ObjectAttributeValue(OrderToFillIn, "BusinessOperation");
		If OrderOperation = Enums.BusinessTransactions.TransferToToller2_5
		 Or OrderOperation = Enums.BusinessTransactions.ProductionByToller2_5
		 Or OrderOperation = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5 Then
			FillingData.HeaderAttributes.Property("BusinessOperation", OrderOperation);
		EndIf;
		If TypeOf(OrderToFillIn) = Type("DocumentRef.TransferOfGoodsToBailee") Then
			
			If OrderOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
				OrderOperation = Enums.BusinessTransactions.ReturnFromCustodian;
			ElsIf OrderOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
				OrderOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent;
			EndIf;
			
		EndIf;
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOnOperation(
			FillingData.AnArrayOfOrders[0],
			"ReceiptOfGoodsFromCustodian",
			OrderOperation);
		
	EndIf;
	
	FilledInBasedOnDocument = False;
	
	If FillInDataType = Type("Structure")
		And FillingData.Property("AnArrayOfOrders") Then
		
		FillInFromOrder(FillingData);
		FilledInBasedOnDocument = True;
		
	ElsIf FillInDataType = Type("Structure")
		And FillingData.Property("BasisOfAct")
		And TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.TransferOfGoodsToBailee") Then
		
		FillInCertificateOfDiscrepanciesAfterShipment(FillingData);
		FilledInBasedOnDocument = True;
		
	ElsIf FillInDataType = Type("Structure")
		And FillingData.Property("BasisOfAct") Then
		
		If FillingData.Property("Patch") Then
			DocumentCorrection.FillInCorrection(ThisObject, FillingData.BasisOfAct);
			CorrectionOfCorrectionOfDocumentOnBasisOfActOfDiscrepanciesAfterAcceptance(FillingData);
		Else
			FillInCertificateOfDiscrepanciesAfterAcceptance(FillingData);
		EndIf;
		FilledInBasedOnDocument = True;
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsShipmentFromStorage") Then
		FillInShippingGoodsFromStorage(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		FilledInBasedOnDocument = True;
		
	EndIf;
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperation);
	If Not Handler.ToUseTermsOfSales()
		And Not FilledInBasedOnDocument Then
		FillInDefaultSalesConditions();
	EndIf;
	
	InitializeDocument(FillingData);
	
	CalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
						ThisObject,
						"Contract");
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(CalculationParameters, Goods);
	
	ReceiptOfGoodsFromCustodianLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperation);
	UseLineCode = Handler.UseLineCode();
	
	If ByReferences
		And (Not UseLineCode
			Or ValueIsFilled(ReferenceOrder)) Then
		
		For Each CurrentData In Goods Do
			
			If Not UseLineCode Then
				CurrentData.RowCode = 0;
			EndIf;
			
			If ValueIsFilled(ReferenceOrder)
				And Not ValueIsFilled(CurrentData.ReferenceOrder) Then
				CurrentData.ReferenceOrder = ReferenceOrder;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	RoundingParameters = Handler.TSParametersForRounding(Warehouse);
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters["Goods"]);
	
	DocumentAmount         = GetDocumentAmount();
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReceiptOfGoodsFromCustodian);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		AccountingForTraceableGoodsLocalization.ClearDataOnImportedGoodsInCommissionAgentSDocuments(ThisObject);
	Else
		ClearDataOnImportedGoodsForProcessingOperations();
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	// The mechanism of "Controlled Lot references".
	KeyAttributes = QualityControl.DetailsOfDeterminingNeedForLotReferenceInDocument(Warehouse, BusinessOperation);
	QualityControl.FillInControlledLotReferenceBeforeWritingDocument(ThisObject, KeyAttributes);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	ReceiptOfGoodsFromCustodianLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperation);
	Handler.AddAdditionalPropertyToControlWhenConducting(ThisObject);
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateUpdateControlledLotReferenceWhenWritingDocument(ThisObject);
	
	ReceiptOfGoodsFromCustodianLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.Posting);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ReceiptOfGoodsFromCustodianLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.UndoPosting);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ReceiptOfGoodsFromCustodianLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	ByReferences           = False;
	ReferenceOrder              = Undefined;
	InventoryOwnerAttributesAreSpecifiedManually = False;
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	DocumentBasis = Undefined;
	
	For Each CurRow In Goods Do
		
		CurRow.ReferenceOrder = Undefined;
		CurRow.RowCode = 0;
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
	
	ReceiptOfGoodsFromCustodianLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInFromOrder(FillingStructure)
	
	AnArrayOfOrders = FillingStructure.AnArrayOfOrders;
	
	If FillingStructure.Property("Warehouse")
		And ValueIsFilled(FillingStructure.Warehouse) Then
		
		FillingStructure.HeaderAttributes.Warehouse = FillingStructure.Warehouse;
		
	EndIf;
	
	FillParameters = Documents.ReceiptOfGoodsFromCustodian.DocumentFillingParameters();
	FillParameters.AddSeriesOnRequest = True;
	FillPropertyValues(FillParameters, FillingStructure);
	
	Documents.ReceiptOfGoodsFromCustodian.InitializeFillingParameters(FillParameters,
		FillingStructure.HeaderAttributes, AnArrayOfOrders);
	
	If FillingStructure.Property("FillByWarehouseDocument") Then
		FillParameters.FillByWarehouseDocument = FillingStructure.FillByWarehouseDocument;
	Else
		WarehouseForReceipt = FillingStructure.HeaderAttributes.Warehouse;
		UseAdvancedWarehousing = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(WarehouseForReceipt,
																						Date);
		
		FillParameters.FillByWarehouseDocument = UseAdvancedWarehousing;
	EndIf;
	
	InvoiceTable = Documents.ReceiptOfGoodsFromCustodian.TableDataAndDocument(Ref);
	
	Documents.ReceiptOfGoodsFromCustodian.FillInByOrdersOrders(InvoiceTable, Ref, FillParameters);
	
	TableOverheadColumnQuantity = InvoiceTable.Columns.Count; // ValueTableColumn
	InvoiceTableColumnsQuantityInOrder_ = InvoiceTable.Columns.NoteQuantity; // ValueTableColumn
	InvoiceTableColumnsQuantityInOrder = InvoiceTable.Columns.QuantityInOrder; // ValueTableColumn
	
	If FillParameters.FillByWarehouseDocument Then
		TableOverheadColumnQuantity.Name        = "QuantityBeforeChange_";
		InvoiceTableColumnsQuantityInOrder_.Name = "Count";
	Else
		TableOverheadColumnQuantity.Name        = "QuantityBeforeChange_";
		InvoiceTableColumnsQuantityInOrder.Name = "Count";
	EndIf;
	
	InvoicesServer.DeleteEmptyLines(InvoiceTable, "Count");
	
	Goods.Load(InvoiceTable);
	
	If ValueIsFilled(AnArrayOfOrders)
		And TypeOf(AnArrayOfOrders[0]) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	ReturnedBatch.Products AS Products,
		|	ReturnedBatch.Characteristic AS Characteristic,
		|	ReturnedBatch.Series AS Series,
		|	ReturnedBatch.Warehouse AS Warehouse,
		|	ReturnedBatch.Purpose AS Purpose,
		|	SUM(ReturnedBatch.Count) AS Count
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedBatch AS ReturnedBatch
		|WHERE
		|	ReturnedBatch.Ref IN (&AnArrayOfOrders)
		|	AND ReturnedBatch.Warehouse IN (&Warehouse)
		|	
		|GROUP BY
		|	ReturnedBatch.Products,
		|	ReturnedBatch.Characteristic,
		|	ReturnedBatch.Series,
		|	ReturnedBatch.Warehouse,
		|	ReturnedBatch.Purpose";
		
		Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
		Query.SetParameter("Warehouse", FillingStructure.HeaderAttributes.Warehouse);
		
		Result = Query.Execute().Unload();
		SetOfSeries.Load(Result);
		
	EndIf;
	
	Documents.ReceiptOfGoodsFromCustodian.FillInHeaderOfOrderDocument(ThisObject, FillParameters);
	Documents.ReceiptOfGoodsFromCustodian.UpdateDependentDetailsOfTablePart(ThisObject, FillParameters);
	
	OrdersServer.FillInOrderInOrderHeaderInTableSection(ReferenceOrder, Goods, "ReferenceOrder");
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReceiptOfGoodsFromCustodian);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	If TypeOf(ReferenceOrder) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
		And BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		And ValueIsFilled(Contract) Then
		ConsignmentSales25 = Common.ObjectAttributeValue(Contract, "ConsignmentSales25");
		If ConsignmentSales25 = False Then
			ErrorText = NStr("vi = 'Không thể lập chứng từ ""%1"" trên cơ sở lệnh %2 với hợp đồng ký gửi phiên bản %3. Để lập chứng từ trả lại, hãy sử dụng chứng từ ""%4""';
							|ru = 'Невозможно оформить документ ""%1"" на основании распоряжения %2 с договором комиссии версии %3. Для оформления возврата воспользуйтесь документом ""%4""';
							|en = 'Cannot register the ""%1"" document based on the %2 reference with the cross-company sales contract version %3. To register the return, use the ""%4"" document'; fa = 'Cannot register the ""%1"" document based on the %2 reference with the cross-company sales contract version %3. To register the return, use the ""%4"" document';
							|it = 'Impossibile registrare il documento ""%1"" in base all''ordine %2 con l''accordo di commissione della versione %3. Per la registrazione del reso utilizzare il documento ""%4""';
							|pl = 'Nie można utworzyć dokumentu ""%1"" na podstawie zamówienia %2 z umową komisową wersji %3. Aby utworzyć zwrot użyj dokumentu ""%4""';
							|tr = 'Komisyon sözleşmesi %3versiyonuna sahip bir %2emir temelinde bir ""%1"" belgesi düzenlemek mümkün değildir. İadeyi yapmak için ""%4"" belgesini kullanın'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
												Metadata.Documents.ReceiptOfGoodsFromCustodian.Synonym,
												ReferenceOrder,
												ConsignmentSalesServer.PostfixCommissionSchemes20(),
												Metadata.Documents.ReturnOfGoodsFromCustomer.Synonym);
			
			Raise ErrorText;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInCertificateOfDiscrepanciesAfterAcceptance(FillingStructure)
	
	FillParameters = Documents.ReceiptOfGoodsFromCustodian.DocumentFillingParameters();
	FillPropertyValues(FillParameters, FillingStructure);
	
	HeaderAttributes = "ReferenceOrder, BusinessOperation, Organization, Department, Warehouse, SalesOpportunity, Partner, Counterparty,
						|Terms, Contract, LineOfBusiness";
	HeaderFields = Common.ObjectAttributesValues(FillingStructure.BasisOfAct, HeaderAttributes);
	
	AnArrayOfOrders = New Array();
	AnArrayOfOrders.Add(HeaderFields.ReferenceOrder);
	
	FillParameters.AnArrayOfOrders = AnArrayOfOrders;
	FillParameters.HeaderAttributes = HeaderFields;
	FillPropertyValues(FillParameters, HeaderFields);
	
	EmptyReceiptFromKeeper = Documents.ReceiptOfGoodsFromCustodian.EmptyRef();
	
	InvoiceTable = Documents.ReceiptOfGoodsFromCustodian.TableDataAndDocument(EmptyReceiptFromKeeper);
	
	Documents.ReceiptOfGoodsFromCustodian.FillInByOrdersOrders(InvoiceTable, Ref, FillParameters);
	
	TableOverheadColumnQuantity = InvoiceTable.Columns.Count; // ValueTableColumn
	InvoiceTableColumnsQuantityInOrder = InvoiceTable.Columns.QuantityInOrder; // ValueTableColumn
	
	TableOverheadColumnQuantity.Name        = "QuantityBeforeChange_";
	InvoiceTableColumnsQuantityInOrder.Name = "Count";
	
	InvoicesServer.DeleteEmptyLines(InvoiceTable, "Count");
	
	Goods.Load(InvoiceTable);
	
	Documents.ReceiptOfGoodsFromCustodian.FillInHeaderOfOrderDocument(ThisObject, FillParameters);
	AdditionalReturnWithinGoodsReceipt = FillingStructure.BasisOfAct;
	Documents.ReceiptOfGoodsFromCustodian.UpdateDependentDetailsOfTablePart(ThisObject, FillParameters);
	
	OrdersServer.FillInOrderInOrderHeaderInTableSection(ReferenceOrder, Goods, "ReferenceOrder");
	
EndProcedure

Procedure CorrectionOfCorrectionOfDocumentOnBasisOfActOfDiscrepanciesAfterAcceptance(FillingData)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductsOfAct.RowCode            AS RowCode,
	|	ProductsOfAct.FilledUsingBaseDocument AS FilledUsingBaseDocument,
	|	ProductsOfAct.Products         AS Products,
	|	ProductsOfAct.Characteristic       AS Characteristic,
	|	ProductsOfAct.Package             AS Package,
	|	ProductsOfAct.Purpose           AS Purpose,
	|	ProductsOfAct.Series                AS Series,
	|	ProductsOfAct.BatchesIndicationStatus  AS BatchesIndicationStatus,
	|	ProductsOfAct.Price                 AS Price,
	|	ProductsOfAct.PurchaseOrder      AS ReferenceOrder,
	|	ProductsOfAct.CCDNumber             AS CCDNumber,
	|	ProductsOfAct.Count           AS Count,
	|	ProductsOfAct.Sum                AS Sum
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS ProductsOfAct
	|WHERE
	|	ProductsOfAct.Ref = &DiscrepancyCertificate
	|	AND ProductsOfAct.DocumentBasis = &DocumentBasis
	|	AND ProductsOfAct.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|	AND ProductsOfAct.Count > 0
	|
	|ORDER BY
	|	LineNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	ActSeries.LineNumber    AS LineNumber,
	|	ActSeries.Products   AS Products,
	|	ActSeries.Characteristic AS Characteristic,
	|	ActSeries.Series          AS Series,
	|	ActSeries.Purpose     AS Purpose,
	|	ActSeries.Count     AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS ActSeries
	|WHERE
	|	ActSeries.Ref = &DiscrepancyCertificate
	|	AND ActSeries.DocumentBasis = &DocumentBasis
	|	AND ActSeries.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|	AND ActSeries.Count > 0
	|	AND NOT (NOT ActSeries.FilledUsingBaseDocument
	|		AND ActSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef))";
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate",  FillingData.DiscrepancyCertificate);
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	TableOfItemsOfReport = QueryBatch[0].Unload();
	ActSeriesTable  = QueryBatch[1].Unload();
	
	GoodsTable = Goods.Unload();
	SeriesTable  = SetOfSeries.Unload();
	
	// Re-filling of products and series according to the act
	SelectionColumns =
		"Products,
		|Characteristic,
		|Purpose,
		|Series";
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		If ByReferences Then
			AdditionalColumns = "RowCode, ReferenceOrder, CCDNumber";
		Else
			AdditionalColumns = "CCDNumber";
		EndIf;
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		And ByReferences Then
		AdditionalColumns = "RowCode, ReferenceOrder";
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5 Then
		AdditionalColumns = "";
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
		And ByReferences Then
		AdditionalColumns = "RowCode, ReferenceOrder";
	EndIf;
	If Not IsBlankString(AdditionalColumns) Then
		SelectionColumns = SelectionColumns + "," + AdditionalColumns;
	EndIf;
	FilterParameters = New Structure(SelectionColumns);
	
	For Each CurRow In TableOfItemsOfReport Do
		
		If CurRow.FilledUsingBaseDocument Then
			FillPropertyValues(FilterParameters, CurRow);
			FoundRows = GoodsTable.FindRows(FilterParameters);
			If FoundRows.Count() > 0 Then
				FoundRow = FoundRows[0];
				FoundRow.Count = CurRow.Count;
				FoundRow.Sum      = CurRow.Sum;
			Else
				NewRow = GoodsTable.Add();
				FillPropertyValues(NewRow, CurRow);
			EndIf;
		Else // to add lines from the act in addition to the order
			NewRow = GoodsTable.Add();
			FillPropertyValues(NewRow, CurRow);
		EndIf;
		
	EndDo;
	
	SelectionColumns =
		"LineNumber,
		|Products,
		|Characteristic,
		|Series,
		|Purpose";
	FilterParameters = New Structure(SelectionColumns);
	
	For Each CurRow In ActSeriesTable Do
		
		FillPropertyValues(FilterParameters, CurRow);
		
		FoundRows = SeriesTable.FindRows(FilterParameters);
		If FoundRows.Count() > 0 Then
			
			For Each FoundRow In FoundRows Do
				
				If FoundRow.Count = CurRow.Count Then
					Continue;
				EndIf;
				
				If FoundRow.Count > CurRow.Count Then
					FoundRow.Count = CurRow.Count;
				Else
					NewRow = SeriesTable.Add();
					FillPropertyValues(NewRow, FoundRow);
					NewRow.Count = CurRow.Count - FoundRow.Count;
				EndIf;
				
			EndDo;
			
		Else // to add lines from the act in addition to the order
			NewRow = SeriesTable.Add();
			FillPropertyValues(NewRow, CurRow);
		EndIf;
		
	EndDo;
	
	Goods.Load(GoodsTable);
	SetOfSeries.Load(SeriesTable);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Procedure InitializeDocumentBeforeFillingItOut()
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
EndProcedure

Procedure FillInCertificateOfDiscrepanciesAfterShipment(FillingStructure)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsHandover.Ref        AS Ref,
	|	UNDEFINED                  AS DocumentStatus,
	|	GoodsHandover.Partner       AS Partner,
	|	GoodsHandover.Counterparty    AS Counterparty,
	|	GoodsHandover.Terms    AS Terms,
	|	CASE
	|		WHEN GoodsHandover.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|		WHEN GoodsHandover.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToToller2_5)
	|			THEN VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5)
	|		ELSE VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|	END                         AS BusinessOperation,
	|	GoodsHandover.Organization   AS Organization,
	|	CASE
	|		WHEN GoodsHandover.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE GoodsHandover.Warehouse
	|	END                         AS Warehouse,
	|	GoodsHandover.Contract       AS Contract,
	|	GoodsHandover.Currency        AS Currency,
	|	GoodsHandover.Currency        AS ARAPCurrency,
	|	GoodsHandover.SalesOpportunity        AS SalesOpportunity,
	|	GoodsHandover.Department AS Department,
	|	GoodsHandover.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	GoodsHandover.ToReturnReusablePackage AS ReusablePackageReturn,
	|	FALSE                          AS DepositForPackageIsRequired,
	|	NOT GoodsHandover.Posted   AS ThereAreErrorsPosted,
	|	FALSE                          AS ThereAreErrorsStatus
	|FROM
	|	Document.TransferOfGoodsToBailee AS GoodsHandover
	|WHERE
	|	GoodsHandover.Ref = &DocumentBasisCorrectionOfBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	DocumentGoods.Products    AS Products,
	|	CatProducts.ItemsType AS ItemsType,
	|	DocumentGoods.Characteristic  AS Characteristic,
	|	DocumentGoods.Purpose      AS Purpose,
	|	DocumentGoods.Package        AS Package,
	|	DocumentGoods.Series           AS Series,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(DocumentGoods.NumberOfPackages) AS NumberOfPackages,
	|	AVG(DocumentGoods.Price)   AS Price,
	|	SUM(DocumentGoods.Sum)    AS Sum
	|INTO TransferGoods
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON DocumentGoods.Products = CatProducts.Ref
	|WHERE
	|	DocumentGoods.Ref = &DocumentBasisCorrectionOfBasis
	|
	|GROUP BY
	|	DocumentGoods.Products,
	|	CatProducts.ItemsType,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Purpose,
	|	DocumentGoods.Series,
	|	DocumentGoods.Package
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	DocumentGoods.Products    AS Products,
	|	CatProducts.ItemsType AS ItemsType,
	|	DocumentGoods.Characteristic  AS Characteristic,
	|	DocumentGoods.Purpose      AS Purpose,
	|	DocumentGoods.Package        AS Package,
	|	DocumentGoods.Series           AS Series,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(DocumentGoods.NumberOfPackages) AS NumberOfPackages,
	|	AVG(DocumentGoods.Price)   AS Price,
	|	SUM(DocumentGoods.Sum)    AS Sum
	|INTO ProductsFromPreviousRefunds
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS DocumentGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON DocumentGoods.Products = CatProducts.Ref
	|WHERE
	|	DocumentGoods.Ref.Posted
	|	AND DocumentGoods.Ref.DocumentTransfers_ = &DocumentBasis
	|
	|GROUP BY
	|	DocumentGoods.Products,
	|	CatProducts.ItemsType,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Purpose,
	|	DocumentGoods.Package,
	|	DocumentGoods.Series
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
	|	&DocumentBasis             AS DocumentSalesOfGoodsAndServices,
	|	TransferGoods.Products    AS Products,
	|	TransferGoods.ItemsType AS ItemsType,
	|	TransferGoods.Characteristic  AS Characteristic,
	|	TransferGoods.Purpose      AS Purpose,
	|	TransferGoods.Package        AS Package,
	|	TransferGoods.Series           AS Series,
	|	TransferGoods.Count - ISNULL(RefundProducts.Count, 0) AS Count,
	|	TransferGoods.NumberOfPackages - ISNULL(RefundProducts.NumberOfPackages, 0) AS NumberOfPackages,
	|	CASE
	|		WHEN TransferGoods.NumberOfPackages - ISNULL(RefundProducts.NumberOfPackages, 0) = 0
	|			THEN TransferGoods.Price
	|		ELSE (TransferGoods.Sum - ISNULL(RefundProducts.Sum, 0)) / (TransferGoods.NumberOfPackages - ISNULL(RefundProducts.NumberOfPackages, 0))
	|	END                          AS Price,
	|	TransferGoods.Sum - ISNULL(RefundProducts.Sum, 0) AS Sum
	|INTO TTProducts_1
	|FROM
	|	TransferGoods AS TransferGoods
	|		LEFT JOIN ProductsFromPreviousRefunds AS RefundProducts
	|		ON TransferGoods.Products = RefundProducts.Products
	|			AND TransferGoods.Characteristic = RefundProducts.Characteristic
	|			AND TransferGoods.Purpose = RefundProducts.Purpose
	|			AND TransferGoods.Series = RefundProducts.Series
	|WHERE
	|	TransferGoods.Count - ISNULL(RefundProducts.Count, 0) > 0
	|	AND (TransferGoods.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|		OR TransferGoods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND NOT CAST(&DocumentBasis AS Document.TransferOfGoodsToBailee).ToReturnReusablePackage)
	|
	|INDEX BY
	|	DocumentSalesOfGoodsAndServices,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Package,
	|	Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	DiscrepancyCertificate.SaleOfGoodsAndServices     AS DocumentSalesOfGoodsAndServices,
	|	DiscrepancyCertificate.Products   AS Products,
	|	DiscrepancyCertificate.Characteristic AS Characteristic,
	|	DiscrepancyCertificate.Purpose     AS Purpose,
	|	DiscrepancyCertificate.Package       AS Package,
	|	DiscrepancyCertificate.Series          AS Series,
	|	SUM(DiscrepancyCertificate.Count - DiscrepancyCertificate.CountByDocument) AS Count,
	|	SUM(DiscrepancyCertificate.NumberOfPackages - DiscrepancyCertificate.NumberOfPackagesByDocument) AS NumberOfPackages,
	|	SUM(DiscrepancyCertificate.Sum - DiscrepancyCertificate.SumByDocument) AS Sum
	|INTO TTCertificateOfDiscrepanciesAfterShipment
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS DiscrepancyCertificate
	|WHERE
	|	DiscrepancyCertificate.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyCertificate.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|	AND DiscrepancyCertificate.SaleOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	DiscrepancyCertificate.SaleOfGoodsAndServices,
	|	DiscrepancyCertificate.Products,
	|	DiscrepancyCertificate.Characteristic,
	|	DiscrepancyCertificate.Purpose,
	|	DiscrepancyCertificate.Package,
	|	DiscrepancyCertificate.Series
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Package,
	|	Series,
	|	DocumentSalesOfGoodsAndServices
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	TTProducts_1.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TTProducts_1.Products   AS Products,
	|	TTProducts_1.Characteristic AS Characteristic,
	|	TTProducts_1.Purpose     AS Purpose,
	|	TTProducts_1.Series          AS Series,
	|	TTProducts_1.Package       AS Package,
	|	CASE
	|		WHEN TTProducts_1.Count < DiscrepancyCertificate.Count
	|			THEN TTProducts_1.Count
	|		ELSE DiscrepancyCertificate.Count
	|	END                   AS Count,
	|	CASE
	|		WHEN TTProducts_1.NumberOfPackages < DiscrepancyCertificate.NumberOfPackages
	|			THEN TTProducts_1.NumberOfPackages
	|		ELSE DiscrepancyCertificate.NumberOfPackages
	|	END                   AS NumberOfPackages,
	|	TTProducts_1.Price           AS Price,
	|	CASE
	|		WHEN TTProducts_1.Sum < DiscrepancyCertificate.Sum
	|			THEN TTProducts_1.Sum
	|		ELSE DiscrepancyCertificate.Sum
	|	END                   AS Sum
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|		INNER JOIN TTCertificateOfDiscrepanciesAfterShipment AS DiscrepancyCertificate
	|		ON TTProducts_1.Products = DiscrepancyCertificate.Products
	|			AND TTProducts_1.Characteristic = DiscrepancyCertificate.Characteristic
	|			AND TTProducts_1.Purpose = DiscrepancyCertificate.Purpose
	|			AND TTProducts_1.Package = DiscrepancyCertificate.Package
	|			AND TTProducts_1.Series = DiscrepancyCertificate.Series
	|			AND TTProducts_1.DocumentSalesOfGoodsAndServices = DiscrepancyCertificate.DocumentSalesOfGoodsAndServices;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose AS Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse AS Warehouse,
	|	SUM(DiscrepancyReportFollowingShipmentSetOfSeries.Count - DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument) AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS DiscrepancyReportFollowingShipmentSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.Count - DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument > 0
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.SaleOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose
	|";
	
	Query.SetParameter("DiscrepancyCertificate",  FillingStructure.DiscrepancyCertificate);
	Query.SetParameter("DocumentBasis", FillingStructure.BasisOfAct);
	
	// Filling in the act if there is a correction of the grounds of the act.
	If FillingStructure.Property("CorrectionOfBasis") And ValueIsFilled(FillingStructure.CorrectionOfBasis) Then
		Query.SetParameter("DocumentBasisCorrectionOfBasis", FillingStructure.CorrectionOfBasis);
	Else
		Query.SetParameter("DocumentBasisCorrectionOfBasis", FillingStructure.BasisOfAct);
	EndIf;
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	HeaderSelection = QueryBatch[0].Select();
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.Ref,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsStatus);
	
	DocumentTransfers_ = FillingStructure.BasisOfAct;
	FillPropertyValues(ThisObject, HeaderSelection);
	
	TableOfGoods = QueryBatch[5].Unload();
	
	For Each CurRow In TableOfGoods Do
		NewRow = Goods.Add();
		FillPropertyValues(NewRow,CurRow);
	EndDo;
	
	SetOfSeries.Load(QueryBatch[6].Unload());
	
EndProcedure

#Region FillingInForShipmentOfGoodsFromStorage

Procedure FillInShippingGoodsFromStorage(FillingStructure)
	
	DetailsOfFoundation = Common.ObjectAttributesValues(FillingStructure, "BusinessOperation, ByOrder");
	
	If DetailsOfFoundation.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
		BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5;
	Else
		BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Basis",             FillingStructure);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	If DetailsOfFoundation.ByOrder
		And GetFunctionalOption("UseSubcontractOrders2_5") Then
		ByReferences  = True;
		Query.Text = FillInQueryTextBasedOnTransferToGiverForOrders();
	Else
		Query.Text = FillInQueryTextBasedOnTransferToGiverWithoutOrder();
	EndIf;
	
	Result = Query.ExecuteBatch();
	HeaderAttributes = Result[Result.UBound() - 2].Select();
	GoodsTable  = Result[Result.UBound() - 1].Unload();
	OrdersTable  = Result[Result.UBound()].Unload();
	
	If HeaderAttributes.Next() Then
		
		FillingErrors = New Array;
		ErrorTemplate = NStr("vi = 'Không thể nhập trên cơ sở chuyển giao cho người đặt gia công. Trong đơn đặt hàng gia công đã chỉ ra các ""%1"" khác nhau.';
							|ru = 'Ввод на основании передачи давальцу невозможен. В заказах переработчику указаны разные ""%1"".';
							|en = 'Cannot generate documents based on transfers to provider. Different %1 are specified in subcontracting purchase orders.'; fa = 'Cannot generate documents based on transfers to provider. Different %1 are specified in subcontracting purchase orders.';
							|it = 'Ввод на основании передачи давальцу невозможен. В заказах переработчику указаны разные ""%1"".';
							|pl = 'Cannot generate documents based on transfers to provider. Different %1 are specified in subcontracting purchase orders.';
							|tr = 'Sağlayıcıya transfer temelinde giriş mümkün değildir. Fason satın alma siparişlerinde farklı ""%1"" bulunmaktadır.'");
		
		If HeaderAttributes.ErrorLineOfBusiness Then
			FillingErrors.Add(NStr("vi = 'Lĩnh vực hoạt động';
									|ru = 'Направления деятельности';
									|en = 'Lines of business'; fa = 'خطوط کسب‌وکار';
									|it = 'Settori di attività';
									|pl = 'Rodzaje działalności';
									|tr = 'İş kolları'"));
		EndIf;
		
		If HeaderAttributes.WarehouseError Then
			FillingErrors.Add(NStr("vi = 'Kho bãi';
									|ru = 'Склады';
									|en = 'Warehouses'; fa = 'انبارها';
									|it = 'Склады';
									|pl = 'Warehouses';
									|tr = 'Ambarlar'"));
		EndIf;
		
		If HeaderAttributes.ErrorDivision Then
			FillingErrors.Add(NStr("vi = 'Bộ phận';
									|ru = 'Подразделения';
									|en = 'Business units'; fa = 'واحدهای تجاری';
									|it = 'Подразделения';
									|pl = 'Business units';
									|tr = 'Departmanlar'"));
		EndIf;
		
		If HeaderAttributes.CurrencyError Then
			FillingErrors.Add(NStr("vi = 'Tiền tệ';
									|ru = 'Валюты';
									|en = 'Currencies'; fa = 'ارزها';
									|it = 'Валюты';
									|pl = 'Currencies';
									|tr = 'Para birimleri'"));
		EndIf;
		
		If HeaderAttributes.ErrorPriceIncludesVAT Then
			FillingErrors.Add(NStr("vi = 'Đơn giá bao gồm thuế GTGT';
									|ru = 'Включения НДС в цену';
									|en = 'VAT is included in the price'; fa = 'VAT is included in the price';
									|it = 'Включения НДС в цену';
									|pl = 'VAT is included in the price';
									|tr = 'KDV''nin fiyata dahil edilmesi'"));
		EndIf;
		
		If HeaderAttributes.ErrorSalesOpportunity Then
			FillingErrors.Add(NStr("vi = 'Vụ việc';
									|ru = 'Сделки';
									|en = 'Sales opportunities'; fa = 'فرصت‌های فروش';
									|it = 'Сделки';
									|pl = 'Sales opportunities';
									|tr = 'Satış fırsatları'"));
		EndIf;
		
		If Not FillingErrors.Count() = 0 Then
			ErrorText = StrTemplate(ErrorTemplate, StrConcat(FillingErrors, ", "));
			Raise ErrorText;
		EndIf;
		
		FillPropertyValues(ThisObject, HeaderAttributes);
		
	EndIf;
	
	If ByReferences Then
		
		OrdersWarehouses = OrdersTable.UnloadColumn("Warehouse");
		OrdersWarehouses = CommonClientServer.CollapseArray(OrdersWarehouses);
		
		If OrdersWarehouses.Count() > 1 Then
			Raise NStr("vi = 'Trong đơn đặt hàng gia công, đã chỉ ra nhiều kho, không thể nhập trên cơ sở chuyển giao cho người đặt gia công. Không thể tạo tiếp nhận theo mỗi kho riêng biệt.';
						|ru = 'В заказах переработчикам указано несколько складов, ввод на основании передачи давальцу невозможен. Необходимо оформить поступление по каждому складу отдельно.';
						|en = 'Subcontracting purchase orders contain several warehouses. Cannot generate documents based on transfers to provider. Register the receipt for each warehouse separately.'; fa = 'Subcontracting purchase orders contain several warehouses. Cannot generate documents based on transfers to provider. Register the receipt for each warehouse separately.';
						|it = 'В заказах переработчикам указано несколько складов, ввод на основании передачи давальцу невозможен. Необходимо оформить поступление по каждому складу отдельно.';
						|pl = 'Subcontracting purchase orders contain several warehouses. Cannot generate documents based on transfers to provider. Register the receipt for each warehouse separately.';
						|tr = 'Verilen fason satın alma siparişi birden fazla ambar belirtildi, sağlayıcıya transfer temelinde giriş mümkün değildir. Her bir ambar için makbuzun ayrı ayrı düzenlenmesi gerekmektedir.'");
		EndIf;
		
		FillInSubcontractPurchaseOrderInGiverSGoods(GoodsTable, OrdersTable);
		
		OrdersToProcessor = OrdersTable.UnloadColumn("SubcontractOrder");
		OrdersToProcessor = CommonClientServer.CollapseArray(OrdersToProcessor);
		
		If OrdersToProcessor.Count() = 1 Then
			GoodsTable.FillValues(OrdersToProcessor[0], "ReferenceOrder");
		EndIf;
		
	EndIf;
	
	Goods.Load(GoodsTable);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages", BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	OrdersServer.FillInOrderInOrderHeaderInTableSection(ReferenceOrder, Goods, "ReferenceOrder");
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReceiptOfGoodsFromCustodian));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Function FillInQueryTextBasedOnTransferToGiverForOrders()
	
	QueryText =
	"SELECT ALLOWED
	|	GiverSOrders.Ref AS MaterialProviderOrder
	|INTO GiverSOrders
	|FROM
	|	Document.GoodsShipmentFromStorage.Goods AS TableOfGoods
	|	
	|	INNER JOIN Document.MaterialProviderOrder2_5 AS ShippingGiverOrders
	|	ON ShippingGiverOrders.Ref = TableOfGoods.SalesOrder
	|	AND NOT ShippingGiverOrders.Basis = VALUE(Document.SubcontractOrder2_5.EmptyRef)
	|	
	|	INNER JOIN Document.MaterialProviderOrder2_5 AS GiverSOrders
	|	ON GiverSOrders.Basis = ShippingGiverOrders.Basis
	|	
	|WHERE
	|	TableOfGoods.Ref = &Basis
	|
	|GROUP BY
	|	GiverSOrders.Ref
	|
	|INDEX BY
	|	MaterialProviderOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OrderData.Basis                      AS SubcontractOrder,
	|	OrdersToProcessor.Date                    AS Date,
	|	OrdersToProcessor.Organization             AS Organization,
	|	OrdersToProcessor.Counterparty              AS Counterparty,
	|	OrdersToProcessor.Partner                 AS Partner,
	|	OrdersToProcessor.Contract                 AS Contract,
	|	OrdersToProcessor.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN OrdersToProcessor.ManufacturedProductsWarehouse.IsFolder
	|			AND OrdersToProcessor.ManufacturedProductsWarehouse.SelectGroup =
	|				VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE OrdersToProcessor.ManufacturedProductsWarehouse
	|	END                                       AS Warehouse,
	|	OrdersToProcessor.Department           AS Department,
	|	OrdersToProcessor.Currency                  AS Currency,
	|	OrdersToProcessor.PriceIncludesVAT         AS PriceIncludesVAT,
	|	OrdersToProcessor.SalesOpportunity                  AS SalesOpportunity
	|INTO OrdersToProcessor
	|FROM
	|	Document.MaterialProviderOrder2_5 AS OrderData
	|	
	|	INNER JOIN Document.SubcontractOrder2_5 AS OrdersToProcessor
	|	ON OrdersToProcessor.Ref = OrderData.Basis
	|
	|WHERE
	|	OrderData.Ref IN
	|		(SELECT
	|			GiverSOrders.MaterialProviderOrder AS MaterialProviderOrder
	|		FROM
	|			GiverSOrders AS GiverSOrders)
	|	AND OrdersToProcessor.Posted
	|
	|GROUP BY
	|	OrderData.Basis,
	|	OrdersToProcessor.Date,
	|	OrdersToProcessor.Organization,
	|	OrdersToProcessor.Counterparty,
	|	OrdersToProcessor.Partner,
	|	OrdersToProcessor.Contract,
	|	OrdersToProcessor.LineOfBusiness,
	|	CASE
	|		WHEN OrdersToProcessor.ManufacturedProductsWarehouse.IsFolder
	|			AND OrdersToProcessor.ManufacturedProductsWarehouse.SelectGroup =
	|				VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE OrdersToProcessor.ManufacturedProductsWarehouse
	|	END,
	|	OrdersToProcessor.Department,
	|	OrdersToProcessor.Currency,
	|	OrdersToProcessor.PriceIncludesVAT,
	|	OrdersToProcessor.SalesOpportunity
	|
	|INDEX BY
	|	SubcontractOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(OrdersToProcessor.Organization) AS Organization,
	|	MIN(OrdersToProcessor.Counterparty)  AS Counterparty,
	|	MIN(OrdersToProcessor.Partner)     AS Partner,
	|	MIN(OrdersToProcessor.Contract)     AS Contract,
	|	CASE
	|		WHEN COUNT(DISTINCT OrdersToProcessor.LineOfBusiness) = 1
	|			THEN MIN(OrdersToProcessor.LineOfBusiness)
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END                                    AS LineOfBusiness,
	|	CASE
	|		WHEN COUNT(DISTINCT OrdersToProcessor.Warehouse) = 1
	|			THEN MIN(OrdersToProcessor.Warehouse)
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END                                    AS Warehouse,
	|	CASE
	|		WHEN COUNT(DISTINCT OrdersToProcessor.Department) = 1
	|			THEN MIN(OrdersToProcessor.Department)
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END                                    AS Department,
	|	CASE
	|		WHEN COUNT(DISTINCT OrdersToProcessor.Currency) = 1
	|			THEN MIN(OrdersToProcessor.Currency)
	|		ELSE VALUE(Catalog.Currencies.EmptyRef)
	|	END                                    AS Currency,
	|	CASE
	|		WHEN COUNT(DISTINCT OrdersToProcessor.PriceIncludesVAT) = 1
	|			THEN MIN(OrdersToProcessor.PriceIncludesVAT)
	|		ELSE FALSE
	|	END                                    AS PriceIncludesVAT,
	|	CASE
	|		WHEN COUNT(DISTINCT OrdersToProcessor.SalesOpportunity) = 1
	|			THEN MIN(OrdersToProcessor.SalesOpportunity)
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END                                    AS SalesOpportunity,
	|	COUNT(DISTINCT OrdersToProcessor.LineOfBusiness) > 1 AS ErrorLineOfBusiness,
	|	COUNT(DISTINCT OrdersToProcessor.Warehouse) > 1                   AS WarehouseError,
	|	COUNT(DISTINCT OrdersToProcessor.Department) > 1           AS ErrorDivision,
	|	COUNT(DISTINCT OrdersToProcessor.Currency) > 1                  AS CurrencyError,
	|	COUNT(DISTINCT OrdersToProcessor.PriceIncludesVAT) > 1         AS ErrorPriceIncludesVAT,
	|	COUNT(DISTINCT OrdersToProcessor.SalesOpportunity) > 1                  AS ErrorSalesOpportunity,
	|	&Basis                               AS DocumentBasis
	|FROM
	|	OrdersToProcessor AS OrdersToProcessor
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfGoods.Products            AS Products,
	|	TableOfGoods.Characteristic          AS Characteristic,
	|	TableOfGoods.Series                   AS Series,
	|	TableOfGoods.CCDNumber                AS CCDNumber,
	|	VALUE(Catalog.Warehouses.EmptyRef)              AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef)          AS Purpose,
	|	VALUE(Document.SubcontractOrder2_5.EmptyRef) AS ReferenceOrder,
	|	0                                      AS RowCode,
	|	SUM(TableOfGoods.Count)       AS Count,
	|	SUM(TableOfGoods.QuantityByGBRN) AS QuantityByGBRN
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes.Products   AS Products,
	|		TableOfGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		TableOfGoods.ItemsLocationAttributes.Series          AS Series,
	|		TableOfGoods.CCDNumber                                  AS CCDNumber,
	|		TableOfGoods.Count                                AS Count,
	|		TableOfGoods.QuantityByGBRN                          AS QuantityByGBRN
	|	FROM
	|		Document.GoodsShipmentFromStorage.InventoryKinds AS TableOfGoods
	|	WHERE
	|		TableOfGoods.SalesOrder IN
	|			(SELECT
	|				GiverSOrders.MaterialProviderOrder AS SubcontractOrder
	|			FROM
	|				GiverSOrders AS GiverSOrders)
	|		AND TableOfGoods.Ref.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableOfGoods.Products      AS Products,
	|		TableOfGoods.Characteristic    AS Characteristic,
	|		TableOfGoods.Series             AS Series,
	|		TableOfGoods.CCDNumber          AS CCDNumber,
	|		-TableOfGoods.Count       AS Count,
	|		-TableOfGoods.QuantityByGBRN AS QuantityByGBRN
	|	FROM
	|		Document.ReceiptOfGoodsFromCustodian.Goods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Ref.Posted
	|		AND TableOfGoods.ReferenceOrder IN
	|			(SELECT
	|				OrdersToProcessor.SubcontractOrder
	|			FROM
	|				OrdersToProcessor AS OrdersToProcessor)
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.CCDNumber
	|
	|HAVING
	|	SUM(TableOfGoods.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	StockBalance.PurchaseOrder     AS SubcontractOrder,
	|	StockBalance.Products        AS Products,
	|	StockBalance.Characteristic      AS Characteristic,
	|	CASE
	|		WHEN OutputProductsOfOrder.Ref IS NOT NULL
	|			THEN OutputProductsOfOrder.Purpose
	|		WHEN ByProductsOfOrder.Ref IS NOT NULL
	|			THEN ByProductsOfOrder.Purpose
	|		WHEN OutputStageProducts.Ref IS NOT NULL
	|			THEN OutputStageProducts.Purpose
	|		ELSE StageByProducts.Purpose
	|	END                              AS Purpose,
	|	StockBalance.RowCode           AS RowCode,
	|	StockBalance.Warehouse               AS Warehouse,
	|	StockBalance.ToReceiveBalance AS Count
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(,
	|		PurchaseOrder IN
	|			(SELECT
	|				OrdersToProcessor.SubcontractOrder
	|			FROM
	|				OrdersToProcessor AS OrdersToProcessor)
	|	) AS StockBalance
	|	
	|	LEFT JOIN Document.SubcontractOrder2_5.ManufacturedProducts AS OutputProductsOfOrder
	|	ON OutputProductsOfOrder.Ref = StockBalance.PurchaseOrder
	|	AND OutputProductsOfOrder.RowCode = StockBalance.RowCode
	|	
	|	LEFT JOIN Document.SubcontractOrder2_5.SideAndIntermediateRelease AS ByProductsOfOrder
	|	ON ByProductsOfOrder.Ref = StockBalance.PurchaseOrder
	|	AND ByProductsOfOrder.RowCode = StockBalance.RowCode
	|	
	|	LEFT JOIN Document.ProductionStage2_2 AS Data_Stage
	|	ON Data_Stage.SubcontractOrder = StockBalance.PurchaseOrder
	|	
	|	LEFT JOIN Document.ProductionStage2_2.ManufacturedProducts AS OutputStageProducts
	|	ON OutputStageProducts.Ref = Data_Stage.Ref
	|	AND OutputStageProducts.RowCode = StockBalance.RowCode
	|	
	|	LEFT JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS StageByProducts
	|	ON StageByProducts.Ref = Data_Stage.Ref
	|	AND StageByProducts.RowCode = StockBalance.RowCode
	|	
	|	INNER JOIN Document.SubcontractOrder2_5 AS OrderData
	|	ON OrderData.Ref = StockBalance.PurchaseOrder
	|
	|	LEFT JOIN Catalog.Priorities AS CatPriorities
	|	ON CatPriorities.Ref = OrderData.Priority
	|
	|ORDER BY
	|	ISNULL(CatPriorities.AddlOrderingAttribute, 0)
	|";
	
	Return QueryText;
	
EndFunction

Function FillInQueryTextBasedOnTransferToGiverWithoutOrder()
	
	QueryText =
	"SELECT ALLOWED
	|	CatCompanies.Ref           AS Organization,
	|	CatCounterparties.Ref           AS Counterparty,
	|	CatCounterparties.Partner          AS Partner,
	|	CatContracts.Ref              AS Contract,
	|	CASE
	|		WHEN CatContracts.LineOfBusiness IS NULL
	|			THEN GoodsShipmentFromStorage.LineOfBusiness
	|		ELSE CatContracts.LineOfBusiness
	|	END                           AS LineOfBusiness,
	|	GoodsShipmentFromStorage.Currency AS Currency,
	|	FALSE                            AS PriceIncludesVAT,
	|	GoodsShipmentFromStorage.SalesOpportunity AS SalesOpportunity,
	|	GoodsShipmentFromStorage.Number  AS IncomingDocumentNumber,
	|	GoodsShipmentFromStorage.Date   AS IncomingDocumentDate,
	|	FALSE                            AS ErrorLineOfBusiness,
	|	FALSE                            AS WarehouseError,
	|	FALSE                            AS ErrorDivision,
	|	FALSE                            AS CurrencyError,
	|	FALSE                            AS ErrorPriceIncludesVAT,
	|	FALSE                            AS ErrorSalesOpportunity,
	|	GoodsShipmentFromStorage.Ref AS DocumentBasis
	|FROM
	|	Document.GoodsShipmentFromStorage AS GoodsShipmentFromStorage
	|	
	|	LEFT JOIN Catalog.Counterparties AS MaterialProvider
	|	ON MaterialProvider.Ref = GoodsShipmentFromStorage.Counterparty
	|	
	|	LEFT JOIN Catalog.Companies AS CatCompanies
	|	ON CatCompanies.TIN = MaterialProvider.TIN
	|	AND CatCompanies.CRTR = MaterialProvider.CRTR
	|	AND NOT CatCompanies.DeletionMark
	|	
	|	LEFT JOIN Catalog.Companies AS Toller
	|	ON Toller.Ref = GoodsShipmentFromStorage.Organization
	|	
	|	LEFT JOIN Catalog.Counterparties AS CatCounterparties
	|	ON CatCounterparties.TIN = Toller.TIN
	|	AND CatCounterparties.CRTR = Toller.CRTR
	|	AND NOT CatCounterparties.DeletionMark
	|	
	|	LEFT JOIN Catalog.CounterpartyContracts AS MaterialProviderContract
	|	ON MaterialProviderContract.Ref = GoodsShipmentFromStorage.Contract
	|
	|	LEFT JOIN Catalog.CounterpartyContracts AS CatContracts
	|	ON CatContracts.Organization = CatCompanies.Ref
	|	AND CatContracts.Counterparty = CatCounterparties.Ref
	|	AND CatContracts.Number = MaterialProviderContract.Number
	|	AND CatContracts.Date = MaterialProviderContract.Date
	|	AND CatContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND NOT CatContracts.DeletionMark
	|
	|WHERE
	|	GoodsShipmentFromStorage.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfGoods.ItemsLocationAttributes.Products   AS Products,
	|	TableOfGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes.Series          AS Series,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5)
	|			THEN TableOfGoods.CCDNumber
	|		ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|	END                                                    AS CCDNumber,
	|	VALUE(Catalog.Warehouses.EmptyRef)                 AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef)             AS Purpose,
	|	UNDEFINED                                             AS ReferenceOrder,
	|	0                                                        AS RowCode,
	|	SUM(TableOfGoods.Count)                         AS Count,
	|	SUM(CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5)
	|			THEN TableOfGoods.QuantityByGBRN
	|		ELSE 0
	|	END)                                                   AS QuantityByGBRN
	|FROM
	|	Document.GoodsShipmentFromStorage.InventoryKinds AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref = &Basis
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5)
	|			THEN TableOfGoods.CCDNumber
	|		ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	StockBalance.PurchaseOrder     AS SubcontractOrder,
	|	StockBalance.Products        AS Products,
	|	StockBalance.Characteristic      AS Characteristic,
	|	StockBalance.RowCode           AS RowCode,
	|	StockBalance.Warehouse               AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	StockBalance.ToReceiveBalance AS Count
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(, FALSE) AS StockBalance
	|";
	
	Return QueryText;
	
EndFunction

Procedure FillInSubcontractPurchaseOrderInGiverSGoods(GoodsTable, OrdersTable)
	
	If OrdersTable.Count() = 0 Then
		Return;
	EndIf;
	
	GoodsTable.Indexes.Add("Products, Characteristic, RowCode");
	
	For Each SubcontractPurchaseOrderLineForProcessor In OrdersTable Do
		
		QuantityOfSubcontractPurchaseOrderToProcessor = SubcontractPurchaseOrderLineForProcessor.Count;
		
		Filter =
			New Structure(
				"Products, Characteristic, RowCode",
				SubcontractPurchaseOrderLineForProcessor.Products,
				SubcontractPurchaseOrderLineForProcessor.Characteristic,
				0);
		
		For Each CurrentData In GoodsTable.FindRows(Filter) Do
			
			If CurrentData.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(QuantityOfSubcontractPurchaseOrderToProcessor, CurrentData.Count);
			
			NewRow = GoodsTable.Add();
			FillPropertyValues(NewRow, CurrentData);
			NewRow.ReferenceOrder = SubcontractPurchaseOrderLineForProcessor.SubcontractOrder;
			NewRow.RowCode    = SubcontractPurchaseOrderLineForProcessor.RowCode;
			NewRow.Warehouse        = SubcontractPurchaseOrderLineForProcessor.Warehouse;
			NewRow.Purpose   = SubcontractPurchaseOrderLineForProcessor.Purpose;
			NewRow.Count   = Count;
			
			CurrentData.Count = CurrentData.Count - Count;
			
			QuantityOfSubcontractPurchaseOrderToProcessor = QuantityOfSubcontractPurchaseOrderToProcessor - Count;
			
			If QuantityOfSubcontractPurchaseOrderToProcessor = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	GoodsTable.Indexes.Clear();
	
	Filter = New Structure("Count", 0);
	For Each CurrentData In GoodsTable.FindRows(Filter) Do
		GoodsTable.Delete(CurrentData);
	EndDo;
	
EndProcedure

#EndRegion

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
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(DocumentBaseWhenFillingIn(FillingData));
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Function DocumentBaseWhenFillingIn(FillingData)
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperation);
	TypesOfProducts_ = Handler.TypesOfProducts_();
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("AnArrayOfOrders")
		And FillingData.AnArrayOfOrders.Count() > 0
		And TypesOfProducts_.Find(TypeOf(FillingData.AnArrayOfOrders[0])) <> Undefined Then
		
		Return FillingData.AnArrayOfOrders[0];
		
	ElsIf TypesOfProducts_.Find(TypeOf(FillingData)) <> Undefined Then
		
		Return FillingData;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	If Cancel Then
		Return;
	EndIf;
	
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
		
		GroupColumns  = "ItemsLocationAttributes, ItemsLocationAttributesGoodsAtPartners, InventoryOwnerAttribute,
								|CCDNumber";
		TotalingColumns = "Count, QuantityByGBRN";
		
		InventoryKinds.GroupBy(GroupColumns, TotalingColumns);
		
		If Not Cancel Then
			FillInAdditionalStockTypeColumns();
			CheckFillingOfGTDVNumbersForInventoryTypes(Cancel);
			FillInInventoryTypeProductList();
		EndIf;
		
	EndIf;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Date, Organization, BusinessOperation, Partner, Contract, Warehouse";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text = 
	"////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	(SELECT
	|		TableOfGoods.BasicAnalytics	AS ItemsLocationAttributes,
	|		TableOfGoods.Products			AS Products,
	|		TableOfGoods.Characteristic		AS Characteristic,
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
	|		TableTypesOfStocks_.Products			AS Products,
	|		TableTypesOfStocks_.Characteristic		AS Characteristic,
	|		TableTypesOfStocks_.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|		TableTypesOfStocks_.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|		-TableTypesOfStocks_.Count			AS Count,
	|		-TableTypesOfStocks_.QuantityByGBRN	AS QuantityByGBRN,
	|		TableTypesOfStocks_.CCDNumber				AS CCDNumber
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.QuantityByGBRN) <> 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return Not Result_Query.IsEmpty();
	
EndFunction

Procedure FillInAdditionalStockTypeColumns()
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
		
		InventoryTypes = Common.ObjectsAttributeValue(InventoryKinds.UnloadColumn("InventoryOwnerAttribute"), "InventoryType");
		StructuresOfStockTypes = New Map;
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	Goods.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners
		|INTO TTProducts_1
		|FROM
		|	&Goods AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
		|	Goods.ItemsLocationAttributesGoodsAtPartners.Products.FinancialAccountingGroup AS FinancialAccountingGroup
		|FROM
		|	TTProducts_1 AS Goods
		|GROUP BY
		|	Goods.ItemsLocationAttributesGoodsAtPartners
		|";
		
		Query.SetParameter("Goods", Goods.Unload(, "ItemsLocationAttributesGoodsAtPartners"));
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			StockTypeStructure = Catalogs.InventoryKinds.StockTypeSelectionParameters();
			FillPropertyValues(StockTypeStructure, Selection);
			
			StructuresOfStockTypes.Insert(
				Selection.ItemsLocationAttributesGoodsAtPartners,
				StockTypeStructure);
				
		EndDo;
		
	EndIf;
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
			If BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
				And Not InventoryTypes[NewRow.InventoryOwnerAttribute] = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider
				And Not InventoryTypes[NewRow.InventoryOwnerAttribute] = Enums.InventoryTypes.ProductsOfMaterialProvider
				And Not InventoryTypes[NewRow.InventoryOwnerAttribute] = Enums.InventoryTypes.GoodsInStorageWithRightToSell Then
				NewRow.CorInventoryOwnerAttribute =
					Catalogs.InventoryKinds.DocumentInventoryView(
						Organization,
						BusinessOperation,
						StructuresOfStockTypes.Get(NewRow.ItemsLocationAttributesGoodsAtPartners));
			Else
				NewRow.CorInventoryOwnerAttribute = NewRow.InventoryOwnerAttribute;
			EndIf;
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
	
	FilterEmptyLines = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(FilterEmptyLines);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Function ParametersForFillingInventoryTypes()
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperation);
	
	Return Handler.ParametersForFillingInventoryTypes(ThisObject);

EndFunction

Procedure FillInInventoryTypeProductList()
	
	If ReturnOfSpoiledGoods Then
		
		TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
		
		RowFilter = New Structure("Damage", True);
		LinesOfSpoilage = Goods.FindRows(RowFilter);
		For Each RowOfGoods In LinesOfSpoilage Do
			
			GoodsQuantity = RowOfGoods.Count;
			
			FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
			
			SearchForStringsByKey = InventoryKinds.FindRows(TheStructureOfTheSearch);
			
			For Each OtherTypesOfStocks In SearchForStringsByKey Do
				
				If OtherTypesOfStocks.Count = 0 Then
					Continue;
				EndIf;
				
				Count = Min(GoodsQuantity, OtherTypesOfStocks.Count);
				
				NewRow = InventoryKinds.Add();
				FillPropertyValues(NewRow, OtherTypesOfStocks);
				
				NewRow.ProductsRecordingAsReceived = RowOfGoods.ProductsRecordingAsReceived;
				NewRow.CharacteristicRecordingAsReceived = RowOfGoods.CharacteristicRecordingAsReceived;
				NewRow.Count = Count;
				
				OtherTypesOfStocks.Count = OtherTypesOfStocks.Count - NewRow.Count;
				
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

Procedure CheckFillingOfGTDVNumbersForInventoryTypes(Cancel)
	
	If Not AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date)
		And Not GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers")
		Or BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
			And UserRightsCached.DisableProductTransferControlByTheSubcontractor()
		Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("InventoryKinds", InventoryKinds.Unload(, "ItemsLocationAttributes, CCDNumber, QuantityByGBRN"));
	Query.SetParameter("RestrictGoodsReceiptWithoutCCDNumbers", GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers"));
	Query.Text =
	"SELECT
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN
	|INTO TempTableTypesOfStocks
	|FROM
	|	&InventoryKinds AS InventoryKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	KeyTable_.Products AS Products,
	|	KeyTable_.Characteristic AS Characteristic,
	|	TempTableTypesOfStocks.CCDNumber AS CCDNumber,
	|	SUM(TempTableTypesOfStocks.QuantityByGBRN) AS QuantityByGBRN
	|INTO TableTypesOfStocks_
	|FROM
	|	TempTableTypesOfStocks
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS KeyTable_
	|		ON TempTableTypesOfStocks.ItemsLocationAttributes = KeyTable_.Ref
	|GROUP BY
	|	KeyTable_.Ref,
	|	KeyTable_.Products,
	|	KeyTable_.Characteristic,
	|	TempTableTypesOfStocks.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Products AS Products,
	|	Characteristic AS Characteristic
	|FROM
	|	TableTypesOfStocks_
	|WHERE
	|	CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND Products.KeepRecordsByCCD
	|	AND CASE
	|		WHEN &RestrictGoodsReceiptWithoutCCDNumbers
	|			THEN TRUE
	|		ELSE QuantityByGBRN > 0
	|	END";
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		MessageTemplate = NStr("vi = 'Không thể chọn số tờ khai hải quan cho hàng hóa ""%1""!';
								|ru = 'Не удалось подобрать номер ГТД для товара ""%1""!';
								|en = 'Cannot pick CCD number for the ""%1"" goods.'; fa = 'Cannot pick CCD number for the ""%1"" goods.';
								|it = 'Не удалось подобрать номер ГТД для товара ""%1""!';
								|pl = 'Cannot pick CCD number for the ""%1"" goods.';
								|tr = '""%1"" ürünü için GKB numarası seçilemedi!'");
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			MessageText = StrTemplate(
				MessageTemplate,
				ProductsClientServer.ProductPresentation(Selection.Products, Selection.Characteristic)
			);
			
			Common.MessageToUser(MessageText, Undefined, "", "Object", Cancel);
		
		EndDo;
		
	EndIf;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.ReceiptOfGoodsFromCustodian.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		
		DocumentTables = Documents.ReceiptOfGoodsFromCustodian.CollectionOfTabularPartsOfGoods();
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
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
	PlacesOfRegistrationWithPartners = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
		Contract,
		Department,
		Partner,
		Contract);
	
	FieldsNames.ItemsLocationAttributes = "ItemsLocationAttributesGoodsAtPartners";
	FieldsNames.BatchesIndicationStatus = "BatchesIndicationStatusOfGoodsTransferred";
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		FieldsNames.Purpose = "";
	Else
		FieldsNames.Purpose = "Purpose";
	EndIf;
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfRegistrationWithPartners, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInPricesBySalesConditions()
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5 Then
		Return;
	EndIf;
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

Function GetDocumentAmount() Export
	
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
	|	Goods AS Goods
	|WHERE
	|	Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	OR NOT &ToReturnReusablePackage";
	
	DocumentGoods = Goods.Unload(,"Products, Sum");
	
	Query.SetParameter("Goods",                    DocumentGoods);
	Query.SetParameter("ToReturnReusablePackage", ReusablePackageReturn);
	
	QueryResult = Query.Execute().Unload();
	TotalAmount__       = QueryResult[0].Sum;
	
	Return TotalAmount__;
	
EndFunction

Procedure ClearDataOnImportedGoodsForProcessingOperations()
	
	If Not (BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5
		Or BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5) Then
		
		Return;
		
	EndIf;
	
	For Each RowOfGoods In Goods Do
		If ValueIsFilled(RowOfGoods.CCDNumber) Then
			RowOfGoods.CCDNumber = Undefined;
		EndIf;
		If RowOfGoods.QuantityByGBRN <> 0 Then
			RowOfGoods.QuantityByGBRN = 0;
		EndIf;
	EndDo;
	
EndProcedure
#EndRegion

#EndRegion

#EndIf
#EndIf
