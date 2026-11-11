
#Region Internal

Procedure StartCalculation() Export
	
	If OrderStructureInternal.BlockPayment() Then
		Return;
	EndIf;
	
	ExportProcedureName = "OrderStructure.StartCalculationContinued";
	ProcedureParameters = New Array();

	Var_Key = Metadata.ScheduledJobs.CalculateProductionOrderStructure.Key;
	
	SetPrivilegedMode(True);
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(New Structure("Key, State", Var_Key, BackgroundJobState.Active));
	SetPrivilegedMode(False);
	
	If ActiveTasks.Count() = 0 Then
		
		Try
			BackgroundJobs.Execute(
				ExportProcedureName,
				ProcedureParameters,
				Var_Key,
				NStr("vi = 'Tính cấu trúc đơn hàng. Luồng quản lý';
					|ru = 'Расчет структуры заказа. Управляющий поток';
					|en = 'Order structure calculation. Thread of control'; fa = 'Order structure calculation. Thread of control';
					|it = 'Calcolo della struttura dell''ordine. Flusso di gestione';
					|pl = 'Obliczenie struktury zamówienia. Przepływ zarządzający';
					|tr = 'Sipariş yapısının hesaplanması. Kontrol akışı'"));
		Except
			// the task is already running
		EndTry;
		
	EndIf;
	
EndProcedure

Procedure StartCalculationContinued() Export
	
	CalculationProtocol = CalculationProtocol();
	
	CalculationProcedure = New Array;
	
	Action = ActionParameters();
	Action.Name = NStr("vi = 'Phân bổ';
						|ru = 'Распределение';
						|en = 'Allocation'; fa = 'تسهیم';
						|it = 'Distribuzione';
						|pl = 'Allocation';
						|tr = 'Dağıtım'");
	Action.ProcedureName = "OrderStructure.PerformInventoryAllocation";
	Action.SelectionFields1 = "Products,Characteristic,Warehouse,Purpose";
	Action.GroupFields = "Id";
	Action.ErrorHandlingParameters.ErrorType = Enums.ErrorsTypesOfProductionOrderStructureCalculation.InventoryAllocationError;
	Action.JobsQueue = InformationRegisters.OrderStructureCalculationTasksInventoryAllocation;
	Action.BatchesCount = CalculationProtocol.CalculationParameters.ThreadsCount;
	AddTextOfBatchSelectionRequest(Action, CalculationProtocol.CalculationParameters, Action.SelectionFields1);
	CalculationProcedure.Add(Action);
	
	Action = ActionParameters();
	Action.Name = NStr("vi = 'Chia tách';
						|ru = 'Разузлование';
						|en = 'Explosion'; fa = 'تفکیک';
						|it = 'Esplosione';
						|pl = 'Explosion';
						|tr = 'Ayrıştırma'");
	Action.ProcedureName = "OrderStructure.PerformUncoupling";
	Action.SelectionFields1 = "BillOfMaterials,ProductionOrder";
	Action.ErrorHandlingParameters.ErrorType = Enums.ErrorsTypesOfProductionOrderStructureCalculation.ExplosionError;
	Action.ErrorHandlingParameters.GroupFields = "ProductionOrder";
	Action.JobsQueue = InformationRegisters.TasksOfBOMOrderStructureCalculation;
	Action.BatchesCount = CalculationProtocol.CalculationParameters.ThreadsCount;
	AddTextOfBatchSelectionRequest(Action, CalculationProtocol.CalculationParameters, Action.SelectionFields1);
	CalculationProcedure.Add(Action);
	
	Action = ActionParameters();
	Action.Name = NStr("vi = 'Tính lại cấu trúc đơn hàng';
						|ru = 'Пересчет структуры заказа';
						|en = 'Order structure recalculation'; fa = 'Order structure recalculation';
						|it = 'Ricalcolo della struttura dell''ordine';
						|pl = 'Przeliczenie struktury zamówienia';
						|tr = 'Sipariş yapısının yeniden hesaplanması'");
	Action.ProcedureName = "OrderStructureInternal.PerformRecalculation";
	Action.SelectionFields1 = "ProductionOrder";
	Action.ErrorHandlingParameters.ErrorType = Enums.ErrorsTypesOfProductionOrderStructureCalculation.ExplosionError;
	Action.ErrorHandlingParameters.GroupFields = "ProductionOrder";
	Action.JobsQueue = InformationRegisters.OrderStructureCleanupTasks;
	Action.BatchesCount = CalculationProtocol.CalculationParameters.ThreadsCount;
	AddTextOfBatchSelectionRequest(Action, CalculationProtocol.CalculationParameters, Action.SelectionFields1);
	CalculationProcedure.Add(Action);
	
	ExecuteActions(CalculationProcedure, CalculationProtocol);
	
EndProcedure

Procedure ExecuteActions(CalculationProcedure, CalculationProtocol)
	
	SetPrivilegedMode(True);
	
	CancelAllThreadsExecution();
	
	CurrentAction1 = Undefined;
	QueueNumber = -1;
	
	Try
		
		ContinueCalculation_ = False;
		
		While True Do //
			
			CalculationBoundary = Constants.CurrentBorderOfOrderStructureCalculationTasks.GetAndMove();
			
			ThereAreTasksToCalculate = SelectChangesFromQueues(CalculationBoundary, CalculationProcedure, CurrentAction1, QueueNumber);
			
			If ThereAreTasksToCalculate Then
				
				LatestRecord = Undefined;
				TotalServings = 0;
				
				While True Do
					
					If TotalServings = 0
						And ThereAreTasksToCalculate Then
						
						Jobs = SelectDataToProcess(
							CalculationProtocol.CalculationParameters,
							QueueNumber,
							CurrentAction1.QueryText,
							CurrentAction1.BatchSelectionCondition,
							LatestRecord,
							ThereAreTasksToCalculate); // ValueTable
							
						If CurrentAction1.ProcedureName = InventoryAllocationProcedure() Then
							AddIdToTableForGrouping(Jobs);
							CurrentAction1.SelectionFields1 = "Products,Characteristic,Warehouse,Purpose,Id";
						EndIf;
							
						PortionsOfCalculation = SplitIntoPortions(
							Jobs,
							CurrentAction1.SelectionFields1,
							CurrentAction1.GroupFields,
							CurrentAction1.BatchesCount);
							
						TotalServings = PortionsOfCalculation.Count();
						
					EndIf;
					
					If TotalServings > 0 Then
						
						ActionParameters = New Structure(
							"Queue,
							|PortionOfCalculation,
							|CalculationParameters",
							 QueueNumber,
							 PortionsOfCalculation[0],
							 CalculationProtocol.CalculationParameters);
						
						ExecuteThread(
							CurrentAction1.Name,
							CurrentAction1.ProcedureName,
							ActionParameters,
							CalculationProtocol);
						
						PortionsOfCalculation.Delete(0);
						
						TotalServings = TotalServings - 1;
						
					EndIf;
					
					If TotalServings > 0 Or ThereAreTasksToCalculate Then
						Continue;
					EndIf;
					
					ExpectCalculationCompletion(CalculationProtocol);
				
					If ErrorsFoundInCalculation(
							CalculationProtocol,
							PortionsOfCalculation,
							CurrentAction1) Then
						TotalServings = PortionsOfCalculation.Count();
						Continue;
					EndIf;
				
					CurrentAction1.JobsQueue.DeleteTasks(QueueNumber);
					
					ThereAreTasksToCalculate = SelectChangesFromQueues(CalculationBoundary, CalculationProcedure, CurrentAction1, QueueNumber);
					
					If ThereAreTasksToCalculate Then
						Continue;
					EndIf;
					
					Break;
					
				EndDo;
				
				ContinueCalculation_ = True;
				
			EndIf;
			
			OrderStructureInternal.PerformActionsAtEndOfCalculationCycle(CalculationBoundary);
			
			If Not ContinueCalculation_ Then
				Break;
			EndIf;
			
			ContinueCalculation_ = False;
			CalculationProtocol.CurTact = CalculationProtocol.CurTact + 1;
			
		EndDo;
		
	Except
		WriteLogEvent(OrderStructure.EventLogEventName(),
			EventLogLevel.Error,,,DetailErrorDescription(ErrorInfo()));
		CancelAllThreadsExecution();
	EndTry;
	
	RecordCalculationProtocolInLog(CalculationProtocol);
	
EndProcedure

#EndRegion

#Region Private

#Region CalculationProcedure

Function ActionParameters()

	ActionParameters = New Structure;
	
	ActionParameters.Insert("Name","");
	ActionParameters.Insert("ProcedureName","");
	
	ActionParameters.Insert("JobsQueue");
	
	ActionParameters.Insert("SelectionFields1", "");
	ActionParameters.Insert("GroupFields", "");
	ActionParameters.Insert("ErrorHandlingParameters", New Structure("ErrorType,GroupFields",,""));
	
	ActionParameters.Insert("BatchesCount", 1);
	
	Return ActionParameters;
	
EndFunction

Procedure AddTextOfBatchSelectionRequest(Action, CalculationParameters, OrderOfString)
	
	Order = StrSplit(OrderOfString, ",");
	
	QueryText =
		"SELECT DISTINCT //First10000
		|	&SelectionFields1
		|FROM
		|	&RegisterName AS Table
		|WHERE
		|	Table.Queue = &Queue
		|	AND &BatchSelectionCondition
		|//ARRANGE #Portion Selection
		|";
	
	QueryText = StrReplace(QueryText, "&RegisterName", Action.JobsQueue.FullName());
	
	QueryText = StrReplace(QueryText, "&SelectionFields1", SelectionFields1(Order));
	
	If CalculationParameters.PortionSelection Then
		QueryText = StrReplace(QueryText, "//FIRST 10000", "FIRST" + " " + Format(CalculationParameters.SelectionSize, "NZ=0; NG=0"));
		QueryText = StrReplace(QueryText, "//ORDER #PortionSelection", "ORDER BY" + " " + OrderFields(Order));
	Else
		QueryText = StrReplace(QueryText, "//FIRST 10000", "");
		QueryText = StrReplace(QueryText, "//ORDER #PortionSelection", "");
	EndIf;
	
	Action.Insert("QueryText", QueryText);
	
	Fields = Order;
	TableName = "Table";
	
	FieldsCount = Fields.Count();
	
	Result = New Array();
	
	Template1 = "%1.%2 %3 &%2";
	Template2 = "(%1)";
	
	While FieldsCount > 0 Do
		
		List = New Array(FieldsCount);
		
		Boundary = FieldsCount - 1;
		
		For IndexOf = 0 To Boundary Do
			If IndexOf = Boundary Then
				List[IndexOf] = StrTemplate(Template1, TableName, Fields[IndexOf], ">");
			Else
				List[IndexOf] = StrTemplate(Template1, TableName, Fields[IndexOf], "=");
			EndIf;
		EndDo;
		
		ConditionText = StrTemplate(Template2, StrConcat(List, " And "));
		Result.Add(ConditionText);
		
		FieldsCount = FieldsCount - 1;
		
	EndDo;
	
	Action.Insert("BatchSelectionCondition", StrConcat(Result, " OR "));
	
EndProcedure

Function SelectionFields1(Fields, TableName = "Table")
	
	FieldsCount = Fields.Count();
	
	List = New Array(FieldsCount);
	
	Template = "%1.%2 AS %2";
	
	For IndexOf = 0 To FieldsCount - 1 Do
		List[IndexOf] = StrTemplate(Template, TableName, Fields[IndexOf]);
	EndDo;
	
	Return StrConcat(List, ",");
	
EndFunction

Function OrderFields(Fields, TableName = "Table")
	
	FieldsCount = Fields.Count();
	
	List = New Array(FieldsCount);
	
	Template = "%1.%2";
	
	For IndexOf = 0 To FieldsCount - 1 Do
		List[IndexOf] = StrTemplate(Template, TableName, Fields[IndexOf]);
	EndDo;
	
	Return StrConcat(List, ",");
	
EndFunction

Function SelectDataToProcess(CalculationParameters, Queue, QueryText, BatchSelectionCondition, LatestRecord, ContinueCalculation_)
	
	Query = New Query();
	Query.SetParameter("Queue", Queue);
	Query.SetParameter("BlankID", CommonClientServer.BlankUUID());
	
	If CalculationParameters.PortionSelection And LatestRecord <> Undefined Then
		
		Query.Text = StrReplace(QueryText, "&BatchSelectionCondition", BatchSelectionCondition);
		
		For Each KeyAndValue In LatestRecord Do
			Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
		
	Else
		Query.Text = StrReplace(QueryText, "&BatchSelectionCondition", "TRUE")
	EndIf;
	
	Data = Query.Execute().Unload();
	
	If CalculationParameters.PortionSelection Then
		
		If CalculationParameters.SelectionSize > Data.Count() Then
			
			ContinueCalculation_ = False;
			LatestRecord = Undefined;
			
		Else
			
			ContinueCalculation_ = True;
			
			LastRow = Data[Data.Count()-1];
			
			If LatestRecord = Undefined Then
				
				LatestRecord = New Structure();
				
				For Each Column In Data.Columns Do
					LatestRecord.Insert(Column.Name, LastRow[Column.Name]);
				EndDo;
				
			Else
				FillPropertyValues(LatestRecord, LastRow);
			EndIf;
			
		EndIf;
		
	Else
		LatestRecord = Undefined;
		ContinueCalculation_ = False;
	EndIf;
	
	Return Data;
	
EndFunction

Function SelectChangesFromQueues(CalculationBoundary, CalculationProcedure, Action, QueueNumber)
	
	QueueNumber = -1;
	Action = Undefined;
	CurrentQueueNumber = -1;
	
	For IndexOf = 0 To CalculationProcedure.UBound() Do
		CurrentAction1 = CalculationProcedure.Get(IndexOf);
		CurrentQueueNumber = CurrentAction1.JobsQueue.SelectChanges(CalculationBoundary);
		If CurrentQueueNumber >= 0 And (QueueNumber = -1 Or QueueNumber > CurrentQueueNumber) Then
			Action = CurrentAction1;
			QueueNumber = CurrentQueueNumber;
		EndIf;
	EndDo;
	
	Return QueueNumber >= 0;
	
EndFunction

Procedure AddIdToTableForGrouping(Jobs)
	
	AnalogsAreUsed = GetFunctionalOption("UseAlternativeMaterials");
	
	Query = New Query;
	Query.SetParameter("BlankID", CommonClientServer.BlankUUID());
	Query.SetParameter("Jobs", Jobs);
	
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Purpose AS Purpose,
	|	&BlankID AS Id
	|INTO TaskTable
	|FROM
	|	&Jobs AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic";
	Query.Execute();
	
	If AnalogsAreUsed Then
	
		Query.Text = 
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	ISNULL(ItemLinksByChangeOrders.Id, ISNULL(KeyCache.Id, &BlankID)) AS Id
		|INTO TaskTableWithKeys
		|FROM
		|	TaskTable AS Table
		|		LEFT JOIN InformationRegister.ItemLinksByChangeOrders AS ItemLinksByChangeOrders
		|		ON Table.Products = ItemLinksByChangeOrders.Products
		|			AND Table.Characteristic = ItemLinksByChangeOrders.Characteristic
		|		LEFT JOIN InformationRegister.CacheOfItemLinkIDsByChangeOrders AS KeyCache
		|		ON Table.Products = KeyCache.Products
		|			AND Table.Characteristic = KeyCache.Characteristic
		|
		|INDEX BY
		|	Id
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Portions.Products AS Products,
		|	Portions.Characteristic AS Characteristic
		|FROM
		|	TaskTableWithKeys AS Portions
		|WHERE
		|	Portions.Id = &BlankID";
		
	Else
		
		Query.Text =
		"SELECT DISTINCT
		|	Portions.Products        AS Products,
		|	Portions.Characteristic      AS Characteristic
		|FROM
		|	TaskTable AS Portions
		|;";
	
	EndIf;
	
	KeyTable_ = Query.Execute().Unload();
	KeyTable_.Columns.Add("Id", New TypeDescription("UUID"));

	For Each FoundRow In KeyTable_ Do
		FoundRow.Id = New UUID();
	EndDo;
	
	PutTableOfValuesInTemporaryTable(Query.TempTablesManager, "KeysByItem", KeyTable_,,, "Products,Characteristic");
	
	Query.Text = 
	"SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Warehouse AS Warehouse,
	|	Table.Purpose AS Purpose,
	|	ISNULL(KeysByItem.Id, Table.Id) AS Id
	|FROM
	|	TaskTable AS Table
	|		LEFT JOIN KeysByItem AS KeysByItem
	|		ON Table.Products = KeysByItem.Products
	|			AND Table.Characteristic = KeysByItem.Characteristic";
	
	If AnalogsAreUsed Then
	
		Query.Text = StrReplace(Query.Text, "TaskTable", "TaskTableWithKeys");
	
	EndIf;
	
	Jobs = Query.Execute().Unload();

EndProcedure

Function InventoryAllocationProcedure()

	Return "OrderStructure.PerformInventoryAllocation";

EndFunction 

#EndRegion

#Region Nodulation

Procedure PerformUncoupling(ActionParameters, ResultAddress) Export
	
	KeyOperation = "OrderStructure.Nodulation";
	CalculationStart = CurrentUniversalDateInMilliseconds();
	PortionSize = ActionParameters.PortionOfCalculation.Count();
	TimeMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
	PerformSeparationInsideTimeMeasurement(ActionParameters);
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(TimeMeasurement, PortionSize);
	CalculationResult2 = New Structure("Operation, PortionSize, Duration", KeyOperation, PortionSize, CurrentUniversalDateInMilliseconds() - CalculationStart);
	PutToTempStorage(CalculationResult2, ResultAddress);
	
EndProcedure

Procedure PerformSeparationInsideTimeMeasurement(ActionParameters)
	
	SetPrivilegedMode(True);
	
	CalculationParameters = ActionParameters.CalculationParameters;
	
	TheProductionScheduleIsUsed = ProductionManagement.TheProductionScheduleIsUsed();
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Queue", ActionParameters.Queue);
	Query.SetParameter("PortionOfCalculation", PortionOfCalculationOfProductGroup(ActionParameters.PortionOfCalculation));
	Query.SetParameter("CalculateChanges_", CalculationParameters.CalculateChanges_);
	Query.SetParameter("AllowRepeatedUseOfCalculatedData", CalculationParameters.AllowRepeatedUseOfCalculatedData);
	Query.SetParameter("EmptySpecification", Catalogs.BillsOfMaterials.EmptyRef());
	Query.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	Query.SetParameter("EmptyStage", Catalogs.ProductionStages.EmptyRef());
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("TheProductionScheduleIsUsed", TheProductionScheduleIsUsed);
	Query.Text =
	"SELECT
	|
	|	NSICache.ProductItemsGroup AS ProductItemsGroup,
	|
	|	RegisterRecords.Products        AS Products,
	|	RegisterRecords.Characteristic      AS Characteristic,
	|	RegisterRecords.Warehouse               AS Warehouse,
	|	RegisterRecords.Purpose          AS Purpose,
	|	RegisterRecords.ProductionOrder AS ProductionOrder,
	|	RegisterRecords.KeyProducts    AS KeyProducts,
	|
	|	NSICache.BillOfMaterials AS BillOfMaterials,
	|
	|	NOT MAX(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
	|			THEN TRUE
	|		ELSE FALSE
	|	END) AS ThisIsASemiFinishedProduct,
	|
	|	MAX(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
	|			  AND RegisterRecords.ProductItemsGroup = NSICache.ProductItemsGroup
	|			THEN RegisterRecords.KeyLot
	|		ELSE &EmptyLinkKey
	|	END) AS KeyLot,
	|
	|	MAX(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
	|			THEN RegisterRecords.KeyLot
	|		ELSE &EmptyLinkKey
	|	END) AS KeyPartyParent,
	|
	|	ISNULL(MAX(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
	|			THEN RegisterRecords.Level
	|	END), 0) AS ParentLevel,
	|
	|	ISNULL(MAX(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
	|			THEN RegisterRecords.DurationBeforeProductionIssue
	|	END), 0) AS DurationUntilReleaseParent,
	|
	|	ISNULL(MAX(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
	|			THEN RegisterRecords.ProductionLotIDInProductGroup
	|	END), """") AS IdInParentProductGroup,
	|	
	|	MAX(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
	|			THEN RegisterRecords.BillOfMaterials
	|		ELSE &EmptySpecification
	|	END) AS ReleaseSpecification,
	|
	|	MAX(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
	|			THEN RegisterRecords.DataVersionID
	|		ELSE &EmptyLinkKey
	|	END) AS DataVersionID,
	|	
	|	MAX(RegisterRecords.StructureAssignment) AS StructureAssignment,
	|
	|	CASE
	|		WHEN SUM(RegisterRecords.Ordered
	|					+ RegisterRecords.ToSupply
	|					- RegisterRecords.Replaced
	|					- RegisterRecords.AllocatedFromAvailableInventory
	|					- RegisterRecords.AllocatedFromAvailableInventoryWithAssignment
	|					- RegisterRecords.AllocatedInFreeProductionLots
	|					- RegisterRecords.AllocatedInAssignedProductionLots) > 0
	|		THEN SUM(RegisterRecords.Ordered
	|					+ RegisterRecords.ToSupply
	|					- RegisterRecords.Replaced
	|					- RegisterRecords.AllocatedFromAvailableInventory
	|					- RegisterRecords.AllocatedFromAvailableInventoryWithAssignment
	|					- RegisterRecords.AllocatedInFreeProductionLots
	|					- RegisterRecords.AllocatedInAssignedProductionLots)
	|		ELSE 0
	|	END AS Required2
	|
	|INTO Delta
	|FROM
	|
	|	InformationRegister.OrderStructure AS RegisterRecords
	|
	|		INNER JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
	|		ON NSICache.Products        = RegisterRecords.Products
	|		 AND NSICache.Characteristic      = RegisterRecords.Characteristic
	|		 AND NSICache.Warehouse               = RegisterRecords.Warehouse
	|		 AND NSICache.Purpose          = RegisterRecords.Purpose
	|		 AND NSICache.ProductionOrder = RegisterRecords.ProductionOrder
	|
	|WHERE
	|	NSICache.ProductItemsGroup IN (&PortionOfCalculation)
	|	AND (NOT NSICache.ThisIsProductBeingDisassembled
	|			OR NOT RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)) // limiting looping of Reverse kitting
	|
	|GROUP BY
	|	RegisterRecords.Products, RegisterRecords.Characteristic, RegisterRecords.Warehouse, RegisterRecords.Purpose,
	|	RegisterRecords.ProductionOrder, RegisterRecords.KeyProducts, NSICache.ProductItemsGroup, NSICache.BillOfMaterials
	|
	|HAVING
	|	SUM(RegisterRecords.Ordered + RegisterRecords.ToSupply) <> 0 OR SUM(RegisterRecords.Scheduled) <> 0
	|;
	|
	|SELECT
	|
	|	DD.ProductionOrder AS ProductionOrder,
	|	DD.ProductItemsGroup       AS ProductItemsGroup,
	|	DD.BillOfMaterials        AS BillOfMaterials,
	|	DD.KeyLot          AS KeyLot,
	|
	|	MAX(DD.KeyProducts) AS KeyProducts,
	|	MAX(DD.ProductionLotIDInProductGroup) AS ProductionLotIDInProductGroup,
	|
	|	ISNULL(MAX(CASE
	|		WHEN DD.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Launched))
	|			THEN TRUE
	|	END), FALSE) AS IsLaunched
	|
	|INTO Lots
	|FROM
	|	InformationRegister.OrderStructure AS DD
	|
	|WHERE
	|	DD.ProductItemsGroup IN (&PortionOfCalculation)
	|		AND DD.LineKind IN (
	|			VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|			VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
	|			VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly),
	|			VALUE(Enum.KindsOfProductionOrderStructureLines.Launched))
	|
	|GROUP BY
	|	DD.ProductItemsGroup, DD.ProductionOrder, DD.BillOfMaterials, DD.KeyLot
	|
	|INDEX
	|	BY SETS ((ProductItemsGroup,IsLaunched,ProductionLotIDInProductGroup), (KeyLot,IsLaunched))
	|;
	|
	|SELECT DISTINCT
	|
	|	Lots.ProductItemsGroup AS ProductItemsGroup
	|
	|INTO GroupsWithErrors
	|FROM
	|	Lots AS Lots
	|
	|WHERE
	|	TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.OrderStructureCalculationProtocol AS DD
	|		WHERE
	|			DD.ErrorID = Lots.KeyLot)
	|
	|INDEX
	|	BY ProductItemsGroup
	|;
	|
	|SELECT
	|	
	|	RECORDAUTONUMBER() AS RowIndex,
	|
	|	Products_1.ProductItemsGroup AS ProductItemsGroup,
	|	
	|	Products_1.Products        AS Products,
	|	Products_1.Characteristic      AS Characteristic,
	|	Products_1.Warehouse               AS Warehouse,
	|	Products_1.Purpose          AS Purpose,
	|	Products_1.ProductionOrder AS ProductionOrder,
	|	Products_1.KeyProducts    AS KeyProducts,
	|	Products_1.KeyLot          AS KeyLot,
	|	Products_1.Required2           AS Required2,
	|	
	|	Products_1.BillOfMaterials AS BillOfMaterials,
	|	Products_1.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|
	|	Products_1.Products.ProductKind AS ProductKind,
	|	CASE
	|		WHEN NOT (Products_1.BillOfMaterials.ContainsResourcesParametrization
	|				OR Products_1.BillOfMaterials.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ItemList)
	|				OR NOT Products_1.BillOfMaterials.ProductionIssueByCustomPortions
	|				OR Products_1.BillOfMaterials.ContainsAliquotStandardsOfWorkCenterTypes
	|				OR Products_1.BillOfMaterials.MinimumReleaseLot > 0)
	|			  AND Products_1.ProductionOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.TollManufacturing2_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Cached,
	|	Products_1.BillOfMaterials.ProductionProcessType AS ProcessType,
	|	CASE
	|		WHEN Products_1.BillOfMaterials.MinimumReleaseLot > 0
	|			OR Products_1.BillOfMaterials.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ItemList)
	|			OR NOT Products_1.BillOfMaterials.ProductionIssueByCustomPortions
	|				AND NOT (Products_1.BillOfMaterials.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.Products)
	|					AND Products_1.BillOfMaterials.MainProductNumberOfPackages = 1
	|					AND Products_1.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS MultipleLaunch,
	|	Products_1.BillOfMaterials.ProductionIssueByCustomPortions AS ProductionIssueByCustomPortions,
	|	Products_1.BillOfMaterials.MinimumReleaseLot AS MinimumReleaseLot,
	|	Products_1.BillOfMaterials.EconomicReleaseLot AS EconomicReleaseLot,
	|	Products_1.BillOfMaterials.PermissibleExcessOfOptimalReleaseLot AS PermissibleExcessOfOptimalReleaseLot,
	|	CASE
	|		WHEN Products_1.BillOfMaterials.ContainsResourcesParametrization
	|			 OR Products_1.BillOfMaterials.ThereIsSpecifiedMainProduct
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ParametricSpecification,
	|	CASE
	|		WHEN Products_1.DataVersionID <> &EmptyLinkKey
	|		THEN Products_1.DataVersionID
	|		ELSE Products_1.BillOfMaterials.DataVersionID
	|	END AS DataVersionID,
	|	CASE 
	|		WHEN TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					GroupsWithErrors AS DD
	|				WHERE
	|					DD.ProductItemsGroup = Products_1.ProductItemsGroup)
	|			THEN TRUE
	|		WHEN TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.TasksOfBOMOrderStructureCalculation AS DD
	|				WHERE
	|					DD.CompleteCalculation
	|					AND DD.Queue = &Queue
	|					AND DD.BillOfMaterials = Products_1.BillOfMaterials
	|					AND DD.ProductionOrder = Products_1.ProductionOrder)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CompleteCalculation,
	|
	|	&TextOfStructureAssignmentField AS StructureAssignment,
	|	&TextOfFreeReleaseAssignmentField AS FreeReleaseAssignment,
	|
	|	Products_1.ProductionOrder.Department           AS ProductionDispatcherBusinessUnit,
	|	Products_1.ProductionOrder.LineOfBusiness AS LineOfBusiness,
	|	Products_1.ProductionOrder.EarliestStartDate           AS ProductionStart,
	|	CASE
	|		WHEN Products_1.ProductionOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TollManufacturing2_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                               AS TollManufacturing,
	|
	|	Products_1.ParentLevel AS ParentLevel,
	|	Products_1.KeyPartyParent AS KeyPartyParent,
	|	Products_1.DurationUntilReleaseParent AS DurationUntilReleaseParent,
	|	Products_1.IdInParentProductGroup AS IdInParentProductGroup
	|
	|INTO Products_1
	|FROM
	|	Delta AS Products_1
	|;
	|
	|SELECT DISTINCT
	|
	|	Products_1.DataVersionID AS DataVersionID
	|
	|INTO Products_1Cached
	|FROM
	|	Products_1 AS Products_1
	|
	|WHERE
	|	&AllowRepeatedUseOfCalculatedData
	|	AND Products_1.Cached
	|	AND NOT Products_1.CompleteCalculation
	|	AND Products_1.DataVersionID <> &EmptyLinkKey
	|
	|INDEX BY
	|	DataVersionID
	|;
	|
	|SELECT
	|
	|	RegisterRecords.DataVersionID AS DataVersionID,
	|	MAX(RegisterRecords.KeyLot) AS KeyLot
	|
	|INTO DataCache
	|FROM
	|
	|	Products_1Cached AS Products_1
	|
	|	INNER JOIN InformationRegister.OrderStructure AS RegisterRecords
	|	ON Products_1.DataVersionID = RegisterRecords.DataVersionID
	|
	|GROUP BY
	|	RegisterRecords.DataVersionID
	|
	|INDEX BY
	|	KeyLot, DataVersionID
	|;
	|
	|SELECT // DATA CACHE (nomenclature movements)
	|
	|	RegisterRecords.BillOfMaterials AS BillOfMaterials,
	|	RegisterRecords.DataVersionID AS DataVersionID,
	|
	|	CASE
	|		WHEN RegisterRecords.LineKind IN (VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
	|			THEN ""MaterialsAndServices""
	|		WHEN RegisterRecords.LineKind IN (VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|									VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
	|									VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
	|			THEN ""Products_1""
	|		WHEN RegisterRecords.LineKind IN (VALUE(Enum.KindsOfProductionOrderStructureLines.AvailableRelease))
	|			THEN ""AvailableRelease""
	|		ELSE """"
	|	END AS TSName,
	|
	|	RegisterRecords.Products   AS Products,
	|	RegisterRecords.Characteristic AS Characteristic,
	|	RegisterRecords.Warehouse          AS Warehouse,
	|
	|	CASE
	|		WHEN RegisterRecords.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS WithAssignment,
	|	CASE
	|		WHEN RegisterRecords.ToSupply <> 0 THEN
	|			VALUE(Enum.SupplyOptions.ToSupply)
	|		WHEN RegisterRecords.NotProvide <> 0 THEN
	|			VALUE(Enum.SupplyOptions.NotRequired)
	|		ELSE
	|			VALUE(Enum.SupplyOptions.EmptyRef)
	|	END AS SupplyOption,
	|
	|	RegisterRecords.Department AS Department,
	|	RegisterRecords.Stage AS Stage,
	|
	|	RegisterRecords.SemiFinishedProductBOM AS SemiFinishedProductBOM,
	|	RegisterRecords.CommunicationKeyBillOfMaterialsRow AS CommunicationKeyBillOfMaterialsRow,
	|	RegisterRecords.QuantityForLaunchLotUnit AS QuantityForLaunchLotUnit,
	|	RegisterRecords.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
	|	RegisterRecords.ProductionLotIDInProductGroup AS ProductionLotIDInProductGroup,
	|	RegisterRecords.ProductCostElement AS ProductCostElement,
	|	RegisterRecords.PermissionToReplace AS PermissionToReplace
	|
	|FROM
	|	DataCache AS Cache
	|
	|	INNER JOIN InformationRegister.OrderStructure AS RegisterRecords
	|	ON Cache.KeyLot          = RegisterRecords.KeyLot
	|	 AND Cache.DataVersionID = RegisterRecords.DataVersionID
	|	 AND NOT RegisterRecords.AdditionalRecord
	|;
	|
	|SELECT // DATA CACHE (labor costs)
	|
	|	RegisterRecords.BillOfMaterials AS BillOfMaterials,
	|	RegisterRecords.DataVersionID AS DataVersionID,
	|
	|	RegisterRecords.WorkKind AS WorkKind,
	|
	|	RegisterRecords.Department AS Department,
	|	RegisterRecords.Stage AS Stage,
	|	
	|	RegisterRecords.CommunicationKeyBillOfMaterialsRow AS CommunicationKeyBillOfMaterialsRow,
	|	RegisterRecords.QuantityForLaunchLotUnit AS QuantityForLaunchLotUnit,
	|	RegisterRecords.ProductCostElement AS ProductCostElement
	|
	|FROM
	|	DataCache AS Cache
	|
	|	INNER JOIN InformationRegister.OrderStructureLaborCosts AS RegisterRecords
	|	ON Cache.KeyLot          = RegisterRecords.KeyLot
	|	 AND Cache.DataVersionID = RegisterRecords.DataVersionID
	|	 AND NOT RegisterRecords.AdditionalRecord
	|;
	|
	|SELECT // movements before the change (movements of the nomenclature)
	|
	|	RegisterRecords.Products        AS Products,
	|	RegisterRecords.Characteristic      AS Characteristic,
	|	RegisterRecords.Warehouse               AS Warehouse,
	|	RegisterRecords.Purpose          AS Purpose,
	|	RegisterRecords.ProductionOrder AS ProductionOrder,
	|	RegisterRecords.KeyProducts    AS KeyProducts,
	|	RegisterRecords.KeyLot          AS KeyLot,
	|	RegisterRecords.LineKind           AS LineKind,
	|	RegisterRecords.ReceiptOrder  AS ReceiptOrder,
	|	RegisterRecords.DateOfReceipt     AS DateOfReceipt,
	|
	|	-RegisterRecords.ToSupply AS ToSupply,
	|	-RegisterRecords.NotProvide AS NotProvide,
	|	-RegisterRecords.Scheduled AS Scheduled,
	|	-RegisterRecords.ReverseKittingScheduled AS ReverseKittingScheduled,
	|
	|	RegisterRecords.Level                          AS Level,
	|	RegisterRecords.AdditionalRecord             AS AdditionalRecord,
	|	RegisterRecords.Department                    AS Department,
	|	RegisterRecords.Stage                             AS Stage,
	|	RegisterRecords.BillOfMaterials                     AS BillOfMaterials,
	|	RegisterRecords.DataVersionID        AS DataVersionID,
	|	RegisterRecords.CommunicationKeyBillOfMaterialsRow      AS CommunicationKeyBillOfMaterialsRow,
	|	RegisterRecords.QuantityForLaunchLotUnit AS QuantityForLaunchLotUnit,
	|	RegisterRecords.StructureAssignment              AS StructureAssignment,
	|	RegisterRecords.SemiFinishedProductBOM        AS SemiFinishedProductBOM,
	|	RegisterRecords.DurationBeforeProductionIssue            AS DurationBeforeProductionIssue,
	|	RegisterRecords.ProductionLotIDInProductGroup      AS ProductionLotIDInProductGroup,
	|	RegisterRecords.ProductItemsGroup                    AS ProductItemsGroup,
	|	RegisterRecords.ProductCostElement                AS ProductCostElement,
	|	RegisterRecords.PermissionToReplace               AS PermissionToReplace
	|
	|FROM
	|	Lots AS Lots
	|
	|	INNER JOIN InformationRegister.OrderStructure AS RegisterRecords
	|	ON Lots.KeyLot = RegisterRecords.KeyLot
	|	 AND NOT Lots.IsLaunched
	|
	|WHERE
	|	(&CalculateChanges_
	|		AND RegisterRecords.LineKind <> VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
	|	OR RegisterRecords.LineKind IN (
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption),
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.AvailableRelease)))
	|	AND (RegisterRecords.PermissionToReplace = VALUE(Document.EngineeringChangeOrder.EmptyRef))
	|;
	|
	|SELECT // movements before changes (labor costs)
	|
	|	RegisterRecords.WorkKind            AS WorkKind,
	|	RegisterRecords.ProductionOrder AS ProductionOrder,
	|	RegisterRecords.KeyWorkType        AS KeyWorkType,
	|	RegisterRecords.KeyLot          AS KeyLot,
	|
	|	-RegisterRecords.Count AS Count,
	|
	|	RegisterRecords.AdditionalRecord             AS AdditionalRecord,
	|	RegisterRecords.Department                    AS Department,
	|	RegisterRecords.Stage                             AS Stage,
	|	RegisterRecords.BillOfMaterials                     AS BillOfMaterials,
	|	RegisterRecords.DataVersionID              AS DataVersionID,
	|	RegisterRecords.CommunicationKeyBillOfMaterialsRow      AS CommunicationKeyBillOfMaterialsRow,
	|	RegisterRecords.QuantityForLaunchLotUnit AS QuantityForLaunchLotUnit,
	|	RegisterRecords.ProductCostElement                AS ProductCostElement
	|
	|FROM
	|	Lots AS Lots
	|
	|	INNER JOIN InformationRegister.OrderStructureLaborCosts AS RegisterRecords
	|	ON Lots.KeyLot = RegisterRecords.KeyLot
	|	 AND NOT Lots.IsLaunched
	|
	|WHERE
	|	&CalculateChanges_
	|;
	|
	|SELECT // nomenclature data (NSI)
	|
	|	Products_1.RowIndex                                  AS Id,
	|	Products_1.BillOfMaterials                                  AS BillOfMaterials,
	|	Products_1.Products                                  AS Products,
	|	Products_1.Characteristic                                AS Characteristic,
	|	Products_1.Required2                                     AS Count,
	|
	|	Products_1.ProductionDispatcherBusinessUnit                        AS ProductionDispatcherBusinessUnit,
	|	Products_1.LineOfBusiness                       AS LineOfBusiness,
	|	Products_1.ProductionStart                            AS ProductionStart
	|
	|FROM
	|	Products_1 AS Products_1
	|
	|WHERE
	|	(Products_1.CompleteCalculation
	|		OR NOT Products_1.Cached
	|		OR (Products_1.DataVersionID) NOT
	|			 IN (
	|				SELECT
	|					Cache.DataVersionID FROM DataCache
	|			AS Cache))
	|	AND Products_1.Required2 <> 0
	|;
	|
	|SELECT // Production schedule
	|
	|	Table.ProductionOrder AS ProductionOrder,
	|	Table.KeyLot AS KeyLot
	|
	|FROM
	|	SubstitutingTasksForCalculationOfSchedule AS Table
	|;
	|
	|SELECT // all parties
	|
	|	Lots.ProductionOrder AS ProductionOrder,
	|	Lots.BillOfMaterials        AS BillOfMaterials,
	|	Lots.ProductItemsGroup       AS ProductItemsGroup,
	|	Lots.KeyLot          AS KeyLot,
	|
	|	Lots.KeyProducts AS KeyProducts, // the main key of the nomenclature
	|	Lots.ProductionLotIDInProductGroup AS ProductionLotIDInProductGroup,
	|
	|	Lots.IsLaunched AS IsLaunched,
	|	CASE 
	|		WHEN Lots.IsLaunched
	|			OR TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					Lots AS DD
	|				WHERE
	|					DD.ProductItemsGroup = Lots.ProductItemsGroup
	|					AND DD.IsLaunched
	|					AND DD.ProductionLotIDInProductGroup = Lots.ProductionLotIDInProductGroup)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS KeyIsUsed,
	|
	|	GroupsWithErrors.ProductItemsGroup IS NOT NULL AS HadErrors
	|
	|FROM
	|	Lots AS Lots
	|		LEFT JOIN GroupsWithErrors AS GroupsWithErrors
	|		ON Lots.ProductItemsGroup = GroupsWithErrors.ProductItemsGroup
	|
	|ORDER BY
	|	ProductItemsGroup
	|;
	|
	|SELECT // all products
	|
	|	Products_1.RowIndex AS RowIndex,
	|
	|	Products_1.ProductItemsGroup AS ProductItemsGroup,
	|	
	|	Products_1.Products        AS Products,
	|	Products_1.Characteristic      AS Characteristic,
	|	Products_1.Warehouse               AS Warehouse,
	|	Products_1.Purpose          AS Purpose,
	|	Products_1.ProductionOrder AS ProductionOrder,
	|	Products_1.KeyProducts    AS KeyProducts,
	|	Products_1.KeyLot          AS KeyLot,
	|	Products_1.Required2           AS Required2,
	|
	|	Products_1.BillOfMaterials AS BillOfMaterials,
	|
	|	Products_1.ParentLevel AS ParentLevel,
	|	Products_1.KeyPartyParent AS KeyPartyParent,
	|	Products_1.DurationUntilReleaseParent AS DurationUntilReleaseParent,
	|	Products_1.IdInParentProductGroup AS IdInParentProductGroup,
	|
	|	Products_1.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	Products_1.TollManufacturing AS TollManufacturing,
	|	Products_1.StructureAssignment AS StructureAssignment,
	|	Products_1.FreeReleaseAssignment AS FreeReleaseAssignment,
	|	
	|	Products_1.Cached AS Cached,
	|	Products_1.ProcessType AS ProcessType,
	|	Products_1.ParametricSpecification AS ParametricSpecification,
	|	Products_1.MultipleLaunch AS MultipleLaunch,
	|	Products_1.ProductionIssueByCustomPortions AS ProductionIssueByCustomPortions,
	|	Products_1.MinimumReleaseLot AS MinimumReleaseLot,
	|	Products_1.EconomicReleaseLot AS EconomicReleaseLot,
	|	Products_1.PermissibleExcessOfOptimalReleaseLot AS AllowableExcessOf,
	|	Products_1.DataVersionID AS DataVersionID,
	|	Products_1.CompleteCalculation AS CompleteCalculation,
	|
	|	ISNULL(CASE
	|		WHEN Products_1.ParametricSpecification AND ProductsBOM.Order <> 1
	|			THEN TRUE
	|		WHEN ProductsBOM.SideExit
	|			THEN TRUE
	|	END, FALSE) AS SideExit,
	|
	|	ISNULL(ProductsBOM.Order, 1) AS Order,
	|	ISNULL(ProductsBOM.NumberOfPackagesPerStartingLotUnit, 1) * ISNULL(&QueryTextPackagingFactor1, 1) AS QuantityForLaunchLotUnit,  
	|	ISNULL(CASE
	|		WHEN ProductsBOM.NumberOfPackagingUnitsPerStartingLotUnit = 0
	|			THEN 1
	|		ELSE ProductsBOM.NumberOfPackagingUnitsPerStartingLotUnit 
	|	END, 1) * ISNULL(&QueryTextPackagingFactor2, 1) AS QuantityOfMainProductPerUnitOfLaunchBatch
	|FROM
	|	Products_1 AS Products_1
	|
	|	LEFT JOIN InformationRegister.ProductsBOM AS ProductsBOM
	|	ON Products_1.BillOfMaterials = ProductsBOM.BillOfMaterials
	|	 AND ProductsBOM.ProductKind = Products_1.ProductKind
	|	 AND ProductsBOM.Products   IN (Products_1.Products, VALUE(Catalog.Products.EmptyRef))
	|	 AND ProductsBOM.Characteristic IN (Products_1.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|
	|WHERE
	|	Products_1.Required2 > 0
	|
	|ORDER BY
	|	ProductItemsGroup
	|;
	|";
	Query.Text = StrReplace(Query.Text, "&TextOfStructureAssignmentField", OrderStructureDocumentPosting.TextOfMaterialsAssignmentField("Products_1.ProductionOrder", "Products_1.StructureAssignment"));
	Query.Text = StrReplace(Query.Text, "&TextOfFreeReleaseAssignmentField", OrderStructureDocumentPosting.TextOfFreeReleaseAssignmentField("Products_1.ProductionOrder"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("ProductsBOM.Package", "Products_1.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("ProductsBOM.MainProductPackagingUnit", "Products_1.Products"));
	
	If TheProductionScheduleIsUsed Then
		SubstitutingTasksForCalculationOfSchedule =
		"SELECT DISTINCT
		|	Products_1.ProductionOrder AS ProductionOrder,
		|	&EmptyLinkKey AS KeyLot
		|FROM
		|	Products_1 AS Products_1
		|WHERE
		|	Products_1.Required2 > 0
		|		AND TRUE NOT IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				InformationRegister.ScheduleOfProductionStages2_2 AS Table
		|			WHERE
		|				Table.ProductionOrder = Products_1.ProductionOrder
		|				AND Table.ScheduleStatus = 0)";
	Else
		SubstitutingTasksForCalculationOfSchedule = 
		"SELECT DISTINCT
		|	Products_1.ProductionOrder AS ProductionOrder,
		|	CASE
		|		WHEN TRUE NOT IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				InformationRegister.TargetOrderStructureSchedule AS Table
		|			WHERE
		|				Table.ProductionOrder = Products_1.ProductionOrder)
		|			THEN &EmptyLinkKey
		|		ELSE ISNULL(Lots.KeyLot, Products_1.KeyPartyParent)
		|	END AS KeyLot
		|FROM
		|	Products_1 AS Products_1
		|		LEFT JOIN Lots AS Lots
		|		ON Products_1.ProductItemsGroup = Lots.ProductItemsGroup
		|		 AND NOT Lots.IsLaunched
		|WHERE
		|	TRUE NOT IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.OrderStructureCalculationProtocol AS Table
		|		WHERE
		|			Table.ProductionOrder = Products_1.ProductionOrder
		|			AND Table.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.TargetScheduleCalculationError))";
	EndIf;
	Query.Text = StrReplace(Query.Text, "SubstitutingTasksForCalculationOfSchedule", "(" + SubstitutingTasksForCalculationOfSchedule + ")");
		
	Storage = Storage();

	QueryResult = Query.ExecuteBatch();
	NumberOfPackages_ = QueryResult.Count();
	
	Query.TempTablesManager.Close();

#Region DataCache
	
	DataCache = New Structure();
	DataCache.Insert("OrderStructure", QueryResult[NumberOfPackages_-8].Unload());
	DataCache.OrderStructure.Indexes.Add("BillOfMaterials,DataVersionID");
	DataCache.Insert("LaborCosts", QueryResult[NumberOfPackages_-7].Unload());
	DataCache.LaborCosts.Indexes.Add("BillOfMaterials,DataVersionID");
	
#EndRegion

#Region RegisteredRecordsBeforeChange
	
	UploadRegisteredRecordsToVault(Storage, "OrderStructure",             QueryResult[NumberOfPackages_-6].Unload(),, New Structure("RegisteredRecordsBeforeChange", True));
	UploadRegisteredRecordsToVault(Storage, "OrderStructureLaborCosts", QueryResult[NumberOfPackages_-5].Unload(),, New Structure("RegisteredRecordsBeforeChange", True));
	
#EndRegion

#Region MasterData
	
	If QueryResult[NumberOfPackages_-4].IsEmpty() Then
		SpecificationsData = New Map();
	Else
		SpecificationsData = Catalogs.BillsOfMaterials.SpecificationData(QueryResult[NumberOfPackages_-4].Unload(), SpecificationDataSamplingParameters());
	EndIf;
	
#EndRegion

#Region ProductionSchedule

	// In the normative schedule, tasks are registered according to a simplified scheme, in the combat schedule they are calculated according to changes.
	
	If Not TheProductionScheduleIsUsed Then
		InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddTasks(QueryResult[NumberOfPackages_-3].Unload());
	Else
		If QueryResult[NumberOfPackages_-3].IsEmpty() Then
			TasksForCalculatingSchedule = InformationRegisters.OrderStructureCalculationJobsProductionSchedule.CreateRecordSet().UnloadColumns("ProductionOrder,KeyLot");
			ThereAreTasksForCalculationOfScheduleFullCalculation = False;
		Else
			TasksForCalculatingSchedule = QueryResult[NumberOfPackages_-3].Unload();
			ThereAreTasksForCalculationOfScheduleFullCalculation = True;
			TasksForCalculationOfScheduleFullCalculation = TasksForCalculatingSchedule.Copy();
			TasksForCalculationOfScheduleFullCalculation.GroupBy("ProductionOrder");
			TasksForCalculationOfScheduleFullCalculation.Indexes.Add("ProductionOrder");
		EndIf;
		TasksForClearingSchedule = TasksForCalculatingSchedule.CopyColumns();
	EndIf;
	
#EndRegion

#Region KeysLinks

	Parameters = New Structure;
	Parameters.Insert("Rows", New Structure("AdditionalRecord", False));
	Parameters.Insert("Columns", "KeyLot,KeyProducts,CommunicationKeyBillOfMaterialsRow");
	Parameters.Insert("ColumnsByValue");
	Parameters.Insert("NewColumnNames", New Structure("KeyProducts", "ConnectionKey"));
	
	CacheCommunicationKeys1 = TMCommonUse.ExportValuesTable(
		Storage.OrderStructure,
		Parameters.Rows,
		Parameters.Columns,
		Parameters.ColumnsByValue,
		Parameters.NewColumnNames);
	
	Parameters = New Structure;
	Parameters.Insert("Rows", New Structure("AdditionalRecord", False));
	Parameters.Insert("Columns", "KeyLot,KeyWorkType,CommunicationKeyBillOfMaterialsRow");
	Parameters.Insert("ColumnsByValue");
	Parameters.Insert("NewColumnNames", New Structure("KeyWorkType", "ConnectionKey"));
	
	CacheCommunicationKeys2 = TMCommonUse.ExportValuesTable(
		Storage.OrderStructureLaborCosts,
		Parameters.Rows,
		Parameters.Columns,
		Parameters.ColumnsByValue,
		Parameters.NewColumnNames);
	
	ConnectTables(CacheCommunicationKeys1, CacheCommunicationKeys2);
	
	KeysLinks = New Structure("Cache, Key", CacheCommunicationKeys1, New Structure("KeyLot, CommunicationKeyBillOfMaterialsRow"));
	
	CacheCommunicationKeys1 = Undefined;
	CacheCommunicationKeys2 = Undefined;
	
	KeysLinks.Cache.Indexes.Add("KeyLot,CommunicationKeyBillOfMaterialsRow");

#EndRegion

	// Parties Before The Change
	PartiesBeforeChange = CopyColumns(QueryResult[NumberOfPackages_-2].Columns);
	PartiesBeforeChange.Columns.Add("IdInProductGroupKeyParent", Common.StringTypeDetails(35)); // See definable types.The identifier of the Product groupstructure of the order
	MaximumLotReferenceCodeInProductGroup = New Map;
	MaxLotReferenceCodeCurrent = 0;
	CurrentProductGroup = Undefined;
	Selection = QueryResult[NumberOfPackages_-2].Select();
	While Selection.Next() Do
		IdInProductGroupKeyParent = ExtractParentKeyFromId(Selection.ProductionLotIDInProductGroup);
		MaxLotReferenceCode = ExtractLotReferenceCodeFromIdentifier(Selection.ProductionLotIDInProductGroup);
		If CurrentProductGroup <> Selection.ProductItemsGroup Or MaxLotReferenceCode > MaxLotReferenceCodeCurrent Then
			MaximumLotReferenceCodeInProductGroup[Selection.ProductItemsGroup] = MaxLotReferenceCode;
			MaxLotReferenceCodeCurrent = MaxLotReferenceCode;
			CurrentProductGroup = Selection.ProductItemsGroup
		EndIf;
		If Not Selection.IsLaunched Then // subject to rescheduling (dynamic batch)
			Lot = PartiesBeforeChange.Add();
			FillPropertyValues(Lot, Selection);
			Lot.IdInProductGroupKeyParent = IdInProductGroupKeyParent;
		EndIf;
	EndDo;
	PartiesBeforeChange.Indexes.Add("ProductItemsGroup, IdInProductGroupKeyParent");
	CacheLotReferenceSearchKey = New Structure("ProductItemsGroup, IdInProductGroupKeyParent");
	CacheLotReference = Undefined;
	
	AllBatchesAreNew = Not PartiesBeforeChange.Count() > 0;
	HadErrors = False;

	// The current Lot reference
	Lots = CopyColumns(PartiesBeforeChange.Columns,, "KeyProducts");
	Lots.Columns.Add("BatchSize", New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Any))); // in the unit of the main finishedproduct
	Lots.Columns.Add("NewBatch_", New TypeDescription("Boolean"));
	Lots.Columns.Add("CalculateChanges_", New TypeDescription("Boolean"));
	Lots.Columns.Add("Valid", New TypeDescription("Boolean"));
	Lots.Columns.Add("TollManufacturing", New TypeDescription("Boolean"));
	Lots.Columns.Add("Protocol");
	PartiesGroups = Lots.CopyColumns();
	PartiesGroups.Columns.Add("Rows", New TypeDescription("Array"));
	PartiesGroups.Columns.Add("LineAdjustment");
	PartiesGroups.Columns.Add("Balance"); // a number or an array of numbers
	
	LotStructure = New Structure("KeyLot");
	EmptyLinkKey = New UUID("00000000-0000-0000-0000-000000000000");
	
	Products_1 = QueryResult[NumberOfPackages_-1].Unload();
	ProductsOfGroup = CopyColumns(Products_1.Columns, "Order,Required2,SideExit,DurationUntilReleaseParent,IdInParentProductGroup");
	ProductsOfGroup.Columns.Add("GroupFields", New TypeDescription("String"));
	ProductsOfGroup.Columns.Add("Product");
	
	TotalProductNumber = Products_1.Count();
	IndexOf = 0;
	
	While TotalProductNumber > IndexOf Do
		
		Product = Products_1[IndexOf];

		ProductItemsGroup = Product.ProductItemsGroup;
		MaximumLotNumber = ValueFromMatch(MaximumLotReferenceCodeInProductGroup, ProductItemsGroup, 0);
		
		If Not
			(Product.MultipleLaunch Or Product.EconomicReleaseLot > 0 Or Product.SideExit) Then
			
			While TotalProductNumber > IndexOf And ProductItemsGroup = Products_1[IndexOf].ProductItemsGroup Do
				Product = Products_1[IndexOf];
				
				Lot = PartiesGroups.Add();
				FillPropertyValues(Lot, Product, "ProductionOrder,ProductItemsGroup,BillOfMaterials" + ", TollManufacturing");
				Lot.BatchSize = Product.Required2;
				Lot.Rows.Add(Product);
				
				IdInProductGroupKeyParent = ExtractLotReferenceKeyFromId(Product.IdInParentProductGroup); // parent ID
				If Not AllBatchesAreNew
					And FindBatchKeyInCache(PartiesBeforeChange, IdInProductGroupKeyParent, Product.ProductItemsGroup, Product, CacheLotReferenceSearchKey, CacheLotReference) Then
					FillPropertyValues(Lot, CacheLotReference, "KeyLot,ProductionLotIDInProductGroup");
				Else
					MaximumLotNumber = MaximumLotNumber + 1;
					Lot.KeyLot = New UUID();
					Lot.NewBatch_ = True;
					Lot.ProductionLotIDInProductGroup = IdOfLotReferenceInProductGroup(
						Product.ProductItemsGroup,
						IdInProductGroupKeyParent,
						Product.ParentLevel,
						MaximumLotNumber);
				EndIf;
				
				IndexOf = IndexOf + 1;
			EndDo;
			
		Else
			
			ProductionIssueByCustomPortions = Product.ProductionIssueByCustomPortions;
			ConversionFactorOfLaunchBatch = ?(ProductionIssueByCustomPortions, 1, Product.QuantityOfMainProductPerUnitOfLaunchBatch);
			OptimalRelease = Round(Product.EconomicReleaseLot * ConversionFactorOfLaunchBatch, 3);
			MinimumOutput = Round(Product.MinimumReleaseLot * ConversionFactorOfLaunchBatch, 3);
			AllowableExcessOf = Round(Product.AllowableExcessOf * ConversionFactorOfLaunchBatch, 3);
			DeltaMinimumOptimum = Product.EconomicReleaseLot - Product.MinimumReleaseLot;
			
			MaxOrder = Product.Order;
			ThereIsDifferentOrder = False;
			ThereIsAccessibilityRestriction = False; 
			
			While TotalProductNumber > IndexOf And ProductItemsGroup = Products_1[IndexOf].ProductItemsGroup Do
				
				Product = Products_1[IndexOf];
				
				ProductOfGroup = ProductsOfGroup.Add();
				FillPropertyValues(ProductOfGroup, Product, "Order,Required2,SideExit,DurationUntilReleaseParent,IdInParentProductGroup");
				ProductOfGroup.Product = Product;
				
				If Not Product.SideExit Then
					If Not Product.MultipleLaunch Then
						ProductOfGroup.GroupFields = "" + Product.KeyProducts;
					Else
						
						Hash = New DataHashing(HashFunction.SHA256);
						
						If Product.MultipleLaunch Then
							Hash.Append("" + Product.ProductItemsGroup);
							Hash.Append("" + Product.KeyPartyParent);
							Hash.Append("" + Product.DurationUntilReleaseParent);
						EndIf;
						
						If Not Product.StructureAssignment.IsEmpty() Then
							Hash.Append("" + Product.StructureAssignment.UUID()); 
							ThereIsAccessibilityRestriction = True;
						EndIf;
						
						If Product.ParametricSpecification Then
							Hash.Append("" + Product.Products.UUID());
							Hash.Append("" + Product.Characteristic.UUID());
							ThereIsAccessibilityRestriction = True;
						EndIf;
						
						ProductOfGroup.GroupFields = Hash.HashSum;
					EndIf;
					
				EndIf;
				
				If MaxOrder <> Product.Order Then
					MaxOrder = Max(MaxOrder, Product.Order);
					ThereIsDifferentOrder = True;
				EndIf;
				
				IndexOf = IndexOf + 1;
				
			EndDo;
			
			SortFields = "DurationUntilReleaseParent DESC, SideExit, IdInParentProductGroup, GroupFields, Order, Required2 DESC";
			ProductsOfGroup.Sort(SortFields, New CompareValues());

			BorderOfProductGroup = ProductsOfGroup.Count() - 1;
			ClockForCalculatingLotReferenceSize = True;
			i = 0; // cursor to search for the Balance in the Lot references
			X = 0; // Finished products traversal iterator
			Y = 0; // iterator for calculating Lot references (right border)
			BorderOfProductsIsPreviousOne = 0;
			BorderOfPartiesIsCurrent = -1;
			GroupFields = Undefined;
			HasErrors = False;
			
			CurrentFinishedProduct = Undefined; // The main finished product of the Lot reference
			CurrOrder = -1;
			PreviousBatchSize = 0;
			BatchSize = 0;
			ManufacturedProductQuantity = 0;
			
			While BorderOfProductGroup >= X Do
				
				ProductOfGroup = ProductsOfGroup[X];
				
				If ThereIsDifferentOrder And CurrOrder <> ProductOfGroup.Order Or ThereIsAccessibilityRestriction And (MinimumOutput > 0 Or Not ProductionIssueByCustomPortions) Then
					// we bypass all batches if the composition of the products is scattered or there is a residue in the batches, but not all batches can be used for leftovers
					i = 0;
				EndIf;
				
				While BorderOfPartiesIsCurrent >= i And ProductOfGroup.Required2 > 0 Do // accounting of the Balance in Lots Reference 
					
					Product = ProductOfGroup.Product;
					Lot = PartiesGroups[i];
					
					If Lot.KeyLot <> EmptyLinkKey Then // Lot reference initialized
						If ThereIsAccessibilityRestriction
							And (Not Product.SideExit And Product.StructureAssignment <> Lot.Rows[0].StructureAssignment
								Or Product.ParametricSpecification 
									And Product.Order = 1 
									And (Product.Products <> Lot.Rows[0].Products
											Or Product.Characteristic <> Lot.Rows[0].Characteristic)) Then
							BalanceOfLotReference = 0;
						Else
							If Not ThereIsDifferentOrder Then 
								BalanceOfLotReference = Lot.Balance;
							Else
								BalanceOfLotReference = Lot.Balance[ProductOfGroup.Order - 1];
								If BalanceOfLotReference = Undefined Then
									BalanceOfLotReference = ?(Product.Order > 1, Lot.BatchSize * Product.QuantityForLaunchLotUnit / Product.QuantityOfMainProductPerUnitOfLaunchBatch, Lot.BatchSize);
								EndIf;
							EndIf;
						EndIf;
					Else
						FillPropertyValues(Lot, Product, "ProductionOrder,ProductItemsGroup,BillOfMaterials" + ",TollManufacturing");
						IdInProductGroupKeyParent = ExtractLotReferenceKeyFromId(Product.IdInParentProductGroup); // parent ID
						If Not AllBatchesAreNew
							And FindBatchKeyInCache(PartiesBeforeChange, IdInProductGroupKeyParent, Product.ProductItemsGroup, Product, CacheLotReferenceSearchKey, CacheLotReference) Then
							FillPropertyValues(Lot, CacheLotReference, "KeyLot,ProductionLotIDInProductGroup");
						Else
							MaximumLotNumber = MaximumLotNumber + 1;
							Lot.KeyLot = New UUID();
							Lot.NewBatch_ = True;
							Lot.ProductionLotIDInProductGroup = IdOfLotReferenceInProductGroup(
								Product.ProductItemsGroup,
								IdInProductGroupKeyParent,
								Product.ParentLevel,
								MaximumLotNumber);
						EndIf;
						BalanceOfLotReference = ?(Product.Order > 1, Lot.BatchSize * Product.QuantityForLaunchLotUnit / Product.QuantityOfMainProductPerUnitOfLaunchBatch, Lot.BatchSize);
						If ThereIsDifferentOrder Then
							Lot.Balance = New Array(MaxOrder);
						EndIf;
					EndIf;
					
					Allocated = Min(BalanceOfLotReference, ProductOfGroup.Required2);
					If Allocated > 0 Then
						
						Lot.Rows.Add(Product);
						
						If Allocated <> Product.Required2 Then 
							Lot.LineAdjustment = ?(Lot.LineAdjustment = Undefined, New Map(), Lot.LineAdjustment);
							Lot.LineAdjustment.Insert(Product.KeyProducts, Product.Required2 - Allocated);
						EndIf;
						
						ProductOfGroup.Required2 = ProductOfGroup.Required2 - Allocated;  
						BalanceOfLotReference = BalanceOfLotReference - Allocated;
					
						If ThereIsDifferentOrder Then
							Lot.Balance[ProductOfGroup.Order-1] = BalanceOfLotReference;
						Else
							Lot.Balance = BalanceOfLotReference;
						EndIf;
						
					EndIf;
					
					If BalanceOfLotReference = 0 Then
						i = i + 1;
					EndIf;
					
				EndDo;
				
				If ClockForCalculatingLotReferenceSize Then
					
					GroupingIsEqualTo = (GroupFields = ProductOfGroup.GroupFields 
						Or GroupFields = Undefined);
					If GroupingIsEqualTo Then // calculation of the Lot reference size
						If CurrentFinishedProduct = Undefined Then
							CurrentFinishedProduct = ProductOfGroup.Product;
							CurrOrder = ProductOfGroup.Order;
						EndIf;
						// the side output does not participate in the calculation of the Lot reference size
						If Not ProductOfGroup.Product.SideExit Then
						 	If CurrOrder = ProductOfGroup.Order Then 
								ManufacturedProductQuantity = ManufacturedProductQuantity + ProductOfGroup.Required2;
							Else
								BatchSize = ?(CurrentFinishedProduct.Order > 1, ManufacturedProductQuantity * CurrentFinishedProduct.QuantityOfMainProductPerUnitOfLaunchBatch / CurrentFinishedProduct.QuantityForLaunchLotUnit, ManufacturedProductQuantity);
								PreviousBatchSize = Max(BatchSize, PreviousBatchSize);
								CurrentFinishedProduct = ProductOfGroup.Product;
								CurrOrder = ProductOfGroup.Order;
								ManufacturedProductQuantity = ProductOfGroup.Required2;
							EndIf;
						EndIf;
						X = X + 1;
						Y = X;
					EndIf;
					If Not GroupingIsEqualTo Or X > BorderOfProductGroup Then // The formation of Lot references
						
						BatchSize = ?(CurrentFinishedProduct.Order > 1, ManufacturedProductQuantity * CurrentFinishedProduct.QuantityOfMainProductPerUnitOfLaunchBatch / CurrentFinishedProduct.QuantityForLaunchLotUnit, ManufacturedProductQuantity);
						BatchSize = Max(BatchSize, PreviousBatchSize);

						ClockForCalculatingLotReferenceSize = False;
						X = BorderOfProductsIsPreviousOne;
						BorderOfPartiesIsPreviousOne = BorderOfPartiesIsCurrent;
						
						If Not ProductionIssueByCustomPortions Then
							// rounding up to whole Lot references
							BatchesCount = BatchSize / ConversionFactorOfLaunchBatch;
							If Int(BatchesCount) <> BatchesCount Then
								BatchSize = (Int(BatchesCount) + 1) * ConversionFactorOfLaunchBatch;
							EndIf;
						EndIf;
						
						If BatchSize > 0 Then
							If OptimalRelease > 0 Then 
								
								While BatchSize >= OptimalRelease Do
									PartiesGroups.Add().BatchSize = OptimalRelease;
									BatchSize = BatchSize - OptimalRelease; 
									BorderOfPartiesIsCurrent = BorderOfPartiesIsCurrent + 1;
								EndDo;
								
								QuantityOfBatches = (BorderOfPartiesIsCurrent - BorderOfPartiesIsPreviousOne);
								
								// if we can cover the balance due to the allowable excess
								If BatchSize <= QuantityOfBatches * AllowableExcessOf Then
									
									For Cnt = -BorderOfPartiesIsCurrent To -(BorderOfPartiesIsPreviousOne + 1) Do
										If BatchSize <= 0 Then
											Break;
										EndIf;
										PartiesGroups[-Cnt].BatchSize = PartiesGroups[-Cnt].BatchSize + Min(AllowableExcessOf, BatchSize);
										BatchSize = BatchSize - Min(AllowableExcessOf, BatchSize);
									EndDo;
									
								// if we can cover the remainder by reducing the optimal batches to the minimum
								Else  
								
									For Cnt = -BorderOfPartiesIsCurrent To -(BorderOfPartiesIsPreviousOne + 1) Do
										If BatchSize >= MinimumOutput Then
											Break;
										EndIf;
										PartiesGroups[-Cnt].BatchSize = PartiesGroups[-Cnt].BatchSize - Min(DeltaMinimumOptimum, MinimumOutput - BatchSize);
										BatchSize = BatchSize + Min(DeltaMinimumOptimum, MinimumOutput - BatchSize);
									EndDo;
									
									PartiesGroups.Add().BatchSize = Max(BatchSize, MinimumOutput);
									BorderOfPartiesIsCurrent = BorderOfPartiesIsCurrent + 1;

								EndIf;
								
							Else
								
								PartiesGroups.Add().BatchSize = Max(BatchSize, MinimumOutput);
								BorderOfPartiesIsCurrent = BorderOfPartiesIsCurrent + 1;
								
							EndIf;
						EndIf;
						
						i = BorderOfPartiesIsPreviousOne + 1;
						
						CurrentFinishedProduct = Undefined;
						CurrOrder = -1;
						PreviousBatchSize = 0;
						BatchSize =  0;
						ManufacturedProductQuantity = 0;
						
					EndIf;
					GroupFields = ProductOfGroup.GroupFields;
					
				Else
					If ProductOfGroup.Required2 > 0 Then
						HasErrors = True;
					EndIf;
					X = X + 1;
					If Y = X Then
						ClockForCalculatingLotReferenceSize = True;
						BorderOfProductsIsPreviousOne = Y;
					EndIf;
				EndIf;
				
			EndDo;
			
			If HasErrors Then
				
				If BorderOfPartiesIsCurrent = -1 Then // there are only side products in the order
					
					Lot = PartiesGroups.Add();
					FillPropertyValues(Lot, Product, "ProductionOrder,ProductItemsGroup,BillOfMaterials, KeyLot");
					
					For Each String In ProductsOfGroup Do
						Lot.Rows.Add(String.Product);
					EndDo;
					
					If Lot.KeyLot = EmptyLinkKey Then
						Lot.NewBatch_ = True;
						Lot.KeyLot = New UUID();
					EndIf;
					
				EndIf;
				
				Lot = PartiesGroups[0];
				
				For Each String In ProductsOfGroup Do
					
					If String.Required2 = 0 Then
						Continue;
					EndIf;
					
					Lot.HadErrors = True;
					ProductPresentation = ProductsClientServer.ProductPresentation(String.Product.Products, String.Product.Characteristic,,,String.Product.Purpose);
					Template = NStr("vi = 'Không thể lập kế hoạch sản phẩm ""%1"" với số lượng %2 %3 theo bảng kê chi tiết %4 ""%5"".';
									|ru = 'Не удалось запланировать изделие ""%1"" в количестве %2 %3 по спецификации %4 ""%5"".';
									|en = 'Cannot schedule the ""%1"" finished product in the amount of %2 %3 under the %4 ""%5"" BOM.'; fa = 'Cannot schedule the ""%1"" finished product in the amount of %2 %3 under the %4 ""%5"" BOM.';
									|it = 'Non è stato possibile pianificare la produzione ""%1"" nella quantità %2 %3 in base alle specifiche %4""%5"".';
									|pl = 'Nie udało się zaplanować wyrobu ""%1"" w ilości %2 %3 według specyfikacji %4 ""%5"".';
									|tr = '""%5"" %4 ürün reçetesine göre %3 %2 miktarındaki ""%1"" nihai ürünü planlanamadı.'");
					MessageText = StrTemplate(Template,
						ProductPresentation, String.Required2, String.Product.Products.UnitOfMeasure, String.Product.BillOfMaterials.Code, String.Product.BillOfMaterials.Description);
					AddMessageToErrorList(Lot.Protocol, MessageText);
					WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Error,,Lot.ProductionOrder,
						MessageText);
					
				EndDo;
				
			EndIf;
			
			ProductsOfGroup.Clear();
			
		EndIf;
		
		For Each Lot In PartiesGroups Do
			
			If Lot.Rows.Count() > 0
				And CheckLoopingOfOrderStructure(Lot, Lot.Rows, CalculationParameters) Then
				Lot.BatchSize = 0; // blocking the calculation
			EndIf;
			
			FillInRegisteredRecordsBasedOnResultOfSeparation(Storage, Lot, Lot.Rows, DataCache, SpecificationsData, KeysLinks);
			
			Lot.Valid             = Lot.BatchSize > 0 Or Lot.Rows.Count() > 0;
			Lot.CalculateChanges_ = Lot.Valid And Not Lot.NewBatch_ And Not Product.CompleteCalculation And Not Lot.HadErrors And CalculationParameters.CalculateChanges_;
			
			FillPropertyValues(Lots.Add(), Lot);
			
			If TheProductionScheduleIsUsed
				And Lot.Valid
				And (Not ThereAreTasksForCalculationOfScheduleFullCalculation
					Or TasksForCalculationOfScheduleFullCalculation.Find(Lot.ProductionOrder, "ProductionOrder") = Undefined) Then
				FillPropertyValues(TasksForCalculatingSchedule.Add(), Lot);
			EndIf;
			
			HadErrors = HadErrors Or Lot.HadErrors;
			
		EndDo;
		
		CacheOfLotReferencesOfFinishedProductGroup = Undefined;
		PartiesGroups.Clear();
		
	EndDo;
	
	Products_1.Clear();
	KeysLinks = Undefined;
	
	// after the calculation, the "old" batch keys may remain in the IB, they need to "erase" the data
	
	If Not
		AllBatchesAreNew Then
		
		Lots.Indexes.Add("KeyLot");
		
		For Each BatchBeforeChange In PartiesBeforeChange Do
			
			HadErrors = HadErrors Or BatchBeforeChange.HadErrors;
			
			Lot = Lots.Find(BatchBeforeChange.KeyLot, "KeyLot");
			
			If Not Lot = Undefined Then
				Lot.HadErrors = Lot.HadErrors Or BatchBeforeChange.HadErrors; 
				Continue;
			EndIf;
			
			FillPropertyValues(Lots.Add(), BatchBeforeChange);
			
			If TheProductionScheduleIsUsed Then
				FillPropertyValues(TasksForClearingSchedule.Add(), BatchBeforeChange);
			EndIf;
			
		EndDo;
		
	EndIf;

	MaximumLotReferenceCodeInProductGroup = Undefined;
	PartiesBeforeChange = Undefined;
	
	// calculation of the "delta" for recording changes according to specifications "repeat.isp = false" (in the "add-on" mode)
	
	If AllBatchesAreNew Then
		
		TotalRows = 0;
		
		For Each Data In Storage Do
			
			Table = Data.Value; // ValueTable
			
			Table.Columns.Add("PortionNumber", Common.TypeDescriptionNumber(4, 0));
			Table.Indexes.Add("KeyLot");
			
			TotalRows = Max(TotalRows, Table.Count());
			
		EndDo;
		
	Else
		
		FoundBatches = Lots.FindRows(New Structure("CalculateChanges_", True));
		
		TotalRows = 0;
		For Each Data In Storage Do
			
			Table = Data.Value; // ValueTable
			
			If FoundBatches.UBound() <> -1 Then
				
				FillingValues = New Structure("CalculateChanges_", True);
				
				FilterParameters = New Structure("KeyLot");
				
				Table.Columns.Add("CalculateChanges_", New TypeDescription("Boolean"));
				Table.Indexes.Add("KeyLot");
				
				For Each Lot In FoundBatches Do
					FillPropertyValues(FilterParameters, Lot);
					FillInColumnsInTableAccordingToSelectionParameters(Table, FilterParameters, FillingValues);
				EndDo;
				
				Table.Indexes.Delete(0);
				
				If Data.Key = "OrderStructure" Then
					CalculateChangesAndAddReverseRegisteredRecordsToOrderStructureTable(Table);
				EndIf;
				
				If Data.Key = "OrderStructureLaborCosts" Then
					CalculateChangesAndAddReverseRegisteredRecordsToTableLaborCostsOfOrderStructure(Table);
				EndIf;
				
			EndIf;
			
			Table.Columns.Add("PortionNumber", Common.TypeDescriptionNumber(4, 0));
			Table.Indexes.Add("KeyLot");
			
			TotalRows = Max(TotalRows, Table.Count());
			
		EndDo;
		
	EndIf;
	
	Lots.Columns.Add("PortionNumber", Common.TypeDescriptionNumber(4, 0));
	
	// grouping of batches in portions of a record by portions of a record
	
	RecordingPortions = RecordingPortions();
	
	If AllBatchesAreNew
		And NumberOfRowsInTheRecordset() > TotalRows Then
		
		RecordingPortions.Add().PortionNumber = 0;
		
	Else
	
		TotalBatches = Lots.Count();
		
		RowsCount = 0;
		Container = New Array();
		
		For X = 0 To TotalBatches - 1 Do
			
			Lot = Lots[X];
			
			FillPropertyValues(LotStructure, Lot);
			
			Replace = Not Lot.NewBatch_ And Not Lot.CalculateChanges_;
			
			For Each Data In Storage Do
				Container.Add(Data.Value.FindRows(LotStructure));
			EndDo;
			
			RowsCount = Container[0].Count();
			
			RecordPortion = RecordPortion(RecordingPortions, Replace, True, RowsCount);
			
			For Each Collection In Container Do
				SetPortionNumberInMovementCollection(Collection, RecordPortion.PortionNumber);
			EndDo;
			
			Lot.PortionNumber = RecordPortion.PortionNumber;
			
			Container.Clear();
			
			RecordPortion.RowsCount = RecordPortion.RowsCount + RowsCount;
			RecordPortion.Available = NumberOfRowsInTheRecordset() > RecordPortion.RowsCount;
			
		EndDo;
		
	EndIf;
	
	// calculation of the table of changes for registration of tasks for the distribution of stocks
	
	EmptyProductGroupStructure = New Structure("ProductItemsGroup", EmptyProductGroup()); // we exclude the lines of the type productionproduction, productionproduction
	
	If AllBatchesAreNew
		Or CalculationParameters.CalculateChanges_ Then
		
		InventoryChanges = Storage.OrderStructure.Copy(EmptyProductGroupStructure, "PortionNumber," + "Products,Characteristic,Warehouse,Purpose" + ",ProductionOrder"); // ValueTable
		InventoryChanges.GroupBy("PortionNumber," + "Products,Characteristic,Warehouse,Purpose" + ",ProductionOrder");
		InventoryChanges.Indexes.Add("PortionNumber");
		
	Else
		
		Dimensions = InformationRegisters.OrderStructure.MetadataStructure().DimensionsString;
		InventoryChanges = Storage.OrderStructure.Copy(EmptyProductGroupStructure, "PortionNumber," + Dimensions + ",ToSupply,Scheduled"); // ValueTable
		CollapseTableAndDeleteNullRows(InventoryChanges, "PortionNumber," + Dimensions, "ToSupply,Scheduled");
		InventoryChanges.GroupBy("PortionNumber," + "Products,Characteristic,Warehouse,Purpose" + ",ProductionOrder");
		InventoryChanges.Indexes.Add("PortionNumber");
		
	EndIf;
	
	// preparation for recording calculation errors
	
	If HadErrors Then
		
		ControlOfDuplicates = New Map();
		BatchErrors = InformationRegisters.OrderStructureCalculationProtocol.CreateRecordSet().UnloadColumns("ProductionOrder,ErrorID");
		BatchErrors.Columns.Add("PortionNumber", Common.TypeDescriptionNumber(4, 0));
		BatchErrors.Columns.Add("Protocol");
		BatchesWithErrors = Lots.FindRows(New Structure("HadErrors", True));
		
		For Each Lot In BatchesWithErrors Do
			
			MessageText = "";
			
			If ValueIsFilled(Lot.Protocol) Then // exclude duplicates
				DuplicateControl_ProductGroup = ControlOfDuplicates.Get(Lot.ProductItemsGroup);
				If DuplicateControl_ProductGroup = Undefined Then
					DuplicateControl_ProductGroup = New Map();
					ControlOfDuplicates.Insert(Lot.ProductItemsGroup, DuplicateControl_ProductGroup);
				EndIf;
				For Each Message In Lot.Protocol Do
					Hash = New DataHashing(HashFunction.SHA256);
					Hash.Append(Message);
					If DuplicateControl_ProductGroup[Hash.HashSum] <> True Then
						MessageText = ?(MessageText = "", Message, MessageText + ";" + Message);
						DuplicateControl_ProductGroup.Insert(Hash.HashSum, True);
					EndIf;
				EndDo;
			EndIf;
			
			If MessageText = "" And Lot.NewBatch_ Then // according to the "old" batches, errors need to be cleared (there were errors = True)
				Continue;
			EndIf;
			
			Error = BatchErrors.Add();
			FillPropertyValues(Error, Lot, "ProductionOrder,PortionNumber");
			Error.ErrorID = Lot.KeyLot;
			
			If Not MessageText = "" Then
 				Protocol = InformationRegisters.OrderStructureCalculationProtocol.ProtocolTemplate();
				Protocol.Data = StructureByFields(Lot, "BillOfMaterials, ProductionOrder");
				Protocol.MessageText = MessageText;
				Error.Protocol = New ValueStorage(Protocol, New Deflation(9)); // error logging
			EndIf;
			
		EndDo;
		
		BatchErrors.Indexes.Add("PortionNumber");

		BatchesWithErrors = Undefined;
		ControlOfDuplicates = Undefined;

	EndIf;
	
	// preparing movements for recording (deleting "before change" records necessary to control changes in the previous step)
	
	If Not
		AllBatchesAreNew Then
		
		For Each Data In Storage Do
			FoundRows = Data.Value.FindRows(New Structure("RegisteredRecordsBeforeChange", True));
			DeleteRowsFromTable(Data.Value, FoundRows);
		EndDo;
		
	EndIf;
	
	For Each Data In Storage Do
		Table = Data.Value; // ValueTable
		Table.LoadColumn(Table.UnloadColumn("KeyLot"), "KeySet"); // separate dimension for recording Registered Recorded movements
		Table.Indexes.Add("PortionNumber");
	EndDo;
	
	Lots.Indexes.Add("PortionNumber");
	
	// recording the result of the unzipping
	
	If TheProductionScheduleIsUsed Then
		If TasksForClearingSchedule.Count() > 0 Then
			InformationRegisters.ScheduleOfProductionStages2_2.ClearScheduleAndDownloadLotReference(TasksForClearingSchedule);
			TasksForClearingSchedule.Clear();
		EndIf;
		If TasksForCalculatingSchedule.Count() > 0 Then
			InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddTasks(TasksForCalculatingSchedule);
			TasksForCalculatingSchedule.Clear();
		EndIf;
	EndIf;
	
	TotalServings = RecordingPortions.Count();
	IndexOf = 0;
	
	ErrorCounter = 1;
	
	While TotalServings > IndexOf Do
		
		RecordPortion = RecordingPortions[IndexOf];
		RecordingPortionStructure = New Structure("PortionNumber", RecordPortion.PortionNumber);
		ModifiedRows = InventoryChanges.Copy(RecordingPortionStructure);
		
		BeginTransaction();
		Try
			
			If Not RecordPortion.Replace Then
				
				RecordSet = InformationRegisters.OrderStructure.CreateRecordSet();
				RecordSet.Load(Storage.OrderStructure.Copy(RecordingPortionStructure));
				RecordSet.Write(False);
				
				RecordSet = InformationRegisters.OrderStructureLaborCosts.CreateRecordSet();
				RecordSet.Load(Storage.OrderStructureLaborCosts.Copy(RecordingPortionStructure));
				RecordSet.Write(False);
				
			Else
				
				FoundBatches = Lots.FindRows(RecordingPortionStructure);
				
				For Each Lot In FoundBatches Do
					
					FillPropertyValues(LotStructure, Lot);
					
					RecordSet = InformationRegisters.OrderStructure.CreateRecordSet();
					RecordSet.Filter.KeySet.Set(Lot.KeyLot);
					If Lot.Valid Then
						RecordSet.Load(Storage.OrderStructure.Copy(LotStructure));
					EndIf;
					RecordSet.Write(True);
					
					RecordSet = InformationRegisters.OrderStructureLaborCosts.CreateRecordSet();
					RecordSet.Filter.KeySet.Set(Lot.KeyLot);
					If Lot.Valid Then
						RecordSet.Load(Storage.OrderStructureLaborCosts.Copy(LotStructure));
					EndIf;
					RecordSet.Write(True);
					
				EndDo;
				
			EndIf;
			
			InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasksToNextQueue(ModifiedRows, ActionParameters.Queue);
			
			If HadErrors Then
				ErrorsStructure = New Structure();
				ErrorsStructure.Insert("ErrorType", Enums.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenFillingTheBOMData);
				ErrorsStructure.Insert("Errors", BatchErrors.Copy(RecordingPortionStructure));
				InformationRegisters.OrderStructureCalculationProtocol.RegisterErrors(ErrorsStructure);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = DetailErrorDescription(ErrorInfo());
			
			If ErrorCounter < NumberOfWriteAttempts() Then
				RecordUnsuccessfulAttemptToWriteToLog(ErrorCounter, ErrorText);
				ErrorCounter = ErrorCounter + 1;
				Continue;
			EndIf;
			
			Raise ErrorText;
			
		EndTry;
		
		IndexOf = IndexOf + 1;
		ErrorCounter = 1;
		
	EndDo;
	
EndProcedure

Function Storage()
	
	Storage = New Structure(); // Registered Records
	
	Return Storage;
	
EndFunction

Procedure UploadRegisteredRecordsToVault(Storage, RegisterName, Data, GiveTypes = True, ColumnsByValue = Undefined)

	If GiveTypes Then
	
		Set = InformationRegisters[RegisterName].CreateRecordSet();
		Set.Load(Data);
		Storage.Insert(RegisterName, Set.Unload());
		
	Else
		Storage.Insert(RegisterName, Data);
	EndIf;
	
	Table = Storage[RegisterName]; // ValueTable
	
	If ColumnsByValue <> Undefined Then
		For Each Column In ColumnsByValue Do
			TypesArray = New Array;
			TypesArray.Add(TypeOf(Column.Value));
			Table.Columns.Add(Column.Key, New TypeDescription(TypesArray));
			Table.FillValues(Column.Value, Column.Key);
		EndDo;
	EndIf;
	
EndProcedure

Function CheckLoopingOfOrderStructure(Lot, Products_1, CalculationParameters)
	
	CycleDescription = "";
	
	HasErrors = False;
	
	Product = Products_1[0];
	Level = Product.ParentLevel + 1;

	If Level > CalculationParameters.MaxAccountingDepth Then
		HasErrors = True;
		Lot.HadErrors = True;
		Template = NStr("vi = 'Vượt quá giá trị chia tách tối đa cấu trúc đơn hàng (%1)';
						|ru = 'Превышена максимальная глубина разузлования структуры заказа (%1)';
						|en = 'The maximum explosion depth of the order structure is exceeded (%1)'; fa = 'The maximum explosion depth of the order structure is exceeded (%1)';
						|it = 'Profondità massima di esplosione della struttura dell''ordine superata (%1)';
						|pl = 'Przekroczono maksymalną głębokość rozdzielenia struktury zamówienia (%1)';
						|tr = 'Sipariş yapısının (%1) maksimum ayrıştırma derinliği aşıldı'");
		MessageText = StrTemplate(Template, CalculationParameters.MaxAccountingDepth);
		AddMessageToErrorList(Lot.Protocol, MessageText);
		WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Error,,Product.ProductionOrder,
			MessageText);
	EndIf;
	
	If Not HasErrors And Level > CalculationParameters.SearchCyclesAfter Then
		
		HasErrors = False;
		
		SpecificationRelationships = New Map();
		
		Query = New Query();
		
		Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
		Query.Text =
		"SELECT
		|
		|	NSICache.BillOfMaterials          AS BillOfMaterials,
		|	RegisterRecords.KeyProducts    AS KeyProducts,
		|	Hierarchy.BillOfMaterials        AS ParentSpecification,
		|	Hierarchy.KeyProducts    AS ProductKeyIsParent,
		|	Hierarchy.Products        AS ParentProduct,
		|	Hierarchy.Characteristic      AS CharacteristicOfParent,
		|	Hierarchy.Warehouse               AS WarehouseParent,
		|	Hierarchy.Purpose          AS ParentAssignment,
		|	Hierarchy.ProductionOrder AS ProductionOrderParent
		|FROM
		|	InformationRegister.OrderStructure AS RegisterRecords
		|
		|		INNER JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
		|		ON NSICache.Products        = RegisterRecords.Products
		|		 AND NSICache.Characteristic      = RegisterRecords.Characteristic
		|		 AND NSICache.Warehouse               = RegisterRecords.Warehouse
		|		 AND NSICache.Purpose          = RegisterRecords.Purpose
		|		 AND NSICache.ProductionOrder = RegisterRecords.ProductionOrder
		|		 AND RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|		 AND RegisterRecords.Separator = &EmptyLinkKey
		|
		|		INNER JOIN InformationRegister.OrderStructure AS Hierarchy
		|		ON RegisterRecords.KeyLot = Hierarchy.KeyLot
		|		 AND Hierarchy.LineKind IN (VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
		|								 VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
		|		 AND Hierarchy.Separator = &EmptyLinkKey
		|
		|WHERE
		|	RegisterRecords.Products          = &Products
		|	AND RegisterRecords.Characteristic      = &Characteristic
		|	AND RegisterRecords.Warehouse               = &Warehouse
		|	AND RegisterRecords.Purpose          = &Purpose
		|	AND RegisterRecords.ProductionOrder = &ProductionOrder
		|	AND RegisterRecords.KeyProducts    = &KeyProducts
		|
		|UNION ALL
		|
		|SELECT
		|
		|	NSICache1.BillOfMaterials         AS BillOfMaterials,
		|	RegisterRecords.KeyProducts    AS KeyProducts,
		|	NSICache2.BillOfMaterials         AS ParentSpecification,
		|	Hierarchy.KeyProducts    AS ProductKeyIsParent,
		|	Hierarchy.Products        AS ParentProduct,
		|	Hierarchy.Characteristic      AS CharacteristicOfParent,
		|	Hierarchy.Warehouse               AS WarehouseParent,
		|	Hierarchy.Purpose          AS ParentAssignment,
		|	Hierarchy.ProductionOrder AS ProductionOrderParent
		|
		|FROM
		|	InformationRegister.OrderStructure AS RegisterRecords
		|	
		|		INNER JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache1
		|		ON NSICache1.Products        = RegisterRecords.Products
		|		 AND NSICache1.Characteristic      = RegisterRecords.Characteristic
		|		 AND NSICache1.Warehouse               = RegisterRecords.Warehouse
		|		 AND NSICache1.Purpose          = RegisterRecords.Purpose
		|		 AND NSICache1.ProductionOrder = RegisterRecords.ProductionOrder
		|		 AND RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|		 AND RegisterRecords.Separator = &EmptyLinkKey
		|	
		|		INNER JOIN InformationRegister.OrderStructure AS Move
		|		ON RegisterRecords.KeyLot = Move.KeyLot
		|		 AND Move.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
		|		 AND Move.Separator = &EmptyLinkKey
		|	
		|		INNER JOIN InformationRegister.OrderStructure AS Hierarchy
		|		ON Move.Products        = Hierarchy.Products
		|		 AND Move.Characteristic      = Hierarchy.Characteristic
		|		 AND Move.Purpose          = Hierarchy.Purpose
		|		 AND Move.ProductionOrder = Hierarchy.ProductionOrder
		|		 AND Move.CommunicationKeyBillOfMaterialsRow = Hierarchy.KeyProducts
		|		 AND Hierarchy.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|		 AND Hierarchy.Separator = &EmptyLinkKey
		|		
		|		INNER JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache2
		|		ON NSICache2.Products        = Hierarchy.Products
		|		 AND NSICache2.Characteristic      = Hierarchy.Characteristic
		|		 AND NSICache2.Warehouse               = Hierarchy.Warehouse
		|		 AND NSICache2.Purpose          = Hierarchy.Purpose
		|		 AND NSICache2.ProductionOrder = Hierarchy.ProductionOrder
		|		 AND Hierarchy.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|		 AND Hierarchy.Separator = &EmptyLinkKey
		|WHERE
		|	RegisterRecords.Products          = &Products
		|	AND RegisterRecords.Characteristic      = &Characteristic
		|	AND RegisterRecords.Warehouse               = &Warehouse
		|	AND RegisterRecords.Purpose          = &Purpose
		|	AND RegisterRecords.ProductionOrder = &ProductionOrder
		|	AND RegisterRecords.KeyProducts    = &KeyProducts
		|";
		Query.SetParameter("Products",        Product.Products);
		Query.SetParameter("Characteristic",      Product.Characteristic);
		Query.SetParameter("Warehouse",               Product.Warehouse);
		Query.SetParameter("Purpose",          Product.Purpose);
		Query.SetParameter("ProductionOrder", Product.ProductionOrder);
		Query.SetParameter("KeyProducts",    Product.KeyProducts);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			FindCyclesInLinks(
				SpecificationRelationships, Selection.BillOfMaterials, Selection.ParentSpecification, CycleDescription, HasErrors);
			
			If HasErrors Then
				
				Lot.HadErrors = True;
				Template = NStr("vi = 'Đã phát hiện vòng lặp bảng kê chi tiết: %1 \%2 %3';
								|ru = 'Обнаружено зацикливание спецификаций: %1 \%2 %3';
								|en = 'Bill of materials looping is found: %1 \%2 %3'; fa = 'Bill of materials looping is found: %1 \%2 %3';
								|it = 'È stato rilevato un ciclo di specifiche: %1 \%2 %3';
								|pl = 'Wykryto zapętlenie specyfikacji: %1 \%2 %3';
								|tr = 'Ürün reçetelerinde döngü tespit edildi: %1 \%2 %3'");
				MessageText = StrTemplate(Template, CycleDescription, TrimAll(Selection.BillOfMaterials.Code), TrimAll(Selection.BillOfMaterials.Description));
				AddMessageToErrorList(Lot.Protocol, MessageText);
				WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Error,,Product.ProductionOrder,
					MessageText);
				Break;
				
			Else
				
				Link = SpecificationRelationships.Get(Selection.BillOfMaterials);
				If Link = Undefined Then
					SpecificationRelationships.Insert(
						Selection.BillOfMaterials,
						CommonClientServer.ValueInArray(Selection.ParentSpecification));
				Else
					If Link.Find(Selection.ParentSpecification) = Undefined Then
						Link.Add(Selection.ParentSpecification);
					EndIf;
				EndIf;
				
			EndIf;
				
			Query.SetParameter("Products",        Selection.ParentProduct);
			Query.SetParameter("Characteristic",      Selection.CharacteristicOfParent);
			Query.SetParameter("Warehouse",               Selection.WarehouseParent);
			Query.SetParameter("Purpose",          Selection.ParentAssignment);
			Query.SetParameter("ProductionOrder", Selection.ProductionOrderParent);
			Query.SetParameter("KeyProducts",    Selection.ProductKeyIsParent);
			
			Selection = Query.Execute().Select();
			
		EndDo;
		
	EndIf;
	
	Return HasErrors;

EndFunction

Procedure FindCyclesInLinks(SpecificationRelationships, BillOfMaterials, ParentSpecification, CycleDescription, Cancel)
	
	If BillOfMaterials = ParentSpecification Then
		Cancel = True;
	Else
		
		Link = SpecificationRelationships.Get(ParentSpecification);
		
		If Link = Undefined Then
			Return;
		EndIf;
		
		For Each Predecessor In Link Do
			
			If Predecessor = BillOfMaterials Then
				
				Cancel = True;
				CycleDescription = "" + StrTemplate(NStr("vi = '""%1 %2""';
														|ru = '""%1 %2""';
														|en = '""%1 %2""'; fa = '""%1 %2""';
														|it = '""%1 %2""';
														|pl = '""%1 %2""';
														|tr = '""%1 %2""'"), TrimAll(BillOfMaterials.Code), TrimAll(BillOfMaterials.Description));
			Else
				
				FindCyclesInLinks(
					SpecificationRelationships, BillOfMaterials, Predecessor, CycleDescription, Cancel);
				
			EndIf;
			
			If Cancel Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Cancel Then
		CycleDescription = CycleDescription + "\" + StrTemplate(NStr("vi = '""%1 %2""';
																	|ru = '""%1 %2""';
																	|en = '""%1 %2""'; fa = '""%1 %2""';
																	|it = '""%1 %2""';
																	|pl = '""%1 %2""';
																	|tr = '""%1 %2""'"), TrimAll(ParentSpecification.Code), TrimAll(ParentSpecification.Description));
	EndIf;
	
EndProcedure

Procedure FillInRegisteredRecordsBasedOnResultOfSeparation(Storage, Lot, Products_1, DataCache, SpecificationsData, KeysLinks)
	
	ProductionLotIDInProductGroup = Lot.ProductionLotIDInProductGroup;
	
	If Lot.BatchSize > 0 Or Lot.Rows.Count() > 0 Then // See CheckLoopingOfOrderStructure()
		
		Product = Products_1[0];
		Level = Product.ParentLevel + 1;

		Cache = Undefined;
		
		EmptyAssignment = Catalogs.Assignments.EmptyRef();
		
	#Region Cache
	
		If Product.Cached And Not Product.CompleteCalculation Then
			
			FilterParameters = New Structure("BillOfMaterials, DataVersionID", Product.BillOfMaterials, Product.DataVersionID);
			
			MovementCache = DataCache.OrderStructure.FindRows(FilterParameters);
			If MovementCache.UBound() <> -1 Then
				
				Cache = New Structure("Products_1,AvailableRelease,MaterialsAndServices", New Array(), New Array(), New Array());
				
				For Each String In MovementCache Do
					Cache[String.TSName].Add(String);
				EndDo;
				
				Cache.Insert("LaborCosts", DataCache.LaborCosts.FindRows(FilterParameters));
			
				If Cache.Products_1.UBound() = -1 Then
					Cache = Undefined;
				EndIf;
			EndIf;
			
		EndIf;
		
	#EndRegion
	
	If Cache <> Undefined Then
	
	#Region Products_1
			
			MovementProducts = Storage.OrderStructure; // ValueTable
		
			ColumnsByValue = New Structure();
			ColumnsByValue.Insert("Level",               Level);
			ColumnsByValue.Insert("KeyLot",            Lot.KeyLot);
			ColumnsByValue.Insert("ProductItemsGroup",         Product.ProductItemsGroup);
			ColumnsByValue.Insert("BillOfMaterials",          Product.BillOfMaterials);
			ColumnsByValue.Insert("ProductionOrder",   Product.ProductionOrder);
			ColumnsByValue.Insert("Stage",                  Cache.Products_1[0].Stage);
			ColumnsByValue.Insert("Department",         Cache.Products_1[0].Department);
			ColumnsByValue.Insert("ProductionLotIDInProductGroup", ProductionLotIDInProductGroup);
			ColumnsByValue.Insert("DurationBeforeProductionIssue", Product.DurationUntilReleaseParent);
			ColumnsByValue.Insert("DataVersionID", Product.DataVersionID);
			
			For Each String In Products_1 Do
				
				NewRow = MovementProducts.Add();
				
				FillPropertyValues(NewRow, ColumnsByValue);
				FillPropertyValues(NewRow, String, "Products,Characteristic,Warehouse,Purpose,StructureAssignment");
				
				NewRow.KeyProducts = String.KeyProducts;

				If Not
					Product.ProcessType = Enums.ProductionProcessTypes.Disassembly Then
					
					If String.ThisIsASemiFinishedProduct Then
						NewRow.LineKind = Enums.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct;
					Else
						NewRow.LineKind = Enums.KindsOfProductionOrderStructureLines.ManufactureOfProducts;
					EndIf;
					
					If Not ValueIsFilled(Lot.LineAdjustment) Then
						NewRow.Scheduled = String.Required2;
					Else
						NewRow.Scheduled = String.Required2 - AdjustValue(NumberType(), Lot.LineAdjustment[String.KeyProducts]);
					EndIf;
					
				Else
					
					NewRow.ReverseKittingScheduled = String.Required2;
					NewRow.LineKind = Enums.KindsOfProductionOrderStructureLines.Disassembly;
					
				EndIf;
				
				NewRow.QuantityForLaunchLotUnit = String.QuantityForLaunchLotUnit;
				
			EndDo;
			
			#EndRegion
	
	#Region FreeRelease_SideOutput
	
			MovementProducts = Storage.OrderStructure; // ValueTable
	
			ColumnsByValue = New Structure();
			ColumnsByValue.Insert("Level",               Level);
			ColumnsByValue.Insert("KeyLot",            Lot.KeyLot);
			ColumnsByValue.Insert("BillOfMaterials",          Product.BillOfMaterials);
			ColumnsByValue.Insert("ProductionOrder",   Product.ProductionOrder);
			ColumnsByValue.Insert("ReceiptOrder",    Product.ProductionOrder);
			ColumnsByValue.Insert("StructureAssignment",   EmptyAssignment);
			ColumnsByValue.Insert("Purpose",                ?(Lot.TollManufacturing, Product.FreeReleaseAssignment, EmptyAssignment));
			ColumnsByValue.Insert("ProductionLotIDInProductGroup", ProductionLotIDInProductGroup);
			ColumnsByValue.Insert("DataVersionID", Product.DataVersionID);
			
			For Each String In Cache.AvailableRelease Do
				
				NewRow = MovementProducts.Add();
				
				FillPropertyValues(NewRow, ColumnsByValue);
				FillPropertyValues(NewRow, String, "Products,Characteristic,Warehouse,Stage,Department,ProductCostElement");
				
				NewRow.LineKind = Enums.KindsOfProductionOrderStructureLines.AvailableRelease;
				
				If Product.ProcessType = Enums.ProductionProcessTypes.PerformRM
					And String.WithAssignment Then
					NewRow.Purpose = Product.StructureAssignment;
				ElsIf Product.ProcessType = Enums.ProductionProcessTypes.Disassembly
					And Not Product.Purpose.IsEmpty()
					And Not ValueIsFilled(String.ProductCostElement) Then // Main product
					NewRow.Purpose = Product.Purpose;
				EndIf;
				
				NewRow.Scheduled = Lot.BatchSize * String.QuantityForLaunchLotUnit / Product.QuantityOfMainProductPerUnitOfLaunchBatch;
				
				NewRow.DurationBeforeProductionIssue = Product.DurationUntilReleaseParent + (String.DurationBeforeProductionIssue - Cache.Products_1[0].DurationBeforeProductionIssue);
				NewRow.CommunicationKeyBillOfMaterialsRow = String.CommunicationKeyBillOfMaterialsRow;
				NewRow.QuantityForLaunchLotUnit = String.QuantityForLaunchLotUnit;
				
				SetStringLinkKey(NewRow, "OrderStructure", "KeyProducts", KeysLinks); // "00000000-0000-0000-0000-000000000000"
				
			EndDo;
	
	#EndRegion
	
	#Region UsedMaterials
	
			MovementProducts = Storage.OrderStructure; // ValueTable
			
			ColumnsByValue = New Structure();
			ColumnsByValue.Insert("Level",               Level);
			ColumnsByValue.Insert("KeyLot",            Lot.KeyLot);
			ColumnsByValue.Insert("BillOfMaterials",          Product.BillOfMaterials);
			ColumnsByValue.Insert("ProductionOrder",   Product.ProductionOrder);
			ColumnsByValue.Insert("Purpose",            EmptyAssignment); // type conversion across all dimensions
			ColumnsByValue.Insert("StructureAssignment",   Product.StructureAssignment);
			ColumnsByValue.Insert("ProductionLotIDInProductGroup", ProductionLotIDInProductGroup);
			ColumnsByValue.Insert("DataVersionID", Product.DataVersionID);
			
			For Each String In Cache.MaterialsAndServices Do
				
				NewRow = MovementProducts.Add();
				
				FillPropertyValues(NewRow, ColumnsByValue);
				FillPropertyValues(NewRow, String, "Products,Characteristic,Stage,Department,ProductCostElement,PermissionToReplace");
				
				NewRow.LineKind = Enums.KindsOfProductionOrderStructureLines.Consumption;
				
				If Product.ProcessType = Enums.ProductionProcessTypes.Disassembly
					And (Product.Products = NewRow.Products And Product.Characteristic = NewRow.Characteristic) Then
					NewRow.Warehouse = Product.Warehouse;
					NewRow.Purpose = Product.Purpose;
				Else
					
					NewRow.Warehouse = String.Warehouse;
					If String.WithAssignment Then
						NewRow.Purpose = Product.StructureAssignment;
					EndIf;
					
				EndIf;
				
				If String.SupplyOption = Enums.SupplyOptions.NotRequired Then
					NewRow.NotProvide = Lot.BatchSize * String.QuantityForLaunchLotUnit / Product.QuantityOfMainProductPerUnitOfLaunchBatch;
				Else
					NewRow.ToSupply = Lot.BatchSize * String.QuantityForLaunchLotUnit / Product.QuantityOfMainProductPerUnitOfLaunchBatch;
				EndIf;
				
				NewRow.SemiFinishedProductBOM = String.SemiFinishedProductBOM;
				NewRow.DurationBeforeProductionIssue = Product.DurationUntilReleaseParent + (String.DurationBeforeProductionIssue - Cache.Products_1[0].DurationBeforeProductionIssue);
				NewRow.CommunicationKeyBillOfMaterialsRow = String.CommunicationKeyBillOfMaterialsRow;
				NewRow.QuantityForLaunchLotUnit = String.QuantityForLaunchLotUnit;
				
				SetStringLinkKey(NewRow, "OrderStructure", "KeyProducts", KeysLinks);
				
			EndDo;
			
	#EndRegion
	
	#Region LaborCosts
	
			RegisteredRecordsLaborCosts = Storage.OrderStructureLaborCosts; // ValueTable
	
			ColumnsByValue = New Structure();
			ColumnsByValue.Insert("KeyLot",          Lot.KeyLot);
			ColumnsByValue.Insert("BillOfMaterials",        Product.BillOfMaterials);
			ColumnsByValue.Insert("ProductionOrder", Product.ProductionOrder);
			ColumnsByValue.Insert("DataVersionID", Product.DataVersionID);
			
			For Each String In Cache.LaborCosts Do
			
				NewRow = RegisteredRecordsLaborCosts.Add();
				
				FillPropertyValues(NewRow, ColumnsByValue);
				FillPropertyValues(NewRow, String, "WorkKind,Stage,Department,ProductCostElement");
				
				NewRow.Count = Lot.BatchSize * String.QuantityForLaunchLotUnit / Product.QuantityOfMainProductPerUnitOfLaunchBatch;
				
				NewRow.CommunicationKeyBillOfMaterialsRow = String.CommunicationKeyBillOfMaterialsRow;
				NewRow.QuantityForLaunchLotUnit = String.QuantityForLaunchLotUnit;
				
				SetStringLinkKey(NewRow, "OrderStructureLaborCosts", "KeyWorkType", KeysLinks);
				
			EndDo;
			
	#EndRegion
	
		Else
			
			SpecificationData = SpecificationData(Product, Lot.BatchSize, SpecificationsData);
			
	#Region Products_1
		
			MovementProducts = Storage.OrderStructure; // ValueTable
			
			ColumnsByValue = New Structure();
			ColumnsByValue.Insert("Level",               Level);
			ColumnsByValue.Insert("KeyLot",            Lot.KeyLot);
			ColumnsByValue.Insert("ProductItemsGroup",         Product.ProductItemsGroup);
			ColumnsByValue.Insert("BillOfMaterials",          Product.BillOfMaterials);
			ColumnsByValue.Insert("ProductionOrder",   Product.ProductionOrder);
			ColumnsByValue.Insert("Stage",                  SpecificationData.MainProduct.Stage);
			ColumnsByValue.Insert("Department",         SpecificationData.MainProduct.StageSubdivision);
			ColumnsByValue.Insert("ProductionLotIDInProductGroup", ProductionLotIDInProductGroup);
			ColumnsByValue.Insert("DurationBeforeProductionIssue", Product.DurationUntilReleaseParent);
			ColumnsByValue.Insert("DataVersionID", ?(Lot.TollManufacturing, "", SpecificationData.DataVersionID));
			
			For Each String In Products_1 Do
				
				NewRow = MovementProducts.Add();
				
				FillPropertyValues(NewRow, ColumnsByValue);
				FillPropertyValues(NewRow, String, "Products,Characteristic,Warehouse,Purpose,StructureAssignment");
				
				NewRow.KeyProducts = String.KeyProducts;
				
				If Not
					Product.ProcessType = Enums.ProductionProcessTypes.Disassembly Then
					
					If String.ThisIsASemiFinishedProduct Then
						NewRow.LineKind = Enums.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct;
					Else
						NewRow.LineKind = Enums.KindsOfProductionOrderStructureLines.ManufactureOfProducts;
					EndIf;
					
					If Not ValueIsFilled(Lot.LineAdjustment) Then
						NewRow.Scheduled = String.Required2;
					Else
						NewRow.Scheduled = String.Required2 - AdjustValue(NumberType(), Lot.LineAdjustment[String.KeyProducts]);
					EndIf;
					
				Else
					
					NewRow.ReverseKittingScheduled = String.Required2;
					NewRow.LineKind = Enums.KindsOfProductionOrderStructureLines.Disassembly;
					
				EndIf;
				
				NewRow.QuantityForLaunchLotUnit = String.QuantityForLaunchLotUnit;
				
			EndDo;
			
	#EndRegion
	
	#Region FreeRelease_SideOutput
	
			MovementProducts = Storage.OrderStructure; // ValueTable
		
			ColumnsByValue = New Structure();
			ColumnsByValue.Insert("Level",               Level);
			ColumnsByValue.Insert("KeyLot",            Lot.KeyLot);
			ColumnsByValue.Insert("BillOfMaterials",          Product.BillOfMaterials);
			ColumnsByValue.Insert("ProductionOrder",   Product.ProductionOrder);
			ColumnsByValue.Insert("ReceiptOrder",    Product.ProductionOrder);
			ColumnsByValue.Insert("StructureAssignment",   EmptyAssignment);
			ColumnsByValue.Insert("Purpose",                ?(Lot.TollManufacturing, Product.FreeReleaseAssignment, EmptyAssignment));
			ColumnsByValue.Insert("ProductionLotIDInProductGroup", ProductionLotIDInProductGroup);
			ColumnsByValue.Insert("DataVersionID", ?(Lot.TollManufacturing, "", SpecificationData.DataVersionID));
			
			If Product.ProcessType = Enums.ProductionProcessTypes.Disassembly Then
				// In the reverse kitting of all output finished products - free release (without additional calculation)
				AvailableRelease = AccessoriesForReverseKitting(Lot, SpecificationData);
			Else
				// In production, it is necessary to calculate the free release taking into account the ordered quantity of finished products
				AvailableRelease = AvailableRelease(Lot, SpecificationData);
			EndIf;
			
			For Each String In AvailableRelease Do
				
				If String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess
					Or String.MethodOfItemVariantAutoselection = Enums.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess
					Or (Product.ProcessType = Enums.ProductionProcessTypes.Assembly
							And String.LineKind = Enums.TypesOfSpecificationLines.IntermediateSemiFinishedProduct) Then
					Continue;
				EndIf;
				
				If (String.MethodOfProductsAutoselection <> Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData
						And Not ValueIsFilled(String.Products)
					Or String.MethodOfItemVariantAutoselection <> Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData
						And Not ValueIsFilled(String.Characteristic)) Then
					Lot.HadErrors = True;
					TSName = ?(ValueIsFilled(String.ProductCostElement), NStr("vi = '""Sản phẩm phụ""';
																				|ru = '""Побочные изделия""';
																				|en = '""By-products""'; fa = '""By-products""';
																				|it = '""By-products""';
																				|pl = '""By-products""';
																				|tr = '""Yan nihai ürünler""'"), NStr("vi = '""Sản phẩm đầu ra""';
																												|ru = '""Выходные изделия""';
																												|en = '""Finished products""'; fa = '""Finished products""';
																												|it = '""Finished products""';
																												|pl = '""Finished products""';
																												|tr = '""Üretilen nihai ürünler""'"));
					Template = NStr("vi = 'Khi chia tách sản phẩm theo bảng kê chi tiết %1 ""%2"" trong dòng số%3 của danh sách %4 không thể tự động chọn mặt hàng do nguyên nhân: %5.';
									|ru = 'При разузловании изделия по спецификации %1 ""%2"" в строке №%3 списка %4 не удалось выполнить автовыбор номенклатуры по причине: %5.';
									|en = 'Cannot autoselect an item while exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""%4"" list due to: %5.'; fa = 'Cannot autoselect an item while exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""%4"" list due to: %5.';
									|it = 'Cannot autoselect an item while exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""%4"" list due to: %5.';
									|pl = 'Cannot autoselect an item while exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""%4"" list due to: %5.';
									|tr = '%4  numaralı listenin %3 numaralı satırındaki %1 ""%2"" numaralı spesifikasyona göre bir ürünün sökülmesi sırasında aşağıdaki nedenden dolayı ürünün otomatik seçimi yapılamamıştır: %5.'");
					MessageText = StrTemplate(Template, SpecificationData.Code, SpecificationData.BillOfMaterialsPresentation, String.LineNumber, TSName, String.AutoselectionDetails);
					AddMessageToErrorList(Lot.Protocol, MessageText);
					WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Error,,Product.ProductionOrder,
						MessageText);
					Continue;
				EndIf;
				
				If String.Warehouse.IsEmpty()
					And String.ItemsType <> Enums.ItemsTypes.Work_5 Then
					Lot.HadErrors = True;
					TSName = ?(ValueIsFilled(String.ProductCostElement), NStr("vi = '""Sản phẩm phụ""';
																				|ru = '""Побочные изделия""';
																				|en = '""By-products""'; fa = '""By-products""';
																				|it = '""By-products""';
																				|pl = '""By-products""';
																				|tr = '""Yan nihai ürünler""'"), NStr("vi = '""Sản phẩm đầu ra""';
																												|ru = '""Выходные изделия""';
																												|en = '""Finished products""'; fa = '""Finished products""';
																												|it = '""Finished products""';
																												|pl = '""Finished products""';
																												|tr = '""Üretilen nihai ürünler""'"));
					Template = NStr("vi = 'Khi chia tách sản phẩm theo bảng kê chi tiết %1 ""%2"" trong dòng số%3 của danh sách %4 không thể chọn kho.';
									|ru = 'При разузловании изделия по спецификации %1 ""%2"" в строке №%3 списка %4 не удалось подобрать склад.';
									|en = 'Cannot pick a warehouse while exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""%4"" list.'; fa = 'Cannot pick a warehouse while exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""%4"" list.';
									|it = 'Cannot pick a warehouse while exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""%4"" list.';
									|pl = 'Cannot pick a warehouse while exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""%4"" list.';
									|tr = '%4 numaralı listenin %3 numaralı satırında %1 ""%2"" numaralı şartnameye göre ürünün demontajı sırasında Ambar seçimi yapılamamıştır.'");
					MessageText = StrTemplate(Template, SpecificationData.Code, SpecificationData.BillOfMaterialsPresentation, String.LineNumber, TSName);
					AddMessageToErrorList(Lot.Protocol, MessageText);
					WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Error,,Product.ProductionOrder,
						MessageText);
					Continue;
				EndIf;
				
				NewRow = MovementProducts.Add();
				
				FillPropertyValues(NewRow, ColumnsByValue);
				FillPropertyValues(NewRow, String, "Products,Characteristic,Stage,ProductCostElement");
				
				NewRow.LineKind = Enums.KindsOfProductionOrderStructureLines.AvailableRelease;
				
				If String.ItemsType <> Enums.ItemsTypes.Work_5 Then
					NewRow.Warehouse = String.Warehouse;
				Else
					NewRow.Warehouse = String.StageSubdivision;
				EndIf;
				
				If Product.ProcessType = Enums.ProductionProcessTypes.PerformRM
					And ValueIsFilled(String.ProductCostElement)
					And String.ItIsSubjectToRAndM Then
					NewRow.Purpose = Product.StructureAssignment;
				ElsIf Product.ProcessType = Enums.ProductionProcessTypes.Disassembly
					And Not Product.Purpose.IsEmpty()
					And Not ValueIsFilled(String.ProductCostElement) Then // Main product
					NewRow.Purpose = Product.Purpose;
				EndIf;
				
				NewRow.Scheduled = String.Count;
				
				NewRow.Department = String.StageSubdivision;
				NewRow.DurationBeforeProductionIssue = String.DurationBeforeProductionIssue + Product.DurationUntilReleaseParent;
				NewRow.CommunicationKeyBillOfMaterialsRow = String.ConnectionKey; // CommunicationKeyBillOfMaterialsRow
				
				If String.QuantityCalculationAlgorithm <> "" And SpecificationData.MainProduct.NumberOfPackages > 0 Then
					NewRow.QuantityForLaunchLotUnit = String.Count
																		* SpecificationData.MainProduct.NumberOfPackagesPerUnitOfProductionBatch / SpecificationData.MainProduct.NumberOfPackages;
				Else
					NewRow.QuantityForLaunchLotUnit = String.NumberOfPackagesPerUnitOfProductionBatch * String.PackageData.Numerator / String.PackageData.Denominator;
				EndIf;
				
				SetStringLinkKey(NewRow, "OrderStructure", "KeyProducts", KeysLinks); // "00000000-0000-0000-0000-000000000000"
				
			EndDo;
			
	#EndRegion
	
	#Region UsedMaterials

			MovementProducts = Storage.OrderStructure; // ValueTable
			
			ColumnsByValue = New Structure();
			ColumnsByValue.Insert("Level",               Level);
			ColumnsByValue.Insert("KeyLot",            Lot.KeyLot);
			ColumnsByValue.Insert("BillOfMaterials",          Product.BillOfMaterials);
			ColumnsByValue.Insert("ProductionOrder",   Product.ProductionOrder);
			ColumnsByValue.Insert("Purpose",            EmptyAssignment); // type conversion across all dimensions
			ColumnsByValue.Insert("StructureAssignment",   Product.StructureAssignment);
			ColumnsByValue.Insert("ProductionLotIDInProductGroup", ProductionLotIDInProductGroup);
			ColumnsByValue.Insert("DataVersionID", ?(Lot.TollManufacturing, "", SpecificationData.DataVersionID));
		
			For Each String In SpecificationData.MaterialsAndServices Do
				
				If String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess
					Or String.MethodOfItemVariantAutoselection = Enums.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess
					// Internal inventory transfer from kit is completely excluded, in other cases we leave it but do not provide it (removable repair R&M units)
					Or (Product.ProcessType = Enums.ProductionProcessTypes.Assembly
							And String.LineKind = Enums.TypesOfSpecificationLines.IntermediateSemiFinishedProduct) Then
					Continue;
				EndIf;
				
				If String.ItemsType = Enums.ItemsTypes.Set
					And Not ValueIsFilled(String.Products)
					And String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess
					And Catalogs.BillsOfMaterials.ThisIsLineTSMaterialsAndWorks(String.LineKind) Then
					Lot.HadErrors = True;
					Template = NStr("vi = 'Khi chia tách sản phẩm theo bảng kê chi tiết %1 ""%2"" trong dòng số %3 của danh sách ""Nguyên vật liệu và công việc"": %4';
									|ru = 'При разузловании изделия по спецификации %1 ""%2"" в строке №%3 списка ""Материалы и работы"": %4';
									|en = 'While exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""Materials and works"" list: %4'; fa = 'While exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""Materials and works"" list: %4';
									|it = 'Durante l''esplosione della produzione per specifiche %1 ""%2"" nella riga №%3 dell''elenco ""Materiali e lavori"":%4';
									|pl = 'Podczas rozdzielenia wyrobu według specyfikacji %1 ""%2"" w wierszu nr%3 listy ""Materiały i prace"": %4';
									|tr = '""Malzemeler ve İşler"" listesinin %3 numaralı satırındaki ""%2"" %1 ürün reçetesine göre nihai ürün ayrıştırılırken: %4'");
					MessageText = StrTemplate(Template, SpecificationData.Code, SpecificationData.BillOfMaterialsPresentation, String.LineNumber, String.AutoselectionDetails);
					AddMessageToErrorList(Lot.Protocol, MessageText);
					WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Error,,Product.ProductionOrder,
						MessageText);
					Continue;
				EndIf;
				
				If (String.MethodOfProductsAutoselection <> Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData
						And Not ValueIsFilled(String.Products)
					Or String.MethodOfItemVariantAutoselection <> Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData
						And String.ItemVariantsAreUsed
						And Not ValueIsFilled(String.Characteristic))
					And Catalogs.BillsOfMaterials.ThisIsLineTSMaterialsAndWorks(String.LineKind) Then
					Lot.HadErrors = True;
					Template = NStr("vi = 'Khi chia tách sản phẩm theo bảng kê chi tiết %1 ""%2"" trong dòng số %3 của danh sách ""Nguyên vật liệu và công việc"" không thể chọn tự động mặt hàng do nguyên nhân: %4.';
									|ru = 'При разузловании изделия по спецификации %1 ""%2"" в строке №%3 списка ""Материалы и работы"" не удалось выполнить автовыбор номенклатуры по причине: %4.';
									|en = 'Cannot autoselect an item while exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""Materials and works"" list due to: %4.'; fa = 'Cannot autoselect an item while exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""Materials and works"" list due to: %4.';
									|it = 'Durante l''esplosione della produzione per specifiche %1 ""%2"" nella riga №%3 dell''elenco ""Materiali e lavori"" non è stato possibile eseguire la selezione automatica della nomenclatura a causa di: %4.';
									|pl = 'Podczas rozdzielenia wyrobu według specyfikacji %1 ""%2"" w wierszu nr %3 listy ""Materiały i prace"" nie udało się wykonać wyboru automatycznego produktu z powodu%4.';
									|tr = '""Malzemeler ve İşler"" listesinin %3 numaralı satırındaki ""%2"" %1 ürün reçetesine göre nihai ürün ayrıştırılırken otomatik öğe seçiminin gerçekleştirilememe nedeni: %4.'");
					MessageText = StrTemplate(Template, SpecificationData.Code, SpecificationData.BillOfMaterialsPresentation, String.LineNumber, String.AutoselectionDetails);
					AddMessageToErrorList(Lot.Protocol, MessageText);
					WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Error,,Product.ProductionOrder,
						MessageText);
					Continue;
				EndIf;
				
				If String.Warehouse.IsEmpty()
					And Not String.ItemsType = Enums.ItemsTypes.Work_5
					And Catalogs.BillsOfMaterials.ThisIsLineTSMaterialsAndWorks(String.LineKind) Then
					Lot.HadErrors = True;
					Template = NStr("vi = 'Khi chia tách sản phẩm theo bảng kê chi tiết %1 ""%2"" trong dòng số %3 của danh sách ""Nguyên vật liệu và công việc"" không thể chọn kho bãi.';
									|ru = 'При разузловании изделия по спецификации %1 ""%2"" в строке №%3 списка ""Материалы и работы"" не удалось подобрать склад.';
									|en = 'Cannot pick the warehouse while exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""Materials and works"" list.'; fa = 'Cannot pick the warehouse while exploding the product by the %1 ""%2"" bill of materials in line No.%3 of the ""Materials and works"" list.';
									|it = 'Durante l''esplosione della produzione per specifiche %1 ""%2"" nella riga №%3 dell''elenco ""Materiali e lavori"" non è stato possibile selezionare il magazzino.';
									|pl = 'Podczas rozdzielenia wyrobu według specyfikacji %1 ""%2"" w wierszu nr%3 listy ""Materiały i prace"" nie udało się wybrać magazynu.';
									|tr = '""Malzemeler ve İşler"" listesinin %3 numaralı satırındaki ""%2"" %1 ürün reçetesine göre nihai ürün ayrıştırılırken ambar seçilemedi.'");
					MessageText = StrTemplate(Template, SpecificationData.Code, SpecificationData.BillOfMaterialsPresentation, String.LineNumber);
					AddMessageToErrorList(Lot.Protocol, MessageText);
					WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Error,,Product.ProductionOrder,
						MessageText);
					Continue;
				EndIf;
				
				NewRow = MovementProducts.Add();
				
				FillPropertyValues(NewRow, ColumnsByValue);
				FillPropertyValues(NewRow, String, "Products,Characteristic,Stage,ProductCostElement");
				
				NewRow.LineKind = Enums.KindsOfProductionOrderStructureLines.Consumption;
				
				If Product.ProcessType = Enums.ProductionProcessTypes.Disassembly
					And (Product.Products = NewRow.Products And Product.Characteristic = NewRow.Characteristic) Then
					NewRow.Warehouse = Product.Warehouse;
					NewRow.Purpose = Product.Purpose;
				Else
					
					If String.ItemsType <> Enums.ItemsTypes.Work_5 Then
						NewRow.Warehouse = String.Warehouse;
					Else
						NewRow.Warehouse = String.StageSubdivision;
					EndIf;
					If String.WithAssignment Or String.ToPlan And Lot.TollManufacturing Then
						NewRow.Purpose = Product.StructureAssignment;
					EndIf;
					
				EndIf;
				
				If String.SupplyOption = Enums.SupplyOptions.NotRequired
						Or String.LineKind = Enums.TypesOfSpecificationLines.IntermediateSemiFinishedProduct Then
					NewRow.NotProvide = String.Count;
				Else
					NewRow.ToSupply = String.Count;
				EndIf;
				
				NewRow.Department = String.StageSubdivision;
				NewRow.SemiFinishedProductBOM = ?(String.ProducedInProcess, String.BillOfMaterials, Catalogs.BillsOfMaterials.EmptyRef());
				NewRow.DurationBeforeProductionIssue = String.DurationBeforeProductionIssue + Product.DurationUntilReleaseParent;
				NewRow.CommunicationKeyBillOfMaterialsRow = String.ConnectionKey; // CommunicationKeyBillOfMaterialsRow
				
				If String.QuantityCalculationAlgorithm <> "" And SpecificationData.MainProduct.NumberOfPackages > 0 Then
					NewRow.QuantityForLaunchLotUnit = String.Count
																		* SpecificationData.MainProduct.NumberOfPackagesPerUnitOfProductionBatch / SpecificationData.MainProduct.NumberOfPackages;
				Else
					NewRow.QuantityForLaunchLotUnit = String.NumberOfPackagesPerUnitOfProductionBatch * String.PackageData.Numerator / String.PackageData.Denominator;
				EndIf;
				
				SetStringLinkKey(NewRow, "OrderStructure", "KeyProducts", KeysLinks);
				
			EndDo;
			
	#EndRegion
	
	#Region LaborCosts
	
			RegisteredRecordsLaborCosts = Storage.OrderStructureLaborCosts; // ValueTable
		
			ColumnsByValue = New Structure();
			ColumnsByValue.Insert("KeyLot",          Lot.KeyLot);
			ColumnsByValue.Insert("BillOfMaterials",        Product.BillOfMaterials);
			ColumnsByValue.Insert("ProductionOrder", Product.ProductionOrder);
			ColumnsByValue.Insert("DataVersionID", ?(Lot.TollManufacturing, "", SpecificationData.DataVersionID));
			
			For Each String In SpecificationData.LaborCosts Do
			
				NewRow = RegisteredRecordsLaborCosts.Add();
				
				FillPropertyValues(NewRow, ColumnsByValue);
				FillPropertyValues(NewRow, String, "WorkKind,Stage,ProductCostElement");
				
				NewRow.Count = String.Count;
				
				NewRow.Department = String.StageSubdivision;
				NewRow.CommunicationKeyBillOfMaterialsRow = String.ConnectionKey; // CommunicationKeyBillOfMaterialsRow
				
				If String.QuantityCalculationAlgorithm <> "" And SpecificationData.MainProduct.NumberOfPackages > 0 Then
					NewRow.QuantityForLaunchLotUnit = String.Count
																		* SpecificationData.MainProduct.NumberOfPackagesPerUnitOfProductionBatch / SpecificationData.MainProduct.NumberOfPackages;
				Else
					NewRow.QuantityForLaunchLotUnit = String.QuantityPerReleaseLotUnit;
				EndIf;
				
				SetStringLinkKey(NewRow, "OrderStructureLaborCosts", "KeyWorkType", KeysLinks);
				
			EndDo;
			
	#EndRegion
		
		EndIf;
		
	EndIf;
	
	If Lot.HadErrors Then
		FillInAttributesInRegisteredRecordsAccordingToSelectionParameters(Storage, New Structure("KeyLot", Lot.KeyLot), New Structure("DataVersionID", New UUID("00000000-0000-0000-0000-000000000000")));
	EndIf;

EndProcedure

Function NeedAdditionalCalculationOfFreeIssue(Lot, SpecificationData)
	
	If SpecificationData.ManufacturedProducts.Count() > 1 Or Lot.Balance <> 0 Then
		Return True;
	EndIf;
	
	If SpecificationData.RecyclableWaste.Count() > 0 And FindRowByColumnValueInArrayOfRows(Lot.Rows, "SideExit", True) <> Undefined Then
		Return True;
	EndIf;
	
	Return False;

EndFunction

Function AvailableRelease(Lot, SpecificationData)
	
	Products_1 = Lot.Rows;
	
	NeedAdditionalCalculationOfFreeIssue = NeedAdditionalCalculationOfFreeIssue(Lot, SpecificationData);
	
	If Not
		NeedAdditionalCalculationOfFreeIssue Then
		
		AvailableRelease = SpecificationData.RecyclableWaste;
		
	Else
		
		AvailableRelease = SpecificationData.RecyclableWaste.CopyColumns();
		
		Cache = AvailableRelease.CopyColumns("Products,Characteristic,Count,NumberOfPackagesPerUnitOfProductionBatch"); // ValueTable
		Cache.Columns.Add("String");
		
		For Each String In SpecificationData.ManufacturedProducts Do
			NewRow = Cache.Add();
			FillPropertyValues(NewRow, String);
			NewRow.String = String;
		EndDo;
		
		For Each String In SpecificationData.RecyclableWaste Do
			NewRow = Cache.Add();
			FillPropertyValues(NewRow, String);
			NewRow.String = String;
		EndDo;
		
		Cache.Indexes.Add("Products,Characteristic");
		
		FilterStructure1 = New Structure("Products,Characteristic");
		
		For Each Product In Products_1 Do
			
			FillPropertyValues(FilterStructure1, Product);
			
			If Not ValueIsFilled(Lot.LineAdjustment) Then
				Required2 = Product.Required2;
			Else
				Required2 = Product.Required2 - AdjustValue(NumberType(), Lot.LineAdjustment[Product.KeyProducts]);
			EndIf;
			
			Rows = Cache.FindRows(FilterStructure1);
			
			For Each String In Rows Do
				Allocated = Min(Required2, String.Count);
				String.Count = String.Count - Allocated;
				Required2 = Required2 - Allocated;
			EndDo;
			
		EndDo;
		
		For Each String In Cache Do
			
			If String.Count > 0 Or String.NumberOfPackagesPerUnitOfProductionBatch > 0 And String.String.Owner() = SpecificationData.RecyclableWaste Then
				NewRow = AvailableRelease.Add();
				FillPropertyValues(NewRow, String.String);
				NewRow.Count = String.Count;
				NewRow.NumberOfPackagesPerUnitOfProductionBatch = String.NumberOfPackagesPerUnitOfProductionBatch;
			EndIf;
		
		EndDo;
		
	EndIf;
	
	Return AvailableRelease;
	
EndFunction 

Function AccessoriesForReverseKitting(Lot, SpecificationData)

	NeedAdditionalCalculationOfFreeIssue = SpecificationData.RecyclableWaste.Count() > 0;

	If Not
		NeedAdditionalCalculationOfFreeIssue Then
		
		AvailableRelease = SpecificationData.ManufacturedProducts;
		
		If AvailableRelease.Columns.Find("ProductCostElement") = Undefined Then
			AvailableRelease.Columns.Add("ProductCostElement", New TypeDescription("CatalogRef.ProductCostElements"));
		EndIf;
		
	Else
		
		AvailableRelease = SpecificationData.RecyclableWaste.Copy();
		
		For Each String In SpecificationData.ManufacturedProducts Do
			NewRow = AvailableRelease.Add();
			FillPropertyValues(NewRow, String);
		EndDo;
		
	EndIf;

	Return AvailableRelease;
	
EndFunction

// Calculates changes and adds reverse entries to the movement table
// 
// Parameters:
// 	RegisterRecords - ValueTable - RegisterRecords
Procedure CalculateChangesAndAddReverseRegisteredRecordsToOrderStructureTable(RegisterRecords)
	
	MetadataStructure = InformationRegisters.OrderStructure.MetadataStructure();
	
	PrimaryLines = RegisterRecords.FindRows(New Structure("CalculateChanges_", True));
	
	Deltas = RegisterRecords.CopyColumns(
		MetadataStructure.DimensionsString + ",ToSupply,NotProvide,Scheduled,ReverseKittingScheduled");
	
	Deltas.Columns.Add("NumberOfMovementLineBeforeChange", Common.TypeDescriptionNumber(10, 0));
	Deltas.Columns.Add("LineNumber", Common.TypeDescriptionNumber(10, 0));
	
	For IndexOf = 0 To PrimaryLines.UBound() Do
		
		String = PrimaryLines[IndexOf];
		
		NewRow = Deltas.Add();
		FillPropertyValues(NewRow, String);
		
		If String.AdditionalRecord Then
			Continue;
		EndIf;
		
		If String.RegisteredRecordsBeforeChange Then
			NewRow.NumberOfMovementLineBeforeChange = IndexOf + 1;
		Else
			NewRow.LineNumber                    = IndexOf + 1;
		EndIf;
		
	EndDo;
	
	Deltas.GroupBy(MetadataStructure.DimensionsString,
		"ToSupply,NotProvide,Scheduled,ReverseKittingScheduled" + ",LineNumber,NumberOfMovementLineBeforeChange");
	
	For Each Delta In Deltas Do
		
		If (Delta.ToSupply = 0 And Delta.NotProvide = 0 And Delta.Scheduled = 0 And Delta.ReverseKittingScheduled = 0) Then
			Continue;
		EndIf;
		
		RegisteredRecordsBeforeChange = Not Delta.ToSupply >= 0 Or Not Delta.NotProvide >= 0 Or Not Delta.Scheduled >= 0 Or Not Delta.ReverseKittingScheduled >= 0;
		
		NewRow = RegisterRecords.Add();
		
		RowIndex = ?(RegisteredRecordsBeforeChange, Delta.NumberOfMovementLineBeforeChange, Delta.LineNumber) - 1;
		PrimaryLine = PrimaryLines[RowIndex];
		
		FillPropertyValues(NewRow, PrimaryLine, MetadataStructure.StringAttributes);
		FillPropertyValues(NewRow, Delta);
		
		If RegisteredRecordsBeforeChange Or Delta.NumberOfMovementLineBeforeChange <> 0 Then
		
			NewRow.AdditionalRecord = True;
			NewRow.Separator = New UUID();
			
		EndIf;
		
	EndDo;
	
	DeleteRowsFromTable(RegisterRecords, PrimaryLines);
	
EndProcedure

// Calculates changes and adds reverse entries to the movement table
// 
// Parameters:
// 	RegisterRecords - ValueTable - RegisterRecords
Procedure CalculateChangesAndAddReverseRegisteredRecordsToTableLaborCostsOfOrderStructure(RegisterRecords)
	
	MetadataStructure = InformationRegisters.OrderStructureLaborCosts.MetadataStructure();
	
	PrimaryLines = RegisterRecords.FindRows(New Structure("CalculateChanges_", True));
	
	Deltas = RegisterRecords.CopyColumns(MetadataStructure.DimensionsString + ",Count");
	
	Deltas.Columns.Add("NumberOfMovementLineBeforeChange", Common.TypeDescriptionNumber(10, 0));
	Deltas.Columns.Add("LineNumber", Common.TypeDescriptionNumber(10, 0));
	
	For IndexOf = 0 To PrimaryLines.UBound() Do
		
		String = PrimaryLines[IndexOf];
		
		NewRow = Deltas.Add();
		FillPropertyValues(NewRow, String);
		
		If String.AdditionalRecord Then
			Continue;
		EndIf;
		
		If String.RegisteredRecordsBeforeChange Then
			NewRow.NumberOfMovementLineBeforeChange = IndexOf + 1;
		Else
			NewRow.LineNumber                    = IndexOf + 1;
		EndIf;
		
	EndDo;
	
	Deltas.GroupBy(MetadataStructure.DimensionsString, "Count" + ", LineNumber, NumberOfMovementLineBeforeChange");
	
	For Each Delta In Deltas Do
		
		If Delta.Count = 0 Then
			Continue;
		EndIf;
		
		RegisteredRecordsBeforeChange = Not Delta.Count >= 0;
		
		NewRow = RegisterRecords.Add();
		
		RowIndex = ?(RegisteredRecordsBeforeChange, Delta.NumberOfMovementLineBeforeChange, Delta.LineNumber) - 1;
		PrimaryLine = PrimaryLines[RowIndex];
		
		FillPropertyValues(NewRow, PrimaryLine, MetadataStructure.StringAttributes);
		FillPropertyValues(NewRow, Delta);
		
		If RegisteredRecordsBeforeChange Or Delta.NumberOfMovementLineBeforeChange <> 0 Then
		
			NewRow.AdditionalRecord = True;
			NewRow.Separator = New UUID();
			
		EndIf;
		
	EndDo;
	
	DeleteRowsFromTable(RegisterRecords, PrimaryLines);
	
EndProcedure

Function RecordingPortions()
	
	Portions = New ValueTable();
	
	Portions.Columns.Add("PortionNumber", Common.TypeDescriptionNumber(4, 0));
	
	Portions.Columns.Add("Replace", New TypeDescription("Boolean"));
	Portions.Columns.Add("Available", New TypeDescription("Boolean"));
	
	Portions.Columns.Add("RowsCount", Common.TypeDescriptionNumber(10, 0));
	
	Return Portions;
	
EndFunction

Function RecordPortion(RecordingPortions, Replace, Find = False, RowsCount = 1, RecordPortion = Undefined)
	
	If Find
		And RecordPortion = Undefined Then
		
		NumberOfRowsInTheRecordset = NumberOfRowsInTheRecordset();
		
		FoundRows = RecordingPortions.FindRows(New Structure("Available, Replace", Find, Replace));
		
		For Each FoundRow In FoundRows Do
			
			If RowsCount < ( NumberOfRowsInTheRecordset - FoundRow.RowsCount ) Then
				
				RecordPortion = FoundRow;
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If RecordPortion = Undefined Then
		
		RecordPortion = RecordingPortions.Add();
		
		RecordPortion.Replace    = Replace;
		RecordPortion.PortionNumber = RecordingPortions.Count();
		
	EndIf;
	
	Return RecordPortion;
	
EndFunction

Procedure SetPortionNumberInMovementCollection(Collection, PortionNumber)
	
	For Each CurrentRow In Collection Do CurrentRow.PortionNumber = PortionNumber;
	EndDo;
	
EndProcedure

Procedure FillInColumnsInTableAccordingToSelectionParameters(Table, FilterParameters, ColumnsByValue)
	
	If FilterParameters = Undefined Then
	
		For Each CurrentRow In Table Do FillPropertyValues(CurrentRow, ColumnsByValue);
		EndDo;
	
	Else
		
		For Each CurrentRow In Table.FindRows(FilterParameters) Do FillPropertyValues(CurrentRow, ColumnsByValue);
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillInAttributesInRegisteredRecordsAccordingToSelectionParameters(Storage, FilterParameters, ColumnsByValue)
	
	For Each Data In Storage Do
		FillInColumnsInTableAccordingToSelectionParameters(Data.Value, FilterParameters, ColumnsByValue);
	EndDo;
	
EndProcedure

Procedure SetStringLinkKey(String, TSName, FieldName, KeysLinks)
	
	FillPropertyValues(KeysLinks.Key, String);
	
	FoundRows = KeysLinks.Cache.FindRows(KeysLinks.Key);
	
	If FoundRows.Count() = 1 Then
		
		String[FieldName] = FoundRows[0].ConnectionKey;
		
	Else
		
		String[FieldName] = New UUID();
		
	EndIf;
	
EndProcedure

Function ProductGroupChecksum(Data, FieldNameSpecification = "BillOfMaterials", FieldNameOrder = "ProductionOrder") Export
	
	DataHashing = New DataHashing(HashFunction.MD5);
	
	DataHashing.Append("" + Data[FieldNameSpecification].UUID());
	DataHashing.Append("" + Data[FieldNameOrder].UUID());
	
	Return StrReplace(DataHashing.HashSum, " ", "");
	
EndFunction

Function EmptyProductGroup()
	
	Return "                                ";
	
EndFunction

Function PortionOfCalculationOfProductGroup(PortionOfCalculation)
	
	RowsCount = PortionOfCalculation.Count();
	
	ManufacturedProductsGroups = New Array(RowsCount);
	
	For IndexOf = 0 To RowsCount - 1 Do
		ManufacturedProductsGroups[IndexOf] = ProductGroupChecksum(PortionOfCalculation[IndexOf]);
	EndDo;
	
	Return ManufacturedProductsGroups;
	
EndFunction

Function IdOfLotReferenceInProductGroup(Val ProductItemsGroup, Val IdInProductGroupKeyParent, Val ParentLevel, Val NumberInProductGroup)
	
	If ParentLevel > 0 And IsBlankString(IdInProductGroupKeyParent) Then
		Return ""; // skip it to save the behavior for "old" orders (we don't do the update handler)
	EndIf;
	
	//Product Group IDENTIFIER - String (70)
	//  * Parent product group (32 characters)
	//  * Lot number in the parent product group (3 characters in Base36)
	//  * Product group (32 characters)
	//  * lot number in the product group (3 characters in Base36)
	
	NumberInProductGroup36 = ConvertBase36(NumberInProductGroup, 3); // See definable types.The identifier of the Product groupstructure of the order
	
	Result = ""
		+ IdInProductGroupKeyParent
		+ ProductItemsGroup
		+ Left("000", 3 - StrLen(NumberInProductGroup36))
		+ NumberInProductGroup36;
	
	Return Result;
	
EndFunction

Function ExtractParentKeyFromId(Val ProductionLotIDInProductGroup)
	
	Result = Left(ProductionLotIDInProductGroup, 35); // See definable types.The identifier of the Product groupstructure of the order

	If Result = "" Then
		Result = "00000000000000000000000000000000000";
	EndIf;
	
	Return Result;
	
EndFunction

Function ExtractLotReferenceKeyFromId(Val ProductionLotIDInProductGroup)
	
	Result = Right(ProductionLotIDInProductGroup, 35); // See definable types.The identifier of the Product groupstructure of the order

	If Result = "" Then
		Result = "00000000000000000000000000000000000";
	EndIf;
	
	Return Result;
	
EndFunction

Function ExtractLotReferenceCodeFromIdentifier(Val ProductionLotIDInProductGroup)
	
	Result = ConvertFromBase36ToDecimalNumber(Right(ProductionLotIDInProductGroup, 3)); // See definable types.The identifier of the Product groupstructure of the order
	Return Result;
	
EndFunction

Function ExtractProductGroupFromId(Val ProductionLotIDInProductGroup)
	
	Result = Mid(ProductionLotIDInProductGroup, 35, 32); // See definable types.The identifier of the Product groupstructure of the order
	Return Result;
	
EndFunction

Function ConvertBase36(Val Decimal, Val Digits = 15)
	
	Result = "";
	
	Decimal = Min(Decimal, Pow(36, Digits));
	
	While Decimal > 0 Do
		Remainder = Decimal % 36;
		Decimal  = (Decimal - Remainder) / 36;
		Result        = Mid("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", Remainder + 1, 1) + Result;
	EndDo;

	Return Result;
	
EndFunction

Function ConvertFromBase36ToDecimalNumber(Val Value)
	
	Value = Upper(Value);
	StringLength = StrLen(Value);
	
	Result = 0;
	For CharacterNumber = 1 To StringLength Do
		Result = Result * 36 + StrFind("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", Mid(Value, CharacterNumber, 1)) - 1;
	EndDo;
	
	Return Result;
	
EndFunction

Function FindBatchKeyInCache(BatchCache, Val IdInProductGroupKeyParent, Val ProductItemsGroup, FieldsOfPriority, CacheLotReferenceSearchKey, SuitableLotReference)
	
	SuitableLotReference = Undefined;

	CacheLotReferenceSearchKey.ProductItemsGroup = ProductItemsGroup;
	CacheLotReferenceSearchKey.IdInProductGroupKeyParent = IdInProductGroupKeyParent;
	
	SuitableLotReference0 = Undefined;
	SuitableLotReference1 = Undefined;
	
	FoundRows = BatchCache.FindRows(CacheLotReferenceSearchKey);
	
	For Each String In FoundRows Do
		
		If String.KeyIsUsed Then
			Continue;
		EndIf;
		
		SuitableLotReference = String;
		
		If SuitableLotReference.KeyLot = FieldsOfPriority.KeyLot Then
			If SuitableLotReference.KeyProducts = FieldsOfPriority.KeyProducts Then
				SuitableLotReference0 = SuitableLotReference;
				Break;
			EndIf;
			SuitableLotReference1 = SuitableLotReference;
		EndIf;
		
	EndDo;
	
	SuitableLotReference = ?(SuitableLotReference0 <> Undefined,
							SuitableLotReference0,
							?(SuitableLotReference1 <> Undefined,
									SuitableLotReference1,
									SuitableLotReference));
	
	If SuitableLotReference <> Undefined Then
		
		SuitableLotReference.KeyIsUsed = True;
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

Procedure AddMessageToErrorList(ErrorList, MessageText)

	If ErrorList = Undefined Then
		ErrorList = New Array;
	EndIf;
	
	ErrorList.Add(MessageText);
	
EndProcedure

#EndRegion

#Region InventoryAllocation

Procedure PerformInventoryAllocation(ActionParameters, ResultAddress) Export
	
	KeyOperation = "OrderStructure.InventoryAllocation";
	CalculationStart = CurrentUniversalDateInMilliseconds();
	PortionSize = ActionParameters.PortionOfCalculation.Count();
	TimeMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
	PerformInventoryAllocationWithinTimeMeasurement(ActionParameters);
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(TimeMeasurement, PortionSize);
	CalculationResult2 = New Structure("Operation, PortionSize, Duration", KeyOperation, PortionSize, CurrentUniversalDateInMilliseconds() - CalculationStart);
	PutToTempStorage(CalculationResult2, ResultAddress);
	
EndProcedure

Procedure PerformInventoryAllocationWithinTimeMeasurement(ActionParameters)
	
	SetPrivilegedMode(True);
	
	TempTablesManager = New TempTablesManager();
	
	StateOfStocks = New Array();
	StateOfStocks.Add(Enums.InventoryStates.InStock);
	StateOfStocks.Add(Enums.InventoryStates.AvailablePendingUnlocking);
	StateOfStocks.Add(Enums.InventoryStates.ExpectedForReceiptWithoutLock);
	StateOfStocks.Add(Enums.InventoryStates.ExpectedForReceiptWithLock);
	StateOfStocks.Add(Enums.InventoryStates.PendingSupplyApproval);
	
	DemandCharacteristic = Enums.DemandCharacteristics.Surplus;
	
	CalculationParameters = ActionParameters.CalculationParameters;
	PortionOfCalculation = ActionParameters.PortionOfCalculation;
	
	AnalogsAreUsed = GetFunctionalOption("UseAlternativeMaterials");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("PortionOfCalculation", PortionOfCalculation);
	Query.SetParameter("StateOfStocks", StateOfStocks);
	Query.SetParameter("DemandCharacteristic", DemandCharacteristic);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("AnalogsAreUsed", AnalogsAreUsed);
	
	ArrayOfRequestTexts = New Array;
	
	TextCalculationPortion = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Purpose AS Purpose,
	|	Goods.Id AS Id
	|INTO PortionOfCalculation
	|FROM
	|	&PortionOfCalculation AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT DISTINCT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Purpose AS Purpose,
	|	Goods.WithAssignment AS WithAssignment,
	|	Goods.Id AS Id
	|INTO GoodsByPortion
	|FROM (
	|
	|SELECT
	|
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|
	|	GoodsProducts.AssignedPurchaseSale AS WithAssignment,
	|
	|	CASE
	|		WHEN GoodsProducts.AssignedPurchaseSale
	|		  OR Goods.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			THEN Goods.Purpose
	|		WHEN TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				PortionOfCalculation AS DD
	|			WHERE
	|				DD.Products = Goods.Products
	|				AND DD.Characteristic = Goods.Characteristic
	|				AND DD.Warehouse = Goods.Warehouse
	|				AND DD.Purpose = VALUE(Catalog.Assignments.EmptyRef))
	|		OR TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.InventoryAllocation AS DD
	|			WHERE
	|				DD.InventoryState IN (&StateOfStocks)
	|				AND DD.DemandCharacteristic = &DemandCharacteristic
	|				AND DD.Products = Goods.Products
	|				AND DD.Characteristic = Goods.Characteristic
	|				AND DD.Warehouse = Goods.Warehouse
	|				AND DD.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|				AND DD.Count > 0)
	|		OR TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.OrderStructure AS DD
	|			WHERE
	|				DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.AvailableRelease)
	|				AND DD.Products = Goods.Products
	|				AND DD.Characteristic = Goods.Characteristic
	|				AND DD.Warehouse = Goods.Warehouse
	|				AND DD.Purpose = VALUE(Catalog.Assignments.EmptyRef))
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE Goods.Purpose
	|	END AS Purpose,
	|	Goods.Id AS Id
	|
	|FROM
	|	PortionOfCalculation AS Goods
	|
	|		LEFT JOIN Catalog.Products AS GoodsProducts
	|		ON Goods.Products = GoodsProducts.Ref
	|
	|) AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose";
	
	TextAnaloguesOfMaterials = 
	"SELECT DISTINCT
	|	ConnectionsOfMaterialsAndAnalogues.Products AS Products,
	|	ConnectionsOfMaterialsAndAnalogues.Characteristic AS Characteristic,
	|	ConnectionsOfMaterialsAndAnalogues.Id AS Id
	|INTO RelatedMaterialAnalogues
	|FROM
	|	GoodsByPortion AS Goods
	|		INNER JOIN InformationRegister.ItemLinksByChangeOrders AS ConnectionsOfMaterialsAndAnalogues
	|		ON (Goods.Id = ConnectionsOfMaterialsAndAnalogues.Id)
	|WHERE
	|	&AnalogsAreUsed
	|
	|INDEX BY
	|	Id";
	
	TextSupplementWithAnalogues = 
	"SELECT DISTINCT
	|	RelatedMaterialAnalogues.Products AS Products,
	|	RelatedMaterialAnalogues.Characteristic AS Characteristic,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Purpose AS Purpose,
	|	Goods.WithAssignment AS WithAssignment,
	|	Goods.Id AS Id
	|ADD GoodsByPortion
	|FROM
	|	GoodsByPortion AS Goods
	|		INNER JOIN RelatedMaterialAnalogues AS RelatedMaterialAnalogues
	|		ON (Goods.Id = RelatedMaterialAnalogues.Id)";
	
	ArrayOfRequestTexts.Add(TextCalculationPortion);
	ArrayOfRequestTexts.Add(TextAnaloguesOfMaterials);
	
	If AnalogsAreUsed Then
		ArrayOfRequestTexts.Add(TextSupplementWithAnalogues);
	EndIf;
	
	TextNomenclaturePlan = 
	"SELECT DISTINCT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.WithAssignment AS WithAssignment,
	|	Goods.Id AS Id
	|INTO AllGoods
	|FROM (
	|
	|SELECT
	|
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	CASE
	|		WHEN TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				GoodsByPortion AS DD
	|			WHERE
	|				DD.Products = Goods.Products
	|				AND DD.Characteristic = Goods.Characteristic
	|				AND DD.Purpose = VALUE(Catalog.Assignments.EmptyRef))
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE Goods.Purpose
	|	END AS Purpose,
	|	Goods.WithAssignment AS WithAssignment,
	|	Goods.Id AS Id
	|
	|FROM
	|	GoodsByPortion AS Goods
	|
	|) AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose
	|;
	|SELECT
	|
	|	RECORDAUTONUMBER() AS RowIndex,
	|
	|	Goods.Id         AS Id,
	|	RegisterRecords.Products        AS Products,
	|	RegisterRecords.Characteristic      AS Characteristic,
	|	RegisterRecords.Warehouse               AS Warehouse,
	|	RegisterRecords.Purpose          AS Purpose,
	|	RegisterRecords.ProductionOrder AS ProductionOrder,
	|	RegisterRecords.KeyProducts    AS KeyProducts,
	|
	|	SUM(RegisterRecords.ToSupply) AS ToSupply,
	|	SUM(RegisterRecords.Replaced) AS Replaced,
	|	SUM(RegisterRecords.Ordered)
	|		- SUM(CASE
	|			WHEN RegisterRecords.LineKind IN (VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|										VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
	|				THEN RegisterRecords.AllocatedInFreeProductionLots + RegisterRecords.AllocatedInAssignedProductionLots
	|			ELSE 0
	|		END) AS Ordered,
	|	SUM(CASE
	|			WHEN NOT RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.AvailableRelease) THEN
	|				RegisterRecords.Scheduled + RegisterRecords.ReverseKittingScheduled
	|			ELSE
	|				0
	|		END) AS Scheduled,
	|	SUM(CASE
	|			WHEN RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move) THEN
	|				RegisterRecords.Scheduled + RegisterRecords.ReverseKittingScheduled
	|			ELSE
	|				0
	|		END) AS PlannedToMove,
	|	SUM(CASE
	|			WHEN RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.AvailableRelease) THEN
	|				RegisterRecords.Scheduled
	|			ELSE
	|				0
	|		END) AS AvailableRelease,
	|	SUM(CASE
	|			WHEN RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
	|					AND RegisterRecords.ReceiptOrder = UNDEFINED
	|				THEN RegisterRecords.AllocatedFromAvailableInventory + RegisterRecords.AllocatedFromAvailableInventoryWithAssignment
	|			ELSE 0
	|		END) AS DistributedFromStockAvailability,
	|	SUM(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
	|				THEN RegisterRecords.Scheduled
	|			ELSE
	|				0
	|		END) AS LoopLimitControl,
	|
	|	MAX(Goods.Purpose) AS PurposeGrouping,
	|
	|	MAX(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
	|			THEN TRUE
	|		ELSE FALSE
	|	END) AS ThisIsOutput_,
	|
	|	MIN(RegisterRecords.ReceiptOrder) AS ReceiptOrder,
	|	MIN(RegisterRecords.DateOfReceipt) AS DateOfReceipt,
	|	
	|	MIN(CASE
	|		WHEN RegisterRecords.LineKind NOT IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Move))
	|			THEN RegisterRecords.KeyLot
	|	END) AS KeyLot,
	|	
	|	MIN(CASE
	|		WHEN RegisterRecords.LineKind NOT IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Move))
	|			THEN RegisterRecords.Stage
	|	END) AS Stage,
	|
	|	MIN(CASE
	|		WHEN RegisterRecords.LineKind NOT IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Move))
	|			THEN RegisterRecords.Department
	|	END) AS Department,
	|
	|	MAX(RegisterRecords.StructureAssignment) AS StructureAssignment,
	|
	|	ISNULL(MIN(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
	|			THEN RegisterRecords.Level
	|	END), 0) AS Level,
	|
	|	ISNULL(MIN(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.AvailableRelease))
	|			THEN RegisterRecords.DurationBeforeProductionIssue
	|	END), 0) AS DurationBeforeProductionIssue,
	|
	|	ISNULL(MIN(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
	|			THEN RegisterRecords.ProductionLotIDInProductGroup
	|	END), 0) AS ProductionLotIDInProductGroup,
	|
	|	MAX(CASE
	|		WHEN RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption) THEN
	|			RegisterRecords.BillOfMaterials
	|		ELSE
	|			VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|	END) AS BillOfMaterials,
	|	MAX(CASE
	|		WHEN RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption) THEN
	|			RegisterRecords.CommunicationKeyBillOfMaterialsRow
	|		ELSE
	|			&EmptyLinkKey
	|	END) AS CommunicationKeyBillOfMaterialsRow,
	|
	|	MAX(CASE
	|		WHEN RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|			AND RegisterRecords.PermissionToReplace <> VALUE(Document.EngineeringChangeOrder.EmptyRef) THEN
	|			&EmptyLinkKey
	|		ELSE
	|			RegisterRecords.ConnectionKeyTransfer
	|	END) AS ConnectionKeyTransfer,
	|	MAX(CASE
	|		WHEN RegisterRecords.PermissionToReplace = VALUE(Document.EngineeringChangeOrder.EmptyRef)
	|			OR RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|		THEN RegisterRecords.ConnectionKeyTransfer
	|		ELSE &EmptyLinkKey
	|	END) AS NeedCommunicationKey,
	|	MAX(RegisterRecords.PermissionToReplace <> VALUE(Document.EngineeringChangeOrder.EmptyRef)) AS ThisIsASubstitute,
	|	MAX(RegisterRecords.SemiFinishedProductBOM) AS SemiFinishedProductBOM,
	|
	|	MAX(CASE
	|		WHEN RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
	|			THEN RegisterRecords.QuantityForLaunchLotUnit
	|	END) AS QuantityForLaunchLotUnit,
	|	MIN(CASE
	|			WHEN RegisterRecords.ToSupply > 0
	|				THEN RegisterRecords.KeySet
	|		END) AS KeySet,
	|	MAX(CASE
	|		WHEN RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|		AND RegisterRecords.ConnectionKeyTransfer = &EmptyLinkKey THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END) AS InitialDemand
	|	
	|INTO ItemPlan
	|
	|FROM
	|	AllGoods AS Goods
	|
	|	INNER JOIN InformationRegister.OrderStructure AS RegisterRecords
	|	ON Goods.Products   = RegisterRecords.Products
	|	 AND Goods.Characteristic = RegisterRecords.Characteristic
	|	 AND (Goods.Purpose    = RegisterRecords.Purpose
	|		OR NOT Goods.WithAssignment AND Goods.Purpose IN (RegisterRecords.StructureAssignment, VALUE(Catalog.Assignments.EmptyRef)))
	|
	|GROUP BY
	|	Goods.Id, RegisterRecords.Products, RegisterRecords.Characteristic, RegisterRecords.Warehouse, RegisterRecords.Purpose,
	|	RegisterRecords.ProductionOrder, RegisterRecords.KeyProducts
	|
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose, ProductionOrder, KeyProducts, KeyLot";
	
	ArrayOfRequestTexts.Add(TextNomenclaturePlan);
	
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	
	Query.Execute();
	
	GetAndCacheSupplyMethods(TempTablesManager, "ItemPlan");
	
	ArrayOfRequestTexts.Clear();
	
	QueryTextResultingTables = 
	"SELECT
	|
	|	Schedule.Products     AS Products,
	|	Schedule.Characteristic   AS Characteristic,
	|	Schedule.Warehouse            AS Warehouse,
	|	Schedule.Purpose       AS Purpose,
	|
	|	Schedule.ReceiptOrder AS ReceiptOrder,
	|	Schedule.AvailabilityDate    AS AvailabilityDate,
	|
	|	Schedule.Count AS Available
	|
	|INTO Schedule
	|FROM
	|	AllGoods AS Goods
	|
	|	INNER JOIN InformationRegister.InventoryAllocation AS Schedule
	|	ON Goods.Products   = Schedule.Products
	|	 AND Goods.Characteristic = Schedule.Characteristic
	|	 AND (Goods.Purpose = Schedule.Purpose
	|		OR NOT Goods.WithAssignment AND Goods.Purpose = VALUE(Catalog.Assignments.EmptyRef))
	|
	|WHERE
	|	Schedule.Count > 0
	|		AND Schedule.InventoryState IN (&StateOfStocks)
	|		AND Schedule.DemandCharacteristic = &DemandCharacteristic
	|
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose
	|;
	|DROP PortionOfCalculation
	|;
	|DROP GoodsByPortion
	|;
	|	
	|SELECT DISTINCT
	|	Plan.ProductionOrder AS Ref
	|INTO AllOrders
	|FROM
	|	ItemPlan AS Plan
	|;"  + ?(AnalogsAreUsed, QueryTextAlternativeMaterials(Query), "")
	 + OrderStructureInternal.RequestTextTemporaryTableOrderQueue("AllOrders", "Queue")
	 + "SELECT
	|	ItemPlan.ConnectionKeyTransfer AS ConnectionKeyTransfer,
	|	ItemPlan.NeedCommunicationKey AS NeedCommunicationKey
	|INTO KeyReplacement
	|FROM
	|	ItemPlan AS ItemPlan
	|WHERE 
	|	&AnalogsAreUsed 
	|	AND ItemPlan.ThisIsASubstitute
	|	AND ItemPlan.ToSupply > 0
	|	AND ItemPlan.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|
	|INDEX BY
	|	ConnectionKeyTransfer
	|
	|;
	|SELECT
	|	ItemPlan.Products AS Products,
	|	ItemPlan.Characteristic AS Characteristic,
	|	ItemPlan.Warehouse AS Warehouse,
	|	ItemPlan.ProductionOrder AS ProductionOrder,
	|	ItemPlan.KeyProducts AS KeyProducts,
	|	ItemPlan.KeyLot AS KeyLot,
	|	ItemPlan.KeySet AS KeySet,
	|	ISNULL(KeyReplacement.NeedCommunicationKey, ItemPlan.ConnectionKeyTransfer) AS ConnectionKeyTransfer
	|FROM
	|	ItemPlan AS ItemPlan
	|		LEFT JOIN KeyReplacement AS KeyReplacement
	|		ON ItemPlan.ConnectionKeyTransfer = KeyReplacement.ConnectionKeyTransfer
	|;
	|SELECT DISTINCT
	|	NSICache.Products.SupplyScheme AS SupplyScheme,
	|	ISNULL(NSICache.SupplyMethod.ProductionDurationDays, 0) * 86400 AS TransferDurationDays,
	|	NSICache.ProductionOrder AS ProductionOrder,
	|	NSICache.Warehouse AS DestinationWarehouse,
	|	NSICache.SupplyMethod.SourceOfDemandSupply AS SourceWarehouse
	|FROM
	|	ItemPlan AS Plan
	|		INNER JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
	|		ON Plan.Products = NSICache.Products
	|			AND Plan.Characteristic = NSICache.Characteristic
	|			AND Plan.ProductionOrder = NSICache.ProductionOrder
	|WHERE
	|	NSICache.ToPlan
	|;
	|
	|SELECT
	|
	|	Schedule.Products       AS Products,
	|	Schedule.Characteristic     AS Characteristic,
	|	Schedule.Warehouse              AS Warehouse,
	|	Schedule.Purpose         AS Purpose,
	|
	|	Schedule.ReceiptOrder AS ReceiptOrder,
	|	Schedule.AvailabilityDate    AS DateOfReceipt,
	|
	|	CASE
	|		WHEN Schedule.AvailabilityDate = DATETIME(1,1,1) AND Schedule.ReceiptOrder = UNDEFINED THEN
	|			1
	|		WHEN Schedule.AvailabilityDate <> DATETIME(1,1,1) AND Schedule.ReceiptOrder <> UNDEFINED THEN
	|			2
	|		ELSE
	|			3
	|	END AS TypeOfStock,
	|	
	|	Schedule.Available AS Available,
	|
	|	-1 AS QueueNumber,
	|	-1 AS OrderOfRegulatorySchedule
	|	
	|FROM
	|	Schedule AS Schedule
	|
	|UNION ALL
	|
	|SELECT
	|
	|	Plan.Products       AS Products,
	|	Plan.Characteristic     AS Characteristic,
	|	Plan.Warehouse              AS Warehouse,
	|	Plan.Purpose         AS Purpose,
	|
	|	Plan.ReceiptOrder AS ReceiptOrder,
	|	Plan.DateOfReceipt    AS DateOfReceipt,
	|
	|	5 AS TypeOfStock,
	|	
	|	Plan.AvailableRelease AS Available,
	|
	|	ISNULL(Queue.QueueNumber, 0)        AS QueueNumber,
	|	ISNULL(-Plan.DurationBeforeProductionIssue, 0) AS OrderOfRegulatorySchedule
	|	
	|FROM
	|	ItemPlan AS Plan
	|
	|		LEFT JOIN Queue AS Queue
	|		ON Queue.Ref = Plan.ProductionOrder
	|	
	|WHERE
	|	Plan.AvailableRelease > 0
	|
	|ORDER BY
	|	Products, Characteristic, Warehouse, Purpose, TypeOfStock, QueueNumber, OrderOfRegulatorySchedule, DateOfReceipt, ReceiptOrder
	|;
	|
	|SELECT
	|
	|	Plan.RowIndex AS RowIndex,
	|
	|	Plan.Products   AS Products,
	|	Plan.Products.SupplyScheme AS SupplyScheme,
	|	Plan.Characteristic AS Characteristic,
	|	Plan.Warehouse          AS Warehouse,
	|
	|	CASE
	|		WHEN Plan.Purpose <> VALUE(Catalog.Assignments.EmptyRef) THEN
	|			Plan.Purpose
	|		ELSE
	|			Plan.StructureAssignment
	|	END AS Purpose,
	|	CASE
	|		WHEN Plan.Purpose <> VALUE(Catalog.Assignments.EmptyRef) THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS WithAssignment,
	|
	|	Plan.ProductionOrder AS ProductionOrder,
	|	Plan.KeyLot          AS KeyLot,
	|	Plan.KeyProducts    AS KeyProducts,
	|	Plan.QuantityForLaunchLotUnit AS QuantityForLaunchLotUnit,
	|
	|	Plan.ToSupply AS Required2,
	|	Plan.Scheduled AS Scheduled,
	|	Plan.LoopLimitControl AS LoopLimitControl,
	|	Plan.ProductionLotIDInProductGroup AS ProductionLotIDInProductGroup,
	|
	|	ISNULL(Queue.QueueNumber, 0)        AS QueueNumber,
	|	ISNULL(-Plan.DurationBeforeProductionIssue, 0) AS OrderOfRegulatorySchedule
	|	
	|FROM
	|	ItemPlan AS Plan
	|
	|		LEFT JOIN Queue AS Queue
	|		ON Queue.Ref = Plan.ProductionOrder
	|
	|WHERE
	|	Plan.InitialDemand AND Plan.ToSupply > 0 AND NOT Plan.ThisIsOutput_
	|
	|ORDER BY
	|	Products, Characteristic, Warehouse, Plan.PurposeGrouping DESC, QueueNumber, Purpose DESC, WithAssignment DESC, OrderOfRegulatorySchedule,
	|	  CASE
	|			WHEN Plan.Stage REFS Document.ProductionStage2_2 THEN
	|				1
	|			ELSE
	|				2
	|	  END,
	|	  CASE
	|			WHEN Plan.Stage REFS Document.ProductionStage2_2 THEN
	|				Plan.Stage
	|			ELSE
	|				NULL
	|	  END,
	|	  ProductionLotIDInProductGroup,
	|	  KeyLot,
	|	  KeyProducts
	|;
	|DROP AllOrders; DROP Queue;
	|";
	
	ArrayOfRequestTexts.Add(QueryTextResultingTables);
	
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	
	QueryResult = Query.ExecuteBatch();
	NumberOfPackages_ = QueryResult.Count();
	
	If AnalogsAreUsed Then
		DataAboutAnalogs = DataAboutAnalogsForCalculatingOrderStructure(TempTablesManager);
	Else
		DataAboutAnalogs = Undefined;
	EndIf;

	AllocationResult = New ValueTable();
	AllocationResult.Columns.Add("RowIndex", Common.TypeDescriptionNumber(10,0));
	AllocationResult.Columns.Add("Purpose", Metadata.InformationRegisters.OrderStructure.Dimensions.Purpose.Type);
	AllocationResult.Columns.Add("DateOfReceipt", Metadata.InformationRegisters.OrderStructure.Dimensions.DateOfReceipt.Type);
	AllocationResult.Columns.Add("ReceiptOrder", Metadata.InformationRegisters.OrderStructure.Dimensions.ReceiptOrder.Type);
	AllocationResult.Columns.Add("Allocated", Common.TypeDescriptionNumber(15,3));
	AllocationResult.Columns.Add("Products", Metadata.InformationRegisters.OrderStructure.Dimensions.Products.Type);
	AllocationResult.Columns.Add("Characteristic", Metadata.InformationRegisters.OrderStructure.Dimensions.Characteristic.Type);
	AllocationResult.Columns.Add("Warehouse", Metadata.InformationRegisters.OrderStructure.Dimensions.Warehouse.Type);
	AllocationResult.Columns.Add("PermissionToReplace", Metadata.InformationRegisters.OrderStructure.Attributes.PermissionToReplace.Type);
	AllocationResult.Columns.Add("EntryType", Common.TypeDescriptionNumber(1,0));
	AllocationResult.Columns.Add("KeyProducts", Metadata.InformationRegisters.OrderStructure.Dimensions.KeyProducts.Type);
	AllocationResult.Columns.Add("KeyLot", Metadata.InformationRegisters.OrderStructure.Dimensions.KeyLot.Type);
	AllocationResult.Columns.Add("KeySet", Metadata.InformationRegisters.OrderStructure.Dimensions.KeySet.Type);
	AllocationResult.Columns.Add("ConnectionKeyTransfer", Metadata.InformationRegisters.OrderStructure.Attributes.ConnectionKeyTransfer.Type);
	AllocationResult.Columns.Add("CommunicationKeyIsAnalog", Metadata.InformationRegisters.OrderStructure.Attributes.ConnectionKeyTransfer.Type);
	AllocationResult.Columns.Add("KeyItemNeeds", Metadata.InformationRegisters.OrderStructure.Attributes.ConnectionKeyTransfer.Type);
	AllocationResult.Columns.Add("TransferDurationDays", Common.TypeDescriptionNumber(14, 4));
	AllocationResult.Columns.Add("QuantityForLaunchLotUnit", Metadata.InformationRegisters.OrderStructure.Attributes.QuantityForLaunchLotUnit.Type);
	
	DistributeStocks(QueryResult[NumberOfPackages_-3], QueryResult[NumberOfPackages_-4], QueryResult[NumberOfPackages_-5], AllocationResult, DataAboutAnalogs, QueryResult[NumberOfPackages_-6]);
	PlaceInventoryAllocationResultInTemporaryTableManager(TempTablesManager, AllocationResult, CalculationParameters.CalculateChanges_);
	AllocationResult = Undefined;
	
	CalculateChangesAndRecordResultOfInventoryAllocation(TempTablesManager, CalculationParameters);
	
	Query.Text =
	"SELECT
	|
	|	Plan.Products        AS Products,
	|	Plan.Characteristic      AS Characteristic,
	|	Plan.Warehouse               AS Warehouse,
	|	Plan.Purpose          AS Purpose,
	|	Plan.ProductionOrder AS ProductionOrder,
	|
	|	NSICache.SupplyType    AS SupplyType,
	|	NSICache.BillOfMaterials      AS BillOfMaterials,
	|
	|	NSICache.ErrorID AS ErrorID
	|
	|INTO ProductionPlan
	|FROM
	|	CalculatingChanges AS Plan
	|
	|	INNER JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
	|	ON Plan.Products        = NSICache.Products
	|	 AND Plan.Characteristic      = NSICache.Characteristic
	|	 AND Plan.Warehouse               = NSICache.Warehouse
	|	 AND Plan.Purpose          = NSICache.Purpose
	|	 AND Plan.ProductionOrder = NSICache.ProductionOrder
	|	 AND NSICache.ToPlan
	|	AND (NSICache.SupplyType = VALUE(Enum.SupplyTypes.Production))
	|
	|
	|WHERE
	|	CASE
	|		WHEN Plan.ThisIsOutput_ OR NSICache.ThisIsProductBeingDisassembled THEN // limiting looping of Reverse kitting
	|			Plan.Ordered <> Plan.Scheduled
	|		ELSE
	|			Plan.QuantityToProduction <> 0
	|	END
	|
	|INDEX BY
	|	BillOfMaterials";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	If Selection.Next() And Selection.Count > 0 Then
		ScheduleProduction(CalculationParameters, TempTablesManager, "ProductionPlan", ActionParameters.Queue);
	EndIf;
	
EndProcedure

Procedure DistributeStocks(ResultIsRequired, ResultStocks, ResultWarehouses, AllocationResult, PermissionsTable, ResultIsCacheOfLotReferenceKeys)
	
	If ResultIsRequired.IsEmpty() Then
		Return;
	EndIf;
	
	ScheduleProducts = CopyColumns(ResultStocks.Columns, "Products,Characteristic,Warehouse,Purpose");
	
	ScheduleProducts.Columns.Add("ThisIsASubstitute",      New TypeDescription("Boolean"));
	ScheduleProducts.Columns.Add("GraphIsDischarged", New TypeDescription("Boolean"));
	ScheduleProducts.Columns.Add("IndexOf",         New TypeDescription("Number", New NumberQualifiers(5, 0, AllowedSign.Nonnegative)));
	ScheduleProducts.Columns.Add("Boundary",        New TypeDescription("Number", New NumberQualifiers(5, 0, AllowedSign.Nonnegative)));
	
	ThereIsScheduleAvailable = Undefined;
	
	Schedule = ResultStocks.Unload();
	IndexOf = 0;
		
	ProductItemSchedule = Undefined;
	
	While Schedule.Count() > IndexOf Do
		
		CurrentRow = Schedule[IndexOf];
		
		If Not (IndexOf > 0
			 And ProductItemSchedule.Products   = CurrentRow.Products
			 And ProductItemSchedule.Characteristic = CurrentRow.Characteristic
			 And ProductItemSchedule.Warehouse          = CurrentRow.Warehouse
			 And ProductItemSchedule.Purpose     = CurrentRow.Purpose)  Then

			ProductItemSchedule = ScheduleProducts.Add();
			FillPropertyValues(ProductItemSchedule, CurrentRow);
			ProductItemSchedule.IndexOf = IndexOf;

		EndIf;
		
		IndexOf               = IndexOf + 1;
		ProductItemSchedule.Boundary = IndexOf;
		
	EndDo;
	
	PresenceOfBalances = Schedule.Copy(,"Products, Characteristic, Warehouse");
	PresenceOfBalances.GroupBy("Products, Characteristic, Warehouse");
	PresenceOfBalances.Indexes.Add("Products, Characteristic, Warehouse");
	SearchForPresenceOfBalances = New Structure("Products, Characteristic, Warehouse");
	
	DisplacementCalculationTable = CopyColumns(AllocationResult.Columns, "RowIndex,Products,Characteristic,PermissionToReplace,KeyProducts,KeyLot,Warehouse");
	DisplacementCalculationTable.Columns.Add("SequenceNumber", Common.TypeDescriptionNumber(10));
	DisplacementCalculationTable.Columns.Add("ProductionOrder", Metadata.InformationRegisters.OrderStructure.Dimensions.ProductionOrder.Type);
	DisplacementCalculationTable.Columns.Add("QuantityForLaunchLotUnit", Metadata.InformationRegisters.OrderStructure.Attributes.QuantityForLaunchLotUnit.Type);

	WarehouseTable = ResultWarehouses.Unload();
	WarehouseTable.Indexes.Add("SupplyScheme, DestinationWarehouse, ProductionOrder");
	
	ChainOfWarehouses = New ValueTable;
	ChainOfWarehouses.Columns.Add("SourceWarehouse", Metadata.InformationRegisters.OrderStructure.Dimensions.Warehouse.Type);
	ChainOfWarehouses.Columns.Add("DestinationWarehouse", Metadata.InformationRegisters.OrderStructure.Dimensions.Warehouse.Type);
	ChainOfWarehouses.Columns.Add("TransferDurationDays", Common.TypeDescriptionNumber(14, 4));
	ChainOfWarehouses.Columns.Add("SequenceNumber", Common.TypeDescriptionNumber(10));
	
	SearchForWarehouses = New Structure("SupplyScheme, DestinationWarehouse, ProductionOrder");
	WarehouseSearchComparison = New Structure("SupplyScheme, DestinationWarehouse, ProductionOrder");
	
	MatchingWarehouseChains = New Map;
	ArrayOfWarehousesCheckingLooping = New Array;
	DurationOfTransferAmount = 0;
	
	IterationMaterialDistribution = "UsedMaterials";
	IterationDistributionOfPriorityAnalogues = "PriorityAnalogues";
	IterationDistributionOfConventionalAnalogues = "ConventionalAnalogues";
	
	IterationsOfInventoryAllocation = New Array;
	IterationsOfInventoryAllocation.Add(IterationMaterialDistribution);
	
	ThereAreAnalogues = TypeOf(PermissionsTable) = Type("ValueTable") And PermissionsTable.Count() > 0;
	
	If ThereAreAnalogues Then
		IterationsOfInventoryAllocation.Insert(0, IterationDistributionOfPriorityAnalogues);
		IterationsOfInventoryAllocation.Add(IterationDistributionOfConventionalAnalogues);
		PermissionsTable.Indexes.Add("Products, Characteristic, Ref, PriorityAnalogue");
	EndIf;
		
	Required2Balance = Undefined;
	
	SearchForPermissions = New Structure("Products, Characteristic, Ref, PriorityAnalogue");
	AnalogAnalytics = New Structure("Products, Characteristic, Warehouse, Purpose");
	
	ScheduleProducts.Indexes.Add("Products,Characteristic,Warehouse,Purpose");
	
	RecordTypeInventoryAllocationReserve = RecordTypeInventoryAllocationReserve();
	RecordTypeInventoryAllocationRelocationRequired = RecordTypeInventoryAllocationRelocationRequired();
	RecordTypeInventoryAllocationConsumptionRequired =  RecordTypeInventoryAllocationConsumptionRequired();
	RecordTypeInventoryAllocationClosingNeeds = RecordTypeInventoryAllocationClosingNeeds();
	RecordTypeInventoryAllocationReplacement = RecordTypeInventoryAllocationReplacement();
	TypeOfRecordDoesNotProvideInventoryAllocation = TypeOfRecordDoesNotProvideInventoryAllocation();
	
	Required2 = Undefined;
	IndexOf = -1;
	Boundary = -1;
	
	Dimension = New Structure("Products,Characteristic,Warehouse,Purpose");
	EmptyLinkKey = New UUID("00000000-0000-0000-0000-000000000000");
	ThereIsChainLooping = False;
	
	TableOfCacheKeysOfLotReferencesOfMovements = ResultIsCacheOfLotReferenceKeys.Unload();
	TableOfCacheKeysOfLotReferencesOfMovements.Indexes.Add("Products, Characteristic, Warehouse, ProductionOrder, ConnectionKeyTransfer");
	SearchForPartyKeys = New Structure("Products, Characteristic, Warehouse, ProductionOrder, ConnectionKeyTransfer");
	ResultOfDistributionIsNotToProvide = AllocationResult.CopyColumns();

	Selection = ResultIsRequired.Select();

	ThereAreRecordsInSelection = Selection.Next();
	
	While ThereAreRecordsInSelection Do
		
		SearchForPartyKeys.ProductionOrder = Selection.ProductionOrder;
		SearchForPartyKeys.ConnectionKeyTransfer = Selection.KeyProducts;
		SearchForWarehouses.SupplyScheme = Selection.SupplyScheme;
		SearchForWarehouses.DestinationWarehouse = Selection.Warehouse;
		SearchForWarehouses.ProductionOrder = Selection.ProductionOrder;
		
		ReFillWarehouseData = Not (SearchForWarehouses.SupplyScheme = WarehouseSearchComparison.SupplyScheme
			And SearchForWarehouses.DestinationWarehouse = WarehouseSearchComparison.DestinationWarehouse
			And SearchForWarehouses.ProductionOrder = WarehouseSearchComparison.ProductionOrder);
		WarehouseIndex = 1;
		
		If ReFillWarehouseData Then
			
			ThereIsChainLooping = False;
			DurationOfTransferAmount = 0;
			ChainOfWarehouses.Clear();
			ArrayOfWarehousesCheckingLooping.Clear();
			ArrayOfWarehousesCheckingLooping.Add(Selection.Warehouse);
			
			NewChainLine = ChainOfWarehouses.Add();
			NewChainLine.SourceWarehouse = Selection.Warehouse;
			NewChainLine.SequenceNumber = WarehouseIndex;
		
		EndIf;
		
		While ReFillWarehouseData Do
		
			FoundWarehouses = WarehouseTable.FindRows(SearchForWarehouses);
			WarehouseAdded = False;
		
			For Each RowOfWarehouseTable In FoundWarehouses Do
				
				If ArrayOfWarehousesCheckingLooping.Find(RowOfWarehouseTable.DestinationWarehouse) = Undefined
				   And ValueIsFilled(RowOfWarehouseTable.DestinationWarehouse)
				   And TypeOf(RowOfWarehouseTable.DestinationWarehouse) = Type("CatalogRef.Warehouses") Then
					ArrayOfWarehousesCheckingLooping.Add(RowOfWarehouseTable.DestinationWarehouse);
					WarehouseAdded = True;
				EndIf;
				
				If ArrayOfWarehousesCheckingLooping.Find(RowOfWarehouseTable.SourceWarehouse) = Undefined
				   And ValueIsFilled(RowOfWarehouseTable.SourceWarehouse)
				   And TypeOf(RowOfWarehouseTable.SourceWarehouse) = Type("CatalogRef.Warehouses") Then
					ArrayOfWarehousesCheckingLooping.Add(RowOfWarehouseTable.SourceWarehouse);
					WarehouseAdded = True;
				EndIf;
				
				SearchForWarehouses.DestinationWarehouse = RowOfWarehouseTable.SourceWarehouse;
				
				If WarehouseAdded Then
					
					WarehouseIndex = WarehouseIndex + 1;
					
					NewChainLine = ChainOfWarehouses.Add();
					FillPropertyValues(NewChainLine, RowOfWarehouseTable);
					TransferDurationDays = ?(RowOfWarehouseTable.TransferDurationDays > 0, RowOfWarehouseTable.TransferDurationDays, 0.0001);
					DurationOfTransferAmount = DurationOfTransferAmount + TransferDurationDays;
					NewChainLine.TransferDurationDays = DurationOfTransferAmount;
					NewChainLine.SequenceNumber = WarehouseIndex;
					
				EndIf;
				
			EndDo;
			
			If FoundWarehouses.Count() = 0 Then
				Break;
			EndIf;
			
			If Not WarehouseAdded And ValueIsFilled(SearchForWarehouses.DestinationWarehouse) And TypeOf(SearchForWarehouses.DestinationWarehouse) = Type("CatalogRef.Warehouses") Then
				ThereIsChainLooping = True;
				Break;
			EndIf;
		
		EndDo;
		
		WarehouseSearchComparison.SupplyScheme = Selection.SupplyScheme;
		WarehouseSearchComparison.DestinationWarehouse = Selection.Warehouse;
		WarehouseSearchComparison.ProductionOrder = Selection.ProductionOrder;
				
		WarehouseNeeds = ArrayOfWarehousesCheckingLooping[ArrayOfWarehousesCheckingLooping.UBound()];
		
		ReplacedEverything = 0;
		Required2Balance = Selection.Required2;
		FillPropertyValues(Dimension, Selection);
		
		If ThereAreAnalogues Then
			
			FillPropertyValues(SearchForPermissions, Dimension);
			SearchForPermissions.PriorityAnalogue = True;
			SearchForPermissions.Ref = Selection.RowIndex;
			
			AvailablePriorityPermissions = PermissionsTable.FindRows(SearchForPermissions);
			ThereArePriorityPermissions = AvailablePriorityPermissions.Count() > 0;
			
			SearchForPermissions.PriorityAnalogue = False;
			Available_Permissions = PermissionsTable.FindRows(SearchForPermissions);
			ThereAreUsualPermissions = Available_Permissions.Count() > 0;
		
		EndIf;
		
		KeyItemOfWarehouseNeeds = Undefined;
		KeyLotReferenceWarehouseNeeds = Undefined;
		ThereAreInventoryTransfer = False;
		
		For Each IterationOfDistribution In IterationsOfInventoryAllocation Do
			
			If Required2Balance = 0 Then
				Break;
			EndIf;
			
			If IterationOfDistribution = IterationDistributionOfPriorityAnalogues 
			 Or IterationOfDistribution = IterationDistributionOfConventionalAnalogues Then
			
				CollectionOfPermissions = ?(IterationOfDistribution = IterationDistributionOfPriorityAnalogues, AvailablePriorityPermissions, Available_Permissions);
				PermissionFlag = ?(IterationOfDistribution = IterationDistributionOfPriorityAnalogues, ThereArePriorityPermissions, ThereAreUsualPermissions);
			
				If ThereAreAnalogues And PermissionFlag Then
					
					For Each RowOfWarehouses In ChainOfWarehouses Do
						
						Warehouse = RowOfWarehouses.SourceWarehouse;
						
						If Required2Balance = 0 Then
							Break;
						EndIf;
						
						Dimension.Warehouse = Warehouse;
						WarehouseMatches = Warehouse = Selection.Warehouse;
						
						For Each StringResolution In CollectionOfPermissions Do
							
							DistributionCoefficient = ProductionClientServer.CoefficientByStandard(
								StringResolution.ControlMultiplier, Required2Balance, StringResolution.NumberOfPackages, StringResolution.PackageData);
							
							AnalogsOfResolution = StringResolution.Substitutes;
							
							For Each StringAnalog In AnalogsOfResolution Do
								
								StringAnalog.KeyItemAnalog = New UUID;
								
								FillPropertyValues(AnalogAnalytics, Dimension);
								FillPropertyValues(AnalogAnalytics, StringAnalog);
								
								ProductItemSchedule = ProductItemSchedule(ScheduleProducts, AnalogAnalytics, Boundary, IndexOf, Selection); // ValueTableRow
								
								ConditionProductSchedule = True;
								Balance = 0;
								While ConditionProductSchedule Do
									
									StringAnalog.GoodsCharts.Add(ProductItemSchedule);
									BorderBypass = Boundary;
									IndexTraversal = IndexOf;
									
									While BorderBypass > IndexTraversal Do
										
										Inventory = Schedule[IndexTraversal];
										
										If ValueIsFilled(Inventory.ReceiptOrder) 
										   And IterationOfDistribution = IterationDistributionOfConventionalAnalogues Then
										
											IndexTraversal = IndexTraversal + 1;
											Continue;
										
										EndIf;
										
										Balance = Balance + Inventory.Available;
										IndexTraversal = IndexTraversal + 1;
										
									EndDo;
									
									ConditionProductSchedule = FollowingProductSchedule(ProductItemSchedule, AnalogAnalytics, Boundary, IndexOf, Selection);
								
								EndDo;
								
								ZoomRatio = ProductionClientServer.CoefficientByStandard(
									StringResolution.ControlMultiplier, Balance, StringAnalog.NumberOfPackages, StringAnalog.PackageData);
									
								DistributionCoefficient = Min(DistributionCoefficient, ZoomRatio);
								
							EndDo;
							
							If DistributionCoefficient > 0 Then
								
								ReplacedByLine = EstimatedNumberOfItems(StringResolution.NumberOfPackages, DistributionCoefficient, StringResolution.PackageData);
								Required2Balance = Required2Balance - ReplacedByLine;
								ReplacedEverything = ReplacedEverything + ReplacedByLine;
								
								CoefficientQuantityPerUnitOfLaunchLotReference = ProductionClientServer.CoefficientByStandard(
									StringResolution.ControlMultiplier, Selection.QuantityForLaunchLotUnit, StringResolution.NumberOfPackages, StringAnalog.PackageData);
								
								For Each StringAnalog In AnalogsOfResolution Do
									
									RemainsToAllocate = EstimatedNumberOfItems(StringAnalog.NumberOfPackages, DistributionCoefficient, StringAnalog.PackageData);
									QuantityForLaunchLotUnit = EstimatedNumberOfItems(StringAnalog.NumberOfPackages, CoefficientQuantityPerUnitOfLaunchLotReference, StringAnalog.PackageData);
									
									RowOfDisplacementCalculationTable = DisplacementCalculationTable.Add();
									RowOfDisplacementCalculationTable.PermissionToReplace = StringResolution.Resolution;
									RowOfDisplacementCalculationTable.RowIndex = Selection.RowIndex;
									RowOfDisplacementCalculationTable.SequenceNumber = RowOfWarehouses.SequenceNumber;
									RowOfDisplacementCalculationTable.QuantityForLaunchLotUnit = QuantityForLaunchLotUnit;
									FillPropertyValues(RowOfDisplacementCalculationTable, StringAnalog, "Products, Characteristic");
									FillPropertyValues(RowOfDisplacementCalculationTable, Selection, "KeyProducts, KeyLot, Warehouse, ProductionOrder");
									ThereAreInventoryTransfer = True;
									
									KeyFromCache = New UUID;
									FillPropertyValues(SearchForPartyKeys, StringAnalog, "Products, Characteristic");
									SearchForPartyKeys.Warehouse = Warehouse;
									For Each CacheTableRow In TableOfCacheKeysOfLotReferencesOfMovements.FindRows(SearchForPartyKeys) Do
										
										StringAnalog.KeyItemAnalog = CacheTableRow.KeyProducts;
										KeyFromCache = CacheTableRow.KeyLot;
										Break;
									
									EndDo;
									
									KeyLot = ?(WarehouseMatches, Selection.KeyLot, KeyFromCache);
									
									For Each ProductItemSchedule In StringAnalog.GoodsCharts Do // ValueTableRow
										
										If ProductItemSchedule = Undefined Then
											Continue;
										EndIf;
										
										IndexOf = ProductItemSchedule.IndexOf; // Number
										Boundary = ProductItemSchedule.Boundary; // Number
										
										While RemainsToAllocate > 0 And Boundary > IndexOf Do
										
											Inventory = Schedule[IndexOf];
											If ValueIsFilled(Inventory.ReceiptOrder) 
											   And IterationOfDistribution = IterationDistributionOfConventionalAnalogues Then
											
												IndexOf = IndexOf + 1;
												Continue;
											
											EndIf;
									
											Allocated = Min(RemainsToAllocate, Inventory.Available);
											
											If Allocated > 0 Then
											
												Demand = AllocationResult.Add();
												FillPropertyValues(Demand, Selection, "RowIndex");
												FillPropertyValues(Demand, Inventory, "Products,Characteristic,DateOfReceipt,ReceiptOrder,Purpose,Warehouse");
												Demand.Allocated = Allocated;
												Demand.PermissionToReplace = StringResolution.Resolution;
												Demand.TransferDurationDays = RowOfWarehouses.TransferDurationDays;
												Demand.QuantityForLaunchLotUnit = QuantityForLaunchLotUnit;
												
												Demand.KeyProducts = StringAnalog.KeyItemAnalog;
												Demand.KeyLot = KeyLot;
												Demand.KeyItemNeeds = Selection.KeyProducts;
												
											Else
												
												ProductItemSchedule.GraphIsDischarged = ProductItemSchedule.GraphIsDischarged Or Inventory.Available > 0;
												
												If ThereIsScheduleAvailable = Undefined And Inventory.Available > 0 Then
													ThereIsScheduleAvailable = ProductItemSchedule;
												EndIf;
												
												If Not ProductItemSchedule.GraphIsDischarged Then
													Break;
												Else
													IndexOf = IndexOf + 1;
													Continue;
												EndIf;	
											
											EndIf;
											
											Inventory.Available = Inventory.Available - Allocated;
											RemainsToAllocate = RemainsToAllocate - Allocated;
											
											If Inventory.Available > 0 Then
												Continue;
											Else
												If IndexOf = ProductItemSchedule.IndexOf Then
													ProductItemSchedule.IndexOf = ProductItemSchedule.IndexOf + 1;
													ProductItemSchedule.GraphIsDischarged = False;
												EndIf;
											EndIf;
											
											IndexOf = IndexOf + 1;	
										
										EndDo;
										
									EndDo;
									
									StringAnalog.GoodsCharts.Clear();
									StringAnalog.KeyItemAnalog = EmptyLinkKey;
									
								EndDo;
								
							EndIf;
							
						EndDo;	
						
					EndDo;	
				
				EndIf;
				
			Else // Distribution of materials
				
				FillPropertyValues(SearchForPresenceOfBalances, Selection, "Products, Characteristic");
				
				For Each RowOfWarehouses In ChainOfWarehouses Do
					
					If Required2Balance = 0 Then
						Break;
					EndIf;
					
					Warehouse = RowOfWarehouses.SourceWarehouse;
					
					SearchForPresenceOfBalances.Warehouse = Warehouse;
					ThereAreLines = PresenceOfBalances.FindRows(SearchForPresenceOfBalances).Count() > 0;
					
					If Not ThereAreLines Then
						Continue;
					EndIf;
					
					WarehouseMatches = Warehouse = Selection.Warehouse;
					
					Dimension.Warehouse = Warehouse;
					
					KeyFromCache = New UUID;
					KeyItemMaterial = New UUID;
					FillPropertyValues(SearchForPartyKeys, Selection, "Products, Characteristic");
					SearchForPartyKeys.Warehouse = Warehouse;
					For Each CacheTableRow In TableOfCacheKeysOfLotReferencesOfMovements.FindRows(SearchForPartyKeys) Do
						
						KeyItemMaterial = CacheTableRow.KeyProducts;
						KeyFromCache = CacheTableRow.KeyLot;
						Break;
					
					EndDo;
					KeyLot = ?(WarehouseMatches, Selection.KeyLot, KeyFromCache);
					
					ProductItemSchedule = ProductItemSchedule(ScheduleProducts, Dimension, Boundary, IndexOf, Selection); // ValueTableRow
					KeyItemMaterial = ?(WarehouseMatches, Selection.KeyProducts, KeyItemMaterial);
					
					If Warehouse = WarehouseNeeds Then
								
						KeyItemOfWarehouseNeeds = KeyItemMaterial;
						KeyLotReferenceWarehouseNeeds = KeyLot;
					
					EndIf;
					
					While ThereAreRecordsInSelection
						And Dimension.Products   = Selection.Products
						And Dimension.Characteristic = Selection.Characteristic
						And Dimension.Warehouse          = Warehouse
						And Dimension.Purpose     = Selection.Purpose Do
						
						Required2 = ?(Not Required2 = Undefined, Required2, Required2Balance);
						
						While Required2 > 0 And Boundary > IndexOf Do
							
							Inventory = Schedule[IndexOf];
							
							If StockIsAvailable(Selection, Inventory) Then
								
								Allocated = Min(Required2, Inventory.Available);

								Demand = AllocationResult.Add();
								FillPropertyValues(Demand, Selection, "RowIndex");
								FillPropertyValues(Demand, Inventory, "Products, Characteristic,DateOfReceipt,ReceiptOrder,Purpose,Warehouse");
								Demand.Allocated = Allocated;
								
								Demand.KeyProducts = KeyItemMaterial;
								Demand.KeyLot = KeyLot;
								Demand.TransferDurationDays = RowOfWarehouses.TransferDurationDays;
								Demand.KeyItemNeeds = Selection.KeyProducts;
								
								If Not WarehouseMatches Then
											
									RowOfDisplacementCalculationTable = DisplacementCalculationTable.Add();
									RowOfDisplacementCalculationTable.PermissionToReplace = Documents.EngineeringChangeOrder.EmptyRef();
									RowOfDisplacementCalculationTable.RowIndex = Selection.RowIndex;
									RowOfDisplacementCalculationTable.SequenceNumber = RowOfWarehouses.SequenceNumber;
									FillPropertyValues(RowOfDisplacementCalculationTable, Selection, "Products, Characteristic, KeyProducts, KeyLot, Warehouse, ProductionOrder");
									ThereAreInventoryTransfer = True;
								
								EndIf;
								
							Else
								
								ProductItemSchedule.GraphIsDischarged = ProductItemSchedule.GraphIsDischarged Or Inventory.Available > 0;
								
								If ThereIsScheduleAvailable = Undefined And Inventory.Available > 0 Then
									ThereIsScheduleAvailable = ProductItemSchedule;
								EndIf;
								
								If Not ProductItemSchedule.GraphIsDischarged Then
									Break;
								Else
									IndexOf = IndexOf + 1;
									Continue;
								EndIf;
								
							EndIf;
							
							Inventory.Available = Inventory.Available - Allocated;
							Required2 = Required2 - Allocated;
							Required2Balance = Required2Balance - Allocated;
							
							If Inventory.Available > 0 Then
								Continue;
							Else
								If IndexOf = ProductItemSchedule.IndexOf Then
									ProductItemSchedule.IndexOf = ProductItemSchedule.IndexOf + 1;
									ProductItemSchedule.GraphIsDischarged = False;
								EndIf;
							EndIf;
							
							IndexOf = IndexOf + 1;
							
						EndDo;
						
						If Required2 > 0 And FollowingProductSchedule(ProductItemSchedule, Dimension, Boundary, IndexOf, Selection) Then
							Continue;
						EndIf;
						
						If ThereIsScheduleAvailable <> Undefined Then
							ProductItemSchedule = ThereIsScheduleAvailable;
							IndexOf  = ProductItemSchedule.IndexOf;
							Boundary = ProductItemSchedule.Boundary;
						EndIf;
						
						ThereIsScheduleAvailable = Undefined;
						Required2 = Undefined;
						
						Break;
						
					EndDo;
					
				EndDo;	
			
			EndIf;	
		
		EndDo;
		
		// Fixing the remaining need for material
		
		If Required2Balance > 0 Then
			
			Demand = AllocationResult.Add();
			FillPropertyValues(Demand, Selection);
			Demand.EntryType = RecordTypeInventoryAllocationClosingNeeds;
			Demand.Warehouse = WarehouseNeeds;
			Demand.Allocated = Required2Balance;
			Demand.KeyItemNeeds = Selection.KeyProducts;
			
			KeyFromCache = New UUID;
			KeyItemNeed = New UUID;
			FillPropertyValues(SearchForPartyKeys, Demand, "Products, Characteristic, Warehouse");
			For Each CacheTableRow In TableOfCacheKeysOfLotReferencesOfMovements.FindRows(SearchForPartyKeys) Do
				
				KeyItemNeed = CacheTableRow.KeyProducts;
				KeyFromCache = CacheTableRow.KeyLot;
				Break;
			
			EndDo;
			
			Demand.KeyProducts = ?(KeyItemOfWarehouseNeeds <> Undefined, KeyItemOfWarehouseNeeds, KeyItemNeed);
			Demand.KeyLot = ?(KeyLotReferenceWarehouseNeeds <> Undefined, KeyLotReferenceWarehouseNeeds, KeyFromCache);
			Demand.TransferDurationDays = DurationOfTransferAmount;
			
			If Not Selection.WithAssignment Then
				Demand.Purpose = Catalogs.Assignments.EmptyRef();
			EndIf;
			
			WarehouseMatches = WarehouseNeeds = Selection.Warehouse;
			
			If Not WarehouseMatches Then
									
				RowOfDisplacementCalculationTable = DisplacementCalculationTable.Add();
				RowOfDisplacementCalculationTable.PermissionToReplace = Documents.EngineeringChangeOrder.EmptyRef();
				RowOfDisplacementCalculationTable.RowIndex = Selection.RowIndex;
				RowOfDisplacementCalculationTable.SequenceNumber = ArrayOfWarehousesCheckingLooping.Count();
				FillPropertyValues(RowOfDisplacementCalculationTable, Selection, "Products, Characteristic, KeyProducts, KeyLot, Warehouse, ProductionOrder");
				ThereAreInventoryTransfer = True;
			
			EndIf;
			
			If ThereIsChainLooping Then
				
				Demand = ResultOfDistributionIsNotToProvide.Add(); // Recording Moving
				FillPropertyValues(Demand, Selection);
				Demand.EntryType = RecordTypeInventoryAllocationRelocationRequired;
				Demand.Warehouse = WarehouseNeeds;
				Demand.Allocated = Required2Balance;
								
				KeyLotReferenceMovingLooping = New UUID;
				
				Demand.KeyProducts = ?(KeyItemOfWarehouseNeeds <> Undefined, KeyItemOfWarehouseNeeds, New UUID);
				Demand.KeyLot = KeyLotReferenceMovingLooping;
				Demand.TransferDurationDays = DurationOfTransferAmount;
				
				If Not Selection.WithAssignment Then
					Demand.Purpose = Catalogs.Assignments.EmptyRef();
				EndIf;
				
				Demand = ResultOfDistributionIsNotToProvide.Add(); // Record Consumption - Do not provide
				FillPropertyValues(Demand, Selection);
				Demand.EntryType = TypeOfRecordDoesNotProvideInventoryAllocation;
				Demand.Warehouse = Selection.Warehouse;
				Demand.Allocated = Required2Balance;
				
				Demand.KeyProducts = New UUID;
				Demand.KeyLot = KeyLotReferenceMovingLooping;
				Demand.TransferDurationDays = DurationOfTransferAmount;
				
				If Not Selection.WithAssignment Then
					Demand.Purpose = Catalogs.Assignments.EmptyRef();
				EndIf;
			
			EndIf;
			
		EndIf;
		
		// Reflection of the replaced quantity
		
		If ReplacedEverything > 0 Then
		
			Demand = AllocationResult.Add();
			FillPropertyValues(Demand, Selection);
			Demand.Allocated = ReplacedEverything;
			
			Demand.EntryType = RecordTypeInventoryAllocationReplacement;
			Demand.KeyItemNeeds = Selection.KeyProducts;
			
		EndIf;
		
		If ThereAreInventoryTransfer Then
		
			MatchingWarehouseChains.Insert(Selection.RowIndex, ChainOfWarehouses.Copy());
		
		EndIf;
			
		ThereAreRecordsInSelection = Selection.Next();
		
	EndDo;
	
	// Formation of records on the movement of materials and analogues
	
	ConnectionsOfAnalogues = AllocationResult.CopyColumns("RowIndex, Products, Characteristic, Warehouse, PermissionToReplace, KeyProducts");
		
	If DisplacementCalculationTable.Count() > 0 Then
		
		QueryText = 
		"SELECT
		|	Table.RowIndex AS RowIndex,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.PermissionToReplace AS PermissionToReplace,
		|	Table.KeyProducts AS KeyProducts,
		|	Table.KeyLot AS KeyLot,
		|	Table.Warehouse AS Warehouse,
		|	Table.ProductionOrder AS ProductionOrder,
		|	Table.QuantityForLaunchLotUnit AS QuantityForLaunchLotUnit,
		|	Table.SequenceNumber AS SequenceNumber
		|INTO DisplacementCalculationTable
		|FROM
		|	&DisplacementCalculationTable AS Table
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.RowIndex AS RowIndex,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.PermissionToReplace AS PermissionToReplace,
		|	Table.KeyProducts AS KeyProducts,
		|	Table.KeyLot AS KeyLot,
		|	Table.Warehouse AS Warehouse,
		|	Table.ProductionOrder AS ProductionOrder,
		|	Table.QuantityForLaunchLotUnit AS QuantityForLaunchLotUnit,
		|	MAX(Table.SequenceNumber) AS SequenceNumber
		|FROM
		|	DisplacementCalculationTable AS Table
		|
		|GROUP BY
		|	Table.RowIndex,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.PermissionToReplace,
		|	Table.KeyProducts,
		|	Table.KeyLot,
		|	Table.Warehouse,
		|	Table.ProductionOrder,
		|	Table.QuantityForLaunchLotUnit";
		
		Query = New Query(QueryText);
		Query.SetParameter("DisplacementCalculationTable", DisplacementCalculationTable);
		TableOfMovements = Query.Execute().Unload();
		
		SearchDistributionResult = AllocationResult.Copy();
		SearchDistributionResult.Indexes.Add("Products, Characteristic, Warehouse, PermissionToReplace, RowIndex");
		ProductsSearch = New Structure("Products, Characteristic, Warehouse, PermissionToReplace, RowIndex");
		
		For Each TableRow In TableOfMovements Do
			
			DistributedTotal = 0;
			AnalogDistribution = ValueIsFilled(TableRow.PermissionToReplace);
			ChainOfWarehouses = MatchingWarehouseChains.Get(TableRow.RowIndex);
			
			NeedRecipient = Undefined;
			FillPropertyValues(ProductsSearch, TableRow, "Products, Characteristic, PermissionToReplace, RowIndex");
			
			IndexOfWarehouse = TableRow.SequenceNumber - 1;
			
			While IndexOfWarehouse > 0 Do
			
				RowOfWarehouses = ChainOfWarehouses[IndexOfWarehouse];
				IndexOfWarehouse = IndexOfWarehouse - 1;
				ProductsSearch.Warehouse = RowOfWarehouses.SourceWarehouse;
				
				TableByNomenclature = SearchDistributionResult.FindRows(ProductsSearch);
				
				If TableByNomenclature.Count() > 0 Then
				
					For Each SpecificationRow In TableByNomenclature Do
						DistributedTotal = DistributedTotal + SpecificationRow.Allocated;
						KeyProducts = SpecificationRow.KeyProducts;
						KeyLot = SpecificationRow.KeyLot;
					EndDo;
					
				Else
					
					KeyProducts = New UUID;
					KeyLot = New UUID;
					
					FillPropertyValues(SearchForPartyKeys, TableRow, "Products, Characteristic, Warehouse, ProductionOrder");
					SearchForPartyKeys.ConnectionKeyTransfer = TableRow.KeyProducts;
				
				EndIf;
				
				If NeedRecipient <> Undefined Then
					NeedRecipient.KeyProducts = KeyProducts;
					NeedRecipient.TransferDurationDays = RowOfWarehouses.TransferDurationDays;
				EndIf;
				
				If DistributedTotal > 0 Then
				
					NeedSender = AllocationResult.Add();
					FillPropertyValues(NeedSender, TableRow);
					NeedSender.Warehouse = RowOfWarehouses.SourceWarehouse;
					NeedSender.TransferDurationDays = RowOfWarehouses.TransferDurationDays;
					NeedSender.Allocated = DistributedTotal;
					NeedSender.EntryType = RecordTypeInventoryAllocationConsumptionRequired;
					NeedSender.KeyProducts = KeyProducts;
					NeedSender.KeyLot = KeyLot;
					NeedSender.KeyItemNeeds = TableRow.KeyProducts;
					
					NeedRecipient = AllocationResult.Add();
					FillPropertyValues(NeedRecipient, TableRow);
					NeedRecipient.Warehouse = RowOfWarehouses.DestinationWarehouse;
					NeedRecipient.Allocated = DistributedTotal;
					NeedRecipient.EntryType = RecordTypeInventoryAllocationRelocationRequired;
					NeedRecipient.KeyLot = KeyLot;
					NeedRecipient.KeyItemNeeds = TableRow.KeyProducts;
					
				EndIf;
			
			EndDo;
				
			If NeedRecipient <> Undefined Then
				NeedRecipient.KeyProducts = TableRow.KeyProducts;
			EndIf;
			
			If AnalogDistribution Then
				
				ProductsSearch.Warehouse = TableRow.Warehouse;
				TableByNomenclature = SearchDistributionResult.FindRows(ProductsSearch);
				KeyIsSetOfAnalogNeeds = New UUID;
				
				If TableByNomenclature.Count() > 0 Then
				
					For Each SpecificationRow In TableByNomenclature Do
						DistributedTotal = DistributedTotal + SpecificationRow.Allocated;
						KeyProducts = SpecificationRow.KeyProducts;
						KeyLot = SpecificationRow.KeyLot;
					EndDo;
					
					FillPropertyValues(SearchForPartyKeys, TableRow, "Products, Characteristic, Warehouse, ProductionOrder");
					SearchForPartyKeys.ConnectionKeyTransfer = TableRow.KeyProducts;
					
					For Each CacheTableRow In TableOfCacheKeysOfLotReferencesOfMovements.FindRows(SearchForPartyKeys) Do
						
						KeyIsSetOfAnalogNeeds = CacheTableRow.KeySet; 
						Break;
					
					EndDo;
					
				Else
					
					KeyProducts = New UUID;
					KeyLot = TableRow.KeyLot;
					
					FillPropertyValues(SearchForPartyKeys, TableRow, "Products, Characteristic, Warehouse, ProductionOrder");
					SearchForPartyKeys.ConnectionKeyTransfer = TableRow.KeyProducts;
					
					For Each CacheTableRow In TableOfCacheKeysOfLotReferencesOfMovements.FindRows(SearchForPartyKeys) Do
						
						KeyIsSetOfAnalogNeeds = CacheTableRow.KeySet; 
						KeyProducts = CacheTableRow.KeyProducts;
						Break;
					
					EndDo;
				
				EndIf;
				
				If DistributedTotal > 0 Then
				
					If NeedRecipient <> Undefined Then
						NeedRecipient.KeyProducts = KeyProducts;
					EndIf;
				
					NeedSender = AllocationResult.Add();
					FillPropertyValues(NeedSender, TableRow);
					NeedSender.Warehouse = TableRow.Warehouse;
					NeedSender.Allocated = DistributedTotal;
					NeedSender.EntryType = RecordTypeInventoryAllocationConsumptionRequired;
					NeedSender.KeyProducts = KeyProducts;
					NeedSender.CommunicationKeyIsAnalog = KeyProducts;
					NeedSender.KeyLot = KeyLot;
					NeedSender.KeySet = KeyIsSetOfAnalogNeeds;
					NeedSender.KeyItemNeeds = TableRow.KeyProducts;
					
					LinkFillingString = ConnectionsOfAnalogues.Add();
					FillPropertyValues(LinkFillingString, NeedSender);
				
				EndIf;
				
			EndIf;
				
		EndDo;
	
	EndIf;
	
	// Generating records for looping needs
	For Each ResultString1 In ResultOfDistributionIsNotToProvide Do
	
		NewRow = AllocationResult.Add();
		FillPropertyValues(NewRow, ResultString1);
	
	EndDo;
	
	AllocationResult.Indexes.Add("RowIndex, Products, Characteristic, PermissionToReplace");
	SearchForAnalogues = New Structure("RowIndex, Products, Characteristic, PermissionToReplace");
	
	// Filling in the keycommunication field for analog strings
	For Each LinkFillingString In ConnectionsOfAnalogues Do
	
		FillPropertyValues(SearchForAnalogues, LinkFillingString);
		DistributionLines = AllocationResult.FindRows(SearchForAnalogues);
		
		For Each ResultRow In DistributionLines Do
			
			If ValueIsFilled(ResultRow.KeySet) Then
				Continue;
			EndIf;
			
			ResultRow.ConnectionKeyTransfer = LinkFillingString.KeyProducts;
			ResultRow.CommunicationKeyIsAnalog = LinkFillingString.KeyProducts;
		
		EndDo;
	
	EndDo;
	
EndProcedure

Function RecordTypeInventoryAllocationReserve()

	Return 0;

EndFunction

Function RecordTypeInventoryAllocationRelocationRequired()

	Return 1;

EndFunction

Function RecordTypeInventoryAllocationConsumptionRequired()

	Return 2;

EndFunction 

Function RecordTypeInventoryAllocationClosingNeeds()

	Return 3;

EndFunction 

Function RecordTypeInventoryAllocationReplacement()

	Return 4;

EndFunction

Function TypeOfRecordDoesNotProvideInventoryAllocation()

	Return 5;

EndFunction

Function EstimatedNumberOfItems(NormativeStandard, ConversionFactor_, PackageData)

	EstimatedQuantity = NormativeStandard * ConversionFactor_
		* PackageData.Numerator / PackageData.Denominator;
			
	CurrentCount = Int(EstimatedQuantity);
	If EstimatedQuantity > CurrentCount Then
		CurrentCount = CurrentCount + Int((EstimatedQuantity - CurrentCount) * 1000) / 1000;
	EndIf;
	
	Return EstimatedQuantity;

EndFunction

Function ProductItemSchedule(Schedule, Dimension, Boundary, IndexOf, CalculationConditions, ChangeAnalytics = False)
	
	Purpose = Dimension.Purpose;
	
	If ChangeAnalytics Then
		Dimension.Purpose = Catalogs.Assignments.EmptyRef();
	EndIf;
	
	List = Schedule.FindRows(Dimension);
	
	ThereIsNoSchedule = List.Count() = 0;
	
	If ThereIsNoSchedule
		And Not ChangeAnalytics And Not CalculationConditions.WithAssignment Then
		
		ProductItemSchedule = ProductItemSchedule(Schedule, Dimension, Boundary, IndexOf, CalculationConditions, True);
		
	Else
		
		If ThereIsNoSchedule Then
			ProductItemSchedule  = Undefined;
			IndexOf  = -1;
			Boundary = -1;
		Else
			ProductItemSchedule = List[0];
			IndexOf  = ProductItemSchedule.IndexOf;
			Boundary = ProductItemSchedule.Boundary;
		EndIf;
		
	EndIf;
	
	If ChangeAnalytics Then
		Dimension.Purpose = Purpose;
	EndIf;
	
	Return ProductItemSchedule;
	
EndFunction

Function FollowingProductSchedule(ProductItemSchedule, Dimension, Boundary, IndexOf, CalculationConditions)
	
	If ProductItemSchedule = Undefined Or CalculationConditions.WithAssignment Then
		Return False;
	EndIf;
	
	If ProductItemSchedule.Purpose.IsEmpty() Then
		ProductItemSchedule  = Undefined;
		IndexOf  = -1;
		Boundary = -1;
		Return False;
	EndIf;
	
	ProductItemSchedule = ProductItemSchedule(ProductItemSchedule.Owner(), Dimension, Boundary, IndexOf, CalculationConditions, True);
	
	Return (ProductItemSchedule <> Undefined);
	
EndFunction

Function StockIsAvailable(Selection, Inventory)
	
	Return Selection.QueueNumber > Inventory.QueueNumber
		Or (Selection.QueueNumber = Inventory.QueueNumber
			And Selection.OrderOfRegulatorySchedule >= Inventory.OrderOfRegulatorySchedule
			And Selection.LoopLimitControl = 0);
	
EndFunction

Procedure PlaceInventoryAllocationResultInTemporaryTableManager(TempTablesManager, AllocationResult, CalculateChanges_)

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	Query.SetParameter("BlankID", CommonClientServer.BlankUUID());
	Query.SetParameter("TypeOfRecordClosingNeeds", RecordTypeInventoryAllocationClosingNeeds());
	Query.SetParameter("TypeOfRecordNeedsToBeMoved", RecordTypeInventoryAllocationRelocationRequired());
	Query.SetParameter("RecordTypeConsumptionRequired", RecordTypeInventoryAllocationConsumptionRequired());
	Query.SetParameter("RecordTypeReserve", RecordTypeInventoryAllocationReserve());
	Query.SetParameter("RecordTypeReplacement", RecordTypeInventoryAllocationReplacement());
	Query.SetParameter("TypeOfRecordDoesNotProvideInventoryAllocation", TypeOfRecordDoesNotProvideInventoryAllocation());
	Query.SetParameter("CalculateChanges_", CalculateChanges_);
	Query.Text = ""
		+ QueryTextPutTableOfValuesInTemporaryTable("AllocationResult", AllocationResult.Columns,,, "RowIndex")
		+ Common.QueryBatchSeparator()
		+ "SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.ProductionOrder AS ProductionOrder,
		|	Table.ConnectionKeyTransfer AS ConnectionKeyTransfer,
		|	Table.ThisIsOutput_ AS ThisIsOutput_,
		|	MAX(Table.Stage) AS Stage,
		|	MAX(Table.RowIndex) AS RowIndex,
		|	SUM(Table.ToSupply) AS ToSupply,
		|	SUM(Table.Scheduled) AS Scheduled,
		|	SUM(Table.Ordered) AS Ordered,
		|	SUM(Table.DistributedFromStockAvailabilityTo) AS DistributedFromStockAvailabilityTo,
		|	SUM(Table.DistributedFromStockAvailabilityAfter) AS DistributedFromStockAvailabilityAfter,
		|	SUM(Table.QuantityToProduction) AS QuantityToProduction,
		|	SUM(Table.ToSupplyDifference) AS ToSupplyDifference,
		|	SUM(Table.PlannedDifference) AS PlannedDifference,
		|	SUM(Table.ReplacedDifference) AS ReplacedDifference
		|INTO CalculatingChanges
		|FROM
		|	(SELECT
		|		Plan.RowIndex AS RowIndex,
		|		Plan.Products AS Products,
		|		Plan.Characteristic AS Characteristic,
		|		Plan.Warehouse AS Warehouse,
		|		Plan.Purpose AS Purpose,
		|		Plan.ProductionOrder AS ProductionOrder,
		|		Plan.Stage AS Stage,
		|		CASE
		|			WHEN Plan.InitialDemand
		|			THEN Plan.KeyProducts
		|			ELSE Plan.ConnectionKeyTransfer
		|		END AS ConnectionKeyTransfer,
		|		Plan.ThisIsOutput_ AS ThisIsOutput_,
		|		Plan.ToSupply AS ToSupply,
		|		Plan.Replaced AS Replaced,
		|		Plan.DistributedFromStockAvailability AS DistributedFromStockAvailabilityTo,
		|		0 AS DistributedFromStockAvailabilityAfter,
		|		Plan.Scheduled AS QuantityToProduction,
		|		Plan.Scheduled AS Scheduled,
		|		Plan.Ordered AS Ordered,
		|		CASE
		|			WHEN Plan.InitialDemand
		|			THEN 0
		|			ELSE Plan.ToSupply
		|		END AS ToSupplyDifference,
		|		Plan.PlannedToMove AS PlannedDifference,
		|		Plan.Replaced AS ReplacedDifference
		|	FROM
		|		ItemPlan AS Plan
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		-1 AS RowIndex,
		|		Reserves.Products AS Products,
		|		Reserves.Characteristic AS Characteristic,
		|		Reserves.Warehouse AS Warehouse,
		|		Plan.Purpose AS Purpose,
		|		Plan.ProductionOrder AS ProductionOrder,
		|		Plan.Stage AS Stage,
		|		CASE
		|			WHEN Reserves.CommunicationKeyIsAnalog <> &BlankID // For analog strings, the field is filled in when calculating collateral
		|			THEN Reserves.CommunicationKeyIsAnalog
		|			ELSE Plan.KeyProducts
		|		END                         AS ConnectionKeyTransfer,
		|		Plan.ThisIsOutput_ AS ThisIsOutput_,
		|		0 AS ToSupply,
		|		CASE
		|			WHEN Reserves.EntryType = &RecordTypeReplacement
		|			THEN -Reserves.Allocated
		|			ELSE 0
		|		END AS Replaced,
		|		0 AS DistributedFromStockAvailabilityTo,
		|		CASE
		|			WHEN Reserves.ReceiptOrder = UNDEFINED
		|				AND Reserves.EntryType = &RecordTypeReserve
		|				THEN Reserves.Allocated
		|			ELSE 0
		|		END AS DistributedFromStockAvailabilityAfter,
		|		CASE
		|			WHEN Reserves.EntryType IN (&TypeOfRecordClosingNeeds, &TypeOfRecordNeedsToBeMoved)
		|			THEN -Reserves.Allocated
		|			ELSE 0
		|		END AS QuantityToProduction,
		|		0 AS Scheduled,
		|		0 AS Ordered,
		|		CASE
		|			WHEN Reserves.EntryType = &RecordTypeConsumptionRequired
		|			THEN -Reserves.Allocated
		|			ELSE 0
		|		END AS ToSupplyDifference,
		|		CASE
		|			WHEN Reserves.EntryType = &TypeOfRecordNeedsToBeMoved
		|			THEN -Reserves.Allocated
		|			ELSE 0
		|		END AS PlannedDifference,
		|		CASE
		|			WHEN Reserves.EntryType = &RecordTypeReplacement
		|			THEN -Reserves.Allocated
		|			ELSE 0
		|		END AS ReplacedDifference
		|	FROM
		|		AllocationResult AS Reserves
		|			LEFT JOIN ItemPlan AS Plan
		|			ON Reserves.RowIndex = Plan.RowIndex) AS Table
		|
		|GROUP BY
		|	Table.Purpose,
		|	Table.ProductionOrder,
		|	Table.Warehouse,
		|	Table.Characteristic,
		|	Table.ConnectionKeyTransfer,
		|	Table.Products,
		|	Table.ThisIsOutput_
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	ProductionOrder
		|;
		|SELECT
		|	CalculatingChanges.Products AS Products,
		|	CalculatingChanges.Characteristic AS Characteristic,
		|	CalculatingChanges.ProductionOrder AS ProductionOrder,
		|	CalculatingChanges.ConnectionKeyTransfer AS ConnectionKeyTransfer,
		|	CalculatingChanges.ToSupplyDifference <> 0
		|		OR CalculatingChanges.PlannedDifference <> 0
		|		OR CalculatingChanges.ReplacedDifference <> 0 AS HasChanges
		|INTO ChangesTable
		|FROM
		|	CalculatingChanges AS CalculatingChanges
		|
		|
		|UNION ALL
		|
		|SELECT
		|	Plan.Products,
		|	Plan.Characteristic,
		|	Plan.ProductionOrder,
		|	Plan.NeedCommunicationKey,
		|	TRUE
		|FROM
		|	ItemPlan AS Plan
		|WHERE 
		|	Plan.ThisIsASubstitute AND Plan.ConnectionKeyTransfer = &BlankID AND Plan.NeedCommunicationKey <> &BlankID
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	ProductionOrder,
		|	ConnectionKeyTransfer,
		|	HasChanges
		|;
		|
		|
		|SELECT
		|
		|	Plan.RowIndex AS RowIndex,
		|
		|	Reserves.Products          AS Products,
		|	Reserves.Characteristic        AS Characteristic,
		|	Reserves.Warehouse                 AS Warehouse,
		|	Plan.Purpose               AS Purpose,
		|	Plan.ProductionOrder      AS ProductionOrder,
		|	Reserves.KeyProducts      AS KeyProducts,
		|	Reserves.KeyLot            AS KeyLot,
		|	CASE
		|		WHEN Reserves.EntryType IN (&RecordTypeReplacement, &RecordTypeReserve, &RecordTypeConsumptionRequired)
		|			AND Plan.Warehouse = Reserves.Warehouse
		|			THEN Plan.Stage
		|	END                         AS Stage,
		|	Plan.Department            AS Department,
		|	Plan.StructureAssignment      AS StructureAssignment,
		|	CASE
		|		WHEN Reserves.ConnectionKeyTransfer <> &BlankID // For analog strings, the field is filled in when calculating collateral
		|		THEN Reserves.ConnectionKeyTransfer
		|		ELSE Plan.KeyProducts
		|	END                         AS ConnectionKeyTransfer,
		|	CASE
		|		WHEN Reserves.KeySet <> &BlankID // The primary need for an analog string
		|		THEN &BlankID
		|		WHEN Reserves.EntryType IN (&RecordTypeConsumptionRequired, &TypeOfRecordNeedsToBeMoved)
		|		THEN Reserves.KeyLot
		|		ELSE &BlankID
		|	END                         AS KeySet,
		|	Reserves.KeySet AS KeyIsSetOfAnalogNeeds,
		|
		|	Reserves.DateOfReceipt    AS DateOfReceipt,
		|	Reserves.ReceiptOrder AS ReceiptOrder,
		|
		|	Reserves.EntryType             AS EntryType,
		|	CASE
		|		WHEN Reserves.EntryType IN (&RecordTypeReserve, &RecordTypeReplacement)
		|		THEN &BlankID
		|		ELSE Plan.KeyProducts
		|	END                         AS CommunicationKeyBillOfMaterialsRow,
		|
		|	ISNULL(LocationOfLaunchedLotAndStagesInOrderStructure.Level, Plan.Level) AS Level,
		|	ISNULL(LocationOfLaunchedLotAndStagesInOrderStructure.DurationBeforeProductionIssue, Plan.DurationBeforeProductionIssue) + Reserves.TransferDurationDays AS DurationBeforeProductionIssue, // we take the batch without taking into account the stage
		|	ISNULL(LocationOfLaunchedLotAndStagesInOrderStructure.ProductionLotIDInProductGroup, Plan.ProductionLotIDInProductGroup) AS ProductionLotIDInProductGroup,
		|	CASE
		|		WHEN LocationOfLaunchedLotAndStagesInOrderStructure.Lot IS NOT NULL THEN
		|			ReleaseStage.Ref
		|		ELSE
		|			NULL
		|	END AS ReleaseStage,
		|	UUID(ReleaseStage.ProductionLot) AS ReleasePartyKey,
		|	CASE
		|		WHEN LocationOfLaunchedLotAndStagesInOrderStructure.Lot IS NOT NULL THEN
		|			ReleaseStage.Department
		|		ELSE
		|			NULL
		|	END AS ReleaseDepartment,
		|
		|	Reserves.PermissionToReplace AS PermissionToReplace,
		|	CASE
		|		WHEN Reserves.EntryType = &RecordTypeConsumptionRequired
		|			AND Reserves.PermissionToReplace <> VALUE(Document.EngineeringChangeOrder.EmptyRef)
		|			AND Reserves.Warehouse = Plan.Warehouse
		|			THEN Reserves.QuantityForLaunchLotUnit
		|		ELSE 0
		|	END AS QuantityForLaunchLotUnit,
		|	CASE
		|		WHEN Reserves.EntryType = &RecordTypeConsumptionRequired
		|			AND Reserves.PermissionToReplace <> VALUE(Document.EngineeringChangeOrder.EmptyRef)
		|			AND Reserves.Warehouse = Plan.Warehouse
		|			THEN Plan.BillOfMaterials
		|		ELSE VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|	END AS BillOfMaterials,
		|
		|	CASE
		|		WHEN Reserves.EntryType = &RecordTypeReplacement
		|			THEN Reserves.Allocated
		|		ELSE 0
		|	END AS Replaced,
		|	CASE
		|		WHEN Reserves.EntryType = &TypeOfRecordNeedsToBeMoved
		|		AND TRUE IN
		|			(SELECT
		|				TRUE
		|			FROM
		|				ChangesTable AS ChangesTable
		|			WHERE
		|				ChangesTable.Products = Reserves.Products
		|				AND ChangesTable.Characteristic = Reserves.Characteristic
		|				AND ChangesTable.ProductionOrder = Plan.ProductionOrder
		|				AND (ChangesTable.ConnectionKeyTransfer = Plan.KeyProducts 
		|					OR ChangesTable.ConnectionKeyTransfer = Reserves.KeyProducts 
		|					OR ChangesTable.ConnectionKeyTransfer = Reserves.ConnectionKeyTransfer)
		|				AND ChangesTable.HasChanges)
		|			THEN Reserves.Allocated
		|		ELSE 0
		|	END AS Scheduled,
		|	CASE
		|		WHEN Reserves.EntryType = &RecordTypeConsumptionRequired
		|			AND TRUE IN
		|			(SELECT
		|				TRUE
		|			FROM
		|				ChangesTable AS ChangesTable
		|			WHERE
		|				ChangesTable.Products = Reserves.Products
		|				AND ChangesTable.Characteristic = Reserves.Characteristic
		|				AND ChangesTable.ProductionOrder = Plan.ProductionOrder
		|				AND (ChangesTable.ConnectionKeyTransfer = Plan.KeyProducts 
		|					OR ChangesTable.ConnectionKeyTransfer = Reserves.KeyProducts 
		|					OR ChangesTable.ConnectionKeyTransfer = Reserves.ConnectionKeyTransfer)
		|				AND ChangesTable.HasChanges)
		|			THEN Reserves.Allocated
		|		ELSE 0
		|	END AS Required2,
		|	CASE
		|		WHEN Reserves.EntryType = &TypeOfRecordDoesNotProvideInventoryAllocation
		|			THEN Reserves.Allocated
		|		ELSE 0
		|	END AS NotProvide,
		|
		|	CASE
		|		WHEN LocationOfLaunchedLotAndStagesInOrderStructure.Lot IS NOT NULL
		|				AND Reserves.EntryType = &RecordTypeReserve
		|				AND Reserves.Purpose <> &EmptyAssignment
		|			THEN Reserves.Allocated
		|		ELSE 0
		|	END AS AllocatedInAssignedProductionLots,
		|	CASE
		|		WHEN LocationOfLaunchedLotAndStagesInOrderStructure.Lot IS NOT NULL
		|				AND Reserves.EntryType = &RecordTypeReserve
		|			AND Reserves.Purpose = &EmptyAssignment 
		|			THEN Reserves.Allocated
		|		ELSE 0
		|	END AS AllocatedInFreeProductionLots,
		|	CASE
		|		WHEN LocationOfLaunchedLotAndStagesInOrderStructure.Lot IS NULL
		|				AND Reserves.EntryType = &RecordTypeReserve
		|				AND Reserves.Purpose <> &EmptyAssignment
		|			THEN Reserves.Allocated
		|		ELSE 0
		|	END AS AllocatedFromAvailableInventoryWithAssignment,
		|	CASE
		|		WHEN LocationOfLaunchedLotAndStagesInOrderStructure.Lot IS NULL
		|				AND Reserves.EntryType = &RecordTypeReserve
		|				AND Reserves.Purpose = &EmptyAssignment
		|			THEN Reserves.Allocated
		|		ELSE 0
		|	END AS AllocatedFromAvailableInventory
		|
		|INTO InventoryAllocation
		|FROM
		|	AllocationResult AS Reserves
		|
		|		LEFT JOIN ItemPlan AS Plan
		|		ON Reserves.RowIndex = Plan.RowIndex
		|
		|		LEFT JOIN Document.ProductionStage2_2 AS ReleaseStage
		|		ON Reserves.ReceiptOrder = ReleaseStage.Ref
		|			AND Plan.ProductionOrder = ReleaseStage.ReferenceOrder // release by order
		|			AND Plan.KeyLot <> UUID(ReleaseStage.ProductionLot) // we exclude intermediate semi-finished products
		|
		|		LEFT JOIN InformationRegister.LocationOfLaunchedLotAndStagesInOrderStructure AS LocationOfLaunchedLotAndStagesInOrderStructure
		|		ON ReleaseStage.ProductionLot = LocationOfLaunchedLotAndStagesInOrderStructure.Lot
		|
		|WHERE 
		|	Reserves.EntryType <> &TypeOfRecordClosingNeeds
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	ProductionOrder
		|;
		|
		|DROP AllocationResult
		|;
		|";
		
	Query.SetParameter("AllocationResult", AllocationResult);
	Query.Execute();
	
EndProcedure

Procedure CalculateChangesAndRecordResultOfInventoryAllocation(TempTablesManager, CalculationParameters)
	
	CalculateChanges_ = CalculationParameters.CalculateChanges_;
	EmptyLinkKey = New UUID("00000000-0000-0000-0000-000000000000");
	RecordSeparator = ?(CalculateChanges_, New UUID, New UUID("00000000-0000-0000-0000-000000000000"));
	TheProductionScheduleIsUsed = ProductionManagement.TheProductionScheduleIsUsed();
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CalculateChanges_", CalculateChanges_);
	Query.SetParameter("RecordSeparator", RecordSeparator);
	Query.SetParameter("ReplacementRecordSeparator", New UUID);
	Query.SetParameter("EmptyLinkKey", EmptyLinkKey);
	Query.SetParameter("TypeOfRecordNeedsToBeMoved", RecordTypeInventoryAllocationRelocationRequired());
	Query.SetParameter("RecordTypeConsumptionRequired", RecordTypeInventoryAllocationConsumptionRequired());
	Query.SetParameter("TypeOfRecordDoesNotProvide", TypeOfRecordDoesNotProvideInventoryAllocation());
	Query.SetParameter("RecordTypeReplacement", RecordTypeInventoryAllocationReplacement());
	Query.SetParameter("TheProductionScheduleIsUsed", TheProductionScheduleIsUsed);
	Query.Text =
	"SELECT
	|	Table.Products           AS Products,
	|	Table.Characteristic         AS Characteristic,
	|	Table.Warehouse                  AS Warehouse,
	|	Table.Purpose             AS Purpose,
	|	Table.ProductionOrder    AS ProductionOrder,
	|	Table.KeyProducts       AS KeyProducts,
	|	Table.KeyLot             AS KeyLot,
	|	Table.LineKind              AS LineKind,
	|	Table.ReceiptOrder     AS ReceiptOrder,
	|	Table.DateOfReceipt        AS DateOfReceipt,
	|	Table.PermissionToReplace     AS PermissionToReplace,
	|	MAX(Table.KeySet)    AS KeySet,
	|	MAX(Table.KeySetSource) AS KeySetSource,
	|	MAX(Table.KeyIsSetOfAnalogNeeds) AS KeyIsSetOfAnalogNeeds,
	|	MAX(Table.BillOfMaterials) AS BillOfMaterials,
	|	MAX(Table.Stage) AS Stage,
	|	MAX(Table.Department) AS Department,
	|	MAX(Table.StructureAssignment) AS StructureAssignment,
	|	MAX(Table.CommunicationKeyBillOfMaterialsRow)  AS CommunicationKeyBillOfMaterialsRow,
	|	MAX(Table.ConnectionKeyTransfer) AS ConnectionKeyTransfer,
	|	MAX(Table.Level) AS Level,
	|	MAX(Table.DurationBeforeProductionIssue) AS DurationBeforeProductionIssue,
	|	MAX(Table.ProductionLotIDInProductGroup) AS ProductionLotIDInProductGroup,
	|	MAX(Table.QuantityForLaunchLotUnit) AS QuantityForLaunchLotUnit,
	|	SUM(Table.Replaced) AS Replaced,
	|	SUM(Table.NotProvide) AS NotProvide,
	|	SUM(Table.Required2) AS Required2,
	|	SUM(Table.Scheduled) AS Scheduled,
	|	SUM(Table.AllocatedFromAvailableInventoryWithAssignment) AS AllocatedFromAvailableInventoryWithAssignment,
	|	SUM(Table.AllocatedFromAvailableInventory) AS AllocatedFromAvailableInventory,
	|	SUM(Table.AllocatedInAssignedProductionLots)  AS AllocatedInAssignedProductionLots,
	|	SUM(Table.AllocatedInFreeProductionLots) AS AllocatedInFreeProductionLots,
	|	MIN(Table.NewRecord) AS NewRecord,
	|	GROUPEDBY(Table.KeyProducts) AS DetailRecord
	|	
	|INTO ReservesChanges
	|FROM (
	|	
	|	SELECT
	|
	|		CASE
	|			WHEN Reserves.EntryType = &TypeOfRecordNeedsToBeMoved
	|			THEN VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
	|			WHEN Reserves.EntryType IN (&RecordTypeConsumptionRequired, &RecordTypeReplacement, &TypeOfRecordDoesNotProvide)
	|			THEN VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|			ELSE VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
	|		END AS LineKind,
	|
	|		Reserves.Products          AS Products,
	|		Reserves.Characteristic        AS Characteristic,
	|		Reserves.Warehouse                 AS Warehouse,
	|		Reserves.Purpose            AS Purpose,
	|		Reserves.ProductionOrder   AS ProductionOrder,
	|		Reserves.KeyProducts      AS KeyProducts,
	|		Reserves.KeyLot            AS KeyLot,
	|		Reserves.Stage                  AS Stage,
	|		Reserves.Department         AS Department,
	|		Reserves.StructureAssignment   AS StructureAssignment,
	|		Reserves.ConnectionKeyTransfer  AS ConnectionKeyTransfer,
	|		Reserves.Level               AS Level,
	|		Reserves.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
	|		Reserves.ProductionLotIDInProductGroup AS ProductionLotIDInProductGroup,
	|		Reserves.ReceiptOrder    AS ReceiptOrder,
	|		Reserves.DateOfReceipt       AS DateOfReceipt,
	|		Reserves.PermissionToReplace    AS PermissionToReplace,
	|		Reserves.BillOfMaterials          AS BillOfMaterials,
	|
	|		&EmptyLinkKey              AS KeySet,
	|		Reserves.KeySet             AS KeySetSource,
	|		Reserves.KeyIsSetOfAnalogNeeds      AS KeyIsSetOfAnalogNeeds,
	|		Reserves.CommunicationKeyBillOfMaterialsRow      AS CommunicationKeyBillOfMaterialsRow,
	|
	|		Reserves.Required2                        AS Required2,
	|		Reserves.Scheduled                    AS Scheduled,
	|		Reserves.AllocatedFromAvailableInventoryWithAssignment AS AllocatedFromAvailableInventoryWithAssignment,
	|		Reserves.AllocatedFromAvailableInventory            AS AllocatedFromAvailableInventory,
	|		0                                        AS AllocatedInAssignedProductionLots,
	|		0                                        AS AllocatedInFreeProductionLots,
	|		Reserves.Replaced                         AS Replaced,
	|		Reserves.NotProvide                   AS NotProvide,
	|		Reserves.QuantityForLaunchLotUnit AS QuantityForLaunchLotUnit,
	|
	|		TRUE AS NewRecord
	|
	|	FROM
	|		InventoryAllocation AS Reserves
	|
	|	WHERE
	|		Reserves.AllocatedFromAvailableInventory > 0 OR Reserves.AllocatedFromAvailableInventoryWithAssignment > 0 OR Reserves.Scheduled > 0 
	|		OR Reserves.Required2 > 0 OR Reserves.Replaced > 0 OR Reserves.NotProvide > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|
	|		CASE
	|			WHEN Reserves.EntryType = &TypeOfRecordNeedsToBeMoved
	|			THEN VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
	|			WHEN Reserves.EntryType IN (&RecordTypeConsumptionRequired, &RecordTypeReplacement)
	|			THEN VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|			ELSE VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct)
	|		END AS LineKind,
	|
	|		Reserves.Products          AS Products,
	|		Reserves.Characteristic        AS Characteristic,
	|		Reserves.Warehouse                 AS Warehouse,
	|		Reserves.Purpose            AS Purpose,
	|		Reserves.ProductionOrder   AS ProductionOrder,
	|		Reserves.KeyProducts      AS KeyProducts,
	|		Reserves.ReleasePartyKey     AS KeyLot,
	|		Reserves.ReleaseStage           AS Stage,
	|		Reserves.ReleaseDepartment  AS Department,
	|		Reserves.StructureAssignment   AS StructureAssignment,
	|		&EmptyLinkKey              AS ConnectionKeyTransfer,
	|		Reserves.Level               AS Level,
	|		Reserves.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
	|		Reserves.ProductionLotIDInProductGroup AS ProductionLotIDInProductGroup,
	|		Reserves.ReceiptOrder    AS ReceiptOrder,
	|		Reserves.DateOfReceipt       AS DateOfReceipt,
	|		Reserves.PermissionToReplace    AS PermissionToReplace,
	|		Reserves.BillOfMaterials          AS BillOfMaterials,
	|
	|		&EmptyLinkKey              AS KeySet,
	|		Reserves.KeySet             AS KeySetSource,
	|		Reserves.KeyIsSetOfAnalogNeeds      AS KeyIsSetOfAnalogNeeds,
	|		Reserves.CommunicationKeyBillOfMaterialsRow      AS CommunicationKeyBillOfMaterialsRow,
	|		
	|		Reserves.Required2                        AS Required2,
	|		Reserves.Scheduled                    AS Scheduled,
	|
	|
	|		0                                        AS AllocatedFromAvailableInventoryWithAssignment,
	|		0                                        AS AllocatedFromAvailableInventory,
	|		Reserves.AllocatedInAssignedProductionLots  AS AllocatedInAssignedProductionLots,
	|		Reserves.AllocatedInFreeProductionLots             AS AllocatedInFreeProductionLots,
	|		Reserves.Replaced                         AS Replaced,
	|		Reserves.NotProvide                   AS NotProvide,
	|		Reserves.QuantityForLaunchLotUnit AS QuantityForLaunchLotUnit,
	|
	|		TRUE AS NewRecord
	|
	|	FROM
	|		InventoryAllocation AS Reserves
	|	
	|	WHERE
	|		Reserves.AllocatedInFreeProductionLots > 0 OR Reserves.AllocatedInAssignedProductionLots > 0 
	|
	|	UNION ALL
	|	
	|	SELECT
	|
	|		Reserves.LineKind AS LineKind,
	|	
	|		Reserves.Products          AS Products,
	|		Reserves.Characteristic        AS Characteristic,
	|		Reserves.Warehouse                 AS Warehouse,
	|		Reserves.Purpose            AS Purpose,
	|		Reserves.ProductionOrder   AS ProductionOrder,
	|		Reserves.KeyProducts      AS KeyProducts,
	|		Reserves.KeyLot            AS KeyLot,
	|		Reserves.Stage                  AS Stage,
	|		Reserves.Department         AS Department,
	|		Reserves.StructureAssignment   AS StructureAssignment,
	|		Reserves.ConnectionKeyTransfer  AS ConnectionKeyTransfer,
	|		Reserves.Level               AS Level,
	|		Reserves.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
	|		Reserves.ProductionLotIDInProductGroup AS ProductionLotIDInProductGroup,
	|		Reserves.ReceiptOrder    AS ReceiptOrder,
	|		Reserves.DateOfReceipt       AS DateOfReceipt,
	|		Reserves.PermissionToReplace    AS PermissionToReplace,
	|		Reserves.BillOfMaterials          AS BillOfMaterials,
	|		
	|		CASE
	|		WHEN (Reserves.LineKind IN (VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved),
	|								VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct)))
	|				OR (Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption) AND (Reserves.Replaced <> 0 OR Reserves.NotProvide <> 0))
	|		THEN Reserves.KeySet
	|		ELSE &EmptyLinkKey
	|		END AS KeySet,
	|		Reserves.KeySet             AS KeySetSource,
	|		CASE
	|			WHEN &CalculateChanges_ 
	|				AND Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|				AND Reserves.PermissionToReplace <> VALUE(Document.EngineeringChangeOrder.EmptyRef)
	|				AND Reserves.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|				THEN Reserves.KeySet
	|			ELSE &EmptyLinkKey
	|		END AS KeyIsSetOfAnalogNeeds,
	|		Reserves.CommunicationKeyBillOfMaterialsRow AS CommunicationKeyBillOfMaterialsRow,
	|
	|		CASE
	|			WHEN &CalculateChanges_ 
	|				AND Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|				AND Reserves.ConnectionKeyTransfer <> &EmptyLinkKey
	|				THEN -Reserves.ToSupply
	|			ELSE 0
	|		END AS Required2,
	|		CASE
	|			WHEN &CalculateChanges_
	|				AND Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
	|				THEN -Reserves.Scheduled
	|			ELSE 0
	|		END AS Scheduled,
	|		CASE
	|			WHEN &CalculateChanges_
	|				THEN -Reserves.AllocatedFromAvailableInventoryWithAssignment
	|			ELSE 0
	|		END AS AllocatedFromAvailableInventoryWithAssignment,
	|		CASE
	|			WHEN &CalculateChanges_
	|				THEN -Reserves.AllocatedFromAvailableInventory
	|			ELSE 0
	|		END AS AllocatedFromAvailableInventory,
	|		CASE
	|			WHEN &CalculateChanges_
	|				THEN -Reserves.AllocatedInAssignedProductionLots
	|			ELSE 0
	|		END AS AllocatedInAssignedProductionLots,
	|		CASE
	|			WHEN &CalculateChanges_
	|				THEN -Reserves.AllocatedInFreeProductionLots
	|			ELSE 0
	|		END AS AllocatedInFreeProductionLots,
	|		CASE
	|			WHEN &CalculateChanges_
	|				THEN -Reserves.Replaced
	|			ELSE 0
	|		END AS Replaced,
	|		CASE
	|			WHEN &CalculateChanges_
	|				AND Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|				AND Reserves.ConnectionKeyTransfer <> &EmptyLinkKey
	|				THEN -Reserves.NotProvide
	|			ELSE 0
	|		END AS NotProvide,
	|		0     AS QuantityForLaunchLotUnit,
	|
	|		FALSE AS NewRecord
	|	
	|	FROM
	|		InformationRegister.OrderStructure AS Reserves
	|	
	|	WHERE
	|		TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				ItemPlan AS ItemPlan
	|			WHERE
	|				ItemPlan.Products = Reserves.Products
	|				AND ItemPlan.Characteristic = Reserves.Characteristic
	|				AND ItemPlan.Warehouse = Reserves.Warehouse
	|				AND ItemPlan.Purpose = Reserves.Purpose)
	|		AND (TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				ChangesTable AS ChangesTable
	|			WHERE
	|				ChangesTable.Products = Reserves.Products
	|				AND ChangesTable.Characteristic = Reserves.Characteristic
	|				AND ChangesTable.ProductionOrder = Reserves.ProductionOrder
	|				AND (ChangesTable.ConnectionKeyTransfer = Reserves.KeyProducts OR ChangesTable.ConnectionKeyTransfer = Reserves.ConnectionKeyTransfer)
	|				AND ChangesTable.HasChanges
	|				AND Reserves.LineKind IN (
	|					VALUE(Enum.KindsOfProductionOrderStructureLines.Move),
	|					VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)))
	|			
	|			OR Reserves.LineKind IN (
	|					VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved),
	|					VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
	|			OR (Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption) AND (Reserves.Replaced <> 0 OR Reserves.NotProvide <> 0)))
	|
	|		AND (Reserves.AllocatedFromAvailableInventory <> 0
	|					OR Reserves.AllocatedFromAvailableInventoryWithAssignment <> 0
	|					OR Reserves.AllocatedInFreeProductionLots <> 0 
	|					OR Reserves.AllocatedInAssignedProductionLots <> 0
	|					OR (Reserves.ToSupply <> 0 AND Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|							AND Reserves.ConnectionKeyTransfer <> &EmptyLinkKey)
	|					OR (Reserves.Scheduled <> 0 AND Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move))
	|					OR Reserves.Replaced <> 0
	|					OR (Reserves.NotProvide <> 0 AND Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|							AND Reserves.ConnectionKeyTransfer <> &EmptyLinkKey))
	|
	|) AS Table
	|
	|GROUP BY GROUPING SETS (
	|
	|	(Table.Products,
	|	 Table.Characteristic,
	|	 Table.Warehouse,
	|	 Table.Purpose),
	|	(Table.Products,
	|	 Table.Characteristic,
	|	 Table.Warehouse,
	|	 Table.Purpose,
	|	 Table.ProductionOrder,
	|	 Table.KeyProducts,
	|	 Table.KeyLot,
	|	 Table.LineKind,
	|	 Table.ReceiptOrder,
	|	 Table.DateOfReceipt,
	|	 Table.PermissionToReplace))
	|
	|HAVING
	|	(NOT &CalculateChanges_
	|			OR SUM(Table.AllocatedFromAvailableInventory) <> 0
	|			OR SUM(Table.AllocatedFromAvailableInventoryWithAssignment) <> 0
	|			OR SUM(Table.AllocatedInFreeProductionLots) <> 0 
	|			OR SUM(Table.AllocatedInAssignedProductionLots) <> 0
	|			OR SUM(Table.Required2) <> 0
	|			OR SUM(Table.Scheduled) <> 0
	|			OR SUM(Table.Replaced) <> 0
	|			OR SUM(Table.NotProvide) <> 0
	|			OR NOT GROUPEDBY(Table.ProductionOrder))
	|
	|INDEX BY SETS
	|(
	|	(Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	DetailRecord),
	|	(Products,
	|	Characteristic,
	|	KeySet,
	|	NewRecord),
	|	(ProductionOrder,
	|	LineKind,
	|	NewRecord)
	|)";
	
	Query.Execute();
	
	Query.Text =
	"SELECT
	|	Portions.Products        AS Products,
	|	Portions.Characteristic      AS Characteristic,
	|	Portions.Warehouse               AS Warehouse,
	|	Portions.Purpose          AS Purpose,
	|	Portions.KeySet           AS KeySet
	|FROM
	|	ReservesChanges AS Portions
	|WHERE
	|	NOT Portions.DetailRecord
	|;";
	RecordingPortions = Query.Execute().Unload();
	
	If RecordingPortions.Count() = 0 Then
		Return;
	EndIf;
	
	FoundRows = RecordingPortions.FindRows(New Structure("KeySet", EmptyLinkKey));
	For Each FoundRow In FoundRows Do
		FoundRow.KeySet = New UUID();
	EndDo;
	
	PutTableOfValuesInTemporaryTable(TempTablesManager, "RecordingPortions", RecordingPortions,,, "Products,Characteristic,Warehouse,Purpose");
	
	Query.Text =
	"SELECT DISTINCT
	|	Table.KeySet AS KeySet
	|FROM
	|	(SELECT
	|		RecordingPortions.KeySet AS KeySet
	|	FROM
	|		RecordingPortions AS RecordingPortions
	|	WHERE
	|		NOT &CalculateChanges_
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReservesChanges.KeySetSource AS KeySet
	|	FROM
	|		ReservesChanges AS ReservesChanges
	|	WHERE
	|		NOT &CalculateChanges_
	|	UNION ALL
	|	
	|	SELECT
	|		ReservesChanges.KeyIsSetOfAnalogNeeds AS KeySet
	|	FROM
	|		ReservesChanges AS ReservesChanges
	|	WHERE
	|		NOT &CalculateChanges_
	|) AS Table
	|;
	|SELECT // writing set keys to the cache
	|
	|	RelatedMaterialAnalogues.Products AS Products,
	|	RelatedMaterialAnalogues.Characteristic AS Characteristic,
	|	RelatedMaterialAnalogues.Id AS Id,
	|	TRUE AS NewRecord
	|
	|FROM
	|	RelatedMaterialAnalogues AS RelatedMaterialAnalogues
	|WHERE 
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				AllGoods AS Goods
	|			WHERE
	|				Goods.Products = RelatedMaterialAnalogues.Products
	|				AND Goods.Characteristic = RelatedMaterialAnalogues.Characteristic)
	|
	|	AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.CacheOfItemLinkIDsByChangeOrders AS Table
	|			WHERE
	|				Table.Products = RelatedMaterialAnalogues.Products
	|				AND Table.Characteristic = RelatedMaterialAnalogues.Characteristic
	|				AND Table.Id = RelatedMaterialAnalogues.Id)
	|
	|UNION ALL
	|
	|SELECT 
	|
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Id AS Id,
	|	FALSE AS NewRecord
	|
	|FROM
	|	InformationRegister.CacheOfItemLinkIDsByChangeOrders AS Table
	|WHERE 
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				AllGoods AS Goods
	|			WHERE
	|				Goods.Products = Table.Products
	|				AND Goods.Characteristic = Table.Characteristic)
	|
	|	AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				RelatedMaterialAnalogues AS RelatedMaterialAnalogues
	|			WHERE
	|				RelatedMaterialAnalogues.Products = Table.Products
	|				AND RelatedMaterialAnalogues.Characteristic = Table.Characteristic
	|				AND RelatedMaterialAnalogues.Id = Table.Id)
	|;
	|SELECT DISTINCT // registration of tasks for the calculation of the schedule for new parties
	|
	|	Reserves.ProductionOrder AS ProductionOrder,
	|	Reserves.KeyLot AS KeyLot
	|
	|FROM
	|	ReservesChanges AS Reserves
	|
	|WHERE
	|	&TheProductionScheduleIsUsed
	|	AND TRUE NOT IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.ScheduleOfProductionStages2_2 AS Table
	|			WHERE
	|				Table.ProductionOrder = Reserves.ProductionOrder
	|				AND Table.ScheduleStatus = 0)
	|	AND Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
	|	AND Reserves.NewRecord
	|;
	|
	|SELECT DISTINCT // tasks for calculating the state of the provision of stages
	|
	|	Plan.Stage AS Stage
	|
	|FROM
	|	CalculatingChanges AS Plan
	|
	|WHERE
	|	Plan.Stage REFS Document.ProductionStage2_2
	|		AND Plan.DistributedFromStockAvailabilityTo <> Plan.DistributedFromStockAvailabilityAfter
	|		AND (Plan.ToSupply > Plan.DistributedFromStockAvailabilityAfter
	|				AND Plan.ToSupply <= Plan.DistributedFromStockAvailabilityTo
	|			OR Plan.ToSupply > Plan.DistributedFromStockAvailabilityTo
	|				AND Plan.ToSupply <= Plan.DistributedFromStockAvailabilityAfter)
	|;
	|SELECT
	|
	|	Reserves.Products          AS Products,
	|	Reserves.Characteristic        AS Characteristic,
	|	Reserves.Warehouse                 AS Warehouse,
	|	Reserves.Purpose            AS Purpose,
	|	Reserves.ProductionOrder   AS ProductionOrder,
	|	Reserves.KeyProducts      AS KeyProducts,
	|	Reserves.KeyLot            AS KeyLot,
	|	Reserves.LineKind             AS LineKind,
	|	Reserves.ReceiptOrder    AS ReceiptOrder,
	|	Reserves.DateOfReceipt       AS DateOfReceipt,
	|	Reserves.Stage                  AS Stage,
	|	Reserves.Department         AS Department,
	|	Reserves.StructureAssignment   AS StructureAssignment,
	|	Reserves.ConnectionKeyTransfer  AS ConnectionKeyTransfer,
	|	Reserves.CommunicationKeyBillOfMaterialsRow AS CommunicationKeyBillOfMaterialsRow,
	|	Reserves.Level               AS Level,
	|	Reserves.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
	|	Reserves.ProductionLotIDInProductGroup AS ProductionLotIDInProductGroup,
	|	Reserves.QuantityForLaunchLotUnit AS QuantityForLaunchLotUnit,
	|	Reserves.PermissionToReplace    AS PermissionToReplace,
	|	Reserves.BillOfMaterials          AS BillOfMaterials,
	|	
	|	CASE
	|		WHEN Reserves.KeyIsSetOfAnalogNeeds <> &EmptyLinkKey
	|		THEN Reserves.KeyIsSetOfAnalogNeeds
	|		WHEN (Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption) AND Reserves.Required2 <> 0
	|			OR Reserves.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move))
	|		THEN Reserves.KeyLot
	|		ELSE RecordingPortions.KeySet
	|	END AS KeySet,
	|
	|	Reserves.Required2                        AS ToSupply,
	|	Reserves.Scheduled                    AS Scheduled,
	|	Reserves.AllocatedFromAvailableInventoryWithAssignment AS AllocatedFromAvailableInventoryWithAssignment,
	|	Reserves.AllocatedFromAvailableInventory            AS AllocatedFromAvailableInventory,
	|	Reserves.AllocatedInAssignedProductionLots  AS AllocatedInAssignedProductionLots,
	|	Reserves.AllocatedInFreeProductionLots             AS AllocatedInFreeProductionLots,
	|	Reserves.Replaced                         AS Replaced,
	|	Reserves.NotProvide                   AS NotProvide,
	|
	|	CASE
	|		WHEN &CalculateChanges_ AND NOT Reserves.NewRecord THEN
	|			&RecordSeparator
	|		ELSE
	|			&EmptyLinkKey
	|	END AS Separator,
	|
	|	&CalculateChanges_ AND NOT Reserves.NewRecord AS AdditionalRecord
	|	
	|FROM
	|	
	|	ReservesChanges AS Reserves
	|
	|	INNER JOIN RecordingPortions AS RecordingPortions
	|	ON Reserves.Products   = RecordingPortions.Products
	|	 AND Reserves.Characteristic = RecordingPortions.Characteristic
	|	 AND Reserves.Warehouse          = RecordingPortions.Warehouse
	|	 AND Reserves.Purpose     = RecordingPortions.Purpose
	|	 AND Reserves.DetailRecord
	|
	|WHERE
	|	(&CalculateChanges_
	|			OR Reserves.Scheduled <> 0
	|			OR Reserves.Required2 <> 0
	|			OR Reserves.Replaced <> 0
	|			OR Reserves.NotProvide <> 0
	|			OR Reserves.AllocatedFromAvailableInventory <> 0
	|			OR Reserves.AllocatedFromAvailableInventoryWithAssignment <> 0
	|			OR Reserves.AllocatedInFreeProductionLots <> 0
	|			OR Reserves.AllocatedInAssignedProductionLots <> 0)
	|;";
	
	QueryResult = Query.ExecuteBatch();
	NumberOfPackages_ = QueryResult.Count();
	
	KeysSets = QueryResult[NumberOfPackages_-5].Unload();
	CacheOfCommunicationKeys = QueryResult[NumberOfPackages_-4].Unload();
	TasksForCalculatingSchedule = QueryResult[NumberOfPackages_-3].Unload();
	OtherStages = QueryResult[NumberOfPackages_-2].Unload().UnloadColumn(0);
	CalculationResult2 = QueryResult[NumberOfPackages_-1].Unload();
	
	ErrorCounter = 1;
	While True Do
		
		BeginTransaction();
		Try
		
#Region RecordingDistribution
			If CalculateChanges_ Then
				OrderStructure.FillInAndRecordSetOfRecords(InformationRegisters.OrderStructure.CreateRecordSet(), CalculationResult2);
			Else
				
				RecordSet = InformationRegisters.OrderStructure.CreateRecordSet();
				RecordingPortionStructure = New Structure("KeySet", EmptyLinkKey);
				CalculationResult2.Indexes.Add("KeySet");
				
				For Each TableRow In KeysSets Do
					
					If Not ValueIsFilled(TableRow.KeySet) Then
						Continue;
					EndIf;
					
					RecordingPortionStructure.KeySet = TableRow.KeySet;
				
					RecordSet.Filter.KeySet.Set(RecordingPortionStructure.KeySet);
					RecordSet.Load(CalculationResult2.Copy(RecordingPortionStructure));
					RecordSet.Write(True);
					RecordSet.Clear();	
					
				EndDo;
				
			EndIf;
#EndRegion

#Region WritingKeysToCache
		EntriesToDelete = CacheOfCommunicationKeys.Copy(New Structure("NewRecord", False));
		EntriesToAdd = CacheOfCommunicationKeys.Copy(New Structure("NewRecord", True));
		If EntriesToDelete.Count() > 0 Then
		
			Set = InformationRegisters.CacheOfItemLinkIDsByChangeOrders.CreateRecordSet();
			Set.Filter.Reset();
			Set.Load(EntriesToDelete);
			Set.Write(ReplacementMode.Delete);
		
		EndIf;
		
		If EntriesToAdd.Count() > 0 Then
		
			Set = InformationRegisters.CacheOfItemLinkIDsByChangeOrders.CreateRecordSet();
			Set.Filter.Reset();
			Set.Load(EntriesToAdd);
			Set.Write(ReplacementMode.Merge);
		
		EndIf;
#EndRegion

#Region WhenSoftwareChanges
			
			If Not TheProductionScheduleIsUsed Then
				InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddTasksFromTemporaryTableManager(TempTablesManager,
					"ReservesChanges",
					"ReservesChanges.ProductionOrder",
					"NULL",
					"ReservesChanges.KeyLot",
					"ReservesChanges.LineKind IN (VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct), 
					|	VALUE(Enum.KindsOfProductionOrderStructureLines.Move))");
			Else
				
				If TasksForCalculatingSchedule.Count() > 0 Then
					InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddTasks(TasksForCalculatingSchedule);
				EndIf;
				
				ProductionManagement.CheckTimingOfSupplyStagesOfDynamicStructure(TempTablesManager,
					"(&TextTableName.Products,
					|	&TextTableName.Characteristic,
					|	&TextTableName.Warehouse,
					|	&TextTableName.Purpose,
					|	&TextTableName.ProductionOrder,
					|	&TextTableName.KeyProducts,
					|	&TextTableName.KeyLot
					|) IN
					|(SELECT DISTINCT
					|	Reserves.Products          AS Products,
					|	Reserves.Characteristic        AS Characteristic,
					|	Reserves.Warehouse                 AS Warehouse,
					|	Reserves.Purpose            AS Purpose,
					|	Reserves.ProductionOrder   AS ProductionOrder,
					|	Reserves.KeyProducts      AS KeyProducts,
					|	Reserves.KeyLot            AS KeyLot
					|FROM
					|	ReservesChanges AS Reserves
					|WHERE
					|	Reserves.DetailRecord)");
			EndIf;
			
#EndRegion
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = DetailErrorDescription(ErrorInfo());
			
			If ErrorCounter < NumberOfWriteAttempts() Then
				RecordUnsuccessfulAttemptToWriteToLog(ErrorCounter, ErrorText);
				ErrorCounter = ErrorCounter + 1;
				Continue;
			EndIf;
			
			Raise ErrorText;
			
		EndTry;
		
		Break;
		
	EndDo;
	
	If OtherStages.Count() > 0 Then
		DocumentsStates.AddTasksToStateOfOrders(
			Undefined,
			OtherStages,
			"ACTION_REFRESH_SUPPLY_STATE",
			"ProductionStageStates");
	EndIf;

EndProcedure

Procedure GetAndCacheSupplyMethods(TempTablesManager, TempTableName = "ItemPlan", DeleteTT = False)
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("EmptySpecification", Catalogs.BillsOfMaterials.EmptyRef());
	Query.Text =
		"SELECT
		|   
		|	MAX(Plan.RowIndex) AS IndexOfLineOfNomenclaturePlan,
		|	Plan.Products AS Products,
		|	Plan.Characteristic AS Characteristic,
		|	Plan.Warehouse AS Warehouse,
		|	Plan.Purpose AS Purpose,
		|	Plan.ProductionOrder AS ProductionOrder,
		|
		|	MAX(Plan.ThisIsOutput_) AS ThisIsOutput_,
		|
		|	CASE
		|		WHEN COUNT(DISTINCT
		|				CASE
		|					WHEN Plan.SemiFinishedProductBOM <> &EmptySpecification
		|					THEN Plan.SemiFinishedProductBOM
		|				END) > 1
		|		THEN
		|			&EmptySpecification
		|		ELSE
		|			MAX(Plan.SemiFinishedProductBOM)
		|	END AS BillOfMaterials,
		|	CASE
		|		WHEN MAX(Plan.SemiFinishedProductBOM) <> &EmptySpecification THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS BOMIsPredefined,
		|	CASE
		|		WHEN MAX(NSICache.BillOfMaterials) <> MAX(Plan.SemiFinishedProductBOM)
		|			AND MAX(NSICache.Products IS NOT NULL) THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS Replace,
		|
		|	MAX(Plan.BillOfMaterials) AS ParentSpecification,
		|	MAX(Plan.CommunicationKeyBillOfMaterialsRow) AS LinkKeyIsBillOfMaterialsStringOfParent
		|
		|INTO ModifiedRows
		|
		|FROM
		|	ItemPlan AS Plan
		|	
		|	LEFT JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
		|	ON Plan.Products        = NSICache.Products
		|	 AND Plan.Characteristic      = NSICache.Characteristic
		|	 AND Plan.Warehouse               = NSICache.Warehouse
		|	 AND Plan.Purpose          = NSICache.Purpose
		|	 AND Plan.ProductionOrder = NSICache.ProductionOrder
		|
		|WHERE
		|	(Plan.Ordered + Plan.ToSupply) > 0
		|	 AND (NSICache.Products IS NULL
		|		OR NSICache.BOMIsPredefined
		|		OR Plan.SemiFinishedProductBOM <> &EmptySpecification)
		|
		|GROUP BY
		|	Plan.Products,
		|	Plan.Characteristic,
		|	Plan.Warehouse,
		|	Plan.Purpose,
		|	Plan.ProductionOrder
		|
		|HAVING
		|	MAX(NSICache.Products) IS NULL
		|	  OR CASE
		|			WHEN COUNT(DISTINCT
		|				CASE
		|					WHEN Plan.SemiFinishedProductBOM <> &EmptySpecification
		|					THEN Plan.SemiFinishedProductBOM
		|				END) > 1
		|			THEN &EmptySpecification ELSE MAX(Plan.SemiFinishedProductBOM)
		|		END <> MAX(NSICache.BillOfMaterials)
		|
		|INDEX BY
		|
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	ProductionOrder
		|;
		|";

	If TempTableName <> "ItemPlan" Then
		Query.Text = StrReplace(Query.Text, "ItemPlan", TempTableName);
	EndIf;
	
	QueryResult = Query.ExecuteBatch();
	
	If QueryResult[0].Unload()[0].Count = 0 Then
		Return;
	EndIf;
	
	Query.Text =
		"" + Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False) +
		"SELECT
		|
		|	RECORDAUTONUMBER() AS TheIndexOfTheData,
		|	Plan.IndexOfLineOfNomenclaturePlan AS IndexOfLineOfNomenclaturePlan,
		|
		|	Plan.Products AS Products,
		|	Plan.Characteristic AS Characteristic,
		|	Plan.Warehouse AS Warehouse,
		|	Plan.Purpose AS Purpose,
		|	Plan.ProductionOrder AS ProductionOrder,
		|
		|	Plan.Products.ProductKind AS ProductKind,
		|
		|	Plan.ProductionOrder.Department AS ProductionDispatcherBusinessUnit,
		|	Plan.ProductionOrder.LineOfBusiness AS LineOfBusiness,
		|	Plan.ProductionOrder.EarliestStartDate AS ProductionStart,
		|
		|	Plan.BillOfMaterials AS BillOfMaterials,
		|	Plan.BOMIsPredefined AS BOMIsPredefined,
		|	Plan.Replace AS Replace,
		|
		|	Plan.ProductionOrder.ProductionProcessType AS ProductionProcessType,
		|	Plan.ProductionOrder.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
		|		AND Plan.ThisIsOutput_ AS ThisIsProductBeingDisassembled,
		|
		|	ISNULL(WorksToPerform.UnderRepairProduct, VALUE(Catalog.Products.EmptyRef)) AS UnderRepairProduct,
		|	ISNULL(WorksToPerform.UnderRepairVariant, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS UnderRepairVariant,
		|
		|	CASE
		|		WHEN Plan.BOMIsPredefined
		|				OR Plan.ProductionOrder.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|					AND ISNULL(WorksToPerform.ProducedInProcess, FALSE) THEN
		|			VALUE(Enum.SupplyTypes.Production)
		|		ELSE
		|			ISNULL(ProcurementStrategies.SupplyType, VALUE(Enum.SupplyTypes.EmptyRef))
		|	END AS SupplyType,
		|	CASE
		|		WHEN Plan.BOMIsPredefined
		|				OR Plan.ProductionOrder.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|					AND ISNULL(WorksToPerform.ProducedInProcess, FALSE) THEN
		|			VALUE(Catalog.ProcurementStrategies.EmptyRef)
		|		ELSE
		|			ISNULL(ProcurementStrategies.Ref, VALUE(Enum.SupplyTypes.EmptyRef))
		|	END AS SupplyMethod,
		|
		|	CASE
		|		WHEN Plan.BOMIsPredefined
		|				OR Plan.ProductionOrder.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|					AND ISNULL(WorksToPerform.ProducedInProcess, FALSE)
		|			THEN TRUE
		|		WHEN (Plan.ProductionOrder.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Assembly)
		|				OR Plan.ProductionOrder.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
		|					AND Plan.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
		|				AND (Plan.ProductionOrder.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|					OR ISNULL(ProcurementStrategies.SourceOfDemandSupply, VALUE(Catalog.BusinessStructure.EmptyRef))
		|						IN (Plan.ProductionOrder.Department,
		|							UNDEFINED,
		|							VALUE(Catalog.BusinessStructure.EmptyRef)))
		|						AND ISNULL(ProcurementStrategies.SupplyType,
		|						   VALUE(Enum.SupplyTypes.EmptyRef)) = VALUE(Enum.SupplyTypes.Production)
		|					AND ISNULL(ProcurementStrategies.SemiFinishedProductPlanningMethod,
		|						   VALUE(Enum.SemiFinishedProductPlanningMethods.EmptyRef)) = VALUE(Enum.SemiFinishedProductPlanningMethods.Automatically)
		|					AND Plan.Products.Quality IN (VALUE(Enum.QualityLevels.New),
		|												VALUE(Enum.QualityLevels.EmptyRef))
		|			THEN TRUE
		|		WHEN ISNULL(ProcurementStrategies.SupplyType, VALUE(Enum.SupplyTypes.EmptyRef)) = VALUE(Enum.SupplyTypes.Move)
		|				AND NOT ProcurementStrategies.SourceOfDemandSupply IN (
		|						Plan.Warehouse,
		|						UNDEFINED,
		|						VALUE(Catalog.Warehouses.EmptyRef))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ToPlan
		|
		|INTO ItemList
		|FROM
		|	ModifiedRows AS Plan
		|	
		|		LEFT JOIN Catalog.BillsOfMaterials.WorksToPerform AS WorksToPerform
		|		ON Plan.ParentSpecification = WorksToPerform.Ref
		|		 AND Plan.LinkKeyIsBillOfMaterialsStringOfParent = WorksToPerform.ConnectionKey
		|		 AND NOT Plan.BOMIsPredefined
		|
		|		LEFT JOIN Catalog.ProcurementStrategies AS ProcurementStrategies
		|		ON &MainSupplyMethodSubstitution
		|		 AND NOT Plan.BOMIsPredefined
		|
		|INDEX BY
		|	TheIndexOfTheData
		|;";
	
	ConnectionFields = "Plan.Products, Plan.Characteristic, Plan.Warehouse";
	ParameterName = "MainSupplyMethodSubstitution";
	
	Query.Text = InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
		Query.Text, ParameterName, ConnectionFields);
	
	Query.Text = Query.Text +
		"SELECT
		|	ItemList.TheIndexOfTheData AS TheIndexOfTheData,
		|	ItemList.ProductKind AS ProductKind,
		|	ItemList.Products AS Products,
		|	ItemList.Characteristic AS Characteristic,
		|	ItemList.ProductionStart AS ProductionStart,
		|	ItemList.ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit,
		|	ItemList.LineOfBusiness AS LineOfBusiness,
		|	ItemList.UnderRepairProduct AS UnderRepairProduct,
		|	ItemList.UnderRepairVariant AS UnderRepairVariant,
		|	CASE
		|		WHEN ItemList.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM) THEN
		|			VALUE(Enum.ProductionProcessTypes.PerformRM)
		|		ELSE
		|			VALUE(Enum.ProductionProcessTypes.Assembly)
		|	END AS TypeOfProduction
		|INTO ManufacturedItems
		|FROM
		|	ItemList AS ItemList
		|
		|WHERE
		|	NOT ItemList.BOMIsPredefined
		|	AND (ItemList.SupplyType = VALUE(Enum.SupplyTypes.EmptyRef)
		|			OR ItemList.ToPlan
		|				AND ItemList.SupplyType = VALUE(Enum.SupplyTypes.Production))
		|;
		|SELECT DISTINCT
		|	Plan.TypeOfProduction AS TypeOfProduction
		|FROM
		|	ManufacturedItems AS Plan";
	
	TypesOfProduction = Query.Execute().Unload().UnloadColumn(0);
	
	If TypesOfProduction.Count() = 0 Then 
		
		Query.Text = // There is no need to select bill of materials
			"SELECT
			|	
			|	Plan.IndexOfLineOfNomenclaturePlan AS IndexOfLineOfNomenclaturePlan,
			|	Plan.Products AS Products,
			|	Plan.Characteristic AS Characteristic,
			|	Plan.Warehouse AS Warehouse,
			|	Plan.Purpose AS Purpose,
			|	Plan.ProductionOrder AS ProductionOrder,
			|
			|	Plan.BillOfMaterials AS BillOfMaterials,
			|	Plan.BOMIsPredefined AS BOMIsPredefined,
			|	Plan.Replace AS Replace,
			|
			|	Plan.ThisIsProductBeingDisassembled AS ThisIsProductBeingDisassembled,
			|
			|	Plan.SupplyType AS SupplyType,
			|	Plan.SupplyMethod AS SupplyMethod,
			|	Plan.SupplyMethod.SourceOfDemandSupply AS SourceOfDemandSupply,
			|	Plan.ToPlan AS ToPlan
			|
			|FROM
			|	ItemList AS Plan
			|;
			|DROP ModifiedRows;
			|DROP TTWarehouseFormats;
			|DROP ItemList;
			|DROP ManufacturedItems;
			|";
		
		QueryResult = Query.ExecuteBatch();
		ValuesInCache = QueryResult[0].Unload();
		
	Else
		
		BillOfMaterialsSelectionTexts = New Array();
		
		SpecificationRequestParameters = ProductDataManagement.ParametersOfRequestTextForManufacturedProductSpecifications();
		SpecificationRequestParameters.PriorityOnly = True;
		SpecificationRequestParameters.NameOfInputTable = "ManufacturedItems";
		SpecificationRequestParameters.OutputTableName = "SpecificationsOfProducts";
		SpecificationRequestParameters.DestroyTemporaryTables = True;
		
		If TypesOfProduction.Find(Enums.ProductionProcessTypes.Assembly) <> Undefined Then
			
			BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly();
			
			SpecificationRequestParameters.OutputTableName = "SpecificationsOfItem_Kit";
			
			If TempTablesManager.Tables.Find(SpecificationRequestParameters.OutputTableName) <> Undefined Then
			
				TMCommonUse.DestroyTemporaryTables(TempTablesManager, CommonClientServer.ValueInArray(SpecificationRequestParameters.OutputTableName));
			
			EndIf;
			
			SpecificationRequestParameters.ConditionsForSelectingIncomingData.Clear();
			SpecificationRequestParameters.ConditionsForSelectingIncomingData.Add(
				"ManufacturedItems.TypeOfProduction = VALUE(Enum.ProductionProcessTypes.Assembly)");
			
			ProductDataManagement.SetParametersForRequestManufacturedProductSpecifications(Query, BOMSelectionParameters);
			
			Query.Text = ProductDataManagement.RequestTextForProductItemsSpecifications(
				SpecificationRequestParameters,
				BOMSelectionParameters);
			
			Query.Execute();
			
			// Error in the Specification parameter platform.Add to the output table = The Truth;
			BillOfMaterialsSelectionTexts.Add("SELECT * FROM SpecificationsOfItem_Kit");
			
		EndIf;
		
		If TypesOfProduction.Find(Enums.ProductionProcessTypes.PerformRM) <> Undefined Then
			
			BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingBillOfMaterialsForRepairWork();
			
			SpecificationRequestParameters.OutputTableName = "ItemBillOfMaterials_PerformingRepairWork";
			
			If TempTablesManager.Tables.Find(SpecificationRequestParameters.OutputTableName) <> Undefined Then
			
				TMCommonUse.DestroyTemporaryTables(TempTablesManager, CommonClientServer.ValueInArray(SpecificationRequestParameters.OutputTableName));
			
			EndIf;
			
			SpecificationRequestParameters.ConditionsForSelectingIncomingData.Clear();
			SpecificationRequestParameters.ConditionsForSelectingIncomingData.Add(
				"ManufacturedItems.TypeOfProduction = VALUE(Enum.ProductionProcessTypes.PerformRM)");
			
			ProductDataManagement.SetParametersForRequestManufacturedProductSpecifications(Query, BOMSelectionParameters);
			
			Query.Text = ProductDataManagement.RequestTextForProductItemsSpecifications(
				SpecificationRequestParameters,
				BOMSelectionParameters);
			
			Query.Execute();
			
			// Error in the Specification parameter platform.Add to the output table = The Truth;
			BillOfMaterialsSelectionTexts.Add("SELECT * FROM ItemBillOfMaterials_PerformingRepairWork");
			
		EndIf;
		
		Query.Text = 
			StrReplace(
			"SELECT
			|	Table.TheIndexOfTheData AS TheIndexOfTheData,
			|	Table.BillOfMaterials AS BillOfMaterials
			|INTO SpecificationsOfProducts
			|FROM
			|	TextOfItemBillOfMaterials AS Table
			|
			|INDEX BY
			|	TheIndexOfTheData
			|;",
			"TextOfItemBillOfMaterials",
			"(" + StrConcat(BillOfMaterialsSelectionTexts, TMCommonUse.QuerySeparatorInJoin()) + ")");
	
		Query.Text = Query.Text +
			"SELECT
			|	
			|	Plan.IndexOfLineOfNomenclaturePlan AS IndexOfLineOfNomenclaturePlan,
			|	Plan.Products AS Products,
			|	Plan.Characteristic AS Characteristic,
			|	Plan.Warehouse AS Warehouse,
			|	Plan.Purpose AS Purpose,
			|	Plan.ProductionOrder AS ProductionOrder,
			|
			|	ISNULL(SpecificationsOfProducts.BillOfMaterials, Plan.BillOfMaterials) AS BillOfMaterials,
			|	Plan.BOMIsPredefined AS BOMIsPredefined,
			|	Plan.Replace AS Replace,
			|
			|	Plan.ThisIsProductBeingDisassembled AS ThisIsProductBeingDisassembled,
			|
			|	CASE
			|		WHEN Plan.SupplyType = VALUE(Enum.SupplyTypes.EmptyRef)
			|			THEN
			|				CASE WHEN SpecificationsOfProducts.BillOfMaterials IS NULL
			|					THEN VALUE(Enum.SupplyTypes.Purchase)
			|					ELSE VALUE(Enum.SupplyTypes.Production)
			|				END
			|			ELSE Plan.SupplyType
			|	END AS SupplyType,
			|	Plan.SupplyMethod AS SupplyMethod,
			|	Plan.SupplyMethod.SourceOfDemandSupply AS SourceOfDemandSupply,
			|	CASE
			|		WHEN SpecificationsOfProducts.BillOfMaterials IS NOT NULL THEN
			|			TRUE
			|		ELSE
			|			Plan.ToPlan
			|	END AS ToPlan
			|
			|FROM
			|	ItemList AS Plan
			|
			|		LEFT JOIN SpecificationsOfProducts AS SpecificationsOfProducts
			|		ON Plan.TheIndexOfTheData = SpecificationsOfProducts.TheIndexOfTheData
			|;
			|DROP ModifiedRows;
			|DROP TTWarehouseFormats;
			|DROP ItemList;
			|DROP ManufacturedItems;
			|DROP SpecificationsOfProducts;
			|";
		
		QueryResult = Query.ExecuteBatch(); 
		ValuesInCache = QueryResult[1].Unload();
		
	EndIf;
	
	Replacement = ValuesInCache.FindRows(New Structure("Replace", True));
	
	If Replacement.Count() > 0 Then
		InformationRegisters.CacheOfOrderStructureMasterData.ReplaceCachedValues(Replacement);
		DeleteRowsFromTable(ValuesInCache, Replacement);
	EndIf;
	
	InformationRegisters.CacheOfOrderStructureMasterData.WriteCachedValues(ValuesInCache);
		
	MovementCacheTable = ValuesInCache.Copy(New Structure("SupplyType, ToPlan", Enums.SupplyTypes.Move, True));
	
	If MovementCacheTable.Count() > 0 Then
		
		TextCleanup = "";
		
		If DeleteTT Then
		
			TextCleanup = "DROP TableName
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
			TextCleanup = StrReplace(TextCleanup, "TableName", TempTableName);	
		
		EndIf;
		
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.Text = TextCleanup + 
		"SELECT
		|	Goods.IndexOfLineOfNomenclaturePlan AS IndexOfLineOfNomenclaturePlan,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.SourceOfDemandSupply AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Goods.ProductionOrder AS ProductionOrder
		|INTO MovementCacheTable
		|FROM
		|	&MovementCacheTable AS Goods
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	ProductionOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Goods.ProductionOrder AS ProductionOrder,
		|	ItemPlan.Ordered AS Ordered,
		|	ItemPlan.ToSupply AS ToSupply,
		|	ItemPlan.RowIndex AS RowIndex,
		|	ItemPlan.BillOfMaterials AS BillOfMaterials,
		|	ItemPlan.ThisIsOutput_ ThisIsOutput_,
		|	ItemPlan.CommunicationKeyBillOfMaterialsRow AS CommunicationKeyBillOfMaterialsRow,
		|	ItemPlan.SemiFinishedProductBOM AS SemiFinishedProductBOM
		|INTO PortionOfCacheCalculation
		|FROM
		|	MovementCacheTable AS Goods
		|		LEFT JOIN ItemPlan AS ItemPlan
		|		ON Goods.IndexOfLineOfNomenclaturePlan = ItemPlan.RowIndex
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP MovementCacheTable";
		
		Query.SetParameter("MovementCacheTable", MovementCacheTable);
		
		Query.Execute();
		GetAndCacheSupplyMethods(TempTablesManager, "PortionOfCacheCalculation", True);
	
	EndIf;
	
EndProcedure

Procedure ScheduleProduction(CalculationParameters, TempTablesManager, TempTableName, QueueNumber)
	
	BlankID = New UUID("00000000-0000-0000-0000-000000000000");
	Query = New Query();
	Query.SetParameter("BlankID", BlankID);
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT DISTINCT
	|
	|	Plan.BillOfMaterials        AS BillOfMaterials,
	|	Plan.ProductionOrder AS ProductionOrder
	|
	|FROM
	|	ProductionPlan AS Plan
	|
	|WHERE
	|	Plan.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|;
	|
	|SELECT DISTINCT
	|
	|	Plan.Products        AS Products,
	|	Plan.Characteristic      AS Characteristic,
	|	Plan.Warehouse               AS Warehouse,
	|	Plan.Purpose          AS Purpose,
	|	Plan.ProductionOrder AS ProductionOrder,
	|	Plan.ErrorID AS ErrorID
	|
	|FROM
	|	ProductionPlan AS Plan
	|
	|WHERE
	|	Plan.SupplyType = VALUE(Enum.SupplyTypes.Production)
	|		AND Plan.ErrorID <> &BlankID
	|		AND Plan.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|";
	
	If TempTableName <> "ProductionPlan" Then
		Query.Text = StrReplace(Query.Text, "ProductionPlan", TempTableName);
	EndIf;
	
	QueryResult = Query.ExecuteBatch();
	
	// tasks for calculating the order structure
	
	If Not QueryResult[0].IsEmpty() Then
		InformationRegisters.TasksOfBOMOrderStructureCalculation.AddTasksToEndOfQueue(QueryResult[0].Unload(), QueueNumber);
	EndIf;
	
	// Specification Selection Errors
	
	If Not QueryResult[1].IsEmpty() Then
		
		Errors = InformationRegisters.OrderStructureCalculationProtocol.CreateRecordSet().UnloadColumns();
		
		ErrorsStructure = New Structure();
		ErrorsStructure.Insert("ErrorType", Enums.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenSelectingBOMs);
		ErrorsStructure.Insert("Errors", Errors);
		
		Protocol = New Structure("Products,Characteristic,Warehouse,Purpose,ProductionOrder"); //@skip-warning
		
		Selection = QueryResult[1].Select();
		While Selection.Next() Do
			Error = Errors.Add();
			FillPropertyValues(Error, Selection, "ErrorID,ProductionOrder");
			FillPropertyValues(Protocol, Selection);
			Error.Protocol = New ValueStorage(Protocol, New Deflation(9));
		EndDo;
		
		InformationRegisters.OrderStructureCalculationProtocol.RegisterErrors(ErrorsStructure);
		
	EndIf;
	
EndProcedure

Procedure DeleteSetOfRecordsByKey(KeySet) Export
	
	RecordSet = InformationRegisters.OrderStructure.CreateRecordSet();
	
	RecordSet.Filter.KeySet.Set(KeySet);

	RecordSetOfRecordsInAttempt(RecordSet, True);
	
EndProcedure

Function DataAboutAnalogsForCalculatingOrderStructure(TempTablesManager)
	
	Query = New Query;
	QueryTextMaterialsAndAnalogues = 
	"SELECT
	|	ConnectionsOfMaterialsAndAnalogues.Resolution AS Resolution,
	|	ConnectionsOfMaterialsAndAnalogues.Ref AS Ref,
	|	ConnectionsOfMaterialsAndAnalogues.LineNumber AS LineNumber,
	|	ConnectionsOfMaterialsAndAnalogues.Products AS Products,
	|	UNDEFINED AS PackageData,
	|	ConnectionsOfMaterialsAndAnalogues.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS ControlMultiplier,
	|	ConnectionsOfMaterialsAndAnalogues.Characteristic AS Characteristic,
	|	ConnectionsOfMaterialsAndAnalogues.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute) AS PriorityAnalogue,
	|	ConnectionsOfMaterialsAndAnalogues.Package AS Package,
	|	ConnectionsOfMaterialsAndAnalogues.NumberOfPackages AS NumberOfPackages,
	|	ISNULL(&PackingText, 1) * ConnectionsOfMaterialsAndAnalogues.NumberOfPackages AS NormativeStandard,
	|	ConnectionsOfMaterialsAndAnalogues.ScopeMaxPriority AS ScopeMaxPriority,
	|	ConnectionsOfMaterialsAndAnalogues.ConnectionKey AS ConnectionKey,
	|	ConnectionsOfMaterialsAndAnalogues.ThisIsASubstitute AS ThisIsASubstitute,
	|	CASE
	|		WHEN ConnectionsOfMaterialsAndAnalogues.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute)
	|			THEN 1
	|		WHEN ConnectionsOfMaterialsAndAnalogues.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials)
	|			THEN 2
	|		ELSE 10
	|	END AS ReplacementPriority
	|FROM
	|	ConnectionsOfMaterialsAndAnalogues AS ConnectionsOfMaterialsAndAnalogues
	|
	|ORDER BY
	|	ThisIsASubstitute, 
	|	ReplacementPriority,
	|	ScopeMaxPriority DESC,
	|	Period DESC,
	|	Resolution,
	|	LineNumber"; // The order is similar to the mechanisms in the Analog Materials module (See AlternativeMaterials.TextOfPermissionRequestByPriority)
	
	QueryTextMaterialsAndAnalogues = StrReplace(QueryTextMaterialsAndAnalogues, "&PackingText",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ConnectionsOfMaterialsAndAnalogues.Package",
			"ConnectionsOfMaterialsAndAnalogues.Products"));
		
	TablesNames = New Array;
	TablesNames.Add("ConnectionsOfMaterialsAndAnalogues");
		
	QueryTextPackageData = ProductDataManagement.QueryTextPackageData_(TablesNames);
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(QueryTextPackageData);
	ArrayOfTexts.Add(QueryTextMaterialsAndAnalogues);
	
	QueryText = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
				
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager; 
	ResultsArray = Query.ExecuteBatch();
	PermissionsTable = ResultsArray[ResultsArray.UBound()].Unload();
	
	Packing_DataTable = ResultsArray[ResultsArray.UBound() - 1].Unload();
	ProductDataManagement.FillInPackingDataInDataset(PermissionsTable, Packing_DataTable);
	
	MaterialsAndAnalogues = PermissionsTable.CopyColumns();
	MaterialsAndAnalogues.Columns.Add("Substitutes", New TypeDescription("ValueTable"));
	MaterialsAndAnalogues.Indexes.Add("Resolution, Ref, ConnectionKey");
	
	TableOfAnalogues = New ValueTable;
	TableOfAnalogues.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfAnalogues.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfAnalogues.Columns.Add("PackageData", New TypeDescription("FixedStructure"));
	TableOfAnalogues.Columns.Add("GoodsCharts", New TypeDescription("Array"));
	TableOfAnalogues.Columns.Add("KeyItemAnalog", New TypeDescription("UUID"));
	TableOfAnalogues.Columns.Add("NumberOfPackages", Common.TypeDescriptionNumber(15, 3));
	
	TheStructureOfTheSearch = New Structure("Resolution, Ref, ConnectionKey");
	
	For Each PermissionRow In PermissionsTable Do
	
		If PermissionRow.ThisIsASubstitute Then
			
			FillPropertyValues(TheStructureOfTheSearch, PermissionRow);
			ContentLines = MaterialsAndAnalogues.FindRows(TheStructureOfTheSearch);
			
			For Each MaterialsTableRow In ContentLines Do
			
				NewRow = MaterialsTableRow.Substitutes.Add();
				FillPropertyValues(NewRow, PermissionRow);
			
			EndDo;
			
		Else
			
			NewRow = MaterialsAndAnalogues.Add();
			FillPropertyValues(NewRow, PermissionRow);
			NewRow.Substitutes = TableOfAnalogues.CopyColumns();
		
		EndIf;
	
	EndDo;
		
	Return MaterialsAndAnalogues;

EndFunction

#EndRegion

#Region MasterData

Function SpecificationDataSamplingParameters()
	
	DataSamplingParameters = Catalogs.BillsOfMaterials.DataSamplingParameters("ManufacturedProducts,RecyclableWaste,MaterialsAndServices,LaborCosts");
	
	DataSamplingParameters.CalculateScheduleProductionAttribute = True; // TollManufacturing
	DataSamplingParameters.CombineMaterialsAndIncomingProducts         = True;
	DataSamplingParameters.CombineMaterialsAndWorksPerformed       = True;
	DataSamplingParameters.IntermediateSemiFinishedProducts                  = ProductDataManagementClientServer.IntermediateSemiFinishedProductsDoNotReceive();
	DataSamplingParameters.ConsiderProbabilityOfDefectiveGoods                   = False;
	
	Return DataSamplingParameters;
	
EndFunction

Function SpecificationData(Product, BatchSize, SpecificationsData)

	SpecificationData = SpecificationsData[Product.RowIndex];
	
	If SpecificationData = Undefined Then
		
		Template = NStr("vi = 'Cần nhận thêm dữ liệu, bộ nhớ đệm của bảng kê chi tiết không chứa dữ liệu phiên bản cần thiết (%1 / %2) hoặc chứa dữ liệu không chính xác';
						|ru = 'Требуется дополнительное получение данных, кэш спецификаций не содержит данных нужной версии (%1 / %2) или содержит некорректные данные';
						|en = 'Additional data is required. The cache of the bills of materials does not contain data of the required version (%1 / %2) or contains incorrect data'; fa = 'Additional data is required. The cache of the bills of materials does not contain data of the required version (%1 / %2) or contains incorrect data';
						|it = 'Требуется дополнительное получение данных, кэш спецификаций не содержит данных нужной версии (%1 / %2) или содержит некорректные данные';
						|pl = 'Additional data is required. The cache of the bills of materials does not contain data of the required version (%1 / %2) or contains incorrect data';
						|tr = 'Ek veri alımı gerekmektedir, ürün reçetesi önbelleği gereken sürüm verilerini (%1 / %2) içermemekte veya hatalı veriler içermektedir'");
		ErrorText = StrTemplate(Template, Product.BillOfMaterials, Product.DataVersionID);
		WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Warning,,Product.ProductionOrder,
			ErrorText);
		ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
		FillPropertyValues(ItemData_3, Product);
		SpecificationData = Catalogs.BillsOfMaterials.SpecificationData(ItemData_3, SpecificationDataSamplingParameters())[0];
		SpecificationsData.Insert(Product.RowIndex, SpecificationData);
		
	EndIf;
	
	ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
	FillPropertyValues(ItemData_3, Product);
	
	// calculation of quantity per Lot reference of output, the size of the Lot reference is transferred to the unit of the main FINISHED product
	
	ReleaseParty = Catalogs.BillsOfMaterials.ReleaseParty(
		BatchSize,
		Product.QuantityOfMainProductPerUnitOfLaunchBatch);
		
	Catalogs.BillsOfMaterials.CalculateQuantityPerBatchRelease(
		ReleaseParty,
		SpecificationData,
		ItemData_3);
	
	Catalogs.BillsOfMaterials.MarkInterimRelease(SpecificationData, True);
	
	Return SpecificationData;
	
EndFunction

#EndRegion

#Region MultiThreadedExecution

Procedure ExecuteThread(JobDescription, ProcedureName, ProcedureParameters, CalculationProtocol)
	
	PlaceInQueue = GetPlaceInCalculationQueue(CalculationProtocol);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Undefined);
	ExecutionParameters.BackgroundJobDescription = StrTemplate(NStr("vi = 'Tính toán cấu trúc đơn hàng: %1 (%2)';
																	|ru = 'Расчет структуры заказа: %1 (%2)';
																	|en = 'Order structure calculation: %1 (%2)'; fa = 'Order structure calculation: %1 (%2)';
																	|it = 'Calcolo della struttura dell''ordine: %1 (%2)';
																	|pl = 'Obliczenie struktury zamówienia: %1 (%2)';
																	|tr = 'Sipariş yapısının hesaplanması: %1 (%2)'"), JobDescription, PlaceInQueue + 1);
	ExecutionParameters.RunNotInBackground1 = Not CalculationProtocol.CalculationParameters.VectorizeCalculation;
	ExecutionParameters.ResultAddress = PutToTempStorage(Undefined, New UUID);
	ExecutionParameters.WaitCompletion = 0;
	
	RunResult = TimeConsumingOperations.ExecuteInBackground(ProcedureName, ProcedureParameters, ExecutionParameters);
	
	If RunResult.Status = "Running" Then
		CalculationProtocol.CalculationQueue[PlaceInQueue] = New Structure(
			"JobID,
			|ResultAddress,
			|ProcedureParameters", RunResult.JobID, RunResult.ResultAddress, ProcedureParameters);
		SaveStream(RunResult.JobID);
	Else
		If RunResult.Status = "Completed2" Then
			RecordResultInCalculationProtocol(CalculationProtocol, RunResult.ResultAddress);
		EndIf;
		If RunResult.Status = "Error" Then
			RecordErrorInCalculationProtocol(
				CalculationProtocol, ProcedureParameters, RunResult.BriefErrorDescription, RunResult.DetailErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Working with threads in memory.

Function ThereAreFreeStreams(CalculationProtocol)
	
	ThereAreFreeStreams = False;
	CalculationQueue = CalculationProtocol.CalculationQueue;
	
	For IndexOf = -CalculationQueue.UBound() To 0 Do
		
		If CalculationQueue[-IndexOf] = Undefined Then
			ThereAreFreeStreams = True;
			Break;
		EndIf;
		
	EndDo;
	
	Return ThereAreFreeStreams;

EndFunction

Function GetPlaceInCalculationQueue(CalculationProtocol)
	
	PlaceInQueue = 0;
	
	If CalculationProtocol.CalculationParameters.VectorizeCalculation Then
		
		If Not ThereAreFreeStreams(CalculationProtocol) Then ExpectCalculationCompletion(CalculationProtocol, False);
		EndIf;
		
		PlaceInQueue = CalculationProtocol.CalculationQueue.Find(Undefined);
		
	EndIf;
	
	Return PlaceInQueue;
	
EndFunction

Function ExpectCalculationCompletion(CalculationProtocol, ExpectCompletionOfCalculationOfAllThreads = True)
	
	CalculationIsCompleted = False;
	CalculationQueue = CalculationProtocol.CalculationQueue;
	
	SetPrivilegedMode(True);
	
	While Not CalculationIsCompleted Do
		
		ActiveTasks = New Array();
		ThereAreCompletedTasks = False;
		
		For Stream = 0 To CalculationQueue.UBound() Do
			
			If CalculationQueue[Stream] = Undefined Then
				Continue;
			EndIf;
			
			JobCompleted = JobCompleted(CalculationProtocol, CalculationQueue[Stream]);
			
			If Not JobCompleted Then
				
				ActiveTasks.Add(CalculationQueue[Stream].JobID);
				Continue;
				
			EndIf;
			
			DeleteFromTempStorage(CalculationQueue[Stream].ResultAddress);
			DeleteThread(CalculationQueue[Stream].JobID);
			
			CalculationQueue[Stream] = Undefined;
			
			ThereAreCompletedTasks = True;
			
		EndDo;
		
		CalculationIsCompleted = (ThereAreCompletedTasks And Not ExpectCompletionOfCalculationOfAllThreads) Or Not ValueIsFilled(ActiveTasks);
		
		If Not CalculationIsCompleted Then
			
			Job = BackgroundJobs.FindByUUID(ActiveTasks[0]);
			
			If Job <> Undefined Then
				
				Job.WaitForExecutionCompletion(CalculationProtocol.CalculationParameters.IntervalForCheckingCompletionOfCalculation);
			
			EndIf;
			
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return CalculationIsCompleted;
	
EndFunction

Function JobCompleted(CalculationProtocol, ThreadDetails)
	
	Job = BackgroundJobs.FindByUUID(ThreadDetails.JobID);
	
	If Not Job = Undefined Then
		
		If Job.State = BackgroundJobState.Active Then
			Return False;
		EndIf;
		
		If Job.State = BackgroundJobState.Completed Then
			RecordResultInCalculationProtocol(CalculationProtocol, ThreadDetails.ResultAddress);
		ElsIf Job.State = BackgroundJobState.Failed Then
			BriefErrorDescription = BriefErrorDescription(ErrorInfo());
			DetailErrorDescription = DetailErrorDescription(ErrorInfo());
			WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Error,,, DetailErrorDescription);
			RecordErrorInCalculationProtocol(
				CalculationProtocol, ThreadDetails.ProcedureParameters, BriefErrorDescription, DetailErrorDescription);
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Working with threads in the database.

Procedure SaveStream(ThreadID)
	
	RecordSet = InformationRegisters.OrderStructureCalculationThreads.CreateRecordSet();
	RecordSet.Filter.ThreadID.Set(ThreadID);
	
	Record = RecordSet.Add();
	Record.ThreadID = ThreadID;
	
	RecordSet.Write();
	
EndProcedure

Procedure DeleteAllStreams()
	
	RecordSet = InformationRegisters.OrderStructureCalculationThreads.CreateRecordSet();
	RecordSet.Write();
	
EndProcedure

Procedure DeleteThread(ThreadID)
	
	RecordSet = InformationRegisters.OrderStructureCalculationThreads.CreateRecordSet();
	RecordSet.Filter.ThreadID.Set(ThreadID);
	RecordSet.Write();
	
EndProcedure

Procedure CancelAllThreadsExecution()
	
	Threads = Threads();
	
	For Stream = 0 To Threads.UBound() Do
		
		TimeConsumingOperations.CancelJobExecution(Threads[Stream]);
		
		DeleteThread(Threads[Stream]);
		
	EndDo;
	
EndProcedure

Function Threads()
	
	Query = New Query();
	Query.Text =
		"SELECT
		|	Threads.ThreadID AS ThreadID
		|FROM
		|	InformationRegister.OrderStructureCalculationThreads AS Threads";
	Return Query.Execute().Unload().UnloadColumn(0);
	
EndFunction


////////////////////////////////////////////////////////////////////////////////
// Working with errors.

Function ErrorsFoundInCalculation(CalculationProtocol, PortionOfCalculation, CurrentAction1)
	
	HadErrors = CalculationProtocol.CalculationErrors.Count() > 0;
	
	If HadErrors
		And CheckErrorStatistics(CalculationProtocol) Then
		
		CalculationErrors = CalculationProtocol.CalculationErrors;
	
		ErrorsStructure = New Structure();
		ErrorsStructure.Insert("ErrorType", CurrentAction1.ErrorHandlingParameters.ErrorType);
		ErrorsStructure.Insert("Errors", New Array());
		
		GroupFields = CurrentAction1.ErrorHandlingParameters.GroupFields;
		
		If GroupFields = "" Then
			GroupFields = CurrentAction1.GroupFields;
		EndIf;
		
		If GroupFields = "" Then
			GroupFields = CurrentAction1.SelectionFields1;
		EndIf;
		
		For IndexOf = -CalculationErrors.Count() + 1 To 0 Do
			
			ErrorDescription = CalculationErrors[-IndexOf];
			
			NewPortionOfCalculation = SplitIntoPortions(
				ErrorDescription.PortionOfCalculation,
				CurrentAction1.SelectionFields1,
				GroupFields,
				?(CurrentAction1.BatchesCount = 1, 4, CurrentAction1.BatchesCount),
				False);
			
			If NewPortionOfCalculation.Count() > 1 Then
				CommonClientServer.SupplementArray(PortionOfCalculation, NewPortionOfCalculation);
			Else
				
				ProductionOrder = CollectionAttributes(ErrorDescription.PortionOfCalculation[0], "ProductionOrder");
				
				Protocol = InformationRegisters.OrderStructureCalculationProtocol.ProtocolTemplate();
				Protocol.Data = ErrorDescription.PortionOfCalculation;
				Protocol.MessageText = ErrorDescription.DetailErrorDescription;
				Protocol = New ValueStorage(Protocol, New Deflation(9));
				
				Error = New Structure();
				Error.Insert("ErrorID", New UUID());
				Error.Insert("ProductionOrder", ProductionOrder);
				Error.Insert("ShortDescription", ErrorDescription.BriefErrorDescription);
				Error.Insert("Protocol", Protocol);
				Error.Insert("LocksCalculation", True);
				
				ErrorsStructure.Errors.Add(Error); // an unsolvable error
			
			EndIf;
			
			CalculationErrors.Delete(-IndexOf);
			
		EndDo;
		
		If ErrorsStructure.Errors.Count() > 0 Then
			InformationRegisters.OrderStructureCalculationProtocol.RegisterErrors(ErrorsStructure);
		EndIf;
		
	EndIf;
	
	Return HadErrors;
	
EndFunction

Function CheckErrorStatistics(CalculationProtocol)

	If CalculationProtocol.CurTact > 1
		And CalculationProtocol.Statistics.Count() = CalculationProtocol.Statistics.FindRows(New Structure("Status", "Error")).Count() Then
		Raise NStr("vi = 'Tất cả các luồng khởi động tính toán đã kết thúc bị lỗi. Đã dừng thực hiện luồng điều khiển.';
					|ru = 'Все запущенные потоки расчета завершились с ошибкой. Выполнение управляющего потока остановлено.';
					|en = 'All started calculation threads completed with an error. Execution of the thread of control is canceled.'; fa = 'All started calculation threads completed with an error. Execution of the thread of control is canceled.';
					|it = 'Tutti i flussi di calcolo avviati sono stati eseguiti con errori. L''esecuzione del flusso gestionale è interrotta.';
					|pl = 'Wszystkie uruchomione przepływy obliczenia zostały zakończone z błędem. Wykonanie przepływu zarządzającego zostało zatrzymane.';
					|tr = 'Başlatılan tüm hesaplama akışları hatayla sonlandı. Yönetici akışının yürütülmesi durduruldu.'");
	EndIf;
	
	Return True;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Calculation protocol.

Procedure RecordResultInCalculationProtocol(CalculationProtocol, ResultAddress)
	
	CalculationResult2 = GetFromTempStorage(ResultAddress);
	
	NewRecord = CalculationProtocol.Statistics.Add();
	NewRecord.NumberCycle = CalculationProtocol.CurTact;
	NewRecord.Status = "Done";
	
	If Not CalculationResult2 = Undefined Then
		FillPropertyValues(NewRecord, CalculationResult2);
	EndIf;
	
	ShortenProtocol(CalculationProtocol);
	
EndProcedure

Procedure RecordErrorInCalculationProtocol(CalculationProtocol, ProcedureParameters, BriefErrorDescription = "", DetailErrorDescription = "")

	NewRecord = CalculationProtocol.Statistics.Add();
	NewRecord.NumberCycle = CalculationProtocol.CurTact;
	NewRecord.Status = "Error";

	ErrorDescription = New Structure();
	
	ErrorDescription.Insert("PortionOfCalculation", ProcedureParameters.PortionOfCalculation);
	ErrorDescription.Insert("BriefErrorDescription", BriefErrorDescription);
	ErrorDescription.Insert("DetailErrorDescription", DetailErrorDescription);
	
	CalculationProtocol.CalculationErrors.Add(ErrorDescription);
	
	ShortenProtocol(CalculationProtocol);
	
EndProcedure

Procedure ShortenProtocol(CalculationProtocol)
	
	If Not CalculationProtocol.Statistics.Count() > 200 Then
		Return;
	EndIf;
	
	Cnt = 1;
	
	For Each RecordingProtocol In CalculationProtocol.Statistics Do
	
		If Cnt > 100 Then
			Break;
		EndIf;
		
		CalculationProtocol.Statistics.Delete(RecordingProtocol);
		Cnt = Cnt + 1;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region CalculationParameters

Function CalculationParameters() Export
	
	Settings = OrderStructureCached.Service_Settings();
	
	CalculationParameters = New Structure();
	
	CalculationParameters.Insert("VectorizeCalculation", Settings.VectorizeCalculation);
	CalculationParameters.Insert("ThreadsCount", ?(Settings.VectorizeCalculation, Settings.ThreadsCount, 1));
	
	CalculationParameters.Insert("PortionSelection", Settings.PortionSelection);
	CalculationParameters.Insert("SelectionSize", Settings.SelectionSize * ?(Settings.VectorizeCalculation, Settings.ThreadsCount, 1));
	
	CalculationParameters.Insert("MaxAccountingDepth", Settings.MaxAccountingDepth);
	CalculationParameters.Insert("SearchCyclesAfter", Settings.SearchCyclesAfter);
	
	CalculationParameters.Insert("IntervalForCheckingCompletionOfCalculation", 2);
	
	CalculationParameters.Insert("CalculateChanges_", Settings.CalculateChanges_);
	CalculationParameters.Insert("AllowRepeatedUseOfCalculatedData", Settings.AllowRepeatedUseOfCalculatedData);
	
	CalculationParameters.Insert("AdditionalParameters", Settings.AdditionalParameters);
	
	Return CalculationParameters;
	
EndFunction

#EndRegion

#Region Service_Settings

Function Service_Settings(CheckOperatingMode = True) Export
	
	CalculationSettings = OrderStructure.StandardSettingsForCalculatingOrderStructure();
	
	SetPrivilegedMode(True);
	Storage = Constants.CalculationSettingsForProductionOrderStructure.Get();
	SetPrivilegedMode(False);
	
	Try
		
		FillPropertyValues(CalculationSettings, Storage.Get());
		
	Except
		
		ErrorText = NStr("vi = 'Không thể nhận tham số tính toán cấu trúc đơn hàng sản xuất, giá trị sẽ được đặt về tùy chỉnh mặc định';
						|ru = 'Не удалось получить параметры расчета структуры заказа на производство, значения будут приведены к настройкам по умолчанию';
						|en = 'Cannot get the calculation parameters of the production order structure, the values will be reset to the default settings'; fa = 'Cannot get the calculation parameters of the production order structure, the values will be reset to the default settings';
						|it = 'Non è stato possibile ricevere i parametri di calcolo della struttura dell''ordine di produzione, i valori saranno inseriti da impostazione predefinita';
						|pl = 'Nie udało się otrzymać parametrów obliczenia struktury zlecenia produkcyjnego, wartości zostaną przywrócone do ustawień domyślnych';
						|tr = 'Üretim emri yapısının hesaplanma parametreleri alınamadı, değerler varsayılan ayarlara getirilecektir'");
		
		WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Error,,,
						ErrorText);
						
		SetStandardSettingsForCalculatingOrderStructure();
		
	EndTry;
	
	If CheckOperatingMode And Common.FileInfobase() Then
		
		CalculationSettings.VectorizeCalculation = False;
		CalculationSettings.ThreadsCount      = 1;
		
	EndIf;
	
	Return New FixedStructure(CalculationSettings);
	
EndFunction

Function StandardSettingsForCalculatingOrderStructure() Export
	
	CalculationSettings = New Structure;
	
	CalculationSettings.Insert("VectorizeCalculation", False);
	CalculationSettings.Insert("ThreadsCount", 8);
	
	CalculationSettings.Insert("AllowRepeatedUseOfCalculatedData", True);
	
	CalculationSettings.Insert("PortionSelection", True);
	CalculationSettings.Insert("SelectionSize", 1000);
	
	CalculationSettings.Insert("MaxAccountingDepth", 125);
	CalculationSettings.Insert("SearchCyclesAfter", 25);
	
	CalculationSettings.Insert("BatchRecording", True);
	CalculationSettings.Insert("NumberOfRowsInTheRecordset", 100000); // Parallelize the calculation = False
	
	CalculationSettings.Insert("CalculateChanges_", True);
	
	CalculationSettings.Insert("AdditionalParameters", "");
	
	Return CalculationSettings;
	
EndFunction

Procedure RecordSettingsForCalculatingOrderStructure(SettingValues) Export
	
	SetPrivilegedMode(True);
	
	CalculationSettings = StandardSettingsForCalculatingOrderStructure();
	
	FillPropertyValues(CalculationSettings, SettingValues);
	
	Constants.CalculationSettingsForProductionOrderStructure.Set(New ValueStorage(CalculationSettings));
	
EndProcedure

Procedure InitializeOrderStructureCalculationSettings() Export
	
	SetPrivilegedMode(True);
	Storage = Constants.CalculationSettingsForProductionOrderStructure.Get();
	SetPrivilegedMode(False);
	
	If Not Storage = Undefined Then
		Return;
	EndIf;
	
	SetStandardSettingsForCalculatingOrderStructure();
	
EndProcedure

Procedure SetStandardSettingsForCalculatingOrderStructure() Export
	
	ParameterValues = StandardSettingsForCalculatingOrderStructure();
	
	RecordSettingsForCalculatingOrderStructure(ParameterValues);
	
EndProcedure

Function IntervalForCheckingCompletionOfCalculation()
	
	Return 2;
	
EndFunction

Function NumberOfRowsInTheRecordset() Export
	
	Settings = OrderStructureCached.Service_Settings();
	Return ?(Settings.BatchRecording, Settings.NumberOfRowsInTheRecordset, MaximumNumberOfLinesInTheRecordSet());
	
EndFunction

Function MaximumNumberOfLinesInTheRecordSet()
	
	Return 100000;
	
EndFunction

Function NumberOfWriteAttempts()
	
	Return ?(TransactionActive(), 1, 3);

EndFunction

#EndRegion

#Region CalculationProtocol

Function CalculationProtocol()
	
	CalculationProtocol = New Structure();
	
	CalculationProtocol.Insert("CurTact", 1);
	CalculationProtocol.Insert("CalculationStart", CurrentUniversalDateInMilliseconds());
	CalculationProtocol.Insert("CalculationParameters", CalculationParameters()); // cache of current values of calculation parameters
	CalculationProtocol.Insert("CalculationQueue", New Array(CalculationProtocol.CalculationParameters.ThreadsCount));
	CalculationProtocol.Insert("CalculationErrors", New Array());
	CalculationProtocol.Insert("Statistics", Statistics());
	
	Return CalculationProtocol;
	
EndFunction

Function Statistics()
	
	Statistics = New ValueTable;
	
	Statistics.Columns.Add("NumberCycle", New TypeDescription("Number"));
	Statistics.Columns.Add("JobID", New TypeDescription("Number"));
	Statistics.Columns.Add("Status", New TypeDescription("String"));
	Statistics.Columns.Add("Operation", New TypeDescription("String"));
	Statistics.Columns.Add("PortionSize", New TypeDescription("Number"));
	Statistics.Columns.Add("Duration", New TypeDescription("Number"));
	
	Return Statistics;
	
EndFunction

Function CodeMeasurements() Export
	
	CodeMeasurements = New ValueTable();
	
	CodeMeasurements.Columns.Add("Operation", New TypeDescription("String", ,New StringQualifiers(32)));
	CodeMeasurements.Columns.Add("NumberCycle", New TypeDescription("Number"));
	
	CodeMeasurements.Columns.Add("CalculationStart", New TypeDescription("Number"));
	CodeMeasurements.Columns.Add("CalculationEnd", New TypeDescription("Number"));
	
	CodeMeasurements.Columns.Add("RowsCount", New TypeDescription("Number"));
	CodeMeasurements.Columns.Add("Duration", New TypeDescription("Number"));
	
	Return CodeMeasurements;
	
EndFunction

Function StartMeasurement(OperationName, CalculationProtocol) Export
	
	CodeMeasurements = CalculationProtocol.CodeMeasurements; // ValueTable
	
	CodeMeasurement = CodeMeasurements.Add();
	
	CodeMeasurement.Operation = OperationName;
	CodeMeasurement.CalculationStart = CurrentUniversalDateInMilliseconds();
	
	Return CodeMeasurement;
	
EndFunction

Function FinishMeasurement(CodeMeasurement, RowsCount = 0) Export
	
	CodeMeasurement.CalculationEnd = CurrentUniversalDateInMilliseconds();
	
	CodeMeasurement.RowsCount = RowsCount;
	CodeMeasurement.Duration = (CodeMeasurement.CalculationEnd - CodeMeasurement.CalculationStart) / 1000;
	
	Return CodeMeasurement.Owner();
	
EndFunction

Function DecryptionOfCalculationProtocolForMeasuringCode(Table)
	
	Totals = Table.Copy(,"Operation,Duration,RowsCount"); // ValueTable
	Totals.GroupBy("Operation", "Duration,RowsCount");

	ArrayOfMessages = New Array;
	ArrayOfMessages.Add(NStr("vi = 'Biên bản tính toán';
							|ru = 'Протокол расчета';
							|en = 'Calculation protocol'; fa = 'Calculation protocol';
							|it = 'Protocollo di calcolo';
							|pl = 'Protokół obliczeniowy';
							|tr = 'Hesaplama protokolü'"));
	
	Template = NStr("vi = '- %1, T: %2, N: %3';
					|ru = '- %1, T: %2, N: %3';
					|en = '- %1, T: %2, N: %3'; fa = '- %1, T: %2, N: %3';
					|it = '- %1, T: %2, N: %3';
					|pl = '- %1, T: %2, N: %3';
					|tr = '- %1, T: %2, N: %3'");
	
	For Each Total In Totals Do
	
		MessageText = StrTemplate(Template, Total.Operation, Total.Duration, Total.RowsCount);
		ArrayOfMessages.Add(MessageText);
		
	EndDo;
	
	MessageText = StrConcat(ArrayOfMessages, ";" + Chars.LF);
	Return MessageText;
	
EndFunction

Procedure RecordCalculationProtocolInLog(CalculationProtocol)
	
	TimeInSeconds = Int((CurrentUniversalDateInMilliseconds() - CalculationProtocol.CalculationStart)/1000);
	
	Hours1 = Int(TimeInSeconds/3600);
	Minutes1 = Int((TimeInSeconds - Hours1 * 3600) / 60);
	Seconds = Max(TimeInSeconds - Hours1 * 3600 - Minutes1 * 60, 1);
	
	DurationHours = ?(Hours1 = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 giờ';
																									|ru = '%1 час';
																									|en = '%1 h'; fa = '%1 h';
																									|it = '%1 ora';
																									|pl = '%1 godzina';
																									|tr = '%1 saat'"), Hours1));
	DurationMinutes = ?(Minutes1 = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 phút';
																										|ru = '%1 мин';
																										|en = '%1 min'; fa = '%1 min';
																										|it = '%1 minuto';
																										|pl = '%1 min';
																										|tr = '%1 dk.'"), Minutes1));
	DurationSeconds = ?(Seconds = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 giây';
																										|ru = '%1 сек';
																										|en = '%1 sec'; fa = '%1 sec';
																										|it = '%1 sec-';
																										|pl = '%1 sek';
																										|tr = '%1 sn.'"), Seconds));
	
	DurationOfCalculation = DurationHours + " " + DurationMinutes + " " + DurationSeconds;
	DurationOfCalculation = TrimAll(DurationOfCalculation);
	
	MessageText = StrTemplate(NStr("vi = 'Đã tính xong, thời lượng %1';
									|ru = 'Завершен расчет, продолжительность %1';
									|en = 'Calculation is completed, duration %1'; fa = 'Calculation is completed, duration %1';
									|it = 'Calcolo completato, durata %1';
									|pl = 'Obliczenie zostało zakończone, czas trwania %1';
									|tr = 'Hesaplama tamamlandı, %1 süre'"), DurationOfCalculation);
	
	If CalculationProtocol.Property("CodeMeasurements") Then
		
		MessageText = MessageText + Chars.LF + DecryptionOfCalculationProtocolForMeasuringCode(CalculationProtocol.CodeMeasurements);
		
	EndIf;
	
	WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Information,,,
		MessageText);

EndProcedure

Procedure RecordUnsuccessfulAttemptToWriteToLog(ErrorCounter, ErrorText) Export
	
	MessageText = StrTemplate(NStr("vi = 'Thử ghi lại thất bại (%1): %2';
									|ru = 'Неудачная попытка записи (%1): %2';
									|en = 'Unsuccessful attempt to write (%1): %2'; fa = 'Unsuccessful attempt to write (%1): %2';
									|it = 'Tentativo fallito di registrazione (%1): %2';
									|pl = 'Nieudana próba zapisu (%1): %2';
									|tr = 'Başarısız kayıt denemesi (%1): %2'"), ErrorCounter, ErrorText);
	
	WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Warning,,,
		MessageText);
	
EndProcedure

#EndRegion

#Region Record

Procedure FillInAndRecordSetOfRecords(
			RecordSet,
			Table,
			Replace = False,
			ThereIsSeparator = False,
			ColumnsByValue = Undefined) Export
	
	NumberOfRowsInTheRecordset = NumberOfRowsInTheRecordset();
	
	If Replace = False
		And Table.Count() > NumberOfRowsInTheRecordset Then
		
		RowsCount = Table.Count();
		
		TotalServings = Round(RowsCount/NumberOfRowsInTheRecordset + 0.5, 0, 0);
		Divisor = New Array(TotalServings);
		
		Counter = 0;
		PortionNumber = 0;
		For Each String In Table Do
			If Counter >= NumberOfRowsInTheRecordset Then
				Counter = 0;
				PortionNumber = PortionNumber + 1;
			EndIf;
			If Divisor[PortionNumber] = Undefined Then
				PortionSize = Min(NumberOfRowsInTheRecordset, RowsCount - NumberOfRowsInTheRecordset * PortionNumber);
				Divisor[PortionNumber] = New Array(PortionSize);
			EndIf;
			Divisor[PortionNumber][Counter] = String;
			Counter = Counter + 1;
		EndDo;
		
		For Each Rows In Divisor Do
			LoadRowsIntoRecordsetWithAdditionalProcessing(
				RecordSet,
				Table,
				Rows,
				ThereIsSeparator,
				ColumnsByValue);
			RecordSetOfRecordsInAttempt(RecordSet, False);
		EndDo;
		
	Else
		
		LoadRowsIntoRecordsetWithAdditionalProcessing(
			RecordSet,
			Table,,
			ThereIsSeparator,
			ColumnsByValue);
		RecordSetOfRecordsInAttempt(RecordSet, Replace);
		
	EndIf;
	
EndProcedure

Procedure LoadRowsIntoRecordsetWithAdditionalProcessing(RecordSet, Table, StringsList = Undefined, ThereIsSeparator = False, ColumnsByValue = Undefined) Export
	
	If ThereIsSeparator Then
		RecordSeparator = New UUID();
	EndIf;

	If ThereIsSeparator Or ColumnsByValue <> Undefined Then
		
		Collection = ?(StringsList = Undefined, Table, StringsList);
		
		For Each String In Collection Do
			
			NewRecord = RecordSet.Add();
			
			FillPropertyValues(NewRecord, String);
			
			If ThereIsSeparator Then
				NewRecord.Separator = RecordSeparator;
			EndIf;
			
			If ColumnsByValue <> Undefined Then
				FillPropertyValues(NewRecord, ColumnsByValue);
			EndIf;
		
		EndDo;
		
	Else
		
		If StringsList <> Undefined Then
			
			RecordSet.Load(Table.Copy(StringsList));
			
		Else
			
			RecordSet.Load(Table);
			
		EndIf;
		
	EndIf;

EndProcedure

Procedure RecordSetOfRecordsInAttempt(RecordSet, Replace)
	
	ErrorCounter = 1;
	
	While True Do
		
		Try
			
			RecordSet.Write(Replace);
			
		Except
			
			ErrorText = DetailErrorDescription(ErrorInfo());
			
			If ErrorCounter < NumberOfWriteAttempts() Then
				RecordUnsuccessfulAttemptToWriteToLog(ErrorCounter, ErrorText);
				ErrorCounter = ErrorCounter + 1;
				Continue;
			EndIf;
			
			Raise ErrorText;
			
		EndTry;
		
		Break;
		
	EndDo;
	
	RecordSet.Clear();
	
EndProcedure

#EndRegion

#Region WorkWithAnalogues

Function QueryTextAlternativeMaterials(Query)

	FieldsMap = New Map;
	FieldsMap.Insert("UseItForAutocorrectInOrders", "UseItForAutocorrectInOrders");
	FieldsMap.Insert("ReplacementPriority", "ArrayOfValues");
	
	SelectionSettings = New Structure;
	SelectionSettings.Insert("GoodsTogetherWithParameters", True);
	SelectionSettings.Insert("ConsiderManyToMany", False);
	SelectionSettings.Insert("ToSelectInterchangeableAnalogues", True);
	SelectionSettings.Insert("SelectionOfPermissions", FieldsMap);
	SelectionSettings.Insert("NameOfTemporaryGoodsTable", "TT_Source");
	SelectionSettings.Insert("TempTableName", "ConnectionsOfMaterialsAndAnalogues");
	
	AnalogQueryText = AlternativeMaterials.QueryTextDataOfMaterialsAndAnalogues(SelectionSettings);
	Separator = Common.QueryBatchSeparator();
	
	TextDataSource = 
	"SELECT
	|	T.RowIndex                                                AS Ref,
	|
	|	T.Products                                                AS Products,
	|	T.Characteristic                                              AS Characteristic,
	|
	|	T.ProductionOrder.EarliestStartDate                           AS PermissionValidityDate,
	|	T.ProductionOrder                                         AS ProductionOrder,
	|	VALUE(Document.SalesOrder.EmptyRef)                  AS SalesOrder,
	|	T.Department                                               AS Department,
	|	T.ProductionOrder.LineOfBusiness                 AS LineOfBusiness,
	|	CASE
	|		WHEN VALUETYPE(T.Stage) = TYPE(Catalog.ProductionStages)
	|			THEN CAST(T.Stage AS Catalog.ProductionStages).Owner.MainProductProducts
	|		WHEN VALUETYPE(T.Stage) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(T.Stage AS Document.ProductionStage2_2).BillOfMaterials.MainProductProducts
	|	END                AS Product,
	|	CASE
	|		WHEN VALUETYPE(T.Stage) = TYPE(Catalog.ProductionStages)
	|			THEN CAST(T.Stage AS Catalog.ProductionStages).Owner.MainProductCharacteristic
	|		WHEN VALUETYPE(T.Stage) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(T.Stage AS Document.ProductionStage2_2).BillOfMaterials.MainProductCharacteristic
	|	END  AS ItemVariantOfProduct,
	|	CASE
	|		WHEN VALUETYPE(T.Stage) = TYPE(Catalog.ProductionStages)
	|			THEN CAST(T.Stage AS Catalog.ProductionStages).Owner
	|		WHEN VALUETYPE(T.Stage) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(T.Stage AS Document.ProductionStage2_2).BillOfMaterials
	|	END                                                         AS BillOfMaterials,
	|	CASE
	|		WHEN VALUETYPE(T.Stage) = TYPE(Catalog.ProductionStages)
	|			THEN CAST(T.Stage AS Catalog.ProductionStages)
	|		WHEN VALUETYPE(T.Stage) = TYPE(Document.ProductionStage2_2)
	|			THEN CAST(T.Stage AS Document.ProductionStage2_2).Stage
	|	END                                                        AS Stage
	|
	|INTO TT_Source
	|FROM
	|	ItemPlan AS T
	|
	|";
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(TextDataSource);
	ArrayOfTexts.Add(Separator);
	ArrayOfTexts.Add(AnalogQueryText);
	ArrayOfTexts.Add(Separator);
	
	QueryText = StrConcat(ArrayOfTexts);
	
	ArrayOfValues = New Array;
	ArrayOfValues.Add(Enums.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute);
	ArrayOfValues.Add(Enums.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials);
		
	Query.SetParameter("UseItForAutocorrectInOrders", True);
	Query.SetParameter("ArrayOfValues", ArrayOfValues);
	
	Return QueryText;

EndFunction

#EndRegion

#Region Other

// Splits the source table into portions
// 
// Parameters:
// 	Table - ValueTable - source table
// 	SelectionFields1 - String - selection fields
// 	GroupFields - String - Grouping fields
// 	BatchesCount - Number - number of servings
// 	TableIsOrdered - Boolean - prizna, the table is ordered
// Returns:
// 	Array - Portions
//
Function SplitIntoPortions(Table, SelectionFields1, GroupFields = "", BatchesCount = 1, TableIsOrdered = True)
	
	Result = New Array();
	
	If BatchesCount > 1 Then
		
		PortionSize = Round((Table.Count() / BatchesCount) + 0.5, 0, 0);
		
		ListOfDimensions = StrSplit(GroupFields, ",");
		
		If Not TableIsOrdered And GroupFields <> "" Then
			Table.Sort(GroupFields, New CompareValues);
		EndIf;
		
		Table.Columns.Add("Divisor", Common.TypeDescriptionNumber(4,0));
		
		Divisor = 1;
		Cnt = 0;
		For Each String In Table Do
			If Cnt >= PortionSize
				And (GroupFields = "" Or GroupFields <> "" And ThereAreDifferencesInColumns(Table[Table.IndexOf(String)-1], String, ListOfDimensions)) Then
				Divisor = Divisor + 1;
				Cnt = 0;
			EndIf;
			String.Divisor = Divisor;
			Cnt = Cnt + 1;
		EndDo;
		
		While Divisor > 0 Do
			Result.Add(Table.Copy(New Structure("Divisor", Divisor), SelectionFields1));
			Divisor = Divisor - 1;
		EndDo;
		
	ElsIf Table.Count() > 0 Then
		Result.Add(Table);
	EndIf;

	Return Result;
	
EndFunction

Procedure ConnectTables(Table, Table1)
	
	For X = 0 To Table1.Count() - 1 Do
		Table.Insert(0);
	EndDo;
	
	For X = 0 To Table1.Columns.Count() - 1 Do 
		Table.LoadColumn(Table1.UnloadColumn(X), X);
	EndDo;
	
EndProcedure

Function ThereAreDifferencesInColumns(String1, String2, Columns)
	
	ThereAreDifferences_ = False;
	
	For Each Column In Columns Do
		
		If String1[Column] <> String2[Column] Then 
			ThereAreDifferences_ = True;
			Break;
		EndIf;
		
	EndDo;
	
	Return ThereAreDifferences_;
	
EndFunction

Function CompareKeyFieldValues(FirstValue, SecondValue, KeyFields, CompareValues) Export
	
	Result = 0;
	
	For Each Field In KeyFields Do
		Result = CompareValues.Compare(FirstValue[Field], SecondValue[Field]);
		If Result <> 0 Then
			Break;
		EndIf;
	EndDo;
		
	Return Result;
	
EndFunction

Function CopyColumns(Columns, CopiedColumns = "", ColumnsToExclude = "", ColumnsToAdd = Undefined) Export
	
	NewTable = New ValueTable();
	
	For Each Column In Columns Do
		
		If CopiedColumns <> "" And StrFind(CopiedColumns, Column.Name) = 0 Or ColumnsToExclude <> "" And StrFind(ColumnsToExclude, Column.Name) > 0 Then
			Continue;
		EndIf;
		
		NewTable.Columns.Add(Column.Name, New TypeDescription(Column.ValueType,, "Null"));
		
	EndDo;
	
	If ColumnsToAdd <> Undefined Then
		
		For Each Column In ColumnsToAdd Do
		
			NewTable.Columns.Add(Column.Key, Column.Value);
			
		EndDo;
		
	EndIf;
	
	Return NewTable;

EndFunction

Procedure CollapseTableAndDeleteNullRows(Table, GroupColumns, TotalingColumns)

	Resources = StrSplit(TotalingColumns, ",");
	
	ModifiedRows = Table.Copy(, GroupColumns + "," + TotalingColumns); // ValueTable
	ModifiedRows.GroupBy(GroupColumns, TotalingColumns);
	
	For IndexOf = -ModifiedRows.Count() + 1 To 0 Do
		
		CurrentRow = ModifiedRows[-IndexOf];
		Delete = True;
		
		For Each Resource In Resources Do
			
			If CurrentRow[Resource] <> 0 Then
				Delete = False;
				Break;
			EndIf;
			
		EndDo;
		
		If Delete Then
			ModifiedRows.Delete(-IndexOf);
			Continue;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure DeleteRowsFromTable(Table, Rows)
	
	For Each String In Rows Do Table.Delete(String);
	EndDo;
	
EndProcedure

Function AdjustValue(TypeDescription, Value)

	Result = TypeDescription.AdjustValue(Value);
	Return Result;
	
EndFunction

Function ColumnNamesOfTableInRow(SourceOfColumns, ColumnsToExclude = "") Export
	
	If TypeOf(SourceOfColumns) = Type("ValueTable")
	 Or TypeOf(SourceOfColumns) = Type("QueryResult") Then
		Columns = SourceOfColumns.Columns;
	Else
		Columns = SourceOfColumns;
	EndIf;
	
	ColumnsNames = "";
	StructureExcludedColumns = New Structure(ColumnsToExclude);
	
	For Each Column In Columns Do
		
		If Not StructureExcludedColumns.Property(Column.Name) Then
			ColumnsNames = ColumnsNames + ?(ColumnsNames = "", "", ", ") + "%1" + Column.Name;
		EndIf;
		
	EndDo;
	
	Return ColumnsNames;
	
EndFunction

Function QueryTextPutTableOfValuesInTemporaryTable(TempTableName, Columns, Val TableFields = "", Val FilterCriterion = "", Val IndexingFields = "") Export
	
	QueryText = StrReplace(
		"SELECT
		|	&Fields
		|INTO TempTableName
		|FROM
		|	&TempTableName AS Table
		|WHERE &FilterCriterion", "TempTableName", TempTableName);
	
	If TableFields = "" Then
		TableFields = ColumnNamesOfTableInRow(Columns);
	EndIf;
	
	QueryText = StrReplace(QueryText, "&Fields", TrimAll(StrReplace(TableFields, "%1", Chars.LF + "Table.")));
	QueryText = StrReplace(QueryText, "&FilterCriterion", ?(FilterCriterion = "", "TRUE", FilterCriterion));
	
	If IndexingFields <> "" Then
		QueryText = QueryText + " " + "INDEX BY" + " " + IndexingFields;
	EndIf;
	
	Return QueryText;
	
EndFunction

Procedure PutTableOfValuesInTemporaryTable(TempTablesManager, TempTableName, Table, Val TableFields = "", Val FilterCriterion = "", Val IndexingFields = "") Export
	
	Columns = Table.Columns; // ValueTableColumnCollection
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
		QueryTextPutTableOfValuesInTemporaryTable(TempTableName, Columns, TableFields, FilterCriterion, IndexingFields);
	Query.SetParameter(TempTableName, Table);
	Query.Execute();
	
EndProcedure

Function CollectionAttributes(Collection, AttributeName)
	
	AttributeStructure = New Structure(AttributeName);

	FillPropertyValues(AttributeStructure, Collection);
	
	Return AttributeStructure[AttributeName];

EndFunction

Function ValueFromMatch(Map, Var_Key, DefaultValue = Undefined)
	
	Value = Map[Var_Key];
	
	If Value <> Undefined Then
		Return Value;
	Else
		Return DefaultValue;
	EndIf;
	
EndFunction

Function FindRowByColumnValueInArrayOfRows(RowsArray, ColumnName, Value)

	FoundRow = Undefined;
	
	For Each String In RowsArray Do
	
		If String[ColumnName] <> Value Then Continue;
		EndIf;
		
		FoundRow = String;
		Break;
		
	EndDo;
	
	Return FoundRow;
	
EndFunction

Function StructureByFields(Collection, FieldList)

	Result = New Structure(FieldList);
	FillPropertyValues(Result, Collection);
	Return Result;

EndFunction

Procedure SortArrayOfStrings(Array, Column, lb, ub)
	
	X = lb;
	Y = ub;
	
	Boundary = Array[Int((X + Y)/2)][Column]; // support element
	
	While X <= Y Do
		
		While Array[X][Column] < Boundary Do
			X = X + 1;
		EndDo;
		
		While Array[Y][Column] > Boundary Do
			Y = Y - 1;
		EndDo;
		
		If X <= Y Then
			Buffer = Array[X];
			Array[X] = Array[Y];
			Array[Y] = Buffer;
			X = X + 1;
			Y = Y - 1;
		EndIf;
		
	EndDo;
	
	If lb < Y Then
		SortArrayOfStrings(Array, Column, lb, Y);
	EndIf;
	
	If X < ub Then
		SortArrayOfStrings(Array, Column, X, ub);
	EndIf;
	
EndProcedure

Function NumberType()
	
	Return New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Any));
	
EndFunction

Function EventLogEventName() Export
	
	Return NStr("vi = 'Tính toán cấu trúc đơn hàng sản xuất';
				|ru = 'Расчет структуры заказа на производство';
				|en = 'Production order structure calculation'; fa = 'Production order structure calculation';
				|it = 'Calcolo della struttura dell''ordine di produzione';
				|pl = 'Obliczenie struktury zlecenia produkcyjnego';
				|tr = 'Üretim emri yapısının hesaplanması'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndRegion
