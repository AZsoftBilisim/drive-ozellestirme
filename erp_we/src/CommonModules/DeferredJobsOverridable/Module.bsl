///////////////////////////////////////////////////////////////////
// The "Deferred Tasks" module contains redefined
// procedures and functions for working with the deferred tasks mechanism.
//
///////////////////////////////////////////////////////////////////

#Region Public

// Returns the default number of threads (background jobs).
// 
// Returns:
//  Number - Default Number Of Background Jobs
//
Function DefaultNumberOfThreads() Export
	
	Return 4;
	
EndFunction

// Returns the default calculation portion.
// 
// Returns:
//  Number - The Default Calculation Portion
//
Function DefaultCalculationPortion() Export
	
	Return 100;
	
EndFunction

#EndRegion

#Region Internal

// Overrides queue parameters.
// 
// Parameters:
//  QueuesTable - See DeferredJobs.TaskQueues
//
Procedure TaskQueues(QueuesTable) Export
	
	UniversalQueueOfRealTimeJobs.TaskQueues(QueuesTable);
	
EndProcedure

#EndRegion