
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	FormParameters.Insert("SeasonalGroups", CommandParameter);
	
	OpenForm("InformationRegister.SeasonalIndexes.Form.SeasonalIndexes", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window); 
	
EndProcedure
