///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Table - See AccessManagement.AccessValuesSetsTable
//
Procedure FillAccessValuesSets(Table) Export

	BusinessProcessesAndTasksOverridable.OnFillingAccessValuesSets(ThisObject, Table);

	If Table.Count() > 0 Then
		Return;
	EndIf;

	FillDefaultAccessValuesSets(Table);

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

#Region BusinessProcessEventHandlers

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	If Author <> Undefined And Not Author.IsEmpty() Then
		AuthorAsString = String(Author);
	EndIf;

	BusinessProcessesAndTasksServer.ValidateRightsToChangeBusinessProcessState(ThisObject);

	If ValueIsFilled(MainTask) 
		And Common.ObjectAttributeValue(MainTask, "BusinessProcess") = Ref Then

		Raise NStr("vi = 'Không thể chỉ định nhiệm vụ riêng của quy trình nghiệp vụ là nhiệm vụ chính.';
					|ru = 'Собственная задача бизнес-процесса не может быть указана как главная задача.';
					|en = 'A task that belongs to the duty cannot be specified as the main task.'; fa = 'A task that belongs to the duty cannot be specified as the main task.';
					|it = 'Il proprio obiettivo del processo aziendale non può essere indicato come obiettivo principale.';
					|pl = 'Zadanie własne procesu biznesowego nie może być określone jako główne zadanie.';
					|tr = 'İş süreci görevi ana görev olarak belirlenemez.'");

	EndIf;

	SetPrivilegedMode(True);
	TaskPerformersGroup = ?(TypeOf(Performer) = Type("CatalogRef.PerformerRoles"),
		BusinessProcessesAndTasksServer.TaskPerformersGroup(Performer, MainAddressingObject,
			AdditionalAddressingObject), Performer);
	TaskPerformersGroupSupervisor = ?(TypeOf(Supervisor) = Type("CatalogRef.PerformerRoles"),
		BusinessProcessesAndTasksServer.TaskPerformersGroup(Supervisor, MainAddressingObjectSupervisor,
			AdditionalAddressingObjectSupervisor), Supervisor);
	SetPrivilegedMode(False);

	If Not IsNew() And Common.ObjectAttributeValue(Ref, "SubjectOf") <> SubjectOf Then
		ChangeTaskSubject();
	EndIf;

EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)

	If IsNew() Then
		Author = Users.AuthorizedUser();
		Supervisor = Users.AuthorizedUser();
		If TypeOf(FillingData) = Type("CatalogRef.Users") Then
			Performer = FillingData;
		Else
			// For auto completion in a blank Assignee field.
			Performer = Catalogs.Users.EmptyRef();
		EndIf;
	EndIf;

	If FillingData <> Undefined And TypeOf(FillingData) <> Type("Structure") 
		And FillingData <> Tasks.PerformerTask.EmptyRef() Then

		If TypeOf(FillingData) <> Type("TaskRef.PerformerTask") Then
			SubjectOf = FillingData;
		Else
			SubjectOf = Common.ObjectAttributeValue(FillingData, "SubjectOf");
		EndIf;

	EndIf;

	BusinessProcessesAndTasksServer.FillMainTask(ThisObject, FillingData);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	NotCheckedAttributeArray = New Array;
	If Not OnValidation Then
		NotCheckedAttributeArray.Add("Supervisor");
	EndIf;
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
EndProcedure

Procedure OnCopy(CopiedObject)

	IterationNumber = 0;
	Completed2 = False;
	Accepted = False;
	ExecutionResult = "";
	CompletedOn = '00010101000000';
	State = Enums.BusinessProcessStates.Running;

EndProcedure

#EndRegion

#Region RouteMapItemsEventHandlers

// Parameters:
//   BusinessProcessRoutePoint - BusinessProcessRoutePointRef.Job
//   TasksBeingFormed - Array of TaskObject
//   Cancel - Boolean
// 
Procedure ExecuteOnCreateTask(BusinessProcessRoutePoint, TasksBeingFormed, Cancel)

	IterationNumber = IterationNumber + 1;
	Write();
	
	// Setting the addressing attributes and additional attributes for each task.
	For Each Task In TasksBeingFormed Do

		Task.Author = Author;
		Task.AuthorAsString = String(Author);
		If TypeOf(Performer) = Type("CatalogRef.PerformerRoles") Then
			Task.PerformerRole = Performer;
			Task.MainAddressingObject = MainAddressingObject;
			Task.AdditionalAddressingObject = AdditionalAddressingObject;
			Task.Performer = Undefined;
		Else
			Task.Performer = Performer;
		EndIf;
		Task.Description = TaskDescriptionForExecution();
		Task.TaskDueDate = TaskDueDateForExecution();
		Task.Importance = Importance;
		Task.SubjectOf = SubjectOf;

	EndDo;

EndProcedure

Procedure ExecuteBeforeCreateTasks(BusinessProcessRoutePoint, TasksBeingFormed, StandardProcessing)

	If SubjectOf = Undefined Or SubjectOf.IsEmpty() Then
		Return;
	EndIf;

EndProcedure

Procedure ExecuteOnExecute(BusinessProcessRoutePoint, Task, Cancel)

	ExecutionResult = CompletePointExecutionResult(Task) + ExecutionResult;
	Write();

EndProcedure
// Parameters:
//  BusinessProcessRoutePoint - BusinessProcessRoutePointRef.Job
//  TasksBeingFormed - Array of TaskObject
//  Cancel - Boolean
// 
Procedure ValidateOnCreateTask(BusinessProcessRoutePoint, TasksBeingFormed, Cancel)

	If Supervisor.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf;
	
	// Setting the addressing attributes and additional attributes for each task.
	For Each Task In TasksBeingFormed Do

		Task.Author = Author;
		If TypeOf(Supervisor) = Type("CatalogRef.PerformerRoles") Then
			Task.PerformerRole = Supervisor;
			Task.MainAddressingObject = MainAddressingObjectSupervisor;
			Task.AdditionalAddressingObject = AdditionalAddressingObjectSupervisor;
		Else
			Task.Performer = Supervisor;
		EndIf;

		Task.Description = TaskDescriptionForCheck();
		Task.TaskDueDate = TaskDueDateForCheck();
		Task.Importance = Importance;
		Task.SubjectOf = SubjectOf;

	EndDo;

EndProcedure

Procedure ValidateOnExecute(BusinessProcessRoutePoint, Task, Cancel)

	ExecutionResult = ValidatePointExecutionResult(Task) + ExecutionResult;
	Write();

EndProcedure

Procedure CheckRequiredConditionCheck(BusinessProcessRoutePoint, Result)

	Result = OnValidation;

EndProcedure

Procedure ReturnToPerformerConditionCheck(BusinessProcessRoutePoint, Result)

	Result = Not Accepted;

EndProcedure

Procedure EndOnComplete(BusinessProcessRoutePoint, Cancel)

	CompletedOn = BusinessProcessesAndTasksServer.BusinessProcessCompletionDate(Ref);
	Write();

EndProcedure

#EndRegion

#EndRegion

#Region Private

// Updates attribute values of uncompleted tasks 
// according to the Job business process attributes:
//   Importance, TaskDueDate, Description, and Author.
//
Procedure ChangeUncompletedTasksAttributes() Export

	Block = New DataLock;
	LockItem = Block.Add("Task.PerformerTask");
	LockItem.SetValue("BusinessProcess", Ref);

	Query = New Query("SELECT
	  |	PerformerTasks.Ref AS Ref
	  |FROM
	  |	Task.PerformerTask AS PerformerTasks
	  |WHERE
	  |	PerformerTasks.BusinessProcess = &BusinessProcess
	  |	AND PerformerTasks.DeletionMark = FALSE
	  |	AND PerformerTasks.Executed = FALSE");
	Query.SetParameter("BusinessProcess", Ref);

	BeginTransaction();
	Try
		Block.Lock();
		SelectionDetailRecords = Query.Execute().Select();

		While SelectionDetailRecords.Next() Do
			TaskObject = SelectionDetailRecords.Ref.GetObject(); // TaskObject
			TaskObject.Importance = Importance;
			TaskObject.TaskDueDate = ?(TaskObject.RoutePoint = BusinessProcesses.Job.RoutePoints.Execute,
				TaskDueDateForExecution(), TaskDueDateForCheck());
			TaskObject.Description = ?(TaskObject.RoutePoint = BusinessProcesses.Job.RoutePoints.Execute,
				TaskDescriptionForExecution(), TaskDescriptionForCheck());
			TaskObject.Author = Author;
			// Don't check for the preliminary data edit lock:
			// this change has a higher priority than the opened task forms.
			TaskObject.Write();
		EndDo;

		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

Procedure ChangeTaskSubject()

	Block = New DataLock;
	LockItem = Block.Add("Task.PerformerTask");
	LockItem.SetValue("BusinessProcess", Ref);

	Query = New Query("SELECT
	  |	PerformerTasks.Ref AS Ref
	  |FROM
	  |	Task.PerformerTask AS PerformerTasks
	  |WHERE
	  |	PerformerTasks.BusinessProcess = &BusinessProcess");

	Query.SetParameter("BusinessProcess", Ref);

	SetPrivilegedMode(True);
	BeginTransaction();
	Try
		Block.Lock();
		SelectionDetailRecords = Query.Execute().Select();

		While SelectionDetailRecords.Next() Do
			TaskObject = SelectionDetailRecords.Ref.GetObject(); // TaskObject
			TaskObject.SubjectOf = SubjectOf;
			// Don't check for the preliminary data edit lock:
			// this change has a higher priority than the opened task forms.
			TaskObject.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

Function TaskDescriptionForExecution()

	Return Description;

EndFunction

Function TaskDueDateForExecution()

	Return TaskDueDate;

EndFunction

Function TaskDescriptionForCheck()

	TaskDescription = NStr("vi = 'Kiểm tra';
							|ru = 'Проверить';
							|en = 'Check'; fa = 'چک';
							|it = 'Verificare';
							|pl = 'Zweryfikuj';
							|tr = 'Kontrol et'");
	Return ?(IsBlankString(TaskDescription), "", TaskDescription + ": ") + Description;

EndFunction

Function TaskDueDateForCheck()

	Return VerificationDueDate;

EndFunction

Function CompletePointExecutionResult(Val TaskRef)

	TaskData = Common.ObjectAttributesValues(TaskRef,
		"ExecutionResult,CompletionDate,Performer,Executed");
		
	PerformerIsCurrentUser = Users.CurrentUser() = TaskData.Performer;

	If TaskData.Executed Then
		If PerformerIsCurrentUser Then
			StringFormat = NStr("vi = '%1, %2 đã thực hiện nhiệm vụ:
				|%3';
				|ru = '%1, %2 выполнил(а) задачу:
				|%3';
				|en = '%1, %2 completed the task:
				|%3'; fa = '%1, %2 completed the task:
				|%3';
				|it = '%1, %2 ha eseguito il compito:
				|%3';
				|pl = '%1, %2 wykonał(a) zadanie:
				|%3';
				|tr = '%1, %2 görevi tamamladı:
				|%3'") + Chars.LF;
		Else
			StringFormat = NStr("vi = '%1, %4 (người thực hiện đã được chỉ định %2) người thực hiện nhiệm vụ:
				|%3';
				|ru = '%1, %4 (исполнителем назначен %2) выполнил(а) задачу:
				|%3';
				|en = '%1, %4 (assigned to %2) completed the task:
				|%3'; fa = '%1, %4 (assigned to %2) completed the task:
				|%3';
				|it = '%1, %4 (assigned to %2) completed the task:
				|%3';
				|pl = '%1, %4 (assigned to %2) completed the task:
				|%3';
				|tr = '%1, %4 (%2 yürütücü olarak atandı) görevi tamamladı:
				|%3'") + Chars.LF;
		EndIf;
	Else
		If PerformerIsCurrentUser Then
			StringFormat = NStr("vi = '%1, %2 đã từ chối nhiệm vụ:
				|%3';
				|ru = '%1, %2 отклонил(а) задачу:
				|%3';
				|en = '%1, %2 rejected the task:
				|%3'; fa = '%1, %2 rejected the task:
				|%3';
				|it = '%1, %2 ha rifiutato il compito:
				|%3';
				|pl = '%1, %2 odrzucił(a) zadanie:
				|%3';
				|tr = '%1, %2 görevi reddetti:
				|%3'") + Chars.LF;
		Else
			StringFormat = NStr("vi = '%1, %4 (người thực hiện đã được chỉ định %2) người từ chối nhiệm vụ:
				|%3';
				|ru = '%1, %4 (исполнителем назначен %2) отклонил(а) задачу:
				|%3';
				|en = '%1, %4 (assigned to %2) rejected the task:
				|%3'; fa = '%1, %4 (assigned to %2) rejected the task:
				|%3';
				|it = '%1, %4 (assigned to %2) rejected the task:
				|%3';
				|pl = '%1, %4 (assigned to %2) rejected the task:
				|%3';
				|tr = '%1, %4 (%2 yürütücü olarak atandı) görevi reddetti:
				|%3'") + Chars.LF;
		EndIf;
	EndIf;

	Comment = TrimAll(TaskData.ExecutionResult);
	Comment = ?(IsBlankString(Comment), "", Comment + Chars.LF);
	
	Result = StringFunctionsClientServer.SubstituteParametersToString(StringFormat, TaskData.CompletionDate,
		TaskData.Performer, Comment, Users.CurrentUser());
	Return Result;

EndFunction

Function ValidatePointExecutionResult(Val TaskRef)
	
	TaskData = Common.ObjectAttributesValues(TaskRef,
		"ExecutionResult,CompletionDate,Performer");
	
	PerformerIsCurrentUser = Users.CurrentUser() = TaskData.Performer;
	
	If Not Accepted Then
		If PerformerIsCurrentUser Then
			StringFormat = NStr("vi = '%1, %2 đã trả lại nhiệm vụ để hoàn thiện:
									  |%3';
									  |ru = '%1, %2 вернул(а) задачу на доработку:
									  |%3';
									  |en = '%1, %2 sent the task back for revision:
									  |%3'; fa = '%1, %2 sent the task back for revision:
									  |%3';
									  |it = '%1, %2 ha reso il compito in rielaborazione:
									  |%3';
									  |pl = '%1, %2 zwrócił(a) zadanie do dopracowania:
									  |%3';
									  |tr = '%1, %2 görevi tekrar revizyona gönderdi:
									  |%3'") + Chars.LF;
		Else
			StringFormat = NStr("vi = '%1, %4 (người kiểm tra đã được chỉ định %2) người trả lại nhiệm vụ để hoàn thiện:
									  |%3';
									  |ru = '%1, %4 (проверяющим назначен %2) вернул(а) задачу на доработку:
									  |%3';
									  |en = '%1, %4 (%2 is appointed as a supervisor) sent task back for revision:
									  |%3'; fa = '%1, %4 (%2 is appointed as a supervisor) sent task back for revision:
									  |%3';
									  |it = '%1, %4 (%2 is appointed as a supervisor) sent task back for revision:
									  |%3';
									  |pl = '%1, %4 (%2 is appointed as a supervisor) sent task back for revision:
									  |%3';
									  |tr = '%1, %4 (%2 denetmen olarak atandı) görevi revizyona gönderdi:
									  |%3'") + Chars.LF;
		EndIf;
	Else
		If Completed2 Then
			If PerformerIsCurrentUser Then
				StringFormat = NStr("vi = '%1, %2 đã xác nhận thực hiện nhiệm vụ:
										  |%3';
										  |ru = '%1, %2 подтвердил(а) выполнение задачи:
										  |%3';
										  |en = '%1, %2 confirmed task completion:
										  |%3'; fa = '%1, %2 confirmed task completion:
										  |%3';
										  |it = '%1, %2 ha confermato l''esecuzione del compito:
										  |%3';
										  |pl = '%1, %2 potwierdził(a) wykonanie zadania:
										  |%3';
										  |tr = '%1, %2 görevin tamamlandığını doğruladı:
										  |%3'") + Chars.LF;
			Else
				StringFormat = NStr("vi = '%1, %4 (người kiểm tra đã được chỉ định %2) người xác nhận thực hiện nhiệm vụ:
										  |%3';
										  |ru = '%1, %4 (проверяющим назначен %2) подтвердил(а) выполнение задачи:
										  |%3';
										  |en = '%1, %4 (%2 is appointed as a supervisor) confirmed task completion:
										  |%3'; fa = '%1, %4 (%2 is appointed as a supervisor) confirmed task completion:
										  |%3';
										  |it = '%1, %4 (%2 is appointed as a supervisor) confirmed task completion:
										  |%3';
										  |pl = '%1, %4 (%2 is appointed as a supervisor) confirmed task completion:
										  |%3';
										  |tr = '%1, %4 (%2 denetmen olarak atandı) görevin tamamlandığını doğruladı:
										  |%3'") + Chars.LF;
			EndIf;
		Else
			If PerformerIsCurrentUser Then
				StringFormat = NStr("vi = '%1, %2 đã xác nhận hủy bỏ nhiệm vụ:
										  |%3';
										  |ru = '%1, %2 подтвердил(а) отмену задачи:
										  |%3';
										  |en = '%1, %2 confirmed task cancellation:
										  |%3'; fa = '%1, %2 confirmed task cancellation:
										  |%3';
										  |it = '%1, %2 ha confermato l''annullamento del compito:
										  |%3';
										  |pl = '%1, %2 potwierdził(a) anulowanie zadania:
										  |%3';
										  |tr = '%1, %2 görevin iptal edildiğini doğruladı:
										  |%3'") + Chars.LF;
			Else
				StringFormat = NStr("vi = '%1, %4 (người kiểm tra đã được chỉ định %2) người xác nhận hủy nhiệm vụ:
										  |%3';
										  |ru = '%1, %4 (проверяющим назначен %2) подтвердил(а) отмену задачи:
										  |%3';
										  |en = '%1, %4 (%2 is appointed as a supervisor) confirmed task cancellation:
										  |%3'; fa = '%1, %4 (%2 is appointed as a supervisor) confirmed task cancellation:
										  |%3';
										  |it = '%1, %4 (%2 is appointed as a supervisor) confirmed task cancellation:
										  |%3';
										  |pl = '%1, %4 (%2 is appointed as a supervisor) confirmed task cancellation:
										  |%3';
										  |tr = '%1, %4 (%2 denetmen olarak atandı) görevin iptal edildiğini doğruladı:
										  |%3'") + Chars.LF;
			EndIf;
		EndIf;
	EndIf;
	
	Comment = TrimAll(TaskData.ExecutionResult);
	Comment = ?(IsBlankString(Comment), "", Comment + Chars.LF);
	Result = StringFunctionsClientServer.SubstituteParametersToString(StringFormat, TaskData.CompletionDate,
		TaskData.Performer, Comment, Users.CurrentUser());
	Return Result;

EndFunction

Procedure FillDefaultAccessValuesSets(Table)
	
	// The default access rights
	// - Read: Author OR Performer (addressing-wise) OR Supervisor (addressing-wise).
	// - Update: Author.
	
	// If the subject is not specified (the business process is not based on another subject), then the subject is not involved in the restriction logic.
	
	// Read, Update: Set #1.
	String = Table.Add();
	String.SetNumber     = 1;
	String.Read          = True;
	String.Update       = True;
	String.AccessValue = Author;
	
	// Read: Set #2.
	String = Table.Add();
	String.SetNumber     = 2;
	String.Read          = True;
	String.AccessValue = TaskPerformersGroup;
	
	// Read: Set #3.
	String = Table.Add();
	String.SetNumber     = 3;
	String.Read          = True;
	String.AccessValue = TaskPerformersGroupSupervisor;

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