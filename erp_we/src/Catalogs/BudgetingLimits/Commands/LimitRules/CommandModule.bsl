
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterParameters = New Structure("Owner", CommandParameter);
	FormParameters = New Structure("Filter", FilterParameters);
	OpenForm("Catalog.BudgetingLimits.ListForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);

EndProcedure
