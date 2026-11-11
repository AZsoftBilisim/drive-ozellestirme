
#Region Internal

#Region BOMsTree

// Returns structure - information about the Balance of the product
//
// Parameters:
//  ItemData - Structure - information about the nomenclature and characteristics:
//  * Products	 	- CatalogRef.Products	- nomenclature,
//  * Characteristic	- CatalogRef.ItemsCharacteristics - characteristics of the nomenclature
// 
// Returns:
//  See SelectGoodsServerCall.SalePriceAndProductBalances
//
Function StructureOfFillingInBalanceOfGoods(ItemData) Export
	
	WarehousesList = New ValueList;
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	Warehouses.Ref AS Warehouse
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	NOT Warehouses.IsFolder";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		WarehousesList.Add(Selection.Warehouse);
	EndDo;
	
	SetPrivilegedMode(True);
	
	ParametersForGettingPriceAndBalances = SelectGoodsClientServer.NewParametersForGettingPriceAndBalanceOfGoods();
	ParametersForGettingPriceAndBalances.Products = ItemData.Products;
	ParametersForGettingPriceAndBalances.Characteristic = ItemData.Characteristic;
	ParametersForGettingPriceAndBalances.Terms = Catalogs.TermsOfSale.EmptyRef();
	ParametersForGettingPriceAndBalances.Currency = Catalogs.Currencies.EmptyRef();
	ParametersForGettingPriceAndBalances.Warehouses = WarehousesList;
	ParametersForGettingPriceAndBalances.TypesOfPrices = Catalogs.TypesOfPrices.EmptyRef();
	ParametersForGettingPriceAndBalances.ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	ParametersForGettingPriceAndBalances.GetBalance = True;
	ParametersForGettingPriceAndBalances.GetPrice = True;
	
	FillingStructure = SelectGoodsServerCall.SalePriceAndProductBalances(ParametersForGettingPriceAndBalances);
	
	Return FillingStructure;
	
EndFunction

#EndRegion

#EndRegion