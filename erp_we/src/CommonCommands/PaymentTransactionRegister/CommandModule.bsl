#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	EquipmentManagerClient.OpenPaymentTransactions(CommandParameter, CommandExecuteParameters);
	
EndProcedure

#EndRegion