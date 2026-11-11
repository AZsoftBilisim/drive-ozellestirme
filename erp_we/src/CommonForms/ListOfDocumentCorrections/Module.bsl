
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CorrectedDocument = ?(ValueIsFilled(Parameters.CorrectedDocument), Parameters.CorrectedDocument, Parameters.CurrentDocument);
	CurrentDocument = Parameters.CurrentDocument;
	
	SetConditionalAppearance();
	
	CommonClientServer.SetDynamicListParameter(ListOfCorrections, "CorrectedDocument", CorrectedDocument);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CorrectedDocumentClick(Item, StandardProcessing)
	
	ShowValue(, CorrectedDocument);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfCorrections

&AtClient
Procedure ListOfCorrectionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(, Items.ListOfCorrections.CurrentData.Ref);
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfCorrectionsDate.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfCorrectionsNumber.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfCorrectionsRef.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue =  New DataCompositionField("ListOfCorrections.Ref");
	ItemFilter.ComparisonType =  DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = CurrentDocument;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
EndProcedure

#EndRegion

