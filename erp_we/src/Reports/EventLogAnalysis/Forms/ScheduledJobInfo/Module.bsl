///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DetailsFromReport = Parameters.DetailsFromReport; // Array
	If DetailsFromReport <> Undefined Then
		Report = Reports.EventLogAnalysis.ScheduledJobDetails1(DetailsFromReport).Report;
		
		ScheduledJobName = DetailsFromReport.Get(1);
		EventDescription = DetailsFromReport.Get(2);
		Title = EventDescription;
		If ScheduledJobName <> "" Then
			NameOfEvent = StrReplace(ScheduledJobName, "ScheduledJob.", "");
			
			SetPrivilegedMode(True);
			FilterByScheduledJobs = New Structure;
			ScheduledJobMetadata = Metadata.ScheduledJobs.Find(NameOfEvent);
			If ScheduledJobMetadata <> Undefined Then
				FilterByScheduledJobs.Insert("Metadata", ScheduledJobMetadata);
				If EventDescription <> Undefined Then
					FilterByScheduledJobs.Insert("Description", EventDescription);
				EndIf;
				SchedJob = ScheduledJobsServer.FindJobs(FilterByScheduledJobs);
				If SchedJob.Count() = 0 And FilterByScheduledJobs.Property("Description") Then
					FilterByScheduledJobs.Delete("Description");
					SchedJob = ScheduledJobsServer.FindJobs(FilterByScheduledJobs);
				EndIf;
				If ValueIsFilled(SchedJob) Then
					ScheduledJobID = SchedJob[0].UUID;
				EndIf;
			EndIf;
			SetPrivilegedMode(False);
		EndIf;
	Else
		Report = Parameters.Report;
		ScheduledJobID = Parameters.ScheduledJobID;
		Title = Parameters.Title;
	EndIf;
	
	Items.ModifySchedule.Visible = Common.SubsystemExists("StandardSubsystems.ScheduledJobs");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportDetailProcessing(Item, Details, StandardProcessing)
	
	StandardProcessing = False;
	StartDate = Details.Get(0);
	EndDate = Details.Get(1);
	ScheduledJobSession.Clear();
	ScheduledJobSession.Add(Details.Get(2)); 
	EventLogFilter = New Structure("Session, StartDate, EndDate", 
		ScheduledJobSession, StartDate, EndDate);
	OpenForm("DataProcessor.EventLog.Form.EventLog", EventLogFilter);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConfigureJobSchedule(Command)
	
	If ValueIsFilled(ScheduledJobID) Then
		CallbackDescription = New CallbackDescription("ConfigureJobScheduleCompletion", ThisObject);
		Dialog = New ScheduledJobDialog(GetSchedule());
		Dialog.Show(CallbackDescription);
	Else
		ShowMessageBox(,NStr("vi = 'Không thể thay đổi lịch của nhiệm vụ thường kỳ: nhiệm vụ thường kỳ không tồn tại trong phiên bản này của ứng dụng.';
							|ru = 'Невозможно изменить расписание регламентного задания: регламентное задание не существует в этой версии приложения.';
							|en = 'Cannot change the job''s schedule: The scheduled job does not exist in this app version.'; fa = 'Cannot change the job''s schedule: The scheduled job does not exist in this app version.';
							|it = 'Невозможно изменить расписание регламентного задания: регламентное задание не существует в этой версии приложения.';
							|pl = 'Cannot change the job''s schedule: The scheduled job does not exist in this app version.';
							|tr = 'Planlanmış iş programını değiştirmek mümkün değil: zamanlanmış görev, uygulamanın bu sürümünde mevcut değil'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToEventLogCommand(Command)
	
	SelectedAreas = Items.Report.GetSelectedAreas();
	For Each Area In SelectedAreas Do
		If Area.AreaType = SpreadsheetDocumentCellAreaType.Rectangle Then
			Details = Area.Details;
		Else
			Details = Undefined;
		EndIf;
		If Details = Undefined
			Or Area.Top <> Area.Bottom Then
			ShowMessageBox(,NStr("vi = 'Hãy chọn dòng hoặc ô của phiên nhiệm vụ cần thiết';
								|ru = 'Выберите строку или ячейку нужного сеанса задания';
								|en = 'Select the job session line or cell.'; fa = 'Select the job session line or cell.';
								|it = 'Seleziona la riga o la cella della sessione di lavoro desiderata.';
								|pl = 'Wybierz wiersz lub komórkę wymaganej sesji zadania';
								|tr = 'Gerekli iş oturumunun bir satırını veya hücresini seçin'"));
			Return;
		EndIf;
		StartDate = Details.Get(0);
		EndDate = Details.Get(1);
		ScheduledJobSession.Clear();
		ScheduledJobSession.Add(Details.Get(2));
		
		UniqueKey = String(StartDate) + "-" + EndDate + "-" + Details.Get(2);
		EventLogFilter = New Structure("Session, StartDate, EndDate", ScheduledJobSession, StartDate, EndDate);
		OpenForm("DataProcessor.EventLog.Form.EventLog", EventLogFilter, , UniqueKey);
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetSchedule()
	
	SetPrivilegedMode(True);
	
	ModuleScheduledJobsServer = Common.CommonModule("ScheduledJobsServer");
	Return ModuleScheduledJobsServer.JobSchedule(ScheduledJobID);
	
EndFunction

&AtClient
Procedure ConfigureJobScheduleCompletion(Schedule, AdditionalParameters) Export
	
	If Schedule <> Undefined Then
		SetJobSchedule(Schedule);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetJobSchedule(Schedule)
	
	SetPrivilegedMode(True);
	
	JobParameters = New Structure;
	JobParameters.Insert("Schedule", Schedule);
	ModuleScheduledJobsServer = Common.CommonModule("ScheduledJobsServer");
	ModuleScheduledJobsServer.ChangeJob(ScheduledJobID, JobParameters);
	
EndProcedure

#EndRegion
