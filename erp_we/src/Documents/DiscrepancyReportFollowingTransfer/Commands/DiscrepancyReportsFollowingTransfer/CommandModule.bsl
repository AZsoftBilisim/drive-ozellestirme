
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	OpenForm("Document.DiscrepancyReportFollowingTransfer.ListForm",
	, 
	CommandExecuteParameters.Source,
	CommandExecuteParameters.Uniqueness,
	CommandExecuteParameters.Window, 
	CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
