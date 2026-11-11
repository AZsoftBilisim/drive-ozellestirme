#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfPurchaseDocuments.Command.InvoicesForPlacingOrders");
	
	OpenForm(
		"DataProcessor.LogOfPurchaseDocuments.Form.InvoicesForRegistrationList",
		,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion