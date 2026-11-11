#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	NotCheckedAttributeArray = New Array;
	
	If Not TemplateAssignment = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel Then
		NotCheckedAttributeArray.Add("PackingLists");
	EndIf;
	
	If TemplateAssignment = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag
		Or TemplateAssignment = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel Then
		NotCheckedAttributeArray.Add("LabelsTemplate");
		NotCheckedAttributeArray.Add("Copies");
	EndIf;
	
	If Not TemplateAssignment = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins Then
		NotCheckedAttributeArray.Add("StorageBins");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
EndProcedure

#EndIf
