
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm(
		"DataProcessor.TMAdministrationPanel.Form.Sales",
		New Structure,
		CommandExecuteParameters.Source,
		"DataProcessor.TMAdministrationPanel.Form.Sales" + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
