#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region StatusOfConstantGraph

// Returns the status code of the work schedule.
// 
// 
// Returns:
//  Number - chart status.
//
Function StatusWorkingSchedule() Export
	
	Return 0;
	
EndFunction

// Returns The Status Code For THE preliminary schedule. The preliminary schedule is the production schedule of the order calculated,
// but not yet recorded by the user. After recording, the schedule changes
// to the Status of "Working" (See StatusWorkingSchedule)
// .
// 
// 
// Returns:
//  Number - chart status.
//
Function StatusPreliminarySchedule() Export
	
	Return 1;
	
EndFunction

// Returns the status code of the chart model. The schedule model is calculated without taking into account one or more
// constraints and cannot be saved as a work schedule.
// 
// 
// Returns:
//  Number - chart status.
//
Function StatusChartModel() Export
	
	Return 2;
	
EndFunction

#EndRegion

#Region Record

// Records the results of planning the order schedule in the register.
//
// Parameters:
//  ProductionOrder - DocumentRef.ProductionOrder2_2 - order, the production schedule for which you want to record.
//  ScheduleStatus - Number - chart status.
//  ProductionSchedule - ValueTable - graph data to record. The composition of columns corresponds
//		to the composition of dimensions/resources/register details.
//
Procedure RecordPlanningResults(ProductionOrder, ScheduleStatus, ProductionSchedule) Export
	
	Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
	Set.Filter.ProductionOrder.Set(ProductionOrder);
	Set.Filter.ScheduleStatus.Set(ScheduleStatus);
	
	If ScheduleStatus = StatusWorkingSchedule() Then
		
		Query = New Query(
		"SELECT
		|	ScheduleOfProductionStages2_2.*
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|WHERE
		|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
		|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &ScheduleStatus
		|	AND NOT ScheduleOfProductionStages2_2.Stage IN (&Stages)");
		Query.SetParameter("ProductionOrder", ProductionOrder);
		Query.SetParameter("ScheduleStatus", ScheduleStatus);
		Query.SetParameter("Stages", ProductionSchedule.UnloadColumn("Stage"));
		
		Set.Load(Query.Execute().Unload());
		
	EndIf;
	
	For Each String In ProductionSchedule Do
		
		Record = Set.Add();
		FillPropertyValues(Record, String);
		Record.ProductionOrder = ProductionOrder;
		Record.ScheduleStatus = ScheduleStatus;
		Record.LineKind = Enums.ProductionScheduleRowKinds.Stage;
		
	EndDo;
	
	Set.Write();
	
EndProcedure

// Changes the status of the preliminary schedule to working. Along with a record of the work schedule
// data from the preliminary graph and model is cleared.
//
// Parameters:
//  ProductionOrder - DocumentRef.ProductionOrder2_2 - the order to record the schedule for.
//
Procedure WritePreliminaryScheduleToWorkingOne(ProductionOrder) Export
	
	Query = New Query(
	"SELECT
	|	ScheduleOfProductionStages2_2.ProductionOrder,
	|	ScheduleOfProductionStages2_2.Stage,
	|	ScheduleOfProductionStages2_2.Begin,
	|	ScheduleOfProductionStages2_2.Ending,
	|	ScheduleOfProductionStages2_2.PreliminaryBufferEnd,
	|	ScheduleOfProductionStages2_2.FollowUpBufferStart,
	|	ScheduleOfProductionStages2_2.NextStageStart,
	|	ScheduleOfProductionStages2_2.OnCriticalPath,
	|	ScheduleOfProductionStages2_2.ItLimitsProductionDate,
	|	ScheduleOfProductionStages2_2.MaterialLimited,
	|	ScheduleOfProductionStages2_2.EquipmentLimited,
	|	ScheduleOfProductionStages2_2.ProductionScheduling,
	|	ScheduleOfProductionStages2_2.LineKind
	|INTO PreliminarySchedule
	|FROM
	|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
	|WHERE
	|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
	|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &StatusPreliminarySchedule
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PreliminarySchedule.ProductionOrder,
	|	PreliminarySchedule.Stage,
	|	&StatusWorkingSchedule AS ScheduleStatus,
	|	PreliminarySchedule.Begin,
	|	PreliminarySchedule.Ending,
	|	PreliminarySchedule.PreliminaryBufferEnd,
	|	PreliminarySchedule.FollowUpBufferStart,
	|	PreliminarySchedule.NextStageStart,
	|	PreliminarySchedule.OnCriticalPath,
	|	PreliminarySchedule.ItLimitsProductionDate,
	|	PreliminarySchedule.MaterialLimited,
	|	PreliminarySchedule.EquipmentLimited,
	|	PreliminarySchedule.ProductionScheduling,
	|	PreliminarySchedule.LineKind
	|FROM
	|	PreliminarySchedule AS PreliminarySchedule
	|
	|UNION ALL
	|
	|SELECT
	|	ScheduleOfProductionStages2_2.ProductionOrder,
	|	ScheduleOfProductionStages2_2.Stage,
	|	ScheduleOfProductionStages2_2.ScheduleStatus,
	|	ScheduleOfProductionStages2_2.Begin,
	|	ScheduleOfProductionStages2_2.Ending,
	|	ScheduleOfProductionStages2_2.PreliminaryBufferEnd,
	|	ScheduleOfProductionStages2_2.FollowUpBufferStart,
	|	ScheduleOfProductionStages2_2.NextStageStart,
	|	ScheduleOfProductionStages2_2.OnCriticalPath,
	|	ScheduleOfProductionStages2_2.ItLimitsProductionDate,
	|	ScheduleOfProductionStages2_2.MaterialLimited,
	|	ScheduleOfProductionStages2_2.EquipmentLimited,
	|	ScheduleOfProductionStages2_2.ProductionScheduling,
	|	ScheduleOfProductionStages2_2.LineKind
	|FROM
	|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
	|WHERE
	|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
	|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &StatusWorkingSchedule
	|	AND NOT ScheduleOfProductionStages2_2.Stage IN
	|				(SELECT
	|					PreliminarySchedule.Stage
	|				FROM
	|					PreliminarySchedule)");
	
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.SetParameter("StatusPreliminarySchedule", StatusPreliminarySchedule());
	Query.SetParameter("StatusWorkingSchedule", StatusWorkingSchedule());
	
	ScheduleData = Query.Execute().Unload();
	
	Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
	Set.Filter.ProductionOrder.Set(ProductionOrder);
	Set.Load(ScheduleData);
	Set.Write();
	
EndProcedure

// Clears the tentative timetable for the order.
//
// Parameters:
//  ProductionOrder - DocumentRef.ProductionOrder2_2 - the order to clear the schedule for.
//
Procedure ClearPreliminarySchedule(ProductionOrder) Export
	
	Query = New Query(
	"SELECT
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
	|		WHERE
	|			ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
	|			AND ScheduleOfProductionStages2_2.ScheduleStatus = &StatusPreliminarySchedule) AS ClearPreliminarySchedule,
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
	|		WHERE
	|			ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
	|			AND ScheduleOfProductionStages2_2.ScheduleStatus = &StatusChartModel) AS ClearModel");
	Query.SetParameter("ProductionOrder", ProductionOrder);
	
	StatusPreliminarySchedule = StatusPreliminarySchedule();
	Query.SetParameter("StatusPreliminarySchedule", StatusPreliminarySchedule);
	
	StatusChartModel = StatusChartModel();
	Query.SetParameter("StatusChartModel", StatusChartModel);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	If Selection.ClearPreliminarySchedule Then
		Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
		Set.Filter.ProductionOrder.Set(ProductionOrder);
		Set.Filter.ScheduleStatus.Set(StatusPreliminarySchedule);
		Set.Write();
	EndIf;
	
	If Selection.ClearModel Then
		Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
		Set.Filter.ProductionOrder.Set(ProductionOrder);
		Set.Filter.ScheduleStatus.Set(StatusChartModel);
		Set.Write();
	EndIf;
	
EndProcedure

// Records the manually set placement of a stage in the graph
//
// Parameters:
//  Dimensions - Structure
//  ProductionSchedule - See ProductionManagementClientServer.StructureOfStagePlacementInSchedule.
//  Attributes - Structure
//
Procedure RecordManualPlacementOfStageInGraph(Dimensions, ProductionSchedule, Attributes) Export
	
	ScheduleStatus = StatusWorkingSchedule();
	
	Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
	Set.Filter.ProductionOrder.Set(Dimensions.ProductionOrder);
	Set.Filter.ScheduleStatus.Set(ScheduleStatus);
	Set.Filter.Stage.Set(Dimensions.Stage);
	Set.Filter.KeyLot.Set(Dimensions.KeyLot);
	Set.Read();
	
	If Set.Count() > 0 Then
		Record = Set[0];
	Else
		Record = Set.Add();
		FillPropertyValues(Record, Dimensions, "ProductionOrder, Stage, KeyLot");
		FillPropertyValues(Record, Attributes);
		Record.ScheduleStatus = ScheduleStatus;
		Record.LineKind = Enums.ProductionScheduleRowKinds.Stage;
	EndIf;
	
	FillPropertyValues(Record, ProductionSchedule,
		"Begin, Ending, PreliminaryBufferEnd, FollowUpBufferStart");
	
	Set.Write();
	
	If ValueIsFilled(Dimensions.KeyLot) Then
		TempTablesManager = New TempTablesManager();
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("KeyLot", Dimensions.KeyLot);
		Query.Text = 
			"SELECT
			|	&KeyLot AS KeyLot
			|INTO TTKeysLotReferences";
		Query.Execute();
		
		CalculateResultsOfLotReferences(Dimensions.ProductionOrder, TempTablesManager, "TTKeysLotReferences");
	EndIf;
	
EndProcedure

// Clears the production schedule of a given stage.
// 
// Parameters:
//  ProductionOrder - DocumentRef.ProductionOrder2_2
//  Stage - DocumentRef.ProductionStage2_2
//
Procedure ToClearStageSchedule(ProductionOrder, Stage) Export
	
	Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
	Set.Filter.ProductionOrder.Set(ProductionOrder);
	Set.Filter.ScheduleStatus.Set(StatusWorkingSchedule());
	Set.Filter.Stage.Set(Stage);
	Set.Write();
	
EndProcedure

// Clears the production schedule and loading of RC types at all stages of a given Lot reference
//
// Parameters:
//  Lots	 - Structure, ValueTable, TempTablesManager - Lot reference or Lot reference list:
//  	*  ProductionOrder - AnyRef - production order.
//  	*  KeyLot - UUID - the party key.
//  	When passing a temporary table manager, it must contain a Batch table.
//
Procedure ClearScheduleAndDownloadLotReference(Lots) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.SetParameter("ScheduleStatus", StatusWorkingSchedule());
	
	QueryTexts = New ValueList;
	
	If TypeOf(Lots) = Type("ValueTable") Then
		
		QueryText = 
			"SELECT DISTINCT
			|	Lots.ProductionOrder AS ProductionOrder,
			|	Lots.KeyLot          AS KeyLot
			|INTO Lots
			|FROM
			|	&Lots AS Lots
			|
			|INDEX BY
			|	ProductionOrder,
			|	KeyLot";
		QueryTexts.Add(QueryText, "Lots");
		
		Query.SetParameter("Lots", Lots);
		
	ElsIf TypeOf(Lots) = Type("TempTablesManager") Then
		
		Query.TempTablesManager = Lots;
		
	Else
		
		QueryText = 
			"SELECT
				|	&ProductionOrder AS ProductionOrder,
				|	&KeyLot          AS KeyLot
				|INTO Lots";
		QueryTexts.Add(QueryText, "Lots");
		
		Query.SetParameter("ProductionOrder", Lots.ProductionOrder);
		Query.SetParameter("KeyLot", Lots.KeyLot);
		
	EndIf;
	
	QueryText =
		"SELECT
		|	Schedule.ProductionOrder AS ProductionOrder,
		|	Schedule.ScheduleStatus AS ScheduleStatus,
		|	Schedule.Stage AS Stage,
		|	Schedule.KeyLot AS KeyLot
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|WHERE
		|	(Schedule.ProductionOrder, Schedule.ScheduleStatus, Schedule.KeyLot) IN
		|			(SELECT
		|				DD.ProductionOrder,
		|				&ScheduleStatus,
		|				DD.KeyLot
		|			FROM
		|				Lots AS DD)";
	QueryTexts.Add(QueryText, "Schedule");
	
	QueryText =
		"SELECT
		|	Load.Recorder AS Recorder,
		|	Load.Period AS Period,
		|	Load.WorkCenterType AS WorkCenterType,
		|	Load.IntervalDate AS IntervalDate,
		|	-SUM(Load.Busy) AS Busy,
		|	Load.ReferenceOrder AS ReferenceOrder,
		|	Load.Department AS Department,
		|	Load.Shift AS Shift,
		|	Load.KeyLot AS KeyLot,
		|	Load.Stage AS Stage
		|FROM
		|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS Load
		|WHERE
		|	(Load.ReferenceOrder, Load.KeyLot) IN
		|			(SELECT
		|				DD.ProductionOrder,
		|				DD.KeyLot
		|			FROM
		|				Lots AS DD)
		|
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
		|
		|HAVING
		|	SUM(Load.Busy) <> 0
		|TOTALS BY
		|	Recorder";
	QueryTexts.Add(QueryText, "Enabled");
	
	QueryText = "SELECT DISTINCT
	|				DD.ProductionOrder AS ProductionOrder,
	|				DD.KeyLot AS KeyLot
	|			FROM
	|				Lots AS DD";
	QueryTexts.Add(QueryText, "Jobs");
	
	QueryResults = TMCommonUse.GetQueryResults(Query, QueryTexts, True);
	
	QueryResultGraph = QueryResults.Schedule; // QueryResult
	Selection = QueryResultGraph.Select();
	While Selection.Next() Do
		Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
		Set.Filter.ProductionOrder.Set(Selection.ProductionOrder);
		Set.Filter.ScheduleStatus.Set(Selection.ScheduleStatus);
		Set.Filter.Stage.Set(Selection.Stage);
		Set.Filter.KeyLot.Set(Selection.KeyLot);
		Set.Write();
	EndDo;
	
	ResultOfAvailabilityQuery = QueryResults.Enabled; // QueryResult
	SamplingLogger = ResultOfAvailabilityQuery.Select(QueryResultIteration.ByGroups);
	While SamplingLogger.Next() Do
		Set = AccumulationRegisters.AvailabilityOfWorkCenterTypes.CreateRecordSet();
		Set.Filter.Recorder.Set(SamplingLogger.Recorder);
		
		Selection = SamplingLogger.Select();
		While Selection.Next() Do
			FillPropertyValues(Set.Add(), Selection);
		EndDo;
		
		Set.Write(False);
	EndDo;
	
	TasksToDeleting = QueryResults.Jobs.Unload();
	RecordsFilter = New Structure("ProductionOrder, KeyLot");
	For Each RowJob In TasksToDeleting Do
		FillPropertyValues(RecordsFilter, RowJob);
		InformationRegisters.OrderStructureCalculationJobsProductionSchedule.DeleteSelectionEntries(RecordsFilter);
	EndDo;
	
EndProcedure

// Removes the "critical Path" and "limited release" flags in the production phase schedule.
//
// Parameters:
//  Stage - DocumentRef.ProductionStage2_2 - stage of production.
//
Procedure ClearStageAttributeOnCriticalPath(Stage) Export
	
	Manager = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordManager();
	Manager.ProductionOrder = Common.ObjectAttributeValue(Stage, "ReferenceOrder");
	Manager.Stage = Stage;
	Manager.ScheduleStatus = StatusWorkingSchedule();
	Manager.Read();
	
	If Manager.Selected() And Manager.OnCriticalPath Then
		
		Manager.OnCriticalPath = False;
		Manager.ItLimitsProductionDate = False;
		Manager.Write();
		
	EndIf;
	
EndProcedure

// Calculates the results of the specified batches and, if necessary, the results of the order.
// 
// Parameters:
//  ProductionOrder - DocumentRef.ProductionOrder2_2
//  TempTablesManager - TempTablesManager
//  NameOfLotReferenceTable - String
//
Procedure CalculateResultsOfLotReferences(ProductionOrder, TempTablesManager, NameOfLotReferenceTable) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("OrderDocument", ProductionOrder);
	Query.SetParameter("ScheduleStatus", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	
	QueryText = 
		"SELECT
		|	Schedule.ProductionOrder      AS ProductionOrder,
		|	Schedule.ScheduleStatus            AS ScheduleStatus,
		|	VALUE(Catalog.ProductionStages.EmptyRef)        AS Stage,
		|	Schedule.KeyLot               AS KeyLot,
		|	VALUE(Enum.ProductionScheduleRowKinds.Lot) AS LineKind,
		|	MIN(Schedule.Begin)          AS Begin,
		|	MAX(Schedule.Ending)      AS Ending,
		|	MIN(Schedule.Order)         AS Order
		|INTO TTResultsOfLotReferences
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|WHERE
		|	(Schedule.ProductionOrder, Schedule.ScheduleStatus, Schedule.KeyLot) IN (
		|		SELECT
		|			&OrderDocument AS ProductionOrder,
		|			&ScheduleStatus AS ScheduleStatus,
		|			T.KeyLot AS KeyLot
		|		FROM
		|			&BatchTable_ AS T)
		|	AND Schedule.LineKind <> VALUE(Enum.ProductionScheduleRowKinds.Lot)
		|
		|GROUP BY
		|	Schedule.ProductionOrder,
		|	Schedule.ScheduleStatus,
		|	Schedule.KeyLot
		|
		|INDEX BY
		|	ProductionOrder, ScheduleStatus, Stage, KeyLot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ResultsOfLotReferences.ProductionOrder AS ProductionOrder,
		|	ResultsOfLotReferences.ScheduleStatus       AS ScheduleStatus,
		|	ResultsOfLotReferences.Stage                AS Stage,
		|	ResultsOfLotReferences.KeyLot          AS KeyLot,
		|	ResultsOfLotReferences.LineKind           AS LineKind,
		|	ResultsOfLotReferences.Begin              AS Begin,
		|	ResultsOfLotReferences.Ending           AS Ending,
		|	ResultsOfLotReferences.Order             AS Order
		|FROM
		|	TTResultsOfLotReferences AS ResultsOfLotReferences
		|WHERE
		|	NOT TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|		WHERE
		|			Schedule.ProductionOrder = ResultsOfLotReferences.ProductionOrder
		|			AND Schedule.ScheduleStatus = ResultsOfLotReferences.ScheduleStatus
		|			AND Schedule.Stage = ResultsOfLotReferences.Stage
		|			AND Schedule.KeyLot = ResultsOfLotReferences.KeyLot
		|			AND Schedule.Begin = ResultsOfLotReferences.Begin
		|			AND Schedule.Ending = ResultsOfLotReferences.Ending)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTResultsOfLotReferences";
	
	QueryText = StrReplace(QueryText, "&BatchTable_", NameOfLotReferenceTable);
	Query.Text = QueryText;
	
	QueryResults = Query.ExecuteBatch();
	Selection = QueryResults[1].Select();
	If Selection.Count() = 0 Then
		Return;
	EndIf;
	
	While Selection.Next() Do
		Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
		Set.Filter.ProductionOrder.Set(Selection.ProductionOrder);
		Set.Filter.ScheduleStatus.Set(Selection.ScheduleStatus);
		Set.Filter.Stage.Set(Selection.Stage);
		Set.Filter.KeyLot.Set(Selection.KeyLot);
		FillPropertyValues(Set.Add(), Selection);
		Set.Write();
	EndDo;
	
	// Order results
	Query.Text =
		"SELECT
		|	Schedule.ProductionOrder      AS ProductionOrder,
		|	Schedule.ScheduleStatus            AS ScheduleStatus,
		|	VALUE(Catalog.ProductionStages.EmptyRef)       AS Stage,
		|	&EmptyLinkKey                AS KeyLot,
		|	VALUE(Enum.ProductionScheduleRowKinds.OrderDocument) AS LineKind,
		|	MIN(Schedule.Begin)          AS Begin,
		|	MAX(Schedule.Ending)      AS Ending,
		|	0                               AS Order
		|INTO ResultsOfOrderTT
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|WHERE
		|	Schedule.ProductionOrder = &OrderDocument
		|	AND Schedule.ScheduleStatus = &ScheduleStatus
		|	AND Schedule.LineKind <> VALUE(Enum.ProductionScheduleRowKinds.OrderDocument)
		|
		|GROUP BY
		|	Schedule.ProductionOrder,
		|	Schedule.ScheduleStatus
		|
		|INDEX BY
		|	ProductionOrder, ScheduleStatus, Stage, KeyLot
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrderTotals.ProductionOrder AS ProductionOrder,
		|	OrderTotals.ScheduleStatus       AS ScheduleStatus,
		|	OrderTotals.Stage                AS Stage,
		|	OrderTotals.KeyLot          AS KeyLot,
		|	OrderTotals.LineKind           AS LineKind,
		|	OrderTotals.Begin              AS Begin,
		|	OrderTotals.Ending           AS Ending,
		|	OrderTotals.Order             AS Order
		|FROM
		|	ResultsOfOrderTT AS OrderTotals
		|WHERE
		|	NOT TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|		WHERE
		|			Schedule.ProductionOrder = OrderTotals.ProductionOrder
		|			AND Schedule.ScheduleStatus = OrderTotals.ScheduleStatus
		|			AND Schedule.Stage = OrderTotals.Stage
		|			AND Schedule.KeyLot = OrderTotals.KeyLot
		|			AND Schedule.Begin = OrderTotals.Begin
		|			AND Schedule.Ending = OrderTotals.Ending)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ResultsOfOrderTT";
	
	QueryResults = Query.ExecuteBatch();
	Selection = QueryResults[1].Select();
	If Not Selection.Next() Then
		Return;
	EndIf;
	
	Set = InformationRegisters.ScheduleOfProductionStages2_2.CreateRecordSet();
	Set.Filter.ProductionOrder.Set(Selection.ProductionOrder);
	Set.Filter.ScheduleStatus.Set(Selection.ScheduleStatus);
	Set.Filter.Stage.Set(Selection.Stage);
	Set.Filter.KeyLot.Set(Selection.KeyLot);
	FillPropertyValues(Set.Add(), Selection);
	Set.Write();
	
EndProcedure

#EndRegion

#Region Read

// Returns the production schedule for stages
//
// Parameters:
//  Stages - Array - stage of production.
// 
// Returns:
//   - ValueTable - production schedule of stages.
//
Function ProductionSchedule(Stages) Export
	
	Query = New Query(
		"SELECT
		|	Document.Ref                                                    AS Stage,
		|	NOT Schedule.Begin IS NULL                                         AS Calculated,
		|	ISNULL(Schedule.Begin, DATETIME(1,1,1))                          AS Begin,
		|	ISNULL(Schedule.Ending, DATETIME(1,1,1))                       AS Ending,
		|	ISNULL(Schedule.PreliminaryBufferEnd, DATETIME(1,1,1)) AS PreliminaryBufferEnd,
		|	ISNULL(Schedule.FollowUpBufferStart, DATETIME(1,1,1))        AS FollowUpBufferStart,
		|	ISNULL(Schedule.OnCriticalPath, FALSE)                           AS OnCriticalPath,
		|	ISNULL(Schedule.ItLimitsProductionDate, FALSE)                     AS ItLimitsProductionDate
		|FROM
		|	Document.ProductionStage2_2 AS Document
		|		LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|		ON Schedule.ProductionOrder = Document.ReferenceOrder
		|			AND Schedule.Stage = Document.Ref
		|			AND (Schedule.ScheduleStatus = &ScheduleStatus)
		|WHERE
		|	Document.Ref IN(&Stages)");
	
	Query.SetParameter("Stages", Stages);
	Query.SetParameter("ScheduleStatus", StatusWorkingSchedule());
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns the query text that gets the start and end dates of stages based on the graph data
//  (for non-started stages) and the data of the stage itself (if the stage is started or completed).
//  When using the function, the request must contain the "Statusgraphics" parameter for selecting
//  a graph with the specified status.
//
// Parameters:
//  TableStages	 - String	 - name of the temporary table that contains the steps for selecting data.
//  StageField		 - String	 - name of the table field.
//  KeyLotReferenceField	 - String	 - name of the table field.
// 
// Returns:
//   - String - the text of the request for the creation of a temporary table for the completion of these steps.
//
Function QueryTextTTTermsOfStages(TableStages, StageField, KeyLotReferenceField = "") Export
	
	Result =
	"SELECT
	|	Schedule.ProductionOrder AS ProductionOrder,
	|	Schedule.Stage AS ProductionStage,
	|	Schedule.KeyLot AS KeyLot,
	|	ISNULL(CASE
	|			WHEN Document.Status IN (VALUE(Enum.StatusesOfProductionStages2_2.Initiated), VALUE(Enum.StatusesOfProductionStages2_2.Completed))
	|				THEN Document.ActualStageStart
	|		END, Schedule.Begin) AS StageStart,
	|	ISNULL(CASE
	|			WHEN Document.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
	|				THEN CASE
	|						WHEN Document.ProductionDate >= Schedule.Ending
	|								AND Document.ProductionDate >= Document.ActualStageStart
	|							THEN ENDOFPERIOD(Document.ProductionDate, DAY)
	|						WHEN Document.ActualStageStart >= Schedule.Ending
	|								AND Document.ActualStageStart >= Document.ProductionDate
	|							THEN ENDOFPERIOD(Document.ActualStageStart, DAY)
	|						ELSE Schedule.Ending
	|					END
	|			WHEN Document.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|				THEN Document.ActualStageEnd
	|		END, Schedule.Ending) AS StageEnd
	|INTO TTTermsOfStages
	|FROM
	|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
	|		LEFT JOIN Document.ProductionStage2_2 AS Document
	|		ON Schedule.Stage = Document.Ref
	|WHERE
	|	(Schedule.Stage, &GraphFieldKeyLotReference) IN
	|			(SELECT
	|				&StageField,
	|				&KeyLotReferenceField
	|			FROM
	|				&TableStages AS T)
	|	AND Schedule.ScheduleStatus = &ScheduleStatus
	|
	|INDEX BY
	|	ProductionStage,
	|	KeyLot";
	
	Result = StrReplace(Result, "&TableStages", TableStages);
	Result = StrReplace(Result, "&StageField", StageField);
	Result = StrReplace(Result, "&KeyLotReferenceField", ?(IsBlankString(KeyLotReferenceField), "TRUE", KeyLotReferenceField));
	Result = StrReplace(Result, "&GraphFieldKeyLotReference", ?(IsBlankString(KeyLotReferenceField), "TRUE", "Schedule.KeyLot"));
	
	Return Result;
	
EndFunction

// Function - Full interval
//
// Parameters:
//  ProductionOrder - DocumentRef.ProductionOrder2_2 - production order.
//  ScheduleStatus - See ProductionManagementClientServer.StructureOfStagePlacementInSchedule
// 
// Returns:
//  Structure - Order Boundaries
//
Function FullInterval(ProductionOrder, ScheduleStatus = 0) Export
	
	Query = New Query;
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.SetParameter("ScheduleStatus", ScheduleStatus);
	
	If GetFunctionalOption("DynamicStructureOfProductionOrders")
		And Common.ObjectAttributeValue(ProductionOrder, "DynamicStructure") = True Then
		Query.Text =
		"SELECT
		|	Schedule.Begin AS Begin,
		|	Schedule.Ending AS Ending
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|WHERE
		|	Schedule.ProductionOrder = &ProductionOrder
		|	AND Schedule.ScheduleStatus = &ScheduleStatus
		|	AND Schedule.KeyLot = &EmptyLinkKey
		|	AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|";
	Else
		Query.Text =
		"SELECT
		|	MIN(Schedule.Begin) AS Begin,
		|	MAX(Schedule.Ending) AS Ending
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|WHERE
		|	Schedule.ProductionOrder = &ProductionOrder
		|	AND Schedule.ScheduleStatus = &ScheduleStatus
		|";
	EndIf;
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	Boundaries = New Structure("Begin, Ending", '00010101', '00010101');
	
	If Selection.Next() Then
		Boundaries.Begin = ?(Not ValueIsFilled(Selection.Begin), '00010101', Selection.Begin);
		Boundaries.Ending = ?(Not ValueIsFilled(Selection.Ending), '00010101', Selection.Ending);
	EndIf;
	
	Return Boundaries;
	
EndFunction

// The function returns an indication of the need to calculate the production schedule
//
// Parameters:
//  ProductionOrder - DocumentRef.ProductionOrder2_2 - production order.
// 
// Returns:
//  Boolean - True if you want to calculate the schedule.
//
Function ItIsRequiredToCalculateSchedule(ProductionOrder) Export
	
	Query = New Query(
		"SELECT
		|	TRUE
		|WHERE
		|	TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.OrderStructureCalculationJobsProductionSchedule AS DD
		|		WHERE
		|			DD.ProductionOrder = &ProductionOrder)
		|	OR TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.JobsToProductionScheduleCalculation AS DD
		|		WHERE
		|			DD.ReferenceOrder = &ProductionOrder)");
	Query.SetParameter("ProductionOrder", ProductionOrder);

	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region Other

// Checks whether the production schedule contains changes
//
// Parameters:
//  Stage - DocumentRef.ProductionStage2_2 - stage of production.
//  ProductionSchedule - See ProductionManagementClientServer.StructureOfStagePlacementInSchedule
// 
// Returns:
//   - Boolean - True if the production schedule contains changes.
//
Function PlacementOfStageInScheduleHasChanged(Stage, ProductionSchedule) Export
	
	Query = New Query(
		"SELECT
		|	TRUE                                  AS Calculated,
		|	Table.Begin                          AS Begin,
		|	Table.PreliminaryBufferEnd AS PreliminaryBufferEnd,
		|	Table.FollowUpBufferStart        AS FollowUpBufferStart,
		|	Table.Ending                       AS Ending
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS Table
		|WHERE
		|	Table.Stage = &Stage
		|	AND Table.ScheduleStatus  = &ScheduleStatus");
	
	Query.SetParameter("Stage", Stage);
	Query.SetParameter("ScheduleStatus", StatusWorkingSchedule());
	
	PlacementInChart = ProductionManagementClientServer.StructureOfStagePlacementInSchedule();

	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		FillPropertyValues(PlacementInChart, Selection);
		
	EndIf;
	
	Return Not Common.DataMatch(PlacementInChart, ProductionSchedule);
	
EndFunction

#EndRegion

#EndRegion

#EndIf