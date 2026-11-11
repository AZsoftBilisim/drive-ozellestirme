#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Temporary storage
// - should be used to add tasks in normal cases

// Adds jobs to the calculation of the production order structure and returns the current job queue number
//
// Parameters:
//  Table	 - ValueTable	 - tasks for calculation.
// 
Procedure AddTasks(Table) Export

	SetPrivilegedMode(True);
	
	Queue = Constants.CurrentBorderOfOrderStructureCalculationTasks.Current();
	
	ColumnsByValue = New Structure();
	ColumnsByValue.Insert("RecordDate", ToUniversalTime(CurrentSessionDate()));
	
	RecordSet = InformationRegisters.BufferOfTasksOfBOMOrderStructureCalculation.CreateRecordSet();
	RecordSet.Load(Table);
	
	For Each Record In RecordSet Do
		FillPropertyValues(Record, ColumnsByValue); 
		Record.Queue = ?(Record.Queue > 0, 
			Record.Queue, Queue);
		Record.Separator = New UUID();
	EndDo;

	RecordSet.Write(False);
	
EndProcedure

// Adds tasks to the calculation of the production order structure
//
// Parameters:
//  Table	 - ValueTable	 - tasks for calculation.
//
Procedure AddTasksFullCalculation(Table) Export

	SetPrivilegedMode(True);
	
	Queue = Constants.CurrentBorderOfOrderStructureCalculationTasks.Current();

	ColumnsByValue = New Structure();
	ColumnsByValue.Insert("RecordDate", ToUniversalTime(CurrentSessionDate()));
	ColumnsByValue.Insert("CompleteCalculation", True);
	
	RecordSet = InformationRegisters.BufferOfTasksOfBOMOrderStructureCalculation.CreateRecordSet();
	RecordSet.Load(Table);
	
	For Each Record In RecordSet Do
		FillPropertyValues(Record, ColumnsByValue); 
		Record.Queue = ?(Record.Queue > 0, 
			Record.Queue, Queue);
		Record.Separator = New UUID();
	EndDo;

	RecordSet.Write(False);
	
EndProcedure

// Adds tasks to the calculation of the production order structure
// 
// Parameters:
// 	BillOfMaterials		 - CatalogRef.BillsOfMaterials	- specification.
// 	ProductionOrder	 - DocumentRef.ProductionOrder2_2	- production order.
//
Procedure AddTaskCompleteCalculation(BillOfMaterials, ProductionOrder) Export

	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.BufferOfTasksOfBOMOrderStructureCalculation.CreateRecordSet();
	
	NewRecord = RecordSet.Add();
	
	NewRecord.BillOfMaterials = BillOfMaterials;
	NewRecord.ProductionOrder = ProductionOrder;
	NewRecord.CompleteCalculation = True;
	
	NewRecord.Queue = Constants.CurrentBorderOfOrderStructureCalculationTasks.Current();
	NewRecord.Separator = New UUID();
	
	RecordSet.Write(False);

EndProcedure

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// The final queue of tasks to be calculated
// - can be used to add tasks in the calculation process

// Adds tasks to the calculation of the production order structure to the end of the queue (only for adding tasks during the calculation process)
//
// Parameters:
//  Table			 - ValueTable	 - tasks for calculation.
//  QueueNumber	 - Number			 - queue number.
//
Procedure AddTasksToEndOfQueue(Table, QueueNumber) Export

	SetPrivilegedMode(True);
	
	ColumnsByValue = New Structure();
	ColumnsByValue.Insert("Queue", QueueNumber);
	
	RecordSet = InformationRegisters.TasksOfBOMOrderStructureCalculation.CreateRecordSet();
	RecordSet.Load(Table);
	
	For Each Record In RecordSet Do
		FillPropertyValues(Record, ColumnsByValue);
		Record.Separator = New UUID();
	EndDo;
	
	RecordSet.Write(False);
	
EndProcedure

#EndRegion

#Region Internal

// Selects changes from the queue based on the calculation date (including)
//
// Parameters:
//  CalculationBoundary	 - Number - Calculation Boundary
// 
// Returns:
//  Number - queue number
//
Function SelectChanges(CalculationBoundary) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.Text =
		"SELECT
		|	Table.Queue                AS Queue,
		|	Table.Separator            AS Separator,
		|	Table.CompleteCalculation           AS CompleteCalculation,
		|	Table.BillOfMaterials           AS BillOfMaterials,
		|	Table.ProductionOrder    AS ProductionOrder
		|FROM
		|	InformationRegister.BufferOfTasksOfBOMOrderStructureCalculation AS Table
		|WHERE
		|	Table.Queue <= &CalculationBoundary
		|";
	Query.SetParameter("CalculationBoundary", CalculationBoundary);
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.BufferOfTasksOfBOMOrderStructureCalculation");
		LockItem.SetValue("Queue", New Range(, CalculationBoundary));
		Block.Lock();
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			
			Buffer = QueryResult.Unload();
			
			Set = InformationRegisters.BufferOfTasksOfBOMOrderStructureCalculation.CreateRecordSet();
			Set.Load(Buffer);
			Set.Write(ReplacementMode.Delete);
			
			Set = InformationRegisters.TasksOfBOMOrderStructureCalculation.CreateRecordSet();
			Set.Load(Buffer);
			Set.Write(False);
		
		EndIf;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Warning,,, 
			DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	Query.Text =
		"SELECT TOP 1
		|	Table.Queue AS Queue
		|FROM
		|	InformationRegister.TasksOfBOMOrderStructureCalculation AS Table
		|WHERE
		|	Table.Queue <= &CalculationBoundary
		|
		|ORDER BY
		|	Queue";
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		QueueNumber = -1;
	Else
		QueueNumber = QueryResult.Unload()[0].Queue;
	EndIf;
	
	Return QueueNumber;
	
EndFunction

// Deletes tasks by queue number
// 
// Parameters:
// 	Queue - Number - queue number
Procedure DeleteTasks(Queue) Export
	
	SetPrivilegedMode(True);
	
	Set = InformationRegisters.TasksOfBOMOrderStructureCalculation.CreateRecordSet();
	Set.Filter.Queue.Set(Queue);
	Set.Write(True);
	
EndProcedure

// Returns a new task table
// 
// Returns:
// 	ValueTable - LongDesc
//
Function TaskTable() Export
	
	Table = InformationRegisters.TasksOfBOMOrderStructureCalculation.CreateRecordSet().UnloadColumns("BillOfMaterials,ProductionOrder");
	Return Table;
	
EndFunction

#EndRegion

#Region Private

Function FullName() Export

	FullName = Metadata.InformationRegisters.TasksOfBOMOrderStructureCalculation.FullName();

	Return FullName;

EndFunction

#EndRegion

#EndIf