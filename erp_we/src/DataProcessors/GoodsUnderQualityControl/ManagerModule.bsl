#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure of operation of long-term data acquisition to fill in the list of items of the workplace of the product Quality control.
//  Parameters:
//   FillParameters - See QualityControlClientServer.FillingParametersOfItemsForQualityControl
//  Returns:
//   ValueTable - table with fields:
//    * Products - CatalogRef.Products - The item of the item of the Lot reference.
//    * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - The stock UOM of the item of the Lot reference.
//    * Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the item of the Lot reference.
//    * Warehouse - CatalogRef.Warehouses - the warehouse where the item of the Lot reference is located.
//    * Purpose - CatalogRef.Assignments - the destination for which the item of the Lot reference is intended.
//    * ControlledLotReference - CatalogRef.ControlledLots - The Lot reference of the item for which there are Balances of the blocked item.
//    * ThisIsARequestForControl - Boolean - The Lot reference is formed by an application for quality control.
//    * Series - CatalogRef.ItemsBatches - Batch of item Lot reference.
//    * Premise - CatalogRef.Warerooms - the room in which the item of the Lot reference is located.
//    * IsLocked - Number - the quantity of the Lot reference item in stock.
//    * AvailableInventory - Number - the free Balance in the warehouse where the item of the Lot reference is located.
//    * ControlTerm - Date - Planned date of End of quality control.
//    * ThereAreControlLines - Boolean - indicates that the Due date field is filled in.
//    * InTransitProcess - Boolean - indicates that not a certain amount of the Lot reference is scheduled to be moved or is in the process of moving between warehouses.
Function CompleteTaskOfFillingInGoods(FillParameters) Export
	
	// 1. We get the Balance of items in warehouses by batch, minus the items
	//    for which expenditure orders for movement in non-final Statuses have already been issued.
	//    These items in warehouses, all series and premises will form the basis of the list displayed in the workplace.
	// 2. We receive items in the sending warehouse in the context of batches
	//    scheduled for relocation with the Reserve action as they arrive.
	//    There are no series and premises in them.
	// 3. We receive items at the sending warehouse in the context of batches for which
	//    a shipment order has been issued (order or transfer), but no orders have been created.
	// 4. Items 2 and 3 are displayed as part of 1 in the sending warehouse.
	//    If there are items 2 and 3, then an indicator will be displayed in the RM for the sender warehouse, there is a process of re-placement
	//    For items 2, the comparison with 1 is without taking into account the series and premises
	//    For items 3, comparison with 1 goes without taking into account the premises, if the series is filled in 3,
	//    then taking into account the series, otherwise without taking into account the series.
	// 5. We receive items for receipt at the receiving warehouse in the context of batches
	//    according to orders for receipt (order or transfer). Movements in orders by
	//    The items to be shipped and the Items to be received are synornized and appear after the Ship action.
	// 6. For each transfer order, we compare data 2 and 5 without taking into account the series.
	//    We find the value by which the Items to be received exceed the Items to be shipped
	//    This quantity is no longer displayed in the sender warehouse, it needs to be displayed in the recipient warehouse.
	//    We do not consider the reverse situation when the Items to be received are less than the Items to be shipped.
	// 7. Add items 6 based on list 1. If matched, then increase the quantity, if not, add a
	//    separate line. If premises and series are used, it will always be a separate line,
	//    since there is no room and series in the Items for receipt.
	// 8. Where added, the indicator will be displayed, there is a process of re-placement
	// 9. For each item analysis and warehouse of the main table, we get a free Balance in the warehouse
	//    for display in the basement of the workplace.
	// 10.For each item analysis, warehouse and batch of the main table, we get the minimum control period,
	//    according to the assurance data as the minimum Date of quality confirmation.
	// 11.The workplace table is ordered in ascending order of time. If the party is not planned to be unlocked
	//    , the party is displayed at the bottom of the list.
	// 12. Ordering by Control period, Batch, Nomenclature, Characteristics, Series, Purpose, Premises, Warehouse
	
	Substitutions = New Array();
	If FillParameters.Filter.Warehouse <> Undefined Then
		Substitution = "Warehouse = &Warehouse";
		Substitutions.Add(Substitution);
	EndIf;
	
	If FillParameters.Filter.Products <> Undefined Then
		Substitution = "Products = &Products";
		Substitutions.Add(Substitution);
	EndIf;

	If FillParameters.Filter.Purpose <> Undefined Then
		Substitution = "Purpose = &Purpose";
		Substitutions.Add(Substitution);
	EndIf;
	
	If Substitutions.Count() = 0 Then
		Substitution = "TRUE"; // @query-part-1
	Else
		Substitution = StrConcat(Substitutions, " AND "); // @query-part-1
	EndIf;
	
	QueryText =
		"SELECT
		|	GoodsForIssue.Products AS Products,
		|	GoodsForIssue.Characteristic AS Characteristic,
		|	GoodsForIssue.Purpose AS Purpose,
		|	GoodsForIssue.Warehouse AS Warehouse,
		|	GoodsForIssue.Recipient AS Recipient,
		|	GoodsForIssue.Series AS Series,
		|	GoodsForIssue.DocumentShipments AS DocumentShipments,
		|	GoodsForIssue.ControlledLotReference AS ControlledLotReference,
		|	GoodsForIssue.InReserveBalance AS ReserveAtWarehouse,
		// The amount minus what got into the spending orders. Displayed at the sending warehouse.
		|	GoodsForIssue.ToShipBalance
		|		- GoodsForIssue.ForAssemblyBalance
		|		- GoodsForIssue.AssemblyInProgressBalance
		|		- GoodsForIssue.AssembledBalance AS ToShip
		|INTO GoodsForIssue
		|FROM
		|	AccumulationRegister.GoodsForIssue.Balance(,
		|		&FilterOverridable
		|		AND ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)
		|		{Products.* AS Products,
		|			Characteristic.* AS Characteristic,
		|			Warehouse.* AS Warehouse,
		|			ControlledLotReference.* AS ControlledLotReference,
		|			Purpose.* AS Purpose}) AS GoodsForIssue
		|;
		|
		|///////////////////////////////////////////////////
		|SELECT
		|	GoodsForIssue.Products AS Products,
		|	GoodsForIssue.Characteristic AS Characteristic,
		|	GoodsForIssue.Purpose AS Purpose,
		|	GoodsForIssue.Warehouse AS Warehouse,
		|	GoodsForIssue.Recipient AS Recipient,
		|	GoodsForIssue.ControlledLotReference AS ControlledLotReference,
		|	SUM(GoodsForIssue.ToShip) AS Count
		|INTO GoodsToShipToCalculateItemsBeingMoved
		|FROM
		|	GoodsForIssue AS GoodsForIssue
		|WHERE
		|	GoodsForIssue.ToShip > 0
		|GROUP BY
		|	GoodsForIssue.Products,
		|	GoodsForIssue.Characteristic,
		|	GoodsForIssue.Purpose,
		|	GoodsForIssue.Warehouse,
		|	GoodsForIssue.Recipient,
		|	GoodsForIssue.ControlledLotReference
		|INDEX BY
		|	Products, Characteristic, Purpose, Warehouse, Recipient, ControlledLotReference
		|;
		|
		|///////////////////////////////////////////////////////////////////////////
		// The product is loaded for the indicator.
		|SELECT DISTINCT
		|	GoodsForIssue.Products AS Products,
		|	GoodsForIssue.Characteristic AS Characteristic,
		|	GoodsForIssue.Purpose AS Purpose,
		|	GoodsForIssue.Warehouse AS Warehouse,
		|	GoodsForIssue.Series AS Series,
		|	GoodsForIssue.ControlledLotReference AS ControlledLotReference
		|INTO GoodsToShipForIndicator
		|FROM
		|	GoodsForIssue AS GoodsForIssue
		|INDEX BY
		|	Products, Characteristic, Purpose, Warehouse, Series
		|;
		|
		|///////////////////////////////////////////////////////////////////////////////
		|DROP GoodsForIssue
		|;
		// The query above must be executed in privileged mode in order for the temporary table to be calculated correctly
		// Moving the goods. Requests are separated by the keyword "DESTROY GOODS ON SHIPMENT".
		|
		|///////////////////////////////////////////////////////////////////////////////
		// Inventory needs for the indicator.
		|SELECT ALLOWED DISTINCT
		|	InventoryAndDemands.Products AS Products,
		|	InventoryAndDemands.Characteristic AS Characteristic,
		|	InventoryAndDemands.Warehouse AS Warehouse,
		|	InventoryAndDemands.Purpose AS Purpose,
		|	InventoryAndDemands.OrderDocument AS ControlledLotReference
		|INTO InventoryAndNeedsForIndicator
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		&FilterOverridable
		|		AND VALUETYPE(OrderDocument) = TYPE(Catalog.ControlledLots)
		|		{Products.* AS Products,
		|			Characteristic.* AS Characteristic,
		|			Warehouse.* AS Warehouse,
		|			Purpose.* AS Purpose,
		|			OrderDocument.* AS ControlledLotReference}) AS InventoryAndDemands
		|WHERE
		|	InventoryAndDemands.ReserveUponReceiptFromLockedBalance > 0
		|		OR InventoryAndDemands.ReserveAtWarehouseFromLockedBalance > 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference
		|;
		|
		|///////////////////////////////////////////////////////
		// Timing of control.
		|SELECT ALLOWED
		|	InventoryAndDemands.Products AS Products,
		|	InventoryAndDemands.Characteristic AS Characteristic,
		|	InventoryAndDemands.Warehouse AS Warehouse,
		|	InventoryAndDemands.Purpose AS Purpose,
		|	InventoryAndDemands.OrderDocument AS ControlledLotReference,
		|	MIN(InventoryAndDemands.EventDate) AS ControlTerm
		|INTO TermsOfControl
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		&FilterOverridable
		// The Lot reference has been received
		|		AND VALUETYPE(OrderDocument) = TYPE(Catalog.ControlledLots)
		|		{Products.* AS Products,
		|			Characteristic.* AS Characteristic,
		|			Warehouse.* AS Warehouse,
		|			Purpose.* AS Purpose,
		|			OrderDocument.* AS ControlledLotReference}) AS InventoryAndDemands
		|WHERE
		|	InventoryAndDemands.ToUnlockBalance > 0
		|GROUP BY
		|	InventoryAndDemands.Products,
		|	InventoryAndDemands.Characteristic,
		|	InventoryAndDemands.Purpose,
		|	InventoryAndDemands.Warehouse,
		|	InventoryAndDemands.OrderDocument
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference
		|;
		|
		|///////////////////////////////////////////////////////////////////////////
		// Moving the goods.
		|SELECT ALLOWED
		|	GoodsToReceive.Products AS Products,
		|	GoodsToReceive.Characteristic AS Characteristic,
		|	GoodsToReceive.Purpose AS Purpose,
		|	GoodsToReceive.Warehouse AS Warehouse,
		|	GoodsToReceive.Sender AS Sender,
		|	GoodsToReceive.ControlledLotReference AS ControlledLotReference,
		// The quantity that is not reflected in goods in warehouses in a non-ordinary warehouse
		|	GoodsToReceive.ToRegisterReceiptsByReferenceBalance
		// Correction for exceeding the order over the receipt at the order warehouse
		|		- GoodsToReceive.ToRegisterGoodsReceiptsBalance AS Count
		|INTO GoodsToBeReceivedForCalculationOfGoodsBeingMoved
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(,
		|		&FilterOverridable
		|			AND ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)
		|		{Products.* AS Products,
		|			Characteristic.* AS Characteristic,
		|			Warehouse.* AS Warehouse,
		|			ControlledLotReference.* AS ControlledLotReference,
		|			Purpose.* AS Purpose}) AS GoodsToReceive
		|INDEX BY
		|	Products, Characteristic, Purpose, Warehouse, Sender, ControlledLotReference
		|;
		|
		|///////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	GoodsToReceive.Products AS Products,
		|	GoodsToReceive.Characteristic AS Characteristic,
		|	GoodsToReceive.Purpose AS Purpose,
		|	GoodsToReceive.Warehouse AS Warehouse,
		|	GoodsToReceive.ControlledLotReference AS ControlledLotReference,
		|	SUM(GoodsToReceive.Count - ISNULL(GoodsForIssue.Count, 0)) AS Count
		|INTO ItemsBeingMoved
		|FROM
		|	GoodsToBeReceivedForCalculationOfGoodsBeingMoved AS GoodsToReceive
		|		
		|		LEFT JOIN GoodsToShipToCalculateItemsBeingMoved AS GoodsForIssue
		|		ON GoodsForIssue.Products = GoodsToReceive.Products
		|		 AND GoodsForIssue.Characteristic = GoodsToReceive.Characteristic
		|		 AND GoodsForIssue.Purpose = GoodsToReceive.Purpose
		|		 AND GoodsForIssue.Warehouse = GoodsToReceive.Sender
		|		 AND GoodsForIssue.Recipient = GoodsToReceive.Warehouse
		|		 AND GoodsForIssue.ControlledLotReference = GoodsToReceive.ControlledLotReference
		|WHERE
		|	GoodsToReceive.Count - ISNULL(GoodsForIssue.Count, 0) > 0
		|{WHERE
		|	CAST(VALUE(Catalog.Warerooms.EmptyRef) AS Catalog.Warerooms).* AS Premise,
		|	CAST(VALUE(Catalog.ItemsBatches.EmptyRef) AS Catalog.ItemsBatches).* AS Series}
		|GROUP BY
		|	GoodsToReceive.Products,
		|	GoodsToReceive.Characteristic,
		|	GoodsToReceive.Purpose,
		|	GoodsToReceive.Warehouse,
		|	GoodsToReceive.ControlledLotReference
		|INDEX BY
		|	Products, Characteristic, Purpose, Warehouse, ControlledLotReference
		|;
		|
		|///////////////////////////////////////////////////////////////////////////
		|DROP GoodsToBeReceivedForCalculationOfGoodsBeingMoved
		|;
		|
		|///////////////////////////////////////////////////////////////////////////
		|DROP GoodsToShipToCalculateItemsBeingMoved
		|;
		|
		|///////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ProductStock.Products AS Products,
		|	ProductStock.Characteristic AS Characteristic,
		|	ProductStock.Warehouse AS Warehouse,
		|	ProductStock.Premise AS Premise,
		|	ProductStock.Purpose AS Purpose,
		|	ProductStock.ControlledLotReference AS ControlledLotReference,
		|	ProductStock.Series AS Series,
		|	ProductStock.InStockBalance
		// In orders
		|		- ProductStock.ToShipBalance AS Count
		|INTO ProductStock
		|FROM
		|	AccumulationRegister.ProductStock.Balance(,
		|		&FilterOverridable
		|		AND ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)
		|		{Products.* AS Products,
		|			Characteristic.* AS Characteristic,
		|			Warehouse.* AS Warehouse,
		|			Purpose.* AS Purpose,
		|			ControlledLotReference.*,
		|			Premise.*,
		|			Series.*}) AS ProductStock
		|WHERE
		|	ProductStock.InStockBalance > 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Premise, Purpose, ControlledLotReference, Series
		|;
		|
		|///////////////////////////////////////////////////////////////////////////
		// The main table.
		|SELECT
		|	ProductStock.Products AS Products,
		|	ProductStock.Characteristic AS Characteristic,
		|	ProductStock.Warehouse AS Warehouse,
		|	ProductStock.Premise AS Premise,
		|	ProductStock.Purpose AS Purpose,
		|	ProductStock.ControlledLotReference AS ControlledLotReference,
		|	ProductStock.Series AS Series,
		|	ProductStock.Count
		|		+ ISNULL(ItemsBeingMoved.Count, 0) AS Count,
		|	NOT ItemsBeingMoved.Products IS NULL InTransitProcess
		|INTO MainTable
		|FROM
		|	ProductStock AS ProductStock
		|		
		|		LEFT JOIN ItemsBeingMoved AS ItemsBeingMoved
		|		ON ItemsBeingMoved.Products = ProductStock.Products
		|		 AND ItemsBeingMoved.Characteristic = ProductStock.Characteristic
		|		 AND ItemsBeingMoved.Warehouse = ProductStock.Warehouse
		|		 AND ProductStock.Premise = VALUE(Catalog.Warerooms.EmptyRef)
		|		 AND ItemsBeingMoved.Purpose = ProductStock.Purpose
		|		 AND ItemsBeingMoved.ControlledLotReference = ProductStock.ControlledLotReference
		|		 AND ProductStock.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	ItemsBeingMoved.Products AS Products,
		|	ItemsBeingMoved.Characteristic AS Characteristic,
		|	ItemsBeingMoved.Warehouse AS Warehouse,
		|	VALUE(Catalog.Warerooms.EmptyRef) AS Premise,
		|	ItemsBeingMoved.Purpose AS Purpose,
		|	ItemsBeingMoved.ControlledLotReference AS ControlledLotReference,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|	ItemsBeingMoved.Count AS Count,
		|	TRUE InTransitProcess
		|FROM
		|	ItemsBeingMoved AS ItemsBeingMoved
		|		
		|		LEFT JOIN ProductStock AS ProductStock
		|		ON ProductStock.Products = ItemsBeingMoved.Products
		|		 AND ProductStock.Characteristic = ItemsBeingMoved.Characteristic
		|		 AND ProductStock.Warehouse = ItemsBeingMoved.Warehouse
		|		 AND ProductStock.Premise = VALUE(Catalog.Warerooms.EmptyRef)
		|		 AND ProductStock.Purpose = ItemsBeingMoved.Purpose
		|		 AND ProductStock.ControlledLotReference = ItemsBeingMoved.ControlledLotReference
		|		 AND ProductStock.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference, Series, Premise
		|;
		|
		|///////////////////////////////////////////////////////////////////////////
		|DROP ProductStock
		|;
		|
		|///////////////////////////////////////////////////////////////////////////
		|DROP ItemsBeingMoved
		|;
		|
		|///////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Analysts.Products AS Products,
		|	Analysts.Characteristic AS Characteristic,
		|	Analysts.Warehouse AS Warehouse,
		|	Analysts.Purpose AS Purpose
		|INTO AnalyticsForObtainingBalances
		|FROM
		|	MainTable AS Analysts
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|///////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
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
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				AnalyticsForObtainingBalances AS Filter)) AS Inventories
		|;
		|
		|///////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Products.UnitOfMeasure AS UnitOfMeasure,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	VALUETYPE(Table.ControlledLotReference.Lot) = TYPE(Document.RequestForGoodsQualityControl) AS ThisIsARequestForControl,
		|	Table.Series AS Series,
		|	Table.Premise AS Premise,
		|	Table.Count AS IsLocked,
		|	ISNULL(Calculation.QuantityForShipAction, 0) AS AvailableInventory,
		|	ISNULL(TermsOfControl.ControlTerm, DATETIME(1,1,1)) AS ControlTerm,
		|	NOT TermsOfControl.ControlTerm IS NULL AS ThereAreControlLines,
		|	Table.InTransitProcess
		|		OR NOT GoodsForIssue.Products IS NULL
		|		OR NOT InventoryAndDemands.Products IS NULL AS InTransitProcess
		|{SELECT
		|	Products.*,
		|	UnitOfMeasure.*,
		|	Characteristic.*,
		|	Warehouse.*,
		|	Purpose.*,
		|	ControlledLotReference.*,
		|	Series.*,
		|	Premise.*,
		|	IsLocked,
		|	AvailableInventory,
		|	ControlTerm,
		|	ThereAreControlLines,
		|	InTransitProcess}
		|FROM
		|	MainTable AS Table
		|		
		|		LEFT JOIN CalculationOfBalancesForSettingActions AS Calculation
		|		ON Calculation.Products = Table.Products
		|		 AND Calculation.Characteristic = Table.Characteristic
		|		 AND Calculation.Warehouse = Table.Warehouse
		|		 AND Calculation.Purpose = Table.Purpose
		|		 AND Calculation.QuantityForShipAction > 0
		|		
		|		LEFT JOIN TermsOfControl AS TermsOfControl
		|		ON TermsOfControl.Products = Table.Products
		|		 AND TermsOfControl.Characteristic = Table.Characteristic
		|		 AND TermsOfControl.Purpose = Table.Purpose
		|		 AND TermsOfControl.Warehouse = Table.Warehouse
		|		 AND TermsOfControl.ControlledLotReference = Table.ControlledLotReference
		|		
		|		LEFT JOIN GoodsToShipForIndicator AS GoodsForIssue
		|		ON GoodsForIssue.Products = Table.Products
		|		 AND GoodsForIssue.Characteristic = Table.Characteristic
		|		 AND GoodsForIssue.Purpose = Table.Purpose
		|		 AND GoodsForIssue.Warehouse = Table.Warehouse
		|		 AND GoodsForIssue.ControlledLotReference = Table.ControlledLotReference
		|		 AND (GoodsForIssue.Series = Table.Series
		|			OR GoodsForIssue.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
		|		
		|		LEFT JOIN InventoryAndNeedsForIndicator AS InventoryAndDemands
		|		ON InventoryAndDemands.Products = Table.Products
		|		 AND InventoryAndDemands.Characteristic = Table.Characteristic
		|		 AND InventoryAndDemands.Purpose = Table.Purpose
		|		 AND InventoryAndDemands.Warehouse = Table.Warehouse
		|		 AND InventoryAndDemands.ControlledLotReference = Table.ControlledLotReference
		|WHERE
		|	(&ApplicationFormalizedOverridable)
		|{WHERE
		|	(ISNULL(TermsOfControl.ControlTerm, DATETIME(1, 1, 1))) AS ControlTerm,
		|	(Table.InTransitProcess
		|			OR NOT GoodsForIssue.Products IS NULL
		|			OR NOT InventoryAndDemands.Products IS NULL) AS InTransitProcess}
		|ORDER BY
		|	ThereAreControlLines DESC,
		|	ControlTerm,
		|	ControlledLotReference,
		|	Products,
		|	Characteristic,
		|	Series,
		|	Purpose,
		|	Premise,
		|	Warehouse";
		
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
	QueryText = StrReplace(QueryText, "&FilterOverridable", Substitution);
	
	If FillParameters.Filter.ApplicationFormalized = Undefined Then
		Substitution = "TRUE";
	ElsIf FillParameters.Filter.ApplicationFormalized Then
		Substitution = "VALUETYPE(Table.ControlledLotReference.Lot) = TYPE(Document.RequestForGoodsQualityControl)";
	Else
		Substitution = "VALUETYPE(Table.ControlledLotReference.Lot) <> TYPE(Document.RequestForGoodsQualityControl)";
	EndIf;
	QueryText = StrReplace(QueryText, "&ApplicationFormalizedOverridable", Substitution);
	
	Filters = DataProcessors.GoodsUnderQualityControl.GetTemplate("Filters");
	Filters.DataSets[0].Query = QueryText;
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(
		Filters,
		FillParameters.CompositionSettings,
		,
		,
		,
		False);
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	For Each LayoutParameter In DataCompositionTemplate.ParameterValues Do
		Query.SetParameter(LayoutParameter.Name, LayoutParameter.Value);
	EndDo;
	
	For Each FilterElement In FillParameters.Filter Do
		Query.SetParameter(FilterElement.Key, FilterElement.Value);
	EndDo;
	
	QueryText = DataCompositionTemplate.DataSets[0].Query;
	Separator = "DROP GoodsForIssue";
	EndOfFirstBlock = StrFind(QueryText, Separator) + StrLen(Separator) + 1;
	// It is necessary to obtain, even if there is no access to the warehouse, the sender of the transfer
	// in order to correctly calculate the temporary table of the goods being moved.
	SetPrivilegedMode(True);
	Query.Text = Left(QueryText, EndOfFirstBlock);
	Query.Execute();
	SetPrivilegedMode(False);
	Query.Text = Mid(QueryText, EndOfFirstBlock + 1);
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Purpose");
	Return FormTemplate;
	
EndFunction

#EndRegion

#EndIf