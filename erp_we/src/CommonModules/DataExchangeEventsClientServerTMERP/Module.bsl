////////////////////////////////////////////////////////////////////////////////
// The subsystem "Data exchange"
// is a general module.The recommended eventsclientserveroutup.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Overrides the form of the object being created to the exchange creation assistant.
Procedure WhenCreatingExchangePlanProcessingReceiptOfForm(Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export
	
	DataExchangeServerCallTMERP.WhenCreatingExchangePlanProcessingReceiptOfForm(Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing);
	
EndProcedure

#EndRegion
