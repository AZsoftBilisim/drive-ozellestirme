
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm(
		"DataProcessor.OrdersAdministrationPanel.Form.IntegrationWith1COrders",
		New Structure,
		CommandExecuteParameters.Source,
		"DataProcessor.OrdersAdministrationPanel.Form.IntegrationWith1COrders" + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
		
EndProcedure

#EndRegion
