
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.RecognizeAndIncludeExpensesInFixedAssetCost.Command.RecognizeAndIncludeExpensesInCost");

	OpenForm("DataProcessor.RecognizeAndIncludeExpensesInFixedAssetCost.Form",, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion