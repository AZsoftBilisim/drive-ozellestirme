
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure("Factor", CommandParameter);
	OpenForm("Catalog.NonFinancialItemProfiles.Form.NonFinancialItemTemplatesForm", 
						FormParameters, CommandExecuteParameters.Source, 
						CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, 
						CommandExecuteParameters.URL);
EndProcedure
