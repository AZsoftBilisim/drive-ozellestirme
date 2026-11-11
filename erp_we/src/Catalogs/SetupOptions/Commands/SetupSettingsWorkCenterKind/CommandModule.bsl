
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure("WorkCenterType", CommandParameter);
	OpenForm("Catalog.SetupOptions.Form.SetupOptions", 
				FormParameters, 
				CommandExecuteParameters.Source, 
				CommandExecuteParameters.Uniqueness, 
				CommandExecuteParameters.Window, 
				CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion