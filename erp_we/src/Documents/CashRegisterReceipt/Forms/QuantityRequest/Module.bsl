
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Products = Parameters.Products;
	PriceKind = Parameters.PriceKind;
	Warehouse = Parameters.Warehouse;
	Price = Parameters.Price;
	Date = Parameters.Date;
	Package = Parameters.Package;
	Organization = Parameters.Organization;
	
	ProductStructure_ = Common.ObjectAttributesValues(Products, "UnitOfMeasure, UsePackages");
	
	If Package.IsEmpty()
		And ProductStructure_.UsePackages Then 
		Package = SelectGoodsServerCall.GetStoragePackaging(Products);
	EndIf;
	
	OldPackaging = Package;
	
	If ProductStructure_.UsePackages Then
		Items.Package.InputHint = ProductStructure_.UnitOfMeasure;
	EndIf;
	
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
	
	ItemListPackagingGroup = Common.ObjectAttributeValue(Products, "PackagingGroup");
	Items.Package.Visible         = ValueIsFilled(ItemListPackagingGroup);
	Items.UnitOfMeasure.Visible = Not ValueIsFilled(ItemListPackagingGroup);
	
	UseWarerooms = (GetFunctionalOption("UseWarerooms") And Common.ObjectAttributeValue(Warehouse, "UseWarerooms"));
	
	If UseWarerooms Then
		Premise = WarehousesServer.RoomForProducts(New Structure("Warehouse, Products, Characteristic", Warehouse, Products, Characteristic));
	Else
		Items.Premise.Visible = False;
	EndIf;

	If ItemsType = PredefinedValue("Enum.ItemsTypes.Set") Then
		CalculateSetParameters();
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
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
		
		ProductParameters_1 = New Structure;
		ProductParameters_1.Insert("Products", Products);        
		ProductParameters_1.Insert("Characteristic", Characteristic);
		ProductParameters_1.Insert("Package", Package);
		ProductParameters_1.Insert("Price", Price);
		ProductParameters_1.Insert("PriceKind", PriceKind);
		ProductParameters_1.Insert("NumberOfPackages", NumberOfPackages);
		ProductParameters_1.Insert("Warehouse", Warehouse);
		ProductParameters_1.Insert("Premise", Premise);
		ProductParameters_1.Insert("Products", Products);
		
		SelectedGoods.Add(ProductParameters_1);
		
	EndIf;
	
	Close(SelectedGoods);
	
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
	ItemField.Field = New DataCompositionField(Items.ProductsUnitOfMeasure.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Count.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FractionalQuantityInBasicUnitsIsSpecified");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure PackagingWhenModifiedOnServer(OldPackaging)
	
	SetVisibilityNumberOfStorageUnits();
	UpdateCount();
	
	Price = Price * 
		Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products) /
		Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(OldPackaging, Products);
	
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

#Region Sets

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
	AdditionalParameters.Insert("Terms", Undefined);
	AdditionalParameters.Insert("Organization", Organization);
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
	
	If ProductConfigurationOptions.SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices Then
		SelectedGoods = SelectedGoods();
		Price = 0;
		For Each TSRow In SelectedGoods Do
			Price = Price + TSRow.Price * TSRow.NumberOfPackages;
		EndDo;
		Items.Price.Enabled = False;
	Else
		Items.Price.Enabled = True;
	EndIf;
	
	Items.Package.Visible         = False;
	Items.UnitOfMeasure.Visible = True;
	
EndProcedure

#EndRegion

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
