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
	
	If Parameters.KeyData <> Undefined Then
		RecordKey = InformationRegisters.UserReminders.CreateRecordKey(Parameters.KeyData);
		
		Record = InformationRegisters.UserReminders.CreateRecordManager();
		FillPropertyValues(Record, Parameters.KeyData);
		Record.Read();
		
		OnReadAtServer(Record);
		ValueToFormAttribute(Record, "Object");
	EndIf;
	
	SubsystemSettings = UserRemindersInternal.SubsystemSettings();
	
	Object.User = Users.CurrentUser();
	
	If ValueIsFilled(Parameters.Source) Then 
		Object.Source = Parameters.Source;
		Object.LongDesc = Common.SubjectString(Object.Source);
	EndIf;
	
	If Parameters.KeyData <> Undefined Then
		InitialParameters = New Structure("User,EventTime,Source");
		FillPropertyValues(InitialParameters, Parameters.KeyData);
		InitialParameters = New FixedStructure(InitialParameters);
	ElsIf Parameters.Property("Key") Then
		InitialParameters = New Structure("User,EventTime,Source");
		FillPropertyValues(InitialParameters, Parameters.Key);
		InitialParameters = New FixedStructure(InitialParameters);
	EndIf;
	
	If ValueIsFilled(Object.Source) Then
		FillSourceAttributesList();
	EndIf;
	
	FillPeriodicityOptions();
	DetermineSelectedPeriodicityOption();	
	
	IsNew = Not ValueIsFilled(Object.SourceRecordKey);
	Items.Dismiss.Visible = Not IsNew;
	
	If UserRemindersClientServer.IsMessageURL(Object.Id) Then
		Items.Text.Visible = False;
		Items.Message.Visible = True;
		MessageID = New CollaborationSystemMessageID(StrReplace(Object.Id, "e1ccs/data/msg?id=",""));
		Message = CollaborationSystem.GetMessage(MessageID);
		Author = CollaborationSystem.GetUser(Message.Author);
		
		If BegOfDay(Message.Date) = BegOfDay(CurrentSessionDate()) Then
			DataAsText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'hôm nay, %1';
																						|ru = 'сегодня %1';
																						|en = 'today %1'; fa = 'today %1';
																						|it = 'сегодня %1';
																						|pl = 'today %1';
																						|tr = 'bugün %1'"), Format(Message.Date, NStr("vi = 'ДФ=ЧЧ:мм';
																																	|ru = 'ДФ=HH:mm';
																																	|en = 'DF=HH:mm'; fa = 'DF=HH:mm';
																																	|it = 'ДФ=ЧЧ:мм';
																																	|pl = 'DF=HH:mm';
																																	|tr = 'DF=SS:dd'")));
		Else
			DataAsText = Format(Message.Date, NStr("vi = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
													|ru = 'ДФ=dd.MM.yyyy HH:mm';
													|en = 'DF=MM/dd/yyyy HH:mm'; fa = 'DF=MM/dd/yyyy HH:mm';
													|it = 'ДФ=dd.MM.yyyy HH:mm';
													|pl = 'DF=MM/dd/yyyy HH:mm';
													|tr = 'DF=dd.MM.yyyy HH:mm'"));
		EndIf;
		
		MessageDetails = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thông báo từ %1, đã nhận %2';
				|ru = 'Сообщение от %1, полученное %2';
				|en = 'Message from %1 received on %2'; fa = 'Message from %1 received on %2';
				|it = 'Сообщение от %1, полученное %2';
				|pl = 'Message from %1 received on %2';
				|tr = '%1den alınan %2 mesaj'"),
			Author.FullName, DataAsText);
		
		Items.MessageDetails.Title = StringFunctions.FormattedString(MessageDetails);
		
		LinkRepresentation = GetURLsPresentations(CommonClientServer.ValueInArray(Object.Id));
		
		HyperlinkAnchorText = StringFunctionsClientServer.SubstituteParametersToString("<a href=""%1"">%2</a>",
		Object.Id, LinkRepresentation[0].Text);
		Items.RefToMessage.Title = StringFunctions.FormattedString(HyperlinkAnchorText);
		Items.SubjectOf.Visible = False;
	Else
		Items.Message.Visible = False;
		Items.SubjectOf.Visible = ValueIsFilled(Object.Source);
		Items.ReminderSubject.Title = Common.SubjectString(Object.Source);
		If ValueIsFilled(Object.Source) Then
			WindowOptionsKey = "ReminderOnSubject";
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

	Schedule = CurrentObject.Schedule.Get();
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If CurrentObject.ReminderTimeSettingMethod = Enums.ReminderTimeSettingMethods.RelativeToCurrentTime Then
		CurrentObject.EventTime = CurrentSessionDate() + Object.ReminderInterval;
		CurrentObject.ReminderTime = CurrentObject.EventTime;
		CurrentObject.ReminderTimeSettingMethod = Enums.ReminderTimeSettingMethods.AtSpecifiedTime;
	ElsIf CurrentObject.ReminderTimeSettingMethod = Enums.ReminderTimeSettingMethods.RelativeToSubjectTime Then
		DateInSource = Common.ObjectAttributeValue(Object.Source, Object.SourceAttributeName);
		If ValueIsFilled(DateInSource) Then
			DateInSource = CalculateClosestDate(DateInSource);
			CurrentObject.EventTime = DateInSource;
			CurrentObject.ReminderTime = DateInSource - Object.ReminderInterval;
		Else
			CurrentObject.EventTime = '00010101';
		EndIf;
	ElsIf CurrentObject.ReminderTimeSettingMethod = Enums.ReminderTimeSettingMethods.AtSpecifiedTime Then
		CurrentObject.ReminderTime = Object.EventTime;
	ElsIf CurrentObject.ReminderTimeSettingMethod = Enums.ReminderTimeSettingMethods.Periodically Then
		ClosestReminderTime = UserRemindersInternal.NearestEventDateOnSchedule(Schedule);
		If ClosestReminderTime = Undefined Then
			ClosestReminderTime = CurrentSessionDate();
		EndIf;
		CurrentObject.EventTime = ClosestReminderTime;
		CurrentObject.ReminderTime = CurrentObject.EventTime;
	EndIf;
	
	If CurrentObject.ReminderTimeSettingMethod <> Enums.ReminderTimeSettingMethods.Periodically Then
		Schedule = Undefined;
	EndIf;
	
	CurrentObject.Schedule = New ValueStorage(Schedule, New Deflation(9));
	
	RecordSet = InformationRegisters.UserReminders.CreateRecordSet();
	RecordSet.Filter.User.Set(CurrentObject.User);
	RecordSet.Filter.Source.Set(CurrentObject.Source);
	RecordSet.Read();
	If RecordSet.Count() > 0 Then
		BusyTime = RecordSet.Unload(,"EventTime").UnloadColumn("EventTime");
		While BusyTime.Find(CurrentObject.EventTime) <> Undefined Do
			CurrentObject.EventTime = CurrentObject.EventTime + 1;
		EndDo;
	EndIf;
	CurrentObject.WriteDataHistory.AdditionalDataFieldsPresentations.Insert("ShouldDisableClientNotifications", "");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// If this is a new record.
	If Not ValueIsFilled(Object.SourceRecordKey) Then
		If Items.SourceAttributeName.ChoiceList.Count() > 0 Then
			Object.SourceAttributeName = Items.SourceAttributeName.ChoiceList[0].Value;
			Object.ReminderTimeSettingMethod = PredefinedValue("Enum.ReminderTimeSettingMethods.RelativeToSubjectTime");
		EndIf;
		Object.EventTime = CommonClient.SessionDate();
	EndIf;
	
	FillTimeList();
	
	FillNotificationMethods();
	If Items.SourceAttributeName.ChoiceList.Count() = 0 Then
		Items.ReminderTimeSettingMethod.ChoiceList.Delete(Items.ReminderTimeSettingMethod.ChoiceList.FindByValue(GetKeyByValueInMap(GetPredefinedNotificationMethods(),PredefinedValue("Enum.ReminderTimeSettingMethods.RelativeToSubjectTime"))));
	EndIf;		
		
	If Object.ReminderInterval > 0 Then
		TimeIntervalString = UserRemindersClient.TimePresentation(Object.ReminderInterval);
	EndIf;
	
	PredefinedNotificationMethods = GetPredefinedNotificationMethods();
	SelectedMethod = GetKeyByValueInMap(PredefinedNotificationMethods, Object.ReminderTimeSettingMethod);
	
	If Object.ReminderTimeSettingMethod = PredefinedValue("Enum.ReminderTimeSettingMethods.RelativeToCurrentTime") Then
		ReminderTimeSettingMethod = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'sau %1';
				|ru = 'через %1';
				|en = 'in %1'; fa = 'in %1';
				|it = 'fra %1';
				|pl = 'za %1';
				|tr = '%1 içinde'"), UserRemindersClient.TimePresentation(Object.ReminderInterval));
	Else
		ReminderTimeSettingMethod = SelectedMethod;
	EndIf;
	
	SetVisibility1();
	
	UpdateEstimatedReminderTime();
	AttachIdleHandler("UpdateEstimatedReminderTime", 1);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	// For the cache update purposes.
	ParametersStructure = UserRemindersClientServer.ReminderDetails(Object, True);
	ParametersStructure.URL = WriteParameters.URL;
	ParametersStructure.Insert("PictureIndex", 2);
	
	UserRemindersClient.UpdateRecordInNotificationsCache(ParametersStructure);
	
	UserRemindersClient.ResetCurrentNotificationsCheckTimer();
	
	If ValueIsFilled(Object.Source) Then 
		NotifyChanged(Object.Source);
	EndIf;
	
	Notify("Write_UserReminders", ParametersStructure, ThisObject);
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	If InitialParameters <> Undefined Then 
		UserRemindersClient.DeleteRecordFromNotificationsCache(InitialParameters);
	EndIf;
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

	WriteParameters.Insert("URL", 
		UserRemindersInternal.ReminderURL(CurrentObject));
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReminderTimeSettingMethodOnChange(Item)
	ClearMessages();
	
	TimeInterval = UserRemindersClient.GetTimeIntervalFromString(ReminderTimeSettingMethod);
	If TimeInterval > 0 Then
		TimeIntervalString = UserRemindersClient.TimePresentation(TimeInterval);
		ReminderTimeSettingMethod = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'sau %1';
				|ru = 'через %1';
				|en = 'in %1'; fa = 'in %1';
				|it = 'fra %1';
				|pl = 'za %1';
				|tr = '%1 içinde'"), TimeIntervalString);
	Else
		If Items.ReminderTimeSettingMethod.ChoiceList.FindByValue(ReminderTimeSettingMethod) = Undefined Then
			CommonClient.MessageToUser(NStr("vi = 'Chưa xác định khoảng thời gian.';
											|ru = 'Интервал времени не определен.';
											|en = 'Please specify the time interval.'; fa = 'Please specify the time interval.';
											|it = 'L''intervallo di tempo non è definito';
											|pl = 'Przedział czasu nie jest zdefiniowany.';
											|tr = 'Zaman aralığı belirtilmemiş.'"), , "ReminderTimeSettingMethod");
		EndIf;
	EndIf;
	
	PredefinedNotificationMethods = GetPredefinedNotificationMethods();
	SelectedMethod = PredefinedNotificationMethods.Get(ReminderTimeSettingMethod);
	
	If SelectedMethod = Undefined Then
		Object.ReminderTimeSettingMethod = PredefinedValue("Enum.ReminderTimeSettingMethods.RelativeToCurrentTime");
	Else
		Object.ReminderTimeSettingMethod = SelectedMethod;
	EndIf;
	
	Object.ReminderInterval = TimeInterval;
	
	SetVisibility1();		
EndProcedure

&AtClient
Procedure OnChangeTimeInterval(Item)
	Object.ReminderInterval = UserRemindersClient.GetTimeIntervalFromString(TimeIntervalString);
	If Object.ReminderInterval > 0 Then
		TimeIntervalString = UserRemindersClient.TimePresentation(Object.ReminderInterval);
	Else
		CommonClient.MessageToUser(NStr("vi = 'Chưa xác định khoảng thời gian';
										|ru = 'Интервал времени не определен';
										|en = 'Please specify the time interval.'; fa = 'Please specify the time interval.';
										|it = 'L''intervallo di tempo non è definito';
										|pl = 'Przedział czasu nie jest zdefiniowany';
										|tr = 'Zaman aralığı belirtilmemiş.'"), , "TimeIntervalString");
	EndIf;
EndProcedure

&AtClient
Procedure FrequencyOptionOnChange(Item)
	OnChangeSchedule();
EndProcedure

&AtClient
Procedure FrequencyOptionOpening(Item, StandardProcessing)
	StandardProcessing = False;
	OnChangeSchedule();
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	FillTimeList();
EndProcedure

&AtClient
Procedure TimeOnChange(Item)
	Object.EventTime = BegOfMinute(Object.EventTime);
EndProcedure

&AtClient
Procedure ReminderSubjectClick(Item)
	ShowValue(, Object.Source);
EndProcedure

&AtClient
Procedure SourceAttributeNameClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Delete(Command)
	
	DialogButtons = New ValueList;
	DialogButtons.Add(DialogReturnCode.Yes, NStr("vi = 'Ngừng';
												|ru = 'Прекратить';
												|en = 'Dismiss'; fa = 'نادیده‌گرفتن';
												|it = 'Прекратить';
												|pl = 'Dismiss';
												|tr = 'Durdur'"));
	DialogButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Không ngừng';
													|ru = 'Не прекращать';
													|en = 'Not now'; fa = 'اکنون نه';
													|it = 'Не прекращать';
													|pl = 'Not now';
													|tr = 'Durdurma'"));
	
	CallbackDescription = New CallbackDescription("DeleteReminder", ThisObject);
	ShowQueryBox(CallbackDescription, NStr("vi = 'Ngừng nhắc việc';
											|ru = 'Прекратить напоминание?';
											|en = 'Dismiss the reminder?'; fa = 'Dismiss the reminder?';
											|it = 'Прекратить напоминание?';
											|pl = 'Dismiss the reminder?';
											|tr = 'Hatırlatma durdurulsun mu?'"), DialogButtons);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure DeleteReminder(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Modified = False;
		If InitialParameters <> Undefined Then 
			DisableReminder();
			UserRemindersClient.DeleteRecordFromNotificationsCache(InitialParameters);
			Notify("Write_UserReminders", New Structure, Object.SourceRecordKey);
			NotifyChanged(Type("InformationRegisterRecordKey.UserReminders"));
		EndIf;
		If IsOpen() Then
			Close();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure DisableReminder()
	UserRemindersInternal.DisableReminder(InitialParameters, False, True);
EndProcedure

&AtServerNoContext
Function SourceAttributeExistsAndContainsDateType(SourceMetadata, AttributeName, CheckDate1 = False)
	Result = False;
	If SourceMetadata.Attributes.Find(AttributeName) <> Undefined
		And SourceMetadata.Attributes[AttributeName].Type.ContainsType(Type("Date")) Then
			Result = True;
	EndIf;
	Return Result;
EndFunction

&AtClientAtServerNoContext
Function GetKeyByValueInMap(Map, Value)
	Result = Undefined;
	For Each KeyAndValue In Map Do
		If TypeOf(Value) = Type("JobSchedule") Then
			If CommonClientServer.SchedulesAreIdentical(KeyAndValue.Value, Value) Then
		    	Return KeyAndValue.Key;
			EndIf;
		Else
			If KeyAndValue.Value = Value Then
				Return KeyAndValue.Key;
			EndIf;
		EndIf;
	EndDo;
	Return Result;	
EndFunction

&AtClient
Function GetPredefinedNotificationMethods()
	Result = New Map;
	Result.Insert(NStr("vi = 'theo chủ đề';
						|ru = 'относительно предмета';
						|en = 'based on subject'; fa = 'based on subject';
						|it = 'Riguardo l''argomento';
						|pl = 'w odniesieniu do przedmiotu';
						|tr = 'konuya göre'"), 
		PredefinedValue("Enum.ReminderTimeSettingMethods.RelativeToSubjectTime"));
	Result.Insert(NStr("vi = 'trong thời gian đã chỉ ra';
						|ru = 'в указанное время';
						|en = 'at specified time'; fa = 'at specified time';
						|it = 'in un momento specifico';
						|pl = 'o określonym czasie';
						|tr = 'belirli bir zamanda'"), 
		PredefinedValue("Enum.ReminderTimeSettingMethods.AtSpecifiedTime"));
	Result.Insert(NStr("vi = 'định kỳ';
						|ru = 'периодически';
						|en = 'periodically'; fa = 'periodically';
						|it = 'periodicamente';
						|pl = 'periodically';
						|tr = 'periyodik olarak'"), 
		PredefinedValue("Enum.ReminderTimeSettingMethods.Periodically"));
	Return Result;
EndFunction

&AtClient
Procedure FillNotificationMethods()
	NotificationMethods = Items.ReminderTimeSettingMethod.ChoiceList;
	NotificationMethods.Clear();
	For Each Method In GetPredefinedNotificationMethods() Do
		NotificationMethods.Add(Method.Key);
	EndDo;	
	
	Items.RemindBeforeDueTime.ChoiceList.Clear();
	TimeIntervals = SubsystemSettings.StandardIntervals;
	For Each Interval In TimeIntervals Do
		NotificationMethods.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'sau %1';
				|ru = 'через %1';
				|en = 'in %1'; fa = 'in %1';
				|it = 'fra %1';
				|pl = 'po %1';
				|tr = '%1 içinde'"), Interval));
		Items.RemindBeforeDueTime.ChoiceList.Add(Interval);
	EndDo;
EndProcedure

&AtClient
Procedure FillTimeList()
	Items.Time.ChoiceList.Clear();
	For Hour = 0 To 23 Do 
		For Period = 0 To 1 Do
			Time = Hour*60*60 + Period*30*60;
			Date = BegOfDay(Object.EventTime) + Time;
			Items.Time.ChoiceList.Add(Date, Format(Date,"DLF=T;"));
		EndDo;
	EndDo;
EndProcedure

&AtServer
Procedure FillSourceAttributesList()
	
	AttributesWithDates = New Array;
	
	// Populate with default values.
	SourceMetadata = Object.Source.Metadata();	
	For Each Attribute In SourceMetadata.Attributes Do
		If Not StrStartsWith(Lower(Attribute.Name), Lower("Delete"))
			And SourceAttributeExistsAndContainsDateType(SourceMetadata, Attribute.Name) Then
			AttributesWithDates.Add(Attribute.Name);
		EndIf;
	EndDo;
	
	// Get an overridden array of attributes.
	SSLSubsystemsIntegration.OnFillSourceAttributesListWithReminderDates(Object.Source, AttributesWithDates);
	UserRemindersOverridable.OnFillSourceAttributesListWithReminderDates(Object.Source, AttributesWithDates);
	
	Items.SourceAttributeName.ChoiceList.Clear();
	AttributesValues = Common.ObjectAttributesValues(Object.Source, StrConcat(AttributesWithDates, ","));
	
	For Each AttributeName In AttributesWithDates Do
		If SourceAttributeExistsAndContainsDateType(SourceMetadata, AttributeName) Then
			If TypeOf(Object.Source[AttributeName]) = Type("Date") Then
				Attribute = SourceMetadata.Attributes.Find(AttributeName);
				AttributeRepresentation = Attribute.Presentation();
				DateInAttribute = AttributesValues[Attribute.Name];
				NearestDate = CalculateClosestDate(DateInAttribute);
				If ValueIsFilled(NearestDate) And DateInAttribute < CurrentSessionDate() Then
					AttributeRepresentation = AttributeRepresentation + " (" + Format(NearestDate, "DLF=D") + ")";
				EndIf;
				If Items.SourceAttributeName.ChoiceList.FindByValue(AttributeName) = Undefined Then
					Items.SourceAttributeName.ChoiceList.Add(AttributeName, AttributeRepresentation);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillPeriodicityOptions()
	Items.FrequencyOption.ChoiceList.Clear();
	SchedulesList = SubsystemSettings.Schedules1;
	For Each StandardSchedule In SchedulesList Do
		Items.FrequencyOption.ChoiceList.Add(StandardSchedule.Key, StandardSchedule.Key);
	EndDo;
	Items.FrequencyOption.ChoiceList.SortByPresentation();
	Items.FrequencyOption.ChoiceList.Add("", NStr("vi = 'theo lịch biểu đã đặt...';
													|ru = 'по заданному расписанию...';
													|en = 'custom schedule…'; fa = 'custom schedule…';
													|it = 'secondo il programma stabilito...';
													|pl = 'wg ustawionego harmonogramu...';
													|tr = 'belirtilen programda ...'"));	
EndProcedure

&AtClient
Procedure SetVisibility1()
	
	PredefinedNotificationMethods = GetPredefinedNotificationMethods();
	SelectedMethod = PredefinedNotificationMethods.Get(ReminderTimeSettingMethod);
	
	If SelectedMethod <> Undefined Then
		If SelectedMethod = PredefinedValue("Enum.ReminderTimeSettingMethods.AtSpecifiedTime") Then
			Items.DetailedSettingsPanel.CurrentPage = Items.DateTime;
		ElsIf SelectedMethod = PredefinedValue("Enum.ReminderTimeSettingMethods.RelativeToSubjectTime") Then
			Items.DetailedSettingsPanel.CurrentPage = Items.EventAlarmSetting;
		ElsIf SelectedMethod = PredefinedValue("Enum.ReminderTimeSettingMethods.Periodically") Then
			Items.DetailedSettingsPanel.CurrentPage = Items.FrequencySetting;
		EndIf;			
	Else
		Items.DetailedSettingsPanel.CurrentPage = Items.NoDetails;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenScheduleSettingDialog()
	If Schedule = Undefined Then 
		Schedule = New JobSchedule;
		Schedule.DaysRepeatPeriod = 1;
	EndIf;
	ScheduleDialog1 = New ScheduledJobDialog(Schedule);
	CallbackDescription = New CallbackDescription("OpenScheduleSettingDialogCompletion", ThisObject);
	ScheduleDialog1.Show(CallbackDescription);
EndProcedure

&AtClient
Procedure OpenScheduleSettingDialogCompletion(SelectedSchedule, AdditionalParameters) Export
	If SelectedSchedule = Undefined Then
		Return;
	EndIf;
	Schedule = SelectedSchedule;
	If Not ScheduleMeetsRequirements(Schedule) Then 
		ShowMessageBox(, NStr("vi = 'Tính định kỳ trong ngày không được hỗ trợ theo tùy chỉnh đã bị xóa.';
								|ru = 'Периодичность в течение дня не поддерживается, соответствующие настройки очищены.';
								|en = 'Repetition during one day is not supported. The settings are cleared.'; fa = 'Repetition during one day is not supported. The settings are cleared.';
								|it = 'La frequenza durante il giorno non è supportata, le impostazioni corrispondenti sono cancellate.';
								|pl = 'Częstotliwość w ciągu dnia nie jest obsługiwana, odpowiednie ustawienia są kasowane.';
								|tr = 'Günlük sıklık desteklenmiyor. İlgili ayarlar temizlendi.'"));
	EndIf;
	NormalizeSchedule(Schedule);
	DetermineSelectedPeriodicityOption();
EndProcedure

&AtClient
Function ScheduleMeetsRequirements(ScheduleToCheck)
	If ScheduleToCheck.RepeatPeriodInDay > 0 Then
		Return False;
	EndIf;
	
	For Each DaySchedule In ScheduleToCheck.DetailedDailySchedules Do
		If DaySchedule.RepeatPeriodInDay > 0 Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
EndFunction

&AtClient
Procedure NormalizeSchedule(ScheduleToNormalize);
	ScheduleToNormalize.EndTime = '000101010000';
	ScheduleToNormalize.RepeatPeriodInDay = 0;
	ScheduleToNormalize.RepeatPause = 0;
	ScheduleToNormalize.CompletionInterval = 0;
	For Each DaySchedule In ScheduleToNormalize.DetailedDailySchedules Do
		DaySchedule.EndTime = '000101010000';
		DaySchedule.CompletionTime =  DaySchedule.EndTime;
		DaySchedule.RepeatPeriodInDay = 0;
		DaySchedule.RepeatPause = 0;
		DaySchedule.CompletionInterval = 0;
	EndDo;
EndProcedure

&AtServer
Procedure DetermineSelectedPeriodicityOption()
	StandardSchedules = SubsystemSettings.Schedules1;
	
	If Schedule = Undefined Then
		FrequencyOption = Items.FrequencyOption.ChoiceList.Get(0).Value;
		Schedule = StandardSchedules[FrequencyOption];
	Else
		FrequencyOption = GetKeyByValueInMap(StandardSchedules, Schedule);
	EndIf;
	
	Items.FrequencyOption.OpenButton = IsBlankString(FrequencyOption);
	Items.FrequencyOption.ToolTip = Schedule;
EndProcedure

&AtClient
Procedure OnChangeSchedule()
	UserSetting = IsBlankString(FrequencyOption);
	If UserSetting Then
		OpenScheduleSettingDialog();
	Else
		StandardSchedules = SubsystemSettings.Schedules1;
		Schedule = StandardSchedules[FrequencyOption];
	EndIf;
	DetermineSelectedPeriodicityOption();
EndProcedure

&AtServer
Function CalculateClosestDate(SourceDate1)
	CurrentDate = CurrentSessionDate();
	If Not ValueIsFilled(SourceDate1) Or SourceDate1 > CurrentDate Then
		Return SourceDate1;
	EndIf;
	
	Result = AddMonth(SourceDate1, 12 * (Year(CurrentDate) - Year(SourceDate1)));
	If Result < CurrentDate Then
		Result = AddMonth(Result, 12);
	EndIf;
	
	Return Result;
EndFunction

&AtClient
Function EstimatedTimeAsString()
	
	CurrentDate = CommonClient.SessionDate();
	EstimatedReminderTime = CurrentDate + Object.ReminderInterval;
	
	OutputDate = Day(EstimatedReminderTime) <> Day(CurrentDate);
	
	DateAsString = Format(EstimatedReminderTime, "DLF=DD");
	TimeAsString = Format(EstimatedReminderTime, NStr("vi = 'ДФ=Ч:мм';
														|ru = 'ДФ=H:mm';
														|en = 'DF=H:mm'; fa = 'DF=H:mm';
														|it = 'ДФ=Ч:мм';
														|pl = 'DF=H:mm';
														|tr = 'DF=H:mm'"));
	
	Return "(" + ?(OutputDate, DateAsString + " ", "") +  TimeAsString + ")";
	
EndFunction

&AtClient
Procedure UpdateEstimatedReminderTime()
	Items.EstimatedReminderTime.Title = EstimatedTimeAsString();
EndProcedure

#EndRegion
