#Region Public


// Opens the form for setting up transaction templates based on operational accounting data.
// 
// Parameters:
// 	FormParameters - See FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms
// 	OwnerForm - ClientApplicationForm - Owner of the configuration form.
// 	BusinessOperation - CatalogRef.BusinessTransactionsSettings - The operation for which you want to configure.
// 	                                                                          If Undefined, then the form opens without selecting by operation.
//
Procedure OpenSettingsForTransactionTemplates(FormParameters, OwnerForm, BusinessOperation = Undefined) Export
	
	If BusinessOperation <> Undefined Then
		FormParameters.Insert("BusinessOperation", BusinessOperation);
	EndIf;
	OpenForm("DataProcessor.PostingTemplatesSetupForFinancialAccounting.Form.PostingTemplatesSetup", 
		FormParameters, OwnerForm);
	
EndProcedure

#EndRegion