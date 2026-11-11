#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.RMDocumentJournal.Command.RMDocuments");
	
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", "RMDocuments");
	
	OpenForm("DataProcessor.RMDocumentJournal.Form.RMDocuments", 
		FormParameters,
		CommandExecuteParameters.Source,
		False, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
		
EndProcedure

#EndRegion
