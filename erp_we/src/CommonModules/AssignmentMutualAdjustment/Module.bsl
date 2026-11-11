////////////////////////////////////////////////////////////////////////////////
// The module "Counter-correction assignments" contains procedures and functions for 
// working with the mechanism of counter-correction.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns parameters for selecting a counter adjustment for a destination
//
// Returns:
//  ValueTable - table with keys:
//   * Products       - CatalogRef.Products - 
//   * Characteristic     - CatalogRef.ItemsCharacteristics - 
//   * Warehouse              - CatalogRef.Warehouses - 
//   * ByAssignment       - Number - 0 - no selection,
//                                  1-selection for equality,
//                                  2 - selection for inequality
//   * Expense             - Number - 
//   * Allocated       - Number - 
//   * RowKey         - UUID - 
//   * KeyOfParentString - UUID - 
//
Function TableOfSelectionOfGoodsOfCounterAdjustmentOfDestination() Export
	
	FilterParameters = New ValueTable();
	FilterParameters.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	FilterParameters.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	FilterParameters.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	FilterParameters.Columns.Add("ByAssignment", Common.TypeDescriptionNumber(1, 0, AllowedSign.Nonnegative));
	FilterParameters.Columns.Add("Expense", Common.TypeDescriptionNumber(15, 3, AllowedSign.Nonnegative));
	FilterParameters.Columns.Add("Allocated", Common.TypeDescriptionNumber(15, 3, AllowedSign.Nonnegative));
	FilterParameters.Columns.Add("RowKey", New TypeDescription("UUID"));
	FilterParameters.Columns.Add("KeyOfParentString", New TypeDescription("UUID"));
	
	Return FilterParameters;
	
EndFunction

//Returns data for counter adjustment of the destination
//
// Parameters:
//  Parameters - Structure - with keys:
//   * OrderDocument            - DocumentRef.ProductionOrder2_2 - 
//   * Products     - CatalogRef.Products - 
//   * Characteristic   - CatalogRef.ItemsCharacteristics - 
//   * Warehouse            - CatalogRef.Warehouses - 
//   * Purpose       - CatalogRef.Assignments - 
//   * KeyProducts - UUID - 
//   * KeyLot       - UUID - 
//  UUID - UUID - id of the form for placing the selection of goods in the storage
//
// Returns:
//  Structure - with keys:
//   * QuantityToPassForAssignment  - See QuantityOfGoodsOfCounterAdjustmentOfDestination
//   * GoodsFilter - See GoodsOfSelectionOfCounterAdjustmentOfAppointment
//
Function DestinationCounterAdjustmentData(Parameters, UUID) Export
	
	Data =  New Structure;
	Data.Insert("QuantityToPassForAssignment", QuantityOfGoodsOfCounterAdjustmentOfDestination(Parameters));
	SelectionProducts = GoodsOfSelectionOfCounterAdjustmentOfAppointment(Parameters);
	Data.Insert("AddressOfGoods", PutToTempStorage(SelectionProducts, UUID));
	
	Return Data;
	
EndFunction

//Returns data for counter adjustment of the destination
//
// Parameters:
//  Parameters - Structure - with keys:
//   * OrderDocument          - DocumentRef.ProductionOrder2_2 - 
//   * Products   - CatalogRef.Products - 
//   * Characteristic - CatalogRef.ItemsCharacteristics - 
//   * Warehouse          - CatalogRef.Warehouses - 
//   * Purpose     - CatalogRef.Assignments - 
//
// Returns:
//  Number - 
//
Function QuantityOfGoodsOfCounterAdjustmentOfDestination(Parameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	OrderStructure.Products        AS Products,
	|	OrderStructure.Characteristic      AS Characteristic,
	|	OrderStructure.Warehouse               AS Warehouse,
	|	OrderStructure.Purpose          AS Purpose,
	|	OrderStructure.ProductionOrder AS ProductionOrder,
	|	OrderStructure.KeyProducts    AS KeyProducts,
	|	SUM(OrderStructure.ToSupply - OrderStructure.Replaced) AS Count
	|
	|INTO DataTable
	|FROM
	|	InformationRegister.OrderStructure AS OrderStructure
	|WHERE
	|	OrderStructure.ProductionOrder = &OrderDocument
	|	AND OrderStructure.Products      = &Products
	|	AND OrderStructure.Characteristic    = &Characteristic
	|	AND OrderStructure.Warehouse             = &Warehouse
	|	AND OrderStructure.Purpose        = &Purpose
	|	AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|
	|GROUP BY
	|	OrderStructure.Products,
	|	OrderStructure.Characteristic,
	|	OrderStructure.Warehouse,
	|	OrderStructure.Purpose,
	|	OrderStructure.ProductionOrder,
	|	OrderStructure.KeyProducts
	|
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose, ProductionOrder, KeyProducts
	|;
	|
	|SELECT
	|	SUM(Table.Count) AS Count
	|FROM
	|	(SELECT
	|		DataTable.Count AS Count
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		-OrderStructure.AllocatedFromAvailableInventory
	|		-OrderStructure.AllocatedFromAvailableInventoryWithAssignment AS Count
	|	FROM
	|		InformationRegister.OrderStructure AS OrderStructure
	|			LEFT JOIN DataTable AS DataTable
	|			ON OrderStructure.Products        = DataTable.Products
	|			 AND OrderStructure.Characteristic      = DataTable.Characteristic
	|			 AND OrderStructure.Warehouse               = DataTable.Warehouse
	|			 AND OrderStructure.Purpose          = DataTable.Purpose
	|			 AND OrderStructure.ProductionOrder = DataTable.ProductionOrder
	|			 AND OrderStructure.KeyProducts    = DataTable.KeyProducts
	|	WHERE
	|		DataTable.KeyProducts IS NOT NULL
	|		AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)) AS Table
	|";

	Query.SetParameter("OrderDocument",          Parameters.OrderDocument);
	Query.SetParameter("Products",   Parameters.Products);
	Query.SetParameter("Characteristic", Parameters.Characteristic);
	Query.SetParameter("Warehouse",          Parameters.Warehouse);
	Query.SetParameter("Purpose",     Parameters.Purpose);
	
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.Count;
	
EndFunction

//Returns product data for the selection of the counter adjustment of the destination
//
// Parameters:
//  Parameters - Structure - with keys:
//   * Products     - CatalogRef.Products - 
//   * Characteristic   - CatalogRef.ItemsCharacteristics -
//   * Warehouse            - CatalogRef.Warehouses -  
//   * KeyProducts - UUID - 
//   * KeyLot       - UUID - 
//
// Returns:
//  See TableOfSelectionOfGoodsOfCounterAdjustmentOfDestination
//
Function GoodsOfSelectionOfCounterAdjustmentOfAppointment(Parameters) Export
	
	TableProductFilter = TableOfSelectionOfGoodsOfCounterAdjustmentOfDestination();
	FilterParameters = TableProductFilter.Add();
	FillPropertyValues(FilterParameters, Parameters);
	FilterParameters.ByAssignment = 2;
	
	TableExpense = New ValueTable;
	TableExpense.Columns.Add("KeyProducts", New TypeDescription("UUID"));
	TableExpense.Columns.Add("KeyLot",       New TypeDescription("UUID"));
	
	TableRow = TableExpense.Add();
	TableRow.KeyProducts = Parameters.KeyProducts;
	TableRow.KeyLot       = Parameters.KeyLot;
	
	FirstIteration = True;
	
	While TableExpense.Count() > 0 Do
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	TableExpense.KeyProducts AS KeyProducts,
		|	TableExpense.KeyLot       AS KeyLot
		|INTO TableExpense
		|FROM
		|	&TableExpense AS TableExpense
		|
		|INDEX BY
		|	KeyProducts
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TableReceipt.KeyProducts AS KeyProducts,
		|	TableReceipt.KeyLot       AS KeyLot
		|INTO TableReceipt
		|FROM
		|	InformationRegister.OrderStructure AS TableReceipt
		|		LEFT JOIN TableExpense AS TableExpense
		|		ON TableReceipt.KeyProducts = TableExpense.KeyProducts
		|		 AND TableReceipt.KeyLot <> TableExpense.KeyLot
		|WHERE
		|	TableExpense.KeyProducts IS NOT NULL
		|	AND TableReceipt.LineKind IN (
		|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
		|				VALUE(Enum.KindsOfProductionOrderStructureLines.Move))
		|
		|INDEX BY
		|	KeyLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrderStructure.Products                                  AS Products,
		|	OrderStructure.Characteristic                                AS Characteristic,
		|	OrderStructure.Warehouse                                         AS Warehouse,
		|	OrderStructure.Purpose                                    AS Purpose,
		|	OrderStructure.ProductionOrder                           AS ProductionOrder,
		|	SUM(OrderStructure.ToSupply - OrderStructure.Replaced)                           AS Expense,
		|	OrderStructure.KeyProducts                              AS KeyProducts,
		|	OrderStructure.KeyLot                                    AS KeyLot,
		|	OrderStructure.KeyProducts                              AS RowKey,
		|	ISNULL(&KeyOfParentString, TableReceipt.KeyProducts) AS KeyOfParentString
		|INTO DataTable
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|		LEFT JOIN TableReceipt AS TableReceipt
		|		ON OrderStructure.KeyLot = TableReceipt.KeyLot
		|WHERE
		|	TableReceipt.KeyLot IS NOT NULL
		|	AND (OrderStructure.Products, OrderStructure.Characteristic) NOT IN (
		|				SELECT
		|					&Products   AS Products,
		|					&Characteristic AS Characteristic)
		|	AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|
		|GROUP BY
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.Warehouse,
		|	OrderStructure.Purpose,
		|	OrderStructure.ProductionOrder,
		|	OrderStructure.KeyProducts,
		|	OrderStructure.KeyLot,
		|	TableReceipt.KeyProducts
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ProductionOrder, KeyProducts
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrderStructure.Products                                  AS Products,
		|	OrderStructure.Characteristic                                AS Characteristic,
		|	OrderStructure.Warehouse                                         AS Warehouse,
		|	OrderStructure.Purpose                                    AS Purpose,
		|	OrderStructure.ProductionOrder                           AS ProductionOrder,
		|	OrderStructure.KeyProducts                              AS KeyProducts,
		|	SUM(OrderStructure.AllocatedFromAvailableInventory
		|		+ OrderStructure.AllocatedFromAvailableInventoryWithAssignment)        AS Allocated
		|INTO TableIsDistributed
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|		LEFT JOIN DataTable AS DataTable
		|		ON OrderStructure.Products        = DataTable.Products
		|		 AND OrderStructure.Characteristic      = DataTable.Characteristic
		|		 AND OrderStructure.Warehouse               = DataTable.Warehouse
		|		 AND OrderStructure.Purpose          = DataTable.Purpose
		|		 AND OrderStructure.ProductionOrder = DataTable.ProductionOrder
		|		 AND OrderStructure.KeyProducts    = DataTable.KeyProducts
		|WHERE
		|	DataTable.KeyProducts IS NOT NULL
		|	AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
		|
		|GROUP BY
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.Warehouse,
		|	OrderStructure.Purpose,
		|	OrderStructure.ProductionOrder,
		|	OrderStructure.KeyProducts
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ProductionOrder, KeyProducts
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataTable.Products                    AS Products,
		|	DataTable.Characteristic                  AS Characteristic,
		|	DataTable.Warehouse                           AS Warehouse,
		|	DataTable.Expense                          AS Expense,
		|	ISNULL(TableIsDistributed.Allocated, 0) AS Allocated,
		|	DataTable.KeyProducts                AS KeyProducts,
		|	DataTable.KeyLot                      AS KeyLot,
		|	DataTable.RowKey                      AS RowKey,
		|	DataTable.KeyOfParentString              AS KeyOfParentString
		|FROM
		|	DataTable AS DataTable
		|		LEFT JOIN TableIsDistributed AS TableIsDistributed
		|		ON TableIsDistributed.Products        = DataTable.Products
		|		 AND TableIsDistributed.Characteristic      = DataTable.Characteristic
		|		 AND TableIsDistributed.Warehouse               = DataTable.Warehouse
		|		 AND TableIsDistributed.Purpose          = DataTable.Purpose
		|		 AND TableIsDistributed.ProductionOrder = DataTable.ProductionOrder
		|		 AND TableIsDistributed.KeyProducts    = DataTable.KeyProducts
		|";
		
		Query.SetParameter("Products",   Parameters.Products);
		Query.SetParameter("Characteristic", Parameters.Characteristic);
		Query.SetParameter("TableExpense",  TableExpense); 
		Query.SetParameter("KeyOfParentString",
			?(FirstIteration, New UUID("00000000-0000-0000-0000-000000000000"), Null));
		
		TableExpense = Query.Execute().Unload();
		TableExpense.Columns.Add("ByAssignment");
		TableExpense.FillValues(1, "ByAssignment");
		TMCommonUseClientServer.SupplementTable(TableExpense, TableProductFilter);
		
		FirstIteration = False;
		
	EndDo;
	
	Return TableProductFilter;
	
EndFunction

#EndRegion