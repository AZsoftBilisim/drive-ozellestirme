#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// For products and warehouses, it gets information from the temporary table about the quantity available for sale, in total for all warehouses.
//
// Parameters:
//  NameOfProductsTable - String - Name of the temporary product table.
//
// Returns:
//  String - The text of the query of the temporary table "Vtsvobodnodlyasly".
//
Function TemporaryTableAvailableForSaleTotalByWarehouse(NameOfProductsTable) Export
	
	QueryText =
		"SELECT ALLOWED
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
		|				BasketProducts.Products AS Products,
		|				BasketProducts.Characteristic AS Characteristic,
		|				BasketProducts.Warehouse AS Warehouse,
		|				VALUE(Catalog.Assignments.EmptyRef) AS Purpose
		|			FROM
		|				&TTProducts_1 AS BasketProducts)) AS Inventories
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT
		|	Calculation.Products AS Products,
		|	Calculation.Characteristic AS Characteristic,
		|	SUM(Calculation.QuantityForShipAction) AS AvailableForInventoryAllocation
		|INTO TTFreeForSale
		|FROM
		|	CalculationOfBalancesForSettingActions AS Calculation
		|GROUP BY
		|	Calculation.Products,
		|	Calculation.Characteristic
		|HAVING
		|	SUM(Calculation.QuantityForShipAction) <> 0
		|INDEX BY
		|	Products, Characteristic
		|;
		|DROP InventoryAndDemandsBalance";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
	QueryText = StrReplace(QueryText, "&TTProducts_1", NameOfProductsTable);
	Return QueryText;
	
EndFunction

// For products and warehouses, it gets the necessary temporary tables from the temporary table to calculate the nearest availability of the product in the warehouse.
//
// Parameters:
//  NameOfProductsTable - String - Name of the temporary product table.
//
// Returns:
//  String - The text of the request for temporary tables "VtBlizhiedaTydaVailability", "vtdavailableostatkipodatam".
//
Function TemporaryTablesForCalculatingAvailableBalances(NameOfProductsTable) Export
	
	Texts = New Array();
	
	QueryText =
		"SELECT ALLOWED
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
		|		(Products, Characteristic, Warehouse, Purpose) IN
		|			(SELECT
		|				BasketProducts.Products AS Products,
		|				BasketProducts.Characteristic AS Characteristic,
		|				BasketProducts.Warehouse AS Warehouse,
		|				VALUE(Catalog.Assignments.EmptyRef) AS Purpose
		|			FROM
		|				&TTProducts_1 AS BasketProducts)) AS Inventories";
	Texts.Add(QueryText);
	
	Set = New Array();

	QueryText =
		"SELECT
		|	Calculation.Products AS Products,
		|	Calculation.Characteristic AS Characteristic,
		|	Calculation.Warehouse AS Warehouse,
		|	&CurrentDayStart AS Period,
		|	Calculation.QuantityForShipAction AS Count
		|INTO TTExpectedReceipt
		|FROM
		|	CalculationOfBalancesForSettingActions AS Calculation
		|WHERE
		|	Calculation.QuantityForShipAction <> 0";
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	Set.Add(QueryText);

	QueryText =
		"SELECT
		|	PlannedCashReceipts.Products    AS Products,
		|	PlannedCashReceipts.Characteristic  AS Characteristic,
		|	PlannedCashReceipts.Warehouse           AS Warehouse,
		|	CASE WHEN PlannedCashReceipts.AvailabilityDate <= DATEADD(&CurrentDayStart, DAY, 1) THEN
		|				DATEADD(&CurrentDayStart, DAY, 1)
		|			ELSE
		|				PlannedCashReceipts.AvailabilityDate
		|		END AS Period,
		|	SUM(PlannedCashReceipts.Count) AS Count
		|FROM
		|	InformationRegister.InventoryAllocation AS PlannedCashReceipts
		|WHERE
		|	PlannedCashReceipts.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|	AND PlannedCashReceipts.InventoryState IN(
		|		VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock))
		|	AND PlannedCashReceipts.DemandCharacteristic IN(
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|		VALUE(Enum.DemandCharacteristics.ToSupply),
		|		VALUE(Enum.DemandCharacteristics.Surplus))
		|	AND TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS SatisfiesSelection
		|		FROM
		|			&TTProducts_1 AS BasketProducts
		|		WHERE
		|			BasketProducts.Products = PlannedCashReceipts.Products
		|				AND BasketProducts.Characteristic = PlannedCashReceipts.Characteristic
		|				AND BasketProducts.Warehouse = PlannedCashReceipts.Warehouse)
		|
		|GROUP BY
		|	PlannedCashReceipts.Products,
		|	PlannedCashReceipts.Characteristic,
		|	PlannedCashReceipts.Warehouse,
		|	CASE WHEN PlannedCashReceipts.AvailabilityDate <= DATEADD(&CurrentDayStart, DAY, 1) THEN
		|				DATEADD(&CurrentDayStart, DAY, 1)
		|			ELSE
		|				PlannedCashReceipts.AvailabilityDate
		|		END
		|HAVING
		|	SUM(PlannedCashReceipts.Count) <> 0";
	Set.Add(QueryText);
	QueryText = StrConcat(Set, TMCommonUse.QuerySeparatorInJoin());
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT ALLOWED
		|	PlannedCashReceipts.Products AS Products,
		|	PlannedCashReceipts.Characteristic AS Characteristic,
		|	PlannedCashReceipts.Warehouse AS Warehouse,
		|	PlannedCashReceipts.Period AS Period,
		|	SUM(PreviouslyExpectedReceipts.Count) AS Count
		|INTO TTAvailableBalancesByDate
		|FROM
		|	TTExpectedReceipt AS PlannedCashReceipts
		|		LEFT JOIN TTExpectedReceipt AS PreviouslyExpectedReceipts
		|		ON PlannedCashReceipts.Products = PreviouslyExpectedReceipts.Products
		|			AND PlannedCashReceipts.Characteristic = PreviouslyExpectedReceipts.Characteristic
		|			AND PlannedCashReceipts.Warehouse = PreviouslyExpectedReceipts.Warehouse
		|			AND PlannedCashReceipts.Period >= PreviouslyExpectedReceipts.Period
		|
		|GROUP BY
		|	PlannedCashReceipts.Products,
		|	PlannedCashReceipts.Characteristic,
		|	PlannedCashReceipts.Warehouse,
		|	PlannedCashReceipts.Period
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTExpectedReceipt
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AvailableBalancesByDate.Products AS Products,
		|	AvailableBalancesByDate.Characteristic AS Characteristic,
		|	AvailableBalancesByDate.Warehouse AS Warehouse,
		|	MIN(AvailableBalancesByDate.Period) AS Date
		|INTO TTUpcomingAvailabilityDates
		|FROM
		|	TTAvailableBalancesByDate AS AvailableBalancesByDate
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpCharacteristic
		|		ON AvailableBalancesByDate.Warehouse = SettingUpCharacteristic.Warehouse
		|			AND AvailableBalancesByDate.Products = SettingUpCharacteristic.Products
		|			AND AvailableBalancesByDate.Characteristic = SettingUpCharacteristic.Characteristic
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpProducts
		|		ON AvailableBalancesByDate.Warehouse = SettingUpProducts.Warehouse
		|			AND AvailableBalancesByDate.Products = SettingUpProducts.Products
		|			AND (SettingUpProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|			AND (SettingUpCharacteristic.Warehouse IS NULL)
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpWarehouse
		|		ON AvailableBalancesByDate.Warehouse = SettingUpWarehouse.Warehouse
		|			AND (SettingUpWarehouse.Products = VALUE(Catalog.Products.EmptyRef))
		|			AND (SettingUpWarehouse.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|			AND (SettingUpCharacteristic.Warehouse IS NULL)
		|			AND (SettingUpProducts.Warehouse IS NULL)
		|WHERE
		|	ISNULL(SettingUpCharacteristic.AvailableStockControl, ISNULL(SettingUpProducts.AvailableStockControl, SettingUpWarehouse.AvailableStockControl))
		|
		|GROUP BY
		|	AvailableBalancesByDate.Products,
		|	AvailableBalancesByDate.Characteristic,
		|	AvailableBalancesByDate.Warehouse
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse
		|;
		|DROP InventoryAndDemandsBalance
		|;
		|DROP CalculationOfBalancesForSettingActions
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
	Texts.Add(QueryText);
	QueryText = StrConcat(Texts, Common.QueryBatchSeparator());
	QueryText = StrReplace(QueryText, "&TTProducts_1", NameOfProductsTable);
	Return QueryText;
	
EndFunction

#EndRegion


#EndIf
