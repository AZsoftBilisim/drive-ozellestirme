#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds entries to the task register.
//
// Parameters:
//  Data - DocumentRef.ProductionStage2_2, ValueTable - the document for which you want to add a task,
//                                                                 or a table of documents for which you want to
//                                                                 add tasks, with a column:
//                                                                  * ObjectOfARAP - DocumentRef.ProductionStage2_2 -
//  AutoStart - Boolean - automatic start of the task.
//
Procedure AddTasks(Data, AutoStart = True) Export
	
	If TypeOf(Data) = Type("ValueTable") Then
		Jobs = Data;
	Else
		Jobs = New Structure;
		Jobs.Insert("ObjectOfARAP", Data);
	EndIf;
	
	If AutoStart Then
		DeferredJobs.ProcessQueueTasks("JobsForCalculatingProductionOperationQueue", Jobs);
	Else
		DeferredJobs.AddTasksToQueue("JobsForCalculatingProductionOperationQueue", Jobs);
	EndIf;
	
EndProcedure

// Starts tasks for calculating the queue of production operations
//
Procedure StartJobs() Export
	
	DeferredJobs.Run("JobsForCalculatingProductionOperationQueue");
	
EndProcedure

// Initializes a data table for recording tasks that can be passed to the method input See AddTasks
//
// Returns:
//  ValueTable - Task Data Table:
//   * ObjectOfARAP - DocumentRef.ProductionStage2_2 - the document for which you want to add the assignment.
//
Function InitializeTaskDataTable() Export
	
	Table = New ValueTable;
	Table.Columns.Add("ObjectOfARAP", New TypeDescription("DocumentRef.ProductionStage2_2"));
	
	Return Table;
	
EndFunction

#EndRegion

#EndIf