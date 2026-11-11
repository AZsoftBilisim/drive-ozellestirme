
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	PriceKind  = Parameters.PriceKind;
	Warehouse    = Parameters.Warehouse;
	Price     = Parameters.Price;
	Date     = Parameters.Date;
	Package = Parameters.Package;
	Organization = Parameters.Organization;
	
	ProductAttributes = New Structure(
		"UsePackages", 
		"UsePackages",
		"PackagingGroup");
	ProductsAttributes = Common.ObjectAttributesValues(Products, ProductAttributes);
	If Package.IsEmpty()
		And ProductsAttributes.UsePackages Then
		Package = SelectGoodsServerCall.GetStoragePackaging(Products);
	EndIf;
	
	OldPackaging = Package;
	
	Products   = Parameters.Products;
	Characteristic = Parameters.Characteristic;
	
	ItemsType = Common.ObjectAttributeValue(Products, "ItemsType");
	
	Currency = Parameters.Currency;
	
	NumberOfPackages = 1;
	
	Items.PriceKind.ReadOnly     = Not Parameters.EditPriceType;
	Items.PriceKind.SkipOnInput = Not Parameters.EditPriceType;
	Items.Price.ReadOnly        = Not Parameters.EditThePrice;
	Items.Price.SkipOnInput    = Not Parameters.EditThePrice;
	
	ProductName = "" + Parameters.Products + ?(ValueIsFilled(Parameters.Characteristic), " (" + Parameters.Characteristic + ")","");
	
	If Parameters.HidePrice Then
		Items.Price.Visible    = False;
		Items.Currency.Visible  = False;
		Items.PriceKind.Visible = False;
		ThisForm.AutoTitle     = False;
		ThisForm.Title         = NStr("vi = 'Nhập số lượng';
										|ru = 'Ввод количества';
										|en = 'Enter quantity'; fa = 'ورود مقدار';
										|it = 'Inserimento quantità';
										|pl = 'Wprowadzanie ilości';
										|tr = 'Miktar girin'");
	EndIf;
	
	Items.Package.Visible         = ValueIsFilled(ProductsAttributes.PackagingGroup);
	Items.UnitOfMeasure.Visible = Not ValueIsFilled(ProductsAttributes.PackagingGroup);
	
	Catalogs.PackagesAndUnitsOfMeasure.DisplayInformationAboutStorageUnit(Products, Items.Package);	
	
	UseWarerooms = (GetFunctionalOption("UseWarerooms") And Common.ObjectAttributeValue(Warehouse, "UseWarerooms"));
	
	If UseWarerooms Then
		Premise = WarehousesServer.RoomForProducts(New Structure("Warehouse, Products, Characteristic", Warehouse, Products, Characteristic));
	Else
		Items.Premise.Visible = False;
	EndIf;
	
	If ItemsType = PredefinedValue("Enum.ItemsTypes.Set") Then
		CalculateSetParameters();
	Else
		Items.GroupInStockUnitOfMeasurement.Visible = False;
	EndIf;
	
	SelectGoodsClientServer.SetCaptionTextToDisplayLeftovers(ThisForm);
	
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
Procedure PriceKindOnChange(Item)
	
	PriceViewWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PriceOnChange(Item)
	
	PriceKind = Undefined;
	
EndProcedure

&AtClient
Procedure DisplayBalanceLabelClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ShowBalance = Not ShowBalance;
	Items.StockBalance.Visible = ShowBalance;
	SelectGoodsClientServer.SetCaptionTextToDisplayLeftovers(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Function SelectedGoods()
	
	ProductConfigurationOptions = SetsServerCall.ProductConfigurationOptions(
		Products,
		Characteristic);
		
	If Not ValueIsFilled(ProductConfigurationOptions) Then
		Return New Array;
	EndIf;
	
	ItemKitConfiguration = ProductConfigurationOptions.ItemKitConfiguration;
	
	ComponentParameters = New Structure;
	ComponentParameters.Insert("ProductsInSet",              Products);
	ComponentParameters.Insert("ItemVariantOfSet",            Characteristic);
	ComponentParameters.Insert("ItemKitConfiguration", ItemKitConfiguration);
	ComponentParameters.Insert("PriceKind", PriceKind);
	ComponentParameters.Insert("Currency", Currency);
	
	ComponentParameters.Insert("Warehouse", Warehouse);
	ComponentParameters.Insert("NumberOfPackages", NumberOfPackages);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Date",    Date);
	AdditionalParameters.Insert("Currency",  Currency);
	AdditionalParameters.Insert("Price",    Price);
	AdditionalParameters.Insert("PriceKind", PriceKind);
	AdditionalParameters.Insert("Organization", Organization);
	AdditionalParameters.Insert("Warehouses", New Array);
	AdditionalParameters.Warehouses.Add(Warehouse);
	SelectedGoods = SetsServerCall.Components(ComponentParameters, AdditionalParameters);
	
	Return SelectedGoods;
	
EndFunction

&AtClient
Procedure AddSet(Command)
	
	Cancel = False;
	If NumberOfPackages = 0 Then
		
		ClearMessages();
		
		Message = New UserMessage;
		Message.Text = NStr("vi = 'Chưa điền số lượng';
							|ru = 'Не заполнено количество';
							|en = 'Quantity is not filled in'; fa = 'Quantity is not filled in';
							|it = 'Quantità non compilata';
							|pl = 'Nie wypełniono ilości';
							|tr = 'Miktar doldurulmadı'");
		Message.Field = "NumberOfPackages";
		Message.Message();
		
		Cancel = True;
		
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	If ItemsType = PredefinedValue("Enum.ItemsTypes.Set") Then
		
		SelectedGoods = SelectedGoods();
		
	Else
		
		SelectedGoods = New Array;
		
		ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
		ProductParameters_1.Products        = Products;
		ProductParameters_1.Characteristic      = Characteristic;
		ProductParameters_1.Package            = Package;
		ProductParameters_1.Price                = Price;
		ProductParameters_1.PriceKind             = PriceKind;
		ProductParameters_1.NumberOfPackages  = NumberOfPackages;
		ProductParameters_1.Warehouse               = Warehouse;
		ProductParameters_1.Insert("Premise", Premise);
		
		SelectedGoods.Add(ProductParameters_1);
		
	EndIf;
	
	Close(SelectedGoods);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure PackagingWhenModifiedOnServer(OldPackaging)
	
	OldPackagingCoefficient = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(OldPackaging, Products);
	PackageFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products);
	
	Price = Price * PackageFactor / OldPackagingCoefficient;
	
EndProcedure

&AtServer
Procedure PriceViewWhenChangedOnServer()
	
	Query = New Query("
		|SELECT
		|	CAST(ItemPricesCrossSectionOfTheLatest.Price * CrossSectionCourses.Rate / CrossSectionCourses.Repetition
		|		/ RatesCutCurrencyPrices.Rate * RatesCutCurrencyPrices.Repetition
		|		* ISNULL(&QueryTextPackagingFactor1, 1)
		|		/ ISNULL(&QueryTextPackagingFactor2, 1) AS NUMBER(31,2)) AS Price
		|FROM
		|	InformationRegister.ItemsPrices.SliceLast(ENDOFPERIOD(&Date, DAY), Products = &Products
		|		AND Characteristic = &Characteristic AND PriceKind = &PriceKind)
		|	AS ItemPricesCrossSectionOfTheLatest
		|LEFT JOIN
		|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CrossSectionCourses
		|ON
		|	CrossSectionCourses.Currency = ItemPricesCrossSectionOfTheLatest.Currency
		|LEFT JOIN
		|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS RatesCutCurrencyPrices
		|ON
		|	TRUE
		|");
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure)",
			"CAST(&Products AS Catalog.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"CAST(&Products AS Catalog.Products"));
	
	Query.SetParameter("PriceKind"        ,PriceKind);
	Query.SetParameter("Date"           ,Date);
	Query.SetParameter("Products"   ,Products);
	Query.SetParameter("Characteristic" ,Characteristic);
	Query.SetParameter("Package"       ,Package);
	Query.SetParameter("Currency"         ,Currency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		If ValueIsFilled(Selection.Price) Then
			Price = Selection.Price;
		Else
			Price = 0;
		EndIf;
	Else
		Price = 0;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

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
	
	Items.Package.Visible         = False;
	Items.UnitOfMeasure.Visible = True;
	
EndProcedure

#EndRegion

#EndRegion
