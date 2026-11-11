///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		FillWithCurrentYearData(Parameters.CopyingValue);
		SetBasicCalendarFieldProperties(ThisObject);
	EndIf;
	
	DaysKindsColors = New FixedMap(Catalogs.BusinessCalendars.BusinessCalendarDayKindsAppearanceColors());
	
	DayKindsList = Catalogs.BusinessCalendars.DayKindsList();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		ModuleStandaloneMode.ObjectOnReadAtServer(CurrentObject, ReadOnly);
	EndIf;
	
	FillWithCurrentYearData();
	
	HasBasicCalendar = ValueIsFilled(Object.BasicCalendar);
	SetBasicCalendarFieldProperties(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StartBasicCalendarVisibilitySetup();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	If Upper(ChoiceSource.FormName) = Upper("CommonForm.SelectDate") Then
		If ValueSelected = Undefined Then
			Return;
		EndIf;
		SelectedDates = Items.Calendar.SelectedDates;
		If SelectedDates.Count() = 0 Or Year(SelectedDates[0]) <> CurrentYearNumber Then
			Return;
		EndIf;
		ReplacementDate = SelectedDates[0];
		ShiftDayKind(ReplacementDate, ValueSelected);
		Items.Calendar.Refresh();
	EndIf;
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If HasBasicCalendar And Not ValueIsFilled(Object.BasicCalendar) Then
		MessageText = NStr("vi = 'Chưa điền lịch nhà nước.';
							|ru = 'Федеральный календарь не заполнен.';
							|en = 'The official calendar is blank.'; fa = 'The official calendar is blank.';
							|it = 'Calendario federale non compilato.';
							|pl = 'Nie wypełniono kalendarza federalnego.';
							|tr = 'Ulusal takvim doldurulmadı.'");
		Common.MessageToUser(MessageText, , , "Object.BasicCalendar", Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Var YearNumber;
	
	If Not WriteParameters.Property("YearNumber", YearNumber) Then
		YearNumber = CurrentYearNumber;
	EndIf;
	
	WriteBusinessCalendarData(YearNumber, CurrentObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CurrentYearNumberOnChange(Item)
	
	WriteScheduleData = False;
	If Modified Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Ghi lại dữ liệu đã thay đổi trong %1 năm?';
																					|ru = 'Записать измененные данные за %1 год?';
																					|en = 'Do you want to save the changes for year %1?'; fa = 'Do you want to save the changes for year %1?';
																					|it = 'Registrare i dati modificati per il %1 anno?';
																					|pl = 'Zapisać zmienione dane za %1 rok?';
																					|tr = '%1 yılı için değiştirilmiş veriler kaydedilsin mı?'"), Format(PreviousYearNumber, "NG=0"));
		Notification = New CallbackDescription("CurrentYearNumberOnChangeCompletion", ThisObject);
		ShowQueryBox(Notification, MessageText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	ProcessYearChange(WriteScheduleData);
	
	Modified = False;
	
	Items.Calendar.Refresh();
	
EndProcedure

&AtClient
Procedure CalendarOnPeriodOutput(Item, PeriodAppearance)
	
	For Each PeriodAppearanceString In PeriodAppearance.Dates Do
		DayAppearanceColor = DaysKindsColors.Get(DaysKinds.Get(PeriodAppearanceString.Date));
		If DayAppearanceColor = Undefined Then
			DayAppearanceColor = CommonClient.StyleColor("BusinessCalendarDayKindColorNotSpecified");
		EndIf;
		PeriodAppearanceString.TextColor = DayAppearanceColor;
		If NonWorkDates.Find(PeriodAppearanceString.Date) <> Undefined Then
			PeriodAppearanceString.BackColor = CommonClient.StyleColor("BusinessCalendarNonWorkPeriodBackground");
		EndIf; 
	EndDo;
	
EndProcedure

&AtClient
Procedure HasBasicCalendarOnChange(Item)
	
	SetBasicCalendarFieldProperties(ThisObject);
	
	If Not HasBasicCalendar Then
		Object.BasicCalendar = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure BasicCalendarOnChange(Item)
	ReadNonWorkDates();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeDay(Command)
	
	SelectedDates = Items.Calendar.SelectedDates;
	
	If SelectedDates.Count() > 0 And Year(SelectedDates[0]) = CurrentYearNumber Then
		Notification = New CallbackDescription("ChangeDayCompletion", ThisObject, SelectedDates);
		ShowChooseFromList(Notification, DayKindsList, , DayKindsList.FindByValue(DaysKinds.Get(SelectedDates[0])));
	EndIf;
	
EndProcedure

&AtClient
Procedure ShiftDay(Command)
	
	SelectedDates = Items.Calendar.SelectedDates;
	
	If SelectedDates.Count() = 0 Or Year(SelectedDates[0]) <> CurrentYearNumber Then
		Return;
	EndIf;
		
	ReplacementDate = SelectedDates[0];
	DayKind = DaysKinds.Get(ReplacementDate);
	
	DateSelectionParameters = New Structure(
		"InitialValue, 
		|BeginOfRepresentationPeriod, 
		|EndOfRepresentationPeriod, 
		|Title, 
		|NoteText");
		
	DateSelectionParameters.InitialValue = ReplacementDate;
	DateSelectionParameters.BeginOfRepresentationPeriod = BegOfYear(Calendar);
	DateSelectionParameters.EndOfRepresentationPeriod = EndOfYear(Calendar);
	DateSelectionParameters.Title = NStr("vi = 'Chọn ngày chuyển';
										|ru = 'Выбор даты переноса';
										|en = 'Select substitute date'; fa = 'Select substitute date';
										|it = 'Selezione della data di trasferimento';
										|pl = 'Wybór daty przeniesienia';
										|tr = 'Hedef tarihi seçin'");
	
	DateSelectionParameters.NoteText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chọn ngày mà sẽ chuyển ngày %1 (%2)';
			|ru = 'Выберите дату, на которую будет осуществлен перенос дня %1 (%2)';
			|en = 'Select a date that substitutes %1 (%2).'; fa = 'Select a date that substitutes %1 (%2).';
			|it = 'Selezionate la data alla quale verrà effettuato il trasferimento del giorno %1 (%2)';
			|pl = 'Wybierz datę, na którą zostanie dokonane przeniesienie dnia %1 (%2)';
			|tr = '%1 yerine geçecek tarihi seçin (%2)'"), 
		Format(ReplacementDate, "DF='d MMMM'"), // ACC:1367 Consider saving the order "date, month" appropriate in this case. So far, this is the optimal solution.
		DayKind);
	
	OpenForm("CommonForm.SelectDate", DateSelectionParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure FillByDefault(Command)
	
	FillWithDefaultData();
	
	Items.Calendar.Refresh();
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	If Object.Ref.IsEmpty() Then
		Handler = New CallbackDescription("PrintCompletion", ThisObject);
		ShowQueryBox(
			Handler,
			NStr("vi = 'Dữ liệu của lịch sản xuất vẫn chưa được ghi lại.
                  |Chỉ có thể in sau khi dữ liệu đã được ghi lại.
                  |
                  |Ghi lại?';
                  |ru = 'Данные производственного календаря еще не записаны.
                  |Печать возможна только после записи данных.
                  |
                  |Записать?';
                  |en = 'You have unsaved business calendar data.
                  |Before you print the calendar, please save the data.
                  |
                  |Do you want to save it?'; fa = 'You have unsaved business calendar data.
                  |Before you print the calendar, please save the data.
                  |
                  |Do you want to save it?';
                  |it = 'I dati del calendario produttivo non sono ancora stati registrati.
                  |La stampa è possibile solo dopo la registrazione dei dati.
                  |
                  |Registrarli?';
                  |pl = 'Dane kalendarza produkcyjnego nie zostały jeszcze zapisane.
                  |Drukowanie jest możliwe tylko po zapisaniu danych.
                  |
                  |Zapisać?';
                  |tr = 'İş takvimi verileri henüz kaydedilmedi.
                  |Sadece verileri kaydettikten sonra yazdırabilirsiniz.
                  |
                  |Kaydedilsin mi?'"),
			QuestionDialogMode.YesNo,
			,
			DialogReturnCode.Yes);
		Return;
	EndIf;
	
	PrintCompletion(-1);
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillWithCurrentYearData(CopyingValue = Undefined)
	
	// Fills in the form with data of the current year.
	
	SetCalendarField();
	
	RefToCalendar = Object.Ref;
	If ValueIsFilled(CopyingValue) Then
		RefToCalendar = CopyingValue;
		Object.Description = Undefined;
		Object.Code = Undefined;
	EndIf;
	
	ReadBusinessCalendarData(RefToCalendar, CurrentYearNumber);
	ReadNonWorkDates();
	
EndProcedure

&AtServer
Procedure ReadBusinessCalendarData(BusinessCalendar, YearNumber)
	
	// Import business calendar data for the given year.
	ConvertBusinessCalendarData(
		Catalogs.BusinessCalendars.BusinessCalendarData(BusinessCalendar, YearNumber));
	
EndProcedure

&AtServer
Procedure FillWithDefaultData()
	
	// Populates the form with the business calendar data 
	// (considering holidays and substitutes).
	
	BasicCalendarCode = Undefined;
	If ValueIsFilled(Object.BasicCalendar) Then
		BasicCalendarCode = Common.ObjectAttributeValue(Object.BasicCalendar, "Code");
	EndIf;
	
	DefaultData = Catalogs.BusinessCalendars.BusinessCalendarDefaultFillingResult(
		Object.Code, CurrentYearNumber, BasicCalendarCode);
		
	ConvertBusinessCalendarData(DefaultData);

	Modified = True;
	
EndProcedure

&AtServer
Procedure ConvertBusinessCalendarData(BusinessCalendarData)
	
	// Business calendar data is used on the form in the maps "DaysKinds" and "ShiftedDays". 
	// This procedure populates these maps.
	// 
	
	DaysKindsMap = New Map;
	ShiftedDaysMap = New Map;
	
	For Each TableRow In BusinessCalendarData Do
		DaysKindsMap.Insert(TableRow.Date, TableRow.DayKind);
		If ValueIsFilled(TableRow.ReplacementDate) Then
			ShiftedDaysMap.Insert(TableRow.Date, TableRow.ReplacementDate);
		EndIf;
	EndDo;
	
	DaysKinds = New FixedMap(DaysKindsMap);
	ShiftedDays = New FixedMap(ShiftedDaysMap);
	
	FillReplacementsPresentation(ThisObject);
	
EndProcedure

&AtServer
Procedure WriteBusinessCalendarData(Val YearNumber, Val CurrentObject = Undefined)
	
	// Write business calendar data for the specified year.
	
	If CurrentObject = Undefined Then
		CurrentObject = FormAttributeToValue("Object");
	EndIf;
	
	BusinessCalendarData = New ValueTable;
	BusinessCalendarData.Columns.Add("Date", New TypeDescription("Date"));
	BusinessCalendarData.Columns.Add("DayKind", New TypeDescription("EnumRef.BusinessCalendarDaysKinds"));
	BusinessCalendarData.Columns.Add("ReplacementDate", New TypeDescription("Date"));
	
	For Each KeyAndValue In DaysKinds Do
		
		TableRow = BusinessCalendarData.Add();
		TableRow.Date = KeyAndValue.Key;
		TableRow.DayKind = KeyAndValue.Value;
		
		// If the day is shifted from another date, specify the replacement date.
		ReplacementDate = ShiftedDays.Get(TableRow.Date);
		If ReplacementDate <> Undefined 
			And ReplacementDate <> TableRow.Date Then
			TableRow.ReplacementDate = ReplacementDate;
		EndIf;
		
	EndDo;
	
	Catalogs.BusinessCalendars.WriteBusinessCalendarData(CurrentObject.Ref, YearNumber, BusinessCalendarData);
	
EndProcedure

&AtServer
Procedure ProcessYearChange(WriteScheduleData)
	
	If Not WriteScheduleData Then
		FillWithCurrentYearData();
		Return;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Write(New Structure("YearNumber", PreviousYearNumber));
	Else
		WriteBusinessCalendarData(PreviousYearNumber);
	EndIf;
	
	FillWithCurrentYearData();	
	
EndProcedure

&AtClient
Procedure ChangeDaysKinds(DaysDates, DayKind)
	
	// Sets a particular day kind for all array dates.
	
	DaysKindsMap = New Map(DaysKinds);
	
	For Each SelectedDate In DaysDates Do
		DaysKindsMap.Insert(SelectedDate, DayKind);
	EndDo;
	
	DaysKinds = New FixedMap(DaysKindsMap);
	
EndProcedure

&AtClient
Procedure ShiftDayKind(ReplacementDate, PurposeDate)
	
	// Substitute a date in the calendar:
	// - Switch each other's day type
	// - Remember the substitution date
	//	Notes: 
	//		* If the substitute day was already substituted, use the existing substitute date.
	//	* If the dates match (a holiday is "unsubstituted"), delete the record.
	
	DaysKindsMap = New Map(DaysKinds);
	
	DaysKindsMap.Insert(PurposeDate, DaysKinds.Get(ReplacementDate));
	DaysKindsMap.Insert(ReplacementDate, DaysKinds.Get(PurposeDate));
	
	ShiftedDaysMap = New Map(ShiftedDays);
	
	EnterReplacementDate(ShiftedDaysMap, ReplacementDate, PurposeDate);
	EnterReplacementDate(ShiftedDaysMap, PurposeDate, ReplacementDate);
	
	DaysKinds = New FixedMap(DaysKindsMap);
	ShiftedDays = New FixedMap(ShiftedDaysMap);
	
	FillReplacementsPresentation(ThisObject);
	
EndProcedure

&AtClient
Procedure EnterReplacementDate(ShiftedDaysMap, ReplacementDate, PurposeDate)
	
	// Populates a correct replacement date according to days replacement dates.
	
	PurposeDateDaySource = ShiftedDays.Get(PurposeDate);
	If PurposeDateDaySource = Undefined Then
		PurposeDateDaySource = PurposeDate;
	EndIf;
	
	If ReplacementDate = PurposeDateDaySource Then
		ShiftedDaysMap.Delete(ReplacementDate);
	Else	
		ShiftedDaysMap.Insert(ReplacementDate, PurposeDateDaySource);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillReplacementsPresentation(Form)
	
	// Generates a holiday replacement presentation as a value list.
	
	Form.ReplacementsList.Clear();
	For Each KeyAndValue In Form.ShiftedDays Do
		// A substitute holiday is originally a business day. 
		// Therefore, from the two dates, select the ex-holiday (which became a business day after substitution).
		SourceDate = KeyAndValue.Key;
		DestinationDate = KeyAndValue.Value;
		DayKind = Form.DaysKinds.Get(SourceDate);
		If DayKind = PredefinedValue("Enum.BusinessCalendarDaysKinds.Saturday")
			Or DayKind = PredefinedValue("Enum.BusinessCalendarDaysKinds.Sunday") Then
			// Swap dates to show holiday replacement information as "A replaces B" instead of "B replaces A".
			ReplacementDate = DestinationDate;
			DestinationDate = SourceDate;
			SourceDate = ReplacementDate;
		EndIf;
		If Form.ReplacementsList.FindByValue(SourceDate) <> Undefined 
			Or Form.ReplacementsList.FindByValue(DestinationDate) <> Undefined Then
			// Holiday replacement is already added, skip it.
			Continue;
		EndIf;
		Form.ReplacementsList.Add(SourceDate, ReplacementPresentation(SourceDate, DestinationDate));
	EndDo;
	Form.ReplacementsList.SortByValue();
	
	SetReplacementsListVisibility(Form);
	
EndProcedure

&AtClientAtServerNoContext
Function ReplacementPresentation(SourceDate, DestinationDate)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'từ%1%2 đến%3%4';
			|ru = 'с %1 %2 на %3 %4';
			|en = 'from %1 %2 to %3 %4'; fa = 'from %1 %2 to %3 %4';
			|it = 'da %1 %2 a %3 %4';
			|pl = 'z %1 %2 na %3 %4';
			|tr = '%1 %2 tarihinden %3 %4 tarihine'"),
		WeekDayMovingFromWording(SourceDate),
		Format(SourceDate, "DF='d MMMM'"), // ACC:1367 Consider saving the order "date, month" appropriate in this case. So far, this is an optimal solution.
		WeekDayMovingToWording(DestinationDate),
		Format(DestinationDate, "DF='d MMMM'")); // ACC:1367 
	
EndFunction

&AtClientAtServerNoContext
Procedure SetReplacementsListVisibility(Form)
	
	ListVisibility = Form.ReplacementsList.Count() > 0;
	CommonClientServer.SetFormItemProperty(Form.Items, "ReplacementsList", "Visible", ListVisibility);
	
EndProcedure

&AtServer
Procedure SetCalendarField()
	
	If CurrentYearNumber = 0 Then
		CurrentYearNumber = Year(CurrentSessionDate());
	EndIf;
	PreviousYearNumber = CurrentYearNumber;
	
	Items.Calendar.BeginOfRepresentationPeriod	= Date(CurrentYearNumber, 1, 1);
	Items.Calendar.EndOfRepresentationPeriod	= Date(CurrentYearNumber, 12, 31);
		
EndProcedure

&AtClient
Procedure CurrentYearNumberOnChangeCompletion(Response, AdditionalParameters) Export
	
	ProcessYearChange(Response = DialogReturnCode.Yes);
	Modified = False;
	Items.Calendar.Refresh();
	
EndProcedure

&AtClient
Procedure ChangeDayCompletion(SelectedElement, SelectedDates) Export
	
	If SelectedElement <> Undefined Then
		ChangeDaysKinds(SelectedDates, SelectedElement.Value);
		Items.Calendar.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintCompletion(ResponseToWriteSuggestion, ExecutionParameters = Undefined) Export
	
	If ResponseToWriteSuggestion <> -1 Then
		If ResponseToWriteSuggestion <> DialogReturnCode.Yes Then
			Return;
		EndIf;
		Written = Write();
		If Not Written Then
			Return;
		EndIf;
	EndIf;
	
	PrintParameters = New Structure;
	PrintParameters.Insert("BusinessCalendar", Object.Ref);
	PrintParameters.Insert("YearNumber", CurrentYearNumber);
	
	CommandParameter = New Array;
	CommandParameter.Add(Object.Ref);
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
		ModulePrintManagerClient.ExecutePrintCommand("Catalog.BusinessCalendars", "BusinessCalendar", 
			CommandParameter, ThisObject, PrintParameters);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetBasicCalendarFieldProperties(Form)
	
	CommonClientServer.SetFormItemProperty(
		Form.Items, 
		"BasicCalendar", 
		"Enabled", 
		Form.HasBasicCalendar);
		
	CommonClientServer.SetFormItemProperty(
		Form.Items, 
		"BasicCalendar", 
		"AutoMarkIncomplete", 
		Form.HasBasicCalendar);
		
	CommonClientServer.SetFormItemProperty(
		Form.Items, 
		"BasicCalendar", 
		"MarkIncomplete", 
		Not ValueIsFilled(Form.Object.BasicCalendar));
	
EndProcedure

&AtClient
Procedure StartBasicCalendarVisibilitySetup()
	
	TimeConsumingOperation = LoadSupportedBusinessCalendarsList();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	CallbackOnCompletion = New CallbackDescription("CompleteBasicCalendarVisibilitySetting", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function LoadSupportedBusinessCalendarsList()
	
	ProcedureParameters = New Structure;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Điền danh sách lịch hỗ trợ';
														|ru = 'Заполнение списка поддерживаемых календарей';
														|en = 'Populate list of supported calendars'; fa = 'Populate list of supported calendars';
														|it = 'Compilazione dell''elenco di calendari supportati';
														|pl = 'Wypełnienie listy obsługiwanych kalendarzy';
														|tr = 'Desteklenen takvimlerin listesini doldur'");
	
	Return TimeConsumingOperations.ExecuteInBackground("Catalogs.BusinessCalendars.FillDefaultBusinessCalendarsTimeConsumingOperation", 
		ProcedureParameters, ExecutionParameters);
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure CompleteBasicCalendarVisibilitySetting(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		CommonClientServer.SetFormItemProperty(Items, "BasicCalendarGroup", "Visible", True);
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;	
	EndIf;
	
	CalendarsAddress = Result.ResultAddress;
	IsSuppliedCalendar = HasSuppliedCalendarWithThisCode(CalendarsAddress, Object.Code);
	
	If Not IsSuppliedCalendar Then
		CommonClientServer.SetFormItemProperty(Items, "BasicCalendarGroup", "Visible", True);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function HasSuppliedCalendarWithThisCode(CalendarsAddress, Code)
	
	CalendarsTable = GetFromTempStorage(CalendarsAddress);
	
	If CalendarsTable <> Undefined And CalendarsTable.Columns.Find("Code") <> Undefined Then
		Return CalendarsTable.Find(TrimAll(Code), "Code") <> Undefined;
	EndIf;
	
	Return False;
	
EndFunction

&AtClientAtServerNoContext
Function WeekDayMovingFromWording(Date)
	
	Map = New Map;
	Map.Insert(1, NStr("vi = 'thứ hai';
						|ru = 'понедельника';
						|en = 'Monday'; fa = 'دوشنبه';
						|it = 'di lunedì';
						|pl = 'Monday';
						|tr = 'Pazartesi'"));
	Map.Insert(2, NStr("vi = 'thứ ba';
						|ru = 'вторника';
						|en = 'Tuesday'; fa = 'سه‌شنبه';
						|it = 'di martedì';
						|pl = 'Tuesday';
						|tr = 'Salı'"));
	Map.Insert(3, NStr("vi = 'thứ tư';
						|ru = 'среды';
						|en = 'Wednesday'; fa = 'چهارشنبه';
						|it = 'di mercoledì';
						|pl = 'Wednesday';
						|tr = 'Çarşamba'"));
	Map.Insert(4, NStr("vi = 'thứ năm';
						|ru = 'четверга';
						|en = 'Thursday'; fa = 'پنجشنبه';
						|it = 'di giovedì';
						|pl = 'Thursday';
						|tr = 'Perşembe'"));
	Map.Insert(5, NStr("vi = 'thứ sáu';
						|ru = 'пятницы';
						|en = 'Friday'; fa = 'جمعه';
						|it = 'di venerdì';
						|pl = 'Friday';
						|tr = 'Cuma'"));
	Map.Insert(6, NStr("vi = 'thứ bảy';
						|ru = 'субботы';
						|en = 'Saturday'; fa = 'شنبه';
						|it = 'di sabato';
						|pl = 'Saturday';
						|tr = 'Cumartesi'"));
	Map.Insert(7, NStr("vi = 'chủ nhật';
						|ru = 'воскресенья';
						|en = 'Sunday'; fa = 'یکشنبه';
						|it = 'di domenica';
						|pl = 'Sunday';
						|tr = 'Pazar'"));
	
	Presentation = Map[WeekDay(Date)];
	If Presentation = Undefined Then
		Return Format(Date, "DF='dddd'"); // ACC:1367 In this case, considering the localization, the displayed weekday is correct.
	EndIf;
	
	Return Presentation;
	
EndFunction

&AtClientAtServerNoContext
Function WeekDayMovingToWording(Date)
	
	Map = New Map;
	Map.Insert(1, NStr("vi = 'thứ hai';
						|ru = 'понедельник';
						|en = 'Monday'; fa = 'دوشنبه';
						|it = 'lunedì';
						|pl = 'Monday';
						|tr = 'Pazartesi'"));
	Map.Insert(2, NStr("vi = 'thứ ba';
						|ru = 'вторник';
						|en = 'Tuesday'; fa = 'سه‌شنبه';
						|it = 'martedì';
						|pl = 'Tuesday';
						|tr = 'Salı'"));
	Map.Insert(3, NStr("vi = 'thứ tư';
						|ru = 'среду';
						|en = 'Wednesday'; fa = 'چهارشنبه';
						|it = 'mercoledì';
						|pl = 'Wednesday';
						|tr = 'Çarşamba'"));
	Map.Insert(4, NStr("vi = 'thứ năm';
						|ru = 'четверг';
						|en = 'Thursday'; fa = 'پنجشنبه';
						|it = 'giovedì';
						|pl = 'Thursday';
						|tr = 'Perşembe'"));
	Map.Insert(5, NStr("vi = 'thứ sáu';
						|ru = 'пятницу';
						|en = 'Friday'; fa = 'جمعه';
						|it = 'venerdì';
						|pl = 'Friday';
						|tr = 'Cuma'"));
	Map.Insert(6, NStr("vi = 'thứ bảy';
						|ru = 'субботу';
						|en = 'Saturday'; fa = 'شنبه';
						|it = 'sabato';
						|pl = 'Saturday';
						|tr = 'Cumartesi'"));
	Map.Insert(7, NStr("vi = 'chủ nhật';
						|ru = 'воскресенье';
						|en = 'Sunday'; fa = 'یکشنبه';
						|it = 'domenica';
						|pl = 'Sunday';
						|tr = 'Pazar'"));
	
	Presentation = Map[WeekDay(Date)];
	If Presentation = Undefined Then
		Return Format(Date, "DF='dddd'"); // ACC:1367 In this case, considering the localization, the displayed weekday is correct.
	EndIf;
	
	Return Presentation;
	
EndFunction

&AtServer
Procedure ReadNonWorkDates(CurrentObject = Undefined)
	
	If CurrentObject = Undefined Then
		CurrentObject = Object;
	EndIf;

	Dates = New Array;
	
	BusinessCalendar = ?(ValueIsFilled(Object.BasicCalendar), 
		CurrentObject.BasicCalendar, CurrentObject.Ref);

	If ValueIsFilled(BusinessCalendar) Then
		TimeIntervals = CalendarSchedules.NonWorkDaysPeriods(
			BusinessCalendar, New StandardPeriod(Date(CurrentYearNumber, 1, 1), Date(CurrentYearNumber, 12, 31)));
		Explanation = "";
		For Each PeriodDetails In TimeIntervals Do
			CommonClientServer.SupplementArray(Dates, PeriodDetails.Dates);
				Explanation = Explanation + ?(Not IsBlankString(Explanation), Chars.LF, "") + PeriodDetails.Presentation;
		EndDo;
		Items.NonWorkPeriodsText.Title = Explanation;
	EndIf;
	
	NonWorkDates = New FixedArray(Dates);
	Items.NonWorkPeriodsGroup.Visible = NonWorkDates.Count() > 0;
	
EndProcedure

#EndRegion
