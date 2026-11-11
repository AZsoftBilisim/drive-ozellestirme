

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure(
		"TypeOfBaseDocumentForNonConformanceCertificate",
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor"));
	
	OpenForm("Document.DiscrepancyReportFollowingReceipt.ListForm",
				FormParameters,
				CommandExecuteParameters.Source,
				"ReturnOfGoodsFromSubcontractor",
				CommandExecuteParameters.Window,
				CommandExecuteParameters.URL);
	Return; // The UT handler is empty
	
EndProcedure

#EndRegion

