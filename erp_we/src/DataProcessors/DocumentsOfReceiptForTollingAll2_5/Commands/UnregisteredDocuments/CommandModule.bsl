
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Command.InvoicesForRegistration");
	
	OpenForm(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices",,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion