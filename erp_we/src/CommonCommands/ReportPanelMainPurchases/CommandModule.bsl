#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ReportsOptionsClient.ShowReportBar("Purchases", CommandExecuteParameters);
	
EndProcedure

#EndRegion 