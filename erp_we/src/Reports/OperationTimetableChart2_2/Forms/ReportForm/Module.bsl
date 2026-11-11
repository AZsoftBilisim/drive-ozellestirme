
#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ModifyFormElementsWhenCreating();
	
	RestoreFormSettingsWhenCreating();
	
	MarkPeriodicityButtons();
	
	DisplayScheduleWhenCreatedOnServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If StartAwaitingBackgroundOperationOnOpening Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackOnCompletion = New CallbackDescription("DisplayScheduleAlert", ThisObject);
	
		TimeConsumingOperationsClient.WaitCompletion(
			BackgroundJobResult, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodOnChange(Item)
	
	SaveFormSettings();
	ProcessSelectionChange();
	
EndProcedure

&AtClient
Procedure DepartmentsOnChange(Item)
	
	SaveFormSettings();
	ProcessSelectionChange();
	
EndProcedure

&AtClient
Procedure ReferencesOnChange(Item)
	
	SaveFormSettings();
	ProcessSelectionChange();
	
EndProcedure

&AtClient
Procedure ProductionStagesOnChange(Item)
	
	SaveFormSettings();
	ProcessSelectionChange();
	
EndProcedure

#EndRegion

#Region EventHandlersForGanttChartElements

&AtClient
Procedure GanttChartDetailProcessing(Item, Decryptions, StandardProcessing, Date)
	
	If TypeOf(Decryptions) = Type("Array")
		And TypeOf(Decryptions[1]) = Type("Structure")
		And Decryptions[1].Property("ParallelLoad")
		And Decryptions[1].ParallelLoad Then
		
		FormParameters = Decryptions[1];
		FormParameters.Insert("SelectionPeriodStart", Period.StartDate);
		FormParameters.Insert("SelectionPeriodEnd", Period.EndDate);
		FormParameters.Insert("Departments", Departments.UnloadValues());
		
		ProductionManagementWhenPlanningClient.ProcessingIntervalDecryptionWithParallelLoading(
			ThisObject, FormParameters, StandardProcessing);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateReport(Command)
	
	DisplaySchedule();
	
EndProcedure

&AtClient
Procedure SetTheDayPeriod(Command)

	SetDayPeriodOnServer();
	
EndProcedure

&AtClient
Procedure SetThePeriodWeek(Command)
	
	SetWeekPeriodOnServer();
	
EndProcedure

&AtClient
Procedure ToSetThePeriodOfAMonth(Command)
	
	SetPeriodMonthOnServer();
	
EndProcedure

#EndRegion

#Region Private

#Region SettingManagement

&AtServer
Procedure RestoreFormSettingsWhenCreating()
	
	FormSettings = FormDataSettingsStorage.Load(
		ObjectKeySettingsManager(), SettingsManagerSettingsKey());
	If ValueIsFilled(FormSettings) Then
		FillPropertyValues(ThisForm, FormSettings);
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveFormSettings()
	
	FormSettings = SavedFormSettings();
	
	FillPropertyValues(FormSettings, ThisForm);
	FormDataSettingsStorage.Save(
		ObjectKeySettingsManager(), SettingsManagerSettingsKey(), FormSettings);
	
EndProcedure

&AtServer
Function SavedFormSettings()
	
	Result = New Structure;
	Result.Insert("Period");
	Result.Insert("Departments");
	Result.Insert("References");
	Result.Insert("ProductionStages");
	Result.Insert("Periodicity");
	
	Return Result;
	
EndFunction

&AtServer
Function ObjectKeySettingsManager()
	
	Return "OperationTimetableChart2_2";
	
EndFunction

&AtServer
Function SettingsManagerSettingsKey()
	
	Return "FormSettings";
	
EndFunction

#EndRegion

#Region ScheduleOutput

&AtClient
Procedure ProcessSelectionChange()
	
	DisplaySchedule();
	
EndProcedure

&AtServer
Procedure SetDayPeriodOnServer()
	
	Periodicity = DataAnalysisTimeIntervalUnitType.Day;
	ProcessChangesInDisplayFrequency();
	
EndProcedure

&AtServer
Procedure SetWeekPeriodOnServer()
	
	Periodicity = DataAnalysisTimeIntervalUnitType.Week;
	ProcessChangesInDisplayFrequency();
	
EndProcedure

&AtServer
Procedure SetPeriodMonthOnServer()
	
	Periodicity = DataAnalysisTimeIntervalUnitType.Month;
	ProcessChangesInDisplayFrequency();
	
EndProcedure

&AtServer
Procedure ProcessChangesInDisplayFrequency()
	
	SaveFormSettings();
	MarkPeriodicityButtons();
	SetPeriodicity();
	
EndProcedure

&AtServer
Procedure MarkPeriodicityButtons()
	
	TaggingDay = False;
	TagWeek = False;
	MarkMonth = False;
	
	If Periodicity = DataAnalysisTimeIntervalUnitType.Day Then
		TaggingDay = True;
	ElsIf Periodicity = DataAnalysisTimeIntervalUnitType.Week Then
		TagWeek = True;
	ElsIf Periodicity = DataAnalysisTimeIntervalUnitType.Month Then
		MarkMonth = True;
	Else
		Periodicity = DataAnalysisTimeIntervalUnitType.Week;
		TagWeek = True;
	EndIf;
	
	Items.SetTheDayPeriod.Check = TaggingDay;
	Items.SetThePeriodWeek.Check = TagWeek;
	Items.ToSetThePeriodOfAMonth.Check = MarkMonth;
	
EndProcedure

&AtServer
Procedure SetPeriodicity()
	
	OutputParameters = ScheduleOutputParameters();
	Reports.OperationTimetableChart2_2.SetPeriodicity(OutputParameters, GanttChart);
	
EndProcedure

&AtServer
Procedure DisplayScheduleWhenCreatedOnServer()
	
	If CheckFilling() Then
		
		BackgroundJobResult = DisplayScheduleInBackground();
		
		If BackgroundJobResult.Status = "Completed2" Then
			StartAwaitingBackgroundOperationOnOpening = False;
			ReadScheduleOutputResultInBackground(GanttChart, BackgroundJobResult.ResultAddress);
		Else
			StartAwaitingBackgroundOperationOnOpening = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DisplaySchedule()
	
	If CheckFilling() Then
		
		BackgroundJobResult = DisplayScheduleInBackground();
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackOnCompletion = New CallbackDescription("DisplayScheduleAlert", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(
			BackgroundJobResult, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DisplayScheduleAlert(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	ReadScheduleOutputResultInBackground(GanttChart, Result.ResultAddress);
	
EndProcedure

&AtServer
Function DisplayScheduleInBackground()
	
	JobParameters = New Structure;
	JobParameters.Insert("Parameters", ScheduleOutputParameters());
	JobParameters.Insert("GanttChart", GanttChart);
	
	JobDescription = NStr("vi = 'Hiển thị lịch';
							|ru = 'Вывод расписания';
							|en = 'Display schedule'; fa = 'Display schedule';
							|it = 'Visualizzazione dell''orario';
							|pl = 'Wyświetlenie harmonogramu';
							|tr = 'Çizelge çıktısı'");
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	
	CalculationResult2 = TimeConsumingOperations.ExecuteInBackground(
		"Reports.OperationTimetableChart2_2.DisplayScheduleInBackground",
		JobParameters,
		ExecutionParameters);
	
	Return CalculationResult2;
	
EndFunction

&AtClientAtServerNoContext
Procedure ReadScheduleOutputResultInBackground(GanttChart, StorageAddress)
	
	If IsTempStorageURL(StorageAddress) Then
		
		GanttChart = GetFromTempStorage(StorageAddress);
	
	EndIf;
	
EndProcedure

&AtServer
Function ScheduleOutputParameters()
	
	OutputParameters = Reports.OperationTimetableChart2_2.OutputParameters();
	FillPropertyValues(OutputParameters, ThisForm);
	
	OutputParameters.Begin = Period.StartDate;
	OutputParameters.Ending = Period.EndDate;
	
	Return OutputParameters;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure ModifyFormElementsWhenCreating()
	
	Reports.OperationTimetableChart2_2.AddChartNotationToForm(ThisForm, True, False);
	
EndProcedure

#EndRegion

#EndRegion
