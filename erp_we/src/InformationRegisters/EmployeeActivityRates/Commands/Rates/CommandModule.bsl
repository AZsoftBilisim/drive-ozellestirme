
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Filter = New Structure("WorkKind", CommandParameter);
	
	FormParameters = New Structure("Filter", Filter);
	OpenForm("InformationRegister.EmployeeActivityRates.ListForm", 
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure
