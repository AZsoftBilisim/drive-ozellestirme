////////////////////////////////////////////////////////////////////////////////
// The subsystem "Data exchange"
// is a general module.The recommended callserveroutup.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Overrides the form of the object being created to the exchange creation assistant.
Procedure WhenCreatingExchangePlanProcessingReceiptOfForm(Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export
	
	If FormType = "ObjectForm"
		And Not Parameters.Property("Key") Then
		
		StandardProcessing = False;
		
		If DataExchangeTMERP.ThisIsCreationOfExchangeNode(Source) Then
			SelectedForm = "DataProcessor.DataExchangeCreationWizard.Form.NewDataSynchronization";
			Parameters.Insert("ExchangePlanName", Source.EmptyRef().Metadata().Name);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
