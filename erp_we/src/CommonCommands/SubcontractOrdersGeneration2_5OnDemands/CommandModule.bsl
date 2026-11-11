#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Parameters = New Structure("FilterBySupplyType", PredefinedValue("Enum.SupplyTypes.ProductionByThirdParty"));
	
	OpenForm("DataProcessor.DemandFulfillment.Form", Parameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness);
	
EndProcedure

#EndRegion