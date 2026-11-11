//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	SegmentsAreUsed = GetFunctionalOption("UseProductSegments");
	
	ChoiceData = New ValueList; // List of values from the enumerationlink.Compositionsretrobonus Products
	ChoiceData.Add(Products);
	ChoiceData.Add(ProductItemProperty);
	If SegmentsAreUsed Then
		ChoiceData.Add(ProductSegments);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf