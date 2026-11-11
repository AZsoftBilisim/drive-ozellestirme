// @strict-types

#Region Public

// Deprecated. Selects the reference list for the task queue that is being added.
//
// Parameters:
//	JobParameters - Structure - Parameters of the task being added, possible keys:
//	 * DataArea - Number - Data area
//	 * Use - Boolean - the fact of the use
//	 * ScheduledStartTime - Date - launch start date
//	 * ExclusiveExecution - Boolean - the fact of the exclusive run
//	 * MethodName - String - name of the method for the task (required.)
//	 * Parameters - Array - array of task parameters
//	 * Key - String - task key
//	 * RestartIntervalOnFailure - Number - specified in seconds
//	 * Schedule - JobSchedule - the schedule of the job
//	 * RestartCountOnFailure - Number - number of repetitions.
//	 
// Returns:
//	CatalogManager.JobsQueue - manager.
Function WhenSelectingReferenceCatalogForTask(Val JobParameters) Export
	
	Return Undefined;
	
EndFunction

#EndRegion
