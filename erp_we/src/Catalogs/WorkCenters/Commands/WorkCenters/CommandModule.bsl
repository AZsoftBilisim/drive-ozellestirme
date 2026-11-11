
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Filter = New Structure("WorkCenterType", CommandParameter);
	FormParameters = New Structure("Filter", Filter);
	
	OpenForm("Catalog.WorkCenters.Form.ListForm", 
				FormParameters, 
				CommandExecuteParameters.Source, 
				CommandExecuteParameters.Uniqueness, 
				CommandExecuteParameters.Window, 
				CommandExecuteParameters.URL);
				
EndProcedure

#EndRegion