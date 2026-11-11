
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.ChangingContactInformation",
				,
				CommandExecuteParameters.Source,
				CommandExecuteParameters.Uniqueness);
	
EndProcedure

#EndRegion
