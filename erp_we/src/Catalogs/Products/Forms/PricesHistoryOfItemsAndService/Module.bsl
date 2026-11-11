
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	FilterProducts = Parameters.Key;
	
	If UsePriceManagementSystem25 Then
		Items.ItemPricePage.Visible = False;
		Items.ItemPricePage2_5.Visible = AccessRight("View",
			Metadata.InformationRegisters.ItemsPrices25);
	Else	
		Items.ItemPricePage2_5.Visible = False;
		Items.ItemPricePage.Visible = AccessRight("View",
			Metadata.InformationRegisters.ItemsPrices);
	EndIf;
	Items.SupplierItemPricesPage.Visible = AccessRight("View",
		Metadata.InformationRegisters.ItemsPricesOfVendor);
	
	If Items.ItemPricePage.Visible Then
		
		CommonClientServer.SetDynamicListFilterItem(
			ItemsPrices,
			"Products",
			FilterProducts,
			DataCompositionComparisonType.Equal,
			"Products",
			True);
	ElsIf Items.ItemPricePage2_5.Visible Then
		
		CommonClientServer.SetDynamicListFilterItem(
			ItemsPrices2_5,
			"Products",
			FilterProducts,
			DataCompositionComparisonType.Equal,
			"Products",
			True);
	EndIf;
	
	If Items.SupplierItemPricesPage.Visible Then
		
		CommonClientServer.SetDynamicListFilterItem(
			ItemsPricesOfVendor,
			"Products",
			FilterProducts,
			DataCompositionComparisonType.Equal,
			"Products",
			True);
		
	EndIf;
	
	ListOfPriceTypes = New ValueList();
	If Parameters.Property("PriceKind") Then
		ListOfPriceTypes.Add(Parameters.PriceKind);
		ProductPriceType = Parameters.PriceKind;
	Else
		ListOfPriceTypes.LoadValues(Catalogs.TypesOfPrices.AvailableTypesOfPrices());	
	EndIf;
	
	If UsePriceManagementSystem25 Then
		CommonClientServer.SetDynamicListFilterItem(
			ItemsPrices2_5, 
			"PriceKind", 
			ListOfPriceTypes, 
			DataCompositionComparisonType.InList, 
			"TypeOfPriceRestrictionOnRights", 
			True);
	Else	
		CommonClientServer.SetDynamicListFilterItem(
			ItemsPrices, 
			"PriceKind", 
			ListOfPriceTypes, 
			DataCompositionComparisonType.InList, 
			"TypeOfPriceRestrictionOnRights", 
			True);
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ItemPricePeriodOnChange(Item)	
	
	ProductPricePeriodWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure ProductPriceTypeOnChange(Item)
	
	ProductPriceViewWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure SupplierSItemPricePeriodOnChange(Item)
	
	PricePeriodOfSupplierProductListWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure SupplierSItemPricePeriodClearing(Item, StandardProcessing)
	
	PricePeriodOfSupplierProductListWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure VendorPriceKindOnChange(Item)
	
	SupplierPriceViewWhenChangedOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure ProductPricePeriodWhenChangedOnServer()
	
	If UsePriceManagementSystem25 Then
		CommonClientServer.DeleteDynamicListFilterGroupItems(ItemsPrices2_5,"Period","Period");
		
		FilterItemsGroup = CommonClientServer.CreateFilterItemGroup(
			TMCommonUseClientServer.GetDynamicListSelection(ItemsPrices2_5).Items,
			"ProductPricesSelectionByPeriod",
			DataCompositionFilterItemsGroupType.AndGroup);			
	Else
		CommonClientServer.DeleteDynamicListFilterGroupItems(ItemsPrices,"Period","Period");
		
		FilterItemsGroup = CommonClientServer.CreateFilterItemGroup(
			TMCommonUseClientServer.GetDynamicListSelection(ItemsPrices).Items,
			"ProductPricesSelectionByPeriod",
			DataCompositionFilterItemsGroupType.AndGroup);			
	EndIf;
	
	CommonClientServer.AddCompositionItem(
		FilterItemsGroup,
		"Period",
		DataCompositionComparisonType.GreaterOrEqual,
		ItemPricePeriod.StartDate,
		"Period",
		ValueIsFilled(ItemPricePeriod.StartDate));
	
	// Set the selection element in the group.
	CommonClientServer.AddCompositionItem(FilterItemsGroup, "Period", DataCompositionComparisonType.LessOrEqual, 
		ItemPricePeriod.EndDate, "Period", ValueIsFilled(ItemPricePeriod.EndDate));
	
EndProcedure

&AtServer
Procedure ProductPriceViewWhenChangedOnServer()
	
	If UsePriceManagementSystem25 Then
		CommonClientServer.DeleteDynamicListFilterGroupItems(ItemsPrices2_5,,"PriceKind");
		
		CommonClientServer.AddCompositionItem(
			TMCommonUseClientServer.GetDynamicListSelection(ItemsPrices2_5), "PriceKind", 
			DataCompositionComparisonType.Equal, ProductPriceType, "PriceKind", ValueIsFilled(ProductPriceType));
	Else			
		CommonClientServer.DeleteDynamicListFilterGroupItems(ItemsPrices,,"PriceKind");
		
		CommonClientServer.AddCompositionItem(
			TMCommonUseClientServer.GetDynamicListSelection(ItemsPrices), "PriceKind", 
			DataCompositionComparisonType.Equal, ProductPriceType, "PriceKind", ValueIsFilled(ProductPriceType));
	EndIf;
	
EndProcedure

&AtServer
Procedure PricePeriodOfSupplierProductListWhenChangedOnServer()
	
	CommonClientServer.DeleteDynamicListFilterGroupItems(ItemsPricesOfVendor,"Period","Period");
	
	FilterItemsGroup = CommonClientServer.CreateFilterItemGroup(
		TMCommonUseClientServer.GetDynamicListSelection(ItemsPricesOfVendor).Items,
		"ProductPricesSelectionByPeriod", DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(FilterItemsGroup, "Period", DataCompositionComparisonType.GreaterOrEqual,
		SupplierSItemPricePeriod.StartDate, "Period", ValueIsFilled(SupplierSItemPricePeriod.StartDate));
	
	// Set the selection element in the group.
	CommonClientServer.AddCompositionItem(FilterItemsGroup, "Period", 
		DataCompositionComparisonType.LessOrEqual, SupplierSItemPricePeriod.EndDate, "Period", 
		ValueIsFilled(SupplierSItemPricePeriod.EndDate));
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	CommonClientServer.DeleteDynamicListFilterGroupItems(ItemsPricesOfVendor,"Partner","Partner");
	
	CommonClientServer.AddCompositionItem(
		TMCommonUseClientServer.GetDynamicListSelection(ItemsPricesOfVendor), "Partner",
		DataCompositionComparisonType.Equal, Partner, "Partner", ValueIsFilled(Partner));
	
EndProcedure

&AtServer
Procedure SupplierPriceViewWhenChangedOnServer()
	
	CommonClientServer.DeleteDynamicListFilterGroupItems(ItemsPricesOfVendor,"VendorPriceKind","VendorPriceKind");
	
	CommonClientServer.AddCompositionItem(
		TMCommonUseClientServer.GetDynamicListSelection(ItemsPricesOfVendor), "VendorPriceKind",
		DataCompositionComparisonType.Equal, VendorPriceKind, "VendorPriceKind", ValueIsFilled(VendorPriceKind));
	
EndProcedure

#EndRegion

#EndRegion
