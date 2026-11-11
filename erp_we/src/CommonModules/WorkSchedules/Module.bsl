///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns dates that differ from the specified date DateFrom by the number of days
// included in the specified schedule WorkScheduleCalendar.
//
// Parameters:
//  WorkScheduleCalendar	- CatalogRef.Calendars - schedule to be used.
//  DateFrom			- Date - a date starting from which the number of days is to be calculated.
//  DaysArray		- Array - a number of days by which the start date is to be increased.
//  CalculateNextDateFromPrevious	- Boolean - shows whether the following date is to be calculated 
//											           from the previous one or all dates are calculated from the passed date.
//  RaiseException1 - Boolean - if True, an exception is thrown if the schedule is not filled in.
//
// Returns:
//  Array, Undefined - Dates incremented by the number of days from WorkSchedule.
//	                       If WorkSchedule is empty and RaiseException = False, return Undefined.
//
Function DatesBySchedule(Val WorkScheduleCalendar, Val DateFrom, Val DaysArray, 
	Val CalculateNextDateFromPrevious = False, RaiseException1 = True) Export
	
	ShiftDays = CalendarSchedules.DaysIncrement(DaysArray, CalculateNextDateFromPrevious);
	
	Query = New Query;
	Query.SetParameter("DateFrom", BegOfDay(DateFrom));
	Query.SetParameter("WorkScheduleCalendar", WorkScheduleCalendar);
	Query.SetParameter("Days", ShiftDays.DaysIncrement.UnloadColumn("DaysCount"));
	Query.Text =
		"SELECT TOP 0
		|	CalendarSchedules.ScheduleDate AS Date
		|FROM
		|	InformationRegister.CalendarSchedules AS CalendarSchedules
		|WHERE
		|	CalendarSchedules.ScheduleDate > &DateFrom
		|	AND CalendarSchedules.Calendar = &WorkScheduleCalendar
		|	AND CalendarSchedules.DayAddedToSchedule
		|
		|ORDER BY
		|	Date";

	// Limit the selection by the maximum shift value to avoid oversized day selection.
	QuerySchema = New QuerySchema();
	QuerySchema.SetQueryText(Query.Text);
	QuerySchema.QueryBatch[0].Operators[0].RetrievedRecordsCount = ShiftDays.Max;
	Query.Text = QuerySchema.GetQueryText();
	
	RequestedDays = New Map();
	For Each TableRow In ShiftDays.DaysIncrement Do
		RequestedDays.Insert(TableRow.DaysCount, False);
	EndDo;
	
	Selection = Query.Execute().Select();
	If Selection.Count() < ShiftDays.Max Then
		If RaiseException1 Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền lịch làm việc ""%1"" từ ngày %2 với số ngày làm việc đã chỉ định.';
					|ru = 'График работы ""%1"" не заполнен с даты %2 на указанное количество рабочих дней.';
					|en = 'Cannot determine the date because work schedule ""%1"" is not filled for the specified number of workdays after %2.'; fa = 'Cannot determine the date because work schedule ""%1"" is not filled for the specified number of workdays after %2.';
					|it = 'Il grafico di lavoro ""%1"" non è compilato dalla data %2 al numero indicato di giorni di lavoro.';
					|pl = 'Harmonogram pracy ""%1"" nie jest wypełniony od daty %2 na wskazaną ilość dni roboczych.';
					|tr = '""%1"" Çalışma takvimi belirtilen sayıda çalışma günü için %2 tarihinden itibaren doldurulmamıştır.'"), 
				WorkScheduleCalendar, 
				Format(DateFrom, "DLF=D"));
		Else
			Return Undefined;
		EndIf;
	EndIf;
	
	RequestedDays.Insert(0, DateFrom);
	OfDays = 0;
	While Selection.Next() Do
		OfDays = OfDays + 1;
		If RequestedDays[OfDays] = False Then
			RequestedDays.Insert(OfDays, Selection.Date);
		EndIf;
	EndDo;
	
	DatesArray = New Array;
	For Each TableRow In ShiftDays.DaysIncrement Do
		Date = RequestedDays[TableRow.DaysCount];
		CommonClientServer.Validate(TypeOf(Date) = Type("Date") And ValueIsFilled(Date));
		DatesArray.Add(Date);
	EndDo;
	
	Return DatesArray;
	
EndFunction

// Returns a date that differs from the specified date DateFrom by the number of days
// included in the specified schedule WorkScheduleCalendar.
//
// Parameters:
//  WorkScheduleCalendar	- CatalogRef.Calendars - schedule to be used.
//  DateFrom			- Date - a date starting from which the number of days is to be calculated.
//  DaysCount	- Number - number of days by which the start date DateFrom is to be increased.
//  RaiseException1 - Boolean - if True, an exception is thrown if the schedule is not filled in.
//
// Returns:
//  Date, Undefined - Date incremented by the number of days from WorkSchedule.
//	                     If WorkSchedule is empty and RaiseException = False, return Undefined.
//
Function DateAccordingToSchedule(Val WorkScheduleCalendar, Val DateFrom, Val DaysCount, RaiseException1 = True) Export
	
	DateFrom = BegOfDay(DateFrom);
	
	If DaysCount = 0 Then
		Return DateFrom;
	EndIf;
	
	DaysArray = New Array;
	DaysArray.Add(DaysCount);
	
	DatesArray = DatesBySchedule(WorkScheduleCalendar, DateFrom, DaysArray, , RaiseException1);
	
	Return ?(DatesArray <> Undefined, DatesArray[0], Undefined);
	
EndFunction

// The constructor of parameters for getting dates nearest to the dates included in the schedule.
//  See NearestWorkDates.
// 
// Returns:
//  Structure:
//   * GetPrevious - Boolean - Method that gets the closest date::
//       If True, workdays preceding the ones passed in the InitialDates parameter are defined.
//       If False, the nearest workdays following the start dates are defined.
//       By default, False:
//   * IgnoreUnfilledSchedule - Boolean - if True, a map returns in any way.
//       Initial dates whose values are missing because of unfilled schedule will not be included.
//       False - a default value:
//   * RaiseException1 - Boolean - raising an exception if the schedule is not filled in
//       If True, raise an exception if the schedule is not filled in.
//       If False, dates whose nearest date is not identified will be ignored.
//       The default value is True.
//
Function NearestDatesByScheduleReceivingParameters() Export
	Parameters = New Structure(
		"GetPrevious,
		|IgnoreUnfilledSchedule,
		|RaiseException1");
	Parameters.GetPrevious = False;
	Parameters.IgnoreUnfilledSchedule = False;
	Parameters.RaiseException1 = True;
	Return Parameters;
EndFunction

// Defines a date of the nearest workday included in the schedule for each date.
//
// Parameters:
//  WorkScheduleCalendar		 - CatalogRef.Calendars
//  InitialDates		 - Array of Date - dates to which the nearest ones must be detected.
//  ReceivingParameters	 - See NearestDatesByScheduleReceivingParameters.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - Date - start date.
//   * Value - Date - the date nearest to it and included in the schedule.
//
Function NearestDatesIncludedInSchedule(WorkScheduleCalendar, InitialDates, ReceivingParameters = Undefined) Export
	
	If ReceivingParameters = Undefined Then
		ReceivingParameters = NearestDatesByScheduleReceivingParameters();
	EndIf;
	
	CommonClientServer.CheckParameter(
		"WorkSchedules.NearestDatesIncludedInSchedule", 
		"WorkScheduleCalendar", 
		WorkScheduleCalendar, 
		Type("CatalogRef.Calendars"));

	CommonClientServer.Validate(
		ValueIsFilled(WorkScheduleCalendar), 
		NStr("vi = 'Lịch trình làm việc không được chỉ định.';
			|ru = 'Не указан график работы.';
			|en = 'Work schedule is not specified.'; fa = 'Work schedule is not specified.';
			|it = 'Orario di lavoro non indicato.';
			|pl = 'Nie podano harmonogramu pracy.';
			|tr = 'Çalışma takvimi belirtilmedi.'"), 
		"WorkSchedules.NearestDatesIncludedInSchedule");
	
	QueryTextTT = "";
	FirstPart = True;
	For Each InitialDate In InitialDates Do
		If Not ValueIsFilled(InitialDate) Then
			Continue;
		EndIf;
		If Not FirstPart Then
			QueryTextTT = QueryTextTT + "
			|UNION ALL
			|";
		EndIf;
		If FirstPart Then
			QueryText = "
			|SELECT
			|	DATETIME(2000,01,01) AS Date 
			|INTO TTInitialDates
			|";
		Else	
			QueryText = "
			|SELECT
			|	DATETIME(2000,01,01)";
		EndIf;
		QueryTextTT = QueryTextTT + StrReplace(QueryText, "2000,01,01", 
			Format(InitialDate, "DF=yyyy,MM,dd"));
		FirstPart = False;
	EndDo;

	If IsBlankString(QueryTextTT) Then
		Return New Map;
	EndIf;

	Query = New Query(QueryTextTT);
	Query.TempTablesManager = New TempTablesManager;
	Query.Execute();
	
	QueryText = 
		"SELECT
		|	InitialDates.Date,
		|	MIN(CalendarDates.ScheduleDate) AS NearestDate
		|FROM
		|	TTInitialDates AS InitialDates
		|		LEFT JOIN InformationRegister.CalendarSchedules AS CalendarDates
		|		ON (CalendarDates.ScheduleDate >= InitialDates.Date)
		|			AND (CalendarDates.Calendar = &Schedule)
		|			AND (CalendarDates.DayAddedToSchedule)
		|
		|GROUP BY
		|	InitialDates.Date";
	
	If ReceivingParameters.GetPrevious Then
		QueryText = StrReplace(QueryText, "MIN(CalendarDates.ScheduleDate)", "MAX(CalendarDates.ScheduleDate)");
		QueryText = StrReplace(QueryText, "CalendarDates.ScheduleDate >= InitialDates.Date", "CalendarDates.ScheduleDate <= InitialDates.Date");
	EndIf;
	Query.Text = QueryText;
	Query.SetParameter("Schedule", WorkScheduleCalendar);
	
	Selection = Query.Execute().Select();
	
	WorkdaysDates = New Map;
	While Selection.Next() Do
		If ValueIsFilled(Selection.NearestDate) Then
			WorkdaysDates.Insert(Selection.Date, Selection.NearestDate);
		Else 
			If ReceivingParameters.IgnoreUnfilledSchedule Then
				Continue;
			EndIf;
			If ReceivingParameters.RaiseException1 Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể xác định ngày được lên lịch gần nhất cho ngày %1,
						 |lịch có thể chưa được điền.';
						 |ru = 'Невозможно определить ближайшую дату, включенную в график, для даты %1, 
						 |возможно, график работы не заполнен.';
						 |en = 'Cannot determine the nearest date included in the schedule for date %1.
						 |The work schedule might be blank.'; fa = 'Cannot determine the nearest date included in the schedule for date %1.
						 |The work schedule might be blank.';
						 |it = 'Impossibile stabilire la data più vicina inclusa nell''orario, per la data %1,
						 | l''orario di lavoro potrebbe non essere compilato.';
						 |pl = 'Niemożliwe jest określenie najbliższej daty, włączonej do harmonogramu, dla daty %1, 
						 |możliwie nie wypełniono harmonogramu pracy.';
						 |tr = 'Programa dahil edilen en yakın tarih belirlenemiyor. %1 tarihi için
						 |çalışma takvimi doldurulmamış olabilir.'"), 
					Format(Selection.Date, "DLF=D"));
			Else
				Return Undefined;
			EndIf;
		EndIf;
	EndDo;
	
	Return WorkdaysDates;
	
EndFunction

// Generates work schedules for dates included in the specified schedules for the specified period.
// If the schedule for a pre-holiday day is not set, it is defined as if this day is a workday.
//
// Parameters:
//  Schedules       - Array of CatalogRef.Calendars - an array of items of the CatalogRef.Calendars type, for which schedules are created.
//  StartDate    - Date   - a start date of the period, for which schedules are to be created.
//  EndDate - Date   - a period end date.
//  RollingShifts - Boolean - if True, then the schedule intervals may cross the border of the day.
//    For example, the interval "03 Apr. 20:00-04:00" can be returned if the schedule is configured accordingly.
//    If the parameter value is False, then a similar schedule will be represented by two intervals:
//    "03 Apr. 20:00-00:00" and "04 Apr. 00:00-04:00".
//
// Returns:
//   ValueTable:
//    * WorkScheduleCalendar    - CatalogRef.Calendars - work schedule.
//    * ScheduleDate     - Date - a date in the WorkScheduleCalendar work schedule.
//    * BeginTime     - Date - work start time on the ScheduleDate day.
//    * EndTime  - Date - work end time on the ScheduleDate day.
//
Function WorkSchedulesForPeriod(Schedules, StartDate, EndDate, RollingShifts = False) Export
	
	TempTablesManager = New TempTablesManager;
	
	// Create a temporary schedule table.
	CreateTTWorkSchedulesForPeriod(TempTablesManager, Schedules, StartDate, EndDate, RollingShifts);
	
	QueryText = 
	"SELECT
	|	WorkSchedules1.WorkScheduleCalendar   AS WorkScheduleCalendar,
	|	WorkSchedules1.ScheduleDate    AS ScheduleDate,
	|	WorkSchedules1.BeginTime    AS BeginTime,
	|	WorkSchedules1.EndTime AS EndTime
	|FROM
	|	TTWorkSchedules AS WorkSchedules1
	|
	|ORDER BY
	|	&OrderingCondition";
	
	If RollingShifts Then
		QueryText = StrReplace(QueryText, "&OrderingCondition", "WorkScheduleCalendar, ScheduleDate, LineNumber");
	Else
		QueryText = StrReplace(QueryText, "&OrderingCondition", "WorkScheduleCalendar, ScheduleDate, BeginTime");
	EndIf;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	Return Query.Execute().Unload();
	
EndFunction

// Creates temporary table TTWorkSchedules in the manager. The table contains columns matching the return
// value of the WorkSchedulesForPeriod function.
//
// Parameters:
//  TempTablesManager - TempTablesManager - manager, in which the temporary table is created.
//  Schedules       - Array of CatalogRef.Calendars - an array of items of the CatalogRef.Calendars type, for which schedules are created.
//  StartDate    - Date   - a start date of the period, for which schedules are to be created.
//  EndDate - Date   - a period end date.
//  RollingShifts - Boolean - if True, then the schedule intervals may cross the border of the day.
//    For example, the interval "03 Apr. 20:00-04:00" can be returned if the schedule is configured accordingly.
//    If the parameter value is False, then a similar schedule will be represented by two intervals:
//    "03 Apr. 20:00-00:00" and "04 Apr. 00:00-04:00".
//
Procedure CreateTTWorkSchedulesForPeriod(TempTablesManager, Schedules, StartDate, EndDate, RollingShifts = False) Export
	
	QueryText = 
	"SELECT
	|	FillingTemplate.Ref AS WorkScheduleCalendar,
	|	MAX(FillingTemplate.LineNumber) AS PeriodLength
	|INTO TTSchedulePeriodLength
	|FROM
	|	Catalog.Calendars.FillingTemplate AS FillingTemplate
	|WHERE
	|	FillingTemplate.Ref IN(&Calendars)
	|
	|GROUP BY
	|	FillingTemplate.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calendars.Ref AS WorkScheduleCalendar,
	|	BusinessCalendarData.Date AS ScheduleDate,
	|	CASE
	|		WHEN BusinessCalendarData.DayKind = VALUE(Enum.BusinessCalendarDaysKinds.Preholiday)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS PreholidayDay
	|INTO TTPreHolidayDays
	|FROM
	|	InformationRegister.BusinessCalendarData AS BusinessCalendarData
	|		INNER JOIN Catalog.Calendars AS Calendars
	|		ON BusinessCalendarData.BusinessCalendar = Calendars.BusinessCalendar
	|			AND (Calendars.Ref IN (&Calendars))
	|			AND (BusinessCalendarData.Date BETWEEN &StartDatePreceding AND &EndDate)
	|			AND (BusinessCalendarData.DayKind = VALUE(Enum.BusinessCalendarDaysKinds.Preholiday))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calendars.Ref AS WorkScheduleCalendar,
	|	BusinessCalendarData.Date AS ScheduleDate,
	|	BusinessCalendarData.ReplacementDate
	|INTO TTShiftDates
	|FROM
	|	InformationRegister.BusinessCalendarData AS BusinessCalendarData
	|		INNER JOIN Catalog.Calendars AS Calendars
	|		ON BusinessCalendarData.BusinessCalendar = Calendars.BusinessCalendar
	|			AND (Calendars.Ref IN (&Calendars))
	|			AND (BusinessCalendarData.Date BETWEEN &StartDatePreceding AND &EndDate)
	|			AND (BusinessCalendarData.ReplacementDate <> DATETIME(1, 1, 1))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalendarSchedules.Calendar AS WorkScheduleCalendar,
	|	CalendarSchedules.ScheduleDate AS ScheduleDate,
	|	DATEDIFF(Calendars.StartingDate, CalendarSchedules.ScheduleDate, DAY) + 1 AS DaysFromStartDate,
	|	PreholidayDays.PreholidayDay,
	|	ShiftDates.ReplacementDate
	|INTO TTDaysIncludedInSchedule
	|FROM
	|	InformationRegister.CalendarSchedules AS CalendarSchedules
	|		INNER JOIN Catalog.Calendars AS Calendars
	|		ON CalendarSchedules.Calendar = Calendars.Ref
	|			AND (CalendarSchedules.Calendar IN (&Calendars))
	|			AND (CalendarSchedules.ScheduleDate BETWEEN &StartDatePreceding AND &EndDate)
	|			AND (CalendarSchedules.DayAddedToSchedule)
	|		LEFT JOIN TTPreHolidayDays AS PreholidayDays
	|		ON (PreholidayDays.WorkScheduleCalendar = CalendarSchedules.Calendar)
	|			AND (PreholidayDays.ScheduleDate = CalendarSchedules.ScheduleDate)
	|		LEFT JOIN TTShiftDates AS ShiftDates
	|		ON (ShiftDates.WorkScheduleCalendar = CalendarSchedules.Calendar)
	|			AND (ShiftDates.ScheduleDate = CalendarSchedules.ScheduleDate)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DaysIncludedInSchedule.WorkScheduleCalendar,
	|	DaysIncludedInSchedule.ScheduleDate,
	|	CASE
	|		WHEN DaysIncludedInSchedule.ModuloOperationResult = 0
	|			THEN DaysIncludedInSchedule.PeriodLength
	|		ELSE DaysIncludedInSchedule.ModuloOperationResult
	|	END AS DayNumber,
	|	DaysIncludedInSchedule.PreholidayDay
	|INTO TTDatesDayNumbers
	|FROM
	|	(SELECT
	|		DaysIncludedInSchedule.WorkScheduleCalendar AS WorkScheduleCalendar,
	|		DaysIncludedInSchedule.ScheduleDate AS ScheduleDate,
	|		DaysIncludedInSchedule.PreholidayDay AS PreholidayDay,
	|		DaysIncludedInSchedule.PeriodLength AS PeriodLength,
	|		DaysIncludedInSchedule.DaysFromStartDate - DaysIncludedInSchedule.DivisionOutputIntegerPart * DaysIncludedInSchedule.PeriodLength AS ModuloOperationResult
	|	FROM
	|		(SELECT
	|			DaysIncludedInSchedule.WorkScheduleCalendar AS WorkScheduleCalendar,
	|			DaysIncludedInSchedule.ScheduleDate AS ScheduleDate,
	|			DaysIncludedInSchedule.PreholidayDay AS PreholidayDay,
	|			DaysIncludedInSchedule.DaysFromStartDate AS DaysFromStartDate,
	|			PeriodsLength.PeriodLength AS PeriodLength,
	|			(CAST(DaysIncludedInSchedule.DaysFromStartDate / PeriodsLength.PeriodLength AS NUMBER(15, 0))) - CASE
	|				WHEN (CAST(DaysIncludedInSchedule.DaysFromStartDate / PeriodsLength.PeriodLength AS NUMBER(15, 0))) > DaysIncludedInSchedule.DaysFromStartDate / PeriodsLength.PeriodLength
	|					THEN 1
	|				ELSE 0
	|			END AS DivisionOutputIntegerPart
	|		FROM
	|			TTDaysIncludedInSchedule AS DaysIncludedInSchedule
	|				INNER JOIN Catalog.Calendars AS Calendars
	|				ON DaysIncludedInSchedule.WorkScheduleCalendar = Calendars.Ref
	|					AND (Calendars.FillingMethod = VALUE(Enum.WorkScheduleFillingMethods.ByArbitraryLengthPeriods))
	|				INNER JOIN TTSchedulePeriodLength AS PeriodsLength
	|				ON DaysIncludedInSchedule.WorkScheduleCalendar = PeriodsLength.WorkScheduleCalendar) AS DaysIncludedInSchedule) AS DaysIncludedInSchedule
	|
	|UNION ALL
	|
	|SELECT
	|	DaysIncludedInSchedule.WorkScheduleCalendar,
	|	DaysIncludedInSchedule.ScheduleDate,
	|	CASE
	|		WHEN DaysIncludedInSchedule.ReplacementDate IS NULL 
	|			THEN WEEKDAY(DaysIncludedInSchedule.ScheduleDate)
	|		ELSE WEEKDAY(DaysIncludedInSchedule.ReplacementDate)
	|	END,
	|	DaysIncludedInSchedule.PreholidayDay
	|FROM
	|	TTDaysIncludedInSchedule AS DaysIncludedInSchedule
	|		INNER JOIN Catalog.Calendars AS Calendars
	|		ON DaysIncludedInSchedule.WorkScheduleCalendar = Calendars.Ref
	|WHERE
	|	Calendars.FillingMethod = VALUE(Enum.WorkScheduleFillingMethods.ByWeeks)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WorkSchedule.Ref      AS Ref,
	|	WorkSchedule.DayNumber    AS DayNumber,
	|	WorkSchedule.LineNumber AS LineNumber,
	|	WorkSchedule.BeginTime AS BeginTime,
	|	CASE
	|		WHEN WorkSchedule.EndTime > WorkSchedule.BeginTime
	|			THEN WorkSchedule.EndTime
	|		ELSE BEGINOFPERIOD(WorkSchedule.BeginTime, DAY)
	|	END                        AS EndTime,
	|	FALSE                         AS RollingPart
	|INTO TTOpeningHours
	|FROM
	|	Catalog.Calendars.WorkSchedule AS WorkSchedule
	|WHERE
	|	NOT &RollingShifts
	|	AND WorkSchedule.Ref IN(&Calendars)
	|	AND (WorkSchedule.EndTime < WorkSchedule.BeginTime
	|			AND WorkSchedule.EndTime <> BEGINOFPERIOD(WorkSchedule.BeginTime, DAY)
	|		OR NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Catalog.Calendars.WorkSchedule AS T
	|			WHERE
	|				T.Ref = WorkSchedule.Ref
	|				AND T.DayNumber = WorkSchedule.DayNumber
	|				AND T.LineNumber < WorkSchedule.LineNumber
	|				AND (T.BeginTime >= WorkSchedule.BeginTime
	|					OR T.EndTime > WorkSchedule.BeginTime
	|					OR T.EndTime <= T.BeginTime)))
	|
	|UNION ALL
	|
	|SELECT
	|	WorkSchedule.Ref         AS Ref,
	|	WorkSchedule.DayNumber       AS DayNumber,
	|	WorkSchedule.LineNumber    AS LineNumber,
	|	CASE
	|		WHEN WorkSchedule.EndTime > WorkSchedule.BeginTime
	|				OR WorkSchedule.EndTime = BEGINOFPERIOD(WorkSchedule.BeginTime, DAY)
	|			THEN WorkSchedule.BeginTime
	|		ELSE BEGINOFPERIOD(WorkSchedule.BeginTime, DAY)
	|	END                           AS BeginTime,
	|	WorkSchedule.EndTime AS EndTime,
	|	TRUE                          AS RollingPart
	|FROM
	|	Catalog.Calendars.WorkSchedule AS WorkSchedule
	|WHERE
	|	NOT &RollingShifts
	|	AND WorkSchedule.Ref IN(&Calendars)
	|	AND (WorkSchedule.EndTime <= WorkSchedule.BeginTime
	|			AND WorkSchedule.EndTime <> BEGINOFPERIOD(WorkSchedule.BeginTime, DAY)
	|		OR TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Catalog.Calendars.WorkSchedule AS T
	|			WHERE
	|				T.Ref = WorkSchedule.Ref
	|				AND T.DayNumber = WorkSchedule.DayNumber
	|				AND T.LineNumber < WorkSchedule.LineNumber
	|				AND (T.BeginTime >= WorkSchedule.BeginTime
	|					OR T.EndTime > WorkSchedule.BeginTime
	|					OR T.EndTime <= T.BeginTime)))
	|
	|UNION ALL
	|
	|SELECT
	|	WorkSchedule.Ref         AS Ref,
	|	WorkSchedule.DayNumber       AS DayNumber,
	|	WorkSchedule.LineNumber    AS LineNumber,
	|	WorkSchedule.BeginTime    AS BeginTime,
	|	WorkSchedule.EndTime AS EndTime,
	|	FALSE                            AS RollingPart
	|FROM
	|	Catalog.Calendars.WorkSchedule AS WorkSchedule
	|WHERE
	|	&RollingShifts
	|	AND WorkSchedule.Ref IN(&Calendars)
	|
	|INDEX BY
	|	Ref,
	|	DayNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DaysIncludedInSchedule.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	DaysIncludedInSchedule.ScheduleDate  AS Period,
	|	CASE
	|		WHEN ISNULL(PreholidayWorkSchedules.RollingPart, ISNULL(WorkSchedules1.RollingPart, FALSE)) = FALSE
	|			THEN DaysIncludedInSchedule.ScheduleDate
	|		ELSE DATEADD(DaysIncludedInSchedule.ScheduleDate, DAY, 1)
	|	END                             AS ScheduleDate,
	|	DaysIncludedInSchedule.DayNumber     AS DayNumber,
	|	ISNULL(PreholidayWorkSchedules.LineNumber, WorkSchedules1.LineNumber) AS LineNumber,
	|	ISNULL(PreholidayWorkSchedules.BeginTime, WorkSchedules1.BeginTime) AS BeginTime,
	|	ISNULL(PreholidayWorkSchedules.EndTime, WorkSchedules1.EndTime) AS EndTime
	|INTO TTWorkSchedules
	|FROM
	|	TTDatesDayNumbers AS DaysIncludedInSchedule
	|		LEFT JOIN TTOpeningHours AS WorkSchedules1
	|		ON (WorkSchedules1.Ref = DaysIncludedInSchedule.WorkScheduleCalendar)
	|			AND (WorkSchedules1.DayNumber = DaysIncludedInSchedule.DayNumber)
	|		LEFT JOIN TTOpeningHours AS PreholidayWorkSchedules
	|		ON (PreholidayWorkSchedules.Ref = DaysIncludedInSchedule.WorkScheduleCalendar)
	|			AND (PreholidayWorkSchedules.DayNumber = 0)
	|			AND (DaysIncludedInSchedule.PreholidayDay)
	|WHERE
	|	CASE
	|		WHEN ISNULL(PreholidayWorkSchedules.RollingPart, ISNULL(WorkSchedules1.RollingPart, FALSE)) = FALSE
	|			THEN DaysIncludedInSchedule.ScheduleDate
	|		ELSE DATEADD(DaysIncludedInSchedule.ScheduleDate, DAY, 1)
	|	END >= &StartDate
	|
	|INDEX BY
	|	WorkScheduleCalendar";
	
	// The formula for calculating the number in an arbitrary-length cycle for a schedule day:
	// NumberOfDay = DayCountFromStartDay % CycleLength
	
	// The modulo formula:
	// Dividend – Int(Dividend / Divisor) * Divisor
	
	// To get the integral part, the following behavior is used:
	// If the rule is "a fractional part of 0.5 is rounded up", and the result exceeds the original number, reduce it by 1.
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	If RollingShifts Then
		QueryText = StrReplace(QueryText, "&StartDatePreceding", "&StartDate");
	Else
		Query.SetParameter("StartDatePreceding", BegOfDay(StartDate - 86400));
	EndIf;
	
	Query.Text = QueryText;
	
	Query.SetParameter("Calendars", Schedules);
	Query.SetParameter("StartDate", StartDate);
	Query.SetParameter("EndDate", EndDate);
	Query.SetParameter("RollingShifts", RollingShifts);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#Region Internal

// Uses business calendar data to update 
// work schedules.
//
// Parameters:
//  - UpdateConditions - ValueTable:
//    - BusinessCalendarCode - Code of the modified business calendar.
//    - Year - Year whose data must be updated.
//
Procedure UpdateWorkSchedulesAccordingToBusinessCalendars(UpdateConditions) Export
	
	InformationRegisters.CalendarSchedules.UpdateWorkSchedulesAccordingToBusinessCalendars(UpdateConditions);
	
EndProcedure

// Adds work schedule catalog to the list of locked items 
// to make schedules unavailable for changing by user while updating business calendars.
//
// Parameters:
//  ObjectsToLock - Array of String - metadata names of objects to be blocked.
//
Procedure FillObjectsToBlockDependentOnBusinessCalendars(ObjectsToLock) Export
	
	ObjectsToLock.Add("Catalog.Calendars");
	
EndProcedure

// Adds the register of calendar schedules to the list of objects to be changed.
//
// Parameters:
//  ObjectsToChange - Array of String - metadata names of objects to be changed.
//
Procedure FillObjectsToChangeDependentOnBusinessCalendars(ObjectsToChange) Export
	
	ObjectsToChange.Add("InformationRegister.CalendarSchedules");
	
EndProcedure

// Defines the number of days included in the schedule for the specified period.
//
// Parameters:
//   WorkScheduleCalendar	- CatalogRef.Calendars - Schedule to be used for day calculation.
//   StartDate		- Date - a period start date.
//   EndDate	- Date - a period end date.
//   RaiseException1 - Boolean - if True, throw an exception if the schedule is not filled in.
//
// Returns:
//   Number		- Days between the start date and end date.
//	              If schedule WorkSchedule is not specified and RaiseException = False, returns Undefined.
//
Function DateDiffByCalendar(Val WorkScheduleCalendar, Val StartDate, Val EndDate, RaiseException1 = True) Export
	
	If Not ValueIsFilled(WorkScheduleCalendar) Then
		If RaiseException1 Then
			Raise NStr("vi = 'Chưa chỉ ra lịch làm việc.';
						|ru = 'Не указан график работы.';
						|en = 'Work schedule is not specified.'; fa = 'Work schedule is not specified.';
						|it = 'Orario di lavoro non indicato.';
						|pl = 'Nie podano harmonogramu pracy.';
						|tr = 'Çalışma takvimi belirtilmedi.'");
		EndIf;
		Return Undefined;
	EndIf;
	
	StartDate = BegOfDay(StartDate);
	EndDate = BegOfDay(EndDate);
	
	ScheduleDates = New Array;
	ScheduleDates.Add(StartDate);
	If Year(StartDate) <> Year(EndDate) Then
		// If the dates are from different years, add the year borders.
		For YearNumber = Year(StartDate) To Year(EndDate) - 1 Do
			ScheduleDates.Add(Date(YearNumber, 12, 31));
		EndDo;
	EndIf;
	ScheduleDates.Add(EndDate);
	
	// Generate a query text of the temporary table containing the specified dates.
	QueryText = "";
	For Each ScheduleDate In ScheduleDates Do
		If IsBlankString(QueryText) Then
			UnionTemplate = 
			"SELECT
			|	DATETIME(2020,01,01) AS ScheduleDate
			|INTO TTScheduleDates
			|";
		Else
			UnionTemplate = 
			"UNION ALL
			|
			|SELECT
			|	DATETIME(2020,01,01)";
		EndIf;
		QueryText = QueryText + StrReplace(
			UnionTemplate, "2020,01,01", Format(ScheduleDate, "DF='yyyy,MM,d'")); // ACC:1367 Format data for technical purposes. Hidden from users.
	EndDo;
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
	// Prepare temporary tables with initial data.
	Query.SetParameter("WorkScheduleCalendar", WorkScheduleCalendar);
	Query.Text =
	"SELECT DISTINCT
	|	ScheduleDates.ScheduleDate AS ScheduleDate
	|INTO TTDifferentScheduleDates
	|FROM
	|	TTScheduleDates AS ScheduleDates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	YEAR(ScheduleDates.ScheduleDate) AS Year
	|INTO TTDifferentScheduleYears
	|FROM
	|	TTScheduleDates AS ScheduleDates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalendarSchedules.Year AS Year,
	|	CalendarSchedules.ScheduleDate AS ScheduleDate,
	|	CalendarSchedules.DayAddedToSchedule AS DayAddedToSchedule
	|INTO TTCalendarSchedules
	|FROM
	|	InformationRegister.CalendarSchedules AS CalendarSchedules
	|		INNER JOIN TTDifferentScheduleYears AS ScheduleYears
	|		ON (ScheduleYears.Year = CalendarSchedules.Year)
	|WHERE
	|	CalendarSchedules.Calendar = &WorkScheduleCalendar
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleDates.ScheduleDate AS ScheduleDate,
	|	COUNT(DaysIncludedInSchedule.ScheduleDate) AS DaysCountInScheduleSinceBegOfYear
	|INTO TTNumberOfDaysInSchedule
	|FROM
	|	TTDifferentScheduleDates AS ScheduleDates
	|		LEFT JOIN TTCalendarSchedules AS DaysIncludedInSchedule
	|		ON (DaysIncludedInSchedule.Year = YEAR(ScheduleDates.ScheduleDate))
	|			AND (DaysIncludedInSchedule.ScheduleDate <= ScheduleDates.ScheduleDate)
	|			AND (DaysIncludedInSchedule.DayAddedToSchedule)
	|
	|GROUP BY
	|	ScheduleDates.ScheduleDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleDates.ScheduleDate AS ScheduleDate,
	|	ISNULL(ScheduleData.DayAddedToSchedule, FALSE) AS DayAddedToSchedule,
	|	DaysIncludedInSchedule.DaysCountInScheduleSinceBegOfYear AS DaysCountInScheduleSinceBegOfYear
	|FROM
	|	TTScheduleDates AS ScheduleDates
	|		LEFT JOIN TTCalendarSchedules AS ScheduleData
	|		ON (ScheduleData.Year = YEAR(ScheduleDates.ScheduleDate))
	|			AND (ScheduleData.ScheduleDate = ScheduleDates.ScheduleDate)
	|		LEFT JOIN TTNumberOfDaysInSchedule AS DaysIncludedInSchedule
	|		ON (DaysIncludedInSchedule.ScheduleDate = ScheduleDates.ScheduleDate)
	|
	|ORDER BY
	|	ScheduleDates.ScheduleDate";
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		If RaiseException1 Then
			ErrorMessage = NStr("vi = 'Chưa điền lịch làm việc ""%1"" trong kỳ %2.';
								|ru = 'График работы ""%1"" не заполнен на период %2.';
								|en = 'The ""%1"" work schedule is blank for period: %2.'; fa = 'The ""%1"" work schedule is blank for period: %2.';
								|it = 'Grafico di lavoro ""%1"" non compilato per il periodo %2.';
								|pl = 'Harmonogram pracy ""%1"" nie jest wypełniony na okres %2.';
								|tr = '""%1"" çalışma takvimi %2 dönemi için doldurulmadı.'");
			Raise StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, WorkScheduleCalendar, PeriodPresentation(StartDate, EndOfDay(EndDate)));
		Else
			Return Undefined;
		EndIf;
	EndIf;
	
	Selection = Result.Select();
	
	// Get a selection where each original date has the number of days in the schedule from the year start. 
	// From the first date's value, subtract all other values to get the negative number of all days in the schedule.
	// If the first day is a weekday and the next one is a day off, the number of matching days is equal, 
	// and you need to adjust the result by adding 1 day to it.
	//  
	//  
	// 
	
	DaysCountInSchedule = Undefined;
	AddFirstDay = False;
	
	While Selection.Next() Do
		If DaysCountInSchedule = Undefined Then
			DaysCountInSchedule = Selection.DaysCountInScheduleSinceBegOfYear;
			AddFirstDay = Selection.DayAddedToSchedule;
		Else
			DaysCountInSchedule = DaysCountInSchedule - Selection.DaysCountInScheduleSinceBegOfYear;
		EndIf;
	EndDo;
	
	Return - DaysCountInSchedule + ?(AddFirstDay, 1, 0);
	
EndFunction

Function WorkSchedulesUpdateProcedureName() Export
	
	Return "InformationRegisters.CalendarSchedules.ProcessDataForMigrationToNewVersion";
	
EndFunction

Function ConsiderNonWorkDaysFlagSettingProcedureName() Export
	
	Return "Catalogs.Calendars.ProcessDataForMigrationToNewVersion";
	
EndFunction

#Region ConfigurationSubsystemsEventHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If Metadata.DataProcessors.Find("FillWorkSchedules") <> Undefined Then
		ModuleFillingInWorkSchedules = Common.CommonModule("DataProcessors.FillWorkSchedules");
		ModuleFillingInWorkSchedules.OnAddUpdateHandlers(Handlers);
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.2.78";
	Handler.Procedure = "InformationRegisters.CalendarSchedules.ProcessDataForMigrationToNewVersion";
	Handler.UpdateDataFillingProcedure = "InformationRegisters.CalendarSchedules.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.ObjectsToRead = "InformationRegister.CalendarSchedules, InformationRegister.ManualWorkScheduleChanges, InformationRegister.BusinessCalendarData";
	Handler.ObjectsToChange = "InformationRegister.CalendarSchedules";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Id = New UUID("39e6fbf8-c02d-4459-bdbd-58adf6c6127c");
	Handler.Comment = NStr("vi = 'Sửa chữa việc đưa vào lịch trình của ngày làm việc và ngày lễ rơi vào Thứ Bảy hoặc Chủ Nhật.';
							|ru = 'Исправление включения в график рабочих и предпраздничных дней, выпадающих на субботу или воскресенье.';
							|en = 'Corrects the inclusion of working days and days before the holidays falling on Saturdays or Sundays in the schedule.'; fa = 'Corrects the inclusion of working days and days before the holidays falling on Saturdays or Sundays in the schedule.';
							|it = 'Correzione dell''inclusione nel programma dei giorni lavorativi e festivi che cadono il sabato o la domenica.';
							|pl = 'Poprawka włączenia do harmonogramu roboczych i przedświątecznych dni, przypadających na sobotę lub niedzielę.';
							|tr = 'Cumartesi veya Pazar günlerine denk gelen çalışma ve tatil öncesi günlerini programa dahil etme düzeltmesi.'");
	Handler.ObjectsToLock = "Catalog.Calendars";
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	If CalendarSchedules.ThereAreChangeableObjectsDependentOnProductionCalendars() Then
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = "CalendarSchedules.UpdateDataDependentOnBusinessCalendars";
		Priority.Order = "After";
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.3.94";
	Handler.Procedure = "Catalogs.Calendars.ProcessDataForMigrationToNewVersion";
	Handler.UpdateDataFillingProcedure = "Catalogs.Calendars.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.ObjectsToRead = "Catalog.Calendars";
	Handler.ObjectsToChange = "Catalog.Calendars";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Id = New UUID("fe8c3f3a-8973-4538-a993-ba74fa9162d8");
	Handler.Comment = NStr("vi = 'Thiết lập dấu hiệu mới ""Ghi nhận kỳ không làm việc"" trong vị trí mặc định.';
							|ru = 'Установка нового признака ""Учитывать нерабочие периоды"" в положение по умолчанию.';
							|en = 'Set the new ""Skip non-work periods"" flag to the default value.'; fa = 'Set the new ""Skip non-work periods"" flag to the default value.';
							|it = 'Impostazione del nuovo contrassegno ""Calcolare i periodi senza lavoro"" nella frase predefinita.';
							|pl = 'Ustawienie nowej oznaki ""Uwzględniaj okresy nierobocze"" do pozycji domyślnej.';
							|tr = '""İş dışı dönemleri dahil et"" yeni bayrağı varsayılan duruma ayarlanıyor.'");
	Handler.ObjectsToLock = "Catalog.Calendars";
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	If CalendarSchedules.ThereAreChangeableObjectsDependentOnProductionCalendars() Then
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = "CalendarSchedules.UpdateDataDependentOnBusinessCalendars";
		Priority.Order = "Before";
	EndIf;
	
EndProcedure

// See UsersOverridable.OnDefineRoleAssignment
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// BothForUsersAndExternalUsers.
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.ReadWorkSchedules.Name);
	
EndProcedure

// See DuplicateObjectsDetection.TypesToExcludeFromPossibleDuplicates
Procedure OnAddTypesToExcludeFromPossibleDuplicates(TypesToExclude) Export

	CommonClientServer.SupplementArray(
		TypesToExclude, Metadata.DefinedTypes.WorkScheduleOwner.Type.Types()); 

EndProcedure

#EndRegion

#EndRegion

#Region Private

Function TwelveHourTimeFormat() Export
	
	TimePresentation = Format(CurrentSessionDate(), "DLF=T");
	If Upper(Right(TimePresentation, 1)) = "M" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion