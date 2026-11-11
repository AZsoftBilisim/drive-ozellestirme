#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	IntegrationWith1CDocumentManagementCoreClient.BeforeExecutingCommand(
		CommandExecuteParameters.Source);
	
	IntegrationWith1CDocumentManagementCoreClient.OpenTasksForMe(
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion