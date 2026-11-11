///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// It is called when changing data of business calendars.
//
Procedure PlanUpdateOfDataDependentOnBusinessCalendars(Val UpdateConditions) Export
	
	If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
		
		ModuleJobsQueue = Common.CommonModule("JobsQueue");
		
		MethodParameters = New Array;
		MethodParameters.Add(UpdateConditions);
		MethodParameters.Add(New UUID);

		JobParameters = New Structure;
		JobParameters.Insert("MethodName", "CalendarSchedulesInternal.UpdateDataDependentOnBusinessCalendars");
		JobParameters.Insert("Parameters", MethodParameters);
		JobParameters.Insert("RestartCountOnFailure", 3);
		JobParameters.Insert("DataArea", -1);
		
		SetPrivilegedMode(True);
		ModuleJobsQueue.AddJob(JobParameters);
		
	EndIf;

EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("CalendarSchedulesInternal.UpdateDataDependentOnBusinessCalendars");
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// The procedure for calling from a job queue. Add it to PlanUpdateOfDataDependentOnBusinessCalendars.
// 
// Parameters:
//  UpdateConditions - a ValueTable with schedule update conditions.
//  FileID - a file UUID of provided master data being processed.
//
Procedure UpdateDataDependentOnBusinessCalendars(Val UpdateConditions, Val FileID) Export
	
	If Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		
		ModuleSuppliedData = Common.CommonModule("SuppliedData");
		
		// Getting data areas to process.
		AreasForUpdate = ModuleSuppliedData.AreasRequiringProcessing(
			FileID, "BusinessCalendarsData");
			
		// Updating work schedules by data areas.
		DistributeBusinessCalendarsDataToDependentData(UpdateConditions, AreasForUpdate, 
			FileID, "BusinessCalendarsData");
			
	EndIf;
		
EndProcedure

// Fills in data that depends on business calendars according to the business calendar data for all data areas.
//
// Parameters:
//  UpdateConditions - ValueTable - a table with schedule update conditions.
//  AreasForUpdate - an array of area codes.
//  FileID - a file UUID of processed rates.
//  HandlerCode - String - a handler code.
//
Procedure DistributeBusinessCalendarsDataToDependentData(Val UpdateConditions, 
	Val AreasForUpdate, Val FileID, Val HandlerCode)
	
	If Not Common.SubsystemExists("CloudTechnology.Core")
		Or Not Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		Return;
	EndIf;
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	UpdateConditions.GroupBy("BusinessCalendarCode, Year");
	
	For Each DataArea In AreasForUpdate Do
		Try
			SetPrivilegedMode(True);
			ModuleSaaSOperations.SignInToDataArea(DataArea);
			SetPrivilegedMode(False);
		Except
			// If the exclusive mode is set to a data area, skip it.
			// Such data areas are inaccessible.
			SetPrivilegedMode(True);
			ModuleSaaSOperations.SignOutOfDataArea();
			SetPrivilegedMode(False);
			Continue;
		EndTry;
		BeginTransaction();
		Try
			CalendarSchedules.FillDataDependentOnBusinessCalendars(UpdateConditions);
			ModuleSuppliedData.AreaProcessed(FileID, HandlerCode, DataArea);
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteLogEvent(NStr("vi = 'Lịch biểu.Mở rộng lịch sản xuất';
								|ru = 'Календарные графики.Распространение производственных календарей';
								|en = 'Calendar schedules.Distribute business calendars'; fa = 'Calendar schedules.Distribute business calendars';
								|it = 'Calendario.Distribuzione dei calendari di produzione';
								|pl = 'Harmonogramy kalendarzowe.Rozpowszechnianie kalendarzy produkcyjnych';
								|tr = 'Takvim grafikler. Çalışma takvimlerinin yayılması'", Common.DefaultLanguageCode()),
									EventLogLevel.Error,,,
									ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		SetPrivilegedMode(True);
		ModuleSaaSOperations.SignOutOfDataArea();
		SetPrivilegedMode(False);
	EndDo;
	
EndProcedure

#EndRegion