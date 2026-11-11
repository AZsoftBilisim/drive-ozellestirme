#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal

Procedure TransferTasks() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		Block = New DataLock();
		Block.Add("Catalog.DeleteJobsQueue");
		Block.Add("Catalog.JobsQueue");
		Block.Add("InformationRegister.JobsProperties");
		Block.Lock();
		
		Selection = Catalogs.DeleteJobsQueue.Select();
		While Selection.Next() Do
			OldAssignment = Selection.GetObject();
			NewJob = Catalogs.JobsQueue.CreateItem();
			NewJob.Use = OldAssignment.Use;
			NewJob.ScheduledStartTime = OldAssignment.ScheduledStartTime;
			NewJob.Milliseconds = OldAssignment.Milliseconds;
			NewJob.JobState = OldAssignment.JobState;
			NewJob.ActiveBackgroundJob = OldAssignment.ActiveBackgroundJob;
			NewJob.ExclusiveExecution = OldAssignment.ExclusiveExecution;
			NewJob.AttemptNumber = OldAssignment.AttemptNumber;
			NewJob.MethodName = OldAssignment.MethodName;
			NewJob.Parameters = OldAssignment.Parameters;
			NewJob.BeginDateOfTheLastLaunch = OldAssignment.BeginDateOfTheLastLaunch;
			NewJob.EndDateOfTheLastLaunch = OldAssignment.EndDateOfTheLastLaunch;
			NewJob.Key = OldAssignment.Key;
			NewJob.RestartIntervalOnFailure = OldAssignment.RestartIntervalOnFailure;
			NewJob.Schedule = OldAssignment.Schedule;
			NewJob.RestartCountOnFailure = OldAssignment.RestartCountOnFailure;
			NewJob.UserName = OldAssignment.UserName;
			NewRef = Catalogs.JobsQueue.GetRef(Selection.Ref.UUID());
			NewJob.SetNewObjectRef(NewRef);
			NewJob.DataExchange.Load = True;
			NewJob.Write();
			OldAssignment.DataExchange.Load = True;
			OldAssignment.Delete();
		EndDo;
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	JobsProperties.JobID
		|FROM
		|	InformationRegister.JobsProperties AS JobsProperties
		|WHERE
		|	JobsProperties.Job REFS Catalog.DeleteJobsQueue";
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			RecordSet = InformationRegisters.JobsProperties.CreateRecordSet();
			RecordSet.Filter.JobID.Set(Selection.JobID);
			RecordSet.Read();
			For Each Record In RecordSet Do
				Record.Job = Catalogs.JobsQueue.GetRef(Record.Job.UUID());
			EndDo;
			RecordSet.DataExchange.Load = True;
			RecordSet.Write();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
		
EndProcedure

#EndRegion
	
#EndIf