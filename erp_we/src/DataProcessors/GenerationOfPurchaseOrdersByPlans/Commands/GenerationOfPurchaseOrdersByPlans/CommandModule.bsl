
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	FormParameters.Insert("FullNameOfPurchaseDocument", "Document.PurchaseOrder");
	
	OpenForm(
		"DataProcessor.GenerationOfPurchaseOrdersByPlans.Form",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion