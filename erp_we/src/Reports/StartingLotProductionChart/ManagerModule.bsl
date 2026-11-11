#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Generates a report.
//
// Parameters:
//  Parameters  - Structure - report generation parameters:
//		* ProductionLot - CatalogRef.ProductionLots - the production batch
//			that needs to be displayed in the report.
//		* ScheduleStatus - Number - the Status of the displayed graph.
//		* ProductionOrder - DocumentRef.ProductionOrder2_2
//		* KeyLot - UUID
//  StorageAddress - String - address of the storage where the report generation result will be placed.
//
Procedure GenerateReport(Parameters, StorageAddress) Export
	
	GanttChart = New GanttChart;
	ConfigureGeneralChartProperties(GanttChart);
	
	Boundaries = New Structure("Begin, Ending", '39991231', '00010101');
	
	GetDataAndDisplayItInChart(
		GanttChart,
		Parameters,
		Boundaries);
	
	AdjustChartTimeline(GanttChart, Boundaries);
	
	PutToTempStorage(GanttChart, StorageAddress);
	
EndProcedure

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
Function AddLaunchBatchScheduleCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.StartingLotProductionChart)
		And ProductionManagementCached.TheProductionScheduleIsUsed() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Id      = Metadata.Reports.StartingLotProductionChart.FullName();
		ReportCommand.Presentation      = NStr("vi = 'Lịch trình khởi động';
												|ru = 'График партии запуска';
												|en = 'Starting lot schedule'; fa = 'Starting lot schedule';
												|it = 'Grafico del lotto di lancio';
												|pl = 'Harmonogram partii startu';
												|tr = 'Başlatma lotu programı'");
		ReportCommand.FormName           = "Report.StartingLotProductionChart.Form";
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance           = "Ordinary";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StartingLotProductionChart);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure GetDataAndDisplayItInChart(GanttChart, Parameters, Boundaries)

	GanttChart.RefreshEnabled = False;
	
	Data = GraphAndDependenciesByChainStages(Parameters);
	
	If Data.Stages.Count() > 0 Then
		
		Series = DefaultSeries(GanttChart);
		
		Intervals = New Map;
		For Each String In Data.Stages Do
			
			Boundaries.Begin = Min(Boundaries.Begin, String.Begin);
			Boundaries.Ending = Max(Boundaries.Ending, String.Ending);
			
			Point = SetPointForChain(GanttChart, String);
			Value = GanttChart.GetValue(Point, Series);
			Interval = AddIntervalStageChain(Value, String);
			
			Intervals.Insert(String.Stage, Interval);
			
		EndDo;
		
		// Connections between stages.
		For Each String In Data.Dependencies Do
			
			Interval = Intervals.Get(String.Stage); // GanttChartInterval - 
			NextInterval_ = Intervals.Get(String.NextStage);
			
			If Not Interval = Undefined
				And Not NextInterval_ = Undefined Then
				
				Link = Interval.Add(NextInterval_);
				Link.LinkType = GanttChartLinkType.EndBegin;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	GanttChart.RefreshEnabled = False;
	
EndProcedure

// Returns a graph and dependence on the stages of the chain
// 
// Parameters:
//  Parameters - Structure - Parameters:
// * ProductionLot - CatalogRef.ProductionLots - Party.
// * ScheduleStatus - Number - status of the production schedule.
// * ProductionOrder - DocumentRef.ProductionOrder2_2 - 
// * KeyLot - UUID - 
// 
// Returns:
//  Structure - Contains:
//   * Stages - ValueTable - Contains:
//   * Dependencies - ValueTable - 
Function GraphAndDependenciesByChainStages(Parameters)
	
	BatchQueryText = New Array;
	
	If Parameters.ScheduleStatus = StatusWorkingSchedule() Then
		
		QueryText =	
		"SELECT
		|	T.Stage,
		|	T.Begin AS Begin,
		|	T.Ending AS Ending,
		|	&KeyLot AS KeyLot,
		|	&PresentationStage AS PresentationStage,
		|	CASE
		|		WHEN T.Stage.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS Completed,
		|	CASE
		|		WHEN VALUETYPE(T.Stage) = TYPE(Document.ProductionStage2_2)
		|			THEN T.Stage.StagePlacementInProductionSchedule
		|		ELSE FALSE
		|	END AS ManualPlacement,
		|	ISNULL(StandardScheduleOfProductionStages.DurationBeforeStart, -T.Order) AS OrderField
		|INTO StageData_1
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS T
		|		LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS StandardScheduleOfProductionStages
		|		ON T.Stage = StandardScheduleOfProductionStages.ProductionStage
		|WHERE
		|	(T.Stage.ProductionLot = &ProductionLot
		|	OR T.ProductionOrder = &ProductionOrder AND T.KeyLot = &KeyLot)
		|	AND T.Stage <> VALUE(Catalog.ProductionStages.EmptyRef)
		|	AND T.ScheduleStatus = &ScheduleStatus";
		
	Else
		
		QueryText =
		"SELECT
		|	ScheduleOfProductionStages2_2.Stage,
		|	ScheduleOfProductionStages2_2.Begin AS Begin,
		|	ScheduleOfProductionStages2_2.Ending AS Ending,
		|	ScheduleOfProductionStages2_2.Order
		|INTO VTGrafikByStatus
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|WHERE
		|	(ScheduleOfProductionStages2_2.Stage.ProductionLot = &ProductionLot
		|	OR ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder AND ScheduleOfProductionStages2_2.KeyLot = &KeyLot)
		|	AND ScheduleOfProductionStages2_2.Stage <> VALUE(Catalog.ProductionStages.EmptyRef)
		|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &ScheduleStatus
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Stage,
		|	T.Begin,
		|	T.Ending,
		|	&KeyLot AS KeyLot,
		|	&PresentationStage AS PresentationStage,
		|	T.Completed,
		|	T.ManualPlacement,
		|	ISNULL(StandardScheduleOfProductionStages.DurationBeforeStart, -T.Order)
		|INTO StageData_1
		|FROM
		|	(SELECT
		|		VTGrafikByStatus.Stage AS Stage,
		|		VTGrafikByStatus.Begin AS Begin,
		|		VTGrafikByStatus.Ending AS Ending,
		|		CASE
		|			WHEN VTGrafikByStatus.Stage.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
		|				THEN TRUE
		|			ELSE FALSE
		|		END AS Completed,
		|		CASE
		|			WHEN VALUETYPE(VTGrafikByStatus.Stage) = TYPE(Document.ProductionStage2_2)
		|				THEN VTGrafikByStatus.Stage.StagePlacementInProductionSchedule
		|			ELSE FALSE
		|		END AS ManualPlacement,
		|		VTGrafikByStatus.Order AS Order
		|	FROM
		|		VTGrafikByStatus AS VTGrafikByStatus
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ScheduleOfProductionStages2_2.Stage,
		|		ScheduleOfProductionStages2_2.Begin,
		|		ScheduleOfProductionStages2_2.Ending,
		|		CASE
		|			WHEN ScheduleOfProductionStages2_2.Stage.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
		|				THEN TRUE
		|			ELSE FALSE
		|		END,
		|		CASE
		|			WHEN VALUETYPE(ScheduleOfProductionStages2_2.Stage) = TYPE(Document.ProductionStage2_2)
		|				THEN ScheduleOfProductionStages2_2.Stage.StagePlacementInProductionSchedule
		|			ELSE FALSE
		|		END,
		|		ScheduleOfProductionStages2_2.Order
		|	FROM
		|		InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|	WHERE
		|		ScheduleOfProductionStages2_2.Stage.ProductionLot = &ProductionLot
		|		AND ScheduleOfProductionStages2_2.ScheduleStatus = &StatusWorkingSchedule
		|		AND NOT ScheduleOfProductionStages2_2.Stage IN
		|					(SELECT
		|						VTGrafikByStatus.Stage
		|					FROM
		|						VTGrafikByStatus)) AS T
		|		LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS StandardScheduleOfProductionStages
		|		ON T.Stage = StandardScheduleOfProductionStages.ProductionStage";
		
	EndIf;
	
	QueryText = StrReplace(
		QueryText,
		"&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage("T.Stage"));
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("KeyLot", ?(ValueIsFilled(Parameters.KeyLot), Parameters.KeyLot, Parameters.ProductionLot.UUID()));
	Query.SetParameter("ProductionLot", Parameters.ProductionLot);
	Query.SetParameter("ProductionOrder", Parameters.ProductionOrder);
	Query.SetParameter("ScheduleStatus", Parameters.ScheduleStatus);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("StatusWorkingSchedule", StatusWorkingSchedule());
	
	Query.Execute();
	
	ProductionManagement.CreateVTLinksOfStages(TempTablesManager, "StageData_1", "Stage", "KeyLot", True, True);
	
	QueryText =
	"SELECT
	|	StageData_1.Stage,
	|	StageData_1.Begin AS Begin,
	|	StageData_1.Ending AS Ending,
	|	StageData_1.PresentationStage AS PresentationStage,
	|	StageData_1.Completed AS Completed,
	|	StageData_1.ManualPlacement AS ManualPlacement
	|FROM
	|	StageData_1 AS StageData_1
	|ORDER BY
	|	StageData_1.OrderField";
	BatchQueryText.Add(QueryText);
	
	QueryText =
	"SELECT
	|	TTCommunicationStages.Stage AS Stage,
	|	TTCommunicationStages.NextStage AS NextStage
	|FROM
	|	TTCommunicationStages AS TTCommunicationStages";
	BatchQueryText.Add(QueryText);
	
	Separator =
	"
	|;
	|/////////////////////////////////////////////////////////////
	|";
	QueryText = StrConcat(BatchQueryText, Separator);
	
	Query.Text = QueryText;
	
	ResultsArray = Query.ExecuteBatch();
	
	Result = New Structure;
	Result.Insert("Stages", ResultsArray[ResultsArray.UBound()-1].Unload());
	Result.Insert("Dependencies", ResultsArray[ResultsArray.UBound()].Unload());
	
	Return Result;
	
EndFunction

Function SetPointForChain(GanttChart, Data)
	
	Result = GanttChart.SetPoint(Data.Stage);
	Result.Text = Data.PresentationStage;
	Result.Details = Data.Stage;
	
	Return Result;
	
EndFunction

Function AddIntervalStageChain(Value, Data)
	
	Result = Value.Add();
	Result.Begin = Data.Begin;
	Result.End = Data.Ending;
	Result.Text = ChartIntervalText(
		Data.Begin, Data.Ending);
	Result.Details = Data.Stage;
	Result.Color = ColorIntervalStageChain(Data.Completed, Data.ManualPlacement);
	
	Return Result;
	
EndFunction

Function ColorIntervalStageChain(TheStepIsCompleted, ManualPlacement)
	
	If TheStepIsCompleted Then
		Result = StyleColors.BackgroundColorStageIsCompleted;
	Else
		If Not ManualPlacement Then
			Result = StyleColors.BackgroundColorStageIsNotCompletedPlannedAutomatically;
		Else
			Result = StyleColors.BackgroundColorStageIsNotCompletedPlannedManually;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ConfigureGeneralChartProperties(GanttChart)
	
	GanttChart.AutoDetectWholeInterval = False;
	GanttChart.ScaleKeeping = GanttChartScaleKeeping.AllData;
	GanttChart.Outline = False;
	GanttChart.ShowLegend = False;
	GanttChart.VerticalScroll = True;
	GanttChart.ShowEmptyValues = False;
	GanttChart.ShowTitle = False;
	GanttChart.ValueTextRepresentation = GanttChartValueTextRepresentation.None;
	GanttChart.PlotArea.Right = 1;
	GanttChart.IntervalTextRepresentation = GanttChartIntervalTextRepresentation.DontShow;
	
EndProcedure

Procedure AdjustChartTimeline(GanttChart, Boundaries)
	
	If Not ValueIsFilled(Boundaries.Ending) Then
		Return;
	EndIf;
	
	ScaleSettings = ProductionManagementClientServer.GanttChartScaleSettingsInAllDataMode(
		Boundaries.Begin, Boundaries.Ending, 9);
	
	TimelineElements = GanttChart.PlotArea.TimeScale.Items;
	
	For IndexOf = 1 To TimelineElements.Count()-1 Do
		TimelineElements.Delete(TimelineElements[IndexOf]);
	EndDo;
	
	ScaleElement = TimelineElements.Add();
	ScaleElement.Unit = ScaleSettings.Unit;
	ScaleElement.Format = ScaleSettings.Format;
	
	If TimelineElements.Count() = 2 Then
		TimelineElements.Delete(TimelineElements[0]);
	EndIf;
	
	GanttChart.SetWholeInterval(
		ScaleSettings.BeginOfWholeInterval,
		ScaleSettings.EndOfFullInterval);
	
EndProcedure

Function DefaultSeries(GanttChart)
	
	Return GanttChart.SetSeries("ProductionSchedule");
	
EndFunction

Function ChartIntervalText(Begin, Ending)
	
	FormatString = ProductionManagement.FormatStringForProductionScheduleDate();
	FormatStart = Format(Begin, FormatString);
	FormatEnd = Format(Ending, FormatString);
	
	If FormatStart = FormatEnd Then
		Result = FormatStart;
	Else
		Result = FormatStart + " - " + FormatEnd;
	EndIf;
	
	Return Result;
	
EndFunction

Function StatusWorkingSchedule()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
EndFunction

#EndRegion

#EndIf