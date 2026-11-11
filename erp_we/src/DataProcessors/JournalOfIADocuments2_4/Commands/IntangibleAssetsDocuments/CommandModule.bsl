#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "DataProcessor.JournalOfIADocuments2_4.Command.IntangibleAssetsDocuments");
	
	OpenForm("DataProcessor.JournalOfIADocuments2_4.Form.IntangibleAssetsDocuments",
		,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
