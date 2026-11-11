
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	FormCode = "Catalog_ItemsCharacteristics_ChoiceForm";
	
	Products          = Undefined;
	ItemVariantsOwner = Undefined;
	
	If Parameters.Filter.Property("Owner") Then
		
		// Let's move the "standard" selection by owner to the Parameterowner property
		Parameters.SettingTheOwner = Parameters.Filter.Owner;
		Parameters.Filter.Delete("Owner");
		
	EndIf;
	
	If Parameters.Property("SettingTheOwner", ItemVariantsOwner) And ValueIsFilled(ItemVariantsOwner) Then
		
		SelectGoodsServer.SetSelectionByOwnerCharacteristics(ThisForm);
		
	ElsIf Parameters.Property("Products", Products) And ValueIsFilled(Products) Then
		
		If Catalogs.Products.CheckUsageCharacteristicsAndGetOwnerToSelect(Products, ItemVariantsOwner) Then
			
			If ItemVariantsOwner = Undefined Then
				
				ExceptionText = NStr("vi = 'Đối với mặt hàng này chưa đặt đặc tính.';
									|ru = 'Для данной номенклатуры характеристики не заданы.';
									|en = 'Variants are not specified for these products.'; fa = 'Variants are not specified for these products.';
									|it = 'Nessuna caratteristica è specificata per questo articolo.';
									|pl = 'Dla danego towaru nie określono charakterystyk.';
									|tr = 'Bu ürün için varyantlar belirlenmedi.'");
				Raise ExceptionText;
				
			Else
				
				SelectGoodsServer.SetSelectionByOwnerCharacteristics(ThisForm);
				
			EndIf;
			
		Else
			
			ExceptionText = NStr("vi = 'Đối với mặt hàng này đã ngắt sử dụng đặc tính.';
								|ru = 'Для данной номенклатуры отключено использование характеристик.';
								|en = 'Variants are disabled for these products.'; fa = 'Variants are disabled for these products.';
								|it = 'L''utilizzo delle caratteristiche non è abilitato per questo articolo.';
								|pl = 'Dla danego towaru wyłączono używanie charakterystyk.';
								|tr = 'Bu öğe için varyantların kullanımı devre dışı bırakıldı.'");
			Raise ExceptionText;
			
		EndIf;
		
	EndIf;
	
	If TypeOf(ItemVariantsOwner) = Type("CatalogRef.ItemKinds") Then
		
		ProductKind = ItemVariantsOwner;
		
	ElsIf TypeOf(ItemVariantsOwner) = Type("CatalogRef.Products") Then
		
		ProductKind = Common.ObjectAttributeValue(ItemVariantsOwner, "ProductKind");
		
	EndIf;
	
	SetSelectionByTypeOfProductByParameters_();
	
	If ValueIsFilled(Parameters.SetPriceCalculationOptions) Then
		CommonClientServer.SetDynamicListParameter(List, "SetPriceCalculationOptions", Parameters.SetPriceCalculationOptions, True);
		CommonClientServer.SetDynamicListParameter(List, "Products", Products, True);
	EndIf;
	
	SelectGoodsServer.FillInFeatureSelectionTree(ThisForm);
	
	ThereAreSelectionsAvailable                      = FilterTree.GetItems().Count() > 0;
	Items.SelectionTreeGroup.Visible   = ThereAreSelectionsAvailable;
	UseFilters                      = ThereAreSelectionsAvailable;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ItemsCharacteristics" 
		And ValueIsFilled(Source) Then
		
		Items.List.CurrentRow = Source;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseFiltersOnChange(Item)
	
	UseFiltersWhenChangingOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy And Not Var_Group Then
		
		Cancel = True;
		
		ParametersForCreatingForm = New Structure;
		ParametersForCreatingForm.Insert("Owner");
		ParametersForCreatingForm.Insert("ProductKind");
		ParametersForCreatingForm.Insert("AddressOfParameterTable");
		
		If UseFilters
			And ValueIsFilled(ProductKind)
			And FilterTree.GetItems().Count() > 0 Then
			
			ParametersForCreatingForm.AddressOfParameterTable = AddressOfSelectionTreeParameterTableOnServer();
			
		EndIf;
		
		ParametersForCreatingForm.ProductKind = ProductKind;
		ParametersForCreatingForm.Owner = ItemVariantsOwner;
		
		OpenForm("Catalog.ItemsCharacteristics.ObjectForm",
			New Structure("AdditionalParameters",ParametersForCreatingForm),
			ThisObject);
		
	EndIf;
	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFilterTree

&AtClient
Procedure FilterTreeFilterOnChange(Item)
	
	SelectGoodsClient.FilterTreeFilterOnChange(ThisForm, New CallbackDescription("SelectionTreeWhenStateChanges", ThisObject));
	
EndProcedure

&AtClient
Procedure FilterTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectGoodsClient.FilterTreeSelection(ThisForm, New CallbackDescription("SelectionTreeWhenStateChanges", ThisObject));
	
EndProcedure

&AtClient
Procedure SelectionTreeWhenStateChanges(Result, AdditionalParameters) Export 
	
	If Result = Undefined Then
		Return;
	ElsIf Result Then
		SelectGoodsClient.SelectionTreeWhenStateChanges(ThisForm);
		
		SelectionTreeSelectionWhenModifiedOnServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTreePresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterTree.Filter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTreeFilterPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterTree.FixedValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, True, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTree.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseFilters");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FormBackColor);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTreeFilterPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseFilters");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

EndProcedure

&AtServer
Procedure SetSelectionByTypeOfProductByParameters_()
	
	Products = Undefined;
	If Not Parameters.Property("Products", Products) 
		Or Not ValueIsFilled(Products) Then
		Return;
	EndIf;
	
	ItemsTypeSet = Enums.ItemsTypes.Set; 
	If Not Common.ObjectAttributeValue(Products, "ItemsType") = ItemsTypeSet Then
		Return;
	EndIf;
	
	FilterValue = Undefined;
	If Not Parameters.Filter.Property("ItemsType", FilterValue) Then
		Return;
	EndIf;
	
	If Not TypeOf(FilterValue) = Type("Array") Then
		Return;
	EndIf;
	
	If FilterValue.Find(ItemsTypeSet) = Undefined Then
		Return;
	EndIf;
	
	LimitSetsByService = FilterValue.Find(Enums.ItemsTypes.OperationService) <> Undefined
		Or FilterValue.Find(Enums.ItemsTypes.Work_5) <> Undefined;
	LimitSetsByProduct = FilterValue.Find(Enums.ItemsTypes.ReusablePackage) <> Undefined
		Or FilterValue.Find(Enums.ItemsTypes.OwnGoods) <> Undefined;
		
	If LimitSetsByService = LimitSetsByProduct Then
		Return;
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List, "Products", Products, True);
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"ContainsServices",
		LimitSetsByService,
		DataCompositionComparisonType.Equal,,
		True);
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"ContainsGoods",
		LimitSetsByProduct,
		DataCompositionComparisonType.Equal,,
		True);
		
EndProcedure

#Region Other

&AtServer
Procedure UseFiltersWhenChangingOnServer()
	
	SelectGoodsServer.WhenChangingUseOfFilters(ThisForm);
	
EndProcedure

&AtServer
Procedure SelectionTreeSelectionWhenModifiedOnServer()
	
	SelectGoodsServer.FilterTreeFilterOnChange(ThisForm);
	
EndProcedure

&AtServer
Function AddressOfSelectionTreeParameterTableOnServer()
	
	TableAddress = SelectGoodsServer.AddressOfSelectionTreeParameterTable(ThisForm);
	Return TableAddress;
	
EndFunction

#EndRegion

#EndRegion
