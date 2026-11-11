#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Document.PurchasingReportToConsignorPrincipal.Command.PurchasingReportsToConsignorsForRegistration");
	
	OpenForm("Document.PurchasingReportToConsignorPrincipal.Form.ToRegister", 	
		,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
