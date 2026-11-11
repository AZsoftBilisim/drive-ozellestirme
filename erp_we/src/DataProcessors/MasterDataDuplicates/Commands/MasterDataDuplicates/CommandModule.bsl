
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	KeyOperation = "DataProcessor.MasterDataDuplicates.Command.MasterDataDuplicates";
	PerformanceMonitorClient.TimeMeasurement(KeyOperation);
	
	OpenForm("DataProcessor.MasterDataDuplicates.Form.Workplace",
		,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion