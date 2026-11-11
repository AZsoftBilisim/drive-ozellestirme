
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	RegisterShiftsOverridable.OnSetNewNumber(ThisObject, StandardProcessing, Prefix);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	RegisterShiftsOverridable.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	RegisterShiftsOverridable.Filling(ThisObject, FillingData, FillingText, StandardProcessing);
	
EndProcedure

#EndRegion

#EndIf
