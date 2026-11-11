

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfIntercompanyDocuments.Command.TransfersToRegister");
		
	FormParameters = New Structure("PurposeUseKey", "DocumentsBetweenCompaniesAll");
	
	OpenForm("DataProcessor.LogOfIntercompanyDocuments.Form.RegisterTransfersAndRedemptions",
		FormParameters,
		CommandExecuteParameters.Source,
		"DocumentsBetweenCompaniesAll",
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion