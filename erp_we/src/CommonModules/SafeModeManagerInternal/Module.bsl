///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Checks whether the security profiles can be set up for the current infobase.
//
// Returns: 
//   Boolean - True if the setting is available.
//
Function CanSetUpSecurityProfiles() Export
	
	If SecurityProfilesUsageAvailable() Then
		
		Cancel = False;
		
		SSLSubsystemsIntegration.OnCheckCanSetupSecurityProfiles(Cancel);
		If Not Cancel Then
			SafeModeManagerOverridable.OnCheckCanSetupSecurityProfiles(Cancel);
		EndIf;
		
		Return Not Cancel;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

#Region ExternalModules

// Returns external module attachment mode.
//
// Parameters:
//  ExternalModule - AnyRef - a reference that matches the external module for which
//    the attaching mode is requested.
//
// Returns:
//   String - a name of the security profile to be used for attaching
//  the external module. If the attachment mode is not registered for the external module, Undefined is returned.
//
Function ExternalModuleAttachmentMode(Val ExternalModule) Export
	
	Return InformationRegisters.ExternalModulesAttachmentModes.ExternalModuleAttachmentMode(ExternalModule);
	
EndFunction

#EndRegion

#Region SecurityProfilesUsage

// Returns a namespace URI of an XDTO package used to describe permissions
// in security profiles.
//
// Returns:
//   String
//
Function Package() Export
	
	Return Metadata.XDTOPackages.ApplicationPermissions_1_0_0_2.Namespace;
	
EndFunction

#EndRegion

#Region PermissionRequestCreation

// Creates requests to use external resources for the external module.
//
// Parameters:
//  ProgramModule - AnyRef - a reference that matches the external module for which permissions are being requested.
//  NewPermissions - Array of XDTODataObject - an array of XDTODataObjects that match internal details of external resource access permissions to be requested.
//    It is assumed that all XDTODataObjects passed 
//    as parameters are generated using the SafeModeManager.Permission*() functions.
//    When requesting permissions for external modules, permissions are added in replacement mode.
//
// Returns:
//   Array of UUID - IDs of the created requests.
//
Function PermissionsRequestForExternalModule(Val ProgramModule, Val NewPermissions = Undefined) Export
	
	Result = New Array();
	
	If NewPermissions = Undefined Then
		NewPermissions = New Array();
	EndIf;
	
	If NewPermissions.Count() > 0 Then
		
		// If there is no security profile, create it.
		If ExternalModuleAttachmentMode(ProgramModule) = Undefined Then
			Result.Add(RequestForSecurityProfileCreation(ProgramModule));
		EndIf;
		
		Result.Add(
			PermissionChangeRequest(
				ProgramModule, True, NewPermissions, Undefined, ProgramModule));
		
	Else
		
		// If there is a security profile, delete it.
		If ExternalModuleAttachmentMode(ProgramModule) <> Undefined Then
			Result.Add(RequestToDeleteSecurityProfile(ProgramModule));
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region SecurityProfilesUsage


// Cast the referenced to the format "Type + ID" for storing in permission registers.
// A custom Ref storage method is used because permission registers don't require reference integrity
//
// and register records are not deleted following an object deletion.
// 
// 
//

// Generates parameters for storing references in permission registers.
//
// Parameters:
//  Ref - AnyRef
//
// Returns:
//   Structure:
//                        * Type - CatalogRef.MetadataObjectIDs,
//                        * Id - UUID - a reference
//                           UUID.
//
Function PropertiesForPermissionRegister(Val Ref) Export
	
	Result = New Structure("Type,Id");
	
	If Ref = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
		Result.Type = Catalogs.MetadataObjectIDs.EmptyRef();
		Result.Id = CommonClientServer.BlankUUID();
		
	Else
		
		Result.Type = Common.MetadataObjectID(Ref.Metadata());
		Result.Id = Ref.UUID();
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ApplyingPermissionRequestsToUseExternalResources

Function PermissionsToUseExternalResourcesPresentation(Val ProgramModuleType, 
	Val ModuleID, Val OwnerType, Val OwnerID, Val Permissions) Export
	
	// ACC:326-off - The transaction is intended to use the "PermissionsRequests" information register as an
	// intermediate cache for estimating if the queries are used to allow external resources.
	// Transaction rollbacks are used as a trigger for clearing up the calculation cache.
	
	BeginTransaction();
	Try
		Manager = DataProcessors.ExternalResourcesPermissionsSetup.Create();
		
		Manager.AddRequestForPermissionsToUseExternalResources(
			ProgramModuleType,
			ModuleID,
			OwnerType,
			OwnerID,
			True,
			Permissions,
			New Array());
		
		Manager.CalculateRequestsApplication();
		
		RollbackTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	// ACC:326-on
	
	Return Manager.Presentation(True);
	
EndFunction

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters, BeforeUpdateApplicationRunParameters = False) Export
	
	If BeforeUpdateApplicationRunParameters Then
		Parameters.Insert("DisplayPermissionSetupAssistant", False);
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Parameters.Insert("DisplayPermissionSetupAssistant", InteractivePermissionRequestModeUsed());
	If Not Parameters.DisplayPermissionSetupAssistant Then
		Return;
	EndIf;	
	
	If Not Users.IsFullUser() Then
		Return;
	EndIf;	
			
	Validation = ExternalResourcesPermissionsSetupServerCall.CheckApplyPermissionsToUseExternalResources();
	If Validation.CheckResult Then
		Parameters.Insert("CheckExternalResourceUsagePermissionsApplication", False);
	Else
		Parameters.Insert("CheckExternalResourceUsagePermissionsApplication", True);
		Parameters.Insert("PermissionsToUseExternalResourcesApplicabilityCheck", Validation);
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParameters
Procedure OnAddClientParameters(Parameters) Export
	
	SetPrivilegedMode(True);
	Parameters.Insert("DisplayPermissionSetupAssistant", InteractivePermissionRequestModeUsed());
	
EndProcedure


// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ExternalResourcesInUse);
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Creates a request to create a security profile for the external module.
// For internal use only.
//
// Parameters:
//  ExternalModule - AnyRef - a reference that matches the external module for which
//    permissions are being requested (Undefined if permissions are requested for configurations, not for external modules).
//
// Returns:
//   UUID - an ID of the created request.
//
Function RequestForSecurityProfileCreation(Val ProgramModule)
	
	StandardProcessing = True;
	Result = Undefined;
	Operation = Enums.SecurityProfileAdministrativeOperations.Creating;
	
	SSLSubsystemsIntegration.OnRequestToCreateSecurityProfile(
		ProgramModule, StandardProcessing, Result);
	
	If StandardProcessing Then
		SafeModeManagerOverridable.OnRequestToCreateSecurityProfile(
			ProgramModule, StandardProcessing, Result);
	EndIf;
	
	If StandardProcessing Then
		
		Result = InformationRegisters.RequestsForPermissionsToUseExternalResources.PermissionAdministrationRequest(
			ProgramModule, Operation);
		
	EndIf;
	
	Return Result;
	
EndFunction

#Region SecurityProfilesUsage

// Checks whether the security profiles can be used for the current infobase.
//
// Returns:
//   Boolean
//
Function SecurityProfilesUsageAvailable() Export
	
	If Common.FileInfobase(InfoBaseConnectionString()) Then
		Return False;
	EndIf;
	
	Cancel = False;
	
	SafeModeManagerOverridable.OnCheckSecurityProfilesUsageAvailability(Cancel);
	
	Return Not Cancel;
	
EndFunction

// Returns checksums of add-in files from the bundle provided in the configuration template.
//
// Parameters:
//  TemplateName - String - a configuration template name.
//
// Returns:
//   FixedMap of KeyAndValue:
//                         * Key - String - a file name,
//                         * Value - String - a checksum.
//
Function AddInBundleFilesChecksum(Val TemplateName) Export
	
	Result = New Map();
	
	NameStructure = StrSplit(TemplateName, ".");
	
	If NameStructure.Count() = 2 Then
		
		// This is a common template.
		Template = GetCommonTemplate(NameStructure[1]);
		
	ElsIf NameStructure.Count() = 4 Then
		
		// This is a metadata object template.
		ObjectManager = Common.ObjectManagerByFullName(NameStructure[0] + "." + NameStructure[1]);
		Template = ObjectManager.GetTemplate(NameStructure[3]);
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo quyền được phép sử dụng cấu phần ngoài: 
				  |Tên biểu mẫu không hợp lệ %1.';
				  |ru = 'Не удалось сформировать разрешение на использование внешней компоненты:
				  |некорректное имя макета %1.';
				  |en = 'Cannot generate a permission to use the add-in:
				  |incorrect name of the %1 template.'; fa = 'Cannot generate a permission to use the add-in:
				  |incorrect name of the %1 template.';
				  |it = 'Non è stato possibile fornire l''autorizzazione per l''utilizzo del componente esterno: 
				  | nome del modello errato %1.';
				  |pl = 'Nie udało się wygenerować uprawnień do używania komponentów zewnętrznych:
				  |niepoprawna nazwa układu %1.';
				  |tr = 'Harici bileşeni kullanma izni oluşturulamadı:
				  |geçersiz şablon adı %1.'"), TemplateName);
	EndIf;
	
	If Template = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo quyền sử dụng cấu phần ngoài được cung cấp,
				  |trong khuôn in %1: không tìm thấy khuôn in %1 trong cấu hình.';
				  |ru = 'Не удалось сформировать разрешение на использование внешней компоненты,
				  |поставляемой в макете %1: макет %1 не обнаружен в составе конфигурации.';
				  |en = 'Cannot create a permission to use the add-in supplied in the template %1:
				  | Template %1 is not found in the configuration.'; fa = 'Cannot create a permission to use the add-in supplied in the template %1:
				  | Template %1 is not found in the configuration.';
				  |it = 'Non è stato possibile fornire l''autorizzazione per l''utilizzo del componente esterno, 
				  |fornito consegnato con il modello %1: il modello %1 non è stato rilevato all''interno della configurazione.';
				  |pl = 'Nie udało się wygenerować uprawnień do używania komponentów zewnętrznych:
				  |w układzie %1: układ %1 nie znaleziono w konfiguracji.';
				  |tr = '%1 şablonda sağlanan harici bileşeni kullanma izni oluşturulamadı
				  |: %1 şablon konfigürasyonda bulunamadı.'"), TemplateName);
	EndIf;
	
	TemplateType = Metadata.FindByFullName(TemplateName).TemplateType;
	If TemplateType <> Metadata.ObjectProperties.TemplateType.BinaryData And TemplateType <> Metadata.ObjectProperties.TemplateType.AddIn Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo quyền sử dụng cấu phần ngoài:
				  |khuôn in %1 không chứa dữ liệu nhị phân.';
				  |ru = 'Не удалось сформировать разрешение на использование внешней компоненты:
				  |макет %1 не содержит двоичных данных.';
				  |en = 'Cannot generate a permission to use the add-in:
				  |the %1 template does not contain binary data.'; fa = 'Cannot generate a permission to use the add-in:
				  |the %1 template does not contain binary data.';
				  |it = 'Non è stato possibile fornire l''autorizzazione per l''utilizzo del componente esterno: 
				  |il modello %1 non contiene i dati binari.';
				  |pl = 'Nie udało się wygenerować uprawnień do używania komponentów zewnętrznych:
				  |układ %1 nie zawiera binarnych danych.';
				  |tr = 'Harici bileşeni kullanma izni oluşturulamadı:
				  |şablon %1 ikili veri içermez.'"), TemplateName);
	EndIf;
	
	TempFile = GetTempFileName("zip");
	Template.Write(TempFile);
	
	Archiver = New ZipFileReader(TempFile);
	UnpackDirectory = GetTempFileName() + "\";
	CreateDirectory(UnpackDirectory);
	
	ManifestFile = "";
	For Each ArchiveItem In Archiver.Items Do
		If Upper(ArchiveItem.Name) = "MANIFEST.XML" Then
			ManifestFile = UnpackDirectory + ArchiveItem.Name;
			Archiver.Extract(ArchiveItem, UnpackDirectory);
		EndIf;
	EndDo;
	
	If IsBlankString(ManifestFile) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo quyền sử dụng thành phần bên ngoài,
				  |được cung cấp trong biểu mẫu %1: không tìm thấy tệp MANIFEST.XML trong tệp nén.';
				  |ru = 'Не удалось сформировать разрешение на использование внешней компоненты,
				  |поставляемой в макете %1: в архиве не обнаружен файл MANIFEST.XML.';
				  |en = 'Cannot create a permission to use the add-in supplied in the template %1:
				  |The archive does not contain the MANIFEST.XML file.'; fa = 'Cannot create a permission to use the add-in supplied in the template %1:
				  |The archive does not contain the MANIFEST.XML file.';
				  |it = 'Non è stato possibile fornire l''autorizzazione per l''utilizzo del componente esterno 
				  |consegnato con il modello %1: nell''archivio non è stato rilevato il file MANIFEST.XML.';
				  |pl = 'Nie udało się wygenerować uprawnień do używania komponentu zewnętrznego,
				  |dostarczonego w układzie %1: w archiwum nie znaleziono pliku MANIFEST.XML.';
				  |tr = '%1 şablonda sağlanan harici bileşeni kullanma izni oluşturulamadı
				  |: arşivde MANIFEST.XML dosyası tespit edilemedi.'"), TemplateName);
	EndIf;
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(ManifestFile);
	BundleDetails = XDTOFactory.ReadXML(ReaderStream, XDTOFactory.Type("http://v8.1c.ru/8.2/addin/bundle", "bundle"));
	For Each ComponentDetails In BundleDetails.component Do
		
		If ComponentDetails.type = "native" Or ComponentDetails.type = "com" Then
			
			ComponentFile = UnpackDirectory + ComponentDetails.path;
			
			Archiver.Extract(Archiver.Items.Find(ComponentDetails.path), UnpackDirectory);
			
			Hashing = New DataHashing(HashFunction.SHA1);
			Hashing.AppendFile(ComponentFile);
			Result.Insert(ComponentDetails.path, Base64String(Hashing.HashSum));
			
		EndIf;
		
	EndDo;
	
	ReaderStream.Close();
	Archiver.Close();
	
	Try
		DeleteFiles(UnpackDirectory);
	Except
		WriteLogEvent(NStr("vi = 'Làm việc ở chế độ an toàn. Không thể xóa file tạm.';
							|ru = 'Работа в безопасном режиме.Не удалось удалить временный файл';
							|en = 'Safe mode manager.Cannot create temporary file'; fa = 'Safe mode manager.Cannot create temporary file';
							|it = 'Lavoro in modalità sicura. Non è stato possibile cancellare il file temporaneo';
							|pl = 'Pracuj w trybie awaryjnym.Nie można usunąć pliku tymczasowego';
							|tr = 'Güvenli modda çalışma.Geçici dosya silinemedi'", Common.DefaultLanguageCode()), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Try
		DeleteFiles(TempFile);
	Except
		WriteLogEvent(NStr("vi = 'Làm việc ở chế độ an toàn. Không thể xóa file tạm.';
							|ru = 'Работа в безопасном режиме.Не удалось удалить временный файл';
							|en = 'Safe mode manager.Cannot create temporary file'; fa = 'Safe mode manager.Cannot create temporary file';
							|it = 'Lavoro in modalità sicura. Non è stato possibile cancellare il file temporaneo';
							|pl = 'Pracuj w trybie awaryjnym.Nie można usunąć pliku tymczasowego';
							|tr = 'Güvenli modda çalışma.Geçici dosya silinemedi'", Common.DefaultLanguageCode()), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return New FixedMap(Result);
	
EndFunction

// Generates a reference by data from the permission registers.
//
// Parameters:
//  Type - CatalogRef.MetadataObjectIDs
//  Id - UUID - a reference UUID.
//
// Returns:
//   AnyRef
//
Function ReferenceFormPermissionRegister(Val Type, Val Id) Export
	
	If Type = Catalogs.MetadataObjectIDs.EmptyRef() Then
		Return Type;
	EndIf;
		
	MetadataObject = Common.MetadataObjectByID(Type);
	Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	Return ?(IsBlankString(Id), Manager.EmptyRef(), Manager.GetRef(Id));
	
EndFunction

#EndRegion

#Region PermissionRequestCreation

// Creates a request for changing permissions to use external resources.
// For internal use only.
//
// Parameters:
//  Owner - AnyRef - an owner of permissions to use external resources.
//    (Undefined when requesting permissions for the configuration, not for configuration objects).
//  Var_ReplacementMode - Boolean - replacement mode of permissions provided earlier for the permission owner.
//  PermissionsToAdd - Array of XDTODataObject - an array of XDTODataObjects that match internal details
//    of external resource access permissions to be requested. It is assumed that all XDTODataObjects passed
//    as parameters are generated using the SafeModeManager.Permission*() functions.
//  PermissionsToDelete - Array of XDTODataObject - an array of XDTODataObjects that match internal details
//    of external resource access permissions to be canceled. It is assumed that all XDTODataObjects passed
//    as parameters are generated using the SafeModeManager.Permission*() functions.
//  ProgramModule - AnyRef - a reference that matches the external module for which
//    permissions are being requested (Undefined if permissions are requested for configurations, not for external modules).
//
// Returns:
//   UUID - an ID of the created request.
//
Function PermissionChangeRequest(Val Owner, Val Var_ReplacementMode, Val PermissionsToAdd = Undefined, 
	Val PermissionsToDelete = Undefined, Val ProgramModule = Undefined) Export
	
	StandardProcessing = True;
	Result = Undefined;
	
	SSLSubsystemsIntegration.OnRequestPermissionsToUseExternalResources(
			ProgramModule, Owner, Var_ReplacementMode, PermissionsToAdd, PermissionsToDelete, StandardProcessing, Result);
	
	If StandardProcessing Then
		
		SafeModeManagerOverridable.OnRequestPermissionsToUseExternalResources(
			ProgramModule, Owner, Var_ReplacementMode, PermissionsToAdd, PermissionsToDelete, StandardProcessing, Result);
		
	EndIf;
	
	If StandardProcessing Then
		
		Result = InformationRegisters.RequestsForPermissionsToUseExternalResources.RequestToUsePermissions(
			ProgramModule, Owner, Var_ReplacementMode, PermissionsToAdd, PermissionsToDelete);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Creates a request to delete a security profile for the external module.
// For internal use only.
//
// Parameters:
//  ProgramModule - AnyRef - a reference that matches the external module for which
//    permissions are being requested (Undefined if permissions are requested for configurations, not for external modules).
//
// Returns:
//   UUID - an ID of the created request.
//
Function RequestToDeleteSecurityProfile(Val ProgramModule) Export
	
	StandardProcessing = True;
	Result = Undefined;
	Operation = Enums.SecurityProfileAdministrativeOperations.Delete;
	
	SSLSubsystemsIntegration.OnRequestToDeleteSecurityProfile(
			ProgramModule, StandardProcessing, Result);
	
	If StandardProcessing Then
		SafeModeManagerOverridable.OnRequestToDeleteSecurityProfile(
			ProgramModule, StandardProcessing, Result);
	EndIf;
	
	If StandardProcessing Then
		
		Result = InformationRegisters.RequestsForPermissionsToUseExternalResources.PermissionAdministrationRequest(
			ProgramModule, Operation);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Creates requests for application permission update.
//
// Parameters:
//  IncludingIBProfileCreationRequest - Boolean - include a request to create a security profile
//    for the current infobase to the result.
//
// Returns: 
//   Array of UUID - request IDs for updating the
//                                       configuration permissions to the currently required ones.
//
Function RequestsToUpdateApplicationPermissions(Val IncludingIBProfileCreationRequest = True) Export
	
	Result = New Array();
	
	BeginTransaction();
	Try
		If IncludingIBProfileCreationRequest Then
			Result.Add(RequestForSecurityProfileCreation(Catalogs.MetadataObjectIDs.EmptyRef()));
		EndIf;
		
		FillPermissionsToUpdatesProtectionCenter(Result);
		SSLSubsystemsIntegration.OnFillPermissionsToAccessExternalResources(Result);
		SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources(Result);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Result;
	
EndFunction

Procedure FillPermissionsToUpdatesProtectionCenter(PermissionsRequests)
	
	Resolution = SafeModeManager.PermissionToUseInternetResource("HTTPS", "1cv8update.com",, 
		NStr("vi = 'Trang web ""Trung tâm bảo vệ cập nhật"" (UPC) để xác minh tính hợp pháp của việc sử dụng và cập nhật sản phẩm phần mềm.';
			|ru = 'Сайт ""Центр защиты обновлений"" (ЦЗО) для проверки правомерности использования и обновления программного продукта.';
			|en = 'The ""Update protection center"" (UPC) site for checking legitimacy of the software usage and updating.'; fa = 'The ""Update protection center"" (UPC) site for checking legitimacy of the software usage and updating.';
			|it = 'Il sito ""Centro di Difesa degli aggiornamenti"" per la verifica della regolarità giuridica dell''utilizzo e per all''aggiornamento del software.';
			|pl = 'Witryna „Centrum ochrony aktualizacji” (COA) do celu sprawdzenia legalności użycia i aktualizacji oprogramowania.';
			|tr = 'Yazılım ürününü kullanmanın ve güncellemenin yasallığını kontrol etmek için ""Güncelleme Koruma Merkezi"" (GKM) web sitesi.'"));
	Permissions = New Array;
	Permissions.Add(Resolution);
	PermissionsRequests.Add(SafeModeManager.RequestToUseExternalResources(Permissions));

EndProcedure

#EndRegion

#Region Other

// Returns the module that is the external module manager.
//
// Parameters:
//  ExternalModule - AnyRef - a reference that matches the external module for which the manager is being requested.
//
// Returns:
//   CommonModule
//
Function ExternalModuleManager(Val ExternalModule) Export
	
	Managers = ExternalModulesManagers();
	For Each Manager In Managers Do
		ManagerContainers = Manager.ExternalModulesContainers();
		
		If TypeOf(ExternalModule) = Type("CatalogRef.MetadataObjectIDs") Then
			MetadataObject = Common.MetadataObjectByID(ExternalModule);
		Else
			MetadataObject = ExternalModule.Metadata();
		EndIf;
		
		If ManagerContainers.Find(MetadataObject) <> Undefined Then
			Return Manager;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Must be called when recording any internal data that cannot
// be changed in the safe mode.
//
Procedure OnSaveInternalData(Object) Export
	
	If SafeModeManager.SafeModeSet() Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cho phép ghi lại đối tượng %1: đã đặt chế độ an toàn: %2.';
				|ru = 'Запись объекта %1 недоступна: установлен безопасный режим: %2.';
				|en = 'Couldn''t save %1. Safe mode is set: %2.'; fa = 'Couldn''t save %1. Safe mode is set: %2.';
				|it = 'La registrazione dell''oggetto %1 non è disponibile: è stata stabilita una modalità sicura: %2.';
				|pl = 'Zapis obiektu %1 niedostępny: ustaw na tryb bezpieczny: %2.';
				|tr = '%1 nesnesi kaydedilemez: güvenli mod ayarlandı: %2.'"),
			Object.Metadata().FullName(),
			SafeMode());
		
	EndIf;
	
EndProcedure

// Checks whether the interactive permission request mode is required.
//
// Returns:
//   Boolean
//
Function InteractivePermissionRequestModeUsed()
	
	If SecurityProfilesUsageAvailable() Then
		
		Return GetFunctionalOption("UseSecurityProfiles") And Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Get();
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// Returns an array of the catalog managers that are external module containers.
//
// Returns:
//   Array of CatalogManager
//
Function ExternalModulesManagers()
	
	Managers = New Array;
	
	SSLSubsystemsIntegration.OnRegisterExternalModulesManagers(Managers);
	
	Return Managers;
	
EndFunction

#EndRegion

#Region ExternalResourcesPermissionsSetup

Procedure ExecuteRequestProcessing(Val RequestsIDs, Val TempStorageAddress,
			Val StateTemporaryStorageAddress, Val AddClearingRequestsBeforeApplying = False) Export
	
	DataProcessors.ExternalResourcesPermissionsSetup.ExecuteRequestProcessing(
		RequestsIDs,
		TempStorageAddress,
		StateTemporaryStorageAddress,
		AddClearingRequestsBeforeApplying);
	
EndProcedure

Procedure ExecuteUpdateRequestProcessing(Val TempStorageAddress,
			Val StateTemporaryStorageAddress) Export
	
	DataProcessors.ExternalResourcesPermissionsSetup.ExecuteUpdateRequestProcessing(
		TempStorageAddress, StateTemporaryStorageAddress);
	
EndProcedure

Procedure ExecuteDisableRequestProcessing(Val TempStorageAddress,
			Val StateTemporaryStorageAddress) Export
	
	DataProcessors.ExternalResourcesPermissionsSetup.ExecuteDisableRequestProcessing(
		TempStorageAddress, StateTemporaryStorageAddress);
	
EndProcedure

Procedure ExecuteRecoveryRequestProcessing(Val TempStorageAddress,
			Val StateTemporaryStorageAddress) Export
	
	DataProcessors.ExternalResourcesPermissionsSetup.ExecuteRecoveryRequestProcessing(
		TempStorageAddress, StateTemporaryStorageAddress);
	
EndProcedure

#EndRegion

#EndRegion