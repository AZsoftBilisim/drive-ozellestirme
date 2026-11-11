
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	
	OpenForm("Catalog.Glossary.ListForm",
	             FormParameters,
	             CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness, 
	             CommandExecuteParameters.Window,
	             CommandExecuteParameters.URL);

EndProcedure

#EndRegion
