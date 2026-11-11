#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ApplicationForImportationOfGoods.Command.ImportApplicationsForRegistration");
	
	OpenForm(NameOfApplicationFormForImportOfGoods(), 
		, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function NameOfApplicationFormForImportOfGoods()
	Return Documents.ApplicationForImportationOfGoods.NameOfApplicationFormForImportOfGoods();
EndFunction

#EndRegion


