////////////////////////////////////////////////////////////////////////////////
// The module "Distribution of stocks" contains procedures and functions
// for reading and writing to the register of information "Distribution of stocks".
//
////////////////////////////////////////////////////////////////////////////////

#Region Internal

Procedure ActualizationOfNeedsOnBorderOfProvisionRegulatoryTask() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.ActualizationDemandsAlongSupplyBorder);
		
	ActualizationOfNeedsAlongBorderOfProvisionBackgroundTask(Undefined, Undefined);
	
EndProcedure

Procedure LaunchBackgroundTaskToUpdateNeedsAlongProvisionBoundary() Export
	
	If Not GetFunctionalOption("UseOrdersAtLeastOneType") Then
		Return;
	EndIf;
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters();
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật nhu cầu theo biên đảm bảo';
														|ru = 'Актуализация потребностей по границе обеспечения';
														|en = 'Update demand based on the supply boundary'; fa = 'به‌روزرسانی نیاز بر اساس مرز تأمین';
														|it = 'Aggiornamento dei fabbisogni al limite della fornitura';
														|pl = 'Aktualizacja zapotrzebowania wg granicy zaopatrzenia';
														|tr = 'Gereksinimlerin teminat sınırına göre gerçekleştirilmesi'");
	
	TimeConsumingOperations.ExecuteInBackground("InventoryAllocation.ActualizationOfNeedsAlongBorderOfProvisionBackgroundTask",
		New Structure, ExecutionParameters);
	
EndProcedure

Procedure ActualizationOfNeedsAlongBorderOfProvisionBackgroundTask(ProcedureParameters, ResultAddress) Export
	
	SetPrivilegedMode(True);
	
	Texts = New Array();
	
	Text =
		"SELECT
		|	IBData.Products AS Products,
		|	IBData.Characteristic AS Characteristic,
		|	IBData.Warehouse AS Warehouse,
		|	IBData.Purpose AS Purpose,
		|	IBData.OrderDocument AS OrderDocument,
		|	IBData.EventDate AS EventDate,
		|	IBData.ReserveAsReceivedBalance AS ReserveAsReceived,
		|	IBData.SnoozeReservationBalance AS SnoozeReservation,
		|	NOT OrderingByDocumentDate.Value IS NULL
		|		OR NOT ReserveControlAsNeeded.Value IS NULL AS DeferredCollateralIsProhibited
		|INTO DataFromOrders
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(, EventDate > DATETIME(1,1,1)) AS IBData
		|		
		|		LEFT JOIN Constant.OptionOfOrderingDemandsByOrdersForSupply AS OrderingByDocumentDate
		|		ON OrderingByDocumentDate.Value = VALUE(Enum.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate)
		|		
		|		LEFT JOIN Constant.ControlBalanceOfGoodsToBeReservedUponReceipt AS ReserveControlAsNeeded
		|		ON ReserveControlAsNeeded.Value
		|WHERE
		|	IBData.ReserveAsReceivedBalance <> 0
		|		AND OrderingByDocumentDate.Value IS NULL
		|		AND ReserveControlAsNeeded.Value IS NULL // Deferred collateral is acceptable
		|		OR IBData.SnoozeReservationBalance <> 0
		|INDEX BY
		|	DeferredCollateralIsProhibited
		|;
		|
		|/////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse
		|INTO VariousGoods
		|FROM
		|	DataFromOrders AS Goods
		|WHERE
		|	NOT Goods.DeferredCollateralIsProhibited
		|INDEX BY
		|	Products, Characteristic, Warehouse";
	
	Texts.Add(Text);
	
	Text = ProvisionInDocumentsServer.TempTableBoundariesOfSupplyPeriod(
		"VariousGoods",
		"&CurrentDayStart");
	Texts.Add(Text);
	
	Text =
		"SELECT DISTINCT
		|	RegisterRecords.Recorder AS Recorder
		|FROM
		|	DataFromOrders AS DataFromOrders
		|		LEFT JOIN LimitsOfSecurityPeriod AS PeriodBoundaries
		|		ON PeriodBoundaries.Products = DataFromOrders.Products
		|		 AND PeriodBoundaries.Characteristic = DataFromOrders.Characteristic
		|		 AND PeriodBoundaries.Warehouse = DataFromOrders.Warehouse
		|		LEFT JOIN AccumulationRegister.InventoryAndDemands AS RegisterRecords
		|		ON RegisterRecords.OrderDocument = DataFromOrders.OrderDocument
		|WHERE
		|	DataFromOrders.SnoozeReservation <> 0
		|			AND (PeriodBoundaries.PeriodBoundary IS NULL OR PeriodBoundaries.PeriodBoundary >= DataFromOrders.EventDate)
		|		OR DataFromOrders.ReserveAsReceived <> 0
		|			AND PeriodBoundaries.PeriodBoundary < DataFromOrders.EventDate";
	
	Texts.Add(Text);
	
	Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Query = New Query(Text);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	
	Selection = Query.Execute().Select();
	
	Set = AccumulationRegisters.InventoryAndDemands.CreateRecordSet();
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			MetadataOfDocument = Selection.Recorder.Metadata(); // MetadataObjectDocument -
			DataLock = New DataLock();
			LockItem = DataLock.Add(MetadataOfDocument.FullName());
			LockItem.SetValue("Ref", Selection.Recorder);
			LockItem.Mode = DataLockMode.Shared;
			DataLock.Lock();
			
			RecordRegisteredRecords = Common.ObjectAttributeValue(Selection.Recorder, "Posted");
			If TypeOf(RecordRegisteredRecords) <> Type("Boolean") Then
				RecordRegisteredRecords = False;
			EndIf;
			If RecordRegisteredRecords Then
				RecordSet = AccumulationRegisters.InventoryAndDemands.CreateRecordSet();
				RecordSet.Filter.Recorder.Set(Selection.Recorder);
				Set.Filter.Recorder.Value = Selection.Recorder;
				Set.Read();
				TotalRows = Set.Count();
				For Counter = 1 To TotalRows Do
					SetRow = Set[TotalRows - Counter];
					If SetRow.EntryType <> Enums.RecordTypesInventoryAndDemands.PrimaryRegisterRecord Then
						Set.Delete(SetRow);
					EndIf;
				EndDo;
				TempTablesManager = New TempTablesManager;
				Set.AdditionalProperties.Insert("CalculateChanges_", True);
				Set.AdditionalProperties.Insert("DocumentProperties", New Structure("IsNew", False));
				Set.AdditionalProperties.Insert("TempTablesManager", TempTablesManager);
				Set.AdditionalProperties.Insert("ControlTables", New Structure);
				Set.AdditionalProperties.Insert("UpdatingDeferredCollateral");
				Set.Write();
				DocumentEmulation = DocumentsPosting.DocumentEmulation(Undefined, Undefined);
				StockAllocationRecords.ReflectInventoryAllocationTasks(DocumentEmulation, TempTablesManager);
			EndIf;
		CommitTransaction();
		Except
		
			RollbackTransaction();
			MessageText = NStr("vi = 'Nhiệm vụ thường kỳ ""Cập nhật nhu cầu theo biên đảm bảo"" đã kết thúc không thành công do lỗi: %Cause%';
								|ru = 'Регламентное задание ""Актуализация потребностей по границе обеспечения"" завершилось неудачно по причине: %Cause%';
								|en = 'The ""Update demand based on the supply boundary"" scheduled job failed. Reason: %Cause%'; fa = 'The ""Update demand based on the supply boundary"" scheduled job failed. Reason: %Cause%';
								|it = 'Task pianificato ""Aggiornamento di fabbisogni al limite della fornitura"" non è riuscito a causa di: %Cause%';
								|pl = 'Zadanie reglamentowane ""Aktualizacja zapotrzebowania według granicy zaopatrzenia"" zakończyło się nieudanie z powodu: %Cause%';
								|tr = '""Gereksinimlerin teminat sınırına göre gerçekleştirilmesi"" zamanlanmış görev şu nedenden dolayı başarısız oldu: %Cause%'");
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			LogEvent = NStr("vi = 'Phân bổ vật tư';
							|ru = 'Распределение запасов';
							|en = 'Inventory allocation'; fa = 'تسهیم موجودی';
							|it = 'Distribuzione delle scorte';
							|pl = 'Przydzielenie zapasów';
							|tr = 'Stok dağıtımı'", Common.DefaultLanguageCode());
			WriteLogEvent(LogEvent,
			                         EventLogLevel.Error,
			                         Metadata.ScheduledJobs.ActualizationDemandsAlongSupplyBorder,
			                         ,
			                         MessageText);
			
		EndTry;
	EndDo;
	
EndProcedure

// Performs distribution in the background
//
// Parameters:
//  Jobs - ValueTable - the columns correspond to the measurements, resources and Attributes of the register of information
//                              "Assignment of inventory allocation", there are also service columns:
//             * Products         - CatalogRef.Products -
//             * Characteristic       - CatalogRef.ItemsCharacteristics -
//             * Warehouse                - CatalogRef.BusinessStructure, CatalogRef.Warehouses  -
//             * Purpose           - CatalogRef.Assignments   -
//             * RecordSeparator    - UUID -
//             * ShipmentOrder      - DefinedType.ExpectedShipment -
//             * RecordID  - UUID - 
//             * ToReserveRemoval       - Number - 
//             * RecordDate           - Date - 
//             * JobID - UUID - Service_
//             * TaskDate_          - Date                    - Service_
//  IdsOfUnprocessedRecords - Map of UUID - The key is the identifier 
//                                                                                   of the failed (giving an error during
//                                                                                   execution) entries
//                                                                                   of the Job queue information register
//                                                                                   (measurement
//                                                                                   of the record identifier of the Job queue information register),
//                                                                                  the value is the Presentation of the error.
//  AdditionalProperties - Undefined, Structure - additional task completion properties.
//
Procedure PerformDistributionInBackground(
			Jobs,
			IdsOfUnprocessedRecords,
			AdditionalProperties = Undefined) Export
	
	SetPrivilegedMode(True);
	If BlockInventoryAllocation() Then
		Return;
	EndIf;
	
	QueryTexts = New Array;
	
	QueryText =
		"SELECT
		|	Jobs.Products AS Products,
		|	Jobs.Characteristic AS Characteristic,
		|	Jobs.Warehouse AS Warehouse,
		|	Jobs.Purpose AS Purpose,
		|	Jobs.ShipmentOrder AS ShipmentOrder,
		|	Jobs.OrderStructureCalculationQueue AS OrderStructureCalculationQueue,
		|	Jobs.RecordID AS RecordID,
		|	Jobs.ToReserveRemoval AS ToReserveRemoval,
		|	Jobs.ToReserveRemovalFromUnlocked AS ToReserveRemovalFromUnlocked
		|INTO JobsForAllocatingInventory
		|FROM
		|	&Jobs AS Jobs
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ShipmentOrder
		|;
		|
		|////////////////////////////////////////
		|SELECT DISTINCT
		|	Jobs.Products   AS Products,
		|	Jobs.Characteristic AS Characteristic,
		|	Jobs.Warehouse          AS Warehouse,
		|	Jobs.Purpose     AS Purpose
		|INTO InventoryDistributionProducts
		|FROM
		|	JobsForAllocatingInventory AS Jobs
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////
		|SELECT
		|	Jobs.Products AS Products,
		|	Jobs.Characteristic AS Characteristic,
		|	Jobs.Warehouse AS Warehouse,
		|	Jobs.Purpose AS Purpose,
		|	Jobs.ShipmentOrder AS ShipmentOrder,
		|	SUM(Jobs.ToReserveRemoval + Jobs.ToReserveRemovalFromUnlocked) AS Shipment
		|INTO ChangingBalanceOfGoodsToControlBalance
		|FROM
		|	JobsForAllocatingInventory AS Jobs
		|WHERE
		|	Jobs.ToReserveRemoval > 0 OR Jobs.ToReserveRemovalFromUnlocked > 0
		|GROUP BY
		|	Jobs.Products,
		|	Jobs.Characteristic,
		|	Jobs.Warehouse,
		|	Jobs.Purpose,
		|	Jobs.ShipmentOrder
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ShipmentOrder";
		
	QueryTexts.Add(QueryText);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
	Query.SetParameter("Jobs", Jobs);
	
	Query.Execute();
	
	Filter = New Structure();
	Filter.Insert("Products");
	Filter.Insert("Characteristic");
	Filter.Insert("Warehouse");
	Filter.Insert("Purpose");
	WholeSetIsRecorded = False;
	DynamicStructureOfProductionOrders =
		GetFunctionalOption("DynamicStructureOfProductionOrders");
	BeginTransaction();
	
	Try
		
		If Not InfobaseUpdate.ObjectProcessed("InformationRegister.InventoryAllocation").Processed
				Or Not InfobaseUpdate.ObjectProcessed("InformationRegister.AvailableStockBalances").Processed Then
			
			Query.Text =
				"SELECT
				|	Table.Products AS Products,
				|	Table.Characteristic AS Characteristic,
				|	Table.Warehouse AS Warehouse,
				|	Table.Purpose AS Purpose
				|FROM
				|	InventoryDistributionProducts AS Table
				|;
				|SELECT
				|	Table.Products AS Products,
				|	Table.Characteristic AS Characteristic,
				|	Table.Warehouse AS Warehouse,
				|	Table.Purpose AS Purpose
				|FROM
				|	InventoryDistributionProducts AS Table
				|WHERE
				|	Table.Warehouse <> UNDEFINED
				|	AND Table.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
				|	AND VALUETYPE(Table.Warehouse) = TYPE(Catalog.Warehouses)";
			LockTables = Query.Execute();
			Block = New DataLock();
			AddLocks(Block, Undefined, LockTables[0], LockTables[1]);
			Block.Lock();
			
		EndIf;
		If DynamicStructureOfProductionOrders Then
			
			Query.Text =
			"SELECT
			|	InventoryAllocation.Products AS Products,
			|	InventoryAllocation.Characteristic AS Characteristic,
			|	InventoryAllocation.Warehouse AS Warehouse,
			|	InventoryAllocation.Purpose AS Purpose,
			|	InventoryAllocation.ReceiptOrder AS ReceiptOrder,
			|	InventoryAllocation.AvailabilityDate AS AvailabilityDate,
			|	InventoryAllocation.Count AS Surplus
			|INTO InventoryAllocationBeforeWrite
			|FROM
			|	InformationRegister.InventoryAllocation AS InventoryAllocation
			|WHERE
			|	TRUE IN
			|		(SELECT TOP 1
			|			TRUE
			|		FROM
			|			JobsForAllocatingInventory AS JobsForAllocatingInventory
			|		WHERE
			|			JobsForAllocatingInventory.Products = InventoryAllocation.Products
			|			AND JobsForAllocatingInventory.Characteristic = InventoryAllocation.Characteristic
			|			AND JobsForAllocatingInventory.Warehouse = InventoryAllocation.Warehouse
			|			AND JobsForAllocatingInventory.Purpose = InventoryAllocation.Purpose)
			|	AND InventoryAllocation.InventoryState IN (
			|			VALUE(Enum.InventoryStates.InStock),
			|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
			|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
			|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
			|			VALUE(Enum.InventoryStates.PendingSupplyApproval))";
			
			Query.Execute();
			
		EndIf;
		Result = DistributionOfInventoryByGoods(Query, "InventoryDistributionProducts", True,
			"InventoryAllocation,AvailableStockBalances");
		RecordInventoryDistributionResult(Result);
		WholeSetIsRecorded = True;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = "";
		ReportUnsuccessfulProductItemProcessing(ErrorInfo(), ErrorText);
		
		For Each RowOfTaskTable In Jobs Do
			IdsOfUnprocessedRecords.Insert(RowOfTaskTable.RecordID, ErrorText);
		EndDo;
		
		WholeSetIsRecorded = False;
		
	EndTry;
	
	If WholeSetIsRecorded Then
		
		QueryTexts.Clear();
		If DynamicStructureOfProductionOrders Then
			
			QueryTextOrderStructureCalculationTasksInventoryAllocation =
			"SELECT DISTINCT
			|	ChangesTable.Products AS Products,
			|	ChangesTable.Characteristic AS Characteristic,
			|	ChangesTable.Warehouse AS Warehouse,
			|	ChangesTable.Purpose AS Purpose
			|INTO InventoryAllocationTableOfChanges
			|FROM
			|	(SELECT
			|		InventoryAllocationBeforeWrite.Products AS Products,
			|		InventoryAllocationBeforeWrite.Characteristic AS Characteristic,
			|		InventoryAllocationBeforeWrite.Warehouse AS Warehouse,
			|		InventoryAllocationBeforeWrite.Purpose AS Purpose,
			|		InventoryAllocationBeforeWrite.ReceiptOrder AS ReceiptOrder,
			|		InventoryAllocationBeforeWrite.AvailabilityDate AS AvailabilityDate,
			|		InventoryAllocationBeforeWrite.Surplus AS Surplus
			|	FROM
			|		InventoryAllocationBeforeWrite AS InventoryAllocationBeforeWrite
			|
			|	UNION ALL
			|
			|	SELECT
			|		InventoryAllocation.Products AS Products,
			|		InventoryAllocation.Characteristic AS Characteristic,
			|		InventoryAllocation.Warehouse AS Warehouse,
			|		InventoryAllocation.Purpose AS Purpose,
			|		InventoryAllocation.ReceiptOrder AS ReceiptOrder,
			|		InventoryAllocation.AvailabilityDate AS AvailabilityDate,
			|		-InventoryAllocation.Count AS Surplus
			|	FROM
			|		InformationRegister.InventoryAllocation AS InventoryAllocation
			|	WHERE
			|		TRUE IN
			|			(SELECT TOP 1
			|				TRUE
			|			FROM
			|				JobsForAllocatingInventory AS JobsForAllocatingInventory
			|			WHERE
			|				JobsForAllocatingInventory.Products = InventoryAllocation.Products
			|				AND JobsForAllocatingInventory.Characteristic = InventoryAllocation.Characteristic
			|				AND JobsForAllocatingInventory.Warehouse = InventoryAllocation.Warehouse
			|				AND JobsForAllocatingInventory.Purpose = InventoryAllocation.Purpose)
			|		AND InventoryAllocation.InventoryState IN (
			|			VALUE(Enum.InventoryStates.InStock),
			|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
			|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
			|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
			|			VALUE(Enum.InventoryStates.PendingSupplyApproval))) AS ChangesTable
			|	
			|	GROUP BY
			|		ChangesTable.Products,
			|		ChangesTable.Characteristic,
			|		ChangesTable.Warehouse,
			|		ChangesTable.Purpose,
			|		ChangesTable.ReceiptOrder,
			|		ChangesTable.AvailabilityDate
			|
			|	HAVING
			|		SUM(ChangesTable.Surplus) <> 0
			|
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose
			|;
			|SELECT DISTINCT
			|	TaskTable.Products   AS Products,
			|	TaskTable.Characteristic AS Characteristic,
			|	TaskTable.Warehouse          AS Warehouse,
			|	TaskTable.Purpose     AS Purpose,
			|	TaskTable.OrderStructureCalculationQueue AS Queue
			|FROM
			|	JobsForAllocatingInventory AS TaskTable
			|WHERE
			|	TRUE IN
			|		(SELECT TOP 1
			|			TRUE
			|		FROM
			|			InventoryAllocationTableOfChanges AS ChangesTable
			|		WHERE
			|			ChangesTable.Products     = TaskTable.Products
			|			AND ChangesTable.Characteristic = TaskTable.Characteristic
			|			AND ChangesTable.Warehouse          = TaskTable.Warehouse
			|			AND ChangesTable.Purpose     = TaskTable.Purpose)
			|";
			
			QueryTexts.Add(QueryTextOrderStructureCalculationTasksInventoryAllocation);
			
		EndIf;
		QueryText =
			"SELECT DISTINCT
			|	Set.Ref AS Ref
			|INTO AllOrders
			|FROM(
			|	SELECT
			|		Jobs.ShipmentOrder AS Ref
			|	FROM
			|		JobsForAllocatingInventory AS Jobs
			|	WHERE
			|		Jobs.ShipmentOrder <> UNDEFINED
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		ISNULL(ExpectedShipment.ShipmentOrder, UNDEFINED) AS Ref
			|	FROM
			|		JobsForAllocatingInventory AS Orders
			|			
			|			LEFT JOIN InformationRegister.InventoryAllocation AS ExpectedShipment
			|			ON ExpectedShipment.Products = Orders.Products
			|			 AND ExpectedShipment.Characteristic = Orders.Characteristic
			|			 AND ExpectedShipment.Warehouse = Orders.Warehouse
			|			 AND ExpectedShipment.Purpose = Orders.Purpose) AS Set
			|INDEX BY
			|	Ref
			|;
			|
			|/////////////////////////////////////////////
			|SELECT
			|	AllOrders.Ref AS Ref
			|FROM
			|	AllOrders AS AllOrders
			|WHERE
			|	AllOrders.Ref <> UNDEFINED
			|	AND NOT TRUE IN(
			|		SELECT TOP 1
			|			TRUE AS OrderIsInRawJobs
			|		FROM
			|			InformationRegister.JobsForAllocatingInventory AS AllTasks_
			|		WHERE
			|			AllTasks_.ShipmentOrder = AllOrders.Ref
			|				AND NOT TRUE IN(
			|					SELECT TOP 1
			|						TRUE AS ThisProductHasBeenWorkedOut
			|					FROM
			|						JobsForAllocatingInventory AS Tasks_Were_Completed
			|					WHERE
			|						Tasks_Were_Completed.Products = AllTasks_.Products
			|							AND Tasks_Were_Completed.Characteristic = AllTasks_.Characteristic
			|							AND Tasks_Were_Completed.Warehouse = AllTasks_.Warehouse
			|							AND Tasks_Were_Completed.Purpose = AllTasks_.Purpose))
			|	AND NOT TRUE IN(
			|		SELECT TOP 1
			|			TRUE AS OrderProductIsInUnprocessedTasks
			|		FROM
			|			InformationRegister.InventoryAllocation AS ExpectedShipment
			|		WHERE
			|			ExpectedShipment.ShipmentOrder = AllOrders.Ref
			|				AND TRUE IN(
			|					SELECT TOP 1
			|						TRUE AS ThisProductIsInTasks
			|					FROM
			|						InformationRegister.JobsForAllocatingInventory AS AllTasks_
			|					WHERE
			|						AllTasks_.Products = ExpectedShipment.Products
			|							AND AllTasks_.Characteristic = ExpectedShipment.Characteristic
			|							AND AllTasks_.Warehouse = ExpectedShipment.Warehouse
			|							AND AllTasks_.Purpose = ExpectedShipment.Purpose)
			|					
			|				AND NOT TRUE IN(
			|					SELECT TOP 1
			|						TRUE AS ThisProductHasBeenWorkedOut
			|					FROM
			|						JobsForAllocatingInventory AS Tasks_Were_Completed
			|					WHERE
			|						Tasks_Were_Completed.Products = ExpectedShipment.Products
			|							AND Tasks_Were_Completed.Characteristic = ExpectedShipment.Characteristic
			|							AND Tasks_Were_Completed.Warehouse = ExpectedShipment.Warehouse
			|							AND Tasks_Were_Completed.Purpose = ExpectedShipment.Purpose))";
		
		QueryTexts.Add(QueryText);
		
		Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
		Results = Query.ExecuteBatch();
		
		Orders = Results[Results.UBound()].Unload().UnloadColumn("Ref");
		ExcludeLinksThatRequireDeferredUpdates(Orders);
		
		RegistersToBeReflected = DocumentsStates.RegistersToReflectStateOfOrders();
		RegistersToBeReflected.SalesOrderStates    = True;
		RegistersToBeReflected.StatusesOfInternalOrders  = True;
		RegistersToBeReflected.ProductionStageStates = True;
		DocumentsStates.AddTasksToStateOfOrders(Undefined, Orders,, RegistersToBeReflected);
		If DynamicStructureOfProductionOrders And Not Results[1].IsEmpty() Then
			
			InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasks(
				Results[1].Unload());
			
			OrderStructure.StartCalculation();
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure RecordDistributionOfStocksInTransaction(Query) Export
	
	Result = DistributionOfInventoryByGoods(Query, "InventoryDistributionProducts", True,
		"InventoryAllocation,AvailableStockBalances");
	RecordInventoryDistributionResult(Result);
	
EndProcedure

Procedure StateWithReflectionOfChanges(OrderDocument, RegisterRecordTable, TempTablesManager, TableSimulationRegistry) Export
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	SetPrivilegedMode(True);
	
	//
	
	Query.SetParameter("TableSimulationRegistry", TableSimulationRegistry);
	Query.SetParameter("OrderDocument", OrderDocument);
	
	Query.Text =
		"SELECT
		|	ReportOrders.ShipmentOrder AS Ref,
		|	ReportOrders.Priority AS Priority,
		|	ReportOrders.DocumentDate AS IBDocumentDate
		|INTO TableSimulationRegistry
		|FROM
		|	&TableSimulationRegistry AS ReportOrders
		|;
		|
		|///////////////////////////////////////////////////
		|SELECT
		|	ReportOrders.Ref AS Ref,
		|	ReportOrders.Priority AS Priority,
		|	ReportOrders.IBDocumentDate AS IBDocumentDate,
		|	FALSE AS AdditionalRecord
		|INTO RegisterOfDocumentsAsAmended
		|FROM
		|	InformationRegister.DocumentsRegistry AS ReportOrders
		|WHERE
		|	NOT Ref IN(
		|		SELECT
		|			ReportOrders.Ref AS Ref
		|		FROM
		|			TableSimulationRegistry AS ReportOrders)
		|		AND NOT ReportOrders.AdditionalRecord
		|		AND TRUE IN(
		|			SELECT TOP 1
		|				TRUE
		|			FROM
		|				InformationRegister.InventoryAllocation AS InformationRecords
		|			WHERE
		|				InformationRecords.ShipmentOrder = ReportOrders.Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	ReportOrders.Ref AS Ref,
		|	ReportOrders.Priority AS Priority,
		|	ReportOrders.IBDocumentDate AS IBDocumentDate,
		|	FALSE AS AdditionalRecord
		|FROM
		|	TableSimulationRegistry AS ReportOrders";
	
	Query.Execute();
	
	Query.SetParameter("SetOfRecordsStocksAndNeeds", RegisterRecordTable);
	Query.SetParameter("Recorder", OrderDocument);
	Query.SetParameter("IsNew", False);
	Query.SetParameter("ControlExcessOfSeparateProvision", False);

	Texts = New Array();
	Text =
		"SELECT
		|	*
		|INTO SetOfRecordsStocksAndNeeds
		|FROM
		|	&SetOfRecordsStocksAndNeeds AS SetOfRecordsStocksAndNeeds";
	Texts.Add(Text);
	Text = StockAllocationRecords.QueryTextOfInitialRegisteredRecordedInventoryAndNeeds();
	Texts.Add(Text);
	Text = StockAllocationRecords.QueryTextOfChangesInRegisteredRecordedInventoryAndNeeds(False, "SetOfRecordsStocksAndNeeds");
	Texts.Add(Text);
	
	Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose
		|INTO InventoryDistributionProducts
		|FROM
		|	SetOfRecordsStocksAndNeeds AS Table";
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose,
		|	Set.ShipmentOrder AS ShipmentOrder,
		|	SUM(Set.Shipment) AS Shipment
		|INTO ChangingBalanceOfGoodsToControlBalance
		|FROM(
		|	SELECT
		|		MovementChanges.Products AS Products,
		|		MovementChanges.Characteristic AS Characteristic,
		|		MovementChanges.Warehouse AS Warehouse,
		|		MovementChanges.Purpose AS Purpose,
		|		MovementChanges.OrderDocument AS ShipmentOrder,
		|		CASE
		|			WHEN SUM(MovementChanges.InStockExpense + MovementChanges.ReserveAtWarehouse) > 0
		|				THEN SUM(MovementChanges.InStockExpense + MovementChanges.ReserveAtWarehouse)
		|			ELSE 0
		|		END
		|		+ CASE
		|			WHEN SUM(MovementChanges.LockedInStockExpense + MovementChanges.ReserveAtWarehouseFromLocked) > 0
		|				THEN SUM(MovementChanges.LockedInStockExpense + MovementChanges.ReserveAtWarehouseFromLocked)
		|			ELSE 0
		|		END AS Shipment
		|	FROM
		|		InventoryAndDemandsUpdate AS MovementChanges
		|	GROUP BY
		|		MovementChanges.Products,
		|		MovementChanges.Characteristic,
		|		MovementChanges.Warehouse,
		|		MovementChanges.Purpose,
		|		MovementChanges.OrderDocument
		|	HAVING
		|		SUM(MovementChanges.InStockExpense + MovementChanges.ReserveAtWarehouse) > 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Jobs.Products AS Products,
		|		Jobs.Characteristic AS Characteristic,
		|		Jobs.Warehouse AS Warehouse,
		|		Jobs.Purpose AS Purpose,
		|		Jobs.ShipmentOrder AS ShipmentOrder,
		|		Jobs.ToReserveRemoval + Jobs.ToReserveRemovalFromUnlocked AS Shipment
		|	FROM
		|		InventoryDistributionProducts AS Goods
		|			
		|			INNER JOIN InformationRegister.JobsForAllocatingInventory AS Jobs
		|			ON Jobs.Products = Goods.Products
		|			 AND Jobs.Characteristic = Goods.Characteristic
		|			 AND Jobs.Warehouse = Goods.Warehouse
		|			 AND Jobs.Purpose = Goods.Purpose
		|	WHERE
		|		Jobs.ToReserveRemoval + Jobs.ToReserveRemovalFromUnlocked > 0) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse,
		|	Set.Purpose,
		|	Set.ShipmentOrder
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose";
	Texts.Add(Text);
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.Execute();
	
	Result = DistributionOfInventoryByGoods(
		Query,
		"InventoryDistributionProducts",
		False,
		"InventoryAllocation",
		"RegisterOfDocumentsAsAmended",
		"InventoryAndDemandsUpdate");
		
	Query.SetParameter("Table", Result.InventoryAllocation);
	Query.Text =
		"SELECT
		|	*
		|INTO SimulationOfReflection
		|FROM
		|	&Table AS Table";
	Query.Execute();

EndProcedure

Procedure AllocationOfInventoryToOrdersInSelectedQueue(Orders, Priority, TempTablesManager) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("OrderDocument", Orders);
	Query.SetParameter("Priority", Priority);
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose
		|INTO AllOrderMaterials
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(, OrderDocument IN(&OrderDocument)) AS Table
		|WHERE
		|	Table.ReserveAtWarehouseBalance > 0
		|		OR Table.ReserveAsReceivedBalance > 0
		|		OR Table.SnoozeReservationBalance > 0
		|		OR Table.ToSupplyBalance > 0
		|		OR Table.NotProvideBalance > 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose
		|INTO InventoryDistributionProducts
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		VALUETYPE(OrderDocument) IN(
		|				TYPE(Document.ProductionStage2_2))
		|			AND NOT OrderDocument IN(&OrderDocument)
		|			AND (Products, Characteristic, Warehouse, Purpose) IN(
		|				SELECT
		|					AllMaterials.Products AS Products,
		|					AllMaterials.Characteristic AS Characteristic,
		|					AllMaterials.Warehouse AS Warehouse,
		|					AllMaterials.Purpose AS Purpose
		|				FROM
		|					AllOrderMaterials AS AllMaterials)
		|			AND NOT (OrderDocument) IN(
		|				SELECT
		|					Register3.Ref AS Ref
		|				FROM
		|					InformationRegister.DocumentsRegistry AS Register3
		|				WHERE
		|					NOT Register3.AdditionalRecord
		|						AND Register3.Priority.AddlOrderingAttribute > &Priority)) AS Table
		|WHERE
		|	Table.OrderedBalance > 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|DROP AllOrderMaterials";
	Query.Execute();

	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	StockAllocationRecords.AddEmptyBalanceChangeTableForItemsToControlBalances(Query);
	
	Result = DistributionOfInventoryByGoods(Query, "InventoryDistributionProducts", False, "InventoryAllocation");
	Query.SetParameter("Set", Result.InventoryAllocation);
	Query.Text =
		"SELECT
		|	Table.InventoryState AS InventoryState,
		|	Table.DemandCharacteristic AS DemandCharacteristic,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.RequestShipmentOn AS RequestShipmentOn,
		|	Table.ReceiptOrder AS ReceiptOrder,
		|	Table.AvailabilityDate AS AvailabilityDate,
		|	Table.Count AS Count
		|INTO Set
		|FROM
		|	&Set AS Table
		|WHERE
		|	Table.ShipmentOrder IN(&OrderDocument)";
	Query.Execute();
	
	Query.Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.RequestShipmentOn AS RequestShipmentOn,
		|	Table.InventoryState AS InventoryState,
		|	Table.DemandCharacteristic AS DemandCharacteristic,
		|	UNDEFINED AS ReceiptOrder,
		|	Table.AvailabilityDate AS AvailabilityDate,
		|	Table.Count AS Count
		|INTO TTDistribution
		|FROM
		|	Set AS Table
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.RequestShipmentOn AS RequestShipmentOn,
		|	Table.InventoryState AS InventoryState,
		|	Table.DemandCharacteristic AS DemandCharacteristic,
		|	Table.ReceiptOrder AS ReceiptOrder,
		|	Table.AvailabilityDate AS AvailabilityDate,
		|	Table.Count AS Count
		|FROM
		|	InformationRegister.InventoryAllocation AS Table
		|WHERE
		|	Table.ShipmentOrder IN(&OrderDocument)
		|		AND NOT TRUE IN(
		|			SELECT TOP 1
		|				TRUE AS ThisIsManufacturedSemiFinishedProduct
		|			FROM
		|				InventoryDistributionProducts AS SemiFinishedProducts
		|		WHERE
		|			SemiFinishedProducts.Products = Table.Products
		|				AND SemiFinishedProducts.Characteristic = Table.Characteristic
		|				AND SemiFinishedProducts.Warehouse = Table.Warehouse
		|				AND SemiFinishedProducts.Purpose = Table.Purpose)
		|INDEX BY
		|	InventoryState, DemandCharacteristic";
	
	Query.Execute();
	
EndProcedure

Procedure UpdateInformationAboutProductAvailabilityForExternalUsers() Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.UpdateDataOnGoodsAvailabilityForExternalUsers);
	
	SetPrivilegedMode(True);

	Query = New Query;
	Query.SetParameter("BegOfDay", BegOfDay(CurrentSessionDate()));
	
	Texts = New Array();
	QueryText =
		"SELECT
		|	&BegOfDay AS Period,
		|	InventoryAllocation.Products AS Products,
		|	InventoryAllocation.Characteristic AS Characteristic,
		|	InventoryAllocation.Warehouse AS Warehouse,
		|	InventoryAllocation.Count AS Available
		|FROM
		|	InformationRegister.InventoryAllocation AS InventoryAllocation
		|WHERE
		|	InventoryAllocation.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|		AND InventoryAllocation.InventoryState = VALUE(Enum.InventoryStates.InStock)
		|		AND InventoryAllocation.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply),
		|			VALUE(Enum.DemandCharacteristics.Surplus))
		|		AND InventoryAllocation.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))";
		
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT
		|	CASE WHEN InventoryAllocation.AvailabilityDate > &BegOfDay THEN
		|			InventoryAllocation.AvailabilityDate
		|		ELSE
		|			&BegOfDay
		|		END AS Period,
		|	InventoryAllocation.Products AS Products,
		|	InventoryAllocation.Characteristic Characteristic,
		|	InventoryAllocation.Warehouse AS Warehouse,
		|	InventoryAllocation.Count AS Available
		|FROM
		|	InformationRegister.InventoryAllocation AS InventoryAllocation
		|WHERE
		|	InventoryAllocation.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|		AND InventoryAllocation.InventoryState IN(
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock))
		|		AND InventoryAllocation.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply),
		|			VALUE(Enum.DemandCharacteristics.Surplus))
		|		AND InventoryAllocation.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND InventoryAllocation.Count <> 0
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	&BegOfDay AS Period,
		|	OldData.Products AS Products,
		|	OldData.Characteristic AS Characteristic,
		|	OldData.Warehouse AS Warehouse,
		|	0 AS Available
		|FROM
		|	InformationRegister.GoodsAvailabilityForExternalUsers AS OldData";
	Texts.Add(QueryText);
	QueryText = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
	
	Text =
		"SELECT
		|	NestedQuery.Period AS Period,
		|	NestedQuery.Products AS Products,
		|	NestedQuery.Characteristic AS Characteristic,
		|	NestedQuery.Warehouse AS Warehouse,
		|	SUM(NestedQuery.Available) AS Available
		|FROM
		|	NestedQueryOverridable AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Products,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Warehouse,
		|	NestedQuery.Period
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Period";
	Query.Text = StrReplace(Text, "NestedQueryOverridable", StrTemplate("(%1)", QueryText));
	
	RemainderLine = Query.Execute().Select();
	
	Var_Key = New Structure("Products,Characteristic,Warehouse");
	Total = 0;
	RecordSet = InformationRegisters.GoodsAvailabilityForExternalUsers.CreateRecordSet();
	While RemainderLine.Next() Do
		
		If RemainderLine.Products <> Var_Key.Products
			Or RemainderLine.Characteristic <> Var_Key.Characteristic
			Or RemainderLine.Warehouse <> Var_Key.Warehouse Then
			
			If Var_Key.Products <> Undefined Then
				RecordSet.Write();
				RecordSet.Clear();
			EndIf;
			
			FillPropertyValues(Var_Key, RemainderLine);
			Total = 0;
			RecordSet.Filter.Products.Set(Var_Key.Products, True);
			RecordSet.Filter.Characteristic.Set(Var_Key.Characteristic, True);
			RecordSet.Filter.Warehouse.Set(Var_Key.Warehouse, True);
			
		EndIf;
		Total = RemainderLine.Available + Total;
		
		If Total > 0 Then
			Record = RecordSet.Add();
			FillPropertyValues(Record, RemainderLine);
			Record.Available = Total;
		EndIf;
		
	EndDo;
	
	If Var_Key.Products <> Undefined Then
		RecordSet.Write();
	EndIf;
	
EndProcedure

// Sets locks when writing to either of the two registers of the allocation of stocks or available stat items
// Parameters:
//  Block - DataLock - Block
//  OwnGoods - Structure - Structure or table with fields:
//   			* Products - CatalogRef.Products
//   			* Characteristic - CatalogRef.ItemsCharacteristics
//   			* Warehouse - CatalogRef.Warehouses,CatalogRef.BusinessStructure
//   			* Purpose - CatalogRef.Assignments
//  TableInventoryAllocation - ValueTable,QueryResult - With Fields:
//   			* Products - CatalogRef.Products
//   			* Characteristic - CatalogRef.ItemsCharacteristics
//   			* Warehouse - CatalogRef.Warehouses,CatalogRef.BusinessStructure
//   			* Purpose - CatalogRef.Assignments
//  TableAvailableGoodsBalances - ValueTable,QueryResult - With Fields:
//   			* Products - CatalogRef.Products
//   			* Characteristic - CatalogRef.ItemsCharacteristics
//   			* Warehouse - CatalogRef.Warehouses
Procedure AddLocks(Block, OwnGoods, TableInventoryAllocation, TableAvailableGoodsBalances) Export
	
	If OwnGoods = Undefined Then
		
		LockItem = Block.Add("InformationRegister.InventoryAllocation");
		LockItem.UseFromDataSource("Products", "Products");
		LockItem.UseFromDataSource("Characteristic", "Characteristic");
		LockItem.UseFromDataSource("Warehouse", "Warehouse");
		LockItem.UseFromDataSource("Purpose", "Purpose");
		LockItem.DataSource = TableInventoryAllocation;
		LockItem.Mode = DataLockMode.Exclusive;
		
		LockItem = Block.Add("InformationRegister.AvailableStockBalances");
		LockItem.UseFromDataSource("Products", "Products");
		LockItem.UseFromDataSource("Characteristic", "Characteristic");
		LockItem.UseFromDataSource("Warehouse", "Warehouse");
		LockItem.DataSource = TableAvailableGoodsBalances;
		LockItem.Mode = DataLockMode.Exclusive;
		
	Else
		
		LockItem = Block.Add("InformationRegister.InventoryAllocation");
		LockItem.SetValue("Products", OwnGoods.Products);
		LockItem.SetValue("Characteristic", OwnGoods.Characteristic);
		LockItem.SetValue("Warehouse", OwnGoods.Warehouse);
		LockItem.SetValue("Purpose", OwnGoods.Purpose);
		LockItem.Mode = DataLockMode.Exclusive;
		
		If TypeOf(OwnGoods.Warehouse) = Type("CatalogRef.Warehouses") And ValueIsFilled(OwnGoods.Warehouse) Then
			LockItem = Block.Add("InformationRegister.AvailableStockBalances");
			LockItem.SetValue("Products", OwnGoods.Products);
			LockItem.SetValue("Characteristic", OwnGoods.Characteristic);
			LockItem.SetValue("Warehouse", OwnGoods.Warehouse);
			LockItem.Mode = DataLockMode.Exclusive;
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Goods - ValueTable - table with fields:
//   * Products - See AccumulationRegister.InventoryAndDemands.Products
//   * Characteristic - See AccumulationRegister.InventoryAndDemands.Characteristic
//   * Warehouse - See AccumulationRegister.InventoryAndDemands.Warehouse
//   * Purpose - See AccumulationRegister.InventoryAndDemands.Purpose
//  RegisterNames - String - comma-separated register names. There are only two names available "Available Inventory items" and "Inventory Distribution".
// Returns:
//  Structure:
//   * InventoryAllocation - See InformationRegisters.InventoryAllocation
//   * AvailableStockBalances - See InformationRegisters.AvailableStockBalances
Function UpdatingInformationSecurityByProduct(Goods, RegisterNames) Export
	
	Query = New Query();
	Query.SetParameter("Goods", Goods);
	Query.TempTablesManager = New TempTablesManager();
	Query.Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose
		|INTO InventoryDistributionProducts
		|FROM
		|	&Goods AS Table
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////
		|SELECT TOP 0
		|	Jobs.Products AS Products,
		|	Jobs.Characteristic AS Characteristic,
		|	Jobs.Warehouse AS Warehouse,
		|	Jobs.Purpose AS Purpose,
		|	Jobs.ShipmentOrder AS ShipmentOrder,
		|	Jobs.ToReserveRemoval AS Shipment
		|INTO ChangingBalanceOfGoodsToControlBalance
		|FROM
		|	InformationRegister.JobsForAllocatingInventory AS Jobs";
	Query.Execute();
	
	Result = DistributionOfInventoryByGoods(Query, "InventoryDistributionProducts", True, RegisterNames);
	
	Return Result;
	
EndFunction

// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList of String - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
Procedure AddTextOfControlRequest(Query, QueryTexts, Document) Export
	
	ThereIsQualityControl = GetFunctionalOption("UseGoodsQualityControl");
	ThereIsConsolidatedLotReferenceControl = ThereIsQualityControl And TypeOf(Document) = Type("DocumentObject.InventoryAssignmentAdjustment");
	
	#Region TempTable_ChangesForAssuranceControl
	
	// Calculation of changes for an empty Lot reference.
	
	// 1) The usual expense document:
	
	// Cash out (total) = 5
	// Blocked Cash Withdrawal = 0
	// Cash (total) = -5
	// Blocked Cash = 0
	
	// 2) The document of expenditure on the Lot reference:
	
	// Cash out (total) = 5
	// Blocked Cash withdrawal = 5
	// Cash (total) = -5
	// Blocked Cash = -5
	
	// 3) The usual parish document:
	
	// Cash out (total) = 0
	// Blocked Cash Withdrawal = 0
	// Cash (total) = 5
	// Blocked Cash = 0
	
	// 4) The document of the parish by party:
	
	// Cash out (total) = 0
	// Blocked Cash Withdrawal = 0
	// Cash (total) = 5
	// Blocked Cash = 5
	
	// The formula is appropriate: Cash withdrawal (by empty Lot reference) = Cash out (total) - Blocked Cash out
	// The formula is appropriate: Cash (by empty Lot reference) = Cash (total) - Blocked Cash
	// According to these formulas, in examples (2) and (4) there are no changes at all for analysts with an empty Lot reference.
	// In example (1), there is an expense for analytics with an empty Lot reference and there is a decrease in the Balance when conducting the document.
	// In example (4), there is no expense for analytics with an empty Lot reference and there is an increase in the Balance when conducting the document.
	
	// Examples 5-8, similarly, cancellation of the event (or reduction of the document).
	// The values of resource changes do not change. The signs of resource changes are reversed. Formulas are also appropriate.
	
	// 9) The document of adjustment from batch to batch:
	
	// Cash out (total) = 0
	// Blocked Cash withdrawal = 5
	// Cash (total) = 0
	// Blocked Cash = 0
	
	// 10) An adjustment document from a batch to an empty batch (unblocking a batch, for example, a quality control act with the Unlock action):
	
	// Cash out (total) = 0
	// Blocked Cash withdrawal = 5
	// Cash (total) = 0
	// Blocked Cash = -5
	
	// 11) An adjustment document from an empty Lot reference to a non-empty Lot reference (blocking from stock, for example, an application for control):
	
	// Cash out (total) = 0
	// Blocked Cash withdrawal = 5
	// Cash (total) = 0
	// Blocked Cash = -5
	
	// The formula is inappropriate: Cash withdrawal (for an empty batch) = Cash out (total) - Blocked Cash out
	// The formula is inappropriate: Cash (for an empty batch) = Cash (total) - Blocked Cash
	
	// Examples 12-14, similarly, cancellation of the Lot reference adjustment document (or reduction of the document).
	// The values of resource changes do not change. The signs of resource changes are reversed. Formulas are also appropriate.
	
	// 15) The document of adjustment from a batch to an empty one (unblocking a batch) with simultaneous consumption from an empty batch according to the methodology is not supported.
	// It is perceived by the system as an expense for a non-empty batch and is not subject to control for an empty batch (it is perceived as an example (2).
	// 16) Similarly, cancellation of the event (or reduction of the document).
	
	// 17) Mixed document of adjustment from Lot reference to empty Lot reference (2 pcs.) and Lot reference consumption (3 pcs.):
	
	// Cash out (total) = 3
	// Blocked Cash withdrawal = 5
	// Cash (total) = -3
	// Blocked Cash = -5
	
	// 18) Mixed document of adjustment from Lot reference to Lot reference (2 pcs.) and Lot reference consumption (3 pcs.):
	
	// Cash out (total) = 3
	// Blocked Cash withdrawal = 5
	// Cash (total) = -3
	// Blocked Cash = -3
	
	// 19) Mixed document adjustments from empty Lot reference to Lot reference (10 pcs.) and Lot reference consumption (3 pcs.):
	
	// Cash out (total) = 3
	// Blocked Cash withdrawal = 3
	// Cash (total) = -3
	// Blocked Cash = 7
	
	// The formula is inappropriate: Cash withdrawal (for an empty batch) = Cash out (total) - Blocked Cash out
	// The formula is inappropriate: Cash (for an empty batch) = Cash (total) - Blocked Cash
	
	// Development of an appropriate formula:
	// If there is a blocked cash withdrawal > 0, it may be the shipment of a batch item, or it may be the unblocking of a batch item or an adjustment to another batch.
	// It is necessary to find the change in cash and the cost > 0.
	// If the cash withdrawal is blocked > Cash withdrawal, then part of the shipment of the batch, and the rest is unblocking or adjusting to another batch.
	// Thus, for an empty batch, the cash withdrawal (>0) must be reduced by Min (Blocked Cash withdrawal (>0), Cash withdrawal (>0))
	// Similarly, to cancel the expense for an empty batch, the cash outflow (<0) must be reduced by Max (blocked Cash Outflow (<0), Cash outflow (<0))
	
	TextOfSet =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Table.AvailableMinusBlocked AS InStock,
		|	Table.YouWillReceiveNegativeMessageBlocked AS Received_1,
		|	Table.ReserveAtWarehouse AS ReserveAtWarehouse,
		|	Table.ReserveAsReceived AS ReserveAsReceived,
		|	Table.AvailableExpenseMinusBlocked AS InStockExpense,
		|	0 AS AvailableByLotReferenceInSummary,
		|	0 AS AvailableExpenseByLotReferenceSummary
		|FROM
		|	InventoryAndDemandsUpdate AS Table";
		
	If ThereIsQualityControl Then
		
		Texts = New Array();
		Texts.Add(TextOfSet);
		Text =
			"SELECT
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.Warehouse AS Warehouse,
			|	Table.Purpose AS Purpose,
			|	Table.OrderDocument AS ControlledLotReference,
			|	Table.LockedInStock AS InStock,
			|	Table.LockedReceipt AS Received_1,
			|	Table.ReserveAtWarehouseFromLocked AS ReserveAtWarehouse,
			|	Table.ReserveUponReceiptFromLocked AS ReserveAsReceived,
			|	Table.LockedInStockExpense AS InStockExpense,
			|	0 AS AvailableByLotReferenceInSummary,
			|	0 AS AvailableExpenseByLotReferenceSummary
			|FROM
			|	InventoryAndDemandsUpdate AS Table
			|WHERE
			|	Table.OrderDocument <> UNDEFINED";
		Texts.Add(Text);
		
		If ThereIsConsolidatedLotReferenceControl Then
			
			Text =
				"SELECT
				|	Table.Products AS Products,
				|	Table.Characteristic AS Characteristic,
				|	Table.Warehouse AS Warehouse,
				|	Table.Purpose AS Purpose,
				|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
				|	0 AS InStock,
				|	0 AS Received_1,
				|	0 AS ReserveAtWarehouse,
				|	0 AS ReserveAsReceived,
				|	0 AS InStockExpense,
				|	Table.LockedInStock AS AvailableByLotReferenceInSummary,
				|	Table.LockedInStockExpense AS AvailableExpenseByLotReferenceSummary
				|FROM
				|	InventoryAndDemandsUpdate AS Table
				|WHERE
				|	Table.OrderDocument <> UNDEFINED";
			
			Texts.Add(Text);
			
		EndIf;
		
		TextOfSet = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf;
	
	QueryText =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	SUM(Table.InStockExpense) AS InStockExpense,
		|	SUM(Table.ReserveAtWarehouse) AS ReserveAtWarehouse,
		|	SUM(Table.ReserveAsReceived) AS ReserveAsReceived,
		|	SUM(Table.InStock) AS InStock,
		|	SUM(Table.Received_1) AS Received_1,
		|	SUM(Table.AvailableByLotReferenceInSummary) AS AvailableByLotReferenceInSummary,
		|	SUM(Table.AvailableExpenseByLotReferenceSummary) AS AvailableExpenseByLotReferenceSummary
		|INTO InventoriesAndNeedsChangeGrouped
		|FROM
		|	SetOverridable AS Table
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse,
		|	Table.Purpose,
		|	Table.ControlledLotReference
		|HAVING
		|	SUM(Table.InStockExpense) <> 0
		|	OR SUM(Table.ReserveAtWarehouse) <> 0
		|	OR SUM(Table.ReserveAsReceived) <> 0
		|	OR SUM(Table.AvailableExpenseByLotReferenceSummary) <> 0
		|INDEX BY
		|	Products, Characteristic, Warehouse";
	QueryText = StrReplace(QueryText, "SetOverridable", StrTemplate("(%1)", TextOfSet));
	QueryTexts.Add(QueryText, "InventoriesAndNeedsChangeGrouped");
	
	QueryText =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.InStockExpense AS InStockExpense,
		|	Table.ReserveAtWarehouse AS ReserveAtWarehouse,
		|	Table.ReserveAsReceived AS ReserveAsReceived,
		|	Table.InStock AS InStock,
		|	Table.Received_1 AS Received_1,
		|	Table.AvailableByLotReferenceInSummary AS AvailableByLotReferenceInSummary,
		|	Table.AvailableExpenseByLotReferenceSummary AS AvailableExpenseByLotReferenceSummary
		|INTO ChangesToControlProvision
		|FROM
		|	InventoriesAndNeedsChangeGrouped AS Table
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpCharacteristic
		|		ON SettingUpCharacteristic.Warehouse          = Table.Warehouse
		|		 AND SettingUpCharacteristic.Products   = Table.Products
		|		 AND SettingUpCharacteristic.Characteristic = Table.Characteristic
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpProducts
		|		ON SettingUpProducts.Warehouse        = Table.Warehouse
		|		 AND SettingUpProducts.Products = Table.Products
		|		 AND SettingUpProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		
		|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpWarehouse
		|		ON SettingUpWarehouse.Warehouse          = Table.Warehouse
		|		 AND SettingUpWarehouse.Products   = VALUE(Catalog.Products.EmptyRef)
		|		 AND SettingUpWarehouse.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|WHERE
		|	ISNULL(SettingUpCharacteristic.AvailableStockControl,
		|			ISNULL(SettingUpProducts.AvailableStockControl,
		|				SettingUpWarehouse.AvailableStockControl))
		|		AND CAST(Table.Products AS Catalog.Products).ItemsType
		|			<> VALUE(Enum.ItemsTypes.Work_5)
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
	QueryTexts.Add(QueryText, "ChangesToControlProvision");
	
	#EndRegion
	
	#Region TempTable_ReservesForOrdersToControlCollateral
	
	TextOfSet =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	CASE
		|		WHEN Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked)
		|			THEN Table.ShipmentOrder
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.Count AS ReceivedReserves
		|FROM
		|	InformationRegister.InventoryAllocation AS Table
		|WHERE
		|	(Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAsReceived)
		|			AND Table.InventoryState = VALUE(Enum.InventoryStates.InStock)
		|		OR Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked)
		|			AND Table.InventoryState IN(
		|				VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|				VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking)))
		|		AND TRUE IN(
		|			SELECT TOP 1
		|				TRUE AS ThereAreRecords
		|			FROM
		|				InventoryAndDemandsBeforeWrite AS Orders
		|			WHERE
		|				Orders.Products = Table.Products
		|				 AND Orders.Characteristic = Table.Characteristic
		|				 AND Orders.Warehouse = Table.Warehouse
		|				 AND Orders.Purpose = Table.Purpose
		|				 AND Orders.OrderDocument = Table.ShipmentOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	- Table.ToReserveRemoval AS ReceivedReserves
		|FROM
		|	InformationRegister.JobsForAllocatingInventory AS Table
		|WHERE
		|	Table.ToReserveRemoval > 0
		|	AND TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS ThereAreRecords
		|		FROM
		|			InventoryAndDemandsBeforeWrite AS Orders
		|		WHERE
		|			Orders.Products = Table.Products
		|			 AND Orders.Characteristic = Table.Characteristic
		|			 AND Orders.Warehouse = Table.Warehouse
		|			 AND Orders.Purpose = Table.Purpose
		|			 AND Orders.OrderDocument = Table.ShipmentOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ShipmentOrder AS ControlledLotReference,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	- Table.ToReserveRemovalFromUnlocked AS ReceivedReserves
		|FROM
		|	InformationRegister.JobsForAllocatingInventory AS Table
		|WHERE
		|	Table.ToReserveRemovalFromUnlocked > 0
		|	AND TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS ThereAreRecords
		|		FROM
		|			InventoryAndDemandsBeforeWrite AS Orders
		|		WHERE
		|			Orders.Products = Table.Products
		|			 AND Orders.Characteristic = Table.Characteristic
		|			 AND Orders.Warehouse = Table.Warehouse
		|			 AND Orders.Purpose = Table.Purpose
		|			 AND Orders.OrderDocument = Table.ShipmentOrder)";
	
	// When shipment on orders dimension of the Order is empty, but you can use the reserves that were in the shipped orders.
	// These orders are in the RegisterRecords before recording.
	QueryText =
		"SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose,
		|	Set.ControlledLotReference AS ControlledLotReference,
		|	SUM(Set.ReceivedReserves) AS ReceivedReserves
		|INTO ReservesForOrdersToControlCollateral
		|FROM(
		|	SELECT
		|		SetByOrders.Products AS Products,
		|		SetByOrders.Characteristic AS Characteristic,
		|		SetByOrders.Warehouse AS Warehouse,
		|		SetByOrders.Purpose AS Purpose,
		|		SetByOrders.ControlledLotReference AS ControlledLotReference,
		|		SetByOrders.ShipmentOrder AS ShipmentOrder,
		|		SUM(SetByOrders.ReceivedReserves) AS ReceivedReserves
		|	FROM
		|		&Set AS SetByOrders
		|	GROUP BY
		|		SetByOrders.Products,
		|		SetByOrders.Characteristic,
		|		SetByOrders.Warehouse,
		|		SetByOrders.Purpose,
		|		SetByOrders.ShipmentOrder,
		|		SetByOrders.ControlledLotReference
		|HAVING
		|	SUM(SetByOrders.ReceivedReserves) > 0) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse,
		|	Set.Purpose,
		|	Set.ControlledLotReference
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
	QueryText = StrReplace(QueryText, "&Set", StrTemplate("(%1)", TextOfSet));
	QueryTexts.Add(QueryText, "ReservesForOrdersToControlCollateral");
	
	#EndRegion
	
	#Region TempTable_ChangesAndReservesForCollateralControl
	
	QueryText =
		"SELECT
		|	Changes.Products AS Products,
		|	Changes.Characteristic AS Characteristic,
		|	Changes.Warehouse AS Warehouse,
		|	Changes.Purpose AS Purpose,
		|	Changes.ControlledLotReference AS ControlledLotReference,
			// Increase Shipping.
		|	Changes.InStockExpense AS Ship,
			// Increase to Ship or reserve a deposit, uncovered by an increase in availability and own reserves allocated to the order.
		|	CASE
		|		WHEN Changes.ReserveAtWarehouse
		|					+ Changes.InStockExpense
		|					- ISNULL(Reserves.ReceivedReserves, 0) < 0
		|				OR Changes.ReserveAtWarehouse
		|					- Changes.InStock
		|					- ISNULL(Reserves.ReceivedReserves, 0) < 0
		|			THEN 0
		|		WHEN Changes.ReserveAtWarehouse
		|					+ Changes.InStockExpense
		|					- ISNULL(Reserves.ReceivedReserves, 0)
		|				< Changes.ReserveAtWarehouse
		|					- Changes.InStock
		|					- ISNULL(Reserves.ReceivedReserves, 0)
		|			THEN
		|				Changes.ReserveAtWarehouse
		|					+ Changes.InStockExpense
		|					- ISNULL(Reserves.ReceivedReserves, 0)
		|		ELSE
		|			Changes.ReserveAtWarehouse
		|				- Changes.InStock
		|				- ISNULL(Reserves.ReceivedReserves, 0)
		|	END AS RequestForAvailableInventory,
			// An increase in Ship, reserve deposit, or reserve non-availability, uncovered by an increase in availability or expected receipt.
		|	CASE
		|		WHEN Changes.ReserveAtWarehouse
		|					+ Changes.ReserveAsReceived
		|					+ Changes.InStockExpense
		|					- Changes.Received_1 < 0
		|				OR Changes.ReserveAtWarehouse
		|					+ Changes.ReserveAsReceived
		|					- Changes.InStock
		|					- Changes.Received_1 < 0
		|			THEN 0
		|		WHEN Changes.ReserveAtWarehouse
		|					+ Changes.ReserveAsReceived
		|					+ Changes.InStockExpense
		|					- Changes.Received_1
		|				< Changes.ReserveAtWarehouse
		|					+ Changes.ReserveAsReceived
		|					- Changes.InStock
		|					- Changes.Received_1
		|			THEN
		|				Changes.ReserveAtWarehouse
		|					+ Changes.ReserveAsReceived
		|					+ Changes.InStockExpense
		|					- Changes.Received_1
		|		ELSE
		|			Changes.ReserveAtWarehouse
		|				+ Changes.ReserveAsReceived
		|				- Changes.InStock
		|				- Changes.Received_1
		|	END AS RequestFreeBalanceOfEverything,
			// The increase is shipped by Lot reference in summary.
		|	CASE
		|		WHEN Changes.AvailableExpenseByLotReferenceSummary < 0 OR - Changes.AvailableByLotReferenceInSummary < 0
		|			THEN 0
		|		WHEN Changes.AvailableExpenseByLotReferenceSummary < - Changes.AvailableByLotReferenceInSummary
		|			THEN Changes.AvailableExpenseByLotReferenceSummary
		|		ELSE - Changes.AvailableByLotReferenceInSummary
		|	END AS ShipByLotReferenceInSummary
		|INTO ChangesAndProvisionsForCollateralControl
		|FROM
		|	ChangesToControlProvision AS Changes
		|		LEFT JOIN ReservesForOrdersToControlCollateral AS Reserves
		|		ON Reserves.Products = Changes.Products
		|		 AND Reserves.Characteristic = Changes.Characteristic
		|		 AND Reserves.Warehouse = Changes.Warehouse
		|		 AND Reserves.Purpose = Changes.Purpose
		|		 AND Reserves.ControlledLotReference = Changes.ControlledLotReference
		|WHERE
		|	Changes.InStockExpense > 0
		|		OR NOT &MonitorOnlyActualBalance
		|			AND Changes.ReserveAtWarehouse
		|				+ Changes.InStockExpense
		|				- ISNULL(Reserves.ReceivedReserves, 0) > 0
		|			AND Changes.ReserveAtWarehouse
		|				- Changes.InStock
		|				- ISNULL(Reserves.ReceivedReserves, 0) > 0
		|		OR NOT &MonitorOnlyActualBalance
		|			AND &ControlBalanceOfGoodsToBeReservedUponReceipt
		|			AND Changes.ReserveAtWarehouse
		|				+ Changes.ReserveAsReceived
		|				+ Changes.InStockExpense
		|				- Changes.Received_1 > 0
		|			AND Changes.ReserveAtWarehouse
		|				+ Changes.ReserveAsReceived
		|				- Changes.InStock
		|				- Changes.Received_1 > 0
		|		OR NOT &MonitorOnlyActualBalance
		|			AND Changes.AvailableExpenseByLotReferenceSummary > 0
		|			AND - Changes.AvailableByLotReferenceInSummary > 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
	QueryTexts.Add(QueryText, "ChangesAndProvisionsForCollateralControl");
	
	#EndRegion
	
	#Region TempTable_AnalyticsInventoryAndNeedsForCollateralControl
	
	NameOfAnalystTable = "ChangesAndProvisionsForCollateralControl";
	If ThereIsQualityControl Then
		
		NameOfAnalystTable = "AnalystsInventoryAndRequirementsForSupplyControl";
		
		QueryText =
			"SELECT
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.Warehouse AS Warehouse,
			|	Table.Purpose AS Purpose
			|INTO AnalystsInventoryAndRequirementsForSupplyControl
			|FROM
			|	ChangesAndProvisionsForCollateralControl AS Table
			|WHERE
			|	Table.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose";
		QueryTexts.Add(QueryText, "AnalystsInventoryAndRequirementsForSupplyControl");
		
		QueryText =
			"SELECT
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.Warehouse AS Warehouse,
			|	Table.Purpose AS Purpose,
			|	Table.ControlledLotReference AS ControlledLotReference
			|INTO AnalystsInventoryAndRequirementsForMonitoringSupplyOfControlledLotReferences
			|FROM
			|	ChangesAndProvisionsForCollateralControl AS Table
			|WHERE
			|	Table.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, ControlledLotReference";
		QueryTexts.Add(QueryText, "AnalystsInventoryAndRequirementsForMonitoringSupplyOfControlledLotReferences");
		
	EndIf;
	
	#EndRegion
	
	#Region TempTable_ControlErrorsForAssuranceControl
	
	TextOfSet =
		"SELECT
		|	ChangesForControl.Products AS Products,
		|	ChangesForControl.Characteristic AS Characteristic,
		|	ChangesForControl.Warehouse AS Warehouse,
		|	ChangesForControl.Purpose AS Purpose,
		|	ChangesForControl.ControlledLotReference AS ControlledLotReference,
		|	FALSE ThereIsReserveAsReceived,
		|	
		|	ChangesForControl.Ship AS Ship,
		|	ChangesForControl.RequestForAvailableInventory AS RequestForAvailableInventory,
		|	ChangesForControl.RequestFreeBalanceOfEverything AS RequestFreeBalanceOfEverything,
		|	ChangesForControl.ShipByLotReferenceInSummary AS ShipByLotReferenceInSummary,
		|	
		|	0 AS ControlOfActualBalanceInWarehouse,
		|	0 AS ControlOfShipmentFromOwnReserve,
		|	0 AS ControlOfAvailableInventoryInWarehouse,
		|	0 AS ControlOfFreeBalanceOfEverything,
		|	0 AS ControlOfAvailableInventoryForReservingAsItBecomesAvailable
		|FROM
		|	ChangesAndProvisionsForCollateralControl AS ChangesForControl
		|
		|UNION ALL
		|
		|SELECT
		|	Balance.Products AS Products,
		|	Balance.Characteristic AS Characteristic,
		|	Balance.Warehouse AS Warehouse,
		|	Balance.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Balance.ReserveAsReceivedBalance > 0
		|		OR Balance.ReserveUponReceiptFromLockedBalance > 0 AS ThereIsReserveAsReceived,
		|	
		|	0 AS Ship,
		|	0 AS RequestForAvailableInventory,
		|	0 AS RequestFreeBalanceOfEverything,
		|	0 AS ShipByLotReferenceInSummary,
		|
		|	Balance.InStockBalance
		|		- Balance.LockedInStockBalance AS ControlOfActualBalanceInWarehouse,
		|	
		|	Balance.InStockBalance
		|		- Balance.LockedInStockBalance
		|		- Balance.ReserveAtWarehouseBalance AS ControlOfShipmentFromOwnReserve,
		|	
		|	Balance.InStockBalance
		|		- Balance.LockedInStockBalance
		|		- Balance.ReserveAtWarehouseBalance
		|		- Balance.ReserveAsReceivedBalance AS ControlOfAvailableInventoryInWarehouse,
		|	
		|	Balance.InStockBalance
		|		+ Balance.Received_1Balance
		|		- Balance.ReserveAtWarehouseBalance
		|		- Balance.ReserveAsReceivedBalance
		|		- Balance.ReserveAtWarehouseFromLockedBalance
		|		- Balance.ReserveUponReceiptFromLockedBalance AS ControlOfFreeBalanceOfEverything,
		|	
		|	Balance.InStockBalance
		|		- Balance.LockedInStockBalance
		|		- Balance.ReserveAtWarehouseBalance
		|		- Balance.ReserveAsReceivedBalance AS ControlOfAvailableInventoryForReservingAsItBecomesAvailable
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Table.Products AS Products,
		|				Table.Characteristic AS Characteristic,
		|				Table.Warehouse AS Warehouse,
		|				Table.Purpose AS Purpose
		|			FROM
		|				&Analysts AS Table)) AS Balance
		|
		|UNION ALL
		|
		|SELECT
		|	Balance.Products AS Products,
		|	Balance.Characteristic AS Characteristic,
		|	Balance.Warehouse AS Warehouse,
		|	Balance.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE ThereIsReserveAsReceived,
		|	
		|	0 AS Ship,
		|	0 AS RequestForAvailableInventory,
		|	0 AS RequestFreeBalanceOfEverything,
		|	0 AS ShipByLotReferenceInSummary,
		|	
		// for the Session parameter.Conducts a check of the reserves of goods orders need to be shipped from the reserves of other orders, but not their own.
		|	- Balance.ReserveAtWarehouseBalance AS ControlOfActualBalanceInWarehouse,
		|	0 AS ControlOfShipmentFromOwnReserve,
		|	Balance.ReserveAsReceivedBalance AS ControlOfAvailableInventoryInWarehouse,
		|	0 AS ControlOfFreeBalanceOfEverything,
		|	0 AS ControlOfAvailableInventoryForReservingAsItBecomesAvailable
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose, OrderDocument) IN(
		|			SELECT
		|				Table.Products AS Products,
		|				Table.Characteristic AS Characteristic,
		|				Table.Warehouse AS Warehouse,
		|				Table.Purpose AS Purpose,
		|				Table.OrderDocument AS OrderDocument
		|			FROM
		|				InventoryAndNeedsAffectedOrders AS Table)
		|		AND (Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Table.Products AS Products,
		|				Table.Characteristic AS Characteristic,
		|				Table.Warehouse AS Warehouse,
		|				Table.Purpose AS Purpose
		|			FROM
		|				&Analysts AS Table)) AS Balance";
	TextOfSet = StrReplace(TextOfSet, "&Analysts", NameOfAnalystTable);
	
	If ThereIsQualityControl Then
		
		Texts = New Array();
		Texts.Add(TextOfSet);
		
		Text =
			"SELECT
			|	Balance.Products AS Products,
			|	Balance.Characteristic AS Characteristic,
			|	Balance.Warehouse AS Warehouse,
			|	Balance.Purpose AS Purpose,
			|	Balance.OrderDocument AS ControlledLotReference,
			|	Balance.ReserveUponReceiptFromLockedBalance > 0 AS ThereIsReserveAsReceived,
			|	
			|	0 AS Ship,
			|	0 AS RequestForAvailableInventory,
			|	0 AS RequestFreeBalanceOfEverything,
			|	0 AS ShipByLotReferenceInSummary,
			|	
			|	Balance.LockedInStockBalance AS ControlOfActualBalanceInWarehouse,
			|	
			|	Balance.LockedInStockBalance
			|		- Balance.ReserveAtWarehouseFromLockedBalance AS ControlOfShipmentFromOwnReserve,
			|	
			|	Balance.LockedInStockBalance
			|		- Balance.ReserveAtWarehouseFromLockedBalance
			|		- Balance.ReserveUponReceiptFromLockedBalance AS ControlOfAvailableInventoryInWarehouse,
			|	
			|	Balance.LockedInStockBalance
			|		+ Balance.LockedReceiptBalance
			|		- Balance.ReserveAtWarehouseFromLockedBalance
			|		- Balance.ReserveUponReceiptFromLockedBalance AS ControlOfFreeBalanceOfEverything,
			|	
			|	0 AS ControlOfAvailableInventoryForReservingAsItBecomesAvailable
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(,
			|		(Products, Characteristic, Warehouse, Purpose, OrderDocument) IN(
			|			SELECT
			|				Table.Products AS Products,
			|				Table.Characteristic AS Characteristic,
			|				Table.Warehouse AS Warehouse,
			|				Table.Purpose AS Purpose,
			|				Table.ControlledLotReference AS OrderDocument
			|			FROM
			|				AnalystsInventoryAndRequirementsForMonitoringSupplyOfControlledLotReferences AS Table)) AS Balance
			|
			|UNION ALL
			|
			|SELECT
			|	Balance.Products AS Products,
			|	Balance.Characteristic AS Characteristic,
			|	Balance.Warehouse AS Warehouse,
			|	Balance.Purpose AS Purpose,
			|	Balance.OrderDocument AS ControlledLotReference,
			|	FALSE ThereIsReserveAsReceived,
			|	
			|	0 AS Ship,
			|	0 AS RequestForAvailableInventory,
			|	0 AS RequestFreeBalanceOfEverything,
			|	0 AS ShipByLotReferenceInSummary,
			|	
			// for the Session parameter.Conducts a check of the reserves of goods orders need to be shipped from the reserves of other orders, but not their own.
			|	- Balance.ReserveAtWarehouseFromLockedBalance AS ControlOfActualBalanceInWarehouse,
			|	0 AS ControlOfShipmentFromOwnReserve,
			|	Balance.ReserveUponReceiptFromLockedBalance AS ControlOfAvailableInventoryInWarehouse,
			|	0 AS ControlOfFreeBalanceOfEverything,
			|	0 AS ControlOfAvailableInventoryForReservingAsItBecomesAvailable
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(,
			|		(Products, Characteristic, Warehouse, Purpose, OrderDocument) IN(
			|			SELECT
			|				Table.Products AS Products,
			|				Table.Characteristic AS Characteristic,
			|				Table.Warehouse AS Warehouse,
			|				Table.Purpose AS Purpose,
			|				Table.OrderDocument AS OrderDocument
			|			FROM
			|				InventoryAndNeedsAffectedOrders AS Table)
			|		AND (Products, Characteristic, Warehouse, Purpose, OrderDocument) IN(
			|			SELECT
			|				Table.Products AS Products,
			|				Table.Characteristic AS Characteristic,
			|				Table.Warehouse AS Warehouse,
			|				Table.Purpose AS Purpose,
			|				Table.ControlledLotReference AS OrderDocument
			|			FROM
			|				AnalystsInventoryAndRequirementsForMonitoringSupplyOfControlledLotReferences AS Table)) AS Balance";
		Texts.Add(Text);
		
		If ThereIsConsolidatedLotReferenceControl Then
			
			// Surplus batches to be unlocked, available for reservation on an empty batch.
			Text =
				"SELECT
				|	NestedQuery.Products AS Products,
				|	NestedQuery.Characteristic AS Characteristic,
				|	NestedQuery.Warehouse AS Warehouse,
				|	NestedQuery.Purpose AS Purpose,
				|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
				|	FALSE ThereIsReserveAsReceived,
				|
				|	0 AS Ship,
				|	0 AS RequestForAvailableInventory,
				|	0 AS RequestFreeBalanceOfEverything,
				|	0 AS ShipByLotReferenceInSummary,
				|	
				|	0 AS ControlOfActualBalanceInWarehouse,
				|	0 AS ControlOfShipmentFromOwnReserve,
				|	0 AS ControlOfAvailableInventoryInWarehouse,
				|	0 AS ControlOfFreeBalanceOfEverything,
				|	CASE
				|		WHEN SUM(NestedQuery.ControlOfReservationInWarehouse) < 0 OR SUM(NestedQuery.ToUnlockBalance) < 0
				|			THEN 0
				|		WHEN SUM(NestedQuery.ToUnlockBalance) < SUM(NestedQuery.ControlOfReservationInWarehouse)
				|			THEN SUM(NestedQuery.ToUnlockBalance)
				|		ELSE SUM(NestedQuery.ControlOfReservationInWarehouse)
				|	END AS ControlOfAvailableInventoryForReservingAsItBecomesAvailable
				|FROM(
				|	SELECT
				|		Balance.Products AS Products,
				|		Balance.Characteristic AS Characteristic,
				|		Balance.Warehouse AS Warehouse,
				|		Balance.Purpose AS Purpose,
				|		Balance.OrderDocument AS ControlledLotReference,
				|		Balance.ToUnlockBalance AS ToUnlockBalance,
				|		Balance.LockedInStockBalance
				|			- Balance.ReserveAtWarehouseFromLockedBalance
				|			- Balance.ReserveUponReceiptFromLockedBalance AS ControlOfReservationInWarehouse
				|	FROM
				|		AccumulationRegister.InventoryAndDemands.Balance(,
				|			(Products, Characteristic, Warehouse, Purpose) IN(
				|				SELECT
				|					Table.Products AS Products,
				|					Table.Characteristic AS Characteristic,
				|					Table.Warehouse AS Warehouse,
				|					Table.Purpose AS Purpose
				|				FROM
				|					AnalystsInventoryAndRequirementsForSupplyControl AS Table)) AS Balance
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		Balance.Products AS Products,
				|		Balance.Characteristic AS Characteristic,
				|		Balance.Warehouse AS Warehouse,
				|		Balance.Purpose AS Purpose,
				|		Balance.OrderDocument AS ControlledLotReference,
				|		0 AS ToUnlockBalance,
				|		Balance.ReserveUponReceiptFromLockedBalance AS ControlOfReservationInWarehouse
				|FROM
				|	AccumulationRegister.InventoryAndDemands.Balance(,
				|		(Products, Characteristic, Warehouse, Purpose, OrderDocument) IN(
				|			SELECT
				|				Table.Products AS Products,
				|				Table.Characteristic AS Characteristic,
				|				Table.Warehouse AS Warehouse,
				|				Table.Purpose AS Purpose,
				|				Table.OrderDocument AS OrderDocument
				|			FROM
				|				InventoryAndNeedsAffectedOrders AS Table)
				|		AND (Products, Characteristic, Warehouse, Purpose) IN(
				|			SELECT
				|				Table.Products AS Products,
				|				Table.Characteristic AS Characteristic,
				|				Table.Warehouse AS Warehouse,
				|				Table.Purpose AS Purpose
				|			FROM
				|				AnalystsInventoryAndRequirementsForSupplyControl AS Table)) AS Balance) AS NestedQuery
				|GROUP BY
				|	NestedQuery.Products,
				|	NestedQuery.Characteristic,
				|	NestedQuery.Warehouse,
				|	NestedQuery.ControlledLotReference,
				|	NestedQuery.Purpose
				|HAVING
				|	SUM(NestedQuery.ControlOfReservationInWarehouse) > 0";
			Texts.Add(Text);
			
		EndIf;
		
		TextOfSet = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf;
	
	QueryText =
		"SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose,
		|	Set.ControlledLotReference AS ControlledLotReference,
		|	&ControlBalanceOfGoodsToBeReservedUponReceipt
		|		AND MAX(Set.ThereIsReserveAsReceived) AS NeedControlOfFreeBalanceOfEverything,
		|	SUM(Set.Ship) AS Ship,
		|	SUM(Set.RequestForAvailableInventory) AS RequestForAvailableInventory,
		|	SUM(Set.RequestFreeBalanceOfEverything) AS RequestFreeBalanceOfEverything,
		|	SUM(Set.ControlOfActualBalanceInWarehouse) AS ControlOfActualBalanceInWarehouse,
		|	SUM(Set.ControlOfAvailableInventoryInWarehouse) AS ControlOfAvailableInventoryInWarehouse,
		|	SUM(Set.ControlOfFreeBalanceOfEverything) AS ControlOfFreeBalanceOfEverything,
		|	CASE
		|		WHEN SUM(Set.ControlOfActualBalanceInWarehouse) > 0
		|			THEN 0
		|		WHEN -SUM(Set.ControlOfActualBalanceInWarehouse) > SUM(Set.Ship)
		|			THEN SUM(Set.Ship)
		|		ELSE -SUM(Set.ControlOfActualBalanceInWarehouse)
		|	END AS ThereIsNotEnoughActualBalanceInStockToShip,
		|	CASE
		|		WHEN SUM(Set.ControlOfActualBalanceInWarehouse) > 0
		|			THEN 0
		|		WHEN -SUM(Set.ControlOfActualBalanceInWarehouse) > SUM(Set.RequestForAvailableInventory)
		|			THEN SUM(Set.RequestForAvailableInventory)
		|		ELSE -SUM(Set.ControlOfActualBalanceInWarehouse)
		|	END AS ThereIsNotEnoughActualBalanceInWarehouse,
		|	CASE
		|		WHEN SUM(Set.ControlOfShipmentFromOwnReserve) > 0
		|			THEN 0
		|		WHEN -SUM(Set.ControlOfShipmentFromOwnReserve) > SUM(Set.Ship)
		|			THEN SUM(Set.Ship)
		|		ELSE -SUM(Set.ControlOfShipmentFromOwnReserve)
		|	END AS ThereIsNotEnoughFreeBalanceInWarehouseToShip,
		|	CASE
		|		WHEN SUM(Set.ControlOfAvailableInventoryInWarehouse) > 0
		|			THEN 0
		|		WHEN -SUM(Set.ControlOfAvailableInventoryInWarehouse) > SUM(Set.RequestForAvailableInventory)
		|			THEN SUM(Set.RequestForAvailableInventory)
		|		ELSE -SUM(Set.ControlOfAvailableInventoryInWarehouse)
		|	END AS ThereIsNotEnoughFreeBalanceInWarehouse,
		|	CASE
		|		WHEN SUM(Set.ControlOfFreeBalanceOfEverything) > 0
		|			THEN 0
		|		WHEN -SUM(Set.ControlOfFreeBalanceOfEverything) > SUM(Set.RequestFreeBalanceOfEverything)
		|			THEN SUM(Set.RequestFreeBalanceOfEverything)
		|		ELSE -SUM(Set.ControlOfFreeBalanceOfEverything)
		|	END AS ThereIsNotEnoughFreeBalanceOfEverything,
		|	CASE
		|		WHEN SUM(Set.ControlOfAvailableInventoryForReservingAsItBecomesAvailable) > 0
		|			THEN 0
		|		WHEN -SUM(Set.ControlOfAvailableInventoryForReservingAsItBecomesAvailable) > SUM(Set.ShipByLotReferenceInSummary)
		|			THEN SUM(Set.ShipByLotReferenceInSummary)
		|		ELSE -SUM(Set.ControlOfAvailableInventoryForReservingAsItBecomesAvailable)
		|	END AS ThereIsNotEnoughAvailableInventoryToReserveAsNeeded
		|INTO ControlErrorsForAssuranceControl
		|FROM
		|	SetOverridable AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse,
		|	Set.Purpose,
		|	Set.ControlledLotReference
		|HAVING
		|		SUM(Set.ControlOfActualBalanceInWarehouse) < 0
		|				AND SUM(Set.Ship) > 0
		|				AND &MonitorOnlyActualBalance
		|		OR SUM(Set.ControlOfActualBalanceInWarehouse) < 0
		|				AND SUM(Set.RequestForAvailableInventory) > 0
		|				AND &MonitorOnlyActualBalance
		|		OR SUM(Set.ControlOfShipmentFromOwnReserve) < 0
		|				AND SUM(Set.Ship) > 0
		|				AND NOT &MonitorOnlyActualBalance
		|		OR SUM(Set.ControlOfAvailableInventoryInWarehouse) < 0
		|				AND SUM(Set.RequestForAvailableInventory) > 0
		|				AND NOT &MonitorOnlyActualBalance
		|		OR SUM(Set.ControlOfFreeBalanceOfEverything) < 0
		|				AND SUM(Set.RequestFreeBalanceOfEverything) > 0
		|				AND MAX(Set.ThereIsReserveAsReceived)
		|				AND NOT &MonitorOnlyActualBalance
		|				AND &ControlBalanceOfGoodsToBeReservedUponReceipt
		|		OR SUM(Set.ControlOfAvailableInventoryForReservingAsItBecomesAvailable) < 0
		|				AND SUM(Set.ShipByLotReferenceInSummary) > 0
		|				AND NOT &MonitorOnlyActualBalance";
	
	QueryText = StrReplace(QueryText, "SetOverridable", StrTemplate("(%1)", TextOfSet));
	QueryTexts.Add(QueryText, "ControlErrorsForAssuranceControl");
	
	#EndRegion
	
	#Region EnsuringControlResults
	
	QueryText =
		"SELECT
		|	ControlErrors.Products AS Products,
		|	ControlErrors.Characteristic AS Characteristic,
		|	ControlErrors.Warehouse AS Warehouse,
		|	ControlErrors.Purpose AS Purpose,
		|	ControlErrors.ControlledLotReference AS ControlledLotReference,
		|	ControlErrors.NeedControlOfFreeBalanceOfEverything AS NeedControlOfFreeBalanceOfEverything,
		|	&MonitorOnlyActualBalance AS MonitorOnlyActualBalance,
		|	CAST(ControlErrors.Products AS Catalog.Products).UnitOfMeasure AS UnitOfMeasure,
		|	
		// Competing controls, the message is issued by a large amount.
		|	CASE
		|		WHEN ControlErrors.ThereIsNotEnoughActualBalanceInStockToShip > ControlErrors.ThereIsNotEnoughActualBalanceInWarehouse
		|			THEN ControlErrors.ThereIsNotEnoughActualBalanceInStockToShip
		|		ELSE ControlErrors.ThereIsNotEnoughActualBalanceInWarehouse
		|	END AS QuantityActualBalance,
		|	
		// Competing controls, the message is issued by a large amount.
		|	CASE
		|		WHEN ControlErrors.ThereIsNotEnoughFreeBalanceInWarehouseToShip > ControlErrors.ThereIsNotEnoughFreeBalanceInWarehouse
		|				AND ControlErrors.ThereIsNotEnoughFreeBalanceInWarehouseToShip > ControlErrors.ThereIsNotEnoughAvailableInventoryToReserveAsNeeded
		|			THEN ControlErrors.ThereIsNotEnoughFreeBalanceInWarehouseToShip
		|		WHEN ControlErrors.ThereIsNotEnoughFreeBalanceInWarehouse > ControlErrors.ThereIsNotEnoughAvailableInventoryToReserveAsNeeded
		|			THEN ControlErrors.ThereIsNotEnoughFreeBalanceInWarehouse
		|		ELSE ControlErrors.ThereIsNotEnoughAvailableInventoryToReserveAsNeeded
		|	END AS QuantityAvailableInventory,
		|	
		|	ControlErrors.ThereIsNotEnoughFreeBalanceOfEverything AS QuantityFreeBalanceTotal
		|FROM
		|	ControlErrorsForAssuranceControl AS ControlErrors";
	QueryTexts.Add(QueryText, "EnsuringControlResults");
	
	#EndRegion
	
	DocumentType = TypeOf(Document.Ref);
	
	ThisDocumentIsException =
		DocumentType = Type("DocumentRef.ReturnOfGoodsFromCustomer")
			Or DocumentType = Type("DocumentRef.RequestForGoodsQualityControl")
			Or DocumentType = Type("DocumentRef.SaleAdjustment")
			Or DocumentType = Type("DocumentRef.ProductionStage2_2")
					And ValueIsFilled(Common.ObjectAttributeValue(Document.Ref, "Partner"))
			Or DocumentType = Type("DocumentRef.GoodsReceiptFromCustomer")
			Or DocumentType = Type("DocumentRef.ReceiptOfGoodsFromCustodian")
				And Not Document.BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5;
		
	If Not Query.Parameters.Property("DimensionalTypesOfUnits") Then
		Query.SetParameter("DimensionalTypesOfUnits",
			Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	EndIf;
	
	#Region ProvisionResultsOfControlOfExcessOfSeparateProvision
	
	ControlExcessOfSeparateProvision = Not ThisDocumentIsException;
	
	If ControlExcessOfSeparateProvision Then
		
		QueryText =
			"SELECT
			|	MovementChanges.Products AS Products,
			|	MovementChanges.Characteristic AS Characteristic,
			|	MovementChanges.Warehouse AS Warehouse,
			|	MovementChanges.Purpose AS Purpose,
			|	MAX(MovementChanges.InStockReceipt > 0) AS ThisIsIncreaseInParish
			|INTO AnalyticsForMonitoringExcessOfSeparateCollateral
			|FROM
			|	InventoryAndDemandsUpdate AS MovementChanges
			|		
			|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpCharacteristic
			|		ON SettingUpCharacteristic.Warehouse          = MovementChanges.Warehouse
			|		 AND SettingUpCharacteristic.Products   = MovementChanges.Products
			|		 AND SettingUpCharacteristic.Characteristic = MovementChanges.Characteristic
			|		
			|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpProducts
			|		ON SettingUpProducts.Warehouse        = MovementChanges.Warehouse
			|		 AND SettingUpProducts.Products = MovementChanges.Products
			|		 AND SettingUpProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		
			|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpWarehouse
			|		ON SettingUpWarehouse.Warehouse          = MovementChanges.Warehouse
			|		 AND SettingUpWarehouse.Products   = VALUE(Catalog.Products.EmptyRef)
			|		 AND SettingUpWarehouse.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		
			|WHERE
			|	MovementChanges.ControlExcessOfSeparateProvision
			|		AND (ISNULL(SettingUpCharacteristic.AvailableStockControl,
			|				ISNULL(SettingUpProducts.AvailableStockControl,
			|					SettingUpWarehouse.AvailableStockControl))
			|			OR CAST(MovementChanges.Products AS Catalog.Products).ItemsType
			|					= VALUE(Enum.ItemsTypes.Work_5))
			|GROUP BY
			|	MovementChanges.Products,
			|	MovementChanges.Characteristic,
			|	MovementChanges.Warehouse,
			|	MovementChanges.Purpose
			|HAVING
			|	SUM(MovementChanges.InStockReceipt) > 0
			|		OR SUM(MovementChanges.Received_1) > 0
			|		OR NOT &MonitorConfirmedReceiptSchedule
			|			AND SUM(MovementChanges.Ordered) > 0
			|		OR SUM(MovementChanges.InStockExpense
			|					+ MovementChanges.ReserveAtWarehouse
			|					+ MovementChanges.ReserveAsReceived
			|					+ MovementChanges.ReserveAtWarehouseFromLocked
			|					+ MovementChanges.ReserveUponReceiptFromLocked
			|					+ MovementChanges.SnoozeReservation
			|					+ MovementChanges.ToSupply) < 0
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose";
		QueryTexts.Add(QueryText, "AnalyticsForMonitoringExcessOfSeparateCollateral");
		
		QueryText =
			"SELECT
			|	Balance.Products AS Products,
			|	Balance.Characteristic AS Characteristic,
			|	Balance.Warehouse AS Warehouse,
			|	Balance.Purpose AS Purpose,
			|	Balance.InStockBalance AS InStockBalance,
			|	CASE
			|		WHEN &MonitorConfirmedReceiptSchedule
			|			THEN Balance.Received_1Balance
			|		ELSE Balance.OrderedBalance
			|	END AS OrderedBalance,
			|	Balance.ReserveAtWarehouseBalance
			|		+ Balance.ReserveAsReceivedBalance
			|		+ Balance.ReserveAtWarehouseFromLockedBalance
			|		+ Balance.ReserveUponReceiptFromLockedBalance
			|		+ Balance.SnoozeReservationBalance
			|		+ Balance.ToSupplyBalance AS AllNeedsBalance
			|INTO StocksAndRequirementsForControlOfSeparateProvision
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(,
			|		(Products, Characteristic, Warehouse, Purpose) IN(
			|			SELECT
			|				Analysts.Products AS Products,
			|				Analysts.Characteristic AS Characteristic,
			|				Analysts.Warehouse AS Warehouse,
			|				Analysts.Purpose AS Purpose
			|			FROM
			|				AnalyticsForMonitoringExcessOfSeparateCollateral AS Analysts)) AS Balance
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose";
		QueryTexts.Add(QueryText, "StocksAndRequirementsForControlOfSeparateProvision");
		
		QueryText =
			"SELECT
			|	Balance.Products AS Products,
			|	Balance.Characteristic AS Characteristic,
			|	Balance.Warehouse AS Warehouse,
			|	Balance.Purpose AS Purpose,
			|	CAST(Balance.Products AS Catalog.Products).UnitOfMeasure AS UnitOfMeasure,
			|	CASE
			|		WHEN Analysts.ThisIsIncreaseInParish
			|				AND Balance.InStockBalance - Balance.AllNeedsBalance
			|					> CASE
			|						WHEN NOT CAST(Balance.Products AS Catalog.Products).UnitOfMeasure.MeasuredValueType
			|									IN (&DimensionalTypesOfUnits)
			|							THEN 0
			|						ELSE Balance.AllNeedsBalance * AllowableVariance.Value / 100
			|					END
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS MistakeOfHavingMoreNeeds,
			|	Balance.InStockBalance - Balance.AllNeedsBalance AS MagnitudeOfAvailabilityIsGreaterThanNeed,
			|	Balance.InStockBalance + Balance.OrderedBalance - Balance.AllNeedsBalance AS OrderValueIsLessThanZero
			|FROM
			|	StocksAndRequirementsForControlOfSeparateProvision AS Balance
			|		
			|		INNER JOIN AnalyticsForMonitoringExcessOfSeparateCollateral AS Analysts
			|		ON Analysts.Products = Balance.Products
			|		 AND Analysts.Characteristic = Balance.Characteristic
			|		 AND Analysts.Warehouse = Balance.Warehouse
			|		 AND Analysts.Purpose = Balance.Purpose
			|		
			|		LEFT JOIN Constant.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving AS AllowableVariance
			|		ON TRUE
			|WHERE
			|	Balance.InStockBalance + Balance.OrderedBalance - Balance.AllNeedsBalance
			|		> CASE
			|			WHEN NOT CAST(Balance.Products AS Catalog.Products).UnitOfMeasure.MeasuredValueType
			|						IN (&DimensionalTypesOfUnits)
			|				THEN 0
			|			ELSE
			|				Balance.AllNeedsBalance * AllowableVariance.Value / 100
			|		END";
		QueryTexts.Add(QueryText, "ProvisionResultsOfControlOfExcessOfSeparateProvision");
		
	EndIf;
	
	#EndRegion
	
	#Region SupplyResultsOfInventoryControlOfControlledLotReferenceInWarehouse
	
	If ThereIsQualityControl Then
		
		QueryText =
			"SELECT
			|	MovementChanges.Products AS Products,
			|	MovementChanges.Characteristic AS Characteristic,
			|	MovementChanges.Warehouse AS Warehouse,
			|	MovementChanges.Purpose AS Purpose,
			|	MovementChanges.OrderDocument AS OrderDocument,
			|	SUM(MovementChanges.LockedInStockExpense) AS DecreaseInAvailabilityByDocument
			|INTO AnalyticsToControlInventoryOfControlledLotReferenceInWarehouse
			|FROM
			|	InventoryAndDemandsUpdate AS MovementChanges
			|		
			|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpCharacteristic
			|		ON SettingUpCharacteristic.Warehouse          = MovementChanges.Warehouse
			|		 AND SettingUpCharacteristic.Products   = MovementChanges.Products
			|		 AND SettingUpCharacteristic.Characteristic = MovementChanges.Characteristic
			|		
			|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpProducts
			|		ON SettingUpProducts.Warehouse        = MovementChanges.Warehouse
			|		 AND SettingUpProducts.Products = MovementChanges.Products
			|		 AND SettingUpProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		
			|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpWarehouse
			|		ON SettingUpWarehouse.Warehouse          = MovementChanges.Warehouse
			|		 AND SettingUpWarehouse.Products   = VALUE(Catalog.Products.EmptyRef)
			|		 AND SettingUpWarehouse.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		
			|WHERE
			|	ISNULL(SettingUpCharacteristic.AvailableStockControl,
			|			ISNULL(SettingUpProducts.AvailableStockControl,
			|				SettingUpWarehouse.AvailableStockControl))
			|		AND MovementChanges.LockedInStockExpense <> 0
			|GROUP BY
			|	MovementChanges.Products,
			|	MovementChanges.Characteristic,
			|	MovementChanges.Warehouse,
			|	MovementChanges.Purpose,
			|	MovementChanges.OrderDocument
			|HAVING
			|	SUM(MovementChanges.LockedInStockExpense) < 0
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, OrderDocument";
		QueryTexts.Add(QueryText, "AnalyticsToControlInventoryOfControlledLotReferenceInWarehouse");
		
		QueryText =
			"SELECT
			|	Turnovers.Products AS Products,
			|	Turnovers.Characteristic AS Characteristic,
			|	Turnovers.Warehouse AS Warehouse,
			|	Turnovers.Purpose AS Purpose,
			|	Turnovers.OrderDocument AS OrderDocument,
			|	- Turnovers.LockedInStockTurnover AS AvailableLessThanZero,
			|	Turnovers.LockedInStockReceipt AS InStockReceipt
			|INTO InventoryAndRequirementsForControlOfInventoryOfControlledLotReferenceInWarehouse
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Turnovers(, , Auto,
			|		(Products, Characteristic, Warehouse, Purpose, OrderDocument) IN(
			|			SELECT
			|				Analysts.Products AS Products,
			|				Analysts.Characteristic AS Characteristic,
			|				Analysts.Warehouse AS Warehouse,
			|				Analysts.Purpose AS Purpose,
			|				Analysts.OrderDocument AS OrderDocument
			|			FROM
			|				AnalyticsToControlInventoryOfControlledLotReferenceInWarehouse AS Analysts)) AS Turnovers
			|WHERE
			|	Turnovers.LockedInStockTurnover < 0
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose";
		QueryTexts.Add(QueryText, "InventoryAndRequirementsForControlOfInventoryOfControlledLotReferenceInWarehouse");
		
		QueryText =
			"SELECT
			|	Turnovers.Products AS Products,
			|	Turnovers.Characteristic AS Characteristic,
			|	Turnovers.Warehouse AS Warehouse,
			|	Turnovers.Purpose AS Purpose,
			|	Turnovers.OrderDocument AS ControlledLotReference,
			|	CAST(Turnovers.Products AS Catalog.Products).UnitOfMeasure AS UnitOfMeasure,
			|	CASE
			|		WHEN Turnovers.AvailableLessThanZero > Analysts.DecreaseInAvailabilityByDocument
			|			THEN Analysts.DecreaseInAvailabilityByDocument
			|		ELSE Turnovers.AvailableLessThanZero
			|	END AS Count
			|FROM
			|	InventoryAndRequirementsForControlOfInventoryOfControlledLotReferenceInWarehouse AS Turnovers
			|		
			|		INNER JOIN AnalyticsToControlInventoryOfControlledLotReferenceInWarehouse AS Analysts
			|		ON Analysts.Products = Turnovers.Products
			|		 AND Analysts.Characteristic = Turnovers.Characteristic
			|		 AND Analysts.Warehouse = Turnovers.Warehouse
			|		 AND Analysts.Purpose = Turnovers.Purpose
			|		 AND Analysts.OrderDocument = Turnovers.OrderDocument
			|		
			|		LEFT JOIN Constant.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving AS AllowableVariance
			|		ON TRUE
			|WHERE
			|	Turnovers.AvailableLessThanZero >
			|	CASE
			|		WHEN NOT CAST(Turnovers.Products AS Catalog.Products).UnitOfMeasure.MeasuredValueType
			|					IN (&DimensionalTypesOfUnits)
			|			THEN 0
			|		ELSE
			|			Turnovers.InStockReceipt * AllowableVariance.Value / 100
			|	END";
		QueryTexts.Add(QueryText, "SupplyResultsOfInventoryControlOfControlledLotReferenceInWarehouse");
		
	EndIf;
	
	#EndRegion
	
EndProcedure

Procedure ReportErrorsDuring(Object, Cancel, ControlResults) Export
	
	DisableControl = SessionParameters.PostWithoutControlOfGoodsReservesUnderOrders;
	
	For Each VerificationError In ControlResults Do
		
		UnitOfMeasure = VerificationError.UnitOfMeasure;
		
		Count = VerificationError.QuantityActualBalance;
		If Count > 0 And DisableControl Or VerificationError.MonitorOnlyActualBalance Then
			
			TextPurposeCharacteristics = NStr("ru = 'Для отгрузки / резервирования товара %1, %2 на складе %3 по назначению %4 недостаточно остатка в наличии в количестве %5 %6.';
												|vi = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve the ""%1"",""%2"" goods in the quantity of %5 %6.';
												|en = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve the ""%1"",""%2"" goods in the quantity of %5 %6.'; fa = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve the ""%1"",""%2"" goods in the quantity of %5 %6.';
												|it = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve the ""%1"",""%2"" goods in the quantity of %5 %6.';
												|pl = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve the ""%1"",""%2"" goods in the quantity of %5 %6.';
												|tr = '%3 ambarındaki %1 , %2 ürünlerinin %4 atamasına ilişkin sevkiyatı/rezervasyonu için %5%6 miktarında yeterli stok bakiyesi bulunmamaktadır.'");
			TextAssignment = NStr("ru = 'Для отгрузки / резервирования обособленного товара %1 на складе %2 по назначению %3 недостаточно остатка в наличии количестве %4 %5';
									|vi = 'Insufficient inventory available at the ""%2"" warehouse by the ""%3"" assignment to ship/reserve the ""%1"" assigned goods, in the quantity of %4 %5';
									|en = 'Insufficient inventory available at the ""%2"" warehouse by the ""%3"" assignment to ship/reserve the ""%1"" assigned goods, in the quantity of %4 %5'; fa = 'Insufficient inventory available at the ""%2"" warehouse by the ""%3"" assignment to ship/reserve the ""%1"" assigned goods, in the quantity of %4 %5';
									|it = 'Insufficient inventory available at the ""%2"" warehouse by the ""%3"" assignment to ship/reserve the ""%1"" assigned goods, in the quantity of %4 %5';
									|pl = 'Insufficient inventory available at the ""%2"" warehouse by the ""%3"" assignment to ship/reserve the ""%1"" assigned goods, in the quantity of %4 %5';
									|tr = '%2 ambarındaki %3 atamasına ilişkin %1 özel ürününün sevkiyatı/rezervasyonu için %4%5miktarında yeterli stok bakiyesi bulunmamaktadır.'");
			UnassignedTextCharacteristic = NStr("ru = 'Для отгрузки / резервирования необособленного товара %1, %2 на складе %3 недостаточно остатка в наличии в количестве %4 %5.';
												|vi = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve the ""%1"",""%2"" non-assigned goods in the quantity of %4 %5.';
												|en = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve the ""%1"",""%2"" non-assigned goods in the quantity of %4 %5.'; fa = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve the ""%1"",""%2"" non-assigned goods in the quantity of %4 %5.';
												|it = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve the ""%1"",""%2"" non-assigned goods in the quantity of %4 %5.';
												|pl = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve the ""%1"",""%2"" non-assigned goods in the quantity of %4 %5.';
												|tr = '%3 ambarındaki %1,%2 atanmamış ürünlerinin sevkiyatı/rezervasyonu için %4%5 miktarında yeterli stok bakiyesi bulunmamaktadır.'");
			UnassignedText = NStr("ru = 'Для отгрузки / резервирования необособленного товара %1 на складе %2 недостаточно остатка в наличии в количестве %3 %4';
									|vi = 'Insufficient inventory available at the ""%2"" warehouse to ship/reserve the ""%1"" non-assigned goods in the quantity of %3 %4';
									|en = 'Insufficient inventory available at the ""%2"" warehouse to ship/reserve the ""%1"" non-assigned goods in the quantity of %3 %4'; fa = 'Insufficient inventory available at the ""%2"" warehouse to ship/reserve the ""%1"" non-assigned goods in the quantity of %3 %4';
									|it = 'Insufficient inventory available at the ""%2"" warehouse to ship/reserve the ""%1"" non-assigned goods in the quantity of %3 %4';
									|pl = 'Insufficient inventory available at the ""%2"" warehouse to ship/reserve the ""%1"" non-assigned goods in the quantity of %3 %4';
									|tr = '%2 ambarındaki %1 atanmamış ürününün sevkiyatı/rezervasyonu için%3%4 miktarında yeterli stok bakiyesi bulunmamaktadır.'");
			
			TextAssignmentCharacteristicLotReference = NStr("ru = 'Для отгрузки / резервирования товара %1, %2 контролируемой партии %3 на складе %4 по назначению %5 недостаточно остатка в наличии в количестве %6 %7.';
															|vi = 'Insufficient inventory available at the ""%4"" warehouse by the ""%5"" assignment to ship/reserve the ""%1"",""%2"" goods of the ""%3"" controlled lot in the quantity of %6 %7.';
															|en = 'Insufficient inventory available at the ""%4"" warehouse by the ""%5"" assignment to ship/reserve the ""%1"",""%2"" goods of the ""%3"" controlled lot in the quantity of %6 %7.'; fa = 'Insufficient inventory available at the ""%4"" warehouse by the ""%5"" assignment to ship/reserve the ""%1"",""%2"" goods of the ""%3"" controlled lot in the quantity of %6 %7.';
															|it = 'Insufficient inventory available at the ""%4"" warehouse by the ""%5"" assignment to ship/reserve the ""%1"",""%2"" goods of the ""%3"" controlled lot in the quantity of %6 %7.';
															|pl = 'Insufficient inventory available at the ""%4"" warehouse by the ""%5"" assignment to ship/reserve the ""%1"",""%2"" goods of the ""%3"" controlled lot in the quantity of %6 %7.';
															|tr = '%4 ambarındaki, %3 kontrole tabi lotuna ait %1,%2 ürünlerinin %5 atamasına ilişkin sevkiyatı/rezervasyonu için %6 %7miktarında yeterli stok bakiyesi bulunmamaktadır.'");
			TextAssignmentLotReference = NStr("ru = 'Для отгрузки / резервирования обособленного товара %1 контролируемой партии %2 на складе %3 по назначению %4 недостаточно остатка в наличии количестве %5 %6';
												|vi = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve the ""%1"" assigned goods of the ""%2"" controlled lot, in the quantity of %5 %6';
												|en = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve the ""%1"" assigned goods of the ""%2"" controlled lot, in the quantity of %5 %6'; fa = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve the ""%1"" assigned goods of the ""%2"" controlled lot, in the quantity of %5 %6';
												|it = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve the ""%1"" assigned goods of the ""%2"" controlled lot, in the quantity of %5 %6';
												|pl = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve the ""%1"" assigned goods of the ""%2"" controlled lot, in the quantity of %5 %6';
												|tr = '%3 ambarındaki, %2 kontrole tabi lotu olan %1 özel ürününün %4 atamasına ilişkin sevkiyatı/rezervasyonu için %5%6 miktarında yeterli stok bakiyesi bulunmamaktadır.'");
			TextWithoutAssignmentCharacteristicLotReference = NStr("ru = 'Для отгрузки / резервирования необособленного товара %1, %2 контролируемой партии %3 на складе %4 недостаточно остатка в наличии в количестве %5 %6.';
																	|vi = 'Insufficient inventory available at the ""%4"" warehouse to ship/reserve the ""%1"",""%2"" non-assigned goods of the ""%3"" controlled lot in the quantity of %5 %6.';
																	|en = 'Insufficient inventory available at the ""%4"" warehouse to ship/reserve the ""%1"",""%2"" non-assigned goods of the ""%3"" controlled lot in the quantity of %5 %6.'; fa = 'Insufficient inventory available at the ""%4"" warehouse to ship/reserve the ""%1"",""%2"" non-assigned goods of the ""%3"" controlled lot in the quantity of %5 %6.';
																	|it = 'Insufficient inventory available at the ""%4"" warehouse to ship/reserve the ""%1"",""%2"" non-assigned goods of the ""%3"" controlled lot in the quantity of %5 %6.';
																	|pl = 'Insufficient inventory available at the ""%4"" warehouse to ship/reserve the ""%1"",""%2"" non-assigned goods of the ""%3"" controlled lot in the quantity of %5 %6.';
																	|tr = '%4 ambarındaki, %3 kontrole tabi lotu olan %1,%2 atanmamış ürünlerinin sevkiyatı/rezervasyonu için %5 %6miktarında yeterli stok bakiyesi bulunmamaktadır.'");
			TextWithNoDestinationLotReference = NStr("ru = 'Для отгрузки / резервирования необособленного товара %1 контролируемой партии %2 на складе %3 недостаточно остатка в наличии в количестве %4 %5';
													|vi = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve the ""%1"" non-assigned goods of the ""%2"" controlled lot in the quantity of %4 %5.';
													|en = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve the ""%1"" non-assigned goods of the ""%2"" controlled lot in the quantity of %4 %5.'; fa = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve the ""%1"" non-assigned goods of the ""%2"" controlled lot in the quantity of %4 %5.';
													|it = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve the ""%1"" non-assigned goods of the ""%2"" controlled lot in the quantity of %4 %5.';
													|pl = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve the ""%1"" non-assigned goods of the ""%2"" controlled lot in the quantity of %4 %5.';
													|tr = '%3 ambarındaki,%2 kontrole tabi lotu olan %1 atanmamış ürününün sevkiyatı/rezervasyonu için %4 %5 miktarında yeterli mevcut stok bakiyesi bulunmamaktadır.'");
			
			If ValueIsFilled(VerificationError.Purpose) Then
				
				If ValueIsFilled(VerificationError.Characteristic) Then
					
					If ValueIsFilled(VerificationError.ControlledLotReference) Then
						MessageText = StrTemplate(TextAssignmentCharacteristicLotReference,
							VerificationError.Products,
							VerificationError.Characteristic,
							VerificationError.ControlledLotReference,
							VerificationError.Warehouse,
							VerificationError.Purpose,
							Count,
							UnitOfMeasure);
					Else
						MessageText = StrTemplate(TextPurposeCharacteristics,
							VerificationError.Products,
							VerificationError.Characteristic,
							VerificationError.Warehouse,
							VerificationError.Purpose,
							Count,
							UnitOfMeasure);
					EndIf;
					
				Else
					
					If ValueIsFilled(VerificationError.ControlledLotReference) Then
						MessageText = StrTemplate(TextAssignmentLotReference,
							VerificationError.Products,
							VerificationError.ControlledLotReference,
							VerificationError.Warehouse,
							VerificationError.Purpose,
							Count,
							UnitOfMeasure);
					Else
						MessageText = StrTemplate(TextAssignment,
							VerificationError.Products,
							VerificationError.Warehouse,
							VerificationError.Purpose,
							Count,
							UnitOfMeasure);
					EndIf;
					
				EndIf;
				
			Else
				
				If ValueIsFilled(VerificationError.Characteristic) Then
					
					If ValueIsFilled(VerificationError.ControlledLotReference) Then
						MessageText = StrTemplate(TextWithoutAssignmentCharacteristicLotReference,
							VerificationError.Products,
							VerificationError.Characteristic,
							VerificationError.ControlledLotReference,
							VerificationError.Warehouse,
							Count,
							UnitOfMeasure);
					Else
						MessageText = StrTemplate(UnassignedTextCharacteristic,
							VerificationError.Products,
							VerificationError.Characteristic,
							VerificationError.Warehouse,
							Count,
							UnitOfMeasure);
					EndIf;
					
				Else
					
					If ValueIsFilled(VerificationError.ControlledLotReference) Then
						MessageText = StrTemplate(TextWithNoDestinationLotReference,
							VerificationError.Products,
							VerificationError.ControlledLotReference,
							VerificationError.Warehouse,
							Count,
							UnitOfMeasure);
					Else
						MessageText = StrTemplate(UnassignedText,
							VerificationError.Products,
							VerificationError.Warehouse,
							Count,
							UnitOfMeasure);
					EndIf;
					
				EndIf;
				
			EndIf;
			
			Common.MessageToUser(MessageText, Object, Undefined, Undefined, Cancel);
			
		EndIf;
		
		If VerificationError.MonitorOnlyActualBalance Then
			Continue;
		EndIf;
		
		Count = VerificationError.QuantityAvailableInventory;
		If Count > 0 Then
			
			TextPurposeCharacteristics = NStr("ru = 'Для отгрузки / резервирования товара %1, %2 на складе %3 по назначению %4 недостаточно свободного остатка в количестве %5 %6.';
												|vi = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve goods ""%1"",""%2"" in the amount of %5 %6.';
												|en = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve goods ""%1"",""%2"" in the amount of %5 %6.'; fa = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve goods ""%1"",""%2"" in the amount of %5 %6.';
												|it = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve goods ""%1"",""%2"" in the amount of %5 %6.';
												|pl = 'Insufficient inventory available at the ""%3"" warehouse by the ""%4"" assignment to ship/reserve goods ""%1"",""%2"" in the amount of %5 %6.';
												|tr = '%3 ambarındaki %1, %2 ürünlerinin %4 atamasına ilişkin sevkiyatı/rezervasyonu için %5 %6 miktarında yeterli serbest stok bakiyesi bulunmamaktadır.'");
			TextAssignment = NStr("ru = 'Для отгрузки / резервирования обособленного товара %1 на складе %2 по назначению %3 недостаточно свободного остатка в количестве %4 %5';
									|vi = 'Insufficient inventory available at the ""%2"" warehouse by the ""%3"" assignment to ship/reserve assigned goods ""%1"", in the amount of %4 %5';
									|en = 'Insufficient inventory available at the ""%2"" warehouse by the ""%3"" assignment to ship/reserve assigned goods ""%1"", in the amount of %4 %5'; fa = 'Insufficient inventory available at the ""%2"" warehouse by the ""%3"" assignment to ship/reserve assigned goods ""%1"", in the amount of %4 %5';
									|it = 'Insufficient inventory available at the ""%2"" warehouse by the ""%3"" assignment to ship/reserve assigned goods ""%1"", in the amount of %4 %5';
									|pl = 'Insufficient inventory available at the ""%2"" warehouse by the ""%3"" assignment to ship/reserve assigned goods ""%1"", in the amount of %4 %5';
									|tr = '%2 ambarındaki %1 özel ürününün %3 atamasına ilişkin sevkiyatı/rezervasyonu için %4 %5miktarında yeterli serbest stok bakiyesi bulunmamaktadır.'");
			UnassignedTextCharacteristic = NStr("ru = 'Для отгрузки / резервирования необособленного товара %1, %2 на складе %3 недостаточно свободного остатка в количестве %4 %5.';
												|vi = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve non-assigned goods ""%1"", ""%2"" in the amount of %4 %5.';
												|en = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve non-assigned goods ""%1"", ""%2"" in the amount of %4 %5.'; fa = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve non-assigned goods ""%1"", ""%2"" in the amount of %4 %5.';
												|it = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve non-assigned goods ""%1"", ""%2"" in the amount of %4 %5.';
												|pl = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve non-assigned goods ""%1"", ""%2"" in the amount of %4 %5.';
												|tr = '%3 ambarındaki %1, %2 atanmamış ürünlerinin sevkiyatı/rezervasyonu için%4 %5miktarında yeterli serbest stok bakiyesi bulunmamaktadır.'");
			UnassignedText = NStr("ru = 'Для отгрузки / резервирования необособленного товара %1 на складе %2 недостаточно свободного остатка в количестве %3 %4';
									|vi = 'Insufficient inventory available at the ""%2"" warehouse to ship/reserve non-assigned goods ""%1"" in the amount of %3 %4';
									|en = 'Insufficient inventory available at the ""%2"" warehouse to ship/reserve non-assigned goods ""%1"" in the amount of %3 %4'; fa = 'Insufficient inventory available at the ""%2"" warehouse to ship/reserve non-assigned goods ""%1"" in the amount of %3 %4';
									|it = 'Insufficient inventory available at the ""%2"" warehouse to ship/reserve non-assigned goods ""%1"" in the amount of %3 %4';
									|pl = 'Insufficient inventory available at the ""%2"" warehouse to ship/reserve non-assigned goods ""%1"" in the amount of %3 %4';
									|tr = '%2 ambarındaki %1 atanmamış ürününün sevkiyatı/rezervasyonu için %3 %4miktarında yeterli serbest stok bakiyesi bulunmamaktadır.'");
			
			TextAssignmentCharacteristicLotReference = NStr("ru = 'Для отгрузки / резервирования товара %1, %2 контролируемой партии %3 на складе %4 по назначению %5 недостаточно свободного остатка в количестве %6 %7.';
															|vi = 'Insufficient inventory available at the ""%4"" warehouse by the ""%5"" assignment to ship/reserve goods ""%1"",""%2"" of the ""%3"" controlled lot in the amount of %6 %7.';
															|en = 'Insufficient inventory available at the ""%4"" warehouse by the ""%5"" assignment to ship/reserve goods ""%1"",""%2"" of the ""%3"" controlled lot in the amount of %6 %7.'; fa = 'Insufficient inventory available at the ""%4"" warehouse by the ""%5"" assignment to ship/reserve goods ""%1"",""%2"" of the ""%3"" controlled lot in the amount of %6 %7.';
															|it = 'Insufficient inventory available at the ""%4"" warehouse by the ""%5"" assignment to ship/reserve goods ""%1"",""%2"" of the ""%3"" controlled lot in the amount of %6 %7.';
															|pl = 'Insufficient inventory available at the ""%4"" warehouse by the ""%5"" assignment to ship/reserve goods ""%1"",""%2"" of the ""%3"" controlled lot in the amount of %6 %7.';
															|tr = '%4 ambarındaki, %3 kontrole tabi lotuna ait %1, %2 ürünlerinin %5 atamasına ilişkin sevkiyatı/rezervasyonu için %6 %7 miktarında yeterli serbest stok bakiyesi bulunmamaktadır.'");
			TextAssignmentLotReference = NStr("ru = 'Для отгрузки / резервирования обособленного товара %1 контролируемой партии %2 на складе %3 по назначению %4 недостаточно свободного остатка количестве %5 %6';
												|vi = 'Insufficient inventory available at warehouse ""%3"" by the ""%4"" assignment to ship/reserve assigned goods ""%1"" of the ""%2"" controlled lot, in the amount of %5 %6';
												|en = 'Insufficient inventory available at warehouse ""%3"" by the ""%4"" assignment to ship/reserve assigned goods ""%1"" of the ""%2"" controlled lot, in the amount of %5 %6'; fa = 'Insufficient inventory available at warehouse ""%3"" by the ""%4"" assignment to ship/reserve assigned goods ""%1"" of the ""%2"" controlled lot, in the amount of %5 %6';
												|it = 'Insufficient inventory available at warehouse ""%3"" by the ""%4"" assignment to ship/reserve assigned goods ""%1"" of the ""%2"" controlled lot, in the amount of %5 %6';
												|pl = 'Insufficient inventory available at warehouse ""%3"" by the ""%4"" assignment to ship/reserve assigned goods ""%1"" of the ""%2"" controlled lot, in the amount of %5 %6';
												|tr = '%3 ambarındaki, %2 kontrole tabi lotu olan %1 özel ürününün %4 atamasına ilişkin sevkiyatı/rezervasyonu için %5 %6miktarında yeterli serbest stok bakiyesi bulunmamaktadır.'");
			TextWithoutAssignmentCharacteristicLotReference = NStr("ru = 'Для отгрузки / резервирования необособленного товара %1, %2 контролируемой партии %3 на складе %4 недостаточно свободного остатка в количестве %5 %6.';
																	|vi = 'Insufficient inventory available at the ""%4"" warehouse to ship/reserve non-assigned goods ""%1"",""%2"" of the ""%3"" controlled lot in the amount of %5 %6.';
																	|en = 'Insufficient inventory available at the ""%4"" warehouse to ship/reserve non-assigned goods ""%1"",""%2"" of the ""%3"" controlled lot in the amount of %5 %6.'; fa = 'Insufficient inventory available at the ""%4"" warehouse to ship/reserve non-assigned goods ""%1"",""%2"" of the ""%3"" controlled lot in the amount of %5 %6.';
																	|it = 'Insufficient inventory available at the ""%4"" warehouse to ship/reserve non-assigned goods ""%1"",""%2"" of the ""%3"" controlled lot in the amount of %5 %6.';
																	|pl = 'Insufficient inventory available at the ""%4"" warehouse to ship/reserve non-assigned goods ""%1"",""%2"" of the ""%3"" controlled lot in the amount of %5 %6.';
																	|tr = '%4 ambarındaki, %3 kontrole tabi lotu olan %1, %2 atanmamış ürünlerinin sevkiyatı/rezervasyonu için %5 %6miktarında yeterli serbest stok bakiyesi bulunmamaktadır.'");
			TextWithNoDestinationLotReference = NStr("ru = 'Для отгрузки / резервирования необособленного товара %1 контролируемой партии %2 на складе %3 недостаточно свободного остатка в количестве %4 %5';
													|vi = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve non-assigned goods ""%1"" of the ""%2"" controlled lot in the amount of %4 %5';
													|en = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve non-assigned goods ""%1"" of the ""%2"" controlled lot in the amount of %4 %5'; fa = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve non-assigned goods ""%1"" of the ""%2"" controlled lot in the amount of %4 %5';
													|it = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve non-assigned goods ""%1"" of the ""%2"" controlled lot in the amount of %4 %5';
													|pl = 'Insufficient inventory available at the ""%3"" warehouse to ship/reserve non-assigned goods ""%1"" of the ""%2"" controlled lot in the amount of %4 %5';
													|tr = '%3 ambarındaki, %2kontrole tabi lotu olan %1 atanmamış ürününün sevkiyatı/rezervasyonu için %4%5 miktarında yeterli serbest stok bakiyesi bulunmamaktadır.'");
			
			If ValueIsFilled(VerificationError.Purpose) Then
				
				If ValueIsFilled(VerificationError.Characteristic) Then
					
					If ValueIsFilled(VerificationError.ControlledLotReference) Then
						MessageText = StrTemplate(TextAssignmentCharacteristicLotReference,
							VerificationError.Products,
							VerificationError.Characteristic,
							VerificationError.ControlledLotReference,
							VerificationError.Warehouse,
							VerificationError.Purpose,
							Count,
							UnitOfMeasure);
					Else
						MessageText = StrTemplate(TextPurposeCharacteristics,
							VerificationError.Products,
							VerificationError.Characteristic,
							VerificationError.Warehouse,
							VerificationError.Purpose,
							Count,
							UnitOfMeasure);
					EndIf;
					
				Else
					
					If ValueIsFilled(VerificationError.ControlledLotReference) Then
						MessageText = StrTemplate(TextAssignmentLotReference,
							VerificationError.Products,
							VerificationError.ControlledLotReference,
							VerificationError.Warehouse,
							VerificationError.Purpose,
							Count,
							UnitOfMeasure);
					Else
						MessageText = StrTemplate(TextAssignment,
							VerificationError.Products,
							VerificationError.Warehouse,
							VerificationError.Purpose,
							Count,
							UnitOfMeasure);
					EndIf;
					
				EndIf;
				
			Else
				
				If ValueIsFilled(VerificationError.Characteristic) Then
					
					If ValueIsFilled(VerificationError.ControlledLotReference) Then
						MessageText = StrTemplate(TextWithoutAssignmentCharacteristicLotReference,
							VerificationError.Products,
							VerificationError.Characteristic,
							VerificationError.ControlledLotReference,
							VerificationError.Warehouse,
							Count,
							UnitOfMeasure);
					Else
						MessageText = StrTemplate(UnassignedTextCharacteristic,
							VerificationError.Products,
							VerificationError.Characteristic,
							VerificationError.Warehouse,
							Count,
							UnitOfMeasure);
					EndIf;
					
				Else
					
					If ValueIsFilled(VerificationError.ControlledLotReference) Then
						MessageText = StrTemplate(TextWithNoDestinationLotReference,
							VerificationError.Products,
							VerificationError.ControlledLotReference,
							VerificationError.Warehouse,
							Count,
							UnitOfMeasure);
					Else
						MessageText = StrTemplate(UnassignedText,
							VerificationError.Products,
							VerificationError.Warehouse,
							Count,
							UnitOfMeasure);
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If DisableControl Then
				Common.MessageToUser(MessageText, Object, Undefined, Undefined, Undefined);
			Else
				Common.MessageToUser(MessageText, Object, Undefined, Undefined, Cancel);
			EndIf;
			
		EndIf;
		
		Count = VerificationError.QuantityFreeBalanceTotal;
		
		If VerificationError.NeedControlOfFreeBalanceOfEverything And Count > 0 Then
			
			TextPurposeCharacteristics = NStr("ru = 'Для обеспечения заказов недостаточно запасов товара %1, %2 в наличии и в ожидаемых поступлениях на склад %3 по назначению %4 в количестве %5 %6.';
												|vi = 'There are not enough ""%1"", ""%2"" items in stock and in the expected receipts to the ""%3"" warehouse by the ""%4"" assignment to fulfill the orders. Shortage: %5 %6.';
												|en = 'There are not enough ""%1"", ""%2"" items in stock and in the expected receipts to the ""%3"" warehouse by the ""%4"" assignment to fulfill the orders. Shortage: %5 %6.'; fa = 'There are not enough ""%1"", ""%2"" items in stock and in the expected receipts to the ""%3"" warehouse by the ""%4"" assignment to fulfill the orders. Shortage: %5 %6.';
												|it = 'There are not enough ""%1"", ""%2"" items in stock and in the expected receipts to the ""%3"" warehouse by the ""%4"" assignment to fulfill the orders. Shortage: %5 %6.';
												|pl = 'There are not enough ""%1"", ""%2"" items in stock and in the expected receipts to the ""%3"" warehouse by the ""%4"" assignment to fulfill the orders. Shortage: %5 %6.';
												|tr = 'Siparişlerin tedariki için stokta ve %3 ambarına beklenen girişlerde %4 atamasına göre %5%6 miktarında %1, %2 ürünlerinden yeterli stok bulunmamaktadır.'");
			TextAssignment = NStr("ru = 'Для обеспечения заказов недостаточно запасов товара %1 в наличии и в ожидаемых поступлениях на склад %2 по назначению %3 в количестве %4 %5';
									|vi = 'There are not enough ""%1"" items in stock and in the expected receipts to the ""%2"" warehouse by the ""%3"" assignment to fulfill the orders. Shortage: %4 %5';
									|en = 'There are not enough ""%1"" items in stock and in the expected receipts to the ""%2"" warehouse by the ""%3"" assignment to fulfill the orders. Shortage: %4 %5'; fa = 'There are not enough ""%1"" items in stock and in the expected receipts to the ""%2"" warehouse by the ""%3"" assignment to fulfill the orders. Shortage: %4 %5';
									|it = 'There are not enough ""%1"" items in stock and in the expected receipts to the ""%2"" warehouse by the ""%3"" assignment to fulfill the orders. Shortage: %4 %5';
									|pl = 'There are not enough ""%1"" items in stock and in the expected receipts to the ""%2"" warehouse by the ""%3"" assignment to fulfill the orders. Shortage: %4 %5';
									|tr = 'Siparişlerin tedariki için stokta ve %2 ambarına beklenen girişlerde %3 atamasına göre %4 %5miktarında %1 ürününden yeterli stok bulunmamaktadır.'");
			UnassignedTextCharacteristic = NStr("ru = 'Для обеспечения заказов недостаточно запасов товара %1, %2 в наличии и в ожидаемых поступлениях на склад %3 в количестве %4 %5.';
												|vi = 'There are not enough ""%1"", ""%2"" items in stock and in the expected receipts to the ""%3"" warehouse to fulfill the orders. Shortage: %4 %5.';
												|en = 'There are not enough ""%1"", ""%2"" items in stock and in the expected receipts to the ""%3"" warehouse to fulfill the orders. Shortage: %4 %5.'; fa = 'There are not enough ""%1"", ""%2"" items in stock and in the expected receipts to the ""%3"" warehouse to fulfill the orders. Shortage: %4 %5.';
												|it = 'There are not enough ""%1"", ""%2"" items in stock and in the expected receipts to the ""%3"" warehouse to fulfill the orders. Shortage: %4 %5.';
												|pl = 'There are not enough ""%1"", ""%2"" items in stock and in the expected receipts to the ""%3"" warehouse to fulfill the orders. Shortage: %4 %5.';
												|tr = 'Siparişlerin tedariki için stokta ve %3 ambarına beklenen girişlerde %4 %5miktarında  %1, %2 ürünlerinden yeterli stok bulunmamaktadır. '");
			UnassignedText = NStr("ru = 'Для обеспечения заказов недостаточно запасов товара %1 в наличии и в ожидаемых поступлениях на склад %2 в количестве %3 %4';
									|vi = 'There are not enough ""%1"" items in stock and in the expected receipts to the ""%2"" warehouse to fulfill the orders. Shortage: %3 %4';
									|en = 'There are not enough ""%1"" items in stock and in the expected receipts to the ""%2"" warehouse to fulfill the orders. Shortage: %3 %4'; fa = 'There are not enough ""%1"" items in stock and in the expected receipts to the ""%2"" warehouse to fulfill the orders. Shortage: %3 %4';
									|it = 'There are not enough ""%1"" items in stock and in the expected receipts to the ""%2"" warehouse to fulfill the orders. Shortage: %3 %4';
									|pl = 'There are not enough ""%1"" items in stock and in the expected receipts to the ""%2"" warehouse to fulfill the orders. Shortage: %3 %4';
									|tr = 'Siparişlerin tedariki için stokta ve %2 ambarına beklenen girişlerde %3%4 miktarında %1 ürününden yeterli stok bulunmamaktadır.'");
			
			TextAssignmentCharacteristicLotReference = NStr("ru = 'Для обеспечения заказов недостаточно запасов товара %1, %2 контролируемой партии %3 в наличии и в ожидаемых поступлениях на склад %4 по назначению %5 в количестве %6 %7.';
															|vi = 'There are not enough ""%1"", ""%2"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse by the ""%5"" assignment to fulfill the orders. Shortage: %6 %7.';
															|en = 'There are not enough ""%1"", ""%2"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse by the ""%5"" assignment to fulfill the orders. Shortage: %6 %7.'; fa = 'There are not enough ""%1"", ""%2"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse by the ""%5"" assignment to fulfill the orders. Shortage: %6 %7.';
															|it = 'There are not enough ""%1"", ""%2"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse by the ""%5"" assignment to fulfill the orders. Shortage: %6 %7.';
															|pl = 'There are not enough ""%1"", ""%2"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse by the ""%5"" assignment to fulfill the orders. Shortage: %6 %7.';
															|tr = 'Siparişlerin tedariki için stokta ve %4 ambarına beklenen girişlerde %5 atamasına göre %6 %7miktarında, %3 kontrole tabi lotuna ait %1%2 ürünlerinden yeterli stok bulunmamaktadır.'");
			TextAssignmentLotReference = NStr("ru = 'Для обеспечения заказов недостаточно запасов товара %1 контролируемой партии %2 в наличии и в ожидаемых поступлениях на склад %3 по назначению %4 в количестве %5 %6';
												|vi = 'There are not enough ""%1"" items of the ""%2"" controlled lot in stock and in the expected receipts to the ""%3"" warehouse by the ""%4"" assignment to fulfill the orders. Shortage: %5 %6';
												|en = 'There are not enough ""%1"" items of the ""%2"" controlled lot in stock and in the expected receipts to the ""%3"" warehouse by the ""%4"" assignment to fulfill the orders. Shortage: %5 %6'; fa = 'There are not enough ""%1"" items of the ""%2"" controlled lot in stock and in the expected receipts to the ""%3"" warehouse by the ""%4"" assignment to fulfill the orders. Shortage: %5 %6';
												|it = 'There are not enough ""%1"" items of the ""%2"" controlled lot in stock and in the expected receipts to the ""%3"" warehouse by the ""%4"" assignment to fulfill the orders. Shortage: %5 %6';
												|pl = 'There are not enough ""%1"" items of the ""%2"" controlled lot in stock and in the expected receipts to the ""%3"" warehouse by the ""%4"" assignment to fulfill the orders. Shortage: %5 %6';
												|tr = 'Siparişlerin tedariki için stokta ve %3 ambarına beklenen girişlerde %4 atamasına göre %5%6 miktarında kontrole tabi lotu %2 olan %1 ürününden yeterli stok bulunmamaktadır.'");
			TextWithoutAssignmentCharacteristicLotReference = NStr("ru = 'Для обеспечения заказов недостаточно запасов товара %1, %2 контролируемой партии %3 в наличии и в ожидаемых поступлениях на склад %4 в количестве %5 %6.';
																	|vi = 'There are not enough ""%1"", ""%2"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse to fulfill the orders. Shortage: %5 %6.';
																	|en = 'There are not enough ""%1"", ""%2"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse to fulfill the orders. Shortage: %5 %6.'; fa = 'There are not enough ""%1"", ""%2"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse to fulfill the orders. Shortage: %5 %6.';
																	|it = 'There are not enough ""%1"", ""%2"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse to fulfill the orders. Shortage: %5 %6.';
																	|pl = 'There are not enough ""%1"", ""%2"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse to fulfill the orders. Shortage: %5 %6.';
																	|tr = 'Siparişlerin tedariki için stokta ve %4 ambarına beklenen girişlerde %5 %6 miktarında kontrole tabi lotu %3 olan %1, %2 ürününden yeterli stok bulunmamaktadır.'");
			TextWithNoDestinationLotReference = NStr("ru = 'Для обеспечения заказов недостаточно запасов товара %1 контролируемой партии %3 в наличии и в ожидаемых поступлениях на склад %4 в количестве %5 %6';
													|vi = 'There are not enough ""%1"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse to fulfill the orders. Shortage: %5 %6';
													|en = 'There are not enough ""%1"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse to fulfill the orders. Shortage: %5 %6'; fa = 'There are not enough ""%1"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse to fulfill the orders. Shortage: %5 %6';
													|it = 'There are not enough ""%1"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse to fulfill the orders. Shortage: %5 %6';
													|pl = 'There are not enough ""%1"" items of the ""%3"" controlled lot in stock and in the expected receipts to the ""%4"" warehouse to fulfill the orders. Shortage: %5 %6';
													|tr = 'Siparişlerin tedariki için stokta ve %4 ambarına beklenen girişlerde %5%6 miktarında kontrole tabi lotu %3 olan %1 ürününden yeterli stok bulunmamaktadır.'");
			
			If ValueIsFilled(VerificationError.Purpose) Then
				
				If ValueIsFilled(VerificationError.Characteristic) Then
					
					If ValueIsFilled(VerificationError.ControlledLotReference) Then
						MessageText = StrTemplate(TextAssignmentCharacteristicLotReference,
							VerificationError.Products,
							VerificationError.Characteristic,
							VerificationError.ControlledLotReference,
							VerificationError.Warehouse,
							VerificationError.Purpose,
							Count,
							UnitOfMeasure);
					Else
						MessageText = StrTemplate(TextPurposeCharacteristics,
							VerificationError.Products,
							VerificationError.Characteristic,
							VerificationError.Warehouse,
							VerificationError.Purpose,
							Count,
							UnitOfMeasure);
					EndIf;
					
				Else
					
					If ValueIsFilled(VerificationError.ControlledLotReference) Then
						MessageText = StrTemplate(TextAssignmentLotReference,
							VerificationError.Products,
							VerificationError.ControlledLotReference,
							VerificationError.Warehouse,
							VerificationError.Purpose,
							Count,
							UnitOfMeasure);
					Else
						MessageText = StrTemplate(TextAssignment,
							VerificationError.Products,
							VerificationError.Warehouse,
							VerificationError.Purpose,
							Count,
							UnitOfMeasure);
					EndIf;
					
				EndIf;
				
			Else
				
				If ValueIsFilled(VerificationError.Characteristic) Then
					
					If ValueIsFilled(VerificationError.ControlledLotReference) Then
						MessageText = StrTemplate(TextWithoutAssignmentCharacteristicLotReference,
							VerificationError.Products,
							VerificationError.Characteristic,
							VerificationError.ControlledLotReference,
							VerificationError.Warehouse,
							Count,
							UnitOfMeasure);
					Else
						MessageText = StrTemplate(UnassignedTextCharacteristic,
							VerificationError.Products,
							VerificationError.Characteristic,
							VerificationError.Warehouse,
							Count,
							UnitOfMeasure);
					EndIf;
					
				Else
					
					If ValueIsFilled(VerificationError.ControlledLotReference) Then
						MessageText = StrTemplate(TextWithNoDestinationLotReference,
							VerificationError.Products,
							VerificationError.ControlledLotReference,
							VerificationError.Warehouse,
							Count,
							UnitOfMeasure);
					Else
						MessageText = StrTemplate(UnassignedText,
							VerificationError.Products,
							VerificationError.Warehouse,
							Count,
							UnitOfMeasure);
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If DisableControl Then
				Common.MessageToUser(MessageText, Object, Undefined, Undefined, Undefined);
			Else
				Common.MessageToUser(MessageText, Object, Undefined, Undefined, Cancel);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReportErrorsInImplementationExceedingSeparateProvision(Object, Cancel, ControlResults) Export
	
	For Each VerificationError In ControlResults Do
		
		TextPurposeCharacteristics = "";
		TextAssignment = "";
		Count = 0;
		UnitOfMeasure = VerificationError.UnitOfMeasure;
		
		If VerificationError.MistakeOfHavingMoreNeeds Then
			Count = VerificationError.MagnitudeOfAvailabilityIsGreaterThanNeed;
			If TypeOf(VerificationError.Warehouse) = Type("CatalogRef.Warehouses") Then
				TextPurposeCharacteristics = NStr("vi = 'Mặt hàng: %1, Đặc tính: %2, Kho bãi: %3, Mục đích: %4. 
					|Được ghi tăng để đảm bảo nhiều hơn mức cần thiết là %5 %6.';
					|ru = 'Номенклатура: %1, Характеристика: %2, Склад: %3, Назначение: %4. 
					|Приходуется для обеспечения больше чем требуется на %5 %6.';
					|en = 'Item: %1, Variant: %2, Warehouse: %3, Assignment: %4.
					|Received for supplying more than required for %5 %6.'; fa = 'Item: %1, Variant: %2, Warehouse: %3, Assignment: %4.
					|Received for supplying more than required for %5 %6.';
					|it = 'Nomenclatura: %1, Caratteristica: %2, Magazzino: %3, Assegnazione: %4.
					|In arrivo per soddisfare più di quanto richiesto di %5 %6.';
					|pl = 'Produkt: %1, Charakterystyka: %2, Magazyn: %3, Przeznaczenie: %4. 
					|Jest rejestrowane do zaopatrzenia więcej niż o %5 %6.';
					|tr = 'Öğe: %1, Özellik: %2, Ambar: %3, Atama: %4. 
					|%5 tarafından gerekenden daha fazlasını sağlamak için alındı %6.'");
				TextAssignment = NStr("vi = 'Mặt hàng: %1, Kho bãi: %2, Mục đích: %3. 
					|Được ghi tăng để đảm bảo nhiều hơn mức cần thiết là %4 %5.';
					|ru = 'Номенклатура: %1, Склад: %2, Назначение: %3. 
					|Приходуется для обеспечения больше чем требуется на %4 %5.';
					|en = 'Item: %1, Warehouse: %2, Assignment: %3.
					|Received for supplying more than required for %4 %5.'; fa = 'Item: %1, Warehouse: %2, Assignment: %3.
					|Received for supplying more than required for %4 %5.';
					|it = 'Nomenclatura: %1, Magazzino: %2, Assegnazione: %3. 
					|In arrivo per soddisfare più di quanto richiesto di %4 %5.';
					|pl = 'Produkt: %1, Magazyn: %2, Przeznaczenie: %3. 
					|Jest rejestrowane do zaopatrzenie więcej niż o %4 %5.';
					|tr = 'Öğe: %1, Ambar: %2, Atama: %3. 
					| %4 tarafından gerekenden daha fazlasını sağlamak için alındı %5.'");
			Else
				TextPurposeCharacteristics = NStr("vi = 'Mặt hàng: %1, Đặc tính: %2, Bộ phận: %3, Mục đích: %4. 
					|Được ghi tăng để đảm bảo nhiều hơn mức cần thiết là %5 %6.';
					|ru = 'Номенклатура: %1, Характеристика: %2, Подразделение: %3, Назначение: %4. 
					|Приходуется для обеспечения больше чем требуется на %5 %6.';
					|en = 'Item: %1, Variant: %2, Business unit: %3, Assignment: %4.
					|Received for supplying more than required for %5 %6.'; fa = 'Item: %1, Variant: %2, Business unit: %3, Assignment: %4.
					|Received for supplying more than required for %5 %6.';
					|it = 'Nomenclatura: %1, Caratteristica: %2, Reparto: %3, Assegnazione: %4. 
					|In arrivo per soddisfare più di quanto richiesto di %5 %6.';
					|pl = 'Produkt: %1, Charakterystyka: %2, Dział: %3, Przeznaczenie: %4. 
					|Jest rejestrowane do zaopatrzenia więcej niż o %5 %6.';
					|tr = 'Ürün: %1, Varyant: %2, Departman: %3, Atama: %4. 
					|tarafından istenenden daha fazlasını sağlamak için alındı %5 %6.'");
				TextAssignment = NStr("vi = 'Mặt hàng: %1, Bộ phận: %2, Mục đích: %3. 
					|Được ghi tăng để đảm bảo nhiều hơn mức cần thiết là %4 %5.';
					|ru = 'Номенклатура: %1, Подразделение: %2, Назначение: %3. 
					|Приходуется для обеспечения больше чем требуется на %4 %5.';
					|en = 'Item: %1, Business unit: %2, Assignment: %3.
					|Received for supplying more than required for %4 %5.'; fa = 'Item: %1, Business unit: %2, Assignment: %3.
					|Received for supplying more than required for %4 %5.';
					|it = 'Nomenclatura: %1, Reparto: %2, Assegnazione: %3. 
					|In arrivo per soddisfare più di quanto richiesto di %4 %5.';
					|pl = 'Produkt: %1, Dział: %2, Przeznaczenie: %3. 
					|Jest rejestrowane do zaopatrzenie więcej niż o %4 %5.';
					|tr = 'Ürün: %1, Departman: %2, Atama: %3. 
					| %4 tarafından istenenden daha fazlasını sağlamak için alındı %5.'");
			EndIf;
		Else
			Count = VerificationError.OrderValueIsLessThanZero;
			If TypeOf(VerificationError.Warehouse) = Type("CatalogRef.Warehouses") Then
				TextPurposeCharacteristics = NStr("vi = 'Mặt hàng: %1, Đặc tính: %2, Kho bãi: %3, Mục đích: %4. 
					|Đã đặt hàng để đảm bảo nhiều hơn mức cần thiết là %5 %6.';
					|ru = 'Номенклатура: %1, Характеристика: %2, Склад: %3, Назначение: %4. 
					|Заказано для обеспечения больше чем требуется на %5 %6.';
					|en = 'Item: %1, Variant: %2, Warehouse: %3, Assignment: %4.
					|Ordered for supplying more than required for %5 %6.'; fa = 'Item: %1, Variant: %2, Warehouse: %3, Assignment: %4.
					|Ordered for supplying more than required for %5 %6.';
					|it = 'Nomenclatura: %1, Caratteristica: %2, Magazzino: %3, Assegnazione: %4.
					|Prenotato per soddisfare più di quanto richiesto di %5 %6.';
					|pl = 'Produkt: %1, Charakterystyka: %2, Magazyn: %3, Przeznaczenie: %4. 
					|Zamówiono do zaopatrzenia więcej niż o %5 %6.';
					|tr = 'Ürün: %1, Özellik: %2, Ambar: %3, Atama: %4. 
					|%5 tarafından talep edilenden daha fazlasını tedarik etmek için sipariş verildi %6.'");
				TextAssignment = NStr("vi = 'Mặt hàng: %1, Kho bãi: %2, Mục đích: %3. 
					|Đã đặt hàng để đảm bảo nhiều hơn mức cần thiết là %4 %5.';
					|ru = 'Номенклатура: %1, Склад: %2, Назначение: %3. 
					|Заказано для обеспечения больше чем требуется на %4 %5.';
					|en = 'Item: %1, Warehouse: %2, Assignment: %3.
					|Ordered for supplying more than required for %4 %5.'; fa = 'Item: %1, Warehouse: %2, Assignment: %3.
					|Ordered for supplying more than required for %4 %5.';
					|it = 'Nomenclatura: %1, Magazzino: %2, Assegnazione: %3. 
					|Prenotato per soddisfare più di quanto richiesto di %4 %5.';
					|pl = 'Produkt: %1, Magazyn: %2, Przeznaczenie: %3. 
					|Zamówiono do zaopatrzenie więcej niż o %4 %5.';
					|tr = 'Ürün: %1, Ambar: %2, Atama: %3. 
					| %4 %5 tarafından gerekenden daha fazla tedarik edilmesi sipariş edildi.'");
			Else
				TextPurposeCharacteristics = NStr("vi = 'Mặt hàng: %1, Đặc tính: %2, Bộ phận: %3, Mục đích: %4. 
					|Đã đặt hàng để đảm bảo nhiều hơn mức cần thiết là %5 %6.';
					|ru = 'Номенклатура: %1, Характеристика: %2, Подразделение: %3, Назначение: %4. 
					|Заказано для обеспечения больше чем требуется на %5 %6.';
					|en = 'Item: %1, Variant: %2, Business unit: %3, Assignment: %4.
					| Ordered for supplying more than required for %5 %6.'; fa = 'Item: %1, Variant: %2, Business unit: %3, Assignment: %4.
					| Ordered for supplying more than required for %5 %6.';
					|it = 'Nomenclatura: %1, Caratteristica: %2, Reparto: %3, Assegnazione: %4.
					|Prenotato per soddisfare più di quanto richiesto di %5 %6.';
					|pl = 'Produkt: %1, Charakterystyka: %2, Dział: %3, Przeznaczenie: %4. 
					|Zamówiono do zaopatrzenia więcej niż o %5 %6.';
					|tr = 'Ürün: %1, Varyant: %2, Departman: %3, Atama: %4. 
					|tarafından gerekenden daha fazla tedarik edilmesi sipariş edildi %5 %6.'");
				TextAssignment = NStr("vi = 'Mặt hàng: %1, Bộ phận: %2, Mục đích: %3. 
					|Đã đặt hàng để đảm bảo nhiều hơn mức cần thiết là %4 %5.';
					|ru = 'Номенклатура: %1, Подразделение: %2, Назначение: %3. 
					|Заказано для обеспечения больше чем требуется на %4 %5.';
					|en = 'Item: %1, Business unit: %2, Assignment: %3.
					| Ordered for supplying more than required for %4 %5.'; fa = 'Item: %1, Business unit: %2, Assignment: %3.
					| Ordered for supplying more than required for %4 %5.';
					|it = 'Nomenclatura: %1, Reparto: %2, Assegnazione: %3. 
					|Prenotato per soddisfare più di quanto richiesto di %4 %5.';
					|pl = 'Produkt: %1, Dział: %2, Przeznaczenie: %3. 
					|Zamówiono do zaopatrzenie więcej niż o %4 %5.';
					|tr = 'Ürün: %1, Departman: %2, Atama: %3. 
					| %4 %5 tarafından gerekenden daha fazlasını tedarik etmesi sipariş edildi.'");
			EndIf;
		EndIf;
		
		If ValueIsFilled(VerificationError.Characteristic) Then
			MessageText = StrTemplate(TextPurposeCharacteristics,
				VerificationError.Products,
				VerificationError.Characteristic,
				VerificationError.Warehouse,
				VerificationError.Purpose,
				Count,
				UnitOfMeasure);
		Else
			MessageText = StrTemplate(TextAssignment,
				VerificationError.Products,
				VerificationError.Warehouse,
				VerificationError.Purpose,
				Count,
				UnitOfMeasure);
		EndIf;
		
		Common.MessageToUser(MessageText, Object, Undefined, Undefined, Cancel);
		
	EndDo;
	
EndProcedure

Procedure ReportErrorsInInventoryOfControlledLotReferenceInWarehouse(Object, Cancel, ControlResults) Export
	
	For Each VerificationError In ControlResults Do
		
		Products = VerificationError.Products;
		Characteristic = VerificationError.Characteristic;
		ControlledLotReference = VerificationError.ControlledLotReference;
		Warehouse = VerificationError.Warehouse;
		Purpose = VerificationError.Purpose;
		Count = VerificationError.Count;
		UnitOfMeasure = VerificationError.UnitOfMeasure;
		
		If ValueIsFilled(VerificationError.Characteristic) And ValueIsFilled(VerificationError.Purpose) Then
		
			Text = NStr("ru = 'Недостаточно товара %1 c характеристикой %2 контролируемой партии %3 на складе %4 по назначению %5 в количестве %6 %7.';
						|vi = 'There are not enough ""%1"" items with the ""%2"" variant of the ""%3"" controlled lot at the ""%4"" warehouse by the ""%5"" assignment in the amount of %6 %7.';
						|en = 'There are not enough ""%1"" items with the ""%2"" variant of the ""%3"" controlled lot at the ""%4"" warehouse by the ""%5"" assignment in the amount of %6 %7.'; fa = 'There are not enough ""%1"" items with the ""%2"" variant of the ""%3"" controlled lot at the ""%4"" warehouse by the ""%5"" assignment in the amount of %6 %7.';
						|it = 'There are not enough ""%1"" items with the ""%2"" variant of the ""%3"" controlled lot at the ""%4"" warehouse by the ""%5"" assignment in the amount of %6 %7.';
						|pl = 'There are not enough ""%1"" items with the ""%2"" variant of the ""%3"" controlled lot at the ""%4"" warehouse by the ""%5"" assignment in the amount of %6 %7.';
						|tr = '%4ambarındaki %3 kontrole tabi lotuna ait %2 varyantındaki %1 ürününde, %5 ataması için %6 %7miktarında yeterli stok bulunmamaktadır.'");
			Text = StrTemplate(Text,
				Products,
				Characteristic,
				ControlledLotReference,
				Warehouse,
				Purpose,
				Count,
				UnitOfMeasure);
				
		ElsIf ValueIsFilled(VerificationError.Characteristic) Then
			
			Text = NStr("ru = 'Недостаточно товара %1 c характеристикой %2 контролируемой партии %3 на складе %4 в количестве %5 %6.';
						|vi = 'There are not enough ""%1"" items with the ""%2"" variant of the ""%3"" controlled lot at the ""%4"" warehouse in the amount of %5 %6.';
						|en = 'There are not enough ""%1"" items with the ""%2"" variant of the ""%3"" controlled lot at the ""%4"" warehouse in the amount of %5 %6.'; fa = 'There are not enough ""%1"" items with the ""%2"" variant of the ""%3"" controlled lot at the ""%4"" warehouse in the amount of %5 %6.';
						|it = 'There are not enough ""%1"" items with the ""%2"" variant of the ""%3"" controlled lot at the ""%4"" warehouse in the amount of %5 %6.';
						|pl = 'There are not enough ""%1"" items with the ""%2"" variant of the ""%3"" controlled lot at the ""%4"" warehouse in the amount of %5 %6.';
						|tr = '%4 ambarındaki %3 kontrole tabi lotuna ait %2 varyantındaki %1 ürününde %5 %6miktarında yeterli stok bulunmamaktadır.'");
			Text = StrTemplate(Text,
				Products,
				Characteristic,
				ControlledLotReference,
				Warehouse,
				Count,
				UnitOfMeasure);
				
		ElsIf ValueIsFilled(VerificationError.Purpose) Then
			
			Text = NStr("ru = 'Недостаточно товара %1 контролируемой партии %2 на складе %3 по назначению %4 в количестве %5 %6.';
						|vi = 'There are not enough ""%1"" items of the ""%2"" controlled lot at the ""%3"" warehouse by the ""%4"" assignment in the amount of %5 %6.';
						|en = 'There are not enough ""%1"" items of the ""%2"" controlled lot at the ""%3"" warehouse by the ""%4"" assignment in the amount of %5 %6.'; fa = 'There are not enough ""%1"" items of the ""%2"" controlled lot at the ""%3"" warehouse by the ""%4"" assignment in the amount of %5 %6.';
						|it = 'There are not enough ""%1"" items of the ""%2"" controlled lot at the ""%3"" warehouse by the ""%4"" assignment in the amount of %5 %6.';
						|pl = 'There are not enough ""%1"" items of the ""%2"" controlled lot at the ""%3"" warehouse by the ""%4"" assignment in the amount of %5 %6.';
						|tr = '%3 ambarındaki %2 kontrole tabi lotuna ait %1 ürününde, %4 ataması için %5 %6miktarında yeterli stok bulunmamaktadır.'");
			Text = StrTemplate(Text,
				Products,
				ControlledLotReference,
				Warehouse,
				Purpose,
				Count,
				UnitOfMeasure);
				
		Else
			
			Text = NStr("ru = 'Недостаточно товара %1 контролируемой партии %2 на складе %3 в количестве %4 %5.';
						|vi = 'There are not enough ""%1"" items of the ""%2"" controlled lot at the ""%3"" warehouse in the amount of %4 %5.';
						|en = 'There are not enough ""%1"" items of the ""%2"" controlled lot at the ""%3"" warehouse in the amount of %4 %5.'; fa = 'There are not enough ""%1"" items of the ""%2"" controlled lot at the ""%3"" warehouse in the amount of %4 %5.';
						|it = 'There are not enough ""%1"" items of the ""%2"" controlled lot at the ""%3"" warehouse in the amount of %4 %5.';
						|pl = 'There are not enough ""%1"" items of the ""%2"" controlled lot at the ""%3"" warehouse in the amount of %4 %5.';
						|tr = '%3 ambarındaki %2 kontrole tabi lotuna ait %1 ürününde %4%5 miktarında yeterli stok bulunmamaktadır.'");
			Text = StrTemplate(Text,
				Products,
				ControlledLotReference,
				Warehouse,
				Count,
				UnitOfMeasure);
				
		EndIf;
		
		Common.MessageToUser(Text, Object, Undefined, Undefined, Cancel);
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////////////////////////////
// Maintenance of order status registers.

Procedure AddTemporaryStateUpdateTables(Query, FilterOverridable, Postfix) Export
	
	RegisterNames = New Array();
	RegisterNames.Add("InformationRegister.SalesOrderStates");
	RegisterNames.Add("InformationRegister.StatusesOfInternalOrders");
	RegisterNames.Add("InformationRegister.ProductionStageStates");
	Texts = New Array();
	
	For Each RegisterName In RegisterNames Do
		
		RegisterName = StrReplace(RegisterName, "InformationRegister.", "");
		Parameters = InformationRegisters[RegisterName].ParametersForUpdatingOrderStates();
		Text = Parameters.RecordSelectionRule;
		Text = StrReplace(Text, "FilterOverridable",  FilterOverridable);
		Text = StrReplace(Text, "TableOverridable", RegisterName + Postfix);
		Texts.Add(Text);
		
	EndDo;
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Procedure TableOfChangesStockAllocationForStateCalculation(Query) Export
	
	RegisterNames = New Array();
	RegisterNames.Add("InformationRegister.SalesOrderStates");
	RegisterNames.Add("InformationRegister.StatusesOfInternalOrders");
	RegisterNames.Add("InformationRegister.ProductionStageStates");
	Texts = New Array();
	
	For Each RegisterName In RegisterNames Do
		
		RegisterName = StrReplace(RegisterName, "InformationRegister.", "");
		Parameters = InformationRegisters[RegisterName].ParametersForUpdatingOrderStates();
		Text = Parameters.FunctionForComparingRecordsInTemporaryTable;
		Text = StrReplace(Text, "BeforeWriteOverridable", RegisterName + "BeforeWrite");
		Text = StrReplace(Text, "OnWriteOverridable",    RegisterName + "OnWrite");
		Text = StrReplace(Text, "UpdateOverridable",    RegisterName + "Update");
		Texts.Add(Text);
		
	EndDo;
	
	For Each RegisterName In RegisterNames Do
		
		RegisterName = StrReplace(RegisterName, "InformationRegister.", "");
		
		Text = "DROP " + RegisterName + "BeforeWrite";
		Texts.Add(Text);
		
		Text = "DROP " + RegisterName + "OnWrite";
		Texts.Add(Text);
		
	EndDo;
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.ExecuteBatch();
	
EndProcedure

Procedure ExcludeLinksThatRequireDeferredUpdates(References) Export
	
	If InfobaseUpdate.DeferredUpdateCompleted() Then
		Return;
	EndIf;
	
	CustomerOrderStateSet = InformationRegisters.SalesOrderStates.CreateRecordSet();
	InternalOrderStateSet = InformationRegisters.StatusesOfInternalOrders.CreateRecordSet();
	SetOfStateStagesOfProduction = InformationRegisters.ProductionStageStates.CreateRecordSet();
	CustomerOrderStateSet.Filter.OrderDocument.Use = True;
	InternalOrderStateSet.Filter.OrderDocument.Use = True;
	SetOfStateStagesOfProduction.Filter.Stage.Use = True;
	TotalItems = References.Count();
	For Counter = 1 To TotalItems Do
		IndexOf = TotalItems - Counter;
		Ref = References[IndexOf];
		
		Set = Undefined;
		If CustomerOrderStateSet.Filter.OrderDocument.ValueType.ContainsType(TypeOf(Ref)) Then
			Set = CustomerOrderStateSet;
			Set.Filter.OrderDocument.Value = Ref;
		ElsIf InternalOrderStateSet.Filter.OrderDocument.ValueType.ContainsType(TypeOf(Ref)) Then
			Set = InternalOrderStateSet;
			Set.Filter.OrderDocument.Value = Ref;
		ElsIf SetOfStateStagesOfProduction.Filter.Stage.ValueType.ContainsType(TypeOf(Ref)) Then
			Set = SetOfStateStagesOfProduction;
			Set.Filter.Stage.Value = Ref;
		EndIf;
		
		If Set <> Undefined Then
			CheckResult = InfobaseUpdate.ObjectProcessed(Set);
			If Not CheckResult.Processed Then
				References.Delete(IndexOf);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

Function CountRegisterWithRoutineTask() Export
	Return Not Common.FileInfobase() Or BlockInventoryAllocation();
EndFunction

Function BlockInventoryAllocation() Export
	ApplicationStartupParameter = SessionParameters.ClientParametersAtServer.Get("LaunchParameter");
	Return StrFind(ApplicationStartupParameter, "BlockInventoryAllocation") > 0;
EndFunction

Function ErrorsInCheckingCorrectnessOfInformationRegisterEntriesInventoryAllocation() Export
	
	Query = New Query();
	
	Texts = New Array();
	
	#Region BalanceSheetsOfControlledLotREFERENCES
	Text =
		"SELECT
		|	&TextRemnantsOfControlledLotsReferences AS State,
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose,
		|	Set.OrderDocument AS ControlledLotReference,
		|	SUM(Set.ToReserveRegisteredRecords) AS ToReserveRegisteredRecords,
		|	SUM(Set.ReserveAsYouRegisterRecorded) AS ReserveAsYouRegisterRecorded,
		|	SUM(Set.AvailableWithRegisteredRecordedLock) AS AvailableWithRegisteredRecordedLock,
		|	SUM(Set.RegisteredRecordedTrafficIsExpectedToBeBlocked) AS RegisteredRecordedTrafficIsExpectedToBeBlocked,
		|	SUM(Set.AvailableWithoutUnblockingRegisteredRecording) AS AvailableWithoutUnblockingRegisteredRecording,
		|	SUM(Set.ItIsExpectedWithoutUnblockingRegisteringRecorded) AS ItIsExpectedWithoutUnblockingRegisteringRecorded,
		|	SUM(Set.BackupInformation) AS BackupInformation,
		|	SUM(Set.ReserveAsNeeded) AS ReserveAsNeeded,
		|	SUM(Set.AvailableWithInformationBlocking) AS AvailableWithInformationBlocking,
		|	SUM(Set.ExpectedWithInformationBlocking) AS ExpectedWithInformationBlocking,
		|	SUM(Set.AvailableWithoutUnlockingInformation) AS AvailableWithoutUnlockingInformation,
		|	SUM(Set.ExpectedWithoutUnlockingInformation) AS ExpectedWithoutUnlockingInformation
		|FROM(
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.OrderDocument AS OrderDocument,
		|		Table.ToReserve_ AS ToReserveRegisteredRecords,
		|		Table.ToReserveAsNeeded AS ReserveAsYouRegisterRecorded,
		|		Table.AvailableWithLock AS AvailableWithRegisteredRecordedLock,
		|		Table.ExpectedWithBlocking AS RegisteredRecordedTrafficIsExpectedToBeBlocked,
		|		Table.InStock - Table.AvailableWithLock AS AvailableWithoutUnblockingRegisteredRecording,
		|		Table.Expected_ - Table.ExpectedWithBlocking AS ItIsExpectedWithoutUnblockingRegisteringRecorded,
		|		0 AS BackupInformation,
		|		0 AS ReserveAsNeeded,
		|		0 AS AvailableWithInformationBlocking,
		|		0 AS ExpectedWithInformationBlocking,
		|		0 AS AvailableWithoutUnlockingInformation,
		|		0 AS ExpectedWithoutUnlockingInformation
		|	FROM(
		|		SELECT
		|			Table.Products AS Products,
		|			Table.Characteristic AS Characteristic,
		|			Table.Warehouse AS Warehouse,
		|			Table.Purpose AS Purpose,
		|			Table.OrderDocument AS OrderDocument,
		|			Table.ReserveAtWarehouseFromLockedBalance AS ToReserve_,
		|			Table.ReserveUponReceiptFromLockedBalance AS ToReserveAsNeeded,
		|			Table.LockedInStockBalance AS InStock,
		|			Table.LockedReceiptBalance AS Expected_,
		|			
					// AvailableWithLock
		|			CASE
		|				WHEN Table.LockedInStockBalance < 0
		|					THEN Table.LockedInStockBalance
		|				WHEN Table.LockedInStockBalance - Table.ToUnlockBalance < 0
		|					THEN Table.LockedInStockBalance
		|				ELSE Table.ToUnlockBalance
		|			END AS AvailableWithLock,
		|			
					// ExpectedWithBlocking
		|			CASE
		|				WHEN Table.LockedInStockBalance < 0
		|					THEN
		|						CASE
		|							WHEN Table.LockedReceiptBalance - Table.ToUnlockBalance < 0
		|								THEN Table.LockedReceiptBalance
		|							ELSE Table.ToUnlockBalance
		|						END
		|				WHEN Table.LockedInStockBalance - Table.ToUnlockBalance < 0
		|					THEN
		|						CASE
		|							WHEN Table.LockedInStockBalance + Table.LockedReceiptBalance - Table.ToUnlockBalance < 0
		|								THEN Table.LockedReceiptBalance
		|							ELSE Table.ToUnlockBalance - Table.LockedInStockBalance
		|						END
		|				ELSE 0
		|			END AS ExpectedWithBlocking
		|		FROM
		|			AccumulationRegister.InventoryAndDemands.Balance AS Table) AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.ReceiptOrder AS OrderDocument,
		|		0 AS ToReserveRegisteredRecords,
		|		0 AS ReserveAsYouRegisterRecorded,
		|		0 AS AvailableWithRegisteredRecordedLock,
		|		0 AS RegisteredRecordedTrafficIsExpectedToBeBlocked,
		|		0 AS AvailableWithoutUnblockingRegisteredRecording,
		|		0 AS ItIsExpectedWithoutUnblockingRegisteringRecorded,
		|		0 AS BackupInformation,
		|		0 AS ReserveAsNeeded,
		|		CASE
		|			WHEN Table.InventoryState = VALUE(Enum.InventoryStates.AvailablePendingUnlocking)
		|				THEN Table.Count
		|			ELSE 0
		|		END AvailableWithInformationBlocking,
		|		CASE
		|			WHEN Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock)
		|				THEN Table.Count
		|			ELSE 0
		|		END AS ExpectedWithInformationBlocking,
		|		CASE
		|			WHEN Table.InventoryState = VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking)
		|				THEN Table.Count
		|			ELSE 0
		|		END AS AvailableWithoutUnlockingInformation,
		|		CASE
		|			WHEN Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking)
		|				THEN Table.Count
		|			ELSE 0
		|		END AS ExpectedWithoutUnlockingInformation
		|	FROM
		|		InformationRegister.InventoryAllocation AS Table
		|	WHERE
		|		Table.InventoryState IN(
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|			VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking))
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.ShipmentOrder AS OrderDocument,
		|		0 AS ToReserveRegisteredRecords,
		|		0 AS ReserveAsYouRegisterRecorded,
		|		0 AS AvailableWithRegisteredRecordedLock,
		|		0 AS RegisteredRecordedTrafficIsExpectedToBeBlocked,
		|		0 AS AvailableWithoutUnblockingRegisteredRecording,
		|		0 AS ItIsExpectedWithoutUnblockingRegisteringRecorded,
		|		CASE
		|			WHEN Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked)
		|				THEN Table.Count
		|			ELSE 0
		|		END AS BackupInformation,
		|		CASE
		|			WHEN Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked)
		|				THEN Table.Count
		|			ELSE 0
		|		END AS ReserveAsNeeded,
		|		0 AS AvailableWithInformationBlocking,
		|		0 AS ExpectedWithInformationBlocking,
		|		0 AS AvailableWithoutUnlockingInformation,
		|		0 AS ExpectedWithoutUnlockingInformation
		|	FROM
		|		InformationRegister.InventoryAllocation AS Table
		|	WHERE
		|		Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
		|			VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked))) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse,
		|	Set.Purpose,
		|	Set.OrderDocument
		|HAVING
		|	SUM(Set.ToReserveRegisteredRecords) <> SUM(Set.BackupInformation)
		|	OR SUM(Set.ReserveAsYouRegisterRecorded) <> SUM(Set.ReserveAsNeeded)
		|	OR SUM(Set.AvailableWithRegisteredRecordedLock) <> SUM(Set.AvailableWithInformationBlocking)
		|	OR SUM(Set.RegisteredRecordedTrafficIsExpectedToBeBlocked) <> SUM(Set.ExpectedWithInformationBlocking)
		|	OR SUM(Set.AvailableWithoutUnblockingRegisteredRecording) <> SUM(Set.AvailableWithoutUnlockingInformation)
		|	OR SUM(Set.ItIsExpectedWithoutUnblockingRegisteringRecorded) <> SUM(Set.ExpectedWithoutUnlockingInformation)";
	#EndRegion
	
	Texts.Add(Text);
	Query.SetParameter("TextRemnantsOfControlledLotsReferences", NStr("ru = 'Остатки контролируемых партий';
																		|vi = 'Controlled lot balance';
																		|en = 'Controlled lot balance'; fa = 'Controlled lot balance';
																		|it = 'Controlled lot balance';
																		|pl = 'Controlled lot balance';
																		|tr = 'Kontrole tabi lot bakiyeleri'"));
	
	#Region BalancesOfCheckedGoods
	
	Text =
		"SELECT
		|	&TextBalanceOfCheckedGoods AS State,
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose,
		|	Set.OrderDocument AS OrderDocument,
		|	Set.EventDate AS EventDate,
		|	SUM(Set.InStockRegisteredRecords) AS InStockRegisteredRecords,
		|	SUM(Set.ThereIsExpectedToBeRegisteredRecorded) AS ThereIsExpectedToBeRegisteredRecorded,
		|	SUM(Set.OnApprovalOfRegisteredRecordedDelivery) AS OnApprovalOfRegisteredRecordedDelivery,
		|	SUM(Set.ReserveAtRegisteredRecordsWarehouse) AS ReserveAtRegisteredRecordsWarehouse,
		|	SUM(Set.ReserveAsTrafficArrives) AS ReserveAsTrafficArrives,
		|	SUM(Set.PostponeMotionReservation) AS PostponeMotionReservation,
		|	SUM(Set.ToEnsureMovement) AS ToEnsureMovement,
		|	SUM(Set.DoNotProvideMovement) AS DoNotProvideMovement,
		|	SUM(Set.AvailableInformation) AS AvailableInformation,
		|	SUM(Set.ExpectedInformation) AS ExpectedInformation,
		|	SUM(Set.OnApprovalOfDeliveryOfInformation) AS OnApprovalOfDeliveryOfInformation,
		|	SUM(Set.ReserveInformationAtWarehouse) AS ReserveInformationAtWarehouse,
		|	SUM(Set.ReserveAsInformationBecomesAvailable) AS ReserveAsInformationBecomesAvailable,
		|	SUM(Set.PostponeReservationOfInformation) AS PostponeReservationOfInformation,
		|	SUM(Set.ToProvideInformation) AS ToProvideInformation,
		|	SUM(Set.DoNotProvideInformation) AS DoNotProvideInformation
		|FROM(
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		UNDEFINED AS OrderDocument,
		|		DATETIME(1, 1, 1) AS EventDate,
		|		Table.InStockBalance - Table.LockedInStockBalance AS InStockRegisteredRecords,
		|		0 AS ThereIsExpectedToBeRegisteredRecorded,
		|		0 AS OnApprovalOfRegisteredRecordedDelivery,
		|		0 AS ReserveAtRegisteredRecordsWarehouse,
		|		0 AS ReserveAsTrafficArrives,
		|		0 AS PostponeMotionReservation,
		|		0 AS ToEnsureMovement,
		|		0 AS DoNotProvideMovement,
		|		0 AS AvailableInformation,
		|		0 AS ExpectedInformation,
		|		0 AS OnApprovalOfDeliveryOfInformation,
		|		0 AS ReserveInformationAtWarehouse,
		|		0 AS ReserveAsInformationBecomesAvailable,
		|		0 AS PostponeReservationOfInformation,
		|		0 AS ToProvideInformation,
		|		0 AS DoNotProvideInformation
		|	FROM
		|		AccumulationRegister.InventoryAndDemands.Balance AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.OrderDocument AS OrderDocument,
		|		Table.EventDate AS EventDate,
		|		0 AS InStockRegisteredRecords,
		|		Table.Received_1Balance - Table.LockedReceiptBalance AS ThereIsExpectedToBeRegisteredRecorded,
		|		Table.OrderedBalance - Table.Received_1Balance AS OnApprovalOfRegisteredRecordedDelivery,
		|		Table.ReserveAtWarehouseBalance AS ReserveAtRegisteredRecordsWarehouse,
		|		Table.ReserveAsReceivedBalance AS ReserveAsTrafficArrives,
		|		Table.SnoozeReservationBalance AS PostponeMotionReservation,
		|		Table.ToSupplyBalance AS ToEnsureMovement,
		|		Table.NotProvideBalance AS DoNotProvideMovement,
		|		0 AS AvailableInformation,
		|		0 AS ExpectedInformation,
		|		0 AS OnApprovalOfDeliveryOfInformation,
		|		0 AS ReserveInformationAtWarehouse,
		|		0 AS ReserveAsInformationBecomesAvailable,
		|		0 AS PostponeReservationOfInformation,
		|		0 AS ToProvideInformation,
		|		0 AS DoNotProvideInformation
		|	FROM
		|		AccumulationRegister.InventoryAndDemands.Balance AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.ReceiptOrder AS OrderDocument,
		|		Table.DateOfReceipt AS EventDate,
		|		0 AS InStockRegisteredRecords,
		|		0 AS ThereIsExpectedToBeRegisteredRecorded,
		|		0 AS OnApprovalOfRegisteredRecordedDelivery,
		|		0 AS ReserveAtRegisteredRecordsWarehouse,
		|		0 AS ReserveAsTrafficArrives,
		|		0 AS PostponeMotionReservation,
		|		0 AS ToEnsureMovement,
		|		0 AS DoNotProvideMovement,
		|		CASE
		|			WHEN Table.InventoryState = VALUE(Enum.InventoryStates.InStock)
		|				THEN
		|					Table.Count
		|			ELSE 0
		|		END AS AvailableInformation,
		|		CASE
		|			WHEN Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock)
		|				THEN
		|					Table.Count
		|			ELSE 0
		|		END AS ExpectedInformation,
		|		CASE
		|			WHEN Table.InventoryState = VALUE(Enum.InventoryStates.PendingSupplyApproval)
		|				THEN
		|					Table.Count
		|			ELSE 0
		|		END AS OnApprovalOfDeliveryOfInformation,
		|		0 AS ReserveInformationAtWarehouse,
		|		0 AS ReserveAsInformationBecomesAvailable,
		|		0 AS PostponeReservationOfInformation,
		|		0 AS ToProvideInformation,
		|		0 AS DoNotProvideInformation
		|	FROM
		|		InformationRegister.InventoryAllocation AS Table
		|	WHERE
		|		Table.InventoryState IN(
		|			VALUE(Enum.InventoryStates.InStock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|			VALUE(Enum.InventoryStates.PendingSupplyApproval))
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.Purpose AS Purpose,
		|		Table.ShipmentOrder AS OrderDocument,
		|		Table.RequestShipmentOn AS EventDate,
		|		0 AS InStockRegisteredRecords,
		|		0 AS ThereIsExpectedToBeRegisteredRecorded,
		|		0 AS OnApprovalOfRegisteredRecordedDelivery,
		|		0 AS ReserveAtRegisteredRecordsWarehouse,
		|		0 AS ReserveAsTrafficArrives,
		|		0 AS PostponeMotionReservation,
		|		0 AS ToEnsureMovement,
		|		0 AS DoNotProvideMovement,
		|		0 AS AvailableInformation,
		|		0 AS ExpectedInformation,
		|		0 AS OnApprovalOfDeliveryOfInformation,
		|		CASE
		|			WHEN Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse)
		|				THEN
		|					Table.Count
		|			ELSE 0
		|		END AS ReserveInformationAtWarehouse,
		|		CASE
		|			WHEN Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAsReceived)
		|				THEN
		|					Table.Count
		|			ELSE 0
		|		END AS ReserveAsInformationBecomesAvailable,
		|		CASE
		|			WHEN Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.SnoozeReservation)
		|				THEN
		|					Table.Count
		|			ELSE 0
		|		END AS PostponeReservationOfInformation,
		|		CASE
		|			WHEN Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ToSupply)
		|				THEN
		|					Table.Count
		|			ELSE 0
		|		END AS ToProvideInformation,
		|		CASE
		|			WHEN Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.NotProvide)
		|				THEN
		|					Table.Count
		|			ELSE 0
		|		END AS DoNotProvideInformation
		|	FROM
		|		InformationRegister.InventoryAllocation AS Table
		|	WHERE
		|		Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply),
		|			VALUE(Enum.DemandCharacteristics.NotProvide))
		|) AS Set
		|	GROUP BY
		|		Set.Products,
		|		Set.Characteristic,
		|		Set.Warehouse,
		|		Set.Purpose,
		|		Set.OrderDocument,
		|		Set.EventDate
		|HAVING
		|	SUM(Set.InStockRegisteredRecords) <> SUM(Set.AvailableInformation)
		|		OR SUM(Set.ThereIsExpectedToBeRegisteredRecorded) <> SUM(Set.ExpectedInformation)
		|		OR SUM(Set.OnApprovalOfRegisteredRecordedDelivery) <> SUM(Set.OnApprovalOfDeliveryOfInformation)
		|		OR SUM(Set.ReserveAtRegisteredRecordsWarehouse) <> SUM(Set.ReserveInformationAtWarehouse)
		|		OR SUM(Set.ReserveAsTrafficArrives) <> SUM(Set.ReserveAsInformationBecomesAvailable)
		|		OR SUM(Set.PostponeMotionReservation) <> SUM(Set.PostponeReservationOfInformation)
		|		OR SUM(Set.ToEnsureMovement) <> SUM(Set.ToProvideInformation)
		|		OR SUM(Set.DoNotProvideMovement) <> SUM(Set.DoNotProvideInformation)";
	
	#EndRegion
	
	Texts.Add(Text);
	Query.SetParameter("TextBalanceOfCheckedGoods", NStr("ru = 'Остатки проверенных товаров';
														|vi = 'Checked goods balance';
														|en = 'Checked goods balance'; fa = 'Checked goods balance';
														|it = 'Checked goods balance';
														|pl = 'Checked goods balance';
														|tr = 'Kontrol edilen ürünlerin bakiyeleri'"));
	
	#Region AvailableForAllPurposes
	
	Text =
		"SELECT
		|	&TextIsAvailableForAllPurposes AS State,
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	SUM(Set.AvailableForRegisteringRecorded) AS AvailableForRegisteringRecorded,
		|	SUM(Set.AvailableBalanceForSelectionOfRegisteredRecorded) AS AvailableBalanceForSelectionOfRegisteredRecorded,
		|	SUM(Set.AvailableForRegisteringRecorded) AS AvailableForSelectionOfInformation,
		|	SUM(Set.AvailableBalanceForInformationSelection) AS AvailableBalanceForInformationSelection
		|FROM(
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		Table.InStockBalance AS AvailableForRegisteringRecorded,
		|		CASE
		|			WHEN Table.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|				THEN 0
		|			WHEN Table.InStockBalance
		|					- Table.LockedInStockBalance
		|						- Table.ReserveAtWarehouseBalance < 0
		|				THEN
		|					Table.InStockBalance
		|						- Table.LockedInStockBalance
		|						- Table.ReserveAtWarehouseBalance
		|			WHEN Table.InStockBalance
		|					- Table.LockedInStockBalance
		|					- Table.ReserveAtWarehouseBalance
		|					- Table.ReserveAsReceivedBalance > 0
		|				THEN
		|					Table.InStockBalance
		|						- Table.LockedInStockBalance
		|						- Table.ReserveAtWarehouseBalance
		|						- Table.ReserveAsReceivedBalance
		|			ELSE 0
		|		END AS AvailableBalanceForSelectionOfRegisteredRecorded,
		|		0 AS AvailableForSelectionOfInformation,
		|		0 AS AvailableBalanceForInformationSelection
		|	FROM
		|		AccumulationRegister.InventoryAndDemands.Balance(,
		|			VALUETYPE(Warehouse) = TYPE(Catalog.Warehouses) AND Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)) AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.Products AS Products,
		|		Table.Characteristic AS Characteristic,
		|		Table.Warehouse AS Warehouse,
		|		0 AS InStockRegisteredRecords,
		|		0 AS AvailableBalanceForSelectionOfRegisteredRecorded,
		|		Table.InStock AS AvailableForSelectionOfInformation,
		|		Table.Available AS AvailableBalanceForInformationSelection
		|	FROM
		|		InformationRegister.AvailableStockBalances AS Table
		|	WHERE
		|		Table.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|		AND Table.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse
		|HAVING
		|	SUM(Set.AvailableForRegisteringRecorded) <> SUM(Set.AvailableForSelectionOfInformation)
		|		OR SUM(Set.AvailableBalanceForSelectionOfRegisteredRecorded) <> SUM(Set.AvailableBalanceForInformationSelection)";
		
	#EndRegion
	
	Texts.Add(Text);
	Query.SetParameter("TextIsAvailableForAllPurposes", NStr("ru = 'В наличии по всем назначениям';
															|vi = 'Available for all assignments';
															|en = 'Available for all assignments'; fa = 'Available for all assignments';
															|it = 'Available for all assignments';
															|pl = 'Available for all assignments';
															|tr = 'Tüm atamalarda mevcut stok'"));
	
	#Region InventoryDistributionProcedureHasBeenViolated
	
	Text =
		"SELECT DISTINCT
		|	&TextInventoryDistributionProcedureHasBeenViolated AS State,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.InventoryState AS StateOfInventoryIsCloser,
		|	Table.ReceiptOrder AS ReceiptOrderCloser,
		|	Table.AvailabilityDate AS AvailabilityDateIsCloser,
		|	NeedIsHigherPriority.InventoryState AS StateOfInventoryIsFurther,
		|	NeedIsHigherPriority.ReceiptOrder AS OrderToGoFurther,
		|	NeedIsHigherPriority.AvailabilityDate AS DateOfAvailabilityNext
		|FROM
		|	InformationRegister.InventoryAllocation AS Table
		|		INNER JOIN InformationRegister.InventoryAllocation AS NeedIsHigherPriority
		|		ON NeedIsHigherPriority.Products = Table.Products
		|		 AND NeedIsHigherPriority.Characteristic = Table.Characteristic
		|		 AND NeedIsHigherPriority.Warehouse = Table.Warehouse
		|		 AND NeedIsHigherPriority.Purpose = Table.Purpose
		|WHERE
		|	Table.InventoryState IN(
		|			VALUE(Enum.InventoryStates.InStock),
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|			VALUE(Enum.InventoryStates.PendingSupplyApproval))
		|		AND (
		|			Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.Surplus)
		|					AND NeedIsHigherPriority.DemandCharacteristic IN(
		|						VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|						VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|						VALUE(Enum.DemandCharacteristics.ToSupply))
		|				OR Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ToSupply)
		|					AND NeedIsHigherPriority.DemandCharacteristic IN(
		|						VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|						VALUE(Enum.DemandCharacteristics.SnoozeReservation))
		|				OR Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.SnoozeReservation)
		|					AND NeedIsHigherPriority.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAsReceived))
		|		AND (CASE
		|				WHEN Table.InventoryState = VALUE(Enum.InventoryStates.InStock)
		|						AND Table.Count > 0
		|					THEN
		|						NeedIsHigherPriority.InventoryState IN(
		|							VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|							VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|							VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|							VALUE(Enum.InventoryStates.PendingSupplyApproval))
		|				WHEN Table.InventoryState = VALUE(Enum.InventoryStates.AvailablePendingUnlocking)
		|					THEN
		|						NeedIsHigherPriority.InventoryState IN(
		|							VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|							VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|							VALUE(Enum.InventoryStates.PendingSupplyApproval))
		|				WHEN Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock)
		|					THEN
		|						NeedIsHigherPriority.InventoryState IN(
		|							VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|							VALUE(Enum.InventoryStates.PendingSupplyApproval))
		|				WHEN Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock)
		|					THEN
		|						NeedIsHigherPriority.InventoryState = VALUE(Enum.InventoryStates.PendingSupplyApproval)
		|				END
		|			OR Table.InventoryState = NeedIsHigherPriority.InventoryState
		|				AND (NeedIsHigherPriority.AvailabilityDate > Table.AvailabilityDate
		|					OR NeedIsHigherPriority.DateOfReceipt = Table.DateOfReceipt
		|						AND NeedIsHigherPriority.ReceiptOrder > Table.ReceiptOrder))";
		
	#EndRegion
	
	Texts.Add(Text);
	Query.SetParameter("TextInventoryDistributionProcedureHasBeenViolated", NStr("ru = 'Нарушен порядок распределения запасов';
																				|vi = 'Inventory allocation procedure is violated';
																				|en = 'Inventory allocation procedure is violated'; fa = 'Inventory allocation procedure is violated';
																				|it = 'Inventory allocation procedure is violated';
																				|pl = 'Inventory allocation procedure is violated';
																				|tr = 'Stok dağıtım sırası ihlal edildi'"));
	
	#Region RecordingFormatIsBroken
	
	Text =
		"SELECT
		|	&TextRecordingFormatIsBroken AS State,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ShipmentOrder AS ShipmentOrder,
		|	Table.RequestShipmentOn AS RequestShipmentOn,
		|	Table.ReceiptOrder AS ReceiptOrder,
		|	Table.DateOfReceipt AS DateOfReceipt,
		|	Table.AvailabilityDate AS AvailabilityDate,
		|	Table.Count
		|FROM
		|	InformationRegister.InventoryAllocation AS Table
		|WHERE
		|	Table.Count = 0
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.EmptyRef)
		|	OR Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.EmptyRef)
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.InStock)
		|		AND Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
		|			VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked),
		|			VALUE(Enum.DemandCharacteristics.NotProvide))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.AvailablePendingUnlocking)
		|		AND Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.NotProvide))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking)
		|		AND Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply),
		|			VALUE(Enum.DemandCharacteristics.NotProvide))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock)
		|		AND Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
		|			VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked),
		|			VALUE(Enum.DemandCharacteristics.NotProvide))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock)
		|		AND Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
		|			VALUE(Enum.DemandCharacteristics.NotProvide))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking)
		|		AND Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply),
		|			VALUE(Enum.DemandCharacteristics.NotProvide))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.PendingSupplyApproval)
		|		AND Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
		|			VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked),
		|			VALUE(Enum.DemandCharacteristics.NotProvide))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.NotProvided)
		|		AND Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
		|			VALUE(Enum.DemandCharacteristics.Surplus))

		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.InStock)
		|		AND NOT(
		|			Table.ReceiptOrder = UNDEFINED
		|			AND Table.DateOfReceipt = DATETIME(1, 1, 1)
		|			AND Table.AvailabilityDate = DATETIME(1, 1, 1))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.AvailablePendingUnlocking)
		|		AND NOT(
		|			Table.ReceiptOrder <> UNDEFINED
		|			AND Table.DateOfReceipt = DATETIME(1, 1, 1)
		|			AND Table.AvailabilityDate <> DATETIME(1, 1, 1))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking)
		|		AND NOT(
		|			Table.ReceiptOrder <> UNDEFINED
		|			AND Table.DateOfReceipt = DATETIME(1, 1, 1)
		|			AND Table.AvailabilityDate = DATETIME(1, 1, 1))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock)
		|		AND NOT(
		|			Table.ReceiptOrder <> UNDEFINED
		|			AND Table.DateOfReceipt <> DATETIME(1, 1, 1)
		|			AND Table.AvailabilityDate <> DATETIME(1, 1, 1))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock)
		|		AND NOT(
		|			Table.ReceiptOrder <> UNDEFINED
		|			AND Table.DateOfReceipt <> DATETIME(1, 1, 1)
		|			AND Table.AvailabilityDate <> DATETIME(1, 1, 1))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking)
		|		AND NOT(
		|			Table.ReceiptOrder <> UNDEFINED
		|			AND Table.DateOfReceipt <> DATETIME(1, 1, 1)
		|			AND Table.AvailabilityDate = DATETIME(1, 1, 1))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.PendingSupplyApproval)
		|		AND NOT(
		|			Table.ReceiptOrder <> UNDEFINED
		|			AND Table.DateOfReceipt = DATETIME(1, 1, 1)
		|			AND Table.AvailabilityDate = DATETIME(1, 1, 1))
		|	OR Table.InventoryState = VALUE(Enum.InventoryStates.NotProvided)
		|		AND NOT(
		|			Table.ReceiptOrder = UNDEFINED
		|			AND Table.DateOfReceipt = DATETIME(1, 1, 1)
		|			AND Table.AvailabilityDate = DATETIME(1, 1, 1))

		|	OR Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked),
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|			VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked),
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply),
		|			VALUE(Enum.DemandCharacteristics.NotProvide))
		|		AND Table.ShipmentOrder = UNDEFINED
		|
		|	OR Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.Surplus)
		|		AND Table.ShipmentOrder <> UNDEFINED";
	
	#EndRegion
	
	Texts.Add(Text);
	Query.SetParameter("TextRecordingFormatIsBroken", NStr("ru = 'Нарушен формат записи';
															|vi = 'Record format is incorrect';
															|en = 'Record format is incorrect'; fa = 'Record format is incorrect';
															|it = 'Record format is incorrect';
															|pl = 'Record format is incorrect';
															|tr = 'Kayıt formatı hatalı'"));
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Package = Query.ExecuteBatch();
	Return Package;
	
EndFunction

#EndRegion

#Region Private

Function CalculationTextAvailableGoodsBalances()
	
	Text =
		"SELECT DISTINCT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse
		|INTO VariousProductsWithoutAppointments
		|FROM
		|	InventoryDistributionProductsOverridable AS Goods
		|WHERE
		|	Goods.Products.ItemsType IN(
		|		VALUE(Enum.ItemsTypes.OwnGoods),
		|		VALUE(Enum.ItemsTypes.ReusablePackage))
		|	AND Goods.Warehouse <> UNDEFINED
		|	AND Goods.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////
		|SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Inventories.InStockBalance AS InStock
		|INTO AvailableForAllPurposes
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse) IN(
		|			SELECT
		|				Goods.Products AS Products,
		|				Goods.Characteristic AS Characteristic,
		|				Goods.Warehouse AS Warehouse
		|			FROM
		|				VariousProductsWithoutAppointments AS Goods)) AS Inventories
		|
		|UNION ALL
		|
		|SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.OrderDocument AS ControlledLotReference,
		|	Inventories.LockedInStockBalance AS InStock
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		OrderDocument <> UNDEFINED
		|			AND OrderDocument <> VALUE(Catalog.ControlledLots.EmptyRef)
		|			AND VALUETYPE(OrderDocument) = TYPE(Catalog.ControlledLots)
		|			AND (Products, Characteristic, Warehouse) IN(
		|				SELECT
		|					Goods.Products AS Products,
		|					Goods.Characteristic AS Characteristic,
		|					Goods.Warehouse AS Warehouse
		|				FROM
		|					VariousProductsWithoutAppointments AS Goods)) AS Inventories
		|;
		|
		|////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Warehouse AS Warehouse
		|INTO VariousProductsWithDestinations
		|FROM
		|	InventoryDistributionProductsOverridable AS Goods
		|WHERE
		|	CAST(Goods.Purpose AS Catalog.Assignments).OrderDocument = UNDEFINED
		|		AND CAST(Goods.Purpose AS Catalog.Assignments).LineOfBusiness
		|			<> VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	AND Goods.Products.ItemsType IN(
		|		VALUE(Enum.ItemsTypes.OwnGoods),
		|		VALUE(Enum.ItemsTypes.ReusablePackage))
		|	AND Goods.Warehouse <> UNDEFINED
		|	AND Goods.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	Goods.Warehouse AS Warehouse
		|FROM
		|	VariousProductsWithoutAppointments AS Goods
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////
		|SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Inventories.InStockBalance
		|		- Inventories.LockedInStockBalance AS InStock,
		|	CASE
		|		WHEN
		|			Inventories.InStockBalance
		|				- Inventories.LockedInStockBalance
		|				- Inventories.ReserveAtWarehouseBalance < 0
		|			THEN
		|				Inventories.InStockBalance
		|					- Inventories.LockedInStockBalance
		|					- Inventories.ReserveAtWarehouseBalance
		|		WHEN Inventories.InStockBalance
		|				- Inventories.LockedInStockBalance
		|				- Inventories.ReserveAtWarehouseBalance
		|				- Inventories.ReserveAsReceivedBalance > 0
		|			THEN
		|				Inventories.InStockBalance
		|				- Inventories.LockedInStockBalance
		|				- Inventories.ReserveAtWarehouseBalance
		|				- Inventories.ReserveAsReceivedBalance
		|		ELSE 0
		|	END AS Available
		|INTO AvailableByAppointment
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Goods.Products AS Products,
		|				Goods.Characteristic AS Characteristic,
		|				Goods.Warehouse AS Warehouse,
		|				Goods.Purpose AS Purpose
		|			FROM
		|				VariousProductsWithDestinations AS Goods)) AS Inventories
		|
		|UNION ALL
		|
		|SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS ControlledLotReference,
		|	Inventories.LockedInStockBalance AS InStock,
		|	CASE
		|		WHEN
		|			Inventories.LockedInStockBalance
		|				- Inventories.ReserveAtWarehouseFromLockedBalance < 0
		|			THEN
		|				Inventories.LockedInStockBalance
		|					- Inventories.ReserveAtWarehouseFromLockedBalance
		|		WHEN Inventories.LockedInStockBalance
		|				- Inventories.ReserveAtWarehouseFromLockedBalance
		|				- Inventories.ReserveUponReceiptFromLockedBalance > 0
		|			THEN
		|				Inventories.LockedInStockBalance
		|				- Inventories.ReserveAtWarehouseFromLockedBalance
		|				- Inventories.ReserveUponReceiptFromLockedBalance 
		|		ELSE 0
		|	END AS Available
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		OrderDocument <> UNDEFINED
		|			AND OrderDocument <> VALUE(Catalog.ControlledLots.EmptyRef)
		|			AND VALUETYPE(OrderDocument) = TYPE(Catalog.ControlledLots)
		|			AND (Products, Characteristic, Warehouse, Purpose) IN(
		|				SELECT
		|					Goods.Products AS Products,
		|					Goods.Characteristic AS Characteristic,
		|					Goods.Warehouse AS Warehouse,
		|					Goods.Purpose AS Purpose
		|				FROM
		|					VariousProductsWithDestinations AS Goods)) AS Inventories
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	AvailableForAllPurposes.ControlledLotReference AS ControlledLotReference,
		|	AvailableForAllPurposes.InStock AS InStock,
		|	CASE
		|		WHEN AvailableForAllPurposes.InStock = 0
		|			THEN 0
		|		ELSE ISNULL(AvailableByAppointment.Available, 0)
		|	END AS Available
		|INTO RegisterDataForCalculatingAvailableItemBalances
		|FROM
		|	VariousProductsWithDestinations AS Goods
		|		LEFT JOIN AvailableForAllPurposes AS AvailableForAllPurposes
		|		ON AvailableForAllPurposes.Products = Goods.Products
		|		 AND AvailableForAllPurposes.Characteristic = Goods.Characteristic
		|		 AND AvailableForAllPurposes.Warehouse = Goods.Warehouse
		|		LEFT JOIN AvailableByAppointment AS AvailableByAppointment
		|		ON AvailableByAppointment.Products = Goods.Products
		|		 AND AvailableByAppointment.Characteristic = Goods.Characteristic
		|		 AND AvailableByAppointment.Warehouse = Goods.Warehouse
		|		 AND AvailableByAppointment.Purpose = Goods.Purpose
		|		 AND AvailableByAppointment.ControlledLotReference = AvailableForAllPurposes.ControlledLotReference
		|WHERE
		|	Goods.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|		AND NOT AvailableForAllPurposes.ControlledLotReference IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	AvailableByAppointment.ControlledLotReference AS ControlledLotReference,
		|	AvailableByAppointment.InStock AS InStock,
		|	CASE
		|		WHEN AvailableByAppointment.InStock = 0
		|			THEN 0
		|		ELSE AvailableByAppointment.Available
		|	END AS Available
		|FROM
		|	VariousProductsWithDestinations AS Goods
		|		LEFT JOIN AvailableByAppointment AS AvailableByAppointment
		|		ON AvailableByAppointment.Products = Goods.Products
		|		 AND AvailableByAppointment.Characteristic = Goods.Characteristic
		|		 AND AvailableByAppointment.Warehouse = Goods.Warehouse
		|		 AND AvailableByAppointment.Purpose = Goods.Purpose
		|WHERE
		|	Goods.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|		AND NOT AvailableByAppointment.ControlledLotReference IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	AvailableStockBalances.ControlledLotReference AS ControlledLotReference,
		|	0 AS InStock,
		|	0 AS Available
		|FROM
		|	VariousProductsWithDestinations AS Goods
		|		INNER JOIN InformationRegister.AvailableStockBalances AS AvailableStockBalances
		|		ON AvailableStockBalances.Products = Goods.Products
		|		 AND AvailableStockBalances.Characteristic = Goods.Characteristic
		|		 AND AvailableStockBalances.Warehouse = Goods.Warehouse
		|		 AND AvailableStockBalances.Purpose = Goods.Purpose
		|WHERE
		|	Goods.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|	AND NOT TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS ThereAreRecords
		|		FROM
		|			AvailableForAllPurposes AS Table
		|		WHERE
		|			Table.Products = AvailableStockBalances.Products
		|			AND Table.Characteristic = AvailableStockBalances.Characteristic
		|			AND Table.Warehouse = AvailableStockBalances.Warehouse
		|			AND Table.ControlledLotReference = AvailableStockBalances.ControlledLotReference)
		|
		|UNION ALL
		|
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	AvailableStockBalances.ControlledLotReference AS ControlledLotReference,
		|	0 AS InStock,
		|	0 AS Available
		|FROM
		|	VariousProductsWithDestinations AS Goods
		|		INNER JOIN InformationRegister.AvailableStockBalances AS AvailableStockBalances
		|		ON AvailableStockBalances.Products = Goods.Products
		|		 AND AvailableStockBalances.Characteristic = Goods.Characteristic
		|		 AND AvailableStockBalances.Warehouse = Goods.Warehouse
		|		 AND AvailableStockBalances.Purpose = Goods.Purpose
		|WHERE
		|	Goods.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|	AND NOT TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS ThereAreRecords
		|		FROM
		|			AvailableByAppointment AS Table
		|		WHERE
		|			Table.Products = AvailableStockBalances.Products
		|			AND Table.Characteristic = AvailableStockBalances.Characteristic
		|			AND Table.Warehouse = AvailableStockBalances.Warehouse
		|			AND Table.Purpose = AvailableStockBalances.Purpose
		|			AND Table.ControlledLotReference = AvailableStockBalances.ControlledLotReference)
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|DROP AvailableForAllPurposes;
		|DROP AvailableByAppointment;
		|DROP VariousProductsWithoutAppointments;
		|DROP VariousProductsWithDestinations";
		
	Return Text;
	
EndFunction

Procedure TempTablesOfRegisterData(Query, NameOfProductsTable, RegisterNames, NameOfDocumentRegistryTable, NameOfAdjustmentTable)
	
	Texts = New Array();
	
	If StrFind(RegisterNames, "AvailableStockBalances") > 0 Then
		Text = CalculationTextAvailableGoodsBalances();
		Texts.Add(Text);
	EndIf;
	
	If StrFind(RegisterNames, "InventoryAllocation") > 0 Then
		Text =
			"SELECT
			|	Inventories.Products AS Products,
			|	Inventories.Characteristic AS Characteristic,
			|	Inventories.Warehouse AS Warehouse,
			|	Inventories.Purpose AS Purpose,
			|	Inventories.OrderDocument AS OrderDocument,
			|	Inventories.EventDate AS EventDate,
			|	Inventories.InStockBalance AS InStock,
			|	Inventories.Received_1Balance AS Received_1,
			|	Inventories.OrderedBalance AS Ordered,
			|	Inventories.LockedInStockBalance AS LockedInStock,
			|	Inventories.LockedReceiptBalance AS LockedReceipt,
			|	Inventories.ToUnlockBalance AS ToUnlock
			|INTO Inventories
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(,
			|		(Products, Characteristic, Warehouse, Purpose) IN(
			|			SELECT
			|				Goods.Products AS Products,
			|				Goods.Characteristic AS Characteristic,
			|				Goods.Warehouse AS Warehouse,
			|				Goods.Purpose AS Purpose
			|			FROM
			|				InventoryDistributionProductsOverridable AS Goods)) AS Inventories";
		
		AddTextOfInventoryAdjustmentRequest(Text, "INTO Inventories", NameOfAdjustmentTable);
		AddIndex(Text, "Products, Characteristic, Warehouse, Purpose");
		Texts.Add(Text);
		
		Text =
			"SELECT
			|	Demands.Products AS Products,
			|	Demands.Characteristic AS Characteristic,
			|	Demands.Warehouse AS Warehouse,
			|	Demands.Purpose AS Purpose,
			|	Demands.OrderDocument AS OrderDocument,
			|	Demands.EventDate AS EventDate,
			|	CASE
			|		WHEN Demands.ReserveAtWarehouseBalance > 0
			|			THEN Demands.ReserveAtWarehouseBalance
			|		ELSE 0
			|	END AS ReserveAtWarehouse,
			|	CASE
			|		WHEN Demands.ReserveAsReceivedBalance > 0
			|			THEN Demands.ReserveAsReceivedBalance
			|		ELSE 0
			|	END AS ReserveAsReceived,
			|	CASE
			|		WHEN Demands.SnoozeReservationBalance > 0
			|			THEN Demands.SnoozeReservationBalance
			|		ELSE 0
			|	END AS SnoozeReservation,
			|	CASE
			|		WHEN Demands.ToSupplyBalance > 0
			|			THEN Demands.ToSupplyBalance
			|		ELSE 0
			|	END AS ToSupply,
			|	CASE
			|		WHEN Demands.NotProvideBalance > 0
			|			THEN Demands.NotProvideBalance
			|		ELSE 0
			|	END AS NotProvide,
			|	CASE
			|		WHEN Demands.ReserveAtWarehouseFromLockedBalance > 0
			|			THEN Demands.ReserveAtWarehouseFromLockedBalance
			|		ELSE 0
			|	END AS ReserveAtWarehouseFromLocked,
			|	CASE
			|		WHEN Demands.ReserveUponReceiptFromLockedBalance > 0
			|			THEN Demands.ReserveUponReceiptFromLockedBalance
			|		ELSE 0
			|	END AS ReserveUponReceiptFromLocked
			|INTO Demands
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(,
			|		(Products, Characteristic, Warehouse, Purpose) IN(
			|			SELECT
			|				Goods.Products AS Products,
			|				Goods.Characteristic AS Characteristic,
			|				Goods.Warehouse AS Warehouse,
			|				Goods.Purpose AS Purpose
			|			FROM
			|				InventoryDistributionProductsOverridable AS Goods)) AS Demands
			|WHERE
			|	Demands.ReserveAtWarehouseBalance > 0
			|		OR Demands.ReserveAsReceivedBalance > 0
			|		OR Demands.SnoozeReservationBalance > 0
			|		OR Demands.ToSupplyBalance > 0
			|		OR Demands.NotProvideBalance > 0
			|		OR Demands.ReserveAtWarehouseFromLockedBalance > 0
			|		OR Demands.ReserveUponReceiptFromLockedBalance > 0";
		
		AddQueryTextToNeedsAdjustment(Text, "INTO Demands", NameOfAdjustmentTable);
		AddIndex(Text, "Products, Characteristic, Warehouse, Purpose, OrderDocument");
		Texts.Add(Text);
		
		Text =
			"SELECT
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.Warehouse AS Warehouse,
			|	Table.Purpose AS Purpose,
			|	SUM(Table.ReserveAtWarehouse) AS ReserveAtWarehouse
			|INTO ProductNeeds
			|FROM
			|	Demands AS Table
			|GROUP BY
			|	Table.Products,
			|	Table.Characteristic,
			|	Table.Warehouse,
			|	Table.Purpose
			|HAVING
			|	SUM(Table.ReserveAtWarehouse) > 0
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose";
		Texts.Add(Text);
		
		Text =
			"SELECT DISTINCT
			|	Demands.OrderDocument AS OrderDocument,
			|	CASE
			|		WHEN VALUETYPE(Demands.OrderDocument) = TYPE(Document.ProductionStage2_2)
			|			THEN CAST(Demands.OrderDocument AS Document.ProductionStage2_2).ReferenceOrder.Date
			|		WHEN TRUE
			|			THEN NULL
			|	END AS ReferenceDate
			|INTO NeedsDifferentOrders
			|FROM
			|	Demands AS Demands
			|INDEX BY
			|	OrderDocument
			|;
			|
			|///////////////////////////////////////
			|SELECT
			|	ReportOrders.Ref AS Ref,
			|	MIN(ReportOrders.Priority) AS Priority,
			|	MIN(ISNULL(Table.ReferenceDate, ReportOrders.IBDocumentDate)) AS IBDocumentDate
			|INTO ReportOrdersTable
			|FROM
			|	NeedsDifferentOrders Table
			|		INNER JOIN DocumentsRegistryOverridable AS ReportOrders
			|		ON ReportOrders.Ref = Table.OrderDocument
			|		AND NOT ReportOrders.AdditionalRecord
			|WHERE
			|	NOT ReportOrders.Ref IS NULL
			|GROUP BY
			|	ReportOrders.Ref
			|INDEX BY
			|	Ref
			|;
			|DROP NeedsDifferentOrders";
		If NameOfDocumentRegistryTable = Undefined Then
			NameOfDocumentRegistryTable = "InformationRegister.DocumentsRegistry";
		EndIf;
		Text = StrReplace(Text, "DocumentsRegistryOverridable", NameOfDocumentRegistryTable);
		Texts.Add(Text);
		
		Text =
			"SELECT
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Purpose AS Purpose
			|INTO GoodsWithCollateralControl
			|FROM
			|	InventoryDistributionProductsOverridable AS Goods
			|		
			|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpSecurityControlCharacteristic
			|		ON SettingUpSecurityControlCharacteristic.Warehouse = Goods.Warehouse
			|		 AND SettingUpSecurityControlCharacteristic.Products = Goods.Products
			|		 AND SettingUpSecurityControlCharacteristic.Characteristic = Goods.Characteristic
			|		
			|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SettingUpControlAndProducts
			|		ON SettingUpControlAndProducts.Warehouse = Goods.Warehouse
			|		 AND SettingUpControlAndProducts.Products = Goods.Products
			|		 AND SettingUpControlAndProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		
			|		LEFT JOIN InformationRegister.SetUpSupplyControl AS SetUpSupplyControl
			|		ON SetUpSupplyControl.Warehouse = Goods.Warehouse
			|		 AND SetUpSupplyControl.Products = VALUE(Catalog.Products.EmptyRef)
			|		 AND SetUpSupplyControl.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|		
			|WHERE
			|	ISNULL(SettingUpSecurityControlCharacteristic.AvailableStockControl,
			|				ISNULL(SettingUpControlAndProducts.AvailableStockControl,
			|					ISNULL(SetUpSupplyControl.AvailableStockControl, FALSE)))
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose";
			
		Texts.Add(Text);
		
		Text =
			"SELECT
			|	InformationRecords.Products AS Products,
			|	InformationRecords.Characteristic AS Characteristic,
			|	InformationRecords.Warehouse AS Warehouse,
			|	InformationRecords.Purpose AS Purpose,
			|	InformationRecords.ShipmentOrder AS OrderDocument,
			|	CASE
			|		WHEN
			|			SUM(CASE
			|					WHEN InformationRecords.InventoryState = VALUE(Enum.InventoryStates.InStock)
			|						THEN InformationRecords.Count
			|					ELSE 0
			|				END) < MAX(ISNULL(ShipmentFromOwnReserve.Shipment, 0))
			|			THEN 0
			|		ELSE
			|			SUM(CASE
			|					WHEN InformationRecords.InventoryState = VALUE(Enum.InventoryStates.InStock)
			|						THEN InformationRecords.Count
			|					ELSE 0
			|				END) - MAX(ISNULL(ShipmentFromOwnReserve.Shipment, 0))
			|	END AS InStock,
			|	SUM(CASE
			|		WHEN InformationRecords.InventoryState = VALUE(Enum.InventoryStates.AvailablePendingUnlocking)
			|			THEN InformationRecords.Count
			|		ELSE 0
			|	END) AS AvailablePendingUnlocking
			|INTO StocksDistributedEarlier
			|FROM
			|	GoodsWithCollateralControl AS Goods
			|		
			|		INNER JOIN InformationRegister.InventoryAllocation AS InformationRecords
			|		ON InformationRecords.Products = Goods.Products
			|		 AND InformationRecords.Characteristic = Goods.Characteristic
			|		 AND InformationRecords.Warehouse = Goods.Warehouse
			|		 AND InformationRecords.Purpose = Goods.Purpose
			|		 AND InformationRecords.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAsReceived)
			|		 AND InformationRecords.InventoryState IN(
			|			VALUE(Enum.InventoryStates.InStock),
			|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking))
			|		
			|		LEFT JOIN ChangingBalanceOfGoodsToControlBalance AS ShipmentFromOwnReserve
			|		ON ShipmentFromOwnReserve.Products = InformationRecords.Products
			|		 AND ShipmentFromOwnReserve.Characteristic = InformationRecords.Characteristic
			|		 AND ShipmentFromOwnReserve.Warehouse = InformationRecords.Warehouse
			|		 AND ShipmentFromOwnReserve.Purpose = InformationRecords.Purpose
			|		 AND ShipmentFromOwnReserve.ShipmentOrder = InformationRecords.ShipmentOrder
	 		|GROUP BY
			|	InformationRecords.Products,
			|	InformationRecords.Characteristic,
			|	InformationRecords.Warehouse,
			|	InformationRecords.Purpose,
			|	InformationRecords.ShipmentOrder
			|INDEX BY
			|	Products, Characteristic, Warehouse, Purpose, OrderDocument";
			
		If Not InfobaseUpdate.ObjectProcessed("InformationRegister.InventoryAllocation").Processed Then
			
			Text =
				"SELECT
				|	InformationRecords.Products AS Products,
				|	InformationRecords.Characteristic AS Characteristic,
				|	InformationRecords.Warehouse AS Warehouse,
				|	InformationRecords.Purpose AS Purpose,
				|	InformationRecords.ShipmentOrder AS OrderDocument,
				|	CASE
				|		WHEN
				|			SUM(CASE
				|					WHEN InformationRecords.InventoryState = VALUE(Enum.InventoryStates.InStock)
				|						THEN InformationRecords.Count
				|					ELSE 0
				|				END) < MAX(ISNULL(InformationRecords.Shipment, 0))
				|			THEN 0
				|		ELSE
				|			SUM(CASE
				|					WHEN InformationRecords.InventoryState = VALUE(Enum.InventoryStates.InStock)
				|						THEN InformationRecords.Count
				|					ELSE 0
				|				END) - MAX(ISNULL(InformationRecords.Shipment, 0))
				|	END AS InStock,
				|	SUM(CASE
				|		WHEN InformationRecords.InventoryState = VALUE(Enum.InventoryStates.AvailablePendingUnlocking)
				|			THEN InformationRecords.Count
				|		ELSE 0
				|	END) AS AvailablePendingUnlocking
				|INTO StocksDistributedEarlier
				|FROM(
				|	SELECT
				|		InformationRecords.Products AS Products,
				|		InformationRecords.Characteristic AS Characteristic,
				|		InformationRecords.Warehouse AS Warehouse,
				|		InformationRecords.Purpose AS Purpose,
				|		InformationRecords.ShipmentOrder AS ShipmentOrder,
				|		InformationRecords.InventoryState AS InventoryState,
				|		InformationRecords.Count AS Count,
				|		ShipmentFromOwnReserve.Shipment AS Shipment
				|	FROM
				|		GoodsWithCollateralControl AS Goods
				|		
				|		INNER JOIN InformationRegister.InventoryAllocation AS InformationRecords
				|		ON InformationRecords.Products = Goods.Products
				|		 AND InformationRecords.Characteristic = Goods.Characteristic
				|		 AND InformationRecords.Warehouse = Goods.Warehouse
				|		 AND InformationRecords.Purpose = Goods.Purpose
				|		 AND InformationRecords.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAsReceived)
				|		 AND InformationRecords.InventoryState IN(
				|			VALUE(Enum.InventoryStates.InStock),
				|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking))
				|		
				|		LEFT JOIN ChangingBalanceOfGoodsToControlBalance AS ShipmentFromOwnReserve
				|		ON ShipmentFromOwnReserve.Products = InformationRecords.Products
				|		 AND ShipmentFromOwnReserve.Characteristic = InformationRecords.Characteristic
				|		 AND ShipmentFromOwnReserve.Warehouse = InformationRecords.Warehouse
				|		 AND ShipmentFromOwnReserve.Purpose = InformationRecords.Purpose
				|		 AND ShipmentFromOwnReserve.ShipmentOrder = InformationRecords.ShipmentOrder
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		InformationRecords.Products AS Products,
				|		InformationRecords.Characteristic AS Characteristic,
				|		InformationRecords.Warehouse AS Warehouse,
				|		InformationRecords.Purpose AS Purpose,
				|		InformationRecords.ShipmentOrder AS ShipmentOrder,
				|		VALUE(Enum.InventoryStates.InStock) AS InventoryState,
				|		InformationRecords.DeleteReserved AS Count,
				|		ShipmentFromOwnReserve.Shipment AS Shipment
				|	FROM
				|		GoodsWithCollateralControl AS Goods
				|		
				|		INNER JOIN InformationRegister.InventoryAllocation AS InformationRecords
				|		ON InformationRecords.Products = Goods.Products
				|		 AND InformationRecords.Characteristic = Goods.Characteristic
				|		 AND InformationRecords.Warehouse = Goods.Warehouse
				|		 AND InformationRecords.Purpose = Goods.Purpose
				|		 AND InformationRecords.DeleteAState = VALUE(Enum.InventoryAllocationStates.ReservedUponReceipt)
				|		
				|		LEFT JOIN ChangingBalanceOfGoodsToControlBalance AS ShipmentFromOwnReserve
				|		ON ShipmentFromOwnReserve.Products = InformationRecords.Products
				|		 AND ShipmentFromOwnReserve.Characteristic = InformationRecords.Characteristic
				|		 AND ShipmentFromOwnReserve.Warehouse = InformationRecords.Warehouse
				|		 AND ShipmentFromOwnReserve.Purpose = InformationRecords.Purpose
				|		 AND ShipmentFromOwnReserve.ShipmentOrder = InformationRecords.ShipmentOrder) AS InformationRecords
				|GROUP BY
				|	InformationRecords.Products,
				|	InformationRecords.Characteristic,
				|	InformationRecords.Warehouse,
				|	InformationRecords.Purpose,
				|	InformationRecords.ShipmentOrder
				|INDEX BY
				|	Products, Characteristic, Warehouse, Purpose, OrderDocument";
			
		EndIf;
		Texts.Add(Text);
		
		Text =
			"SELECT
			|	Table.Products AS Products,
			|	Table.Characteristic AS Characteristic,
			|	Table.Warehouse AS Warehouse,
			|	Table.Purpose AS Purpose,
			|	Table.OrderDocument AS OrderDocument,
			|	Table.EventDate AS EventDate,
			|	Table.ReserveAsReceived AS ReserveAsReceived,
			|	ISNULL(PreviouslyDistributed.InStock, 0) AS InStock,
			|	ISNULL(PreviouslyDistributed.AvailablePendingUnlocking, 0) AS AvailablePendingUnlocking
			|INTO ReserveRequirementsAsTheyBecomeAvailableAndInventoryDistributedEarlier
			|FROM
			|	Demands AS Table
			|		
			|		LEFT JOIN StocksDistributedEarlier AS PreviouslyDistributed
			|		ON PreviouslyDistributed.Products = Table.Products
			|		 AND PreviouslyDistributed.Characteristic = Table.Characteristic
			|		 AND PreviouslyDistributed.Warehouse = Table.Warehouse
			|		 AND PreviouslyDistributed.Purpose = Table.Purpose
			|		 AND PreviouslyDistributed.OrderDocument = Table.OrderDocument
			|WHERE
			|	Table.ReserveAsReceived > 0
			|INDEX BY
			|	OrderDocument,Products,Characteristic,Warehouse,Purpose
			|;
			|
			|//////////////////////////////////////////////////////
			|DROP GoodsWithCollateralControl";
		Texts.Add(Text);
		
	EndIf;
	
	Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.Text = StrReplace(Text, "InventoryDistributionProductsOverridable", NameOfProductsTable);
	Query.ExecuteBatch();
	
EndProcedure

Procedure AddTextOfInventoryAdjustmentRequest(Text, TextOfPlacementInTable, NameOfAdjustmentTable)
	
	If NameOfAdjustmentTable = Undefined Then
		Return;
	EndIf;
	
	Text = StrReplace(Text, TextOfPlacementInTable, "");
	Texts = New Array();
	Texts.Add(Text);
	Text =
		"SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.EventDate AS EventDate,
		|	0 AS InStock,
		|	Inventories.Received_1 AS Received_1,
		|	Inventories.Ordered AS Ordered,
		|	Inventories.LockedInStock AS LockedInStock,
		|	Inventories.LockedReceipt AS LockedReceipt,
		|	Inventories.ToUnlock AS ToUnlock
		|FROM
		|	CorrectionOfRegisteredRecordsOverridable AS Inventories
		|		INNER JOIN InventoryDistributionProductsOverridable AS Filter
		|		ON Filter.Products = Inventories.Products
		|		 AND Filter.Characteristic = Inventories.Characteristic
		|		 AND Filter.Warehouse = Inventories.Warehouse
		|		 AND Filter.Purpose = Inventories.Purpose";
	Text = StrReplace(Text, "CorrectionOfRegisteredRecordsOverridable", NameOfAdjustmentTable);
	Texts.Add(Text);
	Text =
		"SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	UNDEFINED AS OrderDocument,
		|	Inventories.EventDate AS EventDate,
		|	Inventories.InStock AS InStock,
		|	0 AS Received_1,
		|	0 AS Ordered,
		|	0 AS LockedInStock,
		|	0 AS LockedReceipt,
		|	0 AS ToUnlock
		|FROM
		|	CorrectionOfRegisteredRecordsOverridable AS Inventories
		|		INNER JOIN InventoryDistributionProductsOverridable AS Filter
		|		ON Filter.Products = Inventories.Products
		|		 AND Filter.Characteristic = Inventories.Characteristic
		|		 AND Filter.Warehouse = Inventories.Warehouse
		|		 AND Filter.Purpose = Inventories.Purpose";
	Text = StrReplace(Text, "CorrectionOfRegisteredRecordsOverridable", NameOfAdjustmentTable);
	Texts.Add(Text);
	TextOfSet = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
	
	Text =
		"SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.EventDate AS EventDate,
		|	SUM(Inventories.InStock) AS InStock,
		|	SUM(Inventories.Received_1) AS Received_1,
		|	SUM(Inventories.Ordered) AS Ordered,
		|	SUM(Inventories.LockedInStock) AS LockedInStock,
		|	SUM(Inventories.LockedReceipt) AS LockedReceipt,
		|	SUM(Inventories.ToUnlock) AS ToUnlock
		|INTO TableOverridable
		|FROM
		|	SetOverridable AS Inventories
		|GROUP BY
		|	Inventories.Products,
		|	Inventories.Characteristic,
		|	Inventories.Warehouse,
		|	Inventories.Purpose,
		|	Inventories.OrderDocument,
		|	Inventories.EventDate
		|HAVING
		|	SUM(Inventories.InStock) > 0
		|		OR SUM(Inventories.Received_1) > 0
		|		OR SUM(Inventories.Ordered) > 0
		|		OR SUM(Inventories.LockedInStock) > 0
		|		OR SUM(Inventories.LockedReceipt) > 0
		|		OR SUM(Inventories.ToUnlock) > 0";
	Text = StrReplace(Text, "SetOverridable", StrTemplate("(%1)", TextOfSet));
	Text = StrReplace(Text, "INTO TableOverridable", TextOfPlacementInTable);
	
EndProcedure

Procedure AddQueryTextToNeedsAdjustment(Text, TextOfPlacementInTable, NameOfAdjustmentTable)
	
	If NameOfAdjustmentTable = Undefined Then
		Return;
	EndIf;
	
	Text = StrReplace(Text, TextOfPlacementInTable, "");
	Texts = New Array();
	Texts.Add(Text);
	Text =
		"SELECT
		|	Demands.Products AS Products,
		|	Demands.Characteristic AS Characteristic,
		|	Demands.Warehouse AS Warehouse,
		|	Demands.Purpose AS Purpose,
		|	Demands.OrderDocument AS OrderDocument,
		|	Demands.EventDate AS EventDate,
		|	Demands.ReserveAtWarehouse AS ReserveAtWarehouse,
		|	Demands.ReserveAsReceived AS ReserveAsReceived,
		|	Demands.SnoozeReservation AS SnoozeReservation,
		|	Demands.ToSupply AS ToSupply,
		|	Demands.NotProvide AS NotProvide,
		|	Demands.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
		|	Demands.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked
		|FROM
		|	CorrectionOfRegisteredRecordsOverridable AS Demands
		|		INNER JOIN InventoryDistributionProductsOverridable AS Filter
		|		ON Filter.Products = Demands.Products
		|		 AND Filter.Characteristic = Demands.Characteristic
		|		 AND Filter.Warehouse = Demands.Warehouse
		|		 AND Filter.Purpose = Demands.Purpose";
	Text = StrReplace(Text, "CorrectionOfRegisteredRecordsOverridable", NameOfAdjustmentTable);
	Texts.Add(Text);
	
	TextOfSet = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
	Text =
		"SELECT
		|	Demands.Products AS Products,
		|	Demands.Characteristic AS Characteristic,
		|	Demands.Warehouse AS Warehouse,
		|	Demands.Purpose AS Purpose,
		|	Demands.OrderDocument AS OrderDocument,
		|	Demands.EventDate AS EventDate,
		|	SUM(Demands.ReserveAtWarehouse) AS ReserveAtWarehouse,
		|	SUM(Demands.ReserveAsReceived) AS ReserveAsReceived,
		|	SUM(Demands.SnoozeReservation) AS SnoozeReservation,
		|	SUM(Demands.ToSupply) AS ToSupply,
		|	SUM(Demands.NotProvide) AS NotProvide,
		|	SUM(Demands.ReserveAtWarehouseFromLocked) AS ReserveAtWarehouseFromLocked,
		|	SUM(Demands.ReserveUponReceiptFromLocked) AS ReserveUponReceiptFromLocked
		|INTO TableOverridable
		|FROM
		|	SetOverridable AS Demands
		|GROUP BY
		|	Demands.Products,
		|	Demands.Characteristic,
		|	Demands.Warehouse,
		|	Demands.Purpose,
		|	Demands.OrderDocument,
		|	Demands.EventDate
		|HAVING
		|	SUM(Demands.ReserveAtWarehouse) > 0
		|		OR SUM(Demands.ReserveAsReceived) > 0
		|		OR SUM(Demands.SnoozeReservation) > 0
		|		OR SUM(Demands.ToSupply) > 0
		|		OR SUM(Demands.NotProvide) > 0
		|		OR SUM(Demands.ReserveAtWarehouseFromLocked) > 0
		|		OR SUM(Demands.ReserveUponReceiptFromLocked) > 0";
	Text = StrReplace(Text, "SetOverridable", StrTemplate("(%1)", TextOfSet));
	Text = StrReplace(Text, "INTO TableOverridable", TextOfPlacementInTable);
	
EndProcedure

Procedure AddIndex(Text, Fields)
	
	IndexedTexts = New Array();
	IndexedTexts.Add(Text);
	Text =
		"INDEX BY
		|	Fields"; //@Query-part
	IndexedTexts.Add(StrReplace(Text, "Fields", Fields));
	Text = StrConcat(IndexedTexts, Chars.LF);
	
EndProcedure

Procedure AddTempTableOfInventoryBlocked(Query)
	
	Query.Text =
		"SELECT
		|	0 AS RecordType,
		|	0 AS RecordKind,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS OrderDocument,
		|	Table.EventDate AS DateOfReceipt,
		|	DATETIME(1, 1, 1) AS AvailabilityDate,
		|	Table.EventDate AS EventDate,
		|	Table.LockedInStock AS Count,
		|	Table.LockedInStock AS OriginalQuantity,
		|	0 AS QuantityIsAllocated,
		|	FALSE AS IsEmpty
		|FROM
		|	Inventories AS Table
		|WHERE
			// We eliminate incorrect movements where the date is not empty (so as not to group data).
		|	Table.EventDate = DATETIME(1, 1, 1)
		|		AND Table.LockedInStock <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	0 AS RecordType,
		|	1 AS RecordKind,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS OrderDocument,
		|	Table.EventDate AS DateOfReceipt,
		|	DATETIME(1, 1, 1) AS AvailabilityDate,
		|	Table.EventDate AS EventDate,
		|	Table.LockedReceipt AS Count,
		|	Table.LockedReceipt AS OriginalQuantity,
		|	0 AS QuantityIsAllocated,
		|	FALSE AS IsEmpty
		|FROM
		|	Inventories AS Table
		|WHERE
		|	Table.LockedReceipt > 0
		|
		|UNION ALL
		|
		|SELECT
		|	1 AS RecordType,
		|	0 AS RecordKind,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS OrderDocument,
		|	DATETIME(1, 1, 1) AS DateOfReceipt,
		|	Table.EventDate AS AvailabilityDate,
		|	Table.EventDate AS EventDate,
		|	Table.ToUnlock AS Count,
		|	Table.ToUnlock AS OriginalQuantity,
		|	0 AS QuantityIsAllocated,
		|	TRUE AS IsEmpty
		|FROM
		|	Inventories AS Table
		|WHERE
		|	Table.ToUnlock > 0
		|ORDER BY
		|	Products, Characteristic, Warehouse, Purpose, OrderDocument, RecordType, RecordKind, EventDate";
	
	Table = Query.Execute().Unload();
	Table.Columns.Add("Index1", New TypeDescription("Number")); // the first entry for the item
	Table.Columns.Add("IndexOf2", New TypeDescription("Number")); // the first entry To unlock the goods, -1 if there are no such entries.
	Table.Columns.Add("IndexOf3", New TypeDescription("Number")); // last item entry
	
	KeyFields = "Products,Characteristic,Warehouse,Purpose,OrderDocument";
	Var_Key = New Structure(KeyFields);
	TopIndex = Table.Count() - 1;
	For IndexOf = 0 To TopIndex Do
		
		Record = Table[IndexOf];
		If Var_Key.Products <> Record.Products
				Or Var_Key.Characteristic <> Record.Characteristic
				Or Var_Key.Warehouse <> Record.Warehouse
				Or Var_Key.Purpose <> Record.Purpose
				Or Var_Key.OrderDocument <> Record.OrderDocument Then
				
				FirstRecord = Record;
				FillPropertyValues(Var_Key, FirstRecord);
				FirstRecord.Index1 = IndexOf;
				FirstRecord.IndexOf2 = -1;
				
		EndIf;
		
		FirstRecord.IndexOf3 = IndexOf;
		
		If Record.RecordType = 1 And FirstRecord.IndexOf2 = -1 Then
			FirstRecord.IndexOf2 = IndexOf;
		EndIf;
		
	EndDo;
	
	// The result of the cycle:
	// Index1 is the first entry for the product.
	// Index3 - the last entry for the product.
	// Index2 - the first entry To be unblocked for the product, -1 if there are no such entries.
	
	IndexOf = 0;
	While IndexOf <= TopIndex Do
		
		Record = Table[IndexOf];
		If Record.IndexOf2 <> -1 And Record.Index1 < Record.IndexOf2 Then
			
			CurrentReceipt = Record.Index1;
			CurConsumption = Record.IndexOf2;
			
			RecordReceipt = Table[CurrentReceipt];
			RecordExpense = Table[CurConsumption];
			
			ConReceipt = Record.IndexOf2 - 1;
			ExpenseCon = Record.IndexOf3;
			
			While True Do
				
				While RecordExpense.Count = 0 And CurConsumption < ExpenseCon Do
					CurConsumption = CurConsumption + 1;
					RecordExpense = Table[CurConsumption];
				EndDo;
				If RecordExpense.Count = 0 Then
					Break;
				EndIf;
				
				While RecordReceipt.Count <= 0 And CurrentReceipt < ConReceipt Do
					CurrentReceipt = CurrentReceipt + 1;
					RecordReceipt = Table[CurrentReceipt];
				EndDo;
				If RecordReceipt.Count <= 0 Then
					Break;
				EndIf;
				
				If RecordReceipt.Count = RecordExpense.Count Then
					
					RecordExpense.Count = 0;
					NewRecord = RecordReceipt;
					
				ElsIf RecordReceipt.Count < RecordExpense.Count Then
					
					RecordExpense.Count = RecordExpense.Count - Max(RecordReceipt.Count, 0);
					NewRecord = RecordReceipt;
					
				Else // Record the arrival.Quantity > Recordspend.Quantity
					
					RecordReceipt.Count = RecordReceipt.Count - RecordExpense.Count;
					
					NewRecord = Table.Add();
					FillPropertyValues(NewRecord, RecordReceipt);
					NewRecord.Count = RecordExpense.Count;
					
					RecordExpense.Count = 0;
					
				EndIf;
				
				NewRecord.AvailabilityDate = RecordExpense.AvailabilityDate;
				NewRecord.QuantityIsAllocated = NewRecord.Count;
				NewRecord.Count = 0;
				
			EndDo;
			
		EndIf;
		
		IndexOf = Record.IndexOf3 + 1;
		
	EndDo;
	
	Query.Text =
		"SELECT
		|	CASE
		|		WHEN Table.RecordKind = 0 AND Table.Count < 0
		|			THEN VALUE(Enum.InventoryStates.AvailablePendingUnlocking)
		|		WHEN Table.RecordKind = 0 AND Table.Count > 0
		|			THEN VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking)
		|		WHEN Table.RecordKind = 0
		|			THEN VALUE(Enum.InventoryStates.AvailablePendingUnlocking)
		|		WHEN Table.RecordKind = 1 AND Table.Count > 0
		|			THEN VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking)
		|		ELSE VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock)
		|	END AS InventoryState,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS OrderDocument,
		|	Table.DateOfReceipt AS DateOfReceipt,
		|	Table.AvailabilityDate AS AvailabilityDate,
		|	CASE
		|		WHEN Table.Count <> 0
		|			THEN Table.Count
		|		ELSE Table.QuantityIsAllocated
		|	END AS Count
		|INTO InventoryBlocked
		|FROM
		|	&InventoryBlocked AS Table
		|WHERE
		|	NOT Table.IsEmpty";
	Query.SetParameter("InventoryBlocked", Table);
	Query.Execute();
	
EndProcedure

Function InventoryAllocationResult(Query, NameOfProductsTable, AllGoods, RegisterNames)
	
	#Region DataSelection
	
	InventoryAllocationResult = New Structure("InventoryAllocation,AvailableStockBalances");
	TextAvailableItemBalances =
		// Query texts for "Available goods Balances".
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.InStock AS InStock,
		|	Table.Available AS Available,
		|	NOT Analysts.Products IS NULL AS AnalyticsAreInCalculationTasks
		|FROM
		|	RegisterDataForCalculatingAvailableItemBalances AS Table
		|		LEFT JOIN NameOfProductsTable AS Analysts
		|		ON Analysts.Products = Table.Products
		|		 AND Analysts.Characteristic = Table.Characteristic
		|		 AND Analysts.Warehouse = Table.Warehouse
		|		 AND Analysts.Purpose = Table.Purpose
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	0 AS InStock,
		|	0 AS Available,
		|	TRUE AS AnalyticsAreInCalculationTasks
		|FROM
		|	NameOfProductsTable AS Table
		|WHERE
		|	NOT TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS ThereAreRecords
		|		FROM
		|			RegisterDataForCalculatingAvailableItemBalances AS Filter
		|		WHERE
		|			Filter.Products = Table.Products
		|			AND Filter.Characteristic = Table.Characteristic
		|			AND Filter.Warehouse = Table.Warehouse
		|			AND Filter.Purpose = Table.Purpose)
		|ORDER BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////
		|DROP RegisterDataForCalculatingAvailableItemBalances";
	TextAvailableItemBalances = StrReplace(TextAvailableItemBalances, "NameOfProductsTable", NameOfProductsTable);
	
	If StrFind(RegisterNames, "AvailableStockBalances") > 0 And StrFind(RegisterNames, "InventoryAllocation") = 0 Then
		
		Query.Text = TextAvailableItemBalances;
		InventoryAllocationResult.InventoryAllocation = Undefined;
		InventoryAllocationResult.AvailableStockBalances = Query.ExecuteBatch()[0].Unload();
		Return InventoryAllocationResult;
	
	EndIf;
	
	Text =
		// Needs.
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS ShipmentOrder,
		|	Table.EventDate AS RequestShipmentOn,
		|	0 AS OrderOfNeedCharacteristics,
		|	Table.ReserveAtWarehouseFromLocked AS Count,
		|	VALUE(Enum.DemandCharacteristics.ReserveAtWarehouseFromLocked) AS DemandCharacteristic,
		|	VALUE(Enum.InventoryStates.AvailablePendingUnlocking) AS InventoryState,
		|	Table.OrderDocument AS ControlledLotReference,
		|	CAST(ReportOrders.Priority AS Catalog.Priorities).AddlOrderingAttribute AS OrderByDocumentPriority,
		|	
		|	CASE
		|		WHEN NOT OrderingByDocumentDate.Value IS NULL
		|			THEN UNDEFINED
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDateOrWithoutOrder,
		|	
		|	ReportOrders.IBDocumentDate AS OrderByDocumentDate,
		|	
		|	CASE
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDate,
		|	
		|	0 AS QuantityPriority1,
		|	0 AS QuantityPriority2
		|FROM
		|	Demands AS Table
		|		
		|		LEFT JOIN ReportOrdersTable AS ReportOrders
		|		ON ReportOrders.Ref = Table.OrderDocument
		|		
		|		LEFT JOIN Constant.OptionOfOrderingDemandsByOrdersForSupply AS OrderingByDocumentDate
		|		ON OrderingByDocumentDate.Value = VALUE(Enum.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate)
		|WHERE
		|	Table.ReserveAtWarehouseFromLocked > 0
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS ShipmentOrder,
		|	Table.EventDate AS RequestShipmentOn,
		|	1 AS OrderOfNeedCharacteristics,
		|	Table.ReserveUponReceiptFromLocked AS Count,
		|	VALUE(Enum.DemandCharacteristics.ReserveUponReceiptFromLocked) AS DemandCharacteristic,
		|	VALUE(Enum.InventoryStates.NotProvided) AS InventoryState,
		|	Table.OrderDocument AS ControlledLotReference,
		|	CAST(ReportOrders.Priority AS Catalog.Priorities).AddlOrderingAttribute AS OrderByDocumentPriority,
		|	
		|	CASE
		|		WHEN NOT OrderingByDocumentDate.Value IS NULL
		|			THEN UNDEFINED
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDateOrWithoutOrder,
		|	
		|	ReportOrders.IBDocumentDate AS OrderByDocumentDate,
		|	
		|	CASE
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDate,
		|	
		|	0 AS QuantityPriority1,
		|	0 AS QuantityPriority2
		|FROM
		|	Demands AS Table
		|		
		|		LEFT JOIN ReportOrdersTable AS ReportOrders
		|		ON ReportOrders.Ref = Table.OrderDocument
		|		
		|		LEFT JOIN Constant.OptionOfOrderingDemandsByOrdersForSupply AS OrderingByDocumentDate
		|		ON OrderingByDocumentDate.Value = VALUE(Enum.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate)
		|WHERE
		|	Table.ReserveUponReceiptFromLocked > 0
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS ShipmentOrder,
		|	Table.EventDate AS RequestShipmentOn,
		|	2 AS OrderOfNeedCharacteristics,
		|	Table.ReserveAtWarehouse AS Count,
		|	VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse) AS DemandCharacteristic,
		|	VALUE(Enum.InventoryStates.InStock) AS InventoryState,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	CAST(ReportOrders.Priority AS Catalog.Priorities).AddlOrderingAttribute AS OrderByDocumentPriority,
		|	
		|	CASE
		|		WHEN NOT OrderingByDocumentDate.Value IS NULL
		|			THEN UNDEFINED
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDateOrWithoutOrder,
		|	
		|	ReportOrders.IBDocumentDate AS OrderByDocumentDate,
		|	
		|	CASE
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDate,
		|	
		|	0 AS QuantityPriority1,
		|	0 AS QuantityPriority2
		|FROM
		|	Demands AS Table
		|		
		|		LEFT JOIN ReportOrdersTable AS ReportOrders
		|		ON ReportOrders.Ref = Table.OrderDocument
		|		
		|		LEFT JOIN Constant.OptionOfOrderingDemandsByOrdersForSupply AS OrderingByDocumentDate
		|		ON OrderingByDocumentDate.Value = VALUE(Enum.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate)
		|WHERE
		|	Table.ReserveAtWarehouse > 0
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS ShipmentOrder,
		|	Table.EventDate AS RequestShipmentOn,
		|	3 AS OrderOfNeedCharacteristics,
		|	Table.ReserveAsReceived AS Count,
		|	VALUE(Enum.DemandCharacteristics.ReserveAsReceived) AS DemandCharacteristic,
		|	VALUE(Enum.InventoryStates.NotProvided) AS InventoryState,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	CAST(ReportOrders.Priority AS Catalog.Priorities).AddlOrderingAttribute AS OrderByDocumentPriority,
		|	
		|	CASE
		|		WHEN NOT OrderingByDocumentDate.Value IS NULL
		|			THEN UNDEFINED
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDateOrWithoutOrder,
		|	
		|	ReportOrders.IBDocumentDate AS OrderByDocumentDate,
		|	
		|	CASE
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDate,
		|	
		|	Table.InStock AS QuantityPriority1,
		|	Table.AvailablePendingUnlocking AS QuantityPriority2
		|FROM
		|	ReserveRequirementsAsTheyBecomeAvailableAndInventoryDistributedEarlier AS Table
		|		
		|		LEFT JOIN ReportOrdersTable AS ReportOrders
		|		ON ReportOrders.Ref = Table.OrderDocument
		|		
		|		LEFT JOIN Constant.OptionOfOrderingDemandsByOrdersForSupply AS OrderingByDocumentDate
		|		ON OrderingByDocumentDate.Value = VALUE(Enum.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS ShipmentOrder,
		|	Table.EventDate AS RequestShipmentOn,
		|	4 AS OrderOfNeedCharacteristics,
		|	Table.SnoozeReservation AS Count,
		|	VALUE(Enum.DemandCharacteristics.SnoozeReservation) AS DemandCharacteristic,
		|	VALUE(Enum.InventoryStates.NotProvided) AS InventoryState,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	CAST(ReportOrders.Priority AS Catalog.Priorities).AddlOrderingAttribute AS OrderByDocumentPriority,
		|	
		|	CASE
		|		WHEN NOT OrderingByDocumentDate.Value IS NULL
		|			THEN UNDEFINED
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDateOrWithoutOrder,
		|	
		|	ReportOrders.IBDocumentDate AS OrderByDocumentDate,
		|	
		|	CASE
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDate,
		|	
		|	0 AS QuantityPriority1,
		|	0 AS QuantityPriority2
		|FROM
		|	Demands AS Table
		|		
		|		LEFT JOIN ReportOrdersTable AS ReportOrders
		|		ON ReportOrders.Ref = Table.OrderDocument
		|		
		|		LEFT JOIN Constant.OptionOfOrderingDemandsByOrdersForSupply AS OrderingByDocumentDate
		|		ON OrderingByDocumentDate.Value = VALUE(Enum.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate)
		|WHERE
		|	Table.SnoozeReservation > 0
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS ShipmentOrder,
		|	Table.EventDate AS RequestShipmentOn,
		|	5 AS OrderOfNeedCharacteristics,
		|	Table.ToSupply AS Count,
		|	VALUE(Enum.DemandCharacteristics.ToSupply) AS DemandCharacteristic,
		|	VALUE(Enum.InventoryStates.NotProvided) AS InventoryState,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	CAST(ReportOrders.Priority AS Catalog.Priorities).AddlOrderingAttribute AS OrderByDocumentPriority,
		|	
		|	CASE
		|		WHEN NOT OrderingByDocumentDate.Value IS NULL
		|			THEN UNDEFINED
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDateOrWithoutOrder,
		|	
		|	ReportOrders.IBDocumentDate AS OrderByDocumentDate,
		|	
		|	CASE
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDate,
		|	
		|	0 AS QuantityPriority1,
		|	0 AS QuantityPriority2
		|FROM
		|	Demands AS Table
		|		
		|		LEFT JOIN ReportOrdersTable AS ReportOrders
		|		ON ReportOrders.Ref = Table.OrderDocument
		|		
		|		LEFT JOIN Constant.OptionOfOrderingDemandsByOrdersForSupply AS OrderingByDocumentDate
		|		ON OrderingByDocumentDate.Value = VALUE(Enum.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate)
		|WHERE
		|	Table.ToSupply > 0
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS ShipmentOrder,
		|	Table.EventDate AS RequestShipmentOn,
		|	6 AS OrderOfNeedCharacteristics,
		|	Table.NotProvide AS Count,
		|	VALUE(Enum.DemandCharacteristics.NotProvide) AS DemandCharacteristic,
		|	VALUE(Enum.InventoryStates.NotProvided) AS InventoryState,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	CAST(ReportOrders.Priority AS Catalog.Priorities).AddlOrderingAttribute AS OrderByDocumentPriority,
		|	
		|	CASE
		|		WHEN NOT OrderingByDocumentDate.Value IS NULL
		|			THEN UNDEFINED
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDateOrWithoutOrder,
		|	
		|	ReportOrders.IBDocumentDate AS OrderByDocumentDate,
		|	
		|	CASE
		|		WHEN Table.EventDate > &EndOfCurrentDay
		|			THEN Table.EventDate
		|		ELSE ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDate,
		|	
		|	0 AS QuantityPriority1,
		|	0 AS QuantityPriority2
		|FROM
		|	Demands AS Table
		|		
		|		LEFT JOIN ReportOrdersTable AS ReportOrders
		|		ON ReportOrders.Ref = Table.OrderDocument
		|		
		|		LEFT JOIN Constant.OptionOfOrderingDemandsByOrdersForSupply AS OrderingByDocumentDate
		|		ON OrderingByDocumentDate.Value = VALUE(Enum.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate)
		|WHERE
		|	Table.NotProvide > 0
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	OrderOfNeedCharacteristics,
		|	ControlledLotReference,
		|	OrderByDocumentPriority,
		|	OrderByShipmentDateOrWithoutOrder,
		|	OrderByDocumentDate,
		|	OrderByShipmentDate,
		|	ShipmentOrder
		|;
		|
		|/////////////////////////////////////////////////////////////////
		// Inventory.
		|SELECT
		|	0 AS OrderAccordingToStateOfInventory,
		|	0 AS OrderAccordingToStateOfStockIsAdditional,
		|	VALUE(Enum.InventoryStates.InStock) AS InventoryState,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	UNDEFINED AS ReceiptOrder,
		|	UNDEFINED AS ControlledLotReference,
		|	DATETIME(1, 1, 1) AS DateOfReceipt,
		|	DATETIME(1, 1, 1) AS AvailabilityDate,
		|	SUM(Table.InStock - Table.LockedInStock) AS Count
		|FROM
		|	Inventories AS Table
		|WHERE
		|	Table.EventDate = DATETIME(1, 1, 1)
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse,
		|	Table.Purpose
		|	
		|UNION ALL
		|
		|SELECT
		|	CASE
		|		WHEN Table.InventoryState = VALUE(Enum.InventoryStates.AvailablePendingUnlocking)
		|			THEN 1
		|		WHEN Table.InventoryState = VALUE(Enum.InventoryStates.AvailableNotSubjectToUnlocking)
		|			THEN 2
		|		WHEN Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock)
		|			THEN 3
		|		WHEN Table.InventoryState = VALUE(Enum.InventoryStates.ExpectedForReceiptNotSubjectToUnlocking)
		|			THEN 4
		|	END AS OrderAccordingToStateOfInventory,
		|	1 AS OrderAccordingToStateOfStockIsAdditional,
		|	Table.InventoryState AS InventoryState,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS ReceiptOrder,
		|	CASE
		|		WHEN VALUETYPE(Table.OrderDocument) = TYPE(Catalog.ControlledLots)
		|			THEN Table.OrderDocument
		|		ELSE UNDEFINED
		|	END AS ControlledLotReference,
		|	Table.DateOfReceipt AS DateOfReceipt,
		|	Table.AvailabilityDate AS AvailabilityDate,
		|	Table.Count AS Count
		|FROM
		|	InventoryBlocked AS Table
		|
		|UNION ALL
		|
		|SELECT
		|	3 AS OrderAccordingToStateOfInventory,
		|	0 AS OrderAccordingToStateOfStockIsAdditional,
		|	VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock) AS InventoryState,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS ReceiptOrder,
		|	UNDEFINED AS ControlledLotReference,
		|	Table.EventDate AS DateOfReceipt,
		|	Table.EventDate AS AvailabilityDate,
		|	Table.Received_1 - Table.LockedReceipt AS Count
		|FROM
		|	Inventories AS Table
		|WHERE
		|	Table.Received_1 - Table.LockedReceipt > 0
		|	
		|UNION ALL
		|
		|SELECT
		|	5 AS OrderAccordingToStateOfInventory,
		|	0 AS OrderAccordingToStateOfStockIsAdditional,
		|	VALUE(Enum.InventoryStates.PendingSupplyApproval) AS InventoryState,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS ReceiptOrder,
		|	UNDEFINED AS ControlledLotReference,
		|	DATETIME(1, 1, 1) AS DateOfReceipt,
		|	DATETIME(1, 1, 1) AS AvailabilityDate,
		|	Table.Ordered - Table.Received_1 AS Count
		|FROM
		|	Inventories AS Table
		|WHERE
		|	Table.EventDate = DATETIME(1, 1, 1)
		|		AND Table.Ordered - Table.Received_1 > 0
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	OrderAccordingToStateOfInventory,
		|	AvailabilityDate,
		|	OrderAccordingToStateOfStockIsAdditional,
		|	DateOfReceipt,
		|	ReceiptOrder,
		|	ControlledLotReference
		|;
		|
		|////////////////////////////////////////////////////////////////////
		// Items.
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	CAST(-1 AS NUMBER (10,0)) AS NeedsFirst,
		|	CAST(-2 AS NUMBER (10,0)) AS NeedsLast,
		|	CAST(-1 AS NUMBER (10,0)) AS InventoryFirst,
		|	CAST(-2 AS NUMBER (10,0)) AS LastInventory
		|FROM
		|	NameOfProductsTable AS Table
		|ORDER BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////
		// The needdistribution of several recordings.
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS ShipmentOrder,
		|	MAX(Table.InStock) AS QuantityPriority1,
		|	MAX(Table.AvailablePendingUnlocking) AS QuantityPriority2
		|FROM
		|	ReserveRequirementsAsTheyBecomeAvailableAndInventoryDistributedEarlier AS Table
		|WHERE
		|	(Table.InStock > 0 OR Table.AvailablePendingUnlocking > 0)
		|		AND TRUE IN(
		|			SELECT TOP 1
		|				TRUE AS ThereIsSecondEntry
		|			FROM
		|				ReserveRequirementsAsTheyBecomeAvailableAndInventoryDistributedEarlier AS SameTable
		|			WHERE
		|				SameTable.Products = Table.Products
		|				AND SameTable.Characteristic = Table.Characteristic
		|				AND SameTable.Warehouse = Table.Warehouse
		|				AND SameTable.Purpose = Table.Purpose
		|				AND SameTable.OrderDocument = Table.OrderDocument
		|				AND SameTable.EventDate <> Table.EventDate)
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse,
		|	Table.Purpose,
		|	Table.OrderDocument
		|;
		|
		|//////////////////////////////////////////////////////
		|DROP Inventories;
		|DROP InventoryBlocked;
		|DROP ReportOrdersTable;
		|DROP Demands;
		|DROP ReserveRequirementsAsTheyBecomeAvailableAndInventoryDistributedEarlier;
		|DROP StocksDistributedEarlier;
		|DROP ProductNeeds";
	Text = StrReplace(Text, "NameOfProductsTable", NameOfProductsTable);
	
	If StrFind(RegisterNames, "AvailableStockBalances") > 0 Then
		
		Texts = New Array();
		Texts.Add(Text);
		Texts.Add(TextAvailableItemBalances);
		Text = StrConcat(Texts, Common.QueryBatchSeparator());
		
	EndIf;
	
	Query.Text = Text;
	Query.SetParameter("EndOfCurrentDay", EndOfDay(CurrentSessionDate()));
	Result = Query.ExecuteBatch();
	
	Demands = Result[0].Unload();
	Inventories = Result[1].Unload();
	Goods = Result[2].Unload();
	
	NeedsAreDistributedOverSeveralRecords = Result[3].Unload();
	KeyFields = "Products,Characteristic,Warehouse,Purpose,ShipmentOrder";
	SearchKey = New Structure(KeyFields);
	NeedsAreDistributedOverSeveralRecords.Indexes.Add(KeyFields);
	
	AvailableStockBalances = Undefined;
	If StrFind(RegisterNames, "AvailableStockBalances") > 0 Then
		AvailableStockBalances = Result[Result.UBound() - 1].Unload();
	EndIf;
	
	Set = InformationRegisters.InventoryAllocation.CreateRecordSet();
	If AllGoods Then
		Demands.Columns.Add("IsEmpty", New TypeDescription("Boolean"));
	EndIf;
	Demands.Columns.Add("ReceiptOrder", Set.Metadata().Dimensions.ReceiptOrder.Type);
	Demands.Columns.Add("DateOfReceipt", Set.Metadata().Dimensions.DateOfReceipt.Type);
	Demands.Columns.Add("AvailabilityDate", Set.Metadata().Dimensions.AvailabilityDate.Type);
	Demands.Columns.Add("FoundSeveralRecordsInTable", New TypeDescription("Boolean"));
	Demands.Columns.Add("EverythingIsDistributed", New TypeDescription("Boolean"));
	Demands.Columns.Add("Count0", Set.Metadata().Resources.Count.Type);
	Demands.Columns.Add("Count1", Set.Metadata().Resources.Count.Type);
	
	#EndRegion
	
	// The Goods table should contain all the analysts Nomenclature+Characteristics+Warehouse+Purpose, which are found in
	// the tables of Needs and Stocks. All three tables should be ordered by these analysts.
	FillInIndexesInGoodsTable(Goods, Demands, "NeedsFirst", "NeedsLast");
	FillInIndexesInGoodsTable(Goods, Inventories, "InventoryFirst", "LastInventory");
	
	// The needs are ordered by the field of the order of the characteristics of the needs of the
	// 0 - enumeration link.Need characteristics.Reserving a list of blocked
	// 1 - Listing the link.Need characteristics.Reserving the number of blocked users' accesses
	// 2 - Listing the link.Need characteristics.Reserving the layout
	// 3 - Listing link.Need characteristics.Reservingmomere accesses
	// 4 - Listing link.Need characteristics.Postpone reserving
	// 5 - Listing link.Need characteristics.Self- sufficiency
	// 6 - Listing link.Need characteristics.Unsecure
	
	// Inventory is ordered by the field order of inventory status
	// 0 - Link enumeration.States of the reserve.In cash
	// 1 - Listing the link.States of the reserve.Cash is waiting for a release
	// 2 - Listing the link.States of the reserve.cashinepreserves the deadlock
	// 3 - Listing link.States of the reserve.Waiting for a deadlocked access, add. ordering by availability date
	// 3 - Listing link.States of the reserve.Pending access, add. ordering by availability date
	// 4 - Listing link.States of the reserve.The expected access is not subject to a deadlock
	// 5 - Listing link.States of the reserve.Delivery reconciliationsreferences
	
	InventoryFieldsToFillIn = "ReceiptOrder,InventoryState,DateOfReceipt,AvailabilityDate";
	CommonFieldsToFillIn = "Products,Characteristic,Warehouse,Purpose";
	
	AddedLines_ = 0;
	
	SurplusValue = Enums.DemandCharacteristics.Surplus;
	ValueAvailable = Enums.InventoryStates.InStock;
	ValueInStockExpectedToBeUnlocked = Enums.InventoryStates.AvailablePendingUnlocking;
	
	For GoodsIndex = 0 To Goods.Count() - 1 Do
		
		String = Goods[GoodsIndex];
		NeedsFirst = String.NeedsFirst + AddedLines_;
		NeedsLast = String.NeedsLast + AddedLines_;
		
		Record0 = Undefined;
		If String.InventoryFirst <> -1 And Inventories[String.InventoryFirst].OrderAccordingToStateOfInventory = 0 Then
			Record0 = Inventories[String.InventoryFirst];
		EndIf;
		
		#Region InventoryHandling
		
		MatchingParties = New Map();
		For IndexInventory = String.InventoryFirst To String.LastInventory Do
			
			Inventory = Inventories[IndexInventory];
			
			If ValueIsFilled(Inventory.ControlledLotReference) Then
				
				Lot = MatchingParties.Get(Inventory.ControlledLotReference);
				If Lot = Undefined Then
					Lot = New Structure();
					Lot.Insert("AllRecords", New Array());
					Lot.Insert("Record1", New Array());
					Lot.Insert("Record2", New Array());
					Lot.Insert("NegativeReserve", Undefined);
					Lot.Insert("Count1", 0);
					Lot.Insert("Count2", 0);
					MatchingParties.Insert(Inventory.ControlledLotReference, Lot);
				EndIf;
				Lot.AllRecords.Add(Inventory);
				
				If Inventory.OrderAccordingToStateOfInventory = 1 Then
					Lot.Record1.Add(Inventory);
					Lot.Count1 = Lot.Count1 + Max(0, Inventory.Count);
				ElsIf Inventory.OrderAccordingToStateOfInventory = 2 Then
					Lot.Record2.Add(Inventory);
					Lot.Count2 = Lot.Count2 + Max(0, Inventory.Count);
				EndIf;
				
			EndIf;
			
		EndDo;
		
		#EndRegion
		
		If String.NeedsFirst = -1 And String.InventoryFirst = -1 Then // no inventory, no needs.
			
			If AllGoods Then
				// Adding new rows to the end of the table does not prevent the following products from creating continuous sets of analysts (nomenclature, etc.),
				// since there are no other rows in the table of needs for the current product.
				CurrentRecord = Demands.Add();
				FillPropertyValues(CurrentRecord, String);
				CurrentRecord.IsEmpty = True;
			EndIf;
			
		Else
			
			// Needs.
			If String.NeedsFirst <> -1 Then
				
				ThereIsReserveAsNeeded = False;
				For IndexNeed = NeedsFirst To NeedsLast Do
					
					Demand = Demands[IndexNeed];
					
					If Demand.OrderOfNeedCharacteristics = 0 Then
					
					#Region ReserveAtWarehouseFromLocked
						
						Lot = MatchingParties.Get(Demand.ControlledLotReference);
						If Lot = Undefined Then
							Lot = New Structure();
							Lot.Insert("AllRecords", New Array());
							Lot.Insert("Record1", New Array());
							Lot.Insert("Record2", New Array());
							Lot.Insert("NegativeReserve", Undefined);
							Lot.Insert("Count1", 0);
							Lot.Insert("Count2", 0);
							MatchingParties.Insert(Demand.ControlledLotReference, Lot);
						EndIf;
						
						Allocate1 = Min(Lot.Count1, Demand.Count);
						Allocate2 = Min(Demand.Count - Allocate1, Lot.Count2);
						Allocate3 = Demand.Count - Allocate1 - Allocate2;
						
						Lot.Count1 = Lot.Count1 - Allocate1;
						BatchInventoryIndex = 0;
						While Allocate1 > 0 And BatchInventoryIndex < Lot.Record1.Count() Do
							
							Inventory = Lot.Record1[BatchInventoryIndex];
							If Inventory.Count <= 0 Then
								BatchInventoryIndex = BatchInventoryIndex + 1;
								Continue;
							EndIf;
							
							DistributeCurrent = Min(Max(0, Inventory.Count), Allocate1);
							Allocate1 = Allocate1 - DistributeCurrent;
							
							If DistributeCurrent >= Demand.Count Then
								
								CurrentRecord = Demand;
								
							Else
								
								Demand.Count = Demand.Count - DistributeCurrent;
								
								CurrentRecord = Demands.Insert(NeedsLast + 1);
								AddedLines_ = AddedLines_ + 1;
								FillPropertyValues(CurrentRecord, Demand);
								CurrentRecord.Count = DistributeCurrent;
								
							EndIf;
							
							FillPropertyValues(CurrentRecord, Inventory, InventoryFieldsToFillIn);
							Inventory.Count = Inventory.Count - DistributeCurrent;
						
						EndDo;
						
						BatchInventoryIndex = 0;
						While Allocate2 > 0 And BatchInventoryIndex < Lot.Record2.Count() Do
							
							Inventory = Lot.Record2[BatchInventoryIndex];
							If Inventory.Count <= 0 Then
								BatchInventoryIndex = BatchInventoryIndex + 1;
								Continue;
							EndIf;
							
							DistributeCurrent = Min(Max(0, Inventory.Count), Allocate2);
							Allocate2 = Allocate2 - DistributeCurrent;
							
							If DistributeCurrent >= Demand.Count Then
								
								CurrentRecord = Demand;
								
							Else
								
								Demand.Count = Demand.Count - DistributeCurrent;
								
								CurrentRecord = Demands.Insert(NeedsLast + 1);
								AddedLines_ = AddedLines_ + 1;
								FillPropertyValues(CurrentRecord, Demand);
								CurrentRecord.Count = DistributeCurrent;
								
							EndIf;
							
							FillPropertyValues(CurrentRecord, Inventory, InventoryFieldsToFillIn);
							Inventory.Count = Inventory.Count - DistributeCurrent;
						
						EndDo;
						
						If Allocate3 > 0 Then // negative surplus.
							
							Demand.ReceiptOrder = Demand.ControlledLotReference;
							If Lot.NegativeReserve = Undefined Then
								
								Lot.NegativeReserve = Demands.Insert(NeedsLast + 1);
								CurrentRecord = Lot.NegativeReserve;
								
								AddedLines_ = AddedLines_ + 1;
								
								FillPropertyValues(CurrentRecord, Demand, CommonFieldsToFillIn);
								CurrentRecord.ReceiptOrder = Demand.ControlledLotReference;
								CurrentRecord.InventoryState = ValueInStockExpectedToBeUnlocked;
								CurrentRecord.Count = 0;
								CurrentRecord.DemandCharacteristic = SurplusValue;
								
							EndIf;
							
							Lot.NegativeReserve.Count = Lot.NegativeReserve.Count - Allocate3;
							
						EndIf;
						
					#EndRegion
					
					ElsIf Demand.OrderOfNeedCharacteristics = 1 Then
					
					#Region ReserveUponReceiptFromLocked
						
						Lot = MatchingParties.Get(Demand.ControlledLotReference);
						Last_3 = ?(Lot = Undefined, -1, Lot.AllRecords.Count() - 1);
						BatchInventoryIndex = 0;
						
						EverythingIsDistributed = False;
						While BatchInventoryIndex <= Last_3 Do
							
							Inventory = Lot.AllRecords[BatchInventoryIndex];
							If Inventory.Count <= 0 Then
								BatchInventoryIndex = BatchInventoryIndex + 1;
								Continue;
							EndIf;
							
							EverythingIsDistributed = False;
							If Inventory.Count >= Demand.Count Then
								
								CurrentRecord = Demand;
								EverythingIsDistributed = True;
								
							Else
								
								Demand.Count = Demand.Count - Inventory.Count;
								
								CurrentRecord = Demands.Insert(NeedsLast + 1);
								AddedLines_ = AddedLines_ + 1;
								FillPropertyValues(CurrentRecord, Demand);
								CurrentRecord.Count = Inventory.Count;
								
							EndIf;
							
							FillPropertyValues(CurrentRecord, Inventory, InventoryFieldsToFillIn);
							Inventory.Count = Inventory.Count - CurrentRecord.Count;
							If Inventory.OrderAccordingToStateOfInventory = 1 Then
								Lot.Count1 = Lot.Count1 - CurrentRecord.Count;
							EndIf;
							
							If EverythingIsDistributed Then
								Break;
							EndIf;
							
						EndDo;
						
					#EndRegion
					
					ElsIf Demand.OrderOfNeedCharacteristics = 2 Then
					
					#Region ReserveAtWarehouse
						
						If Record0 = Undefined Then
							
							Record0 = Demands.Insert(NeedsLast + 1);
							AddedLines_ = AddedLines_ + 1;
							
							FillPropertyValues(Record0, Demand, CommonFieldsToFillIn);
							Record0.InventoryState = ValueAvailable;
							Record0.Count = 0;
							Record0.DemandCharacteristic = SurplusValue;
							
						EndIf;
						
						Record0.Count = Record0.Count - Demand.Count;
						
					#EndRegion
					
					Else
						
						ThereIsReserveAsNeeded = Demand.OrderOfNeedCharacteristics = 3;
						NeedsFirst = IndexNeed;
						Break;
						
					EndIf;
					
				EndDo;
				
				#Region StockInventoryToReserveAsItBecomesAvailable
				
				Count0 = Max(0, ?(Record0 = Undefined, 0, Record0.Count));
				Count1 = 0;
				For Each KeyAndValue In MatchingParties Do
					Count1 = Count1 + Max(0, KeyAndValue.Value.Count1);
				EndDo;
				
				If ThereIsReserveAsNeeded And (Count0 > 0 Or Count1 > 0) Then
					
					// Need calculation.Quantity 0 and Need.Quantity 1;
					For AisleNumber = 1 To 3 Do
						
						For IndexNeed = NeedsFirst To NeedsLast Do
							
							Demand = Demands[IndexNeed];
							If Demand.OrderOfNeedCharacteristics <> 3 Then
								Break;
							EndIf;
							
							FillPropertyValues(SearchKey, Demand);
							FoundRows = NeedsAreDistributedOverSeveralRecords.FindRows(SearchKey);
							Receiver = ?(AisleNumber < 3 And FoundRows.Count() > 0, FoundRows[0], Demand);
							CurrentDemand = ?(AisleNumber = 1, Receiver.QuantityPriority1, ?(AisleNumber = 2, Receiver.QuantityPriority2, Demand.Count));
							// The order could be reduced and the reserves remained.
							CurrentDemand = Min(CurrentDemand, Demand.Count - Demand.Count0 - Demand.Count1);
							
							Allocate0 = Min(CurrentDemand, Count0);
							Count0 = Count0 - Allocate0;
							CurrentDemand = CurrentDemand - Allocate0;
							
							Allocate1 = Min(CurrentDemand, Count1);
							Count1 = Count1 - Allocate1;
							
							// It is important if the need for the order is set in several lines.
							If AisleNumber = 1 Then
								Receiver.QuantityPriority1 = Receiver.QuantityPriority1 - Allocate0 - Allocate1;
							ElsIf AisleNumber = 2 Then
								Receiver.QuantityPriority2 = Receiver.QuantityPriority2 - Allocate0 - Allocate1;
							EndIf;
							
							Demand.Count0 = Demand.Count0 + Allocate0;
							Demand.Count1 = Demand.Count1 + Allocate1;
							
							If Count0 = 0 And Count1 = 0 Then
								Break;
							EndIf;
							
						EndDo;
						
						If Count0 = 0 And Count1 = 0 Then
							Break;
						EndIf;
						
					EndDo;
					
					// Priority distribution of warehouse inventory.
					InventoryIndex = String.InventoryFirst;
					
					For IndexNeed = NeedsFirst To NeedsLast Do
						
						Demand = Demands[IndexNeed];
						If Demand.OrderOfNeedCharacteristics <> 3 Then
							Break;
						EndIf;
						
						Allocate = Demand.Count0;
						Inventory = Record0;
						
						If Allocate > 0 Then
							
							If Allocate >= Demand.Count Then
								
								CurrentRecord = Demand;
								Demand.EverythingIsDistributed = True;
								
							Else
								
								Demand.Count = Demand.Count - Allocate;
								
								CurrentRecord = Demands.Insert(NeedsLast + 1);
								AddedLines_ = AddedLines_ + 1;
								FillPropertyValues(CurrentRecord, Demand);
								CurrentRecord.Count = Allocate;
								
							EndIf;
							
							FillPropertyValues(CurrentRecord, Inventory, InventoryFieldsToFillIn);
							Inventory.Count = Inventory.Count - Allocate;
							
						EndIf;
						
						DistributeEverything = Demand.Count1;
						
						While DistributeEverything > 0 And InventoryIndex <= String.LastInventory Do
							
							Inventory = Inventories[InventoryIndex];
							
							If Inventory.Count <= 0 Or Inventory.OrderAccordingToStateOfInventory = 0 Then
								InventoryIndex = InventoryIndex + 1;
								Continue;
							EndIf;
							
							If Inventory.OrderAccordingToStateOfInventory <> 1 Then
								Break;
							EndIf;
							
							Allocate = Min(DistributeEverything, Inventory.Count);
							DistributeEverything = DistributeEverything - Allocate;
							
							If Allocate >= Demand.Count Then
								
								CurrentRecord = Demand;
								Demand.EverythingIsDistributed = True;
								
							Else
								
								Demand.Count = Demand.Count - Allocate;
								
								CurrentRecord = Demands.Insert(NeedsLast + 1);
								AddedLines_ = AddedLines_ + 1;
								FillPropertyValues(CurrentRecord, Demand);
								CurrentRecord.Count = Allocate;
								
							EndIf;
							
							FillPropertyValues(CurrentRecord, Inventory, InventoryFieldsToFillIn);
							Inventory.Count = Inventory.Count - Allocate;
							
						EndDo;
						
					EndDo;
					
				EndIf;
				
				#EndRegion
				
				#Region InventoryDistributionTotal
				
				InventoryIndex = String.InventoryFirst;
				
				For IndexNeed = NeedsFirst To NeedsLast Do
					
					Demand = Demands[IndexNeed];
					If Demand.OrderOfNeedCharacteristics = 3 And Demand.EverythingIsDistributed Then
						Continue;
					EndIf;
					
					If Demand.OrderOfNeedCharacteristics <> 3
							And Demand.OrderOfNeedCharacteristics <> 4
							And Demand.OrderOfNeedCharacteristics <> 5 Then
							
						Break;
						
					EndIf;
					
					While InventoryIndex <= String.LastInventory Do
						
						Inventory = Inventories[InventoryIndex];
						
						If Inventory.Count <= 0
								// Inventory that cannot be unlocked.
								Or Inventory.OrderAccordingToStateOfInventory = 2
								Or Inventory.OrderAccordingToStateOfInventory = 4 Then
							InventoryIndex = InventoryIndex + 1;
							Continue;
						EndIf;
						
						EverythingIsDistributed = False;
						Allocate = Inventory.Count;
						
						If Allocate >= Demand.Count Then
							
							CurrentRecord = Demand;
							EverythingIsDistributed = True;
							
						Else
							
							Demand.Count = Demand.Count - Allocate;
							
							CurrentRecord = Demands.Insert(NeedsLast + 1);
							AddedLines_ = AddedLines_ + 1;
							FillPropertyValues(CurrentRecord, Demand);
							CurrentRecord.Count = Allocate;
							
						EndIf;
						
						FillPropertyValues(CurrentRecord, Inventory, InventoryFieldsToFillIn);
						Inventory.Count = Inventory.Count - CurrentRecord.Count;
						
						If EverythingIsDistributed Then
							Break;
						EndIf;
						
					EndDo;
					
				EndDo;
				
				#EndRegion
				
			EndIf;
			
			// Surplus.
			InventoryIndex = String.InventoryFirst;
			While InventoryIndex <= String.LastInventory Do
				
				Inventory = Inventories[InventoryIndex];
				InventoryIndex = InventoryIndex + 1;
				If Inventory.Count = 0 Then
					Continue;
				EndIf;
				
				If String.NeedsFirst = -1 Then
					// Adding new rows to the end of the table does not prevent the following products from creating continuous sets of analysts (nomenclature, etc.),
					// since there are no other rows in the table of needs for the current product.
					CurrentRecord = Demands.Add();
				Else
					CurrentRecord = Demands.Insert(NeedsLast + 1);
					AddedLines_ = AddedLines_ + 1;
				EndIf;
				
				FillPropertyValues(CurrentRecord, Inventory);
				CurrentRecord.DemandCharacteristic = SurplusValue;
				
			EndDo;
			
		EndIf;
		
	EndDo; // Goods
	
	InventoryAllocationResult.InventoryAllocation = Demands;
	InventoryAllocationResult.AvailableStockBalances = AvailableStockBalances;
	Return InventoryAllocationResult;
	
EndFunction

Procedure FillInIndexesInGoodsTable(Goods, Table, First, Last_3)
	
	GoodsIndex = 0;
	For IndexOf = 0 To Table.Count() - 1 Do
		
		Record = Table[IndexOf];
		
		While True Do
			
			OwnGoods = Goods[GoodsIndex];
			If OwnGoods.Products = Record.Products
				And OwnGoods.Characteristic = Record.Characteristic
				And OwnGoods.Warehouse = Record.Warehouse
				And OwnGoods.Purpose = Record.Purpose Then
				
				Break;
				
			EndIf;
			GoodsIndex = GoodsIndex + 1;
			
		EndDo;
		
		If OwnGoods[First] = -1 Then
			OwnGoods[First] = IndexOf;
		EndIf;
		OwnGoods[Last_3] = IndexOf;
		
	EndDo;
	
EndProcedure

Procedure RecordInventoryDistributionResult(Result)
	
	Set = InformationRegisters.InventoryAllocation.CreateRecordSet();
	Fields = "Products,Characteristic,Warehouse,Purpose";
	Filter = New Structure(Fields);
	Table = Result.InventoryAllocation;
	For IndexOf = 0 To Table.Count() - 1 Do
		
		String = Table[IndexOf];
		
		If Filter.Products <> String.Products
				Or Filter.Characteristic <> String.Characteristic
				Or Filter.Warehouse <> String.Warehouse
				Or Filter.Purpose <> String.Purpose Then
					
					If Filter.Products <> Undefined Then
						Set.Write();
					EndIf;
					
					FillPropertyValues(Filter, String);
					
					Set.Clear();
					Set.Filter.Products.Set(Filter.Products);
					Set.Filter.Characteristic.Set(Filter.Characteristic);
					Set.Filter.Warehouse.Set(Filter.Warehouse);
					Set.Filter.Purpose.Set(Filter.Purpose);
					
		EndIf;
		
		If Not String.IsEmpty Then
			FillPropertyValues(Set.Add(), String);
		EndIf;
		
	EndDo;
	
	If Table.Count() > 0 Then
		Set.Write();
	EndIf;
	
	Table = Result.AvailableStockBalances;
	Set = InformationRegisters.AvailableStockBalances.CreateRecordSet();
	For IndexOf = 0 To Table.Count() - 1 Do
		
		String = Table[IndexOf];
		
		Set.Clear();
		Set.Filter.Products.Set(String.Products);
		Set.Filter.Characteristic.Set(String.Characteristic);
		Set.Filter.Warehouse.Set(String.Warehouse);
		Set.Filter.Purpose.Set(String.Purpose);
		Set.Filter.ControlledLotReference.Set(String.ControlledLotReference);
		If String.InStock <> 0 Or String.Available <> 0 Then
			FillPropertyValues(Set.Add(), String);
		EndIf;
		Set.Write();
		
	EndDo;
	
EndProcedure

Function DistributionOfInventoryByGoods(Query, NameOfProductsTable, AllGoods, RegisterNames, NameOfDocumentRegistryTable = Undefined, NameOfAdjustmentTable = Undefined)
	
	TempTablesOfRegisterData(Query, NameOfProductsTable, RegisterNames, NameOfDocumentRegistryTable, NameOfAdjustmentTable);
	If StrFind(RegisterNames, "InventoryAllocation") > 0 Then
		AddTempTableOfInventoryBlocked(Query);
	EndIf;
	Result = InventoryAllocationResult(Query, NameOfProductsTable, AllGoods, RegisterNames); // Structure
	Return Result;
	
EndFunction

Procedure ReportUnsuccessfulProductItemProcessing(ErrorInfo, MessageText)
	
	MessageText = NStr("vi = 'Nhiệm vụ phân bổ vật tư đã kết thúc không thành công do nguyên nhân: %Cause%';
						|ru = 'Задание распределения запасов завершилось неудачно по причине: %Cause%';
						|en = 'Inventory allocation job failed. Reason: %Cause%'; fa = 'Inventory allocation job failed. Reason: %Cause%';
						|it = 'Task di distribuzione delle scorte non è riuscito a causa di: %Cause%';
						|pl = 'Zadanie przydzielenia zapasów zakończyło się nieudanie z powodu: %Cause%';
						|tr = 'Stok dağıtım görevi şu nedenle başarısız oldu: %Cause%'");
	MessageText = StrReplace(MessageText, "%Cause%", ErrorProcessing.DetailErrorDescription(ErrorInfo));
	LogEvent = NStr("vi = 'Phân bổ vật tư';
					|ru = 'Распределение запасов';
					|en = 'Inventory allocation'; fa = 'تسهیم موجودی';
					|it = 'Distribuzione delle scorte';
					|pl = 'Przydzielenie zapasów';
					|tr = 'Stok dağıtımı'", Common.DefaultLanguageCode());
	WriteLogEvent(LogEvent,
	EventLogLevel.Error, Metadata.InformationRegisters.InventoryAllocation,, MessageText);
	
EndProcedure

#EndRegion
