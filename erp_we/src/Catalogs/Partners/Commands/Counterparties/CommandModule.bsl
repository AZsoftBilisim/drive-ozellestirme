
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("Catalog.Partners.ListForm",
	             ,
	             CommandExecuteParameters.Source,
	             New UUID("00000000-0000-0000-0000-000000000002"),
	             CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
