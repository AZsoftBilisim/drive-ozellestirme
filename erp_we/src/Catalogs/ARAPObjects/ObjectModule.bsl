#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsNew() Then
		ARAPAccountingRegistersAreNotDividedByLinesOfBusiness = True;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ARAPAccountingInternal.ClearSettlementRegistersAndDeleteServiceRecorders(Ref, Undefined);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If OnlyBalance Then
		CheckedAttributes.Clear();
	EndIf;
EndProcedure

#EndRegion

#EndIf
