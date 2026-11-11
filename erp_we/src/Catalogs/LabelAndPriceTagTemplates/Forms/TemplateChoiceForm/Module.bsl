
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins Then
		WhetherTemplateIsPredefined = Upper("StorageBins");
	ElsIf Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag Then
		WhetherTemplateIsPredefined = Upper("Goods");
	ElsIf Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel Then
		WhetherTemplateIsPredefined = Upper("Goods");
	ElsIf Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForDelivery Then
		WhetherTemplateIsPredefined = Upper("Deliveries");
	ElsIf Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel Then
		WhetherTemplateIsPredefined = Upper("ItemsBatches");
	ElsIf Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel Then
		WhetherTemplateIsPredefined = Upper("PackingLists");
	ElsIf Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationTape
		Or Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper Then
		WhetherTemplateIsPredefined = Upper("InventoryInOperation");
	ElsIf Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape
		Or Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper Then
		WhetherTemplateIsPredefined = Upper("Assets");
	ElsIf Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper
	 	Or Parameters.Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape Then
		WhetherTemplateIsPredefined = Upper("SubAssets");
	EndIf;
	
	LabelAndPriceTagTemplatesLocalization.WhenCreatingTemplateSelectionFormOnServer(
		ThisObject, Parameters, WhetherTemplateIsPredefined);
		
	LengthOfPredefinedTemplateAttribute = StrLen(WhetherTemplateIsPredefined);
	For Each TemplateMetadata In Metadata.FindByType(Type("CatalogRef.LabelAndPriceTagTemplates")).Templates Do
		If TemplateMetadata.TemplateType = Metadata.ObjectProperties.TemplateType.SpreadsheetDocument Then
			If Upper(Right(TemplateMetadata.Name, LengthOfPredefinedTemplateAttribute)) = WhetherTemplateIsPredefined Then
				Template = TemplateMetadata.Name;
				Items.Template.ChoiceList.Add(TemplateMetadata.Name, TemplateMetadata.Synonym);
			EndIf;
		EndIf;
	EndDo;

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Close(Template);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion