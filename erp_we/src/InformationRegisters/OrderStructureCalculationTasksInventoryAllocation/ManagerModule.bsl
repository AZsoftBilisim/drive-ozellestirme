#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Temporary storage
// - should be used to add tasks in normal cases

// Adds tasks to the calculation of the production order structure
//
// Parameters:
//  Table	 - ValueTable	 - tasks for calculation.
//
Procedure AddTasks(Table) Export

	SetPrivilegedMode(True);
	
	Queue = Constants.CurrentBorderOfOrderStructureCalculationTasks.Current();
	
	ColumnsByValue = New Structure();
	ColumnsByValue.Insert("RecordDate", ToUniversalTime(CurrentSessionDate()));
	
	RecordSet = InformationRegisters.BufferOfOrderStructureCalculationTasksInventoryAllocation.CreateRecordSet();
	RecordSet.Load(Table);
	
	For Each Record In RecordSet Do
		FillPropertyValues(Record, ColumnsByValue); 
		Record.Queue = ?(Record.Queue > 0, 
			Record.Queue, Queue);
		Record.Separator = New UUID();
	EndDo;

	RecordSet.Write(False);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// The final queue of tasks to be calculated
// - can be used to add tasks in the calculation process

// Adds tasks to the calculation of the production order structure in the next queue (only for adding tasks during the calculation process)
//
// Parameters:
//  Table		 - ValueTable	 - tasks for calculation.
//  QueueNumber - Number			 - queue number.
//
Procedure AddTasksToNextQueue(Table, QueueNumber) Export

	SetPrivilegedMode(True);

	ColumnsByValue = New Structure();
	ColumnsByValue.Insert("Queue", QueueNumber + 1);
	
	RecordSet = InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.CreateRecordSet();
	RecordSet.Load(Table);
	
	For Each Record In RecordSet Do
		FillPropertyValues(Record, ColumnsByValue);
		Record.Separator = New UUID();
	EndDo;

	RecordSet.Write(False);
EndProcedure

// Adds tasks to the calculation of the production order structure in the next queue (only for adding tasks during the calculation process)
//
// Parameters:
//  Products	 - CatalogRef.Products			 - Products
//  Characteristic	 - CatalogRef.ItemsCharacteristics	 - characteristics of the nomenclature
//  Warehouse			 - CatalogRef.Warehouses						 - Warehouse
//  Purpose		 - CatalogRef.Assignments					 - Purpose
//  QueueNumber	 - Number										 - queue number.
//
Procedure AddTaskToNextQueue(Products, Characteristic, Warehouse, Purpose, QueueNumber) Export

	SetPrivilegedMode(True);

	RecordSet = InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.CreateRecordSet();
	
	NewRecord = RecordSet.Add();
	
	NewRecord.Queue = QueueNumber + 1;
	
	NewRecord.Products   = Products;
	NewRecord.Characteristic = Characteristic;
	NewRecord.Warehouse          = Warehouse;
	NewRecord.Purpose     = Purpose;
	
	NewRecord.Separator = New UUID();
	
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
		|	Table.Queue             AS Queue,
		|	Table.Separator         AS Separator,
		|	Table.Products        AS Products,
		|	Table.Characteristic      AS Characteristic,
		|	Table.Warehouse               AS Warehouse,
		|	Table.Purpose          AS Purpose,
		|	Table.ProductionOrder AS ProductionOrder
		|FROM
		|	InformationRegister.BufferOfOrderStructureCalculationTasksInventoryAllocation AS Table
		|WHERE
		|	Table.Queue <= &CalculationBoundary
		|	AND NOT(Table.RecordDate > &BoundDataExpectationBoundary
		|					AND (Table.ProductionOrder = VALUE(Document.ProductionOrder2_2.EmptyRef)
		|						AND TRUE IN
		|							(SELECT TOP 1
		|								TRUE
		|							FROM
		|								InformationRegister.JobsForAllocatingInventory AS JobsForAllocatingInventory
		|							WHERE
		|								JobsForAllocatingInventory.Products = Table.Products
		|								AND JobsForAllocatingInventory.Characteristic = Table.Characteristic)
		|						OR Table.ProductsItems <> VALUE(Catalog.Products.EmptyRef)
		|							AND TRUE IN
		|								(SELECT TOP 1
		|									TRUE
		|								FROM
		|									InformationRegister.JobsForAllocatingInventory AS JobsForAllocatingInventory
		|								WHERE
		|									JobsForAllocatingInventory.Products = Table.ProductsItems))
		|				OR NOT Table.ProductsItems IN (VALUE(Catalog.Products.EmptyRef), Table.Products)
		|					AND TRUE IN
		|						(SELECT TOP 1
		|							TRUE
		|						FROM
		|							InformationRegister.BufferOfOrderStructureCalculationTasksInventoryAllocation AS TaskBufferManufacturedProducts
		|						WHERE
		|							TaskBufferManufacturedProducts.Queue <= &CalculationBoundary
		|							AND TaskBufferManufacturedProducts.Products = Table.ProductsItems))
		|";
	Query.SetParameter("CalculationBoundary", CalculationBoundary);
	Query.SetParameter("BoundDataExpectationBoundary", ToUniversalTime(CurrentSessionDate()) - 500);
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.BufferOfOrderStructureCalculationTasksInventoryAllocation");
		LockItem.SetValue("Queue", New Range(, CalculationBoundary));
		Block.Lock();
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			
			Buffer = QueryResult.Unload();
			
			Set = InformationRegisters.BufferOfOrderStructureCalculationTasksInventoryAllocation.CreateRecordSet();
			Set.Load(Buffer);
			Set.Write(ReplacementMode.Delete);
			
			Set = InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.CreateRecordSet();
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
		|	InformationRegister.OrderStructureCalculationTasksInventoryAllocation AS Table
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
	
	Set = InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.CreateRecordSet();
	Set.Filter.Queue.Set(Queue);
	Set.Write(True);
	
EndProcedure

#EndRegion

#Region Private

Function FullName() Export

	FullName = Metadata.InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.FullName();

	Return FullName;

EndFunction

#EndRegion

#EndIf