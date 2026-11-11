#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	TMCommonUse.ProcessingOfSelectionDataAcquisitionBusinessOperations(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#EndIf
#EndIf

