

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure("TypeOfBaseDocumentForNonConformanceCertificate",
	                                 PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice"));
	OpenForm("Document.DiscrepancyReportFollowingShipment.ListForm",
	            FormParameters, 
	            CommandExecuteParameters.Source,
	            "CustomerInvoice",
	            CommandExecuteParameters.Window, 
	            CommandExecuteParameters.URL);

EndProcedure

#EndRegion

