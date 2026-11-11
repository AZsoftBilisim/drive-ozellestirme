
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure("ByParticipant", CommandParameter);
	OpenForm(
		"Catalog.SalesOpportunitiesToCustomer.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);

EndProcedure

#EndRegion
