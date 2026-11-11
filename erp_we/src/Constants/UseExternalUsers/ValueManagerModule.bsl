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

// Intended for the OnWrite event handler.
Var PreviousValue2;

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PreviousValue2 = Constants.UseExternalUsers.Get();
	
	If Value = PreviousValue2 Then
		Return;
	EndIf;
	
	If Not PreviousValue2 And Value And Not UsersInternal.ExternalUsersEmbedded() Then
		ErrorText =
			NStr("vi = 'Chưa xem xét việc sử dụng người sử dụng ngoài trong ứng dụng.';
				|ru = 'Использование внешних пользователей не предусмотрено в приложении.';
				|en = 'The application does not support external users.'; fa = 'The application does not support external users.';
				|it = 'Использование внешних пользователей не предусмотрено в приложении.';
				|pl = 'The application does not support external users.';
				|tr = 'Uygulamada harici kullanıcıların kullanımı öngörülmemiştir.'");
		Raise ErrorText;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ErrorText =
			NStr("vi = 'Cần thực hiện thay đổi sử dụng nhóm người sử dụng trong ứng dụng trong dịch vụ.';
				|ru = 'Изменение использования групп пользователей следует выполнить в приложении в сервисе.';
				|en = 'User groups can only be customized in the SaaS version.'; fa = 'User groups can only be customized in the SaaS version.';
				|it = 'Изменение использования групп пользователей следует выполнить в приложении в сервисе.';
				|pl = 'User groups can only be customized in the SaaS version.';
				|tr = 'Kullanıcı gruplarının kullanımının değiştirilmesi servisteki uygulamada yapılmalıdır.'");
		Raise ErrorText;
		
	ElsIf Common.IsSubordinateDIBNode() Then
		ErrorText =
			NStr("vi = 'Cần thực hiện thay đổi sử dụng nhóm người sử dụng trong nút chính của cơ sở thông tin.';
				|ru = 'Изменение использования групп пользователей следует выполнить в главном узле информационной базы.';
				|en = 'User groups can only be customized in the master node.'; fa = 'User groups can only be customized in the master node.';
				|it = 'Изменение использования групп пользователей следует выполнить в главном узле информационной базы.';
				|pl = 'User groups can only be customized in the master node.';
				|tr = 'Kullanıcı gruplarının kullanımının değiştirilmesi infobase''in ana düğümünde yapılmalıdır.'");
		Raise ErrorText;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.SetLockBeforeWriteToFileIB(, True);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Constants.UseExternalUserGroups.Refresh();
	
	If Value <> PreviousValue2 Then
		OnToggleExternalUsersUsage(Value);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// For internal use only.
Procedure RegisterChangeUponDataImport(DataElement) Export
	
	If DataElement.Value = Constants.UseExternalUsers.Get() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	UsersInternal.RegisterRefs("UseExternalUsers", True);
	
EndProcedure

// For internal use only.
Procedure ProcessChangeRegisteredUponDataImport() Export
	
	If Common.DataSeparationEnabled() Then
		// In the SWS, settings are locked for editing and are not imported into the data area.
		Return;
	EndIf;
	
	Changes = UsersInternal.RegisteredRefs("UseExternalUsers");
	If Changes.Count() = 0 Then
		Return;
	EndIf;
	
	OnToggleExternalUsersUsage(
		Constants.UseExternalUsers.Get());
	
	UsersInternal.RegisterRefs("UseExternalUsers", Null);
	
EndProcedure

Procedure OnToggleExternalUsersUsage(Var_Value)
	
	UsersInternal.UpdateExternalUsersRoles();
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.UpdateUserRoles(Type("CatalogRef.ExternalUsers"));
		
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		If ModuleAccessManagementInternal.LimitAccessAtRecordLevelUniversally() Then
			PlanningParameters = ModuleAccessManagementInternal.AccessUpdatePlanningParameters();
			PlanningParameters.ForUsers = False;
			PlanningParameters.ForExternalUsers = True;
			PlanningParameters.IsUpdateContinuation = True;
			PlanningParameters.LongDesc = "UseExternalUsersOnWrite";
			ModuleAccessManagementInternal.ScheduleAccessUpdate(, PlanningParameters);
		EndIf;
	EndIf;
	
	If Var_Value Then
		UsersInternal.SetShowInListAttributeForAllInfobaseUsers(False);
	Else
		ClearCanSignInAttributeForAllExternalUsers();
	EndIf;
	
	SetPropertySetUsageFlag();
	
EndProcedure

// Clears the FlagShowInList attribute for all infobase users.
Procedure ClearCanSignInAttributeForAllExternalUsers()
	
	Query = New Query;
	Query.SetParameter("BlankUUID",
		CommonClientServer.BlankUUID());
	Query.Text =
	"SELECT
	|	ExternalUsers.Ref AS Ref,
	|	ExternalUsers.IBUserID AS Id
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.IBUserID <> &BlankUUID";
	IDs = Query.Execute().Unload();
	IDs.Indexes.Add("Id");
	
	IBUsers = InfoBaseUsers.GetUsers();
	ChangedUsers = New Array;
	
	For Each IBUser In IBUsers Do
		
		FoundRow = IDs.Find(IBUser.UUID, "Id");
		If FoundRow <> Undefined
		   And Users.CanSignIn(IBUser) Then
			
			IBUser.StandardAuthentication    = False;
			IBUser.OpenIDAuthentication         = False;
			IBUser.OpenIDConnectAuthentication  = False;
			IBUser.AccessTokenAuthentication = False;
			IBUser.OSAuthentication             = False;
			IBUser.Write();
			ChangedUsers.Add(FoundRow.Ref);
		EndIf;
	EndDo;
	
	InformationRegisters.UsersInfo.UpdateRegisterData(ChangedUsers);
	
EndProcedure

Procedure SetPropertySetUsageFlag()
	
	If Not Common.SubsystemExists("StandardSubsystems.Properties") Then
		Return;
	EndIf;
	ModulePropertyManager = Common.CommonModule("PropertyManager");
	
	SetParameters = ModulePropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Value;
	ModulePropertyManager.SetPropertySetParameters("Catalog_ExternalUsers", SetParameters);
	
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