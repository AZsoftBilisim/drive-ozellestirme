#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	ReflectionRules = ThisObject.Unload();
	
	FinancialAccountingUponOperationalAccountingData.BeforeWritingReflectionRules(ReflectionRules, Cancel);
	FinancialAccountingUponLocalAccounting.BeforeWritingReflectionRules(ReflectionRules, Cancel);
	
EndProcedure

#EndRegion

#EndIf