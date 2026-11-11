
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("DataProcessor.AvailabilityOfWorkCenterTypes.Form",, 
			CommandExecuteParameters.Source, 
			CommandExecuteParameters.Uniqueness, 
			CommandExecuteParameters.Window, 
			CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion