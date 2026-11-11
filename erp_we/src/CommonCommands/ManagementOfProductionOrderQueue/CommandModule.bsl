
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("Document.ProductionOrder2_2.Form.Queue",
		,
		CommandExecuteParameters.Source,CommandExecuteParameters.Uniqueness,CommandExecuteParameters.Window,CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
