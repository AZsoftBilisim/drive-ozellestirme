#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	OpenForm("DataProcessor.InternationalCurrencyClassifier.Form.CurrencyClassifier", , CommandExecuteParameters.Source);
EndProcedure

#EndRegion