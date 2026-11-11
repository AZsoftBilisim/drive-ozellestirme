
#Region Internal

// The function returns the value of the user selection set in the report.
// 
// Parameters:
// 	SettingsComposer - DataCompositionSettingsComposer - 
// 	FieldName - String - 
// 	ArrayOfComparisonOperations - Undefined, Array of DataCompositionComparisonType -
// 	OnlyIfUsed - Boolean -
// Returns:
// 	Arbitrary -
Function GetSelectionValue(SettingsComposer, FieldName, ArrayOfComparisonOperations = Undefined, OnlyIfUsed = False) Export
	Value = Undefined;
	FilterField = New DataCompositionField(FieldName);
	ForAllOperations = ?(ValueIsFilled(ArrayOfComparisonOperations), False, True);
	For Each Field In SettingsComposer.Settings.Filter.Items Do
		If TypeOf(Field) <> Type("DataCompositionFilterItem") Then
			Continue;
		EndIf;
		If Field.LeftValue = FilterField And (Not OnlyIfUsed Or Field.Use) Then
			If Not ValueIsFilled(Field.UserSettingID) And Field.Use Then
				Value = Field.RightValue;
			ElsIf ForAllOperations Then
				ValueField = FindCustomSetting(SettingsComposer.UserSettings, Field.UserSettingID);
				Value = ValueField.RightValue;
			Else
				For Each ComparisonOperation_ In ArrayOfComparisonOperations Do
					If Field.ComparisonType = ComparisonOperation_ Then
						ValueField = FindCustomSetting(SettingsComposer.UserSettings, Field.UserSettingID);
						If ValueField <> Undefined And ValueField.Use Then
							Value = ValueField.RightValue;
						EndIf;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	Return Value;
EndFunction

// Returns the end of the report period. It is used in methods
// for updating offline registers and serves as the end date of calculation.
// 
//Parameters:
//	SettingsComposer - DataCompositionSettingsComposer - Report settings Builder
//	FieldName - String - Name of the field in the parameters that is responsible for the report period.
// Returns:
//	Date - calculation boundary.
Function CalculationBoundary(SettingsComposer, FieldName) Export
	ReportPeriodParameter = DataCompositionClientServer.GetParameter(SettingsComposer, FieldName);
	If TypeOf(ReportPeriodParameter.Value) = Type("StandardPeriod") Then
		StandardReportPeriod = ReportPeriodParameter.Value; // StandardPeriod - 
		CalculationBoundary = ?(ReportPeriodParameter.Use,
				StandardReportPeriod.EndDate, GeneralPurposeTMServerCall.SessionDate());
	Else
		CalculationBoundary = ?(ReportPeriodParameter.Use,
				ReportPeriodParameter.Value, GeneralPurposeTMServerCall.SessionDate());
	EndIf;
	Return EndOfMonth(CalculationBoundary) + 1;
EndFunction

// Returns the name of the background task to run the report.
//
// Parameters:
//	Form - ClientApplicationForm - report form.
//
// Returns:
//	String - name of the background task.
//
Function GetNameOfReportExecutionTask(Form) Export
	
	JobDescription = NStr("vi = 'Thực hiện báo cáo: %1';
							|ru = 'Выполнение отчета: %1';
							|en = 'Running report: %1'; fa = 'Running report: %1';
							|it = 'Esecuzione del report: %1';
							|pl = 'Wykonanie raportu: %1';
							|tr = 'Raporun yürütülmesi: %1'");
	
	ReportName = "";
	FormNameElements = StrSplit(Form.FormName, ".");
	If FormNameElements.Count() > 1 And FormNameElements[0] = "Report" Then
		ReportName = FormNameElements[1];
	EndIf;
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(JobDescription, ReportName);
	
	Return JobDescription;
	
EndFunction

// Returns a string with a period representation.
//
// Parameters:
//	BeginOfPeriod - Date - the beginning of the period.
//	EndOfPeriod - Date - end of period.
//	DatesOnly - Boolean - If False, the returned string includes the preposition "for".
//	LanguageCode - String - Used for formatting dates.
//
// Returns:
//  String - The text of the period representation.
//
Function GetPeriodPresentation(BeginOfPeriod = '00010101', EndOfPeriod = '00010101', DatesOnly  = False, LanguageCode = "") Export
	
	TextPeriod = "";
	
	FormatString = ?(ValueIsFilled(LanguageCode), "L="+LanguageCode+";", "") + "FP = True";
	
	If ValueIsFilled(EndOfPeriod) Then 
		If EndOfPeriod >= BeginOfPeriod Then
			TextPeriod = ?(DatesOnly, "", " " + NStr("vi = 'trong';
													|ru = 'за';
													|en = 'for'; fa = 'برای';
													|it = 'per';
													|pl = 'za';
													|tr = 'için'")+ " ") 
				+ PeriodPresentation(BegOfDay(BeginOfPeriod), EndOfDay(EndOfPeriod), FormatString);
		Else
			TextPeriod = "";
		EndIf;
	ElsIf ValueIsFilled(BeginOfPeriod) And Not ValueIsFilled(EndOfPeriod) Then
		TextPeriod = ?(DatesOnly, "", " " + NStr("vi = 'trong';
												|ru = 'за';
												|en = 'for'; fa = 'برای';
												|it = 'per';
												|pl = 'za';
												|tr = 'için'")+ " ") 
			+ PeriodPresentation(BegOfDay(BeginOfPeriod), EndOfDay(Date(3999, 11, 11)), FormatString);
		TextPeriod = StrReplace(TextPeriod, Mid(TextPeriod, StrFind(TextPeriod, " - ")), " - ...");
	EndIf;
	
	Return TextPeriod;
	
EndFunction


// Finds a custom setting by its ID.
//
// Parameters:
//   DCUserSettings - DataCompositionUserSettings - collection of user settings.
//   Id - String - ID of the setting to find.
//
// Returns:
//   Undefined - When the setting is not found.
//   Data Collection items, values of parameter settings,
//     and other types of elements from the collection of elements of user-defined settings, user-defined settings.
//
Function FindCustomSetting(DCUserSettings, Id) Export
	For Each UserSetting In DCUserSettings.Items Do
		If UserSetting.UserSettingID = Id Then
			Return UserSetting;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

// Returns the type of period. Unlike the get period Function, it accepts a standard Period as input.
//
// Parameters:
//    StandardPeriod - StandardPeriod - Standard period
//    AvailablePeriods - Array of EnumRef.AvailableReportPeriods
//
// Returns:
//    EnumRef.AvailableReportPeriods - Type of period
//
Function GetStandardPeriodView(StandardPeriod, AvailablePeriods = Undefined) Export
	
	If StandardPeriod.Variant = StandardPeriodVariant.Custom Then
		
		Return GetPeriodView(StandardPeriod.StartDate, StandardPeriod.EndDate, AvailablePeriods);
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.ThisYear
		Or StandardPeriod.Variant = StandardPeriodVariant.LastYear
		Or StandardPeriod.Variant = StandardPeriodVariant.NextYear
		Or StandardPeriod.Variant = StandardPeriodVariant.FromBeginningOfThisYear
		Or StandardPeriod.Variant = StandardPeriodVariant.TillEndOfThisYear
		Or StandardPeriod.Variant = StandardPeriodVariant.LastYearTillSameDate
		Or StandardPeriod.Variant = StandardPeriodVariant.NextYearTillSameDate Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.Year");
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.ThisHalfYear
		Or StandardPeriod.Variant = StandardPeriodVariant.LastHalfYear
		Or StandardPeriod.Variant = StandardPeriodVariant.NextHalfYear
		Or StandardPeriod.Variant = StandardPeriodVariant.FromBeginningOfThisHalfYear
		Or StandardPeriod.Variant = StandardPeriodVariant.TillEndOfThisHalfYear
		Or StandardPeriod.Variant = StandardPeriodVariant.LastHalfYearTillSameDate
		Or StandardPeriod.Variant = StandardPeriodVariant.NextHalfYearTillSameDate Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.HalfYear");
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.ThisQuarter
		Or StandardPeriod.Variant = StandardPeriodVariant.LastQuarter
		Or StandardPeriod.Variant = StandardPeriodVariant.NextQuarter
		Or StandardPeriod.Variant = StandardPeriodVariant.FromBeginningOfThisQuarter
		Or StandardPeriod.Variant = StandardPeriodVariant.TillEndOfThisQuarter
		Or StandardPeriod.Variant = StandardPeriodVariant.LastQuarterTillSameDate
		Or StandardPeriod.Variant = StandardPeriodVariant.NextQuarterTillSameDate Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.Quarter");
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.ThisMonth
		Or StandardPeriod.Variant = StandardPeriodVariant.LastMonth
		Or StandardPeriod.Variant = StandardPeriodVariant.NextMonth
		Or StandardPeriod.Variant = StandardPeriodVariant.Month
		Or StandardPeriod.Variant = StandardPeriodVariant.FromBeginningOfThisMonth
		Or StandardPeriod.Variant = StandardPeriodVariant.TillEndOfThisMonth
		Or StandardPeriod.Variant = StandardPeriodVariant.LastMonthTillSameDate
		Or StandardPeriod.Variant = StandardPeriodVariant.NextMonthTillSameDate Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.Month");
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.ThisTenDays
		Or StandardPeriod.Variant = StandardPeriodVariant.LastTenDays
		Or StandardPeriod.Variant = StandardPeriodVariant.NextTenDays
		Or StandardPeriod.Variant = StandardPeriodVariant.FromBeginningOfThisTenDays
		Or StandardPeriod.Variant = StandardPeriodVariant.TillEndOfThisTenDays
		Or StandardPeriod.Variant = StandardPeriodVariant.LastTenDaysTillSameDayNumber
		Or StandardPeriod.Variant = StandardPeriodVariant.NextTenDaysTillSameDayNumber Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.TenDays");
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.ThisWeek
		Or StandardPeriod.Variant = StandardPeriodVariant.LastWeek
		Or StandardPeriod.Variant = StandardPeriodVariant.NextWeek
		Or StandardPeriod.Variant = StandardPeriodVariant.FromBeginningOfThisWeek
		Or StandardPeriod.Variant = StandardPeriodVariant.TillEndOfThisWeek
		Or StandardPeriod.Variant = StandardPeriodVariant.Last7Days
		Or StandardPeriod.Variant = StandardPeriodVariant.Next7Days
		Or StandardPeriod.Variant = StandardPeriodVariant.LastWeekTillSameWeekDay
		Or StandardPeriod.Variant = StandardPeriodVariant.NextWeekTillSameWeekDay Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.Week");
		
	ElsIf StandardPeriod.Variant = StandardPeriodVariant.Today
		Or StandardPeriod.Variant = StandardPeriodVariant.Yesterday
		Or StandardPeriod.Variant = StandardPeriodVariant.Tomorrow Then
		
		Return PredefinedValue("Enum.AvailableReportPeriods.Day");
		
	EndIf;
	
EndFunction

// Returns the type of period.
//
// Parameters:
//    BeginOfPeriod - Date - start date of the period
//    EndOfPeriod - Date - period end date
//    AvailablePeriods - ValueList of EnumRef.AvailableReportPeriods
//
// Returns:
//    EnumRef.AvailableReportPeriods - Type of period
//
Function GetPeriodView(BeginOfPeriod, EndOfPeriod, AvailablePeriods = Undefined) Export
	
	PeriodType = Undefined;
	If BeginOfPeriod = BegOfDay(BeginOfPeriod)
		And EndOfPeriod = EndOfDay(EndOfPeriod) Then
		
		DifferenceOfDays = (EndOfPeriod - BeginOfPeriod + 1) / (60*60*24);
		If DifferenceOfDays = 1 Then
			
			PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Day");
			
		ElsIf DifferenceOfDays = 7 Then
			
			If BeginOfPeriod = BegOfWeek(BeginOfPeriod) Then
				PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Week");
			EndIf;
			
		ElsIf DifferenceOfDays <= 11 Then
			
			If (Day(BeginOfPeriod) = 1 And Day(EndOfPeriod) = 10)
				Or (Day(BeginOfPeriod) = 11 And Day(EndOfPeriod) = 20)
				Or (Day(BeginOfPeriod) = 21 And EndOfPeriod = EndOfMonth(BeginOfPeriod)) Then
				PeriodType = PredefinedValue("Enum.AvailableReportPeriods.TenDays");
			EndIf;
			
		ElsIf DifferenceOfDays <= 31 Then
			
			If BeginOfPeriod = BegOfMonth(BeginOfPeriod) And EndOfPeriod = EndOfMonth(BeginOfPeriod) Then
				PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Month");
			EndIf;
			
		ElsIf DifferenceOfDays <= 92 Then
			
			If BeginOfPeriod = BegOfQuarter(BeginOfPeriod) And EndOfPeriod = EndOfQuarter(BeginOfPeriod) Then
				PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Quarter");
			EndIf;
			
		ElsIf DifferenceOfDays <= 190 Then
			
			If Month(BeginOfPeriod) + 5 = Month(EndOfPeriod)
				And BeginOfPeriod = BegOfMonth(BeginOfPeriod)
				And EndOfPeriod = EndOfMonth(EndOfPeriod)
				And (BeginOfPeriod = BegOfYear(BeginOfPeriod) Or EndOfPeriod = EndOfYear(BeginOfPeriod)) Then
				PeriodType = PredefinedValue("Enum.AvailableReportPeriods.HalfYear");
			EndIf;
			
		ElsIf DifferenceOfDays <= 366 Then
			
			If BeginOfPeriod = BegOfYear(BeginOfPeriod) And EndOfPeriod = EndOfYear(BeginOfPeriod) Then
				PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Year");
			EndIf;
			
		EndIf;
	EndIf;
	
	If PeriodType = Undefined Then
		PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Custom");
	EndIf;
	
	If AvailablePeriods <> Undefined And AvailablePeriods.FindByValue(PeriodType) = Undefined Then
		PeriodType = AvailablePeriods[0].Value;
	EndIf;
	
	Return PeriodType;
	
EndFunction

// Adds the selected field from the layout data.
//
// Parameters:
//   Var_To - DataCompositionSettingsComposer, DataCompositionSettings, DataCompositionSelectedFields -
//       The collection to add the selected field to.
//   DCNameOrField - String, DataCompositionField - field name.
//   Title    - String - Optional. The representation of the field.
//
// Returns:
//   DataCompositionSelectedField - The added selected field.
//
Function AddSelectedField(Var_To, DCNameOrField, Title = "") Export
	
	If TypeOf(Var_To) = Type("DataCompositionSettingsComposer") Then
		SelectedDCFields = Var_To.Settings.Selection;
	ElsIf TypeOf(Var_To) = Type("DataCompositionSettings") Then
		SelectedDCFields = Var_To.Selection;
	Else
		SelectedDCFields = Var_To;
	EndIf;
	
	If TypeOf(DCNameOrField) = Type("String") Then
		DCField = New DataCompositionField(DCNameOrField);
	Else
		DCField = DCNameOrField;
	EndIf;
	
	SelectedDCField = SelectedDCFields.Items.Add(Type("DataCompositionSelectedField"));
	SelectedDCField.Field = DCField;
	If Title <> "" Then
		SelectedDCField.Title = Title;
	EndIf;
	
	Return SelectedDCField;
	
EndFunction

#EndRegion


