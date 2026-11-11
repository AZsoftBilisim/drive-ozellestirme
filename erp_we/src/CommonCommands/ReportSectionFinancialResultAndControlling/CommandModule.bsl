
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ReportsOptionsClient.ShowReportBar("FinancialResultAndControlling", CommandExecuteParameters);
	
EndProcedure

#EndRegion
