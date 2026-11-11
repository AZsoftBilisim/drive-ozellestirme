
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// Insert the contents of the handler.
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", "CheckBudgetItemLinks");
	FormParameters.Insert("GenerateOnOpen", True);
	
	OpenForm("Report.CheckBudgetItemLinks.Form", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure
