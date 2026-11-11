
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	Parameters.Property("ScheduledJobID", ScheduledJobID);
	
	SetPrivilegedMode(True);
	ScheduledJob = GetScheduledJobData(ScheduledJobID);
	SetPrivilegedMode(False);
	
	FillPropertyValues(ThisObject, ScheduledJob, ScheduledJobParameters());
	Description = Metadata.ScheduledJobs.DeleteDuplicatesOfDocumentRegistryKeys.Synonym;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	HandlerNotifications = New CallbackDescription("CommandSaveAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(HandlerNotifications, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CommandWrite(Command)
	
	WriteScheduledJob();
	
EndProcedure

&AtClient
Procedure CommandSaveAndClose(Value = Undefined, AdditionalParameters = Undefined) Export
	
	WriteScheduledJob();
	Close(ScheduledJobID);
	
EndProcedure

&AtClient
Procedure SetUpSchedule(Command)
	
	HandlerNotifications = New CallbackDescription("SetUpScheduleCompletion", ThisObject);
	
	Dialog = New ScheduledJobDialog(Schedule);
	Dialog.Show(HandlerNotifications);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetScheduledJobData(ScheduledJobID)
	
	SearchParameters = New Structure;
	
	If ValueIsFilled(ScheduledJobID) Then
		
		SearchParameters.Insert("UUID",
			New UUID(ScheduledJobID));
		
	Else
		
		SearchParameters.Insert("Metadata",
			Metadata.ScheduledJobs.DeleteDuplicatesOfDocumentRegistryKeys);
		
	EndIf;
	
	SetPrivilegedMode(True);
	JobsSearch = ScheduledJobsServer.FindJobs(SearchParameters);
	SetPrivilegedMode(False);

	If JobsSearch.Count() > 0 Then
		ScheduledJobID = String(ScheduledJobsServer.UUID(JobsSearch.Get(0)));
	Else
		
		ScheduledJob = ScheduledJobsServer.AddJob(SearchParameters);
		ScheduledJobID = ScheduledJobsServer.UUID(ScheduledJob);
		
	EndIf;
	
	SetPrivilegedMode(True);
	Job = ScheduledJobsServer.Job(ScheduledJobID);
	SetPrivilegedMode(False);
	
	Result = New Structure(ScheduledJobParameters());
	FillPropertyValues(Result, Job);
	
	Return Result;
	
EndFunction

&AtClient
Procedure SetUpScheduleCompletion(Value, AdditionalParameters) Export
	
	If Value <> Undefined Then
		
		Schedule = Value;
		Modified = True;
		
		If DataSeparationEnabled
			And Schedule.RepeatPeriodInDay > 0
			And Schedule.RepeatPeriodInDay < 3600 Then
			
			Schedule.RepeatPeriodInDay = 3600;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteScheduledJob()
	
	SetPrivilegedMode(True);
	
	ChangeParameters = New Structure(ScheduledJobParameters());
	FillPropertyValues(ChangeParameters, ThisObject);
	
	ScheduledJobsServer.ChangeJob(ScheduledJobID, ChangeParameters);
	
	SetPrivilegedMode(False);
	
	Modified = False;
	
EndProcedure

&AtServer
Function ScheduledJobParameters()
	
	Return "Use, Schedule, RestartIntervalOnFailure, RestartCountOnFailure";
	
EndFunction

#EndRegion
