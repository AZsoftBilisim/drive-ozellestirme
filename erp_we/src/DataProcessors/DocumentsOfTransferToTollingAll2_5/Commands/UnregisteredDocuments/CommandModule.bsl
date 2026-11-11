#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.DocumentsOfTransferToTollingAll2_5.Command.UnregisteredDocuments");
	
	OpenForm("DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices", 
		,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion