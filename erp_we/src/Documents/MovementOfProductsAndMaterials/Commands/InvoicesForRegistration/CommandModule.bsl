
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MovementOfProductsAndMaterials.Command.InvoicesForRegistration");
	// End StandardSubsystems.PerformanceMeasurement
	
	FormParameters = New Structure;
	OpenForm("Document.MovementOfProductsAndMaterials.Form.Workplace",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure
