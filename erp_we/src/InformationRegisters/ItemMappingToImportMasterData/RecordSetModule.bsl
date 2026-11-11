#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	For Each Record In ThisObject Do
		CalculateMatchedAttribute(Record);
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Procedure CalculateMatchedAttribute(Record)
	
	Record.Matched = ValueIsFilled(Record.Products) And ValueIsFilled(Record.Id);
	
EndProcedure

#EndRegion

#EndIf