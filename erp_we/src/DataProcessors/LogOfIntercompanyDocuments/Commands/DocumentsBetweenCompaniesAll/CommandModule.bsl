

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfIntercompanyDocuments.Command.DocumentsBetweenCompaniesAll");
	
	FormParameters = New Structure("PurposeUseKey", "DocumentsBetweenCompaniesAll");
	
	OpenForm("DataProcessor.LogOfIntercompanyDocuments.Form.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		"DocumentsBetweenCompaniesAll",
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion