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
//   WorkScheduleCalendar	- CatalogRef.Calendars
//	             	- CatalogRef.BusinessCalendars - a schedule or 
//                    business calendar to be used to calculate dates.
//   DateFrom			- Date - a date starting from which the number of days is to be calculated.
//   DaysArray		- Array of Number - a number of days by which the start date is to be increased.
//   CalculateNextDateFromPrevious	- Boolean - shows whether the following date is to be calculated
//											           from the previous one or all dates are calculated from the passed date.
//   RaiseException1 - Boolean - if True, throw an exception if the schedule is not filled in.
//
// Returns:
//   Undefined, Array - an array of dates increased by the number of days included in the schedule.
//	                        If schedule WorkSchedule is not filled in and RaiseException = False, Undefined returns.
//
Function DatesByCalendar(Val WorkScheduleCalendar, Val DateFrom, Val DaysArray, Val CalculateNextDateFromPrevious = False, RaiseException1 = True) Export
	
	If Not ValueIsFilled(WorkScheduleCalendar) Then
		If RaiseException1 Then
			Raise NStr("vi = 'Chưa chỉ ra lịch biểu làm việc hoặc lịch sản xuất.';
						|ru = 'Не указан график работы или производственный календарь.';
						|en = 'Work schedule or business calendar is not specified.'; fa = 'Work schedule or business calendar is not specified.';
						|it = 'Non è specificato un programma di lavoro o un calendario di produzione.';
						|pl = 'Nie jest wskazany harmonogram pracy lub kalendarz biznesowy.';
						|tr = 'Çalışma takvimi veya iş takvimi belirtilmedi.'");
		EndIf;
		Return Undefined;
	EndIf;
	
	If TypeOf(WorkScheduleCalendar) <> Type("CatalogRef.BusinessCalendars") Then
		If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
			ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
			Return ModuleWorkSchedules.DatesBySchedule(
				WorkScheduleCalendar, DateFrom, DaysArray, CalculateNextDateFromPrevious, RaiseException1);
		EndIf;
	EndIf;
	
	ShiftDays = DaysIncrement(DaysArray, CalculateNextDateFromPrevious);
	
	KindsOfDaysIncludedInCalculation = New Array();
	KindsOfDaysIncludedInCalculation.Add(Enums.BusinessCalendarDaysKinds.Work); 
	KindsOfDaysIncludedInCalculation.Add(Enums.BusinessCalendarDaysKinds.Preholiday);
	
	Query = New Query();
	Query.SetParameter("BusinessCalendar", WorkScheduleCalendar);
	Query.SetParameter("DateFrom", BegOfDay(DateFrom));
	Query.SetParameter("Days", ShiftDays.DaysIncrement.UnloadColumn("DaysCount"));
	Query.SetParameter("DaysKinds", KindsOfDaysIncludedInCalculation);
	Query.Text =
		"SELECT TOP 0
		|	CalendarSchedules.Date AS Date
		|FROM
		|	InformationRegister.BusinessCalendarData AS CalendarSchedules
		|WHERE
		|	CalendarSchedules.Date > &DateFrom
		|	AND CalendarSchedules.BusinessCalendar = &BusinessCalendar
		|	AND CalendarSchedules.DayKind IN(&DaysKinds)
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
				NStr("vi = 'Lịch sản xuất ""%1"" chưa được điền từ ngày %2 với số ngày làm việc đã chỉ định.';
					|ru = 'Производственный календарь ""%1"" не заполнен с даты %2 на указанное количество рабочих дней.';
					|en = 'Business calendar ""%1"" is not filled in for the specified number of workdays after %2.'; fa = 'Business calendar ""%1"" is not filled in for the specified number of workdays after %2.';
					|it = 'Calendario di produzione ""%1"" non compilato dalla data %2 per il numero indicato di giorni di lavoro.';
					|pl = 'Kalendarz biznesowy ""%1"" nie jest wypełniony od daty %2 nie jest wskazana ilość dni roboczych.';
					|tr = '""%1"" İş takvimi belirtilen iş günü için %2 itibaren doldurulmamıştır.'"), 
				WorkScheduleCalendar, 
				Format(DateFrom, "DLF=D"));
		Else
			Return Undefined;
		EndIf;
	EndIf;
	
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
// included in the specified schedule or the WorkScheduleCalendar business calendar.
//
// Parameters:
//   WorkScheduleCalendar	- CatalogRef.Calendars
//	             	- CatalogRef.BusinessCalendars - a schedule or 
//                    business calendar to be used to calculate dates.
//   DateFrom			- Date - a date starting from which the number of days is to be calculated.
//   DaysCount	- Number - a number of days by which the start date is to be increased.
//   RaiseException1 - Boolean - if True, throw an exception if the schedule is not filled in.
//
// Returns:
//   Date, Undefined - a date increased by the number of days included in the schedule.
//	                      If the selected schedule is not filled in and RaiseException = False, Undefined returns.
//
Function DateByCalendar(Val WorkScheduleCalendar, Val DateFrom, Val DaysCount, RaiseException1 = True) Export
	
	If Not ValueIsFilled(WorkScheduleCalendar) Then
		If RaiseException1 Then
			Raise NStr("vi = 'Chưa chỉ ra lịch biểu làm việc hoặc lịch sản xuất.';
						|ru = 'Не указан график работы или производственный календарь.';
						|en = 'Work schedule or business calendar is not specified.'; fa = 'Work schedule or business calendar is not specified.';
						|it = 'Non è specificato un programma di lavoro o un calendario di produzione.';
						|pl = 'Nie jest wskazany harmonogram pracy lub kalendarz biznesowy.';
						|tr = 'Çalışma takvimi veya iş takvimi belirtilmedi.'");
		EndIf;
		Return Undefined;
	EndIf;
	
	DateFrom = BegOfDay(DateFrom);
	
	If DaysCount = 0 Then
		Return DateFrom;
	EndIf;
	
	DaysArray = New Array;
	DaysArray.Add(DaysCount);
	
	DatesArray = DatesByCalendar(WorkScheduleCalendar, DateFrom, DaysArray, , RaiseException1);
	
	Return ?(DatesArray <> Undefined, DatesArray[0], Undefined);
	
EndFunction

// Defines the number of days included in the schedule for the specified period.
//
// Parameters:
//   WorkScheduleCalendar	- CatalogRef.Calendars
//	             	- CatalogRef.BusinessCalendars - a schedule or 
//                    business calendar to be used to calculate days.
//   StartDate		- Date - a period start date.
//   EndDate	- Date - a period end date.
//   RaiseException1 - Boolean - if True, throw an exception if the schedule is not filled in.
//
// Returns:
//   Number		- a number of days between the start and end dates.
//	              If schedule WorkSchedule is not filled in and RaiseException = False, Undefined returns.
//
Function DateDiffByCalendar(Val WorkScheduleCalendar, Val StartDate, Val EndDate, RaiseException1 = True) Export

	If Not ValueIsFilled(WorkScheduleCalendar) Then
		If RaiseException1 Then
			Raise NStr("vi = 'Chưa chỉ ra lịch sản xuất.';
						|ru = 'Не указан производственный календарь.';
						|en = 'Business calendar is not specified.'; fa = 'Business calendar is not specified.';
						|it = 'Non è indicato il calendario di produzione.';
						|pl = 'Business calendar is not specified.';
						|tr = 'İş takvimi belirtilmedi.'");
		EndIf;
		Return Undefined;
	EndIf;

	If TypeOf(WorkScheduleCalendar) <> Type("CatalogRef.BusinessCalendars") Then
		Result = Undefined;
		If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
			ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
			Result = ModuleWorkSchedules.DateDiffByCalendar(WorkScheduleCalendar, StartDate, EndDate, RaiseException1);
		EndIf;
		Return Result;
	EndIf;

	If EndDate < StartDate Then
		Vrem = StartDate;
		StartDate = EndDate;
		EndDate = Vrem;
	EndIf;
	
	// Check if the calendar is populated for all the years. 
	// If there's a year with no days, calculation fails.
	Years = New Array();
	Year = Year(StartDate);
	While Year <= Year(EndDate) Do
		Years.Add(Year);
		Year = Year + 1;
	EndDo;
	
	Query = New Query();
	Query.SetParameter("Calendar", WorkScheduleCalendar);
	Query.SetParameter("Years", Years);
	Query.Text = 
		"SELECT DISTINCT
		|	CalendarData.Year AS Year
		|FROM
		|	InformationRegister.BusinessCalendarData AS CalendarData
		|WHERE
		|	CalendarData.BusinessCalendar = &Calendar
		|	AND CalendarData.Year IN(&Years)";
	If Query.Execute().Unload().Count() <> Years.Count() Then
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

	IncludedInSchedule = New Array();
	IncludedInSchedule.Add(Enums.BusinessCalendarDaysKinds.Work);
	IncludedInSchedule.Add(Enums.BusinessCalendarDaysKinds.Preholiday);
	
	Query = New Query();
	Query.SetParameter("Calendar", WorkScheduleCalendar);
	Query.SetParameter("Years", Years);
	Query.SetParameter("DaysKinds", IncludedInSchedule);
	Query.SetParameter("StartDate", StartDate);
	Query.SetParameter("EndDate", EndDate);
	Query.Text = 
		"SELECT
		|	COUNT(CalendarData.Date) AS OfDays
		|FROM
		|	InformationRegister.BusinessCalendarData AS CalendarData
		|WHERE
		|	CalendarData.BusinessCalendar = &Calendar
		|	AND CalendarData.Year IN(&Years)
		|	AND CalendarData.DayKind IN(&DaysKinds)
		|	AND CalendarData.Date BETWEEN &StartDate AND &EndDate";

	Return Query.Execute().Unload().UnloadColumn("OfDays")[0];

EndFunction

// A constructor of parameters for receiving the nearest workdays by a calendar.
//  See NearestWorkDates.
//
// Parameters:
//  BusinessCalendar	 - CatalogRef.BusinessCalendars	 -
//  	if specified, NonWorkPeriods will be filled in by default as an Array from the details
//  	received using the NonWorkDaysPeriods method.
// 
// Returns:
//  Structure:
//   * GetPrevious - Boolean - Method that gets the closest date:
//       If True, workdays preceding the ones passed in the InitialDates parameter are defined.
//       If False, the nearest workdays following the start dates are defined.
//       By default, False:
//   * ConsiderNonWorkPeriods - Boolean - defines a relation to the dates that fall on non-work periods of the calendar.
//       If True, the dates that fall on a non-work period will be considered non-work ones.
//       If False, non-work periods will be ignored.
//       The default value is True:
//   * NonWorkPeriods - Undefined - specifies non-work periods to be considered.
//       You can set the Array of period numbers or details obtained by the NonWorkDaysPeriods method.
//       If Undefined, all the periods will be considered.
//       If the BusinessCalendar parameter is filled in, all the periods of this calendar will be filled in NonWorkPeriods.
//       The default value is Undefined:
//   * RaiseException1 - Boolean - raising an exception if the schedule is not filled in
//       If True, raise an exception if the schedule is not filled in.
//       If False, dates whose nearest date is not identified will be ignored.
//       The default value is True.
//   * ShouldGetDatesIfCalendarNotFilled - Boolean - If set to "True", and no custom calendar is filled, it gets the dates from 
//       the default business calendar.
//
Function NearestWorkDatesReceivingParameters(BusinessCalendar = Undefined) Export
	
	Parameters = New Structure;
	Parameters.Insert("GetPrevious", False);
	Parameters.Insert("ConsiderNonWorkPeriods", True);
	Parameters.Insert("NonWorkPeriods", Undefined);
	Parameters.Insert("RaiseException1", True);
	Parameters.Insert("ShouldGetDatesIfCalendarNotFilled", False);
	
	If BusinessCalendar <> Undefined Then
		Parameters.NonWorkPeriods = NonWorkDaysPeriods(BusinessCalendar, New StandardPeriod());
	EndIf;
	
	Return Parameters;
	
EndFunction

// Defines a date of the nearest workday for each date.
//
// Parameters:
//  BusinessCalendar	 - CatalogRef.BusinessCalendars	 - a calendar used for calculation.
//  InitialDates				 - Array of Date - the dates to which the nearest ones will be searched.
//  ReceivingParameters			 - See NearestWorkDatesReceivingParameters.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - Date - a start date,
//   * Value - Date - the working date closest to it (if a working date is passed, it returns).
//
Function NearestWorkDates(BusinessCalendar, InitialDates, ReceivingParameters = Undefined) Export
	
	If ReceivingParameters = Undefined Then
		ReceivingParameters = NearestWorkDatesReceivingParameters();
	EndIf;
	
	CommonClientServer.CheckParameter(
		"CalendarSchedules.NearestWorkDates", 
		"BusinessCalendar", 
		BusinessCalendar, 
		Type("CatalogRef.BusinessCalendars"));

	CommonClientServer.Validate(
		ValueIsFilled(BusinessCalendar), 
		NStr("vi = 'Chưa chỉ ra lịch biểu hoặc lịch sản xuất.';
			|ru = 'Не указан график или производственный календарь.';
			|en = 'The schedule or business calendar is not specified.'; fa = 'The schedule or business calendar is not specified.';
			|it = 'Non è specificato l''orario di lavoro o il calendario di produzione.';
			|pl = 'Nie jest wskazany harmonogram lub kalendarz biznesowy.';
			|tr = 'Çalışma programı veya iş takvimi belirtilmedi.'"), 
		"CalendarSchedules.NearestWorkDates");
	
	WorkdaysDates = New Map;
	
	Selection = SelectionOfNearestBusinessDates(BusinessCalendar, InitialDates, ReceivingParameters);
	If Not ValueIsFilled(Selection) Then
		Return WorkdaysDates;
	EndIf;
	
	DefaultCalendarData = Catalogs.BusinessCalendars.NewBusinessCalendarsData();
	
	While Selection.Next() Do
		
		If ValueIsFilled(Selection.NearestDate) Then
			NearestDate = Selection.NearestDate;
		ElsIf ReceivingParameters.ShouldGetDatesIfCalendarNotFilled Then
			NearestDate = NearestBusinessDateFromDefaultCalendar(Selection.Date, DefaultCalendarData,
				ReceivingParameters.GetPrevious);
		Else
			NearestDate = Undefined;
		EndIf;
		
		If ValueIsFilled(NearestDate) Then
			WorkdaysDates.Insert(Selection.Date, NearestDate);
		ElsIf ReceivingParameters.RaiseException1 Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xác định ngày làm việc gần nhất cho ngày %1,
					 |lịch sản xuất có thể không được điền.';
					 |ru = 'Невозможно определить ближайшую рабочую дату для даты %1, 
					 |возможно, производственный календарь не заполнен.';
					 |en = 'Cannot determine the workday nearest to %1. 
					 |The work schedule might be blank.'; fa = 'Cannot determine the workday nearest to %1. 
					 |The work schedule might be blank.';
					 |it = 'Impossibile stabilire la data di lavoro più vicina per data %1, 
					 | l''orario di lavoro potrebbe non essere compilato.';
					 |pl = 'Niemożliwe jest określenie najbliższego dnia roboczego dla dnia %1, 
					 |możliwie, że harmonogram pracy nie jest wypełniony.';
					 |tr = '%1 tarihi için en yakın iş günü belirlenemiyor.
					 |Çalışma programı doldurulmamış olabilir.'"), 
				Format(Selection.Date, "DLF=D"));
		EndIf;
		
	EndDo;
	
	Return WorkdaysDates;
	
EndFunction

// Generates work schedules for dates included in the specified schedules for the specified period.
// If the schedule for a pre-holiday day is not set, it is defined as if this day is a workday.
// Note that this function requires the WorkSchedules subsystem.
//
// Parameters:
//  Schedules       - Array of CatalogRef.Calendars - an array of items of the CatalogRef.Calendars type, for which schedules are created.
//  StartDate    - Date   - a start date of the period, for which schedules are to be created.
//  EndDate - Date   - a period end date.
//  RollingShifts - Boolean - if True, then the schedule intervals may cross the border of the day.
//
// Returns:
//   ValueTable:
//    * WorkScheduleCalendar    - CatalogRef.Calendars - a work schedule.
//    * ScheduleDate     - Date - a date in the WorkScheduleCalendar work schedule.
//    * BeginTime     - Date - work start time on the ScheduleDate day.
//    * EndTime  - Date - work end time on the ScheduleDate day.
//
Function WorkSchedulesForPeriod(Schedules, StartDate, EndDate, RollingShifts = False) Export
	
	If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
		Return ModuleWorkSchedules.WorkSchedulesForPeriod(Schedules, StartDate, EndDate, RollingShifts);
	EndIf;
	
	Raise NStr("vi = 'Không tìm thấy phân hệ ""Lịch làm việc"".';
				|ru = 'Подсистема ""Графики работы"" не обнаружена.';
				|en = 'The ""Work schedules"" subsystem is not found.'; fa = 'The ""Work schedules"" subsystem is not found.';
				|it = 'Sottosistema ""Grafici di lavoro"" non rilevato.';
				|pl = 'Podsystem ""Harmonogramy pracy"" nie został znaleziony';
				|tr = '""Çalışma takvimleri"" alt sistemi bulunamadı.'");
	
EndFunction

// Creates temporary table TTWorkSchedules in the manager. The table contains columns matching the return
// value of the WorkSchedulesForPeriod function.
// Note that this function requires the WorkSchedules subsystem.
//
// Parameters:
//  TempTablesManager - TempTablesManager - manager, in which the temporary table is created.
//  Schedules       - Array of CatalogRef.Calendars - an array of items of the CatalogRef.Calendars type, for which schedules are created.
//  StartDate    - Date   - a start date of the period, for which schedules are to be created.
//  EndDate - Date   - a period end date.
//  RollingShifts - Boolean - if True, then the schedule intervals may cross the border of the day.
//
Procedure CreateTTWorkSchedulesForPeriod(TempTablesManager, Schedules, StartDate, EndDate, RollingShifts = False) Export
	
	If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
		ModuleWorkSchedules.CreateTTWorkSchedulesForPeriod(TempTablesManager, Schedules, StartDate, EndDate, RollingShifts);
		Return;
	EndIf;
	
	Raise NStr("vi = 'Không tìm thấy phân hệ ""Lịch làm việc"".';
				|ru = 'Подсистема ""Графики работы"" не обнаружена.';
				|en = 'The ""Work schedules"" subsystem is not found.'; fa = 'The ""Work schedules"" subsystem is not found.';
				|it = 'Sottosistema ""Grafici di lavoro"" non rilevato.';
				|pl = 'Podsystem ""Harmonogramy pracy"" nie został znaleziony';
				|tr = '""Çalışma takvimleri"" alt sistemi bulunamadı.'");
	
EndProcedure

// Fills in an attribute in the form if only one business calendar is used.
//
// Parameters:
//  Form         - ClientApplicationForm - a form, in which the attribute is to be filled in.
//  AttributePath2 - String           - a path to the data, for example: "Object.BusinessCalendar".
//  CRTR			  - String           - a taxpayer ID (tax registration reason code) used to determine a state.
//
Procedure FillBusinessCalendarInForm(Form, AttributePath2, CRTR = Undefined) Export
	
	Calendar = Undefined;
	
	If Not GetFunctionalOption("UseMultipleBusinessCalendars") Then
		Calendar = SingleBusinessCalendar();
	Else
		Calendar = StateBusinessCalendar(CRTR);
	EndIf;
	
	If Calendar <> Undefined Then
		CommonClientServer.SetFormAttributeByPath(Form, AttributePath2, Calendar);
	EndIf;
	
EndProcedure

// Returns a main business calendar used in accounting.
//
// Returns:
//   CatalogRef.BusinessCalendars, Undefined - a main business calendar or 
//                                                              Undefined if it is not found.
//
Function MainBusinessCalendar() Export
		
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return Undefined;
	EndIf;	
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	Return ModuleFillingInCalendarSchedules.MainBusinessCalendar();
	
EndFunction

// Prepares details of special non-work periods, for example, set according to certain laws.
// These periods can be considered by schedules and override filling by business calendar data.
// 
// Parameters:
//   BusinessCalendar - CatalogRef.BusinessCalendars - the calendar that is a source.
//   PeriodFilter - StandardPeriod - a time interval within which you need to define non-work periods.
// Returns:
//   Array - Array of Structure with the following fields:
//    * Number     - Number - a sequence number of a period, which can be used for identification.
//    * Period    - StandardPeriod - a non-work period.
//    * Basis - String - a regulation a non-work period is based on.
//    * Dates - Array of Date - dates included in a non-work period.
//    * Presentation  - String - a user presentation of the period.
//
Function NonWorkDaysPeriods(BusinessCalendar, PeriodFilter) Export

	TimeIntervals = New Array;
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return TimeIntervals;
	EndIf;
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	TimeIntervals = ModuleFillingInCalendarSchedules.NonWorkDaysPeriods(BusinessCalendar, PeriodFilter);
	
	DeletePeriodsThatDoNotMatchFilter(TimeIntervals, PeriodFilter);
	
	Return TimeIntervals;

EndFunction

#Region InterfaceImplementation


#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. Outdated. Use: 
// - — CalendarSchedules.NearestWorkDates — for a business calendar, 
// - — or WorkSchedules.NearestDatesIncludedInSchedule — for a work schedule.
// Defines the nearest workday for each date.
//
// Parameters:
//    Schedule	- CatalogRef.Calendars
//	        	- CatalogRef.BusinessCalendars - a schedule or 
//                    business calendar to be used for calculations.
//    InitialDates 				- Array - an array of dates (Date).
//    GetPrevious		- Boolean - a method of getting the closest date:
//										if True, workdays preceding the ones passed in the InitialDates parameter are defined, 
//										if False, dates not earlier than the initial date are defined.
//    RaiseException1 - Boolean - if True, throw an exception if the schedule is not filled in.
//    IgnoreUnfilledSchedule - Boolean - if True, a map returns in any way. 
//										Initial dates whose values are missing because of unfilled schedule will not be included.
//
// Returns:
//    - Map of KeyAndValue:
//      * Key - Date - a date from the passed array
//      * Value - Date - the working date closest to it (if a working date is passed, it returns).
//							If the selected schedule is not filled in and RaiseException = False, Undefined returns
//    - Undefined
//
Function ClosestWorkdaysDates(Schedule, InitialDates, GetPrevious = False, RaiseException1 = True, 
	IgnoreUnfilledSchedule = False) Export
	
	If TypeOf(Schedule) <> Type("CatalogRef.BusinessCalendars") Then
		If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
			ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
			ReceivingParameters = ModuleWorkSchedules.NearestDatesByScheduleReceivingParameters();
			ReceivingParameters.GetPrevious = GetPrevious;
			ReceivingParameters.RaiseException1 = RaiseException1;
			ReceivingParameters.IgnoreUnfilledSchedule = IgnoreUnfilledSchedule;
			Return ModuleWorkSchedules.NearestDatesIncludedInSchedule(Schedule, InitialDates, ReceivingParameters);
		EndIf;
	EndIf;
	
	ReceivingParameters = NearestWorkDatesReceivingParameters();
	ReceivingParameters.GetPrevious = GetPrevious;
	ReceivingParameters.RaiseException1 = RaiseException1;
	Return NearestWorkDates(Schedule, InitialDates, ReceivingParameters);
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Creates a table DaysIncrement, in which a row with item index and value (number of days)  
// is generated for each item of the DaysArray.
// Calculates the maximum day shift.
// 
// Parameters:
//  DaysArray - Array of Number - A days array
//  CalculateNextDateFromPrevious - Boolean - Calculate the next date based on the previous date
// 
// Returns:
//  Structure:
//   * DaysIncrement - ValueTable
//   * Max - Number
//
Function DaysIncrement(DaysArray, Val CalculateNextDateFromPrevious = False) Export

	Result = New Structure();
	Result.Insert("DaysIncrement", New ValueTable);
	Result.Insert("Max", 0);

	Result.DaysIncrement.Columns.Add("RowIndex", New TypeDescription("Number"));
	Result.DaysIncrement.Columns.Add("DaysCount", New TypeDescription("Number"));
	
	DaysCount = 0;
	LineNumber = 0;
	For Each DaysRow In DaysArray Do
		DaysCount = DaysCount + DaysRow;
		String = Result.DaysIncrement.Add();
		String.RowIndex = LineNumber;
		String.DaysCount = ?(CalculateNextDateFromPrevious, DaysCount, DaysRow);
		Result.Max = Max(Result.Max, String.DaysCount);
		LineNumber = LineNumber + 1;
	EndDo;
	
	Return Result;

EndFunction

// Updates items related to a business calendar, 
// for example, Work schedules.
//
// Parameters:
//  ChangesTable - ValueTable:
//    * BusinessCalendarCode - Number - a code of business calendar whose data is changed.
//    * Year - Number - a year, for which data is to be updated.
//
Procedure DistributeBusinessCalendarsDataChanges(ChangesTable) Export
	
	CalendarSchedulesOverridable.OnUpdateBusinessCalendars(ChangesTable);
	
	If Common.DataSeparationEnabled() Then
		PlanUpdateOfDataDependentOnBusinessCalendars(ChangesTable);
		Return;
	EndIf;
	
	FillDataDependentOnBusinessCalendars(ChangesTable);
	
EndProcedure

// Updates items related to a business calendar, 
// for example, Work schedules, in data areas.
//
// Parameters:
//  ChangesTable - ValueTable:
//    * BusinessCalendarCode - Number - a code of business calendar whose data is changed.
//    * Year - Number - a year, for which data is to be updated.
//
Procedure FillDataDependentOnBusinessCalendars(ChangesTable) Export
	
	If ChangesTable.Count() = 0 Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
		ModuleWorkSchedules.UpdateWorkSchedulesAccordingToBusinessCalendars(ChangesTable);
	EndIf;
	
	CalendarSchedulesOverridable.OnUpdateDataDependentOnBusinessCalendars(ChangesTable);
	
EndProcedure

// Returns the internal classifier ID for the ClassifiersOperations subsystem.
//
// Returns:
//  String - a classifier ID.
//
Function ClassifierID() Export
	Return "Calendars20";
EndFunction

// Defines a version of data related to calendars built in the configuration.
//
// Returns:
//   Number - Version number.
//
Function CalendarsVersion() Export
	
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return 0;
	EndIf;
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	Return ModuleFillingInCalendarSchedules.CalendarsVersion();
	
EndFunction

// Returns the version of classifier data imported to the infobase.
//
// Returns:
//   Number - the version number of the imported data, or 0 if the classifier operations subsystem is unavailable.
//
Function LoadedCalendarsVersion() Export
	
	LoadedCalendarsVersion = Undefined;
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		LoadedCalendarsVersion = ModuleClassifiersOperations.ClassifierVersion(ClassifierID());
	EndIf;
	
	If LoadedCalendarsVersion = Undefined Then
		LoadedCalendarsVersion = 0;
	EndIf;
	
	Return LoadedCalendarsVersion;
	
EndFunction

// Requests a file with calendar classifier data. 
// Converts the retrieved file into a structure with calendar tables and their data.
// If the ClassifiersOperations subsystem is unavailable, or the classifier file cannot be retrieved, throws an exception.
//
// Returns:
//  Structure:
//   * BusinessCalendars - Structure:
//     ** TableName - String          - Table name.
//     ** Data     - ValueTable - A calendar table converted from XML.
//   * BusinessCalendarsData - Structure:
//     ** TableName - String          - Table name.
//     ** Data     - ValueTable - A calendar data table converted from XML.
//   * NonWorkDaysPeriods - Structure:
//     ** TableName - String          - Table name.
//     ** Data     - ValueTable - A calendar data table converted from XML.
//
Function ClassifierData() Export
	
	ClassifierData      = New Structure;
	
	BusinessCalendars = New Structure;
	BusinessCalendars.Insert("TableName", "");
	BusinessCalendars.Insert("Data",     New ValueTable());
	
	BusinessCalendarsData = New Structure(New FixedStructure(BusinessCalendars));
	NonWorkDaysPeriods             = New Structure(New FixedStructure(BusinessCalendars));

	ClassifierData.Insert("BusinessCalendarsData", BusinessCalendarsData);	
	ClassifierData.Insert("BusinessCalendars",        BusinessCalendars);
	ClassifierData.Insert("NonWorkDaysPeriods",             NonWorkDaysPeriods);
	
	CalendarSchedulesLocalization.WhenReceivingClassifierData(ClassifierData);
	
	Return ClassifierData;
	
EndFunction

#Region ConfigurationSubsystemsEventHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "CalendarSchedules.UpdateBusinessCalendars";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.66";
	Handler.Procedure = "CalendarSchedules.UpdateDependentBusinessCalendarsData";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.102";
	Handler.Procedure = "CalendarSchedules.UpdateMultipleBusinessCalendarsUsage";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.3.113";
	Handler.Procedure = "CalendarSchedules.ResetClassifierVersion";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.5.80";
	Handler.Procedure = "CalendarSchedules.FixTheDataOfDependentCalendars";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = BusinessCalendarsUpdateVersion();
	Handler.Procedure = "CalendarSchedules.UpdateBusinessCalendars";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = BusinessCalendarsDataUpdateVersion();
	Handler.Procedure = "CalendarSchedules.UpdateBusinessCalendarsData";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	AddHandlerOfDataDependentOnBusinessCalendars(Handlers);
	
EndProcedure

// See UsersOverridable.OnDefineRoleAssignment
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// ForSystemUsersOnly.
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.AddEditCalendarSchedules.Name);
	
EndProcedure

// Parameters:
//   Types - See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport.Types
//
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	Types.Add(Metadata.Catalogs.BusinessCalendars);
	
EndProcedure

// See SaaSOperationsOverridable.OnEnableSeparationByDataAreas.
Procedure OnEnableSeparationByDataAreas() Export
	
	CalendarsTable = Catalogs.BusinessCalendars.DefaultBusinessCalendars();
	Catalogs.BusinessCalendars.UpdateBusinessCalendars(CalendarsTable);
	UpdateMultipleBusinessCalendarsUsage();
	
	BusinessCalendarsData = Catalogs.BusinessCalendars.DefaultBusinessCalendarsData();
	NonWorkDaysPeriods = Catalogs.BusinessCalendars.DefaultNonWorkDaysPeriods();
	FillBusinessCalendarsDataOnUpdate(BusinessCalendarsData, NonWorkDaysPeriods);
	
EndProcedure

#EndRegion

#Region InfobaseUpdateHandlersUsedInOtherSubsystems

// Updates data dependent on business calendars.
//
Procedure UpdateDataDependentOnBusinessCalendars(ParametersOfUpdate) Export
	
	If Not ParametersOfUpdate.Property("ChangesTable") Then
		ParametersOfUpdate.ProcessingCompleted = True;
		Return;
	EndIf;
	
	ChangesTable = ParametersOfUpdate.ChangesTable; // ValueTable
	ChangesTable.GroupBy("BusinessCalendarCode, Year");
	
	FillDataDependentOnBusinessCalendars(ChangesTable);
	
	ParametersOfUpdate.ProcessingCompleted = True;
	
EndProcedure

Function ThereAreChangeableObjectsDependentOnProductionCalendars() Export
	
	ObjectsToChange = New Array;
	FillObjectsToChangeDependentOnBusinessCalendars(ObjectsToChange);
	Return ObjectsToChange.Count() > 0;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Gets a single business calendar in the infobase.
//
Function SingleBusinessCalendar()
	
	UsedCalendars = Catalogs.BusinessCalendars.BusinessCalendarsList();
	
	If UsedCalendars.Count() = 1 Then
		Return UsedCalendars[0];
	EndIf;
	
EndFunction

// Defines a regional business calendar by KPP.
//
Function StateBusinessCalendar(CRTR)
	
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return Undefined;
	EndIf;	
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	Return ModuleFillingInCalendarSchedules.StateBusinessCalendar(CRTR);
	
EndFunction


Function ClassifierFileData(Address) Export
	
	ClassifierData = New Structure(
		"BusinessCalendars,
		|BusinessCalendarsData,
		|NonWorkDaysPeriods");
	
	PathToFile = GetTempFileName();
	BinaryData = GetFromTempStorage(Address); // BinaryData
	BinaryData.Write(PathToFile);
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToFile);
	XMLReader.MoveToContent();
	CheckItemStart(XMLReader, "CalendarSuppliedData");
	XMLReader.Read();
	CheckItemStart(XMLReader, "Calendars");
	
	ClassifierData.BusinessCalendars = Common.ReadXMLToTable(XMLReader);
	
	XMLReader.Read();
	CheckItemEnd(XMLReader, "Calendars");
	XMLReader.Read();
	CheckItemStart(XMLReader, "CalendarData");
	
	ClassifierData.BusinessCalendarsData = Common.ReadXMLToTable(XMLReader);
	
	XMLReader.Read();
	CheckItemEnd(XMLReader, "CalendarData");
	XMLReader.Read();
	CheckItemStart(XMLReader, "NonWorkingPeriods");

	ClassifierData.NonWorkDaysPeriods = Common.ReadXMLToTable(XMLReader);
	
	XMLReader.Close();
	DeleteFiles(PathToFile);
	
	Return ClassifierData;
	
EndFunction

Procedure CheckItemStart(Val XMLReader, Val Name)
	
	If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> Name Then
		EventName = NStr("vi = 'Lịch biểu.Bộ xử lý tệp của bảng phân loại';
						|ru = 'Календарные графики.Обработка файла классификатора';
						|en = 'Calendar schedules.Process classifier file'; fa = 'Calendar schedules.Process classifier file';
						|it = 'Grafiche dei calendari.Elaborazione del file dal classificatore';
						|pl = 'Harmonogramy kalendarzowe.Przetwarzanie pliku klasyfikatora';
						|tr = 'Takvim grafikleri.Sınıflandırıcı dosyasını işleme'", Common.DefaultLanguageCode());
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai định dạng tệp dữ liệu. Đợi bắt đầu phần tử %1';
				|ru = 'Неверный формат файла данных. Ожидается начало элемента %1';
				|en = 'Invalid data file format. Start of ""%1"" element is expected.'; fa = 'Invalid data file format. Start of ""%1"" element is expected.';
				|it = 'Formato file di dati non valido. Si prevede l''inizio dell''elemento %1';
				|pl = 'Błędny format pliku danych. Oczekiwany jest początek elementu %1';
				|tr = 'Yanlış veri dosyası formatı. %1 öğesinin başlaması bekleniyor'"), 
			Name);
		WriteLogEvent(EventName, EventLogLevel.Error, , , MessageText);
		Raise MessageText;
	EndIf;
	
EndProcedure

Procedure CheckItemEnd(Val XMLReader, Val Name)
	
	If XMLReader.NodeType <> XMLNodeType.EndElement Or XMLReader.Name <> Name Then
		EventName = NStr("vi = 'Lịch biểu.Bộ xử lý tệp của bảng phân loại';
						|ru = 'Календарные графики.Обработка файла классификатора';
						|en = 'Calendar schedules.Process classifier file'; fa = 'Calendar schedules.Process classifier file';
						|it = 'Grafiche dei calendari.Elaborazione del file dal classificatore';
						|pl = 'Harmonogramy kalendarzowe.Przetwarzanie pliku klasyfikatora';
						|tr = 'Takvim grafikleri.Sınıflandırıcı dosyasını işleme'", Common.DefaultLanguageCode());
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai định dạng tệp dữ liệu. Đợi kết thúc phần tử %1';
				|ru = 'Неверный формат файла данных. Ожидается конец элемента %1';
				|en = 'Invalid data file format. End of the ""%1"" element is expected.'; fa = 'Invalid data file format. End of the ""%1"" element is expected.';
				|it = 'Formato file di dati non valido. La fine dell''elemento è prevista %1';
				|pl = 'Błędny format pliku danych. Oczekiwany jest koniec elementu %1';
				|tr = 'Yanlış veri dosyası formatı. %1 öğesinin sona ermesi bekleniyor'"), 
			Name);
		WriteLogEvent(EventName, EventLogLevel.Error, , , MessageText);
		Raise MessageText;
	EndIf;
	
EndProcedure

Function BusinessCalendarsUpdateVersion()
	
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return "1.0.0.1";
	EndIf;	
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	Return ModuleFillingInCalendarSchedules.BusinessCalendarsUpdateVersion();
	
EndFunction

Function BusinessCalendarsDataUpdateVersion()
	
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return "1.0.0.1";
	EndIf;
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	Return ModuleFillingInCalendarSchedules.BusinessCalendarsDataUpdateVersion();
	
EndFunction

#Region InfobaseUpdate

// Updates the Business calendars catalog from the template with the same name.
//
Procedure UpdateBusinessCalendars() Export
	
	If Common.IsStandaloneWorkplace() Then
		Return;
	EndIf;
	
	BuiltInCalendarsVersion = CalendarsVersion();
	If BuiltInCalendarsVersion <= LoadedCalendarsVersion() Then
		Return;
	EndIf;
	
	CalendarsTable = Catalogs.BusinessCalendars.BusinessCalendarsFromTemplate();
	Catalogs.BusinessCalendars.UpdateBusinessCalendars(CalendarsTable);
	UpdateMultipleBusinessCalendarsUsage();
	
	BusinessCalendarsData = Catalogs.BusinessCalendars.BusinessCalendarsDataFromTemplate();
	NonWorkDaysPeriods = Catalogs.BusinessCalendars.NonWorkDaysPeriodsFromTemplate();
	FillBusinessCalendarsDataOnUpdate(BusinessCalendarsData, NonWorkDaysPeriods);
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.SetClassifierVersion(ClassifierID(), BuiltInCalendarsVersion);
	EndIf;
	
EndProcedure

// Updates business calendar data from a template.
//  BusinessCalendarsData.
//
Procedure UpdateBusinessCalendarsData() Export
	
	If Common.IsStandaloneWorkplace() Then
		Return;
	EndIf;
	
	BuiltInCalendarsVersion = CalendarsVersion();
	If BuiltInCalendarsVersion <= LoadedCalendarsVersion() Then
		Return;
	EndIf;
	
	BusinessCalendarsData = Catalogs.BusinessCalendars.BusinessCalendarsDataFromTemplate();
	NonWorkDaysPeriods = Catalogs.BusinessCalendars.NonWorkDaysPeriodsFromTemplate();
	FillBusinessCalendarsDataOnUpdate(BusinessCalendarsData, NonWorkDaysPeriods);
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.SetClassifierVersion(ClassifierID(), BuiltInCalendarsVersion);
	EndIf;
	
EndProcedure

// Updates data of business calendars dependent on the basic ones.
//
Procedure UpdateDependentBusinessCalendarsData() Export
	
	If Common.IsStandaloneWorkplace() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Year", 2018);
	Query.Text = 
		"SELECT
		|	DependentCalendars.Ref AS Calendar,
		|	DependentCalendars.BasicCalendar AS BasicCalendar
		|INTO TTDependentCalendars
		|FROM
		|	Catalog.BusinessCalendars AS DependentCalendars
		|WHERE
		|	DependentCalendars.BasicCalendar <> VALUE(Catalog.BusinessCalendars.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	CalendarsData.BusinessCalendar AS BusinessCalendar,
		|	CalendarsData.Year AS Year
		|INTO TTCalendarYears
		|FROM
		|	InformationRegister.BusinessCalendarData AS CalendarsData
		|WHERE
		|	CalendarsData.Year >= &Year
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DependentCalendars.BasicCalendar AS BasicCalendar,
		|	DependentCalendars.BasicCalendar.Code AS BusinessCalendarCode,
		|	BasicCalendarData.Year AS Year
		|FROM
		|	TTDependentCalendars AS DependentCalendars
		|		INNER JOIN TTCalendarYears AS BasicCalendarData
		|		ON (BasicCalendarData.BusinessCalendar = DependentCalendars.BasicCalendar)
		|		LEFT JOIN TTCalendarYears AS DependentCalendarData
		|		ON (DependentCalendarData.BusinessCalendar = DependentCalendars.Calendar)
		|			AND (DependentCalendarData.Year = BasicCalendarData.Year)
		|WHERE
		|	DependentCalendarData.Year IS NULL";
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	ChangesTable = QueryResult.Unload();
	Catalogs.BusinessCalendars.UpdateDependentBusinessCalendarsData(ChangesTable);
	
	If Common.DataSeparationEnabled() Then
		PlanUpdateOfDataDependentOnBusinessCalendars(ChangesTable);
		Return;
	EndIf;
	
	HandlerParameters = InfobaseUpdateInternal.DeferredUpdateHandlerParameters(
		"CalendarSchedules.UpdateDataDependentOnBusinessCalendars");
	If HandlerParameters <> Undefined And HandlerParameters.Property("ChangesTable") Then
		CommonClientServer.SupplementTable(ChangesTable, HandlerParameters.ChangesTable);
	EndIf;
	
	HandlerParameters = New Structure("ChangesTable");
	HandlerParameters.ChangesTable = ChangesTable;
	InfobaseUpdateInternal.WriteDeferredUpdateHandlerParameters(
		"CalendarSchedules.UpdateDataDependentOnBusinessCalendars", HandlerParameters);
	
EndProcedure

Procedure FillBusinessCalendarDependentDataUpdateData(ParametersOfUpdate) Export
	
EndProcedure

Procedure FillObjectsToBlockDependentOnBusinessCalendars(Handler)
	
	ObjectsToLock = New Array;
	
	If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
		ModuleWorkSchedules.FillObjectsToBlockDependentOnBusinessCalendars(ObjectsToLock);
	EndIf;
	
	CalendarSchedulesOverridable.OnFillObjectsToBlockDependentOnBusinessCalendars(ObjectsToLock);
	
	Handler.ObjectsToLock = StrConcat(ObjectsToLock, ",");
	
EndProcedure

Procedure FillObjectsToChangeDependentOnBusinessCalendars(ObjectsToChange)
	
	If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
		ModuleWorkSchedules.FillObjectsToChangeDependentOnBusinessCalendars(ObjectsToChange);
	EndIf;
	
	CalendarSchedulesOverridable.OnFillObjectsToChangeDependentOnBusinessCalendars(ObjectsToChange);
	
EndProcedure

// The procedure updates data dependent on business calendars 
// for all data areas.
//
Procedure PlanUpdateOfDataDependentOnBusinessCalendars(Val UpdateConditions)
	
	CalendarSchedulesInternal.PlanUpdateOfDataDependentOnBusinessCalendars(UpdateConditions);
	
EndProcedure

Procedure FillBusinessCalendarsDataOnUpdate(DataTable, PeriodsTable)
	
	ChangesTable = Catalogs.BusinessCalendars.UpdateBusinessCalendarsData(DataTable);

	CommonClientServer.SupplementTable(
		Catalogs.BusinessCalendars.UpdateNonWorkDaysPeriods(PeriodsTable), ChangesTable);
	
	If Common.DataSeparationEnabled() Then
		PlanUpdateOfDataDependentOnBusinessCalendars(ChangesTable);
		Return;
	EndIf;

	HandlerParameters = InfobaseUpdateInternal.DeferredUpdateHandlerParameters(
		"CalendarSchedules.UpdateDataDependentOnBusinessCalendars");
	If HandlerParameters <> Undefined And HandlerParameters.Property("ChangesTable") Then
		CommonClientServer.SupplementTable(ChangesTable, HandlerParameters.ChangesTable);
	EndIf;
	
	HandlerParameters = New Structure("ChangesTable");
	HandlerParameters.ChangesTable = ChangesTable;
	InfobaseUpdateInternal.WriteDeferredUpdateHandlerParameters(
		"CalendarSchedules.UpdateDataDependentOnBusinessCalendars", HandlerParameters);
	
EndProcedure

// Sets a value of the constant defining usage of multiple business calendars.
//
Procedure UpdateMultipleBusinessCalendarsUsage() Export
	
	If Common.IsStandaloneWorkplace() Then
		Return;
	EndIf;
	
	UseMultipleCalendars = Catalogs.BusinessCalendars.BusinessCalendarsList().Count() <> 1;
	If UseMultipleCalendars <> GetFunctionalOption("UseMultipleBusinessCalendars") Then
		Constants.UseMultipleBusinessCalendars.Set(UseMultipleCalendars);
	EndIf;
	
EndProcedure

Procedure AddHandlerOfDataDependentOnBusinessCalendars(Handlers)
	
	If Common.DataSeparationEnabled() Then
		// In SaaS, it is done in a different way.
		Return;
	EndIf;
	
	ObjectsToChange = New Array;
	FillObjectsToChangeDependentOnBusinessCalendars(ObjectsToChange);
	If ObjectsToChange.Count() = 0 Then
		// No dependent objects.
		Return;
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = BusinessCalendarsDataUpdateVersion();
	Handler.Procedure = "CalendarSchedules.UpdateDataDependentOnBusinessCalendars";
	Handler.UpdateDataFillingProcedure = "CalendarSchedules.FillBusinessCalendarDependentDataUpdateData";
	Handler.ExecutionMode = "Deferred";
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.ObjectsToRead = "InformationRegister.BusinessCalendarData";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Id = New UUID("b1082291-b482-418f-82ab-3c96e93072cc");
	Handler.Comment = NStr("vi = 'Cập nhật lịch biểu làm việc và dữ liệu khác độc lập với lịch sản xuất.';
							|ru = 'Обновление графиков работы и др. данных, зависимых от производственных календарей.';
							|en = 'Updates work schedules and other data that depends on business calendars.'; fa = 'Updates work schedules and other data that depends on business calendars.';
							|it = 'Aggiornare i programmi di lavoro e altri dati dipendenti dai calendari di produzione.';
							|pl = 'Aktualizacja harmonogramów pracy i inn. danych, zależących od kalendarzy produkcyjnych.';
							|tr = 'Çalışma programlarını ve diğer verileri iş takvimlerine göre güncelle.'");
	Handler.ObjectsToChange = StrConcat(ObjectsToChange, ",");
	FillObjectsToBlockDependentOnBusinessCalendars(Handler);
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
		ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = ModuleWorkSchedules.WorkSchedulesUpdateProcedureName();
		Priority.Order = "Before";
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = ModuleWorkSchedules.ConsiderNonWorkDaysFlagSettingProcedureName();
		Priority.Order = "After";
	EndIf;
	
EndProcedure

Procedure DeletePeriodsThatDoNotMatchFilter(TimeIntervals, PeriodFilter)
	
	IndexOf = 0;
	While IndexOf < TimeIntervals.Count() Do
		PeriodDetails = TimeIntervals[IndexOf];
		If PeriodFilter.StartDate > PeriodDetails.Period.EndDate 
			Or (ValueIsFilled(PeriodFilter.EndDate) And PeriodFilter.EndDate < PeriodDetails.Period.StartDate) Then
			TimeIntervals.Delete(IndexOf);
		Else
			IndexOf = IndexOf + 1;
		EndIf; 
	EndDo;
	
EndProcedure

Function NonWorkDatesByNonWorkPeriod(NonWorkPeriods, BusinessCalendar)

	NonWorkDates = New Array;

	If TypeOf(NonWorkPeriods) = Type("Array") Then
		If NonWorkPeriods.Count() = 0 Then
			Return NonWorkDates;
		EndIf;
		If TypeOf(NonWorkPeriods[0]) = Type("Number") Then
			PeriodsDetails = NonWorkDaysPeriods(BusinessCalendar, New StandardPeriod());
			IndexOf = 0;
			While IndexOf < PeriodsDetails.Count() Do
				If NonWorkPeriods.Find(PeriodsDetails[IndexOf].Number) = Undefined Then
					PeriodsDetails.Delete(IndexOf);
				Else
					IndexOf = IndexOf + 1;
				EndIf; 
			EndDo;
		ElsIf TypeOf(NonWorkPeriods[0]) = Type("Structure") Then
			PeriodsDetails = NonWorkPeriods;
		Else
			CommonClientServer.Validate(False,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Kiểu giá trị phần tử không hợp lệ trong tham số %1:
					           |%2';
					           |ru = 'Недопустимый тип значения элемента в параметре %1:
					           |%2';
					           |en = 'Invalid item value type in the %1 parameter:
					           |%2'; fa = 'Invalid item value type in the %1 parameter:
					           |%2';
					           |it = 'Tipo non disponibile di valore dell''elemento%1:
					           |%2';
					           |pl = 'Niedopuszczalny typ wartości elementu w parametrze %1:
					           |%2';
					           |tr = '%1 parametresinde geçersiz öğe değer türü:
					           |%2'"), "NonWorkPeriods", TypeOf(NonWorkPeriods[0])),
				"CalendarSchedules.NearestWorkDates");
		EndIf;
	EndIf;

	If NonWorkPeriods = Undefined Then
		PeriodsDetails = NonWorkDaysPeriods(BusinessCalendar, New StandardPeriod());
	EndIf;
	
	For Each Period In PeriodsDetails Do
		CommonClientServer.SupplementArray(NonWorkDates, Period.Dates);
	EndDo;
	
	Return NonWorkDates;
	
EndFunction

Procedure ResetClassifierVersion() Export
	
	If LoadedCalendarsVersion() = 0 Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		ModuleClassifiersOperations = Common.CommonModule("ClassifiersOperations");
		ModuleClassifiersOperations.SetClassifierVersion(ClassifierID(), 1);
	EndIf;
	
EndProcedure

Procedure FixTheDataOfDependentCalendars() Export
	
	If Common.IsStandaloneWorkplace() Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("DependentCalendarsUpdateStartYear", 2018);
	Query.Text = 
		"SELECT DISTINCT
		|	DependentCalendars.Ref.Code AS CalendarCode1
		|FROM
		|	InformationRegister.BusinessCalendarData AS BaseCalendarData
		|		INNER JOIN Catalog.BusinessCalendars AS DependentCalendars
		|		ON (DependentCalendars.BasicCalendar = BaseCalendarData.BusinessCalendar)
		|			AND (BaseCalendarData.BusinessCalendar.BasicCalendar = VALUE(Catalog.BusinessCalendars.EmptyRef))
		|			AND (BaseCalendarData.Year >= &DependentCalendarsUpdateStartYear)
		|			AND (NOT TRUE IN
		|					(SELECT TOP 1
		|						TRUE
		|					FROM
		|						InformationRegister.BusinessCalendarData AS Data
		|					WHERE
		|						Data.BusinessCalendar = DependentCalendars.Ref
		|						AND Data.Year = BaseCalendarData.Year))";

	CalendarsCodes = Query.Execute().Unload().UnloadColumn("CalendarCode1");
	If CalendarsCodes.Count() = 0 Then
		Return;
	EndIf;

	BusinessCalendarsData = Catalogs.BusinessCalendars.DefaultBusinessCalendarsData(CalendarsCodes);
	NonWorkDaysPeriods = Catalogs.BusinessCalendars.DefaultNonWorkDaysPeriods();
	FillBusinessCalendarsDataOnUpdate(BusinessCalendarsData, NonWorkDaysPeriods);

EndProcedure

// Parameters:
//  See NearestWorkDates
// 
// Returns:
//  Undefined, QueryResultSelection:
//   * Date - Date
//   * NearestDate - Date
//
Function SelectionOfNearestBusinessDates(BusinessCalendar, InitialDates, ReceivingParameters)
	
	QueryText = StartDatesQueryText(InitialDates);

	If IsBlankString(QueryText) Then
		Return Undefined;
	EndIf;

	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.Execute();
	
	QueryText = 
		"SELECT
		|	InitialDates.Date,
		|	MIN(CalendarDates.Date) AS NearestDate
		|FROM
		|	TTInitialDates AS InitialDates
		|		LEFT JOIN InformationRegister.BusinessCalendarData AS CalendarDates
		|		ON CalendarDates.Date >= InitialDates.Date
		|		AND CalendarDates.BusinessCalendar = &BusinessCalendar
		|		AND CalendarDates.DayKind IN (VALUE(Enum.BusinessCalendarDaysKinds.Work),
		|			VALUE(Enum.BusinessCalendarDaysKinds.Preholiday))
		|		AND CalendarDates.Date NOT IN (&NonWorkDates)
		|GROUP BY
		|	InitialDates.Date";
	
	If ReceivingParameters.GetPrevious Then
		QueryText = StrReplace(QueryText, "MIN(CalendarDates.Date)", "MAX(CalendarDates.Date)");
		QueryText = StrReplace(QueryText, "CalendarDates.Date >= InitialDates.Date",
			"CalendarDates.Date <= InitialDates.Date");
	EndIf;
	Query.Text = QueryText;
	Query.SetParameter("BusinessCalendar", BusinessCalendar);
	
	NonWorkDates = New Array;
	If ReceivingParameters.ConsiderNonWorkPeriods Then
		NonWorkDates = NonWorkDatesByNonWorkPeriod(ReceivingParameters.NonWorkPeriods, BusinessCalendar);
	EndIf;
	Query.SetParameter("NonWorkDates", NonWorkDates);
	
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

// Parameters:
//  InitialDates - Array of Date
// 
// Returns:
//  String
//
Function StartDatesQueryText(InitialDates)
	
	QueriesTexts = New Array;
	For Each InitialDate In InitialDates Do
		If Not ValueIsFilled(InitialDate) Then
			Continue;
		EndIf;
		QueryText = 
			"SELECT
			|	&InitialDate AS Date
			|INTO TTInitialDates";
		QueryText = StrReplace(
			QueryText, "&InitialDate", StrTemplate("DATETIME(%1)", Format(InitialDate, "DF=yyyy,MM,dd"))); // ACC:456 Not localizable.
		If QueriesTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "INTO TTInitialDates", "");
		EndIf;
		QueriesTexts.Add(QueryText);
	EndDo;

	QueryText = StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF);
	
	Return QueryText;
	
EndFunction

// Determines the nearest working day to the provided date based on the data of the default business calendar in the Russian Federation.
// If "InitialDate" is a working day, return it. Intended for cases, when no custom business calendar is filled.
// 
// 
// Parameters:
//  InitialDate - Date
//  DefaultCalendarData - See Catalogs.BusinessCalendars.NewBusinessCalendarsData
//  GetPreviousOne - Boolean - The method of getting the nearest date.:
//	 If set to "True", it returns the date that comes before "InitialDate". 
//	 If set to "False", it returns the date that comes after "InitialDate".
// 
// Returns:
//  Date, Undefined
//
Function NearestBusinessDateFromDefaultCalendar(InitialDate, DefaultCalendarData = Undefined,
	GetPreviousOne = False)
	
	If DefaultCalendarData = Undefined Then
		DefaultCalendarData = Catalogs.BusinessCalendars.NewBusinessCalendarsData();
	EndIf;
	
	Year = Year(InitialDate);
	If DefaultCalendarData.Find(Year, "Year") = Undefined Then
		SupplementDefaultCalendarData(DefaultCalendarData, Year, GetPreviousOne);
	EndIf;
	
	TableRow = DefaultCalendarData.Find(InitialDate, "Date");
	If TableRow = Undefined Then
		Return Undefined;
	EndIf;
	If TableRow.DayKind = Enums.BusinessCalendarDaysKinds.Work
		Or TableRow.DayKind = Enums.BusinessCalendarDaysKinds.Preholiday Then
		Return TableRow.Date;
	EndIf;
	
	IndexOf = DefaultCalendarData.IndexOf(TableRow);
	ValueToAdd = ?(GetPreviousOne, -1, 1);
	While True Do
		IndexOf = IndexOf + 1;
		If IndexOf >= DefaultCalendarData.Count() Then
			If IndexOf > 10000 Then
				Break;
			EndIf;
			Year = Year + ValueToAdd;
			SupplementDefaultCalendarData(DefaultCalendarData, Year, GetPreviousOne);
		EndIf;
		TableRow = DefaultCalendarData.Get(IndexOf);
		If TableRow.DayKind = Enums.BusinessCalendarDaysKinds.Work
			Or TableRow.DayKind = Enums.BusinessCalendarDaysKinds.Preholiday Then
			Return TableRow.Date;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Parameters:
//  DefaultCalendarData - See Catalogs.BusinessCalendars.NewBusinessCalendarsData
//  Year - Number
//  SortInDescendingOrder - Boolean
//
Procedure SupplementDefaultCalendarData(DefaultCalendarData, Year, SortInDescendingOrder)

	CommonClientServer.SupplementTable(
		Catalogs.BusinessCalendars.BusinessCalendarDefaultFillingResult("RF", Year),
		DefaultCalendarData);
		
	If SortInDescendingOrder Then
		DefaultCalendarData.Sort("Date Desc");
	Else
		DefaultCalendarData.Sort("Date Asc");
	EndIf;
	
EndProcedure

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("UpdateMultipleBusinessCalendarsUsage");
	Methods.Insert("UpdateBusinessCalendarsData");
	Methods.Insert("FillBusinessCalendarDependentDataUpdateData");
	Methods.Insert("UpdateDataDependentOnBusinessCalendars");
	Methods.Insert("ResetClassifierVersion");
	Methods.Insert("UpdateBusinessCalendars");
	Methods.Insert("FixTheDataOfDependentCalendars");
	Methods.Insert("UpdateDependentBusinessCalendarsData");
	
EndProcedure

#EndRegion