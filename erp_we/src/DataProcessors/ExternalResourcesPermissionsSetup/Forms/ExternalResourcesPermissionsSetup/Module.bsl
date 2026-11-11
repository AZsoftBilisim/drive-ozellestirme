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
Var StorageAddress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	StorageAddressAtServer = Parameters.StorageAddress;
	RequestsProcessingResult = GetFromTempStorage(StorageAddressAtServer);
	
	If GetFunctionalOption("UseSecurityProfiles") And Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Get() Then
		If Parameters.CheckMode Then
			Items.PagesHeader.CurrentPage = Items.ObsoletePermissionsCancellationRequiredInClusterHeaderPage;
		ElsIf Parameters.RecoveryMode Then
			Items.PagesHeader.CurrentPage = Items.SettingsInClusterToSetOnRecoveryHeaderPage;
		Else
			Items.PagesHeader.CurrentPage = Items.ChangesInClusterRequiredHeaderPage;
		EndIf;
	Else
		Items.PagesHeader.CurrentPage = Items.SettingsInClusterToSetOnEnableHeaderPage;
	EndIf;
	
	RequestsApplyingScenario = RequestsProcessingResult.Scenario;
	
	If RequestsApplyingScenario.Count() = 0 Then
		ChangesInSecurityProfilesRequired = False;
		Return;
	EndIf;
	
	PermissionsPresentation = RequestsProcessingResult.Presentation;
	
	ChangesInSecurityProfilesRequired = True;
	InfobaseAdministrationParametersRequired = False;
	For Each ScenarioStep In RequestsApplyingScenario Do
		If ScenarioStep.Operation = Enums.SecurityProfileAdministrativeOperations.Purpose
				Or ScenarioStep.Operation = Enums.SecurityProfileAdministrativeOperations.AssignmentDeletion Then
			InfobaseAdministrationParametersRequired = True;
			Break;
		EndIf;
	EndDo;
	
	AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
	
	If Common.SeparatedDataUsageAvailable() Then
		
		IBUser = InfoBaseUsers.FindByName(AdministrationParameters.InfobaseAdministratorName);
		If IBUser <> Undefined Then
			IBAdministratorID = IBUser.UUID;
		EndIf;
		
	EndIf;
	
	AttachmentType = AdministrationParameters.AttachmentType;
	ServerClusterPort = AdministrationParameters.ClusterPort;
	
	ServerAgentAddress = AdministrationParameters.ServerAgentAddress;
	ServerAgentPort = AdministrationParameters.ServerAgentPort;
	
	AdministrationServerAddress = AdministrationParameters.AdministrationServerAddress;
	AdministrationServerPort = AdministrationParameters.AdministrationServerPort;
	
	NameInCluster = AdministrationParameters.NameInCluster;
	ClusterAdministratorName = AdministrationParameters.ClusterAdministratorName;
	
	IBUser = InfoBaseUsers.FindByName(AdministrationParameters.InfobaseAdministratorName);
	If IBUser <> Undefined Then
		IBAdministratorID = IBUser.UUID;
	EndIf;
	
	Users.FindAmbiguousIBUsers(Undefined, IBAdministratorID);
	IBAdministrator = Catalogs.Users.FindByAttribute("IBUserID", IBAdministratorID);
	
	Items.AdministrationGroup.Visible = InfobaseAdministrationParametersRequired;
	Items.RestartRequiredWarningGroup.Visible = InfobaseAdministrationParametersRequired;
	
	Items.FormAllow.Title = NStr("vi = 'Tiếp theo >';
								|ru = 'Далее >';
								|en = 'Next >'; fa = 'بعدی >';
								|it = 'Avanti >';
								|pl = 'Dalej >';
								|tr = 'İleri >'");
	Items.FormBack.Visible = False;
	
	VisibilityManagement();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
#If MobileClient Then
	ShowMessageBox(, NStr("vi = 'Báo cáo không hợp lệ trong mobile client. Hãy khởi động thin client hoặc web-client.';
							|ru = 'Отчет недоступен в мобильном клиенте. Запустите тонкий клиент или веб-клиент.';
							|en = 'The report is unavailable in mobile client. Start thin client or web client.'; fa = 'The report is unavailable in mobile client. Start thin client or web client.';
							|it = 'Report non disponibile su client mobile. Avviare thin client o web client.';
							|pl = 'Raport jest niedostępny w kliencie mobilnym. Uruchom cienki klient lub klient webowy.';
							|tr = 'Rapor mobil istemcide mevcut değil. İnce istemciyi veya web istemcisini çalıştırın.'"));
	Cancel = True;
	Return;
#EndIf
	
#If WebClient Then
	ShowErrorOperationNotSupportedInWebClient();
	Return;
#EndIf
	
	If ChangesInSecurityProfilesRequired Then
		
		StorageAddress = StorageAddressAtServer;
		
	Else
		
		Close(DialogReturnCode.Ignore);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If InfobaseAdministrationParametersRequired Then
		
		If Not ValueIsFilled(IBAdministrator) Then
			Return;
		EndIf;
		
		FieldName = "IBAdministrator";
		IBUser = GetIBAdministrator();
		If IBUser = Undefined Then
			Common.MessageToUser(NStr("vi = 'Người sử dụng đã chỉ ra không có quyền truy cập đến cơ sở thông tin.';
										|ru = 'Указанный пользователь не имеет доступа к информационной базе.';
										|en = 'This user is not allowed to access the infobase.'; fa = 'This user is not allowed to access the infobase.';
										|it = 'L''utente indicato non ha accesso al database informatico.';
										|pl = 'Wskazany użytkownik nie ma dostępu do bazy informacyjnej.';
										|tr = 'Bu kullanıcının Infobase erişimi yok.'"),,
				FieldName,,Cancel);
			Return;
		EndIf;
		
		If Not Users.IsFullUser(IBUser, True) Then
			Common.MessageToUser(NStr("vi = 'Người sử dụng không có quyền quản trị.';
										|ru = 'У пользователя нет административных прав.';
										|en = 'This user has no administrative rights.'; fa = 'This user has no administrative rights.';
										|it = 'L''utente non ha permessi di amministratore.';
										|pl = 'Użytkownik nie ma uprawnień administracyjnych.';
										|tr = 'Kullanıcının yönetici yetkileri yok.'"),,
				FieldName,,Cancel);
			Return;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AttachmentTypeOnChange(Item)
	
	VisibilityManagement();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	If Items.GroupPages.CurrentPage = Items.PermissionsPage Then
		
		ErrorText = "";
		Items.ErrorGroup.Visible = False;
		Items.FormAllow.Title = NStr("vi = 'Tùy chỉnh cho phép trong Cluster server';
									|ru = 'Настроить разрешения в кластере серверов';
									|en = 'Set up permissions in server cluster'; fa = 'Set up permissions in server cluster';
									|it = 'Impostare le autorizzazioni in un cluster di server';
									|pl = 'Skonfigurować uprawnienia w klastrze serwerów';
									|tr = 'Sunucu kümesinde izinleri yapılandır'");
		Items.GroupPages.CurrentPage = Items.ConnectionPage;
		Items.FormBack.Visible = True;
		
	ElsIf Items.GroupPages.CurrentPage = Items.ConnectionPage Then
		
		ErrorText = "";
		Try
			
			ApplyPermissions();
			FinishApplyingRequests(StorageAddress);
			WaitForSettingsApplyingInCluster();
			
		Except
			ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo()); 
			Items.ErrorGroup.Visible = True;
		EndTry;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If Items.GroupPages.CurrentPage = Items.ConnectionPage Then
		Items.GroupPages.CurrentPage = Items.PermissionsPage;
		Items.FormBack.Visible = False;
		Items.FormAllow.Title = NStr("vi = 'Tiếp theo >';
									|ru = 'Далее >';
									|en = 'Next >'; fa = 'بعدی >';
									|it = 'Avanti >';
									|pl = 'Dalej >';
									|tr = 'İleri >'");
	EndIf;
	
EndProcedure

&AtClient
Procedure ReregisterCOMConnector(Command)
	
	CommonClient.RegisterCOMConnector();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure VisibilityManagement()
	
	If AttachmentType = "COM" Then
		Items.ClusterConnectionParametersByProtocolsPages.CurrentPage = Items.COMClusterConnectionParametersPage;
		COMConnectorVersionErrorGroupVisibility = True;
	Else
		Items.ClusterConnectionParametersByProtocolsPages.CurrentPage = Items.RASClusterConnectionParametersPage;
		COMConnectorVersionErrorGroupVisibility = False;
	EndIf;
	
	Items.COMConnectorVersionErrorGroup.Visible = COMConnectorVersionErrorGroupVisibility;
	
EndProcedure

&AtServer
Procedure ShowErrorOperationNotSupportedInWebClient()
	
	Items.PagesGlobal.CurrentPage = Items.OperationNotSupportedInWebClientPage;
	
EndProcedure

&AtServer
Function GetIBAdministrator()
	
	If Not ValueIsFilled(IBAdministrator) Then
		Return Undefined;
	EndIf;
	
	Return InfoBaseUsers.FindByUUID(
		Common.ObjectAttributeValue(IBAdministrator, "IBUserID"));
	
EndFunction

&AtServerNoContext
Function InfoBaseUserName(Val User)
	
	If Not ValueIsFilled(User) Then
		Return "";
	EndIf;
		
	IBUserID = Common.ObjectAttributeValue(User, "IBUserID");
	IBUser = InfoBaseUsers.FindByUUID(IBUserID);
	Return IBUser.Name;
	
EndFunction

&AtClient
Procedure ApplyPermissions()
	
	ApplyPermissionsAtServer(StorageAddress);
	
EndProcedure

&AtServer
Function StartApplyingRequests(Val StorageAddress)
	
	Result = GetFromTempStorage(StorageAddress);
	RequestsApplyingScenario = Result.Scenario;
	
	OperationKinds = New Structure();
	For Each EnumerationValue In Metadata.Enums.SecurityProfileAdministrativeOperations.EnumValues Do
		OperationKinds.Insert(EnumerationValue.Name, Enums.SecurityProfileAdministrativeOperations[EnumerationValue.Name]);
	EndDo;
	
	Return New Structure("OperationKinds, RequestsApplyingScenario, InfobaseAdministrationParametersRequired",
		OperationKinds, RequestsApplyingScenario, InfobaseAdministrationParametersRequired);
	
EndFunction

&AtServer
Procedure FinishApplyingRequests(Val StorageAddress)
	
	DataProcessors.ExternalResourcesPermissionsSetup.CommitRequests(GetFromTempStorage(StorageAddress).State);
	SaveAdministrationParameters();
	
EndProcedure

&AtServer
Procedure SaveAdministrationParameters()
	
	AdministrationParametersToSave = New Structure();
	
	// Cluster administration parameters.
	AdministrationParametersToSave.Insert("AttachmentType", AttachmentType);
	AdministrationParametersToSave.Insert("ServerAgentAddress", ServerAgentAddress);
	AdministrationParametersToSave.Insert("ServerAgentPort", ServerAgentPort);
	AdministrationParametersToSave.Insert("AdministrationServerAddress", AdministrationServerAddress);
	AdministrationParametersToSave.Insert("AdministrationServerPort", AdministrationServerPort);
	AdministrationParametersToSave.Insert("ClusterPort", ServerClusterPort);
	AdministrationParametersToSave.Insert("ClusterAdministratorName", ClusterAdministratorName);
	AdministrationParametersToSave.Insert("ClusterAdministratorPassword", "");
	
	// Infobase administration parameters.
	AdministrationParametersToSave.Insert("NameInCluster", NameInCluster);
	AdministrationParametersToSave.Insert("InfobaseAdministratorName", InfoBaseUserName(IBAdministrator));
	AdministrationParametersToSave.Insert("InfobaseAdministratorPassword", "");
	
	StandardSubsystemsServer.SetAdministrationParameters(AdministrationParametersToSave);
	
EndProcedure

&AtClient
Procedure WaitForSettingsApplyingInCluster()
	
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtServer
Procedure ApplyPermissionsAtServer(StorageAddress)
	
	ApplyingParameters = StartApplyingRequests(StorageAddress);
	
	OperationKinds = ApplyingParameters.OperationKinds;
	Scenario = ApplyingParameters.RequestsApplyingScenario;
	IBAdministrationParametersRequired = ApplyingParameters.InfobaseAdministrationParametersRequired;
	
	ClusterAdministrationParameters = ClusterAdministration.ClusterAdministrationParameters();
	ClusterAdministrationParameters.AttachmentType = AttachmentType;
	ClusterAdministrationParameters.ServerAgentAddress = ServerAgentAddress;
	ClusterAdministrationParameters.ServerAgentPort = ServerAgentPort;
	ClusterAdministrationParameters.AdministrationServerAddress = AdministrationServerAddress;
	ClusterAdministrationParameters.AdministrationServerPort = AdministrationServerPort;
	ClusterAdministrationParameters.ClusterPort = ServerClusterPort;
	ClusterAdministrationParameters.ClusterAdministratorName = ClusterAdministratorName;
	ClusterAdministrationParameters.ClusterAdministratorPassword = ClusterAdministratorPassword;
	
	If IBAdministrationParametersRequired Then
		IBAdministrationParameters = ClusterAdministration.ClusterInfobaseAdministrationParameters();
		IBAdministrationParameters.NameInCluster = NameInCluster;
		IBAdministrationParameters.InfobaseAdministratorName = InfoBaseUserName(IBAdministrator);
		IBAdministrationParameters.InfobaseAdministratorPassword = IBAdministratorPassword;
	Else
		IBAdministrationParameters = Undefined;
	EndIf;
	
	ApplyPermissionsChangesInSecurityProfilesInServerCluster(
		OperationKinds, Scenario, ClusterAdministrationParameters, IBAdministrationParameters);
	
EndProcedure

#Region ApplyingPermissionRequestsToUseExternalResources

// Applies the security profile permission changes in server cluster by the scenario.
//
// Parameters:
//  OperationKinds - Structure - Describes values of the SecurityProfileAdministrativeOperations enumeration:
//                   * Key - String - an enumeration value name,
//                   * Value - EnumRef.SecurityProfileAdministrativeOperations,
//  PermissionsApplyingScenario - Array of Structure - a scenario of applying changes in permissions to
//    use security profiles in the server cluster. Array values are structures
//    with the following fields:
//                   * Operation - EnumRef.SecurityProfileAdministrativeOperations - an operation to
//                      be executed,
//                   * Profile - String - a security profile name,
//                   * Permissions - See ClusterAdministration.SecurityProfileProperties
//  ClusterAdministrationParameters - See ClusterAdministration.ClusterAdministrationParameters
//  InfobaseAdministrationParameters - See ClusterAdministration.ClusterInfobaseAdministrationParameters
//
&AtServerNoContext
Procedure ApplyPermissionsChangesInSecurityProfilesInServerCluster(Val OperationKinds, Val PermissionsApplyingScenario, Val ClusterAdministrationParameters, Val InfobaseAdministrationParameters = Undefined)
	
	IBAdministrationParametersRequired = (InfobaseAdministrationParameters <> Undefined);
	
	ClusterAdministration.CheckAdministrationParameters(
		ClusterAdministrationParameters,
		InfobaseAdministrationParameters,
		True,
		IBAdministrationParametersRequired);
	
	For Each ScenarioItem In PermissionsApplyingScenario Do
		
		If ScenarioItem.Operation = OperationKinds.Creating Then
			
			If ClusterAdministration.SecurityProfileExists(ClusterAdministrationParameters, ScenarioItem.Profile) Then
				
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã có hồ sơ bảo mật %1 trong cụm Server. Sẽ thay thế tùy chỉnh trong hồ sơ bảo mật...';
																					|ru = 'Профиль безопасности %1 уже присутствует в кластере серверов. Настройки в профиле безопасности будут замещены...';
																					|en = 'Security profile %1 already exists in the server cluster. Settings in the security profile will be replaced…'; fa = 'Security profile %1 already exists in the server cluster. Settings in the security profile will be replaced…';
																					|it = 'Profilo di sicurezza%1 già presente nel cluster di server. Le impostazioni del profilo di sicurezza saranno trasferite...';
																					|pl = 'Profil bezpieczeństwa %1 już istnieje w klastrze serwerów. Ustawienia w profilu bezpieczeństwa będą zastąpione...';
																					|tr = 'Güvenlik profili%1 artık sunucu kümesinde mevcut. Güvenlik profilindeki ayarlar değiştirilecek...'"), ScenarioItem.Profile));
				
				ClusterAdministration.SetSecurityProfileProperties(ClusterAdministrationParameters, ScenarioItem.Permissions);
				
			Else
				
				ClusterAdministration.CreateSecurityProfile(ClusterAdministrationParameters, ScenarioItem.Permissions);
				
			EndIf;
			
		ElsIf ScenarioItem.Operation = OperationKinds.Purpose Then
			
			ClusterAdministration.SetInfobaseSecurityProfile(ClusterAdministrationParameters, InfobaseAdministrationParameters, ScenarioItem.Profile);
			
		ElsIf ScenarioItem.Operation = OperationKinds.RefreshEnabled Then
			
			ClusterAdministration.SetSecurityProfileProperties(ClusterAdministrationParameters, ScenarioItem.Permissions);
			
		ElsIf ScenarioItem.Operation = OperationKinds.Delete Then
			
			If ClusterAdministration.SecurityProfileExists(ClusterAdministrationParameters, ScenarioItem.Profile) Then
				
				ClusterAdministration.DeleteSecurityProfile(ClusterAdministrationParameters, ScenarioItem.Profile);
				
			Else
				
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không có hồ sơ bảo mật %1 trong cụm Server. Có thể là hồ sơ bảo mật đã bị xóa từ trước...';
																					|ru = 'Профиль безопасности %1 отсутствует в кластере серверов. Возможно, профиль безопасности был удален ранее...';
																					|en = 'Security profile %1 does not exist in the server cluster. Security profile might have been deleted earlier…'; fa = 'Security profile %1 does not exist in the server cluster. Security profile might have been deleted earlier…';
																					|it = 'Profilo di sicurezza %1assente nel cluster di server. Probabilmetne è stato precedentemente eliminato';
																					|pl = 'Profil bezpieczeństwa %1 brakuje w klastrze serwerów. Możliwie, że profil bezpieczeństwa został usunięty wcześniej...';
																					|tr = 'Güvenlik profili%1 sunucu kümesinde yok. Güvenlik profili daha önce silinmiş olabilir...'"), ScenarioItem.Profile));
				
			EndIf;
			
		ElsIf ScenarioItem.Operation = OperationKinds.AssignmentDeletion Then
			
			ClusterAdministration.SetInfobaseSecurityProfile(ClusterAdministrationParameters, InfobaseAdministrationParameters, "");
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion