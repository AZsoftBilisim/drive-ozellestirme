
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormOfReconciliationOfSettlements = "Document.ARAPReconciliation2_4.Form.ListForm";
	
	If NewOnlineARAPAccounting() Then
		FormOfReconciliationOfSettlements = "DocumentJournal.ARAPReconciliations.Form.ListForm";
	EndIf;
	
	OpenForm(FormOfReconciliationOfSettlements,,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function NewOnlineARAPAccounting()
	
	Return GetFunctionalOption("NewOnlineARAPAccounting");
	
EndFunction

#EndRegion