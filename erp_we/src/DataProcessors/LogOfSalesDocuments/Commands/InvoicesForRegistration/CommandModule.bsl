
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfSalesDocuments.Command.InvoicesForRegistration");
	
	OpenForm("DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices", 
		,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure
