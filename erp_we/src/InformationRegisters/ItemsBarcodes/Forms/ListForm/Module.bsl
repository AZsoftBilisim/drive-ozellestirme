
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Products") Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Products",
			Parameters.Products,
			DataCompositionComparisonType.Equal,
			,
			True);
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing, Parameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ItemsBarcodes" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	ProductsLocalization.WhenReceivingDataFromListOfItemBarcodesAtServer(TagName, Settings, Rows);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	If GetFunctionalOption("UseItemVariants") Then
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.Characteristic.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("List.Characteristic");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
														|ru = '<характеристики не используются>';
														|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
														|it = '<le caratteristiche non vengono usate>';
														|pl = '<charakterystyki nie dotyczą>';
														|tr = '<varyantlar kullanılmamaktadır>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	EndIf;
	
	If GetFunctionalOption("UseItemsBatchWarehouse") Then
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.Series.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("List.SeriesAreUsed");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng sê-ri>';
														|ru = '<серии не используются>';
														|en = '<batches are not used>'; fa = '<batches are not used>';
														|it = '<le serie non sono utilizzate>';
														|pl = '<serie nie są używane>';
														|tr = '<partiler kullanılmamaktadır>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	EndIf;
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField	= "UnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField			= "List.Package";
	
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Package.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

#EndRegion
