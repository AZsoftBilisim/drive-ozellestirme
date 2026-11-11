#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.CorrectAccountingErrors.Command.CorrectAccountingErrors");
	
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", "CorrectAccountingErrors");
	
	OpenForm("DataProcessor.CorrectAccountingErrors.Form", 
		FormParameters,
		CommandExecuteParameters.Source,
		False, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
		
EndProcedure

#EndRegion