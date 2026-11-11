#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	EquipmentManagerClient.SelectWorkplaceOfCurrentSession(CommandParameter, CommandExecuteParameters);
	
EndProcedure

#EndRegion