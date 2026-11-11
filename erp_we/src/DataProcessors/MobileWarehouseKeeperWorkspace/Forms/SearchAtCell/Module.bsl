
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Cell = Parameters.Cell;
	ShowProductPhotos = Parameters.ShowProductPhotos;
	
	FillInBalanceOfGoods();
	
EndProcedure

Procedure FillInBalanceOfGoods()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	GoodsInStorageBinsBalance.Products AS Products,
		|	GoodsInStorageBinsBalance.Products.SKU AS SKU,
		|	GoodsInStorageBinsBalance.Characteristic AS Characteristic,
		|	GoodsInStorageBinsBalance.Purpose AS Purpose,
		|	CASE
		|		WHEN GoodsInStorageBinsBalance.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN GoodsInStorageBinsBalance.Products.UnitOfMeasure
		|		ELSE GoodsInStorageBinsBalance.Package
		|	END AS Package,
		|	GoodsInStorageBinsBalance.Series AS Series,
		|	GoodsInStorageBinsBalance.InStockBalance AS Count
		|FROM
		|	AccumulationRegister.GoodsInStorageBins.Balance(, Cell = &Cell) AS GoodsInStorageBinsBalance";
	
	Query.SetParameter("Cell", Cell);
	
	QueryResult = Query.Execute().Unload();
	Goods.Load(QueryResult);
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.Count);
	FormParameters.Insert("Mode", "View");
	FormParameters.Insert("LineNumber", Item.CurrentRow);
	FormParameters.Insert("Warehouse", CellStorage(Cell));
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
	ThisForm,,,,,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtServerNoContext
Function CellStorage(Cell)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	StorageBins.Owner AS Warehouse
		|FROM
		|	Catalog.StorageBins AS StorageBins
		|WHERE
		|	StorageBins.Ref = &Cell";
	
	Query.SetParameter("Cell", Cell);
	
	QueryResult = Query.Execute(); 
	
	If QueryResult.IsEmpty() Then
		Return Catalogs.StorageBins.EmptyRef();
	EndIf;
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		Return SelectionDetailRecords.Warehouse;
	EndDo;
	
EndFunction
