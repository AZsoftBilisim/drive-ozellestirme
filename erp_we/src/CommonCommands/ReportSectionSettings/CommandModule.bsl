
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ReportsOptionsClient.ShowReportBar("Settings", CommandExecuteParameters);
	
EndProcedure

#EndRegion
