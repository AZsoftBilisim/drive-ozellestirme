
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.LogOfProductionDocuments.Command.ProductionDocumentsAll");
	// End StandardSubsystems.PerformanceMeasurement
	
	FormParameters = New Structure("FormAssignmentKey", "ProductionDocumentsAll");
	
	OpenForm("DataProcessor.LogOfProductionDocuments.Form.DocumentsList",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure
