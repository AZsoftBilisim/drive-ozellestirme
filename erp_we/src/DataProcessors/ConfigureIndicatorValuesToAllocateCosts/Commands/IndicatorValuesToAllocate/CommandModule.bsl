#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure("RefToSource", CommandParameter);
	OpenForm("DataProcessor.ConfigureIndicatorValuesToAllocateCosts.Form", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);

EndProcedure

#EndRegion
