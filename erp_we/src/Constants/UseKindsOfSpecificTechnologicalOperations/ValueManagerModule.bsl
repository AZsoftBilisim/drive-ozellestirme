
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Documents.ProductionOperation2_2.SetUseOfProperties();
	
EndProcedure

#EndRegion

#EndIf
