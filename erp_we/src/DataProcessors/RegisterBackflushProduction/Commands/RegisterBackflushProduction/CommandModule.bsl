
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.RegisterBackflushProduction.Command.RegisterBackflushProduction");
	// End StandardSubsystems.PerformanceMeasurement
	
	OpenForm("DataProcessor.RegisterBackflushProduction.Form.WorkplaceForm", ,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
		
EndProcedure

#EndRegion