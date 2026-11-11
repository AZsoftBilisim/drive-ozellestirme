
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	Filter = New Structure;
	Filter.Insert("Premise", CommandParameter);
	
	OpenForm("Catalog.StorageAreas.ListForm",New Structure("Filter", Filter),,CommandParameter,CommandExecuteParameters.Window);
EndProcedure

#EndRegion

