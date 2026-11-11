#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.RegisterDocumentsByDepreciationMethod.Command.RegisterDocumentsByDepreciationMethod");
	
	OpenForm("DataProcessor.RegisterDocumentsByDepreciationMethod.Form.DocumentsCreating",, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion