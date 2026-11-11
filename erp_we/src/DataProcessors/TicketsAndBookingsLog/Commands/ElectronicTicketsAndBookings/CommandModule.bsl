#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	KeyOperation = "DataProcessor.TicketsAndBookingsLog.Command.ElectronicTicketsAndBookings";
	PerformanceMonitorClient.TimeMeasurement(KeyOperation);
	
	FormParameters = New Structure("", );
	OpenForm("DataProcessor.TicketsAndBookingsLog.Form",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
		
EndProcedure

#EndRegion