#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	OpenForm(
		"DataProcessor.SettingsAndCatalogsOfPayrollAndHumanResources.Form.SettingsAndCatalogsOfPayrollAndHumanResources",
		,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
		
EndProcedure

#EndRegion
