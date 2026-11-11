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
	ReadParameters_();
	MarkPeriodicityButtons();
	DisplayScheduleWhenCreatedOnServer();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
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
Procedure BeginOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Begin > Ending Then
		Begin = Ending;
	EndIf;
	
	ProcessSelectionChange();
	
EndProcedure

&AtClient
Procedure EndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Ending < Begin Then
		Ending = Begin;
	EndIf;
	
	ProcessSelectionChange();
	
EndProcedure

&AtClient
Procedure DepartmentsOnChange(Item)
	
	ProcessSelectionChange();
	
EndProcedure

&AtClient
Procedure WorkCenterOnChange(Item)
	
	ProcessSelectionChange();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ModifyFormElementsWhenCreating()
	
	Reports.OperationTimetableChart2_2.AddChartNotationToForm(ThisForm, False, False);
	
EndProcedure

Procedure ReadParameters_()
	
	StartParameter = Undefined;
	If Parameters.Property("Begin", StartParameter) Then
		Begin = StartParameter;
	EndIf;
	If Parameters.Property("Ending") Then
		Ending = Parameters.Ending;
	EndIf;
	If Parameters.Property("WorkCenter") Then
		WorkCenter = Parameters.WorkCenter;
	EndIf;
	If Parameters.Property("Departments") Then
		Departments.LoadValues(Parameters.Departments);
	EndIf;
	If Parameters.Property("TimetableModel") Then
		TimetableModel = Parameters.TimetableModel;
	EndIf;
	If Parameters.Property("PlanningModel") Then
		PlanningModel = Parameters.PlanningModel;
	EndIf;
	
	If ((Parameters.Property("SelectionPeriodStart") And ValueIsFilled(Parameters.SelectionPeriodStart))
		Or (Parameters.Property("SelectionPeriodEnd") And ValueIsFilled(Parameters.SelectionPeriodEnd)))
		And ValueIsFilled(Begin) And ValueIsFilled(Ending) Then
		CalculatePeriodForRelatedOperations(Parameters.SelectionPeriodStart, Parameters.SelectionPeriodEnd);
	EndIf;
	
	If BegOfDay(Begin) = BegOfDay(Ending) Then
		Periodicity = DataAnalysisTimeIntervalUnitType.Day;
	ElsIf BegOfWeek(StartParameter) = BegOfWeek(Parameters.Ending) Then
		Periodicity = DataAnalysisTimeIntervalUnitType.Week;
	Else
		Periodicity = DataAnalysisTimeIntervalUnitType.Month;
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculatePeriodForRelatedOperations(SelectionPeriodStart, SelectionPeriodEnd)
	
	TimeIntervals = RelatedOperations_(SelectionPeriodStart, SelectionPeriodEnd);
	
	TheStructureOfTheSearch = New Structure("Begin, Ending", Begin, Ending);
	FoundRows = TimeIntervals.FindRows(TheStructureOfTheSearch);
	If ValueIsFilled(FoundRows) Then
		
		CurrentIndex = TimeIntervals.IndexOf(FoundRows[0]);
		While CurrentIndex > 0 Do
			
			CurrentIndex = CurrentIndex - 1;
			CurrentRow = TimeIntervals[CurrentIndex];//ValueTableRow of See RelatedOperations_ -
			
			If CurrentRow.Ending >= Begin Then
				Begin = Min(Begin, CurrentRow.Begin);
			Else
				Break;
			EndIf;
			
		EndDo;
		
		CurrentIndex = TimeIntervals.IndexOf(FoundRows[0]);
		While CurrentIndex < TimeIntervals.Count()-1 Do
			
			CurrentIndex = CurrentIndex + 1;
			CurrentRow = TimeIntervals[CurrentIndex];//ValueTableRow of See RelatedOperations_ -
			
			If CurrentRow.Begin <= Ending Then
				Ending = Max(Ending, CurrentRow.Ending);
			Else
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Parameters:
// 	SelectionPeriodStart - Date - 
// 	SelectionPeriodEnd - Date - 
// Returns:
// 	ValueTable - Description - where:
// * Begin - Date - 
// * Ending - Date - 
&AtServer
Function RelatedOperations_(SelectionPeriodStart, SelectionPeriodEnd)
	
	Query = New Query(
	"SELECT ALLOWED
	|	PostOperativeSchedule.Begin AS Begin,
	|	PostOperativeSchedule.Ending AS Ending
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|WHERE
	|	PostOperativeSchedule.TimetableModel = &TimetableModel
	|	AND PostOperativeSchedule.PlanningModel = &PlanningModel
	|	AND PostOperativeSchedule.WorkCenter = &WorkCenter
	|	AND (NOT &FilterBegin
	|			OR PostOperativeSchedule.Begin >= &Begin)
	|	AND (NOT &FilterEnding
	|			OR PostOperativeSchedule.Ending <= &Ending)
	|
	|ORDER BY
	|	Begin,
	|	Ending");
	
	Query.SetParameter("TimetableModel", TimetableModel);
	Query.SetParameter("PlanningModel", PlanningModel);
	Query.SetParameter("FilterBegin", ValueIsFilled(SelectionPeriodStart));
	Query.SetParameter("Begin", SelectionPeriodStart);
	Query.SetParameter("FilterEnding", ValueIsFilled(SelectionPeriodEnd));
	Query.SetParameter("Ending", SelectionPeriodEnd);
	Query.SetParameter("WorkCenter", WorkCenter);
	
	Return Query.Execute().Unload();
	
EndFunction

&AtServer
Procedure DisplayScheduleWhenCreatedOnServer()
	
	BackgroundJobResult = DisplayScheduleInBackground();
	
	If BackgroundJobResult.Status = "Completed2" Then
		StartAwaitingBackgroundOperationOnOpening = False;
		ReadScheduleOutputResultInBackground(GanttChart, BackgroundJobResult.ResultAddress);
	Else
		StartAwaitingBackgroundOperationOnOpening = True;
	EndIf;

EndProcedure

&AtClient
Procedure DisplaySchedule()
	
	BackgroundJobResult = DisplayScheduleInBackground();
		
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackOnCompletion = New CallbackDescription("DisplayScheduleAlert", ThisObject);

	TimeConsumingOperationsClient.WaitCompletion(
		BackgroundJobResult, CallbackOnCompletion, IdleParameters);
	
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
	
	JobDescription = NStr("vi = 'Giải mã tải song song';
							|ru = 'Расшифровка параллельной загрузки';
							|en = 'Parallel load drill-down'; fa = 'Parallel load drill-down';
							|it = 'Decrittografia di download parallela';
							|pl = 'Szczegóły równoległego pobierania';
							|tr = 'Paralel çalışma yükünün detaylandırılması'");
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	
	CalculationResult2 = TimeConsumingOperations.ExecuteInBackground(
		"Reports.OperationTimetableChart2_2.DecryptParallelDownloadsInBackground",
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
	
	OutputParameters = Reports.OperationTimetableChart2_2.ParallelLoadingOptions();
	
	FillPropertyValues(OutputParameters, ThisForm);
	If OutputParameters.Property("Departments") Then
		OutputParameters.Departments = Departments.UnloadValues();
	EndIf;
	
	Return OutputParameters;
	
EndFunction

&AtClient
Procedure ProcessSelectionChange()
	
	If CheckFilling() Then
		DisplaySchedule();
	EndIf;
	
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
	If Item.Name = "sh_ShamsiInput_F_Begin" Then
		BeginOnChange(Items.Begin);
	ElsIf Item.Name = "sh_ShamsiInput_F_Ending" Then
		EndingOnChange(Items.Ending);
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
