#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.ConsignmentReportToVendor - the document for which parameters are initialized.
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
//	DocumentTables - See Documents.ConsignmentReportToVendor.CollectionOfTabularPartsOfGoods.
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
	
	CurrentRow = New Structure("VATRate", Catalogs.VATRates.EmptyRef());
	
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	VATRateOfRemuneration = CurrentRow.VATRate;

	AmountVATRemuneration = VATAccountingERPClientServer.CalculateVATAmount(CommissionAmount,
		VATAccountingERPClientServer.ValueOfVATRate(VATRateOfRemuneration));
	
	InventoryKinds.Clear();
	
	ARAPDetailsWithCustomer.Clear();
	ARAPDetailsWithVendor.Clear();
	
	FillParameters = Documents.ConsignmentReportToVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);

	ARAPAccountingServer.OnCopy(ThisObject);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);

	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
		
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("ClearRewardAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount"); 
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);

	ConsignmentSalesServer.FillInLBRateOfJointCommissionRemuneration(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");

	ConsignmentReportToVendorLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("FillInByTheGoodsForRegistration") Then
	
		Partner				= FillingData.Partner;
		Counterparty			= FillingData.Counterparty;
		Terms			= FillingData.Terms;
		Contract				= FillingData.Contract;
		VATTaxation	= FillingData.VATTaxation;
		FillingData.Property("DocumentSales", DocumentSales);
		
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		
		If ValueIsFilled(Terms) Then
			
			FillInTermsOfPurchaseUnderAgreement();
			
			Organization	= FillingData.Organization;
			Contract		= FillingData.Contract;
			
			If ValueIsFilled(FillingData.Counterparty) Then
				Counterparty = FillingData.Counterparty;
			EndIf;
			
		Else
			
			Organization	= FillingData.Organization;
			Currency		= FillingData.Currency;
			
			If Not ValueIsFilled(Counterparty) Then
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(Contract) Then
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = Currency;
			
			Contract = PurchasesServer.GetDefaultContract(ThisObject,
																Enums.BusinessTransactions.ConsignmentProcurement,
																AddlParameters);
		EndIf;
		
		PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
		
		FillParameters = Documents.ConsignmentReportToVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
		VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
		
		ConsignmentSalesServer.InformationOnGoodsForMakingReportsToCommitteeForPeriod(ThisObject,
																						FillingData.BeginOfPeriod,
																						FillingData.EndOfPeriod,
																						False,
																						True,
																						True);
		
		If VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
			For Each TableRow In Goods Do
				TableRow.AmountSalesVAT = 0; 
				TableRow.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
			EndDo;
		EndIf;
		
		ConsignmentSalesServer.CalculateRewardAmount(ThisObject);
		
	EndIf;
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	If Not ValueIsFilled(BankAccount) Then
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, BankAccount);
	EndIf;
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		BankAccount, PaymentMethod);
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If ValueIsFilled(OperationService) Then
		ConsignmentSalesServer.FillInLBRateOfJointCommissionRemuneration(ThisObject, Undefined);
	EndIf;
	
	CurrentRow = New Structure("VATRate", Catalogs.VATRates.EmptyRef());

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	VATRateOfRemuneration = CurrentRow.VATRate;
	
	ConsignmentSalesServer.CalculateRewardAmount(ThisObject);
	
	AmountVATRemuneration = VATAccountingERPClientServer.CalculateVATAmount(
								CommissionAmount,
								VATAccountingERPClientServer.ValueOfVATRate(VATRateOfRemuneration));
	
	InitializeDocument(FillingData);
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	ConsignmentReportToVendorLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.ConsignmentReportToVendor.FillInNamesOfBusinessTransactionDetails(
		CommissionFeeCalculationMethod, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;
	
	If Not ValueIsFilled(Terms) Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
		
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	If NotCheckedAttributeArray.Find("PaymentDate") = Undefined Then	
		If ThisObject.KeepCommissionFee Then
			NotCheckedAttributeArray.Add("PaymentDate");	
		EndIf;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);

	ConsignmentSalesServer.CheckIfPeriodIsCorrect(ThisObject, Cancel);

	If CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating Then
		ConsignmentSalesServer.CheckCommissionService(ThisObject, Cancel);
	EndIf;
	
	ConsignmentReportToVendorLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

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
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
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
	
	RegistrationParameters = Documents.ConsignmentReportToVendor.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	// We will clear the details of the document that are not used for the method of calculating remuneration.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.ConsignmentReportToVendor.FillInNamesOfBusinessTransactionDetails(
		CommissionFeeCalculationMethod,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	If WriteMode = DocumentWriteMode.Posting Then
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
	EndIf;
	
	ConsignmentReportToVendorLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	InvoicesIssued = ThisObject.Goods.UnloadColumn("CustomerInvoiceIssued");
	VATAccountingERP.UpdateCommitteeSInvoicesWhenConducting(InvoicesIssued, Cancel);
	
	RegistrationParameters = Documents.ConsignmentReportToVendor.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	
	ConsignmentReportToVendorLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	InvoicesIssued = ThisObject.Goods.UnloadColumn("CustomerInvoiceIssued");
	VATAccountingERP.UpdateCommitteeSInvoicesWhenDeletingThem(InvoicesIssued);
	
	RegistrationParameters = Documents.ConsignmentReportToVendor.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
	ConsignmentReportToVendorLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ConsignmentReportToVendorLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions <> Undefined Then
	
		DocumentPurchases = ThisObject;
		DocumentPurchases.Currency = PurchaseConditions.Currency;
		DocumentPurchases.LineOfBusiness = PurchaseConditions.LineOfBusiness;
		
		If ValueIsFilled(PurchaseConditions.PaymentMethod) Then
			DocumentPurchases.PaymentMethod = PurchaseConditions.PaymentMethod;
		EndIf;
		
		If ValueIsFilled(PurchaseConditions.Organization) And PurchaseConditions.Organization<>Organization Then
			DocumentPurchases.Organization = PurchaseConditions.Organization;

			BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			
			ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
			ParametersStructure.Organization    			= Organization;
			ParametersStructure.PaymentMethod				= PaymentMethod;
			ParametersStructure.LineOfBusiness = LineOfBusiness;
			CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
		EndIf;
			
		If ValueIsFilled(PurchaseConditions.Counterparty) Then
			DocumentPurchases.Counterparty = PurchaseConditions.Counterparty;
		EndIf;
		
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		
		DocumentPurchases.PriceIncludesVAT = PurchaseConditions.PriceIncludesVAT;
		
		If ValueIsFilled(PurchaseConditions.FinancialAccountingGroup) Then
			FinancialAccountingGroup = PurchaseConditions.FinancialAccountingGroup;
		EndIf;
		
		If ValueIsFilled(PurchaseConditions.CommissionFeeCalculationMethod) Then
			CommissionFeeCalculationMethod = PurchaseConditions.CommissionFeeCalculationMethod;
		EndIf;
		If ValueIsFilled(PurchaseConditions.RemunerationPercentage) Then
			RemunerationPercentage = PurchaseConditions.RemunerationPercentage;
		EndIf;
		KeepCommissionFee = PurchaseConditions.KeepCommissionFee;
		
		If PurchaseConditions.ContractsAreUsed <> Undefined And PurchaseConditions.ContractsAreUsed Then
			
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = Currency;
			Contract = PurchasesServer.GetDefaultContract(
				ThisObject,
				Enums.BusinessTransactions.ConsignmentProcurement,
				AddlParameters);
			
			If ValueIsFilled(Contract) Then
				PaymentInCurrencyUnderContract = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
				If ForeignCurrencyTransaction <> PaymentInCurrencyUnderContract Then
					ForeignCurrencyTransaction = PaymentInCurrencyUnderContract;
					BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
				EndIf;
			EndIf;
			
			PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, BankAccount);
			
			If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") 
				Or GetFunctionalOption("UseVendorARAPInLineOfBusiness") Then
				LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
			EndIf;
		
		Else
			
			If ForeignCurrencyTransaction <> PurchaseConditions.ForeignCurrencyTransaction Then
				ForeignCurrencyTransaction = PurchaseConditions.ForeignCurrencyTransaction;
				BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
			
		EndIf;
		
		ParametersOfAccount = OrganizationSDefaultAccountParameters();
		BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
			BankAccount, PaymentMethod);
		
	EndIf;
	
EndProcedure

Procedure FillInTermsOfPurchaseUnderAgreement(RecalculatePrices_ = True) Export
	
	PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms);
	FillInTermsOfPurchase(PurchaseConditions);
	
	FillParameters = Documents.ConsignmentReportToVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	If RecalculatePrices_ Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.Insert("PopulationFields", "Price, VATRate");
		FillParameters.Insert("Date", Date);
		FillParameters.Insert("Currency", Currency);
		FillParameters.Insert("Terms", Terms);
		FillParameters.Insert("VATTaxation", VATTaxation);
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		
		PartnerPricesFillingServer.FillInPrices(
			Goods,
			Undefined, // Array of strings
			FillParameters,
			StructureOfActions);
			
		EndIf;
		
	ConsignmentSalesServer.FillInAmountWithVAT(Goods, PriceIncludesVAT);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization		= SettingsValueCached.GetDefaultOrganization(Organization);
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		BankAccount, PaymentMethod);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization    	= Organization;
	ParametersStructure.PaymentMethod		= PaymentMethod;
	ParametersStructure.CashAccount 			= CashAccount;
	CashAccount			= SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	Currency			= IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
	
	FillParameters = Documents.ConsignmentReportToVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager		= TemporaryDocumentDataTables();
	RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	AdditionalProperties.Insert("MonitorCCDNumbers", False);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		ThereAreGoodsWithoutQuantity = ThereAreGoodsWithoutQuantity(TempTablesManager);
		
		FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
		FillParameters.WithoutSelectionByCCDNumbers = True;
		FillParameters.NameOfRemainderTable = "GoodsToBeRegisteredInReportsToConsignor";
		FillParameters.SelectAmountsWithZeroAmount = ThereAreGoodsWithoutQuantity;
		FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
		
		SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
		SelectionOfStockTypes_.Organization = Organization;
		SelectionOfStockTypes_.GoodsOwner = Partner;
		SelectionOfStockTypes_.Contract = Contract;
		SelectionOfStockTypes_.Currency = Currency;
		SelectionOfStockTypes_.Terms = Terms;
		SelectionOfStockTypes_.InventoryType = Enums.InventoryTypes.ConsignedGoods;
		SelectionOfStockTypes_.VATTaxation = VATTaxation;
		
		InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, VATRate",
							"Count, NumberOfPackages, QuantityByGBRN, AmountIncludingVAT, VATAmount, CommissionAmount");
		
		If Not Cancel Then
			FillInInvoiceDataByQuantity(ThereAreGoodsWithoutQuantity);
			FillInInvoiceDataWithoutQuantity();
		EndIf;
		
	EndIf;
	
EndProcedure

Function TemporaryDocumentDataTables()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date			AS Date,
	|	&Organization	AS Organization,
	|	&Partner		AS Partner,
	|	&Counterparty		AS Counterparty,
	|	&Terms		AS Terms,
	|	&Contract		AS Contract,
	|	&Currency			AS Currency,
	|	&VATTaxation	AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor)	AS BusinessOperation,
	|	FALSE			AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.ConsignedGoods)		AS InventoryType,
	|	&DocumentSales	AS DocumentSales
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	TableOfGoods.TaxInvoiceDate						AS TaxInvoiceDate,
	|	TableOfGoods.CustomerInvoiceIssued				AS CustomerInvoiceIssued,
	|	TableOfGoods.Customer							AS Customer,
	|	TableOfGoods.Count							AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END												AS QuantityByGBRN,
	|	CAST(TableOfGoods.VATRate AS Catalog.VATRates) AS VATRate,
	|	TableOfGoods.SalesAmount							AS SalesAmount,
	|	TableOfGoods.CommissionAmount					AS CommissionAmount,
	|	0													AS AmountVATRemuneration,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|	TRUE												AS SelectTypesOfStocks,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber,
	|	TableOfGoods.SellingPrice							AS Price,
	|	TableOfGoods.NumberOfPackages					AS NumberOfPackages,
	|	TableOfGoods.Package								AS Package,
	|	&DocumentSales									AS DocumentSalesOfGoodsAndServices
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
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	0 AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.TaxInvoiceDate				AS TaxInvoiceDate,
	|	TableOfGoods.CustomerInvoiceIssued		AS CustomerInvoiceIssued,
	|	TableOfGoods.Customer					AS Customer,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.QuantityByGBRN				AS QuantityByGBRN,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.CommissionAmount			AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration		AS AmountVATRemuneration,
	|	TableOfGoods.Warehouse						AS Warehouse,
	|	TableOfGoods.SalesOpportunity						AS SalesOpportunity,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.SelectTypesOfStocks			AS SelectTypesOfStocks,
	|	TableOfGoods.SalesAmount					AS AmountIncludingVAT,
	|	CAST(TableOfGoods.SalesAmount * 
	|		TableOfGoods.VATRate.Rate1 / (100 + TableOfGoods.VATRate.Rate1) AS NUMBER(31, 2)) AS VATAmount,
	|	TableOfGoods.CCDNumber						AS CCDNumber,
	|	TableOfGoods.Price							AS Price,
	|	TableOfGoods.NumberOfPackages			AS NumberOfPackages,
	|	TableOfGoods.Package						AS Package,
	|	CASE
	|		WHEN TableOfGoods.DocumentSalesOfGoodsAndServices = VALUE(Document.CustomerInvoice.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TableOfGoods.DocumentSalesOfGoodsAndServices
	|	END AS DocumentSalesOfGoodsAndServices
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.TaxInvoiceDate					AS TaxInvoiceDate,
	|	TableTypesOfStocks_.CustomerInvoiceIssued			AS CustomerInvoiceIssued,
	|	TableTypesOfStocks_.Customer						AS Customer,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	TableTypesOfStocks_.VATRate						AS VATRate,
	|	TableTypesOfStocks_.Count						AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END												AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT						AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount							AS VATAmount,
	|	TableTypesOfStocks_.CommissionAmount				AS CommissionAmount,
	|	0													AS AmountVATRemuneration,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS OriginWarehouse,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually							AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.Price								AS Price,
	|	TableTypesOfStocks_.NumberOfPackages				AS NumberOfPackages,
	|	TableTypesOfStocks_.Package							AS Package,
	|	&DocumentSales									AS DocumentSalesOfGoodsAndServices
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	Dimension.Series									AS Series,
	|	TableTypesOfStocks_.TaxInvoiceDate				AS TaxInvoiceDate,
	|	TableTypesOfStocks_.CustomerInvoiceIssued		AS CustomerInvoiceIssued,
	|	TableTypesOfStocks_.Customer					AS Customer,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	UNDEFINED									AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount						AS VATAmount,
	|	TableTypesOfStocks_.CommissionAmount			AS CommissionAmount,
	|	TableTypesOfStocks_.AmountVATRemuneration		AS AmountVATRemuneration,
	|	TableTypesOfStocks_.OriginWarehouse				AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse						AS Warehouse,
	|	TableTypesOfStocks_.SalesOpportunity						AS SalesOpportunity,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually	AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.Price								AS Price,
	|	TableTypesOfStocks_.NumberOfPackages				AS NumberOfPackages,
	|	TableTypesOfStocks_.Package							AS Package,
	|	CASE
	|		WHEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices = VALUE(Document.CustomerInvoice.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|	END AS DocumentSalesOfGoodsAndServices
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
	Query.SetParameter("Partner",					Partner);
	Query.SetParameter("Counterparty",					Counterparty);
	Query.SetParameter("Terms",					Terms);
	Query.SetParameter("Contract",					Contract);
	Query.SetParameter("Currency",						Currency);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually",	InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("TableOfGoods",				TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",			InventoryKinds);
	Query.SetParameter("VATTaxation", 		VATTaxation);
	Query.SetParameter("DocumentSales",			DocumentSales);
	
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

// This procedure creates a temporary table of available inventory types.
//
// Parameters:
//  TempTablesManager - TempTablesManager - temporary table Manager
Procedure GenerateAvailableInventoryTypes(TempTablesManager) Export
	
	Query = New Query("

	|SELECT
	|	InventoryKinds.Ref AS InventoryOwnerAttribute,
	|	InventoryKinds.Ref AS SellerInventoryOwnerAttribute,
	|	FALSE AS SelectionAccordingToCommitteeSVATRate,
	|	UNDEFINED AS CommitteeSVATRate
	|
	|INTO AvailableTypesOfStocks
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	NOT InventoryKinds.SaleOfAnotherCompanyInventory
	|	AND NOT InventoryKinds.DeletionMark
	|	AND InventoryKinds.Organization = &Organization
	|	AND InventoryKinds.GoodsOwner = &Partner
	|	AND InventoryKinds.Terms = &Terms
	|	AND InventoryKinds.Currency = &Currency
	|	AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|INDEX BY
	|	InventoryOwnerAttribute
	|");
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Terms", Terms);
	Query.SetParameter("Currency", Currency);
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.Execute();
	
EndProcedure

Procedure FillInInvoiceDataByQuantity(ThereAreGoodsWithoutQuantity)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.LineNumber					AS LineNumber,
	|	Goods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	CASE
	|		WHEN Goods.Count > 0
	|			THEN 1
	|		ELSE -1
	|	END								AS Character,
	|	Goods.Count					AS Count,
	|	Goods.VATRate					AS VATRate,
	|	Goods.SalesAmount					AS SalesAmount,
	|	Goods.AmountSalesVAT				AS AmountSalesVAT,
	|	Goods.CommissionAmount			AS CommissionAmount,
	|	Goods.Customer					AS Customer,
	|	Goods.TaxInvoiceDate				AS TaxInvoiceDate,
	|	Goods.CustomerInvoiceIssued		AS CustomerInvoiceIssued,
	|	Goods.SellingPrice					AS SellingPrice,
	|	Goods.Package						AS Package,
	|	Goods.NumberOfPackages			AS NumberOfPackages
	|
	|INTO Goods
	|FROM
	|	&GoodsTable AS Goods
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	VATRate
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT DISTINCT
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.VATRate AS VATRate
	|
	|INTO TTGoodsTableWithoutQuantity
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.Count = 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	Goods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Goods.Character							AS Character,
	|	SUM(Goods.Count)			AS Count,
	|	Goods.VATRate					AS VATRate,	
	|	SUM(Goods.SalesAmount)			AS SalesAmount,
	|	SUM(Goods.AmountSalesVAT)		AS AmountSalesVAT,
	|	SUM(Goods.CommissionAmount)	AS CommissionAmount,
	|	Goods.SellingPrice					AS Price,
	|	Goods.Package						AS Package,
	|	SUM(Goods.NumberOfPackages)	AS NumberOfPackages,
	|	CASE
	|		WHEN TableOfGoodsWithoutQuantity.ItemsLocationAttributes IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS DistributeAmounts
	|FROM
	|	Goods AS Goods
	|
	|	LEFT JOIN TTGoodsTableWithoutQuantity AS TableOfGoodsWithoutQuantity
	|		ON TableOfGoodsWithoutQuantity.ItemsLocationAttributes = Goods.ItemsLocationAttributes
	|		AND TableOfGoodsWithoutQuantity.VATRate = Goods.VATRate
	|
	|WHERE
	|	Goods.Count <> 0
	|
	|GROUP BY
	|	Goods.ItemsLocationAttributes,
	|	Goods.Character,
	|	Goods.VATRate,
	|	Goods.SellingPrice,
	|	Goods.Package,
	|	CASE
	|		WHEN TableOfGoodsWithoutQuantity.ItemsLocationAttributes IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	Goods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Goods.Character							AS Character,
	|	SUM(Goods.Count)			AS Count,
	|	Goods.VATRate					AS VATRate,
	|	SUM(Goods.SalesAmount)			AS SalesAmount,
	|	SUM(Goods.AmountSalesVAT)		AS AmountSalesVAT,
	|	SUM(Goods.CommissionAmount)	AS CommissionAmount,
	|	Goods.Customer					AS Customer,
	|	Goods.TaxInvoiceDate				AS TaxInvoiceDate,
	|	Goods.CustomerInvoiceIssued		AS CustomerInvoiceIssued,
	|	Goods.SellingPrice					AS Price,
	|	Goods.Package						AS Package,
	|	SUM(Goods.NumberOfPackages)	AS NumberOfPackages,
	|	CASE
	|		WHEN TableOfGoodsWithoutQuantity.ItemsLocationAttributes IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS DistributeAmounts
	|FROM
	|	Goods AS Goods
	|	
	|	LEFT JOIN TTGoodsTableWithoutQuantity AS TableOfGoodsWithoutQuantity
	|		ON TableOfGoodsWithoutQuantity.ItemsLocationAttributes = Goods.ItemsLocationAttributes
	|		AND TableOfGoodsWithoutQuantity.VATRate = Goods.VATRate
	|
	|WHERE
	|	Goods.Count <> 0
	|
	|GROUP BY
	|	Goods.ItemsLocationAttributes,
	|	Goods.Character,
	|	Goods.VATRate,
	|	Goods.Customer,
	|	Goods.TaxInvoiceDate,
	|	Goods.CustomerInvoiceIssued,
	|	Goods.SellingPrice,
	|	Goods.Package,
	|	CASE
	|		WHEN TableOfGoodsWithoutQuantity.ItemsLocationAttributes IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END";
	
	Query.SetParameter("GoodsTable", Goods);
	
	QueryResul	= Query.ExecuteBatch();
	GoodsTable	= QueryResul[QueryResul.UBound() - 1].Unload();
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, VATRate");
	
	For Each RowOfGoods In GoodsTable Do
		
		NumberOfProductsPerLine_ = RowOfGoods.Count;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			If InventoryLine.Count > 0 Then
				Count = Min(NumberOfProductsPerLine_, InventoryLine.Count);
			Else
				Count = Max(NumberOfProductsPerLine_, InventoryLine.Count);
			EndIf;
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.Count			= Count;
			NewRow.NumberOfPackages	= Count * RowOfGoods.NumberOfPackages
														/ RowOfGoods.Count;

			NewRow.QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			NewRow.VATAmount			= Count * RowOfGoods.AmountSalesVAT / RowOfGoods.Count;
			NewRow.AmountIncludingVAT			= Count * RowOfGoods.SalesAmount / RowOfGoods.Count;
			NewRow.CommissionAmount	= Count * RowOfGoods.CommissionAmount / RowOfGoods.Count;
			
			InventoryLine.Count			= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN		= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.VATAmount				= InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.AmountIncludingVAT				= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.CommissionAmount	= InventoryLine.CommissionAmount - NewRow.CommissionAmount;
			
			If RowOfGoods.DistributeAmounts And InventoryLine.AmountIncludingVAT <> 0
				And InventoryLine.Count = 0 Then
				
				NewRow.VATAmount			= InventoryLine.VATAmount + NewRow.VATAmount;
				NewRow.AmountIncludingVAT			= InventoryLine.AmountIncludingVAT + NewRow.AmountIncludingVAT;
				NewRow.CommissionAmount	= InventoryLine.CommissionAmount + NewRow.CommissionAmount;
				
			EndIf;
			
			NumberOfProductsPerLine_ = NumberOfProductsPerLine_ - NewRow.Count;
			
			If NumberOfProductsPerLine_ = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If ThereAreGoodsWithoutQuantity Then
		RowFilter = New Structure("Count,AmountIncludingVAT,VATAmount,CommissionAmount", 0, 0, 0, 0);
	Else
		RowFilter = New Structure("Count", 0);
	EndIf;
	
	LinesToDelete	= InventoryKinds.FindRows(RowFilter);
	
	For Each InventoryLine In LinesToDelete Do
		InventoryKinds.Delete(InventoryLine);
	EndDo;
	
	GoodsTable = QueryResul[QueryResul.UBound()].Unload();
	NamesOfGroupingColumns = "ItemsLocationAttributes, VATRate, Customer, TaxInvoiceDate,
								|CustomerInvoiceIssued, Package, Price";
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, VATRate");
	
	For Each RowOfGoods In GoodsTable Do
		
		NumberOfProductsPerLine_ = RowOfGoods.Count;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0
				Or (InventoryLine.Count > 0
					And NumberOfProductsPerLine_ < 0)
				Or (InventoryLine.Count < 0
					And NumberOfProductsPerLine_ > 0) Then
				
				Continue;
				
			EndIf;
			
			If InventoryLine.Count > 0 Then
				Count = Min(NumberOfProductsPerLine_, InventoryLine.Count);
			Else
				Count = Max(NumberOfProductsPerLine_, InventoryLine.Count);
			EndIf;
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			FillPropertyValues(NewRow, RowOfGoods, NamesOfGroupingColumns);
			
			NewRow.Count			= Count;
			NewRow.NumberOfPackages	= Count * RowOfGoods.NumberOfPackages
														/ RowOfGoods.Count;
			NewRow.QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			NewRow.VATAmount			= Count * RowOfGoods.AmountSalesVAT / RowOfGoods.Count;
			NewRow.AmountIncludingVAT			= Count * RowOfGoods.SalesAmount / RowOfGoods.Count;
			NewRow.CommissionAmount	= Count * RowOfGoods.CommissionAmount / RowOfGoods.Count;
			
			InventoryLine.Count			= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN		= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.VATAmount				= InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.AmountIncludingVAT				= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.CommissionAmount	= InventoryLine.CommissionAmount - NewRow.CommissionAmount;
			
			If RowOfGoods.DistributeAmounts And InventoryLine.AmountIncludingVAT <> 0
				And InventoryLine.Count = 0 Then
				
				NewRow.VATAmount			= InventoryLine.VATAmount + NewRow.VATAmount;
				NewRow.AmountIncludingVAT			= InventoryLine.AmountIncludingVAT + NewRow.AmountIncludingVAT;
				NewRow.CommissionAmount	= InventoryLine.CommissionAmount + NewRow.CommissionAmount;
				
			EndIf;
			
			NumberOfProductsPerLine_ = NumberOfProductsPerLine_ - NewRow.Count;
			
			If NumberOfProductsPerLine_ = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	LinesToDelete = InventoryKinds.FindRows(RowFilter);
	
	For Each InventoryLine In LinesToDelete Do
		InventoryKinds.Delete(InventoryLine);
	EndDo;
	
	If ThereAreGoodsWithoutQuantity Then
		
		For Each RowOfGoods In GoodsTable Do
			
			If RowOfGoods.DistributeAmounts Then
				
				RowFilter = New Structure("Count,ItemsLocationAttributes,VATRate", 0, RowOfGoods.ItemsLocationAttributes, RowOfGoods.VATRate);
				LinesToDelete = InventoryKinds.FindRows(RowFilter);
	
				For Each InventoryLine In LinesToDelete Do
					InventoryKinds.Delete(InventoryLine);
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;

EndProcedure

Procedure FillInInvoiceDataWithoutQuantity()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.LineNumber					AS LineNumber,
	|	Goods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	CASE
	|		WHEN Goods.Count > 0
	|			THEN 1
	|		ELSE -1
	|	END								AS Character,
	|	Goods.Count					AS Count,
	|	Goods.VATRate					AS VATRate,
	|	Goods.SalesAmount					AS SalesAmount,
	|	Goods.AmountSalesVAT				AS AmountSalesVAT,
	|	Goods.CommissionAmount			AS CommissionAmount,
	|	Goods.Customer					AS Customer,
	|	Goods.TaxInvoiceDate				AS TaxInvoiceDate,
	|	Goods.CustomerInvoiceIssued		AS CustomerInvoiceIssued,
	|	Goods.SellingPrice					AS SellingPrice,
	|	Goods.Package						AS Package,
	|	Goods.NumberOfPackages			AS NumberOfPackages
	|
	|INTO Goods
	|FROM
	|	&GoodsTable AS Goods
	|WHERE
	|	Goods.Count = 0
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	VATRate
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Goods.Character							AS Character,
	|	SUM(Goods.Count)			AS Count,
	|	Goods.VATRate					AS VATRate,	
	|	SUM(Goods.SalesAmount)			AS SalesAmount,
	|	SUM(Goods.AmountSalesVAT)		AS AmountSalesVAT,
	|	SUM(Goods.CommissionAmount)	AS CommissionAmount,
	|	Goods.SellingPrice					AS Price,
	|	Goods.Package						AS Package,
	|	SUM(Goods.NumberOfPackages)	AS NumberOfPackages
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.ItemsLocationAttributes,
	|	Goods.Character,
	|	Goods.VATRate,
	|	Goods.SellingPrice,
	|	Goods.Package
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	Goods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Goods.Character							AS Character,
	|	SUM(Goods.Count)			AS Count,
	|	Goods.VATRate					AS VATRate,
	|	SUM(Goods.SalesAmount)			AS SalesAmount,
	|	SUM(Goods.AmountSalesVAT)		AS AmountSalesVAT,
	|	SUM(Goods.CommissionAmount)	AS CommissionAmount,
	|	Goods.Customer					AS Customer,
	|	Goods.TaxInvoiceDate				AS TaxInvoiceDate,
	|	Goods.CustomerInvoiceIssued		AS CustomerInvoiceIssued,
	|	Goods.SellingPrice					AS Price,
	|	Goods.Package						AS Package,
	|	SUM(Goods.NumberOfPackages)	AS NumberOfPackages
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.ItemsLocationAttributes,
	|	Goods.Character,
	|	Goods.VATRate,
	|	Goods.Customer,
	|	Goods.TaxInvoiceDate,
	|	Goods.CustomerInvoiceIssued,
	|	Goods.SellingPrice,
	|	Goods.Package";
	
	Query.SetParameter("GoodsTable", Goods);
	
	QueryResul	= Query.ExecuteBatch();
	GoodsTable	= QueryResul[QueryResul.UBound() - 1].Unload();
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, VATRate, Count");
	
	For Each RowOfGoods In GoodsTable Do
		
		SumWithVATPerLine         = RowOfGoods.SalesAmount;
		VATAmountPerLine          = RowOfGoods.AmountSalesVAT;
		AmountOfRemunerationPerLine = RowOfGoods.CommissionAmount;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.AmountIncludingVAT = 0 Then
				Continue;
			EndIf;
			
			If InventoryLine.AmountIncludingVAT > 0 Then
				AmountIncludingVAT = Min(SumWithVATPerLine, InventoryLine.AmountIncludingVAT);
				VATAmount = Min(VATAmountPerLine, InventoryLine.VATAmount);
				AmountOfRemunerationForTypeOfInventory = Min(AmountOfRemunerationPerLine, InventoryLine.CommissionAmount);
			Else
				AmountIncludingVAT = Max(SumWithVATPerLine, InventoryLine.AmountIncludingVAT);
				VATAmount = Max(VATAmountPerLine, InventoryLine.VATAmount);
				AmountOfRemunerationForTypeOfInventory = Max(AmountOfRemunerationPerLine, InventoryLine.CommissionAmount);
			EndIf;
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);

			NewRow.Count			= 0;
			NewRow.NumberOfPackages	= 0;
			NewRow.QuantityByGBRN	= 0;
			
			NewRow.AmountIncludingVAT			= AmountIncludingVAT;
			NewRow.VATAmount			= VATAmount;
			NewRow.CommissionAmount	= AmountOfRemunerationForTypeOfInventory;
			
			InventoryLine.VATAmount				= InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.AmountIncludingVAT				= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.CommissionAmount	= InventoryLine.CommissionAmount - NewRow.CommissionAmount;
			
			If InventoryLine.AmountIncludingVAT = 0
				And InventoryLine.VATAmount <> 0 Then
				NewRow.VATAmount			= InventoryLine.VATAmount + NewRow.VATAmount;
			EndIf;
			If InventoryLine.AmountIncludingVAT = 0
				And InventoryLine.CommissionAmount <> 0 Then
				NewRow.CommissionAmount			= InventoryLine.CommissionAmount + NewRow.CommissionAmount;
			EndIf;
			
			SumWithVATPerLine = SumWithVATPerLine - NewRow.AmountIncludingVAT;
			VATAmountPerLine  = VATAmountPerLine - NewRow.VATAmount;
			AmountOfRemunerationPerLine = AmountOfRemunerationPerLine - NewRow.CommissionAmount;
			
			If SumWithVATPerLine = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	RowFilter		= New Structure("Count,AmountIncludingVAT", 0, 0);
	LinesToDelete	= InventoryKinds.FindRows(RowFilter);
	
	For Each InventoryLine In LinesToDelete Do
		InventoryKinds.Delete(InventoryLine);
	EndDo;
	
	GoodsTable = QueryResul[QueryResul.UBound()].Unload();
	NamesOfGroupingColumns = "ItemsLocationAttributes, VATRate, Customer, TaxInvoiceDate,
								|CustomerInvoiceIssued, Package, Price";
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, VATRate, Count");
	
	For Each RowOfGoods In GoodsTable Do
		
		SumWithVATPerLine         = RowOfGoods.SalesAmount;
		VATAmountPerLine          = RowOfGoods.AmountSalesVAT;
		AmountOfRemunerationPerLine = RowOfGoods.CommissionAmount;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.AmountIncludingVAT = 0
				Or (InventoryLine.AmountIncludingVAT > 0
					And SumWithVATPerLine < 0)
				Or (InventoryLine.AmountIncludingVAT < 0
					And SumWithVATPerLine > 0) Then
				
				Continue;
				
			EndIf;
			
			If InventoryLine.AmountIncludingVAT > 0 Then
				AmountIncludingVAT = Min(SumWithVATPerLine, InventoryLine.AmountIncludingVAT);
				VATAmount = Min(VATAmountPerLine, InventoryLine.VATAmount);
				AmountOfRemunerationForTypeOfInventory = Min(AmountOfRemunerationPerLine, InventoryLine.CommissionAmount);
			Else
				AmountIncludingVAT = Max(SumWithVATPerLine, InventoryLine.AmountIncludingVAT);
				VATAmount = Max(VATAmountPerLine, InventoryLine.VATAmount);
				AmountOfRemunerationForTypeOfInventory = Max(AmountOfRemunerationPerLine, InventoryLine.CommissionAmount);
			EndIf;
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			FillPropertyValues(NewRow, RowOfGoods, NamesOfGroupingColumns);

			NewRow.Count			= 0;
			NewRow.NumberOfPackages	= 0;
			NewRow.QuantityByGBRN	= 0;
			
			NewRow.AmountIncludingVAT			= AmountIncludingVAT;
			NewRow.VATAmount			= VATAmount;
			NewRow.CommissionAmount	= AmountOfRemunerationForTypeOfInventory;

			InventoryLine.Count			= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN		= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.VATAmount				= InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.AmountIncludingVAT				= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.CommissionAmount	= InventoryLine.CommissionAmount - NewRow.CommissionAmount;
			
			If InventoryLine.AmountIncludingVAT = 0
				And InventoryLine.VATAmount <> 0 Then
				NewRow.VATAmount			= InventoryLine.VATAmount + NewRow.VATAmount;
			EndIf;
			If InventoryLine.AmountIncludingVAT = 0
				And InventoryLine.CommissionAmount <> 0 Then
				NewRow.CommissionAmount			= InventoryLine.CommissionAmount + NewRow.CommissionAmount;
			EndIf;
			
			SumWithVATPerLine = SumWithVATPerLine - NewRow.AmountIncludingVAT;
			VATAmountPerLine  = VATAmountPerLine - NewRow.VATAmount;
			AmountOfRemunerationPerLine = AmountOfRemunerationPerLine - NewRow.CommissionAmount;
			
			If SumWithVATPerLine = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	LinesToDelete = InventoryKinds.FindRows(RowFilter);
	
	For Each InventoryLine In LinesToDelete Do
		InventoryKinds.Delete(InventoryLine);
	EndDo;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.ConsignmentReportToVendor.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.ConsignmentReportToVendor.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.ConsignmentReportToVendor,
					Undefined,
					Department,
					Partner);
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.BatchesIndicationStatus = "";
	FieldsNames.Purpose = "";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Partner, Terms, Currency";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.TaxInvoiceDate AS TaxInvoiceDate,
	|	TableOfGoods.CustomerInvoiceIssued AS CustomerInvoiceIssued,
	|	TableOfGoods.Customer AS Customer
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate AS VATRate,
	|		TableOfGoods.TaxInvoiceDate AS TaxInvoiceDate,
	|		TableOfGoods.CustomerInvoiceIssued AS CustomerInvoiceIssued,
	|		TableOfGoods.Customer AS Customer,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.CommissionAmount AS CommissionAmount,
	|		TableOfGoods.AmountVATRemuneration AS AmountVATRemuneration
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Products.ItemsType IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		TableTypesOfStocks_.TaxInvoiceDate AS TaxInvoiceDate,
	|		TableTypesOfStocks_.CustomerInvoiceIssued AS CustomerInvoiceIssued,
	|		TableTypesOfStocks_.Customer AS Customer,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount AS VATAmount,
	|		-TableTypesOfStocks_.CommissionAmount AS CommissionAmount,
	|		-TableTypesOfStocks_.AmountVATRemuneration AS AmountVATRemuneration
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.TaxInvoiceDate,
	|	TableOfGoods.CustomerInvoiceIssued,
	|	TableOfGoods.Customer
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.CommissionAmount) <> 0
	|	OR SUM(TableOfGoods.AmountVATRemuneration) <> 0";
	
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Function ThereAreGoodsWithoutQuantity(TempTablesManager)

	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT TOP 1
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|
	|WHERE
	| TableOfGoods.Count = 0";
	
	Return (Not Query.Execute().IsEmpty());

EndFunction

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

#EndRegion

#EndIf
