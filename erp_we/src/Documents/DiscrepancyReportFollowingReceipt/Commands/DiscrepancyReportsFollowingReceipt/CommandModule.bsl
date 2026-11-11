

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure("TypeOfBaseDocumentForNonConformanceCertificate",
	                                 PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice"));
	OpenForm("Document.DiscrepancyReportFollowingReceipt.ListForm",
	            FormParameters, 
	            CommandExecuteParameters.Source,
	            "VendorInvoice",
	            CommandExecuteParameters.Window, 
	            CommandExecuteParameters.URL);

EndProcedure

#EndRegion

