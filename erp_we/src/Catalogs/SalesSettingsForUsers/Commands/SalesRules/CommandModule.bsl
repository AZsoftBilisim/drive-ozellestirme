
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Ref = SalesSettingsForUsersServerCall.SettingObjectRestrictions(CommandParameter);
	If Ref = Undefined Then
		FillingValues = New Structure("Owner", CommandParameter);
		FormParameters = New Structure("FillingValues", FillingValues);
	Else
		FormParameters = New Structure("Key", Ref);
	EndIf;
	
	OpenForm("Catalog.SalesSettingsForUsers.Form.ItemForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure
