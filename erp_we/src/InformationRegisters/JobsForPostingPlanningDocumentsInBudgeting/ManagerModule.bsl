#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds entries to the task register.
//
// Parameters:
//  Document - Document link.Internal consumption plan, document link.Purchase plan, Document link.PlanOstatkov, Documentlink.Sales Plan
//				Document link.Sales plan by categories, documentlink.Production plan, Document link.The assembly plan is a document for which you need to add a task.
//
Procedure AddJob(Document) Export
	
	Job = New Structure;
	Job.Insert("JobsForPostingPlanningDocumentsInBudgeting", New Structure);
	Job.JobsForPostingPlanningDocumentsInBudgeting.Insert("Document", Document);
	
	DeferredJobs.Add(Job);
	
EndProcedure

// Starts the task of calculating the queue of production operations
//
Procedure RunJob() Export
	
	DeferredJobs.Run("JobsForPostingPlanningDocumentsInBudgeting");
	
EndProcedure

#EndRegion

#EndIf
