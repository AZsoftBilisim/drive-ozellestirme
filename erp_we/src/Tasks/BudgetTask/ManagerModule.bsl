#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure sets the duration of the passed task.
//
// Parameters:
//  Task  - TaskObject.BudgetTask - the task that we set a deadline for.
//  BudgetingStep  - CatalogRef.BudgetingSteps - step of the process on the basis of which we fill in the deadline.
//
Procedure SetTaskDuration(Task, BudgetingStep) Export
	
	If TypeOf(BudgetingStep) = Type("Structure") Then
		AttributesOfBudgetPreparationStage = BudgetingStep;
	Else
		AttributesOfBudgetPreparationStage = Common.ObjectAttributesValues(BudgetingStep,
			"Duration, DurationType");
	EndIf;
	
	StageDuration = 1;
	If ValueIsFilled(AttributesOfBudgetPreparationStage.Duration) Then
		StageDuration = AttributesOfBudgetPreparationStage.Duration;
	EndIf;
	
	TaskDate = Task.Date;
	
	If AttributesOfBudgetPreparationStage.DurationType
		= Enums.TypesOfBudgetingStepDurations.CalendarDays Then
		Task.TaskDueDate = EndOfDay(TaskDate + (StageDuration - 1) * 86400);
	Else
		Schedule = Constants.MainEnterpriseCalendar.Get();
		Task.TaskDueDate = EndOfDay(CalendarSchedules.DateByCalendar(Schedule, TaskDate, StageDuration - 1));
	EndIf;
	
EndProcedure

// Budget generates tasks based on the schedule of the budget process.
//
// Parameters:
//  BudgetingModel - CatalogRef.BudgetingModels - Optional. 
//                         The budgeting model for the formation of a budget task.
//  BudgetingProcess - DocumentRef.BudgetingProcess - Optional. 
//                              The process of preparing budgets for the upcoming fiscal problems.
//
Procedure BudgetTasksGeneration(BudgetingModel = Undefined, BudgetingProcess=Undefined) Export
	
	Query = New Query;
	Query.Text = "SELECT
	|	BudgetingModels.Ref AS Ref,
	|	BudgetingModels.Description AS Description
	|INTO models
	|FROM
	|	Catalog.BudgetingModels AS BudgetingModels
	|WHERE
	|	NOT BudgetingModels.IsFolder
	|	AND NOT BudgetingModels.DeletionMark
	|	AND BudgetingModels.Status = &ValidStatus
	|	AND &ConditionBasedOnBudgetingModelLink
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	models.Ref AS Ref,
	|	models.Description AS Description
	|FROM
	|	models AS models
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BudgetingSteps.Ref AS Ref,
	|	BudgetingSteps.Owner AS Model
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|		INNER JOIN models AS models
	|		ON BudgetingSteps.Owner = models.Ref
	|			AND (&ConditionForGroupOfProcessStages)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BudgetTask.BudgetingModel AS Model,
	|	BudgetTask.Ref AS Ref
	|FROM
	|	Task.BudgetTask AS BudgetTask
	|WHERE
	|	&ConditionForTasksBasedOnBudgetingModelLink
	|	AND &ConditionOnLinkOfBudgetProcess
	|	AND BudgetTask.MainTask_ = VALUE(Task.BudgetTask.EmptyRef)
	|	AND NOT BudgetTask.DeletionMark
	|	AND NOT BudgetTask.Inactive_";
	
	If BudgetingModel <> Undefined Then
		Query.Text = StrReplace(Query.Text, "&ConditionBasedOnBudgetingModelLink",
			"BudgetingModels.Ref = &Ref");
		Query.Text = StrReplace(Query.Text, "&ConditionForTasksBasedOnBudgetingModelLink",
			"BudgetTask.BudgetingModel = &Ref");
		Query.SetParameter("Ref", BudgetingModel);
	Else
		Query.Text = StrReplace(Query.Text, "&ConditionBasedOnBudgetingModelLink", "TRUE");
		Query.Text = StrReplace(Query.Text, "&ConditionForTasksBasedOnBudgetingModelLink", "TRUE");
	EndIf;
	
	If BudgetingProcess <> Undefined Then
		Query.Text = StrReplace(Query.Text, "&ConditionForGroupOfProcessStages",
			"BudgetingSteps.Ref IN HIERARCHY (&ProcessStep)");
		Query.Text = StrReplace(Query.Text, "&ConditionOnLinkOfBudgetProcess",
			"BudgetTask.BudgetingProcess = &BudgetProcess");
		Query.SetParameter("ProcessStep",
			Common.ObjectAttributeValue(BudgetingProcess, "StepGroup"));
		Query.SetParameter("BudgetProcess", BudgetingProcess);
	Else
		Query.Text = StrReplace(Query.Text, "&ConditionForGroupOfProcessStages", "TRUE");
		Query.Text = StrReplace(Query.Text, "&ConditionOnLinkOfBudgetProcess", "TRUE");
	EndIf; 
	
	Query.SetParameter("ValidStatus", Enums.BudgetingModelStatuses.Valid);
	
	Results = Query.ExecuteBatch();
	
	AllStages = Results[2].Unload(); // ValueTable
	AllStages.Indexes.Add("Model");
	
	AllTasks = Results[3].Unload(); // ValueTable
	AllTasks.Indexes.Add("Model");
	
	SelectionOfBudgetingModels = Results[1].Select();
	
	CreatedTasks=Undefined; // See CreateBudgetTasksBasedOnModel.CreatedTasks
	TasksCreated_ = False;
	
	While SelectionOfBudgetingModels.Next() Do
		
		BeginTransaction();
		
		Try
		
			StepsToBlock = AllStages.Copy(New Structure("Model", SelectionOfBudgetingModels.Ref), "Ref");
			TasksToBlock = AllTasks.Copy(New Structure("Model", SelectionOfBudgetingModels.Ref), "Ref");
			
			// Blocking for creating tasks without generating documents
			Block = New DataLock;
			LockItem = Block.Add("Catalog.BudgetingSteps");
			LockItem.DataSource = StepsToBlock;
			LockItem.UseFromDataSource("Ref", "Ref");
			LockItem.Mode = DataLockMode.Exclusive;
			
			LockItem = Block.Add("Task.BudgetTask");
			LockItem.DataSource = TasksToBlock;
			LockItem.UseFromDataSource("Ref", "Ref");
			LockItem.Mode = DataLockMode.Shared; // blocked tasks are not changed
			
			Block.Lock();
			
			//@skip-check query-in-loop
			CreateBudgetTasksBasedOnModel(SelectionOfBudgetingModels.Ref, BudgetingProcess, CreatedTasks);
			
			TasksCreated_ = True;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			DefaultLanguageCode = Common.DefaultLanguageCode();
			ErrorText = NStr("vi = 'Không thể tạo các nhiệm vụ ngân sách theo mô hình: %1 do: %2';
							|ru = 'Не удалось создать бюджетные задачи по модели: %1 по причине: %2';
							|en = 'Cannot create budget tasks using the %1 model. Reason: %2'; fa = 'Cannot create budget tasks using the %1 model. Reason: %2';
							|it = 'Impossibile creare gli obiettivi di budget in base al modello: %1 a causa di: %2';
							|pl = 'Nie udało się utworzyć zadania budżetowe dla modelu: %1, z powodu: %2';
							|tr = 'Bütçe görevi model %1''e göre sebeb %2''ye göre oluşturulamadı'", DefaultLanguageCode);
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorText, SelectionOfBudgetingModels.Description, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
								|ru = 'Бюджетный процесс';
								|en = 'Budget process'; fa = 'فرایند بودجه';
								|it = 'Processo di budget';
								|pl = 'Proces budżetowy';
								|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
				+ "." + NStr("vi = 'Tạo nhiệm vụ ngân sách';
							|ru = 'Создание бюджетных задач';
							|en = 'Create budget tasks'; fa = 'Create budget tasks';
							|it = 'Creazione degli obiettivi di budget';
							|pl = 'Tworzenie zadań budżetowych';
							|tr = 'Bütçe görevi oluştur'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorText);
			
		EndTry;
		
	EndDo;
	
	#Region RunningBackgroundJobsToCreateDocuments
	
	If TasksCreated_ Then
		BackgroundTasksForGeneratingDocuments = BackgroundTasksForGeneratingDocuments();
		If BackgroundTasksForGeneratingDocuments.Count() > 0 Then
			
			CreatedTasks.Indexes.Add("Process_");
			Search = New Structure("Process_");
			
			For Each BudgetingProcess In BackgroundTasksForGeneratingDocuments Do
				
				Search.Process_ = BudgetingProcess;
				
				TasksOfFirstStage = CreatedTasks.Copy(Search, "Task").UnloadColumn("Task");
				
				RunBackgroundTaskForGeneratingDocuments(BudgetingProcess, TasksOfFirstStage);
				
			EndDo; 
			
		EndIf;
	EndIf;
	
	#EndRegion
	
EndProcedure

// Generates alerts for budget issues.
//
Procedure GenerateNotificationsForBudgetTasks() Export
	
	If Not GetFunctionalOption("UseNotificationsForBudgetingTasks") Then
		Return;
	EndIf;
	
	GenerateAlertsForBudgetIssues();
	
EndProcedure

// Creates a tree of subordinate tasks by the "main task"attribute.
//
// Parameters:
//  Task - TaskRef.BudgetTask - a task for which subordinate tasks are defined.
//
// Returns:
//  ValueTree - A tree of subordinate tasks for the main task.
//
Function SubordinateTasks(Task) Export
	
	SetPrivilegedMode(True);
	
	LineUp = Reports.PerformanceOfBudgetProcessTasks.GetTemplate("MainDataCompositionSchema");
	
	Variant = LineUp.SettingVariants.Find("ConnectedTasks");
	
	ConfigurationManager = New DataCompositionSettingsComposer;
	ConfigurationManager.Initialize(New DataCompositionAvailableSettingsSource(LineUp));
	ConfigurationManager.LoadSettings(Variant.Settings);
	
	Filter = ConfigurationManager.Settings.Filter;
	NewFilter = Filter.Items.Add(Type("DataCompositionFilterItem"));
	NewFilter.LeftValue = New DataCompositionField("Task");
	NewFilter.ComparisonType = DataCompositionComparisonType.InHierarchy;
	NewFilter.Use = True;
	NewFilter.RightValue = Task;
	
	NewFilter = Filter.Items.Add(Type("DataCompositionFilterItem"));
	NewFilter.LeftValue = New DataCompositionField("Task.MainTask_");
	NewFilter.ComparisonType = DataCompositionComparisonType.Filled;
	NewFilter.Use = True;
	
	DataCompositionSettings = ConfigurationManager.GetSettings();
	TemplateComposer = New DataCompositionTemplateComposer;
	Template = TemplateComposer.Execute(LineUp, DataCompositionSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template);
	CompositionProcessor.Reset();
	
	Result = New ValueTree;
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(Result);
	OutputProcessor.Output(CompositionProcessor);
	
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// Returns a table of approved documents by process steps.
//
// Parameters:
//  Action - EnumRef.TypesOfBudgetingStepActions - action.
//  SettingOfAction - ValueTable - table of events.
//  Period - Date - duration of the issue.
//
// Returns:
//  ValueTable - Table of documents by process step:
//		* Document - DocumentRef - link to the document.
//      * BudgetingStep - CatalogRef.BudgetingSteps - Link to the budget preparation stage.
//    
Function ApprovedDocumentsForProcessStep(Action, SettingOfAction, Period) Export
	
	Result = New ValueTable;
	Result.Columns.Add("Document");
	Result.Columns.Add("BudgetingStep");
	
	If Action <> Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets
		And Action <> Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover Then
		Return Result;
	EndIf;
	
	If SettingOfAction <> Undefined Then
		
		TheStructureOfTheSearch = New Structure("Name", "ApprovedStagesOfBudgetPreparation");
		FoundRows = SettingOfAction.FindRows(TheStructureOfTheSearch);
		
		If FoundRows.Count() Then
			ApprovedProcessSteps = FoundRows[0].Value;
			Query = New Query;
			Query.Text =
			"SELECT DISTINCT
				|	BudgetTaskDocumentsList.Document AS Document,
				|	BudgetTask.BudgetingStep AS BudgetingStep
				|FROM
				|	Task.BudgetTask AS BudgetTask
				|		LEFT JOIN Task.BudgetTask.DocumentsList AS BudgetTaskDocumentsList
				|		ON BudgetTaskDocumentsList.Ref = BudgetTask.Ref
				|WHERE
				|	BudgetTask.BudgetingStep IN(&ApprovedProcessSteps)
				|	AND BudgetTask.Period = &Period
				|	AND NOT BudgetTask.DeletionMark
				|	AND NOT BudgetTask.Inactive_
				|	AND BudgetTask.Executed
				|	AND NOT BudgetTaskDocumentsList.Document IS NULL ";
			Query.SetParameter("ApprovedProcessSteps", ApprovedProcessSteps);
			Query.SetParameter("Period", Period);
			Result = Query.Execute().Unload();
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns an indication of the presence of a similar task with the Inactive = True attribute.
// This is necessary, in particular, in order not to create new documents, but to use previously created ones.
//
// Parameters:
//  Task - TaskRef.BudgetTask - auditable budget task
//
// Returns:
//  Boolean - True if a similar inactive task is found
Function ThereIsInactiveSimilarTask(Task) Export
	
	Query = New Query;
	Query.SetParameter("Task", Task);
	Query.Text = 
	"SELECT TOP 1
	|	BudgetTask.Ref AS Ref
	|FROM
	|	Task.BudgetTask AS BudgetTask
	|		INNER JOIN Task.BudgetTask AS BudgetTask_Inactive
	|		ON BudgetTask.BudgetingStep = BudgetTask_Inactive.BudgetingStep
	|			AND BudgetTask.BudgetingStepBasis = BudgetTask_Inactive.BudgetingStepBasis
	|			AND BudgetTask.BudgetingProcess = BudgetTask_Inactive.BudgetingProcess
	|			AND BudgetTask.Period = BudgetTask_Inactive.Period
	|			AND BudgetTask.Ref <> BudgetTask_Inactive.Ref
	|WHERE
	|	BudgetTask.Ref = &Task
	|	AND BudgetTask_Inactive.Inactive_
	|	AND NOT BudgetTask_Inactive.DeletionMark";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Checks whether a new document needs to be created.
// 
// Parameters:
//  Document - DocumentRef - The current document from the documents list of budget tasks, or "Undefined".
//  Action - EnumRef.TypesOfBudgetingStepActions - Type of action for the budget preparation stage.
//  Add_To_List - Boolean - Indicates whether the list of documents is used in the Budget task.
//
// Returns:
//  Boolean - True if you need to create a new document,
//           False - If there is no need to create a new document.
//
Function YouNeedToCreateNewDocument(Document, Action, Add_To_List) Export
	
	Result = False;
	
	ActionsWithoutCreatingDocument = New Array;
	ActionsWithoutCreatingDocument.Add(Enums.TypesOfBudgetingStepActions.Other);
	ActionsWithoutCreatingDocument.Add(Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets);
	ActionsWithoutCreatingDocument.Add(Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover);
	
	If Not ValueIsFilled(Document) And ActionsWithoutCreatingDocument.Find(Action) = Undefined 
		Or Add_To_List Then
		Result = True;
	EndIf;
	
	Return Result;
	
EndFunction

// Creates a "budget Instance" document in accordance with the action structure.
//
// Parameters:
//  NewDocumentParameters - Structure - Parameters for filling in the document object,
//                                         The Period Of Modellbezeichnung, Etapatelecom.
// 	ActionStructure        - Structure - settings the document is created.
// 	Post - Boolean - Optional. Indicates whether the "budget Instance" document is being held.
//  DonTCheckExistingDocuments - Boolean - Optional. Indicates whether the document was created without searching for existing documents.
// 
// Returns:
//  Array of DocumentRef.BudgetEntryForm -
//
Function CreateBudgetEntryDocument(NewDocumentParameters, ActionStructure, Post = False, DonTCheckExistingDocuments = False) Export
	
	DocumentPeriod_ = NewDocumentParameters.Period;
	If Not ValueIsFilled(DocumentPeriod_) Then
		DocumentPeriod_ = CurrentSessionDate();
	EndIf;
	
	Attributes = New Structure("Periodicity, ExecuteAutomatically", "Parent.Periodicity");
	Attributes = Common.ObjectAttributesValues(NewDocumentParameters.BudgetingStep, Attributes);
	Periodicity = Attributes.Periodicity;
	ExecuteAutomatically = Attributes.ExecuteAutomatically;
	EmployeeResponsible = Common.ObjectAttributeValue(NewDocumentParameters.BudgetingStep,"EmployeeResponsible");
	
	If ActionStructure.Property("BeginOfPeriod") Then
		BeginOfPeriod = ActionStructure.BeginOfPeriod;
	Else
		BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(DocumentPeriod_, Periodicity);
	EndIf;
	
	If ActionStructure.Property("PeriodEnding") Then
		EndOfPeriod = ActionStructure.PeriodEnding;
	Else
		EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(DocumentPeriod_, Periodicity);
	EndIf;
	
	BudgetProfile = Undefined;
	If ActionStructure.Property("BudgetProfile") Then
		BudgetProfile = ActionStructure.BudgetProfile;
	EndIf;
	If BudgetProfile = Undefined Then
		Common.MessageToUser(
			NStr("vi = 'Trong cài đặt hành động, dạng ngân sách để tạo chứng từ không được xác định.';
				|ru = 'В настройках действия не определен вид бюджета для создания документа.';
				|en = 'Budget profile for document creation is not determined in the action settings.'; fa = 'Budget profile for document creation is not determined in the action settings.';
				|it = 'Nelle impostazioni dell''azione non è stata definita la tipologia di budget per creare un documento.';
				|pl = 'W ustawieniach działania typ budżetu do tworzenia dokumentu nie jest zdefiniowany.';
				|tr = 'Eylem ayarlarında belgenin oluşturulması için bütçe profili belirtilmemiş.'"));
		Return Undefined;
	EndIf;
	If Not Catalogs.BudgetProfiles.BudgetViewIsFilledInCorrectly(BudgetProfile) Then
		Return Undefined
	EndIf;
		
	ActionStructure.Insert("BeginOfPeriod",			BeginOfPeriod);
	ActionStructure.Insert("PeriodEnding",		EndOfPeriod);
	ActionStructure.Insert("BudgetingModel",	NewDocumentParameters.BudgetingModel);
	ActionStructure.Insert("BudgetProfile",			BudgetProfile);
	
	ArrayDocuments = Undefined;
	If Not DonTCheckExistingDocuments Then
		ArrayDocuments = FindDocumentByPaddingValues("BudgetEntryForm", ActionStructure);
	EndIf;
	
	FillingInNewDocument = False;
	ObjectsArray = New Array;
	If ArrayDocuments = Undefined Then
		BudgetEntryForm = Documents.BudgetEntryForm.CreateDocument();
		BudgetEntryForm.Fill(ActionStructure);
		BudgetEntryForm.Date = CurrentSessionDate();
		BudgetEntryForm.EmployeeResponsible = EmployeeResponsible;
		ObjectsArray.Add(BudgetEntryForm);
		FillingInNewDocument = Not (ActionStructure.Action
			= Enums.TypesOfBudgetEntryFormActions.AdjustByBudgetFlowItems);
	Else
		For Each Document In ArrayDocuments Do
			BudgetEntryForm = Document.GetObject();
			ObjectsArray.Add(BudgetEntryForm);
		EndDo;
	EndIf;
	
	If Post Then
		Post = (ActionStructure.Action = Enums.TypesOfBudgetEntryFormActions.EnterBudgetEntryForm);
	EndIf;
	
	ArrayDocuments = New Array;
	For Each BudgetEntryForm In ObjectsArray Do
		
		// The document is filled in only at the automatic stage or a new document
		If FillingInNewDocument Or ExecuteAutomatically Then
			Documents.BudgetEntryForm.FillInBudgetAccordingToInformationBase(BudgetEntryForm);
			Documents.BudgetEntryForm.RecalculateRelatedBudgetInstanceCells(BudgetEntryForm);
		EndIf;
		If ExecuteAutomatically Then
			UseBudgetConfirmation = Common.ObjectAttributeValue(
				NewDocumentParameters.BudgetingModel, "UseBudgetConfirmation");
			If UseBudgetConfirmation
				And BudgetEntryForm.Status <> Enums.PlanStatuses.Upholded Then
				BudgetEntryForm.Status = Enums.PlanStatuses.AwaitingConfirmation;
			EndIf;
		EndIf;
		
		If NewDocumentParameters.Property("BudgetTask") Then
			BudgetEntryForm.AdditionalProperties.Insert("BudgetTask", NewDocumentParameters.BudgetTask);
		EndIf;
		
		If Post Then
			Try
				BudgetEntryForm.Write(DocumentWriteMode.Posting);
			Except
				ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Không thể kết chuyển chứng từ: ( %1)';
										|ru = 'Не удалось провести документ: (%1)';
										|en = 'Cannot post the document: (%1)'; fa = 'Cannot post the document: (%1)';
										|it = 'Impossibile registrare il documento: (%1)';
										|pl = 'Nie udało się zaksięgować dokument: (%1)';
										|tr = 'Belge kaydedilemedi: (%1)'"), BudgetEntryForm.Ref);
				WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
									|ru = 'Бюджетный процесс';
									|en = 'Budget process'; fa = 'فرایند بودجه';
									|it = 'Processo di budget';
									|pl = 'Proces budżetowy';
									|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
					+ "." + NStr("vi = 'Tạo chứng từ cho nhiệm vụ';
								|ru = 'Создание документов для задачи';
								|en = 'Creating documents for the task'; fa = 'Creating documents for the task';
								|it = 'Creazione dei documenti per il compito';
								|pl = 'Tworzenie dokumentów dla zadania';
								|tr = 'Görevler için belge oluşturma'", Common.DefaultLanguageCode()),
					EventLogLevel.Error, Metadata.Subsystems.BudgetingAndPlanning,,ErrorMessage);
			EndTry;
		Else
			Try
				BudgetEntryForm.Write();
			Except
				ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Không thể ghi chứng từ: ( %1)';
										|ru = 'Не удалось записать документ: (%1)';
										|en = 'Cannot save document: (%1)'; fa = 'Cannot save document: (%1)';
										|it = 'Non è stato possibile salvare il documento: (%1)';
										|pl = 'Nie udało się zapisać dokumentu: (%1)';
										|tr = 'Belge kaydedilemedi: (%1)'"), BudgetEntryForm.Ref);
				WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
									|ru = 'Бюджетный процесс';
									|en = 'Budget process'; fa = 'فرایند بودجه';
									|it = 'Processo di budget';
									|pl = 'Proces budżetowy';
									|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
					+ "." + NStr("vi = 'Tạo chứng từ cho nhiệm vụ';
								|ru = 'Создание документов для задачи';
								|en = 'Creating documents for the task'; fa = 'Creating documents for the task';
								|it = 'Creazione dei documenti per il compito';
								|pl = 'Tworzenie dokumentów dla zadania';
								|tr = 'Görevler için belge oluşturma'", Common.DefaultLanguageCode()),
					EventLogLevel.Error, Metadata.Subsystems.BudgetingAndPlanning,,ErrorMessage);
			EndTry;
		EndIf;
		
		DetailsOfBudgetType = Common.ObjectAttributesValues(BudgetEntryForm.BudgetProfile, 
										"SaveBudgetInTabularFormToBudgetEntryForm, HeaderDimensions, DataVersion");
		If DetailsOfBudgetType.SaveBudgetInTabularFormToBudgetEntryForm Then
			
			ArrayAnalytics = DetailsOfBudgetType.HeaderDimensions.Unload().UnloadColumn("DimensionKind");
			ListOfAnalysts = New ValueList;
			ListOfAnalysts.LoadValues(ArrayAnalytics);
			
			GenerationMode = Enums.ModesOfBudgetReportGeneration.Document;
			BudgetProfileDisplayParameters = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(BudgetEntryForm.BudgetProfile, GenerationMode);
			
			ScenarioCurrency = Common.ObjectAttributeValue(BudgetEntryForm.Scenario, "Currency");
			ReportParameters = Documents.BudgetEntryForm.ParametersForDisplayingBudgetViewInTableDocument(BudgetEntryForm, ListOfAnalysts, ScenarioCurrency, 
																			BudgetProfileDisplayParameters, GenerationMode);
			
			BudgetInstanceData = BudgetReportingDisplayServer.BudgetInstanceData(ReportParameters);
			
			AuxiliaryData = New Structure;
			AuxiliaryData.Insert("CellData_", 						BudgetInstanceData.CellData_);
			AuxiliaryData.Insert("DetailsData", 				BudgetInstanceData.DetailsData);
			AuxiliaryData.Insert("TreeOfEditListRows", 	BudgetInstanceData.TreeOfEditListRows);
			AuxiliaryData.Insert("BudgetViewVersion", 				DetailsOfBudgetType.DataVersion);
			AuxiliaryData.Insert("BudgetProfile", 						BudgetEntryForm.BudgetProfile);
			AuxiliaryData.Insert("LevelStyle", 						BudgetInstanceData.LevelStyle);
			
			BudgetingServer.SaveStoredTemplate(BudgetInstanceData.Result, AuxiliaryData, BudgetEntryForm.Ref);
			
		EndIf;
	
		ArrayDocuments.Add(BudgetEntryForm.Ref);
		
	EndDo;
	
	Return ArrayDocuments;
	
EndFunction

// Creates a document "Registrar of budget turnover" in accordance with the action settings.
//
// Parameters:
//  NewDocumentParameters - Structure - Parameters for filling in the document object,
//                                         The Period Of Etapatelecom.
// 	ActionStructure        - Structure - settings the document is created.
//  DonTCheckExistingDocuments - Boolean - Optional. Indicates whether the document was created without searching for existing documents.
//
// Returns:
//  DocumentRef.RegistrarOfBudgetTurnover - Link to the created document.
//
Function CreateBudgetTurnoverLogger(NewDocumentParameters, ActionStructure,
	DonTCheckExistingDocuments = False) Export
	
	DocumentPeriod_ = NewDocumentParameters.Period;
	If Not ValueIsFilled(DocumentPeriod_) Then
		DocumentPeriod_ = CurrentSessionDate();
	EndIf;
	
	Attributes = New Structure("Periodicity, ExecuteAutomatically", "Parent.Periodicity");
	Attributes = Common.ObjectAttributesValues(NewDocumentParameters.BudgetingStep, Attributes);
	Periodicity = Attributes.Periodicity;
	ExecuteAutomatically = Attributes.ExecuteAutomatically;
	EmployeeResponsible = Common.ObjectAttributeValue(NewDocumentParameters.BudgetingStep,"EmployeeResponsible");
	
	If ActionStructure.Property("PlanningPeriod") Then
		PlanningPeriod = ActionStructure.PlanningPeriod;
	Else
		PlanningPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(DocumentPeriod_, Periodicity);
	EndIf;
	
	If ActionStructure.Property("Periodicity") Then
		Periodicity = ActionStructure.Periodicity;
	EndIf;
	
	CalculationRule = Undefined;
	If ActionStructure.Property("CalculationRule") Then
		CalculationRule = ActionStructure.CalculationRule;
	EndIf;
	If CalculationRule = Undefined Then
		Common.MessageToUser(
			NStr("vi = 'Trong thiết lập hiệu lực, chưa xác định quy tắc tính toán để tạo chứng từ.';
				|ru = 'В настройках действия не определено правило расчета для создания документа.';
				|en = 'Calculation rule for document creation is not determined in the action settings.'; fa = 'Calculation rule for document creation is not determined in the action settings.';
				|it = 'Calculation rule for document creation is not determined in the action settings.';
				|pl = 'Calculation rule for document creation is not determined in the action settings.';
				|tr = 'Eylem ayarlarında belgenin oluşturulması için hesaplama kuralı belirtilmemiş.'"));
		Return Undefined;
	EndIf;
		
	ActionStructure.Insert("PlanningPeriod", PlanningPeriod);
	ActionStructure.Insert("Periodicity", Periodicity);
	ActionStructure.Insert("CalculationRule", CalculationRule);
	
	ArrayDocuments = Undefined;
	If Not DonTCheckExistingDocuments Then
		ArrayDocuments = FindDocumentByPaddingValues("RegistrarOfBudgetTurnover", ActionStructure);
	EndIf;
	
	ObjectsArray = New Array;
	If ArrayDocuments = Undefined Then
		RegistrarOfBudgetTurnover = Documents.RegistrarOfBudgetTurnover.CreateDocument();
		RegistrarOfBudgetTurnover.Fill(ActionStructure);
		RegistrarOfBudgetTurnover.Date = CurrentSessionDate();
		RegistrarOfBudgetTurnover.EmployeeResponsible = EmployeeResponsible;
		ObjectsArray.Add(RegistrarOfBudgetTurnover);
	Else
		For Each Document In ArrayDocuments Do
			RegistrarOfBudgetTurnover = Document.GetObject();
			ObjectsArray.Add(RegistrarOfBudgetTurnover);
		EndDo;
	EndIf;
	
	ArrayDocuments = New Array;
	For Each RegistrarOfBudgetTurnover In ObjectsArray Do
		
		If ExecuteAutomatically Then
			UseBudgetConfirmation = Common.ObjectAttributeValue(
				NewDocumentParameters.BudgetingModel, "UseBudgetConfirmation");
			If UseBudgetConfirmation
				And RegistrarOfBudgetTurnover.Status <> Enums.PlanStatuses.Upholded Then
				RegistrarOfBudgetTurnover.Status = Enums.PlanStatuses.AwaitingConfirmation;
			EndIf;
		EndIf;
		
		If NewDocumentParameters.Property("BudgetTask") Then
			RegistrarOfBudgetTurnover.AdditionalProperties.Insert("BudgetTask", NewDocumentParameters.BudgetTask);
		EndIf;
		
		Try
			RegistrarOfBudgetTurnover.Write(DocumentWriteMode.Posting);
		Except
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Không thể kết chuyển chứng từ: ( %1)';
									|ru = 'Не удалось провести документ: (%1)';
									|en = 'Cannot post the document: (%1)'; fa = 'Cannot post the document: (%1)';
									|it = 'Impossibile registrare il documento: (%1)';
									|pl = 'Nie udało się zaksięgować dokument: (%1)';
									|tr = 'Belge kaydedilemedi: (%1)'"), RegistrarOfBudgetTurnover.Ref);
			WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
								|ru = 'Бюджетный процесс';
								|en = 'Budget process'; fa = 'فرایند بودجه';
								|it = 'Processo di budget';
								|pl = 'Proces budżetowy';
								|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
				+ "." + NStr("vi = 'Tạo chứng từ cho nhiệm vụ';
							|ru = 'Создание документов для задачи';
							|en = 'Creating documents for the task'; fa = 'Creating documents for the task';
							|it = 'Creazione dei documenti per il compito';
							|pl = 'Tworzenie dokumentów dla zadania';
							|tr = 'Görevler için belge oluşturma'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, Metadata.Subsystems.BudgetingAndPlanning,,ErrorMessage);
		EndTry;
		
		ArrayDocuments.Add(RegistrarOfBudgetTurnover.Ref);
		
	EndDo;
	
	Return ArrayDocuments;
	
EndFunction

// Creates a plan entry document by type according to the action settings.
//
// Parameters:
//  NewDocumentParameters - Structure - Parameters for filling in the document object:
//  	* Key - Name of the parameter of the new document.
//		* Value - The value of the new document parameter.
// 	SettingOfAction - ValueTable - document creation settings:
//		* Name - Name of the action setting.
//      * Value - The value of the action setting.
//
// Returns:
//  DocumentRef - Link to the plan document.
//     
Function CreatePlan(NewDocumentParameters, SettingOfAction) Export
	
	DocumentPeriod_ = NewDocumentParameters.Period;
	If Not ValueIsFilled(DocumentPeriod_) Then
		DocumentPeriod_ = CurrentSessionDate();
	EndIf;
	
	FillingValues = New Structure();
	For Each Setting In SettingOfAction Do
		If ValueIsFilled(Setting.Value) Then
			FillingValues.Insert(Setting.Name, Setting.Value);
		EndIf;
	EndDo; 
	
	PlanType = Undefined;
	Scenario = Undefined;
	PlanProfile = Undefined;
	If Not FillingValues.Property("PlanType", PlanType) Or Not ValueIsFilled(PlanType) Then
		Raise NStr("vi = 'Trong cài đặt hành động, Dạng kế hoạch không được xác định.';
					|ru = 'В настройках действия не определен Тип плана.';
					|en = 'Plan type is not determined in the action settings.'; fa = 'Plan type is not determined in the action settings.';
					|it = 'Nelle impostazioni dell''azione non è definito il Tipo di piano.';
					|pl = 'W ustawieniach działania nie zdefiniowano Typu planu.';
					|tr = 'Eylem ayarlarında Plan türü belirtilmemiş.'");
	ElsIf Not FillingValues.Property("Scenario", Scenario) Or Not ValueIsFilled(Scenario) Then
		Raise NStr("vi = 'Trong tùy chỉnh hành động, không xác định Kịch bản.';
					|ru = 'В настройках действия не определен Сценарий планирования.';
					|en = 'Planning scenario is not determined in the action settings.'; fa = 'Planning scenario is not determined in the action settings.';
					|it = 'Nelle impostazioni dell''azione non è definita lo Scenario di pianificazione.';
					|pl = 'W ustawieniach działania nie zdefiniowano Scenariusza planowania.';
					|tr = 'Eylem ayarlarında Planlama senaryosu belirtilmemiş.'");
	ElsIf Not FillingValues.Property("PlanProfile", PlanProfile) Or Not ValueIsFilled(PlanProfile) Then
		Raise NStr("vi = 'Trong cài đặt hành động, chưa xác định Dạng kế hoạch.';
					|ru = 'В настройках действия не определен Вид плана.';
					|en = 'Plan profile is not determined in the action settings.'; fa = 'Plan profile is not determined in the action settings.';
					|it = 'Nelle impostazioni dell''azione non è definita la Tipologia di piano.';
					|pl = 'W ustawieniach działania nie zdefiniowano Rodzaju planu.';
					|tr = 'Eylem ayarlarında Plan profili belirtilmemiş.'");
	EndIf;
	
	Periodicity = Common.ObjectAttributeValue(Scenario, "Periodicity");
	BudgetingScenario = Common.ObjectAttributeValue(Scenario, "BudgetingScenario");
	BeginOfPeriod = TMCommonUseClientServer.CalculateStartDateOfNearestPeriod(DocumentPeriod_, Periodicity);
	PeriodEnding = TMCommonUseClientServer.CalculatePeriodEndDate(BeginOfPeriod, Periodicity, 1);
	FillingValues.Insert("BudgetingScenario", BudgetingScenario);
	FillingValues.Insert("Periodicity", Periodicity);
	FillingValues.Insert("BeginOfPeriod", BeginOfPeriod);
	FillingValues.Insert("PeriodEnding", PeriodEnding);
	
	Plan = Documents[Common.EnumerationValueName(PlanType)].CreateDocument();
	Plan.Fill(FillingValues);
	Plan.Date = CurrentSessionDate();
	Plan.Write();
	
	Return Plan.Ref;
	
EndFunction

// Creates a document "Setting up the initial set of calculation indicators" in accordance with the structure of the action.
//
// Parameters:
//  NewDocumentParameters - Structure - Parameters for filling in the document object:
//   *Period - Date - Document date
//   *BudgetingModel - CatalogRef.BudgetingModels
//   *BudgetingStep - CatalogRef.BudgetingSteps
// 	ActionStructure        - Structure - settings the document is created.
// 	Post - Boolean - Optional. A sign of the document "Setting the initial Balances of calculated indicators".
//  DonTCheckExistingDocuments - Boolean - Optional. Indicates whether the document was created without searching for existing documents.
// 
// Returns:
//  Array of DocumentRef.SettingOfEstimatesOpeningBalance -
//
Function CreateInstallationOfOpeningBalancesOfCalculatedIndicators(NewDocumentParameters, ActionStructure,
	Post = False, DonTCheckExistingDocuments = False) Export
	
	DocumentPeriod_ = NewDocumentParameters.Period;
	If Not ValueIsFilled(DocumentPeriod_) Then
		DocumentPeriod_ = CurrentSessionDate();
	EndIf;
	
	Attributes = New Structure("Periodicity, ExecuteAutomatically", "Parent.Periodicity");
	Attributes = Common.ObjectAttributesValues(NewDocumentParameters.BudgetingStep, Attributes);
	Periodicity = Attributes.Periodicity;
	ExecuteAutomatically = Attributes.ExecuteAutomatically;
	EmployeeResponsible = Common.ObjectAttributeValue(NewDocumentParameters.BudgetingStep,"EmployeeResponsible");
	
	If ActionStructure.Property("DateOfRemainingGoods") Then
		DateOfRemainingGoods = ActionStructure.DateOfRemainingGoods;
	Else
		DateOfRemainingGoods = WorkingWithClientServerPeriods.BeginningDateOfPeriod(DocumentPeriod_, Periodicity);
	EndIf;
	
	BudgetBalanceItem = Undefined;
	If Not ActionStructure.Property("BudgetBalanceItem", BudgetBalanceItem) Then
		Common.MessageToUser(
			NStr("vi = 'Trong tùy chỉnh hiệu lực, chưa chỉ định chỉ tiêu tính toán để nhập số dư.';
				|ru = 'В настройках действия не указан расчетный показатель для ввода остатков.';
				|en = 'The estimate for entering balances is not specified in the action settings.'; fa = 'The estimate for entering balances is not specified in the action settings.';
				|it = 'The estimate for entering balances is not specified in the action settings.';
				|pl = 'The estimate for entering balances is not specified in the action settings.';
				|tr = 'İşlem ayarlarında bakiye girişi için hesaplanan gösterge belirtilmemiş.'"));
		Return Undefined;
	EndIf;
	
	ActionStructure.Insert("DateOfRemainingGoods", DateOfRemainingGoods);
	
	ArrayDocuments = Undefined;
	If Not DonTCheckExistingDocuments Then
		ArrayDocuments = FindDocumentByPaddingValues("SettingOfEstimatesOpeningBalance",
			ActionStructure);
	EndIf;
	
	ObjectsArray = New Array;
	If ArrayDocuments = Undefined Then
		SettingOfEstimatesOpeningBalance = Documents.SettingOfEstimatesOpeningBalance.CreateDocument();
		SettingOfEstimatesOpeningBalance.Fill(ActionStructure);
		SettingOfEstimatesOpeningBalance.Date = CurrentSessionDate();
		SettingOfEstimatesOpeningBalance.EmployeeResponsible = EmployeeResponsible;
		ObjectsArray.Add(SettingOfEstimatesOpeningBalance);
	Else
		For Each Document In ArrayDocuments Do
			SettingOfEstimatesOpeningBalance = Document.GetObject();
			ObjectsArray.Add(SettingOfEstimatesOpeningBalance);
		EndDo;
	EndIf;
	
	ArrayDocuments = New Array;
	For Each SettingOfEstimatesOpeningBalance In ObjectsArray Do
		
		If NewDocumentParameters.Property("BudgetTask") Then
			SettingOfEstimatesOpeningBalance.AdditionalProperties.Insert("BudgetTask", NewDocumentParameters.BudgetTask);
		EndIf;
		
		If Post Then
			
			Try
				SettingOfEstimatesOpeningBalance.Write(DocumentWriteMode.Posting);
			Except
				ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Không thể kết chuyển chứng từ: ( %1)';
										|ru = 'Не удалось провести документ: (%1)';
										|en = 'Cannot post the document: (%1)'; fa = 'Cannot post the document: (%1)';
										|it = 'Impossibile registrare il documento: (%1)';
										|pl = 'Nie udało się zaksięgować dokument: (%1)';
										|tr = 'Belge kaydedilemedi: (%1)'"), SettingOfEstimatesOpeningBalance.Ref);
				WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
									|ru = 'Бюджетный процесс';
									|en = 'Budget process'; fa = 'فرایند بودجه';
									|it = 'Processo di budget';
									|pl = 'Proces budżetowy';
									|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
					+ "." + NStr("vi = 'Tạo chứng từ cho nhiệm vụ';
								|ru = 'Создание документов для задачи';
								|en = 'Create documents for the task'; fa = 'Create documents for the task';
								|it = 'Creazione dei documenti per il compito';
								|pl = 'Tworzenie dokumentów dla zadania';
								|tr = 'Görevler için belge oluşturma'", Common.DefaultLanguageCode()),
					EventLogLevel.Error, Metadata.Subsystems.BudgetingAndPlanning,,ErrorMessage);
			EndTry;
		
		Else
			
			Try
				SettingOfEstimatesOpeningBalance.Write();
			Except
				ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Không thể ghi chứng từ: ( %1)';
										|ru = 'Не удалось записать документ: (%1)';
										|en = 'Cannot save the document: (%1)'; fa = 'Cannot save the document: (%1)';
										|it = 'Non è stato possibile salvare il documento: (%1)';
										|pl = 'Nie udało się zapisać dokumentu: (%1)';
										|tr = 'Belge kaydedilemedi: (%1)'"), SettingOfEstimatesOpeningBalance.Ref);
				WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
									|ru = 'Бюджетный процесс';
									|en = 'Budget process'; fa = 'فرایند بودجه';
									|it = 'Processo di budget';
									|pl = 'Proces budżetowy';
									|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
					+ "." + NStr("vi = 'Tạo chứng từ cho nhiệm vụ';
								|ru = 'Создание документов для задачи';
								|en = 'Create documents for the task'; fa = 'Create documents for the task';
								|it = 'Creazione dei documenti per il compito';
								|pl = 'Tworzenie dokumentów dla zadania';
								|tr = 'Görevler için belge oluşturma'", Common.DefaultLanguageCode()),
					EventLogLevel.Error, Metadata.Subsystems.BudgetingAndPlanning,,ErrorMessage);
			EndTry;
		
		EndIf;
		
		ArrayDocuments.Add(SettingOfEstimatesOpeningBalance.Ref);
		
	EndDo;
	
	Return ArrayDocuments;
	
EndFunction

// Creates the document "Setting values for non-financial indicators" in accordance with the action settings.
//
// Parameters:
//  NewDocumentParameters - Structure - Parameters for filling in the document object,
//                                         The Period Of Etapatelecom.
// 	SettingOfAction - ValueTable - settings the document is created.
//  Post - Boolean - Optional. Indicates whether the document "Setting values for non-financial indicators"is being executed. 
//
// Returns:
//  DocumentRef.SetValuesForNonFinancialItems - Link to the created document.
//           
Function CreateSettingForNonFinancialIndicators(NewDocumentParameters, SettingOfAction, Post = False) Export
	
	FillingValues = New Structure;
	For Each Setting In SettingOfAction Do
		If ValueIsFilled(Setting.Value) Then
			FillingValues.Insert(Setting.Name, Setting.Value);
		EndIf;
	EndDo;
	
	DocumentPeriod_ = NewDocumentParameters.Period;
	If Not ValueIsFilled(DocumentPeriod_) Then
		DocumentPeriod_ = CurrentSessionDate();
	EndIf;

	Attributes = New Structure("Periodicity, ExecuteAutomatically", "Parent.Periodicity");
	Attributes = Common.ObjectAttributesValues(NewDocumentParameters.BudgetingStep, Attributes);
	Periodicity = Attributes.Periodicity;
	ExecuteAutomatically = Attributes.ExecuteAutomatically;

	BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(DocumentPeriod_, Periodicity);
	FillingValues.Insert("BeginOfPeriod", BeginOfPeriod);
	
	If FillingValues.Property("InputTemplate") Then
		NFPDEFINITIONTable = Common.ObjectAttributeValue(FillingValues.InputTemplate, "TemplateIndicators");
		NFPDefinitions = NFPDEFINITIONTable.Unload()[0].Factor;
	ElsIf FillingValues.Property("NonFinancialItem") Then
		NFPDefinitions = FillingValues.NonFinancialItem;
	Else
		Common.MessageToUser(
			NStr("vi = 'Trong cài đặt hành động, chưa xác định chỉ báo phi tài chính để tạo chứng từ.';
				|ru = 'В настройках действия не определен нефинансовый показатель для создания документа.';
				|en = 'Non-financial item for document creation is not determined in the action settings.'; fa = 'Non-financial item for document creation is not determined in the action settings.';
				|it = 'Nelle impostazioni dell''azione non è stato definito l''indice non finanziario per creare un documento.';
				|pl = 'W ustawieniach działania nie zdefiniowano wskaźnika pozafinansowego do tworzenia dokumentu.';
				|tr = 'Eylem ayarlarında belgenin oluşturulması için finansal olmayan öğe belirtilmemiş.'"));
		Return Undefined;
	EndIf;
	
	NeedEndPeriod = Common.ObjectAttributeValue(NFPDefinitions, "SetAValueForEachPeriod");
	If NeedEndPeriod Then
		PeriodEnding = WorkingWithClientServerPeriods.PeriodEndDate_(DocumentPeriod_, Periodicity);
		FillingValues.Insert("PeriodEnding", PeriodEnding);
	EndIf;
	
	DocumentsArray = FindDocumentByPaddingValues("SetValuesForNonFinancialItems", FillingValues);
	If DocumentsArray = Undefined Then
		SettingNonFinancialIndicators = Documents.SetValuesForNonFinancialItems.CreateDocument();
		SettingNonFinancialIndicators.Fill(FillingValues);
		SettingNonFinancialIndicators.Date = CurrentSessionDate();
	Else
		SettingNonFinancialIndicators = DocumentsArray[DocumentsArray.UBound()].GetObject();
	EndIf;
	
	// The document is filled in only at the automatic stage or a new document
	If DocumentsArray = Undefined Or ExecuteAutomatically Then
		ObjectAndCalculationParameters = Documents.SetValuesForNonFinancialItems.ObjectAndParametersOfCalculationAndSettingValuesOfNonFinancialIndicators(SettingNonFinancialIndicators);
		If ObjectAndCalculationParameters.InputDescriptionStructure.Property("FillingRules") Then
			Documents.SetValuesForNonFinancialItems.FillInConfiguredDocument(ObjectAndCalculationParameters, True);
			Documents.SetValuesForNonFinancialItems.SaveTabularPartToDocument(ObjectAndCalculationParameters, SettingNonFinancialIndicators);
		EndIf;
	EndIf;
	
	SettingNonFinancialIndicators.Write();
	
	If Post Then
		SettingNonFinancialIndicators.Write(DocumentWriteMode.Posting);
	EndIf;
	
	Return SettingNonFinancialIndicators.Ref;
	
EndFunction

// Creates an action Structure according to the action string.
//
// Parameters:
//  ActionString - ValueTreeRow - line of the "budget entry tree".
// 	ActionColumns - ValueTreeColumnCollection - columns of the "budget entry Tree".
//
// Returns:
//  Structure - Structure of action:
//		* Key - Name of the action setting.
//		* Value - The value of the action setting.
//
Function ActionStringParameters(ActionString, ActionColumns) Export
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	ActionStructure = New Structure;
	
	ExcludeColumns = New Array();
	ExcludeColumns.Add("TypeOfBudgetAnalytics");
	ExcludeColumns.Add("BudgetFrequency");
	ExcludeColumns.Add("Document");
	ExcludeColumns.Add("Comment");
	ExcludeColumns.Add("DocumentPresentation");
	ExcludeColumns.Add("DocumentDate");
	ExcludeColumns.Add("DocumentNumber");
	ExcludeColumns.Add("BudgetTypeLineNumber");
	ExcludeColumns.Add("AvailabilityCompany");
	ExcludeColumns.Add("AvailabilityDepartment");
	ExcludeColumns.Add("AvailabilityScenario");
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		ExcludeColumns.Add("AvailabilityOfAnalytics_" + Cnt);
	EndDo;
	If Not ValueIsFilled(ActionString.CalculationRule) Then
		ExcludeColumns.Add("CalculationRule");
		ExcludeColumns.Add("Periodicity");
	EndIf;
	If Not ValueIsFilled(ActionString.BudgetBalanceItem) Then
		ExcludeColumns.Add("BudgetBalanceItem");
	EndIf;
	If ValueIsFilled(ActionString.CalculationRule) Or ValueIsFilled(ActionString.BudgetBalanceItem) Then
		ExcludeColumns.Add("BudgetProfile");
		ExcludeColumns.Add("Action");
		If ValueIsFilled(ActionString.BudgetBalanceItem) Then
			ExcludeColumns.Add("Organization");
			ExcludeColumns.Add("Department");
			ExcludeColumns.Add("EndOfPeriod");
		EndIf;
		For Cnt = 1 To MaximumNumberOfAnalysts Do
			ExcludeColumns.Add("Dimension" + Cnt);
		EndDo;
	EndIf;
		
	For Each Column In ActionColumns Do
		
		If Column.Name = "EndOfPeriod" Then
			If Not ValueIsFilled(ActionString.CalculationRule) And Not ValueIsFilled(
				ActionString.BudgetBalanceItem) Then
				ActionStructure.Insert("PeriodEnding", ActionString[Column.Name]);
			EndIf;
		ElsIf ExcludeColumns.Find(Column.Name) = Undefined Then
			If Column.Name = "BeginOfPeriod" And ValueIsFilled(ActionString.CalculationRule) Then
				ActionStructure.Insert("PlanningPeriod", ActionString[Column.Name]);
			ElsIf Column.Name = "BeginOfPeriod" And ValueIsFilled(ActionString.BudgetBalanceItem) Then
				ActionStructure.Insert("DateOfRemainingGoods", ActionString[Column.Name]);
			Else
				ActionStructure.Insert(Column.Name, ActionString[Column.Name]);
			EndIf;
		EndIf;
	EndDo;
	
	If ValueIsFilled(ActionString.CalculationRule) Then
		ActionStructure.Insert("DocumentBasis", Documents.BudgetEntryForm.EmptyRef());
		If Not ActionStructure.Property("Periodicity") Then
			ActionStructure.Insert("Periodicity", ActionString.BudgetFrequency);
		EndIf;
	EndIf;
	
	Return ActionStructure;

EndFunction

// Creates documents "Instance of the budget" or "Register of budget turnarounds" in accordance with the action settings,
// and places the result in the repository for background execution.
//
// Parameters:
//  Parameters - Structure - New year document parametres-structure of values for filling in the document object,
//                          The Period Of Modellbezeichnung, Etapatelecom.
//                          Budget tree-value Tree - a tree of document creation settings.
// 	StorageAddress - String - Address of the storage for saving the result.
//
Procedure GenerateBudgetsBasedOnBackgroundActionSettings(Parameters, StorageAddress) Export
	
	NewDocumentParameters = Parameters.NewDocumentParameters;
	BudgetEntryTree = Parameters.BudgetEntryTree;
	DonTCheckExistingDocuments = False;
	If Parameters.Property("DonTCheckExistingDocuments") Then
		DonTCheckExistingDocuments = Parameters.DonTCheckExistingDocuments;
	EndIf;
	
	Task = NewDocumentParameters.BudgetTask;
	TaskPresentation = String(Task);
	TaskDetails__ = Common.ObjectAttributesValues(Task, "BudgetingModel, Period, BudgetingStep, BudgetingStepBasis");
	BudgetingSteps = New Array;
	BudgetingSteps.Add(TaskDetails__.BudgetingStep);
	If ValueIsFilled(TaskDetails__.BudgetingStepBasis) Then
		BudgetingSteps.Add(TaskDetails__.BudgetingStepBasis);
	EndIf;
	
	ErrorText = "";
	
	BeginTransaction();
	Try
		
		TasksForTransactionalLocking = TasksToBlockWhenEnteringDocuments(TaskDetails__.BudgetingModel, TaskDetails__.Period, BudgetingSteps);
		Block = New DataLock;
		LockItem = Block.Add("Task.BudgetTask");
		LockItem.DataSource = TasksForTransactionalLocking;
		LockItem.UseFromDataSource("Ref", "Ref");
		Block.Lock();
		
		SharedArrayOfDocuments = Tasks.BudgetTask.GenerateBudgetsBasedOnActionSettings(NewDocumentParameters,
		BudgetEntryTree, True, DonTCheckExistingDocuments);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		DefaultLanguageCode = Common.DefaultLanguageCode();
		ErrorText = NStr("vi = 'Không thể tạo chứng từ cho nhiệm vụ ngân sách: %1%, do: %2%';
						|ru = 'Не удалось создать документы по бюджетной задаче: %1%, по причине: %2%';
						|en = 'Cannot create documents for the %1% budget task. Reason: %2%'; fa = 'Cannot create documents for the %1% budget task. Reason: %2%';
						|it = 'Non è stato possibile creare i documenti per l''obiettivo di budget: %1% a causa di: %2%';
						|pl = 'Nie udało się utworzyć dokumentów dla zadania budżetowego: %1%, z powodu: %2%';
						|tr = '%1 bütçe görevine göre %2 sebebine göre belgeler oluşturulamadı'", DefaultLanguageCode);
		ErrorText = StrReplace(ErrorText, "%1%", TaskPresentation);
		ErrorText = StrReplace(ErrorText, "%2%", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(NStr("vi = 'Tạo chứng từ tương tác cho các nhiệm vụ ngân sách';
							|ru = 'Интерактивное создание документов для бюджетных задач';
							|en = 'Interactive document creation for budget tasks'; fa = 'Interactive document creation for budget tasks';
							|it = 'Creazione interattiva dei documenti per obiettivi di budget';
							|pl = 'Interaktywne tworzenie dokumentów dla zadań budżetowych';
							|tr = 'Bütçe görevleri için manuel belge oluşturma'", DefaultLanguageCode),
		EventLogLevel.Error,Metadata.Tasks.BudgetTask,Task, ErrorText);
		
	EndTry;
		
	Result = New Structure;
	Result.Insert("Documents", SharedArrayOfDocuments);
	Result.Insert("HasErrors", ValueIsFilled(ErrorText));
	Result.Insert("ErrorText", ErrorText);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	Object - TaskObject.BudgetTask - Object of the budget task.
//  SettingOfAction - ValueTable - Table of action settings.
//  Write - Boolean - Optional. The sign that the task needs to be recorded is saved.
//  DonTCheckExistingDocuments - Boolean - Optional. If the action is "Enter budget", it
//                                     indicates whether to check existing documents or not.
//  ErrorText - String - Returned parameter. if an error occurs when creating documents, the error text will be set to this parameter.
// Returns:
// 	Structure, Undefined - LongDesc:
// * FormName - String -
// * Uniqueness - Boolean -
// * FormParameters - Structure -:
// ** NFP_FillDefaultValues - Boolean - default fill parameter for a non-financial indicator
// ** Key - DocumentRef.BudgetEntryForm, DocumentRef.SetValuesForNonFinancialItems -
// ** Key - DocumentRef.SalesPlan, DocumentRef.PurchasePlan -
// ** Key - DocumentRef.ProductionPlan, DocumentRef.AssemblyDisassemblyPlan -
//
Function ExecuteAction(Object, SettingOfAction, Write = False, DonTCheckExistingDocuments = False, ErrorText = "") Export
	
	Action = Object.Action;
	Document = CurrentDocument(Object.DocumentsList);
	
	ListVisibility = False;
	SettingsString = SettingOfAction.Find("BudgetProfile","Name");
	If SettingsString <> Undefined Then
		BudgetProfile = SettingsString.Value;
		ListVisibility = Catalogs.BudgetProfiles.BudgetViewContainsAnalyticsCaps(BudgetProfile);
	EndIf;
	
	If Tasks.BudgetTask.YouNeedToCreateNewDocument(Document, Action, ListVisibility) Then
		
		If DonTCheckExistingDocuments Then
			DonTCheckExistingDocuments = Not Tasks.BudgetTask.ThereIsInactiveSimilarTask(Object.Ref);
		EndIf;
		
		BeginTransaction();
		Try
		
			// We impose a lock to exclude the possibility of parallel creation of documents with a background task.
			BudgetingSteps = New Array;
			BudgetingSteps.Add(Object.BudgetingStep);
			If ValueIsFilled(Object.BudgetingStepBasis) Then
				BudgetingSteps.Add(Object.BudgetingStepBasis);
			EndIf;
			TasksForTransactionalLocking = TasksToBlockWhenEnteringDocuments(Object.BudgetingModel,
			                                                                          Object.Period,
			                                                                          BudgetingSteps);
			Block = New DataLock;
			LockItem = Block.Add("Task.BudgetTask");
			LockItem.DataSource = TasksForTransactionalLocking;
			LockItem.UseFromDataSource("Ref", "Ref");
			Block.Lock();
			
			If Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm
				Or Action = Enums.TypesOfBudgetingStepActions.AdjustCorrectBudgets
				Or Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
				Or Action = Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
				NewDocumentParameters = New Structure("Period, BudgetingModel, BudgetingStep");
				FillPropertyValues(NewDocumentParameters, Object);
				NewDocumentParameters.Insert("BudgetTask", Object.Ref);
				If ValueIsFilled(Object.BudgetingStepBasis) Then
					NewDocumentParameters.BudgetingStep = Object.BudgetingStepBasis;
				EndIf;
				Document = GenerateBudgetsBasedOnActionSettings(NewDocumentParameters, SettingOfAction, , DonTCheckExistingDocuments);
				
			ElsIf Action = Enums.TypesOfBudgetingStepActions.PlanEntry Then
				NewDocumentParameters = New Structure("Period");
				FillPropertyValues(NewDocumentParameters, Object);
				Document = Tasks.BudgetTask.CreatePlan(NewDocumentParameters, SettingOfAction);
				
			ElsIf Action = Enums.TypesOfBudgetingStepActions.SetValuesForNonFinancialItems Then
				NewDocumentParameters = New Structure("Period, BudgetingStep");
				FillPropertyValues(NewDocumentParameters, Object);
				If ValueIsFilled(Object.BudgetingStepBasis) Then
					NewDocumentParameters.BudgetingStep = Object.BudgetingStepBasis;
				EndIf;
				Document = Tasks.BudgetTask.CreateSettingForNonFinancialIndicators(NewDocumentParameters, SettingOfAction);
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			DefaultLanguageCode = Common.DefaultLanguageCode();
			ErrorText = NStr("vi = 'Không thể tạo chứng từ cho nhiệm vụ ngân sách: %1 do: %2';
							|ru = 'Не удалось создать документы по бюджетной задаче: %1 по причине: %2';
							|en = 'Cannot create documents for the %1 budget task. Reason: %2'; fa = 'Cannot create documents for the %1 budget task. Reason: %2';
							|it = 'Non è stato possibile creare i documenti per l''obiettivo di budget: %1 a causa di: %2';
							|pl = 'Nie udało się utworzyć dokumentów dla zadania budżetowego: %1, z powodu: %2';
							|tr = '%1 bütçe görevine göre %2 sebebine göre belgeler oluşturulamadı'", DefaultLanguageCode);
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorText, Object.Ref, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(NStr("vi = 'Tạo chứng từ tương tác cho các nhiệm vụ ngân sách';
								|ru = 'Интерактивное создание документов для бюджетных задач';
								|en = 'Interactive document creation for budget tasks'; fa = 'Interactive document creation for budget tasks';
								|it = 'Creazione interattiva dei documenti per obiettivi di budget';
								|pl = 'Interaktywne tworzenie dokumentów dla zadań budżetowych';
								|tr = 'Bütçe görevleri için manuel belge oluşturma'", DefaultLanguageCode),
				EventLogLevel.Error,Metadata.Tasks.BudgetTask, Object.Ref, ErrorText);
			
		EndTry;
		
		If Not ValueIsFilled(Document) Then
			Return Undefined;
		EndIf;
		
		Write = True;
		
		If TypeOf(Document) = Type("Array") Then
			CommonClientServer.SupplementTableFromArray(Object.DocumentsList, Document, "Document");
		Else
			Object.DocumentsList.Add().Document = Document;
		EndIf;
		
	EndIf;
	
	ObjectFormName = "";
	FormParameters = New Structure();
	Uniqueness = False;
	
	Document = CurrentDocument(Object.DocumentsList);
	ObjectFormName = "Document." + Document.Metadata().Name + ".ObjectForm";
	FormParameters.Insert("Key", Document);
	If Not ValueIsFilled(Document) Then
		FormParameters.Insert("NFP_FillDefaultValues", True);
	EndIf;
	
	Result = New Structure();
	Result.Insert("FormName", ObjectFormName);
	Result.Insert("FormParameters", FormParameters);
	Result.Insert("Uniqueness", Uniqueness);
	
	Return Result;
	
EndFunction

// Searches for documents in the search fields.
// 
// Parameters:
//  TableName - String - Name of the document type from the metadata.
//  FillingValues - Structure - Contains the values of the document fields to search for.
//
// Returns:
//   - Undefined - The document was not found.
//   - Array of DocumentRef.BudgetEntryForm, DocumentRef.SetValuesForNonFinancialItems -
//      documents found by parameters.
//
Function FindDocumentByPaddingValues(TableName, FillingValues) Export
	
	Query = New Query();
	SourceTable2 = "Document." + TableName;
	QueryText = "SELECT Ref FROM &SourceTable2 WHERE NOT DeletionMark";
	QueryText = StrReplace(QueryText, "&SourceTable2", SourceTable2);
	For Each KeysAndValue In FillingValues Do
		Value = KeysAndValue.Value;
		If KeysAndValue.Key = "PeriodEnding" Then
			Value = BegOfDay(Value);
		EndIf;
		Query.Parameters.Insert(KeysAndValue.Key, Value);
		QueryText = QueryText + " " + "And" + " " + KeysAndValue.Key + " = &" + KeysAndValue.Key;
	EndDo;
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	Result = New Array;
	While Selection.Next() Do
		Result.Add(Selection.Ref);
	EndDo;
	
	If Result.Count() Then
		Return Result;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Checks that the task will be displayed as a list.
// 
// Parameters:
//  Task - TaskObject.BudgetTask, TaskRef.BudgetTask - A budget task that is being checked.
//  ActionSettingsTable - ValueTable - Contains a table with action settings.
//                          - String - The address of the storage with the settings of actions on the server.
//
// Returns:
//  Boolean - True if the document is displayed as a list.
//           False if the document is not displayed as a list.
//
Function BudgetTaskList(Task, Val ActionSettingsTable=Undefined) Export
	
	ListVisibility = False;
	
	If Task.DocumentsList.Count() > 1 Then
		ListVisibility = True;
		Return ListVisibility;
	EndIf;
	
	If ActionSettingsTable = Undefined Then
		ActionSettingsTable	= Task.SettingOfAction.Get();
	ElsIf TypeOf(ActionSettingsTable) = Type("String") Then
		ActionSettingsTable	= GetFromTempStorage(ActionSettingsTable);
	EndIf;
	
	ThisIsInputOfBalancesOfCalculatedIndicators = (Task.Action
		= Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance);
	If ThisIsInputOfBalancesOfCalculatedIndicators Then
		Setting = ActionSettingsTable.Find("BalancesOfCalculatedIndicators","Name");
	Else
		Setting = ActionSettingsTable.Find("BudgetProfiles","Name");
	EndIf;
	If Setting <> Undefined And Setting.Value.Count() > 0 Then
		BudgetProfiles = Setting.Value;
	Else
		BudgetProfiles = Undefined;
		Return ListVisibility;
	EndIf;
	Setting = ActionSettingsTable.Find("BudgetPopulationDimension", "Name");
	If Setting <> Undefined Then
		DimensionOfBudgets = Setting.Value;
		If ThisIsInputOfBalancesOfCalculatedIndicators Then
			CollapseAnalyticsOfBudgetFilling(DimensionOfBudgets);
		EndIf;
	Else
		DimensionOfBudgets = Undefined;
	EndIf;
	
	BudgetStageGroup = Common.ObjectAttributeValue(Task.BudgetingStep, "Parent");
	PeriodicityOfBudgetStage = Common.ObjectAttributeValue(BudgetStageGroup, "Periodicity");
	If ThisIsInputOfBalancesOfCalculatedIndicators Then
		BudgetFrequency = PeriodicityOfBudgetStage;
	ElsIf ValueIsFilled(BudgetProfiles[0].BudgetProfile) Then
		BudgetFrequency = Common.ObjectAttributeValue(BudgetProfiles[0].BudgetProfile, "Periodicity");
	Else
		BudgetFrequency = BudgetProfiles[0].Periodicity;
	EndIf;
	If BudgetProfiles <> Undefined Then
		If BudgetProfiles.Count() > 1 Or (DimensionOfBudgets <> Undefined And DimensionOfBudgets.Count() > 1)
		 Or (BudgetProfiles.Count() = 1
		   And Enums.Periodicity.IndexOf(BudgetFrequency) < Enums.Periodicity.IndexOf(PeriodicityOfBudgetStage)) Then
			ListVisibility = True;
		EndIf;
	EndIf;
	
	Return ListVisibility;

EndFunction

// Checks if there is a budget task for the document
//
// Parameters:
//  Document - Document object.Instance of the budget, document object.Budget Turnover Registratorreferences
//  Cancel - Boolean
//
Procedure CheckAvailabilityOfBudgetTaskForDocument(Document, Cancel) Export
	
	If Document.AdditionalProperties.Property("BudgetTask")
		And ValueIsFilled(Document.AdditionalProperties.BudgetTask) Then
		Return;
	EndIf;
	
	UseBudgetProcess = GetFunctionalOption("UseBudgetProcess");

	If UseBudgetProcess And Not Users.RolesAvailable("EditingBudgetingDataOutsideProcesses")
		And Not Users.IsFullUser(, , True) Then
		
		If Not ValueIsFilled(Document.Ref) Then
			ErrorText = NStr("vi = 'Tạo chứng từ chỉ có thể từ nhiệm vụ ngân sách.';
							|ru = 'Создание документа возможно только из бюджетной задачи.';
							|en = 'Document can be created only from the budget task.'; fa = 'Document can be created only from the budget task.';
							|it = 'È possibile creare un documento solo dal task del budget.';
							|pl = 'Utworzenie dokumentu jest możliwe tylko z zadania budżetowego.';
							|tr = 'Sadece bütçe görevinden belge oluşturulabilir.'");
			Common.MessageToUser(ErrorText, Document, , , Cancel);
		Else	
			Query = New Query;
			Query.Text = "SELECT
			|	BudgetTaskDocumentsList.Ref AS Ref
			|FROM
			|	Task.BudgetTask.DocumentsList AS BudgetTaskDocumentsList
			|WHERE
			|	BudgetTaskDocumentsList.Document = &Document
			|	AND NOT BudgetTaskDocumentsList.Ref.Executed
			|	AND NOT BudgetTaskDocumentsList.Ref.DeletionMark
			|	AND BudgetTaskDocumentsList.Ref.Performer = &Performer
			|
			|UNION ALL
			|
			|SELECT
			|	BudgetTaskApprovedDocuments.Ref
			|FROM
			|	Task.BudgetTask.ApprovedDocuments AS BudgetTaskApprovedDocuments
			|WHERE
			|	BudgetTaskApprovedDocuments.Document = &Document
			|	AND NOT BudgetTaskApprovedDocuments.Ref.Executed
			|	AND NOT BudgetTaskApprovedDocuments.Ref.DeletionMark
			|	AND BudgetTaskApprovedDocuments.Ref.Performer = &Performer";
			
			Query.SetParameter("Document", Document.Ref);
			Query.SetParameter("Performer", Users.CurrentUser());
			
			If Query.Execute().IsEmpty() Then
				ErrorText = NStr("vi = 'Thay đổi bị cấm vì Không có nhiệm vụ ngân sách hoạt động.';
								|ru = 'Изменения запрещены, т.к. нет активной бюджетной задачи.';
								|en = 'Changes are prohibited as there is no active budget task.'; fa = 'Changes are prohibited as there is no active budget task.';
								|it = 'La modifica è vietata perché non esiste un task di budget attivo.';
								|pl = 'Zmiany są zakazane, ponieważ brak aktywnego zadania budżetowego.';
								|tr = 'Değişiklikler yasak, çünkü bütçe görevi aktif değil.'");
				Common.MessageToUser(ErrorText, Document, , , Cancel);
			EndIf;
		EndIf;
	EndIf;

EndProcedure

// Returns the name of the budget document as a metadata object based on the type of action of the budget task
//
// Parameters:
//  Action - EnumRef.TypesOfBudgetingStepActions
//
// Returns:
//  String - name of the budget document
//
Function NameOfBudgetDocumentForIssue(Action) Export
	
	If Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules Then
		DocumentName = "RegistrarOfBudgetTurnover";
	ElsIf Action = Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
		DocumentName = "SettingOfEstimatesOpeningBalance";
	Else
		DocumentName = "BudgetEntryForm";
	EndIf;
	
	Return DocumentName;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Author)
	|	OR ValueAllowed(Performer)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region ToDoList

// LongDesc
// 
// Parameters:
// 	ToDoList - ValueTable - defines the case parameters:
//    * Id  - String - internal case ID used by the subsystem.
//    * HasToDoItems       - Boolean - if True, the case is displayed in the user's to-do list.
//    * Important         - Boolean - if True, the case will be highlighted in red.
//    * HideInSettings - Boolean - if True, the case will be hidden in the current Affairs settings form.
//                            You can use it for cases that do not require multiple
//                            use, i.e. after they are completed, they
//                            will no longer be displayed for this information base.
//    * Presentation  - String - view of the case that is displayed to the user.
//    * Count     - Number  - quantitative indicator of the case, displayed in the title bar of the case.
//    * Form          - String - full path to the form to open when you click on the to-do hyperlink
//                                in the Current Affairs panel.
//    * FormParameters - Structure - parameters to open the metric form with.
//    * Owner       - String, MetadataObjectSubsystem - string ID of the case that will be the owner for the current
//                       or metadata object subsystem.
//    * ToolTip      - String - hint text.
Procedure OnFillToDoList(ToDoList) Export
	
	Enabled = (Users.IsFullUser()
			Or AccessRight("Edit", Metadata.Tasks.BudgetTask));
		
	If Not Enabled Then
		Return;
	EndIf;
	
	DataCompositionSchema = New DataCompositionSchema;
	DataSource = DataCompositionSchema.DataSources.Add(); 
	DataSource.Name                = "DataSource";
	DataSource.DataSourceType = "Local";
	
	QueryText = "SELECT
		|	ISNULL(SUM(1), 0) AS TaskCount
		|{SELECT
		|	TaskCount}
		|FROM
		|	Task.BudgetTask AS BudgetTask
		|{WHERE
		|	BudgetTask.DeletionMark,
		|	BudgetTask.Executed,
		|	BudgetTask.Inactive_,
		|	BudgetTask.Performer.*,
		|	BudgetTask.TaskDueDate}";
		
	DataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.AutoFillAvailableFields = False;
	DataSet.Query			= QueryText;
	DataSet.Name				= "DataSet";
	DataSet.DataSource	= "DataSource";
	
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, New UUID);
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema));
		
	SelectedField = SettingsComposer.Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field = New DataCompositionField("TaskCount");
	
	CompositionGroup1 = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
	CompositionGroup1.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	
	SettingsByArtist = GetLayoutSettingsForTasksByArtist();
	
	LayoutSettingsExpired = GetLayoutSettingsForExpiredTasks();
	DataCompositionClientServer.CopyElements(LayoutSettingsExpired.Filter,
														SettingsByArtist.Filter, False);
	
	LayoutSettingsForToday = GetLayoutSettingsForTasksForToday();
	DataCompositionClientServer.CopyElements(LayoutSettingsForToday.Filter,
														SettingsByArtist.Filter, False);
	
	LayoutSettingsForWeek = GetLayoutSettingsForTasksForWeek();
	DataCompositionClientServer.CopyElements(LayoutSettingsForWeek.Filter,
														SettingsByArtist.Filter, False);
	
	LayoutSettingsForNextWeek = GetLayoutSettingsForNextWeekSTasks();
	DataCompositionClientServer.CopyElements(LayoutSettingsForNextWeek.Filter,
														SettingsByArtist.Filter, False);
	
	SelectionOfIndicators_ = New Structure();
	SelectionOfIndicators_.Insert("QuantityOverdue",LayoutSettingsExpired.Filter);
	SelectionOfIndicators_.Insert("QuantityForToday",LayoutSettingsForToday.Filter);
	SelectionOfIndicators_.Insert("QuantityPerWeek",LayoutSettingsForWeek.Filter);
	SelectionOfIndicators_.Insert("QuantityForNextWeek",LayoutSettingsForNextWeek.Filter);
	
	NumericalIndicators = New Structure;
	For Each StructureItem In SelectionOfIndicators_ Do
		
		DataCompositionClientServer.CopyElements(SettingsComposer.Settings.Filter,
															StructureItem.Value);
		
		TemplateComposer = New DataCompositionTemplateComposer;
		CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.Settings,,,
													Type("DataCompositionValueCollectionTemplateGenerator"));
		
		CompositionProcessor = New DataCompositionProcessor;
		CompositionProcessor.Initialize(CompositionTemplate,,,);
		
		LayoutResult = New ValueTable;
		OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
		OutputProcessor.SetObject(LayoutResult);
		
		OutputProcessor.Output(CompositionProcessor);
		
		NumericalIndicators.Insert(StructureItem.Key, LayoutResult[0].TaskCount);
		
	EndDo;
	
	HasToDoItems = NumericalIndicators.QuantityOverdue > 0 
		Or NumericalIndicators.QuantityForToday > 0 
			Or NumericalIndicators.QuantityPerWeek > 0 
				Or NumericalIndicators.QuantityForNextWeek > 0;
		
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "BudgetTasks";
	UserTaskParent.Presentation  = NStr("vi = 'Nhiệm vụ ngân sách';
										|ru = 'Бюджетные задачи';
										|en = 'Budget tasks'; fa = 'وظایف بودجه';
										|it = 'Obiettivi di budget';
										|pl = 'Zadania budżetowe';
										|tr = 'Bütçe görevleri'");
	UserTaskParent.HasToDoItems       = HasToDoItems;
	UserTaskParent.Owner       = Metadata.Subsystems.BudgetingAndPlanning;
	
	FormName = "Task.BudgetTask.Form.MyTasksListForm";
		
	ToDoItem = ToDoList.Add();
	UserTaskPresentation = NStr("vi = 'Nhiệm vụ quá hạn';
								|ru = 'Просроченные задачи';
								|en = 'Overdue tasks'; fa = 'وظایف سررسیدگذشته';
								|it = 'Obiettivi scaduti';
								|pl = 'Zadania przeterminowane';
								|tr = 'Vadesi geçmiş görevler'");
	TitleOfListForm = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Nhiệm vụ ngân sách của tôi (%1)';
			|ru = 'Мои бюджетные задачи (%1)';
			|en = 'My budget tasks (%1)'; fa = 'My budget tasks (%1)';
			|it = 'I miei obiettivi di budget (%1)';
			|pl = 'Moje zadania budżetowe (%1)';
			|tr = 'Bütçe görevlerim (%1)'"), UserTaskPresentation);
	ToDoItem.Id  = "BudgetProcessOverdueTasks";
	ToDoItem.HasToDoItems       = NumericalIndicators.QuantityOverdue > 0;
	ToDoItem.Presentation  = UserTaskPresentation;
	ToDoItem.Count     = NumericalIndicators.QuantityOverdue;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;	
	AddlParameters = New Structure("Title", TitleOfListForm);
	ToDoItem.FormParameters = New Structure("FixedSettings, AddlParameters, PurposeUseKey",
										LayoutSettingsExpired, AddlParameters, "Overdue");
										
	ToDoItem.Owner       = "BudgetTasks";
	
	ToDoItem = ToDoList.Add();
	UserTaskPresentation = NStr("vi = 'Hôm nay';
								|ru = 'На сегодня';
								|en = 'As of today'; fa = 'As of today';
								|it = 'Ad oggi';
								|pl = 'Na dzisiaj';
								|tr = 'Bugün itibarıyla'");
	TitleOfListForm = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Nhiệm vụ ngân sách của tôi (%1)';
			|ru = 'Мои бюджетные задачи (%1)';
			|en = 'My budget tasks (%1)'; fa = 'My budget tasks (%1)';
			|it = 'I miei obiettivi di budget (%1)';
			|pl = 'Moje zadania budżetowe (%1)';
			|tr = 'Bütçe görevlerim (%1)'"), UserTaskPresentation);
	ToDoItem.Id  = "BudgetProcessTasksForToday";
	ToDoItem.HasToDoItems       = NumericalIndicators.QuantityForToday > 0;
	ToDoItem.Presentation  = UserTaskPresentation;
	ToDoItem.Count     = NumericalIndicators.QuantityForToday;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	AddlParameters = New Structure("Title", TitleOfListForm);
	ToDoItem.FormParameters = New Structure("FixedSettings, AddlParameters, PurposeUseKey",
							LayoutSettingsForToday, AddlParameters, "ForToday");
	ToDoItem.Owner       = "BudgetTasks";	
	
	ToDoItem = ToDoList.Add();
	UserTaskPresentation = NStr("vi = 'Trong một tuần';
								|ru = 'На неделю';
								|en = 'For a week'; fa = 'For a week';
								|it = 'Per settimana';
								|pl = 'Na tydzień';
								|tr = 'Bu hafta itibarıyla'");
	TitleOfListForm = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Nhiệm vụ ngân sách của tôi (%1)';
			|ru = 'Мои бюджетные задачи (%1)';
			|en = 'My budget tasks (%1)'; fa = 'My budget tasks (%1)';
			|it = 'I miei obiettivi di budget (%1)';
			|pl = 'Moje zadania budżetowe (%1)';
			|tr = 'Bütçe görevlerim (%1)'"), UserTaskPresentation);
	ToDoItem.Id  = "BudgetProcessTasksForWeek";
	ToDoItem.HasToDoItems       = NumericalIndicators.QuantityPerWeek > 0;
	ToDoItem.Presentation  = UserTaskPresentation;
	ToDoItem.Count     = NumericalIndicators.QuantityPerWeek;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	AddlParameters = New Structure("Title", TitleOfListForm);
	ToDoItem.FormParameters = New Structure("FixedSettings, AddlParameters, PurposeUseKey",
							LayoutSettingsForWeek, AddlParameters, "ForWeek");
	ToDoItem.Owner       = "BudgetTasks";
	
	ToDoItem = ToDoList.Add();
	UserTaskPresentation = NStr("vi = 'Tuần tới';
								|ru = 'На следующую неделю';
								|en = 'For the next week'; fa = 'For the next week';
								|it = 'Per la prossima settimana';
								|pl = 'W przyszłym tygodniu';
								|tr = 'Sonraki hafta itibarıyla'");
	TitleOfListForm = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Nhiệm vụ ngân sách của tôi (%1)';
			|ru = 'Мои бюджетные задачи (%1)';
			|en = 'My budget tasks (%1)'; fa = 'My budget tasks (%1)';
			|it = 'I miei obiettivi di budget (%1)';
			|pl = 'Moje zadania budżetowe (%1)';
			|tr = 'Bütçe görevlerim (%1)'"), UserTaskPresentation);
	ToDoItem.Id  = "BudgetProcessTasksForNextWeek";
	ToDoItem.HasToDoItems       = NumericalIndicators.QuantityForNextWeek > 0;
	ToDoItem.Presentation  = UserTaskPresentation;
	ToDoItem.Count     = NumericalIndicators.QuantityForNextWeek;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	AddlParameters = New Structure("Title", TitleOfListForm);
	ToDoItem.FormParameters = New Structure("FixedSettings, AddlParameters, PurposeUseKey",
							LayoutSettingsForNextWeek, AddlParameters, "ForNextWeek");
	ToDoItem.Owner       = "BudgetTasks";
	
EndProcedure

// The function returns setting of the layout data for the selection task on the executor.
Function GetLayoutSettingsForTasksByArtist()
	
	CompositionSettings = New DataCompositionSettings;
	
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue		= New DataCompositionField("DeletionMark");
	FilterElement.ComparisonType		= DataCompositionComparisonType.Equal;
	FilterElement.RightValue	= False;
	
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue		= New DataCompositionField("Executed");
	FilterElement.ComparisonType		= DataCompositionComparisonType.Equal;
	FilterElement.RightValue	= False;
	
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue		= New DataCompositionField("Performer");
	FilterElement.ComparisonType		= DataCompositionComparisonType.Equal;
	FilterElement.RightValue	= Users.AuthorizedUser();
	
	Return CompositionSettings;
	
EndFunction

// The function returns the settings of the data layout selection for overdue tasks.
Function GetLayoutSettingsForExpiredTasks()
	
	CompositionSettings = New DataCompositionSettings;
	
	Today = New StandardPeriod(StandardPeriodVariant.Today);
	
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue		= New DataCompositionField("TaskDueDate");
	FilterElement.ComparisonType		= DataCompositionComparisonType.NotEqual;
	FilterElement.RightValue	= '00010101';
	
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue		= New DataCompositionField("TaskDueDate");
	FilterElement.ComparisonType		= DataCompositionComparisonType.Less;
	FilterElement.RightValue	= Today.StartDate;
	
	Return CompositionSettings;
	
EndFunction

// The function returns the data layout settings for selecting tasks for today.
Function GetLayoutSettingsForTasksForToday()
	
	CompositionSettings = New DataCompositionSettings;
	
	Today = New StandardPeriod(StandardPeriodVariant.Today);
	
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue		= New DataCompositionField("TaskDueDate");   
	FilterElement.RightValue	= Today.StartDate;
	FilterElement.ComparisonType		= DataCompositionComparisonType.GreaterOrEqual;
	
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue		= New DataCompositionField("TaskDueDate");
	FilterElement.ComparisonType		= DataCompositionComparisonType.LessOrEqual;
	FilterElement.RightValue	= Today.EndDate;
	
	Return CompositionSettings;
	
EndFunction

// The function returns data layout settings for selecting tasks for the week.
Function GetLayoutSettingsForTasksForWeek()
	
	CompositionSettings = New DataCompositionSettings;
	
	Today = New StandardPeriod(StandardPeriodVariant.Today);
	ThisWeek = New StandardPeriod(StandardPeriodVariant.ThisWeek);
	
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue		= New DataCompositionField("TaskDueDate");
	FilterElement.ComparisonType		= DataCompositionComparisonType.Greater;
	FilterElement.RightValue	= Today.EndDate;
	
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue		= New DataCompositionField("TaskDueDate");   
	FilterElement.ComparisonType		= DataCompositionComparisonType.LessOrEqual;
	FilterElement.RightValue	= ThisWeek.EndDate;
	
	Return CompositionSettings;
	
EndFunction

// The function returns data layout settings for selecting tasks for the next week.
Function GetLayoutSettingsForNextWeekSTasks()
	
	CompositionSettings = New DataCompositionSettings;
	
	ThisWeek = New StandardPeriod(StandardPeriodVariant.ThisWeek);
	NextWeek = New StandardPeriod(StandardPeriodVariant.NextWeek);
	
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue		= New DataCompositionField("TaskDueDate");
	FilterElement.ComparisonType		= DataCompositionComparisonType.Greater;
	FilterElement.RightValue	= ThisWeek.EndDate;
	
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue		= New DataCompositionField("TaskDueDate");
	FilterElement.ComparisonType		= DataCompositionComparisonType.LessOrEqual;
	FilterElement.RightValue	= NextWeek.EndDate;
	
	Return CompositionSettings;
	
EndFunction

// Returns the action settings tree for entering budget documents and 
// existing documents for the budget issue.
// 
// Parameters:
//  ActionsTable - ValueTable - Action settings.
//  Action - EnumRef.TypesOfBudgetingStepActions - defines the type of budget document
//  BeginOfPeriod - Date - the beginning of the period.
//  EndOfPeriod - Date - end of period.
//  PeriodicityOfStage - EnumRef.Periodicity - Frequency of the budget preparation stage.
//  DocumentsList - Array of DocumentRef.BudgetEntryForm
//					Array from documentlink.installmentachalnyhostatesaccounting indicators - an array of existing documents
//  DesignResult - Boolean - True if additional processing occurs on the tree, the breakdown 
//								  for periods etc, to display in the form of budget tasks
//								  a lie is a quicker way, without additional processing of the tree.
//
// Returns:
//  ValueTree - A tree of action settings for entering budget documents and 
// 					 existing documents for a budget task.
//
Function ParametersForEnteringBudgetsByActionSettings(Val ActionsTable, Action,
                                                   BeginOfPeriod,
                                                   EndOfPeriod,
                                                   PeriodicityOfStage,
                                                   DocumentsList=Undefined,
                                                   DesignResult = True) Export
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	AllDocuments = False;
	If DocumentsList = Undefined Then
		AllDocuments = True;
		DocumentsList = New Array();
	EndIf;
	
	Schedule = Constants.MainEnterpriseCalendar.Get();
	
	CorrectActionSettings = True;
	ThisIsInputOfBudgetTurnoverAccordingToCalculationRules = (Action
		= Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules);
	ThisIsInputOfBalancesOfCalculatedIndicators = (Action
		= Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance);
	If TypeOf(ActionsTable) = Type("ValueTable") Then
		If ThisIsInputOfBalancesOfCalculatedIndicators Then
			TypesOfBudgetsSearch = ActionsTable.FindRows(New Structure("Name", "BalancesOfCalculatedIndicators"));
		Else
			TypesOfBudgetsSearch = ActionsTable.FindRows(New Structure("Name", "BudgetProfiles"));
		EndIf;
	Else
		TypesOfBudgetsSearch = New Array();
	EndIf;
	If TypesOfBudgetsSearch.Count() = 0 Then
		Common.MessageToUser(NStr("vi = 'Cài đặt hành động không hợp lệ.';
									|ru = 'Неверные настройки действия.';
									|en = 'Incorrect action settings.'; fa = 'Incorrect action settings.';
									|it = 'Impostazioni dell''azione non valide.';
									|pl = 'Nieprawidłowe ustawienia akcji.';
									|tr = 'Geçersiz eylem ayarları.'"));
		CorrectActionSettings = False;
	EndIf;
	If CorrectActionSettings Then
		AnalysisOfBudgetFillingSearch = ActionsTable.FindRows(New Structure("Name", "BudgetPopulationDimension"));
		If AnalysisOfBudgetFillingSearch.Count() = 0 Then
			Common.MessageToUser(NStr("vi = 'Cài đặt hành động không hợp lệ.';
										|ru = 'Неверные настройки действия.';
										|en = 'Incorrect action settings.'; fa = 'Incorrect action settings.';
										|it = 'Impostazioni dell''azione non valide.';
										|pl = 'Nieprawidłowe ustawienia akcji.';
										|tr = 'Geçersiz eylem ayarları.'"));
			CorrectActionSettings = False;
		EndIf;
	EndIf;
	
	If CorrectActionSettings Then
		BudgetProfiles = TypesOfBudgetsSearch[0].Value.Copy();
		BudgetPopulationDimension = AnalysisOfBudgetFillingSearch[0].Value.Copy();
		If ThisIsInputOfBalancesOfCalculatedIndicators Then
			CollapseAnalyticsOfBudgetFilling(BudgetPopulationDimension);
		EndIf;
	Else
		BudgetProfiles = New ValueTable;
		If ThisIsInputOfBudgetTurnoverAccordingToCalculationRules Then
			BudgetProfiles.Columns.Add("CalculationRule", New TypeDescription("CatalogRef.RuleForCalculatingRelatedBudgetBalancesAndTurnovers"));
			BudgetProfiles.Columns.Add("Periodicity", New TypeDescription("EnumRef.Periodicity"));
		ElsIf ThisIsInputOfBalancesOfCalculatedIndicators Then
			BudgetProfiles.Columns.Add("BudgetBalanceItem", New TypeDescription("CatalogRef.BudgetBalanceItems"));
		Else
			BudgetProfiles.Columns.Add("BudgetProfile", New TypeDescription("CatalogRef.BudgetProfiles"));
			BudgetProfiles.Columns.Add("Action", New TypeDescription("EnumRef.TypesOfBudgetEntryFormActions"));
		EndIf;
		BudgetProfiles.Columns.Add("RowKey", New TypeDescription("UUID"));
		BudgetProfiles.Columns.Add("DimensionSettingLineKey", New TypeDescription("UUID"));
		BudgetProfiles.Columns.Add("LineNumber", New TypeDescription("Number"));
		BudgetProfiles.Columns.Add("MeasurementRepresentation", New TypeDescription("String"));
		
		BudgetPopulationDimension = New ValueTable;
		BudgetPopulationDimension.Columns.Add("Scenario", New TypeDescription("CatalogRef.BudgetingScenarios"));
		BudgetPopulationDimension.Columns.Add("RowKey", New TypeDescription("UUID"));
		BudgetPopulationDimension.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
		BudgetPopulationDimension.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
		BudgetPopulationDimension.Columns.Add("AvailabilityCompany" ,New TypeDescription("Boolean"));
		BudgetPopulationDimension.Columns.Add("AvailabilityDepartment", New TypeDescription("Boolean"));
		BudgetPopulationDimension.Columns.Add("AvailabilityScenario", New TypeDescription("Boolean"));
		
		AnalystType = Metadata.Documents.BudgetEntryForm.Attributes.Dimension1.Type;
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			BudgetPopulationDimension.Columns.Add("Dimension" + DimensionNumber, AnalystType);
			BudgetPopulationDimension.Columns.Add("AvailabilityOfAnalytics_" + DimensionNumber,
				New TypeDescription("Boolean"));
		EndDo;
	EndIf;
	
	SQ = New StringQualifiers(36);
	ConnectionKeyType = New TypeDescription("String",,,,SQ);
	BudgetProfiles.Columns.Add("ConnectionKey",ConnectionKeyType);
	For Each Page1 In BudgetProfiles Do
		Page1.ConnectionKey = String(Page1.DimensionSettingLineKey);
	EndDo;
	
	BudgetPopulationDimension.Columns.Add("ConnectionKey",ConnectionKeyType);
	For Each Page1 In BudgetPopulationDimension Do
		Page1.ConnectionKey = String(Page1.RowKey);
	EndDo;
	
	Query = New Query;
	
	QueryTexts = New Array;
	RequestFieldTemplate = "%1.%2 AS %2";
	RequestGroupingTemplate = "%1.%2";
	RequestConnectionConditionTemplate = "%1.%2 = %3.%2";
	If ThisIsInputOfBudgetTurnoverAccordingToCalculationRules Then
		ArrayOfKeyRequestFields = CommonClientServer.ValueInArray("CalculationRule");
	ElsIf ThisIsInputOfBalancesOfCalculatedIndicators Then
		ArrayOfKeyRequestFields = CommonClientServer.ValueInArray("BudgetBalanceItem");
	Else
		ArrayOfKeyRequestFields = StringFunctionsClientServer.SplitStringIntoSubstringsArray("BudgetProfile,Action", ",");
	EndIf;
	
	// We place a table of budget types, supplement it with details that affect the definition of the period of budget instances.
	If ThisIsInputOfBudgetTurnoverAccordingToCalculationRules Then
		QueryText = 
		"SELECT
		|	BudgetProfiles.CalculationRule AS CalculationRule,
		|	BudgetProfiles.Periodicity AS Periodicity,
		|	BudgetProfiles.ConnectionKey AS ConnectionKey,
		|	BudgetProfiles.LineNumber AS LineNumber
		|INTO BudgetProfiles
		|FROM
		|	&BudgetProfiles AS BudgetProfiles
		|
		|INDEX BY
		|	CalculationRule
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CalculationRulesTable.CalculationRule AS CalculationRule,
		|	CalculationRulesTable.ConnectionKey AS ConnectionKey,
		|	CalculationRulesTable.LineNumber AS LineNumber,
		|	CalculationRulesTable.Periodicity AS Periodicity,
		|	VALUE(Enum.BudgetPreparationMethods.EmptyRef) AS PlanningMethod,
		|	0 AS NumberOfPeriodsOfRollingBudget
		|INTO ParametersOfBudgetTypes
		|FROM
		|	BudgetProfiles AS CalculationRulesTable
		|INNER JOIN
		|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CatalogCalculationsRules
		|ON
		|	CalculationRulesTable.CalculationRule = CatalogCalculationsRules.Ref
		|
		|INDEX BY
		|	ConnectionKey";
	ElsIf ThisIsInputOfBalancesOfCalculatedIndicators Then
		QueryText =
		"SELECT
		|	BudgetProfiles.BudgetBalanceItem AS BudgetBalanceItem,
		|	BudgetProfiles.ConnectionKey AS ConnectionKey,
		|	BudgetProfiles.LineNumber AS LineNumber
		|INTO BudgetProfiles
		|FROM
		|	&BudgetProfiles AS BudgetProfiles
		|
		|INDEX BY
		|	BudgetBalanceItem
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	TableBudgetIndicators.BudgetBalanceItem AS BudgetBalanceItem,
		|	TableBudgetIndicators.ConnectionKey AS ConnectionKey,
		|	TableBudgetIndicators.LineNumber AS LineNumber,
		|	&Periodicity AS Periodicity,
		|	VALUE(Enum.BudgetPreparationMethods.EmptyRef) AS PlanningMethod,
		|	0 AS NumberOfPeriodsOfRollingBudget
		|INTO ParametersOfBudgetTypes
		|FROM
		|	BudgetProfiles AS TableBudgetIndicators
		|INNER JOIN
		|	Catalog.BudgetBalanceItems AS CatalogBudgetBalanceItems
		|ON
		|	TableBudgetIndicators.BudgetBalanceItem = CatalogBudgetBalanceItems.Ref
		|
		|INDEX BY
		|	ConnectionKey";
	Else
		QueryText =
		"SELECT
		|	BudgetProfiles.BudgetProfile AS BudgetProfile,
		|	BudgetProfiles.Action AS Action,
		|	BudgetProfiles.ConnectionKey AS ConnectionKey,
		|	BudgetProfiles.LineNumber AS LineNumber
		|INTO BudgetProfiles
		|FROM
		|	&BudgetProfiles AS BudgetProfiles
		|
		|INDEX BY
		|	BudgetProfile
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableTypesOfBudgets.BudgetProfile AS BudgetProfile,
		|	CASE
		|		WHEN TableTypesOfBudgets.Action = VALUE(Enum.TypesOfBudgetEntryFormActions.EmptyRef)
		|			THEN VALUE(Enum.TypesOfBudgetEntryFormActions.EnterBudgetEntryForm)
		|		ELSE TableTypesOfBudgets.Action
		|	END AS Action,
		|	TableTypesOfBudgets.ConnectionKey AS ConnectionKey,
		|	TableTypesOfBudgets.LineNumber AS LineNumber,
		|	CatalogBudgetProfiles.Periodicity AS Periodicity,
		|	CatalogBudgetProfiles.PlanningMethod AS PlanningMethod,
		|	CatalogBudgetProfiles.NumberOfPeriodsOfRollingBudget AS NumberOfPeriodsOfRollingBudget
		|INTO ParametersOfBudgetTypes
		|FROM
		|	BudgetProfiles AS TableTypesOfBudgets
		|INNER JOIN
		|	Catalog.BudgetProfiles AS CatalogBudgetProfiles
		|ON
		|	TableTypesOfBudgets.BudgetProfile = CatalogBudgetProfiles.Ref
		|
		|INDEX BY
		|	ConnectionKey";
	EndIf;
	QueryTexts.Add(QueryText);
	
	QueryText =
		"SELECT
		|	AnalysisOfFillingBudgets.Organization AS Organization,
		|	AnalysisOfFillingBudgets.Department AS Department,
		|	&TextSampleAnalytics,
		|	AnalysisOfFillingBudgets.Scenario AS Scenario,
		|	AnalysisOfFillingBudgets.ConnectionKey AS ConnectionKey,
		|	AnalysisOfFillingBudgets.AvailabilityCompany AS AvailabilityCompany,
		|	AnalysisOfFillingBudgets.AvailabilityDepartment AS AvailabilityDepartment,
		|	&TextSelectionAvailabilityAnalytics,
		|	AnalysisOfFillingBudgets.AvailabilityScenario AS AvailabilityScenario
		|INTO BudgetAnalysts
		|FROM
		|	&AnalysisOfFillingBudgets AS AnalysisOfFillingBudgets";
	
	TextSampleAnalytics = "";
	TextSelectionAvailabilityAnalytics = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextSampleAnalytics = TextSampleAnalytics + ?(TextSampleAnalytics = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"AnalysisOfFillingBudgets.Dimension%1 AS Dimension%1",
				DimensionNumber);
		
		TextSelectionAvailabilityAnalytics = TextSelectionAvailabilityAnalytics
			+ ?(TextSelectionAvailabilityAnalytics = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"AnalysisOfFillingBudgets.AvailabilityOfAnalytics_%1 AS AvailabilityOfAnalytics_%1",
				DimensionNumber);
	EndDo;
	QueryText = StrReplace(QueryText, "&TextSampleAnalytics", TextSampleAnalytics);
	QueryText = StrReplace(QueryText, "&TextSelectionAvailabilityAnalytics", TextSelectionAvailabilityAnalytics);
	
	QueryTexts.Add(QueryText);
	
	// We define the boundaries of the period for the Budget Instance document, depending on the settings of the budget type.
	// For more information, see the Budget View method.Align the periodicity of the budget
	QueryText =
	"SELECT
		|	&FieldsByActionType,
		|	CASE
		|		WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.WEEK)
		|			THEN BEGINOFPERIOD(CalendarSchedules.ScheduleDate, WEEK)
		|		WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.TENDAYS)
		|			THEN BEGINOFPERIOD(CalendarSchedules.ScheduleDate, TENDAYS)
		|		WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.MONTH)
		|			THEN BEGINOFPERIOD(CalendarSchedules.ScheduleDate, MONTH)
		|		WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|			THEN BEGINOFPERIOD(CalendarSchedules.ScheduleDate, QUARTER)
		|		WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN BEGINOFPERIOD(CalendarSchedules.ScheduleDate, HALFYEAR)
		|		WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.YEAR)
		|			THEN BEGINOFPERIOD(CalendarSchedules.ScheduleDate, Year)
		|		ELSE BEGINOFPERIOD(CalendarSchedules.ScheduleDate, DAY)
		|	END AS BeginOfPeriod,
		|	ParametersOfBudgetTypes.Periodicity AS Periodicity,
		|	CASE
		|		WHEN ParametersOfBudgetTypes.PlanningMethod = VALUE(Enum.BudgetPreparationMethods.Rolling)
		|			THEN CASE
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.WEEK)
		|					THEN ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, WEEK, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), WEEK)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.TENDAYS)
		|					THEN ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, TENDAYS, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), TENDAYS)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.MONTH)
		|					THEN ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, MONTH, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), MONTH)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|					THEN ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, QUARTER, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), QUARTER)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|					THEN ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, HALFYEAR, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), HALFYEAR)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.YEAR)
		|					THEN ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, Year, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), Year)
		|				ELSE ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, DAY, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), DAY)
		|			END
		|		ELSE CASE
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.WEEK)
		|					THEN ENDOFPERIOD(CalendarSchedules.ScheduleDate, WEEK)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.TENDAYS)
		|					THEN ENDOFPERIOD(CalendarSchedules.ScheduleDate, TENDAYS)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.MONTH)
		|					THEN ENDOFPERIOD(CalendarSchedules.ScheduleDate, MONTH)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|					THEN ENDOFPERIOD(CalendarSchedules.ScheduleDate, QUARTER)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|					THEN ENDOFPERIOD(CalendarSchedules.ScheduleDate, HALFYEAR)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.YEAR)
		|					THEN ENDOFPERIOD(CalendarSchedules.ScheduleDate, Year)
		|				ELSE ENDOFPERIOD(CalendarSchedules.ScheduleDate, DAY)
		|			END
		|	END AS EndOfPeriod
		|INTO TableOfPeriods
		|FROM
		|	InformationRegister.CalendarSchedules AS CalendarSchedules
		|INNER JOIN
		|	ParametersOfBudgetTypes AS ParametersOfBudgetTypes
		|ON
		|	CalendarSchedules.Calendar = &WorkScheduleCalendar
		|	AND CalendarSchedules.ScheduleDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|
		|GROUP BY
		|	&GroupsByActionType,
		|	CASE
		|		WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.WEEK)
		|			THEN BEGINOFPERIOD(CalendarSchedules.ScheduleDate, WEEK)
		|		WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.TENDAYS)
		|			THEN BEGINOFPERIOD(CalendarSchedules.ScheduleDate, TENDAYS)
		|		WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.MONTH)
		|			THEN BEGINOFPERIOD(CalendarSchedules.ScheduleDate, MONTH)
		|		WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|			THEN BEGINOFPERIOD(CalendarSchedules.ScheduleDate, QUARTER)
		|		WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN BEGINOFPERIOD(CalendarSchedules.ScheduleDate, HALFYEAR)
		|		WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.YEAR)
		|			THEN BEGINOFPERIOD(CalendarSchedules.ScheduleDate, Year)
		|		ELSE BEGINOFPERIOD(CalendarSchedules.ScheduleDate, DAY)
		|	END,
		|	ParametersOfBudgetTypes.Periodicity,
		|	CASE
		|		WHEN ParametersOfBudgetTypes.PlanningMethod = VALUE(Enum.BudgetPreparationMethods.Rolling)
		|			THEN CASE
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.WEEK)
		|					THEN ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, WEEK, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), WEEK)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.TENDAYS)
		|					THEN ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, TENDAYS, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), TENDAYS)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.MONTH)
		|					THEN ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, MONTH, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), MONTH)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|					THEN ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, QUARTER, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), QUARTER)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|					THEN ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, HALFYEAR, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), HALFYEAR)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.YEAR)
		|					THEN ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, Year, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), Year)
		|				ELSE ENDOFPERIOD(DATEADD(CalendarSchedules.ScheduleDate, DAY, ParametersOfBudgetTypes.NumberOfPeriodsOfRollingBudget - 1), DAY)
		|			END
		|		ELSE CASE
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.WEEK)
		|					THEN ENDOFPERIOD(CalendarSchedules.ScheduleDate, WEEK)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.TENDAYS)
		|					THEN ENDOFPERIOD(CalendarSchedules.ScheduleDate, TENDAYS)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.MONTH)
		|					THEN ENDOFPERIOD(CalendarSchedules.ScheduleDate, MONTH)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|					THEN ENDOFPERIOD(CalendarSchedules.ScheduleDate, QUARTER)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|					THEN ENDOFPERIOD(CalendarSchedules.ScheduleDate, HALFYEAR)
		|				WHEN ParametersOfBudgetTypes.Periodicity = VALUE(Enum.Periodicity.YEAR)
		|					THEN ENDOFPERIOD(CalendarSchedules.ScheduleDate, Year)
		|				ELSE ENDOFPERIOD(CalendarSchedules.ScheduleDate, DAY)
		|			END
		|	END";
	FieldsByActionType = New Array;
	GroupsByActionType = New Array;
	For Each TheQueryBox In ArrayOfKeyRequestFields Do
		FieldsByActionType.Add(StringFunctionsClientServer.SubstituteParametersToString(RequestFieldTemplate,
			"ParametersOfBudgetTypes", TheQueryBox));
		GroupsByActionType.Add(StringFunctionsClientServer.SubstituteParametersToString(RequestGroupingTemplate,
			"ParametersOfBudgetTypes", TheQueryBox));
	EndDo;
	QueryText = StrReplace(QueryText, "&FieldsByActionType", StrConcat(FieldsByActionType, "," + Chars.LF
		+ Chars.Tab));
	QueryText = StrReplace(QueryText, "&GroupsByActionType", StrConcat(GroupsByActionType, "," + Chars.LF
		+ Chars.Tab));
	QueryTexts.Add(QueryText);
	
	If ThisIsInputOfBudgetTurnoverAccordingToCalculationRules Then
		QueryText =
		"SELECT
		|	MAX(RegistrarOfBudgetTurnover.Ref) AS Ref,
		|	&TextListOfEmptyAnalytics,
		|	RegistrarOfBudgetTurnover.CalculationRule AS CalculationRule,
		|	RegistrarOfBudgetTurnover.Scenario AS Scenario,
		|	RegistrarOfBudgetTurnover.Organization AS Organization,
		|	RegistrarOfBudgetTurnover.Department AS Department,
		|	RegistrarOfBudgetTurnover.PlanningPeriod AS BeginOfPeriod,
		|	BEGINOFPERIOD(CASE
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.WEEK)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, WEEK)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.TENDAYS)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, TENDAYS)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.MONTH)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, MONTH)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, QUARTER)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, HALFYEAR)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.YEAR)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, YEAR)
		|		ELSE ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, DAY)
		|	END, DAY) AS PeriodEnding,
		|	RegistrarOfBudgetTurnover.Periodicity AS Periodicity,
		|	CAST(RegistrarOfBudgetTurnover.Comment AS STRING(250)) AS Comment
		|INTO DocumentsList
		|FROM
		|	Document.RegistrarOfBudgetTurnover AS RegistrarOfBudgetTurnover
		|INNER JOIN
		|	TableOfPeriods AS TableOfPeriods
		|ON
		|	&AllDocuments
		|	AND RegistrarOfBudgetTurnover.CalculationRule = TableOfPeriods.CalculationRule
		|	AND RegistrarOfBudgetTurnover.PlanningPeriod = TableOfPeriods.BeginOfPeriod
		|	AND RegistrarOfBudgetTurnover.Periodicity = TableOfPeriods.Periodicity
		|	AND NOT RegistrarOfBudgetTurnover.Ref IN (&DocumentsList)
		|	AND NOT RegistrarOfBudgetTurnover.DeletionMark
		|	AND (RegistrarOfBudgetTurnover.Organization, RegistrarOfBudgetTurnover.Department, RegistrarOfBudgetTurnover.Scenario) IN
		|			(SELECT
		|				A.Organization,
		|				A.Department,
		|				A.Scenario
		|			FROM
		|				BudgetAnalysts AS A)
		|
		|GROUP BY
		|	RegistrarOfBudgetTurnover.CalculationRule,
		|	RegistrarOfBudgetTurnover.Scenario,
		|	RegistrarOfBudgetTurnover.Organization,
		|	RegistrarOfBudgetTurnover.Department,
		|	RegistrarOfBudgetTurnover.PlanningPeriod,
		|	RegistrarOfBudgetTurnover.Periodicity,
		|	CAST(RegistrarOfBudgetTurnover.Comment AS STRING(250))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegistrarOfBudgetTurnover.Ref AS Ref,
		|	MAX(ISNULL(BudgetAnalysts.AvailabilityCompany, FALSE)) AS AvailabilityCompany,
		|	MAX(ISNULL(BudgetAnalysts.AvailabilityDepartment, FALSE)) AS AvailabilityDepartment,
		|	&TextAvailabilityOfEmptyAnalytics,
		|	ISNULL(BudgetAnalysts.AvailabilityScenario, FALSE) AS AvailabilityScenario,
		|	MAX(ISNULL(BudgetAnalysts.ConnectionKey, """")) AS ConnectionKey
		|INTO AvailabilityAnalystEB
		|FROM
		|	Document.RegistrarOfBudgetTurnover AS RegistrarOfBudgetTurnover
		|		LEFT JOIN ParametersOfBudgetTypes AS ParametersOfBudgetTypes
		|		ON RegistrarOfBudgetTurnover.CalculationRule = ParametersOfBudgetTypes.CalculationRule
		|		LEFT JOIN BudgetAnalysts AS BudgetAnalysts
		|		ON (ParametersOfBudgetTypes.ConnectionKey = BudgetAnalysts.ConnectionKey)
		|			AND (BudgetAnalysts.AvailabilityCompany
		|				OR RegistrarOfBudgetTurnover.Organization = BudgetAnalysts.Organization)
		|			AND (BudgetAnalysts.AvailabilityDepartment
		|				OR RegistrarOfBudgetTurnover.Department = BudgetAnalysts.Department)
		|			AND (BudgetAnalysts.AvailabilityScenario
		|				OR RegistrarOfBudgetTurnover.Scenario = BudgetAnalysts.Scenario)
		|WHERE
		|	RegistrarOfBudgetTurnover.Ref IN(&DocumentsList)
		|
		|GROUP BY
		|	RegistrarOfBudgetTurnover.Ref,
		|	ISNULL(BudgetAnalysts.AvailabilityScenario, FALSE)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegistrarOfBudgetTurnover.CalculationRule AS CalculationRule,
		|	RegistrarOfBudgetTurnover.Organization AS Organization,
		|	RegistrarOfBudgetTurnover.Department AS Department,
		|	RegistrarOfBudgetTurnover.Scenario AS Scenario,
		|	RegistrarOfBudgetTurnover.PlanningPeriod AS BeginOfPeriod,
		|	CASE
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.WEEK)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, WEEK)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.TENDAYS)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, TENDAYS)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.MONTH)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, MONTH)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, QUARTER)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, HALFYEAR)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.YEAR)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, YEAR)
		|		ELSE ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, DAY)
		|	END AS EndOfPeriod,
		|	SUM(1) AS DocumentsCount,
		|	&TextListOfEmptyAnalytics
		|INTO DocumentsByTask
		|FROM
		|	Document.RegistrarOfBudgetTurnover AS RegistrarOfBudgetTurnover
		|WHERE
		|	RegistrarOfBudgetTurnover.Ref IN(&DocumentsList)
		|
		|GROUP BY
		|	RegistrarOfBudgetTurnover.CalculationRule,
		|	RegistrarOfBudgetTurnover.Organization,
		|	RegistrarOfBudgetTurnover.Department,
		|	RegistrarOfBudgetTurnover.Scenario,
		|	RegistrarOfBudgetTurnover.PlanningPeriod,
		|	RegistrarOfBudgetTurnover.Periodicity";
	ElsIf ThisIsInputOfBalancesOfCalculatedIndicators Then
		QueryText =
		"SELECT
		|	MAX(SettingOfEstimatesOpeningBalance.Ref) AS Ref,
		|	&TextListOfEmptyAnalytics,
		|	SettingOfEstimatesOpeningBalance.BudgetBalanceItem AS BudgetBalanceItem,
		|	SettingOfEstimatesOpeningBalance.Scenario AS Scenario,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	SettingOfEstimatesOpeningBalance.DateOfRemainingGoods AS BeginOfPeriod,
		|	CASE
		|		WHEN &Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|			THEN ENDOFPERIOD(SettingOfEstimatesOpeningBalance.DateOfRemainingGoods, QUARTER)
		|		WHEN &Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN ENDOFPERIOD(SettingOfEstimatesOpeningBalance.DateOfRemainingGoods, HALFYEAR)
		|		WHEN &Periodicity = VALUE(Enum.Periodicity.YEAR)
		|			THEN ENDOFPERIOD(SettingOfEstimatesOpeningBalance.DateOfRemainingGoods, YEAR)
		|		ELSE ENDOFPERIOD(SettingOfEstimatesOpeningBalance.DateOfRemainingGoods, MONTH)
		|	END AS PeriodEnding,
		|	&Periodicity AS Periodicity,
		|	CAST(SettingOfEstimatesOpeningBalance.Comment AS STRING(250)) AS Comment
		|INTO DocumentsList
		|FROM
		|	Document.SettingOfEstimatesOpeningBalance AS SettingOfEstimatesOpeningBalance
		|INNER JOIN
		|	TableOfPeriods AS TableOfPeriods
		|ON
		|	&AllDocuments
		|	AND SettingOfEstimatesOpeningBalance.BudgetBalanceItem = TableOfPeriods.BudgetBalanceItem
		|	AND SettingOfEstimatesOpeningBalance.DateOfRemainingGoods = TableOfPeriods.BeginOfPeriod
		|	AND NOT SettingOfEstimatesOpeningBalance.Ref IN (&DocumentsList)
		|	AND NOT SettingOfEstimatesOpeningBalance.DeletionMark
		|	AND SettingOfEstimatesOpeningBalance.Scenario IN
		|			(SELECT
		|				A.Scenario
		|			FROM
		|				BudgetAnalysts AS A)
		|
		|GROUP BY
		|	SettingOfEstimatesOpeningBalance.BudgetBalanceItem,
		|	SettingOfEstimatesOpeningBalance.Scenario,
		|	SettingOfEstimatesOpeningBalance.DateOfRemainingGoods,
		|	CAST(SettingOfEstimatesOpeningBalance.Comment AS STRING(250))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SettingOfEstimatesOpeningBalance.Ref AS Ref,
		|	MAX(ISNULL(BudgetAnalysts.AvailabilityCompany, FALSE)) AS AvailabilityCompany,
		|	MAX(ISNULL(BudgetAnalysts.AvailabilityDepartment, FALSE)) AS AvailabilityDepartment,
		|	&TextAvailabilityOfEmptyAnalytics,
		|	ISNULL(BudgetAnalysts.AvailabilityScenario, FALSE) AS AvailabilityScenario,
		|	MAX(ISNULL(BudgetAnalysts.ConnectionKey, """")) AS ConnectionKey
		|INTO AvailabilityAnalystEB
		|FROM
		|	Document.SettingOfEstimatesOpeningBalance AS SettingOfEstimatesOpeningBalance
		|		LEFT JOIN ParametersOfBudgetTypes AS ParametersOfBudgetTypes
		|		ON SettingOfEstimatesOpeningBalance.BudgetBalanceItem = ParametersOfBudgetTypes.BudgetBalanceItem
		|		LEFT JOIN BudgetAnalysts AS BudgetAnalysts
		|		ON (ParametersOfBudgetTypes.ConnectionKey = BudgetAnalysts.ConnectionKey)
		|			AND (BudgetAnalysts.AvailabilityScenario
		|				OR SettingOfEstimatesOpeningBalance.Scenario = BudgetAnalysts.Scenario)
		|WHERE
		|	SettingOfEstimatesOpeningBalance.Ref IN(&DocumentsList)
		|
		|GROUP BY
		|	SettingOfEstimatesOpeningBalance.Ref,
		|	ISNULL(BudgetAnalysts.AvailabilityScenario, FALSE)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SettingOfEstimatesOpeningBalance.BudgetBalanceItem AS BudgetBalanceItem,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	SettingOfEstimatesOpeningBalance.Scenario AS Scenario,
		|	SettingOfEstimatesOpeningBalance.DateOfRemainingGoods AS BeginOfPeriod,
		|	CASE
		|		WHEN &Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|			THEN ENDOFPERIOD(SettingOfEstimatesOpeningBalance.DateOfRemainingGoods, QUARTER)
		|		WHEN &Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN ENDOFPERIOD(SettingOfEstimatesOpeningBalance.DateOfRemainingGoods, HALFYEAR)
		|		WHEN &Periodicity = VALUE(Enum.Periodicity.YEAR)
		|			THEN ENDOFPERIOD(SettingOfEstimatesOpeningBalance.DateOfRemainingGoods, YEAR)
		|		ELSE ENDOFPERIOD(SettingOfEstimatesOpeningBalance.DateOfRemainingGoods, MONTH)
		|	END AS EndOfPeriod,
		|	SUM(1) AS DocumentsCount,
		|	&TextListOfEmptyAnalytics
		|INTO DocumentsByTask
		|FROM
		|	Document.SettingOfEstimatesOpeningBalance AS SettingOfEstimatesOpeningBalance
		|WHERE
		|	SettingOfEstimatesOpeningBalance.Ref IN(&DocumentsList)
		|
		|GROUP BY
		|	SettingOfEstimatesOpeningBalance.BudgetBalanceItem,
		|	SettingOfEstimatesOpeningBalance.Scenario,
		|	SettingOfEstimatesOpeningBalance.DateOfRemainingGoods";
	Else
		QueryText =
		"SELECT
		|	MAX(BudgetEntryForm.Ref) AS Ref,
		|	&TextDocumentListAnalyticsSelection,
		|	BudgetEntryForm.BudgetProfile AS BudgetProfile,
		|	BudgetEntryForm.Action AS Action,
		|	BudgetEntryForm.Scenario AS Scenario,
		|	BudgetEntryForm.Organization AS Organization,
		|	BudgetEntryForm.Department AS Department,
		|	BudgetEntryForm.BeginOfPeriod AS BeginOfPeriod,
		|	BudgetEntryForm.PeriodEnding AS PeriodEnding,
		|	BudgetEntryForm.BudgetProfile.Periodicity AS Periodicity,
		|	CAST(BudgetEntryForm.Comment AS STRING(250)) AS Comment
		|INTO DocumentsList
		|FROM
		|	Document.BudgetEntryForm AS BudgetEntryForm
		|INNER JOIN
		|	TableOfPeriods AS TableOfPeriods
		|ON
		|	&AllDocuments
		|	AND BudgetEntryForm.BudgetProfile = TableOfPeriods.BudgetProfile
		|	AND BudgetEntryForm.Action = TableOfPeriods.Action
		|	AND BudgetEntryForm.BeginOfPeriod = TableOfPeriods.BeginOfPeriod
		|	AND BudgetEntryForm.PeriodEnding = TableOfPeriods.EndOfPeriod
		|	AND NOT BudgetEntryForm.Ref IN (&DocumentsList)
		|	AND NOT BudgetEntryForm.DeletionMark
		|	AND (BudgetEntryForm.Organization, BudgetEntryForm.Department, BudgetEntryForm.Scenario) IN
		|			(SELECT
		|				A.Organization,
		|				A.Department,
		|				A.Scenario
		|			FROM
		|				BudgetAnalysts AS A)
		|
		|GROUP BY
		|	&TextDocumentListAnalyticsGrouping,
		|	BudgetEntryForm.BudgetProfile,
		|	BudgetEntryForm.Action,
		|	BudgetEntryForm.Scenario,
		|	BudgetEntryForm.Organization,
		|	BudgetEntryForm.Department,
		|	BudgetEntryForm.BeginOfPeriod,
		|	BudgetEntryForm.PeriodEnding,
		|	BudgetEntryForm.BudgetProfile.Periodicity,
		|	CAST(BudgetEntryForm.Comment AS STRING(250))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BudgetEntryForm.Ref AS Ref,
		|	MAX(ISNULL(BudgetAnalysts.AvailabilityCompany, FALSE)) AS AvailabilityCompany,
		|	MAX(ISNULL(BudgetAnalysts.AvailabilityDepartment, FALSE)) AS AvailabilityDepartment,
		|	&TextAvailabilityAnalystEBSampleAvailabilityAnalyst,
		|	ISNULL(BudgetAnalysts.AvailabilityScenario, FALSE) AS AvailabilityScenario,
		|	MAX(ISNULL(BudgetAnalysts.ConnectionKey, """")) AS ConnectionKey
		|INTO AvailabilityAnalystEB
		|FROM
		|	Document.BudgetEntryForm AS BudgetEntryForm
		|		LEFT JOIN ParametersOfBudgetTypes AS ParametersOfBudgetTypes
		|		ON BudgetEntryForm.BudgetProfile = ParametersOfBudgetTypes.BudgetProfile
		|			AND BudgetEntryForm.Action = ParametersOfBudgetTypes.Action
		|		LEFT JOIN BudgetAnalysts AS BudgetAnalysts
		|		ON (ParametersOfBudgetTypes.ConnectionKey = BudgetAnalysts.ConnectionKey)
		|			AND (BudgetAnalysts.AvailabilityCompany
		|				OR BudgetEntryForm.Organization = BudgetAnalysts.Organization)
		|			AND (BudgetAnalysts.AvailabilityDepartment
		|				OR BudgetEntryForm.Department = BudgetAnalysts.Department)
		|			AND (BudgetAnalysts.AvailabilityScenario
		|				OR BudgetEntryForm.Scenario = BudgetAnalysts.Scenario)
		|			AND &TextAvailabilityAnalystEBConnectionAnalyst
		|WHERE
		|	BudgetEntryForm.Ref IN(&DocumentsList)
		|
		|GROUP BY
		|	BudgetEntryForm.Ref,
		|	ISNULL(BudgetAnalysts.AvailabilityScenario, FALSE)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BudgetEntryForm.BudgetProfile AS BudgetProfile,
		|	BudgetEntryForm.Action AS Action,
		|	BudgetEntryForm.Organization AS Organization,
		|	BudgetEntryForm.Department AS Department,
		|	BudgetEntryForm.Scenario AS Scenario,
		|	BudgetEntryForm.BeginOfPeriod AS BeginOfPeriod,
		|	ENDOFPERIOD(BudgetEntryForm.PeriodEnding, DAY) AS EndOfPeriod,
		|	SUM(1) AS DocumentsCount,
		|	&TextDocumentsForSampleAnalyticsIssue
		|INTO DocumentsByTask
		|FROM
		|	Document.BudgetEntryForm AS BudgetEntryForm
		|WHERE
		|	BudgetEntryForm.Ref IN(&DocumentsList)
		|
		|GROUP BY
		|	BudgetEntryForm.BudgetProfile,
		|	BudgetEntryForm.Action,
		|	BudgetEntryForm.Organization,
		|	BudgetEntryForm.Department,
		|	BudgetEntryForm.Scenario,
		|	BudgetEntryForm.BeginOfPeriod,
		|	ENDOFPERIOD(BudgetEntryForm.PeriodEnding, DAY),
		|	&TextDocumentsForTaskGroupingAnalytics";
	EndIf;
	
	QueryText = QueryText + Common.QueryBatchSeparator() +
		"SELECT
		|	&FieldsByActionType,
		|	&EmptyFieldsByActionType,
		|	OtherTypesOfBudgets.Periodicity AS BudgetFrequency,
		|	BudgetAnalysts.Organization AS Organization,
		|	BudgetAnalysts.Department AS Department,
		|	&TextSelection1Analyst,
		|	BudgetAnalysts.Scenario AS Scenario,
		|	TableOfPeriods.BeginOfPeriod AS BeginOfPeriod,
		|	DocumentsList.Ref AS Document,
		|	TableOfPeriods.EndOfPeriod AS EndOfPeriod,
		|	PRESENTATION(ISNULL(DocumentsList.Ref, &CreateCommand)) AS DocumentPresentation,
		|	"""" AS Comment,
		|	ISNULL(DocumentsList.Ref.Number, """") AS DocumentNumber,
		|	ISNULL(DocumentsList.Ref.DATE, """") AS DocumentDate,
		|	OtherTypesOfBudgets.LineNumber AS BudgetTypeLineNumber,
		|	BudgetAnalysts.AvailabilityCompany AS AvailabilityCompany,
		|	BudgetAnalysts.AvailabilityDepartment AS AvailabilityDepartment,
		|	&TextSelection1AvailabilityAnalyst,
		|	BudgetAnalysts.AvailabilityScenario AS AvailabilityScenario
		|FROM
		|	ParametersOfBudgetTypes AS OtherTypesOfBudgets
		|		LEFT JOIN BudgetAnalysts AS BudgetAnalysts
		|		ON OtherTypesOfBudgets.ConnectionKey = BudgetAnalysts.ConnectionKey
		|		LEFT JOIN TableOfPeriods AS TableOfPeriods
		|		ON &ConnectionConditionsByActionType1
		|		LEFT JOIN DocumentsList AS DocumentsList
		|		ON (BudgetAnalysts.Organization = DocumentsList.Organization)
		|			AND (BudgetAnalysts.Department = DocumentsList.Department)
		|			AND (BudgetAnalysts.Scenario = DocumentsList.Scenario)
		|			AND &TextSelection1ConnectionListOfAnalyticsDocuments
		|			AND &ConnectionConditionsByActionType2
		|			AND (TableOfPeriods.BeginOfPeriod = DocumentsList.BeginOfPeriod)
		|			AND (TableOfPeriods.EndOfPeriod = ENDOFPERIOD(DocumentsList.PeriodEnding, DAY))
		|			AND (TableOfPeriods.Periodicity = DocumentsList.Periodicity)
		|		LEFT JOIN DocumentsByTask AS DocumentsByTask
		|		ON &ConnectionConditionsByActionType3
		|			AND (BudgetAnalysts.Organization = DocumentsByTask.Organization)
		|			AND (BudgetAnalysts.Department = DocumentsByTask.Department)
		|			AND (BudgetAnalysts.Scenario = DocumentsByTask.Scenario)
		|			AND (TableOfPeriods.BeginOfPeriod = DocumentsByTask.BeginOfPeriod)
		|			AND (TableOfPeriods.EndOfPeriod = DocumentsByTask.EndOfPeriod)
		|			AND &TextSelection1ConnectionDocumentsForAnalyticsTask
		|WHERE
		|	CASE
		|			WHEN ISNULL(DocumentsByTask.DocumentsCount, 0) > 0
		|				THEN FALSE
		|			ELSE TRUE
		|		END
		|	AND NOT TableOfPeriods.BeginOfPeriod IS NULL";
	FieldsByActionType = New Array;
	ConnectionConditionsByActionType1 = New Array;
	ConnectionConditionsByActionType2 = New Array;
	ConnectionConditionsByActionType3 = New Array;
	For Each TheQueryBox In ArrayOfKeyRequestFields Do
		FieldsByActionType.Add(StringFunctionsClientServer.SubstituteParametersToString(RequestFieldTemplate,
			"OtherTypesOfBudgets", TheQueryBox));
		ConnectionConditionsByActionType1.Add(StringFunctionsClientServer.SubstituteParametersToString(
			RequestConnectionConditionTemplate, "OtherTypesOfBudgets", TheQueryBox, "TableOfPeriods"));
		ConnectionConditionsByActionType2.Add(StringFunctionsClientServer.SubstituteParametersToString(
			RequestConnectionConditionTemplate, "OtherTypesOfBudgets", TheQueryBox, "DocumentsList"));
		ConnectionConditionsByActionType3.Add(StringFunctionsClientServer.SubstituteParametersToString(
			RequestConnectionConditionTemplate, "OtherTypesOfBudgets", TheQueryBox, "DocumentsByTask"));
	EndDo;
	QueryText = StrReplace(QueryText, "&FieldsByActionType", StrConcat(FieldsByActionType, "," + Chars.LF
		+ Chars.Tab));
	QueryText = StrReplace(QueryText, "&ConnectionConditionsByActionType1", StrConcat(
		ConnectionConditionsByActionType1, Chars.LF + Chars.Tab + "And "));
	QueryText = StrReplace(QueryText, "&ConnectionConditionsByActionType2", StrConcat(
		ConnectionConditionsByActionType2, Chars.LF + Chars.Tab + "And "));
	QueryText = StrReplace(QueryText, "&ConnectionConditionsByActionType3", StrConcat(
		ConnectionConditionsByActionType3, Chars.LF + Chars.Tab + "And "));
	
	If ThisIsInputOfBudgetTurnoverAccordingToCalculationRules Then
		QueryText = QueryText + TMCommonUse.QuerySeparatorInJoin() +
		"SELECT
		|	RegistrarOfBudgetTurnover.CalculationRule AS CalculationRule,
		|	&EmptyFieldsByActionType,
		|	RegistrarOfBudgetTurnover.Periodicity AS BudgetFrequency,
		|	RegistrarOfBudgetTurnover.Organization AS Organization,
		|	RegistrarOfBudgetTurnover.Department AS Department,
		|	&TextListOfEmptyAnalytics,
		|	RegistrarOfBudgetTurnover.Scenario AS Scenario,
		|	RegistrarOfBudgetTurnover.PlanningPeriod AS BeginOfPeriod,
		|	RegistrarOfBudgetTurnover.Ref AS Document,
		|	CASE
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.WEEK)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, WEEK)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.TENDAYS)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, TENDAYS)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.MONTH)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, MONTH)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, QUARTER)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, HALFYEAR)
		|		WHEN RegistrarOfBudgetTurnover.Periodicity = VALUE(Enum.Periodicity.YEAR)
		|			THEN ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, YEAR)
		|		ELSE ENDOFPERIOD(RegistrarOfBudgetTurnover.PlanningPeriod, DAY)
		|	END AS EndOfPeriod,
		|	PRESENTATION(RegistrarOfBudgetTurnover.Ref) AS DocumentPresentation,
		|	RegistrarOfBudgetTurnover.Comment AS Comment,
		|	RegistrarOfBudgetTurnover.Number AS DocumentNumber,
		|	RegistrarOfBudgetTurnover.Date AS DocumentDate,
		|	ISNULL(BudgetProfiles.LineNumber, 999999) AS BudgetTypeLineNumber,
		|	AvailabilityAnalystEB.AvailabilityCompany AS AvailabilityCompany,
		|	AvailabilityAnalystEB.AvailabilityDepartment AS AvailabilityDepartment,
		|	&TextAvailabilityOfEmptyAnalytics,
		|	AvailabilityAnalystEB.AvailabilityScenario AS AvailabilityScenario
		|FROM
		|	Document.RegistrarOfBudgetTurnover AS RegistrarOfBudgetTurnover
		|		LEFT JOIN AvailabilityAnalystEB AS AvailabilityAnalystEB
		|		ON RegistrarOfBudgetTurnover.Ref = AvailabilityAnalystEB.Ref
		|		LEFT JOIN ParametersOfBudgetTypes AS BudgetProfiles
		|		ON AvailabilityAnalystEB.ConnectionKey = BudgetProfiles.ConnectionKey
		|		AND RegistrarOfBudgetTurnover.CalculationRule = BudgetProfiles.CalculationRule
		|WHERE
		|	RegistrarOfBudgetTurnover.Ref IN(&DocumentsList)
		|
		|ORDER BY
		|	BudgetTypeLineNumber,
		|	BeginOfPeriod,
		|	DocumentNumber
		|TOTALS 
		|	MAX(BudgetFrequency) AS BudgetFrequency
		|BY
		|	CalculationRule,
		|	BeginOfPeriod";
	ElsIf ThisIsInputOfBalancesOfCalculatedIndicators Then
		QueryText = QueryText + TMCommonUse.QuerySeparatorInJoin() +
		"SELECT
		|	SettingOfEstimatesOpeningBalance.BudgetBalanceItem AS BudgetBalanceItem,
		|	&EmptyFieldsByActionType,
		|	&Periodicity AS BudgetFrequency,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	&TextListOfEmptyAnalytics,
		|	SettingOfEstimatesOpeningBalance.Scenario AS Scenario,
		|	SettingOfEstimatesOpeningBalance.DateOfRemainingGoods AS BeginOfPeriod,
		|	SettingOfEstimatesOpeningBalance.Ref AS Document,
		|	CASE
		|		WHEN &Periodicity = VALUE(Enum.Periodicity.QUARTER)
		|			THEN ENDOFPERIOD(SettingOfEstimatesOpeningBalance.DateOfRemainingGoods, QUARTER)
		|		WHEN &Periodicity = VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN ENDOFPERIOD(SettingOfEstimatesOpeningBalance.DateOfRemainingGoods, HALFYEAR)
		|		WHEN &Periodicity = VALUE(Enum.Periodicity.YEAR)
		|			THEN ENDOFPERIOD(SettingOfEstimatesOpeningBalance.DateOfRemainingGoods, YEAR)
		|		ELSE ENDOFPERIOD(SettingOfEstimatesOpeningBalance.DateOfRemainingGoods, MONTH)
		|	END AS EndOfPeriod,
		|	PRESENTATION(SettingOfEstimatesOpeningBalance.Ref) AS DocumentPresentation,
		|	SettingOfEstimatesOpeningBalance.Comment AS Comment,
		|	SettingOfEstimatesOpeningBalance.Number AS DocumentNumber,
		|	SettingOfEstimatesOpeningBalance.Date AS DocumentDate,
		|	ISNULL(BudgetProfiles.LineNumber, 999999) AS BudgetTypeLineNumber,
		|	AvailabilityAnalystEB.AvailabilityCompany AS AvailabilityCompany,
		|	AvailabilityAnalystEB.AvailabilityDepartment AS AvailabilityDepartment,
		|	&TextAvailabilityOfEmptyAnalytics,
		|	AvailabilityAnalystEB.AvailabilityScenario AS AvailabilityScenario
		|FROM
		|	Document.SettingOfEstimatesOpeningBalance AS SettingOfEstimatesOpeningBalance
		|		LEFT JOIN AvailabilityAnalystEB AS AvailabilityAnalystEB
		|		ON SettingOfEstimatesOpeningBalance.Ref = AvailabilityAnalystEB.Ref
		|		LEFT JOIN ParametersOfBudgetTypes AS BudgetProfiles
		|		ON AvailabilityAnalystEB.ConnectionKey = BudgetProfiles.ConnectionKey
		|		AND SettingOfEstimatesOpeningBalance.BudgetBalanceItem = BudgetProfiles.BudgetBalanceItem
		|WHERE
		|	SettingOfEstimatesOpeningBalance.Ref IN(&DocumentsList)
		|
		|ORDER BY
		|	BudgetTypeLineNumber,
		|	BeginOfPeriod,
		|	DocumentNumber
		|TOTALS 
		|	MAX(BudgetFrequency) AS BudgetFrequency
		|BY
		|	BudgetBalanceItem,
		|	BeginOfPeriod";
	Else
		QueryText = QueryText + TMCommonUse.QuerySeparatorInJoin() +
		"SELECT
		|	BudgetEntryForm.BudgetProfile AS BudgetProfile,
		|	BudgetEntryForm.Action AS Action,
		|	&EmptyFieldsByActionType,
		|	BudgetEntryForm.BudgetProfile.Periodicity AS BudgetFrequency,
		|	BudgetEntryForm.Organization AS Organization,
		|	BudgetEntryForm.Department AS Department,
		|	&TextSelection2Analyst,
		|	BudgetEntryForm.Scenario AS Scenario,
		|	BudgetEntryForm.BeginOfPeriod AS BeginOfPeriod,
		|	BudgetEntryForm.Ref AS Document,
		|	BudgetEntryForm.PeriodEnding AS EndOfPeriod,
		|	PRESENTATION(BudgetEntryForm.Ref) AS DocumentPresentation,
		|	BudgetEntryForm.Comment AS Comment,
		|	BudgetEntryForm.Number AS DocumentNumber,
		|	BudgetEntryForm.Date AS DocumentDate,
		|	ISNULL(BudgetProfiles.LineNumber, 999999) AS BudgetTypeLineNumber,
		|	AvailabilityAnalystEB.AvailabilityCompany AS AvailabilityCompany,
		|	AvailabilityAnalystEB.AvailabilityDepartment AS AvailabilityDepartment,
		|	&TextSelection2AvailabilityAnalyst,
		|	AvailabilityAnalystEB.AvailabilityScenario AS AvailabilityScenario
		|FROM
		|	Document.BudgetEntryForm AS BudgetEntryForm
		|		LEFT JOIN AvailabilityAnalystEB AS AvailabilityAnalystEB
		|		ON BudgetEntryForm.Ref = AvailabilityAnalystEB.Ref
		|		LEFT JOIN ParametersOfBudgetTypes AS BudgetProfiles
		|		ON AvailabilityAnalystEB.ConnectionKey = BudgetProfiles.ConnectionKey
		|		AND BudgetEntryForm.BudgetProfile = BudgetProfiles.BudgetProfile
		|		AND BudgetEntryForm.Action = BudgetProfiles.Action
		|WHERE
		|	BudgetEntryForm.Ref IN(&DocumentsList)
		|
		|ORDER BY
		|	BudgetTypeLineNumber,
		|	BeginOfPeriod,
		|	DocumentNumber
		|TOTALS 
		|	MAX(BudgetFrequency) AS BudgetFrequency
		|BY
		|	BudgetProfile,
		|	BeginOfPeriod";
	EndIf;
	
	EmptyFieldsByActionType = New Structure;
	If Not ThisIsInputOfBudgetTurnoverAccordingToCalculationRules Then
		EmptyFieldsByActionType.Insert("CalculationRule",
			"VALUE(Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.EmptyRef)");
	EndIf;
	If Not ThisIsInputOfBalancesOfCalculatedIndicators Then
		EmptyFieldsByActionType.Insert("BudgetBalanceItem",
			"VALUE(Catalog.BudgetBalanceItems.EmptyRef)");
	EndIf;
	If ThisIsInputOfBudgetTurnoverAccordingToCalculationRules Or ThisIsInputOfBalancesOfCalculatedIndicators Then
		EmptyFieldsByActionType.Insert("BudgetProfile", "VALUE(Catalog.BudgetProfiles.EmptyRef)");
		EmptyFieldsByActionType.Insert("Action", "VALUE(Enum.TypesOfBudgetEntryFormActions.EmptyRef)");
	EndIf;
	ArrayOfEmptyFieldsByActionType = New Array;
	For Each KeyAndValue In EmptyFieldsByActionType Do
		ArrayOfEmptyFieldsByActionType.Add(StringFunctionsClientServer.SubstituteParametersToString("%1 AS %2",
			KeyAndValue.Value, KeyAndValue.Key));
	EndDo;
	QueryText = StrReplace(QueryText, "&EmptyFieldsByActionType", StrConcat(ArrayOfEmptyFieldsByActionType,
		"," + Chars.LF + Chars.Tab));
	
	TextListOfEmptyAnalytics = "";
	TextDocumentListAnalyticsSelection = "";
	TextDocumentListAnalyticsGrouping = "";
	TextAvailabilityOfEmptyAnalytics = "";
	TextAvailabilityAnalystEBSampleAvailabilityAnalyst = "";
	TextAvailabilityAnalystEBConnectionAnalyst = "";
	TextDocumentsForSampleAnalyticsIssue = "";
	TextDocumentsForTaskGroupingAnalytics = "";
	TextSelection1Analyst = "";
	TextSelection1AvailabilityAnalyst = "";
	TextSelection1ConnectionListOfAnalyticsDocuments = "";
	TextSelection1ConnectionDocumentsForAnalyticsTask = "";
	TextSelection2Analyst = "";
	TextSelection2AvailabilityAnalyst = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		
		TextListOfEmptyAnalytics = TextListOfEmptyAnalytics + ?(TextListOfEmptyAnalytics = "", "", "," + Chars.LF
			+ Chars.Tab) + StringFunctionsClientServer.SubstituteParametersToString("UNDEFINED AS Dimension%1",
			DimensionNumber);
		
		TextDocumentListAnalyticsSelection = TextDocumentListAnalyticsSelection
			+ ?(TextDocumentListAnalyticsSelection = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetEntryForm.Dimension%1 AS Dimension%1",
				DimensionNumber);
		
		TextDocumentListAnalyticsGrouping = TextDocumentListAnalyticsGrouping
			+ ?(TextDocumentListAnalyticsGrouping = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetEntryForm.Dimension%1",
				DimensionNumber);
		
		TextAvailabilityOfEmptyAnalytics = TextAvailabilityOfEmptyAnalytics + ?(TextAvailabilityOfEmptyAnalytics = "", "", ","
			+ Chars.LF + Chars.Tab) + StringFunctionsClientServer.SubstituteParametersToString(
			"FALSE AS AvailabilityOfAnalytics_%1", DimensionNumber);
		
		TextAvailabilityAnalystEBSampleAvailabilityAnalyst = TextAvailabilityAnalystEBSampleAvailabilityAnalyst
			+ ?(TextAvailabilityAnalystEBSampleAvailabilityAnalyst = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"MAX(ISNULL(BudgetAnalysts.AvailabilityOfAnalytics_%1, FALSE)) AS AvailabilityOfAnalytics_%1",
				DimensionNumber);
		
		TextAvailabilityAnalystEBConnectionAnalyst = TextAvailabilityAnalystEBConnectionAnalyst
			+ ?(TextAvailabilityAnalystEBConnectionAnalyst = "", "",
					Chars.LF + Chars.Tab + Chars.Tab + Chars.Tab + Chars.Tab + "And ")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"(BudgetAnalysts.AvailabilityOfAnalytics_%1
				|				OR BudgetEntryForm.Dimension%1 = BudgetAnalysts.Dimension%1)",
				DimensionNumber);
		
		TextDocumentsForSampleAnalyticsIssue = TextDocumentsForSampleAnalyticsIssue
			+ ?(TextDocumentsForSampleAnalyticsIssue = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetEntryForm.Dimension%1 AS Dimension%1",
				DimensionNumber);
		
		TextDocumentsForTaskGroupingAnalytics = TextDocumentsForTaskGroupingAnalytics
			+ ?(TextDocumentsForTaskGroupingAnalytics = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetEntryForm.Dimension%1",
				DimensionNumber);
		
		TextSelection1Analyst = TextSelection1Analyst
			+ ?(TextSelection1Analyst = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetAnalysts.Dimension%1 AS Dimension%1",
				DimensionNumber);
		
		TextSelection1AvailabilityAnalyst = TextSelection1AvailabilityAnalyst
			+ ?(TextSelection1AvailabilityAnalyst = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetAnalysts.AvailabilityOfAnalytics_%1 AS AvailabilityOfAnalytics_%1",
				DimensionNumber);
		
		TextSelection1ConnectionListOfAnalyticsDocuments = TextSelection1ConnectionListOfAnalyticsDocuments
			+ ?(TextSelection1ConnectionListOfAnalyticsDocuments = "", "",
					Chars.LF + Chars.Tab + Chars.Tab + Chars.Tab + "And ")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"(BudgetAnalysts.Dimension%1 = DocumentsList.Dimension%1)",
				DimensionNumber);
		
		TextSelection1ConnectionDocumentsForAnalyticsTask = TextSelection1ConnectionDocumentsForAnalyticsTask
			+ ?(TextSelection1ConnectionDocumentsForAnalyticsTask = "", "",
					Chars.LF + Chars.Tab + Chars.Tab + Chars.Tab + "And ")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"(BudgetAnalysts.Dimension%1 = DocumentsByTask.Dimension%1)",
				DimensionNumber);
		
		TextSelection2Analyst = TextSelection2Analyst
			+ ?(TextSelection2Analyst = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetEntryForm.Dimension%1",
				DimensionNumber);
		
		TextSelection2AvailabilityAnalyst = TextSelection2AvailabilityAnalyst
			+ ?(TextSelection2AvailabilityAnalyst = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"AvailabilityAnalystEB.AvailabilityOfAnalytics_%1",
				DimensionNumber);
		
	EndDo;
	QueryText = StrReplace(QueryText, "&TextListOfEmptyAnalytics", TextListOfEmptyAnalytics);
	QueryText = StrReplace(QueryText, "&TextDocumentListAnalyticsSelection",
		TextDocumentListAnalyticsSelection);
	QueryText = StrReplace(QueryText, "&TextDocumentListAnalyticsGrouping",
		TextDocumentListAnalyticsGrouping);
	QueryText = StrReplace(QueryText, "&TextAvailabilityOfEmptyAnalytics", TextAvailabilityOfEmptyAnalytics);
	QueryText = StrReplace(QueryText, "&TextAvailabilityAnalystEBSampleAvailabilityAnalyst",
		TextAvailabilityAnalystEBSampleAvailabilityAnalyst);
	QueryText = StrReplace(QueryText, "&TextAvailabilityAnalystEBConnectionAnalyst",
		TextAvailabilityAnalystEBConnectionAnalyst);
	QueryText = StrReplace(QueryText, "&TextDocumentsForSampleAnalyticsIssue",
		TextDocumentsForSampleAnalyticsIssue);
	QueryText = StrReplace(QueryText, "&TextDocumentsForTaskGroupingAnalytics",
		TextDocumentsForTaskGroupingAnalytics);
	QueryText = StrReplace(QueryText, "&TextSelection1Analyst", TextSelection1Analyst);
	QueryText = StrReplace(QueryText, "&TextSelection1AvailabilityAnalyst", TextSelection1AvailabilityAnalyst);
	QueryText = StrReplace(QueryText, "&TextSelection1ConnectionListOfAnalyticsDocuments",
		TextSelection1ConnectionListOfAnalyticsDocuments);
	QueryText = StrReplace(QueryText, "&TextSelection1ConnectionDocumentsForAnalyticsTask",
		TextSelection1ConnectionDocumentsForAnalyticsTask);
	QueryText = StrReplace(QueryText, "&TextSelection2Analyst", TextSelection2Analyst);
	QueryText = StrReplace(QueryText, "&TextSelection2AvailabilityAnalyst", TextSelection2AvailabilityAnalyst);
	
	QueryTexts.Add(QueryText);
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	
	Query.SetParameter("BudgetProfiles", BudgetProfiles);
	Query.SetParameter("AnalysisOfFillingBudgets",  BudgetPopulationDimension);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("WorkScheduleCalendar", Schedule);
	Query.SetParameter("DocumentsList", DocumentsList);
	Query.SetParameter("AllDocuments", AllDocuments);
	Query.SetParameter("CreateCommand", NStr("vi = 'Tạo mới';
											|ru = 'Создать';
											|en = 'Create'; fa = 'ایجاد';
											|it = 'Creare';
											|pl = 'Create';
											|tr = 'Oluştur'"));
	If ThisIsInputOfBalancesOfCalculatedIndicators Then
		OrderedPeriodicities = BudgetReportingClientServer.OrderedPeriodicities();
		MinimumTimeFenceForEnteringBalances = Enums.Periodicity.Month;
		If OrderedPeriodicities.Find(PeriodicityOfStage) >= OrderedPeriodicities.Find(MinimumTimeFenceForEnteringBalances) Then
			Query.SetParameter("Periodicity", PeriodicityOfStage);
		Else
			Query.SetParameter("Periodicity", MinimumTimeFenceForEnteringBalances);
		EndIf;
	EndIf;
	
	ExecutionResults = Query.ExecuteBatch();
	NumberOfBudgetTypeParameterEntries = ExecutionResults[1].Unload()[0].Count;
	NumberOfCalendarChartEntries = ExecutionResults[3].Unload()[0].Count;
	If CorrectActionSettings
		And NumberOfBudgetTypeParameterEntries = 0 Then
		CorrectActionSettings = False;
		
		Common.MessageToUser(NStr("vi = 'Cài đặt hành động không hợp lệ.';
									|ru = 'Неверные настройки действия.';
									|en = 'Incorrect action settings.'; fa = 'Incorrect action settings.';
									|it = 'Impostazioni dell''azione non valide.';
									|pl = 'Nieprawidłowe ustawienia akcji.';
									|tr = 'Geçersiz eylem ayarları.'"));
		
		LanguageCode = Common.DefaultLanguageCode();
		MessageText   = NStr("vi = 'Cài đặt hành động không hợp lệ. Tạo một nhiệm vụ là không thể';
							|ru = 'Неверные настройки действия. Создание задачи не возможно';
							|en = 'Invalid action settings. Unable to create the task'; fa = 'Invalid action settings. Unable to create the task';
							|it = 'Impostazioni dell''azione non valide. Impossibile creare un obiettivo';
							|pl = 'Nieprawidłowe ustawienia działania. Tworzenie zadania jest niemożliwe';
							|tr = 'Geçersiz eylem ayarları. Görev oluşturmak mümkün değil'");
		TextOfMessageLR = NStr("vi = 'Cài đặt hành động không hợp lệ. Không thể tạo nhiệm vụ';
								|ru = 'Неверные настройки действия. Создание задачи не возможно';
								|en = 'Invalid action settings. Unable to create the task'; fa = 'Invalid action settings. Unable to create the task';
								|it = 'Impostazioni dell''azione non valide. Impossibile creare un obiettivo';
								|pl = 'Nieprawidłowe ustawienia działania. Tworzenie zadania jest niemożliwe';
								|tr = 'Geçersiz eylem ayarları. Görev oluşturmak mümkün değil'", LanguageCode);
		
		WriteLogEvent(
			NStr("vi = 'Tạo nhiệm vụ ngân sách';
				|ru = 'Создание бюджетных задач';
				|en = 'Create budget tasks'; fa = 'Create budget tasks';
				|it = 'Creazione degli obiettivi di budget';
				|pl = 'Tworzenie zadań budżetowych';
				|tr = 'Bütçe görevi oluştur'", LanguageCode),
			EventLogLevel.Error,
			Metadata.Tasks.BudgetTask,,
			TextOfMessageLR);
			
		Raise MessageText;
	EndIf;
	If CorrectActionSettings And NumberOfCalendarChartEntries = 0 Then
		LanguageCode = Common.DefaultLanguageCode();
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lịch trình %1 không được lên kế hoạch cho giai đoạn từ %2 đến %3. Không thể tạo nhiệm vụ';
				|ru = 'Календарный график %1 не запланирован за период с %2 по %3. Создание задач не возможно';
				|en = 'Calendar schedule %1 is not planned from %2 to %3. Cannot create tasks'; fa = 'Calendar schedule %1 is not planned from %2 to %3. Cannot create tasks';
				|it = 'Il grafico di calendario %1 non è pianificato per il periodo dal %2 al %3. Impossibile creare gli obiettivi';
				|pl = 'Harmonogram kalendarzowy %1 nie jest zaplanowany na okres od %2 do %3. Tworzenie zadań nie jest możliwe';
				|tr = 'Takvim programı %1 %2 tarihinden %3 tarihine kadarki dönem için programlanmadı.'"),
			Schedule,
			Format(BeginOfPeriod, "DLF=D"),
			Format(EndOfPeriod, "DLF=D"));
		TextOfMessageLR = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lịch trình %1 không được lên kế hoạch cho giai đoạn từ %2 đến %3. Không thể tạo nhiệm vụ';
				|ru = 'Календарный график %1 не запланирован за период с %2 по %3. Создание задач не возможно';
				|en = 'Calendar schedule %1 is not planned from %2 to %3. Cannot create tasks'; fa = 'Calendar schedule %1 is not planned from %2 to %3. Cannot create tasks';
				|it = 'Il grafico di calendario %1 non è pianificato per il periodo dal %2 al %3. Impossibile creare gli obiettivi';
				|pl = 'Harmonogram kalendarzowy %1 nie jest zaplanowany na okres od %2 do %3. Tworzenie zadań nie jest możliwe';
				|tr = 'Takvim programı %1 %2 tarihinden %3 tarihine kadarki dönem için programlanmadı.'", LanguageCode),
			Schedule,
			Format(BeginOfPeriod, "DLF=D"),
			Format(EndOfPeriod, "DLF=D"));
		
		WriteLogEvent(
			NStr("vi = 'Tạo nhiệm vụ ngân sách';
				|ru = 'Создание бюджетных задач';
				|en = 'Create budget tasks'; fa = 'Create budget tasks';
				|it = 'Creazione degli obiettivi di budget';
				|pl = 'Tworzenie zadań budżetowych';
				|tr = 'Bütçe görevi oluştur'", LanguageCode),
			EventLogLevel.Error,
			Metadata.Tasks.BudgetTask,,
			TextOfMessageLR);
			
		Raise MessageText;
	EndIf;
	Result = ExecutionResults[ExecutionResults.Count()-1].Unload(
				QueryResultIteration.ByGroupsWithHierarchy); // ValueTree
	
	If Not DesignResult Then
		Return Result;
	EndIf;
		
	BudgetEntryTree = Result.Copy();
	BudgetEntryTree.Rows.Clear();
	BudgetEntryTree.Columns.Add("TypeOfBudgetAnalytics",New TypeDescription("String"));
	BudgetEntryTree.Columns.Add("Periodicity", New TypeDescription("EnumRef.Periodicity"));
	
	For Each BudgetViewLine In Result.Rows Do
		
		BudgetFrequency = BudgetViewLine.BudgetFrequency;
		TreeItems = BudgetEntryTree.Rows;
		NewRow = TreeItems.Add();
		If ThisIsInputOfBudgetTurnoverAccordingToCalculationRules Then
			NewRow.TypeOfBudgetAnalytics = String(BudgetViewLine.CalculationRule);
		ElsIf ThisIsInputOfBalancesOfCalculatedIndicators Then
			NewRow.TypeOfBudgetAnalytics = String(BudgetViewLine.BudgetBalanceItem);
		Else
			NewRow.TypeOfBudgetAnalytics = String(BudgetViewLine.BudgetProfile);
		EndIf;
		FillPropertyValues(NewRow,BudgetViewLine);
		NewRow.Periodicity = BudgetFrequency;
		RowsPeriod = BudgetViewLine.Rows;
		
		If Not ValueIsFilled(BudgetFrequency) Then
			Continue;
		EndIf;
		
		If  Not Enums.Periodicity.IndexOf(BudgetFrequency) < Enums.Periodicity.IndexOf(PeriodicityOfStage) Then
			AnalyticsLines = RowsPeriod[0].Rows; 
			If  AnalyticsLines.Count() = 1 Then
				FillPropertyValues(NewRow,AnalyticsLines[0]);
				If ValueIsFilled(NewRow.Document) Then
					NewRow.DocumentPresentation = NewRow.DocumentNumber + " " + NewRow.DocumentDate;
				EndIf;
			Else
				For Each AnalyticsLine In AnalyticsLines Do
					BudgetLine = NewRow.Rows.Add();
					BudgetLine.TypeOfBudgetAnalytics = DocumentTreeRowAnalystPresentation(AnalyticsLine);
					FillPropertyValues(BudgetLine,AnalyticsLine);
					If ValueIsFilled(BudgetLine.Document) Then
						BudgetLine.DocumentPresentation = BudgetLine.DocumentNumber + " " + BudgetLine.DocumentDate;
					EndIf;
				EndDo;
			EndIf;
		Else
			For Each StringPeriod In RowsPeriod Do
				BudgetLine = NewRow.Rows.Add();
				BudgetLine.TypeOfBudgetAnalytics = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(StringPeriod.BeginOfPeriod, BudgetFrequency);
				FillPropertyValues(BudgetLine,StringPeriod);
				BudgetLine.Periodicity = StringPeriod.BudgetFrequency;
				If StringPeriod.Rows.Count() = 1 Then
					FillPropertyValues(BudgetLine,StringPeriod.Rows[0]);
					If ValueIsFilled(BudgetLine.Document) Then
						BudgetLine.DocumentPresentation = BudgetLine.DocumentNumber + " " + BudgetLine.DocumentDate;
					EndIf;
				Else
					For Each AnalyticsLine In StringPeriod.Rows Do
						BudgetLine1 = BudgetLine.Rows.Add();
						BudgetLine1.TypeOfBudgetAnalytics = DocumentTreeRowAnalystPresentation(AnalyticsLine);
						FillPropertyValues(BudgetLine1,AnalyticsLine);
						If ValueIsFilled(BudgetLine1.Document) Then
							BudgetLine1.DocumentPresentation = BudgetLine1.DocumentNumber + " " + BudgetLine1.DocumentDate;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	
	EndDo;
	
	Return BudgetEntryTree;
	
EndFunction

// Creates budget Instance documents in accordance with the action settings.
//
// Parameters:
//  NewDocumentParameters - Structure - Parameters for filling in the document object:
//   * Period - Date -
//   * BudgetingModel - CatalogRef.BudgetingModels - 
//   * BudgetingStep - CatalogRef.BudgetingSteps - 
//  SettingOfAction        - ValueTable, ValueTree - document creation settings.
//  Post - Boolean -
//  DonTCheckExistingDocuments - Boolean -
//
// Returns:
//  Array of DocumentRef.BudgetEntryForm -
Function GenerateBudgetsBasedOnActionSettings(NewDocumentParameters, Val SettingOfAction, Post = False, DonTCheckExistingDocuments = False) Export
	
	SharedArrayOfDocuments = New Array();
	
	If TypeOf(SettingOfAction) = Type("ValueTree") Then
		BudgetEntryTree = SettingOfAction;
	Else
		DocumentPeriod_ = NewDocumentParameters.Period;
		If Not ValueIsFilled(DocumentPeriod_) Then
			DocumentPeriod_ = CurrentSessionDate();
		EndIf;
		
		Attributes = New Structure("Periodicity, Action", "Parent.Periodicity");
		Attributes = Common.ObjectAttributesValues(NewDocumentParameters.BudgetingStep, Attributes);
		Periodicity = Attributes.Periodicity;
		
		BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(DocumentPeriod_, Periodicity);
		EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(DocumentPeriod_, Periodicity);
		
		BudgetEntryTree = ParametersForEnteringBudgetsByActionSettings(SettingOfAction, Attributes.Action,
		                                                                 BeginOfPeriod,
		                                                                 EndOfPeriod,
		                                                                 Periodicity);
	EndIf;
	
	If BudgetEntryTree = Undefined Then
		Return  SharedArrayOfDocuments;
	EndIf;
	
	Action = Common.ObjectAttributeValue(NewDocumentParameters.BudgetingStep, "Action");
	
	TotalRowsProcessed = NumberOfBudgetTreeRowsProcessed(BudgetEntryTree);
	
	LinesBudgetView = BudgetEntryTree.Rows;
	
	ProcessedRows_ = 0;
	PreviousProgress = 0;
	
	For Each BudgetViewLine In LinesBudgetView Do 
		
		If BudgetViewLine.Rows.Count() > 0 Then
			PeriodAnalysisLines = BudgetViewLine.Rows;
			For Each PeriodAnalyticsLine In PeriodAnalysisLines Do
				If PeriodAnalyticsLine.Rows.Count() > 0 Then
					For Each PeriodAnalyticsLine1 In PeriodAnalyticsLine.Rows Do
						If ValueIsFilled(PeriodAnalyticsLine1.Document) Then 
							SharedArrayOfDocuments.Add(PeriodAnalyticsLine1.Document);
							Continue; 
						EndIf;
						If Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules Then
							//@skip-check query-in-loop
							ArrayDocuments = CreateBudgetTurnoverLogger(NewDocumentParameters, 
								ActionStringParameters(PeriodAnalyticsLine1,BudgetEntryTree.Columns), DonTCheckExistingDocuments);
						ElsIf Action = Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
							//@skip-check query-in-loop
							ArrayDocuments = CreateInstallationOfOpeningBalancesOfCalculatedIndicators(NewDocumentParameters, 
								ActionStringParameters(PeriodAnalyticsLine1,BudgetEntryTree.Columns), False,
								DonTCheckExistingDocuments);
						Else
							//@skip-check query-in-loop
							ArrayDocuments = CreateBudgetEntryDocument(NewDocumentParameters, 
								ActionStringParameters(PeriodAnalyticsLine1,BudgetEntryTree.Columns), True,
								DonTCheckExistingDocuments);
						EndIf;
						If ArrayDocuments <> Undefined Then
							SharedArrayOfDocuments.Add(ArrayDocuments[ArrayDocuments.Count() - 1]);
						EndIf;
						ReportProgress(ProcessedRows_, TotalRowsProcessed, PreviousProgress);
					EndDo;
				Else
					If ValueIsFilled(PeriodAnalyticsLine.Document) Then
						SharedArrayOfDocuments.Add(PeriodAnalyticsLine.Document);
						Continue; 
					EndIf;
					If Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules Then
						//@skip-check query-in-loop
						ArrayDocuments = CreateBudgetTurnoverLogger(NewDocumentParameters, 
							ActionStringParameters(PeriodAnalyticsLine,BudgetEntryTree.Columns), DonTCheckExistingDocuments);
					ElsIf Action = Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
						//@skip-check query-in-loop
						ArrayDocuments = CreateInstallationOfOpeningBalancesOfCalculatedIndicators(NewDocumentParameters, 
							ActionStringParameters(PeriodAnalyticsLine,BudgetEntryTree.Columns), False,
							DonTCheckExistingDocuments);
					Else
						//@skip-check query-in-loop
						ArrayDocuments = CreateBudgetEntryDocument(NewDocumentParameters, 
							ActionStringParameters(PeriodAnalyticsLine,BudgetEntryTree.Columns), True,
							DonTCheckExistingDocuments);
					EndIf;
					If ArrayDocuments <> Undefined Then
						SharedArrayOfDocuments.Add(ArrayDocuments[ArrayDocuments.Count() - 1]);
					EndIf;
					ReportProgress(ProcessedRows_, TotalRowsProcessed, PreviousProgress);
				EndIf;
			EndDo;
		Else
			If ValueIsFilled(BudgetViewLine.Document) Then 
				SharedArrayOfDocuments.Add(BudgetViewLine.Document);
				Continue; 
			EndIf;
			If Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules Then
				//@skip-check query-in-loop
				ArrayDocuments = CreateBudgetTurnoverLogger(NewDocumentParameters,
					ActionStringParameters(BudgetViewLine,BudgetEntryTree.Columns), DonTCheckExistingDocuments);
			ElsIf Action = Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
				//@skip-check query-in-loop
				ArrayDocuments = CreateInstallationOfOpeningBalancesOfCalculatedIndicators(NewDocumentParameters,
					ActionStringParameters(BudgetViewLine,BudgetEntryTree.Columns), False, DonTCheckExistingDocuments);
			Else
				//@skip-check query-in-loop
				ArrayDocuments = CreateBudgetEntryDocument(NewDocumentParameters,
					ActionStringParameters(BudgetViewLine,BudgetEntryTree.Columns), True, DonTCheckExistingDocuments);
			EndIf;
			If ArrayDocuments <> Undefined Then
				SharedArrayOfDocuments.Add(ArrayDocuments[ArrayDocuments.Count() - 1]);
			EndIf;
			ReportProgress(ProcessedRows_, TotalRowsProcessed, PreviousProgress);
		EndIf;
	
	EndDo;
	
	SharedArrayOfDocuments = CommonClientServer.CollapseArray(SharedArrayOfDocuments);
	
	Return SharedArrayOfDocuments;
	
EndFunction

Procedure ReportProgress(ProcessedRows_, TotalRowsProcessed, PreviousProgress)
	
	ProcessedRows_ = ProcessedRows_ + 1;
	ProgressPercent = Int((ProcessedRows_ / TotalRowsProcessed) * 100);
	If ProgressPercent <> PreviousProgress Then
		TimeConsumingOperations.ReportProgress(ProgressPercent);
		PreviousProgress = ProgressPercent;
	EndIf;

EndProcedure

#EndRegion

#Region Private

// LongDesc
// 
// Parameters:
// 	BudgetingModel - CatalogRef.BudgetingModels - 
// 	BudgetingProcess - Undefined, DocumentRef.BudgetingProcess -
// 	CreatedTasks - Undefined, ValueTable - LongDesc:
// * Model - CatalogRef.BudgetingModels -
// * Period - Date -
// * Stage - CatalogRef.BudgetingSteps -
// * Process_ - DocumentRef.BudgetingProcess -
// * Task - TaskRef.BudgetTask -
Procedure CreateBudgetTasksBasedOnModel(BudgetingModel, BudgetingProcess = Undefined, CreatedTasks = Undefined)
	
	GroupOfProcessSteps = Undefined;
	If ValueIsFilled(BudgetingProcess) Then
		GroupOfProcessSteps = Common.ObjectAttributeValue(BudgetingProcess, "StepGroup");
	EndIf;
	TaskTable_ = Catalogs.BudgetingModels.GetBudgetIssues(BudgetingModel, GroupOfProcessSteps,
		Undefined, CurrentSessionDate(), True, True);
	TaskRelationshipTable = Catalogs.BudgetingModels.TaskRelationships(TaskTable_);
	
	Query = New Query();
	Manager = New TempTablesManager;
	Query.TempTablesManager = Manager;
	Query.SetParameter("TaskTable_", TaskTable_);
	Query.SetParameter("TaskRelationshipTable", TaskRelationshipTable);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("GenerateIssuesAutomatically", 
						Common.ObjectAttributeValue(BudgetingModel, "AutomaticallyGenerateTasks"));
	Query.SetParameter("BudgetingProcess",BudgetingProcess);
	
	QueryText = 
	"SELECT
		|	Table_.TaskNumber,
		|	Table_.BudgetingStep,
		|	Table_.BudgetingStepBasis,
		|	Table_.BudgetingProcess,
		|	Table_.Period,
		|	Table_.TaskExecuted,
		|	Table_.Task,
		|	CASE
		|		WHEN Table_.Task <> VALUE(Task.BudgetTask.EmptyRef)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS IssueGenerated,
		|	Table_.StartDate,
		|	Table_.EndDateFact
		|INTO TaskTable_
		|FROM
		|	&TaskTable_ AS Table_
		|WHERE
		|	(&GenerateIssuesAutomatically = TRUE
		|			OR Table_.BudgetingProcess <> VALUE(Document.BudgetingProcess.EmptyRef))
		|	AND (&BudgetingProcess = UNDEFINED
		|			OR Table_.BudgetingProcess = &BudgetingProcess)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table_.Task,
		|	Table_.PreviousTask
		|INTO LinkTable
		|FROM
		|	&TaskRelationshipTable AS Table_
		|WHERE
		|	Table_.PreviousTask <> 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TaskTable_.BudgetingStep,
		|	TaskTable_.BudgetingStepBasis,
		|	TaskTable_.BudgetingProcess,
		|	MAX(TaskTable_.Period) AS Period
		|INTO MaximumPeriodsOfCompletedTasks
		|FROM
		|	TaskTable_ AS TaskTable_
		|WHERE
		|	TaskTable_.IssueGenerated
		|	AND TaskTable_.TaskExecuted
		|
		|GROUP BY
		|	TaskTable_.BudgetingStep,
		|	TaskTable_.BudgetingStepBasis,
		|	TaskTable_.BudgetingProcess
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TaskTable_.TaskNumber,
		|	TaskTable_.BudgetingStep,
		|	TaskTable_.BudgetingStepBasis,
		|	TaskTable_.BudgetingProcess,
		|	TaskTable_.Period,
		|	TaskTable_.TaskExecuted,
		|	TaskTable_.Task,
		|	TaskTable_.IssueGenerated,
		|	TaskTable_.StartDate
		|INTO PeriodsFollowingExecution
		|FROM
		|	TaskTable_ AS TaskTable_
		|		LEFT JOIN MaximumPeriodsOfCompletedTasks AS MaximumPeriodsOfCompletedTasks
		|		ON TaskTable_.BudgetingStep = MaximumPeriodsOfCompletedTasks.BudgetingStep
		|			AND TaskTable_.BudgetingStepBasis = MaximumPeriodsOfCompletedTasks.BudgetingStepBasis
		|			AND TaskTable_.BudgetingProcess = MaximumPeriodsOfCompletedTasks.BudgetingProcess
		|WHERE
		|	TaskTable_.Period > ISNULL(MaximumPeriodsOfCompletedTasks.Period, DATETIME(1, 1, 1))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PeriodsFollowingExecution.TaskNumber,
		|	PeriodsFollowingExecution.Period,
		|	PeriodsFollowingExecution.BudgetingStep,
		|	PeriodsFollowingExecution.BudgetingStepBasis,
		|	PeriodsFollowingExecution.BudgetingProcess
		|INTO TasksForFormation
		|FROM
		|	PeriodsFollowingExecution AS PeriodsFollowingExecution
		|WHERE
		|	NOT (PeriodsFollowingExecution.BudgetingStep, PeriodsFollowingExecution.BudgetingStepBasis, PeriodsFollowingExecution.BudgetingProcess) IN
		|				(SELECT
		|					Filter.BudgetingStep,
		|					Filter.BudgetingStepBasis,
		|					Filter.BudgetingProcess
		|				FROM
		|					PeriodsFollowingExecution AS Filter
		|				WHERE
		|					Filter.IssueGenerated)
		|	AND NOT (PeriodsFollowingExecution.BudgetingStep, PeriodsFollowingExecution.BudgetingStepBasis, PeriodsFollowingExecution.BudgetingProcess) IN
		|				(SELECT
		|					Filter.BudgetingStep,
		|					Filter.BudgetingStepBasis,
		|					VALUE(Document.BudgetingProcess.EmptyRef)
		|				FROM
		|					PeriodsFollowingExecution AS Filter
		|				WHERE
		|					Filter.IssueGenerated)
		|	AND PeriodsFollowingExecution.StartDate <= &CurrentDate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TasksForFormation.BudgetingStep AS BudgetingStep,
		|	TasksForFormation.BudgetingStepBasis,
		|	TasksForFormation.BudgetingProcess,
		|	MIN(TasksForFormation.Period) AS Period
		|INTO Filter
		|FROM
		|	TasksForFormation AS TasksForFormation
		|
		|GROUP BY
		|	TasksForFormation.BudgetingStep,
		|	TasksForFormation.BudgetingStepBasis,
		|	TasksForFormation.BudgetingProcess
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TasksForFormation.TaskNumber
		|INTO TasksForFormationMinimumPeriod
		|FROM
		|	TasksForFormation AS TasksForFormation
		|		INNER JOIN Filter AS Filter
		|		ON TasksForFormation.BudgetingStep = Filter.BudgetingStep
		|			AND TasksForFormation.BudgetingStepBasis = Filter.BudgetingStepBasis
		|			AND TasksForFormation.BudgetingProcess = Filter.BudgetingProcess
		|			AND TasksForFormation.Period = Filter.Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TasksForFormation.TaskNumber,
		|	LinkTable.PreviousTask,
		|	TaskTable_.EndDateFact
		|INTO NumberOfPreviousTasks
		|FROM
		|	TasksForFormationMinimumPeriod AS TasksForFormation
		|		LEFT JOIN LinkTable AS LinkTable
		|		ON TasksForFormation.TaskNumber = LinkTable.Task
		|		LEFT JOIN TaskTable_ AS TaskTable_
		|		ON (LinkTable.PreviousTask = TaskTable_.TaskNumber)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NumberOfPreviousTasks.TaskNumber,
		|	MAX(TaskTable_.EndDateFact) AS EndDateFact
		|INTO TasksWithAndWithoutProcesses
		|FROM
		|	NumberOfPreviousTasks AS NumberOfPreviousTasks
		|		LEFT JOIN TaskTable_ AS TaskTable_
		|		ON NumberOfPreviousTasks.PreviousTask = TaskTable_.TaskNumber
		|
		|GROUP BY
		|	NumberOfPreviousTasks.TaskNumber
		|
		|HAVING
		|	MIN(ISNULL(TaskTable_.TaskExecuted, TRUE)) = TRUE";
	// Explanation of the condition: 
	// MINIMUM - in case only one of the tasks of the parallel group is completed
	// THE TRUTH is NULL - in case the task has no previous tasks.
	
	Separator = "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	SelectionText = 
	"SELECT
		|	TasksWithProcesses.TaskNumber AS TaskNumber,
		|	TasksWithProcesses.EndDateFact AS EndDateFact
		|FROM
		|	TasksWithAndWithoutProcesses AS TasksWithProcesses
		|		INNER JOIN TaskTable_ AS TaskTable_
		|		ON TasksWithProcesses.TaskNumber = TaskTable_.TaskNumber
		|			AND (NOT TaskTable_.BudgetingProcess = VALUE(Document.BudgetingProcess.EmptyRef))
		|
		|UNION ALL
		|
		|SELECT
		|	TasksWithoutProcesses.TaskNumber,
		|	TasksWithoutProcesses.EndDateFact
		|FROM
		|	TasksWithAndWithoutProcesses AS TasksWithoutProcesses
		|		INNER JOIN TaskTable_ AS TaskTable_
		|		ON TasksWithoutProcesses.TaskNumber = TaskTable_.TaskNumber
		|			AND (TaskTable_.BudgetingProcess = VALUE(Document.BudgetingProcess.EmptyRef))
		|		LEFT JOIN TaskTable_ AS DuplicatesOfTasksWithProcesses
		|		ON (NOT TaskTable_.TaskNumber = DuplicatesOfTasksWithProcesses.TaskNumber)
		|			AND (TaskTable_.BudgetingStep = DuplicatesOfTasksWithProcesses.BudgetingStep)
		|			AND (TaskTable_.BudgetingStepBasis = DuplicatesOfTasksWithProcesses.BudgetingStepBasis)
		|			AND (TaskTable_.Period = DuplicatesOfTasksWithProcesses.Period)
		|			AND (TaskTable_.StartDate = DuplicatesOfTasksWithProcesses.StartDate)
		|			AND (TaskTable_.EndDateFact = DuplicatesOfTasksWithProcesses.EndDateFact)
		|WHERE
		|	DuplicatesOfTasksWithProcesses.TaskNumber IS NULL";
	
	QueryTexts = New Array;
	QueryTexts.Add(QueryText);
	QueryTexts.Add(SelectionText);
	Query.Text = StrConcat(QueryTexts, Separator);
	
	If CreatedTasks = Undefined Then
		CreatedTasks = New ValueTable;
		CreatedTasks.Columns.Add("Model",  New TypeDescription("CatalogRef.BudgetingModels"));
		CreatedTasks.Columns.Add("Period",  New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date)));
		CreatedTasks.Columns.Add("Stage",    New TypeDescription("CatalogRef.BudgetingSteps"));
		CreatedTasks.Columns.Add("Process_", New TypeDescription("DocumentRef.BudgetingProcess"));
		CreatedTasks.Columns.Add("Task",  New TypeDescription("TaskRef.BudgetTask"));
	EndIf;
	
	ArrayOfStages = TaskTable_.UnloadColumn("BudgetingStep");
	CommonClientServer.SupplementArray(ArrayOfStages, TaskTable_.UnloadColumn("BudgetingStepBasis"), True);
	ArrayOfStages = CommonClientServer.CollapseArray(ArrayOfStages);
	
	MatchingFlags = Common.ObjectsAttributesValues(ArrayOfStages, "ExecuteAutomatically, SettingOfAction");
	
	ArrayOfProcesses = TaskTable_.UnloadColumn("BudgetingProcess");
	ArrayOfProcesses = CommonClientServer.CollapseArray(ArrayOfProcesses);
	DescriptionExtensionParameters = Common.ObjectsAttributesValues(ArrayOfProcesses, "EmployeeResponsible, AdditionToDescription, Date");
	
	ThereAreAutoRunningTasks = False;
	NumberOfTasksToGenerate = Query.Execute().Unload();
	For Each TaskForFormation In NumberOfTasksToGenerate Do
		TaskLine = TaskTable_.Find(TaskForFormation.TaskNumber, "TaskNumber");
		TaskObject = Tasks.BudgetTask.CreateTask();
		
		TaskObject.SetNewNumber();
		TaskObject.AdditionalProperties.Insert("TaskTable_", TaskTable_);
		TaskObject.Period = TaskLine.Period;
		If ValueIsFilled(TaskLine.BudgetingStepBasis) Then
			ExecuteAutomatically = MatchingFlags[TaskLine.BudgetingStepBasis].ExecuteAutomatically;
			TaskObject.Fill(TaskLine.BudgetingStepBasis);
			SettingUpMainStageAction = MatchingFlags[TaskLine.BudgetingStep].SettingOfAction; // ValueStorage
			SettingUpMainStage = SettingUpMainStageAction.Get();
			SettingUpStageAction = MatchingFlags[TaskLine.BudgetingStepBasis].SettingOfAction; // ValueStorage
			StageSetup = SettingUpStageAction.Get();
			For Each MainStageLine In SettingUpMainStage Do
				FoundRow = StageSetup.Find(MainStageLine.Name, "Name");
				If FoundRow <> Undefined Then
					FoundRow.Value = MainStageLine.Value;
				EndIf;
			EndDo;
			TaskObject.SettingOfAction = New ValueStorage(StageSetup);
		Else
			ExecuteAutomatically = MatchingFlags[TaskLine.BudgetingStep].ExecuteAutomatically;
			TaskObject.Fill(TaskLine.BudgetingStep);
		EndIf;
		
		TaskObject.Performer = TaskLine.Performer;
		
		TaskObject.BudgetingStep = TaskLine.BudgetingStep;
		TaskObject.BudgetingStepBasis = TaskLine.BudgetingStepBasis;
		TaskObject.BudgetingProcess = TaskLine.BudgetingProcess;
		
		If ValueIsFilled(TaskObject.BudgetingProcess) Then
			StructureAdditionToDescription = DescriptionExtensionParameters[TaskObject.BudgetingProcess];
			If ValueIsFilled(StructureAdditionToDescription.AdditionToDescription) Then
				If ValueIsFilled(TaskObject.TaskDetails1) Then
					Postfix = TaskObject.TaskDetails1;
				EndIf;
				TaskObject.TaskDetails1 = String(StructureAdditionToDescription.Date) + ", " + StructureAdditionToDescription.EmployeeResponsible + ":" + Chars.LF;
				TaskObject.TaskDetails1 = TaskObject.TaskDetails1 + TrimAll(StructureAdditionToDescription.AdditionToDescription) + Chars.LF + Chars.LF;
				TaskObject.TaskDetails1 = TaskObject.TaskDetails1 + Postfix;
			EndIf;
		EndIf;
		
		If Not ExecuteAutomatically Then
			If Not ValueIsFilled(TaskForFormation.EndDateFact) Then
				TaskObject.Date = TaskLine.StartDate;
			Else
				TaskObject.Date = Max(TaskForFormation.EndDateFact + 1, TaskLine.StartDate);
			EndIf;
			SetTaskDuration(TaskObject, TaskLine.BudgetingStep);
		Else
			CurrentSessionDate = CurrentSessionDate();
			
			TaskObject.Date = CurrentSessionDate;
			TaskObject.TaskDueDate = CurrentSessionDate;
		EndIf;
		
		If Tasks.BudgetTask.YouNeedToCreateNewDocument(Undefined, TaskObject.Action, False) Then
			
			ArrayDocuments = Undefined;
			
			If TaskObject.Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm
				Or TaskObject.Action
				= Enums.TypesOfBudgetingStepActions.AdjustCorrectBudgets
				Or TaskObject.Action
				= Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules Then
				TaskObject.ForDocumentCreation = True;
			ElsIf TaskObject.Action
				= Enums.TypesOfBudgetingStepActions.SetValuesForNonFinancialItems Then
				TaskObject.ForDocumentCreation = True;
			ElsIf TaskObject.Action
				= Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
				TaskObject.ForDocumentCreation = True;
			EndIf;
			
			If ArrayDocuments <> Undefined Then
				If TypeOf(ArrayDocuments) <> Type("Array") Then
					ArrayDocuments = CommonClientServer.ValueInArray(ArrayDocuments);
				EndIf;
				CommonClientServer.SupplementTableFromArray(TaskObject.DocumentsList, ArrayDocuments, "Document");
			EndIf;
			
		EndIf;
		
		TaskObject.AdditionalProperties.Insert("TaskGenerationMode");
		
		If ExecuteAutomatically
		   And Not TaskObject.ForDocumentCreation Then
			TaskObject.Executed = True;
		EndIf;
		
		TaskObject.Write();
		
		If TaskObject.ForDocumentCreation Then
			RecordOfCreatedTask         = CreatedTasks.Add();
			RecordOfCreatedTask.Model  = TaskObject.BudgetingModel;
			RecordOfCreatedTask.Period  = TaskObject.Period;
			RecordOfCreatedTask.Stage    = TaskObject.BudgetingStep;
			RecordOfCreatedTask.Process_ = TaskObject.BudgetingProcess;
			RecordOfCreatedTask.Task  = TaskObject.Ref;
		EndIf;
		
		If ExecuteAutomatically
		   And TaskObject.Executed Then
			
			ThereAreAutoRunningTasks = True;
		EndIf;
		
	EndDo;
	
	If ThereAreAutoRunningTasks Then
		CreateBudgetTasksBasedOnModel(BudgetingModel,BudgetingProcess,CreatedTasks);
	EndIf;
	
EndProcedure

// Returns Whether the background task for creating documents for the task is currently running
// For the file version, it will return False for users with incomplete permissions.
//
// Parameters:
//	Process_ - DocumentRef.BudgetingProcess - process, task details.
//
// Returns:
//	Boolean - True if the background task with the passed key is executed.
//
Function BackgroundJobForCreatingDocumentsIsRunning(Process_) Export
	SetPrivilegedMode(True);
	
	BackgroundJobRunning_ = False;
	
	Var_Key = BackgroundTaskKeyForCreatingDocumentsForBudgetTasks(Process_);
	Search = New Structure("Key, State", Var_Key, BackgroundJobState.Active);
	TasksInProgress = BackgroundJobs.GetBackgroundJobs(Search);
	
	BackgroundJobRunning_ = Not TasksInProgress.Count()=0;
	
	SetPrivilegedMode(False);
	
	Return BackgroundJobRunning_;
	
EndFunction

// Returns the key of the background task
//
// Parameters:
// 	Process_ - DocumentRef.BudgetingProcess - The process of preparing task budgets.
//
// Returns:
//	String - the generated task key in the specified format.
//
Function BackgroundTaskKeyForCreatingDocumentsForBudgetTasks(Process_)
	
	JobKey = "CreatingDocumentsForBudgetTasks%Process_%";
	If Not ValueIsFilled(Process_) Then
		JobKey = StrReplace(JobKey, "%Process_%", "WithoutProcess");
	Else
		JobKey = StrReplace(JobKey, "%Process_%", String(Process_.UUID()));
	EndIf;
	
	Return JobKey;
EndFunction

Procedure RunBackgroundTaskForGeneratingDocuments(Process_, TasksOfFirstStage = Undefined)
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	JobParameters = New Array();
	JobParameters.Add(Process_);
	JobParameters.Add(TasksOfFirstStage);
	
	JobKey = BackgroundTaskKeyForCreatingDocumentsForBudgetTasks(Process_);
	
	BackgroundJobRunning_ = False;
	If Not Common.FileInfobase() Then
		SetPrivilegedMode(True);
		
		Search = New Structure("Key, State", JobKey, BackgroundJobState.Active);
		BackgroundJobRunning_ = BackgroundJobs.GetBackgroundJobs(Search).Count() > 0;
		
		SetPrivilegedMode(False);
	EndIf;
	
	If Not BackgroundJobRunning_ Then
		Try
		
			If ValueIsFilled(Process_) Then
				TaskDescription = NStr("vi = 'Tạo chứng từ theo quy trình: %1%';
										|ru = 'Создание документов по процессу: %1%';
										|en = 'Create documents for the process: %1%'; fa = 'Create documents for the process: %1%';
										|it = 'Creazione dei documenti relativi al processo: %1%';
										|pl = 'Tworzenie dokumentów procesowych: %1%';
										|tr = 'Süreç %1%''e göre belge oluşturma'", DefaultLanguageCode);
				TaskDescription = StrReplace(TaskDescription, "%1%", String(Process_));
			Else
				TaskDescription = NStr("vi = 'Tạo chứng từ không có quy trình';
										|ru = 'Создание документов без процесса';
										|en = 'Create documents without process'; fa = 'Create documents without process';
										|it = 'Creazione dei documenti senza un processo';
										|pl = 'Tworzenie dokumentów bez procesu';
										|tr = 'Süreç olmadan belge oluşturma'", DefaultLanguageCode);
			EndIf;
			
			BackgroundJobs.Execute("BudgetingServer.CreatingDocumentsForBudgetTasks",JobParameters, JobKey,
				TaskDescription);
			
		Except
			
			If Not ValueIsFilled(Process_) Then
				ErrorText = NStr("vi = 'Không thể bắt đầu tác vụ nền để tạo chứng từ ngân sách mà không cần quá trình.';
								|ru = 'Не удалось запустить фоновое задание для формирования бюджетных документов без процесса.';
								|en = 'Cannot run the background job to generate budget documents without process.'; fa = 'Cannot run the background job to generate budget documents without process.';
								|it = 'Impossibile avviare il task in background per generare i documenti di budget senza un processo.';
								|pl = 'Nie można uruchomić zadania w tle w celu utworzenia dokumentów budżetowych bez procesu.';
								|tr = 'Bütçe belgelerinin oluşturulması için arka plan işleri süreçsiz başlatılamıyor.'",
					DefaultLanguageCode);
			Else
				ErrorText = NStr("vi = 'Không thể bắt đầu tác vụ nền để tạo chứng từ ngân sách cho quy trình %1%.';
								|ru = 'Не удалось запустить фоновое задание для формирования бюджетных документов по процессу %1%.';
								|en = 'Cannot run the background job to generate budget documents for the %1% process.'; fa = 'Cannot run the background job to generate budget documents for the %1% process.';
								|it = 'Impossibile avviare il task in background per generare i documenti di budget relativi al processo %1%.';
								|pl = 'Nie można uruchomić zadania w tle w celu wygenerowania dokumentów budżetowych dot. procesu %1%.';
								|tr = 'Bütçe belgelerinin oluşturulması için arka plan işleri %%1 sürecine göre başlatılamıyor.'",
					DefaultLanguageCode);
				ErrorText = StrReplace(ErrorText, "%1%", String(Process_));
			EndIf;
			
			WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
								|ru = 'Бюджетный процесс';
								|en = 'Budget process'; fa = 'فرایند بودجه';
								|it = 'Processo di budget';
								|pl = 'Proces budżetowy';
								|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
				+ "." + NStr("vi = 'Tạo nhiệm vụ ngân sách';
							|ru = 'Создание бюджетных задач';
							|en = 'Create budget tasks'; fa = 'Create budget tasks';
							|it = 'Creazione degli obiettivi di budget';
							|pl = 'Tworzenie zadań budżetowych';
							|tr = 'Bütçe görevi oluştur'", Common.DefaultLanguageCode()),
				EventLogLevel.Warning,,, ErrorText);
		EndTry;
	EndIf;
	
EndProcedure

// Gets an array of background task processes (including an empty value) for generating
// documents for budget tasks for all models.
//
// Returns:
//	Array of DocumentRef.BudgetingProcess - an array of processes, including, possibly, an empty link, for running background jobs on processes.
//
Function BackgroundTasksForGeneratingDocuments()
	
	Query = New Query;
	Query.Text = "SELECT DISTINCT
		|	BudgetTask.BudgetingProcess AS Process_
		|FROM
		|	Task.BudgetTask AS BudgetTask
		|WHERE
		|	NOT BudgetTask.DeletionMark
		|	AND BudgetTask.ForDocumentCreation";
	
	Return Query.Execute().Unload().UnloadColumn("Process_");
	
EndFunction

// Gets an array of tasks to block based on the passed parameters
// All tasks are blocked for the same model, period, stage (or with a repeat of this stage) to avoid the situation
// of parallel creation of identical documents.
//
// Parameters:
// 	BudgetingModel  - CatalogRef.BudgetingModels - selecting tasks based on the budgeting model.
//                 
// 	Period  - Date - selection of targets by period
//                 
//	BudgetingSteps  - CatalogRef.BudgetingSteps - selecting tasks by stage (array of stages) 
//	                           only link, without groups, the stage specified in the task
//	                           details "Etapodgotovkibudgetov" or "Etapodgotovbudzhetovosnovanie".
//	                           Array from the reference link.Stage of budget preparation-selection by an array of tasks.
//
// Returns:
//	ValueTable - table of budget tasks:
//	  *Ref - TaskRef.BudgetTask - a task for blocking.
//	
//
Function TasksToBlockWhenEnteringDocuments(BudgetingModel, Period, BudgetingSteps) Export
	
	If TypeOf(BudgetingSteps) = Type("Array") Then
		ArrayOfStages = BudgetingSteps;
	Else
		ArrayOfStages = New Array;
		ArrayOfStages.Add(BudgetingSteps);
	EndIf;

	Query = New Query;
	Query.SetParameter("BudgetingModel", BudgetingModel);
	Query.SetParameter("Period", Period);
	Query.SetParameter("ArrayOfStages", ArrayOfStages);
	Query.Text = "SELECT
		|	BudgetTask.Ref AS Ref
		|FROM
		|	Task.BudgetTask AS BudgetTask
		|WHERE
		|	BudgetTask.BudgetingModel = &BudgetingModel
		|	AND BudgetTask.BudgetingStep IN(&ArrayOfStages)
		|	AND BudgetTask.Period = &Period
		|
		|UNION ALL
		|
		|SELECT
		|	BudgetTask.Ref
		|FROM
		|	Task.BudgetTask AS BudgetTask
		|WHERE
		|	BudgetTask.BudgetingModel = &BudgetingModel
		|	AND BudgetTask.BudgetingStepBasis IN(&ArrayOfStages)
		|	AND BudgetTask.Period = &Period";
	
	Return Query.Execute().Unload();
	
EndFunction // The task for the lock and leadedocuments()

#Region CreateDocumentsForBudgetTasksInBackground

// This procedure generates documents for budget tasks with priority for first-priority tasks.
//
// Parameters:
//	Process_ - DocumentRef.BudgetingProcess - Budget preparation process (task details)
//	TasksOfFirstStage - Array of TaskRef.BudgetTask - An array of tasks that will be processed first, 
//	                      the remaining tasks will be considered "hung", and will be processed in the 2nd queue.
Procedure CreatingDocumentsForBudgetTasks(Process_, TasksOfFirstStage = Undefined) Export
	
	Query = New Query;
	QueryText = "SELECT
		|	BudgetTask.Ref AS Ref
		|FROM
		|	Task.BudgetTask AS BudgetTask
		|WHERE
		|	NOT BudgetTask.DeletionMark
		|	AND BudgetTask.ForDocumentCreation
		|	AND BudgetTask.BudgetingProcess = &Process_
		|	AND &LinkCondition
		|
		|ORDER BY
		|	&OrderFields";
	
	Query.SetParameter("Process_", Process_);
	
	If TasksOfFirstStage = Undefined Then
		TasksOfFirstStage = New Array;
	EndIf;
	Query.SetParameter("TasksOfFirstStage", TasksOfFirstStage);
	
	Query.Text = StrReplace(QueryText, "&LinkCondition", "BudgetTask.Ref IN (&TasksOfFirstStage)");
	
	Query.Text = QueryText;	
	Query.Text = StrReplace(Query.Text, "&LinkCondition", "BudgetTask.Ref IN (&TasksOfFirstStage)");
	Query.Text = StrReplace(Query.Text, "&OrderFields", "BudgetTask.Date,
	                                         |	BudgetTask.Ref");
	
	TasksOfFirstStage = Query.Execute().Select();
	
	PreviouslyProcessedTasks = New Array;
	
	While TasksOfFirstStage.Next() Do
		CreatingDocumentsForTask(TasksOfFirstStage.Ref);
		PreviouslyProcessedTasks.Add(TasksOfFirstStage.Ref);
	EndDo;
	
	// Since there is no separate routine task for processing suspended tasks, we process them in separate background tasks.
	// This background task is started with the Process ID launch key (may be empty) so that background tasks
	// do not interfere with each other's work (because tasks are not blocked for the entire time of document generation).
	// In each iteration of the next cycle, we check whether there are previously unprocessed tasks.
	// For each task, we look at whether there is a background task running with the task ID key, and if there is, we do not process it.
	
	ThereAreRawTasks = True;
	While ThereAreRawTasks Do
		
		Query.Text = QueryText;
		Query.Text = StrReplace(Query.Text, "&LinkCondition", "NOT BudgetTask.Ref IN (&PreviouslyProcessedTasks)");
		Query.Text = StrReplace(Query.Text, "&OrderFields", "BudgetTask.TaskDueDate");
		
		Query.SetParameter("PreviouslyProcessedTasks", PreviouslyProcessedTasks);
		
		//@skip-check query-in-loop
		Result = Query.Execute();
		
		If Result.IsEmpty() Then
			ThereAreRawTasks = False;
			Break;
		Else
			HungTasks = Result.Select();
			
			While HungTasks.Next() Do
				CreatingDocumentsForTask(HungTasks.Ref);
				
				PreviouslyProcessedTasks.Add(HungTasks.Ref);
			EndDo;
		EndIf;
	EndDo;

EndProcedure

// The procedure creates documents for a budget task.
//
// Parameters:
// 	Task - TaskRef.BudgetTask - the task for which you want to create documents.
Procedure CreatingDocumentsForTask(Task) 
	
	//	1. The formation of each document may take a long time
	//	2. The user has the right to manually block the task by recording the task if he wants to manually create documents.
	//	   Before writing a task in the background task, we check whether it was blocked, if so, we cancel the transaction
	//	3. The user has the right to simultaneously create one of several (or all) documents in the task.
	//	   In this case, if all the necessary documents have been created, then the Creation of Documents flag is removed from the task when writing 
	//	4. For each task, we get a list of tasks that need to be blocked together with the task being modified in order to
	//	   exclude situations when a task will be added in parallel and the creation of documents for it will begin (automatically or manually).
	
	
	ContinueProcessing = True;
	
	While ContinueProcessing Do
		
		////////////////////////////////////////////////////////////////////////////////////
		// 1. Reading the parameters of the next created document and searching it in the database by parameters.
		Parameters = New Structure;
		Parameters.Insert("Task", Task);
		Parameters.Insert("DataVersion", Common.ObjectAttributeValue(Task, "DataVersion"));
		//@skip-check query-in-loop
		SupplementParametersOfFollowingBudgetTaskDocumentToBeGenerated(Task, Parameters, ContinueProcessing);
		
		DocumentParameters = Parameters.DocumentParameters;
		
		If DocumentParameters = Undefined Then
			ContinueProcessing = False;
			Break;
		EndIf;
		If Not ContinueProcessing Then
			Break;
		EndIf;
		
		////////////////////////////////////////////////////////////////////////////////////
		// 2. Create a document (if not found) and write to the task. 
		//   If we find an analog document after writing the document, we cancel the transaction.
		WriteDocumentToTask = False;
		DocumentRef = Undefined;
		
		//@skip-check query-in-loop
		CreatingReadingBudgetTaskDocumentByParameters(Parameters, DocumentRef, WriteDocumentToTask,
			ContinueProcessing);
		
		If Not WriteDocumentToTask And Not ContinueProcessing Then
			Break;
		EndIf;
		
		////////////////////////////////////////////////////////////////////////////////////
		// 3. If an analog document was found, entered manually in another task, then we write the found document to the task.
		If WriteDocumentToTask Then
			
			//@skip-check query-in-loop
			WriteFoundDocumentToBudgetTaskInSeparateTransaction(Parameters, DocumentRef, ContinueProcessing);
			
			If Not ContinueProcessing Then
				Break;
			EndIf;
		EndIf;
			
	EndDo;
	
EndProcedure

Procedure SupplementParametersOfFollowingBudgetTaskDocumentToBeGenerated(Val Task, Parameters, ContinueProcessing)
	
	Action                 = Undefined;
	DocumentParameters       = Undefined;
	ArrayDocuments          = Undefined;
	SettingOfAction        = Undefined;
	BudgetingSteps  = Undefined;
	NewDocumentParameters = Undefined;
	
	BeginTransaction();
	Try
		TaskObject = Task.GetObject();
		
		BudgetingSteps = New Array;
		BudgetingSteps.Add(TaskObject.BudgetingStep);
		If ValueIsFilled(TaskObject.BudgetingStepBasis) Then
			BudgetingSteps.Add(TaskObject.BudgetingStepBasis);
		EndIf;
		
		// Blocking tasks to exclude parallel operation of methods 
		TasksForTransactionalLocking = TasksToBlockWhenEnteringDocuments(TaskObject.BudgetingModel,
		                                                                          TaskObject.Period,
		                                                                          BudgetingSteps);
		
		TaskObject.Lock();
		Block = New DataLock;
		LockItem = Block.Add("Task.BudgetTask");
		LockItem.DataSource = TasksForTransactionalLocking;
		LockItem.UseFromDataSource("Ref", "Ref");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		If TaskObject.DataVersion <> Parameters.DataVersion Then
			DefaultLanguageCode = Common.DefaultLanguageCode();
			Raise NStr("vi = 'Nhiệm vụ đã được thay đổi, việc tạo chứng từ bị gián đoạn';
						|ru = 'Задача была изменена, создание документов прервано';
						|en = 'Job was changed, document creation is canceled'; fa = 'Job was changed, document creation is canceled';
						|it = 'L''obiettivo è stato modificato, il processo di creazione dei documenti è stato interrotto';
						|pl = 'Zadanie zostało zmienione, tworzenie dokumentów zostało przerwane';
						|tr = 'Görev değiştirildi, belge oluşturma kesintiye uğradı'", DefaultLanguageCode);
		EndIf;
		
		Action = TaskObject.Action;
		
		// selecting the analytics of the first document not created
		Attributes = New Structure("Periodicity, ExecuteAutomatically", "Parent.Periodicity");
		Attributes = Common.ObjectAttributesValues(TaskObject.BudgetingStep, Attributes);
		Periodicity = Attributes.Periodicity;
		
		BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(TaskObject.Period, Periodicity);
		EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(TaskObject.Period, Periodicity);
		
		SettingOfAction = TaskObject.SettingOfAction.Get(); 
		DocumentsList = TaskObject.DocumentsList.Unload(,"Document").UnloadColumn("Document");
		NewDocumentParameters = New Structure("Period, BudgetingModel, BudgetingStep");
		FillPropertyValues(NewDocumentParameters, TaskObject);
		
		If Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm
			Or Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
			Or Action = Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
			BudgetEntryTree = ParametersForEnteringBudgetsByActionSettings(SettingOfAction, Action,
				BeginOfPeriod,
				EndOfPeriod,
				Periodicity,
				DocumentsList,
				False);
			
			For Each BudgetViewLine_ In BudgetEntryTree.Rows Do
				If BudgetViewLine_.Rows.Count() > 0 Then
					For Each PeriodAnalyticsLine In BudgetViewLine_.Rows Do	
						If PeriodAnalyticsLine.Rows.Count() > 0 Then
							For Each AnalyticsLine_ In PeriodAnalyticsLine.Rows Do
								If Not ValueIsFilled(AnalyticsLine_.Document) Then
									DocumentParameters = Tasks.BudgetTask.ActionStringParameters(
										AnalyticsLine_, BudgetEntryTree.Columns);
									Break;
								EndIf;
							EndDo;
							If Not DocumentParameters = Undefined Then
								Break;
							EndIf;
						Else
							If Not ValueIsFilled(PeriodAnalyticsLine.Document) Then
								DocumentParameters = Tasks.BudgetTask.ActionStringParameters(
									PeriodAnalyticsLine, BudgetEntryTree.Columns);
								Break;
							EndIf;
						EndIf;
					EndDo;
					If Not DocumentParameters = Undefined Then
						Break;
					EndIf;
				Else
					If Not ValueIsFilled(BudgetViewLine_.Document) Then
						DocumentParameters = Tasks.BudgetTask.ActionStringParameters(
							BudgetViewLine_, BudgetEntryTree.Columns);
						Break;
					EndIf;
				EndIf;
			EndDo;
			
			If Not DocumentParameters = Undefined Then
				ArrayDocuments = FindDocumentByPaddingValues(NameOfBudgetDocumentForIssue(Action),
					DocumentParameters);
			EndIf;
			
		ElsIf Action = Enums.TypesOfBudgetingStepActions.SetValuesForNonFinancialItems Then
			If DocumentsList.Count() = 0 Then
				FillingValues = New Structure;
				For Each Setting In SettingOfAction Do
					If ValueIsFilled(Setting.Value) Then
						FillingValues.Insert(Setting.Name, Setting.Value);
					EndIf;
				EndDo;
				
				FillingValues.Insert("BeginOfPeriod", BeginOfPeriod);
				
				If FillingValues.Property("InputTemplate") Then
					NFPDEFINITIONTable = Common.ObjectAttributeValue(FillingValues.InputTemplate, "TemplateIndicators");
					NFPDefinitions = NFPDEFINITIONTable.Unload()[0].Factor;
				ElsIf FillingValues.Property("NonFinancialItem") Then
					NFPDefinitions = FillingValues.NonFinancialItem;
				Else
					DefaultLanguageCode = Common.DefaultLanguageCode();
					ErrorText = NStr("vi = 'Trong tác vụ %1% trong cài đặt hành động, chưa xác định chỉ tiêu phi tài chính để tạo chứng từ.';
									|ru = 'В задаче %1% в настройках действия не определен нефинансовый показатель для создания документа.';
									|en = 'Non-financial item for document creation is not determined in the %1% task of the action settings.'; fa = 'Non-financial item for document creation is not determined in the %1% task of the action settings.';
									|it = 'Nelle impostazioni %1% dell''azione non è stato definito l''indice non finanziario per creare un documento.';
									|pl = 'W zadaniu %1% w ustawieniach akcji nie jest zdefiniowany wskaźnik pozafinansowy do tworzenia dokumentu.';
									|tr = '%1 % görevindeki eylem ayarlarında belgenin oluşturulması için finansal olmayan öğe belirtilmemiş.'",
						DefaultLanguageCode);
					ErrorText = StrReplace(ErrorText, "%1%", TaskObject);
					
					Raise ErrorText;
				EndIf;
				
				NeedEndPeriod = Common.ObjectAttributeValue(NFPDefinitions, "SetAValueForEachPeriod");
				If NeedEndPeriod Then
					FillingValues.Insert("PeriodEnding", EndOfPeriod);
				EndIf;
				
				DocumentParameters = FillingValues;
				
				ArrayDocuments = FindDocumentByPaddingValues("SetValuesForNonFinancialItems", DocumentParameters);
			EndIf;
			
		EndIf;
		
		TaskObject = Undefined;
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		DefaultLanguageCode = Common.DefaultLanguageCode();
		ErrorText = NStr("vi = 'Không thể tạo chứng từ cho tác vụ %1 do: %2';
						|ru = 'Не удалось создать документ для задачи %1 по причине: %2';
						|en = 'Cannot create the document for the %1 task. Reason: %2'; fa = 'Cannot create the document for the %1 task. Reason: %2';
						|it = 'Non è stato possibile creare il documento per l''obiettivo %1 a causa di: %2';
						|pl = 'Nie udało się utworzyć dokumentu dla zadania %1 z powodu: %2';
						|tr = '%1 görevi için %2 sebebine göre belge oluşturulamıyor'", DefaultLanguageCode);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorText, TaskObject, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
							|ru = 'Бюджетный процесс';
							|en = 'Budget process'; fa = 'فرایند بودجه';
							|it = 'Processo di budget';
							|pl = 'Proces budżetowy';
							|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
			+ "." + NStr("vi = 'Tạo chứng từ cho nhiệm vụ';
						|ru = 'Создание документов для задачи';
						|en = 'Creating documents for the task'; fa = 'Creating documents for the task';
						|it = 'Creazione dei documenti per il compito';
						|pl = 'Tworzenie dokumentów dla zadania';
						|tr = 'Görevler için belge oluşturma'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorText);
			
		ContinueProcessing = False;
		TaskObject = Undefined;
		
	EndTry;
	
	Parameters.Insert("Action",                 Action);
	Parameters.Insert("DocumentParameters",       DocumentParameters);
	Parameters.Insert("ArrayDocuments",          ArrayDocuments);
	Parameters.Insert("SettingOfAction",        SettingOfAction);
	Parameters.Insert("BudgetingSteps",  BudgetingSteps);
	Parameters.Insert("NewDocumentParameters", NewDocumentParameters);
	
EndProcedure

Procedure CreatingReadingBudgetTaskDocumentByParameters(Parameters, DocumentRef, WriteDocumentToTask, ContinueProcessing)
	
	Task                   = Parameters.Task;
	Action                 = Parameters.Action;
	DocumentParameters       = Parameters.DocumentParameters;
	ArrayDocuments          = Parameters.ArrayDocuments;
	SettingOfAction        = Parameters.SettingOfAction;
	BudgetingSteps  = Parameters.BudgetingSteps;
	NewDocumentParameters = Parameters.NewDocumentParameters;
	
	CancelingTransaction         = False;
	
	BeginTransaction();
	Try
		
		If ArrayDocuments = Undefined Then
			
			If Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm Then
				
				NewDocumentParameters.Insert("BudgetTask", Task);
				ArrayDocuments = CreateBudgetEntryDocument(NewDocumentParameters, DocumentParameters, True, False);
				
			ElsIf Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules Then
				
				NewDocumentParameters.Insert("BudgetTask", Task);
				ArrayDocuments = CreateBudgetTurnoverLogger(NewDocumentParameters, DocumentParameters, False);
			
			ElsIf Action = Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
				
				NewDocumentParameters.Insert("BudgetTask", Task);
				ArrayDocuments = CreateInstallationOfOpeningBalancesOfCalculatedIndicators(NewDocumentParameters,
					DocumentParameters, False, False);
				
			ElsIf Action = Enums.TypesOfBudgetingStepActions.SetValuesForNonFinancialItems Then
				
				DocumentRef = Tasks.BudgetTask.CreateSettingForNonFinancialIndicators(NewDocumentParameters,
				                                                                                        SettingOfAction);
				ArrayDocuments = New Array;
				ArrayDocuments.Add(DocumentRef);
				
			EndIf;
			
		EndIf;
		
		If ArrayDocuments = Undefined Then
			DefaultLanguageCode = Common.DefaultLanguageCode();
			Raise NStr("vi = 'Không thể tạo chứng từ';
						|ru = 'Документы не были сформированы';
						|en = 'Documents were not generated'; fa = 'Documents were not generated';
						|it = 'I documenti non sono stati generati';
						|pl = 'Nie utworzono żadnych dokumentów';
						|tr = 'Belgeler oluşturulmadı'", DefaultLanguageCode);
		EndIf;
		
		DocumentRef = ArrayDocuments[ArrayDocuments.Count()-1];
		
		//////////////////////////////////////////////////////////////////////////
		// We impose a lock and read for duplicates.
		
		// Blocking tasks to exclude parallel operation of methods.
		TasksForTransactionalLocking = TasksToBlockWhenEnteringDocuments(NewDocumentParameters.BudgetingModel,
		                                                                          NewDocumentParameters.Period,
		                                                                          BudgetingSteps);
		
		TaskObject = Task.GetObject(); // TaskObject.BudgetTask
		TaskObject.Lock();
		
		Block = New DataLock;
		LockItem = Block.Add("Task.BudgetTask");
		LockItem.DataSource = TasksForTransactionalLocking;
		LockItem.UseFromDataSource("Ref", "Ref");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		If TaskObject.DataVersion <> Parameters.DataVersion Then
			DefaultLanguageCode = Common.DefaultLanguageCode();
			Raise NStr("vi = 'Đã thay đổi nhiệm vụ, việc tạo chứng từ bị gián đoạn.';
						|ru = 'Задача была изменена, создание документов прервано';
						|en = 'Job was changed, document creation is canceled'; fa = 'Job was changed, document creation is canceled';
						|it = 'L''obiettivo è stato modificato, il processo di creazione dei documenti è stato interrotto';
						|pl = 'Zadanie zostało zmienione, tworzenie dokumentów zostało przerwane';
						|tr = 'Görev değiştirildi, belge oluşturma kesintiye uğradı'", DefaultLanguageCode);
		EndIf;
		If TaskObject.DeletionMark Then
			DefaultLanguageCode = Common.DefaultLanguageCode();
			Raise NStr("vi = 'Nhiệm vụ đã bị đánh dấu xóa, sẽ hủy tạo chứng từ';
						|ru = 'Задача была помечена на удаление, создание документов будет отменено';
						|en = 'Job was marked for deletion, document creation will be canceled'; fa = 'Job was marked for deletion, document creation will be canceled';
						|it = 'L''obiettivo è stato contrassegnato per l''eliminazione, il processo di creazione dei documenti verrà annullato';
						|pl = 'Zadanie zostało oznaczone do usunięcia, utworzenie dokumentów zostanie anulowane';
						|tr = 'Görev silinmek üzere işaretlendi, belge oluşturma iptal edilecek'",DefaultLanguageCode);
		EndIf;
		If Not TaskObject.ForDocumentCreation Then
			DefaultLanguageCode = Common.DefaultLanguageCode();
			Raise NStr("vi = 'Nhiệm vụ đã được thay đổi, việc tạo chứng từ là không cần thiết';
						|ru = 'Задача была изменена, создание документов не требуется';
						|en = 'Job was changed, document creation is not required'; fa = 'Job was changed, document creation is not required';
						|it = 'L''obiettivo è stato modificato, non è necessario creare i documenti';
						|pl = 'Zadanie zostało zmienione, tworzenie dokumentów nie jest wymagane';
						|tr = 'Görev değiştirildi, belge oluşturma kesintiye uğradı'", DefaultLanguageCode);
		EndIf;
		
		//////////////////////////////////////////////////////////////////////////
		// We read the documents, if another one has been entered for a long time during the formation of the document,
		// then we cancel the transaction by entering a new one.
		If Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm
			Or Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
			Or Action
			= Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
			ArrayDocuments = FindDocumentByPaddingValues(NameOfBudgetDocumentForIssue(Action),
				DocumentParameters);
		Else
			ArrayDocuments = FindDocumentByPaddingValues("SetValuesForNonFinancialItems",
				DocumentParameters);
		EndIf;
		
		If ArrayDocuments <> Undefined Then
			For Each FoundDocument In ArrayDocuments Do
				If FoundDocument <> DocumentRef Then
					CancelingTransaction = True;
					
					DocumentRef = FoundDocument; // if we write a document to the task, then the found
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If CancelingTransaction Then
			// Rollback the transaction and proceed to the next step - writing the found document to the task.
			Raise NStr("vi = 'Đã hủy tạo mới chứng từ cho nhiệm vụ, vì có một chứng từ với tham số tương tự';
						|ru = 'Создание документа для задачи было отменено, т.к. существует документ с подобными параметрами';
						|en = 'Creation of the document for task was canceled as the document with similar parameters exists'; fa = 'Creation of the document for task was canceled as the document with similar parameters exists';
						|it = 'Il processo di creazione del documento per l''obiettivo è stato annullato perché esiste un documento con parametri simili';
						|pl = 'Utworzenie dokumentu dla zadania zostało anulowane, ponieważ już istnieje dokument o podobnych parametrach';
						|tr = 'Benzer parametrelere sahip belge mevcut olduğundan görev için belge oluşturma iptal edildi'",
				DefaultLanguageCode);
		EndIf;
		
		DocumentRecording = TaskObject.DocumentsList.Add();
		DocumentRecording.Document = DocumentRef;
		TaskObject.AdditionalProperties.Insert("TaskGenerationMode");
		TaskObject.Write();
		
		TaskObject = Undefined;
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		DefaultLanguageCode = Common.DefaultLanguageCode();
		
		If CancelingTransaction Then
			ErrorText = NStr("vi = 'Đã hủy tạo chứng từ cho nhiệm vụ, bởi vì đang có chứng từ với tham số tương tự';
							|ru = 'Создание документа для задачи было отменено, т.к. существует документ с подобными параметрами';
							|en = 'Creation of the document for task was canceled as the document with similar parameters exists'; fa = 'Creation of the document for task was canceled as the document with similar parameters exists';
							|it = 'Il processo di creazione del documento per l''obiettivo è stato annullato perché esiste un documento con parametri simili';
							|pl = 'Utworzenie dokumentu dla zadania zostało anulowane, ponieważ już istnieje dokument o podobnych parametrach';
							|tr = 'Benzer parametrelere sahip belge mevcut olduğundan görev için belge oluşturma iptal edildi'",
				DefaultLanguageCode);
		Else
			ErrorText = NStr("vi = 'Không thể tạo chứng từ cho tác vụ %1 do: %2';
							|ru = 'Не удалось создать документ для задачи %1 по причине: %2';
							|en = 'Cannot create the document for the %1 task. Reason: %2'; fa = 'Cannot create the document for the %1 task. Reason: %2';
							|it = 'Non è stato possibile creare il documento per l''obiettivo %1 a causa di: %2';
							|pl = 'Nie udało się utworzyć dokumentu dla zadania %1 z powodu: %2';
							|tr = '%1 görevi için %2 sebebine göre belge oluşturulamıyor'", DefaultLanguageCode);
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
				Task, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndIf;
		
		WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
							|ru = 'Бюджетный процесс';
							|en = 'Budget process'; fa = 'فرایند بودجه';
							|it = 'Processo di budget';
							|pl = 'Proces budżetowy';
							|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
			+ "." + NStr("vi = 'Tạo chứng từ cho nhiệm vụ';
						|ru = 'Создание документов для задачи';
						|en = 'Creating documents for the task'; fa = 'Creating documents for the task';
						|it = 'Creazione dei documenti per il compito';
						|pl = 'Tworzenie dokumentów dla zadania';
						|tr = 'Görevler için belge oluşturma'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorText);
		
		If CancelingTransaction Then
			WriteDocumentToTask = True;
		Else
			ContinueProcessing     = False;
			WriteDocumentToTask = False;
		EndIf;
		
		TaskObject = Undefined;
	
	EndTry;
EndProcedure

Procedure WriteFoundDocumentToBudgetTaskInSeparateTransaction(Parameters, DocumentRef, ContinueProcessing)
	
	Task                   = Parameters.Task;
	BudgetingSteps  = Parameters.BudgetingSteps;
	NewDocumentParameters = Parameters.NewDocumentParameters; 
	
	BeginTransaction();
	
	Try
		
		// Blocking tasks to exclude parallel operation of methods.
		TasksForTransactionalLocking = TasksToBlockWhenEnteringDocuments(NewDocumentParameters.BudgetingModel,
		                                                                          NewDocumentParameters.Period,
		                                                                          BudgetingSteps);
		
		TaskObject = Task.GetObject(); // TaskObject.BudgetTask
		If TaskObject.DataVersion <> Parameters.DataVersion Then
			DefaultLanguageCode = Common.DefaultLanguageCode();
			Raise NStr("vi = 'Nhiệm vụ đã được thay đổi, việc tạo chứng từ bị gián đoạn.';
						|ru = 'Задача была изменена, создание документов прервано';
						|en = 'Job was changed, document creation is canceled'; fa = 'Job was changed, document creation is canceled';
						|it = 'L''obiettivo è stato modificato, il processo di creazione dei documenti è stato interrotto';
						|pl = 'Zadanie zostało zmienione, tworzenie dokumentów zostało przerwane';
						|tr = 'Görev değiştirildi, belge oluşturma kesintiye uğradı'", DefaultLanguageCode);
		EndIf;
		TaskObject.Lock();
		
		Block = New DataLock;
		LockItem = Block.Add("Task.BudgetTask");
		LockItem.DataSource = TasksForTransactionalLocking;
		LockItem.UseFromDataSource("Ref", "Ref");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		// Install the found document.
		DocumentRecording = TaskObject.DocumentsList.Add();
		DocumentRecording.Document = DocumentRef; 
		TaskObject.Write();
		
		DocumentRecording = Undefined;
		TaskObject = Undefined;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		DefaultLanguageCode = Common.DefaultLanguageCode();
		ErrorText = NStr("vi = 'Không thể ghi chứng từ vào tác vụ %1 do: %2';
						|ru = 'Не удалось записать документ в задачу %1 по причине: %2';
						|en = 'Cannot save the document to the %1 task. Reason: %2'; fa = 'Cannot save the document to the %1 task. Reason: %2';
						|it = 'Impossibile scrivere il documento nell''obiettivo %1 a causa di: %2';
						|pl = 'Nie udało się zapisać dokument do zadania %1 z powodu: %2';
						|tr = 'Görev%1''e sebep%2''ye göre belge kaydedilemedi'", DefaultLanguageCode);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorText, Task, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
							|ru = 'Бюджетный процесс';
							|en = 'Budget process'; fa = 'فرایند بودجه';
							|it = 'Processo di budget';
							|pl = 'Proces budżetowy';
							|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
			+ "." + NStr("vi = 'Tạo chứng từ cho nhiệm vụ';
						|ru = 'Создание документов для задачи';
						|en = 'Creating documents for the task'; fa = 'Creating documents for the task';
						|it = 'Creazione dei documenti per il compito';
						|pl = 'Tworzenie dokumentów dla zadania';
						|tr = 'Görevler için belge oluşturma'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorText);
			
		ContinueProcessing = False;
		
		TaskObject = Undefined;
	
	EndTry;
EndProcedure

#EndRegion

Procedure GenerateAlertsForBudgetIssues()
	
	Query = New Query;
	Query.Text =
	"SELECT
		|	Task_BudgetTask.Ref AS BudgetTask,
		|	Task_BudgetTask.BudgetingModel AS BudgetingModel,
		|	Task_BudgetTask.TaskDueDate AS TaskDueDate,
		|	CASE
		|		WHEN Task_BudgetTask.TaskDueDate < &CurrentDate
		|			THEN &OverdueTask
		|		WHEN Task_BudgetTask.TaskDueDate = &CurrentDate
		|			THEN &TaskDeadlineIsUpcoming
		|		WHEN Task_BudgetTask.TaskDueDate > &CurrentDate
		|			THEN &NewTaskWasReceived
		|	END AS CurrentNotification
		|INTO CurrentTasks
		|FROM
		|	Task.BudgetTask AS Task_BudgetTask
		|WHERE
		|	NOT Task_BudgetTask.DeletionMark
		|	AND NOT Task_BudgetTask.Inactive_
		|	AND NOT Task_BudgetTask.Executed
		|
		|INDEX BY
		|	BudgetTask,
		|	CurrentNotification
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CurrentTasks.BudgetTask AS BudgetTask,
		|	CurrentTasks.BudgetingModel AS BudgetingModel,
		|	CurrentTasks.CurrentNotification AS CurrentNotification,
		|	CASE
		|		WHEN CurrentTasks.CurrentNotification = &TaskDeadlineIsUpcoming
		|				AND NotificationOfReceipt.NotificationKind IS NULL 
		|			THEN &NewTaskWasReceived
		|		ELSE CurrentTasks.CurrentNotification
		|	END AS NotificationKind,
		|	CurrentTasks.BudgetTask.Description AS BudgetTaskName,
		|	CurrentTasks.BudgetTask.TaskDueDate AS BudgetTaskDueDate,
		|	CurrentTasks.BudgetTask.Performer AS BudgetTaskExecutor,
		|	CurrentTasks.BudgetTask.Performer.IBUserID AS PerformerIBUserID,
		|	CurrentTasks.BudgetTask.Performer.Presentation AS BudgetTaskExecutorPresentation,
		|	CurrentTasks.BudgetTask.BudgetingStep AS BudgetTaskStageOfPreparationOfBudgets
		|INTO SendingNotifications
		|FROM
		|	CurrentTasks AS CurrentTasks
		|		LEFT JOIN InformationRegister.NotificationsSentByBudgetTasks AS NotificationOfReceipt
		|		ON CurrentTasks.BudgetTask = NotificationOfReceipt.BudgetTask
		|			AND (NotificationOfReceipt.NotificationKind = &NewTaskWasReceived)
		|WHERE
		|	NOT (CurrentTasks.BudgetTask, CurrentTasks.CurrentNotification) IN
		|				(SELECT
		|					NotificationsSentByBudgetTasks.BudgetTask,
		|					NotificationsSentByBudgetTasks.NotificationKind
		|				FROM
		|					InformationRegister.NotificationsSentByBudgetTasks AS NotificationsSentByBudgetTasks)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SendingNotifications.BudgetTask,
		|	SendingNotifications.BudgetTaskName AS TaskDescription,
		|	SendingNotifications.BudgetingModel AS BudgetingModel,
		|	SendingNotifications.CurrentNotification,
		|	SendingNotifications.NotificationKind,
		|	SendingNotifications.BudgetTaskDueDate AS TaskDueDate,
		|	SendingNotifications.BudgetTaskStageOfPreparationOfBudgets AS BudgetingStep,
		|	SendingNotifications.BudgetTaskExecutor AS Performer,
		|	SendingNotifications.PerformerIBUserID AS PerformerIBUserID,
		|	SendingNotifications.BudgetTaskExecutorPresentation AS PerformerPresentation,
		|	UsersContactInformation.EMAddress AS PerformerEMAddress
		|FROM
		|	SendingNotifications AS SendingNotifications
		|		INNER JOIN Catalog.Users.ContactInformation AS UsersContactInformation
		|		ON SendingNotifications.BudgetTaskExecutor = UsersContactInformation.Ref
		|			AND (UsersContactInformation.Type = VALUE(Enum.ContactInformationTypes.Email))
		|			AND (UsersContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.UserEmail))
		|
		|ORDER BY
		|	TaskDueDate";
	Query.SetParameter("CurrentDate",		BegOfDay(CurrentSessionDate()));
	Query.SetParameter("NewTaskWasReceived",	Enums.BudgetTasksNotificationKinds.NewTaskWasReceived);
	Query.SetParameter("TaskDeadlineIsUpcoming",	Enums.BudgetTasksNotificationKinds.TaskDeadlineIsUpcoming);
	Query.SetParameter("OverdueTask",	Enums.BudgetTasksNotificationKinds.OverdueTask);
	
	Selection = Query.Execute().Select();
	If Not Selection.Count() Then
		Return;
	EndIf;
	
	Account = EmailOperations.SystemAccount();
	
	Try
		Profile = EmailOperationsInternal.InternetMailProfile(Account);
		Join = New InternetMail;
		Join.Logon(Profile);
	Except
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thiết lập kết nối với máy chủ thư: ( %1)';
				|ru = 'Не удалось установить соединение с почтовым сервером: (%1)';
				|en = 'Cannot connect to the mail server: (%1)'; fa = 'Cannot connect to the mail server: (%1)';
				|it = 'Impossibile connettersi con il server di posta: (%1)';
				|pl = 'Nie można nawiązać połączenie z serwerem poczty: (%1)';
				|tr = 'Posta sunucusu(%1) ile bağlanamadı'"),
				ErrorDescription());
		WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
							|ru = 'Бюджетный процесс';
							|en = 'Budget process'; fa = 'فرایند بودجه';
							|it = 'Processo di budget';
							|pl = 'Proces budżetowy';
							|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
			+ "." + NStr("vi = 'Gửi thông báo';
						|ru = 'Отправка оповещения';
						|en = 'Send notification'; fa = 'ارسال اعلان';
						|it = 'Invio notifica';
						|pl = 'Wysyłanie powiadomienia';
						|tr = 'Bildirim gönderme'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, Metadata.Subsystems.BudgetingAndPlanning,,ErrorMessage);
		Return;
	EndTry;
	
	While Selection.Next() Do
		
		ErrorMessage = Undefined;
		
		Try
			//@skip-check query-in-loop
			CreateAndSendEmailAlerts(Account, Selection, Join);
		Except
			ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		
		If ErrorMessage = Undefined Then
			RecordManager = InformationRegisters.NotificationsSentByBudgetTasks.CreateRecordManager();
			RecordManager.BudgetTask				= Selection.BudgetTask;
			RecordManager.NotificationKind				= Selection.CurrentNotification;
			RecordManager.SentNotificationKind	= Selection.NotificationKind;
			RecordManager.Write();
		Else
			WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
								|ru = 'Бюджетный процесс';
								|en = 'Budget process'; fa = 'فرایند بودجه';
								|it = 'Processo di budget';
								|pl = 'Proces budżetowy';
								|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
				+ "." + NStr("vi = 'Gửi thông báo';
							|ru = 'Отправка оповещения';
							|en = 'Send notification'; fa = 'ارسال اعلان';
							|it = 'Invio notifica';
							|pl = 'Wysyłanie powiadomienia';
							|tr = 'Bildirim gönderme'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, Metadata.Subsystems.BudgetingAndPlanning,,
				ErrorMessage,EventLogEntryTransactionMode.Independent);
		EndIf;
		
	EndDo;
	
EndProcedure

Function LanguageCodeOfPerformerUser(IBUserID)
	
	LanguageCode = "";
	SetPrivilegedMode(True);
	
	If ValueIsFilled(IBUserID) Then
		
		ReadProperties = Users.IBUserProperies(IBUserID);
		If TypeOf(ReadProperties) = Type("Structure")
			And ReadProperties.Property("Language") Then
			Language = Metadata.Languages.Find(ReadProperties.Language);
			If Not Language = Undefined Then
				LanguageCode = Language.LanguageCode;
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(LanguageCode) Then
		LanguageCode = Common.DefaultLanguageCode();
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return LanguageCode;
	
EndFunction

Function CreateAndSendEmailAlerts(Account, SampleItemToSend, Join)
	
	ThereIsSubsystemElectronicSignature = Common.SubsystemExists("StandardSubsystems.DigitalSignature");
	If ThereIsSubsystemElectronicSignature Then
		ModuleDigitalSignatureClientServer =
			Common.CommonModule("DigitalSignature");
		
		SignatureFilesExtension = ModuleDigitalSignatureClientServer.PersonalSettings(
			).SignatureFilesExtension;
			
		ModuleDigitalSignature   = Common.CommonModule("DigitalSignature");
	Else
		SignatureFilesExtension = "p7s";
		
		ModuleDigitalSignature   = Undefined;
	EndIf;
	
	ArtistLanguageCode = LanguageCodeOfPerformerUser(SampleItemToSend.PerformerIBUserID);
	
	EmailParameters = New Structure;
	
	SubstitutionParameters = New Structure();
	SubstitutionParameters.Insert("BudgetTask", SampleItemToSend.BudgetTask);
	SubstitutionParameters.Insert("Performer", SampleItemToSend.Performer);
	SubstitutionParameters.Insert("PerformerPresentation", SampleItemToSend.PerformerPresentation);
	SubstitutionParameters.Insert("TaskDescription", SampleItemToSend.TaskDescription);	
	SubstitutionParameters.Insert("TaskDueDate", SampleItemToSend.TaskDueDate);
	
	EmailParameters = Enums.BudgetTasksNotificationKinds.GetEmailParametersUsingTemplate(
		SampleItemToSend.NotificationKind,
		SubstitutionParameters,
		ArtistLanguageCode);
	
	Recipients = New Array;
	Recipients.Add(New Structure("Address, Presentation", SampleItemToSend.PerformerEMAddress, SampleItemToSend.PerformerPresentation));
	
	EmailParameters.Insert("Whom", Recipients);
	
	CorrespondingAttachments = New Map;
	
	Query = New Query;
	Query.Text = "SELECT
		|	Files.Description AS FullDescr,
		|	Files.Extension AS Extension,
		|	Files.Ref AS Ref
		|FROM
		|	Catalog.BudgetingStepsAttachedFiles AS Files
		|WHERE
		|	Files.FileOwner = &BudgetingStep
		|;
		|SELECT
		|	Files.Description AS FullDescr,
		|	Files.Extension AS Extension,
		|	Files.Ref AS Ref
		|FROM
		|	Catalog.BudgetingModelsAttachedFiles AS Files
		|WHERE
		|	Files.FileOwner = &BudgetingModel";
	Query.SetParameter("BudgetingStep",			SampleItemToSend.BudgetingStep);
	Query.SetParameter("BudgetingModel",			SampleItemToSend.BudgetingModel);
	
	QueryResult = Query.ExecuteBatch(); 
	For Each QueryPackage In QueryResult Do
		Selection = QueryPackage.Select();
		While Selection.Next() Do
			FileName = Selection.FullDescr + ?(Selection.Extension = "", "", "." + Selection.Extension);
			CorrespondingAttachments.Insert(FileName, FilesOperations.FileBinaryData(Selection.Ref));
			If ThereIsSubsystemElectronicSignature Then
				ElectronicFileSignatures = ModuleDigitalSignature.ObjectSignatures(Selection.Ref);
				For Each DS In ElectronicFileSignatures Do
					Signature = DS.Signature; // ValueStorage
					CorrespondingAttachments.Insert(Selection.FullDescr + "-DS("+ DS.SequenceNumber + ")." +
						SignatureFilesExtension, Signature.Get());
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
	IBLabelName = Undefined;
	If EmailParameters.Property("IBLabelName", IBLabelName) Then
		AttachmentFileName = ?(Not IsBlankString(IBLabelName),
			IBLabelName, NStr("vi = 'Khởi chạy CSTT';
								|ru = 'Запустить информационную базу';
								|en = 'Start infobase'; fa = 'Start infobase';
								|it = 'Avviare il database';
								|pl = 'Uruchom bazę informacyjną';
								|tr = 'Veri tabanını başlat'", ArtistLanguageCode)) + ".v8i";
		CorrespondingAttachments.Insert(AttachmentFileName, GetBinaryIBLabelData());
		EmailParameters.Delete("IBLabelName");
	EndIf;
	
	EmailParameters.Insert("Attachments", CorrespondingAttachments);
	EmailParameters.Insert("ProcessTexts", False);
	
	Return EmailOperations.SendEmailMessage(Account, EmailParameters);
	
EndFunction

Function GetBinaryIBLabelData()
	
	SystemTitle = Constants.SystemTitle.Get();
	ConnectionString = InfoBaseConnectionString();
	
	LabelText_ = "["+?(IsBlankString(SystemTitle), ConnectionString, SystemTitle)+"]
		|Connect="+ConnectionString+"
		|App=Auto
		|WA=1";
	
	TempFileName = GetTempFileName();
	
	TextDocument = New TextDocument;
	TextDocument.SetText(LabelText_);	
	TextDocument.Write(TempFileName, TextEncoding.UTF8);
	FileBinaryData = New BinaryData(TempFileName);
	DeleteFiles(TempFileName);
	
	Return FileBinaryData;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	DocumentsList - TaskTabularSection.BudgetTask.DocumentsList - LongDesc
// Returns:
// 	Undefined, DocumentRef - LongDesc
Function CurrentDocument(DocumentsList)
	
	Return ?(DocumentsList.Count(), DocumentsList[DocumentsList.Count()-1].Document, Undefined);
	
EndFunction

Function NumberOfBudgetTreeRowsProcessed(BudgetEntryTree)
	
	TotalRowsToProcess = 0;
	For Each BudgetViewLine In BudgetEntryTree.Rows Do
		If BudgetEntryTree.Rows.Count() > 0 Then
			For Each StringPeriod In BudgetViewLine.Rows Do
				If StringPeriod.Rows.Count() > 0 Then
					For Each AnalyticsLine In StringPeriod.Rows Do
						If Not ValueIsFilled(AnalyticsLine.Document) > 0 Then
							TotalRowsToProcess = TotalRowsToProcess + 1;
						EndIf;
					EndDo;
				Else
					If Not ValueIsFilled(StringPeriod.Document) Then
						TotalRowsToProcess = TotalRowsToProcess + 1;
					EndIf;
				EndIf;
			EndDo;
		Else
			If Not ValueIsFilled(BudgetViewLine.Document) Then
				TotalRowsToProcess = TotalRowsToProcess + 1;
			EndIf;
		EndIf;
	EndDo;
	
	If TotalRowsToProcess = 0 Then
		TotalRowsToProcess = 1;
	EndIf;
	
	Return TotalRowsToProcess;
	
EndFunction

Function DocumentTreeRowAnalystPresentation(TreeRow)
	
	AnalyticsPresentation = "";
	
	If ValueIsFilled(TreeRow.Scenario) Then
		AnalyticsPresentation = AnalyticsPresentation + TreeRow.Scenario + ", ";
	EndIf;
	
	If ValueIsFilled(TreeRow.Organization) Then
		AnalyticsPresentation = AnalyticsPresentation + TreeRow.Organization + ", ";
	EndIf;
	
	If ValueIsFilled(TreeRow.Department) Then
		AnalyticsPresentation = AnalyticsPresentation + TreeRow.Department + ", ";
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		If ValueIsFilled(TreeRow["Dimension"+Cnt]) Then
			AnalyticsPresentation = AnalyticsPresentation + TreeRow["Dimension"+Cnt] + ", ";
		EndIf;
	EndDo;
	
	AnalyticsPresentation = Left(AnalyticsPresentation,StrLen(AnalyticsPresentation) - 2);
	
	Return AnalyticsPresentation;
	
EndFunction

// Brings the types of budget item analytics in the action settings to the metadata of the current configuration
//
Procedure UpdateActionSettings() Export
	
	Selection = Select();
	While Selection.Next() Do
			
		Object = Selection.Ref.GetObject();
		SettingOfAction = Object.SettingOfAction.Get();
		
		If SettingOfAction <> Undefined And TypeOf(SettingOfAction) = Type("ValueTable") Then
			If SettingOfAction.Columns.Find("Name") <> Undefined
				And SettingOfAction.Columns.Find("Value") <> Undefined Then
				
				For Each TableRow1 In SettingOfAction Do
					If TableRow1.Name = "BudgetPopulationDimension" Then
						
						Table = TableRow1.Value;
						TableCopy = Table.CopyColumns();
						
						For Indus = 1 To 6 Do
							AnalyticsColumn = TableCopy.Columns.Find("Dimension" + String(Indus));
							If AnalyticsColumn <> Undefined Then
								TableCopy.Columns.Delete(AnalyticsColumn);
								TableCopy.Columns.Add("Dimension" + String(Indus),
									Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.Type);
							EndIf;
						EndDo;
						
						For Each TableRow2 In Table Do
							FillPropertyValues(TableCopy.Add(), TableRow2);
						EndDo;
						
						TableRow1.Value = TableCopy;
					Else
						Continue;
					EndIf;
				EndDo;
				
				Object.SettingOfAction = New ValueStorage(SettingOfAction);
				Object.Write();
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure CollapseAnalyticsOfBudgetFilling(BudgetPopulationDimension)
	
	BudgetPopulationDimension.FillValues(Catalogs.Companies.EmptyRef(), "Organization");
	BudgetPopulationDimension.FillValues(Catalogs.BusinessStructure.EmptyRef(), "Department");
	ColumnsArray1 = New Array;
	For Each Column In BudgetPopulationDimension.Columns Do
		ColumnsArray1.Add(Column.Name);
	EndDo;
	BudgetPopulationDimension.GroupBy(StrConcat(ColumnsArray1, ","));
	
EndProcedure

// Gets the availability structure of the "budget Instance" Analytics based on the settings
// of the active budget task.
// 
// Parameters:
//  Document - DocumentRef.BudgetEntryForm, Undefined - link to the document "budget Copy"
//           or lack of selection for the document.
//  User - CatalogRef.Users - the user for which we get the availability of Analytics.
//               - Undefined - lack of selection by user.
//
// Returns:
//  Structure - The availability structure of the Budget Instance Analyst:
//   *AvailabilityCompany - Boolean - Indicates whether the organization is available.
//   *AvailabilityDepartment - Boolean - Indicates whether the division is available.
//   *AvailabilityScenario - Boolean - Indicates whether the script is available.
//   *AvailabilityOfAnalytics_1 - Boolean - Indicates whether analytics is available with index 1.
//   *AvailabilityOfAnalytics_2 - Boolean - Indicates whether analytics is available with index 2.
//   *AvailabilityOfAnalytics_3 - Boolean - Indicates whether analytics is available with index 3.
//   *AvailabilityOfAnalytics_4 - Boolean - Indicates whether analytics is available with index 4.
//   *AvailabilityOfAnalytics_5 - Boolean - Indicates whether analytics is available with index 5.
//   *AvailabilityOfAnalytics_6 - Boolean - Indicates whether analytics is available with index 6.
//   *ThereIsActiveTask - Boolean - Indicates whether there is an active task.
//
Function GetAvailabilityOfBudgetInstanceAnalytics(Document = Undefined, User = Undefined) Export
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	AvailabilityOfAnalytics = New Structure;
	AvailabilityOfAnalytics.Insert("AvailabilityCompany",False);
	AvailabilityOfAnalytics.Insert("AvailabilityDepartment",False);
	AvailabilityOfAnalytics.Insert("AvailabilityScenario",False);
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		AvailabilityOfAnalytics.Insert("AvailabilityOfAnalytics_" + Cnt,False);
	EndDo;
	AvailabilityOfAnalytics.Insert("ThereIsActiveTask",False);
	
	If Document = Undefined Or User = Undefined Then
		Return AvailabilityOfAnalytics;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
		|	BudgetTaskDocumentsList.Ref,
		|	BudgetTaskDocumentsList.Ref.Action,
		|	BudgetTaskDocumentsList.Ref.SettingOfAction,
		|	BudgetTaskDocumentsList.Ref.BudgetingStep.Parent.Periodicity AS PeriodicityOfBudgetPreparationStage
		|FROM
		|	Task.BudgetTask.DocumentsList AS BudgetTaskDocumentsList
		|WHERE
		|	BudgetTaskDocumentsList.Document = &EBDocument
		|	AND BudgetTaskDocumentsList.Ref.Performer = &Performer
		|	AND NOT BudgetTaskDocumentsList.Ref.Executed";
	
	Query.SetParameter("EBDocument", Document);
	Query.SetParameter("Performer", User);
	
	Selection = Query.Execute().Select();
	
	Attributes = New Structure("BeginOfPeriod, PeriodEnding", "BeginOfPeriod", "PeriodEnding");
	Attributes = Common.ObjectAttributesValues(Document, Attributes);
	
	While Selection.Next() Do
		
		ActionSettingsStore = Selection.SettingOfAction; // ValueStorage
		SettingOfAction = ActionSettingsStore.Get();
		
		If Not TypeOf(SettingOfAction) = Type("ValueTable") Then
			Continue;
		EndIf;
		
		DocumentsList = New Array();
		DocumentsList.Add(Document);
		
		//@skip-check query-in-loop
		BudgetEntryTree = ParametersForEnteringBudgetsByActionSettings(SettingOfAction, Selection.Action, Attributes.BeginOfPeriod,
			Attributes.PeriodEnding, Selection.PeriodicityOfBudgetPreparationStage, DocumentsList, False);
		
		FoundTreeString = BudgetEntryTree.Rows.Find(Document,"Document",True);
		
		If Not FoundTreeString = Undefined Then
			If FoundTreeString.AvailabilityCompany = True Then
				AvailabilityOfAnalytics.AvailabilityCompany = True;
			EndIf;
			If FoundTreeString.AvailabilityDepartment = True Then
				AvailabilityOfAnalytics.AvailabilityDepartment = True;
			EndIf;
			If FoundTreeString.AvailabilityScenario = True Then
				AvailabilityOfAnalytics.AvailabilityScenario = True;
			EndIf;
			For Cnt = 1 To MaximumNumberOfAnalysts Do
				If FoundTreeString["AvailabilityOfAnalytics_" + Cnt] = True Then
					AvailabilityOfAnalytics["AvailabilityOfAnalytics_" + Cnt] = True;
				EndIf;
			EndDo;
		EndIf;
		
		AvailabilityOfAnalytics.ThereIsActiveTask = True;
		
	EndDo;
	
	Return AvailabilityOfAnalytics;

EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Tasks.BudgetTask.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.3";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("2b11699a-2b7c-41a6-abda-c5e00e582b2c");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Tasks.BudgetTask.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Thêm cột ""Quy tắc tính toán"", ""Tính định kỳ"" vào bảng ""Dạng ngân sách"" mà được lưu trong mục tin ""Tùy chỉnh hiệu lực"".';
							|ru = 'Добавляет колонки ""Правило расчета"", ""Периодичность"" в таблицу ""Виды бюджетов"", хранящуюся в реквизите ""Настройка действия"".';
							|en = 'Adds the ""Calculation rule"" and ""Frequency"" columns to the ""Budget profiles"" table stored in the ""Action settings"" attribute.'; fa = 'Adds the ""Calculation rule"" and ""Frequency"" columns to the ""Budget profiles"" table stored in the ""Action settings"" attribute.';
							|it = 'Adds the ""Calculation rule"" and ""Frequency"" columns to the ""Budget profiles"" table stored in the ""Action settings"" attribute.';
							|pl = 'Adds the ""Calculation rule"" and ""Frequency"" columns to the ""Budget profiles"" table stored in the ""Action settings"" attribute.';
							|tr = '""Eylem ayarları"" özniteliğinde saklı ""Bütçe profilleri"" tablosuna ""Hesaplama kuralı"" ve ""Sıklık"" sütunlarını ekler.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Tasks.BudgetTask.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Tasks.BudgetTask.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Tasks.BudgetTask.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// LongDesc
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters = Undefined) Export
	
	MetadataObjectName = Metadata.Tasks.BudgetTask.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = MetadataObjectName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryText =
	"SELECT
	|	BudgetTask.Ref AS Ref,
	|	BudgetTask.SettingOfAction AS SettingOfAction
	|FROM
	|	Task.BudgetTask AS BudgetTask
	|WHERE
	|	BudgetTask.Action IN (VALUE(Enum.TypesOfBudgetingStepActions.FillingBudgetEntryForm), VALUE(Enum.TypesOfBudgetingStepActions.AdjustCorrectBudgets))";
	
	Query = New Query(QueryText);
	Result = Query.Execute();
	
	ResultTable1 = Result.Unload();
	DataProcessorRefs = New Array;
	For Each TableRow In ResultTable1 Do
		SettingOfAction = TableRow.SettingOfAction.Get();
		If TypeOf(SettingOfAction) = Type("ValueTable") Then
			LineTypesOfBudgets = SettingOfAction.Find("BudgetProfiles", "Name");
			If LineTypesOfBudgets = Undefined Then
				Continue;
			EndIf;
			TableTypesOfBudgets = LineTypesOfBudgets.Value; // -ValueTable-
			If TableTypesOfBudgets.Columns.Find("CalculationRule") = Undefined
				Or TableTypesOfBudgets.Columns.Find("Periodicity") = Undefined Then
				DataProcessorRefs.Add(TableRow.Ref);
			EndIf;
		EndIf;
	EndDo;
	
	InfobaseUpdate.MarkForProcessing(Parameters, DataProcessorRefs);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	MetadataObject = Metadata.Tasks.BudgetTask;
	MetadataObjectName = MetadataObject.FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, MetadataObjectName);
		Return;
	EndIf;
	
	ObjectsProcessed = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý nhiệm vụ ngân sách theo hàm sự kiện:';
								|ru = 'Не удалось обработать бюджетные задачи по обработчику:';
								|en = 'Cannot process the budget tasks by the handler:'; fa = 'Cannot process the budget tasks by the handler:';
								|it = 'Cannot process the budget tasks by the handler:';
								|pl = 'Cannot process the budget tasks by the handler:';
								|tr = 'İşleyici tarafından bütçe görevleri işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- khi xử lý bảng ""Dạng ngân sách"" trong mục tin ""Tùy chỉnh hiệu lực""';
								|ru = '- при обработке таблицы ""Виды бюджетов"" в реквизите ""Настройка действия""';
								|en = '- When processing the ""Budget profiles"" table in the ""Action settings"" attribute'; fa = '- When processing the ""Budget profiles"" table in the ""Action settings"" attribute';
								|it = '- When processing the ""Budget profiles"" table in the ""Action settings"" attribute';
								|pl = '- When processing the ""Budget profiles"" table in the ""Action settings"" attribute';
								|tr = '- ""Eylem ayarı"" özniteliğindeki ""Bütçe profilleri"" tablosunun işlenmesi sırasında'"));

	For Each Selection In UpdatedData Do
	
		ExceptionReason = "";
		Recommendation = "";

		BeginTransaction();

		Try
			
			Task = Selection.Ref; // TaskRef.BudgetTask - 
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			LockItem = Block.Add(MetadataObjectName);
			LockItem.SetValue("Ref", Task);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			ExceptionReason = "BadData";
			Recommendation = NStr("vi = 'Hãy kiểm tra dữ liệu của nhiệm vụ ngân sách theo cách thủ công.';
									|ru = 'Проверьте данные бюджетных задач вручную.';
									|en = 'Check the budget task data manually.'; fa = 'Check the budget task data manually.';
									|it = 'Check the budget task data manually.';
									|pl = 'Check the budget task data manually.';
									|tr = 'Bütçe görevlerinin verilerini manuel olarak kontrol edin.'");

			TaskObject = Task.GetObject();
			SettingOfAction = TaskObject.SettingOfAction.Get();
			LineTypesOfBudgets = SettingOfAction.Find("BudgetProfiles", "Name");
			If LineTypesOfBudgets = Undefined Then
				CommitTransaction();
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
				Continue;
			EndIf;
			TableTypesOfBudgets = LineTypesOfBudgets.Value; // - ValueTable -
			YouNeedToOverwriteObject = False;
			If TableTypesOfBudgets.Columns.Find("CalculationRule") = Undefined Then
				TableTypesOfBudgets.Columns.Add("CalculationRule",
					New TypeDescription("CatalogRef.RuleForCalculatingRelatedBudgetBalancesAndTurnovers"));
				YouNeedToOverwriteObject = True;
			EndIf;
			If TableTypesOfBudgets.Columns.Find("Periodicity") = Undefined Then
				TableTypesOfBudgets.Columns.Add("Periodicity",
					New TypeDescription("EnumRef.Periodicity"));
				YouNeedToOverwriteObject = True;
			EndIf;
			
			ExceptionReason = "Record";

			If YouNeedToOverwriteObject Then
				TaskObject.SettingOfAction = New ValueStorage(SettingOfAction);
				InfobaseUpdate.WriteObject(TaskObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = "BadData" Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(Selection.Ref, Recommendation,
					ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = "Record" Then
				
				InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed,
					Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed > 0 Then
		InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
	EndIf;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
		MetadataObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf