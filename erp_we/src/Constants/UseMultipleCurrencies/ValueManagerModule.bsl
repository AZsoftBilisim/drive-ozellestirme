#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Constants.NotUseMultipleCurrencies.Set(Not ThisObject.Value);
	
EndProcedure

#EndRegion

#EndIf
