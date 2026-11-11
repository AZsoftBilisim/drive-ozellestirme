#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	CallbackDescription = New CallbackDescription("LinkSynchronizationCompletion", ThisObject, CommandExecuteParameters);
	
	OpenForm(
		"InformationRegister.ObjectsIntegratedWith1CDocumentManagement.Form.LinkSynchronization",,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure LinkSynchronizationCompletion(ExcessiveLinks, CommandExecuteParameters) Export
	
	If TypeOf(ExcessiveLinks) <> Type("Structure") Then
		Return;
	EndIf;
	
	OpenForm(
		"InformationRegister.ObjectsIntegratedWith1CDocumentManagement.Form.ExcessiveLinks",
		ExcessiveLinks,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion