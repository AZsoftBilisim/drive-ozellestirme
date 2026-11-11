
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("Product", CommandParameter);
	OpenForm("Catalog.RouteSheets.ListForm", 
				FormParameters, 
				CommandExecuteParameters.Source, 
				CommandExecuteParameters.Uniqueness, 
				CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion