
#Region Public

// Calculate the order schedule of the dynamic structure.
// 
// Parameters:
//  OrderDocument - DocumentRef.ProductionOrder2_2
//  Settings - Structure - Settings:
//   * ScheduleStatus - Number
//   * UseAvailabilityReserve - Boolean
//   * AllMaterialsInStock - Boolean
//   * UnlimitedEquipmentFleet - Boolean
//   * RoundTheClockWorkSevenDaysAWeek - Boolean
//   * NoOtherOrders - Boolean
//   * CancelManualChangesOfSchedule - Boolean
// 
// Returns:
//  Structure:
//   * ScheduleIsPlanned - Boolean
//   * Errors - ValueTable - :
//    ** LongDesc - String -
//    ** Details - Structure - :
//     *** ErrorCode - String
//   * Notifications - Map of String
//   * NumberOfStages - Number
//
Function CalculateTheSchedule(OrderDocument, Settings = Undefined) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"IntershopManagement2_2.OrderStructureCalculationOfProductionSchedule");
	
	SetPrivilegedMode(True);
	Result = ToCalculateScheduleInsideTimeMeasurement(OrderDocument, Settings);
	SetPrivilegedMode(False);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(
		MeasurementDetails,
		?(Result.NumberOfStages > 100, Round(Result.NumberOfStages/10), Result.NumberOfStages));
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

// Calculate the schedule of formed Lot references.
// 
// Parameters:
//  CalculationBoundary - Number - the queue number for which the order structure was calculated.
//
Procedure CalculateLotReferenceScheduleAtStartup(CalculationBoundary) Export
	
	TempTablesManager = New TempTablesManager;
	
	QueryTexts = New ValueList;
	
	#Region TTAllLaunchTasks
	
	QueryText =
		"SELECT
		|	Jobs.ProductionOrder AS ProductionOrder,
		|	Jobs.Separator         AS Separator,
		|	Jobs.ProductionStage    AS ProductionStage,
		|	Jobs.KeyLot          AS KeyLot,
		|	Jobs.Queue             AS Queue
		|INTO TTAllLaunchTasks
		|FROM
		|	InformationRegister.OrderStructureCalculationJobsProductionSchedule AS Jobs
		|WHERE
		|	Jobs.Queue > 0 AND Jobs.Queue <= &CalculationBoundary
		|
		|INDEX BY
		|	Queue";
	QueryTexts.Add(QueryText, "TTAllLaunchTasks");
	
	#EndRegion
	
	#Region TTCurrentQueues
	
	QueryText =
		"SELECT DISTINCT
		|	Jobs.Queue AS Queue
		|INTO TTCurrentQueues
		|FROM
		|	TTAllLaunchTasks AS Jobs
		|INDEX BY
		|	Queue";
	QueryTexts.Add(QueryText, "TTCurrentQueues");
	
	#EndRegion
	
	#Region TTBlockedQueues
	
	QueryText =
		"SELECT
		|	CurrentQueues.Queue AS Queue
		|INTO TTBlockedQueues
		|FROM
		|	TTCurrentQueues AS CurrentQueues
		|WHERE
		|	(TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM 
		|			InformationRegister.BufferOfOrderStructureCalculationTasksInventoryAllocation AS T
		|		WHERE
		|			CurrentQueues.Queue = T.Queue)
		|	OR TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM 
		|			InformationRegister.BufferOfTasksOfBOMOrderStructureCalculation AS T
		|		WHERE
		|			CurrentQueues.Queue = T.Queue)
		|	OR TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM 
		|			InformationRegister.JobsForAllocatingInventory AS T
		|		WHERE
		|			CurrentQueues.Queue = T.OrderStructureCalculationQueue))
		|INDEX BY
		|	Queue";
	QueryTexts.Add(QueryText, "TTBlockedQueues");
	
	#EndRegion
	
	#Region TTLaunchTasks
	
	QueryText =
		"SELECT
		|	Jobs.ProductionOrder AS ProductionOrder,
		|	Jobs.KeyLot          AS KeyLot,
		|	Jobs.Separator         AS Separator,
		|	Jobs.ProductionStage    AS ProductionStage
		|INTO TTLaunchTasks
		|FROM
		|	TTAllLaunchTasks AS Jobs
		|WHERE
		|	Jobs.Queue NOT IN (
		|		SELECT
		|			T.Queue
		|		FROM
		|			TTBlockedQueues AS T)
		|
		|INDEX BY
		|	ProductionOrder,
		|	KeyLot";
	QueryTexts.Add(QueryText, "TTLaunchTasks");
	
	#EndRegion
	
	#Region TTJobs
	
	QueryText =
		"SELECT
		|	Jobs.ProductionOrder AS ProductionOrder,
		|	Jobs.KeyLot          AS KeyLot,
		|	Jobs.Separator         AS Separator,
		|	Jobs.ProductionStage    AS ProductionStage
		|INTO TTJobs
		|FROM
		|	TTLaunchTasks AS Jobs
		|
		|UNION ALL
		|
		|SELECT
		|	Jobs.ProductionOrder AS ProductionOrder,
		|	Jobs.KeyLot          AS KeyLot,
		|	Jobs.Separator         AS Separator,
		|	Jobs.ProductionStage    AS ProductionStage
		|FROM
		|	InformationRegister.OrderStructureCalculationJobsProductionSchedule AS Jobs
		|WHERE
		|	(Jobs.ProductionOrder, Jobs.KeyLot) IN (
		|		SELECT
		|			T.ProductionOrder AS ProductionOrder,
		|			T.KeyLot          AS KeyLot
		|		FROM
		|			TTLaunchTasks AS T)
		|	AND Jobs.Queue = 0
		|
		|INDEX BY
		|	ProductionOrder,
		|	KeyLot";
	QueryTexts.Add(QueryText, "TTJobs");
	
	#EndRegion
	
	#Region OrderBoundariesTT
	
	// The right border of the planned orders
	QueryText = 
		"SELECT
		|	OrderStructure.ProductionOrder            AS ProductionOrder,
		|	MIN(OrderStructure.DurationBeforeProductionIssue) AS DurationBeforeProductionIssue
		|INTO OrderBoundariesTT
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	(OrderStructure.ProductionOrder, OrderStructure.KeyLot) IN (
		|		SELECT
		|			Jobs.ProductionOrder AS ProductionOrder,
		|			Jobs.KeyLot AS KeyLot
		|		FROM
		|			TTJobs AS Jobs)
		|
		|GROUP BY
		|	OrderStructure.ProductionOrder
		|
		|INDEX BY
		|	ProductionOrder";
	
	QueryTexts.Add(QueryText, "OrderBoundariesTT");
	
	#EndRegion
	
	#Region TTOrdersForRAndM
	
	TextSelectionOrders = 
		"&TextTableName.Ref IN (
		|	SELECT DISTINCT
		|		T.ProductionOrder AS Ref
		|	FROM
		|		TTJobs AS T)";
	QueryText = QueryTextTTRMOrders(TextSelectionOrders);
	QueryTexts.Add(QueryText, "TTOrdersForRAndM");
	
	#EndRegion
	
	#Region TTOrdersForRAndMToCalculationOfOrder
	
	// The order is inherited during the formation of Lot references of stages
	QueryText = 
		"SELECT TOP 0
		|	VALUE(Document.ProductionOrder2_2.EmptyRef) AS ProductionOrder
		|INTO TTOrdersForRAndMToCalculationOfOrder";
	QueryTexts.Add(QueryText, "TTOrdersForRAndMToCalculationOfOrder");
	
	#EndRegion
	
	#Region QueueOfOrders
	
	QueryTextFilter = "
		|	&TextTableName.Ref IN (
		|		SELECT
		|			T.ProductionOrder AS Ref
		|		FROM
		|			TTJobs AS T)
		|	AND &TextTableName.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
		|	AND &TextTableName.Posted";//@Query-part
	QueryText = QueryTextOrderData(QueryTextFilter, True);
	QueryTexts.Add(QueryText, "QueueOfOrders");
	
	#EndRegion
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CalculationBoundary", CalculationBoundary);
	
	SetPrivilegedMode(True);
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts,, True, False);
	SetPrivilegedMode(False);
	
	QueueOfOrders = Tables.QueueOfOrders;
	If QueueOfOrders.Count() = 0 Then
		Return;
	EndIf;
	
	Data = ReadStagesOfLotReferences(TempTablesManager);
	
	Links = Data.Links;
	TypesOfRC = Data.TypesOfRC;
	LoadingRCViews = Data.LoadingRCViews;
	PredecessorDates = Data.PredecessorDates;
	FollowerDates = Data.FollowerDates;
	
	QueryTexts.Clear();
	
	#Region Stages
	
	QueryText = 
		"SELECT
		|	&QueryTextAllFieldsOfStagesTable,
		|	ISNULL(StageBoundaries.RightBorder_, Stages.RightBorder_) AS RightBorder_,
		|	CASE
		|		WHEN StageBoundaries.RightBorder_ IS NOT NULL
		|			THEN TRUE
		|		ELSE Stages.ThereIsRightBorder
		|	END                                                      AS ThereIsRightBorder
		|FROM
		|	TTStages AS Stages
		|	
		|	LEFT JOIN TTBoundariesOfStages AS StageBoundaries
		|	ON Stages.KeyLot = StageBoundaries.KeyLot
		|		AND Stages.Stage = StageBoundaries.Stage
		|WHERE
		|	Stages.ProductionOrder = &OrderDocument
		|	AND Stages.KeyLot IN (
		|		SELECT
		|			T.KeyLot
		|		FROM
		|			TTJobs AS T
		|		WHERE
		|			T.ProductionOrder = &OrderDocument)
		|
		|ORDER BY
		|	Stages.RecNo";
	
	QueryText = StrReplace(QueryText, "&QueryTextAllFieldsOfStagesTable", "Stages.*");
	
	QueryTexts.Add(QueryText, "Stages");
	
	#EndRegion
	
	#Region TypesOfRCLinks
	
	QueryText = 
		"SELECT DISTINCT
		|	TypesOfRC.WorkCenterType AS Ref
		|FROM
		|	TTTypesOfRC AS TypesOfRC
		|WHERE
		|	TypesOfRC.ProductionOrder = &OrderDocument";
	QueryTexts.Add(QueryText, "TypesOfRCLinks");
	
	#EndRegion
	
	#Region Departments
	
	QueryText = 
		"SELECT DISTINCT
		|	Stages.Department AS Ref
		|FROM
		|	TTStages AS Stages
		|WHERE
		|	Stages.ProductionOrder = &OrderDocument";
	QueryTexts.Add(QueryText, "Departments");
	
	#EndRegion
	
	SearchKeyLotReferenceStage = New Structure("KeyLot, Stage");
	SearchForRecordNumber = New Structure("RecNo");
	VRCSearch = New Structure("ThisIsIndex, WorkCenterType, IntervalDate", False);
	
	For Each OrderRow In QueueOfOrders Do
		OrderDocument = OrderRow.ProductionOrder;
		
		// Calculation data
		PaymentData = NewCalculationData();
		FillPropertyValues(PaymentData.OrderDetails, OrderRow);
		
		// Reading order data
		Query.SetParameter("OrderDocument", OrderDocument);
		Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts,, True, False);
		
		Stages = Tables.Stages; // ValueTable
		Stages.Indexes.Add("KeyLot, Stage");
		PaymentData.Stages = Stages;
		
		PaymentData.Links = Links;
		PaymentData.TypesOfRC = TypesOfRC;
		PaymentData.StagesWithManualPlacement = New Array;
		
		// Calculation parameters
		CalculationParameters = NewCalculationParameters();
		CalculationParameters.OrderDocument = OrderDocument;
		CalculationParameters.UseAvailabilityReserve = OrderRow.UseAvailabilityReserve;
		
		// Read Availability
		CalculationParameters.AvailabilityUnitSelection = Tables.Departments.UnloadColumn("Ref");
		
		FilterVRC = Tables.TypesOfRCLinks.UnloadColumn("Ref");
		If FilterVRC.Count() = 0 Then
			FilterVRC.Add(Catalogs.WorkCenterTypes.EmptyRef());
		EndIf;
		CalculationParameters.AvailabilityVRCSelection = FilterVRC;
		
		CalculationParameters.AvailabilityIntervalStart = BegOfDay(CurrentSessionDate());
		CalculationParameters.AvailabilityIntervalEnding = EndOfMonth(AddMonth(CurrentSessionDate(), 3));
		
		ReadAvailability(OrderDocument, PaymentData, CalculationParameters);
		
		// Calculation
		For IndexOf = 0 To Stages.Count()-1 Do
			StageString = Stages[IndexOf];
			If Not StageString.ToPlan_2 Then
				Continue;
			EndIf;
			
			// Adjusting availability
			SearchForRecordNumber.RecNo = StageString.RecNo;
			For Each LoadingLine In LoadingRCViews.FindRows(SearchForRecordNumber) Do
				FillPropertyValues(VRCSearch, LoadingLine, "WorkCenterType, IntervalDate");
				AvailabilityLines = PaymentData.WCKAvailability.FindRows(VRCSearch);
				If AvailabilityLines.Count() <> 0 Then
					AvailabilityLines[0].AvailableLoadingTime = AvailabilityLines[0].AvailableLoadingTime - LoadingLine.BusyLoadingTime;
					AvailabilityLines[0].Available_Time = AvailabilityLines[0].Available_Time - LoadingLine.TimeBusy;
				EndIf;
			EndDo;
			
			PostStage = True;
			
			// Inheritance of predecessor dates
			SearchKeyLotReferenceStage.KeyLot = StageString.KeyLot;
			SearchKeyLotReferenceStage.Stage = StageString.Stage;
			For Each LinkString In Links.FindRows(SearchKeyLotReferenceStage) Do
				SearchKeyLotReferenceStage.KeyLot = LinkString.KeyIsPredecessorParty;
				SearchKeyLotReferenceStage.Stage = LinkString.PredecessorStage;
				
				PredecessorLines = Stages.FindRows(SearchKeyLotReferenceStage);
				If PredecessorLines.Count() = 0 Then
					PredecessorLines = PredecessorDates.FindRows(SearchKeyLotReferenceStage);
				EndIf;
				If PredecessorLines.Count() = 0 Then
					Continue;
				EndIf;
				PredecessorStage = PredecessorLines[0];
				
				If Not ValueIsFilled(PredecessorStage.Ending) Then
					PostStage = False;
					Break;
				Else
					StageString.StartOfPlacement = Max(
						StageString.StartOfPlacement,
						?(PredecessorStage.Begin <> PredecessorStage.Ending,
							PredecessorStage.Ending + 1,
							PredecessorStage.Ending));
				EndIf;
			EndDo;
			
			// Stage placement
			If PostStage Then
				If StageString.PlanTypesOfRC Then
					PlaceStageByTypeOfRC(PaymentData, CalculationParameters, StageString);
				Else
					PlaceStageByDuration(PaymentData, CalculationParameters, StageString, True);
				EndIf;
			EndIf;
			
			// Inheritance of the beginning of the next (unplanned) stage
			SearchKeyLotReferenceStage.KeyLot = StageString.KeyLot;
			SearchKeyLotReferenceStage.Stage = StageString.Stage;
			FoundRows = FollowerDates.FindRows(SearchKeyLotReferenceStage);
			If FoundRows.Count() <> 0 Then
				StageString.NextStageStart = FoundRows[0].NextStageStart;
			EndIf;
		EndDo;
		
		StepsToDelete = Stages.FindRows(New Structure("Ending", '00010101'));
		KeysOfLotReferencesScheduleIsNotCalculated = Stages.Copy(StepsToDelete, "KeyLot").UnloadColumn("KeyLot");
		For Each Stage In StepsToDelete Do
			If Stage.PlanTypesOfRC Then
				FillPropertyValues(SearchKeyLotReferenceStage, Stage);
				For Each String In PaymentData.LoadingVRC.FindRows(SearchKeyLotReferenceStage) Do
					PaymentData.LoadingVRC.Delete(String);
				EndDo;
			EndIf;
			Stages.Delete(Stage);
		EndDo;
		
		If Stages.Count() > 0 Then
			#Region Jobs
			
			QueryText = 
				"SELECT DISTINCT
				|	Jobs.KeyLot AS KeyLot
				|INTO TTKeysToCalculatingTotals
				|FROM
				|	TTJobs AS Jobs
				|WHERE
				|	Jobs.ProductionOrder = &OrderDocument
				|	AND Jobs.KeyLot IN (&KeysOfLotReferencesScheduleIsCalculated)
				|
				|INDEX BY
				|	KeyLot
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	Jobs.ProductionOrder AS ProductionOrder,
				|	Jobs.KeyLot          AS KeyLot,
				|	Jobs.Separator         AS Separator,
				|	Jobs.ProductionStage    AS ProductionStage
				|FROM
				|	TTJobs AS Jobs
				|WHERE
				|	Jobs.ProductionOrder = &OrderDocument
				|	AND Jobs.KeyLot NOT IN (&KeysOfLotReferencesScheduleIsNotCalculated)";
			
			Query.Text = QueryText;
			Query.SetParameter("KeysOfLotReferencesScheduleIsCalculated", Stages.UnloadColumn("KeyLot"));
			Query.SetParameter("KeysOfLotReferencesScheduleIsNotCalculated", KeysOfLotReferencesScheduleIsNotCalculated);
			
			TasksToDeleting = Query.Execute().Unload();
			
			#EndRegion
			
			If PaymentData.OrderDetails.ThisIsBuild Then
				ShiftStagesByDuration(PaymentData, CalculationParameters);
			EndIf;
			
			// Recording the schedule of stages
			Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
			Set.Load(Stages);
			Set.Write(ReplacementMode.Merge);
			
			// Calculation and recording of totals
			InformationRegisters.ScheduleOfProductionStages2_2.CalculateResultsOfLotReferences(
				OrderDocument, TempTablesManager, "TTKeysToCalculatingTotals");
			
			// Record Availability
			RecordVRCDownload(PaymentData, CalculationParameters, True);
			
			// Clearing tasks
			InformationRegisters.OrderStructureCalculationJobsProductionSchedule.DeleteTasks(TasksToDeleting);
			
			// Related actions
			AfterRecordingProductionSchedule(OrderDocument, Stages);
			
			// Deleting temporary tables
			Query.Text = "DROP TTKeysToCalculatingTotals";
			Query.Execute();
		EndIf;
		
		// The Lot references for which the calculation could not be performed are excluded from further
		// recalculation of the Lot references by zeroing the queue number
		If KeysOfLotReferencesScheduleIsNotCalculated.Count() > 0 Then
			Query.Text = 
				"SELECT
				|	Jobs.ProductionOrder AS ProductionOrder,
				|	Jobs.KeyLot          AS KeyLot,
				|	Jobs.Separator         AS Separator,
				|	Jobs.ProductionStage    AS ProductionStage,
				|	0                           AS Queue
				|FROM
				|	TTLaunchTasks AS Jobs
				|WHERE
				|	Jobs.ProductionOrder = &OrderDocument
				|	AND Jobs.KeyLot IN (&KeysOfLotReferencesScheduleIsNotCalculated)";
			Query.SetParameter("KeysOfLotReferencesScheduleIsNotCalculated", KeysOfLotReferencesScheduleIsNotCalculated);
			TasksToChange = Query.Execute().Unload();
			
			Set = InformationRegisters.OrderStructureCalculationJobsProductionSchedule.CreateRecordSet();
			Set.Load(TasksToChange);
			SetPrivilegedMode(True);
			Set.Write(ReplacementMode.Merge);
			SetPrivilegedMode(False);
		EndIf;
	EndDo;
	
	#Region InheritanceOfDatesInWorkPlanningStages
	
	Query.Text = 
		"SELECT
		|	Stages.ProductionOrder  AS ProductionOrder,
		|	Schedule.ScheduleStatus       AS ScheduleStatus,
		|	Stages.Stage                 AS Stage,
		|	Stages.KeyLot           AS KeyLot,
		|	MIN(Schedule.Begin)     AS Begin,
		|	MAX(Schedule.Ending) AS Ending
		|INTO TTDatesOfWorkPlanningStages
		|FROM
		|	TTStages AS Stages
		|
		|	INNER JOIN TTCommunication AS Links
		|	ON Stages.ProductionOrder = Links.ProductionOrder
		|		AND Stages.KeyLot = Links.KeyLot
		|		AND Stages.Stage = Links.Stage
		|
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Links.ProductionOrderPredecessor = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = 0
		|		AND Links.KeyIsPredecessorParty = Schedule.KeyLot
		|WHERE
		|	Stages.ProductionOrder IN (
		|		SELECT
		|			T.Ref AS ProductionOrder
		|		FROM
		|			TTOrdersForRAndM AS T)
		|	AND Stages.ThisIsWorkPlanning
		|	AND Links.KeyLot <> Links.KeyIsPredecessorParty
		|
		|GROUP BY
		|	Stages.ProductionOrder,
		|	Schedule.ScheduleStatus,
		|	Stages.Stage,
		|	Stages.KeyLot
		|
		|INDEX BY
		|	ProductionOrder, ScheduleStatus, Stage, KeyLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Schedule.ProductionOrder AS ProductionOrder,
		|	Schedule.ScheduleStatus       AS ScheduleStatus,
		|	Schedule.Stage                AS Stage,
		|	Schedule.KeyLot          AS KeyLot,
		|	Stages.Begin               AS Begin,
		|	Stages.Ending            AS Ending,
		|	Schedule.ProductionScheduling   AS ProductionScheduling,
		|	Schedule.Department       AS Department,
		|	Schedule.BillOfMaterials        AS BillOfMaterials,
		|	Schedule.QuantityOfBatches    AS QuantityOfBatches,
		|	Schedule.Order             AS Order,
		|	Schedule.LineKind           AS LineKind,
		|	Schedule.PlanNotEarlierThanStage       AS PlanNotEarlierThanStage,
		|	Schedule.PlanNotEarlierThanKeyLot AS PlanNotEarlierThanKeyLot
		|FROM
		|	TTDatesOfWorkPlanningStages AS Stages
		|
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Stages.ProductionOrder = Schedule.ProductionOrder
		|		AND Stages.ScheduleStatus = Schedule.ScheduleStatus
		|		AND Stages.Stage = Schedule.Stage
		|		AND Stages.KeyLot = Schedule.KeyLot
		|WHERE
		|	Stages.Begin <> Schedule.Begin
		|	OR Stages.Ending <> Schedule.Ending";
	
	Schedule = Query.Execute().Unload();
	If Schedule.Count() > 0 Then
		Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
		Set.Load(Schedule);
		Set.Write(ReplacementMode.Update);
	EndIf;
	
	#EndRegion
	
	#Region OrderControl
	
	Query.Text = 
		"SELECT DISTINCT
		|	Links.ProductionOrder AS ProductionOrder,
		|	Links.Stage                AS ProductionStage,
		|	Links.KeyLot          AS KeyLot
		|FROM
		|	TTCommunication AS Links
		|	
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS PredecessorSSchedule
		|	ON Links.ProductionOrderPredecessor = PredecessorSSchedule.ProductionOrder
		|		AND Links.KeyIsPredecessorParty = PredecessorSSchedule.KeyLot
		|		AND Links.PredecessorStage = PredecessorSSchedule.Stage
		|		AND PredecessorSSchedule.ScheduleStatus = 0
		|	
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Links.ProductionOrder = Schedule.ProductionOrder
		|		AND Links.KeyLot = Schedule.KeyLot
		|		AND Links.Stage = Schedule.Stage
		|		AND Schedule.ScheduleStatus = 0
		|	
		|	LEFT JOIN TTStages AS Stages
		|	ON Links.ProductionOrder = Stages.ProductionOrder
		|		AND Links.KeyLot = Stages.KeyLot
		|		AND Links.Stage = Stages.Stage
		|WHERE
		|	(Links.ProductionOrderPredecessor, Links.KeyIsPredecessorParty) IN (
		|		SELECT
		|			T.ProductionOrder AS ProductionOrderPredecessor,
		|			T.KeyLot          AS KeyIsPredecessorParty
		|		FROM
		|			TTJobs AS T
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			T.ProductionOrder AS ProductionOrderPredecessor,
		|			T.KeyLot          AS KeyIsPredecessorParty
		|		FROM
		|			TTDatesOfWorkPlanningStages AS T)
		|	AND (
		|		ISNULL(Stages.ThisIsWorkPlanning, FALSE) = FALSE
		|			AND PredecessorSSchedule.Ending > Schedule.Begin
		|		OR ISNULL(Stages.ThisIsWorkPlanning, FALSE) = TRUE
		|			AND PredecessorSSchedule.Ending > Schedule.Ending
		|	)";
	
	NewJobs = Query.Execute().Unload();
	If NewJobs.Count() > 0 Then
		InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddTasks(NewJobs);
	EndIf;
	
	#EndRegion
	
EndProcedure

// To transfer the schedule of "virtual" Lot references to the created documents to the production stage.
// Used when forming stages in cases where the schedule can be inherited.
// 
// Parameters:
//  Stages - ValueTable
//
Procedure RescheduleLotReferencesAtStartup(Stages) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Table.ProductionOrder AS ProductionOrder,
		|	Table.LotReferenceKeyIsOld    AS LotReferenceKeyIsOld,
		|	Table.LotReferenceKeyIsNew     AS LotReferenceKeyIsNew,
		|	Table.Ref              AS Ref,
		|	Table.Stage                AS Stage
		|INTO TTStages
		|FROM
		|	&StepsToTransferSchedule AS Table
		|INDEX BY
		|	ProductionOrder,
		|	LotReferenceKeyIsOld,
		|	Stage
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Load.Recorder       AS Recorder,
		|	Load.Period            AS Period,
		|	Load.WorkCenterType AS WorkCenterType,
		|	Load.IntervalDate     AS IntervalDate,
		|	SUM(Load.Busy)     AS Busy,
		|	Load.ReferenceOrder      AS ReferenceOrder,
		|	Load.Department     AS Department,
		|	Load.Shift             AS Shift,
		|	Load.KeyLot        AS KeyLot,
		|	Load.Stage              AS Stage
		|INTO TTLoadingOfRCTypes
		|FROM
		|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS Load
		|WHERE
		|	(Load.ReferenceOrder, Load.KeyLot) IN (
		|		SELECT
		|			T.ProductionOrder AS ProductionOrder,
		|			T.LotReferenceKeyIsOld    AS KeyLot
		|		FROM
		|			TTStages AS T)
		|GROUP BY
		|	Load.Recorder,
		|	Load.Period,
		|	Load.WorkCenterType,
		|	Load.IntervalDate,
		|	Load.ReferenceOrder,
		|	Load.Department,
		|	Load.Shift,
		|	Load.KeyLot,
		|	Load.Stage
		|HAVING
		|	SUM(Load.Busy) > 0
		|
		|INDEX BY
		|	ReferenceOrder,
		|	KeyLot,
		|	Stage
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Schedule.ProductionOrder             AS ProductionOrder,
		|	Schedule.ScheduleStatus                   AS ScheduleStatus,
		|	Stages.LotReferenceKeyIsNew                  AS KeyLot,
		|	Stages.Ref                           AS Stage,
		|	Schedule.LineKind                       AS LineKind,
		|	Schedule.Begin                          AS Begin,
		|	Schedule.Ending                       AS Ending,
		|	Schedule.PreliminaryBufferEnd AS PreliminaryBufferEnd,
		|	Schedule.FollowUpBufferStart        AS FollowUpBufferStart,
		|	Schedule.NextStageStart           AS NextStageStart,
		|	Schedule.OnCriticalPath               AS OnCriticalPath,
		|	Schedule.ItLimitsProductionDate         AS ItLimitsProductionDate,
		|	Schedule.MaterialLimited           AS MaterialLimited,
		|	Schedule.EquipmentLimited         AS EquipmentLimited,
		|	Schedule.ProductionScheduling               AS ProductionScheduling,
		|	Schedule.Department                   AS Department,
		|	Schedule.BillOfMaterials                    AS BillOfMaterials,
		|	Schedule.QuantityOfBatches                AS QuantityOfBatches,
		|	Schedule.Order                         AS Order,
		|	Schedule.PlanNotEarlierThanStage          AS PlanNotEarlierThanStage,
		|	Schedule.PlanNotEarlierThanKeyLot    AS PlanNotEarlierThanKeyLot
		|FROM
		|	TTStages AS Stages
		|
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Stages.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND Stages.LotReferenceKeyIsOld = Schedule.KeyLot
		|		AND Stages.Stage = Schedule.Stage
		|
		|UNION ALL
		|
		|SELECT
		|	Schedule.ProductionOrder                          AS ProductionOrder,
		|	Schedule.ScheduleStatus                                AS ScheduleStatus,
		|	Stages.LotReferenceKeyIsNew                               AS KeyLot,
		|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
		|	VALUE(Enum.ProductionScheduleRowKinds.Lot) AS LineKind,
		|	MIN(Schedule.Begin)                              AS Begin,
		|	MAX(Schedule.Ending)                          AS Ending,
		|	UNDEFINED                                        AS PreliminaryBufferEnd,
		|	UNDEFINED                                        AS FollowUpBufferStart,
		|	UNDEFINED                                        AS NextStageStart,
		|	UNDEFINED                                        AS OnCriticalPath,
		|	UNDEFINED                                        AS ItLimitsProductionDate,
		|	UNDEFINED                                        AS MaterialLimited,
		|	UNDEFINED                                        AS EquipmentLimited,
		|	UNDEFINED                                        AS ProductionScheduling,
		|	UNDEFINED                                        AS Department,
		|	UNDEFINED                                        AS BillOfMaterials,
		|	UNDEFINED                                        AS QuantityOfBatches,
		|	MIN(Schedule.Order)                             AS Order,
		|	UNDEFINED                                        AS PlanNotEarlierThanStage,
		|	UNDEFINED                                        AS PlanNotEarlierThanKeyLot
		|FROM
		|	TTStages AS Stages
		|
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Stages.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND Stages.LotReferenceKeyIsOld = Schedule.KeyLot
		|		AND Stages.Stage = Schedule.Stage
		|
		|GROUP BY
		|	Schedule.ProductionOrder,
		|	Schedule.ScheduleStatus,
		|	Stages.LotReferenceKeyIsNew
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Load.Recorder       AS Recorder,
		|	Load.Period            AS Period,
		|	Load.WorkCenterType AS WorkCenterType,
		|	Load.IntervalDate     AS IntervalDate,
		|	-Load.Busy           AS Busy,
		|	Load.ReferenceOrder      AS ReferenceOrder,
		|	Load.Department     AS Department,
		|	Load.Shift             AS Shift,
		|	Load.KeyLot        AS KeyLot,
		|	Load.Stage              AS Stage
		|FROM
		|	TTLoadingOfRCTypes AS Load
		|
		|UNION ALL
		|
		|SELECT
		|	Stages.Ref               AS Recorder,
		|	Load.Period            AS Period,
		|	Load.WorkCenterType AS WorkCenterType,
		|	Load.IntervalDate     AS IntervalDate,
		|	Load.Busy            AS Busy,
		|	Load.ReferenceOrder      AS ReferenceOrder,
		|	Load.Department     AS Department,
		|	Load.Shift             AS Shift,
		|	Stages.LotReferenceKeyIsNew      AS KeyLot,
		|	Stages.Ref               AS Stage
		|FROM
		|	TTStages AS Stages
		|
		|	INNER JOIN TTLoadingOfRCTypes AS Load
		|	ON Stages.ProductionOrder = Load.ReferenceOrder
		|		AND Stages.LotReferenceKeyIsOld = Load.KeyLot
		|		AND Stages.Stage = Load.Stage
		|
		|TOTALS BY
		|	Recorder";
	
	StatusWorkingSchedule = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	Query.SetParameter("StepsToTransferSchedule", Stages);
	Query.SetParameter("StatusWorkingSchedule", StatusWorkingSchedule);
	
	QueryResults = Query.ExecuteBatch();
	NumberOfResults = QueryResults.Count();
	
	// New Schedule
	Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
	Set.Load(QueryResults[NumberOfResults - 2].Unload());
	Set.Write(False);
	
	// Transferring availability
	SamplingLogger = QueryResults[NumberOfResults - 1].Select(QueryResultIteration.ByGroups);
	While SamplingLogger.Next() Do
		Set = AccumulationRegisters.AvailabilityOfWorkCenterTypes.CreateRecordSet();
		Set.Filter.Recorder.Set(SamplingLogger.Recorder);
		
		Selection = SamplingLogger.Select();
		While Selection.Next() Do
			FillPropertyValues(Set.Add(), Selection);
		EndDo;
		
		Set.Write(False);
	EndDo;
	
EndProcedure

// Transfer the Order of the "virtual" Lot references to the created documents to the production stage.
// It is relevant for the order stages with the type of Repair work.
// 
// Parameters:
//  Stages - ValueTable
//
Procedure MoveBatchOrderAtStartup(Stages) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Table.ProductionOrder AS ProductionOrder,
		|	Table.LotReferenceKeyIsOld    AS LotReferenceKeyIsOld,
		|	Table.LotReferenceKeyIsNew     AS LotReferenceKeyIsNew,
		|	Table.Ref              AS Ref,
		|	Table.Stage                AS Stage
		|INTO TTStages
		|FROM
		|	&StepsToTransferOrder AS Table
		|INDEX BY
		|	ProductionOrder,
		|	LotReferenceKeyIsOld,
		|	Stage
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Schedule.ProductionOrder AS ProductionOrder,
		|	Schedule.ScheduleStatus       AS ScheduleStatus,
		|	Stages.LotReferenceKeyIsNew      AS KeyLot,
		|	Stages.Ref               AS Stage,
		|	Schedule.LineKind           AS LineKind,
		|	Schedule.Department       AS Department,
		|	Schedule.BillOfMaterials        AS BillOfMaterials,
		|	Schedule.Order             AS Order,
		|	Schedule.PlanNotEarlierThanStage       AS PlanNotEarlierThanStage,
		|	Schedule.PlanNotEarlierThanKeyLot AS PlanNotEarlierThanKeyLot
		|FROM
		|	TTStages AS Stages
		|
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Stages.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND Stages.LotReferenceKeyIsOld = Schedule.KeyLot
		|		AND Stages.Stage = Schedule.Stage";
	
	StatusWorkingSchedule = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	Query.SetParameter("StepsToTransferOrder", Stages);
	Query.SetParameter("StatusWorkingSchedule", StatusWorkingSchedule);
	
	Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
	Set.Load(Query.Execute().Unload());
	Set.Write(False);
	
EndProcedure

// Replace the links to the "virtual" stages with links to the created documents of the Production stage.
// It is relevant for the order stages with the type of Repair work.
// 
// Parameters:
//  Stages - ValueTable
//
Procedure ReplaceReferencesToStagesAtStartup(Stages) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Table.ProductionOrder AS ProductionOrder,
		|	Table.LotReferenceKeyIsOld    AS LotReferenceKeyIsOld,
		|	Table.LotReferenceKeyIsNew     AS LotReferenceKeyIsNew,
		|	Table.Ref              AS Ref,
		|	Table.Stage                AS Stage
		|INTO TTStages
		|FROM
		|	&Stages AS Table
		|INDEX BY
		|	ProductionOrder,
		|	LotReferenceKeyIsOld,
		|	Stage
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Schedule.ProductionOrder             AS ProductionOrder,
		|	Schedule.ScheduleStatus                   AS ScheduleStatus,
		|	Schedule.Stage                            AS Stage,
		|	Schedule.KeyLot                      AS KeyLot,
		|	Schedule.Begin                          AS Begin,
		|	Schedule.Ending                       AS Ending,
		|	Schedule.PreliminaryBufferEnd AS PreliminaryBufferEnd,
		|	Schedule.FollowUpBufferStart        AS FollowUpBufferStart,
		|	Schedule.NextStageStart           AS NextStageStart,
		|	Schedule.OnCriticalPath               AS OnCriticalPath,
		|	Schedule.ItLimitsProductionDate         AS ItLimitsProductionDate,
		|	Schedule.MaterialLimited           AS MaterialLimited,
		|	Schedule.EquipmentLimited         AS EquipmentLimited,
		|	Schedule.ProductionScheduling               AS ProductionScheduling,
		|	Schedule.Department                   AS Department,
		|	Schedule.BillOfMaterials                    AS BillOfMaterials,
		|	Schedule.QuantityOfBatches                AS QuantityOfBatches,
		|	Schedule.Order                         AS Order,
		|	Schedule.LineKind                       AS LineKind,
		|	Stages.Ref                           AS PlanNotEarlierThanStage,
		|	Stages.LotReferenceKeyIsNew                  AS PlanNotEarlierThanKeyLot
		|FROM
		|	TTStages AS Stages
		|
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Stages.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND Stages.LotReferenceKeyIsOld = Schedule.PlanNotEarlierThanKeyLot
		|		AND Stages.Stage = Schedule.PlanNotEarlierThanStage";
	
	StatusWorkingSchedule = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	Query.SetParameter("Stages", Stages);
	Query.SetParameter("StatusWorkingSchedule", StatusWorkingSchedule);
	
	Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
	Set.Load(Query.Execute().Unload());
	Set.Write(ReplacementMode.Update);
	
EndProcedure

#Region WrappersForStartingCalculation

// Calculation of the schedule at the order planning workplace.
// 
// Parameters:
//  Settings - See DataProcessors.ProductionSchedulePlanning2_2.PreScheduleSchedulingSettings
//  StorageAddress - UUID, String - the address in the temporary storage
//		where you want to place the planning results.
//
Procedure CalculateWorkScheduleAndModel(Settings, StorageAddress) Export
	
	FileInfobase = Common.FileInfobase();
	
	NotificationStatusOfStructureCalculation = "";
	If Not FileInfobase Then
		ExpectEndOfOrderStructureCalculation(Settings.ProductionOrder, NotificationStatusOfStructureCalculation);
	EndIf;
	
	GraphResults_ = Undefined;
	ChartSettings = Undefined;
	If Settings.PlanSchedule Then
		ChartSettings = Common.CopyRecursive(Settings);
		ChartSettings.Insert("ScheduleStatus",
			InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
		ChartSettings.Insert("UseAvailabilityReserve",
			Settings.ActivateTheAvailabilityReserveSchedule);
	EndIf;
	
	ModelResults = Undefined;
	SettingsModel = Undefined;
	If Settings.PlanModel Then
		SettingsModel = Common.CopyRecursive(Settings);
		SettingsModel.Insert("ScheduleStatus",
			InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel());
		SettingsModel.Insert("UseAvailabilityReserve",
			Settings.ActivateTheAvailabilityReserveModel);
	EndIf;
	
	ParallelCalculation = Not FileInfobase
		And Settings.PlanSchedule
		And Settings.PlanModel;
	If ParallelCalculation Then
		// Starting The Calculation
		CalculationQueue = New Array;
		
		For Cnt = 1 To 2 Do
			ProcedureParameters = New Structure;
			ProcedureParameters.Insert("OrderDocument", ChartSettings.ProductionOrder);
			ProcedureParameters.Insert("Settings", ?(Cnt = 1, ChartSettings, SettingsModel));
			
			ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Undefined);
			ExecutionParameters.BackgroundJobDescription = ?(Cnt = 1,
				NStr("vi = 'Tính toán lịch biểu (%1)';
					|ru = 'Расчет графика (%1)';
					|en = 'Create schedule (%1)'; fa = 'Create schedule (%1)';
					|it = 'Расчет графика (%1)';
					|pl = 'Create schedule (%1)';
					|tr = 'Grafik hesaplaması (%1)'"),
				NStr("vi = 'Tính toán mô hình lịch biểu (%1)';
					|ru = 'Расчет модели графика (%1)';
					|en = 'Create schedule model (%1)'; fa = 'Create schedule model (%1)';
					|it = 'Расчет модели графика (%1)';
					|pl = 'Create schedule model (%1)';
					|tr = 'Grafik modeli hesaplaması (%1)'"));
			ExecutionParameters.ResultAddress = PutToTempStorage(Undefined, New UUID);
			
			RunResult = TimeConsumingOperations.ExecuteInBackground(
				"OrderStructureProductionSchedule.CalculateGraphInBackground",
				ProcedureParameters,
				ExecutionParameters);
			
			If RunResult.Status = "Running" Then
				QueueItem = New Structure;
				QueueItem.Insert("Id", RunResult.JobID);
				QueueItem.Insert("ResultAddress", RunResult.ResultAddress);
				QueueItem.Insert("ThisIsCalculationOfGraph", Cnt = 1);
				CalculationQueue.Add(QueueItem);
			Else
				If RunResult.Status = "Completed2" Then
					If Cnt = 1 Then
						GraphResults_ = GetFromTempStorage(RunResult.ResultAddress);
					Else
						ModelResults = GetFromTempStorage(RunResult.ResultAddress);
					EndIf;
				Else
					Raise RunResult.DetailErrorDescription;
				EndIf;
			EndIf;
		EndDo;
		
		// Waiting for completion
		CalculationIsCompleted = False;
		IntervalForCheckingCompletionOfCalculation = 2;
		FilterStructure1 = New Structure();
		
		SetPrivilegedMode(True);
		While Not CalculationIsCompleted Do
			ActiveTasks = New Array();
			
			For Stream = 0 To CalculationQueue.UBound() Do
				If CalculationQueue[Stream] = Undefined Then
					Continue;
				EndIf;
				
				QueueItem = CalculationQueue[Stream]; // Structure
				FilterStructure1.Insert("UUID", QueueItem.Id);
				JobsList = BackgroundJobs.GetBackgroundJobs(FilterStructure1);
				
				If JobsList.UBound() <> -1 Then
					If JobsList[0].State = BackgroundJobState.Active Then
						ActiveTasks.Add(JobsList[0].UUID);
						Continue;
					EndIf;
					
					If JobsList[0].State = BackgroundJobState.Failed Then
						Raise ErrorProcessing.DetailErrorDescription(JobsList[0].ErrorInfo);
					EndIf;
				EndIf;
				
				If QueueItem.ThisIsCalculationOfGraph Then
					GraphResults_ = GetFromTempStorage(QueueItem.ResultAddress);
				Else
					ModelResults = GetFromTempStorage(QueueItem.ResultAddress);
				EndIf;
				
				CalculationQueue[Stream] = Undefined;
			EndDo;
			
			CalculationIsCompleted = Not ValueIsFilled(ActiveTasks);
			If Not CalculationIsCompleted Then
				Job = BackgroundJobs.FindByUUID(ActiveTasks[0]);
				If Job <> Undefined Then
					Job.WaitForExecutionCompletion(IntervalForCheckingCompletionOfCalculation);
				EndIf;
			EndIf;
		EndDo;
		SetPrivilegedMode(False);
		
	Else
		If Settings.PlanSchedule Then
			GraphResults_ = CalculateTheSchedule(ChartSettings.ProductionOrder, ChartSettings);
		EndIf;
		
		If Settings.PlanModel Then
			ModelResults = CalculateTheSchedule(SettingsModel.ProductionOrder, SettingsModel);
		EndIf;
	EndIf;
	
	Result = New Structure;
	
	Errors = New ValueTable;
	Errors.Columns.Add("LongDesc", New TypeDescription("String"));
	Errors.Columns.Add("Details");
	Errors.Columns.Add("Key");
	Errors.Columns.Add("ScheduleStatus", New TypeDescription("Number"));
	
	Notifications = New Map;
	
	If Not IsBlankString(NotificationStatusOfStructureCalculation) Then
		Notifications.Insert(NotificationStatusOfStructureCalculation, Settings.ProductionOrder);
	EndIf;
	
	If GraphResults_ <> Undefined Then
		Result.Insert("ScheduleIsPlanned", GraphResults_.ScheduleIsPlanned);
		
		For Each String In GraphResults_.Errors Do
			FillPropertyValues(Errors.Add(), String);
		EndDo;

		For Each KeyAndValue In GraphResults_.Notifications Do
			Notifications.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	Else
		Result.Insert("ScheduleIsPlanned", False);
	EndIf;
	
	If ModelResults <> Undefined Then
		Result.Insert("ModelIsPlanned", ModelResults.ScheduleIsPlanned);
		
		For Each String In ModelResults.Errors Do
			FillPropertyValues(Errors.Add(), String);
		EndDo;

		For Each KeyAndValue In ModelResults.Notifications Do
			Notifications.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	Else
		Result.Insert("ModelIsPlanned", False);
	EndIf;
	
	Result.Insert("Errors", Errors);
	Result.Insert("Notifications", Notifications);
	
	// Properties for compatibility
	Result.Insert("PlacedStages", New Array);
	Result.Insert("NumberOfJobForCalculatingProductionSchedule", 0);
	Result.Insert("CancelManualChangesOfSchedule", False);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Procedure CalculateGraphInBackground(Parameters, ResultAddress) Export
	
	Result = CalculateTheSchedule(Parameters.OrderDocument, Parameters.Settings);
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

// Run in the background the calculation of the schedule of generated Lot references.
// 
// Parameters:
//  CalculationBoundary - Number - the queue number for which the order structure was calculated.
//
Procedure RunCalculationOfLotReferenceSchedule(CalculationBoundary) Export
	
	ExportProcedureName = "OrderStructureProductionSchedule.CalculateLotReferenceScheduleAtStartup";
	
	ExportProcedureParameters = New Array();
	ExportProcedureParameters.Add(CalculationBoundary);
	
	If Common.DebugMode()
		Or Common.FileInfobase() Then
		Common.ExecuteConfigurationMethod(ExportProcedureName, ExportProcedureParameters);
		Return;
	EndIf;
	
	Var_Key = "CalculationOfLotReferenceScheduleAtStartup";
	Filter = New Structure("Key, State", Var_Key, BackgroundJobState.Active);
	
	SetPrivilegedMode(True);
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	SetPrivilegedMode(False);
	
	If ActiveTasks.Count() > 0 Then
		Return;
	EndIf;
	
	JobDescription = NStr("vi = 'Tính toán lịch biểu lô hàng khi khởi động vào sản xuất';
							|ru = 'Расчет графика партий при запуске в производство';
							|en = 'Calculation of lot schedule at production launch'; fa = 'Calculation of lot schedule at production launch';
							|it = 'Calculation of lot schedule at production launch';
							|pl = 'Calculation of lot schedule at production launch';
							|tr = 'Üretimin başında lot programının muhasebesi'");
	
	Try
		BackgroundJobs.Execute(
			ExportProcedureName,
			ExportProcedureParameters,
			Var_Key,
			JobDescription);
	Except
		Return; // the task is already running
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region IsMain

// Calculates the schedule of all stages of the order.
//
Function ToCalculateScheduleInsideTimeMeasurement(OrderDocument, Settings)
	
	CalculationParameters = NewCalculationParameters(Settings);
	CalculationParameters.OrderDocument = OrderDocument;
	
	// Reading data
	PaymentData = NewCalculationData();
	ReadUpdateOrderDetails(OrderDocument, PaymentData, CalculationParameters);
	ReadOrderSteps(OrderDocument, PaymentData, CalculationParameters);
	ReadAvailability(OrderDocument, PaymentData, CalculationParameters);
	
	Stages = PaymentData.Stages; // ValueTable
	Links = PaymentData.Links; // ValueTable
	
	// Cancellation of manual placement
	If CalculationParameters.CancelManualChangesOfSchedule
		And PaymentData.StagesWithManualPlacement.Count() > 0 Then
		Documents.ProductionStage2_2.CancelManualPlacementOfStagesInSchedule(
			PaymentData.StagesWithManualPlacement);
	EndIf;
	
	// Calculation
	SearchStage = CalculationParameters.KeyLotReferenceStage;
	SearchRAndM = ?(PaymentData.OrderDetails.ThisIsRepair, New Structure("KeyIsLotReferenceRAndM"), Undefined);
	ProcessingQueue = ?(PaymentData.OrderDetails.ThisIsRepair, New Array, Undefined);
	
	For IndexOf = 0 To Stages.Count()-1 Do
		StageString = Stages[IndexOf];
		If Not StageString.ToPlan_2 Then
			Continue;
		EndIf;
		
		// Inheritance of predecessor dates
		SearchStage.KeyLot = StageString.KeyLot;
		SearchStage.Stage = StageString.Stage;
		For Each LinkString In Links.FindRows(SearchStage) Do
			SearchStage.KeyLot = LinkString.KeyIsPredecessorParty;
			SearchStage.Stage = LinkString.PredecessorStage;
			
			PredecessorLines = Stages.FindRows(SearchStage);
			If PredecessorLines.Count() <> 0 Then
				StageString.StartOfPlacement = Max(
					StageString.StartOfPlacement,
					?(PredecessorLines[0].Begin <> PredecessorLines[0].Ending,
						PredecessorLines[0].Ending + 1,
						PredecessorLines[0].Ending));
			EndIf;
		EndDo;
		
		// Stage placement
		If StageString.PlanTypesOfRC Then
			PlaceStageByTypeOfRC(PaymentData, CalculationParameters, StageString);
		Else
			PlaceStageByDuration(PaymentData, CalculationParameters, StageString, True);
		EndIf;
		
		// Inheritance of R&M dates in the work planning stage
		If PaymentData.OrderDetails.ThisIsRepair
			And StageString.Ending <> '00010101'
			And (StageString.ThisIsInitialStageOfRepair
				Or StageString.NextStageNo = 0 And Not StageString.ItIsTransfer) Then
			ProcessingQueue.Add(StageString);
			
			While ProcessingQueue.Count() > 0 Do
				QueueItem = ProcessingQueue[0]; // ValueTableRow
				
				SearchRAndM.KeyIsLotReferenceRAndM = QueueItem.KeyLot;
				For Each LinkString In PaymentData.RepairLinks.FindRows(SearchRAndM) Do
					FillPropertyValues(SearchStage, LinkString);
					RowsStages = Stages.FindRows(SearchStage);
					If RowsStages.Count() = 0 Then
						Continue;
					EndIf;
					
					WorkPlanningStage = RowsStages[0];
					If WorkPlanningStage.Begin = '00010101' Then
						FillPropertyValues(WorkPlanningStage, QueueItem, "Begin, Ending");
					Else
						WorkPlanningStage.Begin = Min(WorkPlanningStage.Begin, QueueItem.Begin);
						WorkPlanningStage.Ending = Max(WorkPlanningStage.Ending, QueueItem.Ending);
					EndIf;
					If WorkPlanningStage.ThisIsInitialStageOfRepair Then
						ProcessingQueue.Add(WorkPlanningStage);
					EndIf;
				EndDo;
				
				ProcessingQueue.Delete(0);
			EndDo;
		EndIf;
	EndDo;
	
	ScheduleIsPlanned = Stages.Count() > 0
		And CalculationParameters.Errors.Count() = 0;
	
	If ScheduleIsPlanned Then
		If PaymentData.OrderDetails.ThisIsBuild Then
			ShiftStagesByDuration(PaymentData, CalculationParameters);
		EndIf;
		RecordOrderSchedule(PaymentData, CalculationParameters);
	EndIf;
	
	Result = New Structure;
	Result.Insert("ScheduleIsPlanned", ScheduleIsPlanned);
	Result.Insert("Errors", CalculationParameters.Errors);
	Result.Insert("Notifications", CalculationParameters.Notifications);
	Result.Insert("NumberOfStages", Stages.Count());
	
	Return Result;
	
EndFunction

Procedure ShiftStagesByDuration(PaymentData, CalculationParameters)
	
	Stages = PaymentData.Stages; // ValueTable
	Links = PaymentData.Links; // ValueTable
	
	Stages.FillValues('00010101', "StartOfPlacement");
	
	TheStructureOfTheSearch = New Structure("ThereIsRightBorder, ShiftToRight", True, True);
	For Each StageString In Stages.FindRows(TheStructureOfTheSearch) Do
		StageString.StartOfPlacement = StageString.RightBorder_;
	EndDo;
	
	TheStructureOfTheSearch = CalculationParameters.KeyLotReferenceStage;
	
	For IndexOf = -(Stages.Count()-1) To 0 Do
		StageString = Stages[-IndexOf];
		
		If StageString.ShiftToRight
			And StageString.StartOfPlacement <> '00010101'
			And StageString.StartOfPlacement > StageString.Ending + 1 Then
			PlaceStageByDuration(PaymentData, CalculationParameters, StageString, False);
		EndIf;
		
		TheStructureOfTheSearch.KeyLot = StageString.KeyLot;
		TheStructureOfTheSearch.Stage = StageString.Stage;
		For Each LinkString In Links.FindRows(TheStructureOfTheSearch) Do
			TheStructureOfTheSearch.KeyLot = LinkString.KeyIsPredecessorParty;
			TheStructureOfTheSearch.Stage = LinkString.PredecessorStage;
			
			PredecessorRows = Stages.FindRows(TheStructureOfTheSearch);
			If PredecessorRows.Count() = 0 Then
				Continue;
			EndIf;
			
			StringPredecessor = PredecessorRows[0];
			
			StringPredecessor.NextStageStart = ?(StringPredecessor.NextStageStart = '00010101',
				StageString.Begin,
				Min(StringPredecessor.NextStageStart, StageString.Begin));
			
			If Not StringPredecessor.ShiftToRight Then
				Continue;
			ElsIf StringPredecessor.StartOfPlacement = '00010101' Then
				StringPredecessor.StartOfPlacement = StageString.Begin;
			Else
				StringPredecessor.StartOfPlacement = Min(
					StringPredecessor.StartOfPlacement,
					StageString.Begin);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Procedure RecordOrderSchedule(PaymentData, CalculationParameters)
	
	OrderDocument = CalculationParameters.OrderDocument;
	
	Query = New Query;
	Query.SetParameter("OrderDocument", OrderDocument);
	Query.SetParameter("ScheduleStatus", CalculationParameters.ScheduleStatus);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("CancelManualChangesOfSchedule", CalculationParameters.CancelManualChangesOfSchedule);
	
	WriteMode = Undefined;
	Stages = PaymentData.Stages; //ValueTable
	KeysOfLotReferencesToCalculationOfTotals = Undefined;
	
	If CalculationParameters.ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel() Then
		WriteMode = ReplacementMode.Replace;
	Else
		Query.Text = 
			"SELECT TOP 1
			|	TRUE AS ThereAreRecords
			|FROM
			|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
			|WHERE
			|	Schedule.ProductionOrder = &OrderDocument
			|	AND Schedule.ScheduleStatus = &ScheduleStatus";
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			WriteMode = ReplacementMode.Append;
		Else
			WriteMode = ReplacementMode.Merge;
			Stages = Stages.Copy(New Structure("ScheduleIsChanged", True));
			
			If Stages.Count() = 0 Then
				InformationRegisters.OrderStructureCalculationJobsProductionSchedule.DeleteTasks(PaymentData.Jobs);
				Return;
			EndIf;
			
			KeysOfLotReferencesToCalculationOfTotals = Stages.UnloadColumn("KeyLot");
		EndIf;
	EndIf;
	
	// Recording the schedule of stages
	Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
	If WriteMode = ReplacementMode.Replace Then
		Set.Filter.ProductionOrder.Set(OrderDocument);
		Set.Filter.ScheduleStatus.Set(CalculationParameters.ScheduleStatus);
	EndIf;
	Set.Load(Stages);
	Set.Write(WriteMode);
	
	// Calculation and recording of totals
	SummaryRecordingMode = ?(WriteMode = ReplacementMode.Replace, ReplacementMode.Append, WriteMode);
	
	QueryText = 
		"SELECT
		|	Schedule.ProductionOrder      AS ProductionOrder,
		|	Schedule.ScheduleStatus            AS ScheduleStatus,
		|	Schedule.KeyLot               AS KeyLot,
		|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
		|	VALUE(Enum.ProductionScheduleRowKinds.Lot) AS LineKind,
		|	MIN(Schedule.Begin)          AS Begin,
		|	MAX(Schedule.Ending)      AS Ending,
		|	MIN(Schedule.Order)         AS Order
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|WHERE
		|	Schedule.ProductionOrder = &OrderDocument
		|	AND Schedule.ScheduleStatus = &ScheduleStatus
		|	AND Schedule.Stage <> VALUE(Catalog.ProductionStages.EmptyRef)
		|	AND &QueryTextFilterPartyKeys
		|
		|GROUP BY
		|	Schedule.ProductionOrder,
		|	Schedule.ScheduleStatus,
		|	Schedule.KeyLot
		|
		|UNION ALL
		|
		|SELECT
		|	Schedule.ProductionOrder      AS ProductionOrder,
		|	Schedule.ScheduleStatus            AS ScheduleStatus,
		|	&EmptyLinkKey                AS KeyLot,
		|	VALUE(Catalog.ProductionStages.EmptyRef) AS Stage,
		|	VALUE(Enum.ProductionScheduleRowKinds.OrderDocument) AS LineKind,
		|	MIN(Schedule.Begin)          AS Begin,
		|	MAX(Schedule.Ending)      AS Ending,
		|	0                               AS Order
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|WHERE
		|	Schedule.ProductionOrder = &OrderDocument
		|	AND Schedule.ScheduleStatus = &ScheduleStatus
		|
		|GROUP BY
		|	Schedule.ProductionOrder,
		|	Schedule.ScheduleStatus";
	
	QueryTextFilterPartyKeys = ?(KeysOfLotReferencesToCalculationOfTotals = Undefined,
		"TRUE",
		"Schedule.KeyLot IN (&KeysOfLotReferencesToCalculationOfTotals)");
	QueryText = StrReplace(QueryText, "&QueryTextFilterPartyKeys", QueryTextFilterPartyKeys);
	
	Query.Text = QueryText;
	Query.SetParameter("KeysOfLotReferencesToCalculationOfTotals", KeysOfLotReferencesToCalculationOfTotals);
	
	Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
	Set.Load(Query.Execute().Unload());
	Set.Write(SummaryRecordingMode);
	
	// Record Availability
	If CalculationParameters.ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule() Then
		RecordVRCDownload(PaymentData, CalculationParameters, False);
	Else
		PaymentData.LoadingVRC.GroupBy("Stage, WorkCenterType, IntervalDate, KeyLot, Shift", "Busy");
		InformationRegisters.CreatingScheduleForWorkCenterTypes.RecordPlanningResults(
			OrderDocument, CalculationParameters.ScheduleStatus, PaymentData.LoadingVRC);
	EndIf;
	
	// Clearing tasks
	InformationRegisters.OrderStructureCalculationJobsProductionSchedule.DeleteTasks(PaymentData.Jobs);
	
	// Related actions
	If CalculationParameters.ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule() Then
		AfterRecordingProductionSchedule(OrderDocument, Stages);
	EndIf;
	
EndProcedure

// Record the VRC download.
// 
// Parameters:
//  PaymentData - See NewCalculationData
//  CalculationParameters - See NewCalculationParameters
//  FilterByStages - Boolean - if False, the download will be updated for all stages of the order,
//    if True, then only for the stages in the data table of the account.Downloadcavrc.
//
Procedure RecordVRCDownload(PaymentData, CalculationParameters, FilterByStages)
	
	SetPrivilegedMode(True);
	
	LoadingVRC = PaymentData.LoadingVRC;
	StagesWithManualPlacement = PaymentData.StagesWithManualPlacement;
	
	QueryText = 
		"SELECT
		|	BEGINOFPERIOD(Load.IntervalDate, DAY) AS Period,
		|	Load.WorkCenterType                  AS WorkCenterType,
		|	Load.IntervalDate                      AS IntervalDate,
		|	Load.Busy                             AS Busy,
		|	Load.ReferenceOrder                       AS ReferenceOrder,
		|	Load.Department                      AS Department,
		|	Load.Shift                              AS Shift,
		|	Load.KeyLot                         AS KeyLot,
		|	Load.Stage                               AS Stage
		|INTO TTNewSchedule
		|FROM
		|	&LoadingVRC AS Load
		|
		|INDEX BY
		|	Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Recorder.Date             AS Period,
		|	MAX(Recorder.Ref) AS Ref
		|INTO TTRecorders_
		|FROM
		|	Document.ProductionScheduleRecorder AS Recorder
		|WHERE
		|	Recorder.Posted
		|	AND Recorder.Date IN (
		|		SELECT DISTINCT
		|			T.Period AS Date
		|		FROM
		|			TTNewSchedule AS T)
		|
		|GROUP BY
		|	Recorder.Date
		|
		|INDEX BY
		|	Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Recorder       AS Recorder,
		|	NestedQuery.Period            AS Period,
		|	NestedQuery.WorkCenterType AS WorkCenterType,
		|	NestedQuery.IntervalDate     AS IntervalDate,
		|	SUM(NestedQuery.Busy)     AS Busy,
		|	NestedQuery.ReferenceOrder      AS ReferenceOrder,
		|	NestedQuery.Department     AS Department,
		|	NestedQuery.Shift             AS Shift,
		|	NestedQuery.KeyLot        AS KeyLot,
		|	NestedQuery.Stage              AS Stage
		|FROM
		|	(
		|		SELECT
		|			CASE
		|				WHEN NewSchedule_.Stage REFS Document.ProductionStage2_2
		|					THEN NewSchedule_.Stage
		|				ELSE ISNULL(Recorders.Ref, VALUE(Document.ProductionScheduleRecorder.EmptyRef))
		|			END                         AS Recorder,
		|			NewSchedule_.Period            AS Period,
		|			NewSchedule_.WorkCenterType AS WorkCenterType,
		|			NewSchedule_.IntervalDate     AS IntervalDate,
		|			NewSchedule_.Busy            AS Busy,
		|			NewSchedule_.ReferenceOrder      AS ReferenceOrder,
		|			NewSchedule_.Department     AS Department,
		|			NewSchedule_.Shift             AS Shift,
		|			NewSchedule_.KeyLot        AS KeyLot,
		|			NewSchedule_.Stage              AS Stage
		|		FROM
		|			TTNewSchedule AS NewSchedule_
		|			
		|			LEFT JOIN TTRecorders_ AS Recorders
		|			ON NewSchedule_.Stage REFS Catalog.ProductionStages
		|				AND NewSchedule_.Period = Recorders.Period
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			ScheduleOld.Recorder       AS Recorder,
		|			ScheduleOld.Period            AS Period,
		|			ScheduleOld.WorkCenterType AS WorkCenterType,
		|			ScheduleOld.IntervalDate     AS IntervalDate,
		|			-ScheduleOld.Busy           AS Busy,
		|			ScheduleOld.ReferenceOrder      AS ReferenceOrder,
		|			ScheduleOld.Department     AS Department,
		|			ScheduleOld.Shift             AS Shift,
		|			ScheduleOld.KeyLot        AS KeyLot,
		|			ScheduleOld.Stage              AS Stage
		|		FROM
		|			AccumulationRegister.AvailabilityOfWorkCenterTypes AS ScheduleOld
		|		WHERE
		|			ScheduleOld.ReferenceOrder = &OrderDocument
		|			AND &QueryTextFilterByStages
		|			AND &QueryTextExcludeStepsWithManualPlacement
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Recorder,
		|	NestedQuery.Period,
		|	NestedQuery.WorkCenterType,
		|	NestedQuery.IntervalDate,
		|	NestedQuery.ReferenceOrder,
		|	NestedQuery.Department,
		|	NestedQuery.Shift,
		|	NestedQuery.KeyLot,
		|	NestedQuery.Stage
		|
		|HAVING
		|	SUM(NestedQuery.Busy) <> 0
		|
		|TOTALS BY
		|	Recorder,
		|	Period";
	
	If FilterByStages Then
		QueryText = StrReplace(QueryText,
			"&QueryTextFilterByStages",
			"(ScheduleOld.KeyLot, ScheduleOld.Stage) IN (
			|	SELECT
			|		T.KeyLot,
			|		T.Stage
			|	FROM
			|		TTNewSchedule AS T)");
	Else
		QueryTextFilterByStages = 
			"NOT ScheduleOld.Stage IN (
			|	SELECT
			|		Stages.Ref AS Stage
			|	FROM
			|		Document.ProductionStage2_2 AS Stages
			|	WHERE
			|		Stages.ReferenceOrder = &OrderDocument
			|		AND Stages.Posted
			|		AND Stages.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated))";
		QueryText = StrReplace(QueryText,
			"&QueryTextFilterByStages",
			QueryTextFilterByStages);
	EndIf;
	
	If Not CalculationParameters.CancelManualChangesOfSchedule
		And StagesWithManualPlacement.Count() > 0 Then
		QueryText = StrReplace(QueryText,
			"&QueryTextExcludeStepsWithManualPlacement",
			"ScheduleOld.Stage NOT IN (&StagesWithManualPlacement)");
	Else
		QueryText = StrReplace(QueryText,
			"&QueryTextExcludeStepsWithManualPlacement",
			"TRUE");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("LoadingVRC", LoadingVRC);
	Query.SetParameter("OrderDocument", CalculationParameters.OrderDocument);
	Query.SetParameter("StagesWithManualPlacement", StagesWithManualPlacement);
	
	SamplingLogger = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SamplingLogger.Next() Do
		SamplePeriod = SamplingLogger.Select(QueryResultIteration.ByGroups);
		
		If SamplingLogger.Recorder.IsEmpty() Then
			While SamplePeriod.Next() Do
				DocumentObject = Documents.ProductionScheduleRecorder.CreateDocument();
				DocumentObject.Date = SamplePeriod.Period;
				DocumentObject.Posted = True;
				DocumentObject.DataExchange.Load = True;
				DocumentObject.Write();
				
				Set = AccumulationRegisters.AvailabilityOfWorkCenterTypes.CreateRecordSet();
				Set.Filter.Recorder.Set(DocumentObject.Ref);
				
				Selection = SamplePeriod.Select();
				While Selection.Next() Do
					Record = Set.Add();
					FillPropertyValues(Record, Selection);
					Record.Recorder = DocumentObject.Ref;
				EndDo;
				
				Set.Write(False);
			EndDo;
		Else
			Set = AccumulationRegisters.AvailabilityOfWorkCenterTypes.CreateRecordSet();
			Set.Filter.Recorder.Set(SamplingLogger.Recorder);
			
			While SamplePeriod.Next() Do
				Selection = SamplePeriod.Select();
				While Selection.Next() Do
					FillPropertyValues(Set.Add(), Selection);
				EndDo;
			EndDo;
			
			Set.Write(False);
		EndIf;
	EndDo;
	
	LoadingVRC.GroupBy("WorkCenterType, IntervalDate");
	AccumulationRegisters.AvailabilityOfWorkCenterTypes.CheckDownloadDoesNotExceedScheduleAvailability(LoadingVRC);
	
EndProcedure

Procedure AfterRecordingProductionSchedule(OrderDocument, Stages)
	
	// Updating the goods Registered Records schedule for stages
	TheStructureOfTheSearch = New Structure("IsDocument", True);
	StagesDocuments = Stages.Copy(TheStructureOfTheSearch, "Stage").UnloadColumn("Stage");
	If StagesDocuments.Count() > 0 Then
		UniversalQueueOfRealTimeJobs.ProcessTasks_(StagesDocuments,
			Enums.UniversalQueueTasks.UpdatingScheduleOfRegisteredRecordsOfGoodsByStagesOfProduction);
	EndIf;
	
	StringProductionStage = Stages.Find(True, "ThisIsProductionOfProducts");
	If StringProductionStage <> Undefined Then
		// Updating the order release schedule
		OrderStructureDocumentPosting.UpdateProductionScheduleAfterCalculatingProductionSchedule(OrderDocument);
		
		// Updating the schedule of Registering Records of goods to be ordered
		UniversalQueueOfRealTimeJobs.ProcessTask_(OrderDocument,
			Enums.UniversalQueueTasks.UpdatingScheduleOfRegisteredRecordsOfGoodsOnProductionOrders);
	EndIf;
	
EndProcedure

#EndRegion

#Region ReadingStages

Procedure ReadOrderSteps(OrderDocument, PaymentData, CalculationParameters)
	
	QueryTexts = New ValueList;
	TempTablesManager = New TempTablesManager;
	
	// TTOrderStructure
	QueryText = QueryTextTTOrderStructure("&TextTableName.ProductionOrder = &OrderDocument");
	QueryTexts.Add(QueryText, "TTOrderStructure");
	
	// TTLotReferenceRelease
	QueryText = QueryTextTTLotReferenceIssue();
	QueryTexts.Add(QueryText, "TTLotReferenceRelease");
	
	// TTNumberOfLotReferences
	QueryText = QueryTextTTQuantityOfBatches();
	QueryTexts.Add(QueryText, "TTNumberOfLotReferences");
	
	// TTOrdersForRAndM
	QueryText = QueryTextTTRMOrders("&TextTableName.Ref = &OrderDocument");
	QueryTexts.Add(QueryText, "TTOrdersForRAndM");
	
	#Region TTProductionScheduleRestrictionsOnMaterials
	
	If CalculationParameters.AllMaterialsInStock Then
		
		QueryText = 
			"SELECT
			|	VALUE(Document.ProductionOrder2_2.EmptyRef) AS ProductionOrder,
			|	&EmptyLinkKey                                       AS KeyLot,
			|	VALUE(Document.ProductionStage2_2.EmptyRef)    AS Stage,
			|	DATETIME(1, 1, 1)                                     AS AvailabilityDate
			|INTO TTProductionScheduleRestrictionsOnMaterials";
		QueryTexts.Add(QueryText, "TTProductionScheduleRestrictionsOnMaterials");
		
	Else
		
		ProductionManagement.CreateTTConstraintsOfProductionScheduleBasedOnMaterialsDynamicStructure(
			TempTablesManager,
			OrderDocument,
			False,
			True);
		
	EndIf;
	
	#EndRegion
	
	// TTCommunicationBetweenLotREFERENCES
	QueryText = QueryTextTTLinksBetweenParties();
	QueryTexts.Add(QueryText, "TTCommunicationBetweenLotREFERENCES");
	
	// TTParty
	QueryText = QueryTextTTLots();
	QueryTexts.Add(QueryText, "TTParty");
	
	// TTCommunicationOfPartiesAndStagesCatalog
	QueryText = QueryTextTTOfCommunicationOfPartiesAndStagesCatalog();
	QueryTexts.Add(QueryText, "TTCommunicationOfPartiesAndStagesCatalog");
	
	// TTStagesCatalog
	QueryText = QueryTextTTStagesCatalog();
	QueryTexts.Add(QueryText, "TTStagesCatalog");
	
	// TTCommunicationOfPartiesAndStagesDocument
	QueryText = QueryTextTTOfCommunicationOfBatchesAndStagesIsDocument();
	QueryTexts.Add(QueryText, "TTCommunicationOfPartiesAndStagesDocument");
	
	#Region TTOrdersForRAndMToCalculationOfOrder
	
	If PaymentData.OrderDetails.ThisIsRepair Then
		
		QueryText = 
			"SELECT
			|	&OrderDocument AS ProductionOrder
			|INTO TTOrdersForRAndMToCalculationOfOrder
			|WHERE
			|	TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			TTParty AS Lots
			|			
			|			INNER JOIN Catalog.ProductionStages AS Stages
			|			ON Lots.Ref = Stages.Owner
			|				AND Lots.ItIsTransfer = FALSE
			|		WHERE
			|			NOT Stages.DeletionMark
			|			AND NOT TRUE IN (
			|				SELECT TOP 1
			|					TRUE
			|				FROM
			|					InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
			|				WHERE
			|					Schedule.ProductionOrder = Lots.ProductionOrder
			|					AND Schedule.ScheduleStatus = 0
			|					AND Schedule.Stage = Stages.Ref
			|					AND Schedule.KeyLot = Lots.KeyLot)
			|		
			|		UNION ALL
			|		
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			TTParty AS Lots
			|			
			|			INNER JOIN Document.ProductionStage2_2 AS Stages
			|			ON Lots.Ref = Stages.ProductionLot
			|				AND Lots.ItIsTransfer = FALSE
			|		WHERE
			|			Stages.Posted
			|			AND NOT TRUE IN (
			|				SELECT TOP 1
			|					TRUE
			|				FROM
			|					InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
			|				WHERE
			|					Schedule.ProductionOrder = Lots.ProductionOrder
			|					AND Schedule.ScheduleStatus = 0
			|					AND Schedule.Stage = Stages.Ref
			|					AND Schedule.KeyLot = Lots.KeyLot))";
		QueryTexts.Add(QueryText, "TTOrdersForRAndMToCalculationOfOrder");
		
	Else
		
		QueryText = 
			"SELECT TOP 0
			|	VALUE(Document.ProductionOrder2_2.EmptyRef) AS ProductionOrder
			|INTO TTOrdersForRAndMToCalculationOfOrder";
		QueryTexts.Add(QueryText, "TTOrdersForRAndMToCalculationOfOrder");
		
	EndIf;
	
	#EndRegion
	
	// TTCommunication
	QueryText = QueryTextTTLinks();
	QueryTexts.Add(QueryText, "TTCommunication");
	
	// TTStagesWithManualPlacement
	QueryText = QueryTextTTStagesWithManualPlacement("&TextTableName.ReferenceOrder = &OrderDocument");
	QueryTexts.Add(QueryText, "TTStagesWithManualPlacement");
	
	// TTDatesOfUnplannedPredecessors
	QueryText = QueryTextTTDatesOfUnplannedPredecessors("&TextTableName.ReferenceOrder = &OrderDocument");
	QueryTexts.Add(QueryText, "TTDatesOfUnplannedPredecessors");
	
	// Stages
	QueryText = QueryTextStages(False);
	QueryTexts.Add(QueryText, "Stages");
	
	// Links
	QueryText = QueryTextLinks(CalculationParameters.CancelManualChangesOfSchedule);
	QueryTexts.Add(QueryText, "Links");
	
	// TypesOfRC
	QueryText = QueryTextTypesOfRC(False, "TRUE");
	QueryTexts.Add(QueryText, "TypesOfRC");
	
	// ProductsForCalculationOfTypesOfRCAccordingToFormula
	QueryText = QueryTextProductsForCalculationOfTypesOfRCAccordingToFormula();
	QueryTexts.Add(QueryText, "ProductsForCalculationOfTypesOfRCAccordingToFormula");
	
	#Region Jobs
	
	QueryText = 
		"SELECT
		|	Jobs.ProductionOrder AS ProductionOrder,
		|	Jobs.Separator         AS Separator,
		|	Jobs.ProductionStage    AS ProductionStage,
		|	Jobs.KeyLot          AS KeyLot
		|FROM
		|	InformationRegister.OrderStructureCalculationJobsProductionSchedule AS Jobs
		|WHERE
		|	Jobs.ProductionOrder = &OrderDocument";
	
	QueryTexts.Add(QueryText, "Jobs");
	
	#EndRegion
	
	#Region StagesWithManualPlacement
	
	QueryText = 
		"SELECT
		|	Stages.Ref AS Ref
		|FROM
		|	TTStagesWithManualPlacement AS Stages";
	
	QueryTexts.Add(QueryText, "StagesWithManualPlacement");
	
	#EndRegion
	
	If PaymentData.OrderDetails.ThisIsRepair Then
		
		// RepairLinks
		QueryText = QueryTextRepairLinks();
		QueryTexts.Add(QueryText, "RepairLinks");
		
		#Region TTLotREFERENCEOfRAndMToCalculationOfOrder
		
		QueryText = 
			"SELECT
			|	Lots.KeyLot AS KeyLot,
			|	Lots.Level    AS Level,
			|	SUM(
			|		CASE
			|			WHEN ISNULL(StepsDuration.DurationInSeconds, 0) = 0
			|				THEN 0.0001
			|			ELSE ISNULL(StepsDuration.DurationInSeconds, 0)
			|		END)        AS ResourceIntensity
			|INTO TTLotREFERENCEOfRAndMToCalculationOfOrder
			|FROM
			|	TTParty AS Lots
			|	
			|	INNER JOIN Catalog.ProductionStages AS Stages
			|	ON Lots.Ref = Stages.Owner
			|		AND Lots.ItIsTransfer = FALSE
			|
			|	LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS StepsDuration
			|	ON Stages.Ref = StepsDuration.Stage
			|		AND Lots.Ref = StepsDuration.BillOfMaterials
			|WHERE
			|	Lots.ProductionOrder IN (
			|		SELECT
			|			T.ProductionOrder
			|		FROM
			|			TTOrdersForRAndMToCalculationOfOrder AS T)
			|	AND NOT Stages.DeletionMark
			|
			|GROUP BY
			|	Lots.KeyLot,
			|	Lots.Level
			|
			|UNION ALL
			|
			|SELECT
			|	Lots.KeyLot AS KeyLot,
			|	Lots.Level    AS Level,
			|	SUM(
			|		CASE
			|			WHEN Stages.StageDuration = 0
			|				THEN 0.0001
			|			ELSE 
			|				CASE Stages.UnitOfMeasureOfStageDuration
			|					WHEN VALUE(Enum.TimeMeasureUnits.DAY)
			|						THEN Stages.StageDuration * 86400
			|					WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
			|						THEN Stages.StageDuration * 60
			|					WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
			|						THEN Stages.StageDuration * 3600
			|					WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
			|						THEN Stages.StageDuration
			|				END
			|		END)        AS ResourceIntensity
			|FROM
			|	TTParty AS Lots
			|	
			|	INNER JOIN Document.ProductionStage2_2 AS Stages
			|	ON Lots.Ref = Stages.ProductionLot
			|		AND Lots.ItIsTransfer = FALSE
			|WHERE
			|	Lots.ProductionOrder IN (
			|		SELECT
			|			T.ProductionOrder
			|		FROM
			|			TTOrdersForRAndMToCalculationOfOrder AS T)
			|	AND Stages.Posted
			|
			|GROUP BY
			|	Lots.KeyLot,
			|	Lots.Level
			|
			|UNION ALL
			|
			|SELECT
			|	Lots.KeyLot AS KeyLot,
			|	Lots.Level    AS Level,
			|	CASE
			|		WHEN ISNULL(NSICache.SupplyMethod.ProductionDurationDays, 1) = 0
			|			THEN 0.0001
			|		ELSE ISNULL(NSICache.SupplyMethod.ProductionDurationDays, 1) * 86400
			|	END             AS ResourceIntensity
			|FROM
			|	TTParty AS Lots
			|
			|	LEFT JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
			|	ON Lots.ItemOfMovement = NSICache.Products
			|		AND Lots.CharacteristicsOfMovement = NSICache.Characteristic
			|		AND Lots.WarehouseFromTransfer = NSICache.Warehouse
			|		AND Lots.PurposeOfMove = NSICache.Purpose
			|		AND Lots.ProductionOrder = NSICache.ProductionOrder
			|WHERE
			|	Lots.ProductionOrder IN (
			|		SELECT
			|			T.ProductionOrder
			|		FROM
			|			TTOrdersForRAndMToCalculationOfOrder AS T)
			|	AND Lots.ItIsTransfer
			|	AND Lots.Ref = VALUE(Catalog.BillsOfMaterials.EmptyRef)
			|
			|INDEX BY
			|	KeyLot";
		
		QueryTexts.Add(QueryText, "TTLotREFERENCEOfRAndMToCalculationOfOrder");
		
		#EndRegion
		
		#Region LotReferenceOfRAndMToCalculationOfOrder
		
		QueryText = 
			"SELECT
			|	Lots.KeyLot     AS KeyIsPredecessorParty,
			|	Lots.ResourceIntensity AS ResourceIntensity,
			|	ISNULL(Links.KeyLot, &EmptyLinkKey)                              AS KeyLot,
			|	ISNULL(Links.Stage, VALUE(Catalog.ProductionStages.EmptyRef)) AS Stage
			|FROM
			|	TTLotREFERENCEOfRAndMToCalculationOfOrder AS Lots
			|
			|	LEFT JOIN TTCommunicationBetweenLotREFERENCES AS Links
			|	ON Lots.KeyLot = Links.KeyIsPredecessorParty
			|
			|ORDER BY
			|	Lots.Level DESC";
		
		QueryTexts.Add(QueryText, "LotReferenceOfRAndMToCalculationOfOrder");
		
		#EndRegion
		
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("OrderDocument", OrderDocument);
	Query.SetParameter("ScheduleStatus", CalculationParameters.ScheduleStatus);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("MainCalendar", Constants.MainEnterpriseCalendar.Get());
	Query.SetParameter("CurrentDate", CalculationParameters.CurrentDate);
	Query.SetParameter("UnlimitedEquipmentFleet", CalculationParameters.UnlimitedEquipmentFleet);
	Query.SetParameter("CancelManualChangesOfSchedule", CalculationParameters.CancelManualChangesOfSchedule);
	
	SetPrivilegedMode(True);
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts,, True, False);
	SetPrivilegedMode(False);
	
	Stages = Tables.Stages; // ValueTable
	Stages.Indexes.Add("KeyLot, Stage");
	PaymentData.Stages = Stages;
	
	Links = Tables.Links; // ValueTable
	Links.Indexes.Add("KeyLot, Stage");
	PaymentData.Links = Links;
	
	TypesOfRC = Tables.TypesOfRC; // ValueTable
	CalculateTimeOfRCTypesUsingFormulas(TypesOfRC, Tables.ProductsForCalculationOfTypesOfRCAccordingToFormula);
	TypesOfRC.Indexes.Add("KeyLot, Stage");
	PaymentData.TypesOfRC = TypesOfRC;
	
	PaymentData.Jobs = Tables.Jobs;
	PaymentData.StagesWithManualPlacement = Tables.StagesWithManualPlacement.UnloadColumn("Ref");
	
	If PaymentData.OrderDetails.ThisIsRepair Then
		RepairLinks = Tables.RepairLinks; // ValueTable
		RepairLinks.Indexes.Add("KeyIsLotReferenceRAndM");
		PaymentData.RepairLinks = RepairLinks;
		
		If Tables.LotReferenceOfRAndMToCalculationOfOrder.Count() > 0 Then
			CalculateRAndMRepairProcedure(PaymentData, Tables.LotReferenceOfRAndMToCalculationOfOrder);
		EndIf;
	EndIf;
	
	// Control of RC Species
	TheStructureOfTheSearch = New Structure("ThereIsErrorDownloadIsNotFilledIn", True);
	ErrorsTable = TypesOfRC.Copy(TheStructureOfTheSearch, "WorkCenterType");
	ErrorsTable.GroupBy("WorkCenterType");
	For Each String In ErrorsTable Do
		NotificationText1 = StrTemplate(
			NStr("vi = 'Đối với dạng NLSX ""%1"" chưa xác định kết nhập tối đa. Mục tin bắt buộc cần điền cho dạng NLSX có kết nhập song song.';
				|ru = 'Для вида РЦ ""%1"" не задана максимальная загрузка. Реквизит обязателен к заполнению для видов РЦ с параллельной загрузкой.';
				|en = 'The maximum load is not set for the ""%1"" work center type. The attribute is required for work center types with parallel load.'; fa = 'The maximum load is not set for the ""%1"" work center type. The attribute is required for work center types with parallel load.';
				|it = 'Для вида РЦ ""%1"" не задана максимальная загрузка. Реквизит обязателен к заполнению для видов РЦ с параллельной загрузкой.';
				|pl = 'The maximum load is not set for the ""%1"" work center type. The attribute is required for work center types with parallel load.';
				|tr = 'Для вида РЦ ""%1"" не задана максимальная загрузка. Реквизит обязателен к заполнению для видов РЦ с параллельной загрузкой.'"),
			String.WorkCenterType);
		CalculationParameters.Notifications.Insert(NotificationText1, String.WorkCenterType);
	EndDo;
	
EndProcedure

Function ReadStagesOfLotReferences(TempTablesManager)
	
	QueryTexts = New ValueList;
	
	// TTOrderStructure
	TextSelectionStructure = 
		"TRUE IN (
		|	SELECT TOP 1
		|		TRUE
		|	FROM 
		|		OrderBoundariesTT AS Boundaries
		|	WHERE
		|		Boundaries.ProductionOrder = &TextTableName.ProductionOrder
		|		AND Boundaries.DurationBeforeProductionIssue <= &TextTableName.DurationBeforeProductionIssue)";
	QueryText = QueryTextTTOrderStructure(TextSelectionStructure);
	QueryTexts.Add(QueryText, "TTOrderStructure");
	
	// TTLotReferenceRelease
	QueryText = QueryTextTTLotReferenceIssue();
	QueryTexts.Add(QueryText, "TTLotReferenceRelease");
	
	// TTNumberOfLotReferences
	QueryText = QueryTextTTQuantityOfBatches();
	QueryTexts.Add(QueryText, "TTNumberOfLotReferences");
	
	// TTProductionScheduleRestrictionsOnMaterials
	ProductionManagement.CreateTTConstraintsOfProductionScheduleBasedOnMaterialsDynamicStructure(
		TempTablesManager, TextSelectionStructure, False, True);
	
	// TTCommunicationBetweenLotREFERENCES
	QueryText = QueryTextTTLinksBetweenParties();
	QueryTexts.Add(QueryText, "TTCommunicationBetweenLotREFERENCES");
	
	// TTParty
	QueryText = QueryTextTTLots();
	QueryTexts.Add(QueryText, "TTParty");
	
	// TTCommunicationOfPartiesAndStagesCatalog
	QueryText = QueryTextTTOfCommunicationOfPartiesAndStagesCatalog();
	QueryTexts.Add(QueryText, "TTCommunicationOfPartiesAndStagesCatalog");
	
	// TTStagesCatalog
	QueryText = QueryTextTTStagesCatalog();
	QueryTexts.Add(QueryText, "TTStagesCatalog");
	
	// TTCommunicationOfPartiesAndStagesDocument
	QueryText = QueryTextTTOfCommunicationOfBatchesAndStagesIsDocument();
	QueryTexts.Add(QueryText, "TTCommunicationOfPartiesAndStagesDocument");
	
	// TTCommunication
	QueryText = QueryTextTTLinks();
	QueryTexts.Add(QueryText, "TTCommunication");
	
	// TTStagesWithManualPlacement
	TextSelectionStages = 
		"&TextTableName.ReferenceOrder IN (
		|	SELECT DISTINCT
		|		T.ProductionOrder
		|	FROM
		|		TTJobs AS T)";
	QueryText = QueryTextTTStagesWithManualPlacement(TextSelectionStages);
	QueryTexts.Add(QueryText, "TTStagesWithManualPlacement");
	
	// TTDatesOfUnplannedPredecessors
	TextSelectionStages = 
		"&TextTableName.ReferenceOrder IN (
		|	SELECT DISTINCT
		|		T.ProductionOrder
		|	FROM
		|		TTJobs AS T)";
	QueryText = QueryTextTTDatesOfUnplannedPredecessors(TextSelectionStages);
	QueryTexts.Add(QueryText, "TTDatesOfUnplannedPredecessors");
	
	// TTStages
	QueryText = QueryTextStages(True);
	QueryTexts.Add(QueryText, "TTStages");
	
	// TTTypesOfRC
	TextSelectionOfLotReference = 
		"&TextTableName.KeyLot IN (
		|	SELECT
		|		T.KeyLot
		|	FROM
		|		TTJobs AS T)";
	QueryText = QueryTextTypesOfRC(True, TextSelectionOfLotReference);
	QueryTexts.Add(QueryText, "TTTypesOfRC");
	
	#Region TTIntermediateStages
	
	// Unplanned stages linked to the nearest planned stage
	QueryText = 
		"SELECT
		|	Stages.ProductionOrder           AS ProductionOrder,
		|	Stages.KeyLot                    AS KeyLot,
		|	Stages.Stage                          AS Stage,
		|	MIN(NextSteps_.RecNo) AS RecNo
		|INTO TTIntermediateStages
		|FROM
		|	TTStages AS Stages
		|	
		|	INNER JOIN TTStages AS NextSteps_
		|	ON Stages.ProductionOrder = NextSteps_.ProductionOrder
		|		AND Stages.RecNo < NextSteps_.RecNo
		|WHERE
		|	NOT TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTJobs AS Jobs
		|		WHERE
		|			Jobs.ProductionOrder = Stages.ProductionOrder
		|			AND Jobs.KeyLot = Stages.KeyLot)
		|	AND TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTJobs AS Jobs
		|		WHERE
		|			Jobs.ProductionOrder = NextSteps_.ProductionOrder
		|			AND Jobs.KeyLot = NextSteps_.KeyLot)
		|
		|GROUP BY
		|	Stages.ProductionOrder,
		|	Stages.KeyLot,
		|	Stages.Stage
		|
		|INDEX BY
		|	KeyLot, Stage";
	
	QueryTexts.Add(QueryText, "TTIntermediateStages");
	
	#EndRegion
	
	#Region TTBoundariesOfStages
	
	// Restriction on the right for attracting stages
	// Filled in in cases when the Lot reference on the right does not fall into the current calculation
	QueryText = 
		"SELECT
		|	Stages.KeyLot       AS KeyLot,
		|	Stages.Stage             AS Stage,
		|	MIN(Schedule.Begin) AS RightBorder_
		|INTO TTBoundariesOfStages
		|FROM
		|	TTStages AS Stages
		|	
		|	INNER JOIN TTCommunication AS Links
		|	ON Stages.ProductionOrder = Links.ProductionOrderPredecessor
		|		AND Stages.KeyLot = Links.KeyIsPredecessorParty
		|		AND Stages.Stage = Links.PredecessorStage
		|	
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Links.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = 0
		|		AND Links.Stage = Schedule.Stage
		|		AND Links.KeyLot = Schedule.KeyLot
		|WHERE
		|	(Stages.ProductionOrder, Stages.KeyLot) IN (
		|		SELECT
		|			T.ProductionOrder AS ProductionOrder,
		|			T.KeyLot AS KeyLot
		|		FROM
		|			TTJobs AS T)
		|	AND Stages.NextStageNo = 0
		|	AND Stages.ThereIsRightBorder = FALSE
		|	AND Stages.ShiftToRight
		|	AND NOT TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTJobs AS T
		|		WHERE
		|			T.ProductionOrder = Links.ProductionOrder
		|			AND T.KeyLot = Links.KeyLot)
		|GROUP BY
		|	Stages.KeyLot,
		|	Stages.Stage
		|
		|INDEX BY
		|	KeyLot, Stage";
	
	QueryTexts.Add(QueryText, "TTBoundariesOfStages");
	
	#EndRegion
	
	// Links
	QueryText = QueryTextLinks(False);
	QueryTexts.Add(QueryText, "Links");
	
	// TypesOfRC
	QueryText = "SELECT * FROM TTTypesOfRC";
	QueryTexts.Add(QueryText, "TypesOfRC");
	
	// ProductsForCalculationOfTypesOfRCAccordingToFormula
	QueryText = QueryTextProductsForCalculationOfTypesOfRCAccordingToFormula();
	QueryTexts.Add(QueryText, "ProductsForCalculationOfTypesOfRCAccordingToFormula");
	
	#Region LoadingRCViews
	
	// Loading of unplanned stages linked to the nearest planned stage
	QueryText = 
		"SELECT
		|	Stages.RecNo          AS RecNo,
		|	Load.WorkCenterType AS WorkCenterType,
		|	Load.IntervalDate     AS IntervalDate,
		|	SUM(Load.Busy)     AS TimeBusy,
		|	SUM(Load.Busy) * 
		|		CASE
		|			WHEN Load.WorkCenterType.ParallelLoad
		|					AND Load.WorkCenterType.MaximumLoad <> 0
		|				THEN Load.WorkCenterType.MaximumLoad
		|			ELSE 1
		|		END                  AS BusyLoadingTime
		|FROM
		|	TTIntermediateStages AS Stages
		|	
		|	INNER JOIN AccumulationRegister.AvailabilityOfWorkCenterTypes AS Load
		|	ON Stages.KeyLot = Load.KeyLot
		|		AND Stages.Stage = Load.Stage
		|
		|WHERE
		|	Load.WorkCenterType IN (
		|		SELECT DISTINCT
		|			T.WorkCenterType AS WorkCenterType
		|		FROM
		|			TTTypesOfRC AS T
		|		WHERE
		|			T.ProductionOrder = Stages.ProductionOrder
		|			AND T.ConsiderAvailability = TRUE)
		|
		|GROUP BY
		|	Stages.RecNo,
		|	Load.WorkCenterType,
		|	Load.IntervalDate";
	
	QueryTexts.Add(QueryText, "LoadingRCViews");
	
	#EndRegion
	
	#Region PredecessorDates
	
	// Dates of unplanned stages preceding the planned stages
	QueryText = 
		"SELECT DISTINCT
		|	Links.KeyIsPredecessorParty AS KeyLot,
		|	Links.PredecessorStage       AS Stage,
		|	Schedule.Begin                  AS Begin,
		|	Schedule.Ending               AS Ending
		|FROM
		|	TTCommunication AS Links
		|	
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Links.ProductionOrderPredecessor = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = &ScheduleStatus
		|		AND Links.PredecessorStage = Schedule.Stage
		|		AND Links.KeyIsPredecessorParty = Schedule.KeyLot
		|WHERE
		|	(Links.ProductionOrder, Links.KeyLot) IN (
		|		SELECT
		|			T.ProductionOrder,
		|			T.KeyLot
		|		FROM
		|			TTJobs AS T)
		|	AND NOT TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTJobs AS T
		|		WHERE
		|			T.ProductionOrder = Links.ProductionOrderPredecessor
		|			AND T.KeyLot = Links.KeyIsPredecessorParty)
		|	AND Links.KeyIsPredecessorParty <> Links.KeyLot";
	
	QueryTexts.Add(QueryText, "PredecessorDates");
	
	#EndRegion
	
	#Region FollowerDates
	
	// Start dates of unplanned stages - followers
	QueryText = 
		"SELECT
		|	Links.KeyIsPredecessorParty AS KeyLot,
		|	Links.PredecessorStage       AS Stage,
		|	MIN(Schedule.Begin)         AS NextStageStart
		|FROM
		|	TTCommunication AS Links
		|	
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Links.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = &ScheduleStatus
		|		AND Links.Stage = Schedule.Stage
		|		AND Links.KeyLot = Schedule.KeyLot
		|WHERE
		|	(Links.ProductionOrderPredecessor, Links.KeyIsPredecessorParty) IN (
		|		SELECT
		|			T.ProductionOrder,
		|			T.KeyLot
		|		FROM
		|			TTJobs AS T)
		|	AND NOT TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTJobs AS T
		|		WHERE
		|			T.ProductionOrder = Links.ProductionOrder
		|			AND T.KeyLot = Links.KeyLot)
		|	AND Links.KeyIsPredecessorParty <> Links.KeyLot
		|
		|GROUP BY
		|	Links.KeyIsPredecessorParty,
		|	Links.PredecessorStage";
	
	QueryTexts.Add(QueryText, "FollowerDates");
	
	#EndRegion
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ScheduleStatus", 
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("MainCalendar", Constants.MainEnterpriseCalendar.Get());
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("UnlimitedEquipmentFleet", False);
	Query.SetParameter("CancelManualChangesOfSchedule", False);
	
	SetPrivilegedMode(True);
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts, , True, False);
	SetPrivilegedMode(False);
	
	Result = New Structure;
	
	Links = Tables.Links; // ValueTable
	Links.Indexes.Add("KeyLot, Stage");
	Result.Insert("Links", Links);
	
	TypesOfRC = Tables.TypesOfRC; // ValueTable
	CalculateTimeOfRCTypesUsingFormulas(TypesOfRC, Tables.ProductsForCalculationOfTypesOfRCAccordingToFormula);
	TypesOfRC.Indexes.Add("KeyLot, Stage");
	Result.Insert("TypesOfRC", TypesOfRC);
	
	LoadingRCViews = Tables.LoadingRCViews; // ValueTable
	LoadingRCViews.Indexes.Add("RecNo");
	Result.Insert("LoadingRCViews", LoadingRCViews);
	
	PredecessorDates = Tables.PredecessorDates; // ValueTable
	PredecessorDates.Indexes.Add("KeyLot, Stage");
	Result.Insert("PredecessorDates", PredecessorDates);
	
	FollowerDates = Tables.FollowerDates; // ValueTable
	FollowerDates.Indexes.Add("KeyLot, Stage");
	Result.Insert("FollowerDates", FollowerDates);
	
	Return Result;
	
EndFunction

Function QueryTextTTOrderStructure(QueryTextFilter)
	
	QueryText = 
		"SELECT
		|	OrderStructure.ProductionOrder AS ProductionOrder,
		|	OrderStructure.KeyProducts    AS KeyProducts,
		|	OrderStructure.KeyLot          AS KeyLot,
		|	OrderStructure.Stage                AS Stage,
		|	OrderStructure.Products        AS Products,
		|	OrderStructure.Characteristic      AS Characteristic,
		|	OrderStructure.LineKind <> VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption) AS ThisIsRelease,
		|	OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)  AS ItIsTransfer,
		|	OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts) AS ThisIsProductionOfProducts,
		|	OrderStructure.Products.ProductKind       AS ProductKind,
		|	MAX(OrderStructure.BillOfMaterials)             AS BillOfMaterials,
		|	MAX(OrderStructure.Department)            AS Department,
		|	MAX(
		|		CASE
		|			WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
		|				THEN OrderStructure.Warehouse
		|		END)                                         AS WarehouseFromTransfer,
		|	MAX(
		|		CASE
		|			WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
		|				THEN OrderStructure.Purpose
		|		END)                                         AS PurposeOfMove,
		|	SUM(OrderStructure.Scheduled)
		|		+ SUM(OrderStructure.ReverseKittingScheduled) AS Scheduled,
		|	SUM(OrderStructure.Launched)
		|		+ SUM(OrderStructure.ReverseKittingStarted)      AS Launched,
		|	MIN(OrderStructure.DurationBeforeProductionIssue)         AS DurationBeforeProductionIssue,
		|	MIN(OrderStructure.ProductionLotIDInProductGroup)   AS ProductionLotIDInProductGroup,
		|	MIN(OrderStructure.Level)                       AS Level
		|INTO TTOrderStructure
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	&QueryTextFilter
		|	AND OrderStructure.LineKind <> VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct)
		|
		|GROUP BY
		|	OrderStructure.ProductionOrder,
		|	OrderStructure.KeyProducts,
		|	OrderStructure.KeyLot,
		|	OrderStructure.Stage,
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic,
		|	OrderStructure.LineKind <> VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption),
		|	OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move),
		|	OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
		|	OrderStructure.Products.ProductKind
		|
		|HAVING
		|	SUM(OrderStructure.Scheduled) > 0
		|	OR SUM(OrderStructure.ReverseKittingScheduled) > 0
		|	OR SUM(OrderStructure.Launched) > 0
		|	OR SUM(OrderStructure.ReverseKittingStarted) > 0
		|	OR SUM(OrderStructure.AllocatedInFreeProductionLots) > 0
		|	OR SUM(OrderStructure.AllocatedInAssignedProductionLots) > 0
		|	OR SUM(OrderStructure.ToSupply - OrderStructure.Replaced) > 0
		|
		|INDEX BY
		|	ProductionOrder,
		|	KeyProducts";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextFilter",
		StrReplace(QueryTextFilter, "&TextTableName", "OrderStructure"));
	
	Return QueryText;
	
EndFunction

Function QueryTextTTLotReferenceIssue()
	
	QueryText = 
		"SELECT
		|	OrderStructure.KeyLot              AS KeyLot,
		|	OrderStructure.Products            AS Products,
		|	OrderStructure.Characteristic          AS Characteristic,
		|	SUM(OrderStructure.Scheduled + OrderStructure.Launched) AS QuantityOfUnits,
		|	MAX(
		|		ProductsBOM.NumberOfPackagesPerStartingLotUnit
		|		* ISNULL(&QueryTextPackagingFactor, 1))            AS NumberOfUnitsPerLotReference,
		|	RECORDAUTONUMBER()                       AS Order
		|INTO TTLotReferenceRelease
		|FROM
		|	TTOrderStructure AS OrderStructure
		|	
		|	INNER JOIN InformationRegister.ProductsBOM AS ProductsBOM
		|	ON OrderStructure.BillOfMaterials = ProductsBOM.BillOfMaterials
		|		AND OrderStructure.ProductKind = ProductsBOM.ProductKind
		|		AND ProductsBOM.Products   IN (OrderStructure.Products, VALUE(Catalog.Products.EmptyRef))
		|		AND ProductsBOM.Characteristic IN (OrderStructure.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|WHERE
		|	OrderStructure.ThisIsRelease
		|	AND NOT OrderStructure.ItIsTransfer
		|	
		|GROUP BY
		|	OrderStructure.KeyLot,
		|	OrderStructure.Products,
		|	OrderStructure.Characteristic
		|	
		|HAVING
		|	SUM(OrderStructure.Scheduled + OrderStructure.Launched) <> 0
		|	AND MAX(
		|		ISNULL(ProductsBOM.NumberOfPackagesPerStartingLotUnit, 1)
		|		* ISNULL(&QueryTextPackagingFactor, 1)) <> 0
		|
		|INDEX BY
		|	KeyLot";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductsBOM.Package",
			"ProductsBOM.Products"));
	
	Return QueryText;
	
EndFunction

Function QueryTextTTQuantityOfBatches()
	
	QueryText = 
		"SELECT
		|	LotReferenceIssue.KeyLot       AS KeyLot,
		|	LotReferenceIssue.Products     AS Products,
		|	LotReferenceIssue.Characteristic   AS Characteristic,
		|	LotReferenceIssue.QuantityOfUnits AS QuantityOfUnits,
		|	LotReferenceIssue.QuantityOfUnits AS NumberOfLotReferencesNumerator,
		|	CASE
		|		WHEN LotReferenceIssue.NumberOfUnitsPerLotReference = 0
		|			THEN 1
		|		ELSE LotReferenceIssue.NumberOfUnitsPerLotReference
		|	END                         AS NumberOfLotReferencesDenominator
		|INTO TTNumberOfLotReferences
		|FROM
		|	TTLotReferenceRelease AS LotReferenceIssue
		|WHERE
		|	LotReferenceIssue.Order IN (
		|		SELECT TOP 1
		|			T.Order
		|		FROM
		|			TTLotReferenceRelease AS T
		|		WHERE
		|			T.KeyLot = LotReferenceIssue.KeyLot
		|		ORDER BY
		|			T.QuantityOfUnits / T.NumberOfUnitsPerLotReference DESC)
		|
		|INDEX BY
		|	KeyLot";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTRMOrders(QueryTextFilter)
	
	QueryText = 
		"SELECT
		|	Orders.Ref AS Ref
		|INTO TTOrdersForRAndM
		|FROM
		|	Document.ProductionOrder2_2 AS Orders
		|WHERE
		|	&QueryTextFilter
		|	AND Orders.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|
		|INDEX BY
		|	Ref";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextFilter",
		StrReplace(QueryTextFilter, "&TextTableName", "Orders"));
	
	Return QueryText;
	
EndFunction

Function QueryTextTTLinksBetweenParties()
	
	QueryText = 
		"SELECT DISTINCT
		|	Successors.KeyLot            AS KeyLot,
		|	Successors.Stage                  AS Stage,
		|	Successors.ProductionOrder   AS ProductionOrder,
		|	Predecessors.KeyLot          AS KeyIsPredecessorParty,
		|	Predecessors.Stage                AS PredecessorStage,
		|	Predecessors.ProductionOrder AS ProductionOrderPredecessor
		|INTO TTCommunicationBetweenLotREFERENCES
		|FROM
		|	TTOrderStructure AS Successors
		|
		|	INNER JOIN TTOrderStructure AS Predecessors
		|	ON Successors.ProductionOrder = Predecessors.ProductionOrder
		|		AND Successors.KeyProducts = Predecessors.KeyProducts
		|WHERE
		|	Predecessors.ThisIsRelease = TRUE
		|	AND Successors.ThisIsRelease = FALSE
		|
		|INDEX BY SETS (
		|	(ProductionOrder, KeyLot),
		|	(KeyLot, Stage)
		|)";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTLots()
	
	QueryText = 
		"SELECT TOP 10000000
		|	OrderStructure.ProductionOrder                              AS ProductionOrder,
		|	OrderStructure.KeyLot                                       AS KeyLot,
		|	ISNULL(Stages.ProductionLot, OrderStructure.BillOfMaterials) AS Ref,
		|	MAX(OrderStructure.ItIsTransfer)                         AS ItIsTransfer,
		|	MAX(OrderStructure.ThisIsProductionOfProducts)               AS ThisIsProductionOfProducts,
		|	MIN(OrderStructure.DurationBeforeProductionIssue)                   AS DurationBeforeProductionIssue,
		|	MIN(OrderStructure.ProductionLotIDInProductGroup)             AS ProductionLotIDInProductGroup,
		|	MAX(
		|		CASE
		|			WHEN OrderStructure.ItIsTransfer
		|				THEN OrderStructure.Products
		|		END)                                                       AS ItemOfMovement,
		|	MAX(
		|		CASE
		|			WHEN OrderStructure.ItIsTransfer
		|				THEN OrderStructure.Characteristic
		|		END)                                                       AS CharacteristicsOfMovement,
		|	MAX(
		|		CASE
		|			WHEN OrderStructure.ItIsTransfer
		|				THEN OrderStructure.WarehouseFromTransfer
		|		END)                                                       AS WarehouseFromTransfer,
		|	MAX(
		|		CASE
		|			WHEN OrderStructure.ItIsTransfer
		|				THEN OrderStructure.PurposeOfMove
		|		END)                                                       AS PurposeOfMove,
		|	MIN(
		|		CASE
		|			WHEN Stages.Ref IS NOT NULL
		|				THEN 1
		|			ELSE 2
		|		END)                                                       AS OrderOfLaunch,
		|	MIN(
		|		CASE
		|			WHEN OrderProducts_.DemandDate IS NOT NULL
		|				THEN OrderProducts_.DemandDate
		|		END)                                                       AS DateOfNeedOfManufacturedProduct,
		|	MIN(
		|		CASE
		|			WHEN OrderProducts_.LineNumber IS NOT NULL
		|				THEN OrderProducts_.LineNumber
		|		END)                                                       AS LineNumberProducts,
		|	MAX(
		|		CASE
		|			WHEN ISNULL(BatchData.NumberOfLotReferencesDenominator, 0) <> 0
		|				THEN BatchData.NumberOfLotReferencesNumerator / BatchData.NumberOfLotReferencesDenominator
		|			ELSE 0
		|		END)                                                       AS QuantityOfBatches,
		|	MIN(OrderStructure.Level)                                 AS Level,
		|	RECORDAUTONUMBER()                                                AS Order
		|INTO TTParty
		|FROM
		|	TTOrderStructure AS OrderStructure
		|
		|	LEFT JOIN Document.ProductionStage2_2 AS Stages
		|	ON OrderStructure.Stage = Stages.Ref
		|
		|	LEFT JOIN Document.ProductionOrder2_2.ManufacturedProduct AS OrderProducts_
		|	ON OrderStructure.ProductionOrder = OrderProducts_.Ref
		|		AND OrderStructure.KeyProducts = OrderProducts_.KeyProducts
		|
		|	LEFT JOIN TTNumberOfLotReferences AS BatchData
		|	ON OrderStructure.KeyLot = BatchData.KeyLot
		|
		|GROUP BY
		|	OrderStructure.ProductionOrder,
		|	OrderStructure.KeyLot,
		|	ISNULL(Stages.ProductionLot, OrderStructure.BillOfMaterials)
		|
		|ORDER BY
		|	DurationBeforeProductionIssue DESC,
		|	OrderOfLaunch,
		|	LineNumberProducts,
		|	ProductionLotIDInProductGroup,
		|	KeyLot
		|
		|INDEX BY
		|	Ref";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTOfCommunicationOfPartiesAndStagesCatalog()
	
	QueryText = 
		"SELECT
		|	Stages.Owner AS PartyLink,
		|	Stages.Ref   AS Ref
		|INTO TTCommunicationOfPartiesAndStagesCatalog
		|FROM
		|	Catalog.ProductionStages AS Stages
		|WHERE
		|	Stages.Owner IN (
		|		SELECT
		|			T.Ref AS Owner
		|		FROM
		|			TTParty AS T)
		|
		|INDEX BY
		|	Ref";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTStagesCatalog()
	
	QueryText = 
		"SELECT
		|	Links.PartyLink                           AS PartyLink,
		|	Stages.Ref                                 AS Ref,
		|	Stages.Owner                               AS Owner,
		|	Stages.Department                          AS Department,
		|	Stages.StageNumber                             AS StageNumber,
		|	Stages.NextStageNo                   AS NextStageNo,
		|	Stages.PlanOperationsOfWorkCenterTypes   AS PlanOperationsOfWorkCenterTypes,
		|	Stages.OperatingProcedureOfWorkCenterTypes       AS OperatingProcedureOfWorkCenterTypes,
		|	Stages.UnitOfMeasureOfStageDuration      AS UnitOfMeasureOfStageDuration,
		|	Stages.StageDuration                      AS StageDuration,
		|	Stages.UnitOfMeasureOfPreliminaryBuffer AS UnitOfMeasureOfPreliminaryBuffer,
		|	Stages.PreliminaryBuffer                   AS PreliminaryBuffer,
		|	Stages.UnitOfMeasureOfFollowUpBuffer     AS UnitOfMeasureOfFollowUpBuffer,
		|	Stages.FollowUpBuffer                       AS FollowUpBuffer,
		|	Stages.Continuous_                            AS Continuous_,
		|	Stages.WorkPlanning                      AS WorkPlanning
		|INTO TTStagesCatalog
		|FROM
		|	TTCommunicationOfPartiesAndStagesCatalog AS Links
		|	
		|	INNER JOIN Catalog.ProductionStages AS Stages
		|	ON Links.Ref = Stages.Ref
		|WHERE
		|	NOT Stages.DeletionMark
		|
		|INDEX BY
		|	PartyLink";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTOfCommunicationOfBatchesAndStagesIsDocument()
	
	QueryText = 
		"SELECT
		|	Stages.ProductionLot AS PartyLink,
		|	Stages.Ref             AS Ref
		|INTO TTCommunicationOfPartiesAndStagesDocument
		|FROM
		|	Document.ProductionStage2_2 AS Stages
		|WHERE
		|	Stages.ProductionLot IN (
		|		SELECT
		|			T.Ref AS ProductionLot
		|		FROM
		|			TTParty AS T)
		|
		|INDEX BY
		|	PartyLink";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTLinks()
	
	QueryText = 
		"SELECT
		|	Links.KeyLot                        AS KeyLot,
		|	Links.Stage                              AS Stage,
		|	Links.ProductionOrder               AS ProductionOrder,
		|	Links.KeyIsPredecessorParty          AS KeyIsPredecessorParty,
		|	Links.PredecessorStage                AS PredecessorStage,
		|	Links.ProductionOrderPredecessor AS ProductionOrderPredecessor
		|INTO TTCommunication
		|FROM
		|	TTCommunicationBetweenLotREFERENCES AS Links
		|
		|UNION ALL
		|
		|SELECT
		|	Lots.KeyLot          AS KeyLot,
		|	Stages2.Ref              AS Stage,
		|	Lots.ProductionOrder AS ProductionOrder,
		|	Lots.KeyLot          AS KeyIsPredecessorParty,
		|	Stages1.Ref              AS PredecessorStage,
		|	Lots.ProductionOrder AS ProductionOrderPredecessor
		|FROM
		|	TTParty AS Lots
		|	
		|	INNER JOIN TTStagesCatalog AS Stages1
		|	ON Lots.Ref = Stages1.PartyLink
		|	
		|	INNER JOIN TTStagesCatalog AS Stages2
		|	ON Stages1.PartyLink = Stages2.PartyLink
		|		AND Stages1.NextStageNo = Stages2.StageNumber
		|
		|UNION ALL
		|
		|SELECT
		|	Lots.KeyLot          AS KeyLot,
		|	SuccessorSteps.Stage    AS Stage,
		|	Lots.ProductionOrder AS ProductionOrder,
		|	Lots.KeyLot          AS KeyIsPredecessorParty,
		|	Stages.Ref               AS PredecessorStage,
		|	Lots.ProductionOrder AS ProductionOrderPredecessor
		|FROM
		|	TTParty AS Lots
		|	
		|	INNER JOIN TTCommunicationOfPartiesAndStagesDocument AS Links
		|	ON Lots.Ref = Links.PartyLink
		|	
		|	INNER JOIN Document.ProductionStage2_2 AS Stages
		|	ON Links.Ref = Stages.Ref
		|	
		|	INNER JOIN Document.ProductionStage2_2.Successors AS SuccessorSteps
		|	ON Stages.Ref = SuccessorSteps.Ref
		|		AND SuccessorSteps.LinkType = 0
		|	
		|WHERE
		|	Stages.Posted
		|
		|UNION ALL
		|
		|SELECT
		|	ScheduleRAndM.KeyLot  AS KeyLot,
		|	ScheduleRAndM.Stage        AS Stage,
		|	Lots.ProductionOrder AS ProductionOrder,
		|	ScheduleRAndM.PlanNotEarlierThanKeyLot AS KeyIsPredecessorParty,
		|	ISNULL(PredecessorsCatalog.Ref, PredecessorsOfDocument.Ref) AS PredecessorStage,
		|	Lots.ProductionOrder                  AS ProductionOrderPredecessor
		|FROM
		|	TTParty AS Lots
		|	
		|	INNER JOIN Catalog.ProductionStages AS Stages
		|	ON Lots.Ref = Stages.Owner
		|
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleRAndM
		|	ON Lots.ProductionOrder = ScheduleRAndM.ProductionOrder
		|		AND ScheduleRAndM.ScheduleStatus = 0
		|		AND Stages.Ref = ScheduleRAndM.Stage
		|		AND Lots.KeyLot = ScheduleRAndM.KeyLot
		|
		|	LEFT JOIN Catalog.ProductionStages AS PredecessorsCatalog
		|	ON ScheduleRAndM.PlanNotEarlierThanStage REFS Catalog.ProductionStages
		|		AND CAST(ScheduleRAndM.PlanNotEarlierThanStage AS Catalog.ProductionStages).Owner = PredecessorsCatalog.Owner
		|		AND CAST(ScheduleRAndM.PlanNotEarlierThanStage AS Catalog.ProductionStages).StageNumber = PredecessorsCatalog.NextStageNo
		|		AND NOT PredecessorsCatalog.DeletionMark
		|
		|	LEFT JOIN Document.ProductionStage2_2.Successors AS PredecessorsOfDocument
		|	ON ScheduleRAndM.PlanNotEarlierThanStage REFS Document.ProductionStage2_2
		|		AND ScheduleRAndM.PlanNotEarlierThanStage = PredecessorsOfDocument.Stage
		|		AND PredecessorsOfDocument.LinkType = 0
		|WHERE
		|	Lots.ProductionOrder IN (
		|		SELECT
		|			T.Ref AS ProductionOrder
		|		FROM
		|			TTOrdersForRAndM AS T)
		|	AND Lots.ProductionOrder NOT IN (
		|		SELECT
		|			T.ProductionOrder
		|		FROM
		|			TTOrdersForRAndMToCalculationOfOrder AS T)
		|	AND NOT Stages.DeletionMark
		|	AND ScheduleRAndM.PlanNotEarlierThanStage <> VALUE(Catalog.ProductionStages.EmptyRef)
		|	AND ISNULL(PredecessorsCatalog.Ref, PredecessorsOfDocument.Ref) IS NOT NULL
		|
		|INDEX BY SETS (
		|	(ProductionOrder, KeyLot, Stage),
		|	(ProductionOrderPredecessor, KeyIsPredecessorParty, PredecessorStage),
		|	(PredecessorStage)
		|)";
	
	Return QueryText;
	
EndFunction

Function QueryTextLinks(CancelManualChangesOfSchedule)
	
	QueryText = 
		"SELECT
		|	Links.KeyLot               AS KeyLot,
		|	Links.Stage                     AS Stage,
		|	Links.KeyIsPredecessorParty AS KeyIsPredecessorParty,
		|	Links.PredecessorStage       AS PredecessorStage
		|FROM
		|	TTCommunication AS Links
		|WHERE
		|	&QueryTextExcludeStepsWithManualPlacement";
	If CancelManualChangesOfSchedule Then
		QueryText = StrReplace(QueryText,
			"&QueryTextExcludeStepsWithManualPlacement",
			"TRUE");
	Else
		// Dates of predecessors with manual placement are taken into account when selecting stages
		// (see dates of unplanned predecessors)
		QueryText = StrReplace(QueryText,
			"&QueryTextExcludeStepsWithManualPlacement",
			"NOT TRUE IN (
			|	SELECT TOP 1
			|		TRUE
			|	FROM
			|		TTStagesWithManualPlacement AS T
			|	WHERE 
			|		T.Ref = Links.PredecessorStage)");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextRepairLinks()
	
	QueryText = 
		"SELECT
		|	Links.KeyLot               AS KeyLot,
		|	Links.Stage                     AS Stage,
		|	Links.KeyIsPredecessorParty AS KeyIsLotReferenceRAndM
		|FROM
		|	TTCommunicationBetweenLotREFERENCES AS Links
		|WHERE
		|	Links.ProductionOrder.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|	AND Links.Stage.WorkPlanning";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTStagesWithManualPlacement(QueryTextFilter)
	
	QueryText = 
		"SELECT
		|	Stages.ReferenceOrder AS ProductionOrder,
		|	Stages.Ref       AS Ref
		|INTO TTStagesWithManualPlacement
		|FROM
		|	Document.ProductionStage2_2 AS Stages
		|WHERE
		|	&QueryTextFilter
		|	AND Stages.Posted
		|	AND NOT Stages.Status IN (
		|		VALUE(Enum.StatusesOfProductionStages2_2.Initiated),
		|		VALUE(Enum.StatusesOfProductionStages2_2.Completed))
		|	AND Stages.StagePlacementInProductionSchedule
		|
		|INDEX BY
		|	Ref";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextFilter",
		StrReplace(QueryTextFilter, "&TextTableName", "Stages"));
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDatesOfUnplannedPredecessors(QueryTextFilter)
	
	QueryText = 
		"SELECT
		|	Links.KeyLot           AS KeyLot,
		|	Links.Stage                 AS Stage,
		|	MAX(Schedule.Ending) AS Ending
		|INTO TTDatesOfUnplannedPredecessors
		|FROM
		|	TTCommunication AS Links
		|	
		|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Links.ProductionOrderPredecessor = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = 0
		|		AND Links.PredecessorStage = Schedule.Stage
		|		AND Links.KeyIsPredecessorParty = Schedule.KeyLot
		|WHERE
		|	Links.PredecessorStage IN (
		|		SELECT
		|			Stages.Ref
		|		FROM
		|			TTStagesWithManualPlacement AS Stages
		|		WHERE
		|			NOT &CancelManualChangesOfSchedule
		|		
		|		UNION ALL
		|		
		|		SELECT
		|			Stages.Ref
		|		FROM
		|			Document.ProductionStage2_2 AS Stages
		|		WHERE
		|			&QueryTextFilter
		|			AND Stages.Posted
		|			AND Stages.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated))
		|
		|GROUP BY
		|	Links.KeyLot,
		|	Links.Stage
		|
		|INDEX BY
		|	KeyLot, Stage";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextFilter",
		StrReplace(QueryTextFilter, "&TextTableName", "Stages"));
	
	Return QueryText;
	
EndFunction

Function QueryTextStages(CreateTT)
	
	QueryText = 
		"SELECT
		|	Lots.ProductionOrder                         AS ProductionOrder,
		|	&ScheduleStatus                                     AS ScheduleStatus,
		|	Lots.KeyLot                                  AS KeyLot,
		|	Stages.Ref                                       AS Stage,
		|	VALUE(Enum.ProductionScheduleRowKinds.Stage) AS LineKind,
		|	DATETIME(1, 1, 1, 0, 0, 0)                        AS Begin,
		|	DATETIME(1, 1, 1, 0, 0, 0)                        AS Ending,
		|	DATETIME(1, 1, 1, 0, 0, 0)                        AS PreliminaryBufferEnd,
		|	DATETIME(1, 1, 1, 0, 0, 0)                        AS FollowUpBufferStart,
		|	DATETIME(1, 1, 1, 0, 0, 0)                        AS NextStageStart,
		|	FALSE                                               AS EquipmentLimited,
		|	DATETIME(1, 1, 1, 0, 0, 0)                        AS RequiredSupplyDate,
		|	VALUE(Enum.WayOfLinkingProductionOperations.Backward) AS ProductionScheduling,
		|	Stages.Department                                AS Department,
		|	Stages.Owner                                     AS BillOfMaterials,
		|	Lots.QuantityOfBatches                            AS QuantityOfBatches,
		|	CASE
		|		WHEN OrdersForRAndMToCalculationOfOrder.ProductionOrder IS NOT NULL
		|			THEN 0
		|		WHEN OrderData.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|			THEN ISNULL(Schedule.Order, 0)
		|		ELSE Lots.DurationBeforeProductionIssue + ISNULL(StepsDuration.DurationBeforeProductionIssue, 0)
		|	END                                              AS Order,
		|	CASE
		|		WHEN OrdersForRAndMToCalculationOfOrder.ProductionOrder IS NOT NULL
		|			THEN VALUE(Catalog.ProductionStages.EmptyRef)
		|		ELSE ISNULL(Schedule.PlanNotEarlierThanStage, VALUE(Catalog.ProductionStages.EmptyRef))
		|	END                                              AS PlanNotEarlierThanStage,
		|	CASE
		|		WHEN OrdersForRAndMToCalculationOfOrder.ProductionOrder IS NOT NULL
		|			THEN &EmptyLinkKey
		|		ELSE ISNULL(Schedule.PlanNotEarlierThanKeyLot, &EmptyLinkKey)
		|	END                                              AS PlanNotEarlierThanKeyLot,
		|
		|	Stages.Department.PlanningInterval           AS PlanningInterval,
		|	Stages.Department.PlanningIntervalStart    AS IntervalStart,
		|	Stages.Department.PlanningIntervalEnd AS IntervalEnd_,
		|	CASE
		|		WHEN Stages.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
		|			THEN BEGINOFPERIOD(Stages.Department.PlanningIntervalStart, DAY) <> Stages.Department.PlanningIntervalStart
		|								OR ENDOFPERIOD(Stages.Department.PlanningIntervalEnd, DAY) <> Stages.Department.PlanningIntervalEnd
		|		WHEN Stages.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
		|			THEN BEGINOFPERIOD(Stages.Department.PlanningIntervalStart, WEEK) <> Stages.Department.PlanningIntervalStart
		|								OR ENDOFPERIOD(Stages.Department.PlanningIntervalEnd, WEEK) <> Stages.Department.PlanningIntervalEnd
		|		ELSE FALSE
		|	END                                              AS IntervalHasNonStandardBoundaries,
		|	Stages.StageNumber                                   AS StageNumber,
		|	Stages.NextStageNo                         AS NextStageNo,
		|	Stages.PlanOperationsOfWorkCenterTypes         AS PlanTypesOfRC,
		|	Stages.OperatingProcedureOfWorkCenterTypes             AS OrderOfOperationOfTypesOfRC,
		|	CASE Stages.UnitOfMeasureOfStageDuration
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN Stages.StageDuration
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Stages.StageDuration * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Stages.StageDuration * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|			THEN Stages.StageDuration
		|	END                                              AS StageDuration,
		|	Stages.UnitOfMeasureOfStageDuration = VALUE(
		|		Enum.TimeMeasureUnits.DAY)     AS PostInDays,
		|	CASE
		|		WHEN ISNULL(StepsDuration.DurationInSeconds, 0) = 0
		|			THEN 0.0001
		|		ELSE ISNULL(StepsDuration.DurationInSeconds, 0)
		|	END                                              AS ResourceIntensity,
		|	CASE Stages.UnitOfMeasureOfPreliminaryBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN Stages.PreliminaryBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Stages.PreliminaryBuffer * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Stages.PreliminaryBuffer * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|			THEN Stages.PreliminaryBuffer
		|	END                                              AS BufferUpTo,
		|	Stages.UnitOfMeasureOfPreliminaryBuffer = VALUE(
		|		Enum.TimeMeasureUnits.DAY)     AS BufferUpToPostInDays,
		|	CASE Stages.UnitOfMeasureOfFollowUpBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN Stages.FollowUpBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Stages.FollowUpBuffer * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Stages.FollowUpBuffer * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|			THEN Stages.FollowUpBuffer
		|	END                                              AS BufferAfter,
		|	Stages.UnitOfMeasureOfFollowUpBuffer = VALUE(
		|		Enum.TimeMeasureUnits.DAY)     AS BufferAfterPlacingInDays,
		|	Stages.Continuous_                                  AS Continuous_,
		|	CASE
		|		WHEN &QueryTextAvailabilityDate >= &QueryTextDateOfPredecessors
		|			AND &QueryTextAvailabilityDate >= OrderData.EarliestStartDate
		|			AND &QueryTextAvailabilityDate >= &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|			AND &QueryTextAvailabilityDate >= &CurrentDate
		|			THEN &QueryTextAvailabilityDate
		|		WHEN &QueryTextDateOfPredecessors >= OrderData.EarliestStartDate
		|			AND &QueryTextDateOfPredecessors >= &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|			AND &QueryTextDateOfPredecessors >= &CurrentDate
		|			THEN &QueryTextDateOfPredecessors
		|		WHEN OrderData.EarliestStartDate >= &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|			AND OrderData.EarliestStartDate >= &CurrentDate
		|			THEN OrderData.EarliestStartDate
		|		WHEN &QueryTextOfStageOfRAndMIsPlannedNoEarlier >= &CurrentDate
		|			THEN &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|		ELSE &CurrentDate
		|	END                                              AS StartOfPlacement,
		|	NOT Stages.WorkPlanning
		|		OR NOT TRUE IN (
		|			SELECT TOP 1
		|				TRUE
		|			FROM
		|				TTCommunicationBetweenLotREFERENCES AS LinksBetweenParties
		|			WHERE
		|				LinksBetweenParties.KeyLot = Lots.KeyLot
		|				AND LinksBetweenParties.Stage = Stages.Ref
		|		)                                              AS ToPlan_2,
		|	FALSE                                               AS IsDocument,
		|	FALSE                                               AS ItIsTransfer,
		|	Lots.ThisIsProductionOfProducts                    AS ThisIsProductionOfProducts,
		|	Stages.WorkPlanning                            AS ThisIsWorkPlanning,
		|	OrderData.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|		AND NOT TRUE IN (
		|			SELECT TOP 1
		|				TRUE
		|			FROM
		|				Catalog.ProductionStages AS StagesOnLeft
		|			WHERE
		|				StagesOnLeft.Owner = Stages.Owner
		|				AND StagesOnLeft.NextStageNo = Stages.StageNumber
		|				AND NOT StagesOnLeft.DeletionMark)       AS ThisIsInitialStageOfRepair,
		|	DATETIME(1,1,1)                                   AS PlanNotEarlierThan,
		|	CASE
		|		WHEN Stages.NextStageNo = 0
		|			THEN ISNULL(Lots.DateOfNeedOfManufacturedProduct, DATETIME(1,1,1))
		|		ELSE DATETIME(1,1,1)
		|	END                                              AS RightBorder_,
		|	Stages.NextStageNo = 0
		|		AND ISNULL(Lots.DateOfNeedOfManufacturedProduct, DATETIME(1,1,1)) <> DATETIME(1,1,1) AS ThereIsRightBorder,
		|	OrderData.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Assembly)
		|		AND NOT Stages.PlanOperationsOfWorkCenterTypes
		|		AND (
		|			TRUE IN (
		|				SELECT TOP 1
		|					TRUE
		|				FROM
		|					Catalog.ProductionStages AS StagesOnRight
		|				WHERE
		|					StagesOnRight.Owner = Stages.Owner
		|					AND StagesOnRight.PlanOperationsOfWorkCenterTypes
		|					AND StagesOnRight.StageNumber > Stages.StageNumber
		|					AND NOT StagesOnRight.DeletionMark)
		|			OR NOT TRUE IN (
		|				SELECT TOP 1
		|					TRUE
		|				FROM
		|					Catalog.ProductionStages AS StagesOnLeft
		|				WHERE
		|					StagesOnLeft.Owner = Stages.Owner
		|					AND StagesOnLeft.PlanOperationsOfWorkCenterTypes
		|					AND StagesOnLeft.StageNumber < Stages.StageNumber
		|					AND NOT StagesOnLeft.DeletionMark)
		|		)                                                AS ShiftToRight,
		|	ISNULL(Schedule.Begin, DATETIME(1,1,1))            AS StartBeforeChange,
		|	ISNULL(Schedule.Ending, DATETIME(1,1,1))         AS EndingBeforeChange,
		|	FALSE                                                 AS ScheduleIsChanged,
		|	CASE
		|		WHEN OrdersForRAndMToCalculationOfOrder.ProductionOrder IS NOT NULL
		|			THEN Lots.Level
		|		WHEN OrderData.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|			THEN -ISNULL(Schedule.Order, 0)
		|		ELSE Lots.Order
		|	END                                                AS Order1,
		|	CASE
		|		WHEN OrdersForRAndMToCalculationOfOrder.ProductionOrder IS NOT NULL
		|			THEN -Stages.StageNumber
		|		ELSE Stages.StageNumber
		|	END                                                AS Order2
		|FROM
		|	TTParty AS Lots
		|	
		|	INNER JOIN TTStagesCatalog AS Stages
		|	ON Lots.Ref = Stages.PartyLink
		|
		|	LEFT JOIN TTProductionScheduleRestrictionsOnMaterials AS Supply
		|	ON Lots.ProductionOrder = Supply.ProductionOrder
		|		AND Lots.KeyLot = Supply.KeyLot
		|		AND Stages.Ref = Supply.Stage
		|
		|	LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS StepsDuration
		|	ON Stages.Ref = StepsDuration.Stage
		|		AND Lots.Ref = StepsDuration.BillOfMaterials
		|
		|	LEFT JOIN TTDatesOfUnplannedPredecessors AS PredecessorDates
		|	ON Lots.KeyLot = PredecessorDates.KeyLot
		|		AND Stages.Ref = PredecessorDates.Stage
		|
		|	LEFT JOIN Document.ProductionOrder2_2 AS OrderData
		|	ON Lots.ProductionOrder = OrderData.Ref
		|
		|	LEFT JOIN TTOrdersForRAndMToCalculationOfOrder AS OrdersForRAndMToCalculationOfOrder
		|	ON Lots.ProductionOrder = OrdersForRAndMToCalculationOfOrder.ProductionOrder
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Lots.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = 0
		|		AND Stages.Ref = Schedule.Stage
		|		AND Lots.KeyLot = Schedule.KeyLot
		|
		|UNION ALL
		|
		|SELECT
		|	Lots.ProductionOrder                         AS ProductionOrder,
		|	&ScheduleStatus                                     AS ScheduleStatus,
		|	Lots.KeyLot                                  AS KeyLot,
		|	Stages.Ref                                       AS Stage,
		|	VALUE(Enum.ProductionScheduleRowKinds.Stage) AS LineKind,
		|	DATETIME(1, 1, 1, 0, 0, 0)                        AS Begin,
		|	DATETIME(1, 1, 1, 0, 0, 0)                        AS Ending,
		|	DATETIME(1, 1, 1, 0, 0, 0)                        AS PreliminaryBufferEnd,
		|	DATETIME(1, 1, 1, 0, 0, 0)                        AS FollowUpBufferStart,
		|	DATETIME(1, 1, 1, 0, 0, 0)                        AS NextStageStart,
		|	FALSE                                               AS EquipmentLimited,
		|	DATETIME(1, 1, 1, 0, 0, 0)                        AS RequiredSupplyDate,
		|	VALUE(Enum.WayOfLinkingProductionOperations.Backward) AS ProductionScheduling,
		|	Stages.Department                                AS Department,
		|	Stages.BillOfMaterials                                 AS BillOfMaterials,
		|	Lots.QuantityOfBatches                            AS QuantityOfBatches,
		|	CASE
		|		WHEN OrdersForRAndMToCalculationOfOrder.ProductionOrder IS NOT NULL
		|			THEN 0
		|		WHEN OrderData.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|			THEN ISNULL(Schedule.Order, 0)
		|		ELSE Lots.DurationBeforeProductionIssue + Stages.DurationBeforeProductionIssue
		|	END                                              AS Order,
		|	VALUE(Catalog.ProductionStages.EmptyRef) AS PlanNotEarlierThanStage,
		|	&EmptyLinkKey                                   AS PlanNotEarlierThanKeyLot,
		|
		|	Stages.Department.PlanningInterval           AS PlanningInterval,
		|	Stages.Department.PlanningIntervalStart    AS IntervalStart,
		|	Stages.Department.PlanningIntervalEnd AS IntervalEnd_,
		|	CASE
		|		WHEN Stages.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
		|			THEN BEGINOFPERIOD(Stages.Department.PlanningIntervalStart, DAY) <> Stages.Department.PlanningIntervalStart
		|								OR ENDOFPERIOD(Stages.Department.PlanningIntervalEnd, DAY) <> Stages.Department.PlanningIntervalEnd
		|		WHEN Stages.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
		|			THEN BEGINOFPERIOD(Stages.Department.PlanningIntervalStart, WEEK) <> Stages.Department.PlanningIntervalStart
		|								OR ENDOFPERIOD(Stages.Department.PlanningIntervalEnd, WEEK) <> Stages.Department.PlanningIntervalEnd
		|		ELSE FALSE
		|	END                                              AS IntervalHasNonStandardBoundaries,
		|	Stages.StageNumber                                   AS StageNumber,
		|	Stages.NextStageNo                         AS NextStageNo,
		|	CASE
		|		WHEN &CancelManualChangesOfSchedule
		|			AND Stages.StagePlacementInProductionSchedule
		|			THEN TypesOfRC.WorkCenterType IS NOT NULL
		|		ELSE Stages.PlanOperationsOfWorkCenterTypes
		|	END                                              AS PlanTypesOfRC,
		|	Stages.OperatingProcedureOfWorkCenterTypes             AS OrderOfOperationOfTypesOfRC,
		|	CASE Stages.UnitOfMeasureOfStageDuration
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN Stages.StageDuration
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Stages.StageDuration * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Stages.StageDuration * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|			THEN Stages.StageDuration
		|	END                                              AS StageDuration,
		|	Stages.UnitOfMeasureOfStageDuration = VALUE(
		|		Enum.TimeMeasureUnits.DAY)     AS PostInDays,
		|	CASE
		|		WHEN Stages.StageDuration = 0
		|			THEN 0.0001
		|		ELSE 
		|			CASE Stages.UnitOfMeasureOfStageDuration
		|				WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|					THEN Stages.StageDuration * 86400
		|				WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|					THEN Stages.StageDuration * 60
		|				WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|					THEN Stages.StageDuration * 3600
		|				WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|					THEN Stages.StageDuration
		|			END
		|	END                                              AS ResourceIntensity,
		|	CASE Stages.UnitOfMeasureOfPreliminaryBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN Stages.PreliminaryBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Stages.PreliminaryBuffer * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Stages.PreliminaryBuffer * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|			THEN Stages.PreliminaryBuffer
		|	END                                              AS BufferUpTo,
		|	Stages.UnitOfMeasureOfPreliminaryBuffer = VALUE(
		|		Enum.TimeMeasureUnits.DAY)     AS BufferUpToPostInDays,
		|	CASE Stages.UnitOfMeasureOfFollowUpBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN Stages.FollowUpBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Stages.FollowUpBuffer * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Stages.FollowUpBuffer * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|			THEN Stages.FollowUpBuffer
		|	END                                              AS BufferAfter,
		|	Stages.UnitOfMeasureOfFollowUpBuffer = VALUE(
		|		Enum.TimeMeasureUnits.DAY)     AS BufferAfterPlacingInDays,
		|	Stages.Continuous_                                  AS Continuous_,
		|	CASE
		|		WHEN &QueryTextAvailabilityDate >= &QueryTextStageShouldBePlannedNoEarlier
		|			AND &QueryTextAvailabilityDate >= &QueryTextDateOfPredecessors
		|			AND &QueryTextAvailabilityDate >= OrderData.EarliestStartDate
		|			AND &QueryTextAvailabilityDate >= &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|			AND &QueryTextAvailabilityDate >= &CurrentDate
		|			THEN &QueryTextAvailabilityDate
		|		WHEN &QueryTextStageShouldBePlannedNoEarlier >= &QueryTextDateOfPredecessors
		|			AND &QueryTextStageShouldBePlannedNoEarlier >= OrderData.EarliestStartDate
		|			AND &QueryTextStageShouldBePlannedNoEarlier >= &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|			AND &QueryTextStageShouldBePlannedNoEarlier >= &CurrentDate
		|			THEN &QueryTextStageShouldBePlannedNoEarlier
		|		WHEN &QueryTextDateOfPredecessors >= OrderData.EarliestStartDate
		|			AND &QueryTextDateOfPredecessors >= &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|			AND &QueryTextDateOfPredecessors >= &CurrentDate
		|			THEN &QueryTextDateOfPredecessors
		|		WHEN OrderData.EarliestStartDate >= &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|			AND OrderData.EarliestStartDate >= &CurrentDate
		|			THEN OrderData.EarliestStartDate
		|		WHEN &QueryTextOfStageOfRAndMIsPlannedNoEarlier >= &CurrentDate
		|			THEN &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|		ELSE &CurrentDate
		|	END                                              AS StartOfPlacement,
		|	NOT Stages.WorkPlanning
		|		OR NOT TRUE IN (
		|			SELECT TOP 1
		|				TRUE
		|			FROM
		|				TTCommunicationBetweenLotREFERENCES AS LinksBetweenParties
		|			WHERE
		|				LinksBetweenParties.KeyLot = Lots.KeyLot
		|				AND LinksBetweenParties.Stage = Stages.Ref
		|		)                                              AS ToPlan_2,
		|	TRUE                                             AS IsDocument,
		|	FALSE                                               AS ItIsTransfer,
		|	Lots.ThisIsProductionOfProducts                    AS ThisIsProductionOfProducts,
		|	Stages.WorkPlanning                            AS ThisIsWorkPlanning,
		|	OrderData.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|		AND NOT TRUE IN (
		|			SELECT TOP 1
		|				TRUE
		|			FROM
		|				Document.ProductionStage2_2.Successors AS StagesOnLeft
		|			WHERE
		|				StagesOnLeft.Ref.ProductionLot = Stages.ProductionLot
		|				AND StagesOnLeft.Ref.Posted
		|				AND StagesOnLeft.Ref.Status <> VALUE(Enum.StatusesOfProductionStages2_2.Completed)
		|				AND StagesOnLeft.Stage = Stages.Ref
		|				AND StagesOnLeft.LinkType = 0)             AS ThisIsInitialStageOfRepair,
		|	&QueryTextStageShouldBePlannedNoEarlier                AS PlanNotEarlierThan,
		|	DATETIME(1,1,1)                                   AS RightBorder_,
		|	FALSE                                               AS ThereIsRightBorder,
		|	OrderData.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Assembly)
		|		AND NOT CASE
		|				WHEN &CancelManualChangesOfSchedule
		|					AND Stages.StagePlacementInProductionSchedule
		|					THEN TypesOfRC.WorkCenterType IS NOT NULL
		|				ELSE Stages.PlanOperationsOfWorkCenterTypes
		|			END
		|		AND TRUE IN (
		|			SELECT TOP 1
		|				TRUE
		|			FROM
		|				Document.ProductionStage2_2 AS StagesOnRight
		|				
		|				LEFT JOIN Document.ProductionStage2_2.WorkCenterTypes AS TypesOfRCStagesOnRight
		|				ON &CancelManualChangesOfSchedule
		|					AND StagesOnRight.StagePlacementInProductionSchedule
		|					AND StagesOnRight.Ref = TypesOfRCStagesOnRight.Ref
		|					AND TypesOfRCStagesOnRight.LineNumber = 1
		|			WHERE
		|				StagesOnRight.ProductionLot = Stages.ProductionLot
		|				AND CASE
		|					WHEN &CancelManualChangesOfSchedule
		|						AND StagesOnRight.StagePlacementInProductionSchedule
		|						THEN TypesOfRCStagesOnRight.WorkCenterType IS NOT NULL
		|					ELSE StagesOnRight.PlanOperationsOfWorkCenterTypes
		|				END
		|				AND StagesOnRight.StageNumber > Stages.StageNumber
		|				AND StagesOnRight.Posted)                  AS ShiftToRight,
		|	ISNULL(Schedule.Begin, DATETIME(1,1,1))            AS StartBeforeChange,
		|	ISNULL(Schedule.Ending, DATETIME(1,1,1))         AS EndingBeforeChange,
		|	FALSE                                                 AS ScheduleIsChanged,
		|	CASE
		|		WHEN OrdersForRAndMToCalculationOfOrder.ProductionOrder IS NOT NULL
		|			THEN Lots.Level
		|		WHEN OrderData.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|			THEN -ISNULL(Schedule.Order, 0)
		|		ELSE Lots.Order
		|	END                                                AS Order1,
		|	CASE
		|		WHEN OrdersForRAndMToCalculationOfOrder.ProductionOrder IS NOT NULL
		|			THEN -Stages.StageNumber
		|		ELSE Stages.StageNumber
		|	END                                                AS Order2
		|FROM
		|	TTParty AS Lots
		|	
		|	INNER JOIN TTCommunicationOfPartiesAndStagesDocument AS Links
		|	ON Lots.Ref = Links.PartyLink
		|	
		|	INNER JOIN Document.ProductionStage2_2 AS Stages
		|	ON Links.Ref = Stages.Ref
		|	
		|	LEFT JOIN TTProductionScheduleRestrictionsOnMaterials AS Supply
		|	ON Lots.ProductionOrder = Supply.ProductionOrder
		|		AND Lots.KeyLot = Supply.KeyLot
		|		AND Stages.Ref = Supply.Stage
		|
		|	LEFT JOIN TTDatesOfUnplannedPredecessors AS PredecessorDates
		|	ON Lots.KeyLot = PredecessorDates.KeyLot
		|		AND Stages.Ref = PredecessorDates.Stage
		|
		|	LEFT JOIN Document.ProductionStage2_2.WorkCenterTypes AS TypesOfRC
		|	ON &CancelManualChangesOfSchedule
		|		AND Stages.StagePlacementInProductionSchedule
		|		AND Stages.Ref = TypesOfRC.Ref
		|		AND TypesOfRC.LineNumber = 1
		|
		|	LEFT JOIN Document.ProductionOrder2_2 AS OrderData
		|	ON Lots.ProductionOrder = OrderData.Ref
		|
		|	LEFT JOIN TTOrdersForRAndMToCalculationOfOrder AS OrdersForRAndMToCalculationOfOrder
		|	ON Lots.ProductionOrder = OrdersForRAndMToCalculationOfOrder.ProductionOrder
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Lots.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = 0
		|		AND Stages.Ref = Schedule.Stage
		|		AND Lots.KeyLot = Schedule.KeyLot
		|
		|WHERE
		|	Stages.Posted
		|	AND NOT Stages.Status IN (
		|		VALUE(Enum.StatusesOfProductionStages2_2.Initiated),
		|		VALUE(Enum.StatusesOfProductionStages2_2.Completed))
		|	AND (&CancelManualChangesOfSchedule OR NOT Stages.StagePlacementInProductionSchedule)
		|
		|UNION ALL
		|
		|SELECT
		|	Lots.ProductionOrder    AS ProductionOrder,
		|	&ScheduleStatus                AS ScheduleStatus,
		|	Lots.KeyLot             AS KeyLot,
		|	VALUE(Catalog.ProductionStages.EmptyRef)    AS Stage,
		|	VALUE(Enum.ProductionScheduleRowKinds.Move) AS LineKind,
		|	DATETIME(1, 1, 1, 0, 0, 0)   AS Begin,
		|	DATETIME(1, 1, 1, 0, 0, 0)   AS Ending,
		|	DATETIME(1, 1, 1, 0, 0, 0)   AS PreliminaryBufferEnd,
		|	DATETIME(1, 1, 1, 0, 0, 0)   AS FollowUpBufferStart,
		|	DATETIME(1, 1, 1, 0, 0, 0)   AS NextStageStart,
		|	FALSE                          AS EquipmentLimited,
		|	DATETIME(1, 1, 1, 0, 0, 0)   AS RequiredSupplyDate,
		|	VALUE(Enum.WayOfLinkingProductionOperations.Backward) AS ProductionScheduling,
		|	VALUE(Catalog.BusinessStructure.EmptyRef)  AS Department,
		|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
		|	0                             AS QuantityOfBatches,
		|	CASE
		|		WHEN OrdersForRAndMToCalculationOfOrder.ProductionOrder IS NOT NULL
		|			THEN 0
		|		WHEN OrderData.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|			THEN ISNULL(Schedule.Order, 0)
		|		ELSE Lots.DurationBeforeProductionIssue
		|	END                         AS Order,
		|	VALUE(Catalog.ProductionStages.EmptyRef) AS PlanNotEarlierThanStage,
		|	&EmptyLinkKey              AS PlanNotEarlierThanKeyLot,
		|
		|	UNDEFINED                  AS PlanningInterval,
		|	UNDEFINED                  AS IntervalStart,
		|	UNDEFINED                  AS IntervalEnd_,
		|	FALSE                          AS IntervalHasNonStandardBoundaries,
		|	0                             AS StageNumber,
		|	0                             AS NextStageNo,
		|	FALSE                          AS PlanTypesOfRC,
		|	UNDEFINED                  AS OrderOfOperationOfTypesOfRC,
		|	ISNULL(NSICache.SupplyMethod.ProductionDurationDays, 1)
		|		+ CASE
		|			WHEN ISNULL(Lots.WarehouseFromTransfer.ControlQualityOfReceivedGoods, FALSE)
		|					AND ISNULL(Lots.ItemOfMovement.ControlQualityOfReceivedGoods, FALSE)
		|				THEN Lots.ItemOfMovement.TermOfQualityControl
		|			ELSE 0
		|		END                     AS StageDuration,
		|	TRUE                        AS PostInDays,
		|	CASE
		|		WHEN ISNULL(NSICache.SupplyMethod.ProductionDurationDays, 1) = 0
		|			THEN 0.0001
		|		ELSE ISNULL(NSICache.SupplyMethod.ProductionDurationDays, 1) * 86400
		|	END                         AS ResourceIntensity,
		|	0                             AS BufferUpTo,
		|	FALSE                          AS BufferUpToPostInDays,
		|	0                             AS BufferAfter,
		|	FALSE                          AS BufferAfterPlacingInDays,
		|	FALSE                          AS Continuous_,
		|	CASE
		|		WHEN &QueryTextAvailabilityDate >= &QueryTextDateOfPredecessors
		|			AND &QueryTextAvailabilityDate >= OrderData.EarliestStartDate
		|			AND &QueryTextAvailabilityDate >= &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|			AND &QueryTextAvailabilityDate >= &CurrentDate
		|			THEN &QueryTextAvailabilityDate
		|		WHEN &QueryTextDateOfPredecessors >= OrderData.EarliestStartDate
		|			AND &QueryTextDateOfPredecessors >= &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|			AND &QueryTextDateOfPredecessors >= &CurrentDate
		|			THEN &QueryTextDateOfPredecessors
		|		WHEN OrderData.EarliestStartDate >= &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|			AND OrderData.EarliestStartDate >= &CurrentDate
		|			THEN OrderData.EarliestStartDate
		|		WHEN &QueryTextOfStageOfRAndMIsPlannedNoEarlier >= &CurrentDate
		|			THEN &QueryTextOfStageOfRAndMIsPlannedNoEarlier
		|		ELSE &CurrentDate
		|	END                         AS StartOfPlacement,
		|
		|	TRUE                        AS ToPlan_2,
		|	FALSE                          AS IsDocument,
		|	TRUE                        AS ItIsTransfer,
		|	Lots.ThisIsProductionOfProducts AS ThisIsProductionOfProducts,
		|	FALSE                          AS ThisIsWorkPlanning,
		|	FALSE                          AS ThisIsInitialStageOfRepair,
		|	DATETIME(1,1,1)              AS PlanNotEarlierThan,
		|	DATETIME(1,1,1)              AS RightBorder_,
		|	FALSE                          AS ThereIsRightBorder,
		|	OrderData.ProductionProcessType
		|		= VALUE(Enum.ProductionProcessTypes.Assembly) AS ShiftToRight,
		|	ISNULL(Schedule.Begin, DATETIME(1,1,1))            AS StartBeforeChange,
		|	ISNULL(Schedule.Ending, DATETIME(1,1,1))         AS EndingBeforeChange,
		|	FALSE                                                 AS ScheduleIsChanged,
		|	CASE
		|		WHEN OrdersForRAndMToCalculationOfOrder.ProductionOrder IS NOT NULL
		|			THEN Lots.Level
		|		WHEN OrderData.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
		|			THEN -ISNULL(Schedule.Order, 0)
		|		ELSE Lots.Order
		|	END                                                AS Order1,
		|	0                                                    AS Order2
		|FROM
		|	TTParty AS Lots
		|
		|	LEFT JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
		|	ON Lots.ItemOfMovement = NSICache.Products
		|		AND Lots.CharacteristicsOfMovement = NSICache.Characteristic
		|		AND Lots.WarehouseFromTransfer = NSICache.Warehouse
		|		AND Lots.PurposeOfMove = NSICache.Purpose
		|		AND Lots.ProductionOrder = NSICache.ProductionOrder
		|
		|	LEFT JOIN TTProductionScheduleRestrictionsOnMaterials AS Supply
		|	ON Lots.ProductionOrder = Supply.ProductionOrder
		|		AND Lots.KeyLot = Supply.KeyLot
		|		AND Supply.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|
		|	LEFT JOIN TTDatesOfUnplannedPredecessors AS PredecessorDates
		|	ON Lots.KeyLot = PredecessorDates.KeyLot
		|		AND PredecessorDates.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|
		|	LEFT JOIN Document.ProductionOrder2_2 AS OrderData
		|	ON Lots.ProductionOrder = OrderData.Ref
		|
		|	LEFT JOIN TTOrdersForRAndMToCalculationOfOrder AS OrdersForRAndMToCalculationOfOrder
		|	ON Lots.ProductionOrder = OrdersForRAndMToCalculationOfOrder.ProductionOrder
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON Lots.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = 0
		|		AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|		AND Lots.KeyLot = Schedule.KeyLot
		|WHERE
		|	Lots.Ref = VALUE(Catalog.BillsOfMaterials.EmptyRef)";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextAvailabilityDate",
		"ISNULL(Supply.AvailabilityDate, DATETIME(1,1,1))");
	
	QueryText = StrReplace(QueryText,
		"&QueryTextStageShouldBePlannedNoEarlier",
		"ISNULL(CAST(Stages.PlanNotEarlierThan AS DATE), DATETIME(1,1,1))");
	
	QueryText = StrReplace(QueryText,
		"&QueryTextOfStageOfRAndMIsPlannedNoEarlier",
		"ISNULL(CAST(CAST(Schedule.PlanNotEarlierThanStage AS Document.ProductionStage2_2).PlanNotEarlierThan AS DATE), DATETIME(1,1,1))");
	
	QueryText = StrReplace(QueryText,
		"&QueryTextDateOfPredecessors",
		"ISNULL(PredecessorDates.Ending, DATETIME(1,1,1))");
	
	QueryTextOrder = 
		"
		|ORDER BY
		|	Order1,
		|	Order2";//@Query-part
	
	If CreateTT Then
		QueryTextTT = 
			"SELECT TOP 10000000
			|	*,
			|	RECORDAUTONUMBER() AS RecNo
			|INTO TTStages
			|FROM
			|	(&QueryTextSelection) AS NestedQuery
			|
			|&QueryTextOrder
			|
			|INDEX BY SETS (
			|	(ProductionOrder, RecNo),
			|	(ProductionOrder, KeyLot, Stage)
			|)
			|";//@Query-part
		
		QueryText = StrReplace(QueryTextTT,
			"&QueryTextSelection",
			QueryText);
		
		QueryText = StrReplace(QueryText,
			"&QueryTextOrder",
			QueryTextOrder);
	Else
		QueryText = QueryText + QueryTextOrder;
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextTypesOfRC(CreateTT, QueryTextFilter)
	
	QueryText = 
		"SELECT
		|	Lots.ProductionOrder               AS ProductionOrder,
		|	Lots.KeyLot                        AS KeyLot,
		|	Stages.Ref                             AS Stage,
		|	Stages.StageNumber                         AS StageNumber,
		|	Kinds.LineNumber                         AS LineNumber,
		|	Kinds.WorkCenterType                                     AS WorkCenterType,
		|	Kinds.WorkCenterType.UseAvailabilityAccordingToSchedule AS ConsiderAvailability,
		|	Kinds.WorkCenterType.ParallelLoad                AS ParallelLoad,
		|	CASE
		|		WHEN Kinds.WorkCenterType.ParallelLoad
		|				AND Kinds.WorkCenterType.MaximumLoad <> 0
		|			THEN Kinds.WorkCenterType.MaximumLoad
		|		WHEN Kinds.WorkCenterType.ParallelLoad
		|				AND Kinds.Load <> 0
		|			THEN Kinds.Load
		|		WHEN Kinds.WorkCenterType.ParallelLoad
		|			THEN 1
		|		ELSE 0
		|	END                                    AS MaximumLoad,
		|	Kinds.WorkCenterType.ParallelLoad
		|		AND Kinds.WorkCenterType.MaximumLoad = 0 AS ThereIsErrorDownloadIsNotFilledIn,
		|	CASE
		|		WHEN Kinds.WorkCenterType.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|			THEN Stages.Department
		|		ELSE Kinds.WorkCenterType.Calendar
		|	END                                    AS ChartKey,
		|	Stages.Department.PlanningInterval AS PlanningInterval,
		|
		|	CASE
		|		WHEN Kinds.WorkCenterType.ParallelLoad THEN
		|			
		|			BatchData.NumberOfLotReferencesNumerator * Kinds.Load * Kinds.OperationTime / BatchData.NumberOfLotReferencesDenominator
		|		
		|		WHEN Stages.QuantityOfProductUnitsLotsProducedSimultaneously <> 0
		|				AND Stages.Owner.ProductionIssueByCustomPortions THEN
		|			
		|			CASE
		|				WHEN INT(BatchData.QuantityOfUnits / Stages.QuantityOfProductUnitsLotsProducedSimultaneously)
		|					= BatchData.QuantityOfUnits / Stages.QuantityOfProductUnitsLotsProducedSimultaneously
		|					THEN BatchData.QuantityOfUnits / Stages.QuantityOfProductUnitsLotsProducedSimultaneously * Kinds.OperationTime
		|				ELSE (INT(BatchData.QuantityOfUnits / Stages.QuantityOfProductUnitsLotsProducedSimultaneously) + 1) * Kinds.OperationTime
		|			END
		|		
		|		WHEN Stages.QuantityOfProductUnitsLotsProducedSimultaneously <> 0
		|				AND NOT Stages.Owner.ProductionIssueByCustomPortions THEN
		|			
		|			CASE
		|				WHEN INT(ISNULL(BatchData.NumberOfLotReferencesNumerator / BatchData.NumberOfLotReferencesDenominator, 0) / Stages.QuantityOfProductUnitsLotsProducedSimultaneously)
		|						= ISNULL(BatchData.NumberOfLotReferencesNumerator / BatchData.NumberOfLotReferencesDenominator, 0) / Stages.QuantityOfProductUnitsLotsProducedSimultaneously
		|					THEN ISNULL(BatchData.NumberOfLotReferencesNumerator / BatchData.NumberOfLotReferencesDenominator, 0) / Stages.QuantityOfProductUnitsLotsProducedSimultaneously * Kinds.OperationTime
		|				ELSE (INT(ISNULL(BatchData.NumberOfLotReferencesNumerator / BatchData.NumberOfLotReferencesDenominator, 0) / Stages.QuantityOfProductUnitsLotsProducedSimultaneously) + 1) * Kinds.OperationTime
		|			END
		|			
		|		ELSE BatchData.NumberOfLotReferencesNumerator * Kinds.OperationTime / BatchData.NumberOfLotReferencesDenominator
		|	END * CASE Kinds.UnitOfMeasure
		|				WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|					THEN 60
		|				WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|					THEN 3600
		|				WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|					THEN 86400
		|				ELSE 1
		|			END                            AS LoadingTime,
		|	CASE
		|		WHEN STRINGLENGTH(TRIML(Kinds.QuantityCalculationAlgorithm)) <> 0 THEN
		|			CASE
		|				WHEN Kinds.WorkCenterType.ParallelLoad THEN
		|					Kinds.Load
		|				ELSE 1
		|			END * CASE Kinds.UnitOfMeasure
		|						WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|							THEN 60
		|						WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|							THEN 3600
		|						WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|							THEN 86400
		|						ELSE 1
		|					END
		|		ELSE 0
		|	END                                    AS CalculationCoefficientAccordingToFormula
		|INTO TTTypesOfRC
		|FROM
		|	TTParty AS Lots
		|	
		|	INNER JOIN Catalog.ProductionStages AS Stages
		|	ON Lots.Ref = Stages.Owner
		|		AND Lots.ItIsTransfer = FALSE
		|	
		|	INNER JOIN Catalog.ProductionStages.WorkCenterTypes AS Kinds
		|	ON Stages.Ref = Kinds.Ref
		|
		|	LEFT JOIN TTNumberOfLotReferences AS BatchData
		|	ON Lots.KeyLot = BatchData.KeyLot
		|
		|WHERE
		|	&QueryTextFilter
		|	AND NOT Stages.DeletionMark
		|
		|UNION ALL
		|
		|SELECT
		|	Lots.ProductionOrder               AS ProductionOrder,
		|	Lots.KeyLot                        AS KeyLot,
		|	Stages.Ref                             AS Stage,
		|	Stages.StageNumber                         AS StageNumber,
		|	Kinds1.LineNumber                        AS LineNumber,
		|	ISNULL(Kinds2.WorkCenterType, Kinds1.WorkCenterType)  AS WorkCenterType,
		|	CASE
		|		WHEN Kinds2.WorkCenterType IS NOT NULL
		|			THEN Kinds2.WorkCenterType.UseAvailabilityAccordingToSchedule
		|		ELSE Kinds1.WorkCenterType.UseAvailabilityAccordingToSchedule
		|	END AS ConsiderAvailability,
		|	CASE
		|		WHEN Kinds2.WorkCenterType IS NOT NULL
		|			THEN Kinds2.WorkCenterType.ParallelLoad
		|		ELSE Kinds1.WorkCenterType.ParallelLoad
		|	END AS ParallelLoad,
		|	CASE
		|		WHEN Kinds2.WorkCenterType IS NOT NULL
		|			THEN
		|				CASE
		|					WHEN Kinds2.WorkCenterType.ParallelLoad
		|							AND Kinds2.WorkCenterType.MaximumLoad <> 0
		|						THEN Kinds2.WorkCenterType.MaximumLoad
		|					WHEN Kinds2.WorkCenterType.ParallelLoad
		|							AND Kinds2.LoadStandard <> 0
		|						THEN Kinds2.LoadStandard
		|					WHEN Kinds2.WorkCenterType.ParallelLoad
		|						THEN 1
		|					ELSE 0
		|				END
		|		ELSE
		|			CASE
		|				WHEN Kinds1.WorkCenterType.ParallelLoad
		|						AND Kinds1.WorkCenterType.MaximumLoad <> 0
		|					THEN Kinds1.WorkCenterType.MaximumLoad
		|				WHEN Kinds1.WorkCenterType.ParallelLoad
		|						AND Kinds1.LoadStandard <> 0
		|					THEN Kinds1.LoadStandard
		|				WHEN Kinds1.WorkCenterType.ParallelLoad
		|					THEN 1
		|				ELSE 0
		|			END
		|	END AS MaximumLoad,
		|	CASE
		|		WHEN Kinds2.WorkCenterType IS NOT NULL
		|			THEN Kinds2.WorkCenterType.ParallelLoad
		|					AND Kinds2.WorkCenterType.MaximumLoad = 0
		|		ELSE Kinds1.WorkCenterType.ParallelLoad
		|				AND Kinds1.WorkCenterType.MaximumLoad = 0
		|	END AS ThereIsErrorDownloadIsNotFilledIn,
		|	CASE
		|		WHEN Kinds2.WorkCenterType IS NOT NULL
		|			THEN
		|				CASE
		|					WHEN Kinds2.WorkCenterType.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|						THEN Stages.Department
		|					ELSE Kinds2.WorkCenterType.Calendar
		|				END
		|		ELSE
		|			CASE
		|				WHEN Kinds1.WorkCenterType.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|					THEN Stages.Department
		|				ELSE Kinds1.WorkCenterType.Calendar
		|			END
		|	END                                    AS ChartKey,
		|	Stages.Department.PlanningInterval AS PlanningInterval,
		|	CASE
		|		WHEN Kinds2.WorkCenterType IS NOT NULL
		|			THEN
		|				CASE
		|					WHEN Kinds2.WorkCenterType.ParallelLoad
		|						THEN Kinds2.Load * Kinds2.OperationTimeStandard
		|					ELSE Kinds2.OperationTime
		|				END * CASE Kinds2.UnitOfMeasure
		|							WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|							THEN 60
		|						WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|							THEN 3600
		|						WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|							THEN 86400
		|						ELSE 1
		|					END
		|		ELSE
		|			CASE
		|				WHEN Kinds1.WorkCenterType.ParallelLoad
		|					THEN Kinds1.Load * Kinds1.OperationTimeStandard
		|				ELSE Kinds1.OperationTime
		|			END * CASE Kinds1.UnitOfMeasure
		|						WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|						THEN 60
		|					WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|						THEN 3600
		|					WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|						THEN 86400
		|					ELSE 1
		|				END
		|	END                                    AS LoadingTime,
		|	0                                        AS CalculationCoefficientAccordingToFormula
		|FROM
		|	TTParty AS Lots
		|	
		|	INNER JOIN Document.ProductionStage2_2 AS Stages
		|	ON Lots.Ref = Stages.ProductionLot
		|		AND Lots.ItIsTransfer = FALSE
		|
		|	INNER JOIN Document.ProductionStage2_2.WorkCenterTypes AS Kinds1
		|	ON Stages.Ref = Kinds1.Ref
		|
		|	LEFT JOIN Document.ProductionStage2_2.AlternateWorkCenterTypes AS Kinds2
		|	ON Stages.Ref = Kinds2.Ref
		|		AND Kinds1.ConnectionKey = Kinds2.LinkKeyWorkCenterTypes
		|		AND NOT Kinds1.Use
		|		AND Kinds2.Use
		|
		|WHERE
		|	&QueryTextFilter
		|	AND Stages.Posted
		|	AND NOT Stages.Status IN (
		|		VALUE(Enum.StatusesOfProductionStages2_2.Initiated),
		|		VALUE(Enum.StatusesOfProductionStages2_2.Completed))
		|	AND (&CancelManualChangesOfSchedule OR NOT Stages.StagePlacementInProductionSchedule)";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextFilter",
		StrReplace(QueryTextFilter, "&TextTableName", "Lots"));
	
	If Not CreateTT Then
		QueryText = StrReplace(QueryText, "INTO TTTypesOfRC", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextProductsForCalculationOfTypesOfRCAccordingToFormula()
	
	QueryText = 
		"SELECT
		|	Lots.KeyLot                 AS KeyLot,
		|	Lots.Ref                     AS BillOfMaterials,
		|	BatchData.Products         AS Products,
		|	BatchData.Characteristic       AS Characteristic,
		|	BatchData.QuantityOfUnits     AS Count,
		|	Lots.ProductionOrder        AS ReferenceOrder,
		|	OrderDocument.Department               AS ProductionDispatcherBusinessUnit,
		|	OrderDocument.LineOfBusiness     AS LineOfBusiness,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS AssigneeBusinessUnit,
		|	DATETIME(1,1,1)                  AS ProductionStart,
		|	0                                 AS DaysFromDemand
		|FROM
		|	TTParty AS Lots
		|	
		|	INNER JOIN TTNumberOfLotReferences AS BatchData
		|	ON Lots.KeyLot = BatchData.KeyLot
		|	
		|	INNER JOIN Document.ProductionOrder2_2 AS OrderDocument
		|	ON Lots.ProductionOrder = OrderDocument.Ref
		|WHERE
		|	Lots.Ref REFS Catalog.BillsOfMaterials
		|	AND NOT Lots.ItIsTransfer
		|	AND TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			Catalog.ProductionStages AS Stages
		|			
		|			INNER JOIN Catalog.ProductionStages.WorkCenterTypes AS Kinds
		|			ON Stages.Ref = Kinds.Ref
		|		WHERE
		|			Stages.Owner = Lots.Ref
		|			AND NOT Stages.DeletionMark
		|			AND STRINGLENGTH(TRIML(Kinds.QuantityCalculationAlgorithm)) <> 0)";
	
	Return QueryText;
	
EndFunction

Function QueryTextOrderData(QueryTextFilter, ArrangeResult)
	
	QueryText =
		"SELECT
		|	Orders.Ref          AS ProductionOrder,
		|	Orders.Number           AS Number,
		|	Orders.ProductionProcessType
		|		= VALUE(Enum.ProductionProcessTypes.Assembly)                   AS ThisIsBuild,
		|	Orders.ProductionProcessType
		|		= VALUE(Enum.ProductionProcessTypes.PerformRM) AS ThisIsRepair,
		|	Orders.UseAvailabilityReserve                                               AS UseAvailabilityReserve,
		|	Orders.EarliestStartDate   AS EarliestStartDate,
		|	Orders.DemandDate AS DemandDate,
		|	CASE
		|		WHEN Orders.DemandDate = DATETIME(1,1,1)
		|			THEN 0
		|		ELSE DATEDIFF(Orders.EarliestStartDate, Orders.DemandDate, MONTH)
		|	END                 AS DateDifferenceInMonths
		|FROM
		|	Document.ProductionOrder2_2 AS Orders
		|WHERE
		|	&QueryTextFilter";
	
	If ArrangeResult Then
		QueryTextOrder = "
			|ORDER BY
			|	Orders.Priority.AddlOrderingAttribute,
			|	Orders.Department.AddlOrderingAttribute,
			|	Orders.Queue";//@Query-part
		QueryText = QueryText + QueryTextOrder;
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"&QueryTextFilter",
		StrReplace(QueryTextFilter, "&TextTableName", "Orders"));
	
	Return QueryText;
	
EndFunction

Procedure CalculateTimeOfRCTypesUsingFormulas(TypesOfRC, ProductsForCalculationOfTypesOfRCAccordingToFormula)
	
	If ProductsForCalculationOfTypesOfRCAccordingToFormula.Count() = 0 Then
		Return;
	EndIf;
	
	TypesOfRC.Indexes.Add("KeyLot, Stage, WorkCenterType");
	TheStructureOfTheSearch = New Structure("KeyLot, Stage, WorkCenterType");
	
	SpecificationsData = Catalogs.BillsOfMaterials.SpecificationDataByProductsList(
		ProductsForCalculationOfTypesOfRCAccordingToFormula,
		Catalogs.BillsOfMaterials.DataSamplingParameters("WorkCenterTypes"),
		True,
		"KeyLot");
	
	For Each SpecificationData In SpecificationsData Do
		TheStructureOfTheSearch.KeyLot = SpecificationData.KeyLot;
		For Each String In SpecificationData.WorkCenterTypes Do
			If IsBlankString(String.QuantityCalculationAlgorithm) Then
				Continue;
			EndIf;
			FillPropertyValues(TheStructureOfTheSearch, String, "Stage, WorkCenterType");
			FoundRows = TypesOfRC.FindRows(TheStructureOfTheSearch);
			If FoundRows.Count() <> 0 Then
				FoundRows[0].LoadingTime = String.OperationTime * FoundRows[0].CalculationCoefficientAccordingToFormula;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// Calculate the order of R&M.
// 
// Parameters:
//  PaymentData - Structure:
//   * Stages - ValueTable
//   * Links - ValueTable
//  LotReferenceOfRAndMToCalculationOfOrder - ValueTable
//
Procedure CalculateRAndMRepairProcedure(PaymentData, LotReferenceOfRAndMToCalculationOfOrder)
	
	LinksCopy = PaymentData.Links.Copy();
	LinksCopy.Indexes.Add("KeyLot, Stage");
	LinksCopy.Indexes.Add("KeyLot, Stage, KeyIsPredecessorParty");
	
	PaymentData.Stages.Indexes.Add("KeyLot, ThisIsInitialStageOfRepair");
	LotReferenceOfRAndMToCalculationOfOrder.Indexes.Add("KeyIsPredecessorParty");
	
	SearchStage = New Structure("KeyLot, Stage");
	SearchInternalCommunication = New Structure("KeyLot, Stage, KeyIsPredecessorParty");
	SearchLotReferencePredecessor = New Structure("KeyIsPredecessorParty");
	SearchIsInitialStage = New Structure("KeyLot, ThisIsInitialStageOfRepair", Undefined, True);
	
	// Attribute inheritance is the resource intensity of nested R&M up the tree
	For IndexOf = 0 To LotReferenceOfRAndMToCalculationOfOrder.Count()-1 Do
		
		StringBatch = LotReferenceOfRAndMToCalculationOfOrder[IndexOf];
		FillPropertyValues(SearchStage, StringBatch);
		FoundRows = PaymentData.Stages.FindRows(SearchStage);
		If FoundRows.Count() = 0
			Or FoundRows[0].ResourceIntensity >= StringBatch.ResourceIntensity Then
			Continue;
		EndIf;
		
		StageString = FoundRows[0];
		ResourceIntensityOfStageBeforeChange = StageString.ResourceIntensity;
		StageString.ResourceIntensity = StringBatch.ResourceIntensity;
		
		SearchLotReferencePredecessor.KeyIsPredecessorParty = StageString.KeyLot;
		FoundRows = LotReferenceOfRAndMToCalculationOfOrder.FindRows(SearchLotReferencePredecessor);
		For Each StringLotReferenceFollower In FoundRows Do
			StringLotReferenceFollower.ResourceIntensity = StringLotReferenceFollower.ResourceIntensity
				- ResourceIntensityOfStageBeforeChange
				+ StageString.ResourceIntensity;
		EndDo;
		
	EndDo;
	
	// Bypassing the stages from right to left
	For IndexOf = 0 To PaymentData.Stages.Count()-1 Do
		StageString = PaymentData.Stages[IndexOf];
		Order = StageString.Order + StageString.ResourceIntensity;
		
		FillPropertyValues(SearchStage, StageString);
		
		For Each LinkString In LinksCopy.FindRows(SearchStage) Do
			SearchStage.KeyLot = LinkString.KeyIsPredecessorParty;
			SearchStage.Stage = LinkString.PredecessorStage;
			
			// Calculation of the order of stages
			For Each StringStagePredecessor In PaymentData.Stages.FindRows(SearchStage) Do
				If StageString.ThisIsWorkPlanning
					And StageString.KeyLot <> StringStagePredecessor.KeyLot Then
					StringStagePredecessor.Order = StageString.Order;
				ElsIf StringStagePredecessor.Order < Order Then
					StringStagePredecessor.Order = Order;
				EndIf;
			EndDo;
			
			If StageString.ThisIsWorkPlanning
				And StageString.KeyLot <> LinkString.KeyIsPredecessorParty Then
				SearchIsInitialStage.KeyLot = LinkString.KeyIsPredecessorParty;
				
				For Each LineIsInitialStage In PaymentData.Stages.FindRows(SearchIsInitialStage) Do
					// Filling should be planned no earlier
					If StageString.ThisIsInitialStageOfRepair
						And ValueIsFilled(StageString.PlanNotEarlierThanStage) Then
						LineIsInitialStage.PlanNotEarlierThanStage = StageString.PlanNotEarlierThanStage;
						LineIsInitialStage.PlanNotEarlierThanKeyLot = StageString.PlanNotEarlierThanKeyLot;
					Else
						LineIsInitialStage.PlanNotEarlierThanStage = StageString.Stage;
						LineIsInitialStage.PlanNotEarlierThanKeyLot = StageString.KeyLot;
					EndIf;
					
					// Adjusting the start of placement
					If StageString.PlanNotEarlierThan > LineIsInitialStage.StartOfPlacement Then
						LineIsInitialStage.StartOfPlacement = StageString.PlanNotEarlierThan;
					EndIf;
					
					// Adding links
					SearchInternalCommunication.KeyLot = LineIsInitialStage.PlanNotEarlierThanKeyLot;
					SearchInternalCommunication.KeyIsPredecessorParty = LineIsInitialStage.PlanNotEarlierThanKeyLot;
					SearchInternalCommunication.Stage = LineIsInitialStage.PlanNotEarlierThanStage;
					
					For Each LineInternalCommunication In LinksCopy.FindRows(SearchInternalCommunication) Do
						NewRow = PaymentData.Links.Add();
						NewRow.KeyLot = LineIsInitialStage.KeyLot;
						NewRow.Stage = LineIsInitialStage.Stage;
						NewRow.KeyIsPredecessorParty = LineInternalCommunication.KeyIsPredecessorParty;
						NewRow.PredecessorStage = LineInternalCommunication.PredecessorStage;
					EndDo;
				EndDo;
			EndIf;
		EndDo;
		
		If ValueIsFilled(StageString.PlanNotEarlierThanStage) Then
			SearchStage.KeyLot = StageString.PlanNotEarlierThanKeyLot;
			SearchStage.Stage = StageString.PlanNotEarlierThanStage;
			
			FoundRows = PaymentData.Stages.FindRows(SearchStage);
			If FoundRows.Count() <> 0 Then
				LineWorkPlanningStage = FoundRows[0];
				LineWorkPlanningStage.Order = 
					Max(LineWorkPlanningStage.Order, StageString.Order + 0.0001);
			EndIf;
		EndIf;
	EndDo;
	
	PaymentData.Stages.Sort("Order Desc, StageNumber");
	
EndProcedure

#EndRegion

#Region ReadingAvailability

Procedure ReadAvailability(OrderDocument, PaymentData, CalculationParameters, Boundary = Undefined)
	
	If CalculationParameters.AvailabilitySelectionBoundary = '00010101' Then
		If ValueIsFilled(CalculationParameters.AvailabilityIntervalStart)
			And ValueIsFilled(CalculationParameters.AvailabilityIntervalEnding) Then
			Begin = CalculationParameters.AvailabilityIntervalStart;
			Ending = CalculationParameters.AvailabilityIntervalEnding;
		Else
			Interval = AvailabilitySamplingInterval(PaymentData); // Structure
			Begin = Interval.Begin;
			Ending = Interval.Ending;
		EndIf;
		ThisIsAdditionalReading = False;
	Else
		Begin = CalculationParameters.AvailabilitySelectionBoundary + 1;
		Ending = ?(Boundary <> Undefined And Boundary > Begin,
			Boundary,
			EndOfMonth(AddMonth(Begin, 2)));
		ThisIsAdditionalReading = True;
	EndIf;
	CalculationParameters.AvailabilitySelectionBoundary = Ending;
	
	Query = New Query;
	Query.SetParameter("OrderDocument", OrderDocument);
	Query.SetParameter("Begin", Begin);
	Query.SetParameter("Ending", Ending);
	Query.SetParameter("EndBeginningOfDay", BegOfDay(Ending));
	Query.SetParameter("UseAvailabilityReserve", CalculationParameters.UseAvailabilityReserve);
	Query.SetParameter("CancelManualChangesOfSchedule", CalculationParameters.CancelManualChangesOfSchedule);
	Query.SetParameter("UnlimitedEquipmentFleet", CalculationParameters.UnlimitedEquipmentFleet);
	
	If ThisIsAdditionalReading Then
		Query.SetParameter("DivisionScheduleDay", PaymentData.DivisionScheduleDay);
		Query.SetParameter("SecundaDivisionSchedule", PaymentData.SecundaDivisionSchedule);
		Query.SetParameter("WCKAvailability", PaymentData.WCKAvailability);
	EndIf;
	
	If CalculationParameters.AvailabilityUnitSelection.Count() <> 0 Then
		Query.SetParameter("Departments", CalculationParameters.AvailabilityUnitSelection);
	EndIf;
	
	If CalculationParameters.AvailabilityVRCSelection.Count() <> 0 Then
		Query.SetParameter("TypesOfRC", CalculationParameters.AvailabilityVRCSelection);
	EndIf;
	
	TempTablesManager = New TempTablesManager();
	Query.TempTablesManager = TempTablesManager;
	
	#Region Schedules
	
	QueryText =
		"SELECT
		|	Calendars.Ref AS Ref
		|FROM
		|	Catalog.Calendars AS Calendars
		|WHERE
		|	TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			Catalog.BusinessStructure.WorkSchedules AS Schedules
		|		WHERE
		|			Schedules.WorkScheduleCalendar = Calendars.Ref
		|			AND &QueryTextFilterDepartments)
		|	OR TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			Catalog.WorkCenterTypes AS WorkCenterTypes
		|		WHERE
		|			WorkCenterTypes.Calendar = Calendars.Ref
		|			AND &QueryTextFilterTypesOfRC)
		|	OR TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		WHERE
		|			MainEnterpriseCalendar.Value = Calendars.Ref)";
	
	If CalculationParameters.AvailabilityUnitSelection.Count() = 0 Then
		QueryText = StrReplace(QueryText,
			"&QueryTextFilterDepartments",
			"TRUE");
	Else
		QueryText = StrReplace(QueryText,
			"&QueryTextFilterDepartments",
			"Schedules.Ref IN (&Departments)");
	EndIf;
	
	If CalculationParameters.AvailabilityVRCSelection.Count() = 0 Then
		QueryText = StrReplace(QueryText,
			"&QueryTextFilterTypesOfRC",
			"TRUE");
	Else
		QueryText = StrReplace(QueryText,
			"&QueryTextFilterTypesOfRC",
			"WorkCenterTypes.Ref IN (&TypesOfRC)");
	EndIf;
	
	Query.Text = QueryText;
	Schedules = Query.Execute().Unload().UnloadColumn("Ref");
	
	#EndRegion
	
	CalendarSchedules.CreateTTWorkSchedulesForPeriod(
		TempTablesManager, Schedules, Begin, Ending, False);
	
	RequestSeparatorInPacket_ = Common.QueryBatchSeparator();
	QueryTexts = New ValueList;
	
	If ThisIsAdditionalReading Then
		
		#Region TTScheduleOfDivisionsOfDayIsCurrent
		
		QueryText = 
			"SELECT
			|	DivisionScheduleDay.Department AS Department,
			|	DivisionScheduleDay.Date          AS Date,
			|	DivisionScheduleDay.Begin        AS Begin,
			|	DivisionScheduleDay.Ending     AS Ending,
			|	DivisionScheduleDay.ThisIsIndex     AS ThisIsIndex
			|INTO TTScheduleOfDivisionsOfDayIsCurrent
			|FROM
			|	&DivisionScheduleDay AS DivisionScheduleDay
			|
			|INDEX BY
			|	Department,
			|	Begin";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTScheduleOfDivisionsOfDayIsCurrent");
		
		#EndRegion
		
		#Region TTDivisionScheduleSecundaCurrent
		
		QueryText = 
			"SELECT
			|	SecundaDivisionSchedule.Department AS Department,
			|	SecundaDivisionSchedule.Date          AS Date,
			|	SecundaDivisionSchedule.Begin        AS Begin,
			|	SecundaDivisionSchedule.Ending     AS Ending,
			|	SecundaDivisionSchedule.Duration  AS Duration,
			|	SecundaDivisionSchedule.ThisIsIndex     AS ThisIsIndex
			|INTO TTDivisionScheduleSecundaCurrent
			|FROM
			|	&SecundaDivisionSchedule AS SecundaDivisionSchedule
			|
			|INDEX BY
			|	Department,
			|	Begin";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTDivisionScheduleSecundaCurrent");
		
		#EndRegion
		
		#Region TTAvailabilityOfVRCIsCurrent
		
		QueryText = 
			"SELECT
			|	WCKAvailability.WorkCenterType     AS WorkCenterType,
			|	WCKAvailability.IntervalDate         AS IntervalDate,
			|	WCKAvailability.StartOfRange       AS StartOfRange,
			|	WCKAvailability.EndOfTheInterval    AS EndOfTheInterval,
			|	WCKAvailability.Shift                 AS Shift,
			|	WCKAvailability.AvailableLoadingTime AS AvailableLoadingTime,
			|	WCKAvailability.Available_Time         AS Available_Time,
			|	WCKAvailability.MaximumLoadingTime AS MaximumLoadingTime,
			|	WCKAvailability.ThisIsIndex             AS ThisIsIndex
			|INTO TTAvailabilityOfVRCIsCurrent
			|FROM
			|	&WCKAvailability AS WCKAvailability
			|
			|INDEX BY
			|	WorkCenterType,
			|	IntervalDate,
			|	ThisIsIndex";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTAvailabilityOfVRCIsCurrent");
		
		#EndRegion
		
	Else
		
		#Region TTScheduleOfDivisionsOfDayIsCurrent
		
		QueryText = 
			"SELECT TOP 0
			|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
			|	DATETIME(1, 1, 1)                                     AS Date,
			|	DATETIME(1, 1, 1)                                     AS Begin,
			|	DATETIME(1, 1, 1)                                     AS Ending,
			|	FALSE                                                   AS ThisIsIndex
			|INTO TTScheduleOfDivisionsOfDayIsCurrent";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTScheduleOfDivisionsOfDayIsCurrent");
		
		#EndRegion
		
		#Region TTDivisionScheduleSecundaCurrent
		
		QueryText = 
			"SELECT TOP 0
			|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
			|	DATETIME(1, 1, 1)                                     AS Date,
			|	DATETIME(1, 1, 1)                                     AS Begin,
			|	DATETIME(1, 1, 1)                                     AS Ending,
			|	0                                                      AS Duration,
			|	FALSE                                                   AS ThisIsIndex
			|INTO TTDivisionScheduleSecundaCurrent";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTDivisionScheduleSecundaCurrent");
		
		#EndRegion
		
		#Region TTAvailabilityOfVRCIsCurrent
		
		QueryText = 
			"SELECT TOP 0
			|	VALUE(Catalog.WorkCenterTypes.EmptyRef) AS WorkCenterType,
			|	DATETIME(1, 1, 1)                                   AS IntervalDate,
			|	DATETIME(1, 1, 1)                                   AS StartOfRange,
			|	DATETIME(1, 1, 1)                                   AS EndOfTheInterval,
			|	VALUE(Catalog.Calendars.EmptyRef)          AS Shift,
			|	0                                                    AS AvailableLoadingTime,
			|	0                                                    AS Available_Time,
			|	0                                                    AS MaximumLoadingTime,
			|	FALSE                                                 AS ThisIsIndex
			|INTO TTAvailabilityOfVRCIsCurrent";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTAvailabilityOfVRCIsCurrent");
		
		#EndRegion
		
	EndIf;
	
	#Region TTDayCounter
	
	QueryText = 
		"SELECT 0 AS Step
		|INTO TTDayCounter
		|UNION ALL
		|SELECT 1
		|UNION ALL
		|SELECT 2
		|UNION ALL
		|SELECT 3
		|UNION ALL
		|SELECT 4
		|UNION ALL
		|SELECT 5
		|UNION ALL
		|SELECT 6
		|UNION ALL
		|SELECT 7
		|UNION ALL
		|SELECT 8
		|UNION ALL
		|SELECT 9";
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTDayCounter");
	
	#EndRegion
	
	#Region TTClockCounter
	
	QueryText = 
		"SELECT 0 AS HourNumber
		|INTO TTClockCounter
		|UNION ALL
		|SELECT 1
		|UNION ALL
		|SELECT 2
		|UNION ALL
		|SELECT 3
		|UNION ALL
		|SELECT 4
		|UNION ALL
		|SELECT 5
		|UNION ALL
		|SELECT 6
		|UNION ALL
		|SELECT 7
		|UNION ALL
		|SELECT 8
		|UNION ALL
		|SELECT 9
		|UNION ALL
		|SELECT 10
		|UNION ALL
		|SELECT 11
		|UNION ALL
		|SELECT 12
		|UNION ALL
		|SELECT 13
		|UNION ALL
		|SELECT 14
		|UNION ALL
		|SELECT 15
		|UNION ALL
		|SELECT 16
		|UNION ALL
		|SELECT 17
		|UNION ALL
		|SELECT 18
		|UNION ALL
		|SELECT 19
		|UNION ALL
		|SELECT 20
		|UNION ALL
		|SELECT 21
		|UNION ALL
		|SELECT 22
		|UNION ALL
		|SELECT 23";
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTClockCounter");
	
	#EndRegion
	
	#Region TTDayNumbers
	
	QueryText = 
		"SELECT
		|	Counter1.Step * 1000 + Counter2.Step * 100 + Counter3.Step * 10 + Counter4.Step AS Number
		|INTO TTDayNumbers
		|FROM
		|	TTDayCounter AS Counter1,
		|	TTDayCounter AS Counter2,
		|	TTDayCounter AS Counter3,
		|	TTDayCounter AS Counter4
		|WHERE
		|	(Counter1.Step * 1000 + Counter2.Step * 100 + Counter3.Step * 10 + Counter4.Step) <= DATEDIFF(&Begin, &EndBeginningOfDay, DAY)";
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTDayNumbers");
	
	#EndRegion
	
	#Region TTDaysForPeriod
	
	QueryText = 
		"SELECT
		|	DATEADD(&Begin, DAY, DayNumbers.Number) AS Date
		|INTO TTDaysForPeriod
		|FROM
		|	TTDayNumbers AS DayNumbers
		|
		|INDEX BY
		|	Date";
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTDaysForPeriod");
	
	#EndRegion
	
	#Region TTPriorityOrders
	
	If CalculationParameters.NoOtherOrders Then
		
		QueryText = 
			"SELECT
			|	VALUE(Document.ProductionOrder2_2.EmptyRef) AS Ref
			|INTO TTPriorityOrders";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTPriorityOrders");
		
	Else
		
		Documents.ProductionOrder2_2.CreateTTOrdersWithHighPriority(
			TempTablesManager, "TTPriorityOrders", OrderDocument);
		
	EndIf;
	
	#EndRegion
	
	#Region TTUnits
	
	QueryText = 
		"SELECT
		|	BusinessStructure.Ref AS Ref
		|INTO TTUnits
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|WHERE
		|	NOT BusinessStructure.DeletionMark
		|	AND BusinessStructure.ProductionBusinessUnit
		|	AND &QueryTextFilterDepartments
		|
		|UNION ALL
		|
		|// Value for calculating movements
		|SELECT
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Ref
		|
		|INDEX BY
		|	Ref";
	
	If CalculationParameters.AvailabilityUnitSelection.Count() = 0 Then
		QueryText = StrReplace(QueryText,
			"&QueryTextFilterDepartments",
			"TRUE");
	Else
		QueryText = StrReplace(QueryText,
			"&QueryTextFilterDepartments",
			"BusinessStructure.Ref IN (&Departments)");
	EndIf;
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTUnits");
	
	#EndRegion
	
	#Region TTDivisionSchedules
	
	If Not CalculationParameters.RoundTheClockWorkSevenDaysAWeek Then
		QueryText = 
			"SELECT
			|	Departments.Ref                                                  AS Department,
			|	ISNULL(Schedules.WorkScheduleCalendar, MainEnterpriseCalendar.Value) AS WorkScheduleCalendar
			|INTO TTDivisionSchedules
			|FROM
			|	TTUnits AS Departments
			|
			|	LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS Schedules
			|	ON Departments.Ref = Schedules.Ref
			|
			|	LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
			|	ON (TRUE)
			|
			|INDEX BY
			|	WorkScheduleCalendar";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTDivisionSchedules");
	EndIf;
	
	#EndRegion
	
	#Region DivisionScheduleDay
	
	If CalculationParameters.RoundTheClockWorkSevenDaysAWeek Then
		QueryText = 
			"SELECT
			|	Departments.Ref                     AS Department,
			|	DaysPerPeriod.Date                         AS Date,
			|	DaysPerPeriod.Date                         AS Begin,
			|	DATEADD(DaysPerPeriod.Date, DAY, 1) AS Ending,
			|	FALSE                                     AS ThisIsIndex
			|FROM
			|	TTUnits AS Departments
			|	
			|	INNER JOIN TTDaysForPeriod AS DaysPerPeriod
			|	ON TRUE
			|
			|UNION ALL
			|
			|SELECT
			|	DivisionScheduleDay.Department AS Department,
			|	DivisionScheduleDay.Date          AS Date,
			|	DivisionScheduleDay.Begin        AS Begin,
			|	DivisionScheduleDay.Ending     AS Ending,
			|	DivisionScheduleDay.ThisIsIndex     AS ThisIsIndex
			|FROM
			|	TTScheduleOfDivisionsOfDayIsCurrent AS DivisionScheduleDay
			|
			|ORDER BY
			|	Department,
			|	Begin";
	Else
		QueryText = 
			"SELECT
			|	Schedules.Department                  AS Department,
			|	DaysPerPeriod.Date                       AS Date,
			|	MIN(CASE
			|		WHEN WorkSchedules1.Period IS NULL
			|			THEN DaysPerPeriod.Date
			|		WHEN ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
			|			THEN WorkSchedules1.ScheduleDate
			|		ELSE DATEADD(WorkSchedules1.ScheduleDate, MINUTE,
			|				HOUR(WorkSchedules1.BeginTime) * 60 + MINUTE(WorkSchedules1.BeginTime))
			|	END)                                 AS Begin,
			|	MAX(CASE
			|		WHEN WorkSchedules1.Period IS NULL
			|			THEN DaysPerPeriod.Date
			|		WHEN ISNULL(WorkSchedules1.EndTime, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
			|			THEN DATEADD(WorkSchedules1.ScheduleDate, DAY, 1)
			|		ELSE DATEADD(WorkSchedules1.ScheduleDate, MINUTE,
			|				HOUR(WorkSchedules1.EndTime) * 60
			|					+ MINUTE(WorkSchedules1.EndTime))
			|	END)                                 AS Ending,
			|	WorkSchedules1.Period IS NULL      AS ThisIsIndex
			|FROM
			|	TTDivisionSchedules AS Schedules
			|	
			|	INNER JOIN TTDaysForPeriod AS DaysPerPeriod
			|	ON TRUE
			|	
			|	LEFT JOIN TTWorkSchedules AS WorkSchedules1
			|	ON Schedules.WorkScheduleCalendar = WorkSchedules1.WorkScheduleCalendar
			|		AND DaysPerPeriod.Date = WorkSchedules1.Period
			|
			|GROUP BY
			|	Schedules.Department,
			|	DaysPerPeriod.Date,
			|	WorkSchedules1.Period IS NULL
			|
			|UNION ALL
			|
			|SELECT
			|	DivisionScheduleDay.Department AS Department,
			|	DivisionScheduleDay.Date          AS Date,
			|	DivisionScheduleDay.Begin        AS Begin,
			|	DivisionScheduleDay.Ending     AS Ending,
			|	DivisionScheduleDay.ThisIsIndex     AS ThisIsIndex
			|FROM
			|	TTScheduleOfDivisionsOfDayIsCurrent AS DivisionScheduleDay
			|
			|ORDER BY
			|	Department,
			|	Begin";
	EndIf;
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "DivisionScheduleDay");
	
	#EndRegion
	
	#Region SecundaDivisionSchedule
	
	If CalculationParameters.RoundTheClockWorkSevenDaysAWeek Then
		QueryText = 
			"SELECT
			|	Departments.Ref                     AS Department,
			|	DaysPerPeriod.Date                         AS Date,
			|	DaysPerPeriod.Date                         AS Begin,
			|	DATEADD(DaysPerPeriod.Date, DAY, 1) AS Ending,
			|	86400                                    AS Duration,
			|	FALSE                                     AS ThisIsIndex
			|FROM
			|	TTUnits AS Departments
			|	
			|	INNER JOIN TTDaysForPeriod AS DaysPerPeriod
			|	ON TRUE
			|
			|UNION ALL
			|
			|SELECT
			|	SecundaDivisionSchedule.Department AS Department,
			|	SecundaDivisionSchedule.Date          AS Date,
			|	SecundaDivisionSchedule.Begin        AS Begin,
			|	SecundaDivisionSchedule.Ending     AS Ending,
			|	SecundaDivisionSchedule.Duration  AS Duration,
			|	SecundaDivisionSchedule.ThisIsIndex     AS ThisIsIndex
			|FROM
			|	TTDivisionScheduleSecundaCurrent AS SecundaDivisionSchedule
			|
			|ORDER BY
			|	Department,
			|	Begin";
	Else
		QueryText = 
			"SELECT
			|	Schedules.Department                  AS Department,
			|	DaysPerPeriod.Date                       AS Date,
			|	CASE
			|		WHEN ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
			|			THEN DaysPerPeriod.Date
			|		ELSE DATEADD(DaysPerPeriod.Date, MINUTE,
			|				HOUR(WorkSchedules1.BeginTime) * 60 + MINUTE(WorkSchedules1.BeginTime))
			|	END                                  AS Begin,
			|	CASE
			|		WHEN ISNULL(WorkSchedules1.EndTime, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
			|			THEN DATEADD(DaysPerPeriod.Date, DAY, 1)
			|		ELSE DATEADD(DaysPerPeriod.Date, MINUTE,
			|				HOUR(WorkSchedules1.EndTime) * 60
			|					+ MINUTE(WorkSchedules1.EndTime))
			|	END                                  AS Ending,
			|	CASE
			|		WHEN WorkSchedules1.ScheduleDate IS NULL
			|			THEN 0
			|		WHEN ISNULL(WorkSchedules1.EndTime, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
			|			AND ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1)
			|			THEN 86400 - DATEDIFF(DATETIME(1, 1, 1), WorkSchedules1.BeginTime, SECOND)
			|		WHEN ISNULL(WorkSchedules1.EndTime, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
			|			THEN 86400
			|		ELSE DATEDIFF(ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1)), WorkSchedules1.EndTime, SECOND)
			|	END                                  AS Duration,
			|	WorkSchedules1.ScheduleDate IS NULL AS ThisIsIndex
			|FROM
			|	TTDivisionSchedules AS Schedules
			|	
			|	INNER JOIN TTDaysForPeriod AS DaysPerPeriod
			|	ON TRUE
			|	
			|	LEFT JOIN TTWorkSchedules AS WorkSchedules1
			|	ON Schedules.WorkScheduleCalendar = WorkSchedules1.WorkScheduleCalendar
			|		AND DaysPerPeriod.Date = WorkSchedules1.ScheduleDate
			|
			|UNION ALL
			|
			|SELECT
			|	SecundaDivisionSchedule.Department AS Department,
			|	SecundaDivisionSchedule.Date          AS Date,
			|	SecundaDivisionSchedule.Begin        AS Begin,
			|	SecundaDivisionSchedule.Ending     AS Ending,
			|	SecundaDivisionSchedule.Duration  AS Duration,
			|	SecundaDivisionSchedule.ThisIsIndex     AS ThisIsIndex
			|FROM
			|	TTDivisionScheduleSecundaCurrent AS SecundaDivisionSchedule
			|
			|ORDER BY
			|	Department,
			|	Begin";
	EndIf;
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "SecundaDivisionSchedule");
	
	#EndRegion
	
	#Region TTNumberOfRC
	
	QueryText = 
		"SELECT
		|	WorkCenters.WorkCenterType  AS WorkCenterType,
		|	COUNT(WorkCenters.Ref) AS NumberOfWorkCenters
		|INTO TTNumberOfRC
		|FROM
		|	Catalog.WorkCenters AS WorkCenters
		|WHERE
		|	NOT WorkCenters.DeletionMark
		|	AND NOT WorkCenters.WorkCenterType.EnterAvailabilityForWorkCenterType
		|	AND &QueryTextFilterTypesOfRC
		|
		|GROUP BY
		|	WorkCenters.WorkCenterType
		|
		|INDEX BY
		|	WorkCenterType";
	
	If CalculationParameters.AvailabilityVRCSelection.Count() = 0 Then
		QueryText = StrReplace(QueryText,
			"&QueryTextFilterTypesOfRC",
			"TRUE");
	Else
		QueryText = StrReplace(QueryText,
			"&QueryTextFilterTypesOfRC",
			"WorkCenters.WorkCenterType IN (&TypesOfRC)");
	EndIf;
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTNumberOfRC");
	
	#EndRegion
	
	#Region TTCatalogTypesOfRC
	
	QueryText = 
		"SELECT
		|	TypesOfRC.Ref                                       AS WorkCenterType,
		|	TypesOfRC.Department                                AS Department,
		|	TypesOfRC.Department.PlanningInterval           AS PlanningInterval,
		|	TypesOfRC.Department.PlanningIntervalStart    AS PlanningIntervalStart,
		|	TypesOfRC.Department.PlanningIntervalEnd AS PlanningIntervalEnd,
		|	TypesOfRC.Calendar                                    AS Calendar,
		|	TypesOfRC.AvailabilityReserve                            AS AvailabilityReserve,
		|	TypesOfRC.EnterAvailabilityForWorkCenterType                  AS EnterAvailabilityForWorkCenterType,
		|	CASE
		|		WHEN &UnlimitedEquipmentFleet
		|			THEN FALSE
		|		ELSE TypesOfRC.UseAvailabilityAccordingToSchedule
		|	END                                               AS ConsiderAvailability,
		|	CASE
		|		WHEN NOT TypesOfRC.UseAvailabilityAccordingToSchedule
		|				OR &UnlimitedEquipmentFleet
		|			THEN 100000000
		|		WHEN TypesOfRC.EnterAvailabilityForWorkCenterType
		|			THEN TypesOfRC.NumberOfWorkCenters
		|		ELSE ISNULL(NumberOfRC.NumberOfWorkCenters, 0)
		|	END                                               AS NumberOfWorkCenters,
		|	TypesOfRC.ParallelLoad                         AS ParallelLoad,
		|	CASE TypesOfRC.UnitOfMeasureOfWorkCenterSchedule
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN TypesOfRC.MaximumWorkCenterAvailability * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN TypesOfRC.MaximumWorkCenterAvailability * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|			THEN TypesOfRC.MaximumWorkCenterAvailability * 86400
		|	END                                               AS MaximumAvailability,
		|	TypesOfRC.MaximumLoad                         AS MaximumLoad
		|INTO TTCatalogTypesOfRC
		|FROM
		|	Catalog.WorkCenterTypes AS TypesOfRC
		|	
		|	LEFT JOIN TTNumberOfRC AS NumberOfRC
		|	ON TypesOfRC.Ref = NumberOfRC.WorkCenterType
		|
		|WHERE
		|	NOT TypesOfRC.IsFolder
		|	AND &QueryTextFilterTypesOfRC
		|
		|INDEX BY
		|	WorkCenterType";
	
	If CalculationParameters.AvailabilityVRCSelection.Count() = 0 Then
		QueryText = StrReplace(QueryText,
			"&QueryTextFilterTypesOfRC",
			"TRUE");
	Else
		QueryText = StrReplace(QueryText,
			"&QueryTextFilterTypesOfRC",
			"TypesOfRC.Ref IN (&TypesOfRC)");
	EndIf;
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTCatalogTypesOfRC");
	
	#EndRegion
	
	#Region TTGraphsOfRCTypes
	
	QueryText = 
		"SELECT
		|	TypesOfRC.WorkCenterType              AS WorkCenterType,
		|	TypesOfRC.PlanningInterval           AS PlanningInterval,
		|	TypesOfRC.PlanningIntervalStart    AS PlanningIntervalStart,
		|	TypesOfRC.PlanningIntervalEnd AS PlanningIntervalEnd,
		|	TypesOfRC.ConsiderAvailability           AS ConsiderAvailability,
		|	TypesOfRC.ParallelLoad           AS ParallelLoad,
		|	TypesOfRC.MaximumAvailability        AS MaximumAvailability,
		|	TypesOfRC.MaximumLoad           AS MaximumLoad,
		|	CASE
		|		WHEN TypesOfRC.Calendar <> VALUE(Catalog.Calendars.EmptyRef)
		|			THEN TypesOfRC.Calendar
		|		ELSE ISNULL(Schedules.WorkScheduleCalendar, MainEnterpriseCalendar.Value)
		|	END                                 AS WorkScheduleCalendar
		|INTO TTGraphsOfRCTypes
		|FROM
		|	TTCatalogTypesOfRC AS TypesOfRC
		|
		|	LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS Schedules
		|	ON TypesOfRC.Department = Schedules.Ref
		|		AND TypesOfRC.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|
		|	LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|	ON (TRUE)
		|WHERE
		|	TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
		|	OR NOT TypesOfRC.ConsiderAvailability
		|
		|INDEX BY
		|	WorkScheduleCalendar";
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTGraphsOfRCTypes");
	
	#EndRegion
	
	#Region TTShiftBoundaries
	
	QueryText = 
		"SELECT
		|	WorkSchedules.WorkCenterType AS WorkCenterType,
		|	WorkSchedules.WorkScheduleCalendar      AS Shift,
		|	MIN(DATEADD(Schedule.ScheduleDate, MINUTE,
		|		HOUR(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)))*60
		|		+ MINUTE(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1))))) AS IntervalDate,
		|	MAX(
		|		CASE
		|			WHEN Schedule.EndTime IS NULL 
		|				OR Schedule.EndTime = DATETIME(1, 1, 1)
		|				THEN DATEADD(Schedule.ScheduleDate, DAY, 1)
		|			ELSE DATEADD(Schedule.ScheduleDate, MINUTE,
		|				HOUR(Schedule.EndTime)*60 + MINUTE(Schedule.EndTime))
		|		END) AS EndOfTheInterval
		|INTO TTShiftBoundaries
		|FROM
		|	TTGraphsOfRCTypes AS WorkSchedules
		|	
		|	INNER JOIN TTWorkSchedules AS Schedule
		|	ON WorkSchedules.WorkScheduleCalendar = Schedule.WorkScheduleCalendar
		|WHERE
		|	WorkSchedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
		|
		|GROUP BY
		|	WorkSchedules.WorkCenterType,
		|	WorkSchedules.WorkScheduleCalendar,
		|	Schedule.Period
		|
		|INDEX BY
		|	WorkCenterType,
		|	IntervalDate";
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTShiftBoundaries");
	
	#EndRegion
	
	#Region TTTypesOfRCWithoutTakingIntoAccountAvailabilityHour
	
	If Not CalculationParameters.RoundTheClockWorkSevenDaysAWeek Then
		
		QueryText = 
			"SELECT
			|	WorkSchedules.WorkCenterType AS WorkCenterType,
			|	Schedule.ScheduleDate AS ScheduleDate,
			|	CASE
			|		WHEN ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
			|			THEN 0
			|		WHEN BEGINOFPERIOD(Schedule.BeginTime, HOUR) = Schedule.BeginTime
			|			THEN HOUR(Schedule.BeginTime)
			|		ELSE HOUR(Schedule.BeginTime) + 1
			|	END AS HourIsBeginning,
			|	CASE
			|		WHEN ISNULL(Schedule.EndTime, DATETIME(1, 1, 1)) = DATETIME(1, 1, 1)
			|			THEN 23
			|		WHEN BEGINOFPERIOD(Schedule.EndTime, HOUR) = Schedule.EndTime
			|			THEN HOUR(Schedule.EndTime) - 1
			|		ELSE HOUR(Schedule.EndTime)
			|	END AS HourEnds
			|INTO TTTypesOfRCWithoutTakingIntoAccountAvailabilityHour
			|FROM
			|	TTGraphsOfRCTypes AS WorkSchedules
			|	
			|	INNER JOIN TTWorkSchedules AS Schedule
			|	ON WorkSchedules.WorkScheduleCalendar = Schedule.WorkScheduleCalendar
			|WHERE
			|	NOT WorkSchedules.ConsiderAvailability
			|	AND WorkSchedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTTypesOfRCWithoutTakingIntoAccountAvailabilityHour");
		
	EndIf;
	
	#EndRegion
	
	#Region WCKAvailability
	
	If CalculationParameters.RoundTheClockWorkSevenDaysAWeek Then
		
		QueryText = 
			"SELECT
			|	TypesOfRC.WorkCenterType AS WorkCenterType,
			|	CASE TypesOfRC.PlanningInterval
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN DaysPerPeriod.Date
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
			|			THEN DaysPerPeriod.Date
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN BEGINOFPERIOD(DaysPerPeriod.Date, WEEK)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN BEGINOFPERIOD(DaysPerPeriod.Date, MONTH)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|			THEN DATEADD(DaysPerPeriod.Date, HOUR, ClockCounter.HourNumber)
			|	END                    AS IntervalDate,
			|	CASE TypesOfRC.PlanningInterval
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN DaysPerPeriod.Date
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
			|			THEN DaysPerPeriod.Date
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN BEGINOFPERIOD(DaysPerPeriod.Date, WEEK)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN BEGINOFPERIOD(DaysPerPeriod.Date, MONTH)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|			THEN DATEADD(DaysPerPeriod.Date, HOUR, ClockCounter.HourNumber)
			|	END                    AS StartOfRange,
			|	CASE TypesOfRC.PlanningInterval
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN DATEADD(DaysPerPeriod.Date, DAY, 1)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
			|			THEN DATEADD(DaysPerPeriod.Date, DAY, 1)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN DATEADD(BEGINOFPERIOD(DaysPerPeriod.Date, WEEK), WEEK, 1)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN DATEADD(BEGINOFPERIOD(DaysPerPeriod.Date, MONTH), MONTH, 1)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|			THEN DATEADD(DaysPerPeriod.Date, HOUR, ClockCounter.HourNumber + 1)
			|	END                    AS EndOfTheInterval,
			|	VALUE(Catalog.Calendars.EmptyRef) AS Shift,
			|	CASE
			|		WHEN NOT TypesOfRC.ConsiderAvailability
			|			THEN 100000000
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN 86400 * TypesOfRC.NumberOfWorkCenters
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
			|			THEN 86400 * TypesOfRC.NumberOfWorkCenters
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN 604800 * TypesOfRC.NumberOfWorkCenters
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN COUNT(DaysPerPeriod.Date) * 86400 * TypesOfRC.NumberOfWorkCenters
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|			THEN 3600 * TypesOfRC.NumberOfWorkCenters
			|	END * CASE
			|				WHEN TypesOfRC.ParallelLoad
			|						AND TypesOfRC.MaximumLoad <> 0
			|					THEN TypesOfRC.MaximumLoad
			|				ELSE 1
			|			END            AS AvailableLoadingTime,
			|	CASE
			|		WHEN NOT TypesOfRC.ConsiderAvailability
			|			THEN 100000000
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN 86400 * TypesOfRC.NumberOfWorkCenters
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
			|			THEN 86400 * TypesOfRC.NumberOfWorkCenters
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN 604800 * TypesOfRC.NumberOfWorkCenters
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN COUNT(DaysPerPeriod.Date) * 86400 * TypesOfRC.NumberOfWorkCenters
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|			THEN 3600 * TypesOfRC.NumberOfWorkCenters
			|	END                    AS Available_Time,
			|	CASE
			|		WHEN TypesOfRC.PlanningInterval IN (
			|				VALUE(Enum.ProductionScheduleAccuracy.DAY),
			|				VALUE(Enum.ProductionScheduleAccuracy.Shift))
			|			THEN 86400
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN 604800
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN COUNT(DaysPerPeriod.Date) * 86400
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|			THEN 3600
			|	END * CASE
			|				WHEN TypesOfRC.ParallelLoad
			|						AND TypesOfRC.MaximumLoad <> 0
			|					THEN TypesOfRC.MaximumLoad
			|				ELSE 1
			|			END            AS MaximumLoadingTime,
			|	FALSE                     AS ThisIsIndex
			|FROM
			|	TTCatalogTypesOfRC AS TypesOfRC
			|	
			|	INNER JOIN TTDaysForPeriod AS DaysPerPeriod
			|	ON TRUE
			|	
			|	LEFT JOIN TTClockCounter AS ClockCounter
			|	ON TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|
			|GROUP BY
			|	TypesOfRC.WorkCenterType,
			|	TypesOfRC.ConsiderAvailability,
			|	TypesOfRC.PlanningInterval,
			|	TypesOfRC.NumberOfWorkCenters,
			|	TypesOfRC.ParallelLoad,
			|	TypesOfRC.MaximumLoad,
			|	CASE TypesOfRC.PlanningInterval
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN DaysPerPeriod.Date
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
			|			THEN DaysPerPeriod.Date
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN BEGINOFPERIOD(DaysPerPeriod.Date, WEEK)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN BEGINOFPERIOD(DaysPerPeriod.Date, MONTH)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|			THEN DATEADD(DaysPerPeriod.Date, HOUR, ClockCounter.HourNumber)
			|	END,
			|	CASE TypesOfRC.PlanningInterval
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN DATEADD(DaysPerPeriod.Date, DAY, 1)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
			|			THEN DATEADD(DaysPerPeriod.Date, DAY, 1)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN DATEADD(BEGINOFPERIOD(DaysPerPeriod.Date, WEEK), WEEK, 1)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN DATEADD(BEGINOFPERIOD(DaysPerPeriod.Date, MONTH), MONTH, 1)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|			THEN DATEADD(DaysPerPeriod.Date, HOUR, ClockCounter.HourNumber + 1)
			|	END
			|
			|UNION ALL
			|
			|// Index for searching records
			|SELECT
			|	TypesOfRC.WorkCenterType                    AS WorkCenterType,
			|	CASE TypesOfRC.PlanningInterval
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN BEGINOFPERIOD(DaysPerPeriod.Date, WEEK)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN BEGINOFPERIOD(DaysPerPeriod.Date, MONTH)
			|		ELSE DaysPerPeriod.Date
			|	END                                       AS IntervalDate,
			|	DATETIME(1,1,1,1,1,1)                      AS StartOfRange,
			|	DATETIME(1,1,1,1,1,1)                      AS EndOfTheInterval,
			|	VALUE(Catalog.Calendars.EmptyRef) AS Shift,
			|	0                                           AS AvailableLoadingTime,
			|	0                                           AS Available_Time,
			|	0                                           AS MaximumLoadingTime,
			|	TRUE                                      AS ThisIsIndex
			|FROM
			|	TTCatalogTypesOfRC AS TypesOfRC
			|	
			|	INNER JOIN TTDaysForPeriod AS DaysPerPeriod
			|	ON TRUE
			|
			|UNION ALL
			|
			|SELECT
			|	WCKAvailability.WorkCenterType     AS WorkCenterType,
			|	WCKAvailability.IntervalDate         AS IntervalDate,
			|	WCKAvailability.StartOfRange       AS StartOfRange,
			|	WCKAvailability.EndOfTheInterval    AS EndOfTheInterval,
			|	WCKAvailability.Shift                 AS Shift,
			|	WCKAvailability.AvailableLoadingTime AS AvailableLoadingTime,
			|	WCKAvailability.Available_Time         AS Available_Time,
			|	WCKAvailability.MaximumLoadingTime AS MaximumLoadingTime,
			|	WCKAvailability.ThisIsIndex             AS ThisIsIndex
			|FROM
			|	TTAvailabilityOfVRCIsCurrent AS WCKAvailability
			|
			|ORDER BY
			|	WorkCenterType,
			|	IntervalDate,
			|	ThisIsIndex DESC";
		
	Else
		
		QueryText = 
			"// Types of RC with limited availability
			|SELECT
			|	Enabled.WorkCenterType AS WorkCenterType,
			|	Enabled.IntervalDate     AS IntervalDate,
			|	CASE
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|				AND BEGINOFPERIOD(TypesOfRC.PlanningIntervalStart, DAY) <> TypesOfRC.PlanningIntervalStart
			|			THEN DATEADD(Enabled.IntervalDate, MINUTE, 
			|					HOUR(TypesOfRC.PlanningIntervalStart) * 60
			|					+ MINUTE(TypesOfRC.PlanningIntervalStart))
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|				AND BEGINOFPERIOD(TypesOfRC.PlanningIntervalStart, WEEK) <> TypesOfRC.PlanningIntervalStart
			|			THEN DATEADD(Enabled.IntervalDate, MINUTE,
			|					(DAY(TypesOfRC.PlanningIntervalStart)-1) * 1440
			|					+ HOUR(TypesOfRC.PlanningIntervalStart) * 60
			|					+ MINUTE(TypesOfRC.PlanningIntervalStart))
			|		ELSE Enabled.IntervalDate
			|	END                         AS StartOfRange,
			|	CASE
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|				AND ENDOFPERIOD(TypesOfRC.PlanningIntervalEnd, DAY) <> TypesOfRC.PlanningIntervalEnd
			|			THEN DATEADD(Enabled.IntervalDate, MINUTE, 
			|					HOUR(TypesOfRC.PlanningIntervalEnd) * 60
			|					+ MINUTE(TypesOfRC.PlanningIntervalEnd))
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|				AND ENDOFPERIOD(TypesOfRC.PlanningIntervalEnd, WEEK) <> TypesOfRC.PlanningIntervalEnd
			|			THEN DATEADD(Enabled.IntervalDate, MINUTE,
			|					(DAY(TypesOfRC.PlanningIntervalEnd)-1) * 1440
			|					+ HOUR(TypesOfRC.PlanningIntervalEnd) * 60
			|					+ MINUTE(TypesOfRC.PlanningIntervalEnd))
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN DATEADD(Enabled.IntervalDate, DAY, 1)
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
			|			THEN ISNULL(ShiftBoundaries.EndOfTheInterval, ENDOFPERIOD(Enabled.IntervalDate, DAY))
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN DATEADD(Enabled.IntervalDate, WEEK, 1)
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN DATEADD(Enabled.IntervalDate, MONTH, 1)
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|			THEN DATEADD(Enabled.IntervalDate, HOUR, 1)
			|		ELSE Enabled.IntervalDate
			|	END                         AS EndOfTheInterval,
			|	Enabled.Shift             AS Shift,
			|	CASE
			|		WHEN &UseAvailabilityReserve
			|			THEN SUM(CASE
			|							WHEN TypesOfRC.EnterAvailabilityForWorkCenterType
			|								THEN Enabled.WorkCenterTypeSchedule
			|							ELSE Enabled.WorkCenterSchedule
			|						END) - SUM(Enabled.Busy)
			|		ELSE 
			|			CAST(
			|				SUM(CASE
			|							WHEN TypesOfRC.EnterAvailabilityForWorkCenterType
			|								THEN Enabled.WorkCenterTypeSchedule
			|							ELSE Enabled.WorkCenterSchedule
			|						END) * (100 - MAX(TypesOfRC.AvailabilityReserve)) / 100
			|				AS NUMBER(15, 0))
			|			- SUM(Enabled.Busy)
			|	END * CASE
			|				WHEN TypesOfRC.ParallelLoad
			|						AND TypesOfRC.MaximumLoad <> 0
			|					THEN TypesOfRC.MaximumLoad
			|				ELSE 1
			|			END                 AS AvailableLoadingTime,
			|	CASE
			|		WHEN &UseAvailabilityReserve
			|			THEN SUM(CASE
			|							WHEN TypesOfRC.EnterAvailabilityForWorkCenterType
			|								THEN Enabled.WorkCenterTypeSchedule
			|							ELSE Enabled.WorkCenterSchedule
			|						END) - SUM(Enabled.Busy)
			|		ELSE 
			|			CAST(
			|				SUM(CASE
			|							WHEN TypesOfRC.EnterAvailabilityForWorkCenterType
			|								THEN Enabled.WorkCenterTypeSchedule
			|							ELSE Enabled.WorkCenterSchedule
			|						END) * (100 - MAX(TypesOfRC.AvailabilityReserve)) / 100
			|				AS NUMBER(15, 0))
			|			- SUM(Enabled.Busy)
			|	END                         AS Available_Time,
			|	SUM(CASE
			|			WHEN TypesOfRC.EnterAvailabilityForWorkCenterType
			|				THEN Enabled.MaximumAvailabilityByWorkCenterType
			|			ELSE Enabled.MaximumAvailability
			|		END) * CASE
			|				WHEN TypesOfRC.ParallelLoad
			|						AND TypesOfRC.MaximumLoad <> 0
			|					THEN TypesOfRC.MaximumLoad
			|				ELSE 1
			|			END                 AS MaximumLoadingTime,
			|	FALSE                          AS ThisIsIndex
			|FROM
			|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS Enabled
			|	
			|	INNER JOIN TTCatalogTypesOfRC AS TypesOfRC
			|	ON Enabled.WorkCenterType = TypesOfRC.WorkCenterType
			|	
			|	LEFT JOIN TTPriorityOrders AS PriorityOrders
			|	ON Enabled.ReferenceOrder = PriorityOrders.Ref
			|	
			|	LEFT JOIN TTShiftBoundaries AS ShiftBoundaries
			|	ON Enabled.WorkCenterType = ShiftBoundaries.WorkCenterType
			|		AND Enabled.IntervalDate = ShiftBoundaries.IntervalDate
			|
			|WHERE
			|	TypesOfRC.ConsiderAvailability
			|	AND Enabled.IntervalDate >= &Begin
			|	AND Enabled.IntervalDate < &Ending
			|	AND (Enabled.IsRecordOfWorkCentersCapacityChange
			|		OR PriorityOrders.Ref IS NOT NULL
			|		OR Enabled.Recorder REFS Document.ProductionStage2_2
			|			AND CAST(Enabled.Recorder AS Document.ProductionStage2_2).Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
			|		OR Enabled.Recorder REFS Document.ProductionStage2_2
			|			AND Enabled.ReferenceOrder = &OrderDocument
			|			AND CAST(Enabled.Recorder AS Document.ProductionStage2_2).StagePlacementInProductionSchedule
			|			AND NOT &CancelManualChangesOfSchedule
			|		OR Enabled.Recorder REFS Document.ProductionStage2_2
			|			AND Enabled.ReferenceOrder <> &OrderDocument
			|			AND CAST(Enabled.Recorder AS Document.ProductionStage2_2).StagePlacementInProductionSchedule
			|		OR &TakeIntoAccountLoadingOfRunningLotReferences)
			|	AND Enabled.Active
			|
			|GROUP BY
			|	Enabled.WorkCenterType,
			|	Enabled.IntervalDate,
			|	TypesOfRC.ParallelLoad,
			|	TypesOfRC.MaximumLoad,
			|	CASE
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|				AND BEGINOFPERIOD(TypesOfRC.PlanningIntervalStart, DAY) <> TypesOfRC.PlanningIntervalStart
			|			THEN DATEADD(Enabled.IntervalDate, MINUTE, 
			|					HOUR(TypesOfRC.PlanningIntervalStart) * 60
			|					+ MINUTE(TypesOfRC.PlanningIntervalStart))
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|				AND BEGINOFPERIOD(TypesOfRC.PlanningIntervalStart, WEEK) <> TypesOfRC.PlanningIntervalStart
			|			THEN DATEADD(Enabled.IntervalDate, MINUTE,
			|					(DAY(TypesOfRC.PlanningIntervalStart)-1) * 1440
			|					+ HOUR(TypesOfRC.PlanningIntervalStart) * 60
			|					+ MINUTE(TypesOfRC.PlanningIntervalStart))
			|		ELSE Enabled.IntervalDate
			|	END,
			|	CASE
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|				AND ENDOFPERIOD(TypesOfRC.PlanningIntervalEnd, DAY) <> TypesOfRC.PlanningIntervalEnd
			|			THEN DATEADD(Enabled.IntervalDate, MINUTE, 
			|					HOUR(TypesOfRC.PlanningIntervalEnd) * 60
			|					+ MINUTE(TypesOfRC.PlanningIntervalEnd))
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|				AND ENDOFPERIOD(TypesOfRC.PlanningIntervalEnd, WEEK) <> TypesOfRC.PlanningIntervalEnd
			|			THEN DATEADD(Enabled.IntervalDate, MINUTE,
			|					(DAY(TypesOfRC.PlanningIntervalEnd)-1) * 1440
			|					+ HOUR(TypesOfRC.PlanningIntervalEnd) * 60
			|					+ MINUTE(TypesOfRC.PlanningIntervalEnd))
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN DATEADD(Enabled.IntervalDate, DAY, 1)
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
			|			THEN ISNULL(ShiftBoundaries.EndOfTheInterval, ENDOFPERIOD(Enabled.IntervalDate, DAY))
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN DATEADD(Enabled.IntervalDate, WEEK, 1)
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN DATEADD(Enabled.IntervalDate, MONTH, 1)
			|		WHEN TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|			THEN DATEADD(Enabled.IntervalDate, HOUR, 1)
			|		ELSE Enabled.IntervalDate
			|	END,
			|	Enabled.Shift
			|
			|UNION ALL
			|
			|// Types of RC without restriction of availability (Day, Week, Month)
			|SELECT DISTINCT
			|	WorkSchedules.WorkCenterType             AS WorkCenterType,
			|	CASE WorkSchedules.PlanningInterval
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN BEGINOFPERIOD(Schedule.ScheduleDate, DAY)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN BEGINOFPERIOD(Schedule.ScheduleDate, WEEK)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN BEGINOFPERIOD(Schedule.ScheduleDate, MONTH)
			|	END                                       AS IntervalDate,
			|	CASE
			|		WHEN WorkSchedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|				AND BEGINOFPERIOD(WorkSchedules.PlanningIntervalStart, DAY) <> WorkSchedules.PlanningIntervalStart
			|			THEN DATEADD(BEGINOFPERIOD(Schedule.ScheduleDate, DAY), MINUTE, 
			|					HOUR(WorkSchedules.PlanningIntervalStart) * 60
			|					+ MINUTE(WorkSchedules.PlanningIntervalStart))
			|		WHEN WorkSchedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|				AND BEGINOFPERIOD(WorkSchedules.PlanningIntervalStart, WEEK) <> WorkSchedules.PlanningIntervalStart
			|			THEN DATEADD(BEGINOFPERIOD(Schedule.ScheduleDate, WEEK), MINUTE,
			|					(DAY(WorkSchedules.PlanningIntervalStart)-1) * 1440
			|					+ HOUR(WorkSchedules.PlanningIntervalStart) * 60
			|					+ MINUTE(WorkSchedules.PlanningIntervalStart))
			|		WHEN WorkSchedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN BEGINOFPERIOD(Schedule.ScheduleDate, DAY)
			|		WHEN WorkSchedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN BEGINOFPERIOD(Schedule.ScheduleDate, WEEK)
			|		WHEN WorkSchedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN BEGINOFPERIOD(Schedule.ScheduleDate, MONTH)
			|	END                                       AS StartOfRange,
			|	CASE
			|		WHEN WorkSchedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|				AND ENDOFPERIOD(WorkSchedules.PlanningIntervalEnd, DAY) <> WorkSchedules.PlanningIntervalEnd
			|			THEN DATEADD(BEGINOFPERIOD(Schedule.ScheduleDate, DAY), MINUTE, 
			|					HOUR(WorkSchedules.PlanningIntervalEnd) * 60
			|					+ MINUTE(WorkSchedules.PlanningIntervalEnd))
			|		WHEN WorkSchedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|				AND ENDOFPERIOD(WorkSchedules.PlanningIntervalEnd, WEEK) <> WorkSchedules.PlanningIntervalEnd
			|			THEN DATEADD(BEGINOFPERIOD(Schedule.ScheduleDate, WEEK), MINUTE,
			|					(DAY(WorkSchedules.PlanningIntervalEnd)-1) * 1440
			|					+ HOUR(WorkSchedules.PlanningIntervalEnd) * 60
			|					+ MINUTE(WorkSchedules.PlanningIntervalEnd))
			|		WHEN WorkSchedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN DATEADD(BEGINOFPERIOD(Schedule.ScheduleDate, DAY), DAY, 1)
			|		WHEN WorkSchedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN DATEADD(BEGINOFPERIOD(Schedule.ScheduleDate, WEEK), WEEK, 1)
			|		WHEN WorkSchedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN DATEADD(BEGINOFPERIOD(Schedule.ScheduleDate, MONTH), MONTH, 1)
			|	END                                       AS EndOfTheInterval,
			|	VALUE(Catalog.Calendars.EmptyRef) AS Shift,
			|	100000000                                   AS AvailableLoadingTime,
			|	100000000                                   AS Available_Time,
			|	WorkSchedules.MaximumAvailability
			|		* CASE
			|			WHEN WorkSchedules.ParallelLoad
			|					AND WorkSchedules.MaximumLoad <> 0
			|				THEN WorkSchedules.MaximumLoad
			|			ELSE 1
			|		END                                   AS MaximumLoadingTime,
			|	FALSE                                        AS ThisIsIndex
			|FROM
			|	TTGraphsOfRCTypes AS WorkSchedules
			|	
			|	INNER JOIN TTWorkSchedules AS Schedule
			|	ON WorkSchedules.WorkScheduleCalendar = Schedule.WorkScheduleCalendar
			|WHERE
			|	NOT WorkSchedules.ConsiderAvailability
			|	AND WorkSchedules.PlanningInterval IN (
			|		VALUE(Enum.ProductionScheduleAccuracy.DAY),
			|		VALUE(Enum.ProductionScheduleAccuracy.WEEK),
			|		VALUE(Enum.ProductionScheduleAccuracy.MONTH))
			|
			|UNION ALL
			|
			|// Types of RC without restriction of availability (Shift)
			|SELECT
			|	ShiftBoundaries.WorkCenterType  AS WorkCenterType,
			|	ShiftBoundaries.IntervalDate      AS IntervalDate,
			|	ShiftBoundaries.IntervalDate      AS StartOfRange,
			|	ShiftBoundaries.EndOfTheInterval AS EndOfTheInterval,
			|	ShiftBoundaries.Shift              AS Shift,
			|	100000000                      AS AvailableLoadingTime,
			|	100000000                      AS Available_Time,
			|	TypesOfRC.MaximumAvailability
			|		* CASE
			|			WHEN TypesOfRC.ParallelLoad
			|					AND TypesOfRC.MaximumLoad <> 0
			|				THEN TypesOfRC.MaximumLoad
			|			ELSE 1
			|		END                      AS MaximumLoadingTime,
			|	FALSE                           AS ThisIsIndex
			|FROM
			|	TTShiftBoundaries AS ShiftBoundaries
			|	
			|	INNER JOIN TTCatalogTypesOfRC AS TypesOfRC
			|	ON ShiftBoundaries.WorkCenterType = TypesOfRC.WorkCenterType
			|WHERE
			|	NOT TypesOfRC.ConsiderAvailability
			|
			|UNION ALL
			|
			|// Types of RC without limited availability (Hour)
			|SELECT
			|	TypesOfRCHour.WorkCenterType                 AS WorkCenterType,
			|	DATEADD(TypesOfRCHour.ScheduleDate, HOUR, ClockCounter.HourNumber)     AS IntervalDate,
			|	DATEADD(TypesOfRCHour.ScheduleDate, HOUR, ClockCounter.HourNumber)     AS StartOfRange,
			|	DATEADD(TypesOfRCHour.ScheduleDate, HOUR, ClockCounter.HourNumber + 1) AS EndOfTheInterval,
			|	VALUE(Catalog.Calendars.EmptyRef) AS Shift,
			|	100000000                                   AS AvailableLoadingTime,
			|	100000000                                   AS Available_Time,
			|	TypesOfRC.MaximumAvailability
			|		* CASE
			|			WHEN TypesOfRC.ParallelLoad
			|					AND TypesOfRC.MaximumLoad <> 0
			|				THEN TypesOfRC.MaximumLoad
			|			ELSE 1
			|		END                                   AS MaximumLoadingTime,
			|	FALSE                                        AS ThisIsIndex
			|FROM
			|	TTTypesOfRCWithoutTakingIntoAccountAvailabilityHour AS TypesOfRCHour
			|	
			|	INNER JOIN TTClockCounter AS ClockCounter
			|	ON ClockCounter.HourNumber BETWEEN TypesOfRCHour.HourIsBeginning AND TypesOfRCHour.HourEnds
			|	
			|	INNER JOIN TTCatalogTypesOfRC AS TypesOfRC
			|	ON TypesOfRCHour.WorkCenterType = TypesOfRC.WorkCenterType
			|
			|UNION ALL
			|
			|// Index for searching records
			|SELECT
			|	TypesOfRC.WorkCenterType                    AS WorkCenterType,
			|	CASE TypesOfRC.PlanningInterval
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN BEGINOFPERIOD(DaysPerPeriod.Date, WEEK)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN BEGINOFPERIOD(DaysPerPeriod.Date, MONTH)
			|		ELSE DaysPerPeriod.Date
			|	END                                       AS IntervalDate,
			|	DATETIME(1,1,1,1,1,1)                      AS StartOfRange,
			|	DATETIME(1,1,1,1,1,1)                      AS EndOfTheInterval,
			|	VALUE(Catalog.Calendars.EmptyRef) AS Shift,
			|	0                                           AS AvailableLoadingTime,
			|	0                                           AS Available_Time,
			|	0                                           AS MaximumLoadingTime,
			|	TRUE                                      AS ThisIsIndex
			|FROM
			|	TTCatalogTypesOfRC AS TypesOfRC
			|	
			|	INNER JOIN TTDaysForPeriod AS DaysPerPeriod
			|	ON TRUE
			|
			|GROUP BY
			|	TypesOfRC.WorkCenterType,
			|	CASE TypesOfRC.PlanningInterval
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN BEGINOFPERIOD(DaysPerPeriod.Date, WEEK)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN BEGINOFPERIOD(DaysPerPeriod.Date, MONTH)
			|		ELSE DaysPerPeriod.Date
			|	END
			|
			|UNION ALL
			|
			|SELECT
			|	WCKAvailability.WorkCenterType     AS WorkCenterType,
			|	WCKAvailability.IntervalDate         AS IntervalDate,
			|	WCKAvailability.StartOfRange       AS StartOfRange,
			|	WCKAvailability.EndOfTheInterval    AS EndOfTheInterval,
			|	WCKAvailability.Shift                 AS Shift,
			|	WCKAvailability.AvailableLoadingTime AS AvailableLoadingTime,
			|	WCKAvailability.Available_Time         AS Available_Time,
			|	WCKAvailability.MaximumLoadingTime AS MaximumLoadingTime,
			|	WCKAvailability.ThisIsIndex             AS ThisIsIndex
			|FROM
			|	TTAvailabilityOfVRCIsCurrent AS WCKAvailability
			|
			|ORDER BY
			|	WorkCenterType,
			|	IntervalDate,
			|	ThisIsIndex DESC";
		
		If CalculationParameters.AvailabilityTakeIntoAccountLoadingOfRunningLotReferences Then
			QueryText = StrReplace(QueryText,
				"&TakeIntoAccountLoadingOfRunningLotReferences",
				"Enabled.Recorder REFS Document.ProductionStage2_2 AND Enabled.ReferenceOrder = &OrderDocument");
		Else
			QueryText = StrReplace(QueryText,
				"&TakeIntoAccountLoadingOfRunningLotReferences",
				"FALSE");
		EndIf;
		
	EndIf;
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "WCKAvailability");
	
	#EndRegion
	
	If Not ThisIsAdditionalReading
		And Not CalculationParameters.RoundTheClockWorkSevenDaysAWeek Then
		
		#Region TTBoundariesOfGraphs
		
		QueryText = 
			"SELECT
			|	CalendarSchedules.Calendar             AS WorkScheduleCalendar,
			|	MAX(CalendarSchedules.ScheduleDate) AS Boundary
			|INTO TTBoundariesOfGraphs
			|FROM
			|	InformationRegister.CalendarSchedules AS CalendarSchedules
			|WHERE
			|	CalendarSchedules.Calendar IN (
			|		SELECT DISTINCT
			|			T.WorkScheduleCalendar AS Calendar
			|		FROM
			|			TTGraphsOfRCTypes AS T
			|		WHERE
			|			NOT T.ConsiderAvailability
			|		
			|		UNION ALL
			|		
			|		SELECT DISTINCT
			|			T.WorkScheduleCalendar AS Calendar
			|		FROM
			|			TTDivisionSchedules AS T)
			|	AND CalendarSchedules.DayAddedToSchedule
			|	
			|GROUP BY
			|	CalendarSchedules.Calendar
			|
			|INDEX BY
			|	WorkScheduleCalendar";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTBoundariesOfGraphs");
		
		#EndRegion
		
		#Region AvailabilityLimits
		
		QueryText = 
			"SELECT
			|	AvailabilityTurnover.WorkCenterType       AS Ref,
			|	MAX(AvailabilityTurnover.IntervalDate) AS Boundary
			|FROM
			|	AccumulationRegister.AvailabilityOfWorkCenterTypes.Turnovers(,,, &QueryTextFilterTypesOfRC) AS AvailabilityTurnover
			|
			|GROUP BY
			|	AvailabilityTurnover.WorkCenterType
			|
			|UNION ALL
			|
			|SELECT
			|	Schedules.WorkCenterType         AS Ref,
			|	MAX(GraphBoundaries.Boundary) AS Boundary
			|FROM
			|	TTGraphsOfRCTypes AS Schedules
			|	
			|	INNER JOIN TTBoundariesOfGraphs AS GraphBoundaries
			|	ON Schedules.WorkScheduleCalendar = GraphBoundaries.WorkScheduleCalendar
			|WHERE
			|	NOT Schedules.ConsiderAvailability
			|
			|GROUP BY
			|	Schedules.WorkCenterType
			|
			|UNION ALL
			|
			|SELECT
			|	Schedules.Department             AS Ref,
			|	MAX(GraphBoundaries.Boundary) AS Boundary
			|FROM
			|	TTDivisionSchedules AS Schedules
			|	
			|	INNER JOIN TTBoundariesOfGraphs AS GraphBoundaries
			|	ON Schedules.WorkScheduleCalendar = GraphBoundaries.WorkScheduleCalendar
			|
			|GROUP BY
			|	Schedules.Department";
		
		If CalculationParameters.AvailabilityVRCSelection.Count() = 0 Then
			QueryText = StrReplace(QueryText,
				"&QueryTextFilterTypesOfRC",
				"TRUE");
		Else
			QueryText = StrReplace(QueryText,
				"&QueryTextFilterTypesOfRC",
				"WorkCenterType IN (&TypesOfRC)");
		EndIf;
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "AvailabilityLimits");
		
		#EndRegion
		
	EndIf;
	
	SetPrivilegedMode(True);
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts,, False, False);
	SetPrivilegedMode(False);
	
	DivisionScheduleDay = Tables.DivisionScheduleDay; // ValueTable
	DivisionScheduleDay.Indexes.Add("Department, Date");
	PaymentData.DivisionScheduleDay = DivisionScheduleDay;
	
	SecundaDivisionSchedule = Tables.SecundaDivisionSchedule; // ValueTable
	SecundaDivisionSchedule.Indexes.Add("Department, Date");
	PaymentData.SecundaDivisionSchedule = SecundaDivisionSchedule;
	
	WCKAvailability = Tables.WCKAvailability; // ValueTable
	WCKAvailability.Indexes.Add("WorkCenterType, IntervalDate, ThisIsIndex");
	PaymentData.WCKAvailability = WCKAvailability;
	
	If Not ThisIsAdditionalReading
		And Not CalculationParameters.RoundTheClockWorkSevenDaysAWeek Then
		AvailabilityLimits = Tables.AvailabilityLimits; // ValueTable
		AvailabilityLimits.Indexes.Add("Ref");
		PaymentData.AvailabilityLimits = AvailabilityLimits;
	EndIf;
	
EndProcedure

Function ReadFullAvailabilityAndFindInterval(PaymentData, CalculationParameters, Ref, TableName, TheStructureOfTheSearch, Date)
	
	If CalculationParameters.RoundTheClockWorkSevenDaysAWeek Then
		AvailabilityBoundary = New Structure("Boundary", '39990101');
	Else
		AvailabilityBoundary = PaymentData.AvailabilityLimits.Find(Ref, "Ref");
		If AvailabilityBoundary = Undefined
			Or AvailabilityBoundary.Boundary < Date Then
			Return Undefined;
		EndIf;
	EndIf;
	
	Boundary = Min(EndOfMonth(AddMonth(Date, 2)), AvailabilityBoundary.Boundary);
	ReadAvailability(CalculationParameters.OrderDocument, PaymentData, CalculationParameters, Boundary);
	
	FoundRows = PaymentData[TableName].FindRows(TheStructureOfTheSearch);
	
	Return FoundRows;
	
EndFunction

Function ReadMoreAccessibility(PaymentData, CalculationParameters, Interval, TableName)
	
	TheStructureOfTheSearch = New Structure;
	FieldNameRef = "";
	If TableName = "DivisionScheduleDay"
		Or TableName = "SecundaDivisionSchedule" Then
		TheStructureOfTheSearch.Insert("Department");
		TheStructureOfTheSearch.Insert("Date");
		TheStructureOfTheSearch.Insert("Begin");
		TheStructureOfTheSearch.Insert("Ending");
		TheStructureOfTheSearch.Insert("ThisIsIndex");
		FieldNameRef = "Department";
	ElsIf TableName = "WCKAvailability" Then
		TheStructureOfTheSearch.Insert("WorkCenterType");
		TheStructureOfTheSearch.Insert("IntervalDate");
		TheStructureOfTheSearch.Insert("StartOfRange");
		TheStructureOfTheSearch.Insert("EndOfTheInterval");
		TheStructureOfTheSearch.Insert("ThisIsIndex");
		FieldNameRef = "WorkCenterType"
	EndIf;
	FillPropertyValues(TheStructureOfTheSearch, Interval);
	
	If CalculationParameters.RoundTheClockWorkSevenDaysAWeek Then
		AvailabilityBoundary = New Structure("Boundary", '39990101');
	Else
		AvailabilityBoundary = PaymentData.AvailabilityLimits.Find(Interval[FieldNameRef], "Ref");
		If AvailabilityBoundary = Undefined Then
			Return False;
		EndIf;
	EndIf;
	
	While AvailabilityBoundary.Boundary > CalculationParameters.AvailabilitySelectionBoundary Do
		ReadAvailability(CalculationParameters.OrderDocument, PaymentData, CalculationParameters);
		
		FoundRows = PaymentData[TableName].FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() = 0 Then
			Return False;
		EndIf;
		
		Interval = FoundRows[0]; // The Cur interval in the new table can be used in the calling method
		IndexOf = PaymentData[TableName].IndexOf(Interval) + 1;
		
		While IndexOf < PaymentData[TableName].Count() Do
			If PaymentData[TableName][IndexOf][FieldNameRef] <> Interval[FieldNameRef] Then
				Break;
			ElsIf Not PaymentData[TableName][IndexOf].ThisIsIndex Then
				Return True;
			EndIf;
			IndexOf = IndexOf + 1;
		EndDo;
	EndDo;
	
	Return False;
	
EndFunction

Function AvailabilitySamplingInterval(PaymentData)
	
	OrderDetails = PaymentData.OrderDetails;
	
	Query = New Query(
		"SELECT
		|	MAX(BusinessStructure.PlanningInterval
		|		= VALUE(Enum.ProductionScheduleAccuracy.MONTH))  AS ThereIsMonth,
		|	MAX(BusinessStructure.PlanningInterval
		|		= VALUE(Enum.ProductionScheduleAccuracy.WEEK)) AS ThereIsWeek,
		|	MAX(BusinessStructure.PlanningInterval
		|		= VALUE(Enum.ProductionScheduleAccuracy.Shift))  AS ThereIsShift,
		|	MAX(BusinessStructure.PlanningInterval
		|		= VALUE(Enum.ProductionScheduleAccuracy.HOUR))    AS ThereIsHour
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|WHERE
		|	NOT BusinessStructure.DeletionMark
		|	AND BusinessStructure.ProductionBusinessUnit
		|HAVING
		|	COUNT(BusinessStructure.Ref) > 0");
	SelectingDivision = Query.Execute().Select();
	
	Begin = ?(OrderDetails.EarliestStartDate < CurrentSessionDate(),
		BegOfDay(CurrentSessionDate()),
		BegOfDay(OrderDetails.EarliestStartDate));
	ThereIsIntervalOfHour = False;
	
	If SelectingDivision.Next() Then
		BegOfMonth = ?(SelectingDivision.ThereIsMonth, BegOfMonth(Begin), Begin);
		BegOfWeek = ?(SelectingDivision.ThereIsWeek, BegOfWeek(Begin), Begin);
		StartOfShift = ?(SelectingDivision.ThereIsShift, BegOfDay(Begin - 86400), Begin);
		Begin = Min(BegOfMonth, BegOfWeek, StartOfShift);
		
		ThereIsIntervalOfHour = SelectingDivision.ThereIsHour;
	EndIf;
	
	Ending = '00010101';
	If Begin > OrderDetails.DemandDate Then
		Ending = EndOfMonth(AddMonth(Begin, 3));
	ElsIf ThereIsIntervalOfHour
		And OrderDetails.DateDifferenceInMonths > 6 Then
		Ending = EndOfMonth(AddMonth(Begin, 6));
	ElsIf OrderDetails.DateDifferenceInMonths > 18 Then
		Ending = EndOfMonth(AddMonth(Begin, 18));
	Else
		Ending = EndOfMonth(AddMonth(OrderDetails.DemandDate, 3));
	EndIf;
	
	Return New Structure("Begin, Ending", Begin, Ending);
	
EndFunction

#EndRegion

#Region DurationPlanning

Procedure PlaceStageByDuration(PaymentData, CalculationParameters, Stage, ToGoBackToBeginning)
	
	If Stage.StageDuration = 0 Then
		Stage.Begin = Stage.StartOfPlacement;
		Stage.Ending = Stage.StartOfPlacement;
		Return;
	EndIf;
	
	If Stage.PostInDays Then
		Stage2_ = PlaceDivisionsAccordingToScheduleInDays(
			PaymentData, CalculationParameters, Stage, Stage.StageDuration, Stage.StartOfPlacement, ToGoBackToBeginning);
	Else
		Stage2_ = PlaceUnitsAccordingToScheduleInSeconds(
			PaymentData, CalculationParameters, Stage, Stage.StageDuration, Stage.StartOfPlacement, ToGoBackToBeginning);
	EndIf;
	
	If Not Stage2_ Then
		Return;
	EndIf;
	
	Stage.Begin = CalculationParameters.BeginningEnding.Begin;
	Stage.Ending = CalculationParameters.BeginningEnding.Ending - 1;
	
	Stage.ScheduleIsChanged = Stage.StartBeforeChange <> Stage.Begin
		Or Stage.EndingBeforeChange <> Stage.Ending;
	
EndProcedure

Function PlaceDivisionsAccordingToScheduleInDays(PaymentData, CalculationParameters, Stage, Val Duration, Date, ToGoBackToBeginning)
	
	Begin = '00010101';
	Ending = '00010101';
	
	Interval = InitialIntervalOfDivisionInDays(
		PaymentData, CalculationParameters, Stage.Department, Date, ToGoBackToBeginning); // ValueTableRow
	If Interval = Undefined Then
		HandleDivisionIntervalNotFoundError(CalculationParameters, Stage, Date, ToGoBackToBeginning);
		Return False;
	EndIf;
	
	If ToGoBackToBeginning Then
		Begin = Interval.Begin;
	Else
		Ending = Interval.Ending;
	EndIf;
	
	While True Do
		Duration = Duration - 1;
		
		// Selection of the next interval
		If ToGoBackToBeginning Then
			If Duration = 0 Then
				Ending = Interval.Ending;
				Break;
			EndIf;
			
			IndexOf = PaymentData.DivisionScheduleDay.IndexOf(Interval);
			RowsCount = PaymentData.DivisionScheduleDay.Count();
			While IndexOf < RowsCount Do
				// Read More Accessibility
				If IndexOf = RowsCount - 1
					Or PaymentData.DivisionScheduleDay[IndexOf + 1].Department <> Stage.Department Then
					ThereAreRecords = ReadMoreAccessibility(PaymentData, CalculationParameters, Interval, "DivisionScheduleDay");
					If Not ThereAreRecords Then
						HandleDivisionIntervalNotFoundError(CalculationParameters, Stage, Interval.Ending, ToGoBackToBeginning);
						Return False;
					EndIf;
					
					IndexOf = PaymentData.DivisionScheduleDay.IndexOf(Interval);
					RowsCount = PaymentData.DivisionScheduleDay.Count();
				EndIf;
				
				IndexOf = IndexOf + 1;
				Interval = PaymentData.DivisionScheduleDay[IndexOf];
				If Not Interval.ThisIsIndex Then
					Break;
				EndIf;
			EndDo;
		Else
			If Duration = 0 Then
				Begin = Interval.Begin;
				Break;
			EndIf;
			
			IndexOf = PaymentData.DivisionScheduleDay.IndexOf(Interval);
			While IndexOf >= 0 Do
				// When placed back, full availability should be read
				If IndexOf = 0
					Or PaymentData.DivisionScheduleDay[IndexOf - 1].Department <> Stage.Department Then
					HandleDivisionIntervalNotFoundError(CalculationParameters, Stage, Interval.Begin, ToGoBackToBeginning);
					Return False;
				EndIf;
				
				IndexOf = IndexOf - 1;
				Interval = PaymentData.DivisionScheduleDay[IndexOf];
				If Not Interval.ThisIsIndex Then
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	CalculationParameters.BeginningEnding.Begin = Begin;
	CalculationParameters.BeginningEnding.Ending = Ending;
	
	Return True;
	
EndFunction

Function PlaceUnitsAccordingToScheduleInSeconds(PaymentData, CalculationParameters, Stage, Val Duration, Date, ToGoBackToBeginning)
	
	Begin = '00010101';
	Ending = '00010101';
	
	Interval = InitialIntervalOfDivisionInSeconds(
		PaymentData, CalculationParameters, Stage.Department, Date, ToGoBackToBeginning); // ValueTableRow
	If Interval = Undefined Then
		HandleDivisionIntervalNotFoundError(CalculationParameters, Stage, Date, ToGoBackToBeginning);
		Return False;
	EndIf;
	
	If Date >= Interval.Begin And Date <= Interval.Ending Then
		If ToGoBackToBeginning Then
			Begin = Date;
			
			OffsetTime = Min(Duration, Interval.Ending - Begin);
			Duration = Duration - OffsetTime;
			
			If Duration = 0 Then
				Ending = Begin + OffsetTime;
			EndIf;
		Else
			Ending = Date;
			
			OffsetTime = Min(Duration, Ending - Interval.Begin);
			Duration = Duration - OffsetTime;
			
			If Duration = 0 Then
				Begin = Ending - OffsetTime;
			EndIf;
		EndIf;
	Else
		OffsetTime = Min(Duration, Interval.Duration);
		Duration = Duration - OffsetTime;
		
		If ToGoBackToBeginning Then
			Begin = Interval.Begin;
			
			If Duration = 0 Then
				Ending = Begin + OffsetTime;
			EndIf;
		Else
			Ending = Interval.Ending;
			
			If Duration = 0 Then
				Begin = Ending - OffsetTime;
			EndIf;
		EndIf;
	EndIf;
	
	While Duration > 0 Do
		// Selection of the next interval
		If ToGoBackToBeginning Then
			IndexOf = PaymentData.SecundaDivisionSchedule.IndexOf(Interval);
			RowsCount = PaymentData.SecundaDivisionSchedule.Count();
			While IndexOf < RowsCount Do
				// Read More Accessibility
				If IndexOf = RowsCount - 1
					Or PaymentData.SecundaDivisionSchedule[IndexOf + 1].Department <> Stage.Department Then
					ThereAreRecords = ReadMoreAccessibility(PaymentData, CalculationParameters, Interval, "SecundaDivisionSchedule");
					If Not ThereAreRecords Then
						HandleDivisionIntervalNotFoundError(CalculationParameters, Stage, Interval.Ending, ToGoBackToBeginning);
						Return False;
					EndIf;
					
					IndexOf = PaymentData.SecundaDivisionSchedule.IndexOf(Interval);
					RowsCount = PaymentData.SecundaDivisionSchedule.Count();
				EndIf;
				
				IndexOf = IndexOf + 1;
				Interval = PaymentData.SecundaDivisionSchedule[IndexOf];
				If Not Interval.ThisIsIndex Then
					Break;
				EndIf;
			EndDo;
		Else
			IndexOf = PaymentData.SecundaDivisionSchedule.IndexOf(Interval);
			While IndexOf >= 0 Do
				// When placed back, full availability should be read
				If IndexOf = 0
					Or PaymentData.SecundaDivisionSchedule[IndexOf - 1].Department <> Stage.Department Then
					HandleDivisionIntervalNotFoundError(CalculationParameters, Stage, Interval.Begin, ToGoBackToBeginning);
					Return False;
				EndIf;
				
				IndexOf = IndexOf - 1;
				Interval = PaymentData.SecundaDivisionSchedule[IndexOf];
				If Not Interval.ThisIsIndex Then
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		// End calculation
		OffsetTime = Min(Duration, Interval.Duration);
		Duration = Duration - OffsetTime;
		
		If Duration = 0 Then
			If ToGoBackToBeginning Then
				Ending = Interval.Begin + OffsetTime;
			Else
				Begin = Interval.Ending - OffsetTime;
			EndIf;
			Break;
		EndIf;
	EndDo;
	
	CalculationParameters.BeginningEnding.Begin = Begin;
	CalculationParameters.BeginningEnding.Ending = Ending;
	
	Return True;
	
EndFunction

Function InitialIntervalOfDivisionInDays(PaymentData, CalculationParameters, Department, StartOfPlacement, ToGoBackToBeginning)
	
	If ToGoBackToBeginning Then
		CalculationParameters.DivisionDate.Department = Department;
		CalculationParameters.DivisionDate.Date = BegOfDay(StartOfPlacement);
		
		FoundRows = PaymentData.DivisionScheduleDay.FindRows(CalculationParameters.DivisionDate);
		If FoundRows.Count() = 0 Then
			FoundRows = ReadFullAvailabilityAndFindInterval(
				PaymentData, CalculationParameters, Department, "DivisionScheduleDay", CalculationParameters.DivisionDate, StartOfPlacement);
			If FoundRows = Undefined
				Or FoundRows.Count() = 0 Then
				Return Undefined;
			EndIf;
		EndIf;
		
		If Not FoundRows[0].ThisIsIndex
			And StartOfPlacement <= FoundRows[0].Begin Then
			Return FoundRows[0];
		Else
			Interval = FoundRows[0];
			IndexOf = PaymentData.DivisionScheduleDay.IndexOf(Interval);
			RowsCount = PaymentData.DivisionScheduleDay.Count();
			While IndexOf < RowsCount Do
				// Read More Accessibility
				If IndexOf = RowsCount - 1
					Or PaymentData.DivisionScheduleDay[IndexOf + 1].Department <> Department Then
					ThereAreRecords = ReadMoreAccessibility(PaymentData, CalculationParameters, Interval, "DivisionScheduleDay");
					If Not ThereAreRecords Then
						Return Undefined;
					EndIf;
					
					IndexOf = PaymentData.DivisionScheduleDay.IndexOf(Interval);
					RowsCount = PaymentData.DivisionScheduleDay.Count();
				EndIf;
				
				IndexOf = IndexOf + 1;
				Interval = PaymentData.DivisionScheduleDay[IndexOf];
				If Not Interval.ThisIsIndex
					And StartOfPlacement <= Interval.Begin Then
					Return Interval;
				EndIf;
			EndDo;
		EndIf;
	Else
		CalculationParameters.DivisionDate.Department = Department;
		CalculationParameters.DivisionDate.Date = ?(StartOfPlacement = BegOfDay(StartOfPlacement),
			StartOfPlacement - 86400,
			BegOfDay(StartOfPlacement));
		
		FoundRows = PaymentData.DivisionScheduleDay.FindRows(CalculationParameters.DivisionDate);
		If FoundRows.Count() = 0 Then
			Return Undefined;
		ElsIf Not FoundRows[FoundRows.UBound()].ThisIsIndex
			And StartOfPlacement >= FoundRows[FoundRows.UBound()].Ending Then
			Return FoundRows[FoundRows.UBound()];
		Else
			Interval = FoundRows[FoundRows.UBound()];
			IndexOf = PaymentData.DivisionScheduleDay.IndexOf(Interval);
			While IndexOf > 0 Do
				IndexOf = IndexOf - 1;
				Interval = PaymentData.DivisionScheduleDay[IndexOf];
				If Interval.Department <> Department Then
					Return Undefined;
				ElsIf Not Interval.ThisIsIndex
					And StartOfPlacement >= Interval.Ending Then
					Return Interval;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

Function InitialIntervalOfDivisionInSeconds(PaymentData, CalculationParameters, Department, StartOfPlacement, ToGoBackToBeginning)
	
	If ToGoBackToBeginning Then
		CalculationParameters.DivisionDate.Department = Department;
		CalculationParameters.DivisionDate.Date = BegOfDay(StartOfPlacement);
		
		FoundRows = PaymentData.SecundaDivisionSchedule.FindRows(CalculationParameters.DivisionDate);
		If FoundRows.Count() = 0 Then
			FoundRows = ReadFullAvailabilityAndFindInterval(
				PaymentData, CalculationParameters, Department, "SecundaDivisionSchedule", CalculationParameters.DivisionDate, StartOfPlacement);
			If FoundRows = Undefined
				Or FoundRows.Count() = 0 Then
				Return Undefined;
			EndIf;
		EndIf;
		
		If Not FoundRows[0].ThisIsIndex
			And StartOfPlacement < FoundRows[0].Ending Then
			Return FoundRows[0];
		Else
			Interval = FoundRows[0];
			IndexOf = PaymentData.SecundaDivisionSchedule.IndexOf(Interval);
			RowsCount = PaymentData.SecundaDivisionSchedule.Count();
			While IndexOf < RowsCount Do
				// Read More Accessibility
				If IndexOf = RowsCount - 1
					Or PaymentData.SecundaDivisionSchedule[IndexOf + 1].Department <> Department Then
					ThereAreRecords = ReadMoreAccessibility(PaymentData, CalculationParameters, Interval, "SecundaDivisionSchedule");
					If Not ThereAreRecords Then
						Return Undefined;
					EndIf;
					
					IndexOf = PaymentData.SecundaDivisionSchedule.IndexOf(Interval);
					RowsCount = PaymentData.SecundaDivisionSchedule.Count();
				EndIf;
				
				IndexOf = IndexOf + 1;
				Interval = PaymentData.SecundaDivisionSchedule[IndexOf];
				If Not Interval.ThisIsIndex
					And StartOfPlacement < Interval.Ending Then
					Return Interval;
				EndIf;
			EndDo;
		EndIf;
	Else
		CalculationParameters.DivisionDate.Department = Department;
		CalculationParameters.DivisionDate.Date = ?(StartOfPlacement = BegOfDay(StartOfPlacement),
			StartOfPlacement,
			EndOfDay(StartOfPlacement) + 1);
		
		FoundRows = PaymentData.SecundaDivisionSchedule.FindRows(CalculationParameters.DivisionDate);
		If FoundRows.Count() = 0 Then
			Return Undefined;
		EndIf;
		
		Interval = FoundRows[0];
		IndexOf = PaymentData.SecundaDivisionSchedule.IndexOf(Interval);
		While IndexOf > 0 Do
			IndexOf = IndexOf - 1;
			Interval = PaymentData.SecundaDivisionSchedule[IndexOf];
			If Interval.Department <> Department Then
				Return Undefined;
			ElsIf Not Interval.ThisIsIndex
				And StartOfPlacement > Interval.Begin Then
				Return Interval;
			EndIf;
		EndDo;
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region PlanningByTypeOfRC

Procedure PlaceStageByTypeOfRC(PaymentData, CalculationParameters, Stage)
	
	// Offset per buffer to
	If ValueIsFilled(Stage.BufferUpTo) Then
		If Stage.BufferUpToPostInDays Then
			Stage2_ = PlaceDivisionsAccordingToScheduleInDays(
				PaymentData, CalculationParameters, Stage, Stage.BufferUpTo, Stage.StartOfPlacement, True);
		Else
			Stage2_ = PlaceUnitsAccordingToScheduleInSeconds(
				PaymentData, CalculationParameters, Stage, Stage.BufferUpTo, Stage.StartOfPlacement, True);
		EndIf;
		If Not Stage2_ Then
			Return;
		EndIf;
		Stage.StartOfPlacement = CalculationParameters.BeginningEnding.Ending;
	EndIf;
	
	// VRC planning
	FillPropertyValues(CalculationParameters.KeyLotReferenceStage, Stage, "KeyLot, Stage");
	WorkCenterTypes = PaymentData.TypesOfRC.FindRows(CalculationParameters.KeyLotReferenceStage);
	If WorkCenterTypes.Count() = 1 Then
		Stage2_ = DownloadSingleVRC(PaymentData, CalculationParameters, Stage, WorkCenterTypes[0]);
	ElsIf WorkCenterTypes.Count() > 1
		And (Stage.OrderOfOperationOfTypesOfRC = Enums.OperatingProcedureOfWorkCenterTypes.Sequentially
			Or Stage.OrderOfOperationOfTypesOfRC = Enums.OperatingProcedureOfWorkCenterTypes.Independently) Then
		If TypeOf(Stage.Stage) = Type("CatalogRef.ProductionStages") Then
			NotificationText1 = StrTemplate(NStr("vi = 'Trong bảng kê chi tiết các nguồn lực sản xuất ""%1"" sử dụng trình tự làm việc của dạng NLSX ""%2"". Trong cấu trúc động của đơn hàng, hỗ trợ chỉ việc kết nhập đồng thời dạng NLSX.';
												|ru = 'В спецификации ""%1"" используется порядок работы видов РЦ ""%2"". В динамической структуре заказа поддерживается только одновременная загрузка видов РЦ.';
												|en = 'In the ""%1"" bill of materials, the ""%2"" operating procedure of work center types is used. The dynamic order structure supports only simultaneous load of work center types.'; fa = 'In the ""%1"" bill of materials, the ""%2"" operating procedure of work center types is used. The dynamic order structure supports only simultaneous load of work center types.';
												|it = 'В спецификации ""%1"" используется порядок работы видов РЦ ""%2"". В динамической структуре заказа поддерживается только одновременная загрузка видов РЦ.';
												|pl = 'In the ""%1"" bill of materials, the ""%2"" operating procedure of work center types is used. The dynamic order structure supports only simultaneous load of work center types.';
												|tr = 'В спецификации ""%1"" используется порядок работы видов РЦ ""%2"". В динамической структуре заказа поддерживается только одновременная загрузка видов РЦ.'"),
				Stage.BillOfMaterials,
				Stage.OrderOfOperationOfTypesOfRC);
			CalculationParameters.Notifications.Insert(NotificationText1, Stage.BillOfMaterials);
		Else
			NotificationText1 = StrTemplate(NStr("vi = 'Trong chứng từ %1 sử dụng trình tự làm việc của dạng NLSX ""%2"". Trong cấu trúc động của đơn hàng, hỗ trợ chỉ việc kết nhập đồng thời dạng NLSX.';
												|ru = 'В документе %1 используется порядок работы видов РЦ ""%2"". В динамической структуре заказа поддерживается только одновременная загрузка видов РЦ.';
												|en = 'In the ""%1"" document, the ""%2"" operating procedure of work center types is used. The dynamic order structure supports only simultaneous load of work center types.'; fa = 'In the ""%1"" document, the ""%2"" operating procedure of work center types is used. The dynamic order structure supports only simultaneous load of work center types.';
												|it = 'В документе %1 используется порядок работы видов РЦ ""%2"". В динамической структуре заказа поддерживается только одновременная загрузка видов РЦ.';
												|pl = 'In the ""%1"" document, the ""%2"" operating procedure of work center types is used. The dynamic order structure supports only simultaneous load of work center types.';
												|tr = 'В документе %1 используется порядок работы видов РЦ ""%2"". В динамической структуре заказа поддерживается только одновременная загрузка видов РЦ.'"),
				Stage.Stage,
				Stage.OrderOfOperationOfTypesOfRC);
			CalculationParameters.Notifications.Insert(NotificationText1, Stage.Stage);
		EndIf;
		
		Stage2_ = DownloadSingleVRC(PaymentData, CalculationParameters, Stage, WorkCenterTypes[0]);
	Else
		Stage2_ = UploadVRCGroup(PaymentData, CalculationParameters, Stage, WorkCenterTypes);
	EndIf;
	
	If Not Stage2_ Then
		Return;
	EndIf;
	
	// Placing the buffer before
	If ValueIsFilled(Stage.BufferUpTo) Then
		If Stage.BufferUpToPostInDays Then
			Stage2_ = PlaceDivisionsAccordingToScheduleInDays(
				PaymentData, CalculationParameters, Stage, Stage.BufferUpTo, Stage.PreliminaryBufferEnd, False);
		Else
			Stage2_ = PlaceUnitsAccordingToScheduleInSeconds(
				PaymentData, CalculationParameters, Stage, Stage.BufferUpTo, Stage.PreliminaryBufferEnd, False);
		EndIf;
		If Not Stage2_ Then
			Return;
		EndIf;
		
		Stage.Begin = CalculationParameters.BeginningEnding.Begin;
	Else
		Stage.Begin = Stage.PreliminaryBufferEnd;
	EndIf;
	
	// Placing the buffer after
	If ValueIsFilled(Stage.BufferAfter) Then
		If Stage.BufferAfterPlacingInDays Then
			Stage2_ = PlaceDivisionsAccordingToScheduleInDays(
				PaymentData, CalculationParameters, Stage, Stage.BufferAfter, Stage.FollowUpBufferStart, True);
		Else
			Stage2_ = PlaceUnitsAccordingToScheduleInSeconds(
				PaymentData, CalculationParameters, Stage, Stage.BufferAfter, Stage.FollowUpBufferStart, True);
		EndIf;
		If Not Stage2_ Then
			Return;
		EndIf;
		
		Stage.Ending = CalculationParameters.BeginningEnding.Ending - 1;
	Else
		Stage.Ending = Stage.FollowUpBufferStart - 1;
	EndIf;
	
	Stage.ScheduleIsChanged = Stage.StartBeforeChange <> Stage.Begin
		Or Stage.EndingBeforeChange <> Stage.Ending;
	
EndProcedure

Function DownloadSingleVRC(PaymentData, CalculationParameters, Stage, RCView)
	
	PlacementInterval = InitialVRCPlacementInterval(PaymentData, CalculationParameters, Stage, RCView);
	If PlacementInterval = Undefined Then
		HandleErrorVRCAvailabilityWasNotFound(CalculationParameters, Stage, RCView);
		Return False;
	EndIf;
	
	ItRemainsToPlace = RCView.LoadingTime;
	Begin = '00010101';
	Ending = '00010101';
	NumberOfIntervals_ = 0;
	
	While True Do
		LoadingTime = Min(ItRemainsToPlace,
			PlacementInterval.MaximumLoadingTime, PlacementInterval.AvailableLoadingTime);
		
		If PlacementInterval.StartOfRange < CalculationParameters.CurrentDate
			And PlacementInterval.EndOfTheInterval > CalculationParameters.CurrentDate Then
			LoadingTime = Min(LoadingTime,
				?(Not RCView.ParallelLoad,
					PlacementInterval.EndOfTheInterval - CalculationParameters.CurrentDate,
					(PlacementInterval.EndOfTheInterval - CalculationParameters.CurrentDate) * RCView.MaximumLoad));
		EndIf;
		
		NewRow = PaymentData.LoadingVRC.Add();
		NewRow.ReferenceOrder = Stage.ProductionOrder;
		FillPropertyValues(NewRow, Stage, "Stage, KeyLot, Department");
		FillPropertyValues(NewRow, PlacementInterval, "WorkCenterType, IntervalDate, Shift");
		
		NewRow.BusyLoadingTime = LoadingTime;
		If Not RCView.ParallelLoad Then
			NewRow.Busy = LoadingTime;
		Else
			NewRow.Busy = ?(LoadingTime = PlacementInterval.AvailableLoadingTime,
				PlacementInterval.Available_Time,
				Round(LoadingTime / RCView.MaximumLoad));
		EndIf;
		
		NewRow.Interval = PlacementInterval;
		NumberOfIntervals_ = NumberOfIntervals_ + 1;
		
		PlacementInterval.AvailableLoadingTime = PlacementInterval.AvailableLoadingTime - NewRow.BusyLoadingTime;
		PlacementInterval.Available_Time = PlacementInterval.Available_Time - NewRow.Busy;
		
		ItRemainsToPlace = ItRemainsToPlace - LoadingTime;
		If Begin = '00010101' Then
			Begin = PlacementInterval.StartOfRange;
		EndIf;
		
		If ItRemainsToPlace = 0 Then
			Ending = PlacementInterval.EndOfTheInterval;
			Break;
		EndIf;
		
		// Selection of the next interval
		IndexOf = PaymentData.WCKAvailability.IndexOf(PlacementInterval);
		RowsCount = PaymentData.WCKAvailability.Count();
		While IndexOf < RowsCount Do
			// Read More Accessibility
			If IndexOf = RowsCount - 1
				Or PaymentData.WCKAvailability[IndexOf + 1].WorkCenterType <> RCView.WorkCenterType Then
				ThereAreRecords = ReadMoreAccessibility(PaymentData, CalculationParameters, PlacementInterval, "WCKAvailability");
				If Not ThereAreRecords Then
					HandleErrorVRCAvailabilityWasNotFound(CalculationParameters, Stage, RCView);
					Return False;
				EndIf;
				
				IndexOf = PaymentData.WCKAvailability.IndexOf(PlacementInterval);
				RowsCount = PaymentData.WCKAvailability.Count();
			EndIf;
			
			IndexOf = IndexOf + 1;
			PlacementInterval = PaymentData.WCKAvailability[IndexOf];
			If PlacementInterval.AvailableLoadingTime > 0 Then
				Break;
			ElsIf Not PlacementInterval.ThisIsIndex And Stage.Continuous_ Then
				// Rollback placement
				For Counter = 1 To NumberOfIntervals_ Do
					LoadingLine = PaymentData.LoadingVRC[PaymentData.LoadingVRC.Count()-1];
					LoadingLine.Interval.AvailableLoadingTime = LoadingLine.Interval.AvailableLoadingTime + LoadingLine.BusyLoadingTime;
					LoadingLine.Interval.Available_Time = LoadingLine.Interval.Available_Time + LoadingLine.Busy;
					PaymentData.LoadingVRC.Delete(LoadingLine);
				EndDo;
				
				Stage.EquipmentLimited = True;
				
				ItRemainsToPlace = RCView.LoadingTime;
				Begin = '00010101';
				NumberOfIntervals_ = 0;
			EndIf;
		EndDo;
	EndDo;
	
	Stage.PreliminaryBufferEnd = Begin;
	Stage.FollowUpBufferStart = Ending;
	
	Return True;
	
EndFunction

Function UploadVRCGroup(PaymentData, CalculationParameters, Stage, WorkCenterTypes)
	
	RCView = WorkCenterTypes[0];
	
	PlacementInterval = InitialVRCPlacementInterval(PaymentData, CalculationParameters, Stage, RCView);
	If PlacementInterval = Undefined Then
		HandleErrorVRCAvailabilityWasNotFound(CalculationParameters, Stage, RCView);
		Return False;
	EndIf;
	
	ItRemainsToPlace = RCView.LoadingTime;
	Begin = '00010101';
	Ending = '00010101';
	NumberOfIntervals_ = 0;
	
	Intervals = New Array;
	VRCSearch = New Structure("ThisIsIndex, WorkCenterType, IntervalDate", False);
	
	While True Do
		Intervals.Add(PlacementInterval);
		LoadingTime = Min(ItRemainsToPlace,
			PlacementInterval.MaximumLoadingTime, PlacementInterval.AvailableLoadingTime);
		
		// Selection of intervals of additional types of RC
		While Intervals.Count() <> WorkCenterTypes.Count() Do
			For IndexTypesOfRC = 1 To WorkCenterTypes.Count()-1 Do
				AdditionalTypeOfRC = WorkCenterTypes[IndexTypesOfRC];
				
				VRCSearch.WorkCenterType = AdditionalTypeOfRC.WorkCenterType;
				VRCSearch.IntervalDate = PlacementInterval.IntervalDate;
				FoundRows = PaymentData.WCKAvailability.FindRows(VRCSearch);
				
				If FoundRows.Count() > 0
					And FoundRows[0].AvailableLoadingTime > 0 Then
					// The interval of the additional view is found and available
					LoadingTime = Min(LoadingTime,
						FoundRows[0].MaximumLoadingTime, FoundRows[0].AvailableLoadingTime);
					Intervals.Add(FoundRows[0]);
				Else
					// Additional view interval not found or unavailable
					If Stage.Continuous_ Then
						// Rollback placement
						For Counter = 1 To NumberOfIntervals_ Do
							LoadingLine = PaymentData.LoadingVRC[PaymentData.LoadingVRC.Count()-1];
							LoadingLine.Interval.AvailableLoadingTime = LoadingLine.Interval.AvailableLoadingTime + LoadingLine.BusyLoadingTime;
							LoadingLine.Interval.Available_Time = LoadingLine.Interval.Available_Time + LoadingLine.Busy;
							PaymentData.LoadingVRC.Delete(LoadingLine);
						EndDo;
						
						Stage.EquipmentLimited = True;
						
						ItRemainsToPlace = RCView.LoadingTime;
						Begin = '00010101';
						NumberOfIntervals_ = 0;
					ElsIf ItRemainsToPlace = RCView.LoadingTime Then
						Stage.EquipmentLimited = True;
					EndIf;
					
					// Search for a new interval of the main type of RC
					IndexOf = PaymentData.WCKAvailability.IndexOf(PlacementInterval);
					RowsCount = PaymentData.WCKAvailability.Count();
					While IndexOf < RowsCount Do
						// Read More Accessibility
						If IndexOf = RowsCount - 1
							Or PaymentData.WCKAvailability[IndexOf + 1].WorkCenterType <> RCView.WorkCenterType Then
							ThereAreRecords = ReadMoreAccessibility(PaymentData, CalculationParameters, PlacementInterval, "WCKAvailability");
							If Not ThereAreRecords Then
								HandleErrorVRCAvailabilityWasNotFound(CalculationParameters, Stage, RCView);
								Return False;
							EndIf;
							
							IndexOf = PaymentData.WCKAvailability.IndexOf(PlacementInterval);
							RowsCount = PaymentData.WCKAvailability.Count();
						EndIf;
						
						IndexOf = IndexOf + 1;
						PlacementInterval = PaymentData.WCKAvailability[IndexOf];
						If PlacementInterval.AvailableLoadingTime > 0 Then
							Break;
						EndIf;
					EndDo;
					
					Intervals.Clear();
					Intervals.Add(PlacementInterval);
					
					LoadingTime = Min(ItRemainsToPlace,
						PlacementInterval.MaximumLoadingTime, PlacementInterval.AvailableLoadingTime);
					
					Break;
				EndIf;
			EndDo;
		EndDo;
		
		For IndexOf = 0 To WorkCenterTypes.Count()-1 Do
			CurrentRCView = WorkCenterTypes[IndexOf];
			Interval = Intervals[IndexOf];
			
			NewRow = PaymentData.LoadingVRC.Add();
			NewRow.ReferenceOrder = Stage.ProductionOrder;
			FillPropertyValues(NewRow, Stage, "Stage, KeyLot, Department");
			FillPropertyValues(NewRow, Interval, "WorkCenterType, IntervalDate, Shift");
			
			NewRow.BusyLoadingTime = LoadingTime;
			If Not CurrentRCView.ParallelLoad Then
				NewRow.Busy = LoadingTime;
			Else
				NewRow.Busy = ?(LoadingTime = Interval.AvailableLoadingTime,
					Interval.Available_Time,
					Round(LoadingTime / CurrentRCView.MaximumLoad));
			EndIf;
			
			NewRow.Interval = Interval;
			NumberOfIntervals_ = NumberOfIntervals_ + 1;
			
			Interval.AvailableLoadingTime = Interval.AvailableLoadingTime - NewRow.BusyLoadingTime;
			Interval.Available_Time = Interval.Available_Time - NewRow.Busy;
		EndDo;
		Intervals.Clear();
		
		ItRemainsToPlace = ItRemainsToPlace - LoadingTime;
		If Begin = '00010101' Then
			Begin = PlacementInterval.StartOfRange;
		EndIf;
		
		If ItRemainsToPlace = 0 Then
			Ending = PlacementInterval.EndOfTheInterval;
			Break;
		EndIf;
		
		// Selection of the next interval
		IndexOf = PaymentData.WCKAvailability.IndexOf(PlacementInterval);
		RowsCount = PaymentData.WCKAvailability.Count();
		While IndexOf < RowsCount Do
			// Read More Accessibility
			If IndexOf = RowsCount - 1
				Or PaymentData.WCKAvailability[IndexOf + 1].WorkCenterType <> RCView.WorkCenterType Then
				ThereAreRecords = ReadMoreAccessibility(PaymentData, CalculationParameters, PlacementInterval, "WCKAvailability");
				If Not ThereAreRecords Then
					HandleErrorVRCAvailabilityWasNotFound(CalculationParameters, Stage, RCView);
					Return False;
				EndIf;
				
				IndexOf = PaymentData.WCKAvailability.IndexOf(PlacementInterval);
				RowsCount = PaymentData.WCKAvailability.Count();
			EndIf;
			
			IndexOf = IndexOf + 1;
			PlacementInterval = PaymentData.WCKAvailability[IndexOf];
			If PlacementInterval.AvailableLoadingTime > 0 Then
				Break;
			ElsIf Not PlacementInterval.ThisIsIndex And Stage.Continuous_ Then
				// Rollback placement
				For Counter = 1 To NumberOfIntervals_ Do
					LoadingLine = PaymentData.LoadingVRC[PaymentData.LoadingVRC.Count()-1];
					LoadingLine.Interval.AvailableLoadingTime = LoadingLine.Interval.AvailableLoadingTime + LoadingLine.BusyLoadingTime;
					LoadingLine.Interval.Available_Time = LoadingLine.Interval.Available_Time + LoadingLine.Busy;
					PaymentData.LoadingVRC.Delete(LoadingLine);
				EndDo;
				
				Stage.EquipmentLimited = True;
				
				ItRemainsToPlace = RCView.LoadingTime;
				Begin = '00010101';
				NumberOfIntervals_ = 0;
			EndIf;
		EndDo;
	EndDo;
	
	Stage.PreliminaryBufferEnd = Begin;
	Stage.FollowUpBufferStart = Ending;
	
	Return True;
	
EndFunction

Function InitialVRCPlacementInterval(PaymentData, CalculationParameters, Stage, RCView)
	
	CalculationParameters.VRCSearch.WorkCenterType = RCView.WorkCenterType;
	If RCView.PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		CalculationParameters.VRCSearch.IntervalDate = BegOfWeek(Stage.StartOfPlacement);
	ElsIf RCView.PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		CalculationParameters.VRCSearch.IntervalDate = BegOfMonth(Stage.StartOfPlacement);
	Else
		CalculationParameters.VRCSearch.IntervalDate = BegOfDay(Stage.StartOfPlacement);
	EndIf;
	
	FoundRows = PaymentData.WCKAvailability.FindRows(CalculationParameters.VRCSearch);
	
	If FoundRows.Count() = 0 Then
		FoundRows = ReadFullAvailabilityAndFindInterval(
			PaymentData, CalculationParameters, RCView.WorkCenterType, "WCKAvailability", CalculationParameters.VRCSearch, CalculationParameters.VRCSearch.IntervalDate);
		If FoundRows = Undefined
			Or FoundRows.Count() = 0 Then
			Return Undefined;
		EndIf;
	EndIf;
	
	Interval = FoundRows[0];
	IndexOf = PaymentData.WCKAvailability.IndexOf(Interval);
	RowsCount = PaymentData.WCKAvailability.Count();
	While IndexOf < RowsCount Do
		// Read More Accessibility
		If IndexOf = RowsCount - 1
			Or PaymentData.WCKAvailability[IndexOf + 1].WorkCenterType <> RCView.WorkCenterType Then
			ThereAreRecords = ReadMoreAccessibility(PaymentData, CalculationParameters, Interval, "WCKAvailability");
			If Not ThereAreRecords Then
				Return Undefined;
			EndIf;
			
			IndexOf = PaymentData.WCKAvailability.IndexOf(Interval);
			RowsCount = PaymentData.WCKAvailability.Count();
		EndIf;
		
		IndexOf = IndexOf + 1;
		Interval = PaymentData.WCKAvailability[IndexOf];
		If Interval.ThisIsIndex
			Or Interval.StartOfRange < Stage.StartOfPlacement And Stage.StartOfPlacement <> CalculationParameters.CurrentDate
			Or Interval.EndOfTheInterval <= Stage.StartOfPlacement Then
			Continue;
		ElsIf Interval.AvailableLoadingTime <= 0 Then
			Stage.EquipmentLimited = True;
			Continue;
		Else
			Return Interval;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Errors

Procedure HandleDivisionIntervalNotFoundError(CalculationParameters, Stage, Date, ToGoBackToBeginning)
	
	LongDesc = "";
	Details = New Structure;
	Var_Key = Undefined;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("ScheduleStatus", CalculationParameters.ScheduleStatus);
	
	If Stage.ItIsTransfer Then
		Var_Key = "EnterpriseSchedule";
		
		TheStructureOfTheSearch.Insert("Key", Var_Key);
		FoundRows = CalculationParameters.Errors.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() <> 0 Then
			Return;
		EndIf;
		
		Details.Insert("ErrorCode",
			DataProcessors.ProductionSchedulePlanning2_2.ErrorCodeBusinessHours());
		
		Cause = ?(ToGoBackToBeginning,
			StrTemplate(NStr("vi = 'chưa xác định lịch biểu làm việc của doanh nghiệp hoặc chưa điền dữ liệu của lịch biểu sau %1';
							|ru = 'не определен график работы предприятия или данные графика не заполнены после %1';
							|en = 'enterprise schedule is not specified or schedule data is not filled in after %1'; fa = 'enterprise schedule is not specified or schedule data is not filled in after %1';
							|it = 'не определен график работы предприятия или данные графика не заполнены после %1';
							|pl = 'enterprise schedule is not specified or schedule data is not filled in after %1';
							|tr = 'не определен график работы предприятия или данные графика не заполнены после %1'"),
				Format(Date, "DLF=D;")),
			StrTemplate(NStr("vi = 'chưa xác định lịch biểu làm việc của doanh nghiệp hoặc chưa điền dữ liệu của lịch biểu trước đó%1';
							|ru = 'не определен график работы предприятия или данные графика не заполнены ранее %1';
							|en = 'enterprise schedule is not specified or schedule data is not filled in before %1'; fa = 'enterprise schedule is not specified or schedule data is not filled in before %1';
							|it = 'не определен график работы предприятия или данные графика не заполнены ранее %1';
							|pl = 'enterprise schedule is not specified or schedule data is not filled in before %1';
							|tr = 'не определен график работы предприятия или данные графика не заполнены ранее %1'"),
				Format(Date, "DLF=D;")));
		
		If CalculationParameters.ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel() Then
			LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi lập kế hoạch mô hình, chưa đặt điều chuyển do: %1.';
					|ru = 'При планировании модели не размещено перемещение по причине: %1.';
					|en = 'When planning the model, the transfer is not placed. Reason: %1.'; fa = 'When planning the model, the transfer is not placed. Reason: %1.';
					|it = 'При планировании модели не размещено перемещение по причине: %1.';
					|pl = 'When planning the model, the transfer is not placed. Reason: %1.';
					|tr = 'При планировании модели не размещено перемещение по причине: %1.'"),
				Cause);
		Else
			LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi lập kế hoạch mô hình, chưa đặt điều chuyển do: %1.';
					|ru = 'При планировании графика не размещено перемещение по причине: %1.';
					|en = 'When planning the schedule, the transfer is not placed. Reason: %1.'; fa = 'When planning the schedule, the transfer is not placed. Reason: %1.';
					|it = 'При планировании графика не размещено перемещение по причине: %1.';
					|pl = 'When planning the schedule, the transfer is not placed. Reason: %1.';
					|tr = 'При планировании графика не размещено перемещение по причине: %1.'"),
				Cause);
		EndIf;
	Else
		Var_Key = Stage.Department;
		
		TheStructureOfTheSearch.Insert("Key", Var_Key);
		FoundRows = CalculationParameters.Errors.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() <> 0 Then
			Return;
		EndIf;
		
		Details.Insert("ErrorCode",
			DataProcessors.ProductionSchedulePlanning2_2.ErrorCodeDivisionSchedule());
		Details.Insert("Department", Stage.Department);
		
		Cause = ?(ToGoBackToBeginning,
			StrTemplate(NStr("vi = 'Chưa xác định lịch làm việc của bộ phận ""%1"" hoặc chưa điền dữ liệu lịch biểu sau %2';
							|ru = 'не определен график работы подразделения ""%1"" или данные графика не заполнены после %2';
							|en = 'the work schedule of the ""%1"" business unit is not determined, or the schedule data is not filled after %2'; fa = 'the work schedule of the ""%1"" business unit is not determined, or the schedule data is not filled after %2';
							|it = 'не определен график работы подразделения ""%1"" или данные графика не заполнены после %2';
							|pl = 'the work schedule of the ""%1"" business unit is not determined, or the schedule data is not filled after %2';
							|tr = '""%1"" departmanının çalışma takvimi tanımlanmadı veya %2 sonrasında takvim verileri doldurulmadı.'"),
				Stage.Department, Format(Date, "DLF=D;")),
			StrTemplate(NStr("vi = 'Chưa xác định lịch làm việc của bộ phận ""%1"" hoặc chưa điền dữ liệu lịch biểu trước %2';
							|ru = 'не определен график работы подразделения ""%1"" или данные графика не заполнены ранее %2';
							|en = 'the work schedule of the ""%1"" business unit is not determined, or the schedule data is not filled before %2'; fa = 'the work schedule of the ""%1"" business unit is not determined, or the schedule data is not filled before %2';
							|it = 'не определен график работы подразделения ""%1"" или данные графика не заполнены ранее %2';
							|pl = 'the work schedule of the ""%1"" business unit is not determined, or the schedule data is not filled before %2';
							|tr = '""%1"" departmanının çalışma takvimi tanımlanmadı veya %2 öncesinde takvim verileri doldurulmadı'"),
				Stage.Department, Format(Date, "DLF=D;")));
		
		PresentationStage = ?(TypeOf(Stage.Stage) = Type("DocumentRef.ProductionStage2_2"),
			Documents.ProductionStage2_2.PresentationStage(Stage.Stage),
			Common.ObjectAttributeValue(Stage.Stage, "Description"));
		
		If CalculationParameters.ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel() Then
			LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi lập kế hoạch mô hình, chưa đặt công đoạn ""%1"" do: %2.';
					|ru = 'При планировании модели не размещен этап ""%1"" по причине: %2.';
					|en = 'When planning the model, the ""%1"" stage is not placed. Reason: %1.'; fa = 'When planning the model, the ""%1"" stage is not placed. Reason: %1.';
					|it = 'При планировании модели не размещен этап ""%1"" по причине: %2.';
					|pl = 'When planning the model, the ""%1"" stage is not placed. Reason: %1.';
					|tr = 'При планировании модели не размещен этап ""%1"" по причине: %2.'"),
				PresentationStage,
				Cause);
		Else
			LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi lập kế hoạch lịch biểu, chưa đặt công đoạn ""%1"" do: %2.';
					|ru = 'При планировании графика не размещен этап ""%1"" по причине: %2.';
					|en = 'When planning the schedule, the ""%1"" stage is not placed. Reason: %1.'; fa = 'When planning the schedule, the ""%1"" stage is not placed. Reason: %1.';
					|it = 'При планировании графика не размещен этап ""%1"" по причине: %2.';
					|pl = 'When planning the schedule, the ""%1"" stage is not placed. Reason: %1.';
					|tr = 'При планировании графика не размещен этап ""%1"" по причине: %2.'"),
				PresentationStage,
				Cause);
		EndIf;
	EndIf;
	
	NewRow = CalculationParameters.Errors.Add(); //ValueTableRow
	NewRow.LongDesc = LongDesc;
	NewRow.Details = Details;
	NewRow.Key = Var_Key;
	NewRow.ScheduleStatus = CalculationParameters.ScheduleStatus;
	
EndProcedure

Procedure HandleErrorVRCAvailabilityWasNotFound(CalculationParameters, Stage, RCView)
	
	Var_Key = RCView.WorkCenterType;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("ScheduleStatus", CalculationParameters.ScheduleStatus);
	TheStructureOfTheSearch.Insert("Key", Var_Key);
	FoundRows = CalculationParameters.Errors.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() <> 0 Then
		Return;
	EndIf;
	
	Details = New Structure;
	Details.Insert("ErrorCode", DataProcessors.ProductionSchedulePlanning2_2.ErrorCodeVRCAvailability());
	Details.Insert("ProductionStage", Stage.Stage);
	Details.Insert("Department", Stage.Department);
	Details.Insert("Period", Stage.StartOfPlacement);
	Details.Insert("WorkCenterType", RCView.WorkCenterType);
	
	Cause = StrTemplate(
		NStr("vi = 'không đủ thời gian được phép của dạng NLSX ""%1"" sau %2';
			|ru = 'недостаточно доступного времени вида РЦ ""%1"" после %2';
			|en = 'insufficient available time of the ""%1"" work center type after %2'; fa = 'insufficient available time of the ""%1"" work center type after %2';
			|it = 'недостаточно доступного времени вида РЦ ""%1"" после %2';
			|pl = 'insufficient available time of the ""%1"" work center type after %2';
			|tr = 'недостаточно доступного времени вида РЦ ""%1"" после %2'"),
		RCView.WorkCenterType,
		Format(Stage.StartOfPlacement, "DLF=D;"));
	
	PresentationStage = ?(TypeOf(Stage.Stage) = Type("DocumentRef.ProductionStage2_2"),
		Documents.ProductionStage2_2.PresentationStage(Stage.Stage),
		Common.ObjectAttributeValue(Stage.Stage, "Description"));
	
	LongDesc = "";
	If CalculationParameters.ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel() Then
		LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi lập kế hoạch mô hình, chưa đặt công đoạn ""%1"" do: %2.';
				|ru = 'При планировании модели не размещен этап ""%1"" по причине: %2.';
				|en = 'When planning the model, the ""%1"" stage is not placed. Reason: %1.'; fa = 'When planning the model, the ""%1"" stage is not placed. Reason: %1.';
				|it = 'При планировании модели не размещен этап ""%1"" по причине: %2.';
				|pl = 'When planning the model, the ""%1"" stage is not placed. Reason: %1.';
				|tr = 'При планировании модели не размещен этап ""%1"" по причине: %2.'"),
			PresentationStage,
			Cause);
	Else
		LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi lập kế hoạch lịch biểu, chưa đặt công đoạn ""%1"" do: %2.';
				|ru = 'При планировании графика не размещен этап ""%1"" по причине: %2.';
				|en = 'When planning the schedule, the ""%1"" stage is not placed. Reason: %1.'; fa = 'When planning the schedule, the ""%1"" stage is not placed. Reason: %1.';
				|it = 'При планировании графика не размещен этап ""%1"" по причине: %2.';
				|pl = 'When planning the schedule, the ""%1"" stage is not placed. Reason: %1.';
				|tr = 'При планировании графика не размещен этап ""%1"" по причине: %2.'"),
			PresentationStage,
			Cause);
	EndIf;
	
	NewRow = CalculationParameters.Errors.Add(); //ValueTableRow
	NewRow.LongDesc = LongDesc;
	NewRow.Details = Details;
	NewRow.Key = Var_Key;
	NewRow.ScheduleStatus = CalculationParameters.ScheduleStatus;
	
EndProcedure

#EndRegion

#Region Other

Function NewCalculationParameters(Settings = Undefined)
	
	CalculationParameters = New Structure;
	
	CalculationParameters.Insert("ScheduleStatus", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	CalculationParameters.Insert("UseAvailabilityReserve", Undefined);
	CalculationParameters.Insert("AllMaterialsInStock", False);
	CalculationParameters.Insert("UnlimitedEquipmentFleet", False);
	CalculationParameters.Insert("RoundTheClockWorkSevenDaysAWeek", False);
	CalculationParameters.Insert("NoOtherOrders", False);
	CalculationParameters.Insert("CancelManualChangesOfSchedule", False);
	If TypeOf(Settings) = Type("Structure") Then
		FillPropertyValues(CalculationParameters, Settings);
	EndIf;
	
	If CalculationParameters.ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule() Then
		CalculationParameters.AllMaterialsInStock = False;
		CalculationParameters.UnlimitedEquipmentFleet = False;
		CalculationParameters.RoundTheClockWorkSevenDaysAWeek = False;
		CalculationParameters.NoOtherOrders = False;
	Else
		CalculationParameters.CancelManualChangesOfSchedule = False;
	EndIf;
	
	CalculationParameters.Insert("OrderDocument", Undefined);
	CalculationParameters.Insert("CurrentDate", CurrentSessionDate());
	
	Errors = New ValueTable();
	Errors.Columns.Add("LongDesc", New TypeDescription("String"));
	Errors.Columns.Add("Details");
	Errors.Columns.Add("Key");
	Errors.Columns.Add("ScheduleStatus", New TypeDescription("Number"));
	CalculationParameters.Insert("Errors", Errors);
	
	CalculationParameters.Insert("Notifications", New Map);
	
	// Structures to search for
	BeginningEnding = New Structure("Begin, Ending", '00010101', '00010101');
	CalculationParameters.Insert("BeginningEnding", BeginningEnding);
	
	KeyLotReferenceStage = New Structure("KeyLot, Stage");
	CalculationParameters.Insert("KeyLotReferenceStage", KeyLotReferenceStage);
	
	DivisionDate = New Structure("Department, Date");
	CalculationParameters.Insert("DivisionDate", DivisionDate);
	
	VRCSearch = New Structure("ThisIsIndex, WorkCenterType, IntervalDate", True);
	CalculationParameters.Insert("VRCSearch", VRCSearch);
	
	// Read Availability Options
	CalculationParameters.Insert("AvailabilitySelectionBoundary", '00010101');
	CalculationParameters.Insert("AvailabilityUnitSelection", New Array);
	CalculationParameters.Insert("AvailabilityVRCSelection", New Array);
	//  Availability is reduced by loading previously launched Lot references of the Cur order
	//  (used when calculating the launched stages)
	CalculationParameters.Insert("AvailabilityTakeIntoAccountLoadingOfRunningLotReferences", False);
	//  Parameters that allow you to redefine the primary availability sampling interval
	CalculationParameters.Insert("AvailabilityIntervalStart", '00010101');
	CalculationParameters.Insert("AvailabilityIntervalEnding", '00010101');
	
	Return CalculationParameters;
	
EndFunction

Function NewCalculationData()
	
	PaymentData = New Structure;
	
	OrderDetails = New Structure;
	OrderDetails.Insert("ThisIsBuild", True);
	OrderDetails.Insert("ThisIsRepair", False);
	OrderDetails.Insert("EarliestStartDate", '00010101');
	OrderDetails.Insert("DemandDate", '00010101');
	OrderDetails.Insert("DateDifferenceInMonths", 0);
	PaymentData.Insert("OrderDetails", OrderDetails);
	
	PaymentData.Insert("Stages", Undefined);
	PaymentData.Insert("Links", Undefined);
	PaymentData.Insert("RepairLinks", Undefined);
	PaymentData.Insert("TypesOfRC", Undefined);
	PaymentData.Insert("DivisionScheduleDay", New ValueTable);
	PaymentData.Insert("SecundaDivisionSchedule", New ValueTable);
	PaymentData.Insert("WCKAvailability", New ValueTable);
	PaymentData.Insert("AvailabilityLimits", New ValueTable);
	PaymentData.Insert("Jobs", Undefined);
	PaymentData.Insert("StagesWithManualPlacement", Undefined);
	
	LoadingVRC = New ValueTable;
	LoadingVRC.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	LoadingVRC.Columns.Add("IntervalDate", New TypeDescription("Date"));
	LoadingVRC.Columns.Add("Busy", New TypeDescription("Number")); // Time
	LoadingVRC.Columns.Add("ReferenceOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	LoadingVRC.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	LoadingVRC.Columns.Add("Shift", New TypeDescription("CatalogRef.Calendars"));
	LoadingVRC.Columns.Add("KeyLot", New TypeDescription("UUID"));
	LoadingVRC.Columns.Add("Stage", New TypeDescription("CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2"));
	LoadingVRC.Columns.Add("Interval", New TypeDescription("ValueTableRow"));
	
	// Service field. For regular VRC is identically Busy, for parallel stores data as (Time * Load).
	LoadingVRC.Columns.Add("BusyLoadingTime", New TypeDescription("Number"));
	
	PaymentData.Insert("LoadingVRC", LoadingVRC);
	
	Return PaymentData;
	
EndFunction

Procedure ReadUpdateOrderDetails(OrderDocument, PaymentData, CalculationParameters)
	
	QueryText = QueryTextOrderData("&TextTableName.Ref = &OrderDocument", False);
	
	Query = New Query(QueryText);
	Query.SetParameter("OrderDocument", OrderDocument);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	FillPropertyValues(PaymentData.OrderDetails, Selection);
	
	If CalculationParameters.UseAvailabilityReserve = Undefined Then
		CalculationParameters.UseAvailabilityReserve = Selection.UseAvailabilityReserve;
	ElsIf CalculationParameters.UseAvailabilityReserve <> Selection.UseAvailabilityReserve
		And CalculationParameters.ScheduleStatus <> InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel() Then
		
		DocumentObject = OrderDocument.GetObject();
		Try
			DocumentObject.Lock();
			DocumentObject.UseAvailabilityReserve = CalculationParameters.UseAvailabilityReserve;
			DocumentObject.DataExchange.Load = True;
			DocumentObject.Write(DocumentWriteMode.Write);
			DocumentObject.Unlock();
		Except
			Event = NStr("vi = 'Đơn hàng sản xuất';
						|ru = 'Заказ на производство';
						|en = 'Production order'; fa = 'سفارش تولید';
						|it = 'Ordine di produzione';
						|pl = 'Zlecenie produkcyjne';
						|tr = 'Üretim emri'", Common.DefaultLanguageCode()) + "."
					+ NStr("vi = 'Thay đổi khi tính lịch';
							|ru = 'Изменение при расчете графика';
							|en = 'Change upon schedule calculation'; fa = 'Change upon schedule calculation';
							|it = 'Change upon schedule calculation';
							|pl = 'Change upon schedule calculation';
							|tr = 'Program hesaplama sırasında değişiklik'", Common.DefaultLanguageCode());
			
			WriteLogEvent(
				Event,
				EventLogLevel.Error,
				OrderDocument.Metadata(),
				OrderDocument,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			OrderNumber = ObjectsPrefixesClientServer.NumberForPrinting(
				Selection.Number, False, True);
			
			If CalculationParameters.UseAvailabilityReserve Then
				Notification = StrTemplate(
					NStr("vi = 'Không thể thay đổi đơn hàng sản xuất %1 (thiết lập dấu hiệu Sử dụng dự phòng khả dụng).
						|Có thể đơn hàng đang được mở bởi người dùng khác hoặc đã bắt đầu chỉnh sửa đơn hàng.';
						|ru = 'Не удалось изменить заказ на производство %1 (установка признака Задействовать резерв доступности).
						|Возможно, заказ открыт другим пользователем или начато редактирование заказа.';
						|en = 'Cannot change the %1 production order (select the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.'; fa = 'Cannot change the %1 production order (select the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.';
						|it = 'Cannot change the %1 production order (select the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.';
						|pl = 'Cannot change the %1 production order (select the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.';
						|tr = '%1 üretim emri değiştirilemedi (Rezerve edilmiş kapasiteyi kullan bayrağı ayarlama).
						|Emir başka bir kullanıcı tarafından açık olabilir veya emrin düzenlemesine başlanmış olabilir.'"),
					OrderNumber);
			Else
				Notification = StrTemplate(
					NStr("vi = 'Không thể thay đổi đơn hàng sản xuất %1 (bỏ dấu hiệu Sử dụng dự phòng khả dụng).
						|Có thể đơn hàng đang được mở bởi người dùng khác hoặc đã bắt đầu chỉnh sửa đơn hàng.';
						|ru = 'Не удалось изменить заказ на производство %1 (снятие признака Задействовать резерв доступности).
						|Возможно, заказ открыт другим пользователем или начато редактирование заказа.';
						|en = 'Cannot change the %1 production order (clear the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.'; fa = 'Cannot change the %1 production order (clear the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.';
						|it = 'Cannot change the %1 production order (clear the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.';
						|pl = 'Cannot change the %1 production order (clear the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.';
						|tr = '%1 üretim emri değiştirilemedi (Rezerve edilmiş kapasiteyi kullan bayrağı kaldırma).
						|Emir başka bir kullanıcı tarafından açık olabilir veya emrin düzenlemesine başlanmış olabilir.'"),
					OrderNumber);
			EndIf;
			
			CalculationParameters.Notifications.Insert(Notification, Undefined);
		EndTry;
	EndIf;
	
EndProcedure

Procedure ExpectEndOfOrderStructureCalculation(ProductionOrder, NotificationStatusOfStructureCalculation)
	
	CalculationProtocol = Documents.ProductionOrder2_2.OrderStructureCalculationProtocol(ProductionOrder);
	
	TextStructureIsNotCalculated =
		NStr("vi = 'Структура заказа на производство не рассчитана. Рекомендуется пересчитать график после расчета структуры.';
			|ru = 'Структура заказа на производство не рассчитана. Рекомендуется пересчитать график после расчета структуры.';
			|en = 'The production order structure is not calculated. It is recommended that you recalculate the schedule after calculating the structure.'; fa = 'The production order structure is not calculated. It is recommended that you recalculate the schedule after calculating the structure.';
			|it = 'Структура заказа на производство не рассчитана. Рекомендуется пересчитать график после расчета структуры.';
			|pl = 'The production order structure is not calculated. It is recommended that you recalculate the schedule after calculating the structure.';
			|tr = 'Структура заказа на производство не рассчитана. Рекомендуется пересчитать график после расчета структуры.'");
	
	If CalculationProtocol.State = CalculationProtocol.StateCodes.Calculated Then
		Return;
	ElsIf CalculationProtocol.State = CalculationProtocol.StateCodes.NotCalculated
		Or CalculationProtocol.State = CalculationProtocol.StateCodes.CalculatedHasErrors
		Or CalculationProtocol.State = CalculationProtocol.StateCodes.NotCalculatedHasErrors
		Or CalculationProtocol.State = CalculationProtocol.StateCodes.IsCancelled Then
		NotificationStatusOfStructureCalculation = TextStructureIsNotCalculated;
		Return;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("State", BackgroundJobState.Active);
	Filter.Insert("Description", DataProcessors.ProductionSchedulePlanning2_2.NameOfScheduleCalculationTask());
	
	Jobs = BackgroundJobs.GetBackgroundJobs(Filter);
	If Jobs.Count() <> 1 Then
		Return;
	EndIf;
	CurrentJob = Jobs[0];
	
	Waiting_Period = CurrentSessionDate() + 600;
	Timeout = 1;
	
	While CurrentSessionDate() < Waiting_Period Do
		CurrentJob = CurrentJob.WaitForExecutionCompletion(Timeout);
		
		CalculationProtocol = Documents.ProductionOrder2_2.OrderStructureCalculationProtocol(ProductionOrder);
		If CalculationProtocol.State = CalculationProtocol.StateCodes.Calculated Then
			Return;
		ElsIf CalculationProtocol.State = CalculationProtocol.StateCodes.NotCalculated
			Or CalculationProtocol.State = CalculationProtocol.StateCodes.CalculatedHasErrors
			Or CalculationProtocol.State = CalculationProtocol.StateCodes.NotCalculatedHasErrors
			Or CalculationProtocol.State = CalculationProtocol.StateCodes.IsCancelled Then
			NotificationStatusOfStructureCalculation = TextStructureIsNotCalculated;
			Return;
		EndIf;
		
		If Timeout < 14 Then
			Timeout = Timeout * 1.4;
		EndIf;
	EndDo;
	
	// For States: Pending calculation, Calculated
	NotificationStatusOfStructureCalculation =
		NStr("vi = 'Структура заказа на производство находится в процессе расчета. Рекомендуется пересчитать график после завершения расчета структуры.';
			|ru = 'Структура заказа на производство находится в процессе расчета. Рекомендуется пересчитать график после завершения расчета структуры.';
			|en = 'The production order structure is being calculated. It is recommended that you recalculate the schedule after calculating the structure.'; fa = 'The production order structure is being calculated. It is recommended that you recalculate the schedule after calculating the structure.';
			|it = 'Структура заказа на производство находится в процессе расчета. Рекомендуется пересчитать график после завершения расчета структуры.';
			|pl = 'The production order structure is being calculated. It is recommended that you recalculate the schedule after calculating the structure.';
			|tr = 'Структура заказа на производство находится в процессе расчета. Рекомендуется пересчитать график после завершения расчета структуры.'");
	
EndProcedure

#EndRegion

#EndRegion
