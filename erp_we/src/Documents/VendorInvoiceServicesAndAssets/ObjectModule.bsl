#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not ValueIsFilled(Terms) Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	If VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT 
		 Or VATTaxation = Enums.VATTaxationTypes.VATTaxAgent Then
		NotCheckedAttributeArray.Add("Expenses.VATRate");
	EndIf;
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.VendorInvoiceServicesAndAssets.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	NotCheckedAttributeArray.Add("Expenses.QuantityByGBRN");
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	CheckParameters = Documents.VendorInvoiceServicesAndAssets.VerificationParametersFillingInDocumentOnVATTaxationPurchases(ThisObject);
	VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation(ThisObject, VATTaxation, CheckParameters, Cancel);
	
	CheckParameters = Documents.VendorInvoiceServicesAndAssets.ParametersForCheckingDocumentFillingByTypeOfActivity(ThisObject);
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(ThisObject, PurchaseForActivity, CheckParameters, Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoiceServicesAndAssets.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	VendorInvoiceServicesAndAssetsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.ApplicationForCollateral") Then
		FillInDocumentBasedOnSupplyRequest(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.SubcontractOrder2_5")
		  Or TypeOf(FillingData) = Type("DocumentRef.SubcontractorReport2_5") Then
		FillInDocumentBasedOnProcessorSData2_5(FillingData);
	EndIf;
	
	FillParameters = Documents.VendorInvoiceServicesAndAssets.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	FillParameters = Documents.VendorInvoiceServicesAndAssets.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoiceServicesAndAssets.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	VendorInvoiceServicesAndAssetsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	FillOutBankAccounts();
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);

	If WriteMode = DocumentWriteMode.UndoPosting Then
		ThereAreAdjustingEntries = False;
		PurchasesServer.CheckForAdjustmentsAndInvoices(Ref, Ref, ThereAreAdjustingEntries, Undefined);
		If ThereAreAdjustingEntries Then
			PurchasesServer.ReportErrorsCancellationsAndAdjustments(Ref,Cancel);
		EndIf;
	EndIf;
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Expenses, PriceIncludesVAT);
	
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Expenses");
	
	RegistrationParameters = Documents.VendorInvoiceServicesAndAssets.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoiceServicesAndAssets.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.VendorInvoiceServicesAndAssets.AccountingAccountSettings_(BusinessOperation));
	VendorInvoiceServicesAndAssetsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	VendorInvoiceServicesAndAssetsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	RegistrationParameters = Documents.VendorInvoiceServicesAndAssets.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	VendorInvoiceServicesAndAssetsLocalization.UndoPosting(ThisObject, Cancel);
	
	RegistrationParameters = Documents.VendorInvoiceServicesAndAssets.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentBasis = Undefined;
	InitializeDocument();
	
	IncomingDocumentDate	= Date(1,1,1);
	IncomingDocumentNumber	= "";
	
	FillParameters = Documents.VendorInvoiceServicesAndAssets.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	FillParameters = Documents.VendorInvoiceServicesAndAssets.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUseClientServer.FillInCollectionPropertyValues(Expenses, 0, "AmountARAP");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	StructureOfActions.Insert("AdjustVATRate",StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Expenses, StructureOfActions, CachedValues);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Expenses,
		CachedValues);
	
	If Not GetFunctionalOption("UsePaymentsToSelfEmployedPersons") Then
		OperationWithSelfEmployedPerson = False;
	EndIf;
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Expenses");
	
	VendorInvoiceServicesAndAssetsLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	VendorInvoiceServicesAndAssetsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

// Fills in the purchase conditions in the document.
//
// Parameters:
//	PurchaseConditions - Structure - Structure to fill in.
//
Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	Currency               = PurchaseConditions.Currency;
	ARAPCurrency = PurchaseConditions.ARAPCurrency;
	LineOfBusiness = PurchaseConditions.LineOfBusiness;
	
	If ValueIsFilled(PurchaseConditions.Organization) And PurchaseConditions.Organization <> Organization Then
		Organization = PurchaseConditions.Organization;
		CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Counterparty) And PurchaseConditions.Counterparty <> Counterparty Then
		Counterparty = PurchaseConditions.Counterparty;
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	If PurchaseConditions.ContractsAreUsed <> Undefined And PurchaseConditions.ContractsAreUsed Then

		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Currency;
		AddlParameters.Taxation = VATTaxation;
		Contract = PurchasesServer.GetDefaultContract(ThisObject, BusinessOperation, AddlParameters);
		
		If ValueIsFilled(Contract) Then
			PaymentInCurrencyUnderContract = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
			If ForeignCurrencyTransaction <> PaymentInCurrencyUnderContract Then
				ForeignCurrencyTransaction = PaymentInCurrencyUnderContract;
				CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
		EndIf;
		
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
		
		If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
	Else
		
		If ForeignCurrencyTransaction <> PurchaseConditions.ForeignCurrencyTransaction Then
			ForeignCurrencyTransaction = PurchaseConditions.ForeignCurrencyTransaction;
			CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
	EndIf;
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		ParametersOfAccount, CompanyBankAccount);
	
	PaymentDateValue = PurchasesServer.GetLatestDateOnSchedule(Date, PurchaseConditions.Terms);
	If ValueIsFilled(PaymentDateValue) Then
		PaymentDate = PaymentDateValue;
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = PurchaseConditions.FinancialAccountingGroup;
	EndIf;
	
	PriceIncludesVAT      = PurchaseConditions.PriceIncludesVAT;
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization, , Contract);
	
EndProcedure

// Fills in the terms of purchases under the trade agreement with the supplier.
//
Procedure FillInDefaultPurchaseConditions() Export
	
	If ValueIsFilled(Partner) Then
		
		FilterParameters = New Structure();
		FilterParameters.Insert("ConsiderWarehouseGroups", True);
		FilterParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
		FilterParameters.Insert("BusinessTransactions", Enums.BusinessTransactions.PurchaseFromSupplier);
		FilterParameters.Insert("SelectedAgreement", Terms);
		DefaultPurchasingConditions = PurchasesServer.GetDefaultPurchaseTerms(
			Partner,
			FilterParameters);
			
		PricesAreFilledOut = False;
		
		If DefaultPurchasingConditions <> Undefined Then
			
			If Terms <> DefaultPurchasingConditions.Terms
				And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
				
				Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
				
			Else
				Terms = DefaultPurchasingConditions.Terms;
			EndIf;
			
		Else
			Terms = Undefined;
		EndIf;
		
		CounterpartyBeforeFillingIn = Counterparty;
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		If CounterpartyBeforeFillingIn <> Counterparty Then
			ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
			CounterpartyBankAccount =
				CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
		EndIf;
		
		If Not ValueIsFilled(Contract) Then
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = Currency;
			AddlParameters.Taxation = VATTaxation;
			Contract = PurchasesServer.GetDefaultContract(ThisObject, BusinessOperation, AddlParameters);
			PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount,
				CounterpartyBankAccount);
		EndIf;
		
	EndIf;
		
EndProcedure

Procedure FillInDocumentBasedOnSupplyRequest(ApplicationForCollateral)
	
	ReceivingParameters = Documents.ApplicationForCollateral.ParametersForReceivingFillInDataBasedOn();
	ReceivingParameters.WorkWithStringsIsSupported = True;
	FillingData = Documents.ApplicationForCollateral.FillingDataBasedOn(
		ApplicationForCollateral,
		ReceivingParameters);
	
	// Safe filling of the header:
	HeaderProperties = New Structure;
	HeaderProperties.Insert("Organization");
	HeaderProperties.Insert("Warehouse");
	HeaderProperties.Insert("Department");
	HeaderProperties.Insert("LineOfBusiness");
	HeaderProperties.Insert("Currency");
	FillPropertyValues(HeaderProperties, FillingData.Header);
	FillPropertyValues(ThisObject, HeaderProperties);
	ARAPCurrency = Currency;
	
	DocumentBasis = ApplicationForCollateral;
	
	// Filling PM: 
	If FillingData.Goods.Columns.Find("Department") = Undefined Then
		// To write off expenses, fill in the division from the header:
		FillingData.Goods.Columns.Add(
			"Department",
			New TypeDescription("CatalogRef.BusinessStructure"));
		
		FillingData.Goods.FillValues(Department, "Department");
	EndIf;
	
	FillingData.Goods.Columns.Delete("Count");
	FillingData.Goods.Columns.ProductsAsAString.Name = "Content";
	FillingData.Goods.Columns.NumberOfPackages.Name = "Count";
	
	Expenses.Load(FillingData.Goods);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
		PriceCalculationParameters = BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInVHFPurchases(
		ThisObject,
		True); // Disabling manual discounts
	PriceCalculationParameters.Insert("QuantityName", "Count");
	StructureOfActions.Insert("RecalculatePriceDiscountForAmountInPurchases", PriceCalculationParameters);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(Expenses, StructureOfActions);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	Organization               = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	Department             = SettingsValueCached.UserDivision(Manager, Department);
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		CompanyBankAccount);
	
EndProcedure

Procedure FillOutBankAccounts()
	
	If ValueIsFilled(CompanyBankAccount) And ValueIsFilled(CounterpartyBankAccount) Then
		Return;
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract,
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

#Region Other


Procedure FillInDocumentBasedOnProcessorSData2_5(ProcessorData)
	
	Query = New Query;
	Query.SetParameter("Ref", ProcessorData);
	Query.Text =
	"SELECT
	|	SubcontractOrder.Organization				AS Organization,
	|	SubcontractOrder.Currency					AS Currency,
	|	SubcontractOrder.Currency					AS ARAPCurrency,
	|	SubcontractOrder.Manager					AS Manager,
	|	SubcontractOrder.Counterparty				AS Counterparty,
	|	SubcontractOrder.Partner					AS Partner,
	|	SubcontractOrder.Contract					AS Contract,
	|	SubcontractOrder.Department			AS Department,
	|	SubcontractOrder.PurchaseForActivity	AS PurchaseForActivity,
	|	SubcontractOrder.ForeignCurrencyTransaction			AS ForeignCurrencyTransaction
	|FROM
	|	Document.SubcontractOrder2_5 AS SubcontractOrder
	|WHERE
	|	SubcontractOrder.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	SubcontractorReport.Organization				AS Organization,
	|	SubcontractorReport.Currency					AS Currency,
	|	SubcontractorReport.ARAPCurrency		AS ARAPCurrency,
	|	SubcontractorReport.Manager					AS Manager,
	|	SubcontractorReport.Counterparty				AS Counterparty,
	|	SubcontractorReport.Partner					AS Partner,
	|	SubcontractorReport.Contract					AS Contract,
	|	SubcontractorReport.Department			AS Department,
	|	SubcontractorReport.PurchaseForActivity	AS PurchaseForActivity,
	|	SubcontractorReport.ForeignCurrencyTransaction			AS ForeignCurrencyTransaction
	|FROM
	|	Document.SubcontractorReport2_5 AS SubcontractorReport
	|WHERE
	|	SubcontractorReport.Ref = &Ref";
	
	Result = Query.Execute();
	Header = Result.Select();
	Header.Next();
	
	// Filling in the header.
	FillPropertyValues(ThisObject, Header);
	
EndProcedure
#EndRegion

#EndRegion

#EndIf
