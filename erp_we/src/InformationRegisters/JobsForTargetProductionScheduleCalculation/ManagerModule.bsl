#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds entries to the task register.
//
// Parameters:
//  ObjectOfARAP - DocumentRef.ProductionOrder2_2 - the document for which you want to add the assignment.
//  AutoStart    - Boolean - automatically starts the calculation as a background task.
//
Procedure AddJob(ObjectOfARAP, AutoStart = True) Export
	
	Job = New Structure;
	Job.Insert("ObjectOfARAP", ObjectOfARAP);
	
	If AutoStart Then
		DeferredJobs.ProcessQueueTasks("JobsForTargetProductionScheduleCalculation", Job);
	Else
		DeferredJobs.AddTasksToQueue("JobsForTargetProductionScheduleCalculation", Job)
	EndIf;
	
EndProcedure

// Runs production planning in the background
// Parameters:
//  ObjectOfARAP - DocumentRef.ProductionOrder2_2 - the document for which you want to run the job.
//
Procedure RunJob(ObjectOfARAP = Undefined) Export
	
	Queue = "JobsForTargetProductionScheduleCalculation";
	
	If ValueIsFilled(ObjectOfARAP) Then
		
		Filter = New Structure("ObjectOfARAP", ObjectOfARAP);
		
		TaskTable = DeferredJobs.InitializeTaskTable(Queue);
		TaskTable[0].Jobs = DeferredJobs.GetJobs(Queue, Filter);
		
		DeferredJobs.Run(TaskTable);
		
	Else
		
		DeferredJobs.Run(Queue);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
