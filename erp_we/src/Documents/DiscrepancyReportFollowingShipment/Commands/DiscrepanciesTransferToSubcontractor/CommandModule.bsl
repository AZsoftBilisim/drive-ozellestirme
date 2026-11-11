

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure;
	FormParameters.Insert(
		"TypeOfBaseDocumentForNonConformanceCertificate",
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor"));
	
	OpenForm(
		"Document.DiscrepancyReportFollowingShipment.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		"GoodsTransferToSubcontractor",
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
		Return; // The UT handler is empty
		
EndProcedure

#EndRegion