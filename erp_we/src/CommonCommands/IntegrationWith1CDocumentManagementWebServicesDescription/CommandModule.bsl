#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	IntegrationWith1CDocumentManagementCoreClient.BeforeExecutingCommand(
		CommandExecuteParameters.Source);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.WebServiceDescription");
	
EndProcedure

#EndRegion