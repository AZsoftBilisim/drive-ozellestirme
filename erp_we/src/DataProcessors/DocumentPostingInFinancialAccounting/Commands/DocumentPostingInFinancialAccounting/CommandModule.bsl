
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentPostingInFinancialAccounting.Command.DocumentPostingInFinancialAccounting");
	
	FormParameters = New Structure("", );
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form", 
				FormParameters, 
				CommandExecuteParameters.Source, 
				CommandExecuteParameters.Uniqueness, 
				CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion