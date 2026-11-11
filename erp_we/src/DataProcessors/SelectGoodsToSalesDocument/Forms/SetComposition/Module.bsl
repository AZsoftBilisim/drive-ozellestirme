#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CurrentSessionDate = CurrentSessionDate();
	
	PriceKind                   = Parameters.PriceKind;
	Terms                = Parameters.Terms;
	Price                      = Parameters.Price;
	Date                      = Parameters.Date;
	DateOfShipment              = Parameters.DateOfShipment;
	Warehouse                     = Parameters.Warehouse;
	Products              = Parameters.Products;
	Characteristic            = Parameters.Characteristic;
	Currency                    = Parameters.Currency;
	PriceIncludesVAT           = Parameters.PriceIncludesVAT;
	ItemsType           = Parameters.ItemsType;
	ShowBalance         = Parameters.ShowBalance;
	ControlledLotReference      = Parameters.ControlledLotReference;
	UsePriceManagementSystem25 = Parameters.UsePriceManagementSystem25;
	HidePrice = Parameters.HidePrice;
	
	Warehouses.LoadValues(Parameters.Warehouses);
	TypesOfPrices.LoadValues(Parameters.TypesOfPrices);
	
	Items.PriceKind.ReadOnly     = Not Parameters.EditPriceType;
	Items.PriceKind.SkipOnInput = Not Parameters.EditPriceType;
	Items.Price.ReadOnly        = Not Parameters.EditThePrice;
	Items.Price.SkipOnInput    = Not Parameters.EditThePrice;
	
	ProductName = ProductsClientServer.ProductPresentation(Parameters.Products, Parameters.Characteristic);
	TitleText     = NStr("vi = 'Thành phần tập hợp ""%ProductName%""';
						|ru = 'Состав набора ""%ProductName%""';
						|en = 'Set content ""%ProductName%""'; fa = 'Set content ""%ProductName%""';
						|it = 'Соmposizione del set ""%ProductName%""';
						|pl = 'Skład zestawu ""%ProductName%""';
						|tr = 'Set kapsamı ""%ProductName%""'");
	TitleText     = StrReplace(TitleText, "%ProductName%", ProductName); 
	
	Title = TitleText;
	
	If HidePrice Then
		Items.Price.Visible    = False;
		Items.Currency.Visible  = False;
		Items.PriceKind.Visible = False;
		ThisForm.AutoTitle     = False;
	EndIf;
	
	If Not Parameters.UseShipmentDates Then
		Items.DateOfShipment.Visible = False;
	EndIf;
	
	If Parameters.IsService Then
		DateOfShipment = '00010101';
		Warehouse = Catalogs.Warehouses.EmptyRef();
		Items.DateOfShipment.Visible = False;
	EndIf;
	
	If Not Parameters.UseWarehousesInTheTablePart Then
		Warehouse = Undefined;
	EndIf;
	
	Items.Warehouse.Visible = (Not Parameters.IsService Or Not Parameters.UseShipmentDates) 
		And Parameters.Warehouses.Count() > 1 And Parameters.UseWarehousesInTheTablePart;
	TMCommonUseClientServer.AddSelectionParameter(Items.Warehouse, "Ref", Parameters.Warehouses);
	
	NumberOfPackages = 1;
	
	// Fill in the list of price types selection.
	Query = New Query(
	"SELECT ALLOWED
	|	TypesOfPrices.Ref AS PricesKind
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	NOT TypesOfPrices.DeletionMark
	|	AND TypesOfPrices.UseWhileSellingToCustomers
	|	AND TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)
	|	AND TypesOfPrices.PriceIncludesVAT = &PriceIncludesVAT");
	
	Query.SetParameter("PriceIncludesVAT", PriceIncludesVAT);
	
	Items.PriceKind.ChoiceList.Clear();
	Items.PriceKind.ChoiceList.LoadValues(Query.Execute().Unload().UnloadColumn("PricesKind"));
	Items.PriceKind.ChoiceList.Add(Catalogs.TypesOfPrices.EmptyRef(), NStr("vi = '<tùy ý>';
																			|ru = '<произвольная>';
																			|en = '<custom>'; fa = '<سفارشی>';
																			|it = '<arbitraria>';
																			|pl = '<custom>';
																			|tr = '<isteğe bağlı>'"));
	
	Items.Price.ReadOnly = ValueIsFilled(PriceKind);
	Items.Price.SkipOnInput = ValueIsFilled(PriceKind);

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
				Items.DiscountPercentage.ChoiceListButton = True;
				Items.DiscountPercentage.ChoiceList.Add(MaxDiscountPercentage, Format(MaxDiscountPercentage, "NFD=2"));
			EndIf;
			
			If MaxMarkupPercentage > 0 Then
				Items.MarginPercentage.ChoiceListButton = True;
				Items.MarginPercentage.ChoiceList.Add(MaxMarkupPercentage, Format(MaxMarkupPercentage, "NFD=2"));
			EndIf;
			
		EndIf;
		
		Items.LabelMaximumManualDiscount.Visible  = UseRestrictionsOfManualDiscounts;
		Items.LabelMaximumManualDiscount.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chiết khấu tối đa: %1%2';
				|ru = 'Макс. скидка: %1%2';
				|en = 'Max. discount: %1%2'; fa = 'Max. discount: %1%2';
				|it = 'Sconto massimo: %1%2';
				|pl = 'Maks. zniżka: %1%2';
				|tr = 'Maksimum indirim: %1%2'"),
			MaxDiscountPercentage,
			"%");
		
		Items.LabelMaximumManualMargin.Visible = UseRestrictionsOfManualDiscounts;
		Items.LabelMaximumManualMargin.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phụ thu tối đa: %1%2';
				|ru = 'Макс. наценка: %1%2';
				|en = 'Max markup: %1%2'; fa = 'Max markup: %1%2';
				|it = 'Мargine massimo: %1%2';
				|pl = 'Maks. marża: %1%2';
				|tr = 'Maksimum zam: %1%2'"),
			MaxMarkupPercentage,
			"%");
		
		Items.CaptionMaximumDiscountIsNotLimited.Visible   = Not UseRestrictionsOfManualDiscounts;
		Items.CaptionTheMaximumMarginIsNotLimited.Visible  = Not UseRestrictionsOfManualDiscounts;
		
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
		Items.ProvisionOptions.CurrentPage = Items.ProvisionOptions.ChildItems.Discount;
		
	EndIf;
	
	PriceHeaderText = NStr("vi = 'Đơn giá';
							|ru = 'Цена';
							|en = 'Price'; fa = 'قیمت';
							|it = 'Prezzo';
							|pl = 'Cena';
							|tr = 'Fiyat'");
	
	If ValueIsFilled(Currency) Then
		PriceHeaderText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đơn giá (%1)';
																						|ru = 'Цена (%1)';
																						|en = 'Price (%1)'; fa = 'Price (%1)';
																						|it = 'Prezzo (%1)';
																						|pl = 'Cena (%1)';
																						|tr = 'Fiyat (%1)'"), Currency);
	EndIf;
	
	Items.SetCompositionPrice.Title = PriceHeaderText;
	
	CalculateSetParameters();
	
	FormCode = "Processing_SelectionOfGoodsInSalesDocument_Form";
	
	Items.StockBalance.Visible = ShowBalance;
	SelectGoodsClientServer.SetCaptionTextToDisplayLeftovers(ThisForm);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PriceKindOnChange(Item)
	
	PriceViewWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PriceOnChange(Item)
	
	PriceKind = Undefined;
	
	CalculateSetParameters();
	
EndProcedure

&AtClient
Procedure ProvisionOptionOnChange(Item)
	
	If ProvisionOption = 1 Then
		Items.ProvisionOptions.CurrentPage = Items.ProvisionOptions.ChildItems.Discount;
	Else
		Items.ProvisionOptions.CurrentPage = Items.ProvisionOptions.ChildItems.Markup;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddSet(Command)
	
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
	
	
	If ProvisionOption = 1 Then
		PercentRateOfManualDiscount = PercentRateOfManualDiscountMarkup;
	Else
		PercentRateOfManualDiscount = -PercentRateOfManualDiscountMarkup;
	EndIf;
	
	If ItemsType = PredefinedValue("Enum.ItemsTypes.Set") Then
		
		SelectedGoods = SelectedGoods();
		
	Else
		
		SelectedGoods = New Array;
		
		ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
		ProductParameters_1.Products        = Products;
		ProductParameters_1.Characteristic      = Characteristic;
		ProductParameters_1.Price                = Price;
		ProductParameters_1.PriceKind             = PriceKind;
		ProductParameters_1.NumberOfPackages  = NumberOfPackages;
		ProductParameters_1.Warehouse               = Warehouse;
		ProductParameters_1.DateOfShipment        = DateOfShipment;
		
		ProductParameters_1.PercentRateOfManualDiscount = PercentRateOfManualDiscount;
		
		SelectedGoods.Add(ProductParameters_1);
		
	EndIf;
	
	Result = New Structure("SelectedGoods, MaximumShipmentDate", SelectedGoods, DateOfShipment);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
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
	ItemFilter.LeftValue = New DataCompositionField("PercentRateOfManualDiscountMarkup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxDiscountPercentage");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseRestrictionsOfManualDiscounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MarginPercentage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PercentRateOfManualDiscountMarkup");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaxMarkupPercentage");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseRestrictionsOfManualDiscounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);

EndProcedure

&AtServer
Procedure PriceViewWhenChangedOnServer()
	
	Items.Price.ReadOnly = ValueIsFilled(PriceKind);
	Items.Price.SkipOnInput = ValueIsFilled(PriceKind);

	If Not ValueIsFilled(PriceKind) Then
		Return;
	EndIf;

	If UsePriceManagementSystem25 Then
		
		QueryText = 
		"SELECT ALLOWED
		|	CAST(ItemPricesCrossSectionOfTheLatest.Price * CrossSectionCourses.CourseNumerator / CrossSectionCourses.CourseDenominator /
		|				RatesCutCurrencyPrices.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator
		|	* ISNULL(&QueryTextPackagingFactor1, 1) / ISNULL(&QueryTextPackagingFactor2, 1) AS NUMBER(31, 2)) AS Price
		|FROM
		|	InformationRegister.ItemsPrices25.SliceLast(
		|			ENDOFPERIOD(&Date, DAY),
		|			Products = &Products
		|				AND CASE
		|						WHEN Products.ProductKind.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|							THEN TRUE
		|						ELSE PricingVariant = CAST(&Characteristic AS Catalog.ItemsCharacteristics).ItemsCharacteristicForPricing
		|					END
		|				AND PriceKind = &PriceKind) AS ItemPricesCrossSectionOfTheLatest
		|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CrossSectionCourses
		|		ON (CrossSectionCourses.Currency = ItemPricesCrossSectionOfTheLatest.Currency)
		|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date,
		|				Currency = &Currency AND BaseCurrency = &BaseCurrency) AS RatesCutCurrencyPrices
		|		ON (TRUE)";

	Else	
	
		QueryText = 
		"SELECT ALLOWED
		|	CAST(ItemPricesCrossSectionOfTheLatest.Price * CrossSectionCourses.CourseNumerator / CrossSectionCourses.CourseDenominator /
		|				RatesCutCurrencyPrices.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator
		|	* ISNULL(&QueryTextPackagingFactor1, 1) / ISNULL(&QueryTextPackagingFactor2, 1) AS NUMBER(31, 2)) AS Price
		|FROM
		|	InformationRegister.ItemsPrices.SliceLast(
		|			ENDOFPERIOD(&Date, DAY),
		|			Products = &Products
		|				AND Characteristic = &Characteristic
		|				AND PriceKind = &PriceKind) AS ItemPricesCrossSectionOfTheLatest
		|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CrossSectionCourses
		|		ON (CrossSectionCourses.Currency = ItemPricesCrossSectionOfTheLatest.Currency)
		|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date,
		|				Currency = &Currency AND BaseCurrency = &BaseCurrency) AS RatesCutCurrencyPrices
		|		ON (TRUE)";
		
	EndIf;	
	
	Query = New Query(QueryText);
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure)", Undefined));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
	Query.SetParameter("PriceKind",        PriceKind);
	Query.SetParameter("Date",           Date);
	Query.SetParameter("Products",   Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Package",       Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	Query.SetParameter("Currency",         Currency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	Price = 0;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		If ValueIsFilled(Selection.Price) Then
			Price = Selection.Price;
		EndIf;
	EndIf;
	
	If ItemsType = Enums.ItemsTypes.Set Then
		CalculateSetParameters();
	EndIf;
	
EndProcedure

&AtServer
Function SelectedGoods()
	
	If ProvisionOption = 1 Then
		PercentRateOfManualDiscount = PercentRateOfManualDiscountMarkup;
	Else
		PercentRateOfManualDiscount = -PercentRateOfManualDiscountMarkup;
	EndIf;
	
	ComponentParameters = New Structure;
	ComponentParameters.Insert("ProductsInSet",              Products);
	ComponentParameters.Insert("ItemVariantOfSet",            Characteristic);
	ComponentParameters.Insert("ItemKitConfiguration", ItemKitConfiguration);
	ComponentParameters.Insert("PriceKind", PriceKind);
	ComponentParameters.Insert("Currency", Currency);
	If Warehouses.Count() = 1 Then
		ComponentParameters.Insert("Warehouse", Warehouses.Get(0).Value);
	EndIf;
	ComponentParameters.Insert("NumberOfPackages", NumberOfPackages);
	ComponentParameters.Insert("DateOfShipment", DateOfShipment);
	ComponentParameters.Insert("PercentRateOfManualDiscount", PercentRateOfManualDiscount);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Date",    Date);
	AdditionalParameters.Insert("Currency",  Currency);
	AdditionalParameters.Insert("Price",    Price);
	AdditionalParameters.Insert("PriceKind", PriceKind);
	If ValueIsFilled(Terms) Then
		AdditionalParameters.Insert("Terms", Terms);
	EndIf;
	AdditionalParameters.Insert("Warehouses", Warehouses);
	
	SelectedGoods = SetsServerCall.Components(ComponentParameters, AdditionalParameters);
	
	Return SelectedGoods;
	
EndFunction

&AtServer
Procedure CalculateSetParameters()
	
	ProductConfigurationOptions = SetsServerCall.ProductConfigurationOptions(
		Products,
		Characteristic);
		
	If Not ValueIsFilled(ProductConfigurationOptions) Then
		Return;
	EndIf;
	
	ItemKitConfiguration = ProductConfigurationOptions.ItemKitConfiguration;
	
	SelectedGoods = SelectedGoods();
	
	SetPrice = 0;
	InStockSets = Undefined;
	AvailableSets_ = Undefined;
	
	SetComposition.Clear();
	For Each TSRow In SelectedGoods Do
		
		NewComponents = SetComposition.Add();
		NewComponents.Products = TSRow.Products;
		NewComponents.Characteristic = TSRow.Characteristic;
		NewComponents.Package = TSRow.Package;
		NewComponents.Count = TSRow.NumberOfPackages;
		NewComponents.Price = TSRow.Price;
		
		If TSRow.ItemsType = Enums.ItemsTypes.OwnGoods
			Or TSRow.ItemsType = Enums.ItemsTypes.ReusablePackage Then
		
			NewComponents.InStock = TSRow.InStock;
			NewComponents.Available = TSRow.Available;
			
			If NewComponents.Count <> 0 Then
				InStockAtRow = Int (NewComponents.InStock / NewComponents.Count);
			Else
				InStockAtRow = 0;
			EndIf;
			
			If NewComponents.Count <> 0 Then
				AvailableInLine_ = Int (NewComponents.Available / NewComponents.Count);
			Else
				AvailableInLine_ = 0;
			EndIf;
			
			If InStockSets = Undefined Or InStockAtRow < InStockSets Then
				InStockSets = InStockAtRow;
			EndIf;
			
			If AvailableSets_ = Undefined Or AvailableInLine_ < AvailableSets_ Then
				AvailableSets_ = AvailableInLine_;
			EndIf;
			
		EndIf;
		
		SetPrice = SetPrice + TSRow.Price * TSRow.NumberOfPackages;
		
	EndDo;
	
	InStock = InStockSets;
	Available = AvailableSets_;
	
	If ProductConfigurationOptions.SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices Then
		Items.Price.Enabled = False;
		Price = SetPrice;
	Else
		Items.Price.Enabled = True;
	EndIf;
	
	Items.UnitOfMeasure.Visible = True;
	
EndProcedure

&AtClient
Procedure SetCompositionOnActivateRow(Item)
	
	If Items.SetComposition.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	RowOfProduct = SetComposition.FindByID(Items.SetComposition.CurrentRow);
	
	ParametersForGettingPriceAndBalances = SelectGoodsClientServer.NewParametersForGettingPriceAndBalanceOfGoods();
	ParametersForGettingPriceAndBalances.Products = RowOfProduct.Products;
	ParametersForGettingPriceAndBalances.Characteristic = RowOfProduct.Characteristic;
	ParametersForGettingPriceAndBalances.Terms = Terms;
	ParametersForGettingPriceAndBalances.Currency = Currency;
	ParametersForGettingPriceAndBalances.Warehouses = Warehouses;
	ParametersForGettingPriceAndBalances.TypesOfPrices = TypesOfPrices;
	ParametersForGettingPriceAndBalances.ControlledLotReference = ControlledLotReference;
	ParametersForGettingPriceAndBalances.GetBalance = ShowBalance;
	ParametersForGettingPriceAndBalances.GetPrice = Not HidePrice;
	
	GoodsInformation = SelectGoodsServerCall.SalePriceAndProductBalances(ParametersForGettingPriceAndBalances);
	
	StockInWarehouses = StockBalance.GetItems();
	StockInWarehouses.Clear();
	
	SalePriceOfGoods = GoodsInformation.Price;
	
	PackageNameUnitsOfMeasurement = ?(ValueIsFilled(SalePriceOfGoods.Package),
		String(SalePriceOfGoods.Package), 
		String(SalePriceOfGoods.UnitOfMeasure));
		
	For Each TBLString In GoodsInformation.CurrentItemsBalance Do
		
		InventoryBalancesLine = StockInWarehouses.Add();
		
		InventoryBalancesLine.Period = CurrentSessionDate;
		InventoryBalancesLine.PeriodDescription = NStr("vi = 'Vừa xong';
														|ru = 'Сейчас';
														|en = 'Now'; fa = 'اکنون';
														|it = 'Adesso';
														|pl = 'Now';
														|tr = 'Şimdi'");
		InventoryBalancesLine.Available = TBLString.AvailableForInventoryAllocation;
		InventoryBalancesLine.Inventory = TBLString.Inventory;
		
		InventoryBalancesLine.DescriptionAvailable = "";
		InventoryBalancesLine.StockDescription = "";
		
		If InventoryBalancesLine.Inventory > 0 Then
			InventoryBalancesLine.StockDescription = Format(InventoryBalancesLine.Inventory, "NFD=3")
				+ " "
				+ PackageNameUnitsOfMeasurement;
		EndIf;
		
		If InventoryBalancesLine.Available > 0 Then
			InventoryBalancesLine.DescriptionAvailable = Format(InventoryBalancesLine.Available, "NFD=3")
				+ " "
				+ PackageNameUnitsOfMeasurement;
		EndIf;
		
		InventoryBalancesLine.Warehouse = TBLString.Warehouse;
		InventoryBalancesLine.WarehouseDescription = String(TBLString.Warehouse);
		
		PlannedBalancesByDate = InventoryBalancesLine.GetItems();
		
		ThereArePlannedRemnants = False;
		For Each TBLString In GoodsInformation.PlannedBalances_ Do
			
			If Not (TBLString.Warehouse = InventoryBalancesLine.Warehouse) Then
				Continue;
			EndIf;
			
			ThereArePlannedRemnants = True;
			
			LinePlannedBalancesByDate = PlannedBalancesByDate.Add();
			
			LinePlannedBalancesByDate.Period = TBLString.Period;
			LinePlannedBalancesByDate.PeriodDescription = Format(TBLString.Period, "DLF=D");
			LinePlannedBalancesByDate.Available = TBLString.Available;
			LinePlannedBalancesByDate.Inventory = TBLString.Inventory;
			
			If LinePlannedBalancesByDate.Inventory > 0 Then
				LinePlannedBalancesByDate.StockDescription = Format(InventoryBalancesLine.Inventory, "NFD=3")
					+ " "
					+ PackageNameUnitsOfMeasurement;
			EndIf;
			
			If LinePlannedBalancesByDate.Available > 0 Then
				LinePlannedBalancesByDate.DescriptionAvailable = Format(InventoryBalancesLine.Available, "NFD=3")
					+ " "
					+ PackageNameUnitsOfMeasurement;
			EndIf;
			
			LinePlannedBalancesByDate.Warehouse = TBLString.Warehouse;
			LinePlannedBalancesByDate.WarehouseDescription = "";
			
		EndDo;
		
		If InventoryBalancesLine.Inventory = 0 And Not ThereArePlannedRemnants Then
			StockInWarehouses.Delete(InventoryBalancesLine);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure DisplayBalanceLabelClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ShowBalance = Not ShowBalance;
	Items.StockBalance.Visible = ShowBalance;
	SelectGoodsClientServer.SetCaptionTextToDisplayLeftovers(ThisForm);
	
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
