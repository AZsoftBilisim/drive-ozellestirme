
#Region Public

// Creates payment documents, or generates fill-in data for creating a single payment document.
//
// Parameters:
//    GraphLines - Array - The keys of the records of the schedule of payments
//    DocumentType - String - Type of documents to create. If omitted, it will be detected automatically.
//
// Returns:
//    Structure:
//        Open helpform-Boolean-Indicates whether the document creation assistant form needs to be opened
//        Document creation-Structure - data for filling in a single document
//        Long operation-Structure - a Long operation for creating multiple documents
//        Adressstrokgrafika-String-the Address of the temporary storage that contains the paid lines of the schedule.
//
Function PayChartLines(GraphLines, DocumentType) Export
	
	Return Undefined;
	
EndFunction

// Forms variants of the name of a legal entity in accordance with its organizational and legal form.
//
// Parameters:
//    Description - String - Name of the legal entity.
//
// Returns:
//    Structure - Name, work name, full name.
//
Function CompanyName(Val Description) Export
	
	Description = TrimAll(Description);
	
	NameStructure_1 = New Structure("Description, NameAbbreviated, FullDescr",
		Description, Description, Description);
	
	
	Return NameStructure_1;
	
EndFunction

// The function gets the currency corresponding to the Bank account number.
// The 6-8 digits of the Bank account number correspond to the currency code.
// The code 810 is used for rubles.
//
// Parameters:
//	AccountNumber - Number - Bank account number.
//
// Returns:
//	CatalogRef.Currencies - The currency of the bank account.
//
Function GetCurrencyByAccountNumber(AccountNumber) Export
	
	Currency = Catalogs.Currencies.EmptyRef();
	
	
	Return Currency;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn.
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export


EndProcedure

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn.
//
Procedure SetDescriptionOfAttributesOfPurchaseToBeFilledInBasedOnStatistics(AttributesDetails1) Export


EndProcedure

// List of business of operations available for the foundation document.
//
// Parameters:
//  DocumentBasis - DocumentRef, CatalogRef - the basis on which the document was created.
//  TransactionList - ValueList of EnumRef.BusinessTransactions, Undefined - available of operations by base.
//
Procedure GetAvailableBusinessOfOperationsBasedOn(DocumentBasis, TransactionList = Undefined) Export
	
	If TransactionList = Undefined Then
		TransactionList = New ValueList;
	EndIf;
	
	
EndProcedure

// The procedure checks the possibility of correspondence between the bank accounts specified in the Contract
//
// Parameters:
//  ObjectAgreement - CatalogObject - Contract for which you need to receive possible correspondence
//  Cancel         - Boolean - Indicates that you don't want to continue working.
//
Procedure CheckContractForPossibilityOfCorrespondenceWithDigitalRubleAccount(ObjectAgreement, Cancel) Export
	
	CorrespondenceParameters =
		ParametersOfCorrespondenceWithDigitalRubleAccount(ObjectAgreement.BankAccount,
		                                               ObjectAgreement.CounterpartyBankAccount);
	
	If Not CorrespondenceParameters.CorrespondenceWithDigitalRubleAccountIsAllowed Then
		
		NameOfPositioningElement =
			?(CorrespondenceParameters.CorrespondentAccountOfDigitalRuble, "BankAccount", "CounterpartyBankAccount");
		
		ErrorText = NStr("vi = 'Расчетный счет не может корреспондировать со счетом цифрового рубля.
		                         |Укажите другой счет';
		                         |ru = 'Расчетный счет не может корреспондировать со счетом цифрового рубля.
		                         |Укажите другой счет';
		                         |en = 'The current account cannot correspond with the digital ruble account.
		                         |Specify another account'; fa = 'The current account cannot correspond with the digital ruble account.
		                         |Specify another account';
		                         |it = 'Расчетный счет не может корреспондировать со счетом цифрового рубля.
		                         |Укажите другой счет';
		                         |pl = 'The current account cannot correspond with the digital ruble account.
		                         |Specify another account';
		                         |tr = 'Расчетный счет не может корреспондировать со счетом цифрового рубля.
		                         |Укажите другой счет'");
			
		Common.MessageToUser(
			ErrorText,
			ObjectAgreement,
			NameOfPositioningElement,
			,
			Cancel);
		
	EndIf;
	
EndProcedure

// The function determines:
//  -the admissibility of correspondence with a digital ruble account,
//  -whether the corresponding account is a digital ruble account.
//
// Parameters:
//  BankAccount    - CatalogRef.CompaniesBankAccounts,
//                      Reference link.Counteragents' Bank account - the account being checked.
//  CorBankAccount - CatalogRef.CompaniesBankAccounts,
//                      Reference link.Bankaccountcountagents - verifiable cor. account.
//
// Returns:
//   -Structure - parameters of correspondence with a digital ruble account:
//    *CorrespondenceWithDigitalRubleAccountIsAllowed - Boolean - whether the correlation is acceptable. with a digital ruble account
//    *CorrespondentAccountOfDigitalRuble - Boolean - indicates that a digital ruble account is being used as a correspondent account.
//
Function ParametersOfCorrespondenceWithDigitalRubleAccount(BankAccount, CorBankAccount) Export
	
	CorrespondenceParameters = New Structure;
	CorrespondenceParameters.Insert("CorrespondenceWithDigitalRubleAccountIsAllowed", True);
	CorrespondenceParameters.Insert("CorrespondentAccountOfDigitalRuble", False);
	
	If Not ValueIsFilled(BankAccount)
		 Or Not ValueIsFilled(CorBankAccount) Then
		Return CorrespondenceParameters;
	EndIf;
	
	ArrayOfBankAccounts = CommonClientServer.ArrayOfValues(BankAccount, CorBankAccount);
	BankingAccountDetails = Common.ObjectsAttributeValue(ArrayOfBankAccounts, "DigitalRoubleAccount");
	
	CorrespondentAccountOfDigitalRuble = BankingAccountDetails.Get(CorBankAccount);
	DigitalRoubleAccount     = BankingAccountDetails.Get(BankAccount);
	
	CorrespondenceParameters.CorrespondenceWithDigitalRubleAccountIsAllowed =
		                             (DigitalRoubleAccount And CorrespondentAccountOfDigitalRuble)
		                              Or (Not DigitalRoubleAccount And Not CorrespondentAccountOfDigitalRuble);
	CorrespondenceParameters.CorrespondentAccountOfDigitalRuble = CorrespondentAccountOfDigitalRuble;

	Return CorrespondenceParameters;
	
EndFunction

// Adds commands for creating bank accounts to the form.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which commands for creating bank accounts will be added to the group.
//  CatalogMetadata - MetadataObject - Catalog metadata for checking access rights.
//
Procedure AddBankAccountCreationCommands(Form, CatalogMetadata) Export
	
	GroupCreate = Form.Items.Find("GroupCreate");
	If GroupCreate = Undefined Then
		Return;
	EndIf;
	
	If Not AccessRight("Insert", CatalogMetadata) Then
		Return;
	EndIf;
	
	AddingCommands = New Map;
	AddingCommands.Insert("CreateBankAccount", "Create");
	GroupCreate.Type = FormGroupType.ButtonGroup;
	
	
	For Each CommandDetails In AddingCommands Do
		CreationCommand = Form.Commands.Add(CommandDetails.Key);
		CreationCommand.Action = "Attachable_CreateBankAccount";
		CommandButton = Form.Items.Add(CommandDetails.Key, Type("FormButton"), GroupCreate);
		CommandButton.Title  = CommandDetails.Value;
		CommandButton.CommandName = CommandDetails.Key;
	EndDo;
	
EndProcedure

// Adds available Forms of payment
//
// Parameters:
//  PaymentForms - Array of EnumRef.PaymentForms - list of payment Forms. 
//
Procedure AddAvailableFormsOfPayment(PaymentForms) Export

	
	Return;

EndProcedure


#Region PaymentsToSelfEmployed

// Changes the properties of the elements associated with the operation with the self-employed in the documents "Purchase of goods and services"
// and "Purchase of services and other assets".
//
// Parameters:
//  Form - ClientApplicationForm - The Form in which the display changes.
//
Procedure ConfigureElementsOfOperationsWithSelfEmployed(Form, ThereIsBindingReceipt = True) Export

	
	Return;

EndProcedure

// Disables the self-employed purchase flag in the purchase documents: "Purchase of goods and services" 
// and "Purchase of services and other assets".
//
// Parameters:
//  Form - ClientApplicationForm - The Form of the purchase document.
//
Procedure FillInAttributeForPurchasingFromSelfEmployedPerson(Form) Export

	
	Return;

EndProcedure

// Fills in the document when the "Operation with self-employed" flag is changed.
//
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
//
Procedure OperationWithSelfEmployedPersonOnChange(Form, ThereIsBindingReceipt = True) Export

	
	Return;

EndProcedure

// Sets the Status of the receipt loading in the Form of purchase documents: "Purchase of goods and services"
// and "Purchase of services and other assets".
//
// Parameters:
//  Form - ClientApplicationForm - The Form of the purchase document.
//
Procedure SetStatusOfUploadingReceipts(Form) Export

	
	Return;
	
EndProcedure


#EndRegion

#Region InstantPayments

// Returns a b2b payment link.
// 
// Parameters:
//  DocumentRef - DocumentRef - The document for which the payment link is being searched.
// 
// Returns:
//  String, Undefined - B2B Payment Link
Function PaymentLinkb2b(DocumentRef) Export

	Result = Undefined;
	
	
	Return Result;

EndFunction

// Returns binary data of b2b SBP payment links.
// 
// Parameters:
//  DocumentRef - DocumentRef - The document for which the payment link is being searched.
//  Size - Number - The size of the QR code image.
// 
// Returns:
//  Undefined, BinaryData - Image of the QRcode SBPb2b
Function ImageOfQRCodeSBPb2b(DocumentRef, Size = 200) Export

	BinaryData = Undefined;
	
	
	Return BinaryData;

EndFunction

// Adds the commands "Update payment Status SBP" to the Form of the document.
// 
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
//  CommandParameters - See NewParametersOfSBPPaymentStatusUpdateCommand.
//
Procedure AddSBPPaymentStatusUpdateCommand(Form, CommandParameters) Export

	
	Return;

EndProcedure

// Returns the structure of the parameters of the SBP payment Status update command.
// 
// Returns:
//  Structure:
// * Parent - Undefined - the Form of the document or group on the Form.
// * Location - Undefined - the element in front of which the command will be placed.
Function NewParametersOfSBPPaymentStatusUpdateCommand() Export

	CommandParameters = New Structure;
	CommandParameters.Insert("Parent", Undefined);
	CommandParameters.Insert("Location", Undefined);
	
	Return CommandParameters;

EndFunction

// Checks the recipient specified in the document and the recipient specified in the SBP payment link.
// 
// Parameters:
//  DocumentObject - DocumentObject - A document containing an incoming SBP payment link.
//  WriteMode - DocumentWriteMode - the recording mode of the document.
//  Cancel - Boolean - indicates that the recording was rejected.
//
Procedure CheckRecipientOfPaymentLinksSBP(DocumentObject, WriteMode, Cancel) Export

	
	Return;

EndProcedure

#EndRegion

#EndRegion

