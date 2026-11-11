#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Generates a report.
//
// Parameters:
//  Parameters  - Structure - report generation parameters:
//		* Stage - DocumentRef.ProductionStage2_2, CatalogRef.ProductionStages - the stage being diagnosed.
//		* ScheduleStatus - Number - status of the graph being diagnosed.
//		* ProductionOrder - DocumentRef.ProductionOrder2_2
//		* KeyLot - UUID
//  StorageAddress - String - address of the storage where the report generation result will be placed.
//
Procedure GenerateReport(Parameters, StorageAddress) Export
	
	GanttChart = New GanttChart;
	
	ConfigureGeneralChartProperties(GanttChart);
	
	Boundaries = New Structure("Begin, Ending", '39991231', '00010101');
	
	SelectDataAndFillChart(GanttChart, Parameters, Boundaries);
	
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
Function AddCommandAdjacentProductionStages(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ConnectedProductionStagesChart)
		And ProductionManagementCached.TheProductionScheduleIsUsed() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Id      = Metadata.Reports.ConnectedProductionStagesChart.FullName();
		ReportCommand.Presentation      = NStr("vi = 'Các công đoạn sản xuất liền kề';
												|ru = 'Смежные этапы';
												|en = 'Adjacent stages'; fa = 'Adjacent stages';
												|it = 'Fasi collaterali';
												|pl = 'Sąsiednie etapy';
												|tr = 'Ardışık aşamalar'");
		ReportCommand.FormName           = "Report.ConnectedProductionStagesChart.Form";
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ConnectedProductionStagesChart);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure SelectDataAndFillChart(GanttChart, Parameters, Boundaries)
	
	GanttChart.RefreshEnabled = False;
	
	Data = RelatedStagesAndDependencies(Parameters);
	
	If Data.Stages.Count() > 0 Then
		
		Series = DefaultSeries(GanttChart);
		
		CurrentStageData = Data.Stages.Find(Parameters.Stage);
		CurrentSpecification = ?(ValueIsFilled(CurrentStageData), CurrentStageData.BillOfMaterials, Undefined);
		
		Intervals = New Map;
		For Each String In Data.Stages Do
			
			Boundaries.Begin = Min(Boundaries.Begin, String.Begin);
			Boundaries.Ending = Max(Boundaries.Ending, String.Ending);
			
			If CurrentSpecification <> Undefined And String.BillOfMaterials <> CurrentSpecification Then
				String.PresentationStage = String.PresentationStage + " / " + String.BillOfMaterialsPresentation;
			EndIf;
			
			Point = SetPoint(GanttChart, Parameters.Stage, String);
			Value = GanttChart.GetValue(Point, Series);
			Interval = AddInterval(Value, String);
			
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

// Returns the related milestones and dependencies
//
// Parameters:
//  Parameters - Structure - Parameters:
// * Stage - CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2 - stage.
// * ScheduleStatus - Number - status of the production schedule.
// * ProductionOrder - DocumentRef.ProductionOrder2_2 - 
// * KeyLot - UUID -  
//
// Returns:
//  Structure - Contains:
//   * Stages - ValueTable - Contains:
//   * Dependencies - ValueTable - 
//
Function RelatedStagesAndDependencies(Parameters)
	
	EmptyLinkKey = New UUID("00000000-0000-0000-0000-000000000000");
	TempTablesManager = New TempTablesManager;
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Stage", Parameters.Stage);
	Query.SetParameter("ProductionOrder", Parameters.ProductionOrder);
	Query.SetParameter("ScheduleStatus", Parameters.ScheduleStatus);
	Query.SetParameter("EmptyLinkKey", EmptyLinkKey);
	Query.SetParameter("StatusWorkingSchedule", StatusWorkingSchedule());
	
	KeyLot = Undefined;
	If ValueIsFilled(Parameters.KeyLot) Then
		KeyLot = Parameters.KeyLot;
	Else
		StageDetails = Common.ObjectAttributesValues(
			Parameters.Stage, "ProductionLot, DynamicStructure");
		KeyLot = ?(StageDetails.DynamicStructure,
			StageDetails.ProductionLot.UUID(),
			EmptyLinkKey);
	EndIf;
	Query.SetParameter("KeyLot", KeyLot);
	
	Query.Text =
		"SELECT
		|	&Stage       AS Stage,
		|	&KeyLot AS KeyLot
		|INTO Data_Stage";
	
	Query.Execute();
	
	ProductionManagement.CreateVTLinksOfStages(TempTablesManager, "Data_Stage", "Stage", "KeyLot", True);
	
	BatchQueryText = New Array;
	
	QueryText =
	"SELECT
	|	TTCommunicationStages.Stage AS Stage,
	|	TTCommunicationStages.KeyLot AS KeyLot
	|INTO TTStages
	|FROM
	|	TTCommunicationStages AS TTCommunicationStages
	|
	|UNION ALL
	|
	|SELECT
	|	TTCommunicationStages.NextStage,
	|	TTCommunicationStages.NextStageIsKeyLotReference
	|FROM
	|	TTCommunicationStages AS TTCommunicationStages";
	BatchQueryText.Add(QueryText);
	
	If Parameters.ScheduleStatus = StatusWorkingSchedule() Then
		
		QueryText =
		"SELECT
		|	T.Stage AS Stage,
		|	T.Begin AS Begin,
		|	T.Ending AS Ending,
		|	CASE
		|		WHEN VALUETYPE(T.Stage) = TYPE(Document.ProductionStage2_2)
		|			THEN &PresentationStage
		|		ELSE T.Stage.Description
		|	END AS PresentationStage,
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
		|	T.KeyLot AS KeyLot,
		|	T.BillOfMaterials AS BillOfMaterials,
		|	T.BillOfMaterials.Description AS BillOfMaterialsPresentation
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS T
		|		LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS StandardScheduleOfProductionStages
		|		ON T.Stage = StandardScheduleOfProductionStages.ProductionStage
		|WHERE
		|	(VALUETYPE(&Stage) = TYPE(Document.ProductionStage2_2) OR T.ProductionOrder = &ProductionOrder)
		|	AND (T.Stage, T.KeyLot) IN
		|			(SELECT
		|				TTStages.Stage,
		|				TTStages.KeyLot
		|			FROM
		|				TTStages)
		|	AND T.ScheduleStatus = &ScheduleStatus
		|
		|ORDER BY
		|	ISNULL(StandardScheduleOfProductionStages.DurationBeforeStart, -T.Order)";
		
	Else
		
		QueryText =
		"SELECT
		|	ScheduleOfProductionStages2_2.Stage,
		|	ScheduleOfProductionStages2_2.Begin AS Begin,
		|	ScheduleOfProductionStages2_2.Ending AS Ending,
		|	ScheduleOfProductionStages2_2.Order AS Order,
		|	ScheduleOfProductionStages2_2.KeyLot AS KeyLot,
		|	ScheduleOfProductionStages2_2.BillOfMaterials AS BillOfMaterials,
		|	ScheduleOfProductionStages2_2.BillOfMaterials.Description AS BillOfMaterialsPresentation
		|INTO VTGrafikByStatus
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|WHERE
		|	(VALUETYPE(&Stage) = TYPE(Document.ProductionStage2_2) OR ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder)
		|	AND (ScheduleOfProductionStages2_2.Stage, ScheduleOfProductionStages2_2.KeyLot) IN
		|			(SELECT
		|				TTStages.Stage,
		|				TTStages.KeyLot
		|			FROM
		|				TTStages)
		|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &ScheduleStatus
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Stage AS Stage,
		|	T.Begin AS Begin,
		|	T.Ending AS Ending,
		|	CASE
		|		WHEN VALUETYPE(T.Stage) = TYPE(Document.ProductionStage2_2)
		|			THEN &PresentationStage
		|		ELSE T.Stage.Description
		|	END AS PresentationStage,
		|	T.Completed AS Completed,
		|	T.ManualPlacement AS ManualPlacement,
		|	T.KeyLot AS KeyLot,
		|	T.BillOfMaterials AS BillOfMaterials,
		|	T.BillOfMaterialsPresentation AS BillOfMaterialsPresentation
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
		|		VTGrafikByStatus.Order AS Order,
		|		VTGrafikByStatus.KeyLot AS KeyLot,
		|		VTGrafikByStatus.BillOfMaterials AS BillOfMaterials,
		|		VTGrafikByStatus.BillOfMaterialsPresentation AS BillOfMaterialsPresentation
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
		|		ScheduleOfProductionStages2_2.Order AS Order,
		|		ScheduleOfProductionStages2_2.KeyLot AS KeyLot,
		|		ScheduleOfProductionStages2_2.BillOfMaterials AS BillOfMaterials,
		|		ScheduleOfProductionStages2_2.BillOfMaterials.Description AS BillOfMaterialsPresentation
		|	FROM
		|		InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
		|	WHERE
		|		(VALUETYPE(&Stage) = TYPE(Document.ProductionStage2_2) OR ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder)
		|		AND (ScheduleOfProductionStages2_2.Stage, ScheduleOfProductionStages2_2.KeyLot) IN
		|			(SELECT
		|				TTStages.Stage,
		|				TTStages.KeyLot
		|			FROM
		|				TTStages)
		|		AND NOT ScheduleOfProductionStages2_2.Stage IN
		|					(SELECT
		|						VTGrafikByStatus.Stage
		|					FROM
		|						VTGrafikByStatus)
		|		AND ScheduleOfProductionStages2_2.ScheduleStatus = &StatusWorkingSchedule) AS T
		|		LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS StandardScheduleOfProductionStages
		|		ON T.Stage = StandardScheduleOfProductionStages.ProductionStage
		|
		|ORDER BY
		|	ISNULL(StandardScheduleOfProductionStages.DurationBeforeStart, -T.Order)";
		
	EndIf;
	
	QueryText = StrReplace(
		QueryText,
		"&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage("T.Stage"));
	
	BatchQueryText.Add(QueryText);
	
	QueryText =
	"SELECT
	|	TTCommunicationStages.Stage AS Stage,
	|	TTCommunicationStages.NextStage
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
	MaxIndex_ = ResultsArray.UBound();
	
	Result = New Structure;
	Result.Insert("Stages", ResultsArray[MaxIndex_-1].Unload());
	Result.Insert("Dependencies", ResultsArray[MaxIndex_].Unload());
	
	Return Result;
	
EndFunction

Function DefaultSeries(GanttChart)
	
	Return GanttChart.SetSeries("ProductionSchedule");
	
EndFunction

Function SetPoint(GanttChart, Stage, Data)
	
	Result = GanttChart.SetPoint(Data.Stage);
	Result.Text = Data.PresentationStage;
	Result.Details = New Structure("Stage, KeyLot", Data.Stage, Data.KeyLot);
	
	If Data.Stage = Stage Then
		Result.Font = New Font(,, True);
	EndIf;
	
	Return Result;
	
EndFunction

Function AddInterval(Value, Data)
	
	Result = Value.Add();
	Result.Begin = Data.Begin;
	Result.End = Data.Ending;
	Result.Text = ChartIntervalText(
		Data.Begin, Data.Ending);
	Result.Details = New Structure("Stage, KeyLot", Data.Stage, Data.KeyLot);
	Result.Color = IntervalColor(Data.Completed, Data.ManualPlacement);
	
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
	GanttChart.IntervalTextRepresentation = GanttChartIntervalTextRepresentation.DontShow;
	GanttChart.PlotArea.Right = 1;
	
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
	
	// Output allocation 
	
	GanttChart.BackgroundIntervals.Clear();
	
	Schedules = New Array();
	Schedules.Add(Constants.MainEnterpriseCalendar.Get());
	
	WorkSchedules1 = ProductionPlanning.ScheduleOfWorkOnSchedule(Schedules, ScaleSettings.BeginOfWholeInterval, ScaleSettings.EndOfFullInterval);
	WorkSchedules1.GroupBy("ScheduleDate");
	WorkSchedules1.Indexes.Add("ScheduleDate");
	
	PeriodsOfUnavailability = New ValueTable();
	PeriodsOfUnavailability.Columns.Add("Begin",    New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	PeriodsOfUnavailability.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	
	CurrentPeriod = ScaleSettings.BeginOfWholeInterval;
	While CurrentPeriod <= ScaleSettings.EndOfFullInterval Do
		
		If WorkSchedules1.Find(CurrentPeriod, "ScheduleDate") = Undefined Then
			NewPeriod = PeriodsOfUnavailability.Add();
			NewPeriod.Begin = CurrentPeriod;
			NewPeriod.Ending = EndOfDay(NewPeriod.Begin);
		EndIf;
		
		CurrentPeriod = CurrentPeriod + 86400;
	EndDo;
	
	For Each UnavailabilityData In PeriodsOfUnavailability Do
		
		GanttChart.BackgroundIntervals.Add(UnavailabilityData.Begin, UnavailabilityData.Ending);
		
	EndDo;
	
EndProcedure

Function StatusWorkingSchedule()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
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

Function IntervalColor(TheStepIsCompleted, ManualPlacement)
	
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

#EndRegion

#EndIf