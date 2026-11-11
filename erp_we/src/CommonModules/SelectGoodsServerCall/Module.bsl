
#Region Public

#Region SearchOnSelectionForms

// This procedure updates the full-text search index in privileged mode.
//
Procedure UpdateFullTextSearchIndex() Export
	
	SetPrivilegedMode(True);
	FullTextSearch.UpdateIndex();
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region GeneralPurposeProceduresAndFunctions

// The function returns the item storage package, i.e. a package with a factor of 1 and
//  a storage unit corresponding to the item storage unit.
//
// Parameters:
//  Products - CatalogRef.Products - Nomenclature.
// 
// Returns:
//  CatalogRef.PackagesAndUnitsOfMeasure - storage package or unit of measurement of the item.
//
Function GetStoragePackaging(Products) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CatProducts.UnitOfMeasure AS UnitOfMeasure,
	|	PRESENTATION(CatProducts.UnitOfMeasure) AS UnitOfMeasurePresentation,
	|	ISNULL(CatPackages.Ref, UNDEFINED) AS Package,
	|	PRESENTATION(CatPackages.Ref) AS PackagePresentation,
	|	ISNULL(CatPackages.UnitOfMeasure, UNDEFINED) AS PackingUnit,
	|	ISNULL(CatPackages.UnitOfMeasure.Presentation, """") AS PackingUnitPresentation,
	|	ISNULL(&QueryTextPackagingFactor, 0) AS ZoomRatio
	|FROM
	|	Catalog.Products AS CatProducts
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS CatPackages
	|		ON (CatPackages.Owner = CASE
	|			WHEN CatProducts.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|				THEN CatProducts.Ref
	|			WHEN CatProducts.PackagingGroup <> VALUE(Catalog.PackagingGroups.EmptyRef)
	|				THEN CatProducts.PackagingGroup
	|			ELSE FALSE
	|		END)
	|		AND (NOT CatPackages.DeletionMark)
	|WHERE
	|	CatProducts.Ref = &Products
	|	AND ISNULL(&QueryTextPackagingFactor, 0) = 1
	|	AND ISNULL(CatPackages.UnitOfMeasure, UNDEFINED) = CatProducts.UnitOfMeasure
	|	AND ISNULL(CatPackages.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|ORDER BY
	|	ZoomRatio,
	|	PackingUnitPresentation";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"CatPackages", Undefined));
		
	Query.SetParameter("Products", Products);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		Return Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		
	EndIf;
		
	Selection = QueryResult.Select();
	Selection.Next();
	
	Return Selection.Package;
	
EndFunction

// Returns a structure with information about the sale price and the remaining goods.
//
// Parameters:
// 	Parameters - See SelectGoodsClientServer.NewParametersForGettingPriceAndBalanceOfGoods
//
// Returns:
// 	Structure:
// 		* CurrentItemsBalance - Array of Structure:
// 			** Warehouse - CatalogRef.Warehouses
// 			** InStock - Number
// 			** AvailableForInventoryAllocation - Number
// 		* PlannedBalances_ - Array of Structure:
// 			** Warehouse - CatalogRef.Warehouses
// 			** Period - Date
// 			** Available - Number
// 		* Price - Structure:
// 			** Price - Number
// 			** Package - CatalogRef.PackagesAndUnitsOfMeasure
// 			** UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
// 			** PriceKind - CatalogRef.TypesOfPrices
// 			** LongDesc - String
// 			** DeliveryPeriodDays - Date
//
Function SalePriceAndProductBalances(Parameters) Export
	
	CurrentItemsBalance = New Array();
	PlannedBalances_ = New Array();
	
	SellingPrice = New Structure();
	SellingPrice.Insert("PriceKind", Catalogs.TypesOfPrices.EmptyRef());
	SellingPrice.Insert("Price", 0);
	SellingPrice.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	SellingPrice.Insert("UnitOfMeasure", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	SellingPrice.Insert("LongDesc", "");
	SellingPrice.Insert("DeliveryPeriodDays", Date(1, 1, 1));
	
	If Parameters.GetBalance
		Or Parameters.GetPrice Then
		
		QuerySections = Undefined;
		
		Query = New Query;
		Query.SetParameter("Products", Parameters.Products);
		Query.SetParameter("Characteristic", Parameters.Characteristic);
		Query.SetParameter("Currency", Parameters.Currency);
		Query.SetParameter("Terms", Parameters.Terms);
		Query.SetParameter("CurrentDate", EndOfDay(CurrentSessionDate()));
		Query.SetParameter("TypesOfPrices", Parameters.TypesOfPrices);
		Query.SetParameter("Warehouses", Parameters.Warehouses);
		Query.SetParameter("ControlledLotReference", Parameters.ControlledLotReference);
		
		ZoomRatio = 1;
		
		// sales price
		If Parameters.GetPrice Then
			
			Query.Text = SelectGoodsServer.QueryTextSalePriceOfGoods(QuerySections);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				
				ZoomRatio = Selection.ZoomRatio;
				FillPropertyValues(SellingPrice, Selection);
				
			EndIf;
			
		EndIf;
		
		// planned and current Balances
		If Parameters.GetBalance Then
			
			CurrentWarehouse = Undefined;
			
			Query.Text = ProvisionInDocumentsServer.RequestTextForAvailableBalancesByDateForMatching(
				ValueIsFilled(Parameters.Characteristic),
				QuerySections,
				Parameters.ControlledLotReference);
			
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				
				If Selection.Warehouse <> CurrentWarehouse Then
					
					NewRow = New Structure("Warehouse,Inventory,AvailableForInventoryAllocation");
					FillPropertyValues(NewRow, Selection);
					NewRow.AvailableForInventoryAllocation = ?(Selection.State = 0, Selection.AvailableForInventoryAllocation, 0) / ZoomRatio;
					NewRow.Inventory = ?(Selection.State = 0, Selection.Inventory, 0) / ZoomRatio;
					CurrentItemsBalance.Add(NewRow);
					
					CurrentWarehouse = Selection.Warehouse;
					AvailableByDate = 0;
					StockByDate = 0;
					
				EndIf;
				
				AvailableByDate = AvailableByDate + Selection.AvailableForInventoryAllocation;
				StockByDate = StockByDate + Selection.Inventory;
				
				If Selection.State = 1 Then
					
					NewRow = New Structure;
					NewRow.Insert("Warehouse");
					NewRow.Insert("Period");
					NewRow.Insert("Inventory");
					NewRow.Insert("Available");
					
					FillPropertyValues(NewRow, Selection);
					NewRow.Available = AvailableByDate / ZoomRatio;
					NewRow.Inventory = StockByDate / ZoomRatio;
					PlannedBalances_.Add(NewRow);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return New Structure("CurrentItemsBalance, PlannedBalances_, Price",
		CurrentItemsBalance,
		PlannedBalances_,
		SellingPrice);
	
EndFunction

// Returns structure - information about the purchase price and product balances.
//
// Parameters:
// 	Parameters - See SelectGoodsClientServer.NewParametersForGettingPriceAndBalanceOfGoods
//
// Returns:
// 	Structure:
// 		* CurrentItemsBalance - Array of Structure:
// 			** Warehouse - CatalogRef.Warehouses
// 			** InStock - Number
// 			** AvailableForInventoryAllocation - Number
// 		* PlannedBalances_ - Array of Structure:
// 			** Warehouse - CatalogRef.Warehouses
// 			** Period - Date
// 			** Available - Number
// 		* Price - Structure:
// 			** Price - Number
// 			** Package - CatalogRef.PackagesAndUnitsOfMeasure
// 			** UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
//
Function PurchasePriceAndProductBalances(Parameters) Export
	
	CurrentItemsBalance = New Array();
	PlannedBalances_ = New Array();
	
	PurchasePrice = New Structure();
	PurchasePrice.Insert("Price", 0);
	PurchasePrice.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	PurchasePrice.Insert("UnitOfMeasure", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	
	If Parameters.GetBalance
		Or Parameters.GetPrice Then
		
		QuerySections = Undefined;
		
		Query = New Query;
		Query.SetParameter("Products", Parameters.Products);
		Query.SetParameter("Characteristic", Parameters.Characteristic);
		Query.SetParameter("Currency", Parameters.Currency);
		Query.SetParameter("Terms", Parameters.Terms);
		Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
		Query.SetParameter("Warehouses", Parameters.Warehouses);
		
		ZoomRatio = 1;
		
		// purchase price
		If Parameters.GetPrice Then
			
			Query.Text = SelectGoodsServer.QueryTextPurchasePrice_(QuerySections);
			
			If SelectGoodsServer.ThereAreProductPriceValuesLaterThanPickUpDate(CurrentSessionDate()) Then
				
				Query.Text = StrReplace(Query.Text,
					"&PricesOfSupplierProductsCutByDate",
					"ENDOFPERIOD(&CurrentDate, DAY)");
				
			Else
				
				Query.Text = StrReplace(Query.Text,
					"&PricesOfSupplierProductsCutByDate",
					"");
				
			EndIf;
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				
				ZoomRatio = Selection.ZoomRatio;
				FillPropertyValues(PurchasePrice, Selection);
				
			EndIf;
			
		EndIf;
		
		// planned and current Balances
		If Parameters.GetBalance Then
			
			CurrentWarehouse = Undefined;
			
			Query.Text = ProvisionInDocumentsServer.RequestTextForAvailableBalancesByDateForMatching(
				ValueIsFilled(Parameters.Characteristic),
				QuerySections,
				Undefined);
			
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				
				If Selection.Warehouse <> CurrentWarehouse Then
					
					NewRow = New Structure("Warehouse,Inventory,AvailableForInventoryAllocation");
					FillPropertyValues(NewRow, Selection);
					NewRow.AvailableForInventoryAllocation = ?(Selection.State = 0, Selection.AvailableForInventoryAllocation, 0) / ZoomRatio;
					NewRow.Inventory = ?(Selection.State = 0, Selection.Inventory, 0) / ZoomRatio;
					CurrentItemsBalance.Add(NewRow);
					
					CurrentWarehouse = Selection.Warehouse;
					AvailableByDate = 0;
					StockByDate = 0;
					
				EndIf;
				
				AvailableByDate = AvailableByDate + Selection.AvailableForInventoryAllocation;
				StockByDate = StockByDate + Selection.Inventory;
				
				If Selection.State = 1 Then
					
					NewRow = New Structure;
					NewRow.Insert("Warehouse");
					NewRow.Insert("Period");
					NewRow.Insert("Inventory");
					NewRow.Insert("Available");
					
					FillPropertyValues(NewRow, Selection);
					NewRow.Available = AvailableByDate / ZoomRatio;
					NewRow.Inventory = StockByDate / ZoomRatio;
					PlannedBalances_.Add(NewRow);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return New Structure("CurrentItemsBalance, PlannedBalances_, Price",
		CurrentItemsBalance,
		PlannedBalances_,
		PurchasePrice);
	
EndFunction

#EndRegion

#Region AuxiliarySelections

// The function returns a list of string values of the item's item details or
//  additional item details. Used when navigating through the item view
//  and the item view property tree.
//
// Parameters:
//  ProductKind		 - CatalogRef.ItemKinds - item type,
//  AttributeName		 - String							 - the name of the props,
//  IsAddlAttribute		 - Boolean		 					 - True - a sign of additional.requisite's,
//  FilterRemainingGoodsByShelfLives	 - Boolean 							 - The truth is the symptom of a selection item.
// 
// Returns:
//  ValueList of String - List of string values of the props or add.props.
//
Function ListOfPropsValues(ProductKind, AttributeName, IsAddlAttribute, FilterRemainingGoodsByShelfLives) Export
	
	AttributeValues = New ValueList;
	
	Query = New Query;
	Query.SetParameter("ProductKind", ProductKind);
	
	If Not IsAddlAttribute Then
		
		Query.Text =
		"SELECT DISTINCT TOP 50
		|	&AttributeName AS AttributeValue
		|FROM
		|	Catalog.Products AS Products
		|WHERE
		|	Products.ProductKind = &ProductKind
		|	AND &AttributeName <> """"
		|	";
		
		Query.Text = StrReplace(Query.Text,
			"&AttributeName",
			"Products." + AttributeName);
		
	ElsIf FilterRemainingGoodsByShelfLives Then
		
		Query.Text =
		"SELECT DISTINCT TOP 50
		|	AdditionalAttributes.Value AS AttributeValue
		|FROM
		|	Catalog.Products.AdditionalAttributes AS AdditionalAttributes
		|WHERE
		|	AdditionalAttributes.Property.Description = &Property
		|	AND AdditionalAttributes.Ref.ProductKind = &ProductKind";
		
		Query.SetParameter("Property", AttributeName);
		
	ElsIf Not FilterRemainingGoodsByShelfLives Then
		
		Query.Text =
		"SELECT DISTINCT
		|	CharacteristicsAdditionalDetails_.Value AS AttributeValue
		|FROM
		|	Catalog.ItemsCharacteristics.AdditionalAttributes AS CharacteristicsAdditionalDetails_
		|WHERE
		|	CharacteristicsAdditionalDetails_.Property.Description = &Property
		|	AND CASE
		|			WHEN VALUETYPE(CharacteristicsAdditionalDetails_.Ref.Owner) = TYPE(Catalog.ItemKinds)
		|				THEN CharacteristicsAdditionalDetails_.Ref.Owner = &ProductKind
		|			ELSE CharacteristicsAdditionalDetails_.Ref.Owner.ProductKind = &ProductKind
		|		END";
		
		Query.SetParameter("Property", AttributeName);
		
	EndIf;

	ArrayOfValues = Query.Execute().Unload().UnloadColumn("AttributeValue");
	AttributeValues.LoadValues(ArrayOfValues);
	
	Return AttributeValues;
	
EndFunction

#EndRegion

#EndRegion
