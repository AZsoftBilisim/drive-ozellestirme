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
	Parameters.StatisticsCollectionSections.UseAlways = "Cashier";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Cashier";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "CashAccount";
	Parameters.FillInIf.ObjectFieldsFilledIn = "CashAccount, Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Cashier", Parameters);
	
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
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("PlanningCashControl");
	DocumentMechanisms.Add("AdvanceHoldersARAPAccounting_");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("FinancialInstruments");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("ControlOfBudgetingLimits");
	//++ WE
	DocumentMechanisms.Add("PayrollAccountingHR");
	//-- WE
	CashVoucherLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.CashVoucher") Then
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
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableCashAccountBalance(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableBankAccountCash(Query, QueryTexts, Registers, DocumentObject);
		QueryTextCashInTransit(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCashToBePaid(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCashFlow(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCashFlowLimits(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject);
		//++ WE
		QueryTextTablePayrollCalculationsHR(Query, QueryTexts, Registers, DocumentObject);
		//-- WE
		// Query execution and uploading of the received tables to generate Registered Records
		CashVoucherLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
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
	
	FillParameters.PurchaseOfGoods = True;
	FillParameters.AcquisitionOfWorks = True;
	FillParameters.PurchaseOnArticles = True;
	
	Return FillParameters;
	
EndFunction

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.ExpenseReport.AddGenerateCommand(GenerationCommands);
	
	Documents.CashDepositWithdrawalDiscrepancies.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	If GetFunctionalOption("UseVATAccounting") Then
		Documents.ReceivedTaxInvoicePrepayment.AddGenerateCommand(GenerationCommands);
	EndIf;
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	BusinessOperationsForCorrection = New Array;
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.PaymentToVendor);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.IssueCashToAdvanceHolder);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashDepositToBankAccount);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashCollectionToBank);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashIssueToAnotherCashAccount);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashIssueToCashRegister);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashIssueAsLoanToCounterparty);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CurrencyConversion);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.OtherCashIssue);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.RefundToCustomer);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.PaymentToLessor);
	
	CommandCorrection = DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	
	If CommandCorrection <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			CommandCorrection,
			"BusinessOperation",
			BusinessOperationsForCorrection,
			DataCompositionComparisonType.InList);
		
	EndIf;
	
	CashVoucherLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "cash order Expense".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Order - Number - The order of the command.
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
Function AddGenerateCommand(GenerationCommands, Order = 0) Export
	If AccessRight("Insert", Metadata.Documents.CashVoucher) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CashVoucher.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CashVoucher);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.Order = Order;
		
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
	
	CashVoucherLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism.
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"BusinessOperation");
		BusinessOperation = StructureFillingData.BusinessOperation;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
	Else
		BusinessOperation = FillingData.BusinessOperation;
	EndIf;
	
	StructuresArray = New Array();
	
	#Region AllOtherFunctions
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	If BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	ElsIf BusinessOperation =Enums.BusinessTransactions.PaymentToVendor
		Or BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	EndIf;
	
	ParametersStructure.ChangesPaymentPlan = BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany;
	ParametersStructure.ChangesCalculationsByString                = 
		"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToVendor)
		|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
		|	OR
		|//Conditions of return beginning
		|	DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
		|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
		|//Conditions of return end";
	
	ParametersStructure.ModifiesDeliveryShipmentPlan = False;
	
	If BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
		ParametersStructure.Counterparty                             = "Object.CashAccountRecipient.Owner";
		ParametersStructure.Partner                                = Catalogs.Partners.OurEnterprise;
	Else
		ParametersStructure.Counterparty                             = "Object.Counterparty";
		ParametersStructure.Partner                          = "Object.ARAPDetails.Partner";
	EndIf;
	
	ParametersStructure.ARAPCurrency             = "Object.ARAPDetails.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Form.AmountARAP";
	ParametersStructure.CourseNumerator                    = "Form.ExchangeRateNumeratorOfMutualSettlements";
	ParametersStructure.CourseDenominator                  = "Form.TheExchangeRateIsTheDenominatorOfMutualSettlements";
	ParametersStructure.ARAPObjectSettings                  = "";
	
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	 
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
	ParametersStructure.Organization                      = "Object.Organization";
	ParametersStructure.Terms                       = "";
	ParametersStructure.Contract                          = "Object.Contract";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "Object.CashAccount";
	ParametersStructure.Date                             = "Object.Date";
	ParametersStructure.PaymentID             = "";
	
	ParametersStructure.IncomingDocumentNumber          = "";
	ParametersStructure.IncomingDocumentDate           = "";
	ParametersStructure.VATTaxation               = "Object.VATTaxation";
	
	ParametersStructure.FormItems.ARAPDetails               = "ARAPDetails";
	ParametersStructure.FormItems.AddToPaymentDecryption        = "ARAPDetailsSelectionByStock";
	
	ParametersStructure.PartnerOtherRelations           = False;
	
	ParametersStructure.SelectOnlyUnconditionalDebt =
		BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany;
	ParametersStructure.PaymentByRequests                  = "Object.PaymentByRequests";
		
	ParametersStructure.MutualSettlementsCurrencyViewOnly = True;
	ParametersStructure.DocumentCurrencyViewOnly      = True;
	
	StructuresArray.Add(ParametersStructure);
	
	#EndRegion
	
	#Region SettlementObjectReturn
	
	If BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		
		ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		ParametersStructure.ARAPObject                   = "Object.ARAPObject";
		
		ParametersStructure.ChangesPaymentPlan               = True;
		ParametersStructure.ChangesCalculationsByString           = 
			"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToVendor)
			|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
			|	OR
			|//Conditions of return beginning
			|	DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
			|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
			|//Conditions of return end";
		
		ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
		
		If BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
			ParametersStructure.Counterparty                             = "Object.CashAccountRecipient.Owner";
			ParametersStructure.Partner                                = Catalogs.Partners.OurEnterprise;
		Else
			ParametersStructure.Counterparty                             = "Object.Counterparty";
			ParametersStructure.Partner                                = "Object.ARAPDetails.Partner";
		EndIf;
		
		ParametersStructure.ARAPCurrency             = "Object.ARAPDetails.ARAPCurrency";
		ParametersStructure.AmountARAP              = "Form.AmountARAP";
		ParametersStructure.CourseNumerator                    = "Form.ExchangeRateNumeratorOfMutualSettlements";
		ParametersStructure.CourseDenominator                  = "Form.TheExchangeRateIsTheDenominatorOfMutualSettlements";
		ParametersStructure.ARAPObjectSettings                  = "";
		
		ParametersStructure.PaymentMethod                      = "";
		ParametersStructure.ForeignCurrencyTransaction                    = "";
		 
		ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
		ParametersStructure.Organization                      = "Object.Organization";
		ParametersStructure.Terms                       = "";
		ParametersStructure.Contract                          = "Object.Contract";
		ParametersStructure.CompanyBankAccount        = "";
		ParametersStructure.CounterpartyBankAccount        = "";
		ParametersStructure.CashAccount                            = "Object.CashAccount";
		ParametersStructure.Date                             = "Object.Date";
		ParametersStructure.PaymentID             = "";
		
		ParametersStructure.IncomingDocumentNumber          = "";
		ParametersStructure.IncomingDocumentDate           = "";
		ParametersStructure.VATTaxation               = "Object.VATTaxation";
		
		ParametersStructure.MutualSettlementsCurrencyViewOnly = True;
		ParametersStructure.DocumentCurrencyViewOnly      = True;
		
		StructuresArray.Add(ParametersStructure);
		
	EndIf;
	
	#EndRegion
	
	Return StructuresArray;
	
EndFunction
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CashVoucherLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return CashVoucherLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_(BusinessOperation) Export
	
	ParametersArray = New Array();
	
	#Region SettingUpReflectionAccountInLocalAccounting
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.ARAPDetails";
	SetupParameters.AvailabilityByOperation =
		BusinessOperation = Enums.BusinessTransactions.OtherCashIssue;
	SetupParameters.ArticleType = "ArticleType";
	
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("DecodingWithoutSplittingRepresentationOfReflectionInReglAccounting");
	SetupParameters.FormItems.Add("ARAPDetailsPresentationOfRecordingInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

#EndRegion
#Region Other

// The function gets the details of the document to exchange with the "enterprise Accounting" configuration.
//
// Parameters:
//	DocumentRef - DocumentRef - The document for which you need to get the banking details.
//
// Returns:
//	Structure - The structure of the document details.
//
Function DocumentDetailsForExchangeWithAccounting(DocumentRef) Export
	
	Query = New Query("
	|SELECT TOP 1
	|	DocumentData.CashFlowItem.OffsettingAccount AS OffsettingAccount,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.CashVoucher AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CashFlowItem.OffsettingAccount <> """"
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	DocumentData.ExpenseItem.OffsettingAccount AS OffsettingAccount,
	|	DocumentData.ExpenseItem AS ExpenseItem
	|FROM
	|	Document.CashVoucher.ARAPDetails AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.OtherExpenses)
	|	AND DocumentData.ExpenseItem.OffsettingAccount <> """"
	|
	|ORDER BY
	|	DocumentData.LineNumber
	|");
	Query.SetParameter("Ref", DocumentRef);
	ResultsArray = Query.ExecuteBatch();
	
	Selection = ResultsArray[0].Select();
	If Selection.Next() Then
		OffsettingAccount = Selection.OffsettingAccount;
		BusinessOperation = Selection.BusinessOperation;
	Else
		OffsettingAccount = "";
		BusinessOperation = Enums.BusinessTransactions.EmptyRef();
	EndIf;
	
	Selection = ResultsArray[1].Select();
	If Selection.Next() Then
		OffsettingAccount = Selection.OffsettingAccount;
		ExpenseItem = Selection.ExpenseItem;
	Else
		ExpenseItem = Undefined;
	EndIf;
	
	OperationKind = "Other_Expense";
	
	If BusinessOperation = Enums.BusinessTransactions.OtherExpenses Then
		
		If StrFind(OffsettingAccount, "70") <> 0 Then
			OperationKind = "SalaryPaymentByPaysheets";
		EndIf;
	
	ElsIf BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
		
		If StrFind(OffsettingAccount, "66") <> 0
		 Or StrFind(OffsettingAccount, "67") <> 0 Then
			OperationKind = "SettlementsOnLoansAndBorrowings";
			
		ElsIf StrFind(OffsettingAccount, "70") <> 0 Then
			OperationKind = "SalaryPaymentByPaysheets";
			
		EndIf;
		
	EndIf;
	
	AttributesStructure1 = New Structure("OperationKind, Account, ExpenseItem",
		OperationKind,
		OffsettingAccount,
		ExpenseItem);
	
	Return AttributesStructure1;
		
EndFunction

// The procedure fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	Object - DocumentObject.CashVoucher, FormDataStructure - an object containing the "Business Operation" property
//	ArrayOfAllProps - Array of String - Array of all names of banking details that depend on the business operation
//	ArrayOfOperationDetails - Array of String - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(Object, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	BusinessOperation = Object.BusinessOperation;
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("BankAccount");
	ArrayOfAllProps.Add("CurrencyOfConversion");
	ArrayOfAllProps.Add("Statement");
	ArrayOfAllProps.Add("PayrollPayment");
	ArrayOfAllProps.Add("ExpenseReportDate");
	ArrayOfAllProps.Add("PaysheetDate");
	ArrayOfAllProps.Add("PaymentRequest");
	ArrayOfAllProps.Add("CashRegister");
	ArrayOfAllProps.Add("CashAccountRecipient");
	ArrayOfAllProps.Add("Counterparty");
	ArrayOfAllProps.Add("ConversionRate");
	ArrayOfAllProps.Add("ConversionRateMultiplier");
	ArrayOfAllProps.Add("PaysheetNumber");
	ArrayOfAllProps.Add("PaymentByRequests");
	ArrayOfAllProps.Add("AdvanceHolder");
	ArrayOfAllProps.Add("Department");
	ArrayOfAllProps.Add("CashFlowItem");
	ArrayOfAllProps.Add("ConversionAmount");
	ArrayOfAllProps.Add("RowIndividuals");
	
	ArrayOfAllProps.Add("FinancialAccountingGroup");
	ArrayOfAllProps.Add("LineOfBusiness");
	ArrayOfAllProps.Add("Contract");
	ArrayOfAllProps.Add("VATTaxation");
	
	ArrayOfAllProps.Add("ARAPDetails");
	ArrayOfAllProps.Add("CashTransferReferenceOrder");
	ArrayOfAllProps.Add("ARAPDetails.ARAPCurrency");
	ArrayOfAllProps.Add("ARAPDetails.LoanDepositContract");
	ArrayOfAllProps.Add("ARAPDetails.EmployeeLoanAgreement");
	ArrayOfAllProps.Add("ARAPDetails.LeaseContracts");
	ArrayOfAllProps.Add("ARAPDetails.ARAPObject");
	ArrayOfAllProps.Add("ARAPDetails.PaymentRequest");
	ArrayOfAllProps.Add("ARAPDetails.Comment");
	ArrayOfAllProps.Add("ARAPDetails.Partner");
	ArrayOfAllProps.Add("ARAPDetails.Department");
	ArrayOfAllProps.Add("ARAPDetails.CashFlowItem");
	ArrayOfAllProps.Add("ARAPDetails.AmountARAP");
	ArrayOfAllProps.Add("ARAPDetails.VATRate");
	ArrayOfAllProps.Add("ARAPDetails.VATAmount");
	ArrayOfAllProps.Add("ARAPDetails.LoanAndDepositAmountType");
	ArrayOfAllProps.Add("ARAPDetails.TypeOfLeasePayment");
	ArrayOfAllProps.Add("ARAPDetails.Organization");
	ArrayOfAllProps.Add("ARAPDetails.LineOfBusiness");
	ArrayOfAllProps.Add("ARAPDetails.MaturityDate");
	
	ArrayOfOperationDetails = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.PaymentToVendor Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		ArrayOfOperationDetails.Add("ARAPDetails.MaturityDate");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount Then
		ArrayOfOperationDetails.Add("CashTransferReferenceOrder");
		ArrayOfOperationDetails.Add("BankAccount");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashCollectionToBank Then
		ArrayOfOperationDetails.Add("CashTransferReferenceOrder");
		ArrayOfOperationDetails.Add("BankAccount");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashIssueToAnotherCashAccount Then
		ArrayOfOperationDetails.Add("CashTransferReferenceOrder");
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		ArrayOfOperationDetails.Add("ARAPDetails.MaturityDate");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("ExpenseReportDate");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashIssueToCashRegister Then
		ArrayOfOperationDetails.Add("CashRegister");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Department");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.LineOfBusiness");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("CurrencyOfConversion");
		ArrayOfOperationDetails.Add("ConversionRate");
		ArrayOfOperationDetails.Add("ConversionRateMultiplier");
		ArrayOfOperationDetails.Add("ConversionAmount");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount Then
		
		If GetFunctionalOption("UsePayrollTM")
		//++ WE 
		Or GetFunctionalOption("PayrollAndHumanResourcesWE")
		//-- WE 
		Or False Then
			ArrayOfOperationDetails.Add("Statement");
			ArrayOfOperationDetails.Add("RowIndividuals");
			ArrayOfOperationDetails.Add("PayrollPayment");
		Else
			ArrayOfOperationDetails.Add("PaysheetNumber");
			ArrayOfOperationDetails.Add("PaysheetDate");
		EndIf;
		
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("PaymentRequest");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByDistributor Then
		
		If GetFunctionalOption("UsePayrollTM") Then
			ArrayOfOperationDetails.Add("Statement");
			ArrayOfOperationDetails.Add("RowIndividuals");
			ArrayOfOperationDetails.Add("PayrollPayment");
		Else
			ArrayOfOperationDetails.Add("PaysheetNumber");
			ArrayOfOperationDetails.Add("PaysheetDate");
		EndIf;
		
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("PaymentRequest");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToEmployee Then
		If GetFunctionalOption("UsePayrollTM") Then
			ArrayOfOperationDetails.Add("Statement");
		Else
			ArrayOfOperationDetails.Add("PaysheetNumber");
			ArrayOfOperationDetails.Add("PaysheetDate");
		EndIf;
		
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("PaymentRequest");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or BusinessOperation = Enums.BusinessTransactions.TransferToDeposits
		Or BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty Then
		
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.LoanDepositContract");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		If BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived Then
			ArrayOfOperationDetails.Add("ARAPDetails.LoanAndDepositAmountType");
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee Then
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("Department");
		
		If GetFunctionalOption("UsePayrollTM") Then
			ArrayOfOperationDetails.Add("ARAPDetails");
			ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
			ArrayOfOperationDetails.Add("ARAPDetails.EmployeeLoanAgreement");
			ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
			ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		Else
			ArrayOfOperationDetails.Add("PaymentRequest");
			ArrayOfOperationDetails.Add("CashFlowItem");
		EndIf;
	ElsIf BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("Department");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.LeaseContracts");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.TypeOfLeasePayment");
	EndIf;
	
EndProcedure

// This function determines the details of the selected document.
//
// Parameters:
//  DocumentRef - DocumentRef - Link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.CashVoucher AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
		BusinessOperation = Selection.BusinessOperation;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		BusinessOperation = Enums.BusinessTransactions.EmptyRef();
	EndIf;
	
	AttributesStructure1 = New Structure("Date, Organization, BusinessOperation",
		Date,
		Organization,
		BusinessOperation);
	
	Return AttributesStructure1;

EndFunction

// Determines the composition of households. document operations that do not use the payment transcript if there are no requests for
// the DS expense.
//
// Returns:
//    Array - business transactions without the use of payment decryption.
//
Function ArrayOfOperationsWithoutPaymentDecryption() Export
	
	OperationArray = New Array;
	
	OperationArray.Add(Enums.BusinessTransactions.CurrencyConversion);
	OperationArray.Add(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices);
	
	Return OperationArray;
	
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.ARAPDetails";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
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
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DecodingWithoutSplittingTheExpenseAnalyst");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ARAPDetailsDimensionOfExpenses");
	#EndRegion
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
		
	Return ArrayOfSelectionParameters;
	
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
	
	#Region Header
	// PaymentByRequests
	Item = Settings.Add();
	Item.Fields.Add("PaymentByRequests");
	Item.Fields.Add("TextApplicationHeader");
	
	OrGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	ConditionOfApplicationForExpenseOfCash = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	ConditionOfApplicationForExpenseOfCash.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(ConditionOfApplicationForExpenseOfCash, "More.UsePaymentRequests", True);
	
	UnderGroupOr = Finances.NewFilter(ConditionOfApplicationForExpenseOfCash,,, Type("DataCompositionFilterItemGroup"));
	UnderGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.OtherCashIssue);

	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.PaymentToLessor);
	ConditionOfApplicationForBusinessTrip = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	ConditionOfApplicationForBusinessTrip.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(ConditionOfApplicationForBusinessTrip, "More.UseApplicationsForBusinessTrip", True);
	Finances.NewFilter(ConditionOfApplicationForBusinessTrip, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("PaymentByRequests");
	Finances.NewFilter(Item.Condition, "More.EnabledCreatingCashIssueWithoutPaymentRequest", True);
	Item.Properties.Insert("Enabled");
	
	// AdvanceHolder
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentByDistributor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentToEmployee);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentToEmployee);
	Item.Properties.Insert("Title", NStr("vi = 'Người lao động';
										|ru = 'Работник';
										|en = 'Employee'; fa = 'کارمند';
										|it = 'Dipendente';
										|pl = 'Employee';
										|tr = 'Çalışan'"));
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.SalaryPaymentByDistributor);
	Item.Properties.Insert("Title", NStr("vi = 'Nhà phân phối';
										|ru = 'Раздатчик';
										|en = 'Distributor'; fa = 'Distributor';
										|it = 'Distributore';
										|pl = 'Distributor';
										|tr = 'Dağıtımcı'"));
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Item.Properties.Insert("Title", NStr("vi = 'Người nhận tạm ứng';
										|ru = 'Подотчетное лицо';
										|en = 'Advance holder'; fa = 'تنخواه‌دار';
										|it = 'Titolare di anticipo';
										|pl = 'Osoba rozliczająca się za wydatki';
										|tr = 'Sorumlu kişi'"));
	
	// BankAccount
	Item = Settings.Add();
	Item.Fields.Add("BankAccount");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashDepositToBankAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashCollectionToBank);
	Item.Properties.Insert("Visible");
	
	// CashAccountRecipient
	Item = Settings.Add();
	Item.Fields.Add("CashAccountRecipient");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueToAnotherCashAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Visible");
	
	// CashRegister
	Item = Settings.Add();
	Item.Fields.Add("CashRegister");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueToCashRegister);
	Item.Properties.Insert("Visible");
	
	// LabelCurrency
	Item = Settings.Add();
	Item.Fields.Add("LabelCurrency");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", False);
	Item.Properties.Insert("Visible");
	
	// Counterparty
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Item.Fields.Add("CounterpartyCheckIssueCounterpartyPages");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Nhà môi giới';
										|ru = 'Брокер';
										|en = 'Broker'; fa = 'کارگزار';
										|it = 'Брокер';
										|pl = 'Broker';
										|tr = 'Komisyoncu'"));
	
	// CashFlowItem
	Item = Settings.Add();
	Item.Fields.Add("CashFlowItem");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentViaCashAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentByDistributor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentToEmployee);
	
	AndGroup1 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(AndGroup1, "More.UsePayrollTM", False);
	Item.Properties.Insert("Visible");
	
	// CashTransferReferenceOrder
	Item = Settings.Add();
	Item.Fields.Add("CashTransferReferenceOrder");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashDepositToBankAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashCollectionToBank);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueToAnotherCashAccount);
	Item.Properties.Insert("Visible");
	
	// PaymentRequest
	Item = Settings.Add();
	Item.Fields.Add("PaymentRequest");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentViaCashAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentByDistributor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentToEmployee);
	AndGroup1 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(AndGroup1, "More.UsePayrollTM", False);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("PaymentRequest");
	Finances.NewFilter(Item.Condition, "More.EnabledCreatingCashIssueWithoutPaymentRequest", True);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
	// DocumentBasis
	Item = Settings.Add();
	Item.Fields.Add("DocumentBasis");
	Finances.NewFilter(Item.Condition, "DocumentBasis",,, DataCompositionComparisonType.Filled);
	Item.Properties.Insert("Visible");
	
	// Department
	Item = Settings.Add();
	Item.Fields.Add("Department");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashIssueToAnotherCashAccount);
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region Attributes
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
	
	// Conversion
	Item = Settings.Add();
	Item.Fields.Add("CurrencyOfConversion");
	Item.Fields.Add("ConversionRate");
	Item.Fields.Add("ConversionAmount");
	Item.Fields.Add("ConversionRateMultiplier");
	Item.Fields.Add("CurrencyOfConversionRate");
	Item.Fields.Add("CurrencyOfConversionRateMultiplicity");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Visible");
	
	// Statement
	Item = Settings.Add();
	Item.Fields.Add("Statement");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	AndGroup = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	Finances.NewFilter(AndGroup, "More.UsePayrollTM", True);
	OrGroup1 = Finances.NewFilter(AndGroup,,, Type("DataCompositionFilterItemGroup"));
	OrGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup1, "BusinessOperation", Enums.BusinessTransactions.SalaryPaymentViaCashAccount);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Enums.BusinessTransactions.SalaryPaymentByDistributor);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Enums.BusinessTransactions.SalaryPaymentToEmployee);
	
	//++ WE
	AndGroup1 = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;	
	Finances.NewFilter(AndGroup1, "More.PayrollAndHumanResourcesWE", True);
	Finances.NewFilter(AndGroup1, "BusinessOperation", Enums.BusinessTransactions.SalaryPaymentViaCashAccount);
	//-- WE
	Item.Properties.Insert("Visible");
	
	// RowIndividuals
	Item = Settings.Add();
	Item.Fields.Add("RowIndividuals");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	AndGroup = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	Finances.NewFilter(AndGroup, "More.UsePayrollTM", True);
	OrGroup1 = Finances.NewFilter(AndGroup,,, Type("DataCompositionFilterItemGroup"));
	OrGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup1, "BusinessOperation", Enums.BusinessTransactions.SalaryPaymentViaCashAccount);
	Finances.NewFilter(OrGroup1, "BusinessOperation", Enums.BusinessTransactions.SalaryPaymentByDistributor);
	
	//++ WE
	AndGroup1 = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "More.PayrollAndHumanResourcesWE", True);
	OrGroup2 = Finances.NewFilter(AndGroup1,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Enums.BusinessTransactions.SalaryPaymentViaCashAccount);
	//-- WE
	Item.Properties.Insert("Visible");
	
	//++ WE
	// Summadocument
	Item = Settings.Add();
	Item.Fields.Add("DocumentAmount");
	AndGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Enums.BusinessTransactions.SalaryPaymentViaCashAccount);
	Finances.NewFilter(AndGroup, "More.PayrollAndHumanResourcesWE", True);
	Item.Properties.Insert("ReadOnly");
	//-- WE
	#EndRegion
	
	#Region ARAPDetails
	// TheDecryptionPage
	Item = Settings.Add();
	Item.Fields.Add("TheDecryptionPage");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "PaymentByRequests", True);
	OrGroup2 = Finances.NewFilter(AndGroup,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.CurrencyConversion);
	
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.UsePayrollTM", True);
	OrGroup2 = Finances.NewFilter(AndGroup,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	
	Item.Properties.Insert("Visible");
	
	// PaymentRequest
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.PaymentRequest");
	Item.Fields.Add("DecryptionWithoutSplittingTheApplicationForSpendingMoney");
	
	Finances.NewFilter(Item.Condition, "PaymentByRequests", True);
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.UsePayrollTM", True);
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.PaymentRequest");
	Item.Fields.Add("DecryptionWithoutSplittingTheApplicationForSpendingMoney");
	Finances.NewFilter(Item.Condition, "More.EnabledCreatingCashIssueWithoutPaymentRequest", True);
	Finances.NewFilter(Item.Condition, "PaymentByRequests", False);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.UsePayrollTM", True);
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Item.Properties.Insert("Visible");
	
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	Finances.NewFilter(Item.Condition, "Currency", "More.ARAPCurrency",, DataCompositionComparisonType.NotEqual, True);
	UnderGroupOr = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	UnderGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(UnderGroupOr, "More.MultipleARAPCurrency", True);
	Finances.NewFilter(UnderGroupOr, "More.ARAPCurrency", Catalogs.Currencies.EmptyRef(), , DataCompositionComparisonType.NotEqual);
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
	Item.Properties.Insert("Visible");
	
	// ARAPObject
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.ARAPObject");
	Item.Fields.Add("DecryptionWithoutSplittingTheCalculationObject");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Item.Properties.Insert("Visible");
	
	// Partner
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.Partner");
	Item.Fields.Add("DecryptionWithoutPartitioningPartner");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	Item.Properties.Insert("Visible");
	
	// LoanDepositContract
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.LoanDepositContract");
	Item.Fields.Add("DecryptionWithoutSplittingTheLoanDepositAgreement");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Item.Properties.Insert("Visible");
	
	// HyperlinkPaymentObjectDetails
	Item = Settings.Add();
	Item.Fields.Add("HyperlinkPaymentObjectDetails");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
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
	
	Item = Settings.Add();
	Item.Fields.Add("Contract");
	
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
	
	Item.Properties.Insert("Visible");
	
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
	Item.Fields.Add("ARAPDetailsContract");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	AndGroup1 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "More.UseContractsWithVendors", True);
	Finances.NewFilter(AndGroup1, "BusinessOperation", Operations.PaymentToVendor);
	
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
	
	Item.Properties.Insert("Visible");
	
	// Course Accuracy
	CashServer.FillInConditionalAppearanceAccuracyOfCourse(Settings);
	
	#EndRegion
	
	#Region Commands
	Item = Settings.Add();
	Item.Fields.Add("FillInThePaymentExplanationOnLoansForCounterparty");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetailsSelectionByStock");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Item.Properties.Insert("Visible");
	#EndRegion
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	( ValueAllowed(Organization)
	|	OR (ValueAllowed(CompanyRecipient)
	|		AND BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany))
	|	OR (ValueAllowed(ARAPDetails.Organization)
	|		AND BusinessOperation IN (VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|									VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|									VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|									VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)))
	|	)
	|	AND( ValueAllowed(CashAccount)
	|	OR (ValueAllowed(CashAccountRecipient)
	|	AND BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount), VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)))
	|	AND CASE
	|		WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount)
	|			THEN TRUE
	|		ELSE ValueAllowed(Department) END)
	|	AND ValueAllowed(BusinessOperation)
	|	AND CASE WHEN BusinessOperation IN (VALUE(Enum.BusinessTransactions.PaymentToVendor), VALUE(Enum.BusinessTransactions.RefundToCustomer))
	|	THEN ValueAllowed(ARAPDetails.Partner)
	|	WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) THEN ValueAllowed(AdvanceHolder)
	|	WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueToCashRegister) THEN ValueAllowed(CashRegister)
	|	ELSE TRUE END 
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(CashAccount)
	|	AND CASE
	|		WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount)
	|			THEN TRUE
	|		ELSE ValueAllowed(Department) END
	|	AND ValueAllowed(BusinessOperation)
	|	AND CASE WHEN BusinessOperation IN (VALUE(Enum.BusinessTransactions.PaymentToVendor), VALUE(Enum.BusinessTransactions.RefundToCustomer))
	|	THEN ValueAllowed(ARAPDetails.Partner)
	|	WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) THEN ValueAllowed(AdvanceHolder)
	|	WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueToCashRegister) THEN ValueAllowed(CashRegister)
	|	ELSE TRUE END
	|";

EndProcedure

// End StandardSubsystems.AccessManagement

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
	DataSources.Insert("ARAPDetails.ARAPObject");

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	TemporaryTableQueryTexts = New Map;
	RedefiningParameterCalculation = New Structure;
	SynonymForDocumentTable = "";
	
	FullDocumentName = "Document.CashVoucher";
	
	If RegisterName = "CashToBePaid" Then
		
		RedefiningParameterCalculation.Insert("Recipient", "
			|CASE
			|	WHEN DocumentData.BusinessOperation IN (
			|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
			|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee)
			|		) THEN
			|			DocumentData.AdvanceHolder
			|		WHEN DocumentData.BusinessOperation IN (
			|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
			|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
			|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
			|		THEN
			|			DocumentData.CompanyRecipient
			|	ELSE
			|		DocumentData.Counterparty
			|END");
		
		QueryText = QueryTextTableCashToBePaid(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		RedefiningParameterCalculation.Insert("PartnerFromDocument", "
			|	CASE
			|		WHEN DocumentData.BusinessOperation IN
			|			(VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
			|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
			|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
			|		THEN
			|			VALUE(Catalog.Partners.OurEnterprise)
			|		ELSE
			|			DocumentData.Partner
			|	END");
		RedefiningParameterCalculation.Insert("CounterpartyFromDocument", "
			|	CASE
			|		WHEN DocumentData.BusinessOperation IN
			|			(VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
			|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
			|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
			|		THEN
			|			DocumentData.CompanyRecipient
			|			
			|		ELSE
			|			DocumentData.Counterparty
			|	END");
		RedefiningParameterCalculation.Insert("AssigneeBusinessUnit", "
			|	DocumentData.CashAccount.Department");
		
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
			QueryText, FullDocumentName, SynonymForDocumentTable, RedefiningParameterCalculation, TemporaryTableQueryTexts);
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
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CurrencyOfConversion AS CurrencyOfConversion,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CompanyRecipient AS CompanyRecipient,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.PaymentByRequests AS PaymentByRequests,
	|	DocumentData.PaymentRequest AS PaymentRequest,
	|	DocumentData.CashTransferReferenceOrder AS CashTransferReferenceOrder,
	|	DocumentData.PaymentRequest.Currency AS RequestCurrency,
	|
	|	DocumentData.Basis AS Basis,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			VALUE(Catalog.Partners.OurEnterprise)
	|	
	|		WHEN
	|			ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE)
	|		THEN
	|			VALUE(Catalog.Partners.RetailCustomer)
	|		
	|	ELSE
	|		DocumentData.Partner
	|	END AS Partner,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			DocumentData.CompanyRecipient
	|	
	|		WHEN
	|			ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE)
	|		THEN
	|			VALUE(Catalog.Counterparties.RetailCustomer)
	|		
	|	ELSE
	|		DocumentData.Counterparty
	|	END AS Counterparty,
	|	
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE
	|			DocumentData.Partner
	|	END AS PartnerFromDocument,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			DocumentData.CompanyRecipient
	|			
	|		ELSE
	|			DocumentData.Counterparty
	|	END AS CounterpartyFromDocument,
	|
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|			VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee)
	|		) THEN
	|			DocumentData.AdvanceHolder
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			DocumentData.CompanyRecipient
	|	ELSE
	|		DocumentData.Counterparty
	|	END AS Recipient,
	|	
	|	NOT ISNULL(DocumentData.CashAccountAllowsPaymentsWithoutSpecifyingRequests, FALSE) AS ProhibitPaymentsWithoutSpecifyingRequests,
	|	DocumentData.Department AS Department,
	|	DocumentData.CashAccount.Department AS AssigneeBusinessUnit,
	|	
	|	CAST(DocumentData.CashAccount AS Catalog.CashAccounts).LineOfBusiness AS LineOfBusinessCash,
	|	CAST(DocumentData.Ref AS Document.CashVoucher).ARAPDetails.(PaymentRequest) AS ARAPDetails,
	|	
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	DocumentData.CashAccount                   AS CashAccount,
	|	DocumentData.CashAccountRecipient         AS CashAccountRecipient,
	|	DocumentData.BankAccount          AS BankAccount,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Author                   AS Author,
	|	DocumentData.Cashier                  AS Cashier,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Patch             AS Patch,
	|	DocumentData.ReversedDocument    AS ReversedDocument,
	|	DocumentData.CorrectedDocument    AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.Posted                AS Posted,
	|	ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE) AS ThereIsGiftCertificate,
	|	BusinessTransactionsSettings.Ref   AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|		
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

	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure GetDocumentData(Query, DocumentRef)

	ListOfRequests = New Array;
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader = "SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CompanyRecipient AS CompanyRecipient,
	|	DocumentData.CashAccount AS CashAccount,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Issue AS Issue,
	|	DocumentData.Basis AS Basis,
	|	DocumentData.Application AS Application,
	|	DocumentData.ByDocument AS ByDocument,
	|	DocumentData.CashAccountRecipient AS CashAccountRecipient,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.PaymentRequest AS PaymentRequest,
	|	DocumentData.CashTransferReferenceOrder AS CashTransferReferenceOrder,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Author AS Author,
	|	DocumentData.CashRegister AS CashRegister,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.DoNotControlRequestFilling AS DoNotControlRequestFilling,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	DocumentData.CurrencyOfConversion AS CurrencyOfConversion,
	|	DocumentData.ConversionRate AS ConversionRate,
	|	DocumentData.ConversionAmount AS ConversionAmount,
	|	DocumentData.Statement AS Statement,
	|	DocumentData.Department AS Department,
	|	DocumentData.Director AS Director,
	|	DocumentData.ChiefAccountant AS ChiefAccountant,
	|	DocumentData.PaysheetNumber AS PaysheetNumber,
	|	DocumentData.PaysheetDate AS PaysheetDate,
	|	DocumentData.PaymentByRequests AS PaymentByRequests,
	|	DocumentData.EntriesByEmployees AS EntriesByEmployees,
	|	DocumentData.ExpenseReportDate AS ExpenseReportDate,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.ConversionRateMultiplier AS ConversionRateMultiplier,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.DocumentID AS DocumentID,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.Cashier AS Cashier,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.RegistrationPeriod AS RegistrationPeriod,
	|	DocumentData.CashAccount.EnableCreatingCashIssueWithoutPaymentRequest AS CashAccountAllowsPaymentsWithoutSpecifyingRequests,
	|	DocumentData.Counterparty.Partner AS CounterpartyPartner,
	|	DocumentData.CashAccountRecipient.LineOfBusiness AS CashAccountRecipientLineOfBusiness,
	|	DocumentData.CashAccountRecipient.Owner AS CashAccountRecipientOwner
	|INTO DocumentDataHeader
	|FROM
	|	Document.CashVoucher AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
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
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
	|	PaymentDecryptionTable.AmountARAP AS AmountARAP,
	|	PaymentDecryptionTable.ExpenseItem AS ExpenseItem,
	|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	PaymentDecryptionTable.Department AS Department,
	|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
	|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
	|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest,
	|	PaymentDecryptionTable.Comment AS Comment,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	PaymentDecryptionTable.RowID AS RowID,
	|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.EmployeeLoanAgreement AS EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
	|	PaymentDecryptionTable.Organization AS Organization,
	|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
	|	PaymentDecryptionTable.ExchangeRateNumeratorOfMutualSettlements AS ExchangeRateNumeratorOfMutualSettlements,
	|	PaymentDecryptionTable.TheExchangeRateIsTheDenominatorOfMutualSettlements AS TheExchangeRateIsTheDenominatorOfMutualSettlements,
	|	PaymentDecryptionTable.MaturityDate AS MaturityDate,
	|	PaymentDecryptionTable.ARAPObject.Organization AS ARAPObjectOfCompany,
	|	PaymentDecryptionTable.ARAPObject.Partner AS ARAPObjectIsPartner,
	|	PaymentDecryptionTable.ARAPObject.Contract AS ARAPObjectContract,
	|	PaymentDecryptionTable.ARAPObject.VATTaxation AS ARAPObjectTaxationOfVAT,
	|	PaymentDecryptionTable.ARAPObject.Department AS ObjectOfCalculationsDivision,
	|	PaymentDecryptionTable.ARAPObject.LineOfBusiness AS ARAPObjectLineOfBusiness,
	|	CASE WHEN PaymentDecryptionTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|			THEN
	|				VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE
	|			PaymentDecryptionTable.Partner
	|	END AS ARAPObjectOfPaymentIsPartner,
	|	PaymentDecryptionTable.LeaseContracts.LineOfBusiness AS LeaseContractLineOfBusiness,
	|	PaymentDecryptionTable.LeaseContracts.Department AS LeaseContractDivision,
	|	PaymentDecryptionTable.PaymentRequest.Currency AS PaymentRequestCurrency,
	|	PaymentDecryptionTable.ARAPObject.Object AS CalculationObjectObject,
	|	PaymentDecryptionTable.PaymentRequest.ControlPaymentByARAPObjects AS
	|		PaymentRequestToControlPaymentOfPaymentOfARAPObject
	|INTO DocumentDataTableDecryptionOfPayment
	|FROM
	|	Document.CashVoucher.ARAPDetails AS PaymentDecryptionTable
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                         Common.MetadataObjectID("Document.CashVoucher"));
	Values.Insert("UseCustomerCommercialInvoices",               GetFunctionalOption("UseCustomerCommercialInvoices"));
	Values.Insert("UsePaymentRequests", GetFunctionalOption("UsePaymentRequests"));
	Values.Insert("UseAccountingOfOtherIncomeExpenses",           GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Values.Insert("ControlIssueOfCashByPurposes",       GetFunctionalOption("ControlIssueOfCashByPurposes"));
	Values.Insert("UsePayroll",                  Constants.UsePayroll.Get()
		Or GetFunctionalOption("PayrollAndHumanResourcesWE"));
	Values.Insert("UseCashFlowLimits",        GetFunctionalOption("UseCashFlowLimits"));
	Values.Insert("UseExpenseLimitsForOrganizations",         GetFunctionalOption("UseCashFlowLimitsByCompanies"));
	Values.Insert("UseExpenseLimitsByDivision",       GetFunctionalOption("UseCashFlowLimitsByBusinessUnit"));
	Values.Insert("UseAccountingOfOtherAssetsAndLiabilities",           GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	Values.Insert("ManagementAccountingCurrency",                      Constants.ManagementAccountingCurrency.Get());
	
	If Attributes <> Undefined Then
		
		Values.Insert("CashFlowItem",               CashFlowArticleOfDocument(Attributes));
		
		ArrayOfRequests = Attributes.ARAPDetails.Unload().UnloadColumn("PaymentRequest"); // Array
		ArrayOfRequests.Add(Attributes.PaymentRequest);
		ArrayOfRequests.Add(Attributes.CashTransferReferenceOrder);
		Values.Insert("ArrayOfRequests",                                ArrayOfRequests);
		
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency,
			Attributes.RequestCurrency,
			Attributes.Period,
			Attributes.Organization);
			
		ConversionFactors = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.CurrencyOfConversion,
			Undefined,
			Attributes.Period,
			Attributes.Organization);
			
		Values.Insert("ConversionRateToManCurrency",              Coefficients.ConversionRateToManCurrency);
		Values.Insert("FactorOfConversionToCurrencyOfRegul",             Coefficients.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("ConversionRateToApplicationCurrency",           Coefficients.ConversionRateToSettlementCurrency);
		Values.Insert("ConversionFactorOfConversionToCurrencyMan",   ConversionFactors.ConversionRateToManCurrency);
		Values.Insert("ConversionRateOfConversionToLocalCurrency",  ConversionFactors.FactorOfConversionToCurrencyOfRegul);
		
		Values.Insert("NumberForPrinting",                               ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		Values.Insert("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
		Values.Insert("InitiatorDivision", DocumentSubdivision(Attributes));
		
	EndIf;
	
	Return Values;
	
EndFunction

Procedure InitializeTrackingAnalyticsKeysForPartners(Query, DocumentObject = Undefined)

	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	RequestForAnalytics = New Query;
	RequestForAnalytics.TempTablesManager = Query.TempTablesManager;
	
	RequestForAnalytics.Text ="";
	If Not (RequestForAnalytics.TempTablesManager <> Undefined 
		And RequestForAnalytics.TempTablesManager.Tables.Find("TTTableOfCalculationObjects") <> Undefined) Then
		
		RequestForAnalytics.Text = RequestTextTemporaryTableOfCalculationObjects(RequestForAnalytics, New ValueList, DocumentObject);
		RequestForAnalytics.Text = RequestForAnalytics.Text + "
		|;
		|/////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
	RequestForAnalytics.Text = StrReplace(RequestForAnalytics.Text, "INTO TableOfCalculationObjects", "INTO TTTableOfCalculationObjects");
	
	QueryTextForAnalytics = "
	|SELECT DISTINCT
	|	TableOfCalculationObjects.Organization AS Organization,
	|	&Counterparty                         AS Counterparty,
	|	PaymentDecryptionTable.Partner   AS Partner,
	|	TableOfCalculationObjects.Contract     AS Contract,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|		INNER JOIN TTTableOfCalculationObjects AS TableOfCalculationObjects
	|		ON PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		TableOfCalculationObjects.Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND PaymentDecryptionTable.Partner = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	TableOfCalculationObjects.Contract AS Contract,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|		INNER JOIN TTTableOfCalculationObjects AS TableOfCalculationObjects
	|		ON PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND PaymentDecryptionTable.Partner = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND TableOfCalculationObjects.Organization <> &Organization
	|	AND PaymentDecryptionTable.PaymentRequest <> VALUE(Document.PaymentRequest.EmptyRef)
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	INNER JOIN Catalog.LoanAndDepositContracts AS ContractData
	|		ON PaymentDecryptionTable.LoanDepositContract = ContractData.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND PaymentDecryptionTable.Partner = Dimension.Partner
	|		AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = Dimension.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef)= Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|		VALUE(Enum.BusinessTransactions.TransferToDeposits),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty)
	|	)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	INNER JOIN Catalog.LeaseContract AS ContractData
	|		ON PaymentDecryptionTable.LeaseContracts = ContractData.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND PaymentDecryptionTable.Partner = Dimension.Partner
	|		AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = Dimension.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|	)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
	|	TableOfCalculationObjects.Contract AS Contract,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|
	|	LEFT JOIN
	|		TTTableOfCalculationObjects AS TableOfCalculationObjects
	|	ON
	|		PaymentDecryptionTable.ARAPObject = TableOfCalculationObjects.ARAPObject
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND VALUE(Catalog.Partners.OurEnterprise) = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany))
	|	AND Dimension.DimensionKey IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	PaymentTable_2.Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	&Partner AS Partner,
	|	&Contract AS Contract,
	|	&LineOfBusiness AS LineOfBusiness
	|FROM
	|	DocumentDataHeader AS PaymentTable_2
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		PaymentTable_2.Organization= Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND &Partner = Dimension.Partner
	|		AND &Contract = Dimension.Contract
	|		AND &LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentTable_2.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|		)
	|";
	
	If DocumentObject = Undefined Then
		QueryTextForAnalytics = StrReplace(QueryTextForAnalytics, "DocumentDataTableDecryptionOfPayment", "Document.CashVoucher.ARAPDetails");
		QueryTextForAnalytics = StrReplace(QueryTextForAnalytics, "DocumentDataHeader", "Document.CashVoucher");
	EndIf;
	
	RequestForAnalytics.Text = RequestForAnalytics.Text + QueryTextForAnalytics;
	
	RequestForAnalytics.SetParameter("Ref",                  Query.Parameters.Ref);
	RequestForAnalytics.SetParameter("Organization",             Query.Parameters.Organization);
	RequestForAnalytics.SetParameter("Counterparty",              Query.Parameters.Counterparty);
	RequestForAnalytics.SetParameter("Partner",                 Query.Parameters.Partner);
	RequestForAnalytics.SetParameter("LineOfBusiness", Query.Parameters.LineOfBusiness);
	RequestForAnalytics.SetParameter("BusinessOperation",   Query.Parameters.BusinessOperation);
	
	If ValueIsFilled(Query.Parameters.Contract) Then
		RequestForAnalytics.SetParameter("Contract",                         Query.Parameters.Contract);
	ElsIf Not ValueIsFilled(Query.Parameters.Contract)
			And Query.Parameters.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToAnotherCompany") Then
		RequestForAnalytics.SetParameter("Contract",                         Catalogs.IntercompanyContracts.EmptyRef());
	Else
		RequestForAnalytics.SetParameter("Contract",                         Catalogs.CounterpartyContracts.EmptyRef());
	EndIf;

	Selection = RequestForAnalytics.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	StructureOfAnalytics = New Structure("Organization, Partner, Counterparty, Contract, LineOfBusiness");
	FillPropertyValues(StructureOfAnalytics, Query.Parameters);
	StructureOfAnalytics.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
	StructureOfAnalytics.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	
	If Query.Parameters.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or Query.Parameters.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
	Then
		StructureOfAnalytics.Insert("Contract", Catalogs.IntercompanyContracts.EmptyRef());
		AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureOfAnalytics);
		
		StructureOfAnalytics.Insert("Organization", Query.Parameters.Counterparty);
		StructureOfAnalytics.Insert("Counterparty",  Query.Parameters.Organization);
		AnalyticsOfAccountingByPartnersRecipient = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureOfAnalytics);
		
	ElsIf Query.Parameters.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount
		Or Query.Parameters.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToEmployee
		Or Query.Parameters.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByDistributor Then
		
		StructureOfAnalytics.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
		StructureOfAnalytics.Insert("Partner",    Catalogs.Partners.EmptyRef());
		AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureOfAnalytics);
		AnalyticsOfAccountingByPartnersRecipient = Undefined;
	EndIf;
	
	If ARAPAccountingServer.BusinessOperationRefundOfFunds(Query.Parameters.BusinessOperation) Then
		AnalysisOfAccountingByPartnersObjectOfSettlement = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(RequestForAnalytics.Parameters);
	Else
		AnalysisOfAccountingByPartnersObjectOfSettlement = Undefined;
	EndIf;
	
	Query.SetParameter("AccountingDimensionByPartners",           AccountingDimensionByPartners);
	Query.SetParameter("AnalyticsOfAccountingByPartnersRecipient", AnalyticsOfAccountingByPartnersRecipient);
	Query.SetParameter("AnalysisOfAccountingByPartnersObjectOfSettlement", AnalysisOfAccountingByPartnersObjectOfSettlement);
	
EndProcedure

Function RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject = Undefined) Export
	
	TempTableName = "PaymentDecryptionTable";
	
	InitializeTrackingAnalyticsKeysForPartners(Query, DocumentObject);
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfCalculationObjects", QueryTexts) Then
		RequestTextTemporaryTableOfCalculationObjects(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	Dimension.Organization AS Organization,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	ISNULL(TableOfCalculationObjects.Contract, UNDEFINED) AS Contract,
	|
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|			THEN PaymentDecryptionTable.LineOfBusiness
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|			THEN PaymentDecryptionTable.LeaseContractLineOfBusiness
	|	ELSE 
	|		TableOfCalculationObjects.LineOfBusiness
	|	END AS LineOfBusiness,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|		THEN PaymentDecryptionTable.ExpenseItem 
	|	ELSE 
	|		UNDEFINED
	|	END AS ExpenseItem,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|		THEN PaymentDecryptionTable.DimensionOfExpenses 
	|	ELSE 
	|		UNDEFINED
	|	END AS DimensionOfExpenses,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|		THEN PaymentDecryptionTable.AssetsLiabilitiesDimension 
	|	WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee)
	|		THEN &AdvanceHolder
	|	ELSE 
	|		UNDEFINED
	|	END AS AssetsLiabilitiesDimension,
	|	CASE 
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|			THEN PaymentDecryptionTable.Department
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|			THEN PaymentDecryptionTable.LeaseContractDivision 
	|		ELSE UNDEFINED 
	|	END AS Department,
	|	ISNULL(TableOfCalculationObjects.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS OrderDivision_,
	|
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|
	|	PaymentDecryptionTable.LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType,
	|	PaymentDecryptionTable.EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest,
	|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
	|
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &LocalAccountingCurrency AND &Currency <> &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|	CASE WHEN &Currency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS VATAmountMan,
	|	CASE WHEN &Currency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS VATAmountCompl,
	|
	|	ISNULL(TableOfCalculationObjects.VATTaxation, VALUE(Enum.VATTaxationTypes.EmptyRef)) AS VATTaxation,
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|
	|	PaymentDecryptionTable.RowID AS RowID
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
	|		AND &Counterparty = Dimension.Counterparty
	|		AND PaymentDecryptionTable.Partner = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract 
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND NOT &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty),
	|		VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	&Organization AS Organization,
	|	UNDEFINED AS ARAPObject,
	|	CASE
	|		WHEN PaymentDecryptionTable.Partner <> VALUE(Catalog.Partners.EmptyRef) THEN
	|			PaymentDecryptionTable.Partner
	|		ELSE
	|			DocumentData.CounterpartyPartner
	|	END AS Partner,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|
	|	ContractData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS Department,
	|	ContractData.Department AS OrderDivision_,
	|
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|
	|	PaymentDecryptionTable.LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest,
	|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
	|
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &LocalAccountingCurrency AND &Currency <> &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|	CASE WHEN &Currency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS VATAmountMan,
	|	CASE WHEN &Currency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS VATAmountCompl,
	|
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|
	|	PaymentDecryptionTable.RowID AS RowID
	|
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON PaymentDecryptionTable.Ref = DocumentData.Ref
	|
	|	INNER JOIN Catalog.LoanAndDepositContracts AS ContractData
	|		ON PaymentDecryptionTable.LoanDepositContract = ContractData.Ref
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND CASE
	|			WHEN PaymentDecryptionTable.Partner <> VALUE(Catalog.Partners.EmptyRef) THEN
	|				PaymentDecryptionTable.Partner
	|			ELSE
	|				DocumentData.CounterpartyPartner
	|		END = Dimension.Partner
	|		AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = Dimension.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty)
	|	)
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	&Organization AS Organization,
	|	UNDEFINED AS ARAPObject,
	|	CASE
	|		WHEN PaymentDecryptionTable.Partner <> VALUE(Catalog.Partners.EmptyRef) THEN
	|			PaymentDecryptionTable.Partner
	|		ELSE
	|			DocumentData.CounterpartyPartner
	|	END AS Partner,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|
	|	ContractData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS Department,
	|	ContractData.Department AS OrderDivision_,
	|
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	PaymentDecryptionTable.LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest,
	|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
	|
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &LocalAccountingCurrency AND &Currency <> &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|	CASE WHEN &Currency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS VATAmountMan,
	|	CASE WHEN &Currency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS VATAmountCompl,
	|
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|
	|	PaymentDecryptionTable.RowID AS RowID
	|
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON PaymentDecryptionTable.Ref = DocumentData.Ref
	|
	|	INNER JOIN Catalog.LeaseContract AS ContractData
	|		ON PaymentDecryptionTable.LeaseContracts = ContractData.Ref
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND CASE
	|			WHEN PaymentDecryptionTable.Partner <> VALUE(Catalog.Partners.EmptyRef) THEN
	|				PaymentDecryptionTable.Partner
	|			ELSE
	|				DocumentData.CounterpartyPartner
	|		END = Dimension.Partner
	|		AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = Dimension.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|	)
	|
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	TableOfCalculationObjects.Organization AS Organization,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	TableOfCalculationObjects.Contract AS Contract,
	|
	|	ISNULL(TableOfCalculationObjects.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS Department,
	|	TableOfCalculationObjects.Department AS OrderDivision_,
	|
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|
	|	PaymentDecryptionTable.LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType,
	|	PaymentDecryptionTable.EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest,
	|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
	|
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &LocalAccountingCurrency AND &Currency <> &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		ELSE CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|	CASE WHEN &Currency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS VATAmountMan,
	|	CASE WHEN &Currency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS VATAmountCompl,
	|
	|	TableOfCalculationObjects.VATTaxation AS VATTaxation,
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|
	|	PaymentDecryptionTable.RowID AS RowID
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
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND VALUE(Catalog.Partners.OurEnterprise) = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	1,
	|	CashVoucher.Organization,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	CashVoucher.Department,
	|	CashVoucher.Department,
	|	CashVoucher.DocumentAmount,
	|	CashVoucher.DocumentAmount,
	|	CashVoucher.Currency,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	CashVoucher.CashFlowItem,
	|	CashVoucher.PaymentRequest,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef),
	|	CAST(CashVoucher.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)),
	|	CAST(CashVoucher.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)),
	|	UNDEFINED,
	|	0,
	|	0,
	|	0,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	UNDEFINED,
	|
	|	CashVoucher.DocumentID AS RowID
	|
	|FROM
	|	DocumentDataHeader AS CashVoucher
	|WHERE
	|	CashVoucher.Ref = &Ref
	|	AND CashVoucher.BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee)
	|	AND NOT &UsePayroll
	|";
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.CashVoucher");
		QueryText = StrReplace(QueryText, "DocumentDataTableDecryptionOfPayment", "Document.CashVoucher.ARAPDetails");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.LeaseContractLineOfBusiness", "PaymentDecryptionTable.LeaseContracts.LineOfBusiness");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.LeaseContractDivision", "PaymentDecryptionTable.LeaseContracts.Department");
		QueryText = StrReplace(QueryText, "DocumentData.CounterpartyPartner", "DocumentData.Counterparty.Partner");
	
	EndIf;
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTemporaryTableOfCalculationObjects(Query, QueryTexts, DocumentObject = Undefined) Export
	
	TempTableName = "TableOfCalculationObjects";
	
	QueryText = "
	|SELECT DISTINCT
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|
	|	PaymentDecryptionTable.ARAPObjectOfCompany AS Organization,
	|	PaymentDecryptionTable.ARAPObjectIsPartner AS Partner,
	|	PaymentDecryptionTable.ARAPObjectContract AS Contract,
	|	PaymentDecryptionTable.ARAPObjectTaxationOfVAT AS VATTaxation,
	|	PaymentDecryptionTable.ObjectOfCalculationsDivision AS Department,
	|	CASE WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|					VALUE(Enum.BusinessTransactions.RefundToAnotherCompany))
	|				AND ISNULL(Directions.IncomeAccounting, FALSE)
	|			OR NOT &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|					VALUE(Enum.BusinessTransactions.RefundToAnotherCompany))
	|				AND ISNULL(Directions.VendorARAP, FALSE)
	|		THEN
	|			PaymentDecryptionTable.ARAPObjectLineOfBusiness
	|	ELSE
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness
	|
	|INTO TableOfCalculationObjects
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|	LEFT JOIN Catalog.LinesOfBusiness AS Directions
	|	ON PaymentDecryptionTable.ARAPObjectLineOfBusiness = Directions.Ref
	|	
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND NOT &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty),
	|		VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|		)
	|
	|INDEX BY
	|	ARAPObject
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableDecryptionOfPayment", "Document.CashVoucher.ARAPDetails");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectOfCompany", "PaymentDecryptionTable.ARAPObject.Organization");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectIsPartner", "PaymentDecryptionTable.ARAPObject.Partner");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectContract", "PaymentDecryptionTable.ARAPObject.Contract");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectTaxationOfVAT", "PaymentDecryptionTable.ARAPObject.VATTaxation");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ObjectOfCalculationsDivision", "PaymentDecryptionTable.ARAPObject.Department");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectLineOfBusiness", "PaymentDecryptionTable.ARAPObject.LineOfBusiness");
	EndIf;
		
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashAccountBalance(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashAccountBalance";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "";
	
	If Not DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount Then
	
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber AS LineNumber,
		|	DocumentData.Date AS Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.CashAccount AS CashAccount,
		|	
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	CASE WHEN &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
		|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
		|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
		|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
		|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
		|		VALUE(Enum.BusinessTransactions.OtherCashIssue),
		|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
		|		VALUE(Enum.BusinessTransactions.TransferToDeposits),
		|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee),
		|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty))
		|	THEN
		|		PaymentDecryptionTable.CashFlowItem
		|	ELSE
		|		&CashFlowItem
		|	END AS CashFlowItem,
		|
		|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	
		|	CASE WHEN DocumentData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
		|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
		|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived), 
		|		VALUE(Enum.BusinessTransactions.TransferToDeposits), 
		|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty),
		|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
		|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany))
		|	THEN
		|		PaymentDecryptionTable.AccountingDimensionByPartners
		|	ELSE
		|		UNDEFINED
		|	END AS AccountingDimensionByPartners,
		|	
		|	ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount) AS Sum,
		|	
		|	CASE WHEN PaymentDecryptionTable.Sum IS NULL
		|		THEN CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) 
		|		ELSE PaymentDecryptionTable.SumCompl
		|	END AS SumCompl,
		|	
		|	CASE 
		|		WHEN PaymentDecryptionTable.Sum IS NULL
		|			THEN CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) 
		|		ELSE PaymentDecryptionTable.SumMan
		|	END AS SumMan,
		|	
		|	CASE WHEN  DocumentData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices),
		|		VALUE(Enum.BusinessTransactions.CurrencyConversion),
		|		VALUE(Enum.BusinessTransactions.CashCollectionToBank),
		|		VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount),
		|		VALUE(Enum.BusinessTransactions.CashIssueToCashRegister))
		|	THEN 
		|		DocumentData.DocumentID
		|	ELSE
		|		ISNULL(PaymentDecryptionTable.RowID, DocumentData.DocumentID)
		|	END AS FinRecordID,
		|	
		|	CASE
		|		WHEN FALSE
		|			THEN UNDEFINED
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
		|			THEN CASE PaymentDecryptionTable.TypeOfLeasePayment
		|				WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.PaymentForLeaseServices)
		|				WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.PaymentForLeaseServices)
		|				WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.SecurityPayment)
		|				WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.LeaseBuyoutValuePayment)
		|				WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.LeaseBuyoutValuePrepayment)
		|				ELSE &BusinessTransactionSetting
		|			END
		|		ELSE &BusinessTransactionSetting
		|	END AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|
		|ORDER BY
		|	PaymentDecryptionTable.LineNumber
		|";
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount Then
	
		QueryText = "
		|SELECT
		|	1 AS LineNumber,
		|	DocumentData.Date AS Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.CashAccount AS CashAccount,
		|	
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	&CashFlowItem AS CashFlowItem,
		|
		|	UNDEFINED AS ARAPObject,
		|	UNDEFINED AS AccountingDimensionByPartners,
		|	
		|	DocumentData.DocumentAmount AS Sum,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
		|	
		|	DocumentData.DocumentID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|ORDER BY
		|	LineNumber
		|";
	
	EndIf;
	
	If QueryText = "" Then
		Return "";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableBankAccountCash(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "BankAccountCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.BankAccount AS BankAccount,
	|	
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	&CashFlowItem AS CashFlowItem,
	|	
	|	UNDEFINED AS AccountingDimensionByPartners,
	|	
	|	DocumentData.DocumentAmount AS Sum,
	|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	
	|	&Ref AS PaymentDocument,
	|	
	|	DocumentData.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CashDepositToBankAccount) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataHeader AS DocumentData
	|
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextCashInTransit(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueToAnotherCashAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashCollectionToBank
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion) Then
		Return "";
	EndIf;
	
	QueryText = "";
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueToAnotherCashAccount Then
		
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                      AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	DocumentData.CashAccountRecipient                                             AS Recipient,
		|	CASE
		|		WHEN VALUETYPE(DocumentData.CashAccountRecipient) = TYPE(Catalog.CashAccounts) THEN
		|			DocumentData.CashAccount
		|		ELSE
		|			UNDEFINED
		|	END AS Sender,
		|	VALUE(Enum.CashTransferKinds.TransferToAnotherCashAccount) AS CashTransferKind,
		|	UNDEFINED                                                                AS Counterparty,
		|	DocumentData.Currency                                                      AS Currency,
		|	
		|	DocumentData.DocumentAmount                                              AS Sum,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))   AS SumMan,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))  AS SumCompl,
		|	
		|	&BusinessOperation                                                      AS BusinessOperation,
		|	&CashFlowItem                                              AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                      AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CashIssueToAnotherCashAccount) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashCollectionToBank Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                      AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	DocumentData.BankAccount                                              AS Recipient,
		|	DocumentData.CashAccount                                                       AS Sender,
		|	VALUE(Enum.CashTransferKinds.CashDepositToBank)         AS CashTransferKind,
		|	UNDEFINED                                                                AS Counterparty,
		|	DocumentData.Currency                                                      AS Currency,
		|	
		|	DocumentData.DocumentAmount                                              AS Sum,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))   AS SumMan,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))  AS SumCompl,
		|	
		|	&BusinessOperation                                                      AS BusinessOperation,
		|	&CashFlowItem                                              AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                      AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CashCollectionToBank) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                      AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	DocumentData.CashAccountRecipient                                             AS Recipient,
		|	UNDEFINED                                                                AS Sender,
		|	CASE WHEN DocumentData.Currency = &LocalAccountingCurrency
		|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
		|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
		|	END                                                                       AS CashTransferKind,
		|	Counterparty                                                                  AS Counterparty,
		|	DocumentData.Currency                                                      AS Currency,
		|	
		|	DocumentData.DocumentAmount                                              AS Sum,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency            AS SumMan,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul           AS SumCompl,
		|	
		|	&BusinessOperation                                                      AS BusinessOperation,
		|	&CashFlowItem                                              AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                      AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversion) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
	EndIf;
	
	If QueryText = "" Then
		Return "";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashInCashRegistersCR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueToCashRegister Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CashRegister AS CashRegister,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.DocumentAmount AS Sum,
	|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	&BusinessOperation,
	|	&CashFlowItem,
	|	
	|	DocumentData.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CashIssueToCashRegister) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataHeader AS DocumentData
	|
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "AdvanceHolderCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.Department AS Department,
	|	DocumentData.CashAccount.CashCurrency AS Currency,
	|	
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		PaymentDecryptionTable.CashFlowItem
	|	END AS IssuancePurpose,
	|
	|	&BusinessOperation AS BusinessOperation,
	|	PaymentDecryptionTable.CashFlowItem,
	|	ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount) AS Sum,
	|	CASE WHEN PaymentDecryptionTable.Sum IS NULL 
	|		THEN CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE PaymentDecryptionTable.SumCompl
	|	END AS SumCompl,
	|	CASE WHEN PaymentDecryptionTable.Sum IS NULL 
	|		THEN CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE PaymentDecryptionTable.SumMan
	|	END AS SumMan,
	|	0 AS ToReport,
	|	
	|	PaymentDecryptionTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IssueCashToAdvanceHolder) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|	LEFT JOIN 
	|		PaymentDecryptionTable AS PaymentDecryptionTable
	|	ON
	|		TRUE
	|
	|UNION ALL
	|
	|SELECT
	|	ENDOFPERIOD(DocumentData.ExpenseReportDate, DAY) AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.Department AS Department,
	|	DocumentData.CashAccount.CashCurrency AS Currency,
	|	
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		PaymentDecryptionTable.CashFlowItem
	|	END AS IssuancePurpose,
	|
	|	&BusinessOperation AS BusinessOperation,
	|	PaymentDecryptionTable.CashFlowItem,
	|	0 AS Sum,
	|	0 AS SumCompl,
	|	0 AS SumMan,
	|	ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount) AS ToReport,
	|	
	|	PaymentDecryptionTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IssueCashToAdvanceHolder) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|	LEFT JOIN 
	|		PaymentDecryptionTable AS PaymentDecryptionTable
	|	ON
	|		TRUE
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
	|SELECT // Application in decryption
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DecryptionRequests.PaymentRequest AS PaymentRequest,
	|	DocumentData.CashAccount AS BankAccountCashAccount,
	|	CASE
	|		WHEN DecryptionRequests.PaymentRequest REFS Document.PaymentRequest THEN
	|			CASE WHEN CAST(DecryptionRequests.PaymentRequest AS Document.PaymentRequest).PersonsList THEN
	|				UNDEFINED
	|			ELSE
	|				&Recipient
	|			END
	|		ELSE
	|			&Recipient
	|	END AS Recipient,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN DecryptionRequests.Sum <
	|			SUM(CASE
	|				WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN Cash.Sum
	|				ELSE -Cash.Sum
	|			END)
	|		THEN
	|			DecryptionRequests.Sum
	|		ELSE
	|			SUM(CASE
	|				WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN Cash.Sum
	|				ELSE -Cash.Sum
	|			END)
	|	END AS Sum,
	|	&BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|	LEFT JOIN (
	|		SELECT
	|			DocumentData.Ref AS Ref,
	|			DocumentData.PaymentRequest AS PaymentRequest,
	|			SUM(CASE
	|				WHEN &Currency <> DocumentData.PaymentRequestCurrency THEN
	|						DocumentData.AmountARAP
	|					ELSE
	|						DocumentData.Sum
	|				END) AS Sum
	|			FROM
	|				DocumentDataTableDecryptionOfPayment AS DocumentData
	|		WHERE
	|			DocumentData.Ref = &Ref
	|			AND DocumentData.PaymentRequest <> VALUE(Document.PaymentRequest.EmptyRef)
	|			AND DocumentData.PaymentRequest <> UNDEFINED
	|		GROUP BY
	|			DocumentData.Ref,
	|			DocumentData.PaymentRequest
	|		) AS DecryptionRequests
	|	ON
	|		DecryptionRequests.Ref = DocumentData.Ref
	|
	|	LEFT JOIN
	|		AccumulationRegister.CashToBePaid AS Cash
	|	ON
	|		Cash.PaymentRequest = DecryptionRequests.PaymentRequest
	|		AND Cash.BankAccountCashAccount = DocumentData.CashAccount
	|		AND Cash.Recorder <> DocumentData.Ref
	|		AND Cash.Active
	|		AND Cash.Recorder <> &ReversedDocument
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT DecryptionRequests.Ref IS NULL
	|	AND &UsePaymentRequests
	|	
	|GROUP BY
	|	DocumentData.Ref,
	|	DecryptionRequests.PaymentRequest,
	|	CASE
	|		WHEN DecryptionRequests.PaymentRequest REFS Document.PaymentRequest THEN
	|			CASE WHEN CAST(DecryptionRequests.PaymentRequest AS Document.PaymentRequest).PersonsList THEN
	|				UNDEFINED
	|			ELSE
	|				&Recipient
	|			END
	|		ELSE
	|			&Recipient
	|	END,
	|	DecryptionRequests.Sum,
	|	DocumentData.CashAccount
	|
	|HAVING
	|	SUM(CASE
	|		WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Cash.Sum
	|		ELSE -Cash.Sum
	|	END) <> 0
	|	
	|UNION ALL
	|	
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DecryptionRequests.PaymentRequest AS PaymentRequest,
	|	UNDEFINED AS BankAccountCashAccount,
	|	CASE
	|		WHEN DecryptionRequests.PaymentRequest REFS Document.PaymentRequest THEN
	|			CASE WHEN CAST(DecryptionRequests.PaymentRequest AS Document.PaymentRequest).PersonsList THEN
	|				UNDEFINED
	|			ELSE
	|				&Recipient
	|			END
	|		ELSE
	|			&Recipient
	|	END AS Recipient,
	|	&Organization AS Organization,
	|	DecryptionRequests.Sum -
	|		ISNULL(SUM(CASE
	|			WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Cash.Sum
	|			ELSE -Cash.Sum
	|		END), 0) AS Sum,
	|	&BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|	LEFT JOIN (
	|		SELECT
	|			DocumentData.Ref AS Ref,
	|			DocumentData.PaymentRequest AS PaymentRequest,
	|			SUM(CASE
	|				WHEN &Currency <> DocumentData.PaymentRequestCurrency THEN
	|						DocumentData.AmountARAP
	|					ELSE
	|						DocumentData.Sum
	|				END) AS Sum
	|			FROM
	|				DocumentDataTableDecryptionOfPayment AS DocumentData
	|		WHERE
	|			DocumentData.Ref = &Ref
	|			AND DocumentData.PaymentRequest <> VALUE(Document.PaymentRequest.EmptyRef)
	|			AND DocumentData.PaymentRequest <> UNDEFINED
	|		GROUP BY
	|			DocumentData.Ref,
	|			DocumentData.PaymentRequest
	|		) AS DecryptionRequests
	|	ON
	|		DecryptionRequests.Ref = DocumentData.Ref
	|
	|	LEFT JOIN
	|		AccumulationRegister.CashToBePaid AS Cash
	|	ON
	|		Cash.PaymentRequest = DecryptionRequests.PaymentRequest
	|		AND Cash.BankAccountCashAccount = DocumentData.CashAccount
	|		AND Cash.Recorder <> DocumentData.Ref
	|		AND Cash.Active
	|		AND Cash.Recorder <> &ReversedDocument
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT DecryptionRequests.Ref IS NULL
	|	AND &UsePaymentRequests
	|	
	|GROUP BY
	|	DocumentData.Ref,
	|	DecryptionRequests.PaymentRequest,
	|	CASE
	|		WHEN DecryptionRequests.PaymentRequest REFS Document.PaymentRequest THEN
	|			CASE WHEN CAST(DecryptionRequests.PaymentRequest AS Document.PaymentRequest).PersonsList THEN
	|				UNDEFINED
	|			ELSE
	|				&Recipient
	|			END
	|		ELSE
	|			&Recipient
	|	END,
	|	DecryptionRequests.Sum,
	|	DocumentData.CashAccount
	|	
	|HAVING
	|	DecryptionRequests.Sum >
	|		ISNULL(SUM(CASE
	|			WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Cash.Sum
	|			ELSE -Cash.Sum
	|		END), 0)
	|	
	|UNION ALL
	|	
	|SELECT // Application in the header
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.PaymentRequest AS PaymentRequest,
	|	DocumentData.CashAccount AS BankAccountCashAccount,
	|	&Recipient AS Recipient,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN DocumentData.DocumentAmount <
	|			SUM(CASE
	|				WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN Cash.Sum
	|				ELSE -Cash.Sum
	|			END)
	|		THEN
	|			DocumentData.DocumentAmount
	|		ELSE
	|			SUM(CASE
	|				WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN Cash.Sum
	|				ELSE -Cash.Sum
	|			END)
	|	END AS Sum,
	|	&BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|	LEFT JOIN
	|		DocumentDataTableDecryptionOfPayment AS Details
	|	ON
	|		Details.Ref = DocumentData.Ref
	|	
	|	LEFT JOIN
	|		AccumulationRegister.CashToBePaid AS Cash
	|	ON
	|		Cash.PaymentRequest = DocumentData.PaymentRequest
	|		AND Cash.BankAccountCashAccount = DocumentData.CashAccount
	|		AND Cash.Recorder <> DocumentData.Ref
	|		AND Cash.Active
	|		AND Cash.Recorder <> &ReversedDocument
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.PaymentRequest <> VALUE(Document.PaymentRequest.EmptyRef)
	|	AND DocumentData.PaymentRequest <> UNDEFINED
	|	AND Details.Ref IS NULL
	|	AND &UsePaymentRequests
	|	
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.PaymentRequest,
	|	DocumentData.CashAccount,
	|	DocumentData.DocumentAmount
	|
	|HAVING
	|	SUM(CASE
	|		WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Cash.Sum
	|		ELSE -Cash.Sum
	|	END) <> 0
	|	
	|UNION ALL
	|	
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.PaymentRequest AS PaymentRequest,
	|	UNDEFINED AS BankAccountCashAccount,
	|	&Recipient AS Recipient,
	|	&Organization AS Organization,
	|	DocumentData.DocumentAmount -
	|		ISNULL(SUM(CASE
	|			WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Cash.Sum
	|			ELSE -Cash.Sum
	|		END), 0) AS Sum,
	|	&BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|	LEFT JOIN
	|		DocumentDataTableDecryptionOfPayment AS Details
	|	ON
	|		Details.Ref = DocumentData.Ref
	|
	|	LEFT JOIN
	|		AccumulationRegister.CashToBePaid AS Cash
	|	ON
	|		Cash.PaymentRequest = DocumentData.PaymentRequest
	|		AND Cash.BankAccountCashAccount = DocumentData.CashAccount
	|		AND Cash.Recorder <> DocumentData.Ref
	|		AND Cash.Active
	|		AND Cash.Recorder <> &ReversedDocument
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.PaymentRequest <> VALUE(Document.PaymentRequest.EmptyRef)
	|	AND DocumentData.PaymentRequest <> UNDEFINED
	|	AND Details.Ref IS NULL
	|	AND &UsePaymentRequests
	|	
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.PaymentRequest,
	|	DocumentData.CashAccount,
	|	DocumentData.DocumentAmount
	|	
	|HAVING
	|	DocumentData.DocumentAmount >
	|		ISNULL(SUM(CASE
	|			WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Cash.Sum
	|			ELSE -Cash.Sum
	|		END), 0)
	|	
	|UNION ALL
	|	
	|SELECT // Available to move
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.CashTransferReferenceOrder AS PaymentRequest,
	|	DocumentData.CashAccount AS BankAccountCashAccount,
	|	&Organization AS Recipient,
	|	&Organization AS Organization,
	|	DocumentData.DocumentAmount AS Sum,
	|	&BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CashTransferReferenceOrder <> VALUE(Document.CashTransferReferenceOrder.EmptyRef)
	|	AND &UsePaymentRequests
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashDepositToBankAccount),
	|		VALUE(Enum.BusinessTransactions.CashCollectionToBank),
	|		VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount)
	|		)
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.CashVoucher");
		QueryText = StrReplace(QueryText, "DocumentDataTableDecryptionOfPayment", "Document.CashVoucher.ARAPDetails");
		QueryText = StrReplace(QueryText, "DocumentData.PaymentRequestCurrency", "DocumentData.PaymentRequest.Currency");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Query.Parameters.Property("UsePayroll") Then
		UsePayroll = Query.Parameters.UsePayroll;
	Else
		UsePayroll = Constants.UsePayroll.Get()
			Or GetFunctionalOption("PayrollAndHumanResourcesWE");
	EndIf;
	
	OtherAssetsLiabilities = False;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
		OtherAssetsLiabilities = True;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByDistributor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToEmployee)
		And Not UsePayroll Then
			
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	&Organization AS Organization,
		|	UNDEFINED AS Department,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS AssetRef,
		|	UNDEFINED AS Dimension,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
	
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	&Organization AS Organization,
		|	PaymentDecryptionTable.Department AS Department,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|	PaymentDecryptionTable.ExpenseItem AS AssetRef,
		|	CASE
		|		WHEN PaymentDecryptionTable.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE PaymentDecryptionTable.AssetsLiabilitiesDimension
		|	END AS Dimension,
		|	SUM(CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))) AS Sum
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON TRUE
		|WHERE
		|	PaymentDecryptionTable.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
		|	
		|GROUP BY
		|	PaymentDecryptionTable.ExpenseItem,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension,
		|	PaymentDecryptionTable.LineOfBusiness,
		|	PaymentDecryptionTable.Department
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee Then
	
		// Issuing loans to an employee
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	&Organization AS Organization,
		|	UNDEFINED AS Department,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings) AS AssetRef,
		|	UNDEFINED AS Dimension,
		|	SUM(CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))) AS Sum
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee)
		|
		|HAVING
		|	SUM(CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)))> 0
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	If OtherAssetsLiabilities Then
		ArrayOfRequestTexts.Add(AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities(False));
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SettlementWithBranches = False;
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany) Then
		SettlementWithBranches = True;
	EndIf;
	
	If Query.Parameters.Property("UsePayroll") Then
		UsePayroll = Query.Parameters.UsePayroll;
	Else
		UsePayroll = Constants.UsePayroll.Get()
			Or GetFunctionalOption("PayrollAndHumanResourcesWE");
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If SettlementWithBranches And Not DocumentsPosting.ThereIsQueryTable("TTMovementCounterpartyCounterparty", QueryTexts) Then
		RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByDistributor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToEmployee)
		And Not UsePayroll Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	UNDEFINED AS Department,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS AssetRef,
		|	UNDEFINED AS Dimension,
		|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
		|
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))  AS SumMan,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))  AS AmountIncludingVAT,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))  AS AmountExcludingVAT,
		|
		|	DocumentData.DocumentID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	PaymentDecryptionTable.Department AS Department,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|	PaymentDecryptionTable.ExpenseItem AS AssetRef,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS Dimension,
		|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
		|
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.SumMan  AS SumMan,
		|	PaymentDecryptionTable.SumMan  AS AmountIncludingVAT,
		|	PaymentDecryptionTable.SumMan  AS AmountExcludingVAT,
		|
		|	PaymentDecryptionTable.RowID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|WHERE
		|	PaymentDecryptionTable.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	&Department AS Department,
		|	&LineOfBusiness AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting) AS AssetRef,
		|	DocumentData.CashAccountRecipientOwner AS Dimension,
		|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
		|
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))  AS SumMan,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))  AS AmountIncludingVAT,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))  AS AmountExcludingVAT,
		|
		|	DocumentData.DocumentID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee Then
	
		QueryText = "// Issuing loans to an employee
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	UNDEFINED AS Department,
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings) AS AssetRef,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS Dimension,
		|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
		|
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.SumMan  AS SumMan,
		|	PaymentDecryptionTable.SumMan  AS AmountIncludingVAT,
		|	PaymentDecryptionTable.SumMan  AS AmountExcludingVAT,
		|
		|	PaymentDecryptionTable.RowID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|WHERE
		|	&BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee)
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If SettlementWithBranches Then
		ArrayOfRequestTexts.Add(OtherAssetsLiabilitiesServer.QueryTextSettlementWithBranches());
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined, DocumentObject = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""DocumentData""     AS DataSource,
	|	FALSE                    AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Date   AS Date,
	|	DocumentTable.Organization AS Organization,
	|	DocumentTable.Currency AS DocumentCurrency,
	|	ISNULL(Rows.ARAPCurrency, UNDEFINED) AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Date   AS DateOfCourse,
	|
	|	ISNULL(Rows.LineNumber, 0) AS LineNumber,
	|	ISNULL(Rows.RowID, """") AS RowID,
	|	ISNULL(Rows.Sum - Rows.VATAmount, DocumentTable.DocumentAmount) AS AmountExcludingVAT,
	|	ISNULL(Rows.VATRate, UNDEFINED) AS VATRate,
	|	ISNULL(Rows.VATAmount, 0) AS VATAmount,
	|	ISNULL(Rows.AmountARAP, 0) AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	CASE
	|		WHEN ISNULL(Rows.ARAPObject, VALUE(Catalog.ARAPObjects.EmptyRef)) = VALUE(Catalog.ARAPObjects.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	ISNULL(Rows.ARAPObject, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	LEFT JOIN DocumentDataTableDecryptionOfPayment AS Rows
	|		ON Rows.Ref = DocumentTable.Ref
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	If DocumentObject = Undefined Then
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataHeader", "Document.CashVoucher");
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataTableDecryptionOfPayment", "Document.CashVoucher.ARAPDetails");
	EndIf;
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTrackingAnalyticsKeysForPartners(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	PaymentDecryptionTable.LineNumber                             AS LineNumber,
	|	&Period                                                           AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                            AS RecordType,
	
	|	PaymentDecryptionTable.AccountingDimensionByPartners               AS AccountingDimensionByPartners,
	|	PaymentDecryptionTable.LoanDepositContract                  AS Contract,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.TransferToDeposits),
	|			VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty))
	|			THEN VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|		ELSE PaymentDecryptionTable.LoanAndDepositAmountType
	|	END AS AmountType,
	|	UNDEFINED                                                      AS ARAPDocument,
	|	PaymentDecryptionTable.ARAPCurrency                    AS Currency,
	
	|	PaymentDecryptionTable.AmountARAP                     AS Sum,
	|	PaymentDecryptionTable.AmountARAP                     AS BeingPaid,
	|	PaymentDecryptionTable.SumCompl                               AS SumCompl,
	|	PaymentDecryptionTable.SumMan                                AS SumMan,
	
	|	&BusinessOperation                                            AS BusinessOperation,
	|	CASE
	|		WHEN ContractData.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)
	|		ELSE VALUE(Enum.FinancialInstrumentScheduleTypes.Tranches)
	|	END AS ScheduleType,
	|	PaymentDecryptionTable.CashFlowItem           AS DimensionItem,
	|	
	|	PaymentDecryptionTable.RowID                     AS FinRecordID,
	|	&BusinessTransactionSetting                                   AS BusinessTransactionSetting,
	|	PaymentDecryptionTable.PaymentRequest     AS PaymentRequest
	|	
	|FROM
	|	PaymentDecryptionTable AS PaymentDecryptionTable
	|		INNER JOIN Catalog.LoanAndDepositContracts AS ContractData
	|		ON ContractData.Ref = PaymentDecryptionTable.LoanDepositContract
	|	
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|		VALUE(Enum.BusinessTransactions.TransferToDeposits),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty))
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber                             AS LineNumber,
	|	&Period                                                           AS Period,
	|	VALUE(AccumulationRecordType.Expense)                            AS RecordType,
	
	|	PaymentDecryptionTable.AccountingDimensionByPartners               AS AccountingDimensionByPartners,
	|	PaymentDecryptionTable.LoanDepositContract                  AS Contract,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.TransferToDeposits),
	|			VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty))
	|			THEN VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|		ELSE PaymentDecryptionTable.LoanAndDepositAmountType
	|	END AS AmountType,
	|	UNDEFINED                                                      AS ARAPDocument,
	|	PaymentDecryptionTable.ARAPCurrency                    AS Currency,
	
	|	0                                                                 AS Sum,
	|	PaymentDecryptionTable.AmountARAP                     AS BeingPaid,
	|	0                                                                 AS SumCompl,
	|	0                                                                 AS SumMan,
	
	|	&BusinessOperation                                            AS BusinessOperation,
	|	CASE
	|		WHEN ContractData.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)
	|		ELSE VALUE(Enum.FinancialInstrumentScheduleTypes.Tranches)
	|	END AS ScheduleType,
	|	PaymentDecryptionTable.CashFlowItem           AS DimensionItem,
	|	
	|	PaymentDecryptionTable.RowID                     AS FinRecordID,
	|	&BusinessTransactionSetting                                   AS BusinessTransactionSetting,
	|	PaymentDecryptionTable.PaymentRequest     AS PaymentRequest
	|	
	|FROM
	|	PaymentDecryptionTable AS PaymentDecryptionTable
	|		INNER JOIN Catalog.LoanAndDepositContracts AS ContractData
	|		ON ContractData.Ref = PaymentDecryptionTable.LoanDepositContract
	|	
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|		VALUE(Enum.BusinessTransactions.TransferToDeposits),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty))
	|	AND NOT (&PaymentByRequests AND &UsePaymentRequests)
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber                             AS LineNumber,
	|	&Period                                                           AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                            AS RecordType,
	
	|	PaymentDecryptionTable.AccountingDimensionByPartners               AS AccountingDimensionByPartners,
	|	PaymentDecryptionTable.LeaseContracts                           AS Contract,
	|	PaymentDecryptionTable.TypeOfLeasePayment                      AS AmountType,
	|	CASE
	|		WHEN PaymentDecryptionTable.TypeOfLeasePayment IN (
	|				VALUE(Enum.TypesOfLeasePayments.DepositPayment),
	|				VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)) THEN
	|			&Ref
	|		ELSE
	|			UNDEFINED
	|	END AS ARAPDocument,
	|	PaymentDecryptionTable.ARAPCurrency                    AS Currency,
	
	|	PaymentDecryptionTable.AmountARAP                     AS Sum,
	|	0                                                                 AS BeingPaid,
	|	PaymentDecryptionTable.SumCompl                               AS SumCompl,
	|	PaymentDecryptionTable.SumMan                                AS SumMan,
	
	|	CASE PaymentDecryptionTable.TypeOfLeasePayment
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN VALUE(Enum.BusinessTransactions.PaymentForLeaseServices)
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN VALUE(Enum.BusinessTransactions.PaymentForLeaseServices)
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN VALUE(Enum.BusinessTransactions.SecurityPayment)
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|			THEN VALUE(Enum.BusinessTransactions.LeaseBuyoutValuePayment)
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
	|			THEN VALUE(Enum.BusinessTransactions.LeaseBuyoutValuePrepayment)
	|		ELSE &BusinessOperation
	|	END AS BusinessOperation,
	|
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)  AS ScheduleType,
	|	PaymentDecryptionTable.CashFlowItem           AS DimensionItem,
	|	
	|	PaymentDecryptionTable.RowID                     AS FinRecordID,
	|
	|	CASE PaymentDecryptionTable.TypeOfLeasePayment
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.PaymentForLeaseServices)
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.PaymentForLeaseServices)
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.SecurityPayment)
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.LeaseBuyoutValuePayment)
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.LeaseBuyoutValuePrepayment)
	|		ELSE &BusinessTransactionSetting
	|	END AS BusinessTransactionSetting,
	|	PaymentDecryptionTable.PaymentRequest     AS PaymentRequest
	|	
	|FROM
	|	PaymentDecryptionTable AS PaymentDecryptionTable
	|
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentToLessor))
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber                             AS LineNumber,
	|	&Period                                                           AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                            AS RecordType,
	
	|	PaymentDecryptionTable.AccountingDimensionByPartners               AS AccountingDimensionByPartners,
	|	PaymentDecryptionTable.LeaseContracts                           AS Contract,
	|	PaymentDecryptionTable.TypeOfLeasePayment                      AS AmountType,
	|	UNDEFINED                                                      AS ARAPDocument,
	|	PaymentDecryptionTable.ARAPCurrency                    AS Currency,
	
	|	0                                                                 AS Sum,
	|	PaymentDecryptionTable.AmountARAP                     AS BeingPaid,
	|	0                                                                 AS SumCompl,
	|	0                                                                 AS SumMan,
	
	|	&BusinessOperation                                            AS BusinessOperation,
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)  AS ScheduleType,
	|	PaymentDecryptionTable.CashFlowItem           AS DimensionItem,
	|	
	|	PaymentDecryptionTable.RowID                     AS FinRecordID,
	|	&BusinessTransactionSetting                                   AS BusinessTransactionSetting,
	|	PaymentDecryptionTable.PaymentRequest     AS PaymentRequest
	|	
	|FROM
	|	PaymentDecryptionTable AS PaymentDecryptionTable
	|
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentToLessor))
	|	AND &PaymentByRequests
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCashFlow(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashFlow";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashCollectionToBank
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueToAnotherCashAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueToCashRegister
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion) Then
		Return "";
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Date AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	&InitiatorDivision AS Department,
	|
	|	DocumentData.CashAccount AS Cash,
	|	&LineOfBusinessCash AS LineOfBusiness,
	|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|	THEN
	|		PaymentDecryptionTable.CashFlowItem
	|	ELSE
	|		&CashFlowItem
	|	END AS CashFlowItem,
	|	DocumentData.Currency AS Currency,
	|
	|	CASE
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CashDepositToBankAccount),
	|				VALUE(Enum.BusinessTransactions.CashCollectionToBank))
	|			THEN DocumentData.BankAccount
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount)
	|			THEN DocumentData.CashAccountRecipient
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueToCashRegister)
	|			THEN DocumentData.CashRegister
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|			THEN DocumentData.AdvanceHolder
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|			THEN DocumentData.Counterparty
	|	END AS CorCash,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount)
	|		THEN DocumentData.CashAccountRecipientLineOfBusiness
	|		ELSE ISNULL(PaymentDecryptionTable.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	END AS CorLineOfBusiness,
	|
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|			THEN VALUE(Enum.CashTypes.AdvanceHolderSCash)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashDepositToBankAccount)
	|			THEN VALUE(Enum.CashTypes.BankAccountPayments_)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueToCashRegister)
	|			THEN VALUE(Enum.CashTypes.CashPayment)
	|		ELSE
	|			VALUE(Enum.CashTypes.CashInTransit)
	|	END AS CorCashType,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) THEN
	|			PaymentDecryptionTable.ARAPCurrency
	|		ELSE
	|			DocumentData.Currency
	|	END AS CorrespondingCurency,
	|
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|			THEN CASE WHEN PaymentDecryptionTable.Sum IS NULL 
	|							THEN CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|							ELSE PaymentDecryptionTable.SumMan
	|				END
	|		ELSE CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) 
	|	END AS Sum,
	|	
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|		THEN CASE WHEN PaymentDecryptionTable.Sum IS NULL 
	|							THEN CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|							ELSE PaymentDecryptionTable.SumCompl
	|				END
	|		ELSE CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) 
	|	END AS SumCompl,
	|	
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|		THEN ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount)
	|		ELSE DocumentData.DocumentAmount 
	|	END AS AmountInCurrency,
	|	
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|		THEN ISNULL(PaymentDecryptionTable.AmountARAP, DocumentData.DocumentAmount)
	|		ELSE DocumentData.DocumentAmount 
	|	END AS AmountInCorCurrency,
	|
	|	CASE WHEN ISNULL(PaymentDecryptionTable.PaymentRequest, VALUE(Document.PaymentRequest.EmptyRef)) = VALUE(Document.PaymentRequest.EmptyRef)
	|		OR PaymentDecryptionTable.PaymentRequest = UNDEFINED THEN
	|		CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|		THEN ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount)
	|		ELSE DocumentData.DocumentAmount END
	|	END AS AmountToBePaidAboveLimit,
	|
	|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
	|	CASE 
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashDepositToBankAccount)
	|			THEN DocumentData.BankAccount
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount)
	|			THEN DocumentData.CashAccountRecipient
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
	|			THEN UNDEFINED
	|	END AS CorSourceOfFAGOfCash,
	|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|	LEFT JOIN 
	|		PaymentDecryptionTable AS PaymentDecryptionTable
	|	ON 
	|		TRUE
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
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
		|	DocumentData.Date AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.CashAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	DocumentData.Currency AS Currency,
		|
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusinessItems,
		|	PaymentDecryptionTable.ExpenseItem AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|
		|	PaymentDecryptionTable.SumMan AS Sum,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.Sum AS AmountInCurrency,
		|
		|	CASE WHEN ISNULL(PaymentDecryptionTable.PaymentRequest, VALUE(Document.PaymentRequest.EmptyRef)) = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR PaymentDecryptionTable.PaymentRequest = UNDEFINED THEN
		|		PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidAboveLimit,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|	PaymentDecryptionTable.ExpenseItem AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN 
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON 
		|		TRUE
		|";
	
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByDistributor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToEmployee)
		And Not UsePayroll Then
		
		QueryText = "
		|SELECT
		|	DocumentData.Date AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.CashAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
		|	&CashFlowItem AS CashFlowItem,
		|	DocumentData.Currency AS Currency,
		|
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.DocumentAmount AS AmountInCurrency,
		|	
		|	CASE WHEN DocumentData.PaymentRequest = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR DocumentData.PaymentRequest = UNDEFINED THEN
		|		DocumentData.DocumentAmount
		|	END AS AmountToBePaidAboveLimit,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	DocumentData.PaymentRequest AS PaymentRequest
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
		
		QueryText = "
		|SELECT
		|	DocumentData.Date AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.CashAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	DocumentData.Currency AS Currency,
		|
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLeasing) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	PaymentDecryptionTable.LeaseContracts AS AssetsLiabilitiesDimension,
		|
		|	SUM(PaymentDecryptionTable.SumMan) AS Sum,
		|	SUM(PaymentDecryptionTable.SumCompl) AS SumCompl,
		|	SUM(PaymentDecryptionTable.Sum) AS AmountInCurrency,
		|
		|	SUM(CASE WHEN ISNULL(PaymentDecryptionTable.PaymentRequest, VALUE(Document.PaymentRequest.EmptyRef)) = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR PaymentDecryptionTable.PaymentRequest = UNDEFINED THEN
		|		PaymentDecryptionTable.Sum
		|	END) AS AmountToBePaidAboveLimit,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON TRUE
		|
		|GROUP BY
		|	DocumentData.Date,
		|	DocumentData.Organization,
		|	DocumentData.Department,
		|	PaymentDecryptionTable.Department,
		|	DocumentData.CashAccount,
		|	DocumentData.Currency,
		|	PaymentDecryptionTable.LineOfBusiness,
		|	PaymentDecryptionTable.LeaseContracts,
		|	PaymentDecryptionTable.LeaseContracts.Department,
		|	PaymentDecryptionTable.CashFlowItem,
		|	PaymentDecryptionTable.PaymentRequest";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
		And UsePayroll Then
		
		QueryText = "// Issuing loans to an employee
		|SELECT
		|	DocumentData.Date AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.CashAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	DocumentData.Currency AS Currency,
		|
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|
		|	SUM(PaymentDecryptionTable.SumMan) AS Sum,
		|	SUM(PaymentDecryptionTable.SumCompl) AS SumCompl,
		|	SUM(PaymentDecryptionTable.Sum) AS AmountInCurrency,
		|
		|	SUM(CASE WHEN ISNULL(PaymentDecryptionTable.PaymentRequest, VALUE(Document.PaymentRequest.EmptyRef)) = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR PaymentDecryptionTable.PaymentRequest = UNDEFINED THEN
		|		PaymentDecryptionTable.Sum
		|	END) AS AmountToBePaidAboveLimit,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON TRUE
		|
		|GROUP BY
		|	DocumentData.Date,
		|	DocumentData.Organization,
		|	DocumentData.Department,
		|	DocumentData.CashAccount,
		|	DocumentData.Currency,
		|	PaymentDecryptionTable.CashFlowItem,
		|	PaymentDecryptionTable.PaymentRequest";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
		And Not UsePayroll Then
	
		QueryText = "
		|SELECT
		|	DocumentData.Date AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.CashAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
		|	DocumentData.CashFlowItem AS CashFlowItem,
		|	DocumentData.Currency AS Currency,
		|
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings) AS AssetAndLiabilityItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.DocumentAmount AS AmountInCurrency,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	CASE WHEN DocumentData.PaymentRequest = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR DocumentData.PaymentRequest = UNDEFINED THEN
		|		DocumentData.DocumentAmount
		|	END AS AmountToBePaidAboveLimit,
		|
		|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	DocumentData.PaymentRequest AS PaymentRequest
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
	
		QueryText = "
		|SELECT
		|	DocumentData.Date AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.CashAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	DocumentData.Currency AS Currency,
		|
		|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLeasing) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	PaymentDecryptionTable.LeaseContracts AS AssetsLiabilitiesDimension,
		|
		|	0 AS Sum,
		|	0 AS SumCompl,
		|	0 AS AmountInCurrency,
		|
		|	0 AS AmountToBePaidAboveLimit,
		|
		|	PaymentDecryptionTable.VATAmountMan AS VATAmount,
		|	PaymentDecryptionTable.VATAmountCompl AS VATAmountCompl,
		|	PaymentDecryptionTable.VATAmount AS AmountVATCurrencyPayment,
		|
		|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	PaymentDecryptionTable.VATRate AS VATRate,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON TRUE
		|WHERE
		|	PaymentDecryptionTable.VATAmount <> 0
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
	
	ArrayOfSubqueryTexts = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		
		QueryTextOfSubquery = "// Cash write-off operations
	|	SELECT
	|		DocumentData.Date AS Period,
	|		&BusinessOperation AS BusinessOperation,
	|		DocumentData.Organization AS Organization,
	|		DocumentData.Department AS Department,
	|
	|		DocumentData.CashAccount AS Cash,
	|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|		DocumentData.Currency AS PaymentCurrency,
	|
	|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS Partner,
	|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
	|		PaymentDecryptionTable.AccountingDimensionByPartners.Contract AS Contract,
	|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	
	|		PaymentDecryptionTable.SumMan AS PayAmount,
	|		PaymentDecryptionTable.SumCompl AS PaymentAmountLocal,
	|		PaymentDecryptionTable.Sum AS PaymentAmountPaymentCurrency,
	|
	|		0 AS PostpaymentAmount,
	|		0 AS PostpaymentAmountLocal,
	|		0 AS PaymentAmountInPaymentCurrency,
	|		
	|		0 AS PrepaymentAmountMan,
	|		0 AS PrepaymentAmountLocal,
	|		0 AS PrepaymentAmount,
	|
	|		CASE WHEN ISNULL(PaymentDecryptionTable.PaymentRequest, VALUE(Document.PaymentRequest.EmptyRef)) = VALUE(Document.PaymentRequest.EmptyRef)
	|			OR PaymentDecryptionTable.PaymentRequest = UNDEFINED THEN
	|			PaymentDecryptionTable.Sum
	|		END AS AmountToBePaidAboveLimit,
	|
	|		0 AS VATAmount,
	|		0 AS VATAmountCompl,
	|		0 AS AmountVATCurrencyPayment,
	|
	|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
	|
	|		PaymentDecryptionTable.AmountARAP AS PaymentAmountInTheSettlementCurrency,
	|		0 AS PostPaymentAmountInARAPCurrency,
	|		0 AS PrepaymentAmountInARAPCurrency,
	|
	|		DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
	|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|		UNDEFINED AS VATRate,
	|		PaymentDecryptionTable.PaymentRequest AS PaymentRequest
	|	FROM
	|		DocumentDataHeader AS DocumentData
	|	
	|	LEFT JOIN
	|		PaymentDecryptionTable AS PaymentDecryptionTable
	|	ON
	|		TRUE
	|";
		
		ArrayOfSubqueryTexts.Add(QueryTextOfSubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		QueryTextOfSubquery = "
		|	// Internal money transfer operations
		|	SELECT
		|		DocumentData.Date AS Period,
		|		&BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		DocumentData.Department AS Department,
		|
		|		DocumentData.CashAccount AS Cash,
		|		&CashFlowItem AS CashFlowItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		UNDEFINED AS Partner,
		|		DocumentData.CashAccountRecipientOwner AS Counterparty,
		|		DocumentData.CashAccountRecipientLineOfBusiness AS LineOfBusiness,
		|		UNDEFINED AS Contract,
		|		UNDEFINED AS ARAPObject,
		|	
		|		CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
		|		CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS PaymentAmountLocal,
		|		DocumentData.DocumentAmount AS PaymentAmountPaymentCurrency,
		|
		|		0 AS PostpaymentAmount,
		|		0 AS PostpaymentAmountLocal,
		|		0 AS PaymentAmountInPaymentCurrency,
		|		
		|		0 AS PrepaymentAmountMan,
		|		0 AS PrepaymentAmountLocal,
		|		0 AS PrepaymentAmount,
		|
		|		CASE WHEN ISNULL(DocumentData.PaymentRequest, VALUE(Document.PaymentRequest.EmptyRef)) = VALUE(Document.PaymentRequest.EmptyRef)
		|			OR DocumentData.PaymentRequest = UNDEFINED THEN
		|			DocumentData.DocumentAmount
		|		END AS AmountToBePaidAboveLimit,
		|
		|		0 AS VATAmount,
		|		0 AS VATAmountCompl,
		|		0 AS AmountVATCurrencyPayment,
		|
		|		DocumentData.Currency AS ARAPCurrency,
		|
		|		DocumentData.DocumentAmount AS PaymentAmountInTheSettlementCurrency,
		|		0 AS PostPaymentAmountInARAPCurrency,
		|		0 AS PrepaymentAmountInARAPCurrency,
		|
		|		DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|		UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate,
		|		DocumentData.PaymentRequest AS PaymentRequest
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfSubqueryTexts.Add(QueryTextOfSubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty Then
		
		QueryTextOfSubquery = "// Payment transactions on loans and payments on loans issued
		|	SELECT
		|		DocumentData.Date AS Period,
		|		CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived)
		|				AND PaymentDecryptionTable.LoanAndDepositAmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests) THEN
		|				VALUE(Enum.BusinessTransactions.LoanInterestPayment)
		|			ELSE
		|				&BusinessOperation
		|		END AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		DocumentData.Department AS Department,
		|
		|		DocumentData.CashAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS Partner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|		PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|		PaymentDecryptionTable.LoanDepositContract AS Contract,
		|		UNDEFINED AS ARAPObject,
		|	
		|		PaymentDecryptionTable.SumMan AS PayAmount,
		|		PaymentDecryptionTable.SumCompl AS PaymentAmountLocal,
		|		PaymentDecryptionTable.Sum AS PaymentAmountPaymentCurrency,
		|
		|		0 AS PostpaymentAmount,
		|		0 AS PostpaymentAmountLocal,
		|		0 AS PaymentAmountInPaymentCurrency,
		|		
		|		0 AS PrepaymentAmountMan,
		|		0 AS PrepaymentAmountLocal,
		|		0 AS PrepaymentAmount,
		|
		|		CASE WHEN ISNULL(PaymentDecryptionTable.PaymentRequest, VALUE(Document.PaymentRequest.EmptyRef)) = VALUE(Document.PaymentRequest.EmptyRef)
		|			OR PaymentDecryptionTable.PaymentRequest = UNDEFINED THEN
		|			ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount)
		|		END AS AmountToBePaidAboveLimit,
		|
		|		0 AS VATAmount,
		|		0 AS VATAmountCompl,
		|		0 AS AmountVATCurrencyPayment,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|
		|		PaymentDecryptionTable.AmountARAP AS PaymentAmountInTheSettlementCurrency,
		|		0 AS PostPaymentAmountInARAPCurrency,
		|		0 AS PrepaymentAmountInARAPCurrency,
		|
		|		DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.LoanDepositContract AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate,
		|		PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|";
		
		ArrayOfSubqueryTexts.Add(QueryTextOfSubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer 
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		
		QueryTextOfSubquery = "// VAT
		|	SELECT
		|		DocumentData.Date AS Period,
		|		&BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		DocumentData.Department AS Department,
		|
		|		DocumentData.CashAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS Partner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|		ISNULL(PaymentDecryptionTable.ARAPObject.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Contract AS Contract,
		|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|	
		|		0 AS PayAmount,
		|		0 AS PaymentAmountLocal,
		|		0 AS PaymentAmountPaymentCurrency,
		|
		|		0 AS PostpaymentAmount,
		|		0 AS PostpaymentAmountLocal,
		|		0 AS PaymentAmountInPaymentCurrency,
		|		
		|		0 AS PrepaymentAmountMan,
		|		0 AS PrepaymentAmountLocal,
		|		0 AS PrepaymentAmount,
		|
		|		0 AS AmountToBePaidAboveLimit,
		|
		|		PaymentDecryptionTable.VATAmountMan AS VATAmount,
		|		PaymentDecryptionTable.VATAmountCompl AS VATAmountCompl,
		|		PaymentDecryptionTable.VATAmount AS AmountVATCurrencyPayment,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|
		|		0 AS PaymentAmountInTheSettlementCurrency,
		|		0 AS PostPaymentAmountInARAPCurrency,
		|		0 AS PrepaymentAmountInARAPCurrency,
		|
		|		DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		PaymentDecryptionTable.VATRate AS VATRate,
		|		PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|	WHERE
		|		PaymentDecryptionTable.VATAmount <> 0";
			
		ArrayOfSubqueryTexts.Add(QueryTextOfSubquery);
		
	EndIf;
	
	If ArrayOfSubqueryTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	TextOfQuerySubquery = StrConcat(ArrayOfSubqueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	DocumentData.Cash AS Cash,
	|	&LineOfBusinessCash AS LineOfBusinessCash,
	|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.PaymentCurrency AS PaymentCurrency,
	|
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	CASE WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|					VALUE(Enum.BusinessTransactions.RefundToAnotherCompany))
	|				AND ISNULL(DocumentData.LineOfBusiness.IncomeAccounting, FALSE)
	|			OR NOT &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|					VALUE(Enum.BusinessTransactions.RefundToAnotherCompany))
	|				AND ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE)
	|		THEN
	|			DocumentData.LineOfBusiness
	|	ELSE
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS CounterpartyLineOfBusiness,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|
	|	SUM(DocumentData.PayAmount) AS PayAmount,
	|	SUM(DocumentData.PaymentAmountLocal) AS PaymentAmountLocal,
	|	SUM(DocumentData.PaymentAmountPaymentCurrency) AS PaymentAmountPaymentCurrency,
	|
	|	SUM(DocumentData.PostpaymentAmount) AS PostpaymentAmount,
	|	SUM(DocumentData.PostpaymentAmountLocal) AS PostpaymentAmountLocal,
	|	SUM(DocumentData.PaymentAmountInPaymentCurrency) AS PaymentAmountInPaymentCurrency,
	|
	|	SUM(DocumentData.PrepaymentAmountMan) AS PrepaymentAmountMan,
	|	SUM(DocumentData.PrepaymentAmountLocal) AS PrepaymentAmountLocal,
	|	SUM(DocumentData.PrepaymentAmount) AS PrepaymentAmount,
	|
	|	SUM(DocumentData.AmountToBePaidAboveLimit) AS AmountToBePaidAboveLimit,
	|
	|	SUM(DocumentData.VATAmount) AS VATAmount,
	|	SUM(DocumentData.VATAmountCompl) AS VATAmountCompl,
	|	SUM(DocumentData.AmountVATCurrencyPayment) AS AmountVATCurrencyPayment,
	|	
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|
	|	SUM(DocumentData.PaymentAmountInTheSettlementCurrency) AS PaymentAmountInTheSettlementCurrency,
	|	SUM(DocumentData.PostPaymentAmountInARAPCurrency) AS PostPaymentAmountInARAPCurrency,
	|	SUM(DocumentData.PrepaymentAmountInARAPCurrency) AS PrepaymentAmountInARAPCurrency,
	|
	|	DocumentData.SourceOfCashFinancialAccountingGroup AS SourceOfCashFinancialAccountingGroup,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.VATRate,
	|	DocumentData.PaymentRequest,
	|	FALSE AS DeferredPosting
	|
	|FROM &TheTextOfASubquery AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Period,
	|	DocumentData.BusinessOperation,
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.Cash,
	|	DocumentData.CashFlowItem,
	|	DocumentData.PaymentCurrency,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	CASE WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|					VALUE(Enum.BusinessTransactions.RefundToAnotherCompany))
	|				AND ISNULL(DocumentData.LineOfBusiness.IncomeAccounting, FALSE)
	|			OR NOT &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|					VALUE(Enum.BusinessTransactions.RefundToAnotherCompany))
	|				AND ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE)
	|		THEN
	|			DocumentData.LineOfBusiness
	|	ELSE
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END,
	|	DocumentData.Contract,
	|	DocumentData.ARAPObject,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.SourceOfCashFinancialAccountingGroup,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.VATRate,
	|	DocumentData.PaymentRequest
	|";
	
	QueryText = StrReplace(QueryText, "&TheTextOfASubquery", "(" + TextOfQuerySubquery + ")");
	
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
	
	If Query.Parameters.Property("UsePayroll") Then
		UsePayroll = Query.Parameters.UsePayroll;
	Else
		UsePayroll = Constants.UsePayroll.Get();
	EndIf;
	
	If Not UseCashFlowLimits Then
		Return "";
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If (DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashDepositToBankAccount
		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashIssueToAnotherCashAccount
		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.CashIssueToCashRegister
		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SalaryPaymentViaCashAccount
		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SalaryPaymentByDistributor
		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SalaryPaymentToEmployee) Then
	
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber AS LineNumber,
		|	DocumentData.Date AS Period,
		|	CASE
		|		WHEN &UseExpenseLimitsForOrganizations
		|			THEN &Organization
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS Organization,
		|	CASE
		|		WHEN NOT &UseExpenseLimitsByDivision
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN &Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN &Department 
		|		ELSE DocumentData.CashAccount.Department
		|	END AS Department,
		|
		|	CASE WHEN &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PaymentToVendor), 
		|		VALUE(Enum.BusinessTransactions.RefundToCustomer), 
		|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany), 
		|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany), 
		|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder), 
		|		VALUE(Enum.BusinessTransactions.OtherCashIssue), 
		|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived), 
		|		VALUE(Enum.BusinessTransactions.TransferToDeposits), 
		|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty),
		|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee))
		|	THEN
		|		PaymentDecryptionTable.CashFlowItem
		|	ELSE
		|		&CashFlowItem
		|	END AS CashFlowItem,
		|	
		|	ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount) * &ConversionRateToManCurrency AS ExcessExpense
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN 
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE
		|
		|WHERE
		| (PaymentDecryptionTable.PaymentRequest = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR PaymentDecryptionTable.PaymentRequest = UNDEFINED)
		|
		|ORDER BY
		|	LineNumber";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByDistributor
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToEmployee) 
		And (DocumentObject.PaymentRequest = Documents.PaymentRequest.EmptyRef()
			Or DocumentObject.PaymentRequest = Undefined)
			And Not UsePayroll Then
	
		QueryText = "
		|SELECT
		|	0 AS LineNumber,
		|	DocumentData.Date AS Period,
		|	CASE
		|		WHEN &UseExpenseLimitsForOrganizations
		|			THEN &Organization
		|		ELSE VALUE(Catalog.Companies.EmptyRef)
		|	END AS Organization,
		|	
		|	CASE
		|		WHEN NOT &UseExpenseLimitsByDivision
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN &Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN &Department 
		|		ELSE DocumentData.CashAccount.Department
		|	END AS Department,
		|	
		|	&CashFlowItem AS CashFlowItem,
		|	
		|	DocumentData.DocumentAmount AS ExcessExpense
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|
		|ORDER BY
		|	LineNumber
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

Function RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts, DocumentObject)
	
	TempTableName = "TTMovementCounterpartyCounterparty";
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfSubqueryTexts = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
			
		SubqueryText = "SELECT
		|		DocumentData.Date AS Period,
		|		CASE WHEN &BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.PaymentToVendor),
		|				VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany))
		|			THEN VALUE(Enum.BusinessTransactions.PaymentTransferFromBranchOffice)
		|			ELSE VALUE(Enum.BusinessTransactions.ARAPSettlement)
		|		END AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		PaymentDecryptionTable.OrderDivision_ AS Department,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS Partner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.LineOfBusiness AS LineOfBusiness,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Contract AS Contract,
		|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|
		|		VALUE(Catalog.Partners.OurEnterprise) AS CorPartner,
		|		PaymentDecryptionTable.Organization AS CorCounterparty,
		|		CAST(&LineOfBusinessCash AS Catalog.LinesOfBusiness) AS CorLineOfBusiness,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Contract AS CorContract,
		|		PaymentDecryptionTable.ARAPObject AS CorARAPObject,
		|		
		|	
		|		PaymentDecryptionTable.SumMan AS Sum,
		|		PaymentDecryptionTable.SumCompl AS SumCompl,
		|		PaymentDecryptionTable.Sum AS AmountInCurrency,
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|		PaymentDecryptionTable.AmountARAP AS AmountInARAPCurrency,
		|		PaymentDecryptionTable.ARAPCurrency AS CorCurrencyOfARAPAccounting,
		|		PaymentDecryptionTable.AmountARAP AS AdjAmountInARAPCurrency,
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|			LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON TRUE
		|	WHERE
		|		DocumentData.Organization <> PaymentDecryptionTable.Organization";
		
		ArrayOfSubqueryTexts.Add(SubqueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
			
		SubqueryText = "SELECT
		|		DocumentData.Date AS Period,
		|		CASE WHEN &BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.PaymentToVendor),
		|				VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany))
		|			THEN VALUE(Enum.BusinessTransactions.PaymentAcceptanceAtBranchOffice)
		|			ELSE VALUE(Enum.BusinessTransactions.ARAPSettlement)
		|		END AS BusinessOperation,
		|		PaymentDecryptionTable.Organization AS Organization,
		|		PaymentDecryptionTable.OrderDivision_ AS Department,
		|
		|		VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|		DocumentData.Organization AS Counterparty,
		|		CAST(&LineOfBusinessCash AS Catalog.LinesOfBusiness) AS LineOfBusiness,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Contract AS Contract,
		|		PaymentDecryptionTable.ARAPObject AS ARAPObject,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS CorPartner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS CorCounterparty,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.LineOfBusiness AS CorLineOfBusiness,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Contract AS CorContract,
		|		PaymentDecryptionTable.ARAPObject AS CorARAPObject,
		|		
		|	
		|		PaymentDecryptionTable.SumMan AS Sum,
		|		PaymentDecryptionTable.SumCompl AS SumCompl,
		|		PaymentDecryptionTable.Sum AS AmountInCurrency,
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|		PaymentDecryptionTable.AmountARAP AS AmountInARAPCurrency,
		|		PaymentDecryptionTable.ARAPCurrency AS CorCurrencyOfARAPAccounting,
		|		PaymentDecryptionTable.AmountARAP AS AdjAmountInARAPCurrency,
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|			LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON TRUE
		|	WHERE
		|	DocumentData.Organization <> PaymentDecryptionTable.Organization";
		
		ArrayOfSubqueryTexts.Add(SubqueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
			
		SubqueryText = "// Refund of payment at the advance rate
		|	SELECT
		|		DocumentData.Date AS Period,
		|		VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		PaymentDecryptionTable.OrderDivision_ AS Department,
		|
		|		VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|		DocumentData.Organization AS Counterparty,
		|		&LineOfBusinessCash AS LineOfBusiness,
		|		DocumentData.Contract AS Contract,
		|		DocumentData.ARAPObject AS ARAPObject,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS CorPartner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS CorCounterparty,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.LineOfBusiness AS CorLineOfBusiness,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Contract AS CorContract,
		|		PaymentDecryptionTable.ARAPObject AS CorARAPObject,
		|		
		|	
		|		PaymentDecryptionTable.SumMan AS Sum,
		|		PaymentDecryptionTable.SumCompl AS SumCompl,
		|		PaymentDecryptionTable.Sum AS AmountInCurrency,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|		PaymentDecryptionTable.AmountARAP AS AmountInARAPCurrency,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS CorCurrencyOfARAPAccounting,
		|		PaymentDecryptionTable.AmountARAP AS AdjAmountInARAPCurrency,
		|
		|		DocumentData.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON TRUE
		|	WHERE
		|		PaymentDecryptionTable.ARAPObject.OBJECT <> &Ref";
		
		ArrayOfSubqueryTexts.Add(SubqueryText);
		
	EndIf;
	
	If ArrayOfSubqueryTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	TextOfQuerySubquery = StrConcat(ArrayOfSubqueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE)
	|			THEN DocumentData.LineOfBusiness
	|	END AS LineOfBusiness,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.CorPartner AS CorPartner,
	|	DocumentData.CorCounterparty AS CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.CorLineOfBusiness.VendorARAP, FALSE)
	|			THEN DocumentData.CorLineOfBusiness
	|	END AS CorLineOfBusiness,
	|	DocumentData.CorContract AS CorContract,
	|	DocumentData.CorARAPObject AS CorARAPObject,
	|	&Currency AS Currency,
	|	SUM(DocumentData.Sum) AS Sum,
	|	SUM(DocumentData.SumCompl) AS SumCompl,
	|	SUM(DocumentData.AmountInCurrency) AS AmountInCurrency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	SUM(DocumentData.AmountInARAPCurrency) AS AmountInARAPCurrency,
	|	DocumentData.CorCurrencyOfARAPAccounting AS CorCurrencyOfARAPAccounting,
	|	SUM(DocumentData.AdjAmountInARAPCurrency) AS AdjAmountInARAPCurrency,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.CorSourceOfARAPFinancialAccountingGroup AS CorSourceOfARAPFinancialAccountingGroup
	|INTO TTMovementCounterpartyCounterparty
	|
	|FROM &TheTextOfASubquery AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Period,
	|	DocumentData.BusinessOperation,
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	DocumentData.LineOfBusiness,
	|	DocumentData.Contract,
	|	DocumentData.ARAPObject,
	|	DocumentData.CorPartner,
	|	DocumentData.CorCounterparty,
	|	DocumentData.CorLineOfBusiness,
	|	DocumentData.CorContract,
	|	DocumentData.CorARAPObject,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.CorCurrencyOfARAPAccounting,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.CorSourceOfARAPFinancialAccountingGroup,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE)
	|			THEN DocumentData.LineOfBusiness
	|	END,
	|	CASE
	|		WHEN ISNULL(DocumentData.CorLineOfBusiness.VendorARAP, FALSE)
	|			THEN DocumentData.CorLineOfBusiness
	|	END";
	
	QueryText = StrReplace(QueryText, "&TheTextOfASubquery", "(" + TextOfQuerySubquery + ")");
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany) Then
		Return "";
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTMovementCounterpartyCounterparty", QueryTexts) Then
		RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = 
	"SELECT
	|	RecordsCounterpartyCounterparty.Period                        AS Period,
	|	RecordsCounterpartyCounterparty.BusinessOperation         AS BusinessOperation,
	|	RecordsCounterpartyCounterparty.Organization                   AS Organization,
	|	RecordsCounterpartyCounterparty.Department                 AS Department,
	|
	|	RecordsCounterpartyCounterparty.LineOfBusiness       AS LineOfBusiness,
	|	RecordsCounterpartyCounterparty.Partner                       AS Partner,
	|	RecordsCounterpartyCounterparty.Counterparty                    AS Counterparty,
	|	RecordsCounterpartyCounterparty.Contract                       AS Contract,
	|	RecordsCounterpartyCounterparty.ARAPObject                AS ARAPObject,
	|
	|	RecordsCounterpartyCounterparty.CorPartner                    AS CorPartner,
	|	RecordsCounterpartyCounterparty.CorCounterparty                 AS CorCounterparty,
	|	RecordsCounterpartyCounterparty.CorLineOfBusiness    AS CorLineOfBusiness,
	|	RecordsCounterpartyCounterparty.CorContract                    AS CorContract,
	|	RecordsCounterpartyCounterparty.CorARAPObject             AS CorARAPObject,
	|	RecordsCounterpartyCounterparty.Currency                        AS Currency,
	|
	|	RecordsCounterpartyCounterparty.Sum                         AS Sum,
	|	RecordsCounterpartyCounterparty.SumCompl                     AS SumCompl,
	|	RecordsCounterpartyCounterparty.AmountInCurrency                  AS AmountInCurrency,
	|
	|	RecordsCounterpartyCounterparty.ARAPCurrency          AS ARAPCurrency,
	|	RecordsCounterpartyCounterparty.AmountInARAPCurrency    AS AmountInARAPCurrency,
	|	RecordsCounterpartyCounterparty.CorCurrencyOfARAPAccounting       AS CorCurrencyOfARAPAccounting,
	|	RecordsCounterpartyCounterparty.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
	|
	|	RecordsCounterpartyCounterparty.SourceOfARAPFinancialAccountingGroup           AS SourceOfARAPFinancialAccountingGroup,
	|	RecordsCounterpartyCounterparty.CorSourceOfARAPFinancialAccountingGroup        AS CorSourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTMovementCounterpartyCounterparty AS RecordsCounterpartyCounterparty
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, DocumentObject = Undefined)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	PaymentDecryptionTable.ExpenseItem AS ExpenseItem,
	|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	PaymentDecryptionTable.Department AS Department,
	|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	
	|	PaymentDecryptionTable.SumMan AS AmountIncludingVAT,
	|	PaymentDecryptionTable.SumMan AS AmountExcludingVAT,
	|	PaymentDecryptionTable.SumMan AS AmountExcludingVATMan,
	|	PaymentDecryptionTable.SumCompl AS AmountIncludingVATCompl,
	|	PaymentDecryptionTable.SumCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	PaymentDecryptionTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.OtherCashIssue) AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	PaymentDecryptionTable AS PaymentDecryptionTable
	|	INNER JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		PaymentDecryptionTable.ExpenseItem = ExpenseItems.Ref
	|	
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject = Undefined) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	PaymentDecryptionTable.Department AS Department,
	|	PaymentDecryptionTable.ExpenseItem AS ExpenseItem,
	|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS LotVendorAttributes,
	|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
	|	&Ref AS ExpenseReceiptDocument,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|	
	|	PaymentDecryptionTable.SumMan AS Cost,
	|	PaymentDecryptionTable.SumMan AS CostExcludingVAT,
	|	0 AS VATManag,
	|	PaymentDecryptionTable.SumCompl AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	PaymentDecryptionTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.OtherCashIssue) AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	PaymentDecryptionTable AS PaymentDecryptionTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);

EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

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
		|	&CashAccount                                  AS StorageLocation,
		|	&CounterpartyFromDocument                  AS Counterparty,
		|	&AssigneeBusinessUnit               AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	UNDEFINED                            AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	UNDEFINED                            AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
		|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
		|		VALUE(Enum.BusinessTransactions.OtherCashIssue),
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
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByDistributor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToEmployee
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	&Partner                                AS Partner,
		|	&CashAccount                                  AS StorageLocation,
		|	&AdvanceHolder                        AS Counterparty,
		|	&AssigneeBusinessUnit               AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	UNDEFINED                            AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	UNDEFINED                            AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
		|		VALUE(Enum.BusinessTransactions.SalaryPaymentByDistributor),
		|		VALUE(Enum.BusinessTransactions.SalaryPaymentToEmployee),
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
		|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|	&CashAccount                                  AS StorageLocation,
		|	&CompanyRecipient                  AS Counterparty,
		|	&AssigneeBusinessUnit               AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	UNDEFINED                            AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	UNDEFINED                            AS Priority
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
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashCollectionToBank
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueToAnotherCashAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueToCashRegister
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	UNDEFINED                            AS Partner,
		|	&CashAccount                                  AS StorageLocation,
		|	UNDEFINED                            AS Counterparty,
		|	&AssigneeBusinessUnit               AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	UNDEFINED                            AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	UNDEFINED                            AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	UNDEFINED                            AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashDepositToBankAccount),
		|		VALUE(Enum.BusinessTransactions.CashCollectionToBank),
		|		VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount),
		|		VALUE(Enum.BusinessTransactions.CashIssueToCashRegister),
		|		VALUE(Enum.BusinessTransactions.SalaryPaymentViaCashAccount)
		|	)";
	
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount) Then
	
		QueryText = "
		|SELECT
		|	&MetadataIdentifier                AS RefType,
		|	&BusinessOperation                  AS BusinessOperation,
		|	&Organization                            AS Organization,
		|	UNDEFINED                            AS Partner,
		|	&BankAccount                         AS StorageLocation,
		|	UNDEFINED                            AS Counterparty,
		|	&AssigneeBusinessUnit               AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&Author                                  AS Author,
		|	TRUE                                  AS AdditionalRecord,
		|	UNDEFINED                            AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&Period                                 AS SourceDocumentDate,
		|	&NumberForPrinting                          AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	UNDEFINED                            AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	&Period                                 AS RecordingInAccountingDate,
		|	UNDEFINED                            AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.CashDepositToBankAccount)
		|	)
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject <> Undefined And ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.CashVoucher");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

//++ WE
Function QueryTextTablePayrollCalculationsHR(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "PayrollCalculationsHR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentViaCashAccount Then
		Return "";
	EndIf;

	QueryText = "
	|SELECT
	|	DocumentTable.Ref AS Ref,
	|	&Period AS Period,
	|	DocumentTable.Organization AS Organization,
	|	DocumentTable.Department AS Department,
	|	VALUE(Catalog.TypesOfEmployeeCompensations.Payroll) AS ARAPType,
	|	&BusinessOperation AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.SalaryPaymentViaCashAccount) AS BusinessTransactionSetting,
	|	PayrollPayment.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	PayrollPayment.Individual AS Individual,
	|	DocumentTable.DocumentID AS FinRecordID,
	|	PayrollPayment.Sum AS Sum,
	|	CAST(PayrollPayment.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31, 2)) AS SumCompl,
	|	CAST(PayrollPayment.Sum * &ConversionRateToManCurrency AS NUMBER(31, 2)) AS SumMan,
	|	PayrollPayment.Sum AS AmountToBePaid
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|		INNER JOIN Document.CashVoucher.PayrollPayment AS PayrollPayment
	|		ON DocumentTable.Ref = PayrollPayment.Ref
	|WHERE
	|	DocumentTable.Ref IN(&Ref)";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction
//-- WE

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	ARAPObjects.Ref AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		INNER JOIN DocumentDataHeader AS DocumentDataHeader
		|			ON Table.Ref = DocumentDataHeader.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON Table.Ref = ARAPObjects.Object
		|				AND Table.ARAPObjectOfPaymentIsPartner = ARAPObjects.Partner
		|				AND Table.ARAPCurrency = ARAPObjects.ARAPCurrency
		|				AND NOT ARAPObjects.DeletionMark
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates, True);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	If Not Query.Parameters.Property("UsePaymentRequests") Then
		Query.SetParameter("UsePaymentRequests",
			GetFunctionalOption("UsePaymentRequests"));
	EndIf;
	
	#Region CustomersARAPAccounting
	
	#Region TextReturn
	
	TextReturn = "";
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
	
		TextReturn = "
		|SELECT
		|	Table.Ref                               AS Ref,
		|	Document.Organization                         AS Organization,
		|	CASE WHEN Document.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
		|			THEN VALUE(Catalog.Partners.OurEnterprise)
		|		WHEN &ThereIsGiftCertificate = TRUE
		|			THEN &Partner
		|		ELSE Table.Partner
		|	END                                        AS Partner,
		|	SettlementObjectPayment.Ref                  AS ARAPObject,
		|	
		|	Table.ARAPCurrency                 AS ARAPCurrency,
		|	Table.AmountARAP                  AS AmountARAP,
		|	Document.Currency                              AS DocumentCurrency,
		|	Table.Sum                                AS Sum,
		|	0                                            AS BeingPaid,
		|	
		|	Document.BusinessOperation               AS BusinessOperation,
		|	Document.Date                                AS RecorderDate,
		|	Document.Number                               AS RecorderNumber,
		|	VALUE(Enum.PaymentForms.CashAccountPayment_)  AS PaymentMethod,
		|	Document.Date                                AS DateOfCourse,
		|	Table.CashFlowItem        AS CashFlowItem,
		|	Table.PaymentRequest  AS PaymentRequest,
		|	Table.RowID                  AS FinRecordID,
		|	&BusinessTransactionSetting              AS BusinessTransactionSetting
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		INNER JOIN DocumentDataHeader AS Document
		|			ON Document.Ref = Table.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS SettlementObjectPayment
		|			ON Table.Ref = SettlementObjectPayment.Object
		|				AND Table.ARAPObjectOfPaymentIsPartner = SettlementObjectPayment.Partner
		|				AND Table.ARAPCurrency = SettlementObjectPayment.ARAPCurrency
		|				AND NOT SettlementObjectPayment.DeletionMark
		|";
		
	EndIf;
	
	#EndRegion
	
	#Region ReductionIsPaidToClient
	
	ReduceTextIsPaidToClient = "";
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		
		ReduceTextIsPaidToClient = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	DocumentData.Organization                                               AS Organization,
		|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
		|			THEN VALUE(Catalog.Partners.OurEnterprise)
		|		WHEN &ThereIsGiftCertificate = TRUE
		|			THEN &Partner
		|		ELSE Table.Partner
		|	END                                                                     AS Partner,
		|
		|	Table.ARAPObject                                                    AS ARAPObject,
		|
		|	Table.ARAPCurrency                                              AS ARAPCurrency,
		|	Table.AmountARAP                                               AS IncreaseIsPaid,
		|	DocumentData.BusinessOperation                                     AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.CashAccountPayment_)                               AS PaymentMethod,
		|	Table.CashFlowItem                                     AS CashFlowItem,
		|	Table.PaymentRequest                               AS PaymentRequest,
		|	DocumentData.Currency                                                    AS DocumentCurrency,
		|	DocumentData.Date                                                      AS RecorderDate,
		|	DocumentData.Number                                                     AS RecorderNumber
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentData
		|			ON Table.Ref = DocumentData.Ref
		|WHERE
		|	DocumentData.PaymentByRequests 
		|	AND &UsePaymentRequests
		|	AND Table.PaymentRequestToControlPaymentOfPaymentOfARAPObject
		|";
		
	EndIf;
	
	#EndRegion
	
	#Region DebtTransfer_
	
	TextDebtTransfer = "";
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
			
		TextDebtTransfer = "
		|SELECT
		|	Table.Ref                                             AS Ref,
		|	Document.Organization                                       AS Organization,
		|	CASE WHEN Document.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
		|			THEN VALUE(Catalog.Partners.OurEnterprise)
		|		WHEN &ThereIsGiftCertificate = TRUE
		|			THEN &Partner
		|		ELSE Table.Partner
		|	END                                                      AS Partner,
		|	SettlementObjectPayment.Ref                                AS CalculationObjectReceiver,
		|	Table.ARAPObject                                     AS CalculationObjectSource,
		|	
		|	Table.ARAPCurrency                               AS ARAPCurrency,
		|	Document.Currency                                            AS DocumentCurrency,
		|	Table.AmountARAP                                AS AmountARAP,
		|	Table.Sum                                              AS Sum,
		|	
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment) AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.CashAccountPayment_)                AS PaymentMethod,
		|	Document.Number                                             AS RecorderNumber,
		|	Document.Date                                              AS RecorderDate,
		|	Document.Date                                              AS DateOfCourse,
		|	Table.CashFlowItem                      AS CashFlowItem,
		|	Table.PaymentRequest                AS PaymentRequest,
		|	Table.RowID                                AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment) AS BusinessTransactionSetting
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		INNER JOIN DocumentDataHeader AS Document
		|			ON Document.Ref = Table.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS SettlementObjectPayment
		|			ON Table.Ref = SettlementObjectPayment.Object
		|				AND Table.ARAPObjectOfPaymentIsPartner = SettlementObjectPayment.Partner
		|				AND Table.ARAPCurrency = SettlementObjectPayment.ARAPCurrency
		|				AND NOT SettlementObjectPayment.DeletionMark
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON Table.ARAPObject = ARAPObjects.Ref
		|
		|";
	
	EndIf;
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.MakingRefundToClient(Query, QueryTexts, Registers, TextReturn,
		TextDebtTransfer, ReduceTextIsPaidToClient);
	
	#EndRegion
	
	#Region VendorsARAPAccounting
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
	
		TextPayment = "
		|SELECT
		|	Table.Ref                                                   AS Ref,
		|	DocumentData.Organization                                      AS Organization,
		|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
		|		THEN VALUE(Catalog.Partners.OurEnterprise)
		|		ELSE Table.Partner
		|	END                                                            AS Partner,
		|	DocumentData.Date                                             AS RecorderDate,
		|	DocumentData.Number                                            AS RecorderNumber,
		|	
		|	Table.ARAPObject                                           AS ARAPObject,
		|	Table.ARAPCurrency                                     AS ARAPCurrency,
		|	Table.Sum                                                    AS Sum,
		|	Table.AmountARAP                                      AS AmountARAP,
		|	CASE 
		|		WHEN DocumentData.PaymentByRequests 
		|				AND &UsePaymentRequests
		|				AND Table.PaymentRequestToControlPaymentOfPaymentOfARAPObject
		|			THEN Table.AmountARAP 
		|		ELSE 0 
		|	END                                                            AS ReductionIsPaid,
		|	0                                                                AS IncreaseIsPaid,
		|	0                                                                AS SumMan,
		|	0                                                                AS SumCompl,
		|
		|	DocumentData.BusinessOperation                            AS BusinessOperation,
		|	Table.CashFlowItem                            AS CashFlowItem,
		|	Table.PaymentRequest                      AS PaymentRequest,
		|	VALUE(Enum.PaymentForms.CashAccountPayment_)                      AS PaymentMethod,
		|	DocumentData.Currency                                            AS DocumentCurrency,
		|	DocumentData.Date                                              AS DateOfCourse,
		|	Table.MaturityDate                                            AS MaturityDate,
		|	UNDEFINED                                                     AS LinkedDocument,
		|	Table.RowID                                      AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentData
		|			ON Table.Ref = DocumentData.Ref
		|";
	
		MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment);
	
	EndIf;
	
	#EndRegion
	
EndProcedure


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
	|	BusinessTransactionsSettings.BusinessOperation IN (CASE
	|				WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived)
	|					THEN VALUE(Enum.BusinessTransactions.LoanInterestPayment)
	|			END, CASE
	|				WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|					THEN VALUE(Enum.BusinessTransactions.OtherExpenses)
	|			END, CASE
	|				WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|						AND &AccordingToCorrespondenceTable
	|					THEN VALUE(Enum.BusinessTransactions.PaymentForLeaseServices)
	|				ELSE &BusinessOperation
	|			END, CASE
	|				WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|						AND &AccordingToCorrespondenceTable
	|					THEN VALUE(Enum.BusinessTransactions.SecurityPayment)
	|				ELSE &BusinessOperation
	|			END, CASE
	|				WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|						AND &AccordingToCorrespondenceTable
	|					THEN VALUE(Enum.BusinessTransactions.LeaseBuyoutValuePayment)
	|				ELSE &BusinessOperation
	|			END, CASE
	|				WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|						AND &AccordingToCorrespondenceTable
	|					THEN VALUE(Enum.BusinessTransactions.LeaseBuyoutValuePrepayment)
	|				ELSE &BusinessOperation
	|			END)
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

	QueryTextTemplate2 =
	"SELECT
	|	DataTable.Period AS Period,
	|	DataTable.Recorder AS Recorder,
	|	&BusinessOperation AS DataSource,
	|	&Organization AS Organization,
	|	&PaymentDivision AS Department,
	|	&PaymentDivision AS PaymentDivision,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&Cash AS Cash,
	|	&CashType AS CashType,
	|	DataTable.CashFlowItem AS CashFlowItem,
	|	&Currency AS Currency,
	|	&FieldsOfCoreAnalytics,
	|	0 AS AmountToBePaidWithinLimit,
	|	&Sum AS AmountToBePaidAboveLimit,
	|	&Sum AS AmountToBePaid
	|INTO TempTableName
	|FROM
	|	AccumulationRegister.CashAccountBalance AS DataTable
	|		INNER JOIN CorAccumulationRegister AS DataTableBalanced
	|		ON DataTable.Period = DataTableBalanced.Period
	|			AND DataTable.Recorder = DataTableBalanced.Recorder
	|			AND DataTable.FinRecordID = DataTableBalanced.FinRecordID
	|WHERE
	|	DataTable.Active
	|	AND DataTable.FinRecordID <> &IDOfUnusedFinRecord
	|	AND DataTable.Recorder = &Document
	|	AND DataTable.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND &ConditionForApplicationForExpenditureOfFunds
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|			WHERE
	|				&SettingUpBusinessTransaction = BusinessTransactionsSettings.Ref
	|				AND BusinessTransactionsSettings.Receipt = &Receipt
	|				AND BusinessTransactionsSettings.Expense = &Expense)";
	QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&Receipt",
		FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Receipt));
	QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&Expense",
		FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Expense));
	If LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed() Then
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&ConditionForApplicationForExpenditureOfFunds", "TRUE");
	Else
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&ConditionForApplicationForExpenditureOfFunds", "TRUE IN
			|		(SELECT TOP 1
			|			TRUE
			|		FROM
			|			Document.CashVoucher AS DocumentData
			|				LEFT JOIN Document.CashVoucher.ARAPDetails AS PaymentDecryptionTable
			|				ON DocumentData.Ref = PaymentDecryptionTable.Ref
			|		WHERE
			|			DataTable.Recorder = DocumentData.Ref
			|			AND (PaymentDecryptionTable.PaymentRequest IS NULL
			|			OR PaymentDecryptionTable.PaymentRequest IN (UNDEFINED,
			|				VALUE(Document.PaymentRequest.EmptyRef),
			|				VALUE(Document.ApplicationForBusinessTrip.EmptyRef)))
			|			AND DocumentData.PaymentRequest IN (UNDEFINED,
			|				VALUE(Document.PaymentRequest.EmptyRef),
			|				VALUE(Document.ApplicationForBusinessTrip.EmptyRef)))"); // @query-part
	EndIf;
	
	DefaultDataSourceAlias = FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias();
	NameOfExpenseRegister = Metadata.AccumulationRegisters.CashAccountBalance.Name;
	DocumentKind = Common.MetadataObjectID(Metadata.Documents.CashVoucher);
	
	ResidualRegisters = BudgetingCached.ResidualFinancialRegistersByTypeOfDocument(DocumentKind, Receipt, True);
	
	If Receipt = Enums.AccountingDataTypes.Cash Then
		FieldsOfCoreAnalytics = StrSplit("LineOfBusiness,Cash,CashType", ",");
	ElsIf Receipt = Enums.AccountingDataTypes.IncomeExpenses Then
		FieldsOfCoreAnalytics = StrSplit(
			"Department,LineOfBusiness,IncomeAndExpenseItem,DimensionOfExpenses,DimensionOfRevenue", ",");
	ElsIf Receipt = Enums.AccountingDataTypes.Counterparties Then
		FieldsOfCoreAnalytics = StrSplit("LineOfBusiness,Partner,Counterparty,Contract,ARAPObject", ",");
	ElsIf Receipt = Enums.AccountingDataTypes.OtherAssetsLiabilities Then
		FieldsOfCoreAnalytics = StrSplit(
			"Department,LineOfBusiness,AssetAndLiabilityItem,AssetsLiabilitiesDimension", ",");
	Else
		FieldsOfCoreAnalytics = New Array;
	EndIf;

	MotionReflectionParametersExpense = AccumulationRegisters[NameOfExpenseRegister].ParametersForReflectingRegisteredRecordsInFinancialAccounting();
	PathsToFieldDataExpense = FinancialAccountingByBalanceSheetRegisterData.DescriptionsOfPathsToRegisterFieldData(
		MotionReflectionParametersExpense, "DataTable"); // - Structure -
	StructureOfAnalyticsExpense = MotionReflectionParametersExpense.StructureOfAnalytics; // - Structure -
	If StructureOfAnalyticsExpense.Count() = 0 Then
		StructureOfAnalyticsExpense = DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(
			MotionReflectionParametersExpense.TypeOfAccountingData); // - Structure -
	EndIf;
	
	QueriesTexts = New Array;
	
	For Each ResidualRegister In ResidualRegisters Do
		If ResidualRegister.Key = NameOfExpenseRegister Then
			Continue;
		EndIf;
		MotionReflectionParametersReceipt = ResidualRegister.Value;
		PathsToFieldDataReceipt = FinancialAccountingByBalanceSheetRegisterData.DescriptionsOfPathsToRegisterFieldData(
			MotionReflectionParametersReceipt, "DataTableBalanced"); // - Structure -
		StructureOfAnalyticsReceipt = MotionReflectionParametersReceipt.StructureOfAnalytics; // - Structure -
		If StructureOfAnalyticsReceipt.Count() = 0 Then
			StructureOfAnalyticsReceipt = DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(
				MotionReflectionParametersReceipt.TypeOfAccountingData); // - Structure -
		EndIf;
		
		// Source
		QueryText = StrReplace(QueryTextTemplate2, "CorAccumulationRegister", "AccumulationRegister."
			+ ResidualRegister.Key);
		
		// Common Fields
		QueryText = StrReplace(QueryText, "DataTable.Recorder", PathsToFieldDataExpense.Recorder);
		QueryText = StrReplace(QueryText, "DataTableBalanced.Recorder", PathsToFieldDataReceipt.Recorder);
		If Receipt = Enums.AccountingDataTypes.Counterparties Then
			DataPathSettingUpHouseholdOperations = "(" + StrReplace(PathsToFieldDataExpense.AdditionalSetupOfHouseholdOperations,
				DefaultDataSourceAlias, "DataTable") + ")";
		Else
			DataPathSettingUpHouseholdOperations = "(" + StrReplace(PathsToFieldDataReceipt.AdditionalSetupOfHouseholdOperations,
				DefaultDataSourceAlias, "DataTableBalanced") + ")";
		EndIf;
		QueryText = StrReplace(QueryText, "&SettingUpBusinessTransaction", DataPathSettingUpHouseholdOperations);
		QueryText = StrReplace(QueryText, "&BusinessOperation", DataPathSettingUpHouseholdOperations
			+ ".BusinessOperation");
		QueryText = StrReplace(QueryText, "&Organization", PathsToFieldDataExpense.Organization);
		QueryText = StrReplace(QueryText, "&LineOfBusiness",
			PathsToFieldDataExpense.LineOfBusiness);
		
		// Cash Analytics
		For Each Dimension In StructureOfAnalyticsExpense Do
			If Dimension.Key = "Department" Or Dimension.Key = "LineOfBusiness" Then
				If Receipt <> Enums.AccountingDataTypes.Cash Then
					NameOfAnalyticsField = Dimension.Key;
					NameOfAnalyticsField = DataSourcesCached.FieldNameByAccountingDataType(NameOfAnalyticsField, "",
						Expense).FieldName;
					If NameOfAnalyticsField <> Dimension.Key Then
						QueryText = StrReplace(QueryText, " AS " + Dimension.Key + ",", " AS "
							+ NameOfAnalyticsField + ",");
					EndIf;
				EndIf;
				Continue;
			ElsIf Dimension.Value.Property("Value") Then
				TextAnalytic = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(
					Dimension.Value.Value);
			Else
				TextAnalytic = StrReplace(
					FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
					Dimension.Value.DataPath), DefaultDataSourceAlias, "DataTable");
			EndIf;
			QueryText = StrReplace(QueryText, "&" + Dimension.Key, TextAnalytic);
		EndDo;
		QueryText = StrReplace(QueryText, "&Currency", PathsToFieldDataExpense.Currency);
		
		// Cor. Analytics
		RequestAnalyticsFields = New Array;
		For Each Dimension In StructureOfAnalyticsReceipt Do
			If FieldsOfCoreAnalytics.Find(Dimension.Key) = Undefined Then
				Continue;
			EndIf;
			If Dimension.Key = "Department" Or Dimension.Key = "LineOfBusiness" Then
				TextAnalytic = PathsToFieldDataReceipt[Dimension.Key];
			ElsIf Dimension.Value.Property("Value") Then
				TextAnalytic = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(
					Dimension.Value.Value);
			Else
				TextAnalytic = StrReplace(
					FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
					Dimension.Value.DataPath), DefaultDataSourceAlias, "DataTableBalanced");
			EndIf;
			If MotionReflectionParametersExpense.TypeOfAccountingData = MotionReflectionParametersReceipt.TypeOfAccountingData Then
				RequestAnalyticsFields.Add(TextAnalytic + " AS " + Dimension.Value.NameBalanced);
			Else
				NameOfAnalyticsField = Dimension.Key;
				NameOfAnalyticsField = DataSourcesCached.FieldNameByAccountingDataType(NameOfAnalyticsField, "", Receipt).FieldName;
				RequestAnalyticsFields.Add(TextAnalytic + " AS " + NameOfAnalyticsField);
			EndIf;
		EndDo;
		If PathsToFieldDataReceipt.Property("Currency")
			And MotionReflectionParametersExpense.TypeOfAccountingData = MotionReflectionParametersReceipt.TypeOfAccountingData Then
			RequestAnalyticsFields.Add(PathsToFieldDataReceipt.Currency + " AS CorrespondingCurency");
		EndIf;
		QueryAnalyticsFieldString = StrConcat(RequestAnalyticsFields, "," + Chars.LF + Chars.Tab);
		QueryText = StrReplace(QueryText, "&FieldsOfCoreAnalytics", QueryAnalyticsFieldString);
		
		// summary indicators
		If MotionReflectionParametersReceipt.ShaftResources.Count() = 0 Then
			TextAmount = FinancialAccountingByBalanceSheetRegisterData.ResourceSelectionString(
				MotionReflectionParametersExpense.ShaftResources);
			QueryText = StrReplace(QueryText, "&Sum", StrReplace(TextAmount, DefaultDataSourceAlias
				+ ".", "DataTable."));
		Else
			TextAmount = FinancialAccountingByBalanceSheetRegisterData.ResourceSelectionString(
				MotionReflectionParametersReceipt.ShaftResources);
			QueryText = StrReplace(QueryText, "&Sum", StrReplace(TextAmount, DefaultDataSourceAlias
				+ ".", "DataTableBalanced."));
		EndIf;
		
		// Placing it in a temporary table
		If Not IsBlankString(TempTableName) And QueriesTexts.Count() = 0 Then
			QueryText = StrReplace(QueryText, "TempTableName", TempTableName);
		Else
			QueryText = StrReplace(QueryText, "INTO TempTableName", "");
			If IsBlankString(TempTableName) Then
				ConditionForRegistrar = "TRUE IN
				|			(SELECT TOP 1
				|				TRUE
				|			FROM
				|				AccumulationRegister.LimitsByBudgetingData AS LimitsByBudgetingData
				|			WHERE
				|				DataTable.Recorder = LimitsByBudgetingData.Recorder)
				|AND TRUE IN
				|			(SELECT TOP 1
				|				TRUE
				|			FROM
				|				Document.CashVoucher.ARAPDetails AS ARAPDetails
				|			WHERE
				|				DataTable.Recorder = ARAPDetails.Ref
				|				AND ARAPDetails.PaymentRequest IN (UNDEFINED,
				|				VALUE(Document.PaymentRequest.EmptyRef),
				|				VALUE(Document.ApplicationForBusinessTrip.EmptyRef)))"; // @query-part
				QueryText = StrReplace(QueryText, "DataTable.Recorder = &Document", ConditionForRegistrar);
			EndIf;
		EndIf;
		
		QueriesTexts.Add(QueryText);
	
	EndDo;
	
	If QueriesTexts.Count() = 0 Then
		Return "";
	Else
		Return StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	EndIf;
	
EndFunction

#EndRegion
#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Update", Metadata.Documents.CashVoucher) Then
		// The account cash warrant
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "ACW";
		PrintCommand.Presentation = NStr("vi = 'Phiếu chi';
										|ru = 'Расходный кассовый ордер';
										|en = 'Outgoing payment — Cash account'; fa = 'پرداخت خروجی — صندوق';
										|it = 'Mandato di pagamento';
										|pl = 'Asygnata kasowa rozchodowa';
										|tr = 'Giden ödeme - kasa hesabı'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	CashVoucherLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ACW") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ACW",
			NStr("vi = 'Phiếu chi';
				|ru = 'Расходный кассовый ордер';
				|en = 'Outgoing payment — Cash account'; fa = 'پرداخت خروجی — صندوق';
				|it = 'Mandato di pagamento';
				|pl = 'Asygnata kasowa rozchodowa';
				|tr = 'Giden ödeme - kasa hesabı'"),
			FormPrintedFormOfACW(ObjectsArray, PrintObjects, PrintParameters));
	EndIf;
	
	CashVoucherLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Counterparty";
	ArrayOfRecipientDetails = PrintObjectDataStructure.ArrayOfRecipientDetails; // Array of String
	
	ArrayOfRecipientDetails.Add("Counterparty");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		ArrayOfRecipientDetails.Add("ARAPDetails.Partner");
	EndIf;
	
EndProcedure

Function FormPrintedFormOfACW(ObjectsArray, PrintObjects, PrintParameters)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_ACW";
	Template = PrintManagement.PrintFormTemplate("Document.CashVoucher.PF_MXL_CashVoucher");
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	ISNULL(DocumentData.CorrectedDocument.Date, DocumentData.Date) AS DocumentDate,
	|	ISNULL(DocumentData.CorrectedDocument.Number, DocumentData.Number) AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.Description AS CompanyName,
	|	DocumentData.Organization.AbbreviatedDescription AS CompanyNameAbbreviated,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.CashAccount.Department AS DivisionRepresentation,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.Presentation AS CounterpartyPresentation,
	|	DocumentData.Basis AS Basis,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency.Presentation AS CurrencyPresentation,
	|	DocumentData.Issue AS RecipientSFullName
	|FROM
	|	Document.CashVoucher AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Number
	|;";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	Selection           = Query.Execute().Select();
	
	AttributesOfParties = CashServer.InformationAboutRecipientPayerAccordingToDocuments(ObjectsArray);
	
	FirstDocument = True;
	While Selection.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		TemplateArea = Template.GetArea("Header");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, Selection.Ref);
		TemplateArea.Parameters.Fill(Selection);
		
		// Abbreviated name of the payer
		FilterDescriptions = New Structure("Document, Flag", Selection.Ref, 4);
		NameInformation = AttributesOfParties.FindRows(FilterDescriptions);
		
		ParametersStructure = New Structure();
		ParametersStructure.Insert("RepresentationOfTheOrganization");
		If NameInformation.Count() > 0 Then
			ParametersStructure.RepresentationOfTheOrganization = NameInformation[0].AttributeValue;
		Else
			ParametersStructure.RepresentationOfTheOrganization = Selection.CompanyName;
		EndIf;
		TemplateArea.Parameters.Fill(ParametersStructure);
		
		TemplateArea.Parameters.DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(
			Selection.Number, 
			False,
			True);
		
		DataStructureOrganization = PrintFormGeneration.InformationAboutLegalEntity(Selection.Organization,
			Selection.DocumentDate);
		TemplateArea.Parameters.Fill(DataStructureOrganization);
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			Selection.Ref);
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction
#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#Region Other

Function CashFlowArticleOfDocument(DocumentData)

	If ValueIsFilled(DocumentData.CashFlowItem) Then
		CashFlowItem = DocumentData.CashFlowItem;
	Else
		CashFlowItem =
			Catalogs.CashFlowReportItems.PredefinedCFItem(DocumentData.BusinessOperation, DocumentData.Currency);
	EndIf;
	
	Return CashFlowItem;

EndFunction

Function DocumentSubdivision(DocumentData)

	If DocumentData.BusinessOperation = Enums.BusinessTransactions.CashIssueToAnotherCashAccount Then
		Department = CashServer.InitiatorOfCashWithdrawal(
			DocumentData.CashTransferReferenceOrder, DocumentData.CashAccountRecipient);
	Else
		Department = DocumentData.Department;
	EndIf;
	
	Return Department;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
