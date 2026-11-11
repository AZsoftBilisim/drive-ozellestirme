#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

///////////////////////////////////////////////////////////////////////////////
// Procedures and functions used in the object module to complete processing.

Function Components(Object, Val Warehouses) Export
	
	WarehouseParameter = Catalogs.Warehouses.EmptyRef();
	If TypeOf(Warehouses) = Type("Array") Then
		If Warehouses.Count() = 1 Then
			WarehouseParameter = Warehouses[0];
		EndIf;
	Else
		Warehouses = New Array();
	EndIf;
	
	ComponentParameters = New Structure();
	
	ComponentParameters.Insert("ProductsInSet",              Object.Products);
	ComponentParameters.Insert("ItemVariantOfSet",            Object.Characteristic);
	ComponentParameters.Insert("PriceKind",                         Object.PriceKind);
	ComponentParameters.Insert("ItemKitConfiguration", Object.ItemKitConfiguration);
	ComponentParameters.Insert("Currency",                          Object.Currency);
	ComponentParameters.Insert("NumberOfPackages",              Object.NumberOfPackages);
	ComponentParameters.Insert("Count",                      Object.NumberOfPackages);
	ComponentParameters.Insert("DateOfShipment",                    '00010101');
	ComponentParameters.Insert("PercentRateOfManualDiscount",             Object.PercentRateOfManualDiscountMarkup);
	ComponentParameters.Insert("Warehouse",                           WarehouseParameter);
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("Date",                           Object.Date);
	AdditionalParameters.Insert("Currency",                         Object.Currency);
	AdditionalParameters.Insert("Price",                           Object.Price);
	AdditionalParameters.Insert("PriceKind",                        Object.PriceKind);
	AdditionalParameters.Insert("Terms",                     Object.Terms);
	AdditionalParameters.Insert("Warehouses",                         Warehouses);
	AdditionalParameters.Insert("Purpose",
		?(Object.WithAssignment, Object.Purpose, Catalogs.Assignments.EmptyRef()));
	
	Result = SetsServerCall.Components(ComponentParameters, AdditionalParameters);
	Return Result;
	
EndFunction

Procedure SetPriceByPriceType(Object, KeyParameters) Export
	
	If ValueIsFilled(Object.ItemKitConfiguration) Then
		Return;
	EndIf;
	
	If Not KeyParameters.EditPriceType Then
		Return;
	EndIf;
	
	FoundRows = Object.TypesOfPrices.FindRows(New Structure("PriceKind", Object.PriceKind));
	If FoundRows.Count() > 0 Then
		Object.Price = FoundRows[0].Price;
	EndIf;
	
EndProcedure

Procedure FillInPriceTypes(Object, EditPriceType) Export
	
	UsePriceManagementSystem25 = Object.UsePriceManagementSystem25;
	
	Object.TypesOfPrices.Clear();
	ThisIsSetOfPricesForComponents = Not Object.ItemKitConfiguration.IsEmpty() 
		And Object.SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices;
		
	If Not EditPriceType Then
		If Not Object.PriceKind.IsEmpty() Then
			NewRow = Object.TypesOfPrices.Add();
			NewRow.PriceKind = Object.PriceKind;
		EndIf;
		Return;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("PriceIncludesVAT",              Object.PriceIncludesVAT);
	Query.SetParameter("WithoutFilterByVATInclusionInPrice", Object.WithoutFilterByVATInclusionInPrice);
	Query.SetParameter("Date",                         Object.Date);
	Query.SetParameter("Products",                 Object.Products);
	If UsePriceManagementSystem25 Then
		ItemVariantsOwner = Undefined;
		If Catalogs.Products.CheckUsageCharacteristicsAndGetOwnerToSelect(Object.Products, ItemVariantsOwner) Then
			Query.SetParameter("Characteristic",               ?(Object.Characteristic.IsEmpty(), 
													Catalogs.ItemsCharacteristicsForPricing.EmptyRef(), 
													Object.Characteristic.ItemsCharacteristicForPricing));
		Else
			Query.SetParameter("Characteristic",       Catalogs.ItemsCharacteristicsForPricing.EmptyRef()); 
		EndIf;
		Query.SetParameter("PricingBatch",                  Catalogs.ItemsBatchesForPricing.EmptyRef());
		
		SettingsOfPriceKeyByPackage = Common.ObjectAttributeValue(Object.Products, "ProductKind.SettingsOfPriceKeyByPackage");
		
		If SettingsOfPriceKeyByPackage = Enums.FilterOptionForPriceKey.DontUse Then
			Query.SetParameter("PricingPackage",               Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		Else
			Query.SetParameter("PricingPackage",               Object.Package);
		EndIf;
	Else
		Query.SetParameter("Characteristic",               Object.Characteristic);
	EndIf;
	Query.SetParameter("Currency",                       Object.Currency);
	Query.SetParameter("Package",                     Object.Package);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	QueryTexts = New Array();
		
	If ThisIsSetOfPricesForComponents Then

		QueryText =
			"SELECT ALLOWED
			|	TypesOfPrices.Ref AS PriceKind
			|FROM
			|	Catalog.TypesOfPrices AS TypesOfPrices
			|WHERE
			|	NOT TypesOfPrices.DeletionMark
			|	AND TypesOfPrices.UseWhileSellingToCustomers
			|	AND TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)
			|	AND (&WithoutFilterByVATInclusionInPrice
			|			OR TypesOfPrices.PriceIncludesVAT = &PriceIncludesVAT)";
	
		QueryTexts.Add(QueryText);
		
	Else 
		
		QueryText = 
		"SELECT ALLOWED
		|	TypesOfPrices.Ref AS PriceKind
		|INTO TypesOfPrices
		|FROM
		|	Catalog.TypesOfPrices AS TypesOfPrices
		|WHERE
		|	NOT TypesOfPrices.DeletionMark
		|	AND TypesOfPrices.UseWhileSellingToCustomers
		|	AND TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)
		|	AND (&WithoutFilterByVATInclusionInPrice
		|			OR TypesOfPrices.PriceIncludesVAT = &PriceIncludesVAT)
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
		|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS RatesCutCurrencyPrices
		|;";

		QueryTexts.Add(QueryText);
		
		If UsePriceManagementSystem25 Then
			QueryText = "
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	ItemPricesCrossSectionOfTheLatest.PriceKind AS PriceKind,
			|	ItemPricesCrossSectionOfTheLatest.Currency AS Currency,
			|	ItemPricesCrossSectionOfTheLatest.Price AS Price,
			|	ISNULL(&QueryTextPackagingFactor1, 1) / ISNULL(&QueryTextPackagingFactor2, 1) AS ZoomRatio
			|INTO ItemPricesCrossSectionOfTheLatest
			|FROM
			|	InformationRegister.ItemsPrices25.SliceLast(
			|			ENDOFPERIOD(&Date, DAY),
			|			Products = &Products
			|				AND PricingVariant = &Characteristic
			|				AND PricingBatch = &PricingBatch
			|				AND PricingPackage = &PricingPackage
			|				AND PriceKind IN
			|					(SELECT
			|						TypesOfPrices.PriceKind
			|					FROM
			|						TypesOfPrices AS TypesOfPrices)) AS ItemPricesCrossSectionOfTheLatest
			|;";
		Else
			QueryText = "
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
			|;";
		EndIf;

		QueryTexts.Add(QueryText);

		QueryText = "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ItemPricesCrossSectionOfTheLatest.PriceKind AS PriceKind,
		|	CAST(ItemPricesCrossSectionOfTheLatest.Price * CrossSectionCourses.CourseNumerator / CrossSectionCourses.CourseDenominator / RatesCutCurrencyPrices.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator * ItemPricesCrossSectionOfTheLatest.ZoomRatio AS NUMBER(31,2)) AS Price
		|FROM
		|	ItemPricesCrossSectionOfTheLatest AS ItemPricesCrossSectionOfTheLatest
		|		LEFT JOIN CrossSectionCourses AS CrossSectionCourses
		|		ON CrossSectionCourses.Currency = ItemPricesCrossSectionOfTheLatest.Currency
		|		LEFT JOIN RatesCutCurrencyPrices AS RatesCutCurrencyPrices
		|		ON TRUE";

		QueryTexts.Add(QueryText);
		
		QueryText = StrConcat(QueryTexts);
	
		Substitution = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure)",
			"ItemPricesCrossSectionOfTheLatest.Products");
		
		QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor1", Substitution);
		
		Substitution = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products");
		
		QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor2", Substitution);
	
	EndIf;
	
	Query.Text = QueryText;

	Table = Query.Execute().Unload();

	If Not Object.PriceKind.IsEmpty() Then
		
		If Table.Find(Object.PriceKind, "PriceKind") = Undefined Then
			NewRow = Table.Add();
			NewRow.PriceKind = Object.PriceKind;
		EndIf;
		
	EndIf;
	
	Object.TypesOfPrices.Load(Table);
	
EndProcedure

Procedure KitCompositionCalculateQuantityPickUp(Object) Export
	
	For Each TSRow In Object.SetComposition Do
		TSRow.QuantityPick = Object.Count * TSRow.NumberOfPackages;
	EndDo;
	
EndProcedure

Procedure SetPriceAccordingToCompositionOfSet(Object) Export
	
	If Object.ItemKitConfiguration.IsEmpty() Then
		Return;
	EndIf;
	
	If Object.SetPricingOption <> Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices Then
		Return;
	EndIf;
	
	Object.Price = 0;
	
	For Each String In Object.SetComposition Do
		Object.Price = Object.Price + String.Price * String.NumberOfPackages;
	EndDo;
	
EndProcedure

Procedure CheckFilling(Object) Export
	
	ErrorText = Undefined;
	
	If Common.ObjectAttributeValue(Object.Products, "ItemsType") = Enums.ItemsTypes.Set
			And Not ValueIsFilled(Object.ItemKitConfiguration) Then
		
		ErrorText = StrTemplate(NStr("vi = 'Đối với mặt hàng %1 chưa xác định thành phần tập hợp';
									|ru = 'Для номенклатуры %1 не определен состав набора';
									|en = 'Set content is not determined for products %1'; fa = 'Set content is not determined for products %1';
									|it = 'Per gli articoli non è definita %1 la composizione del set';
									|pl = 'Dla towaru %1 nie jest określony skład zestawu';
									|tr = '%1 öğesi için set kapsamı tanımlanmadı'"), Object.Products);
		
	ElsIf ValueIsFilled(Object.Warehouse) And Common.ObjectAttributeValue(Object.Warehouse, "Ref", True) = Undefined Then
		
		ErrorText = NStr("vi = 'Kho bãi tại dòng không khả dụng. Không thể chọn thao tác.';
						|ru = 'Склад в строке недоступен. Выбор действий невозможен.';
						|en = 'The warehouse on the line is not available. Selecting actions is not available.'; fa = 'The warehouse on the line is not available. Selecting actions is not available.';
						|it = 'Il magazzino nella riga non è disponibile. Impossibile scegliere un''azione.';
						|pl = 'Magazyn w wierszu jest niedostępny. Wybór działań jest niemożliwy.';
						|tr = 'Satırdaki ambar erişilebilir değil. İşlem seçimi mümkün değil.'");
		
	EndIf;
	
	If ErrorText <> Undefined Then
		
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Procedures and functions used in the processing form.

Procedure RecalculateLeftoversInPackage(Goods, Package, Products, Characteristic) Export
	
	PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, Products);
	FoundRows = Goods.FindRows(New Structure("Products,Characteristic", Products, Characteristic));
	For Each String In FoundRows Do
		
		InStock  = String.AvailableAtBaseUnit / PackagingFactor;
		OnSchedule = String.BasedOnScheduleAtBaseUnit / PackagingFactor;
		InReserve  = String.ReservedAtBaseUnit / PackagingFactor;
		
		If String.InStock <> InStock
			Or String.OnSchedule <> OnSchedule
			Or String.InReserve <> InReserve Then // if changes are made to the line, it will be transmitted to the client.
			
			String.InStock  = InStock;
			String.OnSchedule = OnSchedule;
			String.InReserve  = InReserve;
			
			String.InStockAssigned  = ?(String.WithAssignment, String.InStock, 0);
			String.BasedOnScheduleAssigned = ?(String.WithAssignment, String.OnSchedule, 0);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function CurDetails_(Object) Export
	
	Result = New Structure("Products,Characteristic,Package,ProductIndexForSelection");
	If Not ValueIsFilled(Object.ItemKitConfiguration) Then
		
		Result.Products   = Object.Products;
		Result.Characteristic = Object.Characteristic;
		Result.Package       = Object.Package;
		Result.ProductIndexForSelection = 0;
		
	ElsIf Object.SetComposition.Count() > 0 Then
		
		Result.Products   = Object.SetComposition[0].Products;
		Result.Characteristic = Object.SetComposition[0].Characteristic;
		Result.Package       = Object.SetComposition[0].Package;
		Result.ProductIndexForSelection = 0;
		
	Else
		
		Result.Products   = Undefined;
		Result.Characteristic = Undefined;
		Result.Package       = Undefined;
		Result.ProductIndexForSelection = 0;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure CompositionOfSetRecalculate(Object, Attribute) Export
	
	If Attribute = "COUNT" Or Attribute = "NUMBEROFPACKAGES" Then
		
		CompositionOfSetCalculateQuantity(Object);
		KitCompositionCalculateQuantityPickUp(Object);
		
	ElsIf Attribute = "QUANTITYPICK" Then
		
		KitCompositionCalculateQuantityPickUp(Object);
		
	EndIf;
	
EndProcedure

// Parameters:
//  Form - ClientApplicationForm -
//  KeyParameters - See ProvisionInDocumentsClientServer.ParametersOfQuantityAndSeriesRequestForm
//  RowIndex - Number -
//  SeriesSpecificationParameters - See ProductsServer.SeriesSpecificationParameters
Procedure FillInSeriesForProductsLine(Form, KeyParameters, RowIndex, SeriesSpecificationParameters) Export
	
	SelectSeries = KeyParameters.SelectSeries;
	Object = Form.Object; // DataProcessorObject.QuantityAndBatchRequest
	String = Object.Goods[RowIndex];
	
	If Not SelectSeries
			Or String.BatchesIndicationStatus = 0
			Or String.NumberOfBatchesFirstRow <> 0
			Or String.WithAssignment
				And Not ValueIsFilled(String.Purpose) Then
		Return;
	EndIf;
	
	FilterStructure1 = New Structure("Products,Characteristic,Warehouse,WithAssignment");
	FillPropertyValues(FilterStructure1, String);
	
	ProductKind = Common.ObjectAttributeValue(String.Products, "ProductKind");
	
	DataAcquisitionOption = DataProcessors.SelectBatchToDocuments.OptionGettingDataFromRegistersByFormParameters(
		SeriesSpecificationParameters,
		Undefined,
		String.Warehouse,
		ProductKind);
		
	If IsTempStorageURL(Form.Parameters.TableAddressSelectedEarlier) Then
		
		If KeyParameters.SelectGoods Then
			SelectedEarlier = GetFromTempStorage(Form.Parameters.TableAddressSelectedEarlier).Copy(FilterStructure1);
		Else
			SelectedEarlier = GetFromTempStorage(Form.Parameters.TableAddressSelectedEarlier);
		EndIf;
		
	Else
		
		SelectedEarlier = New ValueTable();
		SelectedEarlier.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
		SelectedEarlier.Columns.Add("Count", New TypeDescription("Number"));
		SelectedEarlier.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		SelectedEarlier.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		SelectedEarlier.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
		SelectedEarlier.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		SelectedEarlier.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
		
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Products", String.Products);
	Query.SetParameter("Characteristic", String.Characteristic);
	Query.SetParameter("Purpose", String.Purpose);
	Query.SetParameter("Warehouse", String.Warehouse);
	Query.SetParameter("Department", String.Department);
	Query.SetParameter("Premise", Catalogs.Warerooms.EmptyRef());
	Query.SetParameter("Recorder", Object.Recorder);
	Query.SetParameter("ReferenceOrder", Undefined);
	Query.SetParameter("SelectedEarlier", SelectedEarlier);
	Query.SetParameter("AllSeries", True);
	Query.SetParameter("ControlledLotReference", Object.ControlledLotReference);
	
	For Each AdditionalParameter In SeriesSpecificationParameters.ParametersForGettingDataFromRegisters Do
		Query.SetParameter(AdditionalParameter.Key, AdditionalParameter.Value);
	EndDo;
	
	QueryTexts = New Array();
	QueryText = DataProcessors.SelectBatchToDocuments.TextOfRequestToGenerateTableRegisterData(
		DataAcquisitionOption,
		String.Warehouse);
		
	QueryTexts.Add(QueryText);
	
	QueryText =
		"SELECT
		|	Table.Series      AS Series,
		|	Table.Count AS Count
		|INTO TableOfGoods
		|FROM
		|	&SelectedEarlier AS Table
		|WHERE
		|	Table.Products = &Products
		|		AND Table.Characteristic = &Characteristic
		|		AND Table.Warehouse = &Warehouse
		|		AND Table.Purpose = &Purpose
		|		AND Table.Department = &Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Series             AS Series,
		|	SUM(Table.Count) AS Count
		|INTO SelectedEarlier
		|FROM
		|	TableOfGoods AS Table
		|GROUP BY
		|	Table.Series
		|INDEX BY
		|	Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataOfRegister.Series                                                    AS Series,
		|	DataOfRegister.AvailableStock - ISNULL(SelectedEarlier.Count,0) AS Available,
		|	&RequestTextDetailsAndSelection
		|FROM
		|	DataOfRegister AS DataOfRegister
		|		
		|		LEFT JOIN SelectedEarlier AS SelectedEarlier
		|		ON SelectedEarlier.Series = DataOfRegister.Series
		|ORDER BY
		|	ValidUntil_,
		|	Number";
	
	ProductKind = Common.ObjectAttributeValue(String.Products, "ProductKind");
	SeriesUseSettings = Catalogs.ItemKinds.SeriesUseSettings(
		ProductKind,
		SeriesSpecificationParameters,
		New Structure("Warehouse", String.Warehouse));
	Substitution = DataProcessors.SelectBatchToDocuments.RequestTextDetailsOfSeries("DataOfRegister", SeriesUseSettings, False);
	QueryText = StrReplace(QueryText, "&RequestTextDetailsAndSelection", Substitution);
	
	QueryTexts.Add(QueryText);
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	BalanceTable = Query.Execute().Unload();
	
	If BalanceTable.Count() = 0 Then
		NumberOfBatchesFirstRow = -1;
	Else
		NumberOfBatchesFirstRow = Object.SetOfSeries.Count() + 1;
	EndIf;
	
	For Each SeriesString In BalanceTable Do
		
		NewSeriesLine = Object.SetOfSeries.Add();
		FillPropertyValues(NewSeriesLine, String, "Products,Characteristic,Warehouse,Purpose");
		FillPropertyValues(NewSeriesLine, SeriesString);
		NewSeriesLine.CheckAvailability = NewSeriesLine.Available > 0;
		
	EndDo;
	
	TMPropertyManagement.FillInColumnsOfAdditionalDetails(
		Form,
		"Object.SetOfSeries",
		"Series");
	
	FoundRows = Object.Goods.FindRows(FilterStructure1);
	For Each String In FoundRows Do
		String.NumberOfBatchesFirstRow = NumberOfBatchesFirstRow;
	EndDo;
	
EndProcedure

Procedure UploadPriceTypesToList(Object, List, WithPrices) Export
	
	If WithPrices Then
		List.Clear();
		For Each String In Object.TypesOfPrices Do
			Presentation = StrTemplate("%1 (%2)", Format(String.Price, "NFD=2; NZ="), String.PriceKind);
			List.Add(String.PriceKind, Presentation);
		EndDo;
	Else
		List.LoadValues(Object.TypesOfPrices.Unload().UnloadColumn("PriceKind"));
	EndIf;
	
EndProcedure

Procedure PackageOnChange(Object, KeyParameters) Export
	
	FillInPriceTypes(Object, KeyParameters.EditPriceType);
	SetPriceByPriceType(Object, KeyParameters);
	SetPriceAccordingToCompositionOfSet(Object);
	
	If Not ValueIsFilled(Object.PriceKind)
		Or Not KeyParameters.EditPriceType Then
		Object.Price = Object.InitialPrice *
			Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Object.Package, Object.Products) /
			Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Object.OriginalPackaging, Object.Products);
	EndIf;
	
EndProcedure

Procedure PriceKindOnChange(Object, KeyParameters, Warehouses) Export
	
	ArrayOfComponents = Components(Object, Warehouses);
	Table = Object.SetComposition.Unload(New Array);
	For Each TSRow In ArrayOfComponents Do
		NewComponents = Table.Add();
		FillPropertyValues(NewComponents, TSRow);
	EndDo;

	CompositionOfSetUpdatePrices(Object, Table);
	
	If Object.SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices Then
		SetPriceAccordingToCompositionOfSet(Object);
	Else
		SetPriceByPriceType(Object, KeyParameters);
	EndIf;
	
EndProcedure

Procedure PriceOnChange(Object, Warehouses) Export
	
	ArrayOfComponents = Components(Object, Warehouses);
	Table = Object.SetComposition.Unload(New Array);
	For Each TSRow In ArrayOfComponents Do
		NewComponents = Table.Add();
		FillPropertyValues(NewComponents, TSRow);
	EndDo;

	CompositionOfSetUpdatePrices(Object, Table);
	
	If Object.SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices Then
		SetPriceAccordingToCompositionOfSet(Object);
	EndIf;
	
EndProcedure

// Others .

Function NamesOfSeriesElements(AttributeName) Export
	
	TagName = "";
	
	If AttributeName = "Number" Then
		TagName = "SetOfSeriesNumber";
	ElsIf AttributeName = "ProductionDate" Then
		TagName = "SetOfSeriesProductionDate";
	ElsIf AttributeName = "ValidUntil_" Then
		TagName = "SetOfSeriesValidUntil_";
	ElsIf Upper(AttributeName) = Upper("NumberOfSPMSControlIdentificationMark") Then
		TagName = "SetOfSeriesNumberOfSPMSControlIdentificationMark";
	ElsIf AttributeName = "ManufacturerUSAIS" Then
		TagName = "SetOfSeriesManufacturerUSAIS";
	ElsIf AttributeName = "Certificate2USAIS" Then
		TagName = "SetOfSeriesCertificate2USAIS";
	ElsIf AttributeName = "ManufacturerVetIS" Then
		TagName = "SetOfSeriesManufacturerVetIS";
	ElsIf AttributeName = "WarehouseBookRecordVetIS" Then
		TagName = "SetOfSeriesWarehouseBookRecordVetIS";
	ElsIf AttributeName = "LotIDVetIS" Then
		TagName = "SetOfSeriesLotIDVetIS";
	ElsIf AttributeName = "MaximumRetailPriceMOTP" Then
		TagName = "SetOfSeriesMaximumRetailPriceMOTP";
	EndIf;
	
	Return TagName;
	
EndFunction

Procedure FillInStatusOfSeriesIndicationInTable(SupplyOption, Goods, SeriesSpecificationParameters, Warehouse) Export
	
	If Goods.Count() = 0 Then
		Return;
	EndIf;
	
	If Not SeriesSpecificationParameters.UseItemsBatch
			Or SeriesSpecificationParameters.ThisIsOrder
				And SupplyOption <> PredefinedValue("Enum.SupplyOptions.Ship")
				And SupplyOption <> PredefinedValue("Enum.SupplyOptions.FromWarehouse") Then
			
			For Each String In Goods Do
				String.BatchesIndicationStatus = 0;
			EndDo;
			Return;
			
	EndIf;
	
	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("Products",New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("Characteristic",New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfGoods.Columns.Add("Series",New TypeDescription("CatalogRef.ItemsBatches"));
	TableOfGoods.Columns.Add("SupplyOption",New TypeDescription("EnumRef.SupplyOptions"));
	TableOfGoods.Columns.Add("WithAssignment",New TypeDescription("Boolean"));
	TableOfGoods.Columns.Add(SeriesSpecificationParameters.FieldNameQuantity,TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
	TableOfGoods.Columns.Add("Package",New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	TableOfGoods.Columns.Add("LineNumber",New TypeDescription("Number",New NumberQualifiers(15,0,AllowedSign.Nonnegative)));
	If ValueIsFilled(SeriesSpecificationParameters.WarehouseFieldName) Then
		TableOfGoods.Columns.Add(SeriesSpecificationParameters.WarehouseFieldName,New TypeDescription("CatalogRef.Warehouses"));
	EndIf;
	
	ProductsServer.CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, TableOfGoods); // There is also a statuskazaniyasery
	
	TableOfSeries = TableOfGoods.Copy();
	
	If ValueIsFilled(SeriesSpecificationParameters.WarehouseFieldName)
			And TableOfGoods.Columns.Find(SeriesSpecificationParameters.WarehouseFieldName) = Undefined Then
		TableOfGoods.Columns.Add(SeriesSpecificationParameters.WarehouseFieldName, New TypeDescription("CatalogRef.Warehouses"));
	EndIf;
	If ValueIsFilled(SeriesSpecificationParameters.NameOfSenderWarehouseField)
			And TableOfGoods.Columns.Find(SeriesSpecificationParameters.NameOfSenderWarehouseField) = Undefined Then
		TableOfGoods.Columns.Add(SeriesSpecificationParameters.NameOfSenderWarehouseField, New TypeDescription("CatalogRef.Warehouses"));
	EndIf;
	If ValueIsFilled(SeriesSpecificationParameters.NameOfRecipientWarehouseField)
			And TableOfGoods.Columns.Find(SeriesSpecificationParameters.NameOfRecipientWarehouseField) = Undefined Then
		TableOfGoods.Columns.Add(SeriesSpecificationParameters.NameOfRecipientWarehouseField, New TypeDescription("CatalogRef.Warehouses"));
	EndIf;
	
	For LineNumber = 1 To Goods.Count() Do
		NewRow = TableOfGoods.Add();
		FillPropertyValues(NewRow, Goods[LineNumber - 1]);
		NewRow.SupplyOption = SupplyOption;
		If ValueIsFilled(SeriesSpecificationParameters.WarehouseFieldName) Then
			NewRow[SeriesSpecificationParameters.WarehouseFieldName] = Goods[LineNumber - 1].Warehouse;
		EndIf;
		If ValueIsFilled(SeriesSpecificationParameters.NameOfSenderWarehouseField) Then
			NewRow[SeriesSpecificationParameters.NameOfSenderWarehouseField] = Goods[LineNumber - 1].Warehouse;
		EndIf;
	EndDo;
	
	StructureWarehouses = New Structure;
	If ValueIsFilled(SeriesSpecificationParameters.WarehouseFieldName) Then
		StructureWarehouses.Insert(SeriesSpecificationParameters.WarehouseFieldName, Warehouse);
	EndIf;
	If ValueIsFilled(SeriesSpecificationParameters.NameOfSenderWarehouseField) Then
		StructureWarehouses.Insert(SeriesSpecificationParameters.NameOfSenderWarehouseField, Warehouse);
	EndIf;
	If ValueIsFilled(SeriesSpecificationParameters.NameOfRecipientWarehouseField) Then
		StructureWarehouses.Insert(SeriesSpecificationParameters.NameOfRecipientWarehouseField,Catalogs.Warehouses.EmptyRef());
	EndIf;
	
	ObjectStructure_ = Common.ValueTableRowToStructure(TableOfGoods[0]);
	CommonClientServer.SupplementStructure(ObjectStructure_, StructureWarehouses, True);
	
	If SeriesSpecificationParameters.TSSeriesName <> SeriesSpecificationParameters.NameTSGoods
		And ValueIsFilled(SeriesSpecificationParameters.TSSeriesName) Then
		ObjectStructure_.Insert(SeriesSpecificationParameters.TSSeriesName, TableOfSeries);
	EndIf;
	
	If Not SeriesSpecificationParameters.ProductInHeader Then
		ObjectStructure_.Insert(SeriesSpecificationParameters.NameTSGoods, TableOfGoods);
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ObjectStructure_, SeriesSpecificationParameters);
	
	VHFWarehouses = SeriesSpecificationParameters.LinkFields.Find(SeriesSpecificationParameters.WarehouseFieldName) <> Undefined
		Or SeriesSpecificationParameters.AdditionalFieldNames.Find(SeriesSpecificationParameters.WarehouseFieldName) <> Undefined
		Or SeriesSpecificationParameters.WarehouseFieldName = Undefined;
		
	For IndexOf = 0 To TableOfGoods.Count() - 1 Do
		If TableOfGoods[IndexOf].BatchesIndicationStatus > 8
				And (VHFWarehouses Or Goods[IndexOf].Warehouse = Warehouse)
			Or SeriesSpecificationParameters.ProductInHeader And ObjectStructure_.BatchesIndicationStatus > 8
				And Goods[IndexOf].Warehouse = Warehouse Then
			
				If SeriesSpecificationParameters.ProductInHeader Then
					Goods[IndexOf].BatchesIndicationStatus = ObjectStructure_.BatchesIndicationStatus;
				Else
					Goods[IndexOf].BatchesIndicationStatus = TableOfGoods[IndexOf].BatchesIndicationStatus;
				EndIf;
				
		Else
			Goods[IndexOf].BatchesIndicationStatus = 0;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Procedure CompositionOfSetCalculateQuantity(Object)
	
	CalculatedCount = 0;
	For Each TSRow In Object.SetComposition Do
		CalculatedCount = Max(TSRow.QuantityIsSelected / TSRow.Count, Object.Count);
	EndDo;
	If CalculatedCount > Object.Count Then
		Object.Count = CalculatedCount;
		Object.NumberOfPackages = Object.Count / Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Object.Package, Object.Products);
	EndIf;
	
EndProcedure

Procedure CompositionOfSetUpdatePrices(Object, Components)
	
	SearchFields = "Products,Characteristic";
	Filter = New Structure(SearchFields);
	Components.Indexes.Add(SearchFields);
	
	For Each String In Object.SetComposition Do
		
		FillPropertyValues(Filter, String);
		FoundRows = Components.FindRows(Filter);
		String.Price = ?(FoundRows.Count() > 0, FoundRows[0].Price, 0);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf