#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm(
		"DataProcessor.ConfigureIntegrationWith1CAnalytics.Form.Form",
		New Structure,
		CommandExecuteParameters.Source,
		"DataProcessor.ConfigureIntegrationWith1CAnalytics.Form.Form" + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion