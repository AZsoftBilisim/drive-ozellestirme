
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure("TypeOfBaseDocumentForNonConformanceCertificate",
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage"));
	
	OpenForm("Document.DiscrepancyReportFollowingReceipt.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		"GoodsReceiptForStorage",
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);

EndProcedure

#EndRegion
