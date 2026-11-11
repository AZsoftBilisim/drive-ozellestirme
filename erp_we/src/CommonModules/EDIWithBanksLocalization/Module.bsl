
#Region Public

// Called when opening the organization's Bank Account form.
// Allows you to add additional exchange formats.
// When adding a new exchange format, the following procedures will be called:
// - when unloading: clientbanklocalization.Unload Payments
// - when downloading: clientbanklocalization.Upload payments.
// 
// Parameters:
// 	ExchangeFormats - Array of String
// 
//@skip-warning Implemented partner if necessary.
Procedure WhenFillingExchangeFormats(ExchangeFormats) Export
	
EndProcedure

// Uploads payments according to the passed parameters
// 
// Parameters:
//      DocumentsTable - ValueTable - table for the tabular part of the document processing upload ClientBank:
//      * ExportDate - Date - date of the previous upload.
//      * ToExport - Boolean - the upload flag.
//      * Number - String - payment document number.
//      * Date - Date - date of the payment document.
//      * Sum - DefinedType.MonetaryAmountPositiveNegative - the amount of the payment document.
//      * Currency - CatalogRef.Currencies - currency of the payment document.
//      * PaymentPurposes - String - purpose of payment.
//      * Counterparty - CatalogRef.Companies, CatalogRef.Counterparties, CatalogRef.Persons - Contractor.
//      * Operation - EnumRef.BusinessTransactions - operation.
//      * Organization - CatalogRef.Companies - Organization.
//      * BankAccount - CatalogRef.CompaniesBankAccounts - bank account.
//      * Comment - String - comment.
//      * DocumentKind - EnumRef.TypesOfPaymentDocuments - type of document.
//      * Ref - DocumentRef.BankAccountIssue, DocumentRef.BankAccountReceiptNote - link to the payment document.
//      * ErrorsDescription - String - description of errors.
//      * Code - String - code.
//      * BCCode - String - BC code.
//      * RNCPSRNCMTCode - String - OKATO code.
//      * CounterpartyBank - String - The counterparty's bank.
//      * CounterpartyBankPaymentProcessingCentre - String - name of the bank.
//      * CounterpartyBankForPayments - String - bank for settlements (counterparty).
//      * CounterpartyBankForPaymentsPaymentProcessingCentre - String - name of the bank for settlements.
//      * CounterpartyBankBIC - String - BIC of the counterparty's bank.
//      * CounterpartyBankBICProcessingCentre - String - BIC RC bank.
//      * CityOfCounterpartyBank - String - the city of the counterparty's bank.
//      * CityOfBankSC - String - the city of the bank's RC.
//      * CounterpartyTIN - DefinedType.TIN - INN of the counterparty.
//      * CounterpartyCorrBankAccount - String - correspondent account of the counterparty's bank.
//      * CorrAccountOfBankSC - String - correspondent account of the RC Bank.
//      * CounterpartyWorkName - The counterparty line is short.
//      * CounterpartyBankAccount_ - String - Counterparty's current account.
//      * PayerCRTR - String - Payer's checkpoint.
//      * RecipientCRTR - String - Recipient's checkpoint.
//      * CompanyBank - String - The bank of the organization.
//      * CompanyBankNameCSC - String - name of the bank.
//      * CompanyBankForPayments - String - The bank for the organization's settlements.
//      * CompanyTransferBankNameCSC - String - name of the bank.
//      * CompanyBankBIC - String - The organization's bank BIC.
//      * CompanyBankBICProcessingCentre - String - The BIC of the organization's bank's RC.
//      * CompanyCityOfBank - String - the organization's bank's city.
//      * CompanyCityOfBankSC - String - the city of the organization's bank's RC.
//      * CompanyTIN - DefinedType.TIN - INN of the organization.
//      * CompanyAccount - String - organization's account.
//      * CompanyCorrAccountOfBankSC - String - correspondent account of the organization's RC bank
//      * CompanyBankAccount_ - String - organization's current account
//      * CompanyHiring - String - name of the organization.
//      * CounterpartyName - String - name of the counterparty.
//      * RankingInPriorityOfPayment - Number - The order of payment.
//      * DateIndicator - String - date indicator.
//      * NumberIndicator - String - number indicator.
//      * BasisIndicator - String - the base indicator.
//      * PeriodIndicator - String - period indicator.
//      * TypeIndicator - String - type indicator.
//      * AuthorStatus - String - The Status of the originator.
//      * TransferOfTaxesAndContributions - Boolean - indicates the transfer to the budget.
//      * LegalEntityIndividual - EnumRef.LegalEntityIndividual - a legal entity or an individual.
//      * EDStatus - EnumRef.StatesOfEDIDocuments - The State of the version of the electronic document for the specified object of the information base.
//      * HasError - Boolean - there are mistakes.
//      * PaymentKind - String - type of payment.
//      * IncomeKindCode String - code of the type of income.
//      * PaymentCode - String - payout code.
//      * SwiftBankCompany - String - International Bank Identification Code (SWIFT BIC).
//      * CompanyNameInternational - String - international name of the organization.
//      * CompanyBankInternational - String - the international name of the bank in Latin.
//      * BankAccountOfIBANCompany - Boolean - this is an IBAN account.
//      * TransferFeeType - EnumRef.TypesOfBankFeesForTransfers - the method of charging a bank commission for the transfer.
//      * ISOCurrencyCode_ - String - ISO currency.
//      * SwiftBankCounterparty - String - International Bank Identification Code (SWIFT BIC).
//      * CounterpartyBankInternational - String - the international name of the bank in Latin.
//      * CounterpartyBankCityInternational - String - the city of the counterparty's bank.
//      * CounterpartySBankAccountIBAN - Boolean - this is an IBAN account.
//      * CounterpartyNameInternational - String - international name of the counterparty.
//      * PersonalAccount - String - personal account of treasury support.
//      ExchangeFormat - String - the value of the format from the Exchange form filling().
//        An example of the implementation of the Clientbank Processing manager module in the Unload Payment METHODISO20022 procedure.
//     
//     FileBinaryData - BinaryData - a file containing payment documents uploaded to the bank. 
//
//@skip-warning Implemented partner if necessary.
Procedure UploadDocumentsToFile(DocumentsTable, ExchangeFormat, FileBinaryData) Export
	
EndProcedure

// Reads the extract data from the file.
// 
// Parameters:
//     FileBinaryData - BinaryData - file data
//     ExchangeFormat - String - the name of the format from the procedure for filling in the exchange form
//     StatementData - Structure - the returned statement data, contains the fields:
//      * Title - See CashServer.StatementTitle
//      * SettlementAccounts - Array of Structure - See CashClientServer.CurrentAccountData_;
//      * StatementDocuments - Array of Structure - See CashServer.LoadedOperationData;
//      * ParsingErrors - Array of String - errors in parsing the extract file
//
//@skip-warning Implemented partner if necessary.
Procedure ReadExtractFromFile(FileBinaryData, ExchangeFormat, StatementData) Export
	
EndProcedure

#EndRegion

#Region Internal

// Marks payments that will not be included in the download based on the statement.
// 
// Parameters:
//  LinesToLoad - Array of ValueTableRow - list of lines to check.
//  AccountAttributes - See Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails.
//
Procedure MarkPaymentsThatAreNotUploaded(LinesToLoad, AccountAttributes) Export

	
	Return;

EndProcedure

// Fills in the details of the payment counterparty in the statement
//
// Parameters:
//  Outgoing - Boolean - indicates an outgoing payment.
//  PaymentLine_1 - ValueTableRow, Structure - payment details.
//  NameOfCounterparty - String - the name of the counterparty in the statement.
//
Procedure FillInDetailsOfPaymentCounterparty(Outgoing, PaymentLine_1, NameOfCounterparty) Export

	
	Return;

EndProcedure

// Recognizes the statement payment data.
// 
// Parameters:
//  DocumentsToImport - ValueTable - list of payment lines to recognize.
//  BankAccount - CatalogRef.CompaniesBankAccounts - downloadable bank account.
//  AccountAttributes - See Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails.
//  ImportSettings - Structure - the set parameters for uploading the statement.
//
Procedure PrepareStatementLines(DocumentsToImport, BankAccount, AccountAttributes, ImportSettings) Export

	
	Return;

EndProcedure

// Returns the flag for using an online payment service Operation.
// 
// Parameters:
//  OperationOfPayment - String - payment Operation.
// 
// Returns:
//  Boolean - Indicates whether the old value has been updated.
//
Function ThisIsPaymentOperationThroughOnlineService(OperationOfPayment) Export

	Result = False;

	
	Return Result;

EndFunction

// Fills in the Attributes of the payer in the document "Write-off of non-cash Cash".
// 
// Parameters:
//  DocumentObject - DocumentObject.BankAccountIssue - The document to be filled in.
//  DataOfPayment - Structure - Payment Details
//
Procedure FillInPayerSAttributes(DocumentObject, DataOfPayment) Export

	
	Return;

EndProcedure

// Sets the payment without request checkbox in the payment document.
// 
// Parameters:
//  DocumentObject - DocumentObject.BankAccountIssue - A document that does not require payment on request.
//
Procedure AllowPaymentWithoutRequest(DocumentObject) Export

	
	Return;

EndProcedure

// Fills in the Attributes for debiting the payment from the statement.
// 
// Parameters:
//  DocumentLine - ValueTableRow - recognized payment string.
//  DocumentObject - DocumentObject.BankAccountIssue - the write-off document.
//  AvailableCashFlowArticles - Array of CatalogRef.CashFlowReportItems - available items for Registering Recorded funds for selection.
//
Procedure FillInDebitDetails(DocumentLine, DocumentObject, AvailableCashFlowArticles) Export

	
	Return;

EndProcedure

// Fills in the Attributes of payment receipt from the statement.
// 
// Parameters:
//  DocumentLine - ValueTableRow - recognized payment string.
//  DocumentObject - DocumentObject.BankAccountReceiptNote - Receipt document.
//
Procedure FillInReceiptDetails(DocumentLine, DocumentObject) Export

	
	Return;

EndProcedure

// Fills in the commission amount of the receipt document.
// 
// Parameters:
//  DocumentLine - ValueTableRow - recognized payment string.
//  DocumentObject - DocumentObject.BankAccountReceiptNote - document filling in the commission amount.
//  ContractDetails_ - Structure - Contract data.
//
Procedure FillInCommissionAmount(DocumentLine, DocumentObject, ContractDetails_) Export

	
	Return;

EndProcedure

Procedure FillInArticleOfTargetFundsOfDecryptionOfPayment(DocumentLine, DecryptionString) Export

	
	Return;

EndProcedure

// Launches of operation to fill in information about the counterparty from the 1C service:Counterparty.
// 
// Parameters:
//  Counterparty - CatalogRef.Counterparties - a newly created counterparty for which a long-term Operation is launched.
//  CounterpartyData - Structure - source data of the counterparty.
//  Date - Date - The date on which information about the counterparty will be requested.
//
Procedure StartFillingInCounterpartyData(Counterparty, CounterpartyData, Date) Export

	
	Return;

EndProcedure

// Adds a line to the table part "Payment decryption" for the settlement object.
// 
// Parameters:
//  DataOfPayment - ValueTableRow - data of the recognized payment.
//  DocumentObject - DocumentObject.BankAccountIssue - Filling document.
//  DataOfCalculationObject - ValueTableRow - data of the calculation object according to the Balance table.
//  Parameters - Structure - Parameters for filling in the table part.
//
Procedure AddLineToDecryptPaymentForSettlementObject(DataOfPayment, DocumentObject, DataOfCalculationObject, Parameters) Export

	
	DecryptionString = DocumentObject.ARAPDetails.Add();
	EDIWithBanksServer.FillInLineOfPaymentDecryptionForSettlementObject(
		DecryptionString, DataOfPayment, DocumentObject, DataOfCalculationObject, Parameters);
	FillInArticleOfTargetFundsOfDecryptionOfPayment(DataOfPayment, DecryptionString);
	
EndProcedure

// Adds a line to the table part "Payment decryption" for the settlement object.
// 
// Parameters:
//  DataOfPayment - ValueTableRow - data of the recognized payment.
//  DocumentObject - DocumentObject.BankAccountIssue, DocumentObject.BankAccountReceiptNote - Filling document.
//  Parameters - Structure - Parameters for filling in the table part.
//
Procedure AddLineToDecryptPaymentByPayment(DataOfPayment, DocumentObject, Parameters) Export


		EDIWithBanksServer.SetProperty(DocumentObject, "Contract", DataOfPayment.Contract);
	
	DecryptionString = DocumentObject.ARAPDetails.Add();
	EDIWithBanksServer.FillInLineOfDecryptionOfPaymentForPayment(
		DecryptionString, DataOfPayment, DocumentObject, Parameters);
	FillInArticleOfTargetFundsOfDecryptionOfPayment(DataOfPayment, DecryptionString);
	
EndProcedure

Procedure FillInCurrencyOfOperationCode(DocumentObject) Export

	
	Return;

EndProcedure

// Returns a list of item numbers specified in the payment destination.
// 
// Parameters:
//  PaymentPurposes - String - payment destination string.
// 
// Returns:
//  Array of String - Numbers of settlement objects.
//
Function PaymentDestinationSettlementObjects(PaymentPurposes) Export

	ListOfRooms = New Array;
	
	
	Return ListOfRooms;

EndFunction

// Returns an indication of whether the payment object number being checked is in the payment destination line.
// 
// Parameters:
//  PaymentPurposes - String - payment destination string.
//  ListOfRooms - Array of String - The numbers of the objects selected from the payment destination line.
//  DocumentNumber - String - The verified number of the settlement object.
// 
// Returns:
//  Boolean - indicates whether the calculation object has a number in the destination.
//
Function ThereIsCalculationObjectInAssignment(PaymentPurposes, ListOfRooms, DocumentNumber) Export

	Result = StrOccurrenceCount(PaymentPurposes, DocumentNumber) > 0;
	
	
	Return Result;

EndFunction

// Adds settings for filling in the payment decryption.
// 
// Parameters:
//  ImportSettings - Structure - general settings for uploading a statement.
//  FillParameters - Structure - settings for filling in the payment transcript:
//  *AmountToDistribute - Number - the amount for distribution.
//
Procedure AddParametersForFillingInDecryption(ImportSettings, FillParameters) Export

	
	Return;

EndProcedure

// Fills in the payment with self-employed attribute for the payment line from the statement for the settlement object
//
// Parameters:
//  DocumentsToImport - ValueTable - The table of documents in the statement.
//
Procedure SetCalculationAttributeWithSelfEmployedByCalculationObject(DocumentsToImport) Export

	
	Return;

EndProcedure

// Fills in the business of operation of the payment, defined by the purpose of the payment as the fee of the bank.
// 
// Parameters:
//  Organization - CatalogRef.Companies - the owner of the account where the statement is being uploaded.
//  BankAccount - CatalogRef.CounterpartyBankAccounts - The bank account that the statement is uploaded to.
//  ListOfBankFeePayments - Array of ValueTableRow - payments with the type of bank fee.
Procedure FillInBankSFeeTransaction(Organization, BankAccount, ListOfBankFeePayments) Export

	
	Return;

EndProcedure

// Returns the sign of the GOZ account
//
// Parameters:
//  Account - CatalogRef.CompaniesBankAccounts - bank account for verification.
// 
// Returns:
//  Boolean - the sign of the GOZ account.
//
Function ThisIsAccountOfGOZ(Account) Export

	Result = False;
	
	
	Return Result;

EndFunction

// Fills in payment data if UIP = IGK GOZ.
// 
// Parameters:
//  Outgoing - Boolean - Outgoing payment.
//  BankAccount - CatalogRef.CompaniesBankAccounts - bank account.
//  DocumentsToImport - ValueTable - table of documents to upload.
//  ListOfUIPS - ValueTable - List of UIPS.
Procedure FillInPaymentsForUploadingStateBudgetForUIP(Outgoing, BankAccount, DocumentsToImport, ListOfUIPS) Export
	
	
EndProcedure


#EndRegion

#Region Private


#EndRegion
