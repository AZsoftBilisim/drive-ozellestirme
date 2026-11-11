
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpeningParameters = SupplyClient.ParametersForOpeningProcessingFormProvidingNeeds();
	OpeningParameters.FilterBySupplyType = PredefinedValue("Enum.SupplyTypes.Purchase"); // Only purchase requests can be generated.
	OpeningParameters.PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds();
	
	OpenForm("DataProcessor.DemandFulfillment.Form",
		OpeningParameters,
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion