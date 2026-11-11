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
		ExternalObject = New Structure;
		ExternalObject.Insert("ID", CommandExecuteParameters.Source.ID);
		ExternalObject.Insert("type", CommandExecuteParameters.Source.Type);
		
		If Find(CommandExecuteParameters.Source.Type,"Document") <> 0 Then
			ExternalObject.Insert("name", CommandExecuteParameters.Source.Description);
			ExternalObject.Insert("presentation", CommandExecuteParameters.Source.Presentation);
		Else
			ExternalObject.Insert("presentation", "");
		EndIf;
		
	Else
		ExternalObject = Undefined;
	EndIf;
	
	FormParameters = New Structure("ExternalObject",ExternalObject);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement.Form.TimeSpentByObject",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion