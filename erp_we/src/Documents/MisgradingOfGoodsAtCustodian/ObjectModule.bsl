#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the terms of sale in the document for debiting goods from the custodian.
//
// Parameters:
//	SalesTermsAndConditions - Structure - data to fill in.
//
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	LineOfBusiness = SalesTermsAndConditions.LineOfBusiness;
	
	If SalesTermsAndConditions.Organization <> Organization
		And ValueIsFilled(SalesTermsAndConditions.Organization) Then
		
		Organization = SalesTermsAndConditions.Organization;
		
	EndIf;
	
	If Not SalesTermsAndConditions.Standard_ Then
		
		If ValueIsFilled(SalesTermsAndConditions.Counterparty)
			And SalesTermsAndConditions.Counterparty <> Counterparty Then
			
			Counterparty = SalesTermsAndConditions.Counterparty;
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.PricesKind) Then
		PriceKind = SalesTermsAndConditions.PricesKind;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	Handler = Documents.MisgradingOfGoodsAtCustodian.ActionHandler(BusinessOperation);
	Contract = Handler.GetDefaultContract(ThisObject);
	ContractDetails_ = New Structure("Currency, LineOfBusiness, Department", "ARAPCurrency");
	Catalogs.CounterpartyContracts.FillInDocumentDetails(ThisObject, Contract, ContractDetails_);
	
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
	EndIf;
	
EndProcedure

// Fills in the default sales terms in the product debiting document from the custodian.
//
Procedure FillInDefaultSalesConditions() Export
	
	Handler = Documents.MisgradingOfGoodsAtCustodian.ActionHandler(BusinessOperation);
	ToUseTermsOfSales = Handler.ToUseTermsOfSales();
	
	If ValueIsFilled(Partner)
		Or Not ToUseTermsOfSales Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.MisgradingOfGoodsAtCustodian.EmptyRef());
		FilterParameters.Insert("BusinessTransactions", Handler.ContractBusinessTransaction());
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
										Partner, FilterParameters, Handler.CustomerAgreementsAreApplicable());
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales
				Or (Terms <> DefaultSalesTerms.Terms
					And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				
				FillIn_TermsOfSales(DefaultSalesTerms);
				
			Else
				Terms = DefaultSalesTerms.Terms;
				
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
				
				Contract = Handler.GetDefaultContract(ThisObject);
			EndIf;
			
		Else
			Terms = Undefined;
			
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the terms of sales under the agreement in the document for debiting goods from the custodian.
//
Procedure FillInTermsOfSalesUnderAgreement() Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms);
	
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
EndProcedure

#Region ProductAccountingAnalysts

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
//
Procedure FillInProductTrackingForm() Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
EndProcedure

// The procedure creates a temporary table of products with separate accounting Analytics.
//
// Parameters:
//	TempTablesManager - TempTablesManager - temporary table Manager
//								that will contain the created table.
//
Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes                  AS ItemsLocationAttributes,
	|	DocumentDataTable.Partner                             AS Partner,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)  AS Terms,
	|	TableOfGoods.Products                                AS Products,
	|	TableOfGoods.Characteristic                              AS Characteristic,
	|	TableOfGoods.Purpose                                  AS Purpose,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus = 18
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                                                      AS Series,
	|	TableOfGoods.Count                                  AS Count,
	|	DocumentDataTable.Contract                             AS Warehouse,
	|	DocumentDataTable.Manager                            AS Manager,
	|	DocumentDataTable.SalesOpportunity                              AS SalesOpportunity,
	|	DocumentDataTable.Department                       AS Department,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|WHERE
	|	TableOfGoods.Products.ItemsType IN (
	|									VALUE(Enum.ItemsTypes.OwnGoods),
	|									VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|";
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.Execute();
	
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
	|	&Date                                                      AS Date,
	|	&Partner                                                   AS Partner,
	|	&Counterparty                                                AS Counterparty,
	|	&Terms                                                AS Terms,
	|	&BusinessOperation                                     AS BusinessOperation,
	|	&Organization                                               AS Organization,
	|	&Contract                                                   AS Contract,
	|	&Currency                                                    AS Currency,
	|	CASE
	|		WHEN CAST(&Department AS Catalog.BusinessStructure).OptionOfAssignedAccountingOfGoods =
	|								VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|				THEN &EmployeeResponsible
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END                                                      AS Manager,
	|	CASE
	|		WHEN CAST(&SalesOpportunity AS Catalog.SalesOpportunitiesToCustomer).EnabledGoodsAssignmentInSalesOpportunity
	|			AND &GenerateInventoryOwnerAttributesBySalesOpportunities
	|				THEN &SalesOpportunity
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END                                                      AS SalesOpportunity,
	|	CASE
	|		WHEN CAST(&Department AS Catalog.BusinessStructure).OptionOfAssignedAccountingOfGoods =
	|								VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|				THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END                                                      AS Department,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	&InventoryType                                                AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	TableOfGoods.LineNumber                             AS LineNumber,
	|	TableOfGoods.Products                            AS Products,
	|	TableOfGoods.Characteristic                          AS Characteristic,
	|	TableOfGoods.Purpose                              AS Purpose,
	|	TableOfGoods.Series                                   AS Series,
	|	TableOfGoods.BatchesIndicationStatus                     AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes              AS ItemsLocationAttributes,
	|	TableOfGoods.ProductsRecordingAsReceived               AS ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived             AS CharacteristicRecordingAsReceived,
	|	TableOfGoods.AssignmentGoodsReceipt                 AS AssignmentGoodsReceipt,
	|	TableOfGoods.BatchReceipt                      AS BatchReceipt,
	|	TableOfGoods.BatchesIndicationStatusReceipt        AS BatchesIndicationStatusReceipt,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	&FieldTextTableOfGoodsCCDNumberWriteOff_              AS CCDNumber,
	|	TableOfGoods.Count                              AS Count,
	|	0                                                      AS QuantityByGBRN,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END                                                  AS QuantityByRNPTReceipt,
	|	TableOfGoods.Price                                    AS Price,
	|	TableOfGoods.PriceOffBalance                            AS PriceOffBalance
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	TableOfGoods.LineNumber                             AS LineNumber,
	|	TableOfGoods.Products                            AS Products,
	|	TableOfGoods.Characteristic                          AS Characteristic,
	|	TableOfGoods.Purpose                              AS Purpose,
	|	TableOfGoods.Series                                   AS Series,
	|	TableOfGoods.BatchesIndicationStatus                     AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes              AS ItemsLocationAttributes,
	|	TableOfGoods.ProductsRecordingAsReceived               AS ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived             AS CharacteristicRecordingAsReceived,
	|	TableOfGoods.AssignmentGoodsReceipt                 AS AssignmentGoodsReceipt,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableOfGoods.CCDNumber                                AS CCDNumber,
	|	&Contract                                               AS Warehouse,
	|	&SalesOpportunity                                                AS SalesOpportunity,
	|	TableOfGoods.Count                              AS Count,
	|	TableOfGoods.QuantityByGBRN                        AS QuantityByGBRN,
	|	TableOfGoods.QuantityByRNPTReceipt           AS QuantityByRNPTReceipt,
	|	TableOfGoods.Price                                    AS Price,
	|	TableOfGoods.PriceOffBalance                            AS PriceOffBalance,
	|	VALUE(Catalog.VATRates.EmptyRef)            AS VATRate,
	|	0                                                      AS AmountIncludingVAT,
	|	0                                                      AS VATAmount,
	|	0                                                      AS CommissionAmount,
	|	0                                                      AS AmountVATRemuneration,
	|	TRUE                                                 AS SelectTypesOfStocks
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	TableTypesOfStocks_.LineNumber                             AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes              AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                              AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt                 AS InventoryOwnerAttributeGoodsReceipt,
	|	TableTypesOfStocks_.CCDNumber                                AS CCDNumber,
	|	TableTypesOfStocks_.Count                              AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END                                                      AS QuantityByGBRN,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByRNPTReceipt
	|	END                                                      AS QuantityByRNPTReceipt,
	|	TableTypesOfStocks_.Sum                                   AS Sum,
	|	TableTypesOfStocks_.AmountOffBalance                           AS AmountOffBalance,
	|	&InventoryOwnerAttributesAreSpecifiedManually                                 AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	TableTypesOfStocks_.LineNumber                             AS LineNumber,
	|	Dimension.Products                                     AS Products,
	|	Dimension.Characteristic                                   AS Characteristic,
	|	Dimension.Series                                            AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                              AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes              AS ItemsLocationAttributes,
	|	DimensionRecordingAsReceived.Products                        AS ProductsRecordingAsReceived,
	|	DimensionRecordingAsReceived.Characteristic                      AS CharacteristicRecordingAsReceived,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt                 AS InventoryOwnerAttributeGoodsReceipt,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	Dimension.StorageLocation                                    AS Warehouse,
	|	VALUE(Catalog.Warehouses.EmptyRef)                   AS OriginWarehouse,
	|	TableTypesOfStocks_.CCDNumber                                AS CCDNumber,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)         AS SalesOpportunity,
	|	TableTypesOfStocks_.Count                              AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN                        AS QuantityByGBRN,
	|	TableTypesOfStocks_.QuantityByRNPTReceipt           AS QuantityByRNPTReceipt,
	|	TableTypesOfStocks_.Sum                                   AS Sum,
	|	TableTypesOfStocks_.AmountOffBalance                           AS AmountOffBalance,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually               AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionRecordingAsReceived
	|		ON TableTypesOfStocks_.ItemsLocationAttributesReceipt = DimensionRecordingAsReceived.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|";
	
	Query.TempTablesManager = New TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	Query.SetParameter("Ref",                    Ref);
	Query.SetParameter("Date",                      Date);
	Query.SetParameter("Partner",                   Partner);
	Query.SetParameter("Counterparty",                Counterparty);
	Query.SetParameter("Terms",                Terms);
	Query.SetParameter("BusinessOperation",     BusinessOperation);
	Query.SetParameter("Organization",               Organization);
	Query.SetParameter("Department",             Department);
	Query.SetParameter("Contract",                   Contract);
	Query.SetParameter("Currency",                    Currency);
	Query.SetParameter("InventoryType",                Enums.InventoryTypes.OwnGoods);
	Query.SetParameter("SalesOpportunity",                    SalesOpportunity);
	Query.SetParameter("EmployeeResponsible",             EmployeeResponsible);
	Query.SetParameter("Posted",                  Posted);
	Query.SetParameter("TableOfGoods",            TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",        InventoryKinds);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter(
					"GenerateInventoryOwnerAttributesBySalesOpportunities",
					GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter(
					"GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers",
					GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	
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
	
	Return Query.TempTablesManager;
	
EndFunction

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

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part
// The 'Discrepancies' of the document, and also fills in the tabular part of the 'Types of reserves'.
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.MisgradingOfGoodsAtCustodian.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables = Undefined) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	If DocumentTables <> Undefined Then
		FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables);
		AdditionalProperties.Insert("TablesOfFillingOfTypesOfStocksAtExchange", DocumentTables);
	EndIf;
	
	FillStockTypes(Cancel);
	AdditionalProperties.Delete("TablesOfFillingOfTypesOfStocksAtExchange");
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.FieldNamesWithSuffix.Insert("Products", "ProductsRecordingAsReceived");
	CheckParameters.FieldNamesWithSuffix.Insert("Characteristic", "CharacteristicRecordingAsReceived");
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MisgradingOfGoodsAtCustodian);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	CheckCompletionOfAppointments(Cancel);
	For Each StringTSGoods In Goods Do
		
		If ValueIsFilled(StringTSGoods.Products)
		   And StringTSGoods.Products   = StringTSGoods.ProductsRecordingAsReceived
		   And StringTSGoods.Characteristic = StringTSGoods.CharacteristicRecordingAsReceived
		   And StringTSGoods.Series          = StringTSGoods.BatchReceipt
		   And StringTSGoods.Purpose     = StringTSGoods.AssignmentGoodsReceipt Then
			
			Field = CommonClientServer.PathToTabularSection(
													"Goods",
													StringTSGoods.LineNumber,
													"LineNumber");
		
			ErrorText = StrTemplate(
							NStr("vi = 'Hàng hóa được ghi giảm trùng với hàng hóa được ghi tăng trong dòng %1 của danh sách ""Hàng hóa""';
								|ru = 'Списываемый товар совпадает с приходуемым в строке %1 списка ""Товары""';
								|en = 'Written-off goods and received goods in the %1 line of the ""Goods"" list are the same'; fa = 'Written-off goods and received goods in the %1 line of the ""Goods"" list are the same';
								|it = 'Articolo stornabile corrisponde a quello da ricevere nella riga %1 dell''elenco ""Articoli""';
								|pl = 'Rozchodowany towar jest zgodny z rejestrowanym w wierszu %1 listy ""Towary""';
								|tr = 'Silinecek ürünler, ""Ürünler"" listesinin %1 satırındaki alınacak ürünlerle aynıdır'"),
							StringTSGoods.LineNumber);
		
			Common.MessageToUser(ErrorText, ThisObject, Field,, Cancel);
		
		EndIf;
		
	EndDo;
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods,
																								Date,
																								"ProductsRecordingAsReceived");
	
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	If ThisIsTraceableDocument
		Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers") Then
		
		CheckParameters = InventoriesServer.ParametersForCheckingFillingInOfCCDNumbers();
		CheckParameters.NameOfProductsField = "ProductsRecordingAsReceived";
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel, CheckParameters);
		
	EndIf;
	
	If ThisIsTraceableDocument Then
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject,
																						Goods,
																						Date,
																						"Goods",
																						"ProductsRecordingAsReceived");
	EndIf;
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;
		
	Handler = Documents.MisgradingOfGoodsAtCustodian.ActionHandler(BusinessOperation);
	If Not Handler.ToUseTermsOfSales() Then
		NotCheckedAttributeArray.Add("Terms");
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	PartnersAndCounterparties.CheckPartnerContent(ThisObject, NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters =
		Documents.MisgradingOfGoodsAtCustodian.ItemsAndDimensionsSelectionParameters(
			ReceiveGoodsAtCostTheyWereIssuedFromWarehouse,
			True);
	
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes,
		ItemsAndDimensionsSelectionParameters);
	
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		
		Cancel = True;
		
	EndIf;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	MisgradingOfGoodsAtCustodianLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsMisgrading") Then
		FillInBasedOnReSortingOfGiverSGoods(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.MisgradingOfGoodsAtCustodian") Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	EndIf;
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.MisgradingOfGoodsAtCustodian.ItemsAndDimensionsSelectionParameters(ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument();
	
	RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
							ThisObject,
							"Contract");
	
	FieldNamesWithSuffix = RecalculationParameters.FieldNamesWithSuffix;
	FieldNamesWithSuffix.Insert("Products",	"ProductsRecordingAsReceived");
	FieldNamesWithSuffix.Insert("Characteristic",	"CharacteristicRecordingAsReceived");
	
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	MisgradingOfGoodsAtCustodianLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TotalAmountOfDocument = 0;
	If ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		For Each StringTSGoods In Goods Do
			If StringTSGoods.Price <> 0 Then
				StringTSGoods.Price = 0;
			EndIf;
			If StringTSGoods.PriceOffBalance <> 0 Then
				StringTSGoods.PriceOffBalance = 0;
			EndIf;
		EndDo;
	Else
		For Each StringTSGoods In Goods Do
			TotalAmountOfDocument =
				TotalAmountOfDocument
				+ StringTSGoods.Count * StringTSGoods.Price
				+ StringTSGoods.Count * StringTSGoods.PriceOffBalance;
		EndDo;
	EndIf;
	
	DocumentAmount = TotalAmountOfDocument;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MisgradingOfGoodsAtCustodian);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	If IsNew()
		And Not ValueIsFilled(Number) Then
		
		SetNewNumber();
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.MisgradingOfGoodsAtCustodian.ItemsAndDimensionsSelectionParameters(ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not ValueIsFilled(Author)
		And IsNew() Then
		
		Author = Users.CurrentUser();
		
	EndIf;
	
	MisgradingOfGoodsAtCustodianLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	MisgradingOfGoodsAtCustodianLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	MisgradingOfGoodsAtCustodianLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	MisgradingOfGoodsAtCustodianLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InventoryKinds.Clear();
	Basis = Undefined;
	
	InitializeDocument();
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "InventoryKinds");
	
	MisgradingOfGoodsAtCustodianLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument()
	
	Author = Users.CurrentUser();
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	If ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		If ValueIsFilled(PriceKind) Then
			PriceKind = Undefined;
		EndIf;
	ElsIf Not ValueIsFilled(PriceKind) Then
		PriceKind = Catalogs.TypesOfPrices.DefaultPriceType(PriceKind);
	EndIf;
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
EndProcedure

#Region FillingInByReSortingGiverSGoods

Procedure FillInBasedOnReSortingOfGiverSGoods(FillingStructure)
	
	BusinessOperation = Enums.BusinessTransactions.MisgradingOfGoodsAtToller;
	
	Query = New Query;
	Query.SetParameter("Basis", FillingStructure);
	Query.Text = QueryTextFillInBasedOnReSortingOfGiverSGoods();
	
	Result = Query.ExecuteBatch();
	HeaderAttributes = Result[Result.UBound() - 1].Select();
	GoodsTable  = Result[Result.UBound()].Unload();
	
	If HeaderAttributes.Next() Then
		
		FillingErrors = New Array;
		ErrorTemplate = NStr("vi = 'Không thể nhập trên cơ sở chuyển tồn hàng hóa. Theo dạng vật tư có các ""%1"" khác nhau.';
							|ru = 'Ввод на основании пересортицы товаров невозможен. В видах запасов присутствуют разные ""%1"".';
							|en = 'Cannot generate documents based on the stock reclass. Inventory owner attributes contain different %1.'; fa = 'Cannot generate documents based on the stock reclass. Inventory owner attributes contain different %1.';
							|it = 'Ввод на основании пересортицы товаров невозможен. В видах запасов присутствуют разные ""%1"".';
							|pl = 'Cannot generate documents based on the stock reclass. Inventory owner attributes contain different %1.';
							|tr = 'Stok yeniden sınıflandırılması temelinde giriş mümkün değildir. Stok türlerinde farklı ""%1"" bulunmaktadır.'");
		
		If HeaderAttributes.ErrorCounterparty Then
			FillingErrors.Add(NStr("vi = 'Đối tác';
									|ru = 'Контрагенты';
									|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
									|it = 'Контрагенты';
									|pl = 'Counterparties';
									|tr = 'Cari hesaplar'"));
		EndIf;
		
		If HeaderAttributes.ErrorContract Then
			FillingErrors.Add(NStr("vi = 'Hợp đồng';
									|ru = 'Договоры';
									|en = 'Contracts'; fa = 'قراردادها';
									|it = 'Договоры';
									|pl = 'Contracts';
									|tr = 'Sözleşmeler'"));
		EndIf;
		
		If Not FillingErrors.Count() = 0 Then
			ErrorText = StrTemplate(ErrorTemplate, StrConcat(FillingErrors, ", "));
			Raise ErrorText;
		EndIf;
		
		FillPropertyValues(ThisObject, HeaderAttributes);
		
	EndIf;
	
	Goods.Load(GoodsTable);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MisgradingOfGoodsAtCustodian));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Function QueryTextFillInBasedOnReSortingOfGiverSGoods()
	
	QueryText =
	"SELECT ALLOWED
	|	TableOfGoods.InventoryOwnerAttribute.Counterparty                     AS MaterialProvider,
	|	TableOfGoods.InventoryOwnerAttribute.Contract                        AS MaterialProviderContract,
	|	TableOfGoods.ItemsLocationAttributes.Products   AS Products,
	|	TableOfGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes.Series          AS Series,
	|	TableOfGoods.ItemsLocationAttributesReceipt.Products   AS ProductsRecordingAsReceived,
	|	TableOfGoods.ItemsLocationAttributesReceipt.Characteristic AS CharacteristicRecordingAsReceived,
	|	TableOfGoods.ItemsLocationAttributesReceipt.Series          AS BatchReceipt,
	|	TableOfGoods.CCDNumber                AS CCDNumber,
	|	SUM(TableOfGoods.Count)       AS Count,
	|	SUM(TableOfGoods.QuantityByGBRN) AS QuantityByGBRN
	|INTO ResortableGoods
	|FROM
	|	Document.GoodsMisgrading.InventoryKinds AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref = &Basis
	|	AND TableOfGoods.InventoryOwnerAttribute.InventoryType IN(
	|		VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|
	|GROUP BY
	|	TableOfGoods.InventoryOwnerAttribute,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesReceipt,
	|	TableOfGoods.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ResortableGoods.MaterialProvider     AS MaterialProvider,
	|	ResortableGoods.MaterialProvider.TIN AS TIN,
	|	ResortableGoods.MaterialProvider.CRTR AS CRTR
	|INTO Givers
	|FROM
	|	ResortableGoods AS ResortableGoods
	|
	|WHERE
	|	NOT ResortableGoods.MaterialProvider.DeletionMark
	|
	|GROUP BY
	|	ResortableGoods.MaterialProvider,
	|	ResortableGoods.MaterialProvider.TIN,
	|	ResortableGoods.MaterialProvider.CRTR
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ResortableGoods.MaterialProviderContract       AS MaterialProviderContract,
	|	ResortableGoods.MaterialProviderContract.Number AS Number,
	|	ResortableGoods.MaterialProviderContract.Date  AS Date
	|INTO GiverSContracts
	|FROM
	|	ResortableGoods AS ResortableGoods
	|
	|WHERE
	|	NOT ResortableGoods.MaterialProviderContract.DeletionMark
	|	AND ResortableGoods.MaterialProviderContract.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|
	|GROUP BY
	|	ResortableGoods.MaterialProviderContract,
	|	ResortableGoods.MaterialProviderContract.Number,
	|	ResortableGoods.MaterialProviderContract.Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MIN(CatCompanies.Ref)     AS Organization,
	|	MIN(CatCounterparties.Ref)     AS Counterparty,
	|	MIN(CatCounterparties.Partner)    AS Partner,
	|	MIN(CatContracts.Ref)        AS Contract,
	|	MIN(CASE
	|		WHEN CatContracts.LineOfBusiness IS NULL
	|			THEN GoodsMisgrading.LineOfBusiness
	|		ELSE CatContracts.LineOfBusiness
	|	END)                             AS LineOfBusiness,
	|	MIN(GoodsMisgrading.Currency) AS Currency,
	|	MIN(GoodsMisgrading.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse) AS ReceiveGoodsAtCostTheyWereIssuedFromWarehouse,
	|	COUNT(DISTINCT Givers.MaterialProvider) > 1                 AS ErrorCounterparty,
	|	COUNT(DISTINCT GiverSContracts.MaterialProviderContract) > 1 AS ErrorContract,
	|	MIN(GoodsMisgrading.Ref) AS Basis
	|FROM
	|	Document.GoodsMisgrading AS GoodsMisgrading
	|	
	|	LEFT JOIN Givers AS Givers
	|	ON TRUE
	|	
	|	LEFT JOIN Catalog.Companies AS CatCompanies
	|	ON CatCompanies.TIN = Givers.TIN
	|	AND CatCompanies.CRTR = Givers.CRTR
	|	AND NOT CatCompanies.DeletionMark
	|	
	|	LEFT JOIN Catalog.Companies AS Toller
	|	ON Toller.Ref = GoodsMisgrading.Organization
	|	
	|	LEFT JOIN Catalog.Counterparties AS CatCounterparties
	|	ON CatCounterparties.TIN = Toller.TIN
	|	AND CatCounterparties.CRTR = Toller.CRTR
	|	AND NOT CatCounterparties.DeletionMark
	|	
	|	LEFT JOIN GiverSContracts AS GiverSContracts
	|	ON TRUE
	|
	|	LEFT JOIN Catalog.CounterpartyContracts AS CatContracts
	|	ON CatContracts.Organization = CatCompanies.Ref
	|	AND CatContracts.Counterparty = CatCounterparties.Ref
	|	AND CatContracts.Number = GiverSContracts.Number
	|	AND CatContracts.Date = GiverSContracts.Date
	|	AND CatContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND NOT CatContracts.DeletionMark
	|
	|WHERE
	|	GoodsMisgrading.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ResortableGoods.Products                AS Products,
	|	ResortableGoods.Characteristic              AS Characteristic,
	|	ResortableGoods.Series                       AS Series,
	|	ResortableGoods.ProductsRecordingAsReceived   AS ProductsRecordingAsReceived,
	|	ResortableGoods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	ResortableGoods.BatchReceipt          AS BatchReceipt,
	|	ResortableGoods.CCDNumber                    AS CCDNumber,
	|	ResortableGoods.Count                  AS Count,
	|	ResortableGoods.QuantityByGBRN            AS QuantityByGBRN
	|FROM
	|	ResortableGoods AS ResortableGoods
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region ProductAccountingAnalysts

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.MisgradingOfGoodsAtCustodian.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.MisgradingOfGoodsAtCustodian.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Contract,
																		Department,
																		Partner,
																		Contract);
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.ItemsLocationAttributes = "ItemsLocationAttributesReceipt";
	FieldsNames.Products               = "ProductsRecordingAsReceived";
	FieldsNames.Characteristic             = "CharacteristicRecordingAsReceived";
	FieldsNames.Purpose                 = "AssignmentGoodsReceipt";
	FieldsNames.Series                      = "BatchReceipt";
	FieldsNames.BatchesIndicationStatus        = "BatchesIndicationStatusReceipt";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region InventoryKinds

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
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber", "Count, QuantityByGBRN");
		
		FillInInventoryTypeProductList(Cancel);
		
	EndIf;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

Procedure FillInInventoryTypeProductList(Cancel)
	
	InventoryTypes = InventoryKinds.UnloadColumn("InventoryOwnerAttribute");
	InventoryTypes = Common.ObjectsAttributeValue(InventoryTypes, "InventoryType");
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In Goods Do
		
		GoodsQuantity = RowOfGoods.Count;
		QuantityOfGoodsAccordingToRPT = RowOfGoods.QuantityByGBRN;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.ItemsLocationAttributesReceipt = RowOfGoods.ItemsLocationAttributesReceipt;
			NewRow.CCDNumberRegistration					= RowOfGoods.CCDNumber;
			NewRow.InventoryOwnerAttributeGoodsReceipt					= InventoryLine.InventoryOwnerAttribute;
			
			NewRow.Sum =
				?(Not ReceiveGoodsAtCostTheyWereIssuedFromWarehouse,
					Count * RowOfGoods.Price,
					0);
			
			NewRow.AmountOffBalance =
				?(Not ReceiveGoodsAtCostTheyWereIssuedFromWarehouse,
					Count * RowOfGoods.PriceOffBalance,
					0);
			
			NewRow.Count								= Count;
			NewRow.QuantityByGBRN						= Count * InventoryLine.QuantityByGBRN
																	/ InventoryLine.Count;
			NewRow.QuantityByRNPTReceipt			= Count * RowOfGoods.QuantityByGBRN
																	/ RowOfGoods.Count;
			
			InventoryLine.Count = InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN = InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			QuantityOfGoodsAccordingToRPT = QuantityOfGoodsAccordingToRPT - NewRow.QuantityByRNPTReceipt;
			
			// Checking the filling of prices is performed after selecting the types of stocks, as it depends on the selected type of stocks.
			If Not ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
				
				ErrorText= "";
				CurStockType = InventoryTypes.Get(NewRow.InventoryOwnerAttribute);
				
				If Not ValueIsFilled(NewRow.AmountOffBalance)
					And Not ValueIsFilled(NewRow.Sum)
					And (CurStockType = Enums.InventoryTypes.GoodsInStorageWithRightToSell
						Or CurStockType = Enums.InventoryTypes.MaterialOfMaterialProvider
						Or CurStockType = Enums.InventoryTypes.ProductsOfMaterialProvider
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
					And (CurStockType = Enums.InventoryTypes.GoodsInStorageWithRightToSell
						Or CurStockType = Enums.InventoryTypes.MaterialOfMaterialProvider
						Or CurStockType = Enums.InventoryTypes.ProductsOfMaterialProvider
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
				If CurStockType = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider
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
					And Not CurStockType = Enums.InventoryTypes.MaterialOfMaterialProvider
					And Not CurStockType = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider
					And Not CurStockType = Enums.InventoryTypes.ProductsOfMaterialProvider
					And Not CurStockType = Enums.InventoryTypes.GoodsInStorageWithRightToSell Then
					
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
					And Not CurStockType = Enums.InventoryTypes.MaterialOfMaterialProvider
					And Not CurStockType = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider
					And Not CurStockType = Enums.InventoryTypes.ProductsOfMaterialProvider
					And Not CurStockType = Enums.InventoryTypes.GoodsInStorageWithRightToSell Then
					
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
					NewRow.QuantityByRNPTReceipt = NewRow.QuantityByRNPTReceipt
																+ QuantityOfGoodsAccordingToRPT;
				EndIf;
				
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(New Structure("Count", 0));
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Date, Organization, BusinessOperation, Partner, Contract";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes              AS ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableOfGoods.ProductsRecordingAsReceived               AS ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived             AS CharacteristicRecordingAsReceived
	|FROM 
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes              AS ItemsLocationAttributes,
	|		TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|		TableOfGoods.ProductsRecordingAsReceived               AS ProductsRecordingAsReceived,
	|		TableOfGoods.CharacteristicRecordingAsReceived             AS CharacteristicRecordingAsReceived,
	|		TableOfGoods.Count                              AS Count,
	|		TableOfGoods.QuantityByRNPTReceipt           AS QuantityByGBRN,
	|		CAST(TableOfGoods.Count * TableOfGoods.Price AS NUMBER(31, 2)) AS Sum,
	|		CAST(TableOfGoods.Count * TableOfGoods.PriceOffBalance AS NUMBER(31, 2)) AS AmountOffBalance
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes              AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|		TableTypesOfStocks_.ProductsRecordingAsReceived               AS ProductsRecordingAsReceived,
	|		TableTypesOfStocks_.CharacteristicRecordingAsReceived             AS CharacteristicRecordingAsReceived,
	|		-TableTypesOfStocks_.Count                             AS Count,
	|		-TableTypesOfStocks_.QuantityByRNPTReceipt          AS QuantityByGBRN,
	|		-TableTypesOfStocks_.Sum                                  AS Sum,
	|		-TableTypesOfStocks_.AmountOffBalance                          AS AmountOffBalance
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesReceipt,
	|	TableOfGoods.ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.QuantityByGBRN) <> 0
	|	OR SUM(TableOfGoods.Sum) <> 0
	|	OR SUM(TableOfGoods.AmountOffBalance) <> 0
	|";
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return Not Result_Query.IsEmpty();
	
EndFunction

Function ParametersForFillingInventoryTypes()
	
	Handler = Documents.MisgradingOfGoodsAtCustodian.ActionHandler(BusinessOperation);
	
	Return Handler.ParametersForFillingInventoryTypes(ReversedDocument);
	
EndFunction

#EndRegion
#Region FillInChecks

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
			|tr = '""Ürünler"" listesinin %1satırında, stok fazlası ürünler, iş ortağının/sözleşmenin orijinalinden farklı olmadığı durumlarda, sağlayıcının atamasına uyarlanmalıdır.'"));
	
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

#EndRegion
#EndRegion

#EndIf
