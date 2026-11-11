// @strict-types

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Basic procedures and functions.

// All methods available in the API operate with task parameters. The possibility of using 
// a specific parameter depends on the method and, in some cases, the values of other
// parameters. More about this is written in the description of specific methods.
// For a description of the parameters, see New parameters of the assignment.

// Gets queue tasks based on the specified selection.
// It is possible to obtain inconsistent data.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  Filter - Structure - values to select tasks by (combined by And). Possible structure keys:
//            * DataArea - Number - data region,
//            * MethodName - String - method name,
//            * Id - UUID - task ID,
//            * JobState - EnumRef.JobsStates - job status,
//            * Key - String - task key,
//            * Template - CatalogRef.QueueJobTemplates - job template,
//            * Use - Boolean - using the task.
//        - Array of Structure - LongDesc:
//            * ComparisonType - ComparisonType - valid values are:
//                Type of comparison.Equal, kind of equality.Unequal - for comparison with the value,
//                type of comparison.VSpiske, kind of comparison.Non-list - for comparison with an array.
//            * Value - Arbitrary - comparison values for comparison types are Equal / unequal
//            			 - Array -  for the types of comparison VSpiske and non-VSPISKE
//
// Returns:
//  ValueTable - table of found tasks. Columns correspond to task parameters:
//	 * Id - CatalogRef.JobsQueue - link to the reference book.
//	 ...
//
Function GetJobs(Val Filter) Export
EndFunction

// Adds a new task to the queue.
// In the case of a call in a transaction, an object lock is set for a job.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters: 
//  JobParameters - Structure - parameters of the task being added. Description:
//  * DataArea - Number - number of the data area.
//  * Use - Boolean - signs of use.
//  * ScheduledStartTime - Date - the moment of start (Datetime)
//  * ExclusiveExecution - Boolean - indicates exclusive execution.
//  * MethodName - String - name of the method for the task, required to specify.
//  * Parameters - Array - method parameter.
//  * Key - String - key for the task's uniqueness.
//  * RestartIntervalOnFailure - Number - repeat interval in seconds.
//  * Schedule - JobSchedule - task execution schedules.
//  * RestartCountOnFailure - Number - number of repetitions.
//
// Returns: 
//  CatalogRef.JobsQueue - ID of the added task.
// 
Function AddJob(JobParameters) Export
EndFunction

// Changes the task with the specified ID.
// In the case of a call in a transaction, an object lock is set for a job.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters: 
//	Id - CatalogRef.JobsQueue - the ID of the job.
//	JobParameters - Structure - parameters to set for the task, possible keys:
//						* Use - Boolean -
//						* ScheduledStartTime - Date -
//						* ExclusiveExecution - Boolean - 
//						* MethodName - String - 
//						* Parameters - Array - 
//  					* Key - String - 
//						* RestartIntervalOnFailure - Number - 
//						* Schedule - JobSchedule - 
//						* RestartCountOnFailure - Number - 
//   				- Structure - if the task is based on a template, only the following keys can be specified:
//						* Use - Boolean - 
//						* ScheduledStartTime - Date - 
//						* ExclusiveExecution - Boolean - 
//						* RestartIntervalOnFailure - Number - 
//						* Schedule - JobSchedule - 
//						* RestartCountOnFailure - Number - 
// 
Procedure ChangeJob(Id, JobParameters) Export
EndProcedure

// Deletes a task from the task queue.
// Deleting tasks with an installed template is prohibited.
// In the case of a call in a transaction, an object lock is set for a job.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  Id - CatalogRef.JobsQueue - the ID of the job.
//
Procedure DeleteJob(Id) Export
EndProcedure

// Returns the queue task template by the name of the predefined routine task from which it was created.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  Name - String - name of the predefined scheduled task.
//
// Returns:
//  CatalogRef.QueueJobTemplates - task template.
//
Function TemplateByName_(Val Name) Export
EndFunction

// Returns the error text when trying to complete two tasks with the same key at the same time.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//   String - the exception text.
//
Function GetExceptionTextJobsWithSameKeyDuplication() Export
EndFunction

// Returns a list of queue job templates.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//  Array of String - names of predefined undivided routine tasks that are used 
//           as templates for queue tasks.
//
//
Function QueueJobTemplates() Export
EndFunction

// Returns the Task Queue Catalog manager.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	CatalogManager.JobsQueue - directory manager.
//
Function CatalogJobsQueue() Export
EndFunction

#EndRegion
