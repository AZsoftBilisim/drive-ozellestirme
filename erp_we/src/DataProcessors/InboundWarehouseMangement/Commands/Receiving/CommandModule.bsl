
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.InboundWarehouseMangement.Command.Receiving");
	
	OpenForm("DataProcessor.InboundWarehouseMangement.Form.Form",,,,CommandExecuteParameters.Window);	
EndProcedure

#EndRegion
