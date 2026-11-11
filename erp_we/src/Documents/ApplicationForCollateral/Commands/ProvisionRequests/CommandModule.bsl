#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Document.ApplicationForCollateral.Command.ProvisionRequests");
	
	OpenForm("Document.ApplicationForCollateral.Form.ListForm",
		, // Form parametersreferences,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion