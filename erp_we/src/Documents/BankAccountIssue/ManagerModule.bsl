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
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
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
	BankAccountIssueLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.BankAccountIssue") Then
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
		
		QueryTextTableBankAccountCash(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCashInTransit(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableCashToBePaid(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCashFlowLimits(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableOtherIncome(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableCashFlow(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject);
		//++ WE
		QueryTextTablePayrollCalculationsHR(Query, QueryTexts, Registers, DocumentObject);
		//-- WE
		QueryTextTableDocumentPostingInFinancialAccounting(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject);
		
		BankAccountIssueLocalization.AddRequestTexts(Query, QueryTexts, Registers);
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
//  Object - DocumentObject.BankAccountIssue - the document to generate parameters for.
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
//  Object - DocumentObject.BankAccountIssue - the document to generate parameters for.
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
	
	NewCommand = Documents.ExpenseReport.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.HasVisibilityConditions = True;
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.IssueCashToAdvanceHolder,
			DataCompositionComparisonType.Equal);
	EndIf;
	
	NewCommand = Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.HasVisibilityConditions = True;
		Available_BusinessTransactions = New Array;
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.CurrencyConversion);
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.IssueCashToAdvanceHolder);
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.SalaryPaymentToBankAccounts);
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram);
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.TransferCashToAnotherAccount);
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices);
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.PaymentToVendor);
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"BusinessOperation",
			Available_BusinessTransactions,
			DataCompositionComparisonType.InList);
	EndIf;
	
	NewCommand = Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.HasVisibilityConditions = True;
		Available_BusinessTransactions = New Array;
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.WithdrawalFromBankAccount);
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.IssueCashToAdvanceHolder);
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"BusinessOperation",
			Available_BusinessTransactions,
			DataCompositionComparisonType.InList);
	EndIf;
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	GenerateFromLocalization.AddCommandCreateExchangeWithBanksBasedOnEmail(GenerationCommands);
	
	If GetFunctionalOption("UseVATAccounting") Then
		
		InvoiceCreationCommand = Documents.ReceivedTaxInvoicePrepayment.AddGenerateCommand(GenerationCommands);
		
		If InvoiceCreationCommand <> Undefined Then
			InvoiceCreationCommand.HasVisibilityConditions = True;
			AttachableCommands.AddCommandVisibilityCondition(InvoiceCreationCommand,
																"OperationWithSelfEmployedPerson",
																True,
																DataCompositionComparisonType.NotEqual);
		EndIf;
		
	EndIf;
	
	BusinessOperationsForCorrection = New Array;
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.PaymentToVendor);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.RefundToCustomer);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.IssueCashToAdvanceHolder);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.OtherCashIssue);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.TransferToDeposits);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashIssueAsLoanToCounterparty);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.CashIssueAsLoanToEmployee);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.PaymentToLessor);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.RefundAcquiringPayment);
	BusinessOperationsForCorrection.Add(Enums.BusinessTransactions.TransferOfTaxesAndContributions);
	
	CommandCorrection = DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	
	If CommandCorrection <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			CommandCorrection,
			"BusinessOperation",
			BusinessOperationsForCorrection,
			DataCompositionComparisonType.InList);
		
	EndIf;
	
	TheStornoTeam = DocumentCorrection.AddReverseCommand(
		GenerationCommands,
		EmptyRef().Metadata());
	
	If TheStornoTeam <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			TheStornoTeam,
			"BusinessOperation",
			BusinessOperationsForCorrection,
			DataCompositionComparisonType.InList);
		
	EndIf;
	
	CreationBasedOnCommand = Documents.BankConfirmationAboutCashReceiptOnEmployeeAccount.AddGenerateCommand(GenerationCommands);
	
	If CreationBasedOnCommand <> Undefined Then
		
		ArrayOfBusinessOperations = New Array;
		
		If GetFunctionalOption("UsePayrollTM") Then
			ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram);
		EndIf;
		
		If GetFunctionalOption("UseCashDepositToListEmployees") Then
			ArrayOfBusinessOperations.Add(Enums.BusinessTransactions.IssueCashToAdvanceHolder);
		EndIf;
		
		AttachableCommands.AddCommandVisibilityCondition(CreationBasedOnCommand,
															"BusinessOperation",
															ArrayOfBusinessOperations,
															DataCompositionComparisonType.InList);
		
	EndIf;
	
	BankAccountIssueLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "Write off non-cash DS".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Order - Number - The order of the command.
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
Function AddGenerateCommand(GenerationCommands, Order = 0) Export
	
	If AccessRight("Insert", Metadata.Documents.BankAccountIssue) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.BankAccountIssue.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.BankAccountIssue);
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
	
	BankAccountIssueLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	CASE WHEN DocumentsTable.ProcessedByBank THEN
	|		&ConductedByBank
	|	ELSE
	|		&TransactionNotConductedByBank
	|	END AS PresentationOfCurStatus,
	|	&ConductedByBank AS PresentationOfNewStatus,
	|	DocumentsTable.ProcessedByBank AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.BankAccountIssue AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("ConductedByBank", NStr("vi = 'Kiểm tra bởi ngân hàng';
												|ru = 'Проведено банком';
												|en = 'Processed by bank'; fa = 'پردازش‌شده توسط بانک';
												|it = 'Effettuato a cura della banca';
												|pl = 'Potwierdzono przez bank';
												|tr = 'Banka tarafından kaydedildi'"));
	Query.SetParameter("TransactionNotConductedByBank", NStr("vi = 'Chưa thực hiện bởi ngân hàng';
															|ru = 'Не проведено банком';
															|en = 'Not processed by bank'; fa = 'پردازش‌نشده توسط بانک';
															|it = 'Non è stato registrato dalla banca';
															|pl = 'Nie potwierdzono przez bank';
															|tr = 'Banka tarafından kaydedilmedi'"));
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - String - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks
	
EndFunction

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
			"BusinessOperation,
			|ProcessedByBank,
			|ListOfCounterparties_,
			|OperationWithSelfEmployedPerson,
			|Date,
			|BankPostingDate");
		BusinessOperation = StructureFillingData.BusinessOperation;
		ProcessedByBank       = StructureFillingData.ProcessedByBank;
		ListOfCounterparties_    = StructureFillingData.ListOfCounterparties_;
		OperationWithSelfEmployedPerson = StructureFillingData.OperationWithSelfEmployedPerson;
		DocumentDate         = StructureFillingData.Date;
		BankPostingDate  = StructureFillingData.BankPostingDate;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
		ProcessedByBank       = False;
		ListOfCounterparties_    = False;
		OperationWithSelfEmployedPerson = False;
		DocumentDate         = Date('00010101');
		BankPostingDate  = Date('00010101');
	Else
		BusinessOperation = FillingData.BusinessOperation;
		ProcessedByBank       = FillingData.ProcessedByBank;
		ListOfCounterparties_    = FillingData.ListOfCounterparties_;
		OperationWithSelfEmployedPerson = FillingData.OperationWithSelfEmployedPerson;
		DocumentDate         = FillingData.Date;
		BankPostingDate  = FillingData.BankPostingDate;
	EndIf;
	
	StructuresArray = New Array();
	
	#Region AllOtherFunctions
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	If BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ElsIf BusinessOperation =Enums.BusinessTransactions.PaymentToVendor
		Or BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.CustomsPayment Then
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	EndIf;
	
	ParametersStructure.ChangesPaymentPlan =
		BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.CustomsPayment;
	
	ParametersStructure.ChangesCalculationsByString               = 
		"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToVendor)
		|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
		|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.CustomsPayment)
		|	OR
		|//Conditions of return beginning
		|	DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
		|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
		|//Conditions of return end";
	ParametersStructure.ModifiesDeliveryShipmentPlan = False;
	
	If BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
		ParametersStructure.Counterparty                             = "Object.BankAccountBeneficiary.Owner";
		ParametersStructure.Partner                                = Catalogs.Partners.OurEnterprise;
	ElsIf (BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		And OperationWithSelfEmployedPerson)
		And ListOfCounterparties_ Then
		ParametersStructure.Counterparty                             = "Object.ARAPDetails.Counterparty";
		ParametersStructure.Partner                                = "Object.ARAPDetails.Partner";
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
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	
	If ProcessedByBank
		And BegOfDay(DocumentDate) <> BankPostingDate Then
		ParametersStructure.Date                             = "Object.BankPostingDate";
	Else
		ParametersStructure.Date                             = "Object.Date";
	EndIf;

	ParametersStructure.PaymentID             = "";
	
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.VATTaxation               = "Object.VATTaxation";
	
	ParametersStructure.FormItems.ARAPDetails               = "ARAPDetails";
	ParametersStructure.FormItems.AddToPaymentDecryption        = "ARAPDetailsSelectionByStock";
	ParametersStructure.PaymentsAsPer275FZ                                 = "Object.PaymentsAsPer275FZ";
	
	ParametersStructure.PartnerOtherRelations = BusinessOperation = Enums.BusinessTransactions.CustomsPayment;
	
	ParametersStructure.SelectOnlyUnconditionalDebt = BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany;
	ParametersStructure.PaymentByRequests                  = "Object.PaymentByRequests";
	
	ParametersStructure.OperationWithSelfEmployedPerson = "Object.OperationWithSelfEmployedPerson";
	
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
			|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.CustomsPayment)
			|	OR
			|//Conditions of return beginning
			|	DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
			|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
			|//Conditions of return end";
		ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
		
		If BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
			ParametersStructure.Counterparty                             = "Object.BankAccountBeneficiary.Owner";
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
		ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
		ParametersStructure.CounterpartyBankAccount        = "";
		ParametersStructure.CashAccount                            = "";
		If ProcessedByBank
			And BegOfDay(DocumentDate) <> BankPostingDate Then
			ParametersStructure.Date                             = "Object.BankPostingDate";
		Else
			ParametersStructure.Date                             = "Object.Date";
		EndIf;
		ParametersStructure.PaymentID             = "";
		
		ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
		ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
		ParametersStructure.VATTaxation               = "Object.VATTaxation";
		
		ParametersStructure.MutualSettlementsCurrencyViewOnly = True;
		ParametersStructure.DocumentCurrencyViewOnly      = True;
		
		StructuresArray.Add(ParametersStructure);
		
	EndIf;
	
	#EndRegion
	
	Return StructuresArray;
EndFunction

#Region Other

// The procedure fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	Object - DocumentObject.BankAccountIssue, Structure - Document data.
//	ArrayOfAllProps - Array of String - Array of all the names of banking details that depend on the business operation.
//	ArrayOfOperationDetails - Array of String - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(Object, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	BusinessOperation = Object.BusinessOperation;
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("CounterpartyBankAccount");
	ArrayOfAllProps.Add("BankAccountBeneficiary");
	ArrayOfAllProps.Add("CurrencyOfConversion");
	ArrayOfAllProps.Add("ExpenseReportDate");
	ArrayOfAllProps.Add("PaymentRequest");
	ArrayOfAllProps.Add("CashAccountRecipient");
	ArrayOfAllProps.Add("Counterparty");
	ArrayOfAllProps.Add("ConversionRate");
	ArrayOfAllProps.Add("ConversionRateMultiplier");
	ArrayOfAllProps.Add("PaymentByRequests");
	ArrayOfAllProps.Add("AdvanceHolder");
	ArrayOfAllProps.Add("Department");
	ArrayOfAllProps.Add("CashTransferReferenceOrder");
	ArrayOfAllProps.Add("CashFlowItem");
	ArrayOfAllProps.Add("ConversionAmount");
	ArrayOfAllProps.Add("AcquiringContract");
	ArrayOfAllProps.Add("TaxType");
	ArrayOfAllProps.Add("PaymentWithConversion");
	ArrayOfAllProps.Add("AmountInPayerSCurrency");
	ArrayOfAllProps.Add("KeepRecordsOfCommissionInARAPAccounting");
	ArrayOfAllProps.Add("CommissionARAPObject");
	
	ArrayOfAllProps.Add("FinancialAccountingGroup");
	ArrayOfAllProps.Add("LineOfBusiness");
	ArrayOfAllProps.Add("Contract");
	ArrayOfAllProps.Add("VATTaxation");
	
	ArrayOfAllProps.Add("ARAPDetails");
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
	ArrayOfAllProps.Add("ARAPDetails.TypeOfLeasePayment");
	ArrayOfAllProps.Add("ARAPDetails.LoanAndDepositAmountType");
	ArrayOfAllProps.Add("ARAPDetails.Organization");
	ArrayOfAllProps.Add("ARAPDetails.LineOfBusiness");
	ArrayOfAllProps.Add("ARAPDetails.MaturityDate");
	ArrayOfAllProps.Add("ARAPDetails.Counterparty");
	
	ArrayOfAllProps.Add("PersonalAccountsOfStaff");
	ArrayOfAllProps.Add("PersonalAccountsOfStaff.Individual");
	ArrayOfAllProps.Add("PersonalAccountsOfStaff.PersonalAccount");
	ArrayOfAllProps.Add("PersonalAccountsOfStaff.Sum");
	ArrayOfAllProps.Add("PersonalAccountsOfStaff.CashFlowItem");
	
	ArrayOfOperationDetails = New Array;
	ArrayOfOperationDetails.Add("Department");
	
	If BusinessOperation = Enums.BusinessTransactions.PaymentToVendor Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		ArrayOfOperationDetails.Add("AmountInPayerSCurrency");
	
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
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
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		ArrayOfOperationDetails.Add("AmountInPayerSCurrency");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("ExpenseReportDate");
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("Counterparty");
		
		If Not Object.PersonsList Then
			ArrayOfOperationDetails.Add("PaymentWithConversion");
			ArrayOfOperationDetails.Add("AmountInPayerSCurrency");
		EndIf;
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
		ArrayOfOperationDetails.Add("PersonalAccountsOfStaff");
		ArrayOfOperationDetails.Add("PersonalAccountsOfStaff.Individual");
		ArrayOfOperationDetails.Add("PersonalAccountsOfStaff.PersonalAccount");
		ArrayOfOperationDetails.Add("PersonalAccountsOfStaff.Sum");
		ArrayOfOperationDetails.Add("PersonalAccountsOfStaff.CashFlowItem");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferCashToAnotherAccount Then
		ArrayOfOperationDetails.Add("BankAccountBeneficiary");
		ArrayOfOperationDetails.Add("CashTransferReferenceOrder");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount Then
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		ArrayOfOperationDetails.Add("CashTransferReferenceOrder");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
		ArrayOfOperationDetails.Add("BankAccountBeneficiary");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		ArrayOfOperationDetails.Add("AmountInPayerSCurrency");
		
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
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		ArrayOfOperationDetails.Add("AmountInPayerSCurrency");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Department");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.LineOfBusiness");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CustomsPayment Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		ArrayOfOperationDetails.Add("AmountInPayerSCurrency");
		
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		ArrayOfOperationDetails.Add("ARAPDetails.MaturityDate");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("TaxType");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany Then
		ArrayOfOperationDetails.Add("BankAccountBeneficiary");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		ArrayOfOperationDetails.Add("AmountInPayerSCurrency");
		
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("VATTaxation");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPObject");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.VATRate");
		ArrayOfOperationDetails.Add("ARAPDetails.VATAmount");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.Organization");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		ArrayOfOperationDetails.Add("BankAccountBeneficiary");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("CashFlowItem");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("BankAccountBeneficiary");
		ArrayOfOperationDetails.Add("CurrencyOfConversion");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("ConversionRate");
		ArrayOfOperationDetails.Add("ConversionRateMultiplier");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("ConversionAmount");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToDeposits Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
		ArrayOfOperationDetails.Add("ARAPDetails.LoanDepositContract");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		ArrayOfOperationDetails.Add("AmountInPayerSCurrency");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
		ArrayOfOperationDetails.Add("ARAPDetails.LoanDepositContract");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		ArrayOfOperationDetails.Add("AmountInPayerSCurrency");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
		ArrayOfOperationDetails.Add("ARAPDetails.LoanDepositContract");
		ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
		ArrayOfOperationDetails.Add("ARAPDetails.AmountARAP");
		ArrayOfOperationDetails.Add("ARAPDetails.ARAPCurrency");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		ArrayOfOperationDetails.Add("ARAPDetails.LoanAndDepositAmountType");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee Then
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("Counterparty");
		
		If GetFunctionalOption("UsePayrollTM") Then
			ArrayOfOperationDetails.Add("ARAPDetails");
			ArrayOfOperationDetails.Add("ARAPDetails.EmployeeLoanAgreement");
			ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
			ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
			ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		Else
			ArrayOfOperationDetails.Add("PaymentRequest");
			ArrayOfOperationDetails.Add("CashFlowItem");
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("Counterparty");
		
		If GetFunctionalOption("UsePayrollTM") Then
			ArrayOfOperationDetails.Add("ARAPDetails");
			ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
			ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
			ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		Else
			ArrayOfOperationDetails.Add("PaymentRequest");
			ArrayOfOperationDetails.Add("CashFlowItem");
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("AdvanceHolder");
		
		If GetFunctionalOption("UsePayrollTM") 
		//++ WE
		Or GetFunctionalOption("PayrollAndHumanResourcesWE") 
		//-- WE
		Or False Then
			ArrayOfOperationDetails.Add("ARAPDetails");
			ArrayOfOperationDetails.Add("ARAPDetails.CashFlowItem");
			ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
			ArrayOfOperationDetails.Add("ARAPDetails.Comment");
		Else
			ArrayOfOperationDetails.Add("PaymentRequest");
			ArrayOfOperationDetails.Add("CashFlowItem");
		EndIf;
		
		If ValueIsFilled(Object.Counterparty) Then
			ArrayOfOperationDetails.Add("Counterparty");
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment Then
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("AcquiringContract");
		ArrayOfOperationDetails.Add("ExpensesBusinessUnit");
		ArrayOfOperationDetails.Add("LineOfBusiness");
		ArrayOfOperationDetails.Add("RecordCommission");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("KeepRecordsOfCommissionInARAPAccounting");
		ArrayOfOperationDetails.Add("CommissionARAPObject");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.PaymentRequest");
		ArrayOfOperationDetails.Add("ARAPDetails.Comment");
	ElsIf BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Counterparty");
		ArrayOfOperationDetails.Add("PaymentByRequests");
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("PaymentWithConversion");
		ArrayOfOperationDetails.Add("AmountInPayerSCurrency");
		
		ArrayOfOperationDetails.Add("ARAPDetails");
		ArrayOfOperationDetails.Add("ARAPDetails.Partner");
		ArrayOfOperationDetails.Add("ARAPDetails.Counterparty");
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

// Determines the composition of households. document operations that do not use the payment transcript if there are no requests for
// the DS expense.
//
// Returns:
//    Array - business transactions without the use of payment decryption.
//
Function ArrayOfOperationsWithoutPaymentDecryption() Export
	
	OperationArray = New Array;
	
	OperationArray.Add(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices);
	OperationArray.Add(Enums.BusinessTransactions.CurrencyConversion);
	OperationArray.Add(Enums.BusinessTransactions.RefundAcquiringPayment);
	
	Return OperationArray;
	
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
	
	FilterTransferToEmployeeViaABank = New DataCompositionFilter();
	AndGroup = Finances.NewFilter(FilterTransferToEmployeeViaABank, , , Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "TransferToEmployeeViaABank", True);
	UnderGroupOr = Finances.NewFilter(AndGroup, , , Type("DataCompositionFilterItemGroup"));
	UnderGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	
	FilterPaymentToSelfEmployed = CashServer.FilterPaymentToSelfEmployed();
	FilterListOfCounterparties_ = CashServer.FilterListOfCounterparties_(FilterPaymentToSelfEmployed);
	
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
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.TransferOfTaxesAndContributions);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.SalaryPaymentByPayrollCardProgram);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.RefundAcquiringPayment);
	Finances.NewFilter(UnderGroupOr, "BusinessOperation", Operations.PaymentToLessor);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, UnderGroupOr);
	
	ConditionOfApplicationForBusinessTrip = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	ConditionOfApplicationForBusinessTrip.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(ConditionOfApplicationForBusinessTrip, "More.UseApplicationsForBusinessTrip", True);
	Finances.NewFilter(ConditionOfApplicationForBusinessTrip, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("PaymentByRequests");
	Finances.NewFilter(Item.Condition, "More.EnabledCreatingCashIssueWithoutPaymentRequest", True);
	Item.Properties.Insert("Enabled");
	
	// ProcessedByBank
	Item = Settings.Add();
	Item.Fields.Add("ProcessedByBank");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.CollectionOrder_2);
	Finances.NewFilter(OrGroup, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.PaymentWarrant);
	Finances.NewFilter(OrGroup, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.BankPaymentOrder);
	Item.Properties.Insert("ReadOnly");
	
	// BankPostingDate
	Item = Settings.Add();
	Item.Fields.Add("BankPostingDate");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "ProcessedByBank", False);
	Finances.NewFilter(OrGroup, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.PaymentWarrant);
	Finances.NewFilter(OrGroup, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.BankPaymentOrder);
	Item.Properties.Insert("OnlyViewWithoutBlankMark");
	
	// The date of the incoming document, the number of the incoming document
	Item = Settings.Add();
	Item.Fields.Add("IncomingDocumentDate");
	Item.Fields.Add("IncomingDocumentNumber");
	Finances.NewFilter(Item.Condition, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.PaymentOrder);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
	// AdvanceHolder
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	Item.Properties.Insert("Title", NStr("vi = 'Người lao động';
										|ru = 'Работник';
										|en = 'Employee'; fa = 'کارمند';
										|it = 'Dipendente';
										|pl = 'Employee';
										|tr = 'Çalışan'"));
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Item.Properties.Insert("Title", NStr("vi = 'Người nhận tạm ứng';
										|ru = 'Подотчетное лицо';
										|en = 'Advance holder'; fa = 'تنخواه‌دار';
										|it = 'Titolare di anticipo';
										|pl = 'Osoba rozliczająca się za wydatki';
										|tr = 'Sorumlu kişi'"));
	
	Item = Settings.Add();
	Item.Fields.Add("AdvanceHolder");
	Finances.NewFilter(Item.Condition, "PersonsList", True);
	Item.Properties.Insert("Enabled", False);
	
	// BankAccountBeneficiary
	Item = Settings.Add();
	Item.Fields.Add("BankAccountBeneficiary");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashToAnotherAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("BankAccountBeneficiary");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản ngân hàng mua';
										|ru = 'Счет зачисления';
										|en = 'Account of acceptance'; fa = 'Account of acceptance';
										|it = 'Conto di accredito';
										|pl = 'Rachunek dla zaliczenia';
										|tr = 'Tahakkuk hesabı'"));
	
	Item = Settings.Add();
	Item.Fields.Add("BankAccountBeneficiary");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashToAnotherAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản người nhận';
										|ru = 'Счет получателя';
										|en = 'Payee account'; fa = 'حساب ذی‌نفع';
										|it = 'Conto del destinatario';
										|pl = 'Rachunek odbiorcy';
										|tr = 'Alıcı hesabı'"));
	
	// Counterparty
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Item.Fields.Add("CounterpartyCheckIssueCounterpartyPages");
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentByPayrollCardProgram);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundAcquiringPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	Finances.CopyFilter(FilterTransferToEmployeeViaABank, OrGroup);
	Finances.CopyFilter(FilterListOfCounterparties_, OrGroup);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Item.Properties.Insert("Title", NStr("vi = 'Người nhận';
										|ru = 'Получатель';
										|en = 'Recipient'; fa = 'گیرنده';
										|it = 'Destinatario';
										|pl = 'Recipient';
										|tr = 'Alıcı'"));
	
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
	OrGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.CopyFilter(FilterTransferToEmployeeViaABank, OrGroup);
	Finances.CopyFilter(FilterListOfCounterparties_, OrGroup);
	Item.Properties.Insert("Title", NStr("vi = 'Ngân hàng người nhận';
										|ru = 'Банк-получатель';
										|en = 'Receiving bank'; fa = 'Receiving bank';
										|it = 'Banca-destinatario';
										|pl = 'Receiving bank';
										|tr = 'Alıcı banka'"));
	
	Item = Settings.Add();
	Item.Fields.Add("Counterparty");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Nhà môi giới';
										|ru = 'Брокер';
										|en = 'Broker'; fa = 'کارگزار';
										|it = 'Брокер';
										|pl = 'Broker';
										|tr = 'Komisyoncu'"));
	
	// Recipient
	FilterPaymentToSelfEmployed = CashServer.FilterPaymentToSelfEmployed();
	Item = Settings.Add();
	Item.Fields.Add("LocalizationRecipientGroup");
	Finances.CopyFilter(FilterPaymentToSelfEmployed, Item.Condition);
	Item.Properties.Insert("Visible");
	
	// Contract For Connection To The Payment System
	Item = Settings.Add();
	Item.Fields.Add("AcquiringContract");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.RefundAcquiringPayment);
	Item.Properties.Insert("Visible");
	
	// CounterpartyBankAccount
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferOfTaxesAndContributions);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentByPayrollCardProgram);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundAcquiringPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	Item.Properties.Insert("ReadOnly", True);
	
	OFOperationsWithIndividuals = New Array;
	OFOperationsWithIndividuals.Add(Operations.IssueCashToAdvanceHolder);
	OFOperationsWithIndividuals.Add(Operations.CashIssueAsLoanToEmployee);
	OFOperationsWithIndividuals.Add(Operations.SalaryPaymentToBankAccounts);
	
	OrGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	CounterpartyIsNotFilledIn = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	CounterpartyIsNotFilledIn.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	Finances.NewFilter(CounterpartyIsNotFilledIn, "Counterparty", , , DataCompositionComparisonType.NotFilled);

	UnderGroupOr = Finances.NewFilter(CounterpartyIsNotFilledIn, , , Type("DataCompositionFilterItemGroup"));
	UnderGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	TransferViaBank = Finances.NewFilter(UnderGroupOr, , , Type("DataCompositionFilterItemGroup"));
	TransferViaBank.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	Finances.NewFilter(TransferViaBank, "BusinessOperation", OFOperationsWithIndividuals, , DataCompositionComparisonType.InList);
	Finances.NewFilter(TransferViaBank, "TransferToEmployeeViaABank", True);
	
	Other_Operations = Finances.NewFilter(UnderGroupOr, , , Type("DataCompositionFilterItemGroup"));
	Other_Operations.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
	Finances.NewFilter(Other_Operations, "BusinessOperation", OFOperationsWithIndividuals, , DataCompositionComparisonType.InList);
	
	PhysicalPersonNotFilledIn = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	PhysicalPersonNotFilledIn.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	Finances.NewFilter(PhysicalPersonNotFilledIn, "AdvanceHolder", , , DataCompositionComparisonType.NotFilled);
	Finances.NewFilter(PhysicalPersonNotFilledIn, "BusinessOperation", OFOperationsWithIndividuals, , DataCompositionComparisonType.InList);
	Finances.NewFilter(PhysicalPersonNotFilledIn, "TransferToEmployeeViaABank", False);
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản nhà môi giới';
										|ru = 'Счет брокера';
										|en = 'Broker account'; fa = 'Broker account';
										|it = 'Счет брокера';
										|pl = 'Broker account';
										|tr = 'Komisyoncunun hesabı'"));
	
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion, , DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Title", NStr("vi = 'Tài khoản người nhận';
										|ru = 'Счет получателя';
										|en = 'Payee account'; fa = 'حساب ذی‌نفع';
										|it = 'Conto del destinatario';
										|pl = 'Rachunek odbiorcy';
										|tr = 'Alıcı hesabı'"));
	
	// CashAccountRecipient
	Item = Settings.Add();
	Item.Fields.Add("CashAccountRecipient");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.WithdrawalFromBankAccount);
	Item.Properties.Insert("Visible");
	
	// CashFlowItem
	Item = Settings.Add();
	Item.Fields.Add("CashFlowItem");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundAcquiringPayment);
	
	AndGroup1 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(AndGroup1, "More.UsePayrollTM", False);
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "BusinessOperation", Operations.SalaryPaymentByPayrollCardProgram);
	Finances.NewFilter(AndGroup2, "More.UsePayrollTM", False);
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	Finances.NewFilter(AndGroup2, "More.UsePayrollTM", False);
	//++ WE
	Finances.NewFilter(AndGroup2, "More.PayrollAndHumanResourcesWE", False);
	//-- WE 
	
	Item.Properties.Insert("Visible");
	
	// CashTransferReferenceOrder
	Item = Settings.Add();
	Item.Fields.Add("CashTransferReferenceOrder");
	OrGroup1 = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup1, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.PaymentOrder);
	Finances.NewFilter(OrGroup1, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.BankPaymentOrder);
	Finances.NewFilter(OrGroup1, "PaymentDocumentType", Enums.TypesOfPaymentDocuments.PaymentWarrant);
	OrGroup2 = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.TransferCashToAnotherAccount);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.WithdrawalFromBankAccount);
	Item.Properties.Insert("Visible");
	
	// PaymentRequest
	Item = Settings.Add();
	Item.Fields.Add("PaymentRequest");
	Finances.NewFilter(Item.Condition, "More.UsePayrollTM", False);
	//++ WE
	Finances.NewFilter(Item.Condition, "More.PayrollAndHumanResourcesWE", False);
	//-- WE
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentByPayrollCardProgram);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("PaymentRequest");
	Finances.NewFilter(Item.Condition, "More.EnabledCreatingCashIssueWithoutPaymentRequest", True);
	Finances.NewFilter(Item.Condition, "PaymentByRequests", False);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
	// Counterparty's Bank account
	Item = Settings.Add();
	Item.Fields.Add("CounterpartyBankAccount");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.CurrencyConversion);
	Item.Properties.Insert("AutoMarkIncomplete", False);
	Item.Properties.Insert("MarkIncomplete", False);
	
	// TaxType
	Item = Settings.Add();
	Item.Fields.Add("TaxType");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.TransferOfTaxesAndContributions);
	Item.Properties.Insert("Visible");
	
	// Type of transfer to the accountable person
	Item = Settings.Add();
	Item.Fields.Add("TransferToEmployeeViaABank");
	Item.Properties.Insert("Visible", True);
	GroupsOr = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	GroupsOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(GroupsOr, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	//++ WE
	If Not GetFunctionalOption("PayrollAndHumanResourcesWE") Then
	//-- WE
		Finances.NewFilter(GroupsOr, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	//++ WE
	EndIf;
	//-- WE
	Finances.NewFilter(GroupsOr, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	
	Item = Settings.Add();
	Item.Fields.Add("TransferToEmployeeViaABank");
	Item.Properties.Insert("Enabled", False);
	Finances.NewFilter(Item.Condition, "PersonsList", True);
	
	// Personal account
	Item = Settings.Add();
	Item.Fields.Add("PersonalAccountsOfStaff");
	
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(Item.Condition, "PersonsList", True);
	
	Item.Properties.Insert("Visible");
	
	// An inscription on the availability of a document on crediting DS to personal accounts
	Item = Settings.Add();
	Item.Fields.Add("DecorationAbsenceOfCashCreditingToAccounts");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(Item.Condition, "PersonsList", True);
	Finances.NewFilter(Item.Condition, "More.AvailabilityOfCashTransferDocument", False);
	Item.Properties.Insert("Visible");
	Item.Properties.Insert("TextColor", StyleColors.TextColorWarning);
	
	// List of individuals
	Item = Settings.Add();
	Item.Fields.Add("ListOfIndividualsIncluded");
	Item.Fields.Add("ListOfIndividualsDisabled");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(Item.Condition, "TransferToEmployeeViaABank", True);
	Finances.NewFilter(Item.Condition, "More.UseCashDepositToListEmployees", True);
	Item.Properties.Insert("Visible");
	
	// Article DDS conversion
	Item = Settings.Add();
	Item.Fields.Add("CashFlowItemConversion");
	Finances.NewFilter(Item.Condition, "PaymentWithConversion", True);
	ThereAreNoGroups = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	ThereAreNoGroups.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.NewFilter(ThereAreNoGroups, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Visible");
	
	// CommissionAgreement
	Item = Settings.Add();
	Item.Fields.Add("CommissionAgreement");
	Finances.NewFilter(Item.Condition, "KeepRecordsOfCommissionInARAPAccounting", True);
	Item.Properties.Insert("Visible");
	
	// KeepRecordsOfCommissionInMutualSettlementsSwitch
	Item = Settings.Add();
	Item.Fields.Add("KeepRecordsOfCommissionInMutualSettlementsSwitch");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.RefundAcquiringPayment);
	Item.Properties.Insert("Visible");
	
	#EndRegion
	
	#Region Attributes
	// DocumentAmount
	Item = Settings.Add();
	Item.Fields.Add("DocumentAmount");
	Finances.NewFilter(Item.Condition, "PaymentWithConversion", True);
	Item.Properties.Insert("Title", NStr("vi = 'Số tiền thanh toán';
										|ru = 'Сумма платежа';
										|en = 'Payment amount'; fa = 'مبلغ پرداخت';
										|it = 'Importo di pagamento';
										|pl = 'Wartość płatności';
										|tr = 'Ödeme tutarı'"));
	
	Item = Settings.Add();
	Item.Fields.Add("DocumentAmount");
	Finances.NewFilter(Item.Condition, "PaymentWithConversion", False);
	Item.Properties.Insert("Title", NStr("vi = 'Số tiền';
										|ru = 'Сумма';
										|en = 'Amount'; fa = 'مبلغ';
										|it = 'Сумма';
										|pl = 'Amount';
										|tr = 'Tutar'"));
	//++ WE
	Item = Settings.Add();
	Item.Fields.Add("DocumentAmount");
	AndGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	Finances.NewFilter(AndGroup, "More.PayrollAndHumanResourcesWE", True);
	Item.Properties.Insert("ReadOnly");
	//-- WE
	
	// Currency
	Item = Settings.Add();
	Item.Fields.Add("Currency");
	Filteroperations = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	Filteroperations.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.PaymentToVendor);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.RefundToCustomer);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(Filteroperations, "BusinessOperation", Operations.PaymentToLessor);
	
	PaymentToOneAccountablePerson = Finances.NewFilter(Filteroperations, , , Type("DataCompositionFilterItemGroup"));
	PaymentToOneAccountablePerson.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(PaymentToOneAccountablePerson, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(PaymentToOneAccountablePerson, "PersonsList", False);
	
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", True);
	Item.Properties.Insert("ReadOnly", False);
	
	// LabelCurrency
	Item = Settings.Add();
	Item.Fields.Add("LabelCurrency");
	Item.Fields.Add("LabelCurrencyCommission");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", False);
	Item.Properties.Insert("Visible");
	
	// AmountInRecipientsCurrency
	Item = Settings.Add();
	Item.Fields.Add("AmountInPayerSCurrency");
	Item.Fields.Add("BankAccountCashCurrency");
	Finances.NewFilter(Item.Condition, "PaymentWithConversion", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("AmountInPayerSCurrency");
	Finances.NewFilter(Item.Condition, "PaymentWithConversion", True);
	Finances.NewFilter(Item.Condition, "ProcessedByBank", False);
	Item.Properties.Insert("Enabled", False);
	
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
	Item.Fields.Add("BankAccountForFeeWriteOff");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CurrencyConversion);
	Item.Properties.Insert("Visible");
	
	// Currency payment
	Item = Settings.Add();
	Item.Fields.Add("TransferFeeType");
	Item.Fields.Add("CodesOfInstructionsForBank");
	Item.Fields.Add("InformationToPaymentRecipient");
	Finances.NewFilter(Item.Condition, "More.CurrencyPayment", True);
	Finances.NewFilter(Item.Condition, "More.UseCurrencyPayments", True);
	Finances.NewFilter(Item.Condition, "More.ThisIsATransitAccount", False);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("InformationForRegulatoryBodies");
	Finances.NewFilter(Item.Condition, "More.CurrencyPayment", True);
	Finances.NewFilter(Item.Condition, "More.UseCurrencyPayments", True);
	Finances.NewFilter(Item.Condition, "More.InformationForRegulatoryBodiesIsRequired", True);
	Finances.NewFilter(Item.Condition, "More.ThisIsATransitAccount", False);
	Item.Properties.Insert("Visible");
	
	// InsertIntoAssignment
	Item = Settings.Add();
	Item.Fields.Add("InsertIntoAssignment");
	Finances.NewFilter(Item.Condition, "More.ForeignExchangeControl", True);
	Finances.NewFilter(Item.Condition, "More.UseCurrencyPayments", True);
	Item.Properties.Insert("Visible");
	
	// LabelInvertedPayment
	Item = Settings.Add();
	Item.Fields.Add("LabelInvertedPayment");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	Item.Properties.Insert("Visible");
	
	// Fee
	Item = Settings.Add();
	Item.Fields.Add("GroupCommission");
	Finances.NewFilter(Item.Condition, "RecordCommission", True);
	Item.Properties.Insert("Visible");
	
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
	Finances.NewFilter(Item.Condition, "More.EnabledCreatingCashIssueWithoutPaymentRequest", True);
	Finances.NewFilter(Item.Condition, "PaymentByRequests", False);
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
	Finances.NewFilter(AndGroup, "PaymentByRequests", True);
	OrGroup2 = Finances.NewFilter(AndGroup,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.RefundAcquiringPayment);
	
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.UsePayrollTM", True);
	OrGroup2 = Finances.NewFilter(AndGroup,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.SalaryPaymentByPayrollCardProgram);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	
	//++ WE
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.PayrollAndHumanResourcesWE", True);
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	//-- WE
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(AndGroup, "PersonsList", False);
	
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(AndGroup, "PersonsList", True);
	Finances.NewFilter(AndGroup, "PaymentByRequests", True);
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
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(Item.Condition, "PersonsList", True);
	Finances.NewFilter(Item.Condition, "PaymentByRequests", True);
	Item.Properties.Insert("Title", NStr("vi = 'Giấy đề nghị thanh toán';
										|ru = 'Заявки на оплату';
										|en = 'Payment requests'; fa = 'درخواست‌های پرداخت';
										|it = 'Richieste di pagamento';
										|pl = 'Wnioski o płatność';
										|tr = 'Ödeme talepleri'"));
	
	Item = Settings.Add();
	Item.Fields.Add("TheDecryptionPage");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentByPayrollCardProgram);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
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
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	Item.Properties.Insert("Visible");
	//-- WE
	
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferOfTaxesAndContributions);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashBetweenCompanyAndItsBranchOffices);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CurrencyConversion);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundAcquiringPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.UsePayrollTM", True);
	OrGroup2 = Finances.NewFilter(AndGroup,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.CashIssueAsLoanToEmployee);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.SalaryPaymentByPayrollCardProgram);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	//++ WE
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.PayrollAndHumanResourcesWE", True);
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	//-- WE
	
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	
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
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.SalaryPaymentByPayrollCardProgram);
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	//++ WE
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "More.PayrollAndHumanResourcesWE", True);
	OrGroup2 = Finances.NewFilter(AndGroup,,, Type("DataCompositionFilterItemGroup"));
	OrGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup2, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	//-- WE
	
	AndGroup2 = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup2, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(AndGroup2, "PersonsList", False);
	
	Finances.CopyFilter(FilterPaymentToSelfEmployed, OrGroup);
	
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.RefundToAnotherCompany);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferToDeposits);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentOnLoansAndBorrowingsReceived);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferOfTaxesAndContributions);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.OtherCashIssue);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.PaymentToLessor);
	AndGroup = Finances.NewFilter(OrGroup,,, Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.IssueCashToAdvanceHolder);
	Finances.NewFilter(AndGroup, "PersonsList", False);
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
	
	// Decorations of the currency of the course of payment, the course of the count of the loan settlements, the course of the sign of the loan settlements, the variant of the course of the contract
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
	NotGroup = Finances.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	NotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	Finances.CopyFilter(FilterPaymentToSelfEmployed, NotGroup);
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
	Finances.NewFilter(AndGroup, "More.AmountUnallocated", 0,, DataCompositionComparisonType.NotEqual);
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.RefundToAnotherCompany,, DataCompositionComparisonType.NotEqual);
	Finances.NewFilter(AndGroup, "BusinessOperation", Operations.RefundToCustomer,, DataCompositionComparisonType.NotEqual);
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
	
	AndGroup5 = Finances.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
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
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CustomsPayment);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashPaymentToAnotherCompany);
	
	Item.Properties.Insert("Visible");
	
	// Statement
	Item = Settings.Add();
	Item.Fields.Add("ARAPDetails.Statement");
	Item.Fields.Add("DecryptionWithoutSplittingTheStatement");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "More.UsePayroll", True);   
	//++ WE
	Finances.NewFilter(OrGroup, "More.PayrollAndHumanResourcesWE", True);
	//-- WE
	
	OrGroup1 = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	
	//++ WE
	AndGroup1 = Finances.NewFilter(OrGroup1,,, Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	Finances.NewFilter(AndGroup1, "More.PayrollAndHumanResourcesWE", True);
	Finances.NewFilter(AndGroup1, "BusinessOperation", Operations.SalaryPaymentToBankAccounts);
	//-- WE
	
	Item.Properties.Insert("Visible");
	
	// Course Accuracy
	CashServer.FillInConditionalAppearanceAccuracyOfCourse(Settings);
	
	#EndRegion
	
	#Region Commands
	Item = Settings.Add();
	Item.Fields.Add("FillInTheRemainingAmountsOfNonIssuedAmountsToTheCounterparty");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Operations.CashIssueAsLoanToCounterparty);
	Item.Properties.Insert("Visible");
	
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
	Item.Fields.Add("ARAPDetailsSelectFromRequests");
	Finances.NewFilter(Item.Condition, "PersonsList", False);
	Item.Properties.Insert("Visible");
	#EndRegion

EndProcedure

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	AdditionalAvailability - Boolean - Additional indication that the selection of articles and Analytics is available.
// 
// Returns:
// 	Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation, AdditionalAvailability = False) Export
	
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
	
	AvailabilityOfOperationReturnOfPaymentToPaymentCard =
		(BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment) And AdditionalAvailability;
	AvailabilityOfOperationDoesNotReturnPaymentToPaymentCard =
		(BusinessOperation <> Enums.BusinessTransactions.RefundAcquiringPayment) And AdditionalAvailability;
	
	ChoiceParameters.AvailabilityByOperation = AvailabilityOfOperationReturnOfPaymentToPaymentCard
		Or AvailabilityOfOperationDoesNotReturnPaymentToPaymentCard;
	
	ChoiceParametersArray.Add(ChoiceParameters);
	
	Return ChoiceParametersArray;
	
EndFunction

// Returns a flag indicating whether the specified document number is busy for the period - year.
//
// Parameters:
//   Date - Date - the date on which the number uniqueness check is performed
//   VerifiedNumber - String - document number to be checked for uniqueness
//
// Returns:
//   Boolean - True if the number is unique, False if the number already exists
//
Function ThisIsUniqueDocumentNumber(Date, VerifiedNumber) Export

	Query = New Query;
	Query.Text = 
		"SELECT
		|	BankAccountIssue.Ref AS Ref
		|FROM
		|	Document.BankAccountIssue AS BankAccountIssue
		|WHERE
		|	BankAccountIssue.Number = &Number
		|	AND BankAccountIssue.Date BETWEEN BEGINOFPERIOD(&Date, YEAR) AND ENDOFPERIOD(&Date, YEAR)";
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("Number", VerifiedNumber);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	Return Result;

EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return BankAccountIssueLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return BankAccountIssueLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	TaxType - CatalogRef.TaxContributionKinds - Type of tax.
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
	
	SetupParameters.AssetAndLiabilityItem = "";
	SetupParameters.AssetsLiabilitiesDimension = "";
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	
	SetupParameters.Organization = "Object.Organization";
	
	SetupParameters.FormItems.Add("PresentationOfRecordingInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

#EndRegion
#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
// 
// Parameters:
//  Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	( ValueAllowed(Organization)
	|	OR ValueAllowed(BankAccountBeneficiary.Owner)
	|		AND BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
	|	OR ValueAllowed(ARAPDetails.Organization, Null AS TRUE) AND BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.CustomsPayment)
	|		)
	|	)AND ValueAllowed(BusinessOperation)
	|	AND CASE WHEN BusinessOperation IN (VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer))
	|	THEN ValueAllowed(ARAPDetails.Partner, Null AS TRUE)
	|	WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|	THEN ValueAllowed(AdvanceHolder)
	|	ELSE TRUE END 
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	( ValueAllowed(Organization)
	|	OR ( ValueAllowed(BankAccountBeneficiary.Owner)
	|	AND BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany))
	|	))AND ValueAllowed(BusinessOperation)
	|	AND CASE WHEN BusinessOperation IN (VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer))
	|	THEN ValueAllowed(ARAPDetails.Partner, Null AS TRUE)
	|	WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|	THEN ValueAllowed(AdvanceHolder)
	|	ELSE TRUE END ";

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

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If Parameters.Property("Basis") And ValueIsFilled(Parameters.Basis) Then
		
		If TypeOf(Parameters.Basis) = Type("DocumentRef.PaymentRequest")
			And GeneralPurposeTMServerCall.ObjectAttributeValue(Parameters.Basis, "PayrollTransaction") =
				Enums.BusinessTransactions.SalaryPaymentToBankAccounts
			And (GetFunctionalOption("UsePayrollTM")
			//++ WE
			Or GetFunctionalOption("PayrollAndHumanResourcesWE")
			//-- WE
			Or False) Then
				
			StandardProcessing = False;
			SelectedForm = "FormOfReconciliationWizard";
			
		ElsIf TypeOf(Parameters.Basis) = Type("Structure")
			And Parameters.Basis.Property("MultipleSpendingRequests") And Not Parameters.Basis.MultipleSpendingRequests
			And Parameters.Basis.Property("DocumentBasis") And Parameters.Basis.DocumentBasis.Count()
			And TypeOf(Parameters.Basis.DocumentBasis[0]) = Type("DocumentRef.PaymentRequest") Then
			
			AttributesOfApplication = GeneralPurposeTMServerCall.ObjectAttributesValues(
				Parameters.Basis.DocumentBasis[0], "BusinessOperation, PayrollTransaction, PersonsList, BankAccount, TransferToEmployeeViaABank");
				
			If AttributesOfApplication.PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentToBankAccounts
				Or AttributesOfApplication.PersonsList Then
				
				BankAccount = Undefined;
				If Parameters.Basis.Property("BankAccountCashAccount") And ValueIsFilled(Parameters.Basis.BankAccountCashAccount) Then
					BankAccount = Parameters.Basis.BankAccountCashAccount;
				Else
					BankAccount = AttributesOfApplication.BankAccount;
				EndIf;
				
				Parameters.Basis = Parameters.Basis.DocumentBasis[0];
				Parameters.Insert("BankAccount", BankAccount);
				If AttributesOfApplication.BusinessOperation = Enums.BusinessTransactions.SalaryPayment Then
					Parameters.Insert("BusinessOperation", AttributesOfApplication.PayrollTransaction);
				Else
					Parameters.Insert("BusinessOperation", AttributesOfApplication.BusinessOperation);
				EndIf;
				
				StandardProcessing = False;
				SelectedForm = "FormOfReconciliationWizard";
				
				If Parameters.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
					And AttributesOfApplication.PersonsList
					And GetFunctionalOption("UseCashDepositToListEmployees") Then
					
					If Not AttributesOfApplication.TransferToEmployeeViaABank Then
						SelectedForm = "WizardFormForWriteOffToPersonalAccounts";
					Else
						SelectedForm = Metadata.Documents.BankAccountIssue.Forms.DocumentForm;
					EndIf;
					
				EndIf;
				
			EndIf;
		EndIf;
	EndIf;
	//++ WE
	If GetFunctionalOption("PayrollAndHumanResourcesWE") Then
		If Parameters.Property("Basis") And ValueIsFilled(Parameters.Basis) Then
			If TypeOf(Parameters.Basis) = Type("Structure") And Parameters.Basis.Property("ArrayOfStatements") Then
				StandardProcessing = False;
				SelectedForm = "FormOfReconciliationWizard";
			EndIf;
		EndIf;
		Return;
	EndIf;
	//-- WE
	
	BankAccountIssueLocalization.FormGetProcessing(
		FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing);
	
EndProcedure

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	If RegisterName <> "CashFlowLimits" Then
		DataSources.Insert("ARAPDetails.ARAPObject");
	EndIf;
	
	BankAccountIssueLocalization.AdditionalDataSourcesForRegisteredRecords(RegisterName ,DataSources);
	
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	TemporaryTableQueryTexts = New Map;
	RedefiningParameterCalculation = New Structure;
	SynonymForDocumentTable = "";
	
	FullDocumentName = "Document.BankAccountIssue";
	
	If RegisterName = "CashToBePaid" Then
		
		RedefiningParameterCalculation.Insert("Period", "
			|CASE WHEN NOT DocumentData.ProcessedByBank
			|	OR BEGINOFPERIOD(DocumentData.Date) = DocumentData.BankPostingDate
			|	OR DocumentData.Patch THEN
			|		DocumentData.Date
			|	ELSE
			|		ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
			|END");
			
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
			|			DocumentData.BankAccountBeneficiary.Owner
			|	ELSE
			|		DocumentData.Counterparty
			|END");
			
		QueryText = QueryTextTableCashToBePaid(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		RedefiningParameterCalculation.Insert("Period", "
			|CASE WHEN NOT DocumentData.ProcessedByBank
			|	OR BEGINOFPERIOD(DocumentData.Date) = DocumentData.BankPostingDate
			|	OR DocumentData.Patch THEN
			|		DocumentData.Date
			|	ELSE
			|		ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
			|END");
		RedefiningParameterCalculation.Insert("PartnerFromDocument", "
			|	CASE
			|		WHEN DocumentData.BusinessOperation IN (
			|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
			|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
			|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
			|		THEN
			|			VALUE(Catalog.Partners.OurEnterprise)
			|		ELSE
			|			DocumentData.Partner
			|	END");
		RedefiningParameterCalculation.Insert("CounterpartyFromDocument", "
			|	CASE
			|		WHEN DocumentData.BusinessOperation IN (
			|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
			|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
			|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
			|		THEN
			|			DocumentData.BankAccountBeneficiary.Owner
			|		ELSE
			|			DocumentData.Counterparty
			|	END");
		RedefiningParameterCalculation.Insert("CashCurrency", "
			|CASE WHEN DocumentData.PaymentWithConversion
			|	THEN
			|		DocumentData.BankAccount.CashCurrency
			|	ELSE
			|		DocumentData.Currency
			|END");
		
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
	
	Query.SetParameter("UsePaymentRequests",
		GetFunctionalOption("UsePaymentRequests"));
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("StartDateOfTransferViaIntermediateAccount", Date('00010101'));
	If GetFunctionalOption("UsePayroll") Then
		Query.SetParameter("StartDateOfTransferViaIntermediateAccount",
			Constants.StartDateOfSalaryTransferViaTransfersOnWay.Get());
	EndIf;
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
	|	CASE WHEN NOT DocumentData.ProcessedByBank
	|		OR BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentData.BankPostingDate
	|		OR DocumentData.Patch THEN
	|		DocumentData.Date
	|	ELSE
	|		ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
	|	END AS Period,
	|	CASE WHEN NOT DocumentData.ProcessedByBank
	|		OR BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentData.BankPostingDate THEN
	|		DocumentData.Date
	|	ELSE
	|		ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
	|	END AS RatesPeriod,
	|	DocumentData.ProcessedByBank                               AS ProcessedByBank,
	|	
	|	DocumentData.IncomingDocumentNumber                       AS IncomingDocumentNumber,
	|	DocumentData.Number                                         AS Number,
	|	DocumentData.IncomingDocumentDate                        AS IncomingDocumentDate,
	|	DocumentData.Date                                          AS Date,
	|	DocumentData.PaymentPurposes                             AS PaymentPurposes,
	|	DocumentData.Currency                                        AS Currency,
	|	DocumentData.CurrencyOfConversion                             AS CurrencyOfConversion,
	|	DocumentData.PaymentRequest           AS PaymentRequest,
	|	DocumentData.CashTransferReferenceOrder      AS CashTransferReferenceOrder,
	|	DocumentData.PaymentRequestCurrency     AS RequestCurrency,
	|	DocumentData.Organization                                   AS Organization,
	|	DocumentData.CompanyParentCompany                AS ParentCompany,
	|	DocumentData.BankAccountRecipientOwner              AS CompanyRecipient,
	|	DocumentData.BankAccount                                AS BankAccount,
	|	DocumentData.BankAccountCashCurrency           AS CashCurrency,
	|	DocumentData.BusinessOperation                         AS BusinessOperation,
	|	DocumentData.CashFlowItem                 AS CashFlowItem,
	|	DocumentData.TargetFundItem                          AS TargetFundItem,
	|	DocumentData.Department                                 AS Department,
	|	DocumentData.BankAccountLineOfBusiness         AS LineOfBusinessCash,
	|	DocumentData.PaymentByRequests                               AS PaymentByRequests,
	|	
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
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
	|	END                                                         AS Partner,
	|	
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			DocumentData.BankAccountRecipientOwner
	|	
	|		WHEN
	|			ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE)
	|		THEN
	|			VALUE(Catalog.Counterparties.RetailCustomer)
	|	
	|	ELSE
	|		DocumentData.Counterparty
	|	END                                                         AS Counterparty,
	|	DocumentData.ListOfCounterparties_                            AS ListOfCounterparties_,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE
	|			DocumentData.Partner
	|	END                                                         AS PartnerFromDocument,
	|	
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|			VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
	|		THEN
	|			DocumentData.BankAccountRecipientOwner
	|		ELSE
	|			DocumentData.Counterparty
	|	END                                                         AS CounterpartyFromDocument,
	|	DocumentData.AdvanceHolder                               AS AdvanceHolder,
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
	|			DocumentData.BankAccountRecipientOwner
	|	ELSE
	|		DocumentData.Counterparty
	|	END AS Recipient,
	|	
	|	CAST(DocumentData.Ref AS Document.BankAccountIssue).ARAPDetails.(PaymentRequest) AS ARAPDetails,
	|	
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.EmployeeResponsible           AS EmployeeResponsible,
	|	DocumentData.Author                   AS Author,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Patch             AS Patch,
	|	DocumentData.ReversedDocument    AS ReversedDocument,
	|	DocumentData.CorrectedDocument    AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.Posted                AS Posted,
	|	ISNULL(AvailabilityOfGiftCertificateType.ThereIsGiftCertificate, FALSE) AS ThereIsGiftCertificate,
	|	BusinessTransactionsSettings.Ref   AS BusinessTransactionSetting,
	|	DocumentData.PersonsList            AS PersonsList,
	|	CASE
	|		WHEN NOT DocumentData.ProcessedByBank
	|				OR BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentData.BankPostingDate
	|				OR DocumentData.Patch
	|			THEN DocumentData.Date
	|		ELSE ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
	|	END >= &StartDateOfTransferViaIntermediateAccount
	|	AND &StartDateOfTransferViaIntermediateAccount <> DATETIME(1, 1, 1) AS TransferViaTransfersOnWay,
	|	DocumentData.TransferToEmployeeViaABank AS TransferToEmployeeViaABank,
	|	DocumentData.PaymentWithConversion AS PaymentWithConversion,
	|	DocumentData.AmountInPayerSCurrency AS AmountInPayerSCurrency,
	|	DocumentData.CashFlowItemConversion AS CashFlowItemConversion
	|FROM
	|	DocumentDataHeader AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|		
	|		LEFT JOIN AvailabilityOfTypeOfSettlementObjectGiftCertificate AS AvailabilityOfGiftCertificateType
	|		ON TRUE
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	//++ WE
	PayrollAndHumanResourcesWE = GetFunctionalOption("PayrollAndHumanResourcesWE");
	StartDatePayrollAndHumanResources = BegOfDay(Constants.StartDatePayrollAndHumanResources.Get());
	PayrollAndHumanResourcesWE = PayrollAndHumanResourcesWE And StartDatePayrollAndHumanResources <= Attributes.Period;
	Query.SetParameter("PayrollAndHumanResourcesWE", PayrollAndHumanResourcesWE);
	
	If GetFunctionalOption("PayrollAndHumanResourcesWE") Then
		Query.SetParameter("EndOfDayPeriod", EndOfDay(Attributes.Period));
	EndIf;
	//-- WE
	
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
	QueryTextDocumentDataTablePersonalAccountsOfEmployees(ListOfRequests);
	
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
	|	DocumentData.IncomingDocumentDate AS IncomingDocumentDate,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.PaymentPurposes AS PaymentPurposes,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.RankingInPriorityOfPayment AS RankingInPriorityOfPayment,
	|	DocumentData.BankAccountBeneficiary AS BankAccountBeneficiary,
	|	DocumentData.CashAccountRecipient AS CashAccountRecipient,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.PaymentRequest AS PaymentRequest,
	|	DocumentData.CashTransferReferenceOrder AS CashTransferReferenceOrder,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.TransferOfTaxesAndContributions AS TransferOfTaxesAndContributions,
	|	DocumentData.KindOfFundsTransferToBudget AS KindOfFundsTransferToBudget,
	|	DocumentData.AuthorStatus AS AuthorStatus,
	|	DocumentData.TypeIndicator AS TypeIndicator,
	|	DocumentData.BCCode AS BCCode,
	|	DocumentData.RNCPSRNCMTCode AS RNCPSRNCMTCode,
	|	DocumentData.BasisIndicator AS BasisIndicator,
	|	DocumentData.PeriodIndicator AS PeriodIndicator,
	|	DocumentData.NumberIndicator AS NumberIndicator,
	|	DocumentData.DateIndicator AS DateIndicator,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.DoNotControlRequestFilling AS DoNotControlRequestFilling,
	|	DocumentData.PaymentKind AS PaymentKind,
	|	DocumentData.PaymentDocumentType AS PaymentDocumentType,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.CurrencyOfConversion AS CurrencyOfConversion,
	|	DocumentData.ConversionRate AS ConversionRate,
	|	DocumentData.ConversionAmount AS ConversionAmount,
	|	DocumentData.Department AS Department,
	|	DocumentData.PaysheetNumber AS PaysheetNumber,
	|	DocumentData.PaysheetDate AS PaysheetDate,
	|	DocumentData.PaymentByRequests AS PaymentByRequests,
	|	DocumentData.PaymentID AS PaymentID,
	|	DocumentData.EntriesByEmployees AS EntriesByEmployees,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	DocumentData.ProcessedByBank AS ProcessedByBank,
	|	DocumentData.BankPostingDate AS BankPostingDate,
	|	DocumentData.RegistrationWithTaxAuthority AS RegistrationWithTaxAuthority,
	|	DocumentData.ExportDate AS ExportDate,
	|	DocumentData.ImportDate AS ImportDate,
	|	DocumentData.ImportErrors AS ImportErrors,
	|	DocumentData.FormattedPurposeOfPayment AS FormattedPurposeOfPayment,
	|	DocumentData.StatementData AS StatementData,
	|	DocumentData.NameOfCounterparty AS NameOfCounterparty,
	|	DocumentData.ExpenseReportDate AS ExpenseReportDate,
	|	DocumentData.PaymentsAsPer275FZ AS PaymentsAsPer275FZ,
	|	DocumentData.PaymentType275FZ AS PaymentType275FZ,
	|	DocumentData.ContractWithSDOParticipant AS ContractWithSDOParticipant,
	|	DocumentData.ContractWithCustomer AS ContractWithCustomer,
	|	DocumentData.TaxType AS TaxType,
	|	DocumentData.PaysheetPersonalIncomeTax AS PaysheetPersonalIncomeTax,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.TINOfPayer AS TINOfPayer,
	|	DocumentData.PayerCRTR AS PayerCRTR,
	|	DocumentData.PayerSName AS PayerSName,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.TransferFeeType AS TransferFeeType,
	|	DocumentData.KeyOfTransactionWithForeignCurrency AS KeyOfTransactionWithForeignCurrency,
	|	DocumentData.InformationForForeignExchangeControl AS InformationForForeignExchangeControl,
	|	DocumentData.InformationToPaymentRecipient AS InformationToPaymentRecipient,
	|	DocumentData.InformationForRegulatoryBodies AS InformationForRegulatoryBodies,
	|	DocumentData.ConditionOfConversionTransaction AS ConditionOfConversionTransaction,
	|	DocumentData.BankAccountForFeeWriteOff AS BankAccountForFeeWriteOff,
	|	DocumentData.NotificationOfReceivingCashInForeignCurrency AS NotificationOfReceivingCashInForeignCurrency,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.ConversionRateMultiplier AS ConversionRateMultiplier,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.DocumentID AS DocumentID,
	|	DocumentData.IncomeKindCode AS IncomeKindCode,
	|	DocumentData.Author AS Author,
	|	DocumentData.AcquiringContract AS AcquiringContract,
	|	DocumentData.RecordCommission AS RecordCommission,
	|	DocumentData.FeeAmount AS FeeAmount,
	|	DocumentData.CommissionARAPObject AS CommissionARAPObject,
	|	DocumentData.KeepRecordsOfCommissionInARAPAccounting AS KeepRecordsOfCommissionInARAPAccounting,
	|	DocumentData.ExpenseItem AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.GLAccountSettings AS GLAccountSettings,
	|	DocumentData.PaymentCode AS PaymentCode,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.TransferToEmployeeViaABank AS TransferToEmployeeViaABank,
	|	DocumentData.RegistrationPeriod AS RegistrationPeriod,
	|	DocumentData.PersonsList AS PersonsList,
	|	DocumentData.RegistryExportDate AS RegistryExportDate,
	|	DocumentData.BankContractNumber AS BankContractNumber,
	|	DocumentData.BankContractDate AS BankContractDate,
	|	DocumentData.BankBranch AS BankBranch,
	|	DocumentData.BranchOfBankBranch AS BranchOfBankBranch,
	|	DocumentData.TargetFundItem AS TargetFundItem,
	|	DocumentData.ListOfCounterparties_ AS ListOfCounterparties_,
	|	DocumentData.PaymentRequest.Currency AS PaymentRequestCurrency,
	|	DocumentData.Organization.ParentCompany AS CompanyParentCompany,
	|	DocumentData.BankAccountBeneficiary.Owner AS BankAccountRecipientOwner,
	|	DocumentData.BankAccount.LineOfBusiness AS BankAccountLineOfBusiness,
	|	DocumentData.BankAccount.EnableCreatingCashIssueWithoutPaymentRequest AS BankAccountAllowPaymentsWithoutSpecifyingRequests,
	|	DocumentData.BankAccount.Department AS BankAccountDivision,
	|	DocumentData.BankAccount.CashCurrency AS BankAccountCashCurrency,
	|	DocumentData.Counterparty.Partner AS CounterpartyPartner,
	|	DocumentData.AcquiringContract.LineOfBusiness AS AcquiringContractLineOfBusiness,
	|	DocumentData.AcquiringContract.Partner AS AcquiringContractPartner,
	|	DocumentData.AcquiringContract.CashFlowItemCommission AS
	|		AcquiringContractCashFlowItemFee,
	|	DocumentData.BankAccountBeneficiary.LineOfBusiness AS BankAccountRecipientLineOfBusiness,
	|	DocumentData.PaymentWithConversion AS PaymentWithConversion,
	|	DocumentData.AmountInPayerSCurrency AS AmountInPayerSCurrency,
	|	DocumentData.CashFlowItemConversion AS CashFlowItemConversion
	|INTO DocumentDataHeader
	|FROM
	|	Document.BankAccountIssue AS DocumentData
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
	|	PaymentDecryptionTable.Counterparty AS Counterparty,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
	|	PaymentDecryptionTable.AmountARAP AS AmountARAP,
	|	PaymentDecryptionTable.ExpenseItem AS ExpenseItem,
	|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	PaymentDecryptionTable.Department AS Department,
	|	PaymentDecryptionTable.LoanDepositContract AS LoanDepositContract,
	|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest,
	|	PaymentDecryptionTable.Comment AS Comment,
	|	PaymentDecryptionTable.LeaseContracts AS LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	PaymentDecryptionTable.RowID AS RowID,
	|	PaymentDecryptionTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.EmployeeLoanAgreement AS EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LoanAndDepositAmountType AS LoanAndDepositAmountType,
	|	PaymentDecryptionTable.Organization AS Organization,
	|	PaymentDecryptionTable.ContractWithCustomer AS ContractWithCustomer,
	|	PaymentDecryptionTable.ProductCostElement AS ProductCostElement,
	|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	PaymentDecryptionTable.VATAmount AS VATAmount,
	|	PaymentDecryptionTable.Statement AS Statement,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
	|	PaymentDecryptionTable.ExchangeRateNumeratorOfMutualSettlements AS ExchangeRateNumeratorOfMutualSettlements,
	|	PaymentDecryptionTable.TheExchangeRateIsTheDenominatorOfMutualSettlements AS TheExchangeRateIsTheDenominatorOfMutualSettlements,
	|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
	|	PaymentDecryptionTable.MaturityDate AS MaturityDate,
	|	PaymentDecryptionTable.ARAPObject.Organization AS ARAPObjectOfCompany,
	|	PaymentDecryptionTable.ARAPObject.Partner AS ARAPObjectIsPartner,
	|	PaymentDecryptionTable.ARAPObject.Contract AS ARAPObjectContract,
	|	PaymentDecryptionTable.ARAPObject.Counterparty AS ARAPObjectCounterparty, 
	|	PaymentDecryptionTable.ARAPObject.VATTaxation AS ARAPObjectTaxationOfVAT,
	|	PaymentDecryptionTable.ARAPObject.Department AS ObjectOfCalculationsDivision,
	|	PaymentDecryptionTable.ARAPObject.LineOfBusiness AS ARAPObjectLineOfBusiness,
	|	PaymentDecryptionTable.ARAPObject.Object AS CalculationObjectObject,
	|	CASE WHEN PaymentDecryptionTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|			THEN
	|				VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE
	|			PaymentDecryptionTable.Partner
	|	END AS ARAPObjectOfPaymentPartner,
	|	PaymentDecryptionTable.LeaseContracts.LineOfBusiness AS LeaseContractLineOfBusiness,
	|	PaymentDecryptionTable.LeaseContracts.Department AS LeaseContractDivision,
	|	PaymentDecryptionTable.PaymentRequest.ControlPaymentByARAPObjects AS
	|		PaymentRequestToControlPaymentOfPaymentOfARAPObject,
	|	PaymentDecryptionTable.PaymentRequest.Currency AS PaymentRequestCurrency,
	|	PaymentDecryptionTable.AmountInPayerSCurrency AS AmountInPayerSCurrency,
	|	PaymentDecryptionTable.VATAmountInPayerSCurrency AS VATAmountInPayerSCurrency
	|INTO DocumentDataTableDecryptionOfPayment
	|FROM
	|	Document.BankAccountIssue.ARAPDetails AS PaymentDecryptionTable
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
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
	|	TablePersonalAccountsOfEmployees.CashFlowItem AS CashFlowItem,
	|	TablePersonalAccountsOfEmployees.RowID AS RowID
	|INTO DocumentDataTablePersonalAccountsOfEmployees
	|FROM
	|	Document.BankAccountIssue.PersonalAccountsOfStaff AS TablePersonalAccountsOfEmployees
	|WHERE
	|	TablePersonalAccountsOfEmployees.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                         Common.MetadataObjectID("Document.BankAccountIssue"));
	Values.Insert("UsePaymentRequests", GetFunctionalOption("UsePaymentRequests"));
	Values.Insert("UseAccountingOfOtherIncomeExpenses",           GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Values.Insert("ControlIssueOfCashByPurposes",       GetFunctionalOption("ControlIssueOfCashByPurposes"));
	Values.Insert("UsePayroll",                  Constants.UsePayroll.Get());
	Values.Insert("UseCashFlowLimits",        GetFunctionalOption("UseCashFlowLimits"));
	Values.Insert("UseExpenseLimitsForOrganizations",         GetFunctionalOption("UseCashFlowLimitsByCompanies"));
	Values.Insert("UseExpenseLimitsByDivision",       GetFunctionalOption("UseCashFlowLimitsByBusinessUnit"));
	Values.Insert("UseAccountingOfOtherAssetsAndLiabilities",           GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	Values.Insert("IDOfUnusedFinRecord",            DocumentsPosting.IDOfUnusedFinRecord());
	Values.Insert("ManagementAccountingCurrency",                      Constants.ManagementAccountingCurrency.Get());
	
	If Attributes <> Undefined Then
		
		Values.Insert("CashFlowItem",                         CashFlowArticleOfDocument(Attributes));
		
		ArrayOfRequests = Attributes.ARAPDetails.Unload().UnloadColumn("PaymentRequest"); // Array
		ArrayOfRequests.Add(Attributes.PaymentRequest);
		ArrayOfRequests.Add(Attributes.CashTransferReferenceOrder);
		Values.Insert("ArrayOfRequests",                                ArrayOfRequests);
		
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency,
			Attributes.CashCurrency,
			Attributes.RatesPeriod,
			Attributes.Organization);
			
		ConversionFactors = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.CurrencyOfConversion,
			Attributes.Currency,
			Attributes.RatesPeriod,
			Attributes.Organization);
			
		CashRatios = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.CashCurrency,
			Undefined,
			Attributes.RatesPeriod,
			Attributes.Organization);
			
		Values.Insert("ConversionRateToManCurrency",              Coefficients.ConversionRateToManCurrency);
		Values.Insert("FactorOfConversionToCurrencyOfRegul",             Coefficients.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("ConversionRatioToCurrencyOfFunds",  Coefficients.ConversionRateToSettlementCurrency);
		
		Values.Insert("ConversionFactorOfConversionToCurrencyMan",   ConversionFactors.ConversionRateToManCurrency);
		Values.Insert("ConversionRateOfConversionToLocalCurrency",  ConversionFactors.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("ConversionRateToConversionCurrency",      ConversionFactors.ConversionRateToSettlementCurrency);
		
		Values.Insert("ConversionRatioOfFundsIntoManSCurrency", CashRatios.ConversionRateToManCurrency);
		Values.Insert("ConversionRatioOfFundsToLocalCurrency", CashRatios.FactorOfConversionToCurrencyOfRegul);
		
		Values.Insert("NumberForPrinting",                               ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		Values.Insert("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
		
	EndIf;
	
	Return Values;
	
EndFunction

Procedure InitializeTrackingAnalyticsKeysForPartners(Query, QueryTexts = Undefined, DocumentObject = Undefined)

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
	|	CASE WHEN &ListOfCounterparties_
	|			THEN PaymentDecryptionTable.Counterparty
	|		ELSE &Counterparty
	|	END AS Counterparty,
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
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|		VALUE(Enum.BusinessTransactions.CustomsPayment)
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	CASE WHEN &ListOfCounterparties_
	|			THEN PaymentDecryptionTable.Counterparty
	|		ELSE &Counterparty
	|	END AS Counterparty,
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
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|		VALUE(Enum.BusinessTransactions.CustomsPayment)
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
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived), 
	|		VALUE(Enum.BusinessTransactions.TransferToDeposits), 
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty)
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
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ARAPObjects.Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	ARAPObjects.Partner AS Partner,
	|	ARAPObjects.Contract AS Contract,
	|	ARAPObjects.LineOfBusiness AS LineOfBusiness
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
	|
	|	INNER JOIN TTTableOfCalculationObjects AS ARAPObjects
	|	ON PaymentDecryptionTable.ARAPObject = ARAPObjects.ARAPObject
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		ARAPObjects.Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND ARAPObjects.Partner = Dimension.Partner
	|		AND ARAPObjects.Contract = Dimension.Contract
	|		AND ARAPObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Organization AS Organization,
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
	|		&Organization= Dimension.Organization
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
	|		)";
	
	If DocumentObject = Undefined Then
		QueryTextForAnalytics = StrReplace(QueryTextForAnalytics, "DocumentDataTableDecryptionOfPayment", "Document.BankAccountIssue.ARAPDetails");
		QueryTextForAnalytics = StrReplace(QueryTextForAnalytics, "DocumentDataHeader", "Document.BankAccountIssue");
	EndIf;
	
	RequestForAnalytics.Text = RequestForAnalytics.Text + QueryTextForAnalytics;

	RequestForAnalytics.SetParameter("Ref",                              Query.Parameters.Ref);
	RequestForAnalytics.SetParameter("Organization",                         Query.Parameters.Organization);
	RequestForAnalytics.SetParameter("Counterparty",                          Query.Parameters.Counterparty);
	RequestForAnalytics.SetParameter("Partner",                             Query.Parameters.Partner);
	RequestForAnalytics.SetParameter("LineOfBusiness",             Query.Parameters.LineOfBusiness);
	RequestForAnalytics.SetParameter("ProcessedByBank",                     Query.Parameters.ProcessedByBank);
	RequestForAnalytics.SetParameter("BusinessOperation",               Query.Parameters.BusinessOperation);
	RequestForAnalytics.SetParameter("PaymentRequest", Query.Parameters.PaymentRequest);
	RequestForAnalytics.SetParameter("ListOfCounterparties_",                  Query.Parameters.ListOfCounterparties_);
	
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
	
	If Query.Parameters.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram
		Or Query.Parameters.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts
		Or Query.Parameters.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee Then
		
		StructureOfAnalytics = New Structure;
		StructureOfAnalytics.Insert("Organization", Query.Parameters.Organization);
		StructureOfAnalytics.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
		StructureOfAnalytics.Insert("Partner", Catalogs.Partners.EmptyRef());
		StructureOfAnalytics.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
		StructureOfAnalytics.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
		
		AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureOfAnalytics);
		AnalyticsOfAccountingByPartnersRecipient = Undefined;
	Else
		
		AccountingDimensionByPartners = Undefined;
		AnalyticsOfAccountingByPartnersRecipient = Undefined;
	EndIf;
	
	If ARAPAccountingServer.BusinessOperationRefundOfFunds(Query.Parameters.BusinessOperation) Then
		AnalysisOfAccountingByPartnersObjectOfSettlement = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(RequestForAnalytics.Parameters);
	Else
		AnalysisOfAccountingByPartnersObjectOfSettlement = Undefined;
	EndIf;
	
	Query.SetParameter("AccountingDimensionByPartners",                    AccountingDimensionByPartners);
	Query.SetParameter("AnalyticsOfAccountingByPartnersRecipient",          AnalyticsOfAccountingByPartnersRecipient);
	Query.SetParameter("AnalysisOfAccountingByPartnersObjectOfSettlement",      AnalysisOfAccountingByPartnersObjectOfSettlement);
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized", True);
	
EndProcedure

Function RequestTextTemporaryTableOfCalculationObjects(Query, QueryTexts, DocumentObject = Undefined) Export
	
	TempTableName = "TableOfCalculationObjects";
	
	QueryText = "
	|SELECT DISTINCT
	|	PaymentDecryptionTable.ARAPObject   AS ARAPObject,
	|
	|	PaymentDecryptionTable.ARAPObjectOfCompany AS Organization,
	|	PaymentDecryptionTable.ARAPObjectIsPartner AS Partner,
	|	PaymentDecryptionTable.ARAPObjectCounterparty AS Counterparty,
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
	|	AND PaymentDecryptionTable.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|	AND NOT &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentToLessor),
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|		VALUE(Enum.BusinessTransactions.TransferToDeposits),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty)
	|		)
	|
	|INDEX BY
	|	ARAPObject
	|";
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataTableDecryptionOfPayment", "Document.BankAccountIssue.ARAPDetails");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectOfCompany", "PaymentDecryptionTable.ARAPObject.Organization");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectIsPartner", "PaymentDecryptionTable.ARAPObject.Partner");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectContract", "PaymentDecryptionTable.ARAPObject.Contract");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectCounterparty", "PaymentDecryptionTable.ARAPObject.Counterparty");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectTaxationOfVAT", "PaymentDecryptionTable.ARAPObject.VATTaxation");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ObjectOfCalculationsDivision", "PaymentDecryptionTable.ARAPObject.Department");
		QueryText = StrReplace(QueryText, "PaymentDecryptionTable.ARAPObjectLineOfBusiness", "PaymentDecryptionTable.ARAPObject.LineOfBusiness");
		
	EndIf;
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject = Undefined) Export
	
	TempTableName = "PaymentDecryptionTable";
	
	InitializeTrackingAnalyticsKeysForPartners(Query, QueryTexts, DocumentObject);
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfCalculationObjects", QueryTexts) Then
		RequestTextTemporaryTableOfCalculationObjects(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	TableOfCalculationObjects.Organization AS Organization,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	CASE
	|		WHEN &ThereIsGiftCertificate = TRUE
	|			THEN &Partner
	|		ELSE PaymentDecryptionTable.Partner
	|	END AS Partner,
	|	CASE
	|		WHEN &ListOfCounterparties_
	|			THEN PaymentDecryptionTable.Counterparty
	|		ELSE &Counterparty
	|	END AS Counterparty,
	|	ISNULL(TableOfCalculationObjects.Contract, UNDEFINED) AS Contract,
	|
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|			THEN PaymentDecryptionTable.LineOfBusiness
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|			THEN PaymentDecryptionTable.LeaseContractLineOfBusiness
	|		ELSE ISNULL(TableOfCalculationObjects.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	END AS LineOfBusiness,
	|	CASE WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.OtherCashIssue))
	|		THEN PaymentDecryptionTable.ExpenseItem
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions))
	|		THEN
	|			CASE WHEN &UseAccountingOfOtherAssetsAndLiabilities THEN
	|				VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes)
	|			ELSE
	|				UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END AS ExpenseItem,
	|	CASE WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.OtherCashIssue))
	|		THEN PaymentDecryptionTable.DimensionOfExpenses 
	|		ELSE UNDEFINED 
	|	END AS DimensionOfExpenses,
	|	CASE WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.OtherCashIssue))
	|		THEN PaymentDecryptionTable.AssetsLiabilitiesDimension 
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions))
	|		THEN
	|			DocumentData.TaxType
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee))
	|		THEN
	|			&AdvanceHolder
	|		ELSE UNDEFINED 
	|	END AS AssetsLiabilitiesDimension,
	|	PaymentDecryptionTable.GLAccountSettings AS GLAccountSettings,
	|	CASE 
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|			THEN PaymentDecryptionTable.Department 
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|			THEN PaymentDecryptionTable.LeaseContractDivision 
	|		ELSE UNDEFINED 
	|	END AS Department,
	|	ISNULL(TableOfCalculationObjects.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS OrderDivision_,
	|	
	|	CASE WHEN DocumentData.PaymentWithConversion THEN
	|		PaymentDecryptionTable.AmountInPayerSCurrency
	|	ELSE
	|		PaymentDecryptionTable.Sum
	|	END AS Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|
	|	PaymentDecryptionTable.LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType,
	|	PaymentDecryptionTable.EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	CASE 
	|		WHEN &PersonsList
	|				AND &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	|			THEN &CashFlowItem
	|		WHEN &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|		VALUE(Enum.BusinessTransactions.OtherCashIssue),
	|		VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions),
	|		VALUE(Enum.BusinessTransactions.CustomsPayment),
	|		VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts),
	|		VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee))
	|	THEN
	|		PaymentDecryptionTable.CashFlowItem
	|	ELSE
	|		&CashFlowItem
	|	END AS CashFlowItem,
	|	CASE WHEN &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|		VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
	|		VALUE(Enum.BusinessTransactions.OtherCashIssue),
	|		VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions),
	|		VALUE(Enum.BusinessTransactions.CustomsPayment),
	|		VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts),
	|		VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee))
	|	THEN
	|		PaymentDecryptionTable.TargetFundItem
	|	ELSE
	|		&TargetFundItem
	|	END AS TargetFundItem,
	|	PaymentDecryptionTable.Statement AS Statement,
	|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest,
	|
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		WHEN &Currency = &ManagementAccountingCurrency THEN
	|			PaymentDecryptionTable.Sum
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.AmountInPayerSCurrency * &ConversionRatioOfFundsIntoManSCurrency AS NUMBER(31,2))
	|		ELSE CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		WHEN &Currency = &LocalAccountingCurrency THEN
	|			PaymentDecryptionTable.Sum
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.AmountInPayerSCurrency * &ConversionRatioOfFundsToLocalCurrency AS NUMBER(31,2))
	|		ELSE CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|	
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	CASE WHEN DocumentData.PaymentWithConversion THEN
	|		PaymentDecryptionTable.VATAmountInPayerSCurrency
	|	ELSE PaymentDecryptionTable.VATAmount
	|	END AS VATAmount,
	|	CASE WHEN &Currency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.VATAmountInPayerSCurrency * &ConversionRatioOfFundsIntoManSCurrency AS NUMBER(31,2))
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS VATAmountMan,
	|	CASE WHEN &Currency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.VATAmountInPayerSCurrency * &ConversionRatioOfFundsToLocalCurrency AS NUMBER(31,2))
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
	|	LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON PaymentDecryptionTable.Ref = DocumentData.Ref
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
	|			ELSE PaymentDecryptionTable.Partner
	|		END = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND NOT &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany),
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|		VALUE(Enum.BusinessTransactions.TransferToDeposits),
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
	|	UNDEFINED AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|
	|	ContractData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS GLAccountSettings,
	|	UNDEFINED AS Department,
	|	ContractData.Department AS OrderDivision_,
	|
	|	CASE WHEN DocumentData.PaymentWithConversion THEN
	|		PaymentDecryptionTable.AmountInPayerSCurrency
	|	ELSE
	|		PaymentDecryptionTable.Sum
	|	END AS Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|
	|	PaymentDecryptionTable.LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED AS TypeOfLeasePayment,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
	|	UNDEFINED AS Statement,
	|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest,
	|
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		WHEN &Currency = &ManagementAccountingCurrency THEN
	|			PaymentDecryptionTable.Sum
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.AmountInPayerSCurrency * &ConversionRatioOfFundsIntoManSCurrency AS NUMBER(31,2))
	|		ELSE CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		WHEN &Currency = &LocalAccountingCurrency THEN
	|			PaymentDecryptionTable.Sum
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.AmountInPayerSCurrency * &ConversionRatioOfFundsToLocalCurrency AS NUMBER(31,2))
	|		ELSE CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|	
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	CASE WHEN DocumentData.PaymentWithConversion THEN
	|		PaymentDecryptionTable.VATAmountInPayerSCurrency
	|	ELSE PaymentDecryptionTable.VATAmount
	|	END AS VATAmount,
	|	CASE WHEN &Currency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.VATAmountInPayerSCurrency * &ConversionRatioOfFundsIntoManSCurrency AS NUMBER(31,2))
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS VATAmountMan,
	|	CASE WHEN &Currency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.VATAmountInPayerSCurrency * &ConversionRatioOfFundsToLocalCurrency AS NUMBER(31,2))
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
	|	
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
	|
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived),
	|		VALUE(Enum.BusinessTransactions.TransferToDeposits),
	|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty)
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
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|
	|	ContractData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS GLAccountSettings,
	|	UNDEFINED AS Department,
	|	ContractData.Department AS OrderDivision_,
	|
	|	CASE WHEN DocumentData.PaymentWithConversion THEN
	|		PaymentDecryptionTable.AmountInPayerSCurrency
	|	ELSE
	|		PaymentDecryptionTable.Sum
	|	END AS Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	PaymentDecryptionTable.LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
	|	UNDEFINED AS Statement,
	|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest,
	|
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		WHEN &Currency = &ManagementAccountingCurrency THEN
	|			PaymentDecryptionTable.Sum
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.AmountInPayerSCurrency * &ConversionRatioOfFundsIntoManSCurrency AS NUMBER(31,2))
	|		ELSE CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		WHEN &Currency = &LocalAccountingCurrency THEN
	|			PaymentDecryptionTable.Sum
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.AmountInPayerSCurrency * &ConversionRatioOfFundsToLocalCurrency AS NUMBER(31,2))
	|		ELSE CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|	
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	CASE WHEN DocumentData.PaymentWithConversion THEN
	|		PaymentDecryptionTable.VATAmountInPayerSCurrency
	|	ELSE PaymentDecryptionTable.VATAmount
	|	END AS VATAmount,
	|	CASE WHEN &Currency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.VATAmountInPayerSCurrency * &ConversionRatioOfFundsIntoManSCurrency AS NUMBER(31,2))
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS VATAmountMan,
	|	CASE WHEN &Currency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.VATAmountInPayerSCurrency * &ConversionRatioOfFundsToLocalCurrency AS NUMBER(31,2))
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
	|
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	TableOfCalculationObjects.Organization AS Organization,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	PaymentDecryptionTable.Partner AS Partner,
	|	UNDEFINED AS Counterparty,
	|	TableOfCalculationObjects.Contract AS Contract,
	|	ISNULL(TableOfCalculationObjects.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)),
	|
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS GLAccountSettings,
	|	UNDEFINED AS Department,
	|	TableOfCalculationObjects.Department AS OrderDivision_,
	|
	|	CASE WHEN DocumentData.PaymentWithConversion THEN
	|		PaymentDecryptionTable.AmountInPayerSCurrency
	|	ELSE
	|		PaymentDecryptionTable.Sum
	|	END AS Sum,
	|	PaymentDecryptionTable.AmountARAP,
	|	PaymentDecryptionTable.ARAPCurrency,
	|
	|	PaymentDecryptionTable.LoanDepositContract,
	|	PaymentDecryptionTable.LoanAndDepositAmountType,
	|	PaymentDecryptionTable.EmployeeLoanAgreement,
	|	PaymentDecryptionTable.LeaseContracts,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS TypeOfLeasePayment,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
	|	UNDEFINED AS Statement,
	|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest,
	|
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		WHEN &Currency = &ManagementAccountingCurrency THEN
	|			PaymentDecryptionTable.Sum
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.AmountInPayerSCurrency * &ConversionRatioOfFundsIntoManSCurrency AS NUMBER(31,2))
	|		ELSE CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|	CASE WHEN PaymentDecryptionTable.ARAPCurrency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.AmountARAP
	|		WHEN &Currency = &LocalAccountingCurrency THEN
	|			PaymentDecryptionTable.Sum
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.AmountInPayerSCurrency * &ConversionRatioOfFundsToLocalCurrency AS NUMBER(31,2))
	|		ELSE CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|	
	|	PaymentDecryptionTable.VATRate AS VATRate,
	|	CASE WHEN DocumentData.PaymentWithConversion THEN
	|		PaymentDecryptionTable.VATAmountInPayerSCurrency
	|	ELSE PaymentDecryptionTable.VATAmount
	|	END AS VATAmount,
	|	CASE WHEN &Currency = &ManagementAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.VATAmountInPayerSCurrency * &ConversionRatioOfFundsIntoManSCurrency AS NUMBER(31,2))
	|		ELSE CAST(PaymentDecryptionTable.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS VATAmountMan,
	|	CASE WHEN &Currency = &LocalAccountingCurrency
	|		THEN PaymentDecryptionTable.VATAmount
	|		WHEN DocumentData.PaymentWithConversion THEN
	|			CAST(PaymentDecryptionTable.VATAmountInPayerSCurrency * &ConversionRatioOfFundsToLocalCurrency AS NUMBER(31,2))
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
	|	LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON PaymentDecryptionTable.Ref = DocumentData.Ref
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
	|		AND &Counterparty = Dimension.Counterparty
	|		AND TableOfCalculationObjects.Partner = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|
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
	|	WriteOff.Organization,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	WriteOff.Department,
	|	WriteOff.Department,
	|	WriteOff.DocumentAmount,
	|	WriteOff.DocumentAmount,
	|	WriteOff.Currency,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	WriteOff.CashFlowItem,
	|	WriteOff.TargetFundItem,
	|	UNDEFINED,
	|	WriteOff.PaymentRequest,
	|	CAST(WriteOff.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)),
	|	CAST(WriteOff.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)),
	|	UNDEFINED,
	|	0,
	|	0,
	|	0,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	&AccountingDimensionByPartners,
	|
	|	WriteOff.DocumentID AS RowID
	|
	|FROM
	|	DocumentDataHeader AS WriteOff
	|WHERE
	|	WriteOff.Ref = &Ref
	|	AND WriteOff.BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashIssueAsLoanToEmployee),
	|	                                    VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram),
	|	                                    VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts))
	|	AND NOT &UsePayroll
	//++ WE
	|	AND NOT &PayrollAndHumanResourcesWE
	//-- WE
	|";
	
	If DocumentObject = Undefined Then
		
		If Query.TempTablesManager = Undefined Then
			Query.TempTablesManager = New TempTablesManager();
		EndIf;
		
		If Query.TempTablesManager.Tables.Find("DocumentDataTableDecryptionOfPayment") = Undefined 
			Or Query.TempTablesManager.Tables.Find("DocumentDataHeader") = Undefined Then
			GetDocumentData(Query, Query.Parameters.Ref);
		EndIf;
		
	EndIf;
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryTablePersonalAccountsOfEmployees(Query, QueryTexts, DocumentObject = Undefined) Export
	
	TempTableName = "TablePersonalAccountsOfEmployees";
	
	QueryText = "
	|SELECT
	|	DocumentData.LineNumber AS LineNumber,
	|	DocumentData.Individual AS Individual,
	|	DocumentData.PersonalAccount AS PersonalAccount,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.RowID AS RowID,
	|	DocumentData.Sum AS Sum,
	|	CAST(DocumentData.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	CAST(DocumentData.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl
	|INTO TablePersonalAccountsOfEmployees
	|FROM
	|	DocumentDataTablePersonalAccountsOfEmployees AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTablePersonalAccountsOfEmployees", "Document.BankAccountIssue.PersonalAccountsOfStaff");
	EndIf;
	
	QueryTexts.Add(QueryText, TempTableName);
	
EndFunction

Function QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject = Undefined) Export
	
	RegisterName = "TableOfExchangeDifferences";
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.BankAccount.Department AS Department,
	|	DocumentData.BankAccount.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.CashRevaluation) AS BusinessOperation,
	|
	|	SUM(PaymentDecryptionTable.Sum)
	|		- DocumentData.AmountInPayerSCurrency AS Sum,
	|
	|	SUM(PaymentDecryptionTable.SumMan)
	|		- DocumentData.AmountInPayerSCurrency * &ConversionRatioOfFundsIntoManSCurrency AS SumMan,
	|	
	|	SUM(PaymentDecryptionTable.SumCompl)
	|		- DocumentData.AmountInPayerSCurrency * &ConversionRatioOfFundsToLocalCurrency AS SumCompl,
	|	
	|	DocumentData.DocumentID AS DocumentID
	|
	|INTO TableOfExchangeDifferences
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|	LEFT JOIN PaymentDecryptionTable
	|	ON TRUE
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.PaymentWithConversion
	|	AND &ProcessedByBank
	|
	|GROUP BY
	|	DocumentData.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableBankAccountCash(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "BankAccountCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee)
		And Not DocumentObject.PersonsList
		And Not DocumentObject.PaymentWithConversion Then
	
		QueryText = "
		|SELECT
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		VALUE(AccumulationRecordType.Expense)
		|	ELSE
		|		VALUE(AccumulationRecordType.Receipt)
		|	END AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.BankAccount                                              AS BankAccount,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			PaymentDecryptionTable.Sum
		|	ELSE
		|		0
		|	END AS Sum,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			PaymentDecryptionTable.SumMan
		|	ELSE
		|		0
		|	END AS SumMan,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			PaymentDecryptionTable.SumCompl
		|	ELSE
		|		0
		|	END AS SumCompl,
		|	
		|	CASE
		|		WHEN NOT DocumentData.ProcessedByBank THEN
		|			PaymentDecryptionTable.Sum
		|	ELSE
		|		0
		|	END AS ToWriteOff,
		|	
		|	&BusinessOperation                                                      AS BusinessOperation,
		|	PaymentDecryptionTable.CashFlowItem                     AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem                              AS TargetFundItem,
		|	DocumentData.PaymentType275FZ                                             AS PaymentType275FZ,
		|
		|	CASE 
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|			THEN UNDEFINED
		|		ELSE PaymentDecryptionTable.AccountingDimensionByPartners
		|	END AS AccountingDimensionByPartners,
		|	PaymentDecryptionTable.ARAPObject                                    AS ARAPObject,
		|	DocumentData.Ref                                                      AS PaymentDocument,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			PaymentDecryptionTable.RowID
		|	ELSE
		|		&IDOfUnusedFinRecord
		|	END AS FinRecordID,
		|
		|	CASE 
		|		WHEN NOT DocumentData.ProcessedByBank 
		|			THEN UNDEFINED
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
		|			THEN CASE PaymentDecryptionTable.TypeOfLeasePayment
		|					WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
		|						THEN VALUE(Catalog.BusinessTransactionsSettings.PaymentForLeaseServices)
		|					WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
		|						THEN VALUE(Catalog.BusinessTransactionsSettings.PaymentForLeaseServices)
		|					WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
		|						THEN VALUE(Catalog.BusinessTransactionsSettings.SecurityPayment)
		|					WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
		|						THEN VALUE(Catalog.BusinessTransactionsSettings.LeaseBuyoutValuePayment)
		|					WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
		|						THEN VALUE(Catalog.BusinessTransactionsSettings.LeaseBuyoutValuePrepayment)
		|					ELSE &BusinessTransactionSetting
		|				END
		|		ELSE &BusinessTransactionSetting
		|	END AS BusinessTransactionSetting
		|		
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON TRUE";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And DocumentObject.PersonsList Then
	
		QueryText = "
		|SELECT
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		VALUE(AccumulationRecordType.Expense)
		|	ELSE
		|		VALUE(AccumulationRecordType.Receipt)
		|	END AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.BankAccount                                              AS BankAccount,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			TablePersonalAccountsOfEmployees.Sum
		|	ELSE
		|		0
		|	END AS Sum,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			TablePersonalAccountsOfEmployees.SumMan
		|	ELSE
		|		0
		|	END AS SumMan,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			TablePersonalAccountsOfEmployees.SumCompl
		|	ELSE
		|		0
		|	END AS SumCompl,
		|	
		|	CASE
		|		WHEN NOT DocumentData.ProcessedByBank THEN
		|			TablePersonalAccountsOfEmployees.Sum
		|	ELSE
		|		0
		|	END AS ToWriteOff,
		|	
		|	&BusinessOperation                                                      AS BusinessOperation,
		|	TablePersonalAccountsOfEmployees.CashFlowItem                AS CashFlowItem,
		|	UNDEFINED                                                                AS TargetFundItem,
		|	DocumentData.PaymentType275FZ                                             AS PaymentType275FZ,
		|
		|	UNDEFINED AS AccountingDimensionByPartners,
		
		|	UNDEFINED                                                                AS ARAPObject,
		|	DocumentData.Ref                                                      AS PaymentDocument,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			TablePersonalAccountsOfEmployees.RowID
		|	ELSE
		|		&IDOfUnusedFinRecord
		|	END AS FinRecordID,
		|
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		TablePersonalAccountsOfEmployees AS TablePersonalAccountsOfEmployees
		|	ON
		|		DocumentData.PaymentWithConversion = FALSE
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue)
		And Not DocumentObject.PaymentWithConversion Then
	
		QueryText = "
		|SELECT
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		VALUE(AccumulationRecordType.Expense)
		|	ELSE
		|		VALUE(AccumulationRecordType.Receipt)
		|	END AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.BankAccount                                              AS BankAccount,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			PaymentDecryptionTable.Sum
		|	ELSE
		|		0
		|	END AS Sum,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			PaymentDecryptionTable.SumMan
		|	ELSE
		|		0
		|	END AS SumMan,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			PaymentDecryptionTable.SumCompl
		|	ELSE
		|		0
		|	END AS SumCompl,
		|	
		|	CASE
		|		WHEN NOT DocumentData.ProcessedByBank THEN
		|			PaymentDecryptionTable.Sum
		|	ELSE
		|		0
		|	END AS ToWriteOff,
		|	
		|	&BusinessOperation                                                      AS BusinessOperation,
		|	PaymentDecryptionTable.CashFlowItem                     AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem                              AS TargetFundItem,
		|	DocumentData.PaymentType275FZ                                             AS PaymentType275FZ,
		|	UNDEFINED                                                                AS AccountingDimensionByPartners,
		|	UNDEFINED                                                                AS ARAPObject,
		|	DocumentData.Ref                                                      AS PaymentDocument,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			PaymentDecryptionTable.RowID
		|	ELSE
		|		&IDOfUnusedFinRecord
		|	END AS FinRecordID,
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		&BusinessTransactionSetting
		|	ELSE
		|		UNDEFINED
		|	END AS BusinessTransactionSetting
		|	
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
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashToAnotherAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment) Then
	
		QueryText = "
		|SELECT
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		VALUE(AccumulationRecordType.Expense)
		|	ELSE
		|		VALUE(AccumulationRecordType.Receipt)
		|	END AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.BankAccount                                              AS BankAccount,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		DocumentData.DocumentAmount
		|	ELSE
		|		0
		|	END AS Sum,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|	ELSE
		|		0
		|	END AS SumMan,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
		|	ELSE
		|		0
		|	END AS SumCompl,
		|	
		|	CASE WHEN NOT DocumentData.ProcessedByBank THEN
		|		DocumentData.DocumentAmount
		|	ELSE
		|		0
		|	END AS ToWriteOff,
		|	
		|	&BusinessOperation                                                      AS BusinessOperation,
		|	&CashFlowItem                                              AS CashFlowItem,
		|	&TargetFundItem                                                       AS TargetFundItem,
		|	DocumentData.PaymentType275FZ                                             AS PaymentType275FZ,
		|	UNDEFINED                                                                AS AccountingDimensionByPartners,
		|	UNDEFINED                                                                AS ARAPObject,
		|	DocumentData.Ref                                                      AS PaymentDocument,
		|	
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		DocumentData.DocumentID
		|	ELSE
		|		&IDOfUnusedFinRecord
		|	END AS FinRecordID,
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		&BusinessTransactionSetting
		|	ELSE
		|		UNDEFINED
		|	END AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.PaymentWithConversion Then
		
		QueryText = "
		|SELECT
		|	CASE WHEN DocumentData.ProcessedByBank THEN
		|		VALUE(AccumulationRecordType.Expense)
		|	ELSE
		|		VALUE(AccumulationRecordType.Receipt)
		|	END                                                                       AS RecordType,
		|	&Period                                                                     AS Period,
		|	
		|	DocumentData.Organization                                                 AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.BankAccount                                              AS BankAccount,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			DocumentData.AmountInPayerSCurrency
		|	ELSE
		|		0
		|	END                                                                       AS Sum,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			DocumentData.AmountInPayerSCurrency * &ConversionRatioOfFundsIntoManSCurrency
		|	ELSE
		|		0
		|	END                                                                       AS SumMan,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			DocumentData.AmountInPayerSCurrency * &ConversionRatioOfFundsToLocalCurrency
		|	ELSE
		|		0
		|	END                                                                       AS SumCompl,
		|	
		|	CASE
		|		WHEN NOT DocumentData.ProcessedByBank THEN
		|			PaymentDecryptionTable.Sum
		|	ELSE
		|		0
		|	END                                                                       AS ToWriteOff,
		|	
		|	&BusinessOperation                                                      AS BusinessOperation,
		|	&CashFlowItem                                              AS CashFlowItem,
		|	&TargetFundItem                                                       AS TargetFundItem,
		|	DocumentData.PaymentType275FZ                                             AS PaymentType275FZ,
		|
		|	UNDEFINED                                                                AS AccountingDimensionByPartners,
		|
		|	UNDEFINED                                                                AS ARAPObject,
		|	DocumentData.Ref                                                      AS PaymentDocument,
		|	
		|	CASE
		|		WHEN DocumentData.ProcessedByBank THEN
		|			DocumentData.DocumentID
		|	ELSE
		|		&IDOfUnusedFinRecord
		|	END                                                                       AS FinRecordID,
		|
		|	CASE 
		|		WHEN NOT DocumentData.ProcessedByBank 
		|			THEN UNDEFINED
		|		ELSE &BusinessTransactionSetting
		|	END                                                                       AS BusinessTransactionSetting
		|		
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON DocumentData.ProcessedByBank = FALSE";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TablePersonalAccountsOfEmployees", QueryTexts) Then
		QueryTextTemporaryTablePersonalAccountsOfEmployees(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInTransit(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.ProcessedByBank Then
		Return "";
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                       AS RecordType,
		|	&Period                                                                      AS Period,
		|	
		|	DocumentData.Organization                                                  AS Organization,
		|	DocumentData.CashAccountRecipient                                              AS Recipient,
		|	DocumentData.BankAccount                                               AS Sender,
		|	VALUE(Enum.CashTransferKinds.CashCollectionFromBank_)        AS CashTransferKind,
		|	UNDEFINED                                                                 AS Counterparty,
		|	UNDEFINED                                                                 AS Contract,
		|	DocumentData.Currency                                                       AS Currency,
		|	
		|	DocumentData.DocumentAmount                                               AS Sum,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency             AS SumMan,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul            AS SumCompl,
		|	
		|	DocumentData.BusinessOperation                                        AS BusinessOperation,
		|	&CashFlowItem                                               AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                       AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.WithdrawalFromBankAccount) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
	
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashToAnotherAccount Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                       AS RecordType,
		|	&Period                                                                      AS Period,
		|	
		|	DocumentData.Organization                                                  AS Organization,
		|	DocumentData.BankAccountBeneficiary                                     AS Recipient,
		|	DocumentData.BankAccount                                               AS Sender,
		|	VALUE(Enum.CashTransferKinds.CashTransferToOtherAccount) AS CashTransferKind,
		|	UNDEFINED                                                                 AS Counterparty,
		|	UNDEFINED                                                                 AS Contract,
		|	DocumentData.Currency                                                       AS Currency,
		|	
		|	DocumentData.DocumentAmount                                               AS Sum,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency             AS SumMan,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul            AS SumCompl,
		|	
		|	DocumentData.BusinessOperation                                        AS BusinessOperation,
		|	&CashFlowItem                                               AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                       AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.TransferCashToAnotherAccount) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
	
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                       AS RecordType,
		|	&Period                                                                      AS Period,
		|	
		|	DocumentData.Organization                                                  AS Organization,
		|	DocumentData.BankAccountBeneficiary                                     AS Recipient,
		|	UNDEFINED                                                                 AS Sender,
		|	CASE WHEN DocumentData.Currency = &LocalAccountingCurrency
		|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
		|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
		|	END                                                                        AS CashTransferKind,
		|	DocumentData.Counterparty                                                   AS Counterparty,
		|	UNDEFINED                                                                 AS Contract,
		|	DocumentData.Currency                                                       AS Currency,
		|	
		|	DocumentData.DocumentAmount                                               AS Sum,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency             AS SumMan,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul            AS SumCompl,
		|	
		|	DocumentData.BusinessOperation                                        AS BusinessOperation,
		|	&CashFlowItem                                               AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                       AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversion)        AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.PaymentWithConversion Then
	
		QueryText = "
		|SELECT // Payment With Conversion
		|	VALUE(AccumulationRecordType.Receipt)                                       AS RecordType,
		|	&Period                                                                      AS Period,
		|	
		|	DocumentData.Organization                                                  AS Organization,
		|	DocumentData.BankAccount                                               AS Recipient,
		|	UNDEFINED                                                                 AS Sender,
		|	CASE WHEN &CashCurrency = &LocalAccountingCurrency
		|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
		|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
		|	END                                                                        AS CashTransferKind,
		|	UNDEFINED                                                                 AS Counterparty,
		|	UNDEFINED                                                                 AS Contract,
		|	&CashCurrency                                                       AS Currency,
		|	
		|	DocumentData.AmountInPayerSCurrency                                      AS Sum,
		|	DocumentData.AmountInPayerSCurrency * &ConversionRatioOfFundsIntoManSCurrency AS SumMan,
		|	DocumentData.AmountInPayerSCurrency * &ConversionRatioOfFundsToLocalCurrency AS SumCompl,
		|	
		|	DocumentData.BusinessOperation                                        AS BusinessOperation,
		|	&CashFlowItem                                               AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                       AS FinRecordID,
		|	&BusinessTransactionSetting                                              AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.PaymentWithConversion Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                       AS RecordType,
		|	DocumentData.Date                                                         AS Period,
		|	
		|	DocumentData.Organization                                                  AS Organization,
		|	DocumentData.BankAccount                                               AS Recipient,
		|	UNDEFINED                                                                 AS Sender,
		|	CASE WHEN &CashCurrency = &LocalAccountingCurrency
		|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
		|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
		|	END                                                                        AS CashTransferKind,
		|	UNDEFINED                                                                 AS Counterparty,
		|	UNDEFINED                                                                 AS Contract,
		|	&CashCurrency                                                       AS Currency,
		|	
		|	PaymentDecryptionTable.Sum                                              AS Sum,
		|	PaymentDecryptionTable.SumMan                                           AS SumMan,
		|	PaymentDecryptionTable.SumCompl                                          AS SumCompl,
		|	
		|	&BusinessOperation                                                       AS BusinessOperation,
		|	PaymentDecryptionTable.CashFlowItem                      AS CashFlowItem,
		|	PaymentDecryptionTable.RowID                                AS FinRecordID,
		|	CASE
		|		WHEN NOT DocumentData.ProcessedByBank
		|			THEN UNDEFINED
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
		|			THEN CASE PaymentDecryptionTable.TypeOfLeasePayment
		|					WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
		|						THEN VALUE(Catalog.BusinessTransactionsSettings.PaymentForLeaseServices)
		|					WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
		|						THEN VALUE(Catalog.BusinessTransactionsSettings.SecurityPayment)
		|					WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
		|						THEN VALUE(Catalog.BusinessTransactionsSettings.LeaseBuyoutValuePayment)
		|					WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)
		|						THEN VALUE(Catalog.BusinessTransactionsSettings.LeaseBuyoutValuePrepayment)
		|					ELSE &BusinessTransactionSetting
		|				END
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
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;

	QueryText = "
	|// positive exchange rate differences, payment with conversion
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)                                           AS RecordType,
	|	&Period                                                                          AS Period,
	|	
	|	&Organization                                                                     AS Organization,
	|	&BankAccount                                                                  AS Recipient,
	|	UNDEFINED                                                                     AS Sender,
	|	CASE WHEN &CashCurrency = &LocalAccountingCurrency
	|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
	|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
	|	END                                                                            AS CashTransferKind,
	|	UNDEFINED                                                                     AS Counterparty,
	|	UNDEFINED                                                                     AS Contract,
	|	&CashCurrency                                                           AS Currency,
	|	
	|	-TableOfExchangeDifferences.Sum                                                     AS Sum,
	|	-TableOfExchangeDifferences.SumMan                                                  AS SumMan,
	|	-TableOfExchangeDifferences.SumCompl                                                 AS SumCompl,
	|	
	|	VALUE(Enum.BusinessTransactions.CurrencyConversion)                   AS BusinessOperation,
	|	&CashFlowItem                                                   AS CashFlowItem,
	|	
	|	TableOfExchangeDifferences.DocumentID                                     AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversion)            AS BusinessTransactionSetting
	|	
	|FROM
	|	TableOfExchangeDifferences AS TableOfExchangeDifferences
	|	
	|WHERE
	|	(TableOfExchangeDifferences.SumMan < 0 OR TableOfExchangeDifferences.SumCompl < 0)
	|	
	|UNION ALL
	|
	|// negative exchange differences, payment with conversion
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)                                          AS RecordType,
	|	&Period                                                                         AS Period,
	|	
	|	&Organization                                                                    AS Organization,
	|	&BankAccount                                                                 AS Recipient,
	|	UNDEFINED                                                                    AS Sender,
	|	CASE WHEN &CashCurrency = &LocalAccountingCurrency
	|		THEN VALUE(Enum.CashTransferKinds.ForeignExchangeBuying)
	|		ELSE VALUE(Enum.CashTransferKinds.ForeignExchangeSelling)
	|	END                                                                           AS CashTransferKind,
	|	UNDEFINED                                                                    AS Counterparty,
	|	UNDEFINED                                                                    AS Contract,
	|	&CashCurrency                                                          AS Currency,
	|	
	|	TableOfExchangeDifferences.Sum                                                     AS Sum,
	|	TableOfExchangeDifferences.SumMan                                                  AS SumMan,
	|	TableOfExchangeDifferences.SumCompl                                                 AS SumCompl,
	|	
	|	VALUE(Enum.BusinessTransactions.CurrencyConversion)                  AS BusinessOperation,
	|	&CashFlowItem                                                   AS CashFlowItem,
	|	
	|	TableOfExchangeDifferences.DocumentID                                     AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversion)           AS BusinessTransactionSetting
	|	
	|FROM
	|	TableOfExchangeDifferences AS TableOfExchangeDifferences
	|	
	|WHERE
	|	(TableOfExchangeDifferences.SumMan > 0 OR TableOfExchangeDifferences.SumCompl > 0)";
	
	ArrayOfRequestTexts.Add(QueryText);
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                               AS RecordType,
		|	&Period                                                                              AS Period,
		|	
		|	DocumentData.Organization                                                          AS Organization,
		|	DocumentData.BankAccount                                                       AS Recipient,
		|	UNDEFINED                                                                         AS Sender,
		|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)   AS CashTransferKind,
		|	DocumentData.Counterparty                                                           AS Counterparty,
		|	DocumentData.AcquiringContract                                                    AS Contract,
		|	DocumentData.Currency                                                               AS Currency,
		|	
		|	DocumentData.DocumentAmount                                                       AS Sum,
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency                     AS SumMan,
		|	DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul                    AS SumCompl,
		|	
		|	DocumentData.BusinessOperation                                                AS BusinessOperation,
		|	&CashFlowItem                                                       AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                               AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.RefundAcquiringPayment)    AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment
		And DocumentObject.FeeAmount <> 0 And DocumentObject.RecordCommission Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Expense)                                               AS RecordType,
		|	&Period                                                                              AS Period,
		|	
		|	DocumentData.Organization                                                          AS Organization,
		|	DocumentData.BankAccount                                                       AS Recipient,
		|	UNDEFINED                                                                         AS Sender,
		|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)   AS CashTransferKind,
		|	DocumentData.Counterparty                                                           AS Counterparty,
		|	DocumentData.AcquiringContract                                                    AS Contract,
		|	DocumentData.Currency                                                               AS Currency,
		|	
		|	DocumentData.FeeAmount                                                               AS Sum,
		|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2))   AS SumMan,
		|	CAST(DocumentData.FeeAmount * &FactorOfConversionToCurrencyOfRegul  AS NUMBER(31,2)) AS SumCompl,
		|	
		|	VALUE(Enum.BusinessTransactions.AcquiringFee)                    AS BusinessOperation,
		|	DocumentData.AcquiringContract.CashFlowItemCommission              AS CashFlowItem,
		|	
		|	DocumentData.DocumentID                                               AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.AcquiringFee)             AS BusinessTransactionSetting 
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And DocumentObject.PersonsList Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                          AS RecordType,
		|	&Period                                                                         AS Period,
		|	
		|	DocumentData.Organization                                                     AS Organization,
		|	UNDEFINED                                                                    AS Recipient,
		|	DocumentData.BankAccount                                                  AS Sender,
		|	VALUE(Enum.CashTransferKinds.TransferToPersons) AS CashTransferKind,
		|	DocumentData.Counterparty                                                      AS Counterparty,
		|	UNDEFINED                                                                    AS Contract,
		|	DocumentData.Currency                                                          AS Currency,
		|	
		|	TablePersonalAccountsOfEmployees.Sum                                            AS Sum,
		|	TablePersonalAccountsOfEmployees.SumMan                                         AS SumMan,
		|	TablePersonalAccountsOfEmployees.SumCompl                                        AS SumCompl,
		|	
		|	DocumentData.BusinessOperation                                           AS BusinessOperation,
		|	TablePersonalAccountsOfEmployees.CashFlowItem                    AS CashFlowItem,
		|	
		|	TablePersonalAccountsOfEmployees.RowID                              AS FinRecordID,
		|	ISNULL(BusinessTransactionsSettings.Ref, VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	LEFT JOIN TablePersonalAccountsOfEmployees AS TablePersonalAccountsOfEmployees
		|	ON TRUE
		|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|";
	
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)                                          AS RecordType,
		|	&Period                                                                         AS Period,
		|	
		|	DocumentData.Organization                                                     AS Organization,
		|	UNDEFINED                                                                    AS Recipient,
		|	DocumentData.BankAccount                                                  AS Sender,
		|	VALUE(Enum.CashTransferKinds.TransferToPersons) AS CashTransferKind,
		|	DocumentData.Counterparty                                                      AS Counterparty,
		|	UNDEFINED                                                                    AS Contract,
		|	DocumentData.Currency                                                          AS Currency,
		|	
		|	PaymentDecryptionTable.Sum                                                 AS Sum,
		|	PaymentDecryptionTable.SumMan                                              AS SumMan,
		|	PaymentDecryptionTable.SumCompl                                             AS SumCompl,
		|	
		|	DocumentData.BusinessOperation                                           AS BusinessOperation,
		|	PaymentDecryptionTable.CashFlowItem                         AS CashFlowItem,
		|	
		|	PaymentDecryptionTable.RowID                                   AS FinRecordID,
		|	ISNULL(BusinessTransactionsSettings.Ref, VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)) AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON TRUE
		|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|	
		|WHERE
		|	&TransferViaTransfersOnWay
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TablePersonalAccountsOfEmployees", QueryTexts) Then
		QueryTextTemporaryTablePersonalAccountsOfEmployees(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "AdvanceHolderCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not(DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And DocumentObject.ProcessedByBank And Not DocumentObject.PersonsList) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization,
	|	DocumentData.AdvanceHolder,
	|	DocumentData.Department AS Department,
	|	CASE WHEN DocumentData.PaymentWithConversion THEN
	|		PaymentDecryptionTable.ARAPCurrency
	|	ELSE
	|		DocumentData.BankAccountCashCurrency
	|	END AS Currency,
	|
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		PaymentDecryptionTable.CashFlowItem
	|	END AS IssuancePurpose,
	|	DocumentData.BusinessOperation,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	CASE WHEN DocumentData.PaymentWithConversion THEN
	|		PaymentDecryptionTable.AmountARAP
	|	ELSE
	|		PaymentDecryptionTable.Sum
	|	END AS Sum,
	|	PaymentDecryptionTable.SumCompl AS SumCompl,
	|	PaymentDecryptionTable.SumMan AS SumMan,
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
	|
	|UNION ALL
	|
	|SELECT
	|	ENDOFPERIOD(DocumentData.ExpenseReportDate, DAY) AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization,
	|	DocumentData.AdvanceHolder,
	|	DocumentData.Department AS Department, 
	|	CASE WHEN DocumentData.PaymentWithConversion THEN
	|		PaymentDecryptionTable.ARAPCurrency
	|	ELSE
	|		DocumentData.BankAccountCashCurrency
	|	END AS Currency,
	|
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		PaymentDecryptionTable.CashFlowItem
	|	END AS IssuancePurpose,
	|	DocumentData.BusinessOperation,
	|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
	|	0 AS Sum,
	|	0 AS SumCompl,
	|	0 AS SumMan,
	|	CASE WHEN DocumentData.PaymentWithConversion THEN
	|		PaymentDecryptionTable.AmountARAP
	|	ELSE
	|		PaymentDecryptionTable.Sum
	|	END AS ToReport,
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
	
	If Query.Parameters.Property("UsePaymentRequests") Then
		UsePaymentRequests = Query.Parameters.UsePaymentRequests;
	Else
		UsePaymentRequests = GetFunctionalOption("UsePaymentRequests");
	EndIf;
	
	If Not UsePaymentRequests Then
		Return "";
	EndIf;
	
	QueryTextArray = New Array;
	
	QueryText = "
	|SELECT // The application is in decryption, payment is within the limits of the application.
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DecryptionRequests.PaymentRequest AS PaymentRequest,
	|	DocumentData.BankAccount AS BankAccountCashAccount,
	|	CASE
	|		WHEN DecryptionRequests.PaymentRequest REFS Document.PaymentRequest THEN
	|			CASE WHEN CAST(DecryptionRequests.PaymentRequest AS Document.PaymentRequest).PersonsList THEN
	|				UNDEFINED
	|			WHEN CAST(DecryptionRequests.PaymentRequest AS Document.PaymentRequest).ListOfCounterparties_ THEN
	|				UNDEFINED
	|			ELSE
	|				&Recipient
	|			END
	|		WHEN DocumentData.ListOfCounterparties_
	|			THEN UNDEFINED
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
	|		AND Cash.BankAccountCashAccount = DocumentData.BankAccount
	|		AND Cash.Recorder <> DocumentData.Ref
	|		AND Cash.Active
	|		AND Cash.Recorder <> &CorrectedDocument
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
	|			WHEN CAST(DecryptionRequests.PaymentRequest AS Document.PaymentRequest).ListOfCounterparties_ THEN
	|				UNDEFINED
	|			ELSE
	|				&Recipient
	|			END
	|		WHEN DocumentData.ListOfCounterparties_
	|			THEN UNDEFINED
	|		ELSE
	|			&Recipient
	|	END,
	|	DecryptionRequests.Sum,
	|	DocumentData.BankAccount
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
	|SELECT // Transcript of the application, payment in excess of the application.
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DecryptionRequests.PaymentRequest AS PaymentRequest,
	|	UNDEFINED AS BankAccountCashAccount,
	|	CASE
	|		WHEN DecryptionRequests.PaymentRequest REFS Document.PaymentRequest THEN
	|			CASE WHEN CAST(DecryptionRequests.PaymentRequest AS Document.PaymentRequest).PersonsList THEN
	|				UNDEFINED
	|			WHEN CAST(DecryptionRequests.PaymentRequest AS Document.PaymentRequest).ListOfCounterparties_ THEN
	|				UNDEFINED
	|			ELSE
	|				&Recipient
	|			END
	|		WHEN DocumentData.ListOfCounterparties_
	|			THEN UNDEFINED
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
	|		AND Cash.BankAccountCashAccount = DocumentData.BankAccount
	|		AND Cash.Recorder <> DocumentData.Ref
	|		AND Cash.Active
	|		AND Cash.Recorder <> &CorrectedDocument
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
	|			WHEN CAST(DecryptionRequests.PaymentRequest AS Document.PaymentRequest).ListOfCounterparties_ THEN
	|				UNDEFINED
	|			ELSE
	|				&Recipient
	|			END
	|		WHEN DocumentData.ListOfCounterparties_
	|			THEN UNDEFINED
	|		ELSE
	|			&Recipient
	|	END,
	|	DecryptionRequests.Sum,
	|	DocumentData.BankAccount
	|	
	|HAVING
	|	DecryptionRequests.Sum >
	|		ISNULL(SUM(CASE
	|			WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Cash.Sum
	|			ELSE -Cash.Sum
	|		END), 0)";
	
	QueryTextArray.Add(QueryText);
	
	If DocumentObject = Undefined 
		Or (DocumentObject.PaymentRequest <> Documents.PaymentRequest.EmptyRef()
		And DocumentObject.PaymentRequest <> Undefined) Then
	
		QueryText = "SELECT // Application in the header
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	DocumentData.PaymentRequest AS PaymentRequest,
		|	DocumentData.BankAccount AS BankAccountCashAccount,
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
		|		AND Cash.BankAccountCashAccount = DocumentData.BankAccount
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
		|	DocumentData.DocumentAmount,
		|	DocumentData.PaymentRequest,
		|	DocumentData.BankAccount
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
		|		AND Cash.BankAccountCashAccount = DocumentData.BankAccount
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
		|	DocumentData.DocumentAmount,
		|	DocumentData.PaymentRequest,
		|	DocumentData.BankAccount
		|	
		|HAVING
		|	DocumentData.DocumentAmount >
		|		ISNULL(SUM(CASE
		|			WHEN Cash.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN Cash.Sum
		|			ELSE -Cash.Sum
		|		END), 0)";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.CashTransferReferenceOrder <> Documents.CashTransferReferenceOrder.EmptyRef()
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashToAnotherAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount)) Then
	
		QueryText = "SELECT // Available to move
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	DocumentData.CashTransferReferenceOrder AS PaymentRequest,
		|	DocumentData.BankAccount AS BankAccountCashAccount,
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
		|		VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount),
		|		VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount)
		|		)
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;

	
	If QueryTextArray.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.BankAccountIssue");
		QueryText = StrReplace(QueryText, "DocumentDataTableDecryptionOfPayment", "Document.BankAccountIssue.ARAPDetails");
		QueryText = StrReplace(QueryText, "DocumentData.PaymentRequestCurrency", "DocumentData.PaymentRequest.Currency");
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
	
	If Query.Parameters.Property("UsePayroll") Then
		UsePayroll = Query.Parameters.UsePayroll;
	Else
		UsePayroll = Constants.UsePayroll.Get();
	EndIf;

	QueryTextArray = New Array;
	
	If DocumentObject.BusinessOperation <> Enums.BusinessTransactions.TransferCashToAnotherAccount
		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram
		And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SalaryPaymentToBankAccounts Then
			
		QueryText = "
		|SELECT
		|	PaymentDecryptionTable.LineNumber AS ApplicationLineNumber,
		|	&Period AS Period,
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
		|		ELSE DocumentData.BankAccountDivision
		|	END AS Department,
		|	
		|	CASE WHEN &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PaymentToVendor),
		|		VALUE(Enum.BusinessTransactions.RefundToCustomer), 
		|		VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany), 
		|		VALUE(Enum.BusinessTransactions.RefundToAnotherCompany), 
		|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
		|		VALUE(Enum.BusinessTransactions.OtherCashIssue),
		|		VALUE(Enum.BusinessTransactions.TransferOfTaxesAndContributions),
		|		VALUE(Enum.BusinessTransactions.CustomsPayment),
		|		VALUE(Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived), 
		|		VALUE(Enum.BusinessTransactions.TransferToDeposits), 
		|		VALUE(Enum.BusinessTransactions.CashIssueAsLoanToCounterparty),
		|		VALUE(Enum.BusinessTransactions.PaymentToLessor),
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
		|		DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
		|	ON
		|		PaymentDecryptionTable.Ref = DocumentData.Ref
		|	
		|WHERE
		|	(PaymentDecryptionTable.PaymentRequest = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR PaymentDecryptionTable.PaymentRequest = UNDEFINED)
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram
		And Not UsePayroll Then
			
		QueryText = "
		|SELECT
		|	0 AS ApplicationLineNumber,
		|	&Period AS Period,
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
		|		ELSE DocumentData.BankAccountDivision
		|	END AS Department,
		|	
		|	&CashFlowItem AS CashFlowItem,
		|	
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency AS ExcessExpense
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|
		|WHERE
		|	(&PaymentRequest = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR &PaymentRequest = UNDEFINED)
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts
		And Not UsePayroll Then
	
		QueryText = "
		|SELECT
		|	0 AS ApplicationLineNumber,
		|	&Period AS Period,
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
		|		ELSE DocumentData.BankAccountDivision
		|	END AS Department,
		|	
		|	&CashFlowItem AS CashFlowItem,
		|	
		|	DocumentData.DocumentAmount * &ConversionRateToManCurrency AS ExcessExpense
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|
		|WHERE
		|	(&PaymentRequest = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR &PaymentRequest = UNDEFINED)";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If QueryTextArray.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = QueryText + "
	|
	|ORDER BY
	|	ApplicationLineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|// Calculation of exchange differences
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.CurrencyConversionIncome) AS IncomeItem,
	|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfRevenue,
	|	TableOfExchangeDifferences.Department AS Department,
	|	TableOfExchangeDifferences.LineOfBusiness AS LineOfBusiness,
	|	
	|	VALUE(Enum.BusinessTransactions.CurrencyConversion) AS BusinessOperation,
	|	
	|	TableOfExchangeDifferences.SumMan AS Sum,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN TableOfExchangeDifferences.SumMan
	|		ELSE 0 END) AS SumMan,
	|	(CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN TableOfExchangeDifferences.SumCompl
	|		ELSE 0 END) AS SumCompl,
	|	
	|	TableOfExchangeDifferences.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversion) AS BusinessTransactionSetting
	|	
	|FROM
	|	TableOfExchangeDifferences AS TableOfExchangeDifferences
	|
	|WHERE
	|	&ProcessedByBank
	|	AND (TableOfExchangeDifferences.SumMan > 0 OR TableOfExchangeDifferences.SumCompl > 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, DocumentObject = Undefined)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAmountsOfDocumentsInAccountingCurrencies", QueryTexts) Then 
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Undefined, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Organization AS Organization,
	|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
	|	PaymentDecryptionTable.ExpenseItem AS ExpenseItem,
	|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	PaymentDecryptionTable.Department AS Department,
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
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|	AND &ProcessedByBank
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Organization AS Organization,
	|	DocumentData.AcquiringContractLineOfBusiness AS LineOfBusiness,
	|	DocumentData.ExpenseItem AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.Department AS Department,
	|	UNDEFINED AS VATActivityType,
	|	
	|	// Calculate the amount in the currency of management accounting.
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountIncludingVAT,
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVATMan,
	|
	|	ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl + DocumentAmountsInAccountingCurrency.VATAmountCompl, DocumentData.FeeAmount) AS AmountIncludingVATCompl,
	|	ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl, DocumentData.FeeAmount) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	VALUE(Enum.BusinessTransactions.AcquiringFee) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	DocumentData.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AcquiringFee) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmountsInAccountingCurrency
	|	ON
	|		DocumentAmountsInAccountingCurrency.Ref = DocumentData.Ref
	|		AND DocumentAmountsInAccountingCurrency.RowID = ""1""
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ProcessedByBank
	|	AND DocumentData.FeeAmount <> 0
	|	AND DocumentData.RecordCommission
	|	AND NOT DocumentData.PaymentWithConversion
	|	AND NOT DocumentData.KeepRecordsOfCommissionInARAPAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Organization AS Organization,
	|	TableOfExchangeDifferences.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.CurrencyConversionExpenses) AS ExpenseItem,
	|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
	|	TableOfExchangeDifferences.Department AS Department,
	|	UNDEFINED AS VATActivityType,
	|
	|	-TableOfExchangeDifferences.SumMan AS AmountIncludingVAT,
	|	-TableOfExchangeDifferences.SumMan AS AmountExcludingVAT,
	|	-TableOfExchangeDifferences.SumMan AS AmountExcludingVATMan,
	|	-TableOfExchangeDifferences.SumCompl AS AmountIncludingVATCompl,
	|	-TableOfExchangeDifferences.SumCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	VALUE(Enum.BusinessTransactions.CurrencyConversion) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	TableOfExchangeDifferences.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversion) AS BusinessTransactionSetting
	|	
	|FROM
	|	TableOfExchangeDifferences AS TableOfExchangeDifferences
	|
	|WHERE
	|	&ProcessedByBank
	|	AND (TableOfExchangeDifferences.SumMan < 0 OR TableOfExchangeDifferences.SumCompl < 0)
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.BankAccountIssue");
		QueryText = StrReplace(QueryText, "DocumentData.AcquiringContractLineOfBusiness", "DocumentData.AcquiringContract.LineOfBusiness");
	EndIf;
	
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

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.ProcessedByBank Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined, DocumentObject = Undefined) Export
	
	RegisterName = "DocumentAmountsInAccountingCurrency";
	
	If Registers <> Undefined And Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextdata_ = "
	|SELECT
	|	""DocumentData""     AS DataSource,
	|	TRUE                    AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	CASE 
	|		WHEN NOT DocumentTable.ProcessedByBank
	|				OR BEGINOFPERIOD(DocumentTable.Date, DAY) = DocumentTable.BankPostingDate
	|				OR DocumentTable.Patch  THEN
	|			DocumentTable.Date
	|		ELSE
	|			ENDOFPERIOD(DocumentTable.BankPostingDate, DAY)
	|	END                   AS Date,
	|	DocumentTable.Organization AS Organization,
	|	CASE WHEN DocumentTable.PaymentWithConversion THEN
	|		&CashCurrency
	|	ELSE
	|		DocumentTable.Currency
	|	END AS DocumentCurrency,
	|	ISNULL(Rows.ARAPCurrency, UNDEFINED) AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	CASE
	|		WHEN NOT DocumentTable.ProcessedByBank
	|				OR BEGINOFPERIOD(DocumentTable.Date, DAY) = DocumentTable.Ref.BankPostingDate THEN
	|			DocumentTable.Date
	|		ELSE
	|			ENDOFPERIOD(DocumentTable.BankPostingDate, DAY)
	|	END                   AS DateOfCourse,
	|
	|	ISNULL(Rows.LineNumber, 0) AS LineNumber,
	|	ISNULL(Rows.RowID, """") AS RowID,
	|	CASE
	|		WHEN DocumentTable.PaymentWithConversion THEN
	|			Rows.AmountInPayerSCurrency - Rows.VATAmountInPayerSCurrency
	|		ELSE ISNULL(Rows.Sum - Rows.VATAmount, DocumentTable.DocumentAmount)
	|	END AS AmountExcludingVAT,
	|	ISNULL(Rows.VATRate, UNDEFINED) AS VATRate,
	|	CASE
	|		WHEN DocumentTable.PaymentWithConversion
	|			THEN Rows.VATAmountInPayerSCurrency
	|		ELSE ISNULL(Rows.VATAmount, 0)
	|	END AS VATAmount,
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
	|		LEFT JOIN DocumentDataTableDecryptionOfPayment AS Rows
	|		ON Rows.Ref = DocumentTable.Ref
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""DocumentData"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	CASE 
	|		WHEN NOT DocumentTable.ProcessedByBank
	|				OR BEGINOFPERIOD(DocumentTable.Date, DAY) = DocumentTable.BankPostingDate
	|				OR DocumentTable.Patch THEN
	|			DocumentTable.Date
	|		ELSE
	|			ENDOFPERIOD(DocumentTable.BankPostingDate, DAY)
	|	END                   AS Date,
	|	DocumentTable.Organization AS Organization,
	|	DocumentTable.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	CASE
	|		WHEN NOT DocumentTable.ProcessedByBank
	|				OR BEGINOFPERIOD(DocumentTable.Date, DAY) = DocumentTable.BankPostingDate THEN
	|			DocumentTable.Date
	|		ELSE
	|			ENDOFPERIOD(DocumentTable.BankPostingDate, DAY)
	|	END                   AS DateOfCourse,
	|
	|	0 AS LineNumber,
	|	""1"" AS RowID,
	|	DocumentTable.FeeAmount AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.RecordCommission
	|	AND DocumentTable.FeeAmount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	""DocumentData""     AS DataSource,
	|	TRUE                    AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	CASE 
	|		WHEN NOT DocumentTable.ProcessedByBank
	|				OR BEGINOFPERIOD(DocumentTable.Date, DAY) = DocumentTable.BankPostingDate
	|				OR DocumentTable.Patch  THEN
	|			DocumentTable.Date
	|		ELSE
	|			ENDOFPERIOD(DocumentTable.BankPostingDate, DAY)
	|	END                   AS Date,
	|	DocumentTable.Organization AS Organization,
	|	DocumentTable.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	CASE
	|		WHEN NOT DocumentTable.ProcessedByBank
	|				OR BEGINOFPERIOD(DocumentTable.Date, DAY) = DocumentTable.BankPostingDate THEN
	|			DocumentTable.Date
	|		ELSE
	|			ENDOFPERIOD(DocumentTable.BankPostingDate, DAY)
	|	END                   AS DateOfCourse,
	|
	|	Rows.LineNumber AS LineNumber,
	|	Rows.RowID AS RowID,
	|	Rows.Sum AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	FALSE AS RecordedInARAPAccounting,
	|	VALUE(Catalog.ARAPObjects.EmptyRef) AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN DocumentDataTablePersonalAccountsOfEmployees AS Rows
	|		ON Rows.Ref = DocumentTable.Ref
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|// The amount of the bank's commission when paying with conversion
	|SELECT
	|	""DocumentData""     AS DataSource,
	|	TRUE                    AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	CASE 
	|		WHEN NOT DocumentTable.ProcessedByBank
	|				OR BEGINOFPERIOD(DocumentTable.Date, DAY) = DocumentTable.BankPostingDate
	|				OR DocumentTable.Patch THEN
	|			DocumentTable.Date
	|		ELSE
	|			ENDOFPERIOD(DocumentTable.BankPostingDate, DAY)
	|	END                   AS Date,
	|	DocumentTable.Organization AS Organization,
	|	DocumentTable.BankAccount.CashCurrency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	CASE
	|		WHEN NOT DocumentTable.ProcessedByBank
	|				OR BEGINOFPERIOD(DocumentTable.Date, DAY) = DocumentTable.BankPostingDate THEN
	|			DocumentTable.Date
	|		ELSE
	|			ENDOFPERIOD(DocumentTable.BankPostingDate, DAY)
	|	END                   AS DateOfCourse,
	|
	|	0 AS LineNumber,
	|	"""" AS RowID,
	|	DocumentTable.AmountInPayerSCurrency - ISNULL(Rows.TotalAmount_1, DocumentTable.AmountInPayerSCurrency) AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	FALSE AS RecordedInARAPAccounting,
	|	VALUE(Catalog.ARAPObjects.EmptyRef) AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	LEFT JOIN (SELECT
	|		TableOfAmounts.Ref AS Ref,
	|		SUM(CASE
	|			WHEN &PaymentWithConversion THEN
	|				TableOfAmounts.AmountInPayerSCurrency
	|			ELSE TableOfAmounts.Sum
	|		END) AS TotalAmount_1
	|	FROM
	|		DocumentDataTableDecryptionOfPayment AS TableOfAmounts
	|	
	|	GROUP BY
	|		TableOfAmounts.Ref) AS Rows
	|	ON DocumentTable.Ref = Rows.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.PaymentWithConversion
	|	AND DocumentTable.ProcessedByBank	
	|";
	
	If DocumentObject = Undefined Then
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataHeader", "Document.BankAccountIssue");
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataTableDecryptionOfPayment", "Document.BankAccountIssue.ARAPDetails");
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataTablePersonalAccountsOfEmployees", "Document.BankAccountIssue.PersonalAccountsOfStaff");
	EndIf;
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTrackingAnalyticsKeysForPartners(Query, QueryTexts, DocumentObject);
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Query.Parameters.Property("UsePaymentRequests") Then
		UsePaymentRequests = Query.Parameters.UsePaymentRequests;
	Else
		UsePaymentRequests = GetFunctionalOption("UsePaymentRequests");
	EndIf;
	
	QueryTextArray = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty) 
		And DocumentObject.ProcessedByBank Then
	
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
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty) 
		And Not (DocumentObject.PaymentByRequests And UsePaymentRequests) Then
			
		QueryText = "
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
		|	&IDOfUnusedFinRecord                             AS FinRecordID,
		|	UNDEFINED                                                      AS BusinessTransactionSetting,
		|	PaymentDecryptionTable.PaymentRequest     AS PaymentRequest
		|	
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
		|		INNER JOIN Catalog.LoanAndDepositContracts AS ContractData
		|		ON ContractData.Ref = PaymentDecryptionTable.LoanDepositContract
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor
		And DocumentObject.ProcessedByBank Then
			
		QueryText = "
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
		|				VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment),
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
		|	
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
		|";
		
		QueryTextArray.Add(QueryText);
	
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor
		And DocumentObject.PaymentByRequests Then
			
		QueryText = "
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
		|	&IDOfUnusedFinRecord                             AS FinRecordID,
		|	UNDEFINED                                                      AS BusinessTransactionSetting,
		|	PaymentDecryptionTable.PaymentRequest     AS PaymentRequest
		|	
		|FROM
		|	PaymentDecryptionTable AS PaymentDecryptionTable
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

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts, DocumentObject = Undefined)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	PaymentDecryptionTable.Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	PaymentDecryptionTable.ExpenseItem,
	|	PaymentDecryptionTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS LotVendorAttributes,
	|	PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
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
	|	INNER JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		PaymentDecryptionTable.ExpenseItem = ExpenseItems.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
	|	AND &ProcessedByBank
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts, DocumentObject = Undefined) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.ProcessedByBank Then
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

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	ThereAreOtherAssetsLiabilities = False;
	If DocumentObject.ProcessedByBank And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue 
		Or (DocumentObject.FeeAmount And DocumentObject.RecordCommission)) Then
		ThereAreOtherAssetsLiabilities = True;
	EndIf;
	
	ArrayOfQueryTests = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts 
		And DocumentObject.ProcessedByBank Then
		
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
	
		ArrayOfQueryTests.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram 
		And DocumentObject.ProcessedByBank Then
	
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
		|	
		|WHERE
		|	NOT &TransferViaTransfersOnWay";
	
		ArrayOfQueryTests.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue 
		And DocumentObject.ProcessedByBank Then
	
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
		|	SUM(PaymentDecryptionTable.SumMan) AS Sum
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON TRUE
		|WHERE
		|	PaymentDecryptionTable.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
		|	
		|GROUP BY
		|	PaymentDecryptionTable.ExpenseItem,
		|	PaymentDecryptionTable.Department,
		|	PaymentDecryptionTable.LineOfBusiness,
		|	PaymentDecryptionTable.AssetsLiabilitiesDimension";
		
		ArrayOfQueryTests.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	&Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes) AS AssetRef,
		|	DocumentData.TaxType AS Dimension,
		|	SUM(CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))) AS Sum
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON TRUE
		|	
		|GROUP BY
		|	DocumentData.Department,
		|	DocumentData.TaxType";
		
		ArrayOfQueryTests.Add(QueryText);
		
	EndIf;
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
		And DocumentObject.ProcessedByBank Then
	
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
		|	SUM(CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31, 2))) AS Sum
		|FROM
		|	DocumentDataHeader AS DocumentData
		|GROUP BY
		|	VALUE(AccumulationRecordType.Receipt),
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef),
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings)
		|HAVING
		|	SUM(CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31, 2))) > 0";
		
		ArrayOfQueryTests.Add(QueryText);
		
	EndIf;
	If ThereAreOtherAssetsLiabilities Then
		ArrayOfQueryTests.Add(AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities());
	EndIf;
	
	If ArrayOfQueryTests.Count() = 0 Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = StrConcat(ArrayOfQueryTests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	ReflectSettlementWITHBranches = False;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment) And DocumentObject.ProcessedByBank Then
		
		ReflectSettlementWITHBranches = True;
		
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If ReflectSettlementWITHBranches And Not DocumentsPosting.ThereIsQueryTable("TTMovementCounterpartyCounterparty", QueryTexts) Then
		RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts)
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.LineOfBusiness AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS AssetRef,
		|	UNDEFINED AS Dimension,
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
		|	DocumentDataHeader AS DocumentData
		|	LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON TRUE
		//++ WE
		|WHERE
		|	NOT &PayrollAndHumanResourcesWE
		//-- WE
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue
		And DocumentObject.ProcessedByBank Then
	
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
		|	PaymentDecryptionTable.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.LineOfBusiness AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes) AS AssetRef,
		|	DocumentData.TaxType AS Dimension,
		|	CASE
		|		WHEN PaymentDecryptionTable.GLAccountSettings = VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef)
		|			THEN DocumentData.GLAccountSettings
		|		ELSE PaymentDecryptionTable.GLAccountSettings
		|	END AS GLAccountSettings,
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
		|	DocumentDataHeader AS DocumentData
		|	LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON TRUE
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices
		And DocumentObject.ProcessedByBank Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting) AS AssetRef,
		|	DocumentData.BankAccountRecipientOwner AS Dimension,
		|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
		|
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountIncludingVAT,
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
		|
		|	DocumentData.DocumentID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
		And DocumentObject.ProcessedByBank Then
	
		// Issuing loans to an employee
		QueryText = "
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
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;

	If ArrayOfRequestTexts.Count() = 0 Then
		
		If ReflectSettlementWITHBranches Then
			QueryText = OtherAssetsLiabilitiesServer.QueryTextSettlementWithBranches();
			ArrayOfRequestTexts.Add(QueryText);
		EndIf;
		
	Else
		
		If ReflectSettlementWITHBranches Then
			ArrayOfRequestTexts.Add(OtherAssetsLiabilitiesServer.QueryTextSettlementWithBranches());
		EndIf;
		
	EndIf;
	
	QueryTextLocalization = BankAccountIssueLocalization.QueryTextTableOtherAssetsAndLiabilitiesRecords();
	
	If Not IsBlankString(QueryTextLocalization) Then
		
		ArrayOfRequestTexts.Add(QueryTextLocalization);
		
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashFlow(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CashFlow";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.ProcessedByBank Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAmountsOfDocumentsInAccountingCurrencies", QueryTexts) Then
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers, DocumentObject);
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashToAnotherAccount
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion)
		And Not DocumentObject.PersonsList Then
			
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusiness,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	
		|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|	THEN
		|		PaymentDecryptionTable.CashFlowItem
		|	ELSE
		|		&CashFlowItem
		|	END AS CashFlowItem,
		|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|	THEN
		|		PaymentDecryptionTable.TargetFundItem
		|	ELSE
		|		&TargetFundItem
		|	END AS TargetFundItem,
		|	
		|	CASE
		|		WHEN DocumentData.PaymentWithConversion THEN
		|			&CashCurrency
		|		ELSE DocumentData.Currency
		|	END AS Currency,
		|
		|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount)
		|		THEN DocumentData.BankAccountRecipientLineOfBusiness
		|		ELSE ISNULL(PaymentDecryptionTable.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|	END AS CorLineOfBusiness,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount)
		|			THEN DocumentData.BankAccountBeneficiary
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount)
		|			THEN DocumentData.CashAccountRecipient
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|			THEN DocumentData.AdvanceHolder
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
		|			THEN DocumentData.Counterparty
		|	END AS CorCash,
		|
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|			THEN VALUE(Enum.CashTypes.AdvanceHolderSCash)
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
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) THEN
		|			ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATMan, CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)))
		|		ELSE CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
		|	END AS Sum,
		|	
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder) THEN
		|			ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl, CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)))
		|		ELSE CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
		|	END AS SumCompl,
		|	
		|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|	THEN ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount)
		|	ELSE DocumentData.DocumentAmount END AS AmountInCurrency,
		|
		|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|	THEN ISNULL(PaymentDecryptionTable.AmountARAP, DocumentData.DocumentAmount)
		|	ELSE DocumentData.DocumentAmount END AS AmountInCorCurrency,
		|
		|	CASE WHEN ISNULL(PaymentDecryptionTable.PaymentRequest, VALUE(Document.PaymentRequest.EmptyRef)) = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR PaymentDecryptionTable.PaymentRequest = UNDEFINED THEN
		|		CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
		|		THEN ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount)
		|		ELSE DocumentData.DocumentAmount END
		|	END AS AmountToBePaidAboveLimit,
		|
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	CASE 
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount)
		|			THEN DocumentData.BankAccountBeneficiary
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount)
		|			THEN DocumentData.CashAccountRecipient
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.CurrencyConversion)
		|			THEN UNDEFINED
		|	END AS CorSourceOfFAGOfCash,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN 
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|
		|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmountsInAccountingCurrency
		|			ON PaymentDecryptionTable.RowID = DocumentAmountsInAccountingCurrency.RowID
		|	ON 
		|		TRUE
		|";
	
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		And DocumentObject.PersonsList Then
			
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusiness,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	
		|	TablePersonalAccountsOfEmployees.CashFlowItem AS CashFlowItem,
		|	UNDEFINED AS TargetFundItem,
		|	
		|	DocumentData.Currency AS Currency,
		|
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
		|	TablePersonalAccountsOfEmployees.Individual AS CorCash,
		|
		|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	CAST(TablePersonalAccountsOfEmployees.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(TablePersonalAccountsOfEmployees.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	TablePersonalAccountsOfEmployees.Sum AS AmountInCurrency,
		|	TablePersonalAccountsOfEmployees.Sum AS AmountInCorCurrency,
		|
		|	CASE WHEN NOT DocumentData.PaymentByRequests THEN
		|		TablePersonalAccountsOfEmployees.Sum
		|	END AS AmountToBePaidAboveLimit,
		|
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS CorSourceOfFAGOfCash,
		|	UNDEFINED AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN TablePersonalAccountsOfEmployees AS TablePersonalAccountsOfEmployees
		|	ON TRUE";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits Then
			
		QueryText = "
		|// Deposit payment operations
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusiness,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|
		|	ISNULL(PaymentDecryptionTable.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS CorLineOfBusiness,
		|	PaymentDecryptionTable.LoanDepositContract AS CorCash,
		|	VALUE(Enum.CashTypes.Deposits) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	PaymentDecryptionTable.SumMan AS Sum,
		|	PaymentDecryptionTable.SumCompl AS SumCompl,
		|	PaymentDecryptionTable.Sum AS AmountInCurrency,
		|	PaymentDecryptionTable.Sum AS AmountInCorCurrency,
		|
		|	CASE WHEN ISNULL(PaymentDecryptionTable.PaymentRequest, VALUE(Document.PaymentRequest.EmptyRef)) = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR PaymentDecryptionTable.PaymentRequest = UNDEFINED THEN
		|		PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidAboveLimit,
		|
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	PaymentDecryptionTable.LoanDepositContract AS CorSourceOfFAGOfCash,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN 
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON 
		|		TRUE";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment Then
			
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	UNDEFINED AS Department,
		|	&LineOfBusinessCash AS LineOfBusiness,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	DocumentData.CashFlowItem AS CashFlowItem,
		|	DocumentData.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
		|	DocumentData.AcquiringContract AS CorCash,
		|	VALUE(Enum.CashTypes.BankAcquirerCash) AS CorCashType,
		|	DocumentData.Currency AS CorrespondingCurency,
		|
		|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.DocumentAmount AS AmountInCurrency,
		|	DocumentData.DocumentAmount AS AmountInCorCurrency,
		|	
		|	CASE WHEN ISNULL(PaymentDecryptionTable.PaymentRequest, VALUE(Document.PaymentRequest.EmptyRef)) = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR PaymentDecryptionTable.PaymentRequest = UNDEFINED THEN
		|		PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidAboveLimit,
		|
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS CorSourceOfFAGOfCash,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON TRUE";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.PaymentWithConversion Then
			
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.CurrencyConversion) AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	UNDEFINED AS Department,
		|	&LineOfBusinessCash AS LineOfBusiness,
		|	
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	&CashFlowItem AS CashFlowItem,
		|	DocumentData.TargetFundItem AS TargetFundItem,
		|	DocumentData.BankAccountCashCurrency AS Currency,
		|
		|	&LineOfBusinessCash AS CorLineOfBusiness,
		|	DocumentData.BankAccount AS CorCash,
		|	VALUE(Enum.CashTypes.CashInTransit) AS CorCashType,
		|	DocumentData.BankAccountCashCurrency AS CorrespondingCurency,
		|
		|	CAST(DocumentData.AmountInPayerSCurrency * &ConversionRatioOfFundsIntoManSCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(DocumentData.AmountInPayerSCurrency * &ConversionRatioOfFundsToLocalCurrency AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.AmountInPayerSCurrency AS AmountInCurrency,
		|	DocumentData.AmountInPayerSCurrency AS AmountInCorCurrency,
		|
		|	0 AS AmountToBePaidAboveLimit,
		|
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS CorSourceOfFAGOfCash,
		|	UNDEFINED AS PaymentRequest
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TablePersonalAccountsOfEmployees", QueryTexts) Then
		QueryTextTemporaryTablePersonalAccountsOfEmployees(Query, QueryTexts, DocumentObject);
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
	
	If Not DocumentObject.ProcessedByBank Then
		Return "";
	EndIf;
	
	If Query.Parameters.Property("UsePayroll") Then
		UsePayroll = Query.Parameters.UsePayroll;
	Else
		UsePayroll = Constants.UsePayroll.Get();
	EndIf;
	
	QueryTextArray = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.OtherCashIssue Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	CASE WHEN DocumentData.PaymentWithConversion THEN
		|		&CashCurrency
		|	ELSE
		|		DocumentData.Currency
		|	END AS Currency,
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
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	PaymentDecryptionTable.ExpenseItem AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN 
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON 
		|		TRUE
		|";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions Then
		
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashIssue)
		|		THEN PaymentDecryptionTable.Department
		|		ELSE UNDEFINED
		|	END AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	DocumentData.TaxType AS AssetsLiabilitiesDimension,
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
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	PaymentDecryptionTable.ExpenseItem AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN 
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON 
		|		TRUE
		|";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts)
		And Not UsePayroll Then
		
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	DocumentData.CashFlowItem AS CashFlowItem,
		|	DocumentData.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	&Organization AS AssetsLiabilitiesDimension,
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
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	DocumentData.PaymentRequest AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
	
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment
		And DocumentObject.RecordCommission And DocumentObject.FeeAmount <> 0 Then
		
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.AcquiringFee) AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	DocumentData.Department AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	DocumentData.AcquiringContractCashFlowItemFee AS CashFlowItem,
		|	UNDEFINED,
		|	DocumentData.Currency AS Currency,
		|
		|	DocumentData.AcquiringContractLineOfBusiness AS LineOfBusinessItems,
		|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|
		|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(DocumentData.FeeAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	DocumentData.FeeAmount AS AmountInCurrency,
		|	CASE WHEN DocumentData.PaymentRequest = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR DocumentData.PaymentRequest = UNDEFINED THEN
		|		DocumentData.FeeAmount
		|	END AS AmountToBePaidAboveLimit,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	DocumentData.ExpenseItem AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	DocumentData.PaymentRequest AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData";
	
		QueryTextArray.Add(QueryText);
		
	EndIf;
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts)
		And UsePayroll Then
		
		QueryText = "
		|	SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	&Organization AS AssetsLiabilitiesDimension,
		|
		|	CAST(PaymentDecryptionTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
		|	CAST(PaymentDecryptionTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
		|	PaymentDecryptionTable.Sum AS AmountInCurrency,
		|
		|	CASE WHEN PaymentDecryptionTable.PaymentRequest = VALUE(Document.PaymentRequest.EmptyRef)
		|		OR PaymentDecryptionTable.PaymentRequest = UNDEFINED THEN
		|		PaymentDecryptionTable.Sum
		|	END AS AmountToBePaidAboveLimit,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	CASE WHEN DocumentData.PaymentWithConversion THEN
		|		&CashCurrency
		|	ELSE
		|		DocumentData.Currency
		|	END AS Currency,
		|
		|	ISNULL(PaymentDecryptionTable.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusinessItems,
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
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON TRUE
		|
		|GROUP BY
		|	DocumentData.Date,
		|	DocumentData.Organization,
		|	DocumentData.Department,
		|	DocumentData.BankAccount,
		|	CASE WHEN DocumentData.PaymentWithConversion THEN
		|		&CashCurrency
		|	ELSE
		|		DocumentData.Currency
		|	END,
		|	ISNULL(PaymentDecryptionTable.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)),
		|	PaymentDecryptionTable.LeaseContracts,
		|	PaymentDecryptionTable.Department,
		|	PaymentDecryptionTable.CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem,
		|	PaymentDecryptionTable.PaymentRequest";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	// Issuing loans to an employee
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
		And UsePayroll Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
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
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON TRUE
		|
		|GROUP BY
		|	DocumentData.Date,
		|	DocumentData.Organization,
		|	DocumentData.Department,
		|	DocumentData.BankAccount,
		|	DocumentData.Currency,
		|	PaymentDecryptionTable.CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem,
		|	PaymentDecryptionTable.PaymentRequest";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
		And Not UsePayroll Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	UNDEFINED AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	DocumentData.CashFlowItem AS CashFlowItem,
		|	DocumentData.TargetFundItem AS TargetFundItem,
		|	DocumentData.Currency AS Currency,
		|
		|	UNDEFINED AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings) AS IncomeAndExpenseItem,
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
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	DocumentData.PaymentRequest AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
	
		QueryText = "
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	&LineOfBusinessCash AS LineOfBusinessCash,
		|	PaymentDecryptionTable.Department AS IncomeExpenseBusinessUnit,
		|
		|	DocumentData.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.BankAccountPayments_) AS CashType,
		|	PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|	PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|	CASE WHEN DocumentData.PaymentWithConversion THEN
		|		&CashCurrency
		|	ELSE
		|		DocumentData.Currency
		|	END AS Currency,
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
		|	DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|	UNDEFINED AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	PaymentDecryptionTable.VATRate AS VATRate,
		|	PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN PaymentDecryptionTable AS PaymentDecryptionTable
		|		ON TRUE
		|WHERE
		|	PaymentDecryptionTable.VATAmount <> 0
		|";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	If DocumentObject.PaymentWithConversion Then
	
		QueryText = "
		|// Calculation of income from exchange differences
		|SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain) AS BusinessOperation,
		|	&Organization AS Organization,
		|	TableOfExchangeDifferences.Department AS Department,
		|	&LineOfBusinessCash,
		|	TableOfExchangeDifferences.Department AS IncomeExpenseBusinessUnit,
		|
		|	TableOfExchangeDifferences.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashInTransit) AS CashType,
		|	&CashFlowItem AS CashFlowItem,
		|	&TargetFundItem AS TargetFundItem,
		|	&CashCurrency AS Currency,
		|
		|	&LineOfBusinessCash AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.CurrencyConversionIncome) AS IncomeAndExpenseItem,
		|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfRevenue,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	
		|	TableOfExchangeDifferences.SumMan AS Sum,
		|	TableOfExchangeDifferences.SumCompl AS SumCompl,
		|	TableOfExchangeDifferences.Sum AS AmountInCurrency,
		|
		|	0 AS AmountToBePaidAboveLimit,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|	
		|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.CurrencyConversionIncome) AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	UNDEFINED AS PaymentRequest
		|FROM
		|	TableOfExchangeDifferences AS TableOfExchangeDifferences
		|
		|WHERE
		|	&PaymentWithConversion
		|	AND (TableOfExchangeDifferences.SumMan > 0 OR TableOfExchangeDifferences.SumCompl > 0)
		|
		|UNION ALL
		|
		|// Calculation of expenses from exchange differences
		|SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss) AS BusinessOperation,
		|	&Organization AS Organization,
		|	TableOfExchangeDifferences.Department AS Department,
		|	&LineOfBusinessCash,
		|	TableOfExchangeDifferences.Department AS IncomeExpenseBusinessUnit,
		|
		|	TableOfExchangeDifferences.BankAccount AS Cash,
		|	VALUE(Enum.CashTypes.CashInTransit) AS CashType,
		|	&CashFlowItem AS CashFlowItem,
		|	&TargetFundItem AS TargetFundItem,
		|	&CashCurrency AS Currency,
		|
		|	&LineOfBusinessCash AS LineOfBusinessItems,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.CurrencyConversionExpenses) AS IncomeAndExpenseItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	VALUE(Enum.ExchangeDifferencesDimension.Cash) AS DimensionOfExpenses,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|
		|	-TableOfExchangeDifferences.SumMan AS Sum,
		|	-TableOfExchangeDifferences.SumCompl AS SumCompl,
		|	-TableOfExchangeDifferences.Sum AS AmountInCurrency,
		|
		|	0 AS AmountToBePaidAboveLimit,
		|
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS AmountVATCurrencyPayment,
		|
		|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.CurrencyConversionExpenses) AS SourceOfIncomeExpensesFinancialAccountingGroup,
		|	UNDEFINED AS VATRate,
		|	UNDEFINED AS PaymentRequest
		|
		|FROM
		|	TableOfExchangeDifferences AS TableOfExchangeDifferences
		|
		|WHERE
		|	&PaymentWithConversion
		|	AND (TableOfExchangeDifferences.SumMan < 0 OR TableOfExchangeDifferences.SumCompl < 0)
		|";
		
		QueryTextArray.Add(QueryText);
		
	EndIf;
	
	If QueryTextArray.Count() = 0 Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfExchangeDifferences", QueryTexts) Then
		QueryTextTableOfExchangeDifferences(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCashCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentObject.ProcessedByBank Then
		Return "";
	EndIf;
	
	ArrayOfSubqueryTexts = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment) Then
		
		TextOfQuerySubquery = "// Cash write-off operations
		|	SELECT
		|		&Period AS Period,
		|		&BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		DocumentData.Department AS Department,
		|
		|		DocumentData.BankAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|		CASE WHEN DocumentData.PaymentWithConversion THEN
		|			DocumentData.BankAccountCashCurrency
		|		ELSE
		|			DocumentData.Currency
		|		END AS PaymentCurrency,
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
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate,
		|		PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON TRUE
		|";

		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany) Then
		
		TextOfQuerySubquery = "// Operations for debiting funds to another organization
		|	SELECT
		|		&Period AS Period,
		|		&BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		DocumentData.Department AS Department,
		|
		|		DocumentData.BankAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|		CASE WHEN DocumentData.PaymentWithConversion THEN
		|			DocumentData.BankAccountCashCurrency
		|		ELSE
		|			DocumentData.Currency
		|		END AS PaymentCurrency,
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
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate,
		|		PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON TRUE";
		
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		TextOfQuerySubquery = "// Internal money transfer operations
		|	SELECT
		|		&Period AS Period,
		|		&BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		DocumentData.Department AS Department,
		|
		|		DocumentData.BankAccount AS Cash,
		|		&CashFlowItem AS CashFlowItem,
		|		&TargetFundItem AS TargetFundItem,
		|		CASE WHEN DocumentData.PaymentWithConversion THEN
		|			DocumentData.BankAccountCashCurrency
		|		ELSE
		|			DocumentData.Currency
		|		END AS PaymentCurrency,
		|
		|		UNDEFINED AS Partner,
		|		DocumentData.BankAccountRecipientOwner AS Counterparty,
		|		DocumentData.BankAccountRecipientLineOfBusiness AS LineOfBusiness,
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
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|		UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate,
		|		DocumentData.PaymentRequest AS PaymentRequest
		|
		|	FROM
		|		DocumentDataHeader AS DocumentData";
		
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty) Then
		
		TextOfQuerySubquery = "// Payment transactions on loans and payments on loans issued
		|	SELECT
		|		&Period AS Period,
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
		|		DocumentData.BankAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|		
		|		CASE WHEN DocumentData.PaymentWithConversion THEN
		|			DocumentData.BankAccountCashCurrency
		|		ELSE
		|			DocumentData.Currency
		|		END AS PaymentCurrency,
		|
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Partner AS Partner,
		|		PaymentDecryptionTable.AccountingDimensionByPartners.Counterparty AS Counterparty,
		|		PaymentDecryptionTable.LineOfBusiness AS LineOfBusiness,
		|		PaymentDecryptionTable.LoanDepositContract AS Contract,
		|		UNDEFINED AS ARAPObject,
		|	
		|		PaymentDecryptionTable.SumMan AS PayAmount,
		|		PaymentDecryptionTable.SumCompl AS PaymentAmountLocal,
		|		ISNULL(PaymentDecryptionTable.Sum, DocumentData.DocumentAmount) AS PaymentAmountPaymentCurrency,
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
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.LoanDepositContract AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate,
		|		PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|	ON
		|		TRUE";
		
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany) Then
		
		TextOfQuerySubquery = "// VAT
		|	SELECT
		|		&Period AS Period,
		|		&BusinessOperation AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		DocumentData.Department AS Department,
		|
		|		DocumentData.BankAccount AS Cash,
		|		PaymentDecryptionTable.CashFlowItem AS CashFlowItem,
		|		PaymentDecryptionTable.TargetFundItem AS TargetFundItem,
		|		CASE WHEN DocumentData.PaymentWithConversion THEN
		|			DocumentData.BankAccountCashCurrency
		|		ELSE
		|			DocumentData.Currency
		|		END AS PaymentCurrency,
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
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		PaymentDecryptionTable.VATRate AS VATRate,
		|		PaymentDecryptionTable.PaymentRequest AS PaymentRequest
		|
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON TRUE
		|	WHERE
		|		PaymentDecryptionTable.VATAmount <> 0";
	
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment
		And DocumentObject.FeeAmount <> 0 And DocumentObject.RecordCommission And DocumentObject.ProcessedByBank 
		And DocumentObject.KeepRecordsOfCommissionInARAPAccounting Then
		
		TextOfQuerySubquery = "//Acquiring fees
		|	SELECT
		|		&Period AS Period,
		|		VALUE(Enum.BusinessTransactions.AcquiringFee) AS BusinessOperation,
		|		DocumentData.Organization AS Organization,
		|		DocumentData.Department AS Department,
		|
		|		DocumentData.BankAccount AS Cash,
		|		DocumentData.AcquiringContract.CashFlowItemCommission AS CashFlowItem,
		|		UNDEFINED AS TargetFundItem,
		|		DocumentData.Currency AS PaymentCurrency,
		|
		|		DocumentData.AcquiringContractPartner AS Partner,
		|		DocumentData.CommissionARAPObject.Counterparty AS Counterparty,
		|		DocumentData.CommissionARAPObject.LineOfBusiness AS LineOfBusiness,
		|		DocumentData.CommissionARAPObject.Contract AS Contract,
		|		DocumentData.CommissionARAPObject AS ARAPObject,
		|	
		|		CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
		|		CAST(DocumentData.FeeAmount * &FactorOfConversionToCurrencyOfRegul  AS NUMBER(31,2)) AS PaymentAmountLocal,
		|		DocumentData.FeeAmount AS PaymentAmountPaymentCurrency,
		|
		|		0 AS PostpaymentAmount,
		|		0 AS PostpaymentAmountLocal,
		|		0 AS PaymentAmountInPaymentCurrency,
		|		
		|		0 AS PrepaymentAmountMan,
		|		0 AS PrepaymentAmountLocal,
		|		0 AS PrepaymentAmount,
		|
		|		CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountToBePaidAboveLimit,
		|	
		|		0 AS VATAmount,
		|		0 AS VATAmountCompl,
		|		0 AS AmountVATCurrencyPayment,
		|
		|		DocumentData.Currency AS ARAPCurrency,
		|
		|		DocumentData.FeeAmount AS PaymentAmountInTheSettlementCurrency,
		|		0 AS PostPaymentAmountInARAPCurrency,
		|		0 AS PrepaymentAmountInARAPCurrency,
		|
		|		DocumentData.BankAccount AS SourceOfCashFinancialAccountingGroup,
		|		DocumentData.CommissionARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		UNDEFINED AS VATRate,
		|		UNDEFINED AS PaymentRequest
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|";

		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
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
	|	&LineOfBusinessCash AS LineOfBusinessCash,
	|
	|	DocumentData.Cash AS Cash,
	|	CASE WHEN &PaymentWithConversion THEN
	|		VALUE(Enum.CashTypes.CashInTransit)
	|	ELSE
	|		VALUE(Enum.CashTypes.BankAccountPayments_)
	|	END AS CashType,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.TargetFundItem AS TargetFundItem,
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
	|
	|	DocumentData.VATRate,
	|	DocumentData.PaymentRequest,
	|
	|	FALSE AS DeferredPosting
	|
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
	|	DocumentData.TargetFundItem,
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

Function RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts, DocumentObject)
	
	TempTableName = "TTMovementCounterpartyCounterparty";
	
	If Not DocumentsPosting.ThereIsQueryTable("PaymentDecryptionTable", QueryTexts) Then
		RequestTextTemporaryTablePaymentDecryption(Query, QueryTexts, DocumentObject);
	EndIf;
	
	ArrayOfSubqueryTexts = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment)
		And DocumentObject.ProcessedByBank Then
		
		TextOfQuerySubquery = "// Transferred the branch's debt to the organization
		|	SELECT
		|		&Period AS Period,
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
		|		&LineOfBusinessCash AS CorLineOfBusiness,
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
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON TRUE
		|	WHERE
		|		DocumentData.Organization <> PaymentDecryptionTable.Organization
		|		
		|";
		
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment)
		And DocumentObject.ProcessedByBank Then
		
		TextOfQuerySubquery = "// Repaid the debt of the branch to the supplier
		|	SELECT
		|		&Period AS Period,
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
		|		&LineOfBusinessCash AS LineOfBusiness,
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
		|
		|		PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
		|		PaymentDecryptionTable.AmountARAP AS AmountInARAPCurrency,
		|
		|		PaymentDecryptionTable.ARAPCurrency AS CorCurrencyOfARAPAccounting,
		|		PaymentDecryptionTable.AmountARAP AS AdjAmountInARAPCurrency,
		|
		|		PaymentDecryptionTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
		|		PaymentDecryptionTable.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup
		|	FROM
		|		DocumentDataHeader AS DocumentData
		|	
		|	LEFT JOIN
		|		PaymentDecryptionTable AS PaymentDecryptionTable
		|			ON TRUE
		|	WHERE
		|		DocumentData.Organization <> PaymentDecryptionTable.Organization
		|";
		
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		And DocumentObject.ProcessedByBank Then
		
		TextOfQuerySubquery = "// Refund to the client at the rate of the advance payment
		|	SELECT
		|		&Period AS Period,
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
		
		ArrayOfSubqueryTexts.Add(TextOfQuerySubquery);
		
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
	|		WHEN ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|
	|	DocumentData.CorPartner AS CorPartner,
	|	DocumentData.CorCounterparty AS CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.CorLineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.CorLineOfBusiness
	|	END AS CorLineOfBusiness,
	|	DocumentData.CorContract AS CorContract,
	|	DocumentData.CorARAPObject AS CorARAPObject,
	|	&Currency AS Currency,
	|
	|	SUM(DocumentData.Sum) AS Sum,
	|	SUM(DocumentData.SumCompl) AS SumCompl,
	|	SUM(DocumentData.AmountInCurrency) AS AmountInCurrency,
	|
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	SUM(DocumentData.AmountInARAPCurrency) AS AmountInARAPCurrency,
	|	DocumentData.CorCurrencyOfARAPAccounting AS CorCurrencyOfARAPAccounting,
	|	SUM(DocumentData.AdjAmountInARAPCurrency) AS AdjAmountInARAPCurrency,
	|
	|	DocumentData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.CorSourceOfARAPFinancialAccountingGroup AS CorSourceOfARAPFinancialAccountingGroup
	|INTO TTMovementCounterpartyCounterparty
	|FROM &TheTextOfASubquery AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Period,
	|	DocumentData.BusinessOperation,
	|   DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE)
	|			THEN DocumentData.LineOfBusiness
	|	END,
	|	DocumentData.Contract,
	|	DocumentData.ARAPObject,
	|	DocumentData.CorPartner,
	|	DocumentData.CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.CorLineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.CorLineOfBusiness
	|	END,
	|	DocumentData.CorContract,
	|	DocumentData.CorARAPObject,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.CorCurrencyOfARAPAccounting,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.CorSourceOfARAPFinancialAccountingGroup
	|";
	
	QueryText = StrReplace(QueryText, "&TheTextOfASubquery", "(" + TextOfQuerySubquery + ")");
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentObject.ProcessedByBank Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment) Then
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
	|	RecordsCounterpartyCounterparty.LineOfBusiness       AS LineOfBusiness,
	|
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
	|
	|FROM
	|	TTMovementCounterpartyCounterparty AS RecordsCounterpartyCounterparty
	|";
	
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
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTaxesAndContributions
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToDeposits
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToCounterparty
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram
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
		|	&EmployeeResponsible                          AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&IncomingDocumentDate                 AS SourceDocumentDate,
		|	&IncomingDocumentNumber                AS SourceDocumentNumber,
		|	CASE WHEN &PaymentWithConversion THEN
		|		&AmountInPayerSCurrency
		|	ELSE
		|		&DocumentAmount
		|	END AS Sum,
		|	&CashCurrency                  AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	CASE WHEN &ProcessedByBank THEN
		|		&Period
		|	END AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
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
		|		VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram),
		|		VALUE(Enum.BusinessTransactions.EmptyRef)
		|	)";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined 
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToLessor Then
				
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
		|	&EmployeeResponsible                          AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&IncomingDocumentDate                 AS SourceDocumentDate,
		|	&IncomingDocumentNumber                AS SourceDocumentNumber,
		|	CASE WHEN &PaymentWithConversion THEN
		|		&AmountInPayerSCurrency
		|	ELSE
		|		&DocumentAmount
		|	END AS Sum,
		|	&CashCurrency                  AS Currency,
		|	ISNULL(NestedQuery.LeaseContracts, UNDEFINED) AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	CASE WHEN &ProcessedByBank THEN
		|		&Period
		|	END AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		LEFT JOIN (SELECT
		|			DocumentData.Ref AS Ref,
		|			MAX(PaymentDecryptionTable.LeaseContracts) AS LeaseContracts
		|		FROM
		|			DocumentDataHeader AS DocumentData
		|				INNER JOIN DocumentDataTableDecryptionOfPayment AS PaymentDecryptionTable
		|				ON DocumentData.Ref = PaymentDecryptionTable.Ref
		|					AND (DocumentData.Ref = &Ref)
		|
		|		GROUP BY
		|			DocumentData.Ref
		|
		|		HAVING
		|			COUNT(DISTINCT PaymentDecryptionTable.LeaseContracts) = 1) AS NestedQuery
		|		ON (DocumentData.Ref = NestedQuery.Ref)
		|
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts
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
		|	&EmployeeResponsible                          AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&IncomingDocumentDate                 AS SourceDocumentDate,
		|	&IncomingDocumentNumber                AS SourceDocumentNumber,
		|	CASE WHEN &PaymentWithConversion THEN
		|		&AmountInPayerSCurrency
		|	ELSE
		|		&DocumentAmount
		|	END AS Sum,
		|	&CashCurrency                  AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	CASE WHEN &ProcessedByBank THEN
		|		&Period
		|	ELSE
		|		DATETIME(1,1,1)
		|	END AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder),
		|		VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts),
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
		|	&BankAccount                         AS StorageLocation,
		|	DocumentData.BankAccountRecipientOwner AS Counterparty,
		|	&Department                          AS Department,
		|	&Period                                 AS IBDocumentDate,
		|	&Ref                                 AS Ref,
		
		|	&Number                                  AS IBDocumentNumber,
		|	UNDEFINED                            AS Status,
		|	&EmployeeResponsible                          AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&IncomingDocumentDate                 AS SourceDocumentDate,
		|	&IncomingDocumentNumber                AS SourceDocumentNumber,
		|	CASE WHEN &PaymentWithConversion THEN
		|		&AmountInPayerSCurrency
		|	ELSE
		|		&DocumentAmount
		|	END AS Sum,
		|	&CashCurrency                  AS Currency,
		|	&Contract                                AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	CASE WHEN &ProcessedByBank THEN
		|		&Period
		|	ELSE
		|		DATETIME(1,1,1)
		|	END AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
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
		|	&EmployeeResponsible                          AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&IncomingDocumentDate                 AS SourceDocumentDate,
		|	&IncomingDocumentNumber                AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	UNDEFINED                            AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	CASE WHEN &ProcessedByBank THEN
		|		&Period
		|	ELSE
		|		DATETIME(1,1,1)
		|	END AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
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
		|	&EmployeeResponsible                          AS EmployeeResponsible,
		|	&Author                                  AS Author,
		|	FALSE                                    AS AdditionalRecord,
		|	&PaymentPurposes                      AS More,
		|	&Comment                            AS Comment,
		|	&Posted                               AS Posted,
		|	&DeletionMark                        AS DeletionMark,
		|	&IncomingDocumentDate                 AS SourceDocumentDate,
		|	&IncomingDocumentNumber                AS SourceDocumentNumber,
		|	&DocumentAmount                         AS Sum,
		|	&Currency                                 AS Currency,
		|	DocumentData.AcquiringContract       AS Contract,
		|	&LineOfBusiness                AS LineOfBusiness,
		|	&Patch                            AS ReverseTransactionCorrection,
		|	&ReversedDocument                   AS ReversedDocument,
		|	&CorrectedDocument                   AS CorrectedDocument,
		|	CASE WHEN &ProcessedByBank THEN
		|		&Period
		|	END AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND &BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.RefundAcquiringPayment)
		|	)";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If DocumentObject <> Undefined And ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.BankAccountIssue");
		QueryText = StrReplace(QueryText, "DocumentData.BankAccountRecipientOwner", "DocumentData.BankAccountBeneficiary.Owner");
		QueryText = StrReplace(QueryText, "DocumentDataTableDecryptionOfPayment", "Document.BankAccountIssue.ARAPDetails");
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
	
	ArrayOfRequestTexts = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalaryPaymentToBankAccounts
		And GetFunctionalOption("PayrollAndHumanResourcesWE") Then
	
		QueryText = "
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	&EndOfDayPeriod AS Period,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.AdvanceHolder AS Individual,
		|	DocumentData.Department AS Department,
		|	VALUE(Catalog.TypesOfEmployeeCompensations.Payroll) AS ARAPType,
		|	ARAPDetails.Sum AS Sum,
		|	CAST(ARAPDetails.Sum * &ConversionRateToManCurrency AS NUMBER(31, 2)) AS SumMan,
		|	CAST(ARAPDetails.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31, 2)) AS SumCompl,
		|	ARAPDetails.Sum AS AmountToBePaid,
		|	&BusinessOperation AS BusinessOperation,
		|	CASE
		|		WHEN DocumentData.ProcessedByBank
		|			THEN ARAPDetails.RowID
		|		ELSE &IDOfUnusedFinRecord
		|	END AS FinRecordID,
		|	CASE
		|		WHEN NOT DocumentData.ProcessedByBank
		|			THEN UNDEFINED
		|		ELSE VALUE(Catalog.BusinessTransactionsSettings.SalaryPaymentToBankAccounts)
		|	END AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		INNER JOIN Document.BankAccountIssue.ARAPDetails AS ARAPDetails
		|		ON DocumentData.Ref = ARAPDetails.Ref
		|WHERE
		|	DocumentData.ProcessedByBank";
		
		ArrayOfRequestTexts.Add(QueryText);
	
	EndIf;
	
	If ArrayOfRequestTexts.Count() = 0 Then
		Return "";
	EndIf;

	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
//-- WE
Function QueryTextTableDocumentPostingInFinancialAccounting(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TableOfCalculationObjects", QueryTexts) Then
		RequestTextTemporaryTableOfCalculationObjects(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT DISTINCT
	|	NestedQuery.Period AS Period,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.DateRecord AS DateRecord
	|FROM
	|	(SELECT
	|		&Period                         AS Period,
	|		&Organization                    AS Organization,
	|		BEGINOFPERIOD(&Period, DAY)    AS DateRecord
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		&Period                             AS Period,
	|		TableOfCalculationObjects.Organization AS Organization,
	|		BEGINOFPERIOD(&Period, DAY)        AS DateRecord
	|	FROM
	|		TableOfCalculationObjects AS TableOfCalculationObjects
	|	WHERE
	|		TableOfCalculationObjects.Organization <> &Organization
	|
	|	) NestedQuery
	|";
	QueryText = QueryText + "UNION ALL"
		+ IncomeAndExpensesServer.AddRequestTextToTableReflectionOfDocumentsInLocalAccounting();
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
Function CashFlowArticleOfDocument(DocumentData)
	
	If DocumentData.PaymentWithConversion Then
		CashFlowItem = DocumentData.CashFlowItemConversion;
	Else
		If ValueIsFilled(DocumentData.CashFlowItem) Then
			CashFlowItem = DocumentData.CashFlowItem;
		Else
			CashFlowItem = Catalogs.CashFlowReportItems.PredefinedCFItem(
				DocumentData.BusinessOperation, DocumentData.Currency);
		EndIf;
	EndIf;
	
	Return CashFlowItem;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment) Then
		Return;
	EndIf;
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN BEGINOFPERIOD(DocumentDataHeader.Date, DAY) = DocumentDataHeader.BankPostingDate
		|		OR NOT DocumentDataHeader.ProcessedByBank
		|			THEN DocumentDataHeader.Date
		|		ELSE ENDOFPERIOD(DocumentDataHeader.BankPostingDate, DAY)
		|	END AS DateOfCourse,
		|	ARAPObjects.Ref AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON Table.Ref = ARAPObjects.Object
		|				AND Table.ARAPObjectOfPaymentPartner = ARAPObjects.Partner
		|				AND Table.ARAPCurrency = ARAPObjects.ARAPCurrency
		|				AND NOT ARAPObjects.DeletionMark
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN BEGINOFPERIOD(DocumentDataHeader.Date, DAY) = DocumentDataHeader.BankPostingDate
		|		OR NOT DocumentDataHeader.ProcessedByBank
		|			THEN DocumentDataHeader.Date
		|		ELSE ENDOFPERIOD(DocumentDataHeader.BankPostingDate, DAY)
		|	END AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN BEGINOFPERIOD(DocumentDataHeader.Date, DAY) = DocumentDataHeader.BankPostingDate
		|		OR NOT DocumentDataHeader.ProcessedByBank
		|			THEN DocumentDataHeader.Date
		|		ELSE ENDOFPERIOD(DocumentDataHeader.BankPostingDate, DAY)
		|	END AS DateOfCourse,
		|	ARAPObjects.Ref AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON Table.Ref = ARAPObjects.Object
		|				AND Table.ARAPObjectOfPaymentPartner = ARAPObjects.Partner
		|				AND Table.ARAPCurrency = ARAPObjects.ARAPCurrency
		|				AND NOT ARAPObjects.DeletionMark
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN NOT DocumentDataHeader.ProcessedByBank
		|		OR BEGINOFPERIOD(DocumentDataHeader.Date, DAY) = DocumentDataHeader.BankPostingDate
		|			THEN DocumentDataHeader.Date
		|		ELSE ENDOFPERIOD(DocumentDataHeader.BankPostingDate, DAY)
		|	END AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN NOT DocumentDataHeader.ProcessedByBank
		|		OR BEGINOFPERIOD(DocumentDataHeader.Date, DAY) = DocumentDataHeader.BankPostingDate
		|			THEN DocumentDataHeader.Date
		|		ELSE ENDOFPERIOD(DocumentDataHeader.BankPostingDate, DAY)
		|	END AS DateOfCourse,
		|	DocumentDataHeader.CommissionARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	DocumentDataHeader AS DocumentDataHeader
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
		|	Table.Ref                                                           AS Ref,
		|	Document.Organization                                                     AS Organization,
		|	CASE WHEN Document.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
		|			THEN VALUE(Catalog.Partners.OurEnterprise)
		|		WHEN &ThereIsGiftCertificate = TRUE
		|			THEN &Partner
		|		ELSE Table.Partner
		|	END                                                                    AS Partner,
		|	SettlementObjectPayment.Ref                                              AS ARAPObject,
		|	
		|	Table.ARAPCurrency                                             AS ARAPCurrency,
		|	CASE WHEN Document.ProcessedByBank 
		|		THEN Table.AmountARAP
		|		ELSE 0
		|	END                                                                    AS AmountARAP,
		|	Document.Currency                                                          AS DocumentCurrency,
		|	CASE WHEN Document.ProcessedByBank 
		|		THEN Table.Sum
		|		ELSE 0
		|	END                                                                    AS Sum,
		|	CASE 
		|		WHEN NOT Document.ProcessedByBank
		|				AND NOT (Document.PaymentByRequests 
		|					AND &UsePaymentRequests
		|					AND Table.PaymentRequestToControlPaymentOfPaymentOfARAPObject)
		|			THEN Table.AmountARAP 
		|		ELSE 0 
		|	END                                                                    AS BeingPaid,
		|	
		|	Document.BusinessOperation                                           AS BusinessOperation,
		|	CASE WHEN BEGINOFPERIOD(Document.Date, DAY) = Document.BankPostingDate
		|		OR NOT Document.ProcessedByBank
		|		OR Document.Patch
		|			THEN Document.Date
		|		ELSE ENDOFPERIOD(Document.BankPostingDate, DAY)
		|	END                                                                    AS RecorderDate,
		|	Document.Number                                                           AS RecorderNumber,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                           AS PaymentMethod,
		|	CASE WHEN BEGINOFPERIOD(Document.Date, DAY) = Document.BankPostingDate 
		|		OR NOT Document.ProcessedByBank
		|			THEN Document.Date
		|		ELSE ENDOFPERIOD(Document.BankPostingDate, DAY)
		|	END                                                                    AS DateOfCourse,
		|	Table.CashFlowItem                                    AS CashFlowItem,
		|	Table.PaymentRequest                              AS PaymentRequest,
		|	Table.RowID                                              AS FinRecordID,
		|	&BusinessTransactionSetting                                          AS BusinessTransactionSetting
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS Document
		|			ON Document.Ref = Table.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS SettlementObjectPayment
		|			ON Table.Ref = SettlementObjectPayment.Object
		|				AND Table.ARAPObjectOfPaymentPartner = SettlementObjectPayment.Partner
		|				AND Table.ARAPCurrency = SettlementObjectPayment.ARAPCurrency
		|				AND NOT SettlementObjectPayment.DeletionMark
		|";
	
	EndIf;

	#EndRegion
	
	#Region ReduceTextIsPaidToClient
	
	ReduceTextIsPaidToClient = "";
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany) Then
			
	ReduceTextIsPaidToClient = "
		|SELECT
		|	Table.Ref                                                          AS Ref,
		|	Document.Organization                                                    AS Organization,
		|	CASE WHEN Document.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToAnotherCompany)
		|			THEN VALUE(Catalog.Partners.OurEnterprise)
		|		WHEN &ThereIsGiftCertificate = TRUE
		|			THEN &Partner
		|		ELSE Document.Partner
		|	END                                                                   AS Partner,
		|	Table.ARAPObject                                                  AS ARAPObject,
		|	Table.ARAPCurrency                                            AS ARAPCurrency,
		|
		|	Table.AmountARAP                                             AS IncreaseIsPaid,
		|
		|	Document.BusinessOperation                                          AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                          AS PaymentMethod,
		|	Table.CashFlowItem                                   AS CashFlowItem,
		|	Table.PaymentRequest                             AS PaymentRequest,
		|	Document.Currency                                                         AS DocumentCurrency,
		|	CASE WHEN BEGINOFPERIOD(Document.Date, DAY) = Document.BankPostingDate
		|		OR NOT Document.ProcessedByBank
		|		OR Document.Patch
		|			THEN Document.Date
		|		ELSE ENDOFPERIOD(Document.BankPostingDate, DAY)
		|	END                                                                   AS RecorderDate,
		|	Document.Number                                                          AS RecorderNumber
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS Document
		|			ON Document.Ref = Table.Ref
		|WHERE
		|	Document.ProcessedByBank
		|	AND Document.PaymentByRequests 
		|	AND &UsePaymentRequests 
		|	AND Table.PaymentRequestToControlPaymentOfPaymentOfARAPObject
		|";
	
	EndIf;
	
	#EndRegion
	
	#Region DebtTransfer_
	
	TextDebtTransfer = "";
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany)
		And DocumentObject.ProcessedByBank Then
			
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
		|	ARAPObjects.Ref                                     AS CalculationObjectSource,
		|	
		|	Table.ARAPCurrency                               AS ARAPCurrency,
		|	Document.Currency                                            AS DocumentCurrency,
		|	Table.AmountARAP                                AS AmountARAP,
		|	Table.Sum                                              AS Sum,
		|	
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment) AS BusinessOperation,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)             AS PaymentMethod,
		|	Document.Number                                             AS RecorderNumber,
		|	CASE WHEN BEGINOFPERIOD(Document.Date, DAY) = Document.BankPostingDate 
		|		OR NOT Document.ProcessedByBank
		|		OR Document.Patch THEN
		|		Document.Date
		|	ELSE
		|		ENDOFPERIOD(Document.BankPostingDate, DAY)
		|	END                                                      AS RecorderDate,
		|	CASE WHEN BEGINOFPERIOD(Document.Date, DAY) = Document.BankPostingDate
		|		OR NOT Document.ProcessedByBank
		|			THEN Document.Date
		|		ELSE ENDOFPERIOD(Document.BankPostingDate, DAY)
		|	END                                                      AS DateOfCourse,
		|	Table.CashFlowItem                      AS CashFlowItem,
		|	Table.PaymentRequest                AS PaymentRequest,
		|	Table.RowID                                AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment) AS BusinessTransactionSetting
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS Document
		|			ON Document.Ref = Table.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS SettlementObjectPayment
		|			ON Table.Ref = SettlementObjectPayment.Object
		|				AND Table.ARAPObjectOfPaymentPartner = SettlementObjectPayment.Partner
		|				AND Table.ARAPCurrency = SettlementObjectPayment.ARAPCurrency
		|				AND NOT SettlementObjectPayment.DeletionMark
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects 
		|			ON Table.ARAPObject = ARAPObjects.Ref
		|";
	
	EndIf;
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.MakingRefundToClient(Query, QueryTexts, Registers, TextReturn,
		TextDebtTransfer, ReduceTextIsPaidToClient);
	
	#EndRegion
	
	#Region VendorsARAPAccounting
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.CustomsPayment) Then
			
	TextPayment = "
		|SELECT
		|	Table.Ref                                                 AS Ref,
		|	Document.Organization                                           AS Organization,
		|	CASE WHEN Document.BusinessOperation = VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
		|		THEN VALUE(Catalog.Partners.OurEnterprise)
		|		ELSE Table.Partner
		|	END                                                         AS Partner,
		|	CASE WHEN NOT Document.ProcessedByBank
		|		OR BEGINOFPERIOD(Document.Date, DAY) = Document.BankPostingDate
		|		OR Document.Patch THEN
		|		Document.Date
		|	ELSE
		|		ENDOFPERIOD(Document.BankPostingDate, DAY)
		|	END                                                          AS RecorderDate,
		|	Document.Number                                                 AS RecorderNumber,
		|	
		|	Table.ARAPCurrency                                   AS ARAPCurrency,
		|	Table.ARAPObject                                         AS ARAPObject,
		|	CASE 
		|		WHEN Document.ProcessedByBank 
		|			THEN Table.Sum 
		|		ELSE 0 
		|	END                                                          AS Sum,
		|	CASE 
		|		WHEN Document.ProcessedByBank 
		|			THEN Table.AmountARAP 
		|		ELSE 0 
		|	END                                                          AS AmountARAP,
		|	CASE 
		|		WHEN Document.ProcessedByBank
		|				AND Document.PaymentByRequests 
		|				AND &UsePaymentRequests 
		|				AND Table.PaymentRequestToControlPaymentOfPaymentOfARAPObject
		|			THEN Table.AmountARAP 
		|		ELSE 0 
		|	END                                                          AS ReductionIsPaid,
		|	CASE 
		|		WHEN NOT Document.ProcessedByBank
		|				AND NOT (Document.PaymentByRequests 
		|						AND &UsePaymentRequests 
		|						AND Table.PaymentRequestToControlPaymentOfPaymentOfARAPObject)
		|			THEN Table.AmountARAP 
		|		ELSE 0 
		|	END                                                          AS IncreaseIsPaid,
		|	0                                                              AS SumMan,
		|	0                                                              AS SumCompl,
		|
		|	Document.BusinessOperation                                 AS BusinessOperation,
		|	Table.CashFlowItem                          AS CashFlowItem,
		|	Table.PaymentRequest                    AS PaymentRequest,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                 AS PaymentMethod,
		|	Document.Currency                                                AS DocumentCurrency,
		|	CASE WHEN NOT Document.ProcessedByBank
		|		OR BEGINOFPERIOD(Document.Date, DAY) = Document.BankPostingDate 
		|			THEN Document.Date
		|		ELSE ENDOFPERIOD(Document.BankPostingDate, DAY)
		|	END                                                          AS DateOfCourse,
		|	Table.MaturityDate                                          AS MaturityDate,
		|	UNDEFINED                                                   AS LinkedDocument,
		|	Table.RowID                                    AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS Document
		|			ON Document.Ref = Table.Ref
		|";
	
		MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.RefundAcquiringPayment
		And DocumentObject.FeeAmount <> 0 And DocumentObject.RecordCommission And DocumentObject.ProcessedByBank 
		And DocumentObject.KeepRecordsOfCommissionInARAPAccounting Then
	
		TextPayment = "
		|SELECT
		|	DocumentData.Ref                                           AS Ref,
		|	DocumentData.Organization                                      AS Organization,
		|	DocumentData.AcquiringContractPartner                         AS Partner,
		|	CASE WHEN NOT DocumentData.ProcessedByBank
		|		OR BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentData.BankPostingDate
		|		OR DocumentData.Patch THEN
		|		DocumentData.Date
		|	ELSE
		|		ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
		|	END                                                            AS RecorderDate,
		|	DocumentData.Number                                            AS RecorderNumber,
		|	
		|	DocumentData.CommissionARAPObject                           AS ARAPObject,
		|	DocumentData.Currency                                           AS ARAPCurrency,
		|
		|	DocumentData.FeeAmount                                    AS Sum,
		|	DocumentData.FeeAmount                                    AS AmountARAP,
		|	0                                                                AS ReductionIsPaid,
		|	0                                                                AS IncreaseIsPaid,
		|	0                                                                AS SumMan,
		|	0                                                                AS SumCompl,
		|
		|	VALUE(Enum.BusinessTransactions.AcquiringFee)  AS BusinessOperation,
		|	DocumentData.AcquiringContractCashFlowItemFee AS CashFlowItem,
		|	UNDEFINED                                                       AS PaymentRequest,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                     AS PaymentMethod,
		|	DocumentData.Currency                                             AS DocumentCurrency,
		|	CASE WHEN NOT DocumentData.ProcessedByBank
		|		OR BEGINOFPERIOD(DocumentData.Date, DAY) = DocumentData.BankPostingDate 
		|			THEN DocumentData.Date
		|		ELSE ENDOFPERIOD(DocumentData.BankPostingDate, DAY)
		|	END                                                              AS DateOfCourse,
		|	DATETIME(1,1,1)                                                   AS MaturityDate,
		|	UNDEFINED                                                       AS LinkedDocument,
		|	DocumentData.DocumentID                             AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.AcquiringFee) AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS DocumentData
		|";
		
		MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment);
		
	EndIf;
	
	#EndRegion
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	// Bank details
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PaymentDetails";
	PrintCommand.Presentation = NStr("vi = 'Chi tiết thanh toán quốc tế';
									|ru = 'Реквизиты международного платежа';
									|en = 'Bank details'; fa = 'جزئیات بانکی';
									|it = 'Requisiti del pagamento internazionale';
									|pl = 'Atrybuty płatności międzynarodowej';
									|tr = 'Uluslararası ödeme bilgileri'");
	PrintCommand.CheckPostingBeforePrint = True;

	BankAccountIssueLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PaymentDetails") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"PaymentDetails",
			NStr("vi = 'Thông tin tài khoản ngân hàng';
				|ru = 'Банковские реквизиты';
				|en = 'Bank details'; fa = 'جزئیات بانکی';
				|it = 'Coordinate bancarie';
				|pl = 'Dane bankowe';
				|tr = 'Banka bilgileri'"),
			GeneratePaymentDetails(ObjectsArray, PrintObjects),
			,
			"Document.BankAccountIssue.PF_MXL_PaymentDetails");
	EndIf;
	BankAccountIssueLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
EndProcedure

Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Counterparty";
	ArrayOfRecipientDetails = PrintObjectDataStructure.ArrayOfRecipientDetails; // Array
	
	ArrayOfRecipientDetails.Add("Counterparty");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		ArrayOfRecipientDetails.Add("ARAPDetails.Partner");
	EndIf;
	
EndProcedure

Function GeneratePaymentDetails(ObjectsArray, PrintObjects)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_BankAccountIssue_PaymentDetails";
	Template = PrintManagement.PrintFormTemplate("Document.BankAccountIssue.PF_MXL_PaymentDetails");
	
	RefsTable = New ValueTable;
	RefsTable.Columns.Add("Ref",
		New TypeDescription("DocumentRef.BankAccountIssue, DocumentRef.PaymentRequest"));
	For Indus = 1 To ObjectsArray.Count() Do
		RefsTable.Add();
	EndDo;
	RefsTable.LoadColumn(ObjectsArray, "Ref");
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	RefsTable.Ref AS Ref
	|INTO
	|	PaymentOrders
	|FROM
	|	&RefsTable AS RefsTable
	|WHERE
	|	RefsTable.Ref REFS Document.BankAccountIssue
	|	OR RefsTable.Ref REFS Document.PaymentRequest
	|;"
		+ DataProcessors.EDIWithBanks.RequestTextPaymentOrdersThirdParties() + "UNION ALL"
		+ DataProcessors.EDIWithBanks.RequestTextPaymentOrdersInternal() + "UNION ALL"
		+ DataProcessors.EDIWithBanks.RequestTextPaymentOrdersTransfers()
	;
	Query.SetParameter("RefsTable", RefsTable);
	RFPaymentsSupport = GetFunctionalOption("RFPaymentsSupport");
	Query.SetParameter("RFPaymentsSupport", RFPaymentsSupport);
	
	QueryFields = New Array;
	QueryFields.Add("Ref");
	QueryFields.Add("Sum");
	QueryFields.Add("Currency");
	QueryFields.Add("Number");
	QueryFields.Add("Date");
	QueryFields.Add("PaymentPurposes");
	QueryFields.Add("CounterpartyNameInternational");
	QueryFields.Add("CounterpartyAddressInternational");
	QueryFields.Add("CounterpartyBankAccount_");
	QueryFields.Add("CounterpartyToAccountIsIBAN");
	QueryFields.Add("CounterpartyBankInternational");
	QueryFields.Add("CounterpartyBankAddressInternational");
	QueryFields.Add("SwiftBankCounterparty");
	QueryFields.Add("CounterpartyBankBIC");
	QueryFields.Add("CounterpartyCorrespondentBankAccount");
	QueryFields.Add("CounterpartyBankForSettlementsInternational");
	QueryFields.Add("CounterpartyBankAddressForSettlementsInternational");
	QueryFields.Add("SWIFTBankCounterpartyForSettlements");
	QueryFields.Add("CounterpartyOfBankSBICForSettlements");
	QueryFields.Add("CompanyNameInternational");
	QueryFields.Add("OrganizationAddressInternational");
	QueryFields.Add("CompanyBankAccount_");
	QueryFields.Add("OrganizationAndAccountAreIBAN");
	QueryFields.Add("CompanyBankInternational");
	QueryFields.Add("OrganizationBankAddressInternational");
	QueryFields.Add("SwiftBankCompany");
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(Query.Text);
	
	SelectionRequest = QuerySchema.QueryBatch[1]; // QuerySchemaSelectQuery
	TotalColumns = SelectionRequest.Columns.Count() - 1;
	For Indus = 0 To TotalColumns Do
		Column = SelectionRequest.Columns.Get(TotalColumns - Indus);
		If QueryFields.Find(Column.Alias) = Undefined Then
			SelectionRequest.Columns.Delete(TotalColumns - Indus);
		EndIf;
	EndDo;
	
	Query.Text = QuerySchema.GetQueryText();
	
	If TypeOf(ObjectsArray[0]) = Type("DocumentRef.PaymentRequest") Then
		Query.Text = StrReplace(Query.Text, "BankAccountIssue", "PaymentRequest");
		Query.Text = StrReplace(Query.Text, "DocumentData.IncomingDocumentDate", "DocumentData.RequiredPaymentDate");
	Else
		Query.Text = StrReplace(Query.Text, "DocumentData.Date  ", "ISNULL(DocumentData.CorrectedDocument.Date, DocumentData.Date)  ");
		Query.Text = StrReplace(Query.Text, "DocumentData.Number  ", "ISNULL(DocumentData.CorrectedDocument.Number, DocumentData.Number)  ");
	EndIf;
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		TemplateArea = Template.GetArea("Attributes");
		TemplateArea.Parameters.Fill(Selection);
		
		TemplateArea.Parameters.PaymentAmount = Format(Selection.Sum, "NFD=2") + " " + String(Selection.Currency);
		
		If TypeOf(Selection.Ref) = Type("DocumentRef.BankAccountIssue") Then
			TemplateArea.Parameters.Document = StrTemplate(NStr("vi = 'Mục thanh toán';
																|ru = 'Реквизиты платежа';
																|en = 'Payment details'; fa = 'جزئیات پرداخت';
																|it = 'Requisiti di pagamento';
																|pl = 'Szczegóły płatności';
																|tr = 'Ödeme bilgileri'", Common.DefaultLanguageCode()) 
				+ " №%1 " + NStr("vi = 'ngày';
								|ru = 'от';
								|en = 'dated'; fa = 'مورخ';
								|it = 'del';
								|pl = 'dated';
								|tr = 'tarih'", Common.DefaultLanguageCode()) + " %2",
				ObjectsPrefixesClientServer.NumberForPrinting(Selection.Number), Format(Selection.Date, "DLF=D"));
		Else
			TemplateArea.Parameters.Document = NStr("vi = 'Mục thanh toán';
													|ru = 'Реквизиты платежа';
													|en = 'Payment details'; fa = 'جزئیات پرداخت';
													|it = 'Requisiti di pagamento';
													|pl = 'Szczegóły płatności';
													|tr = 'Ödeme bilgileri'", Common.DefaultLanguageCode());
		EndIf;
		
		If Selection.OrganizationAndAccountAreIBAN = True Then
			TemplateArea.Parameters.PresentationOfOrganizationSAccount = "IBAN"
		Else
			TemplateArea.Parameters.PresentationOfOrganizationSAccount = NStr("vi = 'Số tài khoản';
																				|ru = 'Номер счета';
																				|en = 'Account number'; fa = 'شماره حساب';
																				|it = 'Numero del conto corrente';
																				|pl = 'Numer rachunku';
																				|tr = 'Hesap numarası'");
		EndIf;
		
		If Selection.CounterpartyToAccountIsIBAN = True Then
			TemplateArea.Parameters.PresentationOfRecipientSAccount = "IBAN"
		Else
			TemplateArea.Parameters.PresentationOfRecipientSAccount = NStr("vi = 'Số tài khoản';
																			|ru = 'Номер счета';
																			|en = 'Account number'; fa = 'شماره حساب';
																			|it = 'Numero del conto corrente';
																			|pl = 'Numer rachunku';
																			|tr = 'Hesap numarası'");
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		SpreadsheetDocument.PutHorizontalPageBreak();
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			Selection.Ref);
	EndDo;
	
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

// Adds the command to create the document "Write off non-cash DS".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
Function AddCreateBasedOnCommissionReportCommand_Remuneration(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.BankAccountIssue) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.WriteOffOfNonCashCashTransactionsBasedOnCommissionReport_Remuneration";
		CreateBasedOnCommand.Id = "WriteOffOfNonCashCashTransactionsBasedOnCommissionReport_Remuneration";
		CreateBasedOnCommand.Presentation =
			TMCommonUse.ObjectPresentation(Metadata.Documents.BankAccountIssue)
			+ " " + NStr("vi = 'người đặt ký gửi (thù lao cho đại lý hoa hồng)';
						|ru = 'комитента (вознаграждение комиссионеру)';
						|en = 'consignor (remuneration to consignee)'; fa = 'consignor (remuneration to consignee)';
						|it = 'del committente (compenso dell''agente commissionario)';
						|pl = 'komitenta (wynagrodzenie komisanta)';
						|tr = 'temsilci (komisyon temsilcisinin ücreti)'");
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// The function searches for mirror document Postuplenie for operations between Organizations (of Intercompany).
//
// Parameters:
//	DocumentUnderReview - DocumentRef.BankAccountIssue, DocumentObject.BankAccountIssue - 
//	                      The document for which you need to find a mirror document of the receipt of the BDS.
//
// Returns:
//	DocumentRef.BankAccountReceiptNote, Undefined - Mirrored payment or Undefined if the document is not found.
//
Function FindMirrorPayment(DocumentUnderReview) Export
	
	MirrorPayment = Undefined;
	
	If Common.RefTypeValue(DocumentUnderReview) Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	BankAccountReceiptNote.Ref
		|FROM
		|	Document.BankAccountReceiptNote AS BankAccountReceiptNote
		|		INNER JOIN Document.BankAccountIssue AS BankAccountIssue
		|ON 
		|	BankAccountReceiptNote.BankAccount = BankAccountIssue.BankAccountBeneficiary
		|	AND BankAccountReceiptNote.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
		|	AND BankAccountReceiptNote.Currency = BankAccountIssue.Currency
		|	AND BankAccountReceiptNote.IncomingDocumentDate = BankAccountIssue.IncomingDocumentDate
		|	AND BankAccountReceiptNote.IncomingDocumentNumber = BankAccountIssue.IncomingDocumentNumber
		|	AND BankAccountReceiptNote.SenderBankAccount = BankAccountIssue.BankAccount
		|	AND BankAccountReceiptNote.DocumentAmount = BankAccountIssue.DocumentAmount
		|WHERE
		|	BankAccountIssue.Ref = &DocumentRef
		|";
		
		Query.SetParameter("DocumentRef", DocumentUnderReview);
		
	Else
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	BankAccountReceiptNote.Ref
		|FROM
		|	Document.BankAccountReceiptNote AS BankAccountReceiptNote
		|WHERE 
		|	BankAccountReceiptNote.BankAccount = &BankAccount
		|	AND BankAccountReceiptNote.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
		|	AND BankAccountReceiptNote.Currency = &Currency
		|	AND BankAccountReceiptNote.IncomingDocumentDate = &IncomingDocumentDate
		|	AND BankAccountReceiptNote.IncomingDocumentNumber = &IncomingDocumentNumber
		|	AND BankAccountReceiptNote.SenderBankAccount = &SenderBankAccount
		|	AND BankAccountReceiptNote.DocumentAmount = &DocumentAmount
		|";
		
		Query.SetParameter("BankAccount",				DocumentUnderReview.BankAccountBeneficiary);
		Query.SetParameter("Currency",						DocumentUnderReview.Currency);
		Query.SetParameter("IncomingDocumentDate",		DocumentUnderReview.IncomingDocumentDate);
		Query.SetParameter("IncomingDocumentNumber",	DocumentUnderReview.IncomingDocumentNumber);
		Query.SetParameter("SenderBankAccount",	DocumentUnderReview.BankAccount);
		Query.SetParameter("DocumentAmount",				DocumentUnderReview.DocumentAmount);
		
	EndIf;
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	If Selection.Next() And Selection.Count() = 1 Then
		MirrorPayment = Selection.Ref;
	EndIf;
	
	Return MirrorPayment;
	
EndFunction

// Verifies that the transcripts of the payment in the mirror Postuplenii,
// for operations between Organizations (of Intercompany).
//
// Parameters:
//	DocumentRef - DocumentRef.BankAccountIssue - Write-off document
//  InvertedPaymentReference - DocumentRef.BankAccountReceiptNote - Receipt document
//
// Returns:
//  Boolean - Payment compliance indication
Function CorrespondsToInvertedPayment(DocumentRef, InvertedPaymentReference) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	TRUE AS ThereAreDifferences_
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN
	|				ReceiptOfBDSDecryption.ARAPObject.Object = &NoncashReceipt THEN
	|					UNDEFINED
	|			ELSE
	|				ReceiptOfBDSDecryption.ARAPObject.Object
	|		END AS ARAPObject,
	|		ReceiptOfBDSDecryption.ARAPCurrency AS ARAPCurrency,
	|		SUM(ReceiptOfBDSDecryption.Sum) AS AmountReceived_,
	|		SUM(ReceiptOfBDSDecryption.AmountARAP) AS AmountOfSettlementsReceipt,
	|		SUM(0) AS AmountDebited,
	|		SUM(0) AS AmountOfSettlementsWriteOff,
	|		ReceiptOfBDSDecryption.Ref.BankAccount AS BankAccountReceipt,
	|		ReceiptOfBDSDecryption.Ref.SenderBankAccount AS BankAccountSenderReceipt,
	|		ReceiptOfBDSDecryption.Ref.IncomingDocumentDate AS DateOfIncomingDocumentReceipt,
	|		ReceiptOfBDSDecryption.Ref.IncomingDocumentNumber AS IncomingDocumentNumberReceipt,
	|		NULL AS BankAccountRecipientDebiting,
	|		NULL AS BankAccountDebiting,
	|		NULL AS DateOfIncomingDocumentDebited,
	|		NULL AS NumberOfIncomingDebitingDocument
	|	FROM
	|		Document.BankAccountReceiptNote.ARAPDetails AS ReceiptOfBDSDecryption
	|	WHERE
	|		ReceiptOfBDSDecryption.Ref = &NoncashReceipt
	|		AND ReceiptOfBDSDecryption.ARAPObject.Object <> &NoncashReceipt
	|	
	|	GROUP BY
	|		ReceiptOfBDSDecryption.ARAPCurrency,
	|		CASE
	|			WHEN
	|				ReceiptOfBDSDecryption.ARAPObject.Object = &NoncashReceipt THEN
	|					UNDEFINED
	|			ELSE
	|				ReceiptOfBDSDecryption.ARAPObject.Object
	|		END,
	|		ReceiptOfBDSDecryption.Ref.BankAccount,
	|		ReceiptOfBDSDecryption.Ref.SenderBankAccount,
	|		ReceiptOfBDSDecryption.Ref.IncomingDocumentDate,
	|		ReceiptOfBDSDecryption.Ref.IncomingDocumentNumber
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE
	|			WHEN
	|				BankAccountIssueARAPDetails.ARAPObject.Object = &DebitingBDS THEN
	|					UNDEFINED
	|			ELSE
	|				BankAccountIssueARAPDetails.ARAPObject.Object
	|		END AS ARAPObject,
	|		BankAccountIssueARAPDetails.ARAPCurrency,
	|		0,
	|		0,
	|		SUM(BankAccountIssueARAPDetails.Sum),
	|		SUM(BankAccountIssueARAPDetails.AmountARAP),
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		BankAccountIssueARAPDetails.Ref.BankAccountBeneficiary,
	|		BankAccountIssueARAPDetails.Ref.BankAccount,
	|		BankAccountIssueARAPDetails.Ref.IncomingDocumentDate,
	|		BankAccountIssueARAPDetails.Ref.IncomingDocumentNumber
	|	FROM
	|		Document.BankAccountIssue.ARAPDetails AS BankAccountIssueARAPDetails
	|	WHERE
	|		BankAccountIssueARAPDetails.Ref = &DebitingBDS
	|		AND BankAccountIssueARAPDetails.ARAPObject.Object <> &DebitingBDS
	|	
	|	GROUP BY
	|		CASE
	|			WHEN
	|				BankAccountIssueARAPDetails.ARAPObject.Object = &DebitingBDS THEN
	|					UNDEFINED
	|			ELSE
	|				BankAccountIssueARAPDetails.ARAPObject.Object
	|		END,
	|		BankAccountIssueARAPDetails.ARAPCurrency,
	|		BankAccountIssueARAPDetails.Ref.BankAccount,
	|		BankAccountIssueARAPDetails.Ref.IncomingDocumentDate,
	|		BankAccountIssueARAPDetails.Ref.IncomingDocumentNumber,
	|		BankAccountIssueARAPDetails.Ref.BankAccountBeneficiary) AS DecryptionReceiptWriteOff
	|
	|GROUP BY
	|	DecryptionReceiptWriteOff.ARAPObject,
	|	DecryptionReceiptWriteOff.ARAPCurrency
	|
	|HAVING
	|	(SUM(DecryptionReceiptWriteOff.AmountReceived_) <> SUM(DecryptionReceiptWriteOff.AmountDebited)
	|		OR SUM(DecryptionReceiptWriteOff.AmountOfSettlementsReceipt) <> SUM(DecryptionReceiptWriteOff.AmountOfSettlementsWriteOff)
	|		OR MAX(DecryptionReceiptWriteOff.BankAccountReceipt) <> MAX(DecryptionReceiptWriteOff.BankAccountRecipientDebiting)
	|		OR MAX(DecryptionReceiptWriteOff.BankAccountSenderReceipt) <> MAX(DecryptionReceiptWriteOff.BankAccountDebiting)
	|		OR MAX(DecryptionReceiptWriteOff.DateOfIncomingDocumentReceipt) <> MAX(DecryptionReceiptWriteOff.DateOfIncomingDocumentDebited)
	|		OR MAX(DecryptionReceiptWriteOff.IncomingDocumentNumberReceipt) <> MAX(DecryptionReceiptWriteOff.NumberOfIncomingDebitingDocument))
	|";
	
	Query.SetParameter("NoncashReceipt", InvertedPaymentReference);
	Query.SetParameter("DebitingBDS", DocumentRef);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Return Not Selection.Next();
	
EndFunction

// Aligning the mirror Postuplenii,
// for operations between Organizations (of Intercompany).
//
// Parameters:
//    DocumentRef - DocumentRef.BankAccountIssue - Write-off document
//    MirrorPaymentObject - DocumentObject.BankAccountReceiptNote - Receipt document
//
// Returns:
//  Boolean - A sign of the success of the operation
Function AlignMirrorPayment(DocumentRef, MirrorPaymentObject) Export
	
	Attributes = New Structure("ARAPDetails, DocumentAmount, BankAccountBeneficiary,
		|BankAccount,IncomingDocumentDate, IncomingDocumentNumber, BusinessOperation");
	Attributes = Common.ObjectAttributesValues(DocumentRef, Attributes);
	
	MirrorPaymentObject.DocumentAmount = Attributes.DocumentAmount;
	MirrorPaymentObject.BankAccount = Attributes.BankAccountBeneficiary;
	MirrorPaymentObject.SenderBankAccount = Attributes.BankAccount;
	MirrorPaymentObject.IncomingDocumentDate= Attributes.IncomingDocumentDate;
	MirrorPaymentObject.IncomingDocumentNumber= Attributes.IncomingDocumentNumber;
	
	ARAPDetails = Attributes.ARAPDetails.Unload();
	DecryptionOfPaymentMirrored = MirrorPaymentObject.ARAPDetails;
	
	If ARAPDetails.Count() = 1 And DecryptionOfPaymentMirrored.Count() = 1 Then
		FillPropertyValues(DecryptionOfPaymentMirrored[0], ARAPDetails[0], "ARAPObject, Sum, AmountARAP, ARAPCurrency");
		If Common.ObjectAttributeValue(ARAPDetails[0].ARAPObject,"Object") = DocumentRef Then
			DecryptionOfPaymentMirrored[0].ARAPObject = Catalogs.ARAPObjects.EmptyRef();
		EndIf; 
		Return True;
	EndIf;
	
	DefaultArticle = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Attributes.BusinessOperation);
	If Not ValueIsFilled(DefaultArticle) Then
		ArrayOfArticles = DecryptionOfPaymentMirrored.UnloadColumn("CashFlowItem");
		ArrayOfArticles = CommonClientServer.CollapseArray(ArrayOfArticles);
		If ArrayOfArticles.Count() = 1 Then
			DefaultArticle = ArrayOfArticles[0];
		EndIf;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	ARAPObjects.Ref AS ARAPObject,
	|	SUM(ARAPDetails.Sum) AS Sum,
	|	SUM(ARAPDetails.AmountARAP) AS AmountARAP,
	|	ARAPDetails.ARAPCurrency AS ARAPCurrency,
	|	CASE
	|		WHEN ARAPDetails.ARAPObject.Object REFS Document.CustomerInvoiceIntercompany
	|				OR ARAPDetails.ARAPObject.Object REFS Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany
	|				OR ARAPDetails.ARAPObject.Object REFS Document.CommissionReportIntercompany
	|			THEN CASE
	|					WHEN ARAPDetails.ARAPObject.Contract = VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|							OR ARAPDetails.ARAPObject.Contract.CashFlowItemOfRecipient = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|						THEN &DefaultArticle
	|					ELSE ARAPDetails.ARAPObject.Contract.CashFlowItemOfRecipient
	|				END
	|		ELSE &DefaultArticle
	|	END AS CashFlowItem,
	|	ARAPDetails.ARAPObject.Object AS PaymentPurpose
	|FROM
	|	Document.BankAccountIssue.ARAPDetails AS ARAPDetails
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON ARAPDetails.ARAPObject.Object = ARAPObjects.Object
	|				AND ARAPDetails.ARAPObject <> ARAPObjects.Ref
	|				AND ARAPDetails.ARAPObject.Organization <> ARAPObjects.Organization
	|				AND ARAPDetails.ARAPObject.PaymentType_ <> ARAPObjects.PaymentType_
	|				AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	ARAPDetails.Ref = &Ref
	|
	|GROUP BY
	|	ARAPDetails.ARAPCurrency,
	|	ARAPObjects.Ref,
	|	CASE
	|		WHEN ARAPDetails.ARAPObject.Object REFS Document.CustomerInvoiceIntercompany
	|				OR ARAPDetails.ARAPObject.Object REFS Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany
	|				OR ARAPDetails.ARAPObject.Object REFS Document.CommissionReportIntercompany
	|			THEN CASE
	|					WHEN ARAPDetails.ARAPObject.Contract = VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|							OR ARAPDetails.ARAPObject.Contract.CashFlowItemOfRecipient = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|						THEN &DefaultArticle
	|					ELSE ARAPDetails.ARAPObject.Contract.CashFlowItemOfRecipient
	|				END
	|		ELSE &DefaultArticle
	|	END,
	|	ARAPDetails.ARAPObject.Object");
	
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("DefaultArticle",DefaultArticle);
	
	SetPrivilegedMode(True);
	DecryptionResult = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	For Each Page1 In DecryptionResult Do
		If Not ValueIsFilled(Page1.CashFlowItem) Then
			CommonClientServer.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 không khớp, 
					|không thể điền dạng lưu chuyển tiền tệ theo diễn giải thanh toán.';
					|ru = 'Не приведено в соответствие %1, 
					|не удалось заполнить статьи движения дс в расшифровке платежа.';
					|en = 'Not adjusted %1. 
					|Cannot fill in cash flow items in the payment details.'; fa = 'Not adjusted %1. 
					|Cannot fill in cash flow items in the payment details.';
					|it = 'Non è reso conforme %1, 
					|non è stato possibile compilare le voci di movimento dei mezzi finanziari nella trascrizione del pagamento.';
					|pl = 'Nie uzgodniono %1, 
					| nie udało się wypełnić pozycji przepływu środków pieniężnych w szczegółach płatności';
					|tr = '%1uyumlu değil, 
					| ödeme dökümünde nakit hareket kalemi doldurulamadı.'"), MirrorPaymentObject.Ref));
			Return False;
		EndIf;
	EndDo;
	
	MirrorPaymentObject.ARAPDetails.Load(DecryptionResult);
	
	Return True;
	
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
	|	BusinessTransactionsSettings.BusinessOperation IN (CASE
	|				WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard)
	|					THEN VALUE(Enum.BusinessTransactions.AcquiringFee)
	|			END, CASE
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
	|			END, VALUE(Enum.BusinessTransactions.CurrencyConversion), VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeGain), VALUE(Enum.BusinessTransactions.ExchangeDifferencesForCashExchangeLoss))
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
	|	AccumulationRegister.BankAccountCash AS DataTable
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
			|			Document.BankAccountIssue AS DocumentData
			|				LEFT JOIN Document.BankAccountIssue.ARAPDetails AS PaymentDecryptionTable
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
	NameOfExpenseRegister = Metadata.AccumulationRegisters.BankAccountCash.Name;
	DocumentKind = Common.MetadataObjectID(Metadata.Documents.BankAccountIssue);
	
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
				|				Document.BankAccountIssue.ARAPDetails AS ARAPDetails
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
