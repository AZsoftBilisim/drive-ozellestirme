#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	WorkCenterType = Parameters.WorkCenterType;
	ScheduleDate = Parameters.ScheduleDate;
	ManualChangesMade = Parameters.ManualChangesMade;
	DataAddressWCOperationSchedules = Parameters.DataAddressWCOperationSchedules;
	
	RollingShifts = (Parameters.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift);
	
	If TypeOf(Parameters.WorkSchedules) = Type("Array") And Parameters.WorkSchedules.Count() > 0 Then
		WCAddressWorkSchedules = PutToTempStorage(Parameters.WorkSchedules, UUID);
	EndIf;
	
	If Parameters.DataChanged1 Then
		ScheduleOfWorkSchedulesOfRC = GetFromTempStorage(DataAddressWCOperationSchedules);
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("WorkCenter", Parameters.WorkCenter);
		TheStructureOfTheSearch.Insert("Shift", Parameters.Shift);
		TheStructureOfTheSearch.Insert("ScheduleDate", ScheduleDate);
		
		ScheduleAsOfScheduleDate = ScheduleOfWorkSchedulesOfRC.FindRows(TheStructureOfTheSearch);
	Else
		ScheduleAsOfScheduleDate = ScheduleAsOfScheduleDate(Parameters.WorkCenter, Parameters.Shift, ScheduleDate);
	EndIf; 
	
	For Each DaySchedule In ScheduleAsOfScheduleDate Do
		If DaySchedule.Count <> 0 Then
			LineInterval = Intervals.Add();
			LineInterval.BeginTime    = DaySchedule.BeginTime;
			LineInterval.EndTime = DaySchedule.EndTime;
		EndIf; 
	EndDo;
	
	If Not RollingShifts Then
		Intervals.Sort("BeginTime");
	EndIf;
	
	Items.Intervals.ChangeRowOrder = RollingShifts;
	
	FillInTotalTime(ThisObject);
	
	If Parameters.OnlyChartView Then
		Items.Intervals.ReadOnly = True;
		Items.ScheduleDatesFillInAccordingToTheWorkSchedule.Visible = False;
		Items.CommandBarBottom.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		
		StandardProcessing = False;
		
		ClosingNotification_ = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		
		CommonClient.ShowFormClosingConfirmation(ClosingNotification_, Cancel, Exit, QueryText,
			WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("CatalogRef.Calendars") Then
		FillInAccordingToServerSchedule(ValueSelected);
		ManualChangesMade = False;
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIntervals

&AtClient
Procedure IntervalsOnChange(Item)

	ManualChangesMade = True;
	
	FillInTotalTime(ThisObject);
	
	If Not RollingShifts Then
		ProductionManagementClient.RestoreCollectionRowOrderAfterEditing(
			Intervals,
			"BeginTime",
			Item.CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure IntervalsOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		
		FillInTotalTime(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EndOfTheIntervalOnChange(Item)
	
	CurrentData = Items.Intervals.CurrentData;
	If CurrentData <> Undefined
		And BegOfMinute(CurrentData.EndTime) <> CurrentData.EndTime Then
		CurrentData.EndTime = BegOfMinute(CurrentData.EndTime);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TeamFillInAccordingToWorkSchedule(Command)
	
	If IsTempStorageURL(WCAddressWorkSchedules) Then
		
		FillInAccordingToServerSchedule(GetFromTempStorage(WCAddressWorkSchedules));
		ManualChangesMade = False;
		
	Else
		
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		CallbackDescription = New CallbackDescription("FillInByWorkScheduleCompletion", ThisObject);
		OpenForm("Catalog.Calendars.ChoiceForm", 
						FormParameters, 
						ThisForm,,,, 
						CallbackDescription, 
						FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure OkCommand(Command)
	
	CompleteEditing();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FillInByWorkScheduleCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		FillInAccordingToServerSchedule(ClosingResult);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAccordingToServerSchedule(WorkScheduleCalendar)
	
	Intervals.Clear();
	
	WorkSchedulesForPeriod = ProductionPlanning.ScheduleOfWorkOnSchedule(
		WorkScheduleCalendar,
		BegOfDay(ScheduleDate),
		EndOfDay(ScheduleDate),
		RollingShifts);
	For Each ScheduleLine In WorkSchedulesForPeriod Do
		LineInterval = Intervals.Add();
		FillPropertyValues(LineInterval, ScheduleLine);
	EndDo; 
	
	FillInTotalTime(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CompleteEditing();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteEditing()

	ClearMessages();
	
	DaySchedule = DaySchedule();
	If DaySchedule = Undefined Then
		Return;
	EndIf;
	
	EditResult = New Structure;
	EditResult.Insert("ManualChangesMade", ManualChangesMade);
	EditResult.Insert("DaySchedule", DaySchedule);
	
	Modified = False;
	
	Close(EditResult);

EndProcedure

&AtClient
Function DaySchedule()
	
	Cancel = False;
	
	DaySchedule = New Array;
	
	If RollingShifts Then
		DayNumber = 1;
		EndDay = '00010101';
		For RowIndex = 0 To Intervals.Count()-1 Do
			ScheduleString = Intervals[RowIndex];
			
			If ScheduleString.BeginTime < EndDay Then
				DayNumber = DayNumber + 1;
			EndIf;
			
			If ScheduleString.BeginTime = ScheduleString.EndTime
				Or Not ValueIsFilled(ScheduleString.EndTime)
				Or ScheduleString.BeginTime > ScheduleString.EndTime Then
				DayNumber = DayNumber + 1;
			EndIf;
			
			EndDay = ScheduleString.EndTime;
			
			If DayNumber >= 3 And ValueIsFilled(EndDay) Then
				CommonClient.MessageToUser(
					NStr("vi = 'Tìm thấy khoản thời gian chồng chéo';
						|ru = 'Обнаружены пересекающиеся интервалы';
						|en = 'Overlapping intervals are detected.'; fa = 'Overlapping intervals are detected.';
						|it = 'Rilevati intervalli sovrapposti';
						|pl = 'Znaleziono pokrywające się interwały';
						|tr = 'Çakışan aralıklar tespit edildi'"), ,
					StringFunctionsClientServer.SubstituteParametersToString("Intervals[%1].BeginTime", RowIndex), ,
					Cancel);
				Break;
			EndIf;
			
			Duration = ProductionManagementClientServer.DurationOfScheduleInterval(
				ScheduleString.BeginTime, ScheduleString.EndTime);
			
			DaySchedule.Add(New Structure("BeginTime, EndTime, Duration", 
									ScheduleString.BeginTime, ScheduleString.EndTime, Duration));
		EndDo;
	Else
		EndDay = Undefined;
	
		For Each ScheduleString In Intervals Do
			RowIndex = Intervals.IndexOf(ScheduleString);
			If ScheduleString.BeginTime > ScheduleString.EndTime 
				And ValueIsFilled(ScheduleString.EndTime) Then
				CommonClientServer.MessageToUser(
					NStr("vi = 'Thời gian bắt đầu lớn hơn thời gian kết thúc';
						|ru = 'Время начала больше времени окончания';
						|en = 'The start time is greater than the end time.'; fa = 'The start time is greater than the end time.';
						|it = 'Il tempo d''inizio è superiore al tempo del termine';
						|pl = 'Czas rozpoczęcia jest późniejszy od czasu zakończenia';
						|tr = 'Başlangıç zamanı, bitiş zamanından ileri'"), ,
					StringFunctionsClientServer.SubstituteParametersToString("Intervals[%1].EndTime", RowIndex), ,
					Cancel);
			EndIf;
			If ScheduleString.BeginTime = ScheduleString.EndTime Then
				CommonClientServer.MessageToUser(
					NStr("vi = 'Thời gian của khoảng thời gian chưa xác định';
						|ru = 'Длительность интервала не определена';
						|en = 'The interval length is not specified.'; fa = 'The interval length is not specified.';
						|it = 'Durata dell''intervallo non definita';
						|pl = 'Czas trwania interwału nie został określony';
						|tr = 'Aralık süresi tanımlanmadı'"), ,
					StringFunctionsClientServer.SubstituteParametersToString("Intervals[%1].EndTime", RowIndex), ,
					Cancel);
			EndIf;
			If EndDay <> Undefined Then
				If EndDay > ScheduleString.BeginTime 
					Or Not ValueIsFilled(EndDay) Then
					CommonClientServer.MessageToUser(
						NStr("vi = 'Tìm thấy khoản thời gian chồng chéo';
							|ru = 'Обнаружены пересекающиеся интервалы';
							|en = 'Overlapping intervals are detected.'; fa = 'Overlapping intervals are detected.';
							|it = 'Rilevati intervalli sovrapposti';
							|pl = 'Znaleziono pokrywające się interwały';
							|tr = 'Çakışan aralıklar tespit edildi'"), ,
						StringFunctionsClientServer.SubstituteParametersToString("Intervals[%1].BeginTime", RowIndex), ,
						Cancel);
				EndIf;
			EndIf;
			EndDay = ScheduleString.EndTime;
			
			Duration = ProductionManagementClientServer.DurationOfScheduleInterval(
				ScheduleString.BeginTime, ScheduleString.EndTime);
			
			DaySchedule.Add(New Structure("BeginTime, EndTime, Duration", 
									ScheduleString.BeginTime, ScheduleString.EndTime, Duration));
		EndDo;
	EndIf;
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	Return DaySchedule;
	
EndFunction

&AtServer
Function ScheduleAsOfScheduleDate(WorkCenter, Shift, ScheduleDate)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	AvailabilityOfWorkCentersIntervals.BeginTime AS BeginTime,
	|	AvailabilityOfWorkCentersIntervals.EndTime AS EndTime,
	|	AvailabilityOfWorkCentersIntervals.Count
	|FROM
	|	Document.AvailabilityOfWorkCenters.Intervals AS AvailabilityOfWorkCentersIntervals
	|WHERE
	|	AvailabilityOfWorkCentersIntervals.Ref.Posted
	|	AND AvailabilityOfWorkCentersIntervals.WorkCenter = &WorkCenter
	|	AND AvailabilityOfWorkCentersIntervals.Shift = &Shift
	|	AND AvailabilityOfWorkCentersIntervals.ScheduleDate = &ScheduleDate
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("WorkCenter", WorkCenter);
	Query.SetParameter("Shift", Shift);
	Query.SetParameter("ScheduleDate", ScheduleDate);
	
	ScheduleAsOfScheduleDate = Query.Execute().Unload();

	Return ScheduleAsOfScheduleDate;

EndFunction

&AtClientAtServerNoContext
Procedure FillInTotalTime(Form)
	
	Seconds = 0;
	For Each String In Form.Intervals Do
		Seconds = Seconds + ProductionManagementClientServer.DurationOfScheduleInterval(
			String.BeginTime, String.EndTime);
	EndDo;
	
	Hours = Round(Seconds / 3600, 1);
	
	Form.Items.TotalTime.Title = StrTemplate(NStr("vi = 'Tổng số: %1 giờ';
													|ru = 'Всего: %1 ч.';
													|en = 'Total: %1 h.'; fa = 'Total: %1 h.';
													|it = 'Всего: %1 ч.';
													|pl = 'Total: %1 h.';
													|tr = 'Tümü: %1 s.'"), Hours);
	
EndProcedure

#EndRegion
