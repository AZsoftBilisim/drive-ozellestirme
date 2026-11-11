#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure("OpeningFromList");
	OpenForm("DataProcessor.DownloadingECBExchangeRates.Form", FormParameters);
EndProcedure

#EndRegion