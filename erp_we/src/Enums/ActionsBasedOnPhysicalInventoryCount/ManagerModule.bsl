#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates an array of references to the enumeration by the specified keys
//
// Parameters:
// 		Actions - String - A string of comma-separated enumeration keys.
//
// Returns:
// 		Array - Array of references to enumeration elements.
//
Function ArrayOfValuesBySpecifiedNames(Actions) Export
	
	Array = New Array;
	
	Structure = New Structure(Actions);
	For Each KeyAndValue In Structure Do
		EnumerationValue = Enums.ActionsBasedOnPhysicalInventoryCount[KeyAndValue.Key];
		If ValueIsFilled(EnumerationValue) Then
			Array.Add(EnumerationValue);
		EndIf;
	EndDo;
	
	Return Array;
	
EndFunction

#EndRegion

#EndIf
