#Region Public

// Called when the view definition, the currency of payment of the service.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
// 
// Parameters:
//  PresentationOfPaymentCurrency - String - presentation of the payment currency.
//
Procedure OnSetPaymentCurrencyPresentation(PresentationOfPaymentCurrency) Export
EndProcedure

// Called when the name of the form for processing the response to the invoice request is received.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
// 
// Parameters:
//  ResponseProcessingFormName - String - name of the response processing form.
//
Procedure OnGetResponseProcessingFormName(ResponseProcessingFormName) Export
EndProcedure

// Called when setting the service's payment settings.
// @skip-check module-empty-method 
//
// Parameters:
//  SubscriberCode - Number - code of the subscriber-owner of the accounting system
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - sign of a processing error
//   * Message - String - processing error message.
//
Procedure AtSettingServicePaymentSettings(SubscriberCode, ProcessingResult) Export
	
	
EndProcedure

// Called when the service payment settings are deleted.
// @skip-check module-empty-method 
//
// Parameters:
//  SubscriberCode - Number - code of the subscriber-owner of the accounting system
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - sign of a processing error
//   * Message - String - processing error message.
//
Procedure AtDeletingServicePaymentSettings(SubscriberCode, ProcessingResult) Export
	
	
EndProcedure

// Called when determining whether the service's tariffs can be loaded.
// @skip-warning EmptyMethod - Overridable method.
// @skip-check module-empty-method 
//   
// Parameters:
//  Result - Boolean - the result of determining the upload capability.
//  
Procedure OnDefineServicePlansImportSupport(Result) Export

	
EndProcedure

// It is called when tariffs are uploaded to the information database according to the data of the service manager.
// The method is idempotent. Repeated execution with a similar result is supported.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
//
// Parameters:
//  RawData - Structure:
//   * ProviderRates - See ServiceProgrammingInterface.ServiceRates
//   * ServiceOrganizationRates - See ServiceProgrammingInterface.ServiceOrganizationRates
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - sign of a processing error
//   * Message - String - processing error message.
//
Procedure OnImportServicePlans(RawData, ProcessingResult) Export
	
	
EndProcedure

// Called when creating a subscriber information form on the server, if they need to be filled in.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method
//  
//  Parameters:
//   RequiredInformation - Structure:
//   * HasErrors - Boolean - indicates whether there are filling errors.
//   * Attributes - ValueTable - additional Attributes of the subscriber:
//     ** Key - String - name of additional account details
//     ** Title - String - the header of the additional props
//     ** Type - String - Value type 
//     ** Value - String, Number, Date, Boolean - Value of additional details
//     ** RequiredToFill - Boolean - required field sign
//     ** ToolTip - String - filling hint
//     ** Error - Boolean - indication of a filling error
//     ** Message - String - Error message
//     ** Visible - Boolean - indicates whether it is displayed on the fill-in form
//   * Properties - ValueTable - additional subscriber properties:
//     ** Key - String - name of the additional property
//     ** Title - String - the header of the additional props
//     ** Type - String - Value type
//     ** Value - String, Number, Date, Boolean - value of the additional property
//     ** RequiredToFill - Boolean - required field sign
//     ** ToolTip - String - filling hint
//     ** Error - Boolean - indication of a filling error
//     ** Message - String - Error message
//     ** Visible - Boolean - indicates whether it is displayed on the fill-in form
//   Subscriber - See ServiceProgrammingInterface.SubscriberOfThisApplication
Procedure AtFillingInRequiredInformationForSubscribing(RequiredInformation, Subscriber) Export
	
	
EndProcedure

// Called when creating an invoice for payment upon request from the service manager.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
//
// Parameters:
//  QueryData - See ServicePayment.InvoiceRequestData
//  ProformaInvoice - DocumentRef - created payment invoice (returned data)
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - sign of a processing error
//   * Message - String - processing error message.
//
Procedure OnCreateProformaInvoice(QueryData, ProformaInvoice, ProcessingResult) Export

	
EndProcedure

// Sets the printed form of the invoice for payment.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
//
// Parameters:
//  QueryData - See ServicePayment.InvoiceRequestData
//  ProformaInvoice - DocumentRef - Invoice for payment
//  PrintForm - SpreadsheetDocument - printed form of the payment invoice (returned data)
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - sign of a processing error
//   * Message - String - processing error message.
//
Procedure OnGetProformaInvoicePrintForm(QueryData, ProformaInvoice, PrintForm, ProcessingResult) Export


EndProcedure

// Sets the binary data of the invoice for payment.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
//  
// Parameters:
//  QueryData - See ServicePayment.InvoiceRequestData
//  ProformaInvoice - DocumentRef - Invoice for payment
//  Data - BinaryData - payment invoice data (returned data)
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - sign of a processing error
//   * Message - String - processing error message.
//
Procedure OnGetProformaInvoiceDetails(QueryData, ProformaInvoice, Data, ProcessingResult) Export
	
	
EndProcedure

// Sets the value of the invoice's payment link.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
//
// Parameters:
//  QueryData - See ServicePayment.InvoiceRequestData
//  ProformaInvoice - DocumentRef - Invoice for payment
//  PaymentURL - String - payment link (returned data)
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - sign of a processing error
//   * Message - String - processing error message.
//
Procedure OnGetPaymentURL(QueryData, ProformaInvoice, PaymentURL, ProcessingResult) Export
	
	
EndProcedure

#EndRegion