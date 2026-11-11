
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("TypeOfBaseDocumentForNonConformanceCertificate",
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage"));
	
	OpenForm("Document.DiscrepancyReportFollowingShipment.ListForm", FormParameters,
		CommandExecuteParameters.Source, "GoodsShipmentFromStorage", CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion

