#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load
	 Or AdditionalProperties.Property("ThisIsNewSetOfRecords") Then
		Return;
	EndIf;   	

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

#EndRegion

#EndIf