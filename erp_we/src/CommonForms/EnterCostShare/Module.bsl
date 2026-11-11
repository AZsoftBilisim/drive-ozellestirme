
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// Checking required parameters
	If Not Parameters.Property("ItemData_3")
		Or Not Parameters.Property("MethodOfAllocatingFinishedProductCosts") Then
		Raise NStr("vi = 'Để mở biểu mẫu, cần truyền các tham số.';
					|ru = 'Для открытия формы необходимо передать параметры.';
					|en = 'To open the form, pass the parameters.'; fa = 'To open the form, pass the parameters.';
					|it = 'Per l''apertura del modulo è necessario trasferire i parametri.';
					|pl = 'Aby otworzyć formularz, musisz przekazać parametry.';
					|tr = 'Formun açılması için parametreleri transfer etmeniz gerekmektedir.'");
	EndIf;
	
	If Not ValueIsFilled(Parameters.MethodOfAllocatingFinishedProductCosts) Then
		Raise NStr("vi = 'Phương pháp phân bổ chi phí cho sản phẩm đầu ra không được chuyển giao.';
					|ru = 'Способ распределения затрат на выходные изделия не передан.';
					|en = 'Method of allocating finished product costs is not passed.'; fa = 'Method of allocating finished product costs is not passed.';
					|it = 'Il metodo di ripartizione dei costi per i prodotti di output non è stato trasmesso.';
					|pl = 'Sposób przydziału kosztów wyrobów wyjściowych nie został przekazany.';
					|tr = 'Üretilen nihai ürünlere yönelik maliyet dağıtımı yöntemi aktarılmadı.'");
	EndIf;
	
	// Filling in the form parameters
	PriceKind    = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory();
	PriceCurrency = ?(ValueIsFilled(Parameters.ParametersForFillingInCostShares.Currency), 
									Parameters.ParametersForFillingInCostShares.Currency, 
									Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind).PriceCurrency);
	Date = ?(ValueIsFilled(Parameters.ParametersForFillingInCostShares.Date), 
								Parameters.ParametersForFillingInCostShares.Date, 
								CurrentSessionDate());

	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	GroupCosts = Parameters.GroupCosts;
	MethodOfAllocatingFinishedProductCosts = Parameters.MethodOfAllocatingFinishedProductCosts;
	
	PropertiesToFillIn = "Products,
		|Characteristic,
		|
		|Package,
		|NumberOfPackages,
		|Count,
		|
		|CostShare,
		|CostSharePerUnit";
		
	If Parameters.ItemData_3.Property("Series") Then
		PropertiesToFillIn = PropertiesToFillIn + ",Series";
	EndIf;
	
	FillPropertyValues(
		ThisForm,
		Parameters.ItemData_3,
		PropertiesToFillIn);
	
	CostSharePercentage = Parameters.CostSharePercentage;
	ShareOfCostTotal   = Parameters.ShareOfCostTotal;

	CostShareTotalNew       = ShareOfCostTotal;
	TotalCostShareWithoutTheCurrentOne = ShareOfCostTotal - CostShare;
	
	ParameterizationIsUsed = Parameters.ParameterizationIsUsed;
	
	CustomizeFormElements();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AFractionOfTheCostPerUnitWhenChanging(Item)
	
	StringStructure = New Structure("CostShare,CostSharePerUnit,Count", CostShare, CostSharePerUnit, Count);
	
	ProductionClientServer.CalculateFractionOfCostPerLine(StringStructure, MethodOfAllocatingFinishedProductCosts);
	FillPropertyValues(ThisForm, StringStructure);
	
	WhenChangingShareOfValue();
	
EndProcedure

&AtClient
Procedure CostShareOnChange(Item)
	
	StringStructure = New Structure("CostShare,CostSharePerUnit,Count", CostShare, CostSharePerUnit, Count);
	
	ProductionClientServer.CalculateFractionOfCostPerUnitInRow(StringStructure, MethodOfAllocatingFinishedProductCosts);
	FillPropertyValues(ThisForm, StringStructure);
	
	WhenChangingShareOfValue();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SelectionValue = New Structure("CostShare,CostSharePerUnit", CostShare, CostSharePerUnit);
	NotifyChoice(SelectionValue);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Modified = False;
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	// Title
	ProductsPresentation = ProductsClientServer.ProductPresentation(Products, Characteristic);
	ThisForm.Title = StrTemplate(NStr("vi = 'Tỷ lệ giá trị mặt hàng ""%1""';
										|ru = 'Доля стоимости номенклатуры ""%1""';
										|en = 'Cost share of the ""%1"" products'; fa = 'Cost share of the ""%1"" products';
										|it = 'Parte del costo dell''articolo""%1""';
										|pl = 'Udział kosztów towarów ""%1""';
										|tr = '""%1"" öğe maliyet payı'"), ProductsPresentation);
	ThisForm.AutoTitle = False;
	
	// View only
	If ReadOnly Then
		ItemArray = New Array;
		ItemArray.Add(Items.CostShare.Name);
		ItemArray.Add(Items.PlannedPrice.Name);
		ItemArray.Add(Items.PlannedCost.Name);
		ItemArray.Add(Items.Weight.Name);
		ItemArray.Add(Items.TheWeightOfARow.Name);
		ItemArray.Add(Items.VolumeM3.Name);
		ItemArray.Add(Items.LineSize_2.Name);
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "AutoMarkIncomplete", False);
	EndIf;
	Items.FormButtonGroupEdit.Visible = Not ReadOnly;
	Items.FormClose.Visible = ReadOnly;
	
	// Parameterization is used
	If ParameterizationIsUsed Then
		ItemArray = New Array;
		ItemArray.Add(Items.PlannedCostGroup.Name);
		ItemArray.Add(Items.ShareOfCostTotalAtPlannedCost.Name);
		ItemArray.Add(Items.ThePercentageOfCostThePercentageOfPlannedValue.Name);
		ItemArray.Add(Items.GroupRowWeight.Name);
		ItemArray.Add(Items.CostShareTotalByWeight.Name);
		ItemArray.Add(Items.CostSharePercentageByWeight.Name);
		ItemArray.Add(Items.GroupLineVolume.Name);
		ItemArray.Add(Items.ShareOfCostTotalByVolume.Name);
		ItemArray.Add(Items.ShareOfCostPercentageByVolume.Name);
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", False);
	EndIf;
	
	// Setting the current page, visibility of cost grouping
	ItemsNames = ItemNamesByCostAllocationMethod(MethodOfAllocatingFinishedProductCosts);
	
	Items.MethodsOfCostAllocatingOnProductCosts.CurrentPage = Items[ItemsNames.Page];
	Items[ItemsNames.Group].Visible = ValueIsFilled(GroupCosts);
	
	ConfigureDependentFormElements();
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElements()
	
	QueryText = "SELECT
	|	CAST(&Products   AS Catalog.Products)               AS Products,
	|	CAST(&Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	&FieldSeries,
	|	CAST(&Package       AS Catalog.PackagesAndUnitsOfMeasure)   AS Package
	|INTO TTTable
	|;
	|";
	
	If UsePriceManagementSystem25 Then
		QueryText = StrReplace(QueryText, "TTTable", "TTTablePreliminary") + 
		"
		|SELECT
		|	Table.Products       AS Products,
		|	Table.Characteristic     AS Characteristic,
		|	Table.Package           AS Package,
		|	ISNULL(CASE
		|		WHEN
		|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|		ELSE Table.Characteristic.ItemsCharacteristicForPricing
		|	END, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)) AS PricingVariant,
		|	ISNULL(CASE
		|		WHEN
		|			ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
		|		ELSE Table.Series.ItemsBatchForPricing
		|	END, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)) AS PricingBatch,
		|	CASE
		|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		ELSE Table.Package
		|	END AS PricingPackage
		|
		|INTO TTTable
		|FROM
		|	TTTablePreliminary AS Table
		|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|		ON ItemKinds.Ref = Table.Products.ProductKind
		|;
		|";
		
	EndIf;
	
	QueryText = QueryText + "
	|SELECT
	|
	|	Table.Products                AS Products,
	|	PRESENTATION(Table.Products) AS ProductsPresentation,
	|	
	|	Table.Characteristic                AS Characteristic,
	|	PRESENTATION(Table.Characteristic) AS CharacteristicPresentation,
	|
	|	Table.Products.UnitOfMeasure                AS UnitOfMeasure,
	|	PRESENTATION(Table.Products.UnitOfMeasure) AS UnitOfMeasurePresentation,
	|
	|	Table.Package     AS Package,
	|	&PackingRatio AS PackingRatio,
	|
	|	CASE
	|		WHEN ISNULL(Table.Package.UnitOfMeasure, &PackingEmptyLink) <> &PackingEmptyLink
	|			THEN PRESENTATION(Table.Package.UnitOfMeasure)
	|		ELSE PRESENTATION(Table.Package)
	|	END AS PackagePresentation,
	|
	|	&CostSharePerUnit AS WeightVolumePrice
	|
	|FROM
	|	TTTable AS Table
	|	,CompoundShareCost
	|";
	
	Query = New Query(QueryText);
	Query.Text = StrReplace(Query.Text, "&PackingRatio", Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("Table.Package","Table.Products"));
	
	If UsePriceManagementSystem25 Then
		
		Query.Text = StrReplace(Query.Text, "&FieldSeries,", "CAST(&Series AS Catalog.ItemsBatches) AS Series,");
		
		SubstitutionParameters = ProductionServer.SubstitutionParametersOfCostFractionCalculationAlgorithm(
			"Table",
			"&MethodOfAllocatingFinishedProductCosts",
			"(Products, PricingVariant, PricingBatch, PricingPackage) IN (
			|	SELECT
			|		T.Products,
			|		T.PricingVariant,
			|		T.PricingBatch,
			|		T.PricingPackage
			|	FROM
			|		TTTable AS T)",
			UsePriceManagementSystem25);
			
	Else
		
		Query.Text = StrReplace(Query.Text, "&FieldSeries,", "");
		
		SubstitutionParameters = ProductionServer.SubstitutionParametersOfCostFractionCalculationAlgorithm(
			"Table",
			"&MethodOfAllocatingFinishedProductCosts",
			"(Products, Characteristic) IN (
			|	SELECT
			|		T.Products,
			|		T.Characteristic
			|	FROM
			|		TTTable AS T)",
			UsePriceManagementSystem25);
			
	EndIf;
	ProductionServer.PerformSubstitutionOfCostFractionCalculationAlgorithm(Query.Text, SubstitutionParameters, UsePriceManagementSystem25);
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Package", Package);
	
	If UsePriceManagementSystem25 Then
		Query.SetParameter("Series", Series);
	EndIf;
	
	Query.SetParameter("PriceKind", PriceKind);
	Query.SetParameter("MethodOfAllocatingFinishedProductCosts", MethodOfAllocatingFinishedProductCosts);
	
	Query.SetParameter("PackingEmptyLink", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	Query.SetParameter("Date", Date);
	Query.SetParameter("Currency", PriceCurrency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	// Page Contents
	If MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByTargetCost Then
		
		List = New Array;
		List.Add(Items.PlannedPrice);
		List.Add(Items.PlannedCost);
		List.Add(Items.ShareOfCostTotalAtPlannedCost);
		DisplayUnitOfMeasurementInTooltip(List, PriceCurrency);
		
		Items.PlannedCostGroup.ToolTip = DecodingCalculationOfShareOfCostPlannedCost(Selection);
		
		If CostSharePerUnit = 0 And Not ValueIsFilled(Selection.WeightVolumePrice) Then
			Items.TheTextOfTheFullErrorOnThePrice.Title = ErrorMessageFillingInFormattedString("Price", Selection);
			Items.GroupErrorFillingInPrice.Visible = True;
		Else
			Items.GroupErrorFillingInPrice.Visible = False;
		EndIf;
		
	EndIf;
	
	If MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByWeight Then
		
		UnitType_ = "";
		MeasuringUnit = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Selection.UnitOfMeasure, UnitType_);
		DefaultUnitOfMeasurement = ProductsServer.DefaultUnitOfMeasurement("Weight");
		
		If ( Not MeasuringUnit Or UnitType_ <> "Weight" ) Then
			Items.Weight.Title = StrTemplate(NStr("vi = 'Trọng lượng (1 %1)';
													|ru = 'Вес (1 %1)';
													|en = 'Weight (1 %1)'; fa = 'Weight (1 %1)';
													|it = 'Peso (1 %1)';
													|pl = 'Waga (1 %1)';
													|tr = 'Ağırlık (1 %1)'"), Selection.UnitOfMeasure);
			Items.Weight.Visible = True;
		Else
			Items.Weight.Visible = False;
		EndIf;
		
		List = New Array;
		List.Add(Items.Weight);
		List.Add(Items.TheWeightOfARow);
		List.Add(Items.CostShareTotalByWeight);
		DisplayUnitOfMeasurementInTooltip(List, DefaultUnitOfMeasurement);
		
		Items.GroupRowWeight.ToolTip = DecodingCalculationOfShareOfCostVolumeWeight(Selection, MeasuringUnit, UnitType_, "Weight", DefaultUnitOfMeasurement);
		
		If CostSharePerUnit = 0 And Not ValueIsFilled(Selection.WeightVolumePrice) Then
			Items.TheTextErrorOfFillingWeight.Title = ErrorMessageFillingInFormattedString("Weight", Selection);
			Items.GroupErrorFillingWeight.Visible = True;
		Else
			Items.GroupErrorFillingWeight.Visible = False;
		EndIf;
		
	EndIf;
	
	If MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByVolume Then
		
		UnitType_ = "";
		MeasuringUnit = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Selection.UnitOfMeasure, UnitType_);
		DefaultUnitOfMeasurement = ProductsServer.DefaultUnitOfMeasurement("VolumeM3");
		
		If ( Not MeasuringUnit Or UnitType_ <> "VolumeM3" ) Then
			Items.VolumeM3.Title = StrTemplate(NStr("vi = 'Khối lượng (1 %1)';
													|ru = 'Объем (1 %1)';
													|en = 'Volume (1 %1)'; fa = 'Volume (1 %1)';
													|it = 'Volume (1 %1)';
													|pl = 'Objętość (1 %1)';
													|tr = 'Hacim (1 %1)'"), Selection.UnitOfMeasure);
			Items.VolumeM3.Visible = True;
		Else
			Items.VolumeM3.Visible = False;
		EndIf;
		
		List = New Array;
		List.Add(Items.VolumeM3);
		List.Add(Items.LineSize_2);
		List.Add(Items.ShareOfCostTotalByVolume);
		DisplayUnitOfMeasurementInTooltip(List, DefaultUnitOfMeasurement);
		
		Items.GroupLineVolume.ToolTip = DecodingCalculationOfShareOfCostVolumeWeight(Selection, MeasuringUnit, UnitType_, "VolumeM3", DefaultUnitOfMeasurement);
		
		If CostSharePerUnit = 0 And Not ValueIsFilled(Selection.WeightVolumePrice) Then
			Items.TheTextOfTheErrorOfFillingVolume.Title = ErrorMessageFillingInFormattedString("VolumeM3", Selection);
			Items.GroupErrorFillingVolume.Visible = True;
		Else
			Items.GroupErrorFillingVolume.Visible = False;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function DecodingCalculationOfShareOfCostVolumeWeight(Selection, MeasuringUnit, UnitType_, Type, DefaultUnitOfMeasurement)
	
	RowsArray = New Array();
	
	If ValueIsFilled(Package) Or Not ( MeasuringUnit And UnitType_ = Type ) Then
		
		UnitDenominator_ = "";
		
		If ValueIsFilled(Package) Then
			
			RowsArray.Add(StrTemplate("%1 %2", NumberOfPackages, Selection.PackagePresentation));
			RowsArray.Add(" x ");
			
			UnitDenominator_ = Selection.PackagePresentation;
			
		EndIf;
		
		If Not MeasuringUnit Or UnitType_ <> Type Then
			
			If ValueIsFilled(Package) Then
				RowsArray.Add(StrTemplate("%1 %2/%3", Selection.PackingRatio, Selection.UnitOfMeasurePresentation, UnitDenominator_));
			Else
				RowsArray.Add(StrTemplate("%1 %2", Count, Selection.UnitOfMeasurePresentation));
			EndIf;
			
			RowsArray.Add(" x ");
			
			UnitDenominator_ = Selection.UnitOfMeasurePresentation;
			
		EndIf;
		
		If UnitDenominator_ <> "" Then
			RowsArray.Add(StrTemplate("%1 %2/%3", CostSharePerUnit, DefaultUnitOfMeasurement, UnitDenominator_));
		Else
			RowsArray.Add(StrTemplate("%1 %2", CostSharePerUnit, DefaultUnitOfMeasurement));
		EndIf;
		
	EndIf;
	
	Details = StrConcat(RowsArray);
	Return Details; // 12kg (1 pack x 10 pcs/pack x 1.2 kg/piece)
	
EndFunction

&AtServer
Function DecodingCalculationOfShareOfCostPlannedCost(Selection)
	
	RowsArray = New Array();
	
	If ValueIsFilled(Selection.Package) Then
		RowsArray.Add(StrTemplate("%1 %2", NumberOfPackages, Selection.PackagePresentation));
		RowsArray.Add(" x ");
		RowsArray.Add(StrTemplate("%1 %2/%3", Selection.PackingRatio, Selection.UnitOfMeasurePresentation, Selection.PackagePresentation));
	Else
		RowsArray.Add(StrTemplate("%1 %2", Count, Selection.UnitOfMeasurePresentation));
	EndIf;
	RowsArray.Add(" x ");
	If Selection.UnitOfMeasurePresentation <> "" Then
		RowsArray.Add(StrTemplate("%1 %2/%3", CostSharePerUnit, PriceCurrency, Selection.UnitOfMeasurePresentation));
	Else
		RowsArray.Add(StrTemplate("%1 %2", CostSharePerUnit, PriceCurrency));
	EndIf;
	
	Details = StrConcat(RowsArray);
	Return Details;
	
EndFunction

&AtServer
Function ErrorMessageFillingInFormattedString(Type, Selection)
	
	WarningText = Undefined;
	ProductsPresentation = ProductsClientServer.ProductPresentation(Selection.ProductsPresentation, Selection.CharacteristicPresentation);
	
	If Type = "Price" Then
		
		Rows = New Array();
		
		If ValueIsFilled(PriceKind) Then
			PriceViewLink = GetURL(PriceKind);
		Else
			PriceViewLink = Undefined;
		EndIf;
		
		Rows.Add(NStr("vi = 'Đối với mặt hàng';
						|ru = 'Для номенклатуры';
						|en = 'For items'; fa = 'For items';
						|it = 'Per l''articolo';
						|pl = 'Dla towaru';
						|tr = 'Öğeye ilişkin'") + " ");
		Rows.Add(New FormattedString(ProductsPresentation,,,, GetURL(Products)));
		Rows.Add(" " + NStr("vi = 'không theo lịch trình';
							|ru = 'не задана плановая';
							|en = 'planned one not specified'; fa = 'planned one not specified';
							|it = 'non programmato';
							|pl = 'nie określono planowanej';
							|tr = 'belirtilmemiş standart'") + " ");
		Rows.Add(New FormattedString(NStr("vi = 'đơn giá';
											|ru = 'цена';
											|en = 'price'; fa = 'price';
											|it = 'prezzo';
											|pl = 'price';
											|tr = 'fiyat'"),,,, PriceViewLink));
		
		WarningText = New FormattedString(Rows); 
		
	EndIf;
	
	If Type = "VolumeM3" Then

		Rows = New Array();
		
		Rows.Add(NStr("vi = 'Đối với mặt hàng';
						|ru = 'Для номенклатуры';
						|en = 'For items'; fa = 'For items';
						|it = 'Per l''articolo';
						|pl = 'Dla towaru';
						|tr = 'Öğeye ilişkin'") + " ");
		Rows.Add(New FormattedString(ProductsPresentation,,,, GetURL(Products)));
		Rows.Add(" " + NStr("vi = 'âm lượng không được đặt';
							|ru = 'не задан объем';
							|en = 'volume is not specified'; fa = 'volume is not specified';
							|it = 'volume non indicato';
							|pl = 'nie określono objętości';
							|tr = 'hacim belirtilmedi'"));
		
		WarningText = New FormattedString(Rows);
		
	EndIf;
	
	If Type = "Weight" Then
		
		Rows = New Array();
		
		Rows.Add(NStr("vi = 'Đối với mặt hàng';
						|ru = 'Для номенклатуры';
						|en = 'For items'; fa = 'For items';
						|it = 'Per l''articolo';
						|pl = 'Dla towaru';
						|tr = 'Öğeye ilişkin'") + " ");
		Rows.Add(New FormattedString(ProductsPresentation,,,, GetURL(Products)));
		Rows.Add(" " + NStr("vi = 'trọng lượng không được đặt';
							|ru = 'не задан вес';
							|en = 'weight is not specified'; fa = 'weight is not specified';
							|it = 'peso non indicato';
							|pl = 'nie określono wagi';
							|tr = 'ağırlık belirtilmedi'"));
		
		WarningText = New FormattedString(Rows);
		
	EndIf;
	
	Return WarningText;
	
EndFunction

&AtServerNoContext
Procedure DisplayUnitOfMeasurementInTooltip(List, UnitOfMeasure)
	
	For Each Item In List Do
		Item.ToolTip = UnitOfMeasure;
	EndDo;
	
EndProcedure

&AtClient
Procedure WhenChangingShareOfValue()
	
	CostShareTotalNew = CostShare + TotalCostShareWithoutTheCurrentOne;
	
	If CostShareTotalNew <> 0 Then
		CostSharePercentage = (CostShare/CostShareTotalNew) * 100;
	Else
		CostSharePercentage = 0;
	EndIf;
	
	ConfigureDependentFormElements();
	
EndProcedure

&AtServerNoContext
Function ItemNamesByCostAllocationMethod(CostsAllocationMethod)
	
	MatchingElementNames = New Map;
	
	MatchingElementNames.Insert(
		Enums.MethodsOfCostAllocatingOnProductCosts.ByWeight,
		New Structure("Group, Page", "GroupingByWeight", "PageByWeight"));
	
	MatchingElementNames.Insert(
		Enums.MethodsOfCostAllocatingOnProductCosts.ByVolume,
		New Structure("Group, Page", "GroupingByVolume", "PageByVolume"));
	
	MatchingElementNames.Insert(
		Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares,
		New Structure("Group, Page", "GroupingByCostShares", "PageByCostShares"));
	
	MatchingElementNames.Insert(
		Enums.MethodsOfCostAllocatingOnProductCosts.ByTargetCost,
		New Structure("Group, Page", "GroupingByPlannedCost", "PageByPlannedCost"));
		
	MatchingElementNames.Insert(
		Enums.MethodsOfCostAllocatingOnProductCosts.ByCount,
		New Structure("Group, Page", "GroupingByQuantity", "PageByQuantity"));
	
	Return MatchingElementNames[CostsAllocationMethod];
	
EndFunction

#EndRegion