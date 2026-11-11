
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("FilterByPartner", CommandParameter);
	OpenForm("Catalog.CounterpartyBankAccounts.ListForm",
	             FormParameters, CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness,
	             CommandExecuteParameters.Window);
	
EndProcedure
