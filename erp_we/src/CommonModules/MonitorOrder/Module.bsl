
#Region Internal

// Adjust the time scale.
// 
// Parameters:
//  GanttChart - GanttChart - Gantt Chart
//  BeginOfPeriod - Date - Beginning of the period
//  EndOfPeriod - Date - End of the period
Procedure AdjustTimeScale(GanttChart, BeginOfPeriod, EndOfPeriod) Export
	
	// Time scale
	TimelineElements = GanttChart.PlotArea.TimeScale.Items;
	
	ThereWereElements = TimelineElements.Count();
	
	If (EndOfPeriod - BeginOfPeriod > 50 * 86400) Then
		TimelineElements.Add().Unit = TimeScaleUnitType.Month;
		TimelineElements.Add().Unit = TimeScaleUnitType.Day;
	Else
		TimelineElements.Add().Unit = TimeScaleUnitType.Week;
		TimelineElements.Add().Unit = TimeScaleUnitType.Day;
	EndIf;
	
	If ThereWereElements > 0 Then
		For Cnt = 0 To ThereWereElements - 1 Do
			TimelineElements.Delete(TimelineElements[0]);
		EndDo;
	EndIf;
	
	If GanttChart.PlotArea.TimeScale.Items[0].Unit = TimeScaleUnitType.Month Then
		BeginOfPeriod = BegOfMonth(BeginOfPeriod);
		EndOfPeriod  = EndOfMonth(EndOfPeriod);
	Else
		BeginOfPeriod = BegOfWeek(BeginOfPeriod);
		EndOfPeriod  = EndOfWeek(EndOfPeriod);
	EndIf;
	
	// Output allocation
	GanttChart.BackgroundIntervals.Clear();
	
	Schedules = New Array();
	Schedules.Add(Constants.MainEnterpriseCalendar.Get());
	
	WorkSchedules1 = ProductionPlanning.ScheduleOfWorkOnSchedule(Schedules, BeginOfPeriod, EndOfPeriod);
	WorkSchedules1.GroupBy("ScheduleDate");
	WorkSchedules1.Indexes.Add("ScheduleDate");
	
	PeriodsOfUnavailability = New ValueTable();
	PeriodsOfUnavailability.Columns.Add("Begin",    New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	PeriodsOfUnavailability.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	
	CurrentPeriod = BeginOfPeriod;
	While CurrentPeriod <= EndOfPeriod Do
		
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
	
#EndRegion