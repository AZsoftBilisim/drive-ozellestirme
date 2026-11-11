
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FormCode = "Catalog_ItemsCharacteristics_ChoiceForm";
	
	Products          = Undefined;
	ItemVariantsOwner = Undefined;
	
	If Parameters.Filter.Property("Owner") Then
		
		// Let's move the "standard" selection by owner to the Parameterowner property
		Parameters.SettingTheOwner = Parameters.Filter.Owner;
		Parameters.Filter.Delete("Owner");
		
	EndIf;
	
	If Parameters.Property("SettingTheOwner", ItemVariantsOwner)
		And ValueIsFilled(ItemVariantsOwner) Then
		
		MobileWarehouseKeeperWorkspace.SetSelectionByOwnerCharacteristics(ThisForm);
		
	ElsIf Parameters.Property("Products", Products) And ValueIsFilled(Products) Then
		
		If MobileWarehouseKeeperWorkspace.CheckUsageCharacteristicsAndGetOwnerToSelect(Products, ItemVariantsOwner) Then
			
			If ItemVariantsOwner = Undefined Then
				
				ExceptionText = NStr("vi = 'Đối với mặt hàng này chưa đặt đặc tính.';
									|ru = 'Для данной номенклатуры характеристики не заданы.';
									|en = 'Variants are not specified for these products.'; fa = 'Variants are not specified for these products.';
									|it = 'Nessuna caratteristica è specificata per questo articolo.';
									|pl = 'Dla danego towaru nie określono charakterystyk.';
									|tr = 'Bu ürün için varyantlar belirlenmedi.'");
				Raise ExceptionText;
				
			Else
				
				MobileWarehouseKeeperWorkspace.SetSelectionByOwnerCharacteristics(ThisForm);
				
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
		
		ProductKind = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(ItemVariantsOwner, "ProductKind");
		
	EndIf;
	
	SetSelectionByTypeOfProductByParameters_();
	
	If ValueIsFilled(Parameters.SetPriceCalculationOptions) Then
		MobileWarehouseKeeperWorkspace.SetDynamicListParameter(List, "SetPriceCalculationOptions", Parameters.SetPriceCalculationOptions, True);
		MobileWarehouseKeeperWorkspace.SetDynamicListParameter(List, "Products", Products, True);
	EndIf;
	
	ThereAreSelectionsAvailable                      = FilterTree.GetItems().Count() > 0;
	Items.SelectionTreeGroup.Visible   = ThereAreSelectionsAvailable;
	UseFilters                      = ThereAreSelectionsAvailable;
	
#If Not MobileStandaloneServer Then
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core
#EndIf

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ItemsCharacteristics" And ValueIsFilled(Source) Then
		
		Items.List.CurrentRow = Source;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetSelectionByTypeOfProductByParameters_()
	
	Products = Parameters.Products;
	If Not ValueIsFilled(Products) Then
		Return;
	EndIf;
	
	ItemsTypeSet = Enums.ItemsTypes.Set; 
	If Not MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Products, "ItemsType") = ItemsTypeSet Then
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
		Or FilterValue.FindByValue(Enums.ItemsTypes.OwnGoods) <> Undefined;
		
	If LimitSetsByService = LimitSetsByProduct Then
		Return;
	EndIf;
	
	MobileWarehouseKeeperWorkspace.SetDynamicListParameter(List, "Products", Products, True);
	
	MobileWarehouseKeeperWorkspaceClientServer.SetDynamicListFilterItem(List,
		"ContainsServices",
		LimitSetsByService,
		DataCompositionComparisonType.Equal,,
		True);
		
	MobileWarehouseKeeperWorkspaceClientServer.SetDynamicListFilterItem(
		List,
		"ContainsGoods",
		LimitSetsByProduct,
		DataCompositionComparisonType.Equal,,
		True);
		
EndProcedure

#EndRegion
