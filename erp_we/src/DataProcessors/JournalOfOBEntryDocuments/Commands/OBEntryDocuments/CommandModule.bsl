#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &Productivity Measurement
	// Standard subsystems.Measurement of productivity
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.JournalOfOBEntryDocuments.Command.OBEntryDocuments", False, True);		
	// End StandardSubsystems.PerformanceMeasurement
	
	FormParameters = New Structure("FormAssignmentKey", "OBEntryDocuments");
	
	OpenForm("DataProcessor.JournalOfOBEntryDocuments.Form.ListForm",
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion 