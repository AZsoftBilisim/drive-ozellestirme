#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("CommonForm.FiscalDeviceManagement", , CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion