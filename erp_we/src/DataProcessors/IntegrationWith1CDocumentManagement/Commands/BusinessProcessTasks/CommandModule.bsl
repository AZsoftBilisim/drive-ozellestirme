#Region EventHandlers

// Command handler
//
// Parameters:
//   CommandParameter - Arbitrary
//   CommandExecuteParameters - CommandExecuteParameters:
//     * Source - ClientApplicationForm:
//         ** Description - String
//
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If TypeOf(CommandExecuteParameters.Source) = Type("ClientApplicationForm") Then
		If Find(CommandExecuteParameters.Source.FormName,"BusinessProcess") <> 0 Then
			ExternalObject = New Structure;
			ExternalObject.Insert("name", CommandExecuteParameters.Source.Description);
			ExternalObject.Insert("ID", CommandExecuteParameters.Source.ID);
			ExternalObject.Insert("type", CommandExecuteParameters.Source.Type);
			ExternalObject.Insert("presentation", CommandExecuteParameters.Source.Presentation);
			FormParameters = New Structure("ExternalObject",ExternalObject);
		EndIf;
	EndIf;
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessTasks",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion