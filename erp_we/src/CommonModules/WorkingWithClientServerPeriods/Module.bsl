#Region Public

// This function adds an interval to the date
//
// Parameters:
//	Date - Date - Custom date
//	Periodicity - EnumRef.Periodicity - Frequency of scenario planning.
//	Offset - Number - defines the direction and number of periods in which the date is shifted
//	Cache - Map - cache for adding periods.
//
// Returns:
//	Date - a date that is separated from the original date by a specified number of periods.
//
Function AddInterval(Date, Periodicity, Offset, Cache = Undefined) Export
	
	If Cache <> Undefined Then
		DateInCache = Cache[Date];
		If DateInCache <> Undefined Then
			PeriodicityInCache = DateInCache[Periodicity];
			If PeriodicityInCache <> Undefined Then
				Result = PeriodicityInCache[Offset];
				If Result <> Undefined Then
					Return Result;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If Offset = 0 Then
		Result = Date;
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		Result = StartOfWeekByMonth(Date + Offset * 7 * 24 * 3600);
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.TenDays") Then
		Result = BeginningOfDecade(Date + Offset * 11 * 24 * 3600);
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
		Result = AddMonth(Date, Offset);
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
		Result = AddMonth(Date, Offset * 3);
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
		Result = AddMonth(Date, Offset * 6);
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
		Result = AddMonth(Date, Offset * 12);
		
	Else
		Result = BegOfDay(Date) + Offset * 24 * 3600;
	EndIf;
	
	If Cache <> Undefined Then
		
		If Cache[Date] = Undefined Then
			Cache.Insert(Date, New Map);
		EndIf;
		
		If Cache[Date][Periodicity] = Undefined Then
			Cache[Date].Insert(Periodicity, New Map);
		EndIf;
		
		Cache[Date][Periodicity].Insert(Offset, Result);
		
	EndIf;
	
	Return Result;
	
EndFunction

// This function adds the specified number of days to the date.
//
// Parameters:
// 	Date - Date - Custom date
// 	NumberOfDays - Number - The number of days to add to the date.
// 
// Returns:
// 	Date - The final date.
//
Function AddADay(Date, NumberOfDays) Export
	
	Return Date + NumberOfDays * 86400; // 86400 = 24*60*60 - number of seconds in a day;
	
EndFunction 

// The function returns the nearest start date of the planning period.
//
// Parameters:
//	DateInPeriod - Date - any date.
//	Periodicity - EnumRef.Periodicity - Frequency of scenario planning.
//
// Returns:
//	Date - the nearest start date of the planning period.
//
Function BeginningDateOfPeriod(DateInPeriod, Periodicity) Export
	
	If Not TypeOf(DateInPeriod) = Type("Date") Then
		Return '00010101';
	EndIf;
	
	If Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		Return StartOfWeekByMonth(DateInPeriod);
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.TenDays") Then
		Return BeginningOfDecade(DateInPeriod);
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
		Return BegOfMonth(DateInPeriod);
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
		Return BegOfQuarter(DateInPeriod);
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
		Return BeginningOfHalfYear(DateInPeriod);
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
		Return BegOfYear(DateInPeriod);
	Else
		Return BegOfDay(DateInPeriod);
	EndIf;
	
EndFunction

// The function returns the beginning of the decade by date.
//
// Parameters:
//	Date - Date - any date.
//
// Returns:
//	Date - the beginning of the decade for the transmitted date.
//
Function BeginningOfDecade(Date) Export
	
	If Day(Date) < 11 Then
		Return BegOfMonth(Date);
	ElsIf Day(Date) < 21 Then
		Return AddADay(BegOfMonth(Date), 10);
	Else 
		Return AddADay(BegOfMonth(Date), 20);
	EndIf;
	
EndFunction

// The function returns the end of the decade by date.
//
// Parameters:
//	Date - Date - any date.
//
// Returns:
//	Date - the end of the decade for the transmitted date.
//
Function EndOfDecade(Date) Export
	
	If Day(Date) < 11 Then
		Return AddADay(BegOfMonth(Date), 10) - 1;
	ElsIf Day(Date) < 21 Then
		Return AddADay(BegOfMonth(Date), 20) - 1;
	Else 
		Return EndOfMonth(Date);
	EndIf;
	
EndFunction // The end of the Decade() 

// The function returns the beginning of the half-year by date.
//
// Parameters:
//	Date - Date - any date.
//
// Returns:
//	Date - the beginning of the half-year for the transferred date.
//
Function BeginningOfHalfYear(Date) Export
	
	If Month(Date) < 7 Then
		Return BegOfYear(Date);
	Else
		Return AddMonth(BegOfYear(Date), 6);
	EndIf;
	
EndFunction

// The function returns the end of the half-year by date.
//
// Parameters:
//	Date - Date - any date.
//
// Returns:
//	Date - the beginning of the half-year for the transferred date.
//
Function EndOfHalfYear(Date) Export
	
	If Month(Date) < 7 Then
		Return EndOfDay(Date(Year(Date), 6, 30));
	Else
		Return EndOfYear(Date);
	EndIf;
	
EndFunction

// The function returns the start date of the week, taking into account the beginning of the month
//
// Parameters:
//	Date - Date - any date.
//
// Returns:
//	Date - the beginning of the week.
//
Function StartOfWeekByMonth(Date) Export
	
	If Day(Date) < 7 Then
		Return ?(Day(BegOfWeek(Date)) > Day(Date), BegOfMonth(Date), BegOfWeek(Date));
	Else
		Return BegOfWeek(Date);
	EndIf;
	
EndFunction

// The function returns the end date of the period
//
// Parameters:
//	Date - Date - any date.
//	Periodicity - EnumRef.Periodicity - Frequency of scenario planning.
//
// Returns:
//	Date - end date of the period.
//
Function PeriodEndDate_(Date, Periodicity) Export
	
	If Not TypeOf(Date) = Type("Date") Then
		Return '00010101';
	EndIf;
	
	If Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		Return EndOfWeek(Date);
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.TenDays") Then
		Return EndOfDecade(Date);
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
		Return EndOfMonth(Date);
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
		Return EndOfQuarter(Date);
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
		Return EndOfHalfYear(Date);
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
		Return EndOfYear(Date);
	Else
		Return EndOfDay(Date);
	EndIf;
	
EndFunction

// The function returns a performance period, taking into account periodicity
//
// Parameters:
//	StartDate - Date - any date.
//	Periodicity - EnumRef.Periodicity - Periodicity.
//
// Returns:
//	String - period representation.
//
Function PresentationOfPeriodByDate(StartDate, Periodicity) Export
	
	Presentation = "";
	PeriodPresentationFormatString = "FP = True";
	
	If Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		
		Presentation = NStr("vi = 'Tuần từ %1';
							|ru = 'Неделя с %1';
							|en = 'Week from %1'; fa = 'Week from %1';
							|it = 'Settimana da %1';
							|pl = 'Tydzień od %1';
							|tr = '%1 hafta itibarıyla'");
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(Presentation, Format(StartDate, "DLF=D"));
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.TenDays") Then
		
		If Day(StartDate) < 10 Then
			Presentation = NStr("vi = 'mười ngày đầu. %1';
								|ru = '1 декада. %1';
								|en = '1 ten-day period. %1'; fa = '1 ten-day period. %1';
								|it = '1 decennio. %1';
								|pl = '1 dekada. %1';
								|tr = '10 günlük süre. %1'");
		ElsIf Day(StartDate) < 20 Then
			Presentation = NStr("vi = 'hai mươi ngày. %1';
								|ru = '2 декада. %1';
								|en = '2 ten-day period. %1'; fa = '2 ten-day period. %1';
								|it = '2 decennio. %1';
								|pl = '2 dekada. %1';
								|tr = '20 günlük süre. %1'");
		Else 
			Presentation = NStr("vi = 'ba mươi ngày. %1';
								|ru = '3 декада. %1';
								|en = '3 ten-day period. %1'; fa = '3 ten-day period. %1';
								|it = '3 decennio. %1';
								|pl = '3 dekada. %1';
								|tr = '30 günlük süre. %1'");
		EndIf;
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(Presentation, Format(StartDate, "DLF=D"));
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
		
		Presentation = PeriodPresentation(StartDate, EndOfMonth(StartDate), PeriodPresentationFormatString);
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
		
		Presentation = PeriodPresentation(StartDate, EndOfQuarter(StartDate), PeriodPresentationFormatString);
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
		
		Presentation = PeriodPresentation(StartDate, EndOfHalfYear(StartDate), PeriodPresentationFormatString);
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
		
		Presentation = PeriodPresentation(StartDate, EndOfYear(StartDate), PeriodPresentationFormatString);
		
	Else
		
		Presentation = Format(StartDate, "DLF=D");
		
	EndIf;
	
	Return Presentation;
	
EndFunction

// The function returns a number in digits and a period in the appropriate case
//
// Parameters:
// 	 NumberOfPeriods_ - Number - number of periods
// 	 Periodicity - EnumRef.Periodicity - the frequency of periods.
//
// Returns:
// 	 String - Performance.
//
Function PeriodInNumbersPeriodicityInWords(NumberOfPeriods_, Periodicity) Export
	
	DurationDescription = "";
	If Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
		DurationDescription = NStr("vi = ';%1 ngày;;%1 ngày;%1 ngày;';
									|ru = ';%1 день;;%1 дня;%1 дней;';
									|en = ';%1 day;;%1 days;%1 days;'; fa = ';%1 day;;%1 days;%1 days;';
									|it = ';%1 giorno;;%1 giorni;%1 giorni;';
									|pl = ';%1 dzień;;%1 dnia;%1 dni;';
									|tr = ';%1 gün;;%1 gün;%1 gün;'");
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		DurationDescription = NStr("vi = ';%1 tuần;;%1 tuần;%1 tuần;';
									|ru = ';%1 неделя;;%1 недели;%1 недель;';
									|en = ';%1 week;;%1 weeks;%1 weeks;'; fa = ';%1 week;;%1 weeks;%1 weeks;';
									|it = ';%1 settimana;;%1 settimane; %1 settimane:';
									|pl = ';%1 tydzień;;%1 tygodnie;%1 tygodni;';
									|tr = ';%1 hafta;;%1 hafta;%1 hafta;'");
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.TenDays") Then
		DurationDescription = NStr("vi = ';%1 mười ngày;;%1 mười ngày;%1 mười ngày;';
									|ru = ';%1 декада;;%1 декады;%1 декад;';
									|en = ';%1 ten-day period;;%1 ten-day periods;%1 ten-day periods;'; fa = ';%1 ten-day period;;%1 ten-day periods;%1 ten-day periods;';
									|it = ';%1 decade;;%1 decade;%1 decade;';
									|pl = ';%1 dekada;;%1 dekady;%1 dekad;';
									|tr = ';%1 on günlük süre;;%1 on günlük süre;%1 on günlük süre;'");
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
		DurationDescription = NStr("vi = '; %1 tháng;; %1 tháng; %1 tháng;';
									|ru = ';%1 месяц;;%1 месяца;%1 месяцев;';
									|en = ';%1 month;;%1 month;%1 months;'; fa = ';%1 month;;%1 month;%1 months;';
									|it = ';%1 mese;; %1 mesi; %1 mesi;';
									|pl = ';%1 miesiąc;;%1 miesiąca;%1 miesięcy;';
									|tr = ';%1 ay;;%1 ay;%1 ay;'");
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
		DurationDescription = NStr("vi = ';%1 quý;;%1 quý;%1 quý;';
									|ru = ';%1 квартал;;%1 квартала;%1 кварталов;';
									|en = ';%1 quarter;;%1 quarter;%1 quarters;'; fa = ';%1 quarter;;%1 quarter;%1 quarters;';
									|it = ';%1 trimestre;;%1 trimestre;%1 trimestri;';
									|pl = ';%1 kwartał;;%1 kwartały;%1 kwartałów;';
									|tr = ';%1 yıl çeyreği;;%1 yıl çeyreği;%1 yıl çeyreği;'");
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
		DurationDescription = NStr("vi = ';%1 nửa năm;;%1 nửa năm;%1 nửa năm;';
									|ru = ';%1 полугодие;;%1 полугодия;%1 полугодий;';
									|en = ';%1 half-year;;%1 half-year;%1 half-years;'; fa = ';%1 half-year;;%1 half-year;%1 half-years;';
									|it = ';%1 sei mesi;%1 sei mesi;%1 sei mesi';
									|pl = ';%1 półrocze;;%1 półrocza;%1 półroczy;';
									|tr = ';%1 yarıyıl;;%1 yarıyıl;%1 yarıyıl;'");
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
		DurationDescription = NStr("vi = '; %1 năm ;; %1 năm; %1 năm;';
									|ru = ';%1 год;;%1 года;%1 лет;';
									|en = ';%1 year;;%1 years;%1 years;'; fa = ';%1 year;;%1 years;%1 years;';
									|it = ';%1 anno;;%1 anni;%1 anni;';
									|pl = ';%1 rok;;%1 roku%1 lat;';
									|tr = ';%1 yıl;;%1 yıl;%1 yıl;'");
	EndIf;
	
	Return StringFunctionsClientServer.StringWithNumberForAnyLanguage(DurationDescription, NumberOfPeriods_);
	
EndFunction

#EndRegion