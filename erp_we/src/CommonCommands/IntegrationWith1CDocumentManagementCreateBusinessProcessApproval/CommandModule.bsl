#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	IntegrationWith1CDocumentManagementCoreClient.BeforeExecutingCommand(
		CommandExecuteParameters.Source);
	
	Parameters = New Structure;
	Parameters.Insert("SubjectOfApproval", CommandParameter);
	Parameters.Insert("Source", CommandExecuteParameters.Source);
	
	CallbackDescription = New CallbackDescription(
		"TestConnectionCompletion", ThisObject, Parameters);
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
		
		IntegrationWith1CDocumentManagementClient.StartApproval(Parameters);
		
	EndIf;
	
EndProcedure

#EndRegion