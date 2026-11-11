#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ReportsOptionsClient.ShowReportBar("CRMAndMarketing", CommandExecuteParameters);
	
EndProcedure

#EndRegion 
