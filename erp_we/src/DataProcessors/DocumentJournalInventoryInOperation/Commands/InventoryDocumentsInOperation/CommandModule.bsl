#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "CommonCommand.DocumentJournalInventoryInOperation");
		
	OpenForm(
		"DataProcessor.DocumentJournalInventoryInOperation.Form",
		,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);

EndProcedure

#EndRegion
