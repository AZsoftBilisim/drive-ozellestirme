#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Object = ThisObject;
	
	If Cancel Or Object.IsFolder Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Job = ScheduledJobsServer.Job(Object.ScheduledJob);
	If Job = Undefined Then
		
		JobParameters = New Structure;
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.AutomaticAccrueAndDeductionOfBonusPoints);
		JobParameters.Insert("Use", False);
		JobParameters.Insert("Description", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tự động cộng và trừ điểm thưởng: %1';
				|ru = 'Автоматическое начисление и списание бонусных баллов: %1';
				|en = 'Automatic accrual and write-off of bonus points: %1'; fa = 'Automatic accrual and write-off of bonus points: %1';
				|it = 'Accredito e cancellazione automatica dei punti bonus: %1';
				|pl = 'Automatyczne naliczanie i spisywanie punktów bonusowych: %1';
				|tr = 'Bonus puanların otomatik olarak tahakkuk edilmesi ve silinmesi: %1'"), 
			TrimAll(Object.Description)));
		Job = ScheduledJobsServer.AddJob(JobParameters);
		Object.ScheduledJob = ScheduledJobsServer.UUID(Job);
		
	EndIf;
	
	Object.AdditionalProperties.Insert("Job",Job);
	SetPrivilegedMode(False);

EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Object = ThisObject;
	
	If Cancel Or Object.IsFolder Then
		Return;
	EndIf;
	
	ScheduledJobsServer.DeleteJob(Object.ScheduledJob);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Object = ThisObject;
	
	If Cancel Or Object.IsFolder Then
		Return;
	EndIf;

	If Object.AdditionalProperties.Property("Job") Then
		Job = Object.AdditionalProperties.Job;
		If Job = Undefined Then
			Return;
		EndIf;
	Else
		Return;
	EndIf;
	
	JobParameters = New Structure;
	
	// The schedule is set in the form of an element
	If Object.AdditionalProperties.Property("Schedule") 
			And TypeOf(Object.AdditionalProperties.Schedule) = Type("JobSchedule") Then
		JobParameters.Insert("Schedule", Object.AdditionalProperties.Schedule);
	EndIf;
	
	// Usage is set in the form of an element
	If Object.DeletionMark Then
		JobParameters.Insert("Use", False);
	ElsIf Object.AdditionalProperties.Property("Use") Then
		JobParameters.Insert("Use", Object.AdditionalProperties.Use);
	EndIf;
	
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tự động cộng và trừ điểm thưởng: %1';
																					|ru = 'Автоматическое начисление и списание бонусных баллов: %1';
																					|en = 'Automatic accrual and write-off of bonus points: %1'; fa = 'Automatic accrual and write-off of bonus points: %1';
																					|it = 'Accredito e cancellazione automatica dei punti bonus: %1';
																					|pl = 'Automatyczne naliczanie i spisywanie punktów bonusowych: %1';
																					|tr = 'Bonus puanların otomatik olarak tahakkuk edilmesi ve silinmesi: %1'"), TrimAll(Object.Description));
	JobParameters.Insert("Description", JobDescription);
	
	Parameters = New Array;
	Parameters.Add(Object.Ref);
	JobParameters.Insert("Parameters", Parameters);
	
	SetPrivilegedMode(True);
	ScheduledJobsServer.ChangeJob(Object.ScheduledJob, JobParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	ScheduledJob = Undefined;
	
EndProcedure

#EndRegion

#EndIf
