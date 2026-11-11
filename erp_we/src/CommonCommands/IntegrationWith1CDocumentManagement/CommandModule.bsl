#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	IntegrationWith1CDocumentManagementCoreClient.BeforeExecutingCommand(
		CommandExecuteParameters.Source);
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	If Settings.UseIntegrationBefore2 Then
		FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.DocumentManagement";
	ElsIf Settings.UseIntegrationBefore3 Then
		FormName = "DataProcessor.IntegrationWith1CDocumentManagement3.Form.DocumentManagement";
	EndIf;
	
	FormParameters = New Structure("ExternalObject", CommandParameter);
	OpenForm(
		FormName,
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion