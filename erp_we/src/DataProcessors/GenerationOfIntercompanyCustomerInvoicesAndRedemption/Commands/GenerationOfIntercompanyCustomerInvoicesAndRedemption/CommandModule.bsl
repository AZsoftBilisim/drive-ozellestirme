
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.GenerationOfIntercompanyCustomerInvoicesAndRedemption.Command.GenerationOfIntercompanyCustomerInvoicesAndRedemption");
	
	OpenForm("DataProcessor.GenerationOfIntercompanyCustomerInvoicesAndRedemption.Form",
				,
				CommandExecuteParameters.Source,
				CommandExecuteParameters.Uniqueness,
				CommandExecuteParameters.Window, CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion

