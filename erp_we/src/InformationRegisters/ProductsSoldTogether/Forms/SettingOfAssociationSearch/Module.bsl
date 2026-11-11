
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	AssociationSearchPeriodDescription = StrTemplate(NStr("vi = 'Theo dữ liệu trong kỳ: %1.';
															|ru = 'По данным за период: %1.';
															|en = 'According to data for the period:%1.'; fa = 'According to data for the period:%1.';
															|it = 'Secondo i dati per il periodo: %1.';
															|pl = 'Według danych za okres: %1.';
															|tr = 'Dönem verilerine göre: %1.'"),
		SupplyClientServer.SettingDetails(
			Constants.FrequencyForInventoryAnalysis,
			Constants.NumberOfPeriodsForItemsSoldTogetherAnalisys));
	
	If Common.DataSeparationEnabled() Then
	
		Items.SetUpSchedule.Visible = False;
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodOnChange(Item)
	
	AssociationSearchPeriodDescription = StrTemplate(NStr("vi = 'Theo dữ liệu trong kỳ: %1.';
															|ru = 'По данным за период: %1.';
															|en = 'According to data for the period:%1.'; fa = 'According to data for the period:%1.';
															|it = 'Secondo i dati per il periodo: %1.';
															|pl = 'Według danych za okres: %1.';
															|tr = 'Dönem verilerine göre: %1.'"),
		SupplyClientServer.SettingDetails(
			Constants.FrequencyForInventoryAnalysis,
			Constants.NumberOfPeriodsForItemsSoldTogetherAnalisys));
	
EndProcedure

&AtClient
Procedure NumberOfPeriodsOnChange(Item)
	
	AssociationSearchPeriodDescription = StrTemplate(NStr("vi = 'Theo dữ liệu trong kỳ: %1.';
															|ru = 'По данным за период: %1.';
															|en = 'According to data for the period:%1.'; fa = 'According to data for the period:%1.';
															|it = 'Secondo i dati per il periodo: %1.';
															|pl = 'Według danych za okres: %1.';
															|tr = 'Dönem verilerine göre: %1.'"),
		SupplyClientServer.SettingDetails(
			Constants.FrequencyForInventoryAnalysis,
			Constants.NumberOfPeriodsForItemsSoldTogetherAnalisys));

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// * Id - String - 
&AtClient
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("Id");
	Return Result;
	
EndFunction

&AtClient
Procedure SetUpSchedule(Command)
	
	Id = GetRoutineTaskID();
	
	Dialog = New ScheduledJobDialog(GetScheduleForRoutineTask(Id));
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.Id = Id;
	
	Dialog.Show(New CallbackDescription("SetUpScheduleCompletion", ThisObject, AdditionalParameters));
	
EndProcedure

// Parameters:
// 	Schedule - Undefined, JobSchedule -
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure SetUpScheduleCompletion(Schedule, AdditionalParameters) Export
	
	Id = AdditionalParameters.Id;
	
	If Schedule <> Undefined Then
		SetJobSchedule(Id, Schedule);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServerNoContext
Function GetRoutineTaskID()
	
	SetPrivilegedMode(True);
	Job = ScheduledJobsServer.Job(Metadata.ScheduledJobs.UpdateItemsSoldTogether);
	Return ScheduledJobsServer.UUID(Job);
	
EndFunction

&AtServerNoContext
Function SetJobSchedule(Id, Val Schedule)
	
	JobParameters = New Structure("Schedule", Schedule);
	ScheduledJobsServer.ChangeJob(Id, JobParameters);
	
EndFunction

&AtServerNoContext
Function GetScheduleForRoutineTask(Id)
	
	Job = ScheduledJobsServer.Job(Id);
	Return Job.Schedule;
	
EndFunction

#EndRegion

#EndRegion
