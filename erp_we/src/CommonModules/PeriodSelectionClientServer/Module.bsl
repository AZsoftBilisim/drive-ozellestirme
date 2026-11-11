////////////////////////////////////////////////////////////////////////////////
// Functions and procedures for ensuring the selection of the period.
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Fills in the selection list passed in the parameters. 
// 
// Parameters: 
// MinimumPeriod   - EnumRef.AvailableReportPeriods - the minimum type of period 
//                       from which to include the other types of period in ascending order.
// ChoiceList        - ValueList - in the list, return the completed selection list
// DefaultValue - EnumRef.AvailableReportPeriods - returns the default period type in the parameter.
//
Procedure FillInPeriodViewSelectionList(Val MinimumPeriod, ChoiceList, DefaultValue = Undefined) Export
	
	If TypeOf(ChoiceList) <> Type("ValueList") Then
		Return;
	EndIf;
	
	ListOfAvailablePeriods = GetListOfAvailablePeriods();
	
	ListItem = ListOfAvailablePeriods.FindByValue(MinimumPeriod);
	If ListItem <> Undefined Then
		ElementIndex = ListOfAvailablePeriods.IndexOf(ListItem);
		For Cnt = ElementIndex To ListOfAvailablePeriods.Count() - 1 Do
			Period = ListOfAvailablePeriods.Get(Cnt);
			ChoiceList.Add(Period.Value, Period.Presentation);
		EndDo;
		If Not ValueIsFilled(DefaultValue) Then
			DefaultValue = PredefinedValue("Enum.AvailableReportPeriods.Custom");
		EndIf;
	Else
		Return; 
	EndIf;
	
EndProcedure

// Returns the start date of the passed period, the period is determined by the given date.
//
// Parameters:
//   PeriodType – Listing Link.Available reporting period - Type of period.
//   PeriodDate_ - Date - Date that belongs to the period.
//
// Returns:
//   Date - start date of the period.
//
Function BeginningOfReportPeriod(PeriodType, PeriodDate_) Export
	
	BeginOfPeriod = PeriodDate_;
	
	If PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Year") Then
		BeginOfPeriod = BegOfYear(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.HalfYear") Then
		If Month(PeriodDate_) > 6 Then
			BeginOfPeriod = Date(Year(PeriodDate_), 7, 1);
		Else
			BeginOfPeriod = Date(Year(PeriodDate_), 1, 1);
		EndIf;
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Quarter") Then
		BeginOfPeriod = BegOfQuarter(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Month") Then
		BeginOfPeriod = BegOfMonth(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.TenDays") Then
		If Day(PeriodDate_) <= 10 Then
			BeginOfPeriod = Date(Year(PeriodDate_), Month(PeriodDate_), 1);
		ElsIf Day(PeriodDate_) > 10 And Day(PeriodDate_) <= 20 Then
			BeginOfPeriod = Date(Year(PeriodDate_), Month(PeriodDate_), 11);
		Else
			BeginOfPeriod = Date(Year(PeriodDate_), Month(PeriodDate_), 21);
		EndIf;
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Week") Then
		BeginOfPeriod = BegOfWeek(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Day") Then
		BeginOfPeriod = BegOfDay(PeriodDate_);
		
	EndIf;
		
	Return BeginOfPeriod;
	
EndFunction
 
// Returns the end date of the passed period type. the period itself is determined by the passed date.
//
// Parameters:
//   PeriodType – Listing Link.Available reporting period - Type of period.
//   PeriodDate_ - Date - Date that belongs to the period.
//
// Returns:
//   Date - end date of the period.
//
Function EndOfReportPeriod(PeriodType, PeriodDate_) Export
	
	EndOfPeriod = PeriodDate_;
	
	If PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Year") Then
		EndOfPeriod = EndOfYear(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.HalfYear") Then
		If Month(PeriodDate_) > 6 Then
			EndOfPeriod = EndOfYear(PeriodDate_);
		Else
			EndOfPeriod = EndOfDay(Date(Year(PeriodDate_), 6, 30));
		EndIf;
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Quarter") Then
		EndOfPeriod = EndOfQuarter(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Month") Then
		EndOfPeriod = EndOfMonth(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.TenDays") Then
		If Day(PeriodDate_) <= 10 Then
			EndOfPeriod = EndOfDay(Date(Year(PeriodDate_), Month(PeriodDate_), 10));
		ElsIf Day(PeriodDate_) > 10 And Day(PeriodDate_) <= 20 Then
			EndOfPeriod = EndOfDay(Date(Year(PeriodDate_), Month(PeriodDate_), 20));
		Else
			EndOfPeriod = EndOfMonth(PeriodDate_);
		EndIf;
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Week") Then
		EndOfPeriod = EndOfWeek(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Day") Then
		EndOfPeriod = EndOfDay(PeriodDate_);
		
	EndIf;
		
	Return EndOfPeriod;
	
EndFunction

// Returns a list of periods, list is determined by the given date and period.
// 
// Parameters:
//   BeginOfPeriod - Date - start date of the period.
//   PeriodType    - EnumRef.AvailableReportPeriods - Type of period.
// 
// Returns:
//   ValueList - A list of possible periods.
// 
Function GetListOfPeriods(Val BeginOfPeriod, Val PeriodType) Export
	
	PeriodsList = New ValueList;
	If BeginOfPeriod = '00010101' Then
		Return New ValueList;
	Else
		StartOfPeriodValue = BeginOfPeriod;
	EndIf;
	
	If PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Year") Then
		CurrentYear = Year(StartOfPeriodValue);
		PeriodsList.Add(Date(CurrentYear - 7, 1, 1), NStr("vi = 'Năm trước';
															|ru = 'Предыдущие года';
															|en = 'Previous years'; fa = 'Previous years';
															|it = 'Anno precedente';
															|pl = 'Poprzednie lata';
															|tr = 'Önceki yıllar'"));
		For Cnt = CurrentYear - 3 To CurrentYear + 3 Do
			PeriodsList.Add(Date(Cnt, 1, 1), Format(Cnt, "NG=0"));
		EndDo;
		PeriodsList.Add(Date(CurrentYear + 7, 1, 1), NStr("vi = 'Năm tiếp theo';
															|ru = 'Последующие года';
															|en = 'Subsequent years'; fa = 'Subsequent years';
															|it = 'Anno successivo';
															|pl = 'Następujące lata';
															|tr = 'Sonraki yıllar'"));
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.HalfYear") Then
		CurrentYear = Year(StartOfPeriodValue);
		PeriodsList.Add(Date(CurrentYear - 2, 1, 1), Format(CurrentYear - 2, "NG=0") + "...");
		For Cnt = CurrentYear - 1 To CurrentYear + 1 Do
			PeriodsList.Add(Date(Cnt, 1, 1), StrTemplate(NStr("vi = 'Nửa năm I %1';
																|ru = 'I полугодие %1';
																|en = 'Half-year I %1'; fa = 'Half-year I %1';
																|it = 'I semestre %1';
																|pl = 'I półrocze %1';
																|tr = 'I yarıyıl %1'"), Format(Cnt, "NG=0")));
			PeriodsList.Add(Date(Cnt, 7, 1), StrTemplate(NStr("vi = 'Nửa năm II %1';
																|ru = 'II полугодие %1';
																|en = 'Half-year II %1'; fa = 'Half-year II %1';
																|it = 'II semestre %1';
																|pl = 'II półrocze %1';
																|tr = 'I yarıyıl %1'"), Format(Cnt, "NG=0")));
		EndDo;
		PeriodsList.Add(Date(CurrentYear + 2, 1, 1), Format(CurrentYear + 2, "NG=0") + "...");
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Quarter") Then
		CurrentYear = Year(StartOfPeriodValue);
		PeriodsList.Add(Date(CurrentYear - 2, 1, 1), Format(CurrentYear - 2, "NG=0") + "...");
		For Cnt = CurrentYear - 1 To CurrentYear Do
			PeriodsList.Add(Date(Cnt, 1, 1),	 StrTemplate(NStr("vi = 'Quý 1 %1';
																	|ru = '1 квартал %1';
																	|en = 'Quarter 1 %1'; fa = 'Quarter 1 %1';
																	|it = 'I trimestre %1';
																	|pl = '1 kwartał %1';
																	|tr = '1 çeyrek %1'"), Format(Cnt, "NG=0")));
			PeriodsList.Add(Date(Cnt, 4, 1),	 StrTemplate(NStr("vi = 'Quý 2 %1';
																	|ru = '2 квартал %1';
																	|en = 'Quarter 2 %1'; fa = 'Quarter 2 %1';
																	|it = 'II trimestre %1';
																	|pl = '2 kwartał %1';
																	|tr = '2 çeyrek %1'"), Format(Cnt, "NG=0")));
			PeriodsList.Add(Date(Cnt, 7, 1),	 StrTemplate(NStr("vi = 'Quý 3 %1';
																	|ru = '3 квартал %1';
																	|en = 'Quarter 3 %1'; fa = 'Quarter 3 %1';
																	|it = 'III trimestre %1';
																	|pl = '3 kwartał %1';
																	|tr = '3 çeyrek %1'"), Format(Cnt, "NG=0")));
			PeriodsList.Add(Date(Cnt, 10, 1), StrTemplate(NStr("vi = 'quý 4 %1';
																|ru = '4 квартал %1';
																|en = 'Quarter 4 %1'; fa = 'Quarter 4 %1';
																|it = 'IV trimestre %1';
																|pl = '4 kwartał %1';
																|tr = '4 çeyrek %1'"), Format(Cnt, "NG=0")));
		EndDo;
		PeriodsList.Add(Date(CurrentYear + 1, 1, 1), Format(CurrentYear + 1, "NG=0") + "...");
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Month") Then
		CurrentYear = Year(StartOfPeriodValue);
		PeriodsList.Add(Date(CurrentYear - 1, 1, 1), Format(CurrentYear - 1, "NG=0") + "...");

		For Cnt = 1 To 12 Do
			PeriodsList.Add(Date(CurrentYear, Cnt, 1), Format(Date(CurrentYear, Cnt, 1), "DF='MMMM yyyy'"));
		EndDo;
		PeriodsList.Add(Date(CurrentYear + 1, 1, 1), Format(CurrentYear + 1, "NG=0") + "...");

	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.TenDays") Then
		CurrentYear   = Year(StartOfPeriodValue);
		CurrentMonth = Month(StartOfPeriodValue);
		
		CountMonth = ?(CurrentMonth - 4 < 1, 12 + CurrentMonth - 4, CurrentMonth - 4);
		CountYear   = ?(CurrentMonth - 4 < 1, CurrentYear - 1       , CurrentYear);
		Cnt = 6;
		
		Period = Date(?(CountMonth <> 1, CountYear, CountYear - 1), ?(CountMonth > 1, CountMonth - 1, 12), 1);
		PeriodsList.Add(Period, Format(Period, "DF='MMMM yyyy'") + "...");
		While Cnt >0 Do
			PeriodsList.Add(Date(CountYear, CountMonth, 1),  StrTemplate(NStr("vi = 'Mười ngày I %1';
																				|ru = 'I дек. %1';
																				|en = 'Ten-day period 1, %1'; fa = 'Ten-day period 1, %1';
																				|it = 'I decade. %1';
																				|pl = 'I dek. %1';
																				|tr = 'I 10 günlük süre. %1'"), Lower(Format(Date(CountYear, CountMonth, 1), "DF='MMMM yyyy'"))));
			PeriodsList.Add(Date(CountYear, CountMonth, 11), StrTemplate(NStr("vi = 'Mười ngày II %1';
																				|ru = 'II дек. %1';
																				|en = 'Ten-day period 2, %1'; fa = 'Ten-day period 2, %1';
																				|it = 'II decade %1';
																				|pl = 'II dek. %1';
																				|tr = 'II 10 günlük süre. %1'"), Lower(Format(Date(CountYear, CountMonth, 1), "DF='MMMM yyyy'"))));
			PeriodsList.Add(Date(CountYear, CountMonth, 21), StrTemplate(NStr("vi = 'Ba mươi ngày %1';
																				|ru = 'III дек. %1';
																				|en = 'Ten-day period 3, %1'; fa = 'Ten-day period 3, %1';
																				|it = 'III decade %1';
																				|pl = 'III dek. %1';
																				|tr = 'III 10 günlük süre. %1'"), Lower(Format(Date(CountYear, CountMonth, 1), "DF='MMMM yyyy'"))));
			CountMonth = CountMonth + 1;
			If CountMonth > 12 Then
				CountYear = CountYear + 1;
				CountMonth = 1;
			EndIf;
			Cnt = Cnt - 1;
		EndDo;
		PeriodsList.Add(Date(CountYear, CountMonth, 1), Format(Date(CountYear, CountMonth, 1), "DF='MMMM yyyy'") + "...");
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Week") Then
		BegOfWeek = BegOfWeek(StartOfPeriodValue) - 21 * 86400;
		
		PeriodsList.Add(BegOfWeek - 7 * 86400, NStr("vi = 'Tuần trước ...';
													|ru = 'Пред. недели ...';
													|en = 'Previous weeks ...'; fa = 'Previous weeks ...';
													|it = 'Settimana precedente...';
													|pl = 'Poprzednie tygodnie ...';
													|tr = 'Önceki. haftalar ...'"));
		For Cnt = 0 To 6 Do
			BeginningOfWeek = BegOfWeek + 7 * Cnt * 86400;  
			NdOfWeek = EndOfWeek(BeginningOfWeek);
			PeriodsList.Add(BeginningOfWeek, Format(BeginningOfWeek, "DF=dd.MM") + " - " + Format(NdOfWeek, "DF=dd.MM"));
		EndDo;
		PeriodsList.Add(BegOfWeek + 7 * 86400, NStr("vi = 'Tuần sau ...';
													|ru = 'След. недели ...';
													|en = 'Next weeks ...'; fa = 'Next weeks ...';
													|it = 'Settimana successiva ...';
													|pl = 'Następne tygodnie ...';
													|tr = 'Sonraki. haftalar ...'"));
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Day") Then
		EndOfWeek   = EndOfWeek(StartOfPeriodValue);
		DayOfWeekDate = BegOfWeek(StartOfPeriodValue);
		
		PeriodsList.Add(DayOfWeekDate - 86400, NStr("vi = 'Tuần trước';
													|ru = 'Предыдущая неделя';
													|en = 'Previous week'; fa = 'Previous week';
													|it = 'Settimana precedente';
													|pl = 'Poprzedni tydzień';
													|tr = 'Önceki hafta'"));
		
		While DayOfWeekDate < EndOfWeek Do
			DayNed = WeekDay(DayOfWeekDate);
			
			PeriodsList.Add(DayOfWeekDate, Format(DayOfWeekDate, "DF='dd MMMM yyyy (ddd)'"));
			
			DayOfWeekDate = DayOfWeekDate + 86400;
		EndDo;
		
		PeriodsList.Add(EndOfWeek + 1, NStr("vi = 'Tuần sau';
											|ru = 'Следующая неделя';
											|en = 'Next week'; fa = 'هفته بعد';
											|it = 'Settimana successiva';
											|pl = 'Następny tydzień';
											|tr = 'Sonraki hafta'"));
	EndIf;
		
	Return PeriodsList;
	
EndFunction

// Returns the type of period for the transmitted start and end dates of this period.
// 
// Parameters:
// 	BeginOfPeriod - Date - start date of the period.
//  EndOfPeriod  - Date - end date of the period.
//	MinimumPeriodType - EnumRef.AvailableReportPeriods - The smallest available type of period.
// 
// Returns:
//   EnumRef.AvailableReportPeriods - Type of period.
// 
Function GetPeriodView(Val BeginOfPeriod, Val EndOfPeriod, Val MinimumPeriodType = Undefined) Export
	
	PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Custom");
	If ValueIsFilled(BeginOfPeriod) And ValueIsFilled(EndOfPeriod) Then
		Begin = BegOfDay(BeginOfPeriod);
		End  = EndOfDay(EndOfPeriod);
		If Begin = BegOfDay(BeginOfPeriod) And End = EndOfDay(BeginOfPeriod) Then
			PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Day");
		ElsIf Begin = BegOfWeek(BeginOfPeriod) And End = EndOfWeek(BeginOfPeriod) Then
			PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Week");
		ElsIf Begin = BegOfMonth(BeginOfPeriod) And End = EndOfMonth(BeginOfPeriod) Then
			PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Month");
		ElsIf Begin = BegOfQuarter(BeginOfPeriod) And End = EndOfQuarter(BeginOfPeriod) Then
			PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Quarter");
		ElsIf Begin = BegOfYear(BeginOfPeriod) And End = EndOfYear(BeginOfPeriod) Then
			PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Year");
		ElsIf Begin = Date(Year(BeginOfPeriod), 1, 1) And End = Date(Year(BeginOfPeriod), 6, 30, 23, 59, 59)
			Or Begin = Date(Year(BeginOfPeriod), 7, 1) And End = Date(Year(BeginOfPeriod), 12, 31, 23, 59, 59) Then
			PeriodType = PredefinedValue("Enum.AvailableReportPeriods.HalfYear");
		ElsIf Begin = Date(Year(BeginOfPeriod), Month(BeginOfPeriod), 1) 
			And End = Date(Year(BeginOfPeriod), Month(BeginOfPeriod), 10, 23, 59, 59)
			Or Begin = Date(Year(BeginOfPeriod), Month(BeginOfPeriod), 11) 
			And End = Date(Year(BeginOfPeriod), Month(BeginOfPeriod), 20, 23, 59, 59)
			Or Begin = Date(Year(BeginOfPeriod), Month(BeginOfPeriod), 1) 
			And End = EndOfMonth(BeginOfPeriod)	Then
			PeriodType = PredefinedValue("Enum.AvailableReportPeriods.TenDays");
		EndIf;
	EndIf;
	
	If ValueIsFilled(MinimumPeriodType) Then
		ListOfAvailablePeriods = GetListOfAvailablePeriods();
		
		PositionTypeOfPeriod            = ListOfAvailablePeriods.IndexOf(ListOfAvailablePeriods.FindByValue(PeriodType));
		PositionMinimumTypeOfPeriod = ListOfAvailablePeriods.IndexOf(ListOfAvailablePeriods.FindByValue(MinimumPeriodType));
		
		If PositionTypeOfPeriod < PositionMinimumTypeOfPeriod Then
			PeriodType = MinimumPeriodType;
		EndIf;
	EndIf;
	
	Return PeriodType;
	
EndFunction

// Returns a representation of the period.
// 
// Parameters:
//   PeriodType    - EnumRef.AvailableReportPeriods - Type of period.
//   BeginOfPeriod - Date - start date of the period.
//   EndOfPeriod  - Date - end date of the period.
// 
// Returns:
//   String - Text representation of the period.
// 
Function GetPresentationOfReportPeriod(PeriodType, Val BeginOfPeriod, Val EndOfPeriod) Export
	
	If PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Custom") Then	
		If Not ValueIsFilled(BeginOfPeriod) And Not ValueIsFilled(EndOfPeriod) Then
			Return "";
		Else
			Return Format(BeginOfPeriod, "DF=MM/dd/yy") + " - " + Format(EndOfPeriod, "DF=MM/dd/yy");
		EndIf;
	Else
		EstimatedPeriodType = GetPeriodView(BeginOfPeriod, EndOfPeriod);
		If EstimatedPeriodType <> PeriodType And ValueIsFilled(BeginOfPeriod) Then
			PeriodType = EstimatedPeriodType;
		EndIf;
		
		List = GetListOfPeriods(BeginOfPeriod, PeriodType);
		
		ListItem = List.FindByValue(BeginOfPeriod);
		If ListItem <> Undefined Then
			Return ListItem.Presentation;
		Else
			Return "";
		EndIf;
	EndIf;
	
	Return "";
	
EndFunction

// Selects the report period by the type of period and current report dates.
//
// Parameters:
//	PeriodType    - EnumRef.AvailableReportPeriods - Type of period.
//	Text         - String - Text description of the period.
//	StartDate    - Date - start date of the period.
//	EndDate - Date - end date of the period.
//
// Returns:
//	ValueList of Date
//
Function SelectReportPeriod_(PeriodType, Text, StartDate, EndDate) Export
	
	DataToSelect = New ValueList;
	
	WordArray = GetArrayOfWordsRepresentingReportPeriod(Text);
	
	GetPeriodValue(PeriodType, WordArray, DataToSelect);
	
	Return DataToSelect;
	
EndFunction

#EndRegion

#Region Private

Procedure GetPeriodValue(PeriodType, WordArray, DataToSelect)

	DateToday = CurrentDate(); // The session date is not used.

	Day  = Day(DateToday);
	Month = Month(DateToday);
	Year   = Year(DateToday);
	
	If PredefinedValue("Enum.AvailableReportPeriods.Day") = PeriodType Then
		If WordArray.Count() > 0 Then                 
			If ContainsCharacters(WordArray[0], "1234567890") Then
				Day = Number(WordArray[0]);
			EndIf;
		EndIf;
		
		If WordArray.Count() > 1 Then
			MonthNumber = GetMonth(WordArray[1]);
			If MonthNumber <> Undefined Then
				Month = MonthNumber;
			EndIf;
		EndIf;
		
		If WordArray.Count() > 2 Then
			If ContainsCharacters(WordArray[2], "1234567890") Then
				Year = GetYear(WordArray[2], DateToday);
			EndIf;
		EndIf;
		
		Try
			DateToSelect = Date(Year, Month, Day);
		Except
			Return;
		EndTry;
		
		DataToSelect.Add(DateToSelect, Format(DateToSelect, "DF='dd MMMM yyyy'"))
		
	ElsIf PredefinedValue("Enum.AvailableReportPeriods.Week") = PeriodType Then
	// The Week period is not processed.
	ElsIf PredefinedValue("Enum.AvailableReportPeriods.TenDays") = PeriodType Then
		If Day <= 10 Then
			DecadeNumber = 1;
		ElsIf Day >= 11 And Day <= 20 Then
			DecadeNumber = 2;
		ElsIf Day >= 21 Then
			DecadeNumber = 3;
		EndIf;
		
		If WordArray.Count() > 0 Then
			If ContainsCharacters(WordArray[0], "123") Then
				DecadeNumber = Number(WordArray[0]);
			Else
				Return;
			EndIf;
		EndIf;
		
		If WordArray.Count() > 1 Then
			If StrFind(WordArray[1], "dec") = 0  Then
				Return;
			EndIf;
		EndIf;
		
		
		If WordArray.Count() > 2 Then
			MonthNumber = GetMonth(WordArray[2]);
			If MonthNumber <> Undefined Then
				Month = MonthNumber;
			EndIf;
		EndIf;
		
		If WordArray.Count() > 3 Then
			If ContainsCharacters(WordArray[3], "1234567890") Then 
				Year = GetYear(WordArray[3], DateToday);
			EndIf;
		EndIf;
		
		Try 
			BeginningOfDecade = Date(Year, Month, (DecadeNumber - 1) * 10 + 1);
			EndOfDecade  = EndOfReportPeriod(PeriodType, BeginningOfDecade);
		Except
			Return;
		EndTry;
		
		DataToSelect.Add(BeginningOfDecade, GetPresentationOfReportPeriod(PeriodType, BeginningOfDecade, EndOfDecade))
		
	ElsIf PredefinedValue("Enum.AvailableReportPeriods.Month") = PeriodType Then
		Day = 1;

		If WordArray.Count() > 0 Then
			MonthNumber = GetMonth(WordArray[0]);
			If MonthNumber <> Undefined Then
				Month = MonthNumber;
			EndIf;
		EndIf;
		
		If WordArray.Count() > 1 Then
			If ContainsCharacters(WordArray[1], "1234567890") Then 
				Year = GetYear(WordArray[1], DateToday);
			EndIf;
		EndIf;
		
		Try
			BegOfMonth = Date(Year, Month, Day);
			EndOfMonth  = EndOfReportPeriod(PeriodType, BegOfMonth);
		Except
			Return;
		EndTry;
		
		DataToSelect.Add(BegOfMonth, GetPresentationOfReportPeriod(PeriodType, BegOfMonth, EndOfMonth))
		
	ElsIf PredefinedValue("Enum.AvailableReportPeriods.Quarter") = PeriodType Then
		QuarterNumber = 1;
		If Month <= 3 Then
			QuarterNumber = 1;
		ElsIf Month >= 4 And Month <= 6 Then
			QuarterNumber = 2;
		ElsIf Month >= 7 And Month <= 9 Then
			QuarterNumber = 3;
		ElsIf Month >= 10 Then
			QuarterNumber = 4;
		EndIf;
		
		If WordArray.Count() > 0 Then
			If ContainsCharacters(WordArray[0], "1234") Then
				QuarterNumber = Number(WordArray[0]);
			Else
				Return;
			EndIf;
		EndIf;
		
		If WordArray.Count() > 1 Then
			If StrFind(WordArray[1], "kv") = 0  Then
				Return;
			EndIf;
		EndIf;

		If WordArray.Count() > 2 Then
			If ContainsCharacters(WordArray[2], "1234567890") Then 
				Year = GetYear(WordArray[2], DateToday);
			EndIf;
		EndIf;
		
		Try 
			BegOfQuarter = BegOfQuarter(Date(Year, (QuarterNumber - 1) * 3 + 1, 1));
			EndOfQuarter  = EndOfReportPeriod(PeriodType, BegOfQuarter);
		Except
			Return;
		EndTry;
	
		DataToSelect.Add(BegOfQuarter, GetPresentationOfReportPeriod(PeriodType, BegOfQuarter, EndOfQuarter))

	ElsIf PredefinedValue("Enum.AvailableReportPeriods.HalfYear") = PeriodType Then
		HalfYearNumber = 1;
		If Month <= 6 Then
			HalfYearNumber = 1;
		Else
			HalfYearNumber = 2;
		EndIf;
		
		If WordArray.Count() > 0 Then
			If ContainsCharacters(WordArray[0], "12") Then
				HalfYearNumber = Number(WordArray[0]);
			Else
				Return;
			EndIf;
		EndIf;
		
		If WordArray.Count() > 1 Then
			If StrFind(WordArray[1], "gender") = 0  Then
				Return;
			EndIf;
		EndIf;

		If WordArray.Count() > 2 Then
			If ContainsCharacters(WordArray[2], "1234567890") Then
				Year = GetYear(WordArray[2], DateToday);
			EndIf;
		EndIf;
		
		Try 
			BeginningOfHalfYear = BegOfQuarter(Date(Year, (HalfYearNumber - 1) * 6 + 1, 1));
			EndOfHalfYear  = EndOfReportPeriod(PeriodType, BeginningOfHalfYear);
		Except
			Return;
		EndTry;
		
		DataToSelect.Add(BeginningOfHalfYear, GetPresentationOfReportPeriod(PeriodType, BeginningOfHalfYear, EndOfHalfYear))
		
	ElsIf PredefinedValue("Enum.AvailableReportPeriods.Year") = PeriodType Then
		For Each Word In WordArray Do
			If ContainsCharacters(Word, "1234567890") Then 
				Year = GetYear(Word, DateToday);
				BegOfYear = Date(Year, 1, 1);
				EndOfYear  = Date(Year, 12, 31, 23, 59, 59);
				DataToSelect.Add(BegOfYear, GetPresentationOfReportPeriod(PeriodType, BegOfYear, EndOfYear))
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Function GetMonth(MonthPresentationRow)
	
	ListOfMonths = New ValueList;
	ListOfMonths.Add(1, "jan");
	ListOfMonths.Add(2, "feb");
	ListOfMonths.Add(3, "mar");
	ListOfMonths.Add(4, "apr");
	ListOfMonths.Add(5, "may");
	ListOfMonths.Add(6, "jun");
	ListOfMonths.Add(7, "jul");
	ListOfMonths.Add(8, "aug");
	ListOfMonths.Add(9, "sen");
	ListOfMonths.Add(10, "oct");
	ListOfMonths.Add(11, "nov");
	ListOfMonths.Add(12, "dec");
	
	Month = Undefined;
	
	If ContainsCharacters(MonthPresentationRow, "1234567890") Then
		Month = Number(MonthPresentationRow);
	Else
		For Each ListItem In ListOfMonths Do
			If StrFind(MonthPresentationRow, ListItem.Presentation) > 0 Then
				Month = ListItem.Value;
			EndIf;
		EndDo;
	EndIf;
	Return Month;
	
EndFunction

Function GetYear(YearRepresentationString, DateToday)
	
	If ContainsCharacters(YearRepresentationString, "1234567890") Then 
		Year = Number(YearRepresentationString);
		If Year < 10 Then // One sign.
			CurYear = Year(DateToday);
			Year = Int(CurYear / 10) * 10 + Year;
		ElsIf Year >= 10 And Year < 100  Then // Two signs.
			CurYear             = Year(DateToday);
			CurCentury        = Int(CurYear / 100) * 100;
			PreviousCentury = CurCentury - 100;
			UpperBoundaryOfCurCentury = CurYear - CurCentury + 20;
			If Year >= 0 And UpperBoundaryOfCurCentury >= Year Then
				Year = Year + CurCentury;
			Else
				Year = Year + PreviousCentury;
			EndIf;
		EndIf;
		Try 
			BegOfYear = Date(Year, 1, 1);
			Return Year(BegOfYear);
		Except
			Return Year(DateToday);
		EndTry;
	EndIf;
	
	Return Year(DateToday);
	
EndFunction 


Function ContainsCharacters(LineForVerification, CharacterString)
	
	ContainOnlySubstring = True;
	
	ValidationSymbols = New ValueList;
	
	For Cnt = 1 To StrLen(CharacterString) Do
		ValidationSymbols.Add(CharCode(CharacterString, Cnt));
	EndDo;
	
	For Cnt = 1 To StrLen(LineForVerification) Do
		If ValidationSymbols.FindByValue(CharCode(LineForVerification, Cnt)) = Undefined Then
			ContainOnlySubstring = False;
			Break;
		EndIf;
	EndDo;
	
	Return ContainOnlySubstring;
	
EndFunction

Function GetListOfAvailablePeriods()
	
	ListOfAvailablePeriods = New ValueList;
	ListOfAvailablePeriods.Add(PredefinedValue("Enum.AvailableReportPeriods.Day"));
	ListOfAvailablePeriods.Add(PredefinedValue("Enum.AvailableReportPeriods.Month"));
	ListOfAvailablePeriods.Add(PredefinedValue("Enum.AvailableReportPeriods.Quarter"));
	ListOfAvailablePeriods.Add(PredefinedValue("Enum.AvailableReportPeriods.HalfYear"));
	ListOfAvailablePeriods.Add(PredefinedValue("Enum.AvailableReportPeriods.Year"));
	ListOfAvailablePeriods.Add(PredefinedValue("Enum.AvailableReportPeriods.Custom"));
	
	Return ListOfAvailablePeriods;
	
EndFunction

// The lines that specify the report period are extracted from the passed text.
//
// Parameters:
//  Text        - text containing data from the report period.
//
// Returns:
//   Array      - lines specifying the report period.
//
Function GetArrayOfWordsRepresentingReportPeriod(Text)
	
	WordArray = New Array;
	SearchText_ = Lower(TrimAll(Text));
	SeparatorPosition = 1;
	While SearchText_ <> "" Do
		Word = "";
		SeparatorPosition = 0;
		If StrFind(SearchText_, " ") > 0 Then
			 SeparatorPosition = ?(SeparatorPosition > 0, Min(SeparatorPosition, StrFind(SearchText_, " ")), StrFind(SearchText_, " "));
		EndIf;
		If StrFind(SearchText_, ".") > 0 Then
			 SeparatorPosition = ?(SeparatorPosition > 0, Min(SeparatorPosition, StrFind(SearchText_, ".")), StrFind(SearchText_, "."));
		EndIf;
		If StrFind(SearchText_, "/") > 0 Then
			 SeparatorPosition = ?(SeparatorPosition > 0, Min(SeparatorPosition, StrFind(SearchText_, "/")), StrFind(SearchText_, "/"));
		EndIf;
		If StrFind(SearchText_, "\") > 0 Then
			 SeparatorPosition = ?(SeparatorPosition > 0, Min(SeparatorPosition, StrFind(SearchText_, "\")), StrFind(SearchText_, "\"));
		EndIf;
		
		If SeparatorPosition = 0 Then
			Word = TrimAll(SearchText_);
			SearchText_ = "";
		Else
			Word = TrimAll(Mid(SearchText_, 1, SeparatorPosition-1));
		EndIf;
		
		If Word <> " " And Word <> "." And Word <> "/" And Word <> "\" And Word <> "" Then
			WordArray.Add(Word);
		EndIf;

		SearchText_ = TrimAll(Right(SearchText_, StrLen(SearchText_) - SeparatorPosition));
	EndDo;
	
	Return WordArray;
	
EndFunction

#EndRegion
