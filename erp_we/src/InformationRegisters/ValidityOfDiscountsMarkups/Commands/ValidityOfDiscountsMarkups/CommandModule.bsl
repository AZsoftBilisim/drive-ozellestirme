
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure("Source", CommandParameter);
	OpenForm("InformationRegister.ValidityOfDiscountsMarkups.Form.ValidityOfDiscountsMarkupsSource",
	             FormParameters, CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness,
	             CommandExecuteParameters.Window);
	
EndProcedure
