#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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

#Region Internal

// Parameters:
//  Query - Query -
//  TableName - String - 
//  InstalledLocks - See AccumulationRegisters.InventoryAndDemands.SetBlockingOrdersAndProducts
//  AttachableSet - AccumulationRegisterRecordSet.InventoryAndDemands - a set from which you need to take
//                                                                         the document Registered Records that are not recorded in the database, and not from the database.
Procedure TempTableOfChartClosure(Query, TableName, InstalledLocks, AttachableSet = Undefined) Export
	
	Orders = InstalledLocks.Orders;
	RecordersAndOrders = InstalledLocks.RecordersAndOrders;
	OrderRecorders = New Map();
	For Each String In RecordersAndOrders Do
		OrderRecorders.Insert(String.OrderDocument, String.Recorder);
	EndDo;
	
	Query.SetParameter("Orders", Orders);
	Query.SetParameter("ExcludedRegistrar", Undefined);
	
	RecordsText =
		"SELECT
		|	RegisterRecords.Period AS Period,
		|	RegisterRecords.RecordType AS RecordType,
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	RegisterRecords.OrderDocument AS OrderDocument,
		|	RegisterRecords.EventDate AS EventDate,
		|	RegisterRecords.Received_1 AS Received_1,
		|	RegisterRecords.Ordered AS Ordered,
		|	RegisterRecords.ReserveAtWarehouse AS ReserveAtWarehouse,
		|	RegisterRecords.ReserveAsReceived AS ReserveAsReceived,
		|	RegisterRecords.SnoozeReservation AS SnoozeReservation,
		|	RegisterRecords.ToSupply AS ToSupply,
		|	RegisterRecords.NotProvide AS NotProvide,
		|	RegisterRecords.LockedInStock AS LockedInStock,
		|	RegisterRecords.LockedReceipt AS LockedReceipt,
		|	
			// The correspondence of the resources is blocked cash and blocked access with the resource Krazblockke.
			// The blocking resource is not closed directly, but is closed through these two resources.
			// This imposes restrictions on the Registered Recorded operations in the Movement distribution module.
			// Krazblockke =
			//	Blocked Cash (with the subject to be unblocked attribute)
			//	+ Blocked access (with the subject to be unblocked sign)
		|	CASE
		|		WHEN RegisterRecords.SubjectToUnlocking
		|			THEN RegisterRecords.LockedInStock
		|		ELSE 0
		|	END AS LockedAvailableForUnlocking,
		|	
		|	CASE
		|		WHEN RegisterRecords.SubjectToUnlocking
		|			THEN RegisterRecords.LockedReceipt
		|		ELSE 0
		|	END AS BlockedWillBeSentForUnblocking,
		|	
		|	RegisterRecords.ToUnlock AS ToUnlock,
		|
		|	RegisterRecords.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
		|	RegisterRecords.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
			// To close the resource, It has been ordered and will be received.
		|	RegisterRecords.CloseReceiptSchedule AS CloseReceiptSchedule,
		|	
			// To close the resource, access is blocked.
		|	CASE
		|		WHEN RegisterRecords.ToControlQuality
		|			THEN RegisterRecords.CloseReceiptSchedule
		|		ELSE 0
		|	END AS CloseReceiptScheduleCheckQuality,
		|	
			// To close the resource to deadlock.
		|	CASE
		|		WHEN RegisterRecords.SubjectToUnlocking
		|			THEN RegisterRecords.CloseReceiptSchedule
		|		ELSE 0
		|	END AS CloseReceiptScheduleToBeUnblocked,
		|	
			// To close resources, do not provide, to provide, postpone reserving, reservingreferences,
			// Reserve a deposit, reserve a deposit of blocked deposits, reserve a deposit of blocked deposits.
		|	RegisterRecords.CloseScheduleShipping AS CloseScheduleShipping,
		|	RegisterRecords.ReversingEntry AS ReversingEntry
		|FROM
		|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
		|WHERE
		|	RegisterRecords.OrderDocument IN(&Orders)
		|		AND NOT RegisterRecords.Recorder = &ExcludedRegistrar
		|		AND RegisterRecords.Active
		|		AND RegisterRecords.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)";
	
	If AttachableSet <> Undefined Then
		
		Query.SetParameter("AttachableSet", AttachableSet.Unload());
		Query.SetParameter("ExcludedRegistrar", AttachableSet.Filter.Recorder.Value);
		
		Texts = New Array();
		Texts.Add(RecordsText);
		
		SignPosition = StrFind(RecordsText, "AccumulationRegister.InventoryAndDemands");
		SignPosition = StrFind(RecordsText, "WHERE", , SignPosition);
		Text = Left(RecordsText, SignPosition - 1);
		Text = StrReplace(Text, "AccumulationRegister.InventoryAndDemands", "AttachableSet");
		
		Texts.Add(Text);
		RecordsText = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
		
		TemporaryTableText =
			"SELECT
			|	Set.Period AS Period,
			|	Set.RecordType AS RecordType,
			|	Set.Products AS Products,
			|	Set.Characteristic AS Characteristic,
			|	Set.Warehouse AS Warehouse,
			|	Set.Purpose AS Purpose,
			|	Set.OrderDocument AS OrderDocument,
			|	Set.EventDate AS EventDate,
			|	Set.Received_1 AS Received_1,
			|	Set.Ordered AS Ordered,
			|	Set.ReserveAtWarehouse AS ReserveAtWarehouse,
			|	Set.ReserveAsReceived AS ReserveAsReceived,
			|	Set.SnoozeReservation AS SnoozeReservation,
			|	Set.ToSupply AS ToSupply,
			|	Set.NotProvide AS NotProvide,
			|	Set.LockedReceipt AS LockedReceipt,
			|	Set.LockedInStock AS LockedInStock,
			|	Set.ToUnlock AS ToUnlock,
			|	Set.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
			|	Set.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
			|	Set.CloseReceiptSchedule AS CloseReceiptSchedule,
			|	Set.ToControlQuality AS ToControlQuality,
			|	Set.SubjectToUnlocking AS SubjectToUnlocking,
			|	Set.CloseScheduleShipping AS CloseScheduleShipping,
			|	Set.ReversingEntry AS ReversingEntry
			|INTO AttachableSet
			|FROM
			|	&AttachableSet AS Set
			|WHERE
			|	Set.Active
			|		AND Set.OrderDocument IN(&Orders)
			|		AND Set.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)";
		
	EndIf;
	
	RecordsText = StrTemplate("(%1)", RecordsText);
	Text =
		"SELECT
		|	MIN(RegisterRecords.Period) AS Period,
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	RegisterRecords.OrderDocument AS OrderDocument,
		|	RegisterRecords.EventDate AS EventDate,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.Received_1
		|			ELSE -RegisterRecords.Received_1
		|		END) AS Received_1,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.Ordered
		|			ELSE -RegisterRecords.Ordered
		|		END) AS Ordered,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.ReserveAtWarehouse
		|			ELSE -RegisterRecords.ReserveAtWarehouse
		|		END) AS ReserveAtWarehouse,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.ReserveAsReceived
		|			ELSE -RegisterRecords.ReserveAsReceived
		|		END) AS ReserveAsReceived,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.SnoozeReservation
		|			ELSE -RegisterRecords.SnoozeReservation
		|		END) AS SnoozeReservation,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.ToSupply
		|			ELSE -RegisterRecords.ToSupply
		|		END) AS ToSupply,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.NotProvide
		|			ELSE -RegisterRecords.NotProvide
		|		END) AS NotProvide,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.LockedInStock
		|			ELSE -RegisterRecords.LockedInStock
		|		END) AS LockedInStock,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.LockedReceipt
		|			ELSE -RegisterRecords.LockedReceipt
		|		END) AS LockedReceipt,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.LockedAvailableForUnlocking
		|			ELSE -RegisterRecords.LockedAvailableForUnlocking
		|		END) AS LockedAvailableForUnlocking,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.BlockedWillBeSentForUnblocking
		|			ELSE -RegisterRecords.BlockedWillBeSentForUnblocking
		|		END) AS BlockedWillBeSentForUnblocking,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
		|				THEN RegisterRecords.LockedInStock
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt) AND RegisterRecords.LockedInStock < 0
		|				THEN -RegisterRecords.LockedInStock
		|			ELSE 0
		|		END
		|			+ CASE
		// In typical operations, there is no negative arrival on the Krazblockke resource,
		// except for a corrective document in which the Registered Records are formed by technical reversal. For this amount, the Balance of the resource
		// The deadlock will be closed automatically by platform calculation of the Balance, taking into account the measurement of the event date. It is necessary to reduce the amount
		// by which we are going to close the resource to the deadlock.
		|				WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt) AND RegisterRecords.ToUnlock < 0
		|					THEN RegisterRecords.ToUnlock
		|				ELSE 0
		|			END) AS LockedInStockExpense,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.ToUnlock
		|			ELSE -RegisterRecords.ToUnlock
		|		END) AS ToUnlock,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.ReserveAtWarehouseFromLocked
		|			ELSE -RegisterRecords.ReserveAtWarehouseFromLocked
		|		END) AS ReserveAtWarehouseFromLocked,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.ReserveUponReceiptFromLocked
		|			ELSE -RegisterRecords.ReserveUponReceiptFromLocked
		|		END) AS ReserveUponReceiptFromLocked,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.CloseReceiptSchedule
		|			ELSE -RegisterRecords.CloseReceiptSchedule
		|		END) AS CloseReceiptSchedule,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.CloseReceiptScheduleCheckQuality
		|			ELSE -RegisterRecords.CloseReceiptScheduleCheckQuality
		|		END) AS CloseReceiptScheduleCheckQuality,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.CloseReceiptScheduleToBeUnblocked
		|			ELSE -RegisterRecords.CloseReceiptScheduleToBeUnblocked
		|		END) AS CloseReceiptScheduleToBeUnblocked,
		|	SUM(
		|		CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.CloseScheduleShipping
		|			ELSE -RegisterRecords.CloseScheduleShipping
		|		END) AS CloseScheduleShipping
		|INTO ChartRotations
		|FROM
		|	SetOverridable AS RegisterRecords
		|GROUP BY
		|	RegisterRecords.Products,
		|	RegisterRecords.Characteristic,
		|	RegisterRecords.Warehouse,
		|	RegisterRecords.Purpose,
		|	RegisterRecords.OrderDocument,
		|	RegisterRecords.EventDate
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, OrderDocument
		|;
		|
		|//////////////////////////////////////////////
		|SELECT
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	RegisterRecords.OrderDocument AS OrderDocument,
		|	SUM(RegisterRecords.CloseScheduleShipping) AS CloseScheduleShipping,
		|	SUM(RegisterRecords.CloseReceiptSchedule) AS CloseReceiptSchedule,
		|	SUM(RegisterRecords.CloseReceiptScheduleToBeUnblocked) AS CloseReceiptScheduleToBeUnblocked,
		|
			// For the first iteration of closing the schedule for the resource, Access is blocked.
			// when the Check Quality attribute is set in the closing records.
		|	SUM(RegisterRecords.CloseReceiptScheduleCheckQuality) AS CloseReceiptScheduleCheckQuality,
		|
			// For the second iteration of closing the schedule, the resource is 
			// blocked when the Check Quality attribute is not set in the closing records.
		|	CASE
				// The Balance is blocked. Access > The Balance is received.
		|		WHEN SUM(RegisterRecords.LockedReceipt) - SUM(RegisterRecords.CloseReceiptScheduleCheckQuality) > 0
		|				AND SUM(RegisterRecords.LockedReceipt) - SUM(RegisterRecords.CloseReceiptScheduleCheckQuality)
		|					> SUM(RegisterRecords.Received_1) - SUM(RegisterRecords.CloseReceiptSchedule)
		|				THEN
		|					CASE
		|						WHEN SUM(RegisterRecords.Received_1) - SUM(RegisterRecords.CloseReceiptSchedule) > 0
									// Close for the difference blocked Access is received.
		|							THEN
		|								SUM(RegisterRecords.LockedReceipt) - SUM(RegisterRecords.CloseReceiptScheduleCheckQuality)
		|									- (SUM(RegisterRecords.Received_1) - SUM(RegisterRecords.CloseReceiptSchedule))
								// Close blocked access in its entirety.
		|						ELSE
		|							SUM(RegisterRecords.LockedReceipt) - SUM(RegisterRecords.CloseReceiptScheduleCheckQuality)
		|					END
		|			ELSE 0
		|		END CloseReceiptScheduleDoNotCheckQuality,
		|	
			// The initial number of blocked accesses, blocked
			// accesses,blocked accesses, blocked accesses are summarized, without taking into account the receipt dates.
		|	SUM(RegisterRecords.LockedReceipt) LockedReceiptReceipt,
		|	SUM(RegisterRecords.LockedAvailableForUnlocking) AS LockedAvailableForUnlockingReceipt,
		|	SUM(RegisterRecords.BlockedWillBeSentForUnblocking) AS BlockedWillBeSentForUnblockingReceipt,
		|	
		|	SUM(RegisterRecords.LockedInStockExpense) AS LockedInStockExpense
		|INTO ChartBalances
		|FROM
		|	ChartRotations AS RegisterRecords
		|GROUP BY
		|	RegisterRecords.Products,
		|	RegisterRecords.Characteristic,
		|	RegisterRecords.Warehouse,
		|	RegisterRecords.Purpose,
		|	RegisterRecords.OrderDocument
		|HAVING
		|	SUM(RegisterRecords.CloseReceiptSchedule) > 0
		|		OR SUM(RegisterRecords.CloseScheduleShipping) > 0
		|		OR SUM(RegisterRecords.CloseReceiptScheduleCheckQuality) > 0
		|		OR SUM(RegisterRecords.CloseReceiptScheduleToBeUnblocked) > 0
		|		OR SUM(RegisterRecords.LockedInStockExpense) > 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, OrderDocument
		|;
		|
		|//////////////////////////////////////////////
		|SELECT
		|	ChartRotations.Period AS Period,
		|	ChartBalances.Products AS Products,
		|	ChartBalances.Characteristic AS Characteristic,
		|	ChartBalances.Warehouse AS Warehouse,
		|	ChartBalances.Purpose AS Purpose,
		|	ChartBalances.OrderDocument AS OrderDocument,
		|	ChartRotations.EventDate AS EventDate,
		|	CASE
		|		WHEN ChartRotations.EventDate = DATETIME(1, 1, 1) AND ChartRotations.Ordered > 0
		|			THEN 1
		|		ELSE 0
		|	END AS OrderForExpectedReceipts,
		|	
			// To close resources, do not provide, to provide, postpone reserving, reservingreferences,
			// Reserve a deposit, reserve a deposit of blocked deposits, reserve a deposit of blocked deposits.
		|	ChartBalances.CloseScheduleShipping AS CloseScheduleShipping,
		|
			// To close the resource is ordered.
		|	ChartBalances.CloseReceiptSchedule AS CloseReceiptScheduleOrdered,
		|
			// To close the resource, access is blocked.
		|	ChartBalances.CloseReceiptScheduleCheckQuality
		|		+ ChartBalances.CloseReceiptScheduleDoNotCheckQuality AS CloseReceiptScheduleBlockedIncoming,
		|	
			// To close the resource, it will be received.
		|	ChartBalances.CloseReceiptSchedule
				// Reduce closure, since the closure algorithm works like this:
				// Received - closure is blocked - accesses are closed - Accesses are closed
		|		- CASE
		|			WHEN ChartBalances.LockedReceiptReceipt
		|					- ChartBalances.CloseReceiptScheduleCheckQuality
		|					- ChartBalances.CloseReceiptScheduleDoNotCheckQuality > 0
		|				THEN ChartBalances.CloseReceiptScheduleCheckQuality
		|						+ ChartBalances.CloseReceiptScheduleDoNotCheckQuality
		|			ELSE ChartBalances.LockedReceiptReceipt
		|		END AS CloseReceiptScheduleWillBeReceived,
		|	
			// To close the resource to deadlock.
			// The first iteration for Lot references of non-received goods: the closure of the blocked accesses is subject to blocking on records
			// with the specified attribute is subject to blocking:
		|	CASE
		|		WHEN ChartBalances.BlockedWillBeSentForUnblockingReceipt < 0
		|				OR ChartBalances.BlockedWillBeSentForUnblockingReceipt < 0
		|			THEN 0
		|		WHEN ChartBalances.CloseReceiptScheduleToBeUnblocked
		|				< ChartBalances.BlockedWillBeSentForUnblockingReceipt
		|			THEN ChartBalances.CloseReceiptScheduleToBeUnblocked
		|		ELSE ChartBalances.BlockedWillBeSentForUnblockingReceipt
		|	END
			// The second iteration for batches of non-received goods: the closure of the blocked access is subject to blocking on records
			// with an unspecified attribute is subject to blocking:
			// Increase the closure, otherwise the unblocking schedule will exceed the receipt schedule of the blocked goods.
		|	+ CASE
				// The Balance of the deadlock <= 0
		|		WHEN ChartBalances.BlockedWillBeSentForUnblockingReceipt - ChartBalances.CloseReceiptScheduleToBeUnblocked < 0
		|				OR ChartBalances.BlockedWillBeSentForUnblockingReceipt < 0
		|			THEN 0
				// Balance of Blocking > Balance of blocking Accesses
		|		WHEN ChartBalances.BlockedWillBeSentForUnblockingReceipt - ChartBalances.CloseReceiptScheduleToBeUnblocked >
		|				ChartBalances.LockedReceiptReceipt
		|					- ChartBalances.CloseReceiptScheduleCheckQuality
		|					- ChartBalances.CloseReceiptScheduleDoNotCheckQuality
		|			THEN
		|				CASE
		|					WHEN
		|							ChartBalances.LockedReceiptReceipt
		|								- ChartBalances.CloseReceiptScheduleCheckQuality
		|								- ChartBalances.CloseReceiptScheduleDoNotCheckQuality > 0
		|						THEN
									// Close on the difference krazblokke - blocked access.
		|							 ChartBalances.BlockedWillBeSentForUnblockingReceipt
		|									- ChartBalances.CloseReceiptScheduleToBeUnblocked
		|								- (ChartBalances.LockedReceiptReceipt
		|									- ChartBalances.CloseReceiptScheduleCheckQuality
		|									- ChartBalances.CloseReceiptScheduleDoNotCheckQuality)
		|					ELSE
								// Close krazblockke entirely.
		|						ChartBalances.BlockedWillBeSentForUnblockingReceipt
		|							- ChartBalances.CloseReceiptScheduleToBeUnblocked
		|				END
		|		ELSE 0
		|	END
		// The first iteration for Lot references of incoming goods: closing of blocked cash and unblocking records of expense
		// from the warehouse of the goods of the Lot reference. 
		|	+ CASE
		|		WHEN ChartBalances.LockedInStockExpense < 0 OR ChartBalances.LockedAvailableForUnlockingReceipt < 0
		|			THEN 0
		|		WHEN ChartBalances.LockedInStockExpense < ChartBalances.LockedAvailableForUnlockingReceipt
		|			THEN ChartBalances.LockedInStockExpense
		|		ELSE ChartBalances.LockedAvailableForUnlockingReceipt
		|	END AS CloseUnblockingSchedule,
		|	CASE
		|		WHEN ChartRotations.Received_1 < 0
		|			THEN 0
		|		ELSE ChartRotations.Received_1
		|	END AS Received_1,
		|	CASE
		|		WHEN ChartRotations.Ordered < 0
		|			THEN 0
		|		ELSE ChartRotations.Ordered
		|	END AS Ordered,
		|	CASE
		|		WHEN ChartRotations.ReserveAtWarehouse < 0
		|			THEN 0
		|		ELSE ChartRotations.ReserveAtWarehouse
		|	END AS ReserveAtWarehouse,
		|	CASE
		|		WHEN ChartRotations.ReserveAsReceived < 0
		|			THEN 0
		|		ELSE ChartRotations.ReserveAsReceived
		|	END AS ReserveAsReceived,
		|	CASE
		|		WHEN ChartRotations.SnoozeReservation < 0
		|			THEN 0
		|		ELSE ChartRotations.SnoozeReservation
		|	END AS SnoozeReservation,
		|	CASE
		|		WHEN ChartRotations.ToSupply < 0
		|			THEN 0
		|		ELSE ChartRotations.ToSupply
		|	END AS ToSupply,
		|	CASE
		|		WHEN ChartRotations.NotProvide < 0
		|			THEN 0
		|		ELSE ChartRotations.NotProvide
		|	END AS NotProvide,
		|	CASE
		|		WHEN ChartRotations.LockedReceipt < 0
		|			THEN 0
		|		ELSE ChartRotations.LockedReceipt
		|	END AS LockedReceipt,
		|	CASE
		|		WHEN ChartRotations.ToUnlock < 0
		|			THEN 0
		|		ELSE ChartRotations.ToUnlock
		|	END AS ToUnlock,
		|	CASE
		|		WHEN ChartRotations.ReserveAtWarehouseFromLocked < 0
		|			THEN 0
		|		ELSE ChartRotations.ReserveAtWarehouseFromLocked
		|	END AS ReserveAtWarehouseFromLocked,
		|	CASE
		|		WHEN ChartRotations.ReserveUponReceiptFromLocked < 0
		|			THEN 0
		|		ELSE ChartRotations.ReserveUponReceiptFromLocked
		|	END AS ReserveUponReceiptFromLocked
		|FROM
		|	ChartBalances AS ChartBalances
		|		INNER JOIN ChartRotations AS ChartRotations
		|		ON ChartRotations.Products = ChartBalances.Products
		|		 AND ChartRotations.Characteristic = ChartBalances.Characteristic
		|		 AND ChartRotations.Warehouse = ChartBalances.Warehouse
		|		 AND ChartRotations.Purpose = ChartBalances.Purpose
		|		 AND ChartRotations.OrderDocument = ChartBalances.OrderDocument
		|		 AND (ChartRotations.Ordered > 0 AND ChartBalances.CloseReceiptSchedule > 0
		|				OR ChartRotations.Received_1 > 0 AND ChartBalances.CloseReceiptSchedule > 0
		|				OR ChartRotations.Received_1 > 0 AND ChartBalances.CloseReceiptScheduleCheckQuality > 0
		|				OR ChartRotations.LockedReceipt > 0 AND ChartBalances.CloseReceiptScheduleCheckQuality > 0
		|				OR ChartRotations.LockedReceipt > 0 AND ChartBalances.CloseReceiptScheduleDoNotCheckQuality > 0
		|				OR ChartRotations.ToUnlock > 0 AND ChartBalances.CloseReceiptScheduleToBeUnblocked > 0
		|				OR ChartRotations.ToUnlock > 0 AND ChartBalances.CloseReceiptScheduleCheckQuality > 0
		|				OR ChartRotations.ToUnlock > 0 AND ChartBalances.CloseReceiptScheduleDoNotCheckQuality > 0
		|				OR ChartRotations.ToUnlock > 0 AND ChartBalances.LockedAvailableForUnlockingReceipt > 0 AND ChartBalances.LockedInStockExpense > 0
		|				OR ChartRotations.ReserveAtWarehouse > 0 AND ChartBalances.CloseScheduleShipping > 0
		|				OR ChartRotations.ReserveAsReceived > 0 AND ChartBalances.CloseScheduleShipping > 0
		|				OR ChartRotations.ReserveAtWarehouseFromLocked > 0 AND ChartBalances.CloseScheduleShipping > 0
		|				OR ChartRotations.ReserveUponReceiptFromLocked > 0 AND ChartBalances.CloseScheduleShipping > 0
		|				OR ChartRotations.SnoozeReservation > 0 AND ChartBalances.CloseScheduleShipping > 0
		|				OR ChartRotations.ToSupply > 0 AND ChartBalances.CloseScheduleShipping > 0
		|				OR ChartRotations.NotProvide > 0 AND ChartBalances.CloseScheduleShipping > 0)
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	OrderDocument,
		|	OrderForExpectedReceipts,
		|	EventDate,
		|	Period,
		|	Received_1 DESC,
		|	ReserveAtWarehouse DESC,
		|	ReserveAsReceived DESC,
		|	ReserveAtWarehouseFromLocked DESC,
		|	ReserveUponReceiptFromLocked DESC,
		|	SnoozeReservation DESC,
		|	ToSupply DESC,
		|	NotProvide DESC
		|;
		|
		|/////////////////////////
		|DROP ChartBalances;
		|DROP ChartRotations";
	
	OffsetInPacket = 3;
	Text = StrReplace(Text, "SetOverridable", RecordsText);
	If AttachableSet <> Undefined Then
		
		Texts = New Array();
		Texts.Add(TemporaryTableText);
		Texts.Add(Text);
		Texts.Add("DROP AttachableSet");
		Text = StrConcat(Texts, Common.QueryBatchSeparator());
		
		OffsetInPacket = OffsetInPacket + 1;
		
	EndIf;
		
	Query.Text = Text;
	
	ResultsPackage = Query.ExecuteBatch();
	Schedule = ResultsPackage[ResultsPackage.Count() - OffsetInPacket].Unload(); // ValueTable -
	Schedule.Columns.Add("ThereIsSchedule", New TypeDescription("Boolean"));
	Schedule.Columns.Add("Recorder",
		Metadata.AccumulationRegisters.InventoryAndDemands.StandardAttributes.Recorder.Type);
	
	Products = Undefined;
	Characteristic = Undefined;
	Warehouse = Undefined;
	Purpose = Undefined;
	OrderDocument = Undefined;
	
	For IndexOf = 0 To Schedule.Count() - 1 Do
		
		CurRow = Schedule[IndexOf];
		If CurRow.Products <> Products
				Or CurRow.Characteristic <> Characteristic
				Or CurRow.Warehouse <> Warehouse
				Or CurRow.Purpose <> Purpose
				Or CurRow.OrderDocument <> OrderDocument Then
				
				Products = CurRow.Products;
				Characteristic = CurRow.Characteristic;
				Warehouse = CurRow.Warehouse;
				Purpose = CurRow.Purpose;
				OrderDocument = CurRow.OrderDocument;
				CloseReceiptScheduleOrdered = Max(CurRow.CloseReceiptScheduleOrdered, 0);
				CloseReceiptScheduleWillBeReceived = Max(CurRow.CloseReceiptScheduleWillBeReceived, 0); // Here is the amount that needs to be closed in addition to the closing of the blockingapproachability
				CloseReceiptScheduleBlockedIncoming = Max(CurRow.CloseReceiptScheduleBlockedIncoming, 0);
				CloseUnblockingSchedule = Max(CurRow.CloseUnblockingSchedule, 0);
				CloseScheduleShipping = Max(CurRow.CloseScheduleShipping, 0);
		EndIf;
		
		LockedReceipt = Min(CurRow.LockedReceipt, CloseReceiptScheduleBlockedIncoming);
		CloseReceiptScheduleBlockedIncoming = CloseReceiptScheduleBlockedIncoming - LockedReceipt;
		CurRow.LockedReceipt = -LockedReceipt;
		
		ReceivedBlocked = Min(CurRow.Received_1, LockedReceipt);
		
		Received_1 = Min(CurRow.Received_1 - ReceivedBlocked, CloseReceiptScheduleWillBeReceived);
		CloseReceiptScheduleWillBeReceived = CloseReceiptScheduleWillBeReceived - Received_1;
		CurRow.Received_1 = - Received_1 - ReceivedBlocked;
		
		OrderedReceived = Min(CurRow.Ordered, Received_1 + ReceivedBlocked);
		CloseReceiptScheduleOrdered = CloseReceiptScheduleOrdered - OrderedReceived;
		
		Ordered = Min(CurRow.Ordered - OrderedReceived, CloseReceiptScheduleOrdered);
		CloseReceiptScheduleOrdered = CloseReceiptScheduleOrdered - Ordered;
		CurRow.Ordered = - Ordered - OrderedReceived;
		
		ToUnlock = Min(CurRow.ToUnlock, CloseUnblockingSchedule);
		CloseUnblockingSchedule = CloseUnblockingSchedule - ToUnlock;
		CurRow.ToUnlock = - ToUnlock;
		
		Demand = Min(CurRow.ReserveAtWarehouse, CloseScheduleShipping);
		CloseScheduleShipping = CloseScheduleShipping - Demand;
		CurRow.ReserveAtWarehouse = - Demand;
		
		Demand = Min(CurRow.ReserveAsReceived, CloseScheduleShipping);
		CloseScheduleShipping = CloseScheduleShipping - Demand;
		CurRow.ReserveAsReceived = - Demand;
		
		Demand = Min(CurRow.ReserveAtWarehouseFromLocked, CloseScheduleShipping);
		CloseScheduleShipping = CloseScheduleShipping - Demand;
		CurRow.ReserveAtWarehouseFromLocked = - Demand;
		
		Demand = Min(CurRow.ReserveUponReceiptFromLocked, CloseScheduleShipping);
		CloseScheduleShipping = CloseScheduleShipping - Demand;
		CurRow.ReserveUponReceiptFromLocked = - Demand;
		
		Demand = Min(CurRow.SnoozeReservation, CloseScheduleShipping);
		CloseScheduleShipping = CloseScheduleShipping - Demand;
		CurRow.SnoozeReservation = - Demand;
		
		Demand = Min(CurRow.ToSupply, CloseScheduleShipping);
		CloseScheduleShipping = CloseScheduleShipping - Demand;
		CurRow.ToSupply = - Demand;
		
		Demand = Min(CurRow.NotProvide, CloseScheduleShipping);
		CloseScheduleShipping = CloseScheduleShipping - Demand;
		CurRow.NotProvide = - Demand;
		
		CurRow.Recorder = OrderRecorders.Get(CurRow.OrderDocument);
		CurRow.ThereIsSchedule = CurRow.Received_1 < 0
			Or CurRow.Ordered < 0
			Or CurRow.ReserveAtWarehouse < 0
			Or CurRow.ReserveAsReceived < 0
			Or CurRow.LockedReceipt < 0
			Or CurRow.ToUnlock < 0
			Or CurRow.ReserveAtWarehouseFromLocked < 0
			Or CurRow.ReserveUponReceiptFromLocked < 0
			Or CurRow.SnoozeReservation < 0
			Or CurRow.ToSupply < 0
			Or CurRow.NotProvide < 0;
		
	EndDo;
	Query.SetParameter("TableScheduleOfAdmission", Schedule.Copy(New Structure("ThereIsSchedule", True)));
	Text =
		"SELECT
		|	Schedule.Recorder AS Recorder,
		|	Schedule.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	TRUE AS Active,
		|	Schedule.Products AS Products,
		|	Schedule.Characteristic AS Characteristic,
		|	Schedule.Warehouse AS Warehouse,
		|	Schedule.Purpose AS Purpose,
		|	Schedule.OrderDocument AS OrderDocument,
		|	Schedule.EventDate AS EventDate,
		|	0 AS InStock,
		|	Schedule.Received_1 AS Received_1,
		|	Schedule.Ordered AS Ordered,
		|	Schedule.ReserveAtWarehouse AS ReserveAtWarehouse,
		|	Schedule.ReserveAsReceived AS ReserveAsReceived,
		|	Schedule.SnoozeReservation AS SnoozeReservation,
		|	Schedule.ToSupply AS ToSupply,
		|	Schedule.NotProvide AS NotProvide,
		|	0 AS LockedInStock,
		|	Schedule.LockedReceipt AS LockedReceipt,
		|	Schedule.ToUnlock AS ToUnlock,
		|	Schedule.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
		|	Schedule.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	0 AS CloseReceiptSchedule,
		|	0 AS CloseScheduleShipping,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.CreateSchedule) AS EntryType,
		|	FALSE AS ReversingEntry
		|INTO TableOverridable
		|FROM
		|	&TableScheduleOfAdmission AS Schedule
		|INDEX BY
		|	Recorder";
	
	Query.Text = StrReplace(Text, "TableOverridable", TableName);
	Query.Execute();
	
EndProcedure

// Parameters:
//  InstalledLocks - See AccumulationRegisters.InventoryAndDemands.SetBlockingOrdersAndProducts
//  Query - Query -
//  ExcludedRegistrar - AnyRef
Procedure RecordResultOfGraphCalculation(InstalledLocks, Query, ExcludedRegistrar = Undefined) Export
	
	Recorders = InstalledLocks.RecordersAndOrders.Copy();
	Recorders.GroupBy("Recorder");
	Recorders = Recorders.UnloadColumn("Recorder");
	Item = Recorders.Find(ExcludedRegistrar);
	If Item <> Undefined Then
		Recorders.Delete(Item);
	EndIf;
	
	RecordsetGraph = CreateRecordSet();
	RecordsetGraph.DataExchange.Load = True;
	For Each Recorder In Recorders Do
		
		Query.SetParameter("Recorder", Recorder);
		
		Query.Text =
			"SELECT
			|	RegisterRecords.Recorder AS Recorder,
			|	RegisterRecords.Period AS Period,
			|	RegisterRecords.RecordType AS RecordType,
			|	RegisterRecords.Active AS Active,
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose,
			|	RegisterRecords.OrderDocument AS OrderDocument,
			|	RegisterRecords.EventDate AS EventDate,
			|	RegisterRecords.InStock AS InStock,
			|	RegisterRecords.Received_1 AS Received_1,
			|	RegisterRecords.Ordered AS Ordered,
			|	RegisterRecords.ReserveAtWarehouse AS ReserveAtWarehouse,
			|	RegisterRecords.ReserveAsReceived AS ReserveAsReceived,
			|	RegisterRecords.SnoozeReservation AS SnoozeReservation,
			|	RegisterRecords.ToSupply AS ToSupply,
			|	RegisterRecords.NotProvide AS NotProvide,
			|	RegisterRecords.LockedInStock AS LockedInStock,
			|	RegisterRecords.LockedReceipt AS LockedReceipt,
			|	RegisterRecords.ToUnlock AS ToUnlock,
			|	RegisterRecords.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
			|	RegisterRecords.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
			|	RegisterRecords.CloseReceiptSchedule AS CloseReceiptSchedule,
			|	RegisterRecords.ToControlQuality AS ToControlQuality,
			|	RegisterRecords.SubjectToUnlocking AS SubjectToUnlocking,
			|	RegisterRecords.CloseScheduleShipping AS CloseScheduleShipping,
			|	RegisterRecords.OrderToShip AS OrderToShip,
			|	RegisterRecords.EntryType AS EntryType,
			|	RegisterRecords.ReversingEntry AS ReversingEntry
			|FROM
			|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
			|WHERE
			|	RegisterRecords.Recorder = &Recorder
			|		AND (RegisterRecords.EntryType IN(
			|				VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord),
			|				VALUE(Enum.RecordTypesInventoryAndDemands.DeferredReservation))
			|			OR NOT RegisterRecords.OrderDocument IN(&Orders))
			|
			|UNION ALL
			|
			|SELECT
			|	CalculationResults.Recorder AS Recorder,
			|	CalculationResults.Period AS Period,
			|	CalculationResults.RecordType AS RecordType,
			|	CalculationResults.Active AS Active,
			|	CalculationResults.Products AS Products,
			|	CalculationResults.Characteristic AS Characteristic,
			|	CalculationResults.Warehouse AS Warehouse,
			|	CalculationResults.Purpose AS Purpose,
			|	CalculationResults.OrderDocument AS OrderDocument,
			|	CalculationResults.EventDate AS EventDate,
			|	CalculationResults.InStock AS InStock,
			|	CalculationResults.Received_1 AS Received_1,
			|	CalculationResults.Ordered AS Ordered,
			|	CalculationResults.ReserveAtWarehouse AS ReserveAtWarehouse,
			|	CalculationResults.ReserveAsReceived AS ReserveAsReceived,
			|	CalculationResults.SnoozeReservation AS SnoozeReservation,
			|	CalculationResults.ToSupply AS ToSupply,
			|	CalculationResults.NotProvide AS NotProvide,
			|	CalculationResults.LockedInStock AS LockedInStock,
			|	CalculationResults.LockedReceipt AS LockedReceipt,
			|	CalculationResults.ToUnlock AS ToUnlock,
			|	CalculationResults.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
			|	CalculationResults.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
			|	CalculationResults.CloseReceiptSchedule AS CloseReceiptSchedule,
			|	CalculationResults.ToControlQuality AS ToControlQuality,
			|	CalculationResults.SubjectToUnlocking AS SubjectToUnlocking,
			|	CalculationResults.CloseScheduleShipping AS CloseScheduleShipping,
			|	UNDEFINED AS OrderToShip,
			|	CalculationResults.EntryType AS EntryType,
			|	CalculationResults.ReversingEntry AS ReversingEntry
			|FROM
			|	GraphCalculationResults AS CalculationResults
			|WHERE
			|	CalculationResults.Recorder = &Recorder";
			
		Table = Query.Execute().Unload();
		RecordsetGraph.Filter.Recorder.Set(Recorder);
		RecordsetGraph.Load(Table);
		RecordsetGraph.Write();
		
	EndDo

EndProcedure

// Parameters:
//  Set - AccumulationRegisterRecordSet.InventoryAndDemands -
Procedure AddDeferredCollateralRecordsToSet(Set) Export
	
	If Set.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("TableOfGoods", Set.Unload());
	Query.SetParameter("Recorder", Set[0].Recorder);
	
	Texts = New Array();
	Text =
		"SELECT
		|	RegisterRecords.Recorder AS Recorder,
		|	RegisterRecords.Period AS Period,
		|	RegisterRecords.RecordType AS RecordType,
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	RegisterRecords.OrderDocument AS OrderDocument,
		|	RegisterRecords.EventDate AS EventDate,
		|	RegisterRecords.InStock AS InStock,
		|	RegisterRecords.Received_1 AS Received_1,
		|	RegisterRecords.Ordered AS Ordered,
		|	RegisterRecords.ReserveAtWarehouse AS ReserveAtWarehouse,
		|	RegisterRecords.ReserveAsReceived AS ReserveAsReceived,
		|	RegisterRecords.SnoozeReservation AS SnoozeReservation,
		|	RegisterRecords.ToSupply AS ToSupply,
		|	RegisterRecords.NotProvide AS NotProvide,
		|	RegisterRecords.LockedInStock AS LockedInStock,
		|	RegisterRecords.LockedReceipt AS LockedReceipt,
		|	RegisterRecords.ToUnlock AS ToUnlock,
		|	RegisterRecords.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
		|	RegisterRecords.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
		|	RegisterRecords.CloseReceiptSchedule AS CloseReceiptSchedule,
		|	RegisterRecords.ToControlQuality AS ToControlQuality,
		|	RegisterRecords.SubjectToUnlocking AS SubjectToUnlocking,
		|	RegisterRecords.CloseScheduleShipping AS CloseScheduleShipping
		|INTO RegisteredRecordsDuringRecording
		|FROM
		|	&TableOfGoods AS RegisterRecords";
	Texts.Add(Text);
	
	If Set.AdditionalProperties.Property("UpdatingDeferredCollateral") Then
		Text =
			"SELECT TOP 1
			|	TRUE AS ThereAreRecords
			|INTO RecountIsRequired";
	Else
		Text =
			"SELECT TOP 1
			|	TRUE AS ThereAreRecords
			|INTO RecountIsRequired
			|FROM(
			|	SELECT
			|		RegisterRecords.Recorder AS Recorder,
			|		RegisterRecords.Period AS Period,
			|		RegisterRecords.RecordType AS RecordType,
			|		RegisterRecords.Products AS Products,
			|		RegisterRecords.Characteristic AS Characteristic,
			|		RegisterRecords.Warehouse AS Warehouse,
			|		RegisterRecords.Purpose AS Purpose,
			|		RegisterRecords.OrderDocument AS OrderDocument,
			|		RegisterRecords.EventDate AS EventDate,
			|		RegisterRecords.InStock AS InStock,
			|		RegisterRecords.Received_1 AS Received_1,
			|		RegisterRecords.Ordered AS Ordered,
			|		RegisterRecords.ReserveAtWarehouse AS ReserveAtWarehouse,
			|		RegisterRecords.ReserveAsReceived AS ReserveAsReceived,
			|		RegisterRecords.SnoozeReservation AS SnoozeReservation,
			|		RegisterRecords.ToSupply AS ToSupply,
			|		RegisterRecords.NotProvide AS NotProvide,
			|		RegisterRecords.LockedInStock AS LockedInStock,
			|		RegisterRecords.LockedReceipt AS LockedReceipt,
			|		RegisterRecords.ToUnlock AS ToUnlock,
			|		RegisterRecords.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
			|		RegisterRecords.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
			|		RegisterRecords.CloseReceiptSchedule AS CloseReceiptSchedule,
			|		RegisterRecords.ToControlQuality AS ToControlQuality,
			|		RegisterRecords.SubjectToUnlocking AS SubjectToUnlocking,
			|		RegisterRecords.CloseScheduleShipping AS CloseScheduleShipping
			|	FROM
			|		RegisteredRecordsDuringRecording AS RegisterRecords
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		RegisterRecords.Recorder AS Recorder,
			|		RegisterRecords.Period AS Period,
			|		RegisterRecords.RecordType AS RecordType,
			|		RegisterRecords.Products AS Products,
			|		RegisterRecords.Characteristic AS Characteristic,
			|		RegisterRecords.Warehouse AS Warehouse,
			|		RegisterRecords.Purpose AS Purpose,
			|		RegisterRecords.OrderDocument AS OrderDocument,
			|		RegisterRecords.EventDate AS EventDate,
			|		-RegisterRecords.InStock AS InStock,
			|		-RegisterRecords.Received_1 AS Received_1,
			|		-RegisterRecords.Ordered AS Ordered,
			|		-RegisterRecords.ReserveAtWarehouse AS ReserveAtWarehouse,
			|		-RegisterRecords.ReserveAsReceived AS ReserveAsReceived,
			|		-RegisterRecords.SnoozeReservation AS SnoozeReservation,
			|		-RegisterRecords.ToSupply AS ToSupply,
			|		-RegisterRecords.NotProvide AS NotProvide,
			|		-RegisterRecords.LockedInStock AS LockedInStock,
			|		-RegisterRecords.LockedReceipt AS LockedReceipt,
			|		-RegisterRecords.ToUnlock AS ToUnlock,
			|		-RegisterRecords.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
			|		-RegisterRecords.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
			|		-RegisterRecords.CloseReceiptSchedule AS CloseReceiptSchedule,
			|		RegisterRecords.ToControlQuality AS ToControlQuality,
			|		RegisterRecords.SubjectToUnlocking AS SubjectToUnlocking,
			|		-RegisterRecords.CloseScheduleShipping AS CloseScheduleShipping
			|	FROM
			|		AccumulationRegister.InventoryAndDemands AS RegisterRecords
			|	WHERE
			|		RegisterRecords.Recorder = &Recorder
			|			AND RegisterRecords.Active
			|			AND RegisterRecords.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)) AS Changes
			|GROUP BY
			|	Changes.Recorder,
			|	Changes.Period,
			|	Changes.RecordType,
			|	Changes.Products,
			|	Changes.Characteristic,
			|	Changes.Warehouse,
			|	Changes.Purpose,
			|	Changes.OrderDocument,
			|	Changes.EventDate,
			|	Changes.ToControlQuality,
			|	Changes.SubjectToUnlocking
			|HAVING
			|	SUM(Changes.InStock) <> 0
			|		OR SUM(Changes.Received_1) <> 0
			|		OR SUM(Changes.Ordered) <> 0
			|		OR SUM(Changes.ReserveAtWarehouse) <> 0
			|		OR SUM(Changes.ReserveAsReceived) <> 0
			|		OR SUM(Changes.SnoozeReservation) <> 0
			|		OR SUM(Changes.ToSupply) <> 0
			|		OR SUM(Changes.NotProvide) <> 0
			|		OR SUM(Changes.LockedInStock) <> 0
			|		OR SUM(Changes.LockedReceipt) <> 0
			|		OR SUM(Changes.ToUnlock) <> 0
			|		OR SUM(Changes.ReserveAtWarehouseFromLocked) <> 0
			|		OR SUM(Changes.ReserveUponReceiptFromLocked) <> 0
			|		OR SUM(Changes.CloseReceiptSchedule) <> 0
			|		OR SUM(Changes.CloseScheduleShipping) <> 0";
	EndIf;
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	RegisterRecords.Recorder AS Recorder,
		|	RegisterRecords.Period AS Period,
		|	RegisterRecords.RecordType AS RecordType,
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	RegisterRecords.OrderDocument AS OrderDocument,
		|	RegisterRecords.EventDate AS EventDate,
		|	RegisterRecords.ReserveAsReceived AS ReserveAsReceived
		|INTO Rows
		|FROM
		|	RegisteredRecordsDuringRecording AS RegisterRecords
		|		
		|		LEFT JOIN RecountIsRequired AS RecountIsRequired
		|		ON RecountIsRequired.ThereAreRecords
		|WHERE
		|	RegisterRecords.ReserveAsReceived <> 0
		|		AND RegisterRecords.EventDate > &CurrentDayStart
		|		AND NOT RecountIsRequired.ThereAreRecords IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Rows.Products AS Products,
		|	Rows.Characteristic AS Characteristic,
		|	Rows.Warehouse AS Warehouse
		|INTO VariousProductsWithoutAppointments
		|FROM
		|	Rows AS Rows
		|INDEX BY
		|	Products, Characteristic, Warehouse";
		
	Texts.Add(Text);
	
	Text = ProvisionInDocumentsServer.TempTableBoundariesOfSupplyPeriod(
		"VariousProductsWithoutAppointments", "&CurrentDayStart");
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	TableOfGoods.Recorder AS Recorder,
		|	TableOfGoods.Period AS Period,
		|	TableOfGoods.RecordType AS RecordType,
		|	TRUE AS Active,
		|	TableOfGoods.Products AS Products,
		|	TableOfGoods.Characteristic AS Characteristic,
		|	TableOfGoods.Warehouse AS Warehouse,
		|	TableOfGoods.Purpose AS Purpose,
		|	TableOfGoods.OrderDocument AS OrderDocument,
		|	TableOfGoods.EventDate AS EventDate,
		|	0 AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS ReserveAtWarehouse,
		|	-TableOfGoods.ReserveAsReceived AS ReserveAsReceived,
		|	TableOfGoods.ReserveAsReceived AS SnoozeReservation,
		|	0 AS ToSupply,
		|	0 AS NotProvide,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock,
		|	0 AS ReserveAtWarehouseFromLocked,
		|	0 AS ReserveUponReceiptFromLocked,
		|	0 AS CloseReceiptSchedule,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	0 AS CloseScheduleShipping,
		|	VALUE(Enum.RecordTypesInventoryAndDemands.DeferredReservation) AS EntryType,
		|	FALSE AS ReversingEntry
		|FROM
		|	Rows AS TableOfGoods
		|		INNER JOIN LimitsOfSecurityPeriod AS Boundaries
		|		ON Boundaries.Products = TableOfGoods.Products
		|		 AND Boundaries.Characteristic = TableOfGoods.Characteristic
		|		 AND Boundaries.Warehouse = TableOfGoods.Warehouse
		|		 AND Boundaries.PeriodBoundary < TableOfGoods.EventDate
		|		 AND Boundaries.PeriodBoundary > DATETIME(1, 1, 1)
		|
		|UNION ALL
		|
		|SELECT
		|	RegisterRecords.Recorder AS Recorder,
		|	RegisterRecords.Period AS Period,
		|	RegisterRecords.RecordType AS RecordType,
		|	TRUE AS Active,
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	RegisterRecords.OrderDocument AS OrderDocument,
		|	RegisterRecords.EventDate AS EventDate,
		|	RegisterRecords.InStock AS InStock,
		|	RegisterRecords.Received_1 AS Received_1,
		|	RegisterRecords.Ordered AS Ordered,
		|	RegisterRecords.ReserveAtWarehouse AS ReserveAtWarehouse,
		|	RegisterRecords.ReserveAsReceived AS ReserveAsReceived,
		|	RegisterRecords.SnoozeReservation AS SnoozeReservation,
		|	RegisterRecords.ToSupply AS ToSupply,
		|	RegisterRecords.NotProvide AS NotProvide,
		|	RegisterRecords.LockedInStock AS LockedInStock,
		|	RegisterRecords.LockedReceipt AS LockedReceipt,
		|	RegisterRecords.ToUnlock AS ToUnlock,
		|	RegisterRecords.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
		|	RegisterRecords.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
		|	RegisterRecords.CloseReceiptSchedule AS CloseReceiptSchedule,
		|	RegisterRecords.ToControlQuality AS ToControlQuality,
		|	RegisterRecords.SubjectToUnlocking AS SubjectToUnlocking,
		|	RegisterRecords.CloseScheduleShipping AS CloseScheduleShipping,
		|	RegisterRecords.EntryType AS EntryType,
		|	RegisterRecords.ReversingEntry AS ReversingEntry
		|FROM
		|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
		|		
		|		LEFT JOIN RecountIsRequired AS RecountIsRequired
		|		ON RecountIsRequired.ThereAreRecords
		|WHERE
		|	RegisterRecords.Recorder = &Recorder
		|		AND RegisterRecords.Active
		|		AND RegisterRecords.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.DeferredReservation)
		|		AND RecountIsRequired.ThereAreRecords IS NULL";
		
	Texts.Add(Text);
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.TempTablesManager = New TempTablesManager;
	TableOfDeferredCollateral = Query.Execute().Unload();
	
	TMCommonUseClientServer.SupplementTable(TableOfDeferredCollateral, Set);
	
EndProcedure

// Parameters:
//  RecordSet - AccumulationRegisterRecordSet.InventoryAndDemands - recordable set
//  Ref - AnyRef - a recordable document.
//  ThisIsIBUpdate - Boolean - indicates that locks need to be set from the Inventory register update handler.
// Returns:
// Structure - structure with fields:
//  * RecordersAndOrders - ValueTable - table with column:
//   ** Recorder - AnyRef - a document, including a service inventory recorder, for which
//                                  locks are installed, and which requires the calculation of Register Records for closing the schedule.
//   ** OrderDocument - DefinedType.ExpectedShipmentOrReceipt - the dimension value is the order corresponding to this registrar.
//  * Orders - Array of DefinedType.ExpectedShipmentOrReceipt - an array of measurement values of the order for which
//                                  the locks are set, and which requires the calculation of Registered Records for closing the schedule.
Function SetBlockingOrdersAndProducts(RecordSet, Ref, ThisIsIBUpdate) Export
	
	Query = New Query();
	Orders = RecordSet.Unload(, "OrderDocument");
	Query.SetParameter("Orders", Orders);
	Query.SetParameter("Recorder", Ref);
	
	Query.Text =
		"SELECT DISTINCT
		|	Orders.OrderDocument AS OrderDocument
		|INTO OrdersWhenRecording
		|FROM
		|	&Orders AS Orders
		|WHERE
		|	Orders.OrderDocument <> UNDEFINED
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////
		// The shared lock on the document has already been installed, so you can read the movements of the document from the database
		// since the document cannot be recorded/changed, which means they cannot change its movements.
		|SELECT DISTINCT
		|	RegisterRecords.OrderDocument AS Ref
		|INTO VariousDocumentsContractsAndLotReferences
		|FROM
		|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
		|WHERE
		|	RegisterRecords.Recorder = &Recorder
		|		AND RegisterRecords.Active
		|		AND RegisterRecords.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)
		|		AND RegisterRecords.OrderDocument <> UNDEFINED
		|
		|UNION
		|
		|SELECT
		|	RegisterRecords.OrderDocument AS Ref
		|FROM
		|	OrdersWhenRecording AS RegisterRecords
		|INDEX BY
		|Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////
		// The index in the package is 2. The values of the "Order" change for setting a controlled lock.
		|SELECT
		|	References.Ref AS OrderDocument,
		|	VALUE(Catalog.Products.EmptyRef) AS Products
		|FROM
		|	VariousDocumentsContractsAndLotReferences AS References
		|WHERE
		// If the Lot reference in the document is not filled in, but there is a flag to check the quality. These Registered Records are incorrect.
		|	References.Ref <> VALUE(Catalog.ControlledLots.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	References.Ref AS OrderDocument,
		|	VALUE(Catalog.Products.EmptyRef) AS Products
		|FROM
		|	VariousDocumentsContractsAndLotReferences AS References
		|WHERE
		// If the Lot reference in the document is not filled in, but there is a flag to check the quality. These Registered Records are incorrect.
		|	References.Ref <> VALUE(Catalog.ControlledLots.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(References.Ref.Lot, References.Ref) AS Ref,
		|	References.Ref AS OrderDocument
		|INTO VariousDocumentsAndContracts
		|FROM
		|	VariousDocumentsContractsAndLotReferences AS References
		|WHERE
		// If the Lot reference in the document is not filled in, but there is a flag to check the quality. These Registered Records are incorrect.
		|	References.Ref <> VALUE(Catalog.ControlledLots.EmptyRef)
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////
		// The index in the package is 5. Recorders for setting a controlled lock.
		|SELECT
		|	0 AS Order,
		|	MIN(Table.Ref) AS Recorder,
		|	References.Ref AS OrderDocument
		|FROM
		|	VariousDocumentsAndContracts AS References
		|		INNER JOIN Document.VendorContractVendorAgreementRecorder AS Table
		|		ON Table.ReferenceOrder = References.Ref
		|GROUP BY
		|	References.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	1 AS Order,
		|	References.Ref AS Recorder,
		|	References.OrderDocument AS OrderDocument
		|FROM
		|	VariousDocumentsAndContracts AS References
		|WHERE
		|	NOT VALUETYPE(References.Ref) IN(
		|		TYPE(Catalog.TermsOfPurchaseFromVendors),
		|		TYPE(Catalog.CounterpartyContracts))
		|
		|UNION ALL
		|
		|SELECT
		|	2 AS Order,
		|	&Recorder AS Recorder,
		|	UNDEFINED AS OrderDocument
		|ORDER BY
		|	Order
		|;
		|
		|///////////////////////////////
		|SELECT TOP 1
		|	TRUE AS ThereAreEmptyLotReferences
		|FROM
		|	VariousDocumentsContractsAndLotReferences AS References
		|WHERE
		// If the Lot reference in the document is not filled in, but there is a flag to check the quality. These Registered Records are incorrect.
		|	References.Ref = VALUE(Catalog.ControlledLots.EmptyRef)";
		
	ResultsPackage = Query.ExecuteBatch();
	Orders = ResultsPackage[2];
	RecordersAndOrders = ResultsPackage[5];
	
	ThereAreEmptyLotReferences = Not ResultsPackage[6].IsEmpty();
	If ThereAreEmptyLotReferences Then
		
		ErrorText = DetailErrorDescription(ErrorInfo());
		MessageText = NStr("vi = 'Các bút toán không hợp lệ trên lô hàng được kiểm soát khi kết chuyển: %1.';
							|ru = 'Некорректные движения по контролируемой партии при проведении: %1.';
							|en = 'Incorrect controlled lot records when posting: %1.'; fa = 'Incorrect controlled lot records when posting: %1.';
							|it = 'Incorrect controlled lot records when posting: %1.';
							|pl = 'Incorrect controlled lot records when posting: %1.';
							|tr = 'İşlenirken kontrollü lotta geçersiz hareketler: %1.'");
		MessageText = StrTemplate(MessageText, Ref);
		LogEvent = InfobaseUpdate.EventLogEvent();
		WriteLogEvent(
			LogEvent,
			EventLogLevel.Error,
			Metadata.AccumulationRegisters.InventoryAndDemands,
			RecordSet,
			MessageText);
		
	EndIf;
	
	DataLock = New DataLock();
	
	LockItem = DataLock.Add("AccumulationRegister.InventoryAndDemands");
	
	// Registrars are waiting with the same orders as the Cur registrar.
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = Orders;
	LockItem.UseFromDataSource("OrderDocument", "OrderDocument");
	LockItem.UseFromDataSource("Products", "Products");
	
	// It is necessary to responsibly read the Product specified in the orders of our document, and then put settlement records under the orders.
	LockItem = DataLock.Add("AccumulationRegister.InventoryAndDemands.RecordSet");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = RecordersAndOrders;
	LockItem.UseFromDataSource("Recorder", "Recorder");
	
	//@skip-check lock-out-of-try
	DataLock.Lock();
	
	RecordersAndOrders = RecordersAndOrders.Unload();
	Recorders = RecordersAndOrders.UnloadColumn("Recorder"); // values can be repeated
	Query.SetParameter("GoodsTable", RecordSet.Unload());
	
	QueryTexts = New Array();
	QueryTexts.Add(
		"SELECT DISTINCT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Goods.OrderDocument AS OrderDocument,
		|	Goods.EventDate AS EventDate
		|INTO RegisteredRecordsDuringRecording
		|FROM
		|	&GoodsTable AS Goods
		|WHERE
		|	Goods.Active");
	
	DimensionsTexts = New Array();
	
	DimensionsTexts.Add(
		"SELECT DISTINCT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Goods.OrderDocument AS OrderDocument,
		|	Goods.EventDate AS EventDate
		|FROM
		|	RegisteredRecordsDuringRecording AS Goods");
	
	RecordersByTypes = RecordersByTypes(Recorders);
	For Each Item In RecordersByTypes Do
		
		TextByTypeOfRecorder =
			"SELECT DISTINCT
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose,
			|	RegisterRecords.OrderDocument AS OrderDocument,
			|	RegisterRecords.EventDate AS EventDate
			|FROM
			|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
			|WHERE
			|	RegisterRecords.Recorder IN(&RecordersOverridable)
			|		AND RegisterRecords.Active";
		TextByTypeOfRecorder = StrReplace(TextByTypeOfRecorder, "RecordersOverridable", Item.ParameterName);
		DimensionsTexts.Add(TextByTypeOfRecorder);
		Query.SetParameter(Item.ParameterName, Item.Recorders);
		
	EndDo;
	
	TextDifferentDimensions = StrConcat(DimensionsTexts, TMCommonUse.QuerySeparatorInJoin(True));
	QueryTexts.Add(TextDifferentDimensions);
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Goods = Query.Execute();
	
	// We block actual measurements that may be affected when recording sets by the Cur registrar and by orders.
	DataLock = New DataLock();
	
	LockItem = DataLock.Add("AccumulationRegister.InventoryAndDemands");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = Goods;
	LockItem.UseFromDataSource("Products", "Products");
	LockItem.UseFromDataSource("Characteristic", "Characteristic");
	LockItem.UseFromDataSource("Warehouse", "Warehouse");
	LockItem.UseFromDataSource("Purpose", "Purpose");
	LockItem.UseFromDataSource("OrderDocument", "OrderDocument");
	LockItem.UseFromDataSource("EventDate", "EventDate");
	
	If Not ThisIsIBUpdate Then
		CountRegisterWithRoutineTask = InventoryAllocation.CountRegisterWithRoutineTask();
		If Not CountRegisterWithRoutineTask Then
			
		Query.Text =
			"SELECT DISTINCT
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Purpose AS Purpose
			|INTO RegisteredRecordsDuringRecording
			|FROM
			|	&GoodsTable AS Goods
			|WHERE
			|	Goods.Active
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Purpose AS Purpose
			|FROM
			|	RegisteredRecordsDuringRecording AS Goods
			|
			|UNION
			|
			|SELECT DISTINCT
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose
			|FROM
			|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
			|WHERE
			|	RegisterRecords.Recorder = &Recorder
			|		AND RegisterRecords.Active
			|;
			|
			|/////////////////////////////////////////
			|SELECT DISTINCT
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Purpose AS Purpose
			|FROM
			|	RegisteredRecordsDuringRecording AS Goods
			|WHERE
			|	Goods.Warehouse <> UNDEFINED
			|		AND Goods.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
			|		AND VALUETYPE(Goods.Warehouse) = TYPE(Catalog.Warehouses)
			|
			|UNION
			|
			|SELECT DISTINCT
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose
			|FROM
			|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
			|WHERE
			|	RegisterRecords.Recorder = &Recorder
			|		AND RegisterRecords.Active
			|		AND RegisterRecords.Warehouse <> UNDEFINED
			|		AND RegisterRecords.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
			|		AND VALUETYPE(RegisterRecords.Warehouse) = TYPE(Catalog.Warehouses)";
			
			QueryResult = Query.ExecuteBatch();
			
			InventoryAllocation.AddLocks(DataLock, Undefined,
				QueryResult[QueryResult.UBound() - 1], QueryResult[QueryResult.UBound()]);
			
		EndIf;
		
		//@skip-check lock-out-of-try
		DataLock.Lock();
		
	EndIf;
	
	// If this is an order, then it was already in the first two sections of the request, other Recorders are not needed as a result.
	RecordersAndOrders.Delete(RecordersAndOrders.Count() - 1);
	Orders = Orders.Unload().UnloadColumn("OrderDocument");
	Result = New Structure("RecordersAndOrders,Orders", RecordersAndOrders, Orders);
	Return Result;

EndFunction

#EndRegion

#Region Private

Procedure RecordOrdersAccordingToCalculations(InstalledLocks, Query)
	
	Recorders = InstalledLocks.RecordersAndOrders.Copy();
	Recorders.GroupBy("Recorder");
	Recorders = Recorders.UnloadColumn("Recorder");
	
	RecordsetGraph = CreateRecordSet();
	RecordsetGraph.DataExchange.Load = True;
	RecordsetGraph.AdditionalProperties.Insert("RegisterAtExchangePlanNodesOnUpdateIB");
	RecordsetGraph.DataExchange.Recipients.AutoFill = False;
	For Each Recorder In Recorders Do
		
		Query.SetParameter("Recorder", Recorder);
		
		Query.Text =
			"SELECT
			|	RegisterRecords.Recorder AS Recorder,
			|	RegisterRecords.Period AS Period,
			|	RegisterRecords.RecordType AS RecordType,
			|	RegisterRecords.Active AS Active,
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose,
			|	RegisterRecords.OrderDocument AS OrderDocument,
			|	RegisterRecords.EventDate AS EventDate,
			|	RegisterRecords.InStock AS InStock,
			|	RegisterRecords.Received_1 AS Received_1,
			|	RegisterRecords.Ordered AS Ordered,
			|	RegisterRecords.ReserveAtWarehouse AS ReserveAtWarehouse,
			|	RegisterRecords.ReserveAsReceived AS ReserveAsReceived,
			|	RegisterRecords.SnoozeReservation AS SnoozeReservation,
			|	RegisterRecords.ToSupply AS ToSupply,
			|	RegisterRecords.NotProvide AS NotProvide,
			|	RegisterRecords.LockedInStock AS LockedInStock,
			|	RegisterRecords.LockedReceipt AS LockedReceipt,
			|	RegisterRecords.ToUnlock AS ToUnlock,
			|	RegisterRecords.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
			|	RegisterRecords.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
			|	RegisterRecords.CloseReceiptSchedule AS CloseReceiptSchedule,
			|	RegisterRecords.ToControlQuality AS ToControlQuality,
			|	RegisterRecords.SubjectToUnlocking AS SubjectToUnlocking,
			|	RegisterRecords.CloseScheduleShipping AS CloseScheduleShipping,
			|	RegisterRecords.OrderToShip AS OrderToShip,
			|	RegisterRecords.EntryType AS EntryType,
			|	RegisterRecords.ReversingEntry AS ReversingEntry
			|FROM
			|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
			|WHERE
			|	RegisterRecords.Recorder = &Recorder
			|		AND (RegisterRecords.EntryType IN(
			|				VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord),
			|				VALUE(Enum.RecordTypesInventoryAndDemands.DeferredReservation))
			|			OR NOT RegisterRecords.OrderDocument IN(&Orders))
			|
			|UNION ALL
			|
			|SELECT
			|	CalculationResults.Recorder AS Recorder,
			|	CalculationResults.Period AS Period,
			|	CalculationResults.RecordType AS RecordType,
			|	CalculationResults.Active AS Active,
			|	CalculationResults.Products AS Products,
			|	CalculationResults.Characteristic AS Characteristic,
			|	CalculationResults.Warehouse AS Warehouse,
			|	CalculationResults.Purpose AS Purpose,
			|	CalculationResults.OrderDocument AS OrderDocument,
			|	CalculationResults.EventDate AS EventDate,
			|	CalculationResults.InStock AS InStock,
			|	CalculationResults.Received_1 AS Received_1,
			|	CalculationResults.Ordered AS Ordered,
			|	CalculationResults.ReserveAtWarehouse AS ReserveAtWarehouse,
			|	CalculationResults.ReserveAsReceived AS ReserveAsReceived,
			|	CalculationResults.SnoozeReservation AS SnoozeReservation,
			|	CalculationResults.ToSupply AS ToSupply,
			|	CalculationResults.NotProvide AS NotProvide,
			|	CalculationResults.LockedInStock AS LockedInStock,
			|	CalculationResults.LockedReceipt AS LockedReceipt,
			|	CalculationResults.ToUnlock AS ToUnlock,
			|	CalculationResults.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
			|	CalculationResults.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
			|	CalculationResults.CloseReceiptSchedule AS CloseReceiptSchedule,
			|	CalculationResults.ToControlQuality AS ToControlQuality,
			|	CalculationResults.SubjectToUnlocking AS SubjectToUnlocking,
			|	CalculationResults.CloseScheduleShipping AS CloseScheduleShipping,
			|	UNDEFINED AS OrderToShip,
			|	CalculationResults.EntryType AS EntryType,
			|	CalculationResults.ReversingEntry AS ReversingEntry
			|FROM
			|	GraphCalculationResults AS CalculationResults
			|WHERE
			|	CalculationResults.Recorder = &Recorder";
			
		Table = Query.Execute().Unload();
		RecordsetGraph.Filter.Recorder.Set(Recorder);
		RecordsetGraph.Load(Table);
		RecordsetGraph.Write();
		
	EndDo
	
EndProcedure

Function RecordersByTypes(Recorders)
	
	TypesOfLoggers = New Map();
	RecordersByTypes = New Array();
	
	For Each Ref In Recorders Do
		
		TypeOfRegistrar = TypeOf(Ref);
		ArrayItems = TypesOfLoggers[TypeOfRegistrar]; 
		If ArrayItems = Undefined Then
			MetadataOfDocument = Ref.Metadata(); // MetadataObject
			ParameterName = "Recorders" + MetadataOfDocument.Name;
			ArrayItems = New Array();
			TypesOfLoggers.Insert(TypeOfRegistrar, ArrayItems);
			RecordersByTypes.Add(New Structure("Recorders,ParameterName", ArrayItems, ParameterName));
		EndIf;
		
		ArrayItems.Add(Ref);
		
	EndDo;
	
	Return RecordersByTypes;
	
EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.InventoryAndDemands.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.41";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("c050f1a4-0885-4ddf-9d5b-0f9575629156");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.InventoryAndDemands.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Comment = NStr("vi = 'Cập nhật bản ghi kết chuyển theo biểu ghi tích lũy ""Vật tư và nhu cầu"" đối với ""Biên bản chênh lệch sau khi tiếp nhận"", khi lập chứng từ mua hàng.
	| Ngoài ra, cập nhật bản ghi kết chuyển của chứng từ ""Điều chỉnh mua hàng"", khi lập chứng từ mua hàng hoặc nội dung công việc.
	| Ngoài ra, cập nhật bản ghi kết chuyển của chứng từ ""Mua hàng và cung cấp dịch vụ"", khi lập chứng từ mua hàng, nội dung công việc.
	| Sửa lỗi bút toán của chứng từ ""Kiểm đếm hàng hóa"" theo các vị trí hàng hóa.';
	|ru = 'Обновляет движения по регистру накопления ""Запасы и потребности"" для документов ""Акт о расхождениях после приемки"", при раздельном оформлении закупок.
	| Также обновляет движения документов ""Корректировка приобретения"", при раздельном оформлении закупок, либо содержащих работы.
	| Также обновляет движения документов ""Приобретение товаров и услуг"", при раздельном оформлении закупок, содержащих работы.
	| Исправляет ошибку движений документов ""Пересчет товаров"" по товарным местам.';
	|en = 'Updates register records in the ""Inventory and demands"" accumulation register for the ""Receipt discrepancy reports"" documents when making separate purchases.
	|Also updates register records of the ""Purchase adjustment"" documents with separate registration of purchases or with works.
	|Also updates register records of the ""Vendor invoice"" documents with separate registration of purchases and works.
	|Corrects the error in ""Inventory count sheet"" document register records by cargo items.'; fa = 'Updates register records in the ""Inventory and demands"" accumulation register for the ""Receipt discrepancy reports"" documents when making separate purchases.
	|Also updates register records of the ""Purchase adjustment"" documents with separate registration of purchases or with works.
	|Also updates register records of the ""Vendor invoice"" documents with separate registration of purchases and works.
	|Corrects the error in ""Inventory count sheet"" document register records by cargo items.';
	|it = 'Updates register records in the ""Inventory and demands"" accumulation register for the ""Receipt discrepancy reports"" documents when making separate purchases.
	|Also updates register records of the ""Purchase adjustment"" documents with separate registration of purchases or with works.
	|Also updates register records of the ""Vendor invoice"" documents with separate registration of purchases and works.
	|Corrects the error in ""Inventory count sheet"" document register records by cargo items.';
	|pl = 'Updates register records in the ""Inventory and demands"" accumulation register for the ""Receipt discrepancy reports"" documents when making separate purchases.
	|Also updates register records of the ""Purchase adjustment"" documents with separate registration of purchases or with works.
	|Also updates register records of the ""Vendor invoice"" documents with separate registration of purchases and works.
	|Corrects the error in ""Inventory count sheet"" document register records by cargo items.';
	|tr = 'Ayrı satın alma işlemlerinde, ""Teslim alma sonrası stok farkları raporu"" belgeleri için ""Stoklar ve talepler"" birikim kaydındaki hareketleri günceller.
	| Ayrıca, ayrı satın alma işlemlerinde veya iş içeren satın alma işlemlerinde ""Satın alma düzeltmesi"" belgelerinin hareketlerini günceller.
	| Ayrıca, ayrı satın alma işlemlerinde, iş içeren satın alma işlemlerinde ""Satın alma faturası "" belgelerinin hareketlerini günceller. 
	| ""Stok sayımı"" belgelerinin ürün yeri hareketlerindeki hatayı düzeltir.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName());
	ItemsToRead.Add(Metadata.Documents.PurchaseAdjustment.FullName());
	ItemsToRead.Add(Metadata.Documents.VendorInvoice.FullName());
	ItemsToRead.Add(Metadata.Documents.InventoryRecount.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.InventoryAndDemands.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.InventoryAndDemands.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	DocumentsList = New Array;
	DocumentsList.Add("Document.DiscrepancyReportFollowingReceipt");
	DocumentsList.Add("Document.PurchaseAdjustment");
	DocumentsList.Add("Document.VendorInvoice");
	DocumentsList.Add("Document.InventoryRecount");
	
	FullRegisterName = Metadata.AccumulationRegisters.InventoryAndDemands.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = StrConcat(DocumentsList, ",");
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	RegisterName = "InventoryAndDemands";
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.GetQueryTexts = True;
	
	QueryTexts = Documents.DiscrepancyReportFollowingReceipt.DocumentDataForPosting(
		Undefined,
		RegisterName,
		AddlParameters);
	
	RecordersCertificatesAfterAcceptance = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullRegisterName,
		"Document.DiscrepancyReportFollowingReceipt",
		Undefined,
		"CloseReceiptSchedule,CloseScheduleShipping",
		"RegisterTable.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)");
	
	QueryTexts = Documents.PurchaseAdjustment.DocumentDataForPosting(
		Undefined,
		RegisterName,
		AddlParameters);
	
	AcquisitionAdjustmentRecorders = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullRegisterName,
		"Document.PurchaseAdjustment",
		Undefined,
		"CloseReceiptSchedule,CloseScheduleShipping",
		"RegisterTable.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)");
	
	QueryTexts = Documents.VendorInvoice.DocumentDataForPosting(
		Undefined,
		RegisterName,
		AddlParameters);
	
	AcquisitionRecorders = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullRegisterName,
		"Document.VendorInvoice",
		Undefined,
		"CloseReceiptSchedule,CloseScheduleShipping",
		"RegisterTable.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)");
	
	QueryTexts = Documents.InventoryRecount.DocumentDataForPosting(
		Undefined,
		RegisterName,
		AddlParameters);
	
	RecordersRecalculationsOfGoods = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullRegisterName,
		"Document.InventoryRecount",
		Undefined,
		"CloseReceiptSchedule,CloseScheduleShipping",
		"RegisterTable.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)");
	
	Query = New Query;
	Query.SetParameter("RecordersCertificatesAfterAcceptance", RecordersCertificatesAfterAcceptance);
	Query.SetParameter("AcquisitionAdjustmentRecorders", AcquisitionAdjustmentRecorders);
	Query.SetParameter("AcquisitionRecorders", AcquisitionRecorders);
	Query.SetParameter("RecordersRecalculationsOfGoods", RecordersRecalculationsOfGoods);
	Query.Text =
		// The transfer of RegisteredRecords to reflect discrepancies in the acquisition adjustment.
		"SELECT
		|	DocumentTable.Ref AS Recorder
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt AS DocumentTable
		|WHERE
		|	DocumentTable.Posted
		|	AND DocumentTable.Ref IN (&RecordersCertificatesAfterAcceptance)
		|	AND DocumentTable.BusinessOperation IN(
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit))
		|
		|UNION ALL
		|
		// The transfer of RegisteredRecords to reflect discrepancies in the acquisition adjustment.
		// Also, the addition of Registered Records for work in a two-way.
		// Deleting Registered Records based on the availability of one-way jobs for the option to reflect Reflect on income/ Write off expenses
		|SELECT
		|	DocumentTable.Ref AS Recorder
		|FROM
		|	Document.PurchaseAdjustment AS DocumentTable
		|WHERE
		|	DocumentTable.Posted
		|	AND DocumentTable.Ref IN (&AcquisitionAdjustmentRecorders)
		|
		|UNION ALL
		|
		// The Registered Records for the works of documents that do not support two-way works (under old Contracts)
		|SELECT
		|	DocumentTable.Ref AS Recorder
		|FROM
		|	Document.VendorInvoice AS DocumentTable
		|WHERE
		|	DocumentTable.Posted
		|	AND DocumentTable.Ref IN (&AcquisitionRecorders)
		|	AND DocumentTable.BusinessOperation IN(
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|
		|UNION ALL
		|
		// Incorrect Registered Records of recalculations of goods by packages of goods items.
		|SELECT
		|	DocumentTable.Ref AS Recorder
		|FROM
		|	Document.InventoryRecount AS DocumentTable
		|WHERE
		|	DocumentTable.Posted
		|	AND DocumentTable.Ref IN (&RecordersRecalculationsOfGoods)";
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure

// An update handler.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	DocumentsList = New Array;
	DocumentsList.Add("Document.DiscrepancyReportFollowingReceipt");
	DocumentsList.Add("Document.PurchaseAdjustment");
	DocumentsList.Add("Document.VendorInvoice");
	DocumentsList.Add("Document.InventoryRecount");
	
	FullRegisterName = Metadata.AccumulationRegisters.InventoryAndDemands.FullName();
	
	AdditionalParameters = InfobaseUpdateTM.AdditionalOptionsForOverwritingRegisteredRecordsFromQueue();
	AdditionalParameters.UpdatedData = Parameters.UpdatedData;
	
	ProcessingCompleted = InfobaseUpdateTM.OverwriteRegisteredRecordsFromQueue(
		DocumentsList,
		FullRegisterName,
		Parameters.Queue,
		AdditionalParameters);
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

Procedure GenerateAndRecordRegisteredRecords(RecordSet, Ref, RecordRegisteredRecords) Export
	
	If RecordRegisteredRecords Then
		
		// Getting primary movements.
		TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(Ref, "InventoryAndDemands");
		DataTable = TablesForRegisteredRecords["Table" + "InventoryAndDemands"];
		RecordSet.Load(DataTable);
		
		InstalledLocks = SetBlockingOrdersAndProducts(RecordSet, Ref, True);
		
		DeferredCollateralIsPossible = False;
		If Constants.OptionOfOrderingDemandsByOrdersForSupply.Get()
					<> Enums.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate
				And Not Constants.ControlBalanceOfGoodsToBeReservedUponReceipt.Get() Then
				
			For Each String In DataTable Do
				If ValueIsFilled(String.EventDate) And String.ReserveAsReceived <> 0 Then
					DeferredCollateralIsPossible = True;
				EndIf;
			EndDo;
			
		EndIf;
		
		// Calculation of deferred reservation.
		If DeferredCollateralIsPossible Then
			
			AddDeferredCollateralRecordsToSet(RecordSet);
			
		EndIf;
		
		InfobaseUpdate.WriteData(RecordSet);
		
		// Calculation of the receipt schedule and the shipment schedule.
		If InstalledLocks.Orders.Count() > 0 Then
			
			Query = New Query();
			Query.TempTablesManager = New TempTablesManager();
			TempTableOfChartClosure(Query, "GraphCalculationResults", InstalledLocks);
			RecordOrdersAccordingToCalculations(InstalledLocks, Query);
			
		EndIf;
		
	Else
		InfobaseUpdate.WriteData(RecordSet);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
