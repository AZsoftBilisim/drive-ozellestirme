
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("PurposeUseKey", "DocumentsOfAcceptanceForProcessing");
	
	OpenForm("DataProcessor.LogOfIntercompanyDocuments.Form.RegisterTransfersAndRedemptions",
		FormParameters,
		CommandExecuteParameters.Source,
		"PurchaseDocumentsAll",
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion