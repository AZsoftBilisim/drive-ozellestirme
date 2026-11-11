#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  - ValueTableRow
//  - Undefined
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.MonitorOrder)
		And ProductionManagementCached.TheProductionScheduleIsUsed() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Id               = Metadata.Reports.MonitorOrder.FullName();
		ReportCommand.Presentation               = NStr("vi = 'Màn hình kiểm soát đơn hàng';
														|ru = 'Мониторинг заказа';
														|en = 'Monitor order'; fa = 'پایش سفارش';
														|it = 'Monitoraggio ordine';
														|pl = 'Monitorowanie zamówienia';
														|tr = 'Sipariş takibi'");
		ReportCommand.Manager                    = "Report.MonitorOrder";
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance      = "Ordinary";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.MonitorOrder);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Generates a report.
//
// Parameters:
//  Parameters  - Structure - report generation parameters:
//		* GanttChart - GanttChart - Gantt chart.
//		* ProductionOrder - DocumentRef.ProductionOrder2_2 - production order.
//		* ScheduleStatus - Number - status of the graph being diagnosed.
//		* ViewMode - Number - report display mode (see the Display Modes function).
//  StorageAddress - String - address of the storage where the report generation result will be placed.
//
Procedure GenerateReport(Parameters, StorageAddress) Export
	
	GanttChart = Parameters.GanttChart;
	ProductionOrder = Parameters.ProductionOrder;
	ViewMode = Parameters.ViewMode;
	ScheduleStatus = Parameters.ScheduleStatus;
	Boundaries = New Structure("Begin, Ending", '39991231', '00010101');
	
	If ViewMode = ModeByDivision()
		Or ViewMode = ModeByTypeOfWorkCenters() Then
		
		GenerateReportOnPerformers(GanttChart, ProductionOrder, ViewMode, ScheduleStatus, Boundaries);
		
	ElsIf ViewMode = ModeOfManufacturingProducts() Then
		
		GenerateReportOnStartupBatches(GanttChart, ProductionOrder, ScheduleStatus, Boundaries);
		
	EndIf;
	
	PutToTempStorage(GanttChart, StorageAddress);
	
EndProcedure

// Display modes.
// 
// Returns:
//  Structure - Display Modes:
// * ByProducts - Number - index of the "By product" mode
// * ByBusinessUnits - Number - index of the "By division" mode
// * ByTypeOfWorkCenters - Number - mode index "By types of RC"
Function ViewModes() Export
	
	Modes = New Structure();
	Modes.Insert("ByProducts", ModeOfManufacturingProducts());
	Modes.Insert("ByBusinessUnits", ModeByDivision());
	Modes.Insert("ByTypeOfWorkCenters", ModeByTypeOfWorkCenters());
	Return Modes;
	
EndFunction

#EndRegion

#Region Private

#Region ByDivisionsAndTypesOfWorkCenters

Procedure GenerateReportOnPerformers(GanttChart, ProductionOrder, ViewMode, ScheduleStatus, Boundaries)
	
	GanttChart.RefreshEnabled = False;
	
	SetPrivilegedMode(True);
	Schedule = ScheduleByArtist(ProductionOrder, ViewMode, ScheduleStatus, Boundaries);
	SetPrivilegedMode(False);
	
	Series = GanttChart.SetSeries("ProductionSchedule");
	
	Performer = Undefined;
	For IndexOf = 0 To Schedule.Count()-1 Do
		
		String = Schedule[IndexOf];
		If Performer = Undefined
			Or Not Performer = String.Performer Then
			
			Point = SetAccessPoint(GanttChart, String);
			Value = GanttChart.GetValue(Point, Series);
			
		EndIf;
		
		AddIntervalPerformer(Value, String);
		
	EndDo;
	
	GanttChart.RefreshEnabled = False;
	
EndProcedure

Function ScheduleByArtist(ProductionOrder, ViewMode, ScheduleStatus, Boundaries)
	
	Result = InitializeScheduleByArtist();
	
	Query = InitializeRequestForPerformers(ProductionOrder, ViewMode, ScheduleStatus);
	
	SampleResults = Query.Execute().Select(QueryResultIteration.ByGroups);
	If SampleResults.Next() Then
		
		FillPropertyValues(Boundaries, SampleResults);
		
		SampleArtist = SampleResults.Select(QueryResultIteration.ByGroups);
		While SampleArtist.Next() Do
			
			PreviousString = Undefined;
			
			Selection = SampleArtist.Select();
			While Selection.Next() Do
				
				If PreviousString = Undefined
					Or (PreviousString.Ending + 1) < Selection.Begin Then
					
					NewRow = Result.Add();
					FillPropertyValues(NewRow, Selection);
					
					PreviousString = NewRow;
					
				Else
					
					PreviousString.Ending = Max(PreviousString.Ending, Selection.Ending);
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function InitializeScheduleByArtist()
	
	TypesOfPerformers = New Array;
	TypesOfPerformers.Add(Type("CatalogRef.BusinessStructure"));
	TypesOfPerformers.Add(Type("CatalogRef.WorkCenterTypes"));
	
	Result = New ValueTable;
	Result.Columns.Add("Performer", New TypeDescription(TypesOfPerformers));
	Result.Columns.Add("Presentation", New TypeDescription("String"));
	Result.Columns.Add("Begin", New TypeDescription("Date"));
	Result.Columns.Add("Ending", New TypeDescription("Date"));
	
	Return Result;
	
EndFunction

Function InitializeRequestForPerformers(ProductionOrder, ViewMode, ScheduleStatus)
	
	TempTablesManager = New TempTablesManager;
	
	If ViewMode = ModeByDivision() Then
		QueryText = RequestTextScheduleByDivision(ScheduleStatus);
	Else
		
		Query = New Query("
		|SELECT
		|	MIN(AvailabilityOfWorkCenterTypes.IntervalDate) AS MinDate_,
		|	MAX(AvailabilityOfWorkCenterTypes.IntervalDate) AS MaxDate_,
		|	AvailabilityOfWorkCenterTypes.Shift AS Shift
		|FROM
		|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS AvailabilityOfWorkCenterTypes
		|WHERE
		|	AvailabilityOfWorkCenterTypes.ReferenceOrder = &ProductionOrder
		|	AND AvailabilityOfWorkCenterTypes.Shift <> VALUE(Catalog.Calendars.EmptyRef)
		|	AND AvailabilityOfWorkCenterTypes.Busy <> 0
		|
		|GROUP BY
		|	AvailabilityOfWorkCenterTypes.Shift");
		
		Query.SetParameter("ProductionOrder", ProductionOrder);
		ShiftsAndDates = Query.Execute().Unload();
		
		FullIntervalStart = '00010101';
		FullIntervalEnding = '00010101';
		ShiftSchedules = New Array;
		
		If ShiftsAndDates.Count() <> 0 Then
			FullIntervalStart = ShiftsAndDates[0].MinDate_;
			FullIntervalEnding = ShiftsAndDates[0].MaxDate_;
			For Each String In ShiftsAndDates Do
				FullIntervalStart = Min(FullIntervalStart, String.MinDate_);
				FullIntervalEnding = Max(FullIntervalStart, String.MaxDate_);
				ShiftSchedules.Add(String.Shift);
			EndDo;
		EndIf;
		
		CalendarSchedules.CreateTTWorkSchedulesForPeriod(
			TempTablesManager, ShiftSchedules, FullIntervalStart - 86400 * 4, FullIntervalEnding + 86400 * 4, False);
		
		QueryText = RequestTextGraphByRCType(ScheduleStatus);
	EndIf;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.SetParameter("ScheduleStatus", ScheduleStatus);
	Query.SetParameter("StatusWorkingSchedule", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	
	Return Query;
	
EndFunction

Function RequestTextScheduleByDivision(ScheduleStatus)
	
	If ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule() Then
		
		Result = 
		"SELECT
		|	ScheduleOfProductionStages2_2.Stage.Department AS Performer,
		|	ScheduleOfProductionStages2_2.Stage.Department.Presentation AS Presentation,
		|	ScheduleOfProductionStages2_2.Begin AS Begin,
		|	ScheduleOfProductionStages2_2.Ending AS Ending
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|WHERE
		|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
		|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &ScheduleStatus
		|	AND NOT ScheduleOfProductionStages2_2.Stage IN (UNDEFINED, VALUE(Catalog.ProductionStages.EmptyRef), VALUE(Document.ProductionStage2_2.EmptyRef))
		|
		|ORDER BY
		|	Performer,
		|	Begin,
		|	Ending
		|TOTALS
		|	MIN(Begin),
		|	MAX(Ending)
		|BY
		|	OVERALL,
		|	Performer";
		
	Else
		
		Result =
		"SELECT
		|	ScheduleOfProductionStages2_2.Stage.Department AS Performer,
		|	ScheduleOfProductionStages2_2.Stage.Department.Presentation AS Presentation,
		|	ScheduleOfProductionStages2_2.Begin AS Begin,
		|	ScheduleOfProductionStages2_2.Ending AS Ending
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|WHERE
		|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
		|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &ScheduleStatus
		|	AND NOT ScheduleOfProductionStages2_2.Stage IN (UNDEFINED, VALUE(Catalog.ProductionStages.EmptyRef), VALUE(Document.ProductionStage2_2.EmptyRef))
		|
		|UNION ALL
		|
		|SELECT
		|	ScheduleOfProductionStages2_2.Stage.Department,
		|	ScheduleOfProductionStages2_2.Stage.Department.Presentation,
		|	ScheduleOfProductionStages2_2.Begin,
		|	ScheduleOfProductionStages2_2.Ending
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|WHERE
		|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
		|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &StatusWorkingSchedule
		|	AND NOT (ScheduleOfProductionStages2_2.Stage, ScheduleOfProductionStages2_2.KeyLot) IN
		|				(SELECT
		|					DD.Stage,
		|					DD.KeyLot
		|				FROM
		|					InformationRegister.ScheduleOfProductionStages2_2 AS DD
		|				WHERE
		|					DD.ProductionOrder = &ProductionOrder
		|					AND DD.ScheduleStatus = &ScheduleStatus)
		|	AND NOT ScheduleOfProductionStages2_2.Stage IN (UNDEFINED, VALUE(Catalog.ProductionStages.EmptyRef), VALUE(Document.ProductionStage2_2.EmptyRef))
		|
		|ORDER BY
		|	Performer,
		|	Begin,
		|	Ending
		|TOTALS
		|	MIN(Begin),
		|	MAX(Ending)
		|BY
		|	OVERALL,
		|	Performer";
		
	EndIf;
	
	Return Result;
	
EndFunction

Function RequestTextGraphByRCType(ScheduleStatus)
	
	Result = "
		|SELECT
		|	Schedule.WorkScheduleCalendar AS Shift,
		|	MIN(DATEADD(Schedule.ScheduleDate, MINUTE,
		|		HOUR(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)))*60
		|		+ MINUTE(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1))))) AS Begin,
		|	MAX(
		|		CASE
		|			WHEN Schedule.EndTime IS NULL 
		|				OR Schedule.EndTime = DATETIME(1, 1, 1)
		|				THEN DATEADD(Schedule.ScheduleDate, DAY, 1)
		|			ELSE DATEADD(Schedule.ScheduleDate, MINUTE,
		|				HOUR(Schedule.EndTime)*60 + MINUTE(Schedule.EndTime))
		|		END) AS Ending
		|INTO TTShiftIntervals
		|FROM
		|	TTWorkSchedules AS Schedule
		|
		|GROUP BY
		|	Schedule.WorkScheduleCalendar,
		|	Schedule.Period";
	
	Result = Result + Common.QueryBatchSeparator();
	
	If ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule() Then
		
		Result = Result +
		"SELECT
		|	AvailabilityOfWorkCenterTypes.WorkCenterType AS Performer,
		|	AvailabilityOfWorkCenterTypes.WorkCenterType.Presentation AS Presentation,
		|	AvailabilityOfWorkCenterTypes.IntervalDate AS Begin,
		|	CASE AvailabilityOfWorkCenterTypes.WorkCenterType.Department.PlanningInterval
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
		|			THEN ENDOFPERIOD(AvailabilityOfWorkCenterTypes.IntervalDate, HOUR)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
		|			THEN ENDOFPERIOD(AvailabilityOfWorkCenterTypes.IntervalDate, DAY)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
		|			THEN ENDOFPERIOD(AvailabilityOfWorkCenterTypes.IntervalDate, WEEK)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
		|			THEN ENDOFPERIOD(AvailabilityOfWorkCenterTypes.IntervalDate, MONTH)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
		|			THEN ShiftIntervals.Ending
		|		ELSE ENDOFPERIOD(AvailabilityOfWorkCenterTypes.IntervalDate, DAY)
		|	END AS Ending
		|FROM
		|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS AvailabilityOfWorkCenterTypes
		|		LEFT JOIN TTShiftIntervals AS ShiftIntervals
		|		ON ShiftIntervals.Shift = AvailabilityOfWorkCenterTypes.Shift
		|		AND ShiftIntervals.Begin = AvailabilityOfWorkCenterTypes.IntervalDate
		|WHERE
		|	AvailabilityOfWorkCenterTypes.ReferenceOrder = &ProductionOrder
		|
		|GROUP BY
		|	AvailabilityOfWorkCenterTypes.WorkCenterType,
		|	AvailabilityOfWorkCenterTypes.IntervalDate,
		|	ShiftIntervals.Ending
		|
		|HAVING
		|	SUM(AvailabilityOfWorkCenterTypes.Busy) <> 0
		|
		|ORDER BY
		|	Performer,
		|	Begin,
		|	Ending
		|TOTALS
		|	MIN(Begin),
		|	MAX(Ending)
		|BY
		|	OVERALL,
		|	Performer";
		
	Else
		
		Result = Result +
		"SELECT
		|	AvailabilityOfWorkCenterTypes.WorkCenterType AS Performer,
		|	AvailabilityOfWorkCenterTypes.WorkCenterType.Presentation AS Presentation,
		|	AvailabilityOfWorkCenterTypes.IntervalDate AS Begin,
		|	CASE AvailabilityOfWorkCenterTypes.WorkCenterType.Department.PlanningInterval
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
		|			THEN ENDOFPERIOD(AvailabilityOfWorkCenterTypes.IntervalDate, HOUR)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
		|			THEN ENDOFPERIOD(AvailabilityOfWorkCenterTypes.IntervalDate, DAY)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
		|			THEN ENDOFPERIOD(AvailabilityOfWorkCenterTypes.IntervalDate, WEEK)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
		|			THEN ENDOFPERIOD(AvailabilityOfWorkCenterTypes.IntervalDate, MONTH)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
		|			THEN ShiftIntervals.Ending
		|		ELSE ENDOFPERIOD(AvailabilityOfWorkCenterTypes.IntervalDate, DAY)
		|	END AS Ending
		|FROM
		|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS AvailabilityOfWorkCenterTypes
		|		LEFT JOIN TTShiftIntervals AS ShiftIntervals
		|		ON ShiftIntervals.Shift = AvailabilityOfWorkCenterTypes.Shift
		|		AND ShiftIntervals.Begin = AvailabilityOfWorkCenterTypes.IntervalDate
		|WHERE
		|	AvailabilityOfWorkCenterTypes.ReferenceOrder = &ProductionOrder
		|	AND NOT (AvailabilityOfWorkCenterTypes.Stage, AvailabilityOfWorkCenterTypes.KeyLot) IN
		|				(SELECT DISTINCT
		|					LoadPlanning.Stage,
		|					LoadPlanning.KeyLot
		|				FROM
		|					InformationRegister.CreatingScheduleForWorkCenterTypes AS LoadPlanning
		|				WHERE
		|					LoadPlanning.ReferenceOrder = &ProductionOrder
		|					AND LoadPlanning.ScheduleStatus = &ScheduleStatus)
		|
		|GROUP BY
		|	AvailabilityOfWorkCenterTypes.WorkCenterType,
		|	AvailabilityOfWorkCenterTypes.IntervalDate,
		|	ShiftIntervals.Ending
		|
		|HAVING
		|	SUM(AvailabilityOfWorkCenterTypes.Busy) <> 0
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	LoadPlanning.WorkCenterType,
		|	LoadPlanning.WorkCenterType.Presentation,
		|	LoadPlanning.IntervalDate,
		|	CASE LoadPlanning.WorkCenterType.Department.PlanningInterval
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
		|			THEN ENDOFPERIOD(LoadPlanning.IntervalDate, HOUR)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
		|			THEN ENDOFPERIOD(LoadPlanning.IntervalDate, DAY)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
		|			THEN ENDOFPERIOD(LoadPlanning.IntervalDate, WEEK)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
		|			THEN ENDOFPERIOD(LoadPlanning.IntervalDate, MONTH)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
		|			THEN ShiftIntervals.Ending
		|		ELSE ENDOFPERIOD(LoadPlanning.IntervalDate, DAY)
		|	END
		|FROM
		|	InformationRegister.CreatingScheduleForWorkCenterTypes AS LoadPlanning
		|		LEFT JOIN TTShiftIntervals AS ShiftIntervals
		|		ON ShiftIntervals.Shift = LoadPlanning.Shift
		|		AND ShiftIntervals.Begin = LoadPlanning.IntervalDate
		|WHERE
		|	LoadPlanning.ReferenceOrder = &ProductionOrder
		|	AND LoadPlanning.ScheduleStatus = &ScheduleStatus
		|
		|ORDER BY
		|	Performer,
		|	Begin,
		|	Ending
		|TOTALS
		|	MIN(Begin),
		|	MAX(Ending)
		|BY
		|	OVERALL,
		|	Performer";
		
	EndIf;
	
	Return Result;
	
EndFunction

Function SetAccessPoint(GanttChart, Data)
	
	Result = GanttChart.SetPoint(Data.Performer);
	Result.Text = Data.Presentation;
	Result.Details = Data.Performer;
	
	Return Result;
	
EndFunction

Procedure AddIntervalPerformer(Value, Data)
	
	Interval = Value.Add();
	Interval.Begin = Data.Begin;
	Interval.End = Data.Ending + 1;
	Interval.Color = WebColors.Green;
	
EndProcedure

#EndRegion

#Region ByStartingBatches

Procedure GenerateReportOnStartupBatches(GanttChart, ProductionOrder, ScheduleStatus, Boundaries)
	
	GanttChart.RefreshEnabled = False;
	
	Data = ScheduleAndDependenciesByLaunchBatch(ProductionOrder, ScheduleStatus);
	ProductSelection_ = Data.ProductSelection_;
	
	If ProductSelection_.Count() > 0 Then
		
		Series = GanttChart.SetSeries("ProductionSchedule");
		
		Intervals = New ValueTable;
		Intervals.Columns.Add("ProductionLot");
		Intervals.Columns.Add("Interval");
		
		Intervals.Indexes.Add("ProductionLot");
		
		While ProductSelection_.Next() Do
			
			Boundaries.Begin = Min(Boundaries.Begin, ProductSelection_.Begin);
			Boundaries.Ending = Max(Boundaries.Ending, ProductSelection_.Ending);
			
			Point = SetStartingPoint(GanttChart, ProductSelection_);
			Value = GanttChart.GetValue(Point, Series);
			Interval = AddIntervalToRun(Value, ProductSelection_);
			
			NewRow = Intervals.Add();
			NewRow.ProductionLot = ProductSelection_.ProductionLot;
			NewRow.Interval = Interval;
			
		EndDo;
		
		OrderType_5 = Common.ObjectAttributeValue(ProductionOrder, "ProductionProcessType");
		If OrderType_5 <> Enums.ProductionProcessTypes.Repair
			And OrderType_5 <> Enums.ProductionProcessTypes.PerformRM Then
			
			AddIntervalLinks(Data.Dependencies, Intervals)
			
		EndIf;
		
	EndIf;
	
	GanttChart.RefreshEnabled = False;
	
EndProcedure

// Returns the schedule and dependencies by launch batches
//
// Parameters:
//  ProductionOrder - DocumentRef.ProductionOrder2_2 - order.
//  ScheduleStatus - Number - status of the production schedule.
//
// Returns:
//  Structure - Contains:
//   * ProductSelection_ - QueryResultSelection - Contains:
//   * Dependencies - ValueTable - 
//
Function ScheduleAndDependenciesByLaunchBatch(ProductionOrder, ScheduleStatus)
	
	BatchQueryText = New Array;
	
	If ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule() Then
		
		QueryText = 
		"SELECT
		|	ScheduleOfProductionStages2_2.Stage.ProductionLot AS ProductionLot,
		|	MIN(ScheduleOfProductionStages2_2.Begin) AS Begin,
		|	MAX(ScheduleOfProductionStages2_2.Ending) AS Ending
		|INTO TTProductionSchedule
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|WHERE
		|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
		|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &ScheduleStatus
		|
		|GROUP BY
		|	ScheduleOfProductionStages2_2.Stage.ProductionLot
		|
		|INDEX BY
		|	ProductionLot";
		
	Else
		
		QueryText = 
		"SELECT
		|	ScheduleOfProductionStages2_2.Stage,
		|	ScheduleOfProductionStages2_2.Begin,
		|	ScheduleOfProductionStages2_2.Ending
		|INTO VTGrafikByStatus
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|WHERE
		|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
		|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &ScheduleStatus
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Stage.ProductionLot AS ProductionLot,
		|	MIN(NestedQuery.Begin) AS Begin,
		|	MAX(NestedQuery.Ending) AS Ending
		|INTO TTProductionSchedule
		|FROM
		|	(SELECT
		|		VTGrafikByStatus.Stage AS Stage,
		|		VTGrafikByStatus.Begin AS Begin,
		|		VTGrafikByStatus.Ending AS Ending
		|	FROM
		|		VTGrafikByStatus AS VTGrafikByStatus
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ScheduleOfProductionStages2_2.Stage,
		|		ScheduleOfProductionStages2_2.Begin,
		|		ScheduleOfProductionStages2_2.Ending
		|	FROM
		|		InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|	WHERE
		|		ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
		|		AND ScheduleOfProductionStages2_2.ScheduleStatus = &StatusWorkingSchedule
		|		AND NOT ScheduleOfProductionStages2_2.Stage IN
		|					(SELECT
		|						VTGrafikByStatus.Stage
		|					FROM
		|						VTGrafikByStatus)) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Stage.ProductionLot
		|
		|INDEX BY
		|	ProductionLot";
		
	EndIf;
	BatchQueryText.Add(QueryText);
	
	QueryText =
	"SELECT DISTINCT
	|	Products_1.Ref AS Sender,
	|	Products_1.StageConsumer AS Recipient
	|INTO TTCommunicationProducts
	|FROM
	|	Document.ProductionStage2_2.ManufacturedProducts AS Products_1
	|		LEFT JOIN Document.ProductionStage2_2 AS Document
	|		ON Products_1.Ref = Document.Ref
	|WHERE
	|	Document.ReferenceOrder = &ProductionOrder
	|	AND Document.Posted
	|	AND NOT Products_1.Canceled
	|	AND Products_1.StageConsumer <> VALUE(Document.ProductionStage2_2.EmptyRef)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Products_1.Ref,
	|	Products_1.StageConsumer
	|FROM
	|	Document.ProductionStage2_2.SideAndIntermediateRelease AS Products_1
	|		LEFT JOIN Document.ProductionStage2_2 AS Document
	|		ON Products_1.Ref = Document.Ref
	|WHERE
	|	Document.ReferenceOrder = &ProductionOrder
	|	AND Document.Posted
	|	AND NOT Products_1.Canceled
	|	AND Products_1.StageConsumer <> VALUE(Document.ProductionStage2_2.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Schedule.ProductionLot          AS ProductionLot,
	|	Schedule.Begin                      AS Begin,
	|	Schedule.Ending                   AS Ending,
	|	Lot.MainProductProducts AS Products,
	|	Lot.MainProductProducts.Presentation AS ProductsPresentation
	|FROM
	|	TTProductionSchedule AS Schedule
	|		LEFT JOIN Catalog.ProductionLots AS Lot
	|		ON Schedule.ProductionLot = Lot.Ref
	|
	|ORDER BY
	|	Begin,
	|	Ending
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	StageSender.ProductionLot AS ProductionLot,
	|	RecipientStage.ProductionLot AS NextStage
	|FROM
	|	TTCommunicationProducts AS TTCommunicationProducts
	|		LEFT JOIN Document.ProductionStage2_2 AS StageSender
	|		ON TTCommunicationProducts.Sender = StageSender.Ref
	|		LEFT JOIN Document.ProductionStage2_2 AS RecipientStage
	|		ON TTCommunicationProducts.Recipient = RecipientStage.Ref
	|WHERE
	|	StageSender.ProductionLot <> RecipientStage.ProductionLot";
	BatchQueryText.Add(QueryText);
	
	Separator =
	"
	|;
	|/////////////////////////////////////////////////////////////
	|";
	QueryText = StrConcat(BatchQueryText, Separator);
	
	Query = New Query(QueryText);
	
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.SetParameter("ScheduleStatus", ScheduleStatus);
	Query.SetParameter("StatusWorkingSchedule", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	
	ResultsArray = Query.ExecuteBatch();
	MaxIndex_ = ResultsArray.UBound();
	
	Result = New Structure;
	
	Result.Insert(
		"ProductSelection_",
		ResultsArray[MaxIndex_-1].Select());
	
	Result.Insert(
		"Dependencies",
		ResultsArray[MaxIndex_].Unload());
	
	Return Result;
	
EndFunction

Function SetStartingPoint(GanttChart, ProductSelection_)
	
	PointValue = ProductSelection_.ProductionLot;
	Result = GanttChart.SetPoint(PointValue);
	
	Result.Text = ProductSelection_.ProductsPresentation;
	Result.Details = ProductSelection_.ProductionLot;
	
	Return Result;
	
EndFunction

Function AddIntervalToRun(Value, ProductSelection_)
	
	Result = Value.Add();
	Result.Begin = ProductSelection_.Begin;
	Result.End = ProductSelection_.Ending;
	Result.Details = New Structure("ProductionLot, Type", ProductSelection_.ProductionLot, "Lot");
	Result.Color = WebColors.Green;
	
	Return Result;
	
EndFunction

Procedure AddIntervalLinks(Dependencies, Intervals)
	
	For Each StringDependency In Dependencies Do
		
		FoundRow = Intervals.Find(StringDependency.ProductionLot, "ProductionLot");
		If Not FoundRow = Undefined Then
			
			Interval = FoundRow.Interval; // GanttChartInterval - 
			
			FoundRow = Intervals.Find(StringDependency.NextStage, "ProductionLot");
			If Not FoundRow = Undefined Then
				
				NextInterval_ = FoundRow.Interval;
				
				Link = Interval.Add(NextInterval_);
				Link.LinkType = GanttChartLinkType.EndBegin;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function ModeOfManufacturingProducts()

	Return 0;
	
EndFunction

Function ModeByDivision()
	
	Return 1;
	
EndFunction

Function ModeByTypeOfWorkCenters()
	
	Return 2;
	
EndFunction

#EndRegion

#EndRegion

#EndIf