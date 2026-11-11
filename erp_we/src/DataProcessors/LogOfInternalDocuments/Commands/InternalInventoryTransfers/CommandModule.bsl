
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", "InternalInventoryTransfers");
	
	OpenForm("DataProcessor.LogOfInternalDocuments.Form.DocumentsList",
		FormParameters,
		CommandExecuteParameters.Source,
		False, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
		
EndProcedure