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

	SetConditionalAppearance();
	
	If Not Object.Ref.IsEmpty() Then
		Return;
	EndIf;
	
	TwelveHourTimeFormat = WorkSchedules.TwelveHourTimeFormat();
	
	InfobaseUpdate.CheckObjectProcessed("Catalog.Calendars", ThisObject);
	
	// If there is only one business calendar in the application, fill it in by default.
	BusinessCalendars = Catalogs.BusinessCalendars.BusinessCalendarsList();
	If BusinessCalendars.Count() = 1 Then
		Object.BusinessCalendar = BusinessCalendars[0];
	EndIf;
	
	PeriodLength = 7;
	
	Object.StartDate = BegOfYear(CurrentSessionDate());
	Object.StartingDate = BegOfYear(CurrentSessionDate());
	
	FillWithCurrentYearData(Parameters.CopyingValue);
	
	OnGetDataAtServer();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	TwelveHourTimeFormat = WorkSchedules.TwelveHourTimeFormat();
	
	PeriodLength = Object.FillingTemplate.Count();
	FillWithCurrentYearData();
	
	OnGetDataAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	Var YearNumber;
	
	If Not WriteParameters.Property("YearNumber", YearNumber) Then
		YearNumber = CurrentYearNumber;
	EndIf;
	
	// If the current year data was manually edited, write it "as is," 
	// and update the periods from the template.
	
	If ResultModified Then
		InformationRegisters.CalendarSchedules.WriteScheduleDataToRegister(CurrentObject.Ref, ScheduleDays, 
			Date(YearNumber, 1, 1), Date(YearNumber, 12, 31), True);
	EndIf;
	SaveManualEditingFlag(CurrentObject, YearNumber);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	PeriodLength = Object.FillingTemplate.Count();
	
	ConfigureFillingSettingItems(ThisObject);
	
	GenerateFillingTemplate(Object.FillingMethod, Object.FillingTemplate, PeriodLength, Object.StartingDate);
	
	FillSchedulePresentation(ThisObject);
	
	SpecifyFillDate();
	
	SetRemoveTemplateModified(ThisObject, False);
	
	FillWithCurrentYearData();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.FillingMethod = Enums.WorkScheduleFillingMethods.ByArbitraryLengthPeriods Then
		CheckedAttributes.Add("PeriodLength");
		CheckedAttributes.Add("StartingDate");
		
		// Checking the intersection of intervals between days
		DayNumbersInChart = New Array;
		For Each String In Object.FillingTemplate.FindRows(New Structure("DayAddedToSchedule", True)) Do
			DayNumbersInChart.Add(String.LineNumber);
		EndDo;
		
		Schedule = New ValueTable;
		Schedule.Columns.Add("LineNumber");
		Schedule.Columns.Add("DayNumber");
		Schedule.Columns.Add("BeginTime");
		Schedule.Columns.Add("EndTime");
		
		For Each String In Object.WorkSchedule Do
			If DayNumbersInChart.Find(String.DayNumber) = Undefined Then
				Continue;
			EndIf;
			
			NewRow = Schedule.Add();
			FillPropertyValues(NewRow, String);
		EndDo;
		
		Schedule.Sort("DayNumber, LineNumber");
		
		If PeriodLength <> 0 And Schedule.Count() > 0 Then
			DayNumber = Schedule[0].DayNumber;
			For IndexOf = 0 To Schedule.Count()-1 Do
				String = Schedule[IndexOf];
				If String.DayNumber = DayNumber Then
					NewRow = Schedule.Add();
					FillPropertyValues(NewRow, String,, "DayNumber");
					NewRow.DayNumber = DayNumber + PeriodLength;
				Else
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		DayNumber = 0;
		ScheduleBoundary = 0;
		EndDay = '00010101';
		
		For IndexOf = 0 To Schedule.Count()-1 Do
			String = Schedule[IndexOf];
			
			If String.DayNumber > DayNumber Then
				If ScheduleBoundary > String.DayNumber
					Or ScheduleBoundary = String.DayNumber
						And EndDay > String.BeginTime Then
					Common.MessageToUser(
						NStr("vi = 'Tìm thấy khoản thời gian chồng chéo';
							|ru = 'Обнаружены пересекающиеся интервалы';
							|en = 'Overlapping intervals are detected'; fa = 'Overlapping intervals are detected';
							|it = 'Обнаружены пересекающиеся интервалы';
							|pl = 'Znaleziono pokrywające się interwały';
							|tr = 'Çakışan aralıklar tespit edildi'"), , "Object.FillingTemplate", , Cancel);
					Break;
				EndIf;
				
				DayNumber = String.DayNumber;
				ScheduleBoundary = String.DayNumber;
				EndDay = '00010101';
			EndIf;
			
			If String.BeginTime < EndDay Then
				ScheduleBoundary = ScheduleBoundary + 1;
			EndIf;
			
			If String.BeginTime = String.EndTime
				Or Not ValueIsFilled(String.EndTime)
				Or String.BeginTime > String.EndTime Then
				ScheduleBoundary = ScheduleBoundary + 1;
			EndIf;
			
			EndDay = String.EndTime;
		EndDo;
	EndIf;
	
	If Object.FillingTemplate.FindRows(New Structure("DayAddedToSchedule", True)).Count() = 0 Then
		Common.MessageToUser(
			NStr("vi = 'Chưa đánh dấu ngày được đưa vào lịch làm việc';
				|ru = 'Не отмечены дни, включаемые в график работы';
				|en = 'Please select the days to include in the work schedule.'; fa = 'Please select the days to include in the work schedule.';
				|it = 'Nessun giorno è incluso nell''orario di lavoro';
				|pl = 'Nie zaznaczono dni, włączanych do harmonogramu pracy';
				|tr = 'Çalışma takvimine dahil edilen günler işaretlenmedi'"), , "Object.FillingTemplate", , Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessCalendarOnChange(Item)
	
	SetEnabledConsiderHolidays(ThisObject);
	SetAvailabilityConsiderNonWorkPeriods(ThisObject);
	
	SetClearResultsMatchTemplateFlag(ThisObject, False);
	SetRemoveTemplateModified(ThisObject, True);
	
EndProcedure

&AtClient
Procedure FillingMethodOnChange(Item)
	
	// Schedule normalization
	If Object.FillingMethod = PredefinedValue("Enum.WorkScheduleFillingMethods.ByWeeks") Then
		DayNumber = -1;
		EndDay = Undefined;
		DeleteRemainingDays = False;
		LinesToDelete = New Array;
		
		For IndexOf = 0 To Object.WorkSchedule.Count()-1 Do
			String = Object.WorkSchedule[IndexOf];
			
			If String.DayNumber <> DayNumber Then
				DayNumber = String.DayNumber;
				EndDay = Undefined;
				DeleteRemainingDays = False;
			EndIf;
		    
			If DeleteRemainingDays
				Or String.BeginTime > String.EndTime 
					And ValueIsFilled(String.EndTime)
				Or String.BeginTime = String.EndTime
				Or EndDay <> Undefined
					And (EndDay > String.BeginTime 
						Or Not ValueIsFilled(EndDay)) Then
				LinesToDelete.Add(String);
				DeleteRemainingDays = True;
			EndIf;
			
			EndDay = String.EndTime;
		EndDo;
		
		For Each String In LinesToDelete Do
			Object.WorkSchedule.Delete(String);
		EndDo;
	EndIf;
	
	ConfigureFillingSettingItems(ThisObject);
	
	ClarifyStartingDate();	
	
	GenerateFillingTemplate(Object.FillingMethod, Object.FillingTemplate, PeriodLength, Object.StartingDate);
	FillSchedulePresentation(ThisObject);

	SetClearResultsMatchTemplateFlag(ThisObject, False);
	SetRemoveTemplateModified(ThisObject, True);
	
EndProcedure

&AtClient
Procedure StartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.StartDate < Date(1900, 1, 1) Then
		Object.StartDate = BegOfYear(CommonClient.SessionDate());
	EndIf;
	
	SetAvailabilityConsiderNonWorkPeriods(ThisObject);
	
EndProcedure

&AtClient
Procedure EndDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	SetAvailabilityConsiderNonWorkPeriods(ThisObject);
EndProcedure

&AtClient
Procedure StartingDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ClarifyStartingDate();
	
	GenerateFillingTemplate(Object.FillingMethod, Object.FillingTemplate, PeriodLength, Object.StartingDate);
	
	SetClearResultsMatchTemplateFlag(ThisObject, False);
	SetRemoveTemplateModified(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PeriodLengthOnChange(Item)
	
	GenerateFillingTemplate(Object.FillingMethod, Object.FillingTemplate, PeriodLength, Object.StartingDate);
	FillSchedulePresentation(ThisObject);

	SetClearResultsMatchTemplateFlag(ThisObject, False);
	SetRemoveTemplateModified(ThisObject, True);
	
EndProcedure

&AtClient
Procedure ConsiderHolidaysOnChange(Item)
	
	SetClearResultsMatchTemplateFlag(ThisObject, False);
	SetRemoveTemplateModified(ThisObject, True);
	
	SetEnabledPreholidaySchedule(ThisObject);

EndProcedure

&AtClient
Procedure ConsiderNonWorkPeriodsOnChange(Item)

	SetClearResultsMatchTemplateFlag(ThisObject, False);
	SetRemoveTemplateModified(ThisObject, True);

EndProcedure

&AtClient
Procedure PreholidayScheduleClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	StartFillDaySchedule(0);
	
EndProcedure

&AtClient
Procedure PlanningHorizonOnChange(Item)
	
	AdjustScheduleFilled(ThisObject);
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(Item.EditText, ThisObject, "Object.LongDesc");
	
EndProcedure

&AtClient
Procedure CurrentYearNumberOnChange(Item)
	
	If CurrentYearNumber < Year(Object.StartDate)
		Or (ValueIsFilled(Object.EndDate) And CurrentYearNumber > Year(Object.EndDate)) Then
		CurrentYearNumber = PreviousYearNumber;
		Return;
	EndIf;
	
	WriteScheduleData = False;
	
	If ResultModified Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Ghi lại thay đổi dữ liệu cho %1 năm?';
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
	
	SetRemoveResultModified(ThisObject, False);
	
	Items.WorkScheduleCalendar.Refresh();
	
EndProcedure

&AtClient
Procedure WorkScheduleCalendarOnPeriodOutput(Item, PeriodAppearance)
	
	For Each PeriodAppearanceString In PeriodAppearance.Dates Do
		If ScheduleDays.Get(PeriodAppearanceString.Date) = Undefined Then
			DayTextColor = CommonClient.StyleColor("BusinessCalendarDayKindColorNotSpecified");
		Else
			DayTextColor = CommonClient.StyleColor("BusinessCalendarDayKindWorkdayColor");
		EndIf;
		PeriodAppearanceString.TextColor = DayTextColor;
		// Manual edit.
		If ChangedDays.Get(PeriodAppearanceString.Date) = Undefined Then
			DayBgColor = CommonClient.StyleColor("FieldBackColor");
		Else
			DayBgColor = CommonClient.StyleColor("ChangedScheduleDateBackground");
		EndIf;
		PeriodAppearanceString.BackColor = DayBgColor;
	EndDo;
	
EndProcedure

&AtClient
Procedure WorkScheduleCalendarSelection(Item, SelectedDate)
	
	If ScheduleDays.Get(SelectedDate) = Undefined Then
		// Include in the schedule.
		WorkSchedulesClient.InsertIntoFixedMap(ScheduleDays, SelectedDate, True);
		DayAddedToSchedule = True;
	Else
		// Exclude from the schedule.
		WorkSchedulesClient.DeleteFromFixedMap(ScheduleDays, SelectedDate);
		DayAddedToSchedule = False;
	EndIf;
	
	// Save the manual change as of the date.
	WorkSchedulesClient.InsertIntoFixedMap(ChangedDays, SelectedDate, DayAddedToSchedule);
	
	Items.WorkScheduleCalendar.Refresh();
	
	SetRemoveManualEditingFlag(ThisObject, True);
	SetRemoveResultModified(ThisObject, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFillingTemplate

&AtClient
Procedure FillingTemplateSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TemplateRow = Object.FillingTemplate.FindByID(RowSelected);
	StartFillDaySchedule(TemplateRow.LineNumber, RowSelected);
	
EndProcedure

&AtClient
Procedure FillingTemplateDayAddedToScheduleOnChange(Item)
	
	SetClearResultsMatchTemplateFlag(ThisObject, False);
	SetRemoveTemplateModified(ThisObject, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillFromTemplate(Command)
	
	FillByTemplateAtServer();
	
	Items.WorkScheduleCalendar.Refresh();
	
EndProcedure

&AtClient
Procedure FillingResult(Command)
	
	Items.Pages.CurrentPage = Items.FillingResultPage;
	
	If Not ResultFilledByTemplate Then
		FillByTemplateAtServer(True);
	EndIf;
	
	Items.WorkScheduleCalendar.Refresh();
	
EndProcedure

&AtClient
Procedure FillingSettings(Command)
	
	Items.Pages.CurrentPage = Items.FillingSettingsPage;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnGetDataAtServer(CurrentObject = Undefined)
	
	If CurrentObject = Undefined Then
		CurrentObject = Object;
	EndIf;
	
	ConfigureFillingSettingItems(ThisObject);
	
	GenerateFillingTemplate(
		CurrentObject.FillingMethod, Object.FillingTemplate, PeriodLength, CurrentObject.StartingDate);
	
	SpecifyFillDate();
	
	FillSchedulePresentation(ThisObject);
	
	SetAvailabilityConsiderNonWorkPeriods(ThisObject);

	SetClearResultsMatchTemplateFlag(ThisObject, True);
	SetRemoveTemplateModified(ThisObject, False);

	SetEnabledConsiderHolidays(ThisObject);
	SetEnabledPreholidaySchedule(ThisObject);
	
	SetManualChangesSet();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingTemplateSchedulePresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FillingTemplate.SchedulePresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FillingTemplate.DayAddedToSchedule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", BlankSchedulePresentation());

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingTemplateLineNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FillingMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.WorkScheduleFillingMethods.ByWeeks;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IsFilledInformationText.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RequiresFilling");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingResultInformationText.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ResultFilledByTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ManualEditing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PreholidaySchedule.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PreholidaySchedule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ConsiderHolidays");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", BlankSchedulePresentation());

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureFillingSettingItems(Form)
	
	CanChangeSetting = Form.Object.FillingMethod = PredefinedValue("Enum.WorkScheduleFillingMethods.ByArbitraryLengthPeriods");
	
	Form.Items.PeriodLength.ReadOnly = Not CanChangeSetting;
	Form.Items.StartingDate.ReadOnly = Not CanChangeSetting;
	
	Form.Items.StartingDate.AutoMarkIncomplete = CanChangeSetting;
	Form.Items.StartingDate.MarkIncomplete = CanChangeSetting And Not ValueIsFilled(Form.Object.StartingDate);
	
EndProcedure

&AtClientAtServerNoContext
Procedure GenerateFillingTemplate(FillingMethod, FillingTemplate, Val PeriodLength, Val StartingDate = Undefined)
	
	// Generates the table for editing the template used for filling by days.
	
	If FillingMethod = PredefinedValue("Enum.WorkScheduleFillingMethods.ByWeeks") Then
		PeriodLength = 7;
	EndIf;
	
	While FillingTemplate.Count() > PeriodLength Do
		FillingTemplate.Delete(FillingTemplate.Count() - 1);
	EndDo;

	While FillingTemplate.Count() < PeriodLength Do
		FillingTemplate.Add();
	EndDo;
	
	If FillingMethod = PredefinedValue("Enum.WorkScheduleFillingMethods.ByWeeks") Then
		FillingTemplate[0].DayPresentation = NStr("vi = 'Thứ hai';
													|ru = 'Понедельник';
													|en = 'Monday'; fa = 'دوشنبه';
													|it = 'Lunedì';
													|pl = 'Poniedziałek';
													|tr = 'Pazartesi'");
		FillingTemplate[1].DayPresentation = NStr("vi = 'Thứ 3';
													|ru = 'Вторник';
													|en = 'Tuesday'; fa = 'سه‌شنبه';
													|it = 'Martedì';
													|pl = 'Wtorek';
													|tr = 'Salı'");
		FillingTemplate[2].DayPresentation = NStr("vi = 'Thứ 4';
													|ru = 'Среда';
													|en = 'Wednesday'; fa = 'چهارشنبه';
													|it = 'Mercoledì';
													|pl = 'Wednesday';
													|tr = 'Çarşamba'");
		FillingTemplate[3].DayPresentation = NStr("vi = 'Thứ 5';
													|ru = 'Четверг';
													|en = 'Thursday'; fa = 'پنجشنبه';
													|it = 'Giovedì';
													|pl = 'Thursday';
													|tr = 'Perşembe'");
		FillingTemplate[4].DayPresentation = NStr("vi = 'Thứ 6';
													|ru = 'Пятница';
													|en = 'Friday'; fa = 'جمعه';
													|it = 'Venerdì';
													|pl = 'Friday';
													|tr = 'Cuma'");
		FillingTemplate[5].DayPresentation = NStr("vi = 'Thứ 7';
													|ru = 'Суббота';
													|en = 'Saturday'; fa = 'شنبه';
													|it = 'Sabato';
													|pl = 'Saturday';
													|tr = 'Cumartesi'");
		FillingTemplate[6].DayPresentation = NStr("vi = 'Chủ nhật';
													|ru = 'Воскресенье';
													|en = 'Sunday'; fa = 'یکشنبه';
													|it = 'Domenica';
													|pl = 'Sunday';
													|tr = 'Pazar'");
	Else
		DayDate = StartingDate;
		For Each DayRow In FillingTemplate Do
			DayRow.DayPresentation = Format(DayDate, "DF=d.MM");
			DayRow.SchedulePresentation = BlankSchedulePresentation();
			DayDate = DayDate + 86400;
		EndDo;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillSchedulePresentation(Form)
	
	For Each TemplateRow In Form.Object.FillingTemplate Do
		TemplateRow.SchedulePresentation = DaySchedulePresentation(Form, TemplateRow.LineNumber);
	EndDo;
	
	Form.PreholidaySchedule = DaySchedulePresentation(Form, 0);
	
EndProcedure

&AtClientAtServerNoContext
Function DaySchedulePresentation(Form, DayNumber)
	
	IntervalsPresentation = "";
	Seconds = 0;
	For Each ScheduleString In Form.Object.WorkSchedule Do
		If ScheduleString.DayNumber <> DayNumber Then
			Continue;
		EndIf;
		IntervalPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			"%1-%2, ", 
			DayPartPresentation(ScheduleString.BeginTime, Form.TwelveHourTimeFormat), 
			DayPartPresentation(ScheduleString.EndTime, Form.TwelveHourTimeFormat));
		IntervalsPresentation = IntervalsPresentation + IntervalPresentation;
		
		If ScheduleString.BeginTime = ScheduleString.EndTime Then
			IntervalInSeconds = 86400;
		ElsIf ScheduleString.BeginTime < ScheduleString.EndTime Then
			IntervalInSeconds = ScheduleString.EndTime - ScheduleString.BeginTime;
		ElsIf Not ValueIsFilled(ScheduleString.EndTime) Then
			IntervalInSeconds = EndOfDay(ScheduleString.EndTime) - ScheduleString.BeginTime + 1;
		Else
			IsMainPart = EndOfDay(ScheduleString.BeginTime) - ScheduleString.BeginTime + 1;
			RollingPart = ScheduleString.EndTime - BegOfDay(ScheduleString.EndTime);
			IntervalInSeconds = IsMainPart + RollingPart;
		EndIf;
		Seconds = Seconds + IntervalInSeconds;
	EndDo;
	StringFunctionsClientServer.DeleteLastCharInString(IntervalsPresentation, 2);
	
	If Seconds = 0 Then
		Return BlankSchedulePresentation();
	EndIf;
	
	Hours = Round(Seconds / 3600, 1);
	
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 g. (%2)';
																		|ru = '%1 ч. (%2)';
																		|en = '%1 h (%2)'; fa = '%1 h (%2)';
																		|it = '%1 h. (%2)';
																		|pl = '%1 godz. (%2)';
																		|tr = '%1 s. (%2)'"), Hours, IntervalsPresentation);
	
EndFunction

&AtClientAtServerNoContext
Function DayPartPresentation(Val DayPart, TwelveHourTimeFormat)
	
	If Not ValueIsFilled(DayPart) Then
		DayPart = Date(1980, 1, 1);
	EndIf;
	
	TimeFormat = ?(TwelveHourTimeFormat,
		NStr("vi = 'DF=''hh:mm tt''';
			|ru = 'ДФ=''чч:мм вв''';
			|en = 'DF=''hh:mm tt'''; fa = 'DF=''hh:mm tt''';
			|it = 'DF=''hh:mm''';
			|pl = 'DF=''hh:mm''';
			|tr = 'DF=''hh:mm ww'''"), NStr("vi = 'DF=HH:mm; DE=';
											|ru = 'ДФ=ЧЧ:мм; ДП=';
											|en = 'DF=HH:mm; DE='; fa = 'DF=HH:mm; DE=';
											|it = 'DF=HH:mm; DE=';
											|pl = 'DF=GG:mm; DE=';
											|tr = 'DF=HH:mm; DE='"));
		
	Return Format(DayPart, TimeFormat);
	
EndFunction

&AtClient
Function WorkSchedule(DayNumber)
	
	DaySchedule = New Array;
	
	For Each ScheduleString In Object.WorkSchedule Do
		If ScheduleString.DayNumber = DayNumber Then
			DaySchedule.Add(New Structure("BeginTime, EndTime", ScheduleString.BeginTime, ScheduleString.EndTime));
		EndIf;
	EndDo;
	
	Return DaySchedule;
	
EndFunction

&AtClientAtServerNoContext
Function BlankSchedulePresentation()
	
	Return NStr("vi = 'Điền lịch biểu';
				|ru = 'Заполнить расписание';
				|en = 'Fill in the schedule'; fa = 'Fill in the schedule';
				|it = 'Compilare l''orario';
				|pl = 'Wypełń';
				|tr = 'Programı doldur'");
	
EndFunction

&AtClientAtServerNoContext
Procedure SetEnabledConsiderHolidays(Form)
	
	Form.Items.ConsiderHolidays.Enabled = ValueIsFilled(Form.Object.BusinessCalendar);
	If Not Form.Items.ConsiderHolidays.Enabled Then
		Form.Object.ConsiderHolidays = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityConsiderNonWorkPeriods(Form)

	Items = Form.Items;
	Object = Form.Object;
	
	Items.ConsiderNonWorkPeriodsGroup.Visible = False;
	If Not ValueIsFilled(Object.BusinessCalendar) Then
		Return;
	EndIf;
	
	TimeIntervals = NonWorkDaysPeriods(Object.BusinessCalendar, Object.StartDate, Object.EndDate);
	If TimeIntervals.Count() = 0 Then
		Return;
	EndIf;
	
	Items.ConsiderNonWorkPeriodsGroup.Visible = True;
	
	Explanation = "";
	For Each PeriodDetails In TimeIntervals Do
		Explanation = Explanation + ?(Not IsBlankString(Explanation), Chars.LF, "") + PeriodDetails.Presentation;
	EndDo;
	Items.NonWorkPeriodsInformation.Title = Explanation;
	
EndProcedure

&AtServerNoContext
Function NonWorkDaysPeriods(BusinessCalendar, StartDate, EndDate)
	Return CalendarSchedules.NonWorkDaysPeriods(
		BusinessCalendar, New StandardPeriod(StartDate, EndDate));
EndFunction

&AtServer
Procedure SpecifyFillDate()
	
	QueryText = 
	"SELECT
	|	MAX(CalendarSchedules.ScheduleDate) AS Date
	|FROM
	|	InformationRegister.CalendarSchedules AS CalendarSchedules
	|WHERE
	|	CalendarSchedules.Calendar = &WorkScheduleCalendar";
	
	Query = New Query(QueryText);
	Query.SetParameter("WorkScheduleCalendar", Object.Ref);
	Selection = Query.Execute().Select();
	
	FillDate = Undefined;
	If Selection.Next() Then
		FillDate = Selection.Date;
	EndIf;	
	
	AdjustScheduleFilled(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustScheduleFilled(Form)
	
	Form.RequiresFilling = False;
	
	If Form.Parameters.Key.IsEmpty() Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Form.FillDate) Then
		Form.IsFilledInformationText = NStr("vi = 'Lịch biểu làm việc chưa điền';
											|ru = 'График работы не заполнен';
											|en = 'The work schedule is blank.'; fa = 'The work schedule is blank.';
											|it = 'L''orario di lavoro non è compilato';
											|pl = 'Nie wypełniono harmonogramu pracy';
											|tr = 'Çalışma takvimi doldurulmadı'");
		Form.RequiresFilling = True;
	Else	
		If Not ValueIsFilled(Form.Object.PlanningHorizon) Then
			InformationText = NStr("vi = 'Lịch biểu làm việc đã điền đến %1';
									|ru = 'График работы заполнен до %1';
									|en = 'The work schedule is filled in till %1.'; fa = 'The work schedule is filled in till %1.';
									|it = 'L''orario di lavoro è compilato fino a %1';
									|pl = 'Harmonogram pracy jest wypełniony do %1';
									|tr = 'Çalışma takvimi %1 tarihine kadar dolduruldu'");
			Form.IsFilledInformationText = StringFunctionsClientServer.SubstituteParametersToString(InformationText, Format(Form.FillDate, "DLF=D"));
		Else
#If WebClient Or ThinClient Or MobileClient Then
				CurrentDate = CommonClient.SessionDate();
#Else
				CurrentDate = CurrentSessionDate();
#EndIf
			EndPlanningHorizon = AddMonth(CurrentDate, Form.Object.PlanningHorizon);
			InformationText = NStr("vi = 'Lịch biểu làm việc đã điền đến %1, có tính đến đường chân trời lập kế hoạch lịch biểu phải được điền đến %2';
									|ru = 'График работы заполнен до %1, с учетом горизонта планирования график должен быть заполнен до %2';
									|en = 'The work schedule is filled till %1. The provided scheduling interval requires that you fill it till %2.'; fa = 'The work schedule is filled till %1. The provided scheduling interval requires that you fill it till %2.';
									|it = 'L''orario di lavoro è compilato fino a %1, considerando il periodo di pianificazione l''orario deve essere compilato fino a %2';
									|pl = 'Harmonogram pracy jest wypełniony do %1, z uwzględnieniem horyzontu planowania harmonogram powinien być wypełniony do %2';
									|tr = 'Çalışma takvimi %1 tarihine kadar dolduruldu; planlama süresini dikkate alınarak çalışma takvimi %2 tarihine kadar doldurulmalıdır'");
			Form.IsFilledInformationText = StringFunctionsClientServer.SubstituteParametersToString(InformationText, Format(Form.FillDate, "DLF=D"), Format(EndPlanningHorizon, "DLF=D"));
			If EndPlanningHorizon > Form.FillDate Then
				Form.RequiresFilling = True;
			EndIf;
		EndIf;
	EndIf;
	Form.Items.IsFilledDecoration.Picture = ?(Form.RequiresFilling, PictureLib.Warning, PictureLib.Information);
	
EndProcedure

&AtServer
Procedure FillByTemplateAtServer(PreserveManualEditing = False)

	FillParameters = InformationRegisters.CalendarSchedules.ScheduleFillingParameters();
	FillParameters.FillingMethod = Object.FillingMethod;
	FillParameters.FillingTemplate = Object.FillingTemplate;
	FillParameters.BusinessCalendar = Object.BusinessCalendar;
	FillParameters.ConsiderHolidays = Object.ConsiderHolidays;
	FillParameters.ConsiderNonWorkPeriods = Object.ConsiderNonWorkPeriods;
	FillParameters.StartingDate = Object.StartingDate;
	
	DaysIncludedInSchedule = InformationRegisters.CalendarSchedules.DaysIncludedInSchedule(
		Object.StartDate, Object.EndDate, FillParameters);
	
	If ManualEditing Then
		If PreserveManualEditing Then
			// Apply manual adjustments.
			For Each KeyAndValue In ChangedDays Do
				ChangesDate = KeyAndValue.Key;
				DayAddedToSchedule = KeyAndValue.Value;
				If DayAddedToSchedule Then
					DaysIncludedInSchedule.Insert(ChangesDate, True);
				Else
					DaysIncludedInSchedule.Delete(ChangesDate);
				EndIf;
			EndDo;
		Else
			SetRemoveResultModified(ThisObject, True);
			SetRemoveManualEditingFlag(ThisObject, False);
		EndIf;
	EndIf;
	
	// Move the result to the original filling map to prevent overwriting 
	// the dates that stand outside of the filling time period.
	ScheduleDaysMap = New Map(ScheduleDays);
	DayDate = Object.StartDate;
	EndDate = Object.EndDate;
	If Not ValueIsFilled(EndDate) Then
		EndDate = EndOfYear(Object.StartDate);
	EndIf;
	While DayDate <= EndDate Do
		DayAddedToSchedule = DaysIncludedInSchedule[DayDate];
		If DayAddedToSchedule = Undefined Then
			ScheduleDaysMap.Delete(DayDate);
		Else
			ScheduleDaysMap.Insert(DayDate, DayAddedToSchedule);
		EndIf;
		DayDate = DayDate + 86400;
	EndDo;
	
	ScheduleDays = New FixedMap(ScheduleDaysMap);
	
	If Not ResultFilledByTemplate Then
		SetRemoveResultModified(ThisObject, True);
		SetClearResultsMatchTemplateFlag(ThisObject, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillWithCurrentYearData(CopyingValue = Undefined)
	
	// Fills in the form with data of the current year.
	
	SetCalendarField();
	
	If ValueIsFilled(CopyingValue) Then
		ScheduleRef = CopyingValue;
	Else
		ScheduleRef = Object.Ref;
	EndIf;
	
	ScheduleDays = New FixedMap(
		InformationRegisters.CalendarSchedules.ReadScheduleDataFromRegister(ScheduleRef, CurrentYearNumber));

	ReadManualEditingFlag(Object, CurrentYearNumber);
	
	// If there are no manual adjustments or data, generate the result by template for the selected year.
	If ScheduleDays.Count() = 0 And ChangedDays.Count() = 0 Then
		FillParameters = InformationRegisters.CalendarSchedules.ScheduleFillingParameters();
		FillParameters.FillingMethod = Object.FillingMethod;
		FillParameters.FillingTemplate = Object.FillingTemplate;
		FillParameters.BusinessCalendar = Object.BusinessCalendar;
		FillParameters.ConsiderHolidays = Object.ConsiderHolidays;
		FillParameters.ConsiderNonWorkPeriods = Object.ConsiderNonWorkPeriods;
		FillParameters.StartingDate = Object.StartingDate;
		DaysIncludedInSchedule = InformationRegisters.CalendarSchedules.DaysIncludedInSchedule(
			Object.StartDate, Date(CurrentYearNumber, 12, 31), FillParameters);
		ScheduleDays = New FixedMap(DaysIncludedInSchedule);
	EndIf;
	
	SetRemoveResultModified(ThisObject, False);
	SetClearResultsMatchTemplateFlag(ThisObject, Not TemplateModified);

EndProcedure

&AtServer
Procedure ReadManualEditingFlag(CurrentObject, YearNumber)
	
	If CurrentObject.Ref.IsEmpty() Then
		SetRemoveManualEditingFlag(ThisObject, False);
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	ManualChanges.ScheduleDate
	|FROM
	|	InformationRegister.ManualWorkScheduleChanges AS ManualChanges
	|WHERE
	|	ManualChanges.WorkScheduleCalendar = &WorkScheduleCalendar
	|	AND ManualChanges.Year = &Year");
	
	Query.SetParameter("WorkScheduleCalendar", CurrentObject.Ref);
	Query.SetParameter("Year", YearNumber);
	
	Map = New Map;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Map.Insert(Selection.ScheduleDate, True);
	EndDo;
	ChangedDays = New FixedMap(Map);
	
	SetRemoveManualEditingFlag(ThisObject, ChangedDays.Count() > 0);
	
EndProcedure

&AtServer
Procedure SaveManualEditingFlag(CurrentObject, YearNumber)
	
	RecordSet = InformationRegisters.ManualWorkScheduleChanges.CreateRecordSet();
	RecordSet.Filter.WorkScheduleCalendar.Set(CurrentObject.Ref);
	RecordSet.Filter.Year.Set(YearNumber);
	
	For Each KeyAndValue In ChangedDays Do
		SetRow = RecordSet.Add();
		SetRow.ScheduleDate = KeyAndValue.Key;
		SetRow.WorkScheduleCalendar = CurrentObject.Ref;
		SetRow.Year = YearNumber;
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

&AtServer
Procedure WriteWorkScheduleDataForYear(YearNumber)
	
	InformationRegisters.CalendarSchedules.WriteScheduleDataToRegister(Object.Ref, ScheduleDays, Date(YearNumber, 1, 1), 
		Date(YearNumber, 12, 31), True);
	SaveManualEditingFlag(Object, YearNumber);
	
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
		WriteWorkScheduleDataForYear(PreviousYearNumber);
		FillWithCurrentYearData();	
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetRemoveManualEditingFlag(Form, ManualEditing)
	
	Form.ManualEditing = ManualEditing;
	
	If Not ManualEditing Then
		Form.ChangedDays = New FixedMap(New Map);
	EndIf;
	
	FillFillingResultInformationText(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetClearResultsMatchTemplateFlag(Form, ResultFilledByTemplate)
	
	Form.ResultFilledByTemplate = ResultFilledByTemplate;
	
	FillFillingResultInformationText(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetRemoveTemplateModified(Form, TemplateModified)
	
	Form.TemplateModified = TemplateModified;
	
	Form.Modified = Form.TemplateModified Or Form.ResultModified;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetRemoveResultModified(Form, ResultModified)
	
	Form.ResultModified = ResultModified;
	
	Form.Modified = Form.TemplateModified Or Form.ResultModified;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillFillingResultInformationText(Form)
	
	InformationText = "";
	InformativeImage = New Picture;
	CanFillByTemplate = False;
	If Form.ManualEditing Then
		InformationText = NStr("vi = 'Đã thay đổi thủ công lịch làm việc trong năm nay. 
                                    |Hãy nhấn ""Điền theo mẫu"" để quay lại điền tự động.';
                                    |ru = 'График работы на текущий год изменен вручную. 
                                    |Нажмите ""Заполнить по шаблону"", чтобы вернуться к автоматическому заполнению.';
                                    |en = 'The work schedule for the current year is changed manually. 
                                    |Click ""Fill in by template"" to return to automatic filling.'; fa = 'The work schedule for the current year is changed manually. 
                                    |Click ""Fill in by template"" to return to automatic filling.';
                                    |it = 'Il grafico di lavoro per l''anno corrente è stato modificato manualmente.
                                    |Cliccare su ""Compilare da modello"" per tornare alla compilazione automatica.';
                                    |pl = 'Harmonogram pracy na bieżący rok został zmieniony ręcznie. 
                                    |Naciśnij ""Wypełnij wg szablonu"", żeby wrócić do automatycznego wypełniania.';
                                    |tr = 'Geçerli yıl için çalışma takvimi manuel olarak değiştirildi. 
                                    |Otomatik doldurmaya dönmek için ""Şablona göre doldur"" butonuna tıklayın.'");
		InformativeImage = PictureLib.Warning;
		CanFillByTemplate = True;
	Else
		If Form.ResultFilledByTemplate Then
			If ValueIsFilled(Form.Object.BusinessCalendar) Then
				InformationText = NStr("vi = 'Lịch biểu làm việc tự động được cập nhật khi thay đổi lịch sản xuất trong kỳ hiện tại.';
										|ru = 'График работы автоматически обновляется при изменении производственного календаря за текущий год.';
										|en = 'The work schedule is updated automatically upon changing the business calendar for the current year.'; fa = 'The work schedule is updated automatically upon changing the business calendar for the current year.';
										|it = 'L''orario di lavoro viene rinnovato automaticamente durante la modifica del calendario di produzione dell''anno corrente.';
										|pl = 'Harmonogram pracy jest aktualizowany automatycznie przy zmianie kalendarza produkcyjnego na bieżący rok.';
										|tr = 'Mevcut yıl için iş takvimi değiştiğinde çalışma takvimi otomatik olarak güncellenir.'");
				InformativeImage = PictureLib.Information;
			EndIf;
		Else
			InformationText = NStr("vi = 'Kết quả hiển thị không tương ứng với tùy chỉnh khuôn mẫu. 
                                        |Nhấn nút ""Điền theo mẫu"" để xem cách thức hiển thị lịch làm việc theo khuôn mẫu khác nhau.';
                                        |ru = 'Отображаемый результат не соответствует настройке шаблона. 
                                        |Нажмите ""Заполнить по шаблону"", чтобы увидеть как выглядит график работы с учетом изменений шаблона.';
                                        |en = 'The displayed result does not match the template.
                                        |Click ""Fill in by template"" to view the work schedule based on the updated template.'; fa = 'The displayed result does not match the template.
                                        |Click ""Fill in by template"" to view the work schedule based on the updated template.';
                                        |it = 'Il risultato visualizzato non corrisponde all''impostazione del modello. 
                                        |Cliccare su ""Compilare da modello"" per vedere come appare il grafico di lavoro con contabilità delle modifiche dimodello.';
                                        |pl = 'Odzwierciedlany rezultat nie odpowiada ustawieniom szablonu. 
                                        |Naciśnij ""Wypełnij wg szablonu"", aby zobaczyć jak wygląda harmonogram pracy z uwzględnieniem zmian wprowadzonych do szablonu.';
                                        |tr = 'Görüntülenen sonuç şablon ayarıyla eşleşmiyor. 
                                        |Şablon değişiklikleri göz önüne alındığında çalışma takviminin nasıl göründüğünü görmek için ""Şablona göre Doldur"" butonuna tıklayın.'");
			InformativeImage = PictureLib.Warning;
			CanFillByTemplate = True;
		EndIf;
	EndIf;
	
	Form.FillingResultInformationText = InformationText;
	Form.Items.FillingResultDecoration.Picture = InformativeImage;
	Form.Items.FillFromTemplate.Enabled = CanFillByTemplate;
	
	FillInformationTextManualEditing(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInformationTextManualEditing(Form)
	
	InformationText = "";
	InformativeImage = New Picture;
	If Form.ManualEditing Then
		InformativeImage = PictureLib.Warning;
		InformationText = NStr("vi = 'Lịch biểu làm việc cho năm hiện tại đã thay đổi thủ công. Thay đổi được chọn trong các kết quả điền.';
								|ru = 'График работы на текущий год изменен вручную. Изменения выделены в результатах заполнения.';
								|en = 'The work schedule for the current year is changed manually. The changes are highlighted.'; fa = 'The work schedule for the current year is changed manually. The changes are highlighted.';
								|it = 'L''orario di lavoro per l''anno corrente è stato modificato manualmente. Le modifiche sono evidenziate nei risultati della compilazione.';
								|pl = 'Harmonogram pracy na bieżący rok został zmieniony ręcznie, Zmiany zaznaczono w rezultatach wypełniania.';
								|tr = 'Geçerli yıl için çalışma takvimi manuel olarak değiştirildi. Değişiklikler doldurma sonuçlarında vurgulanmıştır.'");
	EndIf;
	
	Form.ManualEditingInformationText = InformationText;
	Form.Items.ManualEditingDecoration.Picture = InformativeImage;
	
EndProcedure

&AtServer
Procedure SetCalendarField()
	
	If CurrentYearNumber = 0 Then
		CurrentYearNumber = Year(CurrentSessionDate());
	EndIf;
	PreviousYearNumber = CurrentYearNumber;
	
	WorkScheduleCalendar = Date(CurrentYearNumber, 1, 1);
	Items.WorkScheduleCalendar.BeginOfRepresentationPeriod	= Date(CurrentYearNumber, 1, 1);
	Items.WorkScheduleCalendar.EndOfRepresentationPeriod	= Date(CurrentYearNumber, 12, 31);
		
EndProcedure

&AtClient
Procedure CurrentYearNumberOnChangeCompletion(Response, AdditionalParameters) Export
	
	WriteScheduleData = False;
	If Response = DialogReturnCode.Yes Then
		WriteScheduleData = True;
	EndIf;
	
	ProcessYearChange(WriteScheduleData);
	SetRemoveResultModified(ThisObject, False);
	Items.WorkScheduleCalendar.Refresh();
	
EndProcedure

&AtClient
Procedure ClarifyStartingDate()
	
	If Object.StartingDate < Date(1900, 1, 1) Then
		Object.StartingDate = BegOfYear(CommonClient.SessionDate());
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetEnabledPreholidaySchedule(Form)
	Items = Form.Items;
	Items.PreholidaySchedule.Enabled = Form.Object.ConsiderHolidays;
EndProcedure

&AtClient
Function AdditionalDayScheduleFillingParameters()

	AdditionalParameters = New Structure(
		"DayNumber,
		|TemplateRowID");
	Return AdditionalParameters;
	
EndFunction

&AtClient
Procedure StartFillDaySchedule(DayNumber, TemplateRowID = Undefined)
	
	ChoiceContext = AdditionalDayScheduleFillingParameters();
	ChoiceContext.DayNumber = DayNumber;
	ChoiceContext.TemplateRowID = TemplateRowID;
	
	RollingShifts = Object.FillingMethod = PredefinedValue(
		"Enum.WorkScheduleFillingMethods.ByArbitraryLengthPeriods");
	
	FormParameters = New Structure;
	FormParameters.Insert("WorkSchedule", WorkSchedule(ChoiceContext.DayNumber));
	FormParameters.Insert("RollingShifts", RollingShifts);
	FormParameters.Insert("ReadOnly", ReadOnly);
	
	CloseHandler = New CallbackDescription("CompleteDayScheduleFilling", ThisObject, ChoiceContext);
	OpenForm("Catalog.Calendars.Form.WorkSchedule", FormParameters, ThisObject, , , , CloseHandler);
	
EndProcedure

&AtClient
Procedure CompleteDayScheduleFilling(ValueSelected, ChoiceContext) Export
	
	If ValueSelected = Undefined Or ReadOnly Then
		Return;
	EndIf;
	
	// Delete the previously filled in schedule for this day.
	DayRows = New Array;
	For Each ScheduleString In Object.WorkSchedule Do
		If ScheduleString.DayNumber = ChoiceContext.DayNumber Then
			DayRows.Add(ScheduleString.GetID());
		EndIf;
	EndDo;
	For Each RowID In DayRows Do
		Object.WorkSchedule.Delete(Object.WorkSchedule.FindByID(RowID));
	EndDo;
	
	// Filling the work hours for a day.
	For Each IntervalDetails In ValueSelected.WorkSchedule Do
		NewRow = Object.WorkSchedule.Add();
		FillPropertyValues(NewRow, IntervalDetails);
		NewRow.DayNumber = ChoiceContext.DayNumber;
	EndDo;
	
	If ChoiceContext.DayNumber = 0 Then
		PreholidaySchedule = DaySchedulePresentation(ThisObject, 0);
	EndIf;
	
	SetClearResultsMatchTemplateFlag(ThisObject, False);
	SetRemoveTemplateModified(ThisObject, True);
	
	If ChoiceContext.TemplateRowID <> Undefined Then
		TemplateRow = Object.FillingTemplate.FindByID(ChoiceContext.TemplateRowID);
		TemplateRow.DayAddedToSchedule = ValueSelected.WorkSchedule.Count() > 0; // Schedule is filled.
		TemplateRow.SchedulePresentation = DaySchedulePresentation(ThisObject, ChoiceContext.DayNumber);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetManualChangesSet()
	
	If Not AccessRight("Update", Metadata.Catalogs.Calendars) Then
		Items.WorkScheduleCalendar.ReadOnly = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_StartDate" Then
		StartDateOnChange(Items.StartDate);
	ElsIf Item.Name = "sh_ShamsiInput_EndDate" Then
		EndDateOnChange(Items.EndDate);
	ElsIf Item.Name = "sh_ShamsiInput_StartingDate" Then
		StartingDateOnChange(Items.StartingDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
