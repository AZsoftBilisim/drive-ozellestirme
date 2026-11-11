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
	
	FormParameters = New Structure;
	If TypeOf(CommandExecuteParameters.Source) = Type("ClientApplicationForm") Then
		FormParameters.Insert("ID", CommandExecuteParameters.Source.ID);
		FormParameters.Insert("Description", CommandExecuteParameters.Source.Description);
		FormParameters.Insert("CurrentVersionID", CommandExecuteParameters.Source.CurrentVersionID);
		FormParameters.Insert("FileOwner", CommandExecuteParameters.Source.OwnerID);
	EndIf;
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.FileVersions",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion