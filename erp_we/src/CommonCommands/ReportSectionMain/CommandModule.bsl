#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ReportsOptionsClient.ShowReportBar(
		ReportsOptionsClientServer.HomePageID(),
		CommandExecuteParameters);
	
EndProcedure

#EndRegion