#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds entries to the task register.
//
// Parameters:
//  ObjectOfARAP	 - CatalogObject.ARAPObjects  - reference list to add the task to.
//  CompleteCalculation	 - Boolean							 - a sign that you need to calculate the standard duration of production stages.
//  AutoStart		 - Boolean							 - automatic start.
//
Procedure AddJob(ObjectOfARAP, CompleteCalculation = False, AutoStart = True) Export
	
	Job = New Structure;
	Job.Insert("ObjectOfARAP", ObjectOfARAP);
	Job.Insert("CompleteCalculation",  CompleteCalculation);
	
	If AutoStart Then
		DeferredJobs.ProcessQueueTasks("JobsOfStandardProductionDurationCalculation", Job);
	Else
		DeferredJobs.AddTasksToQueue("JobsOfStandardProductionDurationCalculation", Job);
	EndIf;
	
EndProcedure

// Starts production planning
//
// Parameters:
//  Filter - Undefined, See DeferredJobs.GetJobs.Filter
//
Procedure RunJob(Filter = Undefined) Export
	
	Queue = "JobsOfStandardProductionDurationCalculation";
	
	If ValueIsFilled(Filter) Then
		
		TaskTable = DeferredJobs.InitializeTaskTable(Queue);
		TaskTable[0].Jobs = DeferredJobs.GetJobs(Queue, Filter);
		
		DeferredJobs.Run(TaskTable);
		
	Else
		
		DeferredJobs.Run(Queue);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf