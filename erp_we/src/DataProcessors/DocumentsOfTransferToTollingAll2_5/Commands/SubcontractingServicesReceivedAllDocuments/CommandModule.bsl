#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure("FormAssignmentKey", "SubcontractingServicesReceivedAllDocuments");
	
	OpenForm("DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.DocumentsList", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
EndProcedure

#EndRegion