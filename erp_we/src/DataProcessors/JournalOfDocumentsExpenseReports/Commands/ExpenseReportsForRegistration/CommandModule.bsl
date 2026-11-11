
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	KeyOperation = "DataProcessor.JournalOfDocumentsExpenseReports.Command.ExpenseReportsForRegistration";
	PerformanceMonitorClient.StartTimeMeasurement(, KeyOperation);
	
	FormParameters = New Structure("", );
	OpenForm("DataProcessor.JournalOfDocumentsExpenseReports.Form.ExpenseReportsForRegistration",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
		
EndProcedure

#EndRegion