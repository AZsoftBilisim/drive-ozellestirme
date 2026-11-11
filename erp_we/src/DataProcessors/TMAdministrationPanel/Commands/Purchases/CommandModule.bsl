
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm(
		"DataProcessor.TMAdministrationPanel.Form.Purchases",
		New Structure,
		CommandExecuteParameters.Source,
		"DataProcessor.TMAdministrationPanel.Form.Purchases" + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
