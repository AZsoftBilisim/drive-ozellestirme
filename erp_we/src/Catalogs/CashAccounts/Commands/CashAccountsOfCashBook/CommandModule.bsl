
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("CashBook", CommandParameter);
	FilterStructure1.Insert("Organization", CommandExecuteParameters.Source.Object.Owner);
	
	FormParameters = New Structure("Filter", FilterStructure1);
	
	OpenForm("Catalog.CashAccounts.Form.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure
