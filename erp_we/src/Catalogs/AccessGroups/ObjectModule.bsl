///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var PreviousValues1; // Values of some attributes and tables of the access group
                      // before it is changed for use in the "OnWrite" event handler.

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	// ACC:75-off - The DataExchange.Load check must follow the logging of changes.
	If IsFolder Then
		Return;
	EndIf;
	
	If UsersInternal.ShouldRegisterChangesInAccessRights()
	 Or Not DataExchange.Load Then
		
		AccessManagement.SetLockBeforeWriteToFileIB(, True);
		PreviousValues1 = PreviousValues1();
	EndIf;
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AccessManagementInternal.SimplifiedAccessRightsSetupInterface()
		And AccessManagementInternal.IsCTLUserRightsSetupSupported() Then
		
		// Intended for "AccessManagementInternalSaaS.MembersByProfile"
		Block = New DataLock();
		LockItem = Block.Add("Catalog.AccessGroupProfiles");
		LockItem.SetValue("Ref", Profile);
		
		// ACC:1320-off - Omit "Try…Except" as the "BeforeWrite" handler puts a lock.
		Block.Lock(); 
		// ACC:1320-on
	EndIf;

	InformationRegisters.RolesRights.CheckRegisterData();
	
	If Not Catalogs.ExtensionsVersions.AllExtensionsConnected() Then
		Catalogs.AccessGroupProfiles.RestoreNonexistentViewsFromAccessValue(PreviousValues1, ThisObject);
	EndIf;
	
	// Deleting blank members of the access group.
	IndexOf = Users.Count() - 1;
	While IndexOf >= 0 Do
		If Not ValueIsFilled(Users[IndexOf].User) Then
			Users.Delete(IndexOf);
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	
	If Ref = AccessManagement.AdministratorsAccessGroup() Then
		
		// Administrator predefined profile is always used.
		Profile = AccessManagement.ProfileAdministrator();
		
		// Cannot be a personal access group.
		User = Undefined;
		
		// Regular users cannot be responsible for the group (only full access users can).
		EmployeeResponsible = Undefined;
		
		// Only full access users can make changes.
		ModuleUsers = Common.CommonModule("Users");
		If Not ModuleUsers.IsFullUser() Then
			Raise
				NStr("vi = 'Người quản trị có thể thay đổi nhóm truy cập định trước
				           |trong chế độ đặc quyền
				           |hoặc có ""Toàn quyền"".';
				           |ru = 'Предопределенную группу доступа Администраторы
				           |можно изменять, либо в привилегированном режиме,
				           |либо при наличии роли ""Полные права"".';
				           |en = 'The predefined access group ""Administrators""
				           |can be changed only if you have the ""Full access"" role
				           |or in privileged mode.'; fa = 'The predefined access group ""Administrators""
				           |can be changed only if you have the ""Full access"" role
				           |or in privileged mode.';
				           |it = 'Il gruppo di accesso predefinito Amministratori
				           |è modificabile solamente in modalità privilegiata
				           |oppure se si dispone del ruolo ""Diritti completi"".';
				           |pl = 'Predefiniowaną grupę dostępu Administratorzy
				           |można zmieniać albo w trybie uprzywilejowanym,
				           |albo posiadając rolę ""Pełne uprawnienia"".';
				           |tr = 'Önceden belirlenmiş Yönetici grubu, 
				           |ya ayrıcalıklı modda 
				           |ya da ""Tüm haklar"" rolü bulunduğunda değiştirilebilir.'");
		EndIf;
		
		// Checking whether the access group contains regular users only.
		For Each CurrentRow In Users Do
			If TypeOf(CurrentRow.User) <> Type("CatalogRef.Users") Then
				Raise
					NStr("vi = 'Nhóm truy cập định trước Người quản trịị
					           | chỉ có thể chứa người sử dụng. 
					           |
					           |Nhóm người sử dụng, người sử dụng ngoài và
					           |nhóm người sử dụng ngoài không được phép.';
					           |ru = 'Предопределенная группа доступа Администраторы
					           |может содержать только пользователей.
					           |
					           |Группы пользователей, внешние пользователи и
					           |группы внешних пользователей недопустимы.';
					           |en = 'The predefined access group ""Administrators""
					           |can contain only users.
					           |
					           |User groups, external users, and
					           |external user groups are not allowed.'; fa = 'The predefined access group ""Administrators""
					           |can contain only users.
					           |
					           |User groups, external users, and
					           |external user groups are not allowed.';
					           |it = 'Il gruppo di accesso predefinito Amministratori
					           |può contenere solamente utenti.
					           |
					           |Gruppi di utenti, utenti esterni e
					           |gruppi di utenti esterni non sono permessi.';
					           |pl = 'Predefiniowana grupa dostępu Administratorzy
					           |może zawierać wyłącznie użytkowników.
					           |
					           |Grupy użytkowników, użytkownicy zewnętrzni i
					           |grupy użytkowników zewnętrznych są niedozwolone.';
					           |tr = 'Yöneticiler grubu, aşağıdaki türlerden 
					           |bir veya birkaç öğe içerdiği için kaydedilemez: kullanıcı grubu, harici kullanıcı veya 
					           |harici kullanıcı grubu.
					           |
					           |Bu öğeleri kaldırın ve tekrar deneyin.'");
			EndIf;
		EndDo;
		
	// Administrator predefined profile cannot be set to an arbitrary access group.
	ElsIf Profile = AccessManagement.ProfileAdministrator() Then
		Raise
			NStr("vi = 'Hồ sơ định trước Người quản trị chỉ có thể nằm trong
			           |nhóm truy cập định trước Người quản trị.';
			           |ru = 'Предопределенный профиль Администратор может быть только
			           |у предопределенной группы доступа Администраторы.';
			           |en = 'Only the predefined access group ""Administrators""
			           |can have the predefined profile ""Administrator.""'; fa = 'Only the predefined access group ""Administrators""
			           |can have the predefined profile ""Administrator.""';
			           |it = 'Il profilo predefinito Amministratore può essere assegnato solamente
			           |al gruppo di accesso predefinito Amministratori.';
			           |pl = 'Predefiniowany profil Administrator może należeć tylko
			           |do predefiniowanej grupy dostępu Administratorzy.';
			           |tr = 'Önceden tanımlanmış Yönetici profili 
			           |yalnızca önceden tanımlanmış Yöneticiler erişim grubunda olabilir.'");
	EndIf;
	
	// Automatically setting attributes for the personal access group.
	If ValueIsFilled(User) Then
		Parent = Catalogs.AccessGroups.PersonalAccessGroupsParent();
	Else
		User = Undefined;
		If Parent = Catalogs.AccessGroups.PersonalAccessGroupsParent(True) Then
			Parent = Undefined;
		EndIf;
	EndIf;
	
	// When the deletion mark is cleared from an access group,
	// it's also cleared from the group's profile.
	If Not DeletionMark And PreviousValues1.DeletionMark = True
	   And Profile = PreviousValues1.Profile Then
		
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Catalog.AccessGroupProfiles");
			LockItem.SetValue("Ref", Profile);
			Block.Lock();
			
			ProfileDeletionMark = Common.ObjectAttributeValue(Profile, "DeletionMark");
			ProfileDeletionMark = ?(TypeOf(ProfileDeletionMark) = Type("Boolean"), ProfileDeletionMark, False);
			If ProfileDeletionMark Then
				AccessManagement.CheckChangeAllowed(Profile);
				LockDataForEdit(Profile);
				SetPrivilegedMode(True);
				ProfileObject = Profile.GetObject();
				ProfileObject.AdditionalProperties.Insert("UnmarkProfileForDeletionWhenAccessGroupUnmarkedForDeletion", Ref);
				ProfileObject.DeletionMark = False;
				ProfileObject.Write();
				SetPrivilegedMode(False);
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

// Updates:
// - roles of added, remaining, and deleted users
// - InformationRegister.AccessGroupsTables
// - InformationRegister.AccessGroupsValues
//
Procedure OnWrite(Cancel)
	
	// ACC:75-off - The DataExchange.Load check must follow the logging of changes.
	If IsFolder Then
		SendMessageAboutAccessGroupChanges();		
		Return;
	EndIf;
	
	If UsersInternal.ShouldRegisterChangesInAccessRights() Then
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		
		Catalogs.AccessGroups.RegisterChangeInAccessGroupsMembers(ThisObject, PreviousValues1);
		Catalogs.AccessGroups.RegisterChangeInAllowedValues(ThisObject, PreviousValues1);
		
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
	EndIf;
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not AdditionalProperties.Property("DoNotUpdateUsersRoles") Then
		UpdateUsersRolesOnChangeAccessGroup();
	EndIf;
	
	HasMembers = Users.Count() <> 0;
	HasOldMembers = PreviousValues1.Ref = Ref And Not PreviousValues1.Users.IsEmpty();
	
	If Profile           <> PreviousValues1.Profile
	 Or DeletionMark   <> PreviousValues1.DeletionMark
	 Or HasMembers <> HasOldMembers Then
		
		InformationRegisters.AccessGroupsTables.UpdateRegisterData(Ref);
	EndIf;
	
	If AccessManagementInternal.LimitAccessAtRecordLevelUniversally() Then
		CompositionOfRoleChanges = Catalogs.AccessGroups.RolesForUpdatingRights(PreviousValues1, ThisObject);
		AccessManagementInternal.ScheduleAnAccessUpdateWhenTheAccessGroupProfileChanges(
			"AccessGroupWhenChangingTheProfile", CompositionOfRoleChanges, Profile <> PreviousValues1.Profile);
	EndIf;
	
	If Catalogs.AccessGroups.AccessKindsOrAccessValuesChanged(PreviousValues1, ThisObject)
	 Or DeletionMark   <> PreviousValues1.DeletionMark
	 Or HasMembers <> HasOldMembers Then
		
		InformationRegisters.AccessGroupsValues.UpdateRegisterData(Ref);
	EndIf;
	
	If AccessManagementInternal.LimitAccessAtRecordLevelUniversally() Then
		ChangedMembersTypes = ChangedMembersTypes(Users, PreviousValues1.Users,
			DeletionMark <> PreviousValues1.DeletionMark);
		AccessManagementInternal.ScheduleAccessGroupsSetsUpdate(
			"AccessGroupsOnChangingMembers",
			ChangedMembersTypes.Users,
			ChangedMembersTypes.ExternalUsers);
		
		If Not DeletionMark Then
			AccessManagementInternal.ScheduleAccessUpdateOnChangeAccessGroupMembers(Ref,
				ChangedMembersTypes);
		EndIf;
		If DeletionMark <> PreviousValues1.DeletionMark Then
			AccessManagementInternal.UpdateAccessGroupsOfAllowedAccessKey(Ref);
		EndIf;
	EndIf;
	
	SendMessageAboutAccessGroupChanges();
	
EndProcedure

Procedure SendMessageAboutAccessGroupChanges(ThisIsRemoval = False)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AccessManagementInternal.IsAccessManagementSaaSSupported() Then
		ModuleAccessManagementInternalSaaS = Common.CommonModule(
			"AccessManagementInternalSaaS");
		ModuleAccessManagementInternalSaaS.SendMessageAboutAccessGroupChanges(ThisObject, ThisIsRemoval);
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If AdditionalProperties.Property("VerifiedObjectAttributes") Then
		Common.DeleteNotCheckedAttributesFromArray(
			CheckedAttributes, AdditionalProperties.VerifiedObjectAttributes);
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SendMessageAboutAccessGroupChanges(True);

EndProcedure

#EndRegion

#Region Private

// Values of some attributes and tables of the access group
// before it is changed for use in the "OnWrite" event handler.
// 
// Returns:
//  Structure:
//     * Ref - CatalogRef.AccessGroups
//     * DeletionMark - Boolean
//     * Profile - CatalogRef.AccessGroupProfiles
//     * ProfileDeletionMark - Boolean
//     * Users - QueryResult
//     * AccessKinds - QueryResult
//     * AccessValues - QueryResult
//
Function PreviousValues1()
	
	Result = Common.ObjectAttributesValues(Ref,
		"Ref, Profile, DeletionMark, Users, AccessKinds, AccessValues");
	
	Result.Insert("ProfileDeletionMark", Undefined);
	
	If ValueIsFilled(Result.Profile) Then
		Result.ProfileDeletionMark = Common.ObjectAttributeValue(
			Result.Profile, "DeletionMark");
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  NewMembers - CatalogTabularSection.AccessGroups.Users
//  OldMembers - QueryResult
//                  - Undefined
// Returns:
//  Structure:
//    * ExternalUsers - Boolean
//    * Users - Boolean
//
Function ChangedMembersTypes(NewMembers, OldMembers, DeletionTagHasChanged)
	
	ChangedMembersTypes = New Structure;
	ChangedMembersTypes.Insert("Users", False);
	ChangedMembersTypes.Insert("ExternalUsers", False);
	
	AllMembers = NewMembers.Unload(, "User");
	AllMembers.Columns.Add("LineChangeType", New TypeDescription("Number"));
	AllMembers.FillValues(1, "LineChangeType");
	If OldMembers <> Undefined Then
		Selection = OldMembers.Select();
		While Selection.Next() Do
			NewRow = AllMembers.Add();
			NewRow.User = Selection.User;
			NewRow.LineChangeType = -1;
		EndDo;
	EndIf;
	AllMembers.GroupBy("User", "LineChangeType");
	For Each String In AllMembers Do
		If String.LineChangeType = 0
		   And Not DeletionTagHasChanged Then
			Continue;
		EndIf;
		If TypeOf(String.User) = Type("CatalogRef.Users")
		 Or TypeOf(String.User) = Type("CatalogRef.UserGroups") Then
			ChangedMembersTypes.Users = True;
		EndIf;
		If TypeOf(String.User) = Type("CatalogRef.ExternalUsers")
		 Or TypeOf(String.User) = Type("CatalogRef.ExternalUsersGroups") Then
			ChangedMembersTypes.ExternalUsers = True;
		EndIf;
	EndDo;
	
	Return ChangedMembersTypes;
	
EndFunction

Procedure UpdateUsersRolesOnChangeAccessGroup()
	
	If Common.DataSeparationEnabled()
		And Ref = AccessManagement.AdministratorsAccessGroup()
		And AdditionalProperties.Property("ServiceUserPassword") Then
		
		ServiceUserPassword = AdditionalProperties.ServiceUserPassword;
	Else
		ServiceUserPassword = Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	
	UsersForUpdate =
		Catalogs.AccessGroups.UsersForRolesUpdate(PreviousValues1, ThisObject);
	
	If Ref = AccessManagement.AdministratorsAccessGroup() Then
		// Adding users associated with infobase users with the FullAccess role.
		
		For Each IBUser In InfoBaseUsers.GetUsers() Do
			If IBUser.Roles.Contains(Metadata.Roles.FullAccess) Then
				
				FoundUser = Catalogs.Users.FindByAttribute(
					"IBUserID", IBUser.UUID);
				
				If Not ValueIsFilled(FoundUser) Then
					FoundUser = Catalogs.ExternalUsers.FindByAttribute(
						"IBUserID", IBUser.UUID);
				EndIf;
				
				If ValueIsFilled(FoundUser)
				   And UsersForUpdate.Find(FoundUser) = Undefined Then
					
					UsersForUpdate.Add(FoundUser);
				EndIf;
				
			EndIf;
		EndDo;
	EndIf;
	
	AccessManagement.UpdateUserRoles(UsersForUpdate, ServiceUserPassword);
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf