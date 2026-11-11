
#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ModifyFormElementsWhenCreating();
	
	RestoreFormSettingsWhenCreating();
	
	ReadFormParametersWhenCreating();
	
	MarkPeriodicityButtons();
	
	DisplayScheduleWhenCreatedOnServer();
	
	AvailabilityControl(ThisObject);
	
	Items.FormPages.CurrentPage = Items.SchedulePage;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If StartAwaitingBackgroundOperationOnOpening Then
		
		AttachIdleHandler("StartWaitingForBackgroundOperation", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If TheCalculationIsPerformed Then
		ProcessCalculationResultsBeforeClosing(Cancel, StandardProcessing);
	Else
		DeleteSimulationResultsAndScheduleLocks();
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
Procedure DepartmentOnChange(Item)
	
	AvailabilityControl(ThisObject);
	
	ProductionStages.Clear();
	References.Clear();
	
	SaveFormSettings();
	ProcessSelectionChange();
	
EndProcedure

&AtClient
Procedure StagesWhenChanging(Item)
	
	ProcessSelectionChange();
	
EndProcedure

&AtClient
Procedure StagesStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("StagesStartOfSelectionCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Department", Department);
	FormParameters.Insert("References", References.UnloadValues());
	FormParameters.Insert("Stages", ProductionStages.UnloadValues());
	
	OpenForm("DataProcessor.ManufacturingExecutionSystem2_2.Form.SelectStages",
		FormParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure
	
&AtClient
Procedure StagesStartOfSelectionCompletion(ClosingResult, AdditionalParameters) Export
	
	If Not ClosingResult = Undefined Then
		
		ProductionStages.LoadValues(ClosingResult);
		ProcessSelectionChange();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReferencesOnChange(Item)
	
	ProcessSelectionChange();
	
EndProcedure

&AtClient
Procedure ReferencesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;	
	If Not CheckFilling() Then	
		Return;	
	EndIf;
	
	CallbackDescription = New CallbackDescription("ReferencesStartChoiceCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("References", References.UnloadValues());
	
	OpenForm("DataProcessor.ManufacturingExecutionSystem2_2.Form.SelectReferences",
		FormParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ReferencesStartChoiceCompletion(ClosingResult, AdditionalParameters) Export
	
	If Not ClosingResult = Undefined Then
		
		ProductionStages.Clear();
		References.LoadValues(ClosingResult);
		ProcessSelectionChange();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTimetableIssues

&AtClient
Procedure TimetableIssuesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	RowData = TimetableIssues.FindByID(RowSelected);
	
	If RowData.Category = PredefinedValue(
		"Enum.IssueCategoriesOfOperationTimetable.OperationDurationIsNotSet") Then
		
		If TypeOf(RowData.Properties) = Type("Structure")
			And RowData.Properties.Property("ProductionStage") Then
			ShowValue(, RowData.Properties.ProductionStage);
		EndIf;
		
	ElsIf RowData.Category = PredefinedValue(
		"Enum.IssueCategoriesOfOperationTimetable.WorkCenterIsUnavailable") Then
		
		If TypeOf(RowData.Properties) = Type("Structure")
			And RowData.Properties.Property("WorkCenterType")
			And RowData.Properties.Property("Period") Then
			
			FormParameters = New Structure;
			FormParameters.Insert("WorkCenterType", RowData.Properties.WorkCenterType);
			FormParameters.Insert("BeginOfPeriod", RowData.Properties.Period);
			FormParameters.Insert("WorkMode", PredefinedValue("Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable"));
			OpenForm("DataProcessor.AvailabilityOfWorkCenterTypes.Form", FormParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForGanttChartElements

&AtClient
Procedure GanttChartDetailProcessing(Item, Decryptions, StandardProcessing, Date)
	
	If TypeOf(Decryptions) = Type("CatalogRef.MESModels")
		And ValueIsFilled(Decryptions)
		And ScheduleRecordingIsAcceptable() Then
		
		DecryptPlanningModel(Decryptions, StandardProcessing);
		
	ElsIf TypeOf(Decryptions) = Type("Array")
		And TypeOf(Decryptions[1]) = Type("Structure")
		And Decryptions[1].Property("ParallelLoad")
		And Decryptions[1].ParallelLoad Then
		
		FormParameters = Decryptions[1];
		FormParameters.Insert("SelectionPeriodStart", Period.StartDate);
		FormParameters.Insert("SelectionPeriodEnd", Period.EndDate);
		
		If ValueIsFilled(Department) Then
			Departments = New Array;
			Departments.Add(Department);
			FormParameters.Insert("Departments", Departments);
		EndIf;
		
		ProductionManagementWhenPlanningClient.ProcessingIntervalDecryptionWithParallelLoading(
			ThisObject, Decryptions[1], StandardProcessing);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	DisplaySchedule();
	
EndProcedure

&AtClient
Procedure CalculateASchedule(Command)
	
	CallbackDescription = New CallbackDescription("SelectionOfCalculationParametersCompletion", ThisForm);
	
	FormParameters = New Structure("UUID, Department, References, ProductionStages");
	FillPropertyValues(FormParameters, ThisObject);
	
	OpenForm("DataProcessor.ManufacturingExecutionSystem2_2.Form.CalculationParameters",
				 FormParameters,
				 ThisForm,
				 ,
				 ,
				 ,
				 CallbackDescription,
				 FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WriteScheduleCommand(Command)
	
	If ScheduleRecordingIsAcceptable() Then
		
		RecordASchedule(False);
		
	EndIf;
	
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

&AtClient
Procedure TimetableAnalysis(Command)
	
	FilterParameters = New Structure;
	FilterParameters.Insert("TimetableModel", TimetableModel);
	FilterParameters.Insert("OptimumPlanningModel", OptimumPlanningModel);
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Filter", FilterParameters);
	ReportParameters.Insert("GenerateOnOpen", True);
	
	OpenForm("Report.AnalysisOfOperationTimetable2_2.Form", ReportParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure ShowHideScheduleIssues(Command)
	
	If Items.FormPages.CurrentPage = Items.SchedulePage Then
		Items.FormPages.CurrentPage = Items.TheIssuesPageOfTheSchedule;
	Else
		Items.FormPages.CurrentPage = Items.SchedulePage;
	EndIf;
	
	SetCommandTitleShowHideProblems(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateOperationStatus(Command)
	
	Result = UpdateStatusOfOperationsInBackground();
	FillInBackgroundOperationDetails(Result);
	
	If Result.Status = "Completed2" Then
		UpdatingStatusOfOperationsInBackgroundHasBeenCompleted();
	Else
		StartWaitingForBackgroundOperation();
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
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
	Result.Insert("Periodicity");
	Result.Insert("Department");
	
	Return Result;
	
EndFunction

&AtServer
Function ObjectKeySettingsManager()
	
	Return "ManufacturingExecutionSystem2_2";
	
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
	
	Items.FormSetTheDayPeriod.Check = TaggingDay;
	Items.FormSetThePeriodWeek.Check = TagWeek;
	Items.FormToSetThePeriodOfAMonth.Check = MarkMonth;
	
EndProcedure

&AtServer
Procedure SetPeriodicity()
	
	OutputParameters = ScheduleOutputParameters();
	Reports.OperationTimetableChart2_2.SetPeriodicity(OutputParameters, GanttChart);
	
EndProcedure

&AtServer
Procedure DisplayScheduleWhenCreatedOnServer()
	
	If ValueIsFilled(Department) Then
		
		Result = DisplayScheduleInBackground();
		
		If Result.Status = "Completed2" Then
			
			StartAwaitingBackgroundOperationOnOpening = False;
			
			ReadScheduleOutputResultInBackground(GanttChart, Result.ResultAddress);
			
		Else
			
			StartAwaitingBackgroundOperationOnOpening = True;
			
			BackgroundJobResult = Result;
			StorageAddressBackgroundOperation = Result.ResultAddress;
			JobID = Result.JobID;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DisplaySchedule()
	
	If CheckFilling() Then
		
		Result = DisplayScheduleInBackground();
		FillInBackgroundOperationDetails(Result);
		
		If Result.Status = "Completed2" Then
			FinishedDisplayingScheduleInBackground();
		Else
			StartWaitingForBackgroundOperation();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function DisplayScheduleInBackground()
	
	JobParameters = New Structure;
	JobParameters.Insert("Parameters", ScheduleOutputParameters());
	JobParameters.Insert("GanttChart", GanttChart);
	
	CurrentBackgroundOperation = "ScheduleOutput";
	JobDescription = NStr("vi = 'Hiển thị lịch';
							|ru = 'Вывод расписания';
							|en = 'Display schedule'; fa = 'Display schedule';
							|it = 'Visualizzazione dell''orario';
							|pl = 'Wyświetlenie harmonogramu';
							|tr = 'Çizelge çıktısı'");
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = JobDescription;
		
	CalculationResult2 = TimeConsumingOperations.ExecuteInBackground(
		"Reports.OperationTimetableChart2_2.DisplayScheduleInBackground",
		JobParameters,
		ExecutionParameters);
	
	Return CalculationResult2;
	
EndFunction

&AtClient
Procedure FinishedDisplayingScheduleInBackground()
	
	ReadScheduleOutputResultInBackground(GanttChart, StorageAddressBackgroundOperation);
	
EndProcedure

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
	
	If OutputParameters.Property("Departments") Then
		OutputParameters.Departments.Add(Department);
	EndIf;
	
	OutputParameters.Begin = Period.StartDate;
	OutputParameters.Ending = Period.EndDate;
	
	Return OutputParameters;
	
EndFunction

&AtServer
Procedure MarkOptimalModel()
	
	Reports.OperationTimetableChart2_2.LabelOptimalModel(
		GanttChart, OptimumPlanningModel);
	
EndProcedure

#EndRegion

#Region CalculateTimetable

&AtClient
Procedure SelectionOfCalculationParametersCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined
		Or Not IsTempStorageURL(ClosingResult) Then
		Return;
	EndIf;
	
	Result = PerformCalculationInBackground(ClosingResult);
	FillInBackgroundOperationDetails(Result);
	
	If Result.Status = "Completed2" Then
		CalculationOfScheduleInBackgroundIsCompleted();
	Else
		StartWaitingForBackgroundOperation();
	EndIf;
	
EndProcedure

&AtServer
Function PerformCalculationInBackground(AddressTaskParameters)
	
	DeleteSimulationResultsAndScheduleLocks();
	ClearCalculationResultsStore(ThisObject);
	
	JobParameters = GetFromTempStorage(AddressTaskParameters);
	
	CurrentBackgroundOperation = "CalculateTimetable";
	JobDescription = NStr("vi = 'Tính toán tiến độ sản xuất';
							|ru = 'Расчет пооперационного расписания производства';
							|en = 'Calculate operation production timetable'; fa = 'Calculate operation production timetable';
							|it = 'Calcolo dell''orario di produzione per operazioni consecutive';
							|pl = 'Obliczanie pooperacyjnego harmonogramu produkcji';
							|tr = 'Üretim yürütme programının hesaplanması'");
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = JobDescription;
		
	CalculationResult2 = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ManufacturingExecutionSystem2_2.CalculateASchedule",
		JobParameters,
		ExecutionParameters);
	
	Return CalculationResult2;
	
EndFunction

&AtClient
Procedure CalculationOfScheduleInBackgroundIsCompleted()
	
	CalculationResultStorageAddress = StorageAddressBackgroundOperation;
	
	ReadCalculationResults();
	
	SetAvailabilityOfRecordScheduleCommand();
	SetVisibilityOfScheduleAnalysisCommand();
	RemoveScheduleLocksWhenCalculationIsComplete();
	SetTeamVisibilityShowHideScheduleIssues(ThisObject);
	
	ReportScheduleCalculation();
	
	DisplaySchedule();
	
EndProcedure

&AtClient
Procedure ReportScheduleCalculation()
	
	If TheCalculationIsPerformed Then
		
		NotificationText1 = NStr("vi = 'Lịch trình tính toán hoàn thành.';
								|ru = 'Расчет расписания завершен.';
								|en = 'Timetable calculation is completed.'; fa = 'Timetable calculation is completed.';
								|it = 'Il calcolo dell''orario è terminato.';
								|pl = 'Obliczanie harmonogramu zostało zakończone.';
								|tr = 'Çizelgenin hesaplanması tamamlandı.'");
		Picture = PictureLib.Information32;
		
	Else
		
		NotificationText1 = NStr("vi = 'Lịch trình tính toán thất bại.';
								|ru = 'Расчет расписания не выполнен.';
								|en = 'Timetable is not estimated.'; fa = 'Timetable is not estimated.';
								|it = 'Il calcolo dell''orario non è terminato.';
								|pl = 'Obliczanie harmonogramu nie zostało wykonane.';
								|tr = 'Çizelgenin hesaplanması gerçekleştirilmedi.'");
		Picture = PictureLib.Error32;
		
	EndIf;
	
	ErrorsDetected = Not(TimetableIssues.Count()=0);
	If ErrorsDetected Then
		
		Explanation = StrTemplate(
			NStr("vi = 'Trong quá trình tính toán, các cảnh báo đã xảy ra (%1).';
				|ru = 'В процессе расчета возникли предупреждения (%1).';
				|en = 'Warnings (%1) occurred during the estimation.'; fa = 'Warnings (%1) occurred during the estimation.';
				|it = 'Durante il calcolo si sono verificati gli avvisi (%1).';
				|pl = 'W procesie obliczania wynikły ostrzeżenia (%1).';
				|tr = 'Hesaplama sürecinde uyarılar oluştu (%1).'"),
			TimetableIssues.Count());
		
	Else
		Explanation = "";
	EndIf;
	
	ShowUserNotification(NotificationText1,, Explanation, Picture);
	
EndProcedure

&AtClient
Procedure NotifyAboutScheduleCalculation()
	
	Notify(ProductionManagementWhenPlanningClient.NameOfEventChangingOperationalSchedule());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfRecordScheduleCommand()
	
	If ScheduleRecordingIsAcceptable() Then
		Modified = True;
		Items.FormRecordASchedule.Enabled = True;
	Else
		Modified = False;
		Items.FormRecordASchedule.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfScheduleAnalysisCommand()
	
	Items.FormTimetableAnalysis.Visible = TheCalculationIsPerformed;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetTeamVisibilityShowHideScheduleIssues(Form)
	
	DisplayCommand = ValueIsFilled(Form.TimetableIssues);
	Form.Items.ShowHideScheduleIssues.Visible = DisplayCommand;
	If DisplayCommand Then
		SetCommandTitleShowHideProblems(Form);
	EndIf;
	
EndProcedure

&AtClient
Procedure RemoveScheduleLocksWhenCalculationIsComplete()
	
	If Not ScheduleRecordingIsAcceptable() Then
		RemoveScheduleLocks();
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadCalculationResults()
	
	TimetableModel = CalculationResultByName(
		CalculationResultStorageAddress,
		"TimetableModel",
		New UUID("00000000-0000-0000-0000-000000000000"));
		
	DepartmentCalculation = CalculationResultByName(
		CalculationResultStorageAddress,
		"Department",
		Catalogs.BusinessStructure.EmptyRef());
	
	TheCalculationIsPerformed = CalculationResultByName(
		CalculationResultStorageAddress,
		"TheCalculationIsPerformed",
		False);
		
	ScenariosAreUsed = CalculationResultByName(
		CalculationResultStorageAddress,
		"ScenariosAreUsed",
		False);
	
	If TheCalculationIsPerformed Then
		
		OptimumPlanningModel = CalculationResultByName(CalculationResultStorageAddress,
			"OptimumPlanningModel",
			PredefinedValue("Catalog.MESModels.EmptyRef"));
		
	EndIf;
	
	ReadScheduleIssues();
	
EndProcedure

&AtServer
Procedure ReadScheduleIssues()
	
	If ValueIsFilled(TimetableModel) Then
		
		ResultOfProblem = CalculationResultByName(CalculationResultStorageAddress, "TimetableIssues", Undefined);
		
		If ValueIsFilled(ResultOfProblem) Then
			
			NumberOfLines_1 = 1;
			For Each String In ResultOfProblem Do
				NewRow = TimetableIssues.Add();
				FillPropertyValues(NewRow, String);
				NewRow.LineNumber = NumberOfLines_1;
				
				NumberOfLines_1 = NumberOfLines_1 + 1;
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CalculationResultByName(StorageAddress, PropertyName, DefaultValue = Undefined)
	
	If IsTempStorageURL(StorageAddress) Then
		CalculationResult2 = GetFromTempStorage(StorageAddress);
		If TypeOf(CalculationResult2) = Type("Structure") Then
			If CalculationResult2.Property(PropertyName) Then
				Return CalculationResult2[PropertyName];
			Else
				Return DefaultValue;
			EndIf;
		Else
			Return DefaultValue;
		EndIf;
	Else
		Return DefaultValue;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Procedure ClearCalculationResultsStore(Form)

	Form.CalculationResultStorageAddress = "";
	Form.OptimumPlanningModel = Undefined;
	
	Form.TimetableModel = Undefined;
	Form.DepartmentCalculation = Undefined;
	Form.TheCalculationIsPerformed = False;
	Form.ScenariosAreUsed = False;
	
	Form.TimetableIssues.Clear();
	Form.Items.FormPages.CurrentPage = Form.Items.SchedulePage;
	
	SetTeamVisibilityShowHideScheduleIssues(Form);
	
EndProcedure

&AtServerNoContext
Procedure DeleteSimulationResults(TimetableModel)
	
	If ValueIsFilled(TimetableModel) Then
		InformationRegisters.PostOperativeSchedule2_2.ClearScheduleScheduleModel(TimetableModel);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessCalculationResultsBeforeClosing(Cancel, StandardProcessing)
	
	If ScheduleRecordingIsAcceptable() Then
		
		If Not ClosingInProgress Then
			
			Cancel = True;
			
			CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
			QueryText = NStr("vi = 'Dữ liệu đã được thay đổi. Ghi nhận thay đổi?';
							|ru = 'Данные были изменены. Записать изменения?';
							|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
							|it = 'I dati sono stati modificati. Registrare le modifiche?';
							|pl = 'Dane zostały zmienione. Zapisać zmiany?';
							|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
			Buttons = QuestionDialogMode.YesNoCancel;
			DefaultButton = DialogReturnCode.Cancel;
			
			ShowQueryBox(CallbackDescription, QueryText, Buttons,, DefaultButton);
			
		EndIf;
		
	Else
		
		DeleteSimulationResultsAndScheduleLocks();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(ClosingResult, AdditionalParameters) Export
	
	TheUserResponse = ClosingResult;
	
	If TheUserResponse = DialogReturnCode.Yes Then
		
		RecordASchedule(True);
		
	ElsIf TheUserResponse = DialogReturnCode.No Then
		
		DeleteSimulationResultsAndScheduleLocks();
		
		ClosingInProgress = True;
		Close();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region WriteTimetable

&AtClient
Procedure RecordASchedule(WriteBeforeClosing)
	
	// The mechanism of recording (saving the schedule)
	WriteATimetableBeforeClosing = WriteBeforeClosing;
	
	Result = RecordScheduleInBackground();
	FillInBackgroundOperationDetails(Result);
	
	If Result.Status = "Completed2" Then
		FinishedRecordingScheduleInBackground();
	Else
		If WriteBeforeClosing Then
			AttachIdleHandler("StartWaitingForBackgroundOperation", 0.1, True);
		Else
			StartWaitingForBackgroundOperation();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function RecordScheduleInBackground()
	
	// The mechanism of recording (saving the schedule)
	JobParameters = New Structure;
	JobParameters.Insert("TimetableModel", TimetableModel);
	JobParameters.Insert("PlanningModel", OptimumPlanningModel);
	
	CurrentBackgroundOperation = "WriteTimetable";
	JobDescription = NStr("vi = 'Ghi lại lịch trình';
							|ru = 'Запись расписания';
							|en = 'Write timetable'; fa = 'Write timetable';
							|it = 'La registrazione dell''orario';
							|pl = 'Zapis harmonogramu';
							|tr = 'Çizelge kaydı'");
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = JobDescription;
		
	CalculationResult2 = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ManufacturingExecutionSystem2_2.RecordScheduleInBackground",
		JobParameters,
		ExecutionParameters);
	
	Return CalculationResult2;
	
EndFunction

&AtClient
Function ScheduleRecordingIsAcceptable()
	
	Return ValueIsFilled(TimetableModel) And TheCalculationIsPerformed And Not ScenariosAreUsed;
	
EndFunction

&AtClient
Procedure FinishedRecordingScheduleInBackground()
	
	If IsTempStorageURL(StorageAddressBackgroundOperation) Then
		
		WritingCompleted = GetFromTempStorage(StorageAddressBackgroundOperation);
		
		If TypeOf(WritingCompleted) = Type("Boolean") And WritingCompleted Then
			
			RemoveScheduleLocks();
			
			ClearCalculationResultsStore(ThisObject);
			
			NotifyAboutScheduleCalculation();
			SetAvailabilityOfRecordScheduleCommand();
			SetVisibilityOfScheduleAnalysisCommand();
			
			If WriteATimetableBeforeClosing Then
				ClosingInProgress = True;
				Close();
			Else
				ReportScheduleEntry();
				DisplaySchedule();
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportScheduleEntry()
	
	TitleText = NStr("vi = 'Lịch trình ghi';
					|ru = 'Расписание записано';
					|en = 'Timetable is written'; fa = 'Timetable is written';
					|it = 'L''orario è registrato';
					|pl = 'Harmonogram został zapisany';
					|tr = 'Çizelge kaydedildi'");
	ShowUserNotification(TitleText,,, PictureLib.Information32);
	
EndProcedure

#EndRegion

#Region PerformingOperationsInBackground

&AtClient
Procedure FillInBackgroundOperationDetails(Result)
	
	StorageAddressBackgroundOperation = Result.ResultAddress;
	JobID = Result.JobID;
	BackgroundJobResult = Result;
	
EndProcedure

&AtClient
Procedure StartWaitingForBackgroundOperation()
	
	EnableHandlerForWaitingForBackgroundOperation();
	
EndProcedure

&AtClient
Procedure EnableHandlerForWaitingForBackgroundOperation()
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackOnCompletion = New CallbackDescription("ProcessBackgroundTaskNotification", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJobResult, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure ProcessBackgroundTaskNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Canceled" Then
		If CurrentBackgroundOperation = "CalculateTimetable" Then
				// It is possible that the task was canceled by the user and outdated entries remained in the lock register.
				RemoveScheduleLocksOnServer();
			EndIf;
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		If CurrentBackgroundOperation = "CalculateTimetable" Then
			CalculationOfScheduleInBackgroundIsCompleted();
		ElsIf CurrentBackgroundOperation = "ScheduleOutput" Then
			FinishedDisplayingScheduleInBackground();
		ElsIf CurrentBackgroundOperation = "WriteTimetable" Then
			FinishedRecordingScheduleInBackground();
		ElsIf CurrentBackgroundOperation = "UpdateOperationStatus" Then
			UpdatingStatusOfOperationsInBackgroundHasBeenCompleted();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	If Not ValueIsFilled(Form.Department) Then
		OperationsNeedToBeUpdated = False;
	Else
		OperationsNeedToBeUpdated = ManagementMethodIsChanged(Form.Department);
	EndIf;
	
	Form.Items.FormCalculateASchedule.Enabled = Not OperationsNeedToBeUpdated;
	Form.Items.FormRecordASchedule.Enabled = Not OperationsNeedToBeUpdated;
	Form.Items.GroupToUpdateTheStatusOfOperations.Visible = OperationsNeedToBeUpdated;
	
EndProcedure

&AtServerNoContext
Function ManagementMethodIsChanged(Department)
	
	Return InformationRegisters.BlockingOperationalSchedule2_2.DivisionScheduleBlocked(
		Department, Enums.ReasonsForOperationTimetableLocks.ManagementMethodIsChanged);
	
EndFunction

&AtServer
Procedure ReadFormParametersWhenCreating()
	
	If Parameters.Property("Department") Then
		Department = Parameters.Department;
	EndIf;
	
EndProcedure

&AtServer
Procedure ModifyFormElementsWhenCreating()
	
	Reports.OperationTimetableChart2_2.AddChartNotationToForm(ThisForm, True, True);
	
EndProcedure

&AtClient
Procedure DecryptPlanningModel(Details, StandardProcessing)
	
	StandardProcessing = False;
	
	AdditionalActions = New ValueList;
	
	ActionInstall = NStr("vi = 'Đặt làm mô hình tối ưu';
						|ru = 'Установить в качестве оптимальной модели';
						|en = 'Set as an optimal model'; fa = 'Set as an optimal model';
						|it = 'Impostare come modello ottimale';
						|pl = 'Ustawić jako optymalny model';
						|tr = 'Optimum model olarak yapılandır'");
	AdditionalActions.Add("InstallApp", ActionInstall);
	
	OpenAction = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Mở ""%1""';
			|ru = 'Открыть ""%1""';
			|en = 'Open ""%1""'; fa = 'Open ""%1""';
			|it = 'Aprire ""%1""';
			|pl = 'Otwórz ""%1""';
			|tr = 'Aç ""%1""'"), ObjectAttributeValue(Details, "Description"));
	AdditionalActions.Add("OpenValue", OpenAction);
	
	Notification = New CallbackDescription("SelectingDecryptionActionOfPlanningModelCompletion", ThisObject, Details);
	AdditionalActions.ShowChooseItem(Notification, NStr("vi = 'Chọn hiệu lực';
														|ru = 'Выбор действия';
														|en = 'Select action'; fa = 'انتخاب اقدام';
														|it = 'Scelta dell''azione';
														|pl = 'Wybór czynności';
														|tr = 'Eylem seçimi'"));
	
EndProcedure

&AtClient
Procedure SelectingDecryptionActionOfPlanningModelCompletion(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement = Undefined Then
		
		Return;
		
	ElsIf SelectedElement.Value = "OpenValue" Then
		
		OpenForm("Catalog.MESModels.ObjectForm", New Structure("Key", AdditionalParameters));		
		
	ElsIf SelectedElement.Value = "InstallApp" Then
		
		OptimumPlanningModel = AdditionalParameters;
		MarkOptimalModel();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ObjectAttributeValue(Ref, AttributeName)
	
	Return (Common.ObjectAttributeValue(Ref, AttributeName));
	
EndFunction

&AtClientAtServerNoContext
Procedure SetCommandTitleShowHideProblems(Form)
	
	If Form.Items.FormPages.CurrentPage = Form.Items.SchedulePage Then
		CommandTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hiển thị cảnh báo (%1) >>';
				|ru = 'Показать предупреждения (%1) >>';
				|en = 'Show warnings (%1) >>'; fa = 'Show warnings (%1) >>';
				|it = 'Visualizzare avvisi (%1) >>';
				|pl = 'Pokaż ostrzeżenia (%1) >>';
				|tr = 'Uyarıları göster (%1) >>'"), Form.TimetableIssues.Count());
	Else
		CommandTitle = NStr("vi = '<< Quay lại lịch trình';
							|ru = '<< Назад к расписанию';
							|en = '<< Back to the timetable'; fa = '<< Back to the timetable';
							|it = '<< Indietro all''orario';
							|pl = '<< Powrót do harmonogramu';
							|tr = '<< Çizelgeye geri dön'");
	EndIf;
	
	Form.Items.ShowHideScheduleIssues.Title = CommandTitle;
	
EndProcedure

&AtServer
Procedure RemoveScheduleLocks()
	
	If ValueIsFilled(DepartmentCalculation) Then
		RemoveScheduleLocksOnServer(DepartmentCalculation);
		DepartmentCalculation = Undefined;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure RemoveScheduleLocksOnServer(Department=Undefined)

	SessionNumber = InfoBaseSessionNumber();
	SessionStarted =  SessionStarted();
	
	InformationRegisters.BlockingOperationalSchedule2_2.UnblockScheduleCalculation(SessionNumber, SessionStarted, Department);
	
EndProcedure

&AtServerNoContext
Function SessionStarted()
	
	SessionStarted = '00010101';
	
	SetPrivilegedMode(True);
	Session = GetCurrentInfoBaseSession();
	SetPrivilegedMode(False);
	
	SessionStarted = Session.SessionStarted;
	
	Return SessionStarted;
	
EndFunction

&AtServer
Function UpdateStatusOfOperationsInBackground()
	
	JobParameters = New Structure("Department", Department);
	
	CurrentBackgroundOperation = "UpdateOperationStatus";
	JobDescription = NStr("vi = 'Cập nhật trạng thái hoạt động';
							|ru = 'Актуализация статуса операций';
							|en = 'Update operation status'; fa = 'به‌روزرسانی وضعیت عملیات';
							|it = 'Aggiornamento dello stato di operazioni';
							|pl = 'Aktualizacja statusu operacji';
							|tr = 'İşlem durumunun güncellenmesi'");
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = JobDescription;
		
	CalculationResult2 = TimeConsumingOperations.ExecuteInBackground(
		"InformationRegisters.PostOperativeSchedule2_2.WhenSwitchingFromRegistrationOfDeviationsToRegistrationOfFact",
		JobParameters,
		ExecutionParameters);
	
	Return CalculationResult2;
	
EndFunction

&AtClient
Procedure UpdatingStatusOfOperationsInBackgroundHasBeenCompleted()
	
	AvailabilityControl(ThisObject);
	DisplaySchedule();
	
EndProcedure

&AtServer
Procedure DeleteSimulationResultsAndScheduleLocks()
	
	DeleteSimulationResults(TimetableModel);
	RemoveScheduleLocks();
	
EndProcedure

#EndRegion

ClosingInProgress = False;

#EndRegion
