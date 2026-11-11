
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	// The form can be opened in the following modes:
	// 1. In the mode of configuring route maps for a given nomenclature.
	//    In this mode, the user cannot change the nomenclature and the choice of route maps is limited.
	//
	// 2. In the mode of configuring route maps for a given nomenclature and route map.
	//    In this mode, the user cannot change the nomenclature and route map.
	//
	// 3. In the route map settings mode for route maps.
	//    In this mode, the user cannot change the route map and the choice of nomenclature is limited.
	//
	// 4. In normal mode.
	//    There are no restrictions in this mode.
	
	Parameters.Property("ForTheSpecifiedProducts",    ForTheSpecifiedProducts);
	Parameters.Property("ForSpecifiedOperationsSheet", ForSpecifiedOperationsSheet);
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Products", FilterProduct, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Department", FilterDepartment, QuickFilterStructure);
	
	If ForTheSpecifiedProducts Then
		
		Items.FilterProduct.ReadOnly = True;

	EndIf; 
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"Department", 
		FilterDepartment, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(FilterDepartment));
	
EndProcedure

&AtClient
Procedure FilterProductOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"Products", 
		FilterProduct, 
		DataCompositionComparisonType.Equal,
		, 
		ValueIsFilled(FilterProduct));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	FillingValues = New Structure;
	FillingValues.Insert("Department",   FilterDepartment);
	FillingValues.Insert("Products",    FilterProduct);
	FillingValues.Insert("RouteSheet", ForSpecifiedOperationsSheet);
	
	FormParameters = New Structure("FillingValues", FillingValues);
	
	If ForTheSpecifiedProducts Then
		OpenForm("InformationRegister.MainRouteSheets.Form.FormEntriesForSpecifiedItems", FormParameters); 
	Else
		OpenForm("InformationRegister.MainRouteSheets.RecordForm", FormParameters); 
	EndIf; 
	
EndProcedure

&AtClient
Procedure ListAfterDeleteRow(Item)
	
	ProductDataManagementClient.NotifyAboutRecordingOfMainRouteMap();

EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If ForTheSpecifiedProducts Then
		StandardProcessing = False;
		OpenEntryForm();
	EndIf; 
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	If ForTheSpecifiedProducts Then
		Cancel = True;
		OpenEntryForm();
	EndIf; 
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.BillOfMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("ForGivenSpecification");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterBillOfMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

EndProcedure

#Region Other

&AtClient
Procedure OpenEntryForm()

	CurrentData = Items.List.CurrentData;
	
	RecordKeyData = New Structure("Products,Characteristic,Department", 
									CurrentData.Products, 
									CurrentData.Characteristic, 
									CurrentData.Department);
									
	ArrayOfConstructorParameters = New Array();
	ArrayOfConstructorParameters.Add(RecordKeyData);
	
	RecordKey = New("InformationRegisterRecordKey.MainRouteSheets", ArrayOfConstructorParameters);	
	
	OpenForm("InformationRegister.MainRouteSheets.Form.FormEntriesForSpecifiedItems", New Structure("Key", RecordKey));
	
EndProcedure

#EndRegion

#EndRegion
