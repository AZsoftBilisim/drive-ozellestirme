#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	IntegrationWith1CDocumentManagementCoreClient.BeforeExecutingCommand(
		CommandExecuteParameters.Source);
	
	IntegrationWith1CDocumentManagementClient.ProcessingOutgoingMessageCommand(CommandParameter, CommandExecuteParameters);
	
EndProcedure

#EndRegion