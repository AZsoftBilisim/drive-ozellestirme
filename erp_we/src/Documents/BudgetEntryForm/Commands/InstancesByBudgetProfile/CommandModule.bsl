
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FilterParameters = New Structure("BudgetProfile", CommandParameter);
	FormParameters = New Structure("Filter", FilterParameters);
	OpenForm("Document.BudgetEntryForm.ListForm", FormParameters, CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);

EndProcedure

#EndRegion