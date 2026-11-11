#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("CommonForm.POSTerminalManagement", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness);
	
EndProcedure

#EndRegion