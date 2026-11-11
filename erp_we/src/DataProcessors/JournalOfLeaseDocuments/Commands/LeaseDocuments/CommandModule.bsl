#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "DataProcessor.JournalOfLeaseDocuments.Command.LeaseDocuments");
	
	DefaultFormAssignmentKey = "LeaseDocuments";
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", DefaultFormAssignmentKey);
	
	OpenForm("DataProcessor.JournalOfLeaseDocuments.Form", 
		FormParameters,
		CommandExecuteParameters.Source,
		False, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
		
EndProcedure

#EndRegion
