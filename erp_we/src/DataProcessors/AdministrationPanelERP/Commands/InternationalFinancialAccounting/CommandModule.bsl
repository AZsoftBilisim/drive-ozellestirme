
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormName = "InternationalFinancialAccounting";
	
	FormParameters = New Structure("CurrentSection", FormName);
	
	OpenForm(
		"DataProcessor.AdministrationPanelERP.Form" + "." + FormName,
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
