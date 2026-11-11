#If Not MobileStandaloneServer Then

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	WarehousesServerCall.TypesOfOperationsForAdjustingBalanceOfGoodsProcessingReceiptOfSelectionData(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#EndIf
