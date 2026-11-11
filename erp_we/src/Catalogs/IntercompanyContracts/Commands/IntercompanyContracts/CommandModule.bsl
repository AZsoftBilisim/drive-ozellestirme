#Region Private

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("Catalog.IntercompanyContracts.Form.ListForm",
				 ,
				 CommandExecuteParameters.Source,
				 CommandExecuteParameters.Uniqueness,
				 CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
