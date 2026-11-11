///////////////////////////////////////////////////////////////
// The Deferred Tasks module contains procedures and functions for
// working with the deferred tasks mechanism.
//
///////////////////////////////////////////////////////////////

#Region Public

// Handles tasks.
//
// Parameters:
//  Jobs - Structure - key: name of the job queue information register
//                        value: - Structure - keys match the names of dimensions, resources
//                                                      , and Attributes of the job register.
//                                  - ValueTable - The column names match the names of the dimensions, resources
//                                                      , and Attributes of the job information register.
//  GenerateRecordId - Boolean - if TRUE, then the record ID will be generated
//                                              automatically. The default is TRUE.
//
Procedure ToProcess(Jobs, GenerateRecordId = True) Export
	
	TaskTable = InitializeTaskTable(Jobs);
	
	Add(Jobs, GenerateRecordId, TaskTable);
	
	Run(TaskTable);
	
EndProcedure

// Handles queue tasks.
//
// Parameters:
//  Queue - String - name of the task queue information register
//  Data - Structure, ValueTable - The structure keys and column names of the table match the names of dimensions,
//                                        resources, and Attributes of the job register.
//  GenerateRecordId - Boolean - if TRUE, then the record ID will be generated
//                                              automatically. The default is TRUE.
//
Procedure ProcessQueueTasks(Queue, Data, GenerateRecordId = True) Export
	
	TaskTable = InitializeTaskTable(Queue);
	
	AddTasksToQueue(Queue, Data, GenerateRecordId, TaskTable);
	
	Run(TaskTable);
	
EndProcedure

// Adds tasks.
//
// Parameters:
//  Jobs - Structure - key: name of the job queue information register
//                        value: - Structure - keys match the names of dimensions, resources
//                                                      , and Attributes of the job register.
//                                  - ValueTable - The column names match the names of the dimensions, resources
//                                                      , and Attributes of the job information register.
//  GenerateRecordId - See AddTasksToQueue.GenerateRecordId
//  TaskTable                   - See AddTasksToQueue.TaskTable
//
//
Procedure Add(Jobs, GenerateRecordId = False, TaskTable = Undefined) Export
	
	If Jobs.Count() = 1 Then
		
		For Each Job In Jobs Do
			
			AddTasksToQueue(Job.Key, Job.Value, GenerateRecordId, TaskTable);
			
		EndDo;
		
	Else
		
		QueuesTable = TaskQueues();
		QueuesTable.Indexes.Add("Queue");
		
		ListOfQueues = New ValueList;
		For Each Job In Jobs Do
			
			Queue      = Job.Key;
			RowIndex = QueuesTable.FindRows(New Structure("Queue", Queue))[0].RowIndex;
			
			ListOfQueues.Add(RowIndex, Queue);
			
		EndDo;
		
		ListOfQueues.SortByValue();
		For Each QueueElement In ListOfQueues Do
			
			Queue = QueueElement.Presentation;
			
			AddTasksToQueue(Queue, Jobs[Queue], GenerateRecordId, TaskTable);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds tasks to the queue.
//
// Parameters:
//  Queue - String - name of the task queue information register
//  Data - Structure, ValueTable - The structure keys and column names of the table match the names of dimensions,
//                                        resources, and Attributes of the job register.
//  GenerateRecordId - Boolean - if TRUE, then the record ID will be generated
//                                              automatically. The default is FALSE.
//  TaskTable - ValueTable - See InitializeTaskTable
//                                     1. In the file database:
//                                     1.1 if the parameter of the Execute Transaction queue in the File database = TRUE, then
//                                         the tasks are added to the Tasks column in the line corresponding to the queue,
//                                     1.2 if the parameter of the Execute Transaction queue in the File database = FALSE, then:
//                                     1.2.1 tasks are added to the Tasks column in the line corresponding to the queue,
//                                     1.2.2 tasks are added to the information register of the task queue,
//                                     2. in the client-server database:
//                                     2.1 tasks are added to the Tasks column in the row corresponding to the queue,
//                                     2.2 Tasks are added to the information register of the task queue.
//                 - Undefined - 1. In the file database, tasks are transferred for execution,
//                                  2. In the client-server database, tasks are added to the information register of the task queue.
//                                  Undefined by default.
//
Procedure AddTasksToQueue(
			Queue,
			Data,
			GenerateRecordId = False,
			TaskTable = Undefined) Export
	
	DataType          = TypeOf(Data);
	TypeTableOfValues = Type("ValueTable");
	StructureType       = Type("Structure");
	
	If DataType <> TypeTableOfValues And DataType <> StructureType Then
		Raise StrTemplate(NStr("vi = 'Kiểu dữ liệu không xác định ""%1"" của nhiệm vụ hoãn lại.';
								|ru = 'Неизвестный тип данных ""%1"" отложенного задания.';
								|en = 'Unknown %1 data type of the deferred job.'; fa = 'Unknown %1 data type of the deferred job.';
								|it = 'Неизвестный тип данных ""%1"" отложенного задания.';
								|pl = 'Unknown %1 data type of the deferred job.';
								|tr = 'Ertelenen görevin bilinmeyen ""%1"" veri türü.'"), DataType);
	EndIf;
	
	CurrentTaskTable = Undefined;
	
	FilterQueue = New Structure("Queue", Queue);
	
	TableQueue = TaskQueues().Copy(FilterQueue, LaunchFields());
	
	StartTaskCompletion = TableQueue.Columns.Find("ExecuteInTransactionInFileDatabase") <> Undefined;
	
	If StartTaskCompletion Then
		
		TableOfTasksToBeCompleted = ?(TaskTable = Undefined,
										InitializeTaskTable(Queue),
										TaskTable);
		
		If TableQueue[0].ExecuteInTransactionInFileDatabase Or Common.DebugMode() Then
			SourceOfTasks       = TableOfTasksToBeCompleted.FindRows(FilterQueue)[0].Jobs;
		Else
			SourceOfTasks       = InformationRegisters[Queue].CreateRecordSet();
			CurrentTaskTable = TableOfTasksToBeCompleted.FindRows(FilterQueue)[0].Jobs;
		EndIf;
		
	Else
		
		SourceOfTasks = InformationRegisters[Queue].CreateRecordSet();
		
		If ValueIsFilled(TaskTable) Then
			CurrentTaskTable = TaskTable.FindRows(FilterQueue)[0].Jobs;
		EndIf;
		
	EndIf;
	
	If TypeOf(SourceOfTasks) = TypeTableOfValues Then
		
		If DataType = Type("ValueTable") Then
			
			For Each DataString1 In Data Do
				SourceRow = SourceOfTasks.Add();
				FillInTaskSourceLine(SourceRow, DataString1, GenerateRecordId);
			EndDo;
			
		ElsIf DataType = Type("Structure") Then
			
			SourceRow = SourceOfTasks.Add();
			FillInTaskSourceLine(SourceRow, Data, GenerateRecordId);
			
		EndIf;
		
	Else
		
		RecordsCount = 0;
		
		BeginTransaction();
		
		Try
			
			If DataType = TypeTableOfValues Then
				
				For Each DataString1 In Data Do
					
					SourceRow = SourceOfTasks.Add();
					FillInTaskSourceLine(SourceRow, DataString1, GenerateRecordId);
					
					If CurrentTaskTable <> Undefined Then
						FillPropertyValues(CurrentTaskTable.Add(), SourceRow);
					EndIf;
					
					RecordsCount = RecordsCount + 1;
					If RecordsCount = 1000 Then
						
						SetPrivilegedMode(True);
						SourceOfTasks.Write(False);
						SetPrivilegedMode(False);
						
						SourceOfTasks = InformationRegisters[Queue].CreateRecordSet();
						
						RecordsCount = 0;
						
					EndIf;
					
				EndDo;
				
			ElsIf DataType = StructureType Then
				
				SourceRow = SourceOfTasks.Add();
				FillInTaskSourceLine(SourceRow, Data, GenerateRecordId);
				
				If CurrentTaskTable <> Undefined Then
					FillPropertyValues(CurrentTaskTable.Add(), SourceRow);
				EndIf;
				
				RecordsCount = RecordsCount + 1;
				
			EndIf;
			
			If RecordsCount > 0 Then
			
				SetPrivilegedMode(True);
				SourceOfTasks.Write(False);
				SetPrivilegedMode(False);
			
			EndIf;
			
			CommitTransaction();
		
		Except
			
			RollbackTransaction();
			
			WriteErrorToEventLog(
				Queue,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			Raise StrTemplate(NStr("vi = 'Không thể thêm bản ghi vào biểu ghi hàng đợi ""%1"" do:
													|%2.';
													|ru = 'Не удалось добавить запись в регистр очереди ""%1"" по причине:
													|%2.';
													|en = 'Cannot add a record to the ""%1"" queue register. Reason:
													|%2.'; fa = 'Cannot add a record to the ""%1"" queue register. Reason:
													|%2.';
													|it = 'Не удалось добавить запись в регистр очереди ""%1"" по причине:
													|%2.';
													|pl = 'Cannot add a record to the ""%1"" queue register. Reason:
													|%2.';
													|tr = '""%1"" sıra kaydı şu nedenle eklenemedi:
													|%2.'"), Queue, BriefErrorDescription);
			
		EndTry;
		
	EndIf;
	
	If StartTaskCompletion And TaskTable = Undefined Then
	
		Run(TableOfTasksToBeCompleted);
		
	EndIf;
	
EndProcedure

// Starts task execution.
//
// Parameters:
//  DataOfQueue - String, Array of String, ValueTable, Undefined -
//             1. String - name of the job queue information register
//             2. Array of String - names of registers of information of job queues
//             3. Task Tables - See InitializeTaskTable
//             4. Undefined     - starts all queues.
//
Procedure Run(Val DataOfQueue = Undefined) Export
	
	FileInfobase = Common.FileInfobase();
	DebugMode               = Common.DebugMode();
	
	QueueType = TypeOf(DataOfQueue);
	
	QueuesTable = Undefined;
	
	If QueueType = Type("ValueTable") Then
		
		TaskQueues = TaskQueues().Copy(, LaunchFields());
		TaskQueues.Indexes.Add("Queue");
		
		QueuesTable = DataOfQueue;
		QueuesTable.Columns.Add("RowIndex", TaskQueues.Columns.RowIndex.ValueType);
		
		If TaskQueues.Columns.Find("ExecuteInTransactionInFileDatabase") <> Undefined Then
			
			QueuesTable.Columns.Add(
				"ExecuteInTransactionInFileDatabase",
				TaskQueues.Columns.ExecuteInTransactionInFileDatabase.ValueType);
			
		EndIf;
		
		For Each TableRow In QueuesTable Do
			
			FillPropertyValues(
				TableRow,
				TaskQueues.FindRows(New Structure("Queue", TableRow.Queue))[0]);
			
		EndDo;
		
		If DebugMode Then
			QueuesTable.FillValues(True, "ExecuteInTransactionInFileDatabase");
		EndIf;
		
		If QueuesTable.Count() > 1 Then
			QueuesTable.Sort("RowIndex", New CompareValues);
		EndIf;
		
	ElsIf Not FileInfobase And Not DebugMode Then
		
		If QueueType = Type("String") Then
			
			QueuesTable = TaskQueues().Copy(New Structure("Queue", DataOfQueue), LaunchFields());
			
		ElsIf QueueType = Type("Array") Then
			
			If DataOfQueue.Count() = 1 Then
				
				QueuesTable = TaskQueues().Copy(New Structure("Queue", DataOfQueue[0]), LaunchFields());
				
			Else
				
				TaskQueues = TaskQueues().Copy(, LaunchFields());
				TaskQueues.Indexes.Add("Queue");
				
				QueuesTable = TaskQueues.CopyColumns();
				
				For Each Queue In DataOfQueue Do
					
					FillPropertyValues(
						QueuesTable.Add(),
						TaskQueues.FindRows(New Structure("Queue", Queue))[0]);
					
				EndDo;
				
				QueuesTable.Sort("RowIndex", New CompareValues);
				
			EndIf;
			
		Else
			
			QueuesTable = TaskQueues().Copy(, LaunchFields());
			
		EndIf;
		
	EndIf;
	
	If QueuesTable <> Undefined Then
		
		If FileInfobase Or DebugMode Then
			
			RunInFileDatabase(QueuesTable);
			
		Else
			
			ExecuteStart(QueuesTable);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns a description of the task completion error
//
// Parameters:
//  Fields          - Structure - names and Presentations of the fields involved in generating the error description
//  Data        - Structure, QueryResultSelection, ValueTableRow - Task Data
//  ErrorText   - String - error text
//
// Returns:
//  String - error text
//
Function ExecutionErrorText(Fields, Data, ErrorText) Export
	
	ErrorsTexts    = New Array;
	JobDetails = New Array;
	
	ErrorsTexts.Add(ErrorText);
	
	UserMessages = GetUserMessages(True);
	If UserMessages.Count() > 0 Then
		
		ErrorsTexts.Add("");
		
		For Each Message In UserMessages Do
			ErrorsTexts.Add(Message.Text);
		EndDo;
		
	EndIf;
	
	For Each Field In Fields Do
		
		Name           = Field.Key;
		Presentation = Field.Value;
		
		If Not ValueIsFilled(Presentation) Then
			Presentation = Name;
		EndIf;
		
		JobDetails.Add(StrTemplate("%1: %2", Presentation, Data[Name]));
		
	EndDo;
	
	ErrorTemplate = NStr("vi = 'Lỗi xử lý dữ liệu:
							   |
							   |%1
							   |
							   |%2';
							   |ru = 'Ошибка обработки задания:
							   |
							   |%1
							   |
							   |%2';
							   |en = 'An error occurred while processing the job:
							   |
							   |%1
							   |
							   |%2'; fa = 'An error occurred while processing the job:
							   |
							   |%1
							   |
							   |%2';
							   |it = 'Ошибка обработки задания:
							   |
							   |%1
							   |
							   |%2';
							   |pl = 'An error occurred while processing the job:
							   |
							   |%1
							   |
							   |%2';
							   |tr = 'Görev işleme hatası:
							   |
							   |%1
							   |
							   |%2'");
	
	Separator  = ";
					|";
	
	Return StrTemplate(ErrorTemplate, StrConcat(JobDetails, Separator), StrConcat(ErrorsTexts, Chars.LF));
	
EndFunction

// Initializes the task table that can be passed to the method input See Run
// 
// Parameters:
//  DataOfQueue - String, Array of String, Structure, Undefined - queues to initialize
//                                                                the task table for. If Undefined, then the returned table
//                                                                does not initialize specific queues.
//                                                                Undefined by default.
//
// Returns:
//  ValueTable - Task Table:
//   * Queue - String - name of the task queue information register.
//   * Jobs - ValueTable - The columns of the value table correspond to the structure of the job queue information register.
//
Function InitializeTaskTable(DataOfQueue = Undefined) Export
	
	Table = New ValueTable;
	Table.Columns.Add("Queue", Common.StringTypeDetails(150));
	Table.Columns.Add("Jobs", New TypeDescription("ValueTable"));
	Table.Indexes.Add("Queue");
	
	If ValueIsFilled(DataOfQueue) Then
		
		QueueType = TypeOf(DataOfQueue);
		
		If QueueType = Type("String") Then
			
			TableRow = Table.Add();
			TableRow.Queue = DataOfQueue;
			TableRow.Jobs = InformationRegisters[DataOfQueue].CreateRecordSet().UnloadColumns();
			
		ElsIf QueueType = Type("Array") Then
			
			For Each Queue In DataOfQueue Do
				
				TableRow = Table.Add();
				TableRow.Queue = Queue;
				TableRow.Jobs = InformationRegisters[Queue].CreateRecordSet().UnloadColumns();
				
			EndDo;
			
		Else
			
			For Each QueueElement In DataOfQueue Do
				
				Queue = QueueElement.Key;
				
				TableRow = Table.Add();
				TableRow.Queue = Queue;
				TableRow.Jobs = InformationRegisters[Queue].CreateRecordSet().UnloadColumns();
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return Table;
	
EndFunction

// Checks and adds a queue job table
// 
// Parameters:
//  Queue - See AddTasksToQueue.Queue
//  Table - See InitializeTaskTable
// 
// Returns:
//  ValueTable - The columns of the value table correspond to the structure of the job queue information register.
//
Function CheckAddTaskTable(Queue, Table) Export
	
	FoundRows = Table.FindRows(New Structure("Queue", Queue));
	If FoundRows.Count() = 0 Then
		
		TableRow = Table.Add();
		TableRow.Queue = Queue;
		TableRow.Jobs = InformationRegisters[Queue].CreateRecordSet().UnloadColumns();
		
	Else
		
		TableRow = FoundRows[0];
		
	EndIf;
	
	Return TableRow.Jobs;
	
EndFunction

// Returns a table of queue tasks.
//
// Parameters:
//  Queue - String    - name of the task queue information register.
//  Filter   - Structure - the structure of the selection of records of the task queue information register:
//                        keys - the names of measurements, resources, Attributes of the task queue information register,
//                        value - a single value or an array of values.
//
// Returns:
//  ValueTable - queue task table.
//
Function GetJobs(Queue, Filter) Export
	
	Query = New Query;
	
	QueryText =
	"SELECT
	|	*
	|FROM
	|	JobsQueue AS Table
	|WHERE
	|	&Filter
	|";
	
	FilterTexts = New Array;
	
	For Each FilterElement In Filter Do
		
		FieldName      = FilterElement.Key;
		Simple = FilterElement.Value;
		
		FilterTemplate = ?(TypeOf(Simple) = Type("Array"), "Table.%1 IN (&%1)", "Table.%1 = &%1");
		
		FilterTexts.Add(StrTemplate(FilterTemplate, FieldName));
		
		Query.SetParameter(FieldName, Simple);
		
	EndDo;
	
	Separator = " And
				  |";
	
	QueryText = StrReplace(QueryText, "JobsQueue", StrTemplate("%1.%2", "InformationRegister", Queue));
	QueryText = StrReplace(QueryText, "&Filter",         StrConcat(FilterTexts, Separator));
	
	Query.Text = QueryText;
	
	SetPrivilegedMode(True);
	Jobs = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Return Jobs;
	
EndFunction

#EndRegion

#Region Internal

// Returns a table of job queues.
//
// Returns:
//  ValueTable - Task Queues:
//   * Queue                           - String - name of the task queue information register.
//   * MethodName                         - String - the name of the task execution method, the principle of formation is similar
//                                                  to the argument method name of the general purpose method.Perform
//                                                  (See Common.ExecuteConfigurationMethod.MethodName)the Configuration method.
//   * ActionPointer                 - String - the name of the task queue register field that defines the name
//                                                  of the task execution method. The tasks will be completed in the context of this field.
//                                                  The action pointer must be included in the calculation analytics list
//                                                  (Calculation Analytics parameter).
//                                                  It makes sense if the methodname is not filled in.
//   * MethodNamesByPointerValues  - Map of KeyAndValue - the matching of values is configured 
//                                                  An action pointer with the names of the task execution methods
//                                                  (See AddNestedQueue).
//                                                  It makes sense if the methodname is not filled in.
//   * Multithreaded                     - Boolean - indicates whether tasks in the queue are being executed with multiple threads.
//   * ThreadsCount                 - Number  - the number of threads (background jobs) to perform pending
//                                                  queue jobs, by default 4
//                                                  (See DeferredJobsOverridable.DefaultNumberOfThreads).
//   * MaximumThreadsNumber     - Number  - the maximum number of threads (background jobs) that can
//                                                  be started to complete tasks in this queue. Makes sense for
//                                                  queues with nested queues
//                                                  (as an example, the queue "Universal queue of operational tasks").
//                                                  If 0, then the maximum number of threads is not controlled.
//                                                  By default, 0.
//   * PortionOfCalculation                     - Number  - The number of tasks to be transferred to the workflow
//                                                  is 100 by default
//                                                  (See DeferredJobsOverridable.DefaultCalculationPortion).
//   * TaskAllocationMode         - String - the mode of distributing tasks by threads:
//                                                   1. "EVENLY_BY_THREADS" - tasks are evenly distributed
//                                                                                across free streams,
//                                                   2. "MAXIMUM TASK_IN_FLOW" - the maximum
//                                                                                   possible number of tasks are transferred to the stream.
//                                                  By default, "MAX_PROBLEM_IN_FLOW".
//   * DimensionCalculation                  - String - A comma-separated list of job queue information register fields
//                                                  that define a job. If it is not filled in,
//                                                  then one register entry is considered one job.
//   * ProcessingInterval                 - Number  - processing interval (in seconds) between the start of the Cur sample
//                                                  and the end of the last portion of the calculation:
//                                                    1. If the processing interval is greater than 0, then the selection and execution
//                                                       of tasks occurs when one of the following
//                                                       conditions occurs:
//                                                         1. The number of tasks in the sample is not less than a portion of the calculation,
//                                                         2. The interval between the Cur date and the end date of
//                                                            the last batch of tasks is not less than the processing interval,
//                                                    2. If the processing interval is 0, then the processing interval does
//                                                       not affect the selection and execution of tasks.
//   * Priority                         - Number  - has only an informative meaning, is displayed in the interface,
//                                                  possible values:
//                                                    1. -1 - high (blocks operational work -
//                                                            inventory distribution, documents cannot be printed ...),
//                                                    2. 0 - medium,
//                                                    3. 1 is low.
//   * CompleteTasksInTransaction       - Boolean - tasks of one portion are performed in a transaction, by default FALSE.
//   * ExecuteInTransactionInFileDatabase - Boolean - if FALSE, then in the file database the tasks are executed in the control
//                                                  thread,
//                                                  if TRUE, then in the file database they are executed in the same transaction.
//                                                  The default is TRUE.
//   * DefaultSelectionOfTasks         - Boolean - if TRUE, then the Query Text is used to select tasks
//                                                  generated in the function See QueryTextOfDefaultTaskSelection
//                                                  , 
//                                                  if FALSE, then the task selection Query Text
//                                                  
//                                                  (See InformationRegisters.JobsForProcessingProductionStages.TaskSelectionQueryText)is generated in the Task Selection Query text function of the Task Queue Information Register manager module
//                                                  .
//                                                  The default is TRUE.
//   * AdditionalErrorProcessing     - Boolean - if TRUE, then the procedure is started in the task execution method
//                                                  (See CompleteJobs)before error handling
//                                                  Processing errors in the Task queue Information register manager module
//                                                  (See InformationRegisters.JobsForProcessingProductionStages.BeforeErrorHandling).
//                                                  The default is FALSE.
//   * RowIndex                      - Number  - The service field stores the index of the Cur row.
//
Function TaskQueues() Export
	
	NumberType1 = Common.TypeDescriptionNumber(1);
	NumberType3 = Common.TypeDescriptionNumber(3,, AllowedSign.Nonnegative);
	NumberType6 = Common.TypeDescriptionNumber(6,, AllowedSign.Nonnegative);
	BooleanType = New TypeDescription("Boolean");
	
	QueuesTable = New ValueTable;
	QueuesTable.Columns.Add("Queue",                           Common.StringTypeDetails(150));
	QueuesTable.Columns.Add("MethodName",                         Common.StringTypeDetails(1000));
	QueuesTable.Columns.Add("ActionPointer",                 Common.StringTypeDetails(1000));
	QueuesTable.Columns.Add("MethodNamesByPointerValues",  New TypeDescription("Map"));
	QueuesTable.Columns.Add("Multithreaded",                     BooleanType);
	QueuesTable.Columns.Add("ThreadsCount",                 NumberType3);
	QueuesTable.Columns.Add("MaximumThreadsNumber",     NumberType6);
	QueuesTable.Columns.Add("PortionOfCalculation",                     NumberType6);
	QueuesTable.Columns.Add("TaskAllocationMode",         Common.StringTypeDetails(24));
	QueuesTable.Columns.Add("DimensionCalculation" ,                 Common.StringTypeDetails(0));
	QueuesTable.Columns.Add("ProcessingInterval",                 NumberType6);
	QueuesTable.Columns.Add("Priority",                         NumberType1);
	QueuesTable.Columns.Add("CompleteTasksInTransaction",       BooleanType);
	QueuesTable.Columns.Add("ExecuteInTransactionInFileDatabase", BooleanType);
	QueuesTable.Columns.Add("DefaultSelectionOfTasks",         BooleanType);
	QueuesTable.Columns.Add("AdditionalErrorProcessing",     BooleanType);
	QueuesTable.Columns.Add("RowIndex",                      NumberType6);
	QueuesTable.Indexes.Add("Queue");
	
	MetaRegister = Metadata.InformationRegisters;
	
	Parameters = TaskQueueParameters();
	Parameters.Queue           = MetaRegister.UniversalQueueOfRealTimeJobs.Name;
	Parameters.ActionPointer = "Job";
	Parameters.DimensionCalculation  = "Object, Job";
	AddQueue(QueuesTable, Parameters);
	Parameters = TaskQueueParameters();
	Parameters.Queue          = MetaRegister.JobsForCalculatingProductionOperationQueue.Name;
	Parameters.MethodName        = "InformationRegisters.QueueOfProductionOperations.CalculateQueueDeferred";
	Parameters.DimensionCalculation = "ObjectOfARAP";
	AddQueue(QueuesTable, Parameters);
	Parameters = TaskQueueParameters();
	Parameters.Queue          = MetaRegister.JobsOfStandardProductionDurationCalculation.Name;
	Parameters.MethodName        = "InformationRegisters.StandardProductionDuration.PerformTheCalculation";
	Parameters.DimensionCalculation = "ObjectOfARAP";
	AddQueue(QueuesTable, Parameters);
	Parameters = TaskQueueParameters();
	Parameters.Queue                           = MetaRegister.JobsForProcessingProductionStages.Name;
	Parameters.MethodName                         = "Documents.ProductionStage2_2.ProcessDocumentDeferred";
	Parameters.DimensionCalculation                  = "ProductionStage";
	Parameters.ExecuteInTransactionInFileDatabase = False;
	Parameters.DefaultSelectionOfTasks         = False;
	Parameters.AdditionalErrorProcessing     = True;
	AddQueue(QueuesTable, Parameters);
	Parameters = TaskQueueParameters();
	Parameters.Queue           = MetaRegister.JobsForAllocatingInventory.Name;
	Parameters.MethodName         = "InventoryAllocation.PerformDistributionInBackground";
	Parameters.ThreadsCount = 1;
	Parameters.PortionOfCalculation     = 200;
	Parameters.DimensionCalculation  = "Products, Characteristic, Warehouse";
	AddQueue(QueuesTable, Parameters);
	Parameters = TaskQueueParameters();
	Parameters.Queue                     = MetaRegister.TasksOfCalculatingDurationBeforeReleaseByProductionStages.Name;
	Parameters.MethodName                   = "Documents.ProductionStage2_2.CalculateShiftsOfStagesWithinBatch";
	Parameters.DimensionCalculation            = "ProductionLot";
	Parameters.CompleteTasksInTransaction = False;
	AddQueue(QueuesTable, Parameters);
	
	Parameters = TaskQueueParameters();
	Parameters.Queue                     = MetaRegister.JobsForTargetProductionScheduleCalculation.Name;
	Parameters.MethodName                   = "InformationRegisters.StandardScheduleOfProductionStages.ProcessTasksForCalculatingStandardProductionSchedule";
	Parameters.DimensionCalculation            = "ObjectOfARAP";
	Parameters.CompleteTasksInTransaction = False;
	AddQueue(QueuesTable, Parameters);
	Parameters = TaskQueueParameters();
	Parameters.Queue                     = MetaRegister.JobsForPostingPlanningDocumentsInBudgeting.Name;
	Parameters.MethodName                   = "BudgetingServer.PerformReflectionOfPlanningDocumentsInBudgeting";
	Parameters.DimensionCalculation            = "Document";
	Parameters.ExecuteInTransactionInFileDatabase = False;
	AddQueue(QueuesTable, Parameters);
	
	Parameters = TaskQueueParameters();
	Parameters.Queue                     = MetaRegister.JobsOfRecordingLimitsByBudgetingData.Name;
	Parameters.MethodName                   = "LimitsByBudgetingDataServer.ReflectLimitsBasedOnBudgetingData";
	Parameters.DimensionCalculation            = "Document";
	Parameters.ExecuteInTransactionInFileDatabase = False;
	AddQueue(QueuesTable, Parameters);
	Parameters = TaskQueueParameters();
	Parameters.Queue          = MetaRegister.JobsToReflectOrderState.Name;
	Parameters.MethodName        = "DocumentsStates.ReflectDocumentStatesInStateRegisters";
	Parameters.DimensionCalculation = "Document";
	AddQueue(QueuesTable, Parameters);
	
	Parameters = TaskQueueParameters();
	Parameters.Queue          = MetaRegister.JobsToRecordInOtherAssetsLiabilities.Name;
	Parameters.MethodName        = "OtherAssetsLiabilitiesServer.ReflectOtherAssetsAndLiabilities";
	Parameters.DimensionCalculation = "Document";
	AddQueue(QueuesTable, Parameters);
	
	Parameters = TaskQueueParameters();
	Parameters.Queue                     = MetaRegister.JobsToNotifyUsers.Name;
	Parameters.MethodName                   = "UserNotificationsOfEvents.CompleteTasksForNotifyingUsers";
	Parameters.DimensionCalculation            = "NotificationKind";
	Parameters.ExecuteInTransactionInFileDatabase = False;
	AddQueue(QueuesTable, Parameters);
	
	Parameters = TaskQueueParameters();
	Parameters.Queue                     = MetaRegister.JobsForARAPAllocating.Name;
	Parameters.MethodName                   = "InformationRegisters.JobsForARAPAllocating.PerformDeferredDistributionOfSettlements";
	Parameters.DimensionCalculation            = "AccountingDimensionByPartners, ARAPObject, Currency";
	Parameters.PortionOfCalculation               = BackdateJobQueueCached.PortionSizeDistributionOfSettlementsByTime();
	Parameters.TaskAllocationMode   = "Max_OfTasks_In_Stream";
	Parameters.AdditionalErrorProcessing = True;
	Parameters.DefaultSelectionOfTasks = False;
	AddQueue(QueuesTable, Parameters);
	Parameters = TaskQueueParameters();
	Parameters.Queue           = MetaRegister.JobsForCalculatingItemLinksByChangeOrders.Name;
	Parameters.MethodName         = "InformationRegisters.ItemLinksByChangeOrders.CalculateRelationshipOfMaterialsAndAnaloguesInPlanning";
	Parameters.ThreadsCount = 1;
	Parameters.DimensionCalculation  = "Resolution";
	AddQueue(QueuesTable, Parameters);
	DeferredJobsOverridable.TaskQueues(QueuesTable);
	
	Return QueuesTable;
	
EndFunction

// Adds a nested queue.
// 
// Parameters:
//  TaskQueues            - See TaskQueues
//  Queue                   - See AddTasksToQueue.Queue
//  ValueOfActionPointer - AnyRef - The Value Of The Action Pointer
//  MethodName                 - String - the name of the task execution method, the principle of formation is similar
//                                       to the argument method name of the general purpose method.Perform
//                                       (See Common.ExecuteConfigurationMethod.MethodName)the Configuration method.
//
Procedure AddNestedQueue(TaskQueues, Queue, ValueOfActionPointer, MethodName) Export
	
	TaskQueues.FindRows(New Structure("Queue", Queue))[0].MethodNamesByPointerValues.Insert(
		ValueOfActionPointer,
		MethodName);
	
EndProcedure

// Starts the control flow
//
// Parameters:
//  QueuesTable        - See ExecuteStart.QueuesTable
//  WriteError - Boolean - If TRUE, then the control thread startup error is recorded in the registration Log.
//
Procedure Starter(QueuesTable, WriteError = False) Export
	
	DebugMode = Common.DebugMode();
	
	HasJobs = QueuesTable.Columns.Find("Jobs") <> Undefined;
	
	If DebugMode Then
	
		For Each TableRow In QueuesTable Do
			
			Queue = TableRow.Queue;
			
			ExecutionParameters = TimeConsumingOperations.ProcedureExecutionParameters();
			ExecutionParameters.BackgroundJobDescription = StrTemplate("%1 ""%2""",
																			NStr("vi = 'Quản lý luồng';
																				|ru = 'Управляющий поток';
																				|en = 'Thread of control'; fa = 'Thread of control';
																				|it = 'Управляющий поток';
																				|pl = 'Thread of control';
																				|tr = 'Kontrol akışı'"),
																			Queue);
			ExecutionParameters.BackgroundJobKey         = ControlFlowKey(Queue);
			ExecutionParameters.RunInBackground              = True;
			ExecutionParameters.WaitCompletion           = 0;
			
			Try
				
				TimeConsumingOperations.ExecuteProcedure(
					ExecutionParameters,
					"DeferredJobs.ThreadOfControl",
					Queue,
					?(HasJobs And ValueIsFilled(TableRow.Jobs), TableRow.Jobs, Undefined));
				
			Except
				
				// Background task "Control flow"<Queue view>"" with the key "Control Flow_<Queue>"
				// already running.
				
				If WriteError Then
					
					WriteLogEvent(
						NameOfControlFlowStartEvent(),
						EventLogLevel.Error,
						Metadata.InformationRegisters[Queue],,
						ErrorProcessing.DetailErrorDescription(ErrorInfo()));
								
				EndIf;
				
			EndTry;
			
		EndDo;
		
	Else
		
		For Each TableRow In QueuesTable Do
			
			Queue = TableRow.Queue;
			
			ControlFlowParameters = New Array;
			ControlFlowParameters.Add(Queue);
			
			If HasJobs And ValueIsFilled(TableRow.Jobs) Then
				ControlFlowParameters.Add(TableRow.Jobs);
			EndIf;
			
			NameOfControlFlow = StrTemplate("%1 ""%2""",
														NStr("vi = 'Quản lý luồng';
															|ru = 'Управляющий поток';
															|en = 'Thread of control'; fa = 'Thread of control';
															|it = 'Управляющий поток';
															|pl = 'Thread of control';
															|tr = 'Kontrol akışı'"),
														Queue);
			
			Try
				
				BackgroundJobs.Execute(
					"DeferredJobs.ThreadOfControl",
					ControlFlowParameters,
					ControlFlowKey(Queue),
					NameOfControlFlow);
				
			Except
				
				// Background task "Control flow"<Queue view>"" with the key "Control Flow_<Queue>"
				// already running.
				
				If WriteError Then
					
					WriteLogEvent(
						NameOfControlFlowStartEvent(),
						EventLogLevel.Error,
						Metadata.InformationRegisters[Queue],,
						ErrorProcessing.DetailErrorDescription(ErrorInfo()));
								
				EndIf;
				
			EndTry;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ControlFlowStarter(Queue = "") Export
	
	FilterUP = New Structure;
	FilterUP.Insert("Key",      ParametersOfControlFlowStarter().Key);
	FilterUP.Insert("State", BackgroundJobState.Active);
	
	Pause(20,, FilterUP);
	
	Filter = Undefined;
	
	If ValueIsFilled(Queue) Then
		Filter = New Structure;
		Filter .Insert("Queue", Queue);
	EndIf;
	
	If Common.FileInfobase() Then
		
		If Filter = Undefined Then
			Filter = New Structure;
		EndIf;
		
		Filter.Insert("ExecuteInTransactionInFileDatabase", False);
		
	EndIf;
	
	QueuesTable = ?(ValueIsFilled(Filter), TaskQueues().Copy(Filter), TaskQueues());
	
	If QueuesTable.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = QueryTextSignificantQueues(QueuesTable);
	
	If Not ValueIsFilled(QueryText) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If Not QueryResult.IsEmpty() Then
		Starter(QueryResult.Unload());
	EndIf;
	
EndProcedure

// Selects tasks and starts the execution of selected tasks.
//
// Parameters:
//  Queue - String - name of the task queue information register,
//  Jobs - ValueTable - if the parameter of the just-flowing task of this method takes the value
//                               1. TRUTH, then only these zanadnia are fulfilled,
//                               2. FALSE, then the availability of job data in the job queue information register is monitored
//                                  (a lock is set on job data).
//                              The columns of the value table correspond to the structure of the job queue information register.
//          - Undefined - The selection takes place according to the information register of the job queue.
//                           Undefined by default.
//  ProcessOnlyCurrentJobs - Boolean - if TRUE, then only the tasks passed in the parameter are executed
//                                            Tasks (for more details, see the description of the Task parameter).
//                                            It makes sense if the Task parameter is filled in.
//                                            The default is FALSE.
//
Procedure ThreadOfControl(Queue, Jobs = Undefined, ProcessOnlyCurrentJobs = False) Export
	
	If Jobs <> Undefined And Not ProcessOnlyCurrentJobs Then
		
		BeginTransaction();
		
		Try
			
			MetaOfRegister = Metadata.InformationRegisters[Queue];
			
			Block = New DataLock;
			
			LockItem = Block.Add(StrTemplate("InformationRegister.%1", Queue));
			LockItem.Mode          = DataLockMode.Exclusive;
			LockItem.DataSource = Jobs;
			
			For Each RegisterDimension In MetaOfRegister.Dimensions Do
				DimensionName = RegisterDimension.Name;
				LockItem.UseFromDataSource(DimensionName, DimensionName);
			EndDo;
			
			Block.Lock();
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			WriteLogEvent(
				NameOfControlFlowStartEvent(),
				EventLogLevel.Error,
				MetaOfRegister,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndIf;
	
	FileInfobase = Common.FileInfobase();
	DebugMode               = Common.DebugMode();
	
	CompleteOnlyCurrentTasks = Jobs <> Undefined And ProcessOnlyCurrentJobs;
	
	QueueParameters = TaskQueueParameters();
	FillPropertyValues(QueueParameters, TaskQueues().FindRows(New Structure("Queue", Queue))[0]);
	
	ThereIsActionPointer             = Not ValueIsFilled(QueueParameters.MethodName)
										And ValueIsFilled(QueueParameters.ActionPointer);
	ActionPointer				  = ?(ThereIsActionPointer, QueueParameters.ActionPointer, "");
	MethodNamesByPointerValues  = QueueParameters.MethodNamesByPointerValues;
	NumberOfWorkThreads		  = ?(QueueParameters.Multithreaded
											And (Not Common.DataSeparationEnabled()
												Or Not Common.SeparatedDataUsageAvailable()),
													QueueParameters.ThreadsCount,
													1);
	MaximumThreadsNumber	  = QueueParameters.MaximumThreadsNumber;
	PortionOfCalculation					  = QueueParameters.PortionOfCalculation;
	TaskAllocationMode		  = QueueParameters.TaskAllocationMode;
	ExecuteInTransactionInFileDatabase = QueueParameters.ExecuteInTransactionInFileDatabase;
	ProcessingInterval				  = ?(Not FileInfobase And Not CompleteOnlyCurrentTasks,
											QueueParameters.ProcessingInterval,
											0);
	
	WorkFlows                        = Undefined;
	IdsPassedForExecution = Undefined;
	
	Timeouts                             = Undefined;
	
	If DebugMode Then
		
		ProcessingInterval = 0;
		
		NameOfWorkflowMethod = NameOfWorkflowMethod(Queue);
		
		QueueParameters.CompleteTasksInTransaction = False;
		
	ElsIf FileInfobase Then
		
		NameOfWorkflowMethod = NameOfWorkflowMethod(Queue);
		
		If ExecuteInTransactionInFileDatabase Then
			QueueParameters.CompleteTasksInTransaction = False;
		Else
			Timeouts = Timeouts();
		EndIf;
		
	Else
		
		ArrayOfQueues = New Array;
		ArrayOfQueues.Add(Queue);
		
		SettingsTable  = QueuesSettings(ArrayOfQueues);
		
		QueueSettings = ?(SettingsTable.Count() = 0,
								New Structure("Queue, Suspended_, LastProcessingDate", Queue, False),
								SettingsTable[0]);
		
		If QueueSettings.Suspended_ Then
			Return;
		EndIf;
		
		If ThereIsActionPointer Or NumberOfWorkThreads > 1 Then
			WorkFlows = WorkFlows();
		Else
			NameOfWorkflowMethod = NameOfWorkflowMethod(Queue);
		EndIf;
		
		If Not CompleteOnlyCurrentTasks Then
			Timeouts = Timeouts();
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(ProcessingInterval) Then
		PauseProcessingInterval(QueueSettings, ProcessingInterval);
	EndIf;
	
	NumberOfWorkFlowJobs = NumberOfWorkThreads
									  * PortionOfCalculation 
									  * ?(ThereIsActionPointer,
									  		QueueParameters.MethodNamesByPointerValues.Count(),
									  		1);
	
	Query = New Query;
	
	If CompleteOnlyCurrentTasks Then
		
		JobsCount               = Jobs.Count();
		NumberOfWorkFlowJobs = Min(NumberOfWorkFlowJobs, JobsCount);
		
		Query.SetParameter("JobsQueue", Jobs);
		
	EndIf;
	
	Query.Text = TaskSelectionQueryText(Query, QueueParameters, NumberOfWorkFlowJobs);
	
	TaskTable = TaskTable(Query, IdsPassedForExecution, Queue, ActionPointer, Timeouts);
	
	NumberOfRowsToProcess_ = TaskTable.Count();
	
	If NumberOfRowsToProcess_ > 0 Then
		
		FilterProcessed    = New Structure("Processed", False);
		FilterId = New Structure("Processed, JobID", False);
		
		If ThereIsActionPointer Then
			
			FilterProcessed.Insert(ActionPointer);
			FilterId.Insert(ActionPointer);
			
			FilterActionPointer = New Structure("Processed", False);
			
			TableOfActionPointers = TableOfActionPointers(TaskTable, ActionPointer);
			
			FillPropertyValues(FilterProcessed, TableOfActionPointers[0]);
			
			QueueParameters.MethodName = MethodNamesByPointerValues.Get(FilterProcessed[ActionPointer]);
			
			CheckTasksInSelection = True;
			
		Else
			
			CheckTasksInSelection = Not CompleteOnlyCurrentTasks
										Or JobsCount > NumberOfWorkFlowJobs;
			
		EndIf;
		
		FoundRowsToBeProcessed = TaskTable.FindRows(FilterProcessed);
		NumberOfRowsToProcess_ = FoundRowsToBeProcessed.Count();
		
		PortionTable = TaskTable.CopyColumns();
		PortionTable.Columns.Delete("Processed");
		
		CountIterations = NumberOfWorkThreads;
		
		MaximumNumberOfThreadsHasBeenExceeded = False;
		
		PortionsByStreams = CalculatePortionsByStreams(
							TaskTable,
							FilterProcessed,
							CountIterations,
							PortionOfCalculation,
							TaskAllocationMode);
		
	EndIf;
	
	While NumberOfRowsToProcess_ > 0 And CountIterations > 0 Do
		
		FillPropertyValues(FilterId, FoundRowsToBeProcessed[0]);
		
		FoundTaskLines = TaskTable.FindRows(FilterId);
		For Each TableRow In FoundTaskLines Do
			FillPropertyValues(PortionTable.Add(), TableRow);
			TableRow.Processed = True;
		EndDo;
		
		PortionsByStreams[0] = PortionsByStreams[0] - 1;
		
		FoundRowsToBeProcessed = TaskTable.FindRows(FilterProcessed);
		NumberOfRowsToProcess_ = FoundRowsToBeProcessed.Count();
		
		If NumberOfRowsToProcess_ = 0 Or PortionsByStreams[0] = 0 Then
			
			If FileInfobase And ExecuteInTransactionInFileDatabase Or DebugMode Then
				
				Common.ExecuteConfigurationMethod(
					NameOfWorkflowMethod,
					WorkflowParameters(
						QueueParameters,
						DataParameters(PortionTable),
						False,
						FileInfobase And ExecuteInTransactionInFileDatabase));
				
			ElsIf WorkFlows = Undefined Then
				
				// Jobs are executed in the background job of the control thread.
				
				CompleteTasksInBackgroundOfControlFlow(
					NameOfWorkflowMethod,
					QueueParameters,
					PortionTable.Copy());
				
			Else
				
				AddWorkflow(WorkFlows, QueueParameters, PortionTable.Copy());
				
			EndIf;
			
			PortionsByStreams.Delete(0);
			
			PortionTable.Clear();
			
			CountIterations = CountIterations - 1;
			
			If MaximumThreadsNumber > 0
			   And MaximumThreadsNumber <= NumberOfActiveWorkThreads(QueueParameters, True) Then
				
				MaximumNumberOfThreadsHasBeenExceeded = True;
				
			EndIf;
			
		EndIf;
		
		If (NumberOfRowsToProcess_ = 0 Or CountIterations = 0) And ThereIsActionPointer Then
			
			// The value of the current pointer
			
			FoundLinesAreActionPointers = TableOfActionPointers.FindRows(FilterProcessed);
			
			If NumberOfRowsToProcess_ = 0 Then
				TableOfActionPointers.Delete(FoundLinesAreActionPointers[0]);
			Else
				FoundLinesAreActionPointers[0].Processed = True;
			EndIf;
			
			// The value of the next pointer
			
			If TableOfActionPointers.Count() > 0 Then
				
				FoundLinesAreActionPointers = TableOfActionPointers.FindRows(FilterActionPointer);
				If FoundLinesAreActionPointers.Count() > 0 Then
					FillPropertyValues(FilterProcessed, FoundLinesAreActionPointers[0]);
				Else
					TableOfActionPointers.FillValues(False, "Processed");
					FillPropertyValues(FilterProcessed, TableOfActionPointers[0]);
				EndIf;
				
				QueueParameters.MethodName = MethodNamesByPointerValues.Get(
												FilterProcessed[ActionPointer]);
				
				FoundRowsToBeProcessed = TaskTable.FindRows(FilterProcessed);
				NumberOfRowsToProcess_ = FoundRowsToBeProcessed.Count();
				
				CountIterations = 0;
				
			EndIf;
			
		EndIf;
		
		If NumberOfRowsToProcess_ = 0 And CheckTasksInSelection Then
			
			If ValueIsFilled(ProcessingInterval) Then
				PauseProcessingInterval(QueueSettings, ProcessingInterval);
			EndIf;
			
			If ValueIsFilled(IdsPassedForExecution)
			   And (Not FileInfobase Or Not ExecuteInTransactionInFileDatabase)
			   And Not DebugMode Then
				IdsPassedForExecution = Undefined;
			EndIf;
			
			IdsPassedForExecution(WorkFlows, TaskTable, IdsPassedForExecution);
			
			TaskTable = TaskTable(
								Query,
								IdsPassedForExecution,
								Queue,
								ActionPointer,
								Timeouts);
			
			NumberOfRowsToProcess_ = TaskTable.Count();
			
			If NumberOfRowsToProcess_ > 0 Then
				
				If ThereIsActionPointer Then
					
					TableOfActionPointers = TableOfActionPointers(TaskTable, ActionPointer);
					
					FillPropertyValues(FilterProcessed, TableOfActionPointers[0]);
					
					QueueParameters.MethodName = MethodNamesByPointerValues.Get(
													FilterProcessed[ActionPointer]);
					
				EndIf;
				
				FoundRowsToBeProcessed = TaskTable.FindRows(FilterProcessed);
				NumberOfRowsToProcess_ = FoundRowsToBeProcessed.Count();
				
				CountIterations = 0;
				
			EndIf;
			
		EndIf;
		
		If CountIterations = 0 And NumberOfRowsToProcess_ > 0 Then
			
			CountIterations = NumberOfWorkThreads
								 - MonitorWorkFlows(WorkFlows, QueueParameters);
			
			PortionsByStreams = CalculatePortionsByStreams(
								TaskTable,
								FilterProcessed,
								CountIterations,
								PortionOfCalculation,
								TaskAllocationMode);
			
		ElsIf MaximumNumberOfThreadsHasBeenExceeded And CountIterations > 0 And NumberOfRowsToProcess_ > 0 Then
			
			MonitorWorkFlows(WorkFlows, QueueParameters);
			
			MaximumNumberOfThreadsHasBeenExceeded = False;
			
		EndIf;
		
	EndDo;
	
	If Not DebugMode Then
		
		If Not FileInfobase Then
			
			QueueParameters.MaximumThreadsNumber = 0;
			MonitorWorkFlows(WorkFlows, QueueParameters, True);
			
			If Not CompleteOnlyCurrentTasks Then
				
				StartStarterOfControlFlow();
				
			EndIf;
			
		ElsIf Not ExecuteInTransactionInFileDatabase And Not CompleteOnlyCurrentTasks Then
			
			StartStarterOfControlFlow();
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Performs tasks
//
// Parameters:
//  QueueParameters            - See TaskQueueParameters
//  DataParameters             - See DataParameters
//  RecordError         - Boolean - if TRUE, then if an error occurs, the task is deleted from
//                                         the task queue information register and added to 
//                                         the "Error Completion of the assigned tasks" register.
//  ProcessInCurrentSession    - Boolean - if TRUE, then the jobs are executed in this transaction.
//                                         If an error occurs during the execution of tasks, if
//                                         the error parameter is UNDEFINED, an exception is raised.
//  ErrorText                 - String, Undefined - if the type is a String, then the text
//                                                       of the error that occurred is returned to this parameter.
//                                                       UNDEFINED by default.
//  AdditionalProperties       - Structure, Undefined - the necessary data to pass to the
//                                                           task execution method.
//                                                           UNDEFINED by default.
//
Procedure CompleteJobs(
			QueueParameters,
			DataParameters,
			RecordError,
			ProcessInCurrentSession,
			ErrorText = Undefined,
			AdditionalProperties = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Queue                     = QueueParameters.Queue;
	MethodName                   = QueueParameters.MethodName;
	CompleteTasksInTransaction = QueueParameters.CompleteTasksInTransaction;
	
	BackgroundSessionJob = GetCurrentInfoBaseSession().GetBackgroundJob();
	If BackgroundSessionJob <> Undefined Then
		UserToCheckPeriodClosingDates = Constants.UserToCheckPeriodClosingDatesWhenPerformingQueueTasks.Get();
		PeriodClosingDates.SetUserToCheckDatesOfBan(UserToCheckPeriodClosingDates);
	EndIf;
	
	Data = DataParameters.Data;
	
	Parameters = New Array;
	Parameters.Add(Data);
	Parameters.Add(New Map); // See DeleteTasks.Errors
	Parameters.Add(AdditionalProperties);
	
	If ProcessInCurrentSession Then
		
		ExceptionText = "";
		
		Try
			
			StandardProcessing = False;
			
			Common.ExecuteConfigurationMethod(MethodName, Parameters);
			
			StandardProcessing = True;
			
			Errors = Parameters[1];
			If Errors.Count() > 0 Then
				ExceptionText = ErrorPresentation(Errors);
			EndIf;
			
		Except
			
			If StandardProcessing Then
				
				TextOfCurrentError = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				
				WriteErrorToEventLog(Queue, TextOfCurrentError);
				
			Else
				
				//An exception was raised in the execution method
				TextOfCurrentError = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				
			EndIf;
			
			If Not ValueIsFilled(ExceptionText) Then
				ExceptionText = TextOfCurrentError;
			EndIf;
			
		EndTry;
		
		If ValueIsFilled(ExceptionText) Then
			
			If ErrorText = Undefined Then
				
				Common.MessageToUser(ExceptionText);
				
				If TransactionActive() Then
					Raise ExceptionText;
				EndIf;
				
			Else
				ErrorText = ExceptionText;
			EndIf;
			
		EndIf;
		
	Else
		
		ExceptionText = "";
		
		If CompleteTasksInTransaction Then
			
			BeginTransaction();
			
			Try
				
				Common.ExecuteConfigurationMethod(MethodName, Parameters);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				
				WriteErrorToEventLog(Queue, ExceptionText);
				
			EndTry;
			
		Else
			
			Try
				
				Common.ExecuteConfigurationMethod(MethodName, Parameters);
				
			Except
				
				ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				
				WriteErrorToEventLog(Queue, ExceptionText);
				
			EndTry;
			
		EndIf;
		
		Errors = Parameters[1];
		
		If Not ValueIsFilled(ExceptionText) Then
			
			Try
				
				If RecordError And ValueIsFilled(Errors) Then
					
					If QueueParameters.AdditionalErrorProcessing Then
						
						InformationRegisters[Queue].BeforeErrorHandling(
							QueueParameters,
							Data,
							Errors,
							ExceptionText,
							Parameters[2]); // AdditionalProperties
						
					EndIf;
					
					If ValueIsFilled(Errors) Then
						
						DeleteTasks(QueueParameters, Data, Undefined, ExceptionText);
						
						If ValueIsFilled(ExceptionText) Then
							
							ErrorTextForRegistrationLog = ExceptionText;
							
						Else
							
							ErrorsTexts = New Array;
							
							For Each Error In Errors Do
								
								If ErrorsTexts.Find(Error.Value) <> Undefined Then
									Continue;
								EndIf;
								
								ErrorsTexts.Add(Error.Value);
								
							EndDo;
							
							ErrorTextForRegistrationLog = StrConcat(ErrorsTexts, Chars.LF);
							
						EndIf;
						
						WriteErrorToEventLog(Queue, ErrorTextForRegistrationLog);
						
					EndIf;
					
				Else
					
					DeleteTasks(QueueParameters, Data, Errors, ExceptionText);
					
					If Data.Count() > 0 Then
						PutToTempStorage(Data, DataParameters.AddressOfUnprocessedData);
					EndIf;
					
				EndIf;
				
			Except
				
				ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				
				WriteErrorToEventLog(Queue, ExceptionText);
				
			EndTry;
			
		EndIf;
		
		If Not ValueIsFilled(ExceptionText) And Not RecordError And ValueIsFilled(Errors) Then
			
			ExceptionText = ErrorPresentation(Errors);
			
			WriteErrorToEventLog(Queue, ExceptionText);
			
		EndIf;
		
		If ValueIsFilled(ExceptionText) Then
			
			If ErrorText = Undefined Then
				
				// The transfer of the State of the workflow to the states of the desired assignment.Completed in an emergency
				Raise ExceptionText;
				
			Else
				ErrorText = ExceptionText;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns the Query Text of the default task selection.
//
// Parameters:
//  Query              - Query - request for a selection of tasks
//  QueueParameters    - See TaskQueueParameters
//  JobsCount   - Number  - number of tasks in the selection
//  AdditionalSelection - String - additional selection of tasks in the selection text.
//                                 It is not filled in by default.
//
// Returns:
//  String - Task Selection Query Text
//
Function QueryTextOfDefaultTaskSelection(
			Query,
			QueueParameters,
			JobsCount,
			AdditionalSelection = "") Export
	
	DimensionCalculation = QueueParameters.DimensionCalculation;
	
	If ValueIsFilled(DimensionCalculation) Then
		
		QueryText =
		"SELECT TOP 999
		|	DimensionCalculation,
		|	MIN(RecordID) AS JobID,
		|	MIN(RecordDate)          AS TaskDate_
		|INTO Jobs
		|FROM
		|	JobsQueue AS Table
		|WHERE
		|	NOT TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			JobsQueue AS Jobs
		|		WHERE
		|			&ConnectionCondition_
		|			AND Jobs.RecordID IN (&IdsPassedToWorkStreams))
		|	AND &AdditionalSelection
		|
		|GROUP BY
		|	DimensionCalculation
		|
		|ORDER BY
		|	TaskDate_,
		|	DimensionCalculation
		|
		|INDEX BY
		|	DimensionCalculation
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Jobs.JobID AS JobID,
		|	Jobs.TaskDate_          AS TaskDate_,
		|	Table.*
		|FROM
		|	Jobs AS Jobs
		|		LEFT JOIN JobsQueue AS Table
		|		ON &ConnectionCondition_
		|
		|ORDER BY
		|	TaskDate_,
		|	&Ordering
		|";
		
		Fields = New Structure(DimensionCalculation);
		
		Conditions        = New Array;
		Ordering = New Array;
		For Each Field In Fields Do
			
			FieldName = Field.Key;
			
			Conditions.Add(StrTemplate("Jobs.%1 = Table.%1", FieldName));
			Ordering.Add(StrTemplate("Table.%1", FieldName));
			
		EndDo;
		
		Separator = "
					  |		   AND ";
		
		QueryText = StrReplace(QueryText, "DimensionCalculation",   DimensionCalculation);
		QueryText = StrReplace(QueryText, "&ConnectionCondition_", StrConcat(Conditions, Separator));
		QueryText = StrReplace(QueryText, "&Ordering",    StrConcat(Ordering, ", "));
		
	Else
		
		QueryText =
		"SELECT TOP 999
		|	Table.RecordID AS JobID,
		|	Table.RecordDate          AS TaskDate_,
		|	*
		|FROM
		|	JobsQueue AS Table
		|WHERE
		|	NOT Table.RecordID IN (&IdsPassedToWorkStreams)
		|	AND &AdditionalSelection
		|
		|ORDER BY
		|	RecordDate
		|";
		
	EndIf;
	
	If Query.Parameters.Property("JobsQueue") Then
		
		QueryTextSource = 
		"SELECT
		|	*
		|INTO JobsQueue
		|FROM
		|	&JobsQueue AS JobsQueue
		|
		|INDEX BY
		|	IndexedFields
		|";
		
		QueryTextSource = StrReplace(QueryTextSource,
											"IndexedFields",
											?(ValueIsFilled(DimensionCalculation), DimensionCalculation, "RecordDate"));
		
		QueriesTexts = New Array;
		QueriesTexts.Add(QueryTextSource);
		QueriesTexts.Add(QueryText);
		
		QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		
	Else
		
		QueryText = StrReplace(QueryText,
									"JobsQueue",
									StrTemplate("%1.%2", "InformationRegister", QueueParameters.Queue));
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "999", Format(JobsCount, "NZ=0; NG=;"));
	
	QueryText = StrReplace(QueryText,
								"&AdditionalSelection",
								?(ValueIsFilled(AdditionalSelection), AdditionalSelection, "TRUE"));
	
	Return QueryText;
	
EndFunction

// Returns the name of the "Task queue Processing" event.
// 
// Returns:
//  String - Event name
//
Function EventName() Export
	
	Return NStr("vi = 'Xử lý hàng đợi công việc';
				|ru = 'Обработка очереди заданий';
				|en = 'Job queue processing'; fa = 'Job queue processing';
				|it = 'Elaborazione di fila task';
				|pl = 'Przetwarzanie kolejki zadań';
				|tr = 'Görev kuyruğunun işlenmesi'", Common.DefaultLanguageCode());
	
EndFunction

#Region QueueWrapperMethods

// Makes it possible to use the mechanism of requiring the assignment of functionality, calls the procedure to perform tasks.
//
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
//
Procedure UniversalQueueOfRealTimeJobs(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);
	
EndProcedure

// Makes it possible to use the mechanism of requiring the assignment of functionality, calls the procedure to perform tasks.
//
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
//
Procedure JobsForCalculatingProductionOperationQueue(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);
	
EndProcedure

// Makes it possible to use the mechanism of requiring the assignment of functionality, calls the procedure to perform tasks.
//
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
//
Procedure JobsOfStandardProductionDurationCalculation(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);
	
EndProcedure

// Makes it possible to use the mechanism of requiring the assignment of functionality, calls the procedure to perform tasks.
//
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
//
Procedure JobsForProcessingProductionStages(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	SetPrivilegedMode(True);
	AdditionalProperties =
		InformationRegisters.JobsForProcessingProductionStages.AdditionalProperties(RecordError);
	SetPrivilegedMode(False);
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText,
		AdditionalProperties);
	
EndProcedure

// Makes it possible to use the mechanism of requiring the assignment of functionality, calls the procedure to perform tasks.
//
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
//
Procedure JobsForAllocatingInventory(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);
	
EndProcedure

// Makes it possible to use the mechanism of requiring the assignment of functionality, calls the procedure to perform tasks.
//
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
//
Procedure TasksOfCalculatingDurationBeforeReleaseByProductionStages(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);
	
EndProcedure

// Makes it possible to use the mechanism of requiring the assignment of functionality, calls the procedure to perform tasks.
//
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
//
Procedure JobsForTargetProductionScheduleCalculation(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);
	
EndProcedure

Procedure JobsForPostingPlanningDocumentsInBudgeting(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);

EndProcedure

Procedure JobsOfRecordingLimitsByBudgetingData(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);

EndProcedure

// Makes it possible to use the mechanism of requiring the assignment of functionality, calls the procedure to perform tasks.
//
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
//
Procedure JobsToReflectOrderState(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);
	
EndProcedure

// Makes it possible to use the mechanism of requiring the assignment of functionality, calls the procedure to perform tasks.
//
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
//
Procedure JobsToRecordInOtherAssetsLiabilities(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);
	
EndProcedure

// Makes it possible to use the mechanism of requiring the assignment of functionality, calls the procedure to perform tasks.
//
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
//
Procedure JobsForARAPAllocating(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);
	
EndProcedure

// Makes it possible to use the mechanism of requiring the assignment of functionality, calls the procedure to perform tasks.
//
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
//
Procedure JobsToNotifyUsers(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);
	
EndProcedure

// Makes it possible to use the mechanism of requiring the assignment of functionality, calls the procedure to perform tasks.
//
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
//
Procedure JobsForCalculatingItemLinksByChangeOrders(
			QueueParameters,
			DataParameters,
			RecordError = False,
			ProcessInCurrentSession = False,
			ErrorText = Undefined) Export
	
	CompleteJobs(
		QueueParameters,
		DataParameters,
		RecordError,
		ProcessInCurrentSession,
		ErrorText);
	
EndProcedure

#EndRegion

#Region ScheduledJob

Procedure CompletionOfDeferredTasksRoutineTask() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.ExecuteDeferredJobs);
	
	Filter = ?(Common.FileInfobase(),
				New Structure("ExecuteInTransactionInFileDatabase", False),
				Undefined);
	
	QueuesTable = TaskQueues().Copy(Filter, "Queue, RowIndex");
	
	If QueuesTable.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = QueryTextSignificantQueues(QueuesTable);
	
	If Not ValueIsFilled(QueryText) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If Not QueryResult.IsEmpty() Then
		Starter(QueryResult.Unload());
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region StartingQueues

// Starts the starter, or executes the starter method (See Starter)
// .
//
// Parameters:
//  QueuesTable - ValueTable - with columns:
//   * Queue - String - name of the task queue information register.
//   * Jobs - ValueTable - The columns of the value table correspond to the structure of the job queue information register.
//                                 The column is optional.
//
Procedure ExecuteStart(Val QueuesTable)
	
	QueuesTable.Columns.Add("ToProcess", New TypeDescription("Boolean"));
	QueuesTable.Indexes.Add("Queue");
	QueuesTable.Indexes.Add("ToProcess");
	
	SettingsTable = QueuesSettings(QueuesTable.UnloadColumn("Queue"));
	
	Filter = New Structure;
	Filter.Insert("Key");
	Filter.Insert("State", BackgroundJobState.Active);
	
	FilterQueue = New Structure("Queue");
	
	SetPrivilegedMode(True);
	
	For Each TableRow In QueuesTable Do
		
		Queue = TableRow.Queue;
		
		FilterQueue.Queue = Queue;
		
		FoundSettings = SettingsTable.FindRows(FilterQueue);
		If FoundSettings.Count() > 0 And FoundSettings[0].Suspended_ Then
			
			TableRow.ToProcess = False;
			
		Else
			
			Filter.Key = ControlFlowKey(Queue);
			
			TableRow.ToProcess = BackgroundJobs.GetBackgroundJobs(Filter).Count() = 0;
			
		EndIf;
		
	EndDo;
	
	QueuesTable    = QueuesTable.Copy(New Structure("ToProcess", True));
	NumberOfQueues = QueuesTable.Count();
	If NumberOfQueues > 0 Then
		
		If Common.DataSeparationEnabled()
		   And Common.SeparatedDataUsageAvailable() Then
			
			Starter(QueuesTable, True);
			
		Else
			
			If NumberOfQueues = 1 Then
				
				NameOfStarter = StrTemplate("Starter ""%1""", QueuesTable[0].Queue);
				
				FilterByDescription = New Structure;
				FilterByDescription.Insert("Description", NameOfStarter);
				FilterByDescription.Insert("State",    BackgroundJobState.Active);
				
				StartStarter = BackgroundJobs.GetBackgroundJobs(FilterByDescription).Count() = 0;
				
			Else 
				
				NameOfStarter = "Starter";
				
				StartStarter = True;
				
			EndIf;
			
			If StartStarter Then
				
				StarterParameters = New Array;
				StarterParameters.Add(QueuesTable);
				
				BackgroundJobs.Execute("DeferredJobs.Starter", StarterParameters,, NameOfStarter);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Starts the execution of tasks in the Cur transaction.
//
// Parameters:
//  QueuesTable - See InitializeTaskTable.
//
Procedure RunInCurrentTransaction(QueuesTable)
	
	SettingsTable = QueuesSettings(QueuesTable.UnloadColumn("Queue"));
	
	FilterQueue = New Structure("Queue");
	
	For Each TableRow In QueuesTable Do
		
		Queue = TableRow.Queue;
		
		FilterQueue.Queue = Queue;
		
		FoundSettings = SettingsTable.FindRows(FilterQueue);
		If FoundSettings.Count() > 0 And FoundSettings[0].Suspended_ Then
			Continue;
		EndIf;
		
		ThreadOfControl(Queue, TableRow.Jobs, True);
		
	EndDo;
	
EndProcedure

// Starts the execution of pending tasks in the file database.
//
// Parameters:
//  QueuesTable - ValueTable - with columns:
//   * Queue                           - String          - name of the task queue information register,
//   * RowIndex                      - Number           - determines the order of execution of queues.
//   * Jobs                           - ValueTable - The columns of the value table correspond to the structure
//                                                           of the job queue information register.
//   * ExecuteInTransactionInFileDatabase - Boolean          - if FALSE, then in the file database the tasks are executed
//                                                           in the control thread,
//                                                           if TRUE, then in the file database they are executed
//                                                           in the same transaction.
//
Procedure RunInFileDatabase(QueuesTable)
	
	QueuesTable.Indexes.Add("ExecuteInTransactionInFileDatabase");
	
	NumberOfExecuteTransactionsInFileDatabase =
		QueuesTable.FindRows(New Structure("ExecuteInTransactionInFileDatabase", True)).Count();
	
	If NumberOfExecuteTransactionsInFileDatabase = QueuesTable.Count() Then
		
		RunInCurrentTransaction(QueuesTable);
		
	ElsIf NumberOfExecuteTransactionsInFileDatabase = 0 Then
		
		ExecuteStart(QueuesTable);
		
	Else
		
		Table = QueuesTable.CopyColumns();
		
		ExecuteInTransactionInFileDatabase = QueuesTable[0].ExecuteInTransactionInFileDatabase;
		
		For Each TableRow In QueuesTable Do
			
			If ExecuteInTransactionInFileDatabase <> TableRow.ExecuteInTransactionInFileDatabase Then
				
				If ExecuteInTransactionInFileDatabase Then
					
					RunInCurrentTransaction(Table);
					
				Else
					
					ExecuteStart(Table);
					
				EndIf;
				
				Table.Clear();
				
				ExecuteInTransactionInFileDatabase = TableRow.ExecuteInTransactionInFileDatabase;
				
			EndIf;
			
			FillPropertyValues(Table.Add(), TableRow);
			
		EndDo;
		
		If ExecuteInTransactionInFileDatabase Then
			
			RunInCurrentTransaction(Table);
			
		Else
			
			ExecuteStart(Table);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function LaunchFields()
	
	Return ?(Common.FileInfobase() Or Common.DebugMode(),
				"Queue, RowIndex, ExecuteInTransactionInFileDatabase",
				"Queue, RowIndex");
	
EndFunction

Function NameOfControlFlowStartEvent()
	
	Return NStr("vi = 'Khởi động luồng quản lý';
				|ru = 'Запуск управляющего потока';
				|en = 'Start main thread'; fa = 'Start main thread';
				|it = 'Запуск управляющего потока';
				|pl = 'Start main thread';
				|tr = 'Kontrol akışının başlatılması'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#Region TaskSelection

#Region QueriesTexts

Function TaskSelectionQueryText(Query, QueueParameters, JobsCount)
	
	If QueueParameters.DefaultSelectionOfTasks Then
		
		QueryText = QueryTextOfDefaultTaskSelection(Query, QueueParameters, JobsCount);
		
	Else
		
		Queue = QueueParameters.Queue;
		
		QueryText = InformationRegisters[Queue].TaskSelectionQueryText(Query, QueueParameters, JobsCount);
		
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextSignificantQueues(QueuesTable)
	
	SettingsTable = QueuesSettings(QueuesTable.UnloadColumn("Queue"));
	
	QueryTemplate =
	"SELECT TOP 1
	|	&Queue      AS Queue,
	|	&RowIndex AS RowIndex
	|FROM
	|	JobsQueue AS Table";
	
	QueryTexts = New Array;
	
	Filter = New Structure;
	Filter.Insert("Queue");
	
	For Each TableRow In QueuesTable Do
		
		Queue = TableRow.Queue;
		
		Filter.Queue = Queue;
		
		FoundRows = SettingsTable.FindRows(Filter);
		If FoundRows.Count() > 0 And FoundRows[0].Suspended_ Then
			Continue;
		EndIf;
		
		QueryText = StrReplace(QueryTemplate, "&Queue",       StrTemplate("""%1""", Queue));
		QueryText = StrReplace(QueryText,  "&RowIndex",  Format(TableRow.RowIndex, "NZ=0; NG=;"));
		QueryText = StrReplace(QueryText,  "JobsQueue", StrTemplate("%1.%2", "InformationRegister", Queue));
		
		QueryTexts.Add(QueryText);
		
	EndDo;
	
	QueryText = ?(QueryTexts.Count() = 0,
						"",
						StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin()));
	
	Return QueryText;
	
EndFunction

#EndRegion

Function TaskTable(
			Query,
			IdsPassedToWorkStreams,
			Queue,
			ActionPointer,
			Timeouts = Undefined)
	
	Query.SetParameter(
		"IdsPassedToWorkStreams",
		?(IdsPassedToWorkStreams = Undefined, New Array, IdsPassedToWorkStreams));
	
	SetPrivilegedMode(True);
	Table = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	NumberOfTimeouts = ?(Timeouts = Undefined, 0, Timeouts.Count());
	TimeoutIndex      = 0;
	
	While Table.Count() = 0 And TimeoutIndex < NumberOfTimeouts Do
		
		Pause(Timeouts[TimeoutIndex], Queue);
		
		SetPrivilegedMode(True);
		Table = Query.Execute().Unload();
		SetPrivilegedMode(False);
		
		TimeoutIndex = TimeoutIndex + 1;
		
	EndDo;
	
	Table.Columns.Add("Processed", New TypeDescription("Boolean"));
	
	If ValueIsFilled(ActionPointer) Then
		Table.Indexes.Add(StrTemplate("Processed, %1", ActionPointer));
		Table.Indexes.Add(StrTemplate("Processed, JobID, %1", ActionPointer));
	Else
		Table.Indexes.Add("Processed");
		Table.Indexes.Add("Processed, JobID");
	EndIf;
	
	Return Table;
	
EndFunction

Function TableOfActionPointers(TaskTable, ActionPointer)
	
	TableOfActionPointers = TaskTable.Copy(, ActionPointer);
	TableOfActionPointers.GroupBy(ActionPointer);
	TableOfActionPointers.Columns.Add("Processed", New TypeDescription("Boolean"));
	TableOfActionPointers.Indexes.Add("Processed");
	TableOfActionPointers.Indexes.Add(StrTemplate("Processed, %1", ActionPointer));
	
	Return TableOfActionPointers;
	
EndFunction

#EndRegion

#Region CompletingsTasks

// Deletes tasks.
//
// Parameters:
//  QueueParameters - See TaskQueueParameters
//  Data           - ValueTable - data for completing tasks,
//  Errors           - Map of UUID - The key is the identifier of the failed (giving an error
//                                                                during execution) entries of the Job queue information register
//                                                                (measurement
//                                                                of the record identifier of the Job queue information register),
//                                                               the value is the Presentation of the error.
//  ExceptionText  - String - text of the exception error.
//
Procedure DeleteTasks(QueueParameters, Data, Errors, ExceptionText = "")
	
	Queue                     = QueueParameters.Queue;
	CompleteTasksInTransaction = QueueParameters.CompleteTasksInTransaction;
	GetRecordsToDeleteById = Not QueueParameters.DefaultSelectionOfTasks;
	
	RecordSet = InformationRegisters[Queue].CreateRecordSet();
	PortionOfDataToDelete = RecordSet.Unload();
	
	If GetRecordsToDeleteById Then
		PortionOfDataToDelete.GroupBy("RecordID");
	EndIf;
	
	ArrayOfProcessedStrings = New Array;
	ArrayOfDataPortionRows = New Array;
	
	PortionSize = 1000;
	
	If CompleteTasksInTransaction Then 
		
		BeginTransaction();
		
		Try
				
			For Each DataString1 In Data Do
				
				RecordID = DataString1.RecordID;
				
				If Errors <> Undefined And Errors[RecordID] <> Undefined Then
					Continue;
				EndIf;
				
				FillPropertyValues(PortionOfDataToDelete.Add(), DataString1);
				
				ArrayOfDataPortionRows.Add(DataString1);
				
				If PortionOfDataToDelete.Count() = PortionSize Then
					
					DeleteEntriesFromTaskQueueRegister(Queue, PortionOfDataToDelete, RecordSet, GetRecordsToDeleteById);
					PortionOfDataToDelete.Clear();
					
					CommonClientServer.SupplementArray(ArrayOfProcessedStrings, ArrayOfDataPortionRows);
					ArrayOfDataPortionRows.Clear();
					
				EndIf;
				
			EndDo;
			
			If PortionOfDataToDelete.Count() > 0 Then
				
				DeleteEntriesFromTaskQueueRegister(Queue, PortionOfDataToDelete, RecordSet, GetRecordsToDeleteById);
				PortionOfDataToDelete.Clear();
				
				CommonClientServer.SupplementArray(ArrayOfProcessedStrings, ArrayOfDataPortionRows);
				ArrayOfDataPortionRows.Clear();
				
			EndIf;
			
			For Each RowToDelete In ArrayOfProcessedStrings Do
				Data.Delete(RowToDelete);
			EndDo;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteErrorToEventLog(Queue, ExceptionText);
		
		EndTry;
		
	Else
		
		ErrorOccurredWhileDeleting = False;
		
		For Each DataString1 In Data Do
			
			RecordID = DataString1.RecordID;
			
			If Errors <> Undefined And Errors[RecordID] <> Undefined Then
				Continue;
			EndIf;
			
			FillPropertyValues(PortionOfDataToDelete.Add(), DataString1);
			
			ArrayOfDataPortionRows.Add(DataString1);
			
			If PortionOfDataToDelete.Count() = PortionSize Then
				
				Try
					
					DeleteEntriesFromTaskQueueRegister(Queue, PortionOfDataToDelete, RecordSet, GetRecordsToDeleteById);
					PortionOfDataToDelete.Clear();
					
					CommonClientServer.SupplementArray(ArrayOfProcessedStrings, ArrayOfDataPortionRows);
					ArrayOfDataPortionRows.Clear();
					
				Except 
					
					ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
					
					WriteErrorToEventLog(Queue, ExceptionText);
					
					ErrorOccurredWhileDeleting = True;
					
					Break;
					
				EndTry;
				
			EndIf;
			
		EndDo;
		
		If Not ErrorOccurredWhileDeleting And PortionOfDataToDelete.Count() > 0 Then
			
			Try
				
				DeleteEntriesFromTaskQueueRegister(Queue, PortionOfDataToDelete, RecordSet, GetRecordsToDeleteById);
				PortionOfDataToDelete.Clear();
				
				CommonClientServer.SupplementArray(ArrayOfProcessedStrings, ArrayOfDataPortionRows);
				ArrayOfDataPortionRows.Clear();
				
			Except 
				
				ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				WriteErrorToEventLog(Queue, ExceptionText);
				
			EndTry;
			
		EndIf;
		
		For Each RowToDelete In ArrayOfProcessedStrings Do
			
			Data.Delete(RowToDelete);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure DeleteEntriesFromTaskQueueRegister(Queue, DataToDelete_1, Val RecordSet = Undefined, GettingDataToBeDeletedById = False)
	
	If RecordSet = Undefined Then
		RecordSet = InformationRegisters[Queue].CreateRecordSet();
	EndIf;
	
	If GettingDataToBeDeletedById Then
		
		Query = New Query;
		Query.SetParameter("RecordIds", DataToDelete_1.UnloadColumn("RecordID"));
		Query.Text = "
		|SELECT *
		|FROM
		|	&TableQueue AS Queue
		|WHERE
		|	Queue.RecordID IN (&RecordIds)";
		Query.Text = StrReplace(Query.Text,"&TableQueue" , "InformationRegister." + Queue);
		
		SetPrivilegedMode(True);
		TaskEntriesToDelete = Query.Execute().Unload();
		SetPrivilegedMode(False);
			
	Else
		
		TaskEntriesToDelete = DataToDelete_1.Copy();
		
	EndIf;
	
	SetPrivilegedMode(True);
	RecordSet.DataExchange.Load = True;
	RecordSet.Load(TaskEntriesToDelete);
	RecordSet.Write(ReplacementMode.Delete);
	SetPrivilegedMode(False);
	
EndProcedure

Function ErrorPresentation(Errors)
	
	ErrorText = "";
	
	If ValueIsFilled(Errors) Then
		
		ErrorsTexts = New Array;
		
		For Each Id In Errors Do
			
			Text = Id.Value;
			If ErrorsTexts.Find(Text) = Undefined Then
				ErrorsTexts.Add(Text);
			EndIf;
			
		EndDo;
		
		ErrorText = StrConcat(ErrorsTexts, Chars.LF);
		
	EndIf;
	
	Return ErrorText;
	
EndFunction

Procedure CompleteTasksInBackgroundOfControlFlow(MethodName, QueueParameters, Batch)
	
	RepeatCount        = RepeatCount();
	CurrentNumberOfRepetitions = 0;
	
	DataParameters = DataParameters(Batch, PutToTempStorage(Undefined));
	
	While True Do
		
		CurrentNumberOfRepetitions = CurrentNumberOfRepetitions + 1;
		RecordError       = CurrentNumberOfRepetitions = RepeatCount;
		
		MethodParameters = WorkflowParameters(QueueParameters, DataParameters, RecordError, False, "");
		
		Common.ExecuteConfigurationMethod(MethodName, MethodParameters);
		
		ErrorText = MethodParameters[4];
		
		If RecordError Or Not ValueIsFilled(ErrorText) Then
			DeleteFromTempStorage(DataParameters.AddressOfUnprocessedData);
			Break;
		Else
			
			CurrentData = GetFromTempStorage(DataParameters.AddressOfUnprocessedData);
			
			If ValueIsFilled(CurrentData) Then
				DataParameters.Data = CurrentData;
			Else
				DeleteFromTempStorage(DataParameters.AddressOfUnprocessedData);
				Break;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WriteErrorToEventLog(Queue, ErrorText)
	
	WriteLogEvent(
		EventName(),
		EventLogLevel.Error,
		Metadata.InformationRegisters[Queue],,
		ErrorText);
	
EndProcedure

#EndRegion

#Region WorkFlow

// Initializes the work flow table.
//
// Returns:
//  ValueTable - workflow table:
//   * Data                    - See DataParameters.Data
//   * AddressOfUnprocessedData - See DataParameters.AddressOfUnprocessedData
//   * MethodName                 - String - the name of the task execution method (Methodname column See TaskQueues
//                                          )
//   * BackgroundJob            - BackgroundJob - workflow
//   * UUID   - UUID - unique workflow identifier
//   * RepeatCount        - Number - number of repetitions
//
Function WorkFlows()
	
	Table = New ValueTable;
	Table.Columns.Add("Data",                    New TypeDescription("ValueTable"));
	Table.Columns.Add("AddressOfUnprocessedData", Common.StringTypeDetails(0));
	Table.Columns.Add("MethodName",                 Common.StringTypeDetails(1000));
	Table.Columns.Add("BackgroundJob",            New TypeDescription("BackgroundJob"));
	Table.Columns.Add("UUID",   New TypeDescription("UUID"));
	Table.Columns.Add("RepeatCount",        Common.TypeDescriptionNumber(1));
	Table.Indexes.Add("MethodName");
	Table.Indexes.Add("UUID");
	
	Return Table;
	
EndFunction

// Creates a workflow and adds it to the workflow table.
//
// Parameters:
//  Table           - See WorkFlows
//  QueueParameters  - See TaskQueueParameters
//  Data            - ValueTable - task data table,
//
Procedure AddWorkflow(Table, QueueParameters, Data)
	
	TableRow = Table.Add();
	TableRow.Data                    = Data;
	TableRow.AddressOfUnprocessedData = PutToTempStorage(Undefined);
	TableRow.MethodName                 = QueueParameters.MethodName;
	TableRow.BackgroundJob            = WorkFlow(QueueParameters, TableRow, False);
	TableRow.UUID   = TableRow.BackgroundJob.UUID;
	TableRow.RepeatCount        = 1;
	
EndProcedure

Function WorkFlow(QueueParameters, Data, RecordError)
	
	NameOfWorkflowMethod    = NameOfWorkflowMethod(QueueParameters.Queue);
	NameOfWorkflow = NameOfWorkflow(QueueParameters);
	
	DataParameters = DataParameters(Undefined);
	FillPropertyValues(DataParameters, Data);
	
	MethodParameters = WorkflowParameters(QueueParameters, DataParameters, RecordError);
	
	Return BackgroundJobs.Execute(NameOfWorkflowMethod, MethodParameters,, NameOfWorkflow);
	
EndFunction

Function NameOfWorkflowMethod(Queue)
	
	Return StrTemplate("%1.%2", "DeferredJobs", Queue);
	
EndFunction

Function NameOfWorkflow(QueueParameters)
	
	Return StrTemplate("%1 ""%2 [%3]""",
						NStr("vi = 'Luồng làm việc';
							|ru = 'Рабочий поток';
							|en = 'Worker thread'; fa = 'Worker thread';
							|it = 'Рабочий поток';
							|pl = 'Worker thread';
							|tr = 'İş akışı'"),
						QueueParameters.Queue,
						QueueParameters.MethodName);
	
EndFunction

// Returns the parameters of the workflow as an array.
// 
// Parameters:
//  QueueParameters         - See CompleteJobs.QueueParameters
//  DataParameters          - See CompleteJobs.DataParameters
//  RecordError      - See CompleteJobs.RecordError
//  ProcessInCurrentSession - See CompleteJobs.ProcessInCurrentSession
//  ErrorText              - See CompleteJobs.ErrorText
// 
// Returns:
//  Array - Workflow Parameters
//
Function WorkflowParameters(
			QueueParameters,
			DataParameters,
			RecordError,
			ProcessInCurrentSession = False,
			ErrorText = Undefined)
	
	MethodParameters = New Array;
	MethodParameters.Add(QueueParameters);
	MethodParameters.Add(DataParameters);
	MethodParameters.Add(RecordError);
	MethodParameters.Add(ProcessInCurrentSession);
	MethodParameters.Add(ErrorText);
	
	Return MethodParameters;
	
EndFunction

Function NumberOfActiveWorkThreads(QueueParameters, AllThreads = False)
	
	Filter = New Structure;
	Filter.Insert("MethodName", NameOfWorkflowMethod(QueueParameters.Queue));
	Filter.Insert("State", BackgroundJobState.Active);
	
	If Not AllThreads Then
		Filter.Insert("Description", NameOfWorkflow(QueueParameters));
	EndIf;
	
	SetPrivilegedMode(True);
	
	Return BackgroundJobs.GetBackgroundJobs(Filter).Count();
	
EndFunction

Function MonitorWorkFlows(WorkFlows, QueueParameters, AllThreads = False)
	
	If WorkFlows = Undefined Then
		Return 0;
	EndIf;
	
	FilterWorkFlow = New Structure;
	FilterWorkFlow.Insert("UUID");
	
	GetAllStreams             = AllThreads;
	MaximumThreadsNumber = QueueParameters.MaximumThreadsNumber;
	
	ThereIsFreeWorkFlow     = False;
	
	RepeatCount            = RepeatCount();
	
	If AllThreads Then
		ProcessedWorkFlows = WorkFlows;
	Else
		FilterMethodName = New Structure("MethodName", QueueParameters.MethodName);
		ProcessedWorkFlows = WorkFlows.FindRows(FilterMethodName);
	EndIf;
	
	SetPrivilegedMode(True);
	
	While ProcessedWorkFlows.Count() > 0 Do
		
		FoundWorkStreams = BackgroundJobs.WaitForExecutionCompletion(
									GetWorkFlows(WorkFlows, QueueParameters, GetAllStreams), 1);
		
		For Each CurrentWorkFlow In FoundWorkStreams Do
			
			WorkflowState = CurrentWorkFlow.State;
			
			If WorkflowState = BackgroundJobState.Completed
			 Or WorkflowState = BackgroundJobState.Canceled Then
				
				FilterWorkFlow.UUID = CurrentWorkFlow.UUID;
				
				LineRP = WorkFlows.FindRows(FilterWorkFlow)[0];
				
				DeleteFromTempStorage(LineRP.AddressOfUnprocessedData);
				
				WorkFlows.Delete(LineRP);
				
				If Not AllThreads And Not ThereIsFreeWorkFlow Then
					ThereIsFreeWorkFlow = True;
				EndIf;
				
			ElsIf WorkflowState = BackgroundJobState.Failed Then
				
				FilterWorkFlow.UUID = CurrentWorkFlow.UUID;
				
				LineRP = WorkFlows.FindRows(FilterWorkFlow)[0];
				If LineRP.RepeatCount = RepeatCount Then
					
					DeleteFromTempStorage(LineRP.AddressOfUnprocessedData);
					
					WorkFlows.Delete(LineRP);
					
					If Not AllThreads And Not ThereIsFreeWorkFlow Then
						ThereIsFreeWorkFlow = True;
					EndIf;
					
				Else
					
					CurrentData = GetFromTempStorage(LineRP.AddressOfUnprocessedData);
					
					If ValueIsFilled(CurrentData) Then
						
						If AllThreads Then
							QueueParameters.MethodName = LineRP.MethodName;
						EndIf;
						
						CurrentNumberOfRepetitions = LineRP.RepeatCount + 1;
						RecordError       = CurrentNumberOfRepetitions = RepeatCount;
						
						LineRP.Data                  = CurrentData;
						LineRP.BackgroundJob          = WorkFlow(QueueParameters, LineRP, RecordError);
						LineRP.UUID = LineRP.BackgroundJob.UUID;
						LineRP.RepeatCount      = CurrentNumberOfRepetitions;
						
					Else
						
						DeleteFromTempStorage(LineRP.AddressOfUnprocessedData);
						
						WorkFlows.Delete(LineRP);
						
						If Not AllThreads And Not ThereIsFreeWorkFlow Then
							ThereIsFreeWorkFlow = True;
						EndIf;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
			
		If ThereIsFreeWorkFlow Then
			
			If MaximumThreadsNumber = 0
			 Or MaximumThreadsNumber > NumberOfActiveWorkThreads(QueueParameters, True) Then
				Break;
			Else
				ProcessedWorkFlows = WorkFlows;
				GetAllStreams           = True;
			EndIf;
			
		EndIf;
			
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return ?(AllThreads, 0, NumberOfActiveWorkThreads(QueueParameters));
	
EndFunction

Function GetWorkFlows(WorkFlows, QueueParameters, AllThreads)
	
	If AllThreads Then
		
		ArrayOfWorkStreams = WorkFlows.UnloadColumn("BackgroundJob");
		
	Else
		
		FoundRows = WorkFlows.FindRows(New Structure("MethodName", QueueParameters.MethodName));
		
		If FoundRows.Count() = WorkFlows.Count() Then
			ArrayOfWorkStreams = WorkFlows.UnloadColumn("BackgroundJob");
		Else
			ArrayOfWorkStreams = Common.UnloadColumn(FoundRows, "BackgroundJob")
		EndIf;
		
	EndIf;
	
	Return ArrayOfWorkStreams;
	
EndFunction

// Returns the number of repetitions of starting the workflow when an error occurs.
//
// Returns:
//  Number - number of repetitions
//
Function RepeatCount()
	
	Return 3;
	
EndFunction

// Returns data parameters.
//
// Parameters:
//  Data                    - ValueTable, Undefined - data for completing tasks,
//  AddressOfUnprocessedData - String, Undefined          - The address in the temporary storage is used to transfer
//                                                              unprocessed data from the worker thread to the control
//                                                              thread. UNDEFINED by default.
//
// Returns:
//  Structure - with keys:
//   * Data                    - See DataParameters.Data
//   * AddressOfUnprocessedData - See DataParameters.AddressOfUnprocessedData
//
Function DataParameters(Data, AddressOfUnprocessedData = Undefined)
	
	Parameters = New Structure;
	Parameters.Insert("Data",                    Data);
	Parameters.Insert("AddressOfUnprocessedData", AddressOfUnprocessedData);
	
	Return Parameters;
	
EndFunction

// Returns the IDs of job records that are executed in work streams. If no work streams are specified,
// then the IDs of processed records are obtained from the job table.
// 
// Parameters:
//  WorkFlows  - See WorkFlows
//  TaskTable - ValueTable - task table with required columns:
//   * Processed          - Boolean - 
//   * RecordID - UUID -
//  IdsPassedForExecution - Array of UUID - array of IDs of task records
//                                                                             that are submitted for execution.
//
Procedure IdsPassedForExecution(WorkFlows, TaskTable, IdsPassedForExecution)
	
	If WorkFlows <> Undefined Then
		
		If WorkFlows.Count() = 0 Then
			
			IdsPassedForExecution = Undefined;
			
		Else
			
			IdsPassedForExecution = New Array;
			
			For Each LineRP In WorkFlows Do
				
				If LineRP.BackgroundJob.State = BackgroundJobState.Completed Then
					Continue;
				EndIf;
				
				For Each TDRow In LineRP.Data Do
					IdsPassedForExecution.Add(TDRow.RecordID);
				EndDo;
				
			EndDo;
			
		EndIf;
		
	ElsIf ValueIsFilled(TaskTable) Then
		
		FilterProcessed = New Structure("Processed", True);
		IDsTable = TaskTable.Copy(FilterProcessed, "RecordID");
		
		If ValueIsFilled(IdsPassedForExecution) Then
			
			CommonClientServer.SupplementArray(
				IdsPassedForExecution,
				IDsTable.UnloadColumn("RecordID"));
			
		Else
			
			IdsPassedForExecution = IDsTable.UnloadColumn("RecordID");
			
		EndIf;
		
	Else
		
		IdsPassedForExecution = Undefined;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

#Region WorkingWithQueues

// Returns task queue parameters.
// 
// Returns:
//  Structure - with keys:
//   * Queue                           - String - name of the task queue information register.
//   * MethodName                         - String - the name of the task execution method, the principle of formation is similar
//                                                  to the argument method name of the general purpose method.Perform
//                                                  (See Common.ExecuteConfigurationMethod.MethodName)the Configuration method.
//   * ActionPointer                 - String - the name of the task queue register field that defines the name
//                                                  of the task execution method. The tasks will be completed in the context of this field.
//                                                  The action pointer must be included in the calculation analytics list
//                                                  (Calculation Analytics parameter).
//                                                  It makes sense if the methodname is not filled in.
//   * MethodNamesByPointerValues  - Map of KeyAndValue - the matching of values is configured 
//                                                  An action pointer with the names of the task execution methods. 
//                                                  It makes sense if the methodname is not filled in.
//   * Multithreaded                     - Boolean - indicates whether tasks in the queue are being executed with multiple threads.
//   * ThreadsCount                 - Number  - the number of threads (background jobs) to perform pending
//                                                  queue jobs, by default 4
//                                                  (See DeferredJobsOverridable.DefaultNumberOfThreads).
//   * MaximumThreadsNumber     - Number  - the maximum number of threads (background jobs) that can
//                                                  be started to complete tasks in this queue. Makes sense for
//                                                  queues with nested queues
//                                                  (as an example of a universal sequence of operational tasks).
//                                                  If 0, then the maximum number of threads is not controlled.
//                                                  By default, 0.
//   * PortionOfCalculation                     - Number  - The number of tasks to be transferred to the workflow
//                                                  is 100 by default
//                                                  (See DeferredJobsOverridable.DefaultCalculationPortion).
//   * TaskAllocationMode         - String - task allocation mode by threads:
//                                                   1. "EVENLY_BY_THREADS" - tasks are evenly distributed
//                                                                                across free streams,
//                                                   2. "MAXIMUM TASK_IN_FLOW" - the maximum
//                                                                                   possible number of tasks are transferred to the stream.
//                                                  By default, "EVENLY_BY_THREADS".
//   * DimensionCalculation                  - String - A comma-separated list of job queue information register fields
//                                                  that define a job. If it is not filled in,
//                                                  then one register entry is considered one job.
//   * ProcessingInterval                 - Number  - processing interval (in seconds) between the start of the Cur sample
//                                                  and the end of the last portion of the calculation:
//                                                    1. If the processing interval is greater than 0, then the selection and execution
//                                                       of tasks occurs when one of the following
//                                                       conditions occurs:
//                                                         1. The number of tasks in the sample is not less than a portion of the calculation,
//                                                         2. The interval between the Cur date and the end date of
//                                                            the last batch of tasks is not less than the processing interval,
//                                                    2. If the processing interval is 0, then the processing interval does
//                                                       not affect the selection and execution of tasks.
//   * Priority                         - Number  - has only an informative meaning, is displayed in the interface,
//                                                  possible values:
//                                                    1. -1 - high (blocks operational work -
//                                                            inventory distribution, documents cannot be printed ...),
//                                                    2. 0 - medium,
//                                                    3. 1 is low.
//   * CompleteTasksInTransaction       - Boolean - tasks of one portion are performed in a transaction, by default FALSE.
//   * ExecuteInTransactionInFileDatabase - Boolean - if FALSE, then in the file database the tasks are executed in the control
//                                                  thread,
//                                                  if TRUE, then in the file database they are executed in the same transaction.
//                                                  The default is TRUE.
//   * DefaultSelectionOfTasks         - Boolean - if TRUE, then the Query Text is used to select tasks
//                                                  generated in the function See QueryTextOfDefaultTaskSelection
//                                                  , 
//                                                  if FALSE, then the task selection Query Text
//                                                  
//                                                  (See InformationRegisters.JobsForProcessingProductionStages.TaskSelectionQueryText)is generated in the Task Selection Query text function of the Task Queue Information Register manager module
//                                                  .
//                                                  The default is TRUE.
//   * AdditionalErrorProcessing     - Boolean - if TRUE, then in the task execution method
//                                                  (See CompleteJobs), before processing errors
//                                                  , the error processing procedure of the task queue Information register manager module is started
//                                                  
//                                                  (See InformationRegisters.JobsForProcessingProductionStages.BeforeErrorHandling).
//                                                  The default is FALSE.
//
Function TaskQueueParameters()
	
	ThreadsCount = DeferredJobsOverridable.DefaultNumberOfThreads();
	PortionOfCalculation     = DeferredJobsOverridable.DefaultCalculationPortion();
	
	Parameters = New Structure;
	Parameters.Insert("Queue",                           "");
	Parameters.Insert("MethodName",                         "");
	Parameters.Insert("ActionPointer",                 "");
	Parameters.Insert("MethodNamesByPointerValues",  New Map);
	Parameters.Insert("Multithreaded",                     True);
	Parameters.Insert("ThreadsCount",                 ThreadsCount);
	Parameters.Insert("MaximumThreadsNumber",     0);
	Parameters.Insert("PortionOfCalculation",                     PortionOfCalculation);
	Parameters.Insert("TaskAllocationMode",         "EVENLY_BY_THREADS");
	Parameters.Insert("DimensionCalculation",                  "");
	Parameters.Insert("ProcessingInterval",                 0);
	Parameters.Insert("Priority",                         0);
	Parameters.Insert("CompleteTasksInTransaction",       False);
	Parameters.Insert("ExecuteInTransactionInFileDatabase", True);
	Parameters.Insert("DefaultSelectionOfTasks",         True);
	Parameters.Insert("AdditionalErrorProcessing",     False);
	
	Return Parameters;
	
EndFunction

// Adds a task queue.
// 
// Parameters:
//  TaskQueues   - See TaskQueues
//  QueueParameters - See TaskQueueParameters
//
Procedure AddQueue(TaskQueues, QueueParameters)
	
	TableRow = TaskQueues.Add();
	FillPropertyValues(TableRow, QueueParameters);
	
	TableRow.RowIndex = TaskQueues.Count() - 1;
	
EndProcedure

// Returns queue settings
// 
// Parameters:
//  ArrayOfQueues - Array of String, Undefined - array of names of registers of information of queues of tasks.
// 
// Returns:
//  ValueTable - with columns:
//   * Queue                - String - name of the task queue information register,
//   * Suspended_         - Boolean - if TRUE, then the tasks are recorded but not executed,
//   * LastProcessingDate - Date   - it is used only for those queues where 
//                                       the "Processing Interval" parameter (See TaskQueues)
//                                       is full.
//
Function QueuesSettings(ArrayOfQueues = Undefined)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Settings.Queue                AS Queue,
	|	Settings.Suspended_         AS Suspended_,
	|	Settings.LastProcessingDate AS LastProcessingDate
	|FROM
	|	InformationRegister.JobQueueSettings AS Settings
	|WHERE
	|	Settings.Queue IN (&ArrayOfQueues)";
	
	If ValueIsFilled(ArrayOfQueues) Then
		Query.SetParameter("ArrayOfQueues", ArrayOfQueues);
	Else
		Query.Text = StrReplace(Query.Text, "Settings.Queue IN (&ArrayOfQueues)", "TRUE");
	EndIf;
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If QueryResult.IsEmpty() Then
		
		SettingsTable = New ValueTable;
		SettingsTable.Columns.Add("Queue",                Common.StringTypeDetails(150));
		SettingsTable.Columns.Add("Suspended_",         New TypeDescription("Boolean"));
		SettingsTable.Columns.Add("LastProcessingDate", Common.DateTypeDetails(DateFractions.DateTime));
		
	Else
		
		SettingsTable = QueryResult.Unload();
		
	EndIf;
	
	SettingsTable.Indexes.Add("Queue");
	
	Return SettingsTable;
	
EndFunction

#EndRegion

#Region ThreadOfControl

// Returns the key of the control flow.
// 
// Parameters:
//  Queue - String - name of the task queue information register.
// 
// Returns:
//  String - the key of the control stream in the format "Control stream_<name of the job queue information register>"
//
Function ControlFlowKey(Queue)
	
	Return StrTemplate("ThreadOfControl_%1", Queue);
	
EndFunction

Function ParametersOfControlFlowStarter()
	
	Parameters = New Structure;
	Parameters.Insert("Key",         "ControlFlowStarter");
	Parameters.Insert("MethodName",    "DeferredJobs.ControlFlowStarter");
	Parameters.Insert("Description", NStr("vi = 'Bộ khởi động quản lý luồng';
											|ru = 'Стартер управляющего потока';
											|en = 'Starter of thread of control'; fa = 'Starter of thread of control';
											|it = 'Стартер управляющего потока';
											|pl = 'Starter of thread of control';
											|tr = 'Kontrol akışı başlatıcısı'"));
	
	Return Parameters;
	
EndFunction

Procedure StartStarterOfControlFlow()
	
	ERPStarterParameters = ParametersOfControlFlowStarter();
	
	ExecutionParameters = TimeConsumingOperations.ProcedureExecutionParameters();
	ExecutionParameters.BackgroundJobDescription = ERPStarterParameters.Description;
	ExecutionParameters.BackgroundJobKey         = ERPStarterParameters.Key;
	ExecutionParameters.RunInBackground              = True;
	ExecutionParameters.WaitCompletion           = 0;
	
	Try
		TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, ERPStarterParameters.MethodName);
	Except
		// The background task "Starter of the control stream" with the key "Starter of the control stream" is already running.
	EndTry;
	
EndProcedure

#EndRegion

#Region Pauses

Procedure Pause(Duration, Queue = Undefined, Filter = Undefined)
	
	If Filter = Undefined Then
		
		Filter = New Structure;
		Filter.Insert("Key",      ControlFlowKey(Queue));
		Filter.Insert("State", BackgroundJobState.Active);
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	FoundBackgroundTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	If FoundBackgroundTasks.Count() > 0 Then
		
		BackgroundJobs.WaitForExecutionCompletion(FoundBackgroundTasks, Duration);
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure PauseProcessingInterval(QueueSettings, ProcessingInterval)
	
	Queue                = QueueSettings.Queue;
	LastProcessingDate = QueueSettings.LastProcessingDate;
	
	CurrentDate            = CurrentUniversalDate();
	
	If ValueIsFilled(LastProcessingDate) Then
		
		PauseDuration = ProcessingInterval - (CurrentDate - LastProcessingDate);
		
		If PauseDuration > 0 And PauseDuration <= ProcessingInterval Then
			
			Pause(PauseDuration, Queue);
			
			CurrentDate = CurrentUniversalDate();
			
		EndIf;
		
	EndIf;
	
	QueueSettings.LastProcessingDate = CurrentDate;
	
	RecordSet = InformationRegisters.JobQueueSettings.CreateRecordSet();
	RecordSet.Filter.Queue.Set(Queue);
	FillPropertyValues(RecordSet.Add(), QueueSettings);
	
	SetPrivilegedMode(True);
	RecordSet.Write();
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

Function Timeouts()
	
	Timeouts = New Array;
	Timeouts.Add(0.2);
	Timeouts.Add(0.5);
	Timeouts.Add(0.5);
	Timeouts.Add(1);
	Timeouts.Add(1);
	Timeouts.Add(2);
	
	Return Timeouts;
	
EndFunction

Function CalculatePortionsByStreams(
			TaskTable,
			Filter,
			FreeThreadsCount,
			PortionOfCalculation,
			TaskAllocationMode)
	
	PortionsByStreams = New Array;
	
	If FreeThreadsCount > 0 Then
		
		CurrentNumberOfThreads = FreeThreadsCount;
		
		If TaskAllocationMode = "EVENLY_BY_THREADS" Then
			
			ArrayOfJobIds = Common.UnloadColumn(
											TaskTable.FindRows(Filter),
											"JobID",
											True);
			
			NumberOfJobIDs = ArrayOfJobIds.Count();
			
			PortionOfCalculationInStream = Int(NumberOfJobIDs / CurrentNumberOfThreads);
			If PortionOfCalculationInStream < PortionOfCalculation Then
				QuantityNotAllocated = NumberOfJobIDs - PortionOfCalculationInStream * CurrentNumberOfThreads;
			Else
				PortionOfCalculationInStream      = PortionOfCalculation;
				QuantityNotAllocated = 0;
			EndIf;
			
			While CurrentNumberOfThreads > 0 And (PortionOfCalculationInStream > 0 Or QuantityNotAllocated > 0) Do
				
				CurrentPortionOfCalculationInStream = PortionOfCalculationInStream;
				
				If QuantityNotAllocated > 0 Then
					CurrentPortionOfCalculationInStream = CurrentPortionOfCalculationInStream + 1;
					QuantityNotAllocated   = QuantityNotAllocated - 1;
				EndIf;
				
				PortionsByStreams.Add(CurrentPortionOfCalculationInStream);
				CurrentNumberOfThreads = CurrentNumberOfThreads - 1;
				
			EndDo;
			
		ElsIf TaskAllocationMode = "Max_OfTasks_In_Stream" Then
			
			While CurrentNumberOfThreads > 0 Do
				PortionsByStreams.Add(PortionOfCalculation);
				CurrentNumberOfThreads = CurrentNumberOfThreads - 1;
			EndDo;
			
		Else
			
			ArrayOfJobIds = Common.UnloadColumn(
											TaskTable.FindRows(Filter),
											"JobID",
											True);
			
			NumberOfJobIDs = ArrayOfJobIds.Count();
			
			CurrentNumberOfThreads = Int(NumberOfJobIDs / PortionOfCalculation);
			If CurrentNumberOfThreads * PortionOfCalculation < NumberOfJobIDs Then
				CurrentNumberOfThreads = CurrentNumberOfThreads + 1;
			EndIf;
			
			While CurrentNumberOfThreads > 0 Do
				PortionsByStreams.Add(PortionOfCalculation);
				CurrentNumberOfThreads = CurrentNumberOfThreads - 1;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return PortionsByStreams; 
	
EndFunction

Procedure FillInTaskSourceLine(SourceRow, Data, GenerateRecordId)
	
	FillPropertyValues(SourceRow, Data);
	
	If Not ValueIsFilled(SourceRow.RecordDate) Then
		SourceRow.RecordDate = CurrentUniversalDate();
	EndIf;
	
	If Not ValueIsFilled(SourceRow.RecordID) Or GenerateRecordId Then
		SourceRow.RecordID = New UUID;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion