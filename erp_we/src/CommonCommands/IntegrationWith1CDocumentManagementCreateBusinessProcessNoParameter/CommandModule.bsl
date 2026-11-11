#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	IntegrationWith1CDocumentManagementCoreClient.BeforeExecutingCommand(
		CommandExecuteParameters.Source);
	
	CallbackDescription = New CallbackDescription(
		"TestConnectionCompletion", ThisObject, Undefined);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject,
		True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure TestConnectionCompletion(Result, Parameters) Export
	
	If Result = True Then // authorization is successful
		
		IntegrationWith1CDocumentManagementClient.CreateBusinessProcess();
		
	EndIf;
	
EndProcedure

#EndRegion