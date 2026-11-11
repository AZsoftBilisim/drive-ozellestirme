

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure("TypeOfBaseDocumentForNonConformanceCertificate",
	                                 PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer"));
	OpenForm("Document.DiscrepancyReportFollowingReceipt.ListForm",
	            FormParameters,
	            CommandExecuteParameters.Source,
	            "ReturnFromCustomer",
	            CommandExecuteParameters.Window, 
	            CommandExecuteParameters.URL);

EndProcedure

#EndRegion
