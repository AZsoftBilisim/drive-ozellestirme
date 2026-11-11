#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "DataProcessor.FADocumentLog2_4.Command.FixedAssetsDocuments");
	
	DefaultFormAssignmentKey = DefaultFormAssignmentKey();
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", DefaultFormAssignmentKey);
	
	OpenForm("DataProcessor.FADocumentLog2_4.Form.FixedAssetsDocuments", 
		FormParameters,
		CommandExecuteParameters.Source,
		False, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DefaultFormAssignmentKey()
	Return DataProcessors.FADocumentLog2_4.DefaultFormAssignmentKey();
EndFunction

#EndRegion
