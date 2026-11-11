#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If TypeOf(CommandExecuteParameters.Source) = Type("ClientApplicationForm") Then
		If CommandExecuteParameters.Source.FormName = "DataProcessor.IntegrationWith1CDocumentManagement.Form.Task" Then
			ExternalObject = New Structure;
			ExternalObject.Insert("name", CommandExecuteParameters.Source.Process_);
			ExternalObject.Insert("ID", CommandExecuteParameters.Source.Process_ID);
			ExternalObject.Insert("type", CommandExecuteParameters.Source.Process_Type);
			ExternalObject.Insert("presentation", CommandExecuteParameters.Source.Process_Presentation);
			FormParameters = New Structure("ExternalObject",ExternalObject);
		EndIf;
	EndIf;
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement.Form.AllTasks",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion