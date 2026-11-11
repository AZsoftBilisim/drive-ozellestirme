///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure OnChangeRetainReportDistributionHistory() Export
	
	If GetFunctionalOption("RetainReportDistributionHistory") Then
		// Every day; every 1800 seconds
		Schedule = New JobSchedule;
		Schedule.DaysRepeatPeriod = 1;
		Schedule.RepeatPeriodInDay = 1800; 
		SetScheduledJobUsage(Metadata.ScheduledJobs.GetStatusesOfEmailMessages, True, Schedule);
		// Every day; from 2:00:00 once a day, finish after 5:00:00
		Schedule = New JobSchedule;
		Schedule.DaysRepeatPeriod = 1;
		Schedule.BeginTime = '00010101020000';
		Schedule.EndTime = '00010101050000';
		SetScheduledJobUsage(Metadata.ScheduledJobs.ReportDistributionHistoryClearUp, True, Schedule);
	Else
		SetScheduledJobUsage(Metadata.ScheduledJobs.ReportDistributionHistoryClearUp, False);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// For internal use.
//
// Parameters:
//   RecipientsParameters - Structure
//
// Returns:
//   Structure:
//     * Recipients - Map
//     * HadCriticalErrors - Boolean
//     * Text - String
//     * More - String
//
Function GenerateMailingRecipientsList(Val RecipientsParameters) Export
	LogParameters = New Structure("EventName, Metadata, Data, ErrorsArray, HadErrors");
	LogParameters.EventName   = NStr("vi = 'Gửi báo cáo hàng loạt. Tạo danh sách người nhận';
									|ru = 'Рассылка отчетов. Формирование списка получателей';
									|en = 'Report distribution. Generating recipient list'; fa = 'Report distribution. Generating recipient list';
									|it = 'Invio massivo dei report. Formazione dell''elenco dei destinatari';
									|pl = 'Wysyłka raportów. Tworzenie listy odbiorców';
									|tr = 'Rapor dağıtımı. Alıcı listesi düzenle'", Common.DefaultLanguageCode());
	LogParameters.ErrorsArray = New Array;
	LogParameters.HadErrors   = False;
	LogParameters.Data       = RecipientsParameters.Ref;
	LogParameters.Metadata   = Metadata.Catalogs.ReportMailings;
	
	ExecutionResult = New Structure("Recipients, HadCriticalErrors, Text, More");
	ExecutionResult.Recipients = ReportMailing.GenerateMailingRecipientsList(RecipientsParameters, LogParameters);
	ExecutionResult.HadCriticalErrors = ExecutionResult.Recipients.Count() = 0;
	
	If ExecutionResult.HadCriticalErrors Then
		ExecutionResult.Text = ReportMailing.MessagesToUserString(LogParameters.ErrorsArray, False);
	EndIf;
	
	Return ExecutionResult;
EndFunction

// Runs background job.
Function RunBackgroundJob1(Val MethodParameters, Val UUID) Export
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Gửi báo cáo hàng loạt: Thực hiện gửi hàng loạt trong nền';
													|ru = 'Рассылки отчетов: Выполнение рассылок в фоне';
													|en = 'Report distribution. Running in the background'; fa = 'Report distribution. Running in the background';
													|it = 'Invio massivo dei report: Esecuzione dell''invio massivo dei report in background';
													|pl = 'Wysyłki raportów: Wykonywanie wysyłek w tle';
													|tr = 'Rapor dağıtımları: Arka planda çalışıyor'");
	StartSettings1.RefinementErrors = NStr("vi = 'Không thể thực hiện gửi báo cáo theo nguyên nhân:';
											|ru = 'Не удалось выполнить рассылки отчетов по причине:';
											|en = 'Report distributions failed due to:'; fa = 'Report distributions failed due to:';
											|it = 'Не удалось выполнить рассылки отчетов по причине:';
											|pl = 'Report distributions failed due to:';
											|tr = 'Raporlar şu sebeple gönderilemiyor:'");
	
	Return TimeConsumingOperations.ExecuteInBackground("ReportMailing.SendBulkEmailsInBackgroundJob",
		MethodParameters, StartSettings1);
	
EndFunction

// Starts the background job that sends out text messages with archive passwords (required for opening the attachments).
Function RunBackgroundJobToSendSMSWithPasswords(Val MethodParameters, Val UUID) Export
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Gửi báo cáo hàng loạt: Gửi hàng loạt SMS có mật khẩu trong nền';
													|ru = 'Рассылки отчетов: Выполнение SMS-рассылок с паролями в фоне';
													|en = 'Report distributions: Send text messages with passwords in the background'; fa = 'Report distributions: Send text messages with passwords in the background';
													|it = 'Рассылки отчетов: Выполнение SMS-рассылок с паролями в фоне';
													|pl = 'Report distributions: Send text messages with passwords in the background';
													|tr = 'Rapor dağıtımları: Parolayla SMS dağıtımı arka planda çalışıyor'");
	StartSettings1.RefinementErrors =
		NStr("vi = 'Không thể gửi SMS hàng loạt có mật khẩu để nhận gửi báo cáo theo nguyên nhân:';
			|ru = 'Не удалось выполнить SMS-рассылку с паролями для получения рассылки отчетов по причине:';
			|en = 'Cannot send text messages with archive passwords to receive the report distribution. Reason:'; fa = 'Cannot send text messages with archive passwords to receive the report distribution. Reason:';
			|it = 'Не удалось выполнить SMS-рассылку с паролями для получения рассылки отчетов по причине:';
			|pl = 'Cannot send text messages with archive passwords to receive the report distribution. Reason:';
			|tr = 'Rapor dağıtımının alınması için şifreli SMS dağıtımı gerçekleştirilemiyor.'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"ReportMailing.SendBulkSMSMessagesWithReportDistributionArchivePasswordsInBackgroundJob",
		MethodParameters,
		StartSettings1);
	
EndFunction

// Starts the background job that purges the report distribution history.
Function RunBackgroundJobToClearUpReportDistributionHistory(Val MethodParameters, Val UUID) Export
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Gửi báo cáo hàng loạt: Xóa lịch sử gửi báo cáo hàng loạt';
													|ru = 'Рассылки отчетов: Очистка истории рассылки отчетов';
													|en = 'Report distributions: Clear the report distribution history'; fa = 'Report distributions: Clear the report distribution history';
													|it = 'Рассылки отчетов: Очистка истории рассылки отчетов';
													|pl = 'Report distributions: Clear the report distribution history';
													|tr = 'Rapor dağıtımları: Rapor dağıtım geçmişini temizle'");
	StartSettings1.RefinementErrors =
		NStr("vi = 'Không thể xóa lịch sử gửi báo cáo theo nguyên nhân:';
			|ru = 'Не удалось выполнить очистку истории рассылки отчетов по причине:';
			|en = 'Cleanup of report distributions failed due to:'; fa = 'Cleanup of report distributions failed due to:';
			|it = 'Не удалось выполнить очистку истории рассылки отчетов по причине:';
			|pl = 'Cleanup of report distributions failed due to:';
			|tr = 'Rapor dağıtımı geçmişinin temizlenmesi gerçekleştirilemedi.'");
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"ReportMailing.ClearUpReportDistributionHistoryInBackgroundJob",
		MethodParameters,
		StartSettings1);
	
EndFunction

Procedure SetScheduledJobUsage(MetadataJob1, Use, Schedule = Undefined)
	
	JobParameters = New Structure;
	JobParameters.Insert("Metadata", MetadataJob1);
	
	SetPrivilegedMode(True);
	
	JobsList = ScheduledJobsServer.FindJobs(JobParameters);
	If JobsList.Count() = 0 Then
		JobParameters = New Structure;
		JobParameters.Insert("Use", Use);
		JobParameters.Insert("Metadata", MetadataJob1);
		If Schedule <> Undefined Then
			JobParameters.Insert("Schedule", Schedule);
		EndIf;
		ScheduledJobsServer.AddJob(JobParameters);
	Else
		JobParameters = New Structure("Use", Use);
		For Each Job In JobsList Do
			ScheduledJobsServer.ChangeJob(Job, JobParameters);
		EndDo;
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion
