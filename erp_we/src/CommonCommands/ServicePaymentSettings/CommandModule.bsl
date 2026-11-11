
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure;
	OpenForm(
		"DataProcessor.AdministrationPanelCTL.Form.ServicePaymentSettings", FormParameters,
		CommandExecuteParameters.Source,
		"DataProcessor.AdministrationPanelCTL.Form.ServicePaymentSettings" 
			+ ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);

EndProcedure

#EndRegion
