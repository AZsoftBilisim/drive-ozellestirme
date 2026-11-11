#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array of String - names of the blocked details.
//
Function GetObjectAttributesToLock() Export

	AttributesToLock = New Array;
	AttributesToLock.Add("RateType");
	AttributesToLock.Add("Country");
	AttributesToLock.Add("UnitOfMeasure");
	AttributesToLock.Add("Currency");
	
	Return AttributesToLock;

EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Code");
	Fields.Add("Description");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	Presentation = Data.Code + " (" + Data.Description + ")";
	
EndProcedure

#EndRegion
