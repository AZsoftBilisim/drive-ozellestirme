
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Form.ContextListForm", 
		New Structure("Source", CommandParameter), 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion