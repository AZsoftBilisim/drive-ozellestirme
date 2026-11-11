#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If ImportPackingLists Then
		NotCheckedAttributeArray = New Array;
		NotCheckedAttributeArray.Add("Goods.Products");
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	EndIf;
EndProcedure

#EndRegion

#EndIf