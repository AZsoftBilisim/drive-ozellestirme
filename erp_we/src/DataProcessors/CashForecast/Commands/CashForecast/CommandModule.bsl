#Region Private

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PerformanceMonitorClient.StartTimeMeasurement(True, "DataProcessor.CashForecast.Form");
	
	OpenForm("DataProcessor.CashForecast.Form",
		,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
