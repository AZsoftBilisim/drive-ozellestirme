
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm(
		"DataProcessor.CAAdministrationPanel.Form.NonCurrentAssets",
		New Structure,
		CommandExecuteParameters.Source,
		"DataProcessor.CAAdministrationPanel.Form.NonCurrentAssets" + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
