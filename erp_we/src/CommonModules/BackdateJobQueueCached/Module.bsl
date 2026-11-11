#Region Internal

// Description of task queues.
// Used when generating request texts for executing tasks in a non-operational queue.
// 
// Returns:
//  Structure - Task Queues:
// * KindsOfTasks - Map of CatalogRef.BackdateJobKinds - Description of the types of tasks.
// * QueuesTable - ValueTable - Description of queues:
// ** Register - CatalogRef.MetadataObjectIDs - Queue register.
// ** QueueName - String - Queue Name
// ** FullNameOfQueue  - String - Full Name of the Queue
// ** RequestParameterTaskType  - String - LongDesc See BackdateJobQueue.StructureOfDescriptionOfQueueParameters.
// ** TaskTypeValue - String - LongDesc See BackdateJobQueue.StructureOfDescriptionOfQueueParameters.
// ** RequestParameterQueueNumber - String - LongDesc See BackdateJobQueue.StructureOfDescriptionOfQueueParameters.
// ** QueueNumberValue - String - LongDesc See BackdateJobQueue.StructureOfDescriptionOfQueueParameters.
// ** QueueNumberField - String - LongDesc See BackdateJobQueue.StructureOfDescriptionOfQueueParameters.
// ** CalculationGrunulaFields - String - Comma-separated list of job queue register fields.
// ** CalculationGranules - ValueTable - A table with a description of the calculation granules for tasks.
// The composition of the table fields corresponds to the fields of the calculation granule of the queue register (see the Calculation Granule table() in the Queue Register Manager module).
// For each table entry, additional information is stored about the type of job being processed and the workflow identifier.
// ** TaskRegisterManager - InformationRegisterManager - Task Register Manager
// ** NameQueue - String -Name Of the Task Queue
// ** QueryTextCalculationGranulesInProcessing - String - LongDesc See BackdateJobQueue.StructureOfDescriptionOfQueueParameters.
// ** QueryTextExcludedDocuments - String - LongDesc See BackdateJobQueue.StructureOfDescriptionOfQueueParameters.
// ** ProcessedGranulesTableName - String - LongDesc See BackdateJobQueue.StructureOfDescriptionOfQueueParameters.
// ** AvailabilityOfChangeControlPeriodField - Boolean - the presence in the register of the Attribute "Change control period".
// 
Function TaskQueues() Export

	TaskQueues = New Structure;
	
	QueuesTable = New ValueTable;
	QueuesTable.Columns.Add("Register", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	QueuesTable.Columns.Add("QueueName", Common.StringTypeDetails(1000));
	QueuesTable.Columns.Add("FullNameOfQueue", Common.StringTypeDetails(1000));
	
	QueuesTable.Columns.Add("RequestParameterTaskType", Common.StringTypeDetails(250));
	QueuesTable.Columns.Add("TaskTypeValue", New TypeDescription("CatalogRef.BackdateJobKinds"));
	QueuesTable.Columns.Add("RequestParameterQueueNumber", Common.StringTypeDetails(250));
	QueuesTable.Columns.Add("QueueNumberValue", Common.TypeDescriptionNumber(10,0));
	
	QueuesTable.Columns.Add("QueueNumberField", Common.StringTypeDetails(1000));
	QueuesTable.Columns.Add("CalculationGranules",New TypeDescription("ValueTable"));
	QueuesTable.Columns.Add("CalculationGrunulaFields",Common.StringTypeDetails(0));
	QueuesTable.Columns.Add("TaskRegisterManager");
	QueuesTable.Columns.Add("NameQueue", Common.StringTypeDetails(1000));
	QueuesTable.Columns.Add("QueryTextCalculationGranulesInProcessing", New TypeDescription("String"));
	QueuesTable.Columns.Add("QueryTextExcludedDocuments", New TypeDescription("String"));
	QueuesTable.Columns.Add("ProcessedGranulesTableName", Common.StringTypeDetails(1000));
	QueuesTable.Columns.Add("AvailabilityOfChangeControlPeriodField", New TypeDescription("Boolean"));
		
	QueuesTable.Indexes.Add("Register");
	
	// Excluded types of tasks are listed in the Catalog for reference.
	// In the mechanism of a non-operational queue, tasks should not be registered and processed for them.
	ExcludedTypesOfTasks = New Array;
	
	
	ExcludedTypesOfTasks.Add(Catalogs.BackdateJobKinds.RecordInFinancialAccounting);
	Query = New Query;
	Query.Text = "
	|SELECT
	|	BackdateJobKinds.Ref AS JobKind,
	|	BackdateJobKinds.Register AS QueueRegister,
	|	BackdateJobKinds.MaximumBatch AS MaximumBatch,
	|	BackdateJobKinds.QueueNumber AS QueueNumber
	|FROM
	|	Catalog.BackdateJobKinds AS BackdateJobKinds
	|WHERE
	|	NOT BackdateJobKinds.Ref IN (&ExcludedTypesOfTasks)";
	Query.SetParameter("ExcludedTypesOfTasks", ExcludedTypesOfTasks);
	
	KindsOfTasks = New Map;
	SetPrivilegedMode(True);
	DataOnTypesOfTasks = Query.Execute().Unload();
	SetPrivilegedMode(False);
	For Each CurrentTypeOfTask In DataOnTypesOfTasks Do
		
		KindsOfTasks.Insert(CurrentTypeOfTask.JobKind, Common.ValueTableRowToStructure(CurrentTypeOfTask));
		
	EndDo;
		
	TaskQueues.Insert("KindsOfTasks", KindsOfTasks);
	
	ArrayOfRegisters = CommonClientServer.CollapseArray(DataOnTypesOfTasks.UnloadColumn(
		"QueueRegister"));
	
	For Each QueueRegister In ArrayOfRegisters Do
		
		TaskRegisterMetadata = Common.MetadataObjectByID(QueueRegister);
		FullNameOfQueue = TaskRegisterMetadata.FullName();
		QueueName = TaskRegisterMetadata.Name;
		TaskRegisterManager = Common.ObjectManagerByFullName(FullNameOfQueue);

		NewRecord = QueuesTable.Add();
		NewRecord.Register = QueueRegister;
		NewRecord.FullNameOfQueue = FullNameOfQueue;
		NewRecord.QueueName = QueueName;
		NewRecord.TaskRegisterManager = TaskRegisterManager;
		NewRecord.NameQueue = TaskRegisterMetadata.Presentation();
		QueueParameters = TaskRegisterManager.DescriptionOfQueueParameters(QueueName);
		FillPropertyValues(NewRecord, QueueParameters);
		
		CalculationGranules = TaskRegisterManager.TableOfCalculationGranules(); // ValueTable
		
		ColumnsNames = New Array;
		For Each Column In CalculationGranules.Columns Do
			ColumnsNames.Add(Column.Name);
		EndDo;
		NewRecord.CalculationGrunulaFields = StrConcat(ColumnsNames, ", ");
		
		CalculationGranules.Columns.Add("JobKind", New TypeDescription("CatalogRef.BackdateJobKinds"));
		CalculationGranules.Columns.Add("ThreadID", New TypeDescription("UUID"));
		NewRecord.CalculationGranules = CalculationGranules;
		NewRecord.AvailabilityOfChangeControlPeriodField = TaskRegisterMetadata.Attributes.Find("ChangeControlPeriod") <> Undefined;
		
	EndDo;
	
	QueuesTable.Indexes.Add("Register");
	TaskQueues.Insert("QueuesTable", QueuesTable);
	
	Return TaskQueues;
	
EndFunction

// Retrieves the list of available types of tasks for the queue register by its ID.
// 
// Parameters:
//  RegisterID - CatalogRef.MetadataObjectIDs -Register ID
// 
// Returns:
//  Array of CatalogRef.BackdateJobKinds - List Of Available Types Of Tasks For The Queue Register
Function ListOfAvailableTypesOfTasksForQueueRegister(RegisterID) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	BackdateJobKinds.Ref AS JobKind
	|FROM
	|	Catalog.BackdateJobKinds AS BackdateJobKinds
	|WHERE
	|	BackdateJobKinds.Register = &QueueRegister";
	Query.SetParameter("QueueRegister", RegisterID);
	SetPrivilegedMode(True);
	ListOfAvailableTypesOfTasks = Query.Execute().Unload().UnloadColumn("JobKind");
	SetPrivilegedMode(False);
	
	Return ListOfAvailableTypesOfTasks;
	
EndFunction

// The size of the portion is the distribution of AR/AP accounts by time.
// 
// Returns:
//  Number - The maximum size of the portion of the distribution of the terms of the AR/AP accounts
Function PortionSizeDistributionOfSettlementsByTime() Export
	
	ARAPAllocationByDueDates = Catalogs.BackdateJobKinds.ARAPAllocationByDueDates;
	PortionOfCalculation = Common.ObjectAttributeValue(ARAPAllocationByDueDates, "MaximumBatch");
	
	Return PortionOfCalculation;
	
EndFunction

#EndRegion
