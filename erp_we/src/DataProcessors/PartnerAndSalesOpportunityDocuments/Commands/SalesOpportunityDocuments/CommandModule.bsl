

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FilterStructure1 = New Structure("SalesOpportunity", CommandParameter);
	
	FormParameters = New Structure(
			"Filter, SettingsKey, GenerateOnOpen",
			FilterStructure1,
			"SalesOpportunity",
			True);

	OpenForm("DataProcessor.PartnerAndSalesOpportunityDocuments.Form.SalesOpportunityDocuments",
			FormParameters,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window);

EndProcedure

#EndRegion
