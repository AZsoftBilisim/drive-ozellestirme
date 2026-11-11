&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True, "CommonCommand.OrderSupplyForecast");
	
	FormParameters = ProvisionInDocumentsClient.OrderSecurityStateFormParameters("SECTION");
	OpenForm("DataProcessor.OrderSupplyForecast.Form",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,
		Undefined,
		FormWindowOpeningMode.Independent);

EndProcedure
