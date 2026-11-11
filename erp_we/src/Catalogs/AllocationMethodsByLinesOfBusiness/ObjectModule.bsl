#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;

	If AllocatedAccordingToRule <> Enums.AllocationRulesByLinesOfBusiness.InProportionToFactors Then
		NotCheckedAttributeArray.Add("LinesOfBusiness");
		NotCheckedAttributeArray.Add("LinesOfBusiness.ZoomRatio");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

	If AllocatedAccordingToRule <> Enums.AllocationRulesByLinesOfBusiness.InProportionToFactors
	   And LinesOfBusiness.Total("ZoomRatio") <> 0
	Then
		Array = New Array(LinesOfBusiness.Count());	
		LinesOfBusiness.LoadColumn(Array, "ZoomRatio");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
