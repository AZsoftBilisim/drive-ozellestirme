#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	UseLocal = GetFunctionalOption("UseLocal");

	NotCheckedAttributeArray = New Array;

	If Not (CostAllocationOptionLocal = Enums.CostAllocationOptions.ToProductionCosts
		And CostAllocationOptionManag = Enums.CostAllocationOptions.ToProductionCosts)
	Then
		NotCheckedAttributeArray.Add("CostSharingRule");
		NotCheckedAttributeArray.Add("ProductCostElement");
	EndIf;
	
	If Not UseLocal Or Not LocalizationRFService Then
		NotCheckedAttributeArray.Add("CostAllocationOptionTax");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);

EndProcedure

#EndRegion

#EndIf