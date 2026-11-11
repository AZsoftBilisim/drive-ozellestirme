///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Called when processing the SetFullControl message.
//
// Parameters:
//  DataAreaUser - CatalogRef.Users - the user 
//   to be added to or removed from the Administrators group.
//  AccessAllowed - Boolean - if True, the user is added to the group.
//   If False, the user is removed from the group.
//
Procedure SetUserBelongingToAdministratorGroup(Val DataAreaUser, Val AccessAllowed) Export
	
	AdministratorsGroup = AccessManagement.AdministratorsAccessGroup();
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.AccessGroups");
	LockItem.SetValue("Ref", AdministratorsGroup);
	Block.Lock();
	
	GroupObject = AdministratorsGroup.GetObject();
	
	UserString = GroupObject.Users.Find(DataAreaUser, "User");
	
	If AccessAllowed And UserString = Undefined Then
		
		UserString = GroupObject.Users.Add();
		UserString.User = DataAreaUser;
		GroupObject.Write();
		
	ElsIf Not AccessAllowed And UserString <> Undefined Then
		
		GroupObject.Users.Delete(UserString);
		GroupObject.Write();
	Else
		AccessManagement.UpdateUserRoles(DataAreaUser);
	EndIf;
	
EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.DataFillingForAccessRestriction.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.AccessUpdateOnRecordsLevel.Name);
	
EndProcedure

// See ExportImportDataOverridable.AfterImportData.
Procedure AfterImportData(Container) Export
	
	// In SaaS, the "FillExtensionsOperationParameters" scheduled job updates 1C-supplied profiles in a scheduled job.
	// The job is enabled and started in the procedure "StandardSubsystemsServer.AfterImportData".
	// 
	If Not Common.DataSeparationEnabled() Then
		Catalogs.AccessGroupProfiles.UpdateSuppliedProfiles();
		Catalogs.AccessGroupProfiles.UpdateUnshippedProfiles();
	EndIf;
	
	AccessManagementInternal.ScheduleAccessRestrictionParametersUpdate(
		"AfterUploadingDataToTheDataArea");
	
EndProcedure

// This procedure is called when updating the infobase user roles.
//
// Parameters:
//  IBUserID - UUID.
//  Cancel - Boolean - if this parameter is set to False in the event handler,
//    roles are not updated for this infobase user.
//
Procedure OnUpdateIBUserRoles(Val UserIdentificator, Cancel) Export
	
	If Common.DataSeparationEnabled()
		And UsersInternalSaaS.UserRegisteredAsShared(UserIdentificator) Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

Procedure SetUserRights(User, AccessGroups, UserGroups) Export	
	Query = New Query("SELECT DISTINCT
	|	ExcludeFromGroups.Ref AS Group,
	|	ExcludeFromGroups.Ref.Profile AS Profile,
	|	ExcludeFromGroups.Ref.Parent AS Parent
	|FROM
	|	Catalog.AccessGroups.Users AS ExcludeFromGroups
	|WHERE
	|	ExcludeFromGroups.User = &User
	|	AND ExcludeFromGroups.Ref NOT IN (&AccessGroups)
	|	AND ExcludeFromGroups.Ref.Profile NOT IN (&AccessGroups)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ExcludeFromGroups.Ref AS Group
	|FROM
	|	Catalog.UserGroups.Content AS ExcludeFromGroups
	|WHERE
	|	ExcludeFromGroups.User = &User
	|	AND ExcludeFromGroups.Ref NOT IN (&UserGroups)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AccessGroups.Ref AS Group
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|		LEFT JOIN Catalog.AccessGroups.Users AS GroupsComposition
	|		ON GroupsComposition.Ref = AccessGroups.Ref
	|		AND GroupsComposition.User = &User
	|WHERE
	|	AccessGroups.Ref IN (&AccessGroups)
	|	AND GroupsComposition.User IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	UserGroups.Ref AS Group
	|FROM
	|	Catalog.UserGroups AS UserGroups
	|		LEFT JOIN Catalog.UserGroups.Content AS GroupsComposition
	|		ON (UserGroups.Ref = GroupsComposition.Ref)
	|		AND (GroupsComposition.User = &User)
	|WHERE
	|	UserGroups.Ref IN (&UserGroups)
	|	AND GroupsComposition.User IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AccessGroupProfiles.Ref AS Profile
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|		LEFT JOIN Catalog.AccessGroups AS AccessGroups
	|		ON AccessGroups.Profile = AccessGroupProfiles.Ref
	|		AND AccessGroups.Parent = &PersonalGroupsParent
	|		LEFT JOIN Catalog.AccessGroups.Users AS GroupsComposition
	|		ON GroupsComposition.Ref = AccessGroups.Ref
	|		AND GroupsComposition.User = &User
	|WHERE
	|	AccessGroupProfiles.Ref IN (&AccessGroups)
	|	AND GroupsComposition.User IS NULL");
	
	PersonalGroupsParent = Catalogs.AccessGroups.PersonalAccessGroupsParent(True);
	
	Query.SetParameter("User", User);
	Query.SetParameter("AccessGroups", AccessGroups);
	Query.SetParameter("UserGroups", UserGroups);
	Query.SetParameter("PersonalGroupsParent", PersonalGroupsParent);
	
	Result = Query.ExecuteBatch();
	
	AccessGroupsExclude = Result[0].Unload();
	UsersGroupsExclude = Result[1].Unload();
	AccessGroupsInclude = Result[2].Unload();
	UsersGroupsInclude = Result[3].Unload();
	ProfilesInclude = Result[4].Unload();
	
	Block = PrepareLockByUserGroups(
		AccessGroupsInclude, 
		AccessGroupsExclude, 
		UsersGroupsInclude, 
		UsersGroupsExclude);
	
	AddLockByUserProfiles(
		Block,
		ProfilesInclude, 
		AccessGroupsExclude, 
		PersonalGroupsParent);
	
	BeginTransaction();
	Try
		Block.Lock();
		
		ProcessIncludeToExcludeFromGroups(User, AccessGroupsExclude, AccessGroupsInclude, False);
		
		ProcessIncludeToExcludeFromGroups(
			User, UsersGroupsExclude, UsersGroupsInclude, True);
			
		ProcessInclusionToExclusionFromProfiles(
			User, AccessGroupsExclude, ProfilesInclude, PersonalGroupsParent);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

// Update the access group profile from the template.
// 
// Parameters:
//  TemplateName - String
//  Comment - String
//  IdentifierTemplate - UUID
//  TemplateRoles - Array of String
//  IsDisconnection - Boolean
//
Procedure UpdateAccessGroupsProfileByTemplate(TemplateName, Comment, IdentifierTemplate, TemplateRoles, IsDisconnection) Export
	Block = New DataLock();
	LockItem = Block.Add("Catalog.AccessGroupProfiles");
	LockItem.SetValue("ServiceTemplateID", IdentifierTemplate);
	Block.Lock();
	
	SimplifiedMode = AccessManagementInternal.SimplifiedAccessRightsSetupInterface();
	
	Profile = Catalogs.AccessGroupProfiles.FindByAttribute("ServiceTemplateID", IdentifierTemplate);
	If Profile.IsEmpty() Then
		ObjectOfProfile = Catalogs.AccessGroupProfiles.CreateItem();
	Else
		ObjectOfProfile = Profile.GetObject();
		
		If ObjectOfProfile.DeletionMark <> IsDisconnection Then
			ObjectOfProfile.SetDeletionMark(IsDisconnection);
			If IsDisconnection Then
				Return; 
			EndIf;
		EndIf;
	EndIf;
	
	ObjectOfProfile.Description = TemplateName;
	ObjectOfProfile.Comment = Comment;
	ObjectOfProfile.ServiceTemplateID = IdentifierTemplate;
	ObjectOfProfile.Roles.Clear();
		
	FullRoleNames = New Array;
	For Each NameOfRole In TemplateRoles Do
		MetadataObjectRole = Metadata.Roles.Find(NameOfRole);
		If MetadataObjectRole = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa tìm thấy vai trò %1';
					|ru = 'Не найдена роль %1';
					|en = 'Role not found: %1'; fa = 'Role not found: %1';
					|it = 'Role not found: %1';
					|pl = 'Role not found: %1';
					|tr = '%1 rolü bulunamadı'"), NameOfRole);
			Raise ErrorText;
		EndIf;
		
		FullRoleNames.Add(MetadataObjectRole.FullName());
	EndDo;
	
	RoleIDs = Common.MetadataObjectIDs(FullRoleNames);	
	For Each KeyValue In RoleIDs Do
		ObjectOfProfile.Roles.Add().Role = KeyValue.Value;
	EndDo;
	
	ObjectOfProfile.Purpose.Clear();
	ObjectOfProfile.Purpose.Add().UsersType = Catalogs.Users.EmptyRef();
	
	ObjectOfProfile.Write();
	
	If SimplifiedMode Then
		Return;
	EndIf;
	
	AccessGroups = Catalogs.AccessGroups.ProfileAccessGroups(ObjectOfProfile.Ref);
	If AccessGroups.Count() = 0 Then
		AccessGroup = Catalogs.AccessGroups.CreateItem();
		AccessGroup.Description = ObjectOfProfile.Description;
		AccessGroup.Profile = ObjectOfProfile.Ref;
		AccessGroup.Write();
	ElsIf Not IsDisconnection Then
		GroupsMarks = Common.ObjectsAttributeValue(AccessGroups, "DeletionMark");
		
		For Each KeyValue In GroupsMarks Do
			If KeyValue.Value = False Then
				Continue;
			EndIf;
			
			GroupObject = KeyValue.Key.GetObject();
			GroupObject.SetDeletionMark(False);
		EndDo;
	EndIf;
EndProcedure

Procedure SendUserGroupChangeMessage(GroupObject1, 
														Delete = False, 
														AllServiceUsersIDs = Undefined,
														ShouldSendByInstantMessage = True) Export
	SetPrivilegedMode(True);
	
	If Not IsCTLUserRightsSetupSupported() Then
		Return;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	UsersGroup = New Structure;
	UsersGroup.Insert("Zone", ModuleSaaSOperations.SessionSeparatorValue());
	UsersGroup.Insert("Id", XMLString(GroupObject1.Ref));
	UsersGroup.Insert("Name", GroupObject1.Description);
	UsersGroup.Insert("Comment", GroupObject1.Comment);
	UsersGroup.Insert("DeletionMark", GroupObject1.DeletionMark);
	UsersGroup.Insert("Deleted", Delete);
	UsersGroup.Insert("Parent", XMLString(GroupObject1.Parent));
	UsersGroup.Insert("GroupAllUsers", GroupObject1.Ref = Users.AllUsersGroup());
	UsersGroup.Insert("Users", 
		ServiceUsersIDs(
			GroupObject1.Content.UnloadColumn("User"),
			AllServiceUsersIDs));
	
	SendMessage(
		"AccessRights/UserGroups",
		UsersGroup,
		ModuleSaaSOperations.ServiceManagerEndpoint(),
		ShouldSendByInstantMessage);
EndProcedure


// Send a message with the access group changes.
// 
// Parameters:
//  GroupObject1 - CatalogRef.AccessGroups, CatalogRef.AccessGroupProfiles
//  Delete - Boolean
//  AllServiceUsersIDs - Undefined, Map
//
Procedure SendMessageAboutAccessGroupChanges(GroupObject1, 
													Delete = False, 
													AllServiceUsersIDs = Undefined,
													ShouldSendByInstantMessage = True) Export
	SetPrivilegedMode(True);
	
	If Not IsCTLUserRightsSetupSupported() Then
		Return;
	EndIf;
	
	SimplifiedMode = AccessManagementInternal.SimplifiedAccessRightsSetupInterface();
	ThisProfile = TypeOf(GroupObject1) = Type("CatalogObject.AccessGroupProfiles");
	
	If Not SimplifiedMode And ThisProfile Then
		Return;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	AccessGroup = New Structure;
	AccessGroup.Insert("Zone", ModuleSaaSOperations.SessionSeparatorValue());
	AccessGroup.Insert("Id", XMLString(GroupObject1.Ref));
	AccessGroup.Insert("Name", GroupObject1.Description);
	AccessGroup.Insert("Parent", XMLString(GroupObject1.Parent));
	AccessGroup.Insert("IsFolder", GroupObject1.IsFolder);
	AccessGroup.Insert("DeletionMark", GroupObject1.DeletionMark);
	AccessGroup.Insert("Deleted", Delete);
	
	If Not GroupObject1.IsFolder Then
	
		UsersList = New Array;
		ListOfUserGroups = New Array;
		Profile = Catalogs.AccessGroupProfiles.EmptyRef();
		PersonalGroupsParent = Catalogs.AccessGroups.PersonalAccessGroupsParent(True);
		
		If SimplifiedMode 
			Or (PersonalGroupsParent <> Undefined And PersonalGroupsParent = GroupObject1.Parent) Then
			
			If ThisProfile Then
				Profile = GroupObject1.Ref;
			Else
				Profile = GroupObject1.Profile;
				AccessGroup.Deleted = False;
				AccessGroup.DeletionMark = False;
			EndIf;
			
			AccessGroup.Id = XMLString(Profile);
			AccessGroup.Parent = XMLString(Catalogs.AccessGroups.EmptyRef());
			UsersList = MembersByProfile(Profile, PersonalGroupsParent);			
						
		Else
			Profile = GroupObject1.Profile;
			
			UsersReferences = New Array;
			For Each User In GroupObject1.Users.UnloadColumn("User") Do
				
				If TypeOf(User) = Type("CatalogRef.Users") Then
					UsersReferences.Add(User);
				ElsIf TypeOf(User) = Type("CatalogRef.UserGroups") Then 
					ListOfUserGroups.Add(XMLString(User));
				EndIf;
				
			EndDo;
			
			UsersList = 
				ServiceUsersIDs(UsersReferences, AllServiceUsersIDs);
			
		EndIf;
		
		AccessGroup.Insert("Comment", GroupObject1.Comment);		
		AccessGroup.Insert("SimplifiedMode", SimplifiedMode);
		AccessGroup.Insert("IsAdmin", Profile = AccessManagement.ProfileAdministrator());
		AccessGroup.Insert("LoginToAppAllowed", CanProfileLogInToApp(Profile));
		AccessGroup.Insert("Users", UsersList);
		AccessGroup.Insert("UserGroups", ListOfUserGroups);
		AccessGroup.Insert("ProfileId", XMLString(Profile));
		
	EndIf;
	
	SendMessage(
		"AccessRights/AccessGroups",
		AccessGroup,
		ModuleSaaSOperations.ServiceManagerEndpoint(),
		ShouldSendByInstantMessage);
EndProcedure

Procedure SendAccessGroupsToServiceManager(ShouldSendByInstantMessage = True) Export
	If Not IsCTLUserRightsSetupSupported() Then
		Return;
	EndIf;
	
	// ACC:96-off - JOIN is required to select unique records
	Query = New Query("SELECT
	|	UserGroups.Ref AS Group
	|FROM
	|	Catalog.UserGroups AS UserGroups
	|
	|ORDER BY
	|	Group HIERARCHY
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccessGroups_Users.User AS User,
	|	CAST(AccessGroups_Users.User AS Catalog.Users).ServiceUserID AS
	|		ServiceUserID
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroups_Users
	|WHERE
	|	NOT CAST(AccessGroups_Users.User AS Catalog.Users).ServiceUserID IS NULL
	|
	|UNION
	|
	|SELECT
	|	UserGroupsComposition.User,
	|	CAST(UserGroupsComposition.User AS Catalog.Users).ServiceUserID
	|FROM
	|	Catalog.UserGroups.Content AS UserGroupsComposition
	|WHERE
	|	NOT CAST(UserGroupsComposition.User AS Catalog.Users).ServiceUserID IS NULL");
	// ACC:96-on
	
	Query.Text = Query.Text + Common.QueryBatchSeparator() + QueryTextOfAccessGroupsSelection();
	Query.SetParameter("PersonalAccessGroupsParent", 
		Catalogs.AccessGroups.PersonalAccessGroupsParent(True));
	
	Result = Query.ExecuteBatch();
	
	AllServiceUsersIDs = New Map;
	
	IDsSelection = Result[1].Select();
	While IDsSelection.Next() Do
		AllServiceUsersIDs[IDsSelection.User] = 
			IDsSelection.ServiceUserID; 		
	EndDo;
	
	SimplifiedMode = AccessManagementInternal.SimplifiedAccessRightsSetupInterface();
	
	SelectionUsersGroup = Result[0].Select();
	While SelectionUsersGroup.Next() Do
		GroupObject = SelectionUsersGroup.Group.GetObject();
		//@skip-check query-in-loop
		SendUserGroupChangeMessage(
			GroupObject, , AllServiceUsersIDs, ShouldSendByInstantMessage);
	EndDo;
	
	SelectionAccessGroup = Result[2].Select();
	While SelectionAccessGroup.Next() Do
		GroupObject = SelectionAccessGroup.Group.GetObject();	
		//@skip-check query-in-loop
		SendMessageAboutAccessGroupChanges(
			GroupObject, , AllServiceUsersIDs, ShouldSendByInstantMessage);
	EndDo;
EndProcedure

Procedure OnAddUpdateHandlers(Handlers) Export
	If Not IsCTLUserRightsSetupSupported() Then
		Return;
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.11.1";
	Handler.Procedure = "AccessManagementInternalSaaS.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.Comment = NStr("vi = 'Gửi nhóm truy cập và nhóm người sử dụng vào Bộ quản lý dịch vụ.';
							|ru = 'Отправляет группы доступа и группы пользователей в Менеджер сервиса.';
							|en = 'Sends access groups and user groups to the Service Manager.'; fa = 'Sends access groups and user groups to the Service Manager.';
							|it = 'Sends access groups and user groups to the Service Manager.';
							|pl = 'Sends access groups and user groups to the Service Manager.';
							|tr = 'Erişim gruplarını ve kullanıcı gruplarını Servis Yöneticisi''ne gönderir.'");
	Handler.Id = New UUID("7fce724c-8d26-49ab-805d-dd5c21ca0af5");
	Handler.UpdateDataFillingProcedure = "AccessManagementInternalSaaS.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead = "Catalog.AccessGroups,Catalog.UserGroups";
EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	// Data registration is not required.
	Return;
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export	
	SendAccessGroupsToServiceManagerOnMigrateToNewVersion();	
	Parameters.ProcessingCompleted = True;
EndProcedure

Procedure SendAccessGroupsToServiceManagerOnMigrateToNewVersion() Export
	ObjectKey = "AppAccessGroups";
	SettingsKey = "UpdateHandlerHasBeenExecuted";
	HandlerCompleted  = SystemSettingsStorage.Load(ObjectKey, SettingsKey);
	If HandlerCompleted <> Undefined Then		
		Return;
	EndIf;
				
	BeginTransaction();
	Try
		SendAccessGroupsToServiceManager(False);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

	SystemSettingsStorage.Save(ObjectKey, SettingsKey, True);
EndProcedure

Procedure OnDefineSupportedInterfaceVersions(SupportedVersionsStructure) Export
	
	VersionsArray = New Array;
	VersionsArray.Add("1.0.0.1");
	
	SupportedVersionsStructure.Insert(
		"SettingUpUserRightsInServiceModel",
		VersionsArray);
	
EndProcedure

Function IsCTLUserRightsSetupSupported() Export
	
	If Not AreRequiredCTLSubsystemsExist() Then
		Return False;
	EndIf;
	
	SupportedVersions = Common.InterfacesVersions();
	
	IsInterfaceSupported = IsAPISupported(
		SupportedVersions,
		RemoteAppAdministrationInterfaceName(),
		"1.0.3.16");
	
	If Not IsInterfaceSupported Then
		
		IsInterfaceSupported = IsAPISupported(
			SupportedVersions,
			AccessRightsManagementInterfaceName());
		
	EndIf;
	
	Return IsInterfaceSupported;
	
EndFunction

#EndRegion

#Region Private

Procedure ProcessInclusionToExclusionFromProfiles(User, 
												  AccessGroupsExclude,												   
												  ProfilesInclude,
												  PersonalGroupsParent)

	If Not AccessManagementInternal.SimplifiedAccessRightsSetupInterface() Then
		Return;
	EndIf;
													  
	For Each RowProfile In AccessGroupsExclude Do
		If RowProfile.Parent <> PersonalGroupsParent Then
			Continue;
		EndIf;
		
		AccessManagement.DisableUserProfile(User, RowProfile.Profile);
	EndDo;
	
	For Each CurRow In ProfilesInclude Do
		AccessManagement.EnableProfileForUser(User, CurRow.Profile);
	EndDo;
EndProcedure

Procedure AddLockByUserProfiles(Block, ProfilesInclude, AccessGroupsExclude, PersonalGroupsParent)
	ProfilesForLocking = ProfilesInclude.Copy();
	For Each RowProfile In AccessGroupsExclude Do
		If RowProfile.Parent <> PersonalGroupsParent Then
			Continue;
		EndIf;
		
		ProfilesForLocking.Add().Profile = RowProfile.Profile;
	EndDo;

	LockItem = Block.Add("Catalog.AccessGroupProfiles");
	LockItem.UseFromDataSource("Ref", "Profile");
	LockItem.DataSource = ProfilesForLocking;
EndProcedure

Function MembersByProfile(Profile, PersonalGroupsParent)
	// A profile lock is set earlier, when writing the access group
	
	Result = New Array();
	
	Query = New Query("SELECT DISTINCT
	|	CAST(AccessGroups.User AS Catalog.Users).ServiceUserID AS
	|		ServiceUserID
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroups
	|WHERE
	|	AccessGroups.Ref.Profile = &Profile
	|	AND NOT AccessGroups.Ref.DeletionMark
	|	AND CAST(AccessGroups.User AS Catalog.Users) <> VALUE(Catalog.Users.EmptyRef)
	|	AND VALUETYPE(AccessGroups.User) = TYPE(Catalog.Users)
	|	AND CAST(AccessGroups.User AS
	|		Catalog.Users).ServiceUserID <> &BlankID
	|	AND (AccessGroups.Ref.Parent = &PersonalGroupsParent
	|		OR &IsProfileAdministrator)");
	Query.SetParameter("Profile", Profile);
	Query.SetParameter("PersonalGroupsParent", PersonalGroupsParent);
	Query.SetParameter("IsProfileAdministrator", Profile = AccessManagement.ProfileAdministrator());
	Query.SetParameter("BlankID", 
		New UUID("00000000-0000-0000-0000-000000000000"));
		
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Add(String(Selection.ServiceUserID));
	EndDo;
	
	Return Result;
EndFunction

Function PrepareLockByUserGroups(AccessGroupsInclude, 
												   AccessGroupsExclude, 
												   UsersGroupsInclude, 
												   UsersGroupsExclude)
	
	ByAccessGroups = AccessGroupsInclude.Copy();
	For Each AccessGroupRow In AccessGroupsExclude Do
		ByAccessGroups.Add().Group = AccessGroupRow.Group;
	EndDo;
	
	ByUsersGroups = UsersGroupsInclude.Copy();
	For Each UserGroupRow In UsersGroupsExclude Do
		ByUsersGroups.Add().Group = UserGroupRow.Group;
	EndDo;

	Block = New DataLock;
	LockItem = Block.Add("Catalog.AccessGroups");
	LockItem.UseFromDataSource("Ref", "Group");
	LockItem.DataSource = ByAccessGroups;
		
	LockItem = Block.Add("Catalog.UserGroups");
	LockItem.UseFromDataSource("Ref", "Group");
	LockItem.DataSource = ByUsersGroups;
	
	Return Block;
EndFunction

// ACC:1327-off - An exclusive lock has been set in the upper level
Procedure ProcessIncludeToExcludeFromGroups(User, GroupExclude, GroupInclude, IsUsersGroup)
	TabularSectionName = "Users";
	If IsUsersGroup Then
		TabularSectionName = "Content";
	EndIf;
	PersonalGroupsParent = Catalogs.AccessGroups.PersonalAccessGroupsParent(True);
	SimplifiedMode = AccessManagementInternal.SimplifiedAccessRightsSetupInterface();

	For Each CurRow In GroupExclude Do
		If Not IsUsersGroup And CurRow.Parent = PersonalGroupsParent And SimplifiedMode Then
			Continue;
		EndIf;
		
		GroupObject = CurRow.Group.GetObject();
		UserString = GroupObject[TabularSectionName].Find(User, "User");
		If UserString <> Undefined Then
			GroupObject[TabularSectionName].Delete(UserString);
			GroupObject.Write();
		EndIf;
	EndDo;
	
	For Each CurRow In GroupInclude Do
		GroupObject = CurRow.Group.GetObject();
		UserString = GroupObject[TabularSectionName].Find(User, "User");
		If UserString <> Undefined Then
			Continue;
		EndIf;
				
		GroupObject[TabularSectionName].Add().User = User;
		GroupObject.Write();
	EndDo;
EndProcedure
// ACC:1327-on

Function ServiceUsersIDs(GroupUsers, AllServiceUsersIDs = Undefined)
	Result = New Array;
	BlankID = New UUID("00000000-0000-0000-0000-000000000000");
	
	If AllServiceUsersIDs = Undefined Then
		
		Query = New Query("SELECT
		|	Users.ServiceUserID AS ServiceUserID
		|FROM
		|	Catalog.Users AS Users
		|WHERE 
		|	Ref IN (&GroupUsers)
		|	AND Users.ServiceUserID <> &BlankID");
		Query.SetParameter("GroupUsers", GroupUsers);
		Query.SetParameter("BlankID", BlankID);
		
		UsersTable = Query.Execute().Unload();
		For Each CurRow In UsersTable Do
			Result.Add(String(CurRow.ServiceUserID));
		EndDo;
		
	Else
		
		For Each GroupUser1 In GroupUsers Do
			UserIdentificator = AllServiceUsersIDs.Get(GroupUser1);
			If UserIdentificator = Undefined Or UserIdentificator = BlankID Then
				Continue;
			EndIf;
			
			Result.Add(String(UserIdentificator));
		EndDo;
		
	EndIf;
	
	Return Result;
EndFunction

Function CanProfileLogInToApp(Profile)

	BasicRoles = New Array;
	BasicRoles.Add(Common.MetadataObjectID(
		Metadata.Roles.BasicAccessSSL.FullName()));
	BasicRoles.Add(Common.MetadataObjectID(
		Metadata.Roles.BasicAccessExternalUserSSL.FullName()));
	
	RolesGrantingStartupRights = New Array;
	RolesGrantingStartupRights.Add(Common.MetadataObjectID(
		Metadata.Roles.StartThinClient.FullName()));
	RolesGrantingStartupRights.Add(Common.MetadataObjectID(
		Metadata.Roles.StartWebClient.FullName()));
	RolesGrantingStartupRights.Add(Common.MetadataObjectID(
		Metadata.Roles.StartMobileClient.FullName()));
	RolesGrantingStartupRights.Add(Common.MetadataObjectID(
		Metadata.Roles.StartThickClient.FullName()));
		
	Query = New Query;
	Query.SetParameter("RolesGrantingStartupRights", RolesGrantingStartupRights);
	Query.SetParameter("BasicRoles", BasicRoles);
	Query.SetParameter("Profile", Profile);
	Query.Text =
	"SELECT
	|	Subquery.Profile AS Profile
	|FROM
	|	(SELECT DISTINCT
	|		ProfilesRoles.Ref AS Profile
	|	FROM
	|		Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
	|	WHERE
	|		ProfilesRoles.Ref = &Profile
	|		AND ProfilesRoles.Role IN (&RolesGrantingStartupRights)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		ProfilesRoles.Ref AS Profile
	|	FROM
	|		Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
	|	WHERE
	|		ProfilesRoles.Ref = &Profile
	|		AND ProfilesRoles.Role IN (&BasicRoles)) AS Subquery
	|GROUP BY
	|	Subquery.Profile
	|HAVING
	|	COUNT(Subquery.Profile) > 1";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function AreRequiredCTLSubsystemsExist()
	
	Return Common.SubsystemExists("CloudTechnology.Core")
		And Common.SubsystemExists("CloudTechnology.MessagesExchange");
			
EndFunction

Function IsAPISupported(
	SupportedVersions, InterfaceName, InterfaceVersion = Undefined)
	
	InterfaceVersions = Undefined;
	
	If Not SupportedVersions.Property(InterfaceName, InterfaceVersions)
		Or Not ValueIsFilled(InterfaceVersions) Then
		
		Return False;
		
	EndIf;
	
	If ValueIsFilled(InterfaceVersion)
		And InterfaceVersions.Find(InterfaceVersion) = Undefined Then
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

Function AccessRightsManagementInterfaceName()
	
	Return "ManageAccessRights";
	
EndFunction

Function RemoteAppAdministrationInterfaceName()
	
	Return "RemoteAdministrationApp";
	
EndFunction

Function QueryTextOfAccessGroupsSelection()
	If AccessManagementInternal.SimplifiedAccessRightsSetupInterface() Then
		Return "SELECT
			|	AccessGroupProfiles.Ref AS Group
			|FROM
			|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
			|WHERE
			|	NOT AccessGroupProfiles.IsFolder";
	Else
		Return "SELECT
			|	AccessGroups.Ref AS Group
			|FROM
			|	Catalog.AccessGroups AS AccessGroups
			|WHERE
			|	AccessGroups.Parent <> &PersonalAccessGroupsParent
			|
			|ORDER BY
			|	Group HIERARCHY";
	EndIf;
EndFunction

Procedure SendMessage(Canal, Data, Recipient, IsInstant)
	ModuleMessagesExchange = Common.CommonModule("MessagesExchange");
	MessageText = Common.ValueToJSON(Data);
	
	If IsInstant Then
		ModuleMessagesExchange.SendMessageNow(Canal, MessageText, Recipient);
	Else
		ModuleMessagesExchange.SendMessage(Canal, MessageText, Recipient);
	EndIf;
EndProcedure

#EndRegion
