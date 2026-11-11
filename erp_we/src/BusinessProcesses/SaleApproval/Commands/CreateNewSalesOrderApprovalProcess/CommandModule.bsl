#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("BusinessProcess.SaleApproval.ObjectForm",
	             New Structure("Basis",CommandParameter),
	             ,
	             ,);

EndProcedure

#EndRegion
