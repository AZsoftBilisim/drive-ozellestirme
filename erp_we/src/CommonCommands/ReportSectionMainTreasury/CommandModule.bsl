#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ReportsOptionsClient.ShowReportBar("TreasuryAndARAPAccounting", CommandExecuteParameters);
	
EndProcedure

#EndRegion 