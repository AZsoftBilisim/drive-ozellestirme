#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// It is intended for getting the query text of the temporary table "VT support Methods",
// which contains the main security method for the list of goods and warehouses.
//
// Parameters:
//  WarehouseFormats - String - if the value of the "CALCULATE" parameter is set, a temporary table "Vtformatskladov" will be created,
//                            otherwise it is assumed that this table already exists at the time of query execution.
//
// Returns:
//  String - the text of the request for a temporary support table".
//
Function TemporaryTableWaysToEnsure(WarehouseFormats) Export
	
	QueryText = "";
	If WarehouseFormats = "CALCULATE" Then
		
		QueryText = Catalogs.StoreFormats.QueryTextTTWarehouseFormats();
		
	EndIf;
	
	QueryText = QueryText +
	"SELECT ALLOWED DISTINCT
	|	ProductMatrix.Products   AS Products,
	|	ProductMatrix.Characteristic AS Characteristic,
	|	ProductMatrix.Warehouse          AS Warehouse,
	|	
	|	ISNULL(CatMethod.Ref, VALUE(Catalog.ProcurementStrategies.EmptyRef)) AS ProcurementStrategy,
	|	CASE ISNULL(CatMethod.SupplyType, VALUE(Enum.SupplyTypes.EmptyRef))
	|		WHEN VALUE(Enum.SupplyTypes.Production)
	|			THEN 1
	|		WHEN VALUE(Enum.SupplyTypes.AssemblyDisassembly)
	|			THEN 2
	|		WHEN VALUE(Enum.SupplyTypes.ProductionByThirdParty)
	|			THEN 3
	|		WHEN VALUE(Enum.SupplyTypes.Purchase)
	|			THEN 4
	|		WHEN VALUE(Enum.SupplyTypes.Move)
	|			THEN 5
	|		ELSE 9999
	|	END AS SecurityTypePriority,
	|	
	|	CASE WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
	|		
	|			CatProducts.ProcurementStrategy
	|			
	|		ELSE
	|			
	|			ISNULL(TableOfWarehouseSupportSchemes.ProcurementStrategy,
	|					ISNULL(TableOfTheFormatSupportScheme.ProcurementStrategy,
	|						VALUE(Catalog.ProcurementStrategies.EmptyRef)))
	|			
	|		END                      AS WayToEnsureNeedsIsInherited,
	|		
	|	CASE WHEN NOT TableOptionsForProvidingGoods.Products IS NULL OR NOT TableOptionsForProvidingWork.Products IS NULL THEN
	|				
	|				""ProductDescriptionWarehouse""
	|				
	|			WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
	|				
	|				""Products""
	|				
	|			ELSE
	|				
	|				""SupplyScheme""
	|				
	|		END AS SettingSource
	|	
	|INTO TTWaysToEnsure
	|FROM
	|	TTProducts_1 AS ProductMatrix
	|		
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = ProductMatrix.Products
	|		
	|		LEFT JOIN InformationRegister.WorksProcurementStrategy AS TableOptionsForProvidingWork
	|		ON CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND TableOptionsForProvidingWork.Products   = ProductMatrix.Products
	|		 AND TableOptionsForProvidingWork.Characteristic = ProductMatrix.Characteristic
	|		 AND TableOptionsForProvidingWork.AddlOrderingAttribute = 1
	|		
	|		LEFT JOIN InformationRegister.GoodsProcurementStrategy AS TableOptionsForProvidingGoods
	|		ON CatProducts.ItemsType IN(
	|			VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage),
	|			VALUE(Enum.ItemsTypes.Set))
	|		 AND TableOptionsForProvidingGoods.Products   = ProductMatrix.Products
	|		 AND TableOptionsForProvidingGoods.Characteristic = ProductMatrix.Characteristic
	|		 AND TableOptionsForProvidingGoods.Warehouse          = ProductMatrix.Warehouse
	|		 AND TableOptionsForProvidingGoods.AddlOrderingAttribute = 1
	|		
	|		LEFT JOIN TTWarehouseFormats AS TableWarehouseFormats
	|		ON TableWarehouseFormats.Warehouse = ProductMatrix.Warehouse
	|		
	|		LEFT JOIN InformationRegister.SupplySchemes AS TableOfWarehouseSupportSchemes
	|		ON TableOfWarehouseSupportSchemes.SupplyScheme = CatProducts.SupplyScheme
	|		 AND TableOfWarehouseSupportSchemes.Warehouse = ProductMatrix.Warehouse
	|		
	|		LEFT JOIN InformationRegister.SupplySchemes AS TableOfTheFormatSupportScheme
	|		ON TableOfTheFormatSupportScheme.SupplyScheme = CatProducts.SupplyScheme
	|		 AND TableOfTheFormatSupportScheme.Warehouse = TableWarehouseFormats.StoreFormat
	|		
	|		LEFT JOIN Catalog.ProcurementStrategies AS CatMethod
	|		ON CASE WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
	|						
	|						ISNULL(TableOptionsForProvidingWork.ProcurementStrategy,
	|							CatProducts.ProcurementStrategy)
	|						
	|					ELSE
	|						
	|						ISNULL(TableOptionsForProvidingGoods.ProcurementStrategy,
	|							ISNULL(TableOfWarehouseSupportSchemes.ProcurementStrategy,
	|								ISNULL(TableOfTheFormatSupportScheme.ProcurementStrategy,
	|									VALUE(Catalog.ProcurementStrategies.EmptyRef))))
	|						
	|				END = CatMethod.Ref
	|		
	|INDEX BY
	|	Products, Characteristic, Warehouse";
	
	Return QueryText;
	
EndFunction

// It is intended for getting the query text of the temporary table "Vtosobesposobespecheniya",
// which contains the main method of provision in all warehouses for the list of goods.
//
// Parameters:
//  SupplyType - EnumRef.SupplyTypes - if the value of the security type "Move" is set,
//                                                        the result will contain only goods and warehouses with the main
//                                                        security method by moving.
//  ThereIsTableOfWarehouseFormats - Boolean - true if the table has already been generated previously.
//
// Returns:
//  String - the text of the request for a temporary support table".
//
Function TemporaryTableWaysToSecureAllWarehouses(SupplyType = Undefined, ThereIsTableOfWarehouseFormats = False) Export
	
	QueryText = "";
	If Not ThereIsTableOfWarehouseFormats Then
		QueryText = Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False);
	EndIf;
	
	QueryText = QueryText +
		"SELECT ALLOWED
		|	Set.Products   AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse          AS Warehouse,
		|	Set.ProcurementStrategy AS ProcurementStrategy
		|INTO TTWaysToEnsure
		|FROM(
		|	SELECT
		|		ProductMatrix.Products   AS Products,
		|		ProductMatrix.Characteristic AS Characteristic,
		|		
		|		Setting.Warehouse                         AS Warehouse,
		|		Setting.ProcurementStrategy AS ProcurementStrategy
		|	FROM
		|		TTProducts_1 AS ProductMatrix
		|			
		|			LEFT JOIN InformationRegister.GoodsProcurementStrategy AS Setting
		|			ON Setting.Products   = ProductMatrix.Products
		|			 AND Setting.Characteristic = ProductMatrix.Characteristic
		|			 AND Setting.AddlOrderingAttribute = 1
		|	WHERE
		|		NOT Setting.Warehouse IS NULL
		|		AND &Filters
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ProductMatrix.Products   AS Products,
		|		ProductMatrix.Characteristic AS Characteristic,
		|		
		|		Setting.Warehouse                         AS Warehouse,
		|		Setting.ProcurementStrategy AS ProcurementStrategy
		|	FROM
		|		TTProducts_1 AS ProductMatrix
		|			
		|			LEFT JOIN InformationRegister.SupplySchemes AS Setting
		|			ON Setting.SupplyScheme = ProductMatrix.Products.SupplyScheme
		|			 AND Setting.Warehouse REFS Catalog.Warehouses
		|			
		|			LEFT JOIN InformationRegister.GoodsProcurementStrategy AS PreemptiveSetting
		|			ON PreemptiveSetting.Products   = ProductMatrix.Products
		|			 AND PreemptiveSetting.Characteristic = ProductMatrix.Characteristic
		|			 AND PreemptiveSetting.Warehouse          = Setting.Warehouse
		|			 AND PreemptiveSetting.AddlOrderingAttribute = 1
		|	WHERE
		|		NOT Setting.Warehouse IS NULL
		|		AND PreemptiveSetting.Warehouse IS NULL
		|		AND &Filters
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ProductMatrix.Products   AS Products,
		|		ProductMatrix.Characteristic AS Characteristic,
		|		
		|		FormatWarehouses.Warehouse                     AS Warehouse,
		|		Setting.ProcurementStrategy AS ProcurementStrategy
		|	FROM
		|		TTProducts_1 AS ProductMatrix
		|			
		|			LEFT JOIN InformationRegister.SupplySchemes AS Setting
		|			ON Setting.SupplyScheme = ProductMatrix.Products.SupplyScheme
		|			 AND Setting.Warehouse REFS Catalog.StoreFormats
		|			
		|			LEFT JOIN TTWarehouseFormats AS FormatWarehouses
		|			ON FormatWarehouses.StoreFormat = Setting.Warehouse
		|			
		|			LEFT JOIN InformationRegister.SupplySchemes AS PreemptiveCircuitTuning
		|			ON PreemptiveCircuitTuning.SupplyScheme = ProductMatrix.Products.SupplyScheme
		|			 AND PreemptiveCircuitTuning.Warehouse REFS Catalog.Warehouses
		|			 AND PreemptiveCircuitTuning.Warehouse = FormatWarehouses.Warehouse
		|			
		|			LEFT JOIN InformationRegister.GoodsProcurementStrategy AS PreemptiveSetting
		|			ON PreemptiveSetting.Products   = ProductMatrix.Products
		|			 AND PreemptiveSetting.Characteristic = ProductMatrix.Characteristic
		|			 AND PreemptiveSetting.Warehouse          = FormatWarehouses.Warehouse
		|			 AND PreemptiveSetting.AddlOrderingAttribute = 1
		|	WHERE
		|		NOT Setting.Warehouse IS NULL
		|		AND NOT FormatWarehouses.Warehouse IS NULL
		|		AND PreemptiveCircuitTuning.Warehouse IS NULL
		|		AND PreemptiveSetting.Warehouse IS NULL
		|		AND &Filters) AS Set
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|
		|////////////////////////////////////
		|";
	
	ReplaceSubstring = "";
	If SupplyType = Enums.SupplyTypes.Move Then
		
		ReplaceSubstring = "Setting.ProcurementStrategy.SupplyType = VALUE(Enum.SupplyTypes.Move)
			|		AND Setting.ProcurementStrategy.SourceOfDemandSupply REFS Catalog.Warehouses
			|		AND Setting.ProcurementStrategy.SourceOfDemandSupply <> VALUE(Catalog.Warehouses.EmptyRef)";
		
	EndIf;
	QueryText = StrReplace(QueryText, "&Filters", ReplaceSubstring);
	Return QueryText;
	
EndFunction

// Inserts in the request text the connections required to get the main method of providing goods in the warehouse or
// work.
//
// Parameters:
//  QueryText	 - String - the query text in which to substitute the connection
//  ParameterName	 - String - name of the parameter to replace the connection with
//  ConnectionFields	 - String - connection fields in the format [leading Table].Nomenclature, [Leading Table].Characteristic, [Leading Table].Warehouse.
//  Postfix         - String - unique text for internal table synonyms.
// 
// Returns:
//  String - new query test
//
Function SubstituteConnectionToGetSecurityMethod(QueryText, ParameterName, ConnectionFields = Undefined, Postfix = "") Export
	
	SubstitutionResult = QueryText;
	While True Do
		
		ParameterStart = StrFind(SubstitutionResult, ParameterName, SearchDirection.FromBegin);
		
		If ParameterStart = 0 Then
			Break;
		EndIf;
		
		LastChar = ParameterStart + StrLen(ParameterName);
		BeginningOfSynonym = StrFind(SubstitutionResult, "AS", SearchDirection.FromEnd, ParameterStart) + StrLen("AS");
		Synonym = TrimAll(StrReplace(Mid(SubstitutionResult, BeginningOfSynonym, ParameterStart - BeginningOfSynonym - 1), "ON", ""));
		FirstSymbol = StrFind(SubstitutionResult, "JOIN", SearchDirection.FromEnd, BeginningOfSynonym) + StrLen("JOIN");
		
		SearchSubstring = Mid(SubstitutionResult, FirstSymbol, LastChar - FirstSymbol);
		ReplaceSubstring =
			"		InformationRegister.WorksProcurementStrategy AS TableOptionsForProvidingWorkOverridable
			|		On T.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
			|		 AND TableOptionsForProvidingWorkOverridable.Products   = T.Products
			|		 AND TableOptionsForProvidingWorkOverridable.Characteristic = T.Characteristic
			|		 AND TableOptionsForProvidingWorkOverridable.AddlOrderingAttribute = 1
			|		
			|		LEFT JOIN InformationRegister.GoodsProcurementStrategy AS TableOptionsForProvidingGoodsOverridable
			|		ON T.Products.ItemsType IN(
			|			VALUE(Enum.ItemsTypes.OwnGoods),
			|			VALUE(Enum.ItemsTypes.ReusablePackage),
			|			VALUE(Enum.ItemsTypes.Set))
			|		 AND TableOptionsForProvidingGoodsOverridable.Products   = T.Products
			|		 AND TableOptionsForProvidingGoodsOverridable.Characteristic = T.Characteristic
			|		 AND TableOptionsForProvidingGoodsOverridable.Warehouse          = T.Warehouse
			|		 AND TableOptionsForProvidingGoodsOverridable.AddlOrderingAttribute = 1
			|		
			|		LEFT JOIN TTWarehouseFormats AS TableWarehouseFormatsOverridable
			|		ON TableWarehouseFormatsOverridable.Warehouse = T.Warehouse
			|		 AND TableOptionsForProvidingGoodsOverridable.Products IS NULL
			|		
			|		LEFT JOIN InformationRegister.SupplySchemes AS TableOfWarehouseSupportSchemesOverridable
			|		ON TableOfWarehouseSupportSchemesOverridable.SupplyScheme = T.Products.SupplyScheme
			|		 AND TableOfWarehouseSupportSchemesOverridable.Warehouse = T.Warehouse
			|		 AND TableOptionsForProvidingGoodsOverridable.Products IS NULL
			|		
			|		LEFT JOIN InformationRegister.SupplySchemes AS TableOfTheFormatSupportSchemeOverridable
			|		ON TableOfTheFormatSupportSchemeOverridable.SupplyScheme = T.Products.SupplyScheme
			|		 AND TableOfTheFormatSupportSchemeOverridable.Warehouse = TableWarehouseFormatsOverridable.StoreFormat
			|		 AND TableOfWarehouseSupportSchemesOverridable.SupplyScheme IS NULL
			|		 AND TableOptionsForProvidingGoodsOverridable.Products IS NULL
			|		
			|		LEFT JOIN Catalog.ProcurementStrategies AS CatMethod
			|		ON CASE WHEN T.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
			|						
			|						ISNULL(TableOptionsForProvidingWorkOverridable.ProcurementStrategy,
			|							T.Products.ProcurementStrategy)
			|						
			|					ELSE
			|						
			|						ISNULL(TableOptionsForProvidingGoodsOverridable.ProcurementStrategy,
			|							ISNULL(TableOfWarehouseSupportSchemesOverridable.ProcurementStrategy,
			|								ISNULL(TableOfTheFormatSupportSchemeOverridable.ProcurementStrategy,
			|									VALUE(Catalog.ProcurementStrategies.EmptyRef))))
			|						
			|				END = CatMethod.Ref";
			
		ReplaceSubstring = StrReplace(ReplaceSubstring, "CatMethod", Synonym);
		If ConnectionFields <> Undefined Then
			SubstringsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ConnectionFields);
			ReplaceSubstring = StrReplace(ReplaceSubstring, "T.Products",   SubstringsArray[0]);
			ReplaceSubstring = StrReplace(ReplaceSubstring, "T.Characteristic", SubstringsArray[1]);
			ReplaceSubstring = StrReplace(ReplaceSubstring, "T.Warehouse",          SubstringsArray[2]);
		EndIf;
		
		ReplaceSubstring = StrReplace(ReplaceSubstring, "TableOptionsForProvidingWorkOverridable", "TableOptionsForProvidingWork" + Postfix);
		ReplaceSubstring = StrReplace(ReplaceSubstring, "TableOptionsForProvidingGoodsOverridable", "TableOptionsForProvidingGoods" + Postfix);
		ReplaceSubstring = StrReplace(ReplaceSubstring, "TableWarehouseFormatsOverridable", "TableWarehouseFormats" + Postfix);
		ReplaceSubstring = StrReplace(ReplaceSubstring, "TableOfWarehouseSupportSchemesOverridable", "TableOfWarehouseSupportSchemes" + Postfix);
		ReplaceSubstring = StrReplace(ReplaceSubstring, "TableOfTheFormatSupportSchemeOverridable", "TableOfTheFormatSupportScheme" + Postfix);
		
		SubstitutionResult = StrReplace(SubstitutionResult, SearchSubstring, ReplaceSubstring);
		
	EndDo;
	
	Return SubstitutionResult;
	
EndFunction

// Defines the topology of warehouses for the transferred keys. The list of centers from which goods are moved to remote warehouses.
//  The result is saved to a temporary layout table with the fields:
//   Nomenclature - Reference link.Nomenclature - product nomenclature,
//   Feature - Reference link.Nomenclature characteristics - product characteristics,
//   Center - Directory link.Warehouses - a warehouse from which goods are moved to other warehouses,
//   Warehouse - Reference link.Warehouses - the warehouse to which goods are moved from the center, as well as the center of the distribution network itself.
// Parameters:
//  Query - Query - the query in the temporary tables of which you want to put the result
//  NameOfProductsTable - String - name of a temporary table containing a set of unique keys:
//                     * Products   - CatalogRef.Products - Range of goods,
//                     * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of goods,
//
Procedure TemporaryTableWarehouseTopology(Query, NameOfProductsTable) Export
	
	Text = TemporaryTableWaysToSecureAllWarehouses(Enums.SupplyTypes.Move, True);
	Text = StrReplace(Text, "TTProducts_1", NameOfProductsTable);
	
	QueryTexts = New Array();
	QueryTexts.Add(Text);
	
	Text =
		"SELECT ALLOWED
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS DestinationWarehouse,
		|	CAST(Table.ProcurementStrategy AS Catalog.ProcurementStrategies).SourceOfDemandSupply AS SourceWarehouse
		|INTO TopologyIsTemporary
		|FROM
		|	TTWaysToEnsure AS Table
		|WHERE
		|	Table.Warehouse <> CAST(Table.ProcurementStrategy AS Catalog.ProcurementStrategies).SourceOfDemandSupply
		|INDEX BY
		|	Products, Characteristic
		|;
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.DestinationWarehouse AS DestinationWarehouse,
		|	Table.SourceWarehouse AS SourceWarehouse,
		|	FALSE AS Processed
		|FROM
		|	TopologyIsTemporary AS Table
		|ORDER BY
		|	Products, Characteristic
		|;
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	COUNT(*) AS TotalRecords
		|FROM
		|	TopologyIsTemporary AS Table
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic
		|ORDER BY
		|	Products, Characteristic
		|;
		|DROP TTWaysToEnsure";
		
	QueryTexts.Add(Text);
	Query.Text = StrConcat(QueryTexts);
	QueryResults = Query.ExecuteBatch();
	Table = QueryResults[QueryResults.UBound() - 2].Unload();
	Table.Indexes.Add("Products,Characteristic,DestinationWarehouse");
	TableOfGoods = QueryResults[QueryResults.UBound() - 1].Unload();
	SubordinateWarehouses = Table.CopyColumns();
	
	Filter = New Structure("Products,Characteristic,DestinationWarehouse");
	IndexLast = -1;
	For IndexProductItem = 0 To TableOfGoods.Count() - 1 Do
		
		OwnGoods = TableOfGoods[IndexProductItem];
		FillPropertyValues(Filter, OwnGoods);
		IndexOne = IndexLast + 1;
		IndexLast = IndexOne + OwnGoods.TotalRecords - 1;
		
		ProcessingCompleted = False;
		While Not ProcessingCompleted Do
			
			ProcessingCompleted = True;
			
			For CurrentIndex = IndexOne To IndexLast Do
				
				TableRow = Table[CurrentIndex];
				If TableRow.Processed Then
					Continue;
				EndIf;
				TableRow.Processed = True;
				NewRow = SubordinateWarehouses.Add();
				FillPropertyValues(NewRow, TableRow);
				Filter.DestinationWarehouse = TableRow.SourceWarehouse;
				FoundRows = Table.FindRows(Filter);
				If FoundRows.Count() > 0 Then
					
						CenterIsAboveLevel = FoundRows[0].SourceWarehouse;
						If TableRow.DestinationWarehouse = CenterIsAboveLevel Then // protection against looping
							Continue;
						EndIf;
						
						ProcessingCompleted = False;
						TableRow.Processed = False;
						TableRow.SourceWarehouse = CenterIsAboveLevel;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	Query.SetParameter("SubordinateWarehouses", SubordinateWarehouses);
	Query.Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.SourceWarehouse AS SourceWarehouse,
		|	Table.DestinationWarehouse AS DestinationWarehouse
		|INTO SubordinateWarehouses
		|FROM
		|	&SubordinateWarehouses AS Table
		|;
		|SELECT
		|	SubordinateWarehouses.Products AS Products,
		|	SubordinateWarehouses.Characteristic AS Characteristic,
		|	SubordinateWarehouses.DestinationWarehouse AS Warehouse,
		|	SubordinateWarehouses.SourceWarehouse AS Center
		|INTO WarehouseTopology
		|FROM
		|	SubordinateWarehouses AS SubordinateWarehouses
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.SourceWarehouse AS Warehouse,
		|	Table.SourceWarehouse AS Center
		|FROM
		|	TopologyIsTemporary AS Table
		|INDEX BY
		|	Products, Characteristic, Warehouse, Center
		|;
		|DROP SubordinateWarehouses
		|;
		|DROP TopologyIsTemporary";
	Query.Execute();
	Query.SetParameter("SubordinateWarehouses", Undefined); // clearing the table
	
EndProcedure

// Complements transmitted to the key table. For warehouse, distribution center network
// adds all the warehouses of the network according to topologii warehouses.
//
// Parameters:
//  NameOfProductsTable - String - the name of the temporary table containing the keys Item, Characteristic,Warehouse (uniqueness is not required)
//  DrillDownToAppointments - Boolean - indicates that the table has an assignment.
//
// Returns:
//  String - The query text of the temporary table query "Various product accounts" with unique keys:
//           * Products   - CatalogRef.Products - Range of goods,
//           * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of goods,
//           * Purpose     - CatalogRef.Assignments - purpose of the product, or Undefined,
//           * Warehouse          - CatalogRef.Warehouses - warehouse.
//
Function TemporaryTableOfVariousGoodsAndWarehouses(NameOfProductsTable, DrillDownToAppointments) Export
	
	Text =
		"SELECT DISTINCT
		|	Goods.Products    AS Products,
		|	Goods.Characteristic  AS Characteristic,
		|	Goods.Warehouse           AS Warehouse,
		|	&SubstitutionAssignment AS Purpose
		|INTO VariousGoodsAndWarehouses
		|FROM
		|	TableNameOverridable AS Goods
		|
		|UNION
		|
		|SELECT DISTINCT
		|	Goods.Products    AS Products,
		|	Goods.Characteristic  AS Characteristic,
		|	Topology.Warehouse        AS Warehouse,
		|	&SubstitutionAssignment AS Purpose
		|FROM
		|	TableNameOverridable AS Goods
		|		
		|		LEFT JOIN WarehouseTopology AS Topology
		|		ON Topology.Products   =  Goods.Products
		|		 AND Topology.Characteristic =  Goods.Characteristic
		|		 AND Topology.Center          =  Goods.Warehouse
		|WHERE
		|	NOT Topology.Products IS NULL
		|INDEX BY
		|	Products, Characteristic, Warehouse";
		
	Text = StrReplace(Text, "TableNameOverridable", NameOfProductsTable);
	TotalSubstitution = ?(DrillDownToAppointments, "Goods.Purpose", "UNDEFINED");
	Text = StrReplace(Text, "&SubstitutionAssignment", TotalSubstitution);
	
	Return Text;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Warehouse)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region Internal

Procedure Add(Warehouse, SupplyScheme, SupplyMethod) Export
	
	Set = InformationRegisters.SupplySchemes.CreateRecordSet();
	
	Set.Filter.SupplyScheme.Set(SupplyScheme);
	Set.Filter.Warehouse.Set(Warehouse);
	
	Record = Set.Add();
	Record.SupplyScheme = SupplyScheme;
	Record.Warehouse = Warehouse;
	
	Record.ProcurementStrategy = SupplyMethod;
	Set.Write();
	
EndProcedure

Procedure Delete(Warehouse, SupplyScheme) Export
	
	Set = InformationRegisters.SupplySchemes.CreateRecordSet();
	
	Set.Filter.SupplyScheme.Set(SupplyScheme);
	Set.Filter.Warehouse.Set(Warehouse);
	
	Set.Write();
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
