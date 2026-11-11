#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then 
		Return;
	EndIf;
	
	If RelevantTo = '00010101000000' Then 
		RelevantTo = '39991231235959';
	EndIf;
	
EndProcedure

#EndRegion

#EndIf