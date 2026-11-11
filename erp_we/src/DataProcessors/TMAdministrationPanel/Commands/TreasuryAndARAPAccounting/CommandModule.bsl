
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm(
		"DataProcessor.TMAdministrationPanel.Form.TreasuryAndARAPAccounting",
		New Structure,
		CommandExecuteParameters.Source,
		"DataProcessor.TMAdministrationPanel.Form.TreasuryAndARAPAccounting" + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
