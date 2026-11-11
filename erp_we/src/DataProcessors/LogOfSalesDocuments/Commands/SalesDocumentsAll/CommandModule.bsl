
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure("FormAssignmentKey", "SalesDocumentsAll");
	
	OpenForm("DataProcessor.LogOfSalesDocuments.Form.DocumentsList", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
EndProcedure
