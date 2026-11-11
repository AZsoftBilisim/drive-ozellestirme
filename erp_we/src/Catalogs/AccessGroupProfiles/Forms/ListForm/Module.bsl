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
	
	If Parameters.ChoiceMode Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "SelectionPick");
	EndIf;
	
	If Parameters.ChoiceMode Then
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		
		// Hide the Administrator profile.
		CommonClientServer.SetDynamicListFilterItem(
			List, "Ref", AccessManagement.ProfileAdministrator(),
			DataCompositionComparisonType.NotEqual, , True);
		
		Items.List.ChoiceFoldersAndItems = Parameters.ChoiceFoldersAndItems;
		
		AutoTitle = False;
		If Parameters.CloseOnChoice = False Then
			// Pick mode.
			Items.List.MultipleChoice = True;
			Items.List.SelectionMode = TableSelectionMode.MultiRow;
			
			Title = NStr("vi = 'Chọn hồ sơ nhóm truy cập';
						|ru = 'Подбор профилей групп доступа';
						|en = 'Pick access group profiles'; fa = 'Pick access group profiles';
						|it = 'Scelta dei profili dei gruppi di accesso';
						|pl = 'Wybór profili grup dostępu';
						|tr = 'Erişim grubu profillerini seç'");
		Else
			Title = NStr("vi = 'Chọn hồ sơ nhóm truy cập';
						|ru = 'Выбор профиля групп доступа';
						|en = 'Select access group profile'; fa = 'Select access group profile';
						|it = 'Selezione del profilo dei gruppi d''accesso';
						|pl = 'Wybór profilu grup dostępu';
						|tr = 'Erişim grubu profilini seç'");
		EndIf;
	Else
		Items.List.ChoiceMode = False;
	EndIf;
	
	ShowProfiles = ?(Parameters.ProfilesWithRolesMarkedForDeletion, "Obsolete", "AllProfiles");
	If Not Parameters.ChoiceMode Then
		SetFilter();
	Else
		Items.ShowProfiles.Visible = False;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ReadOnly = True;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		PlacementParameters = ModuleAttachableCommands.PlacementParameters();
		PlacementParameters.CommandBar = Items.CommandBar;
		ModuleAttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowProfilesOnChange(Item)
	
	SetFilter();
	
EndProcedure

&AtClient
Procedure UsersKindStartChoice(Item, ChoiceData, StandardProcessing)
	
	CallbackDescription = New CallbackDescription("AfterAssignmentChoice", ThisObject);
	
	UsersInternalClient.SelectPurpose(ThisObject,
		NStr("vi = 'Chọn mục đích của hồ sơ';
			|ru = 'Выбор назначения профилей';
			|en = 'Select profile assignment'; fa = 'Select profile assignment';
			|it = 'Selezione delle assegnazioni dei profili';
			|pl = 'Wybór przeznaczenia profili';
			|tr = 'Profil amaçlarının seçimi'"), True, True, CallbackDescription);
	
EndProcedure

&AtClient
Procedure UsersKindClearing(Item, StandardProcessing)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Ref.Purpose.UsersType", , , , False);
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	
	ListOnChangeAtServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	UpdateAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateAtServer()
	
	SetFilter();
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure SetFilter()
	
	If ShowProfiles = "Obsolete" Then
		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref",
			Catalogs.AccessGroupProfiles.IncompatibleAccessGroupsProfiles(),
			DataCompositionComparisonType.InList, , True);
	Else
		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref", , , , False);
	EndIf;
	
	If ShowProfiles = "Supplied1" Then
		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref.SuppliedDataID",
			CommonClientServer.BlankUUID(),
			DataCompositionComparisonType.NotEqual, , True);
		
	ElsIf ShowProfiles = "UnsuppliedProfiles" Then
		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref.SuppliedDataID",
			CommonClientServer.BlankUUID(),
			DataCompositionComparisonType.Equal, , True);
	Else
		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref.SuppliedDataID", , , , False);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAssignmentChoice(TypesArray, AdditionalParameters) Export
	
	If TypesArray.Count() <> 0 Then
		CommonClientServer.SetDynamicListFilterItem(List,
			"Ref.Purpose.UsersType",
			TypesArray,
			DataCompositionComparisonType.InList, , True);
	Else
		CommonClientServer.SetDynamicListFilterItem(
			List, "Ref.Purpose.UsersType", , , , False);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ListOnChangeAtServer()
	
	AccessManagementInternal.StartAccessUpdate();
	
EndProcedure

// StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
	ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
	ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
	ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion
