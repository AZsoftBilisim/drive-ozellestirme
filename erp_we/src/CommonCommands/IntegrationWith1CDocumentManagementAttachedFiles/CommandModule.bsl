#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpeningParameters = IntegrationWith1CDocumentManagementCoreClient.OptionsForOpeningListOfFiles(
		CommandExecuteParameters.Source);
	OpeningParameters.Uniqueness = CommandExecuteParameters.Uniqueness;
	OpeningParameters.Window = CommandExecuteParameters.Window;
	IntegrationWith1CDocumentManagementCoreClient.OpenFormAttachedFiles(
		CommandParameter,
		OpeningParameters);
	
EndProcedure

#EndRegion