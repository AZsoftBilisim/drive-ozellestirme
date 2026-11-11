#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(TrimAll(Value)) Then
		Value = "0";
	EndIf;
	
EndProcedure


#EndRegion

#EndIf
