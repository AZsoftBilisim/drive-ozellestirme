

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure(
		"TypeOfBaseDocumentForNonConformanceCertificate",
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor"));
	
	OpenForm("Document.DiscrepancyReportFollowingReceipt.ListForm",
				FormParameters,
				CommandExecuteParameters.Source,
				"GoodsReceiptFromSubcontractor",
				CommandExecuteParameters.Window,
				CommandExecuteParameters.URL);
	Return; // The UT handler is empty
	
EndProcedure

#EndRegion

