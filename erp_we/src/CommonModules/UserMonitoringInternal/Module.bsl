///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystem event handlers.

// See CommonOverridable.OnAddMetadataObjectsRenaming.
Procedure OnAddMetadataObjectsRenaming(Renamings) Export
	
	Common.AddRenaming(Renamings, "2.1.0.1",
		"Subsystem.StandardSubsystems.Subsystem.EventLogMonitor",
		"Subsystem.StandardSubsystems.Subsystem.EventLogAnalysis",
		"StandardSubsystems");
	
	Common.AddRenaming(Renamings, "3.1.10.32",
		"Subsystem.StandardSubsystems.Subsystem.EventLogAnalysis",
		"Subsystem.StandardSubsystems.Subsystem.UserMonitoring",
		"StandardSubsystems");
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.EventLogAnalysis);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.UserAccountsChanges);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.MembersChangeInUsersGroups);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.EditAccessGroupMembers);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.AccessGroupsAllowedValuesChange);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ProfilesRolesChanges);
	
EndProcedure

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	Reports.EventLogAnalysis.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	Reports.UserAccountsChanges.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	Reports.MembersChangeInUsersGroups.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	Reports.EditAccessGroupMembers.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	Reports.AccessGroupsAllowedValuesChange.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	Reports.ProfilesRolesChanges.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
	
EndProcedure

// See UsersOverridable.OnDefineRegistrationSettingsForDataAccessEvents
Procedure OnDefineRegistrationSettingsForDataAccessEvents(Settings) Export
	
	StoredSettings = StoredRegistrationSettings();
	If Not StoredSettings.Use Then
		Return;
	EndIf;
	
	For Each Setting In StoredSettings.Content Do
		Settings.Add(Setting);
	EndDo;
	
EndProcedure

// See SSLSubsystemsIntegration.OnFillToDoList.
Procedure OnFillToDoList(ToDoList) Export
	
	If Common.DataSeparationEnabled()
	 Or Not Users.IsFullUser(, True) Then
		Return;
	EndIf;
	
	AdministrationSection = Metadata.Subsystems.Find("Administration");
	If AdministrationSection = Undefined Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	StoredSettings = StoredRegistrationSettings();
	
	UnfoundFields = New Array;
	UsersInternal.DeleteNonExistentFieldsFromAccessAccessEventSetting(
		StoredSettings.Content, UnfoundFields);
	
	If Not ValueIsFilled(UnfoundFields) Then
		Return;
	EndIf;
	
	// The procedure can be called only if the "To-do list" subsystem is integrated.
	// Therefore, don't check if the subsystem is integrated.
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "KeepRegistrationSettingsForDataAccessEventsUpToDate";
	ToDoItem.HasToDoItems       = True;
	ToDoItem.Important         = True;
	ToDoItem.Count     = UnfoundFields.Count();
	ToDoItem.Presentation  = NStr("vi = 'Cập nhật tùy chỉnh ghi nhận sự kiện truy cập đến dữ liệu';
									|ru = 'Актуализировать настройки регистрации событий доступа к данным';
									|en = 'Update data access logging settings'; fa = 'Update data access logging settings';
									|it = 'Актуализировать настройки регистрации событий доступа к данным';
									|pl = 'Update data access logging settings';
									|tr = 'Veri erişim olaylarını kaydetmeye yönelik ayarları güncelleme'");
	ToDoItem.ToolTip      = NStr("vi = 'Chưa thực hiện kiểm soát truy cập đối với các tùy chỉnh chưa cập nhật.';
								|ru = 'Не выполняется контроль доступа для неактуальных настроек.';
								|en = 'Access control is disabled for outdated settings.'; fa = 'Access control is disabled for outdated settings.';
								|it = 'Не выполняется контроль доступа для неактуальных настроек.';
								|pl = 'Access control is disabled for outdated settings.';
								|tr = 'Güncel olmayan ayarlar için erişim kontrolü yapılmaz.'");
	ToDoItem.Form          = "CommonForm.RegistrationSettingsForDataAccessEvents";
	ToDoItem.Owner       = AdministrationSection;
	
EndProcedure

// Parameters:
//  ErrorText - String - Return value (the error text can be extended).
//
Procedure OnWriteErrorUpdatingRegistrationSettingsForDataAccessEvents(ErrorText) Export
	
	SetPrivilegedMode(True);
	StoredSettings = StoredRegistrationSettings();
	
	If Not StoredSettings.Use Then
		Return;
	EndIf;
	
	UnfoundFields = New Array;
	UsersInternal.DeleteNonExistentFieldsFromAccessAccessEventSetting(
		StoredSettings.Content, UnfoundFields);
	
	If Not ValueIsFilled(UnfoundFields) Then
		Return;
	EndIf;
	
	ErrorText = ErrorText + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Nên điều chỉnh các cài đặt được thực hiện trong biểu mẫu thông qua liên kết:
		           |%1';
		           |ru = 'Рекомендуется скорректировать сделанные настройки в форме по ссылке:
		           |%1';
		           |en = 'You are recommended to adjust the form settings by the link:
		           |%1'; fa = 'You are recommended to adjust the form settings by the link:
		           |%1';
		           |it = 'Рекомендуется скорректировать сделанные настройки в форме по ссылке:
		           |%1';
		           |pl = 'You are recommended to adjust the form settings by the link:
		           |%1';
		           |tr = 'Formda yapılan ayarları şu bağlantıyı kullanarak değiştirmeniz önerilir:
		           |%1'", Common.DefaultLanguageCode()),
		"e1cib/app/CommonForm.RegistrationSettingsForDataAccessEvents");
	
EndProcedure

// Returns:
//  Boolean
//
Function ShouldRegisterDataAccess() Export
	
	SetPrivilegedMode(True);
	
	Return StoredRegistrationSettings().Use;
	
EndFunction

// Parameters:
//  ShouldRegisterDataAccess - Boolean
//
Procedure SetDataAccessRegistration(ShouldRegisterDataAccess) Export
	
	Block = New DataLock;
	Block.Add("Constant.RegistrationSettingsForDataAccessEvents");
	
	BeginTransaction();
	Try
		Block.Lock();
		CurrentSettings = StoredRegistrationSettings();
		CurrentSettings.Use = ShouldRegisterDataAccess;
		Storage = New ValueStorage(CurrentSettings, New Deflation(9));
		Constants.RegistrationSettingsForDataAccessEvents.Set(Storage);
		Users.UpdateRegistrationSettingsForDataAccessEvents();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns:
//  Boolean
//
Function ShouldRegisterChangesInAccessRights() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Result = Constants.ShouldRegisterChangesInAccessRights.Get();
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// See UserMonitoring.RegistrationSettingsForDataAccessEvents
Function RegistrationSettingsForDataAccessEvents() Export
	
	Result = New Structure;
	Result.Insert("Content", New Array);
	Result.Insert("Comments", New Map);
	Result.Insert("GeneralComment", "");
	
	FillPropertyValues(Result, StoredRegistrationSettings());
	
	Return Result;
	
EndFunction

// See UserMonitoring.SetRegistrationSettingsForDataAccessEvents
Procedure SetRegistrationSettingsForDataAccessEvents(Settings) Export
	
	Block = New DataLock;
	Block.Add("Constant.RegistrationSettingsForDataAccessEvents");
	
	BeginTransaction();
	Try
		Block.Lock();
		CurrentSettings = StoredRegistrationSettings();
		CurrentSettings.Content           = Settings.Content;
		CurrentSettings.Comments      = Settings.Comments;
		CurrentSettings.GeneralComment = Settings.GeneralComment;
		Storage = New ValueStorage(CurrentSettings, New Deflation(9));
		Constants.RegistrationSettingsForDataAccessEvents.Set(Storage);
		Users.UpdateRegistrationSettingsForDataAccessEvents();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function EventNameDataAccessAuditingEventRegistrationSettingsChange() Export
	
	Return NStr("vi = 'Kiểm tra truy cập đến dữ liệu.Thay đổi tùy chỉnh ghi nhận sự kiện';
				|ru = 'Аудит доступа к данным.Изменение настроек регистрации событий';
				|en = 'Data access audit.Change event logging settings'; fa = 'Data access audit.Change event logging settings';
				|it = 'Аудит доступа к данным.Изменение настроек регистрации событий';
				|pl = 'Data access audit.Change event logging settings';
				|tr = 'Аудит доступа к данным.Изменение настроек регистрации событий'",
		Common.DefaultLanguageCode());
	
EndFunction

// Parameters:
//  Storage - Undefined - Read from the constant.
//            - ValueStorage - Use the specified one.
//
// Returns:
//  Structure:
//    * Use - Boolean
//    * Content - Array of EventLogAccessEventUseDescription
//    * Comments - Map of KeyAndValue:
//        * Key     - String - Full table name followed by field name. For example, "Catalog.Individuals.DocumentNumber".
//        * Value - String - Arbitrary text
//    * GeneralComment - String - Arbitrary text
//
Function StoredRegistrationSettings(Storage = Undefined) Export
	
	Result = New Structure;
	Result.Insert("Use", False);
	Result.Insert("Content", New Array);
	Result.Insert("Comments", New Map);
	Result.Insert("GeneralComment", "");
	
	If Storage = Undefined Then
		Storage = Constants.RegistrationSettingsForDataAccessEvents.Get();
	EndIf;
	If TypeOf(Storage) <> Type("ValueStorage") Then
		Return Result;
	EndIf;
	
	Value = Storage.Get();
	If TypeOf(Value) <> Type("Structure") Then
		Return Result;
	EndIf;
	
	For Each KeyAndValue In Result Do
		If Not Value.Property(KeyAndValue.Key)
		 Or TypeOf(Value[KeyAndValue.Key]) <> TypeOf(KeyAndValue.Value) Then
			Continue;
		EndIf;
		If KeyAndValue.Key = "Content" Then
			For Each Setting In Value.Content Do
				If TypeOf(Setting) = Type("EventLogAccessEventUseDescription") Then
					Result.Content.Add(Setting);
				EndIf;
			EndDo;
		Else
			Result[KeyAndValue.Key] = Value[KeyAndValue.Key];
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Intended for the correct translation of the log column name.
//
Function ConnectionColumnName() Export
	Return "Connection";
EndFunction

#EndRegion
