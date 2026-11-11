
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ReportsOptionsClient.ShowReportBar("InternationalFinancialAccounting", CommandExecuteParameters);
	
EndProcedure

#EndRegion