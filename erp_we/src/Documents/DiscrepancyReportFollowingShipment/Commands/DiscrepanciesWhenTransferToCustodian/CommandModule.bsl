
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("TypeOfBaseDocumentForNonConformanceCertificate",
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee"));
	
	OpenForm("Document.DiscrepancyReportFollowingShipment.ListForm", FormParameters,
		CommandExecuteParameters.Source, "TransferOfGoodsToBailee", CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion

