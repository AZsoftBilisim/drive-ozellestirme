#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	For Each SetRow In ThisObject Do
		AccountingPoliciesTaxSettingsLocalization.VATAccountingSettingsBeforeWrite(SetRow);
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
