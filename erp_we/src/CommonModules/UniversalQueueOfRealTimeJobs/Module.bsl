////////////////////////////////////////////////////////////////////////////////////
// The Universal Queue of Operational Tasks module contains procedures and functions for
// working with the universal queue of operational tasks.
//
////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Processes the tasks of the universal register of operational tasks.
//
// Parameters:
//  Data - Structure             - the keys match the names of dimensions, resources, and register Attributes
//                                   Universal turn of operational tasks.
//         - ValueTable       - column names match the names of dimensions, resources, and register Attributes
//                                   Universal turn of operational tasks.
//         - Array of AnyRef - array of nested queue objects - the value of the nested queue task is passed
//                                   to the Task parameter.
//  Job - Undefined                                   - if the Data parameter is a structure or a table
//                                                             of values.
//          - EnumRef.UniversalQueueTasks - if the Data parameter is an array (required for
//                                                             filling).
//  AdditionalData - Undefined, ValueStorage - used if the Data parameter is an array.
//  GenerateRecordId - Boolean - if TRUE, then the record ID will be generated
//                                              automatically. The default is TRUE.
//
Procedure ProcessTasks_(
			Data,
			Job = Undefined,
			AdditionalData = Undefined,
			GenerateRecordId = True) Export
	
	DataType = TypeOf(Data);
	
	If DataType = Type("Structure") Or DataType = Type("ValueTable") Then
		
		CurrentData = Data;
		
	ElsIf DataType = Type("Array") Then
		
		CurrentData = InformationRegisters.UniversalQueueOfRealTimeJobs.CreateRecordSet().UnloadColumns();
		
		For Each Object In Data Do
			
			TableRow = CurrentData.Add();
			TableRow.Object               = Object;
			TableRow.Job              = Job;
			TableRow.AdditionalData = AdditionalData;
			
		EndDo;
		
	Else
		
		Raise StrTemplate(
							NStr("vi = 'Неизвестный тип данных ""%1"" универсальной очереди оперативных заданий.';
								|ru = 'Неизвестный тип данных ""%1"" универсальной очереди оперативных заданий.';
								|en = 'Unknown ""%1"" data type of the universal queue of real-time jobs.'; fa = 'Unknown ""%1"" data type of the universal queue of real-time jobs.';
								|it = 'Неизвестный тип данных ""%1"" универсальной очереди оперативных заданий.';
								|pl = 'Unknown ""%1"" data type of the universal queue of real-time jobs.';
								|tr = 'Неизвестный тип данных ""%1"" универсальной очереди оперативных заданий.'"),
							DataType);
		
	EndIf;
	
	DeferredJobs.ProcessQueueTasks(
		"UniversalQueueOfRealTimeJobs",
		CurrentData,
		GenerateRecordId);
	
EndProcedure

// Processes the task of the universal register of operational tasks.
//
// Parameters:
//  Object               - AnyRef -
//  Job              - EnumRef.UniversalQueueTasks -
//  AdditionalData - ValueStorage, Undefined -
//
Procedure ProcessTask_(Object, Job, AdditionalData = Undefined) Export
	
	DeferredJobs.ProcessQueueTasks(
		"UniversalQueueOfRealTimeJobs",
		New Structure("Object, Job, AdditionalData", Object, Job, AdditionalData),
		True);
	
EndProcedure

// Adds tasks to the Universal Queue of Operational Tasks register.
//
// Parameters:
//  Data - Structure             - the keys match the names of dimensions, resources, and register Attributes
//                                   Universal turn of operational tasks.
//         - ValueTable       - column names match the names of dimensions, resources, and register Attributes
//                                   Universal turn of operational tasks.
//         - Array of AnyRef - array of nested queue objects - the value of the nested queue task is passed
//                                   to the Task parameter.
//  Job - Undefined                                   - if the Data parameter is a structure or a table
//                                                             of values.
//          - EnumRef.UniversalQueueTasks - if the Data parameter is an array (required for
//                                                             filling).
//  AdditionalData - Undefined, ValueStorage - used if the Data parameter is an array.
//  GenerateRecordId - See DeferredJobs.AddTasksToQueue.GenerateRecordId
//  TaskTable                   - See DeferredJobs.AddTasksToQueue.TaskTable
//
Procedure AddTasks(
			Data,
			Job = Undefined,
			AdditionalData = Undefined,
			GenerateRecordId = False,
			TaskTable = Undefined) Export
	
	DataType = TypeOf(Data);
	
	If DataType = Type("Structure") Or DataType = Type("ValueTable") Then
		
		CurrentData = Data;
		
	ElsIf DataType = Type("Array") Then
		
		CurrentData = InformationRegisters.UniversalQueueOfRealTimeJobs.CreateRecordSet().UnloadColumns();
		
		For Each Object In Data Do
			
			TableRow = CurrentData.Add();
			TableRow.Object               = Object;
			TableRow.Job              = Job;
			TableRow.AdditionalData = AdditionalData;
			
		EndDo;
		
	Else
		
		Raise StrTemplate(
							NStr("vi = 'Неизвестный тип данных ""%1"" универсальной очереди оперативных заданий.';
								|ru = 'Неизвестный тип данных ""%1"" универсальной очереди оперативных заданий.';
								|en = 'Unknown ""%1"" data type of the universal queue of real-time jobs.'; fa = 'Unknown ""%1"" data type of the universal queue of real-time jobs.';
								|it = 'Неизвестный тип данных ""%1"" универсальной очереди оперативных заданий.';
								|pl = 'Unknown ""%1"" data type of the universal queue of real-time jobs.';
								|tr = 'Неизвестный тип данных ""%1"" универсальной очереди оперативных заданий.'"),
							DataType);
		
	EndIf;
	
	DeferredJobs.AddTasksToQueue(
		"UniversalQueueOfRealTimeJobs",
		CurrentData,
		GenerateRecordId,
		TaskTable);
	
EndProcedure

// Adds a task to the Universal Task Queue register.
//
// Parameters:
//  Object               - AnyRef -
//  Job              - EnumRef.UniversalQueueTasks -
//  AdditionalData - ValueStorage, Undefined -
//  TaskTable       - See DeferredJobs.AddTasksToQueue.TaskTable
//
Procedure AddJob(Object, Job, AdditionalData = Undefined, TaskTable = Undefined) Export
	
	DeferredJobs.AddTasksToQueue(
		"UniversalQueueOfRealTimeJobs",
		New Structure("Object, Job, AdditionalData", Object, Job, AdditionalData),
		True,
		TaskTable);
	
EndProcedure

// Starts the execution of tasks in the Universal Queue register of operational tasks.
//
// Parameters:
//  QueuesTable - ValueTable, Undefined -
//             1. Task tables - see Initialize the Task tables
//             2. Undefined - starts all tasks of the universal register of operational tasks.
//
Procedure Run(Val QueuesTable = Undefined) Export
	
	DeferredJobs.Run(?(ValueIsFilled(QueuesTable), QueuesTable, "UniversalQueueOfRealTimeJobs"));
	
EndProcedure

#EndRegion

#Region Internal

// Overrides the parameters of the universal queue of operational tasks, and is also used to add
// nested queues (using the Add Nested Queue method).
// 
// Parameters:
//  QueuesTable - See DeferredJobs.TaskQueues
//
Procedure TaskQueues(QueuesTable) Export
	AddNestedQueue(
		QueuesTable,
		Enums.UniversalQueueTasks.UpdatingScheduleOfRegisteredRecordsOfGoodsByStagesOfProduction,
		"Documents.ProductionStage2_2.UpdateScheduleOfRegisteredRecordsOfGoods");
		
	AddNestedQueue(
		QueuesTable,
		Enums.UniversalQueueTasks.UpdatingScheduleOfRegisteredRecordsOfGoodsOnProductionOrders,
		"Documents.ProductionOrder2_2.UpdateScheduleOfRegisteredRecordsOfGoods");
	
	AddNestedQueue(
		QueuesTable,
		Enums.UniversalQueueTasks.UpdateOrderStructureWhenQueuePlaceIsChanged,
		"OrderStructureInternal.UpdateOrderStructureONChangingPlaceInQueue");
	
	AddNestedQueue(
		QueuesTable,
		Enums.UniversalQueueTasks.UpdatePriorityInProductionStages,
		"ProductionManagement.UpdatePriorityInProductionPhases");
		
	AddNestedQueue(
		QueuesTable,
		Enums.UniversalQueueTasks.GenerationOfRelatedBudgetTurnovers,
		"BudgetingServer.GenerateRelatedBudgetTurnover");
	
				
EndProcedure

#EndRegion

#Region Private

// Adds a nested queue to the universal queue of operational tasks.
// 
// Parameters:
//  TaskQueues            - See DeferredJobs.TaskQueues
//  ValueOfActionPointer - EnumRef.UniversalQueueTasks - The Value Of The Action Pointer
//  MethodName                 - String - the name of the task execution method, the principle of formation is similar
//                                       to the argument method name of the general purpose method.Perform
//                                       (See Common.ExecuteConfigurationMethod.MethodName)the Configuration method.
//
Procedure AddNestedQueue(TaskQueues, ValueOfActionPointer, MethodName)
	
	DeferredJobs.AddNestedQueue(
		TaskQueues,
		"UniversalQueueOfRealTimeJobs",
		ValueOfActionPointer,
		MethodName)
	
EndProcedure

#EndRegion