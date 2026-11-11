#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	EquipmentManagerClient.OpenPeripherals(CommandParameter, CommandExecuteParameters);
	
EndProcedure

#EndRegion