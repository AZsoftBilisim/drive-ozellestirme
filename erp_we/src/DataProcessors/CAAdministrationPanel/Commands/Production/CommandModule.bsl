
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm(
		"DataProcessor.CAAdministrationPanel.Form.Production",
		New Structure,
		CommandExecuteParameters.Source,
		"DataProcessor.CAAdministrationPanel.Form.Production" + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
