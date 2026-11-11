
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure();
	OpenForm("DataProcessor.TransferOfAssignedGoods.Form",
	             FormParameters,
	             CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness,
	             CommandExecuteParameters.Window,
	             CommandExecuteParameters.URL);
	
EndProcedure
