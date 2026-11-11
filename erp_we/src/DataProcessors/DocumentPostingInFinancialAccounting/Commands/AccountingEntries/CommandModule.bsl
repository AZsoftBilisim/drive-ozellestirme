
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FilterParameters = New Structure("Recorder", CommandParameter);
	FormParameters = New Structure("Filter", FilterParameters);
	
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.FinancialAccountingPostings",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandParameter,
		CommandExecuteParameters.Window);

EndProcedure

#EndRegion