

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure;
	
	FormParameters.Insert(
		"BusinessOperation",
		PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5"));
		
	FormParameters.Insert(
		"TypeOfBaseDocumentForNonConformanceCertificate",
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider"));
	
	OpenForm(
		"Document.DiscrepancyReportFollowingReceipt.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		"ReceiptFromMaterialProvider2_5",
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	Return; // The TMAR handler is empty
	
EndProcedure

#EndRegion

