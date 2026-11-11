
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FilterParameters = New Structure("Competitor", True);
	
	OpenForm("Catalog.Partners.ListForm",
	New Structure("Filter", FilterParameters),
	CommandExecuteParameters.Source,
	New UUID("00000000-0000-0000-0000-000000000003"),
	CommandExecuteParameters.Window);

EndProcedure


#EndRegion


