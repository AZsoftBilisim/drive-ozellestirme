
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Function-constructor of parameters for displaying the operational schedule in the form of a Gantt chart.
//
// Returns:
//  Structure - output parameters.
//
Function OutputParameters() Export
	
	Result = New Structure;
	Result.Insert("Begin");
	Result.Insert("Ending");
	Result.Insert("Departments", New ValueList);
	Result.Insert("ProductionStages", New ValueList);
	Result.Insert("StagesOfProductionIllumination", New ValueList);
	Result.Insert("References", New ValueList);
	Result.Insert("Periodicity", DataAnalysisTimeIntervalUnitType.Week);
	Result.Insert("TimetableModel", New UUID("00000000-0000-0000-0000-000000000000"));
	Result.Insert("OptimumPlanningModel", Catalogs.MESModels.EmptyRef());
	
	Return Result;
	
EndFunction

// The constructor function of the parameters of the decoding interval of the Gantt chart with parallel download.
//
// Returns:
//  Structure - parameters of the interval with parallel loading.
//
Function ParallelLoadingOptions() Export
	
	Result = New Structure;
	Result.Insert("Begin", '00010101');
	Result.Insert("Ending", '00010101');
	Result.Insert("WorkCenter", Catalogs.WorkCenters.EmptyRef());
	Result.Insert("Departments", New Array);
	Result.Insert("TimetableModel");
	Result.Insert("PlanningModel", Catalogs.MESModels.EmptyRef());
	Result.Insert("ParallelLoad", True);
	Result.Insert("Periodicity", DataAnalysisTimeIntervalUnitType.Day);
	
	Return Result;
	
EndFunction

// Provides output of the operational schedule to the Gantt chart.
//
// Parameters:
//  Parameters - Structure - parameters of the formation and output of the schedule, composition, see the function of the parameter output.
//  GanttChart - GanttChart - the object that the schedule will be displayed in.
//
Procedure DisplaySchedule(Val Parameters, GanttChart) Export
	
	OutputProductionSchedule(Parameters, GanttChart);
	
EndProcedure

// The assignment is similar to the method Vyvestiraspisanie with the difference that the launch is performed in the background
//	and as a result, the results of the work (generated diagram) are transmitted to the calling session via
//	temporary storage.
//
// Parameters:
//  JobParameters - Structure - contains values:
//		* Parameters - Structure - parameters of the formation and output of the schedule, composition, see the function of the parameter output.
//		* GanttChart - GanttChart - the object that the schedule will be displayed in.
//  StorageAddress - UUID, String - the address in temporary storage where
//                                                     the generated chart should be placed.
//
Procedure DisplayScheduleInBackground(Val JobParameters, StorageAddress) Export
	
	Parameters = JobParameters.Parameters;
	GanttChart = JobParameters.GanttChart;
	
	OutputProductionSchedule(Parameters, GanttChart);
	
	PutToTempStorage(GanttChart, StorageAddress);
	
EndProcedure

// Sets the frequency of the Gantt chart containing the operational schedule.
//
// Parameters:
//  Parameters - Structure - parameters of the formation and output of the schedule, composition, see the function of the parameter output.
//  GanttChart - GanttChart - chart containing the schedule.
//
Procedure SetPeriodicity(Val Parameters, GanttChart) Export
	
	SetChartPeriodicity(Parameters, GanttChart);
	
EndProcedure

// Ensures the optimal allocation planning model in the chart with the schedule of production.
//
// Parameters:
//  GanttChart - GanttChart - chart containing the schedule.
//  OptimalModel - CatalogRef.MESModels - optimal planning model. 
//
Procedure LabelOptimalModel(GanttChart, Val OptimalModel) Export
	
	ModelPoints = ModelPointsOfPlanningModels(GanttChart);
	For Each Point In ModelPoints Do
		If Point.Details = OptimalModel Then
			CreatePointOptimalModel(Point);
		Else
			FormalizingPointIsNotOptimalModel(Point);
		EndIf;
	EndDo;
	
EndProcedure

// Displays a legend with a description of the Gantt chart elements in the form.
//	To display the legend, the form must have a group named "Groupvalues".
//
// Parameters:
//  Form - ClientApplicationForm - the form that the legend will be displayed in.
//	WorkCenters - Boolean - flag that specifies whether to display the icon for the work center icon.
//  Modeling - Boolean - flag that determines whether the calculation (and therefore modeling)
//		of the operational schedule can be performed in the form passed through the first parameter. Depending on the flag value
//		, the legend can display a grouping of elements that are used only for modeling.
//
Procedure AddChartNotationToForm(Form, WorkCenters = True, Modeling = True) Export
	
	DesignationGroupName = "DesignationGroup";
	DesignationGroup = Form.Items.Find(DesignationGroupName);
	If DesignationGroup = Undefined Then
		DesignationGroup = AddNotationGroupToForm(Form, DesignationGroupName);
	EndIf;
	
	If WorkCenters Or Modeling Then
		AddImageLegendToList(Form, DesignationGroup, WorkCenters, Modeling);
	EndIf;
	
	AddLegendOfColorsToNotation(Form, DesignationGroup);
	
EndProcedure

// Returns a custom view for an empty planning model.
//
// Returns:
//  String - representation of an empty model.
//
Function PresentationOfEmptyModel() Export
	
	Return NStr("vi = '<Mặc định>';
				|ru = '<По умолчанию>';
				|en = '<By default>'; fa = '<By default>';
				|it = 'Di default';
				|pl = '<Domyślnie>';
				|tr = '<Varsayılan>'");
	
EndFunction

// Displays the expanded RC production schedule with parallel loading in the Gantt chart.
// Used for decoding a parallel loaded schedule interval set by the RC.
//
// Parameters:
//  JobParameters - Structure - contains values:
//		* Parameters - Structure - parameters for the formation and output of the schedule, composition, see the function parameterparallel loading.
//		* GanttChart - GanttChart - the object that the schedule will be displayed in.
//  StorageAddress - UUID, String - the address in temporary storage where
//                                                     the generated chart should be placed.
//
Procedure DecryptParallelDownloadsInBackground(Val JobParameters, StorageAddress) Export
	
	Parameters = JobParameters.Parameters;
	GanttChart = JobParameters.GanttChart;
	
	DecryptParallelDownload(Parameters, GanttChart);
	
	PutToTempStorage(GanttChart, StorageAddress);
	
EndProcedure

#EndRegion

#Region Private

#Region OutputScheduleToGanttChart

Procedure OutputProductionSchedule(Parameters, GanttChart)
	
	ScheduleData_ = ProductionScheduleData(Parameters);
	DisplayScheduleInChart(Parameters, GanttChart, ScheduleData_);
	CreateDiagram(Parameters, GanttChart);
	
EndProcedure

Procedure DisplayScheduleInChart(Val Parameters, GanttChart, Val ScheduleData_)
	
	GanttChart.RefreshEnabled = False;
	GanttChart.Clear();
	
	Series = DefaultSeries(GanttChart);
	
	CurCommunicationKey = Undefined;
	CurWorkCenter = Undefined;
	For Each Interval In ScheduleData_ Do
		
		If CurCommunicationKey = Undefined Or Not CurCommunicationKey = Interval.CommunicationKeyModel Then
			CurCommunicationKey = Interval.CommunicationKeyModel;
			CurWorkCenter = Undefined;
			SetPointChartModel(Parameters, Interval, GanttChart);
		EndIf;
		
		If CurWorkCenter = Undefined Or WorkingCenterOfIntervalHasChanged(Interval, CurWorkCenter) Then
			CurWorkCenter = Interval.WorkCenter;
			WorkingCenterPoint = ChartPointWorkCenter(Interval, GanttChart);
			Value = GanttChart.GetValue(WorkingCenterPoint, Series);
		EndIf;
		
		OutputInterval(Parameters, Interval, Value);
		
	EndDo;
	
	GanttChart.RefreshEnabled = True;
	
EndProcedure

Function WorkingCenterOfIntervalHasChanged(Interval, CurWorkCenter)
	
	If Not TypeOf(CurWorkCenter) = TypeOf(Interval.WorkCenter) Then
		Return True;
	Else
		Return Not CurWorkCenter = Interval.WorkCenter;
	EndIf;
	
EndFunction

Function DefaultSeries(GanttChart)
	
	Return GanttChart.SetSeries("Schedule");
	
EndFunction

Procedure SetPointChartModel(Val Parameters, Val FillingValues, GanttChart)
	
	ConnectionKey = PointConnectionKey(FillingValues);
	
	If ConnectionKey = Undefined Then
		
		Result = Undefined;
		
	Else
		
		Result = GanttChart.SetPoint(ConnectionKey);
		Result.Text = 
			?(ValueIsFilled(FillingValues.PlanningModel),
				FillingValues.PlanningModelPresentation,
				PresentationOfEmptyModel());
		Result.Picture = PicturePlanningModel();
		Result.Details = FillingValues.PlanningModel;
				
		If FillingValues.PlanningModel = Parameters.OptimumPlanningModel Then
			CreatePointOptimalModel(Result);
		EndIf;
		
	EndIf;
	
EndProcedure

Function PointConnectionKey(Val FillingValues)
	
	If ValueIsFilled(FillingValues.CommunicationKeyModel) Then
		Return FillingValues.CommunicationKeyModel;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Procedure CreatePointOptimalModel(Point)
	
	BoldFont = New Font(,, True);
	Point.Font = BoldFont;
	
EndProcedure

Procedure FormalizingPointIsNotOptimalModel(Point)
	
	SimpleFont = New Font;
	Point.Font = SimpleFont;
	
EndProcedure

Function ModelPointsOfPlanningModels(Val GanttChart)
	
	Result = New Array;
	
	For Each Point In GanttChart.Points Do
		If TypeOf(Point.Details) = Type("CatalogRef.MESModels") Then
			Result.Add(Point);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function ChartPointWorkCenter(Val FillingValues, GanttChart)
	
	PointValue = New Structure("WorkCenter, PlanningModel");
	FillPropertyValues(PointValue, FillingValues);
	ConnectionKey = PointConnectionKey(FillingValues);
	
	Result = GanttChart.SetPoint(PointValue, ConnectionKey);
	Result.Text = FillingValues.WorkCenterPresentation;
	Result.Picture = WorkingCenterPointImage(FillingValues);
	Result.Details = FillingValues.WorkCenter;
	
	Return Result;
	
EndFunction

Function WorkingCenterPointImage(Val FillingValues)
	
	If Not TypeOf(FillingValues.WorkCenter) = Type("String") Then
		
		If FillingValues.Auxiliary Then
			Result = PictureAuxiliaryWorkCenter();
		Else
			Result = ImageWorkCenter();
		EndIf;
		
	Else
		
		Result = ImageAdditionalWorkCenter();
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
// 	Parameters - Structure - 
// 	FillingValues - See InitializeScheduleData
// 	ChartValue - GanttChartValue - 
//
Procedure OutputInterval(Val Parameters, Val FillingValues, ChartValue)
	
	Interval = ChartValue.Add();
	Interval.Begin = FillingValues.Begin;
	Interval.End = FillingValues.Ending;
	Interval.Color = ChartIntervalColor(Parameters, FillingValues);
	Interval.Text = IntervalHint(FillingValues);
	Interval.Details = IntervalDetails1(FillingValues);
	
EndProcedure

Function IntervalHint(Val FillingValues)
	
	Result = Format(FillingValues.Begin, "DF=HH:mm") + "-"
		+ Format(FillingValues.Ending, "DF=HH:mm") + " "
		+ Format(FillingValues.Ending, "DLF=D");
	
	If FillingValues.State = TextWork()
		Or FillingValues.State = TextChangeover() Then
		
		If Not FillingValues.ParallelLoad Then
			
			Result = Result
				+ Chars.LF
				+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Giao dịch: %1';
																				|ru = 'Операция: %1';
																				|en = 'Operation: %1'; fa = 'Operation: %1';
																				|it = 'Operazione: %1';
																				|pl = 'Operacja: %1';
																				|tr = 'İşlem: %1'"), FillingValues.OperationPresentation)
				+ ?(ValueIsFilled(FillingValues.LotNumber), Chars.LF 
				+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Lô:%1';
																				|ru = 'Партия: %1';
																				|en = 'Lot: %1'; fa = 'Lot: %1';
																				|it = 'Partita: %1';
																				|pl = 'Partia: %1';
																				|tr = 'Lot: %1'"), FillingValues.LotNumber), "")
				+ Chars.LF
				+ ProductionStagePresentation(FillingValues.StageNumber, FillingValues.StageDate);
			
			If ValueIsFilled(FillingValues.Load) Then
				Result = Result
					+ Chars.LF
					+ StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Tải:%1 %2';
							|ru = 'Загрузка: %1 %2';
							|en = 'Load: %1 %2'; fa = 'Load: %1 %2';
							|it = 'Caricamento: %1 %2';
							|pl = 'Pobieranie: %1 %2';
							|tr = 'Çalışma yükü: %1 %2'"),
						FillingValues.Load,
						FillingValues.UnitOfMeasureOfLoad);
			EndIf;
			
		Else
			
			Result = Result
				+ Chars.LF
				+ NStr("vi = 'Kết nhập song song';
						|ru = 'Параллельная загрузка';
						|en = 'Parallel load'; fa = 'بار موازی';
						|it = 'Caricamento parallelo';
						|pl = 'Równoległe obciążenie';
						|tr = 'Paralel çalışma yükü'");
			
		EndIf;
		
	ElsIf FillingValues.State = TextRepair() Then
		
		Result = Result + Chars.LF + NStr("vi = 'Sửa chữa';
											|ru = 'Ремонт';
											|en = 'R&M'; fa = 'تعمیر و نگهداری';
											|it = 'Manutenzione';
											|pl = 'Naprawa';
											|tr = 'Bakım-onarım'");
		
	EndIf;
	
	Return Result;
	
EndFunction

Function IntervalDetails1(Val FillingValues)
	
	If Not FillingValues.ParallelLoad Then
		
		Result = FillingValues.Details;
		
	Else
		
		Result = ParallelLoadingOptions();
		FillPropertyValues(Result, FillingValues);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ChartIntervalColor(Val Parameters, Val FillingValues)
	
	If Parameters.Property("StagesOfProductionIllumination")
		And ValueIsFilled(Parameters.StagesOfProductionIllumination) Then
		Result = IntervalColorByBacklightSettings(Parameters, FillingValues);
	Else
		Result = IntervalColorAccordingToScheduleData(FillingValues);
	EndIf;
	
	Return Result;
	
EndFunction

Function IntervalColorByBacklightSettings(Val Parameters, Val FillingValues)
	
	If Parameters.StagesOfProductionIllumination.FindByValue(FillingValues.Stage) = Undefined Then
		Result = WebColors.LightGray;
	Else
		Result = IntervalColorAccordingToScheduleData(FillingValues);
	EndIf;
	
	Return Result;
	
EndFunction

Function IntervalColorAccordingToScheduleData(Val FillingValues)
	
	Return IntervalColor(FillingValues.State, FillingValues.Perform, FillingValues.ParallelLoad);
	
EndFunction

Procedure CreateDiagram(Val Parameters, GanttChart)
	
	SetGeneralChartProperties(GanttChart);
	SetChartPeriodicity(Parameters, GanttChart);
	
EndProcedure

Procedure SetGeneralChartProperties(GanttChart)
	
	GanttChart.ShowPointLevel(0);
	
	GanttChart.AutoDetectWholeInterval = False;
	GanttChart.VerticalScroll = True;
	GanttChart.ShowTitle = False;
	GanttChart.Outline = True;
	GanttChart.ShowEmptyValues = False;
	GanttChart.ShowLegend = False;
	GanttChart.IntervalTextRepresentation = GanttChartIntervalTextRepresentation.DontShow;
	
EndProcedure

Procedure SetChartPeriodicity(Val Parameters, GanttChart)
	
	If Not Parameters.Property("Periodicity")
		Or Not ValueIsFilled(Parameters.Periodicity) Then
		Periodicity = DataAnalysisTimeIntervalUnitType.Week;
	Else
		Periodicity = Parameters.Periodicity;
	EndIf;
	
	DeleteTimelineItems(GanttChart);
	
	If Periodicity = DataAnalysisTimeIntervalUnitType.Week Then
		
		SetFrequencyWeek(GanttChart);
		
	ElsIf Periodicity = DataAnalysisTimeIntervalUnitType.Day Then
		
		SetPeriodicityDay(GanttChart);
		
	ElsIf Periodicity = DataAnalysisTimeIntervalUnitType.Month Then
		
		SetPeriodicityMonth(GanttChart);
		
	EndIf;
	
	If ValueIsFilled(Parameters.Begin) And ValueIsFilled(Parameters.Ending) Then
		
		If GanttChart.AutoDetectWholeInterval Then
			GanttChart.AutoDetectWholeInterval = False;
		EndIf;
		
		GanttChart.SetWholeInterval(Parameters.Begin, Parameters.Ending);
		
	EndIf;
	
EndProcedure

Procedure DeleteTimelineItems(GanttChart)
	
	TimeScaleItems = GanttChart.PlotArea.TimeScale.Items;
	
	// It is impossible to completely clean up the collection, there will always be one element.
	For Cnt = 1 To TimeScaleItems.Count()-1 Do
		TimeScaleItems.Delete(TimeScaleItems[1]);
	EndDo; 
	
EndProcedure

Procedure SetFrequencyWeek(GanttChart)
	
	TheFirstControl = GanttChart.PlotArea.TimeScale.Items[0];
	TheFirstControl.Unit = TimeScaleUnitType.Month;
	TheFirstControl.PointLines = New Line(ChartLineType.Solid, 1);
	TheFirstControl.Format = "DF='MMMM yyyy'";
	
	Item = GanttChart.PlotArea.TimeScale.Items.Add();
	Item.Unit = TimeScaleUnitType.Day;
	Item.DayFormat =  TimeScaleDayFormat.MonthDayWeekDay;
	Item.PointLines = New Line(ChartLineType.Dotted, 1);		
	
	Item = GanttChart.PlotArea.TimeScale.Items.Add();
	Item.Unit = TimeScaleUnitType.Hour;
	Item.Repetition = 6;
	Item.Format = "DF='HH'";
	Item.PointLines = New Line(ChartLineType.None, 1);		
	
	GanttChart.ScaleKeeping = GanttChartScaleKeeping.Period;
	GanttChart.PeriodicVariantRepetition = 1;
	GanttChart.PeriodicVariantUnit = TimeScaleUnitType.Week;
	
EndProcedure

Procedure SetPeriodicityDay(GanttChart)
	
	TheFirstControl = GanttChart.PlotArea.TimeScale.Items[0];
	TheFirstControl.Unit = TimeScaleUnitType.Day;
	TheFirstControl.PointLines = New Line(ChartLineType.Solid, 1);
	TheFirstControl.DayFormat =  TimeScaleDayFormat.MonthDayWeekDay;
	TheFirstControl.Format = "";
	
	Item = GanttChart.PlotArea.TimeScale.Items.Add();
	Item.Unit = TimeScaleUnitType.Hour;
	Item.PointLines = New Line(ChartLineType.Dotted, 1);		
	Item.Format = "DF='HH'";
	
	GanttChart.ScaleKeeping = GanttChartScaleKeeping.Period;
	GanttChart.PeriodicVariantRepetition = 21;
	GanttChart.PeriodicVariantUnit = TimeScaleUnitType.Hour;
	
EndProcedure

Procedure SetPeriodicityMonth(GanttChart)
	
	TheFirstControl = GanttChart.PlotArea.TimeScale.Items[0];
	TheFirstControl.Unit = TimeScaleUnitType.Month;
	TheFirstControl.PointLines = New Line(ChartLineType.Solid, 1);
	TheFirstControl.Format = "DF='MMMM yyyy'";
	
	Item = GanttChart.PlotArea.TimeScale.Items.Add();
	Item.Unit = TimeScaleUnitType.Day;
	Item.DayFormat =  TimeScaleDayFormat.MonthDayWeekDay;
	Item.PointLines = New Line(ChartLineType.Dotted, 1);		
	
	GanttChart.ScaleKeeping = GanttChartScaleKeeping.Period;
	GanttChart.PeriodicVariantRepetition = 1;
	GanttChart.PeriodicVariantUnit = TimeScaleUnitType.Month;
	
EndProcedure

#EndRegion

#Region GettingScheduleData

Function ProductionScheduleData(Val Parameters)
	
	DataSelection = SelectScheduleData(Parameters);
	Result = InitializeScheduleData(DataSelection.Columns);
	ParallelIntervals = New Array;
	
	SampleModel = DataSelection.Select(QueryResultIteration.ByGroups);
	While SampleModel.Next() Do
		
		SamplingWorkCenter = SampleModel.Select(QueryResultIteration.ByGroups);
		While SamplingWorkCenter.Next() Do
			
			ParallelIntervals.Clear();
			ParallelLoad = False;
			Ending = Undefined;
			
			Selection = SamplingWorkCenter.Select();
			While Selection.Next() Do
				
				If Selection.Perform = Enums.OperationExecutionStatuses.Completed Then 
					AddCompletedOperationInterval(Result, Selection);
					Continue;
				EndIf;
				
				If Not Ending = Undefined Then
					
					If Selection.Begin >= Ending Then
						
						NewRow = Result.Add();
						FillPropertyValues(NewRow, Selection);
						If ParallelLoad Then
							If ParallelIntervals.Count() > 0 Then
								ParallelIntervals.Clear();
							EndIf;
						EndIf;
						Ending = Selection.Ending;
						
					Else
						
						ParallelLoad = True;
						If ParallelIntervals.Count() = 0 Then
							PrecedingLine = Result[Result.Count()-1];
							ParallelIntervals.Add(PrecedingLine);
						EndIf;
						
						DisplaceIntervals(Result, ParallelIntervals, Selection, Ending);
						
					EndIf;
					
				Else
					
					NewRow = Result.Add();
					FillPropertyValues(NewRow, Selection);
					Ending = Selection.Ending;
					
				EndIf;
				
			EndDo;
			
		EndDo;
	EndDo;
	
	FillInLinkKeyModel(Result);
	
	Return Result;
	
EndFunction

Function SelectScheduleData(Val Parameters)
	
	QueryText = QueryTextScheduleData_();
	Query = New Query(QueryText);
	
	Query.SetParameter("TimetableModel", Parameters.TimetableModel);
	Query.SetParameter("OptimumPlanningModel", Parameters.OptimumPlanningModel);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	EmptyWorkCenterValues = New Array;
	EmptyWorkCenterValues.Add(Catalogs.WorkCenters.EmptyRef());
	EmptyWorkCenterValues.Add("");
	EmptyWorkCenterValues.Add(Undefined);
	Query.SetParameter("EmptyWorkCenterValues", EmptyWorkCenterValues);
	
	Query.SetParameter("FilterBegin", ValueIsFilled(Parameters.Begin));
	Query.SetParameter("Begin", Parameters.Begin);
	
	Query.SetParameter("FilterEnding", ValueIsFilled(Parameters.Ending));
	Query.SetParameter("Ending", Parameters.Ending);
	
	Query.SetParameter("FilterDepartments", ValueIsFilled(Parameters.Departments));
	Query.SetParameter("Departments", Parameters.Departments.UnloadValues());
	
	Query.SetParameter("FilterProductionStages", ValueIsFilled(Parameters.ProductionStages));
	Query.SetParameter("ProductionStages", Parameters.ProductionStages.UnloadValues());
	
	Query.SetParameter("FilterReferences", ValueIsFilled(Parameters.References));
	Query.SetParameter("References", Parameters.References.UnloadValues());
	
	Query.SetParameter("TextChangeover", TextChangeover());
	Query.SetParameter("TextWork", TextWork());
	Query.SetParameter("TextRepair", TextRepair());
	
	Return Query.Execute();
	
EndFunction

Function TextChangeover()
	
	Return NStr("vi = 'Chỉnh lại';
				|ru = 'Переналадка';
				|en = 'Changeover'; fa = 'تغییر تنظیمات';
				|it = 'Riconfigurazione';
				|pl = 'Changeover';
				|tr = 'Yeniden ayarlama'");
	
EndFunction

Function TextWork()
	
	Return NStr("vi = 'Công việc';
				|ru = 'Работа';
				|en = 'Work'; fa = 'کار';
				|it = 'Lavoro';
				|pl = 'Work';
				|tr = 'İş'");
	
EndFunction

Function TextRepair()
	
	Return NStr("vi = 'Sửa chữa';
				|ru = 'Ремонт';
				|en = 'R&M'; fa = 'تعمیر و نگهداری';
				|it = 'Manutenzione';
				|pl = 'R&M';
				|tr = 'Bakım-onarım'");
	
EndFunction

Function QueryTextScheduleData_()
	
	Result = 
	"SELECT ALLOWED
	|	PostOperativeSchedule.Begin AS Begin,
	|	PostOperativeSchedule.Ending AS Ending,
	|	CAST(PostOperativeSchedule.WorkCenter AS Catalog.WorkCenters) AS WorkCenter
	|INTO ClearOperations
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|WHERE
	|	PostOperativeSchedule.TimetableModel = &TimetableModel
	|	AND PostOperativeSchedule.ThisIsOperationDeletion = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	PostOperativeSchedule.TimetableModel AS TimetableModel,
	|	PostOperativeSchedule.PlanningModel AS PlanningModel,
	|	PostOperativeSchedule.Begin AS Begin,
	|	PostOperativeSchedule.Ending AS Ending,
	|	PostOperativeSchedule.WorkCenter AS WorkCenter,
	|	PostOperativeSchedule.ThisIsChangeover AS ThisIsChangeover,
	|	PostOperativeSchedule.Secondary AS Secondary,
	|	SUM(PostOperativeSchedule.Load) AS Load,
	|	PostOperativeSchedule.Stage AS Stage,
	|	PostOperativeSchedule.Operation AS Operation,
	|	PostOperativeSchedule.Department AS Department,
	|	PostOperativeSchedule.LotQuantity AS LotQuantity,
	|	PostOperativeSchedule.Running AS Running,
	|	PostOperativeSchedule.Completed2 AS Completed2,
	|	PostOperativeSchedule.RepetitionIsRequired AS RepetitionIsRequired,
	|	PostOperativeSchedule.Skipped3 AS Skipped3,
	|	PostOperativeSchedule.LotNumber AS LotNumber
	|INTO ScheduleOperations
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|		LEFT JOIN InformationRegister.QueueOfProductionOperations AS QueueOfProductionOperations
	|		ON PostOperativeSchedule.Stage = QueueOfProductionOperations.Stage
	|			AND PostOperativeSchedule.Operation = QueueOfProductionOperations.Operation
	|			AND PostOperativeSchedule.OperationID = QueueOfProductionOperations.OperationID
	|WHERE
	|	PostOperativeSchedule.TimetableModel = &TimetableModel
	|	AND PostOperativeSchedule.ThisIsOperationDeletion = FALSE
	|	AND NOT PostOperativeSchedule.WorkCenter IN (&EmptyWorkCenterValues)
	|	AND (NOT &FilterBegin
	|			OR PostOperativeSchedule.Ending > &Begin)
	|	AND (NOT &FilterEnding
	|			OR PostOperativeSchedule.Begin < &Ending)
	|	AND (NOT &FilterDepartments
	|			OR PostOperativeSchedule.Department IN (&Departments))
	|	AND (NOT &FilterProductionStages
	|			OR PostOperativeSchedule.Stage IN (&ProductionStages))
	|	AND NOT ISNULL(QueueOfProductionOperations.InArchive, TRUE)
	|
	|GROUP BY
	|	PostOperativeSchedule.TimetableModel,
	|	PostOperativeSchedule.PlanningModel,
	|	PostOperativeSchedule.Begin,
	|	PostOperativeSchedule.Ending,
	|	PostOperativeSchedule.WorkCenter,
	|	PostOperativeSchedule.ThisIsChangeover,
	|	PostOperativeSchedule.Secondary,
	|	PostOperativeSchedule.Stage,
	|	PostOperativeSchedule.Operation,
	|	PostOperativeSchedule.Department,
	|	PostOperativeSchedule.LotQuantity,
	|	PostOperativeSchedule.Running,
	|	PostOperativeSchedule.Completed2,
	|	PostOperativeSchedule.RepetitionIsRequired,
	|	PostOperativeSchedule.Skipped3,
	|	PostOperativeSchedule.LotNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleOperations.WorkCenter AS WorkCenter,
	|	MIN(ScheduleOperations.Secondary) AS Secondary
	|INTO AuxiliaryRC
	|FROM
	|	ScheduleOperations AS ScheduleOperations
	|
	|GROUP BY
	|	ScheduleOperations.WorkCenter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ScheduleOperations.TimetableModel AS TimetableModel,
	|	ScheduleOperations.PlanningModel AS PlanningModel,
	|	ScheduleOperations.PlanningModel.Presentation AS PlanningModelPresentation,
	|	CASE
	|		WHEN ScheduleOperations.PlanningModel = UNDEFINED
	|			THEN 1
	|		ELSE 2
	|	END AS OrderPlanningModel,
	|	ScheduleOperations.Begin AS Begin,
	|	ScheduleOperations.Ending AS Ending,
	|	ScheduleOperations.WorkCenter AS WorkCenter,
	|	CASE
	|		WHEN ScheduleOperations.WorkCenter REFS Catalog.WorkCenters
	|			THEN ScheduleOperations.WorkCenter.Description
	|		ELSE ScheduleOperations.WorkCenter
	|	END AS WorkCenterPresentation,
	|	CASE
	|		WHEN ScheduleOperations.ThisIsChangeover
	|			THEN &TextChangeover
	|		ELSE &TextWork
	|	END AS State,
	|	ScheduleOperations.Secondary AS Auxiliary,
	|	ScheduleOperations.Stage AS Stage,
	|	ScheduleOperations.Stage.Number AS StageNumber,
	|	ScheduleOperations.Stage.Date AS StageDate,
	|	ScheduleOperations.Operation AS Operation,
	|	CASE
	|		WHEN ScheduleOperations.Operation REFS Catalog.ManufacturingOperations
	|			THEN CAST(ScheduleOperations.Operation AS Catalog.ManufacturingOperations).Presentation
	|		ELSE ScheduleOperations.Operation
	|	END AS OperationPresentation,
	|	ScheduleOperations.Stage.ReferenceOrder AS ReferenceOrder,
	|	ScheduleOperations.Department AS Department,
	|	ScheduleOperations.Operation.SetupSettings AS SetupSettings,
	|	CASE
	|		WHEN ScheduleOperations.LotQuantity = (ScheduleOperations.Completed2 + ScheduleOperations.Skipped3 - ScheduleOperations.RepetitionIsRequired)
	|			THEN VALUE(Enum.OperationExecutionStatuses.Completed)
	|		WHEN ScheduleOperations.Running + ScheduleOperations.Completed2 > 0
	|			THEN VALUE(Enum.OperationExecutionStatuses.Started_)
	|		ELSE VALUE(Enum.OperationExecutionStatuses.NotStarted_)
	|	END AS Perform,
	|	ScheduleOperations.Stage AS Details,
	|	ScheduleOperations.Load AS Load,
	|	ScheduleOperations.WorkCenter.WorkCenterType.UnitOfMeasureOfLoad AS UnitOfMeasureOfLoad,
	|	BEGINOFPERIOD(ScheduleOperations.Begin, DAY) AS IntervalDate,
	|	CASE
	|		WHEN ScheduleOperations.LotQuantity = ScheduleOperations.Completed2
	|			THEN 1
	|		ELSE 0
	|	END AS AddlOrderingAttribute,
	|	ScheduleOperations.LotNumber AS LotNumber
	|FROM
	|	ScheduleOperations AS ScheduleOperations
	|WHERE
	|	(NOT &FilterReferences
	|			OR ScheduleOperations.Stage.ReferenceOrder IN (&References))
	|	AND ScheduleOperations.LotQuantity > (ScheduleOperations.Completed2 + ScheduleOperations.Skipped3) 
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED,
	|	UNDEFINED,
	|	NULL,
	|	1,
	|	WorkCenterRM.StartDate,
	|	WorkCenterRM.CompletedOn,
	|	WorkCenterRM.WorkCenter,
	|	WorkCenterRM.WorkCenter.Description,
	|	&TextRepair,
	|	ISNULL(AuxiliaryRC.Secondary, FALSE),
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	WorkCenterRM.WorkCenter.WorkCenterType.Department,
	|	NULL,
	|	NULL,
	|	WorkCenterRM.Recorder,
	|	0,
	|	NULL,
	|	BEGINOFPERIOD(WorkCenterRM.StartDate, DAY),
	|	0,
	|	NULL
	|FROM
	|	InformationRegister.WorkCenterRM AS WorkCenterRM
	|		LEFT JOIN AuxiliaryRC AS AuxiliaryRC
	|		ON WorkCenterRM.WorkCenter = AuxiliaryRC.WorkCenter
	|WHERE
	|	WorkCenterRM.WorkCenter IN
	|			(SELECT
	|				ScheduleOperations.WorkCenter AS WorkCenter
	|			FROM
	|				ScheduleOperations)
	|	AND (NOT &FilterBegin
	|			OR WorkCenterRM.StartDate >= &Begin)
	|	AND (NOT &FilterEnding
	|			OR WorkCenterRM.CompletedOn <= &Ending)
	|	AND (NOT &FilterDepartments
	|			OR WorkCenterRM.WorkCenter.WorkCenterType.Department IN (&Departments))
	|
	|ORDER BY
	|	OrderPlanningModel,
	|	PlanningModel,
	|	WorkCenterPresentation,
	|	AddlOrderingAttribute,
	|	Begin,
	|	Ending
	|TOTALS
	|	MIN(Auxiliary)
	|BY
	|	PlanningModel,
	|	WorkCenter";
	
	Return Result;
	
EndFunction

// Parameters:
// 	Columns - QueryResultColumnsCollection - 
// Returns:
// 	ValueTable - LongDesc:
// * TimetableModel - UUID -
// * PlanningModel - CatalogRef.MESModels -
// * PlanningModelPresentation - String - 
// * OrderPlanningModel - Number - 
// * Begin - Date - 
// * Ending - Date - 
// * WorkCenter - String, CatalogRef.WorkCenters -
// * WorkCenterPresentation  -String - 
// * State - String - 
// * Auxiliary - Boolean -
// * Stage - DocumentRef.ProductionStage2_2 - 
// * StageNumber - Number - 
// * StageDate - Date - 
// * Operation - CatalogRef.ManufacturingOperations -
// * OperationPresentation - String - 
// * ReferenceOrder - DocumentRef.ProductionOrder2_2 -
// * Department - CatalogRef.BusinessStructure -
// * SetupSettings - CatalogRef.SetupOptions -
// * Perform - EnumRef.OperationExecutionStatuses - 
// * Details - DocumentRef.ProductionStage2_2 -
// * Load - Number -
// * UnitOfMeasureOfLoad - String -
// * IntervalDate - Date - 
// * AddlOrderingAttribute - Number -
// * LotNumber - Number -
// * CommunicationKeyModel - Number -
// * ParallelLoad - Boolean -
Function InitializeScheduleData(Columns)

	Result = New ValueTable;
	For Each Column In Columns Do
		Result.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	Result.Columns.Add("CommunicationKeyModel", New TypeDescription("Number", New NumberQualifiers(5)));
	Result.Columns.Add("ParallelLoad", New TypeDescription("Boolean"));
	
	Result.Indexes.Add("PlanningModel, WorkCenter, IntervalDate");
	
	Return Result;
	
EndFunction

// Parameters:
// 	ScheduleData_ - See InitializeScheduleData
// 	ParallelIntervals - Array of ValueTableRow - Where:
// * CommunicationKeyModel - Number -
// * ParallelLoad - Boolean -
// * Begin - Date - 
// * Ending - Date - 
// 	CurrentInterval - QueryResultSelection -
// 	Ending - Undefined -
Procedure DisplaceIntervals(ScheduleData_, ParallelIntervals, CurrentInterval, Ending)
	
	IndexOf = 0;
	For Each NextInterval In ParallelIntervals Do
		If CurrentInterval.Begin < NextInterval.Ending Then
			
			If NextInterval.ParallelLoad Then
				
				If CurrentInterval.Ending > NextInterval.Ending Then
					NextInterval.Ending = CurrentInterval.Ending;
					If Not IndexOf = ParallelIntervals.UBound() Then
						NextInterval_ = ParallelIntervals[IndexOf+1];
						If NextInterval.Ending >= NextInterval_.Ending Then
							ScheduleData_.Delete(NextInterval_);
							ParallelIntervals.Delete(IndexOf+1);
						Else
							NextInterval_.Begin = NextInterval.Ending;
						EndIf;
					EndIf;
				EndIf;
				
			Else
				
				If CurrentInterval.Begin = NextInterval.Begin
					And CurrentInterval.Ending >= NextInterval.Ending Then
					
					If  CurrentInterval.Ending = NextInterval.Ending Then
						NextInterval.ParallelLoad = True;
					Else
						NewInterval = ScheduleData_.Add();
						FillPropertyValues(NewInterval, NextInterval);
						NewInterval.Begin = NextInterval.Ending;
						NewInterval.Ending = CurrentInterval.Ending;
						ParallelIntervals.Add(NewInterval);
						
						NextInterval.ParallelLoad = True;
					EndIf;
					
					If Not IndexOf = 0 Then
						PreviousInterval = ParallelIntervals[IndexOf-1];
						If PreviousInterval.ParallelLoad Then
							PreviousInterval.Ending = NextInterval.Ending;
							
							ScheduleData_.Delete(NextInterval);
							ParallelIntervals.Delete(IndexOf);
						EndIf;
					EndIf;
					
				ElsIf CurrentInterval.Begin = NextInterval.Begin Then
					
					NewInterval = ScheduleData_.Add();
					FillPropertyValues(NewInterval, NextInterval);
					NewInterval.Begin = CurrentInterval.Ending;
					ParallelIntervals.Add(NewInterval);
					
					NextInterval.ParallelLoad = True;
					NextInterval.Ending = CurrentInterval.Ending;
					
					If Not IndexOf = 0 Then
						PreviousInterval = ParallelIntervals[IndexOf-1];
						If PreviousInterval.ParallelLoad Then
							PreviousInterval.Ending = NextInterval.Ending;
							
							ScheduleData_.Delete(NextInterval);
							ParallelIntervals.Delete(IndexOf);
						EndIf;
					EndIf;
					
				ElsIf CurrentInterval.Ending >= NextInterval.Ending Then
					
					If CurrentInterval.Ending = NextInterval.Ending Then
						
						NewInterval = ScheduleData_.Add();
						FillPropertyValues(NewInterval, NextInterval);
						NewInterval.Begin = CurrentInterval.Begin;
						NewInterval.ParallelLoad = True;
						ParallelIntervals.Add(NewInterval);
						
						NextInterval.Ending = CurrentInterval.Begin;
						
					Else
						
						NewInterval = ScheduleData_.Add();
						FillPropertyValues(NewInterval, NextInterval);
						NewInterval.Begin = CurrentInterval.Begin;
						NewInterval.Ending = NextInterval.Ending;
						NewInterval.ParallelLoad = True;
						ParallelIntervals.Add(NewInterval);
						
						NewInterval = ScheduleData_.Add();
						FillPropertyValues(NewInterval, NextInterval);
						NewInterval.Begin = NextInterval.Ending;
						NewInterval.Ending = CurrentInterval.Ending;
						ParallelIntervals.Add(NewInterval);
						
						NextInterval.Ending = CurrentInterval.Begin;
						
					EndIf;
					
				Else
					
					NewInterval = ScheduleData_.Add();
					FillPropertyValues(NewInterval, NextInterval);
					NewInterval.Begin = CurrentInterval.Begin;
					NewInterval.Ending = CurrentInterval.Ending;
					NewInterval.ParallelLoad = True;
					ParallelIntervals.Add(NewInterval);
					
					NewInterval = ScheduleData_.Add();
					FillPropertyValues(NewInterval, NextInterval);
					NewInterval.Begin = CurrentInterval.Ending;
					ParallelIntervals.Add(NewInterval);
					
					NextInterval.Ending = CurrentInterval.Begin;
					
				EndIf;
				
			EndIf;
			
			Ending = Max(Ending, CurrentInterval.Ending);
			Break;
		EndIf;
		
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

Procedure FillInLinkKeyModel(ScheduleData_)
	
	If ValueIsFilled(ScheduleData_) Then
		
		PlanningModel = ScheduleData_[0].PlanningModel;
		TimetableModel = ScheduleData_[0].TimetableModel;
		ConnectionKey = ?(ValueIsFilled(PlanningModel), 1, 0);
		
		For Each String In ScheduleData_ Do
			
			If Not String.PlanningModel = PlanningModel
				Or Not String.TimetableModel = TimetableModel Then
				
				ConnectionKey = ConnectionKey + 1;
				PlanningModel = String.PlanningModel;
				TimetableModel = String.TimetableModel;
				
			EndIf;
			
			String.CommunicationKeyModel = ConnectionKey;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure AddCompletedOperationInterval(ScheduleData_, CurrentInterval)
	
	AddInterval = True;
	
	FilterStructure1 = New Structure("PlanningModel, WorkCenter, IntervalDate");
	FillPropertyValues(FilterStructure1, CurrentInterval);
	Intervals = ScheduleData_.FindRows(FilterStructure1);
	For Each Interval In Intervals Do
		
		If CurrentInterval.Begin >= Interval.Ending
			Or CurrentInterval.Ending <= Interval.Begin Then
			Continue;
		EndIf;
		
		AddInterval = False;
		Break;
		
	EndDo;
	
	If AddInterval Then
		
		NewRow = ScheduleData_.Add();
		FillPropertyValues(NewRow, CurrentInterval);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region GraphicDesignOfChartElements

Function ImageWorkCenter()
	
	Return PictureLib.WorkCenter;
	
EndFunction

Function PictureAuxiliaryWorkCenter()
	
	Return PictureLib.Pin;
	
EndFunction

Function ImageAdditionalWorkCenter()
	
	Return PictureLib.CreateListItem;
	
EndFunction

Function PicturePlanningModel()
	
	Return PictureLib.DataCompositionOutputParameters;
	
EndFunction

Function IntervalColor(State, Perform=Undefined, ParallelLoad=False)
	
	Result = WebColors.Gold;
	
	If State = TextWork() Then
		
		If ParallelLoad Then
			Result = WebColors.Plum;
		ElsIf Perform = Enums.OperationExecutionStatuses.NotStarted_ Then
			Result = WebColors.Gold;
		ElsIf Perform = Enums.OperationExecutionStatuses.Started_ Then
			Result = WebColors.LightBlue;
		ElsIf Perform = Enums.OperationExecutionStatuses.Completed Then
			Result = WebColors.LightGreen;
		EndIf;
		
	ElsIf State = TextRepair() Then
		
		Result = WebColors.Coral;
		
	ElsIf State = TextChangeover() Then
		
		Result = WebColors.Tan;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region AddingChartNotationToForm

// Parameters:
// 	Form - Form, ClientApplicationForm - 
// 	GroupName - String - 
// Returns:
// 	FormGroup - 
Function AddNotationGroupToForm(Form, GroupName)
	
	Result = Form.Items.Add(GroupName, Type("FormGroup"));
	
	Result.Type = FormGroupType.UsualGroup;
	Result.Title = NStr("vi = 'Ký hiệu';
						|ru = 'Обозначения';
						|en = 'Designations'; fa = 'نشانه‌ها';
						|it = 'Designazione';
						|pl = 'Designations';
						|tr = 'Tanımlamalar'");
	Result.Behavior = UsualGroupBehavior.Collapsible;
	Result.CollapsedRepresentationTitle = NStr("vi = 'Hiển thị chỉ định';
												|ru = 'Показать обозначения';
												|en = 'Legend'; fa = 'راهنما';
												|it = 'Mostra le designazioni';
												|pl = 'Pokaż oznaczenia';
												|tr = 'Tanımlamaları göster'");
	Result.ControlRepresentation = UsualGroupControlRepresentation.Picture;
	Result.Representation = UsualGroupRepresentation.None;
	Result.Group = ChildFormItemsGroup.Vertical;
	Result.ToolTip = NStr("vi = 'Ký hiệu phần tử biểu đồ';
							|ru = 'Обозначения элементов диаграммы';
							|en = 'Chart item designations'; fa = 'نمادهای اقلام نمودار';
							|it = 'Designazione degli elementi del diagramma';
							|pl = 'Oznaczenia elementów wykresu';
							|tr = 'Grafik öğelerini tanılama'");
	
	Return Result;
	
EndFunction

Procedure AddImageLegendToList(Form, DesignationGroup, WorkCenters, Modeling)
	
	LegendGroup = AddLegendGroupToForm(Form, DesignationGroup, "GroupLegendPictures");
	
	If WorkCenters Then
		AddWorkCenterDescriptionToLegend(Form, LegendGroup);
		AddDescriptionOfRegionalServiceWorkCenterToLegend(Form, LegendGroup);
	EndIf;
	
	If Modeling Then
		AddDescriptionOfAdditionalWorkCenterToLegend(Form, LegendGroup);
		AddPlanningModelDescriptionToLegend(Form, LegendGroup);
	EndIf;
	
EndProcedure

Procedure AddWorkCenterDescriptionToLegend(Form, Parent)
	
	Picture = ImageWorkCenter();
	Explanation = NStr("vi = '- nguồn lực sản xuất';
						|ru = '- рабочий центр';
						|en = '- work center'; fa = '- work center';
						|it = '- centro di lavoro';
						|pl = '- stanowisko pracy';
						|tr = '- iş merkezi'");
	
	DetailsGroup = AddItemDescriptionGroupToForm(Form, Parent, "GroupWorkCenter");
	AddImageOfPlaceToDescription(Form, DetailsGroup, "ImageWorkCenter", Picture);
	AddExplanationOfItemToDescription(Form, DetailsGroup, "ExplanationWorkCenter", Explanation);
	
EndProcedure

Procedure AddDescriptionOfRegionalServiceWorkCenterToLegend(Form, Parent)
	
	Picture = PictureAuxiliaryWorkCenter();
	Explanation = NStr("vi = '- nguồn lực sản xuất phụ trợ';
						|ru = '- вспомогательный рабочий центр';
						|en = '- secondary work center'; fa = '- secondary work center';
						|it = '- centro di lavoro ausiliario';
						|pl = '- pomocnicze stanowisko pracy';
						|tr = '- yardımcı iş merkezi'");
	
	DetailsGroup = AddItemDescriptionGroupToForm(Form, Parent, "GroupAuxiliaryWorkCenter");
	AddImageOfPlaceToDescription(Form, DetailsGroup, "PictureAuxiliaryWorkCenter", Picture);
	AddExplanationOfItemToDescription(Form, DetailsGroup, "ExplanationAuxiliaryWorkCenter", Explanation);
	
EndProcedure

Procedure AddDescriptionOfAdditionalWorkCenterToLegend(Form, Parent)
	
	Picture = ImageAdditionalWorkCenter();
	Explanation = NStr("vi = '- nguồn lực sản xuất bổ sung';
						|ru = '- дополнительный рабочий центр';
						|en = '- additional work center'; fa = '- additional work center';
						|it = '- centro di lavoro aggiuntivo';
						|pl = '- dodatkowe stanowisko pracy';
						|tr = '- ek iş merkezi'");
	
	DetailsGroup = AddItemDescriptionGroupToForm(Form, Parent, "AdditionalWorkCenterGroup");
	AddImageOfPlaceToDescription(Form, DetailsGroup, "ImageAdditionalWorkCenter", Picture);
	AddExplanationOfItemToDescription(Form, DetailsGroup, "ExplanationAdditionalWorkCenter", Explanation);
	
EndProcedure

Procedure AddPlanningModelDescriptionToLegend(Form, Parent)
	
	Picture = PicturePlanningModel();
	Explanation = NStr("vi = '- mô hình lập kế hoạch';
						|ru = '- модель планирования';
						|en = '- planning model'; fa = '- planning model';
						|it = 'Modello di pianificazione';
						|pl = '- model planowania';
						|tr = '- planlama modeli'");
	
	DetailsGroup = AddItemDescriptionGroupToForm(Form, Parent, "GroupPlanningModel");
	AddImageOfPlaceToDescription(Form, DetailsGroup, "PicturePlanningModel", Picture);
	AddExplanationOfItemToDescription(Form, DetailsGroup, "ExplanationPlanningModel", Explanation);
	
EndProcedure

Procedure AddLegendOfColorsToNotation(Form, DesignationGroup)
	
	LegendGroup = AddLegendGroupToForm(Form, DesignationGroup, "GroupLegendColorOperations");
	
	AddLegendForProcessingAndAssemblyOperations(Form, LegendGroup);
	AddLegendForOtherOperations(Form, LegendGroup);
	
EndProcedure

Procedure AddLegendForProcessingAndAssemblyOperations(Form, Parent)
	
	GroupName = "GroupLegendColorOperationsProcessingAssembly";
	GroupTitle = NStr("vi = 'Giao dịch xử lý và gom';
						|ru = 'Операции обработки и сборки';
						|en = 'Operations of processing and assembly'; fa = 'Operations of processing and assembly';
						|it = 'Operazioni di elaborazione e assemblaggio';
						|pl = 'Operacje przetwarzania i montażu';
						|tr = 'İşleme ve montaj işlemleri'");
	FlowerLegendGroup = AddColorLegendGroupToForm(Form, Parent, GroupName, GroupTitle);
	
	GroupNotStartedParallelDownload = AddNotStartedParallelLoadingGroupToForm(Form, FlowerLegendGroup);
	AddColorDescriptionNotStartedToLegend(Form, GroupNotStartedParallelDownload);
	AddColorDescriptionToLegendParallelLoading(Form, GroupNotStartedParallelDownload);
	
	AddColorDescriptionToLegendStarted(Form, FlowerLegendGroup);
	AddColorDescriptionToLegendEnd(Form, FlowerLegendGroup);
	
EndProcedure

Procedure AddLegendForOtherOperations(Form, Parent)
	
	GroupName = "ColorLegendGroupOtherOperations";
	GroupTitle = NStr("vi = 'Giao dịch khác';
						|ru = 'Прочие операции';
						|en = 'Other operations'; fa = 'سایر عملیات';
						|it = 'Altre operazioni';
						|pl = 'Inne operacje';
						|tr = 'Diğer işlemler'");
	FlowerLegendGroup = AddColorLegendGroupToForm(Form, Parent, GroupName, GroupTitle);
	
	AddColorDescriptionToLegendChangeover(Form, FlowerLegendGroup);
	
	If GetFunctionalOption("UseRMManagement") Then
		AddColorDescriptionToLegendRepair(Form, FlowerLegendGroup);
	Else
		AddIndentationToGroup(Form, FlowerLegendGroup, "DecorationAndRepair");
	EndIf;
		
EndProcedure

Function AddLegendGroupToForm(Form, Parent, GroupName)
	
	Result = Form.Items.Add(GroupName, Type("FormGroup"), Parent);
	
	Result.Type = FormGroupType.UsualGroup;
	Result.Representation = UsualGroupRepresentation.None;
	Result.Group = ChildFormItemsGroup.Horizontal;
	Result.ShowTitle = False;
	
	Return Result;
	
EndFunction

Function AddColorLegendGroupToForm(Form, Parent, GroupName, GroupTitle)
	
	Result = Form.Items.Add(GroupName, Type("FormGroup"), Parent);
	
	Result.Title = GroupTitle;
	Result.Type = FormGroupType.UsualGroup;
	Result.Representation = UsualGroupRepresentation.StrongSeparation;
	Result.Group = ChildFormItemsGroup.Vertical;
	Result.ShowTitle = True;
	
	Return Result;
	
EndFunction

Function AddNotStartedParallelLoadingGroupToForm(Form, Parent)
	
	GroupName = "GroupLegendColorOperationsNotStartedParallelLoading";
	Result = Form.Items.Add(GroupName, Type("FormGroup"), Parent);
	
	Result.Type = FormGroupType.UsualGroup;
	Result.Representation = UsualGroupRepresentation.None;
	Result.Group = ChildFormItemsGroup.Horizontal;
	Result.ShowTitle = False;
	
	Return Result;
	
EndFunction

Procedure AddColorDescriptionNotStartedToLegend(Form, Parent)
	
	State = TextWork();
	Perform = Enums.OperationExecutionStatuses.NotStarted_;
	Color = IntervalColor(State, Perform);
	
	Explanation = NStr("vi = 'Bắt đầu chưa thực hiện';
						|ru = 'Выполнение не начато';
						|en = 'Execution is not started'; fa = 'Execution is not started';
						|it = 'Esecuzione non avviata';
						|pl = 'Wykonanie nie rozpoczęto';
						|tr = 'Gerçekleştirme başlatılmadı'");
	
	DetailsGroup = AddItemDescriptionGroupToForm(Form, Parent, "GroupExecutionNotStarted");
	AddColorPresentationToDescription(Form, DetailsGroup, "ColorExecutionNotStarted", Color);
	AddExplanationOfItemToDescription(Form, DetailsGroup, "ExplanationExecutionNotStarted", Explanation);
	
EndProcedure

Procedure AddColorDescriptionToLegendParallelLoading(Form, Parent)
	
	State = TextWork();
	Color = IntervalColor(State,, True);
	
	Explanation = NStr("vi = 'Kết nhập song song';
						|ru = 'Параллельная загрузка';
						|en = 'Parallel load'; fa = 'بار موازی';
						|it = 'Caricamento parallelo';
						|pl = 'Równoległe obciążenie';
						|tr = 'Paralel çalışma yükü'");
	
	DetailsGroup = AddItemDescriptionGroupToForm(Form, Parent, "ParallelLoadingGroup");
	AddColorPresentationToDescription(Form, DetailsGroup, "ColorParallelLoading", Color);
	AddExplanationOfItemToDescription(Form, DetailsGroup, "ExplanationParallelLoading", Explanation);
	
EndProcedure

Procedure AddColorDescriptionToLegendStarted(Form, Parent)
	
	State = TextWork();
	Perform = Enums.OperationExecutionStatuses.Started_;
	Color = IntervalColor(State, Perform);
	
	Explanation = NStr("vi = 'Bắt đầu thực hiện';
						|ru = 'Выполнение начато';
						|en = 'Execution is started'; fa = 'اجرا شروع شده است';
						|it = 'Esecuzione iniziata';
						|pl = 'Wykonanie rozpoczęto';
						|tr = 'Gerçekleştirme başlatıldı'");
	
	DetailsGroup = AddItemDescriptionGroupToForm(Form, Parent, "GroupExecutionStarted");
	AddColorPresentationToDescription(Form, DetailsGroup, "ColorExecutionStarted", Color);
	AddExplanationOfItemToDescription(Form, DetailsGroup, "ExplanationExecutionStarted", Explanation);
	
EndProcedure

Procedure AddColorDescriptionToLegendEnd(Form, Parent)
	
	Return; // Completed operations are not displayed in the diagram.
	
	State = TextWork();
	Perform = Enums.OperationExecutionStatuses.Completed;
	Color = IntervalColor(State, Perform);
	
	Explanation = NStr("vi = 'Hoàn thành ';
						|ru = 'Выполнение завершено';
						|en = 'Execution is completed'; fa = 'اجرا تکمیل شده است';
						|it = 'L''esecuzione è stata completata';
						|pl = 'Wykonanie zakończono';
						|tr = 'Gerçekleştirme tamamlandı'");
	
	DetailsGroup = AddItemDescriptionGroupToForm(Form, Parent, "GroupExecutionCompleted");
	AddColorPresentationToDescription(Form, DetailsGroup, "ColorExecutionCompleted", Color);
	AddExplanationOfItemToDescription(Form, DetailsGroup, "ExplanationExecutionCompleted", Explanation);
	
EndProcedure

Procedure AddColorDescriptionToLegendChangeover(Form, Parent)
	
	State = TextChangeover();
	Color = IntervalColor(State);
	
	DetailsGroup = AddItemDescriptionGroupToForm(Form, Parent, "ChangeoverGroup");
	AddColorPresentationToDescription(Form, DetailsGroup, "ColorChangeover", Color);
	AddExplanationOfItemToDescription(Form, DetailsGroup, "ExplanationChangeover", State);
	
EndProcedure

Procedure AddColorDescriptionToLegendRepair(Form, Parent)
	
	State = TextRepair();
	Color = IntervalColor(State);
	
	DetailsGroup = AddItemDescriptionGroupToForm(Form, Parent, "RepairGroup");
	AddColorPresentationToDescription(Form, DetailsGroup, "ColorRepair", Color);
	AddExplanationOfItemToDescription(Form, DetailsGroup, "ExplanationRepair", State);
	
EndProcedure

Function AddItemDescriptionGroupToForm(Form, Parent, GroupName)
	
	Result = Form.Items.Add(GroupName, Type("FormGroup"), Parent);
	
	Result.Type = FormGroupType.UsualGroup;
	Result.Representation = UsualGroupRepresentation.None;
	Result.Group = ChildFormItemsGroup.Horizontal;
	Result.ShowTitle = False;
	
	Return Result;
	
EndFunction

Procedure AddImageOfPlaceToDescription(Form, Parent, TagName, Picture)
	
	NewItem = Form.Items.Add(TagName, Type("FormDecoration"), Parent);
	
	NewItem.Type = FormDecorationType.Picture;
	NewItem.Picture = Picture;
	NewItem.Width = 2;
	NewItem.Height = 1;
	
EndProcedure

Procedure AddExplanationOfItemToDescription(Form, Parent, TagName, Explanation)
	
	NewItem = Form.Items.Add(TagName, Type("FormDecoration"), Parent);
	
	NewItem.Type = FormDecorationType.Label;
	NewItem.Title = Explanation;
	
EndProcedure

Procedure AddColorPresentationToDescription(Form, Parent, TagName, Color)
	
	NewItem = Form.Items.Add(TagName, Type("FormDecoration"), Parent);
	
	NewItem.Title = NStr("vi = 'Màu sắc';
						|ru = 'Цвет';
						|en = 'Color'; fa = 'رنگ';
						|it = 'Colore';
						|pl = 'Color';
						|tr = 'Renk'");
	NewItem.Type = FormDecorationType.Label;
	NewItem.TextColor = Color;
	NewItem.BackColor = Color;
	NewItem.BorderColor = WebColors.Black;
	NewItem.Border = New Border(ControlBorderType.Single);
	
EndProcedure

Procedure AddIndentationToGroup(Form, Parent, TagName)
	
	NewItem = Form.Items.Add(TagName, Type("FormDecoration"), Parent);
	NewItem.Type = FormDecorationType.Label;
	
EndProcedure

#EndRegion

#Region DrillDownOfParallelLoadOfWorkCenter

Procedure DecryptParallelDownload(Parameters, GanttChart)
	
	ScheduleData_ = ParallelLoadedIntervalData(Parameters);
	DisplayParallelLoadingScheduleInDiagram(Parameters, GanttChart, ScheduleData_);
	CreateParallelLoadingDiagram(Parameters, GanttChart);
	
EndProcedure

Function ParallelLoadedIntervalData(Parameters)
	
	QueryText = QueryTextDrillDownOfParallelLoadOfWorkCenter();
	
	Query = New Query(QueryText);
	Query.SetParameter("Begin", Parameters.Begin);
	Query.SetParameter("Ending", Parameters.Ending);
	Query.SetParameter("WorkCenter", Parameters.WorkCenter);
	Query.SetParameter("TimetableModel", Parameters.TimetableModel);
	Query.SetParameter("PlanningModel", Parameters.PlanningModel);
	
	Query.SetParameter("Departments", Parameters.Departments);
	Query.SetParameter("FilterDepartments", ValueIsFilled(Parameters.Departments));
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	Query.SetParameter("TextChangeover", TextChangeover());
	Query.SetParameter("TextWork", TextWork());
	Query.SetParameter("TextRepair", TextRepair());
	
	Return Query.Execute();
	
EndFunction

Function QueryTextDrillDownOfParallelLoadOfWorkCenter()
	
	Result = 
	"SELECT
	|	PostOperativeSchedule.PlanningModel AS PlanningModel,
	|	PostOperativeSchedule.Stage AS Stage,
	|	PostOperativeSchedule.Stage AS Details,
	|	PostOperativeSchedule.Stage.Number AS StageNumber,
	|	PostOperativeSchedule.Stage.Date AS StageDate,
	|	PostOperativeSchedule.Begin AS Begin,
	|	PostOperativeSchedule.Ending AS Ending,
	|	SUM(PostOperativeSchedule.Load) AS Load,
	|	PostOperativeSchedule.WorkCenter.WorkCenterType.UnitOfMeasureOfLoad AS UnitOfMeasureOfLoad,
	|	PostOperativeSchedule.Operation AS OperationPresentation,
	|	CASE
	|		WHEN PostOperativeSchedule.ThisIsChangeover
	|			THEN &TextChangeover
	|		ELSE &TextWork
	|	END AS State,
	|	CASE
	|		WHEN PostOperativeSchedule.Completed2 = (PostOperativeSchedule.LotQuantity + PostOperativeSchedule.Skipped3 - PostOperativeSchedule.RepetitionIsRequired)
	|			THEN VALUE(Enum.OperationExecutionStatuses.Completed)
	|		WHEN PostOperativeSchedule.Running > 0
	|			THEN VALUE(Enum.OperationExecutionStatuses.Started_)
	|		ELSE VALUE(Enum.OperationExecutionStatuses.NotStarted_)
	|	END AS Perform,
	|	FALSE AS ParallelLoad,
	|	PostOperativeSchedule.Operation AS Operation,
	|	PostOperativeSchedule.LotNumber AS LotNumber
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|WHERE
	|	(PostOperativeSchedule.Begin >= &Begin
	|				AND PostOperativeSchedule.Begin < &Ending
	|			OR PostOperativeSchedule.Ending > &Begin
	|				AND PostOperativeSchedule.Ending <= &Ending)
	|	AND PostOperativeSchedule.WorkCenter = &WorkCenter
	|	AND PostOperativeSchedule.TimetableModel = &TimetableModel
	|	AND PostOperativeSchedule.PlanningModel = &PlanningModel
	|	AND (NOT &FilterDepartments
	|			OR PostOperativeSchedule.Department IN (&Departments))
	|	AND PostOperativeSchedule.LotQuantity > (PostOperativeSchedule.LotQuantity + PostOperativeSchedule.Skipped3 - PostOperativeSchedule.RepetitionIsRequired)
	|
	|GROUP BY
	|	PostOperativeSchedule.PlanningModel,
	|	PostOperativeSchedule.Stage,
	|	PostOperativeSchedule.Stage,
	|	PostOperativeSchedule.Stage.Number,
	|	PostOperativeSchedule.Stage.Date,
	|	PostOperativeSchedule.Begin,
	|	PostOperativeSchedule.Ending,
	|	PostOperativeSchedule.WorkCenter.WorkCenterType.UnitOfMeasureOfLoad,
	|	PostOperativeSchedule.Operation,
	|	PostOperativeSchedule.Operation,
	|	PostOperativeSchedule.LotNumber,
	|	CASE
	|		WHEN PostOperativeSchedule.ThisIsChangeover
	|			THEN &TextChangeover
	|		ELSE &TextWork
	|	END,
	|	CASE
	|		WHEN PostOperativeSchedule.Completed2 = (PostOperativeSchedule.LotQuantity + PostOperativeSchedule.Skipped3 - PostOperativeSchedule.RepetitionIsRequired)
	|			THEN VALUE(Enum.OperationExecutionStatuses.Completed)
	|		WHEN PostOperativeSchedule.Running > 0
	|			THEN VALUE(Enum.OperationExecutionStatuses.Started_)
	|		ELSE VALUE(Enum.OperationExecutionStatuses.NotStarted_)
	|	END
	|
	|ORDER BY
	|	Begin,
	|	Ending,
	|	PostOperativeSchedule.Stage.PointInTime
	|TOTALS BY
	|	Stage,
	|	Operation,
	|	LotNumber";
	
	Return Result;
	
EndFunction

Procedure DisplayParallelLoadingScheduleInDiagram(Parameters, GanttChart, ScheduleData_)
	
	GanttChart.RefreshEnabled = False;
	GanttChart.Clear();
	
	Series = DefaultSeries(GanttChart);
	
	SamplingStagesOfProduction = ScheduleData_.Select(QueryResultIteration.ByGroups);
	While SamplingStagesOfProduction.Next() Do
		
		PointOfProductionStage = PointDiagramProductionStage(SamplingStagesOfProduction, GanttChart);
		
		SelectionOfOperations = SamplingStagesOfProduction.Select(QueryResultIteration.ByGroups);
		While SelectionOfOperations.Next() Do 
			
			SampleBatchNumbers = SelectionOfOperations.Select(QueryResultIteration.ByGroups);
			While SampleBatchNumbers.Next() Do
				
				PointPartyOperation = PointDiagramBatchOperation(SampleBatchNumbers, GanttChart);
				Value = GanttChart.GetValue(PointPartyOperation, Series);
				
				Selection = SampleBatchNumbers.Select();
				While Selection.Next() Do
					Interval = Value.Add();
					Interval.Begin = Selection.Begin;
					Interval.End = Selection.Ending;
					Interval.Color = ChartIntervalColor(Parameters, Selection);
					Interval.Text = IntervalHint(Selection);
					Interval.Details = IntervalDetails1(Selection);
				EndDo;
		
			EndDo;
	
		EndDo;
		
	EndDo;
	
	GanttChart.RefreshEnabled = True;
	
EndProcedure

Function PointDiagramProductionStage(Val FillingValues, GanttChart)
	
	Result = GanttChart.SetPoint(FillingValues.Stage);
	Result.Text = ProductionStagePresentation(FillingValues.StageNumber, FillingValues.StageDate);
	Result.Details = FillingValues.Stage;
	
	Return Result;
	
EndFunction

Function ProductionStagePresentation(Number, Date)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Công đoạn số %1 ngày %2';
			|ru = 'Этап №%1 от %2';
			|en = 'Stage No.%1 from %2'; fa = 'Stage No.%1 from %2';
			|it = 'Fase №%1 di %2';
			|pl = 'Etap Nr%1 z dnia %2';
			|tr = '%2 tarihli %1 numaralı aşama'"),
		ObjectsPrefixesClientServer.NumberForPrinting(Number, False, True),
		Format(Date, "DLF=D"));
	
EndFunction

Function PointDiagramBatchOperation(Val FillingValues, GanttChart)
	
	PointValue = New Structure("Stage, Operation, LotNumber");
	FillPropertyValues(PointValue, FillingValues);
	
	Result = GanttChart.SetPoint(PointValue, FillingValues.Stage);
	Result.Text = PresentationOfOperationBatch(FillingValues.Operation, FillingValues.LotNumber);
	Result.Details = FillingValues.Stage;
	
	Return Result;
	
EndFunction

Function PresentationOfOperationBatch(Operation, LotNumber)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Giao dịch ""%1"", lô %2';
			|ru = 'Операция ""%1"", партия %2';
			|en = 'Operation ""%1"", %2 lot'; fa = 'Operation ""%1"", %2 lot';
			|it = 'Operazione ""%1"", partita %2';
			|pl = 'Operacja ""%1"", partia %2';
			|tr = '""%1"" işlemi, %2 lotu'"), Operation, LotNumber);
	
EndFunction
	
Procedure CreateParallelLoadingDiagram(Parameters, GanttChart)
	
	SetGeneralChartProperties(GanttChart);
	SetChartPeriodicity(Parameters, GanttChart);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
