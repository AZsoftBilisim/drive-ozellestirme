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
	Else
		Items.List.ChoiceMode = False;
	EndIf;
	
	PersonalAccessGroupsParent = Catalogs.AccessGroups.PersonalAccessGroupsParent(True);
	
	SimplifiedAccessRightsSetupInterface = AccessManagementInternal.SimplifiedAccessRightsSetupInterface();
	
	If SimplifiedAccessRightsSetupInterface Then
		CommonClientServer.SetFormItemProperty(Items,
			"FormCreate", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"ListContextMenuCreate", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"FormCopy", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"ListContextMenuCopy", "Visible", False);
	EndIf;
	
	List.Parameters.SetParameterValue("Profile", Parameters.Profile);
	If ValueIsFilled(Parameters.Profile) Then
		Items.Profile.Visible = False;
		Items.List.Representation = TableRepresentation.List;
		AutoTitle = False;
		
		Title = NStr("vi = 'Nhóm truy cập';
					|ru = 'Группы доступа';
					|en = 'Access groups'; fa = 'گروه‌های دسترسی';
					|it = 'Gruppi di accesso';
					|pl = 'Grupy dostępu';
					|tr = 'Erişim grupları'");
		
		CommonClientServer.SetFormItemProperty(Items,
			"FormCreateFolder", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"ListContextMenuCreateFolder", "Visible", False);
	EndIf;
	
	If Not AccessRight("Read", Metadata.Catalogs.AccessGroupProfiles) Then
		Items.Profile.Visible = False;
	EndIf;
	
	If Not Users.IsFullUser() Then
		// Hiding the Administrators access group.
		CommonClientServer.SetDynamicListFilterItem(
			List, "Ref", AccessManagement.AdministratorsAccessGroup(),
			DataCompositionComparisonType.NotEqual, , True);
	EndIf;
	
	ChoiceMode = Parameters.ChoiceMode;
	
	If Parameters.ChoiceMode Then
		
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		Items.List.ChoiceFoldersAndItems = Parameters.ChoiceFoldersAndItems;
		
		AutoTitle = False;
		If Parameters.CloseOnChoice = False Then
			// Pick mode.
			Items.List.SelectionMode = TableSelectionMode.MultiRow;
			
			Title = NStr("vi = 'Chọn nhóm truy cập';
						|ru = 'Подбор групп доступа';
						|en = 'Pick access groups'; fa = 'Pick access groups';
						|it = 'Selezione dei gruppi di accesso';
						|pl = 'Wybór grup dostępu';
						|tr = 'Erişim gruplarını seçin'");
		Else
			Items.List.MultipleChoice = False;
			Title = NStr("vi = 'Chọn nhóm truy cập';
						|ru = 'Выбор группы доступа';
						|en = 'Select access group'; fa = 'Select access group';
						|it = 'Scelta del gruppo di accesso';
						|pl = 'Wybór grupy dostępu';
						|tr = 'Erişim grubu seç'");
		EndIf;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ReadOnly = True;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	
	ListOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	If Not StandardSubsystemsClient.IsDynamicListItem(Items.List) Then
		Return;
	EndIf;
	
	CurrentData = CurrentTableData(Items.List);
	TransferAvailable = Not ValueIsFilled(CurrentData.User)
	                  And CurrentData.Ref <> PersonalAccessGroupsParent;
	
	CommonClientServer.SetFormItemProperty(Items,
		"FormMoveItem", "Enabled", TransferAvailable);
	
	CommonClientServer.SetFormItemProperty(Items,
		"ListContextMenuMoveItem", "Enabled", TransferAvailable);
	
	CommonClientServer.SetFormItemProperty(Items,
		"ListMoveItem", "Enabled", TransferAvailable);
	
EndProcedure

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	If Value = PersonalAccessGroupsParent Then
		StandardProcessing = False;
		ShowMessageBox(, NStr("vi = 'Nhóm này chỉ dành cho nhóm truy cập cá nhân.';
								|ru = 'Эта группа только для персональных групп доступа.';
								|en = 'The group can contain only personal access groups.'; fa = 'The group can contain only personal access groups.';
								|it = 'Questo gruppo è solo per i gruppi d''accesso personali.';
								|pl = 'Ta grupa jest przeznaczona wyłącznie dla prywatnych grup dostępu.';
								|tr = 'Bu grup sadece kişisel erişim grupları içindir.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Parent = PersonalAccessGroupsParent Then
		
		Cancel = True;
		
		If Var_Group Then
			ShowMessageBox(, NStr("vi = 'Trong nhóm này không sử dụng các nhóm con.';
									|ru = 'В этой группе не используются подгруппы.';
									|en = 'The group cannot contain subgroups.'; fa = 'The group cannot contain subgroups.';
									|it = 'Questo gruppo non utilizza sottogruppi.';
									|pl = 'W tej grupie nie są używane podgrupy.';
									|tr = 'Bu klasör alt klasörler içeremez.'"));
			
		ElsIf SimplifiedAccessRightsSetupInterface Then
			ShowMessageBox(,
				NStr("vi = 'Nhóm truy cập cá nhân
				           | chỉ được tạo trong biểu mẫu ""Quyền truy cập"".';
				           |ru = 'Персональные группы доступа
				           |создаются только в форме ""Права доступа"".';
				           |en = 'Personal access groups
				           |can be created only in the ""Access rights"" form.'; fa = 'Personal access groups
				           |can be created only in the ""Access rights"" form.';
				           |it = 'I gruppi di accesso personali
				           |vengono creati solamente in forma ""Diritti d''accesso"".';
				           |pl = 'Prywatne grupy dostępu
				           |są tworzone tylko w formularzu ""Prawa dostępu"".';
				           |tr = 'Kişisel erişim grubu yalnızca 
				           |""Erişim hakları"" formunda oluşturulabilir.'"));
		Else
			ShowMessageBox(, NStr("vi = 'Không sử dụng nhóm truy cập cá nhân.';
									|ru = 'Персональные группы доступа не используются.';
									|en = 'Personal access groups are disabled.'; fa = 'Personal access groups are disabled.';
									|it = 'I gruppi d''accesso personali non vengono utilizzati.';
									|pl = 'Prywatne grupy dostępu nie są używane.';
									|tr = 'Kişisel erişim grupları mevcut değildir.'"));
		EndIf;
		
	ElsIf Not Var_Group
	        And SimplifiedAccessRightsSetupInterface Then
		
		Cancel = True;
		
		ShowMessageBox(,
			NStr("vi = 'Chỉ sử dụng các nhóm truy cập cá nhân, 
			           |được tạo trong biểu mẫu ""Quyền truy cập"".';
			           |ru = 'Используются только персональные группы доступа,
			           |которые создаются только в форме ""Права доступа"".';
			           |en = 'Personal access groups can be created
			           |only in the ""Access rights"" form.'; fa = 'Personal access groups can be created
			           |only in the ""Access rights"" form.';
			           |it = 'Vengono utilizzati solo gruppi d''accesso personali,
			           |che vengono creati solamente in forma ""Diritti d''accesso"".';
			           |pl = 'Są używane wyłącznie prywatne grupy dostępu,
			           |które są tworzone tylko w formularzu ""Prawa dostępu"".';
			           |tr = 'Yalnızca ""Erişim hakları"" formunda oluşturulan kişisel erişim grupları 
			           |kullanılabilir.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	CurrentData = Item.CurrentData;
	
	If CurrentData = Undefined
	 Or CurrentData.IsFolder Then
		Return;
	EndIf;
	
	Cancel = True;
	
	FormParameters = New Structure("Key", CurrentData.Ref);
	OpenForm("Catalog.AccessGroups.ObjectForm", FormParameters, Item);
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	For Each ListLine In Rows Do
		If TypeOf(ListLine.Key) <> Type("CatalogRef.AccessGroups") Then
			Continue;
		EndIf;
		Data = ListLine.Value.Data;
		
		If Data.IsFolder
		 Or Not ValueIsFilled(Data.User) Then
			Continue;
		EndIf;
		
		Data.Description =
			AccessManagementInternalClientServer.PresentationAccessGroups(Data);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	If String = PersonalAccessGroupsParent Then
		StandardProcessing = False;
		ShowMessageBox(, NStr("vi = 'Thư mục này chỉ dành cho nhóm truy cập cá nhân.';
								|ru = 'Эта папка только для персональных групп доступа.';
								|en = 'This folder is for personal access groups only.'; fa = 'This folder is for personal access groups only.';
								|it = 'Questa cartella è solo per i gruppi d''accesso personali.';
								|pl = 'Ten folder jest przeznaczony wyłącznie dla prywatnych grup dostępu.';
								|tr = 'Bu klasör sadece kişisel erişim grupları içindir.'"));
		
	ElsIf DragParameters.Value = PersonalAccessGroupsParent Then
		StandardProcessing = False;
		ShowMessageBox(, NStr("vi = 'Chưa chuyển thư mục nhóm truy cập cá nhân.';
								|ru = 'Папка персональных групп доступа не переносится.';
								|en = 'Cannot move a personal access groups folder.'; fa = 'Cannot move a personal access groups folder.';
								|it = 'La cartella dei gruppi d''accesso personali non viene migrata.';
								|pl = 'Folder prywatnych grup dostępu nie może zostać przeniesiony.';
								|tr = 'Kişisel erişim grupları klasörü taşınamaz.'"));
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ListOnChangeAtServer()
	
	AccessManagementInternal.StartAccessUpdate();
	
EndProcedure

// Parameters:
//  FormTable - FormDataCollection
// 
// Returns:
//  FormDataStructure:
//   * Ref - CatalogRef.AccessGroups
//   * User - CatalogRef.Users
//                  - CatalogRef.ExternalUsers
//
&AtClient
Function CurrentTableData(FormTable)
	Return FormTable.CurrentData;
EndFunction

#EndRegion

#Region Private

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