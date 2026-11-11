#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Other

Function DataLayoutSchemaTemplates() Export
	
	Templates = New Array;
	
	For Each Template In Metadata.DataProcessors.PlanningDataSources.Templates Do
		
		If Template.TemplateType <> Metadata.ObjectProperties.TemplateType.DataCompositionSchema Then
			
			Continue;
			
		EndIf;
		
		If Template.Name = "SalesOrders" And Not GetFunctionalOption("UseSalesOrders")
			Or Template.Name = "PurchaseOrders" And Not GetFunctionalOption("UsePurchaseOrders")
			Or Template.Name = "InventoryConsumptionOrders" And Not GetFunctionalOption("UseInventoryConsumptionOrders")
			Or Template.Name = "TransferOrdersShipment" And Not GetFunctionalOption("UseTransferOrders")
			Or Template.Name = "TransferOrdersGoodsReceipt" And Not GetFunctionalOption("UseTransferOrders")
			Or Template.Name = "AssemblyOrdersIsuue" And Not GetFunctionalOption("UseAssemblyDisassemblyOrders")
			Or Template.Name = "AssemblyOrdersReceipt" And Not GetFunctionalOption("UseAssemblyDisassemblyOrders")
			Or Template.Name = "PurchasePlansPredefined" And Not GetFunctionalOption("UsePurchasePlanning")
			Or Template.Name = "InventoryConsumptionPlansPredefined" And Not GetFunctionalOption("UsePlanningOfInventoryConsumption")
			Or Template.Name = "SalesPlansPredefined" And Not GetFunctionalOption("UseSalesPlans") 
			Or Template.Name = "SalesPlansComponentsPredefined" 
				And (Not GetFunctionalOption("UseSalesPlans") 
					Or Not GetFunctionalOption("UseAssemblyDisassembly"))
			Or Template.Name = "SalesComponentsPredefined" 
				And (Not GetFunctionalOption("UseSalesPlans") 
					Or Not GetFunctionalOption("UseAssemblyDisassembly"))
			Or Template.Name = "AssemblyPlansComponentsPredefined" And Not GetFunctionalOption("UseAssemblyDisassemblyPlanning")
			Or Template.Name = "AssemblyDisassemblyPlansKitsPredefined" And Not GetFunctionalOption("UseAssemblyDisassemblyPlanning")
			Or Template.Name = "SalesPlansByCategoriesPredefined" And Not GetFunctionalOption("UseSalesPlansByCategories")
			Or Template.Name = "SalesPlansByCategoriesBySalesSpeedPredefined" And Not GetFunctionalOption("UseSalesPlansByCategories")
			Or Template.Name = "AssemblyDisassemblyPredefined" And Not GetFunctionalOption("UseAssemblyDisassembly") Then
			
			Continue;
			
		EndIf;

		Templates.Add(New Structure("Name, Synonym, FullNameOfTemplateSource", Template.Name, Template.Synonym, "DataProcessor.PlanningDataSources"));
		
	EndDo;
	
	Return Templates;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// The procedure calls handlers for the result obtained from the layout
Procedure AfterFetchingData(ResultTable2, DataSourceParameters, UserSettings, AdditionalParameters, DataCompositionSettingsComposer) Export 
	
	DCSTemplateName = DataSourceParameters.PlanningDataSource.DCSTemplateName;
	If DCSTemplateName = "DataProcessor.PlanningDataSources.SalesPlansComponentsPredefined"
		Or DCSTemplateName = "DataProcessor.PlanningDataSources.SalesComponentsPredefined" Then
		
		DecipherByComponents(ResultTable2, DataCompositionSettingsComposer, AdditionalParameters);
		
	ElsIf DCSTemplateName = "DataProcessor.PlanningDataSources.SalesPlansByCategoriesPredefined" Then
		
		RecalculateQuantityByDistributionStandards(ResultTable2, DataCompositionSettingsComposer, AdditionalParameters, True);
		
	ElsIf DCSTemplateName = "DataProcessor.PlanningDataSources.SalesPlansByCategoriesBySalesSpeedPredefined" Then
		
		RecalculateQuantityByDistributionStandards(ResultTable2, DataCompositionSettingsComposer, AdditionalParameters, False);
		
	EndIf; 

EndProcedure

#Region TemplateDataProcessingProcedures

Procedure RecalculateQuantityByDistributionStandards(ResultTable2, DataCompositionSettingsComposer, AdditionalParameters, DistributeByProductRange)
	
	If ResultTable2.Columns.Find("Products") = Undefined Or ResultTable2.Columns.Find("Count") = Undefined Then
		Return;
	EndIf; 
	
	MetricFieldName = New Array;
	MetricFieldName.Add("Count");
	
	If ResultTable2.Columns.Find("Period") = Undefined Then
		
		PeriodColumn = ResultTable2.Columns.Add("Period", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
		ResultTable2.FillValues(AdditionalParameters.DataParameters.BeginOfPeriod, "Period");
		
		Documents.SalesPlansAllocationBaseByCategories.RecalculateIndicatorsByDistributionStandards(ResultTable2, MetricFieldName, DistributeByProductRange);
		
		ResultTable2.Columns.Delete(PeriodColumn);
		
	Else
		Documents.SalesPlansAllocationBaseByCategories.RecalculateIndicatorsByDistributionStandards(ResultTable2, MetricFieldName, DistributeByProductRange);
	EndIf;
	
EndProcedure

#Region _maketProcessing_SalesPlans_Components_

Procedure DecipherByComponents(ResultTable2, DataCompositionSettingsComposer, AdditionalParameters)

	AddRequiredConfigurationColumns(ResultTable2, DataCompositionSettingsComposer, AdditionalParameters);
	
	Explosion = ParameterValue("Explosion", DataCompositionSettingsComposer, False);
	
	CollectedGoods = CollectedGoods(ResultTable2);
	ResultTable2.Clear();
	
	DefaultBankingDetailsValues = New Structure;
	DefaultBankingDetailsValues.Insert("Price",  0);
	DefaultBankingDetailsValues.Insert("Sum", 0);
	
	AddProductComponents(
			ResultTable2, 
			CollectedGoods, 
			Explosion, 
			DefaultBankingDetailsValues);

EndProcedure

Function CollectedGoods(GoodsTable)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsTable.Warehouse            AS Warehouse,
	|	GoodsTable.Period           AS Period,
	|	CAST(GoodsTable.Products AS Catalog.Products) AS Products,
	|	GoodsTable.Characteristic   AS Characteristic,
	|	GoodsTable.Count       AS Count
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|
	|INDEX BY
	|	Warehouse,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|" + StrReplace(
			InformationRegisters.SupplySchemes.TemporaryTableWaysToEnsure("CALCULATE"),
			"TTProducts_1",
			"GoodsTable") + "
	|;
	|
	|////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsTable.Warehouse            AS Warehouse,
	|	GoodsTable.Period           AS Period,
	|	GoodsTable.Products     AS Products,
	|	GoodsTable.Characteristic   AS Characteristic,
	|	GoodsTable.Count       AS Count
	|FROM
	|	GoodsTable AS GoodsTable
	|		
	|		LEFT JOIN TTWaysToEnsure AS CatSupplyMethod
	|		ON GoodsTable.Warehouse = CatSupplyMethod.Warehouse
	|			AND GoodsTable.Products = CatSupplyMethod.Products
	|			AND GoodsTable.Characteristic = CatSupplyMethod.Characteristic
	|		
	|WHERE
	|	GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND CatSupplyMethod.ProcurementStrategy.SupplyType = VALUE(Enum.SupplyTypes.AssemblyDisassembly)";

	Query.SetParameter("GoodsTable", GoodsTable);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

Procedure AddRequiredConfigurationColumns(ResultTable2, DataCompositionSettingsComposer, AdditionalParameters)

	If ResultTable2.Columns.Find("Characteristic") = Undefined Then
		
		ColumnType = New TypeDescription("CatalogRef.ItemsCharacteristics");
		ResultTable2.Columns.Add("Characteristic", ColumnType);

	EndIf;
	
	If ResultTable2.Columns.Find("Count") = Undefined Then
		
		ColumnType = New TypeDescription("Number", New NumberQualifiers(15,3, AllowedSign.Nonnegative));
		ResultTable2.Columns.Add("Count", ColumnType);

	EndIf;
	
	If ResultTable2.Columns.Find("Period") = Undefined Then
		
		ResultTable2.Columns.Add("Period", New TypeDescription("Date"));
		ResultTable2.FillValues(CurrentSessionDate(), "Period");

	EndIf;
	
	If ResultTable2.Columns.Find("Warehouse") = Undefined Then
		
		ResultTable2.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
		
		If AdditionalParameters.DataParameters.Property("Warehouse") Then
			DefaultWarehouse = AdditionalParameters.DataParameters.Warehouse;
		Else
			DefaultWarehouse = Catalogs.Warehouses.EmptyRef();
		EndIf; 
		
		ResultTable2.FillValues(DefaultWarehouse, "Warehouse");

	EndIf;
	
	If ResultTable2.Columns.Find("ProductKit") = Undefined Then
		
		ResultTable2.Columns.Add("ProductKit", New TypeDescription("CatalogRef.ProductKitConfigurations"));

	EndIf;
	
EndProcedure

#EndRegion

#Region Getting_complexes_From_NSI


// Parameters:
// 	ResultTable2 - ValueTable -
// 	CollectedGoods - ValueTable - 
// 	Explosion - Boolean, Undefined - 
// 	DefaultBankingDetailsValues - Undefined, Structure - LongDesc:
// * Sum - Number -
// * Price - Number -
// 	FilterBySupplyType - Undefined - 
Procedure AddProductComponents(ResultTable2, CollectedGoods, Explosion = False, DefaultBankingDetailsValues = Undefined, FilterBySupplyType = Undefined)

	If CollectedGoods.Columns.Find("ProductKit") = Undefined Then
		CollectedGoods.Columns.Add("ProductKit", New TypeDescription("CatalogRef.ProductKitConfigurations"));
	EndIf;
	If CollectedGoods.Columns.Find("Warehouse") = Undefined Then
		CollectedGoods.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	EndIf;
	
	While CollectedGoods.Count() <> 0 Do
		
		ProductsAndAccessories = ProductsAndAccessories(CollectedGoods);
		
		CollectedGoods.Clear();
		
		TableComponents = ProductsAndAccessories.TableComponents;
		TableComponents.Indexes.Add("ProductProducts,ProductCharacteristics_,Warehouse,Period");
		
		GoodsTable = ProductsAndAccessories.GoodsTable;
		
		For Each RowGoods In GoodsTable Do
			
			// Let's find a configuration option
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("ProductProducts", RowGoods.Products);
			TheStructureOfTheSearch.Insert("ProductCharacteristics_", RowGoods.Characteristic);
			TheStructureOfTheSearch.Insert("Warehouse", RowGoods.Warehouse);
			TheStructureOfTheSearch.Insert("Period", RowGoods.Period);
			
			ListOfComponents = TableComponents.FindRows(TheStructureOfTheSearch);
			KitConfigurations = New Array;
			For Each StringComponents In ListOfComponents Do
				If KitConfigurations.Find(StringComponents.ProductKit) = Undefined Then
					If StringComponents.Main Then
						KitConfigurations.Clear();
						KitConfigurations.Add(StringComponents.ProductKit);
						Break;
					Else
						KitConfigurations.Add(StringComponents.ProductKit);
					EndIf;
				EndIf;
			EndDo;
			
			If KitConfigurations.Count() <> 1 Then
				// You can add accessories if the configuration option is the main or the only one
				Continue;
			EndIf;
			
			ProductKit = KitConfigurations[0];
			
			For Each StringComponents In ListOfComponents Do
				
				If StringComponents.ProductKit <> ProductKit Then
					Continue;
				EndIf;
				
				If FilterBySupplyType = Undefined Or StringComponents.SupplyType = FilterBySupplyType Then
					NewComponentLine = ResultTable2.Add();
					If DefaultBankingDetailsValues <> Undefined Then
						FillPropertyValues(NewComponentLine, DefaultBankingDetailsValues);
					EndIf;
					FillPropertyValues(NewComponentLine, StringComponents);
					NewComponentLine.ProductKit = ProductKit;
				EndIf;
				
				If StringComponents.SupplyType = Enums.SupplyTypes.AssemblyDisassembly Then
					LineNewSourceComponent = CollectedGoods.Add();
					FillPropertyValues(LineNewSourceComponent, StringComponents);
				EndIf; 
				
			EndDo; 
			
		EndDo;
		
		If Not Explosion Then
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure


// Parameters:
// 	GoodsTable - ValueTable -
// Returns:
// 	Structure - LongDesc:
// * GoodsTable - ValueTable -
// * TableComponents - ValueTable -
Function ProductsAndAccessories(GoodsTable)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsTable.Warehouse                 AS Warehouse,
	|	GoodsTable.Period                AS Period,
	|	CAST(GoodsTable.Products AS Catalog.Products) AS Products,
	|	GoodsTable.Characteristic        AS Characteristic,
	|	GoodsTable.ProductKit   AS ProductKit,
	|	GoodsTable.Count            AS Count
	|INTO TTProducts_1
	|FROM
	|	&GoodsTable AS GoodsTable
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	ProductKit
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|"
	+ Catalogs.StoreFormats.QueryTextTTWarehouseFormats() +
	// 2
	"
	|SELECT ALLOWED
	|	GoodsTable.Warehouse                           AS Warehouse,
	|	GoodsTable.Products                    AS ProductProducts,
	|	GoodsTable.Characteristic                  AS ProductCharacteristics_,
	|	GoodsTable.Period                          AS Period,
	|	ProductKitConfigurations.Ref       AS ProductKit,
	|	CASE
	|		WHEN GoodsTable.ProductKit <> VALUE(Catalog.ProductKitConfigurations.EmptyRef)
	|			THEN TRUE
	|		ELSE ProductKitConfigurations.Main
	|	END                                         AS Main,
	|	TableComponents.Products             AS Products,
	|	TableComponents.Characteristic           AS Characteristic,
	|	TableComponents.Products.ProductCategory AS ProductCategory,
	|	TableComponents.Products.SalesRank     AS SalesRank,
	|	TableComponents.Count 
	|		* GoodsTable.Count 
	|		/ ProductKitConfigurations.Count AS Count,
	|	ISNULL(CatSupplyMethod.SupplyType, 
	|		VALUE(Enum.SupplyTypes.EmptyRef)) AS SupplyType
	|FROM
	|	Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		INNER JOIN TTProducts_1 AS GoodsTable
	|		ON (GoodsTable.Products = ProductKitConfigurations.Owner)
	|			AND (GoodsTable.Characteristic = ProductKitConfigurations.Characteristic)
	|			AND (GoodsTable.ProductKit = VALUE(Catalog.ProductKitConfigurations.EmptyRef)
	|				OR GoodsTable.ProductKit = ProductKitConfigurations.Ref)
	|		INNER JOIN Catalog.ProductKitConfigurations.Goods AS TableComponents
	|		ON (TableComponents.Ref = ProductKitConfigurations.Ref)
	|		
	|		LEFT JOIN Catalog.ProcurementStrategies AS CatSupplyMethod
	|		ON &MainSupplyMethodSubstitution
	|
	|WHERE
	|	NOT ProductKitConfigurations.DeletionMark";

	Query.Text = InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
		Query.Text,
		"MainSupplyMethodSubstitution",
		"TableComponents.Products,TableComponents.Characteristic,GoodsTable.Warehouse");

	TableProductsCopy = GoodsTable.Copy();
	Query.SetParameter("GoodsTable", TableProductsCopy);
	
	Result = Query.Execute();

	Return New Structure("GoodsTable, TableComponents", 
							TableProductsCopy, Result.Unload());
	
EndFunction

#EndRegion

#EndRegion

#Region Other


// Returns the value of the data alignment settings parameter
// 
// Parameters:
// 	ParameterName - String - 
// 	DataCompositionSettingsComposer - DataCompositionSettingsComposer - 
// 	DefaultValue - Boolean, Undefined - 
// Returns:
// 	Undefined - arbitrary value
Function ParameterValue(ParameterName, DataCompositionSettingsComposer, DefaultValue = Undefined)

	ParameterValue = Undefined;
	UnravelParameter = DataCompositionSettingsComposer.Settings.DataParameters.Items.Find(ParameterName);
	If UnravelParameter <> Undefined Then
		Id = UnravelParameter.UserSettingID;
		SettingItem = DataCompositionSettingsComposer.UserSettings.Items.Find(Id);
		If SettingItem <> Undefined Then
			ParameterValue = SettingItem.Value;
		EndIf; 
	EndIf; 

	Return ?(ParameterValue = Undefined,DefaultValue, ParameterValue);
	
EndFunction

#EndRegion

#EndRegion

#EndIf
