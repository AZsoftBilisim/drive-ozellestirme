#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	If Not GetFunctionalOption("LocalizationRFService") Then
		AttributesNotToCheck.Add("AccountingProcedure");
		AttributesNotToCheck.Add("RevaluationCycle");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

#EndRegion

#EndIf