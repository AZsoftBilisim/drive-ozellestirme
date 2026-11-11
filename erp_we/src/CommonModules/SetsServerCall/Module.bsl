////////////////////////////////////////////////////////////////////////////////
// The "Set of Server Calls" module contains procedures and functions for
// working with sets.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// This function returns the default configuration option for the item
//
// Parameters:
//  Products - CatalogRef.Products - The position of the item.
//  Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//
// Returns:
//  CatalogRef.ProductKitConfigurations - The default configuration option.
//
Function DefaultProductConfigurationOption(Val Products, Val Characteristic) Export
	
	ItemKitConfiguration = Undefined;
	
	If Characteristic = Undefined Then
		Characteristic = Catalogs.ItemsCharacteristics.EmptyRef();
	EndIf;
	
	Query = New Query(
	"SELECT TOP 1
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration
	|FROM
	|	Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|WHERE
	|	ProductKitConfigurations.Owner = &Owner
	|	AND ProductKitConfigurations.Characteristic = &Characteristic
	|
	|ORDER BY
	|	ProductKitConfigurations.Main DESC,
	|	ProductKitConfigurations.DeletionMark");
	
	Query.SetParameter("Owner", Products);
	Query.SetParameter("Characteristic", Characteristic);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		ItemKitConfiguration = Selection.ItemKitConfiguration;
	EndIf;
	
	Return ItemKitConfiguration;
	
EndFunction

// This function returns parameters for the item's configuration option
// 
// Parameters:
//  Products - CatalogRef.Products - The position of the item.
//  Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//
// Returns:
//  Undefined, Structure - structure with properties:
//   * ItemKitConfiguration - CatalogRef.ProductKitConfigurations - Configuration option.
//   * SetPricingOption - EnumRef.SetPriceCalculationOptions - option for calculating the set price.
//   * PresentationOptionInPrintForms - EnumRef.OptionsOfSetPresentationInPrintForms -
//                                                 Option of providing in printed forms.
//   * Components - ValueTable - Accessories.
//   * ProductsOfMainComponent - CatalogRef.Products - Nomenclature of the main component.
//   * MainComponentCharacteristic - CatalogRef.ItemsCharacteristics - Characteristics of the main component.
//
Function ProductConfigurationOptions(Val Products, Val Characteristic) Export
	
	SetPrivilegedMode(True);
	
	If Characteristic = Undefined Then
		Characteristic = Catalogs.ItemsCharacteristics.EmptyRef();
	EndIf;
	
	Query = New Query(
	"SELECT TOP 1
	|	ProductKitConfigurations.Ref                                    AS ItemKitConfiguration,
	|	ProductKitConfigurations.SetPricingOption                  AS SetPricingOption,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.ProductsOfMainComponent           AS ProductsOfMainComponent,
	|	ProductKitConfigurations.MainComponentCharacteristic         AS MainComponentCharacteristic,
	|	ProductKitConfigurations.Goods.(
	|		Ref,
	|		LineNumber,
	|		Products,
	|		Products.UnitOfMeasure AS UnitOfMeasure,
	|		(Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)) AS PieceUnitOfMeasure,
	|		Products.ItemsType  AS ItemsType,
 	|		CASE 
	|			WHEN Products.UseVariants IN (
	|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|				THEN TRUE
	|			ELSE FALSE
	|		END                         AS ItemVariantsAreUsed,
	|		Characteristic,
	|		Package,
	|		NumberOfPackages,
	|		ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
	|		CostShare,
	|		Count
	|	) AS Components
	|FROM
	|	Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|WHERE
	|	ProductKitConfigurations.Owner = &Owner
	|	AND ProductKitConfigurations.Characteristic = &Characteristic
	|
	|ORDER BY
	|	ProductKitConfigurations.Main DESC");
	
	Query.SetParameter("Owner", Products);
	Query.SetParameter("Characteristic", Characteristic);
	
	QueryTextPackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ProductKitConfigurations.Goods.Package",
		"ProductKitConfigurations.Goods.Products");
	
	Query.Text = StrReplace(
		Query.Text,
		"&QueryTextPackagingFactor",
		QueryTextPackagingFactor);
	
	Result = Query.Execute().Unload();
	If Result.Count() > 0 Then
		
		ReturnValue = New Structure;
		ReturnValue.Insert("ItemKitConfiguration",           Result[0].ItemKitConfiguration);
		ReturnValue.Insert("SetPricingOption",                  Result[0].SetPricingOption);
		ReturnValue.Insert("PresentationOptionInPrintForms", Result[0].PresentationOptionInPrintForms);
		ReturnValue.Insert("Components",                             Result[0].Components);
		ReturnValue.Insert("ProductsOfMainComponent",           Result[0].ProductsOfMainComponent);
		ReturnValue.Insert("MainComponentCharacteristic",         Result[0].MainComponentCharacteristic);
		
		Return ReturnValue;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// The function returns the components of the set, their prices, and inventory balances
// 
// Parameters:
//  Parameters - Structure - Description of the set parameters.
//  AdditionalParameters - Structure - Other parameters (Calculation of prices and balances).
//
// Returns:
//  Array of Structure - Array with kit components. See SelectGoodsClientServer.ProductParameters_1
//                        ()
//
Function Components(Parameters, AdditionalParameters) Export
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(Parameters.ItemKitConfiguration) Then
		ItemKitConfiguration = DefaultProductConfigurationOption(
			Parameters.ProductsInSet,
			Parameters.ItemVariantOfSet);
	Else
		ItemKitConfiguration = Parameters.ItemKitConfiguration;
	EndIf;
	
	If Not Parameters.Property("NumberOfPackages") Then
		Parameters.Insert("NumberOfPackages", 1);
	EndIf;
	
	SelectedGoods = New Array;
	
	If Not ValueIsFilled(ItemKitConfiguration) Then
		ErrorText = NStr("vi = 'Đối với mặt hàng %1 chưa xác định thành phần tập hợp';
						|ru = 'Для номенклатуры %1 не определен состав набора';
						|en = 'Set content is not determined for products %1'; fa = 'Set content is not determined for products %1';
						|it = 'Per gli articoli non è definita %1 la composizione del set';
						|pl = 'Dla towaru %1 nie jest określony skład zestawu';
						|tr = '%1 öğesi için set kapsamı tanımlanmadı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorText,
			Parameters.ProductsInSet,
			Parameters.ItemVariantOfSet);
		CommonClientServer.MessageToUser(ErrorText);
		Return SelectedGoods;
	EndIf;
	
	Components = SetsServer.CreateSetCompositionTable(DialColumns());
	Components.Columns.Add("ItemsType", New TypeDescription("EnumRef.ItemsTypes"));
	Components.Columns.Add("ProductKind", New TypeDescription("CatalogRef.ItemKinds"));
	Components.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Components.Columns.Add("PackagingFactor", New TypeDescription("Number"));
	Components.Columns.Add("SKU", New TypeDescription("String",, New StringQualifiers(50)));
	
	SetPricingOption = Common.ObjectAttributeValue(ItemKitConfiguration, "SetPricingOption");
	
	Query = New Query();
	Texts = New Array();
	QueryText =
		"SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic) IN(
		|			SELECT
		|				ConfigurationOptionsForProductRange.Products AS Products,
		|				ConfigurationOptionsForProductRange.Characteristic AS Characteristic
		|			FROM
		|				Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
		|			WHERE
		|				ConfigurationOptionsForProductRange.Ref = &Ref)
		|		AND &FilterWarehouses_
		|		AND &FilterAssignment) AS Inventories
		|;
		|
		|////////////////////////////////////////////////////////
		|SELECT
		|	Calculation.Products AS Products,
		|	Calculation.Characteristic AS Characteristic,
		|	SUM(
		|		CASE
		|			WHEN Calculation.Purpose = &Purpose
		|				THEN Calculation.QuantityForShipAction
		|			ELSE 0
		|		END) AS AvailableForInventoryAllocation,
		|	SUM(Calculation.QuantityInStock) AS InStock
		|INTO Available2Balance
		|FROM
		|	CalculationOfBalancesForSettingActions AS Calculation
		|GROUP BY
		|	Calculation.Products,
		|	Calculation.Characteristic
		|INDEX BY
		|	Products, Characteristic";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
	Texts.Add(QueryText);
	QueryText =
		"SELECT
		|	ConfigurationOptionsForProductRange.LineNumber AS LineNumber,
		|	ConfigurationOptionsForProductRange.Products AS Products,
		|	ConfigurationOptionsForProductRange.Products.ItemsType AS ItemsType,
		|	ConfigurationOptionsForProductRange.Products.UnitOfMeasure AS UnitOfMeasure,
		|	ConfigurationOptionsForProductRange.Products.ProductKind AS ProductKind,
		|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
		|	ConfigurationOptionsForProductRange.Package AS Package,
		|	ConfigurationOptionsForProductRange.NumberOfPackages AS NumberOfPackages,
		|	ConfigurationOptionsForProductRange.Count AS Count,
		|	ConfigurationOptionsForProductRange.CostShare AS CostShare,
		|	SUM(ISNULL(AvailabilityOfGoods.InStock, 0) / ISNULL(&QueryTextPackagingFactor, 1)) AS InStock,
		|	SUM(ISNULL(AvailabilityOfGoods.AvailableForInventoryAllocation, 0) / ISNULL(&QueryTextPackagingFactor, 1)) AS Available,
		|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor
		|FROM
		|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
		|		LEFT JOIN Available2Balance AS AvailabilityOfGoods
		|		ON AvailabilityOfGoods.Products = ConfigurationOptionsForProductRange.Products
		|			AND AvailabilityOfGoods.Characteristic = ConfigurationOptionsForProductRange.Characteristic
		|WHERE
		|	ConfigurationOptionsForProductRange.Ref = &Ref
		|
		|GROUP BY
		|	ConfigurationOptionsForProductRange.Characteristic,
		|	ConfigurationOptionsForProductRange.Package,
		|	ConfigurationOptionsForProductRange.Products,
		|	ConfigurationOptionsForProductRange.LineNumber,
		|	ConfigurationOptionsForProductRange.Products.ItemsType,
		|	ConfigurationOptionsForProductRange.Products.UnitOfMeasure,
		|	ConfigurationOptionsForProductRange.Products.ProductKind,
		|	ConfigurationOptionsForProductRange.NumberOfPackages,
		|	ConfigurationOptionsForProductRange.Count,
		|	ConfigurationOptionsForProductRange.CostShare
		|
		|ORDER BY
		|	LineNumber";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"CAST(ConfigurationOptionsForProductRange.Package AS Catalog.PackagesAndUnitsOfMeasure)",
		"CAST(ConfigurationOptionsForProductRange.Products AS Catalog.Products)"));
	Texts.Add(QueryText);
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Ref",  ItemKitConfiguration);
	If AdditionalParameters.Property("Purpose") And ValueIsFilled(AdditionalParameters.Purpose) Then
		// According to the transferred assignment, we get Balances available only for this purpose and available Balances too.
		Query.SetParameter("Purpose", AdditionalParameters.Purpose);
		Query.Text = StrReplace(Query.Text, "&FilterAssignment", "Purpose = &Purpose");
	Else
		// If a specific assignment is not passed, we get available for all assignments and available Balances for an empty assignment.
		Query.SetParameter("Purpose", Catalogs.Assignments.EmptyRef());
		Query.Text = StrReplace(Query.Text, "&FilterAssignment", "TRUE");
	EndIf;
	
	If AdditionalParameters.Property("Warehouses") Then
		Query.Text = StrReplace(Query.Text, "&FilterWarehouses_", "Warehouse IN (&Warehouses)");
		Query.SetParameter("Warehouses",  AdditionalParameters.Warehouses);
	Else
		Query.Text = StrReplace(Query.Text, "&FilterWarehouses_", "TRUE");
	EndIf;

	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		NewRow = Components.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.ProductsInSet   = Parameters.ProductsInSet;
		NewRow.ItemVariantOfSet = Parameters.ItemVariantOfSet;
		
	EndDo;
	
	If SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices Then
		
		If AdditionalParameters.Property("PriceKind") And ValueIsFilled(AdditionalParameters.PriceKind) Then
			
			FillParameters = New Structure;
			FillParameters.Insert("Date", AdditionalParameters.Date);
			FillParameters.Insert("Currency", AdditionalParameters.Currency);
			FillParameters.Insert("PriceKind", AdditionalParameters.PriceKind);
			FillParameters.Insert("CalculateSets", True);
			FillParameters.Insert("PopulationFields", "Price, PriceKind");
			
			If AdditionalParameters.Property("Organization") And ValueIsFilled(AdditionalParameters.Organization) Then
				FillParameters.Insert("Organization", AdditionalParameters.Organization);
			EndIf;
			
			PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
				Components,
				Undefined, // Array of rows or selection structure.
				FillParameters);
		ElsIf AdditionalParameters.Property("Terms") And ValueIsFilled(AdditionalParameters.Terms) Then
			
			FillParameters = New Structure;
			FillParameters.Insert("Date", AdditionalParameters.Date);
			FillParameters.Insert("Currency", AdditionalParameters.Currency);
			FillParameters.Insert("Terms", AdditionalParameters.Terms);
			FillParameters.Insert("CalculateSets", True);
			FillParameters.Insert("PopulationFields", "Price, PriceKind");
			
			If AdditionalParameters.Property("Organization") And ValueIsFilled(AdditionalParameters.Organization) Then
				FillParameters.Insert("Organization", AdditionalParameters.Organization);
			EndIf;
			
			PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
				Components,
				Undefined, // Array of rows or selection structure.
				FillParameters);
		EndIf;
		
		For Each TSRow In Components Do
			
			ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
			FillPropertyValues(ProductParameters_1, Parameters);
			
			ProductParameters_1.SKU            = TSRow.SKU;
			ProductParameters_1.Products       = TSRow.Products;
			ProductParameters_1.Characteristic     = TSRow.Characteristic;
			ProductParameters_1.Package           = TSRow.Package;
			ProductParameters_1.ItemsType    = TSRow.ItemsType;
			ProductParameters_1.ProductKind    = TSRow.ProductKind;
			ProductParameters_1.UnitOfMeasure   = TSRow.UnitOfMeasure;
			ProductParameters_1.PriceKind            = TSRow.PriceKind;
			ProductParameters_1.Price               = TSRow.Price;
			ProductParameters_1.NumberOfPackages = TSRow.NumberOfPackages * Parameters.NumberOfPackages;
			ProductParameters_1.Count         = TSRow.Count * Parameters.NumberOfPackages;
			ProductParameters_1.Available           = TSRow.Available;
			ProductParameters_1.InStock           = TSRow.InStock;
			ProductParameters_1.PackagingFactor = TSRow.PackagingFactor;
			
			If ProductParameters_1.ItemsType = Enums.ItemsTypes.OperationService
				Or ProductParameters_1.ItemsType = Enums.ItemsTypes.Work_5 Then
				ProductParameters_1.Warehouse = Catalogs.Warehouses.EmptyRef();
			EndIf;
			
			ProductParameters_1.ItemVariantsAreUsed = ?(ValueIsFilled(ProductParameters_1.Characteristic), True, False);
			
			SelectedGoods.Add(ProductParameters_1);
			
		EndDo;
		
	Else
		
		If GetFunctionalOption("ToUseTermsOfSales")
			And AdditionalParameters.Property("Terms")
			And ValueIsFilled(AdditionalParameters.Terms) Then
			
			CalculationParameters = New Structure;
			CalculationParameters.Insert("Date", AdditionalParameters.Date);
			CalculationParameters.Insert("Currency", AdditionalParameters.Currency);
			CalculationParameters.Insert("Terms", AdditionalParameters.Terms);
			CalculationParameters.Insert("PopulationFields", "Price");
			
		Else
			
			CalculationParameters = New Structure;
			CalculationParameters.Insert("Date", AdditionalParameters.Date);
			CalculationParameters.Insert("Currency", AdditionalParameters.Currency);
			CalculationParameters.Insert("PriceKind", AdditionalParameters.PriceKind);
			CalculationParameters.Insert("PopulationFields", "Price");
			
		EndIf;
		
		CoefficientsOfProportionalityOfCalculationOfPricesOfSets = SetsServer.DistributionCoefficients(
			Components.Copy(), CalculationParameters);
		
		TotalCost = 0;
		For Each CurrentRow In CoefficientsOfProportionalityOfCalculationOfPricesOfSets Do
			TotalCost = TotalCost + CurrentRow.Price;
		EndDo;

		AmountForAllocation = AdditionalParameters.Price * Parameters.NumberOfPackages;
		
		ServiceTS = New ValueTable;
		ServiceTS.Columns.Add("TSRow");
		ServiceTS.Columns.Add("LineNumber");
		
		Components.Sort("NumberOfPackages Desc");
		For Each CurrentRow In Components Do
			
			Cost = CoefficientsOfProportionalityOfCalculationOfPricesOfSets.Find(CurrentRow.LineNumber, "LineNumber").Price;
			
			ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
			FillPropertyValues(ProductParameters_1, Parameters);
			
			ProductParameters_1.Products       = CurrentRow.Products;
			ProductParameters_1.Characteristic     = CurrentRow.Characteristic;
			ProductParameters_1.Package           = CurrentRow.Package;
			ProductParameters_1.ItemsType    = CurrentRow.ItemsType;
			ProductParameters_1.ProductKind    = CurrentRow.ProductKind;
			ProductParameters_1.UnitOfMeasure   = CurrentRow.UnitOfMeasure;
			ProductParameters_1.NumberOfPackages = CurrentRow.NumberOfPackages * Parameters.NumberOfPackages;
			ProductParameters_1.Count         = CurrentRow.Count * Parameters.NumberOfPackages;
			ProductParameters_1.PackagingFactor = CurrentRow.PackagingFactor;
			
			If ProductParameters_1.ItemsType = Enums.ItemsTypes.OperationService
				Or ProductParameters_1.ItemsType = Enums.ItemsTypes.Work_5 Then
				ProductParameters_1.Warehouse = Catalogs.Warehouses.EmptyRef();
			EndIf;
			
			If AdditionalParameters.Property("PriceKind") Then
				ProductParameters_1.PriceKind = AdditionalParameters.PriceKind;
			Else
				ProductParameters_1.PriceKind = Catalogs.TypesOfPrices.EmptyRef();
			EndIf;
			
			If ProductParameters_1.NumberOfPackages <> 0 And TotalCost <> 0 Then
				ProductParameters_1.Price = Round(((Cost / TotalCost) * AmountForAllocation) / ProductParameters_1.NumberOfPackages, 2);
			Else
				ProductParameters_1.Price = 0;
			EndIf;
			
			TotalCost = TotalCost - Cost;
			AmountForAllocation = AmountForAllocation - ProductParameters_1.Price * ProductParameters_1.NumberOfPackages;
			
			ProductParameters_1.Available = CurrentRow.Available;
			ProductParameters_1.InStock = CurrentRow.InStock;
			
			ProductParameters_1.ItemVariantsAreUsed = ?(ValueIsFilled(ProductParameters_1.Characteristic), True, False);
			
			ServiceLine = ServiceTS.Add();
			ServiceLine.TSRow = ProductParameters_1;
			ServiceLine.LineNumber = CurrentRow.LineNumber;
			
		EndDo;
		
		If AmountForAllocation <> 0 And ServiceTS.Count() > 0 Then
			
			LastRow = ServiceTS[ServiceTS.Count() - 1];
			InitialString = LastRow.TSRow;
			
			If InitialString.NumberOfPackages > 1 Then
				NewRow = SelectGoodsClientServer.ProductParameters_1();
				FillPropertyValues(NewRow, InitialString);
				
				InitialString.NumberOfPackages = InitialString.NumberOfPackages - 1;
				NewRow.NumberOfPackages = 1;
				NewRow.Price = NewRow.Price + AmountForAllocation;
				
				ServiceLine = ServiceTS.Add();
				ServiceLine.TSRow = NewRow;
				ServiceLine.LineNumber = LastRow.LineNumber;
				
			Else
				
				InitialString.Error_ = AmountForAllocation;
				
			EndIf;
			
		EndIf;
		
		ServiceTS.Sort("LineNumber Asc");
		For Each TSRow In ServiceTS Do
			SelectedGoods.Add(TSRow.TSRow);
		EndDo;
		
	EndIf;
	
	Return SelectedGoods;

EndFunction

// The procedure supplements the array of rows in the table part with the remaining rows of sets,
// if the specified sets are not fully represented in the array of rows.
// 
// Parameters:
//  TabularSection - TabularSection - The tabular part.
//  RowsArray - Array - Rows in the table part for the extension.
//  ConsiderLineCode - Boolean - Indicates whether the line code is accounted for.
//
Procedure AddToFullSet(TabularSection, RowsArray, ConsiderLineCode = False) Export
	
	If Not ValueIsFilled(TabularSection) Or Not ValueIsFilled(RowsArray)
		Or Not TMCommonUseClientServer.HasObjectAttribute(TabularSection[0], "ProductsInSet") Then
		Return;
	EndIf;
	
	TableOfProducts = New ValueTable;
	TableOfProducts.Columns.Add("ProductsInSet", New TypeDescription("CatalogRef.Products"));
	TableOfProducts.Columns.Add("ItemVariantOfSet", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	For Each TSRow In RowsArray Do
		If ValueIsFilled(TSRow.ProductsInSet) Then
			NewRow = TableOfProducts.Add();
			NewRow.ProductsInSet = TSRow.ProductsInSet;
			NewRow.ItemVariantOfSet = TSRow.ItemVariantOfSet;
		EndIf;
	EndDo;
	TableOfProducts.GroupBy("ProductsInSet,ItemVariantOfSet");
	
	If Not ValueIsFilled(TableOfProducts) Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	T.ProductsInSet,
	|	T.ItemVariantOfSet
	|INTO Table
	|FROM
	|	&Table AS T
	|;
	|SELECT
	|	T.ProductsInSet,
	|	T.ItemVariantOfSet,
	|	ProductKitConfigurations.SetPricingOption
	|FROM
	|	Table AS T
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = T.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = T.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|");
	
	Query.SetParameter("Table", TableOfProducts);
	
	Data = Query.Execute().Unload();
	
	LinesToAdd = New Array;
	For Each TSRow In RowsArray Do
		
		If ValueIsFilled(TSRow.ProductsInSet) Then
			
			Filter = New Structure;
			Filter.Insert("ProductsInSet", TSRow.ProductsInSet);
			Filter.Insert("ItemVariantOfSet", TSRow.ItemVariantOfSet);
			
			FoundRows = Data.FindRows(Filter);
			If FoundRows.Count() > 0 Then
				If FoundRows[0].SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares
					Or FoundRows[0].SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices Then
					FoundRowsInTablePart = TabularSection.FindRows(Filter);
					For Each FoundRow In FoundRowsInTablePart Do
						
						If ConsiderLineCode And FoundRow.RowCode <> 0 Then
							Continue;
						EndIf;
						
						If RowsArray.Find(FoundRow) = Undefined Then
							 LinesToAdd.Add(FoundRow);
						EndIf;
						
					EndDo;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each TSRow In LinesToAdd Do
		RowsArray.Add(TSRow);
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Function DialColumns()
	
	Columns = New Array;
	Columns.Add("LineNumber");
	Columns.Add("ProductsInKit");
	Columns.Add("KitCharacteristic");
	Columns.Add("Products");
	Columns.Add("Characteristic");
	Columns.Add("Price");
	Columns.Add("PriceKind");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	Columns.Add("PercentRateOfManualDiscount");
	Columns.Add("ManualDiscount");
	Columns.Add("Available");
	Columns.Add("InStock");
	
	Return Columns;
	
EndFunction

#EndRegion
