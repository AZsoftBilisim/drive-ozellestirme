#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetOfCacheSettingsLimits = InformationRegisters.BudgetingLimitSettingsCache.CreateRecordSet();
	SetPrivilegedMode(True);
	SetOfCacheSettingsLimits.Write();
	
EndProcedure

#EndRegion

#EndIf
