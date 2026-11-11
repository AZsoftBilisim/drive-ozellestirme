
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PerformanceMonitorClient.TimeMeasurement(
		"CommonCommands.ConsumptionReportsSubcontractingServicesDeliveredToRegister");
	
	FormParameters = New Structure("PurposeUseKey", "DocumentsBetweenCompaniesAll");
	
	OpenForm(
		"Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Form.WorkplaceForm",
		FormParameters,
		CommandExecuteParameters.Source,
		"DocumentsBetweenCompaniesAll",
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion