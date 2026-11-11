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
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.UserReminders
	If Common.SubsystemExists("StandardSubsystems.UserReminders") Then
		ModuleUserReminder = Common.CommonModule("UserReminders");
		PlacementParameters = ModuleUserReminder.PlacementParameters();
		PlacementParameters.NameOfAttributeWithEventDate = "TaskDueDate";
		ModuleUserReminder.OnCreateAtServer(ThisObject, PlacementParameters);
	EndIf;
	// End StandardSubsystems.UserReminders
	
	// For new objects, run the form initializer in "OnCreateAtServer".
	// For existing objects, in "OnReadAtServer".
	If Object.Ref.IsEmpty() Then
		InitializeTheForm();
	EndIf;
	
	SetPrivilegedMode(True);
	AuthorAsString = String(Object.Author);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	InitializeTheForm();
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement 
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = Common.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.UserReminders
	If Common.SubsystemExists("StandardSubsystems.UserReminders") Then
		ModuleUserReminder = Common.CommonModule("UserReminders");
		ModuleUserReminder.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.UserReminders
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	BusinessProcessesAndTasksClient.TaskFormNotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.UserReminders
	If CommonClient.SubsystemExists("StandardSubsystems.UserReminders") Then
		ModuleUserReminderClient = CommonClient.CommonModule("UserRemindersClient");
		ModuleUserReminderClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	EndIf;
	// End StandardSubsystems.UserReminders
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.UserReminders
	If Common.SubsystemExists("StandardSubsystems.UserReminders") Then
		ModuleUserReminder = Common.CommonModule("UserReminders");
		ReminderText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kiểm tra việc thực hiện nhiệm vụ %1';
				|ru = 'Проверить выполнение задачи %1';
				|en = 'Check if task %1 is completed'; fa = 'Check if task %1 is completed';
				|it = 'Проверить выполнение задачи %1';
				|pl = 'Check if task %1 is completed';
				|tr = '%1 görevinin tamamlanıp tamamlanmadığını kontrol et'"), CurrentObject.Description);	
		ModuleUserReminder.OnWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters, ReminderText);
	EndIf;
	// End StandardSubsystems.UserReminders
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OpenTaskFormDecorationClick(Item)
	
	ShowValue(,Object.Ref);
	Modified = False;
	Close();
	
EndProcedure

&AtClient
Procedure SubjectOfClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(,Object.SubjectOf);
	
EndProcedure

&AtClient
Procedure CompletionDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.CompletionDate = BegOfDay(Object.CompletionDate) Then
		Object.CompletionDate = EndOfDay(Object.CompletionDate);
	EndIf;
	
EndProcedure

// StandardSubsystems.UserReminders
&AtClient
Procedure Attachable_OnChangeReminderSettings(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.UserReminders") Then
		ModuleUserReminderClient = CommonClient.CommonModule("UserRemindersClient");
		ModuleUserReminderClient.OnChangeReminderSettings(Item, ThisObject);
	EndIf;
	
EndProcedure
// End StandardSubsystems.UserReminders

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndCloseExecute(Command)
	
	BusinessProcessesAndTasksClient.WriteAndCloseExecute(ThisObject);
	
EndProcedure

&AtClient
Procedure ExecutedExecute(Command)

	BusinessProcessesAndTasksClient.WriteAndCloseExecute(ThisObject, True);

EndProcedure

&AtClient
Procedure More(Command)
	
	BusinessProcessesAndTasksClient.OpenAdditionalTaskInfo(Object.Ref);
	
EndProcedure

// StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
	ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
	ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
	ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure InitializeTheForm()
	
	If ValueIsFilled(Object.BusinessProcess) Then
		FormParameters = BusinessProcessesAndTasksServer.TaskExecutionForm(Object.Ref);
		HasBusinessProcessTaskForm = FormParameters.Property("FormName");
		Items.ExecutionFormGroup.Visible = HasBusinessProcessTaskForm;
		Items.Executed.Enabled = Not HasBusinessProcessTaskForm;
	Else
		Items.ExecutionFormGroup.Visible = False;
	EndIf;
	InitialExecutionFlag = Object.Executed;
	If Object.Ref.IsEmpty() Then
		Object.Importance = Enums.TaskImportanceOptions.Ordinary;
		Object.TaskDueDate = CurrentSessionDate();
	EndIf;
	
	Items.SubjectOf.Hyperlink = Object.SubjectOf <> Undefined And Not Object.SubjectOf.IsEmpty();
	SubjectString = Common.SubjectString(Object.SubjectOf);	
	
	UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
	Items.ExecutionStartDateScheduledTime.Visible = UseDateAndTimeInTaskDeadlines;
	Items.CompletionDateTime.Visible = UseDateAndTimeInTaskDeadlines;
	BusinessProcessesAndTasksServer.SetDateFormat(Items.TaskDueDate);
	BusinessProcessesAndTasksServer.SetDateFormat(Items.Date);
	
	BusinessProcessesAndTasksServer.TaskFormOnCreateAtServer(ThisObject, Object, 
		Items.StateGroup, Items.CompletionDate);
		
	If Users.IsExternalUserSession() Then
		Items.Author.Visible = False;
		Items.AuthorAsString.Visible = True;
		Items.Performer.OpenButton = False;
	EndIf;
	
	Items.Executed.Enabled = AccessRight("Update", Metadata.Tasks.PerformerTask);
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_CompletionDate" Then
		CompletionDateOnChange(Items.CompletionDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
