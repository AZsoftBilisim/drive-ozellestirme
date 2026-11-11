///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region BusinessProcessCommands

// Marks the specified business processes as suspended.
//
// Parameters:
//  CommandParameter  - Array of DefinedType.BusinessProcess
//                   - DefinedType.BusinessProcess
//
Procedure Stop(Val CommandParameter) Export
	
	QueryText = "";
	TaskCount1 = 0;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		
		If CommandParameter.Count() = 0 Then
			ShowMessageBox(,NStr("vi = 'Chưa chọn quy trình nghiệp vụ nào.';
								|ru = 'Не выбран ни один бизнес-процесс.';
								|en = 'No business process is selected.'; fa = 'No business process is selected.';
								|it = 'Non è stato selezionato nemmeno un processo aziendale.';
								|pl = 'Nie wybrano ani jednego procesu biznesowego.';
								|tr = 'Hiçbir iş süreci seçilmedi.'"));
			Return;
		EndIf;
		
		If CommandParameter.Count() = 1 And TypeOf(CommandParameter[0]) = Type("DynamicListGroupRow") Then
			ShowMessageBox(,NStr("vi = 'Chưa chọn quy trình nghiệp vụ nào.';
								|ru = 'Не выбран ни один бизнес-процесс.';
								|en = 'No business process is selected.'; fa = 'No business process is selected.';
								|it = 'Non è stato selezionato nemmeno un processo aziendale.';
								|pl = 'Nie wybrano ani jednego procesu biznesowego.';
								|tr = 'Hiçbir iş süreci seçilmedi.'"));
			Return;
		EndIf;
		
		TaskCount1 = BusinessProcessesAndTasksServerCall.UncompletedBusinessProcessesTasksCount(CommandParameter);
		If CommandParameter.Count() = 1 Then
			If TaskCount1 > 0 Then
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sẽ dừng quy trình nghiệp vụ ""%1"" và tất cả nhiệm vụ chưa thực hiện của nó (%2). Tiếp tục?';
						|ru = 'Будет выполнена остановка бизнес-процесса ""%1"" и всех его невыполненных задач (%2). Продолжить?';
						|en = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?'; fa = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?';
						|it = 'Il processo aziendale ""%1"" e tutti i suoi task non conclusi (%2) verranno terminati. Continuare?';
						|pl = 'Będzie wykonane zatrzymanie procesu biznesowego ""%1"" i wszystkich jego niewykonanych zadań (%2). Kontynuować?';
						|tr = '""%1"" iş süreci ve tüm tamamlanmamış görevler (%2) durdurulacaktır. Devam edilsin mi?'"), 
					String(CommandParameter[0]), TaskCount1);
			Else
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sẽ dừng quy trình nghiệp vụ ""%1"". Tiếp tục?';
						|ru = 'Будет выполнена остановка бизнес-процесса ""%1"". Продолжить?';
						|en = 'Business process ""%1"" will be stopped. Continue?'; fa = 'Business process ""%1"" will be stopped. Continue?';
						|it = 'Il processo aziendale ""%1"" verrà terminato. Continuare?';
						|pl = 'Będzie wykonano zatrzymanie procesu biznesowego ""%1"". Kontynuować?';
						|tr = '""%1"" iş süreci durdurulacaktır. Devam edilsin mi?'"), 
					String(CommandParameter[0]));
			EndIf;
		Else
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sẽ dừng quy trình nghiệp vụ (%1) và tất cả nhiệm vụ chưa thực hiện của nó (%2). Tiếp tục?';
					|ru = 'Будет выполнена остановка бизнес-процессов (%1) и всех их невыполненных задач (%2). Продолжить?';
					|en = 'Business processes (%1) and all their unfinished tasks (%2) will be stopped. Continue?'; fa = 'Business processes (%1) and all their unfinished tasks (%2) will be stopped. Continue?';
					|it = 'I processi aziendali ""%1"" e tutti i loro task non conclusi (%2) verranno terminati. Continuare?';
					|pl = 'Będzie wykonane zatrzymanie procesów biznesowych ""%1"" i wszystkich ich niewykonanych zadań (%2). Kontynuować?';
					|tr = '(%1) iş süreçleri ve tüm tamamlanmamış görevleri (%2) durdurulacaktır. Devam edilsin mi?'"), 
				CommandParameter.Count(), TaskCount1);
		EndIf;
		
	Else
		
		If TypeOf(CommandParameter) = Type("DynamicListGroupRow") Then
			ShowMessageBox(,NStr("vi = 'Chưa chọn quy trình nghiệp vụ nào';
								|ru = 'Не выбран ни один бизнес-процесс';
								|en = 'No business process is selected'; fa = 'No business process is selected';
								|it = 'Non è stato selezionato nemmeno un processo aziendale';
								|pl = 'Nie wybrano ani jednego procesu biznesowego';
								|tr = 'Hiçbir iş süreci seçilmedi'"));
			Return;
		EndIf;
		
		TaskCount1 = BusinessProcessesAndTasksServerCall.UncompletedBusinessProcessTasksCount(CommandParameter);
		If TaskCount1 > 0 Then
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sẽ dừng quy trình nghiệp vụ ""%1"" và tất cả nhiệm vụ chưa thực hiện của nó (%2). Tiếp tục?';
					|ru = 'Будет выполнена остановка бизнес-процесса ""%1"" и всех его невыполненных задач (%2). Продолжить?';
					|en = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?'; fa = 'Business process ""%1"" and all its unfinished tasks (%2) will be stopped. Continue?';
					|it = 'Il processo aziendale ""%1"" e tutti i suoi task non conclusi (%2) verranno terminati. Continuare?';
					|pl = 'Będzie wykonane zatrzymanie procesu biznesowego ""%1"" i wszystkich jego niewykonanych zadań (%2). Kontynuować?';
					|tr = '""%1"" iş süreci ve tüm tamamlanmamış görevler (%2) durdurulacaktır. Devam edilsin mi?'"), 
				String(CommandParameter), TaskCount1);
		Else
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sẽ dừng quy trình nghiệp vụ ""%1"". Tiếp tục?';
					|ru = 'Будет выполнена остановка бизнес-процесса ""%1"". Продолжить?';
					|en = 'Business process ""%1"" will be stopped. Continue?'; fa = 'Business process ""%1"" will be stopped. Continue?';
					|it = 'Il processo aziendale ""%1"" verrà terminato. Continuare?';
					|pl = 'Będzie wykonano zatrzymanie procesu biznesowego ""%1"". Kontynuować?';
					|tr = '""%1"" iş süreci durdurulacaktır. Devam edilsin mi?'"), 
				String(CommandParameter));
		EndIf;
		
	EndIf;
	
	Notification = New CallbackDescription("StopCompletion", ThisObject, CommandParameter);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("vi = 'Tạm dừng quy trình nghiệp vụ';
																								|ru = 'Остановка бизнес-процесса';
																								|en = 'Stop business process'; fa = 'Stop business process';
																								|it = 'Terminazione del processo aziendale';
																								|pl = 'Zatrzymanie procesu biznesowego';
																								|tr = 'İş sürecini durdur'"));
	
EndProcedure

// Marks the specified business process as suspended.
//  The procedure is called from a business process form.
//
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForObjects - a business process form, where:
//   * Object - DefinedType.BusinessProcessObject - business process. 
//
Procedure StopBusinessProcessFromObjectForm(Form) Export
	Form.Object.State = PredefinedValue("Enum.BusinessProcessStates.Suspended");
	ClearMessages();
	Form.Write();
	ShowUserNotification(
		NStr("vi = 'Đã dừng quy trình nghiệp vụ';
			|ru = 'Бизнес-процесс остановлен';
			|en = 'The business process is stopped'; fa = 'The business process is stopped';
			|it = 'Il processo aziendale è stato terminato';
			|pl = 'Proces biznesowy zatrzymany';
			|tr = 'İş süreci durduruldu'"),
		GetURL(Form.Object.Ref),
		String(Form.Object.Ref),
		PictureLib.DialogInformation);
	NotifyChanged(Form.Object.Ref);
	
EndProcedure

// Marks the specified business processes as active.
//
// Parameters:
//  CommandParameter - Array of DefinedType.BusinessProcess
//                  - DynamicListGroupRow
//                  - DefinedType.BusinessProcess - business process.
//
Procedure MakeActivated(Val CommandParameter) Export
	
	QueryText = "";
	TaskCount1 = 0;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		
		If CommandParameter.Count() = 0 Then
			ShowMessageBox(,NStr("vi = 'Chưa chọn quy trình nghiệp vụ nào.';
								|ru = 'Не выбран ни один бизнес-процесс.';
								|en = 'No business process is selected.'; fa = 'No business process is selected.';
								|it = 'Non è stato selezionato nemmeno un processo aziendale.';
								|pl = 'Nie wybrano ani jednego procesu biznesowego.';
								|tr = 'Hiçbir iş süreci seçilmedi.'"));
			Return;
		EndIf;
		
		If CommandParameter.Count() = 1 And TypeOf(CommandParameter[0]) = Type("DynamicListGroupRow") Then
			ShowMessageBox(,NStr("vi = 'Chưa chọn quy trình nghiệp vụ nào.';
								|ru = 'Не выбран ни один бизнес-процесс.';
								|en = 'No business process is selected.'; fa = 'No business process is selected.';
								|it = 'Non è stato selezionato nemmeno un processo aziendale.';
								|pl = 'Nie wybrano ani jednego procesu biznesowego.';
								|tr = 'Hiçbir iş süreci seçilmedi.'"));
			Return;
		EndIf;
		
		TaskCount1 = BusinessProcessesAndTasksServerCall.UncompletedBusinessProcessesTasksCount(CommandParameter);
		If CommandParameter.Count() = 1 Then
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Quy trình nghiệp vụ ""%1"" và tất cả nhiệm vụ của quy trình (%2) sẽ được kích hoạt. Tiếp tục?';
					|ru = 'Бизнес-процесс ""%1"" и все его задачи (%2) будут сделаны активными. Продолжить?';
					|en = 'Business process ""%1"" and its tasks (%2) will be active. Continue?'; fa = 'Business process ""%1"" and its tasks (%2) will be active. Continue?';
					|it = 'Il processo aziendale ""%1"" e tutti i suoi task (%2) verranno resi attivi. Continuare?';
					|pl = 'Proces biznesowy ""%1"" i wszystkie jego zadania (%2) będą aktywowane. Kontynuować?';
					|tr = '""%1"" iş süreci ve görevleri (%2) etkinleştirilecek. Devam edilsin mi?'"),
				String(CommandParameter[0]), TaskCount1);
		Else		
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Quy trình nghiệp vụ (%1) và nhiệm vụ của nó (%2) sẽ được kích hoạt. Tiếp tục?';
					|ru = 'Бизнес-процессы (%1) и их задачи (%2) будут сделаны активными. Продолжить?';
					|en = 'Business processes (%1) and their tasks (%2) will be active. Continue?'; fa = 'Business processes (%1) and their tasks (%2) will be active. Continue?';
					|it = 'I processi aziendali ""%1"" e tutti i loro task (%2) verranno resi attivi. Continuare?';
					|pl = 'Procesy biznesowe (%1) i ich zadania (%2) będą aktywowane. Kontynuować?';
					|tr = '(%1) iş süreçleri ve görevleri (%2) etkinleştirilecek. Devam edilsin mi?'"),
				CommandParameter.Count(), TaskCount1);
		EndIf;
		
	Else
		
		If TypeOf(CommandParameter) = Type("DynamicListGroupRow") Then
			ShowMessageBox(,NStr("vi = 'Chưa chọn quy trình nghiệp vụ nào.';
								|ru = 'Не выбран ни один бизнес-процесс.';
								|en = 'No business process is selected.'; fa = 'No business process is selected.';
								|it = 'Non è stato selezionato nemmeno un processo aziendale.';
								|pl = 'Nie wybrano ani jednego procesu biznesowego.';
								|tr = 'Hiçbir iş süreci seçilmedi.'"));
			Return;
		EndIf;
		
		TaskCount1 = BusinessProcessesAndTasksServerCall.UncompletedBusinessProcessTasksCount(CommandParameter);
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Quy trình nghiệp vụ ""%1"" và tất cả nhiệm vụ của quy trình (%2) sẽ được kích hoạt. Tiếp tục?';
				|ru = 'Бизнес-процесс ""%1"" и все его задачи (%2) будут сделаны активными. Продолжить?';
				|en = 'Business process ""%1"" and its tasks (%2) will be active. Continue?'; fa = 'Business process ""%1"" and its tasks (%2) will be active. Continue?';
				|it = 'Il processo aziendale ""%1"" e tutti i suoi task (%2) verranno resi attivi. Continuare?';
				|pl = 'Proces biznesowy ""%1"" i wszystkie jego zadania (%2) będą aktywowane. Kontynuować?';
				|tr = '""%1"" iş süreci ve görevleri (%2) etkinleştirilecek. Devam edilsin mi?'"),
			String(CommandParameter), TaskCount1);
			
	EndIf;
	
	Notification = New CallbackDescription("MakeActivatedCompletion", ThisObject, CommandParameter);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("vi = 'Tạm dừng quy trình nghiệp vụ';
																								|ru = 'Остановка бизнес-процесса';
																								|en = 'Stop business process'; fa = 'Stop business process';
																								|it = 'Terminazione del processo aziendale';
																								|pl = 'Zatrzymanie procesu biznesowego';
																								|tr = 'İş sürecini durdur'"));
	
EndProcedure

// Marks the specified business processes as active.
// The procedure is intended for calling from a business process form.
//
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForObjects - a business process form, where:
//   * Object - DefinedType.BusinessProcessObject - business process.
//
Procedure ContinueBusinessProcessFromObjectForm(Form) Export
	
	Form.Object.State = PredefinedValue("Enum.BusinessProcessStates.Running");
	ClearMessages();
	Form.Write();
	ShowUserNotification(
		NStr("vi = 'Quy trình nghiệp vụ đã được kích hoạt';
			|ru = 'Бизнес-процесс сделан активным';
			|en = 'The business process is activated'; fa = 'The business process is activated';
			|it = 'Il processo aziendale è stato reso attivo';
			|pl = 'Proces biznesowy został aktywowany';
			|tr = 'İş süreci etkinleştirildi'"),
		GetURL(Form.Object.Ref),
		String(Form.Object.Ref),
		PictureLib.DialogInformation);
	NotifyChanged(Form.Object.Ref);
	
EndProcedure

// Marks the specified task as accepted for execution.
//
// Parameters:
//  TaskArray - Array of TaskRef.PerformerTask
//
Procedure AcceptTasksForExecution(Val TaskArray) Export
	
	BusinessProcessesAndTasksServerCall.AcceptTasksForExecution(TaskArray);
	If TaskArray.Count() = 0 Then
		ShowMessageBox(,NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
							|ru = 'Команда не может быть выполнена для указанного объекта.';
							|en = 'Cannot run the command for the object.'; fa = 'Cannot run the command for the object.';
							|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
							|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
		Return;
	EndIf;
	
	TaskValueType = Undefined;
	For Each Task In TaskArray Do
		If TypeOf(Task) <> Type("DynamicListGroupRow") Then 
			TaskValueType = TypeOf(Task);
			Break;
		EndIf;
	EndDo;
	If TaskValueType <> Undefined Then
		NotifyChanged(TaskValueType);
	EndIf;
	
EndProcedure

// Marks the specified task as accepted for execution.
//
// Parameters:
//  Form               - ClientApplicationForm
//                      - ManagedFormExtensionForObjects - a task form, where:
//   * Object - TaskObject 
//            - TaskObject.PerformerTask - task.
//  CurrentUser - CatalogRef.ExternalUsers
//                      - CatalogRef.Users - Reference to the current user.
//                                                        
//
Procedure AcceptTaskForExecution(Form, CurrentUser) Export
	
	Form.Object.AcceptedForExecution = True;
	Performer                     = Form.Object.Performer;
	
	// Keep "AcceptForExecutionDate" empty. 
	// It will be initialized with the current session date before writing the task.
	Form.Object.AcceptForExecutionDate = Date('00010101');
	If Not ValueIsFilled(Performer) Then
		Form.Object.Performer = CurrentUser;
		AcceptTaskForExecutionContinued(Form, True);
	ElsIf Performer = CurrentUser Then
		AcceptTaskForExecutionContinued(Form);
	Else
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("CurrentUser", CurrentUser);
		AdditionalParameters.Insert("Form",               Form);
		
		QuestionNotification = New CallbackDescription("AfterQuestionAcceptTaskForExecution", ThisObject, AdditionalParameters);
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Nhận nhiệm vụ để thực hiện đồng thời thay đổi người thực hiện không?
			|Người thực hiện mới: %1 (thay cho %2)';
			|ru = 'Принять задачу в работу со сменой исполнителя?
			|Новый исполнитель: %1 (вместо %2)';
			|en = 'Accept the task with a change of assignee?
			|New assignee: %1 (instead of %2)'; fa = 'Accept the task with a change of assignee?
			|New assignee: %1 (instead of %2)';
			|it = 'Accept the task with a change of assignee?
			|New assignee: %1 (instead of %2)';
			|pl = 'Accept the task with a change of assignee?
			|New assignee: %1 (instead of %2)';
			|tr = 'Görev, yürütücü değişikliğiyle kabul edilsin mi?
			|Yeni yürütücü: %1 (%2 yerine)'"), CurrentUser, Performer);
		
		DialogButtons = New ValueList();
		DialogButtons.Add(DialogReturnCode.Yes,     NStr("vi = 'Có';
														|ru = 'Да';
														|en = 'Yes'; fa = 'بله';
														|it = 'Yes';
														|pl = 'Yes';
														|tr = 'Evet'"));
		DialogButtons.Add(DialogReturnCode.No,    NStr("vi = 'Để như hiện tại';
														|ru = 'Оставить текущего';
														|en = 'Leave the current'; fa = 'Leave the current';
														|it = 'Lasciare quello corrente';
														|pl = 'Zostawić bieżącego';
														|tr = 'Geçerli olan kalsın'"));
		DialogButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Cancel';
														|pl = 'Cancel';
														|tr = 'İptal'"));
		
		ShowQueryBox(QuestionNotification, QueryText, DialogButtons);
	EndIf;
	
EndProcedure

// Marks the specified tasks as not accepted for execution.
//
// Parameters:
//  TaskArray - Array of TaskRef.PerformerTask
//
Procedure CancelAcceptTasksForExecution(Val TaskArray) Export
	
	BusinessProcessesAndTasksServerCall.CancelAcceptTasksForExecution(TaskArray);
	
	If TaskArray.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
								|ru = 'Команда не может быть выполнена для указанного объекта.';
								|en = 'Cannot run the command for the object.'; fa = 'Cannot run the command for the object.';
								|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
								|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
								|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
		Return;
	EndIf;
	
	TaskValueType = Undefined;
	For Each Task In TaskArray Do
		If TypeOf(Task) <> Type("DynamicListGroupRow") Then 
			TaskValueType = TypeOf(Task);
			Break;
		EndIf;
	EndDo;
	
	If TaskValueType <> Undefined Then
		NotifyChanged(TaskValueType);
	EndIf;
	
EndProcedure

// Marks the specified task as not accepted for execution.
//
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForObjects - a task form, where:
//   * Object - TaskObject - task.
//
Procedure CancelAcceptTaskForExecution(Form) Export
	
	Form.Object.AcceptedForExecution      = False;
	Form.Object.AcceptForExecutionDate = "00010101000000";
	If Not Form.Object.PerformerRole.IsEmpty() Then
		Form.Object.Performer = Undefined;
	EndIf;
	
	ClearMessages();
	Form.Write();
	UpdateAcceptForExecutionCommandsAvailability(Form);
	NotifyChanged(Form.Object.Ref);
	
EndProcedure

// Sets availability of commands for accepting for execution.
//
// Parameters:
//  Form - ClientApplicationForm - a task form, where:
//   * Items - FormAllItems - form items. The form contains:
//     ** FormAcceptForExecution - TextBox - a command button on the form.
//     ** FormCancelAcceptForExecution - TextBox - a command button on the form. 
//
Procedure UpdateAcceptForExecutionCommandsAvailability(Form) Export
	
	If Form.Object.AcceptedForExecution = True Then
		Form.Items.FormAcceptForExecution.Enabled = False;
		
		If Form.Object.Executed Then
			Form.Items.FormCancelAcceptForExecution.Enabled = False;
		Else
			Form.Items.FormCancelAcceptForExecution.Enabled = True;
		EndIf;
		
	Else	
		Form.Items.FormAcceptForExecution.Enabled = True;
		Form.Items.FormCancelAcceptForExecution.Enabled = False;
	EndIf;
		
EndProcedure

// Opens the form to set up deferred start of a business process.
//
// Parameters:
//  BusinessProcess  - DefinedType.BusinessProcess
//  TaskDueDate - Date
//
Procedure SetUpDeferredStart(BusinessProcess, TaskDueDate) Export
	
	If BusinessProcess.IsEmpty() Then
		WarningText = 
			NStr("vi = 'Không thể tùy chỉnh hoãn bắt đầu đối với quy trình chưa điền.';
				|ru = 'Невозможно настроить отложенный старт для незаписанного процесса.';
				|en = 'Cannot set up deferred start for an unsaved process.'; fa = 'Cannot set up deferred start for an unsaved process.';
				|it = 'Non è possibile configurare un avvio ritardato per un processo non registrato.';
				|pl = 'Niemożliwe jest ustawić odłożony start dla niezapisanego procesu.';
				|tr = 'Kaydedilmemiş bir süreç için ertelenmiş başlangıç düzenlenemez.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
		
	FormParameters = New Structure;
	FormParameters.Insert("BusinessProcess", BusinessProcess);
	FormParameters.Insert("TaskDueDate", TaskDueDate);
	
	OpenForm(
		"InformationRegister.ProcessesToStart.Form.DeferredProcessStartSetup",
		FormParameters,,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region AdditionalProceduresAndFunctions

// Standard notification handler for task execution forms.
//  The procedure is intended for calling from the NotificationProcessing form event handler.
//
// Parameters:
//  Form      - ClientApplicationForm - a task execution form, where:
//   * Object - TaskObject  - Object's task.
//  EventName - String       - Event name.
//  Parameter   - Arbitrary - an event parameter.
//  Source   - Arbitrary - an event source.
//
Procedure TaskFormNotificationProcessing(Form, EventName, Parameter, Source) Export
	
	If EventName = "Write_PerformerTask" Then
		If Not Form.Modified 
			And (Source = Form.Object.Ref Or (TypeOf(Source) = Type("Array") 
			And Source.Find(Form.Object.Ref) <> Undefined)) Then
			If Parameter.Property("Forwarded") Then
				Form.Close();
			Else
				Form.Read();
			EndIf;
		ElsIf Parameter.Property("AcceptTaskForExecution") And Parameter.AcceptTaskForExecution = "Refresh" Then
			Form.Read();
		EndIf;
	EndIf;
	
EndProcedure

// Standard BeforeAddRow handler for task lists.
//  The procedure is intended for calling from the BeforeAddRow form table event handler.
//
// Parameters:
//  Form        - ClientApplicationForm - task form.
//  Item      - FormTable - form table items.
//  Cancel        - Boolean - shows whether adding objects is canceled. If the parameter is set to
//                          True in the handler, the object is not added.
//  Copy  - Boolean - defines the copy mode. If True, the row is copied. 
//  Parent     - Undefined
//               - CatalogRef
//               - ChartOfAccountsRef - a reference to the item used
//                                    as a parent on adding.
//  Group       - Boolean - shows whether a group is added. True - a group is added. 
//
Procedure TaskListBeforeAddRow(Form, Item, Cancel, Copy, Parent, Group) Export
	
	If Copy Then
		Task = Item.CurrentRow;
		If Not ValueIsFilled(Task) Then
			Return;
		EndIf;
		FormParameters = New Structure("Basis", Task);
	EndIf;
	CreateJob(Form, FormParameters);
	Cancel = True;
	
EndProcedure

// Writes and closes the task execution form.
//
// Parameters:
//  Form  - ClientApplicationForm - a task execution form, where:
//   * Object - TaskObject - a business process task.
//  ExecuteTask  - Boolean - a task is written in the execution mode.
//  NotificationParameters - Structure - Additional notification parameters.
//
// Returns:
//   Boolean   - True if the task is written.
//
Function WriteAndCloseExecute(Form, ExecuteTask = False, NotificationParameters = Undefined) Export
	
	ClearMessages();
	
	NewObject = Form.Object.Ref.IsEmpty();
	NotificationText1 = "";
	If NotificationParameters = Undefined Then
		NotificationParameters = New Structure;
	EndIf;
	If Not Form.InitialExecutionFlag And ExecuteTask Then
		If Not Form.Write(New Structure("ExecuteTask", True)) Then
			Return False;
		EndIf;
		NotificationText1 = NStr("vi = 'Nhiệm vụ đã thực hiện';
								|ru = 'Задача выполнена';
								|en = 'The task is completed'; fa = 'وظیفه تکمیل شده است';
								|it = 'Task completato';
								|pl = 'Zadanie zakończone';
								|tr = 'Görev tamamlandı'");
	Else
		If Not Form.Write() Then
			Return False;
		EndIf;
		NotificationText1 = ?(NewObject, NStr("vi = 'Nhiệm vụ đã tạo';
												|ru = 'Задача создана';
												|en = 'The task is created'; fa = 'The task is created';
												|it = 'Obiettivo creato';
												|pl = 'Zadanie zostało utworzone';
												|tr = 'Görev oluşturuldu'"), NStr("vi = 'Nhiệm vụ đã thay đổi';
																					|ru = 'Задача изменена';
																					|en = 'The task is changed'; fa = 'The task is changed';
																					|it = 'Task modificato';
																					|pl = 'Zadanie zostało zmienione';
																					|tr = 'Görev değişti'"));
	EndIf;
	
	Notify("Write_PerformerTask", NotificationParameters, Form.Object.Ref);
	ShowUserNotification(NotificationText1,
		GetURL(Form.Object.Ref),
		String(Form.Object.Ref),
		PictureLib.DialogInformation);
	Form.Close();
	Return True;
	
EndFunction

// Opens a new job form.
//
// Parameters:
//  OwnerForm  - ClientApplicationForm - a form that must be the owner for the form being opened.
//  FormParameters - Structure - parameters of the form to be opened.
//
Procedure CreateJob(Val OwnerForm = Undefined, Val FormParameters = Undefined) Export
	
	OpenForm("BusinessProcess.Job.ObjectForm", FormParameters, OwnerForm);
	
EndProcedure	

// Opens a form for forwarding one or several tasks to another assignee.
//
// Parameters:
//  RedirectedTasks_ - Array of TaskRef.PerformerTask
//  OwnerForm - ClientApplicationForm - a form that must be the owner for the task forwarding
//                                               form being opened.
//
Procedure ForwardTasks(RedirectedTasks_, OwnerForm) Export
	
	If RedirectedTasks_ = Undefined Then
		ShowMessageBox(,NStr("vi = 'Chưa chọn nhiệm vụ.';
							|ru = 'Не выбраны задачи.';
							|en = 'Tasks are not selected.'; fa = 'Tasks are not selected.';
							|it = 'Obiettivi non selezionati.';
							|pl = 'Nie wybrane zadania.';
							|tr = 'Görevler seçilmedi.'"));
		Return;
	EndIf;
		
	TasksCanBeForwarded = BusinessProcessesAndTasksServerCall.ForwardTasks(
		RedirectedTasks_, Undefined, True);
	If Not TasksCanBeForwarded And RedirectedTasks_.Count() = 1 Then
		ShowMessageBox(,NStr("vi = 'Không thể chuyển hướng nhiệm vụ đã thực hiện hoặc nhiệm vụ đã chuyển hướng cho người thực hiện khác.';
							|ru = 'Невозможно перенаправить уже выполненную задачу или направленную другому исполнителю.';
							|en = 'Cannot forward a task that is already completed or was sent to another user.'; fa = 'Cannot forward a task that is already completed or was sent to another user.';
							|it = 'Non è possibile reindirizzare un obiettivo già completato o indirizzato a un altro esecutore.';
							|pl = 'Jest niemożliwe przekierować już wykonane zadanie lub skierowane do innego wykonawcy.';
							|tr = 'Tamamlanmış veya başka bir kullanıcıya gönderilmiş olan görev iletilemez.'"));
		Return;
	EndIf;
		
	Notification = New CallbackDescription("ForwardTasksCompletion", ThisObject, RedirectedTasks_);
	OpenForm("Task.PerformerTask.Form.ForwardTasks",
		New Structure("Task,TaskCount,FormCaption", 
		RedirectedTasks_[0], RedirectedTasks_.Count(), 
		?(RedirectedTasks_.Count() > 1, NStr("vi = 'Chuyển hướng nhiệm vụ';
											|ru = 'Перенаправить задачи';
											|en = 'Forward tasks'; fa = 'ارجاع وظایف';
											|it = 'Reindirizzare gli obiettivi';
											|pl = 'Przekieruj zadania';
											|tr = 'Görevleri yönlendir'"), 
			NStr("vi = 'Chuyển hướng nhiệm vụ';
				|ru = 'Перенаправить задачу';
				|en = 'Forward task'; fa = 'Forward task';
				|it = 'Reindirizzare l''obiettivo';
				|pl = 'Przekieruj zadanie';
				|tr = 'Görevi ilet'"))), 
		OwnerForm,,,, Notification);
		
EndProcedure

// Opens the form with additional information about the task.
//
// Parameters:
//  TaskRef - TaskRef.PerformerTask
// 
Procedure OpenAdditionalTaskInfo(Val TaskRef) Export
	
	OpenForm("Task.PerformerTask.Form.More", 
		New Structure("Key", TaskRef));
	
EndProcedure

// Opens the list of task assignees and roles.
//
Procedure OpenRolesAndTaskPerformersList() Export
	
	OpenForm("InformationRegister.TaskPerformers.Form.RolesAndTaskPerformers");
	
EndProcedure

// Opens the assignee role selection form.
// 
// Parameters:
//  FormParameters - See PerformerRoleChoiceFormParameters
//  Owner - Undefined
//           - ClientApplicationForm - The form where the assignee selection form opens.
//
Procedure OpenPerformerRoleChoiceForm(FormParameters, Owner) Export

	OpenForm("CommonForm.SelectPerformerRole", FormParameters, Owner);

EndProcedure

// The form opening parameters.
// 
// Parameters:
//  PerformerRole - CatalogRef.PerformerRoles - A role for role-based assignment of the task to business process members. 
//  MainAddressingObject - Arbitrary - The main business object for forwarding the task.
//  AdditionalAddressingObject - Arbitrary - An additional business object for forwarding the task.
// 
// Returns:
//  Structure:
//   * PerformerRole  - CatalogRef.PerformerRoles - A role for role-based assignment of the task to business process members.
//   * MainAddressingObject - Arbitrary - The main business object for forwarding the task.
//   * AdditionalAddressingObject - Arbitrary - An additional business object for forwarding the task.
//   * SelectAddressingObject - Boolean - If set to "True", the main business object is selected in the list.
// 
Function PerformerRoleChoiceFormParameters(PerformerRole, MainAddressingObject = Undefined, 
		AdditionalAddressingObject = Undefined) Export

	FormParameters = New Structure;
	FormParameters.Insert("PerformerRole",               PerformerRole);
	FormParameters.Insert("MainAddressingObject",       MainAddressingObject);
	FormParameters.Insert("AdditionalAddressingObject", AdditionalAddressingObject);
	FormParameters.Insert("SelectAddressingObject",         False);
	
	Return FormParameters;

EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure OpenBusinessProcess(List) Export
	If TypeOf(List.CurrentRow) <> Type("TaskRef.PerformerTask") Then
		ShowMessageBox(,NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
							|ru = 'Команда не может быть выполнена для указанного объекта.';
							|en = 'Cannot run the command for the object.'; fa = 'Cannot run the command for the object.';
							|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
							|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
		Return;
	EndIf;
	If List.CurrentData.BusinessProcess = Undefined Then
		ShowMessageBox(,NStr("vi = 'Trong nhiệm vụ đã chọn chưa chỉ ra quy trình nghiệp vụ.';
							|ru = 'У выбранной задачи не указан бизнес-процесс.';
							|en = 'Business process of the selected task is not specified.'; fa = 'Business process of the selected task is not specified.';
							|it = 'Nel processo selezionato non è indicato nessun processo aziendale.';
							|pl = 'U wybranego zadania nie określono procesu biznesowego.';
							|tr = 'Seçilen görevin iş süreci belirtilmedi.'"));
		Return;
	EndIf;
	ShowValue(, List.CurrentData.BusinessProcess);
EndProcedure

Procedure OpenTaskSubject(List) Export
	If TypeOf(List.CurrentRow) <> Type("TaskRef.PerformerTask") Then
		ShowMessageBox(,NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ định.';
							|ru = 'Команда не может быть выполнена для указанного объекта.';
							|en = 'Cannot run the command for the object.'; fa = 'Cannot run the command for the object.';
							|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
							|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
		Return;
	EndIf;
	If List.CurrentData.SubjectOf = Undefined Then
		ShowMessageBox(,NStr("vi = 'Trong nhiệm vụ chưa chỉ ra chủ đề.';
							|ru = 'У выбранной задачи не указан предмет.';
							|en = 'Subject of the selected task is not specified.'; fa = 'Subject of the selected task is not specified.';
							|it = 'Nel processo selezionato non è indicato un oggetto.';
							|pl = 'U wybranego zadania nie określono przedmiotu.';
							|tr = 'Seçilen görevin konusu belirtilmedi.'"));
		Return;
	EndIf;
	ShowValue(, List.CurrentData.SubjectOf);
EndProcedure

Procedure AfterQuestionAcceptTaskForExecution(Result, AdditionalParameters) Export
	
	IsFormUpdateRequired = False;
	If Result = DialogReturnCode.Cancel Then
		Return;
	ElsIf Result = DialogReturnCode.Yes Then
		AdditionalParameters.Form.Object.Performer = AdditionalParameters.CurrentUser;
		IsFormUpdateRequired = True;
	EndIf;
	
	AcceptTaskForExecutionContinued(AdditionalParameters.Form, IsFormUpdateRequired);
	
EndProcedure

// Parameters:
//  Form               - ClientApplicationForm
//                      - ManagedFormExtensionForObjects - a task form, where:
//   * Object - TaskObject.PerformerTask 
//            - TaskObject - task.
//  CurrentUser - CatalogRef.ExternalUsers
//                      - CatalogRef.Users - Reference to the
//                                                        current user.
//
Procedure AcceptTaskForExecutionContinued(Form, IsFormUpdateRequired = False)
	
	AcceptTaskForExecution = ?(IsFormUpdateRequired, "Refresh", "");
	NotificationParameters = New Structure;
	NotificationParameters.Insert("AcceptTaskForExecution", AcceptTaskForExecution);
	
	ClearMessages();
	Form.Write();
	UpdateAcceptForExecutionCommandsAvailability(Form);
	NotifyChanged(Form.Object.Ref);
	
	Notify("Write_PerformerTask", NotificationParameters, Form.Object.Ref);
	
EndProcedure

// Standard handler DeletionMark used in the lists of business processes.
// The procedure is intended for calling from the DeletionMark list event handler.
//
// Parameters:
//   List  - FormTable - a form control (form table) with a list of business processes.
//
Procedure BusinessProcessesListDeletionMark(List) Export
	
	SelectedRows = List.SelectedRows;
	If SelectedRows = Undefined Or SelectedRows.Count() <= 0 Then
		ShowMessageBox(,NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
							|ru = 'Команда не может быть выполнена для указанного объекта.';
							|en = 'Cannot run the command for the object.'; fa = 'Cannot run the command for the object.';
							|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
							|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
		Return;
	EndIf;
	Notification = New CallbackDescription("BusinessProcessesListDeletionMarkCompletion", ThisObject, List);
	ShowQueryBox(Notification, NStr("vi = 'Thay đổi dấu xóa?';
									|ru = 'Изменить пометку удаления?';
									|en = 'Change deletion mark?'; fa = 'Change deletion mark?';
									|it = 'Modificare il contrassegno per la cancellazione?';
									|pl = 'Zmienić zaznaczenie usunięcia?';
									|tr = 'Silme işareti değiştirilsin mi?'"), QuestionDialogMode.YesNo);
	
EndProcedure

// Opens the assignee selection form.
//
// Parameters:
//   PerformerItem - FormField - a form item where an assignee is selected. 
//      The form item is specified as the owner of the assignee selection form.
//   PerformerAttribute - CatalogRef.Users - a previously selected Assignee value.
//      Used to set the current row in the assignee selection form.
//   SimpleRolesOnly - Boolean - If True, only roles without business objects 
//      are used in the selection.
//   NoExternalRoles - Boolean - If True, only roles without the ExternalRole flag
//      are used in the selection.
//
Procedure SelectPerformer(PerformerItem, PerformerAttribute, SimpleRolesOnly = False, NoExternalRoles = False) Export 
	
	StandardProcessing = True;
	BusinessProcessesAndTasksClientOverridable.OnPerformerChoice(PerformerItem, PerformerAttribute, 
		SimpleRolesOnly, NoExternalRoles, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;
			
	FormParameters = New Structure("Performer, SimpleRolesOnly, NoExternalRoles", 
		PerformerAttribute, SimpleRolesOnly, NoExternalRoles);
	OpenForm("CommonForm.SelectBusinessProcessPerformer", FormParameters, PerformerItem);
	
EndProcedure	

Procedure StopCompletion(Val Result, Val CommandParameter) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		BusinessProcessesAndTasksServerCall.StopBusinessProcesses(CommandParameter);
	Else
		BusinessProcessesAndTasksServerCall.StopBusinessProcess(CommandParameter);
	EndIf;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		If CommandParameter.Count() <> 0 Then
			For Each Parameter In CommandParameter Do
				If TypeOf(Parameter) <> Type("DynamicListGroupRow") Then
					NotifyChanged(TypeOf(Parameter));
					Break;
				EndIf;
			EndDo;
		EndIf;
	Else
		NotifyChanged(CommandParameter);
	EndIf;

EndProcedure

Procedure BusinessProcessesListDeletionMarkCompletion(Result, List) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	SelectedRows = List.SelectedRows;
	BusinessProcessRef = BusinessProcessesAndTasksServerCall.MarkBusinessProcessesForDeletion(SelectedRows);
	List.Refresh();
	ShowUserNotification(NStr("vi = 'Đã thay đổi dấu xóa.';
								|ru = 'Пометка удаления изменена.';
								|en = 'The deletion mark is changed.'; fa = 'The deletion mark is changed.';
								|it = 'Contrassegno per la cancellazione modificato.';
								|pl = 'Zaznaczenie usunięcia została zmieniona';
								|tr = 'Silme işareti değiştirildi.'"), 
		?(BusinessProcessRef <> Undefined, GetURL(BusinessProcessRef), ""),
		?(BusinessProcessRef <> Undefined, String(BusinessProcessRef), ""));
	
EndProcedure

Procedure MakeActivatedCompletion(Val Result, Val CommandParameter) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
		
	If TypeOf(CommandParameter) = Type("Array") Then
		BusinessProcessesAndTasksServerCall.ActivateBusinessProcesses(CommandParameter);
	Else
		BusinessProcessesAndTasksServerCall.ActivateBusinessProcess(CommandParameter);
	EndIf;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		If CommandParameter.Count() <> 0 Then
			For Each Parameter In CommandParameter Do
				If TypeOf(Parameter) <> Type("DynamicListGroupRow") Then
					NotifyChanged(TypeOf(Parameter));
					Break;
				EndIf;
			EndDo;
		EndIf;
	Else
		NotifyChanged(CommandParameter);
	EndIf;
	
EndProcedure

Procedure ForwardTasksCompletion(Val Result, Val TaskArray) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	ForwardedTaskArray = Undefined;
	TasksAreForwarded = BusinessProcessesAndTasksServerCall.ForwardTasks(
		TaskArray, Result, False, ForwardedTaskArray);
		
		
	If TasksAreForwarded Then
		Notify("Write_PerformerTask", New Structure("Forwarded", TasksAreForwarded), TaskArray);
	EndIf;
	
EndProcedure

#EndRegion