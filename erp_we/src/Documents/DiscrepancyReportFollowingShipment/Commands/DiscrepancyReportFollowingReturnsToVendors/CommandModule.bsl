

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure("TypeOfBaseDocumentForNonConformanceCertificate",
	                                 PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor"));
	OpenForm("Document.DiscrepancyReportFollowingShipment.ListForm",
	            FormParameters,
	            CommandExecuteParameters.Source,
	            "ReturnToVendor",
	            CommandExecuteParameters.Window, 
	            CommandExecuteParameters.URL);

EndProcedure

#EndRegion

