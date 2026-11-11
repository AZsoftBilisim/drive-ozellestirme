

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure("Partner", CommandParameter);
	OpenForm(
		"InformationRegister.ABCXYZCustomerClassification.Form.HistoryOfClassification",
		FormParameters, CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);

EndProcedure

#EndRegion
