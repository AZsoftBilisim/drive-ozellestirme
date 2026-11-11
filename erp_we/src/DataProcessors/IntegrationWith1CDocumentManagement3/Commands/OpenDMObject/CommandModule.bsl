#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	IntegrationWith1CDocumentManagement3Client.OpenDMObject();
	
EndProcedure

#EndRegion