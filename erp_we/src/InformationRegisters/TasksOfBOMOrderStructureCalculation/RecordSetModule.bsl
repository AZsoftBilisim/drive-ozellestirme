#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf