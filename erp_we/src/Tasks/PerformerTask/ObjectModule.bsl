///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	TaskWasExecuted = Common.ObjectAttributeValue(Ref, "Executed");
	If Executed And TaskWasExecuted <> True And Not AddressingAttributesAreFilled() Then
		
		Common.MessageToUser(
			NStr("vi = 'Hãy chỉ ra người thực hiện nhiệm vụ.';
				|ru = 'Укажите исполнителя задачи.';
				|en = 'Specify a task assignee.'; fa = 'Specify a task assignee.';
				|it = 'Indicare l''esecutore del compito.';
				|pl = 'Wskaż wykonawców zadania.';
				|tr = 'Görevi yürüteni belirtin.'"),,,
			"Object.Performer", Cancel);
		Return;
			
	EndIf;
	
	If TaskDueDate <> '00010101' And StartDate > TaskDueDate Then
		Common.MessageToUser(
			NStr("vi = 'Ngày bắt đầu thực hiện không được vượt quá thời hạn.';
				|ru = 'Дата начала исполнения не должна превышать крайний срок.';
				|en = 'Execution start date cannot be later than the deadline.'; fa = 'Execution start date cannot be later than the deadline.';
				|it = 'La data di inizio dell''esecuzione non deve superare quella di scadenza';
				|pl = 'Data rozpoczęcia wykonania nie może przekroczyć ostatniego terminu.';
				|tr = 'Uygulama başlangıç tarihi bitiş tarihinden ileri bir tarih olamaz.'"),,,
			"Object.StartDate", Cancel);
		Return;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Date = CurrentSessionDate();

EndProcedure


Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Ref.IsEmpty() Then
		InitialAttributes = Common.ObjectAttributesValues(Ref, 
			"Executed, DeletionMark, BusinessProcessState");
	Else
		InitialAttributes = New Structure(
			"Executed, DeletionMark, BusinessProcessState",
			False, False, Enums.BusinessProcessStates.EmptyRef());
	EndIf;
		
	If InitialAttributes.DeletionMark <> DeletionMark Then
		BusinessProcessesAndTasksServer.OnMarkTaskForDeletion(Ref, DeletionMark);
	EndIf;
	
	ThisIsTest = AdditionalProperties.Property("IsCheckOnly") And AdditionalProperties.IsCheckOnly;
	IsRedirection = AdditionalProperties.Property("Redirection1") And AdditionalProperties.Redirection1;
	
	If IsUserPerformer(Performer)
	   And Not ThisIsTest 
	   And Not IsRedirection Then
		
		UserDetails = Common.ObjectAttributesValues(Performer, "Invalid,DeletionMark");
		
		If UserDetails.Invalid 
		 Or UserDetails.DeletionMark Then
			Common.MessageToUser(NStr("vi = 'Một người dùng không hợp lệ đã được chọn làm người thực hiện nhiệm vụ.';
										|ru = 'Исполнителем задачи выбран недействительный пользователь.';
										|en = 'The task is assigned to an inactive user.'; fa = 'The task is assigned to an inactive user.';
										|it = 'The task is assigned to an inactive user.';
										|pl = 'The task is assigned to an inactive user.';
										|tr = 'Görev yöneticisi olarak geçersiz bir kullanıcı seçili.'"),,,, Cancel);
			Return; 
		EndIf;
		
	EndIf;
	
	If Not InitialAttributes.Executed And Executed Then
		
		If BusinessProcessState = Enums.BusinessProcessStates.Suspended Then
			Raise NStr("vi = 'Không nên thực hiện nhiệm vụ của quy trình nghiệp vụ đã dừng.';
						|ru = 'Нельзя выполнять задачи остановленных бизнес-процессов.';
						|en = 'Cannot perform tasks of suspended business processes.'; fa = 'Cannot perform tasks of suspended business processes.';
						|it = 'Gli obiettivi dei processi aziendali interrotti non devono essere eseguiti.';
						|pl = 'Nie można wykonywać zadań zatrzymanych procesów biznesowych.';
						|tr = 'Askıya alınan iş süreçlerinin görevleri gerçekleştirilemez.'");
		EndIf;
		
		// If the task is completed, write the user who completed it to the Performer attribute.
		// This is required for reporting purposes.
		// Write it only if the status in the infobase was incomplete
		// and has changed to complete in the object.
		If Not ValueIsFilled(Performer) Then
			Performer = Users.AuthorizedUser();
		EndIf;
		If CompletionDate = Date(1, 1, 1) Then
			CompletionDate = CurrentSessionDate();
		EndIf;
	ElsIf Not DeletionMark And InitialAttributes.Executed And Executed Then
			Common.MessageToUser(
				NStr("vi = 'Nhiệm vụ này đã được thực hiện từ trước.';
					|ru = 'Эта задача уже была выполнена ранее.';
					|en = 'This task is already completed.'; fa = 'This task is already completed.';
					|it = 'Questo obiettivo è stato già eseguito.';
					|pl = 'Zadanie to zostało już zakończone wcześniej.';
					|tr = 'Görev zaten tamamlandı.'"),,,, Cancel);
			Return;
	EndIf;
	
	If Importance.IsEmpty() Then
		Importance = Enums.TaskImportanceOptions.Ordinary;
	EndIf;
	
	If Not ValueIsFilled(BusinessProcessState) Then
		BusinessProcessState = Enums.BusinessProcessStates.Running;
	EndIf;
	
	SubjectString = Common.SubjectString(SubjectOf);
	
	If Not Ref.IsEmpty() And InitialAttributes.BusinessProcessState <> BusinessProcessState Then
		SetSubordinateBusinessProcessesState(BusinessProcessState);
	EndIf;
	
	If Executed And Not AcceptedForExecution Then
		AcceptedForExecution = True;
		AcceptForExecutionDate = CurrentSessionDate();
	EndIf;
	
	// StandardSubsystems.AccessManagement
	SetPrivilegedMode(True);
	TaskPerformersGroup = BusinessProcessesAndTasksServer.TaskPerformersGroup(PerformerRole, 
		MainAddressingObject, AdditionalAddressingObject);
	SetPrivilegedMode(False);
	// End StandardSubsystems.AccessManagement
	
	// Populate attribute AcceptForExecutionDate.
	If AcceptedForExecution And AcceptForExecutionDate = Date('00010101') Then
		AcceptForExecutionDate = CurrentSessionDate();
	EndIf;
	
	If ThisIsTest Then
		Executed = False;
	EndIf;
	
EndProcedure

Function IsUserPerformer(Performer)
	
	Return ValueIsFilled(Performer) 
	   And (TypeOf(Performer) = Type("CatalogRef.Users") 
	 Or TypeOf(Performer) = Type("CatalogRef.ExternalUsers"));
	
EndFunction

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("TaskObject.PerformerTask") Then
		FillPropertyValues(ThisObject, FillingData, 
			"BusinessProcess,RoutePoint,Description,Performer,PerformerRole,MainAddressingObject," 
			+ "AdditionalAddressingObject,Importance,CompletionDate,Author,LongDesc,TaskDueDate," 
			+ "StartDate,ExecutionResult,SubjectOf");
		Date = CurrentSessionDate();
	EndIf;
	If Not ValueIsFilled(Importance) Then
		Importance = Enums.TaskImportanceOptions.Ordinary;
	EndIf;
	
	If Not ValueIsFilled(BusinessProcessState) Then
		BusinessProcessState = Enums.BusinessProcessStates.Running;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetSubordinateBusinessProcessesState(NewState)
	
	BeginTransaction();
	Try
		SubordinateBusinessProcesses = BusinessProcessesAndTasksServer.MainTaskBusinessProcesses(Ref, True);
		For Each SubordinateBusinessProcess In SubordinateBusinessProcesses Do
			BusinessProcessObject = SubordinateBusinessProcess.GetObject();
			BusinessProcessObject.Lock();
			BusinessProcessObject.State = NewState;
			BusinessProcessObject.Write(); // ACC:1327 - A lock is set in BusinessProcessesAndTasksServer.MainTaskBusinessProcesses.
		EndDo;	
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Determines whether addressing attributes are filled in: assignee or business role
// 
// Returns:
//  Boolean - Returns True if an assignee or a business role is specified in the task.
//
Function AddressingAttributesAreFilled()
	
	Return ValueIsFilled(Performer) Or Not PerformerRole.IsEmpty();

EndFunction

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf