#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Supervisor_ = Users.CurrentUser();
	Performer = Users.CurrentUser();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Closed_ Then
		
		// check filling in the fields
		If Supervisor_ <> Users.CurrentUser() Then
			CommonClientServer.MessageToUser(
			NStr("vi = 'Nhiệm vụ chưa đóng bởi vì bạn không phải là người quản trị';
				|ru = 'Задача не закрыта, так как Вы не являетесь ее куратором.';
				|en = 'The task is not closed as you are not its supervisor.'; fa = 'The task is not closed as you are not its supervisor.';
				|it = 'Il task non è chiuso, in quanto non si è il suo curatore.';
				|pl = 'Zadanie nie zostało zamknięte, ponieważ nie jesteś jego kuratorem.';
				|tr = 'Yöneticisi olmadığınız için görev kapatılmadı.'"),
			ThisObject,
			"Supervisor_",
			,
			Cancel);
		EndIf;	
		
		If ResultDetails = "" Then
			CommonClientServer.MessageToUser(
			NStr("vi = 'Nhiệm vụ chưa đóng bởi vì không có bản mô tả kết quả';
				|ru = 'Задача не закрыта, так как нет описания результата.';
				|en = 'Task is not closed, as there is no result description.'; fa = 'Task is not closed, as there is no result description.';
				|it = 'Il task non è chiuso, poiché non esiste una descrizione del risultato.';
				|pl = 'Zadanie nie zostało zamknięte, ponieważ brak opisu rezultatu.';
				|tr = 'Sonucun açıklaması olmadığı için görev kapatılmadı.'"),
			ThisObject,
			"ResultDetails",, Cancel);
		EndIf;	
		
		If StartDate = '00010101' Then
			CommonClientServer.MessageToUser(
			NStr("vi = 'Nhiệm vụ chưa đóng bởi vì chưa xác định ngày bắt đầu';
				|ru = 'Задача не закрыта, так не определена дата ее начала.';
				|en = 'The task is not closed as its start date is not determined.'; fa = 'The task is not closed as its start date is not determined.';
				|it = 'Il task non è chiuso, poiché la data del suo inizio non è determinata.';
				|pl = 'Zadanie nie zostało zamknięte, ponieważ nie określono daty jego rozpoczęcia.';
				|tr = 'Görev kapatılmadığından başlangıç ​​tarihi tanımlanmadı.'"),
			ThisObject,
			"StartDate",, Cancel);
		EndIf;
		
		If EndDate = '00010101' Then
			CommonClientServer.MessageToUser(
			NStr("vi = 'Nhiệm vụ không bị đóng, như vậy không xác định ngày kết thúc nhiệm vụ.';
				|ru = 'Задача не закрыта, так не определена дата ее окончания.';
				|en = 'The task is not closed as its end date is not determined.'; fa = 'The task is not closed as its end date is not determined.';
				|it = 'Il task non è chiuso, poiché la data del suo termine non è definita.';
				|pl = 'Zadanie nie ostało zamknięte, ponieważ nie określono daty jego zakończenia.';
				|tr = 'Görev kapatılmadığından tamamlanma tarihi tanımlanmadı.'"),
			ThisObject,
			"EndDate",, Cancel);
		EndIf;
		
		If Phase <> Enums.TaskPhases.Proved Then
			CommonClientServer.MessageToUser(
			NStr("vi = 'Nhiệm vụ chưa đóng bởi vì chưa kiểm tra';
				|ru = 'Задача не закрыта, так как не проверена.';
				|en = 'Task is not closed, as it is not checked.'; fa = 'Task is not closed, as it is not checked.';
				|it = 'Il task non è chiuso, poiché non è verificato.';
				|pl = 'Zadanie nie zostało zamknięte, ponieważ nie było zweryfikowane.';
				|tr = 'Kontrol edilmediği için görev kapatılmadı.'"),
			ThisObject,
			"Phase",, Cancel);
		EndIf;
		
		// set the end date
		If Not Cancel And (EndDate < StartDate) Then
			EndDate = CurrentSessionDate();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf