
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure;
	OpenForm(
		"DataProcessor.AdministrationPanelCTL.Form.FreshServiceConnectionSettings", FormParameters,
		CommandExecuteParameters.Source,
		"DataProcessor.AdministrationPanelCTL.Form.FreshServiceConnectionSettings" 
			+ ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);

EndProcedure

#EndRegion
