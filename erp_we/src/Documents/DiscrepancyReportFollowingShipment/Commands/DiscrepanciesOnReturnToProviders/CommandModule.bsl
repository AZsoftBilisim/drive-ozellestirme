#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure;
	
	FormParameters.Insert(
		"BusinessOperation",
		PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5"));
		
	FormParameters.Insert(
		"TypeOfBaseDocumentForNonConformanceCertificate",
		PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider"));
	
	OpenForm(
		"Document.DiscrepancyReportFollowingShipment.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		"ReturnToMaterialProvider2_5",
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	Return; // The TMAR handler is empty
	
EndProcedure

#EndRegion