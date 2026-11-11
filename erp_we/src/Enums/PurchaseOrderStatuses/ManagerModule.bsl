
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

Function ClosedStatusIsUsed() Export
	
	Return  GetFunctionalOption("DoNotClosePurchaseOrdersBeforeAllGoodsAreReceived")
		Or GetFunctionalOption("DoNotClosePurchaseOrdersWithoutCompletePayment");
	
EndFunction 

#EndRegion

#EndIf


#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	ChoiceData.Add(Enums.PurchaseOrderStatuses.NotApproved);
	ChoiceData.Add(Enums.PurchaseOrderStatuses.Approved);
	ChoiceData.Add(Enums.PurchaseOrderStatuses.Confirmed_);
	
	If GetFunctionalOption("DoNotClosePurchaseOrdersBeforeAllGoodsAreReceived")
		Or GetFunctionalOption("DoNotClosePurchaseOrdersWithoutCompletePayment") Then
		
		ChoiceData.Add(Enums.PurchaseOrderStatuses.Closed);
		
	EndIf;
	
EndProcedure

#EndRegion
