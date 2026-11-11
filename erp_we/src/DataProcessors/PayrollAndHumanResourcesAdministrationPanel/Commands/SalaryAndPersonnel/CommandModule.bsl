#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormName = "SalaryAndPersonnel";
	
	FormParameters = New Structure("CurrentSection", FormName);
	
	OpenForm(
		"DataProcessor.PayrollAndHumanResourcesAdministrationPanel.Form" + "." + FormName,
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	EndProcedure
	
#EndRegion
