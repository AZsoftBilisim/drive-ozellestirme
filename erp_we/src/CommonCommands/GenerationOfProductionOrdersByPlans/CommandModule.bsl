
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
 	OpenForm("DataProcessor.GenerationOfProductionOrdersByPlans.Form",, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure
