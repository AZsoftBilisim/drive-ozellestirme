
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetPrivilegedMode(True);
	Job = BackgroundJobs.FindByUUID(Parameters.JobID);
	If Job <> Undefined
		And StrStartsWith(Job.MethodName, "JobsQueue") Then
		Title = NStr("vi = 'Sao lưu dự phòng';
					|ru = 'Резервное копирование';
					|en = 'Backup'; fa = 'پشتیبان‌گیری';
					|it = 'Backup';
					|pl = 'Kopiowanie zapasowe';
					|tr = 'Yedek kopyalama'");
		Items.LabelDecoration.Title = 
			NStr("vi = 'Vui lòng đợi, đang sao lưu dự phòng, tạm thời không thể làm việc';
				|ru = 'Подождите, выполняется резервное копирование, работа временно невозможна';
				|en = 'Please wait, backup is in progress. Operations are temporarily unavailable'; fa = 'Please wait, backup is in progress. Operations are temporarily unavailable';
				|it = 'Attendere, backup in corso, impossibile continuare il lavoro';
				|pl = 'Czekaj, trwa kopiowanie zapasowe, praca jest czasowo niemożliwa ';
				|tr = 'Bekleyin, yedekleme gerçekleştiriliyor, geçici olarak iş yapılamıyor'");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("WaitHandler", 3);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If Not IsJobCompleted Then
		Cancel = True;
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WaitHandler()
	
	If Not TaskIsRunning(Parameters.JobID) Then
		DetachIdleHandler("WaitHandler");
		IsJobCompleted = True;
		Close();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function TaskIsRunning(JobID)
	SetPrivilegedMode(True);
	Job = BackgroundJobs.FindByUUID(JobID);
	Return Job <> Undefined And Job.State = BackgroundJobState.Active;
EndFunction

#EndRegion
