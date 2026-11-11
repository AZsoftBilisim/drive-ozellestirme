
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	PriceKind                        = Parameters.PriceKind;
	Price                           = Parameters.Price;
	Date                           = Parameters.Date;
	DateOfShipment                   = Parameters.DateOfShipment;
	Warehouse                          = Parameters.Warehouse;
	Products                   = Parameters.Products;
	Characteristic                 = Parameters.Characteristic;
	Package                       = Parameters.Package;
	Currency                         = Parameters.Currency;
	PriceIncludesVAT                = Parameters.PriceIncludesVAT;
	If Not Parameters.Property("UsePriceManagementSystem25", UsePriceManagementSystem25) Then
		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(Date);
	EndIf;
	
	EditPriceType           = Parameters.EditPriceType;
	
	Parameters.Property("WithoutFilterByVATInclusionInPrice", WithoutFilterByVATInclusionInPrice);
	Parameters.Property("WithoutFilterByUseWhileSellingToCustomersInPrice", WithoutFilterByUseWhileSellingToCustomersInPrice);
	
	ProductStructure_ = Common.ObjectAttributesValues(Products, "UnitOfMeasure, UsePackages");
		
	If ProductStructure_.UsePackages Then
		Items.Package.InputHint = ProductStructure_.UnitOfMeasure;
	EndIf;
		
	OldPackaging            = Package;
	
	ProductName = "" + Parameters.Products + ?(ValueIsFilled(Parameters.Characteristic), " (" + Parameters.Characteristic + ")","");
	
	
	If ValueIsFilled(PriceKind) Then
		PriceKindPresentation  = PriceKind;
	Else
		PriceKindPresentation  = NStr("vi = '<tùy ý>';
										|ru = '<произвольная>';
										|en = '<custom>'; fa = '<سفارشی>';
										|it = '<arbitraria>';
										|pl = '<dowolny>';
										|tr = '<isteğe bağlı>'");
	EndIf;
	
	If Parameters.HidePrice Then
		Items.Price.Visible    = False;
		Items.DecorationTitlePrice.Visible  = False;
		Items.PriceKindPresentation.Visible    = False;
		Items.Currency.Visible  = False;
		ThisForm.AutoTitle     = False;
		ThisForm.Title         = NStr("vi = 'Nhập số lượng';
										|ru = 'Ввод количества';
										|en = 'Enter quantity'; fa = 'ورود مقدار';
										|it = 'Inserimento quantità';
										|pl = 'Wprowadzanie ilości';
										|tr = 'Miktar girin'");
	EndIf;
	
	If Not Parameters.UseShipmentDates Then
		Items.DateOfShipment.Visible = False;
	EndIf;
	
	If Parameters.ItemsType = Enums.ItemsTypes.OperationService Then
		DateOfShipment = '00010101';
		Warehouse = Catalogs.Warehouses.EmptyRef();
		Items.DateOfShipment.Visible = False;
	EndIf;
	
	If Not Parameters.UseWarehousesInTheTablePart
		Or Parameters.Warehouses.Find(Warehouse) = Undefined Then
		Warehouse = Undefined;
	EndIf;
	
	Items.Warehouse.Visible = Not Parameters.ItemsType = Enums.ItemsTypes.OperationService
		And Not Parameters.ItemsType = Enums.ItemsTypes.Work_5
		And Parameters.Warehouses.Count() > 1
		And Parameters.UseWarehousesInTheTablePart;
	Items.DecorationTitleWarehouse.Visible = Items.Warehouse.Visible;
		
	TMCommonUseClientServer.AddSelectionParameter(Items.Warehouse, "Ref", Parameters.Warehouses);
	
	StructureOfMeasurementsIndicationsInDocuments = Common.ObjectAttributesValues(Products, "AreaCanBeSpecifiedInDocuments, VolumeCanBeSpecifiedInDocuments, YouCanSpecifyWeightInDocuments, YouCanSpecifyLengthInDocuments");
	If StructureOfMeasurementsIndicationsInDocuments.AreaCanBeSpecifiedInDocuments
		Or StructureOfMeasurementsIndicationsInDocuments.YouCanSpecifyWeightInDocuments
		Or StructureOfMeasurementsIndicationsInDocuments.VolumeCanBeSpecifiedInDocuments
		Or StructureOfMeasurementsIndicationsInDocuments.YouCanSpecifyLengthInDocuments
		Or ValueIsFilled(Common.ObjectAttributeValue(Products, "PackagingGroup")) Then
		
		Items.Package.Visible = True;
		Items.UnitOfMeasure.Visible = False;
		Items.Package.InputHint = ProductStructure_.UnitOfMeasure;
	Else
		Items.Package.Visible = False;
		Items.UnitOfMeasure.Visible = True;
	EndIf;
	
	NumberOfPackages = 1;
	
	Items.Price.Enabled = Parameters.EditPriceType;
	
	FillInListOfPrices();
	
	// Adjust visibility and set the values of the details for editing manual discounts, margins.
	DocumentAmount = NumberOfPackages * Price;
	
	If Not Parameters.UseDiscountAdjustmentsInSales Or Parameters.HideManualDiscounts Then
		
		Items.GroupParametersDiscountsMarkups.Visible = False;
		
	Else
		
		// Set the properties of the elements related to discounts (margins).
		UseRestrictionsOfManualDiscounts = (GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByUsers")
		                                      Or GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales"));
		
		If UseRestrictionsOfManualDiscounts Then
			
			TableStructure = GetFromTempStorage(Parameters.AddressInTempStorage);
			
			MaxDiscountPercentage  = TableStructure.Restrictions[0].MaximumPercentageForManualDiscount;
			MaxMarkupPercentage = TableStructure.Restrictions[0].MaximumPercentageForManualMarkup;
			
			If MaxDiscountPercentage > 0 Then
				Items.PercentRateOfManualDiscountMarkup.ChoiceListButton = True;
				Items.PercentRateOfManualDiscountMarkup.ChoiceList.Add(MaxDiscountPercentage, Format(MaxDiscountPercentage, "NFD=2"));
			EndIf;
			
		EndIf;
		
		Items.LabelMaximumManualDiscount.Visible  = UseRestrictionsOfManualDiscounts;
		Items.LabelMaximumManualDiscount.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%2 Tối đa chiết khấu: %1 %2';
				|ru = '%2 Макс. скидка: %1%2';
				|en = '%2 Max. discount: %1%2'; fa = '%2 Max. discount: %1%2';
				|it = '%2 Sconto massimo: %1%2';
				|pl = '%2 Maks. zniżka: %1%2';
				|tr = '%2 Maksimum indirim: %1%2'"),
			MaxDiscountPercentage,
			"%");
		
		Items.LabelMaximumManualMargin.Visible = UseRestrictionsOfManualDiscounts;
		Items.LabelMaximumManualMargin.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%2 Tối đa phụ thu: %1 %2';
				|ru = '%2 Макс. наценка: %1%2';
				|en = '%2 Max. markup: %1%2'; fa = '%2 Max. markup: %1%2';
				|it = '%2 Мargine massimo: %1%2';
				|pl = '%2 Maks. marża: %1%2';
				|tr = '%2 Maksimum zam: %1%2'"),
			MaxMarkupPercentage,
			"%");
		
		Items.CaptionMaximumDiscountIsNotLimited.Visible   = Not UseRestrictionsOfManualDiscounts;
		Items.CaptionTheMaximumMarginIsNotLimited.Visible  = Not UseRestrictionsOfManualDiscounts;
		
		// Set the options for choosing a manual discount (mark-up).
		Items.ProvisionOption.ChoiceList.Add("Discount", NStr("vi = 'Chiết khấu';
																|ru = 'Скидка';
																|en = 'Discount'; fa = 'تخفیف';
																|it = 'Sconto';
																|pl = 'Rabat';
																|tr = 'İndirim'"));
		Items.ProvisionOption.ChoiceList.Add("Markup", NStr("vi = 'Phụ thu';
															|ru = 'Наценка';
															|en = 'Markup'; fa = 'افزایش قیمت';
															|it = 'Sovrapprezzo';
															|pl = 'Marża';
															|tr = 'Marj'"));
		
		// Set the value of the grant option when opening.
		ProvisionOption = "Discount"; // Discount
		Items.ProvisionOptions.CurrentPage = Items.ProvisionOptions.ChildItems.Discount;
		
	EndIf;
	
	SetVisibilityNumberOfStorageUnits();

	UpdateCount();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PackageOnChange(Item)
	
	PackagingWhenModifiedOnServer(OldPackaging);
	OldPackaging = Package;
	
EndProcedure

&AtClient
Procedure PackageClearing(Item, StandardProcessing)
	
	PackagingWhenModifiedOnServer(OldPackaging);
	OldPackaging = Package;
	
EndProcedure

&AtClient
Procedure PriceChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("Number") Then
		
		PriceKindPresentation = NStr("vi = '<tùy ý>';
									|ru = '<произвольная>';
									|en = '<custom>'; fa = '<سفارشی>';
									|it = '<arbitraria>';
									|pl = '<dowolny>';
									|tr = '<isteğe bağlı>'");
		Return;
		
	EndIf;
	
	StandardProcessing = False;
	
	PriceKind = ValueSelected;
	PriceKindPresentation = ValueSelected;
		
	For Each String In PriceTypePrice Do
		If String.PriceKind = ValueSelected Then
			Price = String.Price;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure PriceTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	StandardProcessing = False;
	PriceKind = Undefined;
	PriceKindPresentation = NStr("vi = '<tùy ý>';
								|ru = '<произвольная>';
								|en = '<custom>'; fa = '<سفارشی>';
								|it = '<arbitraria>';
								|pl = '<dowolny>';
								|tr = '<isteğe bağlı>'");
	Price = Number(Text);
	
	ChoiceData = New ValueList;
	ChoiceData.Add( Price, Format(Price, "NFD=2; NZ=") + " (<custom>)" );
	
EndProcedure

&AtClient
Procedure ProvisionOptionOnChange(Item)
	
	Items.PercentRateOfManualDiscountMarkup.ChoiceListButton = False;
	Items.PercentRateOfManualDiscountMarkup.ChoiceList.Clear();
	
	If ProvisionOption = "Discount" Then
		Items.ProvisionOptions.CurrentPage = Items.ProvisionOptions.ChildItems.Discount;
		If MaxDiscountPercentage > 0 Then
			Items.PercentRateOfManualDiscountMarkup.ChoiceListButton = True;
			Items.PercentRateOfManualDiscountMarkup.ChoiceList.Add(MaxDiscountPercentage, Format(MaxDiscountPercentage, "NFD=2"));
		EndIf;
	Else
		Items.ProvisionOptions.CurrentPage = Items.ProvisionOptions.ChildItems.Markup;
		If MaxMarkupPercentage > 0 Then
			Items.PercentRateOfManualDiscountMarkup.ChoiceListButton = True;
			Items.PercentRateOfManualDiscountMarkup.ChoiceList.Add(MaxMarkupPercentage, Format(MaxMarkupPercentage, "NFD=2"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure NumberOfPackagesOnChange(Item)
	
	UpdateCount();
	
EndProcedure

&AtClient
Procedure CountOnChange(Item)
	
	UpdateNumberOfPackages();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Cancel = False;
	ClearMessages();
	
	If NumberOfPackages = 0 Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền số lượng';
												|ru = 'Не заполнено количество';
												|en = 'Quantity is not filled in'; fa = 'Quantity is not filled in';
												|it = 'Quantità non compilata';
												|pl = 'Nie wypełniono ilości';
												|tr = 'Miktar doldurulmadı'"),,"NumberOfPackages",,Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	SelectedGoods = New Array;
	
	ProductParameters_1 = New Structure;
	ProductParameters_1.Insert("Products", Products);        
	ProductParameters_1.Insert("Characteristic", Characteristic);
	ProductParameters_1.Insert("Package", Package);
	ProductParameters_1.Insert("Price", Price);
	ProductParameters_1.Insert("PriceKind", PriceKind);
	ProductParameters_1.Insert("NumberOfPackages", NumberOfPackages);
	ProductParameters_1.Insert("Warehouse", Warehouse);
	ProductParameters_1.Insert("DateOfShipment", DateOfShipment);
	
	If ProvisionOption = "Discount" Then
		ProductParameters_1.Insert("PercentRateOfManualDiscount", PercentRateOfManualDiscountMarkup);
	Else
		ProductParameters_1.Insert("PercentRateOfManualDiscount", -PercentRateOfManualDiscountMarkup);
	EndIf;
	
	SelectedGoods.Add(ProductParameters_1);
	
	Result = New Structure("SelectedGoods, MaximumShipmentDate", SelectedGoods, DateOfShipment);

	Close(Result);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure RoundOff(Command)
	
	Count = Round(Count, 0, RoundMode.Round15as20);
	UpdateNumberOfPackages();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentRateOfManualDiscountMarkup.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PercentRateOfManualDiscountMarkup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxDiscountPercentage");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseRestrictionsOfManualDiscounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProvisionOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "Discount";

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentRateOfManualDiscountMarkup.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PercentRateOfManualDiscountMarkup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxMarkupPercentage");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseRestrictionsOfManualDiscounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProvisionOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "Markup";
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsUnitOfMeasure.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Count.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FractionalQuantityInBasicUnitsIsSpecified");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

EndProcedure

&AtServer
Procedure PackagingWhenModifiedOnServer(OldPackaging)
	
	SetVisibilityNumberOfStorageUnits();
	UpdateCount();
	
	FillInListOfPrices();
	If Not ValueIsFilled(PriceKind) 
		Or Not EditPriceType Then
		Price = Price * 
			Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products) /
			Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(OldPackaging, Products);
	EndIf;
		
EndProcedure

&AtServer
Procedure FillInListOfPrices()
	
	If (UsePriceManagementSystem25) Then
		FillInListOfPrices2_5();
		Return;
	EndIf;
	
	If EditPriceType Then
		// Fill in the list of price types selection.
		Query = New Query(
		"SELECT ALLOWED
		|	TypesOfPrices.Ref AS PriceKind
		|INTO TypesOfPrices
		|FROM
		|	Catalog.TypesOfPrices AS TypesOfPrices
		|WHERE
		|	NOT TypesOfPrices.DeletionMark
		|	AND TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)
		|	AND &UseWhileSellingToCustomers
		|	AND &PriceIncludesVAT
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	CrossSectionCourses.Currency AS Currency,
		|	CrossSectionCourses.CourseNumerator,
		|	CrossSectionCourses.CourseDenominator
		|INTO CrossSectionCourses
		|FROM
		|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CrossSectionCourses
		|
		|INDEX BY
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	RatesCutCurrencyPrices.Currency AS Currency,
		|	RatesCutCurrencyPrices.CourseNumerator,
		|	RatesCutCurrencyPrices.CourseDenominator
		|INTO RatesCutCurrencyPrices
		|FROM
		|	InformationRegister.RelativeExchangeRates.SliceLast(&Date,
		|				Currency = &Currency AND BaseCurrency = &BaseCurrency) AS RatesCutCurrencyPrices
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ItemPricesCrossSectionOfTheLatest.PriceKind AS PriceKind,
		|	ItemPricesCrossSectionOfTheLatest.Currency AS Currency,
		|	ItemPricesCrossSectionOfTheLatest.Price AS Price,
		|	ISNULL(&QueryTextPackagingFactor1, 1) / ISNULL(&QueryTextPackagingFactor2, 1) AS ZoomRatio
		|INTO ItemPricesCrossSectionOfTheLatest
		|FROM
		|	InformationRegister.ItemsPrices.SliceLast(
		|			ENDOFPERIOD(&Date, DAY),
		|			Products = &Products
		|				AND Characteristic = &Characteristic
		|				AND PriceKind IN
		|					(SELECT
		|						TypesOfPrices.PriceKind
		|					FROM
		|						TypesOfPrices AS TypesOfPrices)) AS ItemPricesCrossSectionOfTheLatest
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ItemPricesCrossSectionOfTheLatest.PriceKind AS PriceKind,
		|	CAST(ItemPricesCrossSectionOfTheLatest.Price * CrossSectionCourses.CourseNumerator / CrossSectionCourses.CourseDenominator / RatesCutCurrencyPrices.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator * ItemPricesCrossSectionOfTheLatest.ZoomRatio AS NUMBER(31,2)) AS Price
		|FROM
		|	ItemPricesCrossSectionOfTheLatest AS ItemPricesCrossSectionOfTheLatest
		|		LEFT JOIN CrossSectionCourses AS CrossSectionCourses
		|		ON (CrossSectionCourses.Currency = ItemPricesCrossSectionOfTheLatest.Currency)
		|		LEFT JOIN RatesCutCurrencyPrices AS RatesCutCurrencyPrices
		|		ON (TRUE)");
		Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure)", "ItemPricesCrossSectionOfTheLatest.Products"));
		Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
		
		ReplacementText = "TypesOfPrices.PriceIncludesVAT = &PriceIncludesVAT";
		If WithoutFilterByVATInclusionInPrice Then
			ReplacementText = "TRUE";
		Else
			Query.SetParameter("PriceIncludesVAT", PriceIncludesVAT);
		EndIf;
		Query.Text = StrReplace(Query.Text, "&PriceIncludesVAT", ReplacementText);

		ReplacementText = "TypesOfPrices.UseWhileSellingToCustomers";
		If WithoutFilterByUseWhileSellingToCustomersInPrice Then
			ReplacementText = "TRUE";
		EndIf;
		Query.Text = StrReplace(Query.Text, "&UseWhileSellingToCustomers", ReplacementText);
		
		Query.SetParameter("Date",           Date);
		Query.SetParameter("Products",   Products);
		Query.SetParameter("Characteristic", Characteristic);
		Query.SetParameter("Package",       Package);
		Query.SetParameter("Currency",         Currency);
		Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
		
		PriceSelectionList = Items.Price.ChoiceList;
		PriceSelectionList.Clear();
		PriceTypePrice.Load(Query.Execute().Unload());
		
		TypeOfPriceCoincided = False;
		For Each String In PriceTypePrice Do
			Presentation = Format(String.Price, "NFD=2; NZ=") + " (" + String.PriceKind + ")";
			PriceSelectionList.Add(String.PriceKind,Presentation);
			If String.PriceKind = PriceKind Then
				Price = String.Price;
				TypeOfPriceCoincided = True;
			EndIf;
		EndDo;
		
		If Not TypeOfPriceCoincided Then
			PriceKind = Catalogs.TypesOfPrices.EmptyRef();
			PriceKindPresentation  = NStr("vi = '<tùy ý>';
											|ru = '<произвольная>';
											|en = '<custom>'; fa = '<سفارشی>';
											|it = '<arbitraria>';
											|pl = '<dowolny>';
											|tr = '<isteğe bağlı>'");
		EndIf;
			
	EndIf;
EndProcedure

&AtServer
Procedure FillInListOfPrices2_5()
	
	If EditPriceType Then
		// Fill in the list of price types selection.
		Query = New Query(
		"SELECT
		|	CAST(&Products AS Catalog.Products) AS Products,
		|	CAST(&Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
		|	CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package
		|INTO GoodsTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	CASE
		|		WHEN
		|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|		ELSE GoodsTable.Characteristic.ItemsCharacteristicForPricing
		|	END AS PricingVariant,
		|	VALUE(Catalog.ItemsBatchesForPricing.EmptyRef) AS PricingBatch,
		|	CASE
		|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		ELSE GoodsTable.Package
		|	END AS PricingPackage
		|INTO FilterTable
		|FROM
		|	GoodsTable AS GoodsTable
		|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|		ON ItemKinds.Ref = GoodsTable.Products.ProductKind
		|
		|INDEX BY
		|	Products,
		|	PricingVariant,
		|	PricingBatch,
		|	PricingPackage
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	TypesOfPrices.Ref AS PriceKind
		|INTO TypesOfPrices
		|FROM
		|	Catalog.TypesOfPrices AS TypesOfPrices
		|WHERE
		|	NOT TypesOfPrices.DeletionMark
		|	AND TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)
		|	AND &UseWhileSellingToCustomers
		|	AND &PriceIncludesVAT
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	CrossSectionCourses.Currency AS Currency,
		|	CrossSectionCourses.CourseNumerator,
		|	CrossSectionCourses.CourseDenominator
		|INTO CrossSectionCourses
		|FROM
		|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CrossSectionCourses
		|
		|INDEX BY
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	RatesCutCurrencyPrices.Currency AS Currency,
		|	RatesCutCurrencyPrices.CourseNumerator,
		|	RatesCutCurrencyPrices.CourseDenominator
		|INTO RatesCutCurrencyPrices
		|FROM
		|	InformationRegister.RelativeExchangeRates.SliceLast(&Date,
		|			Currency = &Currency AND BaseCurrency = &BaseCurrency) AS RatesCutCurrencyPrices
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ItemPricesCrossSectionOfTheLatest.PriceKind AS PriceKind,
		|	ItemPricesCrossSectionOfTheLatest.Currency AS Currency,
		|	ItemPricesCrossSectionOfTheLatest.Price AS Price,
		|	ISNULL(&QueryTextPackagingFactor1, 1) / ISNULL(&QueryTextPackagingFactor2, 1) AS ZoomRatio
		|INTO ItemPricesCrossSectionOfTheLatest
		|FROM
		|	InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&Date, DAY), (Products, PricingVariant,
		|		PricingBatch, PricingPackage) IN
		|		(SELECT
		|			T.Products,
		|			T.PricingVariant,
		|			T.PricingBatch,
		|			T.PricingPackage
		|		FROM
		|			FilterTable AS T)
		|	AND PriceKind IN
		|		(SELECT
		|			TypesOfPrices.PriceKind
		|		FROM
		|			TypesOfPrices AS TypesOfPrices)) AS ItemPricesCrossSectionOfTheLatest
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ItemPricesCrossSectionOfTheLatest.PriceKind AS PriceKind,
		|	CAST(ItemPricesCrossSectionOfTheLatest.Price * CrossSectionCourses.CourseNumerator / CrossSectionCourses.CourseDenominator /
		|		RatesCutCurrencyPrices.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator *
		|		ItemPricesCrossSectionOfTheLatest.ZoomRatio AS NUMBER(31, 2)) AS Price
		|FROM
		|	ItemPricesCrossSectionOfTheLatest AS ItemPricesCrossSectionOfTheLatest
		|		LEFT JOIN CrossSectionCourses AS CrossSectionCourses
		|		ON CrossSectionCourses.Currency = ItemPricesCrossSectionOfTheLatest.Currency
		|		LEFT JOIN RatesCutCurrencyPrices AS RatesCutCurrencyPrices
		|		ON TRUE");
		Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure)", "ItemPricesCrossSectionOfTheLatest.Products"));
		Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
		
		ReplacementText = "TypesOfPrices.PriceIncludesVAT = &PriceIncludesVAT";
		If WithoutFilterByVATInclusionInPrice Then
			ReplacementText = "TRUE";
		Else
			Query.SetParameter("PriceIncludesVAT", PriceIncludesVAT);
		EndIf;
		Query.Text = StrReplace(Query.Text, "&PriceIncludesVAT", ReplacementText);
		
		ReplacementText = "TypesOfPrices.UseWhileSellingToCustomers";
		If WithoutFilterByUseWhileSellingToCustomersInPrice Then
			ReplacementText = "TRUE";
		EndIf;
		Query.Text = StrReplace(Query.Text, "&UseWhileSellingToCustomers", ReplacementText);
		
		Query.SetParameter("Date",           Date);
		Query.SetParameter("Products",   Products);
		Query.SetParameter("Characteristic", Characteristic);
		Query.SetParameter("Package",       Package);
		Query.SetParameter("Currency",         Currency);
		Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
		
		PriceSelectionList = Items.Price.ChoiceList;
		PriceSelectionList.Clear();
		PriceTypePrice.Load(Query.Execute().Unload());
		
		TypeOfPriceCoincided = False;
		For Each String In PriceTypePrice Do
			Presentation = Format(String.Price, "NFD=2; NZ=") + " (" + String.PriceKind + ")";
			PriceSelectionList.Add(String.PriceKind,Presentation);
			If String.PriceKind = PriceKind Then
				Price = String.Price;
				TypeOfPriceCoincided = True;
			EndIf;
		EndDo;
		
		If Not TypeOfPriceCoincided Then
			PriceKind = Catalogs.TypesOfPrices.EmptyRef();
			PriceKindPresentation  = NStr("vi = '<tùy ý>';
											|ru = '<произвольная>';
											|en = '<arbitrary>'; fa = '<arbitrary>';
											|it = '<arbitraria>';
											|pl = '<dowolny>';
											|tr = '<isteğe bağlı>'");
		EndIf;
			
	EndIf;
EndProcedure

&AtServer
Procedure UpdateCount()
	
	Count = NumberOfPackages*Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products);
	SetVisibilityToRound();
	
EndProcedure

&AtServer
Procedure UpdateNumberOfPackages()
	
	NumberOfPackages = Count/Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products);
	SetVisibilityToRound();
	
EndProcedure

&AtServer
Procedure SetVisibilityNumberOfStorageUnits()
	
	UnitOfMeasurementTypeOfMeasuredValue = "";
	PackagingTypeOfMeasuredValue = "";
	
	UnitMeasuring = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Common.ObjectAttributeValue(Products, "UnitOfMeasure"),
																			UnitOfMeasurementTypeOfMeasuredValue);
																			
	PackagingMeasured = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Package,
																			PackagingTypeOfMeasuredValue);
	If UnitMeasuring
		And PackagingTypeOfMeasuredValue <> UnitOfMeasurementTypeOfMeasuredValue
		And PackagingTypeOfMeasuredValue <> "Package"
		And PackagingTypeOfMeasuredValue <> ""
		Or UnitOfMeasurementTypeOfMeasuredValue = "NumberOfPieces" 
		And PackagingMeasured Then 
		
		Items.Count.Visible = True;
		Items.ProductsUnitOfMeasure.Visible = True;
		Items.DecorationQuantityRoundUp.Visible = False;
		
	Else
		
		Items.Count.Visible = False;
		Items.ProductsUnitOfMeasure.Visible = False;
		Items.DecorationQuantityRoundUp.Visible = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityToRound()
	
	If Count <> Int(Count) And Items.Count.Visible And Not UnitMeasuring Then
		FractionalQuantityInBasicUnitsIsSpecified = True;
		Items.RoundOff.Visible = True;
	Else
		FractionalQuantityInBasicUnitsIsSpecified = False;
		Items.RoundOff.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
