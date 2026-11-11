#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal
	
// Returns:
// 	JobSchedule
//
Function DefaultSchedule() Export
	
	Schedule = New JobSchedule;
	Schedule.DaysRepeatPeriod = 1;
	Schedule.RepeatPeriodInDay = 60;
	
	Return Schedule;
	
EndFunction

// The update handler
//
Procedure TransferDataFromRoutineTask() Export
	
	Filter = New Structure("Metadata", Metadata.ScheduledJobs.DeleteJobsQueueProcessingCTL);
	FoundJobs = ScheduledJobs.GetScheduledJobs(Filter);
	For Each Job In FoundJobs Do
		Ref = Catalogs.JobsQueueHandlers.GetRef(New UUID(Job.Key));
		HandlerTaskQueues = Ref.GetObject();
		If HandlerTaskQueues <> Undefined Then
			HandlerTaskQueues.Use = Job.Use;
			HandlerTaskQueues.Schedule = New ValueStorage(Job.Schedule);
			HandlerTaskQueues.DataExchange.Load = True;
			HandlerTaskQueues.Write();
		EndIf;
		Job.Delete();
	EndDo;
	
EndProcedure

#EndRegion
	
#EndIf
