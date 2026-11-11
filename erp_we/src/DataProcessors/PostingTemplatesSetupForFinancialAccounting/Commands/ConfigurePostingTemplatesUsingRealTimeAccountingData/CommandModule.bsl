
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	OpenForm("DataProcessor.PostingTemplatesSetupForFinancialAccounting.Form.PostingTemplatesSetup",
				 FormParameters,
				 CommandExecuteParameters.Source,
				 CommandExecuteParameters.Uniqueness,
				 CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion

