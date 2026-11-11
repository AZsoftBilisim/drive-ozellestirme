
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	Parameters = New Structure("FilterBySupplyType", PredefinedValue("Enum.SupplyTypes.Purchase"));
	OpenForm("DataProcessor.DemandFulfillment.Form", Parameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness);

EndProcedure
