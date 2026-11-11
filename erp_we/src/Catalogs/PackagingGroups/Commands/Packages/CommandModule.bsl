
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	             				  
	Filter = New Structure;
	Filter.Insert("Owner",CommandParameter);
	FormParameters = New Structure("Filter", Filter);
	
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion

