
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm(
		"DataProcessor.TMAdministrationPanel.Form.InitialFilling",
		New Structure,
		CommandExecuteParameters.Source,
		"DataProcessor.TMAdministrationPanel.Form.InitialFilling" + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
