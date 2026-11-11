#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = GetAvailableValues();
	
EndProcedure

#EndRegion

#Region Private

// The function fills in the list 
// of selection data values.
//
Function GetAvailableValues()
	
	AvailableValues = New ValueList;
	TradeManagement = GetFunctionalOption("TradeManagement");

	For Each EnumerationValue In Metadata.Enums.OptionsForRegisteringServiceDocuments.EnumValues Do
		If TradeManagement Then
			If EnumerationValue.Name = "ReceiptOfServicesIsReversed" Then
				Continue;
			EndIf;
		EndIf;

		Ref = Enums.OptionsForRegisteringServiceDocuments[EnumerationValue.Name];

		AvailableValues.Add(Ref, EnumerationValue.Synonym);
	EndDo;
	
	Return AvailableValues;
	
EndFunction

#EndRegion
	
#EndIf