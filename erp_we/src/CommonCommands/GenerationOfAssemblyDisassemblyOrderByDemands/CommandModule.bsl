
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Parameters = New Structure("FilterBySupplyType", PredefinedValue("Enum.SupplyTypes.AssemblyDisassembly"));
	
	OpenForm("DataProcessor.DemandFulfillment.Form", Parameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness);
	
EndProcedure
