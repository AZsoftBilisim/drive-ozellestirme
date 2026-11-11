#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ReportsOptionsClient.ShowReportBar("NonCurrentAssets", CommandExecuteParameters);
	
EndProcedure

#EndRegion 