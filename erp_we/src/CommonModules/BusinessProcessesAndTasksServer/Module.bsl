///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Initializes common parameters of the task execution form.
//
// Parameters:
//  BusinessTaskForm            - ClientApplicationForm - a task execution form.
//  TaskObject           - TaskObject     - a task object.
//  StateGroupItem - FormGroup      - a group with information on the task state.
//  CompletionDateItem  - FormField        - a field with the task completion date.
//
Procedure TaskFormOnCreateAtServer(BusinessTaskForm, TaskObject, 
	StateGroupItem, CompletionDateItem) Export
	
	BusinessTaskForm.ReadOnly = TaskObject.Executed;

	If TaskObject.Executed Then
		If StateGroupItem <> Undefined Then
			StateGroupItem.Visible = True;
		EndIf;
		Parent = ?(StateGroupItem <> Undefined, StateGroupItem, BusinessTaskForm);
		Item = BusinessTaskForm.Items.Find("__TaskStatePicture");
		If Item = Undefined Then
			Item = BusinessTaskForm.Items.Add("__TaskStatePicture", Type("FormDecoration"), Parent);
			Item.Type = FormDecorationType.Picture;
			Item.Picture = PictureLib.Information;
		EndIf;
		
		Item = BusinessTaskForm.Items.Find("__TaskState");
		If Item = Undefined Then
			Item = BusinessTaskForm.Items.Add("__TaskState", Type("FormDecoration"), Parent);
			Item.Type = FormDecorationType.Label;
			Item.Height = 0; // Auto height.
			Item.AutoMaxWidth = False;
		EndIf;
		UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
		CompletionDateAsString = ?(UseDateAndTimeInTaskDeadlines, 
			Format(TaskObject.CompletionDate, "DLF=DT"), Format(TaskObject.CompletionDate, "DLF=D"));
		Item.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Nhiệm vụ đã thực hiện %1 bởi người sử dụng %2';
																					|ru = 'Задача выполнена %1 пользователем %2.';
																					|en = 'The task is completed on %1 by user %2.'; fa = 'The task is completed on %1 by user %2.';
																					|it = 'L''obiettivo %1 è stato completato dall''utente %2.';
																					|pl = 'Zadanie zostało wykonane %1 użytkownikiem %2.';
																					|tr = 'Görev %1''de %2 kullanıcısı tarafından tamamlandı.'"),
			CompletionDateAsString, 
			PerformerString(TaskObject.Performer, TaskObject.PerformerRole,
			TaskObject.MainAddressingObject, TaskObject.AdditionalAddressingObject));
	EndIf;
	
	If IsHeadTask(TaskObject.Ref) Then
		If StateGroupItem <> Undefined Then
			StateGroupItem.Visible = True;
		EndIf;
		Parent = ?(StateGroupItem <> Undefined, StateGroupItem, BusinessTaskForm);
		Item = BusinessTaskForm.Items.Find("__HeadTaskPicture");
		If Item = Undefined Then
			Item = BusinessTaskForm.Items.Add("__HeadTaskPicture", Type("FormDecoration"), Parent);
			Item.Type = FormDecorationType.Picture;
			Item.Picture = PictureLib.Information;
		EndIf;
		
		Item = BusinessTaskForm.Items.Find("__HeadTask");
		If Item = Undefined Then
			Item = BusinessTaskForm.Items.Add("__HeadTask", Type("FormDecoration"), Parent);
			Item.Type = FormDecorationType.Label;
			Item.Title = NStr("vi = 'Đây là nhiệm vụ chính (hàng đầu) đối với quy trình nghiệp vụ lồng trong. Sẽ tự động thực hiện nhiệm vụ đó khi kết thúc các quy trình.';
								|ru = 'Это ведущая задача для вложенных бизнес-процессов. Она будет выполнена автоматически при их завершении.';
								|en = 'This is a leading task for nested business processes. It will be completed automatically upon their completion.'; fa = 'This is a leading task for nested business processes. It will be completed automatically upon their completion.';
								|it = 'Questo è l''obiettivo principale dei processi aziendali nidificati. Sarà eseguito automaticamente quando saranno completati.';
								|pl = 'To jest wiodące zadanie dla pochodnych procesów biznesowych. Ono zostanie wykonane automatycznie po ich zakończeniu.';
								|tr = 'Bu, gömülü iş süreçlerinin başlıca görevidir. Tamamlanmaları üzerine otomatik olarak tamamlanacaktır.'");
			Item.Height = 0; // Auto height.
			Item.AutoMaxWidth = False;
		EndIf;
	EndIf;
	
EndProcedure

// The procedure is called when creating a task list form on the server.
//
// Parameters:
//  TaskListOrItsConditionalAppearance - DynamicList
//                                      - DataCompositionConditionalAppearance - conditional appearance of a task list.
//
Procedure SetTaskAppearance(Val TaskListOrItsConditionalAppearance) Export
	
	If TypeOf(TaskListOrItsConditionalAppearance) = Type("DynamicList") Then
		ConditionalTaskListAppearance = TaskListOrItsConditionalAppearance.SettingsComposer.Settings.ConditionalAppearance;
		ConditionalTaskListAppearance.UserSettingID = "MainAppearance";
	Else
		ConditionalTaskListAppearance = TaskListOrItsConditionalAppearance;
	EndIf;
	
	// Deleting preset appearance items.
	Predefined1 = New Array;
	Items = ConditionalTaskListAppearance.Items;
	For Each ConditionalAppearanceItem In Items Do
		If ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
			Predefined1.Add(ConditionalAppearanceItem);
		EndIf;
	EndDo;
	For Each ConditionalAppearanceItem In Predefined1 Do
		Items.Delete(ConditionalAppearanceItem);
	EndDo;
		
	// Set the appearance for overdue tasks.
	ConditionalAppearanceItem = ConditionalTaskListAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = CurrentSessionDate();
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Executed");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value =  Metadata.StyleItems.OverdueDataColor.Value;   
	AppearanceColorItem.Use = True;
	
	// Set the appearance for completed tasks.
	ConditionalAppearanceItem = ConditionalTaskListAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Executed");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.ExecutedTask.Value; 
	AppearanceColorItem.Use = True;
	
	// Set the appearance for unaccepted tasks.
	ConditionalAppearanceItem = ConditionalTaskListAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("AcceptedForExecution");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Font");
	AppearanceColorItem.Value = Metadata.StyleItems.NotAcceptedForExecutionTasks.Value; 
	AppearanceColorItem.Use = True;
	
	// Set the appearance for tasks with an empty due date.
	ConditionalAppearanceItem = ConditionalTaskListAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("TaskDueDate");
	FormattedField.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Text");
	AppearanceColorItem.Value = NStr("vi = 'Thời hạn chưa chỉ ra';
									|ru = 'Срок не указан';
									|en = 'Due date is not specified'; fa = 'Due date is not specified';
									|it = 'Termine non indicato';
									|pl = 'Termin nie jest podany';
									|tr = 'Bitiş tarihi belirtilmedi'");
	AppearanceColorItem.Use = True;
	
	// Set the appearance for external users. The Author field is empty.
	If Users.IsExternalUserSession() Then
			ConditionalAppearanceItem = ConditionalTaskListAppearance.Items.Add();
			ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;

			FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
			FormattedField.Field = New DataCompositionField("Author");
			FormattedField.Use = True;
			
			DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			DataFilterItem.LeftValue = New DataCompositionField("Author");
			DataFilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
			DataFilterItem.RightValue = Users.AuthorizedUser();
			DataFilterItem.Use = True;

			AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("Text");
			AppearanceColorItem.Value = NStr("vi = 'Đại diện doanh nghiệp';
											|ru = 'Представитель организации';
											|en = 'Company representative'; fa = 'Company representative';
											|it = 'Rappresentante dell''organizzazione';
											|pl = 'Przedstawiciel firmy';
											|tr = 'İş yeri temsilcisi'");
			AppearanceColorItem.Use = True;
	EndIf;
	
EndProcedure

// The procedure is called when creating business processes list form on the server.
//
// Parameters:
//  BusinessProcessesConditionalAppearance - DataCompositionConditionalAppearance - conditional appearance of a business process list.
//
Procedure SetBusinessProcessesAppearance(Val BusinessProcessesConditionalAppearance) Export
	
	// Description is not specified.
	ConditionalAppearanceItem = BusinessProcessesConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("Description");
	FormattedField.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Description");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Không có mô tả';
																		|ru = 'Без описания';
																		|en = 'No description'; fa = 'No description';
																		|it = 'Senza descrizione';
																		|pl = 'Bez opisu';
																		|tr = 'Açıklama yok'"));
	
	// Completed business process.
	ConditionalAppearanceItem = BusinessProcessesConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Completed");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.CompletedBusinessProcess);
	
EndProcedure

// Returns the string representation of the task assignee Performer 
// or the values specified in parameters PerformerRole, MainAddressingObject, and AdditionalAddressingObject.
//
// Parameters:
//  Performer                   - CatalogRef.Users - a task assignee.
//  PerformerRole               - CatalogRef.PerformerRoles - role.
//  MainAddressingObject       - AnyRef - a reference to the main business object.
//  AdditionalAddressingObject - AnyRef - a reference to the additional business object.
//
// Returns:
//  String - String representation of the task assignee, for example:
//           "John Smith" - an assignee as specified in the Performer parameter.
//           "Chief accountant" - a business role specified in the PerformerRole parameter.
//           "Chief accountant (Sun LLC)" - if a role is specified along with the main business object.
//           "Chief accountant (Sun LLC, New York branch)" - if a role is specified along with both business
//                                                                   objects.
//
Function PerformerString(Val Performer, Val PerformerRole,
	Val MainAddressingObject = Undefined, Val AdditionalAddressingObject = Undefined) Export
	
	If ValueIsFilled(Performer) Then
		Return String(Performer)
	ElsIf Not PerformerRole.IsEmpty() Then
		Return RoleString(PerformerRole, MainAddressingObject, AdditionalAddressingObject);
	EndIf;
	Return NStr("vi = 'Chưa chỉ ra';
				|ru = 'Не указан';
				|en = 'Not specified'; fa = 'مشخص نشده';
				|it = 'Non specificato';
				|pl = 'Nie określony';
				|tr = 'Belirtilmemiş'");

EndFunction

// Returns a string representation of the PerformerRole role and its business objects if they are specified.
//
// Parameters:
//  PerformerRole               - CatalogRef.PerformerRoles - role.
//  MainAddressingObject       - AnyRef - a reference to the main business object.
//  AdditionalAddressingObject - AnyRef - a reference to the additional business object.
// 
// Returns:
//  String - String representation of the role, for example:
//            "Chief accountant" - a business role specified in the PerformerRole parameter.
//            "Chief accountant (Sun LLC)" - if a role is specified along with the main business object.
//            "Chief accountant (Sun LLC, New York branch)" - if a role is specified along with both business
//                                                                    objects.
//
Function RoleString(Val PerformerRole,
	Val MainAddressingObject = Undefined, Val AdditionalAddressingObject = Undefined) Export
	
	If Not PerformerRole.IsEmpty() Then
		Result = String(PerformerRole);
		If MainAddressingObject <> Undefined Then
			Result = Result + " (" + String(MainAddressingObject);
			If AdditionalAddressingObject <> Undefined Then
				Result = Result + " ," + String(AdditionalAddressingObject);
			EndIf;
			Result = Result + ")";
		EndIf;
		Return Result;
	EndIf;
	Return "";

EndFunction

// Marks for deletion all the specified business process tasks (or clears the mark).
//
// Parameters:
//  BusinessProcessRef - DefinedType.BusinessProcess - a business process whose tasks are to be marked for deletion.
//  DeletionMark     - Boolean - the DeletionMark property value for tasks.
//
Procedure MarkTasksForDeletion(BusinessProcessRef, DeletionMark) Export
	
	RepresentationOfTheReference = String(BusinessProcessRef);
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("Task.PerformerTask");
		LockItem.SetValue("BusinessProcess", BusinessProcessRef);
		Block.Lock();
		
		Query = New Query("SELECT
			|	PerformerTasks.Ref AS Ref 
			|FROM
			|	Task.PerformerTask AS PerformerTasks
			|WHERE
			|	PerformerTasks.BusinessProcess = &BusinessProcess");
		Query.SetParameter("BusinessProcess", BusinessProcessRef);
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			TaskObject = Selection.Ref.GetObject();
			TaskObject.SetDeletionMark(DeletionMark);
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error, 
			BusinessProcessRef.Metadata(), RepresentationOfTheReference, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure	

// Sets display and edit format for a form field of the Date type
// based on the subsystem settings.
//
// Parameters:
//  DateField - FormField - a form control, a field with a value of the Date type.
//
Procedure SetDateFormat(DateField) Export
	
	UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
	FormatLine = ?(UseDateAndTimeInTaskDeadlines, "DLF=DT", "DLF=D");
	If DateField.Type = FormFieldType.InputField Then
		DateField.EditFormat = FormatLine;
	Else	
		DateField.Format               = FormatLine;
	EndIf;
	DateField.Width                   = ?(UseDateAndTimeInTaskDeadlines, 0, 9);
	
EndProcedure

// Gets the business processes of the TaskRef head task.
//
// Parameters:
//   TaskRef - TaskRef.PerformerTask - a head task.
//   ForChange - Boolean - If True, sets an exclusive managed lock for all business processes of the specified 
//                           head task. Default value is False.
// Returns:
//    Array of DefinedType.BusinessProcess
// 
Function HeadTaskBusinessProcesses(TaskRef, ForChange = False) Export
	
	Result = SelectHeadTaskBusinessProcesses(TaskRef, ForChange);
	Return Result.Unload().UnloadColumn("Ref");
		
EndFunction

// Returns the business process completion date
// which is the maximum completion date of the business process tasks.
//
// Parameters:
//  BusinessProcessRef - DefinedType.BusinessProcess
// 
// Returns:
//  Date
//
Function BusinessProcessCompletionDate(BusinessProcessRef) Export
	
	VerifyAccessRights("Read", BusinessProcessRef.Metadata());
	SetPrivilegedMode(True);
	Query = New Query;
	Query.Text = 
		"SELECT
		|	MAX(PerformerTask.CompletionDate) AS MaxCompletionDate
		|FROM
		|	Task.PerformerTask AS PerformerTask
		|WHERE
		|	PerformerTask.BusinessProcess = &BusinessProcess
		|	AND PerformerTask.Executed = TRUE";
	Query.SetParameter("BusinessProcess", BusinessProcessRef);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then 
		Return CurrentSessionDate();
	EndIf;	
	
	Selection = Result.Select();
	Selection.Next();
	Return Selection.MaxCompletionDate;
	
EndFunction	

// Returns business processes subordinate to the current task.
//
// Parameters:
//  TaskRef  - TaskRef.PerformerTask
//  ForChange  - Boolean - If True, sets an exclusive managed lock 
//                           for all business processes of the specified head task. Default value is False.
//
// Returns:
//   Array of DefinedType.BusinessProcess
//
Function MainTaskBusinessProcesses(TaskRef, ForChange = False) Export
	
	Result = New Array;
	If ForChange Then
		
		Block = New DataLock;
		
		For Each BusinessProcessType In Metadata.DefinedTypes.BusinessProcess.Type.Types() Do
			
			BusinessProcessMetadata = Metadata.FindByType(BusinessProcessType);
			
			// Business processes are not required to have a main task.
			MainTaskAttribute = BusinessProcessMetadata.Attributes.Find("MainTask");
			If MainTaskAttribute = Undefined Then
				Continue;
			EndIf;
				
			LockItem = Block.Add(BusinessProcessMetadata.FullName());
			LockItem.SetValue("MainTask", TaskRef);
			
		EndDo;
		Block.Lock();
	EndIf;
	
	QueryTemplate = "SELECT ALLOWED
		|	Table.Ref AS Ref
		|FROM
		|	#Table AS Table
		|WHERE
		|	Table.MainTask = &MainTask";
			
	QueriesTexts = New Array;
	For Each BusinessProcessType In Metadata.DefinedTypes.BusinessProcess.Type.Types() Do
		
		BusinessProcessMetadata = Metadata.FindByType(BusinessProcessType);
		
		// A main task is not required in business process.
		MainTaskAttribute = BusinessProcessMetadata.Attributes.Find("MainTask");
		If MainTaskAttribute = Undefined Then
			Continue;
		EndIf;
			
		QueryText = StrReplace(QueryTemplate, "#Table", BusinessProcessMetadata.FullName());
		If QueriesTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "SELECT ALLOWED", "SELECT"); // @query-part-1, @query-part-2
		EndIf;
		QueriesTexts.Add(QueryText);
		
	EndDo;
	
	If QueriesTexts.Count() = 0 Then
		Return Result;
	EndIf;
	
	Query = New Query(StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF));
	Query.SetParameter("MainTask", TaskRef);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Add(Selection.Ref);
	EndDo;
	
	Return Result;
	
EndFunction

// Checks if the current user has sufficient rights to change the business process state.
//
// Parameters:
//  BusinessProcessObject - DefinedType.BusinessProcessObject
//
Procedure ValidateRightsToChangeBusinessProcessState(BusinessProcessObject) Export
	
	If Not ValueIsFilled(BusinessProcessObject.State) Then 
		BusinessProcessObject.State = Enums.BusinessProcessStates.Running;
	EndIf;
	
	If BusinessProcessObject.IsNew() Then
		PreviousState = Enums.BusinessProcessStates.Running;
	Else
		PreviousState = Common.ObjectAttributeValue(BusinessProcessObject.Ref, "State");
	EndIf;
	
	If PreviousState <> BusinessProcessObject.State Then
		
		If Not HasRightsToStopBusinessProcess(BusinessProcessObject) Then 
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không đủ quyền để dừng quy trình nghiệp vụ ""%1"".';
					|ru = 'Недостаточно прав для остановки бизнес-процесса ""%1"".';
					|en = 'Insufficient rights to stop business process ""%1"".'; fa = 'Insufficient rights to stop business process ""%1"".';
					|it = 'Permessi insufficienti per terminare il processo aziendale ""%1"".';
					|pl = 'Niewystarczjące uprawnienia dla zatrymania procesu biznesowego ""%1"".';
					|tr = '""%1"" sürecini durdurmak için yetersiz yetki.'"),
				String(BusinessProcessObject));
			Raise(MessageText, ErrorCategory.AccessViolation);
		EndIf;
		
		If PreviousState = Enums.BusinessProcessStates.Running Then
			
			If BusinessProcessObject.Completed Then
				Raise NStr("vi = 'Không thể dừng quy trình nghiệp vụ đã hoàn thành.';
							|ru = 'Невозможно остановить завершенные бизнес-процессы.';
							|en = 'Cannot stop the completed business processes.'; fa = 'Cannot stop the completed business processes.';
							|it = 'È impossibile terminare dei processi aziendali terminati.';
							|pl = 'Jest niemożliwe  zatrzymać zakończone procesy biznesowe.';
							|tr = 'Tamamlanmış iş süreçleri durdurulamaz.'");
			EndIf;
				
			If Not BusinessProcessObject.Started Then
				Raise NStr("vi = 'Không thể dừng quy trình nghiệp vụ chưa khởi động.';
							|ru = 'Невозможно остановить не стартовавшие бизнес-процессы.';
							|en = 'Cannot stop the business processes that are not started yet.'; fa = 'Cannot stop the business processes that are not started yet.';
							|it = 'È impossibile terminare dei processi aziendali non avviati.';
							|pl = 'Jest niemożliwe zatrzymać nie uruchomione procesy biznesowe.';
							|tr = 'Başlamamış olan iş süreçleri durdurulamaz.'");
			EndIf;
			
		ElsIf PreviousState = Enums.BusinessProcessStates.Suspended Then
			
			If BusinessProcessObject.Completed Then
				Raise NStr("vi = 'Không thể làm quy trình nghiệp vụ đã hoàn thiện thành đang hoạt động.';
							|ru = 'Невозможно сделать активными завершенные бизнес-процессы.';
							|en = 'Cannot activate the completed business processes.'; fa = 'Cannot activate the completed business processes.';
							|it = 'È impossibile rendere attivi dei processi aziendali terminati.';
							|pl = 'Jest niemożliwe zrobić aktywnymi zakończone procesy biznesowe.';
							|tr = 'Tamamlanmış iş süreçleri etkinleştirilemez.'");
			EndIf;
				
			If Not BusinessProcessObject.Started Then
				Raise NStr("vi = 'Không thể làm quy trình nghiệp vụ chưa khởi động thành đang hoạt động.';
							|ru = 'Невозможно сделать активными не стартовавшие бизнес-процессы.';
							|en = 'Cannot activate the business processes that are not started yet.'; fa = 'Cannot activate the business processes that are not started yet.';
							|it = 'È impossibile rendere attivi dei processi aziendali non avviati.';
							|pl = 'Jest niemożliwe zrobić aktywnymi nie uruchomione procesy biznesowe.';
							|tr = 'Başlamamış olan iş süreçleri etkinleştirilemez.'");
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Sets an exclusive managed lock for the specified business process.
// For calling commands in dynamic lists from handlers.
// Rows of dynamic list grouping are ignored.
//
// Parameters:
//   Var_BusinessProcesses - DefinedType.BusinessProcess
//                  - Array of DefinedType.BusinessProcess
//
Procedure LockBusinessProcesses(Var_BusinessProcesses) Export
	
	Block = New DataLock;
	If TypeOf(Var_BusinessProcesses) = Type("Array") Then
		For Each BusinessProcess In Var_BusinessProcesses Do
			
			If TypeOf(BusinessProcess) = Type("DynamicListGroupRow") Then
				Continue;
			EndIf;	
			
			LockItem = Block.Add(BusinessProcess.Metadata().FullName());
			LockItem.SetValue("Ref", BusinessProcess);
		EndDo;
	Else	
		If TypeOf(Var_BusinessProcesses) = Type("DynamicListGroupRow") Then
			Return;
		EndIf;	
		LockItem = Block.Add(Var_BusinessProcesses.Metadata().FullName());
		LockItem.SetValue("Ref", Var_BusinessProcesses);
	EndIf;
	Block.Lock();
	
EndProcedure	

// Sets an exclusive managed lock for the specified tasks.
// For calling commands in dynamic lists from handlers.
// Rows of dynamic list grouping are ignored.
//
// Parameters:
//   Var_Tasks - Array of TaskRef.PerformerTask
//          - TaskRef.PerformerTask
//
Procedure LockTasks(Var_Tasks) Export
	
	Block = New DataLock;
	If TypeOf(Var_Tasks) = Type("Array") Then
		For Each Task In Var_Tasks Do
			
			If TypeOf(Task) = Type("DynamicListGroupRow") Then 
				Continue;
			EndIf;
			
			LockItem = Block.Add("Task.PerformerTask");
			LockItem.SetValue("Ref", Task);
		EndDo;
	Else	
		If TypeOf(BusinessProcesses) = Type("DynamicListGroupRow") Then
			Return;
		EndIf;	
		LockItem = Block.Add("Task.PerformerTask");
		LockItem.SetValue("Ref", Var_Tasks);
	EndIf;
	Block.Lock();
	
EndProcedure

// Fills MainTask attribute when creating a business process based on another business process.
// See also BusinessProcessesAndTasksOverridable.OnFillMainBusinessProcessTask.
//
// Parameters:
//  BusinessProcessObject	 - DefinedType.BusinessProcessObject
//  FillingData	 - TaskRef
//                  	 - Arbitrary - filling data that is passed to the filling handler.
//
Procedure FillMainTask(BusinessProcessObject, FillingData) Export
	
	StandardProcessing = True;
	BusinessProcessesAndTasksOverridable.OnFillMainBusinessProcessTask(BusinessProcessObject, FillingData, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	If FillingData = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(FillingData) = Type("TaskRef.PerformerTask") Then
		BusinessProcessObject.MainTask = FillingData;
	EndIf;
	
EndProcedure

// Gets a task assignees group that matches the addressing attributes.
//  If the group does not exist yet, it is created and returned.
//
// Parameters:
//  PerformerRole               - CatalogRef.PerformerRoles - business role.
//  MainAddressingObject       - Characteristic.TaskAddressingObjects - a reference to the main business object.
//  AdditionalAddressingObject - Characteristic.TaskAddressingObjects - a reference to the additional business object.
// 
// Returns:
//  CatalogRef.TaskPerformersGroups
//
Function TaskPerformersGroup(PerformerRole, MainAddressingObject, AdditionalAddressingObject) Export
	
	BeginTransaction();
	Try
		
		Query = New Query(
			"SELECT TOP 1
			|	TaskPerformersGroups.Ref AS Ref
			|FROM
			|	Catalog.TaskPerformersGroups AS TaskPerformersGroups
			|WHERE
			|	TaskPerformersGroups.PerformerRole = &PerformerRole
			|	AND TaskPerformersGroups.MainAddressingObject = &MainAddressingObject
			|	AND TaskPerformersGroups.AdditionalAddressingObject = &AdditionalAddressingObject");
			
		Query.SetParameter("PerformerRole",               PerformerRole);
		Query.SetParameter("MainAddressingObject",       MainAddressingObject);
		Query.SetParameter("AdditionalAddressingObject", AdditionalAddressingObject);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			PerformersGroup = Selection.Ref;
		Else
		
			Block = New DataLock;
			LockItem = Block.Add("Catalog.TaskPerformersGroups");
			LockItem.SetValue("PerformerRole",               PerformerRole);
			LockItem.SetValue("MainAddressingObject",       MainAddressingObject);
			LockItem.SetValue("AdditionalAddressingObject", AdditionalAddressingObject);
			Block.Lock();
			
			Selection = Query.Execute().Select(); // A locking read.
			If Selection.Next() Then
				
				PerformersGroup = Selection.Ref;
			
			Else
				
				// It is necessary to add a new task assignees group.
				PerformersGroupObject = Catalogs.TaskPerformersGroups.CreateItem();
				PerformersGroupObject.PerformerRole               = PerformerRole;
				PerformersGroupObject.MainAddressingObject       = MainAddressingObject;
				PerformersGroupObject.AdditionalAddressingObject = AdditionalAddressingObject;
				PerformersGroupObject.Write();
				PerformersGroup = PerformersGroupObject.Ref;
				
			EndIf;
			
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return PerformersGroup;
	
EndFunction 

// Gets a structure with description of a task execution form.
//
// Parameters:
//  TaskRef - TaskRef.PerformerTask
//
// Returns:
//   See BusinessProcessesAndTasksOverridable.OnReceiveTaskExecutionForm.FormParameters
//
Function TaskExecutionForm(Val TaskRef) Export
	
	CommonClientServer.CheckParameter("BusinessProcessesAndTasks.TaskExecutionForm", 
		"TaskRef", TaskRef, Type("TaskRef.PerformerTask"));

	Attributes = Common.ObjectAttributesValues(TaskRef, "BusinessProcess,RoutePoint");
	If Attributes.BusinessProcess = Undefined Or Attributes.BusinessProcess.IsEmpty() Then
		Return New Structure();
	EndIf;
	
	BusinessProcessType = Attributes.BusinessProcess.Metadata(); // MetadataObjectBusinessProcess 
	FormParameters = BusinessProcesses[BusinessProcessType.Name].TaskExecutionForm(TaskRef,
		Attributes.RoutePoint);
	BusinessProcessesAndTasksOverridable.OnReceiveTaskExecutionForm(
		BusinessProcessType.Name, TaskRef, Attributes.RoutePoint, FormParameters);
	
	Return FormParameters;
	
EndFunction

// Checks whether the report cell contains a reference to the task and returns details value in
// the DetailsValue parameter.
//
// Parameters:
//  Details             - String - a cell name.
//  ReportDetailsData - String - address in temporary storage.
//  DetailsValue     - TaskRef.PerformerTask
//                          - Arbitrary - details value from the cell.
// 
// Returns:
//  Boolean - True if it is a task to an assignee.
//
Function IsPerformerTask(Val Details, Val ReportDetailsData, DetailsValue) Export
	
	ObjectDetailsData = GetFromTempStorage(ReportDetailsData); // DataCompositionDetailsData
	DetailsValue = ObjectDetailsData.Items[Details].GetFields()[0].Value;
	Return TypeOf(DetailsValue) = Type("TaskRef.PerformerTask");
	
EndFunction

// Completes the TaskRef task. If necessary executes
// DefaultCompletionHandler in the manager module
// of the business process where the TaskRef task belongs.
//
// Parameters:
//  TaskRef        - TaskRef
//  DefaultAction - Boolean       - shows whether it is required to call procedure 
//                                       DefaultCompletionHandler for the task business process.
//
Procedure ExecuteTask(TaskRef, DefaultAction = False) Export
	
	BeginTransaction();
	Try
		LockTasks(TaskRef);
		
		TaskInfoRecords = Common.ObjectAttributesValues(TaskRef, "Executed, BusinessProcess, RoutePoint");
		If TaskInfoRecords.Executed Then
			Raise NStr("vi = 'Đã thực hiện nhiệm vụ từ trước.';
						|ru = 'Задача уже была выполнена ранее.';
						|en = 'The task was completed earlier.'; fa = 'The task was completed earlier.';
						|it = 'Il task è già stato svolto precedentemente.';
						|pl = 'Zadanie już było wykonane wcześniej.';
						|tr = 'Görev önceden tamamlandı.'");
		EndIf;
		
		If DefaultAction 
			 And TaskInfoRecords.BusinessProcess <> Undefined
			 And Not TaskInfoRecords.BusinessProcess.IsEmpty() Then
				BusinessProcessType = TaskInfoRecords.BusinessProcess.Metadata(); // MetadataObjectBusinessProcess
				BusinessProcesses[BusinessProcessType.Name].DefaultCompletionHandler(TaskRef,
					TaskInfoRecords.BusinessProcess, TaskInfoRecords.RoutePoint);
		EndIf;
		
		TaskObject = TaskRef.GetObject();
		TaskObject.Executed = False;
		TaskObject.ExecuteTask();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Forwards the TaskArray tasks to a new assignee specified in the ForwardingInfo structure.
//
// Parameters:
//  RedirectedTasks_ - Array of TaskRef.PerformerTask
//  ForwardingInfo   - Structure - new values of task addressing attributes.
//  IsCheckOnly         - Boolean    - If True, the function does not actually forward
//                                       tasks, it only checks 
//                                       whether they can be forwarded.
//  RedirectedTasks - Array of TaskRef.PerformerTask - forwarded tasks.
//                                       The array elements might not exactly match 
//                                       the TasksToRedirect elements if some tasks cannot be forwarded.
//
// Returns:
//   Boolean   - True if the tasks are forwarded successfully.
//
Function ForwardTasks(Val RedirectedTasks_, Val ForwardingInfo, Val IsCheckOnly = False,
	RedirectedTasks = Undefined) Export
	
	Result = True;
	
	If TypeOf(ForwardingInfo) = Type("Structure") 
	  And (TypeOf(ForwardingInfo.Performer) = Type("CatalogRef.Users")
	Or TypeOf(ForwardingInfo.Performer) = Type("CatalogRef.ExternalUsers")) Then
		UserDetails = Common.ObjectAttributesValues(ForwardingInfo.Performer, "Invalid,DeletionMark");
		
		If UserDetails.Invalid 
		 Or UserDetails.DeletionMark Then
			Common.MessageToUser(NStr("vi = 'Một người dùng không hợp lệ đã được chọn làm người thực hiện nhiệm vụ.';
										|ru = 'Исполнителем задачи выбран недействительный пользователь.';
										|en = 'The task is assigned to an inactive user.'; fa = 'The task is assigned to an inactive user.';
										|it = 'The task is assigned to an inactive user.';
										|pl = 'The task is assigned to an inactive user.';
										|tr = 'Görev yöneticisi olarak geçersiz bir kullanıcı seçili.'"));
			Return False; 
		EndIf;
	EndIf;
	
	TasksInfo = Common.ObjectsAttributesValues(RedirectedTasks_, "BusinessProcess,Executed");
	BeginTransaction();
	Try
		For Each Task In TasksInfo Do
			
			If Task.Value.Executed Then
				Result = False;
				If IsCheckOnly Then
					RollbackTransaction();
					Return Result;
				EndIf;
			EndIf;
			
			LockTasks(Task.Key);
			If ValueIsFilled(Task.Value.BusinessProcess) And Not Task.Value.BusinessProcess.IsEmpty() Then
				LockBusinessProcesses(Task.Value.BusinessProcess);
			EndIf;
		EndDo;
		
		If IsCheckOnly Then
			For Each Task In TasksInfo Do
				TaskObject = Task.Key.GetObject();
				TaskObject.Executed = False;
				TaskObject.AdditionalProperties.Insert("Redirection1", True);
				TaskObject.AdditionalProperties.Insert("IsCheckOnly",  True);
				TaskObject.ExecuteTask();
			EndDo;
			RollbackTransaction();
			Return Result;
		EndIf;
		
		For Each Task In TasksInfo Do
			
			If Not ValueIsFilled(RedirectedTasks) Then
				RedirectedTasks = New Array();
			EndIf;
			
			// Don't set a deadlock on "Task" to allow forwarding the task from its form. 
			// 
			TaskObject = Task.Key.GetObject();
			
			SetPrivilegedMode(True);
			NewTask = Tasks.PerformerTask.CreateTask();
			NewTask.Fill(TaskObject);
			FillPropertyValues(NewTask, ForwardingInfo, 
				"Performer,PerformerRole,MainAddressingObject,AdditionalAddressingObject");
			NewTask.Write();
			SetPrivilegedMode(False);
		
			RedirectedTasks.Add(NewTask.Ref);
			
			TaskObject.ExecutionResult = ForwardingInfo.Comment; 
			TaskObject.Executed = False;
			TaskObject.AdditionalProperties.Insert("Redirection1", True);
			TaskObject.ExecuteTask();
			
			SetPrivilegedMode(True);
			//@skip-check query-in-loop - object-by-object recording of large amounts of data.
			SubordinateBusinessProcesses = SelectHeadTaskBusinessProcesses(Task.Key, True).Select();
			SetPrivilegedMode(False);
			While SubordinateBusinessProcesses.Next() Do
				BusinessProcessObject = SubordinateBusinessProcesses.Ref.GetObject();
				BusinessProcessObject.HeadTask = NewTask.Ref;
				BusinessProcessObject.Write();
			EndDo;
			
			SetPrivilegedMode(True);
			//@skip-check query-in-loop - object-by-object recording of large amounts of data.
			SubordinateBusinessProcesses = MainTaskBusinessProcesses(Task.Key, True);
			SetPrivilegedMode(False);
			
			For Each SubordinateBusinessProcess In SubordinateBusinessProcesses Do
				BusinessProcessObject = SubordinateBusinessProcess.GetObject();
				BusinessProcessObject.MainTask = NewTask.Ref;
				BusinessProcessObject.Write();
			EndDo;
			
			OnForwardTask(TaskObject, NewTask);
			
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Result = False;
		If Not IsCheckOnly Then
			Raise;
		EndIf;
	EndTry;
	
	Return Result;
	
EndFunction

// Checks whether the specified task is the head one.
//
// Parameters:
//  TaskRef  - TaskRef.PerformerTask
//
// Returns:
//   Boolean
//
Function IsHeadTask(TaskRef) Export
	
	SetPrivilegedMode(True);
	Result = SelectHeadTaskBusinessProcesses(TaskRef);
	Return Not Result.IsEmpty();
	
EndFunction

// Generates a choice list for picking assignees in input fields of flexible type ("User" and "Role").
//
// Parameters:
//  Text - String - a text fragment to search for possible assignees.
// 
// Returns:
//  ValueList - a selection list containing possible assignees.
//
Function GeneratePerformerChoiceData(Text) Export
	
	ChoiceData = New ValueList;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	Users.Ref AS Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Description LIKE &Text ESCAPE ""~""
	|	AND Users.Invalid = FALSE
	|	AND Users.IsInternal = FALSE
	|	AND Users.DeletionMark = FALSE
	|
	|UNION ALL
	|
	|SELECT
	|	PerformerRoles.Ref
	|FROM
	|	Catalog.PerformerRoles AS PerformerRoles
	|WHERE
	|	PerformerRoles.Description LIKE &Text ESCAPE ""~""
	|	AND NOT PerformerRoles.DeletionMark";
	Query.SetParameter("Text", Common.GenerateSearchQueryString(Text) + "%");
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ChoiceData.Add(Selection.Ref);
	EndDo;
	
	Return ChoiceData;
	
EndFunction

#Region BusinessProcessCommands

// Marks the specified business processes as active.
//
// Parameters:
//  Var_BusinessProcesses - Array of DefinedType.BusinessProcess
//
Procedure ActivateBusinessProcesses(Var_BusinessProcesses) Export
	
	BeginTransaction();
	Try
		LockBusinessProcesses(Var_BusinessProcesses);
		
		For Each BusinessProcess In Var_BusinessProcesses Do
			ActivateBusinessProcess(BusinessProcess);
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Marks the specified business processes as active.
//
// Parameters:
//  BusinessProcess - DefinedType.BusinessProcess
//
Procedure ActivateBusinessProcess(BusinessProcess) Export
	
	If TypeOf(BusinessProcess) = Type("DynamicListGroupRow") Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		LockBusinessProcesses(BusinessProcess);
		
		Object = BusinessProcess.GetObject();
		If Object.State = Enums.BusinessProcessStates.Running Then
			
			If Object.Completed Then
				Raise NStr("vi = 'Không thể đặt quy trình nghiệp vụ đã hoàn thiện thành đang hoạt động.';
							|ru = 'Невозможно сделать активными завершенные бизнес-процессы.';
							|en = 'Cannot activate the completed business processes.'; fa = 'Cannot activate the completed business processes.';
							|it = 'È impossibile rendere attivi dei processi aziendali terminati.';
							|pl = 'Jest niemożliwe zrobić aktywnymi zakończone procesy biznesowe.';
							|tr = 'Tamamlanmış iş süreçleri etkinleştirilemez.'");
			EndIf;
			
			If Not Object.Started Then
				Raise NStr("vi = 'Không thể đặt quy trình nghiệp vụ chưa khởi động thành đang hoạt động.';
							|ru = 'Невозможно сделать активными не стартовавшие бизнес-процессы.';
							|en = 'Cannot activate the business processes that are not started yet.'; fa = 'Cannot activate the business processes that are not started yet.';
							|it = 'È impossibile rendere attivi dei processi aziendali non avviati.';
							|pl = 'Jest niemożliwe zrobić aktywnymi nie uruchomione procesy biznesowe.';
							|tr = 'Başlamamış olan iş süreçleri etkinleştirilemez.'");
			EndIf;
			
			Raise NStr("vi = 'Đã kích hoạt quy trình nghiệp vụ.';
						|ru = 'Бизнес-процесс уже активен.';
						|en = 'The business process is already active.'; fa = 'The business process is already active.';
						|it = 'Il processo aziendale è già attivo.';
						|pl = 'Proces biznesowy jest już aktywowany.';
						|tr = 'İş süreci zaten etkin.'");
		EndIf;
			
		Object.Lock();
		Object.State = Enums.BusinessProcessStates.Running;
		Object.Write(); // ACC:1327 - A lock is set earlier in BusinessProcessesAndTasksServer.LockBusinessProcesses.
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Marks the specified business processes as suspended.
//
// Parameters:
//  Var_BusinessProcesses - Array of DefinedType.BusinessProcess
//
Procedure StopBusinessProcesses(Var_BusinessProcesses) Export
	
	BeginTransaction();
	Try 
		LockBusinessProcesses(Var_BusinessProcesses);
		
		For Each BusinessProcess In Var_BusinessProcesses Do
			StopBusinessProcess(BusinessProcess);
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

// Marks the specified business process as suspended.
//
// Parameters:
//  BusinessProcess - DefinedType.BusinessProcess
//
Procedure StopBusinessProcess(BusinessProcess) Export
	
	If TypeOf(BusinessProcess) = Type("DynamicListGroupRow") Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		LockBusinessProcesses(BusinessProcess);
		
		Object = BusinessProcess.GetObject();
		If Object.State = Enums.BusinessProcessStates.Suspended Then
			
			If Object.Completed Then
				Raise NStr("vi = 'Không thể dừng quy trình nghiệp vụ đã hoàn thành.';
							|ru = 'Невозможно остановить завершенные бизнес-процессы.';
							|en = 'Cannot suspend the completed business processes.'; fa = 'Cannot suspend the completed business processes.';
							|it = 'È impossibile terminare dei processi aziendali terminati.';
							|pl = 'Jest niemożliwe  zatrzymać zakończone procesy biznesowe.';
							|tr = 'Tamamlanmış iş süreçleri durdurulamaz.'");
			EndIf;
				
			If Not Object.Started Then
				Raise NStr("vi = 'Không thể dừng quy trình nghiệp vụ chưa khởi động.';
							|ru = 'Невозможно остановить не стартовавшие бизнес-процессы.';
							|en = 'Cannot suspend the business processes that are not started yet.'; fa = 'Cannot suspend the business processes that are not started yet.';
							|it = 'È impossibile terminare dei processi aziendali non avviati.';
							|pl = 'Jest niemożliwe zatrzymać nie uruchomione procesy biznesowe.';
							|tr = 'Başlamamış olan iş süreçleri durdurulamaz.'");
			EndIf;
			
			Raise NStr("vi = 'Đã dừng quy trình nghiệp vụ.';
						|ru = 'Бизнес-процесс уже остановлен.';
						|en = 'The business process is already suspended.'; fa = 'The business process is already suspended.';
						|it = 'Il processo aziendale è già terminato.';
						|pl = 'Proces biznesowy jest już zatrzymany.';
						|tr = 'İş süreci zaten durduruldu.'");
		EndIf;
		
		Object.Lock();
		Object.State = Enums.BusinessProcessStates.Suspended;
		Object.Write(); // ACC:1327 - A lock is set earlier in BusinessProcessesAndTasksServer.LockBusinessProcesses.
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Marks the specified task as accepted for execution.
//
// Parameters:
//   Var_Tasks - Array of TaskRef.PerformerTask
//
Procedure AcceptTasksForExecution(Var_Tasks) Export
	
	NewTaskArray = New Array();
	
	BeginTransaction();
	Try
		LockTasks(Var_Tasks);
		
		ListOfCompletedTasks = TasksExecutionStatusesByPerformer(Var_Tasks, Users.CurrentUser());
		
		For Each Task In Var_Tasks Do
			
			If TypeOf(Task) = Type("DynamicListGroupRow") Then
				Continue;
			EndIf;
			
			TaskInformation = ListOfCompletedTasks.Find(Task, "Task");
			If TaskInformation = Undefined Or TaskInformation.Executed Then
				Continue;
			EndIf;
			
			TaskObject = Task.GetObject();
			TaskObject.Lock();
			
			TaskObject.AcceptedForExecution      = True;
			TaskObject.AcceptForExecutionDate = CurrentSessionDate();
			If Not ValueIsFilled(TaskObject.Performer) Then
				TaskObject.Performer         = Users.AuthorizedUser();
			EndIf;
			TaskObject.Write(); // ACC:1327 - A lock is set earlier in BusinessProcessesAndTasksServer.LockTasks.
			
			NewTaskArray.Add(Task);
			
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Var_Tasks = NewTaskArray;
	
EndProcedure

// Marks the specified tasks as not accepted for execution.
//
// Parameters:
//   Var_Tasks - Array of TaskRef.PerformerTask
//
Procedure CancelAcceptTasksForExecution(Var_Tasks) Export
	
	NewTaskArray = New Array();
	
	BeginTransaction();
	Try
		LockTasks(Var_Tasks);
		
		For Each Task In Var_Tasks Do
			
			If TypeOf(Task) = Type("DynamicListGroupRow") Then 
				Continue;
			EndIf;
			
			TaskObject = Task.GetObject();
			If TaskObject.Executed Then
				Continue;
			EndIf;
			
			TaskObject.Lock();
			TaskObject.AcceptedForExecution = False;
			TaskObject.AcceptForExecutionDate = "00010101000000";
			If Not TaskObject.PerformerRole.IsEmpty() Then
				TaskObject.Performer = Undefined;
			EndIf;
			TaskObject.Write(); // ACC:1327 - A lock is set earlier in BusinessProcessesAndTasksServer.LockTasks.
			
			NewTaskArray.Add(Task);
			
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Var_Tasks = NewTaskArray;
	
EndProcedure

#EndRegion

#Region BusinessProcessDeferredStart

// Adds a process for deferred start.
//
// Parameters:
//  Process_    - DefinedType.BusinessProcess
//  StartDate4 - Date - deferred start date.
//
Procedure AddProcessForDeferredStart(Process_, StartDate4) Export
	
	If Not ValueIsFilled(StartDate4) Or Not ValueIsFilled(Process_) Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.ProcessesToStart.CreateRecordSet();
	RecordSet.Filter.Owner.Set(Process_);
	
	Record = RecordSet.Add();
	Record.Owner = Process_;
	Record.DeferredStartDate = StartDate4;
	Record.State = Enums.ProcessesStatesForStart.ReadyToStart;
	
	RecordSet.Write();
	
EndProcedure

// Disables deferred process start.
//
// Parameters:
//  Process_ - DefinedType.BusinessProcess
//
Procedure DisableProcessDeferredStart(Process_) Export
	
	StartSettings = DeferredProcessParameters(Process_);
	
	If StartSettings = Undefined Then // The process does not wait for start.
		Return;
	EndIf;
	
	If StartSettings.State = PredefinedValue("Enum.ProcessesStatesForStart.ReadyToStart") Then
		RecordSet = InformationRegisters.ProcessesToStart.CreateRecordSet();
		RecordSet.Filter.Owner.Set(Process_);
		RecordSet.Write();
	EndIf;
	
EndProcedure

// Starts the deferred business process and sets the start flag.
//
// Parameters:
//   BusinessProcess - DefinedType.BusinessProcess
//
Procedure StartDeferredProcess(BusinessProcess) Export
	
	BeginTransaction();
	
	Try
		
		LockDataForEdit(BusinessProcess);
		BusinessProcessObject = BusinessProcess.GetObject();
		// Start the business process and record this in the register.
		BusinessProcessObject.Start();
		InformationRegisters.ProcessesToStart.RegisterProcessStart(BusinessProcess);
		UnlockDataForEdit(BusinessProcess);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể khởi động hoãn lại quy trình do nguyên nhân:
			|%1
			|Hãy thử khởi động quy trình thủ công, mà không hoãn lại.';
			|ru = 'Не удалось отложенно запустить процесс по причине:
			|%1
			|Попробуйте запустить процесс вручную, а не отложенно.';
			|en = 'Cannot delay the process startup due to:
			|%1
			|Try to start the process manually.'; fa = 'Cannot delay the process startup due to:
			|%1
			|Try to start the process manually.';
			|it = 'Не удалось отложенно запустить процесс по причине:
			|%1
			|Попробуйте запустить процесс вручную, а не отложенно.';
			|pl = 'Cannot delay the process startup due to:
			|%1
			|Try to start the process manually.';
			|tr = 'Sürecin başlaması şu sebeple ertelenemedi:
			|%1
			|Süreci manuel olarak başlatmayı deneyin ve ertelemeyin.'"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		InformationRegisters.ProcessesToStart.RegisterStartCancellation(BusinessProcess, LongDesc);
			
	EndTry;
	
EndProcedure

// Returns information on the business process start.
//
// Parameters:
//  Process_ - DefinedType.BusinessProcess
// 
// Returns:
//  - Undefined - if there is no info.
//  - Structure:
//     * BusinessProcess - DefinedType.BusinessProcess
//     * DeferredStartDate - Date
//     * State - EnumRef.ProcessesStatesForStart
//     * StartCancelReason - String - start cancellation reason.
//
Function DeferredProcessParameters(Process_) Export
	
	Result = Undefined;
	
	If Not ValueIsFilled(Process_) Then
		Return Result;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ProcessesToStart.Owner,
		|	ProcessesToStart.DeferredStartDate,
		|	ProcessesToStart.State,
		|	ProcessesToStart.StartCancelReason
		|FROM
		|	InformationRegister.ProcessesToStart AS ProcessesToStart
		|WHERE
		|	ProcessesToStart.Owner = &BusinessProcess";
	Query.SetParameter("BusinessProcess", Process_);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Result = New Structure;
		Result.Insert("BusinessProcess", Selection.Owner);
		Result.Insert("DeferredStartDate", Selection.DeferredStartDate);
		Result.Insert("State", Selection.State);
		Result.Insert("StartCancelReason", Selection.StartCancelReason);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the start date of a deferred business process if BusinessProcess
// waits for deferred start. Otherwise returns an empty date.
//
// Parameters:
//  BusinessProcess - DefinedType.BusinessProcess
// 
// Returns:
//  Date
//
Function ProcessDeferredStartDate(BusinessProcess) Export

	DeferredStartDate = '00010101';
	
	Setting = DeferredProcessParameters(BusinessProcess);
	
	If Setting = Undefined Then
		Return DeferredStartDate;
	EndIf;
	
	If Setting.State = PredefinedValue("Enum.ProcessesStatesForStart.ReadyToStart") Then
		DeferredStartDate = Setting.DeferredStartDate;
	EndIf;
	
	Return DeferredStartDate;

EndFunction

#EndRegion

#Region ScheduledJobsHandlers

// Runs notification mailing to assignees on new tasks received since the date of previous mailing.
// Notifications are sent using email on behalf of the system account.
// Also it is the NewPerformerTaskNotifications scheduled job handler.
//
Procedure NotifyPerformersOnNewTasks() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.NewPerformerTaskNotifications);
	
	ErrorDescription = "";
	MessageKind = NStr("vi = 'Quy trình nghiệp vụ và nhiệm vụ.Thông báo về các nhiệm vụ mới';
						|ru = 'Бизнес-процессы и задачи.Уведомление о новых задачах';
						|en = 'Business processes and tasks.New task notification'; fa = 'Business processes and tasks.New task notification';
						|it = 'Processi aziendali e obiettivi. Notifica sui nuovi obiettivi';
						|pl = 'Procesy biznesowe i zadania. Powiadomienie o nowych zadaniach';
						|tr = 'İş süreçleri ve görevler. Yeni görev bildirimi'", Common.DefaultLanguageCode());

	If Not SystemEmailAccountIsSetUp(ErrorDescription) Then
		WriteLogEvent(MessageKind, EventLogLevel.Error,
			Metadata.ScheduledJobs.NewPerformerTaskNotifications,, ErrorDescription);
		Return;
	EndIf;
	
	NotificationDate3 = CurrentSessionDate();
	LatestNotificationDate = Constants.NewTasksNotificationDate.Get();
	
	// If the notification was not sent or was sent more than 24 hours ago,
	// select the tasks created in the last 24 hours.
	If (LatestNotificationDate = '00010101000000') 
		Or (NotificationDate3 - LatestNotificationDate > 24*60*60) Then
		LatestNotificationDate = NotificationDate3 - 24*60*60;
	EndIf;
	
	WriteLogEvent(MessageKind, EventLogLevel.Information,,,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Bắt đầu thông báo định kỳ về nhiệm vụ mới trong kỳ %1 - %2';
																		|ru = 'Начато регламентное уведомление о новых задачах за период %1 - %2';
																		|en = 'Scheduled notification of new tasks for the period %1–%2 is started'; fa = 'Scheduled notification of new tasks for the period %1–%2 is started';
																		|it = 'Iniziata una notifica di routine sui nuovi obiettivi per il periodo %1 - %2';
																		|pl = 'Rozpoczęto reglamentowane powiadomienie o nowych zadaniach za okres %1 - %2';
																		|tr = '%1–%2 dönemi için yeni görevlerin planlanmış bildirimi başladı'"),
		LatestNotificationDate, NotificationDate3));
	
	TasksByPerformers = SelectNewTasksByPerformers(LatestNotificationDate, NotificationDate3);
	Recipients = CommonClientServer.CollapseArray(TasksByPerformers.Rows.UnloadColumn("Performer"));
	RecipientsAddresses = Emails(Recipients);
	For Each PerformerRow In TasksByPerformers.Rows Do
		SendNotificationOnNewTasks(PerformerRow.Performer, PerformerRow, RecipientsAddresses);
	EndDo;
	
	SetPrivilegedMode(True);
	Constants.NewTasksNotificationDate.Set(NotificationDate3);
	SetPrivilegedMode(False);
	
	WriteLogEvent(MessageKind, EventLogLevel.Information,,,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã hoàn tất thông báo định kỳ về các nhiệm vụ mới (đã thông báo cho người thực hiện: %1)';
																		|ru = 'Завершено регламентное уведомление о новых задачах (уведомлено исполнителей: %1)';
																		|en = 'Scheduled notification of new tasks is completed (notified assignees: %1)'; fa = 'Scheduled notification of new tasks is completed (notified assignees: %1)';
																		|it = 'Notifica di routine sui nuovi compiti terminata (esecutori informati: %1)';
																		|pl = 'Zakończono powiadomienie reglamentowane o nowych zadaniach (powiadomiono wykonawców: %1)';
																		|tr = 'Yeni görevlerin planlanmış bildirimi tamamlandı (bildirilen atanan: %1)'"),
		TasksByPerformers.Rows.Count()));
	
EndProcedure

// Runs notification mailing to task assignees and authors on overdue tasks.
// Notifications are sent using email on behalf of the system account.
// If a task is sent to a role with no assignee,
// a new task to the persons responsible for role setting is created.
//
// Also it is the TaskMonitoring scheduled job handler.
//
Procedure CheckTasks() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.TaskMonitoring);
	ErrorDescription = "";
	
	If Not SystemEmailAccountIsSetUp(ErrorDescription) Then
		MessageKind = NStr("vi = 'Quy trình nghiệp vụ và nhiệm vụ.Kiểm soát nhiệm vụ';
							|ru = 'Бизнес-процессы и задачи.Мониторинг задач';
							|en = 'Business processes and tasks.Task monitoring'; fa = 'Business processes and tasks.Task monitoring';
							|it = 'Processi e obiettivi aziendali. Monitoraggio degli obiettivi';
							|pl = 'Procesy biznesowe i zadania. Monitorowanie zadań';
							|tr = 'İş süreçleri ve görevler.Görev izlemesi'", Common.DefaultLanguageCode());
		WriteLogEvent(MessageKind, EventLogLevel.Error,
			Metadata.ScheduledJobs.TaskMonitoring,, ErrorDescription);
			Return;
	EndIf;

	OverdueTasks = OverdueTasksList();
	If OverdueTasks.Count() = 0 Then
		Return;
	EndIf;
		
	OverdueTasksEmails = OverdueTasksEmails(OverdueTasks);
	For Each MailMessage In OverdueTasksEmails Do
		SendNotifAboutOverdueTask(MailMessage);
	EndDo;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// Prepares the first portion of objects for deferred access rights processing.
// It is intended to call from deferred update handlers on changing the logic of generating access value sets.
//
// Parameters:
//   Parameters     - Structure - structure of deferred update handler parameters.
//   BusinessProcess - MetadataObjectBusinessProcess  - business process metadata whose access value sets
//                   are to be updated.
//   ProcedureName  - String - a name of procedure of deferred update handler for the event log.
//   PortionSize  - Number  - a number of objects processed in one call.
//
Procedure StartUpdateAccessValuesSetsPortion(Parameters, BusinessProcess, ProcedureName, PortionSize = 1000) Export
	
	If Parameters.ExecutionProgress.TotalObjectCount = 0 Then
		Query = New Query;
		Query.Text =
			"SELECT
			|	COUNT(TableWithAccessValueSets.Ref) AS Count,
			|	MAX(TableWithAccessValueSets.Date) AS Date
			|FROM
			|	#Table AS TableWithAccessValueSets";
		
		Query.Text = StrReplace(Query.Text, "#Table", BusinessProcess.FullName());
		QueryResult = Query.Execute().Unload();
		Parameters.ExecutionProgress.TotalObjectCount = QueryResult[0].Count;
		
		If Not Parameters.Property("InitialDataForProcessing") Then
			Parameters.Insert("InitialDataForProcessing", QueryResult[0].Date);
		EndIf;
		
	EndIf;
	
	If Not Parameters.Property("ObjectsWithIssues") Then
		Parameters.Insert("ObjectsWithIssues", New Array);
	EndIf;
	
	If Not Parameters.Property("InitialRefForProcessing") Then
		Parameters.Insert("InitialRefForProcessing", Common.ObjectManagerByFullName(BusinessProcess.FullName()).EmptyRef());
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT TOP 1
		|	TableWithAccessValueSets.Ref AS Ref,
		|	TableWithAccessValueSets.Date AS Date
		|FROM
		|	#Table AS TableWithAccessValueSets
		|WHERE TableWithAccessValueSets.Date <= &InitialDataForProcessing
		|   AND TableWithAccessValueSets.Ref > &InitialRefForProcessing
		|ORDER BY 
		|   Date DESC,
		|   Ref";
	
	Query.Text = StrReplace(Query.Text, "SELECT TOP 1", "SELECT TOP " + Format(PortionSize, "NG=0")); //@Query-part-1, @Query-part-2
	Query.Text = StrReplace(Query.Text, "#Table", BusinessProcess.FullName());
	Query.SetParameter("InitialDataForProcessing", Parameters.InitialDataForProcessing);
	Query.SetParameter("InitialRefForProcessing", Parameters.InitialRefForProcessing);
	
	QueryResult = Query.Execute().Unload();
	ObjectsToBeProcessed = QueryResult.UnloadColumn("Ref");
	Parameters.Insert("ObjectsToBeProcessed", ObjectsToBeProcessed);
	
	CommonClientServer.SupplementArray(Parameters.ObjectsToBeProcessed, Parameters.ObjectsWithIssues);
	Parameters.ObjectsWithIssues.Clear();
	
	Parameters.ProcessingCompleted = ObjectsToBeProcessed.Count() = 0 
		Or QueryResult[0].Ref = Parameters.InitialRefForProcessing;
	If Not Parameters.ProcessingCompleted Then
		
		If Not Parameters.Property("BusinessProcess") Then
			Parameters.Insert("BusinessProcess", BusinessProcess);
		EndIf;
		
		If Not Parameters.Property("ObjectsProcessed") Then
			Parameters.Insert("ObjectsProcessed", 0);
		EndIf;
		
		If Not Parameters.Property("ProcedureName") Then
			Parameters.Insert("ProcedureName", ProcedureName);
		EndIf;
		
		Parameters.InitialDataForProcessing = QueryResult[QueryResult.Count() - 1].Date;
		Parameters.InitialRefForProcessing = QueryResult[QueryResult.Count() - 1].Ref;
	EndIf;
	
EndProcedure

// Complete processing of the first portion of objects for deferred access right processing.
// It is intended to call from deferred update handlers on changing the logic of generating access value sets.
//
// Parameters:
//   Parameters - Structure - parameters of the deferred update handler.
//
Procedure FinishUpdateAccessValuesSetsPortions(Parameters) Export
	
	Parameters.ExecutionProgress.ProcessedObjectsCount1 = Parameters.ExecutionProgress.ProcessedObjectsCount1 + Parameters.ObjectsProcessed;
	If Parameters.ObjectsProcessed = 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thủ tục ""%1"" không thể cập nhật quyền truy cập đối với một số đối tượng (bị bỏ qua): %2';
				|ru = 'Процедуре ""%1"" не удалось обновить права доступа для некоторых объектов (пропущены): %2';
				|en = 'Procedure ""%1"" cannot update access rights for some objects (skipped): %2'; fa = 'Procedure ""%1"" cannot update access rights for some objects (skipped): %2';
				|it = 'Alla procedura ""%1"" non è stato possibile aggiornare i permessi di accesso per alcuni oggetti (ignorati): %2';
				|pl = 'Procedurze ""%1"" nie udało się zaktualizować praw dostępu dla niektórych obiektów (pominięte): %2';
				|tr = '""%1"" prosedürü bazı nesneler için erişim haklarını güncelleyemiyor (atlandı): %2'"),
				Parameters.ProcedureName, Parameters.ObjectsWithIssues.Count());
		Raise MessageText;
	EndIf;
	
	WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
		Parameters.BusinessProcess,, 
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Quy trình ""%1"" đã cập nhật quyền truy cập phần đối tượng tiếp theo: %2';
																		|ru = 'Процедура ""%1"" обновила права доступа для очередной порции объектов: %2';
																		|en = 'The ""%1"" procedure has updated access rights for objects: %2'; fa = 'The ""%1"" procedure has updated access rights for objects: %2';
																		|it = 'La procedura ""%1"" ha aggiornato i permessi d''accesso per un altro gruppo di oggetti: %2';
																		|pl = 'Procedura ""%1"" zaktualizowała prawa dostępu dla kolejnej części obiektów: %2';
																		|tr = '""%1"" Prosedürü nesneler için erişim haklarını güncelledi: %2'"), 
			Parameters.ProcedureName, Parameters.ObjectsProcessed));
	
	// Clearing temporary parameters which are not required to save between the sessions.
	Parameters.Delete("ObjectsToBeProcessed");
	Parameters.Delete("ProcedureName");
	Parameters.Delete("BusinessProcess");
	Parameters.Delete("ObjectsProcessed");
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.2.2";
	Handler.InitialFilling = True;
	Handler.Procedure = "BusinessProcessesAndTasksServer.FillEmployeeResponsibleForCompletionControl";
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Version              = "2.3.3.70";
	Handler.Procedure           = "BusinessProcessesAndTasksServer.UpdateScheduledJobUsage";
	Handler.SharedData         = False;
	Handler.ExecutionMode     = "Seamless";
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "BusinessProcessesAndTasksServer.FillPredefinedItemDescriptionAllAddressingObjects";
	
	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.BusinessProcessesData.ProcessDataForMigrationToNewVersion";
	Handler.Version = "3.1.9.99";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("5137a43e-75aa-4a68-ba2f-525a3a646de8");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.BusinessProcessesData.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Điền mục tin Trạng thái trong biểu ghi Quy trình nghiệp vụ.';
							|ru = 'Заполнение реквизита Состояние в регистре Бизнес-процессы.';
							|en = 'Populate the State attribute in the ""Business processes"" information register.'; fa = 'Populate the State attribute in the ""Business processes"" information register.';
							|it = 'Заполнение реквизита Состояние в регистре Бизнес-процессы.';
							|pl = 'Populate the State attribute in the ""Business processes"" information register.';
							|tr = 'İş Süreçleri kaydındaki Durum özniteliklerinin doldurulması.'");
	Handler.ObjectsToChange = Metadata.InformationRegisters.BusinessProcessesData.FullName();
	Handler.ObjectsToLock = Metadata.InformationRegisters.BusinessProcessesData.FullName();

	ItemsToRead = New Array;
	BusinessProcessesTypes = Metadata.DefinedTypes.BusinessProcess.Type;
	If Not BusinessProcessesTypes.ContainsType(Type("String")) Then
		For Each BusinessProcessType In BusinessProcessesTypes.Types() Do 
			ItemsToRead.Add(Metadata.FindByType(BusinessProcessType).FullName());
		EndDo;	
	EndIf;
	ItemsToRead.Add(Metadata.InformationRegisters.BusinessProcessesData.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
EndProcedure

// See SSLSubsystemsIntegration.OnDeterminePerformersGroups.
Procedure OnDeterminePerformersGroups(TempTablesManager, ParameterContent, ParameterValue, NoPerformerGroups) Export
	
	NoPerformerGroups = False;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	If ParameterContent = "PerformersGroups" Then
		
		Query.SetParameter("PerformersGroups", ParameterValue);
		Query.Text =
		"SELECT DISTINCT
		|	TaskPerformers.TaskPerformersGroup AS PerformersGroup,
		|	TaskPerformers.Performer AS User
		|INTO PerformerGroupsTable
		|FROM
		|	InformationRegister.TaskPerformers AS TaskPerformers
		|WHERE
		|	TaskPerformers.TaskPerformersGroup IN(&PerformersGroups)";
		
	ElsIf ParameterContent = "Assignees" Then
		
		Query.SetParameter("Assignees", ParameterValue);
		Query.Text =
		"SELECT DISTINCT
		|	TaskPerformers.TaskPerformersGroup AS PerformersGroup,
		|	TaskPerformers.Performer AS User
		|INTO PerformerGroupsTable
		|FROM
		|	InformationRegister.TaskPerformers AS TaskPerformers
		|WHERE
		|	TaskPerformers.Performer IN(&Assignees)";
		
	Else
		Query.Text =
		"SELECT DISTINCT
		|	TaskPerformers.TaskPerformersGroup AS PerformersGroup,
		|	TaskPerformers.Performer AS User
		|INTO PerformerGroupsTable
		|FROM
		|	InformationRegister.TaskPerformers AS TaskPerformers";
	EndIf;
	
	Query.Execute();
	
EndProcedure

// StandardSubsystems.AccessManagement

// See UsersInternal.OnFillRegisteredRefKinds.
Procedure OnFillRegisteredRefKinds(RefsKinds) Export
	
	RefsKind = RefsKinds.Add();
	RefsKind.Name = "ModifiedTasksAssigneesGroups";
	RefsKind.AllowedTypes = New TypeDescription("CatalogRef.TaskPerformersGroups");
	RefsKind.ParameterNameExtensionsOperation =
		"StandardSubsystems.BusinessProcessesAndTasks.ModifiedTasksAssigneesGroupsModifiedUponImport";
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromMaster.
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender) Export
	
	OnDataGet(DataElement, ItemReceive);
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromSlave.
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender) Export
	
	OnDataGet(DataElement, ItemReceive);
	
EndProcedure

// See StandardSubsystemsServer.AfterGetData.
Procedure AfterGetData(Sender, Cancel, GetFromMasterNode) Export
	
	If InfobaseUpdate.InfobaseUpdateInProgress() Then
		Return;
	EndIf;
	
	UpdateAuxiliaryDataOfItemsModifiedUponDataImport();
	
EndProcedure

// See description in the "FillAllExtensionsParameters" procedure
// of the "ExtensionVersionParameters" information register manager module.
//
Procedure OnFillAllExtensionParameters() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	// If exceptions occurred and the update is not completed.
	UpdateAuxiliaryDataOfItemsModifiedUponDataImport();
	
EndProcedure

// End StandardSubsystems.AccessManagement

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// Cannot import to the TaskPerformersGroups catalog.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.TaskPerformersGroups.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.BusinessProcesses.Job.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Tasks.PerformerTask.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.ChartsOfCharacteristicTypes.TaskAddressingObjects.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.TaskPerformersGroups.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PerformerRoles.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
Procedure OnDefineScheduledJobSettings(Settings) Export
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.TaskMonitoring;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseBusinessProcessesAndTasks;
	Setting.UseExternalResources = True;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.NewPerformerTaskNotifications;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseBusinessProcessesAndTasks;
	Setting.UseExternalResources = True;
	Setting.EnableOnEnableFunctionalOption = False;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.StartDeferredProcesses;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseBusinessProcessesAndTasks;

EndProcedure

// See CommonOverridable.OnAddReferenceSearchExceptions.
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(Metadata.InformationRegisters.BusinessProcessesData.FullName());
	RefSearchExclusions.Add(Metadata.Catalogs.TaskPerformersGroups.FullName());
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.TaskMonitoring.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.NewPerformerTaskNotifications.Name);
	
EndProcedure

// See UserRemindersOverridable.OnFillSourceAttributesListWithReminderDates.
Procedure OnFillSourceAttributesListWithReminderDates(Source, AttributesWithDates) Export
	
	If TypeOf(Source) = Type("TaskRef.PerformerTask") Then
		AttributesWithDates.Clear();
		AttributesWithDates.Add("TaskDueDate"); 
		AttributesWithDates.Add("StartDate"); 
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessRightsDependencies.
Procedure OnFillAccessRightsDependencies(RightsDependencies) Export
	
	// The assignee's task can be modified even if its business process is read-only.
	// Therefore, don't check for the "Update" access right.
	// Instead, check if the "Read" right is granted.
	
	String = RightsDependencies.Add();
	String.SubordinateTable = "Task.PerformerTask";
	String.LeadingTable     = "BusinessProcess.Job";
	
EndProcedure

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionKinds.
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export
	
	LongDesc = LongDesc 
		+ "
		|BusinessProcess.Job.Read.Users
		|BusinessProcess.Job.Update.Users
		|Task.PerformerTask.Read.Object.BusinessProcess.Job
		|Task.PerformerTask.Read.Users
		|Task.PerformerTask.Update.Users
		|InformationRegister.BusinessProcessesData.Read.Object.BusinessProcess.Job
		|";
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessKinds.
Procedure OnFillAccessKinds(AccessKinds) Export
	
	AccessKind = AccessKinds.Find("Users", "Name");
	If AccessKind <> Undefined Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AddExtraAccessKindTypes(AccessKind,
			Type("CatalogRef.TaskPerformersGroups"));
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.InformationRegisters.BusinessProcessesData, True);
	Lists.Insert(Metadata.InformationRegisters.TaskPerformers, True);
	Lists.Insert(Metadata.BusinessProcesses.Job, True);
	Lists.Insert(Metadata.Tasks.PerformerTask, True);
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.BusinessProcesses);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.HungTasks);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.Jobs);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.Tasks);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ExpiringTasksOnDate);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.OverdueTasks);
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("Edit", Metadata.Tasks.PerformerTask)
		Or ModuleToDoListServer.UserTaskDisabled("PerformerTasks") Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseBusinessProcessesAndTasks") Then
		Return;
	EndIf;
	
	PerformerTaskQuantity = PerformerTaskQuantity();
	
	// The procedure can be called only if the "To-do list" subsystem is integrated.
	// Therefore, don't check if the subsystem is integrated.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Tasks.PerformerTask.FullName());
	
	If Users.IsExternalUserSession()
		And Sections.Count() = 0 Then
		Sections.Add(Metadata.Tasks.PerformerTask);
	EndIf;
	
	For Each Section In Sections Do
		
		MyTasksID = "PerformerTasks" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = MyTasksID;
		ToDoItem.HasToDoItems       = PerformerTaskQuantity.Total > 0;
		ToDoItem.Presentation  = NStr("vi = 'Nhiệm vụ của tôi';
										|ru = 'Мои задачи';
										|en = 'My Tasks'; fa = 'وظایف من';
										|it = 'I miei obiettivi';
										|pl = 'Moje zadania';
										|tr = 'Görevlerim'");
		ToDoItem.Count     = PerformerTaskQuantity.Total;
		ToDoItem.Form          = "Task.PerformerTask.Form.MyTasks";
		FilterValue		= New Structure("Executed", False);
		ToDoItem.FormParameters = New Structure("Filter", FilterValue);
		ToDoItem.Owner       = Section;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "PerformerTasksOverdue";
		ToDoItem.HasToDoItems       = PerformerTaskQuantity.Overdue1 > 0;
		ToDoItem.Presentation  = NStr("vi = 'Quá hạn';
										|ru = 'просроченные';
										|en = 'overdue'; fa = 'overdue';
										|it = 'scaduti';
										|pl = 'overdue';
										|tr = 'süresi bitmiş'");
		ToDoItem.Count     = PerformerTaskQuantity.Overdue1;
		ToDoItem.Important         = True;
		ToDoItem.Owner       = MyTasksID; 
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "PerformerTasksForToday";
		ToDoItem.HasToDoItems       = PerformerTaskQuantity.ForToday > 0;
		ToDoItem.Presentation  = NStr("vi = 'hôm nay';
										|ru = 'сегодня';
										|en = 'today'; fa = 'today';
										|it = 'oggi';
										|pl = 'today';
										|tr = 'bugün'");
		ToDoItem.Count     = PerformerTaskQuantity.ForToday;
		ToDoItem.Owner       = MyTasksID; 

		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "PerformerTasksForWeek";
		ToDoItem.HasToDoItems       = PerformerTaskQuantity.ForWeek > 0;
		ToDoItem.Presentation  = NStr("vi = 'trong tuần này';
										|ru = 'на этой неделе';
										|en = 'this week'; fa = 'this week';
										|it = 'in questa settimana';
										|pl = 'w tym tygodniu';
										|tr = 'bu hafta'");
		ToDoItem.Count     = PerformerTaskQuantity.ForWeek;
		ToDoItem.Owner       = MyTasksID; 

		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "PerformerTasksForNextWeek";
		ToDoItem.HasToDoItems       = PerformerTaskQuantity.ForNextWeek > 0;
		ToDoItem.Presentation  = NStr("vi = 'vào tuần tới';
										|ru = 'на следующей неделе';
										|en = 'next week'; fa = 'next week';
										|it = 'nella prossima settimana';
										|pl = 'w przyszłym tygodniu';
										|tr = 'gelecek hafta'");
		ToDoItem.Count     = PerformerTaskQuantity.ForNextWeek > 0;
		ToDoItem.Owner       = MyTasksID; 
	EndDo;
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("BusinessProcessesAndTasksEvents.StartDeferredProcesses");
	
EndProcedure

// See also InfobaseUpdateOverridable.OnDefineSettings
//
// Parameters:
//  Objects - Array of MetadataObject
//
Procedure OnDefineObjectsWithInitialFilling(Objects) Export
	
	Objects.Add(Metadata.Catalogs.PerformerRoles);
	Objects.Add(Metadata.ChartsOfCharacteristicTypes.TaskAddressingObjects);
	
EndProcedure

// See GenerateFromOverridable.OnDefineObjectsWithCreationBasedOnCommands.
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export
	
	Objects.Add(Metadata.BusinessProcesses.Job);
	Objects.Add(Metadata.Tasks.PerformerTask);
	
EndProcedure

// See GenerateFromOverridable.OnAddGenerationCommands.
Procedure OnAddGenerationCommands(Object, GenerationCommands, Parameters, StandardProcessing) Export
	
	If Object = Metadata.Catalogs.Users Then
		BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
		If ModuleFilesOperationsInternal.IsDirectoryFiles(Object) Then
			BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure OnForwardTask(TaskObject, NewTaskObject) 
	
	If TaskObject.BusinessProcess = Undefined Or TaskObject.BusinessProcess.IsEmpty() Then
		Return;
	EndIf;
	
	AttachedBusinessProcesses = New Map;
	AttachedBusinessProcesses.Insert(Metadata.BusinessProcesses.Job.FullName(), "");
	BusinessProcessesAndTasksOverridable.OnDetermineBusinessProcesses(AttachedBusinessProcesses);
	
	BusinessProcessType = TaskObject.BusinessProcess.Metadata();
	BusinessProcessInfo = AttachedBusinessProcesses[BusinessProcessType.FullName()];
	If BusinessProcessInfo <> Undefined Then 
		BusinessProcesses[BusinessProcessType.Name].OnForwardTask(TaskObject.Ref, NewTaskObject.Ref);
	EndIf;
	
EndProcedure

#Region MonitoringAndCompletionControl

Function ExportPerformers(QueryText, MainAddressingObjectRef = Undefined, 
	AdditionalAddressingObjectRef = Undefined)
	
	Query = New Query(QueryText);
	
	If ValueIsFilled(AdditionalAddressingObjectRef) Then
		Query.SetParameter("AAO", AdditionalAddressingObjectRef);
	EndIf;
	
	If ValueIsFilled(MainAddressingObjectRef) Then
		Query.SetParameter("MAO", MainAddressingObjectRef);
	EndIf;
	
	Return Query.Execute().Unload().UnloadColumn("Performer");
	
EndFunction

Function FindPersonsResponsibleForRolesAssignment(MainAddressingObject, AdditionalAddressingObject)
	
	QueryTemplate = 
		"SELECT DISTINCT ALLOWED
		|	TaskPerformers.Performer
		|FROM
		|	InformationRegister.TaskPerformers AS TaskPerformers
		|		LEFT JOIN Catalog.PerformerRoles AS PerformerRoles
		|		ON TaskPerformers.PerformerRole = PerformerRoles.Ref
		|WHERE
		|	PerformerRoles.Ref = VALUE(Catalog.PerformerRoles.EmployeeResponsibleForTasksManagement)
		|	AND &ConditionByAddressingObjects";
	
	If ValueIsFilled(AdditionalAddressingObject) Then
		ConditionByAddressingObjects = "TaskPerformers.MainAddressingObject = &MAO
			|	AND TaskPerformers.AdditionalAddressingObject = &AAO"; // @Query-part
	ElsIf ValueIsFilled(MainAddressingObject) Then
		ConditionByAddressingObjects =
			"TaskPerformers.MainAddressingObject = &MAO
			|	AND (TaskPerformers.AdditionalAddressingObject = VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.EmptyRef)
			|	OR TaskPerformers.AdditionalAddressingObject = UNDEFINED)"; // @Query-part
	Else
		ConditionByAddressingObjects =
			"(TaskPerformers.MainAddressingObject = VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.EmptyRef)
			|		OR TaskPerformers.MainAddressingObject = UNDEFINED)
			|	AND (TaskPerformers.AdditionalAddressingObject = VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.EmptyRef)
			|		OR TaskPerformers.AdditionalAddressingObject = UNDEFINED)"; // @Query-part
	EndIf;

	QueryText = StrReplace(QueryTemplate, "&ConditionByAddressingObjects", ConditionByAddressingObjects);
	Assignees = ExportPerformers(QueryText, MainAddressingObject, AdditionalAddressingObject);
	
	// If the main and additional business objects are not specified in the task.
	If Not ValueIsFilled(AdditionalAddressingObject) And Not ValueIsFilled(MainAddressingObject) Then
		Return Assignees;
	EndIf;
	
	If Assignees.Count() = 0 And ValueIsFilled(AdditionalAddressingObject) Then
		ConditionByAddressingObjects =
			"TaskPerformers.MainAddressingObject = &MAO
			|	AND (TaskPerformers.AdditionalAddressingObject = VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.EmptyRef)
			|	OR TaskPerformers.AdditionalAddressingObject = UNDEFINED)"; // @Query-part
		QueryText = StrReplace(QueryTemplate, "&ConditionByAddressingObjects", ConditionByAddressingObjects);
		Assignees = ExportPerformers(QueryText, MainAddressingObject);
	EndIf;
	
	If Assignees.Count() = 0 Then
		ConditionByAddressingObjects =
			"(TaskPerformers.MainAddressingObject = VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.EmptyRef)
			|		OR TaskPerformers.MainAddressingObject = UNDEFINED)
			|	AND (TaskPerformers.AdditionalAddressingObject = VALUE(ChartOfCharacteristicTypes.TaskAddressingObjects.EmptyRef)
			|		OR TaskPerformers.AdditionalAddressingObject = UNDEFINED)"; // @Query-part
		QueryText = StrReplace(QueryTemplate, "&ConditionByAddressingObjects", ConditionByAddressingObjects);
		Assignees = ExportPerformers(QueryText);
	EndIf;
	
	Return Assignees;
	
EndFunction

Function TaskPerformers(Var_Tasks)
	
	Result = New Structure;
	Result.Insert("Assignees", New Array);
	Result.Insert("ByTasks", New Map);

	QueryText = 
		"SELECT DISTINCT ALLOWED
		|	PerformerTask.Ref AS PerformerTask,
		|	TaskPerformers.Performer AS Performer
		|FROM
		|	Task.PerformerTask AS PerformerTask
		|		LEFT JOIN InformationRegister.TaskPerformers AS TaskPerformers
		|		ON TaskPerformers.PerformerRole = PerformerTask.PerformerRole
		|		AND TaskPerformers.MainAddressingObject = PerformerTask.MainAddressingObject
		|		AND TaskPerformers.AdditionalAddressingObject = PerformerTask.AdditionalAddressingObject
		|WHERE
		|	PerformerTask.Ref IN (&Tasks)
		|
		|ORDER BY
		|	PerformerTask.Ref";
		
	Query = New Query(QueryText);
	Query.SetParameter("Tasks", Var_Tasks);
	QuerySelection = Query.Execute().Select();
	While QuerySelection.Next() Do
		TaskAssignees = Result.ByTasks[QuerySelection.PerformerTask];
		If TaskAssignees = Undefined Then
			TaskAssignees = New Array;
			Result.ByTasks[QuerySelection.PerformerTask] = TaskAssignees;
		EndIf;
		If ValueIsFilled(QuerySelection.Performer) Then
			TaskAssignees.Add(QuerySelection.Performer);
			Result.Assignees.Add(QuerySelection.Performer);
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

Procedure FindMessageAndAddText(Val MessageSetByAddressees, Val EmailRecipient,
	Val MessageRecipientPresentation, Val EmailText, Val EmailType)
	
	If Not ValueIsFilled(EmailRecipient) Then
		Return;
	EndIf;
	
	FilterParameters = New Structure("EmailType, MailAddress", EmailType, EmailRecipient);
	EmailParametersRow = MessageSetByAddressees.FindRows(FilterParameters);
	If EmailParametersRow.Count() = 0 Then
		EmailParametersRow = Undefined;
	Else
		EmailParametersRow = EmailParametersRow[0];
	EndIf;
	
	If EmailParametersRow = Undefined Then
		EmailParametersRow = MessageSetByAddressees.Add();
		EmailParametersRow.MailAddress = EmailRecipient;
		EmailParametersRow.EmailText = "";
		EmailParametersRow.TaskCount = 0;
		EmailParametersRow.EmailType = EmailType;
		EmailParametersRow.Recipient = MessageRecipientPresentation;
	EndIf;
	
	If ValueIsFilled(EmailParametersRow.EmailText) Then
		EmailParametersRow.EmailText =
		        EmailParametersRow.EmailText + Chars.LF
		        + "------------------------------------"  + Chars.LF;
	EndIf;
	
	EmailParametersRow.TaskCount = EmailParametersRow.TaskCount + 1;
	EmailParametersRow.EmailText = EmailParametersRow.EmailText + EmailText;
	
EndProcedure

// Returns:
//  ValueTable:
//    * Ref - TaskRef.PerformerTask
//    * TaskDueDate - Date
//    * Performer - CatalogRef.ExternalUsers
//                  - CatalogRef.Users
//    * PerformerRole - CatalogRef.PerformerRoles
//    * MainAddressingObject - Characteristic.TaskAddressingObjects
//    * AdditionalAddressingObject - Characteristic.TaskAddressingObjects
//    * Author - CatalogRef.ExternalUsers
//            - CatalogRef.Users
//    * LongDesc - String
// 
Function OverdueTasksList()

	QueryText = 
		"SELECT ALLOWED
		|	PerformerTask.Ref AS Ref,
		|	PerformerTask.TaskDueDate AS TaskDueDate,
		|	PerformerTask.Performer AS Performer,
		|	PerformerTask.PerformerRole AS PerformerRole,
		|	PerformerTask.MainAddressingObject AS MainAddressingObject,
		|	PerformerTask.AdditionalAddressingObject AS AdditionalAddressingObject,
		|	PerformerTask.Author AS Author,
		|	PerformerTask.LongDesc AS LongDesc
		|FROM
		|	Task.PerformerTask AS PerformerTask
		|WHERE
		|	PerformerTask.DeletionMark = FALSE
		|	AND PerformerTask.Executed = FALSE
		|	AND PerformerTask.TaskDueDate <= &Date
		|	AND PerformerTask.BusinessProcessState <> VALUE(Enum.BusinessProcessStates.Suspended)";
	
	TaskDueDate = EndOfDay(CurrentSessionDate());

	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Date", TaskDueDate);
	
	OverdueTasks = Query.Execute().Unload();
	
	SelectionBusinessProcesses = SelectBusinessProcessesOfHeadTasks(OverdueTasks.UnloadColumn("Ref"));
	IndexOf = OverdueTasks.Count() - 1;
	Filter = New Structure("HeadTask"); 
	While IndexOf >= 0 Do
		OverdueTask = OverdueTasks.Get(IndexOf);
		IndexOf = IndexOf - 1;
		If ValueIsFilled(OverdueTask.Performer) Then
			Continue;
		EndIf;
		SelectionBusinessProcesses.Reset();
		Filter.HeadTask = OverdueTask.Ref; 
		If SelectionBusinessProcesses.FindNext(Filter) Then
			OverdueTasks.Delete(OverdueTask);
		EndIf;
	EndDo;
	
	Return OverdueTasks;
	
EndFunction

Function OverdueTasksEmails(OverdueTasks)
	
	TasksCoordinators = New Map;
	EmailsRecipients = New Array;
	TasksWithRoleAddressing = New Array;
	For Each OverdueTask In OverdueTasks Do
		OverdueTaskRef = OverdueTask.Ref;
		AddEmailRecipient(EmailsRecipients, OverdueTask.Author, OverdueTaskRef, NStr("ru = 'Автор';
																					|vi = 'Author';
																					|en = 'Author'; fa = 'ایجادکننده';
																					|it = 'Author';
																					|pl = 'Author';
																					|tr = 'Oluşturan'"));
		If ValueIsFilled(OverdueTask.Performer) Then
			AddEmailRecipient(EmailsRecipients, OverdueTask.Performer, OverdueTaskRef, NStr("ru = 'Исполнитель';
																							|vi = 'Assignee';
																							|en = 'Assignee'; fa = 'Assignee';
																							|it = 'Assignee';
																							|pl = 'Assignee';
																							|tr = 'İcracı'"));
		Else
			TasksWithRoleAddressing.Add(OverdueTask);
			//@skip-check query-in-loop
			Coordinators = FindPersonsResponsibleForRolesAssignment(OverdueTask.MainAddressingObject, 
				OverdueTask.AdditionalAddressingObject);
			TasksCoordinators[OverdueTaskRef] = Coordinators;
			For Each Coordinator In Coordinators Do
				AddEmailRecipient(EmailsRecipients, Coordinator, OverdueTaskRef, NStr("ru = 'Координатор';
																						|vi = 'Coordinator';
																						|en = 'Coordinator'; fa = 'هماهنگ‌کننده';
																						|it = 'Coordinator';
																						|pl = 'Coordinator';
																						|tr = 'Koordinatör'"));
			EndDo;
		EndIf;
	EndDo;

	TaskPerformers = TaskPerformers(TasksWithRoleAddressing);
	CommonClientServer.SupplementArray(EmailsRecipients, TaskPerformers.Assignees);
	EmailsRecipients = CommonClientServer.CollapseArray(EmailsRecipients);
	
	UsersDetails = Common.ObjectsAttributesValues(EmailsRecipients, "Invalid,DeletionMark");
	
	Position = EmailsRecipients.UBound();
	While Position >= 0 Do
		UserDetails = UsersDetails[EmailsRecipients[Position]];
		If UserDetails = Undefined
			Or UserDetails.Invalid
			Or UserDetails.DeletionMark Then
			EmailsRecipients.Delete(Position);
		EndIf;
		Position = Position - 1;
	EndDo;
	
	RecipientsAddresses = Emails(EmailsRecipients);

	MessageSetByAddressees = New ValueTable;
	MessageSetByAddressees.Columns.Add("MailAddress");
	MessageSetByAddressees.Columns.Add("EmailText");
	MessageSetByAddressees.Columns.Add("TaskCount");
	MessageSetByAddressees.Columns.Add("EmailType");
	MessageSetByAddressees.Columns.Add("Recipient");
	MessageSetByAddressees.Indexes.Add("EmailType, MailAddress");
	
	For Each OverdueTask In OverdueTasks Do
		OverdueTaskRef = OverdueTask.Ref;
		
		EmailText = GenerateTaskPresentation(OverdueTask);
		If ValueIsFilled(OverdueTask.Performer) Then
			EmailRecipient = Email(RecipientsAddresses, OverdueTask.Performer);
			FindMessageAndAddText(MessageSetByAddressees, EmailRecipient, OverdueTask.Performer, EmailText, "ToPerformer");
		Else
			Assignees = TaskPerformers.ByTasks[OverdueTaskRef];
			Coordinators = TasksCoordinators[OverdueTaskRef];
			
			If Assignees.Count() > 0 Then
				For Each Performer In Assignees Do
					EmailRecipient = Email(RecipientsAddresses, Performer);
					FindMessageAndAddText(MessageSetByAddressees, EmailRecipient, Performer, EmailText, "ToPerformer");
				EndDo;
			Else	// There is no assignee to perform the task.
				CreateTaskForSettingRoles(OverdueTaskRef, Coordinators);
			EndIf;
			
			For Each Coordinator In Coordinators Do
				EmailRecipient = Email(RecipientsAddresses, Coordinator);
				FindMessageAndAddText(MessageSetByAddressees, EmailRecipient, Coordinator, EmailText, "ToCoordinator");
			EndDo;
		EndIf;
		EmailRecipient = Email(RecipientsAddresses, OverdueTask.Author);
		FindMessageAndAddText(MessageSetByAddressees, EmailRecipient, OverdueTask.Author, EmailText, "ToAuthor");
	EndDo;
	
	Return MessageSetByAddressees;
	
EndFunction

Procedure AddEmailRecipient(EmailsRecipients, EmailRecipient, ObjectReference, Details_3 = "")
	
	If Not ValueIsFilled(EmailRecipient) Then
		LogText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'У задачи %1 не заполнен %2. Задача не может быть обработана.
			|Необходимо заполнить обязательные реквизиты или удалить задачу.';
			|vi = 'The %2 is not filled out for the %1 task.
			|Please fill out the required attributes or remove the task.';
			|en = 'The %2 is not filled out for the %1 task.
			|Please fill out the required attributes or remove the task.'; fa = 'The %2 is not filled out for the %1 task.
			|Please fill out the required attributes or remove the task.';
			|it = 'The %2 is not filled out for the %1 task.
			|Please fill out the required attributes or remove the task.';
			|pl = 'The %2 is not filled out for the %1 task.
			|Please fill out the required attributes or remove the task.';
			|tr = '%1 görevinin %2 alanı doldurulmamış. Görev işlenemez.
			| Zorunlu alanların doldurulması veya görevin silinmesi gerekmektedir.'"),
					ObjectReference, Details_3);
		
		ObjectMetadata = Metadata.FindByType(TypeOf(ObjectReference));
		EventLog.AddMessageForEventLog(EventLogEvent(),
			EventLogLevel.Error,ObjectMetadata, ObjectReference, LogText);
		Return;
		
	EndIf;
	
	EmailsRecipients.Add(EmailRecipient);
	
EndProcedure

Procedure SendNotifAboutOverdueTask(MailMessage)
	
	If IsBlankString(MailMessage.MailAddress) Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa gửi thông báo, bởi vì chưa đặt địa chỉ email cho người thực hiện nhiệm vụ %1.';
				|ru = 'Уведомление не было отправлено, так как не задан адрес электронной почты у исполнителя задачи %1.';
				|en = 'The notification is not sent as the email address of the %1 task assignee is not specified.'; fa = 'The notification is not sent as the email address of the %1 task assignee is not specified.';
				|it = 'Уведомление не было отправлено, так как не задан адрес электронной почты у исполнителя задачи %1.';
				|pl = 'The notification is not sent as the email address of the %1 task assignee is not specified.';
				|tr = '%1 görevlerine atananların e-posta adresi belirtilmediğinden bildirim gönderilmedi.'"), 
			Common.SubjectString(MailMessage.Recipient));
		WriteLogEvent(NStr("vi = 'Quy trình nghiệp vụ và nhiệm vụ.Thông báo về các nhiệm vụ quá hạn';
							|ru = 'Бизнес-процессы и задачи.Уведомление о просроченных задачах';
							|en = 'Business processes and tasks.Overdue task notification'; fa = 'Business processes and tasks.Overdue task notification';
							|it = 'Processi aziendali e compiti. Notifica sui compiti scaduti';
							|pl = 'Procesy biznesowe i zadania. Powiadomienie o zaległych zadaniach';
							|tr = 'İş süreçleri ve görevler. Vadesi geçmiş görevler bildirimi'", 
			Common.DefaultLanguageCode()),
			EventLogLevel.Information,,, MessageText);
		Return;
	EndIf;
	
	EmailParameters = New Structure;
	EmailParameters.Insert("Whom", MailMessage.MailAddress);
	If MailMessage.EmailType = "ToPerformer" Then
		MessageBodyText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không phải tất cả nhiệm vụ đều đúng hạn:
			| 
			|%1';
			|ru = 'Не выполненные в срок задачи:
			| 
			|%1';
			|en = 'Overdue tasks:
			|
			|%1'; fa = 'Overdue tasks:
			|
			|%1';
			|it = 'Obiettivi non completati in tempo:
			| 
			|%1';
			|pl = 'Zaległe zadania: 
			| 
			|%1';
			|tr = 'Vadesi geçmiş görevler: 
			|
			|%1'"), MailMessage.EmailText);
		EmailParameters.Insert("Body", MessageBodyText);
		
		EmailSubjectText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không phải tất cả nhiệm vụ đều đúng hạn (%1)';
																						|ru = 'Не выполненные в срок задачи (%1)';
																						|en = 'Overdue tasks (%1)'; fa = 'Overdue tasks (%1)';
																						|it = 'Obiettivi non completati in tempo (%1)';
																						|pl = 'Zaległe zadania (%1)';
																						|tr = 'Vadesi geçmiş görevler (%1)'"),
			String(MailMessage.TaskCount ));
		EmailParameters.Insert("Subject", EmailSubjectText);
	ElsIf MailMessage.EmailType = "ToAuthor" Then
		MessageBodyText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Các nhiệm vụ được nhập đã qua hạn chót:
			| 
			|%1';
			|ru = 'По введенным задачам прошел крайний срок:
			| 
			|%1';
			|en = 'Deadline for specified tasks expired:
			|
			|%1'; fa = 'Deadline for specified tasks expired:
			|
			|%1';
			|it = 'Il termine massimo dei obiettivi immessi è stato superato:
			| 
			|%1';
			|pl = 'Według wprowadzonych zadań minął ostateczny termin: 
			| 
			|%1';
			|tr = 'Belirtilen görevlerin bitiş tarihi geçti: 
			|
			|%1'"), MailMessage.EmailText);
		EmailParameters.Insert("Body", MessageBodyText);
		
		EmailSubjectText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Theo nhiệm vụ đã quá thời hạn kiểm soát (%1)';
																						|ru = 'По задачам истек контрольный срок (%1)';
																						|en = 'Task deadline expired (%1)'; fa = 'Task deadline expired (%1)';
																						|it = 'Il termine massimo degli obiettivi è scaduto (%1)';
																						|pl = 'Według zadań minął kontrolny termin (%1)';
																						|tr = 'Görevin bitiş tarihi geçti (%1)'"),
			String(MailMessage.TaskCount));
		EmailParameters.Insert("Subject", EmailSubjectText);
	ElsIf MailMessage.EmailType = "ToCoordinator" Then
		MessageBodyText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Các nhiệm vụ đã qua hạn chót: 
			| 
			|%1';
			|ru = 'Прошел крайний срок по задачам:
			| 
			|%1';
			|en = 'Deadline for tasks has passed:
			| 
			|%1'; fa = 'Deadline for tasks has passed:
			| 
			|%1';
			|it = 'È stato superato il termine massimo degli obiettivi:
			| 
			|%1';
			|pl = 'Minął ostateczny termin według zadań: 
			| 
			|%1';
			|tr = 'Görevlerin bitiş tarihi geçti: 
			| 
			|%1'"), MailMessage.EmailText);
		EmailParameters.Insert("Body", MessageBodyText);
		
		EmailSubjectText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Nhiệm vụ đã qua hạn kiểm soát (%1)';
																						|ru = 'Истек контрольный срок задач (%1)';
																						|en = 'Deadline for tasks (%1) expired'; fa = 'Deadline for tasks (%1) expired';
																						|it = 'Scaduto il termine massimo degli obiettivi (%1)';
																						|pl = 'Minął kontrolny termin zadań (%1)';
																						|tr = 'Görevin bitiş tarihi geçti (%1)'"),
			String(MailMessage.TaskCount));
		EmailParameters.Insert("Subject", EmailSubjectText);
	EndIf;
	
	MessageText = "";
	
	ModuleEmailOperations = Common.CommonModule("EmailOperations");
	ModuleEmailOperationsInternalClientServer = Common.CommonModule(
		"EmailOperationsInternalClientServer");
	
	Account = ModuleEmailOperations.SystemAccount();
	MailMessage = ModuleEmailOperations.PrepareEmail(Account, EmailParameters);
	Try
		ModuleEmailOperations.SendMail(Account, MailMessage);
	Except
		ErrorInfo = ErrorInfo();
		
		If Not ModuleEmailOperationsInternalClientServer.IsInternetMailError(
			ErrorInfo) Then
			
			Raise;
		EndIf;
		
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa gửi thông báo về nhiệm vụ quá hạn do nguyên nhân: 
				|%1.';
				|ru = 'Не отправлены уведомления о просроченных задачах по причине: 
				|%1.';
				|en = 'Overdue task notifications are not sent due to: 
				|%1.'; fa = 'Overdue task notifications are not sent due to: 
				|%1.';
				|it = 'Не отправлены уведомления о просроченных задачах по причине: 
				|%1.';
				|pl = 'Overdue task notifications are not sent due to: 
				|%1.';
				|tr = 'Vadesi geçmiş görev bildirimi şu nedenlerle gönderilmedi:
				|%1.'"),
			ErrorDescription);
		EventImportanceLevel = EventLogLevel.Error;
	EndTry;
	
	If IsBlankString(MessageText) Then
		If EmailParameters.Whom.Count() > 0 Then
			Whom = ? (IsBlankString(EmailParameters.Whom[0].Presentation),
						EmailParameters.Whom[0].Address,
						EmailParameters.Whom[0].Presentation + " <" + EmailParameters.Whom[0].Address + ">");
		EndIf;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã gửi thành công thông báo về nhiệm vụ quá hạn đến địa chỉ %1.';
				|ru = 'Уведомление о просроченных задачах успешно отправлено на адрес %1.';
				|en = 'Overdue task notification sent to %1.'; fa = 'Overdue task notification sent to %1.';
				|it = 'Notifica sugli obiettivi scaduti inviata correttamente all''indirizzo %1.';
				|pl = 'Powiadomienie zaległych zadaniach pomyślnie wysłano na adres %1.';
				|tr = 'Vadesi geçmiş görev bildirimi %1 adresine gönderildi.'"), Whom);
		EventImportanceLevel = EventLogLevel.Information;
	EndIf;
	
	WriteLogEvent(NStr("vi = 'Quy trình nghiệp vụ và nhiệm vụ.Thông báo về các nhiệm vụ quá hạn';
						|ru = 'Бизнес-процессы и задачи.Уведомление о просроченных задачах';
						|en = 'Business processes and tasks.Overdue task notification'; fa = 'Business processes and tasks.Overdue task notification';
						|it = 'Processi aziendali e compiti. Notifica sui compiti scaduti';
						|pl = 'Procesy biznesowe i zadania. Powiadomienie o zaległych zadaniach';
						|tr = 'İş süreçleri ve görevler. Vadesi geçmiş görevler bildirimi'",
		Common.DefaultLanguageCode()), 
		EventImportanceLevel,,, MessageText);
		
EndProcedure

Procedure CreateTaskForSettingRoles(TaskRef, EmployeesResponsible)
	
	For Each EmployeeResponsible In EmployeesResponsible Do
		TaskObject = Tasks.PerformerTask.CreateTask();
		TaskObject.Date = CurrentSessionDate();
		TaskObject.Importance = Enums.TaskImportanceOptions.High;
		TaskObject.Performer = EmployeeResponsible;
		TaskObject.SubjectOf = TaskRef;

		TaskObject.LongDesc = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể hoàn thành nhiệm vụ vì vai trò không chỉ định cho người thực hiện:
		    |%1';
		    |ru = 'Задача не может быть исполнена, так как у роли не задано ни одного исполнителя:
		    |%1';
		    |en = 'The task cannot be completed as no assignees are assigned for the role:
		    |%1'; fa = 'The task cannot be completed as no assignees are assigned for the role:
		    |%1';
		    |it = 'L''obiettivo non può essere eseguito, poiché il ruolo non ha alcun esecutore:
		    |%1';
		    |pl = 'Zadanie nie może być wykonano, ponieważ u roli nie zadano ani jednego wykonawcy: 
		    |%1';
		    |tr = 'Görev tamamlanamaz çünkü göreve atanan olmadı: 
		    |%1'"), String(TaskRef));
		TaskObject.Description = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Ấn định người thực hiện: không thể thực hiện nhiệm vụ %1';
																								|ru = 'Назначить исполнителей: задача не может быть исполнена %1';
																								|en = 'Set assignees: task %1 cannot be executed'; fa = 'Set assignees: task %1 cannot be executed';
																								|it = 'Indicare degli esecutori: l''obiettivo non può essere eseguito %1';
																								|pl = 'Wyznacz wykonawców: zadanie nie może być wykonane %1';
																								|tr = 'Atanan belirle: %1 görevi gerçekleştirilemez'"), String(TaskRef));
		TaskObject.Write();
	EndDo;
	
EndProcedure

Function SelectNewTasksByPerformers(Val DateTimeFrom, Val DateTimeTo)
	
	Query = New Query(
		"SELECT ALLOWED
		|	PerformerTask.Ref AS Ref,
		|	PerformerTask.Number AS Number,
		|	PerformerTask.Date AS Date,
		|	PerformerTask.Description AS Description,
		|	PerformerTask.TaskDueDate AS TaskDueDate,
		|	PerformerTask.Author AS Author,
		|	PerformerTask.LongDesc AS LongDesc,
		|	CASE
		|		WHEN PerformerTask.Performer <> UNDEFINED
		|			THEN PerformerTask.Performer
		|		ELSE TaskPerformers.Performer
		|	END AS Performer,
		|	PerformerTask.PerformerRole AS PerformerRole,
		|	PerformerTask.MainAddressingObject AS MainAddressingObject,
		|	PerformerTask.AdditionalAddressingObject AS AdditionalAddressingObject
		|FROM
		|	Task.PerformerTask AS PerformerTask
		|		LEFT JOIN InformationRegister.TaskPerformers AS TaskPerformers
		|		ON PerformerTask.PerformerRole = TaskPerformers.PerformerRole
		|			AND PerformerTask.MainAddressingObject = TaskPerformers.MainAddressingObject
		|			AND PerformerTask.AdditionalAddressingObject = TaskPerformers.AdditionalAddressingObject
		|WHERE
		|	PerformerTask.Executed = FALSE
		|	AND PerformerTask.Date BETWEEN &DateTimeFrom AND &DateTimeTo
		|	AND PerformerTask.DeletionMark = FALSE
		|	AND (PerformerTask.Performer <> VALUE(Catalog.Users.EmptyRef)
		|			OR TaskPerformers.Performer IS NOT NULL 
		|		AND TaskPerformers.Performer <> VALUE(Catalog.Users.EmptyRef))
		|
		|ORDER BY
		|	Performer,
		|	TaskDueDate DESC
		|TOTALS BY
		|	Performer");
	Query.Parameters.Insert("DateTimeFrom", DateTimeFrom + 1);
	Query.Parameters.Insert("DateTimeTo", DateTimeTo);
	Result = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	Return Result;
	
EndFunction

Function SendNotificationOnNewTasks(Performer, TasksByExecutive, RecipientsAddresses)
	
	RecipientEmailAddress = Email(RecipientsAddresses, Performer);
	If IsBlankString(RecipientEmailAddress) Then
		WriteLogEvent(NStr("vi = 'Quy trình nghiệp vụ và nhiệm vụ.Thông báo về các nhiệm vụ mới';
							|ru = 'Бизнес-процессы и задачи.Уведомление о новых задачах';
							|en = 'Business processes and tasks.New task notification'; fa = 'Business processes and tasks.New task notification';
							|it = 'Processi aziendali e obiettivi. Notifica sui nuovi obiettivi';
							|pl = 'Procesy biznesowe i zadania. Powiadomienie o nowych zadaniach';
							|tr = 'İş süreçleri ve görevler. Yeni görev bildirimi'", Common.DefaultLanguageCode()),
			EventLogLevel.Information,,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa gửi thông báo, bởi vì chưa chỉ định địa chỉ email cho người thực hiện nhiệm vụ %1.';
					|ru = 'Уведомление не отправлено, так как не указан почтовый адрес у исполнителя задачи %1.';
					|en = 'The notification is not sent as the email address of the %1 task assignee is not specified.'; fa = 'The notification is not sent as the email address of the %1 task assignee is not specified.';
					|it = 'Уведомление не отправлено, так как не указан почтовый адрес у исполнителя задачи %1.';
					|pl = 'The notification is not sent as the email address of the %1 task assignee is not specified.';
					|tr = '%1 görevlerine atananların e-posta adresi belirtilmediğinden bildirim gönderilmedi.'"), 
				Common.SubjectString(Performer)));
		Return False;
	EndIf;
	
	EmailText = "";
	For Each Task In TasksByExecutive.Rows Do
		EmailText = EmailText + GenerateTaskPresentation(Task);
	EndDo;
	EmailSubject = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã gửi nhiệm vụ - %1';
																				|ru = 'Направлены задачи - %1';
																				|en = 'Tasks sent- %1'; fa = 'Tasks sent- %1';
																				|it = 'Obiettivi indirizzati - %1';
																				|pl = 'Wysłane zadania - %1';
																				|tr = 'Görev gönderildi- %1'"), Metadata.BriefInformation);
	
	EmailParameters = New Structure;
	EmailParameters.Insert("Subject", EmailSubject);
	EmailParameters.Insert("Body", EmailText);
	EmailParameters.Insert("Whom", RecipientEmailAddress);
	
	ModuleEmailOperations = Common.CommonModule("EmailOperations");
	ModuleEmailOperationsInternalClientServer = Common.CommonModule(
		"EmailOperationsInternalClientServer");
	
	Account = ModuleEmailOperations.SystemAccount();
	MailMessage = ModuleEmailOperations.PrepareEmail(Account, EmailParameters);
	Try
		ModuleEmailOperations.SendMail(Account, MailMessage);
	Except
		ErrorInfo = ErrorInfo();
		
		If Not ModuleEmailOperationsInternalClientServer.IsInternetMailError(
			ErrorInfo) Then
			
			Raise;
		EndIf;
		
		WriteLogEvent(NStr("vi = 'Quy trình nghiệp vụ và nhiệm vụ.Thông báo về các nhiệm vụ mới';
							|ru = 'Бизнес-процессы и задачи.Уведомление о новых задачах';
							|en = 'Business processes and tasks.New task notification'; fa = 'Business processes and tasks.New task notification';
							|it = 'Processi aziendali e obiettivi. Notifica sui nuovi obiettivi';
							|pl = 'Procesy biznesowe i zadania. Powiadomienie o nowych zadaniach';
							|tr = 'İş süreçleri ve görevler. Yeni görev bildirimi'",
			Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa gửi thông báo về nhiệm vụ mới do nguyên nhân:
				|%1';
				|ru = 'Уведомления о новых задачах не отправлены по причине:
				|%1';
				|en = 'New task notifications are not sent due to:
				|%1'; fa = 'New task notifications are not sent due to:
				|%1';
				|it = 'Уведомления о новых задачах не отправлены по причине:
				|%1';
				|pl = 'New task notifications are not sent due to:
				|%1';
				|tr = 'Yeni görevlere dair bildirimler şu nedenlerle gönderilmedi:
				|%1'"), 
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		Return False;
	EndTry;

	WriteLogEvent(NStr("vi = 'Quy trình nghiệp vụ và nhiệm vụ.Thông báo về các nhiệm vụ mới';
						|ru = 'Бизнес-процессы и задачи.Уведомление о новых задачах';
						|en = 'Business processes and tasks.New task notification'; fa = 'Business processes and tasks.New task notification';
						|it = 'Processi aziendali e obiettivi. Notifica sui nuovi obiettivi';
						|pl = 'Procesy biznesowe i zadania. Powiadomienie o nowych zadaniach';
						|tr = 'İş süreçleri ve görevler. Yeni görev bildirimi'",
		Common.DefaultLanguageCode()),
		EventLogLevel.Information,,,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã gửi thành công thông báo đến địa chỉ %1.';
																		|ru = 'Уведомления успешно отправлены на адрес %1.';
																		|en = 'Notifications sent to %1.'; fa = 'Notifications sent to %1.';
																		|it = 'Notifiche inviate correttamente all''indirizzo %1.';
																		|pl = 'Powiadomienia pomyślnie wysłane na adres %1.';
																		|tr = '%1 adresine bildirimler gönderildi.'"), 
			RecipientEmailAddress));
	Return True;	
		
EndFunction

Function GenerateTaskPresentation(TaskStructure)
	
	Result = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1
		|
		|Hạn chót: %2';
		|ru = '%1
		|
		|Крайний срок: %2';
		|en = '%1
		|
		|Deadline: %2'; fa = '%1
		|
		|Deadline: %2';
		|it = '%1
		|
		|Termine massimo: %2';
		|pl = '%1
		|
		|Ostateczny termin: %2';
		|tr = '%1
		|
		|Bitiş tarihi: %2'") + Chars.LF,
		TaskStructure.Ref, 
		Format(TaskStructure.TaskDueDate, NStr("vi = 'ДЛФ=ДД; ДП=''không được chỉ định''';
												|ru = 'ДЛФ=DD; ДП=''не указан''';
												|en = 'DLF=DD; DE=''not specified'''; fa = 'DLF=DD; DE=''not specified''';
												|it = 'LFD= DD; DP=''Non specificato''';
												|pl = 'DLF=DD; DE=''Nie został podany''';
												|tr = 'DLF=DD; DE=''belirtilmedi'''")));
	If ValueIsFilled(TaskStructure.Performer) Then
		Result = Result + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Người thực hiện: %1';
																						|ru = 'Исполнитель: %1';
																						|en = 'Assignee: %1'; fa = 'Assignee: %1';
																						|it = 'Esecutore: %1';
																						|pl = 'Wykonawca: %1';
																						|tr = 'Atanan: %1'"), 
			TaskStructure.Performer) + Chars.LF;
	EndIf;
	If ValueIsFilled(TaskStructure.PerformerRole) Then
		Result = Result + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Vai trò: %1';
																						|ru = 'Роль: %1';
																						|en = 'Role: %1'; fa = 'Role: %1';
																						|it = 'Ruolo: %1';
																						|pl = 'Rola: %1';
																						|tr = 'Rol: %1'"), 
			TaskStructure.PerformerRole) + Chars.LF;
	EndIf;
	If ValueIsFilled(TaskStructure.MainAddressingObject) Then
		Result = Result + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đối tượng đánh địa chỉ chính: %1';
																						|ru = 'Основной объект адресации: %1';
																						|en = 'Main business object: %1'; fa = 'Main business object: %1';
																						|it = 'Oggetto di indirizzamento principale: %1';
																						|pl = 'Podstawowy obiekt adresowania: %1';
																						|tr = 'Ana gönderim hedefi: %1'"), 
			TaskStructure.MainAddressingObject) + Chars.LF;
	EndIf;
	If ValueIsFilled(TaskStructure.AdditionalAddressingObject) Then
		Result = Result + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đối tượng đánh địa chỉ bổ sung: %1';
																						|ru = 'Доп. объект адресации: %1';
																						|en = 'Additional business object: %1'; fa = 'Additional business object: %1';
																						|it = 'Oggetto di indirizzamento secondario: %1';
																						|pl = 'Dodatkowy obiekt adresowania: %1';
																						|tr = 'Ek gönderim hedefi: %1'"), 
			TaskStructure.AdditionalAddressingObject) + Chars.LF;
	EndIf;
	If ValueIsFilled(TaskStructure.Author) Then
		Result = Result + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tác giả: %1';
																						|ru = 'Автор: %1';
																						|en = 'Author: %1'; fa = 'Author: %1';
																						|it = 'Autore: %1';
																						|pl = 'Autor: %1';
																						|tr = 'Oluşturan: %1'"), 
			TaskStructure.Author) + Chars.LF;
	EndIf;
	If ValueIsFilled(TaskStructure.LongDesc) Then
		Result = Result + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1';
																									|ru = '%1';
																									|en = '%1'; fa = '%1';
																									|it = '%1';
																									|pl = '%1';
																									|tr = '%1'"), 
			TaskStructure.LongDesc) + Chars.LF;
	EndIf;
	Return Result + Chars.LF;
	
EndFunction

#EndRegion

#Region AuxiliaryProceduresAndFunctions

// Parameters:
//  Task - Array of TaskRef - Tasks to be checked.
//  Performer - CatalogRef.Users, 
//                CatalogRef.ExternalUsers - Assignee.
// 
// Returns:
//  ValueTable:
//   * Task - TaskRef - Task
//   * Executed - Task status (if the user is the assignee or has the assignee role).
//
Function TasksExecutionStatusesByPerformer(Var_Tasks, Performer)
	
	Query = New Query;
	Query.Text =  "SELECT
	|	PerformerTask.Ref AS Task,
	|	PerformerTask.Executed AS Executed
	|FROM
	|	Task.PerformerTask AS PerformerTask
	|		LEFT JOIN InformationRegister.TaskPerformers AS TaskPerformers
	|		ON PerformerTask.PerformerRole = TaskPerformers.PerformerRole
	|			AND PerformerTask.MainAddressingObject = TaskPerformers.MainAddressingObject
	|			AND PerformerTask.AdditionalAddressingObject = TaskPerformers.AdditionalAddressingObject
	|WHERE
	|	PerformerTask.Ref IN(&Tasks)
	|	AND (PerformerTask.Performer = &Performer
	|		OR TaskPerformers.Performer = &Performer)";
	
	Query.SetParameter("Performer", Performer);
	Query.SetParameter("Tasks",      Var_Tasks);

	QueryResult = Query.Execute().Unload();
	
	Return QueryResult;
	
EndFunction


Function SelectRolesWithPerformerCount(MainAddressingObject) Export
	If MainAddressingObject <> Undefined Then
		QueryText = 
			"SELECT ALLOWED
			|	PerformerRoles.Ref AS RoleRef,
			|	PerformerRoles.Description AS Role,
			|	PerformerRoles.ExternalRole AS ExternalRole,
			|	PerformerRoles.MainAddressingObjectTypes AS MainAddressingObjectTypes,
			|	SUM(CASE
			|			WHEN TaskPerformers.PerformerRole <> VALUE(Catalog.PerformerRoles.EmptyRef) 
			|				AND TaskPerformers.PerformerRole IS NOT NULL 
			|				AND TaskPerformers.MainAddressingObject = &MainAddressingObject
			|				THEN 1
			|			ELSE 0
			|		END) AS Assignees
			|FROM
			|	Catalog.PerformerRoles AS PerformerRoles
			|		LEFT JOIN InformationRegister.TaskPerformers AS TaskPerformers
			|		ON (TaskPerformers.PerformerRole = PerformerRoles.Ref)
			|WHERE
			|	PerformerRoles.DeletionMark = FALSE
			|	AND PerformerRoles.UsedByAddressingObjects = TRUE
			| GROUP BY
			|	PerformerRoles.Ref,
			|	TaskPerformers.PerformerRole, 
			|	PerformerRoles.ExternalRole,
			|	PerformerRoles.Description,
			|	PerformerRoles.MainAddressingObjectTypes";
	Else
		QueryText = 
			"SELECT ALLOWED
			|	PerformerRoles.Ref AS RoleRef,
			|	PerformerRoles.Description AS Role,
			|	PerformerRoles.ExternalRole AS ExternalRole,
			|	PerformerRoles.MainAddressingObjectTypes AS MainAddressingObjectTypes,
			|	SUM(CASE
			|			WHEN TaskPerformers.PerformerRole <> VALUE(Catalog.PerformerRoles.EmptyRef) 
			|				AND TaskPerformers.PerformerRole IS NOT NULL 
			|				AND (TaskPerformers.MainAddressingObject IS NULL 
			|					OR TaskPerformers.MainAddressingObject = UNDEFINED)
			|				THEN 1
			|			ELSE 0
			|		END) AS Assignees
			|FROM
			|	Catalog.PerformerRoles AS PerformerRoles
			|		LEFT JOIN InformationRegister.TaskPerformers AS TaskPerformers
			|		ON (TaskPerformers.PerformerRole = PerformerRoles.Ref)
			|WHERE
			|	PerformerRoles.DeletionMark = FALSE
			|	AND PerformerRoles.UsedWithoutAddressingObjects = TRUE
			| GROUP BY
			|	PerformerRoles.Ref,
			|	TaskPerformers.PerformerRole, 
			|	PerformerRoles.ExternalRole,
			|	PerformerRoles.Description, 
			|	PerformerRoles.MainAddressingObjectTypes";
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		CurrentLanguageSuffix = ModuleNationalLanguageSupportServer.CurrentLanguageSuffix();

		If ValueIsFilled(CurrentLanguageSuffix) Then
			QueryText = StrReplace(QueryText, "PerformerRoles.Description", 
				"PerformerRoles.Description" + CurrentLanguageSuffix);
		EndIf;
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("MainAddressingObject", MainAddressingObject);
	QuerySelection = Query.Execute().Select();
	Return QuerySelection;
	
EndFunction

// Checks if there is at least one assignee for the specified role.
//
// Returns:
//   Boolean
//
Function HasRolePerformers(RoleRef, MainAddressingObject = Undefined,
	AdditionalAddressingObject = Undefined) Export
	
	QueryResult = ChooseRolePerformers(RoleRef, MainAddressingObject,
		AdditionalAddressingObject);
	Return Not QueryResult.IsEmpty();	
	
EndFunction

Function ChooseRolePerformers(RoleRef, MainAddressingObject = Undefined,
	AdditionalAddressingObject = Undefined)
	
	QueryText = 
		"SELECT
	   |	TaskPerformers.Performer
	   |FROM
	   |	InformationRegister.TaskPerformers AS TaskPerformers
	   |WHERE
	   |	TaskPerformers.PerformerRole = &PerformerRole";
	If MainAddressingObject <> Undefined Then  
		QueryText = QueryText 
			+ "	AND TaskPerformers.MainAddressingObject = &MainAddressingObject";
	EndIf;		
	If AdditionalAddressingObject <> Undefined Then  
		QueryText = QueryText 
			+ "	AND TaskPerformers.AdditionalAddressingObject = &AdditionalAddressingObject";
	EndIf;		
	
	Query = New Query(QueryText);
	Query.Parameters.Insert("PerformerRole", RoleRef);
	Query.Parameters.Insert("MainAddressingObject", MainAddressingObject);
	Query.Parameters.Insert("AdditionalAddressingObject", AdditionalAddressingObject);
	QueryResult = Query.Execute();
	Return QueryResult;
	
EndFunction

Function SelectPerformer(MainAddressingObject, PerformerRole) Export
	
	Query = New Query(
		"SELECT ALLOWED TOP 1
		|	TaskPerformers.Performer AS Performer
		|FROM
		|	InformationRegister.TaskPerformers AS TaskPerformers
		|WHERE
		|	TaskPerformers.PerformerRole = &PerformerRole
		|	AND TaskPerformers.MainAddressingObject = &MainAddressingObject");
	Query.Parameters.Insert("MainAddressingObject", MainAddressingObject);
	Query.Parameters.Insert("PerformerRole", PerformerRole);
	QuerySelection = Query.Execute().Unload();
	Return ?(QuerySelection.Count() > 0, QuerySelection[0].Performer, Catalogs.Users.EmptyRef());
	
EndFunction	

Function SelectHeadTaskBusinessProcesses(TaskRef, ForChange = False)
	
	QueryTemplate = "SELECT ALLOWED
		|	Table.Ref AS Ref
		|FROM
		|	&TableName AS Table
		|WHERE
		|	Table.HeadTask = &HeadTask";
	QueriesTexts = New Array;
	For Each BusinessProcessType In Metadata.DefinedTypes.BusinessProcess.Type.Types() Do
		
		BusinessProcessMetadata = Metadata.FindByType(BusinessProcessType);
		
		If ForChange Then
			Block = New DataLock;
			LockItem = Block.Add(BusinessProcessMetadata.FullName());
			LockItem.SetValue("HeadTask", TaskRef);
			Block.Lock();
		EndIf;
		
		QueryText = StrReplace(QueryTemplate, "&TableName", BusinessProcessMetadata.FullName());
		If QueriesTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "SELECT ALLOWED", "SELECT"); // @Query-part-1, @Query-part-2
		EndIf;
		QueriesTexts.Add(QueryText);

	EndDo;
	
	Query = New Query(StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF));
	Query.SetParameter("HeadTask", TaskRef);
	Return Query.Execute();
	
EndFunction

Function SelectBusinessProcessesOfHeadTasks(Var_Tasks, ForChange = False)
	
	QueryTemplate = "SELECT ALLOWED
		|	Table.Ref AS Ref,
		|	Table.HeadTask AS HeadTask
		|FROM
		|	&TableName AS Table
		|WHERE
		|	Table.HeadTask IN (&HeadTasks)";
	QueriesTexts = New Array;
	For Each BusinessProcessType In Metadata.DefinedTypes.BusinessProcess.Type.Types() Do
		
		BusinessProcessMetadata = Metadata.FindByType(BusinessProcessType);
		
		If ForChange Then
			Block = New DataLock;
			For Each TaskRef In Var_Tasks Do
				LockItem = Block.Add(BusinessProcessMetadata.FullName());
				LockItem.SetValue("HeadTask", TaskRef);
			EndDo;
			Block.Lock();
		EndIf;
		
		QueryText = StrReplace(QueryTemplate, "&TableName", BusinessProcessMetadata.FullName());
		If QueriesTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "SELECT ALLOWED", "SELECT"); // @Query-part-1, @Query-part-2
		EndIf;
		QueriesTexts.Add(QueryText);

	EndDo;
	
	Query = New Query(StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF));
	Query.SetParameter("HeadTasks", Var_Tasks);
	Return Query.Execute().Select();
	
EndFunction

Function EventLogEvent() Export
	Return NStr("vi = 'Quy trình nghiệp vụ và nhiệm vụ';
				|ru = 'Бизнес-процессы и задачи';
				|en = 'Business processes and tasks'; fa = 'فرایندهای تجاری و وظایف';
				|it = 'Processi aziendali e obiettivi';
				|pl = 'Procesy biznesowe i zadania';
				|tr = 'İş süreçleri ve görevler'", Common.DefaultLanguageCode());
EndFunction

// The procedure is called when changing state of a business process. 
// It is used to propagate the state change to the uncompleted 
// tasks of the business process.
//
// Parameters:
//   BusinessProcessObject - DefinedType.BusinessProcessObject
//   OldState - EnumRef.BusinessProcessStates
// 
Procedure OnChangeBusinessProcessState(BusinessProcessObject, OldState) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PerformerTask.Ref AS Ref
		|FROM
		|	Task.PerformerTask AS PerformerTask
		|WHERE
		|	PerformerTask.BusinessProcess = &BusinessProcess
		|	AND PerformerTask.Executed = FALSE";

	Query.SetParameter("BusinessProcess", BusinessProcessObject.Ref);

	Block = New DataLock;
	LockItem = Block.Add("Task.PerformerTask");
	LockItem.SetValue("BusinessProcess", BusinessProcessObject.Ref);
	Block.Lock();
	
	OutstandingTasks = Query.Execute().Unload();
	For Each TaskRef In OutstandingTasks Do
		Task = TaskRef.Ref.GetObject();
		Task.Lock();
		Task.BusinessProcessState = BusinessProcessObject.State;
		Task.Write();
	EndDo;
	OnChangeTasksState(OutstandingTasks, OldState, BusinessProcessObject.State);

EndProcedure

// Parameters:
//  Var_Tasks - ValueTable:
//    * Ref - TaskRef.PerformerTask
//  OldState - EnumRef.BusinessProcessStates 
//  NewState - EnumRef.BusinessProcessStates
//
Procedure OnChangeTasksState(Var_Tasks, OldState, NewState)
	
	// Locking nested and subordinate business processes.
	Block = New DataLock;
	For Each BusinessProcessMetadata In Metadata.BusinessProcesses Do
		
		If Not AccessRight("Update", BusinessProcessMetadata) Then
			Continue;
		EndIf;
		
		LockItem = Block.Add(BusinessProcessMetadata.FullName());
		LockItem.DataSource = Var_Tasks;
		LockItem.UseFromDataSource("HeadTask", "Ref");
		
		MainTaskAttribute = BusinessProcessMetadata.Attributes.Find("MainTask");
		If MainTaskAttribute <> Undefined Then
			LockItem = Block.Add(BusinessProcessMetadata.FullName());
			LockItem.DataSource = Var_Tasks;
			LockItem.UseFromDataSource("MainTask", "Ref");
		EndIf;
		
	EndDo;
	Block.Lock();
	
	TasksRefs = Var_Tasks.UnloadColumn("Ref");
	QueryTemplate = 
		"SELECT ALLOWED
		|	SubBusinessProcesses.Ref AS Ref
		|FROM
		|	#BusinessProcesses AS SubBusinessProcesses
		|WHERE
		|  SubBusinessProcesses.HeadTask IN (&Tasks)
		|  AND SubBusinessProcesses.DeletionMark = FALSE
		|	AND SubBusinessProcesses.Completed = FALSE";
	QueryTexts = New Array;
	
	// Change the state of the nested business processes.
	For Each BusinessProcessMetadata In Metadata.BusinessProcesses Do
		
		If Not AccessRight("Update", BusinessProcessMetadata) Then
			Continue;
		EndIf;
		
		QueryText = StrReplace(QueryTemplate, "#BusinessProcesses", BusinessProcessMetadata.FullName());
		If QueryTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "SELECT ALLOWED", "SELECT"); // @query-part-1, @query-part-2
		EndIf;
		QueryTexts.Add(QueryText);
		
	EndDo;
	
	If QueryTexts.Count() > 0 Then
		Query = New Query(StrConcat(QueryTexts, Chars.LF + "UNION ALL" + Chars.LF)); // @query-part
		Query.SetParameter("Tasks", TasksRefs);
		
		SelectionDetailRecords = Query.Execute().Select();
		While SelectionDetailRecords.Next() Do
			BusinessProcess = SelectionDetailRecords.Ref.GetObject(); // BusinessProcessObject
			BusinessProcess.State = NewState;
			BusinessProcess.Write();
		EndDo;
	EndIf;
	
	QueryTemplate = 
		"SELECT ALLOWED
		|	SubordinateBusinessProcesses.Ref AS Ref
		|FROM
		|	#BusinessProcesses AS SubordinateBusinessProcesses
		|WHERE
		|   SubordinateBusinessProcesses.MainTask IN (&Tasks)
		|   AND SubordinateBusinessProcesses.DeletionMark = FALSE
		| 	AND SubordinateBusinessProcesses.Completed = FALSE";
	QueryTexts = New Array;
	
	// Changing state of subordinate business processes.
	For Each BusinessProcessMetadata In Metadata.BusinessProcesses Do
		
		// A main task is not required in business process.
		MainTaskAttribute = BusinessProcessMetadata.Attributes.Find("MainTask");
		If MainTaskAttribute = Undefined Then
			Continue;
		EndIf;	
			
		QueryText = StrReplace(QueryTemplate, "#BusinessProcesses", BusinessProcessMetadata.FullName());
		If QueryTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "SELECT ALLOWED", "SELECT"); // @query-part-1, @query-part-2
		EndIf;
		QueryTexts.Add(QueryText);

	EndDo;
	
	If QueryTexts.Count() > 0 Then
		Query = New Query(StrConcat(QueryTexts, Chars.LF + "UNION ALL" + Chars.LF)); // @query-part
		Query.SetParameter("Tasks", TasksRefs);
	
		SelectionDetailRecords = Query.Execute().Select();
		While SelectionDetailRecords.Next() Do
			BusinessProcess = SelectionDetailRecords.Ref.GetObject(); // BusinessProcessObject
			BusinessProcess.State = NewState;
			BusinessProcess.Write();
		EndDo;
	EndIf;
	
EndProcedure

// Gets task assignee groups according to the new task assignee records.
//
// Parameters:
//  NewTasksPerformers  - ValueTable - data retrieved from
//                           the TaskPerformers information register record set.
//
// Returns:
//   Array of CatalogRef.TaskPerformersGroups
//
Function TaskPerformersGroups(NewTasksPerformers) Export
	
	FieldsNames1 = "PerformerRole, MainAddressingObject, AdditionalAddressingObject";
	
	Query = New Query;
	Query.SetParameter("NewRecords", NewTasksPerformers.Copy( , FieldsNames1));
	Query.Text =
	"SELECT DISTINCT
	|	NewRecords.PerformerRole AS PerformerRole,
	|	NewRecords.MainAddressingObject AS MainAddressingObject,
	|	NewRecords.AdditionalAddressingObject AS AdditionalAddressingObject
	|INTO NewRecords
	|FROM
	|	&NewRecords AS NewRecords
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TaskPerformersGroups.Ref, VALUE(Catalog.TaskPerformersGroups.EmptyRef)) AS Ref,
	|	NewRecords.PerformerRole AS PerformerRole,
	|	NewRecords.MainAddressingObject AS MainAddressingObject,
	|	NewRecords.AdditionalAddressingObject AS AdditionalAddressingObject
	|FROM
	|	NewRecords AS NewRecords
	|		LEFT JOIN Catalog.TaskPerformersGroups AS TaskPerformersGroups
	|		ON NewRecords.PerformerRole = TaskPerformersGroups.PerformerRole
	|			AND NewRecords.MainAddressingObject = TaskPerformersGroups.MainAddressingObject
	|			AND NewRecords.AdditionalAddressingObject = TaskPerformersGroups.AdditionalAddressingObject";
	
	PerformersGroups = Query.Execute().Unload();
	
	FilterPerformersGroups = New Structure(FieldsNames1);
	TaskPerformersGroups = New Array;
	
	For Each Record In NewTasksPerformers Do
		FillPropertyValues(FilterPerformersGroups, Record);
		PerformersGroup = PerformersGroups.FindRows(FilterPerformersGroups)[0];
		// It is necessary to update the reference in the found row.
		If Not ValueIsFilled(PerformersGroup.Ref) Then
			// It is necessary to add a new assignee group.
			PerformersGroupObject = Catalogs.TaskPerformersGroups.CreateItem();
			FillPropertyValues(PerformersGroupObject, FilterPerformersGroups);
			PerformersGroupObject.Write();
			PerformersGroup.Ref = PerformersGroupObject.Ref;
		EndIf;
		TaskPerformersGroups.Add(PerformersGroup.Ref);
	EndDo;
	
	Return TaskPerformersGroups;
	
EndFunction

// The procedure marks nested and subordinate business processes of TaskRef for deletion.
//
// Parameters:
//  TaskRef                 - TaskRef.PerformerTask
//  DeletionMarkNewValue - Boolean
//
Procedure OnMarkTaskForDeletion(TaskRef, DeletionMarkNewValue) Export
	
	ObjectOfTask = TaskRef.Metadata();
	If DeletionMarkNewValue Then
		VerifyAccessRights("InteractiveSetDeletionMark", ObjectOfTask);
	EndIf;
	If Not DeletionMarkNewValue Then
		VerifyAccessRights("InteractiveClearDeletionMark", ObjectOfTask);
	EndIf;
	If TaskRef.IsEmpty() Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		// Mark nested business processes.
		SetPrivilegedMode(True);
		SubBusinessProcesses = HeadTaskBusinessProcesses(TaskRef, True);
		SetPrivilegedMode(False);
		// Without privileged mode, with rights check.
		For Each SubBusinessProcess In SubBusinessProcesses Do
			BusinessProcessObject = SubBusinessProcess.GetObject();
			BusinessProcessObject.SetDeletionMark(DeletionMarkNewValue);
		EndDo;
		
		// Mark subordinate business processes.
		SubordinateBusinessProcesses = MainTaskBusinessProcesses(TaskRef, True);
		For Each SubordinateBusinessProcess In SubordinateBusinessProcesses Do
			BusinessProcessObject = SubordinateBusinessProcess.GetObject();
			BusinessProcessObject.Lock();
			BusinessProcessObject.SetDeletionMark(DeletionMarkNewValue);
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Checks whether the user has sufficient rights to mark a business process
// as suspended or active.
// 
// Parameters:
//  BusinessProcess - DefinedType.BusinessProcessObject
//
// Returns:
//  Boolean - True if the user has the rights.
//
Function HasRightsToStopBusinessProcess(BusinessProcess)
	
	HasRights = False;
	StandardProcessing = True;
	BusinessProcessesAndTasksOverridable.OnCheckStopBusinessProcessRights(BusinessProcess, HasRights, StandardProcessing);
	If Not StandardProcessing Then
		Return HasRights;
	EndIf;
	
	If Users.IsFullUser() Then
		Return True;
	EndIf;
	
	If BusinessProcess.Author = Users.CurrentUser() Then
		Return True;
	EndIf;
	
	Return HasRights;
	
EndFunction

// Parameters:
//   List - DynamicList
//
Procedure SetMyTasksListParameters(List) Export
	
	CurrentSessionDate = CurrentSessionDate();
	Today = New StandardPeriod(StandardPeriodVariant.Today);
	ThisWeek = New StandardPeriod(StandardPeriodVariant.ThisWeek);
	NextWeek = New StandardPeriod(StandardPeriodVariant.NextWeek);
	
	List.Parameters.SetParameterValue("CurrentDate", CurrentSessionDate);
	List.Parameters.SetParameterValue("EndOfDay", Today.EndDate);
	List.Parameters.SetParameterValue("EndOfWeek", ThisWeek.EndDate);
	List.Parameters.SetParameterValue("EndOfNextWeek", NextWeek.EndDate);
	List.Parameters.SetParameterValue("Overdue", " " + NStr("vi = 'Đã quá hạn';
															|ru = 'Просрочено';
															|en = 'Overdue'; fa = 'سررسیدگذشته';
															|it = 'Scaduto';
															|pl = 'Overdue';
															|tr = 'Vadesi geçmiş'")); // Insert a space for sort purposes.
	List.Parameters.SetParameterValue("Today", NStr("vi = 'Trong hôm nay';
													|ru = 'В течение сегодня';
													|en = 'Today'; fa = 'امروز';
													|it = 'Durante la giornata di oggi';
													|pl = 'W ciągu dzisiejszego dnia';
													|tr = 'Bugün içinde'"));
	List.Parameters.SetParameterValue("ThisWeek", NStr("vi = 'Đến cuối tuần';
														|ru = 'До конца недели';
														|en = 'Till the end of the week'; fa = 'Till the end of the week';
														|it = 'Fino alla fine di questa settimana';
														|pl = 'Do końca tygodnia';
														|tr = 'Hafta sonuna kadar'"));
	List.Parameters.SetParameterValue("NextWeek", NStr("vi = 'Vào tuần tới';
														|ru = 'На следующей неделе';
														|en = 'Next week'; fa = 'هفته بعد';
														|it = 'Nella prossima settimana';
														|pl = 'W przyszłym tygodniu';
														|tr = 'Gelecek hafta'"));
	List.Parameters.SetParameterValue("Later", NStr("vi = 'Muộn hơn';
													|ru = 'Позднее';
													|en = 'Later'; fa = 'Later';
													|it = 'Più tardi';
													|pl = 'Later';
													|tr = 'Sonra'"));
	List.Parameters.SetParameterValue("BegOfDay", BegOfDay(CurrentSessionDate));
	List.Parameters.SetParameterValue("BlankDate", Date(1,1,1));
	
EndProcedure

Function PerformerTaskQuantity()
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	TasksByExecutive.Ref AS Ref,
	|	TasksByExecutive.TaskDueDate AS TaskDueDate
	|INTO UserBusinessProcesses
	|FROM
	|	Task.PerformerTask.TasksByExecutive AS TasksByExecutive
	|WHERE
	|	NOT TasksByExecutive.DeletionMark
	|	AND NOT TasksByExecutive.Executed
	|	AND TasksByExecutive.BusinessProcessState = VALUE(Enum.BusinessProcessStates.Running)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(UserBusinessProcesses.Ref) AS Count
	|FROM
	|	UserBusinessProcesses AS UserBusinessProcesses
	|
	|UNION ALL
	|
	|SELECT
	|	COUNT(UserBusinessProcesses.Ref)
	|FROM
	|	UserBusinessProcesses AS UserBusinessProcesses
	|WHERE
	|	UserBusinessProcesses.TaskDueDate <> DATETIME(1, 1, 1)
	|	AND UserBusinessProcesses.TaskDueDate <= &CurrentDate
	|
	|UNION ALL
	|
	|SELECT
	|	COUNT(UserBusinessProcesses.Ref)
	|FROM
	|	UserBusinessProcesses AS UserBusinessProcesses
	|WHERE
	|	UserBusinessProcesses.TaskDueDate > &CurrentDate
	|	AND UserBusinessProcesses.TaskDueDate <= &Today
	|
	|UNION ALL
	|
	|SELECT
	|	COUNT(UserBusinessProcesses.Ref)
	|FROM
	|	UserBusinessProcesses AS UserBusinessProcesses
	|WHERE
	|	UserBusinessProcesses.TaskDueDate > &Today
	|	AND UserBusinessProcesses.TaskDueDate <= &EndOfWeek
	|
	|UNION ALL
	|
	|SELECT
	|	COUNT(UserBusinessProcesses.Ref)
	|FROM
	|	UserBusinessProcesses AS UserBusinessProcesses
	|WHERE
	|	UserBusinessProcesses.TaskDueDate > &EndOfWeek
	|	AND UserBusinessProcesses.TaskDueDate <= &EndOfNextWeek";
	
	Today = New StandardPeriod(StandardPeriodVariant.Today);
	ThisWeek = New StandardPeriod(StandardPeriodVariant.ThisWeek);
	NextWeek = New StandardPeriod(StandardPeriodVariant.NextWeek);
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("Today", Today.EndDate);
	Query.SetParameter("EndOfWeek", ThisWeek.EndDate);
	Query.SetParameter("EndOfNextWeek", NextWeek.EndDate);
	QueryResult = Query.Execute().Unload();
	
	Result = New Structure("Total,Overdue1,ForToday,ForWeek,ForNextWeek");
	Result.Total = QueryResult[0].Count;
	Result.Overdue1 = QueryResult[1].Count;
	Result.ForToday = QueryResult[2].Count;
	Result.ForWeek = QueryResult[3].Count;
	Result.ForNextWeek = QueryResult[4].Count;
	
	Return Result;
	
EndFunction

// StandardSubsystems.AccessManagement

#EndRegion

#Region ProceduresUsedForDIBDataExchange

// Overrides the standard behavior on data import.
Procedure OnDataGet(DataElement, ItemReceive)
	
	// Standard data processor cannot be overridden.
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	If TypeOf(DataElement) = Type("InformationRegisterRecordSet.TaskPerformers") Then
		RegisterTaskAssigneesChangeUponDataImport(DataElement);
	EndIf;
	
EndProcedure

// Intended for "OnGetData".
Procedure RegisterTaskAssigneesChangeUponDataImport(DataElement)
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Groups = DataElement.ModifiedTasksAssigneesGroups();
	If Not ValueIsFilled(Groups) Then
		Return;
	EndIf;
	
	UsersInternal.RegisterRefs("ModifiedTasksAssigneesGroups", Groups);
	
EndProcedure

// Intended for procedure "AfterGetData".
Procedure UpdateAuxiliaryDataOfItemsModifiedUponDataImport()
	
	RefsKindName = "ModifiedTasksAssigneesGroups";
	
	Groups = UsersInternal.RegisteredRefs(RefsKindName);
	If Groups.Count() = 0 Then
		Return;
	EndIf;
	
	If Groups.Count() = 1 And Groups[0] = Undefined Then
		Groups = Undefined;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.UpdatePerformersGroupsUsers(Groups);
	EndIf;
	
	UsersInternal.RegisterRefs(RefsKindName, Null);
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region InfobaseUpdate

// Initializes EmployeeResponsibleForTasksManagement predefined business role.
// 
Procedure FillEmployeeResponsibleForCompletionControl() Export
	
	AllAddressingObjects = ChartsOfCharacteristicTypes.TaskAddressingObjects.AllAddressingObjects;
	
	RoleObject1 = Catalogs.PerformerRoles.EmployeeResponsibleForTasksManagement.GetObject();
	LockDataForEdit(RoleObject1.Ref);
	RoleObject1.Description = NStr("vi = 'Điều phối viên thực hiện nhiệm vụ';
									|ru = 'Координатор выполнения задач';
									|en = 'Task control manager'; fa = 'Task control manager';
									|it = 'Coordinatore di esecuzione dei task';
									|pl = 'Koordynator zadań';
									|tr = 'Görev kontrolü yöneticisi'");
	RoleObject1.UsedWithoutAddressingObjects = True;
	RoleObject1.UsedByAddressingObjects = True;
	RoleObject1.MainAddressingObjectTypes = AllAddressingObjects;
	InfobaseUpdate.WriteObject(RoleObject1);
	
EndProcedure

// Parameters:
//  Recipients - See ContactsManager.ObjectsContactInformation
//  Recipient - CatalogRef.Users, CatalogRef.ExternalUsers 
// 
// Returns:
//  String
//
Function Email(Recipients, Recipient)
	
	If Recipients = Undefined Then
		Return "";
	EndIf;

	TableRows = Recipients.FindRows(New Structure("Object", Recipient));
	If TableRows.Count() > 0 Then
		Return TableRows[0].Presentation;
	EndIf;
	
	Return "";
	 
EndFunction

// Parameters:
//   Recipients - Array of CatalogRef.Users
//              - Array of CatalogRef.ExternalUsers
//   
// Returns:
//   See ContactsManager.ObjectsContactInformation
//
Function Emails(Recipients)
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		
		ModuleContactsManager = Common.CommonModule("ContactsManager");

		UsersRefs = New Array;
		ExternalUsersRefs = New Array;
		HasExternalUsersAddresses = ModuleContactsManager.ContainsContactInformation(Type("CatalogRef.ExternalUsers"));
		For Each Recipient In Recipients Do
			If TypeOf(Recipient) = Type("CatalogRef.Users") Then
				UsersRefs.Add(Recipient);
			ElsIf HasExternalUsersAddresses And TypeOf(Recipient) = Type("CatalogRef.ExternalUsers") Then
				ExternalUsersRefs.Add(Recipient);
			EndIf;
		EndDo;
	
		ContactInformationKind = ModuleContactsManager.ContactInformationKindByName("UserEmail");
		ContactInformationType = ModuleContactsManager.ContactInformationTypeByDescription("Email");
		
		Result = Undefined;
		If UsersRefs.Count() > 0 Then
			Result = ModuleContactsManager.ObjectsContactInformation(UsersRefs,,
				ContactInformationKind, CurrentSessionDate());
		EndIf;
		
		If ExternalUsersRefs.Count() > 0 Then
			ResultExternalUsers = ModuleContactsManager.ObjectsContactInformation(
				ExternalUsersRefs, ContactInformationType,, CurrentSessionDate());
			If Result <> Undefined Then
				CommonClientServer.SupplementTable(ResultExternalUsers, Result);
			EndIf;
		EndIf;
		
		If Result <> Undefined Then
			Result.Indexes.Add("Object");
		EndIf;
		Return Result;
		
	EndIf;
	
	Return New Array;
	
EndFunction

Function SystemEmailAccountIsSetUp(ErrorDescription)
	
	If Not Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ErrorDescription = NStr("vi = 'Chưa xem xét gửi thư trong ứng dụng.';
								|ru = 'Отправка почты не предусмотрена в приложении.';
								|en = 'Sending email messages is not supported in the app.'; fa = 'Sending email messages is not supported in the app.';
								|it = 'Отправка почты не предусмотрена в приложении.';
								|pl = 'Sending email messages is not supported in the app.';
								|tr = 'Uygulamada e-posta gönderimi mevcut değil.'");
	Else
		ModuleEmailOperations = Common.CommonModule("EmailOperations");
		If ModuleEmailOperations.AccountSetUp(ModuleEmailOperations.SystemAccount(), True, False) Then
			Return True;
		EndIf;
		ErrorDescription = NStr("vi = 'Chưa tùy chỉnh email để gửi thông báo hàng loạt.';
								|ru = 'Не настроена электронная почта для рассылки уведомлений.';
								|en = 'The service email account is not set up.'; fa = 'The service email account is not set up.';
								|it = 'Не настроена электронная почта для рассылки уведомлений.';
								|pl = 'The service email account is not set up.';
								|tr = 'Bildirim bültenleri için e-posta yapılandırılmadı.'");
	EndIf;
	
	Return False;
EndFunction

// [2.3.3.70] Updates the StartDeferredProcesses scheduled job.
Procedure UpdateScheduledJobUsage() Export
	
	SearchParameters = New Structure;
	SearchParameters.Insert("Metadata", Metadata.ScheduledJobs.StartDeferredProcesses);
	JobsList = ScheduledJobsServer.FindJobs(SearchParameters);
	
	JobParameters = New Structure("Use", GetFunctionalOption("UseBusinessProcessesAndTasks"));
	For Each Job In JobsList Do
		ScheduledJobsServer.ChangeJob(Job, JobParameters);
	EndDo;
	
EndProcedure

// Runs during update to SSL v.3.0.2.131 and initial data population.
// 
Procedure FillPredefinedItemDescriptionAllAddressingObjects() Export
	
	Ref = Common.ObjectAttributeValue(ChartsOfCharacteristicTypes.TaskAddressingObjects.AllAddressingObjects, "Ref");
	
	Block = New DataLock;
	LockItem = Block.Add("ChartOfCharacteristicTypes.TaskAddressingObjects");
	LockItem.SetValue("Ref", Ref);

	BeginTransaction();
	Try
		
		Block.Lock();
		
		AllAddressingObjects = ChartsOfCharacteristicTypes.TaskAddressingObjects.AllAddressingObjects.GetObject();
		AllAddressingObjects.Description = NStr("vi = 'Tất cả đối tượng đánh địa chỉ';
												|ru = 'Все объекты адресации';
												|en = 'All business objects'; fa = 'All business objects';
												|it = 'Tutti gli oggetti dell''indirizzamento';
												|pl = 'Wszystkie obiekty adresowania';
												|tr = 'Tüm gönderim hedefleri'");
		InfobaseUpdate.WriteObject(AllAddressingObjects);

		CommitTransaction();

	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

// Returns:
//  ValueTable:
//   * TaskRef - TaskRef
//
Function NewTasksBySubject() Export
	
	TypesList = New Array;
	For Each MetadataTasks In Metadata.Tasks Do
		TypesList.Add(Type(StringFunctionsClientServer.SubstituteParametersToString(
			"%1.%2", "TaskRef", MetadataTasks.Name)));
	EndDo;
	
	FlexibleTypeDetails = New TypeDescription(TypesList);
	
	TasksBySubject = New ValueTable;
	TasksBySubject.Columns.Add("TaskRef", FlexibleTypeDetails);
	Return TasksBySubject;

EndFunction

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("FillEmployeeResponsibleForCompletionControl");
	Methods.Insert("UpdateScheduledJobUsage");
	Methods.Insert("FillPredefinedItemDescriptionAllAddressingObjects");
	
EndProcedure

#EndRegion