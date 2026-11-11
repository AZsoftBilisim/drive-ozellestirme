
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Price              = Parameters.Price;
	Date              = Parameters.Date;
	Package          = Parameters.Package;
	Warehouse             = Parameters.Warehouse;
	Currency            = Parameters.Currency;
	Terms        = Parameters.Terms;
	PriceIncludesVAT   = Parameters.PriceIncludesVAT;
	Partner           = Parameters.Partner;
	Products      = Parameters.Products;
	Characteristic    = Parameters.Characteristic;
	VendorPriceKind = Parameters.VendorPriceKind;
	
	TMCommonUseClientServer.AddSelectionParameter(Items.Warehouse, "Ref", Parameters.Warehouses);
	Items.Warehouse.Visible = (Parameters.Warehouses.Count() > 1) And Parameters.UseWarehousesInTheTablePart;
	
	ProductStructure_ = Common.ObjectAttributesValues(Products, "UnitOfMeasure, UsePackages, PackagingGroup");
	
	OldPackaging = Package;
	NumberOfPackages = 1;
	
	Items.Price.ReadOnly = Not Parameters.EditThePrice;
	
	ProductName = "" + Parameters.Products + ?(ValueIsFilled(Parameters.Characteristic), " (" + Parameters.Characteristic + ")","");
	
	If Parameters.HidePrice Then
		Items.Price.Visible              = False;
		Items.Currency.Visible            = False;
		ThisForm.AutoTitle               = False;
		ThisForm.Title                   = NStr("vi = 'Nhập số lượng';
												|ru = 'Ввод количества';
												|en = 'Enter quantity'; fa = 'ورود مقدار';
												|it = 'Inserimento quantità';
												|pl = 'Wprowadzanie ilości';
												|tr = 'Miktar girin'");
		Items.VendorPriceKind.Visible = False;
	EndIf;
	
	Items.Package.Visible              = ValueIsFilled(ProductStructure_.PackagingGroup);
	Items.UnitOfMeasure.Visible      = Not ValueIsFilled(ProductStructure_.PackagingGroup);
	Items.Package.InputHint         = ProductStructure_.UnitOfMeasure;
	
	If ProductStructure_.UsePackages Then
		Items.Package.InputHint = ProductStructure_.UnitOfMeasure;
	EndIf;

	If Parameters.IsService Then
		Warehouse                    = PredefinedValue("Catalog.Warehouses.EmptyRef");
		Items.Warehouse.Visible = False;
	EndIf;
	
	NumberOfPackages = 1;
	Items.NumberOfPackages.Enabled = True;
	
	Package = OldPackaging;
	
	// Adjust visibility and set the values of the details for editing manual discounts, margins.
	DocumentAmount = NumberOfPackages * Price;
	
	If Not Parameters.UseDiscountAdjustmentsInPurchases Or Parameters.HideManualDiscounts Then
		
		Items.GroupParametersDiscountsMarkups.Visible = False;
		
	Else
		
		// Set the properties of the elements related to discounts (margins).
		UseRestrictionsOfManualDiscounts = True;
		
		If UseRestrictionsOfManualDiscounts Then
			
			TableStructure = GetFromTempStorage(Parameters.AddressInTempStorage);
				
			MaxDiscountPercentage  = TableStructure.Restrictions[0].MaximumPercentageForManualDiscount;
			MaxMarkupPercentage = TableStructure.Restrictions[0].MaximumPercentageForManualMarkup;
			
			If MaxDiscountPercentage > 0 Then
				Items.DiscountPercentage.ChoiceListButton = True;
				Items.DiscountPercentage.ChoiceList.Add(MaxDiscountPercentage, Format(MaxDiscountPercentage, "NFD=2"));
			EndIf;
			
			If MaxMarkupPercentage > 0 Then
				Items.MarginPercentage.ChoiceListButton = True;
				Items.MarginPercentage.ChoiceList.Add(MaxMarkupPercentage, Format(MaxMarkupPercentage, "NFD=2"));
			EndIf;
			
		EndIf;
		
		Items.LabelMaximumManualDiscount.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chiết khấu tối đa: %1%2';
				|ru = 'Макс. скидка: %1%2';
				|en = 'Max. discount: %1%2'; fa = 'Max. discount: %1%2';
				|it = 'Sconto massimo: %1%2';
				|pl = 'Maks. zniżka: %1%2';
				|tr = 'Maksimum indirim: %1%2'"),
			MaxDiscountPercentage,
			"%");
		
		Items.LabelMaximumManualMargin.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phụ thu tối đa: %1%2';
				|ru = 'Макс. наценка: %1%2';
				|en = 'Max markup: %1%2'; fa = 'Max markup: %1%2';
				|it = 'Мargine massimo: %1%2';
				|pl = 'Maks. marża: %1%2';
				|tr = 'Maksimum zam: %1%2'"),
			MaxMarkupPercentage,
			"%");
		
		// Set the options for choosing a manual discount (mark-up).
		Items.ProvisionOption.ChoiceList.Add(1, NStr("vi = 'Chiết khấu';
													|ru = 'Скидка';
													|en = 'Discount'; fa = 'تخفیف';
													|it = 'Sconto';
													|pl = 'Rabat';
													|tr = 'İndirim'"));
		Items.ProvisionOption.ChoiceList.Add(2, NStr("vi = 'Phụ thu';
													|ru = 'Наценка';
													|en = 'Markup'; fa = 'افزایش قیمت';
													|it = 'Sovrapprezzo';
													|pl = 'Marża';
													|tr = 'Marj'"));
		
		// Set the value of the grant option when opening.
		ProvisionOption = 1; // Discount
		
		SetVisibilityOfDiscountsMarkups();
		
	EndIf;
	
	SupplierPriceViewWhenChangedOnServer();
	
	SetVisibilityNumberOfStorageUnits();

	UpdateCount();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PackageOnChange(Item)
	
	PackagingWhenModifiedOnServer(OldPackaging);
	OldPackaging = Package;
	
EndProcedure

&AtClient
Procedure VendorPriceKindOnChange(Item)
	
	SupplierPriceViewWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PackageClearing(Item, StandardProcessing)
	
	PackagingWhenModifiedOnServer(OldPackaging);
	OldPackaging = Package;
	
EndProcedure

&AtClient
Procedure ProvisionOptionOnChange(Item)
	
	SetVisibilityOfDiscountsMarkups();
	
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
	
	StructuresArray = New Array;
	
	NewRow = New Structure;
	NewRow.Insert("Products",          Products);
	NewRow.Insert("Characteristic",        Characteristic);
	NewRow.Insert("VendorPriceKind",     VendorPriceKind);
	NewRow.Insert("Price",                  Price);
	
	NewRow.Insert("Package",              Package);
	NewRow.Insert("NumberOfPackages",    NumberOfPackages);
	NewRow.Insert("Warehouse",                 Warehouse);
	
	If ProvisionOption = 1 Then
		NewRow.Insert("PercentRateOfManualDiscount", PercentRateOfManualDiscountMarkup);
	Else
		NewRow.Insert("PercentRateOfManualDiscount", -PercentRateOfManualDiscountMarkup);
	EndIf;
	
	StructuresArray.Add(NewRow);
	
	Close(StructuresArray);
	
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
	ItemField.Field = New DataCompositionField(Items.DiscountPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseRestrictionsOfManualDiscounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PercentRateOfManualDiscountMarkup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxDiscountPercentage");

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MarginPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseRestrictionsOfManualDiscounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PercentRateOfManualDiscountMarkup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxMarkupPercentage");

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
	
	Price = Price * 
		Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products) /
		Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(OldPackaging, Products);
	
EndProcedure

&AtServer
Procedure SupplierPriceViewWhenChangedOnServer()
	
	ThereIsRightToReadPrices = AccessRight(
		"Read",
		Metadata.InformationRegisters.ItemsPricesOfVendor,
		Users.CurrentUser());
	
	If Not ThereIsRightToReadPrices Then
		Return;
	EndIf;
	
	Price = 0;
	
	Query = New Query();
	Query.SetParameter("VendorPriceKind", VendorPriceKind);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Package", Package);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	Query.Text =
	"SELECT ALLOWED
	|	CAST(
	|		ItemPricesCrossSectionOfTheLatest.Price * CrossSectionCourses.CourseNumerator / CrossSectionCourses.CourseDenominator / RatesCutCurrencyPrices.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator
	|		* ISNULL(&QueryTextPackagingFactor1, 1) / ISNULL(&QueryTextPackagingFactor2, 1) AS NUMBER(31,2)) AS Price
	|FROM
	|	InformationRegister.ItemsPricesOfVendor.SliceLast(
	|			ENDOFPERIOD(&Date, DAY),
	|			Products = &Products
	|				AND Characteristic = &Characteristic
	|				AND VendorPriceKind = &VendorPriceKind) AS ItemPricesCrossSectionOfTheLatest
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CrossSectionCourses
	|		ON (CrossSectionCourses.Currency = ItemPricesCrossSectionOfTheLatest.Currency)
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS RatesCutCurrencyPrices
	|		ON (TRUE)";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure)",
			"ItemPricesCrossSectionOfTheLatest.Products"));
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
	
	Selection = Query.Execute().Select();
	If Selection.Next()
		And ValueIsFilled(Selection.Price) Then
		
		Price = Selection.Price;
		
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

&AtServer
Procedure SetVisibilityOfDiscountsMarkups()
	
	Items.DiscountPercentage.Visible  = ProvisionOption = 1;
	Items.MarginPercentage.Visible = ProvisionOption = 2;
	
	Items.LabelMaximumManualDiscount.Visible = UseRestrictionsOfManualDiscounts
																And ProvisionOption = 1;
	Items.CaptionMaximumDiscountIsNotLimited.Visible = Not UseRestrictionsOfManualDiscounts
																And ProvisionOption = 1;
	Items.LabelMaximumManualMargin.Visible = UseRestrictionsOfManualDiscounts
																And ProvisionOption = 2;
	Items.CaptionTheMaximumMarginIsNotLimited.Visible = Not UseRestrictionsOfManualDiscounts
																And ProvisionOption = 2;
	
EndProcedure

#EndRegion
