#Region Internal

#Region Totals

// Starts the background task of calculating the totals for the production order.
// 
// Parameters:
//  ProductionOrder - DocumentRef.ProductionOrder2_2 - A document for calculating the totals.
//  CompleteCalculation - Boolean - Full settlement
// 
// Returns:
//  Structure - Start Calculating The Results Of The Production Order:
// * JobID - UUID - ID of the background task for calculating totals.
// * UpdateDate - Date - Calculation date.
// * RunResult - See TimeConsumingOperations.OperationNewRuntimeResult
//
Function StartCalculatingResultsOfProductionOrder(ProductionOrder, CompleteCalculation = False) Export
	
	CurrentTime = Date(1,1,1) + CurrentUniversalDateInMilliseconds()/1000;
	
	Result = New Structure();
	Result.Insert("JobID", New UUID("00000000-0000-0000-0000-000000000000"));
	Result.Insert("UpdateDate", '00010101');
	Result.Insert("RunResult", Undefined);
	
	CalculationInformation_ = InformationRegisters.OrderMonitoringPreviousCalculation.Get_Information(ProductionOrder);
	
	If Not CompleteCalculation
		And CurrentTime < CalculationInformation_.CalculationPeriod + 10*60 And CalculationInformation_.RunTime > 2 Then
	
		Result.UpdateDate = CalculationInformation_.CalculationPeriod;
		
	Else
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("ProductionOrder", ProductionOrder);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters();
		ExecutionParameters.WaitCompletion = 0;
		ExecutionParameters.BackgroundJobDescription =
			NStr("vi = 'Màn hình theo dõi đơn hàng sản xuất. Tính phần tổng kết lịch biểu sản xuất';
				|ru = 'Мониторинг заказа на производство. Расчет итогов графика производства';
				|en = 'Production order monitoring. Calculation of the production schedule totals'; fa = 'Production order monitoring. Calculation of the production schedule totals';
				|it = 'Monitoraggio dell''ordine in produzione. Calcolo dei totali del grafico di produzione';
				|pl = 'Monitorowanie zlecenia produkcyjnego. Obliczenie wyników harmonogramu produkcji';
				|tr = 'Üretim emrinin izlenmesi. Üretim programı toplamlarının hesaplanması'");
	
		ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
			"MonitorProductionOrder.CalculateResultsOfProductionOrder",
			ProcedureParameters,
			ExecutionParameters);
			
		Result.RunResult = ExecutionResult;
		Result.JobID = ExecutionResult.JobID;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure CalculateResultsOfProductionOrder(Parameters, StorageAddress) Export
	
	MeasurementStart = CurrentUniversalDateInMilliseconds();
	
	KeyOperation = "IntershopManagement2_2.CalculationOfResultsOfProductionOrder";
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
	DataVolume = CalculateFullIntervalOfProductionSchedule(Parameters);
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
	CurrentTime = CurrentUniversalDateInMilliseconds();
	RunTime = (CurrentTime - MeasurementStart)/1000;
	
	CalculationInformation_ = New Structure;
	CalculationInformation_.Insert("ProductionOrder", Parameters.ProductionOrder);
	CalculationInformation_.Insert("CalculationPeriod", Date(1,1,1) + CurrentTime/1000);
	CalculationInformation_.Insert("RunTime", RunTime);
	
	InformationRegisters.OrderMonitoringPreviousCalculation.RecordInformation(CalculationInformation_);
	
EndProcedure

#Region FullInterval

Function CalculateFullIntervalOfProductionSchedule(Parameters)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("ProductionOrder", Parameters.ProductionOrder);
	Query.SetParameter("MainCalendar", Constants.MainEnterpriseCalendar.Get());
	Query.Text =
	"SELECT
	|	OrderStructure.KeyLot AS KeyLot,
	|	OrderStructure.Stage AS Stage,
	|	OrderStructure.DateOfReceipt AS DateOfReceipt,
	|	ISNULL(BEGINOFPERIOD(Schedule.Begin, DAY), DATETIME(1,1,1)) AS DesiredDate,
	|	MAX(ISNULL(NSICache.SupplyMethod.OrderFulfillmentPeriod, 1)) AS NumberOfDays
	|INTO ReceiptSchedule
	|FROM
	|	InformationRegister.OrderStructure AS OrderStructure
	|
	|	LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS Schedule
	|	ON OrderStructure.ProductionOrder = Schedule.ProductionOrder
	|		AND OrderStructure.KeyLot = Schedule.KeyLot
	|		AND OrderStructure.Stage = Schedule.Stage
	|	
	|	LEFT JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
	|	ON OrderStructure.DateOfReceipt = DATETIME(1,1,1)
	|		AND OrderStructure.Products = NSICache.Products
	|		AND OrderStructure.Characteristic = NSICache.Characteristic
	|		AND OrderStructure.Warehouse = NSICache.Warehouse
	|		AND OrderStructure.Purpose = NSICache.Purpose
	|		AND OrderStructure.ProductionOrder = NSICache.ProductionOrder
	|WHERE
	|	OrderStructure.ProductionOrder = &ProductionOrder
	|	AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
	|	AND OrderStructure.ReceiptOrder <> UNDEFINED
	|
	|GROUP BY
	|	OrderStructure.KeyLot,
	|	OrderStructure.Stage,
	|	OrderStructure.DateOfReceipt,
	|	ISNULL(BEGINOFPERIOD(Schedule.Begin, DAY), DATETIME(1,1,1))
	|
	|HAVING
	|	SUM(OrderStructure.AllocatedFromAvailableInventory) <> 0
	|		OR SUM(OrderStructure.AllocatedFromAvailableInventoryWithAssignment) <> 0
	|
	|INDEX BY
	|	DateOfReceipt
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	ReceiptSchedule.KeyLot AS KeyLot,
	|	ReceiptSchedule.Stage AS Stage
	|INTO ViolationsOfDesiredDate
	|FROM
	|	ReceiptSchedule AS ReceiptSchedule
	|
	|GROUP BY
	|	ReceiptSchedule.KeyLot,
	|	ReceiptSchedule.Stage
	|
	|HAVING
	|	MAX(ReceiptSchedule.DateOfReceipt > ReceiptSchedule.DesiredDate) = TRUE
	|
	|INDEX BY
	|	KeyLot,
	|	Stage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	NestedQuery.KeyLot AS KeyLot,
	|	NestedQuery.Stage AS Stage,
	|	NestedQuery.StartingDate AS StartingDate,
	|	MAX(NestedQuery.NumberOfDays) AS NumberOfDays
	|INTO MaterialsToProvide
	|FROM
	|	(
	|		SELECT
	|			OrderStructure.KeyLot AS KeyLot,
	|			OrderStructure.Stage AS Stage,
	|			ISNULL(BEGINOFPERIOD(Schedule.Begin, DAY), DATETIME(1,1,1)) AS StartingDate,
	|			MAX(ISNULL(NSICache.SupplyMethod.OrderFulfillmentPeriod, 1)) AS NumberOfDays
	|		FROM
	|			InformationRegister.OrderStructure AS OrderStructure
	|		
	|			LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS Schedule
	|			ON OrderStructure.ProductionOrder = Schedule.ProductionOrder
	|				AND OrderStructure.KeyLot = Schedule.KeyLot
	|				AND OrderStructure.Stage = Schedule.Stage
	|		
	|			LEFT JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
	|			ON OrderStructure.Products = NSICache.Products
	|				AND OrderStructure.Characteristic = NSICache.Characteristic
	|				AND OrderStructure.Warehouse = NSICache.Warehouse
	|				AND OrderStructure.Purpose = NSICache.Purpose
	|				AND OrderStructure.ProductionOrder = NSICache.ProductionOrder
	|		WHERE
	|			OrderStructure.ProductionOrder = &ProductionOrder
	|			AND OrderStructure.LineKind IN(
	|					VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption),
	|					VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved))
	|			AND TRUE NOT IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.CacheOfOrderStructureMasterData AS MasterDataCacheProduction
	|				WHERE
	|					MasterDataCacheProduction.ProductionOrder = OrderStructure.ProductionOrder
	|					AND MasterDataCacheProduction.Products = OrderStructure.Products
	|					AND MasterDataCacheProduction.Characteristic = OrderStructure.Characteristic
	|					AND MasterDataCacheProduction.ToPlan
	|					AND MasterDataCacheProduction.SupplyType = VALUE(Enum.SupplyTypes.Production))
	|			AND ISNULL(NSICache.SupplyType, UNDEFINED) <> VALUE(Enum.SupplyTypes.Move)
	|		
	|		GROUP BY
	|			OrderStructure.KeyLot,
	|			OrderStructure.Stage,
	|			OrderStructure.Products,
	|			OrderStructure.Characteristic,
	|			OrderStructure.Warehouse,
	|			OrderStructure.Purpose,
	|			ISNULL(BEGINOFPERIOD(Schedule.Begin, DAY), DATETIME(1,1,1))
	|		
	|		HAVING
	|			SUM(OrderStructure.ToSupply - OrderStructure.Replaced - OrderStructure.AllocatedFromAvailableInventory - OrderStructure.AllocatedFromAvailableInventoryWithAssignment) > 0
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.KeyLot,
	|	NestedQuery.Stage,
	|	NestedQuery.StartingDate
	|
	|INDEX BY
	|	StartingDate, NumberOfDays
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT DISTINCT
	|	&MainCalendar AS Calendar,
	|	Schedule.DesiredDate AS StartingDate,
	|	Schedule.NumberOfDays   AS NumberOfDays
	|INTO TTSearchParameters
	|FROM
	|	ReceiptSchedule AS Schedule
	|WHERE
	|	Schedule.DateOfReceipt = DATETIME(1,1,1)
	|	AND Schedule.DesiredDate <> DATETIME(1,1,1)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	&MainCalendar    AS Calendar,
	|	UsedMaterials.StartingDate AS StartingDate,
	|	UsedMaterials.NumberOfDays   AS NumberOfDays
	|FROM
	|	MaterialsToProvide AS UsedMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|"
	+ ProductionServer.QueryTextForDatesByCalendar(False) + "
	|
	|SELECT
	|	NestedQuery.KeyLot AS KeyLot,
	|	NestedQuery.Stage AS Stage,
	|	MIN(NestedQuery.LeftLimit) AS LeftLimit
	|INTO Supply
	|FROM
	|	(
	|		SELECT
	|			ReceiptSchedule.KeyLot AS KeyLot,
	|			ReceiptSchedule.Stage AS Stage,
	|			CASE
	|				WHEN ReceiptSchedule.DateOfReceipt <> DATETIME(1,1,1)
	|					THEN ReceiptSchedule.DateOfReceipt
	|				ELSE ScheduleDates.Date
	|			END AS LeftLimit
	|		FROM
	|			ReceiptSchedule AS ReceiptSchedule
	|			
	|			LEFT JOIN TTScheduleDates AS ScheduleDates
	|			ON ReceiptSchedule.DateOfReceipt = DATETIME(1,1,1)
	|				AND ReceiptSchedule.DesiredDate = ScheduleDates.StartingDate
	|				AND ReceiptSchedule.NumberOfDays = ScheduleDates.NumberOfDays
	|		WHERE
	|			ReceiptSchedule.DateOfReceipt <> DATETIME(1,1,1)
	|			OR ScheduleDates.Date IS NOT NULL
	|
	|		UNION ALL
	|
	|		SELECT
	|			UsedMaterials.KeyLot AS KeyLot,
	|			UsedMaterials.Stage AS Stage,
	|			ScheduleDates.Date AS LeftLimit
	|		FROM
	|			MaterialsToProvide AS UsedMaterials
	|			
	|			INNER JOIN TTScheduleDates AS ScheduleDates
	|			ON UsedMaterials.StartingDate = ScheduleDates.StartingDate
	|				AND UsedMaterials.NumberOfDays = ScheduleDates.NumberOfDays
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.KeyLot,
	|	NestedQuery.Stage
	|
	|INDEX BY
	|	KeyLot, Stage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Schedule.ProductionOrder AS ProductionOrder,
	|	Schedule.KeyLot          AS KeyLot,
	|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
	|	MIN(Schedule.Begin)     AS Begin,
	|	MAX(Schedule.Ending) AS Ending,
	|	MIN(
	|		CASE
	|			WHEN Schedule.Stage REFS Catalog.ProductionStages
	|					OR ProductionStage.Status <> VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|				THEN ISNULL(Supply.LeftLimit, Schedule.Begin)
	|		END) AS LeftLimit,
	|	MAX(ViolationsOfDesiredDate.Stage IS NOT NULL) AS RequestedSupplyDateIsViolated,
	|	TRUE                     AS ThisIsFinalLine,
	|	FALSE                       AS ItIsTransfer
	|FROM
	|	InformationRegister.TargetOrderStructureSchedule AS Schedule
	|
	|	LEFT JOIN Document.ProductionStage2_2 AS ProductionStage
	|	ON Schedule.Stage = ProductionStage.Ref
	|
	|	LEFT JOIN Supply AS Supply
	|	ON Schedule.KeyLot = Supply.KeyLot
	|		AND Schedule.Stage = Supply.Stage
	|		AND Supply.LeftLimit < Schedule.Begin
	|
	|	LEFT JOIN ViolationsOfDesiredDate AS ViolationsOfDesiredDate
	|	ON Schedule.KeyLot = ViolationsOfDesiredDate.KeyLot
	|		AND Schedule.Stage = ViolationsOfDesiredDate.Stage
	|WHERE
	|	Schedule.ProductionOrder = &ProductionOrder
	|	AND Schedule.Stage <> VALUE(Catalog.ProductionStages.EmptyRef)
	|
	|GROUP BY
	|	Schedule.ProductionOrder,
	|	Schedule.KeyLot
	|
	|UNION ALL
	|
	|SELECT
	|	Schedule.ProductionOrder AS ProductionOrder,
	|	Schedule.KeyLot          AS KeyLot,
	|	Schedule.Stage                AS Stage,
	|	Schedule.Begin              AS Begin,
	|	Schedule.Ending           AS Ending,
	|	ISNULL(Supply.LeftLimit, Schedule.Begin) AS LeftLimit,
	|	ViolationsOfDesiredDate.Stage IS NOT NULL AS RequestedSupplyDateIsViolated,
	|	FALSE                       AS ThisIsFinalLine,
	|	FALSE                       AS ItIsTransfer
	|FROM
	|	InformationRegister.TargetOrderStructureSchedule AS Schedule
	|
	|	LEFT JOIN Supply AS Supply
	|	ON Schedule.KeyLot = Supply.KeyLot
	|		AND Schedule.Stage = Supply.Stage
	|		AND Supply.LeftLimit < Schedule.Begin
	|
	|	LEFT JOIN ViolationsOfDesiredDate AS ViolationsOfDesiredDate
	|	ON Schedule.KeyLot = ViolationsOfDesiredDate.KeyLot
	|		AND Schedule.Stage = ViolationsOfDesiredDate.Stage
	|WHERE
	|	Schedule.ProductionOrder = &ProductionOrder
	|	AND Schedule.Stage <> VALUE(Catalog.ProductionStages.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	OrderStructure.ProductionOrder AS ProductionOrder,
	|	OrderStructure.KeyLot          AS KeyLot,
	|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
	|	Schedule.Begin                       AS Begin,
	|	Schedule.Ending                    AS Ending,
	|	ISNULL(Supply.LeftLimit, Schedule.Begin) AS LeftLimit,
	|	FALSE                                AS RequestedSupplyDateIsViolated,
	|	TRUE                              AS ThisIsFinalLine,
	|	TRUE                              AS ItIsTransfer
	|FROM
	|	InformationRegister.OrderStructure AS OrderStructure
	|
	|	INNER JOIN InformationRegister.TargetOrderStructureSchedule AS Schedule
	|	ON OrderStructure.ProductionOrder = Schedule.ProductionOrder
	|		AND OrderStructure.KeyLot = Schedule.KeyLot
	|
	|	LEFT JOIN Supply AS Supply
	|	ON Schedule.KeyLot = Supply.KeyLot
	|		AND Supply.LeftLimit < Schedule.Begin
	|WHERE
	|	OrderStructure.ProductionOrder = &ProductionOrder
	|	AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
	|
	|ORDER BY
	|	LeftLimit
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT DISTINCT
	|	ProductionIssue.KeyLot      AS KeyLot,
	|	Consumption.KeyLot AS KeyPartyConsumer,
	|	Consumption.Stage       AS StageConsumer
	|FROM
	|	InformationRegister.OrderStructure AS ProductionIssue
	|		INNER JOIN InformationRegister.OrderStructure AS Consumption
	|		ON ProductionIssue.Products        = Consumption.Products
	|		 AND ProductionIssue.Characteristic      = Consumption.Characteristic
	|		 AND ProductionIssue.Warehouse               = Consumption.Warehouse
	|		 AND ProductionIssue.Purpose          = Consumption.Purpose
	|		 AND ProductionIssue.ProductionOrder = Consumption.ProductionOrder
	|		 AND ProductionIssue.KeyProducts    = Consumption.KeyProducts
	|WHERE
	|	ProductionIssue.ProductionOrder = &ProductionOrder
	|	AND ProductionIssue.LineKind IN(
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.Move))
	|	AND Consumption.LineKind IN(
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
	|	AND Consumption.AdditionalRecord = FALSE
	|
	|GROUP BY
	|	ProductionIssue.Products,
	|	ProductionIssue.Characteristic,
	|	ProductionIssue.Warehouse,
	|	ProductionIssue.Purpose,
	|	ProductionIssue.KeyProducts,
	|	ProductionIssue.KeyLot,
	|	Consumption.KeyLot,
	|	Consumption.Stage
	|	
	|HAVING
	|	SUM(ProductionIssue.Scheduled) <> 0 OR SUM(ProductionIssue.AllocatedInFreeProductionLots + ProductionIssue.AllocatedInAssignedProductionLots) <> 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Schedule.Begin    AS Begin,
	|	Schedule.Ending AS Ending
	|FROM
	|	InformationRegister.TargetOrderStructureSchedule AS Schedule
	|WHERE
	|	Schedule.ProductionOrder = &ProductionOrder
	|	AND Schedule.KeyLot = &EmptyLinkKey
	|	AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)";
	
	QueryResults = Query.ExecuteBatch();
	
	Schedule = QueryResults[QueryResults.UBound()-2].Unload();
	Links = QueryResults[QueryResults.UBound()-1].Unload();
	Totals = QueryResults[QueryResults.UBound()].Unload();
	
	Schedule.Indexes.Add("KeyLot, ThisIsFinalLine");
	Schedule.Indexes.Add("KeyLot, Stage");
	Links.Indexes.Add("KeyLot");
	
	SearchStructureKeySummary = New Structure("KeyLot, ThisIsFinalLine", Undefined, True);
	SearchStructureKeyStage = New Structure("KeyLot, Stage");
	SearchStructureKey = New Structure("KeyLot");
	
	LeftLimit = ?(Totals.Count() = 1, Totals[0].Begin, '00010101');
	RequestedSupplyDateIsViolated = False;
	
	For IndexOf = 0 To Schedule.Count()-1 Do
		
		String = Schedule[IndexOf];
		
		If Not String.ThisIsFinalLine
			Or String.LeftLimit = null Then
			Continue;
		EndIf;
		
		SearchStructureKey.KeyLot = String.KeyLot;
		For Each LinkString In Links.FindRows(SearchStructureKey) Do
			
			SearchStructureKeySummary.KeyLot = LinkString.KeyPartyConsumer;
			For Each ConsumerRow In Schedule.FindRows(SearchStructureKeySummary) Do
				ConsumerRow.LeftLimit = Min(ConsumerRow.LeftLimit, String.LeftLimit);
				If String.RequestedSupplyDateIsViolated Then
					ConsumerRow.RequestedSupplyDateIsViolated = True;
				EndIf;
			EndDo;
			
			If Not LinkString.StageConsumer.IsEmpty() Then
				
				SearchStructureKeyStage.KeyLot = LinkString.KeyPartyConsumer;
				SearchStructureKeyStage.Stage = LinkString.StageConsumer;
				For Each ConsumerRow In Schedule.FindRows(SearchStructureKeyStage) Do
					ConsumerRow.LeftLimit = Min(ConsumerRow.LeftLimit, String.LeftLimit);
					If String.RequestedSupplyDateIsViolated Then
						ConsumerRow.RequestedSupplyDateIsViolated = True;
					EndIf;
				EndDo;
				
			EndIf;
			
		EndDo;
		
		LeftLimit = Min(LeftLimit, String.LeftLimit);
		If String.RequestedSupplyDateIsViolated Then
			RequestedSupplyDateIsViolated = True;
		EndIf;
		
	EndDo;
	
	// Final entry
	If Totals.Count() = 1 Then
		NewRow = Schedule.Add();
		NewRow.ProductionOrder = Parameters.ProductionOrder;
		NewRow.Stage = Catalogs.ProductionStages.EmptyRef();
		NewRow.LeftLimit = LeftLimit;
		NewRow.RequestedSupplyDateIsViolated = RequestedSupplyDateIsViolated;
		FillPropertyValues(NewRow, Totals[0], "Begin, Ending");
	EndIf;
	
	RecordSet = InformationRegisters.OrderMonitoringFullTargetScheduleInterval.CreateRecordSet();
	RecordSet.Filter.ProductionOrder.Set(Parameters.ProductionOrder);
	RecordSet.Load(Schedule);
	RecordSet.Write(True);
	
	Return Schedule.Count();
	
EndFunction

Function FullIntervalOfProductionSchedule(ProductionOrder) Export
	
	Query = New Query;
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.Text =
	"SELECT
	|	Schedule.LeftLimit AS LeftLimit,
	|	Schedule.Begin       AS Begin,
	|	Schedule.Ending    AS Ending
	|FROM
	|	InformationRegister.OrderMonitoringFullTargetScheduleInterval AS Schedule
	|WHERE
	|	Schedule.ProductionOrder = &ProductionOrder
	|	AND Schedule.KeyLot = &EmptyLinkKey
	|	AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
	|";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	Boundaries = New Structure("LeftLimit, Begin, Ending", '00010101', '00010101', '00010101');
	
	If Selection.Next() Then
		Boundaries.LeftLimit = ?(Not ValueIsFilled(Selection.LeftLimit), '00010101', Selection.LeftLimit);
		Boundaries.Begin = ?(Not ValueIsFilled(Selection.Begin), '00010101', Selection.Begin);
		Boundaries.Ending = ?(Not ValueIsFilled(Selection.Ending), '00010101', Selection.Ending);
	EndIf;
	
	Return Boundaries;
	
EndFunction

#EndRegion

#EndRegion

#Region Indicators

Function InformationLineIndicators(ProductionOrder, OutputParameters) Export
	
	Result = New Structure();
	
	Query = New Query;
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.SetParameter("WorkingDate", OutputParameters.WorkingDate);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.Text = 
	"SELECT
	|	COUNT(*) AS Count
	|FROM
	|(
	|SELECT TOP 101
	|	1
	|FROM
	|	InformationRegister.OrderStructure AS Products_1
	|WHERE
	|	Products_1.ProductionOrder = &ProductionOrder
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.TargetOrderStructureSchedule AS Schedule
	|		WHERE
	|			Schedule.ProductionOrder = &ProductionOrder
	|			AND Products_1.KeyLot = Schedule.KeyLot
	|			AND Products_1.Stage = Schedule.Stage
	|			AND Schedule.Begin <= &WorkingDate)
	|	AND Products_1.LineKind NOT IN (
	|			VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
	|			VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|			VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
	|
	|GROUP BY
	|	CASE
	|		WHEN Products_1.ConnectionKeyTransfer = &EmptyLinkKey THEN
	|				Products_1.KeyProducts
	|			ELSE
	|				Products_1.ConnectionKeyTransfer
	|		END
	|
	|HAVING
	|	SUM(Products_1.ToSupply - Products_1.Replaced) >
	|		SUM(CASE
	|			WHEN Products_1.ReceiptOrder = UNDEFINED AND Products_1.DateOfReceipt = DATETIME(1, 1, 1)
	|				THEN Products_1.AllocatedFromAvailableInventory + Products_1.AllocatedFromAvailableInventoryWithAssignment
	|			ELSE 0
	|		END)
	|) AS T
	|";
	
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	NumberOfPackages_ = QueryResult.Count();
	
	Result.Insert("NumberOfExpiredProducts", QueryResult[NumberOfPackages_-1].Unload()[0].Count);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion