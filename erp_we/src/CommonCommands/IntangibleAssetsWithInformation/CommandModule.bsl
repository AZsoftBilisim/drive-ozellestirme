
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "CommonCommand.IntangibleAssets");
	
	OpenForm("Catalog.IntangibleAssets.Form.ListFormWithInformation");
	
EndProcedure

#EndRegion
