
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	OpenForm("DataProcessor.GenerationOfPurchaseOrders.Form", ,
	CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness);

EndProcedure
