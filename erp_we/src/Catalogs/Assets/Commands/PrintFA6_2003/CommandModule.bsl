
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PrintManagementClient.ExecutePrintCommand(
		"Catalog.Assets",
		"FA6",
		CommandParameter,
		CommandExecuteParameters,
		New Structure);
	
EndProcedure

