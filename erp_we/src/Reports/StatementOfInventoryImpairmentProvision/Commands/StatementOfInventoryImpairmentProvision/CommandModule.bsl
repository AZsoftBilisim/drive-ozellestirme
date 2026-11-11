
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("Report.StatementOfInventoryImpairmentProvision.ObjectForm",
					, 
					CommandExecuteParameters.Source, 
					CommandExecuteParameters.Uniqueness, 
					CommandExecuteParameters.Window, 
					CommandExecuteParameters.URL);

EndProcedure

#EndRegion
