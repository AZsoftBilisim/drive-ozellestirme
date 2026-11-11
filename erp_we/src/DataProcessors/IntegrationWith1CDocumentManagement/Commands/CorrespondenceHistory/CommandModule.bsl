#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure();
	FormParameters.Insert("ID", CommandExecuteParameters.Source.ID);
	FormParameters.Insert("type", CommandExecuteParameters.Source.Type);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.CorrespondenceHistory",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion