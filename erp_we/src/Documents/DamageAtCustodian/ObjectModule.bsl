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
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	Handler = Documents.DamageAtCustodian.ActionHandler(BusinessOperation);
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
	
	Handler = Documents.DamageAtCustodian.ActionHandler(BusinessOperation);
	ToUseTermsOfSales = Handler.ToUseTermsOfSales();
	
	If ValueIsFilled(Partner)
		Or Not ToUseTermsOfSales Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.DamageAtCustodian.EmptyRef());
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

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.ReversingEntry, DocumentObject.DamageAtCustodian - the document is reversed or the document being reversed.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes());
	
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
	|	TableOfGoods.ProductsRecordingAsReceived               AS ProductsRecordingAsReceived,
	|	TableOfGoods.Characteristic                          AS Characteristic,
	|	TableOfGoods.CharacteristicRecordingAsReceived             AS CharacteristicRecordingAsReceived,
	|	TableOfGoods.ItemsLocationAttributes              AS ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableOfGoods.Purpose                              AS Purpose,
	|	TableOfGoods.ForAssignment                           AS ForAssignment,
	|	TableOfGoods.Series                                   AS Series,
	|	TableOfGoods.BatchesIndicationStatus                     AS BatchesIndicationStatus,
	|	TableOfGoods.Count                              AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END                                                  AS QuantityByGBRN,
	|	TableOfGoods.Price                                    AS Price,
	|	TableOfGoods.PriceOffBalance                            AS PriceOffBalance,
	|	&FieldTextTableOfGoodsCCDNumber_                      AS CCDNumber
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
	|	TableOfGoods.ForAssignment                           AS ForAssignment,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableOfGoods.CCDNumber                                AS CCDNumber,
	|	&Contract                                               AS Warehouse,
	|	&SalesOpportunity                                                AS SalesOpportunity,
	|	TableOfGoods.Count                              AS Count,
	|	TableOfGoods.QuantityByGBRN                        AS QuantityByGBRN,
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
	
	Return Query.TempTablesManager;
	
EndFunction

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

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.DamageAtCustodian.CollectionOfTabularPartsOfGoods.
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

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.FieldNamesWithSuffix.Insert("Products", "ProductsRecordingAsReceived");
	CheckParameters.FieldNamesWithSuffix.Insert("Characteristic", "CharacteristicRecordingAsReceived");
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DamageAtCustodian);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	
	For Each StringTSGoods In Goods Do
		
		If ValueIsFilled(StringTSGoods.Products)
		   And StringTSGoods.Products = StringTSGoods.ProductsRecordingAsReceived Then
			
			Field = CommonClientServer.PathToTabularSection(
													"Goods",
													StringTSGoods.LineNumber,
													"ProductsRecordingAsReceived");
		
			ErrorText = StrTemplate(
							NStr("vi = 'Không thể chọn hàng hóa có chất lượng ban đầu. Hãy chọn hàng hóa có chất lượng khác tại dòng %1 của danh sách ""Hàng hóa""';
								|ru = 'Нельзя выбирать товар исходного качества. Выберите товар другого качества в строке %1 списка ""Товары""';
								|en = 'Cannot select goods of the original quality. Select goods of other quality in the %1 line of the ""Goods"" list'; fa = 'Cannot select goods of the original quality. Select goods of other quality in the %1 line of the ""Goods"" list';
								|it = 'Impossibile selezionare l''articolo di qualità originale. Selezionare un articolo di un''altra qualità nella riga %1 dell''elenco ""Articoli""';
								|pl = 'Nie można wybierać towar wyjściowej jakości. Wybierz towar innej jakości w wierszu %1 listy ""Towary""';
								|tr = 'Orijinal kalitedeki ürün seçemezsin. ""Ürünler"" listenin %1 satırından uygun kalitede olmayan ürünler seç'"),
							StringTSGoods.LineNumber);
		
			Common.MessageToUser(ErrorText, ThisObject, Field,, Cancel);
		
		EndIf;
		
	EndDo;
	
	ProductsServer.CheckTypeOfProductDescription(ThisObject,Cancel);
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;
	
	Handler = Documents.DamageAtCustodian.ActionHandler(BusinessOperation);
	If Not Handler.ToUseTermsOfSales() Then
		NotCheckedAttributeArray.Add("Terms");
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	PartnersAndCounterparties.CheckPartnerContent(ThisObject, NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters =
		Documents.DamageAtCustodian.ItemsAndDimensionsSelectionParameters(ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.FillCheckProcessing(
		ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	CheckVATRates(Cancel);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	DamageAtCustodianLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsDamage") Then
		FillInBasedOnDamageToGiverSGoods(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.DamageAtCustodian") Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	EndIf;
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters =
		Documents.DamageAtCustodian.ItemsAndDimensionsSelectionParameters(ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument(FillingData);
	
	ResponsiblePersonsServer.EmployeesInChargeOfFillingDocument(
		ThisObject, FillingData, StandardProcessing);
		
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	DamageAtCustodianLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
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
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DamageAtCustodian);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	If IsNew()	And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters =
		Documents.DamageAtCustodian.ItemsAndDimensionsSelectionParameters(ReceiveGoodsAtCostTheyWereIssuedFromWarehouse);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
	DamageAtCustodianLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DamageAtCustodianLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	DamageAtCustodianLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes());
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	DamageAtCustodianLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InventoryKinds.Clear();
	Basis = Undefined;
	
	InitializeDocument();
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "InventoryKinds");
	
	DamageAtCustodianLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	If Not ReceiveGoodsAtCostTheyWereIssuedFromWarehouse Then
		PriceKind = Catalogs.TypesOfPrices.DefaultPriceType(PriceKind);
	EndIf;
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

#Region FillingInForDamageToGiverSGoods

Procedure FillInBasedOnDamageToGiverSGoods(FillingStructure)
	
	BusinessOperation = Enums.BusinessTransactions.DamageAtToller;
	
	Query = New Query;
	Query.SetParameter("Basis", FillingStructure);
	Query.Text = QueryTextFillInBasedOnDamageToGiverSGoods();
	
	Result = Query.ExecuteBatch();
	HeaderAttributes = Result[Result.UBound() - 1].Select();
	GoodsTable  = Result[Result.UBound()].Unload();
	
	If HeaderAttributes.Next() Then
		
		FillingErrors = New Array;
		ErrorTemplate = NStr("vi = 'Không thể nhập trên cơ sở hàng hóa hư hỏng. Theo dạng vật tư có các ""%1"" khác nhau.';
							|ru = 'Ввод на основании порчи товаров невозможен. В видах запасов присутствуют разные ""%1"".';
							|en = 'Cannot generate documents based on the stock quality change. Inventory owner attributes contain different %1.'; fa = 'Cannot generate documents based on the stock quality change. Inventory owner attributes contain different %1.';
							|it = 'Ввод на основании порчи товаров невозможен. В видах запасов присутствуют разные ""%1"".';
							|pl = 'Cannot generate documents based on the stock quality change. Inventory owner attributes contain different %1.';
							|tr = 'Stok kalite değişikliği temelinde giriş mümkün değildir. Stok türlerinde farklı ""%1"" bulunmaktadır.'");
		
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
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DamageAtCustodian));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Function QueryTextFillInBasedOnDamageToGiverSGoods()
	
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
	|INTO SpoilageGoods
	|FROM
	|	Document.GoodsDamage.InventoryKinds AS TableOfGoods
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
	|	SpoilageGoods.MaterialProvider     AS MaterialProvider,
	|	SpoilageGoods.MaterialProvider.TIN AS TIN,
	|	SpoilageGoods.MaterialProvider.CRTR AS CRTR
	|INTO Givers
	|FROM
	|	SpoilageGoods AS SpoilageGoods
	|
	|WHERE
	|	NOT SpoilageGoods.MaterialProvider.DeletionMark
	|
	|GROUP BY
	|	SpoilageGoods.MaterialProvider,
	|	SpoilageGoods.MaterialProvider.TIN,
	|	SpoilageGoods.MaterialProvider.CRTR
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SpoilageGoods.MaterialProviderContract       AS MaterialProviderContract,
	|	SpoilageGoods.MaterialProviderContract.Number AS Number,
	|	SpoilageGoods.MaterialProviderContract.Date  AS Date
	|INTO GiverSContracts
	|FROM
	|	SpoilageGoods AS SpoilageGoods
	|
	|WHERE
	|	NOT SpoilageGoods.MaterialProviderContract.DeletionMark
	|	AND SpoilageGoods.MaterialProviderContract.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|
	|GROUP BY
	|	SpoilageGoods.MaterialProviderContract,
	|	SpoilageGoods.MaterialProviderContract.Number,
	|	SpoilageGoods.MaterialProviderContract.Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MIN(CatCompanies.Ref)    AS Organization,
	|	MIN(CatCounterparties.Ref)    AS Counterparty,
	|	MIN(CatCounterparties.Partner)   AS Partner,
	|	MIN(CatContracts.Ref)       AS Contract,
	|	MIN(CatContracts.LineOfBusiness) AS LineOfBusiness,
	|	MIN(GoodsDamage.Currency)       AS Currency,
	|	MIN(GoodsDamage.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse) AS ReceiveGoodsAtCostTheyWereIssuedFromWarehouse,
	|	MIN(GoodsDamage.CauseForDamage) AS CauseForDamage,
	|	COUNT(DISTINCT Givers.MaterialProvider) > 1                 AS ErrorCounterparty,
	|	COUNT(DISTINCT GiverSContracts.MaterialProviderContract) > 1 AS ErrorContract,
	|	MIN(GoodsDamage.Ref)       AS Basis
	|FROM
	|	Document.GoodsDamage AS GoodsDamage
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
	|	ON Toller.Ref = GoodsDamage.Organization
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
	|	GoodsDamage.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SpoilageGoods.Products                AS Products,
	|	SpoilageGoods.Characteristic              AS Characteristic,
	|	SpoilageGoods.Series                       AS Series,
	|	SpoilageGoods.ProductsRecordingAsReceived   AS ProductsRecordingAsReceived,
	|	SpoilageGoods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	SpoilageGoods.BatchReceipt          AS BatchReceipt,
	|	SpoilageGoods.CCDNumber                    AS CCDNumber,
	|	SpoilageGoods.Count                  AS Count,
	|	SpoilageGoods.QuantityByGBRN            AS QuantityByGBRN
	|FROM
	|	SpoilageGoods AS SpoilageGoods
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
//	DocumentTables - See Documents.DamageAtCustodian.CollectionOfTabularPartsOfGoods
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.DamageAtCustodian.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Contract,
																		Department,
																		Partner,
																		Contract);
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting);
	
	DestinationsFieldText = 
	"CASE
	|	WHEN Collection.ForAssignment
	|		THEN Collection.Purpose
	|	ELSE VALUE(Catalog.Assignments.EmptyRef)
	|END";
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.ItemsLocationAttributes = "ItemsLocationAttributesReceipt";
	FieldsNames.Products               = "ProductsRecordingAsReceived";
	FieldsNames.Characteristic             = "CharacteristicRecordingAsReceived";
	FieldsNames.Purpose                 = New Structure("FieldText", DestinationsFieldText);
	FieldsNames.Series                      = "Series";
	FieldsNames.BatchesIndicationStatus        = "BatchesIndicationStatus";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager = TemporaryDocumentDataTables();
	
	RefillInventoryKinds = InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
	 Or RefillInventoryKinds
	 Or CheckChangesToDocumentDetails(TempTablesManager)
	 Or CheckProductChanges_(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(
			ThisObject, TempTablesManager, Cancel, FillParameters);
		
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
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do

			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);

			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.ItemsLocationAttributesReceipt	= RowOfGoods.ItemsLocationAttributesReceipt;
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

			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			
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
	|	OR SUM(TableOfGoods.Sum) <> 0
	|	OR SUM(TableOfGoods.AmountOffBalance) <> 0
	|";
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return Not Result_Query.IsEmpty();
	
EndFunction

Function ParametersForFillingInventoryTypes()
	
	Handler = Documents.DamageAtCustodian.ActionHandler(BusinessOperation);
	
	Return Handler.ParametersForFillingInventoryTypes(ReversedDocument);
	
EndFunction

#EndRegion

#Region FillInChecks

Procedure CheckVATRates(Cancel)
	
	ListProducts = Goods.UnloadColumn("Products");
	ProductsRecordingAsReceived = Goods.UnloadColumn("ProductsRecordingAsReceived");
	CommonClientServer.SupplementArray(ListProducts, ProductsRecordingAsReceived, True);
	
	VATRates = VATAccountingERP.VATRatesByItemArray(ListProducts, Organization, Date);
	
	For Each LineProducts_ In Goods Do
		If VATRates[LineProducts_.Products] <> VATRates[LineProducts_.ProductsRecordingAsReceived] Then
			Field = CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "Products");
			MessageText = NStr("vi = 'Không thể phản ánh hàng hỏng, vì mặt hàng kém chất lượng và mặt hàng ban đầu không trùng thuế suất thuế GTGT';
								|ru = 'Невозможно отразить порчу, т.к. у некачественной и исходной номенклатуры не равны ставки НДС';
								|en = 'Cannot record damage as spoiled and source products have different VAT rates'; fa = 'Cannot record damage as spoiled and source products have different VAT rates';
								|it = 'È impossibile riportare il danno, perché le aliquote IVA sono diverse per la nomenclatura di qualità carente e per quella originale';
								|pl = 'Nie można wyrazić uszkodzeń, ponieważ niejakościowe i oryginalne produkty nie są równe stawce VAT';
								|tr = 'Kusurlu ve orijinal stok eşit KDV oranlarına sahip olmadığı için bozulma muhasebeleştirilemez'");
			Common.MessageToUser(MessageText, , Field, "Object", Cancel);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
