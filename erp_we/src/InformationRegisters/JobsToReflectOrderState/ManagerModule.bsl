#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds tasks to the information register "Tasks to reflect the State of orders".
// 
// Parameters:
//  Jobs - DocumentRef, Array of DocumentRef - a document or an array of documents that need to be reflected.
//  Action - String - 
//  TaskTable - See DeferredJobs.AddTasksToQueue.TaskTable
//
Procedure AddTasks(Jobs, Action = "", TaskTable = Undefined) Export
	
	Data = New Structure("Document, Action");
	
	If TypeOf(Jobs) = Type("Array") Then
		
		For Each Job In Jobs Do
			
			Data.Document = Job;
			Data.Action = Action;
			
			DeferredJobs.AddTasksToQueue("JobsToReflectOrderState", Data,, TaskTable);
			
		EndDo;
		
	Else
		
		Data.Document = Jobs;
		Data.Action = Action;
		
		DeferredJobs.AddTasksToQueue("JobsToReflectOrderState", Data,, TaskTable);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf