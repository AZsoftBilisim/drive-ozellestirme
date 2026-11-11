
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	KeyOperation = "DataProcessor.DocumentsJournalCashPayment.Command.CashPaymentJournal";
	PerformanceMonitorClient.StartTimeMeasurement(, KeyOperation);
	
	FormParameters = New Structure("", );
	OpenForm("DataProcessor.DocumentsJournalCashPayment.Form",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure
