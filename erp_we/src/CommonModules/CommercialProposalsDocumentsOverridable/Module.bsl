////////////////////////////////////////////////////////////////////////////////
// Subsystem "Commercial offers documents".
// General module.Commercial propositiondocumentdetermined
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Defines the list of offer sources to analyze.
// By default, only trade offers from 1C are analyzed:The business network and
// commercial offers are not from this request.
//
// Parameters:
//  Sources - ValueTable - table with columns:
//   * SourceName           - String   - name of the offer source.
//   * SourcePresentation - String   - source view.
//   * SourceImage      - Picture - image of the source for output to the form.
//   * BriefPresentation   - String   - text description of the source.
//   * Use           - Boolean   - use the source for new documents.
//   * IsLocked           - Boolean   - block the ability to disable the source.
//   * SupportsSaving - Boolean   - supports comments and state changes.
//
Procedure AnalyzedSourcesOfProposals(Sources) Export
	
	CommercialProposalsDocumentsTM.AnalyzedSourcesOfProposals(Sources);
	
EndProcedure


// Saves changes to comments and source States.
//
// Parameters:
//   Sources - ValueTable - table with columns:
//    * Source          - Arbitrary - source of analysis of trade offers.
//    * StoppedBeingReviewed - Boolean   - don't consider the offer.
//    * Comment       - Picture - brief comment.
//   Cancel - Boolean - there were errors during saving.
//
Procedure SaveUserChangesInSourceDocuments(Sources, Cancel) Export
	
	CommercialProposalsDocumentsTM.SaveUserChangesInSourceDocuments(Sources, Cancel);
	
EndProcedure

// Setting the conditional design for the item characteristics.
//
// Parameters:
//  Form - Form - Contains this form 
//  NameOfCharacteristicInputField - String - Name of the form element containing the item's characteristics,
//     if it differs from"product Characteristics".
//  PathToSelectionField - String - The full path to the "characteristics used" attribute,
//     if it differs from " Object.Goods.Characteristics are used".
//
Procedure EstablishConditionalAppearanceOfProductCharacteristics(Form,
	NameOfCharacteristicInputField = "GoodsCharacteristic",
	PathToSelectionField = "Object.Goods.ItemVariantsAreUsed") Export
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(Form);
	
EndProcedure

// Ability to define the conditional design in the form.
//
// Parameters:
//  Form - ClientApplicationForm - the form for which the conditional design is defined.
//
Procedure WhenSettingConditionalAppearance(Form) Export
	
	CommercialProposalsDocumentsTM.WhenSettingConditionalAppearance(Form);
	
EndProcedure

// The ability determine the settings of the account.
//
// Parameters:
//  Settings - See CommercialProposalsDocuments.AccountingSettings
//
Procedure WhenDefiningAccountingSettings(Settings) Export
	
	CommercialProposalsDocumentsTM.WhenDefiningAccountingSettings(Settings);
	
	
EndProcedure


// Called to get documents created based on a Commercial offer to the client.
//
// Parameters:
//  ObjectReference - DocumentRef - link to the document commercial offer to the client.
//  CommercialOffersToClient - ValueTable - a table with data about the created on the basis of the document:
//   * Ref   - DocumentRef - Link to the created document.
//   * Number    - Number  - document number.
//   * Date     - Date   - document date.
//   * Manager - String - Name of the user who created the document.
//
Procedure ReceiveCommercialOffersToClientOnBasisOf(Val ObjectReference, CommercialOffersToClient) Export
	
	CommercialProposalsDocumentsTM.ReceiveCommercialOffersToClientOnBasisOf(ObjectReference,
		CommercialOffersToClient);
	
EndProcedure

// Called to get the partner view.
//
// Parameters:
//   PresentationOfCounterpartySPartner - String - text representation of the counterparty's partner.
//   Partner                          - DefinedType.PartnerOfEDL - link to the partners directory.
//   Counterparty                       - DefinedType.EDLCounterparty - link to the contractors directory.
//   StandardProcessing             - Boolean - The counterparty's view has been changed.
//
Procedure UponReceiptOfPresentationOfCounterpartySPartner(PresentationOfCounterpartySPartner, Partner, Counterparty, StandardProcessing) Export
	
	CommercialProposalsDocumentsTM.UponReceiptOfPresentationOfCounterpartySPartner(PresentationOfCounterpartySPartner, Partner, 
		Counterparty, StandardProcessing);
	
EndProcedure

// The ability to override the provision of data to generate an electronic document.
//
// Parameters:
//   ObjectReference       - DocumentRef.CommercialProposalForCustomer - link to the document.
//   PreparedData - Undefined - the prepared data is placed in this variable.
//   StandardProcessing             - Boolean - The counterparty's view has been changed.
//
Procedure WhenFillingInDataOfElectronicDocument(ObjectReference, PreparedData , StandardProcessing) Export
	
	CommercialProposalsDocumentsTM.WhenFillingInDataOfElectronicDocument(ObjectReference, PreparedData , StandardProcessing);
	
EndProcedure

#Region FormEventHandlers

// Occurs on the server when creating a form.
//
// Parameters:
//  Form - ClientApplicationForm - the form being created.
//  Cancel - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard processing is being performed.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	CommercialProposalsDocumentsTM.OnCreateAtServer(Form, Cancel, StandardProcessing);
	
EndProcedure

// Called when reading an object on the server.
//
// Parameters:
//  Form - ClientApplicationForm - form of the readable object.
//  CurrentObject - DocumentObject, CatalogObject - readable object.
//
Procedure OnReadAtServer(Form, CurrentObject) Export
	
	CommercialProposalsDocumentsTM.OnReadAtServer(Form, CurrentObject);
	
EndProcedure

// Called after writing in the form of an object on the server.
//
// Parameters:
//  Form           - ClientApplicationForm - form of the recorded object,
//  CurrentObject   - DocumentObject, CatalogObject - the recorded object,
//  WriteParameters - Structure - contains the recording parameters.
//
Procedure AfterWriteAtServer(Form, CurrentObject, WriteParameters) Export
	
	CommercialProposalsDocumentsTM.AfterWriteAtServer(Form, CurrentObject);
	
EndProcedure

#EndRegion

#Region DocumentEventHandlers

// Called when entering a document based on, when executing the Fill in method, or when interactively entering a new one.
//
// Parameters:
//  DocumentObject - DocumentObject - The document to be filled in.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  FillingText - String, Undefined - Text used to fill in the document.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure ProcessingDocumentFilling(DocumentObject, FillingData, FillingText, StandardProcessing) Export
	
	CommercialProposalsDocumentsTM.ProcessingDocumentFilling(DocumentObject, FillingData, FillingText, StandardProcessing);
	
EndProcedure

// Called by the form extension when it is necessary to check the filling in of details when writing or when conducting a document in the form,
// as well as when executing the Checkfill method.
//
// Parameters:
//  DocumentObject - DocumentObject - The document being checked.
//  Cancel - Boolean - indicates that the document was rejected.
//  CheckedAttributes - Array of See PropertyManager.FillCheckProcessing - Array of paths to the details to be checked for.
//  NotCheckedAttributeArray - Array of See PropertyManager.FillCheckProcessing - array of paths to details that will not be checked for filling in.
//
Procedure FillCheckProcessing(DocumentObject, Cancel, CheckedAttributes, NotCheckedAttributeArray) Export
	
	CommercialProposalsDocumentsTM.FillCheckProcessing(DocumentObject, Cancel, CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

// Occurs before writing a document. Called after the start of the write transaction, but before the document is written.
//
// Parameters:
//  DocumentObject - DocumentObject - recordable document,
//  Cancel - Boolean - flag for refusing to write,
//  WriteMode - DocumentWriteMode - the current recording mode of the document,
//  PostingMode - DocumentPostingMode - the current mode of the document.
//
Procedure BeforeWrite(DocumentObject, Cancel, WriteMode, PostingMode) Export
	
	CommercialProposalsDocumentsTM.BeforeWrite(DocumentObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

// Occurs in a transaction when writing a document.
//
// Parameters:
//  DocumentObject - DocumentObject - recordable document,
//  Cancel - Boolean - flag for refusing to write
//
Procedure OnWrite(DocumentObject, Cancel) Export
	
	CommercialProposalsDocumentsTM.OnWrite(DocumentObject, Cancel);
	
EndProcedure

// Occurs in a transaction when a document is being processed.
//
// Parameters:
//  DocumentObject  - DocumentObject - current document.
//  Cancel           - Boolean - indicates that the operation was refused.
//  PostingMode - DocumentPostingMode - promptly or not.
//
Procedure Posting(DocumentObject, Cancel, PostingMode) Export
	
	CommercialProposalsDocumentsTM.Posting(DocumentObject, Cancel, PostingMode);
	
EndProcedure

// Occurs in a transaction when a document is being processed.
//
// Parameters:
//  DocumentObject  - DocumentObject - the document where the transaction is being deleted.
//  Cancel           - Boolean         - indicates that the operation was refused.
//
Procedure UndoPosting(DocumentObject, Cancel) Export
	
	CommercialProposalsDocumentsTM.UndoPosting(DocumentObject, Cancel);
	
EndProcedure

// Called when copying a document.
//
// Parameters:
//  DocumentObject - DocumentObject - The document to be filled in.
Procedure OnCopy(DocumentObject) Export
	
	CommercialProposalsDocumentsTM.OnCopy(DocumentObject);
		
EndProcedure

// Occurs when getting a to-do list for commercial offer documents.
//
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList.
//  DocumentName - String - name of the document to fill in the to-do list for.
//
Procedure WhenFillingInListOfCurOfBusinessCommercialOffers(ToDoList, DocumentName) Export
	
	CommercialProposalsDocumentsTM.WhenFillingInListOfCurOfBusinessCommercialOffers(ToDoList, DocumentName);
	
EndProcedure

#EndRegion

#Region ServerSideEventHandlersForDocumentElements

// Performs actions when changing the item in the Products table.
//
// Parameters:
//  Form                   - ClientApplicationForm - the form in which the event occurred.
//  CurrentRow           - FormDataCollectionItem - a row in the product table.
//  CurrentItem          - String - Name of the changed field in the current line,
//
Procedure WhenChangingProducts(Form, CurrentRow, CurrentItem) Export
	
EndProcedure

// Performs actions when changing a characteristic in the Products table.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow - FormDataCollectionItem - a row in the product table.
//
Procedure WhenChangingCharacteristics(Form, CurrentRow) Export
	
EndProcedure

// Performs actions when changing the unit of measurement in the Products table.
//
// Parameters:
//  Form          - ClientApplicationForm - the form in which the event occurred.
//  CurrentRow - FormDataCollectionItem - Row of the table products,
//
Procedure WhenChangingUnitOfMeasurement(Form, CurrentRow) Export
	
EndProcedure

// Performs actions when changing the quantity in the Products table.
//
// Parameters:
//  Form          - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow  - FormDataCollectionItem - a row in the product table.
//
Procedure WhenChangingQuantity(Form, CurrentRow) Export
	
EndProcedure

// Performs actions when the price changes in the Products table.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow - FormDataCollectionItem - a row in the product table.
//
Procedure WhenPriceChanges(Form, CurrentRow) Export
	
EndProcedure

// Performs actions when changing the type of price in the Products table.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow - FormDataCollectionItem - a row in the product table.
//
Procedure WhenChangingPriceType(Form, CurrentRow) Export
	
EndProcedure

// Performs actions when changing the amount in the Products table.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow - FormDataCollectionItem - row of the table products
//
Procedure WhenChangingAmount(Form, CurrentRow) Export
	
EndProcedure

// Performs actions when changing the VAT rate in the Products table.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow - FormDataCollectionItem - row of the table products
//
Procedure WhenChangingVATRate(Form, CurrentRow) Export
	
EndProcedure

// Performs actions when changing the VAT amount in the Products table.
//
// Parameters:
//  Form           - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow   - FormDataCollectionItem - Row of the table products,
//  PriceIncludesVAT - Boolean - indicates that the price includes VAT.
//
Procedure WhenChangingVATAmount(Form, CurrentRow, PriceIncludesVAT) Export
	
EndProcedure

// Performs actions when VAT taxation changes.
//
// Parameters:
//  Form                   - ClientApplicationForm - the form in which the event occurred.
//
Procedure WhenChangingVATTaxation(Form) Export
	
	CommercialProposalsDocumentsTM.WhenChangingVATTaxation(Form);
	
EndProcedure

// Performs actions when the VAT inclusion attribute is changed in the Price.
//
// Parameters:
//  Form           - ClientApplicationForm - the form in which the event occurred,
//  Taxation - Boolean - indicates that the sale or purchase is subject to VAT
//
Procedure OnChangePriceIncludesVAT(Form, Taxation) Export
	
	CommercialProposalsDocumentsTM.OnChangePriceIncludesVAT(Form, Taxation);
	
EndProcedure

// Performs actions when a partner (customer or supplier) changes in the document form.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred
//
Procedure WhenChangingPartner(Form) Export
	
	 CommercialProposalsDocumentsTM.WhenChangingPartner(Form);
	
EndProcedure

// Performs actions when the counterparty changes in the document form.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred.
//
Procedure WhenChangingCounterparty(Form) Export
	
EndProcedure

// Performs actions when changing the currency in the document form.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred.
//
Procedure WhenChangingCurrency(Form) Export
	
	CommercialProposalsDocumentsTM.WhenChangingCurrency(Form);
	
EndProcedure

// Performs actions when changing the validity period of a commercial offer in the form of a document.
//
// Parameters:
//  Form        - ClientApplicationForm - the form in which the event occurred.
//  CurrentDate  - Date - date when the change was made.
//
Procedure WhenChangingValidityPeriodOfCommercialOffer(Form, CurrentDate) Export
	
EndProcedure

// Performs actions when changing a business transaction in the document form.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred.
//
Procedure WhenBusinessTransactionChanges(Form) Export
	
	CommercialProposalsDocumentsTM.WhenBusinessTransactionChanges(Form);
	
EndProcedure

// Performs actions when changing the flag can be redeemed partially in the form of a document.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred.
//
Procedure WhenChangingFlagCanBeRedeemedPartially(Form) Export
	
EndProcedure

// Performs actions when the Manager changes in the document form.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred.
//
Procedure WhenChangingManager(Form) Export
	
EndProcedure

// Performs actions when changing the contact person in the document form.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred.
//
Procedure WhenChangingContactPerson(Form) Export
	
EndProcedure

// Performs actions when the status changes in the document form.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  CurrentDate - Date - date when the change was made.
//
Procedure WhenStatusChanges(Form, CurrentDate) Export
	
EndProcedure

// Performs actions when the organization changes in the document form.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred.
//
Procedure WhenOrganizationChanges(Form) Export
	
	CommercialProposalsDocumentsTM.WhenOrganizationChanges(Form);
	
EndProcedure

// Performs actions when changing the percentage of a manual discount in the Products table.
//
// Parameters:
//  Form                   - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow           - FormDataCollectionItem - Row of the table products,
//  PriceIncludesVAT         - Boolean - indicates that the price includes VAT,
//  Taxation         - Boolean - indicates that the sale or purchase is subject to VAT.
//
Procedure WhenChangingPercentageOfManualDiscount(Form, CurrentRow , PriceIncludesVAT, Taxation) Export
	
EndProcedure

// Performs actions when changing the amount of a manual discount in the Products table.
//
// Parameters:
//  Form           - ClientApplicationForm - the form in which the event occurred
//  CurrentRow   - FormDataCollectionItem - row of the table products
//  PriceIncludesVAT - Boolean - indicates that the price includes VAT
//  Taxation - Boolean - indicates that the sale or purchase is subject to VAT
//
Procedure WhenChangingAmountOfManualDiscount(Form, CurrentRow , PriceIncludesVAT, Taxation) Export
	
EndProcedure

// Server handler for the selection event in the "Products" tabular part of the "client's Commercial offer" document"
//
// Parameters:
//  Form              - ClientApplicationForm - the form in which the command is executed.
//  FieldName            - String - name of the table part field where the event occurred.
//  ProcessingResult - Arbitrary     - you can place custom data for further processing on the client.
//
Procedure GoodsSelectionServer(Form, FieldName, ProcessingResult) Export
	
EndProcedure

#EndRegion

#Region AccessManagement

// Event handler for filling in the individual restrictions of the right objects of the access Control subsystem Data.
//
// Parameters:
//  ObjectName - String - name of the object where the event occurred.
//  LongDesc   - See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionKinds.LongDesc
//
Procedure OnFillMetadataObjectsAccessRestrictionKinds(ObjectName, LongDesc) Export
	
	CommercialProposalsDocumentsTM.OnFillMetadataObjectsAccessRestrictionKinds(ObjectName, LongDesc);
	
EndProcedure

// Event handler for filling in access Restrictionsof the "access Control" subsystem"
//
// Parameters:
//  ObjectName - String - name of the object where the event occurred
//  Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(ObjectName, Restriction) Export
	
	CommercialProposalsDocumentsTM.OnFillAccessRestriction(ObjectName, Restriction);
	
EndProcedure

#EndRegion

#Region Discounts

// Server handler for the "Calculate discounts" command in the "client's Commercial offer" document"
//
// Parameters:
//  Form              - ClientApplicationForm - the form in which the command is executed
//  ProcessingResult - Arbitrary - you can place custom data for further processing on the client
//
Procedure CalculateDiscountsOnServer(Form, ProcessingResult) Export
	
	CommercialProposalsDocumentsTM.CalculateDiscountsOnServer(Form, ProcessingResult);
	
EndProcedure

// Server handler for the "Show discount information" command in the "client's Commercial offer" document"
//
// Parameters:
//  Form              - ClientApplicationForm - the form in which the command is executed
//  ProcessingResult - Arbitrary     - you can place custom data for further processing on the client
//
Procedure PrepareOpeningInformationAboutDiscountsOnServer(Form, ProcessingResult) Export
	
	CommercialProposalsDocumentsTM.PrepareOpeningInformationAboutDiscountsOnServer(Form, ProcessingResult);
	
EndProcedure

// Server handler for the "Cancel manual discounts" command in the "customer's Offer" document"
//
// Parameters:
//  Form              - ClientApplicationForm - the form in which the command is executed
//  ProcessingResult - Arbitrary     - you can place custom data for further processing on the client
//
Procedure WhenCancelingManualDiscountsOnServer(Form, ProcessingResult) Export
	
	CommercialProposalsDocumentsTM.WhenCancelingManualDiscountsOnServer(Form, ProcessingResult);
	
EndProcedure

// Server handler for the "Assign manual discounts" command in the "client's Commercial offer" document"
//
// Parameters:
//  Form              - ClientApplicationForm - the form in which the command is executed
//  ProcessingResult - Arbitrary     - you can place custom data for further processing on the client
//
Procedure WhenAssigningManualDiscountOnServer(Form, ProcessingResult) Export
	
	CommercialProposalsDocumentsTM.WhenAssigningManualDiscountOnServer(Form, ProcessingResult);
	
EndProcedure

// Server handler after selecting a manual discount on the server
//
// Parameters:
//  Form                   - ClientApplicationForm - the form in which the command is executed
//  SelectedRows        - Array of LineOfATabularSection - the selected row of a tabular part the Goods for which the discounts are applied
//  ProcessingResult      - Arbitrary - you can place custom data for further processing on the client
//  AdditionalParameters - Structure    - Command Execution Parameters
//
Procedure AfterAssigningManualDiscountOnServer(Form, SelectedRows, ProcessingResult, AdditionalParameters) Export
	
	CommercialProposalsDocumentsTM.AfterAssigningManualDiscountOnServer(Form, SelectedRows, ProcessingResult, AdditionalParameters);
	
EndProcedure

// Server handler for the "Assign automatic discounts" command in the "client's Commercial offer" document"
//
// Parameters:
//  Form     - ClientApplicationForm - the form in which the command is executed
//  Result - Arbitrary - you can place custom data for further processing on the client
//
Procedure WhenAssigningAutomaticDiscountsOnServer(Form, Result) Export
	
	CommercialProposalsDocumentsTM.WhenAssigningAutomaticDiscountsOnServer(Form, Result);
	
EndProcedure

// Server handler after automatic discounts are assigned
//
// Parameters:
//  Form                   - ClientApplicationForm - the form in which the command is executed
//  Result               - Arbitrary     - you can place custom data for further processing on the client
//  AdditionalParameters - Structure        - Command Execution Parameters
//
Procedure AfterAssigningAutomaticDiscountOnServer(Form, Result, AdditionalParameters) Export
	
	CommercialProposalsDocumentsTM.AfterAssigningAutomaticDiscountOnServer(Form, Result, AdditionalParameters);
	
EndProcedure

#EndRegion

#Region IntegrationOfMessageTemplates

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

// Server handler for the redefined command in the "client's Commercial offer" document"
//
// Parameters:
//  Form              - ClientApplicationForm - the form in which the command is executed,
//  CommandName         - String - form, name of the executed command,
//  ProcessingResult - Arbitrary     - you can place custom data for further processing on the client.
//
Procedure WhenExecutingOverridableCommand(Form, CommandName, ProcessingResult) Export
	
	CommercialProposalsDocumentsTM.WhenExecutingOverridableCommand(Form, CommandName, ProcessingResult);
	
EndProcedure

// Event handler for adding command Reports to the "Pluggable commands" subsystem"
//
// Parameters:
//  ObjectName - String - name of the object where the event occurred,
//  ReportsCommands - ValueTable - A table with report commands. For changes.
//      See the description of parameter 1 of the report variationreferences procedure.Before adding Team reports().
//  Parameters - Structure - Auxiliary parameters. For reading.
//      See the description of the 2 parameters of the procedure variationreportable.Before adding Team reports().
//
Procedure OnAddReportsCommands(ObjectName, ReportsCommands, Parameters) Export
	
	CommercialProposalsDocumentsTM.OnAddReportsCommands(ObjectName, ReportsCommands, Parameters);
	
EndProcedure

// Processes successful barcode scanning in the Products table.
//
// Parameters:
//  Form              - ClientApplicationForm - the form in which the selection is made,
//  BarcodeData_1    - Arbitrary - data of the scanned barcode,
//  ProcessingResult - Arbitrary - you need to put the result of processing in this value for further
//    actions on the client.
//
Procedure ProcessBarcodeInput(Form, BarcodeData_1, ProcessingResult) Export
	
	CommercialProposalsDocumentsTM.ProcessBarcodeInput(Form, BarcodeData_1, ProcessingResult);
	
EndProcedure

// Fills in the Products tabular part with the selected products.
// Parameters:
//  Form - ClientApplicationForm - the form in which the selection is made.
//  ValueSelected - Arbitrary - data containing the item selected by the user.
//  AdditionalParameters - Structure, Undefined - additional processing parameters.
//  ProcessingResult - Arbitrary - you can place custom data for further processing on the client.
//
Procedure ProcessingProductSelectionResults(Form, ValueSelected, AdditionalParameters, ProcessingResult) Export
	
	CommercialProposalsDocumentsTM.ProcessingProductSelectionResults(Form, ValueSelected, AdditionalParameters, ProcessingResult);
	
EndProcedure

// Fills in the Products tabular part with products received from an external data file.
// Parameters:
//  Form     - ClientApplicationForm - form to fill in,
//  Result - Arbitrary - data from the file.
//
Procedure LoadDataReceivedFromExternalFile(Form, Result) Export
	
	CommercialProposalsDocumentsTM.LoadDataReceivedFromExternalFile(Form, Result);
	
EndProcedure

// It is intended for transferring the table of products formed during the processing of TSD data.
//
// Parameters:
//  Form              - ClientApplicationForm - the form in which the TSD data was uploaded,
//  TableOfGoods     - Arbitrary - contains product data generated from the TSD data,
//  ProcessingResult - Arbitrary - this value should contain the result of processing
//    for further actions on the client.
//
Procedure ProcessReceivedTSDData(Form, TableOfGoods, ProcessingResult) Export
	
	CommercialProposalsDocumentsTM.ProcessReceivedTSDData(Form, TableOfGoods, ProcessingResult);
	
EndProcedure

// It is intended for filling in prices for the selected type of price for the selected rows of the table part
// of the goods document "Commercial offer to the client".
//
// Parameters:
//  Form                   - ClientApplicationForm - a form where you need to fill in prices by type of price.
//  PriceKind                 - DefinedType.PriceKindCommercialProposals - selected price type.
//  AdditionalParameters - Structure - additional processing parameters.
//
Procedure FillInPricesByPriceKind(Form, PriceKind, AdditionalParameters) Export
	
	CommercialProposalsDocumentsTM.FillInPricesByPriceKind(Form, PriceKind, AdditionalParameters);
	
EndProcedure

// It is used to fill in prices for the selected sales condition for the selected rows
// of the products table part of the "Commercial offer to the client" document.
//
// Parameters:
//  Form                   - ClientApplicationForm - form where you need to fill in prices by type of price,
//  SalesCondition           - Arbitrary     - selected conditions of sale,
//  AdditionalParameters - Structure        - additional processing parameters.
//
Procedure FillInPricesBySalesCondition(Form, SalesCondition, AdditionalParameters) Export
	
	CommercialProposalsDocumentsTM.FillInPricesBySalesCondition(Form, SalesCondition, AdditionalParameters);
	
EndProcedure

// Getting data on the nomenclature for forming the EDI tree.
//
// Parameters:
//   ListOfProducts - Array of DefinedType.EDLProducts - list of items that need to be decrypted
//   ProductFieldValues - Map of KeyAndValue - Field values of item elements:
//     * Key     - Arbitrary - Value of the array element
//     * Value - Structure    - The value of the fields required to fill in:
//        ** ProductsLink       - DefinedType.EDLProducts - link to an item from the 'List of Items' array
//        ** NomenclatureName - String - Presentation Of The nomenclature
//
Procedure FillInProductData(Val ListOfProducts, ProductFieldValues) Export
	
	CommercialProposalsDocumentsTM.FillInProductData(ListOfProducts, ProductFieldValues);
	
EndProcedure

// Getting data on the characteristics of the item to form the EDI tree.
//
// Parameters:
//  ListOfCharacteristics - Array of DefinedType.ItemsCharacteristicEDL - A list of characteristics of the item for which you want the transcript
//  CharacteristicFieldValues - Map of KeyAndValue - Values of the fields of the elements of the Characteristic array. Contains properties:
//    * Key     - Arbitrary - Value of the array element
//    * Value - Structure    - The value of the fields required to fill in.Contains properties:
//        ** CharacteristicReference       - DefinedType.ItemsCharacteristicEDL - link to a characteristic from the 'List of Characteristics' array
//        ** CharacteristicName - String - Presentation of the nomenclature characteristics
//
Procedure FillInProductCharacteristicsData(Val ListOfCharacteristics, CharacteristicFieldValues) Export
	
	CommercialProposalsDocumentsTM.FillInProductCharacteristicsData(ListOfCharacteristics, CharacteristicFieldValues);
	
EndProcedure

// Getting data on units of measurement for forming the EDI tree.
//
// Parameters:
//  ListOfUnits - Array of DefinedType.PackageEDLItems - List of units of measurement to be decrypted
//  FieldValues - Map of KeyAndValue - The values of the fields of the array elements are units of measurement. Contains properties:
//   * Key     - Arbitrary - Value of the array element
//   * Value - Structure    - The value of the fields required to fill in:
//      ** UnitOfMeasureLink            - DefinedType.PackageEDLItems - reference to the unit of measurement
//      ** UnitOfMeasurementCodeOceania           - String - Oceania unit code
//      ** UnitOfMeasurementName      - String - Presentation Of The unit of measurement
//      ** LogisticsPackagingName - String - Presentation Of Logistics packaging
//      ** Numerator                         - Number  - Numerator
//      ** Denominator                       - Number  - Denominator
//
Procedure FillInUnitData(Val ListOfUnits, FieldValues) Export
	
	CommercialProposalsDocumentsTM.FillInUnitData(ListOfUnits, FieldValues);
	
EndProcedure

// Getting data on units of measurement for forming the EDI tree.
//
// Parameters:
//  ListOfProducts	- ValueTable - List of fields for getting barcodes. Contains columns:
//   * Products     - DefinedType.EDLProducts - Products
//   * Characteristic   - DefinedType.ItemsCharacteristicEDL - characteristics of the nomenclature
//   * UnitOfMeasure - DefinedType.PackageEDLItems - Unit
//   * Barcode         - String - Barcode
//
Procedure FillInDataOfProductBarcodes(ListOfProducts) Export
	
	CommercialProposalsDocumentsTM.FillInDataOfProductBarcodes(ListOfProducts);
	
EndProcedure

// Getting information About the partner by counterparty.
//
// Parameters:
//  Counterparty - DefinedType.EDLCounterparty - Link to the counterparty.
//  Partner    - DefinedType.PartnerOfEDL - link to the partner.
//
Procedure GetCounterpartyPartner(Val Counterparty, Partner) Export
	CommercialProposalsDocumentsTM.GetCounterpartyPartner(Counterparty, Partner);
EndProcedure

// Ability to implement filling in the contact person details of the document, according to the transmitted contact person data.
//
// Parameters:
//  Counterparty             - DefinedType.EDLCounterparty - counterparty of the document.
//  ContactPersonDetails  - Structure - contains the following fields:
//    * LastFirstName              - String - last name, first name and patronymic.
//    * Email - String - email address.
//    * Phone          - String - phone number.
//  ContactPerson         - DefinedType.ContactPersonOnCommercialProposals - contact person of the document.
//
Procedure FillInContactPersonOfDocumentAccordingToElectronicDocument(Counterparty, ContactPersonDetails, ContactPerson) Export
	
	CommercialProposalsDocumentsTM.FillInContactPersonOfDocumentAccordingToElectronicDocument(Counterparty, ContactPersonDetails, ContactPerson);
	
EndProcedure

// Creates a structure that describes the data of the organization or counterparty.
//
// Parameters:
//  Member        - DefinedType.Organization, DefinedType.EDLCounterparty - one of the sides of the commercial offer.
//  ParticipantData - Structure - data of the participant of commercial offers for placement in a tree:
//   * Ref           - DefinedType.Organization, DefinedType.EDLCounterparty - a reference to a directory element.
//   * Description     - String - name of the counterparty or organization.
//   * LegalAddress - String - legal address of the counterparty or organization.
//   * Kind              - Structure - if it is an individual entrepreneur, then "INN, first Name, Last name, patronymic",
//                                     if it is a legal Entity, then "INN, KPP".
//
Procedure DataOfParticipantOfCommercialOffers(Val Member, ParticipantData) Export
	
	CommercialProposalsDocumentsTM.DataOfParticipantOfCommercialOffers(Member, ParticipantData);
	
EndProcedure

// Fills in the address and FIAS code representation for the defined type of storecommercial offers.
//
// Parameters:
//  Warehouse        - DefinedType.WarehousesCommercialProposals - link to the warehouse.
//  AddressData - Structure - data of the participant of commercial offers for placement in a tree:
//   * Presentation - String - text representation of the address.
//   * Code           - String - FIAS ID.
//
Procedure FillInWarehouseAddress(Val Warehouse, AddressData) Export
	
	CommercialProposalsDocumentsTM.FillInWarehouseAddress(Warehouse, AddressData);
	
EndProcedure

// Allows you to change the receipt of the unit of measurement if
// the unit of measurement may not always be filled in in the application logic.
//
// Parameters:
//  QueryText - String - the text of the request to get the unit of measurement, by default " Products.Units of measurement".
//
Procedure GetTextOfRequestToGetUnitOfMeasurement(QueryText) Export
	
	CommercialProposalsDocumentsTM.GetTextOfRequestToGetUnitOfMeasurement(QueryText);
	
EndProcedure

// Allows you to override the filling in of the "Comparison Requested offered" layout in
//	the "Vendor's Commercial Offer" and "Customer's Commercial Offer" documents.
//
// Parameters:
//  Parameters  - Structure - the fill parameters of the layout
//  QueryStringData  - FormDataCollectionItem - string data Requested.
//  CurrentRowData    - FormDataCollectionItem - data lines are Suggested.
//
Procedure WhenFillingInComparisonParametersItIsRequestedThat(Parameters, QueryStringData, CurrentRowData) Export
	
	CommercialProposalsDocumentsTM.WhenFillingInComparisonParametersItIsRequestedThat(Parameters, QueryStringData, CurrentRowData);
	
EndProcedure

// Allows you to define additional actions after adding lines from the request for commercial offers by command
// in the form of the document "Commercial offer to the client".
//
// Parameters:
//  Form                                 - ClientApplicationForm - the form in which the event occurred,
//  ArrayOfIDsOfAddedRows - Array of String - indicates the added rows.
//
Procedure AfterAddingLinesFromRequestToCommercialOfferToClient(Form, ArrayOfIDsOfAddedRows) Export
	
	CommercialProposalsDocumentsTM.AfterAddingLinesFromRequestToCommercialOfferToClient(Form, ArrayOfIDsOfAddedRows);
	
EndProcedure

// It is intended for organizing the output of a bar code to the printed form of a document.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - a tabular document that forms the printed form of the document.
//  Template             - SpreadsheetDocument - the layout that is used to form the printed form.
//  TemplateArea     - SpreadsheetDocument - the area of the table document layout that contains the image
//                                          that will display the document's bar code.
//  PrintData      - Structure - contains data for the object to print.
//
Procedure WhenDisplayingBarCodeInPrintedForms(SpreadsheetDocument, Template, TemplateArea, PrintData) Export
	
	CommercialProposalsDocumentsTM.WhenDisplayingBarCodeInPrintedForms(SpreadsheetDocument, Template, TemplateArea, PrintData);
	
EndProcedure

// Allows you to redefine the output of the title of the printed form of the document " Commercial offer to the client"
//
// Parameters:
//  Template         - SpreadsheetDocument - layout of the printed form,
//  TemplateArea - SpreadsheetDocument - the layout area that contains the title of the printed form.
//  ObjectData - Structure - contains the document data.
//
Procedure WhenFormingTitleOfPrintedForm(Template, TemplateArea, ObjectData) Export
	
	CommercialProposalsDocumentsTM.WhenFormingTitleOfPrintedForm(Template, TemplateArea, ObjectData);
	
EndProcedure

// Allows you to add data when printing for a row in the table part Products
//
// Parameters:
//  RowOfProductsTable - Structure - print data for the line.
//  LineProducts_        - ValueTableRow - data string for generating print data
//  ObjectData       - Structure - contains the document data.
//
Procedure AddObjectDataForPrinting(RowOfProductsTable, LineProducts_, ObjectData) Export
	
	CommercialProposalsDocumentsTM.AddObjectDataForPrinting(RowOfProductsTable, LineProducts_, ObjectData);
	
EndProcedure

// Allows you to redefine the formation of the print data structure in the document " Commercial offer to the client"
//
// Parameters:
//  ObjectsArray           - Array of DocumentRef - print objects.
//  DataStructureForPrinting - Undefined - here you need to put the generated data in the form of a structure.
//  PrintParameters          - Structure - print settings.
//  StandardProcessing     - Boolean - must be set to False if an override is performed.
//
Procedure CommercialOfferToClientWhenFormingPrintDataStructure(ObjectsArray, DataStructureForPrinting, PrintParameters, StandardProcessing) Export
	
	CommercialProposalsDocumentsTM.CommercialOfferToClientWhenFormingPrintDataStructure(
		ObjectsArray,
		DataStructureForPrinting,
		PrintParameters,
		StandardProcessing);
	
EndProcedure

// Allows you to redefine the output of a line in the products table part in the "Commercial offer to customer" document"
//
// Parameters:
//  SpreadsheetDocument              - SpreadsheetDocument - to which the output is made.
//  LineProducts_                   - ValueTableRow - data string for generating print data.
//  AreaRowOfProductsTable     - SpreadsheetDocument - area of the product table row.
//  NamedAreaStringProducts - String - name of the area to output to.
//  AdditionalOutputParameters  - Undefined - provides the ability to save data for multiple calls to this procedure.
//  StandardProcessing           - Boolean - must be set to False if an override is performed.
//
Procedure WhenDisplayingLineInPrintedForm(SpreadsheetDocument, LineProducts_, AreaRowOfProductsTable, NamedAreaStringProducts, AdditionalOutputParameters, StandardProcessing) Export
	
	CommercialProposalsDocumentsTM.WhenDisplayingLineInPrintedForm(SpreadsheetDocument, 
	                                                                      LineProducts_, 
	                                                                      AreaRowOfProductsTable, 
	                                                                      NamedAreaStringProducts, 
	                                                                      AdditionalOutputParameters, 
	                                                                      StandardProcessing);
	
EndProcedure

// Gets information about the organization by the link.
//
// Parameters:
//  Organization - DefinedType.Organization - a link to the reference list element that is used for getting data.
//  InformationRecords - Structure - Returned Data:
//   * FullDescr      - String - full name.
//   * Description            - String - name.
//   * LegalAddress        - String - representation of the legal address.
//   * Phones                - String - representation of phone numbers.
//   * Email        - String - email view.
//
Procedure FillInOrganizationData(Val Organization, InformationRecords) Export

	CommercialProposalsDocumentsTM.FillInOrganizationData(Organization, InformationRecords);
	
EndProcedure

// Allows you to override getting the unit of measurement as the default element.
// 
// Parameters:
//  UnitOfMeasure - Undefined, DefinedType.PackageEDLItems - You must fill 
//	in the default unit.
Procedure WhenDefiningDefaultUnitOfMeasurement(UnitOfMeasure) Export
	
	CommercialProposalsDocumentsTM.WhenDefiningDefaultUnitOfMeasurement(UnitOfMeasure);
	
EndProcedure

#Region FormCommands

// Initialization commands of the form.
// Used for implementing application logic for managing form commands.
//
// Parameters:
//  EventName - String - the key of the event name, for example, "add a command to create a Base".
//  ObjectName - String - the name of the metadata object, e.g. "Realizationduring".
//  Context   - Arbitrary - the context initialization.
//  Result  - Arbitrary - return result.
//  Parameters  - Arbitrary - initialization parameter.
//
Procedure InitializingFormCommands(EventName, ObjectName, Context, Result = Undefined, Parameters = Undefined) Export
	
	CommercialProposalsDocumentsTM.InitializingFormCommands(EventName, ObjectName, Context, Result, Parameters);
	
EndProcedure

#EndRegion

#Region CopyRows

// Allows you to override actions when inserting lines from the clipboard in the "Commercial offer to customer" document.
// 
// Parameters:
//  Form                - ClientApplicationForm - the form of the document where the lines from the clipboard were inserted.
//  RowsCount      - Number                      - in case of redefinition, you need to put information about the copied number of rows.
//  StandardProcessing - Boolean                     - must be set to False if an override is performed. 
//
Procedure WhenPastingLinesFromClipboard(Form, RowsCount, StandardProcessing) Export
	
	CommercialProposalsDocumentsTM.WhenPastingLinesFromClipboard(Form, RowsCount, StandardProcessing);
	
EndProcedure

// Allows you to redefine actions when copying lines to the clipboard in the "Commercial offer to customer"document.
// 
// Parameters:
//  Form                - ClientApplicationForm - the document form from which lines are copied from the clipboard.
//  TabularSection       - FormDataStructure       - the table part from which rows are copied.
//  SelectedRows     - Array of LineOfATabularSection - the copied row.
//  TabularSectionName    - String                     - name of the table part.
//  StandardProcessing - Boolean                     - must be set to False if an override is performed. 
//
Procedure WhenCopyingLinesToClipboard(Form, TabularSection, SelectedRows, TabularSectionName, StandardProcessing) Export
	
	CommercialProposalsDocumentsTM.WhenCopyingLinesToClipboard(Form, TabularSection, SelectedRows, TabularSectionName, StandardProcessing);
	
EndProcedure

#EndRegion

#EndRegion
