#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, DocumentBasis, WhoStated";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency, PaymentMethodOfPaymentRequest";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CashAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "CompanyRecipient";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "CompanyRecipient";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BankAccountBeneficiary", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("PlanningCashControl");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("FinancialInstruments");
	DocumentMechanisms.Add("ControlOfBudgetingLimits");
	PaymentRequestLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.PaymentRequest") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
	Else
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableCashToBePaid(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCashFlowLimits(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCashFlow(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject);
		
		PaymentRequestLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.CashVoucher - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Contract = Object.Contract;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	FillParameters.Department = Object.Department;
	
	FillParameters.GoodsSales = True;
	FillParameters.ImplementationOfWorksServices = True;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.CashVoucher - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Contract = Object.Contract; 
	FillParameters.Period  = Object.Date;
	
	FillParameters.PurchaseOfGoods = True;
	FillParameters.AcquisitionOfWorks = True;
	FillParameters.PurchaseOnArticles = True;
	
	Return FillParameters;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	NewCommand = Documents.PaymentCardTransaction.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.Handler = "GenerationByReferenceTMClient.CreatePaymentCardOperation";
		NewCommand.VisibilityInForms = "DocumentForm, DocumentsListForm, ListForm, FormOfListOfRequestsForApproval";
		NewCommand.HasVisibilityConditions = True;
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.RefundToCustomer,
			DataCompositionComparisonType.Equal);
	EndIf;
	
	NewCommand = Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.Handler = "GenerationByReferenceTMClient.CreateSpendingCashOrder";
		NewCommand.VisibilityInForms =
			"DocumentForm, DocumentsListForm, ListForm, FormOfListOfRequestsForApproval, PaymentRequestsForFinancialInstruments";
		NewCommand.MultipleChoice = True;
		NewCommand.HasVisibilityConditions = True;
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"PaymentMethodCash",
			True,
			DataCompositionComparisonType.Equal);
	EndIf;
	
	NewCommand = Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.Handler = "GenerationByReferenceTMClient.CreateNonCashCashDebiting";
		NewCommand.VisibilityInForms =
			"DocumentForm, DocumentsListForm, ListForm, FormOfListOfRequestsForApproval, PaymentRequestsForFinancialInstruments";
		NewCommand.MultipleChoice = True;
		NewCommand.HasVisibilityConditions = True;
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"PaymentMethodBankAccount",
			True,
			DataCompositionComparisonType.Equal);
	EndIf;
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	PaymentRequestLocalization.AddGenerationCommands(GenerationCommands, Parameters)
	
EndProcedure

// Adds the command to create the document "request for expenditure of DS".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Order - Number - The order of the command.
//
// Returns:
//  ValueTableRow:
//   * Manager - String
//   * Presentation - String
//   * WriteMode - String
//   * FunctionalOptions - String
//   * Order - Number
//  Undefined.
Function AddGenerateCommand(GenerationCommands, Order = 0) Export
	
	If AccessRight("Insert", Metadata.Documents.PaymentRequest) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PaymentRequest.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PaymentRequest);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePaymentRequests";
		CreateBasedOnCommand.Order = Order;
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds the command to create the document "request for expenditure of DS".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands.
//
// Returns:
//  Undefined
//
Function AddCreateBasedOnCommissionReportCommand_Remuneration(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.BankAccountIssue) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler =
			"GenerationByReferenceTMClient.ApplicationForCashExpenditureBasedOnCommissionReport_Remuneration";
		CreateBasedOnCommand.Id = "ApplicationForCashExpenditureBasedOnCommissionReport_Remuneration";
		CreateBasedOnCommand.Presentation =
			TMCommonUse.ObjectPresentation(Metadata.Documents.PaymentRequest)
			+ " " + NStr("vi = 'người đặt ký gửi (thù lao cho đại lý hoa hồng)';
						|ru = 'комитента (вознаграждение комиссионеру)';
						|en = 'consignor (remuneration to consignee)'; fa = 'consignor (remuneration to consignee)';
						|it = 'del committente (compenso dell''agente commissionario)';
						|pl = 'komitenta (wynagrodzenie komisanta)';
						|tr = 'temsilci (komisyon temsilcisinin ücreti)'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePaymentRequests";
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.CashFlowLimits.AddReportCommand(ReportsCommands);
	Reports.LimitsByBudgetingData.AddReportCommand(ReportsCommands);
	Reports.FulfillmentOfPaymentRequests.AddReportCommand(ReportsCommands);
	NewCommand = Reports.ControlOfAdvancesPaidToAdvanceHolderUnderRequest.AddReportCommand(ReportsCommands);
	If NewCommand <>  Undefined Then
		NewCommand.HasVisibilityConditions = True;
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.IssueCashToAdvanceHolder,
			DataCompositionComparisonType.Equal);
	EndIf;
	
	PaymentRequestLocalization.AddReportCommands(ReportsCommands, Parameters)
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Read", Metadata.Documents.BankAccountIssue) Then
		// Bank details
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "Document.BankAccountIssue";
		PrintCommand.Id = "PaymentDetails";
		PrintCommand.Presentation = NStr("vi = 'Chi tiết thanh toán quốc tế';
										|ru = 'Реквизиты международного платежа';
										|en = 'Bank details'; fa = 'جزئیات بانکی';
										|it = 'Requisiti del pagamento internazionale';
										|pl = 'Atrybuty płatności międzynarodowej';
										|tr = 'Uluslararası ödeme bilgileri'");
	EndIf;
	
	PaymentRequestLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Fills in the table of details that depend on the business operation of the document.
//
// Parameters:
//	Object - DocumentObject - Application object
//	ArrayOfAllProps - Array of String - Array of all banking details that depend on the business operation
//	ArrayOfOperationDetails - Array of String - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(Object, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	BusinessOperation = Object.BusinessOperation;
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("CounterpartyBankAccount");
	ArrayOfAllProps.Add("BankAccountBeneficiary");
	ArrayOfAllProps.Add("CurrencyOfConversion");
	ArrayOfAllProps.Add("ExpenseReportDate");
	ArrayOfAllProps.Add("CashAccountRecipient");
	ArrayOfAllProps.Add("Counterparty");
	ArrayOfAllProps.Add("ConversionRate");
	ArrayOfAllProps.Add("ConversionRateMultiplier");
	ArrayOfAllProps.Add("CompanyRecipient");
	ArrayOfAllProps.Add("AmountPlanning");
	ArrayOfAllProps.Add("AdvanceHolder");
	ArrayOfAllProps.Add("AssetAndLiabilityItem");
	ArrayOfAllProps.Add("AssetsLiabilitiesDimension");
	ArrayOfAllProps.Add("CashFlowItem");
	ArrayOfAllProps.Add("ConversionAmount");
	ArrayOfAllProps.Add("PayrollTransaction");
	ArrayOfAllProps.Add("BankAccountForFeeWriteOff");
	ArrayOfAllProps.Add("AcquiringContract");
	ArrayOfAllProps.Add("TaxType");
	ArrayOfAllProps.Add("PaymentWithConversion");
	
	ArrayOfAllProps.Add("FinancialAccountingGroup");
	ArrayOfAllProps.Add("LineOfBusiness");
	ArrayOfAllProps.Add("Contract");
	
	ArrayOfAllProps.Add("ARAPDetails");
	ArrayOfAllProps.Add("ARAPDetails.DimensionOfExpenses");
	ArrayOfAllProps.Add("ARAPDetails.AssetsLiabilitiesDimension");
	ArrayOfAllProps.Add("ARAPDetails.ARAPCurrency");
	ArrayOfAllProps.Add("ARAPDetails.LoanDepositContract");
	ArrayOfAllProps.Add("ARAPDetails.LeaseContracts");
	ArrayOfAllProps.Add("ARAPDetails.EmployeeLoanAgreement");
	ArrayOfAllProps.Add("ARAPDetails.ARAPObject");
	ArrayOfAllProps.Add("ARAPDetails.Comment");
	ArrayOfAllProps.Add("ARAPDetails.LineOfBusiness");
	ArrayOfAllProps.Add("ARAPDetails.Partner");
	ArrayOfAllProps.Add("ARAPDetails.CashFlowItem");
	ArrayOfAllProps.Add("ARAPDetails.ExpenseItem");
	ArrayOfAllProps.Add("ARAPDetails.AmountARAP");
	ArrayOfAllProps.Add("ARAPDetails.VATRate");
	ArrayOfAllProps.Add("ARAPDetails.VATAmount");
	ArrayOfAllProps.Add("ARAPDetails.TypeOfLeasePayment");
	ArrayOfAllProps.Add("ARAPDetails.LoanAndDepositAmountType");
	ArrayOfAllProps.Add("ARAPDetails.Department");
	ArrayOfAllProps.Add("ARAPDetails.Organization");
	ArrayOfAllProps.Add("ARAPDetails.MaturityDate");
	ArrayOfAllProps.Add("ARAPDetails.Counterparty");
	
	ArrayOfAllProps.Add("PersonalAccountsOfStaff");
	ArrayOfAllProps.Add("PersonalAccountsOfStaff.Individual");
	ArrayOfAllProps.Add("PersonalAccountsOfStaff.PersonalAccount");
	ArrayOfAllProps.Add("PersonalAccountsOfStaff.CashFlowItem");
	
	ArrayOfOperationDetails = New Array;
	If BusinessOperation = Enums.BusinessTransactions.PaymentToVendor Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AmountPlanning");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.MaturityDate");
	
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AmountPlanning");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");

		If TypeOf(Object.DocumentBasis) = Type("DocumentRef.PaymentCardTransaction") Then
			ArrayOfOperationDetails.Add("AcquiringContract");
		EndIf;
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("ExpenseReportDate");
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AmountPlanning");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
		ArrayOfOperationDetails.Add("PersonalAccountsOfStaff");
		ArrayOfOperationDetails.Add("PersonalAccountsOfStaff.Individual");
		ArrayOfOperationDetails.Add("PersonalAccountsOfStaff.PersonalAccount");
		ArrayOfOperationDetails.Add("PersonalAccountsOfStaff.CashFlowItem");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AmountPlanning");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Department");
		ArrayOfOperationDetails.Add("ARAPDetails.LineOfBusiness");
		ArrayOfOperationDetails.Add("ARAPDetails.ExpenseItem");
		ArrayOfOperationDetails.Add("ARAPDetails.DimensionOfExpenses");
		ArrayOfOperationDetails.Add("ARAPDetails.AssetsLiabilitiesDimension");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CustomsPayment Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AmountPlanning");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.MaturityDate");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AmountPlanning");
		ArrayOfOperationDetails.Add("TaxType");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
		ArrayOfOperationDetails.Add("BankAccountBeneficiary");
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		ArrayOfOperationDetails.Add("CompanyRecipient");
		ArrayOfOperationDetails.Add("AmountPlanning");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.MaturityDate");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		ArrayOfOperationDetails.Add("BankAccountBeneficiary");
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		ArrayOfOperationDetails.Add("CompanyRecipient");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		ArrayOfOperationDetails.Add("CompanyRecipient");
		ArrayOfOperationDetails.Add("BankAccountBeneficiary");
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		ArrayOfOperationDetails.Add("CashFlowItem");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("CurrencyOfConversion");
		ArrayOfOperationDetails.Add("ConversionRate");
		ArrayOfOperationDetails.Add("ConversionRateMultiplier");
		ArrayOfOperationDetails.Add("ConversionAmount");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("BankAccountBeneficiary");
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		ArrayOfOperationDetails.Add("BankAccountForFeeWriteOff");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.SalaryPayment Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("PayrollTransaction");
		
		ArrayOfOperationDetails.Add("PersonalAccountsOfStaff");
		ArrayOfOperationDetails.Add("PersonalAccountsOfStaff.Individual");
		ArrayOfOperationDetails.Add("PersonalAccountsOfStaff.PersonalAccount");
		
		If Not Constants.UsePayroll.Get() Then
			ArrayOfOperationDetails.Add("CashFlowItem");
		EndIf;
		
		If Constants.UsePayroll.Get()
			//++ WE 
			Or GetFunctionalOption("PayrollAndHumanResourcesWE")
			//-- WE 
			Or False Then
			ArrayOfOperationDetails.Add("ARAPDetails");
			ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
			ArrayOfOperationDetails.Add("ARAPDetails.Comment");
			//++ WE
			ArrayOfOperationDetails.Add("ARAPDetails.Statement");
			//-- WE
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AmountPlanning");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
		ArrayOfOperationDetails.Add("ARAPDetails.LoanDepositContract");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.LoanAndDepositAmountType");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToDeposits Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AmountPlanning");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
		ArrayOfOperationDetails.Add("ARAPDetails.LoanDepositContract");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AmountPlanning");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
		ArrayOfOperationDetails.Add("ARAPDetails.LoanDepositContract");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee Then
		
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		
		If GetFunctionalOption("UsePayrollTM") Then
			ArrayOfOperationDetails.Add("ARAPDetails");
			ArrayOfOperationDetails.Add("ARAPDetails.EmployeeLoanAgreement");
			ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
			ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		Else
			ArrayOfOperationDetails.Add("CashFlowItem");
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AcquiringContract");
		ArrayOfOperationDetails.Add("ExpensesBusinessUnit");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("RecordCommission");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("CashFlowItem");
	ElsIf BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
		
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AmountPlanning");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
		ArrayOfOperationDetails.Add("ARAPDetails.LeaseContracts");
		ArrayOfOperationDetails.Add("ARAPDetails.TypeOfLeasePayment");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
	EndIf;
	
EndProcedure

// Complements the passed structure with the values of the details of the available payment form, depending on the business transaction.
//
// Parameters:
//    FillingData - Structure - A structure containing a household. operation.
//
Procedure FillInPaymentFormForBusinessTransaction(FillingData) Export
	
	If TypeOf(FillingData) <> Type("Structure") Then
		Return;
	EndIf;
	
	BusinessOperation = Undefined; PayrollTransaction = Undefined;
	FillingData.Property("BusinessOperation", BusinessOperation);
	FillingData.Property("PayrollTransaction", PayrollTransaction);
	
	If BusinessOperation = Enums.BusinessTransactions.SalaryPayment Then
		PaymentMethod = LimitingFormOfPayment(PayrollTransaction);
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		PaymentMethod = Enums.PaymentForms.BankAccountPayment;
	Else
		PaymentMethod = LimitingFormOfPayment(BusinessOperation);
	EndIf;
	
	If PaymentMethod <> Undefined Then
		FillingData.Insert("PaymentMethodCash",         (PaymentMethod = Enums.PaymentForms.CashAccountPayment_));
		FillingData.Insert("PaymentMethodBankAccount",
			(PaymentMethod = Enums.PaymentForms.BankAccountPayment
			Or PaymentMethod = Enums.PaymentForms.InstantPayments));
		FillingData.Insert("MethodOfPaymentPaymentCard",   (PaymentMethod = Enums.PaymentForms.PaymentCard));
		FillingData.Insert("PaymentMethodOfPaymentRequest",           PaymentMethod);
	Else // Default
		AttributesOfApplication = Metadata.Documents.PaymentRequest.Attributes;
		If Not FillingData.Property("PaymentMethodCash") Then
			FillingData.Insert("PaymentMethodCash",         AttributesOfApplication.PaymentMethodCash.FillValue);
		EndIf;
		If Not FillingData.Property("PaymentMethodBankAccount") Then
			FillingData.Insert("PaymentMethodBankAccount",      AttributesOfApplication.PaymentMethodBankAccount.FillValue);
		EndIf;
		If Not FillingData.Property("MethodOfPaymentPaymentCard") Then
			FillingData.Insert("MethodOfPaymentPaymentCard",   AttributesOfApplication.MethodOfPaymentPaymentCard.FillValue);
		EndIf;
		If Not FillingData.Property("PaymentMethodOfPaymentRequest") Then
			FillingData.Insert("PaymentMethodOfPaymentRequest",           AttributesOfApplication.PaymentMethodOfPaymentRequest.FillValue);
		EndIf;
	EndIf;
	
EndProcedure

// This function determines the payment form available for a business transaction
//
// Parameters:
//    Operation - EnumRef.BusinessTransactions - Household. the operation to check for.
//
// Returns:
//    EnumRef.PaymentForms, Undefined - Restriction on the form of payment, or Undefined if there are no restrictions.
//
Function LimitingFormOfPayment(Operation) Export
	
	Restrictions = New Map;
	Restrictions.Insert(Enums.BusinessTransactions.TransferOfTaxesAndContributions,                    Enums.PaymentForms.BankAccountPayment);
	Restrictions.Insert(Enums.BusinessTransactions.TransferToDeposits,                 Enums.PaymentForms.BankAccountPayment);
	Restrictions.Insert(Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram,    Enums.PaymentForms.BankAccountPayment);
	Restrictions.Insert(Enums.BusinessTransactions.SalaryPaymentToBankAccounts,          Enums.PaymentForms.BankAccountPayment);
	Restrictions.Insert(Enums.BusinessTransactions.RefundAcquiringPayment,          Enums.PaymentForms.BankAccountPayment);
	Restrictions.Insert(Enums.BusinessTransactions.SalaryPaymentViaCashAccount,              Enums.PaymentForms.CashAccountPayment_);
	Restrictions.Insert(Enums.BusinessTransactions.SalaryPaymentByDistributor,             Enums.PaymentForms.CashAccountPayment_);
	
	Return Restrictions.Get(Operation);
	
EndFunction

// Defines the properties of form fields depending on the data
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array of String - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
//
Procedure FillInFormFieldSettings(Settings) Export
	
	Finances = FinancialReportingServer;
	Operations = Enums.BusinessTransactions;
	
	NonCashPaymentIsNotAllowed = CashServer.SelectionNonCashPaymentOfApplication();
	
	SelectionWhenTransferringToEmployeeViaBank = New DataCompositionFilter();
	
	AndGroup = Finances.NewFilter(SelectionWhenTransferringToEmployeeViaBank, , , Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "TransferToEmployeeViaABank", True);
	
	UnderGroupOr = Finances.NewFilter(AndGroup, , , Type("DataCompositionFilterItemGroup"));
	UnderGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	
	UnderGroupAnd = Finances.NewFilter(UnderGroupOr, , , Type("DataCompositionFilterItemGroup"));
	UnderGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(UnderGroupAnd, "BusinessOperation", Operations.SalaryPayment);
	Finances.NewFilter(UnderGroupAnd, "PayrollTransaction", Operations.SalaryPaymentToBankAccounts);
	
	FilterPaymentToSelfEmployed = CashServer.FilterPaymentToSelfEmployed();
	FilterListOfCounterparties_ = CashServer.FilterListOfCounterparties_(FilterPaymentToSelfEmployed);
	
	FilterProhibitingStatusChanges = New DataCompositionFilter();
	FilterAmountDue = Finances.NewFilter(FilterProhibitingStatusChanges, , , Type("DataCompositionFilterItemGroup"));
	FilterAmountDue.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(FilterAmountDue, "Status", Enums.StatusesOfPaymentRequests.AmountDue);
	Finances.NewFilter(FilterAmountDue, "More.ConfirmationRight", False);
	
	#Region Header
	// Status
	Item = Settings.Add();
	Item.Fields.Add("Status");
	Finances.CopyFilter(FilterProhibitingStatusChanges, Item.Condition);
	Item.Properties.Insert("ReadOnly");
	
	// TaxType
	Item = Settings.Add();
	Item.Fields.Add("TaxType");
	Item.Fields.Add("FillInWithThePreviousPayment");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.TransferOfTaxesAndContributions);
	Item.Properties.Insert("Visible");
	
	// PayrollTransaction
	Item = Settings.Add();
	Item.Fields.Add("PayrollTransaction");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.SalaryPayment);
	Item.Properties.Insert("Visible");
	
	// PaymentMethod
	Item = Settings.Add();
	Item.Fields.Add("PaymentMethod");
	Finances.NewFilter(Item.Condition, "More.PaymentMethodIsLimited", False);
	Item.Properties.Insert("Visible");
	
	// Bank account
	Item = Settings.Add();
	Item.Fields.Add("BankAccount");
	OrGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.BankAccountPayment);
	Finances.NewFilter(OrGroup, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.InstantPayments);
	Item.Properties.Insert("Visible");
	
	// CashAccount
	Item = Settings.Add();
	Item.Fields.Add("CashAccount");
	Finances.NewFilter(Item.Condition, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.CashAccountPayment_);
	Item.Properties.Insert("Visible");
	
	// Counterparty
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	GroupOrAnd = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	GroupOrAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	Finances.NewFilter(GroupOrAnd, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(GroupOrAnd, "OperationWithSelfEmployedPerson", False);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferOfTaxesAndContributions);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundAcquiringPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.SalaryPayment);
	Finances.NewFilter(AndGroup, "PayrollTransaction", Operations.SalaryPaymentByPayrollCardProgram);
	
	UnderGroupAnd = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	UnderGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.CopyFilter(NonCashPaymentIsNotAllowed, UnderGroupAnd);
	
	UnderGroupOr = Finances.NewFilter(UnderGroupAnd, , , Type("DataCompositionFilterItemGroup"));
	UnderGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.CopyFilter(SelectionWhenTransferringToEmployeeViaBank, UnderGroupOr);
	Finances.CopyFilter(FilterListOfCounterparties_, UnderGroupOr);
	
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Item.Fields.Add("AcquiringContract");
	Item.Fields.Add("ARAPDetails.Counterparty");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.NotAgreedUpon);
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.IsRejected);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Item.Properties.Insert("AutoMarkIncomplete", True);
	Finances.CopyFilter(NonCashPaymentIsNotAllowed, Item.Condition);
	Finances.CopyFilter(SelectionWhenTransferringToEmployeeViaBank, Item.Condition);
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Item.Properties.Insert("Title", NStr("vi = 'Người nhận';
										|ru = 'Получатель';
										|en = 'Payee'; fa = 'ذی‌نفع';
										|it = 'Destinatario';
										|pl = 'Payee';
										|tr = 'Alıcı'"));
	NotGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	OrGroup = Finances.NewFilter(NotGroup, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundAcquiringPayment);
	Finances.CopyFilter(SelectionWhenTransferringToEmployeeViaBank, OrGroup);
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.RefundAcquiringPayment);
	Item.Properties.Insert("Title", NStr("vi = 'Thiết bị thanh toán thẻ';
										|ru = 'Эквайер';
										|en = 'Acquirer'; fa = 'پذیرنده';
										|it = 'Acquirer';
										|pl = 'Acquirer';
										|tr = 'Alıcı banka'"));
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Item.Properties.Insert("Title", NStr("vi = 'Ngân hàng người nhận';
										|ru = 'Банк-получатель';
										|en = 'Receiving bank'; fa = 'Receiving bank';
										|it = 'Banca-destinatario';
										|pl = 'Receiving bank';
										|tr = 'Alıcı banka'"));
	Finances.CopyFilter(NonCashPaymentIsNotAllowed, Item.Condition);
	OrGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.CopyFilter(SelectionWhenTransferringToEmployeeViaBank, OrGroup);
	Finances.CopyFilter(FilterListOfCounterparties_, OrGroup);
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Nhà môi giới';
										|ru = 'Брокер';
										|en = 'Broker'; fa = 'کارگزار';
										|it = 'Брокер';
										|pl = 'Broker';
										|tr = 'Komisyoncu'"));
	//++ WE
	// Recipient
	Item = Settings.Add();
	Item.Fields.Add("Recipient");
	NotGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.NewFilter(NotGroup, "BusinessOperation", Operations.SalaryPayment);
	Item.Properties.Insert("Visible");
	//-- WE
	
	// Contract For Connection To The Payment System
	Item = Settings.Add();
	Item.Fields.Add("AcquiringContract");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.RefundAcquiringPayment);
	Item.Properties.Insert("Visible");
	
	// CounterpartyBankAccount
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	
	Finances.CopyFilter(NonCashPaymentIsNotAllowed, Item.Condition);
	
	OrGroup1 = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.TransferOfTaxesAndContributions);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.RefundAcquiringPayment);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.PaymentToLessor);
	AndGroup = Finances.NewFilter(OrGroup1,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.SalaryPayment);
	Finances.NewFilter(AndGroup, "PayrollTransaction", Operations.SalaryPaymentByPayrollCardProgram);
	
	AndGroup2 = Finances.NewFilter(OrGroup1,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(AndGroup2, "PersonsList", False);
	
	Finances.CopyFilter(SelectionWhenTransferringToEmployeeViaBank, OrGroup1);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup1);
	
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(Item.Condition, "TransferToEmployeeViaABank", False);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản cá nhân';
										|ru = 'Лицевой счет';
										|en = 'Personal account'; fa = 'حساب شخصی';
										|it = 'Conto individuale';
										|pl = 'Konto osobiste';
										|tr = 'Kişisel hesap'"));
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(Item.Condition, "TransferToEmployeeViaABank", True);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản người nhận';
										|ru = 'Счет получателя';
										|en = 'Payee account'; fa = 'حساب ذی‌نفع';
										|it = 'Conto del destinatario';
										|pl = 'Rachunek odbiorcy';
										|tr = 'Alıcı hesabı'"));
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	NotGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.NewFilter(NotGroup, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản người nhận';
										|ru = 'Счет получателя';
										|en = 'Payee account'; fa = 'حساب ذی‌نفع';
										|it = 'Conto del destinatario';
										|pl = 'Rachunek odbiorcy';
										|tr = 'Alıcı hesabı'"));
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản của nhà môi giới';
										|ru = 'Счет брокера';
										|en = 'Broker account'; fa = 'Broker account';
										|it = 'Счет брокера';
										|pl = 'Broker account';
										|tr = 'Komisyoncunun hesabı'"));
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(Item.Condition, "PersonsList", True);
	Finances.NewFilter(Item.Condition, "TransferToEmployeeViaABank", False);
	Item.Properties.Insert("Enabled", False);
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.NotAgreedUpon);
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.IsRejected);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	Item.Properties.Insert("AutoMarkIncomplete", True);
	
	Finances.CopyFilter(SelectionWhenTransferringToEmployeeViaBank, Item.Condition);
	
	// Accountable person
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Employee");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	Finances.NewFilter(Item.Condition, "PersonsList", True);
	Item.Properties.Insert("Enabled", False);
	
	// List of individuals
	Item = Settings.Add();
	Item.Fields.Add("ListOfIndividualsIncluded");
	Item.Fields.Add("ListOfIndividualsDisabled");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Item.Properties.Insert("Visible");
	
	// CompanyRecipient
	Item = Settings.Add();
	Item.Fields.Add("CompanyRecipient");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Item.Properties.Insert("Visible");
	
	// BankAccountBeneficiary
	Item = Settings.Add();
	Item.Fields.Add("BankAccountBeneficiary");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	ConditionOfFormOfPayment = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	ConditionOfFormOfPayment.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(ConditionOfFormOfPayment, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.BankAccountPayment);
	Finances.NewFilter(ConditionOfFormOfPayment, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.InstantPayments);
	Finances.NewFilter(ConditionOfFormOfPayment, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.EmptyRef());
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("BankAccountBeneficiary");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản kiểm kê';
										|ru = 'Счет конвертации';
										|en = 'Conversion account'; fa = 'Conversion account';
										|it = 'Conto della conversione';
										|pl = 'Rachunek konwersji';
										|tr = 'Dönüşüm hesabı'"));
	
	Item = Settings.Add();
	Item.Fields.Add("BankAccountBeneficiary");
	NotGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.NewFilter(NotGroup, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản người nhận';
										|ru = 'Счет получателя';
										|en = 'Payee account'; fa = 'حساب ذی‌نفع';
										|it = 'Conto del destinatario';
										|pl = 'Rachunek odbiorcy';
										|tr = 'Alıcı hesabı'"));
	
	// CashAccountRecipient
	Item = Settings.Add();
	Item.Fields.Add("CashAccountRecipient");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(Item.Condition, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.CashAccountPayment_);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("CashAccountRecipient");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Quầy thu ngân chuyển đổi';
										|ru = 'Касса конвертации';
										|en = 'Conversion cash account'; fa = 'Conversion cash account';
										|it = 'Cassa della conversione';
										|pl = 'Kasa konwersji';
										|tr = 'Dönüşüm kasası'"));
	
	Item = Settings.Add();
	Item.Fields.Add("CashAccountRecipient");
	NotGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.NewFilter(NotGroup, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Quỹ tiền mặt của người nhận';
										|ru = 'Касса получателя';
										|en = 'Receiving cash account'; fa = 'صندوق دریافت‌کننده';
										|it = 'Cassa del destinatario';
										|pl = 'Kasa odbiorcy';
										|tr = 'Alıcı Kasası'"));
	
	// DDS article
	Item = Settings.Add();
	Item.Fields.Add("CashFlowItem");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundAcquiringPayment);
	
	AndGroup1 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "BusinessOperation", Operations.SalaryPayment);
	Finances.NewFilter(AndGroup1, "More.UsePayrollTM", False);
	//++ WE
	Finances.NewFilter(AndGroup1, "More.PayrollAndHumanResourcesWE", False);
	//-- WE
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(AndGroup2, "More.UsePayrollTM", False);
	//++ WE
	Finances.NewFilter(AndGroup2, "More.PayrollAndHumanResourcesWE", False);
	//-- WE 
	
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("CashFlowItem");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.NotAgreedUpon);
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.IsRejected);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
	// AmountPlanning
	Item = Settings.Add();
	Item.Fields.Add("AmountPlanning");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferOfTaxesAndContributions);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(AndGroup, "PersonsList", False);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	Item.Properties.Insert("Visible");
	
	// Type of transfer to the accountable person
	Item = Settings.Add();
	Item.Fields.Add("TransferToEmployeeViaABank");
	Item.Properties.Insert("Visible", True);
	
	OrGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	
	AndGroup = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.SalaryPayment);
	Finances.NewFilter(AndGroup, "PayrollTransaction", Operations.SalaryPaymentToBankAccounts);
	//++ WE
	Finances.NewFilter(AndGroup, "More.PayrollAndHumanResourcesWE", False);
	//-- WE
	
	Finances.CopyFilter(NonCashPaymentIsNotAllowed, Item.Condition);
	
	// The UIP is different
	Item = Settings.Add();
	Item.Fields.Add("SceneryOfUIPIsDifferent");
	Item.Fields.Add("UIPInscriptionIsDifferent");
	Item.Fields.Add("UIPDecorationDiffersInList");
	Item.Fields.Add("UIPInscriptionIsDistinguishedByList");
	Item.Fields.Add("DecorationOfUIPIsDifferentWithoutSplitting");
	Item.Fields.Add("DecryptionOfPaymentDecorationOfUIPIsDifferent");
	Finances.NewFilter(Item.Condition, "More.UIPIsDifferent", True);
	Finances.NewFilter(Item.Condition, "More.CurrencyPayment", False);
	Finances.NewFilter(Item.Condition, "TransferOfTaxesAndContributions", False);
	Item.Properties.Insert("Visible");
	#EndRegion
	
	#Region Attributes
	// Who decided
	Item = Settings.Add();
	Item.Fields.Add("WhoDecided");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.AgreedUpon);
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.AmountDue);
	Item.Properties.Insert("Visible");
	
	// View only
	Item = Settings.Add();
	Item.Fields.Add("Number");
	Item.Fields.Add("Date");
	Item.Fields.Add("AmountPlanning");
	Item.Fields.Add("DocumentAmount");
	Item.Fields.Add("Currency");
	Item.Fields.Add("PaymentMethod");
	Item.Fields.Add("Organization");
	Item.Fields.Add("Department");
	Item.Fields.Add("Applicant");
	Item.Fields.Add("BusinessOperation");
	Item.Fields.Add("TaxType");
	Item.Fields.Add("PersonalAccountsOfStaff");
	Item.Fields.Add("PayrollTransaction");
	Item.Fields.Add("RequiredPaymentDate");
	Item.Fields.Add("Counterparty");
	Item.Fields.Add("AcquiringContract");
	Item.Fields.Add("CompanyRecipient");
	Item.Fields.Add("AdvanceHolder");
	Item.Fields.Add("BankAccountBeneficiary");
	Item.Fields.Add("CashAccountRecipient");
	Item.Fields.Add("CashFlowItem");
	Item.Fields.Add("ARAPDetails");
	Item.Fields.Add("ExplanationWithoutSplit");
	Item.Fields.Add("PaymentPurposes");
	Item.Fields.Add("CurrencyOfConversion");
	Item.Fields.Add("ConversionRate");
	Item.Fields.Add("ConversionAmount");
	Item.Fields.Add("ConversionRateMultiplier");
	Item.Fields.Add("OverLimits");
	Item.Fields.Add("BankAccount");
	Item.Fields.Add("CashAccount");
	Item.Fields.Add("ExpenseReportPeriod");
	Item.Fields.Add("ListOfIndividualsIncluded");
	Item.Fields.Add("ListOfIndividualsDisabled");
	Item.Fields.Add("TransferFeeType");
	Item.Fields.Add("CodesOfInstructionsForBank");
	Item.Fields.Add("InformationForRegulatoryBodies");
	Item.Fields.Add("InformationToPaymentRecipient");
	Item.Fields.Add("FeeAmount");
	Item.Fields.Add("Department");
	Item.Fields.Add("LineOfBusiness");
	Item.Fields.Add("ExpenseItem");
	Item.Fields.Add("DimensionOfExpenses");
	Item.Fields.Add("TransferToEmployeeViaABank");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.AgreedUpon);
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.AmountDue);
	Finances.NewFilter(OrGroup, "Closed_", True);
	Finances.NewFilter(Item.Condition, "Posted", True);
	Finances.NewFilter(Item.Condition, "More.Modified", False);
	Item.Properties.Insert("ReadOnly");
	//++ WE
	Item = Settings.Add();
	Item.Fields.Add("DocumentAmount");
	AndGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.SalaryPayment);
	Finances.NewFilter(AndGroup, "More.PayrollAndHumanResourcesWE", True);
	Item.Properties.Insert("ReadOnly");
	//-- WE
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	Item.Properties.Insert("ReadOnly", True);
	
	OrGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	UnderGroupAnd1 = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	UnderGroupAnd1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	UnderGroupOr1 = Finances.NewFilter(UnderGroupAnd1, , , Type("DataCompositionFilterItemGroup"));
	UnderGroupOr1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(UnderGroupOr1, "Status", Enums.StatusesOfPaymentRequests.AgreedUpon);
	Finances.NewFilter(UnderGroupOr1, "Status", Enums.StatusesOfPaymentRequests.AmountDue);
	Finances.NewFilter(UnderGroupAnd1, "Posted", True);
	Finances.NewFilter(UnderGroupAnd1, "More.Modified", False);
	
	CounterpartyGroupIsNotFilledIn = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	CounterpartyGroupIsNotFilledIn.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(CounterpartyGroupIsNotFilledIn, "Counterparty", , , DataCompositionComparisonType.NotFilled);
	
	SubgroupOfAdditionalConditions = Finances.NewFilter(CounterpartyGroupIsNotFilledIn, , , Type("DataCompositionFilterItemGroup"));
	SubgroupOfAdditionalConditions.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.CopyFilter(SelectionWhenTransferringToEmployeeViaBank, SubgroupOfAdditionalConditions);
	Finances.CopyFilter(FilterListOfCounterparties_, SubgroupOfAdditionalConditions);
	
	SubgroupOtherOperations = Finances.NewFilter(SubgroupOfAdditionalConditions, , , Type("DataCompositionFilterItemGroup"));
	SubgroupOtherOperations.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
	OFOperationsWithIndividuals = New Array;
	OFOperationsWithIndividuals.Add(Operations.IssueCashToAdvanceHolder);
	OFOperationsWithIndividuals.Add(Operations.CashIssueAsLoanToEmployee);
	
	Finances.NewFilter(SubgroupOtherOperations, "BusinessOperation", OFOperationsWithIndividuals, , DataCompositionComparisonType.InList);
	
	GroupIndividualNotFilledIn = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	GroupIndividualNotFilledIn.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(GroupIndividualNotFilledIn, "AdvanceHolder", , , DataCompositionComparisonType.NotFilled);
	
	Finances.NewFilter(GroupIndividualNotFilledIn, "TransferToEmployeeViaABank", False);
	
	PhysicalPersonSubgroupIsNotFilledIn = Finances.NewFilter(GroupIndividualNotFilledIn, , , Type("DataCompositionFilterItemGroup"));
	PhysicalPersonSubgroupIsNotFilledIn.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(PhysicalPersonSubgroupIsNotFilledIn, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(PhysicalPersonSubgroupIsNotFilledIn, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	
	Item = Settings.Add();
	Item.Fields.Add("Status");
	Item.Fields.Add("Priority");
	Item.Fields.Add("AccountAllocationPage");
	Finances.NewFilter(Item.Condition, "Closed_", True);
	Item.Properties.Insert("ReadOnly");
	
	// AllocationByAccounts
	Item = Settings.Add();
	Item.Fields.Add("AllocationByAccounts");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	AndGroup1 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	OrGroup1 = Finances.NewFilter(AndGroup1,,, Type("DataCompositionFilterItemGroup"));
	OrGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup1, "Status", Enums.StatusesOfPaymentRequests.AgreedUpon);
	Finances.NewFilter(OrGroup1, "Status", Enums.StatusesOfPaymentRequests.AmountDue);
	Finances.NewFilter(AndGroup1, "Posted", True);
	Finances.NewFilter(AndGroup1, "More.ConfirmationRight", False);
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "More.ApprovalRight", False);
	Finances.NewFilter(AndGroup2, "More.ConfirmationRight", False);
	Item.Properties.Insert("ReadOnly");
	
	// Personal account
	Item = Settings.Add();
	Item.Fields.Add("PersonalAccountsOfStaff");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	AndGroup1 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "BusinessOperation", Operations.SalaryPayment);
	Finances.NewFilter(AndGroup1, "PayrollTransaction", Operations.SalaryPaymentToBankAccounts);
	Finances.NewFilter(AndGroup1, "More.UsePayrollTM", False);
	//++ WE
	Finances.NewFilter(AndGroup1, "More.PayrollAndHumanResourcesWE", False);
	//-- WE
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(AndGroup2, "PersonsList", True);
	
	Item.Properties.Insert("Visible");
	
	// To close the application
	Item = Settings.Add();
	Item.Fields.Add("CloseRequest");
	Finances.NewFilter(Item.Condition, "More.BalanceOfPayment", 0,, DataCompositionComparisonType.NotEqual);
	Finances.NewFilter(Item.Condition, "Posted", True);
	Finances.NewFilter(Item.Condition, "Closed_", False);
	Finances.NewFilter(Item.Condition, "Status", Enums.StatusesOfPaymentRequests.IsRejected,, DataCompositionComparisonType.NotEqual);
	
	ExclusionGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	ExclusionGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.CopyFilter(FilterProhibitingStatusChanges, ExclusionGroup);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Closed_");
	Finances.NewFilter(Item.Condition, "Closed_", True);
	Item.Properties.Insert("Visible");
	
	// LabelActualPayment
	Item = Settings.Add();
	Item.Fields.Add("LabelActualPayment");
	Finances.NewFilter(Item.Condition, "Status", Enums.StatusesOfPaymentRequests.AmountDue);
	Item.Properties.Insert("Visible");
	
	// Conversion
	Item = Settings.Add();
	Item.Fields.Add("CurrencyOfConversion");
	Item.Fields.Add("ConversionRate");
	Item.Fields.Add("ConversionAmount");
	Item.Fields.Add("ConversionRateMultiplier");
	Item.Fields.Add("CurrencyOfConversionRate");
	Item.Fields.Add("CurrencyOfConversionRateMultiplicity");
	Item.Fields.Add("BankAccountForFeeWriteOff");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Visible");
	
	// The period of the financial report, the date of the financial report
	Item = Settings.Add();
	Item.Fields.Add("ExpenseReportPeriod");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("ExpenseReportDate");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(Item.Condition, "More.ExpenseReportPeriodDate", False);
	Item.Properties.Insert("Visible");
	
	// Currency payment
	Item = Settings.Add();
	Item.Fields.Add("TransferFeeType");
	Item.Fields.Add("CodesOfInstructionsForBank");
	Item.Fields.Add("InformationToPaymentRecipient");
	Finances.NewFilter(Item.Condition, "More.CurrencyPayment", True);
	Finances.NewFilter(Item.Condition, "More.UseCurrencyPayments", True);
	Finances.CopyFilter(NonCashPaymentIsNotAllowed, Item.Condition);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("InformationForRegulatoryBodies");
	Finances.NewFilter(Item.Condition, "More.CurrencyPayment", True);
	Finances.NewFilter(Item.Condition, "More.UseCurrencyPayments", True);
	Finances.NewFilter(Item.Condition, "More.InformationForRegulatoryBodiesIsRequired", True);
	Finances.CopyFilter(NonCashPaymentIsNotAllowed, Item.Condition);
	Item.Properties.Insert("Visible");
	
	// Over the limit
	Item = Settings.Add();
	Item.Fields.Add("OverLimits");
	Finances.NewFilter(Item.Condition, "OverLimits", True);
	Item.Properties.Insert("TitleTextColor", StyleColors.SpecialTextColor);
	
	Item = Settings.Add();
	Item.Fields.Add("OverLimits");
	Finances.NewFilter(Item.Condition, "OverLimits", False);
	Item.Properties.Insert("TitleTextColor", StyleColors.FormTextColor);
	
	// DocumentBasis
	Item = Settings.Add();
	Item.Fields.Add("DocumentBasis");
	Finances.NewFilter(Item.Condition, "DocumentBasis",,, DataCompositionComparisonType.Filled);
	Item.Properties.Insert("Visible");
	
	// Fee
	Item = Settings.Add();
	Item.Fields.Add("GroupCommission");
	Finances.NewFilter(Item.Condition, "RecordCommission", True);
	Item.Properties.Insert("Visible");
	#EndRegion
	
	#Region ARAPDetails
	// TheDecryptionPage
	Item = Settings.Add();
	Item.Fields.Add("TheDecryptionPage");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferOfTaxesAndContributions);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.UsePayrollTM", True);
	
	OrGroup2 = Finances.NewFilter(AndGroup,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.SalaryPayment);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	//++ WE
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.PayrollAndHumanResourcesWE", True);
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.SalaryPayment);
	//-- WE
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(AndGroup2, "PersonsList", False);
	
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("TheDecryptionPage");
	Item.Properties.Insert("Title", NStr("vi = 'Diễn giải thanh toán';
										|ru = 'Расшифровка платежа';
										|en = 'Payment details'; fa = 'جزئیات پرداخت';
										|it = 'Dettagli del pagamento';
										|pl = 'Szczegóły płatności';
										|tr = 'Ödeme bilgileri'"));
	
	Item = Settings.Add();
	Item.Fields.Add("TheDecryptionPage");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.SalaryPayment);
	Item.Properties.Insert("Title", NStr("vi = 'Bảng kê';
										|ru = 'Ведомости';
										|en = 'Statements'; fa = 'Statements';
										|it = 'Ведомости';
										|pl = 'Statements';
										|tr = 'Beyanları'"));
	//++ WE
	// Decryption Switch
	Item = Settings.Add();
	Item.Fields.Add("DecryptionSwitch");
	NotGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	AndGroup = Finances.NewFilter(NotGroup, , , Type("DataCompositionFilterItemGroup"));
	Finances.NewFilter(AndGroup, "More.PayrollAndHumanResourcesWE", True);
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.SalaryPayment);
	Item.Properties.Insert("Visible");
	
	// Statement
	Item = Settings.Add();
	Item.Fields.Add("DecryptionWithoutSplittingTheStatement");
	AndGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.SalaryPayment);
	Finances.NewFilter(AndGroup, "More.PayrollAndHumanResourcesWE", True);
	Item.Properties.Insert("Visible");
	//-- WE
	
	// SummaNDS, StavkaNDS
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.VATAmount");
	Item.Fields.Add("DecryptionWithoutSplittingTheVATAmount");
	Item.Fields.Add("ARAPDetails.VATRate");
	Item.Fields.Add("DecodingWithoutSplittingTheVATRate");
	Item.Fields.Add("VATCurrency");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	NotGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.CopyFilter(FilterPaymentToSelfEmployed, NotGroup);
	Item.Properties.Insert("Visible");
	
	// Analytics of other output
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.Department");
	Item.Fields.Add("DecryptionWithoutDivisionDivision");
	Item.Fields.Add("ARAPDetails.LineOfBusiness");
	Item.Fields.Add("DecodingWithoutSplittingTheDirectionOfActivity");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.OtherCashIssue);
	Item.Properties.Insert("Visible");
	
	// CashFlowItem
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.CashFlowItem");
	Item.Fields.Add("DecodingWithoutSplittingTheCashFlowItem");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferOfTaxesAndContributions);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.UsePayrollTM", True);
	OrGroup2 = Finances.NewFilter(AndGroup,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.SalaryPayment);
	//++ WE
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.PayrollAndHumanResourcesWE", True);
	OrGroup2 = Finances.NewFilter(AndGroup,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.SalaryPayment);
	//-- WE
	
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.CashFlowItem");
	Item.Fields.Add("DecodingWithoutSplittingTheCashFlowItem");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.NotAgreedUpon);
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.IsRejected);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
	// The sum of the settlements, the currency of the settlements
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.AmountARAP");
	Item.Fields.Add("DecryptionWithoutSplittingTheAmountOfMutualSettlements");
	Item.Fields.Add("ARAPDetails.ARAPCurrency");
	Item.Fields.Add("DecryptionWithoutSplittingTheCurrencyOfMutualSettlements");
	
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", True);
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferOfTaxesAndContributions);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	Item.Properties.Insert("Visible");
	
	// AmountARAP
	Item = Settings.Add();
	Item.Fields.Add("DecryptionWithoutSplittingTheAmountOfMutualSettlements");
	
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", True);
	Finances.NewFilter(Item.Condition, "More.ARAPCurrency", "Currency", , , True);
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferOfTaxesAndContributions);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	Item.Properties.Insert("ReadOnly");
	
	// Decorations of the currency of the course of payment, the exchange rate of the account, the exchange rate of the sign of the account
	Item = Settings.Add();
	Item.Fields.Add("CurrencyDecorationAndPaymentRate");
	Item.Fields.Add("ARAPDetails.ExchangeRateNumeratorOfMutualSettlements");
	Item.Fields.Add("DecodingWithoutSplittingTheCourseNumeratorOfMutualSettlements");
	Item.Fields.Add("ARAPDetails.CourseNumeratorOfMutualSettlementsText");
	Item.Fields.Add("DecodingOfThePaymentTheExchangeRateTheDenominatorOfMutualSettlementsTheInscription");
	Item.Fields.Add("ARAPDetails.ContractRateOption");
	Item.Fields.Add("DecodingWithoutSplittingIsVariantOfContractCourse");
	
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", True);
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferOfTaxesAndContributions);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	
	Finances.NewFilter(Item.Condition, "Currency", "More.ARAPCurrency",, DataCompositionComparisonType.NotEqual, True);
	UnderGroupOr = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	UnderGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(UnderGroupOr, "More.MultipleARAPCurrency", True);
	Finances.NewFilter(UnderGroupOr,
						"More.ARAPCurrency",
						Catalogs.Currencies.EmptyRef(), ,
						DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Visible");
	
	// CurrencyDecorationAndPaymentRate
	Item = Settings.Add();
	Item.Fields.Add("CurrencyDecorationAndPaymentRate");
	AndGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.ARAPCurrency",,, DataCompositionComparisonType.Filled);
	Finances.NewFilter(AndGroup, "More.ContractRateOption",,, DataCompositionComparisonType.Filled);
	Finances.NewFilter(AndGroup, "More.ExchangeRateNumeratorOfMutualSettlements", 0,, DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Enabled");
	
	// DecodingWithoutSplittingIsVariantOfContractCourse
	Item = Settings.Add();
	Item.Fields.Add("DecodingWithoutSplittingIsVariantOfContractCourse");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "More.ContractRateOption", Enums.ContractRateOptions.SpecifiedInContract,, DataCompositionComparisonType.Equal);
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.ContractRateOption", Enums.ContractRateOptions.FixedAsOfShipmentDate,, DataCompositionComparisonType.Equal);
	Finances.NewFilter(AndGroup, "More.ARAPObjectType", Enums.ARAPObjectTypes.Invoice,, DataCompositionComparisonType.Equal);
	Item.Properties.Insert("Hyperlink");
	
	// ARAPObject
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.ARAPObject");
	Item.Fields.Add("DecryptionWithoutSplittingTheCalculationObject");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	Item.Properties.Insert("Visible");
	
	// Partner
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.Partner");
	Item.Fields.Add("DecryptionWithoutPartitioningPartner");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.Partner");
	Item.Fields.Add("DecryptionWithoutPartitioningPartner");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.NotAgreedUpon);
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.IsRejected);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
	// LoanDepositContract
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.LoanDepositContract");
	Item.Fields.Add("DecryptionWithoutSplittingTheLoanDepositAgreement");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Item.Properties.Insert("Visible");
	
	// LoanAndDepositAmountType
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.LoanAndDepositAmountType");
	Item.Fields.Add("DecryptionWithoutSplittingTheTypeOfLoanAmountDeposit");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Item.Properties.Insert("Visible");
	
	// EmployeeLoanAgreement
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.EmployeeLoanAgreement");
	Item.Fields.Add("TranscriptWithoutSplittingTheLoanAgreementToTheEmployee");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(Item.Condition, "More.UsePayrollTM", True);
	Item.Properties.Insert("Visible");
	
	// LeaseContracts
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.LeaseContracts");
	Item.Fields.Add("DecryptionWithoutSplittingTheLeaseAgreement");
	Item.Fields.Add("ARAPDetails.TypeOfLeasePayment");
	Item.Fields.Add("DecryptionWithoutSplittingTheTypeOfRentPayment");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.PaymentToLessor);
	Item.Properties.Insert("Visible");
	
	// Organization
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.Organization");
	Item.Fields.Add("DecryptionWithoutSplittingTheOrganization");
	Finances.NewFilter(Item.Condition, "More.ThereAreBranches", True);
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	Item.Properties.Insert("Visible");
	
	// HyperlinkPaymentObjectDetails
	Item = Settings.Add();
	Item.Fields.Add("HyperlinkPaymentObjectDetails");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	Item.Properties.Insert("Visible");
	
	// Unallocated payment
	Item = Settings.Add();
	Item.Fields.Add("FinancialAccountingGroup");
	Item.Fields.Add("LineOfBusiness");
	AndGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.RefundToAnotherCompany,, DataCompositionComparisonType.NotEqual);
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.RefundToCustomer,, DataCompositionComparisonType.NotEqual);
	Finances.NewFilter(AndGroup, "More.AmountUnallocated", 0,, DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("FinancialAccountingGroupOfRefund");
	Item.Fields.Add("DirectionOfReturnActivity");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Item.Properties.Insert("Visible");
	
	// Contract
	Item = Settings.Add();
	Item.Fields.Add("Contract");
	
	Finances.NewFilter(Item.Condition, "ListOfCounterparties_", False);
	
	AndGroup1 = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	OrGroup = Finances.NewFilter(AndGroup1,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(AndGroup2, "More.UseContractsWithVendors", True);
	
	AndGroup3 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup3, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(AndGroup3, "More.UseIntercompanyContracts", True);
	
	AndGroup4 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup4.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup4, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(AndGroup4, "More.UseContractsWithVendors", True);
	
	AndGroup5 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup5.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.CopyFilter(FilterPaymentToSelfEmployed, AndGroup5);
	Finances.NewFilter(AndGroup5, "More.UseContractsWithVendors", True);
	
	Item.Properties.Insert("Visible");
	
	// Return Agreement
	Item = Settings.Add();
	Item.Fields.Add("ReturnAgreement");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	AndGroup1 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(AndGroup1, "More.UseIntercompanyContracts", True);
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(AndGroup2, "More.UseCustomerContracts", True);
	
	Item.Properties.Insert("Visible");
	
	// Settlement object agreement
	Item = Settings.Add();
	Item.Fields.Add("DecryptionWithoutSplittingTheObjectOfCalculationsContract");
	
	BasicConditions = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	BasicConditions.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Finances.NewFilter(BasicConditions, "ListOfCounterparties_", True);
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	AndGroup1 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "More.UseContractsWithVendors", True);
	OrGroup1 = Finances.NewFilter(AndGroup1,,, Type("DataCompositionFilterItemGroup"));
	OrGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.CustomsPayment);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup1);
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "More.UseIntercompanyContracts", True);
	OrGroup2 = Finances.NewFilter(AndGroup2,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.RefundToAnotherCompany);
	
	AndGroup3 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup3, "More.UseCustomerContracts", True);
	OrGroup3 = Finances.NewFilter(AndGroup3,,, Type("DataCompositionFilterItemGroup"));
	OrGroup3.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup3, "BusinessOperation", Operations.RefundToCustomer);
	
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetailsContract");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	AndGroup1 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "More.UseContractsWithVendors", True);
	OrGroup1 = Finances.NewFilter(AndGroup1,,, Type("DataCompositionFilterItemGroup"));
	OrGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Operations.CustomsPayment);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup1);
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "More.UseIntercompanyContracts", True);
	OrGroup2 = Finances.NewFilter(AndGroup2,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.RefundToAnotherCompany);
	
	AndGroup3 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup3, "More.UseCustomerContracts", True);
	OrGroup3 = Finances.NewFilter(AndGroup3,,, Type("DataCompositionFilterItemGroup"));
	OrGroup3.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup3, "BusinessOperation", Operations.RefundToCustomer);
	
	Item.Properties.Insert("Visible");
	
	// Maturity Date
	Item = Settings.Add();
	Item.Fields.Add("DecryptionWithoutSplittingRepaymentDate");
	Item.Fields.Add("ARAPDetailsMaturityDate");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	
	Item.Properties.Insert("Visible");
	
	// Course Accuracy
	CashServer.FillInConditionalAppearanceAccuracyOfCourse(Settings);
	
	#EndRegion
	
	#Region Commands
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetailsSelectionByStock");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("FillInTheRemainingAmountsOfNonIssuedAmountsToTheCounterparty");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetailsSelectionByStock");
	Item.Fields.Add("FillInTheRemainingAmountsOfNonIssuedAmountsToTheCounterparty");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.AgreedUpon);
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.AmountDue);
	Finances.NewFilter(OrGroup, "Closed_", True);
	Finances.NewFilter(Item.Condition, "Posted", True);
	Item.Properties.Insert("Enabled", False);
	
	Item = Settings.Add();
	Item.Fields.Add("PopulatePurposeOfPayment");
	Item.Fields.Add("PersonalAccountsOfStaffFillInCashFlowItem");
	Item.Fields.Add("TransferToEmployeeViaABank");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.AgreedUpon);
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.AmountDue);
	Finances.NewFilter(Item.Condition, "Posted", True);
	Finances.NewFilter(Item.Condition, "More.Modified", False);
	Item.Properties.Insert("Enabled", False);
	#EndRegion
	
	#Region PersonalAccountsOfStaff

	Item = Settings.Add();
	Item.Fields.Add("PersonalAccountsOfStaffPersonalAccount");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(Item.Condition, "PaymentMethodOfPaymentRequest", Enums.PaymentForms.CashAccountPayment_);
	Item.Properties.Insert("Visible", False);
	
	Item = Settings.Add();
	Item.Fields.Add("PersonalAccountsOfStaffCashFlowItem");
	OrGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.NotAgreedUpon);
	Finances.NewFilter(OrGroup, "Status", Enums.StatusesOfPaymentRequests.IsRejected);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
	Item = Settings.Add();
	Item.Fields.Add("PersonalAccountsOfStaffCashFlowItem");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Item.Properties.Insert("Visible");
	#EndRegion

EndProcedure

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	TaxType - CatalogRef.TaxContributionKinds - The tax type of the document.
// 	
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_(BusinessOperation, TaxType) Export
	
	ParametersArray = New Array();
	
	#Region ExpenseItem
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.ARAPDetails";
	SetupParameters.AvailabilityByOperation =
		BusinessOperation = Enums.BusinessTransactions.OtherCashIssue
		Or (BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
			And LocalAccntingServer.TypesOfTaxesWithAccountSettings().Find(TaxType) <> Undefined);
	SetupParameters.ArticleType = "ArticleType";
	
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	
	SetupParameters.Organization = "Object.Organization";
	
	SetupParameters.FormItems.Add("DecodingWithoutSplittingRepresentationOfReflectionInReglAccounting");
	SetupParameters.FormItems.Add("ARAPDetailsPresentationOfRecordingInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	#Region AssetAndLiabilityItem
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.AvailabilityByOperation =
		BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
		And LocalAccntingServer.TypesOfTaxesWithAccountSettings().Find(TaxType) = Undefined;
	
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	SetupParameters.AssetAndLiabilityItem = "";
	SetupParameters.Organization = "Object.Organization";
	
	SetupParameters.FormItems.Add("PresentationOfRecordingInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction
// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	AdditionalAvailability - Boolean - Additional indication that the selection of articles and Analytics is available.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation, AdditionalAvailability = True) Export
	
	ChoiceParametersArray = New Array;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.ARAPDetails";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	If BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions Then
		ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.AssetLiabilityItems.EmptyRef();
	EndIf;
	ChoiceParameters.FormItems.AssetRef.Add("DecodingWithoutSplittingTheCostItem");
	ChoiceParameters.FormItems.AssetRef.Add("ARAPDetailsExpenseItem");	
	ChoiceParameters.AvailabilityByOperation = BusinessOperation = Enums.BusinessTransactions.OtherCashIssue;
	
	#Region AssetsLiabilitiesDimension
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DecodingWithoutSplittingTheAssetLiabilityAnalysis");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ARAPDetailsAssetsLiabilitiesDimension");
	#EndRegion
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = BusinessOperation <> Enums.BusinessTransactions.TransferOfTaxesAndContributions;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DecodingWithoutSplittingTheExpenseAnalyst");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ARAPDetailsDimensionOfExpenses");
	#EndRegion
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ChoiceParameters.AvailabilityByOperation =
		(BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment) And AdditionalAvailability;
	
	ChoiceParametersArray.Add(ChoiceParameters);
	
	Return ChoiceParametersArray;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"BusinessOperation, ListOfCounterparties_, OperationWithSelfEmployedPerson");
		BusinessOperation = StructureFillingData.BusinessOperation;
		ListOfCounterparties_ = StructureFillingData.ListOfCounterparties_;
		OperationWithSelfEmployedPerson = StructureFillingData.OperationWithSelfEmployedPerson;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
		ListOfCounterparties_ = False;
		OperationWithSelfEmployedPerson = False;
	Else
		BusinessOperation = FillingData.BusinessOperation;
		ListOfCounterparties_ = FillingData.ListOfCounterparties_;
		OperationWithSelfEmployedPerson = FillingData.OperationWithSelfEmployedPerson;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	If BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ElsIf BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.CustomsPayment Then
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	EndIf;
	
	ParametersStructure.ChangesPaymentPlan = BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.CustomsPayment;
	
	ParametersStructure.ModifiesDeliveryShipmentPlan = False;
	
	If BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
		ParametersStructure.Counterparty                             = "Object.CompanyRecipient";
	ElsIf (BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		And OperationWithSelfEmployedPerson)
		And ListOfCounterparties_ Then
		ParametersStructure.Counterparty                             = "";
	Else
		ParametersStructure.Counterparty                             = "Object.Counterparty";
	EndIf;
	
	ParametersStructure.ARAPCurrency             = "Object.ARAPDetails.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Form.AmountARAP";
	ParametersStructure.CourseNumerator                    = "Form.ExchangeRateNumeratorOfMutualSettlements";
	ParametersStructure.CourseDenominator                  = "Form.TheExchangeRateIsTheDenominatorOfMutualSettlements";
	ParametersStructure.ARAPObjectSettings                  = "";
	
	ParametersStructure.PaymentMethod                      = "Object.PaymentMethodOfPaymentRequest";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	ParametersStructure.Partner                          = "Object.ARAPDetails.Partner";
	
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
	ParametersStructure.Terms                       = "";
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount"; 
	ParametersStructure.VATTaxation               = "Object.VATTaxation";
	
	ParametersStructure.FormItems.ARAPDetails       = "ARAPDetails";
	ParametersStructure.FormItems.AddToPaymentDecryption  = "ARAPDetailsSelectionByStock";
	ParametersStructure.PaymentsAsPer275FZ                           = "Object.PaymentsAsPer275FZ";
	
	ParametersStructure.OperationWithSelfEmployedPerson = "Object.OperationWithSelfEmployedPerson";
	
	ParametersStructure.PaymentPurposes = "Object.PaymentPurposes";
	
	ParametersStructure.MutualSettlementsCurrencyViewOnly = True;
	ParametersStructure.DocumentCurrencyViewOnly      = True;
	
	Return ParametersStructure;
EndFunction

// Performs the closing of applications
// 
// Parameters:
//    Requests - Array of DocumentRef.PaymentRequest, DocumentRef.ApplicationForBusinessTrip - Applications to be closed
//    Interactively - Boolean - The sign of closing the application during the document
//
// Returns:
//    Number - Number of closed applications
//
Function CloseApplications(Val Requests, Interactively = False) Export
	
	PerformanceMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.PaymentRequest.ManagerModule.CloseApplications");
	
	ProcessedItemsCount = 0;
	
	If TypeOf(Requests) <> Type("Array") Then
		Request = Requests;
		Requests = New Array;
		Requests.Add(Request);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Period", CurrentSessionDate());
	Query.SetParameter("Request", Requests);
	
	ObjectsToRecalculateScheduleSettlementsWithSuppliers = New Array;
	ObjectsToRecalculateScheduleSettlementsWithClients    = New Array;
	QueryTextForRecalculationOfPaymentSchedule =
	"SELECT
	|	ARAPObjects.Ref AS ARAPObject,
	|	ARAPObjects.Object AS PaymentObject
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE
	|	ARAPObjects.Ref IN(&ObjectsToRecalculateScheduleSettlementsWithSuppliers)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ARAPObjects.Ref AS ARAPObject,
	|	ARAPObjects.Object AS PaymentObject
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE
	|	ARAPObjects.Ref IN(&ObjectsToRecalculateScheduleSettlementsWithClients)";
	
	QueryTexts = New ValueList;
	QueryTexts.Add(ClosingRequestCashForPayment(),              "CashToBePaid");
	QueryTexts.Add(RequestForClosingSettlementsWithSuppliers(),                  "VendorsARAPAccounting");
	QueryTexts.Add(RequestForClosingSettlementsWithCustomers(),                     "CustomersARAPAccounting");
	QueryTexts.Add(RequestToCloseSettlementsOnFinancialInstruments(),       "FinancialInstrumentsARAP");
	QueryTexts.Add(CashFlowClosureRequest(),               "CashFlow");
	QueryTexts.Add(RequestClosureCashFlowIncomeExpenses(), "RecordsCashIncomeExpenses");
	QueryTexts.Add(RequestToCloseCashFlowCounterparty(),    "RecordsCashCounterparty");
	
	If GetFunctionalOption("UseCashFlowLimits") Then
		QueryTexts.Add(RequestForClosingCashFlowLimits(),      "CashFlowLimits");
		Query.SetParameter("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
		Query.SetParameter("UseExpenseLimitsForOrganizations",
			GetFunctionalOption("UseCashFlowLimitsByCompanies"));
		Query.SetParameter("UseExpenseLimitsByDivision",
			GetFunctionalOption("UseCashFlowLimitsByBusinessUnit"));
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		
		If Not Interactively Then
			
			LockTable = New ValueTable;
			LockTable.Columns.Add("Recorder");
			For Each Request In Requests Do
				LockTable.Add();
			EndDo;
			LockTable.LoadColumn(Requests, "Recorder");
			
			Block = New DataLock;
			
			For Each QueryText In QueryTexts Do
				LockItem = Block.Add("AccumulationRegister." + QueryText.Presentation + ".RecordSet");
				LockItem.Mode = DataLockMode.Exclusive;
				LockItem.DataSource = LockTable;
				LockItem.UseFromDataSource("Recorder", "Recorder");
			EndDo;
			
			Block.Lock();
		EndIf;
		
		Results = DocumentsPosting.UploadQueryPostResults(Query, QueryTexts);
		
		RecordSearchStructure = New Structure("PaymentRequest");
		
		For Each Request In Requests Do
			
			If Not Interactively Then
				
				RequestObject = Request.GetObject();
				
				Try
					RequestObject.Lock();
				Except
					MessageText = StrTemplate(
						NStr("vi = '%1 đang được soạn bởi người sử dụng hoặc hệ thống và không thể thay đổi.';
							|ru = '%1 находится в процессе редактирования пользователем или системой и не может быть изменена.';
							|en = '%1 is being edited by a user or the application and cannot be changed.'; fa = '%1 is being edited by a user or the application and cannot be changed.';
							|it = '%1 si trova in fase di modifica e non può essere modificato.';
							|pl = '%1 jest w trakcie edycji przez użytkownika lub przez system i nie może być zmieniona.';
							|tr = '%1 kullanıcı veya sistem tarafından düzenlenme sürecindedir ve değiştirilemez.'"),
						RequestObject);
					Common.MessageToUser(MessageText);
					Continue;
				EndTry;
				
				RequestObject.Closed_ = True;
				RequestObject.Write();
			EndIf;
			
			For Each SetRecords In Results Do
			
				RecordSearchStructure.PaymentRequest = Request;
				SetStrings = SetRecords.Value.FindRows(RecordSearchStructure);
				If SetStrings.Count() Then
					
					RecordSet = AccumulationRegisters[SetRecords.Key].CreateRecordSet();
					RecordSet.Filter.Recorder.Set(Request);
					DataToWriteToSet = SetRecords.Value.Copy(SetStrings);
					RecordSet.Load(DataToWriteToSet);
					RecordSet.Write(False);
					
					If SetRecords.Key = "VendorsARAPAccounting" Then
						CommonClientServer.SupplementArray(ObjectsToRecalculateScheduleSettlementsWithSuppliers,
							DataToWriteToSet.UnloadColumn("ARAPObject"), True);
					ElsIf SetRecords.Key = "CustomersARAPAccounting" Then
						CommonClientServer.SupplementArray(ObjectsToRecalculateScheduleSettlementsWithClients,
							DataToWriteToSet.UnloadColumn("ARAPObject"), True);
					EndIf;
					
				EndIf;
			EndDo;
			
			ProcessedItemsCount = ProcessedItemsCount + 1;
		EndDo;
		
		// Recalculation of the schedule. Kleenets and suppliers.
		//
		Query.Text = QueryTextForRecalculationOfPaymentSchedule;
		Query.SetParameter("ObjectsToRecalculateScheduleSettlementsWithSuppliers", ObjectsToRecalculateScheduleSettlementsWithSuppliers);
		Query.SetParameter("ObjectsToRecalculateScheduleSettlementsWithClients", ObjectsToRecalculateScheduleSettlementsWithClients);
		
		DataForRecalculationOfPaymentSchedule      = Query.ExecuteBatch();
		ResultIsARAPObjectWithSuppliers = DataForRecalculationOfPaymentSchedule[0];
		ResultIsARAPObjectWithCustomers    = DataForRecalculationOfPaymentSchedule[1];
		
		If Not ResultIsARAPObjectWithSuppliers.IsEmpty() Then
			InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForSettlementsWithSuppliers(ResultIsARAPObjectWithSuppliers.Unload());
		EndIf;
		
		If Not ResultIsARAPObjectWithCustomers.IsEmpty() Then
			InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForSettlementsWithCustomers(ResultIsARAPObjectWithCustomers.Unload());
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		MessageText = NStr("vi = 'Không thể đóng giấy đề nghị theo nguyên nhân: %1';
							|ru = 'Не удалось закрыть заявки по причине: %1';
							|en = 'Cannot close the requests. Reason: %1'; fa = 'Cannot close the requests. Reason: %1';
							|it = 'Impossibile chiudere la richiesta a causa di: %1';
							|pl = 'Nie udało się zamknąć zlecenia z powodu: %1';
							|tr = 'Şu sebepten dolayı talepler kapatılamadı: %1'");
		MessageText = StrTemplate(MessageText, ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Common.MessageToUser(MessageText);
		
		ErrorText = NStr("vi = 'Không thể đóng giấy đề nghị.';
						|ru = 'Не удалось закрыть заявки.';
						|en = 'Cannot close the requests.'; fa = 'Cannot close the requests.';
						|it = 'Impossibile chiudere le richieste.';
						|pl = 'Nie udało się zamknąć zleceń.';
						|tr = 'Talepler kapatılamadı.'", Common.DefaultLanguageCode());
		WriteLogEvent(
			ErrorText,
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
	EndTry;
	
	SetPrivilegedMode(False);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(PerformanceMeasurement, ProcessedItemsCount);
	
	Return ProcessedItemsCount;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
// 
// Parameters:
//  Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text = "AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(WhoStated)
	|	AND CASE
	|		WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPayment) THEN
	|			ValueAllowed(PayrollTransaction)
	|		ELSE
	|			ValueAllowed(BusinessOperation)
	|		END
	|	AND CASE
	|		WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|			OR BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer) THEN
	|			ValueAllowed(ARAPDetails.Partner) OR ARAPDetails.Partner IS NULL
	|		WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) THEN
	|			ValueAllowed(AdvanceHolder)
	|	ELSE TRUE END";

EndProcedure
// End StandardSubsystems.AccessManagement

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = UserNotificationsOfEvents.NotificationTypeGroup("TreasuryAndARAPAccounting");
	NewTypeOfAlerts.Id = "487a9d01-34bd-4f0a-a2fc-32a22e0eb00a";
	NewTypeOfAlerts.Description = NStr("vi = 'Thay đổi trạng thái yêu cầu chi tiền';
										|ru = 'Изменение статуса заявки на расходование денежных средств';
										|en = 'Payment request status change'; fa = 'Payment request status change';
										|it = 'Payment request status change';
										|pl = 'Payment request status change';
										|tr = 'Nakit harcama talebi durumunun değiştirilmesi'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.Nonexclusive;
	NewTypeOfAlerts.DCSTemplateName = Metadata.Documents.PaymentRequest.Templates.Notifications_StatusChange.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã thiết lập trạng thái [Status] cho chứng từ';
												|ru = 'Документу установлен статус [Status]';
												|en = 'The document status is set to [Status]';
												|it = 'The document status is set to [Status]';
												|pl = 'The document status is set to [Status]';
												|tr = 'Belge durumu [Status] olarak ayarlandı'"; // @NStr-1
	UserNotificationsOfEvents.AddDescriptionOfDataSource(NewTypeOfAlerts, 
		Metadata.Documents.PaymentRequest.FullName());
	
EndProcedure

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.PaymentRequest";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	If RegisterName = "CashToBePaid" Then
		
		QueryText = QueryTextTableCashToBePaid(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		RedefiningParameterCalculation.Insert("PartnerFromDocument", "DocumentData.Partner");
		RedefiningParameterCalculation.Insert("CounterpartyFromDocument", "DocumentData.Counterparty");
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText, FullDocumentName, SynonymForDocumentTable, True, RedefiningParameterCalculation);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ValuesOfHoldingParameters();
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS ThereIsGiftCertificate
	|INTO AvailabilityOfTypeOfSettlementObjectGiftCertificate
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS ARAPDetails
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON (ARAPDetails.ARAPObject = ARAPObjects.Ref)
	|WHERE
	|	ARAPObjects.Object REFS Catalog.GiftCertificates
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Date                                     AS Period,
	|	DocumentData.PaymentDate                              AS PaymentDate,
	|	DocumentData.RequiredPaymentDate                   AS RequiredPaymentDate,
	|	DocumentData.Organization                              AS Organization,
	|	DocumentData.Department                            AS Department,
	|	DocumentData.CompanyRecipient                    AS CompanyRecipient,
	|
	|	CASE
	|		WHEN
	|			ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE)
	|		THEN
	|			VALUE(Catalog.Counterparties.RetailCustomer)
	|	ELSE
	|		DocumentData.Counterparty
	|	END                                                    AS Counterparty,
	|	DocumentData.ListOfCounterparties_                       AS ListOfCounterparties_,
	|
	|	CASE
	|		WHEN
	|			ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE)
	|		THEN
	|			VALUE(Catalog.Partners.RetailCustomer)
	|	ELSE
	|		DocumentData.Partner
	|	END                                                    AS Partner,
	|	DocumentData.Counterparty                               AS CounterpartyFromDocument,
	|	DocumentData.Partner                                  AS PartnerFromDocument,
	|	
	|	DocumentData.AdvanceHolder                          AS AdvanceHolder,
	|	DocumentData.Currency                                   AS Currency,
	|	DocumentData.Status                                   AS Status,
	|	DocumentData.BusinessOperation                    AS BusinessOperation,
	|	DocumentData.CashFlowItem            AS CashFlowItem,
	|	DocumentData.TargetFundItem                     AS TargetFundItem,
	|	DocumentData.PayrollTransaction          AS PayrollTransaction,
	|	DocumentData.PaymentMethodOfPaymentRequest                        AS PaymentMethod,
	|	DocumentData.OverLimits                              AS OverLimits,
	|
	|	DocumentData.BankAccount                           AS BankAccount,
	|	DocumentData.Number                                    AS Number,
	|	DocumentData.PaymentPurposes                        AS PaymentPurposes,
	|	DocumentData.Comment                              AS Comment,
	|	DocumentData.Posted                                 AS Posted,
	|	DocumentData.DeletionMark                          AS DeletionMark,
	|	DocumentData.DocumentAmount                           AS DocumentAmount,
	|	DocumentData.Contract                                  AS Contract,
	|	DocumentData.LineOfBusiness                  AS LineOfBusiness,
	|	DocumentData.WhoStated                                AS EmployeeResponsible,
	|	DocumentData.Author                                    AS Author,
	|	DocumentData.WhoStated                                AS WhoStated,
	|	ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE) AS ThereIsGiftCertificate,
	|	DocumentData.PaymentPriority                          AS PaymentPriority,
	|	DocumentData.TransferToEmployeeViaABank          AS TransferToEmployeeViaABank
	|FROM
	|	DocumentDataHeader AS DocumentData
	|		LEFT JOIN AvailabilityOfTypeOfSettlementObjectGiftCertificate AS AvailabilityOfGiftCertificateType
	|		ON TRUE
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	For Each KeyAndValue In ValuesOfHoldingParameters(Attributes) Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
EndProcedure

Procedure GetDocumentData(Query, DocumentRef)

	ListOfRequests = New Array;
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests);
	QueryTextDocumentDataTableDistributionByAccounts(ListOfRequests);
	QueryTextDocumentDataTablePersonalAccountsOfEmployees(ListOfRequests);

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader = "SELECT
	|	HeaderData_.Date AS Date,
	|	HeaderData_.Number AS Number,
	|	HeaderData_.DeletionMark AS DeletionMark,
	|	HeaderData_.Posted AS Posted,
	|	HeaderData_.Ref AS Ref,
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Status AS Status,
	|	HeaderData_.BusinessOperation AS BusinessOperation,
	|	HeaderData_.DocumentAmount AS DocumentAmount,
	|	HeaderData_.Currency AS Currency,
	|	HeaderData_.PaymentMethodCash AS PaymentMethodCash,
	|	HeaderData_.PaymentMethodBankAccount AS PaymentMethodBankAccount,
	|	HeaderData_.MethodOfPaymentPaymentCard AS MethodOfPaymentPaymentCard,
	|	HeaderData_.BankAccount AS BankAccount,
	|	HeaderData_.CashAccount AS CashAccount,
	|	HeaderData_.PaymentPurposes AS PaymentPurposes,
	|	HeaderData_.RequiredPaymentDate AS RequiredPaymentDate,
	|	HeaderData_.Counterparty AS Counterparty,
	|	HeaderData_.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	HeaderData_.AdvanceHolder AS AdvanceHolder,
	|	HeaderData_.CompanyRecipient AS CompanyRecipient,
	|	HeaderData_.BankAccountBeneficiary AS BankAccountBeneficiary,
	|	HeaderData_.CashAccountRecipient AS CashAccountRecipient,
	|	HeaderData_.Department AS Department,
	|	HeaderData_.WhoStated AS WhoStated,
	|	HeaderData_.WhoDecided AS WhoDecided,
	|	HeaderData_.Comment AS Comment,
	|	HeaderData_.PaymentMethodOfPaymentRequest AS PaymentMethodOfPaymentRequest,
	|	HeaderData_.PaymentDate AS PaymentDate,
	|	HeaderData_.DocumentBasis AS DocumentBasis,
	|	HeaderData_.CashFlowItem AS CashFlowItem,
	|	HeaderData_.Author AS Author,
	|	HeaderData_.CurrencyOfConversion AS CurrencyOfConversion,
	|	HeaderData_.ConversionAmount AS ConversionAmount,
	|	HeaderData_.ConversionRate AS ConversionRate,
	|	HeaderData_.AmountPlanning AS AmountPlanning,
	|	HeaderData_.PaysheetNumber AS PaysheetNumber,
	|	HeaderData_.PaysheetDate AS PaysheetDate,
	|	HeaderData_.OverLimits AS OverLimits,
	|	HeaderData_.AssetAndLiabilityItem AS AssetAndLiabilityItem,
	|	HeaderData_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	HeaderData_.PaymentID AS PaymentID,
	|	HeaderData_.PayrollTransaction AS PayrollTransaction,
	|	HeaderData_.ExpenseReportDate AS ExpenseReportDate,
	|	HeaderData_.ContractWithSDOParticipant AS ContractWithSDOParticipant,
	|	HeaderData_.PaymentsAsPer275FZ AS PaymentsAsPer275FZ,
	|	HeaderData_.PaymentType275FZ AS PaymentType275FZ,
	|	HeaderData_.SubjectOfPayment AS SubjectOfPayment,
	|	HeaderData_.PaymentOption AS PaymentOption,
	|	HeaderData_.ContractSubjectClause AS ContractSubjectClause,
	|	HeaderData_.ContractPaymentClause AS ContractPaymentClause,
	|	HeaderData_.TransferOfTaxesAndContributions AS TransferOfTaxesAndContributions,
	|	HeaderData_.KindOfFundsTransferToBudget AS KindOfFundsTransferToBudget,
	|	HeaderData_.RNCPSRNCMTCode AS RNCPSRNCMTCode,
	|	HeaderData_.BasisIndicator AS BasisIndicator,
	|	HeaderData_.PeriodIndicator AS PeriodIndicator,
	|	HeaderData_.NumberIndicator AS NumberIndicator,
	|	HeaderData_.DateIndicator AS DateIndicator,
	|	HeaderData_.TypeIndicator AS TypeIndicator,
	|	HeaderData_.AuthorStatus AS AuthorStatus,
	|	HeaderData_.BCCode AS BCCode,
	|	HeaderData_.TaxType AS TaxType,
	|	HeaderData_.PaysheetPersonalIncomeTax AS PaysheetPersonalIncomeTax,
	|	HeaderData_.PaymentPriority AS PaymentPriority,
	|	HeaderData_.RegistrationWithTaxAuthority AS RegistrationWithTaxAuthority,
	|	HeaderData_.TINOfPayer AS TINOfPayer,
	|	HeaderData_.PayerCRTR AS PayerCRTR,
	|	HeaderData_.PayerSName AS PayerSName,
	|	HeaderData_.TransferFeeType AS TransferFeeType,
	|	HeaderData_.InformationToPaymentRecipient AS InformationToPaymentRecipient,
	|	HeaderData_.ConditionOfConversionTransaction AS ConditionOfConversionTransaction,
	|	HeaderData_.BankAccountForFeeWriteOff AS BankAccountForFeeWriteOff,
	|	HeaderData_.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	HeaderData_.LineOfBusiness AS LineOfBusiness,
	|	HeaderData_.Contract AS Contract,
	|	HeaderData_.ConversionRateMultiplier AS ConversionRateMultiplier,
	|	HeaderData_.Partner AS Partner,
	|	HeaderData_.PersonsList AS PersonsList,
	|	HeaderData_.IncomeKindCode AS IncomeKindCode,
	|	HeaderData_.AcquiringContract AS AcquiringContract,
	|	HeaderData_.RecordCommission AS RecordCommission,
	|	HeaderData_.FeeAmount AS FeeAmount,
	|	HeaderData_.ExpenseItem AS ExpenseItem,
	|	HeaderData_.DimensionOfExpenses AS DimensionOfExpenses,
	|	HeaderData_.GLAccountSettings AS GLAccountSettings,
	|	HeaderData_.PaymentCode AS PaymentCode,
	|	HeaderData_.VATTaxation AS VATTaxation,
	|	HeaderData_.ControlPaymentByARAPObjects AS ControlPaymentByARAPObjects,
	|	HeaderData_.Closed_ AS Closed_,
	|	HeaderData_.TransferToEmployeeViaABank AS TransferToEmployeeViaABank,
	|	HeaderData_.TargetFundItem AS TargetFundItem,
	|	HeaderData_.ListOfCounterparties_ AS ListOfCounterparties_,
	|	HeaderData_.Counterparty.Partner AS CounterpartyPartner,
	|	HeaderData_.BankAccount.LineOfBusiness AS BankAccountLineOfBusiness,
	|	HeaderData_.CashAccount.LineOfBusiness AS CashAccountLineOfBusiness,
	|	HeaderData_.AcquiringContract.LineOfBusiness AS AcquiringContractLineOfBusiness
	|INTO DocumentDataHeader
	|FROM
	|	Document.PaymentRequest AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextHeader);
	
EndProcedure

Procedure QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests)
	
	QueryText = "SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	PaymentDecryptionTable.Ref AS Ref,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
	|	PaymentDecryptionTable.AmountARAP AS AmountARAP,
	|	PaymentDecryptionTable.ExpenseItem AS ExpenseItem,
	|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
	|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	PaymentDecryptionTable.Comment AS Comment,
	|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.EmployeeLoanAgreement AS EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
	|	PaymentDecryptionTable.Department AS Department,
	|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|	PaymentDecryptionTable.Statement AS Statement,
	|	PaymentDecryptionTable.Organization AS Organization,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
	|	PaymentDecryptionTable.ExchangeRateNumeratorOfMutualSettlements AS ExchangeRateNumeratorOfMutualSettlements,
	|	PaymentDecryptionTable.TheExchangeRateIsTheDenominatorOfMutualSettlements AS TheExchangeRateIsTheDenominatorOfMutualSettlements,
	|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
	|	PaymentDecryptionTable.MaturityDate AS MaturityDate,
	|	PaymentDecryptionTable.LeaseContracts.Department AS LeaseContractDivision,
	|	PaymentDecryptionTable.LeaseContracts.LineOfBusiness AS LeaseContractLineOfBusiness,
	|	PaymentDecryptionTable.ARAPObject.LineOfBusiness AS ARAPObjectLineOfBusiness,
	|	PaymentDecryptionTable.ARAPObject.Contract AS ARAPObjectContract,
	|	PaymentDecryptionTable.Counterparty AS Counterparty,
	|	PaymentDecryptionTable.LoanDepositContract.CashFlowItemOfPrincipalDebt AS
	|		ContractOfLoanDepositArticleDdsOfPrincipalDebt,
	|	PaymentDecryptionTable.LoanDepositContract.CashFlowItemOfReceiptIssuie AS
	|		ContractOfLoanDepositArticleDDSOfReceiptIssuance,
	|	PaymentDecryptionTable.LoanDepositContract.CashFlowItemOfInterestPayment AS ContractOfLoanDepositArticleDDSInterest,
	|	PaymentDecryptionTable.LoanDepositContract.CashFlowItemOfFeePayment AS ContractOfLoanDepositArticleDdsFees,
	|	PaymentDecryptionTable.LoanDepositContract.LineOfBusiness AS
	|		LoanDepositContractLineOfBusiness
	|INTO DocumentDataTableDecryptionOfPayment
	|FROM
	|	Document.PaymentRequest.ARAPDetails AS PaymentDecryptionTable
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDocumentDataTableDistributionByAccounts(ListOfRequests)
	
	QueryText = "SELECT
	|	TableDistributionByAccounts.LineNumber AS LineNumber,
	|	TableDistributionByAccounts.Ref AS Ref,
	|	TableDistributionByAccounts.BankAccountCashAccount AS BankAccountCashAccount,
	|	TableDistributionByAccounts.Sum AS Sum,
	|	TableDistributionByAccounts.PaymentDate AS PaymentDate
	|INTO DocumentDataTableDistributionByAccounts
	|FROM
	|	Document.PaymentRequest.AllocationByAccounts AS TableDistributionByAccounts
	|WHERE
	|	TableDistributionByAccounts.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDocumentDataTablePersonalAccountsOfEmployees(ListOfRequests)
	
	QueryText = "SELECT
	|	TablePersonalAccountsOfEmployees.LineNumber AS LineNumber,
	|	TablePersonalAccountsOfEmployees.Ref AS Ref,
	|	TablePersonalAccountsOfEmployees.Individual AS Individual,
	|	TablePersonalAccountsOfEmployees.PersonalAccount AS PersonalAccount,
	|	TablePersonalAccountsOfEmployees.Sum AS Sum,
	|	TablePersonalAccountsOfEmployees.CashFlowItem AS CashFlowItem
	|INTO DocumentDataTablePersonalAccountsOfEmployees
	|FROM
	|	Document.PaymentRequest.PersonalAccountsOfStaff AS TablePersonalAccountsOfEmployees
	|WHERE
	|	TablePersonalAccountsOfEmployees.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                         Common.MetadataObjectID("Document.PaymentRequest"));
	Values.Insert("UsePaymentRequests", GetFunctionalOption("UsePaymentRequests"));
	Values.Insert("UsePayroll",                  Constants.UsePayroll.Get());
	Values.Insert("UseCashFlowLimits",        GetFunctionalOption("UseCashFlowLimits"));
	Values.Insert("UseExpenseLimitsForOrganizations",         GetFunctionalOption("UseCashFlowLimitsByCompanies"));
	Values.Insert("UseExpenseLimitsByDivision",       GetFunctionalOption("UseCashFlowLimitsByBusinessUnit"));
	Values.Insert("UseAccountingOfOtherAssetsAndLiabilities",           GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	
	If Attributes <> Undefined Then
		Values.Insert("CashFlowItem",               CashFlowArticleOfDocument(Attributes));
		Values.Insert("OverLimits",                                 Attributes.OverLimits);
		Values.Insert("NumberForPrinting",                               ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;
	
	Return Values;
	
EndFunction

Procedure InitializeTrackingAnalyticsKeysForPartners(Attributes, DocumentRef, TempTablesManager, DocumentObject = Undefined)

	Query = New Query("
	|SELECT DISTINCT
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	CASE WHEN PaymentDecryptionTable.Organization = VALUE(Catalog.Companies.EmptyRef)
	|		THEN &Organization
	|		ELSE PaymentDecryptionTable.Organization
	|	END AS Organization,
	|	CASE WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany))
	|		THEN VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE PaymentDecryptionTable.Partner
	|	END AS Partner,
	|	CASE WHEN &ListOfCounterparties_
	|			THEN PaymentDecryptionTable.Counterparty
	|		ELSE &Counterparty
	|	END AS Counterparty,
	|
	|	CASE WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|											VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany))
	|			THEN ISNULL(PaymentDecryptionTable.ARAPObjectContract, VALUE(Catalog.IntercompanyContracts.EmptyRef))
	|		ELSE ISNULL(PaymentDecryptionTable.ARAPObjectContract, VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|	END AS Contract,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|			VALUE(Enum.BusinessTransactions.TransferToDeposits),
	|			VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty)) THEN
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.PaymentToLessor)) THEN
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		ELSE
	|			ISNULL(PaymentDecryptionTable.ARAPObjectLineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	END AS LineOfBusiness
	|
	|INTO TableOfCalculationObjects
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|		VALUE(Enum.BusinessTransactions.CustomsPayment),
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|		VALUE(Enum.BusinessTransactions.TransferToDeposits),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty),
	|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|		VALUE(Enum.BusinessTransactions.PaymentToLessor),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany))
	|
	|INDEX BY
	|	ARAPObject
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfCalculationObjects.Organization AS Organization,
	|	TableOfCalculationObjects.Counterparty  AS Counterparty,
	|	TableOfCalculationObjects.Partner     AS Partner,
	|	TableOfCalculationObjects.Contract     AS Contract,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness
	|FROM
	|	TableOfCalculationObjects AS TableOfCalculationObjects
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		TableOfCalculationObjects.Organization = Dimension.Organization
	|		AND TableOfCalculationObjects.Counterparty = Dimension.Counterparty
	|		AND TableOfCalculationObjects.Partner = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TableOfCalculationObjects.Organization           AS Organization,
	|	&CompanyRecipient                        AS Counterparty,
	|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
	|	TableOfCalculationObjects.Contract   AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	TableOfCalculationObjects AS TableOfCalculationObjects
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		TableOfCalculationObjects.Organization = Dimension.Organization
	|		AND &CompanyRecipient = Dimension.Counterparty
	|		AND VALUE(Catalog.Partners.OurEnterprise) = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany))
	|");
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("Organization", Attributes.Organization);
	Query.SetParameter("CompanyRecipient", Attributes.CompanyRecipient);
	Query.SetParameter("Counterparty", Attributes.Counterparty);
	Query.SetParameter("ListOfCounterparties_", Attributes.ListOfCounterparties_);
	Query.SetParameter("BusinessOperation", Attributes.BusinessOperation);
	Query.TempTablesManager = TempTablesManager;

	If DocumentObject = Undefined Then
		Query.Text = StrReplace(Query.Text, "DocumentDataTableDecryptionOfPayment", "Document.PaymentRequest.ARAPDetails");
		Query.Text = StrReplace(Query.Text, "PaymentDecryptionTable.ARAPObjectContract", "PaymentDecryptionTable.ARAPObject.Contract");
		Query.Text = StrReplace(Query.Text, "PaymentDecryptionTable.LoanDepositContractLineOfBusiness", "PaymentDecryptionTable.LoanDepositContract.LineOfBusiness");
		Query.Text = StrReplace(Query.Text, "PaymentDecryptionTable.LeaseContractLineOfBusiness", "PaymentDecryptionTable.LeaseContracts.LineOfBusiness");
		Query.Text = StrReplace(Query.Text, "PaymentDecryptionTable.ARAPObjectLineOfBusiness", "PaymentDecryptionTable.ARAPObject.LineOfBusiness");
	EndIf;

	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;

EndProcedure

Function RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject)
	
	RegisterName = "PaymentDecryptionTable";
	
	SetParameterForPartnerAccountingAnalyticsRequest(Query, DocumentObject);
	
	TypesOfPersonalIncomeTax = New Array;
	TypesOfPersonalIncomeTax.Add(Catalogs.TaxContributionKinds.GetLinkOfPredefinedElement("PERSONALINCOMETAX"));
	TypesOfPersonalIncomeTax.Add(Catalogs.TaxContributionKinds.GetLinkOfPredefinedElement("PersonalIncomeTaxOnIncomeInExcessOfMaximumAmountCalculatedByTaxAgent"));
	Query.SetParameter("TypesOfPersonalIncomeTax", TypesOfPersonalIncomeTax);
	
	QueryText = "
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|	
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
	|	PaymentDecryptionTable.EmployeeLoanAgreement AS EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	UNDEFINED AS Statement,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
	|	CASE
	|		WHEN &ThereIsGiftCertificate = TRUE
	|			THEN &Partner
	|		ELSE PaymentDecryptionTable.Partner
	|	END AS Partner,
	|	ISNULL(TableOfCalculationObjects.Counterparty, &Counterparty) AS Counterparty,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|		THEN PaymentDecryptionTable.LeaseContractDivision 
	|		ELSE
	|			UNDEFINED
	|	END 
	|	AS Department,
	|
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.Ref AS Ref
	|
	|INTO PaymentDecryptionTable
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	
	|	LEFT JOIN
	|		TableOfCalculationObjects AS TableOfCalculationObjects
	|	ON
	|		PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|		AND PaymentDecryptionTable.Partner = TableOfCalculationObjects.Partner
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		TableOfCalculationObjects.Organization = Dimension.Organization
	|		AND TableOfCalculationObjects.Counterparty = Dimension.Counterparty
	|		AND CASE WHEN &ThereIsGiftCertificate = TRUE
	|			THEN &Partner
	|			ELSE TableOfCalculationObjects.Partner
	|		END = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|		VALUE(Enum.BusinessTransactions.CustomsPayment)
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	UNDEFINED AS ARAPObject,
	|
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|
	|	UNDEFINED AS AccountingDimensionByPartners,
	|	UNDEFINED AS LoanDepositContract,
	|	UNDEFINED AS LoanAndDepositAmountType,
	|	UNDEFINED AS EmployeeLoanAgreement,
	|	UNDEFINED AS LeaseContracts,
	|	UNDEFINED AS TypeOfLeasePayment,
	|	PaymentDecryptionTable.Statement AS Statement,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.Ref AS Ref
	|
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.SalaryPayment)
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|	
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
	|	PaymentDecryptionTable.EmployeeLoanAgreement AS EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions)
	|				AND DocumentData.TaxType IN (&TypesOfPersonalIncomeTax)
	|		THEN PaymentDecryptionTable.Statement 
	|		ELSE UNDEFINED
	|	END AS Statement,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	UNDEFINED AS Counterparty,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|		THEN PaymentDecryptionTable.Department
	|		ELSE UNDEFINED
	|	END AS Department,
	|
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|		THEN PaymentDecryptionTable.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|	CASE WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.OtherCashIssue))
	|		THEN PaymentDecryptionTable.ExpenseItem
	|		WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions))
	|		THEN
	|			CASE WHEN &UseAccountingOfOtherAssetsAndLiabilities THEN
	|				VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes)
	|			ELSE
	|				UNDEFINED
	|			END
	|	END AS ExpenseItem,
	|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions) 
	|		THEN DocumentData.TaxType 
	|		ELSE PaymentDecryptionTable.AssetsLiabilitiesDimension
	|	END AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.Ref AS Ref
	|
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON PaymentDecryptionTable.Ref = DocumentData.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND PaymentDecryptionTable.Partner = Dimension.Partner
	|		AND Dimension.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND Dimension.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OtherCashIssue),
	|		VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|	
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
	|	PaymentDecryptionTable.EmployeeLoanAgreement AS EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	UNDEFINED AS Statement,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.Ref AS Ref
	|	
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|
	|	LEFT JOIN
	|		TableOfCalculationObjects AS TableOfCalculationObjects
	|	ON
	|		PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|		AND VALUE(Catalog.Partners.OurEnterprise) = TableOfCalculationObjects.Partner
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		TableOfCalculationObjects.Organization = Dimension.Organization
	|		AND &CompanyRecipient = Dimension.Counterparty
	|		AND VALUE(Catalog.Partners.OurEnterprise) = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber,
	|	PaymentDecryptionTable.ARAPObject,
	|
	|	PaymentDecryptionTable.Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|	
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|
	|	ISNULL(Dimension.DimensionKey, UNDEFINED),
	|	PaymentDecryptionTable.LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType,
	|	PaymentDecryptionTable.EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	UNDEFINED AS Statement,
	|	PaymentDecryptionTable.CashFlowItem,
	|	PaymentDecryptionTable.TargetFundItem,
	|	CASE
	|		WHEN PaymentDecryptionTable.Partner <> VALUE(Catalog.Partners.EmptyRef) THEN
	|			PaymentDecryptionTable.Partner
	|		ELSE
	|			DocumentData.CounterpartyPartner
	|	END AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.Ref AS Ref
	|
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|		LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON PaymentDecryptionTable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON (&Organization = Dimension.Organization)
	|			AND (&Counterparty = Dimension.Counterparty)
	|			AND CASE
	|				WHEN PaymentDecryptionTable.Partner <> VALUE(Catalog.Partners.EmptyRef) THEN
	|					PaymentDecryptionTable.Partner
	|				ELSE
	|					PaymentDecryptionTable.Ref.Counterparty.Partner
	|			END = Dimension.Partner
	|			AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = Dimension.Contract
	|			AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|		VALUE(Enum.BusinessTransactions.TransferToDeposits),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber,
	|	PaymentDecryptionTable.ARAPObject,
	|
	|	PaymentDecryptionTable.Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|	
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|
	|	ISNULL(Dimension.DimensionKey, UNDEFINED),
	|	PaymentDecryptionTable.LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType,
	|	PaymentDecryptionTable.EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	UNDEFINED AS Statement,
	|	PaymentDecryptionTable.CashFlowItem,
	|	PaymentDecryptionTable.TargetFundItem,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.Ref AS Ref
	|
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON (&Organization = Dimension.Organization)
	|			AND (&Counterparty = Dimension.Counterparty)
	|			AND PaymentDecryptionTable.Partner = Dimension.Partner
	|			AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = Dimension.Contract
	|			AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee)
	|	)
	|	AND &UsePayroll
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber,
	|	PaymentDecryptionTable.ARAPObject,
	|
	|	PaymentDecryptionTable.Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|	
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|
	|	ISNULL(Dimension.DimensionKey, UNDEFINED),
	|	PaymentDecryptionTable.LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType,
	|	PaymentDecryptionTable.EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	UNDEFINED AS Statement,
	|	PaymentDecryptionTable.CashFlowItem,
	|	PaymentDecryptionTable.TargetFundItem,
	|	CASE
	|		WHEN PaymentDecryptionTable.Partner <> VALUE(Catalog.Partners.EmptyRef) THEN
	|			PaymentDecryptionTable.Partner
	|		ELSE
	|			DocumentData.CounterpartyPartner
	|	END AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.Ref AS Ref
	|
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|		
	|		LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON PaymentDecryptionTable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON (&Organization = Dimension.Organization)
	|			AND (&Counterparty = Dimension.Counterparty)
	|			AND CASE
	|				WHEN PaymentDecryptionTable.Partner <> VALUE(Catalog.Partners.EmptyRef) THEN
	|					PaymentDecryptionTable.Partner
	|				ELSE
	|					DocumentData.CounterpartyPartner
	|			END = Dimension.Partner
	|			AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = Dimension.Contract
	|			AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	1,
	|	UNDEFINED,
	|
	|	Request.DocumentAmount,
	|	Request.DocumentAmount,
	|	Request.Currency,
	|
	|	UNDEFINED,
	|	0,
	|	
	|	&AccountingDimensionByPartners,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED AS Statement,
	|	Request.CashFlowItem,
	|	Request.TargetFundItem,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED,
	|	
	|	UNDEFINED,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	Request.Ref
	|
	|FROM
	|	DocumentDataHeader AS Request
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee)
	|	AND NOT &UsePayroll
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCashToBePaid(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "CashToBePaid";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableDistributionByAccounts.PaymentDate AS Period,
	|	&Ref AS PaymentRequest,
	|	TableDistributionByAccounts.BankAccountCashAccount AS BankAccountCashAccount,
	|	CASE
	|		WHEN DocumentData.PersonsList THEN
	|			UNDEFINED
	|		WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|			VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee)
	|		) THEN
	|			&AdvanceHolder
	|		WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
	|		) THEN
	|			&CompanyRecipient
	|		WHEN DocumentData.ListOfCounterparties_
	|			THEN UNDEFINED
	|		ELSE
	|			&CounterpartyFromDocument
	|	END AS Recipient,
	|	
	|	&Organization AS Organization,
	|	
	|	TableDistributionByAccounts.Sum AS Sum,
	|	
	|	&BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|	LEFT JOIN
	|		DocumentDataTableDistributionByAccounts AS TableDistributionByAccounts
	|	ON
	|		TableDistributionByAccounts.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &UsePaymentRequests
	|	AND &Status <> VALUE(Enum.StatusesOfPaymentRequests.IsRejected)
	|	AND NOT TableDistributionByAccounts.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.RequiredPaymentDate AS Period,
	|	&Ref AS PaymentRequest,
	|	UNDEFINED AS BankAccountCashAccount,
	|
	|	CASE
	|		WHEN DocumentData.PersonsList THEN
	|			UNDEFINED
	|		WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|			VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee)
	|		) THEN
	|			&AdvanceHolder
	|		WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
	|		) THEN
	|			&CompanyRecipient
	|		WHEN DocumentData.ListOfCounterparties_
	|			THEN UNDEFINED
	|		ELSE
	|			&CounterpartyFromDocument
	|	END AS Recipient,
	|	
	|	&Organization AS Organization,
	|	
	|	DocumentData.DocumentAmount - SUM(ISNULL(TableDistributionByAccounts.Sum, 0)) AS Sum,
	|	
	|	&BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|	LEFT JOIN
	|		DocumentDataTableDistributionByAccounts AS TableDistributionByAccounts
	|	ON
	|		TableDistributionByAccounts.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &UsePaymentRequests
	|	AND &Status <> VALUE(Enum.StatusesOfPaymentRequests.IsRejected)
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.RequiredPaymentDate,
	|	DocumentData.PersonsList,
	|	DocumentData.ListOfCounterparties_,
	|	DocumentData.DocumentAmount
	|
	|HAVING
	|	DocumentData.DocumentAmount - SUM(ISNULL(TableDistributionByAccounts.Sum, 0)) > 0
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.PaymentRequest");
		QueryText = StrReplace(QueryText, "DocumentDataTableDistributionByAccounts", "Document.PaymentRequest.AllocationByAccounts");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCashFlowLimits(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashFlowLimits";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Query.Parameters.Property("UseCashFlowLimits") Then
		UseCashFlowLimits = Query.Parameters.UseCashFlowLimits;
	Else
		UseCashFlowLimits = GetFunctionalOption("UseCashFlowLimits");
	EndIf;
	
	If Not UseCashFlowLimits Then
		Return "";
	EndIf;

	If Not (DocumentObject.Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon
		Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AgreedUpon
		Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AmountDue) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	SetRequestParametersCurrencyCoefficients(Query);

	ArrayOfRequestTexts = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee)
		And Not DocumentObject.PersonsList Then
		
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber AS ApplicationLineNumber,
		|	0 AS StatementLineNumber,
		|	
		|	CASE WHEN &PaymentDate <> DATETIME(1,1,1) THEN
		|		BEGINOFPERIOD(&PaymentDate, MONTH)
		|	WHEN &RequiredPaymentDate <> DATETIME(1,1,1) THEN
		|		BEGINOFPERIOD(&RequiredPaymentDate, MONTH)
		|	ELSE
		|		BEGINOFPERIOD(&Period, MONTH)
		|	END AS Period,
		|	
		|	CASE
		|		WHEN &UseExpenseLimitsForOrganizations
		|			THEN &Organization 
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS Organization,
		|	CASE
		|		WHEN &UseExpenseLimitsByDivision
		|			THEN &Department 
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS Department,
		|	
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	
		|	CASE
		|		WHEN NOT &OverLimits
		|			THEN PaymentDecryptionTable.Sum * &ConversionRateToManCurrency 
		|		ELSE 0
		|	END AS ConsumptionWithinLimit,
		|	
		|	CASE
		|		WHEN &OverLimits
		|			THEN PaymentDecryptionTable.Sum * &ConversionRateToManCurrency 
		|		ELSE 0
		|	END AS ExcessExpense
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	INNER JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And DocumentObject.PersonsList Then
		
		QueryText = "
		|SELECT
		|	TablePersonalAccountsOfEmployees.LineNumber AS ApplicationLineNumber,
		|	0 AS StatementLineNumber,
		|	
		|	CASE WHEN &PaymentDate <> DATETIME(1,1,1) THEN
		|		BEGINOFPERIOD(&PaymentDate, MONTH)
		|	WHEN &RequiredPaymentDate <> DATETIME(1,1,1) THEN
		|		BEGINOFPERIOD(&RequiredPaymentDate, MONTH)
		|	ELSE
		|		BEGINOFPERIOD(&Period, MONTH)
		|	END AS Period,
		|	
		|	CASE
		|		WHEN &UseExpenseLimitsForOrganizations
		|			THEN &Organization 
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS Organization,
		|	CASE
		|		WHEN &UseExpenseLimitsByDivision
		|			THEN &Department 
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS Department,
		|	
		|	TablePersonalAccountsOfEmployees.CashFlowItem AS CashFlowItem,
		|	
		|	CASE
		|		WHEN NOT &OverLimits
		|			THEN TablePersonalAccountsOfEmployees.Sum * &ConversionRateToManCurrency 
		|		ELSE 0
		|	END AS ConsumptionWithinLimit,
		|	
		|	CASE
		|		WHEN &OverLimits
		|			THEN TablePersonalAccountsOfEmployees.Sum * &ConversionRateToManCurrency 
		|		ELSE 0
		|	END AS ExcessExpense
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	INNER JOIN DocumentDataTablePersonalAccountsOfEmployees AS TablePersonalAccountsOfEmployees
		|		ON DocumentData.Ref = TablePersonalAccountsOfEmployees.Ref
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber AS ApplicationLineNumber,
		|	0 AS StatementLineNumber,
		|	
		|	CASE WHEN &PaymentDate <> DATETIME(1,1,1) THEN
		|		BEGINOFPERIOD(&PaymentDate, MONTH)
		|	WHEN &RequiredPaymentDate <> DATETIME(1,1,1) THEN
		|		BEGINOFPERIOD(&RequiredPaymentDate, MONTH)
		|	ELSE
		|		BEGINOFPERIOD(&Period, MONTH)
		|	END AS Period,
		|	
		|	CASE
		|		WHEN &UseExpenseLimitsForOrganizations
		|			THEN &Organization 
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS Organization,
		|	CASE
		|		WHEN &UseExpenseLimitsByDivision
		|			THEN &Department 
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS Department,
		|	
		|	&CashFlowItem AS CashFlowItem,
		|	
		|	CASE
		|		WHEN NOT &OverLimits
		|			THEN ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount) * &ConversionRateToManCurrency 
		|		ELSE 0
		|	END AS ConsumptionWithinLimit,
		|	
		|	CASE
		|		WHEN &OverLimits
		|			THEN ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount) * &ConversionRateToManCurrency 
		|		ELSE 0
		|	END AS ExcessExpense
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
		|	ON
		|		DocumentData.Ref = PaymentDecryptionTable.Ref
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPayment Then
		
		QueryText = "
		|SELECT
		|	0 AS ApplicationLineNumber,
		|	0 AS StatementLineNumber,
		|	
		|	CASE WHEN &PaymentDate <> DATETIME(1,1,1) THEN
		|		BEGINOFPERIOD(&PaymentDate, MONTH)
		|	WHEN &RequiredPaymentDate <> DATETIME(1,1,1) THEN
		|		BEGINOFPERIOD(&RequiredPaymentDate, MONTH)
		|	ELSE
		|		BEGINOFPERIOD(&Period, MONTH)
		|	END AS Period,
		|	
		|	CASE
		|		WHEN &UseExpenseLimitsForOrganizations
		|			THEN &Organization 
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS Organization,
		|	CASE
		|		WHEN &UseExpenseLimitsByDivision
		|			THEN &Department 
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS Department,
		|	
		|	ISNULL(PaymentDecryptionTable.CashFlowItem,&CashFlowItem) AS CashFlowItem,
		|	
		|	CASE
		|		WHEN NOT &OverLimits 
		|			THEN ISNULL(PaymentDecryptionTable.Sum,DocumentData.DocumentAmount) * &ConversionRateToManCurrency 
		|		ELSE 0
		|	END AS ConsumptionWithinLimit,
		|	
		|	CASE
		|		WHEN &OverLimits 
		|			THEN ISNULL(PaymentDecryptionTable.Sum,DocumentData.DocumentAmount) * &ConversionRateToManCurrency 
		|		ELSE 0
		|	END AS ExcessExpense
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		&UsePayroll
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon
		Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AgreedUpon
		Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AmountDue) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	SetParameterForPartnerAccountingAnalyticsRequest(Query, DocumentObject);
	
	If Query.Parameters.Property("UsePayroll") Then
		UsePayroll = Query.Parameters.UsePayroll;
	Else
		UsePayroll = Constants.UsePayroll.Get();
	EndIf;
	
	QueryTextArray = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty) Then
	
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber                       AS LineNumber,
		|	&Period                                                     AS Period,
		|	VALUE(AccumulationRecordType.Expense)                      AS RecordType,
		
		|	PaymentDecryptionTable.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.LoanDepositContract            AS Contract,
		|	CASE
		|		WHEN &BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.TransferToDeposits),
		|			VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty))
		|			THEN VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
		|		ELSE PaymentDecryptionTable.LoanAndDepositAmountType
		|	END AS AmountType,
		|	PaymentDecryptionTable.ARAPCurrency              AS Currency,
		
		|	0 AS Sum,
		|	PaymentDecryptionTable.AmountARAP               AS BeingPaid,
		|	0 AS SumMan,
		|	0 AS SumCompl,
		
		|	&BusinessOperation                                      AS BusinessOperation,
		|	CASE
		|		WHEN ContractData.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
		|			THEN VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)
		|		ELSE VALUE(Enum.FinancialInstrumentScheduleTypes.Tranches)
		|	END AS ScheduleType,
		|	PaymentDecryptionTable.CashFlowItem     AS DimensionItem,
		|	&Ref                                                     AS PaymentRequest
		|	
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|		INNER JOIN Catalog.LoanAndDepositContracts AS ContractData
		|		ON PaymentDecryptionTable.LoanDepositContract = ContractData.Ref";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
	
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber                       AS LineNumber,
		|	&Period                                                     AS Period,
		|	VALUE(AccumulationRecordType.Expense)                      AS RecordType,
		
		|	PaymentDecryptionTable.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.LeaseContracts                     AS Contract,
		|	PaymentDecryptionTable.TypeOfLeasePayment                AS AmountType,
		|	PaymentDecryptionTable.ARAPCurrency              AS Currency,
		
		|	0 AS Sum,
		|	PaymentDecryptionTable.AmountARAP               AS BeingPaid,
		|	0 AS SumMan,
		|	0 AS SumCompl,
		
		|	&BusinessOperation                                      AS BusinessOperation,
		|	VALUE(Enum.FinancialInstrumentScheduleTypes.Payments) AS ScheduleType,
		|	PaymentDecryptionTable.CashFlowItem     AS DimensionItem,
		|	&Ref                                                     AS PaymentRequest
		|	
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|		INNER JOIN Catalog.LeaseContract AS ContractData
		|		ON PaymentDecryptionTable.LeaseContracts = ContractData.Ref
		|";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	If QueryTextArray.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashFlow(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashFlow";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not (DocumentObject.Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon
		Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AgreedUpon
		Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AmountDue) Then
		Return "";
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashToAnotherAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion)
		And Not DocumentObject.PersonsList Then

		QueryText = "
		|SELECT
		|	CASE WHEN &PaymentDate <> DATETIME(1,1,1) THEN
		|		&PaymentDate
		|	WHEN &RequiredPaymentDate <> DATETIME(1,1,1) THEN
		|		&RequiredPaymentDate
		|	ELSE
		|		BEGINOFPERIOD(&Period, DAY)
		|	END AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	CASE DocumentData.PaymentMethodOfPaymentRequest
		|		WHEN VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
		|			DocumentData.CashAccount
		|		ELSE
		|			DocumentData.BankAccount
		|	END AS Cash,
		|	CASE DocumentData.PaymentMethodOfPaymentRequest
		|		WHEN VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
		|			VALUE(Enum.CashTypes.CashPayment)
		|		WHEN VALUE(Enum.PaymentForms.BankAccountPayment) THEN
		|			VALUE(Enum.CashTypes.BankAccountPayments_)
		|		WHEN VALUE(Enum.PaymentForms.InstantPayments) THEN
		|			VALUE(Enum.CashTypes.BankAccountPayments_)
		|		ELSE
		|			UNDEFINED
		|	END AS CashType,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) THEN
		|			PaymentDecryptionTable.CashFlowItem
		|		ELSE &CashFlowItem
		|	END AS CashFlowItem,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) THEN
		|			PaymentDecryptionTable.TargetFundItem
		|		ELSE &TargetFundItem
		|	END AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount)
		|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
		|			THEN DocumentData.BankAccountBeneficiary
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount)
		|			THEN DocumentData.CashAccountRecipient
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|			THEN DocumentData.AdvanceHolder
		|	END AS CorCash,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|			THEN VALUE(Enum.CashTypes.AdvanceHolderSCash)
		|		ELSE VALUE(Enum.CashTypes.CashInTransit)
		|	END AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|	CASE
		|		WHEN DocumentData.OverLimits = FALSE
		|			THEN CASE
		|					WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|						THEN ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount)
		|					ELSE DocumentData.DocumentAmount
		|				END
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DocumentData.OverLimits = TRUE
		|			THEN CASE
		|					WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|						THEN ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount)
		|					ELSE DocumentData.DocumentAmount
		|				END
		|	END AS AmountToBePaidAboveLimit,
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount)
		|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
		|			THEN DocumentData.BankAccountBeneficiary
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount)
		|			THEN DocumentData.CashAccountRecipient
		|	END AS CorSourceOfFAGOfCash,
		|	&Ref AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON (TRUE)
		|";
	
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And DocumentObject.PersonsList Then

		QueryText = "
		|SELECT
		|	CASE
		|		WHEN &PaymentDate <> DATETIME(1, 1, 1)
		|			THEN &PaymentDate
		|		WHEN &RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN &RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(&Period, DAY)
		|	END AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	CASE DocumentData.PaymentMethodOfPaymentRequest
		|		WHEN VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN DocumentData.CashAccount
		|		ELSE DocumentData.BankAccount
		|	END AS Cash,
		|	CASE DocumentData.PaymentMethodOfPaymentRequest
		|		WHEN VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN VALUE(Enum.CashTypes.CashPayment)
		|		WHEN VALUE(Enum.PaymentForms.BankAccountPayment)
		|			THEN VALUE(Enum.CashTypes.BankAccountPayments_)
		|		ELSE UNDEFINED
		|	END AS CashType,
		|	TablePersonalAccountsOfEmployees.CashFlowItem AS CashFlowItem,
		|	&TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.AdvanceHolder AS CorCash,
		|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|	SUM(CASE
		|			WHEN DocumentData.OverLimits = FALSE
		|				THEN TablePersonalAccountsOfEmployees.Sum
		|		END) AS AmountToBePaidWithinLimit,
		|	SUM(CASE
		|			WHEN DocumentData.OverLimits = TRUE
		|				THEN TablePersonalAccountsOfEmployees.Sum
		|		END) AS AmountToBePaidAboveLimit,
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS CorSourceOfFAGOfCash,
		|	&Ref AS PaymentRequest
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		INNER JOIN DocumentDataTablePersonalAccountsOfEmployees AS TablePersonalAccountsOfEmployees
		|		ON DocumentData.Ref = TablePersonalAccountsOfEmployees.Ref
		|
		|GROUP BY
		|	DocumentData.Organization,
		|	DocumentData.Department,
		|	CASE DocumentData.PaymentMethodOfPaymentRequest
		|		WHEN VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN DocumentData.CashAccount
		|		ELSE DocumentData.BankAccount
		|	END,
		|	CASE DocumentData.PaymentMethodOfPaymentRequest
		|		WHEN VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN VALUE(Enum.CashTypes.CashPayment)
		|		WHEN VALUE(Enum.PaymentForms.BankAccountPayment)
		|			THEN VALUE(Enum.CashTypes.BankAccountPayments_)
		|		ELSE UNDEFINED
		|	END,
		|	TablePersonalAccountsOfEmployees.CashFlowItem,
		|	DocumentData.Currency,
		|	DocumentData.AdvanceHolder,
		|	DocumentData.BankAccount,
		|	DocumentData.Currency";
	
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits Then

		QueryText = "
		|SELECT
		|	CASE WHEN &PaymentDate <> DATETIME(1,1,1) THEN
		|		&PaymentDate
		|	WHEN &RequiredPaymentDate <> DATETIME(1,1,1) THEN
		|		&RequiredPaymentDate
		|	ELSE
		|		BEGINOFPERIOD(&Period, DAY)
		|	END AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	PaymentDecryptionTable.LoanDepositContract AS CorCash,
		|	VALUE(Enum.CashTypes.Deposits) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|	CASE
		|		WHEN DocumentData.OverLimits = FALSE
		|			THEN PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DocumentData.OverLimits = TRUE
		|			THEN PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidAboveLimit,
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	PaymentDecryptionTable.LoanDepositContract AS CorSourceOfFAGOfCash,
		|	&Ref AS PaymentRequest
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON (TRUE)
		|";
	
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment Then

		QueryText = "
		|SELECT
		|	CASE WHEN &PaymentDate <> DATETIME(1,1,1) THEN
		|		&PaymentDate
		|	WHEN &RequiredPaymentDate <> DATETIME(1,1,1) THEN
		|		&RequiredPaymentDate
		|	ELSE
		|		BEGINOFPERIOD(&Period, DAY)
		|	END AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	&CashFlowItem AS CashFlowItem,
		|	&TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.AcquiringContract AS CorCash,
		|	VALUE(Enum.CashTypes.BankAcquirerCash) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|	CASE
		|		WHEN DocumentData.OverLimits = FALSE
		|			THEN DocumentData.DocumentAmount
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DocumentData.OverLimits = TRUE
		|			THEN DocumentData.DocumentAmount
		|	END AS AmountToBePaidAboveLimit,
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS CorSourceOfFAGOfCash,
		|	&Ref AS PaymentRequest
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon
		Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AgreedUpon
		Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AmountDue) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Query.Parameters.Property("UsePayroll") Then
		UsePayroll = Query.Parameters.UsePayroll;
	Else
		UsePayroll = Constants.UsePayroll.Get();
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
		
		QueryText = "
		|SELECT
		|	CASE
		|		WHEN &PaymentDate <> DATETIME(1, 1, 1)
		|			THEN &PaymentDate
		|		WHEN &RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN &RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(&Period, DAY)
		|	END AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|	DocumentData.BankAccount AS Cash,
		|	CASE
		|		WHEN DocumentData.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
		|			VALUE(Enum.CashTypes.CashPayment)
		|		ELSE
		|			VALUE(Enum.CashTypes.BankAccountPayments_)
		|	END AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusinessItems,
		|	PaymentDecryptionTable.ExpenseItem AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	CASE
		|		WHEN DocumentData.OverLimits = FALSE
		|			THEN PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DocumentData.OverLimits = TRUE
		|			THEN PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidAboveLimit,
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	PaymentDecryptionTable.ExpenseItem AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	&Ref AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON (TRUE)
		|";
	
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions Then
		
		QueryText = "
		|SELECT
		|	CASE
		|		WHEN &PaymentDate <> DATETIME(1, 1, 1)
		|			THEN &PaymentDate
		|		WHEN &RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN &RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(&Period, DAY)
		|	END AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	DocumentData.TaxType AS AssetsLiabilitiesDimension,
		|	CASE
		|		WHEN DocumentData.OverLimits = FALSE
		|			THEN PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DocumentData.OverLimits = TRUE
		|			THEN PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidAboveLimit,
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	&Ref AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON (TRUE)
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPayment
		And Not UsePayroll Then
		
		QueryText = "
		|SELECT
		|	CASE
		|		WHEN &PaymentDate <> DATETIME(1, 1, 1)
		|			THEN &PaymentDate
		|		WHEN &RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN &RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(&Period, DAY)
		|	END AS Period,
		|	&PayrollTransaction AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|	DocumentData.BankAccount AS Cash,
		|	CASE
		|		WHEN DocumentData.PayrollTransaction = VALUE(Enum.BusinessTransactions.SalaryPaymentViaCashAccount) THEN
		|			VALUE(Enum.CashTypes.CashPayment)
		|		ELSE
		|			VALUE(Enum.CashTypes.BankAccountPayments_)
		|	END AS CashType,
		|	DocumentData.CashFlowItem AS CashFlowItem,
		|	DocumentData.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	CASE
		|		WHEN DocumentData.OverLimits = FALSE
		|			THEN DocumentData.DocumentAmount
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DocumentData.OverLimits = TRUE
		|			THEN DocumentData.DocumentAmount
		|	END AS AmountToBePaidAboveLimit,
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	&Ref AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment
		And DocumentObject.RecordCommission And DocumentObject.FeeAmount <> 0 Then
		
		QueryText = "
		|SELECT
		|	CASE
		|		WHEN &PaymentDate <> DATETIME(1, 1, 1)
		|			THEN &PaymentDate
		|		WHEN &RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN &RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(&Period, DAY)
		|	END AS Period,
		|	VALUE(Enum.BusinessTransactions.AcquiringFee) AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.Department AS IncomeExpenseBusinessUnit,
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	ISNULL(DocumentData.AcquiringContract.CashFlowItemCommission, VALUE(Catalog.CashFlowReportItems.PaymentToVendor)) AS CashFlowItem,
		|	DocumentData.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.AcquiringContractLineOfBusiness AS LineOfBusinessItems,
		|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	CASE
		|		WHEN DocumentData.OverLimits = FALSE
		|			THEN DocumentData.FeeAmount
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DocumentData.OverLimits = TRUE
		|			THEN DocumentData.FeeAmount
		|	END AS AmountToBePaidAboveLimit,
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.ExpenseItem AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	&Ref AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPayment
		And UsePayroll Then
		
		QueryText = "
		|SELECT
		|	CASE
		|		WHEN &PaymentDate <> DATETIME(1, 1, 1)
		|			THEN &PaymentDate
		|		WHEN &RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN &RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(&Period, DAY)
		|	END AS Period,
		|	&PayrollTransaction AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|	DocumentData.BankAccount AS Cash,
		|	CASE
		|		WHEN DocumentData.PayrollTransaction = VALUE(Enum.BusinessTransactions.SalaryPaymentViaCashAccount) THEN
		|			VALUE(Enum.CashTypes.CashPayment)
		|		ELSE
		|			VALUE(Enum.CashTypes.BankAccountPayments_)
		|	END AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	CASE
		|		WHEN DocumentData.OverLimits = FALSE
		|			THEN PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DocumentData.OverLimits = TRUE
		|			THEN PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidAboveLimit,
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	&Ref AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON (TRUE)
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
		And UsePayroll Then
		
		QueryText = "
		|SELECT
		|	CASE
		|		WHEN &PaymentDate <> DATETIME(1, 1, 1)
		|			THEN &PaymentDate
		|		WHEN &RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN &RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(&Period, DAY)
		|	END AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|	DocumentData.BankAccount AS Cash,
		|	CASE
		|		WHEN DocumentData.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
		|			VALUE(Enum.CashTypes.CashPayment)
		|		ELSE
		|			VALUE(Enum.CashTypes.BankAccountPayments_)
		|	END AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	PaymentDecryptionTable.EmployeeLoanAgreement AS AssetsLiabilitiesDimension,
		|	CASE
		|		WHEN DocumentData.OverLimits = FALSE
		|			THEN PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DocumentData.OverLimits = TRUE
		|			THEN PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidAboveLimit,
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	&Ref AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON (TRUE)
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
		And Not UsePayroll Then
	
		QueryText = "
		|SELECT
		|	CASE
		|		WHEN &PaymentDate <> DATETIME(1, 1, 1)
		|			THEN &PaymentDate
		|		WHEN &RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN &RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(&Period, DAY)
		|	END AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|	DocumentData.BankAccount AS Cash,
		|	CASE
		|		WHEN DocumentData.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
		|			VALUE(Enum.CashTypes.CashPayment)
		|		ELSE
		|			VALUE(Enum.CashTypes.BankAccountPayments_)
		|	END AS CashType,
		|	DocumentData.CashFlowItem AS CashFlowItem,
		|	DocumentData.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	CASE
		|		WHEN DocumentData.OverLimits = FALSE
		|			THEN DocumentData.DocumentAmount
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DocumentData.OverLimits = TRUE
		|			THEN DocumentData.DocumentAmount
		|	END AS AmountToBePaidAboveLimit,
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	&Ref AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
	
		QueryText = "
		|SELECT
		|	CASE
		|		WHEN &PaymentDate <> DATETIME(1, 1, 1)
		|			THEN &PaymentDate
		|		WHEN &RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN &RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(&Period, DAY)
		|	END AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|	DocumentData.BankAccount AS Cash,
		|	CASE
		|		WHEN DocumentData.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_) THEN
		|			VALUE(Enum.CashTypes.CashPayment)
		|		ELSE
		|			VALUE(Enum.CashTypes.BankAccountPayments_)
		|	END AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLeasing) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	PaymentDecryptionTable.LeaseContracts AS AssetsLiabilitiesDimension,
		|	CASE
		|		WHEN DocumentData.OverLimits = FALSE
		|			THEN PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DocumentData.OverLimits = TRUE
		|			THEN PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidAboveLimit,
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	&Ref AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON (TRUE)
		|";
	
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCashCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon
		Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AgreedUpon
		Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AmountDue) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	SetParameterForPartnerAccountingAnalyticsRequest(Query, DocumentObject);
	
	QueryTextArray = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment) Then
	
		SubqueryText = "SELECT
		|		CASE
		|			WHEN &PaymentDate <> DATETIME(1, 1, 1)
		|				THEN &PaymentDate
		|			WHEN &RequiredPaymentDate <> DATETIME(1, 1, 1)
		|				THEN &RequiredPaymentDate
		|			ELSE BEGINOFPERIOD(&Period, DAY)
		|		END AS Period,
		|		DocumentData.PaymentMethodCash AS PaymentMethodCash,
		|		DocumentData.PaymentMethodOfPaymentRequest AS PaymentMethodOfPaymentRequest,
		|		DocumentData.Status AS Status,
		|		&BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		DocumentData.Department AS Department,
		|		DocumentData.BankAccountLineOfBusiness AS LineOfBusinessBankAccount,
		|		DocumentData.CashAccountLineOfBusiness AS FieldOfActivityCheckout,
		|		DocumentData.BankAccount AS BankAccount,
		|		DocumentData.CashAccount AS CashAccount,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS CounterpartyLineOfBusiness,
		|		ISNULL(PaymentDecryptionTable.AccountingDimensionByPartners.Partner, PaymentDecryptionTable.Partner) AS Partner,
		|		ISNULL(PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty, DocumentData.Counterparty) AS Counterparty,
		|		ISNULL(PaymentDecryptionTable.ARAPObject.Contract, DocumentData.Contract) AS Contract,
		|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|		PaymentDecryptionTable.Sum AS AmountToBePaid,
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		DocumentData.OverLimits AS OverLimits
		|
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|			LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON (TRUE)
		|";
	
		QueryTextArray.Add(SubqueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
	
		SubqueryText = "SELECT
		|		CASE
		|			WHEN &PaymentDate <> DATETIME(1, 1, 1)
		|				THEN &PaymentDate
		|			WHEN &RequiredPaymentDate <> DATETIME(1, 1, 1)
		|				THEN &RequiredPaymentDate
		|			ELSE BEGINOFPERIOD(&Period, DAY)
		|		END AS Period,
		|		DocumentData.PaymentMethodCash AS PaymentMethodCash,
		|		DocumentData.PaymentMethodOfPaymentRequest AS PaymentMethodOfPaymentRequest,
		|		DocumentData.Status AS Status,
		|		&BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		DocumentData.Department AS Department,
		|		DocumentData.BankAccountLineOfBusiness AS LineOfBusinessBankAccount,
		|		DocumentData.CashAccountLineOfBusiness AS FieldOfActivityCheckout,
		|		DocumentData.BankAccount AS BankAccount,
		|		DocumentData.CashAccount AS CashAccount,
		|		&CashFlowItem AS CashFlowItem,
		|		&TargetFundItem AS TargetFundItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|		VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CounterpartyLineOfBusiness,
		|		UNDEFINED AS Partner,
		|		DocumentData.BankAccountBeneficiary.Owner AS Counterparty,
		|		UNDEFINED AS Contract,
		|		UNDEFINED AS ARAPObject,
		|		DocumentData.DocumentAmount AS AmountToBePaid,
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|		UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		|		DocumentData.OverLimits AS OverLimits
		|	
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|";
	
		QueryTextArray.Add(SubqueryText);
		
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty) Then
	
		SubqueryText = "SELECT
		|		CASE
		|			WHEN &PaymentDate <> DATETIME(1, 1, 1)
		|				THEN &PaymentDate
		|			WHEN &RequiredPaymentDate <> DATETIME(1, 1, 1)
		|				THEN &RequiredPaymentDate
		|			ELSE BEGINOFPERIOD(&Period, DAY)
		|		END AS Period,
		|		DocumentData.PaymentMethodCash AS PaymentMethodCash,
		|		DocumentData.PaymentMethodOfPaymentRequest AS PaymentMethodOfPaymentRequest,
		|		DocumentData.Status AS Status,
		|		CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived)
		|					AND (PaymentDecryptionTable.LoanDepositContract.CashFlowItemOfPrincipalDebt = PaymentDecryptionTable.CashFlowItem
		|						OR PaymentDecryptionTable.LoanDepositContract.CashFlowItemOfReceiptIssuie = PaymentDecryptionTable.CashFlowItem)
		|				THEN VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived)
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived)
		|					AND (PaymentDecryptionTable.LoanDepositContract.CashFlowItemOfInterestPayment = PaymentDecryptionTable.CashFlowItem
		|						OR PaymentDecryptionTable.LoanDepositContract.CashFlowItemOfFeePayment = PaymentDecryptionTable.CashFlowItem)
		|				THEN VALUE(Enum.BusinessTransactions.LoanInterestPayment)
		|			ELSE &BusinessOperation
		|		END AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		DocumentData.Department AS Department,
		|		DocumentData.BankAccountLineOfBusiness AS LineOfBusinessBankAccount,
		|		DocumentData.CashAccountLineOfBusiness AS FieldOfActivityCheckout,
		|		DocumentData.BankAccount AS BankAccount,
		|		DocumentData.CashAccount AS CashAccount,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|		PaymentDecryptionTable.LoanDepositContract.LineOfBusiness AS CounterpartyLineOfBusiness,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS Partner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|		PaymentDecryptionTable.LoanDepositContract AS Contract,
		|		UNDEFINED AS ARAPObject,
		|		ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount) AS AmountToBePaid,
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.LoanDepositContract AS SourceOfARAPFinancialAccountingGroup,
		|		DocumentData.OverLimits AS OverLimits
		|
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|			LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON (TRUE)
		|";
	
		QueryTextArray.Add(SubqueryText);
		
	EndIf;
	
	If QueryTextArray.Count() = 0 Then
		Return "";
	EndIf;
	
	SubqueryText = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	CASE
	|		WHEN DocumentData.Status = VALUE(Enum.StatusesOfPaymentRequests.NotAgreedUpon)
	|			THEN CASE
	|					WHEN DocumentData.PaymentMethodCash
	|						THEN DocumentData.FieldOfActivityCheckout
	|					ELSE DocumentData.LineOfBusinessBankAccount
	|				END
	|		ELSE CASE
	|				WHEN DocumentData.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
	|					THEN DocumentData.FieldOfActivityCheckout
	|				ELSE DocumentData.LineOfBusinessBankAccount
	|			END
	|	END AS LineOfBusinessCash,
	|	CASE
	|		WHEN DocumentData.Status = VALUE(Enum.StatusesOfPaymentRequests.NotAgreedUpon)
	|			THEN CASE
	|					WHEN DocumentData.PaymentMethodCash
	|						THEN DocumentData.CashAccount
	|					ELSE DocumentData.BankAccount
	|				END
	|		ELSE CASE
	|				WHEN DocumentData.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
	|					THEN DocumentData.CashAccount
	|				ELSE DocumentData.BankAccount
	|			END
	|	END AS Cash,
	|	CASE
	|		WHEN DocumentData.Status = VALUE(Enum.StatusesOfPaymentRequests.NotAgreedUpon)
	|			THEN CASE
	|					WHEN DocumentData.PaymentMethodCash
	|						THEN VALUE(Enum.CashTypes.CashPayment)
	|					ELSE VALUE(Enum.CashTypes.BankAccountPayments_)
	|				END
	|		ELSE CASE
	|				WHEN DocumentData.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
	|					THEN VALUE(Enum.CashTypes.CashPayment)
	|				ELSE VALUE(Enum.CashTypes.BankAccountPayments_)
	|			END
	|	END AS CashType,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.TargetFundItem AS TargetFundItem,
	|	DocumentData.PaymentCurrency AS PaymentCurrency,
	|	CASE 
	|		WHEN ISNULL(DocumentData.CounterpartyLineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.CounterpartyLineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	CASE
	|		WHEN DocumentData.OverLimits = FALSE
	|			THEN SUM(DocumentData.AmountToBePaid)
	|	END AS AmountToBePaidWithinLimit,
	|	CASE
	|		WHEN DocumentData.OverLimits = TRUE
	|			THEN SUM(DocumentData.AmountToBePaid)
	|	END AS AmountToBePaidAboveLimit,
	|	DocumentData.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	&Ref AS PaymentRequest
	|
	|FROM
	|	&SubqueryTable AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Period,
	|	DocumentData.Status,
	|	DocumentData.BusinessOperation,
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.LineOfBusinessBankAccount,
	|	DocumentData.FieldOfActivityCheckout,
	|	DocumentData.BankAccount,
	|	DocumentData.CashAccount,
	|	DocumentData.CashFlowItem,
	|	DocumentData.TargetFundItem,
	|	DocumentData.PaymentCurrency,
	|	CASE 
	|		WHEN ISNULL(DocumentData.CounterpartyLineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.CounterpartyLineOfBusiness
	|	END,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	DocumentData.Contract,
	|	DocumentData.ARAPObject,
	|	DocumentData.SourceOfCashFinancialAccountingGroup,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.OverLimits,
	|	DocumentData.PaymentMethodCash,
	|	DocumentData.PaymentMethodOfPaymentRequest
	|";
	
	QueryText = StrReplace(QueryText, "&SubqueryTable", "(" + SubqueryText +")");

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency") Then
		Return;
	EndIf;
	
	ConversionRateToManCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		Query.Parameters.Currency, Constants.ManagementAccountingCurrency.Get(), Query.Parameters.Period);
	
	Query.SetParameter("ConversionRateToManCurrency", ConversionRateToManCurrency);
	
EndProcedure

Procedure SetParameterForPartnerAccountingAnalyticsRequest(Query, DocumentObject)
	
	If Query.Parameters.Property("AccountingDimensionByPartners") Then
		Return;
	EndIf;
	
	If Query.TempTablesManager = Undefined Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	InitializeTrackingAnalyticsKeysForPartners(Query.Parameters, Query.Parameters.Ref, Query.TempTablesManager, DocumentObject);
	
	If Query.Parameters.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee Then
		
		StructureOfAnalytics = New Structure;
		StructureOfAnalytics.Insert("Organization", Query.Parameters.Organization);
		StructureOfAnalytics.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
		StructureOfAnalytics.Insert("Partner", Catalogs.Partners.EmptyRef());
		StructureOfAnalytics.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
		StructureOfAnalytics.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
		
		AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureOfAnalytics);
		
		Query.SetParameter("AccountingDimensionByPartners", AccountingDimensionByPartners);
	Else
		
		Query.SetParameter("AccountingDimensionByPartners", Undefined);
	EndIf;
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	ArrayOfRequestTexts = New Array; 
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.EmptyRef()) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	&PartnerFromDocument                     AS Partner,
		|	&BankAccount                         AS StorageLocation,
		|	&CounterpartyFromDocument                  AS Counterparty,
		|	&Department                          AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&WhoStated                              AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	FALSE                                    AS ReverseTransactionCorrection,
		|	UNDEFINED                            AS ReversedDocument,
		|	UNDEFINED                            AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	&PaymentPriority                        AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
		|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
		|		VALUE(Enum.BusinessTransactions.OtherCashIssue),
		|		VALUE(Enum.BusinessTransactions.CustomsPayment),
		|		VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions),
		|		VALUE(Enum.BusinessTransactions.CurrencyConversion),
		|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
		|		VALUE(Enum.BusinessTransactions.TransferToDeposits),
		|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty),
		|		VALUE(Enum.BusinessTransactions.PaymentToLessor),
		|		VALUE(Enum.BusinessTransactions.EmptyRef)
		|	)";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	&Partner                                AS Partner,
		|	&BankAccount                         AS StorageLocation,
		|	CASE
		|		WHEN &TransferToEmployeeViaABank
		|			THEN &CounterpartyFromDocument
		|		ELSE &AdvanceHolder
		|	END                                   AS Counterparty,
		|	&Department                          AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&WhoStated                              AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	FALSE                                    AS ReverseTransactionCorrection,
		|	UNDEFINED                            AS ReversedDocument,
		|	UNDEFINED                            AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	&PaymentPriority                        AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
		|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee)
		|	)";

		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	&Partner                                AS Partner,
		|	&BankAccount                         AS StorageLocation,
		|	DocumentData.BankAccountBeneficiary.Owner AS Counterparty,
		|	&Department                          AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&WhoStated                              AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	FALSE                                    AS ReverseTransactionCorrection,
		|	UNDEFINED                            AS ReversedDocument,
		|	UNDEFINED                            AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	&PaymentPriority                        AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
		|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
		|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
		|	)";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashToAnotherAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	UNDEFINED                            AS Partner,
		|	&BankAccount                         AS StorageLocation,
		|	UNDEFINED                            AS Counterparty,
		|	&Department                          AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&WhoStated                              AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	UNDEFINED                            AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	FALSE                                    AS ReverseTransactionCorrection,
		|	UNDEFINED                            AS ReversedDocument,
		|	UNDEFINED                            AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	&PaymentPriority                        AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount),
		|		VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount)
		|	)";
	
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	&Partner                                AS Partner,
		|	&BankAccount                         AS StorageLocation,
		|	&Counterparty                             AS Counterparty,
		|	&Department                          AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&WhoStated                              AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	DocumentData.AcquiringContract       AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	FALSE                                    AS ReverseTransactionCorrection,
		|	UNDEFINED                            AS ReversedDocument,
		|	UNDEFINED                            AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	&PaymentPriority                        AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|	)
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined
		Or DocumentObject.PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram
		Or DocumentObject.PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentToBankAccounts Then
		
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&PayrollTransaction        AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	&PartnerFromDocument                     AS Partner,
		|	&BankAccount                         AS StorageLocation,
		|	CASE
		|		WHEN &PayrollTransaction = VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram)
		|			THEN &CounterpartyFromDocument
		|		WHEN &PayrollTransaction = VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)
		|				AND &TransferToEmployeeViaABank
		|			THEN &CounterpartyFromDocument
		|		ELSE &AdvanceHolder
		|	END                                   AS Counterparty,
		|	&Department                          AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&WhoStated                              AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	FALSE                                    AS ReverseTransactionCorrection,
		|	UNDEFINED                            AS ReversedDocument,
		|	UNDEFINED                            AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	&PaymentPriority                        AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &PayrollTransaction IN (
		|		VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram),
		|		VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)
		|	)";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject <> Undefined And ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.PaymentRequest");
	EndIf;
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	#Region LinesOfBusiness
	
	RegisterName = "TemporaryTableOfLinesOfBusiness";
	
	QueryTextLinesOfBusiness = 
		"SELECT
		|	Table.ARAPObject AS ARAPObject
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table";
		
	QueryTextLinesOfBusiness = ARAPAccountingPosting.GetTableOfLinesOfBusiness(QueryTextLinesOfBusiness);

	QueryTexts.Add(QueryTextLinesOfBusiness, RegisterName);
	
	#EndRegion
	
	#Region CustomersARAPAccounting
	
	QueryTextCustomers = "";
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany) 
		And (DocumentObject.Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon
			Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AgreedUpon
			Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AmountDue) 
		And DocumentObject.ControlPaymentByARAPObjects Then
		
		QueryTextCustomers = "
			|SELECT
			|	Table.Ref                                                AS Ref,
			|	CASE WHEN DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
			|			THEN VALUE(Catalog.Partners.OurEnterprise)
			|		WHEN &ThereIsGiftCertificate = TRUE
			|			THEN &Partner
			|		ELSE Table.Partner
			|	END AS Partner,
			|	Table.ARAPObject                                        AS ARAPObject,
			|	Table.ARAPCurrency                                  AS ARAPCurrency,
			|	Table.AmountARAP                                   AS BeingPaid,
			|	Table.CashFlowItem                         AS CashFlowItem,
			|	
			|	DocumentDataHeader.Number                                    AS RecorderNumber,
			|	DocumentDataHeader.Date                                     AS RecorderDate,
			|	DocumentDataHeader.BusinessOperation                    AS BusinessOperation,
			|	DocumentDataHeader.PaymentMethodOfPaymentRequest                        AS PaymentMethod,
			|	DocumentDataHeader.Currency                                   AS DocumentCurrency
			|FROM
			|	DocumentDataTableDecryptionOfPayment AS Table
			|	LEFT JOIN DocumentDataHeader
			|		ON Table.Ref = DocumentDataHeader.Ref
			|";
	EndIf;
	
	ARAPAccountingPostingCustomers.ConductingRequestForRefundToClient(Query, QueryTexts, Registers, QueryTextCustomers);
	
	#EndRegion
	
	#Region VendorsARAPAccounting
	
	QueryTextVendors = "";
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment) 
		And (DocumentObject.Status = Enums.StatusesOfPaymentRequests.NotAgreedUpon
			Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AgreedUpon
			Or DocumentObject.Status = Enums.StatusesOfPaymentRequests.AmountDue)
		And DocumentObject.ControlPaymentByARAPObjects Then
				
	QueryTextVendors = "
		|SELECT
		|	Table.Ref                                                 AS Ref,
		|	CASE WHEN DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
		|			THEN VALUE(Catalog.Partners.OurEnterprise)
		|		WHEN &ThereIsGiftCertificate = TRUE
		|			THEN &Partner
		|		ELSE Table.Partner
		|	END AS Partner,
		|	
		|	Table.ARAPCurrency                                   AS ARAPCurrency,
		|	Table.AmountARAP                                    AS IncreaseIsPaid,
		|	Table.ARAPObject                                         AS ARAPObject,
		|	Table.CashFlowItem                          AS CashFlowItem,
		|	
		|	DocumentDataHeader.Number                                     AS RecorderNumber,
		|	DocumentDataHeader.Date                                      AS RecorderDate,
		|	DocumentDataHeader.BusinessOperation                     AS BusinessOperation,
		|	DocumentDataHeader.PaymentMethodOfPaymentRequest                         AS PaymentMethod,
		|	DocumentDataHeader.Currency                                    AS DocumentCurrency
		|	
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|	LEFT JOIN DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|";
	EndIf;
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ExecutionOfRequestForPaymentToSupplier(Query, QueryTexts, Registers, QueryTextVendors);
	
	#EndRegion
	
EndProcedure

Function ClosingRequestCashForPayment()
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	&Period                                             AS Period,
	|	RegisterData.PaymentRequest  AS PaymentRequest,
	|	RegisterData.BankAccountCashAccount                  AS BankAccountCashAccount,
	|	RegisterData.Recipient                           AS Recipient,
	|	RegisterData.Organization                          AS Organization,
	|	-RegisterData.SumBalance                        AS Sum,
	|	TRUE                                              AS ReversingEntry
	|FROM
	|	AccumulationRegister.CashToBePaid.Balance(, PaymentRequest IN (&Request)) AS RegisterData
	|";
	
	Return QueryText;
	
EndFunction

Function RequestForClosingSettlementsWithSuppliers()
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	&Period                                             AS Period,
	|	RegisterData.AccountingDimensionByPartners            AS AccountingDimensionByPartners,
	|	RegisterData.ARAPObject                       AS ARAPObject,
	|	RegisterData.Currency                               AS Currency,
	|	SUM(CASE RegisterData.RecordType
	|		WHEN VALUE(AccumulationRecordType.Expense) THEN
	|			-RegisterData.BeingPaid
	|		WHEN VALUE(AccumulationRecordType.Receipt) THEN
	|			RegisterData.BeingPaid
	|	END) AS BeingPaid,
	|	RegisterData.PaymentRequest  AS PaymentRequest,
	|	TRUE                                              AS ReversingEntry
	|	
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS RegisterData
	|WHERE
	|	RegisterData.PaymentRequest IN (&Request)
	|GROUP BY
	|	RegisterData.AccountingDimensionByPartners,
	|	RegisterData.ARAPObject,
	|	RegisterData.Currency,
	|	RegisterData.PaymentRequest
	|HAVING
	|	SUM(CASE RegisterData.RecordType
	|		WHEN VALUE(AccumulationRecordType.Expense) THEN
	|			-RegisterData.BeingPaid
	|		WHEN VALUE(AccumulationRecordType.Receipt) THEN
	|			RegisterData.BeingPaid
	|	END) <> 0
	|";
	
	Return QueryText;
	
EndFunction

Function RequestForClosingSettlementsWithCustomers()
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	&Period                                             AS Period,
	|	RegisterData.AccountingDimensionByPartners            AS AccountingDimensionByPartners,
	|	RegisterData.ARAPObject                       AS ARAPObject,
	|	RegisterData.Currency                               AS Currency,
	|	SUM(CASE RegisterData.RecordType
	|		WHEN VALUE(AccumulationRecordType.Expense) THEN
	|			-RegisterData.BeingPaid
	|		WHEN VALUE(AccumulationRecordType.Receipt) THEN
	|			RegisterData.BeingPaid
	|	END) AS BeingPaid,
	|	RegisterData.PaymentRequest  AS PaymentRequest,
	|	TRUE                                              AS ReversingEntry
	|	
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS RegisterData
	|WHERE
	|	RegisterData.PaymentRequest IN (&Request)
	|GROUP BY
	|	RegisterData.AccountingDimensionByPartners,
	|	RegisterData.ARAPObject,
	|	RegisterData.Currency,
	|	RegisterData.PaymentRequest
	|HAVING
	|	SUM(CASE RegisterData.RecordType
	|		WHEN VALUE(AccumulationRecordType.Expense) THEN
	|			-RegisterData.BeingPaid
	|		WHEN VALUE(AccumulationRecordType.Receipt) THEN
	|			RegisterData.BeingPaid
	|	END) <> 0
	|";
	
	Return QueryText;
	
EndFunction

Function RequestToCloseSettlementsOnFinancialInstruments()
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	&Period                                             AS Period,
	|	RegisterData.AccountingDimensionByPartners            AS AccountingDimensionByPartners,
	|	RegisterData.Contract                              AS Contract,
	|	RegisterData.AmountType                             AS AmountType,
	|	RegisterData.ARAPDocument                    AS ARAPDocument,
	|	RegisterData.Currency                               AS Currency,
	|	SUM(CASE RegisterData.RecordType
	|		WHEN VALUE(AccumulationRecordType.Expense) THEN
	|			-RegisterData.BeingPaid
	|		WHEN VALUE(AccumulationRecordType.Receipt) THEN
	|			RegisterData.BeingPaid
	|	END) AS BeingPaid,
	|	RegisterData.PaymentRequest  AS PaymentRequest,
	|	TRUE                                              AS ReversingEntry
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS RegisterData
	|WHERE
	|	RegisterData.PaymentRequest IN (&Request)
	|GROUP BY
	|	RegisterData.AccountingDimensionByPartners,
	|	RegisterData.Contract,
	|	RegisterData.AmountType,
	|	RegisterData.ARAPDocument,
	|	RegisterData.Currency,
	|	RegisterData.PaymentRequest
	|HAVING
	|	SUM(CASE RegisterData.RecordType
	|		WHEN VALUE(AccumulationRecordType.Expense) THEN
	|			-RegisterData.BeingPaid
	|		WHEN VALUE(AccumulationRecordType.Receipt) THEN
	|			RegisterData.BeingPaid
	|	END) <> 0
	|";
	
	Return QueryText;
	
EndFunction

Function CashFlowClosureRequest()
	
	QueryText = "
	|SELECT
	|	&Period                                             AS Period,
	|	MIN(RegisterData.Period)                      AS PeriodInitial,
	|	RegisterData.BusinessOperation                AS BusinessOperation,
	|	RegisterData.Organization                          AS Organization,
	|	RegisterData.Department                        AS Department,
	|	RegisterData.LineOfBusiness              AS LineOfBusiness,
	|	RegisterData.CashFlowItem        AS CashFlowItem,
	|	RegisterData.Currency                               AS Currency,
	|	RegisterData.CorCash                  AS CorCash,
	|	RegisterData.CorCashType                AS CorCashType,
	|	RegisterData.CorLineOfBusiness           AS CorLineOfBusiness,
	|	SUM(RegisterData.AmountInCurrency)
	|	 - SUM(RegisterData.AmountToBePaidWithinLimit) AS AmountToBePaidWithinLimit,
	|	0                                                   AS AmountToBePaidAboveLimit,
	|	RegisterData.PaymentRequest  AS PaymentRequest,
	|	TRUE                                              AS ReversingEntry
	|FROM
	|	AccumulationRegister.CashFlow AS RegisterData
	|WHERE
	|	RegisterData.PaymentRequest IN (&Request)
	|GROUP BY
	|	RegisterData.BusinessOperation,
	|	RegisterData.Organization,
	|	RegisterData.Department,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.CashFlowItem,
	|	RegisterData.Currency,
	|	RegisterData.CorCash,
	|	RegisterData.CorCashType,
	|	RegisterData.CorLineOfBusiness,
	|	RegisterData.PaymentRequest
	|HAVING
	|	SUM(RegisterData.AmountInCurrency) - SUM(RegisterData.AmountToBePaidWithinLimit) < 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                             AS Period,
	|	MIN(RegisterData.Period)                      AS PeriodInitial,
	|	RegisterData.BusinessOperation                AS BusinessOperation,
	|	RegisterData.Organization                          AS Organization,
	|	RegisterData.Department                        AS Department,
	|	RegisterData.LineOfBusiness              AS LineOfBusiness,
	|	RegisterData.CashFlowItem        AS CashFlowItem,
	|	RegisterData.Currency                               AS Currency,
	|	RegisterData.CorCash                  AS CorCash,
	|	RegisterData.CorCashType                AS CorCashType,
	|	RegisterData.CorLineOfBusiness           AS CorLineOfBusiness,
	|	0                                                   AS AmountToBePaidWithinLimit,
	|	SUM(RegisterData.AmountInCurrency)
	|	 - SUM(RegisterData.AmountToBePaidAboveLimit)   AS AmountToBePaidAboveLimit,
	|	RegisterData.PaymentRequest  AS PaymentRequest,
	|	TRUE                                              AS ReversingEntry
	|FROM
	|	AccumulationRegister.CashFlow AS RegisterData
	|WHERE
	|	RegisterData.PaymentRequest IN (&Request)
	|GROUP BY
	|	RegisterData.BusinessOperation,
	|	RegisterData.Organization,
	|	RegisterData.Department,
	|	RegisterData.LineOfBusiness,
	|	RegisterData.CashFlowItem,
	|	RegisterData.Currency,
	|	RegisterData.CorCash,
	|	RegisterData.CorCashType,
	|	RegisterData.CorLineOfBusiness,
	|	RegisterData.PaymentRequest
	|HAVING
	|	SUM(RegisterData.AmountInCurrency) - SUM(RegisterData.AmountToBePaidAboveLimit) < 0
	|";
	
	Return QueryText;
	
EndFunction

Function RequestClosureCashFlowIncomeExpenses()
	
	QueryText = "
	|SELECT
	|	&Period                                             AS Period,
	|	MIN(RegisterData.Period)                      AS PeriodInitial,
	|	RegisterData.BusinessOperation                AS BusinessOperation,
	|	RegisterData.Organization                          AS Organization,
	|	RegisterData.Department                        AS Department,
	|	RegisterData.LineOfBusinessCash            AS LineOfBusinessCash,
	|	RegisterData.IncomeExpenseBusinessUnit         AS IncomeExpenseBusinessUnit,
	|	RegisterData.CashFlowItem        AS CashFlowItem,
	|	RegisterData.Currency                               AS Currency,
	|	RegisterData.LineOfBusinessItems        AS LineOfBusinessItems,
	|	RegisterData.IncomeAndExpenseItem                AS IncomeAndExpenseItem,
	|	RegisterData.DimensionOfRevenue                     AS DimensionOfRevenue,
	|	RegisterData.DimensionOfExpenses                    AS DimensionOfExpenses,
	|	RegisterData.AssetsLiabilitiesDimension             AS AssetsLiabilitiesDimension,
	|	SUM(RegisterData.AmountInCurrency)
	|	 - SUM(RegisterData.AmountToBePaidWithinLimit) AS AmountToBePaidWithinLimit,
	|	0                                                   AS AmountToBePaidAboveLimit,
	|	RegisterData.PaymentRequest  AS PaymentRequest,
	|	TRUE                                              AS ReversingEntry
	|FROM
	|	AccumulationRegister.RecordsCashIncomeExpenses AS RegisterData
	|WHERE
	|	RegisterData.PaymentRequest IN (&Request)
	|GROUP BY
	|	RegisterData.BusinessOperation,
	|	RegisterData.Organization,
	|	RegisterData.Department,
	|	RegisterData.LineOfBusinessCash,
	|	RegisterData.IncomeExpenseBusinessUnit,
	|	RegisterData.CashFlowItem,
	|	RegisterData.Currency,
	|	RegisterData.LineOfBusinessItems,
	|	RegisterData.IncomeAndExpenseItem,
	|	RegisterData.DimensionOfRevenue,
	|	RegisterData.DimensionOfExpenses,
	|	RegisterData.AssetsLiabilitiesDimension,
	|	RegisterData.PaymentRequest
	|HAVING
	|	SUM(RegisterData.AmountInCurrency) - SUM(RegisterData.AmountToBePaidWithinLimit) < 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                             AS Period,
	|	MIN(RegisterData.Period)                      AS PeriodInitial,
	|	RegisterData.BusinessOperation                AS BusinessOperation,
	|	RegisterData.Organization                          AS Organization,
	|	RegisterData.Department                        AS Department,
	|	RegisterData.LineOfBusinessCash            AS LineOfBusinessCash,
	|	RegisterData.IncomeExpenseBusinessUnit         AS IncomeExpenseBusinessUnit,
	|	RegisterData.CashFlowItem        AS CashFlowItem,
	|	RegisterData.Currency                               AS Currency,
	|	RegisterData.LineOfBusinessItems        AS LineOfBusinessItems,
	|	RegisterData.IncomeAndExpenseItem                AS IncomeAndExpenseItem,
	|	RegisterData.DimensionOfRevenue                     AS DimensionOfRevenue,
	|	RegisterData.DimensionOfExpenses                    AS DimensionOfExpenses,
	|	RegisterData.AssetsLiabilitiesDimension             AS AssetsLiabilitiesDimension,
	|	0                                                   AS AmountToBePaidWithinLimit,
	|	SUM(RegisterData.AmountInCurrency) - SUM(RegisterData.AmountToBePaidAboveLimit) AS AmountToBePaidAboveLimit,
	|	RegisterData.PaymentRequest  AS PaymentRequest,
	|	TRUE                                              AS ReversingEntry
	|FROM
	|	AccumulationRegister.RecordsCashIncomeExpenses AS RegisterData
	|WHERE
	|	RegisterData.PaymentRequest IN (&Request)
	|GROUP BY
	|	RegisterData.BusinessOperation,
	|	RegisterData.Organization,
	|	RegisterData.Department,
	|	RegisterData.LineOfBusinessCash,
	|	RegisterData.IncomeExpenseBusinessUnit,
	|	RegisterData.CashFlowItem,
	|	RegisterData.Currency,
	|	RegisterData.LineOfBusinessItems,
	|	RegisterData.IncomeAndExpenseItem,
	|	RegisterData.DimensionOfRevenue,
	|	RegisterData.DimensionOfExpenses,
	|	RegisterData.AssetsLiabilitiesDimension,
	|	RegisterData.PaymentRequest
	|HAVING
	|	SUM(RegisterData.AmountInCurrency) - SUM(RegisterData.AmountToBePaidAboveLimit) < 0
	|";
	
	Return QueryText;
	
EndFunction

Function RequestToCloseCashFlowCounterparty()
	
	QueryText = "
	|SELECT
	|	&Period                                             AS Period,
	|	MIN(RegisterData.Period)                      AS PeriodInitial,
	|	RegisterData.BusinessOperation                AS BusinessOperation,
	|	RegisterData.Organization                          AS Organization,
	|	RegisterData.Department                        AS Department,
	|	RegisterData.LineOfBusinessCash            AS LineOfBusinessCash,
	|	RegisterData.CashFlowItem        AS CashFlowItem,
	|	RegisterData.PaymentCurrency                        AS PaymentCurrency,
	|	RegisterData.CounterpartyLineOfBusiness   AS CounterpartyLineOfBusiness,
	|	RegisterData.Partner                              AS Partner,
	|	RegisterData.Counterparty                           AS Counterparty,
	|	RegisterData.Contract                              AS Contract,
	|	RegisterData.ARAPObject                       AS ARAPObject,
	|	SUM(RegisterData.PaymentAmountPaymentCurrency)
	|	 - SUM(RegisterData.AmountToBePaidWithinLimit) AS AmountToBePaidWithinLimit,
	|	0                                                   AS AmountToBePaidAboveLimit,
	|	RegisterData.PaymentRequest  AS PaymentRequest,
	|	TRUE                                              AS ReversingEntry
	|FROM
	|	AccumulationRegister.RecordsCashCounterparty AS RegisterData
	|WHERE
	|	RegisterData.PaymentRequest IN (&Request)
	|GROUP BY
	|	RegisterData.BusinessOperation,
	|	RegisterData.Organization,
	|	RegisterData.Department,
	|	RegisterData.LineOfBusinessCash,
	|	RegisterData.CashFlowItem,
	|	RegisterData.PaymentCurrency,
	|	RegisterData.PaymentRequest,
	|	RegisterData.CounterpartyLineOfBusiness,
	|	RegisterData.Partner,
	|	RegisterData.Counterparty,
	|	RegisterData.Contract,
	|	RegisterData.ARAPObject
	|HAVING
	|	SUM(RegisterData.PaymentAmountPaymentCurrency) - SUM(RegisterData.AmountToBePaidWithinLimit) < 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                             AS Period,
	|	MIN(RegisterData.Period)                      AS PeriodInitial,
	|	RegisterData.BusinessOperation                AS BusinessOperation,
	|	RegisterData.Organization                          AS Organization,
	|	RegisterData.Department                        AS Department,
	|	RegisterData.LineOfBusinessCash            AS LineOfBusinessCash,
	|	RegisterData.CashFlowItem        AS CashFlowItem,
	|	RegisterData.PaymentCurrency                        AS PaymentCurrency,
	|	RegisterData.CounterpartyLineOfBusiness   AS CounterpartyLineOfBusiness,
	|	RegisterData.Partner                              AS Partner,
	|	RegisterData.Counterparty                           AS Counterparty,
	|	RegisterData.Contract                              AS Contract,
	|	RegisterData.ARAPObject                       AS ARAPObject,
	|	0                                                   AS AmountToBePaidWithinLimit,
	|	SUM(RegisterData.PaymentAmountPaymentCurrency)
	|	 - SUM(RegisterData.AmountToBePaidAboveLimit)   AS AmountToBePaidAboveLimit,
	|	RegisterData.PaymentRequest  AS PaymentRequest,
	|	TRUE                                              AS ReversingEntry
	|FROM
	|	AccumulationRegister.RecordsCashCounterparty AS RegisterData
	|WHERE
	|	RegisterData.PaymentRequest IN (&Request)
	|GROUP BY
	|	RegisterData.BusinessOperation,
	|	RegisterData.Organization,
	|	RegisterData.Department,
	|	RegisterData.LineOfBusinessCash,
	|	RegisterData.CashFlowItem,
	|	RegisterData.PaymentCurrency,
	|	RegisterData.PaymentRequest,
	|	RegisterData.CounterpartyLineOfBusiness,
	|	RegisterData.Partner,
	|	RegisterData.Counterparty,
	|	RegisterData.Contract,
	|	RegisterData.ARAPObject
	|HAVING
	|	SUM(RegisterData.PaymentAmountPaymentCurrency) - SUM(RegisterData.AmountToBePaidAboveLimit) < 0
	|";
	
	Return QueryText;
	
EndFunction

Function RequestForClosingCashFlowLimits()
	
	QueryTexts = New ValueList;
	
	QueryText = "
	|SELECT
	|	CatalogCurrencies.Ref AS ARAPCurrency,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization
	|INTO PeriodsTable
	|FROM
	|	Document.PaymentRequest AS DocumentData,
	|	Catalog.Currencies AS CatalogCurrencies
	|WHERE
	|	DocumentData.Ref IN (&Request)
	|GROUP BY
	|	CatalogCurrencies.Ref,
	|	DocumentData.Date,
	|	DocumentData.Organization
	|	
	|UNION ALL
	|	
	|SELECT
	|	CatalogCurrencies.Ref AS ARAPCurrency,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization
	|FROM
	|	Document.ApplicationForBusinessTrip AS DocumentData,
	|	Catalog.Currencies AS CatalogCurrencies
	|WHERE
	|	DocumentData.Ref IN (&Request)
	|GROUP BY
	|	CatalogCurrencies.Ref,
	|	DocumentData.Date,
	|	DocumentData.Organization
	|INDEX BY
	|	ARAPCurrency,
	|	Date,
	|	Organization
	|";

	QueryTexts.Add(QueryText, "PeriodsTable");
	
	FinancialInstruments.QueryTextTTCurrencyConversionFactors(QueryTexts, "TTCurrencyConversionFactors", True);
	
	QueryTextArray = New Array;
	For Each QueryText In QueryTexts Do
		If ValueIsFilled(QueryText.Presentation) Then
			QueryTextArray.Add("// " + QueryText.Presentation);
		EndIf; 
		QueryTextArray.Add(QueryText.Value + Common.QueryBatchSeparator());
	EndDo;
	QueryText = StrConcat(QueryTextArray, Chars.LF);
	
	QueryText = QueryText + "
	|SELECT
	|	BEGINOFPERIOD(MovementData.PeriodInitial, MONTH) AS Period,
	|	MovementData.CashFlowItem   AS CashFlowItem,
	|	CASE
	|		WHEN &UseExpenseLimitsForOrganizations
	|			THEN MovementData.Organization
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END AS Organization,
	|	CASE
	|		WHEN &UseExpenseLimitsByDivision
	|			THEN MovementData.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	MovementData.AmountToBePaidWithinLimit * ConversionRatesToCurrencyOfAccountingMan.ManConversionFactor AS ConsumptionWithinLimit,
	|	MovementData.AmountToBePaidAboveLimit * ConversionRatesToCurrencyOfAccountingMan.ManConversionFactor AS ExcessExpense,
	|	MovementData.PaymentRequest      AS PaymentRequest,
	|	TRUE                                                  AS ReversingEntry
	|FROM
	|	&CashFlowClosureRequest AS MovementData
	|	LEFT JOIN
	|		TTCurrencyConversionFactors AS ConversionRatesToCurrencyOfAccountingMan
	|	ON
	|		ConversionRatesToCurrencyOfAccountingMan.ARAPCurrency = MovementData.Currency
	|		AND ConversionRatesToCurrencyOfAccountingMan.Date = MovementData.PaymentRequest.DATE
	|		AND ConversionRatesToCurrencyOfAccountingMan.Organization = MovementData.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(MovementData.PeriodInitial, MONTH) AS Period,
	|	MovementData.CashFlowItem   AS CashFlowItem,
	|	CASE
	|		WHEN &UseExpenseLimitsForOrganizations
	|			THEN MovementData.Organization
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END AS Organization,
	|	CASE
	|		WHEN &UseExpenseLimitsByDivision
	|			THEN MovementData.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	MovementData.AmountToBePaidWithinLimit * ConversionRatesToCurrencyOfAccountingMan.ManConversionFactor AS ConsumptionWithinLimit,
	|	MovementData.AmountToBePaidAboveLimit * ConversionRatesToCurrencyOfAccountingMan.ManConversionFactor AS ExcessExpense,
	|	MovementData.PaymentRequest      AS PaymentRequest,
	|	TRUE                                                  AS ReversingEntry
	|FROM
	|	&RequestClosureCashFlowIncomeExpenses AS MovementData
	|	LEFT JOIN
	|		TTCurrencyConversionFactors AS ConversionRatesToCurrencyOfAccountingMan
	|	ON
	|		ConversionRatesToCurrencyOfAccountingMan.ARAPCurrency = MovementData.Currency
	|		AND ConversionRatesToCurrencyOfAccountingMan.Date = MovementData.PaymentRequest.DATE
	|		AND ConversionRatesToCurrencyOfAccountingMan.Organization = MovementData.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(MovementData.PeriodInitial, MONTH) AS Period,
	|	MovementData.CashFlowItem   AS CashFlowItem,
	|	CASE
	|		WHEN &UseExpenseLimitsForOrganizations
	|			THEN MovementData.Organization
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END AS Organization,
	|	CASE
	|		WHEN &UseExpenseLimitsByDivision
	|			THEN MovementData.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	MovementData.AmountToBePaidWithinLimit * ConversionRatesToCurrencyOfAccountingMan.ManConversionFactor AS ConsumptionWithinLimit,
	|	MovementData.AmountToBePaidAboveLimit * ConversionRatesToCurrencyOfAccountingMan.ManConversionFactor AS ExcessExpense,
	|	MovementData.PaymentRequest      AS PaymentRequest,
	|	TRUE                                                  AS ReversingEntry
	|FROM
	|	&RequestToCloseCashFlowCounterparty AS MovementData
	|	LEFT JOIN
	|		TTCurrencyConversionFactors AS ConversionRatesToCurrencyOfAccountingMan
	|	ON
	|		ConversionRatesToCurrencyOfAccountingMan.ARAPCurrency = MovementData.PaymentCurrency
	|		AND ConversionRatesToCurrencyOfAccountingMan.Date = MovementData.PaymentRequest.DATE
	|		AND ConversionRatesToCurrencyOfAccountingMan.Organization = MovementData.Organization
	|";
	
	QueryText = StrReplace(QueryText,
		"&CashFlowClosureRequest", "(" + CashFlowClosureRequest() + ")");
	QueryText = StrReplace(QueryText,
		"&RequestClosureCashFlowIncomeExpenses", "(" + RequestClosureCashFlowIncomeExpenses() + ")");
	QueryText = StrReplace(QueryText,
		"&RequestToCloseCashFlowCounterparty", "(" + RequestToCloseCashFlowCounterparty() + ")");
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfPaymentRequests[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.PaymentRequest AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks for the document "Application for the use of monetary funds"
	
EndFunction

Function CashFlowArticleOfDocument(DocumentData)
	
	If ValueIsFilled(DocumentData.CashFlowItem) Then
		CashFlowItem = DocumentData.CashFlowItem;
	Else
		CashFlowItem = Catalogs.CashFlowReportItems.PredefinedCFItem(
			DocumentData.BusinessOperation, DocumentData.Currency);
	EndIf;
	
	Return CashFlowItem;
	
EndFunction

// Settlement of operations.
// 
// Returns:
//  Array of EnumRef.BusinessTransactions - Settlement Operations
Function SettlementOperations() Export
	SettlementOperations = New Array;
	SettlementOperations.Add(Enums.BusinessTransactions.PaymentToVendor);
	SettlementOperations.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
	SettlementOperations.Add(Enums.BusinessTransactions.CustomsPayment);
	SettlementOperations.Add(Enums.BusinessTransactions.RefundToCustomer);
	SettlementOperations.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
	
	Return SettlementOperations;
EndFunction

// Calculates the value for filling in the Attribute "Control payment objectsaccounts". The value depends on the value 
// of the "Business Operation" Attribute and the filling in of the "Account Object" Attribute in the lines of the "Payment Decryption" tabular part. 
// 
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//  ARAPObjects - Array of CatalogRef.ARAPObjects - Array of calculation objects from the tabular part "Payment decryption". 
// 
// Returns:
//  Boolean - The value for filling in the Attribute "Control payment objectsaccounts".
//
Function ControlPaymentByARAPObjects(BusinessOperation, ARAPObjects) Export

	ControlPaymentByARAPObjects = False;
	SettlementOperations = SettlementOperations();

	If SettlementOperations.Find(BusinessOperation) = Undefined Then
		Return ControlPaymentByARAPObjects;
	EndIf;

	ControlPaymentByARAPObjects = True;

	For Each ARAPObject In ARAPObjects Do
		If Not ValueIsFilled(ARAPObject) Then
			ControlPaymentByARAPObjects = False;
			Break;
		EndIf;
	EndDo;

	Return ControlPaymentByARAPObjects;

EndFunction

#EndRegion
#Region ControllingLimitsBasedOnBudgetingData

// Returns the Query Text for creating a temporary table with data sources for rules for getting actual data on budget items.
// Data sources depend on the business of operation of the document.
//
// Returns:
//  String - Query text
//
Function QueryTextDataSourcesOfRulesForObtainingFact() Export
	
	QueryText = 
	"SELECT
	|	BusinessTransactionsSettings.Ref AS DataSource,
	|	BusinessTransactionsSettings.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettings.Receipt AS Receipt,
	|	BusinessTransactionsSettings.Expense AS Expense
	|INTO DataSourcesOfRulesForObtainingFact
	|FROM
	|	Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|WHERE
	|	CASE
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
	|				THEN BusinessTransactionsSettings.Expense = VALUE(Enum.AccountingDataTypes.Cash)
	|			ELSE BusinessTransactionsSettings.BusinessOperation IN (CASE
	|						WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard)
	|							THEN VALUE(Enum.BusinessTransactions.AcquiringFee)
	|					END, CASE
	|						WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived)
	|							THEN VALUE(Enum.BusinessTransactions.LoanInterestPayment)
	|					END, CASE
	|						WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|							THEN VALUE(Enum.BusinessTransactions.OtherExpenses)
	|					END, CASE
	|						WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|								AND &AccordingToCorrespondenceTable
	|							THEN VALUE(Enum.BusinessTransactions.PaymentForLeaseServices)
	|						ELSE &BusinessOperation
	|					END, CASE
	|						WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|								AND &AccordingToCorrespondenceTable
	|							THEN VALUE(Enum.BusinessTransactions.SecurityPayment)
	|						ELSE &BusinessOperation
	|					END, CASE
	|						WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|								AND &AccordingToCorrespondenceTable
	|							THEN VALUE(Enum.BusinessTransactions.LeaseBuyoutValuePayment)
	|						ELSE &BusinessOperation
	|					END, CASE
	|						WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|								AND &AccordingToCorrespondenceTable
	|							THEN VALUE(Enum.BusinessTransactions.LeaseBuyoutValuePrepayment)
	|						ELSE &BusinessOperation
	|					END)
	|		END
	|	AND BusinessTransactionsSettings.UseInBudgeting";
	
	Return QueryText;
	
EndFunction

// Returns the Query Text as the source of actual data for the document.
// The source of actual data depends on the types of accounting data of operation rules for obtaining actual data on budget items.
//
// Parameters:
//  Expense - EnumRef.AccountingDataTypes - Business expense of operation
//  Receipt - EnumRef.AccountingDataTypes - Business Receipt of operation
//  TempTableName - String - name of the temp table (if not specified, the temp table is not generated)
//
// Returns:
//  String - Query text
//
Function QueryTextFactSourceByTypeOfAccountingData(Expense, Receipt, TempTableName = "") Export
	
	QueryText = "";
	
	If Expense <> Enums.AccountingDataTypes.Cash Then
		Return QueryText;
	EndIf;
	
	If Receipt = Enums.AccountingDataTypes.Cash Then
		
		QueryText =
		"SELECT
		|	CASE
		|		WHEN DataTable.PaymentDate <> DATETIME(1, 1, 1)
		|			THEN DataTable.PaymentDate
		|		WHEN DataTable.RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN DataTable.RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(DataTable.Date, DAY)
		|	END AS Period,
		|	DataTable.Ref AS Recorder,
		|	DataTable.BusinessOperation AS DataSource,
		|	DataTable.Organization AS Organization,
		|	DataTable.Department AS Department,
		|	DataTable.Department AS PaymentDivision,
		|	UNDEFINED AS LineOfBusiness,
		|	CASE
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN DataTable.CashAccount
		|		ELSE DataTable.BankAccount
		|	END AS Cash,
		|	CASE
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN VALUE(Enum.CashTypes.CashPayment)
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.BankAccountPayment)
		|			OR DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.InstantPayments)
		|			THEN VALUE(Enum.CashTypes.BankAccountPayments_)
		|		ELSE CASE
		|			WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|				THEN VALUE(Enum.CashTypes.BankAccountPayments_)
		|			ELSE UNDEFINED
		|		END
		|	END AS CashType,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|			THEN ISNULL(TablePersonalAccountsOfEmployees.CashFlowItem, PaymentDecryptionTable.CashFlowItem)
		|		ELSE DataTable.CashFlowItem
		|	END AS CashFlowItem,
		|	DataTable.Currency AS Currency,
		|	UNDEFINED AS CorLineOfBusiness,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount)
		|				OR DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
		|			THEN DataTable.BankAccountBeneficiary
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount)
		|			THEN DataTable.CashAccountRecipient
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|			THEN ISNULL(TablePersonalAccountsOfEmployees.Individual, DataTable.AdvanceHolder)
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|			THEN DataTable.AcquiringContract
		|	END AS CorCash,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|			THEN VALUE(Enum.CashTypes.AdvanceHolderSCash)
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|			THEN VALUE(Enum.CashTypes.BankAcquirerCash)
		|		ELSE VALUE(Enum.CashTypes.CashInTransit)
		|	END AS CorCashType,
		|	DataTable.Currency AS CorrespondingCurency,
		|	CASE
		|		WHEN NOT DataTable.OverLimits
		|			THEN CASE
		|				WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) AND DataTable.PersonsList
		|					THEN TablePersonalAccountsOfEmployees.Sum
		|				ELSE ISNULL(PaymentDecryptionTable.Sum, DataTable.DocumentAmount)
		|			END
		|		ELSE 0
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DataTable.OverLimits
		|			THEN CASE
		|				WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) AND DataTable.PersonsList
		|					THEN TablePersonalAccountsOfEmployees.Sum
		|				ELSE ISNULL(PaymentDecryptionTable.Sum, DataTable.DocumentAmount)
		|			END
		|		ELSE 0
		|	END AS AmountToBePaidAboveLimit,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) AND DataTable.PersonsList
		|			THEN TablePersonalAccountsOfEmployees.Sum
		|		ELSE ISNULL(PaymentDecryptionTable.Sum, DataTable.DocumentAmount)
		|	END AS AmountToBePaid
		|INTO TempTableName
		|FROM
		|	Document.PaymentRequest AS DataTable
		|		LEFT JOIN Document.PaymentRequest.ARAPDetails AS PaymentDecryptionTable
		|		ON DataTable.Ref = PaymentDecryptionTable.Ref
		|		AND (NOT DataTable.PersonsList)
		|		LEFT JOIN Document.PaymentRequest.PersonalAccountsOfStaff AS TablePersonalAccountsOfEmployees
		|		ON DataTable.Ref = TablePersonalAccountsOfEmployees.Ref
		|		AND (DataTable.PersonsList)
		|WHERE
		|	NOT DataTable.Status = VALUE(Enum.StatusesOfPaymentRequests.IsRejected)
		|	AND DataTable.Ref = &Document
		|	AND CASE
		|			WHEN DataTable.PaymentDate <> DATETIME(1, 1, 1)
		|				THEN DataTable.PaymentDate
		|			WHEN DataTable.RequiredPaymentDate <> DATETIME(1, 1, 1)
		|				THEN DataTable.RequiredPaymentDate
		|			ELSE BEGINOFPERIOD(DataTable.Date, DAY)
		|		END BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|			WHERE
		|				DataTable.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|				AND BusinessTransactionsSettings.Receipt = VALUE(Enum.AccountingDataTypes.Cash)
		|				AND BusinessTransactionsSettings.Expense = VALUE(Enum.AccountingDataTypes.Cash))";
		
	ElsIf Receipt = Enums.AccountingDataTypes.IncomeExpenses Then
		
		QueryText =
		"SELECT
		|	CASE
		|		WHEN DataTable.PaymentDate <> DATETIME(1, 1, 1)
		|			THEN DataTable.PaymentDate
		|		WHEN DataTable.RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN DataTable.RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(DataTable.Date, DAY)
		|	END AS Period,
		|	DataTable.Ref AS Recorder,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|			THEN VALUE(Enum.BusinessTransactions.AcquiringFee)
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
		|			THEN VALUE(Enum.BusinessTransactions.OtherExpenses)
		|		ELSE DataTable.BusinessOperation
		|	END AS DataSource,
		|	DataTable.Organization AS Organization,
		|	DataTable.Department AS Department,
		|	DataTable.Department AS PaymentDivision,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|			THEN DataTable.AcquiringContract.LineOfBusiness
		|		ELSE UNDEFINED
		|	END AS LineOfBusinessCash,
		|	CASE
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN DataTable.CashAccount
		|		ELSE DataTable.BankAccount
		|	END AS Cash,
		|	CASE
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN VALUE(Enum.CashTypes.CashPayment)
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.BankAccountPayment)
		|			OR DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.InstantPayments)
		|			THEN VALUE(Enum.CashTypes.BankAccountPayments_)
		|		ELSE CASE
		|			WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|				THEN VALUE(Enum.CashTypes.BankAccountPayments_)
		|			ELSE UNDEFINED
		|		END
		|	END AS CashType,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|			THEN ISNULL(DataTable.AcquiringContract.CashFlowItemCommission, VALUE(Catalog.CashFlowReportItems.PaymentToVendor))
		|		ELSE ISNULL(PaymentDecryptionTable.CashFlowItem, DataTable.CashFlowItem)
		|	END AS CashFlowItem,
		|	DataTable.Currency AS Currency,
		|	ISNULL(PaymentDecryptionTable.Department, DataTable.Department) AS IncomeExpenseBusinessUnit,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusinessOfIncomeExpenses,
		|	PaymentDecryptionTable.ExpenseItem AS IncomeAndExpenseItem,
		|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS DimensionOfRevenue,
		|	CASE
		|		WHEN NOT DataTable.OverLimits
		|			THEN CASE
		|				WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|					THEN DataTable.FeeAmount
		|				ELSE ISNULL(PaymentDecryptionTable.Sum, DataTable.DocumentAmount)
		|			END
		|		ELSE 0
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DataTable.OverLimits
		|			THEN CASE
		|				WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|					THEN DataTable.FeeAmount
		|				ELSE ISNULL(PaymentDecryptionTable.Sum, DataTable.DocumentAmount)
		|			END
		|		ELSE 0
		|	END AS AmountToBePaidAboveLimit,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|			THEN DataTable.FeeAmount
		|		ELSE ISNULL(PaymentDecryptionTable.Sum, DataTable.DocumentAmount)
		|	END AS AmountToBePaid
		|INTO TempTableName
		|FROM
		|	Document.PaymentRequest AS DataTable
		|		LEFT JOIN Document.PaymentRequest.ARAPDetails AS PaymentDecryptionTable
		|		ON DataTable.Ref = PaymentDecryptionTable.Ref
		|WHERE
		|	NOT DataTable.Status = VALUE(Enum.StatusesOfPaymentRequests.IsRejected)
		|	AND DataTable.Ref = &Document
		|	AND CASE
		|			WHEN DataTable.PaymentDate <> DATETIME(1, 1, 1)
		|				THEN DataTable.PaymentDate
		|			WHEN DataTable.RequiredPaymentDate <> DATETIME(1, 1, 1)
		|				THEN DataTable.RequiredPaymentDate
		|			ELSE BEGINOFPERIOD(DataTable.Date, DAY)
		|		END BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND CASE
		|			WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|				THEN DataTable.FeeAmount <> 0
		|			WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
		|				THEN PaymentDecryptionTable.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
		|			ELSE TRUE IN
		|					(SELECT TOP 1
		|						TRUE
		|					FROM
		|						Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|					WHERE
		|						DataTable.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|						AND BusinessTransactionsSettings.Receipt = VALUE(Enum.AccountingDataTypes.IncomeExpenses)
		|						AND BusinessTransactionsSettings.Expense = VALUE(Enum.AccountingDataTypes.Cash))
		|		END";
		
	ElsIf Receipt = Enums.AccountingDataTypes.Counterparties Then
		
		QueryText =
		"SELECT
		|	CASE
		|		WHEN DataTable.PaymentDate <> DATETIME(1, 1, 1)
		|			THEN DataTable.PaymentDate
		|		WHEN DataTable.RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN DataTable.RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(DataTable.Date, DAY)
		|	END AS Period,
		|	DataTable.Ref AS Recorder,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
		|			THEN CASE
		|					WHEN PaymentDecryptionTable.TypeOfLeasePayment IN (VALUE(Enum.TypesOfLeasePayments.RentalService), VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment))
		|						THEN VALUE(Enum.BusinessTransactions.PaymentForLeaseServices)
		|					WHEN PaymentDecryptionTable.TypeOfLeasePayment = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
		|						THEN VALUE(Enum.BusinessTransactions.SecurityPayment)
		|					WHEN PaymentDecryptionTable.TypeOfLeasePayment = VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
		|						THEN VALUE(Enum.BusinessTransactions.LeaseBuyoutValuePayment)
		|					WHEN PaymentDecryptionTable.TypeOfLeasePayment = VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
		|						THEN VALUE(Enum.BusinessTransactions.LeaseBuyoutValuePrepayment)
		|					ELSE DataTable.BusinessOperation
		|				END
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived)
		|			THEN CASE
		|					WHEN PaymentDecryptionTable.LoanAndDepositAmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
		|						THEN VALUE(Enum.BusinessTransactions.LoanInterestPayment)
		|					ELSE DataTable.BusinessOperation
		|				END
		|		ELSE DataTable.BusinessOperation
		|	END AS DataSource,
		|	DataTable.Organization AS Organization,
		|	DataTable.Department AS Department,
		|	DataTable.Department AS PaymentDivision,
		|	CASE
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN DataTable.CashAccount.LineOfBusiness
		|		ELSE DataTable.BankAccount.LineOfBusiness
		|	END AS LineOfBusinessCash,
		|	CASE
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN DataTable.CashAccount
		|		ELSE DataTable.BankAccount
		|	END AS Cash,
		|	CASE
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN VALUE(Enum.CashTypes.CashPayment)
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.BankAccountPayment)
		|			OR DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.InstantPayments)
		|			THEN VALUE(Enum.CashTypes.BankAccountPayments_)
		|		ELSE CASE
		|			WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|				THEN VALUE(Enum.CashTypes.BankAccountPayments_)
		|			ELSE UNDEFINED
		|		END
		|	END AS CashType,
		|	ISNULL(PaymentDecryptionTable.CashFlowItem, DataTable.CashFlowItem) AS CashFlowItem,
		|	DataTable.Currency AS Currency,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
		|			THEN UNDEFINED
		|		WHEN PaymentDecryptionTable.LoanDepositContract <> VALUE(Catalog.LoanAndDepositContracts.EmptyRef)
		|			THEN PaymentDecryptionTable.LoanDepositContract.LineOfBusiness
		|		WHEN PaymentDecryptionTable.LeaseContracts <> VALUE(Catalog.LeaseContract.EmptyRef)
		|			THEN PaymentDecryptionTable.LeaseContracts.LineOfBusiness
		|		ELSE ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DataTable.LineOfBusiness)
		|	END AS CounterpartyLineOfBusiness,
		|	CASE
		|		WHEN DataTable.BusinessOperation IN (VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
		|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany))
		|			THEN VALUE(Catalog.Partners.OurEnterprise)
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
		|			THEN UNDEFINED
		|		ELSE ISNULL(PaymentDecryptionTable.ARAPObject.Partner, DataTable.Partner)
		|	END AS Partner,
		|	CASE
		|		WHEN DataTable.BusinessOperation IN (VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
		|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany))
		|			THEN DataTable.CompanyRecipient
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
		|			THEN DataTable.BankAccountBeneficiary.Owner
		|		ELSE ISNULL(PaymentDecryptionTable.ARAPObject.Counterparty, DataTable.Counterparty)
		|	END AS Counterparty,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
		|			THEN UNDEFINED
		|		WHEN PaymentDecryptionTable.LoanDepositContract <> VALUE(Catalog.LoanAndDepositContracts.EmptyRef)
		|			THEN PaymentDecryptionTable.LoanDepositContract
		|		WHEN PaymentDecryptionTable.LeaseContracts <> VALUE(Catalog.LeaseContract.EmptyRef)
		|			THEN PaymentDecryptionTable.LeaseContracts
		|		ELSE ISNULL(PaymentDecryptionTable.ARAPObject.Contract, DataTable.Contract)
		|	END AS Contract,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
		|			THEN UNDEFINED
		|		ELSE PaymentDecryptionTable.ARAPObject
		|	END AS ARAPObject,
		|	CASE
		|		WHEN NOT DataTable.OverLimits
		|			THEN ISNULL(PaymentDecryptionTable.Sum, DataTable.DocumentAmount)
		|		ELSE 0
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DataTable.OverLimits
		|			THEN ISNULL(PaymentDecryptionTable.Sum, DataTable.DocumentAmount)
		|		ELSE 0
		|	END AS AmountToBePaidAboveLimit,
		|	ISNULL(PaymentDecryptionTable.Sum, DataTable.DocumentAmount) AS AmountToBePaid
		|INTO TempTableName
		|FROM
		|	Document.PaymentRequest AS DataTable
		|		LEFT JOIN Document.PaymentRequest.ARAPDetails AS PaymentDecryptionTable
		|		ON DataTable.Ref = PaymentDecryptionTable.Ref
		|WHERE
		|	NOT DataTable.Status = VALUE(Enum.StatusesOfPaymentRequests.IsRejected)
		|	AND DataTable.Ref = &Document
		|	AND CASE
		|			WHEN DataTable.PaymentDate <> DATETIME(1, 1, 1)
		|				THEN DataTable.PaymentDate
		|			WHEN DataTable.RequiredPaymentDate <> DATETIME(1, 1, 1)
		|				THEN DataTable.RequiredPaymentDate
		|			ELSE BEGINOFPERIOD(DataTable.Date, DAY)
		|		END BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND CASE
		|			WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
		|				THEN TRUE
		|			ELSE TRUE IN
		|					(SELECT TOP 1
		|						TRUE
		|					FROM
		|						Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|					WHERE
		|						DataTable.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|						AND BusinessTransactionsSettings.Receipt = VALUE(Enum.AccountingDataTypes.Counterparties)
		|						AND BusinessTransactionsSettings.Expense = VALUE(Enum.AccountingDataTypes.Cash))
		|		END";
	
	ElsIf Receipt = Enums.AccountingDataTypes.OtherAssetsLiabilities Then
		
		QueryText =
		"SELECT
		|	CASE
		|		WHEN DataTable.PaymentDate <> DATETIME(1, 1, 1)
		|			THEN DataTable.PaymentDate
		|		WHEN DataTable.RequiredPaymentDate <> DATETIME(1, 1, 1)
		|			THEN DataTable.RequiredPaymentDate
		|		ELSE BEGINOFPERIOD(DataTable.Date, DAY)
		|	END AS Period,
		|	DataTable.Ref AS Recorder,
		|	CASE
		|		WHEN DataTable.PayrollTransaction <> VALUE(Enum.BusinessTransactions.EmptyRef)
		|			THEN DataTable.PayrollTransaction
		|		ELSE DataTable.BusinessOperation
		|	END AS DataSource,
		|	DataTable.Organization AS Organization,
		|	DataTable.Department AS Department,
		|	DataTable.Department AS PaymentDivision,
		|	UNDEFINED AS LineOfBusinessCash,
		|	CASE
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN DataTable.CashAccount
		|		ELSE DataTable.BankAccount
		|	END AS Cash,
		|	CASE
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.CashAccountPayment_)
		|			THEN VALUE(Enum.CashTypes.CashPayment)
		|		WHEN DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.BankAccountPayment)
		|			OR DataTable.PaymentMethodOfPaymentRequest = VALUE(Enum.PaymentForms.InstantPayments)
		|			THEN VALUE(Enum.CashTypes.BankAccountPayments_)
		|		ELSE CASE
		|			WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|				THEN VALUE(Enum.CashTypes.BankAccountPayments_)
		|			ELSE UNDEFINED
		|		END
		|	END AS CashType,
		|	ISNULL(PaymentDecryptionTable.CashFlowItem, DataTable.CashFlowItem) AS CashFlowItem,
		|	DataTable.Currency AS Currency,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
		|			THEN PaymentDecryptionTable.Department
		|		ELSE UNDEFINED
		|	END AS DivisionOfAssetsLiabilities,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
		|			THEN PaymentDecryptionTable.LineOfBusiness
		|		ELSE UNDEFINED
		|	END AS LineOfBusinessOfAssetsLiabilities,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions)
		|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes)
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPayment)
		|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll)
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee)
		|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings)
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
		|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLeasing)
		|		ELSE PaymentDecryptionTable.ExpenseItem
		|	END AS AssetAndLiabilityItem,
		|	CASE
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions)
		|			THEN DataTable.TaxType
		|		WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
		|			THEN PaymentDecryptionTable.LeaseContracts
		|		WHEN DataTable.BusinessOperation IN (VALUE(Enum.BusinessTransactions.OtherCashIssue), VALUE(Enum.BusinessTransactions.SalaryPayment))
		|			THEN PaymentDecryptionTable.AssetsLiabilitiesDimension
		|		ELSE UNDEFINED
		|	END AS AssetsLiabilitiesDimension,
		|	CASE
		|		WHEN NOT DataTable.OverLimits
		|			THEN ISNULL(PaymentDecryptionTable.Sum, DataTable.DocumentAmount)
		|		ELSE 0
		|	END AS AmountToBePaidWithinLimit,
		|	CASE
		|		WHEN DataTable.OverLimits
		|			THEN ISNULL(PaymentDecryptionTable.Sum, DataTable.DocumentAmount)
		|		ELSE 0
		|	END AS AmountToBePaidAboveLimit,
		|	ISNULL(PaymentDecryptionTable.Sum, DataTable.DocumentAmount) AS AmountToBePaid
		|INTO TempTableName
		|FROM
		|	Document.PaymentRequest AS DataTable
		|		LEFT JOIN Document.PaymentRequest.ARAPDetails AS PaymentDecryptionTable
		|		ON DataTable.Ref = PaymentDecryptionTable.Ref
		|WHERE
		|	NOT DataTable.Status = VALUE(Enum.StatusesOfPaymentRequests.IsRejected)
		|	AND DataTable.Ref = &Document
		|	AND CASE
		|			WHEN DataTable.PaymentDate <> DATETIME(1, 1, 1)
		|				THEN DataTable.PaymentDate
		|			WHEN DataTable.RequiredPaymentDate <> DATETIME(1, 1, 1)
		|				THEN DataTable.RequiredPaymentDate
		|			ELSE BEGINOFPERIOD(DataTable.Date, DAY)
		|		END BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND CASE
		|			WHEN DataTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
		|				THEN NOT PaymentDecryptionTable.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
		|			WHEN DataTable.PayrollTransaction <> VALUE(Enum.BusinessTransactions.EmptyRef)
		|				THEN TRUE
		|			ELSE TRUE IN
		|					(SELECT TOP 1
		|						TRUE
		|					FROM
		|						Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|					WHERE
		|						DataTable.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|						AND BusinessTransactionsSettings.Receipt = VALUE(Enum.AccountingDataTypes.OtherAssetsLiabilities)
		|						AND BusinessTransactionsSettings.Expense = VALUE(Enum.AccountingDataTypes.Cash))
		|		END";
		
	EndIf;
	
	If Not IsBlankString(TempTableName) Then
		QueryText = StrReplace(QueryText, "TempTableName", TempTableName);
	Else
		QueryText = StrReplace(QueryText, "INTO TempTableName", "");
		QueryText = StrReplace(QueryText, "DataTable.Ref = &Document", "DataTable.Posted");
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion
#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//    ToDoList - ValueTable - Current service.Novatoriskais().
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Document.PaymentRequest.Form.FormOfListOfRequestsForApproval";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.PaymentRequest))
		And (AccessRight("Update", Metadata.Documents.PaymentRequest)
			Or UserRightsCached.PaymentRequestsApproval())
		And GetFunctionalOption("UsePaymentRequests");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT CASE
	|			WHEN PaymentRequest.Status = VALUE(Enum.StatusesOfPaymentRequests.NotAgreedUpon)
	|				THEN PaymentRequest.Ref
	|			ELSE NULL
	|		END) AS RequestsForPaymentToBeAgreed,
	|	COUNT(DISTINCT CASE
	|			WHEN PaymentRequest.Status = VALUE(Enum.StatusesOfPaymentRequests.NotAgreedUpon)
	|					AND PaymentRequest.PaymentDate < BEGINOFPERIOD(&UpdateDate, DAY)
	|				THEN PaymentRequest.Ref
	|			ELSE NULL
	|		END) AS RequestsForPaymentForApprovalOverdue
	|FROM
	|	Document.PaymentRequest AS PaymentRequest
	|WHERE
	|	PaymentRequest.Posted";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Application for payment
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "PaymentRequests";
	UserTaskParent.Presentation  = NStr("vi = 'Giấy đề nghị thanh toán';
										|ru = 'Заявки на оплату';
										|en = 'Payment requests'; fa = 'درخواست‌های پرداخت';
										|it = 'Richieste di pagamento';
										|pl = 'Wnioski o płatność';
										|tr = 'Ödeme talepleri'");
	UserTaskParent.Owner       = Metadata.Subsystems.Purchases;
	
	// RequestsForPaymentToBeAgreed
	FilterParameters = New Structure;
	FilterParameters.Insert("Status", Enums.StatusesOfPaymentRequests.NotAgreedUpon);
	FilterParameters.Insert("PayDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Organization", Catalogs.Companies.EmptyRef());
	FilterParameters.Insert("Priority", Catalogs.Priorities.EmptyRef());
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "RequestsForPaymentToBeAgreed";
	ToDoItem.HasToDoItems       = Result.RequestsForPaymentToBeAgreed > 0;
	ToDoItem.Presentation  = NStr("vi = 'Giấy đề nghị cần thống nhất';
									|ru = 'Заявки к согласованию';
									|en = 'Requests for approval'; fa = 'درخواست‌ها برای تأیید';
									|it = 'Richieste da concordare';
									|pl = 'Wnioski do uzgodnienia';
									|tr = 'Anlaşma talepleri'");
	ToDoItem.Count     = Result.RequestsForPaymentToBeAgreed;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "PaymentRequests";
	
	// RequestsForPaymentForApprovalOverdue
	FilterParameters = New Structure;
	FilterParameters.Insert("Status", Enums.StatusesOfPaymentRequests.NotAgreedUpon);
	FilterParameters.Insert("PayDate", BegOfDay(CommonQueryParameters.CurrentDate - 86400));
	FilterParameters.Insert("Organization", Catalogs.Companies.EmptyRef());
	FilterParameters.Insert("Priority", Catalogs.Priorities.EmptyRef());
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "RequestsForPaymentForApprovalOverdue";
	ToDoItem.HasToDoItems       = Result.RequestsForPaymentForApprovalOverdue > 0;
	ToDoItem.Presentation  = NStr("vi = 'Thống nhất đã quá hạn';
									|ru = 'Согласование просрочено';
									|en = 'Approval overdue'; fa = 'مهلت تأیید گذشته است';
									|it = 'Concordamento scaduto';
									|pl = 'Zaległe uzgodnienie';
									|tr = 'Süresi geçmiş mutabakat'");
	ToDoItem.Count     = Result.RequestsForPaymentForApprovalOverdue;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "PaymentRequests";
	
	If Result.RequestsForPaymentToBeAgreed > 0
		Or Result.RequestsForPaymentForApprovalOverdue > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Print

// Forms printed forms
//
// Parameters:
//  (input)
//    ObjectsArray  - Array    - references to objects that should be printed;
//    PrintParameters - Structure - advanced print settings;
//  (output)
//   PrintFormsCollection - ValueTable - generated tabular documents.
//   PrintObjects         - ValueList  - value - the object reference;
//                                             view - name of the area where the object was displayed;
//   OutputParameters       - Structure       - additional parameters of generated table documents.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	PaymentRequestLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export


EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	
EndProcedure


#EndRegion

#EndRegion

#EndIf
