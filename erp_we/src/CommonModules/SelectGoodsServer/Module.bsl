///////////////////////////////////////////////////////////////////////////////
// The module "Selection of Goods Server" contains the procedures and functions necessary for
// the work of the forms of selection of goods. The module contains the main functions that are responsible
// for the installation and removal of selections, switching pages of nomenclature / characteristics,
// search functions.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region WorkingWithBasket

// Called when the data in the shopping cart of selected products changes in the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure WhenChangingBucket(Form) Export
	
	ThisIsFormOfMatchingInSalesDocuments = SelectGoodsClientServer.ThisIsFormOfMatchingInSalesDocuments(Form.FormCode);
	
	SelectGoodsClientServer.SetTextOfInformationLabel(Form);
	
	If (ThisIsFormOfMatchingInSalesDocuments
		And Not Form.SelectionModeWithoutAmountParameters) Then
		
		SelectGoodsClientServer.EstablishVisibilityOfProductSelectionTeamSoldJointly(Form);
		
		If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsSoldTogether Then
			
			If SelectGoodsClientServer.ThereAreGoodsSoldJointly(Form.Object) Then
				EstablishSelectionByProductSoldJointly(Form);
			Else
				Form.NavigationOption = Enums.ItemFormNavigationOptions.ByHierarchy;
				WhenChangingNavigationOption(Form);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region GettingInformationAboutPriceAndProductBalancesFromSelectionForms

// Transfers data for set selection values from the selection tree by
//  item type properties to the value table and places it in temporary
//  storage.
//
// Parameters:
//  Form	 - ClientApplicationForm	 - selection form.
// 
// Returns:
//  String - The address of the value table in the temporary storage.
//
Function AddressOfSelectionTreeParameterTable(Form) Export
	
	FormUniqueID = Form.UUID;
	TreeOfSelectionValues        = Form.FormAttributeToValue("FilterTree");
	
	TableAddress = Undefined;
	
	ParametersTable = New ValueTable;
	
	ParametersTable.Columns.Add("AttributeName");
	ParametersTable.Columns.Add("FilterValue");
	ParametersTable.Columns.Add("IsAddlAttribute");
	
	FilterParameters = New Structure("Filter", True);
	
	SelectionTreeRows_ = TreeOfSelectionValues.Rows;
	
	FoundRows = SelectionTreeRows_.FindRows(FilterParameters);
	
	For Each SelectionTreeString In FoundRows Do
		
		If TypeOf(SelectionTreeString.FilterValue) = Type("String")
			Or TypeOf(SelectionTreeString.FilterValue) = Type("Boolean") Then
			
			TableRow = ParametersTable.Add();
			FillPropertyValues(TableRow, SelectionTreeString);
			
		ElsIf Not SelectionTreeString.FilterAvailable Then
			
			SubordinateRows = SelectionTreeString.Rows.FindRows(FilterParameters);
			
			If SubordinateRows.Count() = 1 Then
				
				SelectionValueString_ = SubordinateRows[0];
				TableRow = ParametersTable.Add();
				
				FillPropertyValues(TableRow, SelectionValueString_);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ParametersTable.Count() > 0 Then
		TableAddress = PutToTempStorage(ParametersTable, FormUniqueID);
	EndIf;
	
	Return TableAddress;
	
EndFunction

// Transfers data for set selection values from the selection tree by
//  item type properties to the value table and places it in temporary storage.
//
// Parameters:
//  Form	 - ClientApplicationForm	 - selection form.
// 
// Returns:
//  String - The address of the value table in the temporary storage.
//
Function AddressOfSelectionTreeMappingTable(Form) Export
	
	FormUniqueID = Form.UUID;
	TreeOfSelectionValues = Form.FormAttributeToValue("FilterTree");
	
	TableAddress = Undefined;
	
	ParametersTable = New ValueTable;
	
	ParametersTable.Columns.Add("AttributeName");
	ParametersTable.Columns.Add("FilterValue");
	ParametersTable.Columns.Add("IsAddlAttribute");
	ParametersTable.Columns.Add("IntervalFrom");
	ParametersTable.Columns.Add("IntervalTo");
	ParametersTable.Columns.Add("Interval");
	
	FilterParameters = New Structure("Filter", True);
	
	SelectionTreeRows_ = TreeOfSelectionValues.Rows;
	
	FoundRows = SelectionTreeRows_.FindRows(FilterParameters);
	
	For Each SelectionTreeString In FoundRows Do
		
		If SelectionTreeString.FixedValue Then
			
			TableRow = ParametersTable.Add();
			FillPropertyValues(TableRow, SelectionTreeString);
			
			If SelectionTreeString.IntervalFrom <> Undefined Then
				TableRow.Interval = True;
			EndIf;
			
		ElsIf TypeOf(SelectionTreeString.FilterValue) = Type("String")
			Or TypeOf(SelectionTreeString.FilterValue) = Type("Boolean") Then
			
			TableRow = ParametersTable.Add();
			FillPropertyValues(TableRow, SelectionTreeString);
			
			TableRow.Interval = False;
			
		ElsIf Not SelectionTreeString.FilterAvailable Then
			
			SubordinateRows = SelectionTreeString.Rows.FindRows(FilterParameters);
			
			For Each SelectionValueString_ In SubordinateRows Do
				
				TableRow = ParametersTable.Add();
				
				FillPropertyValues(TableRow, SelectionValueString_);
				
				TableRow.Interval = False;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	If ParametersTable.Count() > 0 Then
		TableAddress = PutToTempStorage(ParametersTable, FormUniqueID);
	EndIf;
	
	Return TableAddress;
	
EndFunction

#EndRegion

#Region NavigatingCharacteristicsInSelectionForms

// Sets the current page with the list of items.
// Used in the selection forms (in the sales and purchase document).
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure GoToListOfProducts(Form) Export
	
	Items = Form.Items;
	
	ThisIsFormOfMatching = SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode);
	
	If ThisIsFormOfMatching Then
		
		If Form.CharacteristicNavigation Then
			
			NameOfProductItemPage = SelectGoodsClientServer.NameOfProductListPageBySearchOption(Form);
			Items.PagesOfLists.CurrentPage = Items[NameOfProductItemPage];
			
			Form.CharacteristicNavigation = False;
			Items.ProductSegment.ReadOnly = False;
			
			NameOfProductList = SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form);
			
			If ValueIsFilled(Form.SearchStringProducts) Then
				Form.CurrentItem = Form.Items.SearchStringProducts;
			Else
				Form.CurrentItem = Form.Items[NameOfProductList];
			EndIf;
			
			Form.Items.PagesCreate.CurrentPage = Form.Items.PageCreateProducts;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CommonFormEventHandlers

// Called from the event handler for the" join Server " of list forms.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form.
//
Procedure OnCreateAtServer(Form) Export
	
	Form.ThereIsProductKindSettingRight = AccessRight("Update", Metadata.Catalogs.ItemKinds);
	Form.FormTextColor = StyleColors.FormTextColor;	
	
	SetValuesForFormSettings(Form);
	
	Form.UseStandardSearchWhenSelectingGoods = Constants.UseStandardSearchWhenSelectingGoods.Get();
	
	If SelectGoodsClientServer.ThisIsFormOfProductSelection(Form.FormCode) Then
		
		If Form.Parameters.Filter.Property("MarkedProducts") Then
			Form.Parameters.Filter.Delete("ProductKind");
		EndIf;
		
		For Each Item In Form.Parameters.Filter Do
			
			If Item.Key = "ItemsType" Then
				
				SetSelectionByTypeOfProductByParameters_(Form);
				Continue;
				
			EndIf;
			
			If Item.Key = "ProductKind" Then
				
				//@skip-check query-in-loop
				SetSelectionByTypeOfProductByParameters(Form);
				Continue;
				
			EndIf;
			
			If Item.Key = "Owner" Or Item.Key = "ArticleOwner"
				Or Item.Key = "MarkedProducts" Or Item.Key = "TypesOfIPProducts" Then
				Continue;
			EndIf;
			
			If TypeOf(Item.Value) = Type("FixedArray") Then
				
				AddFilterItem(TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts), 
				Item.Key, Item.Value, DataCompositionComparisonType.InList, "FilterDefault");
				
			Else
				
				AddFilterItem(TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts), 
				Item.Key, Item.Value, DataCompositionComparisonType.Equal, "FilterDefault");
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	SelectGoodsClientServer.SetCurPagesBySearchOption(Form);
	
	If SelectGoodsClientServer.ThisIsFormOfProductSelection(Form.FormCode) Then
		SelectGoodsClientServer.AssignDefaultSelectionButton(Form);
	EndIf;
	
	TMCommonUse.InitializeFormDetailsForFullTextSearch(Form, "UseFullTextSearchWhenSelectingGoods");
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChangeListQueryTextForCurrentLanguage(Form, "ListProducts");
	// End StandardSubsystems.Core
	
EndProcedure

// Called from the handler for the "join Server" event for selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - The Form Of selection, where:
//		* Items - FormAllItems - Where:
//			** junkPrice - FormTable
//			** OnlyInStock - FormField
//			** ProductSegment - FormField
//			** ProductKind - FormField
//			** ItemKinds - FormTable - Where:
//				*** CurrentData - DynamicList - Where:
//					**** Ref - CatalogRef.ItemKinds
//			** UseFilters - FormField
//			** StandardSearchCommandPanelSetFilter - FormGroup
//			** AdvancedSearchCommandBarSetFilter - FormGroup
//			** ListAdvancedSearchProductsContextMenuProductsWithSimilarProperties - FormButton
//			** ListAdvancedSearchProductsContextMenuAnotherQualityGoods - FormButton
//			** ListStandardSearchProductsContextMenuProductsWithSimilarProperties - FormButton
//			** ListStandardSearchProductsContextMenuAnotherQualityGoods - FormButton
//			** ListStandardSearchProductsInStockBalance - FormField 
//			** ListAdvancedSearchProductsInStockBalance - FormField
//			** ListAdvancedSearchProductsAvailable - FormField
//			** ListStandardSearchProductsAvailable - FormField
//			** ListAdvancedSearchProductsPrice - FormField
//			** ListStandardSearchProductsPrice - FormField
//			** ListAdvancedSearchCharacteristicsPrice - FormField
//			** ListStandardSearchCharacteristicsPrice - FormField
//			** ListAdvancedSearchCharacteristicsInStockBalance - FormField
//			** ListStandardSearchCharacteristicsInStockBalance - FormField
//			** ListAdvancedSearchCharacteristicsAvailable - FormField
//			** ListStandardSearchCharacteristicsAvailable - FormField
//			** ListOfAdvancedSearchPartnerNomenclature - FormField
//			** ListOfStandardSearchPartnerNomenclature - FormField
//			** AListOfAdvancedSearchItemPartnerItem - FormField
//			** TheListOfDefaultSearchItemPartnerItem - FormField
//			** ProductsHierarchy - FormTable
//			** TheHierarchyOfItemPartner - FormTable
//			** SearchStringProducts - FormField
//			** SearchBarCharacteristics - FormField
//			** StockBalancePeriodDescription - FormField
//			** StockBalance - FormField
//			** SupplierStockBalance - FormField
//			** FilterTree - FormTable
//			** FilterTreeFilter - FormField
//			** FilterTreePresentation - FormField
//			** FilterTreeFilterPresentation - FormField
//			** ListQualities - FormTable
//			** FilterPriceFrom - FormField
//			** FilterPriceUpTo - FormField
//			** CommandBarNavigationOption - FormButton
//			** LabelNavigationOption - FormField
//			** ProductsOfOriginalQuality - FormField
//			** CommandBarCreateProducts - FormGroup
//			** CommandBarCreateCharacteristic - FormGroup
//		* Commands - FormCommands - Where:
//			** MoveToDocument - FormCommand
//		* FilterParametersTable - FormDataCollection
//		* ListProducts - DynamicList - Where:
//			** Parameters - DataCompositionDataParameterValues
//		* FeatureList - DynamicList - Where:
//			** Parameters - DataCompositionDataParameterValues
//		* ListOfThePartnerSNomenclature - DynamicList - Where:
//			** Parameters - DataCompositionDataParameterValues
//		* NewCharacteristic - See SelectGoodsClientServer.StructureOfCharacteristicsString
//		* StockBalance - FormDataTreeItem
//		* SupplierStockBalance - FormDataTreeItem
//		
//
Procedure WhenCreatingMatchingFormOnServer(Form) Export
	
	Parameters = Form.Parameters;
	Items = Form.Items;
	ThisIsFormOfMatchingInSalesDocuments = SelectGoodsClientServer.ThisIsFormOfMatchingInSalesDocuments(Form.FormCode);
	ThisIsFormOfSelectionInPurchaseDocuments = SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode);
	AnExternalUserIsAuthorized = TMCommonUseClientServer.AnExternalUserIsAuthorized();
	
#Region GetFunctionOptionValues
	
	Form.UseItemPackages = GetFunctionalOption("UseItemPackages");
	Form.UseItemVariants = GetFunctionalOption("UseItemVariants");
	Form.UseStandardSearchWhenSelectingGoods = Constants.UseStandardSearchWhenSelectingGoods.Get();
	Form.UsePartnersAndCounterparties = GetFunctionalOption("UsePartnersAndCounterparties");
		
	If ThisIsFormOfMatchingInSalesDocuments Then
		
		If Parameters.Property("UsePriceManagementSystem25") Then
			Form.UsePriceManagementSystem25 = Parameters.UsePriceManagementSystem25;
		Else
			Form.UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(Parameters.Date);
		EndIf;
		
		Form.UseDiscountAdjustmentsInSales = GetFunctionalOption("UseDiscountAdjustmentsInSales")
			And Not AnExternalUserIsAuthorized;
		Form.UseItemsSoldTogether = GetFunctionalOption("UseItemsSoldTogether");
		
		If Not Form.SelectionModeWithoutAgreementsWithCustomers Then
			Form.ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
		EndIf;
		
		If Not Form.ToUseTermsOfSales Then
			
			PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
			PriceTypeSelectionParameters.PriceIncludesVAT = Form.Object.PriceIncludesVAT;
			PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
			PriceTypeSelectionParameters.Status = Enums.StatusesOfPriceTypeValidity.Valid;
			
			DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
			Form.OnlyOneSalePriceKind = Not DefaultPriceType.IsEmpty();
			
		EndIf;
		
	ElsIf ThisIsFormOfSelectionInPurchaseDocuments Then
		
		Form.UseDiscountAdjustmentsInPurchases = GetFunctionalOption("UseDiscountAdjustmentsInPurchases");
		Form.UsePartnersProducts = GetFunctionalOption("UsePartnersProducts");
		
	EndIf;
	
#EndRegion

#Region SetFormPropertiesByParameters
	
	#Region SetWarehouseSettingsByParameters
	
	ListOfWarehousesWasTransmitted = TypeOf(Parameters.Warehouse) = Type("ValueList");
	ThisIsWarehouseGroup = Not ListOfWarehousesWasTransmitted
		And Catalogs.Warehouses.IsFolder(Parameters.Warehouse);

	If ValueIsFilled(Parameters.Warehouse)
		And ThisIsWarehouseGroup Then
		
		SelectWarehouseGroup = New Array();
		SelectWarehouseGroup.Add(Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices);
		
		If Not Parameters.SelectionModeExcludeGroupsAvailableInOrders Then
			SelectWarehouseGroup.Add(Enums.SelectWarehouseGroup.AllowInOrders);
		EndIf;
		
		RequestForWarehouses = New Query();
		RequestForWarehouses.SetParameter("Warehouse", Parameters.Warehouse);
		RequestForWarehouses.SetParameter("SelectWarehouseGroup", SelectWarehouseGroup);
		RequestForWarehouses.Text =
		"SELECT ALLOWED DISTINCT
		|	Warehouses.Ref AS Warehouse
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref IN HIERARCHY(&Warehouse)
		|	AND Warehouses.SelectGroup IN(&SelectWarehouseGroup)
		|	AND NOT Warehouses.IsFolder";
		
		Form.Warehouses.LoadValues(RequestForWarehouses.Execute().Unload().UnloadColumn("Warehouse"));
		
	ElsIf ListOfWarehousesWasTransmitted Then
		
		Form.Warehouses.LoadValues(Parameters.Warehouse.UnloadValues());
		
	Else
		
		If ValueIsFilled(Parameters.Warehouse) Then
			Form.Warehouses.Add(Parameters.Warehouse);
		EndIf;
		
	EndIf;
	
	// If the warehouse is not selected, then fill in the list of warehouses with all allowed warehouses.
	If Form.Warehouses.Count() = 0
		And Not ListOfWarehousesWasTransmitted
		And Parameters.Property("AllWarehouseBalance")
		And Parameters.AllWarehouseBalance Then
		
		Form.AllWarehouseBalance = True;
		
		RequestForWarehouses = New Query();
		RequestForWarehouses.Text =
		"SELECT ALLOWED
		|	Warehouses.Ref AS Warehouse
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	(NOT Warehouses.IsFolder)";
		
		Form.Warehouses.LoadValues(RequestForWarehouses.Execute().Unload().UnloadColumn("Warehouse"));
		
	EndIf;
	
	If Form.Warehouses.Count() = 0 Then
		WarehouseParameter_ = Catalogs.Warehouses.EmptyRef();
	ElsIf Form.Warehouses.Count() = 1 Then
		WarehouseParameter_ = Form.Warehouses[0].Value;
	Else
		WarehouseParameter_ = Form.Warehouses.UnloadValues();
	EndIf;
	
	NumberOfWarehouses = Form.Warehouses.Count();
	MultipleWarehouses = (NumberOfWarehouses > 1);
	
	// Fill in the selection list of available warehouses in the shopping cart.
	Items.junkWarehouse.ChoiceParameters = New FixedArray(New Array);
	TMCommonUseClientServer.AddSelectionParameter(Items.junkWarehouse, "Ref", Form.Warehouses.UnloadValues());
	Items.junkWarehouse.Visible = (MultipleWarehouses And Parameters.SelectionModeUseWarehousesInTabularSection);
	
	If NumberOfWarehouses = 0 Then
		
		Form.OnlyInStock = False;
		Form.ShowBalance = False;
		
	EndIf;
	
	If Not ValueIsFilled(Parameters.Warehouse) Then 
		
		Form.OnlyInStock = False;
		
	EndIf;
	
	Form.DisplayBalanceLabel =
		?(Form.ShowBalance, 
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
	
	Items.junkWarehouse.ChoiceParameters = New FixedArray(New Array);
	TMCommonUseClientServer.AddSelectionParameter(Items.junkWarehouse, "Ref", WarehouseParameter_);
	
	#EndRegion
	
	#Region SetPropertiesOfSelectionFormForVATTaxation
	
	If Parameters.Property("VATTaxation")
		And ValueIsFilled(Parameters.VATTaxation) Then
		
		Restrictions = VATAccountingERP.RestrictionOfGoodsOnTaxation(Parameters.VATTaxation);
		For Each Restriction In Restrictions Do
			
			CommonClientServer.SetDynamicListFilterItem(
				Form.ListProducts,
				"Products." + Restriction.Attribute,
				Restriction.Value,
				Restriction.ComparisonType,
				"FilterDefault",
				True);
			
			If Restriction.Attribute = "DeleteExcisableGoods" Then
				Items.DecorationExcisableGoods.Visible = True;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	If ThisIsFormOfSelectionInPurchaseDocuments Then
		
		#Region SetSelectionFormPropertiesInPurchaseDocumentsByParameters
		
		FillPropertyValues(
			Form,
			Parameters,
			"Currency, Date, Terms, Partner,
			|SelectionModeUseWarehousesInTabularSection,
			|CheckFilling");
		
		Form.SupplierPartner = Parameters.Partner;
		
		If TMCommonUseClientServer.HasObjectAttribute(Parameters, "VendorPriceKind") Then
			Form.VendorPriceKind = Parameters.VendorPriceKind;
		EndIf;
		
		If TMCommonUseClientServer.HasObjectAttribute(Parameters, "PriceIncludesVAT") Then
			Form.Object.PriceIncludesVAT = Parameters.PriceIncludesVAT;
		EndIf;
		
		Form.ThereAreProductPricesOfSuppliersInTheFuture = ThereAreProductPriceValuesLaterThanPickUpDate(Form.Date);
		
		Form.Object.Warehouse = Parameters.Warehouse;
		
		If ValueIsFilled(Parameters.Terms) Then
			
			Terms = Parameters.Terms; // CatalogRef.TermsOfSale
			Form.Object.Terms = Terms;
			Form.Organization = Common.ObjectAttributeValue(Terms, "Organization");
			
		EndIf;
		
		Form.Object.Partner = Parameters.Partner;
		
		// Set the properties of the form elements according to the passed parameters.
		CommonClientServer.SetDynamicListFilterItem(
		Form.TheHierarchyOfItemPartner, "Owner", Form.SupplierPartner);
		
		// Fill in the values of the form and object details according to the passed parameters.
		Items.junkWarehouse.Visible = Form.SelectionModeUseWarehousesInTabularSection And (Form.Warehouses.Count() > 1);
		
		If Parameters.ModeOfSelectionWithoutQuantitativeParameters <> Undefined Then
			Form.ModeOfSelectionWithoutQuantitativeParameters = Parameters.ModeOfSelectionWithoutQuantitativeParameters;
		EndIf;
		
		If Parameters.SelectionModeWithoutAmountParameters <> Undefined Then
			Form.SelectionModeWithoutAmountParameters = Parameters.SelectionModeWithoutAmountParameters;
		EndIf;
		
		If Parameters.HideManualDiscounts <> Undefined Then
			Form.HideManualDiscounts = Parameters.HideManualDiscounts;
		EndIf;
		
		If Not Form.SelectionModeWithoutAmountParameters
			And Not ValueIsFilled(Form.Currency) Then
				
			Form.Currency = SettingsValueCached.ManagementAccountingCurrency();
			
		EndIf;
		
		// Set the properties of the form elements according to the passed parameters.
		Items.junkPrice.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đơn giá (%1)';
																								|ru = 'Цена (%1)';
																								|en = 'Price (%1)'; fa = 'Price (%1)';
																								|it = 'Prezzo (%1)';
																								|pl = 'Cena (%1)';
																								|tr = 'Fiyat (%1)'"), Form.Currency);
		
		CommonClientServer.SetDynamicListFilterItem(
		Form.ListOfThePartnerSNomenclature, "Owner", Parameters.Partner, 
		DataCompositionComparisonType.Equal, "FilterDefault", ValueIsFilled(Parameters.Partner));
		
		If ValueIsFilled(Parameters.Title) Then
			
			Form.AutoTitle = False;
			Form.Title = Parameters.Title;
			
		EndIf;
		
		If ValueIsFilled(Parameters.TransferButtonTitle) Then
			
			Form.Commands.MoveToDocument.Title = Parameters.TransferButtonTitle;
			Form.Commands.MoveToDocument.ToolTip = Parameters.TransferButtonTitle;
			Form.Items.CommandBarMove.Width = 24;
			
		EndIf;
		
		If Parameters.ModeOfSelectionWithoutQuantitativeParameters Then
			Items.ShoppingCartQuantitativeParameters.Visible = False;
		EndIf;
		
		DisplayRemainingQuantityInWarehouses = Not Parameters.HideCommandRemainingQuantityInWarehouses And Not (Form.Warehouses.Count() = 0);
		Form.HideCommandRemainingQuantityInWarehouses = Parameters.HideCommandRemainingQuantityInWarehouses;
		Form.DisplayRemainingQuantityInWarehouses = DisplayRemainingQuantityInWarehouses;
		
		Items.DisplayBalanceLabel.Visible = DisplayRemainingQuantityInWarehouses;
		Items.DisplayTheRemainingInventoryItemsOfThePartnerLabel.Visible = DisplayRemainingQuantityInWarehouses;
		
		If FirstOpeningOfForm(Form.FormCode) Then
			
			SetSelectionTreeParametersQualityNew(Form);
			Form.ShowBalance = True;
			
		EndIf;
		
		Items.StockBalance.Visible = Form.ShowBalance And DisplayRemainingQuantityInWarehouses And Not Form.ModeOfSelectionWithoutQuantitativeParameters;
		Items.SupplierStockBalance.Visible = Form.ShowBalance And DisplayRemainingQuantityInWarehouses And Not Form.HideCommandRemainingQuantityInWarehouses;
		
		// Set the visibility of the remainder display elements.
		
		Items.OnlyInStock.Visible = DisplayRemainingQuantityInWarehouses;
		
		Items.ListStandardSearchProductsInStockBalance.Visible = Not Parameters.HideCommandRemainingQuantityInWarehouses;
		Items.ListAdvancedSearchProductsInStockBalance.Visible = Not Parameters.HideCommandRemainingQuantityInWarehouses;
		
		Items.ListStandardSearchProductsAvailable.Visible = DisplayRemainingQuantityInWarehouses;
		Items.ListAdvancedSearchProductsAvailable.Visible = DisplayRemainingQuantityInWarehouses;
		Items.ListStandardSearchCharacteristicsInStockBalance.Visible = Not Parameters.HideCommandRemainingQuantityInWarehouses;
		Items.ListStandardSearchCharacteristicsAvailable.Visible = DisplayRemainingQuantityInWarehouses;
		Items.ListAdvancedSearchCharacteristicsInStockBalance.Visible = Not Parameters.HideCommandRemainingQuantityInWarehouses;
		Items.ListAdvancedSearchCharacteristicsAvailable.Visible = DisplayRemainingQuantityInWarehouses;
		
		// Set the visibility of the price display elements.
		VisibilityOfPriceDisplayElements = Not Parameters.HideTheItemPricesCommand;
		
		Items.ListStandardSearchItemContextMenuGoToItemPrices.Visible = VisibilityOfPriceDisplayElements;
		Items.ListStandardSearchCharacteristicsContextMenuItemsPrices.Visible = VisibilityOfPriceDisplayElements;
		Items.AListOfAdvancedSearchItemContextMenuToNavigateToTheItemCost.Visible = VisibilityOfPriceDisplayElements;
		Items.ListAdvancedSearchCharacteristicsContextMenuItemsPrices.Visible = VisibilityOfPriceDisplayElements;
		Items.TheListOfDefaultSearchItemPartnerContextMenuToNavigateToTheItemCost.Visible = VisibilityOfPriceDisplayElements;
		Items.ListAdvancedSearchPartnerSItemContextMenuGoToItemPrices.Visible = VisibilityOfPriceDisplayElements;
		
		If Parameters.SelectionModeWithoutAmountParameters Then
			Items.junkManualDiscount.Visible = False;
			Items.junkPercentRateOfManualDiscount.Visible = False;
			Items.junkSum.Visible = False;
			Items.junkPrice.Visible = False;
			Items.ListStandardSearchProductsPrice.Visible = False;
			Items.ListAdvancedSearchProductsPrice.Visible = False;
			Items.ListAdvancedSearchCharacteristicsPrice.Visible = False;
			Items.ListStandardSearchCharacteristicsPrice.Visible = False;
			Items.ListOfStandardSearchPartnerNomenclaturePrice.Visible = False;
			Items.ListOfAdvancedSearchPartnerNomenclaturePrice.Visible = False;
			Items.GroupFilterByPrice.Visible = False;
			Items.TypeOfSupplierSPriceItem.Visible = False;
			Items.VendorPriceKind.Visible = False;
			Items.junkVendorPriceKind.Visible = False;
		EndIf;
		
		If Parameters.HideManualDiscounts Then
			Items.junkManualDiscount.Visible = False;
			Items.junkPercentRateOfManualDiscount.Visible = False;
		EndIf;
		
		If Not (Parameters.RequestQuantity = Undefined) Then
			Form.RequestQuantity = Parameters.RequestQuantity;
		EndIf;
		
		Items.RequestQuantityPrice.Visible = Not Parameters.HideTheRequestQuantityButton;
		Items.RequestQuantityPrice.Check = Form.RequestQuantity;
		
		If Form.SelectionModeWithoutAmountParameters Then
			Items.RequestQuantityPrice.Title = NStr("vi = 'Hỏi số lượng';
													|ru = 'Запрашивать количество';
													|en = 'Request quantity'; fa = 'درخواست مقدار';
													|it = 'Richiedere la quantità';
													|pl = 'Żądaj ilości';
													|tr = 'Miktarı sorgula'");
		EndIf;
		
		If Not Form.UsePartnersProducts Or Not ValueIsFilled(Parameters.Partner) Then
			Items.ThePartnerSNomenclaturePage.Visible = False;
			Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
			Items.PartnerProducts.Visible = False;
		EndIf;
		
		Form.ProductsKindBeforeChange = Form.ProductKind;
		
		Items.PageCreateProducts.Visible = AccessRight("Insert", Metadata.Catalogs.Products);
		Items.PageCreateCharacteristic.Visible = AccessRight("Insert", Metadata.Catalogs.ItemsCharacteristics);
		
		#EndRegion
		
	ElsIf ThisIsFormOfMatchingInSalesDocuments Then
		
		#Region SetSelectionFormPropertiesInSalesDocumentsByParameters
		
		FirstOpeningOfForm = FirstOpeningOfForm(Form.FormCode);
		If FirstOpeningOfForm Then
			SetSelectionTreeParametersQualityNew(Form);
		EndIf;
		
		If ValueIsFilled(Parameters.Terms) Then
			ProductSegment = GeneralPurposeTMServerCall.ObjectAttributeValue(Parameters.Terms, "ProductSegment");
			Form.ProductSegment = ProductSegment;
		Else 
			Form.ProductSegment = Catalogs.ProductSegments.EmptyRef();
		EndIf;
		
		Items.ProductSegment.Enabled = AccessRight("View", Metadata.Catalogs.ProductSegments); 
		
		Items.junkProducts.ReadOnly = Parameters.ToHideTheItem;
		
		Form.Currency = Parameters.Currency;
		Form.Date = Parameters.Date;
		Form.Object.Warehouse = Parameters.Warehouse;
		Form.Partner = Parameters.Partner;
		Form.Terms = Parameters.Terms;
		Form.Object.Terms = Parameters.Terms;
		Form.Object.VATTaxation = Parameters.VATTaxation;
		Form.Object.PriceIncludesVAT = Parameters.PriceIncludesVAT;
		Form.SelectionModeUseWarehousesInTabularSection = Parameters.SelectionModeUseWarehousesInTabularSection;
		Form.ReturnReusablePackage = Parameters.ReturnReusablePackage;
		Form.PriceKind = Parameters.PriceKind;
		Form.ModeOfSelectionWithoutQuantitativeParameters = Parameters.ModeOfSelectionWithoutQuantitativeParameters;
		Form.SelectionModeWithoutAmountParameters = Parameters.SelectionModeWithoutAmountParameters;
		Form.SelectionModeWithoutAgreementsWithCustomers = Parameters.SelectionModeWithoutAgreementsWithCustomers;
		Form.HideManualDiscounts = Parameters.HideManualDiscounts;
		Form.UseShipmentDates = Parameters.UseShipmentDates;
		Form.DoNotSplitSetsByComponents = Parameters.DoNotSplitSetsByComponents;
		Form.AnalysisOptionOfProductsSoldTogether = Parameters.AnalysisOptionOfProductsSoldTogether;

		If TypeOf(Parameters.SelectionParametersPriceType) = Type("Array") Then
			SelectionParametersPriceType = Parameters.SelectionParametersPriceType;
		Else
			SelectionParametersPriceType = New Array;
		EndIf;
		
		If SelectionParametersPriceType.Count() = 0 Then
			SelectionParametersPriceType.Add(New ChoiceParameter("Filter.UseWhileSellingToCustomers", True));
		EndIf;
		
		ItemSelectionOptions_ = New Array(Form.Items.junkPriceKind.ChoiceParameters);
		For Each PriceTypeSelectionParameter In SelectionParametersPriceType Do
			
			If TypeOf(PriceTypeSelectionParameter) = Type("ChoiceParameter") Then
				ItemSelectionOptions_.Add(PriceTypeSelectionParameter);
			EndIf;
			
		EndDo;
		
		Form.Items.junkPriceKind.ChoiceParameters = New FixedArray(ItemSelectionOptions_);

		TypesOfObjectPricesAndSalesConditions = Undefined;
		
		TypesOfPrices = New Array();
		
		If Not Form.SelectionModeWithoutAmountParameters Then
			
			If Form.SelectionModeByProductRange Then
				
				Form.ProductRangePlanningObject = ProductRangeServer.PlanningObject(WarehouseParameter_, Form.Date);
				
				SelectionOfPriceTypes = New Structure;
				SelectionOfPriceTypes.Insert("SalesAreAllowed", True);
				
				TypesOfPrices = ProductRangeServer.TypesOfPricesByAssortment(Form.ProductRangePlanningObject, Form.Date, SelectionOfPriceTypes);
				Form.ThereArePricesInTheFuture = ThereArePriceValuesLaterThanPickUpDate(Form.Date, TypesOfPrices, Form.UsePriceManagementSystem25);
				
			ElsIf Form.SelectionModeForRetailSales Then
				
				If Form.UsePriceManagementSystem25 Then
					
					Form.ObjectForStoringSalesTermsAndConditions = ProductRangeServerCached.StoreFormatByWarehouse(WarehouseParameter_, Form.Date);
					TypesOfPrices.Add(Common.ObjectAttributeValue(Form.ObjectForStoringSalesTermsAndConditions, "RetailPriceType"));
					Form.TheTypeOfPricesIsIndividual = Common.ObjectAttributeValue(Form.ObjectForStoringSalesTermsAndConditions, "SpecialPriceType");
					Form.ThereArePricesInTheFuture = ThereArePriceValuesLaterThanPickUpDate(Form.Date, TypesOfPrices, Form.UsePriceManagementSystem25);
					
				EndIf;
				
			ElsIf Form.SelectionModeWithoutAgreementsWithCustomers Then
				
				TypesOfPrices.Add(Form.PriceKind);
				Form.ThereArePricesInTheFuture = ThereArePriceValuesLaterThanPickUpDate(Form.Date, TypesOfPrices, Form.UsePriceManagementSystem25);
				
			ElsIf Not Form.ToUseTermsOfSales Then
				
				Form.ObjectForStoringSalesTermsAndConditions = Form.Partner;
				
				If Form.UsePriceManagementSystem25 Then
					
					TypesOfPrices.Add(Common.ObjectAttributeValue(Form.ObjectForStoringSalesTermsAndConditions, "PricesKind"));
					Form.TheTypeOfPricesIsIndividual = Common.ObjectAttributeValue(Form.ObjectForStoringSalesTermsAndConditions, "SpecialPriceType");
					
				EndIf;
				
				If Not ValueIsFilled(TypesOfPrices) Then
					TypesOfPrices = DefaultPriceTypes(Form.Object.PriceIncludesVAT);
				EndIf;
				
				Form.ThereArePricesInTheFuture = ThereArePriceValuesLaterThanPickUpDate(Form.Date, TypesOfPrices, Form.UsePriceManagementSystem25);
				
			Else
				
				Form.ObjectForStoringSalesTermsAndConditions = Form.Terms;
				
				If Form.UsePriceManagementSystem25 Then
					
					TypesOfPrices.Add(Common.ObjectAttributeValue(Form.ObjectForStoringSalesTermsAndConditions, "PricesKind"));
					Form.TheTypeOfPricesIsIndividual = Common.ObjectAttributeValue(Form.ObjectForStoringSalesTermsAndConditions, "SpecialPriceType");
					
				Else
					TypesOfPrices = TypesOfPricesByAgreementWithClient(Form.Terms);
				EndIf;
				
				If Not ValueIsFilled(TypesOfPrices) Then
					TypesOfPrices = DefaultPriceTypes(Form.Object.PriceIncludesVAT);
				EndIf;
				
				Form.ThereArePricesInTheFuture = ThereArePriceValuesLaterThanPickUpDate(Form.Date, TypesOfPrices, Form.UsePriceManagementSystem25);
				
			EndIf;
			
		EndIf;
		
		Form.TypesOfPrices.LoadValues(TypesOfPrices);
		
		If Not TypesOfObjectPricesAndSalesConditions = Undefined Then
			If TypesOfObjectPricesAndSalesConditions.Property("PricesKind") Then
				Form.MainPriceType = TypesOfObjectPricesAndSalesConditions.PricesKind;
			ElsIf TypesOfObjectPricesAndSalesConditions.Property("RetailPriceType") Then 
				Form.MainPriceType = TypesOfObjectPricesAndSalesConditions.RetailPriceType;
			Else
				Form.MainPriceType = Catalogs.TypesOfPrices.EmptyRef();
			EndIf;
			
			If TypesOfObjectPricesAndSalesConditions.Property("SpecialPriceType") Then
				Form.TheTypeOfPricesIsIndividual = TypesOfObjectPricesAndSalesConditions.SpecialPriceType;
			Else
				Form.TheTypeOfPricesIsIndividual = Catalogs.TypesOfPrices.EmptyRef();
			EndIf;
		Else
			Form.DoNotUsePriceTypesBasedOnTheSalesCondition = True;
		EndIf;
		
		If Form.UsePriceManagementSystem25 Then
			If Form.SelectionModeWithoutAmountParameters Then
				Form.PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.WithoutPrices;
			ElsIf (Not Form.ToUseTermsOfSales Or Form.SelectionModeWithoutAgreementsWithCustomers) 
				And Not Form.SelectionModeForRetailSales Then
				Form.PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeader;
			Else
				Form.PriceCalculationOption = PriceCalculationOption(Form);
			EndIf;
		Else
			If Form.SelectionModeWithoutAmountParameters Then
				Form.PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.WithoutPrices;
			ElsIf Not Form.ToUseTermsOfSales
				Or Form.SelectionModeWithoutAgreementsWithCustomers Then	
				Form.PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeader;
			Else
				Form.PriceCalculationOption = Common.ObjectAttributeValue(Form.Terms, "PriceCalculationOption");
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(Form.PriceCalculationOption) Then
			Form.PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.WithoutPrices;
		EndIf;
		
		If Not ValueIsFilled(Form.AnalysisOptionOfProductsSoldTogether) Then
			Form.AnalysisOptionOfProductsSoldTogether = Enums.AnalysisOptionsForItemsSoldTogether.Wholesale;
		EndIf;
		
		Items.junkDateOfShipment.Visible = Form.UseShipmentDates;
		
		If Not Form.SelectionModeWithoutAmountParameters Then
			If Not ValueIsFilled(Form.Currency) Then
				Form.Currency = SettingsValueCached.ManagementAccountingCurrency();
			EndIf;
		EndIf;
		
		If Parameters.ModeOfSelectionWithoutQuantitativeParameters Then
			Items.ShoppingCartQuantitativeParameters.Visible = False;
		EndIf;
		
		WithoutFilterByUseWhileSellingToCustomersInPrice = False;
		If Parameters.Property("Document") Then
			
			If TypeOf(Parameters.Document) = Type("DocumentRef.OBEntryGoods") Then
				NewParameters = New Array;
				NewParameters.Add(New ChoiceParameter("OutputAnArbitraryTypeOfPrices", True));
				NewParameters.Add(New ChoiceParameter("Filter.Status", Enums.StatusesOfPriceTypeValidity.Valid));
				Items.junkPriceKind.ChoiceParameters = New FixedArray(NewParameters);
				
				WithoutFilterByUseWhileSellingToCustomersInPrice = True;
			EndIf;
			
		EndIf;
		
		PushingAssignment = Undefined;
		If ValueIsFilled(Parameters.LineOfBusiness) Then
			PushingAssignment = LinesOfBusinessServer.PushingAssignment(Parameters.LineOfBusiness);
		EndIf;
		ModeForSelectingBalancesByBusinessLine = ValueIsFilled(PushingAssignment);
		Form.WithAssignment = ModeForSelectingBalancesByBusinessLine;
		Form.FilterByAssignment = PushingAssignment;
		Form.TheSelectionForTheAppointmentOfTheCurrent = PushingAssignment;
		Form.ModeForSelectingBalancesByBusinessLine = ModeForSelectingBalancesByBusinessLine;
		Items.ApartFromStandardSearchNomenclature.Visible = ModeForSelectingBalancesByBusinessLine;
		Items.SeparatelyAdvancedSearchNomenclature.Visible = ModeForSelectingBalancesByBusinessLine;
		Items.StandAloneStandardFeatureSearch.Visible = ModeForSelectingBalancesByBusinessLine;
		Items.SeparatelyAdvancedFeatureSearch.Visible = ModeForSelectingBalancesByBusinessLine;
		Items.junkWithAssignment.Visible = ModeForSelectingBalancesByBusinessLine
			Or Form.SelectSupplyOptions
				And Not Form.LimitSupplyOptions;
		Items.junkSupplyOption.Visible = Form.SelectSupplyOptions
			And Not Form.LimitSupplyOptions;
		
		If Form.SelectSupplyOptions
			And Not Form.LimitSupplyOptions Then
			Items.junkSupplyOption.ChoiceList.Clear();
			Items.junkSupplyOption.ChoiceList.Add(Enums.SupplyOptions.Ship);
			Items.junkSupplyOption.ChoiceList.Add(Enums.SupplyOptions.FromWarehouse);
			Items.junkSupplyOption.ChoiceList.Add(Enums.SupplyOptions.ToSupply);
			Items.junkSupplyOption.ChoiceList.Add(Enums.SupplyOptions.ReserveAsReceived);
			Items.junkSupplyOption.ChoiceList.Add(Enums.SupplyOptions.NotRequired);
		EndIf;
		
		DisplayRemainingQuantityInWarehouses = Not Parameters.HideCommandRemainingQuantityInWarehouses And Not (Form.Warehouses.Count() = 0);
		Form.HideCommandRemainingQuantityInWarehouses = Parameters.HideCommandRemainingQuantityInWarehouses;
		Form.DisplayRemainingQuantityInWarehouses = DisplayRemainingQuantityInWarehouses;
		
		If FirstOpeningOfForm Then
			Form.ShowBalance = True;
		EndIf;
		
		// The remains are in the form of a selection.
		Items.DisplayBalanceLabel.Visible = DisplayRemainingQuantityInWarehouses
			And Not ValueIsFilled(Parameters.LineOfBusiness);
		Items.StockBalance.Visible = Form.ShowBalance
			And DisplayRemainingQuantityInWarehouses
			And Not ValueIsFilled(Parameters.LineOfBusiness);
		Items.ListStandardSearchProductsInStockBalance.Visible = Not Form.HideCommandRemainingQuantityInWarehouses;
		Items.ListAdvancedSearchProductsInStockBalance.Visible = Not Form.HideCommandRemainingQuantityInWarehouses;
		Items.ListStandardSearchCharacteristicsInStockBalance.Visible = Not Form.HideCommandRemainingQuantityInWarehouses;
		Items.ListAdvancedSearchCharacteristicsInStockBalance.Visible = Not Form.HideCommandRemainingQuantityInWarehouses;
		SetVisibilityOfAvailableMatchingBalancesInSalesDocument(Form);
		
		Items.OnlyInStock.Visible = DisplayRemainingQuantityInWarehouses;
		
		If UserRightsCached.ThisIsPartner() Then
			Items.OnlyInStock.Visible = False;
		EndIf;
		
		If Parameters.SelectionModeWithoutAmountParameters Then
			Items.junkManualDiscount.Visible = False;
			Items.junkPercentRateOfManualDiscount.Visible = False;
			Items.junkSum.Visible = False;
			Items.junkPrice.Visible = False;
			Items.ListStandardSearchProductsPrice.Visible = False;
			Items.ListAdvancedSearchProductsPrice.Visible = False;
			Items.ListAdvancedSearchCharacteristicsPrice.Visible = False;
			Items.ListStandardSearchCharacteristicsPrice.Visible = False;
			Items.GroupFilterByPrice.Visible = False;
			
			Items.junkContextMenuFillThePricesByTermsOfSales.Visible            = False;
			Items.junkContextMenuFillInPricesOfSelectedRowsByPriceType.Visible = False;
			Items.junkContextMenuAssignAManualDiscount.Visible                = False;
			Items.junkContextMenuAssignAManualDiscountToSelectedRows.Visible = False;
			Items.junkContextMenuCancelManualDiscounts.Visible                 = False;
		EndIf;
		
		If Parameters.HideManualDiscounts Then
			Items.junkManualDiscount.Visible = False;
			Items.junkPercentRateOfManualDiscount.Visible = False;
			Items.junkContextMenuAssignAManualDiscount.Visible                = False;
			Items.junkContextMenuAssignAManualDiscountToSelectedRows.Visible = False;
			Items.junkContextMenuCancelManualDiscounts.Visible                 = False;
		EndIf;
		
		If ValueIsFilled(Parameters.Title) Then
			Form.AutoTitle = False;
			Form.Title = Parameters.Title;
		EndIf;
		
		If ValueIsFilled(Parameters.TransferButtonTitle) Then
			Form.Commands.MoveToDocument.Title = Parameters.TransferButtonTitle;
			Form.Commands.MoveToDocument.ToolTip = Parameters.TransferButtonTitle;
		EndIf;
		
		If Parameters.RequestQuantity <> Undefined Then
			Form.RequestQuantity = Parameters.RequestQuantity;
		EndIf;
		
		Items.NotRequestQuantity.Visible = Not Parameters.HideTheRequestQuantityButton And Not Form.SelectionModeWithoutAmountParameters;
		Items.RequestQuantityPrice.Visible = Not Parameters.HideTheRequestQuantityButton And Not Form.SelectionModeWithoutAmountParameters;
		Items.RequestQuantity.Visible = Not Parameters.HideTheRequestQuantityButton;
		
		Items.ListStandardSearchProductsContextMenuItemsPrices.Visible = Not Parameters.HideTheItemPricesCommand;
		Items.ListAdvancedSearchProductsContextMenuItemsPrices.Visible = Not Parameters.HideTheItemPricesCommand;
		Items.ListAdvancedSearchCharacteristicsContextMenuItemsPrices.Visible = Not Parameters.HideTheItemPricesCommand;
		Items.ListStandardSearchCharacteristicsContextMenuItemsPrices.Visible = Not Parameters.HideTheItemPricesCommand;
		Items.junkPriceKind.Visible = Not (Parameters.SelectionModeWithoutAmountParameters Or Parameters.HideTheViewPriceColumn);
		
		Items.junkContextMenuFillThePricesByTermsOfSales.Visible            = Not (Parameters.SelectionModeWithoutAmountParameters Or Parameters.HideTheViewPriceColumn);
		Items.junkContextMenuFillInPricesOfSelectedRowsByPriceType.Visible = Not (Parameters.SelectionModeWithoutAmountParameters Or Parameters.HideTheViewPriceColumn);
		
		Items.junkIndexGoodsSoldTogether.Visible = GetFunctionalOption("UseItemsSoldTogether");
		
		Form.ProductsKindBeforeChange = Form.ProductKind;
		
		Items.PageCreateProducts.Visible = AccessRight("Insert", Metadata.Catalogs.Products);
		Items.PageCreateCharacteristic.Visible = AccessRight("Insert", Metadata.Catalogs.ItemsCharacteristics);
		
		Form.ProhibitionOfSetContent = Parameters.ProhibitionOfSetContent;
		Form.ProhibitionOfEditingSetPrice    = Parameters.ProhibitionOfEditingSetPrice;
		
		Form.WithoutFilterByVATInclusionInPrice      = Parameters.WithoutFilterByVATInclusionInPrice;
		Form.ProhibitionOfSetContent = Parameters.ProhibitionOfSetContent;
		Form.ProhibitionOfEditingSetPrice    = Parameters.ProhibitionOfEditingSetPrice;
		Form.WithoutFilterByUseWhileSellingToCustomersInPrice    = WithoutFilterByUseWhileSellingToCustomersInPrice;
		
		Form.TheModeOfSelectionForDocumentsPricing = Parameters.TheModeOfSelectionForDocumentsPricing;
		
		#EndRegion
		
	EndIf;
	
#EndRegion
	SetValuesForFormSettings(Form);
	
#Region SetValuesBasedOnSelectionFormSettings
	
	Form.OnlyInStock = False;
	
	Settings = Common.CommonSettingsStorageLoad(Form.FormCode,  "");
	
	If Not (Settings = Undefined) Then
		
		If Settings.Property("OnlyInStock") Then
			Form.OnlyInStock = Settings.OnlyInStock And Form.DisplayRemainingQuantityInWarehouses;
		EndIf;
		
		If Form.HideCommandRemainingQuantityInWarehouses Then
			Form.OnlyInStock = False;
		EndIf; 
		
		// The remains are in the form of a selection.
		If Settings.Property("ShowBalance") Then
			Form.ShowBalance = Settings.ShowBalance;
			Form.DisplayBalanceLabel = ?(Form.ShowBalance,
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
			
			Items.StockBalance.Visible = Form.ShowBalance
				And Not (Form.ModeOfSelectionWithoutQuantitativeParameters
					Or Form.HideCommandRemainingQuantityInWarehouses)
				And Form.DisplayRemainingQuantityInWarehouses
				And (ThisIsFormOfSelectionInPurchaseDocuments Or Not ValueIsFilled(Parameters.LineOfBusiness));
			
			If ThisIsFormOfSelectionInPurchaseDocuments Then
				Items.SupplierStockBalance.Visible = Form.ShowBalance
					And Not Form.HideCommandRemainingQuantityInWarehouses;
			EndIf;
		EndIf;
		
		If Settings.Property("ShowSelectedGoods") Then
			
			Form.ShowSelectedGoods = Settings.ShowSelectedGoods;
			
		EndIf;
		
		If ThisIsFormOfMatchingInSalesDocuments Then
			If Settings.Property("RequestQuantity") Then
				Form.RequestQuantity = Settings.RequestQuantity;
			Else
				Form.RequestQuantity = GetFunctionalOption("UseItemsBatch");
			EndIf;
			
			If Settings.Property("RequestPrice") Then
				Form.RequestPrice = Settings.RequestPrice;
			Else
				Form.RequestPrice = True;
			EndIf;
		Else
			If Settings.Property("RequestQuantity") Then
				Form.RequestQuantity = Settings.RequestQuantity;
			EndIf;
		EndIf;
		
	EndIf;
	
	If ThisIsFormOfSelectionInPurchaseDocuments Then
		Items.RequestQuantityPrice.Check = Form.RequestQuantity;
	Else
		Items.NotRequestQuantity.Check = Not Form.RequestQuantity;
		Items.RequestQuantity.Check = Form.RequestQuantity And (Not Form.RequestPrice Or Form.SelectionModeWithoutAmountParameters);
		Items.RequestQuantityPrice.Check = Form.RequestQuantity And Form.RequestPrice;
	EndIf;

#EndRegion	

	SetFilterOnlyInStock(Form);

	#Region SetFormElementHeadersByParameters
	NameOfProductList = SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form);
	NameOfListOfCharacteristics = SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(Form);
		
	TitleText = NStr("vi = 'Đơn giá';
					|ru = 'Цена';
					|en = 'Price'; fa = 'قیمت';
					|it = 'Prezzo';
					|pl = 'Cena';
					|tr = 'Fiyat'");
	
	If ValueIsFilled(Form.Currency) Then
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đơn giá (%1)';
																					|ru = 'Цена (%1)';
																					|en = 'Price (%1)'; fa = 'Price (%1)';
																					|it = 'Prezzo (%1)';
																					|pl = 'Cena (%1)';
																					|tr = 'Fiyat (%1)'"), Form.Currency);
	EndIf;
	
	ProductPriceField = Form.Items[NameOfProductList].ChildItems[NameOfProductList+"Price"]; // FormField
	FormFieldCharacteristicPrice = Form.Items[NameOfListOfCharacteristics].ChildItems[NameOfListOfCharacteristics+"Price"]; // FormField
	
	ProductPriceField.Title = TitleText;
	FormFieldCharacteristicPrice.Title = TitleText;
	
	Items.junkPrice.Title = TitleText;
	WarehouseGroupSelected = Not ListOfWarehousesWasTransmitted And Catalogs.Warehouses.IsFolder(Parameters.Warehouse);
	
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(
		?(WarehouseGroupSelected,
		NStr("vi = 'Chỉ có sẵn trong nhóm kho bãi ""%1""';
			|ru = 'Только в наличии на группе складов ""%1""';
			|en = 'Only in stock in the ""%1"" warehouse group'; fa = 'Only in stock in the ""%1"" warehouse group';
			|it = 'Disponibile solo nel gruppo di magazzini ""%1""';
			|pl = 'Tylko dostęne w grupie magazynów ""%1""';
			|tr = 'Sadece ""%1"" ambar grubu stoklarında mevcut'"),
		?(Not ListOfWarehousesWasTransmitted And ValueIsFilled(Parameters.Warehouse),
			NStr("vi = 'Chỉ có sẵn trong kho ""%1""';
				|ru = 'Только в наличии на складе ""%1""';
				|en = 'Only in stock at the ""%1"" warehouse'; fa = 'Only in stock at the ""%1"" warehouse';
				|it = 'Disponibile solo nel magazzino ""%1""';
				|pl = 'Tylko dostęne w magazynie ""%1""';
				|tr = 'Sadece ""%1"" ambar stoklarında mevcut'"), NStr("vi = 'Chỉ có sẵn';
																		|ru = 'Только в наличии';
																		|en = 'Only in stock'; fa = 'فقط موجود در انبار';
																		|it = 'Solo disponibile';
																		|pl = 'Tylko dostępne';
																		|tr = 'Sadece stoktaki'"))),
		Parameters.Warehouse);
	
	If Parameters.Property("Document") Then
		If TypeOf(Parameters.Document) <> Type("DocumentRef.PriceSetup") Then
			Items.OnlyInStock.Title = TitleText;
		EndIf;
	Else
		Items.OnlyInStock.Title = TitleText;
	EndIf;
#EndRegion

	SetQualityValueListItems(Form);
	SetSelectionByTypeOfProductByParameters_(Form);
	
#Region SetSelectionByOptionOfCalculatingPricesOfSets
	
	If ThisIsFormOfMatchingInSalesDocuments Then
		
		If Parameters.SelectionByTheOptionOfCalculatingThePricesOfSets <> Undefined Then
			SelectionByTheOptionOfCalculatingThePricesOfSets = Parameters.SelectionByTheOptionOfCalculatingThePricesOfSets;
			Filter = New ValueList;
			Filter.LoadValues(SelectionByTheOptionOfCalculatingThePricesOfSets);
			
			CommonClientServer.SetDynamicListFilterItem(
				Form.ListProducts, "SetPricingOption", Filter, 
				DataCompositionComparisonType.InList, "SelectionByTheOptionOfCalculatingThePricesOfSets", (Filter.Count() > 0));
				
			CommonClientServer.SetDynamicListFilterItem(
				Form.FeatureList, "SetPricingOption", Filter, 
				DataCompositionComparisonType.InList, "SelectionByTheOptionOfCalculatingThePricesOfSets", (Filter.Count() > 0));
		EndIf;
	EndIf;
	
#EndRegion

#Region SetFilterAccountingFeature
	If Parameters.Property("AccountingFeature") Then
		CommonClientServer.SetDynamicListFilterItem(
		Form.ListProducts, "Ref.AccountingFeature", Parameters.AccountingFeature, 
			DataCompositionComparisonType.InList, "FilterAccountingFeature",ValueIsFilled(Parameters.AccountingFeature));
	EndIf;

#EndRegion

#Region SetFilterAccountingFeature

	If Parameters.Property("ItemsCollection") Then
		CommonClientServer.SetDynamicListFilterItem(
		Form.ListProducts, "Ref.ItemsCollection", Parameters.ItemsCollection, 
			DataCompositionComparisonType.Equal, "FilterItemsCollection",ValueIsFilled(Parameters.ItemsCollection));
	EndIf;

#EndRegion

	Form.CurrentLineOfProducts = SelectGoodsClientServer.StructureOfProductLine();
	Form.CurrentCharacteristicLine = SelectGoodsClientServer.StructureOfCharacteristicsString();
	
	TMCommonUse.InitializeFormDetailsForFullTextSearch(Form, "UseFullTextSearchWhenSelectingGoods");
	
	SetQueryTextsForMatchingFormLists(Form);

	#Region SetSelectionFormListParameters
	
	ListProducts = Form.ListProducts;
	FeatureList = Form.FeatureList;
	
	If ThisIsFormOfSelectionInPurchaseDocuments Then
		ListOfThePartnerSNomenclature = Form.ListOfThePartnerSNomenclature;
	EndIf;
	
	BaseCurrency = SettingsValueCached.DefaultBaseCurrency();
	
	If ThisIsFormOfMatchingInSalesDocuments Then
		
		If Form.SelectionModeByProductRange Then
			SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "PlanningObject", Form.ProductRangePlanningObject);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "PlanningObject", Form.ProductRangePlanningObject);
		EndIf;
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "ProductSegment", Form.ProductSegment, ValueIsFilled(Form.ProductSegment));
		If Form.ToUseTermsOfSales
			And Not Form.SelectionModeWithoutAgreementsWithCustomers Then
			SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "Terms", Form.Terms);
		EndIf;
		
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "Currency", Form.Currency);
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "BaseCurrency", BaseCurrency);
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "Date", Form.Date);
		
		If Form.TypesOfPrices.Count() = 0 Then
			TypesOfPricesParameter = Catalogs.TypesOfPrices.EmptyRef();
		ElsIf Form.TypesOfPrices.Count() = 1 Then
			TypesOfPricesParameter = Form.TypesOfPrices[0].Value;
		Else
			TypesOfPricesParameter = Form.TypesOfPrices.UnloadValues();
		EndIf;
		
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "TypesOfPrices", TypesOfPricesParameter);
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "Purpose", Form.TheSelectionForTheAppointmentOfTheCurrent);
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "ControlledLotReference", Form.ControlledLotReference);
		
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "MainPriceType", Form.MainPriceType);
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "TheTypeOfPricesIsIndividual", Form.TheTypeOfPricesIsIndividual);
		
		If Form.UseItemVariants Then
			
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "Products", Catalogs.Products.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "ProductSegment", Catalogs.ProductSegments.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "SegmentProducts", Catalogs.Products.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "UnitOfMeasure", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "ItemVariantsOwner", Catalogs.Products.EmptyRef());
			If Form.ToUseTermsOfSales
				And Not Form.SelectionModeWithoutAgreementsWithCustomers Then
				SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "Terms", Form.Terms);
			EndIf;
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "Currency", Form.Currency);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "BaseCurrency", BaseCurrency);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "Date", Form.Date);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "TypesOfPrices", TypesOfPricesParameter);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "MainPriceType", Form.MainPriceType);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "TheTypeOfPricesIsIndividual", Form.TheTypeOfPricesIsIndividual);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "ItemsType", Enums.ItemsTypes.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "ProductKind", Catalogs.ItemKinds.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "PriceGroup", Catalogs.PriceGroups.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "Purpose", Form.TheSelectionForTheAppointmentOfTheCurrent);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "ControlledLotReference", Form.ControlledLotReference);
			
		EndIf;
		
		If Not UserRightsCached.ThisIsPartner() Then
			
			SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "Warehouse", WarehouseParameter_);
			
			If Form.UseItemVariants Then
				SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "Warehouse", WarehouseParameter_);
			EndIf;
			
		EndIf;
				
	ElsIf ThisIsFormOfSelectionInPurchaseDocuments Then
				
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "Date", Form.Date);
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "Warehouse", WarehouseParameter_);
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "Currency", Form.Currency);
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "BaseCurrency", BaseCurrency);
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "Terms", Form.Terms);
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "VendorPriceKind", Form.VendorPriceKind);
		SelectGoodsClientServer.SetDynamicListParameter(ListProducts, "ProductSegment", Form.ProductSegment, ValueIsFilled(Form.ProductSegment));
		
		If Form.UseItemVariants Then
			
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "VendorPriceKind", Form.VendorPriceKind);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "ProductSegment", Form.ProductSegment);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "SegmentProducts", Catalogs.Products.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "Terms", Form.Terms);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "Currency", Form.Currency);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "BaseCurrency", BaseCurrency);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "Date", Form.Date);
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "Products", Catalogs.Products.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "UnitOfMeasure", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "ItemVariantsOwner", Catalogs.Products.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "ItemsType", Enums.ItemsTypes.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "ProductKind", Catalogs.ItemKinds.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "VATRate", Catalogs.VATRates.EmptyRef());
			SelectGoodsClientServer.SetDynamicListParameter(FeatureList, "Warehouse", WarehouseParameter_);
			
		EndIf;
		
		If Form.UsePartnersProducts Then
			
			SelectGoodsClientServer.SetDynamicListParameter(ListOfThePartnerSNomenclature, "VendorPriceKind", Form.VendorPriceKind);
			SelectGoodsClientServer.SetDynamicListParameter(ListOfThePartnerSNomenclature, "Terms", Form.Parameters.Terms);
			SelectGoodsClientServer.SetDynamicListParameter(ListOfThePartnerSNomenclature, "Currency", Form.Parameters.Currency);
			SelectGoodsClientServer.SetDynamicListParameter(ListOfThePartnerSNomenclature, "BaseCurrency", BaseCurrency);
			SelectGoodsClientServer.SetDynamicListParameter(ListOfThePartnerSNomenclature, "Date", Form.Parameters.Date);
			
		EndIf;

	EndIf;


#EndRegion
	
	FormSettingsWhenOpening = SelectionFormSettings(Form);
	StructureOfSavedFormSettings = New Structure("SavingIsRequired");
	For Each Setting In FormSettingsWhenOpening Do
		If Not TypeOf(Setting.Value) = Type("ValueTable") Then
			StructureOfSavedFormSettings.Insert(Setting.Key);
		EndIf;
	EndDo;
	Form.FormSettingsWhenOpening = StructureOfSavedFormSettings;
	
	SelectGoodsClientServer.SetCurPagesBySearchOption(Form);
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChangeListQueryTextForCurrentLanguage(Form, "ListProducts");
	NationalLanguageSupportServer.ChangeListQueryTextForCurrentLanguage(Form, "FeatureList");
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region VisibilityManagement

// Sets the visibility of columns associated with the display of available balances.
// Used in the selection form in the sales document.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetVisibilityOfAvailableMatchingBalancesInSalesDocument(Form) Export
	
	VisibilityOfResidues = Form.DisplayRemainingQuantityInWarehouses And Not ValueIsFilled(Form.TheSelectionForTheAppointmentOfTheCurrent);
	Form.Items.ListStandardSearchProductsAvailable.Visible = VisibilityOfResidues;
	Form.Items.ListAdvancedSearchProductsAvailable.Visible = VisibilityOfResidues;
	Form.Items.ListStandardSearchCharacteristicsAvailable.Visible = VisibilityOfResidues;
	Form.Items.ListAdvancedSearchCharacteristicsAvailable.Visible = VisibilityOfResidues;
	
EndProcedure

#EndRegion

#Region WorkingWithSelectionTreeBasedOnPropertiesOfProductType

// Invoked when the value changes in the tree selection view properties of the item.
// Ie client functions handle the processing of the values on the form element (set
// the values of the check boxes on the rows, the child rows, you open the form set the interval of values
// etc.), then control is transferred to the first server and disabled all the installed selections
// in the properties tree, and then turn on the selection only on values of rows with the checkboxes selected selection.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure FilterTreeFilterOnChange(Form) Export
	
	If Not Form.UseFilters Then
		Return;
	EndIf;
	
	DeleteSelectionBasedOnProductTypeProperties(Form);
	EstablishSelectionAccordingToPropertiesOfTypeOfProduct(Form);
	
EndProcedure

// Invoked when the value changes in the tree selection view properties of the item.
// Ie client functions handle the processing of the values on the form element (set
// the values of the check boxes on the rows, the child rows, you open the form set the interval of values
// etc.), then control is transferred to the first server and disabled all the installed selections
// in the properties tree, and then turn on the selection only on values of rows with the checkboxes selected selection.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure QualityListTaggingOnChange(Form) Export
	
	If Not Form.UseFilters Then
		Return;
	EndIf;
	
	DeleteProductQualitySelection(Form);
	EstablishSelectionOnQualityOfProducts(Form);
	
EndProcedure

// Invoked when the value changes in the tree selection view properties of the item.
// Ie client functions handle the processing of the values on the form element (set
// the values of the check boxes on the rows, the child rows, you open the form set the interval of values
// etc.), then control is transferred to the first server and disabled all the installed selections
// in the properties tree, and then turn on the selection only on values of rows with the checkboxes selected selection.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure ProductsOfOriginalQualityOnChange(Form) Export
	
	If Not Form.UseFilters Then
		Return;
	EndIf;
	
	SetQualityValueListItems(Form);
	EstablishSelectionByProductOfInitialQuality(Form);
	DeleteProductQualitySelection(Form);
	SetQualityGradationMark(Form);
	EstablishSelectionOnQualityOfProducts(Form);
	
EndProcedure

// Fills in the tree of feature selections based on the properties of the item type selected on the form.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure FillInFeatureSelectionTree(Form) Export
	
	FilterTree = Form.FormAttributeToValue("FilterTree");
	FilterTree.Rows.Clear();
	
	FillInTreeOfSelectionValues(Form, FilterTree, True);
	
	Form.ValueToFormAttribute(FilterTree, "FilterTree");
	
EndProcedure

#EndRegion

#Region InstallingAndRemovingSelections

// Sets the current page with a list of characteristics.
// Used in the standard scenario - when you select a line
// in the item list, and if the item is registered for characteristics,
// then you go to the list of characteristics.
//
// Used in selection forms (in sales and purchase documents).
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure GoToListOfCharacteristics(Form) Export
	
	// Clear the parameters of the new item so that when adding a new feature
	// , it is possible to understand for which item the feature is being added.
	Form.NewNomenclature = Undefined;
	
	WhenGoingToListOfCharacteristics(Form, Form.CurrentLineOfProducts)
	
EndProcedure

// Sets the selection by the owner of the characteristics. Used in the selection form of the "nomenclature Characteristics"reference list.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetSelectionByOwnerCharacteristics(Form) Export
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List, "Owner", Form.ItemVariantsOwner, 
		DataCompositionComparisonType.Equal, "SelectionBasedOnCharacteristics", True);
	
EndProcedure

// Called when you click the command button with the selected nomenclature, it is also sold from
// the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - selection form, sales assistant form.
//
Procedure WhenSettingSelectionForProductSoldJointly(Form) Export
		
	EstablishSelectionByProductSoldJointly(Form);
	
	If Form.CharacteristicNavigation Then
		GoToListOfProducts(Form);
	EndIf;
		
EndProcedure

// Sets the selection for the list of items sold together
// with the specified item.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure EstablishSelectionByProductSoldJointly(Form) Export
	
	Form.UseFilters = True;
	SelectGoodsClientServer.SetAvailabilityOfFilterElements(Form);
	
	If Form.NavigationOption <> Enums.ItemFormNavigationOptions.ByGoodsSoldTogether Then
		NavigationOptionBeforeChange = Form.NavigationOption;
	EndIf;
	Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsSoldTogether;
	
	DeleteSelectionByProductTypeAndProductTypeProperties(Form);
	SelectGoodsClientServer.DeleteSelectionByProductHierarchy(Form);
	SetNavigationOptionPage(Form, NavigationOptionBeforeChange);
	
	// Set a filter by the item sold jointly.
	Form.TableItemSoldTogetherPremise.Clear();
	
	junk = Form.Object.junk;
	
	Filter = New Structure("Products, Characteristic");
	
	For Each RowOfBasketTable In junk Do
		
		If RowOfBasketTable.IndexGoodsSoldTogether = 1 Then
			
			FillPropertyValues(Filter, RowOfBasketTable);
			RowsArray = Form.TableItemSoldTogetherPremise.FindRows(Filter);
			
			If RowsArray.Count() = 0 Then
				NewRow = Form.TableItemSoldTogetherPremise.Add();
				FillPropertyValues(NewRow, RowOfBasketTable);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Goods = ProductsSoldTogether.GetDataOnProductsSoldJointly(
			junk.Unload(,"Products, Characteristic"), 
			Form.AnalysisOptionOfProductsSoldTogether);
	
	Form.TableItemSoldJointly.Load(Goods);
	
	JointlySoldGoods = Goods.UnloadColumn("Products");
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.ListProducts, "Products", JointlySoldGoods, 
		DataCompositionComparisonType.InList, "ByProductSoldJointly", True);
	
EndProcedure

// Sets the selection by the owner of the characteristics. Used
// in the selection form of the "nomenclature Characteristics"reference list.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure EstablishSelectionByProductOfInitialQuality(Form) Export
	
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	AnotherQualityGoods.OtherQualityGoods
	|FROM
	|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|WHERE
	|	AnotherQualityGoods.Products = &Products";
	
	Query.SetParameter("Products", Form.ProductsOfOriginalQuality);
	Table = Query.Execute().Unload();
	
	GroupSelectionForGoodsOfInitialQuality = CommonClientServer.CreateFilterItemGroup(
		TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts).Items,
		"GroupSelectionForGoodsOfInitialQuality",
		DataCompositionFilterItemsGroupType.AndGroup);
	
	ArrayOfProducts_2 = Table.UnloadColumn("OtherQualityGoods");
	
	CommonClientServer.SetFilterItem(GroupSelectionForGoodsOfInitialQuality, "Ref", ArrayOfProducts_2, 
		DataCompositionComparisonType.InList, "GroupSelectionForGoodsOfInitialQuality", True);
	
EndProcedure

// Sets the selection by the owner of the characteristics. Used
// in the selection form of the "nomenclature Characteristics"reference list.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure EstablishSelectionOnQualityOfProducts(Form) Export
	
	QualityArray = New Array;
	
	For Each ListItem In Form.ListQualities Do
		If ListItem.Check Then
			QualityArray.Add(ListItem.Value);
		EndIf;
	EndDo;
	
	If QualityArray.Count() > 0 Then
		CommonClientServer.SetDynamicListFilterItem(
			Form.ListProducts, "Quality", QualityArray, DataCompositionComparisonType.InList);
	EndIf;
	
EndProcedure

// Adds a selection to the specified selection area collection.
//
// Parameters:
//	SelectionArea - DataCompositionFilter - selecting a dynamic list,
//	LeftValue - String - path to the selection field data,
//	RightValue - Arbitrary - the value of the selection,
//	TypeOfFilter - DataCompositionComparisonType - type of comparison,
//	Presentation - String - representation of the selection element.
//
Procedure AddFilterItem(SelectionArea, LeftValue, RightValue, TypeOfFilter, Presentation = "") Export
	
	FilterElement                   = SelectionArea.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue     = New DataCompositionField(LeftValue);
	FilterElement.RightValue    = RightValue;
	FilterElement.ViewMode  = DataCompositionSettingsItemViewMode.Inaccessible;
	FilterElement.ComparisonType      = TypeOfFilter;
	
	If ValueIsFilled(Presentation) Then
		FilterElement.Presentation = Presentation;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForElementsOnSelectionForms

// Called from the selection forms when the use filters checkbox is changed.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure WhenChangingUseOfFilters(Form) Export
	
	If SelectGoodsClientServer.ThisIsFormOfFeatureSelection(Form.FormCode) Then
		
		DeleteSelectionBasedOnProductTypeProperties(Form);
		
		If Form.UseFilters Then
			EstablishSelectionAccordingToPropertiesOfTypeOfProduct(Form);
		EndIf;
		
	Else
		
		If (Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties
			Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties
			Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds) Then
			
			Form.ProductsKindBeforeChange = Undefined;
			
			If Form.UseFilters Then
				EstablishSelectionByTypeOfProductAndPropertiesOfTypeOfProduct(Form);
			Else
				DeleteSelectionByProductTypeAndProductTypeProperties(Form);
			EndIf;
			
			WhenChangingTypeOfProductItem(Form);
			
		Else
			
			If Form.UseFilters Then
				
				If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByHierarchy Then
					
					SetCurRowOfProductHierarchy(Form);
					SelectGoodsClientServer.SetSelectionByProductHierarchy(Form);
					
				ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsSoldTogether Then
					
					EstablishSelectionByProductSoldJointly(Form);
					
				ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsOfAnotherQuality Then
					
					EstablishSelectionByProductOfInitialQuality(Form);
					EstablishSelectionOnQualityOfProducts(Form);
					
				EndIf;
				
			Else
				
				SelectGoodsClientServer.DeleteSelectionByProductHierarchy(Form);
				DeleteSelectionByProductTypeAndProductTypeProperties(Form);
				
				If Not SelectGoodsClientServer.ThisIsFormOfProductSelection(Form.FormCode)
					Or Not Form.SelectGoodsOfOtherQuality Then
					DeleteProductQualitySelection(Form);
				EndIf;
				
				RemoveSelectionBySourceQualityProduct(Form);
				
				If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsSoldTogether Then
					CommonClientServer.DeleteDynamicListFilterGroupItems(
					Form.ListProducts,,"ByProductSoldJointly");
				EndIf;
				
			EndIf;
			
			GoToListOfProducts(Form);
		EndIf;
		
	EndIf;
	
	SelectGoodsClientServer.SetAvailabilityOfFilterElements(Form);
	
EndProcedure

// Called from the selection forms when the navigation option is changed.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure WhenChangingNavigationOption(Form) Export
	
	SetNavigationOptionPage(Form);
	SelectGoodsClientServer.DeleteSelectionByProductHierarchy(Form);
	DeleteSelectionByProductTypeAndProductTypeProperties(Form);
	RemoveSelectionBySourceQualityProduct(Form);
	DeleteProductQualitySelection(Form);
	
	If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByHierarchy Then
		
		SelectGoodsClientServer.SetSelectionByProductHierarchy(Form);
		
	ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties 
			Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds
			Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties Then
		
		EstablishSelectionByTypeOfProductAndPropertiesOfTypeOfProduct(Form);
		
	ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsSoldTogether Then
		
		EstablishSelectionByProductSoldJointly(Form);
		
	ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsOfAnotherQuality Then
		
		EstablishSelectionByProductOfInitialQuality(Form);
		EstablishSelectionOnQualityOfProducts(Form);
		
	EndIf;
	
EndProcedure

// Called from a form of selection when changing the type of the item.
//
// Parameters:
//	Form - ClientApplicationForm - selection form, list form, selection form.
//
Procedure WhenChangingTypeOfProductItem(Form) Export
	
	If Form.ProductKind = Form.ProductsKindBeforeChange Then
		Return;
	EndIf;
	
	ThisIsFormOfMatching = SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode);
	ThisIsProductListForm = SelectGoodsClientServer.ThisIsProductListForm(Form.FormCode);
	ThisIsFormOfProductSelection = SelectGoodsClientServer.ThisIsFormOfProductSelection(Form.FormCode);
	
	Form.ProductsKindBeforeChange = Form.ProductKind;
	
	DeleteSelectionByProductTypeAndProductTypeProperties(Form);
	
	If Not ValueIsFilled(Form.ProductKind)
		Or Not Form.UseFilters Then
		
		ClearSelectionTree(Form);
		If Form.UseFilters Then
			SetSelectionByTypeOfProduct(Form);
		EndIf;
		
	Else
		
		If ThisIsFormOfMatching
			Or	ThisIsProductListForm
			Or ThisIsFormOfProductSelection Then
			
			FillInProductSelectionTree(Form);
			
		Else
			
			FillInProductSelectionTree(Form);
			
		EndIf;
		
		EstablishSelectionByTypeOfProductAndPropertiesOfTypeOfProduct(Form);
		
	EndIf;
	
EndProcedure

// Adds a row to the parameter table selection is used when the navigation option
// the products of "alternative" quality.
//
// Parameters:
//	Form - ClientApplicationForm - selection form, list form, selection form
//
Procedure SetSelectionTreeParametersQualityNew(Form) Export
	
	RowOfSelectionParametersTable = Form.FilterParametersTable.Add();
	
	RowOfSelectionParametersTable.AttributeName = "Quality";
	RowOfSelectionParametersTable.FilterValue = Enums.QualityLevels.New;
	RowOfSelectionParametersTable.Presentation = "New";
	RowOfSelectionParametersTable.FixedValue = False;
	RowOfSelectionParametersTable.Filter = True;
	
EndProcedure

// Called from the selection forms when the item segment value changes.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure WhenChangingSupplierSPriceType(Form) Export
	
	If Not SupplierPriceViewChanged(Form) Then
		Return;
	EndIf;
	
	SelectGoodsClientServer.SetSelectionBySupplierType(Form);
	SelectGoodsClientServer.SetSelectionBySupplierPriceRange(Form);
	
EndProcedure

// To clear the check boxes for item properties in the context menu of the item list in the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure ResetFiltersByProperties(Form) Export
	
	For Each FilterFirstLevel In Form.FilterTree.GetItems() Do
		
		If FilterFirstLevel.Filter Then
			
			FilterFirstLevel.Filter = False;
			
			For Each SecondLevelSelection In FilterFirstLevel.GetItems() Do
				SecondLevelSelection.Filter = False;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Form.FilterParametersTable.Clear();	
	
	SetNeedToSaveSettings(Form);
	
	DeleteSelectionBasedOnProductTypeProperties(Form);
	
EndProcedure

// Called when executing the command to display products of a different quality
// in the context menu of the item list in the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - item list form or selection form
//
Procedure EstablishSelectionForProductsOfDifferentQuality(Form) Export
	
	NameOfProductList = SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form);
	
	ProductFormTable = Form.Items[NameOfProductList]; // FormTable
	RowOfProductTable = ProductFormTable.CurrentRow;
	If RowOfProductTable = Undefined Then
		Return;
	EndIf;
	
	Form.UseFilters = True;
	SelectGoodsClientServer.SetAvailabilityOfFilterElements(Form);
	
	NavigationOptionBeforeChange = Form.NavigationOption;

	Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsOfAnotherQuality;
	Form.ProductsOfOriginalQuality = RowOfProductTable.Ref;

	SetNavigationOptionPage(Form, NavigationOptionBeforeChange);
	SelectGoodsClientServer.DeleteSelectionByProductHierarchy(Form);
	DeleteSelectionByProductTypeAndProductTypeProperties(Form);
	RemoveSelectionBySourceQualityProduct(Form);
	ProductsOfOriginalQualityOnChange(Form);
	GoToListOfProducts(Form);
	
EndProcedure

// Called from the selection forms when the item segment value changes.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure WhenProductItemSegmentChanges(Form) Export
	
	If Not ProductSegmentChanged(Form) Then
		Return;
	EndIf;
	
	SetSelectionByProductSegment(Form);
	SelectGoodsClientServer.SetSelectionByPriceRange(Form);
	
EndProcedure

// Called when executing the command to display products with similar properties
// in the context menu of the item list in the selection forms.
//
// Parameters:
//	Form - See WhenCreatingMatchingFormOnServer.Form
//
Procedure WhenChangingDisplayOfItemWithSimilarProperties(Form) Export
	
	ProductFormTable = Form.Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form)]; // FormTable
	
	CurrentRow = ProductFormTable.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FilterBySimilarProperties(Form, CurrentRow.Ref);
	
	If SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode) Then
		GoToListOfProducts(Form);
		
		Form.Items.ItemKinds.CurrentRow = Form.ProductKind;
	EndIf;
	
EndProcedure

#EndRegion

#Region SelectionsBasedOnAvailabilityAndPrices

// Sets the "available only" selection to the list of items
// and characteristics in the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetFilterOnlyInStock(Form) Export
	
	// For the list of items.
	FilterGroupOnlyInStockProducts = CommonClientServer.CreateFilterItemGroup(
		TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts).Items,
		"GroupOnlyInStock", DataCompositionFilterItemsGroupType.OrGroup);
	
	CommonClientServer.SetFilterItem(
		FilterGroupOnlyInStockProducts,
		"AvailableInBasicUnits", 0, DataCompositionComparisonType.Greater,,Form.OnlyInStock);
		
	// For a list of characteristics.
	FilterGroupOnlyInStockCharacteristics = CommonClientServer.CreateFilterItemGroup(
		TMCommonUseClientServer.GetDynamicListSelection(Form.FeatureList).Items,
		"GroupOnlyInStock", DataCompositionFilterItemsGroupType.OrGroup);
	
	CommonClientServer.SetFilterItem(
		FilterGroupOnlyInStockCharacteristics,
		"AvailableInBasicUnits", 0, DataCompositionComparisonType.Greater,,Form.OnlyInStock);
	
	SetActiveListOnForm(Form);
	
EndProcedure

#EndRegion

#Region AuxiliarySelections

// Returns an array of properties for which selection is set when displaying
//  a list of products with similar properties in the selection forms.
//
// Parameters:
//  Products - CatalogRef.Products - the item for which an array of properties is generated.
// 
// Returns:
//  Array - An array of properties and values of the properties of the item item for which you will need
//  to select the goods.
//
Function PropertiesForSelectingProductsWithSimilarProperties(Products) Export
	
	AdditionalAttributes = New Array;
	Properties = New Array;
	
	// Get the names and values of the details that are used for selection.
	Query = New Query(
	"SELECT
	|	AttributesOfQuickFilterOfProducts.AttributeName   AS AttributeName,
	|	AttributesOfQuickFilterOfProducts.Property       AS Property,
	|	AttributesOfQuickFilterOfProducts.IsAddlAttribute AS IsAddlAttribute
	|FROM
	|	Catalog.ItemKinds.AttributesOfQuickFilterOfProducts AS AttributesOfQuickFilterOfProducts
	|WHERE
	|	AttributesOfQuickFilterOfProducts.Ref = &ProductKind");
	
	Query.SetParameter("ProductKind", Common.ObjectAttributeValue(Products, "ProductKind"));
	
	FieldsCount = 0;
	
	QueryText = "SELECT *";
	QueryText = Left(QueryText, 7);
	
	AttributesOfQuickFilterOfProducts = Query.Execute().Unload();
	
	For Each TSRow In AttributesOfQuickFilterOfProducts Do
		
		If TSRow.IsAddlAttribute Then
			AdditionalAttributes.Add(TSRow.Property);
		Else
			
			FieldsCount = FieldsCount + 1;
			
			If FieldsCount = 1 Then
				QueryText = QueryText + " " + "T." + TSRow.AttributeName + " " + "AS " + TSRow.AttributeName;
			Else
				QueryText = QueryText + ", " + "T." + TSRow.AttributeName + " " + "AS " + TSRow.AttributeName;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If FieldsCount > 0 Then
		
		QueryText = QueryText +" " + "FROM Catalog.Products AS T WHERE T.Ref = &Products";
		
		Query = New Query(
		QueryText +
		";
		|SELECT
		|	ProductsAdditionalDetails.Property           AS Property,
		|	ProductsAdditionalDetails.Value           AS Value,
		|	ProductsAdditionalDetails.Property.Title AS Presentation
		|FROM
		|	Catalog.Products.AdditionalAttributes AS ProductsAdditionalDetails
		|WHERE
		|	ProductsAdditionalDetails.Ref = &Products
		|	AND ProductsAdditionalDetails.Property IN (&AdditionalAttributes)");
		
		Query.SetParameter("Products",            Products);
		Query.SetParameter("AdditionalAttributes", AdditionalAttributes);
		
		ResultsArray = Query.ExecuteBatch();
		Result = ResultsArray[0]; // QueryResult
		
		Selection = Result.Select(); // bypassing item Attributes
		
		While Selection.Next() Do
			
			For Each Column In Result.Columns Do
				
				NewRow = New Structure("AttributeName, Value, Presentation");
				
				NewRow.AttributeName = Column.Name;
				NewRow.Value     = Selection[Column.Name];
				
				Attribute = Metadata.Catalogs.Products.Attributes.Find(Column.Name);
				
				NewRow.Presentation = Attribute.Synonym;
				
				Properties.Add(NewRow); // the name and value of the item item details are added to the output array
				
			EndDo;
			
		EndDo;
		
		Result = ResultsArray[1]; // QueryResult
		Selection = Result.Select(); // bypassing additional item Attributes
		
		While Selection.Next() Do
			
			NewRow = New Structure("Property, Value, Presentation");
			
			FillPropertyValues(NewRow, Selection);
			
			If Not ValueIsFilled(Selection.Presentation) Then
				NewRow.Presentation = String(Selection.Property);
			EndIf;
			
			Properties.Add(NewRow); // the name and value of the additional are added to the output array.the details of the type of nomenclature
			
		EndDo;
		
	Else
		
		// In the event that the details of the item type are not included in the quick selection panel,
		// then only the values of the additional are added to the output array.the details of the type of nomenclature.
		
		Query = New Query(
		"SELECT
		|	ProductsAdditionalDetails.Property           AS Property,
		|	ProductsAdditionalDetails.Value           AS Value,
		|	ProductsAdditionalDetails.Property.Title AS Presentation
		|FROM
		|	Catalog.Products.AdditionalAttributes AS ProductsAdditionalDetails
		|WHERE
		|	ProductsAdditionalDetails.Ref = &Products
		|	AND ProductsAdditionalDetails.Property IN (&AdditionalAttributes)");
		
		Query.SetParameter("Products",            Products);
		Query.SetParameter("AdditionalAttributes", AdditionalAttributes);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		While Selection.Next() Do
			
			NewRow = New Structure("Property, Value, Presentation");
			FillPropertyValues(NewRow, Selection);
			
			If Not ValueIsFilled(Selection.Presentation) Then
				NewRow.Presentation = String(Selection.Property);
			EndIf;
			
			Properties.Add(NewRow);
			
		EndDo;
		
	EndIf;
	
	Return Properties;
	
EndFunction

// Sets the selection for the list of items based on similar properties of the item type of the transferred product.
//
// Parameters:
//	Form - ClientApplicationForm - item list form or selection form,
//	Products - CatalogRef.Products - a product whose property values should be used to select the item list.
//
Procedure FilterBySimilarProperties(Form, Products) Export
	
	// Enable the use of filters.
	Form.UseFilters = True;
	SelectGoodsClientServer.SetAvailabilityOfFilterElements(Form);
	
	// Set the navigation option - "by properties".
	If Not (Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds) Then
		Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties;
	EndIf;
	
	SetNavigationOptionPage(Form);
	
	// Set the type of nomenclature and fill in the selection tree.
	ProductAttributes = Common.ObjectAttributesValues(Products, "Description, ProductKind");
	Form.ProductKind = ProductAttributes.ProductKind;
	Form.ProductsKindBeforeChange = ProductAttributes.ProductKind;
	
	DeleteSelectionByProductTypeAndProductTypeProperties(Form);
	
	FillInProductSelectionTree(Form);
	
	// Get a list of properties and values of the item type of the current product..
	PropertiesForSelectingProductsWithSimilarProperties = PropertiesForSelectingProductsWithSimilarProperties(Products);
	
	FilterParametersTable = Form.FilterParametersTable.Unload();
	FilterParametersTable.Clear();
	
	If PropertiesForSelectingProductsWithSimilarProperties.Count() = 0 Then
		
		MessageText = NStr("vi = 'Mặt hàng ""%1"" chưa chỉ định giá trị mục tin để lọc nhanh trong danh sách. Đã hủy lọc.';
							|ru = 'У номенклатуры ""%1"" не указаны значения реквизитов для быстрого отбора в списках. Установка фильтра отменена.';
							|en = 'Attribute values for quick filter in lists are not specified for the ""%1"" item. The filter is cleared.'; fa = 'Attribute values for quick filter in lists are not specified for the ""%1"" item. The filter is cleared.';
							|it = 'У номенклатуры ""%1"" не указаны значения реквизитов для быстрого отбора в списках. Установка фильтра отменена.';
							|pl = 'Attribute values for quick filter in lists are not specified for the ""%1"" item. The filter is cleared.';
							|tr = '""%1"" öğesinin listelerde hızlı filtre için öznitelik değerleri belirtilmedi. Filtre ayarı iptal edildi.'");
		Common.MessageToUser(StrTemplate(MessageText, ProductAttributes.Description));
		
	Else
		
		FilterTree = Form.FormAttributeToValue("FilterTree");
		
		// Go through the resulting list of properties, put down the usage flags.
		For Each AdditionalProperty In PropertiesForSelectingProductsWithSimilarProperties Do
			
			For Each Property In FilterTree.Rows Do
				
				If Not (AdditionalProperty.Presentation = Property.Presentation) Then
					Continue;
				EndIf;
				
				// Enable the use of the property in the selection if the value of the selection tree is similar 
				// to the value of the list of properties of the current item type.
				If Property.FilterValue = AdditionalProperty.Value Then
					Property.Filter = True;
					NewRow = FilterParametersTable.Add();
					FillPropertyValues(NewRow, Property);
				Else
					
					If Property.Rows.Count() > 0 Then
						
						For Each PropertyValue In Property.Rows Do
							
							PropertyValue.Filter = (PropertyValue.FilterValue = AdditionalProperty.Value);
							
							If PropertyValue.Filter Then
								Property.Filter = True;
								
								NewRow = FilterParametersTable.Add();
								FillPropertyValues(NewRow, PropertyValue);
							EndIf;
							
						EndDo;
						
					Else
						
						If TypeOf(Property.FilterValue) = Type("ValueList") Then
							Property.FilterValue.Clear();
							Property.FilterValue.Add(AdditionalProperty.Value);
						Else
							Property.FilterValue = AdditionalProperty.Value;
						EndIf;
						
						Property.Filter = True;
						Property.FilterPresentation = String(Property.FilterValue);
						
						NewRow = FilterParametersTable.Add();
						FillPropertyValues(NewRow, Property);
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		Form.ValueToFormAttribute(FilterTree, "FilterTree");
		
	EndIf;
	
	Form.FilterParametersTable.Load(FilterParametersTable);
	
	SetNeedToSaveSettings(Form);
	
	// The checkboxes are placed, now apply selections to the list of items.
	EstablishSelectionByTypeOfProductAndPropertiesOfTypeOfProduct(Form);
	
EndProcedure

#EndRegion

#Region SearchOnSelectionForms

// Searches for an item in the search bar.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form, selection form.
//
// Returns:
//	Boolean - True - the search was successful, the elements were found, False - the search failed.
//
Function SearchForProducts(Form) Export
	
	SearchCompleted_ = ExecuteSearch(Form, "Products");
	Return SearchCompleted_;
	
EndFunction

// Searches for characteristics in the search bar.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
// Returns:
//	Boolean - True - the search was successful, the elements were found, False - the search failed.
//
Function SearchForCharacteristics(Form) Export
	
	SearchCompleted_ = ExecuteSearch(Form, "ItemsCharacteristics");
	Return SearchCompleted_;
	
EndFunction

// Searches for the partner item in the search bar.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form, selection form.
//
// Returns:
//	Boolean - True - the search was successful, the elements were found, False - the search failed.
//
Function SearchForPartnerProducts(Form) Export
	
	SearchCompleted_ = ExecuteSearch(Form, "ProductCrossReferences");
	Return SearchCompleted_;
	
EndFunction

Function ExecuteSearch(Form, SearchListName)
	
	SearchParameters = New Structure;
	SearchParameters.Insert("ExactCompliance");
	SearchParameters.Insert("SearchString");
	SearchParameters.Insert("SearchAreas");
	SearchParameters.Insert("PropsNameSearchFailed");
	SearchParameters.Insert("PropsNameList");
	SearchParameters.Insert("SearchListName", SearchListName);
	
	If SearchListName = "Products" Then
		
		SearchParameters.ExactCompliance = Form.FindAnItemByExactMatch;
		
		SearchParameters.SearchString = FormatSearchString(
			Form.SearchStringProducts,
			Form.UseFullTextSearch,
			SearchParameters.ExactCompliance);
			
		SearchParameters.PropsNameSearchFailed = "ProductsSearchReturnedNoResults";
		SearchParameters.PropsNameList = "ListProducts";
		
		If Form.UseFilters Then
			AdditionalConditions   = New Array;
			AdditionalParameters = New Map;
			
			If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties
				Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties
				Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds Then
				AdditionalConditions.Add("(CatalogProducts.ProductKind = &FilterByTheProductKind)");
				AdditionalParameters.Insert("FilterByTheProductKind", Form.ProductKind);
				
			ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByHierarchy Then
				AdditionalConditions.Add("(CatalogProducts.Parent = &SelectionByProductHierarchy)");
				AdditionalParameters.Insert("SelectionByProductHierarchy", Form.CurrentProductsHierarchy);
				
			ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsSoldTogether Then
				Goods = ProductsSoldTogether.GetDataOnProductsSoldJointly(
							Form.Object.junk.Unload(,"Products, Characteristic"), 
							Form.AnalysisOptionOfProductsSoldTogether);

				AdditionalConditions.Add("(CatalogProducts.Ref IN (&FilterByProductSoldJointly))");
				AdditionalParameters.Insert("FilterByProductSoldJointly", Goods.UnloadColumn("Products"));
				
			ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsOfAnotherQuality Then
				Query = New Query;	
				Query.Text = "SELECT
							   |	AnotherQualityGoods.OtherQualityGoods
							   |FROM
							   |	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
							   |WHERE
							   |	AnotherQualityGoods.Products = &Products";
				
				Query.SetParameter("Products", Form.ProductsOfOriginalQuality);
				Table = Query.Execute().Unload();

				AdditionalConditions.Add("(CatalogProducts.Ref IN (&FilterByGoodsOfAnotherQuality))");
				AdditionalParameters.Insert("FilterByGoodsOfAnotherQuality", Table.UnloadColumn("OtherQualityGoods"));
				
				QualityArray = New Array;					
				For Each ListItem In Form.ListQualities Do
					If ListItem.Check Then
						QualityArray.Add(ListItem.Value);
					EndIf;
				EndDo;
				
				If QualityArray.Count() > 0 Then
					AdditionalConditions.Add("(CatalogProducts.Quality IN (&SelectionOfGoodsOfOriginalQuality))");
					AdditionalParameters.Insert("SelectionOfGoodsOfOriginalQuality", QualityArray);
				EndIf;
			EndIf;
			
			If ValueIsFilled(Form.ProductSegment) Then
				AdditionalConditions.Add("(CatalogProducts.Ref IN
											   |	(SELECT
											   |		Segments.Products
											   |	FROM
											   |		InformationRegister.SegmentProducts AS Segments
											   |	WHERE
											   |		Segments.Segment = &SelectionByProductSegment))");
				AdditionalParameters.Insert("SelectionByProductSegment", Form.ProductSegment);
			EndIf;
			
			If AdditionalConditions.Count() > 0 Then
				SearchParameters.Insert("AdditionalConditions",   AdditionalConditions);
				SearchParameters.Insert("AdditionalParameters", AdditionalParameters);
			EndIf;
		EndIf;
		
	ElsIf SearchListName = "ItemsCharacteristics" Then
		
		SearchParameters.ExactCompliance = Form.FindCharacteristicsByExactMatch;
		
		SearchParameters.SearchString = FormatSearchString(
			Form.SearchBarCharacteristics,
			Form.UseFullTextSearch,
			SearchParameters.ExactCompliance);
		
		SearchParameters.PropsNameSearchFailed = "FailedToFindCharacteristics";
		SearchParameters.PropsNameList = "FeatureList";
		
	ElsIf SearchListName = "ProductCrossReferences" Then	
		
		SearchParameters.ExactCompliance = Form.FindThePartnerSItemByExactMatch;
		SearchParameters.SearchString = FormatSearchString(
			Form.SearchBarPartnerItem,
			Form.UseFullTextSearch,
			SearchParameters.ExactCompliance);
		
		SearchParameters.PropsNameSearchFailed = "TheSearchForThePartnerSNomenclatureIsNotSuccessful";
		SearchParameters.PropsNameList = "ListOfThePartnerSNomenclature";
		
	Else
		
		ExceptionText = NStr("vi = 'Giá trị tham số không xác định %1';
							|ru = 'Неизвестное значение параметра %1';
							|en = 'Unknown value of the %1 parameter'; fa = 'Unknown value of the %1 parameter';
							|it = 'Valore sconosciuto del parametro %1';
							|pl = 'Nieznana wartość parametru %1';
							|tr = '%1 parametresi için bilinmeyen değer'");
		ExceptionText = StrTemplate(ExceptionText, "SearchListName");
		
		Raise ExceptionText;
		
	EndIf;
	
	SearchParameters.SearchAreas = DescriptionsOfSearchAreas(Form, SearchParameters);
	
	SearchCompleted_ = False;
	
	Form[SearchParameters.PropsNameSearchFailed] = False;
	Form.SearchErrorCode = "";
	
	If ValueIsFilled(SearchParameters.SearchString) Then
		
		If Not Form.UseFullTextSearch 
			Or SearchParameters.ExactCompliance Then
			SearchResult = IncompleteTextSearchResult(Form, SearchParameters);
		Else
			SearchResult = FullTextSearchResult(Form, SearchParameters);
		EndIf;
		
		If SearchParameters.SearchListName = "Products" Then 
			AddProductSearchResults(SearchResult);
		EndIf;
		
		SearchCompleted_ = True;
	Else
		SearchResult = SearchResults(SearchParameters.SearchAreas);
	EndIf;
	
	Form[SearchParameters.PropsNameSearchFailed] = (SearchCompleted_ And ValueIsFilled(SearchResult.ErrorCode));
	Form.SearchErrorCode = SearchResult.ErrorCode;
	If SearchCompleted_ Then
		
		SelectGoodsClientServer.SetListSelectionBySearchBar(
			TMCommonUseClientServer.GetDynamicListSelection(Form[SearchParameters.PropsNameList]).Items,
			SearchResult[SearchListName], 
			True);
		
	Else
		
		SelectGoodsClientServer.SetListSelectionBySearchBar(
			TMCommonUseClientServer.GetDynamicListSelection(Form[SearchParameters.PropsNameList]).Items,
			New ValueList,
			False);
		
	EndIf;
	
	If SearchParameters.SearchListName = "Products" Then
		Form.ThereIsAFilterForProductsSearch = SearchCompleted_;
		If Not SelectGoodsClientServer.ThisIsFormForSelectingProductsByCategory(Form.FormCode) Then
			SelectGoodsClientServer.SetSelectionByPriceRange(Form);
		EndIf;
	EndIf;
	
	Return SearchCompleted_;
	
EndFunction

// Returns a description of the search area.
// 
// Returns:
//
// 	Structure:
// 		* MetadataObject - Undefined
// 		* AreaSearchRequestText - String
// 		* TextOfProductSearchQuery - String
// 		* AreaSearchRequestParameters - Map of String
//
Function SearchAreaDescription() Export
	
	SearchAreaDescription = New Structure;
	SearchAreaDescription.Insert("MetadataObject", Undefined);
	SearchAreaDescription.Insert("AreaSearchRequestText", "");
	SearchAreaDescription.Insert("TextOfProductSearchQuery", "");
	SearchAreaDescription.Insert("AreaSearchRequestParameters", New Map);

	Return SearchAreaDescription;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsForSavingAndRestoringSettings

// Saves the values of the details on the form in the General settings storage.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form.
//
Procedure SaveFormSettings(Form) Export
	
	FormSettings = FormSettings(Form);
	Common.CommonSettingsStorageSave(Form.FormCode, "", FormSettings);
	Common.CommonSettingsStorageSave("GoodsSearchOption", "", Form.GoodsSearchOption);
	SaveSelectionLists(Form);
	
EndProcedure

// Saves the values of the details on the selection form in the General settings store.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SaveSelectionFormSettings(Form) Export
	
	SelectionFormSettings = SelectionFormSettings(Form);
	Common.CommonSettingsStorageSave(Form.FormCode, "", SelectionFormSettings);
	Common.CommonSettingsStorageSave("GoodsSearchOption", "", Form.GoodsSearchOption);
	
EndProcedure

#EndRegion

#Region HandlingAlertsFromHelpersForAddingNewProducts
// and a new feature.

// Called when processing a new item creation alert
// from the add new item assistant.
//
// Parameters:
//	Form - ClientApplicationForm - selection form,
//	Products - CatalogRef.Products - event source.
//
Procedure WhenWritingNewProductItem(Form, Products) Export
	
	If Not ValueIsFilled(Products) Then
		Return;
	EndIf;
	
	ProductFormTable = Form.Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form)]; // FormTable
	ProductFormTable.CurrentRow = Products;
	
	FillInParametersOfNewProductItem(Form, Products);
	
	MatchesSelectionByProductType = NewProductCorrespondsToSelectionByTypeOfProduct(Form);
	
	If Form.UseItemVariants 
		And Form.NewNomenclature.ItemVariantsAreUsed Then
		
		If MatchesSelectionByProductType Then
			GoToListOfCharacteristicsOfNewProduct(Form);
		EndIf;
		
	Else
		
		Form.GoodsForAddingToTheCart = SelectGoodsClientServer.ProductParameters_1();
		
		FillPropertyValues(Form.GoodsForAddingToTheCart, Form.NewNomenclature);
		FillInStockOfProductToAddToCart(Form);
		
		Form.GoodsForAddingToTheCart.NumberOfPackages = 1;
		
		If Not MatchesSelectionByProductType Then
			Form.GoodsForAddingToTheCart = Undefined;
		EndIf;
		
	EndIf;
	
EndProcedure

// Called when processing a new feature creation alert
// from the add new feature wizard.
//
// Parameters:
//	Form - ClientApplicationForm - selection form,
//	Characteristic - CatalogRef.ItemsCharacteristics - event source.
//
Procedure WhenRecordingNewCharacteristic(Form, Characteristic) Export
	
	If Not ValueIsFilled(Characteristic) Then
		Return;
	EndIf;
	
	ShapeTableCharacteristic = Form.Items[SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(Form)]; // FormTable
	ShapeTableCharacteristic.CurrentRow = Characteristic;
	
	FillInParametersOfNewCharacteristic(Form, Characteristic);
	
	Form.GoodsForAddingToTheCart = SelectGoodsClientServer.ProductParameters_1();
	
	FillPropertyValues(Form.GoodsForAddingToTheCart, Form.NewCharacteristic);
	FillInProductPropertiesToAddToCartByProductType(Form.GoodsForAddingToTheCart, Form.NewCharacteristic.ItemsType);
	FillInStockOfProductToAddToCart(Form);
	
	Form.GoodsForAddingToTheCart.NumberOfPackages = 1;
	
	// Check if the new product does not match the selection by item type, then do not add it to the cart.
	If Not NewProductCorrespondsToSelectionByTypeOfProduct(Form) Then
		Form.GoodsForAddingToTheCart = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region GeneralPurposeProceduresAndFunctions

// Attempts to load settings from a shared configuration storage
// for the key name of the object. If there are settings in the shared storage, it means that the form
// has already been opened. if not, it means that this is the first opening of the form.
//
// Parameters:
//	ObjectKey - String - key of the form settings object.
//
// Returns:
//	Boolean - Truth is a sign of the first discovery of the form.
//
Function FirstOpeningOfForm(ObjectKey) Export
	
	FormSettings = Common.CommonSettingsStorageLoad(ObjectKey, "");
	
	If FormSettings = Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Returns the structure of parameters for creating a new item from selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
// Returns:
//	Structure - parameters for creating a new item from the selection forms:
//		* Parent					- CatalogRef.Products		- parent of the new item;
//		* ProductKind			- CatalogRef.ItemKinds	- item type of the new item;
//		* AddressOfParameterTable	- String							- address of the parameter table in temporary storage;
//		* AddressOfMappingTable	- String							- address of the mapping table in temporary storage.
//
Function ParametersForCreatingNewProductItem(Form) Export
	
	ParametersForCreatingForm = New Structure("Parent, ProductKind, AddressOfParameterTable, AddressOfMappingTable");
	
	If Form.UseFilters Then
		
		If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByHierarchy Then
			
			ParametersForCreatingForm.Parent = ?(ValueIsFilled(Form.CurrentProductsHierarchy), Form.CurrentProductsHierarchy, Catalogs.Products.EmptyRef());
			
		ElsIf (Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties
					Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties)Then
			
			If ValueIsFilled(Form.ProductKind) Then
				ParametersForCreatingForm.ProductKind = Form.ProductKind;
				ParametersForCreatingForm.AddressOfParameterTable = AddressOfSelectionTreeParameterTable(Form);
				ParametersForCreatingForm.AddressOfMappingTable = AddressOfSelectionTreeMappingTable(Form)
			EndIf;
			
		ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds Then
			If ValueIsFilled(Form.ProductKind) Then
				ParametersForCreatingForm.ProductKind = Form.ProductKind;
			EndIf;
		EndIf;
		
	EndIf;
	
	Return ParametersForCreatingForm;
	
EndFunction

// Returns the parameter structure for creating a new characteristic from the selection forms.
//
// Parameters:
//	Form - See WhenCreatingMatchingFormOnServer.Form
//
// Returns:
//	Structure - parameters for creating a new item from the selection forms:
//		* Owner - CatalogRef.Products, CatalogRef.ItemKinds - parent of the new characteristic
//		* ProductKind - CatalogRef.ItemKinds - type of item of the new feature
//
Function ParametersForCreatingNewCharacteristic(Form) Export
	
	FormParameters = New Structure("Owner, ProductKind, AddressOfParameterTable");
	
	// The parameters for creating a new characteristic can be obtained from the parameters
	// of the dynamic list of characteristics, because in general, selection can be
	// imposed both by the nomenclature displayed in the list of nomenclature,
	// and by a new nomenclature that is not displayed in the list.
	
	ParametersOfListOfCharacteristics = Form.FeatureList.Parameters.Items;
	
	// ... get the value of the item parameter.
	Parameter = ParametersOfListOfCharacteristics.Find("Products");
	
	If Not (Parameter = Undefined) Then
		FormParameters.Owner = OwnerOfProductCharacteristics(Parameter.Value);
	EndIf;
	
	// ... get the value of the item type parameter.
	Parameter = ParametersOfListOfCharacteristics.Find("ProductKind");
	
	If Not (Parameter = Undefined) Then
		FormParameters.ProductKind = Parameter.Value;
	EndIf;
	
	If Form.UseFilters Then
		If (Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds)Then
			If ValueIsFilled(Form.ProductKind) Then
				FormParameters.AddressOfParameterTable = AddressOfSelectionTreeParameterTable(Form);
			EndIf;
		EndIf;
	EndIf;
	
	Return FormParameters;
	
EndFunction

#EndRegion

#Region GeneratingQueryTextsForDynamicListsOnSelectionForms

// Returns the text of the request for information about the product's sale price.
//
// Parameters:
//	QuerySections - Array, Undefined - variable to write an array of strings, the composition of sections of the query text.
//
// Returns:
//	String - the text of the request for information about the sale price of the product.
//
Function QueryTextSalePriceOfGoods(QuerySections) Export
	
	If QuerySections = Undefined Then
		QuerySections = New Array;
	EndIf;
	
	QuerySections.Add("SalePriceOfGoods");
	
	Text = 
	"SELECT ALLOWED
	|	CASE
	|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
	|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
	|		WHEN AgreementGoods.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				AND AgreementGoods.PriceKind IS NOT NULL 
	|			THEN AgreementGoods.PriceKind
	|		WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				OR AgreementGoods.PriceKind IS NULL )
	|				AND AgreementPriceGroups.PricesKind IS NOT NULL 
	|				AND AgreementPriceGroups.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|			THEN AgreementPriceGroups.PricesKind
	|		WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				OR AgreementGoods.PriceKind IS NULL )
	|				AND (AgreementPriceGroups.PricesKind IS NULL 
	|					OR AgreementPriceGroups.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef))
	|				AND AgreementHeader_.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|			THEN AgreementHeader_.PricesKind
	|	END AS PriceKind,
	|	CASE
	|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
	|			THEN 1
	|		WHEN AgreementGoods.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				AND AgreementGoods.PriceKind IS NOT NULL 
	|			THEN 2
	|		WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				OR AgreementGoods.PriceKind IS NULL )
	|				AND AgreementPriceGroups.PricesKind IS NOT NULL 
	|				AND AgreementPriceGroups.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|			THEN 3
	|		WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				OR AgreementGoods.PriceKind IS NULL )
	|				AND (AgreementPriceGroups.PricesKind IS NULL 
	|					OR AgreementPriceGroups.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef))
	|				AND AgreementHeader_.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|			THEN 4
	|	END AS LongDesc,
	|	CASE
	|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
	|			THEN AgreementGoods.Package
	|		ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
	|	END AS Package,
	|	CatalogProducts.UnitOfMeasure AS UnitOfMeasure,
	|	ISNULL(&QueryTextPackagingFactor1, 1) AS ZoomRatio,
	|	CAST(CASE
	|			WHEN ISNULL(AgreementGoods.Price, 0) > 0
	|				THEN AgreementGoods.Price
	|			WHEN CASE
	|						WHEN ISNULL(AgreementGoods.Price, 0) > 0
	|							THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
	|						WHEN AgreementGoods.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|								AND AgreementGoods.PriceKind IS NOT NULL 
	|							THEN AgreementGoods.PriceKind
	|						WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|								OR AgreementGoods.PriceKind IS NULL )
	|								AND AgreementPriceGroups.PricesKind IS NOT NULL 
	|								AND AgreementPriceGroups.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|							THEN AgreementPriceGroups.PricesKind
	|						WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|								OR AgreementGoods.PriceKind IS NULL )
	|								AND (AgreementPriceGroups.PricesKind IS NULL 
	|									OR AgreementPriceGroups.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef))
	|								AND AgreementHeader_.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|							THEN AgreementHeader_.PricesKind
	|					END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|					AND ISNULL(ItemsPrices.Price, 0) > 0
	|				THEN ItemsPrices.Price * CASE
	|						WHEN &Currency <> ItemsPrices.Currency
	|							THEN CASE
	|									WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
	|											AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
	|											AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
	|											AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
	|										THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
	|									ELSE 0
	|								END
	|						ELSE 1
	|					END
	|			ELSE 0
	|		END AS NUMBER(31,2)) AS Price,
	|	CASE
	|		WHEN ISNULL(AgreementGoods.DeliveryPeriodDays, 0) > 0
	|			THEN AgreementGoods.DeliveryPeriodDays
	|		ELSE CASE
	|				WHEN ISNULL(AgreementPriceGroups.DeliveryPeriodDays, 0) > 0
	|					THEN AgreementPriceGroups.DeliveryPeriodDays
	|				ELSE AgreementHeader_.DeliveryPeriodDays
	|			END
	|	END AS DeliveryPeriodDays
	|FROM
	|	Catalog.TermsOfSale AS AgreementHeader_
	|		LEFT JOIN Catalog.TermsOfSale.Goods AS AgreementGoods
	|		ON AgreementHeader_.Ref = AgreementGoods.Ref
	|			AND (AgreementGoods.Products = &Products)
	|			AND (AgreementGoods.Characteristic = &Characteristic)
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON (CatalogProducts.Ref = &Products)
	|		LEFT JOIN Catalog.TermsOfSale.PriceGroups AS AgreementPriceGroups
	|		ON (AgreementPriceGroups.Ref = &Terms)
	|			AND (AgreementPriceGroups.PriceGroup = CatalogProducts.PriceGroup)
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(
	|				ENDOFPERIOD(&CurrentDate, DAY),
	|				PriceKind IN (&TypesOfPrices)
	|					AND Products = &Products
	|					AND Characteristic = &Characteristic) AS ItemsPrices
	|		ON (ItemsPrices.PriceKind = CASE
	|				WHEN ISNULL(AgreementGoods.Price, 0) > 0
	|					THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				WHEN AgreementGoods.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|						AND AgreementGoods.PriceKind IS NOT NULL 
	|					THEN AgreementGoods.PriceKind
	|				WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|						OR AgreementGoods.PriceKind IS NULL )
	|						AND AgreementPriceGroups.PricesKind IS NOT NULL 
	|						AND AgreementPriceGroups.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|					THEN AgreementPriceGroups.PricesKind
	|				WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|						OR AgreementGoods.PriceKind IS NULL )
	|						AND (AgreementPriceGroups.PricesKind IS NULL 
	|							OR AgreementPriceGroups.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef))
	|						AND AgreementHeader_.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|					THEN AgreementHeader_.PricesKind
	|			END)
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(,
	|			BaseCurrency IN
	|			(SELECT
	|				DefaultBaseCurrency.Value
	|			FROM
	|				Constant.DefaultBaseCurrency AS DefaultBaseCurrency)) AS RatesCutCurrencyPrices
	|		ON (RatesCutCurrencyPrices.Currency = ItemsPrices.Currency)
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(,
	|			Currency = &Currency
	|			AND BaseCurrency IN
	|			(SELECT
	|				DefaultBaseCurrency.Value
	|			FROM
	|				Constant.DefaultBaseCurrency AS DefaultBaseCurrency)) AS CrossSectionRatesDocumentCurrency
	|		ON (TRUE)
	|WHERE
	|	AgreementHeader_.Ref = &Terms";
	
	Text = StrReplace(Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ItemsPrices.Package",
		"ItemsPrices.Products"));
		
	Return Text;
	
EndFunction

// Returns the text of the request for information about the purchase price of the product.
//
// Parameters:
//	QuerySections - Array of Arbitrary - variable to write an array of strings, the composition of sections of the query text.
//
// Returns:
//	String - the text of the request for information about the purchase price of the goods.
//
Function QueryTextPurchasePrice_(QuerySections) Export
	
	If QuerySections = Undefined Then
		QuerySections = New Array;
	EndIf;
	
	QuerySections.Add("PurchasePrice_");
	
	Text = 
	"SELECT ALLOWED
	|	ISNULL(ItemsPricesOfVendor.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	CatalogProducts.UnitOfMeasure AS UnitOfMeasure,
	|	ISNULL(&QueryTextPackagingFactor2, 1) AS ZoomRatio,
	|	CAST(ISNULL(ItemsPricesOfVendor.Price, 0) * CASE
	|			WHEN &Currency <> ItemsPricesOfVendor.Currency
	|				THEN CASE
	|						WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
	|								AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
	|								AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
	|								AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
	|							THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
	|						ELSE 0
	|					END
	|			ELSE 1
	|		END AS NUMBER(31,2)) AS Price
	|FROM
	|	Catalog.Products AS CatalogProducts
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS AgreementHeader_
	|		ON AgreementHeader_.Ref = &Terms
	|		LEFT JOIN InformationRegister.ItemsPricesOfVendor.SliceLast(
	|				&PricesOfSupplierProductsCutByDate,
	|				Partner = CAST(&Terms AS Catalog.TermsOfPurchaseFromVendors).Partner
	|					AND Products = &Products
	|					AND Characteristic = &Characteristic) AS ItemsPricesOfVendor
	|		ON (AgreementHeader_.VendorPriceKind = ItemsPricesOfVendor.VendorPriceKind)
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(,
	|			BaseCurrency IN
	|			(SELECT
	|				DefaultBaseCurrency.Value
	|			FROM
	|				Constant.DefaultBaseCurrency AS DefaultBaseCurrency)) AS RatesCutCurrencyPrices
	|		ON (RatesCutCurrencyPrices.Currency = ItemsPricesOfVendor.Currency)
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(,
	|			Currency = &Currency
	|			AND BaseCurrency IN
	|			(SELECT
	|				DefaultBaseCurrency.Value
	|			FROM
	|				Constant.DefaultBaseCurrency AS DefaultBaseCurrency)) AS CrossSectionRatesDocumentCurrency
	|		ON (TRUE)
	|WHERE
	|	CatalogProducts.Ref = &Products";
	
	Text = StrReplace(Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ItemsPricesOfVendor.Package",
		"ItemsPricesOfVendor.Products"));
		
	Return Text;
	
EndFunction

#EndRegion

#Region SettingParametersForDynamicListQueriesOnSelectionForms

// Sets the values of dynamic list query texts on selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetQueryTextsForMatchingFormLists(Form) Export
	
	ThisIsFormOfSelectionInPurchaseDocuments = SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode);
	
	Form.ListProducts.QueryText = RequestTextForSelectionFormList(Form, "ListProducts");
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChangeListQueryTextForCurrentLanguage(Form, "ListProducts");
	// End StandardSubsystems.Core
	
	If Form.UseItemVariants Then
		
		Form.FeatureList.QueryText = RequestTextForSelectionFormList(Form, "FeatureList");
		
		// StandardSubsystems.Core
		NationalLanguageSupportServer.ChangeListQueryTextForCurrentLanguage(Form, "ListProducts");
		// End StandardSubsystems.Core
		
	EndIf;
	
	If ThisIsFormOfSelectionInPurchaseDocuments
		And Form.UsePartnersProducts Then
		
		Form.ListOfThePartnerSNomenclature.QueryText = RequestTextForSelectionFormList(Form, "ListOfThePartnerSNomenclature");
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ManagingVisibilityOfPagesWithNavigationParameters

// Sets the navigation option page on the selection form.
//
// Parameters:
//  Form						 - ClientApplicationForm	 - the list form item or the form of selection.  
//  NavigationOptionBeforeChange	 - EnumRef.ItemFormNavigationOptions - the navigation option that was in the form before the new option was selected.
//									This parameter is passed to implement the ability to return to the previous navigation option and is relevant for
//									the options "Potovaramdrugogodestvo " and"Posovmestnymprodazham".
//
Procedure SetNavigationOptionPage(Form, NavigationOptionBeforeChange = Undefined) Export
	
	If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByHierarchy Then
		NavigationOptionsPage = Form.Items.ProductsHierarchyNavigation;
	ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByVendorHierarchy Then
		NavigationOptionsPage = Form.Items.NavigationPartnerItemHierarchy;
	ElsIf Not ValueIsFilled(Form.NavigationOption) Then
		NavigationOptionsPage = Form.Items.ProductsHierarchyNavigation;
		Form.NavigationOption = Enums.ItemFormNavigationOptions.ByHierarchy;
	ElsIf (Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds) Then
		NavigationOptionsPage = Form.Items.ProductKindsNavigation;
		
		If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties Then
			Form.Items.FilterTree.Visible    = True;
			Form.Items.ProductKind.Visible  = False;
		ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds Then
			Form.Items.FilterTree.Visible    = False;
			Form.Items.ProductKind.Visible  = False;
		ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties Then
			Form.Items.FilterTree.Visible    = True;
			Form.Items.ProductKind.Visible  = True;
		EndIf;
		
		If SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode)
			Or SelectGoodsClientServer.ThisIsFormOfProductSelection(Form.FormCode)
			Or SelectGoodsClientServer.ThisIsProductListForm(Form.FormCode) Then
			
			If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties Then
				Form.Items.ItemKinds.Visible = True;
			ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds Then
				Form.Items.ItemKinds.Visible = True;
			ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties Then
				Form.Items.ItemKinds.Visible = False;
			EndIf;
		EndIf;
	
	ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsSoldTogether Then
		NavigationOptionsPage = Form.Items.PageSelectedGoods;
	ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsOfAnotherQuality Then
		If SelectGoodsClientServer.ThisIsFormOfSimilarGoodsProduct(Form.FormCode) Then
			NavigationOptionsPage = Form.Items.ProductsHierarchyNavigation;
		Else
			NavigationOptionsPage = Form.Items.PageOtherQualityGoods;
		EndIf;
	ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.RemainingGoodsByShelfLives Then
		Form.Items.ProductKind.Visible  = False;
		NavigationOptionsPage = Form.Items.ProductsNavigation;
	ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByVendorPartNumbers Then
		Form.Items.ProductKind.Visible  = False;
		NavigationOptionsPage = Form.Items.NavigationPartnerNomenclature;
	EndIf;
	
	ReturnToFilters = Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsOfAnotherQuality
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsSoldTogether;
	
	If SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode)
		Or SelectGoodsClientServer.ThisIsFormOfProductSelection(Form.FormCode)
		Or SelectGoodsClientServer.ThisIsProductListForm(Form.FormCode) Then
		Form.Items.UseFilters.Enabled = Not ReturnToFilters;
		Form.Items.StandardSearchCommandPanelSetFilter.Enabled = Not ReturnToFilters;
		Form.Items.AdvancedSearchCommandBarSetFilter.Enabled = Not ReturnToFilters;
		Form.Items.ListAdvancedSearchProductsContextMenuProductsWithSimilarProperties.Enabled = Not ReturnToFilters;
		Form.Items.ListAdvancedSearchProductsContextMenuAnotherQualityGoods.Enabled = Not ReturnToFilters;
		Form.Items.ListStandardSearchProductsContextMenuProductsWithSimilarProperties.Enabled = Not ReturnToFilters;
		Form.Items.ListStandardSearchProductsContextMenuAnotherQualityGoods.Enabled = Not ReturnToFilters;
		GenerateCaptionNavigationOption(Form, NavigationOptionBeforeChange);
	EndIf;
	
	Form.Items.NavigationOptions.CurrentPage = NavigationOptionsPage;
	
	If Not SelectGoodsClientServer.ThisIsPriceListForm(Form.FormCode)
			And Not SelectGoodsClientServer.ThisIsSuppliersPriceListForm(Form.FormCode) Then
		
		If AccessRight("Update", Metadata.Catalogs.ItemKinds) Then
			
			Visible = Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties
				Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds;
			
			CommonClientServer.SetFormItemProperty(Form.Items, "TypesOfNomenclatureCreate", "Visible", Visible);
			CommonClientServer.SetFormItemProperty(Form.Items, "ItemTypesCreateAGroup", "Visible", Visible);
			CommonClientServer.SetFormItemProperty(Form.Items, "ChangeItemTypes", "Visible", Visible);
			CommonClientServer.SetFormItemProperty(Form.Items, "TypesOfNomenclatureCopy", "Visible", Visible);
			CommonClientServer.SetFormItemProperty(Form.Items, "ItemTypesSetTheDeleteMark", "Visible", Visible);
			
			CommonClientServer.SetFormItemProperty(Form.Items, "CreateAnItemView", "Visible", Visible);
			CommonClientServer.SetFormItemProperty(Form.Items, "CreateAGroupOfItemTypes", "Visible", Visible);
			
		EndIf;
		
		If AccessRight("Update", Metadata.Catalogs.Products) Then
			Visible = Form.NavigationOption = Enums.ItemFormNavigationOptions.ByHierarchy;
			CommonClientServer.SetFormItemProperty(Form.Items, "CreateAnItemGroup", "Visible", Visible);
		EndIf;
		
	EndIf;
	
	Visible = Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties;
	
	Form.Items.ResetFiltersByProperties.Visible = Visible;
	
	Enabled = Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties;
	
	Form.Items.ResetFiltersByProperties.Enabled = Enabled;
	
EndProcedure

// Forms a view of the navigation option
//
// Parameters:
//  Form						 - ClientApplicationForm - item list form or selection form 
//  NavigationOptionBeforeChange	 - EnumRef.ItemFormNavigationOptions - the navigation option that was in the form before the new option was selected.
//									This parameter is passed to implement the ability to return to the previous navigation option and is relevant for
//									the options "Potovaramdrugogodestvo " and"Posovmestnymprodazham".
//
Procedure GenerateCaptionNavigationOption(Form, NavigationOptionBeforeChange = Undefined)
	ArrayOfLabelLines = New Array();
		
	If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByHierarchy Then
		ArrayOfLabelLines.Add(NStr("vi = 'Phân nhánh mặt hàng';
									|ru = 'Иерархия номенклатуры';
									|en = 'Items hierarchy'; fa = 'سلسله‌مراتب اقلام';
									|it = 'Gerarchia di articoli';
									|pl = 'Hierarchia nomenklatury';
									|tr = 'Öğe hiyerarşisi'"));
	ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsOfAnotherQuality Then
		ArrayOfLabelLines.Add(NStr("vi = 'Hàng hóa có chất lượng khác';
									|ru = 'Товары другого качества';
									|en = 'Nonconforming products'; fa = 'محصولات نامنطبق';
									|it = 'Prodotti di un''altra qualità';
									|pl = 'Wiersze pozycji innej jakości';
									|tr = 'Farklı kalitede olan ürünler'"));
		ArrayOfLabelLines.Add("  ");
		ArrayOfLabelLines.Add(New FormattedString(NStr("vi = 'Quay lại';
														|ru = 'Назад';
														|en = 'Back'; fa = 'بازگشت';
														|it = 'Indietro';
														|pl = 'Back';
														|tr = 'Geri'"),
		,
		,
		,
		Common.EnumerationValueName(NavigationOptionBeforeChange)));
	ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsSoldTogether 
		And ValueIsFilled(NavigationOptionBeforeChange) Then
		ArrayOfLabelLines.Add(NStr("vi = 'Bán hàng chung';
									|ru = 'Совместные продажи';
									|en = 'Joint sales'; fa = 'فروش مشترک';
									|it = 'Vendite congiunte';
									|pl = 'Wspólne sprzedaże';
									|tr = 'Ortak satışlar'"));
		ArrayOfLabelLines.Add("  ");
		ArrayOfLabelLines.Add(New FormattedString(NStr("vi = 'Quay lại';
														|ru = 'Назад';
														|en = 'Back'; fa = 'بازگشت';
														|it = 'Indietro';
														|pl = 'Back';
														|tr = 'Geri'"),
		,
		,
		,
		Common.EnumerationValueName(NavigationOptionBeforeChange)));
	ElsIf Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties 
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds 
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties Then
		
		If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties Then 
			ArrayOfLabelLines.Add(New FormattedString(NStr("vi = 'Dạng và thuộc tính';
															|ru = 'Виды и свойства';
															|en = 'Filter by kinds and attributes'; fa = 'Filter by kinds and attributes';
															|it = 'Tipi e proprietà';
															|pl = 'Rodzaje i właściwości';
															|tr = 'Türler ve özellik'"),
			New Font(,,True),
			Form.FormTextColor,
			,));
		Else
			ArrayOfLabelLines.Add(New FormattedString(NStr("vi = 'Dạng và thuộc tính';
															|ru = 'Виды и свойства';
															|en = 'Filter by kinds and attributes'; fa = 'Filter by kinds and attributes';
															|it = 'Tipi e proprietà';
															|pl = 'Rodzaje i właściwości';
															|tr = 'Türler ve özellik'"),
			,
			,
			,
			Common.EnumerationValueName(Enums.ItemFormNavigationOptions.ByKindsAndProperties)));
		EndIf;
		
		ArrayOfLabelLines.Add("  ");
		
		
		If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKinds Then
			ArrayOfLabelLines.Add(New FormattedString(NStr("vi = 'Dạng';
															|ru = 'Виды';
															|en = 'Filter by kinds'; fa = 'Filter by kinds';
															|it = 'Tipi';
															|pl = 'Filter by kinds';
															|tr = 'Türler'"),
			New Font(,,True),
			Form.FormTextColor,
			,));
		Else
			ArrayOfLabelLines.Add(New FormattedString(NStr("vi = 'Dạng';
															|ru = 'Виды';
															|en = 'Filter by kinds'; fa = 'Filter by kinds';
															|it = 'Tipi';
															|pl = 'Filter by kinds';
															|tr = 'Türler'"),
			,
			,
			,
			Common.EnumerationValueName(Enums.ItemFormNavigationOptions.ByKinds)));
		EndIf;
		
		ArrayOfLabelLines.Add("  ");
		
		If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties Then
			ArrayOfLabelLines.Add(New FormattedString(NStr("vi = 'Thuộc tính';
															|ru = 'Свойства';
															|en = 'Filter by attributes'; fa = 'Filter by attributes';
															|it = 'Proprietà';
															|pl = 'Filter by attributes';
															|tr = 'Özellikler'"),
			New Font(,,True),
			Form.FormTextColor,
			,));
		Else
			ArrayOfLabelLines.Add(New FormattedString(NStr("vi = 'Thuộc tính';
															|ru = 'Свойства';
															|en = 'Filter by attributes'; fa = 'Filter by attributes';
															|it = 'Proprietà';
															|pl = 'Filter by attributes';
															|tr = 'Özellikler'"),
			,
			,
			,
			Common.EnumerationValueName(Enums.ItemFormNavigationOptions.ByProperties)));
		EndIf;
	Else
		ArrayOfLabelLines = New Array();
	EndIf;
	
	If ArrayOfLabelLines.Count() > 0 Then
		Form.LabelNavigationOption = New FormattedString(ArrayOfLabelLines);
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForNavigatingCharacteristicsInSelectionForms

// Called when switching to a page with a list of characteristics.
//
// Parameters:
//	Form - ClientApplicationForm - selection form,
//	Nomenclature parametres-Structure - parameters of the nomenclature to switch to the page with a list of characteristics for.
//
Procedure GoToListOfCharacteristicsOfNewProduct(Form)
	ProductParameters_ = Form.NewNomenclature;
	
	ThisIsFormOfSelectionInPurchaseDocuments = SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode);
	ThisIsFormOfMatchingInSalesDocuments = SelectGoodsClientServer.ThisIsFormOfMatchingInSalesDocuments(Form.FormCode);
	
	// Enable the feature navigation feature.
	Form.CharacteristicNavigation = True;
	
	// Set the column heading of the characteristics table.
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đặc tính: ""%1""';
			|ru = 'Характеристики: ""%1""';
			|en = 'Variants: ""%1""'; fa = 'Variants: ""%1""';
			|it = 'Caratteristiche: ""%1""';
			|pl = 'Charakterystyki: ""%1""';
			|tr = 'Varyantlar: ""%1""'"), ProductParameters_.Products);
	
	TagName = SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(Form) + "Characteristic";
	ShapeTableCharacteristic = Form.Items[TagName]; // FormTable
	ShapeTableCharacteristic.Title = TitleText;
	
	// Set the parameters of the list of characteristics.
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "Products", ProductParameters_.Products);
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "UnitOfMeasure", 
		ProductParameters_.UnitOfMeasure);
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "ItemVariantsOwner", 
		ProductParameters_.ItemVariantsOwner);
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "ItemsType", ProductParameters_.ItemsType);
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "ProductKind", ProductParameters_.ProductKind);
	
	If Not ThisIsFormOfSelectionInPurchaseDocuments Then
		CommonClientServer.SetDynamicListParameter(
			Form.FeatureList, "PriceGroup", ProductParameters_.PriceGroup);
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "ProductSegment", 
		Form.ProductSegment, ValueIsFilled(Form.ProductSegment));
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "SegmentProducts", 
		ProductParameters_.Products, ValueIsFilled(Form.ProductSegment));
	
	// Set the selection of a list of characteristics for goods sold together.
	If ThisIsFormOfMatchingInSalesDocuments Then
		
		ArrayOfCharacteristics = New Array;
		
		For Each TSRow In Form.TableItemSoldJointly Do
			
			If TSRow.Products = ProductParameters_.Products Then
				ArrayOfCharacteristics.Add(TSRow.Characteristic);
			EndIf;
			
		EndDo;
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.FeatureList, "Characteristic",
			ArrayOfCharacteristics, DataCompositionComparisonType.InList, ,ArrayOfCharacteristics.Count() > 0);
		
	EndIf;
	
	Form.Items.PagesOfLists.CurrentPage = Form.Items[SelectGoodsClientServer.CurPageNameBySearchOption(Form)];
	Form.CurrentItem = Form.Items[SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(Form)];
	Form.Items.ProductSegment.ReadOnly = True;
	
	Form.Items.PagesCreate.CurrentPage = Form.Items.PageCreateCharacteristic;
	
	SelectGoodsClientServer.SetAvailabilityOfFilterElements(Form);
	
EndProcedure

#EndRegion

#Region WorkingWithSelectionTreeBasedOnPropertiesOfProductType

Procedure LabelNavigationOptionNavigationLink(Form, URL, StandardProcessing) Export
	
	StandardProcessing = False;
	
	NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions." + URL);
	Form.NavigationOption = NavigationOption;
	WhenChangingNavigationOption(Form);
	
EndProcedure

// Fills in the selection tree based on the properties of the item type selected on the form.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure FillInProductSelectionTree(Form) Export
	
	FilterTree = Form.FormAttributeToValue("FilterTree");
	FilterTree.Rows.Clear();
	
	FillInTreeOfSelectionValues(Form, FilterTree, False);
	
	If SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode) Then
		FillInTreeOfSelectionValues(Form, FilterTree, True);
	EndIf;
	
	Form.ValueToFormAttribute(FilterTree, "FilterTree");
	
EndProcedure

// Fills the selection value tree of the form (list, selection)
// with selection values for the item.
//
// Parameters:
//	Form - ClientApplicationForm - form the list form of selection.
//	FilterTree - ValueTree - tree of property selection values.
//	ByItemVariants - Boolean - indicates whether to fill in the selection values for the list of characteristics.
//
Procedure FillInTreeOfSelectionValues(Form, FilterTree, ByItemVariants)
	
	TypeOfProductForCharacteristics = Undefined;
	
	FilterParametersTable = Form.FilterParametersTable.Unload();
	FilterParametersTable.Indexes.Add("FilterFeatures");
	FilterParametersTable.Indexes.Add("AttributeName");
	
	Filter				= New Structure("FilterFeatures", ByItemVariants);
	PickedRows	= FilterParametersTable.FindRows(Filter);
	
	For Each String In PickedRows Do
		String.Filter = False;
	EndDo;
		
	If ByItemVariants Then
		
		ProductKindAttributes = Common.ObjectAttributesValues(
										Form.ProductKind,
										"UseVariants,ItemVariantsOwner");
		
		If ProductKindAttributes.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind
			Or ProductKindAttributes.UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems Then
			TypeOfProductForCharacteristics = Form.ProductKind;
		ElsIf ProductKindAttributes.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
			TypeOfProductForCharacteristics = ProductKindAttributes.ItemVariantsOwner;
		Else
			Return;
		EndIf;
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	AttributesOfItemVariantQuickFilter.LineNumber AS LineNumber,
		|	AttributesOfItemVariantQuickFilter.Property AS Property,
		|	AttributesOfItemVariantQuickFilter.AttributeName AS AttributeName,
		|	CASE
		|		WHEN AttributesOfItemVariantQuickFilter.IsAddlAttribute
		|			THEN PRESENTATION(AttributesOfItemVariantQuickFilter.Property)
		|		ELSE AttributesOfItemVariantQuickFilter.AttributeRepresentation
		|	END AS AttributeRepresentation,
		|	AttributesOfItemVariantQuickFilter.IsAddlAttribute AS IsAddlAttribute,
		|	CASE
		|		WHEN NOT AttributesOfItemVariantQuickFilter.Property IS NULL 
		|			THEN AttributesOfItemVariantQuickFilter.Property.ValueType
		|	END AS DescriptionOfValueType_,
		|	AttributesOfItemVariantQuickFilter.Property.Title AS PropsHeader
		|FROM
		|	Catalog.ItemKinds.AttributesOfItemVariantQuickFilter AS AttributesOfItemVariantQuickFilter
		|WHERE
		|	AttributesOfItemVariantQuickFilter.Ref = &ProductKind";
		
		Query.SetParameter("ProductKind", TypeOfProductForCharacteristics);
		
	Else
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	AttributesOfQuickFilterOfProducts.LineNumber AS LineNumber,
		|	AttributesOfQuickFilterOfProducts.Property AS Property,
		|	AttributesOfQuickFilterOfProducts.AttributeName AS AttributeName,
		|	CASE
		|		WHEN AttributesOfQuickFilterOfProducts.IsAddlAttribute
		|			THEN PRESENTATION(AttributesOfQuickFilterOfProducts.Property)
		|		ELSE AttributesOfQuickFilterOfProducts.AttributeRepresentation
		|	END AS AttributeRepresentation,
		|	AttributesOfQuickFilterOfProducts.IsAddlAttribute AS IsAddlAttribute,
		|	CASE
		|		WHEN NOT AttributesOfQuickFilterOfProducts.Property IS NULL 
		|			THEN AttributesOfQuickFilterOfProducts.Property.ValueType
		|	END AS DescriptionOfValueType_,
		|	AttributesOfQuickFilterOfProducts.Property.Title AS PropsHeader
		|FROM
		|	Catalog.ItemKinds.AttributesOfQuickFilterOfProducts AS AttributesOfQuickFilterOfProducts
		|WHERE
		|	AttributesOfQuickFilterOfProducts.Ref = &ProductKind
		|
		|ORDER BY
		|	LineNumber";
		
		Query.SetParameter("ProductKind", Form.ProductKind);
		
	EndIf;
	
	QuickSelectionDetails = Query.Execute().Unload();
	PropsString = Undefined;
	MaximumNumberOfValuesInTree = Constants.MaximumNumberOfItemsInItemFilterTree.Get();
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "ProductSegment")
		And ValueIsFilled(Form.ProductSegment) Then
		
		ThereIsSelectionBySegment = True;
		
	Else
		ThereIsSelectionBySegment = False;
	EndIf;
	
	For Each Attribute In QuickSelectionDetails Do
		
		If Attribute.IsAddlAttribute Then
			AttributeType = Attribute.DescriptionOfValueType_;
			ProductItemDetails = Undefined;
		Else
			ProductItemDetails = Metadata.Catalogs.Products.Attributes[Attribute.AttributeName];
			AttributeType = ProductItemDetails.Type;
		EndIf;
		
		If PropsString <> Undefined
			And PropsString.Rows.Count() > 0 Then
			PropsString.Rows.Sort("Presentation");
		EndIf;
		
		PropsString = FilterTree.Rows.Add();
		PropsString.AttributeName		= ?(Attribute.IsAddlAttribute,
												Attribute.AttributeRepresentation,
												Attribute.AttributeName);
		PropsString.IsAddlAttribute		= Attribute.IsAddlAttribute;
		PropsString.Presentation		= ?(ValueIsFilled(Attribute.PropsHeader),
												Attribute.PropsHeader,
												Attribute.AttributeRepresentation);
		PropsString.FilterFeatures	= ByItemVariants;
		PropsString.FilterAvailable		= True;
		
		Filter = New Structure("AttributeName", PropsString.AttributeName);
		PickedRows = FilterParametersTable.FindRows(Filter);
		
		If AttributeType.ContainsType(Type("Date")) Then
			
			If PickedRows.Count()>0 Then
				PickedRows[0].Filter = True;
				
				FillPropertyValues(PropsString,PickedRows[0]);
			Else
				PropsString.IntervalFrom            = Date('00010101');
				PropsString.IntervalTo            = Date('00010101');
				PropsString.FixedValue = True;
				PropsString.FilterValue        = Date('00010101');
				PropsString.FilterPresentation   = NStr("vi = '<chưa đặt>';
														|ru = '<не задано>';
														|en = '<not set>'; fa = '<تنظیم نشده>';
														|it = '<non indicato>';
														|pl = '<nie określono>';
														|tr = '<belirtilmedi>'");
			EndIf;
			
		ElsIf AttributeType.ContainsType(Type("Number"))Then
			
			If PickedRows.Count() > 0 Then
				PickedRows[0].Filter = True;
				
				FillPropertyValues(PropsString,PickedRows[0]);
			Else
				PropsString.IntervalFrom            = 0;
				PropsString.IntervalTo            = 0;
				PropsString.FixedValue = True;
				PropsString.FilterValue        = 0;
				PropsString.FilterPresentation   = NStr("vi = '<chưa đặt>';
														|ru = '<не задано>';
														|en = '<not set>'; fa = '<تنظیم نشده>';
														|it = '<non indicato>';
														|pl = '<nie określono>';
														|tr = '<belirtilmedi>'");
			EndIf;
			
		ElsIf AttributeType.ContainsType(Type("Boolean")) Then
			
			PropsString.FilterValue = True;
			If PickedRows.Count() > 0 Then
				PickedRows[0].Filter = True;
				PropsString.Filter = True;
			EndIf;
			
		ElsIf AttributeType.ContainsType(Type("String")) Then
			
			If PickedRows.Count() > 0 Then
				PickedRows[0].Filter = True;
				
				FillPropertyValues(PropsString,PickedRows[0]);
			Else
				PropsString.FilterValue        = "";
				PropsString.FixedValue = True;
				PropsString.FilterPresentation   = NStr("vi = '<chưa đặt>';
														|ru = '<не задано>';
														|en = '<not set>'; fa = '<تنظیم نشده>';
														|it = '<non indicato>';
														|pl = '<nie określono>';
														|tr = '<belirtilmedi>'");
				PropsString.FilterAvailable         = True;
			EndIf;
			
		Else
			
			PropsString.FilterAvailable = False;
			
			TypeMetadata = Metadata.FindByType(AttributeType.Types()[0]);
			
			If Not AccessRight("Read", TypeMetadata) Then
				FilterTree.Rows.Delete(PropsString);
				PropsString = Undefined;
				Continue;
			EndIf;
			
			Query = New Query;
			
			If ByItemVariants Then
				QueryText =
				"SELECT ALLOWED DISTINCT TOP 999
				|	AdditionalAttributes.Value AS FilterValue
				|FROM
				|	Catalog.ItemsCharacteristics.AdditionalAttributes AS AdditionalAttributes
				|WHERE
				|	&PropsOwnerOfCharacteristics = &TypeOfProductForCharacteristics
				|	AND AdditionalAttributes.Property = &Property";
				
				QueryText = StrReplace(QueryText, "TOP 999", "TOP " + String(MaximumNumberOfValuesInTree + 1)+" "); //@Query-part-2
				
				If ProductKindAttributes.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind Then
					PropsOwnerOfCharacteristics = "AdditionalAttributes.Ref.Owner";
					SelectionOfProductsByType = "TRUE";
				ElsIf ProductKindAttributes.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
					PropsOwnerOfCharacteristics = "AdditionalAttributes.Ref.Owner";
					SelectionOfProductsByType = "Segments.Products.ProductKind = &ProductKind";
				ElsIf ProductKindAttributes.UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems Then
					PropsOwnerOfCharacteristics = "AdditionalAttributes.Ref.Owner.ProductKind";
					SelectionOfProductsByType = "TRUE";
				Else
					Return;
				EndIf;
				
				If ThereIsSelectionBySegment Then
					
					QueryText = QueryText + "
					|	AND 1 IN
					|			(SELECT TOP 1
					|				1
					|			FROM
					|				InformationRegister.SegmentProducts AS Segments
					|			WHERE
					|				Segments.Characteristic = AdditionalAttributes.Ref
					|				AND Segments.Segment IN HIERARCHY (&ProductSegment)
					|				AND &SelectionOfProductsByType)
					|";
					
				EndIf;
				
				QueryText = StrReplace(QueryText, "&PropsOwnerOfCharacteristics", PropsOwnerOfCharacteristics);
				QueryText = StrReplace(QueryText, "&SelectionOfProductsByType", SelectionOfProductsByType);
				
			ElsIf Attribute.IsAddlAttribute Then
				
				QueryText =
				"SELECT ALLOWED DISTINCT TOP 999
				|	AdditionalAttributes.Value AS FilterValue
				|FROM
				|	Catalog.Products.AdditionalAttributes AS AdditionalAttributes
				|WHERE
				|	AdditionalAttributes.Ref.ProductKind = &ProductKind
				|	AND AdditionalAttributes.Property = &Property";
				
				QueryText = StrReplace(QueryText, "TOP 999", "TOP " + String(MaximumNumberOfValuesInTree + 1)+" "); //@Query-part-2
				
				If ThereIsSelectionBySegment Then
					
					QueryText = QueryText + "
					|	AND 1 IN
					|			(SELECT TOP 1
					|				1
					|			FROM
					|				InformationRegister.SegmentProducts AS Segments
					|			WHERE
					|				Segments.Products = AdditionalAttributes.Ref
					|				AND Segments.Segment IN HIERARCHY (&ProductSegment))
					|";
					
				EndIf;
				
			Else
				
				QueryText =
				"SELECT ALLOWED DISTINCT TOP 999
				|	CatalogTable." + Attribute.AttributeName + " AS FilterValue
				|FROM
				|	Catalog.Products AS CatalogTable
				|WHERE
				|	CatalogTable.ProductKind = &ProductKind";
				
				QueryText = StrReplace(QueryText, "TOP 999", "TOP " + String(MaximumNumberOfValuesInTree + 1)+" "); //@Query-part-2
				
				If ThereIsSelectionBySegment Then
					
					QueryText = QueryText + "
					|	AND 1 IN
					|			(SELECT TOP 1
					|				1
					|			FROM
					|				InformationRegister.SegmentProducts AS Segments
					|			WHERE
					|				Segments.Products = CatalogTable.Ref
					|				AND Segments.Segment IN HIERARCHY (&ProductSegment))
					|";
					
				EndIf;
				
			EndIf;
			
			Query.Text = QueryText;
			
			Query.SetParameter("Property", Attribute.Property);
			Query.SetParameter("ProductKind", Form.ProductKind);
			Query.SetParameter("TypeOfProductForCharacteristics", TypeOfProductForCharacteristics);
			
			If ThereIsSelectionBySegment Then
				Query.SetParameter("ProductSegment", Form.ProductSegment);
			EndIf;
			
			// On a large database, a query in a loop is faster than a single query with groupings.
			// At the same time, it is faster both if you group by Property-Value, and if you combine queries
			// with groupings for each property separately.
			
			//@skip-check query-in-loop
			FetchingValues = Query.Execute().Select();
			
			If FetchingValues.Count() = 0 Then
				
				FilterTree.Rows.Delete(PropsString);
				PropsString = Undefined;
				
			ElsIf FetchingValues.Count() > MaximumNumberOfValuesInTree Then
				
				PropsString.FilterValue        = New ValueList;
				PropsString.FixedValue = True;
				PropsString.FilterPresentation   = NStr("vi = '<chưa đặt>';
														|ru = '<не задано>';
														|en = '<not set>'; fa = '<تنظیم نشده>';
														|it = '<non indicato>';
														|pl = '<nie określono>';
														|tr = '<belirtilmedi>'");
				PropsString.FilterAvailable         = True;
				
				Filter = New Structure;
				Filter.Insert("FilterValue");
				
				For Each CollectionItem In PickedRows Do
					If TypeOf(CollectionItem.FilterValue) = Type("ValueList") Then
						For Each ListItem In CollectionItem.FilterValue Do
							Filter.FilterValue = ListItem.Value;
							
							FetchingValues.Reset();
							
							If FetchingValues.FindNext(Filter) Then
								CollectionItem.Filter = True;
								
								PropsString.FilterValue = CollectionItem.FilterValue;
								
								Break;
							EndIf;
						EndDo;
					Else
						FillPropertyValues(Filter, CollectionItem);
						
						FetchingValues.Reset();
						
						If FetchingValues.FindNext(Filter) Then
							CollectionItem.Filter = True;
							
							PropsString.FilterValue.Add(CollectionItem.FilterValue);
						EndIf;
					EndIf;
				EndDo;
				
				If PropsString.FilterValue.Count() > 0 Then
					PropsString.FilterPresentation = String(PropsString.FilterValue);
					PropsString.Filter               = True;
				EndIf;
				
			Else
				
				FilterIs_Specified = False;
				
				While FetchingValues.Next() Do
					
					If (FetchingValues.Count() = 1
						And Not ValueIsFilled(FetchingValues.FilterValue)) Then
						FilterTree.Rows.Delete(PropsString);
						PropsString = Undefined;
						Continue;
					EndIf;
					
					ValueRow = PropsString.Rows.Add();
					FillPropertyValues(ValueRow, PropsString);
					
					ValueRow.FilterValue = FetchingValues.FilterValue;
					
					// Getting a line-by-line representation for 50 values works faster, fetching it immediately in a query
					// that forms a selection of values, because there is a grouping there
					// It also works faster than a representation query (Query Language REPRESENTATION function)
					// made for 50 values at once.
					ValueRow.Presentation  = String(FetchingValues.FilterValue);
					ValueRow.FilterAvailable  = True;
					
					For Each CollectionItem In PickedRows Do
						If TypeOf(CollectionItem.FilterValue) = Type("ValueList") 
								And CollectionItem.FilterValue.FindByValue(ValueRow.FilterValue) <> Undefined
							Or CollectionItem.FilterValue = ValueRow.FilterValue Then
							CollectionItem.Filter = True;
							ValueRow.Filter = True;
							FilterIs_Specified = True;
							Break;
						EndIf;
					EndDo;
					
				EndDo;
				
				If PropsString <> Undefined Then
					PropsString.Filter = FilterIs_Specified;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Form.FilterParametersTable.Load(FilterParametersTable);
	
	SetNeedToSaveSettings(Form);
	
	If PropsString <> Undefined
		And PropsString.Rows.Count() > 0 Then
		
		PropsString.Rows.Sort("Presentation");
		
	EndIf;
	
EndProcedure

// Clears the property tree for selection by item type properties.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure ClearSelectionTree(Form)
	
	FilterTree = Form.FormAttributeToValue("FilterTree");
	FilterTree.Rows.Clear();
	
	Form.ValueToFormAttribute(FilterTree, "FilterTree");
	
EndProcedure

#EndRegion

#Region InstallingAndRemovingSelections

// Sets a mark for elements in the list of quality gradations.
// Used when navigating through alternative quality products.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form, selection form.
//
Procedure SetQualityGradationMark(Form)
	
	For Each ListItem In Form.ListQualities Do
		ListItem.Check = True;
	EndDo;
	
EndProcedure

// Sets selection by the parent of the current line in the item list
// in the product selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure SetCurRowOfProductHierarchy(Form)
	
	ProductFormTable = Form.Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form)]; // FormTable
	CurrentRow = ProductFormTable.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	Parent = Common.ObjectAttributeValue(CurrentRow, "Parent");
	
	Form.Items.ProductsHierarchy.CurrentRow = Parent;
	Form.CurrentProductsHierarchy = Parent; 
	
EndProcedure

// Sets selection by item type and item type properties
// for the item list in the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure EstablishSelectionByTypeOfProductAndPropertiesOfTypeOfProduct(Form)
	
	SetSelectionByTypeOfProduct(Form);
	If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties Then
		EstablishSelectionAccordingToPropertiesOfTypeOfProduct(Form);
	EndIf;
	
EndProcedure

// Sets the selection by item type in the list of items on the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure SetSelectionByTypeOfProduct(Form)
	
	ProductKind = Form.ProductKind;
	FilterItems1 = TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts);
	
	// Set the selection by type of nomenclature.
	CommonClientServer.SetFilterItem(
		FilterItems1,
		"ProductKind",
		ProductKind,
		DataCompositionComparisonType.Equal, 
		"FilterByTheProductKind",
		True);
	
EndProcedure

// Sets selection by item type properties for the item list on the selection form.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form, selection form.
//
Procedure EstablishSelectionAccordingToPropertiesOfTypeOfProduct(Form)
	
	ThisIsFormOfMatching = SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode);
	ThisIsFormOfFeatureSelection = SelectGoodsClientServer.ThisIsFormOfFeatureSelection(Form.FormCode);
	
	FilterParameters = New Structure("Filter", True);
	
	SetSelectionOfListOfCharacteristics = False;
	
	If ThisIsFormOfFeatureSelection Then
		SetSelectionOfListOfCharacteristics = True;
		SelectingListOfCharacteristics = TMCommonUseClientServer.GetDynamicListSelection(Form.List);
	Else
		SelectingListOfProducts = TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts);
	EndIf;
	
	If ThisIsFormOfMatching And Form.UseItemVariants Then
		SetSelectionOfListOfCharacteristics = True;
		SelectingListOfCharacteristics = TMCommonUseClientServer.GetDynamicListSelection(Form.FeatureList);
	EndIf;
	
	RefName = "Ref.[";
	
	FilterParametersTable = Form.FilterParametersTable.Unload();
	FilterParametersTable = FilterParametersTable.Copy(FilterParameters);
	
	While FilterParametersTable.Count() <> 0 Do
		
		SelectionTreeString = FilterParametersTable[0];
		
		If SelectionTreeString.FixedValue Then
			
			// Generate the name of the selection element.
			FilterElementName = ?(SelectionTreeString.IsAddlAttribute,
									RefName + SelectionTreeString.AttributeName + "]",
									SelectionTreeString.AttributeName);
			
			// Depending on the type, set the value of the selection element.
			If TypeOf(SelectionTreeString.FilterValue) = Type("Boolean") Then
				
				If Not SelectionTreeString.FilterFeatures Then
					CommonClientServer.SetFilterItem(SelectingListOfProducts, FilterElementName, True,
						DataCompositionComparisonType.Equal,,True);
				ElsIf SetSelectionOfListOfCharacteristics Then
					CommonClientServer.SetFilterItem(SelectingListOfCharacteristics, FilterElementName, True,
						DataCompositionComparisonType.Equal,,True);
				EndIf;
				
			ElsIf TypeOf(SelectionTreeString.FilterValue) = Type("Date")
				Or TypeOf(SelectionTreeString.FilterValue) = Type("Number") Then
				
				If ValueIsFilled(SelectionTreeString.IntervalFrom) Then
					
					If Not SelectionTreeString.FilterFeatures Then
						AddFilterItem(SelectingListOfProducts, FilterElementName, SelectionTreeString.IntervalFrom,
							DataCompositionComparisonType.GreaterOrEqual);
					ElsIf SetSelectionOfListOfCharacteristics Then
						AddFilterItem(SelectingListOfCharacteristics, FilterElementName, SelectionTreeString.IntervalFrom,
							DataCompositionComparisonType.GreaterOrEqual);
					EndIf;
					
				EndIf;
				
				If ValueIsFilled(SelectionTreeString.IntervalTo) Then
					
					If Not SelectionTreeString.FilterFeatures Then
						AddFilterItem(SelectingListOfProducts, FilterElementName, SelectionTreeString.IntervalTo,
							DataCompositionComparisonType.LessOrEqual);
					ElsIf SetSelectionOfListOfCharacteristics Then
						AddFilterItem(SelectingListOfCharacteristics, FilterElementName, SelectionTreeString.IntervalTo,
							DataCompositionComparisonType.LessOrEqual);
					EndIf;
					
				EndIf;
				
			ElsIf TypeOf(SelectionTreeString.FilterValue) = Type("String") Then
				
				If Not SelectionTreeString.FilterFeatures Then
					CommonClientServer.SetFilterItem(SelectingListOfProducts, FilterElementName,
						SelectionTreeString.FilterValue, DataCompositionComparisonType.Equal,,True);
				ElsIf SetSelectionOfListOfCharacteristics Then
					CommonClientServer.SetFilterItem(SelectingListOfCharacteristics, FilterElementName,
						SelectionTreeString.FilterValue, DataCompositionComparisonType.Equal,,True);
				EndIf;
				
			ElsIf TypeOf(SelectionTreeString.FilterValue) = Type("ValueList") Then
				
				If Not SelectionTreeString.FilterFeatures Then
					CommonClientServer.SetFilterItem(SelectingListOfProducts, FilterElementName,
						SelectionTreeString.FilterValue, DataCompositionComparisonType.InList,,True);
				ElsIf SetSelectionOfListOfCharacteristics Then
					CommonClientServer.SetFilterItem(SelectingListOfCharacteristics, FilterElementName,
						SelectionTreeString.FilterValue, DataCompositionComparisonType.InList,,True);
				EndIf;
				
			EndIf;
			
			FilterParametersTable.Delete(SelectionTreeString);
			
		Else
			
			FilterParameters = New Structure("AttributeName", SelectionTreeString.AttributeName);
			
			RowsArray = FilterParametersTable.FindRows(FilterParameters);
			
			FIlterRow = RowsArray[0];
			FilterFeatures = FIlterRow.FilterFeatures;
			
			// Generate the name of the selection element.
			FilterElementName = ?(FIlterRow.IsAddlAttribute,
									RefName + FIlterRow.AttributeName + "]",
									FIlterRow.AttributeName);
			
			SelectionValues = New Array;
			
			For Each String In RowsArray Do
				SelectionValues.Add(String.FilterValue);
				FilterParametersTable.Delete(String);
			EndDo;
			
			If Not FilterFeatures Then 
				CommonClientServer.SetFilterItem(SelectingListOfProducts, FilterElementName,
					SelectionValues, DataCompositionComparisonType.InList, , True);
			ElsIf SetSelectionOfListOfCharacteristics Then
				CommonClientServer.SetFilterItem(SelectingListOfCharacteristics, FilterElementName,
					SelectionValues, DataCompositionComparisonType.InList, , True);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Disables the set selections by item type and by properties of the selected
// item type on the selection form.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form, selection form.
//
Procedure DeleteSelectionByProductTypeAndProductTypeProperties(Form)
	
	DeleteSelectionByProductType(Form);
	DeleteSelectionBasedOnProductTypeProperties(Form);
	
EndProcedure

// Removes selection by item type from the list of items on the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure DeleteSelectionByProductType(Form)
	
	ProductKind = Form.ProductKind;
	FilterItems1 = TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts);
	
	CommonClientServer.SetFilterItem(
		FilterItems1,
		"ProductKind",
		ProductKind,
		DataCompositionComparisonType.Equal, 
		"FilterByTheProductKind",
		False);
	
EndProcedure

// Deletes the set selections based on the item type properties.
// More precisely, all set selections on the list are deleted, except for those
// that do not belong to the selections of the property tree.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure DeleteSelectionBasedOnProductTypeProperties(Form)
	
	ThisIsFormOfMatching = SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode);
	ThisIsFormOfFeatureSelection = SelectGoodsClientServer.ThisIsFormOfFeatureSelection(Form.FormCode);
	ThisIsProductListForm = SelectGoodsClientServer.ThisIsProductListForm(Form.FormCode);
	ThisIsFormOfProductSelection = SelectGoodsClientServer.ThisIsFormOfProductSelection(Form.FormCode);
	
	// Some selection elements should not be deleted - they do not belong
	// to the selection by the properties of the type of nomenclature.
	NotItemsToRemove = SelectionElementsThatCannotBeDeleted();
	
	// Delete selection elements based on the properties of the item type.
	If ThisIsFormOfMatching Or ThisIsProductListForm Or ThisIsFormOfProductSelection Then
		
		SelectingListOfProducts = TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts).Items;
		UBound = SelectingListOfProducts.Count() - 1;
		
		For OBRIndex = 0 To UBound Do
			
		FilterElement = SelectingListOfProducts[UBound - OBRIndex];
			
			If NotItemsToRemove.Find(FilterElement.Presentation) = Undefined Then
				SelectingListOfProducts.Delete(FilterElement);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If (ThisIsFormOfMatching And Form.UseItemVariants) Or ThisIsFormOfFeatureSelection Then
		
		If ThisIsFormOfFeatureSelection Then
			SelectingListOfCharacteristics = TMCommonUseClientServer.GetDynamicListSelection(Form.List).Items;
		Else
			SelectingListOfCharacteristics = TMCommonUseClientServer.GetDynamicListSelection(Form.FeatureList).Items;
		EndIf;
		
		UBound = SelectingListOfCharacteristics.Count() - 1;
		
		For OBRIndex = 0 To UBound Do
			
			FilterElement = SelectingListOfCharacteristics[UBound - OBRIndex];
			
			If NotItemsToRemove.Find(FilterElement.Presentation) = Undefined Then
				SelectingListOfCharacteristics.Delete(FilterElement);
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Removes selection by item quality from the list of items on the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure DeleteProductQualitySelection(Form)
	
	CommonClientServer.DeleteDynamicListFilterGroupItems(
		Form.ListProducts, "Quality", "QualityOfProducts");
	
EndProcedure

// Sets selection by item segment on the selection form.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure SetSelectionByProductSegment(Form)
	
	// Selection by segment from the list of items.
	CommonClientServer.SetDynamicListParameter(
		Form.ListProducts, 
		"ProductSegment", 
		Form.ProductSegment, 
		ValueIsFilled(Form.ProductSegment));
		
EndProcedure

// Returns an array of element names that should not be deleted.
//
// Returns:
// 	Array of String - Array of selection names that should not be deleted
//
Function SelectionElementsThatCannotBeDeleted()
	
	NotItemsToRemove = New Array;
	
	NotItemsToRemove.Add("SearchBySubstring");
	NotItemsToRemove.Add("ItemsPrices");
	NotItemsToRemove.Add("PriceFeatures");
	NotItemsToRemove.Add("GroupOnlyInStock");
	NotItemsToRemove.Add("FilterByTheProductKind");
	NotItemsToRemove.Add("SelectionBasedOnCharacteristics");
	NotItemsToRemove.Add("FilterByProductType");
	NotItemsToRemove.Add("FilterDefault");
	NotItemsToRemove.Add("FilterAccountingFeature");
	NotItemsToRemove.Add("FilterProductTypeIS");
	NotItemsToRemove.Add("FilterItemsCollection");
	NotItemsToRemove.Add("SelectionTypeOfAlcoholicProductsLabeled");
	
	Return NotItemsToRemove
	
EndFunction

// Deletes the selection based on the original quality item.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure RemoveSelectionBySourceQualityProduct(Form)
	
	CommonClientServer.DeleteDynamicListFilterGroupItems(
		Form.ListProducts,,"GroupSelectionForGoodsOfInitialQuality");
	
EndProcedure

#EndRegion

#Region EventHandlersForElementsOnSelectionForms

// Called when switching to a page with a list of characteristics.
//
// Parameters:
//	Form - ClientApplicationForm - selection form,
//	ProductParameters_ - Structure - the parameters of an item for which you want to switch to the page with the list of characteristics.
//
Procedure WhenGoingToListOfCharacteristics(Form, ProductParameters_)
	
	ThisIsFormOfSelectionInPurchaseDocuments = SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode);
	ThisIsFormOfMatchingInSalesDocuments = SelectGoodsClientServer.ThisIsFormOfMatchingInSalesDocuments(Form.FormCode);
	
	Form.CharacteristicNavigation = True;
	
	// Set the parameters of the list of characteristics.
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "Products", ProductParameters_.Products);
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "UnitOfMeasure", ProductParameters_.UnitOfMeasure);
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "ItemVariantsOwner", ProductParameters_.ItemVariantsOwner);
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "ItemsType", ProductParameters_.ItemsType);
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "ProductKind", ProductParameters_.ProductKind);
	
	If Not ThisIsFormOfSelectionInPurchaseDocuments Then
		CommonClientServer.SetDynamicListParameter(
			Form.FeatureList, "PriceGroup", ProductParameters_.PriceGroup);
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "ProductSegment", 
		Form.ProductSegment, ValueIsFilled(Form.ProductSegment));
	
	CommonClientServer.SetDynamicListParameter(
		Form.FeatureList, "SegmentProducts", 
		ProductParameters_.Products, ValueIsFilled(Form.ProductSegment));
	
	// Set the selection of a list of characteristics for goods sold together.
	If ThisIsFormOfMatchingInSalesDocuments Then
		
		ArrayOfCharacteristics = New Array;
		
		For Each TSRow In Form.TableItemSoldJointly Do
			If TSRow.Products = ProductParameters_.Products Then
				ArrayOfCharacteristics.Add(TSRow.Characteristic);
			EndIf;
		EndDo;
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.FeatureList, "Characteristic",
			ArrayOfCharacteristics, DataCompositionComparisonType.InList,, ArrayOfCharacteristics.Count() > 0);
			
	EndIf;
	
	CurrentPageName = SelectGoodsClientServer.CurPageNameBySearchOption(Form);
	CurrentPage = Form.Items[CurrentPageName];
	
	Form.Items.PagesOfLists.CurrentPage = CurrentPage;
	Form.CurrentItem = Form.Items[SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(Form)];
	Form.Items.ProductSegment.ReadOnly = True;
	
	If ThisIsFormOfSelectionInPurchaseDocuments Then
		HowToCreateCharacteristic = (Form.CharacteristicNavigation And Not Form.NavigationThroughThePartnerSProductRange);
	Else
		HowToCreateCharacteristic = Form.CharacteristicNavigation;
	EndIf;
	
	CommonClientServer.SetFormItemProperty(Form.Items, "CommandBarCreateCharacteristic", "Enabled", HowToCreateCharacteristic);
	
	Form.Items.PagesCreate.CurrentPage = Form.Items.PageCreateCharacteristic;
	
	SelectGoodsClientServer.SetAvailabilityOfFilterElements(Form);
	
EndProcedure

#EndRegion

#Region SelectionsBasedOnAvailabilityAndPrices

// Returns True if the supplier's price condition on the selection form was changed
// from the previously set value.
//
// Parameters:
//	Form - See WhenCreatingMatchingFormOnServer.Form
//
Function SupplierPriceViewChanged(Form)
	
	ParameterName = "VendorPriceKind";
	
	ParameterValue = Form.ListOfThePartnerSNomenclature.Parameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	
	If ParameterValue = Undefined Then
		
		If Not ValueIsFilled(Form.VendorPriceKind) Then
			Return False;
		EndIf;
		
		Return True;
		
	EndIf;
	
	Return Not (ParameterValue.Value = Form.VendorPriceKind);
	
EndFunction

#EndRegion

#Region AuxiliarySelections

// Returns True if the item segment on the selection form was changed
// from the previously set value.
//
// Parameters:
//	Form - See WhenCreatingMatchingFormOnServer.Form
//
Function ProductSegmentChanged(Form)
	
	ParameterValue = Form.ListProducts.Parameters.FindParameterValue(New DataCompositionParameter("ProductSegment"));
	
	If ParameterValue = Undefined Then
		
		If Not ValueIsFilled(Form.ProductSegment) Then
			Return False;
		EndIf;
		
		Return True;
		
	EndIf;
	
	Return (ParameterValue.Value <> Form.ProductSegment Or Not ParameterValue.Use);
	
EndFunction

#EndRegion

#Region SearchOnSelectionForms

Function FullTextSearchResult(Form, SearchParameters)
	
	SearchResult = SearchResults(SearchParameters.SearchAreas);
	
	// Create a search list.
	SearchResultsList = FullTextSearch.CreateList(SearchParameters.SearchString);
	SearchResultsList.GetDescription = False;
	SearchResultsList.MetadataUse = FullTextSearchMetadataUse.DontUse;
	
	SearchAreas = New Array;
	For Each ArrRow In SearchParameters.SearchAreas Do
		SearchAreas.Add(ArrRow.MetadataObject);
	EndDo;
	SearchResultsList.SearchArea = SearchAreas;
	
	Try
		SearchResultsList.FirstPart();
	Except
		SearchResult.ErrorCode = "SearchError";
		Return SearchResult;
	EndTry;
	
	If SearchResultsList.TooManyResults() Then
		SearchResult.ErrorCode = "TooManyResults";
		Return SearchResult;
	EndIf;
	
	NumberOfResults = SearchResultsList.TotalCount();
	
	If NumberOfResults = 0 Then
		SearchResult.ErrorCode = "FoundNothing";
		Return SearchResult;
	EndIf;
	
	If NumberOfResults > MaximumNumberOfSearchElements() Then
		SearchResult.ErrorCode = "TooManyResults";
		Return SearchResult;
	EndIf;
	
	// Go through the search list.
	PortionSize = 20;
	StartPosition = 0;
	UBound = ?(NumberOfResults > PortionSize, PortionSize, NumberOfResults) - 1;
	
	HasNextBatch = True;
	
	While HasNextBatch Do
		For Number = 0 To UBound Do
			ListItem = SearchResultsList.Get(Number);
			ProcessSearchListItem(ListItem, SearchResult);
		EndDo;
		
		StartPosition = StartPosition + PortionSize;
		HasNextBatch = (StartPosition < NumberOfResults - 1);
		
		If HasNextBatch Then
			UBound = ?(NumberOfResults > (StartPosition + PortionSize), PortionSize, NumberOfResults - StartPosition) - 1;
			SearchResultsList.NextPart();
		EndIf;
	EndDo;
	
	Return SearchResult;
	
EndFunction

// Returns the result of the item search.
//
// Parameters:
// 	Form - ClientApplicationForm - selection form, list form.
// 	SearchParameters - Structure:
// 		* SearchAreas - Structure:
// 			** AreaSearchRequestText - String
//
// Returns:
//	Structure - product search result.
//
Function IncompleteTextSearchResult(Form, SearchParameters)
	
	Query = New Query;
	AreaSearchRequestTexts = New Array;
	
	For Each SearchArea In SearchParameters.SearchAreas Do
		AreaSearchRequestTexts.Add(SearchArea.AreaSearchRequestText);
		
		For Each KeyValue In SearchArea.AreaSearchRequestParameters Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
		
	EndDo;
	
	QueryText = StrConcat(AreaSearchRequestTexts, Common.QueryBatchSeparator());

	ConditionText = "%ComparisonType% &SearchString %Special_Character%";
	ConditionText = StrReplace(ConditionText,
		"%ComparisonType%",
		?(SearchParameters.ExactCompliance,
			"=",
			"LIKE")); //@Query-part
	ConditionText = StrReplace(ConditionText, "%Special_Character%",
		?(SearchParameters.ExactCompliance,
			"",
			"ESCAPE ""~""")); //@Query-part
	
	QueryText = StrReplace(QueryText, "999", Format(MaximumNumberOfSearchElements() + 1, "ND=10; NG=0"));
	QueryText = StrReplace(QueryText, "= &ComparisonCondition", ConditionText);

	Query.Text = QueryText;
	Query.SetParameter("SearchString", SearchParameters.SearchString);
	
	If SearchParameters.Property("AdditionalParameters") Then
		For Each KeyValue In SearchParameters.AdditionalParameters Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	QueryResults = Query.ExecuteBatch(); 
	SearchResult = SearchResults(SearchParameters.SearchAreas);
	
	NumberOfResults = 0;
	
	// Add the found items to the search list. As soon as the number of items in the list
	// exceeds the maximum number of items found, abort the crawl cycle.
	For Each QueryResult In QueryResults Do
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			SearchItem = New Structure("Value, Metadata");
			FillPropertyValues(SearchItem, Selection);
			
			ProcessSearchListItem(SearchItem, SearchResult);
			NumberOfResults = NumberOfResults + 1;
			
			If NumberOfResults > MaximumNumberOfSearchElements() Then
				Break;
			EndIf;
		EndDo;
		
		If NumberOfResults > MaximumNumberOfSearchElements() Then
			Break;
		EndIf;
	EndDo;
	
	If NumberOfResults > MaximumNumberOfSearchElements()  Then
		SearchResult.ErrorCode = "TooManyResults";
	ElsIf NumberOfResults = 0 Then
		SearchResult.ErrorCode = "FoundNothing";
	Else
		SearchResult.ErrorCode = "";
	EndIf;
		
	Return SearchResult;
	
EndFunction

// Checks whether an item in the search list
// belongs to the metadata type, and includes the item
// 's value in the appropriate section of the search result.
//
// Parameters:
//	ListItem - ValueListItem - element of the search list,
//	SearchResult - Structure - structure of search results.
//
Procedure ProcessSearchListItem(ListItem, SearchResult)
	
	ItemMetadata = ListItem.Metadata;
	ElementValue = ListItem.Value;
	
	If TypeOf(ItemMetadata) = Type("MetadataObject") Then
		SearchAreaName = ItemMetadata.Name;
	Else
		SearchAreaName = ItemMetadata;
	EndIf;
	SearchResultSearchAreaName = SearchResult[SearchAreaName]; // See DescriptionsOfSearchAreas
	SearchResultSearchAreaName.Add(ElementValue);
	
EndProcedure

// Returns an array of product search areas.
//
// Parameters:
// 	Form - ClientApplicationForm - the form from which the search function was called.
// 	SearchParameters - Structure:
// 		* SearchAreas - Structure:
// 			** AreaSearchRequestText - String
//
// Returns:
// 	Array of See SearchAreaDescription - An array of metadata, product search areas.
//
Function DescriptionsOfSearchAreas(Form, SearchParameters)
	
	// Depending on which form the search function is called from,
	// the list of search areas will vary.
	SearchAreas = New Array;
	
	If SearchParameters.SearchListName = "Products" Then
		
		SearchAreaDescription                             = SearchAreaDescription();
		SearchAreaDescription.MetadataObject            = Metadata.Catalogs.Products;
		SearchAreaDescription.AreaSearchRequestText =
		"SELECT TOP 999
		|	CatalogProducts.Ref AS Value,
		|	""Products"" AS Metadata
		|FROM
		|	Catalog.Products AS CatalogProducts
		|WHERE
		|	NOT CatalogProducts.IsFolder AND
		|	(CatalogProducts.Description = &ComparisonCondition
		|			OR CatalogProducts.DescriptionFull = &ComparisonCondition
		|			OR CatalogProducts.Code = &ComparisonCondition
		|			OR CatalogProducts.SearchCode = &ComparisonCondition
		|			OR CatalogProducts.SKU = &ComparisonCondition)";

		If SearchParameters.Property("AdditionalConditions") Then
			SearchAreaDescription.AreaSearchRequestText = SearchAreaDescription.AreaSearchRequestText +
				"
				|	AND " + StrConcat(SearchParameters.AdditionalConditions, " And ");
		EndIf;
		
		SearchAreaDescription.TextOfProductSearchQuery = "";
		SearchAreas.Add(SearchAreaDescription);
		
		SearchAreaDescription                             = SearchAreaDescription();
		SearchAreaDescription.MetadataObject            = Metadata.InformationRegisters.ItemsBarcodes;
		SearchAreaDescription.AreaSearchRequestText =
		"SELECT TOP 999
		|	ItemsBarcodes.Barcode AS Value,
		|	""ItemsBarcodes"" AS Metadata
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|WHERE
		|	ItemsBarcodes.Barcode = &BarcodeSearchBar";
		SearchAreaDescription.AreaSearchRequestParameters.Insert("BarcodeSearchBar",
		OriginalSearchString(SearchParameters.SearchString, Form.FindAnItemByExactMatch));
		
		SearchAreaDescription.TextOfProductSearchQuery =
		"SELECT
		|	ItemsBarcodes.Products AS Products
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|WHERE
		|	ItemsBarcodes.Barcode IN(&ItemsBarcodes)";
		SearchAreas.Add(SearchAreaDescription);
		
		If GetFunctionalOption("UseSalesForExport")
			Or GetFunctionalOption("UseImports") Then
			
			SearchAreaDescription                             = SearchAreaDescription();
			SearchAreaDescription.MetadataObject            = Metadata.Catalogs.FEACN;
			SearchAreaDescription.AreaSearchRequestText =
			"SELECT TOP 999
			|	FEACN.Ref AS Value,
			|	""FEACN"" AS Metadata
			|FROM
			|	Catalog.FEACN AS FEACN
			|WHERE
			|	FEACN.Code = &ComparisonCondition";
			SearchAreaDescription.TextOfProductSearchQuery =
			"SELECT
			|	Products.Ref AS Products
			|FROM
			|	Catalog.Products AS Products
			|		INNER JOIN Catalog.FEACN AS FEACN
			|		ON Products.FEACNCode = FEACN.Ref
			|WHERE
			|	FEACN.Ref IN(&FEACN)";
			SearchAreas.Add(SearchAreaDescription);
			
		EndIf;
		
	EndIf;
		
	If (SearchParameters.SearchListName = "Products"
		Or SearchParameters.SearchListName = "ProductCrossReferences")
		And SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode) Then
		
		SearchAreaDescription                             = SearchAreaDescription();
		SearchAreaDescription.MetadataObject            = Metadata.Catalogs.ProductCrossReferences;
		SearchAreaDescription.AreaSearchRequestText =
		"SELECT ALLOWED TOP 999
		|	ProductCrossReferences.Ref AS Value,
		|	""ProductCrossReferences"" AS Metadata
		|FROM
		|	Catalog.ProductCrossReferences AS ProductCrossReferences
		|WHERE
		|	NOT ProductCrossReferences.IsFolder AND
		|	(ProductCrossReferences.SKU = &ComparisonCondition
		|		OR ProductCrossReferences.Description = &ComparisonCondition)
		|	AND ProductCrossReferences.Owner = &Partner";
		
		SearchAreaDescription.AreaSearchRequestParameters.Insert("Partner", Form.SupplierPartner);
		
		SearchAreaDescription.TextOfProductSearchQuery =
		"SELECT
		|	ProductCrossReferences.Products AS Products
		|FROM
		|	Catalog.ProductCrossReferences AS ProductCrossReferences
		|WHERE
		|	ProductCrossReferences.Ref IN(&ProductCrossReferences)";
		SearchAreas.Add(SearchAreaDescription);
	EndIf;

	If SearchParameters.SearchListName = "ItemsCharacteristics" Then
		SearchAreaDescription                             = SearchAreaDescription();
		SearchAreaDescription.MetadataObject            = Metadata.Catalogs.ItemsCharacteristics;
		SearchAreaDescription.AreaSearchRequestText =
		"SELECT TOP 999
		|	ItemsCharacteristics.Ref AS Value,
		|	""ItemsCharacteristics"" AS Metadata
		|FROM
		|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|WHERE
		|	ItemsCharacteristics.Description = &ComparisonCondition
		|	OR ItemsCharacteristics.DescriptionFull = &ComparisonCondition";
		SearchAreaDescription.TextOfProductSearchQuery = "";
		SearchAreas.Add(SearchAreaDescription);
		
	EndIf;
	
	ProductsLocalization.DescriptionsOfSearchAreas(SearchAreas, Form, SearchParameters);	
	
	Return SearchAreas;
	
EndFunction

// Returns the structure of search results.
// Used for non-full-text product search.
// 
// Parameters:
// 		SearchAreas - See DescriptionsOfSearchAreas
// 		
// Returns:
//		Structure:
//			* ErrorCode - String
//			* SearchAreas - See DescriptionsOfSearchAreas
//			* Products - Array of Arbitrary
//
Function SearchResults(SearchAreas)
	
	SearchResult = New Structure();
	
	SearchResult.Insert("ErrorCode", "");
	SearchResult.Insert("SearchAreas", SearchAreas);
	For Each ArrRow In SearchAreas Do
		SearchResult.Insert(ArrRow.MetadataObject.Name, New Array);
	EndDo;
	
	Return SearchResult;
	
EndFunction

// Returns the maximum number of elements that can be processed
// when performing a full-text or non-full-text search. If the number
// of elements found exceeds the value returned by this function, it is assumed that the search condition is set
// blurry and it is suggested to Refine it.
//
Function MaximumNumberOfSearchElements()
	
	Return 500;
	
EndFunction

// Performs additional processing of search results:
// if the search was performed by characteristics, barcodes, or
// supplier nomenclature, the procedure performs an additional query to search
// for the item owners of the found items. The found item
// is included in the search result in the "item"section.
//
// Parameters:
// 		SearchResult - See SearchResults
//
Procedure AddProductSearchResults(SearchResult)
	
	// If the characteristics of the item, the nomenclature of suppliers, or the barcodes
	// of the item are found, then you need to find the owners for them and add them to the list of nomenclature.
	Query = New Query;
	ProductSearchQueryTexts = New Array;
	
	For Each ArrRow In SearchResult.SearchAreas Do
		If Not IsBlankString(ArrRow.TextOfProductSearchQuery)
			And SearchResult[ArrRow.MetadataObject.Name].Count() > 0 Then
			
			ProductSearchQueryTexts.Add(ArrRow.TextOfProductSearchQuery);
			
			SearchData = SearchResult[ArrRow.MetadataObject.Name];
			If SearchData.Count() > 0
				And TypeOf(SearchData[0]) = Type("InformationRegisterRecordKey.ItemsBarcodes") Then
				
				ParameterValue = New Array;
				
				For Each SearchValue In SearchData Do
					ParameterValue.Add(SearchValue.Barcode);
				EndDo;
				
			Else
				ParameterValue = SearchResult[ArrRow.MetadataObject.Name];
			EndIf;
			
			Query.SetParameter(ArrRow.MetadataObject.Name, ParameterValue)
			
		EndIf;
	EndDo;
	
	If ProductSearchQueryTexts.Count() > 0 Then
		Query.Text = StrConcat(ProductSearchQueryTexts, TMCommonUse.QuerySeparatorInJoin());
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			SearchResult.Products.Add(Selection.Products);
		EndDo;
	EndIf;
	
EndProcedure

// Returns the original search string that was entered on the search form.
// Used for non-full-text search.
//
// Parameters:
//	SearchString - String - search string,
//	ExactMap - Boolean - indicates whether to search for an exact match.
//
// Returns:
//	String - The original search string.
//
Function OriginalSearchString(Val SearchString, ExactMap)
	
	If ExactMap Then
		Return SearchString;
	EndIf;
	
	Return Mid(SearchString, 2, StrLen(SearchString) - 2);
	
EndFunction

// Returns a formatted search string - a string with the addition of service characters.
// Used for incomplete text search.
//
// Parameters:
//	SearchString - String - search bar.
//	UseFullTextSearch - Boolean - indicates whether full-text search is used.
//	ExactMap - Boolean - indicates whether to search for an exact match.
//
// Returns:
//	String - Formatted search string.
//
Function FormatSearchString(Val SearchString, UseFullTextSearch, ExactMap)
	
	If ExactMap
		Or UseFullTextSearch
		Or Not ValueIsFilled(SearchString) Then
		
		Return SearchString;
		
	EndIf;
	
	SearchString = MaskSpecialSimilarityCharacters(SearchString);
	
	If Left(SearchString, 1) <> "%" Then
		SearchString = "%" + SearchString;
	EndIf;
	
	If Right(SearchString, 1) <> "%" Then
		SearchString = SearchString + "%";
	EndIf;
	
	Return SearchString;
	
EndFunction

Function MaskSpecialSimilarityCharacters(Text)
	Result = Text;
	
	SPECCHARACTER = "~";
	Utilities  = SPECCHARACTER + "%_[]^";
	
	For IndexOf = 1 To StrLen(Utilities) Do
		Char = Mid(Utilities, IndexOf, 1);
		Result = StrReplace(Result, Char, SPECCHARACTER + Char);
	EndDo;
		
	Return Result;
EndFunction

#EndRegion

#Region ProceduresAndFunctionsForSavingAndRestoringSettings

// Returns the structure - values of settings for the list form and the product selection form.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form.
//
// Returns:
//	Structure - The values of the settings of the list form, the selection form.
//
Function FormSettings(Form)
	
	FormSettings = New Structure;
	
	FormSettings.Insert("UseFilters", Form.UseFilters);
	If Not (Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsOfAnotherQuality
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsSoldTogether
		Or Form.NavigationOption = Enums.ItemFormNavigationOptions.ByVendorHierarchy) Then
		
		FormSettings.Insert("NavigationOption", Form.NavigationOption);
	Else
		FormSettings.Insert("NavigationOption", Enums.ItemFormNavigationOptions.EmptyRef());
	EndIf;
	FormSettings.Insert("ProductKind", Form.ProductKind);
	FormSettings.Insert("CurrentProductsHierarchy", Form.CurrentProductsHierarchy);
		
	// Saving the selection parameters.
	If SelectGoodsClientServer.ThisIsProductListForm(Form.FormCode)
		Or SelectGoodsClientServer.ThisIsFormOfProductSelection(Form.FormCode) Then
		
		FormSettings.Insert("FilterParametersTable", Form.FilterParametersTable.Unload());
		FormSettings.Insert("ProductsOfOriginalQuality", Form.ProductsOfOriginalQuality);
		
	EndIf;
	
	FormSettings.Insert("ProductSearchOptionIsSet", True);
	
	Return FormSettings;
	
EndFunction

// Returns the structure - values of the product selection form settings.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
// Returns:
//	Structure - Values of the selection form settings.
//
Function SelectionFormSettings(Form)
	
	SelectionFormSettings = FormSettings(Form);
	
	SelectionFormSettings.Insert("RequestQuantity", Form.RequestQuantity);
	
	If SelectGoodsClientServer.ThisIsFormOfMatchingInSalesDocuments(Form.FormCode) Then
		SelectionFormSettings.Insert("RequestPrice", Form.RequestPrice);
	EndIf;
	
	If SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode) Then
		SelectionFormSettings.Insert("UseThePartnerItemFilter_3", Form.UseThePartnerItemFilter_3);
		SelectionFormSettings.Insert("CurrentPartnerItemHierarchy", Form.CurrentPartnerItemHierarchy);
	EndIf;
	
	SelectionFormSettings.Insert("ShowBalance", Form.ShowBalance);
	SelectionFormSettings.Insert("ShowSelectedGoods", Form.ShowSelectedGoods);
	SelectionFormSettings.Insert("OnlyInStock", Form.OnlyInStock);

	If SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode) Then
		SelectionFormSettings.Insert("FilterParametersTable", Form.FilterParametersTable.Unload());
		SelectionFormSettings.Insert("ProductsOfOriginalQuality", Form.ProductsOfOriginalQuality);
	EndIf;
	
	Return SelectionFormSettings;
	
EndFunction

// Saves the values of selection lists on list forms and selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - form the list form of selection.
//
Procedure SaveSelectionLists(Form)
	
	SelectionListsClientServer.Save("ProductSearchHistory", Form.Items.SearchStringProducts.ChoiceList);
	SelectionListsClientServer.Save("HistoryOfProductSegmentSelection", Form.Items.ProductSegment.ChoiceList);
	
EndProcedure

// Restores the value of details on the form from the General settings store.
//
// Parameters:
//	Form - See WhenCreatingMatchingFormOnServer.Form
//
Procedure SetValuesForFormSettings(Form)
	
	ThisIsFormOfMatching = SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode);
	ThisIsFormOfSelectionInPurchaseDocuments = SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode);
	ThisIsFormOfSimilarGoodsProduct = SelectGoodsClientServer.ThisIsFormOfSimilarGoodsProduct(Form.FormCode);
	
	// Set default values.
	Form.UseFilters = True;
	Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties;
	
	Form.ProductKind = Catalogs.ItemKinds.EmptyRef();
	Form.CurrentProductsHierarchy = Catalogs.Products.EmptyRef();
	
	// Get the product search option setting.
	SettingsProductSearchOption = Common.CommonSettingsStorageLoad("GoodsSearchOption",  "");
	
	If SettingsProductSearchOption = Undefined Then
		Form.GoodsSearchOption = "Default";
	Else
		Form.GoodsSearchOption = SettingsProductSearchOption;
	EndIf;
	
	// If there are saved settings, then set the values according to the settings.
	Settings = Common.CommonSettingsStorageLoad(Form.FormCode,  "");
	
	If Settings <> Undefined Then
		
		If Settings.Property("UseFilters") Then
			Form.UseFilters = Settings.UseFilters;
		EndIf;
		
		If Settings.Property("UseThePartnerItemFilter_3") Then
			Form.UseThePartnerItemFilter_3 = Settings.UseThePartnerItemFilter_3;
		EndIf;
		
		If Settings.Property("NavigationOption")
			And ValueIsFilled(Settings.NavigationOption) Then

			If TypeOf(Settings.NavigationOption) = Type("String") Then
				If Metadata.Enums.ItemFormNavigationOptions.EnumValues.Find(Settings.NavigationOption) = Undefined Then
					NavigationOption = Form.NavigationOption;
				Else
					NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions." + Settings.NavigationOption);
				EndIf;
			ElsIf TypeOf(Settings.NavigationOption) = Type("EnumRef.ItemFormNavigationOptions") Then
				NavigationOption = Settings.NavigationOption;
			Else
				NavigationOption = Form.NavigationOption;
			EndIf;
			
			If Not (NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsOfAnotherQuality
				Or NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsSoldTogether
				Or NavigationOption = Enums.ItemFormNavigationOptions.ByVendorHierarchy) Then
				Form.NavigationOption = NavigationOption;
			EndIf;
			
			If ThisIsFormOfSimilarGoodsProduct Then
				Form.NavigationOption = Enums.ItemFormNavigationOptions.ByProperties;
			EndIf;
		EndIf;
		
		If Settings.Property("FilterParametersTable") Then
			If ValueIsFilled(Settings.FilterParametersTable) Then
				Form.FilterParametersTable.Load(Settings.FilterParametersTable);
			EndIf;
		EndIf;
		
		If Settings.Property("ProductKind") Then
			
			If ValueIsFilled(Settings.ProductKind) Then
				
				// Check that the reference points to an existing object.
				If Settings.ProductKind.GetObject() <> Undefined Then
					
					Form.ProductKind = Settings.ProductKind;
					
					If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByHierarchy Then
						
						FillInProductSelectionTree(Form);
						
					EndIf;
					
					If Form.NavigationOption = Enums.ItemFormNavigationOptions.ByGoodsOfAnotherQuality Then
						
						FillInProductSelectionTree(Form);
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If Settings.Property("CurrentProductsHierarchy") Then
			If ValueIsFilled(Settings.CurrentProductsHierarchy) Then
				// Check that the reference points to an existing object.
				If Not (Settings.CurrentProductsHierarchy.GetObject() = Undefined) Then
					Form.Items.ProductsHierarchy.CurrentRow = Settings.CurrentProductsHierarchy;
					Form.CurrentProductsHierarchy = Settings.CurrentProductsHierarchy;
				EndIf;
			EndIf;
		EndIf;
		
		If Settings.Property("CurrentPartnerItemHierarchy") Then
			If ValueIsFilled(Settings.CurrentPartnerItemHierarchy) Then
				// Check that the reference points to an existing object.
				If Not (Settings.CurrentPartnerItemHierarchy.GetObject() = Undefined) Then
					Form.Items.TheHierarchyOfItemPartner.CurrentRow = Settings.CurrentPartnerItemHierarchy;
					Form.CurrentPartnerItemHierarchy = Settings.CurrentPartnerItemHierarchy;
				EndIf;
			EndIf;
		EndIf;
		
		If Settings.Property("ProductsOfOriginalQuality") Then
			If ValueIsFilled(Settings.ProductsOfOriginalQuality) Then
				If Not (Settings.ProductsOfOriginalQuality.GetObject() = Undefined) Then
					Form.ProductsOfOriginalQuality = Settings.ProductsOfOriginalQuality;
				EndIf;
			EndIf;
		EndIf;
		
		If Not Settings.Property("ProductSearchOptionIsSet") Then
			Form.GoodsSearchOption = "Default";
		EndIf;
		
	EndIf;
	
	// Set the page of the navigation option for the list of items.
	SetNavigationOptionPage(Form);
	
	WhenChangingUseOfFilters(Form);
	
	SelectionListsClientServer.Load("ProductSearchHistory", Form.Items.SearchStringProducts.ChoiceList);
	
	If ThisIsFormOfMatching Then
		SelectionListsClientServer.Load("ProductSearchHistory", Form.Items.SearchBarCharacteristics.ChoiceList);
		SelectionListsClientServer.Load("HistoryOfProductSegmentSelection", Form.Items.ProductSegment.ChoiceList);
	EndIf;
	
	If ThisIsFormOfSelectionInPurchaseDocuments Then
		SelectionListsClientServer.Load("ProductSearchHistory", Form. Items.SearchBarPartnerItem.ChoiceList);
	EndIf;
	
EndProcedure

// Sets if necessary to save the selection form settings to the settings store.
//
// Parameters:
//	Form - See WhenCreatingMatchingFormOnServer.Form
//
Procedure SetNeedToSaveSettings(Form)
	
	If SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode)
			And Form.FormSettingsWhenOpening <> Undefined Then
		Form.FormSettingsWhenOpening.SavingIsRequired = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForFillingOutFormsByParameters

// Processes the value passed in the form parameters for selecting the item list by item type.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetSelectionByTypeOfProductByParameters_(Form)
	
	ThisIsFormOfMatchingInSalesDocuments = SelectGoodsClientServer.ThisIsFormOfMatchingInSalesDocuments(Form.FormCode);
	ThisIsFormOfSelectionInPurchaseDocuments = SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode);
	ThisIsFormOfProductSelection = SelectGoodsClientServer.ThisIsFormOfProductSelection(Form.FormCode);
	
	If ThisIsFormOfMatchingInSalesDocuments Or ThisIsFormOfSelectionInPurchaseDocuments Then
		
		If Form.Parameters.FilterByProductType = Undefined Then
			Return;
		Else
			SelectionByProductTypeFromParameters = Form.Parameters.FilterByProductType;
		EndIf;
		
	ElsIf ThisIsFormOfProductSelection Then
		
		Form.Parameters.Filter.Property("ItemsType", SelectionByProductTypeFromParameters);
		Form.Parameters.Filter.Delete("ItemsType");
		
		If SelectionByProductTypeFromParameters = Undefined Then
			Return;
		EndIf;
		
	Else
		Return;
	EndIf;
	
	If ThisIsFormOfMatchingInSalesDocuments Then
		FilterByProductType = Form.FilterByProductType;
	Else
		FilterByProductType = New ValueList;
	EndIf;
		
	// The <Selection Type of Nomenclature> parameter is of any type. Either a separate
	// item type or an array of types can be passed.
	If TypeOf(SelectionByProductTypeFromParameters) = Type("EnumRef.ItemsTypes") Then
		
		FilterByProductType.Add(SelectionByProductTypeFromParameters);
		
	ElsIf TypeOf(SelectionByProductTypeFromParameters) = Type("FixedArray") Then
		
		For Each Value In SelectionByProductTypeFromParameters Do
			FilterByProductType.Add(Value);
		EndDo;
		
	ElsIf TypeOf(SelectionByProductTypeFromParameters) = Type("Array") Then
		
		FilterByProductType.LoadValues(SelectionByProductTypeFromParameters);
		
	ElsIf TypeOf(SelectionByProductTypeFromParameters) = Type("ValueList") Then
		
		FilterByProductType.LoadValues(SelectionByProductTypeFromParameters.UnloadValues());
		
	Else
		Return;
	EndIf;
	
	ContainsSet = False;
	SelectionsByProductTypeWithoutSets = New ValueList;
	SelectionsByProductTypeWithoutSets.LoadValues(FilterByProductType.UnloadValues());
	If SelectionsByProductTypeWithoutSets.FindByValue(Enums.ItemsTypes.Set) <> Undefined Then
		ContainsSet = True;
		SelectionsByProductTypeWithoutSets.Delete(SelectionsByProductTypeWithoutSets.FindByValue(Enums.ItemsTypes.Set));
	EndIf;
	
	If Not ContainsSet Then
		
		// Set selection by item types for the item list.
		CommonClientServer.SetDynamicListFilterItem(
			Form.ListProducts, "ItemsType", FilterByProductType, 
			DataCompositionComparisonType.InList, "FilterByProductType", (FilterByProductType.Count() > 0));
		
		If ThisIsFormOfSelectionInPurchaseDocuments Then
			CommonClientServer.SetDynamicListFilterItem(
				Form.ListOfThePartnerSNomenclature, "ItemsType", FilterByProductType, 
				DataCompositionComparisonType.InList, "FilterByProductType", (FilterByProductType.Count() > 0));
		EndIf;
		
	Else
		
		LimitSetsByService = SelectionsByProductTypeWithoutSets.FindByValue(Enums.ItemsTypes.OperationService) <> Undefined
		                          Or SelectionsByProductTypeWithoutSets.FindByValue(Enums.ItemsTypes.Work_5) <> Undefined;
		LimitSetsByProduct = SelectionsByProductTypeWithoutSets.FindByValue(Enums.ItemsTypes.ReusablePackage) <> Undefined
		                          Or SelectionsByProductTypeWithoutSets.FindByValue(Enums.ItemsTypes.OwnGoods) <> Undefined;
		
		If LimitSetsByService And Not LimitSetsByProduct Then
			
			SelectionGroupSets = CommonClientServer.CreateFilterItemGroup(
				TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts).Items,
				"FilterByProductType", DataCompositionFilterItemsGroupType.OrGroup);
				
			// Type of the Goods and Services product range, Packaging
			CommonClientServer.SetFilterItem(
				SelectionGroupSets,
				"ItemsType", SelectionsByProductTypeWithoutSets, DataCompositionComparisonType.InList,,(SelectionsByProductTypeWithoutSets.Count() > 0));
				
			// Sets without characteristics
			SelectionGroupSetsNested = CommonClientServer.CreateFilterItemGroup(
				SelectionGroupSets.Items,
				"SelectionGroupSetsNested", DataCompositionFilterItemsGroupType.AndGroup);
				
			CommonClientServer.SetFilterItem(
				SelectionGroupSetsNested,
				"ItemsType", Enums.ItemsTypes.Set, DataCompositionComparisonType.Equal,, True);
				
			CommonClientServer.SetFilterItem(
				SelectionGroupSetsNested,
				"ContainsServices", True, DataCompositionComparisonType.Equal,, True);
				
			CommonClientServer.SetFilterItem(
				SelectionGroupSetsNested,
				"ContainsGoods", False, DataCompositionComparisonType.Equal,, True);
				
			CommonClientServer.SetFilterItem(
				SelectionGroupSetsNested,
				"UseVariants", Enums.ItemVariantsUsageOptions.DontUse, DataCompositionComparisonType.Equal,, True);
				
			// Sets with characteristics
			SelectionGroupNestedWithCharacteristics = CommonClientServer.CreateFilterItemGroup(
				SelectionGroupSets.Items,
				"SelectionGroupSetsWithNestedCharacteristics", DataCompositionFilterItemsGroupType.AndGroup);
				
			CommonClientServer.SetFilterItem(
				SelectionGroupNestedWithCharacteristics,
				"ItemsType", Enums.ItemsTypes.Set, DataCompositionComparisonType.Equal,, True);
				
			CommonClientServer.SetFilterItem(
				SelectionGroupNestedWithCharacteristics,
				"UseVariants", Enums.ItemVariantsUsageOptions.DontUse, DataCompositionComparisonType.NotEqual,, True);
				
			If ThisIsFormOfMatchingInSalesDocuments Then
				
				SelectionGroupSets = CommonClientServer.CreateFilterItemGroup(
					TMCommonUseClientServer.GetDynamicListSelection(Form.FeatureList).Items,
					"FilterByProductType", DataCompositionFilterItemsGroupType.OrGroup);
					
				// Type of the Goods and Services product range, Packaging
				CommonClientServer.SetFilterItem(
					SelectionGroupSets,
					"ItemsType", SelectionsByProductTypeWithoutSets, DataCompositionComparisonType.InList,,(SelectionsByProductTypeWithoutSets.Count() > 0));
					
				// Sets without characteristics
				SelectionGroupSetsNested = CommonClientServer.CreateFilterItemGroup(
					SelectionGroupSets.Items,
					"SelectionGroupSetsNested", DataCompositionFilterItemsGroupType.AndGroup);
					
				CommonClientServer.SetFilterItem(
					SelectionGroupSetsNested,
					"ItemsType", Enums.ItemsTypes.Set, DataCompositionComparisonType.Equal,, True);
					
				CommonClientServer.SetFilterItem(
					SelectionGroupSetsNested,
					"ContainsServices", True, DataCompositionComparisonType.Equal,, True);
					
				CommonClientServer.SetFilterItem(
					SelectionGroupSetsNested,
					"ContainsGoods", False, DataCompositionComparisonType.Equal,, True);
					
			EndIf;
				
		EndIf;
		If Not LimitSetsByService And LimitSetsByProduct Then
			
			SelectionGroupSets = CommonClientServer.CreateFilterItemGroup(
				TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts).Items,
				"FilterByProductType", DataCompositionFilterItemsGroupType.OrGroup);
				
			// Type of the Goods and Services product range, Packaging
			CommonClientServer.SetFilterItem(
				SelectionGroupSets,
				"ItemsType", SelectionsByProductTypeWithoutSets, DataCompositionComparisonType.InList,,(SelectionsByProductTypeWithoutSets.Count() > 0));
				
			// Sets without characteristics
			SelectionGroupSetsNested = CommonClientServer.CreateFilterItemGroup(
				SelectionGroupSets.Items,
				"SelectionGroupSetsNested", DataCompositionFilterItemsGroupType.AndGroup);
				
			CommonClientServer.SetFilterItem(
				SelectionGroupSetsNested,
				"ItemsType", Enums.ItemsTypes.Set, DataCompositionComparisonType.Equal,, True);
				
			CommonClientServer.SetFilterItem(
				SelectionGroupSetsNested,
				"ContainsServices", False, DataCompositionComparisonType.Equal,, True);
				
			CommonClientServer.SetFilterItem(
				SelectionGroupSetsNested,
				"ContainsGoods", True, DataCompositionComparisonType.Equal,, True);
				
			CommonClientServer.SetFilterItem(
				SelectionGroupSetsNested,
				"UseVariants", Enums.ItemVariantsUsageOptions.DontUse, DataCompositionComparisonType.Equal,, True);
				
			// Sets with characteristics
			SelectionGroupNestedWithCharacteristics = CommonClientServer.CreateFilterItemGroup(
				SelectionGroupSets.Items,
				"SelectionGroupSetsWithNestedCharacteristics", DataCompositionFilterItemsGroupType.AndGroup);
				
			CommonClientServer.SetFilterItem(
				SelectionGroupNestedWithCharacteristics,
				"ItemsType", Enums.ItemsTypes.Set, DataCompositionComparisonType.Equal,, True);
				
			CommonClientServer.SetFilterItem(
				SelectionGroupNestedWithCharacteristics,
				"UseVariants", Enums.ItemVariantsUsageOptions.DontUse, DataCompositionComparisonType.NotEqual,, True);
				
			If ThisIsFormOfMatchingInSalesDocuments Then
				
				SelectionGroupSets = CommonClientServer.CreateFilterItemGroup(
					TMCommonUseClientServer.GetDynamicListSelection(Form.FeatureList).Items,
					"FilterByProductType", DataCompositionFilterItemsGroupType.OrGroup);
					
				// Type of the Goods and Services product range, Packaging
				CommonClientServer.SetFilterItem(
					SelectionGroupSets,
					"ItemsType", SelectionsByProductTypeWithoutSets, DataCompositionComparisonType.InList,,(SelectionsByProductTypeWithoutSets.Count() > 0));
					
				// Sets without characteristics
				SelectionGroupSetsNested = CommonClientServer.CreateFilterItemGroup(
					SelectionGroupSets.Items,
					"SelectionGroupSetsNested", DataCompositionFilterItemsGroupType.AndGroup);
					
				CommonClientServer.SetFilterItem(
					SelectionGroupSetsNested,
					"ItemsType", Enums.ItemsTypes.Set, DataCompositionComparisonType.Equal,, True);
					
				CommonClientServer.SetFilterItem(
					SelectionGroupSetsNested,
					"ContainsServices", False, DataCompositionComparisonType.Equal,, True);
					
				CommonClientServer.SetFilterItem(
					SelectionGroupSetsNested,
					"ContainsGoods", True, DataCompositionComparisonType.Equal,, True);
					
			EndIf;
				
		EndIf;
		If LimitSetsByService And LimitSetsByProduct Then
			
			// Set selection by item types for the item list.
			CommonClientServer.SetDynamicListFilterItem(
				Form.ListProducts, "ItemsType", FilterByProductType, 
				DataCompositionComparisonType.InList, "FilterByProductType", (FilterByProductType.Count() > 0));
			
		EndIf;
	EndIf;
	
	// Set the selection parameters for the basket item.
	If SelectionsByProductTypeWithoutSets.Count() > 0
		And (ThisIsFormOfMatchingInSalesDocuments Or ThisIsFormOfSelectionInPurchaseDocuments) Then
		
		ChoiceParameters = New Array;
		ChoiceParameters.Add(New ChoiceParameter("Filter.ItemsType", SelectionsByProductTypeWithoutSets));
		
		Form.Items.junkProducts.ChoiceParameters = New FixedArray(ChoiceParameters);
		
		If ThisIsFormOfSelectionInPurchaseDocuments Then
			
			ChoiceParameters = New Array;
			ChoiceParameters.Add(New ChoiceParameter("ItemsType", SelectionsByProductTypeWithoutSets));
			
			Form.Items.PartnerProducts.ChoiceParameters = New FixedArray(ChoiceParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Processes the value passed in the form parameters for selecting the item list by item type.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetSelectionByTypeOfProductByParameters(Form) Export

	FilterByTheProductKind = Undefined;
	Form.Parameters.Filter.Property("ProductKind", FilterByTheProductKind);
	Form.Parameters.Filter.Delete("ProductKind");
	
	If FilterByTheProductKind = Undefined Or Not ValueIsFilled(FilterByTheProductKind) Then
		Return;
	EndIf;
	
	Form.UseFilters = True; 
	Form.NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties;
	Form.ProductKind = FilterByTheProductKind;

	FillInProductSelectionTree(Form);
	SetNavigationOptionPage(Form);
	WhenChangingUseOfFilters(Form);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForHandlingAlerts

// Fills in the details of the "current inventory Line" form with the values of the item details.
//
// Parameters:
//	Form - ClientApplicationForm - selection form,
//	Products - CatalogRef.Products - the item item that was created.
//
Procedure FillInParametersOfNewProductItem(Form, Products)
	
	Form.NewNomenclature = SelectGoodsClientServer.StructureOfProductLine();
	
	ProductAttributes = "Ref, IsFolder, Parent, DeletionMark, ProductKind, UnitOfMeasure, 
	|UseVariants, ItemsType, PriceGroup";
	
	ValuesOfProductItemDetails = Common.ObjectAttributesValues(Products, ProductAttributes);
	
	FillPropertyValues(Form.NewNomenclature, ValuesOfProductItemDetails);
	
	Form.NewNomenclature.Products = Products;
	Form.NewNomenclature.ItemVariantsAreUsed = 
		Not (ValuesOfProductItemDetails.UseVariants = Enums.ItemVariantsUsageOptions.DontUse);
	Form.NewNomenclature.ThisIsAProduct  = (ValuesOfProductItemDetails.ItemsType = Enums.ItemsTypes.OwnGoods
										Or ValuesOfProductItemDetails.ItemsType = Enums.ItemsTypes.ReusablePackage);
	Form.NewNomenclature.IsService = (ValuesOfProductItemDetails.ItemsType = Enums.ItemsTypes.OperationService
										Or ValuesOfProductItemDetails.ItemsType = Enums.ItemsTypes.Work_5);
	Form.NewNomenclature.ItemVariantsOwner = OwnerOfProductCharacteristics(Products);
	
EndProcedure

// Fills in the details of the "Newcharacteristics" form with the values of the details of the new characteristic.
//
// Parameters:
//	Form - See WhenCreatingMatchingFormOnServer.Form
//	Characteristic - CatalogRef.ItemsCharacteristics - characteristic.
//
Procedure FillInParametersOfNewCharacteristic(Form, Characteristic)
	
	Form.NewCharacteristic = SelectGoodsClientServer.StructureOfCharacteristicsString();
	
	Form.NewCharacteristic.Ref = Characteristic;
	Form.NewCharacteristic.Characteristic = Characteristic;
	
	If ValueIsFilled(Form.NewNomenclature) Then
		ProductParameters_ = Form.NewNomenclature;
	Else
		ProductParameters_ = Form.CurrentLineOfProducts;
	EndIf;
	
	FillPropertyValues(Form.NewCharacteristic, ProductParameters_);
	
EndProcedure

// Checks whether the item type of the created item matches the item type
// set as the selection of the item list in the selection form.
//
// Parameters:
// 	Form - ClientApplicationForm - selection Form
//
Function NewProductCorrespondsToSelectionByTypeOfProduct(Form)
	
	Var TypesOfSelectionProducts;
	
	If Not ValueIsFilled(Form.NewNomenclature) Then
		Return True;
	EndIf;
	
	// If the selection by the type of item is not set, then you can add
	// any type of goods to the basket.
	If Not SelectionByTypeOfProductHasBeenEstablished(Form, TypesOfSelectionProducts) Then
		Return True;
	EndIf;
	
	ProductKind = Form.NewNomenclature.ProductKind; // CatalogRef.ItemKinds
	TypeOfProductProduct = Common.ObjectAttributeValue(ProductKind, "ItemsType");
	
	// If the type of the product nomenclature is not in the list of types established as
	// selection types, then, therefore, it does not correspond.
	If TypesOfSelectionProducts.FindByValue(TypeOfProductProduct) = Undefined Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Checks whether the item type selection is set for the item list.
//
// Parameters:
//	Form - ClientApplicationForm - selection form,
//	TypesOfSelectionProducts - Undefined - variable to which the value of the set 
//		selection by item type is passed. A list of values is always used as the values of the set selection
//		. Selection by item type is set in the procedure 
//		<Set the selection for the nomenclatureparameters>.
//
// Returns:
//	Boolean - The truth is established, the Lie is not.
//
Function SelectionByTypeOfProductHasBeenEstablished(Form, TypesOfSelectionProducts = Undefined)
	
	For Each FilterElement In TMCommonUseClientServer.GetDynamicListSelection(Form.ListProducts).Items Do
		
		If FilterElement.Presentation = "FilterByProductType"
			And FilterElement.Use Then
			
			If Not TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
				If TypeOf(FilterElement.RightValue) = Type("ValueList") Then
					
					If FilterElement.RightValue.Count() > 0 Then
						
						TypesOfSelectionProducts = FilterElement.RightValue;
						Return True;
						
					EndIf;
					
				EndIf;
			Else
				
				If FilterElement.Items.Count() > 0 And TypeOf(FilterElement.Items[0].RightValue) = Type("ValueList") Then
					
					If FilterElement.Items[0].RightValue.Count() > 0 Then
						
						TypesOfSelectionProducts = FilterElement.Items[0].RightValue;
						Return True;
						
					EndIf;
					
				EndIf;
				
			EndIf;
		
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

// Fills in the "this Product", "this Service" fields of the Product structureaddavleniyavkorzinu.
//
// Parameters:
//	GoodsForAddingToTheCart - Structure - goods parameters to add to cart,
//	ItemsType - EnumRef.ItemsTypes - the type of item.
//
Procedure FillInProductPropertiesToAddToCartByProductType(GoodsForAddingToTheCart, ItemsType)
	
	GoodsForAddingToTheCart.ThisIsAProduct = (ItemsType = Enums.ItemsTypes.OwnGoods);
	GoodsForAddingToTheCart.IsService = (ItemsType = Enums.ItemsTypes.OperationService);
	
EndProcedure

// Analyzes the settings of the selection form in the part of specifying the warehouse and fills
// in the "Warehouse" field of the product to be added to the cart.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure FillInStockOfProductToAddToCart(Form)
	
	If Not Form.GoodsForAddingToTheCart.ThisIsAProduct Then
		Return;
	EndIf;
	
	NumberOfWarehouses = Form.Warehouses.Count();
	
	If Not NumberOfWarehouses = 1 Or NumberOfWarehouses = 0 Then
		Return;
	EndIf;
	
	Warehouse = Form.Warehouses.Get(0).Value;
	
	If Form.SelectionModeUseWarehousesInTabularSection Then
		Form.GoodsForAddingToTheCart.Warehouse = Warehouse;
	EndIf;
	
EndProcedure

#EndRegion

#Region GeneralPurposeProceduresAndFunctions

// Sets the item list
// or feature list as the active element on the form. Used when changing filter values.
// In this case, the focus set on the list is lost, and when you try to select
// a product, another element is activated.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetActiveListOnForm(Form)
	
	NameOfProductList = SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form);
	NameOfListOfCharacteristics = SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(Form);
	
	CurrentItem = Form.Items[NameOfProductList];
	If Form.CharacteristicNavigation Then
		CurrentItem = Form.Items[NameOfListOfCharacteristics];
	EndIf;
	
	Form.CurrentItem = CurrentItem;
	
EndProcedure

// Sets the gradation of quality in the list
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetQualityValueListItems(Form)
	
	Form.ListQualities.Clear();

	If Form.ProductsOfOriginalQuality.IsEmpty() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	AnotherQualityGoods.QualityGradation AS QualityGradation,
	|	AnotherQualityGoods.QualityGradation.Order AS Order
	|FROM
	|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|WHERE
	|	AnotherQualityGoods.Products = &Products
	|
	|ORDER BY
	|	Order";
	
	Query.SetParameter("Products", Form.ProductsOfOriginalQuality);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Form.ListQualities.Add(Selection.QualityGradation);
	EndDo;
	
	SetQualityGradationMark(Form);
	
EndProcedure

// Creates structures for passing parameters to the Central function for getting discount/mark-up parameters
// and calls it. Returns the address of data for calculating manual mark-up discounts in temporary storage.
//
// Parameters:
//	Form - ClientApplicationForm - selection form,
//	ProductParameters_1 - Structure - the parameters of the product.
//
// Returns:
//	String - The address of the data in the temporary storage.
//
Function AddressOfDataForCalculatingManualDiscountsForMatchingInTemporaryStorage(Form, ProductParameters_1) Export
	
	ObjectStructure = New Structure;
	
	If TMCommonUseClientServer.HasObjectAttribute(Form.Object, "Terms") Then
		CustomerTermsOfSales = Form.Object.Terms;
	Else
		CustomerTermsOfSales = Form.Terms;
	EndIf;
	
	ObjectStructure.Insert("Terms", CustomerTermsOfSales);
	
	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("NumberOfPackages", New TypeDescription("Number",,,New NumberQualifiers(15,3)));
	TableOfGoods.Columns.Add("Price", New TypeDescription("Number",,,New NumberQualifiers(15,2)));
	
	NewRow = TableOfGoods.Add();
	FillPropertyValues(NewRow, ProductParameters_1);
	
	ObjectStructure.Insert("Goods", TableOfGoods);
	
	DataParameters = New Structure("Object", ObjectStructure);
	
	If SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode) Then
		ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
		ParametersStructure.TableName = "Goods";
		ParametersStructure.OnlyForSelectedLines = False;
		DataAddress = DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryPurchaseStorage(
			DataParameters,Form.UUID, ParametersStructure);
	Else
		ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
		ParametersStructure.TableName = "Goods";
		ParametersStructure.OnlyForSelectedLines = False;
		DataAddress = DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(
			DataParameters,Form.UUID,ParametersStructure);
	EndIf;
	
	Return DataAddress;
	
EndFunction

// Returns a flag for the availability of price values for the list of price types whose date exceeds
// the date of product selection. It is necessary for making a decision on
// whether to set the "Period" parameter when accessing the latest
// data section of the "price Nomenclature" register. Without setting this parameter, the request will be executed faster.
//
// Parameters:
//	DateOfSelection_ - Date - product selection date,
//	TypesOfPrices - Array of CatalogRef.TypesOfPrices, 
//		List of values from the Reference Listlink.Price list - list of price types.
//	UsePriceManagementSystem25 - Boolean - True, a new pricing is being used
//
// Returns:
//	Boolean - True - there are values of prices set by a future date,
//		False - no.
//
Function ThereArePriceValuesLaterThanPickUpDate(DateOfSelection_, TypesOfPrices, UsePriceManagementSystem25 = False)
	
	Query = New Query();
	Query.Text = 
	"SELECT ALLOWED TOP 1
	|	ItemsPrices.Period AS Period
	|FROM
	|	&ItemsPrices AS ItemsPrices
	|WHERE
	|	ItemsPrices.PriceKind IN(&TypesOfPrices)
	|	AND ItemsPrices.Period > &DateOfSelection_";
	
	Query.SetParameter("TypesOfPrices", TypesOfPrices);
	Query.SetParameter("DateOfSelection_", EndOfDay(DateOfSelection_));
	
	If UsePriceManagementSystem25 Then
		Query.Text = StrReplace(Query.Text, "&ItemsPrices", "InformationRegister.ItemsPrices25");
	Else
		Query.Text = StrReplace(Query.Text, "&ItemsPrices", "InformationRegister.ItemsPrices");
	EndIf;
	
	Return Not Query.Execute().IsEmpty(); 
	
EndFunction

// Returns the fact that there are currency exchange rate values whose start date exceeds the date when goods were selected.
//
// Parameters:
// 	DateOfSelection_ - Date
//
// Returns:
// 	Boolean
//
Function ThereAreCurrencyExchangeRatesLaterThanPickUpDate(DateOfSelection_)
	
	Query = New Query();
	Query.SetParameter("DateOfSelection_", EndOfDay(DateOfSelection_));
	Query.Text =
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.RelativeExchangeRates AS RegisterTable
	|WHERE
	|	RegisterTable.Period > ENDOFPERIOD(&DateOfSelection_, DAY)";
	
	SetPrivilegedMode(True);
	Result = Not Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// Returns a flag for the availability of item price values whose date exceeds
// the product selection date. It is necessary to make a decision on
// whether to set the "Period" parameter when accessing a cross-section of the latest register
// of information "pricenotable suppliers". Without setting this parameter, the query will run faster.
//
// Parameters:
//	DateOfSelection_ - Date - date of product selection.
//
// Returns:
//	Boolean - True - there are values of prices set by a future date,
//		False - no.
//
Function ThereAreProductPriceValuesLaterThanPickUpDate(DateOfSelection_) Export
	
	Query = New Query();
	Query.Text = 
	"SELECT TOP 1
	|	ItemsPricesOfVendor.Period AS Period
	|FROM
	|	InformationRegister.ItemsPricesOfVendor AS ItemsPricesOfVendor
	|WHERE
	|	ItemsPricesOfVendor.Period > &DateOfSelection_";
	
	Query.SetParameter("DateOfSelection_", EndOfDay(DateOfSelection_));
	
	SetPrivilegedMode (True);
	Return Not Query.Execute().IsEmpty(); 
	
EndFunction

// Returns an array of item price types that are specified in the agreement with the customer.
//
// Parameters:
// 	CustomerTermsOfSales - CatalogRef.TermsOfSale - AGREEMENT WITH THE CLIENT
//
// Returns:
// 	Array of CatalogRef.TypesOfPrices - array of types of agreement prices
//
Function TypesOfPricesByAgreementWithClient(CustomerTermsOfSales)
	
	Query = New Query();
	
	Query.Text = 
	"SELECT ALLOWED DISTINCT
	|	AgreementHeader_.PricesKind AS PricesKind
	|FROM
	|	Catalog.TermsOfSale AS AgreementHeader_
	|WHERE
	|	AgreementHeader_.Ref = &Terms
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Goods.PriceKind
	|FROM
	|	Catalog.TermsOfSale.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Terms
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	PriceGroups.PricesKind
	|FROM
	|	Catalog.TermsOfSale.PriceGroups AS PriceGroups
	|WHERE
	|	PriceGroups.Ref = &Terms";
	
	Query.SetParameter("Terms", CustomerTermsOfSales);
	
	Return Query.Execute().Unload().UnloadColumn("PricesKind");
	
EndFunction
 
Function PriceCalculationOption(Form)
	
	PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.WithoutPrices;
	
	If Form.SelectionModeForRetailSales Then
		
		ValuesOfPriceTypes = Common.ObjectAttributesValues(Form.ObjectForStoringSalesTermsAndConditions, "RetailPriceType, SpecialPriceType");
		
		If ValueIsFilled(ValuesOfPriceTypes.RetailPriceType) And ValueIsFilled(ValuesOfPriceTypes.SpecialPriceType) Then
			PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeaderAndAdjustedPricesByItems;
		ElsIf ValueIsFilled(ValuesOfPriceTypes.RetailPriceType) Or ValueIsFilled(ValuesOfPriceTypes.SpecialPriceType) Then
			PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeader;
		EndIf;
		
	ElsIf Form.ToUseTermsOfSales Then
		
		ValuesOfPriceTypes = Common.ObjectAttributesValues(Form.ObjectForStoringSalesTermsAndConditions, "PricesKind, SpecialPriceType");
		
		If ValueIsFilled(ValuesOfPriceTypes.PricesKind) And ValueIsFilled(ValuesOfPriceTypes.SpecialPriceType) Then
			PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeaderAndAdjustedPricesByItems;
		ElsIf ValueIsFilled(ValuesOfPriceTypes.PricesKind) Or ValueIsFilled(ValuesOfPriceTypes.SpecialPriceType) Then
			PriceCalculationOption = Enums.PriceCalculationOptionsByTermsOfSales.PricesKindInHeader;
		EndIf;
		
	EndIf;
	
	Return PriceCalculationOption;
	
EndFunction

// Returns an array of item price types with a single element, if it can be defined uniquely.
// Used to get the default price type in the disabled customer agreements mode.
//
// Parameters:
// 	PriceIncludesVAT - Boolean - Indicates whether VAT is included in the price
//
// Returns:
// 	Array of CatalogRef.TypesOfPrices - array of types of agreement prices
//
Function DefaultPriceTypes(PriceIncludesVAT)
	
	ArrayOfPriceTypes = New Array; 
	
	ChoiceParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
	ChoiceParameters.PriceIncludesVAT = PriceIncludesVAT;
	ChoiceParameters.UseWhileSellingToCustomers = True;
	
	DefaultPriceView = SettingsValueCached.DefaultPriceType(ChoiceParameters);
	If ValueIsFilled(DefaultPriceView) Then
		ArrayOfPriceTypes.Add(DefaultPriceView);
	EndIf;
	
	Return ArrayOfPriceTypes;
	
EndFunction

// Parameters:
// 	Form - See WhenCreatingMatchingFormOnServer.Form
// 	ThisIsFormOfSelectionInPurchaseDocuments - Boolean
//
Procedure SetConditionalAppearanceOfDynamicLists(Form, ThisIsFormOfSelectionInPurchaseDocuments = False) Export
	
	ThisIsPartner = UserRightsCached.ThisIsPartner();
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	If Not ThisIsPartner 
		And Not Form.HideCommandRemainingQuantityInWarehouses Then
	
		Items.ListAdvancedSearchProductsInStockBalance.Format = "NFD=3";
		Items.ListStandardSearchProductsInStockBalance.Format = "NFD=3";

		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchProductsInStockBalance.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchProductsInStockBalance.Name);
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListProducts.InStockBalance");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = 0;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListProducts.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
		ValueList = New ValueList;
		ValueList.Add(Enums.ItemsTypes.Work_5);
		ValueList.Add(Enums.ItemsTypes.OperationService);
		ValueList.Add(Enums.ItemsTypes.Set);
		ItemFilter.RightValue = ValueList;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("DisplayRemainingQuantityInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không>';
														|ru = '<нет>';
														|en = '<no>'; fa = '<خیر>';
														|it = '<no>';
														|pl = '<no>';
														|tr = '<hayır>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchProductsInStockBalance.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchProductsInStockBalance.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("DisplayRemainingQuantityInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("MarkNegatives", True);
		
	EndIf;
	
	//
	
	If Not ThisIsPartner 
		And Form.DisplayRemainingQuantityInWarehouses Then

		Items.ListAdvancedSearchProductsAvailable.Format = "NFD=3";
		Items.ListStandardSearchProductsAvailable.Format = "NFD=3";
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchProductsAvailable.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchProductsAvailable.Name);
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListProducts.Available");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = 0;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListProducts.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
		ValueList = New ValueList;
		ValueList.Add(Enums.ItemsTypes.Work_5);
		ValueList.Add(Enums.ItemsTypes.OperationService);
		ValueList.Add(Enums.ItemsTypes.Set);
		ItemFilter.RightValue = ValueList;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không>';
														|ru = '<нет>';
														|en = '<no>'; fa = '<خیر>';
														|it = '<no>';
														|pl = '<no>';
														|tr = '<hayır>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchProductsAvailable.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchProductsAvailable.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("DisplayRemainingQuantityInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("MarkNegatives", True);
		
	EndIf;
	
	//
	
	If Not Form.SelectionModeWithoutAmountParameters Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchProductsPrice.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchProductsPrice.Name);
		
		Item.Appearance.SetParameterValue("Format", "NFD=2");

		//

		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchProductsPrice.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchProductsPrice.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListProducts.UseVariants");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ValueList = New ValueList;
		ValueList.Add(Enums.ItemVariantsUsageOptions.CommonForItemKind);
		ValueList.Add(Enums.ItemVariantsUsageOptions.SpecialForItems);
		ValueList.Add(Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind);
		ItemFilter.RightValue = ValueList;
		
		Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, False, False, ));
		Item.Appearance.SetParameterValue("Text", "...");
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchCharacteristicsPrice.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchCharacteristicsPrice.Name);
		
		Item.Appearance.SetParameterValue("Format", "NFD=2");
		
	EndIf;
	
	//
	
	If Not ThisIsPartner
		And Not Form.HideCommandRemainingQuantityInWarehouses Then
		
		Items.ListAdvancedSearchCharacteristicsInStockBalance.Format = "NFD=3";
		Items.ListStandardSearchCharacteristicsInStockBalance.Format = "NFD=3";
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchCharacteristicsInStockBalance.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchCharacteristicsInStockBalance.Name);
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("FeatureList.InStockBalance");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = 0;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("FeatureList.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
		ValueList = New ValueList;
		ValueList.Add(Enums.ItemsTypes.Work_5);
		ValueList.Add(Enums.ItemsTypes.OperationService);
		ValueList.Add(Enums.ItemsTypes.Set);
		ItemFilter.RightValue = ValueList;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("DisplayRemainingQuantityInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không>';
														|ru = '<нет>';
														|en = '<no>'; fa = '<خیر>';
														|it = '<no>';
														|pl = '<no>';
														|tr = '<hayır>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchCharacteristicsInStockBalance.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchCharacteristicsInStockBalance.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("DisplayRemainingQuantityInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("MarkNegatives", True);
		
	EndIf;
	
	//
	
	If Not ThisIsPartner
		And Form.DisplayRemainingQuantityInWarehouses Then
		
		Items.ListAdvancedSearchCharacteristicsAvailable.Format = "NFD=3";
		Items.ListStandardSearchCharacteristicsAvailable.Format = "NFD=3";
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchCharacteristicsAvailable.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchCharacteristicsAvailable.Name);
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("FeatureList.Available");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = 0;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("FeatureList.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
		ValueList = New ValueList;
		ValueList.Add(Enums.ItemsTypes.Work_5);
		ValueList.Add(Enums.ItemsTypes.OperationService);
		ValueList.Add(Enums.ItemsTypes.Set);
		ItemFilter.RightValue = ValueList;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không>';
														|ru = '<нет>';
														|en = '<no>'; fa = '<خیر>';
														|it = '<no>';
														|pl = '<no>';
														|tr = '<hayır>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchCharacteristicsAvailable.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchCharacteristicsAvailable.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("DisplayRemainingQuantityInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("MarkNegatives", True);
		
	EndIf;
	
	//
	
	If ThisIsFormOfSelectionInPurchaseDocuments Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListOfStandardSearchPartnerNomenclature.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListOfAdvancedSearchPartnerNomenclature.Name);
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListOfThePartnerSNomenclature.Products");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListOfThePartnerSNomenclature.IsFolder");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("TextColor", WebColors.RosyBrown);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.TheListOfDefaultSearchItemPartnerItem.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.AListOfAdvancedSearchItemPartnerItem.Name);
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListOfThePartnerSNomenclature.Products");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListOfThePartnerSNomenclature.IsFolder");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
		Item.Appearance.SetParameterValue("Text", "?");
		
	EndIf;
	
	//
	
	If Not ThisIsPartner 
		And Not Form.HideCommandRemainingQuantityInWarehouses Then
	
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchProductsInStockBalance.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchProductsInStockBalance.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchCharacteristicsInStockBalance.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchCharacteristicsInStockBalance.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("DisplayRemainingQuantityInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<kho không được chọn>';
														|ru = '<не выбран склад>';
														|en = '<warehouse is not selected>'; fa = '<warehouse is not selected>';
														|it = '<nessun magazzino selezionato>';
														|pl = '<nie jest wybrany magazyn>';
														|tr = '<ambar seçilmedi>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	EndIf;


EndProcedure

// Parameters:
// 	Form - See WhenCreatingMatchingFormOnServer.Form
// 	ThisIsFormOfSelectionInPurchaseDocuments - Boolean
//
Procedure SetConditionalAppearanceOfSelectionFormElements(Form, ThisIsFormOfSelectionInPurchaseDocuments = False) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SearchStringProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsSearchReturnedNoResults");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SearchBarCharacteristics.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FailedToFindCharacteristics");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);
	
	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "junkProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.junk.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(Form, 
																"junkCharacteristic",
																"Object.junk.ItemVariantsAreUsed");

	//
	
	If Form.DisplayRemainingQuantityInWarehouses
				And Not (Form.ModeOfSelectionWithoutQuantitativeParameters
					Or Form.HideCommandRemainingQuantityInWarehouses) Then
		
		Item = ConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.StockBalancePeriodDescription.Name);

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("StockBalance.Period");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
		ItemFilter.RightValue = BegOfDay(CurrentSessionDate());

		Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);
		
		//
		
		Item = ConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.StockBalance.Name);

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("StockBalance.WarehouseIsAvailableForSelection");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;

		Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
		
		//
		
		If ThisIsFormOfSelectionInPurchaseDocuments Then
			
			//
			
			Item = ConditionalAppearance.Items.Add();
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(Items.SupplierStockBalance.Name);
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("SupplierStockBalance.WarehouseIsAvailableForSelection");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = False;
			
			Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
			
			//
		
		EndIf;
		
	EndIf;

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
	ItemField.Field = New DataCompositionField(Items.FilterTreePresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterTree.Filter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTree.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsHierarchy.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemKinds.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListQualities.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseFilters");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FormBackColor);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTreeFilter.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTreePresentation.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTreeFilterPresentation.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NavigationOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ListOfNavigationOptions = New ValueList;
	ListOfNavigationOptions.Add(Enums.ItemFormNavigationOptions.ByProperties);
	ListOfNavigationOptions.Add(Enums.ItemFormNavigationOptions.ByKindsAndProperties);
	ItemFilter.RightValue = ListOfNavigationOptions;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseFilters");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CharacteristicNavigation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterTree.FilterFeatures");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ListStandardSearchItemItemUnitOfMeasurement";
	ConditionalDesignParameters.PathToPackagingUnitField = "ListProducts.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "AdvancedSearchListItemUnitOfMeasurement";
	ConditionalDesignParameters.PathToPackagingUnitField = "ListProducts.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);
	
	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ListStandardSearchCharacteristicsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "FeatureList.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ListAdvancedSearchCharacteristicsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "FeatureList.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);
	
	//

	If ThisIsFormOfSelectionInPurchaseDocuments Then
		ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
		ConditionalDesignParameters.NameOfUnitField = "ListOfStandardSearchPartnerNomenclature";
		ConditionalDesignParameters.PathToPackagingUnitField = "ListProducts.Package";
		ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);
		
		ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
		ConditionalDesignParameters.NameOfUnitField = "ListOfAdvancedSearchPartnerNomenclature";
		ConditionalDesignParameters.PathToPackagingUnitField = "ListProducts.Package";
		ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);
	EndIf;
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductKind.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseFilters");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterPriceFrom.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterPriceUpTo.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterPriceFrom");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("FilterPriceUpTo");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterPriceUpTo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);
	
EndProcedure	

// Returns the owner of the item's characteristics. Depending on
// the item type settings, this can be either an item type or an item type.
//
// Parameters:
//	Products - CatalogRef.Products - Products
//
// Returns:
//	CatalogRef.Products, CatalogRef.ItemKinds, Undefined - 
//
Function OwnerOfProductCharacteristics(Products)
	
	Attributes = Common.ObjectAttributesValues(Products, "ProductKind,UseVariants,ItemVariantsOwner");
	
	If Attributes.UseVariants = Enums.ItemVariantsUsageOptions.CommonForItemKind Then
		Return Attributes.ProductKind;
	ElsIf Attributes.UseVariants = Enums.ItemVariantsUsageOptions.SpecialForItems Then
		Return Products;
	ElsIf Attributes.UseVariants = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind Then
		Return Attributes.ItemVariantsOwner;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsForGeneratingQueryTexts

// Returns the query text for the dynamic list of the selection form.
//
// Parameters:
// 	Form - ClientApplicationForm - selection Form
// 	ListType - String - the type of the selection Form list
//
// Returns:
// 	String - Request Text For The Selection Form List
//
Function RequestTextForSelectionFormList(Form, ListType)
	
	BuildParameters = SelectGoodsClientServer.NewParametersForBuildingListQuery();
	BuildParameters.ListType = ListType;
	BuildParameters.OnlyInStock = Form.OnlyInStock;
	BuildParameters.MultipleWarehouses = Form.Warehouses.Count() > 1;
	BuildParameters.SelectionModeWithoutAmountParameters = Form.SelectionModeWithoutAmountParameters;
	BuildParameters.DisplayRemainingQuantityInWarehouses = Form.DisplayRemainingQuantityInWarehouses;
	BuildParameters.ThereAreRatessInFuture = ThereAreCurrencyExchangeRatesLaterThanPickUpDate(Form.Date);
	
	If Form.UseItemVariants Then
		
		NavigationOptionsWithCharacteristics = New Array;
		NavigationOptionsWithCharacteristics.Add(Enums.ItemFormNavigationOptions.ByProperties);
		NavigationOptionsWithCharacteristics.Add(Enums.ItemFormNavigationOptions.ByKindsAndProperties);
		NavigationOptionsWithCharacteristics.Add(Enums.ItemFormNavigationOptions.ByKinds);
		
		If Form.UseFilters
			And ValueIsFilled(Form.ProductKind)
			And NavigationOptionsWithCharacteristics.Find(Form.NavigationOption) <> Undefined Then
			
			ProductKindSelection = Form.ProductKind; // CatalogRef.ItemKinds
			UseVariants = Common.ObjectAttributeValue(
				ProductKindSelection,
				"UseVariants");
			
			If UseVariants <>
				Enums.ItemVariantsUsageOptions.DontUse Then
				
				BuildParameters.UseItemVariants = True;
				
			EndIf;
			
		Else
			BuildParameters.UseItemVariants = True;
		EndIf;
		
	EndIf;
	
	If SelectGoodsClientServer.ThisIsFormOfMatchingInSalesDocuments(Form.FormCode) Then
		
		BuildParameters.FormType = "SelectionInSalesDocuments";
		BuildParameters.ThisIsPartner = UserRightsCached.ThisIsPartner();
		BuildParameters.UsePriceManagementSystem25 = Form.UsePriceManagementSystem25;
		BuildParameters.PriceCalculationOption = Form.PriceCalculationOption;
		BuildParameters.SelectionModeByProductRange = Form.SelectionModeByProductRange;
		BuildParameters.DoNotUsePriceTypesBasedOnTheSalesCondition = Form.DoNotUsePriceTypesBasedOnTheSalesCondition;
		BuildParameters.SeveralPriceTypes = Form.TypesOfPrices.Count() > 1;
		BuildParameters.DisplayBalancesAsIntended = ValueIsFilled(Form.TheSelectionForTheAppointmentOfTheCurrent);
		BuildParameters.DisplayBalanceOfControlledLotReference = ValueIsFilled(Form.ControlledLotReference);
		BuildParameters.ThereArePricesInTheFuture = Form.ThereArePricesInTheFuture;
		
		If Form.FilterByProductType.FindByValue(Enums.ItemsTypes.Set) <> Undefined
			Or Form.FilterByProductType.Count() = 0 Then
			
			BuildParameters.UseKits = GetFunctionalOption("UseSets");
			
		EndIf;
		
	ElsIf SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode) Then
		
		SupplierPriceCalculationOption = "PricesByAgreement";
		
		If ValueIsFilled(Form.Object.Terms) Then
			Form.VendorPriceKind = Form.Object.Terms.VendorPriceKind;
		Else
			SupplierPriceCalculationOption = "WithoutPrices";
		EndIf;
		
		BuildParameters.FormType = "SelectionInPurchaseDocuments";
		BuildParameters.SupplierPriceCalculationOption = SupplierPriceCalculationOption;
		BuildParameters.ThereAreProductPricesOfSuppliersInTheFuture = Form.ThereAreProductPricesOfSuppliersInTheFuture;
		
	Else
		
		Raise NStr("ru = 'Ошибка при открытии формы подбора';
					|vi = 'An error occurred when opening the pick form';
					|en = 'An error occurred when opening the pick form'; fa = 'An error occurred when opening the pick form';
					|it = 'An error occurred when opening the pick form';
					|pl = 'An error occurred when opening the pick form';
					|tr = 'Seçim formunu açılırken hata oluştu'");
		
	EndIf;
	
	RequestTextTemplate = GenerateQueryTextOfSelectionFormList(BuildParameters);
	
	
	Return TrimAll(RequestTextTemplate);
	
EndFunction

// Builds a query for lists of items and characteristics.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
// Returns:
// 	String
//
Function GenerateQueryTextOfSelectionFormList(QueryConstructionParameters) Export
	
	If QueryConstructionParameters.FormType = "SelectionInSalesDocuments" Then
		
		If QueryConstructionParameters.ThisIsPartner Then
			
			QueryConstructionParameters.QueryTemplate =
			"SELECT
			|	&FieldTextCommonFields,
			|	&TextOfPackagingUnitField AS Package,
			|	&TextOfPriceTypeField AS PriceKind,
			|	&TextOfPriceField AS Price
			|FROM
			|	#MainTable
			|WHERE
			|	&TextGeneralCondition";
			
			GenerateQueryTextForExternalUsers(QueryConstructionParameters);
			
		ElsIf QueryConstructionParameters.SelectionModeByProductRange Then
			
			QueryConstructionParameters.QueryTemplate =
			"SELECT
			|	&FieldTextCommonFields,
			|	&TextOfPackagingUnitField AS Package,
			|	&TextOfPriceField AS Price,
			|	&FieldTextAvailableBalance AS InStockBalance,
			|	&TextOfFieldIsAvailableInBasicUnits AS AvailableInBasicUnits,
			|	&TextOfAvailableQuantityField AS Available
			|FROM
			|	#MainTable
			|WHERE
			|	&TextGeneralCondition";
			
			GenerateQueryTextOfProductRange(QueryConstructionParameters);
			
		Else
			
			QueryConstructionParameters.QueryTemplate =
			"SELECT
			|	&FieldTextCommonFields,
			|	&TextOfPackagingUnitField AS Package,
			|	&TextOfPriceTypeField AS PriceKind,
			|	&TextOfPriceField AS Price,
			|	&FieldTextAvailableBalance AS InStockBalance,
			|	&TextOfFieldIsAvailableInBasicUnits AS AvailableInBasicUnits,
			|	&TextOfAvailableQuantityField AS Available
			|FROM
			|	#MainTable
			|WHERE
			|	&TextGeneralCondition";
			
			GenerateQueryTextAccordingToParametersOfAgreementWithClient(QueryConstructionParameters);
			
		EndIf;
		
	ElsIf QueryConstructionParameters.FormType = "SelectionInPurchaseDocuments" Then
		
		If QueryConstructionParameters.ListType = "ListOfThePartnerSNomenclature" Then
			
			QueryConstructionParameters.QueryTemplate =
			"SELECT
			|	&FieldTextCommonFields,
			|	&TextOfPriceField AS Price,
			|	&FieldTextVendorPriceType AS VendorPriceKind
			|FROM
			|	#MainTable
			|WHERE
			|	&TextGeneralCondition";
			
		ElsIf QueryConstructionParameters.ListType = "ListProducts"
			Or QueryConstructionParameters.ListType = "FeatureList" Then
			
			QueryConstructionParameters.QueryTemplate =
			"SELECT
			|	&FieldTextCommonFields,
			|	&TextOfPackagingUnitField AS Package,
			|	&TextOfPriceField AS Price,
			|	&FieldTextCurrency AS Currency,
			|	&FieldTextAvailableBalance AS InStockBalance,
			|	&TextOfFieldIsAvailableInBasicUnits AS AvailableInBasicUnits,
			|	&TextOfAvailableQuantityField AS Available
			|FROM
			|	#MainTable
			|WHERE
			|	&TextGeneralCondition";
			
		EndIf;
		
		GenerateQueryTextBasedOnParametersOfAgreementWithSupplier(QueryConstructionParameters);
		
	EndIf;
	
	AddTemporaryTablesToQuery(QueryConstructionParameters);
	PerformTemplateReplacementsInQueryText(QueryConstructionParameters);
	
	QueryText = QueryConstructionParameters.QueryTemplate;
	
	Return QueryText;
	
EndFunction

// Complements the query template with the text of creating temporary tables.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
Procedure AddTemporaryTablesToQuery(QueryConstructionParameters)
	
	TextsOfTemporaryTables = New Array();
	
	For Each TempTableName In QueryConstructionParameters.TemporaryTable Do
		
		If TempTableName = "TableOfExchangeRates"
			Or TempTableName = "GeneralTableOfExchangeRates" Then
			
			TemporaryTableText = TextOfTemporaryCurrencyExchangeRatesTable(
				QueryConstructionParameters,
				TempTableName = "TableOfExchangeRates");
			
		ElsIf TempTableName = "ProductRange" Then
			
			TemporaryTableText = TextOfTemporaryProductRangeTable(
				QueryConstructionParameters);
			
		Else
			TemporaryTableText = "";
		EndIf;
		
		TemporaryTableText = StrReplace(TemporaryTableText,
			"TempTableName",
			TempTableName);
			
		If ValueIsFilled(TemporaryTableText) Then
			TextsOfTemporaryTables.Add(TemporaryTableText);
		EndIf;
		
	EndDo;
	
	If TextsOfTemporaryTables.Count() Then
	
		QueryConstructionParameters.QueryTemplate =
			StrConcat(TextsOfTemporaryTables, Common.QueryBatchSeparator())
			+ Common.QueryBatchSeparator()
			+ QueryConstructionParameters.QueryTemplate;
		
	EndIf;
	
EndProcedure

// Builds a query for lists of items and characteristics in external user mode.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
Procedure GenerateQueryTextForExternalUsers(QueryConstructionParameters)
	
	If Not ValueIsFilled(QueryConstructionParameters.QueryTemplate) Then
		Return;
	EndIf;
	
	TextReplacements = QueryConstructionParameters.TextReplacements;
	
	QueryConstructionParameters.TemporaryTable.Add("TableOfExchangeRates");
	QueryConstructionParameters.TemporaryTable.Add("GeneralTableOfExchangeRates");
	
	If QueryConstructionParameters.ListType = "ListProducts"
		And QueryConstructionParameters.UsePriceManagementSystem25
		Or QueryConstructionParameters.ListType = "FeatureList" Then
		
		TextReplacements.Insert("&TextOfPackagingUnitField",
			"CASE
			|	WHEN ISNULL(IndividualProductPrices.Price, 0) > 0
			|		THEN ISNULL(IndividualProductPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
			|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
			|END");
		
		TextReplacements.Insert("&TextOfPriceTypeField",
			"CASE
			|	WHEN ISNULL(IndividualProductPrices.Price, 0) > 0
			|		THEN IndividualProductPrices.PriceKind
			|	ELSE ISNULL(ItemsPrices.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
			|END");
		
		TextReplacements.Insert("&TextOfPriceField",
			"CAST(CASE
			|	WHEN ISNULL(IndividualProductPrices.Price, 0) > 0
			|		THEN IndividualProductPrices.Price
			|		* CASE
			|			WHEN &Currency <> IndividualProductPrices.Currency
			|				THEN CASE
			|					WHEN ISNULL(RatesCrossSectionCurrencyIndividualPrices.CourseDenominator, 0) > 0
			|					AND ISNULL(RatesCrossSectionCurrencyIndividualPrices.CourseNumerator, 0) > 0
			|					AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
			|					AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
			|						THEN RatesCrossSectionCurrencyIndividualPrices.CourseNumerator
			|							* CrossSectionRatesDocumentCurrency.CourseDenominator
			|							/ (CrossSectionRatesDocumentCurrency.CourseNumerator
			|							* RatesCrossSectionCurrencyIndividualPrices.CourseDenominator)
			|					ELSE 0
			|				END
			|			ELSE 1
			|		END
			|	ELSE ItemsPrices.Price
			|	* CASE
			|		WHEN &Currency <> ItemsPrices.Currency
			|			THEN CASE
			|				WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
			|				AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
			|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
			|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
			|					THEN RatesCutCurrencyPrices.CourseNumerator
			|						* CrossSectionRatesDocumentCurrency.CourseDenominator
			|						/ (CrossSectionRatesDocumentCurrency.CourseNumerator
			|						* RatesCutCurrencyPrices.CourseDenominator)
			|				ELSE 0
			|			END
			|		ELSE 1
			|	END
			|END AS NUMBER(31,2))");
		
	Else
		
		TextReplacements.Insert("&TextOfPackagingUnitField",
			"CASE
			|	WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
			|	<> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|		THEN AgreementGoods.Package
			|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
			|END");
		
		TextReplacements.Insert("&TextOfPriceTypeField",
			"CASE
			|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
			|		THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
			|	WHEN AgreementGoods.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
			|	AND AgreementGoods.PriceKind IS NOT NULL
			|		THEN AgreementGoods.PriceKind
			|	WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
			|		OR AgreementGoods.PriceKind IS NULL)
			|	AND AgreementPriceGroups.PricesKind IS NOT NULL
			|	AND AgreementPriceGroups.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
			|		THEN AgreementPriceGroups.PricesKind
			|	WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
			|		OR AgreementGoods.PriceKind IS NULL)
			|	AND (AgreementPriceGroups.PricesKind IS NULL
			|		OR AgreementPriceGroups.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef))
			|	AND AgreementHeader_.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
			|		THEN AgreementHeader_.PricesKind
			|END");
		
		TextReplacements.Insert("&TextOfPriceField",
			"CAST(CASE
			|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
			|		THEN AgreementGoods.Price
			|		* CASE
			|			WHEN &Currency <> AgreementGoods.Ref.Currency
			|				THEN CASE
			|					WHEN ISNULL(CutRatesAgreementCurrency.CourseDenominator, 0) > 0
			|					AND ISNULL(CutRatesAgreementCurrency.CourseNumerator, 0) > 0
			|					AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
			|					AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
			|						THEN CutRatesAgreementCurrency.CourseNumerator
			|							* CrossSectionRatesDocumentCurrency.CourseDenominator
			|							/ (CrossSectionRatesDocumentCurrency.CourseNumerator
			|							* CutRatesAgreementCurrency.CourseDenominator)
			|					ELSE 0
			|				END
			|			ELSE 1
			|		END
			|	WHEN CASE
			|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
			|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
			|		WHEN AgreementGoods.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
			|		AND AgreementGoods.PriceKind IS NOT NULL
			|			THEN AgreementGoods.PriceKind
			|		WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
			|			OR AgreementGoods.PriceKind IS NULL)
			|		AND AgreementPriceGroups.PricesKind IS NOT NULL
			|		AND AgreementPriceGroups.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
			|			THEN AgreementPriceGroups.PricesKind
			|		WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
			|			OR AgreementGoods.PriceKind IS NULL)
			|		AND (AgreementPriceGroups.PricesKind IS NULL
			|			OR AgreementPriceGroups.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef))
			|		AND AgreementHeader_.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
			|			THEN AgreementHeader_.PricesKind
			|	END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
			|	AND ISNULL(ItemsPrices.Price, 0) > 0
			|		THEN ItemsPrices.Price
			|		* CASE
			|			WHEN &Currency <> ItemsPrices.Currency
			|				THEN CASE
			|					WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
			|					AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
			|					AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
			|					AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
			|						THEN RatesCutCurrencyPrices.CourseNumerator
			|							* CrossSectionRatesDocumentCurrency.CourseDenominator
			|							/ (CrossSectionRatesDocumentCurrency.CourseNumerator
			|							* RatesCutCurrencyPrices.CourseDenominator)
			|					ELSE 0
			|				END
			|			ELSE 1
			|		END
			|	ELSE 0
			|END AS NUMBER(31,2))");
		
	EndIf;
	
	If QueryConstructionParameters.ListType = "ListProducts" Then
		
		If QueryConstructionParameters.UsePriceManagementSystem25 Then
			
			TextReplacements.Insert("#MainTable",
				TableTextMainCatalogTable(QueryConstructionParameters) +
				"
				|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
				|		ON CatalogProducts.Ref = ItemsPrices.Products
				|
				|		LEFT JOIN &TableOfIndividualItemPrices AS IndividualProductPrices
				|		ON CatalogProducts.Ref = IndividualProductPrices.Products
				|
				|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCrossSectionCurrencyIndividualPrices
				|		ON IndividualProductPrices.Currency = RatesCrossSectionCurrencyIndividualPrices.Currency
				|
				|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
				|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
				|
				|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
				|		ON TRUE");
			
			TextReplacements.Insert("&TextGeneralCondition",
				TextSelectionGeneralCondition(QueryConstructionParameters, "AND &SelectionOfProductsAtPriceOf25"));
			
		Else
			
			TextReplacements.Insert("#MainTable",
				TableTextMainCatalogTable(QueryConstructionParameters) +
				"
				|		LEFT JOIN Catalog.TermsOfSale AS AgreementHeader_
				|		ON AgreementHeader_.Ref = &Terms
				|
				|		LEFT JOIN Catalog.TermsOfSale.Goods AS AgreementGoods
				|		ON AgreementGoods.Ref = &Terms
				|		AND CatalogProducts.Ref = AgreementGoods.Products
				|		AND AgreementGoods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
				|		
				|		LEFT JOIN Catalog.TermsOfSale.PriceGroups AS AgreementPriceGroups
				|		ON AgreementHeader_.Ref = AgreementPriceGroups.Ref
				|		AND CatalogProducts.PriceGroup = AgreementPriceGroups.PriceGroup
				|
				|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
				|		ON CatalogProducts.Ref = ItemsPrices.Products
				|		AND ItemsPrices.PriceKind =
				|			CASE
				|				WHEN ISNULL(AgreementGoods.Price, 0) > 0
				|					THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
				|				WHEN AgreementGoods.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
				|				AND AgreementGoods.PriceKind IS NOT NULL
				|					THEN AgreementGoods.PriceKind
				|				WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
				|					OR AgreementGoods.PriceKind IS NULL)
				|				AND AgreementPriceGroups.PricesKind IS NOT NULL
				|				AND AgreementPriceGroups.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
				|					THEN AgreementPriceGroups.PricesKind
				|				WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
				|					OR AgreementGoods.PriceKind IS NULL)
				|				AND (AgreementPriceGroups.PricesKind IS NULL
				|					OR AgreementPriceGroups.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef))
				|				AND AgreementHeader_.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
				|					THEN AgreementHeader_.PricesKind
				|			END
				|
				|		LEFT JOIN GeneralTableOfExchangeRates AS CutRatesAgreementCurrency
				|		ON AgreementGoods.Ref.Currency = CutRatesAgreementCurrency.Currency
				|
				|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
				|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
				|
				|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
				|		ON TRUE");
			
			TextReplacements.Insert("&TextGeneralCondition",
				TextSelectionGeneralCondition(QueryConstructionParameters, "AND &ItemsFilterByPrice20"));
			
		EndIf;
			
	ElsIf QueryConstructionParameters.ListType = "FeatureList" Then
		
		If QueryConstructionParameters.UsePriceManagementSystem25 Then
			
			TextReplacements.Insert("#MainTable",
				TableTextMainCatalogTable(QueryConstructionParameters) +
				"
				|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
				|		ON ItemsPrices.PricingVariant =
				|			CASE
				|				WHEN CAST(&ProductKind AS Catalog.ItemKinds).SettingsOfPriceKeyByItemVariant =
				|				VALUE(Enum.FilterOptionForPriceKey.DontUse)
				|					THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
				|				ELSE ItemsCharacteristics.ItemsCharacteristicForPricing
				|			END
				|
				|		LEFT JOIN &TableOfIndividualItemPrices AS IndividualProductPrices
				|		ON IndividualProductPrices.PricingVariant =
				|			CASE
				|				WHEN CAST(&ProductKind AS Catalog.ItemKinds).SettingsOfPriceKeyByItemVariant =
				|				VALUE(Enum.FilterOptionForPriceKey.DontUse)
				|					THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
				|				ELSE ItemsCharacteristics.ItemsCharacteristicForPricing
				|			END
				|
				|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCrossSectionCurrencyIndividualPrices
				|		ON IndividualProductPrices.Currency = RatesCrossSectionCurrencyIndividualPrices.Currency
				|
				|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
				|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
				|
				|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
				|		ON TRUE");
			
			TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
			
		Else
			
			TextReplacements.Insert("#MainTable",
				TableTextMainCatalogTable(QueryConstructionParameters) +
				"
				|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
				|		ON ItemsPrices.Characteristic = ItemsCharacteristics.Ref
				|
				|		LEFT JOIN &TableOfIndividualItemPrices AS IndividualProductPrices
				|		ON IndividualProductPrices.PricingVariant =
				|			CASE
				|				WHEN CAST(&ProductKind AS Catalog.ItemKinds).SettingsOfPriceKeyByItemVariant =
				|				VALUE(Enum.FilterOptionForPriceKey.DontUse)
				|					THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
				|				ELSE ItemsCharacteristics.ItemsCharacteristicForPricing
				|			END
				|
				|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCrossSectionCurrencyIndividualPrices
				|		ON IndividualProductPrices.Currency = RatesCrossSectionCurrencyIndividualPrices.Currency
				|
				|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
				|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
				|
				|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
				|		ON TRUE");
			
			TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Performs query construction for lists of items and characteristics in assortment selection mode.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
Procedure GenerateQueryTextOfProductRange(QueryConstructionParameters)
	
	If Not ValueIsFilled(QueryConstructionParameters.QueryTemplate) Then
		Return;
	EndIf;
	
	TextReplacements = QueryConstructionParameters.TextReplacements;
	
	QueryConstructionParameters.TemporaryTable.Add("TableOfExchangeRates");
	QueryConstructionParameters.TemporaryTable.Add("GeneralTableOfExchangeRates");
	
	QueryConstructionParameters.TemporaryTable.Add("ProductRange");
	
	TextReplacements.Insert("&TextOfPackagingUnitField",
		"ItemsPrices.Package");
	
	TextReplacements.Insert("&TextOfPriceField",
		"CAST(ISNULL(ItemsPrices.Price, 0)
		|	* CASE
		|		WHEN &Currency <> ItemsPrices.Currency
		|			THEN CASE
		|				WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
		|				AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
		|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
		|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
		|					THEN RatesCutCurrencyPrices.CourseNumerator
		|						* CrossSectionRatesDocumentCurrency.CourseDenominator
		|						/ (CrossSectionRatesDocumentCurrency.CourseNumerator
		|						* RatesCutCurrencyPrices.CourseDenominator)
		|				ELSE 0
		|			END
		|		ELSE 1
		|	END AS NUMBER(31,2))");
	
	TextReplacements.Insert("&FieldTextAvailableBalance",
		"CAST(&AllBalancesInStock / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
	
	TextReplacements.Insert("&TextOfAvailableQuantityField",
		"CAST(&AllLeftoversAreAvailable / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
	
	If QueryConstructionParameters.ListType = "ListProducts" Then
		
		If QueryConstructionParameters.UsePriceManagementSystem25 Then
			
			ConditionAccordingToPricingVersion =
				"ItemsPrices.Products = CatalogProducts.Ref
				|AND ItemsPrices.PricingVariant = VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)";
			
		Else
			
			ConditionAccordingToPricingVersion =
				"ItemsPrices.Products = CatalogProducts.Ref";
			
		EndIf;
		
		TextMainTable =
			TableTextMainCatalogTable(QueryConstructionParameters) +
			TextOfConnectionWithBalanceTable(QueryConstructionParameters) +
			"
			|		INNER JOIN ProductRange AS ProductRange
			|		ON CatalogProducts.Ref = ProductRange.Products
			|		AND ProductRange.SalesAreAllowed
			|
			|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
			|		ON CatalogProducts.Ref = ItemsPrices.Products
			|		AND &ConditionAccordingToPricingVersion
			|		AND ProductRange.PriceKind = ItemsPrices.PriceKind
			|
			|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
			|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
			|
			|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
			|		ON TRUE";
		
		TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
		
	Else
		
		If QueryConstructionParameters.UsePriceManagementSystem25 Then
			
			ConditionAccordingToPricingVersion =
				"ItemsPrices.Products = &Products
				|AND ItemsPrices.PricingVariant =
				|	CASE
				|		WHEN CAST(&ProductKind AS Catalog.ItemKinds).SettingsOfPriceKeyByItemVariant =
				|		VALUE(Enum.FilterOptionForPriceKey.DontUse)
				|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
				|		ELSE ItemsCharacteristics.ItemsCharacteristicForPricing
				|	END";
			
		Else
			
			ConditionAccordingToPricingVersion =
				"ItemsPrices.Products = &Products
				|AND ItemsPrices.Characteristic = ItemsCharacteristics.Ref";
			
		EndIf;
		
		TextMainTable =
			TableTextMainCatalogTable(QueryConstructionParameters) +
			TextOfConnectionWithBalanceTable(QueryConstructionParameters) +
			"
			|		INNER JOIN ProductRange AS ProductRange
			|		ON ProductRange.SalesAreAllowed
			|
			|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
			|		ON &ConditionAccordingToPricingVersion
			|
			|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
			|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
			|
			|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
			|		ON TRUE";
		
		TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
		
	EndIf;
	
	TextMainTable = StrReplace(TextMainTable,
		"&ConditionAccordingToPricingVersion",
		ConditionAccordingToPricingVersion);
	
	TextReplacements.Insert("#MainTable", TextMainTable);
	
EndProcedure

// Performs the construction of a query for lists of items and characteristics according to the parameters of the agreement with the client.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
Procedure GenerateQueryTextAccordingToParametersOfAgreementWithClient(QueryConstructionParameters)
	
	If Not ValueIsFilled(QueryConstructionParameters.QueryTemplate) Then
		Return;
	EndIf;
	
	Variants = Enums.PriceCalculationOptionsByTermsOfSales;
	TextReplacements = QueryConstructionParameters.TextReplacements;
	
	If QueryConstructionParameters.PriceCalculationOption <> Variants.WithoutPrices Then
		
		QueryConstructionParameters.TemporaryTable.Add("TableOfExchangeRates");
		QueryConstructionParameters.TemporaryTable.Add("GeneralTableOfExchangeRates");
		
	EndIf;
	
	If QueryConstructionParameters.PriceCalculationOption = Variants.WithoutPrices Then
		
		TextReplacements.Insert("&TextOfPackagingUnitField", "VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
		TextReplacements.Insert("&TextOfPriceTypeField", "VALUE(Catalog.TypesOfPrices.EmptyRef)");
		TextReplacements.Insert("&TextOfPriceField", "0");
		TextReplacements.Insert("&FieldTextAvailableBalance", "CAST(&AllBalancesInStock AS NUMBER(15, 3))");
		TextReplacements.Insert("&TextOfAvailableQuantityField", "CAST(&AllLeftoversAreAvailable AS NUMBER(15, 3))");
		
		TextReplacements.Insert("#MainTable",
			TableTextMainCatalogTable(QueryConstructionParameters)
			+ TextOfConnectionWithBalanceTable(QueryConstructionParameters));
		
		TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
		
	ElsIf QueryConstructionParameters.UsePriceManagementSystem25 Then
		
		If QueryConstructionParameters.PriceCalculationOption = Variants.PricesKindInHeader Then
			
			TextReplacements.Insert("&TextOfPackagingUnitField",
				"ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))");
			TextReplacements.Insert("&TextOfPriceTypeField", "&TypesOfPrices");
			TextReplacements.Insert("&TextOfPriceField",
				"CAST(ISNULL(ItemsPrices.Price, 0)
				|	* CASE
				|		WHEN &Currency <> ItemsPrices.Currency
				|			THEN CASE
				|				WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
				|				AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
				|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
				|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
				|					THEN RatesCutCurrencyPrices.CourseNumerator
				|						* CrossSectionRatesDocumentCurrency.CourseDenominator
				|						/ (CrossSectionRatesDocumentCurrency.CourseNumerator
				|						* RatesCutCurrencyPrices.CourseDenominator)
				|				ELSE 0
				|			END
				|		ELSE 1
				|	END AS NUMBER(31,2))");
			
			TextReplacements.Insert("&FieldTextAvailableBalance",
				"CAST(&AllBalancesInStock / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
			TextReplacements.Insert("&TextOfAvailableQuantityField",
				"CAST(&AllLeftoversAreAvailable / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
			
			If QueryConstructionParameters.ListType = "ListProducts" Then
				
				TextReplacements.Insert("#MainTable",
					TableTextMainCatalogTable(QueryConstructionParameters) +
					TextOfConnectionWithBalanceTable(QueryConstructionParameters) +
					"
					|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
					|		ON ItemsPrices.Products = CatalogProducts.Ref
					|
					|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
					|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
					|
					|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
					|		ON TRUE");
				
				TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
				
			Else
				
				TextReplacements.Insert("#MainTable",
					TableTextMainCatalogTable(QueryConstructionParameters) +
					TextOfConnectionWithBalanceTable(QueryConstructionParameters) +
					"
					|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
					|		ON ItemsPrices.PricingVariant =
					|			CASE
					|				WHEN CAST(&ProductKind AS Catalog.ItemKinds).SettingsOfPriceKeyByItemVariant =
					|				VALUE(Enum.FilterOptionForPriceKey.DontUse)
					|					THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
					|				ELSE ItemsCharacteristics.ItemsCharacteristicForPricing
					|			END
					|
					|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
					|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
					|
					|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
					|		ON TRUE");
				
				TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
				
			EndIf;
			
		ElsIf QueryConstructionParameters.PriceCalculationOption = Variants.PricesKindInHeaderAndAdjustedPricesByItems Then
			
			TextReplacements.Insert("&TextOfPackagingUnitField",
				"CASE
				|	WHEN ISNULL(IndividualProductPrices.Price, 0) > 0
				|		THEN ISNULL(IndividualProductPrices.Package,
				|			VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
				|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
				|END");
				
			TextReplacements.Insert("&TextOfPriceTypeField",
				"CASE
				|	WHEN ISNULL(IndividualProductPrices.Price, 0) > 0
				|		THEN IndividualProductPrices.PriceKind
				|	ELSE ISNULL(ItemsPrices.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
				|END");
				
			TextReplacements.Insert("&TextOfPriceField",
				"CAST(CASE
				|	WHEN ISNULL(IndividualProductPrices.Price, 0) > 0
				|		THEN IndividualProductPrices.Price
				|		* CASE
				|			WHEN &Currency <> IndividualProductPrices.Currency
				|				THEN CASE
				|					WHEN ISNULL(RatesCrossSectionCurrencyIndividualPrices.CourseDenominator, 0) > 0
				|					AND ISNULL(RatesCrossSectionCurrencyIndividualPrices.CourseNumerator, 0) > 0
				|					AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
				|					AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
				|						THEN RatesCrossSectionCurrencyIndividualPrices.CourseNumerator
				|							* CrossSectionRatesDocumentCurrency.CourseDenominator
				|							/ (CrossSectionRatesDocumentCurrency.CourseNumerator
				|							* RatesCrossSectionCurrencyIndividualPrices.CourseDenominator)
				|					ELSE 0
				|				END
				|			ELSE 1
				|		END
				|	ELSE ItemsPrices.Price
				|	* CASE
				|		WHEN &Currency <> ItemsPrices.Currency
				|			THEN CASE
				|				WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
				|				AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
				|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
				|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
				|					THEN RatesCutCurrencyPrices.CourseNumerator
				|						* CrossSectionRatesDocumentCurrency.CourseDenominator
				|						/ (CrossSectionRatesDocumentCurrency.CourseNumerator
				|							* RatesCutCurrencyPrices.CourseDenominator)
				|					ELSE 0
				|				END
				|			ELSE 1
				|		END
				|	END AS NUMBER(31,2))");
			
			If QueryConstructionParameters.ListType = "ListProducts" Then
				
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock
					|	/ CASE
					|		WHEN ISNULL(IndividualProductPrices.Price, 0) > 0
					|			THEN ISNULL(&QueryTextPackagingFactor3, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable
					|	/ CASE
					|		WHEN ISNULL(IndividualProductPrices.Price, 0) > 0
					|			THEN ISNULL(&QueryTextPackagingFactor3, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				
				TextReplacements.Insert("#MainTable",
					TableTextMainCatalogTable(QueryConstructionParameters) +
					TextOfConnectionWithBalanceTable(QueryConstructionParameters) +
					"
					|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
					|		ON ItemsPrices.Products = CatalogProducts.Ref
					|
					|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
					|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
					|
					|		LEFT JOIN &TableOfIndividualItemPrices AS IndividualProductPrices
					|		ON IndividualProductPrices.Products = CatalogProducts.Ref
					|
					|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCrossSectionCurrencyIndividualPrices
					|		ON IndividualProductPrices.Currency = RatesCrossSectionCurrencyIndividualPrices.Currency
					|
					|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
					|		ON TRUE");
				
				TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
				
			Else
				
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
				
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
				
				TextReplacements.Insert("#MainTable",
					TableTextMainCatalogTable(QueryConstructionParameters) +
					TextOfConnectionWithBalanceTable(QueryConstructionParameters) +
					"
					|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
					|		ON ItemsPrices.PricingVariant =
					|			CASE
					|				WHEN CAST(&ProductKind AS Catalog.ItemKinds).SettingsOfPriceKeyByItemVariant =
					|				VALUE(Enum.FilterOptionForPriceKey.DontUse)
					|					THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
					|				ELSE ItemsCharacteristics.ItemsCharacteristicForPricing
					|			END
					|
					|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
					|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
					|
					|		LEFT JOIN &TableOfIndividualItemPrices AS IndividualProductPrices
					|		ON IndividualProductPrices.PricingVariant =
					|			CASE
					|				WHEN CAST(&ProductKind AS Catalog.ItemKinds).SettingsOfPriceKeyByItemVariant =
					|				VALUE(Enum.FilterOptionForPriceKey.DontUse)
					|					THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
					|				ELSE ItemsCharacteristics.ItemsCharacteristicForPricing
					|			END
					|
					|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCrossSectionCurrencyIndividualPrices
					|		ON IndividualProductPrices.Currency = RatesCrossSectionCurrencyIndividualPrices.Currency
					|
					|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
					|		ON TRUE");
				
				TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
				
			EndIf;
			
		EndIf;
		
	Else
		
		If QueryConstructionParameters.ListType = "ListProducts" Then
			
			TextMainTable =
				TableTextMainCatalogTable(QueryConstructionParameters)
				+ TextOfConnectionWithBalanceTable(QueryConstructionParameters);
			
			TextCommonConnections =
				"
				|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
				|		ON CatalogProducts.Ref = ItemsPrices.Products
				|		AND &AdditionalConditionOfConnectionByPrices
				|		
				|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
				|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
				|
				|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
				|		ON TRUE";
			
			TableAgreementHeader = False;
			TableAgreementGoods = False;
			TableAgreementPriceGroups = False;
			
			TextGeneralCondition = TextSelectionGeneralCondition(QueryConstructionParameters);
			
			If QueryConstructionParameters.PriceCalculationOption =
				Variants.PricesKindInHeaderAndPricesKindsByPriceGroups Then
				
				TableAgreementHeader = True;
				TableAgreementPriceGroups = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"ISNULL(AgreementPriceGroups.PricesKind, AgreementHeader_.PricesKind)");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(CASE
					|	WHEN CASE
					|				WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementPriceGroups.PricesKind
					|				WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) = VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|			END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			AND ISNULL(ItemsPrices.Price, 0) > 0
					|		THEN ItemsPrices.Price * CASE
					|				WHEN &Currency <> ItemsPrices.Currency
					|					THEN CASE
					|							WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|									AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	ELSE 0
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind =
				|	CASE
				|		WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementPriceGroups.PricesKind
				|		WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) =
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
				|	END";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PriceTypeInHeaderAndPriceTypesByItems Then
				
				TableAgreementHeader = True;
				TableAgreementGoods = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|		THEN AgreementGoods.Package
					|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|	VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementGoods.PriceKind
					|	ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(CASE
					|	WHEN CASE
					|				WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementGoods.PriceKind
					|				WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) = VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|			END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			AND ISNULL(ItemsPrices.Price, 0) > 0
					|		THEN ItemsPrices.Price * CASE
					|				WHEN &Currency <> ItemsPrices.Currency
					|					THEN CASE
					|							WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|									AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	ELSE 0
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind =
				|	CASE
				|		WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementGoods.PriceKind
				|		WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) =
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
				|	END";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PricesKindInHeaderPricesKindsByItemsAndAdjustedPricesByItems Then
				
				TableAgreementHeader = True;
				TableAgreementGoods = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|	WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|	VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|	WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|	VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementGoods.PriceKind
					|	ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN AgreementGoods.Price * CASE
					|				WHEN &Currency <> AgreementGoods.Ref.Currency
					|					THEN CASE
					|							WHEN ISNULL(CutRatesAgreementCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CutRatesAgreementCurrency.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN CutRatesAgreementCurrency.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * CutRatesAgreementCurrency.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	WHEN CASE
					|				WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|					THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|				WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementGoods.PriceKind
					|				WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) = VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|			END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			AND ISNULL(ItemsPrices.Price, 0) > 0
					|		THEN ItemsPrices.Price * CASE
					|				WHEN &Currency <> ItemsPrices.Currency
					|					THEN CASE
					|							WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|									AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	ELSE 0
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock / 
					|	CASE
					|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|		VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind =
				|	CASE
				|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
				|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
				|		WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementGoods.PriceKind
				|		WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) =
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
				|	END";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PricesKindInHeaderAndAdjustedPricesByItems Then
					
				TableAgreementHeader = True;
				TableAgreementGoods = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|	WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|	VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementGoods.PriceKind
					|	ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN AgreementGoods.Price * CASE
					|				WHEN &Currency <> AgreementGoods.Ref.Currency
					|					THEN CASE
					|							WHEN ISNULL(CutRatesAgreementCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CutRatesAgreementCurrency.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN CutRatesAgreementCurrency.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * CutRatesAgreementCurrency.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	WHEN CASE
					|				WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|					THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|				WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementGoods.PriceKind
					|				WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) = VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|			END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			AND ISNULL(ItemsPrices.Price, 0) > 0
					|		THEN ItemsPrices.Price * CASE
					|				WHEN &Currency <> ItemsPrices.Currency
					|					THEN CASE
					|							WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|									AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	ELSE 0
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind =
				|	CASE
				|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
				|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
				|		WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementGoods.PriceKind
				|		WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) =
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
				|	END";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PricesKindInHeaderPricesKindsByPriceGroupsAndPricesKindsByItems Then
				
				TableAgreementHeader = True;
				TableAgreementGoods = True;
				TableAgreementPriceGroups = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|		THEN AgreementGoods.Package
					|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|	VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementGoods.PriceKind
					|	WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|	VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementPriceGroups.PricesKind
					|	ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(CASE
					|	WHEN CASE
					|				WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementGoods.PriceKind
					|				WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementPriceGroups.PricesKind
					|				ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|			END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			AND ISNULL(ItemsPrices.Price, 0) > 0
					|		THEN ItemsPrices.Price * CASE
					|				WHEN &Currency <> ItemsPrices.Currency
					|					THEN CASE
					|							WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|									AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	ELSE 0
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind =
				|	CASE
				|		WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementGoods.PriceKind
				|		WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementPriceGroups.PricesKind
				|		ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
				|	END";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PricesKindInHeaderPricesKindsByPriceGroupsAndPricesKindsByItemsRefined Then
				
				TableAgreementHeader = True;
				TableAgreementGoods = True;
				TableAgreementPriceGroups = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|		THEN AgreementGoods.Package
					|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|	WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|	VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementGoods.PriceKind
					|	WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|	VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementPriceGroups.PricesKind
					|	ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN AgreementGoods.Price * CASE
					|				WHEN &Currency <> AgreementGoods.Ref.Currency
					|					THEN CASE
					|							WHEN ISNULL(CutRatesAgreementCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CutRatesAgreementCurrency.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN CutRatesAgreementCurrency.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * CutRatesAgreementCurrency.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	WHEN CASE
					|				WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementGoods.PriceKind
					|				WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementPriceGroups.PricesKind
					|				ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|			END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			AND ISNULL(ItemsPrices.Price, 0) > 0
					|		THEN ItemsPrices.Price * CASE
					|				WHEN &Currency <> ItemsPrices.Currency
					|					THEN CASE
					|							WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|									AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	ELSE 0
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind =
				|	CASE
				|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
				|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
				|		WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementGoods.PriceKind
				|		WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementPriceGroups.PricesKind
				|		ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
				|	END";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PricesKindInHeaderPricesKindsByPriceGroupsAndAdjustedPricesByItems Then
				
				TableAgreementHeader = True;
				TableAgreementGoods = True;
				TableAgreementPriceGroups = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|		THEN AgreementGoods.Package
					|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|	WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|	VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementPriceGroups.PricesKind
					|	ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN AgreementGoods.Price * CASE
					|				WHEN &Currency <> AgreementGoods.Ref.Currency
					|					THEN CASE
					|							WHEN ISNULL(CutRatesAgreementCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CutRatesAgreementCurrency.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN CutRatesAgreementCurrency.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * CutRatesAgreementCurrency.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	WHEN CASE
					|				WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementPriceGroups.PricesKind
					|				ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|			END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			AND ISNULL(ItemsPrices.Price, 0) > 0
					|		THEN ItemsPrices.Price * CASE
					|				WHEN &Currency <> ItemsPrices.Currency
					|					THEN CASE
					|							WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|									AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	ELSE 0
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind =
				|	CASE
				|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
				|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
				|		WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementPriceGroups.PricesKind
				|		ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
				|	END";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PriceTypesByPriceGroupsAndPriceTypesByItems Then
				
				TableAgreementGoods = True;
				TableAgreementPriceGroups = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|		THEN AgreementGoods.Package
					|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|	VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementGoods.PriceKind
					|	ELSE ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(CASE
					|	WHEN CASE
					|				WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementGoods.PriceKind
					|				ELSE ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|			END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			AND ISNULL(ItemsPrices.Price, 0) > 0
					|		THEN ItemsPrices.Price * CASE
					|				WHEN &Currency <> ItemsPrices.Currency
					|					THEN CASE
					|							WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|									AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	ELSE 0
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind =
				|	CASE
				|		WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementGoods.PriceKind
				|		ELSE ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
				|	END";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PriceTypesByPriceGroupsPriceTypesByItemsAndAdjustedPricesByItems Then
				
				TableAgreementHeader = True;
				TableAgreementGoods = True;
				TableAgreementPriceGroups = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|		THEN AgreementGoods.Package
					|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|	WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|	VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementGoods.PriceKind
					|	ELSE ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN AgreementGoods.Price * CASE
					|				WHEN &Currency <> AgreementGoods.Ref.Currency
					|					THEN CASE
					|							WHEN ISNULL(CutRatesAgreementCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CutRatesAgreementCurrency.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN CutRatesAgreementCurrency.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * CutRatesAgreementCurrency.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	WHEN CASE
					|				WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementGoods.PriceKind
					|				ELSE ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|			END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			AND ISNULL(ItemsPrices.Price, 0) > 0
					|		THEN ItemsPrices.Price * CASE
					|				WHEN &Currency <> ItemsPrices.Currency
					|					THEN CASE
					|							WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|									AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	ELSE 0
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) <>
					|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind =
				|	CASE
				|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
				|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
				|		WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementGoods.PriceKind
				|		WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementPriceGroups.PricesKind
				|		ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
				|	END";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PriceTypesByPriceGroupsAndAdjustedPricesByItems Then
				
				TableAgreementHeader = True;
				TableAgreementGoods = True;
				TableAgreementPriceGroups = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|	ELSE ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN AgreementGoods.Price * CASE
					|				WHEN &Currency <> AgreementGoods.Ref.Currency
					|					THEN CASE
					|							WHEN ISNULL(CutRatesAgreementCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CutRatesAgreementCurrency.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN CutRatesAgreementCurrency.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * CutRatesAgreementCurrency.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	WHEN CASE
					|				WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|					THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|				ELSE ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|			END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			AND ISNULL(ItemsPrices.Price, 0) > 0
					|		THEN ItemsPrices.Price * CASE
					|				WHEN &Currency <> ItemsPrices.Currency
					|					THEN CASE
					|							WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|									AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	ELSE 0
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind =
				|	CASE
				|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
				|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
				|		WHEN ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementPriceGroups.PricesKind
				|		ELSE ISNULL(AgreementHeader_.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
				|	END";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PricesKindInHeader Then
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"&TypesOfPrices");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(ISNULL(ItemsPrices.Price, 0) * CASE
					|	WHEN &Currency <> ItemsPrices.Currency
					|		THEN CASE
					|				WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|						AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|						AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|						AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|					THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|				ELSE 0
					|			END
					|	ELSE 1
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind = &TypesOfPrices";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PriceTypesByPriceGroups Then
				
				TableAgreementPriceGroups = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"ISNULL(AgreementPriceGroups.PricesKind, VALUE(Catalog.TypesOfPrices.EmptyRef))");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(ISNULL(ItemsPrices.Price, 0) * CASE
					|	WHEN &Currency <> ItemsPrices.Currency
					|		THEN CASE
					|				WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|						AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|						AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|						AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|					THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|				ELSE 0
					|			END
					|	ELSE 1
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind = AgreementPriceGroups.PricesKind";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PriceTypesByItems Then
				
				TableAgreementGoods = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef))");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(ISNULL(ItemsPrices.Price, 0) * CASE
					|	WHEN &Currency <> ItemsPrices.Currency
					|		THEN CASE
					|				WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|						AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|						AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|						AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|					THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|				ELSE 0
					|			END
					|	ELSE 1
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock / ISNULL(&QueryTextPackagingFactor4, 1) AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable / ISNULL(&QueryTextPackagingFactor4, 1) AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind = AgreementGoods.PriceKind";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.PriceTypesByItemsAndAdjustedPricesByItems Then
				
				TableAgreementGoods = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|	OR ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|	VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|	ELSE ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|	ELSE ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef))
					|END");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN AgreementGoods.Price * CASE
					|				WHEN &Currency <> AgreementGoods.Ref.Currency
					|					THEN CASE
					|							WHEN ISNULL(CutRatesAgreementCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CutRatesAgreementCurrency.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN CutRatesAgreementCurrency.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * CutRatesAgreementCurrency.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	WHEN CASE
					|			WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|				THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|				THEN AgreementGoods.PriceKind
					|		END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN ISNULL(ItemsPrices.Price, 0) * CASE
					|				WHEN &Currency <> ItemsPrices.Currency
					|					THEN CASE
					|							WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|									AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	ELSE 0
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		OR ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|		VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable
					|	/ CASE
					|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		OR ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
					|		VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			THEN ISNULL(&QueryTextPackagingFactor4, 1)
					|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
					|	END AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"ItemsPrices.PriceKind =
				|	CASE
				|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
				|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
				|		WHEN ISNULL(AgreementGoods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) <>
				|		VALUE(Catalog.TypesOfPrices.EmptyRef)
				|			THEN AgreementGoods.PriceKind
				|	END";
				
			ElsIf QueryConstructionParameters.PriceCalculationOption =
				Variants.OnlySpecifiedPricesOfItems Then
				
				TableAgreementGoods = True;
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"ISNULL(AgreementGoods.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"VALUE(Catalog.TypesOfPrices.EmptyRef)");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(ISNULL(AgreementGoods.Price, 0) * CASE
					|	WHEN &Currency <> AgreementGoods.Ref.Currency
					|		THEN CASE
					|				WHEN ISNULL(CutRatesAgreementCurrency.CourseDenominator, 0) > 0
					|						AND ISNULL(CutRatesAgreementCurrency.CourseNumerator, 0) > 0
					|						AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|						AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|					THEN CutRatesAgreementCurrency.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * CutRatesAgreementCurrency.CourseDenominator)
					|				ELSE 0
					|			END
					|	ELSE 1
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock / ISNULL(&QueryTextPackagingFactor4, 1) AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable / ISNULL(&QueryTextPackagingFactor4, 1) AS NUMBER(15, 3))");
				
				AdditionalConditionOfConnectionByPrices =
				"FALSE";
				
			EndIf;
			
			If TableAgreementHeader Then
				
				TextCommonConnections = 
					"
					|		LEFT JOIN Catalog.TermsOfSale AS AgreementHeader_
					|		ON AgreementHeader_.Ref = &Terms"
					+ TextCommonConnections;
				
			EndIf;
			
			If TableAgreementGoods Then
				
				TextCommonConnections = 
					"
					|		LEFT JOIN Catalog.TermsOfSale.Goods AS AgreementGoods
					|		ON AgreementGoods.Ref = &Terms
					|		AND CatalogProducts.Ref = AgreementGoods.Products
					|		AND AgreementGoods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
					|
					|		LEFT JOIN GeneralTableOfExchangeRates AS CutRatesAgreementCurrency
					|		ON AgreementGoods.Ref.Currency = CutRatesAgreementCurrency.Currency"
					+ TextCommonConnections;
				
			EndIf;
			
			If TableAgreementPriceGroups Then
				
				TextCommonConnections = 
					"
					|		LEFT JOIN Catalog.TermsOfSale.PriceGroups AS AgreementPriceGroups
					|		ON AgreementPriceGroups.Ref = &Terms
					|		AND CatalogProducts.PriceGroup = AgreementPriceGroups.PriceGroup"
					+ TextCommonConnections;
				
			EndIf;
			
		Else
			
			If QueryConstructionParameters.PriceCalculationOption =
				Variants.PricesKindInHeader Then
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"&TypesOfPrices");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(ISNULL(ItemsPrices.Price, 0) * CASE
					|	WHEN &Currency <> ItemsPrices.Currency
					|		THEN CASE
					|				WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|						AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|						AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|						AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|					THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|				ELSE 0
					|			END
					|	ELSE 1
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
				
				TextMainTable =
					TableTextMainCatalogTable(QueryConstructionParameters)
					+ TextOfConnectionWithBalanceTable(QueryConstructionParameters);
				
				TextCommonConnections =
					"
					|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
					|		ON ItemsPrices.Characteristic = ItemsCharacteristics.Ref
					|		AND &AdditionalConditionOfConnectionByPrices
					|		
					|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
					|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
					|
					|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
					|		ON TRUE";
				
				AdditionalConditionOfConnectionByPrices = "ItemsPrices.PriceKind = &TypesOfPrices";
				
			Else
				
				TextReplacements.Insert("&TextOfPackagingUnitField",
					"ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))");
				TextReplacements.Insert("&TextOfPriceTypeField",
					"CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|	WHEN AgreementGoods.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			AND AgreementGoods.PriceKind IS NOT NULL 
					|		THEN AgreementGoods.PriceKind
					|	WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			OR AgreementGoods.PriceKind IS NULL )
					|			AND AgreementPriceGroups.PricesKind IS NOT NULL 
					|			AND AgreementPriceGroups.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementPriceGroups.PricesKind
					|	WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			OR AgreementGoods.PriceKind IS NULL )
					|			AND (AgreementPriceGroups.PricesKind IS NULL 
					|				OR AgreementPriceGroups.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef))
					|			AND AgreementHeader_.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementHeader_.PricesKind
					|END");
				TextReplacements.Insert("&TextOfPriceField",
					"CAST(CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN AgreementGoods.Price * CASE
					|				WHEN &Currency <> AgreementGoods.Ref.Currency
					|					THEN CASE
					|							WHEN ISNULL(CutRatesAgreementCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CutRatesAgreementCurrency.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN CutRatesAgreementCurrency.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * CutRatesAgreementCurrency.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	WHEN CASE
					|				WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|					THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|				WHEN AgreementGoods.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|						AND AgreementGoods.PriceKind IS NOT NULL 
					|					THEN AgreementGoods.PriceKind
					|				WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
					|						OR AgreementGoods.PriceKind IS NULL )
					|						AND AgreementPriceGroups.PricesKind IS NOT NULL 
					|						AND AgreementPriceGroups.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementPriceGroups.PricesKind
					|				WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
					|						OR AgreementGoods.PriceKind IS NULL )
					|						AND (AgreementPriceGroups.PricesKind IS NULL 
					|							OR AgreementPriceGroups.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef))
					|						AND AgreementHeader_.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|					THEN AgreementHeader_.PricesKind
					|			END <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|			AND ISNULL(ItemsPrices.Price, 0) > 0
					|		THEN ItemsPrices.Price * CASE
					|				WHEN &Currency <> ItemsPrices.Currency
					|					THEN CASE
					|							WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
					|									AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
					|									AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
					|								THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
					|							ELSE 0
					|						END
					|				ELSE 1
					|			END
					|	ELSE 0
					|END AS NUMBER(31,2))");
				TextReplacements.Insert("&FieldTextAvailableBalance",
					"CAST(&AllBalancesInStock / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
				TextReplacements.Insert("&TextOfAvailableQuantityField",
					"CAST(&AllLeftoversAreAvailable / ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15, 3))");
				
				TextMainTable =
					TableTextMainCatalogTable(QueryConstructionParameters)
					+ TextOfConnectionWithBalanceTable(QueryConstructionParameters);
				
				TextCommonConnections =
					"
					|		LEFT JOIN Catalog.TermsOfSale AS AgreementHeader_
					|		ON AgreementHeader_.Ref = &Terms
					|
					|		LEFT JOIN Catalog.TermsOfSale.Goods AS AgreementGoods
					|		ON AgreementGoods.Ref = &Terms
					|		AND &Products = AgreementGoods.Products
					|		AND AgreementGoods.Characteristic = ItemsCharacteristics.Ref
					|
					|		LEFT JOIN Catalog.TermsOfSale.PriceGroups AS AgreementPriceGroups
					|		ON AgreementPriceGroups.Ref = &Terms
					|		AND AgreementPriceGroups.PriceGroup = &PriceGroup
					|
					|		LEFT JOIN &TableOfPriceOfItemOfEnterprise AS ItemsPrices
					|		ON ItemsPrices.Characteristic = ItemsCharacteristics.Ref
					|		AND &AdditionalConditionOfConnectionByPrices
					|		
					|		LEFT JOIN GeneralTableOfExchangeRates AS CutRatesAgreementCurrency
					|		ON AgreementGoods.Ref.Currency = CutRatesAgreementCurrency.Currency
					|
					|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
					|		ON ItemsPrices.Currency = RatesCutCurrencyPrices.Currency
					|
					|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
					|		ON TRUE";
				
				AdditionalConditionOfConnectionByPrices =
					"(ItemsPrices.PriceKind = CASE
					|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
					|		THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
					|	WHEN AgreementGoods.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|	AND AgreementGoods.PriceKind IS NOT NULL 
					|		THEN AgreementGoods.PriceKind
					|	WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
					|	OR AgreementGoods.PriceKind IS NULL )
					|	AND AgreementPriceGroups.PricesKind IS NOT NULL 
					|	AND AgreementPriceGroups.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementPriceGroups.PricesKind
					|	WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
					|	OR AgreementGoods.PriceKind IS NULL )
					|	AND (AgreementPriceGroups.PricesKind IS NULL 
					|	OR AgreementPriceGroups.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef))
					|	AND AgreementHeader_.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
					|		THEN AgreementHeader_.PricesKind
					|END)";
				
			EndIf;
			
			TextGeneralCondition = TextSelectionGeneralCondition(QueryConstructionParameters);
			
		EndIf;
		
		TextCommonConnections = StrReplace(TextCommonConnections,
			"&AdditionalConditionOfConnectionByPrices",
			AdditionalConditionOfConnectionByPrices);
		
		TextReplacements.Insert("#MainTable",
			TextMainTable
			+ TextCommonConnections);
		
		TextReplacements.Insert("&TextGeneralCondition",
			TextGeneralCondition + StrTemplate("
				|{WHERE
				|	%1 AS Price}",
				TextReplacements.Get("&TextOfPriceField")));
		
	EndIf;
	
EndProcedure

// Builds a query for lists of items and characteristics based on the parameters of the agreement with the supplier.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
Procedure GenerateQueryTextBasedOnParametersOfAgreementWithSupplier(QueryConstructionParameters)
	
	If Not ValueIsFilled(QueryConstructionParameters.QueryTemplate) Then
		Return;
	EndIf;
	
	TextReplacements = QueryConstructionParameters.TextReplacements;
	
	If QueryConstructionParameters.SupplierPriceCalculationOption = "WithoutPrices" Then
		
		If QueryConstructionParameters.ListType = "ListOfThePartnerSNomenclature" Then
			
			TextReplacements.Insert("&TextOfPriceField", "0");
			TextReplacements.Insert("&FieldTextVendorPriceType", "VALUE(Catalog.VendorPriceTypes.EmptyRef)");
			
			TextReplacements.Insert("#MainTable",
				"Catalog.ProductCrossReferences AS CatalogProductCrossReferences
				|		
				|		LEFT JOIN Catalog.Products AS CatProducts_
				|		ON CatalogProductCrossReferences.Products = CatProducts_.Ref");
			
			TextReplacements.Insert("&TextGeneralCondition", "&SelectionOfNomenclatureOfCounterpartiesForGroup");
			
		ElsIf QueryConstructionParameters.ListType = "ListProducts"
			Or QueryConstructionParameters.ListType = "FeatureList" Then
			
			TextReplacements.Insert("&TextOfPackagingUnitField", "VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
			TextReplacements.Insert("&TextOfPriceField", "0");
			TextReplacements.Insert("&FieldTextCurrency", "VALUE(Catalog.Currencies.EmptyRef)");
			TextReplacements.Insert("&FieldTextAvailableBalance", "CAST(&AllBalancesInStock AS NUMBER(15, 3))");
			TextReplacements.Insert("&TextOfAvailableQuantityField", "CAST(&AllLeftoversAreAvailable AS NUMBER(15, 3))");
			
			If QueryConstructionParameters.ListType = "ListProducts" Then
				
				TextReplacements.Insert("#MainTable",
					TableTextMainCatalogTable(QueryConstructionParameters)
					+ TextOfConnectionWithBalanceTable(QueryConstructionParameters));
				
				TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
				
			Else
				
				TextReplacements.Insert("#MainTable",
					TableTextMainCatalogTable(QueryConstructionParameters)
					+ TextOfConnectionWithBalanceTable(QueryConstructionParameters));
				
				TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
				
			EndIf;
			
		EndIf;
		
	ElsIf QueryConstructionParameters.SupplierPriceCalculationOption = "PricesByAgreement" Then
		
		QueryConstructionParameters.TemporaryTable.Add("TableOfExchangeRates");
		QueryConstructionParameters.TemporaryTable.Add("GeneralTableOfExchangeRates");
		
		If QueryConstructionParameters.ListType = "ListOfThePartnerSNomenclature" Then
			
			TextReplacements.Insert("&TextOfPriceField",
				"CAST(ISNULL(ItemsPricesOfVendor.Price, 0)
				|	* CASE
				|		WHEN &Currency <> ItemsPricesOfVendor.Currency
				|			THEN CASE
				|				WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
				|				AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
				|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
				|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
				|				THEN RatesCutCurrencyPrices.CourseNumerator
				|					* CrossSectionRatesDocumentCurrency.CourseDenominator
				|					/ (CrossSectionRatesDocumentCurrency.CourseNumerator
				|					* RatesCutCurrencyPrices.CourseDenominator)
				|			ELSE 0
				|		END
				|	ELSE 1
				|END AS NUMBER(31,2))");
			
			TextReplacements.Insert("&FieldTextVendorPriceType", "ItemsPricesOfVendor.VendorPriceKind");
			
			TextReplacements.Insert("#MainTable",
				"Catalog.ProductCrossReferences AS CatalogProductCrossReferences
				|
				|		LEFT JOIN &SupplierItemPriceTable AS ItemsPricesOfVendor
				|		ON ItemsPricesOfVendor.Products = CatalogProductCrossReferences.Products
				|		AND ItemsPricesOfVendor.Characteristic = CatalogProductCrossReferences.Characteristic
				|		AND ItemsPricesOfVendor.VendorPriceKind = &VendorPriceKind
				|
				|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
				|		ON RatesCutCurrencyPrices.Currency = ItemsPricesOfVendor.Currency
				|
				|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
				|		ON TRUE
				|
				|		LEFT JOIN Catalog.Products AS CatProducts_
				|		ON CatalogProductCrossReferences.Products = CatProducts_.Ref");
			
			TextReplacements.Insert("&TextGeneralCondition", "&SelectionOfNomenclatureOfCounterpartiesForGroup");
			
		ElsIf QueryConstructionParameters.ListType = "ListProducts"
			Or QueryConstructionParameters.ListType = "FeatureList" Then
			
			TextReplacements.Insert("&TextOfPackagingUnitField",
				"ISNULL(ItemsPricesOfVendor.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))");
			
			TextReplacements.Insert("&TextOfPriceField",
				"CAST((CAST(ISNULL(ItemsPricesOfVendor.Price, 0) AS NUMBER(31,2)))
				|	* CASE
				|		WHEN &Currency <> ItemsPricesOfVendor.Currency
				|			THEN CASE
				|				WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
				|				AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
				|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
				|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
				|				THEN RatesCutCurrencyPrices.CourseNumerator
				|					* CrossSectionRatesDocumentCurrency.CourseDenominator
				|					/ (CrossSectionRatesDocumentCurrency.CourseNumerator
				|					* RatesCutCurrencyPrices.CourseDenominator)
				|			ELSE 0
				|		END
				|	ELSE 1
				|END AS NUMBER(31,2))");
			
			TextReplacements.Insert("&FieldTextCurrency",
				"ISNULL(ItemsPricesOfVendor.Currency, VALUE(Catalog.Currencies.EmptyRef))");
			
			TextReplacements.Insert("&FieldTextAvailableBalance",
				"CAST(&AllBalancesInStock / ISNULL(&QueryTextPackagingFactor2, 1) AS NUMBER(15, 3))");
			
			TextReplacements.Insert("&TextOfAvailableQuantityField",
				"CAST(&AllLeftoversAreAvailable / ISNULL(&QueryTextPackagingFactor2, 1) AS NUMBER(15, 3))");
			
			If QueryConstructionParameters.ListType = "ListProducts" Then
				
				TextReplacements.Insert("#MainTable",
					TableTextMainCatalogTable(QueryConstructionParameters) +
					"
					|		LEFT JOIN &SupplierItemPriceTable AS ItemsPricesOfVendor
					|		ON ItemsPricesOfVendor.Products = CatalogProducts.Ref
					|		AND ItemsPricesOfVendor.VendorPriceKind = &VendorPriceKind
					|
					|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
					|		ON RatesCutCurrencyPrices.Currency = ItemsPricesOfVendor.Currency
					|
					|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
					|		ON TRUE
					|" +
					TextOfConnectionWithBalanceTable(QueryConstructionParameters));
				
				TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
				
			Else
				
				TextReplacements.Insert("#MainTable",
					TableTextMainCatalogTable(QueryConstructionParameters) +
					"
					|		LEFT JOIN &SupplierItemPriceTable AS ItemsPricesOfVendor
					|		ON ItemsPricesOfVendor.Characteristic = ItemsCharacteristics.Ref
					|		AND ItemsPricesOfVendor.VendorPriceKind = &VendorPriceKind
					|
					|		LEFT JOIN GeneralTableOfExchangeRates AS RatesCutCurrencyPrices
					|		ON RatesCutCurrencyPrices.Currency = ItemsPricesOfVendor.Currency
					|
					|		LEFT JOIN TableOfExchangeRates AS CrossSectionRatesDocumentCurrency
					|		ON TRUE
					|" +
					TextOfConnectionWithBalanceTable(QueryConstructionParameters));
				
				TextReplacements.Insert("&TextGeneralCondition", TextSelectionGeneralCondition(QueryConstructionParameters));
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#Region StringReplacements

// Performs template replacements in the text of a dynamic list query.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
Procedure PerformTemplateReplacementsInQueryText(QueryConstructionParameters)
	
	// 1) the substitutions accumulated during the construction of the template contain templates of sample fields, expressions and conditions
	For Each MapItem In QueryConstructionParameters.TextReplacements Do
		
		QueryConstructionParameters.QueryTemplate = StrReplace(
			QueryConstructionParameters.QueryTemplate,
			MapItem.Key,
			MapItem.Value);
		
	EndDo;
	
	// 2) substitutions of sample fields, contain templates of expressions and conditions
	If QueryConstructionParameters.ListType = "ListProducts" Then
		FieldTextCommonFields = TextOfSelectionFieldsListItem();
	ElsIf QueryConstructionParameters.ListType = "FeatureList" Then
		FieldTextCommonFields = TextOfSelectionFieldsListOfCharacteristics(QueryConstructionParameters);
	ElsIf QueryConstructionParameters.ListType = "ListOfThePartnerSNomenclature" Then
		FieldTextCommonFields = TextOfSelectionFieldsListOfPartnerItems();
	EndIf;
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&FieldTextCommonFields",
		FieldTextCommonFields);
	
	// 3) substitutions of expressions and conditions
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&SubqueryGoodsBalances",
		TextOfGoodsBalanceSubquery(QueryConstructionParameters));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&TableOfPriceOfItemOfEnterprise",
		TextOfPriceTableOfItemOfEnterprise(QueryConstructionParameters));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&SupplierItemPriceTable",
		TextOfPriceTableOfItemOfSuppliers(QueryConstructionParameters));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&TableOfIndividualItemPrices",
		TableTextIndividualItemPrices(QueryConstructionParameters));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&SelectingProductsByGroup",
		"NOT CatalogProducts.IsFolder");
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&SelectionOfNomenclatureOfCounterpartiesForGroup",
		"NOT CatalogProductCrossReferences.IsFolder");
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&PricesOfSupplierProductsCutByDate",
		?(QueryConstructionParameters.ThereAreProductPricesOfSuppliersInTheFuture,
			"&Date",
			""));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&TextOfFieldIsAvailableInBasicUnits",
		"&AllBalancesInStock");
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&ItemsFilterByPrice20",
		TextSelectionOfItemsAtPriceOf20(QueryConstructionParameters));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&SelectionOfProductsAtPriceOf25",
		TextSelectionOfItemsAtPriceOf25(QueryConstructionParameters));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&SetPricingOption",
		?(QueryConstructionParameters.UseKits,
			"ProductKitConfigurations.SetPricingOption",
			"VALUE(Enum.SetPriceCalculationOptions.EmptyRef)"));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&SetContainsProducts",
		?(QueryConstructionParameters.UseKits,
			"ProductKitConfigurations.ContainsGoods",
			"FALSE"));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&SetContainsServices",
		?(QueryConstructionParameters.UseKits,
			"ProductKitConfigurations.ContainsServices",
			"FALSE"));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"AND &SelectingProductsBySegment",
		"{WHERE
		|	(1 IN
		|		(SELECT TOP 1
		|			1
		|		FROM
		|			InformationRegister.SegmentProducts AS Segments
		|		WHERE
		|			Segments.Products = CatalogProducts.Ref
		|			AND Segments.Segment = &ProductSegment))}");
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&SelectionOfCharacteristicsByOwner",
		"ItemsCharacteristics.Owner = &ItemVariantsOwner");
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"AND &SelectingCharacteristicsBySegment",
		"{WHERE
		|	(1 IN
		|		(SELECT TOP 1
		|			1
		|		FROM
		|			InformationRegister.SegmentProducts AS Segments
		|		WHERE
		|			Segments.Characteristic = ItemsCharacteristics.Ref
		|			AND Segments.Products = &SegmentProducts
		|			AND Segments.Segment = &ProductSegment))}");
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&AllBalancesInStock", "ISNULL(AllBalance.InStock, 0)");
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&AllLeftoversAreAvailable",
		"ISNULL(AllBalance.Available, 0)");
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemsPrices.Package",
			"ItemsPrices.Products"));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemsPricesOfVendor.Package",
			"ItemsPricesOfVendor.Products"));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&QueryTextPackagingFactor3",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"IndividualProductPrices.Package",
			"IndividualProductPrices.Products"));
	
	QueryConstructionParameters.QueryTemplate = StrReplace(
		QueryConstructionParameters.QueryTemplate,
		"&QueryTextPackagingFactor4",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"AgreementGoods.Package",
			"AgreementGoods.Products"));
	
EndProcedure

// Returns the text of the selection fields from the Item Catalog.
//
// Returns:
// 	String
//
Function TextOfSelectionFieldsListItem()
	
	Result =
	"CatalogProducts.Ref AS Ref,
	|CatalogProducts.SKU AS SKU,
	|CatalogProducts.Code AS Code,
	|CatalogProducts.Description AS Description,
	|CatalogProducts.DeletionMark AS DeletionMark,
	|CatalogProducts.Parent AS Parent,
	|CatalogProducts.IsFolder AS IsFolder,
	|CatalogProducts.Ref AS Products,
	|CatalogProducts.Ref AS ListItem,
	|CatalogProducts.ProductKind AS ProductKind,
	|CatalogProducts.ItemsType AS ItemsType,
	|CASE
	|	WHEN CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Set)
	|		THEN ISNULL(&SetPricingOption, VALUE(Enum.SetPriceCalculationOptions.EmptyRef))
	|	ELSE VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|END AS SetPricingOption,
	|&SetContainsProducts AS ContainsGoods,
	|&SetContainsServices AS ContainsServices,
	|CatalogProducts.UnitOfMeasure AS UnitOfMeasure,
	|CatalogProducts.PriceGroup AS PriceGroup,
	|CatalogProducts.Quality AS Quality,
	|CatalogProducts.UseVariants AS UseVariants,
	|CASE
	|	WHEN CatalogProducts.ItemsType IN
	|	(VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|		THEN TRUE
	|	WHEN CatalogProducts.ItemsType IN
	|	(VALUE(Enum.ItemsTypes.Set))
	|	AND ISNULL(&SetContainsProducts, FALSE)
	|	AND NOT ISNULL(&SetContainsServices, FALSE)
	|		THEN TRUE
	|	ELSE FALSE
	|END AS ThisIsAProduct,
	|CASE
	|	WHEN CatalogProducts.ItemsType IN
	|	(VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
	|		THEN TRUE
	|	WHEN CatalogProducts.ItemsType IN
	|	(VALUE(Enum.ItemsTypes.Set))
	|	AND ISNULL(&SetContainsServices, FALSE)
	|	AND NOT ISNULL(&SetContainsProducts, FALSE)
	|		THEN TRUE
	|	ELSE FALSE
	|END AS IsService,
	|CASE
	|	WHEN CatalogProducts.UseVariants =
	|	VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|		THEN CatalogProducts.ProductKind
	|	WHEN CatalogProducts.UseVariants =
	|	VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|		THEN CatalogProducts.Ref
	|	WHEN CatalogProducts.UseVariants =
	|	VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|		THEN CatalogProducts.ItemVariantsOwner
	|	ELSE UNDEFINED
	|END AS ItemVariantsOwner,
	|CASE
	|	WHEN CatalogProducts.UseVariants =
	|	VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|		THEN FALSE
	|	ELSE TRUE
	|END AS ItemVariantsAreUsed,
	|CASE
	|	WHEN CatalogProducts.IsFolder
	|		THEN CASE
	|			WHEN CatalogProducts.DeletionMark
	|				THEN 13
	|			ELSE 12
	|		END
	|	ELSE CASE
	|		WHEN CatalogProducts.ThereAreGoodsOfOtherQuality
	|			THEN 4 + CASE
	|				WHEN CatalogProducts.DeletionMark
	|					THEN 1
	|				ELSE 0
	|			END + CASE
	|				WHEN CatalogProducts.UseVariants =
	|				VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|					THEN 0
	|				ELSE 2
	|			END
	|		ELSE -1 + CASE
	|			WHEN CatalogProducts.DeletionMark
	|				THEN 1
	|			ELSE 0
	|		END + CASE
	|			WHEN CatalogProducts.UseVariants =
	|			VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|				THEN 1
	|			ELSE 3
	|		END
	|	END
	|END AS PictureIndex";
	
	Return Result;
	
EndFunction

// Returns the text of the selection fields from the Characteristics Catalog.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
// Returns:
// 	String
//
Function TextOfSelectionFieldsListOfCharacteristics(QueryConstructionParameters)
	
	If QueryConstructionParameters.UsePriceManagementSystem25 Then
		
		Result =
		"ItemsCharacteristics.Ref AS Ref,
		|ItemsCharacteristics.Ref AS Characteristic,
		|ItemsCharacteristics.DeletionMark AS DeletionMark,
		|TRUE AS ItemVariantsAreUsed,
		|CAST(&Products AS Catalog.Products) AS Products,
		|CAST(&ItemsType AS Enum.ItemsTypes) AS ItemsType,
		|CASE
		|	WHEN CAST(&ProductKind AS Catalog.ItemKinds).SettingsOfPriceKeyByItemVariant =
		|	VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|		THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|	ELSE ItemsCharacteristics.ItemsCharacteristicForPricing
		|END AS PricingVariant,
		|CASE WHEN &ItemsType = VALUE(Enum.ItemsTypes.Set) THEN
		|	ISNULL(&SetPricingOption, VALUE(Enum.SetPriceCalculationOptions.EmptyRef))
		|ELSE
		|	VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
		|END AS SetPricingOption,
		|&SetContainsProducts AS ContainsGoods,
		|&SetContainsServices AS ContainsServices,
		|CAST(&ProductKind AS Catalog.ItemKinds) AS ProductKind,
		|CAST(&UnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure) AS UnitOfMeasure,
		|&ItemVariantsOwner,
		|CASE
		|	WHEN ItemsCharacteristics.DeletionMark
		|		THEN 1
		|	ELSE 0
		|END AS PictureIndex";
		
	Else
		
		Result =
		"ItemsCharacteristics.Ref AS Ref,
		|ItemsCharacteristics.Ref AS Characteristic,
		|ItemsCharacteristics.DeletionMark AS DeletionMark,
		|TRUE AS ItemVariantsAreUsed,
		|CAST(&Products AS Catalog.Products) AS Products,
		|CAST(&ItemsType AS Enum.ItemsTypes) AS ItemsType,
		|CASE WHEN &ItemsType = VALUE(Enum.ItemsTypes.Set) THEN
		|	ISNULL(&SetPricingOption, VALUE(Enum.SetPriceCalculationOptions.EmptyRef))
		|ELSE
		|	VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
		|END AS SetPricingOption,
		|&SetContainsProducts AS ContainsGoods,
		|&SetContainsServices AS ContainsServices,
		|CAST(&ProductKind AS Catalog.ItemKinds) AS ProductKind,
		|CAST(&UnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure) AS UnitOfMeasure,
		|&ItemVariantsOwner,
		|CASE
		|	WHEN ItemsCharacteristics.DeletionMark
		|		THEN 1
		|	ELSE 0
		|END AS PictureIndex";
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the text of the selection fields from the Catalog of Agent Nomenclature.
//
// Returns:
// 	String
//
Function TextOfSelectionFieldsListOfPartnerItems()
	
	Result =
	"CatalogProductCrossReferences.DeletionMark AS DeletionMark,
	|CatalogProductCrossReferences.Predefined AS Predefined,
	|CatalogProductCrossReferences.Owner AS Owner,
	|CatalogProductCrossReferences.Parent AS Parent,
	|CatalogProductCrossReferences.IsFolder AS IsFolder,
	|CatalogProductCrossReferences.Description AS Description,
	|CatalogProductCrossReferences.Products AS Products,
	|CatalogProductCrossReferences.Products.ItemsType AS ItemsType,
	|CatalogProductCrossReferences.Products.UseVariants AS UseVariants,
	|CatalogProductCrossReferences.Products.DescriptionFull AS DescriptionFull,
	|CatalogProductCrossReferences.Characteristic AS Characteristic,
	|CatProducts_.UnitOfMeasure AS UnitOfMeasure,
	|CASE
	|	WHEN CatProducts_.UnitOfMeasure IS NULL
	|		THEN CatalogProductCrossReferences.Package
	|	ELSE CASE
	|		WHEN CatProducts_.UnitOfMeasure = CatalogProductCrossReferences.Package
	|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		ELSE CatalogProductCrossReferences.Package
	|	END
	|END AS Package,
	|CatalogProductCrossReferences.SKU AS SKU,
	|CatalogProductCrossReferences.Code AS Code,
	|CatalogProductCrossReferences.Ref AS Ref,
	|CASE
	|	WHEN CatalogProductCrossReferences.Products.UseVariants =
	|	VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|		THEN FALSE
	|	ELSE TRUE
	|END AS ItemVariantsAreUsed,
	|CASE
	|	WHEN CatalogProductCrossReferences.Products.ItemsType IN
	|	(VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|		THEN TRUE
	|	ELSE FALSE
	|END AS ThisIsAProduct,
	|CASE
	|	WHEN CatalogProductCrossReferences.Products.ItemsType IN
	|	(VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
	|		THEN TRUE
	|	ELSE FALSE
	|END AS IsService,
	|CASE
	|	WHEN CatalogProductCrossReferences.IsFolder
	|		THEN CASE
	|				WHEN CatalogProductCrossReferences.DeletionMark
	|					THEN 13
	|				ELSE 12
	|			END
	|END AS PictureIndex";
	
	Return Result;
	
EndFunction

// Returns the text of the pricing condition 2.0.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
// Returns:
// 	String
//
Function TextSelectionOfItemsAtPriceOf20(QueryConstructionParameters)
	
	Return ?(QueryConstructionParameters.SelectionModeWithoutAmountParameters,
		"TRUE",
		"CASE
		|	WHEN CatalogProducts.UseVariants =
		|	VALUE(Enum.ItemVariantsUsageOptions.DontUse)
		|		THEN FALSE
		|	ELSE TRUE
		|END
		|OR CASE
		|	WHEN ISNULL(AgreementGoods.Price, 0) > 0
		|		THEN AgreementGoods.Price
		|			* CASE
		|				WHEN &Currency <> AgreementGoods.Ref.Currency
		|					THEN CASE
		|						WHEN ISNULL(CutRatesAgreementCurrency.CourseDenominator, 0) > 0
		|						AND ISNULL(CutRatesAgreementCurrency.CourseNumerator, 0) > 0
		|						AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
		|						AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
		|							THEN CutRatesAgreementCurrency.CourseNumerator
		|								* CrossSectionRatesDocumentCurrency.CourseDenominator
		|								/ (CrossSectionRatesDocumentCurrency.CourseNumerator
		|								* CutRatesAgreementCurrency.CourseDenominator)
		|						ELSE 0
		|					END
		|				ELSE 1
		|			END
		|	WHEN CASE
		|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
		|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
		|		WHEN AgreementGoods.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
		|		AND AgreementGoods.PriceKind IS NOT NULL
		|			THEN AgreementGoods.PriceKind
		|		WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
		|			OR AgreementGoods.PriceKind IS NULL)
		|		AND AgreementPriceGroups.PricesKind IS NOT NULL
		|		AND AgreementPriceGroups.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
		|			THEN AgreementPriceGroups.PricesKind
		|		WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
		|			OR AgreementGoods.PriceKind IS NULL)
		|		AND (AgreementPriceGroups.PricesKind IS NULL
		|			OR AgreementPriceGroups.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef))
		|		AND AgreementHeader_.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
		|			THEN AgreementHeader_.PricesKind
		|	END <> VALUE(Catalog.TypesOfPrices.EmptyRef) AND ISNULL(ItemsPrices.Price, 0) > 0
		|		THEN ItemsPrices.Price * CASE
		|			WHEN &Currency <> ItemsPrices.Currency
		|				THEN CASE
		|					WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
		|					AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
		|					AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
		|					AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
		|						THEN RatesCutCurrencyPrices.CourseNumerator
		|							* CrossSectionRatesDocumentCurrency.CourseDenominator
		|							/ (CrossSectionRatesDocumentCurrency.CourseNumerator
		|							* RatesCutCurrencyPrices.CourseDenominator)
		|					ELSE 0
		|				END
		|			ELSE 1
		|		END
		|	ELSE 0
		|END <> 0
		|OR &SetPricingOption =
		|VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)");
	
EndFunction

// Returns the text of the general condition.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
// 	AdditionalCondition - String
//
// Returns:
// 	String
//
Function TextSelectionGeneralCondition(QueryConstructionParameters, AdditionalCondition = "")
	
	If QueryConstructionParameters.ListType = "ListProducts" Then
		
		Result =
			"&SelectingProductsByGroup
			|AND &SelectingProductsBySegment";
	Else
		
		Result =
			"&SelectionOfCharacteristicsByOwner
			|AND &SelectingCharacteristicsBySegment";
		
	EndIf;
	
	Return Result
		+ ?(ValueIsFilled(AdditionalCondition),
			Chars.LF + AdditionalCondition,
			"");
	
EndFunction

// Returns the text of the pricing condition 2.5.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
// Returns:
// 	String
//
Function TextSelectionOfItemsAtPriceOf25(QueryConstructionParameters)
	
	Return ?(QueryConstructionParameters.SelectionModeWithoutAmountParameters,
		"TRUE",
		"CASE
		|	WHEN CatalogProducts.UseVariants =
		|	VALUE(Enum.ItemVariantsUsageOptions.DontUse)
		|		THEN FALSE
		|	ELSE TRUE
		|END OR CASE
		|	WHEN ISNULL(IndividualProductPrices.Price, 0) > 0
		|		THEN IndividualProductPrices.Price * CASE
		|			WHEN &Currency <> IndividualProductPrices.Currency
		|				THEN CASE
		|					WHEN ISNULL(RatesCrossSectionCurrencyIndividualPrices.CourseDenominator, 0) > 0
		|					AND ISNULL(RatesCrossSectionCurrencyIndividualPrices.CourseNumerator, 0) > 0
		|					AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
		|					AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
		|						THEN RatesCrossSectionCurrencyIndividualPrices.CourseNumerator
		|							* CrossSectionRatesDocumentCurrency.CourseDenominator
		|							/ (CrossSectionRatesDocumentCurrency.CourseNumerator
		|							* RatesCrossSectionCurrencyIndividualPrices.CourseDenominator)
		|					ELSE 0
		|				END
		|			ELSE 1
		|		END
		|	ELSE ItemsPrices.Price * CASE
		|		WHEN &Currency <> ItemsPrices.Currency
		|			THEN CASE
		|				WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
		|				AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
		|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
		|				AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
		|					THEN RatesCutCurrencyPrices.CourseNumerator
		|						* CrossSectionRatesDocumentCurrency.CourseDenominator
		|						/ (CrossSectionRatesDocumentCurrency.CourseNumerator
		|						* RatesCutCurrencyPrices.CourseDenominator)
		|					ELSE 0
		|				END
		|			ELSE 1
		|		END
		|	END <> 0
		|OR &SetPricingOption =
		|VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)");
	
EndFunction

// Returns the text of the table in the Item Catalog or the characteristics of the item with configuration options.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
// Returns:
// 	String
//
Function TableTextMainCatalogTable(QueryConstructionParameters)
	
	If QueryConstructionParameters.ListType = "ListProducts" Then
		
		Result =
			"Catalog.Products AS CatalogProducts"
				+ ?(QueryConstructionParameters.UseKits,
				"
				|
				|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
				|		ON ProductKitConfigurations.Owner = CatalogProducts.Ref
				|		AND ProductKitConfigurations.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
				|		AND ProductKitConfigurations.Main",
				"");
		
	Else
		
		Result =
			"Catalog.ItemsCharacteristics AS ItemsCharacteristics"
				+ ?(QueryConstructionParameters.UseKits,
				"
				|
				|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
				|		ON ProductKitConfigurations.Owner = &Products
				|		AND ItemsCharacteristics.Ref = ProductKitConfigurations.Characteristic
				|		AND ProductKitConfigurations.Main",
				"");
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the text of the table of individual item prices.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
// Returns:
// 	String
//
Function TableTextIndividualItemPrices(QueryConstructionParameters)
	
	TableText =
	"InformationRegister.ItemsPrices25.SliceLast(&SelectionCriteriaByDate, PriceKind = &TheTypeOfPricesIsIndividual
	|			AND &ConditionByListType
	|			AND PricingBatch = VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|			AND PricingPackage = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) {Products.* AS Products}
	|			{Products.Parent.* AS Parent} {Products.ProductKind.* AS ProductKind})";
	
	SelectionCriteriaByDate = ?(QueryConstructionParameters.ThereArePricesInTheFuture,
		"ENDOFPERIOD(&DATE, DAY)",
		"");
	
	TableText = StrReplace(TableText,
		"&SelectionCriteriaByDate",
		SelectionCriteriaByDate);
	
	ConditionByListType = ?(QueryConstructionParameters.ListType = "ListProducts",
		"PricingVariant = VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)",
		"Products = &Products");
	
	TableText = StrReplace(TableText,
		"&ConditionByListType",
		ConditionByListType);
	
	Return TableText;
	
EndFunction

// Returns the text of the price table of the item of the enterprise.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
// Returns:
// 	String
//
Function TextOfPriceTableOfItemOfEnterprise(QueryConstructionParameters)
	
	If QueryConstructionParameters.UsePriceManagementSystem25 Then
		
		TableText =
		"InformationRegister.ItemsPrices25.SliceLast(&SelectionCriteriaByDate, &SelectionConditionByTypeOfPrices
		|			AND &ConditionByListType
		|			AND PricingBatch = VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
		|			AND PricingPackage = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) {Products.* AS Products}
		|			{Products.Parent.* AS Parent} {Products.ProductKind.* AS ProductKind})";
		
		SelectionCriteriaByDate = ?(QueryConstructionParameters.ThereArePricesInTheFuture,
			"ENDOFPERIOD(&DATE, DAY)",
			"");
		
		TableText = StrReplace(TableText,
			"&SelectionCriteriaByDate",
			SelectionCriteriaByDate);
		
		If QueryConstructionParameters.DoNotUsePriceTypesBasedOnTheSalesCondition Then
			
			SelectionConditionByTypeOfPrices =
				?(QueryConstructionParameters.SeveralPriceTypes,
				"PriceKind IN (&TypesOfPrices)",
				"PriceKind = &TypesOfPrices");
			
		Else
			SelectionConditionByTypeOfPrices = "PriceKind = &MainPriceType";
		EndIf;
		
		TableText = StrReplace(TableText,
			"&SelectionConditionByTypeOfPrices",
			SelectionConditionByTypeOfPrices);
		
		ConditionByListType = ?(QueryConstructionParameters.ListType = "ListProducts",
			"PricingVariant = VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)",
			"Products = &Products");
		
		TableText = StrReplace(TableText,
			"&ConditionByListType",
			ConditionByListType);
		
	Else
		
		TableText =
		"InformationRegister.ItemsPrices.SliceLast(&SelectionCriteriaByDate, &SelectionConditionByTypeOfPrices
		|		AND &ConditionByListType {Products.* AS Products} {Products.Parent.* AS Parent}
		|			{Products.ProductKind.* AS ProductKind})";
		
		SelectionCriteriaByDate = ?(QueryConstructionParameters.ThereArePricesInTheFuture,
			"ENDOFPERIOD(&DATE, DAY)",
			"");
		
		TableText = StrReplace(TableText,
			"&SelectionCriteriaByDate",
			SelectionCriteriaByDate);
		
		SelectionConditionByTypeOfPrices =
			?(QueryConstructionParameters.SeveralPriceTypes,
			"PriceKind IN (&TypesOfPrices)",
			"PriceKind = &TypesOfPrices");
		
		TableText = StrReplace(TableText,
			"&SelectionConditionByTypeOfPrices",
			SelectionConditionByTypeOfPrices);
		
		ConditionByListType = ?(QueryConstructionParameters.ListType = "ListProducts",
			"Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)",
			"Products = &Products");
		
		TableText = StrReplace(TableText,
			"&ConditionByListType",
			ConditionByListType);
		
	EndIf;
	
	Return TableText;
	
EndFunction

// Returns the text of the price table of the supplier item list.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
// Returns:
// 	String
//
Function TextOfPriceTableOfItemOfSuppliers(QueryConstructionParameters)
	
	TableText =
	"InformationRegister.ItemsPricesOfVendor.SliceLast(&PricesOfSupplierProductsCutByDate,
	|			VendorPriceKind = &VendorPriceKind
	|			AND &ConditionByListType {Products.* AS Products} {Products.Parent.* AS Parent}
	|			{Products.ProductKind.* AS ProductKind})";
	
	If QueryConstructionParameters.ListType = "ListOfThePartnerSNomenclature" Then
		
		ConditionByListType = "TRUE";
		
	ElsIf QueryConstructionParameters.ListType = "ListProducts" Then
		
		ConditionByListType = "Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)";
		
	ElsIf QueryConstructionParameters.ListType = "FeatureList" Then
		
		ConditionByListType = "Products = &Products";
		
	EndIf;
	
	TableText = StrReplace(TableText,
		"&ConditionByListType",
		ConditionByListType);
	
	Return TableText;
	
EndFunction

// Returns the text of the subquery to the goods Balance.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
// Returns:
// 	String
//
Function TextOfGoodsBalanceSubquery(QueryConstructionParameters)
	
	SubqueryText =
	"SELECT
	|	&TextOfDimensionField AS ConnectionField,
	|	SUM(Distribution_Table.InStock) AS InStock,
	|	SUM(Distribution_Table.Available) AS Available
	|FROM
	|	InformationRegister.AvailableStockBalances AS Distribution_Table
	|WHERE
	|	&TextOfSelectionByWarehouse
	|	AND Distribution_Table.Purpose = &Purpose
	|	AND Distribution_Table.ControlledLotReference = &ControlledLotReference
	|	AND &TextBalancesInWarehouses
	|	AND &SelectionTextByItem
	|{WHERE
	|	Distribution_Table.Products.* AS Products,
	|	Distribution_Table.Products.ProductKind.* AS ProductKind,
	|	Distribution_Table.Products.Parent.* AS Parent,
	|	Distribution_Table.Characteristic.* AS Characteristic,
	|	Distribution_Table.Warehouse.* AS Warehouse}
	|GROUP BY
	|	&TextOfDimensionField";
	
	If QueryConstructionParameters.ListType = "ListProducts"
		Or QueryConstructionParameters.ListType = "ListOfThePartnerSNomenclature" Then
		
		TextOfDimensionField = "Distribution_Table.Products";
		SelectionTextByItem = "TRUE";
		
	ElsIf QueryConstructionParameters.ListType = "FeatureList" Then
		
		TextOfDimensionField = "Distribution_Table.Characteristic";
		SelectionTextByItem = "Distribution_Table.Products = &Products";
		
	EndIf;
	
	// The grouping field
	SubqueryText = StrReplace(SubqueryText,
		"&TextOfDimensionField",
		TextOfDimensionField);
	
	// condition text
	SubqueryText = StrReplace(SubqueryText,
		"&SelectionTextByItem",
		SelectionTextByItem);
		
	// The Text Of The Selection By Warehouse
	TextOfSelectionByWarehouse = ?(QueryConstructionParameters.MultipleWarehouses,
		"Distribution_Table.Warehouse IN (&Warehouse)",
		"Distribution_Table.Warehouse = &Warehouse");
	
	SubqueryText = StrReplace(SubqueryText,
		"&TextOfSelectionByWarehouse",
		TextOfSelectionByWarehouse);
		
	// the text of the condition by destination
	If Not QueryConstructionParameters.DisplayBalancesAsIntended Then
		
		SubqueryText = StrReplace(SubqueryText,
			"&Purpose",
			"VALUE(Catalog.Assignments.EmptyRef)");
		
	EndIf;
	
	// the text of the condition for the controlled Lot reference
	If Not QueryConstructionParameters.DisplayBalanceOfControlledLotReference Then
		
		SubqueryText = StrReplace(SubqueryText,
			"&ControlledLotReference",
			"VALUE(Catalog.ControlledLots.EmptyRef)");
		
	EndIf;
	
	// condition for displaying Balances
	TextBalancesInWarehouses = ?(QueryConstructionParameters.DisplayRemainingQuantityInWarehouses,
		"TRUE",
		"FALSE");
	
	SubqueryText = StrReplace(SubqueryText,
		"&TextBalancesInWarehouses",
		TextBalancesInWarehouses);
	
	Return StrTemplate("(%1)", SubqueryText);
	
EndFunction

// Returns the text of the connection to the goods Balance table.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
// Returns:
// 	String
//
Function TextOfConnectionWithBalanceTable(QueryConstructionParameters)
	
	If QueryConstructionParameters.ListType = "ListProducts" Then
		
		Result =
			?(QueryConstructionParameters.OnlyInStock,
				"
				|		INNER JOIN &SubqueryGoodsBalances AS AllBalance
				|		ON CatalogProducts.Ref = AllBalance.ConnectionField",
				"
				|		LEFT JOIN &SubqueryGoodsBalances AS AllBalance
				|		ON CatalogProducts.Ref = AllBalance.ConnectionField");
		
	Else
		
		Result =
			?(QueryConstructionParameters.OnlyInStock,
				"
				|		INNER JOIN &SubqueryGoodsBalances AS AllBalance
				|		ON ItemsCharacteristics.Ref = AllBalance.ConnectionField",
				"
				|		LEFT JOIN &SubqueryGoodsBalances AS AllBalance
				|		ON ItemsCharacteristics.Ref = AllBalance.ConnectionField")
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the text of creating a temporary table with exchange rates.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
// 	CurrencySelection_2 - Boolean
//
// Returns:
// 	String
//
Function TextOfTemporaryCurrencyExchangeRatesTable(QueryConstructionParameters, CurrencySelection_2)
	
	TemporaryTableText =
	"SELECT
	|	RateTable.Currency AS Currency,
	|	RateTable.CourseNumerator AS CourseNumerator,
	|	RateTable.CourseDenominator AS CourseDenominator
	|INTO TempTableName
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&SelectionCriteriaByDate, BaseCurrency = &BaseCurrency
	|		AND &CurrencySelectionCriteria) AS RateTable";
	
	SelectionCriteriaByDate = ?(QueryConstructionParameters.ThereAreRatessInFuture,
		"ENDOFPERIOD(&DATE, DAY)",
		"");
	
	TemporaryTableText = StrReplace(TemporaryTableText,
		"&SelectionCriteriaByDate",
		SelectionCriteriaByDate);
	
	TemporaryTableText = StrReplace(TemporaryTableText,
		"&CurrencySelectionCriteria",
		?(CurrencySelection_2,
			"Currency = &Currency",
			"TRUE {Currency.* AS Currency}"));
	
	Return TemporaryTableText;
	
EndFunction

// Returns the text for creating a temporary table with assortment data.
//
// Parameters:
// 	QueryConstructionParameters - See SelectGoodsClientServer.NewParametersForBuildingListQuery
//
// Returns:
// 	String
//
Function TextOfTemporaryProductRangeTable(QueryConstructionParameters)
	
	TemporaryTableText =
	"SELECT
	|	ProductRange.Products AS Products,
	|	ProductRange.PriceKind AS PriceKind,
	|	ProductRange.SalesAreAllowed AS SalesAreAllowed
	|INTO TempTableName
	|FROM
	|	InformationRegister.ProductRange.SliceLast(ENDOFPERIOD(&Date, DAY), PlanningObject = &PlanningObject
	|	AND &ConditionByListType) AS ProductRange
	|
	|INDEX BY
	|	Products,
	|	PriceKind";
	
	ConditionByListType = ?(QueryConstructionParameters.ListType = "ListProducts",
		"TRUE {(Products).* AS Products}",
		"Products = &Products");
	
	TemporaryTableText = StrReplace(TemporaryTableText,
		"&ConditionByListType",
		ConditionByListType);
	
	Return TemporaryTableText;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion