

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FilterParameters = New Structure("Vendor", True);
	
	OpenForm("Catalog.Partners.ListForm",
	New Structure("Filter", FilterParameters),
		CommandExecuteParameters.Source,
		New UUID("00000000-0000-0000-0000-000000000001"),
		CommandExecuteParameters.Window);

EndProcedure

#EndRegion

