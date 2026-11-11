#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Commands

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//   ValueTableRow - new report command.
Function AddCommandStateOfCustomerOrderListProvision(ReportsCommands) Export
	
	If AccessRight("View", Metadata.DataProcessors.OrderSupplyForecast) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.DataProcessors.OrderSupplyForecast.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái đảm bảo';
											|ru = 'Состояние обеспечения';
											|en = 'Supply forecast'; fa = 'پیش‌بینی تأمین';
											|it = 'Stato di approvvigionamento';
											|pl = 'Status zaopatrzenia';
											|tr = 'Tedarik durumu'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		ReportCommand.FormParameterName = "Orders";
		ReportCommand.FormParameters = New Structure("ContextOfUse", "ORDERLIST");
		
		ReportCommand.FunctionalOptions = "UseShipmentByRowsInSalesOrder";
		
		ReportCommand.HasVisibilityConditions = True;
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand,
			"ThisIsOrderAsInvoice",
			False, 
			DataCompositionComparisonType.Equal);
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

// Defines the item availability parameters for the order. Used in warehouse reservation teams.
// Parameters:
//  Products - CatalogRef.Products - Products
//  Characteristic - CatalogRef.ItemsCharacteristics - Characteristic 
//  Purpose - CatalogRef.Assignments - Purpose
//  Warehouse - CatalogRef.Warehouses - Warehouse
//  ShipmentOrder - DefinedType.ExpectedShipment - OrderDocument
// Returns:
//  Structure - structure with fields:
//   * NeedForOrder - Number - the need for the goods in stock in the order, except for the lines with the action "Do not provide" and "Ship"
//   * ReserveUnderOrder - Number - the quantity of need provided by the action "Reserve in stock in the order"
//   * Available - Number - the quantity available for shipment to the order, for the lines with the actions "Reserve as received" and "To ensure"
Function NumericalReservationParameters(Products, Characteristic, Purpose, Warehouse, ShipmentOrder) Export
	
	Query = New Query();
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("ShipmentOrder", ShipmentOrder);
	
	QueryText =
		"SELECT
		|	&Products AS Products,
		|	&Characteristic AS Characteristic,
		|	&Warehouse AS Warehouse,
		|	&Purpose AS Purpose,
		|	&ShipmentOrder AS ShipmentOrder,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference
		|INTO Table
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ShipmentOrder
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ToUnlockBalance AS ToUnlockBalance,
		|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose, OrderDocument) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose,
		|				Filter.ShipmentOrder AS ShipmentOrder
		|			FROM
		|				Table AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|////////////////////////////////////////////////
		|SELECT
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
		|				Table AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|////////////////////////////////////////////////
		|SELECT
		|	InventoryAllocation.Products AS Products,
		|	InventoryAllocation.Characteristic AS Characteristic,
		|	InventoryAllocation.Warehouse AS Warehouse,
		|	InventoryAllocation.Purpose AS Purpose,
		|	InventoryAllocation.InventoryState AS InventoryState,
		|	InventoryAllocation.DemandCharacteristic AS DemandCharacteristic,
		|	InventoryAllocation.ReceiptOrder AS ReceiptOrder,
		|	InventoryAllocation.DateOfReceipt AS DateOfReceipt,
		|	InventoryAllocation.AvailabilityDate AS AvailabilityDate,
		|	InventoryAllocation.ShipmentOrder AS ShipmentOrder,
		|	InventoryAllocation.RequestShipmentOn AS RequestShipmentOn,
		|	InventoryAllocation.Count AS Count
		|INTO InventoryAllocation
		|FROM
		|	InformationRegister.InventoryAllocation AS InventoryAllocation
		|WHERE
		|	TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS ThereAreRecords
		|		FROM
		|			Table AS Filter
		|		WHERE
		|			Filter.Products = InventoryAllocation.Products
		|			AND Filter.Characteristic = InventoryAllocation.Characteristic
		|			AND Filter.Warehouse = InventoryAllocation.Warehouse
		|			AND Filter.Purpose = InventoryAllocation.Purpose
		|			AND Filter.ShipmentOrder = InventoryAllocation.ShipmentOrder)
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(Demands.ReserveAtWarehouse
		|				+ Demands.ReserveAsReceived
		|				+ Demands.SnoozeReservation
		|				+ Demands.ToSupply, 0) AS NeedForOrder,
		|	ISNULL(Balance.QuantityForShipAction, 0) AS Available,
		|	ISNULL(Demands.ReserveAtWarehouse, 0) AS ReserveUnderOrder
		|FROM
		|	Table AS Table
		|		
		|		LEFT JOIN CalculationOfBalancesForSettingActions AS Balance
		|		ON Balance.ShipmentOrder = Table.ShipmentOrder
		|		AND Balance.Products = Table.Products
		|		AND Balance.Characteristic = Table.Characteristic
		|		AND Balance.Warehouse = Table.Warehouse
		|		AND Balance.Purpose = Table.Purpose
		|		AND Balance.ControlledLotReference = Table.ControlledLotReference
		|		
		|		LEFT JOIN Demands AS Demands
		|		ON Demands.ShipmentOrder = Table.ShipmentOrder
		|		AND Demands.Products = Table.Products
		|		AND Demands.Characteristic = Table.Characteristic
		|		AND Demands.Warehouse = Table.Warehouse
		|		AND Demands.Purpose = Table.Purpose
		|		AND Demands.ControlledLotReference = Table.ControlledLotReference";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Analysts = "Table"; // @query-part-1
	TablesNames.InventoryAndDemandsUpdate = ""; // @query-part-1
	TablesNames.InventoryAllocation = "InventoryAllocation"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	TablesNames.Demands = "Demands"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames, True);
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	Indicators = New Structure("NeedForOrder,ReserveUnderOrder,Available", 0, 0, 0);
	If Selection.Next() Then
		
		Indicators.NeedForOrder = Selection.NeedForOrder;
		Indicators.ReserveUnderOrder = Selection.ReserveUnderOrder;
		Indicators.Available = Selection.Available;
		Indicators.Available = Max(0, Min(Indicators.Available, Indicators.NeedForOrder));
		
	EndIf;
	Return Indicators;
	
EndFunction

#EndRegion

#EndIf
