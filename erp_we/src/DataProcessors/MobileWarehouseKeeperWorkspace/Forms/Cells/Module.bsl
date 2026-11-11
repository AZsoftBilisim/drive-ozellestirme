
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Query = New Query;
	
#If MobileStandaloneServer Then
	
	Query.Text = 
	"SELECT
	|	StorageBins.Ref AS Cell
	|FROM
	|	Catalog.StorageBins AS StorageBins
	|WHERE
	|	StorageBins.Owner = &Warehouse
	|	AND StorageBins.Premise = &Premise
	|	AND NOT StorageBins.DeletionMark";
	
	Query.SetParameter("Warehouse",              Parameters.Warehouse);
	Query.SetParameter("Premise",          Parameters.Premise);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		NewRow = Cells.Add();
		NewRow.Cell = SelectionDetailRecords.Cell;
	EndDo;
	
#Else
	
	If Parameters.Mode = "PlacementInCell" Or Parameters.Mode = "EditingPlacementByCells" 
		Or Parameters.Mode = "Recalculate" Or Parameters.Mode = "EditingRecalculation" Then
		
		Query.Text = 
		"SELECT
		|	StorageBins.Ref AS Cell
		|INTO TTCells
		|FROM
		|	Catalog.StorageBins AS StorageBins
		|WHERE
		|	StorageBins.Owner = &Warehouse
		|	AND StorageBins.Premise = &Premise
		|	AND NOT StorageBins.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTCells.Cell AS Cell,
		|	ISNULL(GoodsInStorageBinsBalance.InStockBalance, 0) AS InStockBalance,
		|	ISNULL(GoodsInStorageBinsBalance.Package, """") AS Package
		|FROM
		|	TTCells AS TTCells
		|		LEFT JOIN AccumulationRegister.GoodsInStorageBins.Balance(
		|				,
		|				Products = &Products
		|					AND Characteristic = &Characteristic
		|					AND Series = &Series) AS GoodsInStorageBinsBalance
		|		ON TTCells.Cell = GoodsInStorageBinsBalance.Cell
		|
		|ORDER BY
		|	GoodsInStorageBinsBalance.InStockBalance DESC,
		|	GoodsInStorageBinsBalance.Cell.TabIndex";
		
	Else
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	GoodsInStorageBinsBalance.Cell AS Cell,
		|	GoodsInStorageBinsBalance.Package AS Package,
		|	GoodsInStorageBinsBalance.InStockBalance AS InStockBalance
		|FROM
		|	AccumulationRegister.GoodsInStorageBins.Balance(
		|			,
		|			Products = &Products
		|				AND Characteristic = &Characteristic
		|				AND Series = &Series
		|				AND Cell.Owner = &Warehouse
		|				AND Cell.Premise = &Premise) AS GoodsInStorageBinsBalance
		|
		|ORDER BY
		|	GoodsInStorageBinsBalance.Cell.TabIndex";
		
	EndIf;

	Query.SetParameter("Warehouse",              Parameters.Warehouse);
	Query.SetParameter("Premise",          Parameters.Premise);
	Query.SetParameter("Products",       Parameters.Products);
	Query.SetParameter("Characteristic",     Parameters.Characteristic);
	Query.SetParameter("Series",              Parameters.Series);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		NewRow = Cells.Add();
		NewRow.Cell = SelectionDetailRecords.Cell;
		NewRow.Count = SelectionDetailRecords.InStockBalance;
		NewRow.Package = SelectionDetailRecords.Package;
	EndDo;
	
#EndIf
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCells

&AtClient
Procedure CellsSelection(Item, RowSelected, Field, StandardProcessing) 
	
	StandardProcessing = False;
	Close(Item.CurrentData.Cell);
	
EndProcedure

#EndRegion
