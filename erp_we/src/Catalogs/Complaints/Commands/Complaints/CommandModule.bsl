
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterParameters = New Structure("Partner",CommandParameter);
	
	OpenForm("Catalog.Complaints.ListForm",
	             New Structure("Filter",FilterParameters),
	             CommandExecuteParameters.Source,
	             CommandExecuteParameters.Source.UniqueKey,
	             CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
