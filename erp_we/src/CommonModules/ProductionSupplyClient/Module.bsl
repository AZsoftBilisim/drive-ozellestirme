#Region Internal

#Region BOMsTree

// Procedure for filling in the tree of leftovers in Forms
// 
// Parameters:
//  Form - See DataProcessor.BillsOfMaterialsTree.Form.Form
//  ItemData - Structure - information about the nomenclature and characteristics:
//  * Products - CatalogRef.Products	- Products
//  * Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the nomenclature
//
Procedure FillInGoodsBalanceTree(Form, ItemData) Export

	StockInWarehouses = Form.StockBalance.GetItems();
	StockInWarehouses.Clear();
	
	GoodsInformation = ProductionSupplyServerCall.StructureOfFillingInBalanceOfGoods(ItemData);

	SalePriceOfGoods = GoodsInformation.Price;
	
	PackageNameUnitsOfMeasurement = ?(ValueIsFilled(SalePriceOfGoods.Package), 
		String(SalePriceOfGoods.Package), 
		String(SalePriceOfGoods.UnitOfMeasure));
	
	CurrentSessionDate = Form.CurrentSessionDate;
	
	For Each TBLString In GoodsInformation.CurrentItemsBalance Do
		
		InventoryBalancesLine = StockInWarehouses.Add();
		
		InventoryBalancesLine.Period = CurrentSessionDate;
		InventoryBalancesLine.PeriodDescription = NStr("vi = 'Hiện tại';
														|ru = 'Сейчас';
														|en = 'Now'; fa = 'اکنون';
														|it = 'Сейчас';
														|pl = 'Now';
														|tr = 'Şimdi'");
		InventoryBalancesLine.Available = TBLString.AvailableForInventoryAllocation;
		InventoryBalancesLine.Inventory = TBLString.Inventory;
		
		InventoryBalancesLine.StockDescription = DescriptionOfQuantityInBalanceLine(
			InventoryBalancesLine.Inventory,
			PackageNameUnitsOfMeasurement);
		
		InventoryBalancesLine.DescriptionAvailable = DescriptionOfQuantityInBalanceLine(
			InventoryBalancesLine.Available,
			PackageNameUnitsOfMeasurement);
		
		InventoryBalancesLine.Warehouse = TBLString.Warehouse;
		InventoryBalancesLine.WarehouseDescription = String(TBLString.Warehouse);
		
		PlannedBalancesByDate = InventoryBalancesLine.GetItems();
			
		ThereArePlannedRemnants = False;
		For Each TBLString In GoodsInformation.PlannedBalances_ Do
			
			If Not (TBLString.Warehouse = InventoryBalancesLine.Warehouse) Then
				Continue;
			EndIf;
			
			ThereArePlannedRemnants = True;
			
			LinePlannedBalancesByDate = PlannedBalancesByDate.Add();
			
			LinePlannedBalancesByDate.Period = TBLString.Period;
			LinePlannedBalancesByDate.PeriodDescription = Format(TBLString.Period, "DLF=D");
			LinePlannedBalancesByDate.Available = TBLString.Available;
			LinePlannedBalancesByDate.Inventory = TBLString.Inventory;
			
			LinePlannedBalancesByDate.StockDescription = DescriptionOfQuantityInBalanceLine(
				LinePlannedBalancesByDate.Inventory,
				PackageNameUnitsOfMeasurement);
			
			LinePlannedBalancesByDate.DescriptionAvailable = DescriptionOfQuantityInBalanceLine(
				LinePlannedBalancesByDate.Available,
				PackageNameUnitsOfMeasurement);
			
			LinePlannedBalancesByDate.Warehouse = TBLString.Warehouse;
			LinePlannedBalancesByDate.WarehouseDescription = "";
			
		EndDo;
		
		If InventoryBalancesLine.Inventory = 0 And Not ThereArePlannedRemnants Then
			StockInWarehouses.Delete(InventoryBalancesLine);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Returns a string description of the quantity. Used when displaying rows in the Balance table.
//
// Parameters:
//  Count - Number - amount of goods,
//	PackageNameUnitsOfMeasurement - String - package name, units of measurement,
//
// Returns:
//	String - Description of the number of products for the Cur line in the selection Form.
//
Function DescriptionOfQuantityInBalanceLine(Count, PackageNameUnitsOfMeasurement)
	
	QuantityDescription = "";
	
	If ValueIsFilled(Count) Then
			QuantityDescription = Format(Count,"NFD=3") + " " + PackageNameUnitsOfMeasurement;
	EndIf;
	
	Return QuantityDescription;
	
EndFunction

#EndRegion