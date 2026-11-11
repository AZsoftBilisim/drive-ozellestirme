///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
//                          FORM USAGE                                         //
//
// Additional open parameters:
//
// AdvancedPick - Boolean - If set to "True", open the extended user pick form.
//  It is used along with the "ExtendedPickFormParameters".
// ExtendedPickFormParameters - String - Address in the temporary storage with the structure
//  "UsersInternal.NewParametersOfExtendedPickForm".
//

#Region Variables

&AtClient
Var LastItem;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	// The initial setting value (before loading data from the settings).
	SelectHierarchy = True;
	
	NewStoredParameters1();
	
	FillDynamicListParameters(Parameters.Purpose);
	
	If Parameters.ChoiceMode Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "SelectionPick");
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		
	ElsIf Users.IsFullUser() Then
		// Adding the filter by users added by the person responsible for the list.
		CommonClientServer.SetDynamicListFilterItem(
			ExternalUsersList, "Prepared", True, ,
			NStr("vi = 'Chuẩn bị chịu trách nhiệm danh sách';
				|ru = 'Подготовленные ответственным за список';
				|en = 'Users are submitted for authorization'; fa = 'Users are submitted for authorization';
				|it = 'Preparati dal responsabile della lista';
				|pl = 'Przygotowano przez osobę odpowiedzialną za listę';
				|tr = 'Liste sorumlusu tarafından hazırlananlar'"), False,
			DataCompositionSettingsItemViewMode.Normal);
	EndIf;
	
	// If the parameter value is True, hiding users with empty IDs.
	If Parameters.HideUsersWithoutMatchingIBUsers Then
		CommonClientServer.SetDynamicListFilterItem(
			ExternalUsersList,
			"IBUserID",
			CommonClientServer.BlankUUID(),
			DataCompositionComparisonType.NotEqual);
	EndIf;
	
	ApplyConditionalAppearanceAndHideInvalidExternalUsers();
	SetExternalUserListParametersForSetPasswordCommand();
	SetAllExternalUsersGroupOrder(ExternalUsersGroups);
	
	StoredParameters.AdvancedPick = Parameters.AdvancedPick;
	Items.SelectedUsersAndGroups.Visible = StoredParameters.AdvancedPick;
	Items.UsersKind.Visible = Not StoredParameters.AdvancedPick;
	
	If Not AccessRight("Edit", Metadata.Catalogs.ExternalUsersGroups) Then
		Items.ExternalUsersListContextMenuAssignGroups.Visible = False;
		Items.AssignGroups.Visible = False;
	EndIf;
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	If Not Users.IsFullUser(, Not DataSeparationEnabled) Then
		If Items.Find("IBUsers") <> Undefined Then
			Items.IBUsers.Visible = False;
		EndIf;
		Items.ExternalUsersInfo.Visible = False;
	EndIf;
	
	If Parameters.ChoiceMode Then
		
		If Items.Find("IBUsers") <> Undefined Then
			Items.IBUsers.Visible = False;
		EndIf;
		Items.ExternalUsersInfo.Visible = False;
		Items.ExternalUsersGroups.ChoiceMode = StoredParameters.SelectExternalUsersGroups;
		
		// Hiding the user passed from the user selection form.
		If TypeOf(Parameters.UsersToHide) = Type("ValueList") Then
			CommonClientServer.SetDynamicListFilterItem(
				ExternalUsersList,
				"Ref",
				Parameters.UsersToHide,
				DataCompositionComparisonType.NotInList);
		EndIf;
		
		// Disabling dragging users in the "select users" and "pick users" forms.
		Items.ExternalUsersList.EnableStartDrag = False;
		
		If ValueIsFilled(Parameters.NonExistingIBUsersIDs) Then
			CommonClientServer.SetDynamicListFilterItem(
				ExternalUsersList, "IBUserID",
				Parameters.NonExistingIBUsersIDs,
				DataCompositionComparisonType.InList, , True,
				DataCompositionSettingsItemViewMode.Inaccessible);
		EndIf;
		
		If Parameters.CloseOnChoice = False Then
			// Pick mode.
			Items.ExternalUsersList.MultipleChoice = True;
			
			If StoredParameters.AdvancedPick Then
				StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "AdvancedPick");
				ChangeExtendedPickFormParameters();
			EndIf;
			
			If StoredParameters.SelectExternalUsersGroups Then
				Items.ExternalUsersGroups.MultipleChoice = True;
			EndIf;
		EndIf;
	Else
		Items.ExternalUsersList.ChoiceMode  = False;
		Items.ExternalUsersGroups.ChoiceMode = False;
		Items.Comments.Visible = False;
		
		CommonClientServer.SetFormItemProperty(Items,
			"SelectExternalUser", "Visible", False);
		
		CommonClientServer.SetFormItemProperty(Items,
			"SelectExternalUsersGroup", "Visible", False);
	EndIf;
	
	ConfigureUserGroupsUsageForm(False, True);
	
	If Not Common.SubsystemExists("StandardSubsystems.BatchEditObjects")
	 Or Not Users.IsFullUser() Then
		
		Items.FormChangeSelectedItems.Visible = False;
		Items.ExternalUsersListContextMenuChangeSelectedItems.Visible = False;
	EndIf;
	
	ObjectDetails = New Structure;
	ObjectDetails.Insert("Ref", Catalogs.Users.EmptyRef());
	ObjectDetails.Insert("IBUserID", CommonClientServer.BlankUUID());
	AccessLevel = UsersInternal.UserPropertiesAccessLevel(ObjectDetails);
	
	If Not AccessLevel.ListManagement Then
		Items.FormSetPassword.Visible = False;
		Items.ExternalUsersListContextMenuSetPassword.Visible = False;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ReadOnly = True;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.EndAndClose.Representation = ButtonRepresentation.Picture;
	EndIf;
	
	UsersInternal.SetUpFieldDynamicListPicNum(ExternalUsersList);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Parameters.ChoiceMode Then
		CurrentFormItemModificationCheck();
	EndIf;
	
#If MobileClient Then
	If StoredParameters.UseGroups Then
		Items.GroupsGroup.Title = ?(Items.ExternalUsersGroups.CurrentData = Undefined,
			NStr("vi = 'Nhóm người sử dụng ngoài';
				|ru = 'Группы внешних пользователей';
				|en = 'External user groups'; fa = 'گروه‌های کاربران خارجی';
				|it = 'Gruppi di utenti esterni';
				|pl = 'Grupy zewnętrznych użytkowników';
				|tr = 'Dış kullanıcı grupları'"),
			String(Items.ExternalUsersGroups.CurrentData.Ref));
	EndIf;
#EndIf
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_ExternalUsersGroups")
	   And Source = Items.ExternalUsersGroups.CurrentRow
	 Or Upper(EventName) = Upper("ArrangeUsersInGroups")
	 Or Upper(EventName) = Upper("Write_AccessGroups") Then
		
		Items.ExternalUsersGroups.Refresh();
		Items.ExternalUsersList.Refresh();
		RefreshFormContentOnGroupChange(ThisObject);
		
	ElsIf Upper(EventName) = Upper("Write_ConstantsSet") Then
		
		If Upper(Source) = Upper("UseUserGroups") Then
			AttachIdleHandler("UserGroupsUsageOnChange", 0.1, True);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeImportingDataFromSettingsAtServer(Settings)
	
	If TypeOf(Settings["SelectHierarchy"]) = Type("Boolean") Then
		SelectHierarchy = Settings["SelectHierarchy"];
	EndIf;
	
	If Not SelectHierarchy Then
		RefreshFormContentOnGroupChange(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectHierarchyOnChange(Item)
	
	RefreshFormContentOnGroupChange(ThisObject);
	
EndProcedure

&AtClient
Procedure ShowInvalidUsersOnChange(Item)
	ToggleInvalidUsersVisibility(ShowInvalidUsers);
EndProcedure

&AtClient
Procedure UsersKindStartChoice(Item, ChoiceData, StandardProcessing)
	
	CallbackDescription = New CallbackDescription("AfterAssignmentChoice", ThisObject);
	UsersInternalClient.SelectPurpose(ThisObject, NStr("vi = 'Chọn dạng người sử dụng';
														|ru = 'Выбор вида пользователей';
														|en = 'Select users type'; fa = 'Select users type';
														|it = 'Selezione del tipo degli utenti';
														|pl = 'Wybór rodzaju użytkowników';
														|tr = 'Kullanıcı türünün seçimi'"), False, True, CallbackDescription);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExternalUsersGroups

&AtClient
Procedure ExternalUsersGroupsOnChange(Item)
	
	ListOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure ExternalUsersGroupsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Not Parameters.ChoiceMode
	 Or Items.ExternalUsersGroups.ChoiceMode Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	If StoredParameters.AdvancedPick Then
		GetPicturesAndFillSelectedItemsList(
			CommonClientServer.ValueInArray(RowSelected));
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalUsersGroupsOnActivateRow(Item)
	
	RefreshFormContentOnGroupChange(ThisObject);
	
#If MobileClient Then
	If Not StoredParameters.AdvancedPick Then
		Items.GroupsGroup.Title = ?(Items.ExternalUsersGroups.CurrentData = Undefined,
			NStr("vi = 'Nhóm người sử dụng ngoài';
				|ru = 'Группы внешних пользователей';
				|en = 'External user groups'; fa = 'گروه‌های کاربران خارجی';
				|it = 'Gruppi di utenti esterni';
				|pl = 'Grupy zewnętrznych użytkowników';
				|tr = 'Dış kullanıcı grupları'"),
			String(Items.ExternalUsersGroups.CurrentData.Ref));
		CurrentItem = Items.ExternalUsersList;
	EndIf;
#EndIf
	
EndProcedure

&AtClient
Procedure ExternalUsersGroupsValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not StoredParameters.AdvancedPick Then
		NotifyChoice(Value);
	Else
		GetPicturesAndFillSelectedItemsList(Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalUsersGroupsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy Then
		Cancel = True;
		FormParameters = New Structure;
		
		If ValueIsFilled(Items.ExternalUsersGroups.CurrentRow) Then
			
			FormParameters.Insert(
				"FillingValues",
				New Structure("Parent", Items.ExternalUsersGroups.CurrentRow));
		EndIf;
		
		OpenForm(
			"Catalog.ExternalUsersGroups.ObjectForm",
			FormParameters,
			Items.ExternalUsersGroups);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalUsersGroupsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ExternalUsersGroupsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If SelectHierarchy Then
		ShowMessageBox(,
			NStr("vi = 'Để kéo và thả người sử dụng vào các nhóm, hãy bỏ chọn
			           |hộp kiểm ""Hiển thị người sử dụng của các nhóm cấp dưới"".';
			           |ru = 'Для перетаскивания пользователя в группы отключите
			           |флажок ""Показывать пользователей нижестоящих групп"".';
			           |en = 'To allow dragging users to groups, clear the
			           |""Show users that belong to subgroups"" check box.'; fa = 'To allow dragging users to groups, clear the
			           |""Show users that belong to subgroups"" check box.';
			           |it = 'Per trascinare un utente nei gruppi, disattivare
			           |il contrassegno ""Mostrare utenti dei gruppi sotto"".';
			           |pl = 'Aby przeciągać użytkowników do grup, należy odznaczyć
			           |pole wyboru ""Pokazuj użytkowników podrzędnych grup"".';
			           |tr = 'Bir kullanıcıyı gruplara sürüklemek için devre dışı bırakın
			           |""Alt grupların kullanıcılarını göster"" onay kutusu.'"));
		Return;
	EndIf;
	
	If Items.ExternalUsersGroups.CurrentRow = String
		Or String = Undefined Then
		Return;
	EndIf;
	
	If DragParameters.Action = DragAction.Move Then
		Move = True;
	Else
		Move = False;
	EndIf;
	
	CurrentGroupRow = Items.ExternalUsersGroups.CurrentRow;
	GroupWithAllAuthorizationObjectsType = 
		Items.ExternalUsersGroups.RowData(CurrentGroupRow).AllAuthorizationObjects;
	
	If String = StoredParameters.AllUsersGroup
		And GroupWithAllAuthorizationObjectsType Then
		UserMessage = New Structure("Message, HasErrors, Users",
			NStr("vi = 'Trong nhóm có kiểu người tham gia ""Tất cả người sử dụng có kiểu đã chọn"" không thể loại trừ người sử dụng.';
				|ru = 'Из групп с типом участников ""Все пользователи заданного типа"" исключение пользователей невозможно.';
				|en = 'Users cannot be removed from groups with an ""All users of the specified types"" flag.'; fa = 'Users cannot be removed from groups with an ""All users of the specified types"" flag.';
				|it = 'Dai gruppi con il tipo di partecipanti ""Tutti gli utenti del tipo specificato"" l''esclusione degli utenti è impossibile.';
				|pl = 'Usuwanie użytkowników z grup o typie członków ""Wszyscy użytkownicy określonego rodzaju"" nie jest możliwe.';
				|tr = 'Üye türü ""Belirlenen türe ait tüm kullanıcılar"" olan gruplardan üye çıkarılamaz.'"),
			True,
			Undefined);
	Else
		GroupMarkedForDeletion = Items.ExternalUsersGroups.RowData(String).DeletionMark;
		UsersCount = DragParameters.Value.Count();
		ActionExcludeUser = (StoredParameters.AllUsersGroup = String);
		AddToGroup = (StoredParameters.AllUsersGroup = CurrentGroupRow) Or GroupWithAllAuthorizationObjectsType;
		
		If UsersCount = 1 Then
			If ActionExcludeUser Then
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Loại trừ người sử dụng %1 khỏi nhóm ""%2""?';
						|ru = 'Исключить пользователя ""%1"" из группы ""%2""?';
						|en = 'Do you want to remove user ""%1"" from group ""%2""?'; fa = 'Do you want to remove user ""%1"" from group ""%2""?';
						|it = 'Escludere l''utente ""%1"" dal gruppo ""%2""?';
						|pl = 'Wykluczyć użytkownika ""%1"" z grupy ""%2""?';
						|tr = '""%1"" kullanıcısı ""%2"" grubundan çıkarılsın mı?'"),
					String(DragParameters.Value[0]),
					String(Items.ExternalUsersGroups.CurrentRow));
				
			ElsIf Not GroupMarkedForDeletion Then
				If AddToGroup Then
					Template = NStr("vi = 'Nhập người sử dụng %1 vào nhóm ""%2""?';
									|ru = 'Включить пользователя ""%1"" в группу ""%2""?';
									|en = 'Do you want to add user ""%1"" to group ""%2""?'; fa = 'Do you want to add user ""%1"" to group ""%2""?';
									|it = 'Includere l''utente ""%1"" nel gruppo ""%2""?';
									|pl = 'Dodać użytkownika ""%1"" do grupy ""%2""?';
									|tr = '""Alt kullanıcılarını göster"" onay kutusu ""%1"" gruba ""%2""?'");
				ElsIf Move Then
					Template = NStr("vi = 'Chuyển người sử dụng %1 vào nhóm ""%2""?';
									|ru = 'Переместить пользователя ""%1"" в группу ""%2""?';
									|en = 'Do you want to move user ""%1"" to group ""%2""?'; fa = 'Do you want to move user ""%1"" to group ""%2""?';
									|it = 'Spostare l''utente ""%1"" nel gruppo ""%2""?';
									|pl = 'Przenieś użytkownika ""%1"" do grupy ""%2""?';
									|tr = 'Kullanıcıyı taşı ""%1"" gruba ""%2""?'");
				Else
					Template = NStr("vi = 'Sao chép người sử dụng %1 vào nhóm ""%2""?';
									|ru = 'Скопировать пользователя ""%1"" в группу ""%2""?';
									|en = 'Do you want to copy user ""%1"" to group ""%2""?'; fa = 'Do you want to copy user ""%1"" to group ""%2""?';
									|it = 'Copiare l''utente ""%1"" nel gruppo ""%2""?';
									|pl = 'Kopiować użytkownika ""%1"" do grupy ""%2""?';
									|tr = 'Kullanıcıyı Kopyala ""%1"" gruba ""%2""?'");
				EndIf;
				
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					Template,
					String(DragParameters.Value[0]),
					String(String));
			Else
				If AddToGroup Then
					Template = NStr("vi = 'Nhóm ""%1"" đã được đánh dấu để xóa. Bao gồm người dùng ""%2"" trong nhóm này?';
									|ru = 'Группа ""%1"" помечена на удаление. Включить пользователя ""%2"" в эту группу?';
									|en = 'Group ""%1"" is marked for deletion. Do you want to add user ""%2"" to the group?'; fa = 'Group ""%1"" is marked for deletion. Do you want to add user ""%2"" to the group?';
									|it = 'Gruppo ""%1"" è contrassegnato per l''eliminazione. Includere l''utente ""%2"" in questo gruppo?';
									|pl = 'Grupa ""%1"" jest zaznaczona do usunięcia. Dodać użytkownika ""%2"" do tej grupy?';
									|tr = 'Grup ""%1"" silinmek üzere işaretlenmiştir. Kullanıcıyı Etkinleştir""%2""bu gruba?'");
				ElsIf Move Then
					Template = NStr("vi = 'Nhóm ""%1"" đã được đánh dấu để xóa. Chuyển người dùng ""%2"" vào nhóm này?';
									|ru = 'Группа ""%1"" помечена на удаление. Переместить пользователя ""%2"" в эту группу?';
									|en = 'Group ""%1"" is marked for deletion. Do you want to move user ""%2"" to the group?'; fa = 'Group ""%1"" is marked for deletion. Do you want to move user ""%2"" to the group?';
									|it = 'Gruppo ""%1"" è contrassegnato per l''eliminazione. Spostare l''utente ""%2"" in questo gruppo?';
									|pl = 'Grupa ""%1"" jest zaznaczona do usunięcia. Przenieść użytkownika ""%2"" do tej grupy?';
									|tr = 'Grup ""%1"" silinmek üzere işaretlenmiştir. ""%2"" kullanıcısı bu gruba taşınsın mı?'");
				Else
					Template = NStr("vi = 'Nhóm ""%1"" đã đánh dấu để xóa. Sao chép người dùng ""%2"" vào nhóm này?';
									|ru = 'Группа ""%1"" помечена на удаление. Скопировать пользователя ""%2"" в эту группу?';
									|en = 'Group ""%1"" is marked for deletion. Do you want to copy user ""%2"" to the group?'; fa = 'Group ""%1"" is marked for deletion. Do you want to copy user ""%2"" to the group?';
									|it = 'Gruppo ""%1"" è contrassegnato per l''eliminazione. Copiare l''utente ""%2"" in questo gruppo?';
									|pl = 'Grupa ""%1"" jest zaznaczona do usunięcia. Kopiować użytkownika ""%2"" do tej grupy?';
									|tr = '""%1"" grubu silinmek üzere işaretlendi. ""%2"" kullanıcısı bu gruba kopyalansın mı?'");
				EndIf;
				
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					Template,
					String(String),
					String(DragParameters.Value[0]));
			EndIf;
		Else
			If ActionExcludeUser Then
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Loại trừ người sử dụng (%1) khỏi nhóm ""%2""?';
						|ru = 'Исключить пользователей (%1) из группы ""%2""?';
						|en = 'Do you want to remove %1 users from group ""%2""?'; fa = 'Do you want to remove %1 users from group ""%2""?';
						|it = 'Escludere gli utenti (%1) dal gruppo ""%2""?';
						|pl = 'Wykluczyć użytkowników (%1) z grupy ""%2""?';
						|tr = '%1 kullanıcıları ""%2"" grubundan çıkarılsın mı?'"),
					UsersCount,
					String(Items.ExternalUsersGroups.CurrentRow));
				
			ElsIf Not GroupMarkedForDeletion Then
				If AddToGroup Then
					Template = NStr("vi = 'Đưa người sử dụng (%1) vào nhóm ""%2""?';
									|ru = 'Включить пользователей (%1) в группу ""%2""?';
									|en = 'Do you want to add %1 users to group ""%2""?'; fa = 'Do you want to add %1 users to group ""%2""?';
									|it = 'Includere gli utenti (%1) nel gruppo ""%2""?';
									|pl = 'Dodać użytkownika (%1) do grupy ""%2""?';
									|tr = '""%2"" grubuna users(%1) dahil edilsin mi?'");
				ElsIf Move Then
					Template = NStr("vi = 'Chuyển người sử dụng (%1) vào nhóm ""%2""?';
									|ru = 'Переместить пользователей (%1) в группу ""%2""?';
									|en = 'Do you want to move %1 users to group ""%2""?'; fa = 'Do you want to move %1 users to group ""%2""?';
									|it = 'Spostare gli utenti (%1) nel gruppo ""%2""?';
									|pl = 'Przenieść użytkowników (%1) do grupy ""%2""?';
									|tr = 'Kullanıcılar(%1) ""%2"" grubuna taşınsın mı?'");
				Else
					Template = NStr("vi = 'Sao chép người sử dụng (%1) vào nhóm ""%2""?';
									|ru = 'Скопировать пользователей (%1) в группу ""%2""?';
									|en = 'Do you want to copy %1 users to group ""%2""?'; fa = 'Do you want to copy %1 users to group ""%2""?';
									|it = 'Copiare gli utenti (%1) nel gruppo ""%2""?';
									|pl = 'Kopiować użytkowników (%1) do grupy ""%2""?';
									|tr = 'Kullanıcılar (%1) ""%2"" grubuna kopyalansın mı?'");
				EndIf;
				
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					Template,
					UsersCount,
					String(String));
			Else
				If AddToGroup Then
					Template = NStr("vi = 'Nhóm ""%1"" đã đánh dấu để xóa. Chuyển người dùng (%2) vào nhóm này?';
									|ru = 'Группа ""%1"" помечена на удаление. Включить пользователей (%2) в эту группу?';
									|en = 'Group ""%1"" is marked for deletion. Do you want to add %2 users to the group?'; fa = 'Group ""%1"" is marked for deletion. Do you want to add %2 users to the group?';
									|it = 'Gruppo ""%1"" è contrassegnato per l''eliminazione. Includere gli utenti (%2) in questo gruppo?';
									|pl = 'Grupa ""%1"" jest zaznaczona do usunięcia. Dodać użytkowników ""%2"" do tej grupy?';
									|tr = '""%1"" grubu silinmek üzere işaretlendi. Kullanıcılar (%2) bu gruba dahil edilsin mi?'");
				ElsIf Move Then
					Template = NStr("vi = 'Nhóm ""%1"" đã đánh dấu để xóa. Chuyển người dùng (%2) vào nhóm này?';
									|ru = 'Группа ""%1"" помечена на удаление. Переместить пользователей (%2) в эту группу?';
									|en = 'Group ""%1"" is marked for deletion. Do you want to move %2 users to the group?'; fa = 'Group ""%1"" is marked for deletion. Do you want to move %2 users to the group?';
									|it = 'Gruppo ""%1"" è contrassegnato per l''eliminazione. Spostare gli utenti (%2) in questo gruppo?';
									|pl = 'Grupa ""%1"" jest zaznaczona do usunięcia. Przenieść użytkowników ""%2"" do tej grupy?';
									|tr = '""%1"" grubu silinmek üzere işaretlendi. Kullanıcılar(%2) bu gruba taşınsın mı?'");
				Else
					Template = NStr("vi = 'Nhóm ""%1"" đã bị đặt dấu xóa. Sao chép người sử dụng (%2) vào nhóm này?';
									|ru = 'Группа ""%1"" помечена на удаление. Скопировать пользователей (%2) в эту группу?';
									|en = 'Group ""%1"" is marked for deletion. Do you want to copy %2 users to the group?'; fa = 'Group ""%1"" is marked for deletion. Do you want to copy %2 users to the group?';
									|it = 'Gruppo ""%1"" è contrassegnato per l''eliminazione. Copiare gli utenti (%2) in questo gruppo?';
									|pl = 'Grupa ""%1"" jest zaznaczona do usunięcia. Kopiować użytkowników (%2) do tej grupy?';
									|tr = '""%1"" grubu silinmek üzere işaretlendi. Kullanıcılar (%2) bu gruba kopyalansın mı?'");
				EndIf;
				
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					Template,
					String(String),
					UsersCount);
			EndIf;
		EndIf;
		
		AdditionalParameters = New Structure("DragParameters, String, Move",
			DragParameters.Value, String, Move);
		Notification = New CallbackDescription("ExternalUserGroupsDragQuestionProcessing", ThisObject, AdditionalParameters);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes);
		Return;
		
	EndIf;
	
	ExternalUsersGroupsDragCompletion(UserMessage);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExternalUsers

&AtClient
Procedure ExternalUsersListOnChange(Item)
	
	ListOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure ExternalUsersListOnActivateRow(Item)
	
	If StandardSubsystemsClient.IsDynamicListItem(Items.ExternalUsersList) Then
		CanChangePassword = Items.ExternalUsersList.CurrentData.CanChangePassword;
	Else
		CanChangePassword = False;
	EndIf;
	
	Items.FormSetPassword.Enabled = CanChangePassword;
	Items.ExternalUsersListContextMenuSetPassword.Enabled = CanChangePassword;
	
	// StandardSubsystems.AttachableCommands
	If Not StoredParameters.AdvancedPick Then
		If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
			ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
			ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
		EndIf;
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ExternalUsersListValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not StoredParameters.AdvancedPick Then
		NotifyChoice(Value);
	Else
		GetPicturesAndFillSelectedItemsList(Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalUsersListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	FormParameters = New Structure(
		"NewExternalUserGroup", Items.ExternalUsersGroups.CurrentRow);
	
	If ValueIsFilled(StoredParameters.FilterAuthorizationObject) Then
		
		FormParameters.Insert(
			"NewExternalUserAuthorizationObject",
			StoredParameters.FilterAuthorizationObject);
	EndIf;
	
	If Copy And Item.CurrentData <> Undefined Then
		FormParameters.Insert("CopyingValue", Item.CurrentRow);
	EndIf;
	
	OpenForm(
		"Catalog.ExternalUsers.ObjectForm",
		FormParameters,
		Items.ExternalUsersList);
	
EndProcedure

&AtClient
Procedure ExternalUsersListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	If Not ValueIsFilled(Item.CurrentRow) Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Key", Item.CurrentRow);
	OpenForm("Catalog.ExternalUsers.ObjectForm", FormParameters, Item);
	
EndProcedure

&AtServerNoContext
Procedure ExternalUsersListOnGetDataAtServer(TagName, Settings, Rows)
	
	UsersInternal.DynamicListOnGetDataAtServer(TagName, Settings, Rows);
	
EndProcedure

&AtClient
Procedure ExternalUsersListDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedUsersAndGroupsList

&AtClient
Procedure SelectedUsersAndGroupsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	DeleteFromSelectedItems();
	Modified = True;
	
EndProcedure

&AtClient
Procedure SelectedUsersAndGroupsListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateExternalUsersGroup(Command)
	
	CurrentData = Items.ExternalUsersGroups.CurrentData;
	If Not StandardSubsystemsClient.IsDynamicListItem(CurrentData) Then
		Return;
	EndIf;
	
	If CurrentData.AllAuthorizationObjects Then
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thêm nhóm con vào nhóm ""%1"" 
			           | vì các thành viên của nhóm bao gồm tất cả người sử dụng của các dạng đã chọn.';
			           |ru = 'Невозможно добавить подгруппу к группе ""%1"", 
			           |так как в число ее участников входят все пользователи выбранных видов.';
			           |en = 'Cannot add a subgroup to group ""%1"" as 
			           | it includes all users of the specified types.'; fa = 'Cannot add a subgroup to group ""%1"" as 
			           | it includes all users of the specified types.';
			           |it = 'Non è possibile aggiungere un sottogruppo al gruppo "" %1"" 
			           | perché l''elenco dei partecipanti comprende tutti gli utenti dei tipi selezionati.';
			           |pl = 'Do grupy ""%1"" nie można dodać podgrupy, 
			           |ponieważ należą do niej wszyscy użytkownicy wybranych rodzajów.';
			           |tr = '""%1"" grubuna seçilmiş türden tüm kullanıcılar dahil edildiği için, 
			           |alt grup eklenemez.'"),
			CurrentData.Description));
		Return;
	EndIf;
		
	Items.ExternalUsersGroups.AddRow();
	
EndProcedure

&AtClient
Procedure AssignGroups(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Users", Items.ExternalUsersList.SelectedRows);
	FormParameters.Insert("ExternalUsers", True);
	
	OpenForm("CommonForm.UserGroups", FormParameters);
	
EndProcedure

&AtClient
Procedure SetPassword(Command)
	
	CurrentData = Items.ExternalUsersList.CurrentData;
	
	If StandardSubsystemsClient.IsDynamicListItem(CurrentData) Then
		UsersInternalClient.OpenChangePasswordForm(CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure EndAndClose(Command)
	
	If StoredParameters.AdvancedPick Then
		UsersArray = SelectionResult();
		NotifyChoice(UsersArray);
		Modified = False;
		Close(UsersArray);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectUserCommand(Command)
	
	UsersArray = Items.ExternalUsersList.SelectedRows;
	GetPicturesAndFillSelectedItemsList(UsersArray);
	
EndProcedure

&AtClient
Procedure CancelUserOrGroupSelection(Command)
	
		DeleteFromSelectedItems();
	
EndProcedure

&AtClient
Procedure ClearSelectedUsersAndGroupsList(Command)
	
	DeleteFromSelectedItems(True);
	
EndProcedure

&AtClient
Procedure SelectGroup(Command)
	
	GroupsArray1 = Items.ExternalUsersGroups.SelectedRows;
	GetPicturesAndFillSelectedItemsList(GroupsArray1);
	
EndProcedure

&AtClient
Procedure ExternalUsersInfo(Command)
	
	OpenForm(
		"Report.UsersInfo.ObjectForm",
		New Structure("VariantKey", "ExternalUsersInfo"),
		ThisObject,
		"ExternalUsersInfo");
	
EndProcedure

#Region BatchObjectModificationSupport

&AtClient
Procedure ChangeSelectedItems(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.BatchEditObjects") Then
		ModuleBatchObjectsModificationClient = CommonClient.CommonModule("BatchEditObjectsClient");
		ModuleBatchObjectsModificationClient.ChangeSelectedItems(Items.ExternalUsersList, ExternalUsersList);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Returns:
//   Structure:
//   * SelectExternalUsersGroups - Boolean
//   * FilterAuthorizationObject - DefinedType.ExternalUser
//   * AdvancedPick - Boolean
//   * PickFormHeader - String
//   * AllUsersGroup - CatalogRef.ExternalUsersGroups
//   * UseGroups - Boolean
//
&AtServer
Function NewStoredParameters1()
	
	StoredParameters = New Structure;
	StoredParameters.Insert("SelectExternalUsersGroups", Parameters.SelectExternalUsersGroups);
	StoredParameters.Insert("FilterAuthorizationObject", 
		?(Parameters.Filter.Property("AuthorizationObject"), Parameters.Filter.AuthorizationObject, Undefined));
	StoredParameters.Insert("AdvancedPick", False);
	StoredParameters.Insert("PickFormHeader", "");
	StoredParameters.Insert("AllUsersGroup", ExternalUsers.AllExternalUsersGroup());
	StoredParameters.Insert("UseGroups", GetFunctionalOption("UseUserGroups"));
	Return StoredParameters;
	
EndFunction

&AtServer
Procedure FillDynamicListParameters(BlankRefsArray = Undefined)
	
	Used = BlankRefsArray <> Undefined And BlankRefsArray.Count() <> 0;
	
	CommonClientServer.SetDynamicListFilterItem(
		ExternalUsersGroups, "Ref.Purpose.UsersType",
		BlankRefsArray, DataCompositionComparisonType.InList, , Used);
	
	TypesArray = New Array;
	If Used Then
		For Each Item In BlankRefsArray Do
			TypesArray.Add(TypeOf(Item));
		EndDo;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		ExternalUsersList, "AuthorizationObjectType",
		TypesArray, DataCompositionComparisonType.InList, , Used);
	
EndProcedure

&AtServer
Procedure ApplyConditionalAppearanceAndHideInvalidExternalUsers()
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("ExternalUsersList.Invalid");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("ExternalUsersList");
	AppearanceFieldItem.Use = True;
	
	CommonClientServer.SetDynamicListFilterItem(
		ExternalUsersList, "Invalid", False, , , True);
	
EndProcedure

&AtServer
Procedure SetExternalUserListParametersForSetPasswordCommand()
	
	UpdateDataCompositionParameterValue(ExternalUsersList, "CurrentIBUserID",
		InfoBaseUsers.CurrentUser().UUID);
	
	UpdateDataCompositionParameterValue(ExternalUsersList, "BlankUUID",
		CommonClientServer.BlankUUID());
	
	UpdateDataCompositionParameterValue(ExternalUsersList, "CanChangeOwnPasswordOnly",
		Not Users.IsFullUser());
	
EndProcedure

&AtServer
Procedure SetAllExternalUsersGroupOrder(List)
	
	Var Order;
	
	// Order.
	Order = List.SettingsComposer.Settings.Order;
	Order.UserSettingID = "DefaultOrder";
	
	Order.Items.Clear();
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Predefined");
	OrderItem.OrderType = DataCompositionSortDirection.Desc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Description");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
EndProcedure

&AtClient
Procedure CurrentFormItemModificationCheck()
	
	If CurrentItem <> LastItem Then
		CurrentFormItemOnChange();
		LastItem = CurrentItem;
	EndIf;
	
#If WebClient Then
	AttachIdleHandler("CurrentFormItemModificationCheck", 0.7, True);
#Else
	AttachIdleHandler("CurrentFormItemModificationCheck", 0.1, True);
#EndIf
	
EndProcedure

&AtClient
Procedure CurrentFormItemOnChange()
	
	If CurrentItem = Items.ExternalUsersGroups Then
		Items.Comments.CurrentPage = Items.CommentOfGroup;
		
	ElsIf CurrentItem = Items.ExternalUsersList Then
		Items.Comments.CurrentPage = Items.UserComment;
		
	EndIf
	
EndProcedure

&AtServer
Procedure DeleteFromSelectedItems(DeleteAll1 = False)
	
	If DeleteAll1 Then
		SelectedUsersAndGroups.Clear();
		UpdateSelectedUsersAndGroupsListTitle();
		Return;
	EndIf;
	
	ListItemsArray = Items.SelectedUsersAndGroupsList.SelectedRows;
	For Each ListItem In ListItemsArray Do
		SelectedUsersAndGroups.Delete(SelectedUsersAndGroups.FindByID(ListItem));
	EndDo;
	
	UpdateSelectedUsersAndGroupsListTitle();
	
EndProcedure

&AtClient
Procedure GetPicturesAndFillSelectedItemsList(SelectedItemsArray)
	
	SelectedItemsAndPictures = New Array;
	For Each SelectedElement In SelectedItemsArray Do
		
		If TypeOf(SelectedElement) = Type("CatalogRef.ExternalUsers") Then
			PictureNumber = Items.ExternalUsersList.RowData(SelectedElement).PictureNumber;
			
		ElsIf TypeOf(SelectedElement) = Type("CatalogRef.ExternalUsersGroups") Then
			PictureNumber = Items.ExternalUsersGroups.RowData(SelectedElement).PictureNumber;
		Else
			Continue;
		EndIf;
		
		SelectedItemsAndPictures.Add(
			New Structure("SelectedElement, PictureNumber", SelectedElement, PictureNumber));
	EndDo;
	
	FillSelectedUsersAndGroupsList(SelectedItemsAndPictures);
	
EndProcedure

&AtServer
Function SelectionResult()
	
	SelectedUsersValueTable = SelectedUsersAndGroups.Unload( , "User");
	UsersArray = SelectedUsersValueTable.UnloadColumn("User");
	Return UsersArray;
	
EndFunction

&AtServer
Procedure ChangeExtendedPickFormParameters()
	
	// Loading the list of selected users.
	PickingParameters = UsersInternal.NewParametersOfExtendedPickForm();
	If ValueIsFilled(Parameters.ExtendedPickFormParameters) Then
		GivenParameters = GetFromTempStorage(Parameters.ExtendedPickFormParameters);
		If TypeOf(GivenParameters) = Type("Structure") Then
			FillPropertyValues(PickingParameters, GivenParameters);
		EndIf;
	Else
		FillPropertyValues(PickingParameters, Parameters);
	EndIf;
	If TypeOf(PickingParameters.SelectedUsers) = Type("Array") Then
		For Each SelectedUser In PickingParameters.SelectedUsers Do
			SelectedUsersAndGroups.Add().User = SelectedUser;
		EndDo;
		Users.FillUserPictureNumbers(SelectedUsersAndGroups,
			"User", "PictureNumber");
	EndIf;
	StoredParameters.PickFormHeader = PickingParameters.PickFormHeader;
	
	// Setting parameters of the extended pick form.
	Items.EndAndClose.Visible                      = True;
	Items.SelectUserGroup.Visible              = True;
	// Making the list of selected users visible.
	Items.SelectedUsersAndGroups.Visible           = True;
	UseUserGroups = GetFunctionalOption("UseUserGroups");
	Items.SelectGroupGroup.Visible                    = UseUserGroups;
	
	If Common.IsMobileClient() Then
		Items.GroupsAndUsers.Group                 = ChildFormItemsGroup.Vertical;
		Items.GroupsAndUsers.DisplayImportance      = DisplayImportance.VeryHigh;
		Items.ContentGroup.Group                              = ChildFormItemsGroup.AlwaysHorizontal;
		Items.SelectGroupGroup.Visible                   = False;
		Items.SelectUserGroup.Visible             = False;
		Items.Move(Items.SelectedUsersAndGroups, Items.ContentGroup, Items.SelectedUsersAndGroups);
	ElsIf UseUserGroups Then
		Items.GroupsAndUsers.Group                 = ChildFormItemsGroup.Vertical;
		Items.ExternalUsersList.Height                = 5;
		Items.ExternalUsersGroups.Height               = 3;
		Height                                        = 17;
		// Making the titles of UsersList and UserGroups lists visible.
		Items.ExternalUsersGroups.TitleLocation   = FormItemTitleLocation.Top;
		Items.ExternalUsersList.TitleLocation    = FormItemTitleLocation.Top;
		Items.ExternalUsersList.Title             = NStr("vi = 'Người sử dụng trong nhóm';
														|ru = 'Пользователи в группе';
														|en = 'Users in group'; fa = 'Users in group';
														|it = 'Utenti nel gruppo';
														|pl = 'Użytkownicy w grupie';
														|tr = 'Gruptaki kullanıcılar'");
		Items.SelectGroup.Visible                         = StoredParameters.SelectExternalUsersGroups;
	Else
		Items.CancelUserSelection.Visible             = True;
		Items.ClearSelectedItemsList.Visible               = True;
	EndIf;
	
	// Adding the number of selected users to the title of the list of selected users and groups.
	UpdateSelectedUsersAndGroupsListTitle();
	
EndProcedure

&AtServer
Procedure UpdateSelectedUsersAndGroupsListTitle()
	
	If StoredParameters.UseGroups Then
		SelectedUsersAndGroupsTitle = NStr("vi = 'Người sử dụng và nhóm đã chọn (%1)';
											|ru = 'Выбранные пользователи и группы (%1)';
											|en = 'Selected users and groups (%1)'; fa = 'Selected users and groups (%1)';
											|it = 'Utenti e gruppi selezionati (%1)';
											|pl = 'Wybrani użytkownicy i grupy (%1)';
											|tr = 'Seçilmiş kullanıcılar ve gruplar (%1)'");
	Else
		SelectedUsersAndGroupsTitle = NStr("vi = 'Người sử dụng đã chọn (%1)';
											|ru = 'Выбранные пользователи (%1)';
											|en = 'Selected users (%1)'; fa = 'Selected users (%1)';
											|it = 'Utenti selezionati (%1)';
											|pl = 'Wybrani użytkownicy (%1)';
											|tr = 'Seçilmiş kullanıcılar (%1)'");
	EndIf;
	
	UsersCount = SelectedUsersAndGroups.Count();
	If UsersCount <> 0 Then
		Items.SelectedUsersAndGroupsList.Title = StringFunctionsClientServer.SubstituteParametersToString(
			SelectedUsersAndGroupsTitle, UsersCount);
	Else
		
		If StoredParameters.UseGroups Then
			Items.SelectedUsersAndGroupsList.Title = NStr("vi = 'Người sử dụng và nhóm đã chọn';
															|ru = 'Выбранные пользователи и группы';
															|en = 'Selected users and groups'; fa = 'کاربران و گروه‌های انتخاب‌شده';
															|it = 'Utenti e gruppi selezionati';
															|pl = 'Wybrani użytkownicy i grupy';
															|tr = 'Seçilmiş kullanıcılar ve gruplar'");
		Else
			Items.SelectedUsersAndGroupsList.Title = NStr("vi = 'Người sử dụng đã chọn';
															|ru = 'Выбранные пользователи';
															|en = 'Selected users'; fa = 'کاربران انتخاب‌شده';
															|it = 'Utenti selezionati';
															|pl = 'Wybrani użytkownicy';
															|tr = 'Seçilmiş kullanıcılar'");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillSelectedUsersAndGroupsList(SelectedItemsAndPictures)
	
	UsersInternal.SelectGroupUsers(
		SelectedItemsAndPictures, StoredParameters, Items.ExternalUsersList);
	
	For Each ArrayRow In SelectedItemsAndPictures Do
		
		SelectedUserOrGroup = ArrayRow.SelectedElement;
		PictureNumber = ArrayRow.PictureNumber;
		
		FilterParameters = New Structure("User", SelectedUserOrGroup);
		Found3 = SelectedUsersAndGroups.FindRows(FilterParameters);
		If Found3.Count() = 0 Then
			
			SelectedUsersRow = SelectedUsersAndGroups.Add();
			SelectedUsersRow.User = SelectedUserOrGroup;
			SelectedUsersRow.PictureNumber = PictureNumber;
			Modified = True;
			
		EndIf;
		
	EndDo;
	
	SelectedUsersAndGroups.Sort("User Asc");
	UpdateSelectedUsersAndGroupsListTitle();
	
EndProcedure

&AtClient
Procedure UserGroupsUsageOnChange()
	
	ConfigureUserGroupsUsageForm(True);
	
EndProcedure

&AtServer
Procedure ConfigureUserGroupsUsageForm(GroupUsageChanged = False, 
		SetCurrentRow = False)
	
	AllExternalUsersGroup = ExternalUsers.AllExternalUsersGroup();
	
	If GroupUsageChanged Then
		StoredParameters.UseGroups = GetFunctionalOption("UseUserGroups");
	EndIf;
	
	If SetCurrentRow Then
		If TypeOf(Parameters.CurrentRow) = Type("CatalogRef.ExternalUsersGroups") 
			And StoredParameters.UseGroups Then

			Items.ExternalUsersGroups.CurrentRow = Parameters.CurrentRow;
		Else
			CurrentItem = Items.ExternalUsersList;
			Items.ExternalUsersGroups.CurrentRow = AllExternalUsersGroup;
		EndIf;
	ElsIf Not StoredParameters.UseGroups Then
		If Items.ExternalUsersGroups.CurrentRow <> AllExternalUsersGroup Then
			Items.ExternalUsersGroups.CurrentRow = AllExternalUsersGroup;
		EndIf;
	EndIf;
	
	Items.SelectHierarchy.Visible = StoredParameters.UseGroups;
	Items.AssignGroups.Visible = ?(StoredParameters.AdvancedPick, False, StoredParameters.UseGroups);
	
	Items.CreateExternalUsersGroup.Visible =
		AccessRight("InteractiveInsert", Metadata.Catalogs.ExternalUsersGroups)
		And StoredParameters.UseGroups;
	
	SelectExternalUsersGroups = StoredParameters.SelectExternalUsersGroups
		And StoredParameters.UseGroups
	 	And Parameters.ChoiceMode;
	
	If Parameters.ChoiceMode Then
		
		CommonClientServer.SetFormItemProperty(Items,
			"SelectExternalUsersGroup", "Visible", ?(StoredParameters.AdvancedPick,
				False, SelectExternalUsersGroups));
		
		CommonClientServer.SetFormItemProperty(Items,
			"SelectExternalUser", "DefaultButton", ?(StoredParameters.AdvancedPick,
				False, Not SelectExternalUsersGroups));
		
		CommonClientServer.SetFormItemProperty(Items,
			"SelectExternalUser", "Visible", Not StoredParameters.AdvancedPick);
		
		AutoTitle = False;
		
		If Parameters.CloseOnChoice = False Then
			// Pick mode.
			If SelectExternalUsersGroups Then
				Title = ?(StoredParameters.AdvancedPick, StoredParameters.PickFormHeader,
					NStr("vi = 'Chọn người sử dụng ngoài và nhóm';
						|ru = 'Подбор внешних пользователей и групп';
						|en = 'Pick external users and groups'; fa = 'Pick external users and groups';
						|it = 'Selezione di utenti esterni e gruppi';
						|pl = 'Wybór użytkowników zewnętrznych i grup';
						|tr = 'Harici kullanıcıları ve grupları seçin'"));
				CommonClientServer.SetFormItemProperty(Items,
					"SelectExternalUser", "Title", NStr("vi = 'Chọn người sử dụng ngoài';
														|ru = 'Выбрать внешних пользователей';
														|en = 'Select external users'; fa = 'Select external users';
														|it = 'Selezionare utenti esterni';
														|pl = 'Wybierz użytkowników zewnętrznych';
														|tr = 'Harici kullanıcıları seçin'"));
				CommonClientServer.SetFormItemProperty(Items,
					"SelectExternalUsersGroup", "Title", NStr("vi = 'Chọn nhóm';
																|ru = 'Выбрать группы';
																|en = 'Select groups'; fa = 'انتخاب گروه‌ها';
																|it = 'Selezionare i gruppi';
																|pl = 'Wybierz grupy';
																|tr = 'Grupları seçin'"));
			Else
				Title = ?(StoredParameters.AdvancedPick, StoredParameters.PickFormHeader,
					NStr("vi = 'Chọn người sử dụng ngoài';
						|ru = 'Подбор внешних пользователей';
						|en = 'Pick external users'; fa = 'Pick external users';
						|it = 'Selezione di utenti esterni';
						|pl = 'Wybór użytkowników zewnętrznych';
						|tr = 'Harici kullanıcıların seçimi'"));
			EndIf;
		Else
			// Selection mode.
			If SelectExternalUsersGroups Then
				Title = NStr("vi = 'Chọn người sử dụng ngoài hoặc nhóm';
							|ru = 'Выбор внешнего пользователя или группы';
							|en = 'Select external user or a group'; fa = 'Select external user or a group';
							|it = 'Selezione di un utente esterno o di un gruppo';
							|pl = 'Wybór użytkownika zewnętrznego lub grupy';
							|tr = 'Harici kullanıcı veya grup seçin'");
				
				CommonClientServer.SetFormItemProperty(Items,
					"SelectExternalUser", "Title", NStr("vi = 'Chọn người sử dụng ngoài';
														|ru = 'Выбрать внешнего пользователя';
														|en = 'Select external user'; fa = 'Select external user';
														|it = 'Selezionare un utente esterno';
														|pl = 'Wybierz użytkownika zewnętrznego';
														|tr = 'Harici kullanıcıyı seçin'"));
			Else
				Title = NStr("vi = 'Chọn người sử dụng ngoài';
							|ru = 'Выбор внешнего пользователя';
							|en = 'Select external user'; fa = 'Select external user';
							|it = 'Selezione di un utente esterno';
							|pl = 'Wybór użytkownika zewnętrznego';
							|tr = 'Harici kullanıcı seçimi'");
			EndIf;
		EndIf;
	EndIf;
	
	RefreshFormContentOnGroupChange(ThisObject);
	
	// Force-update the visibility after the functional option changed
	// without employing the "RefreshInterface" command.
	Items.ExternalUsersGroups.Visible = False;
	Items.ExternalUsersGroups.Visible = True;
	
EndProcedure

&AtServer
Function MoveUserToNewGroup(UsersArray, NewParentGroup, Move)
	
	If NewParentGroup = Undefined Then
		Return Undefined;
	EndIf;
	
	CurrentParentGroup = Items.ExternalUsersGroups.CurrentRow;
	UserMessage = UsersInternal.MoveUserToNewGroup(
		UsersArray, CurrentParentGroup, NewParentGroup, Move);
	
	Items.ExternalUsersList.Refresh();
	Items.ExternalUsersGroups.Refresh();
	
	Return UserMessage;
	
EndFunction

&AtClient
Procedure ToggleInvalidUsersVisibility(ShowInvalidUsers)
	
	CommonClientServer.SetDynamicListFilterItem(
		ExternalUsersList, "Invalid", False, , ,
		Not ShowInvalidUsers);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshFormContentOnGroupChange(Form)
	
	Items = Form.Items;
	AllExternalUsersGroup = PredefinedValue(
		"Catalog.ExternalUsersGroups.AllExternalUsers");
	
	If Not Form.StoredParameters.UseGroups
		Or Items.ExternalUsersGroups.CurrentRow = AllExternalUsersGroup Then
		
		UpdateDataCompositionParameterValue(Form.ExternalUsersList,
			"AllExternalUsers", True);
		
		UpdateDataCompositionParameterValue(Form.ExternalUsersList,
			"SelectHierarchy", True);
		
		UpdateDataCompositionParameterValue(Form.ExternalUsersList,
			"ExternalUsersGroup", AllExternalUsersGroup);
	Else
		UpdateDataCompositionParameterValue(Form.ExternalUsersList,
			"AllExternalUsers", False);
		
#If Server Then
		If ValueIsFilled(Items.ExternalUsersGroups.CurrentRow) Then
			CurrentData = Common.ObjectAttributesValues(
				Items.ExternalUsersGroups.CurrentRow, "AllAuthorizationObjects");
		Else
			CurrentData = Undefined;
		EndIf;
#Else
		CurrentData = Items.ExternalUsersGroups.CurrentData;
#EndIf
		
		If CurrentData <> Undefined
		   And Not CurrentData.Property("RowGroup")
		   And CurrentData.AllAuthorizationObjects Then
			
			UpdateDataCompositionParameterValue(Form.ExternalUsersList,
				"SelectHierarchy", True);
		Else
			UpdateDataCompositionParameterValue(Form.ExternalUsersList,
				"SelectHierarchy", Form.SelectHierarchy);
		EndIf;
		
		UpdateDataCompositionParameterValue(Form.ExternalUsersList,
			"ExternalUsersGroup", Items.ExternalUsersGroups.CurrentRow);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDataCompositionParameterValue(Val ParametersOwner,
                                                    Val ParameterName,
                                                    Val ParameterValue)
	
	For Each Parameter In ParametersOwner.Parameters.Items Do
		If String(Parameter.Parameter) = ParameterName Then
			
			If Parameter.Use
			   And Parameter.Value = ParameterValue Then
				
				Return;
			EndIf;
			Break;
			
		EndIf;
	EndDo;
	
	ParametersOwner.Parameters.SetParameterValue(ParameterName, ParameterValue);
	
EndProcedure

&AtServerNoContext
Procedure ListOnChangeAtServer()
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.StartAccessUpdate();
	EndIf;
	
EndProcedure

#Region DraggingUsers

// A question handler.
// 
// Parameters:
//  Response - DialogReturnCode
//  AdditionalParameters - Structure:
//    * DragParameters - Array of CatalogRef.ExternalUsers
//    * String - CatalogRef.ExternalUsersGroups
//    * Move - Boolean
//
&AtClient
Procedure ExternalUserGroupsDragQuestionProcessing(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	UserMessage = MoveUserToNewGroup(
		AdditionalParameters.DragParameters, AdditionalParameters.String, AdditionalParameters.Move);
	ExternalUsersGroupsDragCompletion(UserMessage);
	
EndProcedure

&AtClient
Procedure ExternalUsersGroupsDragCompletion(UserMessage)
	
	If UserMessage.Message = Undefined Then
		Return;
	EndIf;
	
	Notify("Write_ExternalUsersGroups");
	
	If UserMessage.HasErrors = False Then
		ShowUserNotification(
			NStr("vi = 'Di chuyển người sử dụng';
				|ru = 'Перемещение пользователей';
				|en = 'Move users'; fa = 'Move users';
				|it = 'Spostamento di utenti';
				|pl = 'Przemieszczenie użytkowników';
				|tr = 'Kullanıcıları taşıyın'"), , UserMessage.Message, PictureLib.DialogInformation);
	Else
		StandardSubsystemsClient.ShowQuestionToUser(Undefined, 
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1
				|Những người sử dụng sau không có trong nhóm đã chọn:
				|%2';
				|ru = '%1
				|Следующие пользователи не были включены в выбранную группу:
				|%2';
				|en = '%1
				|The following users were not included into the selected group:
				|%2'; fa = '%1
				|The following users were not included into the selected group:
				|%2';
				|it = '%1
				|I seguenti utenti non sono stati inclusi nel gruppo selezionato: 
				|%2';
				|pl = '%1
				|Następujący użytkownicy nie zostali włączeni do wybranej grupy:
				|%2';
				|tr = '%1
				|Aşağıdaki kullanıcılar seçilmiş gruba dahil edilmedi: 
				|%2'"), UserMessage.Message, UserMessage.Users), QuestionDialogMode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAssignmentChoice(TypesArray, AdditionalParameters) Export
	
	FillDynamicListParameters(TypesArray);
	
EndProcedure

&AtClient
Procedure UsersKindClearing(Item, StandardProcessing)
	
	FillDynamicListParameters();
	
EndProcedure

// StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
	ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.ExternalUsersList);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
	ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.ExternalUsersList);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
	ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ExternalUsersList);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion