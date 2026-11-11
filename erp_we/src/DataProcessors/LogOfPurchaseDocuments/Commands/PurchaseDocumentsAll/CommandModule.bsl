#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfPurchaseDocuments.Command.PurchaseDocumentsAll");

	FormParameters = New Structure("FormAssignmentKey", "PurchaseDocumentsAll");
	
	OpenForm("DataProcessor.LogOfPurchaseDocuments.Form.DocumentsList", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion