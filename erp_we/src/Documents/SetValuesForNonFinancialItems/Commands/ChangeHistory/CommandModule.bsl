#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure("NonFinancialItem", CommandParameter);
	OpenForm("Document.SetValuesForNonFinancialItems.Form.HistoryOfValueInput", 
							FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, 
							CommandExecuteParameters.Window, CommandExecuteParameters.URL);
EndProcedure

#EndRegion