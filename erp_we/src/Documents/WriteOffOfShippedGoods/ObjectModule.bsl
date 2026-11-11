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
	
	If ValueIsFilled(SalesTermsAndConditions.ARAPCurrency) Then
		Currency = SalesTermsAndConditions.ARAPCurrency;
	EndIf;
	
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
	
	Handler	= Documents.WriteOffOfShippedGoods.ActionHandler(BusinessOperation);
	Contract		= Handler.GetDefaultContract(ThisObject);
	
	ContractDetails_ = New Structure("LineOfBusiness, Department");
	Catalogs.CounterpartyContracts.FillInDocumentDetails(ThisObject, Contract, ContractDetails_);
	
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
	EndIf;
	
EndProcedure

// Fills in the default sales terms in the product debiting document from the custodian.
//
Procedure FillInDefaultSalesConditions() Export
	
	Handler = Documents.WriteOffOfShippedGoods.ActionHandler(BusinessOperation);
	ToUseTermsOfSales = Handler.ToUseTermsOfSales();
	
	If ValueIsFilled(Partner)
		Or Not ToUseTermsOfSales Then
		
		ContractBusinessTransaction = Handler.ContractBusinessTransaction();
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",		Terms);
		FilterParameters.Insert("EmptyDocumentLink",	Documents.WriteOffOfShippedGoods.EmptyRef());
		FilterParameters.Insert("BusinessTransactions",	ContractBusinessTransaction);
		FilterParameters.Insert("ShipmentWithDeferredTransferOfTitle25",
									ContractBusinessTransaction = Enums.BusinessTransactions.SaleToCustomer);
		
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

// This function generates temporary document data.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date        AS Date,
	|	&Partner     AS Partner,
	|	&Counterparty  AS Counterparty,
	|	&Terms  AS Terms,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Contract     AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	&InventoryType  AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	TableOfGoods.LineNumber    AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Products   AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose     AS Purpose,
	|	TableOfGoods.Series          AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Count     AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END                         AS QuantityByGBRN,
	|	TableOfGoods.CCDNumber       AS CCDNumber,
	|	&Contract					  AS Warehouse,
	|	TRUE                        AS SelectTypesOfStocks,
	|	TableOfGoods.Price           AS Price,
	|	TableOfGoods.Sum          AS Sum
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	TableTypesOfStocks_.LineNumber		AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute		AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count		AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END								AS QuantityByGBRN,
	|	TableTypesOfStocks_.CCDNumber			AS CCDNumber,
	|	TableTypesOfStocks_.Price				AS Price,
	|	TableTypesOfStocks_.Sum			AS Sum
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	TableTypesOfStocks_.LineNumber		AS LineNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttribute		AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products				AS Products,
	|	Dimension.Characteristic			AS Characteristic,
	|	Dimension.Series						AS Series,
	|	TableTypesOfStocks_.Count		AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN	AS QuantityByGBRN,
	|	TableTypesOfStocks_.CCDNumber			AS CCDNumber,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	Dimension.StorageLocation				AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually			AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.Price				AS Price,
	|	TableTypesOfStocks_.Sum			AS Sum
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
	
	Query.SetParameter("Ref",                    Ref);
	Query.SetParameter("Date",                      Date);
	Query.SetParameter("Partner",                   Partner);
	Query.SetParameter("Counterparty",                Counterparty);
	Query.SetParameter("Terms",                Terms);
	Query.SetParameter("BusinessOperation",     BusinessOperation);
	Query.SetParameter("Organization",               Organization);
	Query.SetParameter("Contract",                   Contract);
	Query.SetParameter("InventoryType",                Enums.InventoryTypes.OwnGoods);
	Query.SetParameter("Posted",                  Posted);
	Query.SetParameter("TableOfGoods",            TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",        InventoryKinds);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	
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
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.WriteOffOfShippedGoods - the document for which parameters are initialized.
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
//	DocumentTables - See Documents.WriteOffOfShippedGoods.CollectionOfTabularPartsOfGoods.
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

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(
								ThisObject,
								Documents.WriteOffOfShippedGoods);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.WriteOffOfShippedGoods Then
		
		For CurIndex__ = 0 To Goods.Count() - 1 Do
			
			LineProducts_ = Goods[CurIndex__]; // LineOfATabularSection
			
			If Not ValueIsFilled(ReferenceOrder)
				And Not ValueIsFilled(LineProducts_.ReferenceOrder) Then
				
				ErrorText = NStr("vi = 'Chưa điền trường ""Lệnh"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Распоряжение"" в строке %LineNumber% списка ""Товары""';
								|en = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list'; fa = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list';
								|it = 'Campo ""Disposizione"" non compilato nella riga %LineNumber% dell''elenco ""Articoli""';
								|pl = 'Pole ""Zamówienie"" w wierszu %LineNumber% listy ""Towary""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Emir"" alanı doldurulmamış'");
				ErrorText =  StrReplace(ErrorText, "%LineNumber%", LineProducts_.LineNumber);
				ErrorField  = CommonClientServer.PathToTabularSection("Goods",
																				LineProducts_.LineNumber,
																				"ReferenceOrder");
				
				Common.MessageToUser(ErrorText, ThisObject, ErrorField, Undefined, Cancel);
				
			EndIf;
			
		EndDo;
	
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	If GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers")
		And Not BusinessOperation = Enums.BusinessTransactions.GoodsWriteOffAtToller
		And True Then
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel);
		
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	Handler = Documents.WriteOffOfShippedGoods.ActionHandler(BusinessOperation);
	
	If Not Handler.ToUseTermsOfSales() Then
		NotCheckedAttributeArray.Add("Terms");
	EndIf;
	
	If Not BusinessOperation = Enums.BusinessTransactions.WriteOffOfShippedGoods Then
		NotCheckedAttributeArray.Add("ReferenceOrder");
	EndIf;
	
	PartnersAndCounterparties.CheckPartnerContent(ThisObject, NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffOfShippedGoods.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(
		ThisObject,
		Cancel,
		CheckedAttributes,
		ItemsAndDimensionsSelectionParameters);
		
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		
		Cancel = True;
		
	EndIf;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	
	WriteOffOfShippedGoodsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FilledInBasedOnDocument = False;
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DiscrepancyCertificate") Then
		
		FillInAccordingToDiscrepancyCertificate(FillingData);
		FilledInBasedOnDocument = True;

	ElsIf TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("DocumentBasis") Then
			
			DocumentBasis = FillingData.DocumentBasis;
			ArrayOfBases = Undefined;
			If TypeOf(DocumentBasis) = Type("Array") And ValueIsFilled(DocumentBasis) Then
				ArrayOfBases = DocumentBasis;
				DocumentBasis = FillingData.DocumentBasis[0];
			EndIf;
			
			BasisType = TypeOf(DocumentBasis);
			If BasisType = Type("DocumentRef.GoodsShipmentToCustomer") Then
				FillInBasedOnShipmentOfGoodsToCustomer(DocumentBasis);
				FilledInBasedOnDocument = True;
			ElsIf ValueIsFilled(ArrayOfBases) Then
				FillInBasedOnArrayOfOrdersForShipmentOfGoodsToClient(ArrayOfBases);
				FilledInBasedOnDocument = True;
			EndIf;
		Else
			FillPropertyValues(ThisObject, FillingData);
		EndIf;
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReportOnVMIAdjustment") Then
		FillInOnBasisOfReportOnWriteOffOfGiverSGoods(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsShipmentToCustomer") Then
		
		FillInBasedOnShipmentOfGoodsToCustomer(FillingData);
		FilledInBasedOnDocument = True;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	EndIf;
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffOfShippedGoods.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not FilledInBasedOnDocument Then
		InitializeDocument();
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",		Terms);
		FilterParameters.Insert("EmptyDocumentLink",	Documents.WriteOffOfShippedGoods.EmptyRef());
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(Partner, FilterParameters);
		
		If DefaultSalesTerms <> Undefined Then
			Currency = DefaultSalesTerms.Currency;
		EndIf;
	EndIf;
	
	ResponsiblePersonsServer.EmployeesInChargeOfFillingDocument(Ref, FillingData, StandardProcessing);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	WriteOffOfShippedGoodsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps		= New Array;
	ArrayOfOperationDetails	= New Array;
	
	Documents.WriteOffOfShippedGoods.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(
								ThisObject,
								Documents.WriteOffOfShippedGoods);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	DocumentAmount = Goods.Total("Sum");
	
	If Not BusinessOperation = Enums.BusinessTransactions.WriteOffOfShippedGoods Then
		ReferenceOrder = Undefined;
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
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(
		ThisObject,
		Documents.WriteOffOfShippedGoods.AccountingAccountSettings_());
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffOfShippedGoods.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	WriteOffOfShippedGoodsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	WriteOffOfShippedGoodsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	WriteOffOfShippedGoodsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	WriteOffOfShippedGoodsLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	Basis = Undefined;
	
	InventoryKinds.Clear();
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "InventoryKinds");
	
	WriteOffOfShippedGoodsLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument()
	
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	EmployeeResponsible = Users.CurrentUser();
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	If Not ValueIsFilled(SourseOfInformationAboutPricesForPrinting) Then
		SourseOfInformationAboutPricesForPrinting = Enums.SourcesOfPriceInformationForPrinting.ByCost;
		PriceKind                           = Undefined;
	EndIf;
	
EndProcedure

#Region FillingInReportOnWriteOffOfGiverSGoods

Procedure FillInOnBasisOfReportOnWriteOffOfGiverSGoods(FillingStructure)
	
	BusinessOperation = Enums.BusinessTransactions.GoodsWriteOffAtToller;
	
	Query = New Query;
	Query.SetParameter("Basis", FillingStructure);
	Query.Text = QueryTextFillInOnBasisOfReportOnWriteOffOfGiverSGoods();
	
	Result = Query.ExecuteBatch();
	HeaderAttributes = Result[Result.UBound() - 1].Select();
	GoodsTable  = Result[Result.UBound()].Unload();
	
	If HeaderAttributes.Next() Then
		FillPropertyValues(ThisObject, HeaderAttributes);
	EndIf;
	
	Goods.Load(GoodsTable);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.WriteOffOfShippedGoods));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Function QueryTextFillInOnBasisOfReportOnWriteOffOfGiverSGoods()
	
	QueryText =
	"SELECT ALLOWED
	|	CatCompanies.Ref           AS Organization,
	|	CatCounterparties.Ref           AS Counterparty,
	|	CatCounterparties.Partner          AS Partner,
	|	CatContracts.Ref              AS Contract,
	|	CASE
	|		WHEN CatContracts.LineOfBusiness IS NULL
	|			THEN ReportOnVMIAdjustment.LineOfBusiness
	|		ELSE CatContracts.LineOfBusiness
	|	END                                 AS LineOfBusiness,
	|	ReportOnVMIAdjustment.Currency AS Currency,
	|	CASE
	|		WHEN CatContracts.ARAPCurrency IS NULL
	|			THEN ReportOnVMIAdjustment.ARAPCurrency
	|		ELSE CatContracts.ARAPCurrency
	|	END                                 AS ARAPCurrency,
	|	ReportOnVMIAdjustment.Ref AS Basis
	|FROM
	|	Document.ReportOnVMIAdjustment AS ReportOnVMIAdjustment
	|	
	|	LEFT JOIN Catalog.Counterparties AS MaterialProvider
	|	ON MaterialProvider.Ref = ReportOnVMIAdjustment.Counterparty
	|	
	|	LEFT JOIN Catalog.Companies AS CatCompanies
	|	ON CatCompanies.TIN = MaterialProvider.TIN
	|	AND CatCompanies.CRTR = MaterialProvider.CRTR
	|	AND NOT CatCompanies.DeletionMark
	|	
	|	LEFT JOIN Catalog.Companies AS Toller
	|	ON Toller.Ref = ReportOnVMIAdjustment.Organization
	|	
	|	LEFT JOIN Catalog.Counterparties AS CatCounterparties
	|	ON CatCounterparties.TIN = Toller.TIN
	|	AND CatCounterparties.CRTR = Toller.CRTR
	|	AND NOT CatCounterparties.DeletionMark
	|	
	|	LEFT JOIN Catalog.CounterpartyContracts AS MaterialProviderContract
	|	ON MaterialProviderContract.Ref = ReportOnVMIAdjustment.Contract
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
	|	ReportOnVMIAdjustment.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfGoods.ItemsLocationAttributes.Products   AS Products,
	|	TableOfGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes.Series          AS Series,
	|	TableOfGoods.CCDNumber                                  AS CCDNumber,
	|	SUM(TableOfGoods.Count)                         AS Count,
	|	TableOfGoods.Price                                      AS Price,
	|	SUM(TableOfGoods.Sum)                              AS Sum
	|FROM
	|	Document.ReportOnVMIAdjustment.InventoryKinds AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref = &Basis
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.CCDNumber,
	|	TableOfGoods.Price
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

Procedure FillInBasedOnShipmentOfGoodsToCustomer(DocumentBasis)
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(
		DocumentBasis,
		CheckParameters);
	
	QueryText = 
	"SELECT
	|	DataHeader.Partner                 AS Partner,
	|	DataHeader.Counterparty              AS Counterparty,
	|	DataHeader.Terms              AS Terms,
	|	DataHeader.Contract                 AS Contract,
	|	VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods) AS BusinessOperation,
	|	DataHeader.Organization             AS Organization,
	|	DataHeader.LineOfBusiness AS LineOfBusiness,
	|	DataHeader.Department           AS Department,
	|	DataHeader.SalesOpportunity                  AS SalesOpportunity,
	|	DataHeader.Currency                  AS Currency,
	|	DataHeader.Warehouse                   AS Warehouse
	|FROM
	|	Document.GoodsShipmentToCustomer AS DataHeader
	|WHERE
	|	DataHeader.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
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
	|	GoodsTable.Ref = &DocumentBasis
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
	|	GoodsTable.Ref = &DocumentBasis
	|	AND NOT GoodsTable.Ref.ShipmentByOrders
	|	AND GoodsTable.SalesOrder IN(
	|	                  VALUE(Document.SalesOrder.EmptyRef),
	|	                  VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                  VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                  UNDEFINED
	|	                  )
	|";

	Query = New Query(QueryText);
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResults = Query.ExecuteBatch();
	
	HeaderAttributes = QueryResults[QueryResults.UBound() - 1].Select();
	References = QueryResults[QueryResults.UBound()].Unload().UnloadColumn("ReferenceOrder");
	
	HeaderAttributes.Next();
	FillPropertyValues(ThisObject, HeaderAttributes);
	
	InvoiceManager = Documents.WriteOffOfShippedGoods;
	
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

EndProcedure

Procedure FillInAccordingToDiscrepancyCertificate(FillingData)
	
	DiscrepancyCertificate = FillingData.DiscrepancyCertificate;
	BaseDocumentForDiscrepancyReport = FillingData.BasisOfAct;
	ReduceShipmentByReference = FillingData.ReduceShipmentByReference;
	
	FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer();
	
	// 1. We receive orders from the act of discrepancies. In the future, they will be needed to obtain the Balance of goods by CCD numbers
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	CASE
	|		WHEN Table.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer)
	|			AND Table.SalesOrder IN (
	|					VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|					VALUE(Document.SalesOrder.EmptyRef),
	|					UNDEFINED
	|					)
	|			THEN Table.SaleOfGoodsAndServices
	|		ELSE
	|			Table.SalesOrder
	|	END AS ReferenceOrder
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS Table
	|WHERE
	|	Table.Ref = &DiscrepancyCertificate
	|";
	
	Query.SetParameter("DiscrepancyCertificate", DiscrepancyCertificate);
	References = Query.Execute().Unload().UnloadColumn("ReferenceOrder");
	
	QueryTexts = New Array;
	
	// 2. We receive the data of the certificate of discrepancies: information from the header and the tabular part of the Goods
	QueryText =
	"SELECT
	|	DataHeader.Partner                 AS Partner,
	|	DataHeader.Counterparty              AS Counterparty,
	|	DataHeader.Terms              AS Terms,
	|	DataHeader.Contract                 AS Contract,
	|	VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods) AS BusinessOperation,
	|	DataHeader.Organization             AS Organization,
	|	DataHeader.Warehouse                   AS Warehouse,
	|	DataHeader.LineOfBusiness AS LineOfBusiness,
	|	DataHeader.Department           AS Department,
	|	DataHeader.SalesOpportunity                  AS SalesOpportunity,
	|	DataHeader.Currency                  AS Currency,
	|	DataHeader.Ref                  AS BaseDocumentForDiscrepancyReport
	|FROM
	|	Document.GoodsShipmentToCustomer AS DataHeader
	|WHERE
	|	DataHeader.Ref = &BaseDocumentForDiscrepancyReport
	|
	|UNION ALL
	|
	|SELECT
	|	DataHeader.Partner                 AS Partner,
	|	DataHeader.Counterparty              AS Counterparty,
	|	DataHeader.Terms              AS Terms,
	|	DataHeader.Contract                 AS Contract,
	|	VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods) AS BusinessOperation,
	|	DataHeader.Organization             AS Organization,
	|	DataHeader.Warehouse                   AS Warehouse,
	|	DataHeader.LineOfBusiness AS LineOfBusiness,
	|	DataHeader.Department           AS Department,
	|	DataHeader.SalesOpportunity                  AS SalesOpportunity,
	|	DataHeader.Currency                  AS Currency,
	|	DataHeader.Ref                  AS BaseDocumentForDiscrepancyReport
	|FROM
	|	Document.CustomerInvoice AS DataHeader
	|WHERE
	|	DataHeader.Ref = &BaseDocumentForDiscrepancyReport
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
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
	|	ActOfDiscrepancies.Products         AS Products,
	|	ActOfDiscrepancies.Characteristic       AS Characteristic,
	|	ActOfDiscrepancies.Purpose           AS Purpose,
	|	ActOfDiscrepancies.CountByDocument - ActOfDiscrepancies.Count AS ForRegistrationQuantity,
	|	CASE
	|		WHEN ActOfDiscrepancies.CountByDocument - ActOfDiscrepancies.Count <> 0
	|			AND ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.GoodsShipmentToCustomer
	|			THEN (ActOfDiscrepancies.SumByDocument - ActOfDiscrepancies.Sum) / (ActOfDiscrepancies.CountByDocument - ActOfDiscrepancies.Count)
	|		WHEN ActOfDiscrepancies.CountByDocument - ActOfDiscrepancies.Count <> 0
	|			THEN (ActOfDiscrepancies.AmountIncludingVATByDocument - ActOfDiscrepancies.AmountIncludingVAT) / (ActOfDiscrepancies.CountByDocument - ActOfDiscrepancies.Count)
	|		ELSE
	|			0
	|	END                                       AS Price,
	|	CASE
	|		WHEN ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.GoodsShipmentToCustomer
	|			THEN ActOfDiscrepancies.SumByDocument - ActOfDiscrepancies.Sum
	|		ELSE
	|			ActOfDiscrepancies.AmountIncludingVATByDocument - ActOfDiscrepancies.AmountIncludingVAT
	|	END                                       AS AmountToBeProcessed,
	|	ActOfDiscrepancies.Warehouse                AS Warehouse,
	|	CASE
	|		WHEN ShipmentDocumentsByOrder.WarehouseInHeader IS NOT NULL
	|			THEN ShipmentDocumentsByOrder.WarehouseInHeader
	|		WHEN ShipmentDocumentsForImplementation.WarehouseInHeader IS NOT NULL
	|			THEN ShipmentDocumentsForImplementation.WarehouseInHeader
	|		ELSE
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|	END                                       AS WarehouseInHeader,
	|	ActOfDiscrepancies.Series                AS Series,
	|	ActOfDiscrepancies.RowCode            AS RowCode,
	|	CASE
	|		WHEN ActOfDiscrepancies.SalesOrder IN (
	|	                                VALUE(Document.SalesOrder.EmptyRef),
	|	                                VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                                VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                                VALUE(Document.SourceDocument.EmptyRef),
	|	                                UNDEFINED
	|	                                )
	|			THEN ActOfDiscrepancies.SaleOfGoodsAndServices
	|		ELSE
	|			ActOfDiscrepancies.SalesOrder
	|	END                                       AS ReferenceOrder,
	|	&ReduceShipmentByReference            AS ReduceShipmentByReference,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber
	|INTO TTDataOfAct
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
	|	AND ActOfDiscrepancies.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit)
	|	AND CASE
	|		WHEN ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.CustomerInvoice
	|			AND &ReduceShipmentByReference
	|			THEN ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|					AND (ActOfDiscrepancies.SalesOrder REFS Document.SalesOrder
	|						OR ActOfDiscrepancies.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer)
	|		WHEN ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.CustomerInvoice
	|			AND NOT &ReduceShipmentByReference
	|			THEN ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)
	|				OR ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|					AND NOT ActOfDiscrepancies.SalesOrder REFS Document.SalesOrder
	|					AND NOT ActOfDiscrepancies.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|		WHEN ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.GoodsShipmentToCustomer
	|			AND &ReduceShipmentByReference
	|			THEN ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|					AND (ActOfDiscrepancies.SalesOrder REFS Document.SalesOrder
	|						OR ActOfDiscrepancies.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer)
	|		WHEN ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.GoodsShipmentToCustomer
	|			AND NOT &ReduceShipmentByReference
	|			THEN ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)
	|				OR ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|					AND NOT ActOfDiscrepancies.SalesOrder REFS Document.SalesOrder
	|					AND NOT ActOfDiscrepancies.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|	END
	|";
	
	QueryTexts.Add(QueryText);
	
	// 3. We receive the Balance of goods by CCD numbers
	QueryText = Documents.WriteOffOfShippedGoods.QueryTextBalancesToBeProcessedUnderCCD("TTDataOfAct");
	QueryTexts.Add(QueryText);
	
	// 4. We connect the data of the certificate of discrepancies and the Balance of goods by CCD numbers
	QueryText =
	"SELECT
	|	ActData.Products                    AS Products,
	|	ActData.Characteristic                  AS Characteristic,
	|	ActData.Purpose                      AS Purpose,
	|	ActData.Price                            AS Price,
	|	ActData.Warehouse                           AS Warehouse,
	|	ActData.WarehouseInHeader                     AS WarehouseInHeader,
	|	ActData.Series                           AS Series,
	|	ActData.RowCode                       AS RowCode,
	|	ActData.ReferenceOrder                    AS ReferenceOrder,
	|	ActData.ReduceShipmentByReference AS ReduceShipmentByReference,
	|	ISNULL(DataOfAccounting.CCDNumber, ActData.CCDNumber) AS CCDNumber,
	|	ISNULL(DataOfAccounting.ForRegistrationQuantity, ActData.ForRegistrationQuantity) AS Count,
	|	ISNULL(DataOfAccounting.AmountToBeProcessed, ActData.AmountToBeProcessed) AS Sum
	|FROM
	|	TTDataOfAct AS ActData
	|	LEFT JOIN TTAccountingData AS DataOfAccounting
	|		ON ActData.ReferenceOrder = DataOfAccounting.ReferenceOrder
	|			AND ActData.Products = DataOfAccounting.Products
	|			AND ActData.Characteristic = DataOfAccounting.Characteristic
	|			AND ActData.RowCode = DataOfAccounting.RowCode
	|			AND ActData.Series = DataOfAccounting.Series
	|";
	
	QueryTexts.Add(QueryText);
	QueryText = StrConcat(QueryTexts, InvoicesServer.QuerySeparatorText());
	
	Query = New Query(QueryText);
	Query.SetParameter("BaseDocumentForDiscrepancyReport", BaseDocumentForDiscrepancyReport);
	Query.SetParameter("DiscrepancyCertificate", DiscrepancyCertificate);
	Query.SetParameter("ItemsTypes", FilterByProductType);
	Query.SetParameter("ReduceShipmentByReference", ReduceShipmentByReference);
	Query.SetParameter("References", References);
	Query.SetParameter("Recorder", Undefined);
	
	QueryResults = Query.ExecuteBatch();
	
	HeaderAttributes = QueryResults[0].Select();
	GoodsTable = QueryResults[QueryResults.UBound()].Unload();
	
	HeaderAttributes.Next();
	FillPropertyValues(ThisObject, HeaderAttributes);
	
	If GoodsTable.Count() > 0 And ValueIsFilled(GoodsTable[0].WarehouseInHeader) Then
		Warehouse = GoodsTable[0].WarehouseInHeader;
	EndIf;
	
	Goods.Load(GoodsTable);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(
															ThisObject, Documents.WriteOffOfShippedGoods));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);

EndProcedure

Procedure FillInBasedOnArrayOfOrdersForShipmentOfGoodsToClient(ArrayOfBases)
	
	Query = New Query;
	Query.Text = QueryTextBasedOnArrayOfOrdersForShipmentOfGoodsToClient();
	Query.SetParameter("ArrayOfBases", ArrayOfBases);
	
	QueryResults = Query.ExecuteBatch();
	QueryResult = QueryResults[1];
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	References = QueryResults[2].Unload().UnloadColumn("ReferenceOrder");
	
	// Filling in the header
	HeaderAttributes = QueryResult.Select();
	HeaderAttributes.Next();
	FillPropertyValues(ThisObject, HeaderAttributes);
	
	InvoiceManager = Documents.WriteOffOfShippedGoods;
	
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
	
EndProcedure

Function QueryTextBasedOnArrayOfOrdersForShipmentOfGoodsToClient()
	
	QueryText =
	"SELECT DISTINCT ALLOWED
	|	NestedQuery.Ref AS Ref
	|INTO TT_ShipmentsOfGoods
	|FROM
	|	(SELECT
	|		DocumentTable.Ref
	|	FROM
	|		Document.GoodsShipmentToCustomer AS DocumentTable
	|	WHERE
	|		DocumentTable.SalesOrder IN (&ArrayOfBases)
	|		AND DocumentTable.Posted
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableOfGoods.Ref
	|	FROM
	|		Document.GoodsShipmentToCustomer.Goods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.SalesOrder IN (&ArrayOfBases)
	|		AND TableOfGoods.Ref.Posted
	|	) AS NestedQuery
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 1
	|	GoodsShipmentToCustomer.Partner                 AS Partner,
	|	GoodsShipmentToCustomer.Counterparty              AS Counterparty,
	|	GoodsShipmentToCustomer.Terms              AS Terms,
	|	GoodsShipmentToCustomer.Contract                 AS Contract,
	|	GoodsShipmentToCustomer.Organization             AS Organization,
	|	GoodsShipmentToCustomer.LineOfBusiness AS LineOfBusiness,
	|	GoodsShipmentToCustomer.Department           AS Department,
	|	GoodsShipmentToCustomer.SalesOpportunity                  AS SalesOpportunity,
	|	GoodsShipmentToCustomer.Currency                  AS Currency,
	|	GoodsShipmentToCustomer.Warehouse                   AS Warehouse,
	|	VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods) AS BusinessOperation
	|FROM
	|	Document.GoodsShipmentToCustomer AS GoodsShipmentToCustomer
	|WHERE
	|	GoodsShipmentToCustomer.Ref  IN (SELECT TT.Ref FROM TT_ShipmentsOfGoods AS TT)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CASE
	|		WHEN GoodsTable.SalesOrder REFS Document.SalesOrder
	|				AND CAST(GoodsTable.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|				AND DocumentTable.Patch
	|			THEN DocumentTable.CorrectedDocument
	|		WHEN GoodsTable.SalesOrder REFS Document.SalesOrder
	|				AND CAST(GoodsTable.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|			THEN GoodsTable.Ref
	|		WHEN GoodsTable.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|				AND CAST(GoodsTable.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|				AND DocumentTable.Patch
	|			THEN DocumentTable.CorrectedDocument
	|		WHEN GoodsTable.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|				AND CAST(GoodsTable.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|			THEN GoodsTable.Ref
	|		ELSE
	|			GoodsTable.SalesOrder
	|	END AS ReferenceOrder
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
	|LEFT JOIN
	|	Document.GoodsShipmentToCustomer AS DocumentTable
	|ON
	|	GoodsTable.Ref = DocumentTable.Ref
	|WHERE
	|	GoodsTable.Ref IN (SELECT TT.Ref FROM TT_ShipmentsOfGoods AS TT)
	|	AND DocumentTable.ShipmentByOrders
	|	AND NOT GoodsTable.SalesOrder IN(
	|	                  VALUE(Document.SalesOrder.EmptyRef),
	|	                  VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                  UNDEFINED
	|	                  )
	|
	|";
	
	Return QueryText;

EndFunction
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
		FillInAdditionalStockTypes();
		
	EndIf;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

// The procedure fills in additional columns in the table part of the document's' types of items'.
//
Procedure FillInAdditionalStockTypes() Export
	
	UnloadedColumns = "ItemsLocationAttributes, Count, Price, Sum";
	
	GoodsTable = Goods.Unload(, UnloadedColumns);
	GoodsTable.GroupBy("ItemsLocationAttributes, Price",
							"Count, Sum");
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In GoodsTable Do
		
		GoodsQuantity  = RowOfGoods.Count;
		GoodsAmount       = RowOfGoods.Sum;
		
		If GoodsQuantity = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.Price       = RowOfGoods.Price;
			NewRow.Count = Count;
			
			If GoodsQuantity <> 0 Then
				NewRow.Sum               = Count * GoodsAmount / GoodsQuantity;
			EndIf;
			
			InventoryLine.Count = InventoryLine.Count - NewRow.Count;
			
			GoodsQuantity  = GoodsQuantity - NewRow.Count;
			GoodsAmount       = GoodsAmount - NewRow.Sum;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Filter = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(Filter);
	
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
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.Products   AS Products,
	|		TableOfGoods.Characteristic AS Characteristic,
	|		TableOfGoods.Count     AS Count,
	|		TableOfGoods.CCDNumber       AS CCDNumber,
	|		TableOfGoods.Sum          AS Sum
	|
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.Products   AS Products,
	|		TableTypesOfStocks_.Characteristic AS Characteristic,
	|		-TableTypesOfStocks_.Count    AS Count,
	|		TableTypesOfStocks_.CCDNumber       AS CCDNumber,
	|		-TableTypesOfStocks_.Sum         AS Sum
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.CCDNumber
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.Sum) <> 0
	|";
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return Not Result_Query.IsEmpty();
	
EndFunction

Function ParametersForFillingInventoryTypes()
	
	Handler = Documents.WriteOffOfShippedGoods.ActionHandler(BusinessOperation);
	
	Return Handler.ParametersForFillingInventoryTypes(ThisObject);
	
EndFunction

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.WriteOffOfShippedGoods.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.WriteOffOfShippedGoods.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Contract,
																		Department,
																		Partner,
																		Contract);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.BatchesIndicationStatus = "BatchesIndicationStatusOfGoodsTransferred";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
