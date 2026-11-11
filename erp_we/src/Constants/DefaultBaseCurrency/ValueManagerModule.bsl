#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueIsFilled(ThisObject.Value) Then
		ProcessingOfExchangeRatesTM.CheckCorrectnessOfRelativeRateOn01_01_1980(ThisObject.Value);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf