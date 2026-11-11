
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	KeyOperation = "DataProcessor.DocumentsJournalBankAccountPayments.Command.BankAccountPayments";
	PerformanceMonitorClient.StartTimeMeasurement(, KeyOperation);
	
	FormParameters = New Structure("", );
	OpenForm("DataProcessor.DocumentsJournalBankAccountPayments.Form",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure
