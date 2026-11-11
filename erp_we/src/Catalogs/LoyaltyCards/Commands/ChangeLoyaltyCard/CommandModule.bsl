
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpeningParameters = New Structure("Mode, ReplacedCard");
	OpeningParameters.Mode = "ReplaceLoyaltyCard";
	OpeningParameters.ReplacedCard = CommandParameter;
	
	OpenForm("Catalog.LoyaltyCards.Form.RegistrationWizard", OpeningParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure
