
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", "ProceedsFromOtherAssets");
	OpenForm("DataProcessor.LogOfPurchaseDocuments.Form.DocumentsList", 
		FormParameters,
		CommandExecuteParameters.Source,
		"ProceedsFromOtherAssets",
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
EndProcedure
