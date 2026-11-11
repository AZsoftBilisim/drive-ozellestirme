
#Region Public

#Region GetAddIns

// Updates the State of Internet support elements on the form.
// 
// Parameters:
//  Form - ClientApplicationForm - Form
Procedure RefreshOnlineSupportStatus(Form) Export
	
	
EndProcedure

#EndRegion

#Region FiscalTransactions

// Complements the collection of available payment types for the document type
//
// Parameters:
//  Form - ClientApplicationForm - the form of the document:
//  * Object - DocumentObject - The main props of the form
//  AvailablePaymentMethods - Structure -
//
Procedure SupplementAvailablePaymentMethods(Form, AvailablePaymentMethods) Export
	
	
EndProcedure

// Determines whether verification of marking codes by means of KKT is required.
// 
// Parameters:
//  ParametersOfReceiptFiscalizationOperation - Structure - Parameters of the receipt fiscalization operation
// 
// Returns:
//  Boolean - True - verification of marking codes by means of KKT is required
Function VerificationOfMarkingCodesByMeansOfKKTIsRequired(ParametersOfReceiptFiscalizationOperation) Export
	
	VerificationOfMarkingCodesByMeansOfKKTIsRequired = False;
	
	
	Return VerificationOfMarkingCodesByMeansOfKKTIsRequired;
	
EndFunction


#EndRegion

#Region CachingDataOfDynamicFormDetails

// Caches table row identifiers in relation to the data of dynamic Attributes of form tables.
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure SaveDataOfDynamicAttributesOfFormTablesToCache(Form) Export

	
EndProcedure

// Retrieves data from the cache of dynamic Attributes of Form tables.
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure RecoverDataFromCacheOfDynamicDetailsOfFormTables(Form) Export

	
EndProcedure

#EndRegion


// To process the presence of a requirement to specify permits for the sale of goods.
// 
// Parameters:
//  Form - See Document.CashRegisterReceipt.Form.CWPDocumentForm
Procedure ProcessPermitsForSaleOfGoods(Form) Export
	
	
EndProcedure

#EndRegion

#Region Private


#EndRegion
