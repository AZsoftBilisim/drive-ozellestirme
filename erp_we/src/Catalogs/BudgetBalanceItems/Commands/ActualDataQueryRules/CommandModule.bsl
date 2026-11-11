#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("Catalog.ActualDataQueryRulesByBudgetBalanceItems.Form.ListFormContextBudgetBalanceItem",
		New Structure("BudgetBalanceItem", CommandParameter),
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
		
EndProcedure

#EndRegion