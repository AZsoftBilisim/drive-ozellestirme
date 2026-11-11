#Region Public

#Region AccountingForIncomingVAT

#Region RegistrationOfInvoicesReceived

// Performs processing navigation links formatted string obtained using Whatsup.Invoice received on the basis(). 
// Opens a new or existing invoice form. If several invoices are registered based on the document, it opens the list of documents.
//
// Parameters:
// 	Form - ClientApplicationForm - the form of the document
// 	URL - String - Navigation link of the formatted string.
// 	StandardProcessing - Boolean - indicates standard event handling.
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
//
Procedure ProcessingNavigationLinkInvoicesReceived(Form, URL, StandardProcessing, RegistrationParameters) Export
	
	
EndProcedure

// Called in the handler for processing the Selection () form of the document that is the basis of the invoice received.
// Returns an indication that the invoice form is closed. 
// This requires to update the presentation of invoices in the form of a document.
//
// Parameters:
// 	SelectionResult - Arbitrary - election result.
// 	ChoiceSource - Arbitrary - The form that sent the selection notification.
//
// Returns:
// 	Boolean - Indicates that the document form closing event.
//
Function FinishedEditingInvoiceReceived(SelectionResult, ChoiceSource) Export
	
	Result = False;
	Return Result;
	
EndFunction

#EndRegion


#EndRegion

#Region AccountingForOutgoingVAT

#Region FormationOfInvoicesIssued

// Performs processing navigation links formatted string obtained using Whatsup.The invoice is issued on the basis of(). 
// Opens a new or existing invoice form. If several invoices are registered based on the document, it opens the list of documents.
//
// Parameters:
// 	Form - ClientApplicationForm - the form of the document
// 	URL - String - Navigation link of the formatted string.
// 	StandardProcessing - Boolean - indicates standard event handling.
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
//
Procedure ProcessingNavigationLinkInvoicesIssued(Form, URL, StandardProcessing, RegistrationParameters) Export
	
	
EndProcedure

// Called in the handler for processing the Selection () form of the document that is the basis of the issued invoice.
// Returns an indication that the invoice form is closed. 
// This requires to update the presentation of invoices in the form of a document.
//
// Parameters:
// 	SelectionResult - Arbitrary - election result.
// 	ChoiceSource - Arbitrary - The form that sent the selection notification.
//
// Returns:
// 	Boolean - Indicates that the document form closing event.
//
Function FinishedEditingInvoiceIssued(SelectionResult, ChoiceSource) Export
	
	Result = False;
	Return Result;
	
EndFunction

// Performs printing of the generated corrective invoices.
//
// Parameters:
// 	TableOfModifiedDocuments - ValueTable - modified sales documents and their Attributes:
// 	  * Document - DefinedType.BaseDocumentIssuedTaxInvoice - the foundation document
// 	  * Organization - CatalogRef.Companies - company of the foundation document
// 	  * Date - Date - Date of the founding document
// 	  * EmployeeResponsible - CatalogRef.Users - The person responsible for the document is the foundation
// 	Form - ClientApplicationForm - Owner form from which invoices are printed. 
//
Procedure PrintingCorrectiveInvoicesForChangedDocuments(TableOfModifiedDocuments, Form) Export
	
	
EndProcedure

#EndRegion

#Region FormationOfInvoicesToCommissionAgent
	
// Performs processing navigation links formatted string obtained using Whatsup.Invoice of the commissionerunfoundation(). 
// Opens the invoice form or the form for the workplace for registration.
//
// Parameters:
// 	Form - ClientApplicationForm - the form of the document
// 	URL - String - Navigation link of the formatted string.
// 	StandardProcessing - Boolean - indicates standard event handling.
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesToCommissionAgent
//
Procedure ProcessingOfInvoiceNavigationLinkToCommissionAgent(Form, URL, StandardProcessing, RegistrationParameters) Export

	
EndProcedure

// Called in the handler for processing The selection() of the Commission agent report form.
// Returns an indication that the invoice form, list form, or job creation form is closed. 
// This requires to update the presentation of invoices in the form of a document.
//
// Parameters:
// 	SelectionResult - Arbitrary - election result.
// 	ChoiceSource - Arbitrary - The form that sent the selection notification.
//
// Returns:
// 	Boolean - Indicates that the closing event of the invoice editing form.
//
Function FinishedEditingInvoicesToCommissionAgent(SelectionResult, ChoiceSource) Export
	
	Result = False;
	Return Result;
	
EndFunction
	
#EndRegion

#Region SelectionAndExecutionOfInvoicesForReportToCommittee

// Returns the structure of parameters for opening the invoice selection form for reporting to the Commitee.
//
// Returns:
// 	Structure - Parameters for opening the invoice selection Form for reporting to the committee:
// 	                  * Organization - CatalogRef.Companies - Commission agent organization
// 	                  * Customer - CatalogRef.Counterparties, CatalogRef.Companies - Buyer of a Commission product.
// 	                  * Date - Date - Date when the invoice was issued. In General, the date of sale of goods to the buyer.
// 	                  * SelectedInvoice_ - DocumentRef - Link to the already selected invoice.
// 
Function ParametersForSelectingInvoiceToReportToCommittee() Export
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("Organization");
	ChoiceParameters.Insert("Customer");
	ChoiceParameters.Insert("Date");
	ChoiceParameters.Insert("SelectedInvoice_");
	
	Return ChoiceParameters;
	
EndFunction

// Opens the invoice selection form for reporting to the Commitee. 
// Called in the handler for the initial Selection () of the invoice form field issued to the buyer.
//
// Parameters:
// 	Item - FormField - Control element.
// 	ChoiceParameters - Structure - Parameters for selecting an invoice. See VATAccountingERPClient.ParametersForSelectingInvoiceToReportToCommittee.
// 	StandardProcessing - Boolean - indicates standard event handling.
//
Procedure StartSelectingInvoiceToReportToCommittee(Item, ChoiceParameters, StandardProcessing) Export
	
	
EndProcedure

// Returns the structure of parameters required to open the form formalaccountsfacturefor the report to the Customer
//
// Returns:
//	Structure - A parameter structure containing the following keys:
//              * Organization - CatalogRef.Companies - contains the company of the seller of the commission product
//              * AddressOfTableOfSalesOfCommissionGoods - String - contains the address in the temporary storage for the table 
//																	 of documents for the sale of commission goods
//					The table of implementations should have columns:
//						Link - documentlink - link to the implementation document
//						Date - Date - Date of the implementation document
//						Sum - Number - sum of the implementation document
//						Currency - Reference link.Currency - currency of the implementation document
//						Partner - Directory link.Partners - the partner to whom the commission product was sold
//						Counterparty - Directory link.Counterparties - the counterparty to whom the commission product was sold.
//  
Function ParametersOfInvoiceFormForReportToCommittee() Export
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization");
	FormParameters.Insert("AddressOfTableOfSalesOfCommissionGoods");
	Return FormParameters;
	
EndFunction

// Opens the form for issuing invoices issued.
// When the form is closed, a selection notification will be generated. As a result, the selection will be passed a match in which
//      The key is the implementation document for which the invoice is generated
//      The value is a link to the generated invoice.
//
// Parameters:
//  FormParameters - Structure - Parameters of the form to open See VATAccountingERPClient.ParametersOfInvoiceFormForReportToCommittee
//  OwnerForm - ClientApplicationForm - form for opening invoices 
//
Procedure OpenInvoiceFormForReportToCommittee(FormParameters, OwnerForm) Export
	
	
EndProcedure

// Called in the selection handler () to check whether the issued invoice data needs to be updated.
// Returns an indication that the issued invoice form is closed.
//
// Parameters:
// 	SelectionResult - Arbitrary - election result.
// 	ChoiceSource - Arbitrary - The form that sent the selection notification.
//
// Returns:
// 	Boolean - Indicates that the document form closing event.
//
Function CompletedProcessingOfInvoicesIssued(SelectionResult, ChoiceSource) Export
	
	Result = False;
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region VATTransferToBudgetByCertainTransactions

// LongDesc
// 
// Parameters:
// 	PickingParameters - See VATAccountingERPClient.ParametersForSelectingInvoicesThatRequireVATPayment.
// 	SelectionNotification - CallbackDescription - notification that will be triggered after the selection of documents.
//			The address of the temporary storage with a table of selected documents will be passed to the handler in the "Result" parameter 
//			. 
//			The table contains columns:
//				Counterparty - Directory link.Contractors - Supplier.
//				Contract - Reference book Link.Contractors' Agreements - a Contract with a supplier.
//				Invoice - Documentlink - A document requiring VAT payment.
//				The amount of payment - The number - The amount of VAT payment according to the document.
//
Procedure OpenFormForSelectingInvoicesThatRequireVATPayment(PickingParameters, SelectionNotification) Export
	
	
EndProcedure

// Returns the structure of parameters for opening the form for selecting documents that require VAT payment.
// 
// Returns:
// 	Structure - Structure of selection parameters:
//							* TaxType - CatalogRef.TaxContributionKinds - Type of tax payable: VAT_Importation of goods or tax_agent
//							* Organization - CatalogRef.Companies - Selection of documents by organization
//							* DocumentDate - Date - Selection of documents by period
//							* DocumentRef - DocumentRef - link to the payment document
//							* TempStorageAddress - String
//- A link to a temporary storage with a table of already selected documents.
//			The table should have the following columns:
//				Counterparty - Supplier.
//				Contract - a Contract with a supplier.
//				invoice - a document that pays VAT.
//				the amount of payment is the amount of VAT payment according to the document.
//
Function ParametersForSelectingInvoicesThatRequireVATPayment() Export
	
	PickingParameters = New Structure;
	
	PickingParameters.Insert("TaxType", Type("CatalogRef.TaxContributionKinds"));
	PickingParameters.Insert("Organization", Type("CatalogRef.Companies"));
	PickingParameters.Insert("DocumentDate");
	PickingParameters.Insert("DocumentRef");
	PickingParameters.Insert("TempStorageAddress");
	
	Return PickingParameters;
	
EndFunction

// Opens the form for viewing and editing the VAT payment status for the invoice.
// 
// Parameters:
// 	TaxInvoice - DefinedType.TaxInvoice - A document requiring payment of VAT.
//	OwnerForm - ClientApplicationForm - the form that called the method
//
Procedure OpenInvoiceVATPaymentStateForm(TaxInvoice, OwnerForm) Export
	
	
EndProcedure

// Updates the title of the command to view the VAT payment status for a document after manual editing in the payment documents form.
// 
// Parameters:
//	ChoiceSource - Arbitrary - Form where the selection was made
// 	StateText - String - the new text of the status of payment.
// 	StateCommand - FormButton - An element of the status view command.
Procedure ProcessingChangesInStateOfVATPaymentOnInvoice(ChoiceSource, StateText, StateCommand) Export
	
	
EndProcedure

// Updates the command to view the VAT payment status for a document after changes in the VAT accounting document form.
// 
// Parameters:
// 	StateCommand - FormButton - An element of the status view command.
// 	PaymentOfNDSVBudgetIsRequired - Boolean - determines whether the payment status should be displayed in the document form
Procedure ProcessingChangesInPaymentStateOfNDSInDocumentForm(StateCommand, PaymentOfNDSVBudgetIsRequired) Export
	
	
EndProcedure

// Performs the processing of the navigation link of the formatted string.
// Opens the form for the Workplace for setting the compliance of the document delivery and the DPP.
//
// Parameters:
// 	Form - ClientApplicationForm - the form of the document
// 	Parameters - Structure:
// 	*Basis - DocumentRef
// 	*Organization - CatalogRef.Companies
// 	*Date - Date
// 	URL - String - Navigation link of the formatted string.
// 	StandardProcessing - Boolean - indicates standard event handling.
//
Procedure ProcessingOfNavigationLinkDOPP(Form, Parameters, URL, StandardProcessing) Export
	
	
EndProcedure

#EndRegion

#Region CommandHandlers

// Input command handler based on
// 
// Parameters:
// 	ReferencesArrray - Array of DocumentRef.IssuedTaxInvoicePrepayment -
//  ExecutionParameters - Structure:
//                         * CommandDetails - Structure:
//                            ** Id           - String  - command ID.
//                            ** Presentation           - String  - representation of the team in the form.
//                            ** AdditionalParameters - Structure - Additional command parameters.
//                            ** MultipleChoice      - Boolean - multiple choice flag.
//                        * Form           - ClientApplicationForm - the form from which the command is called.
//                        * IsObjectForm - Boolean - True if the command is called from an object form.
//                        * Source        - FormTable, FormDataStructure - An object or list of the form with the "Link" field.
//
Procedure CorrectiveInvoiceIssuedAdvance(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure();
	
	CommandExecuteParameters.Insert("Source");
	CommandExecuteParameters.Insert("Uniqueness");
	CommandExecuteParameters.Insert("Window");
	CommandExecuteParameters.Insert("URL");
	
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	FillingValues = New Structure;
	FillingValues.Insert("Patch", True);
	FillingValues.Insert("BaseDocumentTaxInvoice", CommandParameter);
	
	FormParameters = New Structure;
	FormParameters.Insert("Basis", FillingValues);
	
	OpenForm("Document.IssuedTaxInvoicePrepayment.ObjectForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

// Input command handler based on
// 
// Parameters:
// 	ReferencesArrray - Array of DocumentRef.ReceivedTaxInvoicePrepayment -
//  ExecutionParameters - Structure:
//                         * CommandDetails - Structure:
//                            ** Id           - String  - command ID.
//                            ** Presentation           - String  - representation of the team in the form.
//                            ** AdditionalParameters - Structure - Additional command parameters.
//                            ** MultipleChoice      - Boolean - multiple choice flag.
//                        * Form           - ClientApplicationForm - the form from which the command is called.
//                        * IsObjectForm - Boolean - True if the command is called from an object form.
//                        * Source        - FormTable, FormDataStructure - An object or list of the form with the "Link" field.
//
Procedure CorrectiveInvoiceReceivedAdvance(ReferencesArrray, ExecutionParameters) Export
	
	CommandExecuteParameters = New Structure();
	
	CommandExecuteParameters.Insert("Source");
	CommandExecuteParameters.Insert("Uniqueness");
	CommandExecuteParameters.Insert("Window");
	CommandExecuteParameters.Insert("URL");
	
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Not ExecutionParameters.CommandDetails.MultipleChoice Then
		CommandParameter = ReferencesArrray;
	Else
		CommandParameter = ReferencesArrray[0];
	EndIf;
	
	FillingValues = New Structure;
	FillingValues.Insert("Patch", True);
	FillingValues.Insert("BaseDocumentTaxInvoice", CommandParameter);
	
	FormParameters = New Structure;
	FormParameters.Insert("Basis", FillingValues);
	
	OpenForm("Document.ReceivedTaxInvoicePrepayment.ObjectForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion

#EndRegion

