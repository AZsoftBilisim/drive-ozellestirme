
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	#If MobileClient Then
		OpenForm(
			"DataProcessor.ExecutionOfOperations2_2.Form.MobileApplicationDesktop",
			,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window,
			CommandExecuteParameters.URL);
	#Else
		OpenForm(
			"DataProcessor.PerformOperationsMES.Form.Workplace",
			,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window,
			CommandExecuteParameters.URL);
	#EndIf
	
EndProcedure

#EndRegion
