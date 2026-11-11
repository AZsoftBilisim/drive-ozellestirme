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
	
	If Not ValueIsFilled(Parameters.User) Then
		Cancel = True;
		Return;
	EndIf;
	
	If TypeOf(Parameters.User) = Type("CatalogRef.Users")
	   And Common.ObjectAttributeValue(Parameters.User, "IsInternal") = True Then
		
		IsInternalUser = True;
		Items.UtilityUserRights.Visible = True;
		CommandBar.Visible = False;
		Items.AccessGroupsAndRoles.Visible = False;
		Return;
	EndIf;
	
	IBUserFull = Users.IsFullUser();
	OwnAccess = Parameters.User = Users.AuthorizedUser();
	
	AdministratorsAccessGroup = AccessManagement.AdministratorsAccessGroup();

	IBUserEmployeeResponsible =
		Not IBUserFull
		And AccessRight("Edit", Metadata.Catalogs.AccessGroups);
	
	Items.AccessGroupsContextMenuChangeGroup.Visible =
		IBUserFull
		Or IBUserEmployeeResponsible;
	
	Items.FormAccessRightsReport.Visible =
		IBUserFull
		Or Parameters.User = Users.AuthorizedUser();
	
	If TypeOf(Parameters.User) = Type("CatalogRef.UserGroups")
	 Or TypeOf(Parameters.User) = Type("CatalogRef.ExternalUsersGroups") Then
		
		Items.FormReportUserRights.Visible = False;
	Else
		Items.FormReportUserRights.Visible =
			IBUserFull
			Or Parameters.User = Users.AuthorizedUser();
	EndIf;
	
	// Configuring commands for a limited user.
	Items.FormAddToGroup.Visible   = IBUserEmployeeResponsible;
	Items.FormRemoveFromGroup.Visible = IBUserEmployeeResponsible;
	Items.FormChangeGroup.Visible    = IBUserEmployeeResponsible;
	
	// Configuring commands for a full access user.
	Items.AccessGroupsAddToGroup.Visible   = IBUserFull;
	Items.AccessGroupsRemoveFromGroup.Visible = IBUserFull;
	Items.AccessGroupsChangeGroup.Visible    = IBUserFull;
	
	// Setting the page tab display.
	Items.AccessGroupsAndRoles.PagesRepresentation =
		?(IBUserFull,
		  FormPagesRepresentation.TabsOnTop,
		  FormPagesRepresentation.None);
	
	// Configuring the command bar view for a full access user.
	Items.AccessGroups.CommandBarLocation =
		?(IBUserFull,
		  FormItemCommandBarLabelLocation.Top,
		  FormItemCommandBarLabelLocation.None);
	
	// Configuring roles view for a full access user.
	Items.RolesRepresentation.Visible = IBUserFull;
	
	If IBUserFull
	 Or IBUserEmployeeResponsible
	 Or OwnAccess Then
		
		OutputAccessGroups();
	Else
		// Regular users cannot view other user access settings.
		Items.AccessGroupsAddToGroup.Visible   = False;
		Items.AccessGroupsRemoveFromGroup.Visible = False;
		
		Items.AccessGroupsAndRoles.Visible         = False;
		Items.InsufficientViewRights.Visible = True;
	EndIf;
	
	ProcessRolesInterface("SetUpRoleInterfaceOnFormCreate");
	ProcessRolesInterface("SetRolesReadOnly", True);
	
	If Common.IsStandaloneWorkplace() Then
		Items.FormAddToGroup.Enabled   = False;
		Items.FormRemoveFromGroup.Enabled = False;
		Items.AccessGroupsAddToGroup.Enabled   = False;
		Items.AccessGroupsRemoveFromGroup.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If IsInternalUser Then
		Return;
	EndIf;
	
	If Upper(EventName) = Upper("Write_AccessGroups")
	 Or Upper(EventName) = Upper("Write_AccessGroupProfiles")
	 Or Upper(EventName) = Upper("Write_UserGroups")
	 Or Upper(EventName) = Upper("Write_ExternalUsersGroups") Then
		
		OutputAccessGroups();
		UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If IsInternalUser Then
		Return;
	EndIf;
	
	ProcessRolesInterface("SetUpRoleInterfaceOnLoadSettings", Settings);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccessGroups

&AtClient
Procedure AccessGroupsOnActivateRow(Item)
	
	CurrentData   = Items.AccessGroups.CurrentData;
	CurrentParent = Items.AccessGroups.CurrentParent;
	
	If CurrentData = Undefined Then
		CurrentAccessGroup = Undefined;
	Else
		CurrentAccessGroup = ?(CurrentParent = Undefined,
			CurrentData.AccessGroup, CurrentParent.AccessGroup);
	EndIf;
	
EndProcedure

&AtClient
Procedure AccessGroupsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If AccessGroups.FindByID(RowSelected) <> Undefined Then
		
		If Items.FormChangeGroup.Visible
		 Or Items.AccessGroupsChangeGroup.Visible Then
			
			ChangeGroup(Items.FormChangeGroup);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddToGroup(Command)
	
	FormParameters = New Structure;
	Selected_ = New Array;
	
	For Each AccessGroupDetails In AccessGroups Do
		Selected_.Add(AccessGroupDetails.AccessGroup);
	EndDo;
	
	FormParameters.Insert("Selected_",         Selected_);
	FormParameters.Insert("GroupsUser", Parameters.User);
	
	OpenForm("Catalog.AccessGroups.Form.SelectGroupsByEmployeeResponsible", FormParameters, ThisObject,
		,,, New CallbackDescription("IncludeExcludeFromGroup", ThisObject, True));
	
EndProcedure

&AtClient
Procedure RemoveFromGroup(Command)
	
	If Not ValueIsFilled(CurrentAccessGroup) Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn nhóm truy cập.';
								|ru = 'Группа доступа не выбрана.';
								|en = 'No access group is selected.'; fa = 'No access group is selected.';
								|it = 'Gruppo di accesso non selezionato.';
								|pl = 'Grupa dostępu nie została wybrana.';
								|tr = 'Erişim grubu seçilmedi.'"));
		Return;
	EndIf;
	
	IncludeExcludeFromGroup(CurrentAccessGroup, False);
	
EndProcedure

&AtClient
Procedure ChangeGroup(Command)
	
	FormParameters = New Structure;
	
	If Not ValueIsFilled(CurrentAccessGroup) Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn nhóm truy cập.';
								|ru = 'Группа доступа не выбрана.';
								|en = 'No access group is selected.'; fa = 'No access group is selected.';
								|it = 'Gruppo di accesso non selezionato.';
								|pl = 'Grupa dostępu nie została wybrana.';
								|tr = 'Erişim grubu seçilmedi.'"));
		Return;
		
	ElsIf IBUserFull
	      Or IBUserEmployeeResponsible
	          And GroupUsersChangeAllowed(CurrentAccessGroup) Then
		
		FormParameters.Insert("Key", CurrentAccessGroup);
		OpenForm("Catalog.AccessGroups.ObjectForm", FormParameters);
	Else
		Raise(NStr("vi = 'Không đủ quyền chỉnh sửa nhóm truy cập.
			|Người chịu trách nhiệm về các thành viên của nhóm truy cập và quản trị viên có thể chỉnh sửa nhóm truy cập.';
			|ru = 'Недостаточно прав для редактирования группы доступа.
			|Редактировать группу доступа могут ответственный за участников группы доступа и администратор.';
			|en = 'Insufficient rights to edit the access group.
			|Only employees responsible for access group members and administrators can edit the access group.'; fa = 'Insufficient rights to edit the access group.
			|Only employees responsible for access group members and administrators can edit the access group.';
			|it = 'Non si dispone delle autorizzazioni sufficienti per modificare il gruppo di accesso.
			|Il gruppo di accesso può essere modificato dalla persona responsabile al gruppo di accesso e dall''amministratore.';
			|pl = 'Niewystarczające uprawnienia do edycji grupy dostępu.
			|Edytować grupę dostępu może osoba odpowiedzialna za członków grupy dostępu i administrator.';
			|tr = 'Erişim grubunu düzenlemek için yetersiz haklar. 
			|Erişim grubundan sorumlu kişi, katılımcıları ve yöneticisi erişim grubunu düzenleyebilir.'"),
			ErrorCategory.AccessViolation);
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	OutputAccessGroups();
	UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	
EndProcedure

&AtClient
Procedure ReportUserRights(Command)
	
	AccessManagementInternalClient.ShowUserRightsOnTables(Parameters.User);
	
EndProcedure

&AtClient
Procedure AccessRightsReport(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", New Structure("User", Parameters.User));
	
	OpenForm("Report.AccessRights.Form", FormParameters);
	
EndProcedure

#Region ForRolesInterfaceOperation

&AtClient
Procedure RolesBySubsystemsGroup(Command)
	
	ProcessRolesInterface("GroupBySubsystems");
	UsersInternalClient.ExpandRoleSubsystems(ThisObject);
	
EndProcedure

&AtClient
Procedure RolesRoleRightsReport(Command)
	
	AccessManagementInternalClient.ShowUserRolesRights(UserRoles(),
		Parameters.User);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtClient
Procedure IncorrectCompositionOfInfobaseInscriptionUserRolesURLProcessing(Item,
			Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	If Var_URL = "ShowDifferencesBetweenConfiguredRolesCompositionAndIBUserRoles" Then
		AccessManagementInternalClient.ShowDifferencesBetweenConfiguredRolesCompositionAndIBUserRoles(
			DifferencesBetweenConfiguredRolesCompositionAndIBUserRoles());
	
	ElsIf Var_URL = "UpdateIBUserRoles" Then
		UpdateIBUserRoles();
	EndIf;
	
EndProcedure

&AtServer
Function DifferencesBetweenConfiguredRolesCompositionAndIBUserRoles()
	
	RolesDifferences = AccessManagementInternal.DifferencesBetweenConfiguredRolesCompositionAndIBUserRoles(
		Parameters.User);
	
	If Not ValueIsFilled(RolesDifferences) Then
		AccessManagementInternal.DisplayUserRolesDifference(ThisObject, Parameters.User);
	EndIf;
	
	Return RolesDifferences;
	
EndFunction

&AtServer
Procedure UpdateIBUserRoles()
	
	AccessManagementInternal.UpdateUserRoles(Parameters.User, ServiceUserPassword);
	AccessManagementInternal.DisplayUserRolesDifference(ThisObject, Parameters.User);
	
EndProcedure

&AtServer
Function UserRoles()
	
	Return AccessManagementInternal.UserRolesForRolesRightsReport(ThisObject);
	
EndFunction

&AtClient
Procedure IncludeExcludeFromGroup(AccessGroup, IncludeInAccessGroup) Export
	
	If TypeOf(AccessGroup) <> Type("CatalogRef.AccessGroups")
	  Or Not ValueIsFilled(AccessGroup) Then
		
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("AccessGroup", AccessGroup);
	AdditionalParameters.Insert("IncludeInAccessGroup", IncludeInAccessGroup);
	
	If CommonClient.DataSeparationEnabled()
	   And AccessGroup = AdministratorsAccessGroup Then
		
		UsersInternalClient.RequestPasswordForAuthenticationInService(
			New CallbackDescription(
				"IncludeExcludeFromGroupCompletion", ThisObject, AdditionalParameters),
			ThisObject,
			ServiceUserPassword);
		Return;
	Else
		IncludeExcludeFromGroupCompletion(Null, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure IncludeExcludeFromGroupCompletion(SaaSUserNewPassword, AdditionalParameters) Export
	
	If SaaSUserNewPassword = Undefined Then
		Return;
	EndIf;
	
	If SaaSUserNewPassword <> Null Then
		ServiceUserPassword = SaaSUserNewPassword;
	EndIf;
	
	ErrorDescription = "";
	
	ChangeGroupContent(
		AdditionalParameters.AccessGroup,
		AdditionalParameters.IncludeInAccessGroup,
		ErrorDescription);
	
	If ValueIsFilled(ErrorDescription) Then
		ShowMessageBox(, ErrorDescription);
	Else
		NotifyChanged(AdditionalParameters.AccessGroup);
		Notify("Write_AccessGroups", New Structure, AdditionalParameters.AccessGroup);
	EndIf;
	
EndProcedure

&AtServer
Procedure OutputAccessGroups()
	
	AccessManagementInternal.DisplayUserRolesDifference(ThisObject, Parameters.User);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	If IBUserFull Or OwnAccess Then
		SetPrivilegedMode(True);
	EndIf;
	
	Query.Text =
	"SELECT ALLOWED
	|	AccessGroups.Ref
	|INTO AllowedAccessGroups
	|FROM
	|	Catalog.AccessGroups AS AccessGroups";
	Query.Execute();
	
	SetPrivilegedMode(True);
	
	Query.Text =
	"SELECT
	|	AllowedAccessGroups.Ref
	|FROM
	|	AllowedAccessGroups AS AllowedAccessGroups
	|WHERE
	|	(NOT AllowedAccessGroups.Ref.DeletionMark)
	|	AND (NOT AllowedAccessGroups.Ref.Profile.DeletionMark)";
	AllowedAccessGroups = Query.Execute().Unload();
	AllowedAccessGroups.Indexes.Add("Ref");
	
	Query.SetParameter("User", Parameters.User);
	Query.Text =
	"SELECT
	|	AccessGroups.Ref AS AccessGroup,
	|	AccessGroups.Description AS Description,
	|	AccessGroups.Profile.Description AS ProfileDescription,
	|	AccessGroups.Comment AS Comment,
	|	AccessGroups.EmployeeResponsible AS EmployeeResponsible
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|WHERE
	|	NOT AccessGroups.DeletionMark
	|	AND NOT AccessGroups.Profile.DeletionMark
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Catalog.AccessGroups.Users AS AccessGroupsUsers
	|			WHERE
	|				AccessGroupsUsers.Ref = AccessGroups.Ref
	|				AND NOT(AccessGroupsUsers.User <> &User
	|						AND NOT AccessGroupsUsers.User IN
	|								(SELECT
	|									UserGroupCompositions.UsersGroup
	|								FROM
	|									InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|								WHERE
	|									UserGroupCompositions.User = &User)))
	|
	|ORDER BY
	|	AccessGroups.Description";
	
	AllAccessGroups = Query.Execute().Unload();
	
	HasProhibitedGroups = False;
	IndexOf = AllAccessGroups.Count()-1;
	
	While IndexOf >= 0 Do
		String = AllAccessGroups[IndexOf];
		
		If AllowedAccessGroups.Find(String.AccessGroup, "Ref") = Undefined Then
			AllAccessGroups.Delete(IndexOf);
			HasProhibitedGroups = True;
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	
	ValueToFormAttribute(AllAccessGroups, "AccessGroups");
	Items.HasHiddenAccessGroupsWarning.Visible = HasProhibitedGroups;
	
	If Not ValueIsFilled(CurrentAccessGroup) Then
		
		If AccessGroups.Count() > 0 Then
			CurrentAccessGroup = AccessGroups[0].AccessGroup;
		EndIf;
	EndIf;
	
	For Each AccessGroupDetails In AccessGroups Do
		
		If AccessGroupDetails.AccessGroup = CurrentAccessGroup Then
			Items.AccessGroups.CurrentRow = AccessGroupDetails.GetID();
			Break;
		EndIf;
	EndDo;
	
	If IBUserFull Then
		FillRoles();
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeGroupContent(Val AccessGroup, Val Add, ErrorDescription = "")
	
	If Not GroupUsersChangeAllowed(AccessGroup) Then
		If Add Then
			ErrorDescription =
				NStr("vi = 'Không đủ quyền đưa người dùng vào nhóm truy cập,
				           |(không chịu trách nhiệm cho các thành viên của nhóm truy cập hoặc không có quyền quản trị viên).';
				           |ru = 'Недостаточно прав для включения пользователя в группу доступа,
				           |(не ответственный за участников группы доступа или нет прав администратора).';
				           |en = 'Insufficient rights to add the user to the access group.
				           |Only employees responsible for access group members and administrators can add users to access groups.'; fa = 'Insufficient rights to add the user to the access group.
				           |Only employees responsible for access group members and administrators can add users to access groups.';
				           |it = 'Diritti insufficienti per includere l''utente nel gruppo di accesso,
				           |(non è responsabile dei partecipanti del gruppo di accesso o non possiede i diritti di amministratore).';
				           |pl = 'Niewystarczające uprawnienia do włączenia użytkownika do grupy dostępu,
				           |(osoba nie odpowiedzialna za uczestników grupy dostępu lub nie ma uprawnień administratora).';
				           |tr = 'Kullanıcının erişim grubunu eklemek için yetersiz yetki,
				           |(erişim grubu üyelerinden sorumlu değil ya da yönetici yetkisi yok).'");
		Else
			ErrorDescription =
				NStr("vi = 'Không đủ quyền để loại trừ người dùng khỏi nhóm truy cập,
				           |(không chịu trách nhiệm cho các thành viên của nhóm truy cập hoặc không có quyền quản trị viên).';
				           |ru = 'Недостаточно прав для исключения пользователя из группы доступа,
				           |(не ответственный за участников группы доступа или нет прав администратора).';
				           |en = 'Insufficient rights to remove the user from the access group.
				           |Only employees responsible for access group members and administrators can remove users from access groups.'; fa = 'Insufficient rights to remove the user from the access group.
				           |Only employees responsible for access group members and administrators can remove users from access groups.';
				           |it = 'Diritti insufficienti per escludere l''utente dal gruppo di accesso,
				           |(non è responsabile dei partecipanti del gruppo di accesso o non possiede i diritti di amministratore).';
				           |pl = 'Niewystarczające uprawnienia do wyłączenia z grupy dostępu,
				           |(osoba nie odpowiedzialna za uczestników grupy dostępu lub nie ma uprawnień administratora).';
				           |tr = 'Kullanıcıyı erişim grubundan çıkarmak için yetersiz yetki,
				           |(erişim grubu üyelerinden sorumlu değil ya da yönetici yetkisi yok).'");
		EndIf;
		Return;
	EndIf;
	
	If Not Add And Not UserIncludedInAccessGroup(CurrentAccessGroup) Then
		ErrorDescription =
			NStr("vi = 'Người dùng không thể bị loại trừ khỏi nhóm truy cập,
			           |vì anh ta gián tiếp được đưa vào nhóm đó.';
			           |ru = 'Невозможно исключить пользователя из группы доступа,
			           |так как он включен в нее косвенно.';
			           |en = 'Cannot remove the user from the access group
			           |as the user is not a direct member of the group.'; fa = 'Cannot remove the user from the access group
			           |as the user is not a direct member of the group.';
			           |it = 'È impossibile escludere un utente da un gruppo di accesso,
			           |poiché egli è indirettamente incluso in esso.';
			           |pl = 'Nie można wykluczyć użytkownika z grupy dostępu,
			           |ponieważ jest on do niej włączony pośrednio.';
			           |tr = 'Kullanıcı, erişim grubuna dolaylı olarak dahil olduğundan, bu erişim grubundan
			           | çıkarılamaz.'");
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled()
	   And AccessGroup = AdministratorsAccessGroup
	   And Common.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS") Then
		
		ModuleUsersInternalSaaS = Common.CommonModule("UsersInternalSaaS");
		ActionsWithSaaSUser = ModuleUsersInternalSaaS.GetActionsWithSaaSUser();
		
		If Not ActionsWithSaaSUser.ChangeAdministrativeAccess Then
			Raise(NStr("vi = 'Không đủ quyền truy cập để thay đổi thành phần của quản trị viên.';
						|ru = 'Недостаточно прав доступа для изменения состава администраторов.';
						|en = 'Insufficient access rights to edit administrators.'; fa = 'Insufficient access rights to edit administrators.';
						|it = 'Non si dispone di diritti sufficienti per modificare la formazione degli amministratori.';
						|pl = 'Niewystarczające uprawnienia do zmiany składu administratorów.';
						|tr = 'Yöneticilerin yapısını değiştirmek için yetersiz erişim hakları.'"),
				ErrorCategory.AccessViolation);
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AccessGroups");
	LockItem.SetValue("Ref", AccessGroup);
	
	BeginTransaction();
	Try
		AccessManagement.SetLockBeforeWriteToFileIB(, True);
		Block.Lock();
		
		AccessGroupObject = AccessGroup.GetObject();
		LockDataForEdit(AccessGroupObject.Ref, AccessGroupObject.DataVersion);
		If Add Then
			If AccessGroupObject.Users.Find(Parameters.User, "User") = Undefined Then
				AccessGroupObject.Users.Add().User = Parameters.User;
			EndIf;
		Else
			TSRow = AccessGroupObject.Users.Find(Parameters.User, "User");
			If TSRow <> Undefined Then
				AccessGroupObject.Users.Delete(TSRow);
			EndIf;
		EndIf;
		
		If AccessGroupObject.Ref = AdministratorsAccessGroup Then
			
			If Common.DataSeparationEnabled() Then
				AccessGroupObject.AdditionalProperties.Insert(
					"ServiceUserPassword", ServiceUserPassword);
			Else
				AccessManagementInternal.CheckAdministratorsAccessGroupForIBUser(
					AccessGroupObject.Users, ErrorDescription);
				
				If ValueIsFilled(ErrorDescription) Then
					RollbackTransaction();
					UnlockDataForEdit(AccessGroupObject.Ref);
					Return;
				EndIf;
			EndIf;
		EndIf;
		
		AccessGroupObject.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		UnlockDataForEdit(AccessGroupObject.Ref);
		ServiceUserPassword = Undefined;
		Raise;
	EndTry;
	
	UnlockDataForEdit(AccessGroupObject.Ref);
	CurrentAccessGroup = AccessGroupObject.Ref;
	AccessManagementInternal.StartAccessUpdate();
	
EndProcedure

&AtServer
Function GroupUsersChangeAllowed(AccessGroup)
	
	If IBUserFull Then
		Return True;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("AccessGroup",              AccessGroup);
	Query.SetParameter("AuthorizedUser", Users.AuthorizedUser());
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		ON (UserGroupCompositions.User = &AuthorizedUser)
	|			AND (UserGroupCompositions.UsersGroup = AccessGroups.EmployeeResponsible)
	|			AND (AccessGroups.Ref = &AccessGroup)";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtServer
Function UserIncludedInAccessGroup(AccessGroup)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("AccessGroup", AccessGroup);
	Query.SetParameter("User", Parameters.User);
	Query.Text =
	"SELECT
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroups_Users
	|WHERE
	|	AccessGroups_Users.Ref = &AccessGroup
	|	AND AccessGroups_Users.User = &User";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtServer
Procedure FillRoles()
	
	AccessManagementInternal.FillInUserRoles(ThisObject);
	ProcessRolesInterface("RefreshRolesTree");
	
EndProcedure

#Region ForRolesInterfaceOperation

&AtServer
Procedure ProcessRolesInterface(Action, MainParameter = Undefined)
	
	AccessManagementInternal.ProcessRolesInterface(ThisObject, Action, MainParameter);
	
EndProcedure

#EndRegion

#EndRegion