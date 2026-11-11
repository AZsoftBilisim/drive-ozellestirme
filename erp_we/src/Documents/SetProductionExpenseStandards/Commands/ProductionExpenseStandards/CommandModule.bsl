
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.SetProductionExpenseStandards.Form.ListForm.FillInStandards");
	
	OpenForm("Document.SetProductionExpenseStandards.ListForm", , 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure
