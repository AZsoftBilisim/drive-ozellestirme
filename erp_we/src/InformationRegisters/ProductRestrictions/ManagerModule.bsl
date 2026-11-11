#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Inserts the connections required to get the inventory maintenance settings in the request text.
//
// Parameters:
//  QueryText	 - String - the query text in which to substitute the connection
//  ParameterName	 - String - name of the parameter to replace the connection with
//  ConnectionFields	 - String - connection fields in the format [leading Table].Nomenclature, [Leading Table].Characteristic, [Leading Table].Warehouse
//  TableAlias - String - Psvedonym of the table used in the query as a data source for getting
//                              product restrictions.
// 
// Returns:
//  String - new query test
//
Function SubstituteConnection(QueryText, ParameterName, ConnectionFields = Undefined, TableAlias = "ProductRestrictions") Export
	
	// If the original Query Text was obtained using the query schema, then the parameter should be enclosed in parentheses.
	QueryText = StrReplace(QueryText, "(&" + ParameterName + ")", "&" + ParameterName);
	
	SubstitutionResult = QueryText;
	While True Do
		
		ParameterStart = StrFind(SubstitutionResult, ParameterName, SearchDirection.FromBegin);
		
		If ParameterStart = 0 Then
			Break;
		EndIf;
		
		// Replacement of resources, measurements and details.
		Fields = Metadata.InformationRegisters.ProductRestrictions.Dimensions;
		SubstituteSelectionFieldExpressions(SubstitutionResult, Fields, TableAlias);
		Fields = Metadata.InformationRegisters.ProductRestrictions.Resources;
		SubstituteSelectionFieldExpressions(SubstitutionResult, Fields, TableAlias);
		Fields = Metadata.InformationRegisters.ProductRestrictions.Attributes;
		SubstituteSelectionFieldExpressions(SubstitutionResult, Fields, TableAlias);
		
		// Connection replacement.
		ParameterStart = StrFind(SubstitutionResult, ParameterName, SearchDirection.FromBegin);
		
		LastChar = ParameterStart + StrLen(ParameterName);
		BeginningOfSynonym = StrFind(SubstitutionResult, "AS", SearchDirection.FromEnd, ParameterStart) + StrLen("AS");
		FirstSymbol = StrFind(SubstitutionResult, "JOIN", SearchDirection.FromEnd, BeginningOfSynonym) + StrLen("JOIN");
		
		SearchSubstring = Mid(SubstitutionResult, FirstSymbol, LastChar - FirstSymbol);
		ReplaceSubstring =
			" InformationRegister.ProductRestrictions AS DetailedSetup
			|		On DetailedSetup.Products   = T.Products
			|		 AND DetailedSetup.Characteristic = T.Characteristic
			|		 AND DetailedSetup.Warehouse          = T.Warehouse
			|		 AND DetailedSetup.GroupingProductRestrictions    = VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
			|		 AND DetailedSetup.ThisIsAValidParameter
			|		
			|		LEFT JOIN InformationRegister.ProductRestrictions AS GroupAffiliation
			|		ON DetailedSetup.Warehouse IS NULL
			|		 AND GroupAffiliation.Products   = T.Products
			|		 AND GroupAffiliation.Characteristic = T.Characteristic
			|		 AND GroupAffiliation.Warehouse          = T.Warehouse
			|		 AND GroupAffiliation.GroupingProductRestrictions <> VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
			|		 AND GroupAffiliation.ThisIsAValidParameter
			|		
			|		LEFT JOIN InformationRegister.ProductRestrictions AS SettingUpAGrouping
			|		ON DetailedSetup.Warehouse IS NULL
			|		 AND SettingUpAGrouping.Products   = VALUE(Catalog.Products.EmptyRef)
			|		 AND SettingUpAGrouping.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		 AND SettingUpAGrouping.Warehouse          = VALUE(Catalog.Warehouses.EmptyRef)
			|		 AND SettingUpAGrouping.GroupingProductRestrictions    = GroupAffiliation.GroupingProductRestrictions
			|		 AND SettingUpAGrouping.ThisIsAValidParameter
			|		
			|		LEFT JOIN InformationRegister.ProductRestrictions AS GeneralSetting
			|		ON DetailedSetup.Warehouse IS NULL
			|		 AND GroupAffiliation.Warehouse IS NULL
			|		 AND T.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		 AND GeneralSetting.Products   = T.Products
			|		 AND GeneralSetting.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		 AND GeneralSetting.Warehouse          = T.Warehouse
			|		 AND GeneralSetting.GroupingProductRestrictions    = VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
			|		 AND GeneralSetting.ThisIsAValidParameter
			|		
			|		LEFT JOIN InformationRegister.ProductRestrictions AS BelongingToSharedSettingsGroup
			|		ON DetailedSetup.Warehouse IS NULL
			|		 AND GroupAffiliation.Warehouse IS NULL
			|		 AND GeneralSetting.Warehouse IS NULL
			|		 AND T.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		 AND BelongingToSharedSettingsGroup.Products   = T.Products
			|		 AND BelongingToSharedSettingsGroup.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		 AND BelongingToSharedSettingsGroup.Warehouse          = T.Warehouse
			|		 AND BelongingToSharedSettingsGroup.GroupingProductRestrictions    <> VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
			|		 AND BelongingToSharedSettingsGroup.ThisIsAValidParameter
			|		
			|		LEFT JOIN InformationRegister.ProductRestrictions AS ConfiguringGroupingOfGeneralSettings
			|		ON DetailedSetup.Warehouse IS NULL
			|		 AND GroupAffiliation.Warehouse IS NULL
			|		 AND GeneralSetting.Warehouse IS NULL
			|		 AND T.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		 AND ConfiguringGroupingOfGeneralSettings.Products   = VALUE(Catalog.Products.EmptyRef)
			|		 AND ConfiguringGroupingOfGeneralSettings.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		 AND ConfiguringGroupingOfGeneralSettings.Warehouse          = VALUE(Catalog.Warehouses.EmptyRef)
			|		 AND ConfiguringGroupingOfGeneralSettings.GroupingProductRestrictions    = BelongingToSharedSettingsGroup.GroupingProductRestrictions
			|		 AND ConfiguringGroupingOfGeneralSettings.ThisIsAValidParameter";
			
		If ConnectionFields <> Undefined Then
			SubstringsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ConnectionFields);
			ReplaceSubstring = StrReplace(ReplaceSubstring, "T.Products",   SubstringsArray[0]);
			ReplaceSubstring = StrReplace(ReplaceSubstring, "T.Characteristic", SubstringsArray[1]);
			ReplaceSubstring = StrReplace(ReplaceSubstring, "T.Warehouse",          SubstringsArray[2]);
		EndIf;
		
		SubstitutionResult = StrReplace(SubstitutionResult, SearchSubstring, ReplaceSubstring);
		
	EndDo;
	
	Return SubstitutionResult;
	
EndFunction

// Inserts the connections required to receive the order packaging in the request text
//
// Parameters:
//  QueryText	 - String - the query text in which to substitute the connection
//  ParameterName	 - String - name of the parameter to replace the connection with
//  ConnectionFields	 - String - connection fields in the format [leading Table].Nomenclature, [Leading Table].Characteristic, [Leading Table].Warehouse
//  TableAlias - String - Psvedonym of the table used in the query as a data source for getting
//                              product restrictions.
// 
// Returns:
//  String - new query test
//
Function SubstituteConnectionForOrderPackaging(QueryText, ParameterName, ConnectionFields = Undefined, TableAlias = "OrderPackaging") Export
	
	SubstitutionResult = QueryText;
	While True Do
		
		ParameterStart = StrFind(SubstitutionResult, ParameterName, SearchDirection.FromBegin);
		
		If ParameterStart = 0 Then
			Break;
		EndIf;
		
		// Replacing a resource.
		SearchSubstring = TableAlias + ".OrderPackage";
		ReplaceSubstring =
		"
		|CASE
		|	WHEN ISNULL(SupplierPrices.SupplierOrderPackaging,VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = 
		|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
		|			ISNULL(OrderDetailedPackages.OrderPackage, OrderPackagingGeneral.OrderPackage)
		|		ELSE
		|			SupplierPrices.SupplierOrderPackaging
		|	END";
		SubstitutionResult = StrReplace(SubstitutionResult, SearchSubstring, ReplaceSubstring);
		
		// Connection replacement.
		ParameterStart = StrFind(SubstitutionResult, ParameterName, SearchDirection.FromBegin);
		
		LastChar = ParameterStart + StrLen(ParameterName);
		BeginningOfSynonym = StrFind(SubstitutionResult, "AS", SearchDirection.FromEnd, ParameterStart) + StrLen("AS");
		FirstSymbol = StrFind(SubstitutionResult, "JOIN", SearchDirection.FromEnd, BeginningOfSynonym) + StrLen("JOIN");
		
		SearchSubstring = Mid(SubstitutionResult, FirstSymbol, LastChar - FirstSymbol);
		ReplaceSubstring =
			" InformationRegister.ProductRestrictions AS OrderDetailedPackages
			|		On OrderDetailedPackages.Products   = T.Products
			|		 AND OrderDetailedPackages.Characteristic = T.Characteristic
			|		 AND OrderDetailedPackages.Warehouse          = T.Warehouse
			|		 AND OrderDetailedPackages.OrderPackage <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|
			|		LEFT JOIN InformationRegister.ProductRestrictions AS OrderPackagingGeneral
			|		ON OrderDetailedPackages.Warehouse IS NULL
			|		 AND T.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		 AND OrderPackagingGeneral.Products   = T.Products
			|		 AND OrderPackagingGeneral.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		 AND OrderPackagingGeneral.Warehouse          = T.Warehouse";
			
		If ConnectionFields <> Undefined Then
			SubstringsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ConnectionFields);
			ReplaceSubstring = StrReplace(ReplaceSubstring, "T.Products",   SubstringsArray[0]);
			ReplaceSubstring = StrReplace(ReplaceSubstring, "T.Characteristic", SubstringsArray[1]);
			ReplaceSubstring = StrReplace(ReplaceSubstring, "T.Warehouse",          SubstringsArray[2]);
		EndIf;
		
		SubstitutionResult = StrReplace(SubstitutionResult, SearchSubstring, ReplaceSubstring);
		
	EndDo;
	
	Return SubstitutionResult;
	
EndFunction

// Inserts the connections required to get the settings for maintaining inventory in shop storerooms in the request text.
//
// Parameters:
//  QueryText	 - String - the query text in which to substitute the connection
//  ParameterName	 - String - name of the parameter to replace the connection with
//  ConnectionFields	 - String - connection fields in the format [leading Table].Nomenclature, [Leading Table].Characteristic, [Leading Table].Unit.
// 
// Returns:
//  String - new query test
//
Function SubstituteForMaintainingStocksInPantries(QueryText, ParameterName, ConnectionFields = Undefined) Export
	
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
			" InformationRegister.ProductRestrictions AS DetailedSetup
			|		On DetailedSetup.Products     = T.Products
			|			AND DetailedSetup.Characteristic = T.Characteristic
			|			AND DetailedSetup.GroupingProductRestrictions    = VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
			|			AND DetailedSetup.Warehouse.ShopFloorStockroom
			|			AND DetailedSetup.Warehouse.Department = T.Department
			|			AND DetailedSetup.AddlOrderingAttribute = 1
			|			AND DetailedSetup.ThisIsAValidParameter
			|		
			|		LEFT JOIN InformationRegister.ProductRestrictions AS GroupAffiliation
			|		ON DetailedSetup.Warehouse IS NULL
			|			AND GroupAffiliation.Products   = T.Products
			|			AND GroupAffiliation.Characteristic = T.Characteristic
			|			AND GroupAffiliation.GroupingProductRestrictions <> VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
			|			AND GroupAffiliation.Warehouse.ShopFloorStockroom
			|			AND GroupAffiliation.Warehouse.Department = T.Department
			|			AND GroupAffiliation.AddlOrderingAttribute = 1
			|			AND GroupAffiliation.ThisIsAValidParameter
			|		
			|		LEFT JOIN InformationRegister.ProductRestrictions AS SettingUpAGrouping
			|		ON DetailedSetup.Warehouse IS NULL
			|			AND SettingUpAGrouping.Products   = VALUE(Catalog.Products.EmptyRef)
			|			AND SettingUpAGrouping.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|			AND SettingUpAGrouping.Warehouse          = VALUE(Catalog.Warehouses.EmptyRef)
			|			AND SettingUpAGrouping.GroupingProductRestrictions    = GroupAffiliation.GroupingProductRestrictions
			|			AND SettingUpAGrouping.ThisIsAValidParameter
			|		
			|		LEFT JOIN InformationRegister.ProductRestrictions AS GeneralSetting
			|		ON DetailedSetup.Warehouse IS NULL
			|			AND GroupAffiliation.Warehouse IS NULL
			|			AND T.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|			AND GeneralSetting.Products   = T.Products
			|			AND GeneralSetting.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|			AND GeneralSetting.GroupingProductRestrictions    = VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef) 
			|			AND GeneralSetting.Warehouse.ShopFloorStockroom
			|			AND GeneralSetting.Warehouse.Department = T.Department
			|			AND GeneralSetting.AddlOrderingAttribute = 1
			|			AND GeneralSetting.ThisIsAValidParameter
			|		
			|		LEFT JOIN InformationRegister.ProductRestrictions AS BelongingToSharedSettingsGroup
			|		ON DetailedSetup.Warehouse IS NULL
			|			AND GroupAffiliation.Warehouse IS NULL
			|			AND GeneralSetting.Warehouse IS NULL
			|			AND T.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|			AND BelongingToSharedSettingsGroup.Products   = T.Products
			|			AND BelongingToSharedSettingsGroup.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|			AND BelongingToSharedSettingsGroup.Warehouse.ShopFloorStockroom
			|			AND BelongingToSharedSettingsGroup.Warehouse.Department = T.Department
			|			AND BelongingToSharedSettingsGroup.AddlOrderingAttribute = 1
			|			AND BelongingToSharedSettingsGroup.GroupingProductRestrictions    <> VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
			|			AND BelongingToSharedSettingsGroup.ThisIsAValidParameter
			|		
			|		LEFT JOIN InformationRegister.ProductRestrictions AS ConfiguringGroupingOfGeneralSettings
			|		ON DetailedSetup.Warehouse IS NULL
			|			AND GroupAffiliation.Warehouse IS NULL
			|			AND GeneralSetting.Warehouse IS NULL
			|			AND T.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|			AND ConfiguringGroupingOfGeneralSettings.Products   = VALUE(Catalog.Products.EmptyRef)
			|			AND ConfiguringGroupingOfGeneralSettings.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|			AND ConfiguringGroupingOfGeneralSettings.Warehouse          = VALUE(Catalog.Warehouses.EmptyRef)
			|			AND ConfiguringGroupingOfGeneralSettings.GroupingProductRestrictions    = BelongingToSharedSettingsGroup.GroupingProductRestrictions
			|			AND ConfiguringGroupingOfGeneralSettings.ThisIsAValidParameter";
			
		If ConnectionFields <> Undefined Then
			SubstringsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ConnectionFields);
			ReplaceSubstring = StrReplace(ReplaceSubstring, "T.Products",   SubstringsArray[0]);
			ReplaceSubstring = StrReplace(ReplaceSubstring, "T.Characteristic", SubstringsArray[1]);
			ReplaceSubstring = StrReplace(ReplaceSubstring, "T.Department",  SubstringsArray[2]);
		EndIf;
		ReplaceSubstring = StrReplace(ReplaceSubstring, "SettingsTable", Synonym);
		
		SubstitutionResult = StrReplace(SubstitutionResult, SearchSubstring, ReplaceSubstring);
		
	EndDo;
	
	Return SubstitutionResult;
	
EndFunction

// Generates the query text of a temporary table containing the inventory maintenance parameters set for products in
// the "Product restrictions" RS. The list of products and warehouses can be selected for data compounding.
// Parameters:
// 
// Returns:
//  String - the test of the query of the temporary table "Vttovarypoderzhivaemogozapas".
//
Function TemporaryTableGoodsOfSupportedStock() Export
	
	QueryText =
		"SELECT ALLOWED
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse          AS Warehouse,
		|	
		|	ISNULL(SettingUpAGrouping.SafetyStockQuantity, Table.SafetyStockQuantity)                           AS SafetyStockQuantity,
		|	ISNULL(SettingUpAGrouping.MinimumInventoryQuantity, Table.MinimumInventoryQuantity)                       AS MinimumInventoryQuantity,
		|	ISNULL(SettingUpAGrouping.MaximumInventoryAmount, Table.MaximumInventoryAmount)                     AS MaximumInventoryAmount,
		|	ISNULL(SettingUpAGrouping.ConsumptionRate, Table.ConsumptionRate)                                             AS ConsumptionRate,
		|	ISNULL(SettingUpAGrouping.InventoryReplenishmentMethod, Table.InventoryReplenishmentMethod)                     AS InventoryReplenishmentMethod,
		|	ISNULL(SettingUpAGrouping.OrderPackage, Table.OrderPackage)                                                 AS OrderPackage,
		|	ISNULL(SettingUpAGrouping.OrderFulfillmentWithinInventoryReplenishment, Table.OrderFulfillmentWithinInventoryReplenishment) AS OrderFulfillmentWithinInventoryReplenishment
		|	
		|INTO TTGoodsOfSupportedStock
		|	
		|FROM
		|	InformationRegister.ProductRestrictions AS Table
		|		
		|		LEFT JOIN InformationRegister.ProductRestrictions AS SettingUpAGrouping
		|		ON Table.GroupingProductRestrictions <> VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
		|			AND SettingUpAGrouping.Products   = VALUE(Catalog.Products.EmptyRef)
		|			AND SettingUpAGrouping.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|			AND SettingUpAGrouping.Warehouse          = VALUE(Catalog.Warehouses.EmptyRef)
		|			AND SettingUpAGrouping.GroupingProductRestrictions    = Table.GroupingProductRestrictions
		|			AND SettingUpAGrouping.ThisIsAValidParameter
		|
		|WHERE
		|	ISNULL(SettingUpAGrouping.InventoryReplenishmentMethod, Table.InventoryReplenishmentMethod) <> VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)
		|	AND Table.Products <> VALUE(Catalog.Products.EmptyRef)
		|	AND (Table.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
		|		OR Table.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|	AND Table.ThisIsAValidParameter
		|{WHERE
		|	Table.Products.*   AS Products,
		|	Table.Characteristic.* AS Characteristic,
		|	Table.Warehouse.*          AS Warehouse}
		|
		|{WHERE (Table.Products, Table.Characteristic) IN(
		|	SELECT
		|		FilterTable.Products   AS Products,
		|		FilterTable.Characteristic AS Characteristic
		|	FROM
		|		SegmentSelection AS FilterTable
		|	WHERE
		|		&FilterByProductSegmentIsUsed)}
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products        AS Products,
		|	CharacteristicTable.Ref AS Characteristic,
		|	Table.Warehouse               AS Warehouse,
		|	
		|	ISNULL(SettingUpAGrouping.SafetyStockQuantity, Table.SafetyStockQuantity)                           AS SafetyStockQuantity,
		|	ISNULL(SettingUpAGrouping.MinimumInventoryQuantity, Table.MinimumInventoryQuantity)                       AS MinimumInventoryQuantity,
		|	ISNULL(SettingUpAGrouping.MaximumInventoryAmount, Table.MaximumInventoryAmount)                     AS MaximumInventoryAmount,
		|	ISNULL(SettingUpAGrouping.ConsumptionRate, Table.ConsumptionRate)                                             AS ConsumptionRate,
		|	ISNULL(SettingUpAGrouping.InventoryReplenishmentMethod, Table.InventoryReplenishmentMethod)                     AS InventoryReplenishmentMethod,
		|	ISNULL(SettingUpAGrouping.OrderPackage, Table.OrderPackage)                                                 AS OrderPackage,
		|	ISNULL(SettingUpAGrouping.OrderFulfillmentWithinInventoryReplenishment, Table.OrderFulfillmentWithinInventoryReplenishment) AS OrderFulfillmentWithinInventoryReplenishment
		|	
		|FROM
		|	InformationRegister.ProductRestrictions AS Table
		|		
		|		LEFT JOIN Catalog.Products AS ProductsTable
		|		ON ProductsTable.Ref = Table.Products
		|		
		|		LEFT JOIN Catalog.ItemsCharacteristics AS CharacteristicTable
		|		ON CharacteristicTable.Owner
		|			= CASE WHEN ProductsTable.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems) THEN
		|						ProductsTable.Ref
		|					WHEN ProductsTable.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind) THEN
		|						ProductsTable.ProductKind
		|					WHEN ProductsTable.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind) THEN
		|						ProductsTable.ItemVariantsOwner
		|				END
		|		
		|		LEFT JOIN InformationRegister.ProductRestrictions AS DetailedSetup
		|		ON DetailedSetup.Products      = Table.Products
		|			AND DetailedSetup.Characteristic = CharacteristicTable.Ref
		|			AND DetailedSetup.Warehouse          = Table.Warehouse
		|			AND DetailedSetup.ThisIsAValidParameter
		|		
		|		LEFT JOIN InformationRegister.ProductRestrictions AS SettingUpAGrouping
		|		ON Table.GroupingProductRestrictions <> VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
		|			AND SettingUpAGrouping.Products   = VALUE(Catalog.Products.EmptyRef)
		|			AND SettingUpAGrouping.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|			AND SettingUpAGrouping.Warehouse          = VALUE(Catalog.Warehouses.EmptyRef)
		|			AND SettingUpAGrouping.GroupingProductRestrictions    = Table.GroupingProductRestrictions
		|			AND SettingUpAGrouping.ThisIsAValidParameter
		|		
		|WHERE
		|	ISNULL(SettingUpAGrouping.InventoryReplenishmentMethod, Table.InventoryReplenishmentMethod) <> VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)
		|	AND Table.Products  <> VALUE(Catalog.Products.EmptyRef)
		|	AND Table.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|	AND Table.Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)
		|	AND Table.ThisIsAValidParameter
		|	AND DetailedSetup.Warehouse IS NULL
		|	AND NOT CharacteristicTable.Ref IS NULL
		|{WHERE
		|	Table.Products.*        AS Products,
		|	CharacteristicTable.Ref.* AS Characteristic,
		|	Table.Warehouse.*               AS Warehouse}
		|
		|{WHERE (Table.Products, Table.Characteristic) IN(
		|	SELECT
		|		FilterTable.Products   AS Products,
		|		FilterTable.Characteristic AS Characteristic
		|	FROM
		|		SegmentSelection AS FilterTable
		|	WHERE
		|		&FilterByProductSegmentIsUsed)}
		|
		|;
		|
		|///////////////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

// Gets the value of the "inventory maintenance Parameters" setting for a product item in the warehouse or grouping.
// Parameters:
//    Var_Key - Structure - Structure with fields:
//                        Nomenclature - Reference link.Item - Item item for which you want
//                                                                       to get the setting value.
//                        Feature - Reference link.Nomenclature specificationat the characteristic of the nomenclature
//                            for which you want to get the setting value.
//                        Warehouse - Reference link.Warehouses - The warehouse for which you want to get the setting value.
//                        Grouping of Product restrictionsreferenceslink.Grouping of product restrictions - The grouping for which
//                            you want to get the setting value
// Returns:
//    Structure - Structure with fields:
//                 The method of specifying the setting - String - Takes one of the following values: "FOR A product",
//                                                    "FOR A PRODUCT CHARACTERISTIC", "FOR A GROUP_PRODUCTS", "NOT SPECIFIED".
//                 Grouping of Product restrictionsreferenceslink.Grouping of product restrictions - The grouping of product restrictions for
//                                                                                 which the setting is set.
//                 The method of providing needs is listing the link.The method of providing needs is the value of the parameter
//                     "Method of providing needs".
//                 Insurance quantity of inventory - Number - Value of the parameter "Insurance quantity of inventory".
//                 The minimum quantity of inventory is a number - The value of the "Minimum amount of inventory" parameter.
//                 The maximum quantity of inventory is a number - The value of the "Maximum amount of inventory" parameter.
//                 Consumption norm - Number - Value of the parameter "Consumption norm".
//                 Packagingkazakase - Reference link.Packageunits of measurement - The value of the parameter "Order packaging".
//                 Securing the order of the order of storage - Transfer of the link.Order Maintenance -
//                     The value of the parameter "Securing orders while maintaining stock".
//
Function ParametersForMaintainingStockOfGoodsInStock(Var_Key) Export
	
	If Var_Key.Property("Group") Then
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	ProductRestrictions.GroupingProductRestrictions,
			|	ProductRestrictions.SafetyStockQuantity,
			|	ProductRestrictions.MinimumInventoryQuantity,
			|	ProductRestrictions.MaximumInventoryAmount,
			|	ProductRestrictions.ConsumptionRate,
			|	ProductRestrictions.InventoryReplenishmentMethod,
			|	ProductRestrictions.OrderPackage,
			|	ProductRestrictions.OrderFulfillmentWithinInventoryReplenishment,
			|	""FOR_GROUP_Products"" AS SettingSpecificationMethod
			|FROM
			|	InformationRegister.ProductRestrictions AS ProductRestrictions
			|WHERE
			|	ProductRestrictions.GroupingProductRestrictions = &GroupingProductRestrictions
			|	AND ProductRestrictions.Products = VALUE(Catalog.Products.EmptyRef)
			|	AND ProductRestrictions.ThisIsAValidParameter";
		
		Query.SetParameter("GroupingProductRestrictions", Var_Key.GroupingProductRestrictions);
		Selection = Query.Execute().Select();
	
	Else
	
		Query = New Query();
		Query.Text =
		"SELECT
		|	&Products   AS Products,
		|	&Characteristic AS Characteristic,
		|	&Warehouse          AS Warehouse
		|INTO TTKeyRecording
		|;
		|
		|////////////////////////////////////////
		|SELECT
		|	&SettingSpecificationMethod                                   AS SettingSpecificationMethod,
		|	ProductRestrictions.GroupingProductRestrictions                            AS GroupingProductRestrictions,
		|	ProductRestrictions.SafetyStockQuantity              AS SafetyStockQuantity,
		|	ProductRestrictions.MinimumInventoryQuantity            AS MinimumInventoryQuantity,
		|	ProductRestrictions.MaximumInventoryAmount           AS MaximumInventoryAmount,
		|	ProductRestrictions.ConsumptionRate                       AS ConsumptionRate,
		|	ProductRestrictions.InventoryReplenishmentMethod           AS InventoryReplenishmentMethod,
		|	ProductRestrictions.OrderPackage                         AS OrderPackage,
		|	ProductRestrictions.OrderFulfillmentWithinInventoryReplenishment AS OrderFulfillmentWithinInventoryReplenishment
		|FROM
		|	TTKeyRecording AS RecordKey
		|		
		|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
		|		ON &SubstituteGoodsRestriction";
		
		Query.Text = SubstituteConnection(
			Query.Text,
			"SubstituteGoodsRestriction",
			"RecordKey.Products,RecordKey.Characteristic,RecordKey.Warehouse");
			
		// Calculation of the field "Method of specifying settings", uses the utility tables of the function Substitute connection(...).
		SubstitutionMethodForSpecifyingSettings =
			"CASE WHEN NOT DetailedSetup.Products IS NULL THEN
			|			CASE WHEN DetailedSetup.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|					AND DetailedSetup.Products.UseVariants 
			|					<> VALUE(Enum.ItemVariantsUsageOptions.DontUse) THEN
			|				""FOR_CHARACTERISTICSOfProduct""
			|			ELSE
			|				""FOR_TOVARA""
			|			END
			|		WHEN NOT GroupAffiliation.Products IS NULL
			|				OR NOT ConfiguringGroupingOfGeneralSettings.Products IS NULL THEN
			|			""FOR_GROUP_Products""
			|		WHEN NOT GeneralSetting.Products IS NULL THEN
			|			""FOR_CHARACTERISTICSOfProduct""
			|		ELSE
			|			NULL
			|	END";
		
		Query.Text = StrReplace(Query.Text, "&SettingSpecificationMethod", SubstitutionMethodForSpecifyingSettings);
		
		Query.SetParameter("Products",   Var_Key.Products);
		Query.SetParameter("Characteristic", Var_Key.Characteristic);
		Query.SetParameter("Warehouse",          Var_Key.Warehouse);
		
		Selection = Query.Execute().Select();
		
	EndIf;
	
	SettingValue = New Structure();
	SettingValue.Insert("SettingSpecificationMethod", "Omitted");
	SettingValue.Insert("GroupingProductRestrictions", Catalogs.GoodsRestrictionGrouping.EmptyRef());
	SettingValue.Insert("InventoryReplenishmentMethod", Enums.InventoryReplenishmentMethods.OrderAgainstOrder);
	SettingValue.Insert("SafetyStockQuantity", 0.000);
	SettingValue.Insert("MinimumInventoryQuantity", 0.000);
	SettingValue.Insert("MaximumInventoryAmount", 0.000);
	SettingValue.Insert("ConsumptionRate", 0.000);
	SettingValue.Insert("OrderPackage", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	SettingValue.Insert("OrderFulfillmentWithinInventoryReplenishment", Enums.OrderFulfillmentWithinInventoryReplenishment.SupplyFromStock);
	
	If Selection.Next() And Selection.SettingSpecificationMethod <> NULL Then
		
		FillPropertyValues(SettingValue, Selection);
		
	EndIf;
	
	If SettingValue.InventoryReplenishmentMethod <> Enums.InventoryReplenishmentMethods.StockReplenishmentByStandard Then
		SettingValue.ConsumptionRate = 0.000;
	EndIf;
	
	Return SettingValue;
	
EndFunction

// Function-constructor of a structure that describes the grouping entry in the register.
//
// Parameters:
//		Group - CatalogRef.GoodsRestrictionGrouping - The grouping that defines the record key.
//
// Returns:
//		Structure - Structure with fields:
//			The key type	- String is a Service Attribute.
//			Grouping of Product restrictions	- Catalog.Grouping of product restrictions.
//
Function KeyForRecordingDimensions(Group = Undefined) Export
	Var_Key = New Structure;
	Var_Key.Insert("KeyType",		"Group");
	Var_Key.Insert("GroupingProductRestrictions",	?(Group <> Undefined, Group,
		Catalogs.GoodsRestrictionGrouping.EmptyRef()));
	Return Var_Key;
EndFunction

// Function-constructor of the structure describing the item entry (General setting for all characteristics) in the register.
//
// Returns:
//		Structure - Structure with fields:
//			The key type 		- String is a Service Attribute.
//			Nomenclature	- Reference link.Nomenclature.
//			Warehouse			- Reference link.Warehouses.
//
Function ProductEntryKey() Export
	Var_Key = New Structure;
	Var_Key.Insert("KeyType",		"CommonSetting");
	Var_Key.Insert("Products",	Catalogs.GoodsRestrictionGrouping.EmptyRef());
	Var_Key.Insert("Warehouse",			Catalogs.Warehouses.EmptyRef());
	Return Var_Key;
EndFunction

// Function-constructor of a structure that describes an item record with a characteristic in the register.
//
// Returns:
//		Structure - Structure with fields:
//			The key type 		- String is a Service Attribute.
//			Nomenclature	- Reference link.Nomenclature.
//			Characteristic	- Reference link.Characteristics of the nomenclature.
//			Warehouse			- Reference link.Warehouses.
//
Function FeatureRecordingKey() Export
	Var_Key = New Structure;
	Var_Key.Insert("KeyType",		"DetailedSetting");
	Var_Key.Insert("Products",	Catalogs.GoodsRestrictionGrouping.EmptyRef());
	Var_Key.Insert("Characteristic",	Catalogs.ItemsCharacteristics.EmptyRef());
	Var_Key.Insert("Warehouse",			Catalogs.Warehouses.EmptyRef());
	Return Var_Key;
EndFunction

// Returns an array of keys for item records and characteristics included in the specified grouping.
//
// Parameters:
//		Group		- CatalogRef.GoodsRestrictionGrouping - Grouping by which record keys are returned.
//		Warehouse			- CatalogRef.Warehouses - Limit the selection by warehouse.
//
// Returns:
//		Array - Contains a key for recording products (see the key for recording Nomenclature() , the key for recording characteristics()).
//
Function KeysForProductEntriesInDimension(Group, Warehouse = Undefined) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	ProductRestrictions.Warehouse,
		|	ProductRestrictions.Products,
		|	ProductRestrictions.Characteristic
		|FROM
		|	InformationRegister.ProductRestrictions AS ProductRestrictions
		|WHERE
		|	ProductRestrictions.GroupingProductRestrictions = &GroupingProductRestrictions
		|	AND ProductRestrictions.Products <> VALUE(Catalog.Products.EmptyRef)";
	
	Query.SetParameter("GroupingProductRestrictions", Group);
	
	If ValueIsFilled(Warehouse) Then
		Query.Text = Query.Text + " AND ProductRestrictions.Warehouse = &Warehouse";
		Query.SetParameter("Warehouse", Warehouse);
	EndIf;
	
	Selection = Query.Execute().Select();
	RecordsKeys = New Array;
	While Selection.Next() Do
		If ValueIsFilled(Selection.Characteristic) Then
			ProductRecordKey = InformationRegisters.ProductRestrictions.FeatureRecordingKey();
		Else
			ProductRecordKey = InformationRegisters.ProductRestrictions.ProductEntryKey();
		EndIf;
		FillPropertyValues(ProductRecordKey, Selection);
		RecordsKeys.Add(ProductRecordKey);
	EndDo;
	
	Return RecordsKeys;
	
EndFunction

// Function-constructor of a structure that describes the parameters for maintaining the "Min-max" stock.
//
// Returns:
//		Structure - Structure with fields:
//			The minimum number of hours				 is a number.
//			The maximum number of hours			 is a number.
//			Securing the order of the order of storage	- enumeration link.Ensuring the order of gas storage support.
//
Function ParametersMinMax() Export
	Parameters = New Structure();
	Parameters.Insert("MinimumInventoryQuantity",	0);
	Parameters.Insert("MaximumInventoryAmount",	0);
	Parameters.Insert("OrderFulfillmentWithinInventoryReplenishment",
		Enums.OrderFulfillmentWithinInventoryReplenishment.SupplyFromStock);
	Return Parameters;
EndFunction

// Function-constructor of the structure that describes the parameters for maintaining the stock "Calculation according to the norm".
//
// Returns:
//	Structure - structure with fields:
//		* ConsumptionRate - Number - Consumption rate.
//		* SafetyStockQuantity - Number - Safety stock.
//		* OrderFulfillmentWithinInventoryReplenishment - EnumRef.OrderFulfillmentWithinInventoryReplenishment - Option for securing orders while maintaining inventory
//
Function ParametersCalculationByNorm() Export
	Parameters = New Structure();
	Parameters.Insert("ConsumptionRate",			0);
	Parameters.Insert("SafetyStockQuantity",	0);
	Parameters.Insert("OrderFulfillmentWithinInventoryReplenishment",
		Enums.OrderFulfillmentWithinInventoryReplenishment.SupplyFromStock);
	Return Parameters;
EndFunction

// Function-constructor of the structure that describes the parameters for maintaining the stock "calculation by statistics".
//
// Returns:
//	Structure - structure with fields:
//		* SafetyStockQuantity - Number - Safety stock.
//		* OrderFulfillmentWithinInventoryReplenishment - EnumRef.OrderFulfillmentWithinInventoryReplenishment - Option for securing orders while maintaining inventory
//
Function ParametersCalculationBasedOnStatistics() Export
	Parameters = New Structure();
	Parameters.Insert("SafetyStockQuantity",	0);
	Parameters.Insert("OrderFulfillmentWithinInventoryReplenishment",
		Enums.OrderFulfillmentWithinInventoryReplenishment.SupplyFromStock);
	Return Parameters;
EndFunction

// Adds inventory maintenance using the "Minmax" method for an item in a warehouse or grouping.
// If the Minmax parameters are not passed and the stock was previously maintained by the key, then the old stock parameters are not reset to zero.
// Parameters:
//		RecordingKeys - Array of Structure, Structure -
//		ParametersMinMax - See ParametersMinMax.
//
Procedure AddStockMaintenanceMinMax(RecordingKeys, ParametersMinMax = Undefined) Export
	
	If TypeOf(RecordingKeys) = Type("Structure") Then
		Var_Key = RecordingKeys;
		RecordingKeys = New Array(1);
		RecordingKeys[0] = Var_Key;
	EndIf;
	
	ResetPreviouslySetMinMax = True;
	If ParametersMinMax = Undefined Then
		ResetPreviouslySetMinMax = False;
		ParametersMinMax = ParametersMinMax();
	EndIf;
	
	ParametersForRecording = EmptyProductRestrictionParameters();
	FillPropertyValues(ParametersForRecording, ParametersMinMax, 
		"MinimumInventoryQuantity, MaximumInventoryAmount, OrderFulfillmentWithinInventoryReplenishment");
	ParametersForRecording.InventoryReplenishmentMethod = Enums.InventoryReplenishmentMethods.StockReplenishmentMinMax;
	
	TableOfGoods		= TableOfGoods();
	DimensionsTable	= DimensionsTable();
	For Each Var_Key In RecordingKeys Do
		If Var_Key.KeyType = "DetailedSetting" Then
			TableEntry = TableOfGoods.Add();
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Characteristic	= Var_Key.Characteristic;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		ElsIf Var_Key.KeyType = "CommonSetting" Then
			TableEntry = TableOfGoods.Add();
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		ElsIf Var_Key.KeyType = "Group" Then
			TableEntry = DimensionsTable.Add();
			TableEntry.GroupingProductRestrictions = Var_Key.GroupingProductRestrictions;
		Else
			Raise NStr("vi = 'Loại khóa hồ sơ không hợp lệ!';
						|ru = 'Недопустимый тип ключа записи!';
						|en = 'Invalid type of record key.'; fa = 'Invalid type of record key.';
						|it = 'Tipo di chiave della registrazione non valido!';
						|pl = 'Nieprawidłowy typ klucza zapisu!';
						|tr = 'Geçersiz kayıt anahtarı tipi!'");;
		EndIf;
	EndDo;
	
	Write(TableOfGoods, DimensionsTable, ParametersForRecording, ResetPreviouslySetMinMax);
	
EndProcedure

// Adds inventory maintenance using the "norm Calculation" method for an item in a warehouse or grouping.
//
// Parameters:
//		RecordingKeys - Array of Structure, Structure -
//		NormalParameters - See ParametersCalculationByNorm.
//
Procedure AddStockMaintenanceRateCalculation(RecordingKeys, NormalParameters) Export
	
	If TypeOf(RecordingKeys) = Type("Structure") Then
		Var_Key = RecordingKeys;
		RecordingKeys = New Array(1);
		RecordingKeys[0] = Var_Key;
	EndIf;
	
	ParametersForRecording = EmptyProductRestrictionParameters();
	FillPropertyValues(ParametersForRecording, NormalParameters,
		"ConsumptionRate, SafetyStockQuantity, OrderFulfillmentWithinInventoryReplenishment");
	ParametersForRecording.InventoryReplenishmentMethod = Enums.InventoryReplenishmentMethods.StockReplenishmentByStandard;
	
	TableOfGoods		= TableOfGoods();
	DimensionsTable	= DimensionsTable();
	For Each Var_Key In RecordingKeys Do
		If Var_Key.KeyType = "DetailedSetting" Then
			TableEntry = TableOfGoods.Add();
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Characteristic	= Var_Key.Characteristic;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		ElsIf Var_Key.KeyType = "CommonSetting" Then
			TableEntry = TableOfGoods.Add();
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		ElsIf Var_Key.KeyType = "Group" Then
			TableEntry = DimensionsTable.Add();
			TableEntry.GroupingProductRestrictions		= Var_Key.GroupingProductRestrictions;
		Else
			Raise NStr("vi = 'Loại khóa hồ sơ không hợp lệ!';
						|ru = 'Недопустимый тип ключа записи!';
						|en = 'Invalid type of record key.'; fa = 'Invalid type of record key.';
						|it = 'Tipo di chiave della registrazione non valido!';
						|pl = 'Nieprawidłowy typ klucza zapisu!';
						|tr = 'Geçersiz kayıt anahtarı tipi!'");;
		EndIf;
	EndDo;
	
	Write(TableOfGoods, DimensionsTable, ParametersForRecording, True);
	
EndProcedure

// Adds inventory maintenance using the "statistics Calculation" method for an item in a warehouse or grouping.
//
// Parameters:
//		RecordingKeys - Array of Structure, Structure -
//		ParametersForStatistics - See ParametersCalculationBasedOnStatistics.
//
Procedure AddStockMaintenanceCalculationByStatistics(RecordingKeys, ParametersForStatistics) Export
	
	If TypeOf(RecordingKeys) = Type("Structure") Then
		Var_Key = RecordingKeys;
		RecordingKeys = New Array(1);
		RecordingKeys[0] = Var_Key;
	EndIf;
	
	ParametersForRecording = EmptyProductRestrictionParameters();
	FillPropertyValues(ParametersForRecording, ParametersForStatistics,
		"SafetyStockQuantity, OrderFulfillmentWithinInventoryReplenishment");
	ParametersForRecording.InventoryReplenishmentMethod = Enums.InventoryReplenishmentMethods.StockReplenishmentByStatistics;
	
	TableOfGoods		= TableOfGoods();
	DimensionsTable	= DimensionsTable();
	For Each Var_Key In RecordingKeys Do
		If Var_Key.KeyType = "DetailedSetting" Then
			TableEntry = TableOfGoods.Add();
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Characteristic	= Var_Key.Characteristic;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		ElsIf Var_Key.KeyType = "CommonSetting" Then
			TableEntry = TableOfGoods.Add();
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		ElsIf Var_Key.KeyType = "Group" Then
			TableEntry = DimensionsTable.Add();
			TableEntry.GroupingProductRestrictions		= Var_Key.GroupingProductRestrictions;
		Else
			Raise NStr("vi = 'Loại khóa hồ sơ không hợp lệ!';
						|ru = 'Недопустимый тип ключа записи!';
						|en = 'Invalid type of record key.'; fa = 'Invalid type of record key.';
						|it = 'Tipo di chiave della registrazione non valido!';
						|pl = 'Nieprawidłowy typ klucza zapisu!';
						|tr = 'Geçersiz kayıt anahtarı tipi!'");;
		EndIf;
	EndDo;
	
	Write(TableOfGoods, DimensionsTable, ParametersForRecording, True);
	
EndProcedure

// Adds inventory maintenance by grouping parameters for an item in the warehouse.
//
// Parameters:
//		RecordingKeys - Array of Structure, Structure -
//		GroupingKey - See KeyForRecordingDimensions.
//
Procedure AddInventoryMaintenanceByGrouping(RecordingKeys, GroupingKey) Export
	
	If TypeOf(RecordingKeys) = Type("Structure") Then
		Var_Key = RecordingKeys;
		RecordingKeys = New Array(1);
		RecordingKeys[0] = Var_Key;
	EndIf;
	
	If GroupingKey.KeyType = "Group" Then
		ParametersForRecording = EmptyProductRestrictionParameters();
		ParametersForRecording.Insert("GroupingProductRestrictions", GroupingKey.GroupingProductRestrictions);
	Else
		Raise NStr("vi = 'Loại khóa hồ sơ nhóm không hợp lệ!';
					|ru = 'Недопустимый тип ключа записи группировки!';
					|en = 'Invalid type of grouping record key.'; fa = 'Invalid type of grouping record key.';
					|it = 'Tipo di chiave della registrazione del raggruppamento non valido!';
					|pl = 'Nieprawidłowy typ klucza grupowania!';
					|tr = 'Gruplama geçersiz kayıt anahtarı tipi!'");
	EndIf;
	
	TableOfGoods = TableOfGoods();
	For Each Var_Key In RecordingKeys Do
		TableEntry = TableOfGoods.Add();
		If Var_Key.KeyType = "DetailedSetting" Then
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Characteristic	= Var_Key.Characteristic;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		ElsIf Var_Key.KeyType = "CommonSetting" Then
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		Else
			Raise NStr("vi = 'Loại khóa hồ sơ không hợp lệ!';
						|ru = 'Недопустимый тип ключа записи!';
						|en = 'Invalid type of record key.'; fa = 'Invalid type of record key.';
						|it = 'Tipo di chiave della registrazione non valido!';
						|pl = 'Nieprawidłowy typ klucza zapisu!';
						|tr = 'Geçersiz kayıt anahtarı tipi!'");
		EndIf;
	EndDo;
	
	// If there is no record for this grouping, then we will create it
	DimensionsTable = DimensionsTable();
	If ValueIsFilled(GroupingKey.GroupingProductRestrictions) Then
		TableEntry = DimensionsTable.Add();
		TableEntry.GroupingProductRestrictions = GroupingKey.GroupingProductRestrictions;
	EndIf;
	
	Write(TableOfGoods, DimensionsTable, ParametersForRecording, True);
	
EndProcedure

// Removes the maintenance of a stock of goods in the warehouse or groupings.
//
// Parameters:
//		RecordingKeys - Array of Structure, Structure -
//
Procedure RemoveStockMaintenance(RecordingKeys) Export

	If TypeOf(RecordingKeys) = Type("Structure") Then
		Var_Key = RecordingKeys;
		RecordingKeys = New Array(1);
		RecordingKeys[0] = Var_Key;
	EndIf;
	
	TableOfGoods		= TableOfGoods();
	DimensionsTable	= DimensionsTable();
	For Each Var_Key In RecordingKeys Do
		If Var_Key.KeyType = "DetailedSetting" Then
			TableEntry = TableOfGoods.Add();
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Characteristic	= Var_Key.Characteristic;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		ElsIf Var_Key.KeyType = "CommonSetting" Then
			TableEntry = TableOfGoods.Add();
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		ElsIf Var_Key.KeyType = "Group" Then
			TableEntry = DimensionsTable.Add();
			TableEntry.GroupingProductRestrictions		= Var_Key.GroupingProductRestrictions;
		Else
			Raise NStr("vi = 'Loại khóa hồ sơ không hợp lệ!';
						|ru = 'Недопустимый тип ключа записи!';
						|en = 'Invalid type of record key.'; fa = 'Invalid type of record key.';
						|it = 'Tipo di chiave della registrazione non valido!';
						|pl = 'Nieprawidłowy typ klucza zapisu!';
						|tr = 'Geçersiz kayıt anahtarı tipi!'");;
		EndIf;
	EndDo;
	
	Delete(TableOfGoods, DimensionsTable);

EndProcedure

// Sets the maintenance of stock for a product with a characteristic in stock according to the general settings of the nomenclature.
//
// Parameters:
//	FeatureRecordingKeys - Array of See InformationRegisters.ProductRestrictions.FeatureRecordingKey
//		- See InformationRegisters.ProductRestrictions.FeatureRecordingKey
//
Procedure SetStockMaintenanceAsForProducts(FeatureRecordingKeys) Export

	If TypeOf(FeatureRecordingKeys) = Type("Structure") Then
		Var_Key = FeatureRecordingKeys;
		FeatureRecordingKeys = New Array(1);
		FeatureRecordingKeys[0] = Var_Key;
	EndIf;
	
	TableOfGoods		= TableOfGoods();
	For Each Var_Key In FeatureRecordingKeys Do
		If Var_Key.KeyType = "DetailedSetting" Then
			TableEntry = TableOfGoods.Add();
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Characteristic	= Var_Key.Characteristic;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		Else
			Raise NStr("vi = 'Loại khóa bản ghi ký tự không hợp lệ!';
						|ru = 'Недопустимый тип ключа записи характеристики!';
						|en = 'Invalid type of variant record key.'; fa = 'Invalid type of variant record key.';
						|it = 'Tipo di chiave della registrazione della caratteristica non valido!';
						|pl = 'Nieprawidłowy typ klucza charakterystyki!';
						|tr = 'Varyantın geçersiz kayıt anahtarı tipi!'");;
		EndIf;
	EndDo;
	
	Delete(TableOfGoods, DimensionsTable(), True);

EndProcedure

// Fills in the specified inventory maintenance parameter for items in the warehouse or groupings.
// Filling in only applies to those records for which it makes sense (based on the security method).
//
// Parameters:
//		RecordingKeys - Array of Structure, Structure -
//		ParameterName	- String - Name of the zaponenie parameter.
//		Value	- Number, EnumRef.OrderFulfillmentWithinInventoryReplenishment - Value of the fill parameter.
// Returns:
//		Number - The number of completed records.
//
Function FillInStockMaintenanceParameter(RecordingKeys, ParameterName, Value) Export
	
	If TypeOf(RecordingKeys) = Type("Structure") Then
		Var_Key = RecordingKeys;
		RecordingKeys = New Array(1);
		RecordingKeys[0] = Var_Key;
	EndIf;
	
	MethodsForSelection = New Array;
	If ParameterName = "MinimumInventoryQuantity" Or ParameterName = "MaximumInventoryAmount" Then
		MethodsForSelection.Add(Enums.InventoryReplenishmentMethods.StockReplenishmentMinMax);
	ElsIf ParameterName = "ConsumptionRate" Then
		MethodsForSelection.Add(Enums.InventoryReplenishmentMethods.StockReplenishmentByStandard);
	ElsIf ParameterName = "SafetyStockQuantity" Then
		MethodsForSelection.Add(Enums.InventoryReplenishmentMethods.StockReplenishmentByStandard);
		MethodsForSelection.Add(Enums.InventoryReplenishmentMethods.StockReplenishmentByStatistics);
	ElsIf ParameterName = "OrderFulfillmentWithinInventoryReplenishment" Then
		MethodsForSelection.Add(Enums.InventoryReplenishmentMethods.StockReplenishmentMinMax);
		MethodsForSelection.Add(Enums.InventoryReplenishmentMethods.StockReplenishmentByStandard);
		MethodsForSelection.Add(Enums.InventoryReplenishmentMethods.StockReplenishmentByStatistics);
	Else
		Raise NStr("vi = 'Đã xác định sai tên tham số!';
					|ru = 'Некорректно задано имя параметра!';
					|en = 'Parameter name is specified incorrectly.'; fa = 'Parameter name is specified incorrectly.';
					|it = 'Nome del parametro impostato incorrettamente!';
					|pl = 'Nazwa parametru jest niepoprawnie ustawiona!';
					|tr = 'Parametre adı yanlış belirtildi!'");
	EndIf;
	
	ParametersForRecording = New Structure;
	ParametersForRecording.Insert(ParameterName, Value);
	
	TableOfGoods		= TableOfGoods();
	DimensionsTable	= DimensionsTable();
	For Each Var_Key In RecordingKeys Do
		If Var_Key.KeyType = "DetailedSetting" Then
			TableEntry = TableOfGoods.Add();
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Characteristic	= Var_Key.Characteristic;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		ElsIf Var_Key.KeyType = "CommonSetting" Then
			TableEntry = TableOfGoods.Add();
			TableEntry.Products		= Var_Key.Products;
			TableEntry.Warehouse				= Var_Key.Warehouse;
		ElsIf Var_Key.KeyType = "Group" Then
			TableEntry = DimensionsTable.Add();
			TableEntry.GroupingProductRestrictions		= Var_Key.GroupingProductRestrictions;
		Else
			Raise NStr("vi = 'Loại khóa hồ sơ không hợp lệ!';
						|ru = 'Недопустимый тип ключа записи!';
						|en = 'Invalid type of record key.'; fa = 'Invalid type of record key.';
						|it = 'Tipo non valido della chiave di registrazione!';
						|pl = 'Nieprawidłowy typ klucza zapisu!';
						|tr = 'Geçersiz kayıt anahtarı tipi!'");;
		EndIf;
	EndDo;
	
	Return Write(TableOfGoods, DimensionsTable, ParametersForRecording, True, MethodsForSelection);
	
EndFunction


// Sets the order packaging for the product in the warehouse.
//
// Parameters:
//  Products	- CatalogRef.Products - Range of goods,
//  Characteristic	- CatalogRef.ItemsCharacteristics - Characteristics of goods,
//  Warehouse			- CatalogRef.Warehouses - warehouse.
//  OrderPackage  - CatalogRef.PackagesAndUnitsOfMeasure - Order packaging.
//
Procedure SetProductPackaging(Products, Characteristic, Warehouse, OrderPackage) Export

	RecordSet = InformationRegisters.ProductRestrictions.CreateRecordSet();
	RecordSet.Filter.Products.Set(Products);
	RecordSet.Filter.Characteristic.Set(Characteristic);
	RecordSet.Filter.Warehouse.Set(Warehouse);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProductRestrictions");
	LockItem.SetValue("Products",	Products);
	LockItem.SetValue("Characteristic",	Characteristic);
	LockItem.SetValue("Warehouse",			Warehouse);
	
	BeginTransaction();
	Try
		
		Block.Lock();
		
		RecordSet.Read();
		
		CleaningPackaging = Not ValueIsFilled(OrderPackage);
		Write = False;
		If RecordSet.Count() = 0 Then
			If Not CleaningPackaging Then
				RegisterRecord = RecordSet.Add();
				RegisterRecord.Products		= Products;
				RegisterRecord.Characteristic	= Characteristic;
				RegisterRecord.Warehouse			= Warehouse;
				RegisterRecord.InventoryReplenishmentMethod	= Enums.InventoryReplenishmentMethods.OrderAgainstOrder;
				RegisterRecord.OrderPackage = OrderPackage;
				RegisterRecord.ThisIsAValidParameter	= False;
				Write = True;
			EndIf;
		ElsIf Not RecordSet[0].ThisIsAValidParameter And CleaningPackaging And
			Not RecordSet[0].ThereIsRecommendationForChange Then
			RecordSet.Clear();
			Write = True;
		ElsIf RecordSet[0].OrderPackage <> OrderPackage Then
			RecordSet[0].OrderPackage = OrderPackage;
			Write = True;
		EndIf;
		If Write Then
			RecordSet.Write();
		EndIf;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("vi = 'Nhiệm vụ đóng gói đơn hàng đối với hàng hóa trong kho';
							|ru = 'Задание упаковки заказа для товара на складе';
							|en = 'Job for packaging the order for goods in the warehouse'; fa = 'Job for packaging the order for goods in the warehouse';
							|it = 'Task per l''imballaggio dell''ordine per la merce nel magazzino';
							|pl = 'Określanie opakowania zamówienia dla towarów magazynowych';
							|tr = 'Ambardaki ürünler için sipariş paketleme ünitelerinin belirtilmesi'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

// Updates consumption statistics for the list of products in warehouses.
//
// Parameters:
//	TempTablesManager	- TempTablesManager - Manager with a temporary table Towary.
//
Procedure CalculateStatisticsOfConsumptionOfGoods(TempTablesManager) Export
	
	Cursor = New Structure("Products, Characteristic, Warehouse");
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	
	SetPrivilegedMode(True);
	
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("RecommendationCalculationDate", CurrentSessionDate());
	SupplyServer.SetParametersForStatisticsCalculationRequest(Query);
	SupplyServer.AddTemporaryTableOfConsumptionStatistics(Query, "TTProducts_1");
	
	SetPrivilegedMode(False);
	
	While True Do
		
		Query.Text = 
			"SELECT TOP 100
			|	T.Products AS Products,
			|	T.Characteristic AS Characteristic,
			|	T.Warehouse AS Warehouse
			|INTO GoodsPortion
			|FROM
			|	TTProducts_1 AS T
			|WHERE
			|	T.Products >= &Products
			|	AND (T.Products > &Products OR T.Characteristic >= &Characteristic)
			|	AND (T.Products > &Products OR T.Characteristic > &Characteristic OR T.Warehouse > &Warehouse)
			|
			|ORDER BY
			|	Products,
			|	Characteristic,
			|	Warehouse
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|// Blocking of mutable records
			|SELECT
			|	GoodsPortion.Products AS Products,
			|	GoodsPortion.Characteristic AS Characteristic,
			|	GoodsPortion.Warehouse AS Warehouse
			|FROM
			|	GoodsPortion AS GoodsPortion
			|
			|UNION ALL
			|
			|// Blocking General Settings records
			|SELECT
			|	GoodsPortion.Products,
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
			|	GoodsPortion.Warehouse
			|FROM
			|	GoodsPortion AS GoodsPortion
			|WHERE
			|	GoodsPortion.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|// Blocking groups
			|SELECT DISTINCT
			|	VALUE(Catalog.Products.EmptyRef) AS Products,
			|	GoodsPortion.Warehouse AS Warehouse,
			|	ProductRestrictions.GroupingProductRestrictions AS GroupingProductRestrictions
			|FROM
			|	GoodsPortion AS GoodsPortion
			|	LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
			|		ON GoodsPortion.Products = ProductRestrictions.Products
			|		AND GoodsPortion.Warehouse = ProductRestrictions.Warehouse
			|WHERE
			|	ProductRestrictions.GroupingProductRestrictions <> VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)";
		
		Query.SetParameter("Products",	Cursor.Products);
		Query.SetParameter("Characteristic",	Cursor.Characteristic);
		Query.SetParameter("Warehouse",			Cursor.Warehouse);
		
		QueryResults = Query.ExecuteBatch();
		
		If QueryResults[1].IsEmpty() Then
			Break;
		EndIf;
		
		BeginTransaction();
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.ProductRestrictions");
			LockItem.DataSource = QueryResults[1];
			LockItem.UseFromDataSource("Products",		"Products");
			LockItem.UseFromDataSource("Characteristic",	"Characteristic");
			LockItem.UseFromDataSource("Warehouse",			"Warehouse");
			
			LockItem = Block.Add("InformationRegister.ProductRestrictions");
			LockItem.DataSource = QueryResults[2];
			LockItem.UseFromDataSource("Products",		"Products");
			LockItem.UseFromDataSource("Warehouse",			"Warehouse");
			LockItem.UseFromDataSource("GroupingProductRestrictions",		"GroupingProductRestrictions");
			
			LockItem = Block.Add("InformationRegister.ProductRestrictions");
			LockItem.DataSource = QueryResults[1];
			LockItem.UseFromDataSource("Products",		"Products");
			LockItem.UseFromDataSource("Warehouse",			"Warehouse");
			LockItem.Mode = DataLockMode.Shared;
			
			LockItem = Block.Add("InformationRegister.ProductRestrictions");
			LockItem.DataSource = QueryResults[2];
			LockItem.UseFromDataSource("Warehouse",			"Warehouse");
			LockItem.UseFromDataSource("GroupingProductRestrictions",		"GroupingProductRestrictions");
			LockItem.Mode = DataLockMode.Shared;
			Block.Lock();
			
			Query.Text = 
				"SELECT
				|	T.Products   AS Products,
				|	T.Characteristic AS Characteristic,
				|	T.Warehouse          AS Warehouse,
				|
				|	ProductRestrictions.GroupingProductRestrictions                            AS GroupingProductRestrictions,
				|	ProductRestrictions.InventoryReplenishmentMethod           AS InventoryReplenishmentMethod,
				|	ProductRestrictions.MinimumInventoryQuantity            AS MinimumInventoryQuantity,
				|	ProductRestrictions.MaximumInventoryAmount           AS MaximumInventoryAmount,
				|	ProductRestrictions.ConsumptionRate                       AS ConsumptionRate,
				|	ProductRestrictions.SafetyStockQuantity              AS SafetyStockQuantity,
				|	ProductRestrictions.OrderFulfillmentWithinInventoryReplenishment AS OrderFulfillmentWithinInventoryReplenishment,
				|	ProductRestrictions.OrderPackage                         AS OrderPackage,
				|
				|	ProductRestrictions.AddlOrderingAttribute AS AddlOrderingAttribute,
				|	ProductRestrictions.ThisIsAValidParameter    AS ThisIsAValidParameter,
				|
				|	ISNULL(Statistics.AverageDailyConsumption, 0) AS AverageDailyConsumption,
				|	ISNULL(Statistics.VarianceOfConsumption, 0)     AS VarianceOfConsumption,
				|	&RecommendationCalculationDate                         AS RecommendationCalculationDate,
				|
				|	ProductRestrictions.Products IS NULL AS NewRecord,
				|	NOT ISNULL(ProductRestrictions.ThisIsAValidParameter, FALSE)
				|		AND ISNULL(Statistics.AverageDailyConsumption, 0) = 0
				|		AND ISNULL(ProductRestrictions.OrderPackage, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS DeleteRecord
				|FROM
				|	GoodsPortion AS T
				|		LEFT JOIN TTConsumptionStatistics AS Statistics
				|		ON T.Products = Statistics.Products
				|			AND T.Characteristic = Statistics.Characteristic
				|			AND T.Warehouse = Statistics.Warehouse
				|			AND Statistics.AverageDailyConsumption > 0
				|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
				|		ON T.Products = ProductRestrictions.Products
				|			AND T.Characteristic = ProductRestrictions.Characteristic
				|			AND T.Warehouse = ProductRestrictions.Warehouse
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP GoodsPortion";
			
			Selection = Query.Execute().Select();
			
			CommonSettings = GeneralSettingsTable_();
			Groups = TableOfServiceDimensions();
			
			While Selection.Next() Do
				FillPropertyValues(Cursor, Selection);
				
				RecordSet = InformationRegisters.ProductRestrictions.CreateRecordSet();
				If Not Selection.DeleteRecord Then
					RegisterRecord = RecordSet.Add();
					FillPropertyValues(RegisterRecord, Selection);
					If Selection.NewRecord Then
						RegisterRecord.InventoryReplenishmentMethod = Enums.InventoryReplenishmentMethods.OrderAgainstOrder;
						RegisterRecord.ThisIsAValidParameter = False;
					EndIf;
					RegisterRecord.AverageConsumptionVariance = Sqrt(Selection.VarianceOfConsumption);
					
					UpdateRecommendationToChangeRegisterEntry(RegisterRecord);
					If Not RegisterRecord.ThisIsAValidParameter And Not RegisterRecord.ThereIsRecommendationForChange
						And Not ValueIsFilled(RegisterRecord.OrderPackage) Then
						RecordSet.Delete(RegisterRecord);
					EndIf;
				EndIf;
				
				If Selection.NewRecord And RecordSet.Count() = 0 Then
					Continue;
				EndIf;
				
				// We remember for which of the grouping records we need to update the props there is a recommendation for modification.
				RememberGroupingForUpdates(Groups, Selection.GroupingProductRestrictions, Selection.Warehouse,
					?(RecordSet.Count() > 0, RecordSet[0].ThereIsRecommendationForChange, False));
				If ValueIsFilled(Selection.Characteristic) Then
					RememberGeneralSettingForUpdate(CommonSettings, Selection.Products, Selection.Warehouse);
				EndIf;
				
				RecordSet.Filter.Products.Set(Selection.Products);
				RecordSet.Filter.Characteristic.Set(Selection.Characteristic);
				RecordSet.Filter.Warehouse.Set(Selection.Warehouse);
				RecordSet.Write();
				
			EndDo;
			
			// Checking the correctness of blocked groupings
			BlockedGroups = QueryResults[2].Unload();
			Filter = New Structure("GroupingProductRestrictions, Warehouse");
			For Each RecordingDimensions In Groups Do
				FillPropertyValues(Filter, RecordingDimensions);
				FoundRows = BlockedGroups.FindRows(Filter);
				If FoundRows.Count() = 0 Then
					Raise NStr("vi = 'Sự không tương ứng trong giao thức của gom nhóm đã thay đổi và bị phong tỏa';
								|ru = 'Несоответствие в транзакции заблокированных и изменяемых группировок';
								|en = 'Mismatch in the transaction of locked and changed groupings'; fa = 'Mismatch in the transaction of locked and changed groupings';
								|it = 'Mancata corrispondenza nella transazione dei raggruppamenti bloccati e quelli in fase di modifica';
								|pl = 'Niedopasowanie transakcji zablokowanych i zmiennych grupowań';
								|tr = 'Kilitli ve değiştirilebilir gruplamaların işleminde uyumsuzluk'");
				EndIf;
			EndDo;
			
			UpdateRecommendationsForChangingGeneralSettings(CommonSettings, Groups);
			UpdateRecommendationsForChangingDimensions(Groups);
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			WriteLogEvent(NStr("vi = 'Tính toán thống kê tiêu thụ hàng hóa';
								|ru = 'Расчет статистики потребления товаров';
								|en = 'Goods consumption statistics calculation'; fa = 'Goods consumption statistics calculation';
								|it = 'Calcolo delle statistiche di consumo delle merci';
								|pl = 'Obliczanie statystyk zużycia towarów';
								|tr = 'Ürün tüketim istatistiklerinin hesaplanması'", CommonClientServer.DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
		
	EndDo;
	
EndProcedure

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
	
	Restriction.TextForExternalUsers1 = Restriction.Text;

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

// Function-constructor of a structure that describes the parameters of product restrictions.
//
// Returns:
//		Structure - Structure with fields:
//			The method of providing needs			- Enumeration.Methods of providing needs.
//			The minimum number of hours				 is a number.
//			The maximum number of hours			 is a number.
//			Insurance number of hours				 is a number.
//			The consumption norm					 is a number.
//			Securing the order of the order of storage	- enumeration link.Ensuring the order of gas storage support.
//
Function EmptyProductRestrictionParameters()
	ProductRestrictionParameters = New Structure();
	ProductRestrictionParameters.Insert("InventoryReplenishmentMethod",
		Enums.InventoryReplenishmentMethods.EmptyRef());
	ProductRestrictionParameters.Insert("MinimumInventoryQuantity",	0);
	ProductRestrictionParameters.Insert("MaximumInventoryAmount",	0);
	ProductRestrictionParameters.Insert("SafetyStockQuantity",		0);
	ProductRestrictionParameters.Insert("ConsumptionRate",				0);
	ProductRestrictionParameters.Insert("OrderFulfillmentWithinInventoryReplenishment",
		Enums.OrderFulfillmentWithinInventoryReplenishment.EmptyRef());

	Return ProductRestrictionParameters;
EndFunction

Function TableOfGoods()
	RecordsTable = New ValueTable;
	RecordsTable.Columns.Add("Products",		New TypeDescription("CatalogRef.Products"));
	RecordsTable.Columns.Add("Characteristic",	New TypeDescription("CatalogRef.ItemsCharacteristics"));
	RecordsTable.Columns.Add("Warehouse",			New TypeDescription("CatalogRef.Warehouses"));
	Return RecordsTable;
EndFunction

Function DimensionsTable()
	RecordsTable = New ValueTable;
	RecordsTable.Columns.Add("GroupingProductRestrictions", New TypeDescription("CatalogRef.GoodsRestrictionGrouping"));
	Return RecordsTable;
EndFunction

Function TableOfServiceDimensions()
	ServiceDimensions = New ValueTable;
	ServiceDimensions.Columns.Add("GroupingProductRestrictions",
		New TypeDescription("CatalogRef.GoodsRestrictionGrouping"));
	ServiceDimensions.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	ServiceDimensions.Columns.Add("ThereIsRecommendationForChange", New TypeDescription("Boolean"));
	Return ServiceDimensions;
EndFunction

Function GeneralSettingsTable_()
	CommonSettings = New ValueTable;
	CommonSettings.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	CommonSettings.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	CommonSettings.Columns.Add("ThereIsRecommendationForChange", New TypeDescription("Boolean"));
	Return CommonSettings;
EndFunction

Procedure RememberGroupingForUpdates(TableOfServiceDimensions, Group, Warehouse,
											ThereIsRecommendationForChange)
	
	If Not ValueIsFilled(Group) Then
		Return;
	EndIf;
	
	Filter = New Structure("GroupingProductRestrictions, Warehouse", Group, Warehouse);
	FoundRows = TableOfServiceDimensions.FindRows(Filter);
	If FoundRows.Count() > 0 Then
		DimensionString = FoundRows[0];
		DimensionString.ThereIsRecommendationForChange	= DimensionString.ThereIsRecommendationForChange
			Or ThereIsRecommendationForChange;
	Else
		DimensionString = TableOfServiceDimensions.Add();
		DimensionString.GroupingProductRestrictions					= Group;
		DimensionString.Warehouse							= Warehouse;
		DimensionString.ThereIsRecommendationForChange	= ThereIsRecommendationForChange;
	EndIf;
	
EndProcedure

Procedure RememberGeneralSettingForUpdate(GeneralSettingsTable_, Products, Warehouse)
	
	Filter = New Structure("Products, Warehouse", Products, Warehouse);
	FoundRows = GeneralSettingsTable_.FindRows(Filter);
	If FoundRows.Count() = 0 Then
		CommonSetting = GeneralSettingsTable_.Add();
		CommonSetting.Products					= Products;
		CommonSetting.Warehouse						= Warehouse;
	EndIf;

EndProcedure

Function Write(TableOfGoods, DimensionsTable, ParametersForRecording, ResetPreviouslySetMinMax,
			MethodsForSelection = Undefined)
	
	TableOfGoods.GroupBy("Products,Characteristic,Warehouse");
	DimensionsTable.GroupBy("GroupingProductRestrictions");
	
	SettingDimensions = ParametersForRecording.Property("GroupingProductRestrictions");
	ExclusionFromGroup = SettingDimensions And ParametersForRecording.GroupingProductRestrictions.IsEmpty();
	
	BeginTransaction();
	Try
	
		Block = New DataLock;
		
		LockItem = Block.Add("InformationRegister.ProductRestrictions");
		LockItem.DataSource = TableOfGoods;
		LockItem.UseFromDataSource("Products",		"Products");
		LockItem.UseFromDataSource("Characteristic",	"Characteristic");
		LockItem.UseFromDataSource("Warehouse",			"Warehouse");
		
		For Each TableRow In DimensionsTable Do
			LockItem = Block.Add("InformationRegister.ProductRestrictions");
			LockItem.SetValue("Products",	Catalogs.Products.EmptyRef());
			LockItem.SetValue("Warehouse",			Catalogs.Warehouses.EmptyRef());
			LockItem.SetValue("GroupingProductRestrictions",		TableRow.GroupingProductRestrictions);
		EndDo;
		
		Block.Lock();
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	TableOfGoods.Products   AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Warehouse          AS Warehouse
			|INTO TTTableOfGoods
			|FROM
			|	&TableOfGoods AS TableOfGoods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DimensionsTable.GroupingProductRestrictions AS GroupingProductRestrictions
			|INTO TTDimensionsTable
			|FROM
			|	&DimensionsTable AS DimensionsTable
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Products     AS Products,
			|	TableOfGoods.Characteristic   AS Characteristic,
			|	TableOfGoods.Warehouse            AS Warehouse,
			|	ProductRestrictions.GroupingProductRestrictions AS GroupingProductRestrictions,
			|
			|	ISNULL(ProductGroupingRestrictions.InventoryReplenishmentMethod,
			|		ProductRestrictions.InventoryReplenishmentMethod)             AS InventoryReplenishmentMethod,
			|	ISNULL(ProductGroupingRestrictions.MinimumInventoryQuantity,
			|		ProductRestrictions.MinimumInventoryQuantity)              AS MinimumInventoryQuantity,
			|	ISNULL(ProductGroupingRestrictions.MaximumInventoryAmount,
			|		ProductRestrictions.MaximumInventoryAmount)             AS MaximumInventoryAmount,
			|	ISNULL(ProductGroupingRestrictions.ConsumptionRate,
			|		ProductRestrictions.ConsumptionRate)                         AS ConsumptionRate,
			|	ISNULL(ProductGroupingRestrictions.SafetyStockQuantity,
			|		ProductRestrictions.SafetyStockQuantity)                AS SafetyStockQuantity,
			|	ISNULL(ProductGroupingRestrictions.OrderFulfillmentWithinInventoryReplenishment,
			|		ProductRestrictions.OrderFulfillmentWithinInventoryReplenishment)   AS OrderFulfillmentWithinInventoryReplenishment,
			|
			|	ProductRestrictions.OrderPackage               AS OrderPackage,
			|	ProductRestrictions.AverageDailyConsumption     AS AverageDailyConsumption,
			|	ProductRestrictions.AverageConsumptionVariance AS AverageConsumptionVariance,
			|	ProductRestrictions.ThereIsRecommendationForChange  AS ThereIsRecommendationForChange,
			|	ProductRestrictions.RecommendationCalculationDate      AS RecommendationCalculationDate,
			|	ProductRestrictions.AddlOrderingAttribute    AS AddlOrderingAttribute,
			|
			|	TableOfGoods.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		OR TableOfGoods.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse) AS ThisIsDetailedRecord,
			|	FALSE AS ThisIsAGrouping
			|FROM
			|	TTTableOfGoods AS TableOfGoods
			|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
			|		ON TableOfGoods.Products = ProductRestrictions.Products
			|			AND TableOfGoods.Characteristic = ProductRestrictions.Characteristic
			|			AND TableOfGoods.Warehouse = ProductRestrictions.Warehouse
			|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductGroupingRestrictions
			|		ON (ProductRestrictions.GroupingProductRestrictions = ProductGroupingRestrictions.GroupingProductRestrictions)
			|			AND (VALUE(Catalog.Products.EmptyRef) = ProductGroupingRestrictions.Products)
			|			AND (VALUE(Catalog.Warehouses.EmptyRef) = ProductGroupingRestrictions.Warehouse)
			|WHERE
			|	(&WithoutSelectionByMethods
			|			OR ProductRestrictions.InventoryReplenishmentMethod IN (&InventoryReplenishmentMethods))
			|
			|UNION ALL
			|
			|SELECT
			|	VALUE(Catalog.Products.EmptyRef),
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
			|	VALUE(Catalog.Warehouses.EmptyRef),
			|	DimensionsTable.GroupingProductRestrictions,
			|
			|	ProductRestrictions.InventoryReplenishmentMethod,
			|	ProductRestrictions.MinimumInventoryQuantity,
			|	ProductRestrictions.MaximumInventoryAmount,
			|	ProductRestrictions.ConsumptionRate,
			|	ProductRestrictions.SafetyStockQuantity,
			|	ProductRestrictions.OrderFulfillmentWithinInventoryReplenishment,
			|
			|	ProductRestrictions.OrderPackage,
			|	ProductRestrictions.AverageDailyConsumption,
			|	ProductRestrictions.AverageConsumptionVariance,
			|	ProductRestrictions.ThereIsRecommendationForChange,
			|	ProductRestrictions.RecommendationCalculationDate,
			|	ProductRestrictions.AddlOrderingAttribute,
			|
			|	FALSE,
			|	TRUE
			|FROM
			|	TTDimensionsTable AS DimensionsTable
			|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
			|		ON DimensionsTable.GroupingProductRestrictions = ProductRestrictions.GroupingProductRestrictions
			|			AND (VALUE(Catalog.Products.EmptyRef) = ProductRestrictions.Products)
			|			AND (VALUE(Catalog.Warehouses.EmptyRef) = ProductRestrictions.Warehouse)
			|WHERE
			|	(&WithoutSkippingDimension
			|			OR ProductRestrictions.InventoryReplenishmentMethod IS NULL)
			|	AND (&WithoutSelectionByMethods
			|			OR ProductRestrictions.InventoryReplenishmentMethod IN (&InventoryReplenishmentMethods))
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Products     AS Products,
			|	TableOfGoods.Characteristic   AS Characteristic
			|FROM
			|	TTTableOfGoods AS TableOfGoods
			|WHERE
			|	TableOfGoods.Warehouse.ShopFloorStockroom";
		
		Query.SetParameter("TableOfGoods", TableOfGoods);
		Query.SetParameter("DimensionsTable", DimensionsTable);
		
		Query.SetParameter("WithoutSelectionByMethods", MethodsForSelection = Undefined);
		Query.SetParameter("InventoryReplenishmentMethods", MethodsForSelection);
		
		// If there is already a grouping record when installing the grouping, do not touch it
		Query.SetParameter("WithoutSkippingDimension", Not SettingDimensions);
		
		SetPrivilegedMode(True);
		Result = Query.ExecuteBatch();
		SetPrivilegedMode(False);
		Selection = Result[2].Select();
		SelectionForUpdatingAdditionalBankingDetails = Result[3].Select();
		
		RecordSet = InformationRegisters.ProductRestrictions.CreateRecordSet();
		RegisterRecord = RecordSet.Add();
		RecordsCount = 0;
		
		CommonSettings = GeneralSettingsTable_();
		Groups = TableOfServiceDimensions();
		
		AllResources = "SafetyStockQuantity,MinimumInventoryQuantity,MaximumInventoryAmount,
			|ConsumptionRate,InventoryReplenishmentMethod,OrderPackage,OrderFulfillmentWithinInventoryReplenishment,
			|AverageDailyConsumption,AverageConsumptionVariance";
		
		While Selection.Next() Do
			
			FillPropertyValues(RegisterRecord, Selection);
			
			If Not ExclusionFromGroup Then // when excluded from the group, we take the grouping parameters
				FillPropertyValues(RegisterRecord, ParametersForRecording);
				If Not ResetPreviouslySetMinMax
					And Selection.InventoryReplenishmentMethod = RegisterRecord.InventoryReplenishmentMethod Then
						FillPropertyValues(RegisterRecord, Selection, AllResources);
				EndIf;
			Else
				RegisterRecord.GroupingProductRestrictions = Catalogs.GoodsRestrictionGrouping.EmptyRef();
			EndIf;
			
			If SettingDimensions And Selection.ThisIsAGrouping Then // there is no record for grouping, we will fill in by default
				FillPropertyValues(RegisterRecord, ParametersMinMax());
				RegisterRecord.InventoryReplenishmentMethod = Enums.InventoryReplenishmentMethods.StockReplenishmentMinMax;
			EndIf;
			
			RegisterRecord.ThisIsAValidParameter = ValueIsFilled(Selection.Characteristic)
				Or RegisterRecord.InventoryReplenishmentMethod <> Enums.InventoryReplenishmentMethods.OrderAgainstOrder;
				
			If Selection.ThisIsDetailedRecord Then
				UpdateRecommendationToChangeRegisterEntry(RegisterRecord);
				
				If ValueIsFilled(Selection.Characteristic) Then
					RememberGeneralSettingForUpdate(CommonSettings, Selection.Products, Selection.Warehouse);
				EndIf;
			ElsIf Not Selection.ThisIsAGrouping Then // general setup for the item
				RememberGeneralSettingForUpdate(CommonSettings, Selection.Products, Selection.Warehouse);
			EndIf;
			
			// We remember for which records of the grouping you need to update the props there is a recommendation for modification.
			If SettingDimensions And Not Selection.ThisIsAGrouping Then
				RememberGroupingForUpdates(Groups, Selection.GroupingProductRestrictions, Selection.Warehouse, False);
				RememberGroupingForUpdates(Groups, ParametersForRecording.GroupingProductRestrictions, Selection.Warehouse,
					RegisterRecord.ThereIsRecommendationForChange);
			EndIf;
			
			RecordSet.Filter.Products.Set(Selection.Products);
			RecordSet.Filter.Characteristic.Set(Selection.Characteristic);
			RecordSet.Filter.Warehouse.Set(Selection.Warehouse);
			If Selection.ThisIsAGrouping Then
				RecordSet.Filter.GroupingProductRestrictions.Set(Selection.GroupingProductRestrictions);
			EndIf;
			
			RecordSet.Write();
			RecordSet.Filter.GroupingProductRestrictions.Use = False;
			RecordsCount = RecordsCount + 1;
			
		EndDo;
		
		UpdateRecommendationsForChangingGeneralSettings(CommonSettings, Groups);
		UpdateRecommendationsForChangingDimensions(Groups);
		
		While SelectionForUpdatingAdditionalBankingDetails.Next() Do
			UpdatePropsValuesForOrdering(SelectionForUpdatingAdditionalBankingDetails.Products,
				SelectionForUpdatingAdditionalBankingDetails.Characteristic);
		EndDo;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("vi = 'Ghi vào biểu ghi ""Hạn chế sản phẩm""';
							|ru = 'Запись в регистр ""Товарные ограничения""';
							|en = 'Record to the ""Goods limitations"" register'; fa = 'Record to the ""Goods limitations"" register';
							|it = 'Registrazione nel registro ""Limitazioni sui prodotti""';
							|pl = 'Wpis do rejestru ""Ograniczenia towarowe""';
							|tr = '""Ürün kısıtlamaları"" kaydına kayıt'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	Return RecordsCount;

EndFunction

Procedure Delete(TableOfGoods, DimensionsTable, DeleteDetailed = False)
	
	TableOfGoods.GroupBy("Products,Characteristic,Warehouse");
	DimensionsTable.GroupBy("GroupingProductRestrictions");
	
	BeginTransaction();
	Try
	
		Block = New DataLock;
		
		LockItem = Block.Add("InformationRegister.ProductRestrictions");
		LockItem.DataSource = TableOfGoods;
		LockItem.UseFromDataSource("Products",		"Products");
		LockItem.UseFromDataSource("Characteristic",	"Characteristic");
		LockItem.UseFromDataSource("Warehouse",			"Warehouse");
		
		LockItem = Block.Add("InformationRegister.ProductRestrictions");
		LockItem.DataSource = DimensionsTable;
		LockItem.UseFromDataSource("GroupingProductRestrictions",		"GroupingProductRestrictions");
		
		Block.Lock();
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	TableOfGoods.Products   AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Warehouse          AS Warehouse
			|INTO TTTableOfGoods
			|FROM
			|	&TableOfGoods AS TableOfGoods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DimensionsTable.GroupingProductRestrictions AS GroupingProductRestrictions
			|INTO TTDimensionsTable
			|FROM
			|	&DimensionsTable AS DimensionsTable
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RecordsWithPackages.Products             AS Products,
			|	RecordsWithPackages.Characteristic           AS Characteristic,
			|	RecordsWithPackages.Warehouse                    AS Warehouse,
			|	RecordsWithPackages.GroupingProductRestrictions              AS GroupingProductRestrictions,
			|	MAX(RecordsWithPackages.ThisIsAGrouping) AS EntireDimensionIsDeleted,
			|	RecordsWithPackages.OrderPackage           AS OrderPackage
			|INTO TTRecordTableWithPackages
			|FROM
			|	(SELECT
			|		ProductRestrictions.Products AS Products,
			|		ProductRestrictions.Characteristic AS Characteristic,
			|		ProductRestrictions.Warehouse AS Warehouse,
			|		TableOfDimensionRecords.GroupingProductRestrictions AS GroupingProductRestrictions,
			|		TRUE AS ThisIsAGrouping,
			|		ProductRestrictions.OrderPackage AS OrderPackage
			|	FROM
			|		TTDimensionsTable AS TableOfDimensionRecords
			|			LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
			|			ON TableOfDimensionRecords.GroupingProductRestrictions = ProductRestrictions.GroupingProductRestrictions
			|	WHERE
			|		(ProductRestrictions.OrderPackage <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|				OR ProductRestrictions.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|				OR ProductRestrictions.Products = VALUE(Catalog.Products.EmptyRef))
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		TableOfDimensionRecords.Products,
			|		TableOfDimensionRecords.Characteristic,
			|		TableOfDimensionRecords.Warehouse,
			|		ProductRestrictions.GroupingProductRestrictions,
			|		FALSE,
			|		ProductRestrictions.OrderPackage
			|	FROM
			|		TTTableOfGoods AS TableOfDimensionRecords
			|			LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
			|			ON TableOfDimensionRecords.Products = ProductRestrictions.Products
			|				AND TableOfDimensionRecords.Characteristic = ProductRestrictions.Characteristic
			|				AND TableOfDimensionRecords.Warehouse = ProductRestrictions.Warehouse) AS RecordsWithPackages
			|
			|GROUP BY
			|	RecordsWithPackages.Products,
			|	RecordsWithPackages.Characteristic,
			|	RecordsWithPackages.Warehouse,
			|	RecordsWithPackages.GroupingProductRestrictions,
			|	RecordsWithPackages.OrderPackage
			|
			|INDEX BY
			|	Products,
			|	Warehouse
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	RecordsToDelete.Products                      AS Products,
			|	RecordsToDelete.Characteristic                    AS Characteristic,
			|	RecordsToDelete.Warehouse                             AS Warehouse,
			|	RecordsToDelete.GroupingProductRestrictions                       AS GroupingProductRestrictions,
			|	RecordsToDelete.EntireDimensionIsDeleted           AS EntireDimensionIsDeleted,
			|	RecordsToDelete.OrderPackage                    AS OrderPackage,
			|	NOT CommonSettings.Products IS NULL          AS ThereIsGeneralSetting,
			|	NOT SharedSettingsThatCanBeDeleted.Products IS NULL AS GeneralSettingIsDeleted
			|FROM
			|	TTRecordTableWithPackages AS RecordsToDelete
			|		LEFT JOIN InformationRegister.ProductRestrictions AS CommonSettings
			|		ON RecordsToDelete.Products = CommonSettings.Products
			|			AND RecordsToDelete.Warehouse = CommonSettings.Warehouse
			|			AND (CommonSettings.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
			|			AND (RecordsToDelete.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef))
			|		LEFT JOIN TTRecordTableWithPackages AS SharedSettingsThatCanBeDeleted
			|		ON RecordsToDelete.Products = SharedSettingsThatCanBeDeleted.Products
			|			AND RecordsToDelete.Warehouse = SharedSettingsThatCanBeDeleted.Warehouse
			|			AND (SharedSettingsThatCanBeDeleted.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
			|			AND (RecordsToDelete.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef))
			|TOTALS
			|	MAX(EntireDimensionIsDeleted)
			|BY
			|	RecordsToDelete.GroupingProductRestrictions
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Products     AS Products,
			|	TableOfGoods.Characteristic   AS Characteristic
			|FROM
			|	TTTableOfGoods AS TableOfGoods
			|WHERE
			|	TableOfGoods.Warehouse.ShopFloorStockroom
			|
			|UNION
			|
			|SELECT
			|	ProductRestrictions.Products,
			|	ProductRestrictions.Characteristic
			|FROM
			|	TTDimensionsTable AS TableOfDimensionRecords
			|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
			|		ON TableOfDimensionRecords.GroupingProductRestrictions = ProductRestrictions.GroupingProductRestrictions
			|			AND ProductRestrictions.Products <> VALUE(Catalog.Products.EmptyRef)
			|WHERE
			|	ProductRestrictions.Warehouse.ShopFloorStockroom";
		
		Query.SetParameter("TableOfGoods", TableOfGoods);
		Query.SetParameter("DimensionsTable", DimensionsTable);
		
		SetPrivilegedMode(True);
		Result = Query.ExecuteBatch();
		SetPrivilegedMode(False);
		SelectionGrouping = Result[3].Select(QueryResultIteration.ByGroups);
		SelectionForUpdatingAdditionalBankingDetails = Result[4].Select();
		
		CommonSettings = GeneralSettingsTable_();
		Groups = TableOfServiceDimensions();
		
		While SelectionGrouping.Next() Do
			
			Selection = SelectionGrouping.Select();
			
			While Selection.Next() Do
				
				RecordSet = InformationRegisters.ProductRestrictions.CreateRecordSet();
				
				RecordIsDeleted = Not (ValueIsFilled(Selection.OrderPackage) 
					Or (Selection.ThereIsGeneralSetting And Not Selection.GeneralSettingIsDeleted And Not DeleteDetailed));
			
				If Not RecordIsDeleted Then
					RegisterRecord = RecordSet.Add();
					FillPropertyValues(RegisterRecord, Selection,, "GroupingProductRestrictions");
					RegisterRecord.InventoryReplenishmentMethod = Enums.InventoryReplenishmentMethods.OrderAgainstOrder;
					RegisterRecord.ThisIsAValidParameter = Selection.ThereIsGeneralSetting And Not DeleteDetailed;
					UpdateRecommendationToChangeRegisterEntry(RegisterRecord);
				EndIf;
				
				// We remember for which of the grouping records we need to update the props there is a recommendation for modification.
				ThereIsRecommendationForChange = ?(RecordSet.Count() > 0, RegisterRecord.ThereIsRecommendationForChange, False);
				If Not Selection.EntireDimensionIsDeleted And ValueIsFilled(Selection.GroupingProductRestrictions) Then
					RememberGroupingForUpdates(Groups, Selection.GroupingProductRestrictions, Selection.Warehouse,
						ThereIsRecommendationForChange);
				EndIf;
				If Selection.ThereIsGeneralSetting And Not Selection.GeneralSettingIsDeleted Then
					RememberGeneralSettingForUpdate(CommonSettings, Selection.Products, Selection.Warehouse);
				EndIf;
				
				If Not Selection.EntireDimensionIsDeleted Or Not RecordIsDeleted Then
					RecordSet.Filter.Products.Set(Selection.Products);
					RecordSet.Filter.Characteristic.Set(Selection.Characteristic);
					RecordSet.Filter.Warehouse.Set(Selection.Warehouse);
					RecordSet.Write();
				EndIf;
			
			EndDo;
			
			If SelectionGrouping.EntireDimensionIsDeleted Then
				RecordSet = InformationRegisters.ProductRestrictions.CreateRecordSet();
				RecordSet.Filter.GroupingProductRestrictions.Set(SelectionGrouping.GroupingProductRestrictions);
				RecordSet.Write();
			EndIf;
			
		EndDo;
		
		UpdateRecommendationsForChangingGeneralSettings(CommonSettings, Groups);
		UpdateRecommendationsForChangingDimensions(Groups);
		
		While SelectionForUpdatingAdditionalBankingDetails.Next() Do
			UpdatePropsValuesForOrdering(SelectionForUpdatingAdditionalBankingDetails.Products,
				SelectionForUpdatingAdditionalBankingDetails.Characteristic);
		EndDo;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("vi = 'Xóa các mục trong biểu ghi ''''Hạn chế sản phẩm''''';
							|ru = 'Удаление записей в регистре ""Товарные ограничения""';
							|en = 'Delete records in the ""Goods limitations"" register'; fa = 'Delete records in the ""Goods limitations"" register';
							|it = 'Eliminazione delle registrazioni nel registro ""Limitazioni sui prodotti""';
							|pl = 'Usuwanie wpisów w rejestrze ""Ograniczenia towarowe""';
							|tr = '""Ürün kısıtlamaları"" kaydındaki kayıtların silinmesi'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

Procedure UpdateRecommendationsForChangingGeneralSettings(CommonSettings, Groups)
	
	If CommonSettings.Count() = 0 Then
		Return;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProductRestrictions");
	LockItem.DataSource = CommonSettings;
	LockItem.UseFromDataSource("Products", "Products");
	LockItem.UseFromDataSource("Warehouse", "Warehouse");
	LockItem.Mode = DataLockMode.Shared;
	Block.Lock();

	Query = New Query;
	Query.Text = 
		"SELECT
		|	CommonSettings.Products,
		|	CommonSettings.Warehouse
		|INTO TTGeneralSettings
		|FROM
		|	&CommonSettings AS CommonSettings
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(ISNULL(CASE
		|				WHEN ISNULL(GroupingOfDetailedSettings.InventoryReplenishmentMethod, DetailedSettings_.InventoryReplenishmentMethod) <> VALUE(Enum.InventoryReplenishmentMethods.EmptyRef)
		|						AND ISNULL(GroupingOfDetailedSettings.InventoryReplenishmentMethod, DetailedSettings_.InventoryReplenishmentMethod) <> VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)
		|					THEN DetailedSettings_.ThereIsRecommendationForChange
		|				ELSE NOT DetailedSettings_.ThereIsRecommendationForChange
		|			END, TRUE)) AS ThereIsRecommendationForChange,
		|	ProductRestrictions.Warehouse,
		|	ProductRestrictions.Products,
		|	ProductRestrictions.Characteristic,
		|	ProductRestrictions.GroupingProductRestrictions,
		|	ProductRestrictions.SafetyStockQuantity,
		|	ProductRestrictions.MinimumInventoryQuantity,
		|	ProductRestrictions.MaximumInventoryAmount,
		|	ProductRestrictions.ConsumptionRate,
		|	ProductRestrictions.InventoryReplenishmentMethod,
		|	ProductRestrictions.OrderPackage,
		|	ProductRestrictions.OrderFulfillmentWithinInventoryReplenishment,
		|	ProductRestrictions.AverageDailyConsumption,
		|	ProductRestrictions.AverageConsumptionVariance,
		|	ProductRestrictions.AddlOrderingAttribute,
		|	ProductRestrictions.RecommendationCalculationDate,
		|	ProductRestrictions.ThisIsAValidParameter,
		|	ProductRestrictions.ThisIsAGrouping
		|FROM
		|	TTGeneralSettings AS CommonSettings
		|		LEFT JOIN InformationRegister.ProductRestrictions AS DetailedSettings_
		|			LEFT JOIN InformationRegister.ProductRestrictions AS GroupingOfDetailedSettings
		|			ON DetailedSettings_.GroupingProductRestrictions = GroupingOfDetailedSettings.GroupingProductRestrictions
		|				AND (DetailedSettings_.Warehouse = VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef))
		|		ON CommonSettings.Products = DetailedSettings_.Products
		|			AND CommonSettings.Warehouse = DetailedSettings_.Warehouse
		|			AND (DetailedSettings_.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
		|		ON CommonSettings.Products = ProductRestrictions.Products
		|			AND CommonSettings.Warehouse = ProductRestrictions.Warehouse
		|			AND (ProductRestrictions.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|			AND ProductRestrictions.ThisIsAValidParameter
		|WHERE
		|	NOT ProductRestrictions.Warehouse IS NULL
		|	AND CommonSettings.Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)
		|
		|GROUP BY
		|	ProductRestrictions.Warehouse,
		|	ProductRestrictions.Products,
		|	ProductRestrictions.Characteristic,
		|	ProductRestrictions.GroupingProductRestrictions,
		|	ProductRestrictions.SafetyStockQuantity,
		|	ProductRestrictions.MinimumInventoryQuantity,
		|	ProductRestrictions.MaximumInventoryAmount,
		|	ProductRestrictions.ConsumptionRate,
		|	ProductRestrictions.InventoryReplenishmentMethod,
		|	ProductRestrictions.OrderPackage,
		|	ProductRestrictions.OrderFulfillmentWithinInventoryReplenishment,
		|	ProductRestrictions.AverageDailyConsumption,
		|	ProductRestrictions.AverageConsumptionVariance,
		|	ProductRestrictions.AddlOrderingAttribute,
		|	ProductRestrictions.RecommendationCalculationDate,
		|	ProductRestrictions.ThisIsAValidParameter,
		|	ProductRestrictions.ThisIsAGrouping,
		|	ProductRestrictions.ThereIsRecommendationForChange
		|
		|HAVING
		|	MIN(ISNULL(CASE
		|				WHEN DetailedSettings_.InventoryReplenishmentMethod <> VALUE(Enum.InventoryReplenishmentMethods.EmptyRef)
		|						AND DetailedSettings_.InventoryReplenishmentMethod <> VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)
		|					THEN DetailedSettings_.ThereIsRecommendationForChange
		|				ELSE NOT DetailedSettings_.ThereIsRecommendationForChange
		|			END, TRUE)) <> ProductRestrictions.ThereIsRecommendationForChange";
		
	Query.SetParameter("CommonSettings", CommonSettings);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProductRestrictions");
	LockItem.DataSource = QueryResult;
	LockItem.UseFromDataSource("Products",		"Products");
	LockItem.UseFromDataSource("Characteristic",	"Characteristic");
	LockItem.UseFromDataSource("Warehouse",			"Warehouse");
	Block.Lock();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		Set = InformationRegisters.ProductRestrictions.CreateRecordSet();
		Set.Filter.Products.Set(Selection.Products);
		Set.Filter.Characteristic.Set(Selection.Characteristic);
		Set.Filter.Warehouse.Set(Selection.Warehouse);
		
		RegisterRecord = Set.Add();
		FillPropertyValues(RegisterRecord, Selection);
		
		If ValueIsFilled(Selection.GroupingProductRestrictions) Then
			RememberGroupingForUpdates(Groups, Selection.GroupingProductRestrictions, Selection.Warehouse, Selection.ThereIsRecommendationForChange);
		EndIf;
		
		Set.Write();
		
	EndDo;
	
EndProcedure

Procedure UpdateRecommendationsForChangingDimensions(Groups)
	
	If Groups.Count() = 0 Then
		Return;
	EndIf;
	
	RowFilter = New Structure("ThereIsRecommendationForChange", False);
	NoRecommendations = Groups.Copy(Groups.FindRows(RowFilter));
	
	Groups.Columns.Add("RecordsCount", New TypeDescription("Number"));
	
	If NoRecommendations.Count() > 0 Then
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ProductRestrictions");
		LockItem.DataSource = NoRecommendations;
		LockItem.UseFromDataSource("GroupingProductRestrictions",	"GroupingProductRestrictions");
		LockItem.UseFromDataSource("Warehouse",		"Warehouse");
		LockItem.Mode = DataLockMode.Shared;
		Block.Lock();
	
		Query = New Query;
		Query.Text = 
			"SELECT
			|	NoRecommendations.GroupingProductRestrictions,
			|	NoRecommendations.Warehouse
			|INTO TTDimensions
			|FROM
			|	&NoRecommendations AS NoRecommendations
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Groups.GroupingProductRestrictions AS GroupingProductRestrictions,
			|	Groups.Warehouse AS Warehouse,
			|	MAX(ISNULL(ProductRestrictions.ThereIsRecommendationForChange, FALSE)) AS ThereIsRecommendationForChange,
			|	COUNT(ProductRestrictions.Products) AS RecordsCount
			|FROM
			|	TTDimensions AS Groups
			|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
			|		ON Groups.GroupingProductRestrictions = ProductRestrictions.GroupingProductRestrictions
			|			AND Groups.Warehouse = ProductRestrictions.Warehouse
			|			AND (ProductRestrictions.Products <> VALUE(Catalog.Products.EmptyRef))
			|
			|GROUP BY
			|	Groups.GroupingProductRestrictions,
			|	Groups.Warehouse";
			
		Query.SetParameter("NoRecommendations", NoRecommendations);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		
		While Selection.Next() Do
			RowFilter = New Structure("GroupingProductRestrictions, Warehouse", Selection.GroupingProductRestrictions, Selection.Warehouse);
			FillPropertyValues(Groups.FindRows(RowFilter)[0], Selection);
		EndDo;
	EndIf;
	
	Groups.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProductRestrictions");
	LockItem.DataSource = Groups;
	LockItem.UseFromDataSource("Products",		"Products");
	LockItem.UseFromDataSource("Warehouse",			"Warehouse");
	LockItem.UseFromDataSource("GroupingProductRestrictions",		"GroupingProductRestrictions");
	Block.Lock();
	
	For Each Setting In Groups Do
		Set = InformationRegisters.ProductRestrictions.CreateRecordSet();
		Set.Filter.Products.Set(Setting.Products);
		Set.Filter.Warehouse.Set(Setting.Warehouse);
		Set.Filter.GroupingProductRestrictions.Set(Setting.GroupingProductRestrictions);
		If Not Setting.ThereIsRecommendationForChange And Setting.RecordsCount = 0 Then 
			// There are no goods in the warehouse in the grouping, the service record is not needed
			Set.Write();
		Else
			Set.Read();
			Write = False;
			If Set.Count() = 0 Then
				// The first item in the warehouse in the grouping, we will add a service record
				RegisterRecord = Set.Add();
				RegisterRecord.Warehouse					= Setting.Warehouse;
				RegisterRecord.GroupingProductRestrictions				= Setting.GroupingProductRestrictions;
				RegisterRecord.ThisIsAValidParameter	= True;
				RegisterRecord.ThisIsAGrouping			= True;
				Write = True;
			EndIf;
			If Set[0].ThereIsRecommendationForChange <> Setting.ThereIsRecommendationForChange Or Write Then
				Set[0].ThereIsRecommendationForChange = Setting.ThereIsRecommendationForChange;
				Set.Write();
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure UpdateRecommendationToChangeRegisterEntry(RegisterRecord)
	
	ConsumptionIsStable = RegisterRecord.AverageDailyConsumption > 0
		And RegisterRecord.AverageConsumptionVariance / RegisterRecord.AverageDailyConsumption < 0.05;
	StockIsSupported = ValueIsFilled(RegisterRecord.GroupingProductRestrictions)
		Or ValueIsFilled(RegisterRecord.InventoryReplenishmentMethod)
			And RegisterRecord.InventoryReplenishmentMethod <> Enums.InventoryReplenishmentMethods.OrderAgainstOrder;
	RegisterRecord.ThereIsRecommendationForChange = (ConsumptionIsStable And Not StockIsSupported)
		Or (Not ConsumptionIsStable And StockIsSupported);
	
EndProcedure

Procedure SubstituteSelectionFieldExpressions(SubstitutionResult, Fields, TableSynonym)

	For Each Field In Fields Do

		SearchSubstring = TableSynonym + "." + Field.Name;
		ReplaceSubstring = "	ISNULL(DetailedSetup.Name, ISNULL(SettingUpAGrouping.Name, ISNULL(GeneralSetting.Name, ConfiguringGroupingOfGeneralSettings.Name)))";
		ReplaceSubstring = StrReplace(ReplaceSubstring, "Name", Field.Name);
		SubstitutionResult = StrReplace(SubstitutionResult, SearchSubstring, ReplaceSubstring);

	EndDo;

EndProcedure

Procedure UpdatePropsValuesForOrdering(Products, Characteristic)
	
	DataLock = New DataLock;
	
	LockItem = DataLock.Add("InformationRegister.ProductRestrictions");
	LockItem.SetValue("Products",	Products);
	LockItem.SetValue("Characteristic",	Characteristic);
	
	DataLock.Lock();
	
	Query = New Query(
	"SELECT
	|	CASE
	|		WHEN Table.Products <> VALUE(Catalog.Products.EmptyRef)
	|				AND Table.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				AND Table.GroupingProductRestrictions = VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
	|			THEN 1
	|		WHEN Table.Products <> VALUE(Catalog.Products.EmptyRef)
	|				AND Table.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				AND Table.GroupingProductRestrictions = VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
	|			THEN 2
	|		ELSE 3
	|	END                                               AS NumberOfGroup,
	|	Table.Warehouse                                       AS Warehouse,
	|	Table.Products                                AS Products,
	|	Table.Characteristic                              AS Characteristic,
	|	Table.GroupingProductRestrictions                                 AS GroupingProductRestrictions,
	|	Table.SafetyStockQuantity                   AS SafetyStockQuantity,
	|	Table.MinimumInventoryQuantity                 AS MinimumInventoryQuantity,
	|	Table.MaximumInventoryAmount                AS MaximumInventoryAmount,
	|	Table.ConsumptionRate                            AS ConsumptionRate,
	|	Table.InventoryReplenishmentMethod                AS InventoryReplenishmentMethod,
	|	Table.OrderPackage                              AS OrderPackage,
	|	Table.OrderFulfillmentWithinInventoryReplenishment      AS OrderFulfillmentWithinInventoryReplenishment,
	|	Table.AverageDailyConsumption                    AS AverageDailyConsumption,
	|	Table.AverageConsumptionVariance                AS AverageConsumptionVariance,
	|	Table.AddlOrderingAttribute                   AS AddlOrderingAttribute,
	|	Table.RecommendationCalculationDate                     AS RecommendationCalculationDate,
	|	Table.ThisIsAValidParameter                      AS ThisIsAValidParameter,
	|	Table.ThereIsRecommendationForChange                 AS ThereIsRecommendationForChange,
	|	Table.ThisIsAGrouping                              AS ThisIsAGrouping,
	|	ISNULL(Table.Warehouse.Department, UNDEFINED) AS Department,
	|	ISNULL(Table.Warehouse.ShopFloorStockroom, FALSE)       AS ShopFloorStockroom,
	|	Table.ThisIsAValidParameter
	|		AND (Table.GroupingProductRestrictions <> VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
	|			OR Table.InventoryReplenishmentMethod <> VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)) AS StockIsSupported
	|FROM
	|	InformationRegister.ProductRestrictions AS Table
	|WHERE
	|	Table.Products = &Products
	|	AND Table.Characteristic = &Characteristic
	|
	|ORDER BY
	|	NumberOfGroup,
	|	Department,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.GroupingProductRestrictions,
	|	Table.AddlOrderingAttribute");
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	
	SetPrivilegedMode(True);
	RecordsTable = Query.Execute().Unload();
	
	If RecordsTable.Count() = 0 
		Or RecordsTable.Find(True, "ShopFloorStockroom") = Undefined Then
		// There is no change of records on shop storerooms
		Return;
	EndIf;
	
	OrderingAttributeValues = 0;
	PreviousRecord = New Structure("NumberOfGroup, Department, Products, Characteristic");
	
	// Creating a recordset
	RecordSet = InformationRegisters.ProductRestrictions.CreateRecordSet();
	RecordSet.Filter.Products.Set(Products);
	RecordSet.Filter.Characteristic.Set(Characteristic);
	
	// You need to process the following combinations
	// Division, Nomenclature, Characteristic, Group not specified
	// Division, Nomenclature, Characteristic not specified, Group not specified
	// Division, Nomenclature, Characteristic, Group.
	For Each Selection In RecordsTable Do
		
		If Not Selection.ShopFloorStockroom Or Not Selection.StockIsSupported Then
			// The record does not relate to the workshop storeroom or the stock is not maintained for it, so we record it as is.
			NewRecord = RecordSet.Add();
			FillPropertyValues(NewRecord, Selection);
			NewRecord.AddlOrderingAttribute = 0;
			Continue;
		EndIf;
			
		// The entry does not differ from the previous one
		If Selection.NumberOfGroup = PreviousRecord.NumberOfGroup 
			And Selection.Department = PreviousRecord.Department 
			And Selection.Products = PreviousRecord.Products 
			And Selection.Characteristic = PreviousRecord.Characteristic Then
			
			// The following ordering value
			OrderingAttributeValues = OrderingAttributeValues + 1;
			
		Else
			
			// Saving the current record
			FillPropertyValues(PreviousRecord, Selection);
			OrderingAttributeValues = 1;
			
		EndIf;
		
		NewRecord = RecordSet.Add();
		FillPropertyValues(NewRecord, Selection);
		NewRecord.AddlOrderingAttribute = OrderingAttributeValues;
			
	EndDo;
	
	RecordSet.Write(True);
	
EndProcedure

#EndIf
