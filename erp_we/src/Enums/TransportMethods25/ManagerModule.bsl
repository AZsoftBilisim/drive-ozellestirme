//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ExcludedValues = New Array; // Array of EnumRef.TransportMethods25
	
	If Parameters.Property("ExcludedValues", ExcludedValues) Then
		
		CommonClientServer.CheckParameter(
			"Enum.TransportMethods25.ChoiceDataGetProcessing",
			"ExcludedValues",
			ExcludedValues,
			Type("FixedArray"));
		
		StandardProcessing = False;
		
	EndIf;
	
	If Not StandardProcessing Then
		
		TMCommonUse.SelectableEnumerationValues(
			"TransportMethods25",
			ChoiceData,
			Parameters,
			ExcludedValues);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf