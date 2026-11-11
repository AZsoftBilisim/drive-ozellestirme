///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var JobActive;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	StorageAddress = PutToTempStorage(Undefined, New UUID);
	StateStorageAddress = PutToTempStorage(Undefined, New UUID);
	
	Items.Close.Enabled = Not Parameters.CheckMode;
	
	StartRequestsProcessing(
		Parameters.IDs,
		Parameters.EnablingMode,
		Parameters.DisablingMode,
		Parameters.RecoveryMode,
		Parameters.CheckMode);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	JobActive = True;
	CheckIteration = 1;
	AttachRequestsProcessingIdleHandler(3);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If JobActive Then
		CancelRequestsProcessing(JobID);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function StartRequestsProcessing(Val Queries, Val EnablingMode, DisablingMode, Val RecoveryMode, Val ApplicabilityCheckMode)
	
	JobDescription = NStr("vi = 'Xử lý yêu cầu sử dụng nguồn ngoài...';
							|ru = 'Обработка запросов на использование внешних ресурсов...';
							|en = 'Processing requests for external resources…'; fa = 'Processing requests for external resources…';
							|it = 'Elaborazione delle richieste per l''utilizzo delle risorse esterne...';
							|pl = 'Przetwarzanie zapytań na korzystanie z zasobów zewnętrznych...';
							|tr = 'Dış kaynakların kullanım istemlerinin işlenmesi'");
	
	If EnablingMode Then
		
		JobParameters = New Array();
		JobParameters.Add(StorageAddress);
		JobParameters.Add(StateStorageAddress);
		
		Job = BackgroundJobs.Execute("SafeModeManagerInternal.ExecuteUpdateRequestProcessing",
			JobParameters,, JobDescription);
		
	ElsIf DisablingMode Then
		
		JobParameters = New Array();
		JobParameters.Add(StorageAddress);
		JobParameters.Add(StateStorageAddress);
		
		Job = BackgroundJobs.Execute("SafeModeManagerInternal.ExecuteDisableRequestProcessing",
			JobParameters,, JobDescription);
		
	ElsIf RecoveryMode Then
		
		JobParameters = New Array();
		JobParameters.Add(StorageAddress);
		JobParameters.Add(StateStorageAddress);
		
		Job = BackgroundJobs.Execute("SafeModeManagerInternal.ExecuteRecoveryRequestProcessing",
			JobParameters,, JobDescription);
	Else
		
		JobParameters = New Array();
		JobParameters.Add(Queries);
		JobParameters.Add(StorageAddress);
		JobParameters.Add(StateStorageAddress);
		
		Job = BackgroundJobs.Execute("SafeModeManagerInternal.ExecuteRequestProcessing",
			JobParameters,, JobDescription);
	EndIf;
	
	JobID = Job.UUID;
	
	Return StorageAddress;
	
EndFunction

&AtClient
Procedure CheckRequestsProcessing()
	
	Try
		Readiness = RequestsProcessed(JobID);
	Except
		JobActive = False;
		Result = New Structure();
		Result.Insert("ReturnCode", DialogReturnCode.Cancel);
		Close(Result);
		Raise;
	EndTry;
	
	If Readiness Then
		JobActive = False;
		EndRequestsProcessing();
	Else
		
		CheckIteration = CheckIteration + 1;
		
		If CheckIteration = 2 Then
			AttachRequestsProcessingIdleHandler(5);
		ElsIf CheckIteration = 3 Then
			AttachRequestsProcessingIdleHandler(8);
		Else
			AttachRequestsProcessingIdleHandler(10);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function RequestsProcessed(Val JobID)
	
	Job = BackgroundJobs.FindByUUID(JobID);
	
	If Job <> Undefined
		And Job.State = BackgroundJobState.Active Then
		
		Return False;
	EndIf;
	
	If Job = Undefined Then
		Raise(NStr("vi = 'Tình huống bất thường khi xử lý truy vấn cho phép sử dụng nguồn ngoài.';
					|ru = 'Непредвиденная ситуация при обработке запросов разрешений на использование внешних ресурсов.';
					|en = 'An unexpected error occurred while processing permission requests to use external resources.'; fa = 'An unexpected error occurred while processing permission requests to use external resources.';
					|it = 'Непредвиденная ситуация при обработке запросов разрешений на использование внешних ресурсов.';
					|pl = 'An unexpected error occurred while processing permission requests to use external resources.';
					|tr = 'Harici kaynakların kullanımındaki çözüm isteklerinin işlenmesinde beklenmedik durum.'"));
	EndIf;
	
	If Job.State = BackgroundJobState.Failed Then
		JobError = Job.ErrorInfo;
		If JobError <> Undefined Then
			Raise(ErrorProcessing.DetailErrorDescription(JobError));
		Else
			Raise(NStr("vi = 'Không thể xử lý truy vấn cho phép sử dụng các nguồn ngoài.';
						|ru = 'Не удалось обработать запросы разрешений на использование внешних ресурсов.';
						|en = 'Cannot process permission requests to use external resources.'; fa = 'Cannot process permission requests to use external resources.';
						|it = 'Не удалось обработать запросы разрешений на использование внешних ресурсов.';
						|pl = 'Cannot process permission requests to use external resources.';
						|tr = 'Harici kaynak kullanımında çözüm istekleri işlenemedi.'"));
		EndIf;
	ElsIf Job.State = BackgroundJobState.Canceled Then
		Raise(NStr("vi = 'Không thể xử lý truy vấn cho phép sử dụng các nguồn ngoài, vì người quản trị đã hủy nhiệm vụ.';
					|ru = 'Не удалось обработать запросы разрешений на использование внешних ресурсов, т.к. задание было отменено администратором.';
					|en = 'Cannot process permission requests to use external resources as the administrator canceled the job.'; fa = 'Cannot process permission requests to use external resources as the administrator canceled the job.';
					|it = 'Не удалось обработать запросы разрешений на использование внешних ресурсов, т.к. задание было отменено администратором.';
					|pl = 'Cannot process permission requests to use external resources as the administrator canceled the job.';
					|tr = 'Harici kaynak kullanımında çözüm istekleri işlenemedi, çünkü görev yönetici tarafından iptal edildi.'"));
	Else
		JobID = Undefined;
		Return True;
	EndIf;
	
EndFunction

&AtClient
Procedure EndRequestsProcessing()
	
	JobActive = False;
	
	If IsOpen() Then
		
		Result = New Structure();
		Result.Insert("ReturnCode", DialogReturnCode.OK);
		Result.Insert("StateStorageAddress", StateStorageAddress);
		
		Close(Result);
		
	Else
		
		CallbackDescription = CallbackDescriptionOnClose;
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, DialogReturnCode.OK);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CancelRequestsProcessing(Val JobID)
	
	Job = BackgroundJobs.FindByUUID(JobID);
	
	If Job = Undefined Or Job.State <> BackgroundJobState.Active Then
		Return;
	EndIf;
	
	Try
		Job.Cancel();
	Except
		// The job might have been completed at that moment and no error occurred.
		WriteLogEvent(NStr("vi = 'Tùy chỉnh cho phép sử dụng các nguồn ngoài. Đã hủy thực hiện nhiệm vụ nền';
							|ru = 'Настройка разрешений на использование внешних ресурсов.Отмена выполнения фонового задания';
							|en = 'External resource permission setup.Cancel background job'; fa = 'External resource permission setup.Cancel background job';
							|it = 'Impostazione di concessione in utilizzo delle risorse esterne. Annullamento dell''esecuzione del task in background';
							|pl = 'Konfiguracja pozwoleń na korzystanie z zasobów zewnętrznych.Anulowanie wykonywania w tle zadania';
							|tr = 'Dış kaynakların kullanımına ilişkin izinlerin yapılandırılması. Fon görevinin yürütülmesi iptal edildi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtClient
Procedure AttachRequestsProcessingIdleHandler(Val Interval)
	
	AttachIdleHandler("CheckRequestsProcessing", Interval, True);
	
EndProcedure

#EndRegion