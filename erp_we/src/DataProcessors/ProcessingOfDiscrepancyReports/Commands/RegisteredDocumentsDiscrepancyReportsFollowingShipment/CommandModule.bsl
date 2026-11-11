

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	FormParameters.Insert("DiscrepancyCertificate", CommandParameter);
	OpenForm("DataProcessor.ProcessingOfDiscrepancyReports.Form.RegisteredDocuments",
	             FormParameters,
	             CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness);
	
EndProcedure

#EndRegion

