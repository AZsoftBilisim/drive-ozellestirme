#Region Private

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PerformanceMonitorClient.StartTimeMeasurement(True, "DataProcessor.MonthEndClosingOperations.Form.Opening");
	
	OpenForm(
		"DataProcessor.MonthEndClosingOperations.Form",
		 ,
		 CommandExecuteParameters.Source,
		 CommandExecuteParameters.Uniqueness,
		 CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion