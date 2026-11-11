
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PerformanceMonitorClient.StartTimeMeasurement(True, "CommonForm.DocumentsUnderContract");
	
	OpenForm("CommonForm.DocumentsUnderContract",
		New Structure("Contract", CommandParameter),
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
		
EndProcedure
