#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure fills in the passed Gantt 
// chart with the steps of the budget process based on the passed budgeting model.
//
// Parameters:
//	Parameters - Structure - Parameter values for filling the chart:
//  	* BudgetingModel - CatalogRef.BudgetingModels - The model for which the budget process will be displayed.
//  	* Result - GanttChart - Gantt chart, where the result will be displayed.
//  	* BeginOfPeriod - Date - The beginning of the Gantt chart period.
//  	* EndOfPeriod - Date - The end of the Gantt chart period.
//  	* ReportType - Number - 0-plan, 1-fact, 2-plan and fact.
//  	* Groups - String - Name of the data layout option.
//  	* AddlParameters - Structure - Structure with additional filters.
//	StorageAddress - String - the address in the temporary storage.
//
Procedure FillDiagram(Parameters, StorageAddress) Export
	
	BudgetingModel = Parameters.BudgetingModel;
	Result     = Parameters.Result; // GanttChart -
	BeginOfPeriod = Parameters.BeginOfPeriod;
	EndOfPeriod  = Parameters.EndOfPeriod;
	ReportType     = Parameters.ReportType;
	Groups   = Parameters.Groups;
	AddlParameters  = Parameters.AddlParameters;
	
	Result.Clear();
	Result.AutoDetectWholeInterval = False;
	If BeginOfPeriod <> '000101010000' And EndOfPeriod <> '000101010000' Then
		Result.SetWholeInterval(BegOfDay(BeginOfPeriod), EndOfDay(EndOfPeriod));
	EndIf;
	
	// Preparing the tree for output to the diagram
	#Region PreparingTree
	
	If Groups = "Variant1" Then
		TaskTable_ = Catalogs.BudgetingModels.GetBudgetIssues(BudgetingModel, Undefined,
			BeginOfPeriod, EndOfPeriod, ReportType > 0, False);
	Else
		TaskTable_ = Catalogs.BudgetingModels.GetBudgetIssues(BudgetingModel, Undefined,
			BeginOfPeriod, EndOfPeriod, ReportType > 0, True);
	EndIf;
		
	TaskTable_.Columns.Add("StageOfPreparationOfBudgetsInPeriod");
	
	For Each TaskLine In TaskTable_ Do
		TaskLine.StartDateFact 		= BegOfDay(TaskLine.StartDateFact);
		TaskLine.EndDateFact 		= EndOfDay(TaskLine.EndDateFact);
	EndDo;
	
	Layout = Reports.BudgetingProcessmonitor.GetTemplate("MainDataCompositionSchema");
	
	VariantName = ?(Groups = "Variant1", "OverviewMode", "ProcessForTasks");
	Variant = Layout.SettingVariants.Find(VariantName);
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Layout));
	SettingsComposer.LoadSettings(Variant.Settings);
	
	FinancialReportingServer.SetLayoutParameter(SettingsComposer.Settings, "BeginOfPeriod", BeginOfPeriod);
	FinancialReportingServer.SetLayoutParameter(SettingsComposer.Settings, "EndOfPeriod", EndOfPeriod);
	
	ShowExecutionPlan = AddlParameters.Property("ExecutionPlan") And AddlParameters.ExecutionPlan;
	
	Filter = SettingsComposer.Settings.Filter;
	If VariantName = "OverviewMode" Then
		If ReportType = 0 Then // Plan
			FinancialReportingServer.NewFilter(Filter, "BudgetingStep", , , DataCompositionComparisonType.Filled);
		ElsIf ReportType = 1 And Not ShowExecutionPlan Then // Real
			FinancialReportingServer.NewFilter(Filter, "Task", , , DataCompositionComparisonType.Filled);
		EndIf;
		FinancialReportingServer.NewFilter(Filter, "BudgetingProcess", , , DataCompositionComparisonType.NotFilled);
	Else
		If ReportType = 0 Then // Plan
			ConfigureFilter(Filter, "GroupFact");
		ElsIf ReportType = 1 Then // Real
			ConfigureFilter(Filter, "GroupPlan");
			If ShowExecutionPlan Then
				ConfigureFilter(Filter, "Task");
			EndIf;
		Else
			If ShowExecutionPlan Then
				ConfigureFilter(Filter, "BudgetingStep");
				ConfigureFilter(Filter, "Task");
			EndIf;
		EndIf;
	EndIf;
	
	If AddlParameters <> Undefined And AddlParameters.Property("FlagPerformer") Then
		NewFilter = Filter.Items.Add(Type("DataCompositionFilterItem"));
		NewFilter.LeftValue = New DataCompositionField("PerformerOriginal");
		NewFilter.ComparisonType = DataCompositionComparisonType.Equal;
		NewFilter.RightValue = AddlParameters.ArtistValue;
		NewFilter.Use = AddlParameters.FlagPerformer;
	EndIf;
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("TaskTable_", TaskTable_);
	TreeResult = FinancialReportingServer.UploadDCSResults(Layout,
		SettingsComposer.Settings,
		ExternalDataSets,
		Groups = "Variant1");
	
	#EndRegion
	
	// Additional processing of the area for the options "Process by tasks" and "Process by performers".
	#Region WoodProcessing
	If Groups = "Variant1" Then
		TheStructureOfTheSearch = New Structure("BudgetingStepAction, BudgetingStepBasis",
												Enums.TypesOfBudgetingStepActions.StepGroupRepetition, Undefined);
		RepeatableGroups = TreeResult.Rows.FindRows(TheStructureOfTheSearch, True);
		ArrayOfRepeatable = New Array;
		For Each StringOfRepeatableGroups In RepeatableGroups Do
			ArrayOfRepeatable.Add(StringOfRepeatableGroups.BudgetingStep);
			StringOfRepeatableGroups.BudgetingStepIsFolder = True;
		EndDo;
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	BudgetingSteps.Ref AS Ref
		|FROM
		|	Catalog.BudgetingSteps AS BudgetingSteps
		|WHERE
		|	BudgetingSteps.Ref IN(&References)
		|TOTALS BY
		|	Ref HIERARCHY";
		
		ActionsSettings = Common.ObjectsAttributesValues(ArrayOfRepeatable, "SettingOfAction");
		References = New Array;
		For Each RepeatableGroup In ArrayOfRepeatable Do
			SettingOfAction = ActionsSettings[RepeatableGroup].SettingOfAction; // ValueStorage
			Action = SettingOfAction.Get();
			FoundRow = Action.Find("StepGroup", "Name");
			If FoundRow <> Undefined Then
				References.Add(FoundRow.Value);
				ActionsSettings.Insert(RepeatableGroup, FoundRow.Value);
			Else
				ActionsSettings.Insert(RepeatableGroup, Undefined);
			EndIf;
		EndDo;
		
		Query.SetParameter("References", References);
		
		HierarchyOfRequiredGroups = TreeOfStagesOfPreparationOfBudget(Query);
		MatchingParents = New Map;
		For Each RepeatableGroup In ArrayOfRepeatable Do
			LinkToGroup = ActionsSettings[RepeatableGroup];
			If LinkToGroup = Undefined Then
				Continue;
			EndIf;
			ParentArray = New Array;
			FoundRow = HierarchyOfRequiredGroups.Rows.Find(LinkToGroup, , True);
			While FoundRow <> Undefined Do
				ParentArray.Add(FoundRow.Ref);
				FoundRow = FoundRow.Parent;
			EndDo;
			MatchingParents.Insert(RepeatableGroup, CommonClientServer.CollapseArray(ParentArray));
		EndDo;
		
		CopyToFillIn = New ValueTree;
		For Each Column In TreeResult.Columns Do
			CopyToFillIn.Columns.Add(Column.Name, Column.ValueType);
		EndDo;
		
		ProcessRepeatableProcessSteps(CopyToFillIn, TreeResult, MatchingParents);
		
		AugmentOutputTreeWithProcesses(BudgetingModel, CopyToFillIn, TaskTable_, BeginOfPeriod, EndOfPeriod, AddlParameters);
		
		TreeResult = CopyToFillIn;
		
	Else
		ByAssignees = Groups = "Variant3";
		PeriodsTable = BreakStepTableByPeriod(TreeResult, BudgetingModel, ByAssignees);
		TreeResult = CreateTreeWithDimensionsForOutputFromDataTable(TreeResult, PeriodsTable, ReportType, ByAssignees);
		If ByAssignees Then
			TreeResult.Rows.Sort("Performer, StartDate" + ?(ReportType = 1, "Real", ""), True);
		Else
			TreeResult.Rows.Sort("StartDate" + ?(ReportType = 1, "Real", ""), True);
		EndIf;
	EndIf;
	
	#EndRegion
	
	If ReportType <> 1 Then
		Series = Result.Series.Add();
		Series.Value = "Plan";
		Series.Text = "Plan";
	EndIf;
	
	If ReportType > 0 Then
		SeriesFact = Result.Series.Add();
		SeriesFact.Value = "Real";
		SeriesFact.Text = "Real";
	EndIf;
	
	SeriesStructure_ = New Structure("Plan, Real", Series, SeriesFact);
	
	OutputTreeToGanttChart(Result, TreeResult, SeriesStructure_, ReportType, Groups, ShowExecutionPlan);
	
	ArrangeDiagramAfterOutput(Result, ReportType, Groups, BeginOfPeriod, EndOfPeriod);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// Gets information about budget tasks and puts the result in storage 
// for background execution.
//
// Parameters:
//  Parameters - Structure - The values of the selections to generate the report.
// 	StorageAddress - String - the address in the temporary storage.
//
Procedure GetInformationAboutIssues(Parameters, StorageAddress) Export
	
	LineUp = Reports.PerformanceOfBudgetProcessTasks.GetTemplate("MainDataCompositionSchema");
	
	Settings = New DataCompositionSettings;
	
	GroupingDetails = Settings.Structure.Add(Type("DataCompositionGroup"));
	GroupingDetails.Use = True;
	
	SelectedField = GroupingDetails.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Use = True;
	SelectedField.Field = New DataCompositionField("NotCompleted");
	SelectedField.Title = "NotCompleted";

 	SelectedField = GroupingDetails.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Use = True;
	SelectedField.Field = New DataCompositionField("Overdue1");
	SelectedField.Title = "Overdue1";
	
	Filter = Settings.Filter;
	NewFilter = Filter.Items.Add(Type("DataCompositionFilterItem"));
	NewFilter.LeftValue = New DataCompositionField("BudgetingModel");
	NewFilter.ComparisonType = DataCompositionComparisonType.Equal;
	NewFilter.RightValue = Parameters.BudgetingModel;
	NewFilter.Use = True;
	
	Parameter = Settings.DataParameters.Items.Add();
	Parameter.Parameter = New DataCompositionParameter("CurrentDate");
	Parameter.Use = True;
	Parameter.Value = CurrentSessionDate();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	Template = TemplateComposer.Execute(LineUp, Settings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template);
	CompositionProcessor.Reset();
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	
	Table = New ValueTable;
	OutputProcessor.SetObject(Table);
	OutputProcessor.Output(CompositionProcessor);
	
	TitleTemplate1 = NStr("vi = 'Nhiệm vụ đã hoàn thành:%1, trong đó quá hạn: %2';
							|ru = 'Выполняется задач: %1, из них просрочено: %2';
							|en = 'Tasks in progress: %1, overdue: %2'; fa = 'Tasks in progress: %1, overdue: %2';
							|it = 'Obiettivi in esecuzione: %1, tra cui scaduti: %2';
							|pl = 'Wykonywanych zadań: %1, z nich są przeterminowane: %2';
							|tr = 'Vadesi geçmiş olan: %2 görev gerçekleştiriliyor: %1'");
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, Table.Total("NotCompleted"), Table.Total("Overdue1"));
	
	PutToTempStorage(Title, StorageAddress);
	
EndProcedure

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.BudgetingProcessmonitor);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region PreparingTreeOfValuesForOutputToDiagram


// Returns a tree of budget preparation stages
// 
// Parameters:
// 	Query - Query - Request for a selection of stages.
// Returns:
// 	ValueTree - the tree of stages of preparation of budgets:
// 	 *Ref - CatalogRef.BudgetingSteps - The preparation of the budget.
Function TreeOfStagesOfPreparationOfBudget(Query)
	QueryResult = Query.Execute();
	HierarchyOfRequiredGroups = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	Return HierarchyOfRequiredGroups;
EndFunction

Procedure ConfigureFilter(Filter, WhatToDisable)
	
	For Each Item In Filter.Items Do
		If Item.Presentation = WhatToDisable Then
			Filter.Items.Delete(Item);
			Return;
		EndIf;
		If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then
			ConfigureFilter(Item, WhatToDisable);
		EndIf;
	EndDo;
	
EndProcedure

Function BreakStepTableByPeriod(TreeResult, BudgetingModel, ByAssignees = False)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	EnumPeriodicity.Ref AS Periodicity
		|FROM
		|	Enum.Periodicity AS EnumPeriodicity
		|WHERE
		|	EnumPeriodicity.Ref IN
		|			(SELECT DISTINCT
		|				BudgetingSteps.Periodicity
		|			FROM
		|				Catalog.BudgetingSteps AS BudgetingSteps
		|			WHERE
		|				BudgetingSteps.Owner = &BudgetingModel)
		|
		|ORDER BY
		|	EnumPeriodicity.Order DESC";

	Query.SetParameter("BudgetingModel", BudgetingModel);
		
	QueryResult = Query.Execute();
	OrdersOfPeriodicity = QueryResult.Unload();
	
	TreeOfPeriods = New ValueTree;
	TreeOfPeriods.Columns.Add("Period");
	TreeOfPeriods.Columns.Add("Periodicity");
	If ByAssignees Then
		TreeOfPeriods.Columns.Add("Performer");
	EndIf;
	
	ModelStartDate = Common.ObjectAttributeValue(BudgetingModel, "ValidOnDate");
	
	For Each ResultString1 In TreeResult Do
		
		If ByAssignees Then
			SearchString = TreeOfPeriods.Rows.Find(ResultString1.Performer);
			If SearchString = Undefined Then
				SearchString = TreeOfPeriods.Rows.Add();
				SearchString.Performer = ResultString1.Performer;
			EndIf;
		Else
			SearchString = TreeOfPeriods;
		EndIf;
		
		FoundPeriodTreeString = OrdersOfPeriodicity.Find(ResultString1.Periodicity);
		For Cnt = 0 To OrdersOfPeriodicity.IndexOf(FoundPeriodTreeString) Do
			PeriodString_ = OrdersOfPeriodicity[Cnt];
			Period = WorkingWithClientServerPeriods.BeginningDateOfPeriod(ResultString1.Period, PeriodString_.Periodicity);
			Period = Max(ModelStartDate, Period); // correction for the beginning of the model
			FoundRow = SearchString.Rows.Find(Period);
			If FoundRow = Undefined Then
				FoundRow = SearchString.Rows.Add();
				FoundRow.Period = Period;
				FoundRow.Periodicity = PeriodString_.Periodicity;
				If ByAssignees Then
					FoundRow.Performer = ResultString1.Performer;
				EndIf;
			EndIf;
			SearchString = FoundRow;
		EndDo;
		
	EndDo;
	
	Return TreeOfPeriods;
	
EndFunction

Function CreateTreeWithDimensionsForOutputFromDataTable(TreeResult, TreeOfPeriods, ReportType, ByAssignees, RowsResult = Undefined)
	
	If RowsResult = Undefined Then
		RowsResult = New ValueTree;
		For Each Column In TreeResult.Columns Do
			RowsResult.Columns.Add(Column.Name, Column.ValueType);
		EndDo;
	EndIf;
	
	For Each PeriodString_ In TreeOfPeriods.Rows Do
		
		// adding a period
		NewRow = RowsResult.Rows.Add();
		FillPropertyValues(NewRow, PeriodString_);
		If Not ByAssignees Or ValueIsFilled(PeriodString_.Parent) Then
			// adding all the tasks of the period to the subordinate lines
			TheStructureOfTheSearch = New Structure("Period, Periodicity", PeriodString_.Period, PeriodString_.Periodicity);
			If ByAssignees Then
				TheStructureOfTheSearch.Insert("Performer", PeriodString_.Performer);
			EndIf;
			FoundRows = TreeResult.FindRows(TheStructureOfTheSearch);
			For Each FoundRow In FoundRows Do
				TaskLine = NewRow.Rows.Add();
				FillPropertyValues(TaskLine, FoundRow);
				If ValueIsFilled(FoundRow.BudgetingStepBasis) Then
					TaskLine.BudgetingStepDescription = 
						FoundRow.BudgetingStepBasisDescription + " ("
							+ FoundRow.BudgetingStepDescription + "%1)";
				ElsIf ValueIsFilled(TaskLine.BudgetingStep) Then
					TaskLine.BudgetingStepDescription = 
							TaskLine.BudgetingStepDescription + "%1";
				ElsIf ValueIsFilled(FoundRow.TaskName_) Then
					TaskLine.BudgetingStepDescription = 
							FoundRow.TaskName_ + "%1";
				Else
					TaskLine.BudgetingStepDescription = "";
				EndIf;
				Process_ = "";
				If ValueIsFilled(FoundRow.BudgetingProcess) Then
					Process_ = NStr("vi = ', Quy trình số';
									|ru = ', Процесс №';
									|en = ', Process No.'; fa = ', Process No.';
									|it = ', Processo №';
									|pl = ', Proces Nr';
									|tr = ', Süreç numarası'") + FoundRow.BudgetPreparationProcessNumber;
				EndIf;
				TaskLine.BudgetingStepDescription = 
					StringFunctionsClientServer.SubstituteParametersToString(TaskLine.BudgetingStepDescription, Process_);
			EndDo;
		EndIf;
		// adding subordinate lines
		CreateTreeWithDimensionsForOutputFromDataTable(TreeResult, PeriodString_, ReportType, ByAssignees, NewRow);
		
		If Not ByAssignees Or ValueIsFilled(PeriodString_.Parent) Then
			FieldName = "StartDate" + ?(ReportType = 1, "Real", "");
			For Each SubordinateRow In NewRow.Rows Do
				If Not ValueIsFilled(NewRow[FieldName]) Then
					NewRow[FieldName] = SubordinateRow.Period;
				Else
					NewRow[FieldName] = Min(NewRow[FieldName], SubordinateRow.Period);
				EndIf;
			EndDo;
		EndIf;
		
	EndDo;
	
	Return RowsResult;
	
EndFunction

Procedure ProcessRepeatableProcessSteps(DestinationTree, StageTree, MatchingParents)
	
	For Each TreeRow In StageTree.Rows Do
		NeedToAdd = True;
		If ValueIsFilled(TreeRow.BudgetingStepBasis) Then
			LinkGroupParents = MatchingParents[TreeRow.BudgetingStep];
			If LinkGroupParents.Find(TreeRow.BudgetingStepBasis) <> Undefined Then
				NeedToAdd = False;
			Else
				TreeRow.BudgetingStepDescription = TreeRow.BudgetingStepBasisDescription;
				TreeRow.BudgetingStepEmployeeResponsible = TreeRow.BudgetingStepBasisEmployeeResponsible;
				TreeRow.BudgetingStepIsFolder = TreeRow.BudgetingStepBasisIsFolder;
				TreeRow.BudgetingStepExecuteAutomatically = TreeRow.BudgetingStepBasisExecuteAutomatically;
			EndIf;
		EndIf;
		If NeedToAdd Then
			NewRow = DestinationTree.Rows.Add();
			FillPropertyValues(NewRow, TreeRow);
			Receiver = NewRow;
		Else
			Receiver = DestinationTree;
		EndIf;
		ProcessRepeatableProcessSteps(Receiver, TreeRow, MatchingParents);
	EndDo;
	
EndProcedure


// Prepares the result tree.
// 
// Parameters:
// 	Process_ - DocumentRef.BudgetingProcess - Document of the preparation process.
// 	Source - ValueTreeRowCollection - LongDesc
// 	Receiver - ValueTreeRowCollection - LongDesc
// 	TaskTable_ - ValueTable - The task table.
// 	CacheOfStageDetails - ValueTable - Cache Of Stage Details:
// 	 *Description - String - Name of the stage.
// 	CacheOfTaskDetails - ValueTable - Cache Of Task Details:
// 	 *Description - String - Name of the task.
// Returns:
// 	Boolean - LongDesc
Function CopyProcessTreeToResultTree(Process_, Source, Receiver, 
									TaskTable_, CacheOfStageDetails, CacheOfTaskDetails)
	
	ThereAreEndStagesInLevel = False;
	For Each SourceRow1 In Source Do
		
		NewRow = Receiver.Add();
		FillPropertyValues(NewRow, SourceRow1);
		NewRow.BudgetingStepIsFolder = SourceRow1.IsFolder;
		Attributes = CacheOfStageDetails.Find(NewRow.BudgetingStep);
		NewRow.BudgetingStepExecuteAutomatically = Attributes.ExecuteAutomatically;
		
		If ValueIsFilled(NewRow.BudgetingStepBasis) Then
			Attributes = CacheOfStageDetails.Find(NewRow.BudgetingStepBasis);
			NewRow.BudgetingStep 							= NewRow.BudgetingStepBasis;
			NewRow.BudgetingStepDescription 				= Attributes.Description;
			NewRow.BudgetingStepEmployeeResponsible 			= Attributes.EmployeeResponsible;
			NewRow.BudgetingStepIsFolder 				= Attributes.IsFolder;
			NewRow.BudgetingStepExecuteAutomatically 	= Attributes.ExecuteAutomatically;
		EndIf;
		NewRow.BudgetingProcess = Process_;
		
		If SourceRow1.IsFolder Then
			ThereAreEndStagesInSubordinates = CopyProcessTreeToResultTree(Process_, SourceRow1.Rows, NewRow.Rows, 
																						TaskTable_, CacheOfStageDetails, CacheOfTaskDetails);
			If Not ThereAreEndStagesInSubordinates Then
				Receiver.Delete(NewRow);
			Else
				ThereAreEndStagesInLevel = True;
			EndIf;
			
		Else
			
			TheStructureOfTheSearch = New Structure(
				"BudgetingStep, BudgetingStepBasis, BudgetingProcess",
				SourceRow1.BudgetingStep, SourceRow1.BudgetingStepBasis, Process_);
			FoundRows = TaskTable_.FindRows(TheStructureOfTheSearch);
			
			ThereAreEndStagesInSubordinates = False;
			For Each FoundRow In FoundRows Do
				
				NewSubordinateLine = NewRow.Rows.Add();
				FillPropertyValues(NewSubordinateLine, NewRow);
				FillPropertyValues(NewSubordinateLine, FoundRow);
				
				If ValueIsFilled(FoundRow.Task) Then
					Attributes = CacheOfTaskDetails.Find(FoundRow.Task);
					NewSubordinateLine.TaskDate_2 = Attributes.Date;
					NewSubordinateLine.TaskName_ = Attributes.Description;
					NewSubordinateLine.TaskNumber_ = Attributes.Number;
					NewSubordinateLine.TaskDueDate_ = Attributes.TaskDueDate;
				EndIf;
			
				ThereAreEndStagesInSubordinates = True;
				
			EndDo;
			
			If Not ThereAreEndStagesInSubordinates Then
				Receiver.Delete(NewRow);
			Else
				ThereAreEndStagesInLevel = True;
			EndIf;
			
		EndIf;
	EndDo;
	
	Return ThereAreEndStagesInLevel;
	
EndFunction

Function FindMasterPlanLinesToFillInTasks(TasksTree, Result = Undefined)
	
	If Result = Undefined Then
		Result = New Array;
	EndIf;
	
	For Each TreeRow In TasksTree.Rows Do
		
		If Not TreeRow.Rows.Count() And Not ValueIsFilled(TreeRow.Task) Then
			Result.Add(TreeRow);
		Else
			FindMasterPlanLinesToFillInTasks(TreeRow, Result);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure FillInMasterPlanTasksForFirstProcess(Process_, ArrayOfRowsToFillInTasks, 
													TableOfFillingTasks, CacheOfTaskDetails)
													
	ArrayToDelete = New Array;
	IndexOf = 0;
	For Each LineToFillIn In ArrayOfRowsToFillInTasks Do
		
		TheStructureOfTheSearch = New Structure();
		TheStructureOfTheSearch.Insert("BudgetingProcess", Process_); 
		TheStructureOfTheSearch.Insert("BudgetingStep", LineToFillIn.BudgetingStep);
		TheStructureOfTheSearch.Insert("BudgetingStepBasis", LineToFillIn.BudgetingStepBasis);
		TheStructureOfTheSearch.Insert("Period", LineToFillIn.Period);
		
		FoundRows = TableOfFillingTasks.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() Then
			FillPropertyValues(LineToFillIn, FoundRows[0], 
				"Performer, Task, TaskExecuted, StartDateFact, EndDateFact");
			If ValueIsFilled(FoundRows[0].Task) Then
				TaskDetails__ = CacheOfTaskDetails.Find(FoundRows[0].Task);
				LineToFillIn.TaskNumber_ = TaskDetails__.Number;
				LineToFillIn.TaskDate_2 = TaskDetails__.Date;
				LineToFillIn.TaskName_ = TaskDetails__.Description;
				LineToFillIn.TaskDueDate_ = TaskDetails__.TaskDueDate;
			EndIf;
			TableOfFillingTasks.Delete(FoundRows[0]);
			ArrayToDelete.Insert(0, IndexOf);
		EndIf;
		
		IndexOf = IndexOf + 1;
		
	EndDo;
	
	For Each Item In ArrayToDelete Do
		ArrayOfRowsToFillInTasks.Delete(Item);
	EndDo;
	
EndProcedure

Procedure AugmentOutputTreeWithProcesses(BudgetingModel, TasksTree, TaskTable_, StartDate, EndDate, AddlParameters)
	
	Processes = TaskTable_.UnloadColumn("BudgetingProcess");
	Processes = CommonClientServer.CollapseArray(Processes);
	IndexOf = Processes.Find(Documents.BudgetingProcess.EmptyRef());
	If IndexOf <> Undefined Then
		Processes.Delete(IndexOf);
	EndIf;
	AttributesArray = Common.ObjectsAttributesValues(Processes, "HierarchySettings, Date");
	ListOfProcesses = New ValueList;
	ListOfProcesses.LoadValues(Processes);
	For Each ListItem In ListOfProcesses Do
		ListItem.Presentation = AttributesArray[ListItem.Value].Date;
	EndDo;
	ListOfProcesses.SortByPresentation();
	Processes = ListOfProcesses.UnloadValues();
	
	Query = New Query();
	Query.Text = 
	"SELECT * INTO FilteredTasks FROM &TaskTable_ AS Table
	|WHERE Table.Period BETWEEN &StartDate AND &EndDate AND &FilterPerArtist
	|;
	|SELECT * FROM FilteredTasks
	|;
	|SELECT
	|	BudgetingSteps.Ref,
	|	BudgetingSteps.Description,
	|	BudgetingSteps.IsFolder,
	|	BudgetingSteps.Action,
	|	BudgetingSteps.EmployeeResponsible,
	|	BudgetingSteps.ExecuteAutomatically
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|WHERE
	|	BudgetingSteps.Owner = &BudgetingModel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BudgetTask.Ref,
	|	BudgetTask.TaskDueDate,
	|	BudgetTask.Description,
	|	BudgetTask.Number,
	|	BudgetTask.Date
	|FROM
	|	Task.BudgetTask AS BudgetTask
	|WHERE
	|	BudgetTask.Ref IN(&Tasks)";
	
	Query.SetParameter("BudgetingModel", BudgetingModel);
	TaskArray = TaskTable_.UnloadColumn("Task");
	TaskArray = CommonClientServer.CollapseArray(TaskArray);
	Query.SetParameter("Tasks", TaskArray);
	CopyOfTaskTable = TaskTable_.Copy();
	CopyOfTaskTable.Columns.Delete("StageOfPreparationOfBudgetsInPeriod");
	CopyOfTaskTable.Columns.Delete("SettingOfAction");
	CopyOfTaskTable.Columns.Delete("PreviousTasks");
	Query.SetParameter("TaskTable_", CopyOfTaskTable);
	Query.SetParameter("StartDate", StartDate);
	Query.SetParameter("EndDate", EndDate);
	If AddlParameters <> Undefined And AddlParameters.Property("FlagPerformer") Then
		If AddlParameters.FlagPerformer Then
			Query.SetParameter("Performer", AddlParameters.ArtistValue);
			Query.Text = StrReplace(Query.Text, "&FilterPerArtist", "Table.Performer = &Performer");
		Else
			Query.Text = StrReplace(Query.Text, "&FilterPerArtist", "TRUE");
		EndIf;
	Else
		Query.Text = StrReplace(Query.Text, "&FilterPerArtist", "TRUE");
	EndIf;
	
	ResultsArray = Query.ExecuteBatch();
	TableOfFillingTasks = ResultsArray[1].Unload();
	CacheOfStageDetails = ResultsArray[2].Unload();
	CacheOfTaskDetails = ResultsArray[3].Unload();
	
	GenerateIssuesAutomatically = Common.ObjectAttributeValue(BudgetingModel, "AutomaticallyGenerateTasks");
	If Not GenerateIssuesAutomatically Then
		ArrayOfRowsToFillInTasks = FindMasterPlanLinesToFillInTasks(TasksTree);
	EndIf;
	
	For Each Process_ In Processes Do
		
		If Not GenerateIssuesAutomatically Then
			FillInMasterPlanTasksForFirstProcess(Process_, ArrayOfRowsToFillInTasks, TableOfFillingTasks, CacheOfTaskDetails);
		EndIf;
		
		If TableOfFillingTasks.Find(Process_, "BudgetingProcess") = Undefined Then
			Continue;
		EndIf;
		
		HierarchyTreeByProcess = Documents.BudgetingProcess.HierarchyOfProcessStepsByDocument(
														AttributesArray[Process_].HierarchySettings.Unload());
		HierarchyTreeByProcess.Rows.Sort("Code", True);
		
		RowOfProcess = TasksTree.Rows.Add();
		RowOfProcess.BudgetingProcess = Process_;
		ThereAreEndStagesInLevel = CopyProcessTreeToResultTree(Process_, HierarchyTreeByProcess.Rows, RowOfProcess.Rows, 
																				TableOfFillingTasks, CacheOfStageDetails, CacheOfTaskDetails);
		If Not ThereAreEndStagesInLevel Then
			TasksTree.Rows.Delete(RowOfProcess);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region OutputTreeOfValuesToGanttChartUtility

Function GetTreeValue(TreeRow)
	
	Columns = TreeRow.Owner().Columns;
	If ValueIsFilled(TreeRow.BudgetingStep)
		Or TreeRow.BudgetingStep = Catalogs.BudgetingSteps.EmptyRef() Then
		Return TreeRow.BudgetingStep;
	ElsIf Columns.Find("Period") <> Undefined
		And ValueIsFilled(TreeRow.Period) Then
		Return TreeRow.Period;
	ElsIf Columns.Find("Performer") <> Undefined
		And ValueIsFilled(TreeRow.Performer) Then
		Return TreeRow.Performer;
	ElsIf Columns.Find("BudgetingProcess") <> Undefined
		And ValueIsFilled(TreeRow.BudgetingProcess) Then
		Return TreeRow.BudgetingProcess;
	Else
		Raise NStr("vi = 'Biểu đồ Gantt không xác định nhóm quy trình ngân sách!';
					|ru = 'Неизвестная группировка диаграммы ганта бюджетного процесса!';
					|en = 'Unknown grouping of Gantt chart of the budget process.'; fa = 'Unknown grouping of Gantt chart of the budget process.';
					|it = 'Raggruppamento sconosciuto diagramma di Gantt del processo di budget!';
					|pl = 'Nieznane grupowanie diagramu Gantta procesu budżetowego!';
					|tr = 'Bütçe sürecindeki Gantt çizelgesinin bilinmeyen gruplaması!'")
	EndIf;
	
EndFunction

Function TaskIntervals()
	
	IntervalsTable = New ValueTable;
	IntervalsTable.Columns.Add("StartDate");
	IntervalsTable.Columns.Add("EndDate");
	IntervalsTable.Columns.Add("StartDateFact");
	IntervalsTable.Columns.Add("EndDateFact");
	IntervalsTable.Columns.Add("Task");
	IntervalsTable.Columns.Add("TaskName_");
	IntervalsTable.Columns.Add("TaskDate_2");
	IntervalsTable.Columns.Add("TaskNumber_");
	IntervalsTable.Columns.Add("TaskExecuted");
	IntervalsTable.Columns.Add("TaskDueDate_");
	IntervalsTable.Columns.Add("BudgetingStep");
	IntervalsTable.Columns.Add("BudgetingStepDescription");
	IntervalsTable.Columns.Add("Periodicity");
	IntervalsTable.Columns.Add("Period");
	
	Return IntervalsTable;
	
EndFunction

#EndRegion

#Region PreparingTableOfValuesWithNonOverlappingIntervals

Function IntersectionOfIntervals(Begin1, End1, Begin2, End2)
	
	// The beginning of 2 lies on the segment 1
	IntersectionOfIntervals 	= Begin1 <= Begin2 And Begin2 <= End1;
	// The end2 lies on the segment 1
	IntersectionOfIntervals 	= IntersectionOfIntervals Or (Begin1 <= End2 And End2 <= End1);
	// The end2 lies on the segment 1
	IntersectionOfIntervals 	= IntersectionOfIntervals Or (Begin2 <= Begin1 And End1 <= End2);
	
	Return IntersectionOfIntervals;
	
EndFunction


// Cuts the date interval for one table from another table and puts the value in the result Table.
// 
// Parameters:
// 	ResultTable1 - ValueTable - table of the result of cutting intervals:
// 	 *Type - String - type.
// 	 *StartDate - Date - start date.
// 	 *EndDate - Date - Expiry date.
// 	 *Rows - Array - Lines.
// 	WhatToCut - String - value of the "Type" column.
// 	FromWhereToCut - Structure - LongDesc:
// 	*Generated_1 - Undefined - the key structure.
// 	*Real - Undefined - the key structure
Procedure CutIntervalFromIntersecting(ResultTable1, WhatToCut, FromWhereToCut)
	
	TableRowsWhatToCut = ResultTable1.FindRows(New Structure("Type", WhatToCut));
	
	For Each KeyAndValue In FromWhereToCut Do
		For Each TableRowWhatToCut In TableRowsWhatToCut Do
			TableRowsFromWhereToCut = ResultTable1.FindRows(New Structure("Type", KeyAndValue.Key));
			For Each TableRowFromWhereToCut In TableRowsFromWhereToCut Do
				IntersectionOfIntervals 	= IntersectionOfIntervals(TableRowWhatToCut.StartDate, 
																TableRowWhatToCut.EndDate, 
																TableRowFromWhereToCut.StartDate, 
																TableRowFromWhereToCut.EndDate);
				If IntersectionOfIntervals Then
					
					// to decrypt, copy the rows of the source table
					For Each ResultString1 In TableRowFromWhereToCut.Rows Do
						TableRowWhatToCut.Rows.Add(ResultString1);
					EndDo;
					
					// The interval "from where" to the left of the interval we want to cut
					If TableRowFromWhereToCut.StartDate < TableRowWhatToCut.StartDate
						And TableRowFromWhereToCut.EndDate <= TableRowWhatToCut.EndDate Then
						TableRowFromWhereToCut.EndDate = TableRowWhatToCut.StartDate - 1;
					// The interval "from where" to the right of the interval we want to cut
					ElsIf TableRowFromWhereToCut.StartDate >= TableRowWhatToCut.StartDate
						And TableRowFromWhereToCut.EndDate > TableRowWhatToCut.EndDate Then
						TableRowFromWhereToCut.StartDate = TableRowWhatToCut.EndDate + 1;
					// The interval "from where" is greater than the interval we want to cut
					ElsIf TableRowFromWhereToCut.StartDate < TableRowWhatToCut.StartDate
						And TableRowFromWhereToCut.EndDate > TableRowWhatToCut.EndDate Then
						NewRow = ResultTable1.Add();
						FillPropertyValues(NewRow, TableRowFromWhereToCut);
						TableRowFromWhereToCut.StartDate = TableRowWhatToCut.EndDate + 1;
						NewRow.EndDate = TableRowWhatToCut.StartDate - 1;
					// The interval "from where" is included in the interval we want to cut
					Else
						ResultTable1.Delete(TableRowFromWhereToCut);
					EndIf;
					
				EndIf;
				
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure


// Processing intersections of intervals.
// 
// Parameters:
// 	ResultRow - ValueTableRow - result table row:
// 	 *StartDate - Date - start date.
// 	 *EndDate - Date - Expiry date.
// 	 *Rows - Array - Lines.
// 	FoundRows - Array of ValueTableRow - rows with columns:
// 	 *StartDate - Date - start date.
// 	 *EndDate - Date - Expiry date.
Procedure HandleIntersectionsOfIntervalsAfterChanges(ResultRow, FoundRows)
	
	StartDateInt1 = ResultRow.StartDate;
	EndDateInt1 = ResultRow.EndDate;
	ThereWereIntersections = False;
	For Each TableRowFromWhereToCut In FoundRows Do
		If TableRowFromWhereToCut = ResultRow Then
			Continue;
		EndIf;
		StartDateInt2 = TableRowFromWhereToCut.StartDate;
		EndDateInt2 = TableRowFromWhereToCut.EndDate;
		IntersectionOfIntervals = IntersectionOfIntervals(StartDateInt1, EndDateInt1, StartDateInt2, EndDateInt2);
		If IntersectionOfIntervals Then
			ResultRow.StartDate = Min(StartDateInt1, StartDateInt2);
			ResultRow.EndDate = Max(EndDateInt1, EndDateInt2);
			For Each InitialString In TableRowFromWhereToCut.Rows Do
				ResultRow.Rows.Add(InitialString);
			EndDo;
			ResultRow.Owner().Delete(TableRowFromWhereToCut);
			ThereWereIntersections = True;
		EndIf;
	EndDo;
	
	If ThereWereIntersections Then
		FoundRows = ResultRow.Owner().FindRows(New Structure("Type", ResultRow.Type));
		HandleIntersectionsOfIntervalsAfterChanges(ResultRow, FoundRows);
	EndIf;
	
EndProcedure


// Processes the interval string.
// 
// Parameters:
// 	Type - String - type.
// 	FoundRow - ValueTableRow, Undefined - the found row of the interval table:
// 	*StartDate - Date - start date.
// 	*EndDate - Date - Expiry date.
// 	ResultTable1 - ValueTable - Result table:
// 	*StartDate - Date - start date.
// 	*EndDate - Date - Expiry date.
// 	*Rows - Array - Lines.
// 	ShowExecutionPlan - Boolean - Show the execution plan.
// 	CurDate - Date - Current date.
Procedure ProcessIntervalString(Type, FoundRow, ResultTable1, ShowExecutionPlan, CurDate)
	
	If Type <> "Plan" Then
		
		If Not ShowExecutionPlan Then
			If Not ValueIsFilled(FoundRow.Task) Then
				FoundRow[Type + "Processed"] = True;
				Return;
			EndIf;
		EndIf;
		
		Compatible = False;
		TaskExecuted = False;
		If TypeOf(FoundRow.TaskExecuted) = Type("Boolean") Then
			TaskExecuted = FoundRow.TaskExecuted;
		EndIf;
		TaskDueDate = FoundRow.EndDateFact;
		If TypeOf(FoundRow.TaskDueDate_) = Type("Date") Then
			TaskDueDate = FoundRow.TaskDueDate_;
		EndIf;
		If Not ValueIsFilled(TaskDueDate) Then
			TaskDueDate = Date(1, 1, 1);
		EndIf;
		
		If Type = "Real" And TaskExecuted = True Then
			Compatible = True;
		ElsIf Type = "IsTaskOverdue" And TaskExecuted = False
			And TaskDueDate <= CurDate Then
			Compatible = True;
		ElsIf Type = "Generated_1" And TaskExecuted = False
			And TaskDueDate > CurDate Then
			Compatible = True;
		EndIf;
		
		If Not Compatible Then
			FoundRow[Type + "Processed"] = True;
			Return
		EndIf;
		
	Else
		
		If Not ValueIsFilled(FoundRow.BudgetingStep) Then
			FoundRow[Type + "Processed"] = True;
			Return
		EndIf;
		
	EndIf;
	
	FoundRows = ResultTable1.FindRows(New Structure("Type", Type));
	
	For Each ResultRow In FoundRows Do
		StartDateInt1 = ResultRow.StartDate;
		EndDateInt1 = ResultRow.EndDate;
		StartDateInt2 = FoundRow["StartDate" 		+ ?(Type = "Plan", "", "Real")];
		EndDateInt2 = FoundRow["EndDate" 	+ ?(Type = "Plan", "", "Real")];
		IntersectionOfIntervals = IntersectionOfIntervals(StartDateInt1, EndDateInt1, StartDateInt2, EndDateInt2);
		If IntersectionOfIntervals Then
			ResultRow.StartDate = Min(StartDateInt1, StartDateInt2);
			ResultRow.EndDate = Max(EndDateInt1, EndDateInt2);
			HandleIntersectionsOfIntervalsAfterChanges(ResultRow, FoundRows);
			FoundRow[Type + "Processed"] = True;
			ResultRow.Rows.Add(FoundRow);
			Return
		EndIf;
	EndDo;
	
	ResultRow = ResultTable1.Add();
	ResultRow.Type = Type;
	ResultRow.StartDate = FoundRow["StartDate" + ?(Type = "Plan", "", "Real")];
	ResultRow.EndDate = FoundRow["EndDate" + ?(Type = "Plan", "", "Real")];
	FoundRow[Type + "Processed"] = True;
	ResultRow.Rows = New Array;
	ResultRow.Rows.Add(FoundRow);
	
EndProcedure

Function ConvertIntervalTable(IntervalsTable, ShowExecutionPlan)
	
	ResultTable1 = IntervalsTable.CopyColumns("StartDate, EndDate");
	ResultTable1.Columns.Add("Type");
	ResultTable1.Columns.Add("Rows");
	
	ResultTable1.Indexes.Add("Type");
	
	CurDate = CurrentSessionDate();
	
	StructureOfTypes = New Structure("Plan, Real, IsTaskOverdue, Generated_1");
	For Each KeyAndValue In StructureOfTypes Do
		
		Type = KeyAndValue.Key;
		IntervalsTable.Columns.Add(Type + "Processed", New TypeDescription("Boolean"));
		
		FoundRow = IntervalsTable.Find(False, Type + "Processed");
		While FoundRow <> Undefined Do
			ProcessIntervalString(Type, FoundRow, ResultTable1, ShowExecutionPlan, CurDate);
			FoundRow = IntervalsTable.Find(False, Type + "Processed");
		EndDo;
		
	EndDo;
	
	CutIntervalFromIntersecting(ResultTable1, "IsTaskOverdue", New Structure("Generated_1, Real"));
	CutIntervalFromIntersecting(ResultTable1, "Generated_1", New Structure("Real"));
	
	Return ResultTable1;
	
EndFunction

#EndRegion

#Region OutputTreeOfValuesToGanttChart


// Adds the chart interval.
// 
// Parameters:
// 	Interval - GanttChartValue - the interval of the chart.
// 	TreeRow - ValueTableRow - Tree Line:
// 	*StartDate - Date - start date.
// 	*EndDate - Date - Expiry date.
// 	Type - String - Type
// 	TaskLevel - Boolean - this is the task level.
Procedure AddChartSpacing(Interval, TreeRow, Type, TaskLevel = False)
	
	Subinterval = Interval.Add();
	Subinterval.Begin 	= TreeRow.StartDate;
	Subinterval.End 	= TreeRow.EndDate;
	If TreeRow.Type = "Plan" Then
		Subinterval.Color 	= StyleColors.ResultIsExpectedColor;
	ElsIf TreeRow.Type = "Real" Then
		Subinterval.Color 	= StyleColors.SuccessResultColor;
	ElsIf TreeRow.Type = "IsTaskOverdue" Then
		Subinterval.Color 	= WebColors.Red;
	ElsIf TreeRow.Type = "Generated_1" Then
		Subinterval.Color 	= WebColors.Orange;
	Else
		Subinterval.Color 	= WebColors.Black;
	EndIf;
	
	DecryptionArray = New ValueList;
	For Each TaskLine In TreeRow.Rows Do
		PeriodPresentation = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(TaskLine.Period, TaskLine.Periodicity);
		If Type = "Real" And ValueIsFilled(TaskLine.Task) Then
			ValuePresentation = NStr("vi = '%1 №%2 ngày %3 (%4)';
									|ru = '%1 №%2 от %3 (%4)';
									|en = '%1 No.%2 from %3 (%4)'; fa = '%1 No.%2 from %3 (%4)';
									|it = '%1 №%2 del %3 (%4)';
									|pl = '%1 Nr%2 z dnia %3 (%4)';
									|tr = '%3 (%4) itibarıyla %1 No.%2'");
			ValuePresentation = StringFunctionsClientServer.SubstituteParametersToString(
												ValuePresentation, 
												TaskLine.TaskName_,
												TaskLine.TaskNumber_,
												Format(TaskLine.TaskDate_2, "DLF=D"),
												PeriodPresentation);
			Value = TaskLine.Task;
		Else
			ValuePresentation = TaskLine.BudgetingStepDescription + " (" + PeriodPresentation + ")";
			Value = TaskLine.BudgetingStep;
		EndIf;
		If TaskLevel Then
			ComplementingPresentation = NStr("vi = 'từ %1 đến %2';
											|ru = 'с %1 по %2';
											|en = 'from %1 to %2'; fa = 'from %1 to %2';
											|it = 'da %1 fino a %2';
											|pl = 'od %1 do %2';
											|tr = '%1 itibaren %2 kadar'");
			ComplementingPresentation = StringFunctionsClientServer.SubstituteParametersToString(
													ComplementingPresentation,
													Format(TreeRow.StartDate, "DF=MM/dd/yy"),
													Format(TreeRow.EndDate, "DF=MM/dd/yy"));
			
			ConnectingStrings = New Array;
			ConnectingStrings.Add(ValuePresentation);
			ConnectingStrings.Add(ComplementingPresentation);
			ValuePresentation = StrConcat(ConnectingStrings, " ");
		EndIf;
		DecryptionArray.Add(Value, ValuePresentation);
	EndDo;
	Subinterval.Details = DecryptionArray;
	If DecryptionArray.Count() = 1 Then
		Subinterval.Text = DecryptionArray[0].Presentation;
	EndIf;
	
EndProcedure

Procedure OutputOutputTable(OutputTable, Result, Point, ReportType, SeriesStructure_)
	
	For Each OutputTableRow_ In OutputTable Do
		
		TaskLevel = Not Point.Points.Count();
		
		If ReportType <> 1 And OutputTableRow_.Type = "Plan" Then
			// displaying tasks
			Interval = Result.GetValue(Point, SeriesStructure_.Plan);
			AddChartSpacing(Interval, OutputTableRow_, "Plan", TaskLevel);
		EndIf;
		
		If ReportType > 0 And OutputTableRow_.Type <> "Plan" Then
			// displaying tasks
			Interval = Result.GetValue(Point, SeriesStructure_.Real);
			AddChartSpacing(Interval, OutputTableRow_, "Real", TaskLevel);
		EndIf;
		
	EndDo;
	
EndProcedure

Function OutputTreeToGanttChart(Result, TreeRows, SeriesStructure_, ReportType, Groups, ShowExecutionPlan, PointParent = Undefined)
	IntervalsTable = Undefined;
	
	If PointParent = Undefined Then
		PointParent = Result;
	EndIf;
	
	For Each TreeRow In TreeRows.Rows Do
		
		If TreeRow.Rows.Count() Then
			
			#Region HierarchyOutput
			
			// point design: setting text, values, images
			Point = PointParent.Points.Add();
			Point.Value = GetTreeValue(TreeRow);
			If Point.Value = Catalogs.BudgetingSteps.EmptyRef() Then
				Point.Text = NStr("vi = '<Ngoài quy trình ngân sách>';
									|ru = '<Вне бюджетного процесса>';
									|en = '<Out of budget process>'; fa = '<Out of budget process>';
									|it = '<Al di fuori del processo di budget>';
									|pl = '<Poza procesem budżetowym>';
									|tr = '<Bütçe süreci olmadan>'");
			Else
				If Groups = "Variant1" Then
					Point.Text = TreeRow.BudgetingStepDescription;
					If ValueIsFilled(TreeRow.BudgetingStep) Then
						If TreeRow.BudgetingStepIsFolder Then
							Point.Picture = PictureLib.Folder;
						Else
							Point.Picture = PictureLib.Item;
							If TreeRow.BudgetingStepExecuteAutomatically = True Then
								Point.Text = Point.Text + NStr("vi = ', <Tự động>';
																|ru = ', <Автоматически>';
																|en = ', <Automatically>'; fa = ', <Automatically>';
																|it = ', <Automaticamente>';
																|pl = ', <Automatycznie>';
																|tr = ',<Otomatik olarak>'");
							ElsIf ValueIsFilled(TreeRow.BudgetingStepEmployeeResponsible) Then
								Point.Text = Point.Text + ", " + TreeRow.BudgetingStepEmployeeResponsible;
							EndIf;
						EndIf;
					ElsIf TypeOf(Point.Value) = Type("DocumentRef.BudgetingProcess") Then
						Point.Picture = PictureLib.Document;
					EndIf;
					Point.Details = Point.Value;
				Else
					If TypeOf(Point.Value) = Type("CatalogRef.Users") Then
						Point.Text = String(Point.Value);
						Point.Picture = PictureLib.User;
						Point.Details = Point.Value;
					Else
						PeriodPresentation = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(TreeRow.Period, TreeRow.Periodicity);
						Point.Text = PeriodPresentation;
						DecodingPeriod = NStr("vi = 'Kỳ kế hoạch: %1';
												|ru = 'Период планирования: %1';
												|en = 'Planning period: %1'; fa = 'Planning period: %1';
												|it = 'Periodo di pianificazione: %1';
												|pl = 'Okres planowania: %1';
												|tr = 'Planlama dönemi: %1'");
						Point.Details = StringFunctionsClientServer.SubstituteParametersToString(DecodingPeriod, PeriodPresentation);
						If TreeRow.Periodicity <> PredefinedValue("Enum.Periodicity.Day") Then
							Point.Details 	= Point.Details + Chars.LF;
							PlanningDate 	= WorkingWithClientServerPeriods.BeginningDateOfPeriod(
															TreeRow.Period, 
															TreeRow.Periodicity);
							PlanningDate 	= Format(PlanningDate, "DLF=D");
							Point.Details 	= Point.Details + PlanningDate;
							Point.Details 	= Point.Details + " - ";
							PlanningDate 	= WorkingWithClientServerPeriods.PeriodEndDate_(
															TreeRow.Period, 
															TreeRow.Periodicity);
							PlanningDate 	= Format(PlanningDate, "DLF=D");
							Point.Details 	= Point.Details + PlanningDate;
						EndIf;
						If TreeRow.Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
							Point.Picture = PictureLib.IconPeriodDay;
						ElsIf TreeRow.Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
							Point.Picture = PictureLib.Period_Week;
						ElsIf TreeRow.Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
							Point.Picture = PictureLib.PeriodWeek;
						Else
							Point.Picture = PictureLib.TimeIntervals;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			// output of tasks
			SubordinateIntervalTable = OutputTreeToGanttChart(Result,
			                                                            TreeRow,
			                                                            SeriesStructure_,
			                                                            ReportType,
			                                                            Groups,
			                                                            ShowExecutionPlan,
			                                                            Point);
			
			// For report variants displaying the process by tasks - 
			// - we output intervals at all levels of the hierarchy.
			If Groups <> "Variant1" Then
				If IntervalsTable = Undefined Then
					IntervalsTable = SubordinateIntervalTable.Copy();
				Else
					CommonClientServer.SupplementTable(SubordinateIntervalTable, IntervalsTable);
				EndIf;
			EndIf;
			
			If SubordinateIntervalTable <> Undefined Then
				
				OutputTable = ConvertIntervalTable(SubordinateIntervalTable, ShowExecutionPlan);
				OutputOutputTable(OutputTable, Result, Point, ReportType, SeriesStructure_);
			
			EndIf;
			
			#EndRegion
			
		Else
			
			#Region TaskOutput
			
			If IntervalsTable = Undefined Then
				IntervalsTable = TaskIntervals();
			EndIf;
			FillPropertyValues(IntervalsTable.Add(), TreeRow);
			
			CurTaskTable = TaskIntervals();
			FillPropertyValues(CurTaskTable.Add(), TreeRow);
			OutputTable = ConvertIntervalTable(CurTaskTable, ShowExecutionPlan);
			
			TaskPoint = PointParent.Points.Add();
			
			If Groups = "Variant1" Then
				TaskPoint.Value = TreeRow.Period;
			Else
				TaskPoint.Value = TreeRow.BudgetingStep;
			EndIf;
			
			If Not ValueIsFilled(TaskPoint.Value) Or Groups <> "Variant1" Then
				
				TaskPoint.Text = TreeRow.BudgetingStepDescription;
				TaskPoint.Text = TaskPoint.Text;
				If Groups = "Variant2" Then
					TaskPoint.Text = TaskPoint.Text + ", " + String(TreeRow.Performer);
				EndIf;
				
			Else
				
				PeriodPresentation = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(TreeRow.Period, TreeRow.Periodicity);
				TaskPoint.Text = PeriodPresentation;
				If TreeRow.Performer <> TreeRow.Parent.BudgetingStepEmployeeResponsible Then
					TaskPoint.Text = TaskPoint.Text + ", " + String(TreeRow.Performer);
				EndIf;
				If PointParent.Text = NStr("vi = '<Ngoài quy trình ngân sách>';
											|ru = '<Вне бюджетного процесса>';
											|en = '<Out of budget process>'; fa = '<Out of budget process>';
											|it = '<Al di fuori del processo di budget>';
											|pl = '<Poza procesem budżetowym>';
											|tr = '<Bütçe süreci olmadan>'") Then
					TaskPoint.Text = TaskPoint.Text + ", " + String(TreeRow.TaskName_);
				EndIf;
				
			EndIf;
			
			TaskPoint.Details = TreeRow.BudgetingStep;
			TaskPoint.Picture = PictureLib.Task;
			
			OutputOutputTable(OutputTable, Result, TaskPoint, ReportType, SeriesStructure_);
			
			#EndRegion
			
		EndIf;
		
	EndDo;
	
	Return IntervalsTable;
	
EndFunction

#EndRegion

#Region ChartLayoutAfterOutput

Function ProcessExpandPoints(Result, Points, CollapsibleType_)
	
	ThereWerePointsWithSubordinatesOnLevel = False;
	CollapsibleType = False;
	For Each Point In Points Do
		
		Expand = ProcessExpandPoints(Result, Point.Points, CollapsibleType_);
		
		If Expand Then
			Result.ExpandPoint(Point, False);
		Else
			Result.CollapsePoint(Point, False);
		EndIf;
		
		If Point.Points.Count() Then
			ThereWerePointsWithSubordinatesOnLevel = True;
		EndIf;
		
		If TypeOf(Point.Value) = CollapsibleType_ Then
			CollapsibleType = True;
		EndIf;
		
	EndDo;
	
	Expand = ThereWerePointsWithSubordinatesOnLevel;
	Expand = Expand Or Not CollapsibleType;
	
	Return Expand;
			
EndFunction

Procedure ArrangeDiagramAfterOutput(Result, ReportType, Groups, Val BeginOfPeriod, Val EndOfPeriod)
	
	Result.IntervalRepresentation = GanttChartIntervalRepresentation.Flat;
	
	ScaleElements = Result.PlotArea.TimeScale.Items;
	
	While ScaleElements.Count() > 1 Do
		ScaleElements.Delete(ScaleElements[1]);
	EndDo;
	
	ScaleElements[0].Unit = TimeScaleUnitType.Day;
	
	If Groups = "Variant1" Then
		ProcessExpandPoints(Result, Result.Points, Type("Date"));
	Else
		ProcessExpandPoints(Result, Result.Points, Type("CatalogRef.BudgetingSteps"));
	EndIf;
	
	If Groups = "Variant1" Then
		Result.AutoDetectWholeInterval = True;
		StartOfAutoInterval = Result.BeginOfWholeInterval;
		EndOfAutoInterval = Result.EndOfWholeInterval;
		Result.AutoDetectWholeInterval = False;
		Result.SetWholeInterval(
							Min(StartOfAutoInterval, BeginOfPeriod),
							Max(EndOfAutoInterval, EndOfDay(EndOfPeriod)));
	Else
		Result.AutoDetectWholeInterval = False;
		Result.SetWholeInterval(BeginOfPeriod, EndOfDay(EndOfPeriod));
	EndIf;
	
	BeginOfPeriod = Result.BeginOfWholeInterval;
	EndOfPeriod = Result.EndOfWholeInterval;
	
	Added2 = 0; 
	AddYearToMonth = True;
	If Year(BeginOfPeriod) <> Year(EndOfPeriod) Then
		AddYearToMonth = False;
		NewScale = ScaleElements.Insert(Added2);
		NewScale.Unit = TimeScaleUnitType.Year;
		NewScale.Format = NStr("vi = 'DF=''yyyy''';
								|ru = 'ДФ=''yyyy''';
								|en = 'DF=''yyyy'''; fa = 'DF=''yyyy''';
								|it = 'DF=''yyyy''';
								|pl = 'DF=''yyyy''';
								|tr = 'DF=''yyyy'''");
		Added2 = Added2 + 1;
	EndIf;
	If BegOfQuarter(BeginOfPeriod) <> BegOfQuarter(EndOfPeriod) Then
		AddYearToMonth = False;
		NewScale = ScaleElements.Insert(Added2);
		NewScale.Unit = TimeScaleUnitType.Quarter;
		ParameterIsWrittenInCodeLanguage = "k";
		YearParameterInCodeLanguage = "yyyy";
		FormatString = NStr("vi = 'ДФ=''""quý"" %1  %2''';
							|ru = 'ДФ=''%1 ""кв."" %2''';
							|en = 'DF=''%1'' ""q"" %2'''; fa = 'DF=''%1'' ""q"" %2''';
							|it = 'DF=''%1 ""trim."" %2''';
							|pl = 'DF=''%1 ""kw."" %2''';
							|tr = 'DF=''%1 ""çy."" %2'''");
		NewScale.Format = StringFunctionsClientServer.SubstituteParametersToString(
			FormatString,
			ParameterIsWrittenInCodeLanguage,
			YearParameterInCodeLanguage);
		Added2 = Added2 + 1;
	EndIf;
	If BegOfMonth(BeginOfPeriod) <> BegOfMonth(EndOfPeriod) Then
		NewScale = ScaleElements.Insert(Added2);
		NewScale.Unit = TimeScaleUnitType.Month;
		If AddYearToMonth Then
			NewScale.Format = NStr("vi = 'ДФ=''""tháng"" MM ""năm"" yyyy''';
									|ru = 'ДФ=''MMMM yyyy''';
									|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
									|it = 'DF=''MMMM yyyy''';
									|pl = 'DF=''MMMM yyyy''';
									|tr = 'DF=''AAAA yyyy'''");
		Else
			NewScale.Format = NStr("vi = 'ДФ=''MMM''';
									|ru = 'ДФ=''MMM''';
									|en = 'DF=''MMM'''; fa = 'DF=''MMM''';
									|it = 'DF=''MMM''';
									|pl = 'DF=''MMM''';
									|tr = 'DF=''AAA'''");
		EndIf;
		Added2 = Added2 + 1;
	EndIf;
	If BegOfMonth(EndOfPeriod) <= EndOfMonth(BeginOfPeriod) + 1 Then
		// if 2 months, then add a day
		NewScale = ScaleElements.Insert(Added2);
		NewScale.Unit = TimeScaleUnitType.Day;
		NewScale.Format = NStr("vi = 'ДФ=dd';
								|ru = 'ДФ=dd';
								|en = 'DF=dd'; fa = 'DF=dd';
								|it = 'DF=dd';
								|pl = 'DF=dd';
								|tr = 'DF=gg'");
		Added2 = Added2 + 1;
	EndIf;
	
	While ScaleElements.Count() > Added2 Do
		ScaleElements.Delete(ScaleElements[Added2]);
	EndDo;
	
	If Groups = "Variant1" Then
		Title = NStr("vi = 'Giai đoạn xử lý /%Thời gian lập kế hoạch';
					|ru = 'Этап процесса / Период планирования';
					|en = 'Process stage / Planning period'; fa = 'Process stage / Planning period';
					|it = 'Этап процесса / Период планирования';
					|pl = 'Process stage / Planning period';
					|tr = 'Süreç aşaması / Planlama dönemi'");
	ElsIf Groups = "Variant2" Then
		Title = NStr("vi = 'Thời gian lập kế hoạch / Nhiệm vụ';
					|ru = 'Период планирования / Задача';
					|en = 'Planning period / Task'; fa = 'Planning period / Task';
					|it = 'Период планирования / Задача';
					|pl = 'Planning period / Task';
					|tr = 'Planlama dönemi / Görev'");
	ElsIf Groups = "Variant3" Then
		Title = NStr("vi = 'Người thực hiện / Thời gian lập kế hoạch / Nhiệm vụ';
					|ru = 'Исполнитель / Период планирования / Задача';
					|en = 'Assignee / Planning period / Task'; fa = 'Assignee / Planning period / Task';
					|it = 'Исполнитель / Период планирования / Задача';
					|pl = 'Assignee / Planning period / Task';
					|tr = 'Atanan / Planlama dönemi / Görev'");
	EndIf;
	
	Result.PlotArea.Title = StrReplace(Title, "/ ", "/" + Chars.LF);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
