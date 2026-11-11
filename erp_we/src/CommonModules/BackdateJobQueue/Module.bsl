#Region Public

#Region RegisteringTasks

// Creating non-operational queue jobs when writing a set of register entries.
// 
// Parameters:
//  Source - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records
//  TempTablesManager - Undefined, TempTablesManager - When specifying the MW, the data from the temporary tables will be used to generate new tasks
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
//
Procedure CreateNonOperationalQueueJobsWhenRecordingRecordset(Source, TempTablesManager = Undefined,
	DataForRegisteringTasks = Undefined) Export
	
	If Source.AdditionalProperties.Property("DonTRegisterNonOperationalQueueTasks") Then
		Return;
	EndIf;

	RegisterMetadata = Source.Metadata();
	RegisterManager = Common.ObjectManagerByFullName(RegisterMetadata.FullName());

	TypesOfTasksToRegisterInQueue = TypesOfTasksToRegisterInQueue(RegisterMetadata);
	For Each CurrentData In TypesOfTasksToRegisterInQueue Do

		TaskRegisterMetadata = Common.MetadataObjectByID(CurrentData.QueueRegister);
		TaskRegisterManager = Common.ObjectManagerByFullName(TaskRegisterMetadata.FullName());

		TaskRegisterManager.CreateJobs(RegisterManager, CurrentData.KindsOfTasks, Source,
			TempTablesManager, DataForRegisteringTasks);

	EndDo;

EndProcedure

// Gets a list of types of tasks for the register being modified
// 
// Parameters:
//  RegisterMetadata - MetadataObjectAccumulationRegister, MetadataObjectInformationRegister - Register metadata
// 
// Returns:
//  ValueTable - Types Of Tasks To Register In The Queue:
// * QueueRegister - CatalogRef.MetadataObjectIDs - 
// * KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List Of Types Of Tasks
Function TypesOfTasksToRegisterInQueue(RegisterMetadata) Export

	TaskTable = New ValueTable;
	TaskTable.Columns.Add("QueueRegister",
		New TypeDescription("CatalogRef.MetadataObjectIDs"));
	TaskTable.Columns.Add("KindsOfTasks", New TypeDescription("Array"));

	RegisterID = Common.MetadataObjectID(RegisterMetadata.FullName());

	Query = New Query;
	Query.Text = "
	|SELECT
	|	RegistersReading.Ref AS JobKind,
	|	RegistersReading.Ref.Register AS QueueRegister
	|FROM
	|	Catalog.BackdateJobKinds.RegistersToRead AS RegistersReading
	|WHERE
	|	RegistersReading.Register = &RegisterID
	|	AND CASE
	|		WHEN
	|			RegistersReading.Ref = VALUE(Catalog.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords)
	|			THEN &UseBalanceSheetStatement
	|		ELSE TRUE
	|	END
	|TOTALS
	|BY
	|	QueueRegister";

	Query.SetParameter("RegisterID", RegisterID);
	Query.SetParameter("UseBalanceSheetStatement", GetFunctionalOption(
		"UseBalanceSheetStatement"));
	
	SetPrivilegedMode(True);
	SamplingQueue = Query.Execute().Select(QueryResultIteration.ByGroups);
	SetPrivilegedMode(False);

	While SamplingQueue.Next() Do

		SelectionTypesOfTasks = SamplingQueue.Select();

		ListOfTypesOfTasks = New Array;

		While SelectionTypesOfTasks.Next() Do

			ListOfTypesOfTasks.Add(SelectionTypesOfTasks.JobKind);

		EndDo;

		If ListOfTypesOfTasks.Count() > 0 Then

			NewRow = TaskTable.Add();
			NewRow.QueueRegister = SamplingQueue.QueueRegister;
			NewRow.KindsOfTasks = ListOfTypesOfTasks;

		EndIf;

	EndDo;

	Return TaskTable;

EndFunction

// Checking the availability conditions for creating non-operational queue tasks in the information database.
// 
// Parameters:
//  Source - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records
// 
// Returns:
//  Boolean - Creation Of Non-Operational Queue Tasks Is Available
Function CreationOfNonOperationalQueueTasksIsAvailable(Source) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Return False; // Job registration is performed only in the main node
	EndIf;
	
	If Source.DataExchange.Load Then
		
		// Let's check the presence of a service additional property for a set of records (added during the exchange of RIB)
		If Source.AdditionalProperties.Property("RIBExchangeCreateNonOperationalQueueJobs") Then
			Return True;
		EndIf;
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region BackdateJobQueueExecution

// The procedure for launching a routine task for executing a non-operational queue.
// 
//Parameters:
//  TaskLaunchParameters - See ParametersForStartingTaskExecution
Procedure RoutineExecutionOfNonOperationalTaskQueue(TaskLaunchParameters = Undefined) Export

	ScheduledJob = Metadata.ScheduledJobs.BackdateJobQueueExecution;
	
	Common.OnStartExecuteScheduledJob(ScheduledJob);
	
	If Common.FileInfobase() Then
		Return;
	EndIf;
	
	If TaskLaunchParameters = Undefined Then
		TaskLaunchParameters = ParametersForStartingTaskExecution();
	EndIf;
	
	SetPrivilegedMode(True);
	
	DataSeparationMode = Common.DataSeparationEnabled();
	
	CurrentSessionDate = CurrentSessionDate();
	
	BackgroundJobIdentifier = Undefined;
	
	BackgroundSessionJob = GetCurrentInfoBaseSession().GetBackgroundJob();
	
	If BackgroundSessionJob <> Undefined Then
		
		BackgroundJobIdentifier = BackgroundSessionJob.UUID;
		
		TimeOfEndOfRoutineTask = Date(1, 1, 1, 0, 0, 0);
		
		If DataSeparationMode Then

			FilterOfTasks = New Structure;
			FilterOfTasks.Insert("MethodName", ScheduledJob.MethodName);
			FilterOfTasks.Insert("JobState", Enums.JobsStates.Running);
			Jobs = ScheduledJobsServer.FindJobs(FilterOfTasks);

			For Each Job In Jobs Do

				IdOfBackgroundTaskThatIsRunning = Common.ObjectAttributeValue(
					Job.Id, "ActiveBackgroundJob");

				If BackgroundJobIdentifier = IdOfBackgroundTaskThatIsRunning Then
					TimeOfEndOfRoutineTask = EndTimeOfScheduledRoutineTask(
						Job.Schedule, CurrentSessionDate);
					Break;
				EndIf;

			EndDo;

		Else

			If BackgroundSessionJob.ScheduledJob <> Undefined Then
				TimeOfEndOfRoutineTask = EndTimeOfScheduledRoutineTask(
					BackgroundSessionJob.ScheduledJob.Schedule, CurrentSessionDate);
			EndIf;

		EndIf;
		
		If ValueIsFilled(TimeOfEndOfRoutineTask) Then
			TaskLaunchParameters.EndTimeOfControlThread = TimeOfEndOfRoutineTask;
		EndIf;
		
	EndIf;
	
	BackgroundJobManagingThread = CheckStartExecutionOfNonOperationalTaskQueue(TaskLaunchParameters);
	
	If DataSeparationMode And BackgroundJobManagingThread <> Undefined Then
		BackgroundJobManagingThread.WaitForExecutionCompletion();
	EndIf;
	
	SetPrivilegedMode(False);

EndProcedure

// Procedure for Ending the execution of a non-operational task queue.
Procedure EndOfExecutionOfNonOperationalTaskQueue() Export
	
	If Common.FileInfobase() Then
		Return;
	EndIf;

	AttemptNumber = 1;
	
	While AttemptNumber <= 3 Do
		
		ActionSuccessful = True;
		
		BeginTransaction();

		Try

			ExceptionReason = "Block";

			Block = New DataLock;
			Item = Block.Add("InformationRegister.PriorityJobsOfBackdateJobQueue");
			Item.Mode = DataLockMode.Exclusive;
			Block.Lock();

			ExceptionReason = "StoppingControlThread";

			Query = New Query;
			Query.Text = "
			|SELECT TOP 1
			|	PriorityJobsOfBackdateJobQueue.Organization AS Organization,
			|	PriorityJobsOfBackdateJobQueue.TaskPeriod AS TaskPeriod
			|FROM
			|	InformationRegister.PriorityJobsOfBackdateJobQueue AS PriorityJobsOfBackdateJobQueue";

			SetPrivilegedMode(True);

			ResultIsMonthEndClosing = Query.Execute();
			If ResultIsMonthEndClosing.IsEmpty() Then

				MethodName = "BackdateJobQueue.CompleteTasksInNonOperationalQueue";
				Filter = New Structure;
				Filter.Insert("MethodName", MethodName);
				Filter.Insert("State", BackgroundJobState.Active);
				BackgroundJobsManagingThread = BackgroundJobs.GetBackgroundJobs(Filter);
				For Each ActiveTask In BackgroundJobsManagingThread Do
					ActiveTask.Cancel();
				EndDo;

			EndIf;

			SetPrivilegedMode(False);

			CommitTransaction();
			
		Except

			RollbackTransaction();
			
			ActionSuccessful = False;
			
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());

			If ExceptionReason = "Block" Then

				Event = NStr("vi = 'Kết thúc luồng điều khiển của hàng đợi không hoạt động: Chặn';
							|ru = 'Завершение управляющего потока неоперативной очереди: Блокировка';
							|en = 'Complete the thread-of-control of the backdate queue: Lock'; fa = 'Complete the thread-of-control of the backdate queue: Lock';
							|it = 'Complete the thread-of-control of the backdate queue: Lock';
							|pl = 'Complete the thread-of-control of the backdate queue: Lock';
							|tr = 'Operasyonel olmayan iş kuyruğunun kontrol akışının sonlandırılması: Bloklama'",
					Common.DefaultLanguageCode());

			Else

				Event = NStr("vi = 'Hoàn tất công việc của luồng xử lý trong hàng đợi nhiệm vụ không hoạt động';
							|ru = 'Завершение работы рабочего потока неоперативной очереди заданий';
							|en = 'Complete the worker thread of the backdate job queue'; fa = 'Complete the worker thread of the backdate job queue';
							|it = 'Complete the worker thread of the backdate job queue';
							|pl = 'Complete the worker thread of the backdate job queue';
							|tr = 'Operasyonel olmayan iş kuyruğunun iş akışının sonlandırılması'",
					Common.DefaultLanguageCode());

			EndIf;

			WriteLogEvent(Event, EventLogLevel.Error, , , ErrorText);

		EndTry;
		
		If ActionSuccessful Then
			Break;
		EndIf;
		
		AttemptNumber = AttemptNumber + 1;
		
	EndDo;
	
EndProcedure

// Starts the execution of tasks in a non-operational queue (control thread).
// The control flow can be started in 3 modes:
// 1. A routine task (all tasks are processed according to the period).
// 2. Closing of the month (tasks related to the closing of the month are performed as a priority).
// 3. Direct launch of tasks on the list of documents (See CompleteTasksInNonOperationalQueueBasedOnListOfDocuments)
// . (See CompleteTasksOfNonOperationalQueueInDocumentTransaction)
// 4. Direct start of execution of tasks on the document in the transaction of carrying
// out.
// 
// Parameters:
//  TaskLaunchParameters - See ParametersForStartingTaskExecution
//
Procedure CompleteTasksInNonOperationalQueue(TaskLaunchParameters = Undefined) Export
	
	If TaskLaunchParameters = Undefined Then
		TaskLaunchParameters = ParametersForStartingTaskExecution();
	EndIf;
	
	StructureOfFormationOfDataPortions = StructureOfFormationOfDataPortions();
	
	ParametersOfTaskCompletion = ParametersOfTaskCompletion();
	ParametersOfTaskCompletion.CompletingTasksDirectly = (TaskLaunchParameters.FileInfobase
		Or TaskLaunchParameters.DebugMode Or TaskLaunchParameters.CompletingTasksBasedOnListOfDocuments);
	
	If TaskLaunchParameters.FileInfobase And ValueIsFilled(TaskLaunchParameters.ClosingPeriod) Then
		TaskLaunchParameters.MonthEndClosingModeIsFileInfobase = True;
	EndIf;
	
	If ParametersOfTaskCompletion.CompletingTasksDirectly Then
		NumberOfWorkThreads = 1;
		StructureOfFormationOfDataPortions.BackgroundJobProcessing = False;
	Else
		NumberOfWorkThreads = NumberOfBackdateJobQueueStreams();
	EndIf;
	
	InformationOnTypesOfTasks = TaskLaunchParameters["TaskQueues"].KindsOfTasks;
	
	Query = New Query;

	WorkFlows = New Array;
	NumberOfFreeWorkThreads = NumberOfWorkThreads;
	ThereAreTasksToBeProcessed = True;
	
	While ThereAreTasksToBeProcessed Or NumberOfFreeWorkThreads < NumberOfWorkThreads Do
		
		Query.SetParameter("Companies", TaskLaunchParameters.Companies);
		Query.SetParameter("ClosingPeriod", TaskLaunchParameters.ClosingPeriod);
		Query.SetParameter("JobKind", TaskLaunchParameters.JobKind);
		SetRequestParametersByQueue(Query, TaskLaunchParameters["TaskQueues"]);
		
		If TaskLaunchParameters.CompletingTasksBasedOnListOfDocuments Then
			Query.Text = QueryTextForSelectingTasksInNonOperationalQueueForExecutionBasedOnListOfDocuments(
				TaskLaunchParameters.DocumentsTable, TaskLaunchParameters.JobKind,
				TaskLaunchParameters["TaskQueues"], TaskLaunchParameters.PerformTasksInTransaction);
			Query.SetParameter("JobKind", TaskLaunchParameters.JobKind);
			Query.SetParameter("DocumentsToBeReflected", TaskLaunchParameters.DocumentsTable);
		Else
			
			Query.TempTablesManager = New TempTablesManager;

			Query.Text = QueryTextMinimumPeriodOfTasksToBeProcessed(TaskLaunchParameters);
			SetPrivilegedMode(True);
			QueryResult = Query.ExecuteBatch();
			SetPrivilegedMode(False);
			ResultIsMonthEndClosingMode = QueryResult[QueryResult.UBound()].Unload();

			MonthEndClosingMode = ResultIsMonthEndClosingMode[0].MonthEndClosingMode;
			If MonthEndClosingMode Then
				PeriodsOfClosing = QueryResult[QueryResult.UBound() - 1].Unload();
				MonthEndClosingBeginningOfPeriod = PeriodsOfClosing[0].PeriodMin;
				MonthEndClosingEndOfPeriod = PeriodsOfClosing[0].PeriodMax;
				CompaniesList = QueryResult[QueryResult.UBound() - 2].Unload().UnloadColumn(
					"Organization");
				Query.SetParameter("Companies", CompaniesList);
				Query.SetParameter("MonthEndClosingBeginningOfPeriod", MonthEndClosingBeginningOfPeriod);
				Query.SetParameter("MonthEndClosingEndOfPeriod", MonthEndClosingEndOfPeriod);
			Else
				If TaskLaunchParameters.MonthEndClosingModeIsFileInfobase Then
					Return;
				EndIf;
				
				If Not TaskLaunchParameters.FileInfobase 
					And ValueIsFilled(TaskLaunchParameters.EndTimeOfControlThread)
					And TaskLaunchParameters.EndTimeOfControlThread < CurrentSessionDate() Then

					Return;
					
				EndIf;
				
			EndIf;
			Query.Text = QueryTextForSelectingTasksInNonOperationalQueueForExecution(TaskLaunchParameters,
				MonthEndClosingMode);
		EndIf;
		
		SetPrivilegedMode(True);
		SelectionTaskType = Query.Execute().Select(QueryResultIteration.ByGroups);
		SetPrivilegedMode(False);
		
		If SelectionTaskType.Next() Then

			SampleDay = SelectionTaskType.Select(QueryResultIteration.ByGroups);

			If SampleDay.Next() Then

				ThereAreTasksToBeProcessed = True;
				TaskTypeDescription = InformationOnTypesOfTasks.Get(SelectionTaskType.JobKind);
				
				FillPropertyValues(StructureOfFormationOfDataPortions, SelectionTaskType);
				StructureOfFormationOfDataPortions.MaximumBatch = TaskTypeDescription.MaximumBatch;
				
				DocumentsSelection = SampleDay.Select();
				
				StructureOfFormationOfDataPortions.DocumentsTable.Clear();
				While DocumentsSelection.Next() Do
					DocumentToProcessing = StructureOfFormationOfDataPortions.DocumentsTable.Add();
					DocumentToProcessing.Document = DocumentsSelection.Document;
				EndDo;
				
				QueueData = TaskLaunchParameters["TaskQueues"].QueuesTable.FindRows(
					New Structure("Register", TaskTypeDescription.QueueRegister));
					
				If QueueData.Count() > 0 Then

					QueueParameters = QueueData[0];

					DataForProcessing_ = QueueParameters.TaskRegisterManager.DataForMultithreadedBackgroundProcessing(
						StructureOfFormationOfDataPortions, NumberOfFreeWorkThreads);

					ParametersOfTaskCompletion.QueueRegister = QueueParameters.Register;
					ParametersOfTaskCompletion.QueueRegisterName = QueueParameters.QueueName;
					ParametersOfTaskCompletion.TaskRegisterManager = QueueParameters.TaskRegisterManager;
					ParametersOfTaskCompletion.CompletingTasksInTransaction = TaskLaunchParameters.PerformTasksInTransaction;
					ParametersOfTaskCompletion.DataForProcessing_ = DataForProcessing_;
					ParametersOfTaskCompletion.JobKind = SelectionTaskType.JobKind;
					ParametersOfTaskCompletion.ThreadsCount = NumberOfFreeWorkThreads;
					ParametersOfTaskCompletion.DataToProcess = QueueParameters.CalculationGranules;
					ParametersOfTaskCompletion.CalculationGrunulaFields = QueueParameters.CalculationGrunulaFields;
					StartProcessingDataChunks(ParametersOfTaskCompletion, WorkFlows);
						
				EndIf;
				
			EndIf;
		
		Else
			
			// While the calculation granules are being processed, the query result may be empty (dependency is taken into account).
			// Therefore, while the tasks are being processed, it is impossible to set the processing task to False
			If NumberOfFreeWorkThreads = NumberOfWorkThreads Then 
				ThereAreTasksToBeProcessed = False;
			EndIf;
			
		EndIf;
		
		If Not ParametersOfTaskCompletion.CompletingTasksDirectly Then
			
			While True Do

				ProcessCompletedBackgroundTasks(WorkFlows,
					TaskLaunchParameters["TaskQueues"].QueuesTable);
				NumberOfFreeWorkThreads = NumberOfWorkThreads - WorkFlows.Count();

				If NumberOfFreeWorkThreads > 0 Then
					Break;
				Else
					TMCommonUse.Pause(1);
				EndIf;

			EndDo;
			
		EndIf;

	EndDo;

EndProcedure

// Completing tasks in a non-operational queue based on a list of documents.
// 
// Parameters:
//  DocumentsArray - Undefined, Array of DocumentRef - Documents that need to be used to complete tasks. If
//  Undefined is passed as a parameter, all documents will be processed according to the specified type of task.
//  JobKind - CatalogRef.BackdateJobKinds - The type of task for which you need to complete
//															 tasks with a lower queue number.
//
Procedure CompleteTasksInNonOperationalQueueBasedOnListOfDocuments(DocumentsArray, JobKind) Export
	
	If TypeOf(DocumentsArray) = Type("Array") And DocumentsArray.Count() = 0 Then
		Return;
	EndIf;
	
	TaskQueues = BackdateJobQueueCached.TaskQueues();
	
	SetPrivilegedMode(True);
	UncheckCompletedWithErrorBasedOnDocuments(DocumentsArray, Undefined);
	SetPrivilegedMode(False);
	
	DocumentsTable = New ValueTable;
	DocumentsTable.Columns.Add("Document", Documents.AllRefsType());
	
	If Not DocumentsArray = Undefined Then
		CommonClientServer.SupplementTableFromArray(DocumentsTable, DocumentsArray, "Document");
	EndIf;
	
	ParametersForStartingTaskExecution = ParametersForStartingTaskExecution();
	ParametersForStartingTaskExecution.CompletingTasksBasedOnListOfDocuments = True;
	ParametersForStartingTaskExecution.DocumentsTable = DocumentsTable;
	ParametersForStartingTaskExecution.JobKind = JobKind;
	ParametersForStartingTaskExecution.Insert("TaskQueues", TaskQueues);
	
	CompleteTasksInNonOperationalQueue(ParametersForStartingTaskExecution);
	
	#Region TaskCompletionErrors

	Query = New Query;
	Query.SetParameter("JobKind", JobKind);
	Query.SetParameter("DocumentsList", DocumentsArray);
	SetRequestParametersByQueue(Query, TaskQueues);

	QueuesTable = TaskQueues.QueuesTable;

	Query.Text = "
	|SELECT DISTINCT
	|	Jobs.Document AS Document
	|FROM
	|	&TheTextOfASubquery AS Jobs";

	SubqueryTextTemplate = "
	|SELECT DISTINCT
	|	TableQueue.Document AS Document
	|FROM
	|	&TableQueue AS TableQueue
	|		INNER JOIN InformationRegister.JobQueueErrors AS ErrorRegister
	|		ON TableQueue.ErrorID = ErrorRegister.ErrorID
	|WHERE
	|	&TaskTypeField = &JobKind
	|	AND TableQueue.CompletedWithAnError
	|	AND &SelectionAccordingToListOfDocuments
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TableQueue.Document AS Document
	|FROM
	|	&TableQueue AS TableQueue
	|		INNER JOIN InformationRegister.JobQueueErrors AS ErrorRegister
	|		ON TableQueue.ErrorID = ErrorRegister.ErrorID
	|WHERE
	|	&QueueNumberField < CAST(&JobKind AS Catalog.BackdateJobKinds).QueueNumber
	|	AND TableQueue.CompletedWithAnError
	|	AND &SelectionAccordingToListOfDocuments";

	ArrayOfSubqueries = New Array;

	For Each CurrentQueue In QueuesTable Do

		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);

		If DocumentsArray = Undefined Then
			QueryTextQueues = StrReplace(QueryTextQueues, "&SelectionAccordingToListOfDocuments", "TRUE");
		Else
			QueryTextQueues = StrReplace(QueryTextQueues, "&SelectionAccordingToListOfDocuments",
				"TableQueue.Document IN (&DocumentsList)");
		EndIf;

		QueryTextQueues = StrReplace(QueryTextQueues, "&TaskTypeField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterTaskType), "&" + CurrentQueue.RequestParameterTaskType,
			"TableQueue.JobKind"));

		QueryTextQueues = StrReplace(QueryTextQueues, "&QueueNumberField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterQueueNumber), "&" + CurrentQueue.RequestParameterQueueNumber,
			"TableQueue.JobKind.QueueNumber"));

		ArrayOfSubqueries.Add(QueryTextQueues);

	EndDo;

	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin(True));
	Query.Text = StrReplace(Query.Text, "&TheTextOfASubquery", "(" + SubqueryText + ")");

	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	If Not Result.IsEmpty() Then

		Documents_With_Errors =  Result.Unload();
		NumberOfDocumentsWithErrors = Documents_With_Errors.Count();

		ExceptionParameter = ?(NumberOfDocumentsWithErrors = 1, Documents_With_Errors[0].Document, Format(
			NumberOfDocumentsWithErrors, "NG=3,0;"));

		ExceptionTextTemplate = ?(NumberOfDocumentsWithErrors = 1, NStr(
			"vi = 'Khi thực hiện nhiệm vụ kết chuyển bổ sung không hiện thời, đã xảy ra lỗi đối với chứng từ: %1. Chi tiết xem trong nhật ký sự kiện.';
			|ru = 'При выполнении заданий неоперативного допроведения возникли ошибки по документу: %1. Подробности в журнале регистрации.';
			|en = 'Errors occurred when performing jobs of backdate additional posting in the ""%1"" document. See the Event log for details.'; fa = 'Errors occurred when performing jobs of backdate additional posting in the ""%1"" document. See the Event log for details.';
			|it = 'Errors occurred when performing jobs of backdate additional posting in the ""%1"" document. See the Event log for details.';
			|pl = 'Errors occurred when performing jobs of backdate additional posting in the ""%1"" document. See the Event log for details.';
			|tr = 'Operasyonel olmayan ek düzenleme görevleri gerçekleştirilirken belgede hatalar oluştu: %1. Ayrıntılar için kayıt günlüğüne bakın.'",
			Common.DefaultLanguageCode()), NStr(
			"vi = 'Khi thực hiện nhiệm vụ kết chuyển bổ sung không hiện thời, đã xảy ra lỗi đối với %1 chứng từ. Chi tiết xem trong nhật ký sự kiện.';
			|ru = 'При выполнении заданий неоперативного допроведения возникли ошибки по %1 документам. Подробности в журнале регистрации.';
			|en = 'Errors occurred when performing jobs of backdate additional posting in the documents: %1. See the Event log for details.'; fa = 'Errors occurred when performing jobs of backdate additional posting in the documents: %1. See the Event log for details.';
			|it = 'Errors occurred when performing jobs of backdate additional posting in the documents: %1. See the Event log for details.';
			|pl = 'Errors occurred when performing jobs of backdate additional posting in the documents: %1. See the Event log for details.';
			|tr = 'Operasyonel olmayan ek düzenleme görevleri gerçekleştirilirken %1 belge kapsamında hatalar oluştu. Ayrıntılar için kayıt günlüğüne bakın.'",
			Common.DefaultLanguageCode()));

		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionTextTemplate,
			ExceptionParameter);

		TaskTypeDescription = TaskQueues.KindsOfTasks.Get(JobKind);
		If Not TaskTypeDescription = Undefined Then
			QueueData = TaskQueues.QueuesTable.FindRows(New Structure("Register",
				TaskTypeDescription["QueueRegister"]));
			QueueName = QueueData[0].QueueName;
			MetadataError = Metadata.InformationRegisters[QueueName];
		Else
			MetadataError = Metadata.CommonModules.BackdateJobQueue;
		EndIf;

		If NumberOfDocumentsWithErrors = 1 Then
			WriteErrorToEventLog(MetadataError, JobKind, ExceptionText);
		Else
			ErrorTemplate = NStr("vi = 'Đã xảy ra lỗi khi thực hiện nhiệm vụ %1 theo chứng từ %2';
								|ru = 'Выполнение задания %1 по документу %2 завершилось с ошибкой';
								|en = 'The ""%1"" job for the ""%2"" document is completed with an error'; fa = 'The ""%1"" job for the ""%2"" document is completed with an error';
								|it = 'The ""%1"" job for the ""%2"" document is completed with an error';
								|pl = 'The ""%1"" job for the ""%2"" document is completed with an error';
								|tr = '%2 belgesi kapsamındaki %1 görevi hata ile tamamlandı'",
				Common.DefaultLanguageCode());

			For Each RowWithError In Documents_With_Errors Do
				ErrorTextByDocument = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
					JobKind, RowWithError.Document);
				WriteErrorToEventLog(MetadataError, JobKind, ErrorTextByDocument, RowWithError.Document);
			EndDo;
		EndIf;

		Raise ExceptionText;

	EndIf;

#EndRegion
	
EndProcedure

// Execution of tasks in a non-operational queue for a document in a transaction.
// 
// Parameters:
//  Document - DocumentRef - The document to complete the tasks for.
//  JobKind - CatalogRef.BackdateJobKinds - The type of task for which you need to complete
//															 tasks with a lower queue number.
//
Procedure CompleteTasksOfNonOperationalQueueInDocumentTransaction(Document, JobKind) Export
	
	TaskQueues = BackdateJobQueueCached.TaskQueues();
	
	DocumentsTable = New ValueTable;
	DocumentsTable.Columns.Add("Document", Documents.AllRefsType());
	DocumentsTable.Add().Document = Document;

	ParametersForStartingTaskExecution = ParametersForStartingTaskExecution();
	ParametersForStartingTaskExecution.CompletingTasksBasedOnListOfDocuments = True;
	ParametersForStartingTaskExecution.DocumentsTable = DocumentsTable;
	ParametersForStartingTaskExecution.JobKind = JobKind;
	ParametersForStartingTaskExecution.PerformTasksInTransaction = True;
	ParametersForStartingTaskExecution.Insert("TaskQueues", TaskQueues);
	
	CompleteTasksInNonOperationalQueue(ParametersForStartingTaskExecution);
	
EndProcedure

// Checks if there is a running instance of the control thread and if the control thread is not active, it starts 
// the execution of tasks in the non-operational queue with selection by type.
// 
// Parameters:
//  JobKind - CatalogRef.BackdateJobKinds - Tasks will be received for completion for all documents that match 
// the value passed in the parameter, as well as all tasks that have a lower completion number.
//
Procedure CompleteTasksInNonOperationalQueueWithSelectionByType(JobKind) Export
	
	If Common.FileInfobase() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	TaskLaunchParameters = ParametersForStartingTaskExecution();
	TaskLaunchParameters.JobKind = JobKind;
	TaskLaunchParameters.SelectionByTaskType = True;
	
	While True Do
		
		BackgroundJobManagingThread = CheckStartExecutionOfNonOperationalTaskQueue(TaskLaunchParameters);
		
		If BackgroundJobManagingThread <> Undefined Then
			Break;
		Else
			TMCommonUse.Pause(5);
		EndIf;

	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Starts background execution of tasks in a non-operational queue with selection by type.
// 
// Parameters:
//  JobKind - CatalogRef.BackdateJobKinds - Tasks will be received for completion for all documents that match 
// the value passed in the parameter, as well as all tasks that have a lower completion number.
//
Procedure StartBackgroundExecutionOfTasksInNonOperationalQueueWithSelectionByType(JobKind) Export
	
	If Common.FileInfobase() Then
		Return;
	EndIf;
	
	BackgroundJobParameters = New Array;
	BackgroundJobParameters.Add(JobKind);
	
	SetPrivilegedMode(True);
	BackgroundJobDescription = NStr(
		"vi = 'Khởi chạy việc thực thi nhiệm vụ trên nền của hàng đợi không tức thời có lọc theo dạng';
		|ru = 'Запуск фонового выполнения заданий неоперативной очереди с отбором по виду';
		|en = 'Run background execution of backdate queue jobs with filter by type'; fa = 'Run background execution of backdate queue jobs with filter by type';
		|it = 'Run background execution of backdate queue jobs with filter by type';
		|pl = 'Run background execution of backdate queue jobs with filter by type';
		|tr = 'Türe göre filtreyle operasyonel olmayan kuyruk işlerinin arka plan yürütülmesinin başlatılması'");
	Var_Key = String(New UUID);
	BackgroundJobs.Execute(
		"BackdateJobQueue.CompleteTasksInNonOperationalQueueWithSelectionByType", BackgroundJobParameters,
		Var_Key, BackgroundJobDescription);
	SetPrivilegedMode(False);
	
EndProcedure

// Error entry in the registration Log.
// 
// Parameters:
//  MetadataError - MetadataObject - Metadata used to record an error in the log
//  JobKind - CatalogRef.BackdateJobKinds - The type of task for which the execution error is registered
//  ErrorText -String - Detailed error text
//  Document - DocumentRef, String - The document or tuple being processed
//
Procedure WriteErrorToEventLog(MetadataError, JobKind, ErrorText, Document = Undefined) Export
	
	EventName = StringFunctionsClientServer.SubstituteParametersToString(NStr(
		"vi = 'Kết chuyển bổ sung bổ sung chứng từ không hiện thời (%1)';
		|ru = 'Неоперативное допроведение документов (%1)';
		|en = 'Backdate additional document posting (%1)'; fa = 'Backdate additional document posting (%1)';
		|it = 'Backdate additional document posting (%1)';
		|pl = 'Backdate additional document posting (%1)';
		|tr = 'Belgelerin operasyonel olmayan ek düzenlemesi (%1)'", Common.DefaultLanguageCode()), JobKind);

	WriteLogEvent(EventName, EventLogLevel.Error,
		MetadataError, Document, ErrorText);

EndProcedure

// Deleting queue tasks based on the passed IDs.
// 
// Parameters:
//  QueueName - String - Queue Register Name
//  TaskIds - Array of UUID - List Of Task Ids To Delete
//
Procedure DeleteQueueTasks(QueueName, TaskIds) Export

	If TaskIds.Count() = 0 Then
		Return;
	EndIf;
	
	TaskQueues = BackdateJobQueueCached.TaskQueues();
	
	Query = New Query;
	Query.Text = "
	|SELECT *
	|FROM
	|	&TableQueue AS Queue
	|WHERE
	|	Queue.RecordID IN (&TaskIds)";
	Query.Text = StrReplace(Query.Text,"&TableQueue" , "InformationRegister." + QueueName);
	
	TableOfPortionsOfIdentifiers = New ValueTable;
	TableOfPortionsOfIdentifiers.Columns.Add("PortionNumber", Common.TypeDescriptionNumber(10,0));
	TableOfPortionsOfIdentifiers.Columns.Add("JobID", New TypeDescription("UUID"));
	TableOfPortionsOfIdentifiers.Indexes.Add("PortionNumber");
	
	CurrentPortionNumber = 1;
	CurPortionSize = 0;
	For Each CurrentID In TaskIds Do
		
		CurPortionSize = CurPortionSize + 1;
		
		NewRow = TableOfPortionsOfIdentifiers.Add();
		NewRow.PortionNumber = CurrentPortionNumber;
		NewRow.JobID = CurrentID;
		
		If CurPortionSize = 1000 Then
			CurrentPortionNumber = CurrentPortionNumber + 1;
			CurPortionSize = 0;
		EndIf;
		 
	EndDo;
	
	ErrorIds = New Array;
		
	For PortionNumber = 1 To CurrentPortionNumber Do
		
		Query.SetParameter("TaskIds", TableOfPortionsOfIdentifiers.Copy(
			New Structure("PortionNumber", PortionNumber)).UnloadColumn("JobID"));
		
		SetPrivilegedMode(True);
		
		TaskRecords = Query.Execute().Unload();
		
		If TaskRecords.Count() > 0 Then

			RecordSet = InformationRegisters[QueueName].CreateRecordSet();
			RecordSet.DataExchange.Load = True;
			RecordSet.Load(TaskRecords);
			RecordSet.Write(ReplacementMode.Delete);

			CommonClientServer.SupplementArray(ErrorIds, TaskRecords.UnloadColumn(
				"ErrorID"), True);

		EndIf;
		
		SetPrivilegedMode(False);
		
	EndDo;

	DeletingQueueErrorRegisterEntries(TaskQueues, ErrorIds);
	CheckForTasksWithHigherPriority(TaskQueues);

EndProcedure

// Error data is processed based on the submitted list of documents and the type of task.
//
// Parameters:
//  DocumentsList - Undefined, Array of DocumentRef - Processed Documents
//  JobKind - Undefined, CatalogRef.BackdateJobKinds - Type of task
//
Procedure UncheckCompletedWithErrorBasedOnDocuments(DocumentsList, JobKind = Undefined) Export

	TaskQueues = BackdateJobQueueCached.TaskQueues();

	QueuesTable = TaskQueues.QueuesTable;

	ErrorIds = New Array;

	For Each CurrentQueue In QueuesTable Do

		TaskRegisterManager = CurrentQueue.TaskRegisterManager;
		TaskRegisterManager.UncheckCompletedWithErrorBasedOnDocuments(DocumentsList, ErrorIds,
			JobKind);

	EndDo;

	DeletingQueueErrorRegisterEntries(TaskQueues, ErrorIds);
	
EndProcedure

// In one transaction, entries marked "Completed with an error" are batch deleted from the queue register according to the transmitted table of tasks with errors and
// new tasks are created in the queue register without the mark "Completed with an error" according to the transmitted table of new tasks for registration.
// 
// Parameters:
//  QueueRegisterManager - InformationRegisterManager - Queue register Manager.
//  TableOfTasksWithErrorsToDelete - ValueTable - Table of tasks to delete:
//   * Dimension - Arbitrary - The queue register measurement field. 
//   The table should list the fields corresponding to all dimensions of the queue register.
//   * ErrorID - UUID - ID of the error in the task entry.
//  TableOfTasksForRegistration - ValueTable - The table of tasks for registration (see the Task formationtable in the Queue Register Manager module)
//  ErrorIds - Array of UUID - Error IDs.
Procedure DeleteTasksWithErrorsAndRegisterNewOnesWithoutErrors(QueueRegisterManager, TableOfTasksWithErrorsToDelete, TableOfTasksForRegistration, ErrorIds) Export
	
	BeginTransaction();

	Try

		QueueErrorIds = TableOfTasksWithErrorsToDelete.UnloadColumn("ErrorID");

		SetPrivilegedMode(True);
		
		RecordSet = QueueRegisterManager.CreateRecordSet();
		RecordSet.Load(TableOfTasksWithErrorsToDelete);
		RecordSet.Write(ReplacementMode.Delete);
		
		QueueRegisterManager.CreateTasksBasedOnDataFromValueTable(TableOfTasksForRegistration);
		
		SetPrivilegedMode(False);

		CommitTransaction();

	Except

		RollbackTransaction();

		QueueErrorIds = New Array;

		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());

		Event = NStr("ru = 'Неоперативная очередь заданий: снятие признака ""Выполнено с ошибкой""';
					|vi = 'Неоперативная очередь заданий: снятие признака ""Выполнено с ошибкой""';
					|en = 'Неоперативная очередь заданий: снятие признака ""Выполнено с ошибкой""'; fa = 'Неоперативная очередь заданий: снятие признака ""Выполнено с ошибкой""';
					|it = 'Неоперативная очередь заданий: снятие признака ""Выполнено с ошибкой""';
					|pl = 'Неоперативная очередь заданий: снятие признака ""Выполнено с ошибкой""';
					|tr = 'Неоперативная очередь заданий: снятие признака ""Выполнено с ошибкой""'",
			Common.DefaultLanguageCode());

		WriteLogEvent(Event, EventLogLevel.Error, , , ErrorText);
		
		If TransactionActive() Then
			Raise ErrorText;
		EndIf;

	EndTry;

	CommonClientServer.SupplementArray(ErrorIds, QueueErrorIds, True);
	TableOfTasksWithErrorsToDelete.Clear();
	TableOfTasksForRegistration.Clear();
	
EndProcedure

// Parameters of a routine task for executing tasks in a non-operational queue.
// These parameters are used in the form of processing the "Month Closing Operation" in order to reflect on the form a hyperlink to setting up a routine task.
// 
// Returns:
//  Structure - Parameters of the routine task of additional verification of documents:
// * ScheduledJobID - Undefined, UUID - ID of the routine task
// * ScheduledJobUsed - Boolean - Indicates that a routine task is being used 
Function ParametersOfRoutineTaskInNonOperationalQueue() Export
	
	ScheduledJobParameters = New Structure;
	ScheduledJobParameters.Insert("ScheduledJobID", Undefined);
	ScheduledJobParameters.Insert("ScheduledJobUsed", False);
	
	FileInfobase = Common.FileInfobase();
	
	If Not FileInfobase And GetFunctionalOption("NewOnlineARAPAccounting") Then

		SetPrivilegedMode(True);
		ScheduledJobID = ScheduledJobsServer.UUID(
			Metadata.ScheduledJobs.BackdateJobQueueExecution);
		ScheduledJobParameters.ScheduledJobID = ScheduledJobID;

		If Not ScheduledJobID = Undefined Then
			Job = ScheduledJobsServer.Job(ScheduledJobID);
			ScheduledJobParameters.ScheduledJobUsed = Job <> Undefined And Job.Use;
		EndIf;
		SetPrivilegedMode(False);

	EndIf;

	Return ScheduledJobParameters;
	
EndFunction

#Region ParametersOfDataProcessing

// The structure of the formation of data portions.
// 
// Returns:
//  Structure - The Structure Of The Formation Of Data Portions:
// * JobKind - CatalogRef.BackdateJobKinds - Type of task
// * MaximumBatch - Number - Maximum portion of calculation granules
// * BackgroundJobProcessing - Boolean - Indicates that tasks will be executed by background threads
// * DocumentsTable - ValueTable - :
// ** Document - DocumentRef
Function StructureOfFormationOfDataPortions() Export

	StructureOfFormationOfDataPortions = New Structure;
	StructureOfFormationOfDataPortions.Insert("JobKind", Catalogs.BackdateJobKinds.EmptyRef());
	StructureOfFormationOfDataPortions.Insert("MaximumBatch", 0);
	StructureOfFormationOfDataPortions.Insert("BackgroundJobProcessing", True);
	
	DocumentsTable = New ValueTable();
	DocumentsTable.Columns.Add("Document", Documents.AllRefsType());
	StructureOfFormationOfDataPortions.Insert("DocumentsTable", DocumentsTable);

	Return StructureOfFormationOfDataPortions;

EndFunction

// Structure of task completion parameters.
// 
// Returns:
//  Structure - Structure of task completion parameters:
// * CompletingTasksDirectly - Boolean - If True, then the jobs will not be executed in the background job
// * QueueRegisterName - String - Queue Register Name
// * TaskRegisterManager - Undefined - Task Register Manager
// * CompletingTasksInTransaction - Boolean - Indicates that the tasks are performed in the document execution transaction.
// * DataForProcessing_ - ValueTable - Table of data portions to be processed.
// The composition of the table fields corresponds to the fields of the calculation granule of the queue register (see the Calculation Granule table() in the Queue Register Manager module).
// For each record of the table, information about the number of the data processing portion is additionally stored.
// * DataToProcess - ValueTable - A table with data that is already being processed.
//The composition of the table fields corresponds to the fields of the calculation granule of the queue register (see the Calculation Granule table() in the Queue Register Manager module).
//For each table entry, additional information is stored about the type of job being processed and the workflow identifier.
// * JobKind - CatalogRef.BackdateJobKinds - Type of task to be processed.
// * QueueRegister - CatalogRef.MetadataObjectIDs - Queue register.
// * ThreadsCount - Number - The number of free streams.
// * CalculationGrunulaFields - String - Comma-separated list of job queue register fields.
Function ParametersOfTaskCompletion() Export

	ParametersOfTaskCompletion = New Structure;
	ParametersOfTaskCompletion.Insert("CompletingTasksDirectly", False);
	ParametersOfTaskCompletion.Insert("QueueRegisterName", "");
	ParametersOfTaskCompletion.Insert("TaskRegisterManager", Undefined);
	ParametersOfTaskCompletion.Insert("CompletingTasksInTransaction", False);
	ParametersOfTaskCompletion.Insert("DataForProcessing_", New ValueTable);
	ParametersOfTaskCompletion.Insert("JobKind", Catalogs.BackdateJobKinds.EmptyRef());
	ParametersOfTaskCompletion.Insert("QueueRegister", Catalogs.MetadataObjectIDs.EmptyRef());
	ParametersOfTaskCompletion.Insert("DataToProcess", New ValueTable);
	ParametersOfTaskCompletion.Insert("ThreadsCount", 0);
	ParametersOfTaskCompletion.Insert("CalculationGrunulaFields", "");
	
	Return ParametersOfTaskCompletion;

EndFunction

// Data portion processing parameters.
// 
// Returns:
//  Structure - Data Portion Processing Parameters:
// * JobKind - CatalogRef.BackdateJobKinds - The type of task for which the data portion will be processed.
// * DataPortion - ValueTable - A table with a description of the calculation granules for tasks.
// * QueueRegisterName - String - Name of the queue register.
// * CompletingTasksInTransaction - Boolean - Indicates that the tasks are performed in the document execution transaction.
Function DataPortionProcessingParameters() Export

	DataParameters = New Structure;
	DataParameters.Insert("DataPortion", New ValueTable);
	DataParameters.Insert("QueueRegisterName", "");
	DataParameters.Insert("CompletingTasksInTransaction", False);
	DataParameters.Insert("JobKind", Catalogs.BackdateJobKinds.EmptyRef());
	
	Return DataParameters;

EndFunction

// The structure of the description of queue parameters by default.
// Used when forming the queue table: See BackdateJobQueueCached.TaskQueues.
// Defines the basic parameters for overriding requests specific to each of the job register.
// Used in the Queue description function of the Task Register manager module.
// 
// Returns:
//  Structure - Structure Of The Description Of Queue Parameters:
// * RequestParameterTaskType - String - Describes the parameters of the Task view request
// * TaskTypeValue - CatalogRef.BackdateJobKinds - The type of task specified in the request parameter.
// * RequestParameterQueueNumber - String - Describes the parameter of the Queue Number field
// * QueueNumberValue - Number - Queue number to be specified in the request parameter.
// * QueryTextCalculationGranulesInProcessing - String - Query Text for selecting calculation granules.
// * QueryTextExcludedDocuments - String - The text of the request for the selection of granule calculation documents.
// * ProcessedGranulesTableName - String - The name of the temporary table containing information on the pellets being processed.
Function StructureOfDescriptionOfQueueParameters() Export
	
	DetailsStructure1 = New Structure;
	DetailsStructure1.Insert("RequestParameterTaskType", "");
	DetailsStructure1.Insert("TaskTypeValue", Catalogs.BackdateJobKinds.EmptyRef());
	DetailsStructure1.Insert("RequestParameterQueueNumber", "");
	DetailsStructure1.Insert("QueueNumberValue", 0);
	
	DetailsStructure1.Insert("QueryTextCalculationGranulesInProcessing", "");
	DetailsStructure1.Insert("QueryTextExcludedDocuments", "");
	DetailsStructure1.Insert("ProcessedGranulesTableName", "");
	
	Return DetailsStructure1;
	
EndFunction

#EndRegion

#EndRegion

#Region MonthEndTransactions

#Region AdditionalDocumentPosting

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_CalculationOfDocumentAmountsInAccountingCurrenciesAndRepostingFinancialRegisters(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.AdditionalDocumentPosting);
	
	NewRow.MultilingualName = "vi = 'Kết chuyển bổ sung chứng từ';
								|ru = 'Допроведение документов';
								|en = 'Additional document posting';
								|it = 'Additional document posting';
								|pl = 'Additional document posting';
								|tr = 'Ek belge düzenlemesi'"; // @NStr-1
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"BackdateJobQueue.Use_CalculationOfAmountsOfDocumentsInAccountingCurrenciesAndRepostingOfFinancialRegisters");
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"BackdateJobQueue.Registration_CalculationOfAmountsOfDocumentsInAccountingCurrenciesAndRepostingOfFinancialRegisters");
	NewRow.ActionExecute = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"BackdateJobQueue.Perform__CalculationOfAmountsOfDocumentsInAccountingCurrenciesAndRepostingFinancialRegisters");
		NewRow.PerformedAtPreliminaryClosingOfMonth = True;
EndProcedure

// Determines the Status of the closing stage of the month
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Use_CalculationOfAmountsOfDocumentsInAccountingCurrenciesAndRepostingOfFinancialRegisters(HandlerParameters) Export
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then

		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters, NStr("vi = 'Không có nhiệm vụ cần kết chuyển lại chứng từ';
									|ru = 'Отсутствуют задания к допроведению документов';
									|en = 'There are no jobs for additional document posting'; fa = 'There are no jobs for additional document posting';
									|it = 'There are no jobs for additional document posting';
									|pl = 'There are no jobs for additional document posting';
									|tr = 'Belgelerin ek düzenlemesi için herhangi bir görev bulunmamaktadır'",
			Common.DefaultLanguageCode()));

		Return;

	EndIf;
	
	TaskQueues = BackdateJobQueueCached.TaskQueues();
	QueuesTable = TaskQueues.QueuesTable;
		
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT
	|	MIN(BEGINOFPERIOD(TasksToProcess.TaskPeriod, MONTH)) AS Month
	|FROM
	|	&TextOfNestedRequestPeriod AS TasksToProcess
	|HAVING
	|	NOT MIN(BEGINOFPERIOD(TasksToProcess.TaskPeriod, MONTH)) IS NULL
	|";
	
	SubqueryTextPeriodTemplate = "
	|SELECT
	|	MIN(CASE
	|		WHEN TableQueue.TaskPeriod = DATETIME(1, 1, 1)
	|			THEN &EndOfPeriod
	|		ELSE TableQueue.TaskPeriod
	|	END) AS TaskPeriod
	|FROM
	|	&TableQueue AS TableQueue
	|WHERE
	|	TableQueue.Organization IN (&CompanyArray)
	|	AND TableQueue.TaskPeriod <= &EndOfPeriod
	|	AND &SelectionByChangeControlPeriod";
		
	ArrayOfSubqueriesPeriod = New Array;
	For Each CurrentQueue In QueuesTable Do
		
		QueryTextQueues = StrReplace(SubqueryTextPeriodTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);
		
		If CurrentQueue.AvailabilityOfChangeControlPeriodField Then
			QueryTextQueues = StrReplace(QueryTextQueues, "&SelectionByChangeControlPeriod", "TableQueue.ChangeControlPeriod < DATETIME(3999, 1, 1)");
		Else
			QueryTextQueues = StrReplace(QueryTextQueues, "&SelectionByChangeControlPeriod", "TRUE");
		EndIf;
		
		ArrayOfSubqueriesPeriod.Add(QueryTextQueues);
		
	EndDo;
	
	SubqueryTextPeriod = StrConcat(ArrayOfSubqueriesPeriod, TMCommonUse.QuerySeparatorInJoin());

	Query.Text = StrReplace(Query.Text, "&TextOfNestedRequestPeriod", "(" + SubqueryTextPeriod + ")");
	Selection = Query.Execute().Select();

	ThereAreTasksForStageOfMonthEndClosing = False;
	
	If Selection.Next() Then

		If Not ValueIsFilled(Selection.Month) Then
			Return;
		EndIf;
		
		ThereAreTasksForStageOfMonthEndClosing = True;
		
		MonthOfTaskProcessing = Selection.Month;

		HandlerParameters.Data_Stage.SettlementStartDate = MonthOfTaskProcessing;

		StateTemplate = NStr("vi = 'Bắt đầu từ kỳ %1 theo chứng từ, cần xử lý các nhiệm vụ';
							|ru = 'Начиная с периода %1 по документам требуется обработать задания';
							|en = 'Starting from the period of %1, process jobs for documents'; fa = 'Starting from the period of %1, process jobs for documents';
							|it = 'Starting from the period of %1, process jobs for documents';
							|pl = 'Starting from the period of %1, process jobs for documents';
							|tr = '%1 döneminden itibaren belgeler kapsamında görevlerin işlenmesi gerekmektedir'",
			Common.DefaultLanguageCode());

		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters, StringFunctionsClientServer.SubstituteParametersToString(
				StateTemplate, CostCalculationProtocol.PresentationOfCalculationPeriod(MonthOfTaskProcessing)));

	EndIf;
	
	// Check for the presence of transferred RegisteredRecords of old calculations
	If Not ThereAreTasksForStageOfMonthEndClosing Then
		Query.Text = 
		"SELECT
		|	MIN(JobsForMonthEndClosing.Month) AS Month,
		|	JobsForMonthEndClosing.Organization AS Organization
		|INTO TTOpenPeriods
		|FROM
		|	InformationRegister.JobsForMonthEndClosing AS JobsForMonthEndClosing
		|		LEFT JOIN InformationRegister.SetUpLockFromChanges AS SetUpLockFromChanges
		|		ON JobsForMonthEndClosing.Organization = SetUpLockFromChanges.Organization
		|WHERE
		|	JobsForMonthEndClosing.Operation = VALUE(Catalog.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation)
		|	AND JobsForMonthEndClosing.Month >= ISNULL(SetUpLockFromChanges.LockUntil, DATETIME(1, 1, 1))
		|	AND JobsForMonthEndClosing.Organization IN (&CompanyArray)
		|GROUP BY
		|	JobsForMonthEndClosing.Organization
		|
		|INDEX BY
		|	Month,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	Calculations.Period AS Period,
		|	Dimension.Organization AS Organization,
		|	Calculations.DocumentRecorder AS DocumentRecorder
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
		|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Dimension
		|		ON Calculations.AccountingDimensionByPartners = Dimension.Ref
		|		AND Dimension.Organization IN (&CompanyArray)
		|	INNER JOIN TTOpenPeriods AS OpenedPeriods
		|		ON Dimension.Organization = OpenedPeriods.Organization
		|		AND Calculations.Period >= OpenedPeriods.Month
		|WHERE
		|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Calculations.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|	AND Calculations.FinRecordID = &IsBlankString
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	Calculations.Period AS Period,
		|	Dimension.Organization AS Organization,
		|	Calculations.DocumentRecorder AS DocumentRecorder
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
		|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Dimension
		|		ON Calculations.AccountingDimensionByPartners = Dimension.Ref
		|		AND Dimension.Organization IN (&CompanyArray)
		|	INNER JOIN TTOpenPeriods AS OpenedPeriods
		|		ON Dimension.Organization = OpenedPeriods.Organization
		|		AND Calculations.Period >= OpenedPeriods.Month
		|WHERE
		|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Calculations.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|	AND Calculations.FinRecordID = &IsBlankString
		|";
		Query.SetParameter("IsBlankString", "");
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			ThereAreTasksForStageOfMonthEndClosing = True;
			StateTemplate = NStr("ru = 'Начиная с периода %1 требуется допроведение по регистрам расчетов по срокам';
								|vi = 'Starting from period %1, additional document posting of calculation registers by due dates is required';
								|en = 'Starting from period %1, additional document posting of calculation registers by due dates is required'; fa = 'Starting from period %1, additional document posting of calculation registers by due dates is required';
								|it = 'Starting from period %1, additional document posting of calculation registers by due dates is required';
								|pl = 'Starting from period %1, additional document posting of calculation registers by due dates is required';
								|tr = '%1 döneminden itibaren vadelere göre hesapla ek kaydetme gerekiyor'",
				Common.DefaultLanguageCode());

			MonthEndTransactionsServer.SetStateFailed(
				HandlerParameters, StringFunctionsClientServer.SubstituteParametersToString(
					StateTemplate, CostCalculationProtocol.PresentationOfCalculationPeriod(MonthOfTaskProcessing)));
		EndIf;
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	Query.SetParameter("ThereAreTasksForStageOfAdditionalVerificationOfDocuments", ThereAreTasksForStageOfMonthEndClosing);
	
	ArrayOfRequestTexts = New Array;
	ArrayOfRequestTexts.Add(QueryTextReconciliationOfAmountsOfOperationalAndFinancialRegisters());
	
	QueryTextCustomers = "
	|SELECT DISTINCT
	|	Discrepancies.Document AS Recorder,
	|	Discrepancies.Organization AS Organization
	|INTO TT_DiscrepanciesClients
	|FROM
	|	SettlementsWithCustomersChanges AS Discrepancies";
	ArrayOfRequestTexts.Add(QueryTextCustomers);
	
	QueryTextVendors = "
	|SELECT
	|	Discrepancies.Document AS Recorder,
	|	Discrepancies.Organization AS Organization
	|INTO TT_DiscrepanciesSuppliers
	|FROM
	|	VendorsARAPAccountingChanges AS Discrepancies";
	ArrayOfRequestTexts.Add(QueryTextVendors);
	
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
		
	Query.Execute();
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.FindRecordersWithDiscrepanciesInMovementsOfAmountsInAccountingCurrenciesAndSettlementRegisters(
		Query.TempTablesManager, Query.Parameters.EndOfPeriod);
	
EndProcedure

// Defines a custom Presentation of the month's closing stage
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Registration_CalculationOfAmountsOfDocumentsInAccountingCurrenciesAndRepostingOfFinancialRegisters(HandlerParameters) Export
	
	HandlerParameters.Data_Stage.Description = NStr(
		"vi = 'Tính số tiền chứng từ theo tiền tệ kế toán và kết chuyển lại theo biểu ghi tài chính';
		|ru = 'Расчет сумм документов в валютах учета и перепроведение по финансовым регистрам';
		|en = 'Calculate document amounts in accounting currencies and repost in financial registers'; fa = 'Calculate document amounts in accounting currencies and repost in financial registers';
		|it = 'Calculate document amounts in accounting currencies and repost in financial registers';
		|pl = 'Calculate document amounts in accounting currencies and repost in financial registers';
		|tr = 'Muhasebe para birimleri cinsinde belge tutarlarının hesaplanması ve finansal kayıtlara yeniden gönderilmesi'");
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Thực hiện';
													|ru = 'Выполнить';
													|en = 'Run'; fa = 'اجرا';
													|it = 'Run';
													|pl = 'Run';
													|tr = 'Gerçekleştir'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

// Performs operations of operations at the closing stage of the month. In particular, before completing tasks, performs correction of Balances on mutual settlements
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Perform__CalculationOfAmountsOfDocumentsInAccountingCurrenciesAndRepostingFinancialRegisters(HandlerParameters) Export
	
	ClearCalculationExecutionProblems(HandlerParameters);
	
	TaskQueues = BackdateJobQueueCached.TaskQueues();
	
	#Region HandlingQueueTaskErrors
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	Query.Text = "
	|SELECT
	|	TasksToProcess.Document AS Document
	|FROM
	|	&TheTextOfASubquery AS TasksToProcess";
	
	SubqueryTextTemplate = "
	|SELECT DISTINCT
	|	TableQueue.Document AS Document
	|FROM
	|	&TableQueue AS TableQueue
	|WHERE
	|	TableQueue.Organization IN (&CompanyArray)
	|	AND TableQueue.TaskPeriod <= &EndOfPeriod
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			&TableQueue AS VZQueueTable
	|		WHERE
	|			TableQueue.Document = VZQueueTable.Document
	|			AND TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.JobQueueErrors AS ErrorRegister
	|				WHERE
	|					VZQueueTable.ErrorID = ErrorRegister.ErrorID))";
	
	ArrayOfSubqueries = New Array;
	For Each CurrentQueue In TaskQueues.QueuesTable Do
		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);
		ArrayOfSubqueries.Add(QueryTextQueues);
	EndDo;

	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin(True));
	Query.Text = StrReplace(Query.Text, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	
	ListOfDocumentsForErrorHandling = Query.Execute().Unload().UnloadColumn("Document");
	If ListOfDocumentsForErrorHandling.Count() > 0 Then
		UncheckCompletedWithErrorBasedOnDocuments(ListOfDocumentsForErrorHandling, Undefined);
	EndIf;

	#EndRegion
	
	RegisterTasksForRecalculatingCalculationsByTimeAfterSwitchingToOnline(HandlerParameters);
	
	MonthEndClosingCompleteTasksInNonOperationalQueue(HandlerParameters, TaskQueues);
	
	CheckResults = ToCheckRegisteredRecordsOfDocumentsInRegistersOfMutualSettlements(HandlerParameters);
	If CheckResults.ProblematicDocumentsAmountsInAccountingCurrencies.Count() > 0
		Or CheckResults.MWDiscrepanciesInSettlementRegisters <> Undefined Then
		CorrectRegisteredRecordsOfDocumentsInRegistersOfMutualSettlements(HandlerParameters, CheckResults, TaskQueues);
	EndIf;
	
	CheckAndRegisterProblemsWithCalculation(HandlerParameters, TaskQueues, Undefined);

EndProcedure

// System health checks related to the stage.
// 
// Parameters:
// 	TableOfChecks - See AuditOfSystemState.SystemStateCheckTable
//
Procedure DescriptionOfChecks_CalculationOfAmountsOfDocumentsInAccountingCurrenciesAndRepostingOfFinancialRegisters(TableOfChecks) Export
	
	#Region ReconciliationOfAmountsOfOperationalAndFinancialRegisters
	
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"DiscrepancyOfAmountsInOperationalAndFinancialRegistersOfMutualSettlements",
		Catalogs.MonthEndClosingOperations.AdditionalDocumentPosting,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"BackdateJobQueue.VerificationOfStage_DiscrepancyOfAmountsInOperationalAndFinancialRegistersOfMutualSettlements");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Sự khác biệt trong biểu ghi hạch toán';
			|ru = 'Расхождения в регистрах взаиморасчетов';
			|en = 'Discrepancies in the mutual settlement registers'; fa = 'Discrepancies in the mutual settlement registers';
			|it = 'Divergenze nei registri dei pagamenti reciproci';
			|pl = 'Odchylenie w rejestrach rozliczeń wzajemnych';
			|tr = 'Mutabakat kayıtlarında tutarsızlık'", Common.DefaultLanguageCode()),
		NStr("vi = 'Không thể có các chứng từ tồn tại chênh lệch trong các biểu ghi hạch toán công nợ';
			|ru = 'Не должно быть документов, по которым имеются расхождения в регистрах взаиморасчетов';
			|en = 'There must be no documents with discrepancies in AR/AP accounting registers'; fa = 'There must be no documents with discrepancies in AR/AP accounting registers';
			|it = 'There must be no documents with discrepancies in AR/AP accounting registers';
			|pl = 'There must be no documents with discrepancies in AR/AP accounting registers';
			|tr = 'Mutabakat kayıtlarında tutarsızlık bulunan herhangi bir belgenin bulunmaması gerekmektedir'", Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region DocumentAmountsInAccountingCurrency
	
	PresentationOfAmountOfDocumentsInAccountingCurrencies = Metadata.InformationRegisters.DocumentAmountsInAccountingCurrency.Presentation();
	
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"DiscrepanciesInMovementsInRegistersOfMutualSettlementsAndRegisterOfAmountOfDocumentsInAccountingCurrencies",
		Catalogs.MonthEndClosingOperations.AdditionalDocumentPosting,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"BackdateJobQueue.VerificationOfStage_DiscrepanciesInMovementsInRegistersOfMutualSettlementsAndRegisterOfAmountOfDocumentsInAccountingCurrencies");
	
	TemplateOfDescription = NStr(
		"ru = 'Не должно быть документов, по которым имеются расхождения в движениях регистров взаиморасчетов и регистру ""%1""';
		|vi = 'There must be no documents with discrepancies in AR/AP accounting and ""%1"" register records';
		|en = 'There must be no documents with discrepancies in AR/AP accounting and ""%1"" register records'; fa = 'There must be no documents with discrepancies in AR/AP accounting and ""%1"" register records';
		|it = 'There must be no documents with discrepancies in AR/AP accounting and ""%1"" register records';
		|pl = 'There must be no documents with discrepancies in AR/AP accounting and ""%1"" register records';
		|tr = 'Mutabakat kayıtlarının hareketlerinde ve ""%1"" kaydında tutarsızlıkların olduğu belgeler bulunmamalıdır'",
		Common.DefaultLanguageCode());
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription, NStr(
		"vi = 'Sự khác biệt trong biểu ghi hạch toán';
		|ru = 'Расхождения в регистрах взаиморасчетов';
		|en = 'Discrepancies in the mutual settlement registers'; fa = 'Discrepancies in the mutual settlement registers';
		|it = 'Divergenze nei registri dei pagamenti reciproci';
		|pl = 'Odchylenie w rejestrach rozliczeń wzajemnych';
		|tr = 'Mutabakat kayıtlarında tutarsızlık'", Common.DefaultLanguageCode()),
		StringFunctionsClientServer.SubstituteParametersToString(TemplateOfDescription,
		PresentationOfAmountOfDocumentsInAccountingCurrencies));
		
	#EndRegion
	
EndProcedure

// Registration of errors in the event of divergence of Registered Records in financial and operational registers of mutual settlements.
// 
// Parameters:
// 	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
//
Procedure VerificationOfStage_DiscrepancyOfAmountsInOperationalAndFinancialRegistersOfMutualSettlements(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Recorder", NStr("vi = 'Chứng từ';
									|ru = 'Документ';
									|en = 'Document'; fa = 'سند';
									|it = 'Documento';
									|pl = 'Dokument';
									|tr = 'Belge'", Common.DefaultLanguageCode()));
	FieldList.Add("Organization", NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Firma';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	
	PresentationTemplateForCalculationRegisters = NStr("vi = ' ""%1"" và ""%2""';
														|ru = ' ""%1"" и ""%2""';
														|en = ' ""%1"" and ""%2""'; fa = ' ""%1"" and ""%2""';
														|it = ' ""%1"" and ""%2""';
														|pl = ' ""%1"" and ""%2""';
														|tr = ' ""%1"" ve ""%2""'", Common.DefaultLanguageCode());
	
	PresentationOfRegistersOfSettlementsWithClients = StringFunctionsClientServer.SubstituteParametersToString(PresentationTemplateForCalculationRegisters,
		Metadata.AccumulationRegisters.CustomersARAPAccounting.Presentation(),
		Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Presentation());
	
	PresentationOfRegistersOfSettlementsWithSuppliers = StringFunctionsClientServer.SubstituteParametersToString(PresentationTemplateForCalculationRegisters,
		Metadata.AccumulationRegisters.VendorsARAPAccounting.Presentation(),
		Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Presentation());
	
	RegistrationParametersClients = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TT_DiscrepanciesClients", NStr(
		"vi = 'Đã phát hiện các chứng từ có chênh lệch bản ghi kết chuyển trong các biểu ghi';
		|ru = 'Обнаружены документы, по которым различаются движения в регистрах';
		|en = 'Documents with discrepancies in register records are found'; fa = 'Documents with discrepancies in register records are found';
		|it = 'Documents with discrepancies in register records are found';
		|pl = 'Documents with discrepancies in register records are found';
		|tr = 'Kayıtlardaki hareketleri farklılaştıran belgeler tespit edildi'",
		Common.DefaultLanguageCode()) + PresentationOfRegistersOfSettlementsWithClients, FieldList);
		
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParametersClients,
		"",
		Undefined,
		Enums.AccountingIssueSeverity.Warning);
		
	RegistrationParametersSuppliers = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TT_DiscrepanciesSuppliers", NStr(
		"vi = 'Đã phát hiện các chứng từ có chênh lệch bản ghi kết chuyển trong các biểu ghi';
		|ru = 'Обнаружены документы, по которым различаются движения в регистрах';
		|en = 'Documents with discrepancies in register records are found'; fa = 'Documents with discrepancies in register records are found';
		|it = 'Documents with discrepancies in register records are found';
		|pl = 'Documents with discrepancies in register records are found';
		|tr = 'Kayıtlardaki hareketleri farklılaştıran belgeler tespit edildi'",
		Common.DefaultLanguageCode()) + PresentationOfRegistersOfSettlementsWithSuppliers, FieldList);
		
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParametersSuppliers,
		"",
		Undefined,
		Enums.AccountingIssueSeverity.Warning);
	
EndProcedure

// Registration of a warning when discrepancies are detected in the Register Records of mutual settlements and the register of "Amounts of documents in accounting currencies".
// 
// Parameters:
// 	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
//
Procedure VerificationOfStage_DiscrepanciesInMovementsInRegistersOfMutualSettlementsAndRegisterOfAmountOfDocumentsInAccountingCurrencies(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Recorder", NStr("vi = 'Chứng từ';
									|ru = 'Документ';
									|en = 'Document'; fa = 'سند';
									|it = 'Documento';
									|pl = 'Dokument';
									|tr = 'Belge'", Common.DefaultLanguageCode()));
	FieldList.Add("Organization", NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Firma';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	
	PresentationOfAmountOfDocumentsInAccountingCurrencies = Metadata.InformationRegisters.DocumentAmountsInAccountingCurrency.Presentation();
	
	TemplateOfDescription = NStr(
		"ru = 'Обнаружены документы, по которым имеются расхождения в движениях регистров взаиморасчетов и регистру ""%1""';
		|vi = 'There are documents with discrepancies in AR/AP accounting and ""%1"" register records';
		|en = 'There are documents with discrepancies in AR/AP accounting and ""%1"" register records'; fa = 'There are documents with discrepancies in AR/AP accounting and ""%1"" register records';
		|it = 'There are documents with discrepancies in AR/AP accounting and ""%1"" register records';
		|pl = 'There are documents with discrepancies in AR/AP accounting and ""%1"" register records';
		|tr = 'Mutabakat kayıtlarındaki hareketlerin ve ""%1"" kaydındaki hareketlerin tutarsız olduğu belgeler tespit edildi'",
		Common.DefaultLanguageCode());
		
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfDescription,
		PresentationOfAmountOfDocumentsInAccountingCurrencies);
		
	RegistrationParametersClients = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"ProblematicDocumentsAmountsInAccountingCurrencies", ErrorText, FieldList);
		
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParametersClients,
		"",
		Undefined,
		Enums.AccountingIssueSeverity.Warning);
			
EndProcedure

#EndRegion

#Region NonOperationalVerificationOfDocumentsManBalance

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_PostingDocumentRegisteredRecordsInBalanceSheetStatement(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.PostingDocumentRegisteredRecordsInBalanceSheetStatement);
	
	NewRow.MultilingualName = "vi = 'Bảng cân đối kế toán quản trị';
								|ru = 'Управленческий баланс';
								|en = 'Balance sheet statement';
								|it = 'Bilancio gestionale';
								|pl = 'Bilans zarządczy';
								|tr = 'Yönetim bilançosu'"; // @NStr-1
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"BackdateJobQueue.Usage_ReflectionOfRegisteredRecordsOfDocumentsOnManagementBalanceSheet");
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"BackdateJobQueue.Design_ReflectionOfRegisteredRecordsOfDocumentsOnManagementBalanceSheet");
	NewRow.ActionExecute = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"BackdateJobQueue.Execute_ReflectionOfRegisteredRecordsOfDocumentsOnManagementBalanceSheet");
		NewRow.PerformedAtPreliminaryClosingOfMonth = True;
		
	NewRow.UpdateStateOfStages.Add(
		Catalogs.MonthEndClosingOperations.AdditionalDocumentPosting);
EndProcedure

// Determines the Status of the closing stage of the month
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Usage_ReflectionOfRegisteredRecordsOfDocumentsOnManagementBalanceSheet(HandlerParameters) Export
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Or Not GetFunctionalOption(
		"UseBalanceSheetStatement") Then

		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters, NStr(
			"vi = 'Không có nhiệm vụ cần phản ánh các bản ghi kết chuyển chứng từ trong bảng cân đối kế toán quản trị';
			|ru = 'Отсутствуют задания к отражению движений документов в управленческом балансе';
			|en = 'There are no jobs for recording document records in the balance sheet statement'; fa = 'There are no jobs for recording document records in the balance sheet statement';
			|it = 'There are no jobs for recording document records in the balance sheet statement';
			|pl = 'There are no jobs for recording document records in the balance sheet statement';
			|tr = 'Yönetim bilançosunda belge kayıtlarını yansıtmak için herhangi bir görev yoktur'",
			Common.DefaultLanguageCode()));

		Return;

	EndIf;
	
	TaskQueues = BackdateJobQueueCached.TaskQueues();

	QueuesTable = TaskQueues.QueuesTable;
		
	Query = New Query;
	SetRequestParametersByQueue(Query, TaskQueues);
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT
	|	MIN(BEGINOFPERIOD(TasksToProcess.TaskPeriod, MONTH)) AS Month
	|FROM
	|	&TextOfNestedRequestPeriod AS TasksToProcess
	|HAVING
	|	NOT MIN(BEGINOFPERIOD(TasksToProcess.TaskPeriod, MONTH)) IS NULL
	|";
	
	SubqueryTextPeriodTemplate = "
	|SELECT
	|	MIN(CASE
	|		WHEN TableQueue.TaskPeriod = DATETIME(1, 1, 1)
	|			THEN &EndOfPeriod
	|		ELSE TableQueue.TaskPeriod
	|	END) AS TaskPeriod
	|FROM
	|	&TableQueue AS TableQueue
	|WHERE
	|	TableQueue.Organization IN (&CompanyArray)
	|	AND TableQueue.TaskPeriod <= &EndOfPeriod
	|	AND &TaskTypeField = VALUE(Catalog.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords)";
	
	ArrayOfSubqueriesPeriod = New Array;
	For Each CurrentQueue In QueuesTable Do
		
		QueryTextQueues = StrReplace(SubqueryTextPeriodTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);
		QueryTextQueues = StrReplace(QueryTextQueues, "&TaskTypeField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterTaskType), "&" + CurrentQueue.RequestParameterTaskType,
			"TableQueue.JobKind"));
		ArrayOfSubqueriesPeriod.Add(QueryTextQueues);
		
	EndDo;
	
	SubqueryTextPeriod = StrConcat(ArrayOfSubqueriesPeriod, TMCommonUse.QuerySeparatorInJoin());

	Query.Text = StrReplace(Query.Text, "&TextOfNestedRequestPeriod", "(" + SubqueryTextPeriod + ")");
	
	Selection = Query.Execute().Select();

	If Selection.Next() Then

		If Not ValueIsFilled(Selection.Month) Then
			Return;
		EndIf;

		MonthOfTaskProcessing = Selection.Month;

		HandlerParameters.Data_Stage.SettlementStartDate = MonthOfTaskProcessing;

		StateTemplate = NStr("vi = 'Cần thực hiện nhiệm vụ từ kỳ %1';
							|ru = 'Требуется выполнение заданий с периода %1';
							|en = 'Perform jobs from the period of %1'; fa = 'Perform jobs from the period of %1';
							|it = 'Perform jobs from the period of %1';
							|pl = 'Perform jobs from the period of %1';
							|tr = '%1 döneminden itibaren görevlerin gerçekleştirilmesi gerekmektedir'",
			Common.DefaultLanguageCode());

		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters, StringFunctionsClientServer.SubstituteParametersToString(
				StateTemplate, CostCalculationProtocol.PresentationOfCalculationPeriod(MonthOfTaskProcessing)));

	EndIf;

EndProcedure

// Defines a custom Presentation of the month's closing stage
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Design_ReflectionOfRegisteredRecordsOfDocumentsOnManagementBalanceSheet(HandlerParameters) Export
	
	HandlerParameters.Data_Stage.Description = NStr("vi = 'Phản ánh các bản ghi kết chuyển theo bảng cân đối kế toán quản trị';
													|ru = 'Отражение движений по управленческому балансу';
													|en = 'Record balance sheet statement entries'; fa = 'Record balance sheet statement entries';
													|it = 'Record balance sheet statement entries';
													|pl = 'Record balance sheet statement entries';
													|tr = 'Yönetim bilançosuna göre hareketlerin yansıması'");
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Thực hiện';
													|ru = 'Выполнить';
													|en = 'Run'; fa = 'اجرا';
													|it = 'Run';
													|pl = 'Run';
													|tr = 'Gerçekleştir'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

// Performs operations of operations at the closing stage of the month
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Execute_ReflectionOfRegisteredRecordsOfDocumentsOnManagementBalanceSheet(HandlerParameters) Export
	
	ClearCalculationExecutionProblems(HandlerParameters);
	
	TaskQueues = BackdateJobQueueCached.TaskQueues();
	
	#Region HandlingQueueTaskErrors
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	SetRequestParametersByQueue(Query, TaskQueues);
	
	Query.Text = "
	|SELECT
	|	TasksToProcess.Document AS Document
	|FROM
	|	&TheTextOfASubquery AS TasksToProcess";
	
	SubqueryTextTemplate = "
	|SELECT DISTINCT
	|	TableQueue.Document AS Document
	|FROM
	|	&TableQueue AS TableQueue
	|WHERE
	|	TableQueue.Organization IN (&CompanyArray)
	|	AND TableQueue.TaskPeriod <= &EndOfPeriod
	|	AND &TaskTypeField = VALUE(Catalog.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords)
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			&TableQueue AS VZQueueTable
	|		WHERE
	|			TableQueue.Document = VZQueueTable.Document
	|			AND TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.JobQueueErrors AS ErrorRegister
	|				WHERE
	|					VZQueueTable.ErrorID = ErrorRegister.ErrorID))";
	
	ArrayOfSubqueries = New Array;
	For Each CurrentQueue In TaskQueues.QueuesTable Do
		
		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);
		
		QueryTextQueues = StrReplace(QueryTextQueues, "&TaskTypeField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterTaskType), "&" + CurrentQueue.RequestParameterTaskType,
			"TableQueue.JobKind"));
			
		ArrayOfSubqueries.Add(QueryTextQueues);
	EndDo;

	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin(True));
	Query.Text = StrReplace(Query.Text, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	
	ListOfDocumentsForErrorHandling = Query.Execute().Unload().UnloadColumn("Document");
	
	If ListOfDocumentsForErrorHandling.Count() > 0 Then
		UncheckCompletedWithErrorBasedOnDocuments(ListOfDocumentsForErrorHandling,
			Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords);
	EndIf;
		
	#EndRegion
	
	MonthEndClosingCompleteTasksInNonOperationalQueue(HandlerParameters, TaskQueues);

	CheckAndRegisterProblemsWithCalculation(HandlerParameters, TaskQueues,
		Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords);
	
EndProcedure

#EndRegion

#EndRegion

// Fills in an array of undivided data types that support link matching
// when uploading data to another information database.
// See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport 
//
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	Types.Add(Metadata.Catalogs.BackdateJobKinds);
	
EndProcedure

#EndRegion

#Region Private

#Region BackdateJobQueueExecution

// Returns task completion parameters.
// 
// Returns:
//  Structure - Task Completion Parameters:
// * FileInfobase - Boolean - A sign that the information base is running in the file version.
// * DebugMode - Boolean - Indicates that the database is running in debug mode.
// * Companies - Array of CatalogRef.Companies - List of organizations. This parameter is filled in only when the month is closed.
// * ClosingPeriod - Date - The closing period of the month. This parameter is filled in only when the month is closed.
// * MonthEndClosingModeIsFileInfobase - Boolean - A sign that the control thread is running in the month closing mode and the information base is running in the file version.
// * CompletingTasksBasedOnListOfDocuments - Boolean - Indicates that tasks on the list of documents will be performed outside the control thread.
// * DocumentsTable - Undefined, ValueTable - A table with a list of documents to be processed.
// * JobKind - CatalogRef.BackdateJobKinds - Type of task.
// According to the transmitted list of documents, all types of tasks will also be completed, on which the execution of the type of task specified in this parameter depends.
// * TaskQueues - See BackdateJobQueueCached.TaskQueues
// * PerformTasksInTransaction - Boolean - Indicates that the tasks will be executed in the document execution transaction
// * SelectionByTaskType - Boolean - Indicates that tasks will be received for completion for all documents that match 
// the value passed in the "Task View" property, as well as all tasks that have a lower completion number.
// * EndTimeOfControlThread - Date - The time after which the control thread should complete its work.
//
Function ParametersForStartingTaskExecution()
	
	ParametersForStartingTaskExecution = New Structure;
	ParametersForStartingTaskExecution.Insert("FileInfobase", Common.FileInfobase());
	ParametersForStartingTaskExecution.Insert("DebugMode", Common.DebugMode());
	ParametersForStartingTaskExecution.Insert("Companies", New Array);
	ParametersForStartingTaskExecution.Insert("ClosingPeriod", Date(1,1,1));
	ParametersForStartingTaskExecution.Insert("MonthEndClosingModeIsFileInfobase", False);
	ParametersForStartingTaskExecution.Insert("CompletingTasksBasedOnListOfDocuments", False);
	ParametersForStartingTaskExecution.Insert("DocumentsTable", Undefined);
	ParametersForStartingTaskExecution.Insert("JobKind", Catalogs.BackdateJobKinds.EmptyRef());
	ParametersForStartingTaskExecution.Insert("TaskQueues", BackdateJobQueueCached.TaskQueues());
	ParametersForStartingTaskExecution.Insert("PerformTasksInTransaction", False);
	ParametersForStartingTaskExecution.Insert("SelectionByTaskType", False);
	ParametersForStartingTaskExecution.Insert("EndTimeOfControlThread", Date(1, 1, 1, 0, 0, 0));
	
	Return ParametersForStartingTaskExecution;
	
EndFunction

// Checks for the presence of a running instance of the control thread and, if it is missing 
// , the control thread of the non-operational job queue is programmatically launched.
// 
// Parameters:
//  TaskLaunchParameters - See ParametersForStartingTaskExecution
// 
// Returns:
//  Undefined, BackgroundJob - Returns the background task of the control thread (if the launch was completed), or Undefined - if
// the background task of the control thread was not started.
Function CheckStartExecutionOfNonOperationalTaskQueue(TaskLaunchParameters = Undefined)
	
	BackgroundTaskOfControlThread = Undefined;
	
	NameOfMethodOfControlThread = "BackdateJobQueue.CompleteTasksInNonOperationalQueue";
	
	If Not ControlThreadIsRunning(NameOfMethodOfControlThread) Then
		
		Try
			
			SetPrivilegedMode(True);
			
			ExceptionReason = "StoppingWorkThreads";
			NameOfWorkerThreadMethod = "BackdateJobQueue.PerformPortionProcessingAsBackgroundTask";
			Filter = New Structure;
			Filter.Insert("MethodName", NameOfWorkerThreadMethod);
			Filter.Insert("State", BackgroundJobState.Active);
			BackgroundJobsWorkThread = BackgroundJobs.GetBackgroundJobs(Filter);
			For Each ActiveTask In BackgroundJobsWorkThread Do
				ActiveTask.Cancel();
			EndDo;

			ExceptionReason = "StartingControlThread";
			BackgroundJobKey = "BackdateJobQueueExecution";
			BackgroundJobDescription = NStr("vi = 'Thực hiện hàng đợi nhiệm vụ không theo chế độ vận hành';
											|ru = 'Исполнение неоперативной очереди заданий';
											|en = 'Backdate job queue execution'; fa = 'اجرای صف وظایف عطف به ماسبق';
											|it = 'Backdate job queue execution';
											|pl = 'Backdate job queue execution';
											|tr = 'Faal olmayan iş kuyruğunun yürütülmesi'");
			BackgroundJobParameters = New Array;
			BackgroundJobParameters.Add(TaskLaunchParameters);
			BackgroundTaskOfControlThread = BackgroundJobs.Execute(NameOfMethodOfControlThread, BackgroundJobParameters,
				BackgroundJobKey, BackgroundJobDescription);
				
			SetPrivilegedMode(False);
			
		Except

			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());

			If ExceptionReason = "StartingControlThread" Then

				Event = NStr("vi = 'Khởi chạy luồng điều khiển của hàng đợi nhiệm vụ không tức thời';
							|ru = 'Запуск управляющего потока неоперативной очереди заданий';
							|en = 'Start the thread-of-control of the backdate job queue'; fa = 'Start the thread-of-control of the backdate job queue';
							|it = 'Start the thread-of-control of the backdate job queue';
							|pl = 'Start the thread-of-control of the backdate job queue';
							|tr = 'Operasyonel olmayan iş kuyruğunun kontrol akışının başlatılması'",
					Common.DefaultLanguageCode());

			Else

				Event = NStr("vi = 'Kết thúc luồng công việc của hàng đợi nhiệm vụ không tức thời';
							|ru = 'Завершение работы рабочих потоков неоперативной очереди заданий';
							|en = 'Complete the worker threads of the backdate job queue'; fa = 'Complete the worker threads of the backdate job queue';
							|it = 'Complete the worker threads of the backdate job queue';
							|pl = 'Complete the worker threads of the backdate job queue';
							|tr = 'Operasyonel olmayan iş kuyruğunun iş akışlarının sonlandırılması'",
					Common.DefaultLanguageCode());

			EndIf;

			WriteLogEvent(Event, EventLogLevel.Error, , , ErrorText);

		EndTry;
		
	EndIf;

	Return BackgroundTaskOfControlThread;
	
EndFunction

Function NumberOfBackdateJobQueueStreams()
	
	If Not SaaSOperations.DataSeparationEnabled()
		Or Not SaaSOperations.SeparatedDataUsageAvailable() Then
			
		SetPrivilegedMode(True);
		ThreadsCount = Constants.NumberOfBackdateJobQueueStreams.Get();
		SetPrivilegedMode(False);
		
		If ThreadsCount = 0 Then
			ThreadsCount = 8;
		EndIf;
		
	Else
		ThreadsCount = 1;
	EndIf;
	
	Return ThreadsCount;

EndFunction

// Analyzes the State of work threads.
// After the worker thread successfully processes the tasks, the control thread stops monitoring its State, 
// and the processed calculation granules become available for sampling again.
// If the workflow crashes, all pellets processed by it are marked with the "Completed with an error" sign.
// 
// Parameters:
//  WorkFlows - Array of See DescriptionOfWorkingThread - Array of used worker threads.
//  TaskQueues - See BackdateJobQueueCached.TaskQueues
Procedure ProcessCompletedBackgroundTasks(WorkFlows, TaskQueues)

	If WorkFlows.Count() = 0 Then
		Return;
	EndIf;
	
	FilterStructure1 = New Structure;
	
	WorkingThreadIndex = WorkFlows.Count() - 1;
	
	While WorkingThreadIndex >= 0 Do

		WorkFlow = WorkFlows[WorkingThreadIndex];

		ThreadID = WorkFlow.ThreadID;

		BackgroundJob = BackgroundJobs.FindByUUID(ThreadID);

		If BackgroundJob = Undefined
			Or Not BackgroundJob.State = BackgroundJobState.Active Then
			
			FilterStructure1.Insert("ThreadID", ThreadID);
			
			CurrentQueue = TaskQueues.Find(WorkFlow.QueueRegister, "Register");
			
			If Not CurrentQueue = Undefined Then
				
				If BackgroundJob <> Undefined And BackgroundJob.State = BackgroundJobState.Failed Then
					FixErrorsInCalculationGranulesInCaseOfEmergencyEndOfDataProcessing(
							CurrentQueue.CalculationGranules.Copy(FilterStructure1),
						CurrentQueue.FullNameOfQueue, WorkFlow.JobKind);
				EndIf;
				
				LinesToDelete = CurrentQueue.CalculationGranules.FindRows(FilterStructure1);
				For Each RowToDelete In LinesToDelete Do
					CurrentQueue.CalculationGranules.Delete(RowToDelete);
				EndDo;
				
			EndIf;

			WorkFlows.Delete(WorkingThreadIndex);
			
		EndIf;

		WorkingThreadIndex = WorkingThreadIndex - 1;

	EndDo;

EndProcedure

// Based on the transmitted table with calculation granules, returns the IDs of their entries in the queue register.
// 
// Parameters:
//  TableOfCalculationGranules - ValueTable - Table of calculation granules.The composition of the table fields must correspond 
//to the fields of the calculation granule of the queue register (see the Calculation Granule table() in the Queue Register Manager module).
//  FullNameOfTaskRegister - String - Full Name Of The Task Register
//  JobKind - Undefined, CatalogRef.BackdateJobKinds - Type of task
// 
// Returns:
//  ValueTable - Identifiers For Calculation Granules
Function IdentifiersForCalculationGranules(TableOfCalculationGranules, FullNameOfTaskRegister, JobKind = Undefined)
	
	RegisterManager = Common.ObjectManagerByFullName(FullNameOfTaskRegister);
	
	TableOfCalculationGranules = RegisterManager.TableOfCalculationGranules(); // ValueTable
	ColumnsOfCalculationGranuleTable = TableOfCalculationGranules.Columns;
	
	ArrayOfRequestTexts = New Array;
	
	#Region TableOfCalculationGranules
		
	TextTableOfCalculationGranules= "
	|SELECT
	|	CalculationGranules.*
	|INTO TT_CalculationGranules
	|FROM
	|	&TableOfCalculationGranules AS CalculationGranules";
	
	CalculationGranuleFields = New Array;
	For Each Field In ColumnsOfCalculationGranuleTable Do
		CalculationGranuleFields.Add(StrTemplate("CalculationGranules.%1 AS %1", Field.Name));
	EndDo;
	
	TextTableOfCalculationGranules = StrReplace(TextTableOfCalculationGranules, "CalculationGranules.*", StrConcat(CalculationGranuleFields, ","));
	
	ArrayOfRequestTexts.Add(TextTableOfCalculationGranules);
	
	#EndRegion
	
	#Region TaskIds
	
	QueueRegisterTable = RegisterManager.CreateRecordSet().UnloadColumns(); // ValueTable
	ThereIsJobTypeFieldInQueueRegister = QueueRegisterTable.Columns.Find("JobKind") <> Undefined;
	
	QueueTaskText = "
	|SELECT 
	|	TaskTable.RecordID AS RecordID,
	|	CalculationGranules.*
	|FROM
	|	TT_CalculationGranules AS CalculationGranules
	|			INNER JOIN &TaskRegister AS TaskTable
	|				ON &ConditionsForJoiningTables
	|WHERE
	|	NOT TaskTable.CompletedWithAnError AND &SelectionByTaskType";
	
	QueueTaskText = StrReplace(QueueTaskText, "&TaskRegister", FullNameOfTaskRegister);
	
	CalculationGranuleFields = New Array;
	ConnectionConditionFields = New Array;
	For Each Field In ColumnsOfCalculationGranuleTable Do
		CalculationGranuleFields.Add(StrTemplate("CalculationGranules.%1 AS %1", Field.Name));
		ConnectionConditionFields.Add(StrTemplate("CalculationGranules.%1 = TaskTable.%1", Field.Name));
	EndDo;
	
	QueueTaskText = StrReplace(QueueTaskText, "CalculationGranules.*", StrConcat(CalculationGranuleFields, ", "));
	QueueTaskText = StrReplace(QueueTaskText, "&ConditionsForJoiningTables", StrConcat(ConnectionConditionFields, " And "));
	QueueTaskText = StrReplace(QueueTaskText, "&SelectionByTaskType", ?(ThereIsJobTypeFieldInQueueRegister
		And Not JobKind = Undefined, "TaskTable.JobKind = &JobKind", "TRUE"));
	
	ArrayOfRequestTexts.Add(QueueTaskText);
	
	#EndRegion
	
	Query = New Query;
	Query.Text =  StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	Query.SetParameter("TableOfCalculationGranules", TableOfCalculationGranules);
	Query.SetParameter("JobKind", JobKind);
	
	SetPrivilegedMode(True);
	TableOfIdentifiersForCalculationGranules = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Return TableOfIdentifiersForCalculationGranules;
	
EndFunction

// Registration of errors on calculation granules, the background processing of which ended in an emergency.
// 
// Parameters:
//  TableOfCalculationGranules - ValueTable - Table of calculation granules.The composition of the table fields must correspond 
//to the fields of the calculation granule of the queue register (see the Calculation Granule table() in the Queue Register Manager module).
//  FullNameOfTaskRegister - String - Full Name Of The Task Register
//  JobKind - Undefined, CatalogRef.BackdateJobKinds - Type of task
Procedure FixErrorsInCalculationGranulesInCaseOfEmergencyEndOfDataProcessing(TableOfCalculationGranules, FullNameOfTaskRegister, JobKind = Undefined)
	
	TableOfIdentifiersForCalculationGranules = IdentifiersForCalculationGranules(TableOfCalculationGranules, FullNameOfTaskRegister, JobKind);
	
	If TableOfIdentifiersForCalculationGranules.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterManager = Common.ObjectManagerByFullName(FullNameOfTaskRegister);
	
	BeginTransaction();
	
	Try
		
		ExceptionReason = "Block";
		Block = New DataLock;
		LockItem = Block.Add(FullNameOfTaskRegister);
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = TableOfIdentifiersForCalculationGranules;
		LockItem.UseFromDataSource("RecordID", "RecordID");
		Block.Lock();
		
		ExceptionReason = "BadData";
		ErrorDescriptionTable = RegisterManager.TableOfCalculationGranules(); // ValueTable
		ErrorDescriptionTable.Columns.Add("JobKind", New TypeDescription("CatalogRef.BackdateJobKinds"));
		ErrorDescriptionTable.Columns.Add("ErrorDescription", New TypeDescription("String"));
		
		ErrorTemplate = NStr("ru = 'Не удалось обработать данные по виду задания ""%1"" из-за аварийного завершения работы фонового процесса.';
							|vi = 'Cannot process data on the ""%1"" job type due to an emergency shutdown of the background process.';
							|en = 'Cannot process data on the ""%1"" job type due to an emergency shutdown of the background process.'; fa = 'Cannot process data on the ""%1"" job type due to an emergency shutdown of the background process.';
							|it = 'Cannot process data on the ""%1"" job type due to an emergency shutdown of the background process.';
							|pl = 'Cannot process data on the ""%1"" job type due to an emergency shutdown of the background process.';
							|tr = 'Arka plan işleminin beklenmedik şekilde sonlanması nedeniyle "" %1 "" görev türündeki veriler işlenemedi.'", Common.DefaultLanguageCode());
		
		For Each CurrentRow In TableOfIdentifiersForCalculationGranules Do
			Record = ErrorDescriptionTable.Add();
			FillPropertyValues(Record, CurrentRow);
			Record.JobKind = JobKind;
			Record.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, JobKind);
		EndDo;
		
		RegisterManager.RegisterDataProcessingErrors(TableOfIdentifiersForCalculationGranules.UnloadColumn(
			"RecordID"), ErrorDescriptionTable);

		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Event = NStr("ru = 'Аварийное завершение работы исполняющего потока неоперативной очереди заданий';
					|vi = 'Abnormal termination of the worker thread of the backdate job queue';
					|en = 'Abnormal termination of the worker thread of the backdate job queue'; fa = 'Abnormal termination of the worker thread of the backdate job queue';
					|it = 'Abnormal termination of the worker thread of the backdate job queue';
					|pl = 'Abnormal termination of the worker thread of the backdate job queue';
					|tr = 'Operasyonel olmayan görev kuyruğu yürütme iş parçacığının beklenmedik şekilde sonlanması.'",
			Common.DefaultLanguageCode());
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(Event, EventLogLevel.Error,
			Metadata.InformationRegisters.JobsOfBackdateAdditionalDocumentPosting, , ErrorText);
		
		If ExceptionReason = "BadData" Then
			Raise NStr("ru = 'Не удалось обработать гранулы расчета неоперативной очереди заданий 
								|после аварийного завершения работы фонового процесса.
								|Ошибки см. в журнале регистрации.';
								|vi = 'Cannot process calculation units of the non-operational job queue 
								|after the background process crashed. 
								|See the event log for details.';
								|en = 'Cannot process calculation units of the non-operational job queue 
								|after the background process crashed. 
								|See the event log for details.'; fa = 'Cannot process calculation units of the non-operational job queue 
								|after the background process crashed. 
								|See the event log for details.';
								|it = 'Cannot process calculation units of the non-operational job queue 
								|after the background process crashed. 
								|See the event log for details.';
								|pl = 'Cannot process calculation units of the non-operational job queue 
								|after the background process crashed. 
								|See the event log for details.';
								|tr = 'Arka plan işleminin beklenmedik şekilde sonlanmasından sonra operasyonel olmayan görev kuyruğu 
								| hesaplama birimleri işlenemedi. 
								| Hatalar için olay günlüğüne bakın.'");
		EndIf;

	EndTry;
	
EndProcedure

Function QueryTextMinimumPeriodOfTasksToBeProcessed(ParametersOfTaskCompletion)

	QueuesTable = ParametersOfTaskCompletion["TaskQueues"].QueuesTable;
	
	QueryTexts = New Array;

#Region DocumentsExcludedFromProcessing

	ArrayOfSubqueries = New Array;
	
	For Each CurrentQueue In QueuesTable Do
		QueryTexts.Add(CurrentQueue.QueryTextCalculationGranulesInProcessing);
		ArrayOfSubqueries.Add(CurrentQueue.QueryTextExcludedDocuments);
	EndDo;

	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin(True));
	
	QueryTextProcessedDocuments_ = "
	|SELECT
	|	ProcessedDocuments_.Document AS Document,
	|	ProcessedDocuments_.JobKind AS JobKind,
	|	ProcessedDocuments_.QueueNumber AS QueueNumber
	|INTO TT_ProcessedDocuments_
	|FROM
	|	&TheTextOfASubquery AS ProcessedDocuments_
	|
	|INDEX BY
	|	Document,
	|	JobKind,
	|	QueueNumber";
	QueryTextProcessedDocuments_ = StrReplace(QueryTextProcessedDocuments_, "&TheTextOfASubquery", "(" + SubqueryText + ")");

	QueryTexts.Add(QueryTextProcessedDocuments_);
	
	TextMinimumQueueNumberProcessedDocuments = "
	|SELECT
	|	ProcessedDocuments_.Document AS Document,
	|	MIN(ProcessedDocuments_.QueueNumber) AS MinimumQueueNumber
	|INTO VT_DocumentsProcessedMinQueue
	|FROM
	|	TT_ProcessedDocuments_ AS ProcessedDocuments_
	|	
	|GROUP BY
	|	ProcessedDocuments_.Document
	|
	|INDEX BY
	|	Document";

	QueryTexts.Add(TextMinimumQueueNumberProcessedDocuments);
	
	QueryTextExcludedDocuments = "
	|SELECT DISTINCT
	|	ExcludedDocuments.Document AS Document,
	|	ExcludedDocuments.JobKind AS JobKind
	|INTO TT_ExcludedDocuments
	|FROM
	|	(SELECT
	|		ProcessedDocuments_.Document AS Document,
	|		BackdateJobKinds.Ref AS JobKind
	|	FROM
	|		VT_DocumentsProcessedMinQueue AS ProcessedDocuments_
	|			INNER JOIN Catalog.BackdateJobKinds AS BackdateJobKinds
	|			ON ProcessedDocuments_.MinimumQueueNumber < BackdateJobKinds.QueueNumber
	|			AND BackdateJobKinds.QueueNumber <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		ProcessedDocuments_.Document AS Document,
	|		ProcessedDocuments_.JobKind AS JobKind
	|	FROM
	|		TT_ProcessedDocuments_ AS ProcessedDocuments_) AS ExcludedDocuments
	|
	|INDEX BY
	|	Document,
	|	JobKind";

	QueryTexts.Add(QueryTextExcludedDocuments);
	
#EndRegion

#Region Documents_With_Errors

	TextDocumentsWithErrors = "
	|SELECT
	|	ErrorsInDocuments.Document AS Document,
	|	MIN(ErrorsInDocuments.QueueNumber) AS QueueNumber
	|INTO TT_ErrorsInDocuments
	|FROM
	|	&TheTextOfASubquery AS ErrorsInDocuments
	|GROUP BY
	|	ErrorsInDocuments.Document
	|
	|INDEX BY
	|	Document,
	|	QueueNumber";
	
	SubqueryTextTemplate = "
	|SELECT DISTINCT
	|	TableQueue.Document AS Document,
	|	&QueueNumberField AS QueueNumber
	|FROM
	|	&TableQueue AS TableQueue
	|		INNER JOIN InformationRegister.JobQueueErrors AS ErrorRegister
	|		ON TableQueue.ErrorID = ErrorRegister.ErrorID";
	
	ArrayOfSubqueries = New Array;
	
	For Each CurrentQueue In QueuesTable Do

		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);

		QueryTextQueues = StrReplace(QueryTextQueues, "&QueueNumberField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterQueueNumber), "&" + CurrentQueue.RequestParameterQueueNumber,
			"TableQueue.JobKind.QueueNumber"));

		ArrayOfSubqueries.Add(QueryTextQueues);

	EndDo;
	
	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin(True));
	TextDocumentsWithErrors = StrReplace(TextDocumentsWithErrors, "&TheTextOfASubquery", "(" + SubqueryText + ")");

	QueryTexts.Add(TextDocumentsWithErrors);
	
#EndRegion

#Region TasksBasedOnExecutionPriorities
	
	If Not ParametersOfTaskCompletion.SelectionByTaskType Then
			
		QueryTextMonthEndClosingMode = "
		|SELECT
		|	MonthClosingParameters.Organization AS Organization,
		|	MAX(ENDOFPERIOD(MonthClosingParameters.TaskPeriod, MONTH)) AS ClosingPeriodEnds,
		|	MIN(BEGINOFPERIOD(MonthClosingParameters.TaskPeriod, MONTH)) AS ClosingPeriodBeginning
		|INTO TT_MonthClosingParameters
		|FROM
		|	InformationRegister.PriorityJobsOfBackdateJobQueue AS MonthClosingParameters
		|WHERE
		|	&ConditionOfMonthEndClosingMode
		|GROUP BY
		|	MonthClosingParameters.Organization
		|
		|INDEX BY
		|	ClosingPeriodEnds,
		|	ClosingPeriodBeginning,
		|	Organization
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MonthClosingParameters.Organization AS Organization,
		|	MonthClosingParameters.ClosingPeriodBeginning AS ClosingPeriodBeginning,
		|	MonthClosingParameters.ClosingPeriodEnds AS ClosingPeriodEnds
		|FROM
		|	TT_MonthClosingParameters AS MonthClosingParameters
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(TT_MonthClosingParameters.ClosingPeriodBeginning) AS PeriodMin,
		|	MAX(TT_MonthClosingParameters.ClosingPeriodEnds) AS PeriodMax
		|FROM
		|	TT_MonthClosingParameters AS TT_MonthClosingParameters
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(Table.MonthEndClosingMode) AS MonthEndClosingMode
		|FROM
		|	&TheTextOfASubquery AS Table";
		
		SubqueryTextTemplate = "
		|SELECT TOP 1
		|		TRUE AS MonthEndClosingMode
		|	FROM
		|		&TableQueue AS TableQueue
		|			LEFT JOIN TT_ExcludedDocuments AS ExcludedDocuments
		|			ON TableQueue.Document = ExcludedDocuments.Document
		|				AND &TaskTypeField = ExcludedDocuments.JobKind
		|			
		|			LEFT JOIN TT_ErrorsInDocuments AS TaskCompletionBan
		|			ON TableQueue.Document = TaskCompletionBan.Document
		|			AND &QueueNumberField > TaskCompletionBan.QueueNumber
		|
		|			INNER JOIN TT_MonthClosingParameters AS TT_MonthClosingParameters
		|			ON TableQueue.Organization = TT_MonthClosingParameters.Organization
		|			AND TableQueue.TaskPeriod
		|				BETWEEN TT_MonthClosingParameters.ClosingPeriodBeginning AND TT_MonthClosingParameters.ClosingPeriodEnds
		|	WHERE
		|		ExcludedDocuments.Document IS NULL
		|		AND TaskCompletionBan.Document IS NULL
		|		AND NOT TableQueue.CompletedWithAnError";
		
		ArrayOfSubqueries = New Array;
		For Each CurrentQueue In QueuesTable Do
			QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);
			QueryTextQueues = StrReplace(QueryTextQueues, "&QueueNumberField", ?(ValueIsFilled(
				CurrentQueue.RequestParameterQueueNumber), "&" + CurrentQueue.RequestParameterQueueNumber,
				"TableQueue.JobKind.QueueNumber"));
			QueryTextQueues = StrReplace(QueryTextQueues, "&TaskTypeField", ?(ValueIsFilled(
				CurrentQueue.RequestParameterTaskType), "&" + CurrentQueue.RequestParameterTaskType,
				"TableQueue.JobKind"));
			ArrayOfSubqueries.Add(QueryTextQueues);
		EndDo;
		ArrayOfSubqueries.Add("SELECT FALSE AS MonthEndClosingMode");
		SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin());
		QueryTextMonthEndClosingMode = StrReplace(QueryTextMonthEndClosingMode, "&TheTextOfASubquery", "(" + SubqueryText + ")");
		
		If ParametersOfTaskCompletion.MonthEndClosingModeIsFileInfobase Then
	
			ConditionOfMonthEndClosingMode = "MonthClosingParameters.Organization IN (&Companies) 
			|AND MonthClosingParameters.TaskPeriod <= &ClosingPeriod";
			
		Else
			ConditionOfMonthEndClosingMode = "TRUE";
		EndIf;
		
		QueryTextMonthEndClosingMode = StrReplace(QueryTextMonthEndClosingMode, "&ConditionOfMonthEndClosingMode",
			ConditionOfMonthEndClosingMode);
		
		QueryTexts.Add(QueryTextMonthEndClosingMode);
		
	Else
		
		QueryTextMonthEndClosingMode = "
		|SELECT
		|	FALSE AS MonthEndClosingMode";
		
		QueryTexts.Add(QueryTextMonthEndClosingMode);
		
	EndIf;
	
#EndRegion
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Return QueryText;

EndFunction

Function QueryTextForSelectingTasksInNonOperationalQueueForExecution(ParametersOfTaskCompletion, MonthEndClosingMode = False)

	QueuesTable = ParametersOfTaskCompletion["TaskQueues"].QueuesTable;
	
	QueryTextArray = New Array;
	
	If ParametersOfTaskCompletion.SelectionByTaskType Then
		
		QueryTextKindsOfTasks = "
		|SELECT
		|	BackdateJobKinds.Ref AS JobKind
		|INTO TT_SelectionByTaskType
		|FROM
		|	Catalog.BackdateJobKinds AS BackdateJobKinds
		|WHERE
		|	BackdateJobKinds.Ref = &JobKind
		|
		|UNION ALL
		|
		|SELECT
		|	BackdateJobKinds.Ref AS JobKind
		|FROM
		|	Catalog.BackdateJobKinds AS BackdateJobKinds
		|WHERE
		|	BackdateJobKinds.QueueNumber < CAST(&JobKind AS Catalog.BackdateJobKinds).QueueNumber";
		
		QueryTextArray.Add(QueryTextKindsOfTasks);
		
	EndIf; 

#Region MinimumPeriodDay
	
	QueryTextMinimumPeriod = "
	|SELECT
	|	BEGINOFPERIOD(MIN(TasksToProcess.TaskPeriod), DAY) AS BeginOfPeriod,
	|	ENDOFPERIOD(MIN(TasksToProcess.TaskPeriod), DAY) AS EndOfPeriod
	|INTO TT_MinimumPeriodDay
	|FROM
	|	&TheTextOfASubquery AS TasksToProcess
	|
	|INDEX BY
	|	BeginOfPeriod,
	|	EndOfPeriod
	|";
	
	If MonthEndClosingMode Then
		SubqueryTextTemplate = "
		|SELECT
		|	NestedTable.TaskPeriod AS TaskPeriod
		|FROM
		|	(SELECT TOP 1
		|		TableQueue.TaskPeriod AS TaskPeriod
		|	FROM
		|		&TableQueue AS TableQueue
		|			
		|			LEFT JOIN TT_ExcludedDocuments AS ExcludedDocuments
		|			ON TableQueue.Document = ExcludedDocuments.Document
		|			AND &TaskTypeField = ExcludedDocuments.JobKind
		|
		|			LEFT JOIN TT_ErrorsInDocuments AS TaskCompletionBan
		|			ON TableQueue.Document = TaskCompletionBan.Document
		|			AND &QueueNumberField > TaskCompletionBan.QueueNumber
		
		|			INNER JOIN TT_MonthClosingParameters AS TT_MonthClosingParameters
		|			ON TableQueue.Organization = TT_MonthClosingParameters.Organization
		|			AND TableQueue.TaskPeriod
		|				BETWEEN TT_MonthClosingParameters.ClosingPeriodBeginning AND TT_MonthClosingParameters.ClosingPeriodEnds
		|	WHERE
		|		ExcludedDocuments.Document IS NULL
		|		AND TaskCompletionBan.Document IS NULL
		|		AND TableQueue.TaskPeriod BETWEEN &MonthEndClosingBeginningOfPeriod AND &MonthEndClosingEndOfPeriod
		|		AND TableQueue.Organization IN (&Companies)
		|		AND TableQueue.CompletedWithAnError = FALSE
		|
		|	ORDER BY
		|		TaskPeriod) AS NestedTable";
	Else
		
		SubqueryTextTemplate = "
		|SELECT
		|	NestedTable.TaskPeriod AS TaskPeriod
		|FROM
		|	(SELECT TOP 1
		|		TableQueue.TaskPeriod AS TaskPeriod
		|	FROM
		|		&TableQueue AS TableQueue
		|
		|			LEFT JOIN TT_ExcludedDocuments AS ExcludedDocuments
		|			ON TableQueue.Document = ExcludedDocuments.Document
		|			AND &TaskTypeField = ExcludedDocuments.JobKind
		|
		|			LEFT JOIN TT_ErrorsInDocuments AS TaskCompletionBan
		|			ON TableQueue.Document = TaskCompletionBan.Document
		|			AND &QueueNumberField > TaskCompletionBan.QueueNumber
		|	WHERE
		|		ExcludedDocuments.Document IS NULL
		|		AND TaskCompletionBan.Document IS NULL
		|		AND TableQueue.CompletedWithAnError = FALSE
		|		AND &SelectionByTaskType
		|
		|	ORDER BY
		|		TaskPeriod) AS NestedTable";
	
	EndIf;
	
	If ParametersOfTaskCompletion.SelectionByTaskType Then
		SubqueryTextTemplate = StrReplace(SubqueryTextTemplate, "&SelectionByTaskType",
			"&TaskTypeField IN (SELECT TT_SelectionByTaskType.JobKind FROM TT_SelectionByTaskType AS TT_SelectionByTaskType)");
	Else
		SubqueryTextTemplate = StrReplace(SubqueryTextTemplate, "&SelectionByTaskType", "TRUE");
	EndIf;
	
	ArrayOfSubqueries = New Array;
	For Each CurrentQueue In QueuesTable Do
		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);
		QueryTextQueues = StrReplace(QueryTextQueues, "&QueueNumberField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterQueueNumber), "&" + CurrentQueue.RequestParameterQueueNumber,
			"TableQueue.JobKind.QueueNumber"));
		QueryTextQueues = StrReplace(QueryTextQueues, "&TaskTypeField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterTaskType), "&" + CurrentQueue.RequestParameterTaskType,
			"TableQueue.JobKind"));
		ArrayOfSubqueries.Add(QueryTextQueues);
	EndDo;
	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin());
	QueryTextMinimumPeriod = StrReplace(QueryTextMinimumPeriod, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	QueryTextArray.Add(QueryTextMinimumPeriod);
#EndRegion

#Region DocumentsInMinimumDay
	QueryTextTasksForDocumentsToBeProcessed="
	|SELECT DISTINCT
	|	TasksToProcess.Document AS Document,
	|	TasksToProcess.QueueNumber AS QueueNumber,
	|	TasksToProcess.JobKind AS JobKind
	|INTO TT_TasksForDocumentsToBeProcessed
	|FROM
	|	&TheTextOfASubquery AS TasksToProcess
	|
	|INDEX BY
	|	Document,
	|	JobKind
	|";
	
	If MonthEndClosingMode Then
		
		SubqueryTextTemplate = "
		|SELECT DISTINCT
		|	TableQueue.Document AS Document,
		|	&QueueNumberField AS QueueNumber,
		|	&TaskTypeField AS JobKind
		|FROM
		|	&TableQueue AS TableQueue
		|		
		|		INNER JOIN TT_MinimumPeriodDay AS MinimumPeriod
		|		ON TableQueue.TaskPeriod BETWEEN MinimumPeriod.BeginOfPeriod AND MinimumPeriod.EndOfPeriod
		|
		|		LEFT JOIN TT_ExcludedDocuments AS ExcludedDocuments
		|		ON TableQueue.Document = ExcludedDocuments.Document
		|		AND &TaskTypeField = ExcludedDocuments.JobKind
		|
		|		LEFT JOIN TT_ErrorsInDocuments AS TaskCompletionBan
		|		ON TableQueue.Document = TaskCompletionBan.Document
		|		AND &QueueNumberField > TaskCompletionBan.QueueNumber
		|		
		|		INNER JOIN TT_MonthClosingParameters AS TT_MonthClosingParameters
		|		ON TableQueue.Organization = TT_MonthClosingParameters.Organization
		|		AND TableQueue.TaskPeriod
		|			BETWEEN TT_MonthClosingParameters.ClosingPeriodBeginning AND TT_MonthClosingParameters.ClosingPeriodEnds
		|WHERE
		|	ExcludedDocuments.Document IS NULL
		|	AND TaskCompletionBan.Document IS NULL
		|	AND TableQueue.Organization IN (&Companies)
		|	AND TableQueue.CompletedWithAnError = FALSE";
		
	Else
		
		SubqueryTextTemplate = "
		|SELECT DISTINCT
		|	TableQueue.Document AS Document,
		|	&QueueNumberField AS QueueNumber,
		|	&TaskTypeField AS JobKind
		|FROM
		|	&TableQueue AS TableQueue
		|		
		|		INNER JOIN TT_MinimumPeriodDay AS MinimumPeriod
		|		ON TableQueue.TaskPeriod BETWEEN MinimumPeriod.BeginOfPeriod AND MinimumPeriod.EndOfPeriod
		|
		|		LEFT JOIN TT_ExcludedDocuments AS ExcludedDocuments
		|		ON TableQueue.Document = ExcludedDocuments.Document
		|		AND &TaskTypeField = ExcludedDocuments.JobKind
		|
		|		LEFT JOIN TT_ErrorsInDocuments AS TaskCompletionBan
		|		ON TableQueue.Document = TaskCompletionBan.Document
		|		AND &QueueNumberField > TaskCompletionBan.QueueNumber
		|
		|WHERE
		|	ExcludedDocuments.Document IS NULL
		|	AND TaskCompletionBan.Document IS NULL
		|	AND TableQueue.CompletedWithAnError = FALSE
		|	AND &SelectionByTaskType";	
				
	EndIf;
	
	If ParametersOfTaskCompletion.SelectionByTaskType Then
		SubqueryTextTemplate = StrReplace(SubqueryTextTemplate, "&SelectionByTaskType",
			"&TaskTypeField IN (SELECT TT_SelectionByTaskType.JobKind FROM TT_SelectionByTaskType AS TT_SelectionByTaskType)");
	Else
		SubqueryTextTemplate = StrReplace(SubqueryTextTemplate, "&SelectionByTaskType", "TRUE");
	EndIf;
	
	ArrayOfSubqueries = New Array;
	
	For Each CurrentQueue In QueuesTable Do
		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);

		QueryTextQueues = StrReplace(QueryTextQueues, "&QueueNumberField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterQueueNumber), "&" + CurrentQueue.RequestParameterQueueNumber,
			"TableQueue.JobKind.QueueNumber"));

		QueryTextQueues = StrReplace(QueryTextQueues, "&TaskTypeField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterTaskType), "&" + CurrentQueue.RequestParameterTaskType,
			"TableQueue.JobKind"));

		ArrayOfSubqueries.Add(QueryTextQueues);
	EndDo;
	
	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin());
	QueryTextTasksForDocumentsToBeProcessed = StrReplace(QueryTextTasksForDocumentsToBeProcessed, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	QueryTextArray.Add(QueryTextTasksForDocumentsToBeProcessed);
#EndRegion

#Region TasksForSelectedDocuments

QueryTextDocumentAssignments ="
	|SELECT
	|	TasksToProcess.TaskPeriod AS TaskPeriod,
	|	TasksToProcess.JobKind AS JobKind,
	|	TasksToProcess.Document AS Document
	|INTO TT_DocumentsTypesOfTasks
	|FROM
	|	&TheTextOfASubquery AS TasksToProcess
	|
	|INDEX BY
	|	JobKind";
	
	SubqueryTextTemplate = "
	|SELECT
	|	MIN(TableQueue.TaskPeriod) AS TaskPeriod,
	|	&TaskTypeField AS JobKind,
	|	TableQueue.Document AS Document
	|FROM
	|	&TableQueue AS TableQueue
	|WHERE
	|	TableQueue.CompletedWithAnError = FALSE
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TT_TasksForDocumentsToBeProcessed AS TasksForDocumentsToBeProcessed
	|		WHERE
	|			TableQueue.Document = TasksForDocumentsToBeProcessed.Document
	|			AND &TaskTypeField = TasksForDocumentsToBeProcessed.JobKind)
	|GROUP BY
	|	TableQueue.Document,
	|	&TaskTypeField";
	
	ArrayOfSubqueries = New Array;
	
	For Each CurrentQueue In QueuesTable Do
		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);

		QueryTextQueues = StrReplace(QueryTextQueues, "&TaskTypeField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterTaskType), "&" + CurrentQueue.RequestParameterTaskType,
			"TableQueue.JobKind"));
		ArrayOfSubqueries.Add(QueryTextQueues);
	EndDo;
	
	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin(True));
	QueryTextDocumentAssignments = StrReplace(QueryTextDocumentAssignments, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	QueryTextArray.Add(QueryTextDocumentAssignments);
	
	QueryTextDocumentsTypesOfTasksToBeProcessed ="
	|SELECT
	|	TableQueue.TaskPeriod AS TaskPeriod,
	|	TableQueue.JobKind AS JobKind,
	|	TableQueue.Document AS Document,
	|	TableQueue.JobKind.QueueNumber AS QueueNumber
	|INTO VT_DocumentsTypesOfTasksToBeProcessed
	|FROM
	|	TT_DocumentsTypesOfTasks AS TableQueue
	|
	|INDEX BY
	|	Document,
	|	QueueNumber,
	|	JobKind";
	QueryTextArray.Add(QueryTextDocumentsTypesOfTasksToBeProcessed);
	
#EndRegion
	
	QueryTextDocumentAssignments ="
	|SELECT
	|	MIN(BEGINOFPERIOD(TableQueue.TaskPeriod, DAY)) AS TaskPeriodDay,
	|	TableQueue.JobKind AS JobKind,
	|	TableQueue.Document AS Document,
	|	TableQueue.QueueNumber AS QueueNumber
	|INTO TT_DocumentAssignments
	|FROM
	|	VT_DocumentsTypesOfTasksToBeProcessed AS TableQueue
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			VT_DocumentsTypesOfTasksToBeProcessed AS DocumentsTypesOfTasks
	|		WHERE
	|			TableQueue.Document = DocumentsTypesOfTasks.Document
	|			AND TableQueue.QueueNumber <= DocumentsTypesOfTasks.QueueNumber)
	|GROUP BY
	|	TableQueue.JobKind,
	|	TableQueue.Document,
	|	TableQueue.QueueNumber
	|
	|INDEX BY
	|	TaskPeriodDay,
	|	JobKind,
	|	QueueNumber";
	
	QueryTextArray.Add(QueryTextDocumentAssignments);

	QueryTextFirstMinimumDay="
	|SELECT TOP 1
	|	MinimumDay.QueueNumber AS QueueNumber,
	|	MinimumDay.TaskPeriodDay AS TaskPeriodDay,
	|	MinimumDay.JobKind AS JobKind
	|INTO VT_QueueMinimumDay
	|FROM
	|	(SELECT
	|		MIN(TT_DocumentAssignments.TaskPeriodDay) AS TaskPeriodDay,
	|		TT_DocumentAssignments.JobKind AS JobKind,
	|		TT_DocumentAssignments.QueueNumber AS QueueNumber
	|	FROM
	|		TT_DocumentAssignments AS TT_DocumentAssignments
	|	GROUP BY
	|		TT_DocumentAssignments.JobKind,
	|		TT_DocumentAssignments.QueueNumber) AS MinimumDay
	|
	|ORDER BY
	|	QueueNumber,
	|	TaskPeriodDay
	|
	|INDEX BY
	|	TaskPeriodDay,
	|	QueueNumber,
	|	JobKind";
	
	QueryTextArray.Add(QueryTextFirstMinimumDay);
	
	RequestTextSummary = "
	|SELECT
	|	TT_DocumentAssignments.JobKind AS JobKind,
	|	TT_DocumentAssignments.TaskPeriodDay AS TaskPeriodDay,
	|	TT_DocumentAssignments.Document AS Document
	|FROM
	|	TT_DocumentAssignments AS TT_DocumentAssignments
	|		INNER JOIN VT_QueueMinimumDay AS MinimumDay
	|		ON TT_DocumentAssignments.TaskPeriodDay = MinimumDay.TaskPeriodDay
	|		AND TT_DocumentAssignments.QueueNumber = MinimumDay.QueueNumber
	|		AND TT_DocumentAssignments.JobKind = MinimumDay.JobKind
	|TOTALS
	|BY
	|	JobKind,
	|	TaskPeriodDay";
	QueryTextArray.Add(RequestTextSummary);
	
	QueryText = StrConcat(QueryTextArray, Common.QueryBatchSeparator());
	
	Return QueryText;

EndFunction

Function QueryTextForSelectingTasksInNonOperationalQueueForExecutionBasedOnListOfDocuments(DocumentsList, JobKind,
	TaskQueues, ExecutionInTransactionOfConducting = False)
	
	QueuesTable = TaskQueues.QueuesTable;
	
	QueryTexts = New Array;

#Region DocumentsForProcessing_

	If DocumentsList.Count() > 0 Then
		
		QueryTextDocuments = "
		|SELECT DISTINCT
		|	DocumentsToBeReflected.Document AS Document
		|INTO TT_DocumentsToBeReflected
		|FROM
		|	&DocumentsToBeReflected AS DocumentsToBeReflected
		|
		|INDEX BY
		|	Document";
		
	Else

		QueryTextDocuments = "
		|SELECT DISTINCT
		|	Jobs.Document AS Document
		|INTO TT_DocumentsToBeReflected
		|FROM
		|	&TheTextOfASubquery AS Jobs
		|
		|INDEX BY
		|	Document";
		
		SubqueryTextTemplate = "
		|SELECT DISTINCT
		|	TableQueue.Document AS Document
		|FROM
		|	&TableQueue AS TableQueue
		|	LEFT JOIN InformationRegister.JobQueueErrors AS ErrorRegister
		|	ON TableQueue.ErrorID = ErrorRegister.ErrorID
		|WHERE
		|	&TaskTypeField = &JobKind
		|	AND ErrorRegister.ErrorID IS NULL
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	TableQueue.Document AS Document
		|FROM
		|	&TableQueue AS TableQueue
		|	LEFT JOIN InformationRegister.JobQueueErrors AS ErrorRegister
		|	ON TableQueue.ErrorID = ErrorRegister.ErrorID
		|WHERE
		|	&QueueNumberField < CAST(&JobKind AS Catalog.BackdateJobKinds).QueueNumber
		|	AND ErrorRegister.ErrorID IS NULL";
		
		ArrayOfSubqueries = New Array;
		
		For Each CurrentQueue In QueuesTable Do

			QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);
			
			QueryTextQueues = StrReplace(QueryTextQueues, "&TaskTypeField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterTaskType), "&" + CurrentQueue.RequestParameterTaskType,
				"TableQueue.JobKind"));
				
			QueryTextQueues = StrReplace(QueryTextQueues, "&QueueNumberField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterQueueNumber), "&" + CurrentQueue.RequestParameterQueueNumber,
				"TableQueue.JobKind.QueueNumber"));
				
			ArrayOfSubqueries.Add(QueryTextQueues);

		EndDo;
		
		SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin(True));
		QueryTextDocuments = StrReplace(QueryTextDocuments, "&TheTextOfASubquery", "(" + SubqueryText + ")");
		
	EndIf;
	
	QueryTexts.Add(QueryTextDocuments);
	
#Region Documents_With_Errors
	
	If Not ExecutionInTransactionOfConducting Then
		
		TextDocumentsWithErrors = "
		|SELECT
		|	ErrorsInDocuments.Document AS Document,
		|	MIN(ErrorsInDocuments.QueueNumber) AS QueueNumber
		|INTO TT_ErrorsInDocuments
		|FROM
		|	&TheTextOfASubquery AS ErrorsInDocuments
		|GROUP BY
		|	ErrorsInDocuments.Document
		|
		|INDEX BY
		|	Document,
		|	QueueNumber";
		
		SubqueryTextTemplate = "
		|SELECT DISTINCT
		|	TableQueue.Document AS Document,
		|	&QueueNumberField AS QueueNumber
		|FROM
		|	&TableQueue AS TableQueue
		|		INNER JOIN TT_DocumentsToBeReflected AS DocumentsToBeReflected
		|		ON TableQueue.Document = DocumentsToBeReflected.Document
		|WHERE
		|	TableQueue.CompletedWithAnError = TRUE";
		
		ArrayOfSubqueries = New Array;
		
		For Each CurrentQueue In QueuesTable Do
	
			QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);
	
			QueryTextQueues = StrReplace(QueryTextQueues, "&QueueNumberField", ?(ValueIsFilled(
				CurrentQueue.RequestParameterQueueNumber), "&" + CurrentQueue.RequestParameterQueueNumber,
				"TableQueue.JobKind.QueueNumber"));
	
			ArrayOfSubqueries.Add(QueryTextQueues);
	
		EndDo;
		
		SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin(True));
		TextDocumentsWithErrors = StrReplace(TextDocumentsWithErrors, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	
		QueryTexts.Add(TextDocumentsWithErrors);
	
	EndIf;
	
#EndRegion
	
	QueryTextDocumentsForProcessing_ = "
	|SELECT
	|	MIN(DATETIME(1, 1, 1, 0, 0, 0)) AS TaskPeriodDay,
	|	TasksToProcess.Document AS Document,
	|	TasksToProcess.QueueNumber AS QueueNumber,
	|	TasksToProcess.JobKind AS JobKind
	|INTO TT_DocumentAssignments
	|FROM
	|	&TheTextOfASubquery AS TasksToProcess
	|
	|GROUP BY
	|	TasksToProcess.Document,
	|	TasksToProcess.QueueNumber,
	|	TasksToProcess.JobKind
	|
	|INDEX BY
	|	JobKind,
	|	Document
	|";
	
	If Not ExecutionInTransactionOfConducting Then
		SubqueryTextTemplate = "
		|SELECT
		|	TableQueue.Document AS Document,
		|	&QueueNumberField AS QueueNumber,
		|	&TaskTypeField AS JobKind
		|FROM
		|	&TableQueue AS TableQueue
		|		INNER JOIN TT_DocumentsToBeReflected AS DocumentsToBeReflected
		|		ON TableQueue.Document = DocumentsToBeReflected.Document
		|		LEFT JOIN TT_ErrorsInDocuments AS TaskCompletionBan
		|		ON TableQueue.Document = TaskCompletionBan.Document
		|		AND &QueueNumberField > TaskCompletionBan.QueueNumber
		|WHERE
		|	TaskCompletionBan.Document IS NULL
		|	AND &QueueNumberField < CAST(&JobKind AS Catalog.BackdateJobKinds).QueueNumber
		|	AND NOT TableQueue.CompletedWithAnError
		|
		|UNION ALL
		|
		|SELECT
		|	TableQueue.Document AS Document,
		|	&QueueNumberField AS QueueNumber,
		|	&TaskTypeField AS JobKind
		|FROM
		|	&TableQueue AS TableQueue
		|		INNER JOIN TT_DocumentsToBeReflected AS DocumentsToBeReflected
		|		ON TableQueue.Document = DocumentsToBeReflected.Document
		|		LEFT JOIN TT_ErrorsInDocuments AS TaskCompletionBan
		|		ON TableQueue.Document = TaskCompletionBan.Document
		|		AND &QueueNumberField > TaskCompletionBan.QueueNumber
		|WHERE
		|	TaskCompletionBan.Document IS NULL
		|	AND &TaskTypeField = &JobKind
		|	AND NOT TableQueue.CompletedWithAnError";
	Else
		SubqueryTextTemplate = "
		|SELECT
		|	TableQueue.Document AS Document,
		|	&QueueNumberField AS QueueNumber,
		|	&TaskTypeField AS JobKind
		|FROM
		|	&TableQueue AS TableQueue
		|		INNER JOIN TT_DocumentsToBeReflected AS DocumentsToBeReflected
		|		ON TableQueue.Document = DocumentsToBeReflected.Document
		|WHERE
		|	&QueueNumberField < CAST(&JobKind AS Catalog.BackdateJobKinds).QueueNumber
		|	AND NOT TableQueue.CompletedWithAnError
		|
		|UNION ALL
		|
		|SELECT
		|	TableQueue.Document AS Document,
		|	&QueueNumberField AS QueueNumber,
		|	&TaskTypeField AS JobKind
		|FROM
		|	&TableQueue AS TableQueue
		|		INNER JOIN TT_DocumentsToBeReflected AS DocumentsToBeReflected
		|		ON TableQueue.Document = DocumentsToBeReflected.Document
		|WHERE
		|	&TaskTypeField = &JobKind
		|	AND NOT TableQueue.CompletedWithAnError";
	EndIf;
	
	ArrayOfSubqueries = New Array;
	
	For Each CurrentQueue In QueuesTable Do

		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);

		QueryTextQueues = StrReplace(QueryTextQueues, "&TaskTypeField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterTaskType), "&" + CurrentQueue.RequestParameterTaskType,
			"TableQueue.JobKind"));

		QueryTextQueues = StrReplace(QueryTextQueues, "&QueueNumberField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterQueueNumber), "&" + CurrentQueue.RequestParameterQueueNumber,
			"TableQueue.JobKind.QueueNumber"));

		ArrayOfSubqueries.Add(QueryTextQueues);

	EndDo;
	
	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin());
	QueryTextDocumentsForProcessing_ = StrReplace(QueryTextDocumentsForProcessing_, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	QueryTexts.Add(QueryTextDocumentsForProcessing_);
	
	QueryTextFirstMinimumDay="
	|SELECT TOP 1
	|	MinimumDay.QueueNumber AS QueueNumber,
	|	MinimumDay.TaskPeriodDay AS TaskPeriodDay,
	|	MinimumDay.JobKind AS JobKind
	|INTO VT_QueueMinimumDay
	|FROM
	|	(SELECT
	|		MIN(TT_DocumentAssignments.TaskPeriodDay) AS TaskPeriodDay,
	|		TT_DocumentAssignments.JobKind AS JobKind,
	|		TT_DocumentAssignments.QueueNumber AS QueueNumber
	|	FROM
	|		TT_DocumentAssignments AS TT_DocumentAssignments
	|	GROUP BY
	|		TT_DocumentAssignments.JobKind,
	|		TT_DocumentAssignments.QueueNumber) AS MinimumDay
	|
	|ORDER BY
	|	QueueNumber,
	|	TaskPeriodDay
	|
	|INDEX BY
	|	TaskPeriodDay,
	|	QueueNumber,
	|	JobKind";
	
	QueryTexts.Add(QueryTextFirstMinimumDay);
	
	RequestTextSummary = "
	|SELECT
	|	TT_DocumentAssignments.JobKind AS JobKind,
	|	TT_DocumentAssignments.TaskPeriodDay AS TaskPeriodDay,
	|	TT_DocumentAssignments.Document AS Document
	|FROM
	|	TT_DocumentAssignments AS TT_DocumentAssignments
	|		INNER JOIN VT_QueueMinimumDay AS MinimumDay
	|		ON TT_DocumentAssignments.TaskPeriodDay = MinimumDay.TaskPeriodDay
	|		AND TT_DocumentAssignments.QueueNumber = MinimumDay.QueueNumber
	|		AND TT_DocumentAssignments.JobKind = MinimumDay.JobKind
	|TOTALS
	|BY
	|	JobKind,
	|	TaskPeriodDay";
	QueryTexts.Add(RequestTextSummary);
	
#EndRegion

	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());

	Return QueryText;

EndFunction

// Starts processing portions of calculation granules.
// If the "Task execution directly" mode is set in the task execution parameter (Task Execution not directly = True), then background task execution will not be started.
// 
// Parameters:
//  ParametersOfTaskCompletion - See ParametersOfTaskCompletion.
//  WorkFlows - Array of See DescriptionOfWorkingThread - Array of used worker threads.
Procedure StartProcessingDataChunks(ParametersOfTaskCompletion, WorkFlows)

	If ParametersOfTaskCompletion.DataForProcessing_.Count() = 0 Then
		Return;
	EndIf;

	DataPortionNumbers = New ValueList;
	DataPortionNumbers.LoadValues(CommonClientServer.CollapseArray(
		ParametersOfTaskCompletion.DataForProcessing_.UnloadColumn("Batch")));
	DataPortionNumbers.SortByValue(SortDirection.Asc);

	For Each CurrentProcessingOrder In DataPortionNumbers Do
		
		If CurrentProcessingOrder.Value > ParametersOfTaskCompletion.ThreadsCount Then
			Break;
		EndIf;

		DataTable = ParametersOfTaskCompletion.DataForProcessing_.Copy(New Structure("Batch",
			CurrentProcessingOrder.Value));

		If DataTable.Count() = 0 Then
			Continue;
		EndIf;

		TaskRegisterManager = ParametersOfTaskCompletion.TaskRegisterManager;

		ProcedureParameters = DataPortionProcessingParameters();
		ProcedureParameters.JobKind = ParametersOfTaskCompletion.JobKind;
		ProcedureParameters.DataPortion = DataTable.Copy();
		ProcedureParameters.QueueRegisterName = ParametersOfTaskCompletion.QueueRegisterName;

		If ParametersOfTaskCompletion.CompletingTasksDirectly Then

			ProcedureParameters.CompletingTasksInTransaction = ParametersOfTaskCompletion.CompletingTasksInTransaction;
			TaskRegisterManager.PerformPortionProcessing(ProcedureParameters);

		Else

			NewWorkThread = DescriptionOfWorkingThread();
			NewWorkThread.QueueRegister = ParametersOfTaskCompletion.QueueRegister;
			NewWorkThread.ProcedureParameters = ProcedureParameters;
			NewWorkThread.JobKind = ParametersOfTaskCompletion.JobKind;

			BackgroundJobDescription = StrTemplate(NStr(
					"ru = 'Обработка порции документов неоперативной очереди заданий [%1].';
					|vi = 'Process a batch of backdate job queue documents [%1].';
					|en = 'Process a batch of backdate job queue documents [%1].'; fa = 'Process a batch of backdate job queue documents [%1].';
					|it = 'Process a batch of backdate job queue documents [%1].';
					|pl = 'Process a batch of backdate job queue documents [%1].';
					|tr = '[ %1 ] operasyonel olmayan görev kuyruğu belge grubunun işlenmesi.'"),
				ParametersOfTaskCompletion.JobKind);
			NameOfTheBackgroundTaskProcedure = "BackdateJobQueue.PerformPortionProcessingAsBackgroundTask";
			BackgroundJobParameters = New Array;
			BackgroundJobParameters.Add(TaskRegisterManager);
			BackgroundJobParameters.Add(ProcedureParameters);
			BackgroundJob = BackgroundJobs.Execute(NameOfTheBackgroundTaskProcedure, BackgroundJobParameters, ,
				BackgroundJobDescription);

			NewWorkThread.ThreadID = BackgroundJob.UUID;

			WorkFlows.Add(NewWorkThread);
			
			DataTable.GroupBy(ParametersOfTaskCompletion.CalculationGrunulaFields);
			For Each DataString1 In DataTable Do
				
				NewRecord = ParametersOfTaskCompletion.DataToProcess.Add();
				FillPropertyValues(NewRecord, DataString1);
				NewRecord.ThreadID = NewWorkThread.ThreadID;
				NewRecord.JobKind = ParametersOfTaskCompletion.JobKind;
				
			EndDo;

		EndIf;

	EndDo;

EndProcedure

Procedure PerformPortionProcessingAsBackgroundTask(TaskRegisterManager, ProcedureParameters) Export
	
	SetPrivilegedMode(True);
	UserToCheckPeriodClosingDates = Constants.UserToCheckPeriodClosingDatesWhenPerformingQueueTasks.Get();
	PeriodClosingDates.SetUserToCheckDatesOfBan(UserToCheckPeriodClosingDates);
	SetPrivilegedMode(False);
	
	TaskRegisterManager.PerformPortionProcessing(ProcedureParameters);
	
EndProcedure

// Deleting entries from the queue error register.
// 
// Parameters:
//  TaskQueues - See BackdateJobQueueCached.TaskQueues
//  IDsList - Array of UUID - List of error IDs
//
Procedure DeletingQueueErrorRegisterEntries(TaskQueues, IDsList) Export

	QueuesTable = TaskQueues.QueuesTable;
	IDsList = CommonClientServer.CollapseArray(IDsList);

	CommonClientServer.DeleteValueFromArray(IDsList,
		CommonClientServer.BlankUUID());
		
	If IDsList.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ErrorIds", IDsList);
	
	QueriesArray = New Array;
	QueryText = "
	|SELECT DISTINCT
	|	QueueErrors.ErrorID AS ErrorID
	|INTO TT_ExceptionErrors
	|FROM
	|	&TheTextOfASubquery AS QueueErrors
	|
	|INDEX BY
	|	ErrorID";

	SubqueryTextTemplate = "
	|SELECT
	|	TableQueue.ErrorID AS ErrorID
	|FROM
	|	&TableQueue AS TableQueue
	|WHERE
	|	TableQueue.ErrorID IN (&ErrorIds)";
	
	ArrayOfSubqueries = New Array;
	For Each CurrentQueue In QueuesTable Do

		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);
		ArrayOfSubqueries.Add(QueryTextQueues);

	EndDo;
	
	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin());
	QueryText = StrReplace(QueryText, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	QueriesArray.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	JobQueueErrors.ErrorID AS ErrorID
	|FROM
	|	InformationRegister.JobQueueErrors AS JobQueueErrors
	|		LEFT JOIN TT_ExceptionErrors AS ExceptionErrors
	|		ON JobQueueErrors.ErrorID = ExceptionErrors.ErrorID
	|WHERE
	|	JobQueueErrors.ErrorID IN (&ErrorIds)
	|	AND ExceptionErrors.ErrorID IS NULL";
	QueriesArray.Add(QueryText);
	
	Query.Text = StrConcat(QueriesArray, Common.QueryBatchSeparator());
	
	SetPrivilegedMode(True);
	JobQueueErrors = Query.Execute().Unload();
	SetPrivilegedMode(False);
			
	BeginTransaction();
	
	Try

		RecordSet = InformationRegisters.JobQueueErrors.CreateRecordSet();
		RecordSet.Load(JobQueueErrors);
		SetPrivilegedMode(True);
		RecordSet.Write(ReplacementMode.Delete);
		SetPrivilegedMode(False);

		CommitTransaction();

	Except

		RollbackTransaction();

		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());

		Event = NStr("vi = 'Hàng đợi nhiệm vụ không hiện thời: Xóa dữ liệu về lỗi';
					|ru = 'Неоперативная очередь заданий: Удаление данных об ошибках';
					|en = 'Backdate job queue: Delete error data'; fa = 'Backdate job queue: Delete error data';
					|it = 'Backdate job queue: Delete error data';
					|pl = 'Backdate job queue: Delete error data';
					|tr = 'Operasyonel olmayan iş kuyruğu: Hata verilerinin silinmesi'",
			Common.DefaultLanguageCode());

		WriteLogEvent(Event, EventLogLevel.Error, , , ErrorText);

	EndTry;

EndProcedure

// Checks for the presence of tasks with a higher priority.
// If there are no tasks for the specified parameters for raising priorities, such parameters are deleted.
// 
// Parameters:
//  TaskQueues - See BackdateJobQueueCached.TaskQueues
//
Procedure CheckForTasksWithHigherPriority(TaskQueues)
	
	QueuesTable = TaskQueues.QueuesTable;
	
	Query = New Query;
	SetRequestParametersByQueue(Query, TaskQueues);
	
	QueryTextArray = New Array;
	
	#Region Documents_With_Errors
	
	TextDocumentsWithErrors = "
	|SELECT
	|	ErrorsInDocuments.Document AS Document,
	|	MIN(ErrorsInDocuments.QueueNumber) AS QueueNumber
	|INTO TT_ErrorsInDocuments
	|FROM
	|	&TheTextOfASubquery AS ErrorsInDocuments
	|GROUP BY
	|	ErrorsInDocuments.Document
	|
	|INDEX BY
	|	Document,
	|	QueueNumber";
	
	SubqueryTextTemplate = "
	|SELECT DISTINCT
	|	TableQueue.Document AS Document,
	|	&QueueNumberField AS QueueNumber
	|FROM
	|	&TableQueue AS TableQueue
	|	INNER JOIN InformationRegister.JobQueueErrors AS ErrorRegister
	|		ON TableQueue.ErrorID = ErrorRegister.ErrorID
	|";
	
	ArrayOfSubqueries = New Array;
	
	For Each CurrentQueue In QueuesTable Do

		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);

		QueryTextQueues = StrReplace(QueryTextQueues, "&QueueNumberField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterQueueNumber), "&" + CurrentQueue.RequestParameterQueueNumber,
			"TableQueue.JobKind.QueueNumber"));

		ArrayOfSubqueries.Add(QueryTextQueues);

	EndDo;
	
	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin(True));
	TextDocumentsWithErrors = StrReplace(TextDocumentsWithErrors, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	QueryTextArray.Add(TextDocumentsWithErrors);
	
	#EndRegion
	
	QueryTextPriorities = "
	|SELECT
	|	MonthClosingParameters.Organization AS Organization,
	|	ENDOFPERIOD(MonthClosingParameters.TaskPeriod, MONTH) AS ClosingPeriod
	|INTO TT_MonthClosingParameters
	|FROM
	|	InformationRegister.PriorityJobsOfBackdateJobQueue AS MonthClosingParameters
	|
	|INDEX BY
	|	Organization,
	|	ClosingPeriod";
	QueryTextArray.Add(QueryTextPriorities);
	
	#Region DocumentAssignments
	
	QueryTextDocumentAssignments = "
	|SELECT
	|	TasksToProcess.Organization AS Organization,
	|	TasksToProcess.ClosingPeriod AS ClosingPeriod
	|INTO TT_Jobs
	|FROM
	|	&TheTextOfASubquery AS TasksToProcess
	|
	|INDEX BY
	|	Organization,
	|	ClosingPeriod";
	
	SubqueryTextTemplate = "
	|SELECT DISTINCT
	|	TT_MonthClosingParameters.Organization AS Organization,
	|	ENDOFPERIOD(TT_MonthClosingParameters.ClosingPeriod, MONTH) AS ClosingPeriod
	|FROM
	|	TT_MonthClosingParameters AS TT_MonthClosingParameters
	|		INNER JOIN &TableQueue AS TableQueue
	|		ON TableQueue.Organization = TT_MonthClosingParameters.Organization
	|		AND TableQueue.TaskPeriod <= TT_MonthClosingParameters.ClosingPeriod
	|		
	|		LEFT JOIN TT_ErrorsInDocuments AS Errors
	|		ON TableQueue.Document = Errors.Document
	|		AND &QueueNumberField > Errors.QueueNumber
	|WHERE
	|	TableQueue.CompletedWithAnError = FALSE
	|	AND Errors.Document IS NULL";
	
	ArrayOfSubqueries = New Array;
	
	For Each CurrentQueue In QueuesTable Do

		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);

		QueryTextQueues = StrReplace(QueryTextQueues, "&QueueNumberField", ?(ValueIsFilled(
			CurrentQueue.RequestParameterQueueNumber), "&" + CurrentQueue.RequestParameterQueueNumber,
			"TableQueue.JobKind.QueueNumber"));

		ArrayOfSubqueries.Add(QueryTextQueues);

	EndDo;
	
	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin(True));
	QueryTextDocumentAssignments = StrReplace(QueryTextDocumentAssignments, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	QueryTextArray.Add(QueryTextDocumentAssignments);
	
	#EndRegion
	
	QueryTextTotal = "
	|SELECT
	|	TT_MonthClosingParameters.Organization AS Organization,
	|	BEGINOFPERIOD(TT_MonthClosingParameters.ClosingPeriod, MONTH) AS TaskPeriod
	|FROM
	|	TT_MonthClosingParameters AS TT_MonthClosingParameters
	|		LEFT JOIN TT_Jobs AS TT_Jobs
	|		ON TT_MonthClosingParameters.Organization = TT_Jobs.Organization
	|		AND TT_MonthClosingParameters.ClosingPeriod = TT_Jobs.ClosingPeriod
	|WHERE
	|	TT_Jobs.Organization IS NULL";
	
	QueryTextArray.Add(QueryTextTotal);
	
	Query.Text = StrConcat(QueryTextArray, Common.QueryBatchSeparator());
	
	SetPrivilegedMode(True);
	PriorityTasks = Query.Execute().Unload();
	If PriorityTasks.Count() > 0 Then
		RecordSet = InformationRegisters.PriorityJobsOfBackdateJobQueue.CreateRecordSet();
		RecordSet.Load(PriorityTasks);
		RecordSet.Write(ReplacementMode.Delete);
	EndIf;
	SetPrivilegedMode(False);
		
EndProcedure

Function EndTimeOfScheduledRoutineTask(Schedule, CurrentSessionDate)
	
	StartTime = Date(1, 1, 1, Hour(CurrentSessionDate), Minute(CurrentSessionDate), Second(CurrentSessionDate));
	MaxDate = Date('39991231235959');
	CompletionTime = MaxDate;

	If Schedule.DetailedDailySchedules.Count() > 0 Then

		For Each CurrentSchedule In Schedule.DetailedDailySchedules Do

			DetermineEndTimeAccordingToSchedule(CurrentSchedule, StartTime, CompletionTime);

		EndDo;

	Else

		DetermineEndTimeAccordingToSchedule(Schedule, StartTime, CompletionTime);

	EndIf;

	Return ?(CompletionTime <> MaxDate,
			Date(Year(CurrentSessionDate), Month(CurrentSessionDate), Day(CurrentSessionDate),
				Hour(CompletionTime), Minute(CompletionTime), Second(CompletionTime)),
			Date(1, 1, 1, 0, 0, 0));
		
EndFunction

Procedure DetermineEndTimeAccordingToSchedule(CurrentSchedule, StartTime, CompletionTime)
	
	EndTime = ?(ValueIsFilled(CurrentSchedule.EndTime), CurrentSchedule.EndTime, Date(1, 1, 1, 23, 59, 59));
	
	If StartTime >= CurrentSchedule.BeginTime And StartTime <= EndTime And ValueIsFilled(CurrentSchedule.CompletionTime) Then
		CompletionTime = Min(CurrentSchedule.CompletionTime, CompletionTime);
	EndIf;
	If StartTime >= CurrentSchedule.BeginTime And StartTime <= EndTime And ValueIsFilled(CurrentSchedule.CompletionInterval) Then
		CompletionTime = Min(StartTime + CurrentSchedule.CompletionInterval, CompletionTime);
	EndIf;

EndProcedure

#EndRegion

Function ControlThreadIsRunning(MethodName)
	
	// Checking whether the background task is running.
	Filter = New Structure;
	Filter.Insert("MethodName", MethodName);
	Filter.Insert("State", BackgroundJobState.Active);
	BackgroundJobsManagingThread = BackgroundJobs.GetBackgroundJobs(Filter);
	
	Return BackgroundJobsManagingThread.Count() > 0;
	
EndFunction

// Setting additional request parameters for task queues.
// 
// Parameters:
//  Query - Query - Query
//  TaskQueues - See BackdateJobQueueCached.TaskQueues
//
Procedure SetRequestParametersByQueue(Query, TaskQueues)
	
	QueuesTable = TaskQueues.QueuesTable;
	
	For Each CurrentQueue In QueuesTable Do
		Query.SetParameter(CurrentQueue.ProcessedGranulesTableName, CurrentQueue.CalculationGranules);
		Query.SetParameter(CurrentQueue.RequestParameterTaskType, CurrentQueue.TaskTypeValue);
		Query.SetParameter(CurrentQueue.RequestParameterQueueNumber, CurrentQueue.QueueNumberValue);
	EndDo;
	
EndProcedure

Function DescriptionOfWorkingThread()

	DescriptionOfWorkingThread = New Structure;
	DescriptionOfWorkingThread.Insert("ThreadID", CommonClientServer.BlankUUID());
	DescriptionOfWorkingThread.Insert("QueueRegister", Catalogs.MetadataObjectIDs.EmptyRef());
	DescriptionOfWorkingThread.Insert("ProcedureParameters", New Structure);
	DescriptionOfWorkingThread.Insert("JobKind", Catalogs.BackdateJobKinds.EmptyRef());

	Return DescriptionOfWorkingThread;

EndFunction

#Region MonthEndTransactions

Procedure MonthEndClosingCompleteTasksInNonOperationalQueue(HandlerParameters, TaskQueues)
	
	FileInfobase = Common.FileInfobase();
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	CalculationStart = CalculationParameters.EndOfPeriod;
	
	#Region SettingTaskExecutionPriorities

	CompaniesList = CalculationParameters.CompanyArray;
	CalculationEnd = EndOfMonth(CalculationParameters.EndOfPeriod);
	
	CalculationDataForMonth = CalculationDataForMonth(CalculationEnd, CompaniesList, TaskQueues);
	
	CalculationStart = CalculationDataForMonth.CalculationStart;
	
	CurrentMonthOfSettlement = BegOfMonth(CalculationStart);
	
	TaskSelectionStructure = New Structure;
	
	While CurrentMonthOfSettlement <= CalculationEnd Do

		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(CurrentMonthOfSettlement,
			CompaniesList);

		For Each Organization In AvailableCompanies Do

			TaskSelectionStructure.Insert("Organization", Organization);
			TaskSelectionStructure.Insert("TaskPeriod", CurrentMonthOfSettlement);

			DataForCalculation = CalculationDataForMonth.DataForCalculation.FindRows(TaskSelectionStructure);
			If DataForCalculation.Count() > 0 Then

				RecordManager = InformationRegisters.PriorityJobsOfBackdateJobQueue.CreateRecordManager();
				FillPropertyValues(RecordManager, TaskSelectionStructure);
				RecordManager.Write();

			EndIf;

		EndDo;
		
		CurrentMonthOfSettlement = EndOfMonth(CurrentMonthOfSettlement) + 1;

	EndDo;
	
	For Each CurrentCompany In CalculationDataForMonth.OrganizationsEmptyTaskPeriod Do
		RecordManager = InformationRegisters.PriorityJobsOfBackdateJobQueue.CreateRecordManager();
		RecordManager.Organization = CurrentCompany;
		RecordManager.TaskPeriod = Date(1,1,1);
		RecordManager.Write();
	EndDo;
	
	#EndRegion

	ClosingParameters = ParametersForStartingTaskExecution();
	ClosingParameters.Companies = CalculationParameters.CompanyArray;
	ClosingParameters.ClosingPeriod = CalculationParameters.EndOfPeriod;
	ClosingParameters.Insert("TaskQueues", TaskQueues);

	If FileInfobase Then
		
		CompleteTasksInNonOperationalQueue(ClosingParameters);

	Else

		ThereAreTasksForMonthEndClosing = True;

		While ThereAreTasksForMonthEndClosing Do

			CheckStartExecutionOfNonOperationalTaskQueue();

			TMCommonUse.Pause(5);

			RequestPriorities = New Query;
			RequestPriorities.Text = "SELECT TOP 1
			|	MonthClosingParameters.Organization AS Organization,
			|	MonthClosingParameters.TaskPeriod AS ClosingPeriod
			|FROM
			|	InformationRegister.PriorityJobsOfBackdateJobQueue AS MonthClosingParameters
			|WHERE
			|	MonthClosingParameters.Organization IN (&CompaniesList)
			|	AND MonthClosingParameters.TaskPeriod <= &ClosingPeriod";

			RequestPriorities.SetParameter("CompaniesList", ClosingParameters.Companies);
			RequestPriorities.SetParameter("ClosingPeriod", EndOfMonth(ClosingParameters.ClosingPeriod));
			
			//@skip-check query-in-loop
			// The check is disabled because the control thread should monitor the work in the month closing mode
			// and in the case of processing all queue jobs, it should be completed.
			QueryResult = RequestPriorities.Execute();
	
			ThereAreTasksForMonthEndClosing = Not QueryResult.IsEmpty();

		EndDo;
		
		EndOfExecutionOfNonOperationalTaskQueue();

	EndIf;
	
EndProcedure

Function CalculationDataForMonth(EndOfPeriod, CompanyArray, TaskQueues)

	StructureOfData = New Structure;
	
	CalculationStartPeriod = BegOfMonth(EndOfPeriod);
	StructureOfData.Insert("CalculationStart", CalculationStartPeriod);
	
	Query = New Query;
	Query.SetParameter("EndOfPeriod", EndOfMonth(EndOfPeriod));
	Query.SetParameter("CompanyArray", CompanyArray);
	Query.Text ="
	|SELECT DISTINCT
	|	TasksToProcess.TaskPeriod AS TaskPeriod,
	|	TasksToProcess.Organization AS Organization
	|FROM
	|	&TheTextOfASubquery AS TasksToProcess
	|
	|ORDER BY
	|	TaskPeriod";
		
	SubqueryTextTemplate = "
	|SELECT DISTINCT
	|	BEGINOFPERIOD(CASE
	|		WHEN TableQueue.TaskPeriod = DATETIME(1, 1, 1)
	|			THEN &EndOfPeriod
	|		ELSE TableQueue.TaskPeriod
	|	END, MONTH) AS TaskPeriod,
	|	TableQueue.Organization AS Organization
	|FROM
	|	&TableQueue AS TableQueue
	|WHERE
	|	TableQueue.Organization IN (&CompanyArray)
	|	AND TableQueue.TaskPeriod <= &EndOfPeriod";

	ArrayOfSubqueries = New Array;
	For Each CurrentQueue In TaskQueues.QueuesTable Do
		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);
		ArrayOfSubqueries.Add(QueryTextQueues);
	EndDo;
	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin(True));
	Query.Text = StrReplace(Query.Text, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	
	SetPrivilegedMode(True);
	DataForCalculation = Query.Execute().Unload();
	SetPrivilegedMode(False);
	DataForCalculation.Indexes.Add("Organization, TaskPeriod");
	
	If DataForCalculation.Count() > 0 Then
		StructureOfData.Insert("CalculationStart", DataForCalculation[0].TaskPeriod);
	EndIf;
	
	StructureOfData.Insert("DataForCalculation", DataForCalculation);
	
	RequestEmptyPeriod = New Query;
	RequestEmptyPeriod.SetParameter("EndOfPeriod", EndOfMonth(EndOfPeriod));
	RequestEmptyPeriod.SetParameter("CompanyArray", CompanyArray);
	RequestEmptyPeriod.Text ="
	|SELECT DISTINCT
	|	TasksToProcess.Organization AS Organization
	|FROM
	|	&TheTextOfASubquery AS TasksToProcess";
		
	SubqueryTextTemplate = "
	|SELECT DISTINCT
	|	TableQueue.Organization AS Organization
	|FROM
	|	&TableQueue AS TableQueue
	|WHERE
	|	TableQueue.Organization IN (&CompanyArray)
	|	AND TableQueue.TaskPeriod = DATETIME(1,1,1)";

	ArrayOfSubqueries = New Array;
	For Each CurrentQueue In TaskQueues.QueuesTable Do
		QueryTextQueues = StrReplace(SubqueryTextTemplate, "&TableQueue", CurrentQueue.FullNameOfQueue);
		ArrayOfSubqueries.Add(QueryTextQueues);
	EndDo;
	SubqueryText = StrConcat(ArrayOfSubqueries, TMCommonUse.QuerySeparatorInJoin(True));
	RequestEmptyPeriod.Text = StrReplace(RequestEmptyPeriod.Text, "&TheTextOfASubquery", "(" + SubqueryText + ")");
	
	SetPrivilegedMode(True);
	DataForCalculationIsEmptyPeriod = RequestEmptyPeriod.Execute().Unload();
	SetPrivilegedMode(False);
	StructureOfData.Insert("OrganizationsEmptyTaskPeriod", DataForCalculationIsEmptyPeriod.UnloadColumn("Organization"));
	
	Return StructureOfData;
	
EndFunction

#Region MonthEndClosingOfVerification

// Performs control of the correctness of the generated Registered Records of documents according to the registers of mutual settlements.
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
// 
// Returns:
//  Structure - RegisteredRecord check results:
// * ProblematicDocumentsAmountsInAccountingCurrencies - Array of DocumentRef - The list of documents in which Registered Records of registers 
// of mutual settlements differ from the Registered Records of the register "Amounts of documents in accounting currencies".
// * MWDiscrepanciesInSettlementRegisters - Undefined, TempTablesManager - Contains temporary tables with data 
// on discrepancies in operational and financial registers of mutual settlements by customers and suppliers. 
// The manager of temporary tables includes the following tables: 
// "Calculation of change rates" - contains information about discrepancies in the Registered Records in the registers "Settlements with customers" and "Settlements with customers by terms", 
// "Settlements with suppliers by terms" - contains information about discrepancies in Registered Records in the registers "Settlements with suppliers" and "Settlements with suppliers by terms".
// If no discrepancies are found, the parameter will be passed Undefined.
Function ToCheckRegisteredRecordsOfDocumentsInRegistersOfMutualSettlements(HandlerParameters)
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	CompaniesList = CalculationParameters.CompanyArray;
	CalculationEnd = EndOfMonth(CalculationParameters.EndOfPeriod);

	#Region ReconciliationOfAmountsOfOperationalAndFinancialRegisters
			
	RequestVerification = New Query;
	RequestVerification.TempTablesManager = New TempTablesManager;
	RequestVerification.SetParameter("EndOfPeriod", CalculationEnd);
	RequestVerification.SetParameter("CompanyArray", CompaniesList);
	RequestVerification.SetParameter("ThereAreTasksForStageOfAdditionalVerificationOfDocuments", False);
	
	RequestVerification.Text = QueryTextReconciliationOfAmountsOfOperationalAndFinancialRegisters();
	
	RequestVerification.Execute();

	TableOfProblematicDocuments = RequestVerification.TempTablesManager.Tables["DocumentsWithDiscrepanciesInSettlementRegisters"].GetData().Unload();
	
	If TableOfProblematicDocuments.Count() > 0 Then

		ErrorTextTemplate = NStr(
			"vi = 'Theo chứng từ %1 các bản ghi kết chuyển trong các biểu ghi hạch toán công nợ ""%2"" và ""%3"" không khớp nhau';
			|ru = 'По документу %1 различаются движения в регистрах взаиморасчетов ""%2"" и ""%3""';
			|en = 'For the %1 document, records in the ""%2"" and ""%3"" AR/AP accounting registers differ'; fa = 'For the %1 document, records in the ""%2"" and ""%3"" AR/AP accounting registers differ';
			|it = 'For the %1 document, records in the ""%2"" and ""%3"" AR/AP accounting registers differ';
			|pl = 'For the %1 document, records in the ""%2"" and ""%3"" AR/AP accounting registers differ';
			|tr = '%1 belgesine göre, ""%2"" ve ""%3"" mutabakat kayıtlarındaki hareketler birbirinden farklıdır'",
			Common.DefaultLanguageCode());

		PresentationOfSettlementsWithClients = Metadata.AccumulationRegisters.CustomersARAPAccounting.Presentation();
		PresentationOfSettlementsWithClientsOnTime = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Presentation();
		PresentationOfSettlementsWithSuppliers = Metadata.AccumulationRegisters.VendorsARAPAccounting.Presentation();
		PresentationOfSettlementsWithSuppliersOnTime = Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Presentation();

		For Each TableRow In TableOfProblematicDocuments Do
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTextTemplate,
				TableRow.Document,
				?(TableRow.TheseAreSettlementsWithCustomers, PresentationOfSettlementsWithClients, PresentationOfSettlementsWithSuppliers),
				?(TableRow.TheseAreSettlementsWithCustomers, PresentationOfSettlementsWithClientsOnTime, PresentationOfSettlementsWithSuppliersOnTime));
			
			WriteLogEvent(NStr("vi = 'Các bản ghi kết chuyển của biểu ghi hạch toán công nợ không khớp nhau';
								|ru = 'Расхождения в движениях регистров взаиморасчетов';
								|en = 'Discrepancies in AR/AP accounting register records'; fa = 'Discrepancies in AR/AP accounting register records';
								|it = 'Discrepancies in AR/AP accounting register records';
								|pl = 'Discrepancies in AR/AP accounting register records';
								|tr = 'Mutabakat kayıtlarının hareketlerindeki tutarsızlıklar'",
				Common.DefaultLanguageCode()), EventLogLevel.Error,
				Metadata.CommonModules.MonthEndTransactionsServer, , ErrorText);
				
		EndDo;

	EndIf;

	#EndRegion
	
	#Region DocumentAmountsInAccountingCurrency
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.FindRecordersWithDiscrepanciesInMovementsOfAmountsInAccountingCurrenciesAndSettlementRegisters(
		RequestVerification.TempTablesManager, CalculationEnd);
		
	ProblematicDocumentsAmountsInAccountingCurrencies = CommonClientServer.CollapseArray(
		RequestVerification.TempTablesManager.Tables["ProblematicDocumentsAmountsInAccountingCurrencies"].GetData().Unload().UnloadColumn(
		"Recorder"));

	If ProblematicDocumentsAmountsInAccountingCurrencies.Count() > 0 Then

		PresentationOfAmountOfDocumentsInAccountingCurrencies = Metadata.InformationRegisters.DocumentAmountsInAccountingCurrency.Presentation();

		ErrorTextTemplate = NStr(
			"vi = 'Bản ghi kết chuyển chứng từ %1 theo biểu ghi hạch toán công nợ khác với bản ghi kết chuyển theo biểu ghi ""%2"".';
			|ru = 'Движения документа %1 по регистрам взаиморасчетов отличаются от движений по регистру ""%2"".';
			|en = 'AR/AP accounting register records of the %1 document differ from the ""%2"" register records.'; fa = 'AR/AP accounting register records of the %1 document differ from the ""%2"" register records.';
			|it = 'AR/AP accounting register records of the %1 document differ from the ""%2"" register records.';
			|pl = 'AR/AP accounting register records of the %1 document differ from the ""%2"" register records.';
			|tr = '%1 belgesinin mutabakat kayıtlarındaki hareketleri ""%2""  kaydındaki hareketlerden farklıdır.'",
			Common.DefaultLanguageCode());

		For Each Document In ProblematicDocumentsAmountsInAccountingCurrencies Do

			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTextTemplate, Document,
				PresentationOfAmountOfDocumentsInAccountingCurrencies);

			WriteLogEvent(NStr("vi = 'Các bản ghi kết chuyển của biểu ghi hạch toán công nợ không khớp nhau';
								|ru = 'Расхождения в движениях регистров взаиморасчетов';
								|en = 'Discrepancies in AR/AP accounting register records'; fa = 'Discrepancies in AR/AP accounting register records';
								|it = 'Discrepancies in AR/AP accounting register records';
								|pl = 'Discrepancies in AR/AP accounting register records';
								|tr = 'Mutabakat kayıtlarının hareketlerindeki tutarsızlıklar'",
				Common.DefaultLanguageCode()), EventLogLevel.Error,
				Metadata.CommonModules.MonthEndTransactionsServer, , ErrorText);

		EndDo;

	EndIf;
	
	#EndRegion
	
	CheckResults = New Structure;
	CheckResults.Insert("ProblematicDocumentsAmountsInAccountingCurrencies", ProblematicDocumentsAmountsInAccountingCurrencies);
	If TableOfProblematicDocuments.Count() > 0 Then
		CheckResults.Insert("MWDiscrepanciesInSettlementRegisters", RequestVerification.TempTablesManager);
	Else
		CheckResults.Insert("MWDiscrepanciesInSettlementRegisters", Undefined);
	EndIf;
	
	Return CheckResults;
	
EndFunction

// An attempt is being made to correct the RegisteredRecords of documents according to the registers of mutual settlements.
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//  CheckResults - Structure - RegisteredRecord check results:
// * ProblematicDocumentsAmountsInAccountingCurrencies - Array of DocumentRef - The list of documents in which Registered Records of registers 
// of mutual settlements differ from the Registered Records of the register "Amounts of documents in accounting currencies".
// * MWDiscrepanciesInSettlementRegisters - Undefined, TempTablesManager - Contains temporary tables with data 
// on discrepancies in operational and financial registers of mutual settlements by customers and suppliers. 
// The manager of temporary tables includes the following tables: 
// "Calculation of change rates" - contains information about discrepancies in the Registered Records in the registers "Settlements with customers" and "Settlements with customers by terms", 
// "Settlements with suppliers by terms" - contains information about discrepancies in Registered Records in the registers "Settlements with suppliers" and "Settlements with suppliers by terms".
// If no discrepancies are found, the parameter takes the value Undefined.
//  TaskQueues - See BackdateJobQueueCached.TaskQueues.
Procedure CorrectRegisteredRecordsOfDocumentsInRegistersOfMutualSettlements(HandlerParameters, CheckResults, TaskQueues)
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	#Region DocumentAmountsInAccountingCurrency

	If CheckResults.ProblematicDocumentsAmountsInAccountingCurrencies.Count() > 0 Then
		
		ProblematicDocuments = CheckResults.ProblematicDocumentsAmountsInAccountingCurrencies;
		
		// An attempt to recheck problematic documents.
		For Each Document In ProblematicDocuments Do
	
			Try
				If Not ValueIsFilled(Document) Then
					Continue;
				EndIf;
				DocumentObject = Document.GetObject(); // DocumentObject
				DocumentObject.Write(DocumentWriteMode.Posting);
			Except
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Khi tạo bản ghi kết chuyển theo dữ liệu hạch toán công nợ trong kỳ %1 
									 |khi thử kết chuyển lại chứng từ %2 đã xảy ra lỗi:
									 |%3';
									 |ru = 'При формировании движений по данным взаиморасчетов за период %1 
									 |при попытке перепроведения документа %2 произошла ошибка:
									 |%3';
									 |en = 'When generating the movements by data of mutual settlements for the period %1 
									 |when attempting to repost the %2 document, an error occurred:
									 |%3'; fa = 'When generating the movements by data of mutual settlements for the period %1 
									 |when attempting to repost the %2 document, an error occurred:
									 |%3';
									 |it = 'Durante la formazione dei movimenti in base ai dati dei conti reciproci per il periodo %1
									 |, durante il tentativo di esecuzione del documento %2 si è verificato un errore:
									 |%3';
									 |pl = 'Wystąpił błąd podczas tworzenia ruchów w oparciu o dane wzajemnych rozliczeń za okres %1
									 |, w którym próbowano zmienić położenie dokumentu %2:
									 |%3';
									 |tr = '%1 dönemi için mutabakat verilerine dayalı işlemler oluşturulurken 
									 | %2 belgesi yeniden kaydedilmeye çalışılırken hata oluştu:
									 |%3'"), 
								CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
								Document,
								ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				WriteLogEvent(NStr("vi = 'Cố gắng kết chuyển lại chứng từ';
									|ru = 'Попытка перепроведения документов';
									|en = 'Attempt to repost documents'; fa = 'Attempt to repost documents';
									|it = 'Tentativo di una nuova registrazione dei documenti';
									|pl = 'Próba ponownego przesłania dokumentów';
									|tr = 'Belgelerin yeninden kaydetme girişimi'", Common.DefaultLanguageCode()),
					EventLogLevel.Error, Metadata.CommonModules.MonthEndTransactionsServer, , ErrorText);
			EndTry;
	
		EndDo;
	
	EndIf;

	#EndRegion
	
	#Region ReconciliationOfAmountsOfOperationalAndFinancialRegisters
	
	If CheckResults.MWDiscrepanciesInSettlementRegisters <> Undefined Then
		
		Query = New Query;
		Query.TempTablesManager = CheckResults.MWDiscrepanciesInSettlementRegisters;
		Query.SetParameter("NewCalculations", True);
		Query.SetParameter("CreateTasksForDistributionOfMutualSettlements", True);
		Query.SetParameter("DoNotCheckBanDateAndDoNotCreateChildTasks", False);
		Query.SetParameter("TypesOfRegistrarsWithoutChangeVerification",
			OnlineARAPAccountingServer.ListOfPlanRegistrarTypes());
	
		#Region RegisteringTasks
		
		ArrayOfRequestTexts = New Array;
		ArrayOfRequestTexts.Add(AccumulationRegisters.CustomersARAPAccounting.QueryTextDataForRegistrationOfTasksForDistributionOfSettlements());
		ArrayOfRequestTexts.Add(AccumulationRegisters.VendorsARAPAccounting.QueryTextDataForRegistrationOfTasksForDistributionOfSettlements());
		
		Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
		Query.Execute();
		
		InformationRegisters.JobsForARAPAllocating.CreateTasksBasedOnDataFromValueTable(
				Query.TempTablesManager.Tables["TasksForDistributionOfMutualSettlementsClients"].GetData().Unload());
		InformationRegisters.JobsForARAPAllocating.CreateTasksBasedOnDataFromValueTable(
				Query.TempTablesManager.Tables["TasksForDistributionOfMutualSettlementsSuppliers"].GetData().Unload());
	
		#EndRegion
		
	EndIf;

	#EndRegion
	
	MonthEndClosingCompleteTasksInNonOperationalQueue(HandlerParameters, TaskQueues);
	
EndProcedure

#EndRegion

// The previously registered problems of performing the calculation at the closing stage of the month are removed.
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
// 
Procedure ClearCalculationExecutionProblems(HandlerParameters)
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MIN(Issues.CheckedPeriod) AS CheckedPeriod
	|FROM
	|	InformationRegister.SystemStatusIssues AS Issues
	|WHERE
	|	Issues.Validation = &Validation
	|	AND Issues.Organization IN (&CompanyArray)
	|	AND BEGINOFPERIOD(Issues.CheckedPeriod, MONTH) <= &Period
	|	AND Issues.Importance = VALUE(Enum.AccountingIssueSeverity.Error)";
	
	Query.SetParameter("Validation", MonthEndTransactionsServer.ServiceStageCheck(HandlerParameters.Data_Stage.Code));
	CompanyArray = TMCommonUseClientServer.Array(CalculationParameters.CompanyArray);
	Query.SetParameter("CompanyArray", CompanyArray);
	Query.SetParameter("Period", EndOfMonth(CalculationParameters.EndOfPeriod));
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		If ValueIsFilled(Selection.CheckedPeriod) Then
			
			CurrentMonthOfSettlement = BegOfMonth(Selection.CheckedPeriod);
			CalculationEnd = EndOfMonth(CalculationParameters.EndOfPeriod);
			
			While CurrentMonthOfSettlement <= CalculationEnd Do
				
				MonthEndTransactionsServer.ClearCalculationExecutionProblems(HandlerParameters.Data_Stage.Code,
					CompanyArray, CurrentMonthOfSettlement);

				CurrentMonthOfSettlement = EndOfMonth(CurrentMonthOfSettlement) + 1;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Registration of problems of operation is performed at the closing stage of the month.
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//  TaskQueues - See BackdateJobQueueCached.TaskQueues
//  JobKind - Undefined, CatalogRef.BackdateJobKinds - Type of task
//
Procedure CheckAndRegisterProblemsWithCalculation(HandlerParameters, TaskQueues, JobKind = Undefined)
	
	QueuesTable = TaskQueues.QueuesTable;
	
	For Each CurrentQueue In QueuesTable Do
		
		TaskRegisterManager = CurrentQueue.TaskRegisterManager; // InformationRegisterManager
		TaskRegisterManager.RegisterCalculationExecutionProblem(HandlerParameters, JobKind);
		
	EndDo;
	
EndProcedure

Procedure RegisterTasksForRecalculatingCalculationsByTimeAfterSwitchingToOnline(HandlerParameters)
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	CompaniesList = CalculationParameters.CompanyArray;
	CalculationEnd = EndOfMonth(CalculationParameters.EndOfPeriod);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("EndOfPeriod", CalculationEnd);
	Query.SetParameter("CompanyArray", CompaniesList);
	Query.SetParameter("ThereAreTasksForStageOfAdditionalVerificationOfDocuments", False);
	Query.SetParameter("IsBlankString", "");
	
	Query.Text = QueryTextOfRegisteredRecordsOfCalculationsOnTimeAfterTransitionToOnline();
	
	Query.Execute();
	
	Query.SetParameter("NewCalculations", True);
	Query.SetParameter("CreateTasksForDistributionOfMutualSettlements", True);
	Query.SetParameter("DoNotCheckBanDateAndDoNotCreateChildTasks", False);
	Query.SetParameter("TypesOfRegistrarsWithoutChangeVerification",
		OnlineARAPAccountingServer.ListOfPlanRegistrarTypes());

	#Region RegisteringTasks
	
	ArrayOfRequestTexts = New Array;
	ArrayOfRequestTexts.Add(AccumulationRegisters.CustomersARAPAccounting.QueryTextDataForRegistrationOfTasksForDistributionOfSettlements());
	ArrayOfRequestTexts.Add(AccumulationRegisters.VendorsARAPAccounting.QueryTextDataForRegistrationOfTasksForDistributionOfSettlements());
	
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	Query.Execute();
	
	InformationRegisters.JobsForARAPAllocating.CreateTasksBasedOnDataFromValueTable(
			Query.TempTablesManager.Tables["TasksForDistributionOfMutualSettlementsClients"].GetData().Unload());
	InformationRegisters.JobsForARAPAllocating.CreateTasksBasedOnDataFromValueTable(
			Query.TempTablesManager.Tables["TasksForDistributionOfMutualSettlementsSuppliers"].GetData().Unload());
	
	#EndRegion
		
EndProcedure

#Region CheckingCorrectnessOfSettlementData

// Generates the text of the request for reconciliation of Registered Records in the operational and financial registers of mutual settlements by amounts.
// The check is performed based on the list of organizations in the closing period, which is set in the month-endclosing parameters.
// For each organization, the periods in which the month-end closing operation has already been performed
// according to the stage "Formation of Registered Records for settlements with partners and reassessment of settlements" are excluded from the audit.
// The result of the query execution will show the identified discrepancies by tuples (analytics, accounting partners, account object, Currency) with details 
// up to the registrar document, period and organization and will place the results in the following temporary tables:
// 
// - Calculation of Change rates - contains information about discrepancies in Registered Records in the registers "Settlements with customers" and "Settlements with customers by time".
// The table of discrepancies will be used in the formation of tasks for the distribution of settlements.
// 
// - Payments by suppliers of change - contains information about discrepancies in Registered Records in the registers "Settlements with suppliers" and "Settlements with suppliers by time".
// The table of discrepancies will be used in the formation of tasks for the distribution of settlements.
// 
// - Document of discrepancies in the registers of mutual settlements - contains information about the registrars for which discrepancies were found 
// in the operational and financial registers of mutual settlements.
// 
// Returns:
//  String - Query text
Function QueryTextReconciliationOfAmountsOfOperationalAndFinancialRegisters()
	
	QueryText = "
	|SELECT
	|	MIN(JobsForMonthEndClosing.Month) AS Month,
	|	JobsForMonthEndClosing.Organization AS Organization
	|INTO TT_PeriodsOfClosing
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS JobsForMonthEndClosing
	|		LEFT JOIN InformationRegister.SetUpLockFromChanges AS SetUpLockFromChanges
	|		ON JobsForMonthEndClosing.Organization = SetUpLockFromChanges.Organization
	|WHERE
	|	JobsForMonthEndClosing.Operation = VALUE(Catalog.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation)
	|	AND JobsForMonthEndClosing.Month >= ISNULL(SetUpLockFromChanges.LockUntil, DATETIME(1, 1, 1))
	|	AND JobsForMonthEndClosing.Organization IN (&CompanyArray)
	|	AND NOT &ThereAreTasksForStageOfAdditionalVerificationOfDocuments
	|GROUP BY
	|	JobsForMonthEndClosing.Organization
	|
	|INDEX BY
	|	Month,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfDiscrepancies.DocumentRecorder AS Document,
	|	TableOfDiscrepancies.Period AS Period,
	|	TableOfDiscrepancies.Period AS RecorderDate,
	|	TableOfDiscrepancies.AccountingDimensionByPartners.Organization AS Organization,
	|	TableOfDiscrepancies.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TableOfDiscrepancies.ARAPObject AS ARAPObject,
	|	TableOfDiscrepancies.Currency AS Currency,
	|	SUM(TableOfDiscrepancies.SumTurnover) - SUM(TableOfDiscrepancies.AmountByTimeFrame) AS Sum,
	|	0 AS AmountDue,
	|	0 AS ToShip,
	|	0 AS SumCompl,
	|	0 AS SumMan
	|INTO SettlementsWithCustomersChanges
	|FROM
	|	(SELECT
	|		Calculations.DocumentRecorder AS DocumentRecorder,
	|		Calculations.Period AS Period,
	|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject AS ARAPObject,
	|		Calculations.Currency AS Currency,
	|		CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.Prepayment - Calculations.Debt
	|			ELSE Calculations.Debt - Calculations.Prepayment
	|		END AS AmountByTimeFrame,
	|		0 AS SumTurnover
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|			INNER JOIN TT_PeriodsOfClosing AS TT_PeriodsOfClosing
	|			ON Calculations.Period >= TT_PeriodsOfClosing.Month
	|			AND Calculations.Period <= &EndOfPeriod
	|			AND Calculations.AccountingDimensionByPartners.Organization = TT_PeriodsOfClosing.Organization
	|	WHERE
	|		Calculations.Active
	|		AND NOT Calculations.DocumentRecorder REFS Document.RegisterAdjustment
	|		AND Calculations.AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Calculations.Recorder AS DocumentRecorder,
	|		Calculations.Period AS Period,
	|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject AS ARAPObject,
	|		Calculations.Currency AS Currency,
	|		0 AS AmountByTimeFrame,
	|		CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Calculations.Sum
	|			ELSE Calculations.Sum
	|		END AS SumTurnover
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting AS Calculations
	|			INNER JOIN TT_PeriodsOfClosing AS TT_PeriodsOfClosing
	|			ON Calculations.Period >= TT_PeriodsOfClosing.Month
	|			AND Calculations.Period <= &EndOfPeriod
	|			AND Calculations.AccountingDimensionByPartners.Organization = TT_PeriodsOfClosing.Organization
	|	WHERE
	|		Calculations.Active
	|		AND NOT Calculations.Recorder REFS Document.RegisterAdjustment
	|		AND Calculations.AccountingDimensionByPartners.Organization IN (&CompanyArray)) AS TableOfDiscrepancies
	|GROUP BY
	|	TableOfDiscrepancies.DocumentRecorder,
	|	TableOfDiscrepancies.Period,
	|	TableOfDiscrepancies.AccountingDimensionByPartners,
	|	TableOfDiscrepancies.ARAPObject,
	|	TableOfDiscrepancies.Currency,
	|	TableOfDiscrepancies.AccountingDimensionByPartners.Organization
	|HAVING
	|	SUM(TableOfDiscrepancies.AmountByTimeFrame) <> SUM(TableOfDiscrepancies.SumTurnover)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfDiscrepancies.DocumentRecorder AS Document,
	|	TableOfDiscrepancies.Period AS Period,
	|	TableOfDiscrepancies.Period AS RecorderDate,
	|	TableOfDiscrepancies.AccountingDimensionByPartners.Organization AS Organization,
	|	TableOfDiscrepancies.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TableOfDiscrepancies.ARAPObject AS ARAPObject,
	|	TableOfDiscrepancies.Currency AS Currency,
	|	SUM(TableOfDiscrepancies.SumTurnover) - SUM(TableOfDiscrepancies.AmountByTimeFrame) AS Sum,
	|	0 AS AmountDue,
	|	0 AS ToReceive,
	|	0 AS SumCompl,
	|	0 AS SumMan
	|INTO VendorsARAPAccountingChanges
	|FROM
	|	(SELECT
	|		Calculations.DocumentRecorder AS DocumentRecorder,
	|		Calculations.Period AS Period,
	|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject AS ARAPObject,
	|		Calculations.Currency AS Currency,
	|		CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.Prepayment - Calculations.Debt
	|			ELSE Calculations.Debt - Calculations.Prepayment
	|		END AS AmountByTimeFrame,
	|		0 AS SumTurnover
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|			INNER JOIN TT_PeriodsOfClosing AS TT_PeriodsOfClosing
	|			ON Calculations.Period >= TT_PeriodsOfClosing.Month
	|			AND Calculations.Period <= &EndOfPeriod
	|			AND Calculations.AccountingDimensionByPartners.Organization = TT_PeriodsOfClosing.Organization
	|	WHERE
	|		Calculations.Active
	|		AND NOT Calculations.DocumentRecorder REFS Document.RegisterAdjustment
	|		AND Calculations.AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Calculations.Recorder AS DocumentRecorder,
	|		Calculations.Period AS Period,
	|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject AS ARAPObject,
	|		Calculations.Currency AS Currency,
	|		0 AS AmountByTimeFrame,
	|		CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.Sum
	|			ELSE -Calculations.Sum
	|		END AS SumTurnover
	|	FROM
	|		AccumulationRegister.VendorsARAPAccounting AS Calculations
	|			INNER JOIN TT_PeriodsOfClosing AS TT_PeriodsOfClosing
	|			ON Calculations.Period >= TT_PeriodsOfClosing.Month
	|			AND Calculations.Period <= &EndOfPeriod
	|			AND Calculations.AccountingDimensionByPartners.Organization = TT_PeriodsOfClosing.Organization
	|	WHERE
	|		Calculations.Active
	|		AND NOT Calculations.Recorder REFS Document.RegisterAdjustment
	|		AND Calculations.AccountingDimensionByPartners.Organization IN (&CompanyArray)) AS TableOfDiscrepancies
	|GROUP BY
	|	TableOfDiscrepancies.DocumentRecorder,
	|	TableOfDiscrepancies.Period,
	|	TableOfDiscrepancies.AccountingDimensionByPartners,
	|	TableOfDiscrepancies.ARAPObject,
	|	TableOfDiscrepancies.Currency,
	|	TableOfDiscrepancies.AccountingDimensionByPartners.Organization
	|HAVING
	|	SUM(TableOfDiscrepancies.AmountByTimeFrame) <> SUM(TableOfDiscrepancies.SumTurnover)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SettlementsWithCustomersChanges.Document AS Document,
	|	SettlementsWithCustomersChanges.Organization AS Organization,
	|	TRUE AS TheseAreSettlementsWithCustomers
	|INTO DocumentsWithDiscrepanciesInSettlementRegisters
	|FROM
	|	SettlementsWithCustomersChanges AS SettlementsWithCustomersChanges
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VendorsARAPAccountingChanges.Document AS Document,
	|	VendorsARAPAccountingChanges.Organization AS Organization,
	|	FALSE AS TheseAreSettlementsWithCustomers
	|FROM
	|	VendorsARAPAccountingChanges AS VendorsARAPAccountingChanges";
	
	Return QueryText;
	
EndFunction

// The request generates a list of documents, the Registered Records for which were transferred 
// from the registers of calculations for documents as a result of switching to online calculations.
// The request uses the parameters for closing the month (list of organizations, closing period).
// Documents of periods in which 
// the month closing Operation "Formation of Registered Records for settlements with partners and revaluation of settlements" has already been completed are excluded from the resulting request.
// 
// Returns:
//  String - Query text
Function QueryTextOfRegisteredRecordsOfCalculationsOnTimeAfterTransitionToOnline()
	
	QueryText = "
	|SELECT
	|	MIN(JobsForMonthEndClosing.Month) AS Month,
	|	JobsForMonthEndClosing.Organization AS Organization
	|INTO TTOpenPeriods
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS JobsForMonthEndClosing
	|		LEFT JOIN InformationRegister.SetUpLockFromChanges AS SetUpLockFromChanges
	|		ON JobsForMonthEndClosing.Organization = SetUpLockFromChanges.Organization
	|WHERE
	|	JobsForMonthEndClosing.Operation = VALUE(Catalog.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation)
	|	AND JobsForMonthEndClosing.Month >= ISNULL(SetUpLockFromChanges.LockUntil, DATETIME(1, 1, 1))
	|	AND JobsForMonthEndClosing.Organization IN (&CompanyArray)
	|	AND NOT &ThereAreTasksForStageOfAdditionalVerificationOfDocuments
	|GROUP BY
	|	JobsForMonthEndClosing.Organization
	|
	|INDEX BY
	|	Month,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Calculations.DocumentRecorder AS Document,
	|	Calculations.Period AS Period,
	|	Calculations.Period AS RecorderDate,
	|	Calculations.AccountingDimensionByPartners.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency AS Currency,
	|	1 AS Sum,
	|	0 AS AmountDue,
	|	0 AS ToShip,
	|	0 AS SumCompl,
	|	0 AS SumMan
	|INTO SettlementsWithCustomersChanges
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|	INNER JOIN TTOpenPeriods AS OpenedPeriods
	|		ON Calculations.Period >= OpenedPeriods.Month
	|		AND Calculations.Period <= &EndOfPeriod
	|		AND Calculations.AccountingDimensionByPartners.Organization = OpenedPeriods.Organization
	|WHERE
	|	Calculations.Active
	|	AND NOT Calculations.DocumentRecorder REFS Document.RegisterAdjustment
	|	AND Calculations.AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|	AND Calculations.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|	AND Calculations.FinRecordID = &IsBlankString
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Calculations.DocumentRecorder AS Document,
	|	Calculations.Period AS Period,
	|	Calculations.Period AS RecorderDate,
	|	Calculations.AccountingDimensionByPartners.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency AS Currency,
	|	1 AS Sum,
	|	0 AS AmountDue,
	|	0 AS ToReceive,
	|	0 AS SumCompl,
	|	0 AS SumMan
	|INTO VendorsARAPAccountingChanges
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|	INNER JOIN TTOpenPeriods AS OpenedPeriods
	|		ON Calculations.Period >= OpenedPeriods.Month
	|		AND Calculations.Period <= &EndOfPeriod
	|		AND Calculations.AccountingDimensionByPartners.Organization = OpenedPeriods.Organization
	|WHERE
	|	Calculations.Active
	|	AND NOT Calculations.DocumentRecorder REFS Document.RegisterAdjustment
	|	AND Calculations.AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|	AND Calculations.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|	AND Calculations.FinRecordID = &IsBlankString
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SettlementsWithCustomersChanges.Document AS Document,
	|	SettlementsWithCustomersChanges.Organization AS Organization,
	|	TRUE AS TheseAreSettlementsWithCustomers
	|INTO DocumentsWithTransferredRegisteredRecordsInRegistersOfMutualSettlements
	|FROM
	|	SettlementsWithCustomersChanges AS SettlementsWithCustomersChanges
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VendorsARAPAccountingChanges.Document AS Document,
	|	VendorsARAPAccountingChanges.Organization AS Organization,
	|	FALSE AS TheseAreSettlementsWithCustomers
	|FROM
	|	VendorsARAPAccountingChanges AS VendorsARAPAccountingChanges";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion