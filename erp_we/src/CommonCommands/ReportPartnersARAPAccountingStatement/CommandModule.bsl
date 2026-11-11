#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure("VariantKey", "StatementBasic");
	
	OpenForm("Report.PartnersARAPAccountingStatement.Form", 
			FormParameters, 
			CommandExecuteParameters.Source, 
			CommandExecuteParameters.Uniqueness, 
			CommandExecuteParameters.Window, 
			CommandExecuteParameters.URL);
EndProcedure

#EndRegion 