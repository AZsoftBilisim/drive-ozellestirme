#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the terms of sales in the customer's order
//
// Parameters:
//	SalesTermsAndConditions - Structure - Structure to fill in
//
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Currency) Then
		Currency = SalesTermsAndConditions.Currency;
	EndIf;
	If ValueIsFilled(SalesTermsAndConditions.ARAPCurrency) Then
		ARAPCurrency = SalesTermsAndConditions.ARAPCurrency;
	EndIf;
	
	PriceIncludesVAT       = SalesTermsAndConditions.PriceIncludesVAT;
	LineOfBusiness = SalesTermsAndConditions.LineOfBusiness; 
	
	OrganizationChanged = ValueIsFilled(SalesTermsAndConditions.Organization) And SalesTermsAndConditions.Organization <> Organization;
	PaymentFormChanged = ValueIsFilled(SalesTermsAndConditions.PaymentMethod) And SalesTermsAndConditions.PaymentMethod <> PaymentMethod;
	
	PaymentMethod = SalesTermsAndConditions.PaymentMethod;
	
	If OrganizationChanged Then
		Organization = SalesTermsAndConditions.Organization;
		CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	If OrganizationChanged Or PaymentFormChanged Then
		
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization = Organization;
		ParametersStructure.LineOfBusiness = LineOfBusiness;
		ParametersStructure.PaymentMethod = PaymentMethod;

		CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
		
	EndIf;
	
	TheCounterpartyPriorToTheChange = Counterparty;
	
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.Counterparty) And SalesTermsAndConditions.Counterparty<>Counterparty Then
			Counterparty = SalesTermsAndConditions.Counterparty;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If TheCounterpartyPriorToTheChange <> Counterparty Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	If SalesTermsAndConditions.ContractsAreUsed <> Undefined And SalesTermsAndConditions.ContractsAreUsed Then
		
		Contract = SalesServer.GetDefaultContract(
			ThisObject,
			Enums.BusinessTransactions.SaleToCustomer,
			ARAPCurrency);
		
		If ValueIsFilled(Contract) Then
			PaymentInCurrencyUnderContract = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
			If ForeignCurrencyTransaction <> PaymentInCurrencyUnderContract Then
				ForeignCurrencyTransaction = PaymentInCurrencyUnderContract;
				CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
		EndIf;
		
		SalesServer.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
		
		If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
	Else
		
		If ForeignCurrencyTransaction <> SalesTermsAndConditions.ForeignCurrencyTransaction Then
			ForeignCurrencyTransaction = SalesTermsAndConditions.ForeignCurrencyTransaction;
			CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
	EndIf;
	
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		OrganizationSDefaultAccountParameters(), CompanyBankAccount);
	
	If ValueIsFilled(SalesTermsAndConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = SalesTermsAndConditions.FinancialAccountingGroup;
	EndIf;
	
	StartDate = ?(ValueIsFilled(Date),Date,CurrentSessionDate());
	
	DiscountsMarkups.Clear();
		
EndProcedure

// Fills in the default sales terms in the customer's order
//
Procedure FillInDefaultSalesConditions() Export
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	If ValueIsFilled (Partner) Or Not ToUseTermsOfSales Then
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
			Partner,
			New Structure (
				"ConsiderWarehouseGroups,
				|ExcludeWarehouseGroupsAvailableInOrders,
				|BusinessTransactions,
				|SelectedAgreement,
				|EmptyDocumentLink",
				True,
				True,
				Enums.BusinessTransactions.SaleToCustomer,
				Terms,
				Documents.CustomerInvoiceServices.EmptyRef()));
		
		TheCounterpartyPriorToTheChange = Counterparty;
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales Or 
				(Terms <> DefaultSalesTerms.Terms And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				TheCounterpartyPriorToTheChange = Counterparty;
				
				If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
					LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
				EndIf;
				
				FillParameters = Documents.CustomerInvoiceServices.ParametersForFillingInSalesVATTaxation(ThisObject);
				VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
				
				If ToUseTermsOfSales Then
					StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
					FillParameters = New Structure;
					FillParameters.Insert("Date", Date);
					FillParameters.Insert("Currency", Currency);
					FillParameters.Insert("Organization", Organization);
					FillParameters.Insert("Terms", Terms);
					FillParameters.Insert("CalculateSets", True);
					FillParameters.Insert("VATTaxation", VATTaxation);
					FillParameters.Insert("PopulationFields", "Price, VATRate");
					FillParameters.Insert("ColumnsByValue", New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef()));
					StructureOfActions = New Structure;
					StructureOfActions.Insert("RecalculateAmount", "Count");
					StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "Count");
					StructureOfActions.Insert("ClearAutomaticDiscount", Undefined);
					StructureOfActions.Insert("ClearAmountOfSettlements", Undefined);
					StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear,QuantityName", False, "Count"));
					
					EnterprisePricesFillingServer.FillInPrices(
						Services,
						, // Array of rows or selection structure
						FillParameters,
						StructureOfActions);
				EndIf;
			Else
				Terms = DefaultSalesTerms.Terms;
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			EndIf;
			
		Else
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			Terms = Undefined;
		EndIf;
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
			?(TheCounterpartyPriorToTheChange = Counterparty, CounterpartyBankAccount, Undefined));
		
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
	
EndProcedure

// Fills in the terms of sales under the agreement in the act of work performed
//
Procedure FillInTermsOfSalesUnderAgreement() Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
	EndIf;
	
	FillParameters = Documents.CustomerInvoiceServices.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	FillParameters = New Structure;
	FillParameters.Insert("Date", Date);
	FillParameters.Insert("Currency", Currency);
	FillParameters.Insert("Organization", Organization);
	FillParameters.Insert("Terms", Terms);
	FillParameters.Insert("VATTaxation", VATTaxation);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, PriceKind, VATRate");
	FillParameters.Insert("ColumnsByValue", New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef()));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "Count");
	StructureOfActions.Insert("ClearAutomaticDiscount", Undefined);
	StructureOfActions.Insert("ClearAmountOfSettlements", Undefined);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear,QuantityName", False, "Count"));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(ThisObject));
	
	EnterprisePricesFillingServer.FillInPrices(
		Services,
		, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
	
EndProcedure

// This function generates temporary document data
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
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.Work_5) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Table Services
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension AS SetAccountingDimension,
	|	TableOfGoods.Count AS Count,
	|	&FieldTextTableOfGoodsQuantityByGBRN_ AS QuantityByGBRN,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Price AS Price,
	|	TableOfGoods.Sum AS Sum,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	TableOfGoods.ManualDiscount AS ManualDiscount,
	|	TableOfGoods.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber,
	|	TableOfGoods.SalesOrder AS SalesOrder,
	|	TableOfGoods.ARAPObject AS ARAPObject,
	|	TableOfGoods.Department AS Department,
	|	TableOfGoods.PartnerProducts AS PartnerProducts
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Traceable Works
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	0 AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension AS SetAccountingDimension,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END AS QuantityByGBRN,
	|	Dimension.StorageLocation AS Warehouse,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Price AS Price,
	|	TableOfGoods.Sum + TableOfGoods.VATAmount * &PriceIncludesVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	TableOfGoods.ManualDiscount AS ManualDiscount,
	|	TableOfGoods.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TableOfGoods.SalesOrder AS SalesOrder,
	|	TableOfGoods.ARAPObject AS ARAPObject,
	|	TableOfGoods.Department AS Department,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.PartnerProducts AS PartnerProducts
	|INTO TableOfGoods
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
	|	TableTypesOfStocks_.SetAccountingDimension AS SetAccountingDimension,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.Price AS Price,
	|	TableTypesOfStocks_.SalesOrder AS SalesOrder,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	TableTypesOfStocks_.ManualDiscount AS ManualDiscount,
	|	TableTypesOfStocks_.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// TableTypesOfStocks_
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.SetAccountingDimension		AS SetAccountingDimension,
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic 						AS Characteristic,
	|	Dimension.Series 								AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber 					AS CCDNumber,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|	TableTypesOfStocks_.Price							AS Price,
	|	VALUE(Catalog.Warehouses.EmptyRef)		AS OriginWarehouse,
	|	Dimension.StorageLocation							AS Warehouse,
	|	TableTypesOfStocks_.SalesOrder					AS SalesOrder,
	|	TableTypesOfStocks_.ARAPObject				AS ARAPObject,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount						AS VATAmount,
	|	TableTypesOfStocks_.AmountARAP			AS AmountARAP,
	|	TableTypesOfStocks_.ManualDiscount			AS ManualDiscount,
	|	TableTypesOfStocks_.DiscountMarkupAmount	AS DiscountMarkupAmount,
	|	&InventoryOwnerAttributesAreSpecifiedManually						AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTTypesOfStocks";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	TableOfGoods =
		?(CommonClientServer.HasAttributeOrObjectProperty(AdditionalProperties, "TablesOfFillingOfTypesOfStocksAtExchange")
			And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
			And CommonClientServer.HasAttributeOrObjectProperty(AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange, "Services"),
		AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Services,
		Services);
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Department", Department);
	Query.SetParameter("PriceIncludesVAT", ?(PriceIncludesVAT, 0, 1));
	
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

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.CustomerInvoiceServices - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

// Fills in the Attributes that store information about the Inventory owner attributes and analytics of inventory items in the tabular part of the 'Services'
// document, and also fills in the tabular part of the 'Inventory types'.
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.CustomerInvoiceServices.CollectionOfTabularPartsOfGoods.
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

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);

	ThereAreAdjustingEntries = False;
	SalesServer.CheckForAdjustments(Ref, Ref, ThereAreAdjustingEntries);
	If WriteMode = DocumentWriteMode.UndoPosting And ThereAreAdjustingEntries Then
		SalesServer.ReportErrorsCancellationsAndAdjustments(Ref,Cancel);
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting 
		And GetFunctionalOption("UseDiscountsMarkupsInSales") 
		And Not DiscountsAreCalculated Then
		
			Cancel = True;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong chứng từ %1, chiết khấu tự động (tỷ suất lợi nhuận) không được tính. Không thể kết chuyển. Để tính chiết khấu tự động (tỷ suất lợi nhuận), hãy kết chuyển chứng từ từ mẫu.';
				|ru = 'В документе %1 не рассчитаны автоматические скидки (наценки). Проведение невозможно. Для расчёта автоматических скидок (наценок) проведите документ из формы документа.';
				|en = 'Discounts/markups are not calculated in the %1document. Posting is impossible. To calculate discounts/markups, post the document from the document form.'; fa = 'Discounts/markups are not calculated in the %1document. Posting is impossible. To calculate discounts/markups, post the document from the document form.';
				|it = 'Nel documento %1 gli sconti (sovraprezzi) automatici non sono calcolati. Impossibile registrare. Per calcolare automaticamente gli sconti (sovraprezzi) registrate il documento dal modulo del documento.';
				|pl = 'W dokumencie %1 nie obliczono automatycznych rabatów (marży). Zatwierdzenie jest niemożliwe. Aby obliczyć automatyczne rabaty (marże) zatwierdź dokument z formularza dokumentu.';
				|tr = 'Otomatik indirimler (marj) %1 belgesinde hesaplanmamıştır. Gerçekleştirilemez. Otomatik indirimleri (marj) hesaplamak için, belgeyi belge formundan çalıştırın.'"),
			Ref);
		
			CommonClientServer.MessageToUser(
				ErrorText,
				Ref,
				,
				,
				Cancel);
		
	EndIf;
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Services, PriceIncludesVAT);
	
	RegistrationParameters = Documents.CustomerInvoiceServices.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	TMCommonUse.ChangeDocumentConsistencyAttribute(
		ThisObject,
		WriteMode);
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Services,InventoryKinds");
	
	CustomerInvoiceServicesLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Var HeaderAttributes;
	
	Author = Users.CurrentUser();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		// Filling out the list of orders from the form.
		If FillingData.Property("DocumentBasis")
			And (TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.SalesOrder") 
			Or TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
			Or TypeOf(FillingData.DocumentBasis) = Type("Array")) Then
			
			FillingData.Property("HeaderAttributes", HeaderAttributes);
			
			FillInDocumentBasedOnCustomerSOrder(FillingData.DocumentBasis, HeaderAttributes);
			
		Else
			
			FillInSelectionDocument(FillingData);
			
		EndIf;
		
	ElsIf FillInDataType = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		
		FillInDocumentOnBasisOfSaleTransaction(FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.SalesOrder")
		Or FillInDataType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		
		Date = OrdersServer.GetMinimumOrderShipmentDate(FillingData);
		FillInDocumentBasedOnCustomerSOrder(FillingData);
		
	ElsIf FillInDataType = Type("CatalogRef.TermsOfSale") Then
		
		FillInDocumentOnBasisOfIndividualAgreementWithClient(FillingData);
		
	EndIf;
	
	InitializeSalesConditions();
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);

	FillOutBankAccounts();
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	ResponsiblePersonsServer.InstallManager(
		ThisObject, SalesServer.DocumentBasis(ThisObject, "InvoiceByOrders, SalesOrder, Services.SalesOrder"));
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(ThisObject, "Manager",, True);
	
	InitializeDocument(FillingData);
	
	If Not ValueIsFilled(ForeignCurrencyTransaction) Then
		CurrencyOfPayment  = CashServer.GetPaymentCurrency(PaymentMethod, CompanyBankAccount, CashAccount);
		ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency(CurrencyOfPayment, Organization);
	EndIf;
	
	If ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice And Not InvoiceByOrders 
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments Then
		
		If ValueIsFilled(Terms) Then
			DetailsOfAgreement = Common.ObjectAttributesValues(Terms,"ContractsAreUsed,FinancialAccountingGroup");
			If DetailsOfAgreement.ContractsAreUsed 
				And ValueIsFilled(Contract) Then
				FinancialAccountingGroup = Common.ObjectAttributeValue(Contract,"FinancialAccountingGroup");
			Else
				FinancialAccountingGroup = DetailsOfAgreement.FinancialAccountingGroup;
			EndIf;
		ElsIf ValueIsFilled(Contract) Then
			FinancialAccountingGroup = Common.ObjectAttributeValue(Contract,"FinancialAccountingGroup");
		EndIf;
		
	EndIf;
	
	CustomerInvoiceServicesLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "Services";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel, CheckParameters);
		
	ContractsAreUsed = TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed");
	
	If Not ValueIsFilled(Terms) Or Not ContractsAreUsed Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	// The line code must be filled in if the certificate of work performed on the order
	If Not ValueIsFilled(SalesOrder) Then
		NotCheckedAttributeArray.Add("Services.RowCode");
	EndIf;
	
	BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject,Cancel);
	
	If Not InvoiceByOrders And Not UserRightsCached.CreatingReportsOfCompletedWorkWithoutOrder() Then
		
		ErrorText = NStr("vi = 'Không có quyền tạo ra một biên bản hoàn thành công việc mà không có đơn hàng';
						|ru = 'Нет прав на создание акта выполненных работ без заказа';
						|en = 'No rights to create a ""Customer invoice — Services"" without order'; fa = 'No rights to create a ""Customer invoice — Services"" without order';
						|it = 'Nessun diritto di creare un verbale di consegna dei lavori effettuati senza un ordine';
						|pl = 'Brak uprawnień na utworzenie protokółu odbioru wykonania prac bez zamówienia';
						|tr = 'Siparişsiz gerçekleştirilen işler raporu oluşturma hakkı yok'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			Ref,
			,
			,
			Cancel);
			
	EndIf;
	
	SalesServer.CheckShipmentBan(Partner, Cancel);
	
	VATAccountingLocalization.CheckServicesAtCommitteeSVATRate(ThisObject, Cancel, "Services");
	
	CustomerInvoiceServicesLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RegistrationParameters = Documents.CustomerInvoiceServices.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	
	CustomerInvoiceServicesLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RegistrationParameters = Documents.CustomerInvoiceServices.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
	CustomerInvoiceServicesLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	Approved   = False;
	SalesOrder = Undefined;
	InvoiceByOrders = False;
	
	If GetFunctionalOption("ToUseTermsOfSales") And ValueIsFilled(Terms) Then
		SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
		If SalesTermsAndConditions.AgreementStatus = Enums.StatusesOfTermsOfSales.Closed Then
			Terms = Undefined;
		EndIf;
	EndIf;
	
	For Each CurRow In Services Do
		
		CurRow.SalesOrder = Undefined;
		CurRow.RowCode    = 0;
		
	EndDo;
	DefaultAssignment = LinesOfBusinessServer.PushingAssignment(LineOfBusiness);
	InvoicesServer.FillInAssignmentsInTablePart(Services, DefaultAssignment);
	
	DiscountsAreCalculated = False;
	DiscountsMarkupsFillingServer.CancelDiscounts(ThisObject, "Services", True, True, True);
	
	For Each TSRow In Services Do
		TSRow.AmountOfBonusPointsToDeduction = 0;
		TSRow.AmountOfBonusPointsToDeductionInCurrency = 0;
	EndDo;

	InitializeDocument();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Services");
	
	CustomerInvoiceServicesLocalization.OnCopy(ThisObject, CopiedObject);

	Author = Users.CurrentUser();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	CustomerInvoiceServicesLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInDocumentBasedOnCustomerSOrder(Val DocumentBasis, OrderDetails = Undefined)
	
	BasisType = TypeOf(DocumentBasis);
	SelectByOrder_ = True;
	
	InvoiceByOrders = True;
	
	If BasisType = Type("DocumentRef.SalesOrder") Then
	
		Query = New Query(
		"SELECT
		|	SalesOrder.Ref AS SalesOrder,
		|	SalesOrder.Partner AS Partner,
		|	SalesOrder.Counterparty AS Counterparty,
		|	SalesOrder.Contract AS Contract,
		|	SalesOrder.Organization AS Organization,
		|	SalesOrder.PaymentMethod AS PaymentMethod,
		|	SalesOrder.Terms AS Terms,
		|	SalesOrder.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	SalesOrder.SalesOpportunity AS SalesOpportunity,
		|	SalesOrder.Currency AS Currency,
		|	SalesOrder.Currency AS ARAPCurrency,
		|	SalesOrder.PaymentSchedule AS PaymentSchedule,
		|	SalesOrder.PriceIncludesVAT AS PriceIncludesVAT,
		|	SalesOrder.VATTaxation AS VATTaxation,
		|	SalesOrder.Status AS DocumentStatus,
		|	SalesOrder.BankAccount AS CompanyBankAccount,
		|	SalesOrder.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	SalesOrder.LoyaltyCard AS LoyaltyCard,
		|	SalesOrder.DateOfShipment AS DateOfShipment,
		|	(NOT SalesOrder.Posted) AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|			OR SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsEconomicOperation,
		|	SalesOrder.DiscountsMarkups.(
		|		ConnectionKey,
		|		DiscountMarkup,
		|		Sum
		|	) AS DiscountsMarkups,
		|	SalesOrder.BusinessOperation AS BusinessOperation,
		|	SalesOrder.Department AS Department,
		|	SalesOrder.ContactPerson AS ContactPerson,
		|	SalesOrder.ARAPObjectSettings AS ARAPObjectSettings,
		|	SalesOrder.LineOfBusiness AS LineOfBusiness,
		|	SalesOrder.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
		|	SalesOrder.UISStateContractStep AS UISStateContractStep,
		|	SalesOrder.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref = &SalesOrder");
		
		Query.SetParameter("SalesOrder", DocumentBasis);
		
		QueryResult = Query.Execute();
		
		OrderDetails = QueryResult.Select();
		OrderDetails.Next();
		
		CheckCorrectnessOfBusinessTransactionOfFoundationDocument(
			OrderDetails.ThereAreErrorsEconomicOperation,
			OrderDetails.BusinessOperation);
		
		Documents.SalesOrder.CheckPossibilityOfEnteringBasedOn(
			OrderDetails.SalesOrder,
			OrderDetails.DocumentStatus,
			OrderDetails.ThereAreErrorsPosted);

		// Filling in the header
		FillPropertyValues(ThisObject, OrderDetails);
		If OrderDetails.ThisIsOrderAsInvoice Then
			If Not ValueIsFilled(Date) Then
				Date = CurrentSessionDate();
			EndIf;
		EndIf;
	ElsIf BasisType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	ReturnRequest.Ref AS SalesOrder,
		|	ReturnRequest.Partner AS Partner,
		|	ReturnRequest.Counterparty AS Counterparty,
		|	ReturnRequest.Contract AS Contract,
		|	ReturnRequest.Organization AS Organization,
		|	ReturnRequest.PaymentMethod AS PaymentMethod,
		|	ReturnRequest.Terms AS Terms,
		|	ReturnRequest.SalesOpportunity AS SalesOpportunity,
		|	ReturnRequest.Currency AS Currency,
		|	ReturnRequest.Currency AS ARAPCurrency,
		|	ReturnRequest.PaymentSchedule AS PaymentSchedule,
		|	ReturnRequest.PriceIncludesVAT AS PriceIncludesVAT,
		|	ReturnRequest.VATTaxation AS VATTaxation,
		|	ReturnRequest.BusinessOperation AS BusinessOperation,
		|	ReturnRequest.Status AS DocumentStatus,
		|	ReturnRequest.BankAccount AS CompanyBankAccount,
		|	ReturnRequest.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	ReturnRequest.LoyaltyCard AS LoyaltyCard,
		|	ReturnRequest.DateOfShipment AS DateOfShipment,
		|	(NOT ReturnRequest.Posted) AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|				OR ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsEconomicOperation,
		|	ReturnRequest.DiscountsMarkups.(
		|		ConnectionKey,
		|		DiscountMarkup,
		|		Sum
		|	) AS DiscountsMarkups,
		|	ReturnRequest.ContactPerson AS ContactPerson,
		|	ReturnRequest.ARAPObjectSettings AS ARAPObjectSettings,
		|	ReturnRequest.LineOfBusiness AS LineOfBusiness,
		|	ReturnRequest.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
		|	ReturnRequest.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
		|WHERE
		|	ReturnRequest.Ref = &DocumentBasis";
		
		Query.SetParameter("DocumentBasis", DocumentBasis);
		
		OrderDetails = Query.Execute().Select();
		OrderDetails.Next();
		
		CheckCorrectnessOfBusinessTransactionOfFoundationDocument(
			OrderDetails.ThereAreErrorsEconomicOperation,
			OrderDetails.BusinessOperation);
		
		Documents.RequestForReturnOfGoodsFromCustomer.CheckPossibilityOfEnteringBasedOn(
			OrderDetails.SalesOrder,
			OrderDetails.DocumentStatus,
			OrderDetails.ThereAreErrorsPosted);
		
		// Filling in the header.
		FillPropertyValues(ThisObject, OrderDetails);
		If OrderDetails.ThisIsOrderAsInvoice Then
			If Not ValueIsFilled(Date) Then
				Date = CurrentSessionDate();
			EndIf;
		EndIf;
	ElsIf BasisType = Type("Array") Then
		
		// Filling in the header.
		FillPropertyValues(ThisObject, OrderDetails);
		Currency = ARAPCurrency;
		CompanyBankAccount = OrderDetails.BankAccount;
		
	EndIf;
	
	If BasisType = Type("Array") Then
		AnArrayOfOrders = DocumentBasis;
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(SalesOrder);
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("UseAdvancedFeaturesOfSalesOrder", Not OrderDetails.ThisIsOrderAsInvoice);
	// Filling out incl. services.
	Documents.CustomerInvoiceServices.FillByOrderBalances(
		ThisObject,
		Services,
		DiscountsMarkups,
		BonusPointAccrual,
		AnArrayOfOrders,
		FillParameters);
	
	OrdersServer.FillInOrderInOrderHeaderInTableSection(SalesOrder, Services, "SalesOrder");
	
	StructureBase = Documents.CustomerInvoiceServices.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, StructureBase);
	
EndProcedure

Procedure FillInDocumentOnBasisOfSaleTransaction(Val Basis)
	
	Query = New Query(
		"SELECT
		|	SalesOpportunitiesToCustomer.Ref AS SalesOpportunity,
		|	SalesOpportunitiesToCustomer.Partner AS Partner,
		|	SalesOpportunitiesToCustomer.CustomerTermsOfSales AS Terms,
		|	SalesOpportunitiesToCustomer.CustomerTermsOfSales.BusinessOperation AS BusinessOperation,
		|	SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactPerson AS ContactPerson
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer.PartnersAndContactPersons AS SalesOpportunitiesToCustomerPartnersAndContactPersons
		|		ON (SalesOpportunitiesToCustomerPartnersAndContactPersons.Ref = SalesOpportunitiesToCustomer.Ref)
		|			AND (SalesOpportunitiesToCustomerPartnersAndContactPersons.Partner = SalesOpportunitiesToCustomer.Partner)
		|			AND (SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactPerson <> VALUE(Catalog.ContactPersonsForPartners.EmptyRef))
		|WHERE
		|	SalesOpportunitiesToCustomer.Ref = &Basis");
		
	Query.SetParameter("Basis",Basis);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	If ValueIsFilled(Selection.Terms) And 
		Selection.BusinessOperation <> Enums.BusinessTransactions.SaleToCustomer  Then
		
		ExceptionText = NStr("vi = 'Chỉ có thể nhập trên cơ sở theo thỏa thuận với giao dịch ""Bán hàng cho khách"".';
							|ru = 'Ввод на основании возможен только по соглашению с операцией ""Реализация клиенту"".';
							|en = 'Generation from base document ""Vendor price registration"" basis is allowed only for vendors and competitors.'; fa = 'Generation from base document ""Vendor price registration"" basis is allowed only for vendors and competitors.';
							|it = 'L''immissione in base alla causale è possibile solo previo accordo con operazione ""Realizzo al cliente"".';
							|pl = 'Wprowadzenie na podstawie jest możliwe tylko według umowy z operacją ""Реализация клиенту"".';
							|tr = 'Temele ilişkin giriş yalnızca ""Müşteriye satış"" işlemi ile mutabık kalınması halinde mümkündür.'");
		Raise ExceptionText;
		
	EndIf;
	
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfSaleTransaction(Selection.Partner);
	FillPropertyValues(ThisObject, Selection);
	
	If GetFunctionalOption("ToUseTermsOfSales") Then
		
		If ValueIsFilled(Terms) Then
			
			AgreementOperation = Common.ObjectAttributeValue(Terms, "BusinessOperation");
			DocumentOperations  = TMCommonUse.PermissibleBusinessOperationsOfDocument("CustomerInvoiceServices");
			
			If DocumentOperations.Find(AgreementOperation) <> Undefined Then
				FillInTermsOfSalesUnderAgreement();
			EndIf;
			
		Else
			FillInDefaultSalesConditions();
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfIndividualAgreementWithClient(Val DocumentBasis)
	
	Query = New Query(
		"SELECT
		|	CustomerTermsOfSales.Ref                AS Terms,
		|	CustomerTermsOfSales.Partner               AS Partner,
		|	CustomerTermsOfSales.BusinessOperation AS BusinessOperation,
		|	CustomerTermsOfSales.ContactPerson        AS ContactPerson,
		|
		|	CustomerTermsOfSales.Status                AS DocumentStatus,
		|	CASE
		|		WHEN
		|			CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
		|		THEN
		|			FALSE
		|		ELSE
		|			TRUE
		|	END AS ThereAreErrorsStatus,
		|	CustomerTermsOfSales.Standard_ AS ThereAreErrorsTypical,
		|	CustomerTermsOfSales.LineOfBusiness AS LineOfBusiness
		|
		|FROM
		|	Catalog.TermsOfSale  AS CustomerTermsOfSales
		|WHERE
		|	CustomerTermsOfSales.Ref = &DocumentBasis
		|");
		
	Query.SetParameter("DocumentBasis", DocumentBasis);
		
	QueryResultsArray = Query.ExecuteBatch();
	QueryResult = QueryResultsArray[0]; // QueryResult
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	SalesServer.CheckPossibilityOfEnteringOnBasisOfAgreement("CustomerInvoiceServices", Selection.BusinessOperation);
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfTermsOfSales.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfAgreement(Selection.ThereAreErrorsTypical);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.Terms,
		Selection.DocumentStatus,
		,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(ThisObject, Selection);
	FillInTermsOfSalesUnderAgreement();
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)

	If FillingData.Property("HeaderAttributes") Then
		FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
	EndIf;
	
	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		If GetFunctionalOption("ToUseTermsOfSales") Then
			FillInDefaultSalesConditions();
		EndIf;
		
	EndIf;
	
	If FillingData.Property("Services") Then
		For Each CurRow In FillingData.Services Do
			
			ServiceLine_1 = Services.Add();
			FillPropertyValues(ServiceLine_1, CurRow);
			
			ServiceLine_1.Content = ProductsClientServer.PresentationOfProductsForPrinting(
										CurRow.ProductFullName,
										CurRow.CharacteristicFullName);
		EndDo;
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	Organization               = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(ARAPCurrency) Then
		ARAPCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	Department             = SettingsValueCached.UserDivision(Manager, Department);

	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		OrganizationSDefaultAccountParameters(), CompanyBankAccount);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization = Organization;
	ParametersStructure.CashAccount 		= CashAccount;
	CashAccount                     = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		CounterpartyBankAccount);
	
	FillParameters = Documents.CustomerInvoiceServices.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	// Fill in the bid taking into account the current date of the document. We recalculate the related details of the tabular part.
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = ValueIsFilled(FillingData);

	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
		
	BatchProcessingOfTablePartServer.TreatTS(Services, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount","Count");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_, QuantityName", False, False, "Count"));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAmountOfSettlements", Undefined);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Services,
		Undefined);
	
EndProcedure

Procedure InitializeSalesConditions()
	
	If Not GetFunctionalOption("ToUseTermsOfSales") And Not InvoiceByOrders Then
		FillInDefaultSalesConditions();
	EndIf;
	
EndProcedure

Procedure FillOutBankAccounts()
	
	If ValueIsFilled(CompanyBankAccount) And ValueIsFilled(CounterpartyBankAccount) Then
		Return;
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Contract,
		?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
		?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
	
	If ValueIsFilled(Organization) And Not ValueIsFilled(CompanyBankAccount) Then
		ParametersOfAccount = OrganizationSDefaultAccountParameters();
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(Counterparty) And Not ValueIsFilled(CounterpartyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
EndProcedure

Function OrganizationSDefaultAccountParameters()
	
	If ValueIsFilled(Organization) Then
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	Else
		ComplCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersOfAccount.LineOfBusiness = LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = ComplCurrency;
	
	Return ParametersOfAccount;
	
EndFunction

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
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject, TempTablesManager, Cancel, FillParameters);
		
		NamesOfGroupingColumns =
			"ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, VATRate, SalesOrder, SetAccountingDimension, ARAPObject";
		NamesOfSummationColumns =
			"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount";
		
		InventoryKinds.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
		
		FillInAdditionalStockTypes();
		
	EndIf;
	
EndProcedure

Procedure FillInAdditionalStockTypes()
	
	NamesOfGroupingColumns =
		"ItemsLocationAttributes, SetAccountingDimension, ProductsInSet, ItemVariantOfSet,
		| SalesOrder, VATRate, Price, ARAPObject";
	NamesOfSummationColumns =
		"Count, AmountIncludingVAT, VATAmount, ManualDiscount, DiscountMarkupAmount, AmountARAP";
	UnloadedColumns = NamesOfGroupingColumns + ", " + NamesOfSummationColumns;
	
	GoodsTable = Services.Unload(, UnloadedColumns);
	GoodsTable.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
	
	Aggregates = New Structure(NamesOfSummationColumns);
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, SalesOrder");
	
	For Each RowOfGoods In GoodsTable Do
		
		FillPropertyValues(Aggregates, RowOfGoods);
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Aggregates);
		
		If ValueIsFilled(RowOfGoods.SalesOrder) And Aggregates.Count <> 0 Then
			TheStructureOfTheSearch.SalesOrder = Undefined;
			FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Aggregates);
		EndIf;
		
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Aggregates)
	
	For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
		
		If InventoryLine.Count = 0 Then
			Continue;
		EndIf;
		
		QuantityPerRow = Min(Aggregates.Count, InventoryLine.Count);
		
		NewRow = InventoryKinds.Add();
		FillPropertyValues(NewRow, InventoryLine);
		
		FillableProperties = "Price, VATRate, SetAccountingDimension, ARAPObject";
		FillPropertyValues(NewRow, RowOfGoods, FillableProperties);
		
		NewRow.Count = QuantityPerRow;
		NewRow.QuantityByGBRN= QuantityPerRow * InventoryLine.QuantityByGBRN / InventoryLine.Count;
		NewRow.SalesOrder = ?(ValueIsFilled(RowOfGoods.SalesOrder), RowOfGoods.SalesOrder, Undefined);
		
		If Aggregates.Count <> 0 Then
			NewRow.AmountARAP			= QuantityPerRow * Aggregates.AmountARAP
														/ Aggregates.Count;
			NewRow.ManualDiscount			= QuantityPerRow * Aggregates.ManualDiscount
														/ Aggregates.Count;
			NewRow.DiscountMarkupAmount	= QuantityPerRow * Aggregates.DiscountMarkupAmount
														/ Aggregates.Count;
		EndIf;
		
		If InventoryLine.Count <> 0 Then
			NewRow.AmountIncludingVAT	= QuantityPerRow * Aggregates.AmountIncludingVAT / Aggregates.Count;
			NewRow.VATAmount	= QuantityPerRow * Aggregates.VATAmount / Aggregates.Count;
		EndIf;
		
		InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
		InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
		InventoryLine.AmountIncludingVAT			= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
		InventoryLine.VATAmount			= InventoryLine.VATAmount - NewRow.VATAmount;
		
		For Each KeyAndValue In Aggregates Do
			Aggregates[KeyAndValue.Key] = Aggregates[KeyAndValue.Key] - NewRow[KeyAndValue.Key];
		EndDo;
		
		If Aggregates.Count = 0 Then
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.CustomerInvoiceServices.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.CustomerInvoiceServices.CollectionOfTabularPartsOfGoods();
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Services;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
		Enums.BusinessTransactions.SaleToCustomer, Undefined, Department, Undefined);
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Delete("Series");
	FieldsNames.Delete("BatchesIndicationStatus");
	FieldsNames.Insert("Work_5", "Department");
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	InformationRegisters.SetAccountingDimension.FillInCollection(GoodsTable);
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckCorrectnessOfBusinessTransactionOfFoundationDocument(ThereAreErrorsEconomicOperation, BusinessOperation)

	If ThereAreErrorsEconomicOperation Then
		
		ErrorText = NStr("vi = 'Không thể nhập biên bản bàn giao dịch vụ trên cơ sở chứng từ có giao dịch kinh tế %BusinessOperation%.';
						|ru = 'Ввод акта выполненных работ на основании документа с хозяйственной операцией %BusinessOperation% невозможен.';
						|en = 'Cannot register a ""Customer invoice — Services"" based on the document with business transaction %BusinessOperation%.'; fa = 'Cannot register a ""Customer invoice — Services"" based on the document with business transaction %BusinessOperation%.';
						|it = 'Non è possibile inserire un verbale di consegna dei lavori effettuati sulla base di un documento con operazione commerciale %BusinessOperation%.';
						|pl = 'Wprowadzenie protokółu odbioru wykonania prac na podstawie dokumentu z operacją gospodarczą %BusinessOperation% jest niemożliwe.';
						|tr = '%BusinessOperation% işlemli bir belgeye dayalı olarak bir iş beyanı girmek mümkün değildir.'");
		ErrorText = StrReplace(ErrorText, "%BusinessOperation%", BusinessOperation);
		
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, VATTaxation";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	(SELECT
	|		TableOfGoods.SalesOrder AS SalesOrder,
	|		TableOfGoods.ARAPObject AS ARAPObject,
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate AS VATRate,
	|		TableOfGoods.Price AS Price,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.AmountARAP AS AmountARAP,
	|		TableOfGoods.ManualDiscount AS ManualDiscount,
	|		TableOfGoods.DiscountMarkupAmount AS DiscountMarkupAmount
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.SalesOrder AS SalesOrder,
	|		TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		TableTypesOfStocks_.Price AS Price,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount AS VATAmount,
	|		-TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|		-TableTypesOfStocks_.ManualDiscount AS ManualDiscount,
	|		-TableTypesOfStocks_.DiscountMarkupAmount AS DiscountMarkupAmount
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ARAPObject,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.Price
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|		OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|		OR SUM(TableOfGoods.VATAmount) <> 0
	|		OR SUM(TableOfGoods.AmountARAP) <> 0
	|		OR SUM(TableOfGoods.ManualDiscount) <> 0
	|		OR SUM(TableOfGoods.DiscountMarkupAmount) <> 0
	|");
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.SelectionOfStockTypes_.VATTaxation = VATTaxation;
	FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	
	Return FillParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
