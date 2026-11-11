
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	OpenForm("DataProcessor.DemandFulfillment.Form", ,
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure
