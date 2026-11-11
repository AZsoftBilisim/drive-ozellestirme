
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterParameters = New Structure("Owner", CommandParameter);
	FormParameters = New Structure("Filter", FilterParameters);
	
	OpenForm("Catalog.SubAssets.Form.SubAssetsList", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
