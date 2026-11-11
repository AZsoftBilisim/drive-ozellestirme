
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = ProvisionInDocumentsClient.OrderSecurityStateFormParameters("ORDERLIST");
	FormParameters.Orders = CommandParameter;
	OpenForm("DataProcessor.OrderSupplyForecast.Form",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);

EndProcedure