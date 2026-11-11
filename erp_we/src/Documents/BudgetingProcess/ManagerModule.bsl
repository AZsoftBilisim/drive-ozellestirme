

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
	
EndProcedure

// Adds a command to create the "budget preparation Process" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow, Undefined - generated commands for output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.BudgetingProcess) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.BudgetingProcess.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.BudgetingProcess);
		CreateBasedOnCommand.WriteMode = "Post";

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Return; //In the future, the command code will be added
	
EndProcedure

Function FindRows(TreeRows, TheStructureOfTheSearch) Export
	
	For Each String In TreeRows Do
		Compatible = True;
		For Each KeyAndValue In TheStructureOfTheSearch Do
			If String[KeyAndValue.Key] <> KeyAndValue.Value Then
				Compatible = False;
				Break;
			EndIf;
		EndDo;
		
		If Compatible Then
			Return String.GetID();
		EndIf;
		
		Result = FindRows(String.GetItems(), TheStructureOfTheSearch);
		If Result <> Undefined Then
			Return Result;
		EndIf;
	EndDo;
	
EndFunction

// Fills in the issue statuses.
// 
// Parameters:
// 	DocumentObject - DocumentObject.BudgetingProcess - Document of the budget preparation process.
// 	BudgetProcessStepTree - See HierarchyOfProcessStepsByDocument
// 	
Procedure FillInTaskStatusesInTree(DocumentObject, BudgetProcessStepTree) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BudgetTask.BudgetingStep,
		|	BudgetTask.BudgetingStepBasis,
		|	BudgetTask.Executed,
		|	BudgetTask.DeletionMark,
		|	BudgetTask.Inactive_,
		|	BudgetTask.Period
		|INTO TempTable
		|FROM
		|	Task.BudgetTask AS BudgetTask
		|WHERE
		|	BudgetTask.BudgetingProcess = &BudgetingProcess
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TempTable.BudgetingStep,
		|	TempTable.BudgetingStepBasis,
		|	TempTable.Executed,
		|	TempTable.Inactive_,
		|	TempTable.Period
		|FROM
		|	TempTable AS TempTable
		|WHERE
		|	NOT TempTable.DeletionMark
		|
		|ORDER BY
		|	TempTable.BudgetingStep,
		|	TempTable.BudgetingStepBasis,
		|	TempTable.Period,
		|	TempTable.Inactive_";
	
	Query.SetParameter("BudgetingProcess", DocumentObject.Ref);
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	ProcessedRows = New Array;
	
	While SelectionDetailRecords.Next() Do
		
		TheStructureOfTheSearch = New Structure("BudgetingStep, BudgetingStepBasis, Period", 
												SelectionDetailRecords.BudgetingStep, 
												SelectionDetailRecords.BudgetingStepBasis,
												SelectionDetailRecords.Period);
		
		If TypeOf(BudgetProcessStepTree) = Type("FormDataTree") Then
			FoundRow = FindRows(BudgetProcessStepTree.GetItems(), TheStructureOfTheSearch);
			ProcessingString = BudgetProcessStepTree.FindByID(FoundRow);
		Else
			ProcessingString = BudgetProcessStepTree.Rows.FindRows(TheStructureOfTheSearch)[0];
		EndIf;
		If ProcessedRows.Find(ProcessingString) = Undefined Then
			ProcessedRows.Add(ProcessingString);
		Else
			Continue;
		EndIf;
		
		If SelectionDetailRecords.Inactive_ Then
			ProcessingString.StatusIndex_3 = 0;
		ElsIf SelectionDetailRecords.Executed Then
			ProcessingString.StatusIndex_3 = 2;
		Else
			ProcessingString.StatusIndex_3 = 1;
		EndIf;
		
	EndDo;
	
EndProcedure

Function InStageTreeAllTasksAreCompleted(BudgetProcessStepTree) Export
	
	If TypeOf(BudgetProcessStepTree) = Type("FormDataTree") Then
		TreeItems = BudgetProcessStepTree.GetItems();
		Return FindRows(TreeItems, New Structure("NotRunning, StatusIndex_3", False, 2)) <> Undefined
				And FindRows(TreeItems, New Structure("NotRunning, StatusIndex_3", False, 0)) = Undefined
				And FindRows(TreeItems, New Structure("NotRunning, StatusIndex_3", False, 1)) = Undefined
	Else
		TreeItems = BudgetProcessStepTree.Rows;
		Return TreeItems.FindRows(New Structure("NotRunning, StatusIndex_3", False, 2), True).Count()
			And TreeItems.FindRows(New Structure("NotRunning, StatusIndex_3", False, 0), True).Count() = 0
			And TreeItems.FindRows(New Structure("NotRunning, StatusIndex_3", False, 1), True).Count() = 0
	EndIf;
		
EndFunction

Function HowToFillInTreeGroupDates(NewLines, TreeRows, BeginOfPeriod, EndOfPeriod, 
										PeriodicityOfParent, CalculationSettings)
	
	For Each TreeRow In TreeRows Do
		TaskPeriod_ = BeginOfPeriod;
		While TaskPeriod_ < EndOfPeriod Do
			If TreeRow.IsFolder Then
				NewRow = NewLines.Add();
				FillPropertyValues(NewRow, TreeRow);
				NewRow.Description = TreeRow.BudgetingStepDescription;
				If Not ValueIsFilled(NewRow.Description) Then
					NewRow.Description = String(TreeRow.BudgetingStep);
				EndIf;
				NewRow.Period = TaskPeriod_;
				If TreeRow.Periodicity <> PeriodicityOfParent Then
					NewRow.PeriodPresentation = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(TaskPeriod_, TreeRow.Periodicity);
				EndIf;
				NewRow.PictureIndex = 1;
				NewRow.StatusIndex_3 = -1;
				EndOfTaskPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(TaskPeriod_, TreeRow.Periodicity);
				HowToFillInTreeGroupDates(NewRow.Rows, TreeRow.Rows, TaskPeriod_, EndOfTaskPeriod, TreeRow.Periodicity, CalculationSettings);
			Else
				NewRow = NewLines.Add();
				FillPropertyValues(NewRow, TreeRow);
				NewRow.Description = TreeRow.BudgetingStepDescription;
				NewRow.Period = TaskPeriod_;
				If Not ValueIsFilled(NewRow.Parent) Then
					NewRow.PeriodPresentation = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(TaskPeriod_, TreeRow.Periodicity);
				Else
					NewRow.PeriodPresentation = "";
				EndIf;
				
				SettingsLines = CalculationSettings.FindRows(New Structure("Period, BudgetingStep, BudgetingStepBasis", 
												NewRow.Period, NewRow.BudgetingStep, NewRow.BudgetingStepBasis));
				FillPropertyValues(NewRow, SettingsLines[0], "EmployeeResponsible, Duration, DurationType, NotRunning, ExecuteAutomatically");
				
			EndIf;
			TaskPeriod_ = WorkingWithClientServerPeriods.AddInterval(TaskPeriod_, TreeRow.Periodicity, 1);
		EndDo;
	EndDo;
	
EndFunction

Procedure CopyTreeOfRepeatableSteps(RowsDestination, StringsSources, BudgetingStep)
	
	For Each SourceRow In StringsSources Do
		
		If SourceRow.BudgetingStepBasisAction = Enums.TypesOfBudgetingStepActions.StepGroupRepetition Then
			Continue;
		EndIf;
		
		Receiver = RowsDestination.Add();
		FillPropertyValues(Receiver, SourceRow);
		Receiver.BudgetingStep = BudgetingStep;
		If SourceRow.IsFolder Then
			Receiver.BudgetingStepDescription = String(SourceRow.BudgetingStepBasis);
		Else
			Receiver.BudgetingStepDescription = SourceRow.BudgetingStepBasisDescription;
			Receiver.BudgetingStepSettingOfAction = SourceRow.BudgetingStepBasisSettingOfAction;
			Receiver.BudgetingStepAction = SourceRow.BudgetingStepBasisAction;
		EndIf;
		
		CopyTreeOfRepeatableSteps(Receiver.Rows, SourceRow.Rows, BudgetingStep);
		
	EndDo;
	
EndProcedure

Procedure DisableActivityOfBudgetProcessTasks(DocumentRef, BudgetingStep) Export
	
	StageDetails = Common.ObjectAttributesValues(BudgetingStep, "Parent, Owner, Code");
	
	Query = New Query;
	Query.SetParameter("GroupOfProcessSteps", StageDetails.Parent);
	Query.SetParameter("CodeOfCurrentStageOfProcess", StageDetails.Code);
	Query.SetParameter("BudgetingProcess", DocumentRef);
	Query.SetParameter("UseBudgetConfirmation", GetFunctionalOption("UseBudgetConfirmation", New Structure("BudgetingModel", StageDetails.Owner)));
	Query.Text =
	"SELECT
	|	BudgetTask.Ref AS Ref
	|INTO BudgetTasks
	|FROM
	|	Task.BudgetTask AS BudgetTask
	|		INNER JOIN Catalog.BudgetingSteps AS BudgetingSteps
	|		ON BudgetTask.BudgetingStep = BudgetingSteps.Ref
	|WHERE
	|	BudgetingSteps.Ref IN HIERARCHY(&GroupOfProcessSteps)
	|	AND CASE
	|			WHEN BudgetingSteps.Parent = &GroupOfProcessSteps
	|				THEN CASE
	|						WHEN BudgetingSteps.StageExecutionProcedure = VALUE(Enum.BudgetingStageExecutionProcedure.Parallel)
	|							THEN BudgetingSteps.Code = &CodeOfCurrentStageOfProcess
	|						ELSE BudgetingSteps.Code >= &CodeOfCurrentStageOfProcess
	|					END
	|			ELSE TRUE
	|		END
	|	AND BudgetTask.BudgetingProcess = &BudgetingProcess
	|	AND NOT BudgetTask.Inactive_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BudgetTasks.Ref AS BudgetTask
	|FROM
	|	BudgetTasks AS BudgetTasks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BudgetTaskDocumentsList.Document AS Document,
	|	VALUETYPE(BudgetTaskDocumentsList.Document) AS DocumentType
	|FROM
	|	BudgetTasks AS BudgetTasks
	|		INNER JOIN Task.BudgetTask.DocumentsList AS BudgetTaskDocumentsList
	|		ON BudgetTasks.Ref = BudgetTaskDocumentsList.Ref
	|WHERE
	|	BudgetTaskDocumentsList.Document.Status IN (VALUE(Enum.PlanStatuses.AwaitingConfirmation), VALUE(Enum.PlanStatuses.Upholded))
	|	AND &UseBudgetConfirmation";
	
	Result = Query.ExecuteBatch();
	BudgetTasksToBeProcessed = Result[1].Unload();
	DocumentsForProcessing_ = Result[2].Unload();
	TypesOfDocumentsToBeProcessed = DocumentsForProcessing_.Copy(, "DocumentType");
	TypesOfDocumentsToBeProcessed.GroupBy("DocumentType");
	
	TheStructureOfTheSearch = New Structure;
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Task.BudgetTask");
		LockItem.DataSource = BudgetTasksToBeProcessed;
		LockItem.UseFromDataSource("Ref", "BudgetTask");
		LockItem.Mode = DataLockMode.Exclusive;
		
		For Each StringDocumentType In TypesOfDocumentsToBeProcessed Do
			MetadataObjectName = Metadata.FindByType(StringDocumentType.DocumentType).FullName();
			LockItem = Block.Add(MetadataObjectName);
			TheStructureOfTheSearch.Insert("DocumentType", StringDocumentType.DocumentType);
			LockItem.DataSource = DocumentsForProcessing_.Copy(TheStructureOfTheSearch);
			LockItem.UseFromDataSource("Ref", "Document");
			LockItem.Mode = DataLockMode.Exclusive;
		EndDo;
		
		Block.Lock();
		
		For Each LineTask In BudgetTasksToBeProcessed Do
			TaskObject = LineTask.BudgetTask.GetObject();
			TaskObject.Inactive_ = True;
			TaskObject.ForDocumentCreation = False;
			TaskObject.AdditionalProperties.Insert("IgnoreFormationOfBudgetTasks", True);
			TaskObject.Write();
		EndDo;
		
		For Each LineDocument In DocumentsForProcessing_ Do
			DocumentObject = LineDocument.Document.GetObject();
			DocumentObject.Status = Enums.PlanStatuses.UnderPreparation;
			If DocumentObject.Posted Then
				DocumentObject.Write(DocumentWriteMode.Posting);
			Else
				DocumentObject.Write();
			EndIf;
		EndDo;
		
		JobParameters = New Array();
		JobParameters.Add(StageDetails.Owner);
		JobParameters.Add(DocumentRef);
		BackgroundJobs.Execute("BudgetingServer.BudgetTasksGeneration",JobParameters);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		MessageText = NStr("vi = 'Không thể thực hiện quay lại giai đoạn %1 do nguyên nhân:
			|%2';
			|ru = 'Не удалось выполнить возврат к этапу %1 по причине:
			|%2';
			|en = 'Cannot go back to the %1 step. Reason:
			|%2'; fa = 'Cannot go back to the %1 step. Reason:
			|%2';
			|it = 'Не удалось выполнить возврат к этапу %1 по причине:
			|%2';
			|pl = 'Cannot go back to the %1 step. Reason:
			|%2';
			|tr = '%1 iade aşamasının yürütülememe nedeni:
			|%2'");
		
		Common.MessageToUser(StrTemplate(MessageText, BudgetingStep, ErrorProcessing.DetailErrorDescription(
			ErrorInfo())));
		
	EndTry;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	HierarchySettings - ValueTable - Table unloaded from the table part of the hierarchy Settings.
// Returns:
// 	ValueTree - LongDesc:
// * BudgetingStepBasis - CatalogRef.BudgetingSteps - the preparation of the budgets.
Function HierarchyOfProcessStepsByDocument(Val HierarchySettings) Export
	
	ArrayOfSteps = HierarchySettings.UnloadColumn("BudgetingStep");
	CommonClientServer.SupplementArray(ArrayOfSteps, HierarchySettings.UnloadColumn("BudgetingStepBasis"));
	AttributesValues = Common.ObjectsAttributesValues(ArrayOfSteps, "IsFolder, Parent, DueDate, TypePeriod, StartCondition");
	
	ArrayOfSteps = New Array;
	ArrayHierarchy = New Array;
	ArrayOfRepeatableSteps = New Array;
	ArrayHierarchyRepeatable = New Array;
	
	HierarchySettings.Columns.Add("IsFolder");
	HierarchySettings.Columns.Add("DueDate");
	HierarchySettings.Columns.Add("TypePeriod");
	HierarchySettings.Columns.Add("StartCondition");
	For Each TableRow In HierarchySettings Do
		If Not ValueIsFilled(TableRow.BudgetingStepBasis) Then
			ObjectAttributesValues = AttributesValues[TableRow.BudgetingStep]; 
			TableRow.IsFolder = ObjectAttributesValues.IsFolder;
			Parent = ObjectAttributesValues.Parent;
			If ValueIsFilled(Parent) Then
				ParentDetailsValues_ = AttributesValues[Parent];
				If ParentDetailsValues_ = Undefined Then
					ParentDetailsValues_ = Common.ObjectAttributesValues(Parent, "DueDate, TypePeriod, StartCondition");	
				EndIf;
				TableRow.DueDate = ParentDetailsValues_.DueDate;
				TableRow.TypePeriod = ParentDetailsValues_.TypePeriod;
				TableRow.StartCondition = ParentDetailsValues_.StartCondition;
			EndIf;
			ArrayHierarchy.Add(TableRow);
		Else
			ObjectAttributesValues = AttributesValues[TableRow.BudgetingStepBasis];
			TableRow.IsFolder = ObjectAttributesValues.IsFolder;
			Parent = ObjectAttributesValues.Parent;
			If ValueIsFilled(Parent) Then
				ParentDetailsValues_ = AttributesValues[Parent];
				If ParentDetailsValues_ = Undefined Then
					ParentDetailsValues_ = Common.ObjectAttributesValues(Parent, "DueDate, TypePeriod, StartCondition");	
				EndIf;
				TableRow.DueDate = ParentDetailsValues_.DueDate;
				TableRow.TypePeriod = ParentDetailsValues_.TypePeriod;
				TableRow.StartCondition = ParentDetailsValues_.StartCondition;

			EndIf;
			ArrayHierarchyRepeatable.Add(TableRow);
		EndIf;
		If Not TableRow.IsFolder Then
			If Not ValueIsFilled(TableRow.BudgetingStepBasis) Then
				ArrayOfSteps.Add(TableRow);
			Else
				ArrayOfRepeatableSteps.Add(TableRow);
			EndIf;
		EndIf;
	EndDo;
	
	StepsWithoutRepeatable = HierarchySettings.Copy(ArrayOfSteps);
	HierarchyWithoutRepeatable = HierarchySettings.Copy(ArrayHierarchy);
	RepeatableSteps = HierarchySettings.Copy(ArrayOfRepeatableSteps);
	HierarchyRepeatable = HierarchySettings.Copy(ArrayHierarchyRepeatable);
	
	ExternalSet = New Structure("Steps, Hierarchy", StepsWithoutRepeatable, HierarchyWithoutRepeatable);
	
	DCS = Documents.BudgetingProcess.GetTemplate("StepTree");
	Composer = FinancialReportingServer.SchemaComposer(DCS);
	
	StepTree = FinancialReportingServer.UploadDCSResults(DCS, Composer, ExternalSet, True);
	StepTree.Rows.Sort("Code", True);
	StepTree.Columns.Add("BudgetingStepBasis", New TypeDescription("CatalogRef.BudgetingSteps"));
	
	TheStructureOfTheSearch = New Structure("BudgetingStepAction", Enums.TypesOfBudgetingStepActions.StepGroupRepetition);
	RepeatableGroups = StepTree.Rows.FindRows(TheStructureOfTheSearch, True);
	
	DCS = Documents.BudgetingProcess.GetTemplate("RepeatedStepTree");
	Composer = FinancialReportingServer.SchemaComposer(DCS);
	
	For Each StringOfRepeatableGroups In RepeatableGroups Do
		
		StringOfRepeatableGroups.IsFolder = True;
		SettingOfAction = StringOfRepeatableGroups.BudgetingStepSettingOfAction; // ValueStorage
		ValueOfActionSetting = SettingOfAction.Get();
		ActionString = ValueOfActionSetting.Find("StepGroup", "Name");
		StringOfRepeatableGroups.Periodicity = ActionString.Value.Periodicity;
		
		BudgetPreparationStage = New Structure("BudgetingStep", StringOfRepeatableGroups.BudgetingStep);
		
		ExternalSet = New Structure;
		ExternalSet.Insert("Steps", RepeatableSteps.Copy(BudgetPreparationStage));
		ExternalSet.Insert("Hierarchy", HierarchyRepeatable.Copy(BudgetPreparationStage));
		
		FinancialReportingServer.SetLayoutParameter(Composer, "RepeatableStep", StringOfRepeatableGroups.BudgetingStep);
		RepeatedStepTree = FinancialReportingServer.UploadDCSResults(DCS, Composer, ExternalSet, True);
		RepeatedStepTree.Rows.Sort("Code", True);
		CopyTreeOfRepeatableSteps(StringOfRepeatableGroups.Rows,
			RepeatedStepTree.Rows,
			StringOfRepeatableGroups.BudgetingStep);
		
	EndDo;
		
	Return StepTree;
	
EndFunction

Function TreeOfProcessStepsByDocument(DocumentObject) Export
	
	AttributesTable = DocumentObject.HierarchySettings.Unload();
	StepTree = HierarchyOfProcessStepsByDocument(AttributesTable);
	
	NewTree = New ValueTree;
	For Each Column In StepTree.Columns Do
		NewTree.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	
	NewTree.Columns.Add("EmployeeResponsible");
	NewTree.Columns.Add("Duration");
	NewTree.Columns.Add("DurationType");
	NewTree.Columns.Add("NotRunning");
	NewTree.Columns.Add("Period");
	NewTree.Columns.Add("PeriodPresentation");
	NewTree.Columns.Add("Description");
	NewTree.Columns.Add("PictureIndex", Common.TypeDescriptionNumber(1));
	NewTree.Columns.Add("StatusIndex_3", Common.TypeDescriptionNumber(1));
	NewTree.Columns.Add("ExecuteAutomatically");
	
	SettingsTable = DocumentObject.CalculationSettings.Unload(); // ValueTable -
	SettingsTable.Indexes.Add("Period, BudgetingStep");
	
	HowToFillInTreeGroupDates(NewTree.Rows, StepTree.Rows, 
			DocumentObject.BeginOfPeriod, DocumentObject.EndOfPeriod, DocumentObject.Periodicity, SettingsTable);
	
	Return NewTree;
	
EndFunction

#EndRegion

#EndIf