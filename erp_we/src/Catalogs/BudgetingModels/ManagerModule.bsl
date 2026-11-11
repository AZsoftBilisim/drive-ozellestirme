#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function returns a table with planned and actual tasks.
//
// Parameters:
//  BudgetingModel - CatalogRef.BudgetingModels - The model that the schedule is built for
//  GroupOfProcessSteps - CatalogRef.BudgetingSteps - group of stages of the budget process
//  BeginOfPeriod - Date - the beginning of the period.
//  EndOfPeriod - Date - end of period.
//  SupplementWithActualTasks - Boolean - If True, data about actual tasks will be filled in.
//  CheckTasksForOtherPeriods - Boolean - If False, the beginning of the period is cut off by the beginning of the model action.
//
// Returns:
//   ValueTable - The schedule of the budget process from the start date of the model by the "Add-on" parameter.
//
Function GetBudgetIssues(BudgetingModel, GroupOfProcessSteps, Val BeginOfPeriod, Val EndOfPeriod,
	Val SupplementWithActualTasks = False, Val CheckTasksForOtherPeriods = False) Export
	
	ModelStart = Common.ObjectAttributeValue(BudgetingModel, "ValidOnDate");
	If Not ValueIsFilled(ModelStart) Then
		Return TaskTemplate();
	EndIf;
	
	If BeginOfPeriod = Undefined Then
		BeginOfPeriod = ModelStart;
	ElsIf Not CheckTasksForOtherPeriods Then
		BeginOfPeriod = Max(BeginOfPeriod, ModelStart);
	EndIf;
	
	ResultTable1 = BudgetingTasks(BudgetingModel,
			GroupOfProcessSteps,
			BeginOfPeriod,
			EndOfPeriod,
			SupplementWithActualTasks,
			CheckTasksForOtherPeriods);
	
	Return ResultTable1;
	
EndFunction

// The function returns a table with relationships between tasks.
//
// Parameters:
//  TaskTable_ - ValueTable - The table obtained by the "get budget Tasks" function.
//
// Returns:
//   ValueTable - a table of relationships between tasks.
//
Function TaskRelationships(TaskTable_) Export
	
	TaskRelationshipTable = New ValueTable;
	TaskRelationshipTable.Columns.Add("PreviousTask", New TypeDescription("Number"));
	TaskRelationshipTable.Columns.Add("Task", 			New TypeDescription("Number"));
	TaskRelationshipTable.Columns.Add("NextTask", 	New TypeDescription("Number"));
	
	For Each TaskLine In TaskTable_ Do
		NewRow = TaskRelationshipTable.Add();
		NewRow.Task = TaskLine.TaskNumber;
		TableOfPreviousOnes = TaskLine.PreviousTasks;
		If ValueIsFilled(TableOfPreviousOnes) Then
			For Each PreviousTask In TableOfPreviousOnes Do
				NewRow = TaskRelationshipTable.Add();
				NewRow.Task = TaskLine.TaskNumber;
				NewRow.PreviousTask = PreviousTask.TaskNumber;
				NewRow = TaskRelationshipTable.Add();
				NewRow.Task = PreviousTask.TaskNumber;
				NewRow.NextTask = TaskLine.TaskNumber;
			EndDo;
		EndIf;
	EndDo;
	
	TaskRelationshipTable.Sort("Task, PreviousTask, NextTask");
	
	Return TaskRelationshipTable;
	
EndFunction

// Checks whether the budgeting model is valid.
//
// Parameters:
// 	BudgetingModel - CatalogRef.BudgetingModels - The budgeting model to check.
//
// Returns:
// 	Boolean - True if the budgeting model is valid.
// 				False if the budgeting model does not work.
//
Function BudgetingModelWorks(BudgetingModel) Export
	
	If Not ValueIsFilled(BudgetingModel) Then
		Valid = False;
	Else
		ObjectAttributes = Common.ObjectAttributesValues(BudgetingModel, 
			New Structure("DeletionMark, Status"));
			
		Valid = Not ObjectAttributes.DeletionMark
				And ObjectAttributes.Status = Enums.BudgetingModelStatuses.Valid;
	EndIf;
		
	Return Valid;
	
EndFunction

// Returns the number of active budgeting models.
//
// Returns:
// 	 Number - The number of active models.
//
Function NumberOfExistingBudgetingModels() Export
	
	Query = New Query("SELECT
		|	SUM(1) AS Count
		|FROM
		|	Catalog.BudgetingModels AS BudgetingModels
		|WHERE
		|	BudgetingModels.Status = &Status
		|	AND NOT BudgetingModels.DeletionMark");
	Query.SetParameter("Status", Enums.BudgetingModelStatuses.Valid);
	
	Selection = Query.Execute().Select();
	
	Return ?(Selection.Next(), Selection.Count, 0);
	
EndFunction

// Gets the default budgeting model for substitution.
//
// Returns:
// 	CatalogRef.BudgetingModels - The default budgeting model or found by statistics.
// 	Undefined - If there are no existing budgeting models.
//
Function DefaultBudgetingModel() Export
	
	DefaultBudgetingModel = Undefined;
	
	ValidStatus = Enums.BudgetingModelStatuses.Valid;
	
	Query = New Query("SELECT TOP 2
		|	BudgetingModels.Ref AS BudgetingModel
		|FROM
		|	Catalog.BudgetingModels AS BudgetingModels
		|WHERE
		|	BudgetingModels.Status = &Status
		|	AND NOT BudgetingModels.DeletionMark");
	Query.SetParameter("Status", ValidStatus);
	
	Selection = Query.Execute().Select();
	
	If Selection.Count() = 1 Then
		
		Selection.Next();
		DefaultBudgetingModel = Selection.BudgetingModel;
		
	EndIf;
	
	If Not ValueIsFilled(DefaultBudgetingModel) And Selection.Count() > 1 Then
		
		SetPrivilegedMode(True);
		AttributesDetails1 = New Structure;
		ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "BudgetingModel");
		DetailsToFillIn = ObjectsFillingByStatistics.GetBankingDetailsValues(
			Documents.BudgetEntryForm.EmptyRef(), AttributesDetails1);
		SetPrivilegedMode(False);
		
		If ValueIsFilled(DetailsToFillIn.BudgetingModel)
			And BudgetingModelWorks(DetailsToFillIn.BudgetingModel) Then
			DefaultBudgetingModel = DetailsToFillIn.BudgetingModel;
		EndIf;
	EndIf;
	
	Return DefaultBudgetingModel;
	
EndFunction

// Gets a budgeting model using budget approval
//
// Returns:
// 	CatalogRef.BudgetingModels - Budgeting model using budget approval.
// 	Undefined - If there are no suitable budgeting models.
//
Function BudgetingModel_UseBudgetConfirmation() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	BudgetingModels.Ref AS Ref
	|FROM
	|	Catalog.BudgetingModels AS BudgetingModels
	|WHERE
	|	BudgetingModels.Status = VALUE(Enum.BudgetingModelStatuses.Valid)
	|	AND NOT BudgetingModels.DeletionMark
	|	AND BudgetingModels.UseBudgetConfirmation";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
// 	Array of String - names of blocked Bank details:
//		* AttributeToLock - String - Name of the blocked account.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("Periodicity");
	Result.Add("ValidOnDate");
	Result.Add("ValidToDate");
	Result.Add("BudgetsByCompanies");
	Result.Add("BudgetsByBusinessUnits");
	Result.Add("UseBudgetConfirmation");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	Date = '00010101';
	BeginOfPeriod = '00010101';
	PeriodEnding = '00010101';
	
	RedefinedSelectionData = Undefined;
	If Parameters.Property("Date", Date) Then
		
		RedefinedSelectionData = BudgetReportingServerCall.BudgetingModelsWithSelectionByDate(Date);
		
	ElsIf Parameters.Property("BeginOfPeriod", BeginOfPeriod)
			And Parameters.Property("PeriodEnding", PeriodEnding) Then
		
		RedefinedSelectionData = BudgetReportingServerCall.BudgetingModelsWithSelectionByPeriod(BeginOfPeriod, PeriodEnding);
		
	EndIf;
	
	If RedefinedSelectionData <> Undefined Then
		
		StandardProcessing = False;
		ChoiceData = RedefinedSelectionData;
		
	Else
		
		Parameters.Filter.Insert("DeletionMark", False);
		
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region MechanismOfFormationOfBudgetScheduleServiceProcedures

Function GetDateByCalendar(ScheduleManager, Date, Deviation)
	
	If Deviation > 0 Then
		SignOfComparison = ">=";
		Function_ = "MAX";
		Order = "ASC";
	ElsIf Deviation < 0 Then
		SignOfComparison = "<=";
		Function_ = "MIN";
		Order = "DESC";
	Else
		Return Date;
	EndIf;
	
	AbsDeviation = Max(Deviation, -Deviation);
	
	Query = New Query();
	Query.TempTablesManager = ScheduleManager;
	Query.Text = 
	"SELECT TOP 0
		|	CalendarSchedules.ScheduleDate AS ScheduleDate
		|INTO TMChartData
		|FROM
		|	ScheduleData AS CalendarSchedules
		|WHERE
		|	&ConditionExpression
		|
		|ORDER BY
		|	&OrderingExpression
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&FunctionExpression AS ScheduleDate
		|FROM
		|	TMChartData AS TMChartData";
	
	RequestSchemes.SetNumberOfRecordsReceived(Query, AbsDeviation + 1, 0);
	
	ConnectingStrings = New Array;
	ConnectingStrings.Add("CalendarSchedules.ScheduleDate");
	ConnectingStrings.Add(SignOfComparison);
	ConnectingStrings.Add("&ScheduleDate");
	ConditionExpression = StrConcat(ConnectingStrings, " ");
	OrderingExpression = "ScheduleDate" + " " + Order;
	FunctionExpression = Function_ + "(TMChartData.ScheduleDate)";
	
	Query.Text = StrReplace(Query.Text, "&ConditionExpression", ConditionExpression);
	Query.Text = StrReplace(Query.Text, "&OrderingExpression", OrderingExpression);
	Query.Text = StrReplace(Query.Text, "&FunctionExpression", FunctionExpression);
	
	Query.SetParameter("ScheduleDate", Date);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	TMCommonUse.DestroyTemporaryTables(ScheduleManager, "TMChartData");
	
	If Not ValueIsFilled(Selection.ScheduleDate) Then
		Return Date;
	EndIf;
	
	Return Selection.ScheduleDate;
	
EndFunction

Procedure CheckCompletionOfChartsForPeriod(StartDate, EndDate, Schedule, Cancel)
	
	TableOfYears = New ValueTable;
	TableOfYears.Columns.Add("Year", New TypeDescription("Number"));
	TableOfYears.Columns.Add("Schedule", New TypeDescription("CatalogRef.Calendars"));
	
	For Year = Year(StartDate) To Year(EndDate) Do
		NewRow = TableOfYears.Add();
		NewRow.Year = Year;
		NewRow.Schedule = Schedule;
	EndDo;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TableOfYears.Year,
		|	TableOfYears.Schedule
		|INTO TableOfYears
		|FROM
		|	&TableOfYears AS TableOfYears
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfYears.Year,
		|	TableOfYears.Schedule,
		|	CalendarSchedules.Year AS YearOfSchedule,
		|	MAX(CalendarSchedules.DayAddedToSchedule) AS DayAddedToSchedule
		|INTO CheckTable
		|FROM
		|	TableOfYears AS TableOfYears
		|		LEFT JOIN InformationRegister.CalendarSchedules AS CalendarSchedules
		|		ON TableOfYears.Year = CalendarSchedules.Year
		|			AND TableOfYears.Schedule = CalendarSchedules.Calendar
		|
		|GROUP BY
		|	TableOfYears.Schedule,
		|	TableOfYears.Year,
		|	CalendarSchedules.Year
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	CheckTable.Year AS Year
		|FROM
		|	CheckTable AS CheckTable
		|WHERE
		|	(CheckTable.YearOfSchedule IS NULL 
		|			OR CheckTable.DayAddedToSchedule = FALSE)
		|
		|ORDER BY
		|	Year";

	Query.SetParameter("TableOfYears", TableOfYears);
	QueryResult = Query.Execute();

	SelectionDetailRecords = QueryResult.Select();
	
	LogParameters = New Structure("EventGroup_, Metadata, Data");
	LogParameters.EventGroup_ = NStr("vi = 'Nhiệm vụ ngân sách';
									|ru = 'Формирование бюджетных задач';
									|en = 'Budget task generation'; fa = 'تولید وظیفه بودجه';
									|it = 'Формирование бюджетных задач';
									|pl = 'Tworzenie zadań budżetowych';
									|tr = 'Bütçe görevleri oluşumu'");
	LogParameters.Metadata = Metadata.FindByType(Type("InformationRegisterRecordSet.CalendarSchedules"));

	While SelectionDetailRecords.Next() Do
		ErrorMessage = NStr("vi = 'Không điền lịch trình hoạt động chính của doanh nghiệp cho năm %1.';
							|ru = 'Не заполнен основной график работы предприятия на %1 г.';
							|en = 'Main enterprise schedule for %1 is not filled in'; fa = 'Main enterprise schedule for %1 is not filled in';
							|it = 'Il programma di lavoro principale dell''azienda nell''anno %1 non è compilato.';
							|pl = 'Nie wypełniono głównego harmonogramu pracy przedsiębiorstwa na %1 r.';
							|tr = '%1 yılında işletme ana çalışma takvimi doldurulmadı'");
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, Format(
			SelectionDetailRecords.Year, "NG="));
		TMCommonUse.LogReportToUser(LogParameters, EventLogLevel.Error, "",
			ErrorMessage);
		Cancel = True;
	EndDo;
	
EndProcedure

Function TableOfTaskNumbersInRow(TableOfIssueNumbers)
	
	Result = "";
	For Each TaskLine In TableOfIssueNumbers Do
		Result = Result + "| " + TaskLine.TaskNumber + " |";
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a template for the task table.
// 
// Returns:
// 	ValueTable - LongDesc:
// * TaskNumber - Number -
// * BudgetingStep - CatalogRef.BudgetingSteps -
// * BudgetingStepBasis - CatalogRef.BudgetingSteps -
// * BudgetingProcess - DocumentRef.BudgetingProcess -
// * Action - EnumRef.TypesOfBudgetingStepActions -
// * Performer - CatalogRef.Users -
// * Periodicity - EnumRef.Periodicity -
// * SettingOfAction - Structure - 
// * Period - Date -
// * PeriodAsString - String -
// * StartDate - Date -
// * EndDate - Date -
// * PreviousTasksByLine - String -
// * PreviousTasks - ValueTable - 
// * Task - TaskRef.BudgetTask -
// * TaskExecuted - Boolean -
// * StartDateFact - Date -
// * EndDateFact - Date -
Function TaskTemplate()
	
	TaskTable_ = New ValueTable;
	TaskTable_.Columns.Add("TaskNumber", 						New TypeDescription("Number"));
	TaskTable_.Columns.Add("BudgetingStep", 			New TypeDescription("CatalogRef.BudgetingSteps"));
	TaskTable_.Columns.Add("BudgetingStepBasis", 	New TypeDescription("CatalogRef.BudgetingSteps"));
	TaskTable_.Columns.Add("BudgetingProcess", 			New TypeDescription("DocumentRef.BudgetingProcess"));
	TaskTable_.Columns.Add("Action", 							New TypeDescription("EnumRef.TypesOfBudgetingStepActions"));
	TaskTable_.Columns.Add("Performer", 						New TypeDescription("CatalogRef.Users"));
	TaskTable_.Columns.Add("Periodicity", 						New TypeDescription("EnumRef.Periodicity"));
	TaskTable_.Columns.Add("SettingOfAction");					// Value storage
	
	TaskTable_.Columns.Add("Period", 							New TypeDescription("Date"));
	TaskTable_.Columns.Add("PeriodAsString", 						New TypeDescription("String"));
	TaskTable_.Columns.Add("StartDate", 						New TypeDescription("Date"));
	TaskTable_.Columns.Add("EndDate", 						New TypeDescription("Date"));
	
	TaskTable_.Columns.Add("PreviousTasksByLine", 			New TypeDescription("String"));
	TaskTable_.Columns.Add("PreviousTasks");					// Table of values
	
	TaskTable_.Columns.Add("Task", 							New TypeDescription("TaskRef.BudgetTask"));
	TaskTable_.Columns.Add("TaskExecuted", 					New TypeDescription("Boolean"));
	TaskTable_.Columns.Add("StartDateFact", 					New TypeDescription("Date"));
	TaskTable_.Columns.Add("EndDateFact", 					New TypeDescription("Date"));
	
	TaskTable_.Indexes.Add("TaskNumber");
	
	Return TaskTable_;
	
EndFunction

// Returns the structure of the start and end dates of the task.
// 
// Parameters:
// 	Selection - ValueTreeRow -
// 	TaskTable_ - ValueTable - :
// 	 *TaskNumber - Number - 
// 	 *StartDate - Date -
// 	 *EndDate - Date -
// 	ScheduleManager - TempTablesManager -
// 	GroupPeriodParameters - Structure -:
// 	 *StartDate - Date -
// 	 *EndDate - Date -
// 	TableOfPreviousTasks - ValueTable -:
// 	 *TaskNumber - Number -
// 	AddFact - Boolean -
// 	InformationAboutFact - ValueTableRow, Undefined -:
// 	 *StartDate - Date - 
// 	 *EndDate - Date - 
// 	 *Executed - Boolean - 
// Returns:
// 	Structure -:
// 	*TaskStartDate - Date - 
// 	*TaskEndDate - Date -
Function GetIssuePeriod(Selection, TaskTable_, ScheduleManager, 
								GroupPeriodParameters, TableOfPreviousTasks, AddFact = False, InformationAboutFact = Undefined)
								
	If AddFact And InformationAboutFact <> Undefined Then
		EndDate = InformationAboutFact.EndDate;
		If Not InformationAboutFact.Executed Then
			EndDate = EndOfDay(CurrentSessionDate());
		EndIf;
		Return New Structure("TaskStartDate, TaskEndDate", InformationAboutFact.StartDate, EndDate);
	EndIf;
	
	If Selection.StartCondition = Enums.TypesOfBudgetingStepStartConditions.Manually Then
		TaskStartDate = BegOfDay(CurrentSessionDate());
		Return New Structure("TaskStartDate, TaskEndDate", TaskStartDate, EndOfDay(TaskStartDate));
	EndIf;
	
	If Selection.StartCondition = Enums.TypesOfBudgetingStepStartConditions.BeforePeriodStart
		Or Selection.StartCondition = Enums.TypesOfBudgetingStepStartConditions.AfterPeriodStart Then
		TaskStartDate = GroupPeriodParameters.StartDate;
	Else
		TaskStartDate = EndOfDay(GroupPeriodParameters.EndDate) + 1;
	EndIf;
	
	If Selection.StartCondition = Enums.TypesOfBudgetingStepStartConditions.BeforePeriodStart
		Or Selection.StartCondition = Enums.TypesOfBudgetingStepStartConditions.BeforePeriodEnd Then
		Character = -1;
	Else
		Character = 1;
	EndIf;
	
	If Selection.TypePeriod = Enums.TypesOfBudgetingStepDurations.InWorkdays Then
		TaskStartDate = GetDateByCalendar(ScheduleManager, TaskStartDate, Character * Selection.DueDate);
	Else
		TaskStartDate = TaskStartDate + Character * Selection.DueDate * 86400;
	EndIf;
	
	PreviousTaskDate = Date(1, 1, 1);
	
	For Each TableRow In TableOfPreviousTasks Do
		FoundRow = TaskTable_.Find(TableRow.TaskNumber, "TaskNumber");
		EndDate = FoundRow.EndDate;
		PreviousTaskDate = Max(PreviousTaskDate, EndDate);
	EndDo;
	
	If ValueIsFilled(PreviousTaskDate) Then
		TaskStartDate = Max(TaskStartDate, PreviousTaskDate + 1);
	EndIf;
	
	If Selection.Duration > 0 Then
		If Selection.DurationType = Enums.TypesOfBudgetingStepDurations.InWorkdays Then
			TaskEndDate = GetDateByCalendar(ScheduleManager, TaskStartDate, Selection.Duration - 1);
		Else
			TaskEndDate = TaskStartDate + (Selection.Duration - 1) * 86400;
		EndIf;
	Else
		TaskEndDate = TaskStartDate;
	EndIf;
	
	Return New Structure("TaskStartDate, TaskEndDate", BegOfDay(TaskStartDate), EndOfDay(TaskEndDate));
	
EndFunction

#EndRegion

#Region MechanismOfFormationOfBudgetScheduleFillingInScheduleTable

// The function adds a row to the planned tasks table
//	and performs the following actions:
//	1. adds a line for the planned task
//	2. fills in information about the actual execution of the stage, if the parameters have the "add fact"flag.
//
// Parameters:
//  Selection  						- ValueTreeRow - result of a request to the Catalog "stages of budget preparation" with a hierarchy of stages:
//   *BudgetingStep		- CatalogRef.BudgetingSteps -
//   *BudgetingStepBasis - CatalogRef.BudgetingSteps -
//   *BudgetingProcess		- DocumentRef.BudgetingProcess -
//   *Action						- EnumRef.TypesOfBudgetingStepActions -
//   *SettingOfAction				- Structure -
//   *Performer					- CatalogRef.Users -
//   *PeriodicityParent			- EnumRef.Periodicity -
//  TaskTableParameters  			- Structure - contains a table with tasks and the "add fact" flag:
//   *TaskTable_					- ValueTable -:
//     **TaskNumber 				- Number -
//     **BudgetingStep		- CatalogRef.BudgetingSteps -
//     **BudgetingStepBasis - CatalogRef.BudgetingSteps -
//     **BudgetingProcess	- DocumentRef.BudgetingProcess - 
//     **Action					- EnumRef.TypesOfBudgetingStepActions -
//     **SettingOfAction			- Structure -
//     **Performer				- CatalogRef.Users -
//     **Periodicity				- EnumRef.Periodicity - 
//     **StartDate					- Date -
//     **EndDate				- Date -
//  ScheduleManager  				- TempTablesManager - contains a table with chart data, filtered
//									by chart and indexed by date.
//  GroupPeriodParameters  		- Structure - structure with the beginning and end of the period for which we create tasks
//  TableOfPreviousTasks  		- ValueTable - contains the number of issues that precede the current issue.
//		
// Returns:
//  ValueTable 				- contains the numbers of tasks that the group or task will be considered completed when it is completed.
//
Function AddScheduledTaskLine(Selection, TaskTableParameters, ScheduleManager, GroupPeriodParameters, TableOfPreviousTasks)
	
	TaskTable_ = TaskTableParameters.TaskTable_;
	
	NewRow 						= TaskTable_.Add();
	NewRow.TaskNumber 			= TaskTable_.Count();
	NewRow.BudgetingStep 	= Selection.BudgetingStep;
	NewRow.BudgetingStepBasis 	= Selection.BudgetingStepBasis;
	NewRow.BudgetingProcess			= Selection.BudgetingProcess;
	NewRow.Action 				= Selection.Action;
	NewRow.SettingOfAction 		= Selection.SettingOfAction;
	NewRow.Performer 			= Selection.Performer;
	NewRow.Periodicity 			= Selection.PeriodicityParent;
	
	DateParametersPlan = GetIssuePeriod(Selection, 
			TaskTable_, 
			ScheduleManager, 
			GroupPeriodParameters, 
			TableOfPreviousTasks);
	
	NewRow.StartDate = DateParametersPlan.TaskStartDate;
	NewRow.EndDate = DateParametersPlan.TaskEndDate;
	
	If TaskTableParameters.Property("AddFact") Then
		
		InformationAboutFact = Undefined;
		SearchKey = New Structure();
		SearchKey.Insert("Period", GroupPeriodParameters.StartDate);
		SearchKey.Insert("BudgetingStep", Selection.BudgetingStep);
		SearchKey.Insert("BudgetingStepBasis", Selection.BudgetingStepBasis); 
		SearchKey.Insert("BudgetingProcess", Selection.BudgetingProcess);
		
		FoundRows = TaskTableParameters.FactTable.FindRows(SearchKey);
		If FoundRows.Count() Then
			InformationAboutFact = FoundRows[0];
			NewRow.Task 			= InformationAboutFact.Task;
			NewRow.TaskExecuted = InformationAboutFact.Executed;
			NewRow.Performer 	= InformationAboutFact.Performer;
		EndIf;
		DateParametersFact = GetIssuePeriod(Selection,
				TaskTable_,
				ScheduleManager,
				GroupPeriodParameters,
				TableOfPreviousTasks,
				True,
				InformationAboutFact);

		NewRow.StartDateFact 			= DateParametersFact.TaskStartDate;
		NewRow.EndDateFact		= DateParametersFact.TaskEndDate;
		If FoundRows.Count() Then
			TaskTableParameters.FactTable.Delete(InformationAboutFact);
		EndIf;
		
	EndIf;
	
	NewRow.Period = GroupPeriodParameters.StartDate;
	NewRow.PeriodAsString = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(
		NewRow.Period, 
		NewRow.Periodicity);
	
	NewRow.PreviousTasksByLine = TableOfTaskNumbersInRow(TableOfPreviousTasks);
	NewRow.PreviousTasks = TableOfPreviousTasks.Copy();
	
	PreviousTasks = New ValueTable;
	PreviousTasks.Columns.Add("TaskNumber");
	PreviousTasks.Add().TaskNumber = NewRow.TaskNumber;
	
	Return PreviousTasks;
	
EndFunction

// The recursive task list generation function based on the stage tree
//	performs the following actions:
//	1. if it is a group of tasks - transfers control of the procedure processing the group
//		the formation of tasks by group is performed for each period of the group
//	2. If this is the Budget Preparation stage, it transfers control to the procedure that forms the task line.
//
// Parameters:
//  Selection - ValueTreeRow - result of a request to the Catalog "stages of budget preparation" with a hierarchy of stages
//  TaskTableParameters  			- Structure:
//  	*TaskTable_				- ValueTable - a table to fill in.
//  	*ProcessCalculationSettings	- Map of KeyAndValue - Where:
//  	 **Key						- DocumentRef.BudgetingProcess - 
//  	 **Value					- ValueTable - 
//  GroupPeriodParameters  		- Structure - structure with the beginning and end of the period for which we create tasks:
//  	*StartDate					- Date -
//  	*EndDate				- Date -
//  ScheduleManager  				- TempTablesManager - contains a table with chart data, filtered by schedule and indexed by date
//  TableOfPreviousTasks  		- ValueTable - contains the number of tasks that precede the Cur task.
//		
//  Assignment table 				- contains the numbers of tasks that the group or task will be considered completed.
//
Function ProcessExecutionOfProcessStep(Selection,
					TaskTableParameters,
					GroupPeriodParameters,
					ScheduleManager,
					TableOfPreviousTasks)
	
	If Not Selection.IsFolder Then
		
		SkipStage = False;
		If ValueIsFilled(Selection.BudgetingProcess) Then
			
			CalculationSettings = TaskTableParameters.ProcessCalculationSettings[Selection.BudgetingProcess];
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("Period", GroupPeriodParameters.StartDate);
			TheStructureOfTheSearch.Insert("NotRunning", False);
			TheStructureOfTheSearch.Insert("BudgetingStep", Selection.BudgetingStep);
			TheStructureOfTheSearch.Insert("BudgetingStepBasis", Selection.BudgetingStepBasis);
			
			FoundRows = CalculationSettings.FindRows(TheStructureOfTheSearch);
			
			If Not FoundRows.Count() Then
				SkipStage = True;
			EndIf;
			
		EndIf;
		
		If Not SkipStage
			And Selection.StartCondition = Enums.TypesOfBudgetingStepStartConditions.Manually Then
			If Not ValueIsFilled(Selection.BudgetingProcess) Then
				SkipStage = True;
			EndIf;
		EndIf;
		
		If Not SkipStage Then
				
			If ValueIsFilled(Selection.BudgetingProcess) Then
			
				CalculationSettings = TaskTableParameters.ProcessCalculationSettings[Selection.BudgetingProcess];
				TheStructureOfTheSearch = New Structure("Period, BudgetingStep, BudgetingStepBasis");
				FillPropertyValues(TheStructureOfTheSearch, Selection);
				TheStructureOfTheSearch.Period = GroupPeriodParameters.StartDate;
				FoundRows = CalculationSettings.FindRows(TheStructureOfTheSearch);
				
				FillPropertyValues(Selection, FoundRows[0], "Duration, DurationType");
				Selection.Performer = FoundRows[0].EmployeeResponsible;
			
			EndIf;
			
			NewTableOfPreviousOnes = AddScheduledTaskLine(Selection,
					TaskTableParameters,
					ScheduleManager,
					GroupPeriodParameters,
					TableOfPreviousTasks);
			
		EndIf;
		
	Else
		
		StartDate = WorkingWithClientServerPeriods.BeginningDateOfPeriod(GroupPeriodParameters.StartDate, Selection.Periodicity);
		
		While StartDate <= GroupPeriodParameters.EndDate Do
			
			EndDate = WorkingWithClientServerPeriods.PeriodEndDate_(StartDate, Selection.Periodicity);
			EndDate = Min(EndDate, GroupPeriodParameters.EndDate);
			
			PeriodParameters_ = New Structure("StartDate, EndDate", StartDate, EndDate);
			
			//@skip-check query-in-loop
			NewTableOfPreviousOnes = FillTaskTree(Selection,
					TaskTableParameters,
					PeriodParameters_,
					ScheduleManager,
					TableOfPreviousTasks);
			
			StartDate = EndDate + 1; //Moving on to the next period
			
		EndDo;
		
	EndIf;
	
	Return NewTableOfPreviousOnes;
	
EndFunction

// The recursive task list generation function based on the process step tree
//	performs the following actions:
//	1. For each row of the tree containing the process step, the process step handler procedure is called
//	2. Based on the type of group, it generates a table that contains the numbers of tasks, 
//	during which the group will be considered completed and the process will move to the next step after the group.
//
// Parameters:
//  StepTree						- ValueTreeRow - the result of a request to the Catalog "steps of the budget process" with a hierarchy of steps
//  TaskTableParameters			- Structure -:
//  	*TaskTable_ 	 			- ValueTable - a table to fill in.
//  GroupPeriodParameters			- Structure - structure with the beginning and end of the period for which we create tasks:
//  	*StartDate					- Date -
//  	*EndDate				- Date - 
//  ScheduleManager					- TempTablesManager - contains a table with chart data, filtered by schedule and indexed by date
//  PreviousTasks				- ValueTable - contains the number of issues that precede the current issue.
//	
//	Returns:
//  ValueTable 				- contains the numbers of tasks that the group will be considered completed when performing.
//
Function FillTaskTree(StepTree, TaskTableParameters, GroupPeriodParameters, 
										ScheduleManager, PreviousTasks = Undefined)
							
	If PreviousTasks = Undefined Then
		PreviousTasks = New ValueTable;
		PreviousTasks.Columns.Add("TaskNumber");
	EndIf;
	
	TableOfPreviousTasks = PreviousTasks.Copy();
	CurTableOfPreviousTasks = TableOfPreviousTasks.CopyColumns();
	
	SequentialGroup = False;
	
	For Each Selection In StepTree.Rows Do
		
		//@skip-check query-in-loop
		NewTableOfPreviousOnes = ProcessExecutionOfProcessStep(Selection,
				TaskTableParameters,
				GroupPeriodParameters,
				ScheduleManager,
				TableOfPreviousTasks);
		
		If NewTableOfPreviousOnes = Undefined Then
			Continue; //no task is included in the report period
		EndIf;
		
		If Selection.StageExecutionProcedure = Enums.BudgetingStageExecutionProcedure.Sequentially Then
			TableOfPreviousTasks = NewTableOfPreviousOnes;
			SequentialGroup = True;
		Else
			For Each TaskLine In NewTableOfPreviousOnes Do
				CurTableOfPreviousTasks.Add().TaskNumber = TaskLine.TaskNumber;
			EndDo;
		EndIf;
		
	EndDo;
	
	If SequentialGroup And NewTableOfPreviousOnes <> Undefined Then
		For Each TaskLine In NewTableOfPreviousOnes Do
			CurTableOfPreviousTasks.Add().TaskNumber = TaskLine.TaskNumber;
		EndDo;
	EndIf;
	
	Return CurTableOfPreviousTasks;
	
EndFunction

Procedure CopyRepeatableStagesOfBudgetPreparation(Source, Receiver, BudgetingStepBasis)
	
	For Each String In Source Do
		If String.Action = Enums.TypesOfBudgetingStepActions.StepGroupRepetition Then
			Continue;
		EndIf;
		NewRow = Receiver.Add();
		FillPropertyValues(NewRow, String);
		BudgetingStep = NewRow.BudgetingStep;
		NewRow.BudgetingStep = BudgetingStepBasis;
		NewRow.BudgetingStepBasis = BudgetingStep;
		CopyRepeatableStagesOfBudgetPreparation(String.Rows, NewRow.Rows, BudgetingStepBasis);
	EndDo;
	
EndProcedure

Procedure SupplementRepeatableStagesOfBudgetPreparation(StepTree) Export
	
	GroupRepeatSearchStructure = New Structure("Action", Enums.TypesOfBudgetingStepActions.StepGroupRepetition);
	FoundRows = StepTree.Rows.FindRows(GroupRepeatSearchStructure, True);
	For Each FoundRow In FoundRows Do
		
		FoundRow.IsFolder = True;
		
		ActionSettings = FoundRow.SettingOfAction.Get();
		RepeatableGroup = ActionSettings.Find("StepGroup", "Name");
		If RepeatableGroup = Undefined Then
			Continue;
		EndIf;
		
		TheStructureOfTheSearch = New Structure("BudgetingStep, BudgetingStepBasis", 
			RepeatableGroup.Value, Catalogs.BudgetingSteps.EmptyRef());
		RepeatLines = StepTree.Rows.FindRows(TheStructureOfTheSearch, True);
		If RepeatLines.Count() Then
			FoundRow.Periodicity = RepeatLines[0].Periodicity;
			CopyRepeatableStagesOfBudgetPreparation(RepeatLines[0].Rows, FoundRow.Rows, FoundRow.BudgetingStep);
		EndIf;
		
	EndDo;
	
EndProcedure

Function ExecutionOrderByProcess(DocumentData, NewRow)
	
	If Not ValueIsFilled(NewRow.BudgetingStep) Then
		// Auxiliary stage
		Return Enums.BudgetingStageExecutionProcedure.Sequentially;
	EndIf;
	
	SourceOfBankingDetails = ?(ValueIsFilled(NewRow.BudgetingStepBasis), 
									NewRow.BudgetingStepBasis,
									NewRow.BudgetingStep);
		
	Attributes = DocumentData.AttributesTable.Find(SourceOfBankingDetails);
		
	If NewRow.Action = Enums.TypesOfBudgetingStepActions.StepGroupRepetition Then
		ActionSettings = NewRow.SettingOfAction.Get();
		RepeatableGroup = ActionSettings.Find("StepGroup", "Name").Value;
		DetailsOfLinkToGroup = DocumentData.AttributesTable.Find(RepeatableGroup);
		Return DetailsOfLinkToGroup.StageExecutionProcedure;
	Else
		Return Attributes.StageExecutionProcedure;
	EndIf;
	
EndFunction

Procedure CopyStagesOfBudgetPreparationProcess(Source, Receiver, DocumentData)
	
	For Each String In Source Do
		
		NewRow = Receiver.Add();
		FillPropertyValues(NewRow, String);
		NewRow.BudgetingProcess = DocumentData.BudgetingProcess;
		NewRow.ProcessDate = DocumentData.Date;
		If ValueIsFilled(NewRow.Parent) Then
			NewRow.PeriodicityParent = NewRow.Parent.Periodicity;
		EndIf;
		
		SourceOfBankingDetails = ?(ValueIsFilled(NewRow.BudgetingStepBasis), 
										NewRow.BudgetingStepBasis,
										NewRow.BudgetingStep);
		
		AttributesTable = DocumentData.AttributesTable; // See TableOfDetailsByModel
		Attributes = AttributesTable.Find(SourceOfBankingDetails);
		NewRow.Action = Attributes.Action;
		NewRow.SettingOfAction = Attributes.SettingOfAction;
		
		If NewRow.Action = Enums.TypesOfBudgetingStepActions.StepGroupRepetition Then
			NewRow.StageExecutionProcedure = ExecutionOrderByProcess(DocumentData, NewRow);
		ElsIf ValueIsFilled(NewRow.Parent) Then
			NewRow.StageExecutionProcedure = ExecutionOrderByProcess(DocumentData, NewRow.Parent);
		EndIf;
		
		CopyStagesOfBudgetPreparationProcess(String.Rows, NewRow.Rows, DocumentData);
		
	EndDo;
	
EndProcedure

// Returns a table of details for the stages of preparing budgets for the model.
// 
// Parameters:
// 	BudgetingModel - CatalogRef.BudgetingModels - 
// Returns:
// 	ValueTable -:
// 	 *Ref - CatalogRef.BudgetingSteps - 
// 	 *Action - EnumRef.TypesOfBudgetingStepActions -
// 	 *SettingOfAction - ValueStorage - 
// 	 *StageExecutionProcedure - EnumRef.BudgetingStageExecutionProcedure -
// 	 *StartCondition - EnumRef.TypesOfBudgetingStepStartConditions -
// 	 *ParentOrderOfSteps - EnumRef.BudgetingStageExecutionProcedure -
//
Function TableOfDetailsByModel(BudgetingModel)
	Query = New Query;
	Query.Text = "SELECT
		|	BudgetingSteps.Ref AS Ref,
		|	BudgetingSteps.Action AS Action,
		|	BudgetingSteps.SettingOfAction AS SettingOfAction,
		|	BudgetingSteps.StageExecutionProcedure AS StageExecutionProcedure,
		|	BudgetingSteps.StartCondition AS StartCondition,
		|	BudgetingSteps.Parent.StageExecutionProcedure AS ParentOrderOfSteps
		|FROM
		|	Catalog.BudgetingSteps AS BudgetingSteps
		|WHERE
		|	BudgetingSteps.Owner = &BudgetingModel";
	Query.SetParameter("BudgetingModel", BudgetingModel);
	
	AttributesTable = Query.Execute().Unload();
	AttributesTable.Indexes.Add("Ref");
	
	Return AttributesTable;
EndFunction

Procedure ComplementExistingBudgetPreparationProcesses(StepTree, BudgetingModel, GroupOfProcessSteps,
													TaskTableParameters, StartDate, EndDate)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BudgetingProcess.Ref
		|INTO ProcessTable
		|FROM
		|	Document.BudgetingProcess AS BudgetingProcess
		|WHERE
		|	BudgetingProcess.BudgetingModel = &BudgetingModel
		|	AND NOT BudgetingProcess.DeletionMark
		|	AND BudgetingProcess.Status = &Running
		|	AND &ConditionForGroupOfProcessStages
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BudgetingProcess.Ref,
		|	BudgetingProcess.HierarchySettings.(
		|		Ref,
		|		LineNumber,
		|		StepGroup,
		|		BudgetingStep,
		|		BudgetingStepBasis,
		|		Code,
		|		Periodicity
		|	),
		|	BudgetingProcess.CalculationSettings.(
		|		Ref,
		|		LineNumber,
		|		Period,
		|		BudgetingStep,
		|		BudgetingStepBasis,
		|		EmployeeResponsible,
		|		Duration,
		|		DurationType,
		|		NotRunning,
		|		ExecuteAutomatically
		|	),
		|	BudgetingProcess.Periodicity,
		|	BudgetingProcess.StepGroup.IsFolder,
		|	BudgetingProcess.Date
		|FROM
		|	ProcessTable AS ProcessTable
		|		LEFT JOIN Document.BudgetingProcess AS BudgetingProcess
		|		ON ProcessTable.Ref = BudgetingProcess.Ref";
	
	Query.SetParameter("BudgetingModel", BudgetingModel);
	If ValueIsFilled(GroupOfProcessSteps) Then
		Query.Text = StrReplace(Query.Text, "&ConditionForGroupOfProcessStages",
			"BudgetingProcess.StepGroup IN HIERARCHY (&GroupOfProcessSteps)"); // query-part
		Query.SetParameter("GroupOfProcessSteps", GroupOfProcessSteps);
	Else
		Query.Text = StrReplace(Query.Text, "&ConditionForGroupOfProcessStages", "TRUE");
	EndIf;
	Query.SetParameter("Running", Enums.StatusesOfBudgetingProcess.Running);
	Query.SetParameter("BeginOfPeriod", StartDate);
	Query.SetParameter("EndOfPeriod", EndDate);
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	AttributesTable = TableOfDetailsByModel(BudgetingModel);
	
	TaskTableParameters.Insert("ProcessCalculationSettings", New Map);
	
	While SelectionDetailRecords.Next() Do
		
		HierarchySettings = SelectionDetailRecords.HierarchySettings.Unload();
		If HierarchySettings.Count() = 0 Then
			Continue;
		EndIf;
		ProcessStepTree = Documents.BudgetingProcess.HierarchyOfProcessStepsByDocument(HierarchySettings);
		
		DocumentData = New Structure();
		DocumentData.Insert("AttributesTable", AttributesTable); 
		DocumentData.Insert("BudgetingProcess", SelectionDetailRecords.Ref);
		DocumentData.Insert("CalculationSettings", SelectionDetailRecords.CalculationSettings.Unload());
		DocumentData.Insert("Periodicity", SelectionDetailRecords.Periodicity);
		DocumentData.Insert("Date", SelectionDetailRecords.Date);
		
		If Not SelectionDetailRecords.StepGroupIsFolder Then
			
			AuxiliaryGroup = StepTree.Rows.Add();
			AuxiliaryGroup.Periodicity = ProcessStepTree.Rows[0].Periodicity;
			AuxiliaryGroup.BudgetingProcess = SelectionDetailRecords.Ref;
			AuxiliaryGroup.IsFolder = True;
			Receiver = AuxiliaryGroup.Rows;
			
		Else
			
			Receiver = StepTree.Rows;
			
		EndIf;
		
		CopyStagesOfBudgetPreparationProcess(ProcessStepTree.Rows, Receiver, DocumentData);
		
		TaskTableParameters.ProcessCalculationSettings.Insert(SelectionDetailRecords.Ref, 
			SelectionDetailRecords.CalculationSettings.Unload());
		
	EndDo;
	
EndProcedure

// Returns a table of existing tasks based on the budgeting model.
// 
// Parameters:
// 	BudgetingModel - CatalogRef.BudgetingModels - 
// 	GroupOfProcessSteps - CatalogRef.BudgetingSteps - 
// Returns:
// 	ValueTable - table of existing tasks:
// 	 *BudgetingStep - CatalogRef.BudgetingSteps - 
// 	 *BudgetingStepBasis - CatalogRef.BudgetingSteps - 
// 	 *Period - Date - 
// 	 *Task - TaskRef.BudgetTask - 
// 	 *Performer - CatalogRef.Users - 
// 	 *StartDate - Date -
// 	 *EndDate - Date - 
// 	 *Executed - Boolean - 
// 	 *Periodicity - EnumRef.Periodicity - 
// 	 *BudgetingProcess - DocumentRef.BudgetingProcess - 
//
Function TaskClassificationTableForModel(BudgetingModel, GroupOfProcessSteps)
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BudgetTask.BudgetingStep AS BudgetingStep,
	|	BudgetTask.BudgetingStepBasis AS BudgetingStepBasis,
	|	BudgetTask.Period AS Period,
	|	BudgetTask.Ref AS Task,
	|	BudgetTask.Performer AS Performer,
	|	BudgetTask.Date AS StartDate,
	|	BudgetTask.CompletionDate AS EndDate,
	|	BudgetTask.Executed AS Executed,
	|	BudgetTask.BudgetingStep.Parent.Periodicity AS Periodicity,
	|	BudgetTask.BudgetingProcess AS BudgetingProcess
	|FROM
	|	Task.BudgetTask AS BudgetTask
	|WHERE
	|	BudgetTask.BudgetingModel = &BudgetingModel
	|	AND BudgetTask.MainTask_ = VALUE(Task.BudgetTask.EmptyRef)
	|	AND NOT BudgetTask.DeletionMark
	|	AND NOT BudgetTask.Inactive_
	|	AND &ConditionForGroupOfProcessStages";
	
	Query.SetParameter("BudgetingModel", BudgetingModel);
	If ValueIsFilled(GroupOfProcessSteps) Then
		Query.Text = StrReplace(Query.Text, "&ConditionForGroupOfProcessStages",
			"BudgetTask.BudgetingStep IN HIERARCHY (&GroupOfProcessSteps)"); // query-part
		Query.SetParameter("GroupOfProcessSteps", GroupOfProcessSteps);
	Else
		Query.Text = StrReplace(Query.Text, "&ConditionForGroupOfProcessStages", "TRUE");
	EndIf;
	
	QueryResult = Query.Execute();
	FactTable = QueryResult.Unload();
	FactTable.Indexes.Add("Period, BudgetingStep");
	
	Return FactTable;
EndFunction

// Returns a tree of steps for the budget preparation stages for the model.
// 
// Parameters:
// 	BudgetingModel - CatalogRef.BudgetingModels - 
// 	GroupOfProcessSteps - CatalogRef.BudgetingSteps - 
// Returns:
// 	ValueTree - :
// 	 *BudgetingStep - CatalogRef.BudgetingSteps - 
// 	 *Periodicity - EnumRef.Periodicity - 
// 	 *Action - EnumRef.TypesOfBudgetingStepActions -
// 	 *SettingOfAction - ValueStorage - 
// 	 *PeriodicityParent - EnumRef.Periodicity - 
// 	 *StageExecutionProcedure - EnumRef.BudgetingStageExecutionProcedure -
// 	 *StartCondition - EnumRef.TypesOfBudgetingStepStartConditions -
// 	 *DueDate - Number - 
// 	 *Duration - Number - 
// 	 *DurationType - EnumRef.TypesOfBudgetingStepDurations -
// 	 *Performer - CatalogRef.Users - 
// 	 *IsFolder - Boolean - 
// 	 *Code - Number - 
// 	 *BudgetingStepBasis - CatalogRef.BudgetingSteps - 
//
Function ModelStepTree(BudgetingModel, GroupOfProcessSteps)
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BudgetingSteps.Ref AS BudgetingStep,
		|	BudgetingSteps.Periodicity AS Periodicity,
		|	BudgetingSteps.Action AS Action,
		|	BudgetingSteps.SettingOfAction AS SettingOfAction,
		|	CASE
		|		WHEN BudgetingSteps.Ref = &GroupOfProcessSteps
		|			THEN NULL
		|		ELSE BudgetingSteps.Parent.Periodicity
		|	END AS PeriodicityParent,
		|	CASE
		|		WHEN BudgetingSteps.Ref = &GroupOfProcessSteps
		|			THEN NULL
		|		ELSE BudgetingSteps.Parent.StageExecutionProcedure
		|	END AS StageExecutionProcedure,
		|	CASE
		|		WHEN BudgetingSteps.Ref = &GroupOfProcessSteps
		|			THEN NULL
		|		ELSE BudgetingSteps.Parent.StartCondition
		|	END AS StartCondition,
		|	CASE
		|		WHEN BudgetingSteps.Ref = &GroupOfProcessSteps
		|			THEN NULL
		|		ELSE BudgetingSteps.Parent.DueDate
		|	END AS DueDate,
		|	CASE
		|		WHEN BudgetingSteps.Ref = &GroupOfProcessSteps
		|			THEN NULL
		|		ELSE BudgetingSteps.Parent.TypePeriod
		|	END AS TypePeriod,
		|	BudgetingSteps.Duration AS Duration,
		|	BudgetingSteps.DurationType,
		|	BudgetingSteps.EmployeeResponsible AS Performer,
		|	BudgetingSteps.IsFolder,
		|	BudgetingSteps.Code AS Code,
		|	VALUE(Catalog.BudgetingSteps.EmptyRef) AS BudgetingStepBasis
		|FROM
		|	Catalog.BudgetingSteps AS BudgetingSteps
		|WHERE
		|	BudgetingSteps.Owner = &BudgetingModel
		|	AND (BudgetingSteps.IsFolder
		|			OR BudgetingSteps.NotRunning = FALSE)
		|	AND &ConditionForGroupOfProcessStages
		|
		|ORDER BY
		|	BudgetingStep HIERARCHY";
	
	Query.SetParameter("BudgetingModel", BudgetingModel);
	Query.SetParameter("GroupOfProcessSteps", GroupOfProcessSteps);
	If ValueIsFilled(GroupOfProcessSteps) Then
		Query.Text = StrReplace(Query.Text, "&ConditionForGroupOfProcessStages",
			"BudgetingSteps.Ref IN HIERARCHY (&GroupOfProcessSteps)"); // query-part
	Else
		Query.Text = StrReplace(Query.Text, "&ConditionForGroupOfProcessStages", "TRUE");
	EndIf;
	
	QueryResult = Query.Execute();
	StepTree = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	StepTree.Rows.Sort("Code", True);
	StepTree.Columns.Add("BudgetingProcess", New TypeDescription("DocumentRef.BudgetingProcess"));
	StepTree.Columns.Add("ProcessDate", New TypeDescription("Date"));
	
	Return StepTree;
EndFunction

// The function returns a table of planned tasks, built according to the steps of the process
//	performs the following actions:
//	1. creates a tree of values with elements of the reference book " stages of budget preparation"
//	2. prepares the Manager of temporary tables for the subsequent determination of the duration "by working days"
//	3. creates a table with actual tasks if the "add with fact" flag is set. 
//		the table of actual tasks is then used in the algorithm for filling in the final table of planned tasks
//	4. supplements the table of planned tasks with actual tasks, if these tasks were created "outside the budget process".
//
// Parameters:
//  BudgetingModel - CatalogRef.BudgetingModels - the model for which the task tree is built.
//  GroupOfProcessSteps - CatalogRef.BudgetingSteps - a group of stages of the budget process.
//  StartDate - Date - the date from which the task table will be built.
//  EndDate - Date - the date by which the task table will be built.
//  SupplementFact - Boolean - If TRUE, information about the actual tasks will be filled in.
//  CheckTasksForOtherPeriods - Boolean - True if you need to check issues from other periods.
//
// Returns:
//   ValueTable - A table of values containing information about the planned and actual steps of the budget process.
//
Function BudgetingTasks(BudgetingModel, GroupOfProcessSteps, StartDate, EndDate, SupplementFact, CheckTasksForOtherPeriods)
	
	Cancel = False;
	Schedule = Constants.MainEnterpriseCalendar.Get();
	
	CheckCompletionOfChartsForPeriod(StartDate, EndDate, Schedule, Cancel);
	
	TaskTable_ = TaskTemplate();
	
	If Cancel Then
		Return TaskTable_;
	EndIf;
	
	StepTree = ModelStepTree(BudgetingModel, GroupOfProcessSteps);
	
	TaskTableParameters = New Structure("TaskTable_", TaskTable_);
	
	SupplementRepeatableStagesOfBudgetPreparation(StepTree);
	ComplementExistingBudgetPreparationProcesses(StepTree,
			BudgetingModel,
			GroupOfProcessSteps,
			TaskTableParameters,
			StartDate,
			EndDate);
	
	Query = New Query();
	ScheduleManager = New TempTablesManager;
	Query.TempTablesManager = ScheduleManager;
	Query.Text = 
		"SELECT
		|	CalendarSchedules.ScheduleDate AS ScheduleDate
		|INTO ScheduleData
		|FROM
		|	InformationRegister.CalendarSchedules AS CalendarSchedules
		|WHERE
		|	CalendarSchedules.Calendar = &WorkScheduleCalendar
		|	AND CalendarSchedules.DayAddedToSchedule
		|
		|INDEX BY
		|	ScheduleDate";
	
	Query.SetParameter("WorkScheduleCalendar", Schedule);
	Query.Execute();
	
	If SupplementFact Then
		TaskTableParameters.Insert("AddFact", SupplementFact);
		
		FactTable = TaskClassificationTableForModel(BudgetingModel, GroupOfProcessSteps);
		
		TaskTableParameters.Insert("FactTable", FactTable);
		
	EndIf;
	
	If CheckTasksForOtherPeriods Then
		
		// Let's add the end
		// of the task period to the end date + 365 working or calendar days
		// 365 - the maximum duration of the task.
		MaxDate_ = GetDateByCalendar(ScheduleManager, EndDate, 365);
		MaxDate_ = Max(MaxDate_, EndDate + 365 * 86400);
		
		EndOfModelAction = Common.ObjectAttributeValue(BudgetingModel, "ValidToDate");
		EndingDateOfPeriod= ?(EndOfModelAction <> '00010101000000', Min(MaxDate_, EndOfModelAction), MaxDate_);
		
		PeriodParameters_ = New Structure("StartDate, EndDate", StartDate, EndingDateOfPeriod);
		FillTaskTree(StepTree, TaskTableParameters, PeriodParameters_, ScheduleManager);
		
	Else
		
		PeriodParameters_ = New Structure("StartDate, EndDate", StartDate, EndDate);
		FillTaskTree(StepTree, TaskTableParameters, PeriodParameters_, ScheduleManager);
		
	EndIf;
	
	If SupplementFact Then
		FactTable = TaskTableParameters.FactTable; // TaskClassificationTableForModel -
		For Each RemainingTaskLine In TaskTableParameters.FactTable Do
			NewRow = TaskTable_.Add();
			NewRow.TaskNumber = TaskTable_.Count();
			NewRow.Task = RemainingTaskLine.Task;
			NewRow.TaskExecuted = RemainingTaskLine.Executed;
			NewRow.Performer = RemainingTaskLine.Performer;
			NewRow.Period = RemainingTaskLine.Period;
			NewRow.StartDateFact = RemainingTaskLine.StartDate;
			NewRow.Periodicity = RemainingTaskLine.Periodicity;
			NewRow.BudgetingStep = RemainingTaskLine.BudgetingStep;
			NewRow.BudgetingStepBasis = RemainingTaskLine.BudgetingStepBasis;
			EndDate = RemainingTaskLine.EndDate;
			If Not RemainingTaskLine.Executed Then
				EndDate = EndOfDay(CurrentSessionDate());
			EndIf;
			NewRow.EndDateFact = EndDate;
		EndDo;
	EndIf;
	
	Return TaskTable_;
	
EndFunction

#EndRegion

#EndRegion

#EndIf