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
	
	ReadOnly = True;
	
	Items.FormCancelBackgroundJob.ExtendedTooltip.Title =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trực tiếp hủy nhiệm vụ nền trong dòng cập nhật truy cập ngay bây giờ.
			           |Những nhiệm vụ nền đang treo sẽ bị hủy tự động (%1 giây).
			           |Nhiệm vụ nền còn thiếu sẽ tự khởi chạy.';
			           |ru = 'Отменить фоновое задание потока обновления доступа прямо сейчас.
			           |Зависшие фоновые задания отменяются автоматически (%1 сек).
			           |Недостающее фоновое задание будет запущено автоматически.';
			           |en = 'Cancel the background job of the access update thread immediately.
			           |Background jobs that do not respond for %1 seconds are canceled automatically.
			           |The missing background job will be started automatically.'; fa = 'Cancel the background job of the access update thread immediately.
			           |Background jobs that do not respond for %1 seconds are canceled automatically.
			           |The missing background job will be started automatically.';
			           |it = 'Отменить фоновое задание потока обновления доступа прямо сейчас.
			           |Зависшие фоновые задания отменяются автоматически (%1 сек).
			           |Недостающее фоновое задание будет запущено автоматически.';
			           |pl = 'Cancel the background job of the access update thread immediately.
			           |Background jobs that do not respond for %1 seconds are canceled automatically.
			           |The missing background job will be started automatically.';
			           |tr = 'Erişim güncelleme iş akışı arka plan işini şimdi iptal edin.
			           |Askıda kalan arka plan işleri otomatik olarak iptal edilir (%1 saniye).
			           |Eksik arka plan işi otomatik olarak başlatılacaktır.'"),
			AccessManagementInternal.MaxWaitSecondsCountOfWaitingForOneJobInThreadToBeProcessed());
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

&AtClient
Procedure CancelBackgroundJob(Command)
	
	If Items.List.CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Hồ sơ không được tô sáng.';
								|ru = 'Запись не выделена.';
								|en = 'Please select a background job.'; fa = 'Please select a background job.';
								|it = 'Record non evidenziato.';
								|pl = 'Rekord nie jest podświetlony.';
								|tr = 'Kayıt seçilmedi.'"));
		Return;
	EndIf;
	
	ResultingText = "";
	CancelBackgroundJobAtServer(Items.List.CurrentData.ThreadID, ResultingText);
	
	ShowMessageBox(, ResultingText);
	
EndProcedure

&AtClient
Procedure AccessUpdateOnRecordsLevel(Command)
	
	AccessManagementInternalClient.OpenAccessUpdateOnRecordsLevelForm(, True);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure CancelBackgroundJobAtServer(JobID, ResultingText)
	
	BackgroundJob = BackgroundJobs.FindByUUID(JobID);
	
	If BackgroundJob = Undefined Then
		ResultingText = NStr("vi = 'Không xa xôi để tìm một nhiệm vụ nền bằng định danh.';
							|ru = 'Не удалость найти фоновое задание по идентификатору.';
							|en = 'Cannot find a background job by ID.'; fa = 'Cannot find a background job by ID.';
							|it = 'Non è stato possibile trovare il task in background per l''identificatore.';
							|pl = 'Nie można znaleźć zadania w tle według identyfikatora.';
							|tr = 'Belirtece göre arka plan görevi bulunamadı.'");
		Return;
	EndIf;
	
	Try
		BackgroundJob.Cancel();
		ResultingText = NStr("vi = 'Nhiệm vụ nền bị hủy bỏ.';
							|ru = 'Фоновое задание отменено.';
							|en = 'The background job is canceled.'; fa = 'The background job is canceled.';
							|it = 'Il task in background è annullato.';
							|pl = 'Anulowano zadanie w tle.';
							|tr = 'Arka plan görevi iptal edildi.'");
	Except
		ErrorInfo = ErrorInfo();
		ResultingText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể hủy nhiệm vụ nền vì lý do:
			           |%1';
			           |ru = 'Не удалось отменить фоновое задание по причине:
			           |%1';
			           |en = 'Cannot cancel the background job. Reason:
			           |%1'; fa = 'Cannot cancel the background job. Reason:
			           |%1';
			           |it = 'Non è stato possibile annullare il task in background a causa di:
			           |%1';
			           |pl = 'Nie udało się anulować zadania w tle z powodu:
			           |%1';
			           |tr = 'Bu nedenle arka plan görevi iptal edilemedi:
			           |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
EndProcedure

#EndRegion


