

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FilterStructure1 = New Structure("Partner", CommandParameter);
	
	FormParameters = New Structure(
			"Filter, SettingsKey, GenerateOnOpen",
			FilterStructure1,
			"Partner",
			True);

	OpenForm("DataProcessor.PartnerAndSalesOpportunityDocuments.Form.DocumentsOfPartner",
			FormParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window);

EndProcedure

#EndRegion
