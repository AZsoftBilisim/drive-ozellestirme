#Region Private

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Filters = New Structure;
	Filters.Insert("Person", CommandParameter);
	
	FormParameters = New Structure("Filter", Filters);
	OpenForm("InformationRegister.DocumentsPersons.Form.DocumentsPerson", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion