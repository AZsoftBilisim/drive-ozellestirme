////////////////////////////////////////////////////////////////////////////////
// The module contains the procedures and functions necessary for the operation
// of product selection forms. The module contains auxiliary functions
// that are called from the client and server modules.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region WrappersForDeterminingTypeOfMatchingForms

// Checks whether the form is a matching form.
//
// Parameters:
// 	FormCode - String - Form code
//
// Returns:
// 	Boolean - True if it is any of the Forms of selection
//
Function ThisIsFormOfMatching(FormCode) Export
	
	Return FormCode = "Processing_SelectionOfGoodsInSalesDocument_Form"
		Or FormCode = "Processing_SelectionOfGoodsInPurchaseDocument_Form"
		Or FormCode = "Processing_SelectionByProductCategory_Form";
	
EndFunction

// Checks whether the selection form is included in the purchase documents.
//
// Parameters:
// 	FormCode - String - the code of the selection Form
//
// Returns:
// 	Boolean - True if it is a Form of selection in the purchase documents
//
Function ThisIsFormOfSelectionInPurchaseDocuments(FormCode) Export
	
	Return FormCode = "Processing_SelectionOfGoodsInPurchaseDocument_Form";
	
EndFunction

// Checks whether the selection form is included in the sales documents.
//
// Parameters:
// 	FormCode - String - the code of the selection Form
//
// Returns:
// 	Boolean - True if it is a Form of selection in the sales documents
//
Function ThisIsFormOfMatchingInSalesDocuments(FormCode) Export
	
	Return FormCode = "Processing_SelectionOfGoodsInSalesDocument_Form";
	
EndFunction

// Checks whether the "item Characteristics" directory selection form is used.
//
// Parameters:
// 	FormCode - String - the code of the selection Form
//
// Returns:
// 	Boolean - True if this is the Form of the choice of characteristics
//
Function ThisIsFormOfFeatureSelection(FormCode) Export
	
	Return FormCode = "Catalog_ItemsCharacteristics_ChoiceForm";
	
EndFunction

// Checks whether the "Nomenclature" directory selection form is used.
//
// Parameters:
// 	FormCode - String - the code of the selection Form
//
// Returns:
// 	Boolean - True if this is the Form of item selection
//
Function ThisIsFormOfProductSelection(FormCode) Export
	
	Return FormCode = "Catalog_Products_ChoiceForm";
	
EndFunction

// Checks whether the list form of the "Nomenclature" reference list is correct.
//
// Parameters:
// 	FormCode - String - the code of the selection Form
//
// Returns:
// 	Boolean - True if this is the Form of the item list
//
Function ThisIsProductListForm(FormCode) Export
	
	Return FormCode = "Catalog_Products_ListForm";
	
EndFunction

// Checks whether it is a form of similar products.
//
// Parameters:
// 	FormCode - String - the code of the selection Form
//
// Returns:
// 	Boolean - True if it is the Form of similar goods in the item list
//
Function ThisIsFormOfSimilarGoodsProduct(FormCode) Export
	
	Return FormCode = "Catalog_Products_SimilarProducts";
	
EndFunction

// Checks whether the selection form is based on product categories.
//
// Parameters:
// 	FormCode - String - the code of the selection Form
//
// Returns:
// 	Boolean - True if it is a Form of selecting goods by category
//
Function ThisIsFormForSelectingProductsByCategory(FormCode) Export
	
	Return FormCode = "Processing_SelectionByProductCategory_Form";
	
EndFunction

// Checks whether the price list is a form.
//
// Parameters:
// 	FormCode - String - the code of the selection Form
//
// Returns:
// 	Boolean - True if it is a price list Form
//
Function ThisIsPriceListForm(FormCode) Export
	
	Return FormCode = "Processing_PriceList_Form"
		Or FormCode = "Processing_PriceList_ConfigurationForm";
	
EndFunction

// Checks whether the price list is a form.
//
// Parameters:
// 	FormCode - String - the code of the selection Form
//
// Returns:
// 	Boolean - True if it is a price list Form
//
Function ThisIsSuppliersPriceListForm(FormCode) Export
	
	Return FormCode = "Processing_SupplierSPriceList_Form"
		Or FormCode = "Processing_SupplierPriceList_ConfigurationForm";
	
EndFunction

#EndRegion

#Region DeterminingNamesOfListsOnFormDependingOnSearchOption

// Returns the name of the list of characteristics by search option.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form, selection form.
//
// Returns:
//	String - the name of the list of characteristics.
//
Function NameOfListOfCharacteristicsBySearchOption(Form) Export
	
	GoodsSearchOption = CurrentSearchOption(Form);
	ListName = ?(GoodsSearchOption = "Advanced", "ListAdvancedSearchCharacteristics", "ListStandardSearchCharacteristics");
	
	Return ListName;
	
EndFunction

// Returns the name of the item list by search option.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form, selection form.
//
// Returns:
//	String - name of the item list.
//
Function NameOfListOfProductsBySearchOption(Form) Export
	
	GoodsSearchOption = CurrentSearchOption(Form);
	ListName = ?(GoodsSearchOption = "Advanced", "ListAdvancedSearchProducts", "ListStandardSearchProducts");
	
	Return ListName;
	
EndFunction

// Returns the name of the supplier's item list by search option.
//
// Parameters:
//	Form - ClientApplicationForm - form for selecting products in purchase documents.
//
// Returns:
//	String - the name of the supplier's item list by search option.
//
Function NameOfListOfPartnerProductsForSearchOption(Form) Export
	
	GoodsSearchOption = CurrentSearchOption(Form);
	ListName = ?(GoodsSearchOption = "Advanced", "ListOfAdvancedSearchPartnerNomenclature", "ListOfStandardSearchPartnerNomenclature");
	
	Return ListName;
	
EndFunction

// Returns the name of the current item page by search option.
//
// Parameters:
//	Form - ClientApplicationForm - form of selection, list, selection.
//
// Returns:
//	String - the name of the item page.
//
Function NameOfProductListPageBySearchOption(Form) Export
	
	GoodsSearchOption = CurrentSearchOption(Form);
	PageName = ?(GoodsSearchOption = "Advanced", "PageAdvancedSearchProducts", "PageStandardSearchProducts");
	
	Return PageName;
	
EndFunction

// Returns the name of the page in the list of pages on the selection form to make current
// , depending on the enabled search type.
//
// Parameters:
//	Form - ClientApplicationForm - form the list form of selection.
//
// Returns:
//	String - page name.
//
Function CurPageNameBySearchOption(Form) Export
	
	NameOfListPage = "";
	
	If ThisIsFormOfMatching(Form.FormCode) Then
		CharacteristicNavigation = Form.CharacteristicNavigation;
	Else
		CharacteristicNavigation = False;
	EndIf;
	
	GoodsSearchOption = CurrentSearchOption(Form);
	
	NameOfListPage = ?(CharacteristicNavigation, "ListStandardCharacteristicSearch", "PageStandardSearchProducts");
	
	If GoodsSearchOption = "Advanced" Then
		NameOfListPage = ?(CharacteristicNavigation, "PageAdvancedCharacteristicSearch", "PageAdvancedSearchProducts");
	EndIf;
	
	Return NameOfListPage;
	
EndFunction

// Returns the name of the page in the list of supplier item pages on the selection form to make current
// , depending on the enabled search type.
//
// Parameters:
//	Form - ClientApplicationForm - form the list form of selection.
//
// Returns:
//	String - page name.
//
Function NameOfCurPageOfSearchPartnerProductList(Form) Export
	
	GoodsSearchOption = CurrentSearchOption(Form);
	
	Return ?(GoodsSearchOption = "Standard", "StandardSearchPartnerItemPage", "TheAdvancedSearchPartnerItemPage");
	
EndFunction

// Returns the ID of the current search option.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form, selection form.
//
// Returns:
//	String - id of the search option.
//
Function CurrentSearchOption(Form) Export
	
	If Form.GoodsSearchOption = "Default" Then
		If Form.UseStandardSearchWhenSelectingGoods Then
			Return "Standard";
		Else
			Return "Advanced";
		EndIf;
	Else
		Return Form.GoodsSearchOption;
	EndIf;
	
EndFunction

#EndRegion

#Region FunctionsForSearchEngine

// Sets the search string selection for the dynamic list.
//
// Parameters:
//	FilterItems1 - DataCompositionFilterItemCollection - Collection Of Selection Elements
//	FilterValue - Array of CatalogRef - Array Of Selection Values
//	UsingSelection - Boolean - flag for using selection.
//
Procedure SetListSelectionBySearchBar(FilterItems1, FilterValue = Undefined, UsingSelection = True) Export
	
	FilterGroup = CommonClientServer.CreateFilterItemGroup(FilterItems1, "SearchBySubstring", 
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.SetFilterItem(FilterGroup, "Ref", FilterValue, 
		DataCompositionComparisonType.InList, "SearchBySubstring", UsingSelection);
	
EndProcedure

// Resets the set selection by the search string for the item list.
//
// Parameters:
//	Form - ClientApplicationForm - selection form, list form.
//
Procedure DeselectProductSearchBar(Form) Export
	
	Form.SearchErrorCode = "";
	Form.ThereIsAFilterForProductsSearch = False;
	Form.ProductsSearchReturnedNoResults = False;
	
	SetListSelectionBySearchBar(
		TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts).Items,, False);
	
	If Not ThisIsFormForSelectingProductsByCategory(Form.FormCode) Then
		SetSelectionByPriceRange(Form);
	EndIf;
	
EndProcedure

// Resets the set selection by the search string in the list of characteristics.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure DeselectByCharacteristicsSearchBar(Form) Export
	
	If Not ThisIsFormOfMatching(Form.FormCode) Then
		Return;
	EndIf;
	
	Form.SearchErrorCode = "";
	Form.FailedToFindCharacteristics = False;
	
	SetListSelectionBySearchBar(
		TMCommonUseClientServer.GetDynamicListSelection(Form.FeatureList).Items,, False);
	
EndProcedure

// Resets the set selection by the search string for the item list.
//
// Parameters:
//	Form - ClientApplicationForm - selection form, list form.
//
Procedure DeselectPartnerProductSearchBar(Form) Export
	
	If Not ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode) Then
		Return;
	EndIf;
	
	Form.SearchErrorCode = "";
	Form.TheSearchForThePartnerSNomenclatureIsNotSuccessful = False;
	
	SetListSelectionBySearchBar(
		TMCommonUseClientServer.GetDynamicListSelection(Form.ListOfThePartnerSNomenclature).Items,, False);
	
EndProcedure

#EndRegion

#Region FunctionsForSettingAndResettingSelections

// Sets the selection by price range for the list of supplier items in the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - form the selection of goods.
//
Procedure SetSelectionBySupplierPriceRange(Form) Export
	
	If Not ThisIsFormOfMatching(Form.FormCode) Then
		Return;
	EndIf;
	
	// Selection for the list of the supplier's nomenclature.
	SelectionGroupPriceProducts = CommonClientServer.CreateFilterItemGroup(
		TMCommonUseClientServer.GetDynamicListSelection(Form.ListOfThePartnerSNomenclature).Items,
		"ItemsPrices",
		DataCompositionFilterItemsGroupType.OrGroup);
	
	GroupSelectionByPrice = CommonClientServer.CreateFilterItemGroup(
		SelectionGroupPriceProducts.Items,
		"FilterByPrice",
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		GroupSelectionByPrice,
		"Price",
		DataCompositionComparisonType.GreaterOrEqual,
		Form.SelectionPriceFromSupplier,
		"Price",
		ValueIsFilled(Form.SelectionPriceFromSupplier));
	
	CommonClientServer.AddCompositionItem(
		GroupSelectionByPrice,
		"Price",
		DataCompositionComparisonType.LessOrEqual,
		Form.SelectionPriceToSupplier,
		"Price",
		ValueIsFilled(Form.SelectionPriceToSupplier));
	
EndProcedure

// Sets the selection based on the supplier's price condition on the selection form.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure SetSelectionBySupplierType(Form) Export
	
	CommonClientServer.SetDynamicListParameter(
		Form.ListOfThePartnerSNomenclature, 
		"VendorPriceKind", 
		Form.VendorPriceKind);
	
	CommonClientServer.SetDynamicListParameter(
		Form.ListProducts, 
		"VendorPriceKind", 
		Form.VendorPriceKind);
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, 
		"VendorPriceKind", 
		Form.VendorPriceKind);

EndProcedure

// Sets the selection by price range for the item list and 
// the list of characteristics in the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - form the selection of goods.
//
Procedure SetSelectionByPriceRange(Form) Export
	
	ThisIsFormOfMatching = ThisIsFormOfMatching(Form.FormCode);
	
	If Not ThisIsFormOfMatching Then
		Return;
	EndIf;
	
	// Selection for the list of nomenclature.
	SelectionGroupPriceProducts = CommonClientServer.CreateFilterItemGroup(
		TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts).Items,
		"ItemsPrices",
		DataCompositionFilterItemsGroupType.OrGroup);
	
	GroupSelectionByPrice = CommonClientServer.CreateFilterItemGroup(
		SelectionGroupPriceProducts.Items,
		"FilterByPrice",
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		GroupSelectionByPrice,
		"Price",
		DataCompositionComparisonType.GreaterOrEqual,
		Form.FilterPriceFrom,
		"Price",
		ValueIsFilled(Form.FilterPriceFrom));
	
	CommonClientServer.AddCompositionItem(
		GroupSelectionByPrice,
		"Price",
		DataCompositionComparisonType.LessOrEqual,
		Form.FilterPriceUpTo,
		"Price",
		ValueIsFilled(Form.FilterPriceUpTo));
	
	// Selection for a list of characteristics.
	VariantList = New ValueList();
	VariantList.Add(PredefinedValue("Enum.ItemVariantsUsageOptions.SpecialForItems"));
	VariantList.Add(PredefinedValue("Enum.ItemVariantsUsageOptions.CommonForItemKind"));
	VariantList.Add(PredefinedValue("Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind"));
	
	CommonClientServer.AddCompositionItem(
		SelectionGroupPriceProducts,
		"UseVariants",
		DataCompositionComparisonType.InList,
		VariantList,
		"UseVariants",
		ValueIsFilled(Form.FilterPriceFrom));
	
	// Set a filter on the list of characteristics.
	SelectionGroupPriceCharacteristics = CommonClientServer.CreateFilterItemGroup(
		TMCommonUseClientServer.GetDynamicListSelection(Form.FeatureList).Items,
		"PriceFeatures",
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		SelectionGroupPriceCharacteristics,
		"Price",
		DataCompositionComparisonType.GreaterOrEqual,
		Form.FilterPriceFrom,
		"Price",
		ValueIsFilled(Form.FilterPriceFrom));
	
	CommonClientServer.AddCompositionItem(
		SelectionGroupPriceCharacteristics,
		"Price",
		DataCompositionComparisonType.LessOrEqual,
		Form.FilterPriceUpTo,
		"Price",
		ValueIsFilled(Form.FilterPriceUpTo));
	
EndProcedure

// Sets the availability values for vendor item filter elements, depending on the value
// of the use vendor item filter check box.
//
// Parameters:
//	Form - See SelectGoodsServer.WhenCreatingMatchingFormOnServer.Form
//
Procedure SetAvailabilityOfPartnerProductFilterElements(Form) Export
	
	Form.Items.TheHierarchyOfItemPartner.Enabled = Form.UseThePartnerItemFilter_3;
	
EndProcedure

// Sets the selection by item group in the item list.
// If the form uses a navigation option other than hierarchy navigation,
// the selection is not set.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure SetSelectionByProductHierarchy(Form) Export
	
	If Not Form.UseFilters Then
		Return;
	EndIf;
	
	If Not Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByHierarchy") Then
		Return;
	EndIf;
	
	SelectionByProductHierarchy = Form.CurrentProductsHierarchy;
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.ListProducts,
		"Parent",
		SelectionByProductHierarchy,
		DataCompositionComparisonType.Equal,
		"Parent",
		True);
	
EndProcedure

// Disables the set selection for the item group in the item list
// on the selection form.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure DeleteSelectionByProductHierarchy(Form) Export
	
	If Not ThisIsFormOfFeatureSelection(Form.FormCode) Then
		CommonClientServer.SetDynamicListFilterItem(Form.ListProducts, "Parent",,,,False);
	EndIf;
	
EndProcedure

// Sets the selection by item group in the supplier's item list.
// If the form uses a navigation option other than hierarchy navigation,
// the selection is not set.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure SetSelectionByPartnerProductHierarchy(Form) Export
	
	If Not Form.UseThePartnerItemFilter_3 Then
		Return;
	EndIf;
	
	SelectionByPartnerProductHierarchy = Form.CurrentPartnerItemHierarchy;
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.ListOfThePartnerSNomenclature, "Parent", 
		SelectionByPartnerProductHierarchy, 
		DataCompositionComparisonType.Equal, "Parent", True);
	
EndProcedure

// Disables the set selection for the supplier's item group in the supplier's item list
// on the selection form.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure DeletePartnerProductHierarchySelection(Form) Export
	
	CommonClientServer.SetDynamicListFilterItem(Form.ListOfThePartnerSNomenclature, "Parent",,,,False);
	
EndProcedure

#EndRegion

#Region ConfiguringFormDisplayBySearchOption

// Sets the default selection button in the item selection form, depending on the search option.
//
// Parameters:
//	Form - ClientApplicationForm - item list form, selection form, selection form.
//
Procedure AssignDefaultSelectionButton(Form) Export
	
	SearchMode = CurrentSearchOption(Form);
	
	If SearchMode = "Advanced" Then
		
		Form.Items.ListStandardSearchProductsSelectProductsValue.DefaultButton = False;
		Form.Items.ListAdvancedSearchItemSelectItemValue.DefaultButton = True;
		
	ElsIf SearchMode = "Standard" Then
		
		Form.Items.ListStandardSearchProductsSelectProductsValue.DefaultButton = True;
		Form.Items.ListAdvancedSearchItemSelectItemValue.DefaultButton = False;
		
	EndIf;
	
EndProcedure

// Sets the values of the current pages on the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - item list form, selection form, selection form.
//
Procedure SetCurPagesBySearchOption(Form) Export
	
	If CurrentSearchOption(Form) = "Standard" Then
		DeselectProductSearchBar(Form);
		Form.SearchStringProducts = "";
	EndIf;
	
	If ThisIsFormOfMatching(Form.FormCode) Then
		
		Form.Items.PagesOfLists.CurrentPage = Form.Items[CurPageNameBySearchOption(Form)];
		
		If ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode) Then
			Form.Items.PagesOfThePartnerSNomenclatureLists.CurrentPage = Form.Items[NameOfCurPageOfSearchPartnerProductList(Form)];
		EndIf;
		
		AssignKeyboardShortcutsToFormCommandsBySearchOption(Form);
		
	Else
		
		PageName = CurPageNameBySearchOption(Form);
		Form.Items.PagesOfLists.CurrentPage = Form.Items[PageName];
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Returns the structure of the item line. The structure is used
//  for caching current data from a row in the dynamic list of items.
// 
// Returns:
//  Structure - Structure for storing information about the activated item line:
//  *Ref - CatalogRef.Products
//  *Parent - CatalogRef.Products
//  *ProductKind - CatalogRef.ItemKinds
//  *ItemsType - EnumRef.ItemsTypes
//  *Package - CatalogRef.PackagesAndUnitsOfMeasure
//  *UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
//  *SKU - String
//  *Products - CatalogRef.Products
//  *PriceGroup - CatalogRef.PriceGroups
//  *ThisIsAProduct - Boolean
//  *IsService - Boolean
//  *DeletionMark - Boolean
//  *ItemVariantsAreUsed - Boolean
//  *IsFolder - Boolean
//  *UseVariants - Boolean
//  *Price - Number
//  *InStockBalance - Number
//  *ItemVariantsOwner - CatalogRef
//  *PriceKind- CatalogRef.TypesOfPrices
//
Function StructureOfProductLine() Export
	
	StringStructure = New Structure();
	
	StringStructure.Insert("Ref");
	StringStructure.Insert("Parent");
	StringStructure.Insert("ProductKind");
	StringStructure.Insert("ItemsType");
	StringStructure.Insert("Package");
	StringStructure.Insert("UnitOfMeasure");
	StringStructure.Insert("SKU");
	StringStructure.Insert("Products");
	StringStructure.Insert("PriceGroup");
	StringStructure.Insert("ThisIsAProduct",False);
	StringStructure.Insert("IsService", False);
	StringStructure.Insert("DeletionMark", False);
	StringStructure.Insert("ItemVariantsAreUsed", False);
	StringStructure.Insert("IsFolder", False);
	StringStructure.Insert("UseVariants", False);
	StringStructure.Insert("Price", 0);
	StringStructure.Insert("InStockBalance", 0);
	StringStructure.Insert("ItemVariantsOwner");
	StringStructure.Insert("PriceKind");
	
	Return StringStructure;
	
EndFunction

// Returns the structure of the characteristics string. The structure is used
//  to cache current data from a row in a dynamic list of characteristics.
// 
// Returns:
//  Structure - structure with keys:
//  * Ref - CatalogRef.ItemsCharacteristics
//  * Characteristic - CatalogRef.ItemsCharacteristics
//  * Products - CatalogRef.Products
//  * ProductKind - CatalogRef.ItemKinds
//  * ItemsType - EnumRef.ItemsTypes
//  * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
//  * Package - CatalogRef.PackagesAndUnitsOfMeasure
//  * PriceGroup - CatalogRef.PriceGroups - 
//  * DeletionMark - Boolean
//  * ItemVariantsAreUsed - Boolean
//  * Price - Number
//  * InStockBalance - Number
//  * ItemVariantsOwner - CatalogRef
//  * PriceKind - CatalogRef.TypesOfPrices
//
Function StructureOfCharacteristicsString() Export
	
	StringStructure = New Structure();
	
	StringStructure.Insert("Ref");
	StringStructure.Insert("Characteristic");
	StringStructure.Insert("Products");
	StringStructure.Insert("ProductKind");
	StringStructure.Insert("ItemsType");
	StringStructure.Insert("UnitOfMeasure");
	StringStructure.Insert("Package");
	StringStructure.Insert("PriceGroup");
	StringStructure.Insert("DeletionMark", False);
	StringStructure.Insert("ItemVariantsAreUsed", True);
	StringStructure.Insert("Price", 0);
	StringStructure.Insert("InStockBalance", 0);
	StringStructure.Insert("ItemVariantsOwner");
	StringStructure.Insert("PriceKind");
	
	Return StringStructure;
	
EndFunction

// Returns the structure necessary for transmitting product data to the
// procedures for adding an item to the cart.
//
// Parameters:
//	Products - CatalogRef.Products - Nomenclature.
//
// Returns:
//	Structure - the structure of the product parameters.
//
Function ProductParameters_1(Products = Undefined) Export
	
	ProductParameters_1 = New Structure();
	ProductParameters_1.Insert("Products", PredefinedValue("Catalog.Products.EmptyRef"));
	ProductParameters_1.Insert("ItemsType", PredefinedValue("Enum.ItemsTypes.EmptyRef"));
	ProductParameters_1.Insert("ProductKind", PredefinedValue("Catalog.ItemKinds.EmptyRef"));
	ProductParameters_1.Insert("SKU", "");
	ProductParameters_1.Insert("Characteristic", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	ProductParameters_1.Insert("PricingVariant", PredefinedValue("Catalog.ItemsCharacteristicsForPricing.EmptyRef"));
	ProductParameters_1.Insert("PricingBatch", PredefinedValue("Catalog.ItemsBatchesForPricing.EmptyRef"));
	ProductParameters_1.Insert("PricingPackage", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	ProductParameters_1.Insert("ItemVariantsAreUsed", False);
	ProductParameters_1.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	ProductParameters_1.Insert("UnitOfMeasure", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	ProductParameters_1.Insert("PriceKind", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
	ProductParameters_1.Insert("Price",0);
	ProductParameters_1.Insert("Warehouse", PredefinedValue("Catalog.Warehouses.EmptyRef"));
	ProductParameters_1.Insert("DateOfShipment",'00010101');
	ProductParameters_1.Insert("DeliveryPeriodDays",0);
	ProductParameters_1.Insert("NumberOfPackages",0);
	ProductParameters_1.Insert("Count",0);
	ProductParameters_1.Insert("ThisIsAProduct",False);
	ProductParameters_1.Insert("IsService",False);
	ProductParameters_1.Insert("VendorPriceKind", PredefinedValue("Catalog.VendorPriceTypes.EmptyRef"));
	ProductParameters_1.Insert("PartnerProducts",PredefinedValue("Catalog.ProductCrossReferences.EmptyRef"));
	ProductParameters_1.Insert("PriceGroup",PredefinedValue("Catalog.PriceGroups.EmptyRef"));
	ProductParameters_1.Insert("PercentRateOfManualDiscount",0);
	ProductParameters_1.Insert("Seller", PredefinedValue("Catalog.Users.EmptyRef"));
	ProductParameters_1.Insert("Premise", PredefinedValue("Catalog.Warerooms.EmptyRef"));
	ProductParameters_1.Insert("Brand", PredefinedValue("Catalog.Brands.EmptyRef"));
	ProductParameters_1.Insert("ProductRangeRole", PredefinedValue("Enum.ProductRangeRoles.EmptyRef"));
	ProductParameters_1.Insert("SalesRank", PredefinedValue("Catalog.SalesRanks.EmptyRef"));
	ProductParameters_1.Insert("ProductRangePhase", PredefinedValue("Enum.ProductRangePhases.EmptyRef"));
	ProductParameters_1.Insert("ProductCategory", PredefinedValue("Catalog.ProductCategories.EmptyRef"));
	ProductParameters_1.Insert("ProductsInSet", PredefinedValue("Catalog.Products.EmptyRef"));
	ProductParameters_1.Insert("ItemVariantOfSet", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	ProductParameters_1.Insert("ItemKitConfiguration", PredefinedValue("Catalog.ProductKitConfigurations.EmptyRef"));
	ProductParameters_1.Insert("SupplyOption", PredefinedValue("Enum.SupplyOptions.EmptyRef"));
	ProductParameters_1.Insert("WithAssignment", False);
	ProductParameters_1.Insert("Series", PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
	ProductParameters_1.Insert("Available", 0);
	ProductParameters_1.Insert("InStock", 0);
	ProductParameters_1.Insert("Error_", 0);
	ProductParameters_1.Insert("PackagingFactor", 1);
	If Products <> Undefined Then
		ProductParameters_1.Package = SelectGoodsServerCall.GetStoragePackaging(Products);
	EndIf; 
	
	Return ProductParameters_1;
	
EndFunction

// Sets the text of the information label about the number and amount
// of products selected in the shopping cart on the selection form.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetTextOfInformationLabel(Form) Export
	
	junk = Form.Object.junk;
	Currency = Form.Currency;
	
	FormatString = NStr("vi = 'НП = True; НД = False; ДП = False';
						|ru = 'НП = Истина; НД = Ложь; ДП = Ложь';
						|en = 'SN = True; FN = False; FS = False'; fa = 'SN = True; FN = False; FS = False';
						|it = 'НП = Истина; НД = Ложь; ДП = Ложь';
						|pl = 'SN = True; FN = False; FS = False';
						|tr = 'SN = True; FN = False; FS = False'");
	
	Sum = Format(junk.Total("Sum"), "NFD=2; NZ=");
	Count = Lower(NumberInWords(junk.Count(), FormatString, NStr("vi = 'vị trí, vị trí, vị trí, m,,,,,0';
																|ru = 'позиция,позиции,позиций,ж,,,,,0';
																|en = 'position,positions,,,0'; fa = 'position,positions,,,0';
																|it = 'posizione,di posizione,di posizioni,zh,,,,,0';
																|pl = 'pozycja,pozycji,pozycji,ж,,,,,0';
																|tr = 'konum,konumlar,konumların,,,,,,0'")));
	
	HelpText = NStr("vi = 'Tất cả đã chọn [Count] hàng hóa, với số tiền [Sum] [Currency] [HideShow]';
					|ru = 'Всего подобрано [Count] товаров, на сумму [Sum] [Currency] [HideShow]';
					|en = '[Count] goods are picked, in the amount of [Sum] [Currency] [HideShow]'; fa = '[Count] goods are picked, in the amount of [Sum] [Currency] [HideShow]';
					|it = 'Totale selezionato [Count] merci, per importo di [Sum] [Currency] [HideShow]';
					|pl = 'Razem wybrano [Count] towarów, na kwotę [Sum] [Currency] [HideShow]';
					|tr = '[Sum] [Currency] [HideShow] tutarında toplam [Count] ürün seçildi'");
	
	HideShow = "";
	
	If Form.ModeOfSelectionWithoutQuantitativeParameters Or Form.SelectionModeWithoutAmountParameters Then
		HelpText = NStr("vi = 'Tất cả đã chọn [Count] hàng hóa [HideShow]';
						|ru = 'Всего подобрано [Count] товаров [HideShow]';
						|en = '[Count] goods are picked [HideShow]'; fa = '[Count] goods are picked [HideShow]';
						|it = 'Totale selezionato [Count] merci, [HideShow]';
						|pl = 'Razem wybrano [Count] towarów [HideShow]';
						|tr = 'Toplam ürün [Count] seçildi [HideShow]'");
	EndIf;
	
	HideShow = ?(Form.ShowSelectedGoods, NStr("vi = '(ẩn)';
												|ru = '(скрыть)';
												|en = '(hide)'; fa = '(hide)';
												|it = '(nascondere)';
												|pl = '(ukryj)';
												|tr = '(gizle)'"), NStr("vi = '(hiển thị)';
																	|ru = '(показать)';
																	|en = '(show)'; fa = '(show)';
																	|it = '(mostrare)';
																	|pl = '(pokaż)';
																	|tr = '(göster)'"));
	
	ValuesToInsert = New Structure;
	ValuesToInsert.Insert("Count",Count);
	ValuesToInsert.Insert("Sum",Sum);
	ValuesToInsert.Insert("Currency",Currency);
	ValuesToInsert.Insert("HideShow",HideShow);
	
	HelpText = StringFunctionsClientServer.InsertParametersIntoString(HelpText, ValuesToInsert);
	
	Form.HelpText = HelpText;
	
	Form.Items.AreaSelectedGoods.Visible = Form.ShowSelectedGoods;
	
EndProcedure

// Sets the text of the label about hiding or displaying leftovers.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetCaptionTextToDisplayLeftovers(Form) Export
	
	Form.DisplayBalanceLabel = ?(Form.Items.StockBalance.Visible, 
		NStr("vi = 'Thông tin chi tiết về số dư (ẩn)';
			|ru = 'Подробная информация об остатках (скрыть)';
			|en = 'Detailed information about balance (hide)'; fa = 'Detailed information about balance (hide)';
			|it = 'Informazioni dettagliate sui saldi (nascondere)';
			|pl = 'Informacje szczegółowe o pozostałościach (ukryj)';
			|tr = 'Bakiyeler ile ilgili detaylı bilgi (gizle)'"), 
		NStr("vi = 'Thông tin chi tiết về số dư (hiển thị)';
			|ru = 'Подробная информация об остатках (показать)';
			|en = 'Detailed information about balance (show)'; fa = 'Detailed information about balance (show)';
			|it = 'Informazioni dettagliate sui saldi (visualizzare)';
			|pl = 'Informacje szczegółowe o pozostałościach (pokaż)';
			|tr = 'Bakiyeler ile ilgili detaylı bilgi (göster)'"));
	
EndProcedure

// Sets the text of the label for hiding/displaying the remaining items of the supplier's item.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetLabelTextToDisplayPartnerProductRemnants(Form) Export
	
	Form.DisplayBalanceLabel = ?(Form.Items.StockBalance.Visible, 
		NStr("vi = 'Thông tin chi tiết về số dư (ẩn)';
			|ru = 'Подробная информация об остатках (скрыть)';
			|en = 'Detailed information about balance (hide)'; fa = 'Detailed information about balance (hide)';
			|it = 'Informazioni dettagliate sui saldi (nascondere)';
			|pl = 'Informacje szczegółowe o pozostałościach (ukryj)';
			|tr = 'Bakiyeler ile ilgili detaylı bilgi (gizle)'"), 
		NStr("vi = 'Thông tin chi tiết về số dư (hiển thị)';
			|ru = 'Подробная информация об остатках (показать)';
			|en = 'Detailed information about balance (show)'; fa = 'Detailed information about balance (show)';
			|it = 'Informazioni dettagliate sui saldi (visualizzare)';
			|pl = 'Informacje szczegółowe o pozostałościach (pokaż)';
			|tr = 'Bakiyeler ile ilgili detaylı bilgi (göster)'"));
	
EndProcedure

// Generates the text of the information label about the quantity and amount of selected products.
//
// Parameters:
//	HelpText - String- details to place the information label in,
//	GoodsQuantity - Number - amount of goods,
//	GoodsAmount - Number - amount of products,
//	Currency - CatalogRef.Currencies - the currency in which the selection of products is made.
//
Procedure CreateInformationLabelForSelectedProducts(HelpText, GoodsQuantity, GoodsAmount, Currency) Export
	
	HelpText = NStr("vi = 'Tổng số hàng hóa đã chọn [GoodsQuantity] số tiền [GoodsAmount] [Currency]';
					|ru = 'Всего подобрано товаров [GoodsQuantity] на сумму [GoodsAmount] [Currency]';
					|en = '[GoodsQuantity] goods are picked in the amount of [GoodsAmount] [Currency]'; fa = '[GoodsQuantity] goods are picked in the amount of [GoodsAmount] [Currency]';
					|it = 'Totale merci selezionate [GoodsQuantity], per importo di [GoodsAmount] [Currency]';
					|pl = 'Razem wybrano towarów [GoodsQuantity] na kwotę [GoodsAmount] [Currency]';
					|tr = '[GoodsAmount] [Currency] tutarında [GoodsQuantity] toplam ürün seçildi'");
	
	ValuesToInsert = New Structure("GoodsQuantity, GoodsAmount, Currency");
	
	ValuesToInsert.GoodsQuantity = Format(GoodsQuantity, "NZ=0");
	ValuesToInsert.GoodsAmount      = Format(GoodsAmount, "NFD=2; NZ=0,00");
	ValuesToInsert.Currency            = Currency;
	
	HelpText = StringFunctionsClientServer.InsertParametersIntoString(HelpText, ValuesToInsert);
	
EndProcedure

// The procedure removes rows from the table of balances on the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure ClearRemainderTable(Form) Export
	
	StockBalance = Form.StockBalance.GetItems();
	StockBalance.Clear();
	
EndProcedure

// Checks whether the cart contains items that are sold together.
//
// Parameters:
// 	Object - FormDataStructure - processing the selection of goods, document
// 
// Returns:
// 	Boolean - true if there are goods
//
Function ThereAreGoodsSoldJointly(Object) Export
	
	Return Object.junk.Total("IndexGoodsSoldTogether") > 0;
	
EndFunction

// Sets the visibility of the command to go to the list of jointly sold products.
//
// Parameters:
// 	Form - ClientApplicationForm - selection Form:
// 		* Object - FormDataStructure - selection processing or document
//
Procedure EstablishVisibilityOfProductSelectionTeamSoldJointly(Form) Export
	
	Form.ThereIsItemSoldJointly = ThereAreGoodsSoldJointly(Form.Object);
	
EndProcedure

// Generates the selection form header, which consists of the form header and the document view.
//
// Parameters:
//	Form - ClientApplicationForm - form the selection of goods.
//
Procedure SetSelectionFormHeader(Form) Export
	
	Document = Form.Parameters.Document;
	
	If Document = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(Document) Then
		Form.Title = Form.Title + ": " + Document;
	Else
		TextDocument_ = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (mới)';
				|ru = '%1 (новый)';
				|en = '%1 (new)'; fa = '%1 (new)';
				|it = '%1 (nuovo)';
				|pl = '%1 (nowy)';
				|tr = '%1 (yeni)'"), Document.Metadata().Synonym);
		
		Form.Title = Form.Title + ": " + TextDocument_;
	EndIf;
	
EndProcedure

// Generates the selection form header, which consists of the form header and the document view.
//
// Parameters:
// 	Title - String - The header of the form
// 	Document - DocumentRef - link to the document from which the selection opens
//
// Returns:
// 	String - header of the selection Form
//
Function CreateSelectionFormHeader(Title, Document) Export
	
	If Document = Undefined Then
		Return Title;
	EndIf; 
	
	If ValueIsFilled(Document) Then
		
		Title = Title + ": " + Document;
		
	Else
		
		TextDocument_ = NStr("vi = '%1 (mới)';
							|ru = '%1 (новый)';
							|en = '%1 (new)'; fa = '%1 (new)';
							|it = '%1 (nuovo)';
							|pl = '%1 (nowy)';
							|tr = '%1 (yeni)'");
		TextDocument_ = StringFunctionsClientServer.SubstituteParametersToString(
			TextDocument_,
			Document.Metadata().Synonym);
		
		Title = Title + ": " + TextDocument_;
		
	EndIf;
	
	Return Title;
	
EndFunction

// Sets the value of the dynamic list parameter, or disables its use, depending on the attribute.
//
// Parameters:
//	List - DynamicList - list,
//	ParameterName - String - parameter name,
//	Value - Arbitrary - parameter value,
//	Use - Boolean - indicates whether the parameter is being used.
//
Procedure SetDynamicListParameter(List, ParameterName, Value, Use = True) Export
	
	ParameterValue = List.Parameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	
	If ParameterValue <> Undefined Then
		If Use Then
			List.Parameters.SetParameterValue(ParameterName, Value);
		Else
			ParameterValue.Value = Value;
			ParameterValue.Use = False;
		EndIf
	EndIf;
	
EndProcedure

// Sets the availability values for filter elements depending on the value
// of the use filters checkbox.
//
// Parameters:
//	Form - See SelectGoodsServer.WhenCreatingMatchingFormOnServer.Form
//
Procedure SetAvailabilityOfFilterElements(Form) Export
	
	ThisIsFormOfMatching = ThisIsFormOfMatching(Form.FormCode);
	ThisIsFormOfFeatureSelection = ThisIsFormOfFeatureSelection(Form.FormCode);
	ThisIsProductListForm = ThisIsProductListForm(Form.FormCode);
	ThisIsFormOfProductSelection = ThisIsFormOfProductSelection(Form.FormCode);
	
	If Not ThisIsFormOfFeatureSelection Then
		
		Form.Items.ProductsHierarchy.Enabled = Form.UseFilters;
		If Not ThisIsFormOfSimilarGoodsProduct(Form.FormCode) Then
			Form.Items.ItemKinds.Enabled = Form.UseFilters;
		EndIf;
		Form.Items.ProductKind.Enabled = Form.UseFilters;
		Form.Items.FilterTree.Enabled = Form.UseFilters;
		Form.Items.CommandBarNavigationOption.Enabled = Form.UseFilters;
		
		If Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByProperties")
			Or Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKindsAndProperties")
			Or Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKinds") Then
			Form.Items.LabelNavigationOption.Enabled = Form.UseFilters;
		EndIf;
		
	Else
		
		Form.Items.FilterTree.Enabled = Form.UseFilters;
		
	EndIf;
	
	If ThisIsFormOfMatching
		Or ThisIsProductListForm
		Or ThisIsFormOfProductSelection Then
		Form.Items.ProductsOfOriginalQuality.Enabled = Form.UseFilters;
		Form.Items.ListQualities.Enabled = Form.UseFilters;
	EndIf;
	
EndProcedure

// Returns parameters for building a list of items or characteristics.
//
// Returns:
// 	Structure:
// 		* QueryTemplate - String
// 		* TextReplacements - Map of String
// 		* TemporaryTable - Array of String
// 		* FormType - String
// 		* ListType - String
// 		* ThereAreRatessInFuture - Boolean
// 		* ThereArePricesInTheFuture - Boolean
// 		* ThereAreProductPricesOfSuppliersInTheFuture - Boolean
// 		* PriceCalculationOption - EnumRef.PriceCalculationOptionsByTermsOfSales
// 		* SupplierPriceCalculationOption - String
// 		* UsePriceManagementSystem25 - Boolean
// 		* SelectionModeByProductRange - Boolean
// 		* SelectionModeWithoutAmountParameters - Boolean
// 		* ThisIsPartner - Boolean
// 		* OnlyInStock - Boolean
// 		* DoNotUsePriceTypesBasedOnTheSalesCondition - Boolean
// 		* SeveralPriceTypes - Boolean
// 		* MultipleWarehouses - Boolean
// 		* DisplayRemainingQuantityInWarehouses - Boolean
// 		* DisplayBalancesAsIntended - Boolean
// 		* UseItemVariants - Boolean
// 		* UseKits - Boolean
//
Function NewParametersForBuildingListQuery() Export
	
	CalculationOption = PredefinedValue("Enum.PriceCalculationOptionsByTermsOfSales.EmptyRef");
	
	Result = New Structure;
	Result.Insert("QueryTemplate", "");
	Result.Insert("TextReplacements", New Map());
	Result.Insert("TemporaryTable", New Array());
	Result.Insert("FormType", "");
	Result.Insert("ListType", "");
	Result.Insert("ThereAreRatessInFuture", False);
	Result.Insert("ThereArePricesInTheFuture", False);
	Result.Insert("ThereAreProductPricesOfSuppliersInTheFuture", False);
	Result.Insert("PriceCalculationOption", CalculationOption);
	Result.Insert("SupplierPriceCalculationOption", "");
	Result.Insert("UsePriceManagementSystem25", False);
	Result.Insert("SelectionModeByProductRange", False);
	Result.Insert("SelectionModeWithoutAmountParameters", False);
	Result.Insert("ThisIsPartner", False);
	Result.Insert("OnlyInStock", False);
	Result.Insert("DoNotUsePriceTypesBasedOnTheSalesCondition", False);
	Result.Insert("SeveralPriceTypes", False);
	Result.Insert("MultipleWarehouses", False);
	Result.Insert("DisplayRemainingQuantityInWarehouses", False);
	Result.Insert("DisplayBalancesAsIntended", False);
	Result.Insert("DisplayBalanceOfControlledLotReference", False);
	Result.Insert("UseItemVariants", False);
	Result.Insert("UseKits", False);
	
	Return Result;
	
EndFunction

// Returns a template for the parameter structure for getting information about the price and Balance of the product.
//
// Returns:
// 	Structure:
// 		* Products - CatalogRef.Products - Products
// 		* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the nomenclature
// 		* Terms - CatalogRef.TermsOfSale - the agreement on the basis of which the sale is carried out
// 		* Currency - CatalogRef.Currencies - The currency of mutual settlements
// 		* Warehouses - CatalogRef.Warehouses, ValueList of CatalogRef.Warehouses - Warehouse
// 		* TypesOfPrices - CatalogRef.TypesOfPrices, ValueList of CatalogRef.TypesOfPrices - Type of price
// 		* ControlledLotReference - CatalogRef.ControlledLots - Controlled Lot Reference
// 		* GetPrice - Boolean - price receipt flag
// 		* GetBalance - Boolean - indicates that Balances have been received
//
Function NewParametersForGettingPriceAndBalanceOfGoods() Export
	
	Result = New Structure;
	
	Result.Insert("Products", PredefinedValue("Catalog.Products.EmptyRef"));
	Result.Insert("Characteristic", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	Result.Insert("Terms", PredefinedValue("Catalog.TermsOfSale.EmptyRef"));
	Result.Insert("Currency", PredefinedValue("Catalog.Currencies.EmptyRef"));
	Result.Insert("Warehouses", PredefinedValue("Catalog.Warehouses.EmptyRef"));
	Result.Insert("TypesOfPrices", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
	Result.Insert("ControlledLotReference", PredefinedValue("Catalog.ControlledLots.EmptyRef"));
	Result.Insert("GetPrice", False);
	Result.Insert("GetBalance", False);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region ProceduresAndFunctionsForConfiguringDisplayOfFormBySearchOption

// Assigns the appropriate keyboard shortcuts for form commands, depending on the search option.
//
// Parameters:
//	Form - ClientApplicationForm - item list form, selection form, selection form.
//
Procedure AssignKeyboardShortcutsToFormCommandsBySearchOption(Form)
	
	SearchMode = CurrentSearchOption(Form);
	
	If SearchMode = "Advanced" Then
		BasicCommand = Form.Items.GoToTheListOfItemsAdvancedSearch;
		AdditionalCommand = Form.Items.GoToTheItemListStandardSearch;
	Else
		BasicCommand = Form.Items.GoToTheItemListStandardSearch;
		AdditionalCommand = Form.Items.GoToTheListOfItemsAdvancedSearch;
	EndIf;
	
	BasicCommand.Shortcut = New Shortcut(Key.BackSpace);
	AdditionalCommand.Shortcut = New Shortcut(Key.None);
	
EndProcedure

#EndRegion

#EndRegion
