
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Organization", CommandParameter);
	
	FormParameters = New Structure("Filter", FilterParameters);
	
	OpenForm(
		"Catalog.CashAccounts.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure
