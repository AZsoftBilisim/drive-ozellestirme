
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ReportsOptionsClient.ShowReportBar("Production", CommandExecuteParameters);
	
EndProcedure

#EndRegion