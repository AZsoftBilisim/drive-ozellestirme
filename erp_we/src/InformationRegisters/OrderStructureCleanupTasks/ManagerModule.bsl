#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds tasks to the calculation of the production order structure
// 
// Parameters:
// 	ProductionOrders - Array, DocumentRef.ProductionOrder2_2	- a production order or a list of production orders.
Procedure AddTasks(Val ProductionOrders) Export

	SetPrivilegedMode(True);
	
	ProductionOrders = TMCommonUseClientServer.Array(ProductionOrders);
	
	RecordSet = InformationRegisters.OrderStructureCleanupTasks.CreateRecordSet();
	
	For Each ProductionOrder In ProductionOrders Do
	
		NewRecord = RecordSet.Add();
		NewRecord.ProductionOrder = ProductionOrder;
		NewRecord.Separator = New UUID()
		
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
	|	&Boundary                       AS Queue,
	|	&Separator                   AS Separator,
	|	Table.ProductionOrder    AS ProductionOrder
	|FROM
	|	InformationRegister.OrderStructureCleanupTasks AS Table
	|WHERE 
	|	Table.Queue = 0
	|
	|GROUP BY
	|	Table.ProductionOrder
	|";
	Query.SetParameter("Boundary", CalculationBoundary);
	Query.SetParameter("Separator", New UUID);
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.OrderStructureCleanupTasks");
		LockItem.SetValue("Queue", 0);
		Block.Lock();
		
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			
			Set = InformationRegisters.OrderStructureCleanupTasks.CreateRecordSet();
			Set.Load(QueryResult.Unload());
			Set.Write(False);
			
			Set = InformationRegisters.OrderStructureCleanupTasks.CreateRecordSet();
			Set.Filter.Queue.Set(0);
			Set.Write(True);
			
		EndIf;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Warning,,,
			DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	Query.SetParameter("CalculationBoundary", CalculationBoundary);
	Query.Text =
		"SELECT TOP 1
		|	Table.Queue AS Queue
		|FROM
		|	InformationRegister.OrderStructureCleanupTasks AS Table
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
	
	Set = InformationRegisters.OrderStructureCleanupTasks.CreateRecordSet();
	Set.Filter.Queue.Set(Queue);
	Set.Write(True);
	
EndProcedure

#EndRegion

#Region Private

Function FullName() Export

	FullName = Metadata.InformationRegisters.OrderStructureCleanupTasks.FullName();

	Return FullName;

EndFunction

#EndRegion

#EndIf