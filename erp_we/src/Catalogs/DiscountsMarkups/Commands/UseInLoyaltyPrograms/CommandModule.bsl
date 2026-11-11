
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("DiscountMarkup", CommandParameter);
	OpenForm("Catalog.DiscountsMarkups.Form.UseInLoyaltyPrograms", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure
