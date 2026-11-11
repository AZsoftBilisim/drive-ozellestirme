#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FilterParameters = New Structure;
	FilterParameters.Insert("Owner", CommandParameter);
	
	FormParameters = New Structure("Filter", FilterParameters);
	
	OpenForm(
		"Catalog.BudgetingSteps.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
