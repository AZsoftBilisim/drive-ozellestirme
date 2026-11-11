////////////////////////////////////////////////////////////////////////////////
// Subsystem "Commercial offers documents".
// General module.Commercial propositiondocumentreferencesexternal links
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region FormEventHandlers

// Occurs on the client before writing an object from the form.
//
// Parameters:
//  Form - ClientApplicationForm - form of the object being recorded,
//  Cancel - Boolean - flag for refusing to write,
//  WriteParameters - Structure - structure containing the record parameters.
//
Procedure BeforeWrite(Form, Cancel, WriteParameters) Export
	
	CommercialProposalsDocumentsClientTM.BeforeWrite(Form, Cancel, WriteParameters);
	
EndProcedure

// Called in all created forms when the Notify method is called.
//
// Parameters:
//  Form - ClientApplicationForm - notifiable form,
//  EventName - String - event name,
//  Parameter - Arbitrary - the parameter of the message. Any necessary data can be transmitted,
//  Source - Arbitrary - event source.
//
Procedure NotificationProcessing(Form, EventName, Parameter, Source) Export
	
EndProcedure

// Called in all created forms when the Notify method is called.
//
// Parameters:
//  Form - ClientApplicationForm - notifiable form,
//  EventName - String - event name,
//  Parameter - Arbitrary - the parameter of the message. Any necessary data can be transmitted,
//  Source - Arbitrary - event source.
//
Procedure HandlingNotificationOfListForms(Form, EventName, Parameter, Source) Export
	
EndProcedure

// Occurs in forms when an external event is received.
//
// Parameters:
//  Form    - ClientApplicationForm - the form in which the external event occurred,
//  Source - String - the source of external events,
//  Event  - String - the name of the event,
//  Data   - String - the data for the event.
//
Procedure ExternalEvent(Form, Source, Event, Data) Export
	
	CommercialProposalsDocumentsClientTM.ExternalEvent(Form, Source, Event, Data);
	
EndProcedure

// Occurs when the opening of the forms.
//
// Parameters:
//  Form - ClientApplicationForm - form of the object being recorded,
//  Cancel - Boolean - indicates that the recording was rejected.
//
Procedure OnOpen(Form, Cancel) Export
	
	CommercialProposalsDocumentsClientTM.OnOpen(Form, Cancel);
	
EndProcedure

// Occurs when closing forms.
//
// Parameters:
//  Form - ClientApplicationForm - the shape of the object being recorded.
//  Exit - Boolean - indicates whether the app is shutting down.
//
Procedure OnClose(Form, Exit) Export
	
	CommercialProposalsDocumentsClientTM.OnClose(Form, Exit)
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

// Performs actions when changing the item in the Products table.
//
// Parameters:
//  Form                   - ClientApplicationForm - the form in which the event occurred.
//  CurrentRow           - FormDataCollectionItem - a row in the product table.
//  CurrentItem - String - Name of the changed field in the current line,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingProducts(Form, CurrentRow, CurrentItem, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingProducts(Form, CurrentRow, CurrentItem, ServerCallRequired__);
	
EndProcedure

// Performs actions when changing a characteristic in the Products table.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow - FormDataCollectionItem - Row of the table products,
//  CurrentItem - String - Name of the changed field in the current line,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingCharacteristics(Form, CurrentRow, CurrentItem, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingCharacteristics(Form, CurrentRow, CurrentItem, ServerCallRequired__);
	
EndProcedure

// Performs actions when changing the unit of measurement in the Products table.
//
// Parameters:
//	Form					- ClientApplicationForm - the form in which the event occurred.
//	CurrentRow			- FormDataCollectionItem 	- Row of the table products,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingUnitOfMeasurement(Form, CurrentRow, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingUnitOfMeasurement(Form, CurrentRow, ServerCallRequired__);
	
EndProcedure

// Performs actions when changing the quantity in the Products table.
//
// Parameters:
//	Form					- ClientApplicationForm - the form in which the event occurred.
//	CurrentRow			- FormDataCollectionItem - Row of the table products,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingQuantity(Form, CurrentRow, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingQuantity(Form, CurrentRow, ServerCallRequired__);
	
EndProcedure

// Performs actions when the price changes in the Products table.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow - FormDataCollectionItem - Row of the table products,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenPriceChanges(Form, CurrentRow, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenPriceChanges(Form, CurrentRow, ServerCallRequired__);
	
EndProcedure

// Performs actions when changing the type of price in the Products table.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow - FormDataCollectionItem - Row of the table products,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingPriceType(Form, CurrentRow, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingPriceType(Form, CurrentRow, ServerCallRequired__);
	
EndProcedure

// Performs actions when changing the amount in the Products table.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow - FormDataCollectionItem - Row of the table products,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingAmount(Form, CurrentRow, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingAmount(Form, CurrentRow, ServerCallRequired__);
	
EndProcedure

// Performs actions when changing the VAT rate in the Products table.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow - FormDataCollectionItem - Row of the table products,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingVATRate(Form, CurrentRow, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingVATRate(Form, CurrentRow, ServerCallRequired__);
	
EndProcedure

// Performs actions when changing the VAT amount in the Products table.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow - FormDataCollectionItem - Row of the table products,
//  PriceIncludesVAT - Boolean - indicates that the price includes VAT,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingVATAmount(Form, CurrentRow, PriceIncludesVAT, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingVATAmount(Form, CurrentRow, ServerCallRequired__);
	
EndProcedure

// Performs actions when VAT taxation changes.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingVATTaxation(Form, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingVATTaxation(Form, ServerCallRequired__);
	
EndProcedure

// Performs actions when the VAT inclusion attribute is changed in the Price.
//
// Parameters:
//  Form           - ClientApplicationForm - the form in which the event occurred,
//  Taxation - Boolean - indicates that the sale or purchase is subject to VAT,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure OnChangePriceIncludesVAT(Form, Taxation, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.OnChangePriceIncludesVAT(Form, ServerCallRequired__);
	
EndProcedure

// Performs actions when a partner (customer or supplier) changes in the document form.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingPartner(Form, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingPartner(Form, ServerCallRequired__);
	
EndProcedure

// Performs actions when the counterparty changes in the document form.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingCounterparty(Form, ServerCallRequired__ = False) Export
	
EndProcedure

// Performs actions when changing the currency in the document form.
//
// Parameters:
//  Form                   - ClientApplicationForm - the form in which the event occurred,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingCurrency(Form, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingCurrency(Form, ServerCallRequired__);
	
EndProcedure

// Performs actions when changing the validity period of a commercial offer in the form of a document.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  CurrentDate   - Date - current date,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingValidityPeriodOfCommercialOffer(Form, CurrentDate, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingValidityPeriodOfCommercialOffer(Form, CurrentDate, ServerCallRequired__);
	
EndProcedure

// Performs actions when changing a business transaction in the document form.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenBusinessTransactionChanges(Form, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenBusinessTransactionChanges(Form, ServerCallRequired__);
	
EndProcedure

// Performs actions when changing the flag can be redeemed partially in the form of a document.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingFlagCanBeRedeemedPartially(Form, ServerCallRequired__ = False) Export
	
EndProcedure

// Performs actions when the Manager changes in the document form.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingManager(Form, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingManager(Form, ServerCallRequired__);
	
EndProcedure

// Performs actions when changing the contact person in the document form.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingContactPerson(Form, ServerCallRequired__ = False) Export
	
EndProcedure

// Performs actions when the status changes in the document form.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  CurrentDate   - Date - current date,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenStatusChanges(Form, CurrentDate, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenStatusChanges(Form, CurrentDate, ServerCallRequired__);
	
EndProcedure

// Performs actions when the organization changes in the document form.
//
// Parameters:
//  Form         - ClientApplicationForm - the form in which the event occurred,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenOrganizationChanges(Form, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenOrganizationChanges(Form, ServerCallRequired__);
	
EndProcedure

// Performs actions when selecting in the table part of the document form.
//
// Parameters:
//  Form                - ClientApplicationForm - the form in which the event occurred.
//  Item              - FormTable - element of the form where the event occurred.
//  RowSelected      - Number - ID of the selected line.
//  Field                 - FormField - active column of the table part.
//  StandardProcessing - Boolean - indicates whether standard event processing is being performed.
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure TabularPartSelection(Form, Item, RowSelected, Field, StandardProcessing, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.TabularPartSelection(Form, Item, RowSelected, Field, StandardProcessing, ServerCallRequired__);
	
EndProcedure

// Performs actions before deleting in the table part of the document form.
//
// Parameters:
//  Form                - ClientApplicationForm - the form in which the event occurred,
//  Item              - FormTable - the form in which the event occurred,
//  CurrentData        - FormDataCollectionItem - data of the deleted row,
//  Cancel                - Boolean - indicates that the operation was rejected.
//
Procedure GoodsBeforeDeleteRow(Form, Item, CurrentData, Cancel) Export
	
	CommercialProposalsDocumentsClientTM.GoodsBeforeDeleteRow(Form, Item, CurrentData, Cancel);
	
EndProcedure

#EndRegion

#Region FillingInDeliveryTerms

// The ability to define the payment terms in the document "Commercial offer to the client".
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the command is executed.
//
Procedure WhenExecutingCommandFillInPaymentTerms(Form) Export
	
	CommercialProposalsDocumentsClientTM.WhenExecutingCommandFillInPaymentTerms(Form);
	
EndProcedure

// Ability to determine the completion of delivery terms in the document "Commercial offer to the client".
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the command is executed.
//
Procedure WhenExecutingCommandFillInDeliveryTerms(Form) Export
	
EndProcedure

#EndRegion

#Region FillingInTablePartGoods

// Opens the item selection form.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the open mapping processing command is called.
//  NotificationOnCompletion - CallbackDescription - the procedure that is called when the form is closed the selection.
//
Procedure OpenProductSelectionForm_(Form, NotificationOnCompletion = Undefined) Export
	
	CommercialProposalsDocumentsClientTM.OpenProductSelectionForm_(Form, NotificationOnCompletion);
	
EndProcedure

// Opens the form for uploading data from external files
//
// Parameters:
//  Form                    - ClientApplicationForm - the form from which the upload was initiated.
//  NotificationOnCompletion  - CallbackDescription - the procedure for processing the closing of the upload form.
//
Procedure OpenUploadFormFromExternalFiles(Form, NotificationOnCompletion = Undefined) Export
	
	CommercialProposalsDocumentsClientTM.OpenUploadFormFromExternalFiles(Form, NotificationOnCompletion);
	
EndProcedure

// Calls the selection processing procedure if there was a selection from the selection form.
//
// Parameters:
//  Form                   - ClientApplicationForm - the form that received the selection event,
//  NotificationOnCompletion - CallbackDescription - the procedure of completion of the selection item,
//  ValueSelected       - Arbitrary - the result of the selection in the subform,
//  ChoiceSource          - ClientApplicationForm - the form where the selection was made.
//
Procedure SelectionProcessingProductSelection(Form, NotificationOnCompletion, ValueSelected, ChoiceSource) Export
	
	CommercialProposalsDocumentsClientTM.SelectionProcessingProductSelection(Form, NotificationOnCompletion, ValueSelected, ChoiceSource);
	
EndProcedure

// Calls the selection processing procedure if an alert from the selection form occurred.
//
// Parameters:
//  Form                   - ClientApplicationForm   - the form that received the selection event,
//  NotificationOnCompletion - CallbackDescription - the procedure of completion of the selection of the item.
//  EventName              - String         - name of the event that is being notified.
//  Parameter                - Arbitrary     - parameter passed to the message.
//  Source                - ClientApplicationForm - the form in which the notification occurred.
//
Procedure ProcessingAndSelectionOfProducts(Form, NotificationOnCompletion, EventName, Parameter, Source) Export
	
	CommercialProposalsDocumentsClientTM.ProcessingAndSelectionOfProducts(Form, NotificationOnCompletion, EventName, Parameter, Source);
	
EndProcedure

// Performs actions when notification of the selection of the item after the server call.
//
// Parameters:
//  Form                   - ClientApplicationForm - the form in which the event occurred,
//  ValueSelected       - Arbitrary - result of the action that the notification was sent about,
//  ProcessingResult      - Arbitrary - result of processing on the server,
//  AdditionalParameters - Structure, Undefined - additional notification parameters.
//
Procedure AfterProcessingAndSelectingProducts(Form, ValueSelected, ProcessingResult, AdditionalParameters) Export
	
	CommercialProposalsDocumentsClientTM.AfterProcessingAndSelectingProducts(Form, ValueSelected, ProcessingResult, AdditionalParameters);

EndProcedure

// Performs actions when notifying about the selection of an item.
//
// Parameters:
//  Form                   - ClientApplicationForm - the form in which the event occurred,
//  Result               - Arbitrary - result of the action that the notification was sent about,
//  AdditionalParameters - Structure, Undefined - additional notification parameters,
//  ServerCallRequired__ - Boolean - indicates whether a server call is required.
//
Procedure AfterProductSelectionProcess(Form, Result, AdditionalParameters, ServerCallRequired__) Export
	
	CommercialProposalsDocumentsClientTM.AfterProductSelectionProcess(Form, Result, AdditionalParameters, ServerCallRequired__);
	
EndProcedure

// In the procedure, you need to show a dialog box for entering a barcode and pass the received data to the notification description.
//
// Parameters:
//  Notification - CallbackDescription - the procedure that should be called after the input of the barcode.
//
Procedure ShowBarcodeInput(Notification) Export
	
	CommercialProposalsDocumentsClientTM.ShowBarcodeInput(Notification);
	
EndProcedure

// Ability to define actions on the client after processing barcodes
//
// Parameters:
//  Form              - ClientApplicationForm - the form in which bar code processing was performed,
//  ProcessingResult - Arbitrary - the result of processing the bar codes on the server.
//
Procedure AfterProcessingBarcodes_(Form, ProcessingResult) Export
	
	CommercialProposalsDocumentsClientTM.AfterProcessingBarcodes_(Form, ProcessingResult);
	
EndProcedure

// Occurs when data is loaded from the data collection terminal.
//
// Parameters:
//  Form                 - ClientApplicationForm - form that starts loading data from the TSD,
//  CallbackOnCompletion - CallbackDescription - procedure for processing the completion of data loading from the TSD.
//
Procedure StartLoadingDataFromTSD(Form, CallbackOnCompletion) Export
	
	CommercialProposalsDocumentsClientTM.StartLoadingDataFromTSD(Form, CallbackOnCompletion);
	
EndProcedure

// It is intended for processing data downloaded from the collection terminal.
//
// Parameters:
//  CallbackOnCompletion   - CallbackDescription - the procedure is complete, load the data from the TSD.
//  Form                   - ClientApplicationForm - the form that starts loading data from the TSD.
//  ExecutionResult     - Arbitrary - received data from the TSD.
//
Procedure WhenReceivingDataFromTSD(CallbackOnCompletion, Form, ExecutionResult) Export
	
	CommercialProposalsDocumentsClientTM.WhenReceivingDataFromTSD(CallbackOnCompletion, ThisObject, ExecutionResult);
	
EndProcedure

// Performs all actions after server processing of the selection in the table part of the document form.
//
// Parameters:
//  Form                - ClientApplicationForm - the form in which the event occurred,
//  FieldName              - String - name of the field where the event occurred,
//  ProcessingResult   - Arbitrary - result of server processing.
//
Procedure AfterCompletingGoodsSelection(Form, FieldName, ProcessingResult) Export
	
	CommercialProposalsDocumentsClientTM.AfterCompletingGoodsSelection(Form, FieldName, ProcessingResult);
	
EndProcedure

#EndRegion

#Region CommercialProposalForCustomer

// It is intended for implementation of the "Fill in prices according to terms of sale" command in the "Commercial offer to the client" document.
//
// Parameters:
//  Form              - ClientApplicationForm - the form in which the command was executed.
//  ChoiceNotification1  - CallbackDescription - notification that will process the selection of the sales condition.
//
Procedure WhenExecutingCommandFillInPricesAccordingToTermsOfSale(Form, ChoiceNotification1) Export
	
	CommercialProposalsDocumentsClientTM.WhenExecutingCommandFillInPricesAccordingToTermsOfSale(Form, ChoiceNotification1);
	
EndProcedure

// It is intended for implementing the command "Fill in prices by type of prices" in the document "Commercial offer to the client".
//
// Parameters:
//  Form              - ClientApplicationForm - form in which the command is executed,
//  ChoiceNotification1  - CallbackDescription - notification that will process the selection of the price type.
//
Procedure WhenExecutingCommandFillInPricesByPriceType(Form, ChoiceNotification1) Export
	
	CommercialProposalsDocumentsClientTM.WhenExecutingCommandFillInPricesByPriceType(Form, ChoiceNotification1);
	
EndProcedure

// It is intended for implementing the "Calculate discounts" command in the "Commercial offer to the client" document.
//
// Parameters:
//  Form                   - ClientApplicationForm - the form in which the command is executed,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenExecutingCalculateDiscountsCommand(Form, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenExecutingCalculateDiscountsCommand(Form, ServerCallRequired__);
	
EndProcedure

// It is intended for determining actions on the client after calculating discounts in the document "Commercial offer to the client".
//
// Parameters:
//  Form            - ClientApplicationForm - form in which the command is executed,
//  CalculationResult2 - Arbitrary - data about the results of the completed discount calculation.
//
Procedure AfterCalculatingDiscounts(Form, CalculationResult2) Export
	
	CommercialProposalsDocumentsClientTM.AfterCalculatingDiscounts(Form, CalculationResult2);
	
EndProcedure

// It is intended for implementing the "Assign automatic discounts" command in the "Commercial offer to customer" document.
//
// Parameters:
//  Form                     - ClientApplicationForm - form in which the command is executed,
//  CallbackOnCompletion     - CallbackDescription - the procedure, which will be returned in the results array,
//  ServerCallRequired__   - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenExecutingAssignAutomaticDiscountsCommand(Form, CallbackOnCompletion, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenExecutingAssignAutomaticDiscountsCommand(
		Form, CallbackOnCompletion, ServerCallRequired__);
	
EndProcedure

// It is intended for defining actions on the client after selecting the automatic discounts assigned by the team in the "Commercial offer to the client" document.
//
// Parameters:
//  Form                   - ClientApplicationForm - form in which the command is executed,
//  Result               - Arbitrary - data about selected discounts,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure AfterAssigningAutomaticDiscount(Form, Result, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.AfterAssigningAutomaticDiscount(
		Form, Result, ServerCallRequired__);
	
EndProcedure

// It is intended for defining actions on the client after calculating the assigned automatic discounts of the team in the document "Commercial offer to the client".
//
// Parameters:
//  Form     - ClientApplicationForm - form in which the command is executed,
//  Result - Arbitrary     - data on the calculation of discounts.
//
Procedure AfterCalculatingAssignedAutomaticDiscounts(Form, Result) Export
	
	CommercialProposalsDocumentsClientTM.AfterCalculatingAssignedAutomaticDiscounts(Form, Result);
	
EndProcedure

// It is intended for implementing the "Assign automatic discounts" command in the "Commercial offer to customer" document,
// if a server call is required before assigning discounts.
//
// Parameters:
//  Form                    - ClientApplicationForm - form in which the command is executed,
//  CallbackOnCompletion    - CallbackDescription - the procedure, which will be returned in the results array,
//  Result                - Arbitrary - the result of the training.
//
Procedure AfterPreparingAppointmentOfAutomaticDiscounts(Form, CallbackOnCompletion, Result) Export
	
	CommercialProposalsDocumentsClientTM.AfterPreparingAppointmentOfAutomaticDiscounts(Form, CallbackOnCompletion, Result);
	
EndProcedure

// It is intended for implementing the "Assign manual discount" command in the "Commercial offer to customer" document.
//
// Parameters:
//  Form                    - ClientApplicationForm - form in which the command is executed,
//  SelectedRows         - Array - array of selected rows in the table part,
//  StandardProcessing     - Boolean - if the event is overridden, it must be set to True,
//  ServerCallRequired__  - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenExecutingAssignManualDiscountCommand(Form, SelectedRows, StandardProcessing, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenExecutingAssignManualDiscountCommand(Form, SelectedRows, StandardProcessing, ServerCallRequired__);
	
EndProcedure

// It is intended for implementing the "Assign manual discount" command in the "Commercial offer to customer" document, 
// if a server call is required before executing the command.
//
// Parameters:
//  Form                                 - ClientApplicationForm - the form in which the command was executed.
//  SelectedRows                      - Array - array of selected rows in the table part.
//  NotificationAfterAssigningManualDiscount - CallbackDescription - procedure to return the result of selecting a discount to,
//  ProcessingResult                    - Arbitrary - the result of the training.
//
Procedure AfterPreparingAssignmentOfManualDiscounts(Form, SelectedRows, NotificationAfterAssigningManualDiscount, ProcessingResult) Export
	
	CommercialProposalsDocumentsClientTM.AfterPreparingAssignmentOfManualDiscounts(Form, SelectedRows, NotificationAfterAssigningManualDiscount, ProcessingResult);
	
EndProcedure

// It is intended for defining actions after the end of assigning a manual discount in the "Commercial offer to the client" document. 
//
// Parameters:
//  Form             - ClientApplicationForm  - form in which the command is executed,
//  SelectedRows  - Array - array of selected rows in the table part,
//  Result         - Arbitrary - result of selecting a manual discount.
//
Procedure AfterCompletingAssignmentOfManualDiscounts(Form, SelectedRows, Result) Export
	
	CommercialProposalsDocumentsClientTM.AfterCompletingAssignmentOfManualDiscounts(Form, SelectedRows, Result);
	
EndProcedure

// It is intended for implementing the "Cancel manual discounts" command in the "Commercial offer to customer" document.
//
// Parameters:
//  Form                    - ClientApplicationForm - form in which the command is executed,
//  SelectedRows         - Array - array of selected rows in the table part,
//  PriceIncludesVAT          - Boolean - indicates that the price includes VAT,
//  Taxation          - Boolean - indicates that the sale or purchase is subject to VAT.
//  ServerCallRequired__  - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenExecutingCancelManualDiscountsCommand(Form, SelectedRows, PriceIncludesVAT, Taxation, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenExecutingCancelManualDiscountsCommand(Form, SelectedRows, PriceIncludesVAT, Taxation, ServerCallRequired__);
	
EndProcedure

// It is intended for processing the "Cancel manual discounts" command in the "Commercial offer to customer" document.
//
// Parameters:
//  Form              - ClientApplicationForm - form in which the command is executed,
//  SelectedRows   - Array - array of selected rows in the table part,
//  ProcessingResult    - Arbitrary - the result of canceling manual discounts on the server.
//
Procedure AfterCancelingManualDiscounts(Form, SelectedRows, ProcessingResult) Export
	
	CommercialProposalsDocumentsClientTM.AfterCancelingManualDiscounts(Form, SelectedRows, ProcessingResult);
	
EndProcedure

// It is intended for implementing the "Open discount information" command in the "Commercial offer to the client" document.
//
// Parameters:
//  Form - ClientApplicationForm - form in which the command is executed,
//  ServerCallRequired__  - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenExecutingOpenDiscountInformationCommand(Form, ServerCallRequired__) Export
	
	CommercialProposalsDocumentsClientTM.WhenExecutingOpenDiscountInformationCommand(Form, ServerCallRequired__);
	
EndProcedure

// It is intended for implementing the "Open discount information" command in the "Commercial offer to the client" document in cases
// when a server call is required before opening the form.
//
// Parameters:
//  Form - ClientApplicationForm - form in which the command is executed,
//  Result  - Arbitrary - data on the results of preparing the opening of information about discounts.
//
Procedure AfterPreparingOpeningOfInformationAboutDiscounts(Form, Result) Export
	
	CommercialProposalsDocumentsClientTM.AfterPreparingOpeningOfInformationAboutDiscounts(Form, Result);
	
EndProcedure

// It is intended for implementing the "Split line" command in the "Commercial offer to the client" document.
//
// Parameters:
//  Form                 - ClientApplicationForm - the form in which the command was executed.
//  CurrentRow         - FormDataCollectionItem - a row in the product table.
//  CallbackOnCompletion - CallbackDescription - the completion routine to split the string.
//
Procedure WhenExecutingSplitLineCommand(Form, CurrentRow, CallbackOnCompletion) Export
	
	CommercialProposalsDocumentsClientTM.WhenExecutingSplitLineCommand(Form, CurrentRow, CallbackOnCompletion);
	
EndProcedure

// Performs actions when changing the percentage of a manual discount in the Products table.
//
// Parameters:
//  Form           - ClientApplicationForm - the form in which the event occurred,
//  CurrentRow   - FormDataCollectionItem - Row of the table products,
//  PriceIncludesVAT - Boolean - indicates that the price includes VAT,
//  Taxation - Boolean - indicates that the sale or purchase is subject to VAT,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingPercentageOfManualDiscount(Form, CurrentRow , PriceIncludesVAT, Taxation, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingPercentageOfManualDiscount(Form, CurrentRow, ServerCallRequired__);
	
EndProcedure

// Performs actions when changing the amount of a manual discount in the Products table.
//
// Parameters:
//  Form           - ClientApplicationForm - the form in which the event occurred.
//  CurrentRow   - FormDataCollectionItem - Row of the table products,
//  PriceIncludesVAT - Boolean - indicates that the price includes VAT,
//  Taxation - Boolean - indicates that the sale or purchase is subject to VAT,
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenChangingAmountOfManualDiscount(Form, CurrentRow, PriceIncludesVAT, Taxation, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenChangingAmountOfManualDiscount(Form, CurrentRow, ServerCallRequired__);
	
EndProcedure

// Performs actions for the redefined command in the "Commercial offer to customer" document.
//
// Parameters:
//  Form                   - ClientApplicationForm - the form in which the event occurred.
//  Command                 - FormCommand   - completed form command.
//  ServerCallRequired__ - Boolean - Indicates that an overridable server call is required.
//
Procedure WhenExecutingOverridableCommand(Form, Command, ServerCallRequired__ = False) Export
	
	CommercialProposalsDocumentsClientTM.WhenExecutingOverridableCommand(Form, Command, ServerCallRequired__);
	
EndProcedure

// Ability to define actions after executing the redefined command in the "Commercial offer to the client" document.
//
// Parameters:
//  Form      - ClientApplicationForm - the form in which the event occurred.
//  Command    - FormCommand     - completed form command.
//  Result  - Arbitrary     - the result of executing the command.
//
Procedure AfterExecutingRedefinedCommand(Form, Command, Result) Export

	CommercialProposalsDocumentsClientTM.AfterExecutingRedefinedCommand(Form, Command, Result);

EndProcedure

// Performs actions for the redefined integration command with "1C: document Flow" in the document "Commercial offer to the client".
//
// Parameters:
//  Command   - FormCommand   - the command is of the form,
//  Form     - ClientApplicationForm - the form in which the event occurred,
//  Object    - FormDataCollection - data of the object document.
//
Procedure ExecutePlugInIntegrationCommand(Command, Form, Object) Export
	
	CommercialProposalsDocumentsClientTM.ExecutePlugInIntegrationCommand(Command, Form, Object);
	
EndProcedure

// It is intended for showing a question to the user about the need to calculate discounts before writing in the document "Commercial offer to the client".
//
// Parameters:
//  Form                   - ClientApplicationForm - the form in which the event occurred,
//  Cancel                   - Boolean - flag for refusing to write,
//  NotificationAfterClose - CallbackDescription - notification of the user's response to a question.
//
Procedure SuggestUserToCalculateDiscounts(Form, Cancel, NotificationAfterClose) Export
	
	CommercialProposalsDocumentsClientTM.SuggestUserToCalculateDiscounts(Form, Cancel, NotificationAfterClose);
	
EndProcedure

#EndRegion

#Region SupplierSCommercialOffer

// It is intended for the implementation of the command "Fill in Price Types" in the document "commercial offer of the supplier".
// The result of the method should be a link to The Price Type passed to the notification.
//
// Parameters:
//  Form				 - ClientApplicationForm - the form from which the discovery came.
//  CallbackDescription	 - CallbackDescription - description of the selection processing procedure.
//
Procedure WhenExecutingCommandFillInSupplierSPriceTypes(Form, CallbackDescription) Export
	
	CommercialProposalsDocumentsClientTM.WhenExecutingCommandFillInSupplierSPriceTypes(Form, CallbackDescription);
	
EndProcedure

// Defines the use of orders to suppliers
// 
// Parameters:
//  UsePurchaseOrders - Boolean - Use orders to suppliers
Procedure UsePurchaseOrders(UsePurchaseOrders) Export

EndProcedure

#EndRegion

// Opens the source for analyzing commercial offers.
//
// Parameters:
//  SourceType - String - defines the source type.
//  Source - Arbitrary - source.
//  SourceLineNumber_ - String - position number in the source.
//
Procedure ShowSourceForm(SourceType, Source, SourceLineNumber_) Export

EndProcedure

// Opens the date selection form
//
// Parameters:
//  SelectedDate        - Date - The currently selected date,
//  CallbackDescription   - CallbackDescription - Notification to return the selected date
//  StandardProcessing - Boolean - if the event is overridden, it must be set to True.
//
Procedure ShowDateSelection(SelectedDate, CallbackDescription, StandardProcessing) Export
	
	
EndProcedure

// Opens the order form for the supplier
//
// Parameters:
//  ReferencesArrray  - Array - List of orders.
//
Procedure OpenSupplierOrderListForm(Val ReferencesArrray) Export
	
	CommercialProposalsDocumentsClientTM.OpenSupplierOrderListForm(ReferencesArrray);
	
EndProcedure

// Defines the key for filling in data when creating a counterparty for automatically filling in Attributes.
// 
// Parameters:
//  FillingDataKey - String - Key of the filling data structure
Procedure SetFillingDataKeyWhenCreatingCounterparty(FillingDataKey) Export
	FillingDataKey = "Basis";
EndProcedure

#EndRegion
