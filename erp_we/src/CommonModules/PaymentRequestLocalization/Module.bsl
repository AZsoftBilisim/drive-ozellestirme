
#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

#EndRegion

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure Posting(Object, Cancel, PostingMode) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array of String - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure UndoPosting(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure BeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  CopiedObject - DocumentObject.PaymentRequest - The source document that is the copy source.
//
Procedure OnCopy(Object, CopiedObject) Export
	
	
EndProcedure

#EndRegion

#Region AttachableCommands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
EndProcedure

// Adds a command of creation of the document "expense report".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Procedure AddGenerateCommand(GenerationCommands) Export


EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
EndProcedure

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	
EndProcedure

#EndRegion

// Fills in the payment ID for the SBP payment link in the payment request.
// 
// Parameters:
//  DocumentObject - DocumentObject.PaymentRequest - Request for payment.
//  PaymentURL - String - SBP payment link.
//
Procedure FillInPaymentIdForPaymentLinkSBP(DocumentObject, PaymentURL) Export

	
	Return;

EndProcedure
 
#EndRegion

#Region Internal

// Adds the available Forms of payment to the list.
// 
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
//
Procedure SupplementAvailableFormsOfPayment(Form) Export

	
	Return;

EndProcedure

#Region InstantPayments

// Fill in the payment link and the payment ID of the SBP based on the document.
//
// Parameters:
//  FillingData - Structure - Data for filling in the document.
//  DocumentsList - Array of DocumentRef, DocumentRef - the documents are the grounds.
//  AmountToPay - Number - Amount due via the payment link.
//
Procedure FillInPaymentLinkBasedOn(FillingData, DocumentsList, AmountToPay) Export


EndProcedure

// Returns the payment attribute without the possibility of using SBP.
// 
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - business transaction of the payment document.
//  PaymentWithConversion - Boolean - indicates a payment with conversion.
//  CounterpartyKind - EnumRef.LegalEntityIndividual - type of counterparty.
// 
// Returns:
//  Boolean
Function ThisIsPaymentOperationWithoutSBP(BusinessOperation, PaymentWithConversion, CounterpartyKind) Export

	Return BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee
		Or BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived
		Or BusinessOperation = Enums.BusinessTransactions.CurrencyConversion
		Or PaymentWithConversion
		Or CounterpartyKind = Enums.LegalEntityIndividual.Person;

EndFunction


#EndRegion

#Region DetailsOfRecipient

// Returns data about the recipient of funds, depending on the type of business transaction.
//
// Parameters:
//   Object - DocumentRef.PaymentRequest, FormDataStructure - application document
//
// Returns:
//   Structure:
//     * Recipient - CatalogRef.Persons, CatalogRef.Counterparties, CatalogRef.Companies, Undefined - recipient of funds
//     * RecipientAccount - CatalogRef.CompaniesBankAccounts, CatalogRef.CounterpartyBankAccounts, Undefined - Recipient's bank account
//     * LawSubject - EnumRef.LegalEntityIndividual - attribute of a legal entity or individual
//
Function DataOfRecipientOfBusinessOfOperation(Object) Export

	Result = New Structure;
	Result.Insert("Recipient", Undefined);
	Result.Insert("RecipientAccount", Undefined);
	Result.Insert("LawSubject", Enums.LegalEntityIndividual.EmptyRef());
	
	// Recipient - individual
	If (Object.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashIssueAsLoanToEmployee)
		And Not Object.TransferToEmployeeViaABank
		And Not Object.PersonsList Then
		
		Result.Recipient = Object.AdvanceHolder;
		Result.LawSubject = Enums.LegalEntityIndividual.Person;
		Result.RecipientAccount = Object.CounterpartyBankAccount;
	
	// Recipient - undefined (there is no recipient field on the form)
	ElsIf (Object.PersonsList
		Or Object.PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentToBankAccounts)
		And Not Object.TransferToEmployeeViaABank Then
		
		Result.Recipient = Undefined;
		Result.LawSubject = Enums.LegalEntityIndividual.EmptyRef();
		Result.RecipientAccount = Undefined;
	
	// Recipient - company
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices Then
		
		Result.Recipient = Object.CompanyRecipient; // CatalogRef.Companies
		Result.LawSubject = Common.ObjectAttributeValue(Result.Recipient, "LegalEntityIndividual");
		Result.RecipientAccount = Object.BankAccountBeneficiary;
		
	ElsIf Object.PayrollTransaction = Enums.BusinessTransactions.SalaryPaymentViaCashAccount Then
		
		AttributesValues = Common.ObjectAttributesValues(Object.CashAccount, "Owner, Owner.LegalEntityIndividual");
		Result.Recipient = AttributesValues.Owner;
		Result.LawSubject = AttributesValues.OwnerOfLegalEntityIsNaturalPerson;
		Result.RecipientAccount = Undefined;
		
	// Recipient - counterparty
	Else
		
		Result.Recipient = Object.Counterparty; //CatalogRef.Counterparties
		Result.LawSubject = Common.ObjectAttributeValue(Result.Recipient, "LegalEntityIndividual");
		Result.RecipientAccount = Object.CounterpartyBankAccount;
		
	EndIf;
	
	Return Result;

EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure AddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure

#EndRegion

#Region Other
#EndRegion

#EndRegion
