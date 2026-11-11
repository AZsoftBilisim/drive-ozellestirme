#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Form = ApplicationParameters[ApplicationsMigrationClient.NameOfTransitionForm()];
	If Form = Undefined Then
		OpenForm("DataProcessor.WizardOfTransitionToCloud.Form.WizardOfTransitionToCloud", , 
			CommandExecuteParameters.Source, 
			CommandExecuteParameters.Uniqueness, 
			CommandExecuteParameters.Window, 
			CommandExecuteParameters.URL);
	ElsIf Not Form.IsOpen() Then
		Form.Open();
	Else
		Form.Activate();
	EndIf;
	
EndProcedure

#EndRegion
