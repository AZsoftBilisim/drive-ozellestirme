///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	SetPrivilegedMode(True);
	
	Schedule = New JobSchedule;
	Schedule.DaysRepeatPeriod = ?(Value, 1, 0);
	Schedule.RepeatPeriodInDay = ?(Value, 43200, 0);
	
	Filter = New Structure("Metadata", Metadata.ScheduledJobs.ProcessStateOfBonusPointsAndGiftCardsLoyaltyServer);
	CurrentJobs	= ScheduledJobsServer.FindJobs(Filter);
	
	If ValueIsFilled(CurrentJobs) Then
		
		JobParameters = New Structure;
		JobParameters.Insert("Use", Value);
		JobParameters.Insert("Schedule", Schedule);
		
		For Each CurrentJob In CurrentJobs Do
			
			ScheduledJobsServer.ChangeJob(CurrentJob, JobParameters);
			
		EndDo;
		
	Else
		
		JobParameters = New Structure;
		JobParameters.Insert("Use", Value);
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ProcessStateOfBonusPointsAndGiftCardsLoyaltyServer);
		JobParameters.Insert("Key", String(New UUID));
		JobParameters.Insert("Schedule", Schedule);
		
		ScheduledJobsServer.AddJob(JobParameters);
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf