
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "CommonCommand.FixedAssets");
	
	OpenForm("Catalog.Assets.Form.ListFormWithInformation");
	
EndProcedure

#EndRegion
