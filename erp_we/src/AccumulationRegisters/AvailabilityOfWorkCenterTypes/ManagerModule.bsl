#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the employment of work center types by stage
//
// Parameters:
//  Ref	 - DocumentRef.ProductionStage2_2	 - stage of production.
// 
// Returns:
//   - ValueTable - occupied by a stage.
//
Function BusyStage(Ref) Export
	
	Query = New Query(
		"SELECT
		|	Table.WorkCenterType AS WorkCenterType,
		|	Table.IntervalDate     AS IntervalDate,
		|	Table.Busy            AS Count
		|FROM
		|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS Table
		|WHERE
		|	Table.Recorder = &Ref");
		
	Query.SetParameter("Ref", Ref);
	
	Return Query.Execute().Unload();
	
EndFunction

// Writes data about equipment loading by the production schedule to the register.
//
// Parameters:
//  Recorders		 - Array - documents whose movements need to be recorded.
//  ProductionSchedule	 - ValueTable - upload data for recording.
//
Procedure RecordBusyProductionSchedule(Recorders, ProductionSchedule) Export
	
	SetPrivilegedMode(True);
	
	ProductionSchedule.Indexes.Add("Stage");
	TheStructureOfTheSearch = New Structure("Stage");
	
	Query = New Query(
	"SELECT
	|	ProductionStage2_2.Ref       AS Recorder,
	|	ProductionStage2_2.ReferenceOrder AS ReferenceOrder,
	|	ProductionStage2_2.Date         AS Period,
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			AccumulationRegister.AvailabilityOfWorkCenterTypes AS T
	|		WHERE
	|			T.Recorder = ProductionStage2_2.Ref) AS ThereAreRegisteredRecords
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|WHERE
	|	ProductionStage2_2.Ref IN(&Recorders)");
	Query.SetParameter("Recorders", Recorders);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		TheStructureOfTheSearch.Stage = Selection.Recorder;
		FoundRows = ProductionSchedule.FindRows(TheStructureOfTheSearch);
		
		If ValueIsFilled(FoundRows) Then
			
			Set = AccumulationRegisters.AvailabilityOfWorkCenterTypes.CreateRecordSet();
			Set.Filter.Recorder.Set(Selection.Recorder);
			For Each String In FoundRows Do
				
				Record = Set.Add();
				FillPropertyValues(Record, String);
				FillPropertyValues(Record, Selection, "ReferenceOrder, Period");
				
			EndDo;
			Set.Write();
			
		ElsIf Selection.ThereAreRegisteredRecords Then
			
			Set = AccumulationRegisters.AvailabilityOfWorkCenterTypes.CreateRecordSet();
			Set.Filter.Recorder.Set(Selection.Recorder);
			Set.Write();
			
		EndIf;
		
	EndDo;
	
	IntervalColumns = "WorkCenterType, IntervalDate";
	Intervals = ProductionSchedule.Copy(, IntervalColumns);
	Intervals.GroupBy(IntervalColumns);
	CheckDownloadDoesNotExceedScheduleAvailability(Intervals);
	
EndProcedure

// Checks that the hardware load does not exceed the available time.
// If an excess is detected, tasks for recalculating the production schedule are recorded in the database.
//
// Parameters:
//  Intervals - ValueTable - the time intervals that you want to test. 
//
Procedure CheckDownloadDoesNotExceedScheduleAvailability(Intervals) Export
	
	Query = New Query(
	"SELECT
	|	Intervals.WorkCenterType AS WorkCenterType,
	|	Intervals.IntervalDate     AS IntervalDate
	|INTO TTAllIntervals
	|FROM
	|	&Intervals AS Intervals
	|
	|INDEX BY
	|	WorkCenterType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAllIntervals.WorkCenterType               AS WorkCenterType,
	|	TTAllIntervals.IntervalDate                   AS IntervalDate,
	|	WorkCenterTypes.EnterAvailabilityForWorkCenterType AS EnterAvailabilityForWorkCenterType
	|INTO TTIntervals
	|FROM
	|	TTAllIntervals AS TTAllIntervals
	|
	|	LEFT JOIN Catalog.WorkCenterTypes AS WorkCenterTypes
	|	ON TTAllIntervals.WorkCenterType = WorkCenterTypes.Ref
	|WHERE
	|	WorkCenterTypes.UseAvailabilityAccordingToSchedule
	|
	|INDEX BY
	|	WorkCenterType,
	|	IntervalDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.WorkCenterType  AS WorkCenterType,
	|	NestedQuery.IntervalDate      AS IntervalDate,
	|	NestedQuery.OrderDocument              AS OrderDocument,
	|	NestedQuery.Stage               AS Stage,
	|	SUM(NestedQuery.Enabled) AS Enabled,
	|	SUM(NestedQuery.Load)    AS Load
	|INTO TTAvailability
	|FROM
	|	(SELECT
	|		Enabled.WorkCenterType AS WorkCenterType,
	|		Enabled.IntervalDate     AS IntervalDate,
	|		CASE
	|			WHEN Enabled.IsRecordOfWorkCentersCapacityChange
	|				THEN UNDEFINED
	|			ELSE Enabled.ReferenceOrder
	|		END                         AS OrderDocument,
	|		CASE
	|			WHEN Enabled.IsRecordOfWorkCentersCapacityChange
	|				OR Enabled.KeyLot <> &EmptyLinkKey
	|					AND Enabled.Stage REFS Catalog.ProductionStages
	|				THEN UNDEFINED
	|			ELSE Enabled.Stage
	|		END                         AS Stage,
	|		CASE
	|			WHEN TTIntervals.EnterAvailabilityForWorkCenterType
	|				THEN Enabled.WorkCenterTypeSchedule
	|			ELSE Enabled.WorkCenterSchedule
	|		END                         AS Enabled,
	|		Enabled.Busy            AS Load
	|	FROM
	|		AccumulationRegister.AvailabilityOfWorkCenterTypes AS Enabled
	|		
	|		INNER JOIN TTIntervals AS TTIntervals
	|		ON Enabled.WorkCenterType = TTIntervals.WorkCenterType
	|			AND Enabled.IntervalDate = TTIntervals.IntervalDate
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.WorkCenterType,
	|	NestedQuery.IntervalDate,
	|	NestedQuery.OrderDocument,
	|	NestedQuery.Stage
	|
	|INDEX BY
	|	WorkCenterType,
	|	IntervalDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAvailability.WorkCenterType  AS WorkCenterType,
	|	TTAvailability.IntervalDate      AS IntervalDate,
	|	SUM(TTAvailability.Enabled) AS AvailabilityInterval
	|INTO TTOverAvailability
	|FROM
	|	TTAvailability AS TTAvailability
	|
	|GROUP BY
	|	TTAvailability.WorkCenterType,
	|	TTAvailability.IntervalDate
	|
	|HAVING
	|	SUM(TTAvailability.Load) > SUM(TTAvailability.Enabled)
	|
	|INDEX BY
	|	WorkCenterType,
	|	IntervalDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAvailability.WorkCenterType AS WorkCenterType,
	|	TTAvailability.IntervalDate     AS IntervalDate,
	|	TTAvailability.OrderDocument             AS OrderDocument,
	|	TTAvailability.Stage              AS Stage,
	|	TTAvailability.Load          AS Load,
	|	CASE
	|		WHEN TTAvailability.OrderDocument REFS Document.ProductionOrder2_2
	|			THEN CAST(TTAvailability.OrderDocument AS Document.ProductionOrder2_2).DynamicStructure
	|		ELSE FALSE
	|	END                           AS DynamicStructure,
	|	TTAvailability.OrderDocument REFS Document.ProductionOrder2_2
	|			AND CAST(TTAvailability.OrderDocument AS Document.ProductionOrder2_2).DynamicStructure
	|			AND TTAvailability.Stage = UNDEFINED
	|		OR TTAvailability.Stage REFS Document.ProductionStage2_2
	|			AND NOT CAST(TTAvailability.Stage AS Document.ProductionStage2_2).StagePlacementInProductionSchedule
	|			AND CAST(TTAvailability.Stage AS Document.ProductionStage2_2).Status IN (
	|				VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated),
	|				VALUE(Enum.StatusesOfProductionStages2_2.Generated1),
	|				VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion)) AS AddToTasks,
	|	TTOverAvailability.AvailabilityInterval AS AvailabilityInterval,
	|	CASE
	|		WHEN TTAvailability.OrderDocument REFS Document.ProductionOrder2_2
	|			THEN CAST(TTAvailability.OrderDocument AS Document.ProductionOrder2_2).Priority.AddlOrderingAttribute
	|	END AS Priority,
	|	CASE
	|		WHEN TTAvailability.OrderDocument REFS Document.ProductionOrder2_2
	|			THEN CAST(TTAvailability.OrderDocument AS Document.ProductionOrder2_2).Department.AddlOrderingAttribute
	|	END AS DivisionPriority_,
	|	CASE
	|		WHEN TTAvailability.OrderDocument REFS Document.ProductionOrder2_2
	|			THEN 2
	|	END AS OrderPriority,
	|	CASE
	|		WHEN TTAvailability.OrderDocument REFS Document.ProductionOrder2_2
	|			THEN CAST(TTAvailability.OrderDocument AS Document.ProductionOrder2_2).Queue
	|	END AS Queue
	|FROM
	|	TTAvailability AS TTAvailability
	|
	|	INNER JOIN TTOverAvailability AS TTOverAvailability
	|	ON TTAvailability.WorkCenterType = TTOverAvailability.WorkCenterType
	|		AND TTAvailability.IntervalDate = TTOverAvailability.IntervalDate
	|
	|	LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS StandardScheduleOfProductionStages
	|	ON TTAvailability.Stage = StandardScheduleOfProductionStages.ProductionStage
	|WHERE
	|	TTAvailability.Load > 0
	|
	|ORDER BY
	|	Priority,
	|	DivisionPriority_,
	|	OrderPriority,
	|	Queue,
	|	ISNULL(StandardScheduleOfProductionStages.DurationBeforeProductionIssue, 0) DESC,
	|	ISNULL(StandardScheduleOfProductionStages.ResourceIntensity, 0) DESC
	|TOTALS
	|	MAX(AvailabilityInterval)
	|BY
	|	WorkCenterType,
	|	IntervalDate");
	
	Query.SetParameter("Intervals", Intervals);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	
	TasksToAdd = New ValueTable();
	TasksToAdd.Columns.Add("ProductionOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	TasksToAdd.Columns.Add("ProductionStage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	
	Stages = New Array;
	
	SelectionViewOfWorkCenter = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SelectionViewOfWorkCenter.Next() Do
		
		SamplingDateInterval = SelectionViewOfWorkCenter.Select(QueryResultIteration.ByGroups);
		While SamplingDateInterval.Next() Do
			
			Enabled = SamplingDateInterval.AvailabilityInterval;
			Selection = SamplingDateInterval.Select();
			While Selection.Next() Do
				If Selection.Load > Enabled Then
					Enabled = 0;
					
					If Selection.AddToTasks
						And Selection.DynamicStructure Then
						NewRow = TasksToAdd.Add();
						NewRow.ProductionOrder = Selection.OrderDocument;
						NewRow.ProductionStage = Selection.Stage;
					ElsIf Selection.AddToTasks
						And Not Selection.DynamicStructure Then
						Stages.Add(Selection.Stage);
					EndIf;
				Else
					Enabled = Enabled - Selection.Load;
				EndIf;
			EndDo;
			
		EndDo;
		
	EndDo;
	
	If TasksToAdd.Count() > 0 Then
		InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddTasks(TasksToAdd, True);
	EndIf;
	
	If Stages.Count() > 0 Then
		InformationRegisters.JobsToProductionScheduleCalculation.AddTasks(Stages);
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

Procedure CollapseRecordsByBusyResource() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager();
	Query.Text =
		"SELECT DISTINCT
		|	RECORDAUTONUMBER()       AS Queue,
		|	Enabled.Recorder AS Recorder
		|INTO TTRecorders_
		|FROM
		|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS Enabled
		|WHERE
		|	Enabled.Recorder REFS Document.ProductionStage2_2
		|	OR Enabled.Recorder REFS Document.ProductionScheduleRecorder
		|
		|GROUP BY
		|	Enabled.Recorder,
		|	Enabled.WorkCenterType,
		|	Enabled.IntervalDate,
		|	Enabled.SetupSettings,
		|	Enabled.ReferenceOrder,
		|	Enabled.Department,
		|	Enabled.Shift,
		|	Enabled.KeyLot,
		|	Enabled.Stage
		|
		|HAVING
		|	COUNT(Enabled.LineNumber) > 1
		|
		|INDEX BY
		|	Queue";
	Selection = Query.Execute().Select();
	Selection.Next();
	If Selection.Count = 0 Then
		Return;
	EndIf;
	
	QueryTextRecorders =
		"SELECT
		|	Recorders.Recorder AS Recorder
		|FROM
		|	TTRecorders_ AS Recorders
		|WHERE
		|	Recorders.Queue >= &BeginningOfQueue 
		|	AND Recorders.Queue < &EndOfQueue";
	
	QueryTextRegisterRecords = 
		"SELECT
		|	Enabled.Recorder       AS Recorder,
		|	Enabled.Period            AS Period,
		|	Enabled.WorkCenterType AS WorkCenterType,
		|	Enabled.IntervalDate     AS IntervalDate,
		|	Enabled.SetupSettings    AS SetupSettings,
		|	Enabled.ReferenceOrder      AS ReferenceOrder,
		|	Enabled.Department     AS Department,
		|	Enabled.Shift             AS Shift,
		|	Enabled.KeyLot        AS KeyLot,
		|	Enabled.Stage              AS Stage,
		|	SUM(Enabled.Busy)     AS Busy
		|FROM
		|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS Enabled
		|WHERE
		|	Enabled.Recorder IN (&Recorders)
		|
		|GROUP BY
		|	Enabled.SetupSettings,
		|	Enabled.WorkCenterType,
		|	Enabled.IntervalDate,
		|	Enabled.KeyLot,
		|	Enabled.Period,
		|	Enabled.Department,
		|	Enabled.ReferenceOrder,
		|	Enabled.Recorder,
		|	Enabled.Shift,
		|	Enabled.Stage
		|
		|HAVING
		|	SUM(Enabled.Busy) <> 0";
	
	BeginningOfQueue = 1;
	TheStructureOfTheSearch = New Structure("Recorder");
	
	While True Do
		Query.Text = QueryTextRecorders;
		Query.SetParameter("BeginningOfQueue", BeginningOfQueue);
		Query.SetParameter("EndOfQueue", BeginningOfQueue + 100);
		BeginningOfQueue = BeginningOfQueue + 100;
		
		Recorders = Query.Execute().Unload();
		If Recorders.Count() = 0 Then
			Break;
		EndIf;
		
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("AccumulationRegister.AvailabilityOfWorkCenterTypes.RecordSet");
			LockItem.DataSource = Recorders;
			LockItem.UseFromDataSource("Recorder", "Recorder");
			Block.Lock();
			
			Query.Text = QueryTextRegisterRecords;
			Query.SetParameter("Recorders", Recorders.UnloadColumn("Recorder"));
			AllRegisteredRecords = Query.Execute().Unload();
			AllRegisteredRecords.Indexes.Add("Recorder");
			
			For Each String In Recorders Do
				Set = AccumulationRegisters.AvailabilityOfWorkCenterTypes.CreateRecordSet();
				Set.Filter.Recorder.Set(String.Recorder);
				
				TheStructureOfTheSearch.Recorder = String.Recorder;
				RegisterRecords = AllRegisteredRecords.Copy(TheStructureOfTheSearch);
				If RegisterRecords.Count() > 0 Then
					Set.Load(RegisterRecords);
				EndIf;
				
				Set.Write();
			EndDo;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			WriteLogEvent(
				NStr("vi = 'Mức độ khả dụng của các dạng nguồn lực sản xuất. Thu gọn bản ghi';
					|ru = 'Доступность видов рабочих центров.Сворачивание записей';
					|en = 'Capacity of work center types.Collapse records'; fa = 'Capacity of work center types.Collapse records';
					|it = 'Доступность видов рабочих центров.Сворачивание записей';
					|pl = 'Capacity of work center types.Collapse records';
					|tr = 'İş merkezi türleri kapasitesi. Kayıtların daraltılması'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndDo;
	
EndProcedure

Procedure ClearDownloadHistoryOfWorkCenterViews() Export
	
	SetPrivilegedMode(True);
	
	CleaningBoundary = BegOfMonth(CurrentSessionDate() - 7*24*60*60);
	
	Query = New Query(
		"SELECT
		|	ProductionScheduleRecorder.Ref AS Ref,
		|	&DocumentNameChartLogger       AS DocumentName
		|FROM
		|	Document.ProductionScheduleRecorder AS ProductionScheduleRecorder
		|WHERE
		|	ProductionScheduleRecorder.Date < &CleaningBoundary
		|
		|UNION ALL
		|
		|SELECT TOP 500
		|	AvailabilityOfWorkCenterType.Ref AS Ref,
		|	&DocumentNameAvailabilityOfRCType       AS DocumentName
		|FROM
		|	Document.AvailabilityOfWorkCenterType AS AvailabilityOfWorkCenterType
		|WHERE
		|	AvailabilityOfWorkCenterType.Date < &CleaningBoundary
		|
		|UNION ALL
		|
		|SELECT TOP 500
		|	AvailabilityOfWorkCenters.Ref AS Ref,
		|	&DocumentNameAvailabilityRC       AS DocumentName
		|FROM
		|	Document.AvailabilityOfWorkCenters AS AvailabilityOfWorkCenters
		|WHERE
		|	AvailabilityOfWorkCenters.Date < &CleaningBoundary");
	
	Query.SetParameter("CleaningBoundary", CleaningBoundary);
	Query.SetParameter("DocumentNameChartLogger", "Document.ProductionScheduleRecorder");
	Query.SetParameter("DocumentNameAvailabilityOfRCType", "Document.AvailabilityOfWorkCenterType");
	Query.SetParameter("DocumentNameAvailabilityRC", "Document.AvailabilityOfWorkCenters");
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			
			Block = New DataLock;
			Block.Add(Selection.DocumentName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			DocumentObject = Selection.Ref.GetObject();
			
			If Not DocumentObject = Undefined Then
				
				For Each RegisterRecords In DocumentObject.RegisterRecords Do
					RegisterRecords.Write = True;
				EndDo;
				
				DocumentObject.RegisterRecords.Write();
				DocumentObject.Delete();
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			WriteLogEvent(
				NStr("vi = 'Mức độ khả dụng của dạng nguồn lực làm việc. Xóa lịch sử kết nhập';
					|ru = 'Доступность видов рабочих центров.Очистка истории загрузки';
					|en = 'Capacity of work center types.Clear load history'; fa = 'Capacity of work center types.Clear load history';
					|it = 'Доступность видов рабочих центров.Очистка истории загрузки';
					|pl = 'Capacity of work center types.Clear load history';
					|tr = 'İş merkezi türleri kapasitesi. İndirme geçmişinin temizlenmesi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndDo;

EndProcedure

#EndRegion

#EndIf
