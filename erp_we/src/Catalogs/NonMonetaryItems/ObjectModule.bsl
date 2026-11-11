
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not ValueIsFilled(Description) Then
		Description = NameForPrinting;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
