
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", "CustomerInvoicesServicesAndAssets");
	OpenForm("DataProcessor.LogOfSalesDocuments.Form.DocumentsList", 
		FormParameters,
		CommandExecuteParameters.Source,
		"CustomerInvoicesServicesAndAssets",
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
EndProcedure
