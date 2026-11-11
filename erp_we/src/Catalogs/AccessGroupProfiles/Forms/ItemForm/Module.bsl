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
Var WriteParametersBeforeWriteContinued;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ProcessRolesInterface("FillRoles", Object.Roles);
	ProcessRolesInterface("SetUpRoleInterfaceOnFormCreate", ValueIsFilled(Object.Ref));
	
	// Prepare auxiliary data.
	AccessManagementInternal.OnCreateAtServerAllowedValuesEditForm(ThisObject, True);
	StandardExtensionRoles =
		AccessManagementInternalCached.DescriptionStandardRolesSessionExtensions().SessionRoles.All;
	
	// Making the properties always visible.
	
	// Determining if the access restrictions must be set.
	If Not AccessManagement.LimitAccessAtRecordLevel() Then
		Items.AccessKindsAndValues.Visible = False;
	EndIf;
	
	// Determining if the form item editing is possible.
	WithoutEditingSuppliedValues = ReadOnly
		Or Not Object.Ref.IsEmpty()
		  And Catalogs.AccessGroupProfiles.ProfileChangeProhibition(Object, Items.Parent.ReadOnly);
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	If Object.Ref = AccessManagement.ProfileAdministrator()
	   And Not Users.IsFullUser(, Not DataSeparationEnabled) Then
		ReadOnly = True;
	EndIf;
	
	Items.Description.ReadOnly = WithoutEditingSuppliedValues;
	
	// Setting up access kind editing.
	Items.AccessKinds.ReadOnly     = WithoutEditingSuppliedValues;
	Items.AccessValues.ReadOnly = WithoutEditingSuppliedValues;
	Items.SelectPurpose.Enabled = Not WithoutEditingSuppliedValues;
	
	ProcessRolesInterface("SetRolesReadOnly", WithoutEditingSuppliedValues);
	
	SetAvailabilityToDescribeAndRestoreSuppliedProfile();
	
	ProcedureExecutedOnCreateAtServer = True;
	
	UsersInternal.UpdateAssignmentOnCreateAtServer(ThisObject);
	
	If Common.IsStandaloneWorkplace() Then
		ReadOnly = True;
	EndIf;
	
	Items.FormWriteAndClose.Enabled = Not ReadOnly
		And AccessRight("Edit", Metadata.Catalogs.AccessGroupProfiles);
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		PlacementParameters = ModuleAttachableCommands.PlacementParameters();
		PlacementParameters.CommandBar = Items.FormCommands;
		ModuleAttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
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
	
	If ProcedureExecutedOnCreateAtServer Then
		ProcessRolesInterface("FillRoles", Object.Roles);
		ProcessRolesInterface("SetUpRoleInterfaceOnReadAtServer", True);
		
		AccessManagementInternal.OnRereadAtServerAllowedValuesEditForm(
			ThisObject, CurrentObject);
		
		SetAvailabilityToDescribeAndRestoreSuppliedProfile(CurrentObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	ProfileFillingCheckRequired = Not WriteParameters.Property(
		"ProfileAccessGroupsUpdateResponseReceived");
	
	If ValueIsFilled(Object.Ref)
	   And ProfileAccessGroupsUpdateRequired
	   And Not WriteParameters.Property("ProfileAccessGroupsUpdateResponseReceived") Then
		
		Cancel = True;
		WriteParametersBeforeWriteContinued = WriteParameters;
		AttachIdleHandler("BeforeWriteFollowUpIdleHandler", 0.1, True);
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Filling object roles from the collection.
	CurrentObject.Roles.Clear();
	For Each String In RolesCollection Do
		CurrentObject.Roles.Add().Role = Common.MetadataObjectID(
			"Role." + String.Role);
	EndDo;
	
	If WriteParameters.Property("UpdateProfileAccessGroups") Then
		CurrentObject.AdditionalProperties.Insert("UpdateProfileAccessGroups");
	EndIf;
	
	AccessManagementInternal.BeforeWriteAtServerAllowedValuesEditForm(
		ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If CurrentObject.AdditionalProperties.Property(
	         "PersonalAccessGroupsWithUpdatedDescription") Then
		
		WriteParameters.Insert(
			"PersonalAccessGroupsWithUpdatedDescription",
			CurrentObject.AdditionalProperties.PersonalAccessGroupsWithUpdatedDescription);
	EndIf;
	
	AccessManagementInternal.AfterWriteAtServerAllowedValuesEditForm(
		ThisObject, CurrentObject, WriteParameters);
	
	SetAvailabilityToDescribeAndRestoreSuppliedProfile(CurrentObject);
	
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ObjectWasWritten = True;
	ProfileAccessGroupsUpdateRequired = False;
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	Notify("Write_AccessGroupProfiles", New Structure, Object.Ref);
	
	If WriteParameters.Property("PersonalAccessGroupsWithUpdatedDescription") Then
		NotifyChanged(Type("CatalogRef.AccessGroups"));
		
		For Each PersonalAccessGroup In WriteParameters.PersonalAccessGroupsWithUpdatedDescription Do
			Notify("Write_AccessGroups", New Structure, PersonalAccessGroup);
		EndDo;
	EndIf;
	
	If WriteParameters.Property("WriteAndClose") Then
		AttachIdleHandler("CloseForm", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not ProfileFillingCheckRequired Then
		CheckedAttributes.Clear();
		Return;
	EndIf;
	
	VerifiedObjectAttributes = New Array;
	Errors = Undefined;
	
	// Checking whether the metadata contains roles.
	VerifiedObjectAttributes.Add("Roles.Role");
	If Not Items.Roles.ReadOnly Then
		TreeItems = Roles.GetItems();
		For Each String In TreeItems Do
			If Not String.Check Then
				Continue;
			EndIf;
			If String.IsNonExistingRole Then
				CommonClientServer.AddUserError(Errors,
					"Roles[%1].RolesSynonym",
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không tìm thấy vai trò ""%1"" trong metadata.';
																					|ru = 'Роль ""%1"" не найдена в метаданных.';
																					|en = 'Role ""%1"" is not found in the metadata.'; fa = 'Role ""%1"" is not found in the metadata.';
																					|it = 'Il ruolo ""%1"" non è stato trovato nei metadati.';
																					|pl = 'Rola ""%1"" nie została znaleziona w metadanych.';
																					|tr = '""%1"" rolü meta veride bulunamadı.'"), String.Synonym),
					"Roles",
					TreeItems.IndexOf(String),
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không tìm thấy vai trò ""%1"" trong hàng%2 trong siêu dữ liệu.';
																					|ru = 'Роль ""%1"" в строке %2 не найдена в метаданных.';
																					|en = 'Role ""%1"" in line #%2 is not found in the metadata.'; fa = 'Role ""%1"" in line #%2 is not found in the metadata.';
																					|it = 'Il ruolo ""%1"" nella riga %2 non p stato trovato nei metadati.';
																					|pl = 'W metadanych nie znaleziono roli ""%1"" w wierszu %2.';
																					|tr = '%2dizesindeki ""%1"" rolü meta verilerde bulunamadı.'"), String.Synonym, "%1"));
			EndIf;
			If String.IsUnavailableRole Then
				CommonClientServer.AddUserError(Errors,
					"Roles[%1].RolesSynonym",
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Vai trò ""%1"" không khả dụng để ấn định hồ sơ.';
																					|ru = 'Роль ""%1"" недоступна для назначения профиля.';
																					|en = 'Role ""%1"" is not available for profile assignment.'; fa = 'Role ""%1"" is not available for profile assignment.';
																					|it = 'Il ruolo ""%1"" non è disponibile per l''assegnazione del profilo.';
																					|pl = 'Rola ""%1"" jest niedostępna dla przeznaczenia profilu.';
																					|tr = '""%1"" rolü profil atamak için kullanılamaz.'"), String.Synonym),
					"Roles",
					TreeItems.IndexOf(String),
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Vai trò ""%1"" trong dòng%2 không có sẵn để gán hồ sơ.';
																					|ru = 'Роль ""%1"" в строке %2 недоступна для назначения профиля.';
																					|en = 'Role ""%1"" in line #%2 is not available for profile assignment.'; fa = 'Role ""%1"" in line #%2 is not available for profile assignment.';
																					|it = 'Ruolo ""%1"" nella riga %2 non p disponibile per l''assegnazione del profilo.';
																					|pl = 'Rola ""%1"" w wierszu %2 jest niedostępna dla przeznaczenia profilu.';
																					|tr = '%2satırındaki ""%1"" rolü, profil ataması için kullanılamaz.'"), String.Synonym, "%1"));
			EndIf;
		EndDo;
	EndIf;
	
	// Checking for blank and duplicate access kinds and values.
	AccessManagementInternalClientServer.ProcessingOfCheckOfFillingAtServerAllowedValuesEditForm(
		ThisObject, Cancel, VerifiedObjectAttributes, Errors);
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
	CheckedAttributes.Delete(CheckedAttributes.Find("Object"));
	CurrentObject = FormAttributeToValue("Object");
	
	CurrentObject.AdditionalProperties.Insert("VerifiedObjectAttributes",
		VerifiedObjectAttributes);
	
	If Not CurrentObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ProcessRolesInterface("SetUpRoleInterfaceOnLoadSettings", Settings);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccessKinds

&AtClient
Procedure AccessKindsOnChange(Item)
	
	ProfileAccessGroupsUpdateRequired = True;
	
EndProcedure

&AtClient
Procedure AccessKindsOnActivateRow(Item)
	
	AccessManagementInternalClient.AccessKindsOnActivateRow(
		ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AccessKindsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	AccessManagementInternalClient.AccessKindsBeforeAddRow(
		ThisObject, Item, Cancel, Copy, Parent, Var_Group);
	
EndProcedure

&AtClient
Procedure AccessKindsBeforeDeleteRow(Item, Cancel)
	
	AccessManagementInternalClient.AccessKindsBeforeDeleteRow(
		ThisObject, Item, Cancel);
	
EndProcedure

&AtClient
Procedure AccessKindsOnStartEdit(Item, NewRow, Copy)
	
	AccessManagementInternalClient.AccessKindsOnStartEdit(
		ThisObject, Item, NewRow, Copy);
	
EndProcedure

&AtClient
Procedure AccessKindsOnEditEnd(Item, NewRow, CancelEdit)
	
	AccessManagementInternalClient.AccessKindsOnEditEnd(
		ThisObject, Item, NewRow, CancelEdit);
	
EndProcedure

#Region EventHandlersForAccessKindPresentationItemOfFormAccessKindsTable

&AtClient
Procedure AccessKindsAccessKindPresentationOnChange(Item)
	
	AccessManagementInternalClient.AccessKindsAccessKindPresentationOnChange(
		ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AccessKindsAccessKindPresentationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	AccessManagementInternalClient.AccessKindsAccessKindPresentationChoiceProcessing(
		ThisObject, Item, ValueSelected, StandardProcessing);
		
EndProcedure

#EndRegion

#Region EventHandlersForAllAllowedPresentationItemOfFormAccessKindsTable

&AtClient
Procedure AccessKindsAllAllowedPresentationOnChange(Item)
	
	AccessManagementInternalClient.AccessKindsAllAllowedPresentationOnChange(
		ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AccessKindsAllAllowedPresentationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	AccessManagementInternalClient.AccessKindsAllAllowedPresentationChoiceProcessing(
		ThisObject, Item, ValueSelected, StandardProcessing);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersAccessValues

&AtClient
Procedure AccessValuesOnChange(Item)
	
	AccessManagementInternalClient.AccessValuesOnChange(
		ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AccessValuesOnStartEdit(Item, NewRow, Copy)
	
	AccessManagementInternalClient.AccessValuesOnStartEdit(
		ThisObject, Item, NewRow, Copy);
	
EndProcedure

&AtClient
Procedure AccessValuesOnEditEnd(Item, NewRow, CancelEdit)
	
	AccessManagementInternalClient.AccessValuesOnEditEnd(
		ThisObject, Item, NewRow, CancelEdit);
	
EndProcedure

&AtClient
Procedure AccessValuesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	AccessManagementInternalClient.AccessValuesChoiceProcessing(
		ThisObject, Item, ValueSelected, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AccessValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	AccessManagementInternalClient.AccessValueStartChoice(
		ThisObject, Item, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AccessValueClearing(Item, StandardProcessing)
	
	AccessManagementInternalClient.AccessValueClearing(
		ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AccessValueAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	
	AccessManagementInternalClient.AccessValueAutoComplete(
		ThisObject, Item, Text, ChoiceData, Waiting, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AccessValueTextInputCompletion(Item, Text, ChoiceData, StandardProcessing)
	
	AccessManagementInternalClient.AccessValueTextInputCompletion(
		ThisObject, Item, Text, ChoiceData, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRoles

////////////////////////////////////////////////////////////////////////////////
// For the roles interface to work.

&AtClient
Procedure RolesCheckOnChange(Item)
	
	TableRow = Items.Roles.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	If TableRow.Check And TableRow.Name = "InteractiveOpenExtReportsAndDataProcessors" Then
		Notification = New CallbackDescription("RolesMarkOnChangeAfterConfirm", ThisObject);
		UsersInternalClient.ShowSecurityWarning(Notification,
			UsersInternalClientServer.SecurityWarningKinds().BeforeSelectRole);
		
	ElsIf StandardExtensionRoles.Get(TableRow.Name) <> Undefined Then
		TableRow.Check = Not TableRow.Check;
		ShowMessageBox(, NStr("vi = 'Đã tự động thêm và xóa các vai trò chuẩn của phần mở rộng.';
								|ru = 'Стандартные роли расширений добавляются и удаляются автоматически.';
								|en = '1C:Enterprise automatically deletes extensions'' standard roles.'; fa = '1C:Enterprise automatically deletes extensions'' standard roles.';
								|it = 'Ruoli standard delle estensioni aggiunti ed eliminati automaticamente.';
								|pl = 'Standardowe role rozszerzeń są dodawane i usuwane automatycznie.';
								|tr = 'Standart uzantı rolleri otomatik olarak eklenir ve kaldırılır.'"));
	Else
		ProcessRolesInterface("UpdateRoleComposition");
	EndIf;
	
EndProcedure

&AtClient
Procedure RolesMarkOnChangeAfterConfirm(Response, ExecutionParameters) Export
	TableRow = Items.Roles.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;
	If Response = "Continue" Then
		ProcessRolesInterface("UpdateRoleComposition");
	Else
		TableRow.Check = False;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	Write(New Structure("WriteAndClose"));
	
EndProcedure

&AtClient
Procedure RestoreByInitialFilling(Command)
	
	ShowQueryBox(
		New CallbackDescription("RestoreByInitialFillingContinued", ThisObject),
		NStr("vi = 'Phục hồi hồ sơ theo nội dung điền ban đầu?';
			|ru = 'Восстановить профиль по содержимому начального заполнения?';
			|en = 'Do you want to restore the profile to the initial settings?'; fa = 'Do you want to restore the profile to the initial settings?';
			|it = 'Ripristinare il profilo al contenuto di default?';
			|pl = 'Odzyskać profil wg zawartości wypełnienia początkowego?';
			|tr = 'Profilin ilk durumu tekrar yüklensin mi?'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SnowUnusedAccessKinds(Command)
	
	ShowUnusedAccessKindsAtServer();
	
EndProcedure

#Region ForRolesInterfaceOperation

&AtClient
Procedure ShowSelectedRolesOnly(Command)
	
	ProcessRolesInterface("SelectedRolesOnly");
	UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	
EndProcedure

&AtClient
Procedure RolesBySubsystemsGroup(Command)
	
	ProcessRolesInterface("GroupBySubsystems");
	UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	
EndProcedure

&AtClient
Procedure AddRoles(Command)
	
	ProcessRolesInterface("UpdateRoleComposition", "IncludeSelected");
	
	UsersInternalClient.ExpandRoleSubsystems(ThisObject, False);
	
EndProcedure

&AtClient
Procedure RemoveRoles(Command)
	
	ProcessRolesInterface("UpdateRoleComposition", "ClearMarked");
	
EndProcedure

&AtClient
Procedure SelectPurpose(Command)
	CallbackDescription = New CallbackDescription("AfterAssignmentChoice", ThisObject);
	UsersInternalClient.SelectPurpose(ThisObject, NStr("vi = 'Chọn mục đích của hồ sơ nhóm truy cập';
														|ru = 'Выбор назначения профиля групп доступа';
														|en = 'Select access group profile assignment'; fa = 'Select access group profile assignment';
														|it = 'Selezione dell''assegnazione del profilo dei gruppi d''accesso';
														|pl = 'Wybór przeznaczenia profilu grup dostępu';
														|tr = 'Erişim grubu profilini seç'"),,, CallbackDescription);
EndProcedure

&AtClient
Procedure PickAccessValues(Command)
	
	AccessManagementInternalClient.AccessValuesPick(ThisObject);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// The BeforeWrite event handler continuation.
&AtClient
Procedure BeforeWriteFollowUpIdleHandler()
	
	WriteParameters = WriteParametersBeforeWriteContinued;
	WriteParametersBeforeWriteContinued = Undefined;
	
	If CheckFilling() Then
		ShowQueryBox(
			New CallbackDescription("BeforeWriteContinued", ThisObject, WriteParameters),
			QuestionTextUpdateProfileAccessGroups(),
			QuestionDialogMode.YesNoCancel,
			,
			DialogReturnCode.No);
	EndIf;
	
EndProcedure

// The BeforeWrite event handler continuation.
&AtClient
Procedure BeforeWriteContinued(Response, WriteParameters) Export
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Response = DialogReturnCode.Yes Then
		WriteParameters.Insert("UpdateProfileAccessGroups");
	EndIf;
	
	WriteParameters.Insert("ProfileAccessGroupsUpdateResponseReceived");
	
	Write(WriteParameters);
	
EndProcedure

// The RestoreByInitialFilling command handler continued.
&AtClient
Procedure RestoreByInitialFillingContinued(Response, Context) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ShowQueryBox(
		New CallbackDescription("RestoreByInitialFillingCompletion", ThisObject),
		QuestionTextUpdateProfileAccessGroups(),
		QuestionDialogMode.YesNoCancel,
		,
		DialogReturnCode.No);
	
EndProcedure

// The RestoreByInitialFilling command handler continued.
&AtClient
Procedure RestoreByInitialFillingCompletion(Response, Context) Export
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Modified Or ObjectWasWritten Then
		UnlockFormDataForEdit();
	EndIf;
	
	UpdateAccessGroups = (Response = DialogReturnCode.Yes);
	
	ProfileAccessGroups = Undefined;
	InitialAccessGroupProfileFilling(UpdateAccessGroups, ProfileAccessGroups);
	
	Read();
	UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	
	If UpdateAccessGroups Then
		Text =
			NStr("vi = 'Hồ sơ ""%1"" đã được khôi phục về nội dung khởi tạo ban đầu,
			           |nhóm hồ sơ truy cập đã được cập nhật.';
			           |ru = 'Профиль ""%1"" восстановлен по содержимому начального заполнения,
			           |группы доступа профиля обновлены.';
			           |en = 'Profile ""%1"" has been restored.
			           |The access groups are updated.'; fa = 'Profile ""%1"" has been restored.
			           |The access groups are updated.';
			           |it = 'Il profilo ""%1"" è ripristinato al contenuto di default,
			           |i gruppi di accesso del profilo sono stati aggiornati.';
			           |pl = 'Profil ""%1"" został odzyskany wg zawartości wypełnienia początkowego,
			           |grupy dostępu profilu zostały zaktualizowane.';
			           |tr = '""%1"" profili ilk durumuna geri yüklendi.
			           |Erişim grupları güncellendi.'");
	Else
		Text =
			NStr("vi = 'Hồ sơ ""%1"" đã được khôi phục về nội dung khởi tạo ban đầu,
			           |nhóm hồ sơ truy cập đã chưa cập nhật.';
			           |ru = 'Профиль ""%1"" восстановлен по содержимому начального заполнения,
			           |группы доступа профиля не обновлены.';
			           |en = 'Profile ""%1"" has been restored.
			           |The access groups are not updated.'; fa = 'Profile ""%1"" has been restored.
			           |The access groups are not updated.';
			           |it = 'Il profilo ""%1"" è ripristinato al contenuto di default,
			           |i gruppi di accesso del profilo non sono stati aggiornati.';
			           |pl = 'Profil ""%1"" został odzyskany wg zawartości wypełnienia początkowego,
			           |grupy dostępu profilu nie zostały zaktualizowane.';
			           |tr = '""%1"" profili ilk durumuna geri yüklendi.
			           |Erişim grupları güncellenmedi.'");
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Đã khôi phục hồ sơ';
								|ru = 'Профиль восстановлен';
								|en = 'Profile restored'; fa = 'Profile restored';
								|it = 'Profilo ripristinato';
								|pl = 'Profil został odzyskany';
								|tr = 'Profil geri yüklendi'"),
		GetURL(Object.Ref),
		StringFunctionsClientServer.SubstituteParametersToString(Text, Object.Description));
	
	Notify("Write_AccessGroupProfiles", New Structure, Object.Ref);
	
	If UpdateAccessGroups Then
		NotifyChanged(Type("CatalogRef.AccessGroups"));
		
		For Each ProfileAccessGroup In ProfileAccessGroups Do
			Notify("Write_AccessGroups", New Structure, ProfileAccessGroup);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShowUnusedAccessKindsAtServer()
	
	AccessManagementInternal.RefreshUnusedAccessKindsRepresentation(ThisObject);
	
EndProcedure

&AtServer
Procedure SetAvailabilityToDescribeAndRestoreSuppliedProfile(CurrentObject = Undefined)
	
	If CurrentObject = Undefined Then
		CurrentObject = Object;
	EndIf;
	
	If Catalogs.AccessGroupProfiles.HasInitialProfileFilling(CurrentObject.Ref) Then
		
		SuppliedProfileDetails =
			Catalogs.AccessGroupProfiles.SuppliedProfileNote(CurrentObject.Ref);
		
		If Catalogs.AccessGroupProfiles.SuppliedProfileChanged(CurrentObject) Then
			// Defining the rights to restore based on the initial filling.
			Items.RestoreByInitialFilling.Visible =
				Users.IsFullUser(,, False);
			
			Items.SuppliedProfileChanged.Visible = True;
		Else
			Items.RestoreByInitialFilling.Visible = False;
			Items.SuppliedProfileChanged.Visible = False;
		EndIf;
		
		Items.Comment2.Visible = False;
	Else
		Items.RestoreByInitialFilling.Visible = False;
		Items.SuppliedProfileDetails.Visible = False;
		Items.SuppliedProfileChanged.Visible = False;
		Items.Comment1.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Function QuestionTextUpdateProfileAccessGroups()
	
	Return
		NStr("vi = 'Bạn có muốn cập nhật nhóm truy cập bằng cách sử dụng hồ sơ này không?
		           |
		           | Các loại quyền truy cập bổ sung với các giá trị truy cập được chỉ định
		           | sẽ bị xóa và các loại quyền truy cập bị thiếu được thêm vào.';
		           |ru = 'Обновить группы доступа, использующие этот профиль?
		           |
		           |Будут удалены лишние виды доступа с заданными для них
		           |значениями доступа и добавлены недостающие виды доступа.';
		           |en = 'Do you want to update the access groups that use the profile?
		           |
		           |Irrelevant access kinds will be deleted and
		           |the missing access kinds will be added.'; fa = 'Do you want to update the access groups that use the profile?
		           |
		           |Irrelevant access kinds will be deleted and
		           |the missing access kinds will be added.';
		           |it = 'Aggiornare i gruppi di accesso che utilizzano questo profilo?
		           |
		           |Verranno rimossi i tipi eccessivi di accesso con l''accesso specificato per loro
		           |e verranno aggiunti i tipi di accesso mancanti.';
		           |pl = 'Zaktualizować grupy dostępu, wykorzystujące ten profil?
		           |
		           |Zostaną usunięte zbędne rodzaje dostępu z określonymi dla nich
		           |wartościami dostępu i dodane brakujące rodzaje dostępu.';
		           |tr = 'Bu profili kullanan erişim gruplarını güncellemek ister misiniz?
		           |
		           |Belirtilen
		           |erişim değerlerine sahip aşırı erişim türleri silinecek ve eksik erişim türleri eklenecektir.'");
		
EndFunction

&AtClient
Procedure CloseForm()
	
	Close();
	
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

#Region ForRolesInterfaceOperation

&AtServer
Procedure ProcessRolesInterface(Action, MainParameter = Undefined)
	
	ActionParameters = New Structure;
	ActionParameters.Insert("MainParameter", MainParameter);
	ActionParameters.Insert("Form",            ThisObject);
	ActionParameters.Insert("RolesCollection",   RolesCollection);
	
	ActionParameters.Insert("HideFullAccessRole",
		Object.Ref <> AccessManagement.ProfileAdministrator());
	
	ActionParameters.Insert("RolesAssignment",
		AccessManagementInternalClientServer.ProfileAssignment(Object));
	
	ActionParameters.Insert("StandardExtensionRoles",
		AccessManagementInternalCached.DescriptionStandardRolesSessionExtensions().SessionRoles);
	
	UsersInternal.ProcessRolesInterface(Action, ActionParameters);
	
EndProcedure

&AtServer
Procedure InitialAccessGroupProfileFilling(Val UpdateAccessGroups, ProfileAccessGroups)
	
	Catalogs.AccessGroupProfiles.FillSuppliedProfile(
		Object.Ref, UpdateAccessGroups);
	
	If Not UpdateAccessGroups Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Profile", Object.Ref);
	Query.Text =
	"SELECT
	|	AccessGroups.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	AccessGroups.Profile = &Profile";
	
	ProfileAccessGroups = Query.Execute().Unload().UnloadColumn("Ref");
	
EndProcedure

&AtClient
Procedure AfterAssignmentChoice(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Modified = True;
		ProcessRolesInterface("RefreshRolesTree");
		UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion