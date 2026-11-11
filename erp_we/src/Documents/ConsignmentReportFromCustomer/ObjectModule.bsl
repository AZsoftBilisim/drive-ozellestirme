#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.ConsignmentReportFromCustomer - the document for which parameters are initialized.
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
//	DocumentTables - See Documents.ConsignmentReportFromCustomer.CollectionOfTabularPartsOfGoods.
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

	IncomingDocumentDate		= Date(1,1,1);
	IncomingDocumentNumber		= "";
	InventoryOwnerAttributesAreSpecifiedManually	= False;
	
	InventoryKinds.Clear();
	
	CurrentRow = New Structure("VATRate", Catalogs.VATRates.EmptyRef());

	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	VATRateOfRemuneration = CurrentRow.VATRate;

	AmountVATRemuneration = VATAccountingERPClientServer.CalculateVATAmount(CommissionAmount,
		VATAccountingERPClientServer.ValueOfVATRate(VATRateOfRemuneration));
	
	ConsignmentSalesServer.RecalculateBalancesBasedOnAccountingData(
		ThisObject,
		ThisObject.EndOfPeriod,
		True, // ThereIsSaleAmount
		Undefined,
		Undefined);
		
	FillParameters = Documents.ConsignmentReportFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	If Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Terms) Then
		RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
								ThisObject,
								"Partner");
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	EndIf;
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	If Not ItemOfExpensesForCostOfGoodsSellingIsIndicated() Then
		ExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	EndIf;
	
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
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	ConsignmentReportFromCustomerLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.AuthorizedUser();

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.AuthorizedUser();
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		Return;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("FillInByAgreement") Then
			
			Partner = FillingData.Partner;
			Terms = FillingData.Terms;
			Organization = FillingData.Organization;
			NewCommissionScheme = Common.ObjectAttributeValue(Terms, "ConsignmentSales25");
			If GetFunctionalOption("ToUseTermsOfSales") And ValueIsFilled(Terms) Then
				FillInTermsOfSalesUnderAgreement(FillingData.Organization);
			Else
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
				Contract = SalesServer.GetDefaultContract(
					ThisObject,
					Enums.BusinessTransactions.TransferToCommissionAgent,
					Currency,
					,
					NewCommissionScheme);
				SalesServer.FillInBankAccountsUnderAgreement(Contract, BankAccount);
				
				If NewCommissionScheme Then
					BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent;
				EndIf;
				
				FillParameters = Documents.ConsignmentReportFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
				VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
			EndIf;
			
			ConsignmentSalesServer.FillInBalanceOfGoodsTransferredToCommission(
				ThisObject, 
				FillingData.EndOfPeriod,
				True); // ThereIsSaleAmount
			
		ElsIf FillingData.Property("Partner") Then
			
			If FillingData.Property("BusinessOperation") Then
				BusinessOperation = FillingData.BusinessOperation;
			EndIf;
			
			Partner = FillingData.Partner;
			If GetFunctionalOption("ToUseTermsOfSales") Then
				
				FillInDefaultSalesConditions();
				
				FillParameters = Documents.ConsignmentReportFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
				VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
				
			EndIf;
			
		ElsIf TypeOf(FillingData) = Type("Structure")
			And FillingData.Property("FillInAccordingToDataForRegistration") Then
			
			If FillingData.Property("BusinessOperation") Then
				BusinessOperation = FillingData.BusinessOperation;
			EndIf;
			
			CachedParameterValues = Undefined;
			Partner = FillingData.HeaderAttributes.Partner;
			FillInDefaultSalesConditions(CachedParameterValues);
			
			Counterparty = FillingData.HeaderAttributes.Counterparty;
			Contract = FillingData.HeaderAttributes.Contract;
			Organization = FillingData.HeaderAttributes.Organization;
			Terms = FillingData.HeaderAttributes.Terms;
			ContractDetails_ = Catalogs.CounterpartyContracts.ObjectAttributes(Contract);
			Currency = ContractDetails_.ARAPCurrency;
			Date = CurrentSessionDate();
			
			If ValueIsFilled(Terms) Then
				FillInTermsOfSalesUnderAgreement(Undefined, CachedParameterValues);
			EndIf;
			
			FillParameters = Documents.ConsignmentReportFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
			VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters, CachedParameterValues);
			
			If BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
				And ValueIsFilled(Contract) And ValueIsFilled(Organization) Then
				
				ConsignmentSalesServer.FillInGoodsOnBalancesTransferredToCommissionUnderNewScheme(ThisObject);
				
			EndIf;
			
		EndIf;
		
		If FillingData.Property("BusinessOperation") Then
			BusinessOperation = FillingData.BusinessOperation;
		EndIf;
		
	EndIf;
	
	InitializeSalesConditions();
	
	If Not ValueIsFilled(BusinessOperation)
		And GetFunctionalOption("OnlyConsignmentSales25") Then
		BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent;
	EndIf;
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	If Not ValueIsFilled(BankAccount) Then
		SalesServer.FillInBankAccountsUnderAgreement(Contract, BankAccount);
	EndIf;
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		BankAccount, PaymentMethod);
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	
	ConsignmentSalesServer.FillInLBRateOfJointCommissionRemuneration(ThisObject);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	If Not ValueIsFilled(FinancialAccountingGroup) And ValueIsFilled(Contract)
		And Not ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		FinancialAccountingGroup = Common.ObjectAttributeValue(Contract,"FinancialAccountingGroup");
	EndIf;
	
	ConsignmentReportFromCustomerLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	Documents.ConsignmentReportFromCustomer.FillInNamesOfBusinessTransactionDetails(
		CommissionFeeCalculationMethod, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		NotCheckedAttributeArray.Add("OperationService");
		NotCheckedAttributeArray.Add("PaymentDate");
		NotCheckedAttributeArray.Add("VATRateOfRemuneration");
		NotCheckedAttributeArray.Add("Department");
	Else
		NotCheckedAttributeArray.Add("Goods.DateOfTaxInvoiceIssuedByCommissionAgent");
	EndIf;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	If Not ValueIsFilled(Terms) Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ConsignmentReportFromCustomer),
												Cancel,
												NotCheckedAttributeArray);
	
	If NotCheckedAttributeArray.Find("PaymentDate") = Undefined Then	
		If ThisObject.KeepCommissionFee Then
			NotCheckedAttributeArray.Add("PaymentDate");	
		EndIf;
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
	
	ConsignmentSalesServer.CheckIfPeriodIsCorrect(ThisObject, Cancel);

	If CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating Then
		ConsignmentSalesServer.CheckCommissionService(ThisObject, Cancel);
	EndIf;
	
	If ByPhysicalCountResults Then
		
		KeyAttributes = New Array;
		KeyAttributes.Add("Products");
		KeyAttributes.Add("Characteristic");
		KeyAttributes.Add("Series");
		KeyAttributes.Add("DateOfTaxInvoiceIssuedByCommissionAgent");
		KeyAttributes.Add("Customer");
		KeyAttributes.Add("CCDNumber");
		TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "Goods", KeyAttributes, Cancel);
		
	EndIf;
	
	ConsignmentReportFromCustomerLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.EmptyRef() Then
		BusinessOperation = Enums.BusinessTransactions.ConsignmentReportFromCustomer;
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
	
	For Each CurRow In Goods Do
		
		If CurRow.NumberOfPackages = 0 Then
			
			CurRow.CommissionAgentSTaxInvoiceNumber = Undefined;
			CurRow.DateOfTaxInvoiceIssuedByCommissionAgent = Undefined;
			CurRow.Customer = Undefined;
			
		EndIf;
	
	EndDo;
	
	AccountingForTraceableGoodsLocalization.ClearGTDUNumbersOfTraceableWorks(ThisObject);
	AccountingForTraceableGoodsLocalization.ClearDataOnImportedGoodsInCommissionAgentSDocuments(ThisObject);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject,
				Documents.ConsignmentReportFromCustomer));
	
	RegistrationParameters = Documents.ConsignmentReportFromCustomer.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	CashServer.ClearUnusedPaymentFormDetails(ThisObject, PaymentMethod);
		
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	// We will clear the details of the document that are not used for the method of calculating remuneration.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.ConsignmentReportFromCustomer.FillInNamesOfBusinessTransactionDetails(
		CommissionFeeCalculationMethod,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	RegistrationParameters = Documents.ConsignmentReportFromCustomer.ParametersForRegisteringInvoicesToCommissionAgent(ThisObject);
	VATAccountingERP.UpdateInvoicesToCommissionAgentBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	If IsNew() And Not ValueIsFilled(Author) Then
		Author = Users.AuthorizedUser();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RegistrationParameters = Documents.ConsignmentReportFromCustomer.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
	RegistrationParameters = Documents.ConsignmentReportFromCustomer.ParametersForRegisteringInvoicesToCommissionAgent(ThisObject);
	VATAccountingERP.UpdateInvoicesToCommissionAgentWhenConducting(RegistrationParameters);
	
	ConsignmentReportFromCustomerLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RegistrationParameters = Documents.ConsignmentReportFromCustomer.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
	RegistrationParameters = Documents.ConsignmentReportFromCustomer.ParametersForRegisteringInvoicesToCommissionAgent(ThisObject);
	VATAccountingERP.UpdateInvoicesToCommissionAgentWhenDeletingThem(RegistrationParameters);
	
	ConsignmentReportFromCustomerLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ConsignmentReportFromCustomerLocalization.OnWrite(ThisObject, Cancel);

EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions) Export
	
	If SalesTermsAndConditions <> Undefined Then
	
		If ValueIsFilled(SalesTermsAndConditions.Currency) Then
			Currency = SalesTermsAndConditions.Currency;
		EndIf;
		LineOfBusiness = SalesTermsAndConditions.LineOfBusiness;
		NewCommissionScheme = SalesTermsAndConditions.NewCommissionScheme;
		
		If ValueIsFilled(SalesTermsAndConditions.PaymentSchedule) Then
			PaymentSchedule = SalesTermsAndConditions.PaymentSchedule;
		EndIf;
		
		PaymentMethod        = SalesTermsAndConditions.PaymentMethod;
		PriceIncludesVAT    = SalesTermsAndConditions.PriceIncludesVAT;
		
		OrganizationChanged = ValueIsFilled(SalesTermsAndConditions.Organization) And SalesTermsAndConditions.Organization <> Organization;
		PaymentFormChanged = ValueIsFilled(SalesTermsAndConditions.PaymentMethod) And SalesTermsAndConditions.PaymentMethod <> PaymentMethod;
		
		PaymentMethod = SalesTermsAndConditions.PaymentMethod;
		
		If OrganizationChanged Then
			Organization = SalesTermsAndConditions.Organization;
			BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
		If OrganizationChanged Or PaymentFormChanged Then
			
			ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
			ParametersStructure.Organization    			= Organization;
			ParametersStructure.LineOfBusiness = LineOfBusiness;
			ParametersStructure.PaymentMethod 			= PaymentMethod;
			CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
			
		EndIf;
		
		If ValueIsFilled(SalesTermsAndConditions.CommissionFeeCalculationMethod) Then
			CommissionFeeCalculationMethod = SalesTermsAndConditions.CommissionFeeCalculationMethod;
		EndIf;
		If ValueIsFilled(SalesTermsAndConditions.RemunerationPercentage) Then
			RemunerationPercentage = SalesTermsAndConditions.RemunerationPercentage;
		EndIf;
		KeepCommissionFee = SalesTermsAndConditions.KeepCommissionFee;
		
		If ValueIsFilled(SalesTermsAndConditions.FinancialAccountingGroup) Then
			FinancialAccountingGroup = SalesTermsAndConditions.FinancialAccountingGroup;
		EndIf;
		
		If Not SalesTermsAndConditions.Standard_
		 And ValueIsFilled(SalesTermsAndConditions.Counterparty) Then
			Counterparty = SalesTermsAndConditions.Counterparty;
		EndIf;
		
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		
		If SalesTermsAndConditions.ContractsAreUsed <> Undefined And SalesTermsAndConditions.ContractsAreUsed Then
			
			Contract = SalesServer.GetDefaultContract(
				ThisObject,
				Enums.BusinessTransactions.TransferToCommissionAgent,
				Currency,
				,
				NewCommissionScheme);
			
			If ValueIsFilled(Contract) Then
				PaymentInCurrencyUnderContract = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
				If ForeignCurrencyTransaction <> PaymentInCurrencyUnderContract Then
					ForeignCurrencyTransaction = PaymentInCurrencyUnderContract;
					BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
				EndIf;
			EndIf;
			
			SalesServer.FillInBankAccountsUnderAgreement(Contract, BankAccount);
			
			If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
				LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
			EndIf;
		
		Else
			
			If ForeignCurrencyTransaction <> SalesTermsAndConditions.ForeignCurrencyTransaction Then
				ForeignCurrencyTransaction = SalesTermsAndConditions.ForeignCurrencyTransaction;
				BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
			
		EndIf;
		
		ParametersOfAccount = OrganizationSDefaultAccountParameters();
		BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
			BankAccount, PaymentMethod);
		
		If NewCommissionScheme Then
			BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInDefaultSalesConditions(CachedParameterValues = Undefined) Export
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");

	If ValueIsFilled(Partner) Or Not ToUseTermsOfSales Then
		
		ConsignmentSales25 = ?(BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent, True, False);
		
		FilterParameters = New Structure();
		FilterParameters.Insert("BusinessTransactions", Enums.BusinessTransactions.TransferToCommissionAgent); 
		FilterParameters.Insert("SelectedAgreement", Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.ConsignmentReportFromCustomer.EmptyRef());
		FilterParameters.Insert("ConsignmentSales25", ConsignmentSales25);
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(Partner, FilterParameters);
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales Or
				(Terms <> DefaultSalesTerms.Terms And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				
				FillParameters = Documents.ConsignmentReportFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
				VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters, CachedParameterValues);
				
				If ToUseTermsOfSales Then
					StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
					
					FillParameters = New Structure;
					FillParameters.Insert("Date", ?(ValueIsFilled(EndOfPeriod), EndOfPeriod, Date));
					FillParameters.Insert("Organization", Organization);
					FillParameters.Insert("Currency", Currency);
					FillParameters.Insert("Terms", Terms);
					FillParameters.Insert("VATTaxation", VATTaxation);
					FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind");
					StructureOfActions = New Structure;
					StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
					StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					
					EnterprisePricesFillingServer.FillInPrices(
						Goods, // Table part
						, // Array of rows or selection structure
						FillParameters,
						StructureOfActions);
				EndIf;
			Else
				Terms = DefaultSalesTerms.Terms;
			EndIf;
		Else
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			Terms = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInTermsOfSalesUnderAgreement(ParameterOrganization = Undefined, CachedParameterValues = Undefined) Export
	
	SetPrivilegedMode(True);
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms);
	If Organization <> Undefined Then
		SalesTermsAndConditions.Organization = ParameterOrganization;
	EndIf;
	FillIn_TermsOfSales(SalesTermsAndConditions);
	SetPrivilegedMode(False);
	
	FillParameters = Documents.ConsignmentReportFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters, CachedParameterValues);
	
	// Initialization of common parameters for further price calculations:	
	GeneralParametersForFillingInPrice = EnterprisePricesFillingServer.NewFillOptionsFillPrices();
	FillPropertyValues(GeneralParametersForFillingInPrice, ThisObject);
	
	If ValueIsFilled(EndOfPeriod) Then
		GeneralParametersForFillingInPrice.Date = EndOfPeriod;
	EndIf;
	
	If ValueIsFilled(ParameterOrganization) Then
		GeneralParametersForFillingInPrice.Organization = ParameterOrganization;
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	// Calculation of transmission prices:
	FillParameters = Common.CopyRecursive(GeneralParametersForFillingInPrice);
	FillParameters.PopulationFields = "PriceKind, Price, VATRate";
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(ThisObject));
	
	If SalesTermsAndConditions.NewCommissionScheme Then
		// The price type in the "New Commission" is used from the Contract 
		FillParameters.PriceKind = Common.ObjectAttributeValue(Contract, "PriceTypeAccountingPriceType");
	EndIf;
		
	EnterprisePricesFillingServer.FillInPrices(
		Goods, // Table part
		, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	// Calculation of sales prices:
	If SalesTermsAndConditions.NewCommissionScheme Then 
		ParametersFillingInSale = Common.CopyRecursive(GeneralParametersForFillingInPrice);
		ParametersFillingInSale.PopulationFields = "SellingPriceType, SellingPrice";
		ParametersFillingInSale.PriceField = "SellingPrice";
		ParametersFillingInSale.PriceTypeField = "SellingPriceType";
		ParametersFillingInSale.PriceKind = Common.ObjectAttributeValue(Contract, "SalesPriceType");
			
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateSaleAmount");
		StructureOfActions.Insert("RecalculateVATSalesAmount", StructureOfRecalculationOfAmount);
	
		EnterprisePricesFillingServer.FillInPrices(
			Goods, // Table part
			, // Array of rows or selection structure
			ParametersFillingInSale,
			StructureOfActions);
	EndIf;
		
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization		= SettingsValueCached.GetDefaultOrganization(Organization);
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		BankAccount, PaymentMethod);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization = Organization;
	ParametersStructure.PaymentMethod = PaymentMethod;
	ParametersStructure.CashAccount 		= CashAccount;
	CashAccount			= SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure InitializeSalesConditions()
	
	If Not GetFunctionalOption("ToUseTermsOfSales") Then
		FillInDefaultSalesConditions();
	EndIf;
	
EndProcedure

Function ItemOfExpensesForCostOfGoodsSellingIsIndicated()
	
	Result = True;
	
	If ValueIsFilled(ExpenseItem) Then
		
		Attributes = Common.ObjectAttributesValues(ExpenseItem,
			"CostAllocationOptionLocal, CostAllocationOptionManag, CostAllocationOptionTax, ControlDimensionFilling");
		
		ToCostOfGoodsSold = Enums.CostAllocationOptions.ToCostOfGoodsSold;
		
		If Attributes.ControlDimensionFilling
			Or Attributes.CostAllocationOptionLocal <> ToCostOfGoodsSold
			Or Attributes.CostAllocationOptionManag <> ToCostOfGoodsSold
			Or Attributes.CostAllocationOptionTax <> ToCostOfGoodsSold Then
			
			Result = False;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
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

#Region InventoryKinds

Function TemporaryDocumentDataTables(ReversingEntry, FilterByProductType = "All")
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date			AS Date,
	|	&EndOfPeriod	AS EndOfPeriod,
	|	&Organization	AS Organization,
	|	&Partner		AS Partner,
	|	&Counterparty		AS Counterparty,
	|	&Terms		AS Terms,
	|	&Contract		AS Contract,
	|	&Currency			AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|	FALSE			AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
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
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus = 18
	|				OR TableOfGoods.BatchesIndicationStatus = 14
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END												AS Series,
	|	TableOfGoods.BatchesIndicationStatus					AS BatchesIndicationStatus,
	|	TableOfGoods.Count							AS Count,
	|	TableOfGoods.QuantityByGBRN						AS QuantityByGBRN,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
	|			THEN &Contract
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END												AS Warehouse,
	|	TableOfGoods.FEACNCode								AS FEACNCode,
	|	TableOfGoods.VATRate							AS VATRate,
	|	TableOfGoods.SalesAmount							AS AmountIncludingVAT,
	|	TableOfGoods.AmountSalesVAT						AS VATAmount,
	|	TableOfGoods.CommissionAmount					AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration				AS AmountVATRemuneration,
	|	TableOfGoods.CCDNumber								AS CCDNumber,
	|	TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent			AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableOfGoods.CommissionAgentSTaxInvoiceNumber		AS CommissionAgentSTaxInvoiceNumber,
	|	TableOfGoods.Customer							AS Customer,
	|	&Terms											AS Terms,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	TRUE												AS SelectTypesOfStocks
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|WHERE
	|	TableOfGoods.Count > 0
	|		AND NOT &ReversingEntry
	|	OR TableOfGoods.Count < 0
	|		AND &ReversingEntry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber						AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableOfGoods.Products						AS Products,
	|	TableOfGoods.Characteristic					AS Characteristic,
	|	TableOfGoods.Purpose						AS Purpose,
	|	TableOfGoods.Series							AS Series,
	|	TableOfGoods.BatchesIndicationStatus				AS BatchesIndicationStatus,
	|	TableOfGoods.Count						AS Count,
	|	CASE
	|		WHEN NOT (&UseTraceableImportedGoodsAccounting
	|					AND BEGINOFPERIOD(&Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart)
	|				OR NOT ISNULL(AgreementData.CommissionAgentUsesInventoryAccountingByProductBatchID, FALSE)
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END											AS QuantityByGBRN,
	|	TableOfGoods.Warehouse							AS Warehouse,
	|	TableOfGoods.FEACNCode							AS FEACNCode,
	|	TableOfGoods.VATRate						AS VATRate,
	|	TableOfGoods.AmountIncludingVAT						AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount							AS VATAmount,
	|	TableOfGoods.CommissionAmount				AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration			AS AmountVATRemuneration,
	|	TableOfGoods.CCDNumber							AS CCDNumber,
	|	TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent		AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableOfGoods.CommissionAgentSTaxInvoiceNumber	AS CommissionAgentSTaxInvoiceNumber,
	|	TableOfGoods.Customer						AS Customer,
	|	TableOfGoods.SalesOpportunity							AS SalesOpportunity,
	|	TableOfGoods.SelectTypesOfStocks				AS SelectTypesOfStocks
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|
	|		LEFT JOIN Catalog.TermsOfSale AS AgreementData
	|		ON TableOfGoods.Terms = AgreementData.Ref
	|
	|WHERE
	|	&FilterOfProducts_
	|	AND ProductData_1.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|											VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber						AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableOfGoods.Products						AS Products,
	|	TableOfGoods.Characteristic					AS Characteristic,
	|	TableOfGoods.Purpose						AS Purpose,
	|	TableOfGoods.Series							AS Series,
	|	TableOfGoods.BatchesIndicationStatus				AS BatchesIndicationStatus,
	|	TableOfGoods.Count						AS Count,
	|	CASE
	|		WHEN NOT ISNULL(AgreementData.CommissionAgentUsesInventoryAccountingByProductBatchID, FALSE)
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END											AS QuantityByGBRN,
	|	Dimension.StorageLocation							AS Warehouse,
	|	TableOfGoods.FEACNCode							AS FEACNCode,
	|	TableOfGoods.VATRate						AS VATRate,
	|	TableOfGoods.AmountIncludingVAT						AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount							AS VATAmount,
	|	TableOfGoods.CommissionAmount				AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration			AS AmountVATRemuneration,
	|	TableOfGoods.CCDNumber							AS CCDNumber,
	|	TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent		AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableOfGoods.CommissionAgentSTaxInvoiceNumber	AS CommissionAgentSTaxInvoiceNumber,
	|	TableOfGoods.Customer						AS Customer,
	|	TableOfGoods.SalesOpportunity							AS SalesOpportunity,
	|	TableOfGoods.SelectTypesOfStocks				AS SelectTypesOfStocks
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.TermsOfSale AS AgreementData
	|		ON TableOfGoods.Terms = AgreementData.Ref
	|WHERE
	|	&SelectionOfWorks
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND ProductData_1.TracedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count						AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END												AS QuantityByGBRN,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS Warehouse,
	|	TableTypesOfStocks_.FEACNCode							AS FEACNCode,
	|	TableTypesOfStocks_.VATRate						AS VATRate,
	|	TableTypesOfStocks_.AmountIncludingVAT						AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount							AS VATAmount,
	|	TableTypesOfStocks_.CommissionAmount				AS CommissionAmount,
	|	TableTypesOfStocks_.AmountVATRemuneration			AS AmountVATRemuneration,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	TableTypesOfStocks_.DateOfTaxInvoiceIssuedByCommissionAgent		AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableTypesOfStocks_.CommissionAgentSTaxInvoiceNumber	AS CommissionAgentSTaxInvoiceNumber,
	|	TableTypesOfStocks_.Customer						AS Customer,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS OriginWarehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually							AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.Count > 0
	|		AND NOT &ReversingEntry
	|	OR TableTypesOfStocks_.Count < 0
	|		AND &ReversingEntry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	UNDEFINED										AS RecipientInventoryOwnerAttribute,
	|	Dimension.Products								AS Products,
	|	Dimension.Characteristic							AS Characteristic,
	|	Dimension.Series										AS Series,
	|	TableTypesOfStocks_.Count						AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN					AS QuantityByGBRN,
	|	TableTypesOfStocks_.VATRate						AS VATRate,
	|	TableTypesOfStocks_.AmountIncludingVAT						AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount							AS VATAmount,
	|	TableTypesOfStocks_.CommissionAmount				AS CommissionAmount,
	|	TableTypesOfStocks_.AmountVATRemuneration			AS AmountVATRemuneration,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	TableTypesOfStocks_.DateOfTaxInvoiceIssuedByCommissionAgent		AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableTypesOfStocks_.CommissionAgentSTaxInvoiceNumber	AS CommissionAgentSTaxInvoiceNumber,
	|	TableTypesOfStocks_.Customer						AS Customer,
	|	TableTypesOfStocks_.OriginWarehouse					AS OriginWarehouse,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
	|			THEN Dimension.StorageLocation
	|		ELSE TableTypesOfStocks_.Warehouse
	|	END												AS Warehouse,
	|	TableTypesOfStocks_.SalesOpportunity							AS SalesOpportunity,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually		AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON Dimension.Products = ProductData_1.Ref
	|WHERE
	|	ProductData_1.ItemsType IN(&ItemsTypes)
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
	
	ItemsTypes = New Array;
	
	If FilterByProductType = "All" Then
		SelectionOfWorks		= True;
		FilterOfProducts_	= True;
		
		ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
		ItemsTypes.Add(Enums.ItemsTypes.Work_5);
		ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	ElsIf FilterByProductType = "Products" Then
		SelectionOfWorks		= False;
		FilterOfProducts_	= True;
		
		ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
		ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	Else
		SelectionOfWorks		= True;
		FilterOfProducts_	= False;
		
		ItemsTypes.Add(Enums.ItemsTypes.Work_5);
	EndIf;
	
	Query.SetParameter("Ref",				Ref);
	Query.SetParameter("Date",				Date);
	Query.SetParameter("EndOfPeriod",		EndOfPeriod);
	Query.SetParameter("Organization",		Organization);
	Query.SetParameter("Partner",			Partner);
	Query.SetParameter("Counterparty",			Counterparty);
	Query.SetParameter("Terms",			Terms);
	Query.SetParameter("Contract",			Contract);
	Query.SetParameter("Currency",				Currency);
	Query.SetParameter("ReversingEntry",				ReversingEntry);
	Query.SetParameter("SelectionOfWorks",			SelectionOfWorks);
	Query.SetParameter("FilterOfProducts_",		FilterOfProducts_);
	Query.SetParameter("ItemsTypes",	ItemsTypes);
	Query.SetParameter("TableOfGoods",		TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",	InventoryKinds);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.ConsignmentReportFromCustomer);
	Query.SetParameter("VATTaxation", VATTaxation);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	ItemsRowData = ItemsRowData();
	
	TypesOfStocksWereFilled	= False;
	ThereAreReportLines		= ItemsRowData.ThereAreReportLines;
	ThereAreLinesOfStornoReport	= ItemsRowData.ThereAreLinesOfStornoReport;
	
	RefillInventoryKinds = InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	TempTablesManager = TemporaryDocumentDataTables(False);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		ManagerOfTemporaryProductTables	= ?(ItemsRowData.ThereAreLinesOfWorksInReport
												And ItemsRowData.ThereAreRowsOfItemsInReport
												And BusinessOperation <> Enums.BusinessTransactions.SalesViaCommissionAgent,
											TemporaryDocumentDataTables(False, "Products"),
											TempTablesManager);
		ManagerOfTemporaryWorkTables	= ?(ItemsRowData.ThereAreLinesOfWorksInReport
												And ItemsRowData.ThereAreRowsOfItemsInReport
												And BusinessOperation <> Enums.BusinessTransactions.SalesViaCommissionAgent,
											TemporaryDocumentDataTables(False, "Work_5"),
											TempTablesManager);
		
		If ThereAreLinesOfStornoReport Then
			TypesOfStornowReserves = InventoryKinds.UnloadColumns();
			
			For Each InventoryLine In InventoryKinds Do
				If InventoryLine.Count < 0 Then
					FillPropertyValues(TypesOfStornowReserves.Add(), InventoryLine);
				EndIf;
			EndDo;
			
			InventoryKinds.Clear();
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
			FillParameters = ParametersForFillingInventoryTypes();
			
			InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																	TempTablesManager,
																	Cancel,
																	FillParameters);
		Else
			If ItemsRowData.ThereAreRowsOfItemsInReport Then
				FillParameters = ParametersForFillingInventoryTypes();
				
				InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																		ManagerOfTemporaryProductTables,
																		Cancel,
																		FillParameters);
			EndIf;
			
			If ItemsRowData.ThereAreLinesOfWorksInReport Then
				TypesOfStocksOfGoods = TypesOfStocksOfGoods(False);
				InventoryKinds.Clear();
				
				FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
				FillParameters.SelectionOfStockTypes_.Organization = Organization;
				FillParameters.SelectionOfStockTypes_.InventoryType = New Array;
				FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
				FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
				
				InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																		ManagerOfTemporaryWorkTables,
																		Cancel,
																		FillParameters);
				
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStocksOfGoods);
			EndIf;
		EndIf;
		
		NamesOfGroupingColumns		= "ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, VATRate, FEACNCode";
		NamesOfSummationColumns	= "Count, QuantityByGBRN, AmountIncludingVAT, VATAmount, CommissionAmount, 
										|AmountVATRemuneration";
		
		InventoryKinds.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
		
		TypesOfStocksWereFilled = True;
		
		If ThereAreLinesOfStornoReport Then
			TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStornowReserves);
		EndIf;
		
	EndIf;
	
	TempTablesManager = TemporaryDocumentDataTables(True);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		ManagerOfTemporaryProductTables	= ?(ItemsRowData.ThereAreLinesOfWorksOnSideOfReport
												And ItemsRowData.ThereAreRowsOfItemsInReportReversingEntry
												And BusinessOperation <> Enums.BusinessTransactions.SalesViaCommissionAgent,
											TemporaryDocumentDataTables(True, "Products"),
											TempTablesManager);
		ManagerOfTemporaryWorkTables	= ?(ItemsRowData.ThereAreLinesOfWorksOnSideOfReport
												And ItemsRowData.ThereAreRowsOfItemsInReportReversingEntry
												And BusinessOperation <> Enums.BusinessTransactions.SalesViaCommissionAgent,
											TemporaryDocumentDataTables(True, "Work_5"),
											TempTablesManager);
		
		If ThereAreReportLines Then
			TypesOfReportInventory = InventoryKinds.UnloadColumns();
			
			For Each InventoryLine In InventoryKinds Do
				If InventoryLine.Count > 0 Then
					FillPropertyValues(TypesOfReportInventory.Add(), InventoryLine);
				EndIf;
			EndDo;
			
			InventoryKinds.Clear();
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
			FillParameters = ParametersForFillingInventoryTypes();
			FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = True;
			
			InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																	TempTablesManager,
																	Cancel,
																	FillParameters);
		Else
			If ItemsRowData.ThereAreRowsOfItemsInReportReversingEntry Then
				FillParameters = ParametersForFillingInventoryTypes();
				FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = True;
				
				InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																		ManagerOfTemporaryProductTables,
																		Cancel,
																		FillParameters);
			EndIf;
			
			If ItemsRowData.ThereAreLinesOfWorksOnSideOfReport Then
				TypesOfStocksOfGoods = TypesOfStocksOfGoods(True);
				InventoryKinds.Clear();
				
				FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
				FillParameters.SelectionOfStockTypes_.Organization = Organization;
				FillParameters.SelectionOfStockTypes_.InventoryType = New Array;
				FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
				FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = True;
				FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
				
				InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																		ManagerOfTemporaryWorkTables,
																		Cancel,
																		FillParameters);
				
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStocksOfGoods);
			EndIf;
		EndIf;
		
		NamesOfGroupingColumns		= "ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, VATRate, FEACNCode";
		NamesOfSummationColumns	= "Count, QuantityByGBRN, AmountIncludingVAT, VATAmount, CommissionAmount, 
										|AmountVATRemuneration";
										
		InventoryKinds.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
		
		TypesOfStocksWereFilled = True;
		
		If ThereAreReportLines Then
			TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfReportInventory);
		EndIf;
		
	EndIf;
	
	If TypesOfStocksWereFilled Then
		FillInAdditionalStockTypes();
	EndIf;
	
EndProcedure

Function ItemsRowData()
	
	ItemsRowData = New Structure;
	ItemsRowData.Insert("ThereAreReportLines",				False);
	ItemsRowData.Insert("ThereAreLinesOfStornoReport",		False);
	ItemsRowData.Insert("ThereAreRowsOfItemsInReport",		False);
	ItemsRowData.Insert("ThereAreRowsOfItemsInReportReversingEntry",	False);
	ItemsRowData.Insert("ThereAreLinesOfWorksInReport",			False);
	ItemsRowData.Insert("ThereAreLinesOfWorksOnSideOfReport",	False);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TSGoods.LineNumber	AS LineNumber,
	|	TSGoods.Products	AS Products,
	|	TSGoods.Count		AS Count
	|INTO TSGoods
	|FROM
	|	&TSGoods AS TSGoods
	|WHERE
	|	TSGoods.Count <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MAX(NestedQuery.ThereAreReportLines), FALSE)				AS ThereAreReportLines,
	|	ISNULL(MAX(NestedQuery.ThereAreLinesOfStornoReport), FALSE)		AS ThereAreLinesOfStornoReport,
	|	ISNULL(MAX(NestedQuery.ThereAreRowsOfItemsInReport), FALSE)		AS ThereAreRowsOfItemsInReport,
	|	ISNULL(MAX(NestedQuery.ThereAreRowsOfItemsInReportReversingEntry), FALSE)	AS ThereAreRowsOfItemsInReportReversingEntry,
	|	ISNULL(MAX(NestedQuery.ThereAreLinesOfWorksInReport), FALSE)			AS ThereAreLinesOfWorksInReport,
	|	ISNULL(MAX(NestedQuery.ThereAreLinesOfWorksOnSideOfReport), FALSE)	AS ThereAreLinesOfWorksOnSideOfReport
	|FROM
	|	(SELECT TOP 1
	|		TRUE	AS ThereAreReportLines,
	|		FALSE	AS ThereAreLinesOfStornoReport,
	|		FALSE	AS ThereAreRowsOfItemsInReport,
	|		FALSE	AS ThereAreRowsOfItemsInReportReversingEntry,
	|		FALSE	AS ThereAreLinesOfWorksInReport,
	|		FALSE	AS ThereAreLinesOfWorksOnSideOfReport
	|	FROM
	|		TSGoods AS TSGoods
	|	WHERE
	|		TSGoods.Count > 0
	|	
	|	UNION ALL
	|	
	|	SELECT TOP 1
	|		FALSE	AS ThereAreReportLines,
	|		TRUE	AS ThereAreLinesOfStornoReport,
	|		FALSE	AS ThereAreRowsOfItemsInReport,
	|		FALSE	AS ThereAreRowsOfItemsInReportReversingEntry,
	|		FALSE	AS ThereAreLinesOfWorksInReport,
	|		FALSE	AS ThereAreLinesOfWorksOnSideOfReport
	|	FROM
	|		TSGoods AS TSGoods
	|	WHERE
	|		TSGoods.Count < 0
	|	
	|	UNION ALL
	|	
	|	SELECT TOP 1
	|		FALSE	AS ThereAreReportLines,
	|		FALSE	AS ThereAreLinesOfStornoReport,
	|		TRUE	AS ThereAreRowsOfItemsInReport,
	|		FALSE	AS ThereAreRowsOfItemsInReportReversingEntry,
	|		FALSE	AS ThereAreLinesOfWorksInReport,
	|		FALSE	AS ThereAreLinesOfWorksOnSideOfReport
	|	FROM
	|		TSGoods AS TSGoods
	|			INNER JOIN Catalog.Products AS CatalogProducts
	|			ON TSGoods.Products = CatalogProducts.Ref
	|	WHERE
	|		TSGoods.Count > 0
	|		AND CatalogProducts.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|													VALUE(Enum.ItemsTypes.ReusablePackage))
	|	
	|	UNION ALL
	|	
	|	SELECT TOP 1
	|		FALSE	AS ThereAreReportLines,
	|		FALSE	AS ThereAreLinesOfStornoReport,
	|		FALSE	AS ThereAreRowsOfItemsInReport,
	|		TRUE	AS ThereAreRowsOfItemsInReportReversingEntry,
	|		FALSE	AS ThereAreLinesOfWorksInReport,
	|		FALSE	AS ThereAreLinesOfWorksOnSideOfReport
	|	FROM
	|		TSGoods AS TSGoods
	|			INNER JOIN Catalog.Products AS CatalogProducts
	|			ON TSGoods.Products = CatalogProducts.Ref
	|	WHERE
	|		TSGoods.Count < 0
	|		AND CatalogProducts.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|													VALUE(Enum.ItemsTypes.ReusablePackage))
	|	
	|	UNION ALL
	|	
	|	SELECT TOP 1
	|		FALSE	AS ThereAreReportLines,
	|		FALSE	AS ThereAreLinesOfStornoReport,
	|		FALSE	AS ThereAreRowsOfItemsInReport,
	|		FALSE	AS ThereAreRowsOfItemsInReportReversingEntry,
	|		TRUE	AS ThereAreLinesOfWorksInReport,
	|		FALSE	AS ThereAreLinesOfWorksOnSideOfReport
	|	FROM
	|		TSGoods AS TSGoods
	|			INNER JOIN Catalog.Products AS CatalogProducts
	|			ON TSGoods.Products = CatalogProducts.Ref
	|	WHERE
	|		TSGoods.Count > 0
	|		AND &UseTraceableImportedGoodsAccounting
	|		AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND CatalogProducts.TracedGoods
	|	
	|	UNION ALL
	|	
	|	SELECT TOP 1
	|		FALSE	AS ThereAreReportLines,
	|		FALSE	AS ThereAreLinesOfStornoReport,
	|		FALSE	AS ThereAreRowsOfItemsInReport,
	|		FALSE	AS ThereAreRowsOfItemsInReportReversingEntry,
	|		FALSE	AS ThereAreLinesOfWorksInReport,
	|		TRUE	AS ThereAreLinesOfWorksOnSideOfReport
	|	FROM
	|		TSGoods AS TSGoods
	|			INNER JOIN Catalog.Products AS CatalogProducts
	|			ON TSGoods.Products = CatalogProducts.Ref
	|	WHERE
	|		TSGoods.Count < 0
	|		AND &UseTraceableImportedGoodsAccounting
	|		AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND CatalogProducts.TracedGoods
	|	
	|	) AS NestedQuery";
	
	ColumnsNames = "LineNumber, Products, Count";
	
	Query.SetParameter("TSGoods", Goods.Unload(, ColumnsNames));
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	FillPropertyValues(ItemsRowData, Selection);
	
	Return ItemsRowData;
	
EndFunction

Function TypesOfStocksOfGoods(ReversingEntry)
	
	TypesOfStocksOfGoods = InventoryKinds.UnloadColumns();
	
	If InventoryKinds.Count() = 0 Then
		Return TypesOfStocksOfGoods;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Count					AS Count
	|INTO TableTypesOfStocks_
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber
	|FROM
	|	TableTypesOfStocks_ AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON Dimension.Products = ProductData_1.Ref
	|
	|WHERE
	|	ProductData_1.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|	AND (NOT &ReversingEntry
	|			AND TableTypesOfStocks_.Count > 0
	|		OR &ReversingEntry
	|			AND TableTypesOfStocks_.Count < 0)";
	
	ColumnsNames = "LineNumber, ItemsLocationAttributes, Count";
	
	Query.SetParameter("ReversingEntry", ReversingEntry);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds.Unload(, ColumnsNames));
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		NewRow = TypesOfStocksOfGoods.Add();
		FillPropertyValues(NewRow, InventoryKinds[Selection.LineNumber - 1]);
	EndDo;
	
	Return TypesOfStocksOfGoods;
	
EndFunction

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	If BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
		FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
		FillParameters.SelectionOfStockTypes_.Organization = Organization;
		FillParameters.SelectionOfStockTypes_.InventoryType = New Array;
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ConsignedGoods);
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
		FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	Else
		FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
		FillParameters.SelectTypesOfStocksForIntercampany = False;
		FillParameters.NameOfRemainderTable = "GoodsTransferredToCommissionAgent";
		FillParameters.WithoutSelectionByCCDNumbers = Not Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Terms)
														Or Not AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date);
	EndIf;
	
	Return FillParameters;
	
EndFunction

Procedure FillInAdditionalStockTypes() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.LineNumber						AS LineNumber,
	|	Goods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	CASE
	|		WHEN Goods.Count > 0
	|			THEN 1
	|		ELSE -1
	|	END									AS Character,
	|	Goods.Count						AS Count,
	|	Goods.VATRate						AS VATRate,
	|	Goods.SalesAmount						AS SalesAmount,
	|	Goods.AmountSalesVAT					AS AmountSalesVAT,
	|	Goods.CommissionAmount				AS CommissionAmount,
	|	Goods.AmountVATRemuneration			AS AmountVATRemuneration,
	|	Goods.Customer						AS Customer,
	|	Goods.DateOfTaxInvoiceIssuedByCommissionAgent		AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	Goods.CommissionAgentSTaxInvoiceNumber	AS CommissionAgentSTaxInvoiceNumber,
	|	Goods.Package							AS Package,
	|	Goods.NumberOfPackages				AS NumberOfPackages
	|INTO Goods
	|FROM
	|	&GoodsTable AS Goods
	|
	|WHERE
	|	Goods.Count <> 0
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	VATRate
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	Goods.Character								AS Character,
	|	SUM(Goods.Count)				AS Count,
	|	Goods.VATRate						AS VATRate,
	|	SUM(Goods.SalesAmount)				AS SalesAmount,
	|	SUM(Goods.AmountSalesVAT)			AS AmountSalesVAT,
	|	SUM(Goods.CommissionAmount)		AS CommissionAmount,
	|	SUM(Goods.AmountVATRemuneration)	AS AmountVATRemuneration,
	|	Goods.Package							AS Package,
	|	SUM(Goods.NumberOfPackages)		AS NumberOfPackages
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.ItemsLocationAttributes,
	|	Goods.Character,
	|	Goods.VATRate,
	|	Goods.Package
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	Goods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	Goods.Character								AS Character,
	|	SUM(Goods.Count)				AS Count,
	|	Goods.VATRate						AS VATRate,
	|	SUM(Goods.SalesAmount)				AS SalesAmount,
	|	SUM(Goods.AmountSalesVAT)			AS AmountSalesVAT,
	|	SUM(Goods.CommissionAmount)		AS CommissionAmount,
	|	SUM(Goods.AmountVATRemuneration)	AS AmountVATRemuneration,
	|	Goods.Customer						AS Customer,
	|	Goods.DateOfTaxInvoiceIssuedByCommissionAgent		AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	Goods.CommissionAgentSTaxInvoiceNumber	AS CommissionAgentSTaxInvoiceNumber,
	|	Goods.Package							AS Package,
	|	SUM(Goods.NumberOfPackages)		AS NumberOfPackages
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.ItemsLocationAttributes,
	|	Goods.Character,
	|	Goods.VATRate,
	|	Goods.Customer,
	|	Goods.DateOfTaxInvoiceIssuedByCommissionAgent,
	|	Goods.CommissionAgentSTaxInvoiceNumber,
	|	Goods.Package";
	
	Query.SetParameter("GoodsTable", Goods);
	
	QueryResul	= Query.ExecuteBatch();
	GoodsTable	= QueryResul[QueryResul.UBound() - 1].Unload();
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, VATRate");
	
	For Each RowOfGoods In GoodsTable Do
		
		GoodsQuantity = RowOfGoods.Count;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			If GoodsQuantity > 0
				And InventoryLine.Count > 0 Then
				
				Count = Min(GoodsQuantity, InventoryLine.Count);
				
			ElsIf GoodsQuantity < 0
				And InventoryLine.Count < 0 Then
				
				Count = Max(GoodsQuantity, InventoryLine.Count);
				
			Else
				Count = Min(GoodsQuantity, InventoryLine.Count);
			EndIf;
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.Count			= Count;
			NewRow.NumberOfPackages	= Count * RowOfGoods.NumberOfPackages / RowOfGoods.Count;
			NewRow.QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			NewRow.VATAmount				= Count * RowOfGoods.AmountSalesVAT / RowOfGoods.Count;
			NewRow.AmountIncludingVAT				= Count * RowOfGoods.SalesAmount / RowOfGoods.Count;
			NewRow.CommissionAmount		= Count * RowOfGoods.CommissionAmount / RowOfGoods.Count;
			NewRow.AmountVATRemuneration	= Count * RowOfGoods.AmountVATRemuneration / RowOfGoods.Count;
			
			InventoryLine.Count				= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN			= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.AmountIncludingVAT					= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount					= InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.CommissionAmount		= InventoryLine.CommissionAmount - NewRow.CommissionAmount;
			InventoryLine.AmountVATRemuneration	= InventoryLine.AmountVATRemuneration - NewRow.AmountVATRemuneration;
			
			If InventoryLine.NumberOfPackages <> 0 Then
				InventoryLine.NumberOfPackages = InventoryLine.NumberOfPackages - NewRow.NumberOfPackages;
			EndIf;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			
			If InventoryLine.AmountIncludingVAT <> 0
				And InventoryLine.Count = 0 Then
				
				NewRow.VATAmount				= InventoryLine.VATAmount + NewRow.VATAmount;
				NewRow.AmountIncludingVAT				= InventoryLine.AmountIncludingVAT + NewRow.AmountIncludingVAT;
				NewRow.CommissionAmount		= InventoryLine.CommissionAmount + NewRow.CommissionAmount;
				NewRow.AmountVATRemuneration	= InventoryLine.AmountVATRemuneration + NewRow.AmountVATRemuneration;
				
			EndIf;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
	GoodsTable = QueryResul[QueryResul.UBound()].Unload();
	NamesOfGroupingColumns = "ItemsLocationAttributes, VATRate, Customer, DateOfTaxInvoiceIssuedByCommissionAgent,
								|CommissionAgentSTaxInvoiceNumber, Package";
	
	ColumnNamesForDistribution		= "ItemsLocationAttributes, VATRate, VATAmount, AmountIncludingVAT, CommissionAmount,
										|AmountVATRemuneration, Count";
	MatchingAmountsToDistribution	= New Map;
	
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
			
			Character = Count > 0;
			
			CacheKey = KeyOfSumCacheToDistribution(InventoryLine, Character);
			AmountsToBeDistributed = MatchingAmountsToDistribution.Get(CacheKey);
			
			If AmountsToBeDistributed <> Undefined Then
				InventoryLine.VATAmount					= InventoryLine.VATAmount + AmountsToBeDistributed.VATAmount;
				InventoryLine.AmountIncludingVAT					= InventoryLine.AmountIncludingVAT + AmountsToBeDistributed.AmountIncludingVAT;
				InventoryLine.CommissionAmount		= InventoryLine.CommissionAmount + AmountsToBeDistributed.CommissionAmount;
				InventoryLine.AmountVATRemuneration	= InventoryLine.AmountVATRemuneration + AmountsToBeDistributed.AmountVATRemuneration;
				
				MatchingAmountsToDistribution.Delete(CacheKey);
			EndIf;
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			FillPropertyValues(NewRow, RowOfGoods, NamesOfGroupingColumns);
			
			NewRow.Count				= Count;
			NewRow.NumberOfPackages		= Count * RowOfGoods.NumberOfPackages / RowOfGoods.Count;
			NewRow.QuantityByGBRN		= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			NewRow.VATAmount				= Count * RowOfGoods.AmountSalesVAT / RowOfGoods.Count;
			NewRow.AmountIncludingVAT				= Count * RowOfGoods.SalesAmount / RowOfGoods.Count;
			NewRow.CommissionAmount		= Count * RowOfGoods.CommissionAmount / RowOfGoods.Count;
			NewRow.AmountVATRemuneration	= Count * RowOfGoods.AmountVATRemuneration / RowOfGoods.Count;
			
			InventoryLine.Count				= InventoryLine.Count - NewRow.Count;
			InventoryLine.NumberOfPackages		= InventoryLine.NumberOfPackages - NewRow.NumberOfPackages;
			InventoryLine.QuantityByGBRN			= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.VATAmount					= InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.AmountIncludingVAT					= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.CommissionAmount		= InventoryLine.CommissionAmount - NewRow.CommissionAmount;
			InventoryLine.AmountVATRemuneration	= InventoryLine.AmountVATRemuneration - NewRow.AmountVATRemuneration;
			
			If InventoryLine.AmountIncludingVAT <> 0
				And InventoryLine.Count = 0 Then
				
				CacheKey = KeyOfSumCacheToDistribution(InventoryLine, Character);
				AmountsToBeDistributed = MatchingAmountsToDistribution.Get(CacheKey);
				
				If AmountsToBeDistributed = Undefined Then
					AmountsToBeDistributed = New Structure(ColumnNamesForDistribution);
					FillPropertyValues(AmountsToBeDistributed, InventoryLine);
					
					AmountsToBeDistributed.Count = Count;
					
					MatchingAmountsToDistribution.Insert(CacheKey, AmountsToBeDistributed);
				Else
					AmountsToBeDistributed.VATAmount				= InventoryLine.VATAmount + AmountsToBeDistributed.VATAmount;
					AmountsToBeDistributed.AmountIncludingVAT				= InventoryLine.AmountIncludingVAT + AmountsToBeDistributed.AmountIncludingVAT;
					AmountsToBeDistributed.CommissionAmount		= InventoryLine.CommissionAmount + AmountsToBeDistributed.CommissionAmount;
					AmountsToBeDistributed.AmountVATRemuneration	= InventoryLine.AmountVATRemuneration + AmountsToBeDistributed.AmountVATRemuneration;
				EndIf;
				
			EndIf;
			
			NumberOfProductsPerLine_ = NumberOfProductsPerLine_ - NewRow.Count;
			
			If NumberOfProductsPerLine_ = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	LinesToDelete = InventoryKinds.FindRows(SearchParameters);
	
	For Each InventoryLine In LinesToDelete Do
		InventoryKinds.Delete(InventoryLine);
	EndDo;
	
	For Each KeyAndValue In MatchingAmountsToDistribution Do
		AmountsToBeDistributed = KeyAndValue.Value;
		
		FillPropertyValues(TheStructureOfTheSearch, AmountsToBeDistributed);
		
		FoundRows	= InventoryKinds.FindRows(TheStructureOfTheSearch);
		IndexOf			= FoundRows.UBound();
		
		While IndexOf >= 0 Do
			InventoryLine = FoundRows[IndexOf];
			
			If (InventoryLine.Count > 0
					And AmountsToBeDistributed.Count < 0)
				Or (InventoryLine.Count < 0
					And AmountsToBeDistributed.Count > 0) Then
				
				IndexOf = IndexOf - 1;
				
				Continue;
				
			EndIf;
			
			InventoryLine.VATAmount					= InventoryLine.VATAmount + AmountsToBeDistributed.VATAmount;
			InventoryLine.AmountIncludingVAT					= InventoryLine.AmountIncludingVAT + AmountsToBeDistributed.AmountIncludingVAT;
			InventoryLine.CommissionAmount		= InventoryLine.CommissionAmount + AmountsToBeDistributed.CommissionAmount;
			InventoryLine.AmountVATRemuneration	= InventoryLine.AmountVATRemuneration + AmountsToBeDistributed.AmountVATRemuneration;
			
			Break;
		EndDo;
	EndDo;
	
EndProcedure

Function KeyOfSumCacheToDistribution(CurrentRow, Character)
	
	CacheKey		= "";
	EmptyValue	= "EmptyValue";
	
	CacheKey = ?(ValueIsFilled(CurrentRow.ItemsLocationAttributes),
				String(CurrentRow.ItemsLocationAttributes.UUID()),
				EmptyValue);
	CacheKey = CacheKey + ?(ValueIsFilled(CurrentRow.VATRate),
							String(CurrentRow.VATRate.UUID()),
							EmptyValue);
	CacheKey = CacheKey + String(Character);
	
	Return CacheKey;
	
EndFunction

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, EndOfPeriod, Partner, Terms";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableOfGoods.CommissionAgentSTaxInvoiceNumber AS CommissionAgentSTaxInvoiceNumber,
	|	TableOfGoods.Customer AS Customer,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate AS VATRate,
	|		TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|		TableOfGoods.CommissionAgentSTaxInvoiceNumber AS CommissionAgentSTaxInvoiceNumber,
	|		TableOfGoods.Customer AS Customer,
	|		TableOfGoods.CCDNumber AS CCDNumber,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.CommissionAmount AS CommissionAmount,
	|		TableOfGoods.AmountVATRemuneration AS AmountVATRemuneration
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		TableTypesOfStocks_.DateOfTaxInvoiceIssuedByCommissionAgent AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|		TableTypesOfStocks_.CommissionAgentSTaxInvoiceNumber AS CommissionAgentSTaxInvoiceNumber,
	|		TableTypesOfStocks_.Customer AS Customer,
	|		TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
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
	|	TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableOfGoods.CommissionAgentSTaxInvoiceNumber,
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

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.ConsignmentReportFromCustomer.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.ConsignmentReportFromCustomer.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	
	If BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
		PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
						BusinessOperation,
						Undefined,
						Department,
						Partner,
						Contract);
	Else
		PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
						Enums.BusinessTransactions.ConsignmentReportFromCustomer,
						Undefined,
						Department,
						Partner);
		FieldsNames.BatchesIndicationStatus = "";
	EndIf;
	
	FieldsNames.Purpose = "";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
