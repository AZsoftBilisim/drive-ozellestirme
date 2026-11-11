#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	FinancialReportingServer.SetLayoutParameter(SettingsComposer, "CurrentDate", CurrentSessionDate(), True);
	
EndProcedure

#EndIf