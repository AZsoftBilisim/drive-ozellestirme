#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.CommissionReportIntercompany - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	Return;
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.CommissionReportIntercompany.CollectionOfTabularPartsOfGoods.
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
	
	InventoryOwnerAttributesAreSpecifiedManually	= False;
	
	InventoryKinds.Clear();
	
	ARAPDetailsWithCustomer.Clear();
	ARAPDetailsWithVendor.Clear();
	ARAPDetailsWithCustomerRemuneration.Clear();
	ARAPDetailsWithVendorRemuneration.Clear();
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	CurrentRow = New Structure("VATRate", Catalogs.VATRates.EmptyRef());
	
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	VATRateOfRemuneration = CurrentRow.VATRate;

	AmountVATRemuneration = VATAccountingERPClientServer.CalculateVATAmount(CommissionAmount,
		VATAccountingERPClientServer.ValueOfVATRate(VATRateOfRemuneration));
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);
	
	RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
							ThisObject,
							"Organization");
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	CommissionReportIntercompanyLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("FillInByTheGoodsForRegistration") Then
		
		Consignee = FillingData.Consignee;
		Currency = FillingData.Currency;
		Organization = FillingData.Organization;
		BeginOfPeriod = FillingData.BeginOfPeriod;
		EndOfPeriod = FillingData.EndOfPeriod;
		If CurrentSessionDate() > EndOfMonth(EndOfPeriod)
			And ValueIsFilled(EndOfPeriod) Then
			Date = EndOfPeriod;
		Else
			Date = CurrentSessionDate();
		EndIf;
		
		If FillingData.Property("Contract") Then
			Contract = FillingData.Contract;
			
			FieldsNames = "LineOfBusiness, ARAPObjectSettings";
			ContractDetails_ = Common.ObjectAttributesValues(Contract, FieldsNames);
			LineOfBusiness = ContractDetails_.LineOfBusiness;
			ARAPObjectSettings = ContractDetails_.ARAPObjectSettings;
		EndIf;
		
		If TypeOf(FillingData) = Type("Structure") And FillingData.Property("VATTaxation")
			And FillingData.VATTaxation <> Enums.VATTaxationTypes.EmptyRef() Then
			VATTaxation = FillingData.VATTaxation;
		Else
			FillParameters = Documents.CommissionReportIntercompany.ParametersForFillingInVATTaxation_(ThisObject);
			VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
		EndIf;
		
		FillInGoodsOnBalancesForRegistration(FillingData.EndOfPeriod);
		
	EndIf;
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	
	CommissionReportIntercompanyLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	CheckOrganizations(Cancel);
	
	If ValueIsFilled(Organization)
		And ValueIsFilled(Consignee) Then
		
		CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Organization, Consignee);
		
		If Not CheckStructure.CurrenciesDoNotMatch Then
			ErrorText = NStr("vi = 'Tiền tệ kế toán tài chính của người đặt ký gửi %1 và người nhận ký gửi %2 phải trùng nhau.';
							|ru = 'Валюты регламентированного учета комитента %1 и комиссионера %2 должны совпадать.';
							|en = 'Local accounting currencies of the %1 vendor and the %2 consignee must match.'; fa = 'Local accounting currencies of the %1 vendor and the %2 consignee must match.';
							|it = 'Le valute della contabilità regolatoria del committente %1 e del commissionario %2 devono coincidere.';
							|pl = 'Waluty ewidencji reglamentowanej komitenta %1 i komisanta %2 powinny być jednakowe.';
							|tr = 'Gönderici %1 ve konsinye %2''nin yerel muhasebe para birimleri eşleşmelidir.'");
			ErrorText = StrTemplate(ErrorText, Organization, Consignee);
			Common.MessageToUser(ErrorText, ThisObject, "Organization",, Cancel);
		EndIf;
		
		If Not CheckStructure.CountriesMatch Then
			ErrorText = NStr("vi = 'Quốc gia đăng ký của người ký gửi %1 và người nhận ký gửi %2 phải trùng nhau.';
							|ru = 'Страны регистрации комитента %1 и комиссионера %2 должны совпадать.';
							|en = 'Countries of residence of consignor %1 and consignee %2 must be the same.'; fa = 'Countries of residence of consignor %1 and consignee %2 must be the same.';
							|it = 'I paesi di registrazione del committente %1 e del commissionario %2 devono corrispondere.';
							|pl = 'Kraje rejestracji komitenta %1 i komisanta %2 powinny być zgodne.';
							|tr = 'Gönderici %1 ve konsinye %2''nin kayıtlı olduğu ülkeler eşleşmelidir.'");
			ErrorText = StrTemplate(ErrorText, Organization, Consignee);
			Common.MessageToUser(ErrorText, ThisObject, "Organization",, Cancel);
		EndIf;
	
	EndIf;
	
	Documents.CommissionReportIntercompany.FillInNamesOfDetailsAccordingToMethodOfCalculatingRemuneration(
		CommissionFeeCalculationMethod,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	If Not ARAPAccountingViaSeparateCounterparty Then
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("Counterparty");
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	ConsignmentSalesServer.CheckIfPeriodIsCorrect(ThisObject, Cancel);
	
	CheckIfPeriodAndDateAreCorrect(Cancel);
	
	If CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating Then
		ConsignmentSalesServer.CheckCommissionService(ThisObject, Cancel);
	EndIf;
	
	CommissionReportIntercompanyLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	CalculationDocumentAmount = Goods.Total("SalesAmount");
	If DocumentAmount <> CalculationDocumentAmount Then
		DocumentAmount = CalculationDocumentAmount;
	EndIf;
	
	CalculationOfRemunerationAmount = Goods.Total("CommissionAmount");
	If CommissionAmount <> CalculationOfRemunerationAmount Then
		CommissionAmount = CalculationOfRemunerationAmount;
	EndIf;
	
	If AmountVATRemuneration <> Goods.Total("AmountVATRemuneration") Then
		ConsignmentSalesServer.FillInAmountOfVATRemunerationInTablePart(Goods, AmountVATRemuneration);
	EndIf;
	
	AccountingForTraceableGoodsLocalization.ClearDataOnImportedGoodsInCommissionAgentSDocuments(ThisObject, True);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	If ARAPAccountingViaSeparateCounterparty
		And Organization <> Catalogs.Companies.ManagementCompany Then
		
		If Not ValueIsFilled(IncomingDocumentDate) Then
			IncomingDocumentDate = BegOfDay(Date);
		EndIf;
		
		If Not ValueIsFilled(IncomingDocumentNumber) Then
			IncomingDocumentNumber = Number;
		EndIf;
		
	Else
		If ValueIsFilled(IncomingDocumentDate) Then
			IncomingDocumentDate = Undefined;
		EndIf;
		
		If ValueIsFilled(IncomingDocumentNumber) Then
			IncomingDocumentNumber = "";
		EndIf;
	EndIf;
		
	If Not ARAPAccountingViaSeparateCounterparty Then
		If ValueIsFilled(Partner) Then
			Partner = Undefined;
		EndIf;
		If ValueIsFilled(Counterparty) Then
			Counterparty = Undefined;
		EndIf;
	EndIf;
	
	// We will clear the details of the document that are not used for the method of calculating remuneration.
	ArrayOfAllProps		= New Array;
	ArrayOfOperationDetails	= New Array;
	
	Documents.CommissionReportIntercompany.FillInNamesOfDetailsAccordingToMethodOfCalculatingRemuneration(
		CommissionFeeCalculationMethod,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	If IsNew()
		And Not ValueIsFilled(Number) Then
		
		SetNewNumber();
		
	EndIf;
	
	If Not ValueIsFilled(PaymentID) Then
		PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	EndIf;
	
	RegistrationParameters = Documents.CommissionReportIntercompany.ParametersForRegisteringInvoicesToCommissionAgent(ThisObject);
	VATAccountingERP.UpdateInvoicesToCommissionAgentBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	RegistrationParameters = Documents.CommissionReportIntercompany.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	RegistrationParameters = Documents.CommissionReportIntercompany.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	CommissionReportIntercompanyLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author)
		And IsNew() Then
		
		Author = Users.CurrentUser();
		
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RegistrationParameters = Documents.CommissionReportIntercompany.ParametersForRegisteringInvoicesToCommissionAgent(ThisObject);
	VATAccountingERP.UpdateInvoicesToCommissionAgentWhenConducting(RegistrationParameters);
	
	RegistrationParameters = Documents.CommissionReportIntercompany.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	
	RegistrationParameters = Documents.CommissionReportIntercompany.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
	CommissionReportIntercompanyLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RegistrationParameters = Documents.CommissionReportIntercompany.ParametersForRegisteringInvoicesToCommissionAgent(ThisObject);
	VATAccountingERP.UpdateInvoicesToCommissionAgentWhenDeletingThem(RegistrationParameters);
	
	RegistrationParameters = Documents.CommissionReportIntercompany.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
	RegistrationParameters = Documents.RedemptionOfReturnablePackagingFromVendor.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
	CommissionReportIntercompanyLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	CommissionReportIntercompanyLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInGoodsOnBalancesForRegistration(FillingDate) Export
	
	FillParameters = New Structure;
	FillParameters.Insert("Date",				Date);
	FillParameters.Insert("BeginOfPeriod",		BeginOfPeriod);
	FillParameters.Insert("EndOfPeriod",		EndOfPeriod);
	FillParameters.Insert("Organization",			Consignee);
	FillParameters.Insert("Partner",				Organization);
	FillParameters.Insert("Counterparty",			Undefined);
	FillParameters.Insert("Terms",			Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	FillParameters.Insert("Contract",				Contract);
	FillParameters.Insert("Currency",				Currency);
	FillParameters.Insert("VATTaxation",	VATTaxation);
	FillParameters.Insert("PriceIncludesVAT",		PriceIncludesVAT);
	FillParameters.Insert("Goods",				Goods);
	
	ThereIsCCDNumber = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date);
	
	ConsignmentSalesServer.InformationOnGoodsForMakingReportsToCommitteeForPeriod(
		FillParameters,
		BeginOfPeriod,
		?(ValueIsFilled(EndOfPeriod), EndOfPeriod, EndOfMonth(Date)),
		ThereIsCCDNumber);
	
	If Not ValueIsFilled(PriceKind) Then
		PriceKind = Catalogs.TypesOfPrices.DefaultPriceType(PriceKind,
			New Structure("UseForIntercompanySales, PriceIncludesVAT", True, PriceIncludesVAT));
	EndIf;
	
	If ValueIsFilled(PriceKind) Then
		Attributes = Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind);
		
		If Not ValueIsFilled(Currency) Then
			Currency = Attributes.PriceCurrency;
		EndIf;
		
		PriceIncludesVAT = Attributes.PriceIncludesVAT;
		
		FillParameters = New Structure;
		FillParameters.Insert("Date",			Date);
		FillParameters.Insert("Organization",		Organization);
		FillParameters.Insert("Currency",			Currency);
		FillParameters.Insert("PriceKind",			PriceKind);
		FillParameters.Insert("PopulationFields",	"Price, PriceKind");
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount",		"NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountWithVAT",	StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateVATAmount",	StructureOfRecalculationOfAmount);
		
		EnterprisePricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, StructureOfActions);
	EndIf;
	
	ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
											ThisObject,
											"Organization");
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																					Goods);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	Organization		= SettingsValueCached.GetDefaultOrganization(Organization);
	Currency			= IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
	PriceKind			= Catalogs.TypesOfPrices.DefaultPriceType(PriceKind,
						New Structure("UseForIntercompanySales, PriceIncludesVAT", True, PriceIncludesVAT));
	
	If Not ValueIsFilled(CompanyBankAccount) Or Not ValueIsFilled(RecipientCompanyBankAccount) Then
		SalesServer.FillInBankAccountsUnderAgreement(Contract,
			?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
			?(ValueIsFilled(RecipientCompanyBankAccount), Undefined, RecipientCompanyBankAccount));
	EndIf;
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = ComplCurrency;
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		CompanyBankAccount);

	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Consignee);
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = ComplCurrency;
	RecipientCompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		ParametersOfAccount, RecipientCompanyBankAccount);
	
	BusinessOperation = Enums.TypesOfIntercompanyContracts.Consignment;
	FinancialAccountingGroup	= Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, Currency, BusinessOperation);
	FinancialAccountingGroupOfRecipient = Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, Currency, BusinessOperation, True);
	
	If Not ValueIsFilled(VATTaxation) Then
		FillParameters = Documents.CommissionReportIntercompany.ParametersForFillingInVATTaxation_(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
		StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject));
		StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", PriceIncludesVAT));
		StructureOfActions.Insert("RecalculateVATSalesAmount");
		StructureOfActions.Insert("ClearRewardAmount");
		
		BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
		
	EndIf;
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
EndProcedure

#EndRegion

#Region InventoryKinds

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.CommissionReportIntercompany.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.CommissionReportIntercompany.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.ConsignmentReportToVendor,
					Undefined,
					Department,
					Organization);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.BatchesIndicationStatus = "";
	FieldsNames.Purpose = "";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
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
		FillParameters.NameOfRemainderTable = "IntercampanyCommissionGoods";
		FillParameters.WhenSelectingByIntercampanyExcludeOrganizations = Consignee;
		
		SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
		SelectionOfStockTypes_.Organization = Consignee;
		SelectionOfStockTypes_.GoodsOwner = Organization;
		SelectionOfStockTypes_.Currency = Currency;
		SelectionOfStockTypes_.InventoryType = Enums.InventoryTypes.ConsignedGoods;
		
		If ValueIsFilled(Contract) Then
			SelectionOfStockTypes_.Contract = Contract;
		Else
			SelectionOfStockTypes_.Contract = New Array; // Array of CatalogRef.IntercompanyContracts
			SelectionOfStockTypes_.Contract.Add(Undefined);
			SelectionOfStockTypes_.Contract.Add(Catalogs.IntercompanyContracts.EmptyRef());
		EndIf;
		
		InventoriesServer.FillOutInventoryTypesForIntercampanyCommissionGoods(ThisObject,
																			TempTablesManager,
																			Cancel,
																			FillParameters);
		
	EndIf;
	
EndProcedure

Function TemporaryDocumentDataTables()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date			AS Date,
	|	&Organization	AS Organization,
	|	&Consignee	AS Consignee,
	|	&Organization	AS Partner,
	|	&Organization	AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&Contract		AS Contract,
	|	&Currency			AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.CommissionReportIntercompany) AS BusinessOperation,
	|	FALSE			AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.ConsignedGoods) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|	0													AS BatchesIndicationStatus,
	|	TableOfGoods.Package								AS Package,
	|	TableOfGoods.Count							AS Count,
	|	TableOfGoods.NumberOfPackages					AS NumberOfPackages,
	|	TableOfGoods.QuantityByGBRN						AS QuantityByGBRN,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS Warehouse,
	|	TableOfGoods.VATRate							AS VATRate,
	|	TableOfGoods.SalesAmount							AS AmountIncludingVAT,
	|	TableOfGoods.AmountSalesVAT						AS VATAmount,
	|	TableOfGoods.CommissionAmount					AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration				AS AmountVATRemuneration,
	|	TableOfGoods.CCDNumber								AS CCDNumber,
	|	TableOfGoods.IssuedTaxInvoiceOfCommissionAgent	AS IssuedTaxInvoiceOfCommissionAgent,
	|	TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent			AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableOfGoods.Customer							AS Customer,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	TRUE												AS SelectTypesOfStocks
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	TableOfGoods.Purpose							AS Purpose,
	|	TableOfGoods.Series								AS Series,
	|	TableOfGoods.BatchesIndicationStatus					AS BatchesIndicationStatus,
	|	TableOfGoods.Package								AS Package,
	|	TableOfGoods.Count							AS Count,
	|	TableOfGoods.NumberOfPackages					AS NumberOfPackages,
	|	TableOfGoods.QuantityByGBRN						AS QuantityByGBRN,
	|	TableOfGoods.Warehouse								AS Warehouse,
	|	TableOfGoods.VATRate							AS VATRate,
	|	TableOfGoods.AmountIncludingVAT							AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount								AS VATAmount,
	|	TableOfGoods.CommissionAmount					AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration				AS AmountVATRemuneration,
	|	TableOfGoods.CCDNumber								AS CCDNumber,
	|	TableOfGoods.IssuedTaxInvoiceOfCommissionAgent	AS IssuedTaxInvoiceOfCommissionAgent,
	|	TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent			AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableOfGoods.Customer							AS Customer,
	|	TableOfGoods.SalesOpportunity								AS SalesOpportunity,
	|	TableOfGoods.SelectTypesOfStocks					AS SelectTypesOfStocks
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	CatalogProducts.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|												VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber							AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber								AS CCDNumber,
	|	TableTypesOfStocks_.Count							AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN						AS QuantityByGBRN,
	|	TableTypesOfStocks_.VATRate							AS VATRate,
	|	TableTypesOfStocks_.AmountIncludingVAT							AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount								AS VATAmount,
	|	TableTypesOfStocks_.CommissionAmount					AS CommissionAmount,
	|	TableTypesOfStocks_.AmountVATRemuneration				AS AmountVATRemuneration,
	|	TableTypesOfStocks_.DateOfTaxInvoiceIssuedByCommissionAgent			AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableTypesOfStocks_.IssuedTaxInvoiceOfCommissionAgent	AS IssuedTaxInvoiceOfCommissionAgent,
	|	TableTypesOfStocks_.Customer							AS Customer,
	|	VALUE(Catalog.Warehouses.EmptyRef)				AS OriginWarehouse,
	|	VALUE(Catalog.Warehouses.EmptyRef)				AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)		AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually								AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber							AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	Dimension.Products									AS Products,
	|	Dimension.Characteristic								AS Characteristic,
	|	Dimension.Series											AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber								AS CCDNumber,
	|	TableTypesOfStocks_.Count							AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN						AS QuantityByGBRN,
	|	TableTypesOfStocks_.VATRate							AS VATRate,
	|	TableTypesOfStocks_.AmountIncludingVAT							AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount								AS VATAmount,
	|	TableTypesOfStocks_.CommissionAmount					AS CommissionAmount,
	|	TableTypesOfStocks_.AmountVATRemuneration				AS AmountVATRemuneration,
	|	TableTypesOfStocks_.DateOfTaxInvoiceIssuedByCommissionAgent			AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableTypesOfStocks_.IssuedTaxInvoiceOfCommissionAgent	AS IssuedTaxInvoiceOfCommissionAgent,
	|	TableTypesOfStocks_.Customer							AS Customer,
	|	TableTypesOfStocks_.Warehouse								AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse								AS Warehouse,
	|	TableTypesOfStocks_.SalesOpportunity								AS SalesOpportunity,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually			AS InventoryOwnerAttributesAreSpecifiedManually
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
	
	Query.SetParameter("Ref",						Ref);
	Query.SetParameter("Date",						Date);
	Query.SetParameter("Organization",				Organization);
	Query.SetParameter("Consignee",				Consignee);
	Query.SetParameter("Contract",					Contract);
	Query.SetParameter("Currency",						Currency);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually",	InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("TableOfGoods",				TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",			InventoryKinds);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Procedure CheckOrganizations(Cancel)
	
	If ValueIsFilled(Organization)
		And ValueIsFilled(Consignee) Then
		
		If Organization = Consignee Then
			
			Text = NStr("vi = 'Một doanh nghiệp không thể đồng thời là người đặt ký gửi và người nhận bán ký gửi';
						|ru = 'Одна и та же организация не может являться комитентом и комиссионером одновременно';
						|en = 'The same company cannot be both the consignor and the consignee'; fa = 'The same company cannot be both the consignor and the consignee';
						|it = 'La stessa società non può essere committente e commissionario contemporaneamente';
						|pl = 'Ta sama firma nie może jednocześnie pełnić funkcji komitenta i komisanta';
						|tr = 'Bir ve aynı iş yeri aynı anda hem gönderici hem de konsinye olamaz'");
			Common.MessageToUser(Text, ThisObject, "Organization", , Cancel);
			
		ElsIf GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets")
			And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Organization, Consignee) Then
		
			Text = NStr("vi = 'Doanh nghiệp nhận hàng không được phép có quan hệ với doanh nghiệp gửi hàng theo cơ cấu tổ chức.';
						|ru = 'Организация-получатель не должна быть взаимосвязана с организацией-отправителем по организационной структуре.';
						|en = 'Receiving company should not be interrelated to the shipping company by the organizational structure.'; fa = 'Receiving company should not be interrelated to the shipping company by the organizational structure.';
						|it = 'La società-destinatario non deve essere interconnessa con la società-mittente per la struttura organizzativa.';
						|pl = 'Firma odbiorca nie powinna być wzajemnie powiązana z firmą nadawcą według struktury organizacyjnej.';
						|tr = 'Alıcı iş yeri, iş yeri yapısı bakımından gönderen iş yeri ile bağlantılı olmamalıdır.'");
			Common.MessageToUser(Text, ThisObject, "Consignee", , Cancel);
			
		EndIf;
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Consignee, Currency, Contract";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent	AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableOfGoods.Customer					AS Customer,
	|	TableOfGoods.CCDNumber						AS CCDNumber
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate							AS VATRate,
	|		TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent			AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|		TableOfGoods.IssuedTaxInvoiceOfCommissionAgent	AS IssuedTaxInvoiceOfCommissionAgent,
	|		TableOfGoods.Customer							AS Customer,
	|		TableOfGoods.CCDNumber								AS CCDNumber,
	|		TableOfGoods.Count							AS Count,
	|		TableOfGoods.Count							AS QuantityByGBRN,
	|		TableOfGoods.AmountIncludingVAT							AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount								AS VATAmount,
	|		TableOfGoods.CommissionAmount					AS CommissionAmount,
	|		TableOfGoods.AmountVATRemuneration				AS AmountVATRemuneration
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|														VALUE(Enum.ItemsTypes.ReusablePackage))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate							AS VATRate,
	|		TableTypesOfStocks_.DateOfTaxInvoiceIssuedByCommissionAgent			AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|		TableTypesOfStocks_.IssuedTaxInvoiceOfCommissionAgent	AS IssuedTaxInvoiceOfCommissionAgent,
	|		TableTypesOfStocks_.Customer							AS Customer,
	|		TableTypesOfStocks_.CCDNumber								AS CCDNumber,
	|		-TableTypesOfStocks_.Count							AS Count,
	|		-TableTypesOfStocks_.Count							AS QuantityByGBRN,
	|		-TableTypesOfStocks_.AmountIncludingVAT							AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount							AS VATAmount,
	|		-TableTypesOfStocks_.CommissionAmount					AS CommissionAmount,
	|		-TableTypesOfStocks_.AmountVATRemuneration				AS AmountVATRemuneration
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableOfGoods.IssuedTaxInvoiceOfCommissionAgent,
	|	TableOfGoods.Customer,
	|	TableOfGoods.CCDNumber
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.QuantityByGBRN) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.CommissionAmount) <> 0
	|	OR SUM(TableOfGoods.AmountVATRemuneration) <> 0";
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure CheckIfPeriodAndDateAreCorrect(Cancel) Export
	
	If EndOfMonth(Date) <> EndOfMonth(EndOfPeriod)
		Or BegOfMonth(Date) <> BegOfMonth(BeginOfPeriod) Then
		
		MessageText = NStr("vi = 'Kỳ mà người nhận ký gửi cần lập bảng kê phải trong cùng một tháng mà đã kết chuyển chứng từ.';
							|ru = 'Период, за который отчитывается комиссионер, должен находиться в том же месяце, в котором проводится документ.';
							|en = 'Period for which the consignee reports should be in the same month in which the document is posted.'; fa = 'Period for which the consignee reports should be in the same month in which the document is posted.';
							|it = 'Il periodo per il quale il commissionario presenta il rendiconto deve far parte dello stesso mese in cui il documento è registrato.';
							|pl = 'Okres, za który komisant jest odpowiedzialny musi dotyczyć tego samego miesiąca, w którym dokument został zaksięgowany.';
							|tr = 'Konsinyenin raporlama yaptığı dönem, belgenin tutulduğu ay ile aynı ay içinde olmalıdır.'");
		
		Common.MessageToUser(MessageText, Undefined, "SetDateInterval", "Object", Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
