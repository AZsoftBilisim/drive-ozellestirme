#If Not MobileStandaloneServer Then
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ProductsServerCall.ExpirationDateUnitsProcessingOfSelectionDataAcquisition(ChoiceData,
																						Parameters,
																						StandardProcessing);
	
EndProcedure

#EndRegion
#EndIf