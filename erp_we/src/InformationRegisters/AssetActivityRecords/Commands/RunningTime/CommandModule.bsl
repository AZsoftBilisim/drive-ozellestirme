
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterParameters = New Structure("Asset", CommandParameter);
	FormParameters = New Structure("Filter", FilterParameters);
	
	OpenForm(
		"InformationRegister.AssetActivityRecords.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure
