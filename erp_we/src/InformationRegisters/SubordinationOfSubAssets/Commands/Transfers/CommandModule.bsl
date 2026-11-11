
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterParameters = New Structure("SubAsset_", CommandParameter);
	FormParameters = New Structure("Filter", FilterParameters);
	
	OpenForm(
		"InformationRegister.SubordinationOfSubAssets.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure
