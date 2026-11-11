#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	IntegrationWith1CDocumentManagementCoreClient.BeforeExecutingCommand(
		CommandExecuteParameters.Source);
	
	IntegrationWith1CDocumentManagement3Client.ProcessingStartProcessingCommand(CommandParameter, CommandExecuteParameters);
	
EndProcedure

#EndRegion