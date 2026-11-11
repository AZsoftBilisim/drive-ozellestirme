#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If TMDataExchange.IsSubordinateDIBNode() Then
		Cancel = True; 
	EndIf;
		
EndProcedure

#EndRegion

#EndIf