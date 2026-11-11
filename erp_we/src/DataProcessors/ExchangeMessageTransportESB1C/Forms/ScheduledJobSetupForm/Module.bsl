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
	
	If Not Parameters.Property("Id") Then
				
		MessageText = NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
							|ru = 'Эта форма не предназначена для непосредственного открытия.';
							|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
							|it = 'Эта форма не предназначена для непосредственного открытия.';
							|pl = 'This is a dependent form and opens from a different form.';
							|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'");
		Common.MessageToUser(MessageText, , , , Cancel);
		
		Return;
		
	EndIf;
	
	Parameters.Property("Id", ScheduledJobID);
	
	Filter = New Structure;
	Filter.Insert("UUID", New UUID(ScheduledJobID));
	
	SetPrivilegedMode(True);
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	
	Job = Jobs[0];
	
	UseScheduledJob = Job.Use;
	Schedule = Job.Schedule;

	Items.ConfigureJobSchedule.Title = String(Schedule);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseScheduledJobOnChange(Item)
	
	SetScheduledJobParameters();
	
EndProcedure

&AtClient
Procedure ConfigureJobSchedule(Command)
	
	Dialog = New ScheduledJobDialog(Schedule);
	
	// Opening a dialog box for editing the schedule.
	CallbackDescription = New CallbackDescription("ConfigureJobScheduleCompletion", ThisObject);
	Dialog.Show(CallbackDescription);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetScheduledJobParameters()
	
	Filter = New Structure;
	Filter.Insert("UUID", New UUID(ScheduledJobID));
	
	SetPrivilegedMode(True);
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	
	Job = Jobs[0];
	Job.Use = UseScheduledJob;
	Job.Schedule = Schedule;
	
	Try
		
		Job.Write();
		
	Except
		
		Template = NStr("vi = 'Đã xảy ra lỗi khi lưu lại lịch biểu thực hiện trao đổi. Chi tiết lỗi: %1';
						|ru = 'Произошла ошибка при сохранении расписания выполнения обменов. Подробное описание ошибки: %1';
						|en = 'Couldn''t save the exchange schedule. Error details: %1'; fa = 'Couldn''t save the exchange schedule. Error details: %1';
						|it = 'Si è verificato un errore durante il salvataggio del grafico degli scambi. Descrizione completa dell''errore: %1';
						|pl = 'Podczas zapisywania harmonogramu wykonywania wymiany zaistniał błąd. Szczegółowy opis błędu: %1';
						|tr = 'Bozdurma takvimini kaydederken bir hata oluştu. Hata açıklaması: %1'");
		MessageString = StrTemplate(Template, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
		Common.MessageToUser(MessageString);
		
	EndTry;
	
EndProcedure

&AtClient
Procedure ConfigureJobScheduleCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		
		Return;
		
	EndIf;
	
	Schedule = Result;
	
	Items.ConfigureJobSchedule.Title = String(Schedule);
	
	SetScheduledJobParameters();
	
EndProcedure

#EndRegion


