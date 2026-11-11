
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceData = New ValueList();
	
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ExciseStampLabel);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForBarcodesPackages);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationTape);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape);
	ChoiceData.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper);
EndProcedure

#EndRegion
