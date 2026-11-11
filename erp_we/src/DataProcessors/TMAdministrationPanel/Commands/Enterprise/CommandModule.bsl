
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm(
		"DataProcessor.TMAdministrationPanel.Form.Enterprise",
		New Structure,
		CommandExecuteParameters.Source,
		"DataProcessor.TMAdministrationPanel.Form.Enterprise" + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
