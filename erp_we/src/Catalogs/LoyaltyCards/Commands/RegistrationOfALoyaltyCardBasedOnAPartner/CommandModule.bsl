
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpeningParameters = New Structure("Mode, Partner");
	OpeningParameters.Mode   = "RegisterNewLoyaltyCard";
	OpeningParameters.Partner = CommandParameter;
	
	OpenForm("Catalog.LoyaltyCards.Form.RegistrationWizard", OpeningParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure
