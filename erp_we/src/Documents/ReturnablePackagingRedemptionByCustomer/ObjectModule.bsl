#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function generates temporary document data
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	&Date				AS Date,
	|	&Organization		AS Organization,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	&Partner			AS Partner,
	|	&Counterparty			AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&Contract			AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	&VATTaxation	AS VATTaxation,
	|	FALSE 				AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) BusinessOperation,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END				AS Department,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END				AS Manager,
	|	CASE
	|		WHEN SalesOpportunitiesToCustomer.EnabledGoodsAssignmentInSalesOpportunity
	|				AND &GenerateInventoryOwnerAttributesBySalesOpportunities
	|			THEN &SalesOpportunity
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END				AS SalesOpportunity,
	|	UNDEFINED		AS DocumentSalesOfGoodsAndServices,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON BusinessStructure.Ref = &Department
	|		
	|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		ON SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
	|
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.Count					AS Count,
	|	VALUE(Catalog.Warehouses.EmptyRef)	AS Warehouse,
	|	CASE
	|		WHEN TableOfGoods.DocumentSalesOfGoodsAndServices = VALUE(Document.CustomerInvoice.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TableOfGoods.DocumentSalesOfGoodsAndServices
	|	END										AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.Sum + (TableOfGoods.VATAmount * &PriceIncludesVAT) AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	TableOfGoods.AmountARAP			AS AmountARAP,
	|	0											AS CommissionAmount,
	|	0											AS AmountVATRemuneration,
	|	&SalesOpportunity										AS SalesOpportunity,
	|	&FieldTextTableOfGoodsCCDNumber_			AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.Count					AS Count,
	|	VALUE(Catalog.Warehouses.EmptyRef)	AS Warehouse,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	0											AS BatchesIndicationStatus,
	|	TableOfGoods.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	TableOfGoods.AmountARAP			AS AmountARAP,
	|	0											AS CommissionAmount,
	|	0											AS AmountVATRemuneration,
	|	&SalesOpportunity										AS SalesOpportunity,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	FALSE										AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber						AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|	CASE
	|		WHEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices = VALUE(Document.CustomerInvoice.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|	END											AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.OriginWarehouse				AS OriginWarehouse,
	|	&SalesOpportunity											AS SalesOpportunity,
	|	TableTypesOfStocks_.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END											AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount						AS VATAmount,
	|	TableTypesOfStocks_.AmountARAP			AS AmountARAP
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|///////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	Dimension.Series									AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|	UNDEFINED									AS RecipientInventoryOwnerAttribute,
	|	Dimension.StorageLocation							AS Warehouse,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.OriginWarehouse				AS OriginWarehouse,
	|	&SalesOpportunity											AS SalesOpportunity,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount						AS VATAmount,
	|	TableTypesOfStocks_.AmountARAP			AS AmountARAP,
	|	&InventoryOwnerAttributesAreSpecifiedManually						AS InventoryOwnerAttributesAreSpecifiedManually
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
	
	Query.SetParameter("Ref",												Ref);
	Query.SetParameter("Date",												Date);
	Query.SetParameter("Organization",										Organization);
	Query.SetParameter("Counterparty",											Counterparty);
	Query.SetParameter("Partner",											Partner);
	Query.SetParameter("Manager",											Manager);
	Query.SetParameter("Contract",											Contract);
	Query.SetParameter("SalesOpportunity",												SalesOpportunity);
	Query.SetParameter("Department",										Department);
	Query.SetParameter("VATTaxation",									VATTaxation);
	Query.SetParameter("PriceIncludesVAT",									?(PriceIncludesVAT, 0, 1));
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers",	GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities",					GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter("TableOfGoods",										Goods);
	Query.SetParameter("TableTypesOfStocks_",									InventoryKinds);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually",							InventoryOwnerAttributesAreSpecifiedManually);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
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

// Fills in the terms of sales in the customer's order
//
// Parameters:
//	SalesTermsAndConditions - Structure - Structure to fill in.
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
		ParametersStructure.Organization    			= Organization;
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
	
	If Counterparty <> TheCounterpartyPriorToTheChange Then
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
		OrganizationSDefaultAccountParameters(),
		CompanyBankAccount);
	
	DepositForPackageIsRequired = SalesTermsAndConditions.PackageDepositIsRequired;
	
	If ValueIsFilled(SalesTermsAndConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = SalesTermsAndConditions.FinancialAccountingGroup;
	EndIf;
	
	StartDate = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization, ,Contract);
	
EndProcedure

// Fills in the default sales terms in the repurchase of returnable containers
//
// Parameters:
//	RecalculatePrices_ - Boolean - indicates the need to re-fill prices.
//
Procedure FillInDefaultSalesConditions(RecalculatePrices_ = True) Export
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	If ValueIsFilled (Partner) Or Not ToUseTermsOfSales Then
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
			Partner,
			New Structure("SelectedAgreement, BusinessTransactions, EmptyDocumentLink", 
				Terms, 
				Enums.BusinessTransactions.SaleToCustomer,
				Documents.ReturnablePackagingRedemptionByCustomer.EmptyRef()));
		
		TheCounterpartyPriorToTheChange = Counterparty;
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales Or 
				(Terms <> DefaultSalesTerms.Terms And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				TheCounterpartyPriorToTheChange = Counterparty;
				
				FillParameters = Documents.ReturnablePackagingRedemptionByCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
				VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
				
				If ToUseTermsOfSales And RecalculatePrices_ Then
					FillParameters = New Structure();
					FillParameters.Insert("Date", Date);
					FillParameters.Insert("Organization", Organization);
					FillParameters.Insert("Currency", Currency);
					FillParameters.Insert("Terms", Terms);
					FillParameters.Insert("VATTaxation", VATTaxation);
					FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind");
	
					StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
					
					ActionsWithModifiedStrings = New Structure();
					ActionsWithModifiedStrings.Insert("RecalculateAmount", "NumberOfPackages");
					ActionsWithModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
					ActionsWithModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					ActionsWithModifiedStrings.Insert("ClearAmountOfSettlements", "NumberOfPackages");
					
					EnterprisePricesFillingServer.FillInPrices(
						Goods, // Table part
						, // Array of rows or selection structure
						FillParameters, // The fill parameters
						ActionsWithModifiedStrings // The structure of the action with the changed strings
						);
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

EndProcedure

// Fills in the terms of sales under the agreement in the sale of goods and services
//
Procedure FillInTermsOfSalesUnderAgreement() Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
	FillParameters = Documents.ReturnablePackagingRedemptionByCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	FillParameters = New Structure();
	FillParameters.Insert("Date", Date);
	FillParameters.Insert("Organization", Organization);
	FillParameters.Insert("Currency", Currency);
	FillParameters.Insert("Terms", Terms);
	FillParameters.Insert("VATTaxation", VATTaxation);
	FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	ActionsWithModifiedStrings = New Structure();
	ActionsWithModifiedStrings.Insert("RecalculateAmount", "NumberOfPackages");
	ActionsWithModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	ActionsWithModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	ActionsWithModifiedStrings.Insert("ClearAmountOfSettlements", "NumberOfPackages");
	
	EnterprisePricesFillingServer.FillInPrices(
		Goods, // Table part
		, // Array of rows or selection structure
		FillParameters, // The fill parameters
		ActionsWithModifiedStrings // The structure of the action with the changed strings
		);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.ReturnablePackagingRedemptionByCustomer.CollectionOfTabularPartsOfGoods.
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
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Goods, PriceIncludesVAT);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	RegistrationParameters = Documents.ReturnablePackagingRedemptionByCustomer.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
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
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
	ReturnablePackagingRedemptionByCustomerLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Var HeaderAttributes;
	
	Author = Users.CurrentUser();
	
	FilledInBasedOnDocument = False;

	FillInDataType = TypeOf(FillingData);

	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("FillInTransferredContainer") Then
			FillInDocumentOnBasisOfTransferredContainer(FillingData);
			FilledInBasedOnDocument = True;
		Else
			FillInSelectionDocument(FillingData);
		EndIf;

	ElsIf FillInDataType = Type("CatalogRef.TermsOfSale") Then
		FillInDocumentOnBasisOfIndividualAgreementWithClient(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.CustomerInvoice") Then
		FillInDocumentBasedOnSaleOfGoodsServices(FillingData);
		FilledInBasedOnDocument = True;
	EndIf;
	
	If Not FilledInBasedOnDocument Then
		InitializeSalesConditions();
	EndIf;
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	FillOutBankAccounts();
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	
	If Not ValueIsFilled(ForeignCurrencyTransaction) Then
		CurrencyOfPayment              = CashServer.GetPaymentCurrency(PaymentMethod, CompanyBankAccount, CashAccount);
		ForeignCurrencyTransaction             = ARAPAccountingServer.GetPaidInDefaultCurrency(CurrencyOfPayment, Organization);
	EndIf;
		
	ReturnablePackagingRedemptionByCustomerLocalization.Filling(ThisObject, FillingData, StandardProcessing);

	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	If Not ValueIsFilled(Terms) Or
		 Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;

	BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	ReturnablePackagingRedemptionByCustomerLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ReturnablePackagingRedemptionByCustomerLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	RegistrationParameters = Documents.ReturnablePackagingRedemptionByCustomer.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ReturnablePackagingRedemptionByCustomerLocalization.UndoPosting(ThisObject, Cancel);
	
	RegistrationParameters = Documents.ReturnablePackagingRedemptionByCustomer.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	
	InventoryKinds.Clear();
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	ReturnablePackagingRedemptionByCustomerLocalization.OnCopy(ThisObject, CopiedObject);

 	ARAPAccountingServer.OnCopy(ThisObject);
 	Author = Users.CurrentUser();
 	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	Prefix = TMCommonUseCached.AdditionalPrefixOfNumeratorDocumentsOfSaleOfGoods();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ReturnablePackagingRedemptionByCustomerLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInDocumentOnBasisOfTransferredContainer(Val DetailsOfFillingInForm)
	
	FillPropertyValues(ThisObject, DetailsOfFillingInForm.HeaderAttributes);
	
	If GetFunctionalOption("ToUseTermsOfSales") Then
		If Not ValueIsFilled(Terms) Then
			FillInDefaultSalesConditions(False);
		EndIf;
	Else
		
		If DetailsOfFillingInForm.HeaderAttributes.PriceIncludesVAT = Undefined Then
			
			DetailsOfDefaultPrice = Catalogs.TypesOfPrices.PriceTypeAndPriceIncludesVATAttributeByDefault(
				New Structure("UseWhileSellingToCustomers", True),
				Documents.ReturnablePackagingRedemptionByCustomer.EmptyRef());
			
			FillPropertyValues(ThisObject, DetailsOfDefaultPrice);
		EndIf;
		
	EndIf;
	
	DepositForPackageIsRequired = DetailsOfFillingInForm.HeaderAttributes.DepositForPackageIsRequired;
	
	FillParameters = Documents.ReturnablePackagingRedemptionByCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	If IsTempStorageURL(DetailsOfFillingInForm.ContainerAddressInTemporaryStorage) Then
		
		TransferredPackage = GetFromTempStorage(DetailsOfFillingInForm.ContainerAddressInTemporaryStorage);
		Goods.Load(TransferredPackage);
		
		StructureOfActions = New Structure;
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		
		BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
		
		For Each CurrentRow In Goods Do
			
			CurrentRow.AmountIncludingVAT = CurrentRow.Sum;
			CurrentRow.NumberOfPackages = CurrentRow.Count;
			
			PriceManagementSystem.RecalculateAmountsInRowWithVAT(CurrentRow, PriceIncludesVAT, False, False, True);
			
		EndDo;
		
	EndIf;
	
	StructureBase = Documents.ReturnablePackagingRedemptionByCustomer.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, StructureBase);
	
EndProcedure

Procedure FillInDocumentOnBasisOfIndividualAgreementWithClient(Val DocumentBasis)
	
	Query = New Query(
		"SELECT
		|	CustomerTermsOfSales.Ref                AS Terms,
		|	CustomerTermsOfSales.Partner               AS Partner,
		|	CustomerTermsOfSales.ContactPerson        AS ContactPerson,
		|
		|	CustomerTermsOfSales.Status                AS DocumentStatus,
		|	CustomerTermsOfSales.LineOfBusiness AS LineOfBusiness,
		|	CASE
		|		WHEN
		|			CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
		|		THEN
		|			FALSE
		|		ELSE
		|			TRUE
		|	END AS ThereAreErrorsStatus,
		|	CustomerTermsOfSales.Standard_ AS ThereAreErrorsTypical
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

Procedure FillInDocumentBasedOnSaleOfGoodsServices(Val DocumentBasis)
	
	Query = New Query(
		"SELECT
		|	CustomerInvoice.Ref                       AS DocumentBasis,
		|	CustomerInvoice.Currency                       AS Currency,
		|	CustomerInvoice.ARAPCurrency         AS ARAPCurrency,
		|	CustomerInvoice.Partner                      AS Partner,
		|	CustomerInvoice.Terms                   AS Terms,
		|	CustomerInvoice.Organization                  AS Organization,
		|	CustomerInvoice.Department                AS Department,
		|	CustomerInvoice.FinancialAccountingGroup       AS FinancialAccountingGroup,
		|	CustomerInvoice.Contract                      AS Contract,
		|	CustomerInvoice.Counterparty                   AS Counterparty,
		|	CustomerInvoice.SalesOpportunity                       AS SalesOpportunity,
		|	CustomerInvoice.ContactPerson               AS ContactPerson,
		|	CustomerInvoice.PriceIncludesVAT              AS PriceIncludesVAT,
		|	CustomerInvoice.VATTaxation           AS VATTaxation,
		|	CustomerInvoice.PackageDepositIsRequired         AS DepositForPackageIsRequired,
		|	CustomerInvoice.ARAPObjectSettings              AS ARAPObjectSettings,
		|	NOT CustomerInvoice.Posted                  AS ThereAreErrorsPosted,
		|	NOT CustomerInvoice.ToReturnReusablePackage AS ThereAreErrorsToReturnMultiTurnContainer,
		|	CustomerInvoice.LineOfBusiness      AS LineOfBusiness,
		|	CustomerInvoice.ForeignCurrencyTransaction                AS ForeignCurrencyTransaction,
		|	CustomerInvoice.PaymentSchedule                 AS PaymentSchedule
		|FROM
		|	Document.CustomerInvoice AS CustomerInvoice
		|WHERE
		|	CustomerInvoice.Ref = &DocumentBasis
		|;
		|SELECT
		|	TransferredReturnablePackagingBalance.Products      AS Products,
		|	TransferredReturnablePackagingBalance.Characteristic    AS Characteristic,
		|	TransferredReturnablePackagingBalance.DocumentTransfers_  AS DocumentSalesOfGoodsAndServices,
		|	TransferredReturnablePackagingBalance.SumBalance      AS Sum,
		|	TransferredReturnablePackagingBalance.CountBalance AS Count,
		|	TransferredReturnablePackagingBalance.CountBalance AS NumberOfPackages,
		|	MIN(GoodsTable.LineNumber)                AS LineNumber
		|FROM
		|	AccumulationRegister.TransferredReturnablePackaging.Balance(, DocumentTransfers_ = &DocumentBasis) AS TransferredReturnablePackagingBalance
		|	INNER JOIN Document.CustomerInvoice.Goods AS GoodsTable
		|		ON TransferredReturnablePackagingBalance.DocumentTransfers_ = GoodsTable.Ref
		|			AND TransferredReturnablePackagingBalance.Products = GoodsTable.Products
		|			AND TransferredReturnablePackagingBalance.Characteristic = GoodsTable.Characteristic
		|
		|GROUP BY
		|	TransferredReturnablePackagingBalance.Products,
		|	TransferredReturnablePackagingBalance.Characteristic,
		|	TransferredReturnablePackagingBalance.DocumentTransfers_,
		|	TransferredReturnablePackagingBalance.SumBalance,
		|	TransferredReturnablePackagingBalance.CountBalance
		|
		|ORDER BY
		|	LineNumber
		|");

	Query.SetParameter("DocumentBasis", DocumentBasis);
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[0].Select();
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfRedemptionOfContainers(
		DocumentBasis,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsToReturnMultiTurnContainer);
		
	FillPropertyValues(ThisObject, HeaderSelection);
	Goods.Load(QueryBatch[1].Unload());
	
	StructureOfActions = New Structure;
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	
	For Each CurrentRow In Goods Do
		CurrentRow.AmountIncludingVAT = CurrentRow.Sum;
		CurrentRow.NumberOfPackages = CurrentRow.Count;
	EndDo;
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	For Each CurrentRow In Goods Do
		PriceManagementSystem.RecalculateAmountsInRowWithVAT(CurrentRow, PriceIncludesVAT, False, False, True);
	EndDo;
	
	StructureBase = Documents.ReturnablePackagingRedemptionByCustomer.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, StructureBase);
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)

	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		If GetFunctionalOption("ToUseTermsOfSales") Then
			FillInDefaultSalesConditions();
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	If Not ValueIsFilled(ARAPCurrency) Then
		ARAPCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	Department = SettingsValueCached.UserDivision(Manager, Department);
	
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		OrganizationSDefaultAccountParameters(),
		CompanyBankAccount);
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		CounterpartyBankAccount);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization    = Organization;
	ParametersStructure.CashAccount = CashAccount;

	CashAccount                     = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization, , Contract);
	
	FillParameters = Documents.ReturnablePackagingRedemptionByCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = ValueIsFilled(FillingData);
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		Undefined);
	
EndProcedure

Procedure InitializeSalesConditions()
	
	If Not GetFunctionalOption("ToUseTermsOfSales") Then
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

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, VATTaxation";
	
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
	|		TableOfGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.AmountARAP AS AmountARAP
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount AS VATAmount,
	|		-TableTypesOfStocks_.AmountARAP AS AmountARAP
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.DocumentSalesOfGoodsAndServices
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.AmountARAP) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure FillInAdditionalStockTypes() Export
	
	GoodsTable = Goods.Unload(, "ItemsLocationAttributes, Package, Count, NumberOfPackages, AmountARAP");
	GoodsTable.GroupBy("ItemsLocationAttributes, Package", "Count, NumberOfPackages, AmountARAP");
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In GoodsTable Do
		
		NumberOfProductsPerLine_	= RowOfGoods.Count;
		NumberOfPackagesPerLine_	= RowOfGoods.NumberOfPackages;
		AmountOfSettlementsByLine	= RowOfGoods.AmountARAP;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			QuantityPerRow = Min(NumberOfProductsPerLine_, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.Package			= RowOfGoods.Package;
			NewRow.NumberOfPackages	= ?(NumberOfProductsPerLine_ <> 0,
												NumberOfPackagesPerLine_ * QuantityPerRow / NumberOfProductsPerLine_,
												0);
			NewRow.Count			= QuantityPerRow;
			NewRow.QuantityByGBRN	= QuantityPerRow * InventoryLine.QuantityByGBRN
												/ InventoryLine.Count;
			NewRow.AmountIncludingVAT			= ?(InventoryLine.Count <> 0,
												QuantityPerRow * InventoryLine.AmountIncludingVAT / InventoryLine.Count,
												0);
			NewRow.VATAmount			= ?(InventoryLine.Count <> 0,
												QuantityPerRow * InventoryLine.VATAmount / InventoryLine.Count,
												0);
			NewRow.AmountARAP = ?(InventoryLine.Count <> 0,
												QuantityPerRow * AmountOfSettlementsByLine / NumberOfProductsPerLine_,
												0);
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.AmountIncludingVAT			= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount			= InventoryLine.VATAmount - NewRow.VATAmount;
			
			NumberOfProductsPerLine_	= NumberOfProductsPerLine_ - NewRow.Count;
			NumberOfPackagesPerLine_	= NumberOfPackagesPerLine_ - NewRow.NumberOfPackages;
			AmountOfSettlementsByLine	= AmountOfSettlementsByLine - NewRow.AmountARAP;
			
			If NumberOfProductsPerLine_ = 0 Then
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
		
		FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
		FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
		FillParameters.SelectTypesOfStocksForIntercampany = False;
		FillParameters.NameOfRemainderTable = "TransferredReturnablePackaging";
		
		InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		NamesOfGroupingColumns		= "ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, OriginWarehouse, VATRate, 
										|InventoryOwnerAttributeShipment, DocumentSalesOfGoodsAndServices";
		NamesOfSummationColumns	= "Count, QuantityByGBRN, AmountIncludingVAT, VATAmount";
		
		InventoryKinds.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
		
		FillInAdditionalStockTypes();
		
	EndIf;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.ReturnablePackagingRedemptionByCustomer.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.ReturnablePackagingRedemptionByCustomer.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.ReturnablePackagingRedemptionByCustomer,
					Undefined,
					Department,
					Partner);
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.BatchesIndicationStatus = 0;
	FieldsNames.Purpose = "";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other

// The procedure creates a temporary table of products with separate accounting Analytics.
//
// Parameters:
//	TempTablesManager - TempTablesManager - temporary table Manager
//								that will contain the created table.
//
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
	|	DocumentDataTable.SalesOpportunity AS SalesOpportunity,
	|	TableOfGoods.Purpose AS Purpose,
	|
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
	|	TableOfGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|");
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
