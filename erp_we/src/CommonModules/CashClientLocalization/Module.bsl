#Region Public


// Performs verification of the document "Purchase of goods and services" and "Purchase of services and other assets" before uploading 
// self-employed person's receipt.
//
// Parameters:
//  Form - ClientApplicationForm - The Form of the purchase document.
//
Procedure BeforeUploadingSelfEmployedPersonSReceiptToDocument(Form) Export

	
	Return;

EndProcedure

// Returns a foreign bank attribute based on account data.
//
// Parameters:
//  InternationalBankAccountDetails - Boolean - setting up "International Attributes of bank accounts".
//  InvoiceData - See CashClientServer.NewBankAccountData.
//
// Returns:
//   Boolean
//
Function ItSForeignBank(InternationalBankAccountDetails, InvoiceData) Export

	
	Return True;

EndFunction

// Checks the account number.
//
// Parameters:
//  Form - ClientApplicationForm - The Form in which the check is performed.
//  Suffix - String - addition to the Attribute name on the Form.
//  InvoiceData - See CashClientServer.NewBankAccountData.
//
Procedure CheckAccountNumber(Form, Suffix, InvoiceData)Export

	
	Return;

EndProcedure

#Region InstantPayments

// Handles notification when an event from the SBP occurs: changes the inscription of the SBP hyperlink.
// 
// Parameters:
//  Form - ClientApplicationForm - the general Form of payment stages.
//  Document - DocumentRef - the document that the notification is processed for.
//  EventName - String - event name.
//  Incoming - Boolean - indicates the direction of the SBP payment link.
//
Procedure ProcessingSBPNotification(Form, Document, EventName, Incoming = False) Export

	
	Return;

EndProcedure

// Handles clicking on the navigation hyperlink of payment via SBP.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form of the payment stages or the Form of the "Invoice for payment" document.
//  Document - DocumentRef - Operation document.
//  URL - String - navigation links.
//
Procedure ProcessingOfNavigationLinkSBP(Form, Document, URL) Export

	
	Return;

EndProcedure

// Gets the SBP connection settings before processing the barcode of the payment link.
// 
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
//  Barcode - String - barcode.
//  DenialProcessing - Undefined, CallbackDescription - notification in case of failure.
Procedure BeforeProcessingBarcodeOfPaymentLink(Form, Barcode, DenialProcessing) Export

	
	Return;

EndProcedure

// Updates the Status of the payment of the SBP according to the document by requesting payment information to the service.
// 
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
//  DocumentRef - DocumentRef - The document for which the Status is being updated.
//
Procedure UpdateStatusOfSBPPaymentByDocument(Form, DocumentRef) Export

	
	Return;

EndProcedure

// Performs verification of the availability of SBP payment by checking the percentage of payment according to the registers of mutual settlements of the document itself and 
// related documents.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form of the document in which the check is performed.
//  DocumentRef - DocumentRef - link to the document in which the check is performed.
//  Counterparty - CatalogRef.Counterparties - the payer in the document.
//
Procedure CheckSBPPayment(Form, DocumentRef, Counterparty) Export

	
	Return;

EndProcedure

#EndRegion

#Region OnlineOrders

// Performs verification of the availability of payment for an onlineorder by checking the percentage of payment in the settlement registers.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form of the document in which the check is performed.
//  DocumentRef - DocumentRef.SalesOrder - link to the document in which the check is performed.
//
Procedure CheckOnlineOrderPayment(Form, DocumentRef) Export

	
	Return;

EndProcedure

#EndRegion

// Enables waiting handlers to check whether a payment has been completed via online order and SBP services.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form of the document in which the handlers are launched.
//  DocumentRef - DocumentRef - link to the document in which the check is performed.
//  Counterparty - CatalogRef.Counterparties - the payer in the document.
//
Procedure AttachablePaymentVerificationViaServices(Form, DocumentRef, Counterparty) Export

	
	Return;

EndProcedure

// Disables checks for payment via services: online order, SBP.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form of the document in which the check was performed.
//
Procedure DisablePaymentVerificationViaServices(Form) Export

	Form.DetachIdleHandler("Attachable_OnlineOrderPaymentVerification");
	Form.DetachIdleHandler("Attachable_SBPPaymentVerification");

EndProcedure

#EndRegion

#Region Internal

Procedure BeforeCreatingBankAccount(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return
	EndIf;
	OpenBankAccountCreationCompletion(AdditionalParameters.Owner, Result, AdditionalParameters.DescriptionOfNotificationAboutClosingAccountForm);
	
EndProcedure

Function OpenPaymentResultsForChartLines(FormItem, Result, Notification) Export
	
	
	Return False;
	
EndFunction

// Opens a form for creating a bank account for an organization or counterparty
//
// Parameters:
//  List          - DynamicList - list of Catalog items
//  Command         - FormCommand - the creation command being called.
//  BankAccountOfCompany - Boolean - indicates whether the Catalog of organizations' bank accounts
//                              has been opened. If set to False
//                              , the counterparty's bank accounts Catalog form will be opened.
//
Procedure OpenBankAccountCreation(List, Command, BankAccountOfCompany = True) Export
	
	CreatingDigitalRubleAccount = False;
	
	AccountHolder = ?(BankAccountOfCompany,
	                  PredefinedValue("Catalog.Companies.EmptyRef"),
	                  PredefinedValue("Catalog.Counterparties.EmptyRef"));

	For Each FilterElement In List.Filter.Items Do
		If FilterElement.LeftValue = New DataCompositionField("Owner") And FilterElement.Use
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
			AccountHolder = FilterElement.RightValue;
			Break;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(AccountHolder) Then
		
		For Each ParameterElement In List.Parameters.Items Do
			
			If ParameterElement.Parameter = New DataCompositionParameter("Owner")
				And ParameterElement.Use
				And TypeOf(ParameterElement.Value) <> Type("Array")
				And TypeOf(ParameterElement.Value) <> Type("ValueList") Then
				AccountHolder = ParameterElement.Value;
				Break;
			EndIf;
			
		EndDo;
	
	EndIf;
	
	OpenBankAccountCreationCompletion(AccountHolder, CreatingDigitalRubleAccount);
	
EndProcedure

// Opens a form for creating a bank account for an organization or counterparty
//
// Parameters:
//  Owner - Directory Link.Organizations,
//                         Reference link.Counterparties,
//                         reference link.A physical page is a list of Catalog elements.
//  StandardProcessing - Boolean - indicates the use of standard processing.
//  DocumentForm       - ClientApplicationForm - The Form from which the creation of a bank account is called
//  NameOfAttributeToFillIn - String - the name of the Attribute of the object to which the newly created bank account should be recorded
//
Procedure StartCreatingBankAccount(AccountHolder, StandardProcessing, DocumentForm, NameOfAttributeToFillIn) Export
	
	
EndProcedure

// Adds a link to the Catalog element to the additional parameters of the Form closing notification.
//
// Parameters:
//  Form - ClientApplicationForm - The Form of the element of the Catalogs of banking accounts of organizations, banking accounts of contractors.
//
Procedure BeforeClosingBankAccountForm(Form) Export
	
	
EndProcedure


#EndRegion

#Region Private

Procedure OpenBankAccountCreationCompletion(AccountHolder, CreatingDigitalRubleAccount, DescriptionOfNotificationAboutClosingAccountForm = Undefined)
	
	BankAccountOfCompany = TypeOf(AccountHolder) = Type("CatalogRef.Companies");
	
	FormPath         = ?(BankAccountOfCompany,
		                   "Catalog.CompaniesBankAccounts.Form.ItemForm",
		                   "Catalog.CounterpartyBankAccounts.Form.ItemForm");
	
	FillingValues = New Structure;
	
	
	FillingValues.Insert("Owner", AccountHolder);
	
	FormParameters = New Structure();
	FormParameters.Insert("FillingValues", FillingValues);
	OpenForm(FormPath, FormParameters, , , , ,DescriptionOfNotificationAboutClosingAccountForm);
	
EndProcedure


#EndRegion