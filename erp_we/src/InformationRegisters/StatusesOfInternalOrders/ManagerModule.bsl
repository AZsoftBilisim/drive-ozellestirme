#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Reflects changes in order States in the register.
//
// Parameters:
//  Orders - Array of DocumentRef - array of reflected orders.
//  Errors - Undefined, Map of KeyAndValue - with structure:
//                          *Key     - DocumentRef -
//                          *Value - String - detailed representation of the error.
//
Procedure ReflectOrderStates(Orders, Errors = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Table.Ref AS OrderDocument
	|FROM
	|	Document.TransferOrder AS Table
	|WHERE
	|	Table.Ref IN (&Orders)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS OrderDocument
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS Table
	|WHERE
	|	Table.Ref IN (&Orders)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS OrderDocument
	|FROM
	|	Document.InventoryConsumptionOrder AS Table
	|WHERE
	|	Table.Ref IN (&Orders)
	|";
	
	Query.SetParameter("Orders", Orders);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	SelectedOrders_1 = Result.Unload().UnloadColumn("OrderDocument");
	
	ReflectOrderState(SelectedOrders_1, Errors);
	
EndProcedure

// Complements the request text of the state calculation engine.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function MatchingRequestsToControlRegisters(Query) Export

	MatchingTasks = New Map();
	MatchingTasks.Insert("RegisteredRecordsGoodsForIssueUpdate", QueryTextGoodsForIssue(Query));
	MatchingTasks.Insert("GoodsToReceiveUpdate", QueryTextGoodsToReceive(Query));
	MatchingTasks.Insert("RegisteredRecordsOrdersToMoveChange", QueryTextTransferOrders(Query));
	MatchingTasks.Insert("RegisteredRecordsBuildOrdersChange", QueryTextAssemblyOrders(Query));
	MatchingTasks.Insert("RegisteredRecordsOfDomesticConsumptionOrdersUpdate", QueryTextInventoryConsumptionOrders(Query));
	If Not InventoryAllocation.CountRegisterWithRoutineTask() Then
		MatchingTasks.Insert("StatusesOfInternalOrdersUpdate",
			QueryTextStatusesOfInternalOrdersUpdate(Query));
	EndIf;
	Return MatchingTasks;
	
EndFunction

// Adds tasks to the State of orders.
// 
// Parameters:
//  Source       - See DocumentsStates.AddTasksToStateOfOrders.Source
//  Orders         - See DocumentsStates.AddTasksToStateOfOrders.Reflected_Documents
//  Action       - See DocumentsStates.AddTasksToStateOfOrders.Action
//  TaskTable - See DeferredJobs.AddTasksToQueue.TaskTable
//
Procedure AddTasksToStateOfOrders(
			Source,
			Orders,
			Action = "",
			TaskTable = Undefined) Export
	
	SetPrivilegedMode(True);
	
	OrderTypes = TypesOfOrdersToReflectStates();
	
	SourceRef = ?(Source = Undefined, Undefined, Source.Ref);
	
	If SourceRef <> Undefined
		And OrderTypes.Find(TypeOf(SourceRef)) <> Undefined
		And Orders.Find(SourceRef) = Undefined Then
			InformationRegisters.JobsToReflectOrderState.AddTasks(
				SourceRef,
				Action,
				TaskTable);
	EndIf;
	
	For Each OrderDocument In Orders Do
		
		If OrderTypes.Find(TypeOf(OrderDocument)) = Undefined Then
			Continue;
		EndIf;
		
		InformationRegisters.JobsToReflectOrderState.AddTasks(OrderDocument, Action, TaskTable);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Internal

Function ParametersForUpdatingOrderStates() Export
	
	Result = New Structure("RecordSelectionRule,RecordComparisonFunction,FunctionForComparingRecordsInTemporaryTable");
	
	Result.RecordSelectionRule =
		"SELECT DISTINCT
		|	InventoryAllocation.ShipmentOrder AS ShipmentOrder
		|INTO TableOverridable
		|FROM
		|	FilterOverridable AS Goods
		|		
		|		LEFT JOIN InformationRegister.InventoryAllocation AS InventoryAllocation
		|		ON InventoryAllocation.Products = Goods.Products
		|		AND InventoryAllocation.Characteristic = Goods.Characteristic
		|		AND InventoryAllocation.Warehouse = Goods.Warehouse
		|		AND InventoryAllocation.Purpose = Goods.Purpose
		|		AND InventoryAllocation.InventoryState IN(
		|			VALUE(Enum.InventoryStates.NotProvided),
		|			VALUE(Enum.InventoryStates.PendingSupplyApproval),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking),
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking))
		|		AND InventoryAllocation.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|			VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked),
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply))
		|		
		|WHERE
		|	NOT InventoryAllocation.Products IS NULL
		|		AND VALUETYPE(InventoryAllocation.ShipmentOrder) IN(
		|			TYPE(Document.ByAssemblyDisassemblyOrder),
		|			TYPE(Document.InventoryConsumptionOrder),
		|			TYPE(Document.TransferOrder))
		|INDEX BY
		|	ShipmentOrder";
		
	Result.FunctionForComparingRecordsInTemporaryTable =
		"SELECT
		|	BeforeWrite.ShipmentOrder AS OrderDocument
		|INTO UpdateOverridable
		|FROM
		|	BeforeWriteOverridable AS BeforeWrite
		|		
		|		LEFT JOIN OnWriteOverridable AS OnWrite
		|		ON OnWrite.ShipmentOrder = BeforeWrite.ShipmentOrder
		|WHERE
		|		OnWrite.ShipmentOrder IS NULL
		|
		|UNION
		|
		|SELECT
		|	OnWrite.ShipmentOrder AS OrderDocument
		|FROM
		|	OnWriteOverridable AS OnWrite
		|		
		|		LEFT JOIN BeforeWriteOverridable AS BeforeWrite
		|		ON BeforeWrite.ShipmentOrder = OnWrite.ShipmentOrder
		|WHERE
		|	BeforeWrite.ShipmentOrder IS NULL";
	
	Result.RecordComparisonFunction = StrReplace(Result.FunctionForComparingRecordsInTemporaryTable,
		"INTO UpdateOverridable", "");
	
Return Result;
	
EndFunction

// Returns the types of orders for which States should be reflected.
//
// Returns:
//  Array of Type - Types of State reflection orders
//
Function TypesOfOrdersToReflectStates() Export
	
	OrderTypes = New Array;
	OrderTypes.Add(Type("DocumentRef.TransferOrder"));
	OrderTypes.Add(Type("DocumentRef.ByAssemblyDisassemblyOrder"));
	OrderTypes.Add(Type("DocumentRef.InventoryConsumptionOrder"));
	
	Return OrderTypes;
	
EndFunction

// Returns an action table to reflect the State of orders.
// Detailed description in the function of document statesadocuments.Initialize the Action table to reflect the status of orders.
// 
// Returns:
//  - Undefined,
//  - See DocumentsStates.InitializeActionTableToReflectStateOfOrders
//
Function ActionsToReflectStateOfOrders() Export
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Private

// The procedure uses the passed order link to calculate and record the order status in the data register.
//
// Parameters:
//  AnArrayOfOrders - Array - An array of documents of the following types: Order for Relocation, order for assembly, order for internal use, within
//                           the framework of which the state is recalculated.
//  Errors - See ReflectOrderStates.Errors.
//
Procedure ReflectOrderState(AnArrayOfOrders, Errors = Undefined)
	
	OrdersByType = TMCommonUse.MatchingArraysByObjectType(AnArrayOfOrders);
	
	For Each Item In OrdersByType Do
		
		OrderType_5 = Item.Key;
		Orders = Item.Value;
		
		If OrderType_5 = "Document.TransferOrder"
				Or OrderType_5 = "Document.ByAssemblyDisassemblyOrder"
				Or OrderType_5 = "Document.InventoryConsumptionOrder" Then
			
			Table = TableOfChangesInOrderStates(OrderType_5, Orders);
			RecordStates(Table, Errors);
		EndIf;
		
	EndDo;
	
EndProcedure

Function TableOfChangesInOrderStates(DocumentType, AnArrayOfOrders)
	
	ManagerOfDocument = Common.ObjectManagerByFullName(DocumentType);
	StructureOfDocumentParameters = ManagerOfDocument.ParametersForCalculatingStates();
	
	TemporaryDocumentTables       = ManagerOfDocument.TemporaryDocumentTablesForCalculatingStates();
	TemporaryTableOrderBalances  = StructureOfDocumentParameters.OrderBalancesModule.TemporaryTableOrderBalances();
	
	QueryTexts = New ValueList();
	QueryTexts.Add(TemporaryDocumentTables.DocumentGoods,          "");
	QueryTexts.Add(TemporaryDocumentTables.DocumentAttributes,       "");
	QueryTexts.Add(TemporaryTableSecuringOrder(),                "");
	QueryTexts.Add(TemporaryTableOrderBalances,                     "");
	QueryTexts.Add(TemporaryTableOfBalancesForShipment(),                 "");
	QueryTexts.Add(TemporaryTableBalancesToReceipt(),              "");
	QueryTexts.Add(TemporaryDiscrepancyTableInvoiceOrder(),        "");
	QueryTexts.Add(TemporaryTableTurnoverForShipmentFromOrderWarehouses(), "");
	QueryTexts.Add(TemporaryTablePartiallyInStock(),                 "");
	QueryTexts.Add(StatusCalculationQueryText(),                     "Table");
	
	Query = New Query();
	
	Query.SetParameter("MonitorOrderClosing", StructureOfDocumentParameters.MonitorOrderClosing);
	Query.SetParameter("StatusInProcessOfAdmission", StructureOfDocumentParameters.StatusInProcessOfAdmission);
	Query.SetParameter("ShippingStatus", StructureOfDocumentParameters.ShippingStatus);
	Query.SetParameter("ReadyForShipmentStatus", StructureOfDocumentParameters.ReadyForShipmentStatus);
	
	Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("ManagerCreatesOrders",
		Constants.GoodsIssueNoteGenerationMode.Get() = Enums.GoodsIssueNoteGenerationModes.ByManager);
	
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts, , True);

	Return Tables.Table;

EndFunction

Function StatusCalculationQueryText()
	
	QueryText =
		"SELECT
		|	Table.Ref                        AS OrderDocument,
		|	Table.State                     AS State,
		|	Table.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice
		|FROM(
		|SELECT
		|	TTDocumentDetails.Ref AS Ref,
		|
		|	CASE WHEN NOT TTDocumentDetails.Posted THEN
		|
		|			VALUE(Enum.StatusesOfInternalOrders.EmptyRef)
		|
		|		WHEN TTDocumentDetails.StatusUnderApproval THEN
		|
		|			VALUE(Enum.StatusesOfInternalOrders.PendingApproval)
		|
		|		WHEN TTOrderAssurance.Ref IS NULL THEN
		|
		|			VALUE(Enum.StatusesOfInternalOrders.EmptyRef)
		|
		|		WHEN TTOrderAssurance.ThereIsToProvision THEN
		|
		|			VALUE(Enum.StatusesOfInternalOrders.ReadyForSupply)
		|
		|		WHEN NOT TTPartiallyInStock.Ref IS NULL THEN
		|
		|			VALUE(Enum.StatusesOfInternalOrders.PendingSupply)
		|
		|		WHEN NOT TTDocumentDetails.ShippingStatus_ OR NOT TTOrderAssurance.ShipEverything THEN
		|
		|			&ReadyForShipmentStatus
		|
		|		WHEN &ManagerCreatesOrders AND TTTurnoversForShipment.Expense = 0 THEN
		|
		|			VALUE(Enum.StatusesOfInternalOrders.ReadyToShip)
		|
		|		WHEN NOT TTOrderBalances.ReferenceOrder IS NULL THEN
		|
		|			&ShippingStatus
		|
		|		WHEN NOT TTBalanceForShipment.ReferenceOrder IS NULL THEN
		|
		|			&ShippingStatus
		|
		|		WHEN NOT TTBalancesToBeReceived.ReferenceOrder IS NULL THEN
		|
		|			&StatusInProcessOfAdmission
		|
		|		WHEN NOT TTDocumentDetails.TheClosedStatus AND &MonitorOrderClosing THEN
		|
		|			VALUE(Enum.StatusesOfInternalOrders.ReadyForClosure)
		|
		|		ELSE
		|
		|			VALUE(Enum.StatusesOfInternalOrders.Closed)
		|
		|	END AS State,
		|	CASE WHEN TTDivergenceInvoiceOrder.ReferenceOrder IS NULL THEN
		|				FALSE
		|			ELSE
		|				TRUE
		|		END AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice
		|
		|FROM
		|	TTDocumentDetails AS TTDocumentDetails
		|
		|		LEFT JOIN TTOrderAssurance AS TTOrderAssurance
		|		ON TTOrderAssurance.Ref = TTDocumentDetails.Ref
		|
		|		LEFT JOIN TTPartiallyInStock AS TTPartiallyInStock
		|		ON TTPartiallyInStock.Ref = TTDocumentDetails.Ref
		|
		|		LEFT JOIN TTTurnoversForShipment AS TTTurnoversForShipment
		|		ON TTTurnoversForShipment.ReferenceOrder = TTDocumentDetails.Ref
		|
		|		LEFT JOIN TTOrderBalances AS TTOrderBalances
		|		ON TTOrderBalances.ReferenceOrder = TTDocumentDetails.Ref
		|
		|		LEFT JOIN TTBalanceForShipment AS TTBalanceForShipment
		|		ON TTBalanceForShipment.ReferenceOrder = TTDocumentDetails.Ref
		|
		|		LEFT JOIN TTBalancesToBeReceived AS TTBalancesToBeReceived
		|		ON TTBalancesToBeReceived.ReferenceOrder = TTDocumentDetails.Ref
		|
		|		LEFT JOIN TTDivergenceInvoiceOrder AS TTDivergenceInvoiceOrder
		|		ON TTDivergenceInvoiceOrder.ReferenceOrder = TTDocumentDetails.Ref) AS Table";
	
	Return QueryText;
	
EndFunction

Function TemporaryTableSecuringOrder()
	
	QueryText =
		"SELECT
		|	Table.Ref AS Ref,
		|	MAX(Table.ControlledLotReference) AS ControlledLotReference,
		|	MAX(Table.SupplyOption = VALUE(Enum.SupplyOptions.NotRequired)
		|		AND Table.ThisIsAProduct) AS ThereIsToProvision,
		|	MAX(Table.SupplyOption IN(
		|			VALUE(Enum.SupplyOptions.ToSupply),
		|			VALUE(Enum.SupplyOptions.ReserveAsReceived),
		|			VALUE(Enum.SupplyOptions.ReserveAsReceived))) AS ThereAreThoseRequiringDistributionOfStocks,
		|	MIN(Table.SupplyOption = VALUE(Enum.SupplyOptions.Ship)) AS ShipEverything
		|INTO TTOrderAssurance
		|	FROM
		|		TTDocumentProducts_ AS Table
		|GROUP BY
		|	Table.Ref";
	
	Return QueryText
	
EndFunction

Function TemporaryTableOfBalancesForShipment()
	
	QueryText =
		"SELECT
		|	Table.DocumentShipments AS ReferenceOrder,
		|	Table.ToShipBalance AS Count
		|INTO TTBalanceForShipment
		|FROM
		|	AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments IN (&AnArrayOfOrders)) AS Table";
		
	Return QueryText;
	
EndFunction

Function TemporaryTableBalancesToReceipt()
	
	QueryText =
		"SELECT
		|	Table.DocumentInflow AS ReferenceOrder
		|INTO TTBalancesToBeReceived
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow IN (&AnArrayOfOrders)) AS Table";
		
	Return QueryText;
	
EndFunction

Function TemporaryDiscrepancyTableInvoiceOrder()
	
	QueryText =
		"SELECT DISTINCT
		|	Set.ReferenceOrder AS ReferenceOrder
		|INTO TTDivergenceInvoiceOrder
		|FROM(
		|	SELECT
		|		Table.DocumentShipments AS ReferenceOrder,
		|
		|		Table.Products     AS Products,
		|		Table.Characteristic   AS Characteristic,
		|		Table.Warehouse            AS Warehouse,
		|		Table.Purpose       AS Purpose,
		|		Table.Series            AS Series
		|
		|FROM
		|	AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(,,,, DocumentShipments IN (&AnArrayOfOrders)) AS Table
		|WHERE
		|	Table.ToRegisterExpense <> Table.ToShipExpense + Table.AssembledReceipt
		|
		|UNION ALL
		|
		|	SELECT
		|		Table.DocumentInflow AS ReferenceOrder,
		|
		|		Table.Products     AS Products,
		|		Table.Characteristic   AS Characteristic,
		|		Table.Warehouse            AS Warehouse,
		|		Table.Purpose       AS Purpose,
		|		Table.Series            AS Series
		|
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(,DocumentInflow IN (&AnArrayOfOrders)) AS Table
		|WHERE
		|	Table.ToRegisterGoodsReceiptsBalance <> 0
		|
		|) AS Set";
		
	Return QueryText;
	
EndFunction

Function TemporaryTableTurnoverForShipmentFromOrderWarehouses()
	
	QueryText =
		"SELECT
		|	Table.DocumentShipments  AS ReferenceOrder,
		|	Table.ToShipReceipt   AS Receipt,
		|	Table.ToShipExpense + Table.ForAssemblyReceipt + Table.AssemblyInProgressReceipt + Table.AssembledReceipt AS Expense //all orders
		|INTO TTTurnoversForShipment
		|FROM
		|	AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(,,,,
		|		DocumentShipments IN (&AnArrayOfOrders)
		|		AND Warehouse IN(
		|			SELECT
		|				CatWarehouses.Ref AS Warehouse
		|			FROM
		|				Catalog.Warehouses AS CatWarehouses
		|			WHERE
		|				CatWarehouses.UseWarehouseManagemantSystemForGoodsIssue
		|				AND CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate)) AS Table";
	
	Return QueryText
	
EndFunction

Function TemporaryTablePartiallyInStock()
	
	QueryText =
		"SELECT
		|	Orders.Ref AS Ref
		|INTO TTPartiallyInStock
		|FROM
		|	TTOrderAssurance AS Orders
		|WHERE
		|	Orders.ThereAreThoseRequiringDistributionOfStocks
		|	AND Orders.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|	AND(
		|		TRUE IN(
		|			SELECT TOP 1
		|				TRUE AS ThereAreRecords
		|			FROM
		|				InformationRegister.InventoryAllocation AS InformationRecords
		|			WHERE
		|				InformationRecords.ShipmentOrder = Orders.Ref
		|					AND InformationRecords.InventoryState IN(
		|						VALUE(Enum.InventoryStates.NotProvided),
		|						VALUE(Enum.InventoryStates.PendingSupplyApproval),
		|						VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|						VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|						VALUE(Enum.InventoryStates.AvailablePendingUnlocking))
		|					AND InformationRecords.DemandCharacteristic IN(
		|						VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|						VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|						VALUE(Enum.DemandCharacteristics.ToSupply)))
		// the document was not held
		|		OR NOT TRUE IN(
		|			SELECT TOP 1
		|				TRUE AS ThereAreRecords
		|			FROM
		|				InformationRegister.InventoryAllocation AS InformationRecords
		|			WHERE
		|				InformationRecords.ShipmentOrder = Orders.Ref))
		|
		|UNION ALL
		|
		|SELECT
		|	Orders.Ref AS Ref
		|FROM
		|	TTOrderAssurance AS Orders
		|WHERE
		|	Orders.ThereAreThoseRequiringDistributionOfStocks
		|	AND Orders.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)
		|	AND TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS ThereAreRecords
		|		FROM
		|			InformationRegister.InventoryAllocation AS InformationRecords
		|		WHERE
		|			InformationRecords.ShipmentOrder = Orders.ControlledLotReference
		|				AND InformationRecords.InventoryState IN(
		|					VALUE(Enum.InventoryStates.NotProvided),
		|					VALUE(Enum.InventoryStates.PendingSupplyApproval),
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|					VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking))
		|				AND InformationRecords.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked))";
	
	Return QueryText
	
EndFunction

Procedure RecordStates(Table, Errors = Undefined)
	
	For Each TableRow In Table Do
	
		Set = InformationRegisters.StatusesOfInternalOrders.CreateRecordSet();
		Set.Filter.OrderDocument.Set(TableRow.OrderDocument);
		
		If Not TableRow.State.IsEmpty() Then
			SetRow = Set.Add();
			FillPropertyValues(SetRow, TableRow);
		EndIf;
		
		Try
			Set.Write(True);
		Except
			
			OrderDocument = TableRow.OrderDocument;
			
			ErrorText = StrTemplate(NStr("vi = 'Không thể phản ánh trạng thái đơn hàng: %1 theo nguyên nhân: %2';
										|ru = 'Не удалось отразить состояние заказа: %1 по причине: %2';
										|en = 'Cannot record the order state: %1. Reason: %2'; fa = 'Cannot record the order state: %1. Reason: %2';
										|it = 'Не удалось отразить состояние заказа: %1 по причине: %2';
										|pl = 'Cannot record the order state: %1. Reason: %2';
										|tr = '%2 nedeniyle tedarikçi siparişinin durumu yansıtılamadı: %1'"),
									OrderDocument,
									ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				EventLogEvent(),
				EventLogLevel.Warning,
				OrderDocument.Metadata(),
				OrderDocument,
				ErrorText);
			
			If Errors <> Undefined Then
				Errors.Insert(TableRow.OrderDocument, ErrorText);
			EndIf;
			
		EndTry;
		
	EndDo;
	
EndProcedure

Function EventLogEvent()
	
	Return NStr("vi = 'Lỗi phản ánh trạng thái đơn hàng theo trình tự';
				|ru = 'Ошибка отражения состояния заказов в очереди';
				|en = 'Error recording order states in the queue'; fa = 'Error recording order states in the queue';
				|it = 'Errore di registrazione dello stato degli ordini in coda';
				|pl = 'Błąd odzwierciedlenie statusu zamówień w kolejce';
				|tr = 'Kuyruktaki siparişlerin durumlarının yansıtılma hatası'", Common.DefaultLanguageCode());
	
EndFunction

#Region ServiceMethodsForGeneratingStates

#Region RequestTextsByControlRegisters

Function QueryTextGoodsForIssue(Query)
	
	QueryText =
	"SELECT
	|	Table.DocumentShipments AS ReflectedDocument
	|FROM
	|	RegisteredRecordsGoodsForIssueUpdate AS Table
	|WHERE
	|	VALUETYPE(Table.DocumentShipments) IN (TYPE(Document.TransferOrder),
	|		TYPE(Document.ByAssemblyDisassemblyOrder),
	|		TYPE(Document.InventoryConsumptionOrder))
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextGoodsToReceive(Query)
	
	QueryText =
	"SELECT
	|	Table.DocumentInflow AS ReflectedDocument
	|FROM
	|	GoodsToReceiveUpdate AS Table
	|WHERE
	|	VALUETYPE(Table.DocumentInflow) IN (TYPE(Document.TransferOrder),
	|		TYPE(Document.ByAssemblyDisassemblyOrder),
	|		TYPE(Document.InventoryConsumptionOrder))
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextTransferOrders(Query)
	
	QueryText =
	"SELECT
	|	Table.TransferOrder AS ReflectedDocument
	|FROM
	|	RegisteredRecordsOrdersToMoveChange AS Table
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextAssemblyOrders(Query)
	
	QueryText =
	"SELECT
	|	Table.ByAssemblyDisassemblyOrder AS ReflectedDocument
	|FROM
	|	RegisteredRecordsBuildOrdersChange AS Table
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextInventoryConsumptionOrders(Query)
	
	QueryText =
	"SELECT
	|	Table.InventoryConsumptionOrder AS ReflectedDocument
	|FROM
	|	RegisteredRecordsOfDomesticConsumptionOrdersUpdate AS Table
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextStatusesOfInternalOrdersUpdate(Query)
	
	QueryText =
	"SELECT
	|	Table.OrderDocument AS ReflectedDocument
	|FROM
	|	StatusesOfInternalOrdersUpdate AS Table
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndIf
