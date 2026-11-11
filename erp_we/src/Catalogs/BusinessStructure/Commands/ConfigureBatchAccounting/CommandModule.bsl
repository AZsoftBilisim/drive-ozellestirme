
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("Department",CommandParameter);
	OpenForm("Catalog.BusinessStructure.Form.BatchRecordSetupForm", 
						FormParameters, 
						CommandExecuteParameters.Source, 
						CommandExecuteParameters.Uniqueness, 
						CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion