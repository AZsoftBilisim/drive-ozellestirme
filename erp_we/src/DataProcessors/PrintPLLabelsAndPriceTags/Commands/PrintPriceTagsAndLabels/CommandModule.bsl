#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure();
	PrintPLLabelsAndPriceTagsClientOverridable.ParametersOfOpeningCommand(FormParameters);
	OpenForm("DataProcessor.PrintPLLabelsAndPriceTags.Form", FormParameters);
	
EndProcedure

#EndRegion
