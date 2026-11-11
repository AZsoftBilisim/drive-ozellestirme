
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.PlanningProcessManagement.Command.PlanningProcessManagement");
	
	OpenForm("DataProcessor.PlanningProcessManagement.Form",, CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
		
	
EndProcedure
