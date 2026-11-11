
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	FormParameters.Insert("ListOfSources", CommandParameter);
	
	OpenForm("DataProcessor.CompareBillsOfMaterials.Form", FormParameters, CommandExecuteParameters.Source, , CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion