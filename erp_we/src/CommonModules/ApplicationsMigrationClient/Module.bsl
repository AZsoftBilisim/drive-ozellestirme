
#Region Internal

Procedure OnStart(Parameters) Export
	
	If Parameters.Cancel Then
		Return;
	EndIf;
	
	StartupOptions = StandardSubsystemsClient.ClientParametersOnStart();
	
	If StartupOptions.SeparatedDataUsageAvailable 
		And StartupOptions.MigrationOfApplicationsOpenForm Then
		Form = GetForm("DataProcessor.WizardOfTransitionToCloud.Form.ApplicationMigration");
		Form.OnOpenForm(True);
	EndIf;
	
EndProcedure

// Returns: 
//  String - the name of the transition form to the service.
Function NameOfTransitionForm() Export

	Return "CloudTechnology.ApplicationsMigration.GoToServiceForm";
	
EndFunction

// Returns: 
//  ClientApplicationForm, Undefined - the transition to service form.
Function GoToServiceForm() Export
	
	Return ApplicationParameters[NameOfTransitionForm()];
	
EndFunction

#EndRegion
