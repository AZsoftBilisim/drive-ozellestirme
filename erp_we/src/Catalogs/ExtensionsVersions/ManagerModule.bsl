///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(SessionParametersNames, SpecifiedParameters) Export

	If SessionParametersNames = Undefined Or SessionParametersNames.Find("InstalledExtensions") <> Undefined Then

		SessionParameters.InstalledExtensions = InstalledExtensions(True);
		SpecifiedParameters.Add("InstalledExtensions");
	EndIf;

	If SessionParametersNames = Undefined Or SessionParametersNames.Find("AttachedExtensions") <> Undefined Then

		Extensions = ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied);
		SessionParameters.AttachedExtensions = ExtensionsChecksums(Extensions, "SafeMode");
		SpecifiedParameters.Add("AttachedExtensions");
	EndIf;

	If SessionParametersNames <> Undefined And SessionParametersNames.Find("ExtensionsVersion") <> Undefined Then

		SessionParameters.ExtensionsVersion = ExtensionsVersion();
		SpecifiedParameters.Add("ExtensionsVersion");
	EndIf;

	If SessionParametersNames = Undefined And CurrentRunMode() <> Undefined Then

		RegisterExtensionsVersionUsage();
	EndIf;

EndProcedure

// Returns checksums for the main extensions
// and patches required for setting the InstalledExtensions session parameter
// and making further checks for changes.
// 
// It is called at the startup to set the InstalledExtensions session parameter,
// which is required to perform the extension availability check and to manage dynamic updates,
// and also from the configuration extensions setup form in 1C:Enterprise mode.
//
// Sessions without separators don't support extensions designed for shared sessions
// (service administrator tools).
//
// Returns:
//  FixedStructure:
//   * Main_    - String - a checksum of all extensions except for patch extensions.
//   * Corrections - String - a checksum of all patch extensions.
//
Function InstalledExtensions(OnStart = False) Export

	DatabaseExtensions = ConfigurationExtensions.Get();
	If OnStart Then
		ExtensionsOnStart = New Map;
		ActiveExtensions = ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied);
		For Each Extension In ActiveExtensions Do
			ExtensionsOnStart.Insert(ExtensionChecksum(Extension), Extension);
		EndDo;
		UnattachedExtensions = ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionDisabled);
		For Each Extension In UnattachedExtensions Do
			ExtensionsOnStart.Insert(ExtensionChecksum(Extension), Extension);
		EndDo;
		AllApplicabilityIssues = ConfigurationExtensions.GetSessionApplicationIssuesInformation();
		For Each ApplicabilityIssue In AllApplicabilityIssues Do
			Checksum = ExtensionChecksum(ApplicabilityIssue.Extension);
			If ExtensionsOnStart.Get(Checksum) = Undefined Then
				ExtensionsOnStart.Insert(Checksum, ApplicabilityIssue.Extension);
			EndIf;
		EndDo;
		AddedExtensions = New Map;
		Extensions = New Array;
		For Each Extension In DatabaseExtensions Do
			Checksum = ExtensionChecksum(Extension);
			ExtensionOnStart = ExtensionsOnStart.Get(Checksum);
			If ExtensionOnStart <> Undefined Then
				AddedExtensions.Insert(Checksum, True);
				Extensions.Add(ExtensionOnStart);
			EndIf;
		EndDo;
		For Each ExtensionDetails In ExtensionsOnStart Do
			If AddedExtensions.Get(ExtensionDetails.Key) = Undefined Then
				Extensions.Add(ExtensionDetails.Value);
			EndIf;
		EndDo;
	Else
		Extensions = DatabaseExtensions;
	EndIf;

	IndexOf = Extensions.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		Extension = Extensions.Get(IndexOf);
		If Base64String(Extension.HashSum) = "AAAAAAAAAAAAAAAAAAAAAAAAAAA=" Then
			Extensions.Delete(IndexOf);
		EndIf;
	EndDo;

	Main_    = New Array;
	Corrections = New Array;

	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleConfigurationUpdate = Common.CommonModule("ConfigurationUpdate");
	Else
		ModuleConfigurationUpdate = Undefined;
	EndIf;
	
	// Exclude the extensions for shared mode users as they are not attached in data areas
	// and cannot amend the configuration code (which is possible only by using the service administrator tools).
	// 
	SharedMode = Common.DataSeparationEnabled()
		And Not Common.SeparatedDataUsageAvailable();

	For Each Extension In Extensions Do
		If SharedMode And Extension.Scope = ConfigurationExtensionScope.DataSeparation Then
			Continue;
		EndIf;
		If ModuleConfigurationUpdate <> Undefined And ModuleConfigurationUpdate.IsPatch(Extension) Then
			Corrections.Add(Extension);
		Else
			Main_.Add(Extension);
		EndIf;
	EndDo;

	InstalledExtensions = New Structure;
	InstalledExtensions.Insert("Main_", ExtensionsChecksums(Main_));
	InstalledExtensions.Insert("Corrections", ExtensionsChecksums(Corrections));
	InstalledExtensions.Insert("MainState", ExtensionsChecksums(Main_, "All"));
	InstalledExtensions.Insert("PatchesState", ExtensionsChecksums(Corrections, "All"));

	If OnStart And ActiveExtensions.Count() = 0 And UnattachedExtensions.Count() = 0
		And DatabaseExtensions.Count() <> 0 And StandardSubsystemsServer.IsBaseConfigurationVersion() Then

		InstalledExtensions.Insert("ExtensionsUnavailable");
	EndIf;

	If OnStart Then
		SetTheInitialRegisteredState(InstalledExtensions, InstalledExtensions);
	EndIf;

	Return New FixedStructure(InstalledExtensions);

EndFunction

// For the TimeConsumingOperations.RunBackgroundJobWithClientContext function.
Procedure InsertARegisteredSetOfInstalledExtensions(Parameters) Export

	ExtensionsChangedDynamically();

	SetPrivilegedMode(True);
	InstalledExtensions = SessionParameters.InstalledExtensions;
	SetPrivilegedMode(False);

	Properties = New Structure;
	Properties.Insert("MainState", InstalledExtensions.BasicRegisteredStatus);
	Properties.Insert("PatchesState", InstalledExtensions.FixesRegisteredStatus);

	Parameters.Insert("RegisteredCompositionOfInstalledExtensions", Properties);

EndProcedure

// For the TimeConsumingOperations.ExecuteWithClientContext procedure.
Procedure RestoreTheRegisteredCompositionOfInstalledExtensions(Parameters) Export

	If Parameters.Property("RegisteredCompositionOfInstalledExtensions") Then
		SetTheInitialRegisteredState(
			Parameters.RegisteredCompositionOfInstalledExtensions);
	EndIf;

EndProcedure

// Returns:
//  FixedStructure
//
Function InstalledExtensionsOnStartup() Export

	Result = New Structure;
	Result.Insert("Main_", "");
	Result.Insert("Corrections", "");
	Result.Insert("MainState", "");
	Result.Insert("PatchesState", "");

	FillPropertyValues(Result, SessionParameters.InstalledExtensions);

	Return New FixedStructure(Result);

EndFunction

// Returns a flag that shows whether the extension content was changed after the session start.
// 
// Returns:
//  Boolean
//
Function ExtensionsChangedDynamically() Export

	SetPrivilegedMode(True);

	InstalledExtensions = InstalledExtensions();

	InstalledExtensionsOnStartup = InstalledExtensionsOnStartup();

	Unchanged = InstalledExtensionsOnStartup.Property("ExtensionsUnavailable")
		Or InstalledExtensionsOnStartup.MainState = InstalledExtensions.MainState
		And InstalledExtensionsOnStartup.PatchesState = InstalledExtensions.PatchesState;

	RegisterChangesToInstalledExtensions(InstalledExtensions, Unchanged);

	Return Not Unchanged;

EndFunction

// Returns information on changed extensions and corrections.
//
// Parameters:
//  InstalledExtensionsOnStartup - See InstalledExtensionsOnStartup
//                                    - Undefined - get for the current session.
//  IsCheckInCurrentSession - Boolean - Set to True if InstalledExtensionsOnStartup
//                                    are obtained in the current session.
//
// Returns:
//  Structure:
//     * Extensions - Structure:
//          * Added2 - Number
//          * Deleted   - Number
//     * Corrections - Structure:
//          * Added2 - Number
//          * Deleted   - Number
//
Function DynamicallyChangedExtensions(InstalledExtensionsOnStartup = Undefined,
	IsCheckInCurrentSession = False) Export

	Result = New Structure;
	Result.Insert("Extensions", Undefined);
	Result.Insert("Corrections", Undefined);

	SetPrivilegedMode(True);

	InstalledExtensions = InstalledExtensions();

	If InstalledExtensionsOnStartup = Undefined Then
		IsCheckInCurrentSession = True;
		InstalledExtensionsOnStartup = InstalledExtensionsOnStartup();
	EndIf;

	Unchanged = InstalledExtensionsOnStartup.Property("ExtensionsUnavailable")
		Or InstalledExtensionsOnStartup.MainState = InstalledExtensions.MainState
		And InstalledExtensionsOnStartup.PatchesState = InstalledExtensions.PatchesState;

	If IsCheckInCurrentSession Then
		RegisterChangesToInstalledExtensions(InstalledExtensions, Unchanged);
	EndIf;

	If Unchanged Then
		Return Result;
	EndIf;

	If InstalledExtensionsOnStartup.PatchesState <> InstalledExtensions.PatchesState Then
		Changes = ChangesInExtensionsComposition(InstalledExtensionsOnStartup.Corrections,
			InstalledExtensions.Corrections);
		Result.Corrections = Changes;
	EndIf;

	If InstalledExtensionsOnStartup.MainState <> InstalledExtensions.MainState Then
		Changes = ChangesInExtensionsComposition(InstalledExtensionsOnStartup.MainState,
			InstalledExtensions.MainState);
		Result.Extensions = Changes;
	EndIf;

	Return Result;

EndFunction

// Adds information that the session started using the metadata version.
Procedure RegisterExtensionsVersionUsage() Export

	If TransactionActive() Then
		Return;
	EndIf;

	If Not Common.SeparatedDataUsageAvailable() Then
		If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
			ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
			ModuleAccessManagementInternal.OnRegisterExtensionsVersionUsageInSharedSession();
		EndIf;
		Return;
	EndIf;

	ExtensionsVersion = ExtensionsVersion(True);
	SessionParameters.ExtensionsVersion = ExtensionsVersion;

	If Not ValueIsFilled(ExtensionsVersion) Then
		UpdateLatestExtensionsVersion(ExtensionsVersion);
		Return;
	EndIf;

	Query = RequestLastUsedDateCheck(ExtensionsVersion);
	If Query.Execute().IsEmpty() Then
		UpdateLatestExtensionsVersion(ExtensionsVersion);
		Return;
	EndIf;
	
	If Common.FileInfobase() Or ExclusiveMode() Then
		UpdateExtensionsVersionLastUsedDate(ExtensionsVersion);
		UpdateLatestExtensionsVersion(ExtensionsVersion);
		Return;
	EndIf;
	
	UpdateLatestExtensionsVersion(ExtensionsVersion);
	
	ProcedureName = "StandardSubsystemsServer.UpdateExtensionsVersionLastUsedDate";
	Filter = New Structure("MethodName, State", ProcedureName, BackgroundJobState.Active);
	VersionAsString = Lower(ExtensionsVersion.UUID());
	
	FoundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	For Each FoundJob In FoundJobs Do
		If StrFind(FoundJob.Description, VersionAsString) > 0 Then
			Return;
		EndIf;
	EndDo;
	
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Phiên bản phần mở rộng: Cập nhật ngày sử dụng gần nhất %1';
			|ru = 'Версии расширений: Обновление даты последнего использования %1';
			|en = 'Extension versions: Update the last used date for %1'; fa = 'Extension versions: Update the last used date for %1';
			|it = 'Версии расширений: Обновление даты последнего использования %1';
			|pl = 'Extension versions: Update the last used date for %1';
			|tr = 'Eklenti sürümleri: %1 son kullanım tarihini güncelle'",
			Common.DefaultLanguageCode()),
		VersionAsString);
	
	JobParameters = CommonClientServer.ValueInArray(ExtensionsVersion);
	
	// The procedure name must be as specified in the ProcedureName variable.
	BackgroundJobs.Execute("StandardSubsystemsServer.UpdateExtensionsVersionLastUsedDate",
		JobParameters,, JobDescription);
	
EndProcedure

// Returns:
//  Structure:
//    * ExtensionsVersion - CatalogRef.ExtensionsVersions
//                       - Undefined
//    * UpdateDate - Date
//    * UpdateID - UUID
//
Function LastExtensionsVersion() Export
	
	ParameterName = "StandardSubsystems.Core.LastExtensionsVersion";
	StoredProperties = StandardSubsystemsServer.ExtensionParameter(ParameterName, True);
	
	NewStoredProperties = NewStoredPropertiesOfExtensionsVersion();
	
	If TypeOf(StoredProperties) = Type("Structure") Then
		For Each KeyAndValue In NewStoredProperties Do
			If StoredProperties.Property(KeyAndValue.Key)
			   And TypeOf(StoredProperties[KeyAndValue.Key]) = TypeOf(KeyAndValue.Value) Then
				Continue;
			EndIf;
			StoredProperties = Undefined;
			Break;
		EndDo;
	EndIf;
	
	If TypeOf(StoredProperties) = Type("Structure") Then
		Return StoredProperties;
	EndIf;
	
	NewStoredProperties.ExtensionsVersion = Undefined;
	
	Return NewStoredProperties;
	
EndFunction

// Deletes obsolete metadata versions.
Procedure DeleteObsoleteParametersVersions() Export

	OtherVersion = OtherExtensionsVersion();

	If Not ValueIsFilled(OtherVersion) Then
		DisableScheduledJobIfRequired();
		Return;
	EndIf;

	ApplicationsToCheck = New Map;
	ApplicationsToCheck.Insert("1CV8", True);
	ApplicationsToCheck.Insert("1CV8C", True);
	ApplicationsToCheck.Insert("WebClient", True);
	ApplicationsToCheck.Insert("COMConnection", True);
	ApplicationsToCheck.Insert("WSConnection", True);
	ApplicationsToCheck.Insert("BackgroundJob", True);
	ApplicationsToCheck.Insert("SystemBackgroundJob", True);

	SessionsArray = GetInfoBaseSessions();
	MinSessionStartDate = GetCurrentInfoBaseSession().SessionStarted;

	For Each Session In SessionsArray Do
		If Session.SessionStarted >= MinSessionStartDate
			Or ApplicationsToCheck.Get(Session.ApplicationName) = Undefined Then
			Continue;
		EndIf;
		MinSessionStartDate = Session.SessionStarted;
	EndDo;
	MinSessionStartDate = RoundedSessionStartDate(MinSessionStartDate);
	MinSessionStartDate = MinSessionStartDate - 24*60*60;
	
	// Obsolete extension version mark.
	While True Do
		OtherVersion = OtherExtensionsVersion(MinSessionStartDate);
		If Not ValueIsFilled(OtherVersion) Then
			Break;
		EndIf;

		Block = New DataLock;
		LockItem = Block.Add("Catalog.ExtensionsVersions");
		LockItem.SetValue("Ref", OtherVersion);

		BeginTransaction();
		Try
			Block.Lock();
			Object = ServiceItem(OtherVersion);

			If Object <> Undefined And Object.DateOfLastUse < MinSessionStartDate Then

				Object.DeletionMark = True;
				Object.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;

	DisableScheduledJobIfRequired();

EndProcedure

// Enables and disables the DeleteObsoleteExtensionsVersionsParameters scheduled job.
Procedure EnableDeleteObsoleteExtensionsVersionsParametersJob(Enable) Export

	ScheduledJobsServer.SetPredefinedScheduledJobUsage(
		Metadata.ScheduledJobs.DeleteObsoleteExtensionsVersionsParameters, Enable);

EndProcedure

// For common forms Extensions and InstalledPatches.
//
Procedure ToggleExtensionUsage(ExtensionID, CurrentUsage) Export

	Extension = FindExtension(ExtensionID);

	If Extension = Undefined Or Extension.Active = CurrentUsage Then

		Return;
	EndIf;

	Extension.Active = CurrentUsage;
	DisableSecurityWarnings(Extension);
	DisableMainRolesUsageForAllUsers(Extension);
	Try
		Extension.Write();
	Except
		Raise;
	EndTry;

	Try
		InformationRegisters.ExtensionVersionParameters.UpdateExtensionParameters();
	Except
		ErrorInfo = ErrorInfo();
		If Extension.Active Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xảy ra tình huống không mong muốn khi chuẩn bị phần mở rộng để làm việc (sau khi bật phần mở rộng):
					 |%1';
					 |ru = 'Возникла непредвиденная ситуация при подготовке расширений к работе (после включения расширения):
					 |%1';
					 |en = 'An unexpected error occurred while preparing the extensions (after enabling the extension):
					 |%1'; fa = 'An unexpected error occurred while preparing the extensions (after enabling the extension):
					 |%1';
					 |it = 'Возникла непредвиденная ситуация при подготовке расширений к работе (после включения расширения):
					 |%1';
					 |pl = 'An unexpected error occurred while preparing the extensions (after enabling the extension):
					 |%1';
					 |tr = 'Uzantıları işlem için hazırlarken beklenmedik bir durum yaşandı (uzantıların etkinleştirilmelerinden sonra):
					 |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xảy ra tình huống không mong muốn khi chuẩn bị phần mở rộng để làm việc (sau khi tắt phần mở rộng):
					 |%1';
					 |ru = 'Возникла непредвиденная ситуация при подготовке расширений к работе (после отключения расширения):
					 |%1';
					 |en = 'An unexpected error occurred while preparing the extensions (after disabling the extension):
					 |%1'; fa = 'An unexpected error occurred while preparing the extensions (after disabling the extension):
					 |%1';
					 |it = 'Возникла непредвиденная ситуация при подготовке расширений к работе (после отключения расширения):
					 |%1';
					 |pl = 'An unexpected error occurred while preparing the extensions (after disabling the extension):
					 |%1';
					 |tr = 'Uzantıları işlem için hazırlarken beklenmedik bir durum yaşandı (uzantıların etkinleştirilmelerinden sonra):
					 |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndIf;
	EndTry;

	If ValueIsFilled(ErrorText) Then
		RecoveryErrorInformation = Undefined;
		Try
			Extension.Active = Not Extension.Active;
			Extension.Write();
		Except
			RecoveryErrorInformation = ErrorInfo();
			ErrorText = ErrorText + Chars.LF + Chars.LF
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã xảy ra tình huống không mong muốn khi thử hủy thay đổi hộp kiểm kết nối phần mở rộng:
						 |%1';
						 |ru = 'Возникла непредвиденная ситуация при попытке отменить изменение флажка подключения расширения:
						 |%1';
						 |en = 'An unexpected error occurred when trying to cancel the change of the extension attachment check box:
						 |%1'; fa = 'An unexpected error occurred when trying to cancel the change of the extension attachment check box:
						 |%1';
						 |it = 'Возникла непредвиденная ситуация при попытке отменить изменение флажка подключения расширения:
						 |%1';
						 |pl = 'An unexpected error occurred when trying to cancel the change of the extension attachment check box:
						 |%1';
						 |tr = 'Uzantıya bağlanma işareti denemesinde beklenmedik bir durum yaşandı:
						 |%1'"), ErrorProcessing.BriefErrorDescription(RecoveryErrorInformation));
		EndTry;
		If RecoveryErrorInformation = Undefined Then
			ErrorText = ErrorText + Chars.LF + Chars.LF
				+ NStr("vi = 'Đã hủy thay đổi hộp kiểm kết nối phần mở rộng.';
						|ru = 'Отменено изменение флажка подключения расширения.';
						|en = 'The change of the ""Attached"" extension parameter is canceled.'; fa = 'The change of the ""Attached"" extension parameter is canceled.';
						|it = 'La modifica del flag di attivazione dell''estensione è annullata.';
						|pl = 'Anulowano zmianę pola podłączenia rozszerzenia.';
						|tr = 'Uzantı bağlantı onay kutusundaki değişiklik iptal edildi.'");
		EndIf;
	EndIf;

	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;

EndProcedure

// For common forms Extensions and InstalledPatches.
//
// Returns:
//  ConfigurationExtension
//  Undefined
//
Function FindExtension(ExtensionID) Export

	Filter = New Structure;
	Filter.Insert("UUID", New UUID(ExtensionID));
	Extensions = ConfigurationExtensions.Get(Filter);

	Extension = Undefined;

	If Extensions.Count() = 1 Then
		Extension = Extensions[0];
	EndIf;

	Return Extension;

EndFunction

// For common forms Extensions and InstalledPatches.
// 
// Parameters:
//  Extension - ConfigurationExtension
//
Procedure DisableSecurityWarnings(Extension) Export

	Extension.UnsafeActionProtection = Common.ProtectionWithoutWarningsDetails();

EndProcedure

// For common forms Extensions and InstalledPatches.
Procedure DisableMainRolesUsageForAllUsers(Extension) Export

	Extension.UseDefaultRolesForAllUsers = False;

EndProcedure

// For common forms Extensions and InstalledPatches.
Procedure DeleteExtensions(ExtensionsIDs, ErrorText) Export

	ExtensionsToDelete = New Array;

	ErrorText = "";
	Try
		ExtensionToDelete = "";
		For Each ExtensionID In ExtensionsIDs Do
			Extension = FindExtension(ExtensionID);
			If Extension <> Undefined Then
				ExtensionDetails = New Structure;
				ExtensionDetails.Insert("Deleted", False);
				ExtensionDetails.Insert("Extension", Extension);
				ExtensionDetails.Insert("ExtensionData", Extension.GetData());
				ExtensionsToDelete.Add(ExtensionDetails);
			EndIf;
		EndDo;
		IndexOf = ExtensionsToDelete.Count() - 1;
		While IndexOf >= 0 Do
			ExtensionDetails = ExtensionsToDelete[IndexOf];
			DisableSecurityWarnings(ExtensionDetails.Extension);
			DisableMainRolesUsageForAllUsers(ExtensionDetails.Extension);
			ExtensionToDelete = ExtensionDetails.Extension.Synonym;
			ExtensionToDelete = ?(ExtensionToDelete = "", ExtensionDetails.Extension.Name, ExtensionToDelete);
			ExtensionDetails.Extension.Delete();
			ExtensionToDelete = "";
			ExtensionDetails.Deleted = True;
			IndexOf = IndexOf - 1;
		EndDo;
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xóa tiện ích mở rộng ""%1"" do nguyên nhân: 
				 |%2';
				 |ru = 'Не удалось удалить расширение ""%1"" по причине:
				 |%2';
				 |en = 'Cannot delete extension ""%1"". Reason:
				 |%2'; fa = 'Cannot delete extension ""%1"". Reason:
				 |%2';
				 |it = 'Non è stato possibile eliminare l''estensione ""%1"" a causa di:
				 |%2';
				 |pl = 'Nie udało się usunąć rozszerzenie ""%1"" z powodu:
				 |%2';
				 |tr = '""%1"" uzantısı 
				 |%2 nedeniyle silinemedi'"), 
			ExtensionToDelete, ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;

	If Not ValueIsFilled(ErrorText) Then
		Try
			If Common.SeparatedDataUsageAvailable()
				And ConfigurationExtensions.Get().Count() = 0 Then

				EnableDeleteObsoleteExtensionsVersionsParametersJob(True);
			EndIf;
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sau khi xóa, trong khi xử lý trường hợp xóa tất cả phần mở rộng, đã xảy ra lỗi:
					 |%1';
					 |ru = 'После удаления, при обработке случая удаления всех расширений, произошла ошибка:
					 |%1';
					 |en = 'After the deletion, an error occurred in the handler of deletion of all extensions:
					 |%1'; fa = 'After the deletion, an error occurred in the handler of deletion of all extensions:
					 |%1';
					 |it = 'Dopo l''eliminazione durante l''elaborazione del caso di eliminazione di tutte le estensioni si è verificato l''errore:
					 |%1';
					 |pl = 'Po usunięciu, podczas przetwarzania wszystkich rozszerzeń, wystąpił błąd:
					 |%1';
					 |tr = 'Silme işleminden sonra, tüm uzantıların silinmesi durumu işlenirken bir hata oluştu:
					 |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndTry;
	EndIf;

	If Not ValueIsFilled(ErrorText) Then
		Try
			InformationRegisters.ExtensionVersionParameters.UpdateExtensionParameters();
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sau khi xóa, trong khi chuẩn bị cho các phần mở rộng còn lại hoạt động, đã xảy ra lỗi:
					 |%1';
					 |ru = 'После удаления, при подготовке оставшихся расширений к работе, произошла ошибка:
					 |%1';
					 |en = 'After the deletion, an error occurred while initializing the remaining extensions:
					 |%1'; fa = 'After the deletion, an error occurred while initializing the remaining extensions:
					 |%1';
					 |it = 'Dopo l''eliminazione, durante la preparazione delle estensioni rimanenti al lavoro, si è verificato un errore:
					 |%1';
					 |pl = 'Po usunięciu, podczas przygotowania pozostałych rozszerzeń do pracy, zaistniał błąd:
					 |%1';
					 |tr = 'Silindikten sonra, kalan uzantıları çalışma için hazırlarken bir hata oluştu:
					 |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndTry;
	EndIf;

	If ValueIsFilled(ErrorText) Then
		RecoveryErrorInformation = Undefined;
		RecoveryPerformed = False;
		Try
			For Each ExtensionDetails In ExtensionsToDelete Do
				If Not ExtensionDetails.Deleted Then
					Continue;
				EndIf;
				ExtensionDetails.Extension.Write(ExtensionDetails.ExtensionData);
				RecoveryPerformed = True;
			EndDo;
		Except
			RecoveryErrorInformation = ErrorInfo();
			ErrorText = ErrorText + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi thử khôi phục các phần mở rộng bị xóa, đã xảy ra một lỗi:
						 |%1';
						 |ru = 'При попытке восстановить удаленные расширения произошла еще одна ошибка:
						 |%1';
						 |en = 'Another error occurred while attempting to restore the deleted extensions:
						 |%1'; fa = 'Another error occurred while attempting to restore the deleted extensions:
						 |%1';
						 |it = 'Durante il tentativo di ripristinare le estensioni eliminate, si è verificato un altro errore:
						 |%1';
						 |pl = 'Podczas próby odzyskania usuniętych rozszerzeń zaistniał jeszcze jeden błąd:
						 |%1';
						 |tr = 'Silinmiş uzantıları geri yüklemeye çalışırken bir hata daha oluştu: 
						 |%1'"), 
					ErrorProcessing.BriefErrorDescription(RecoveryErrorInformation));
		EndTry;
		If RecoveryPerformed And RecoveryErrorInformation = Undefined Then

			ErrorText = ErrorText + Chars.LF + Chars.LF 
				+ NStr("vi = 'Đã khôi phục các phần mở rộng bị xóa.';
						|ru = 'Удаленные расширения были восстановлены.';
						|en = 'The deleted extensions are restored.'; fa = 'The deleted extensions are restored.';
						|it = 'Le estensioni eliminate sono state ripristinate.';
						|pl = 'Usunięte rozszerzenia zostały odzyskane.';
						|tr = 'Silinmiş uzantılar geri yüklendi.'");
		EndIf;
	EndIf;

EndProcedure

// For common forms Extensions and InstalledPatches.
//
// Returns:
//  Array of UUID
//
Function RequestsToRevokeExternalModuleUsagePermissions(ExtensionsIDs) Export

	Queries = New Array;

	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	If Not ModuleSafeModeManager.UseSecurityProfiles() Then
		Return Queries;
	EndIf;

	Permissions = New Array;

	For Each ExtensionID In ExtensionsIDs Do
		CurrentExtension = FindExtension(ExtensionID);
		Permissions.Add(ModuleSafeModeManager.PermissionToUseExternalModule(
			CurrentExtension.Name, Base64String(CurrentExtension.HashSum)));
	EndDo;

	Queries.Add(ModuleSafeModeManager.RequestToCancelPermissionsToUseExternalResources(
		Common.MetadataObjectID("InformationRegister.ExtensionVersionParameters"), Permissions));

	Return Queries;

EndFunction

// Returns:
//  Boolean
//
Function AllExtensionsConnected() Export

	SetPrivilegedMode(True);

	Numberofextensions = ConfigurationExtensions.Get().Count();
	NumberofConnectedExtensions = ConfigurationExtensions.Get(,
		ConfigurationExtensionsSource.SessionApplied).Count();

	Return Numberofextensions = NumberofConnectedExtensions;

EndFunction

// Returns:
//  Date - Universal timestamp received at the first function call in this session.
//         Different machines have different timestamps, which affects the result.
//         
//
Function SessionRealtimeTimestamp() Export

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);

	If Not SessionParameters.InstalledExtensions.Property("SessionRealtimeTimestamp") Then
		InstalledExtensions = New Structure(SessionParameters.InstalledExtensions);
		InstalledExtensions.Insert("SessionRealtimeTimestamp",
			GetCurrentInfoBaseSession().SessionStarted - StandardTimeOffset());
		SessionParameters.InstalledExtensions = New FixedStructure(InstalledExtensions);
	EndIf;
	Timestamp1 = SessionParameters.InstalledExtensions.SessionRealtimeTimestamp;

	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);

	Return Timestamp1;

EndFunction

#EndRegion

#Region Private

// Returns the checksums of the specified extensions.
//
// Parameters:
//  Extensions - Array - the extensions.
//  ConsiderExtencionsState - Boolean - consider the Active and SafeMode flags.
//
// Returns:
//  String - Strings in the following format: "<Extension name> (<Version>) <Hashsum>".
//
Function ExtensionsChecksums(Extensions, AttachmentProperties1 = "", IncludingConfiguration = True)

	List = New ValueList;

	For Each Extension In Extensions Do
		List.Add(ExtensionChecksum(Extension, AttachmentProperties1));
	EndDo;

	If IncludingConfiguration And List.Count() <> 0 Then
		Checksum = "#" + Metadata.Name + " (" + Metadata.Version + ")";
		List.Add(Checksum);
	EndIf;

	Checksums = "";
	For Each Item In List Do
		Checksums = Checksums + Chars.LF + Item.Value;
	EndDo;

	Return TrimL(Checksums);

EndFunction

// For functions ExtensionsChecksums and InstalledExtensions.
Function ExtensionChecksum(Extension, AttachmentProperties1 = "")

	Checksum = Extension.Name + " (" + Extension.Version + ") " + Base64String(Extension.HashSum);

	If ValueIsFilled(AttachmentProperties1) Then
		Checksum = Checksum + " SafeMode:"
			+ ?(TypeOf(Extension.SafeMode) = Type("Boolean"),
				?(Extension.SafeMode, "Yes", "None"),
				"{" + String(Extension.SafeMode) + "}");
	EndIf;

	If AttachmentProperties1 = "All" Then
		Checksum = Checksum + " PassToSubordinateDIBNodes:" 
			+ ?(Extension.UsedInDistributedInfoBase, "Yes", "None") + " Active:" 
			+ ?(Extension.Active, "Yes", "None");
	EndIf;

	Return Checksum;

EndFunction

// Returns the current extension version.
// The search for a version is based on details of the attached extensions.
//
Function ExtensionsVersion(OnRegisterExtensionsVersionsUsage = False)

	If Not Common.SeparatedDataUsageAvailable() Then
		Return EmptyRef();
	EndIf;

	ExtensionsDetails = SessionParameters.AttachedExtensions;
	If Not ValueIsFilled(ExtensionsDetails) Then
		Return EmptyRef();
	EndIf;

	If Not TransactionActive() Or Not Common.FileInfobase() Then
		Query = RequestExtensionsActiveVersions();
		Selection = Query.Execute().Select();
		If VersionFound(Selection, ExtensionsDetails) Then
			Return Selection.Ref;
		EndIf;
	EndIf;
	
	If Common.FileInfobase() Or ExclusiveMode() Then
		ExtensionsVersion = Undefined;
		AddNewExtensionVersion(ExtensionsDetails, ExtensionsVersion);
		Return ExtensionsVersion;
	EndIf;
	
	ProcedureName = "StandardSubsystemsServer.AddNewExtensionVersion";
	Filter = New Structure("MethodName, State", ProcedureName, BackgroundJobState.Active);
	
	Hashing = New DataHashing(HashFunction.SHA512);
	Hashing.Append(ExtensionsDetails);
	HashSumAsStr = Base64String(Hashing.HashSum);
	
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Phiên bản phần mở rộng: Thêm phiên bản mới %1';
			|ru = 'Версии расширений: Добавление новой версии %1';
			|en = 'Extension versions: Add a new version of %1'; fa = 'Extension versions: Add a new version of %1';
			|it = 'Версии расширений: Добавление новой версии %1';
			|pl = 'Extension versions: Add a new version of %1';
			|tr = 'Eklenti sürümü: Yeni %1 sürümünün eklenmesi'",
			Common.DefaultLanguageCode()),
		HashSumAsStr);
	
	JobParameters = CommonClientServer.ValueInArray(ExtensionsDetails);
	TaskIds = New Map;
	
	AttemptNumber = 1;
	While AttemptNumber <= 3 Do
		FoundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
		IndexOf = FoundJobs.UBound();
		While IndexOf >= 0 Do
			FoundJob = FoundJobs[IndexOf];
			If StrFind(FoundJob.Description, HashSumAsStr) = 0 Then
				FoundJobs.Delete(IndexOf);
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
		
		// @skip-check query-in-loop - At each iteration, you need to download up-to-date data from the information security.
		Selection = Query.Execute().Select();
		If VersionFound(Selection, ExtensionsDetails) Then
			If Not OnRegisterExtensionsVersionsUsage Then
				UpdateLatestExtensionsVersion(Selection.Ref);
			EndIf;
			Return Selection.Ref;
		EndIf;
		
		If Not ValueIsFilled(FoundJobs) Then
			// The procedure name must be as specified in the ProcedureName variable.
			BackgroundJob = BackgroundJobs.Execute("StandardSubsystemsServer.AddNewExtensionVersion",
				JobParameters,, JobDescription);
			FoundJobs.Add(BackgroundJob);
		EndIf;
		
		BackgroundJobs.WaitForExecutionCompletion(FoundJobs, 15);
		For Each FoundJob In FoundJobs Do
			TaskIds.Insert(FoundJob.UUID);
		EndDo;
		
		// @skip-check query-in-loop - At each iteration, you need to download up-to-date data from the information security.
		Selection = Query.Execute().Select();
		If VersionFound(Selection, ExtensionsDetails) Then
			If Not OnRegisterExtensionsVersionsUsage Then
				UpdateLatestExtensionsVersion(Selection.Ref);
			EndIf;
			Return Selection.Ref;
		EndIf;
		
		AttemptNumber = AttemptNumber + 1;
	EndDo;
	
	ErrorText = NStr("vi = 'Hãy thử khởi động lại phiên.';
					|ru = 'Попробуйте перезапустить сеанс.';
					|en = 'Try to restart the session.'; fa = 'Try to restart the session.';
					|it = 'Попробуйте перезапустить сеанс.';
					|pl = 'Try to restart the session.';
					|tr = 'Oturumu yeniden başlatmayı deneyin.'");
	ClarificationForAdmin = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể tạo phiên bản mới của phần mở rộng.
		           |1. Mô tả metadata:
		           |%1
		           |2. Giá trị băm mô tả metadata:
		           |%2
		           |3. Mô tả nhiệm vụ:';
		           |ru = 'Не удалось создать новую версию расширений.
		           |1. Описание метаданных:
		           |%1
		           |2. Хеш-сумма описания метаданных:
		           |%2
		           |3. Описание заданий:';
		           |en = 'Failed to create a new extension version.
		           |• Metadata details:
		           |%1
		           |• Metadata objects'' details checksum:
		           |%2
		           |• Job details:'; fa = 'Failed to create a new extension version.
		           |• Metadata details:
		           |%1
		           |• Metadata objects'' details checksum:
		           |%2
		           |• Job details:';
		           |it = 'Не удалось создать новую версию расширений.
		           |1. Описание метаданных:
		           |%1
		           |2. Хеш-сумма описания метаданных:
		           |%2
		           |3. Описание заданий:';
		           |pl = 'Failed to create a new extension version.
		           |• Metadata details:
		           |%1
		           |• Metadata objects'' details checksum:
		           |%2
		           |• Job details:';
		           |tr = 'Uzantıların yeni bir sürümü oluşturulamadı. 
		           |1. Meta veri açıklaması: 
		           |%1
		           |2. Meta veri açıklamasının önbellek toplamı: 
		           |%2
		           |3. İş tanımı:'"),
		ExtensionsDetails,
		HashSumAsStr);
	
	ClarificationForAdmin = ClarificationForAdmin
		+ Chars.LF + JobStatesDetails(TaskIds);
	
	Raise(ErrorText,,, ClarificationForAdmin);
	
EndFunction

// For the ExtensionsVersion function.
Function JobStatesDetails(TaskIds)
	
	TaskDescription_ = New ValueList;
	
	For Each KeyAndValue In TaskIds Do
		BackgroundJob = BackgroundJobs.FindByUUID(KeyAndValue.Key);
		If BackgroundJob = Undefined Then
			Continue;
		EndIf;
		
		If BackgroundJob.State = BackgroundJobState.Active Then
			JobDetails = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Nhiệm vụ %1 được thực hiện từ %2';
					|ru = 'Задание %1 выполняется с %2';
					|en = 'Job %1 started %2'; fa = 'Job %1 started %2';
					|it = 'Задание %1 выполняется с %2';
					|pl = 'Job %1 started %2';
					|tr = '%2 ile %1 görevi tamamlandı'"),
				Lower(BackgroundJob.UUID),
				Format(BackgroundJob.Begin, "DLF=DT"));
			
		ElsIf BackgroundJob.State = BackgroundJobState.Canceled Then
			JobDetails = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Nhiệm vụ %1 từ %2 bị hủy bỏ %3';
					|ru = 'Задание %1 с %2 отменено %3';
					|en = 'Job %1 started %2 canceled %3'; fa = 'Job %1 started %2 canceled %3';
					|it = 'Задание %1 с %2 отменено %3';
					|pl = 'Job %1 started %2 canceled %3';
					|tr = '%2 ile %1 görevi iptal edildi %3'"),
				Lower(BackgroundJob.UUID),
				Format(BackgroundJob.Begin, "DLF=DT"),
				Format(BackgroundJob.End, "DLF=DT"));
			
		ElsIf BackgroundJob.State = BackgroundJobState.Completed Then
			JobDetails = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Nhiệm vụ %1 từ %2 đã kết thúc %3';
					|ru = 'Задание %1 с %2 завершено %3';
					|en = 'Job %1 started %2 completed %3'; fa = 'Job %1 started %2 completed %3';
					|it = 'Задание %1 с %2 завершено %3';
					|pl = 'Job %1 started %2 completed %3';
					|tr = '%2 ile %1 görevi tamamlandı %3'"),
				Lower(BackgroundJob.UUID),
				Format(BackgroundJob.Begin, "DLF=DT"),
				Format(BackgroundJob.End, "DLF=DT"));
			
		ElsIf BackgroundJob.State = BackgroundJobState.Failed Then
			JobDetails = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Nhiệm vụ %1 từ %2 đã kết thúc %3 với lỗi:
				           |%4';
				           |ru = 'Задание %1 с %2 завершено %3 с ошибкой:
				           |%4';
				           |en = 'Job %1 started %2 completed %3 with error:
				           |%4'; fa = 'Job %1 started %2 completed %3 with error:
				           |%4';
				           |it = 'Задание %1 с %2 завершено %3 с ошибкой:
				           |%4';
				           |pl = 'Job %1 started %2 completed %3 with error:
				           |%4';
				           |tr = '%1 ila %2 görevi %3 olarak şu hatalarla sonuçlandı:
				           |%4'"),
				Lower(BackgroundJob.UUID),
				Format(BackgroundJob.Begin, "DLF=DT"),
				Format(BackgroundJob.End, "DLF=DT"),
				?(TypeOf(BackgroundJob.ErrorInfo) = Type("ErrorInfo"),
					ErrorProcessing.DetailErrorDescription(BackgroundJob.ErrorInfo), ""));
		EndIf;
		TaskDescription_.Add(JobDetails, XMLString(BackgroundJob.Begin));
	EndDo;
	
	TaskDescription_.SortByPresentation();
	
	Return StrConcat(TaskDescription_.UnloadValues(), Chars.LF
		+ "----------------------------------" + Chars.LF) + Chars.LF
		+ "----------------------------------";
	
EndFunction

// For the ExtensionsVersion function.
Procedure AddNewExtensionVersion(ExtensionsDetails, ExtensionsVersion = Undefined) Export
	
	Query = RequestExtensionsActiveVersions();
	
	// If another user is creating an extension version,
	// wait till they finish to avoid exclusive locks.
	Block = New DataLock;
	LockItem = Block.Add("Catalog.ExtensionsVersions");
	LockItem.SetValue("Ref", FlagOfAddingNewVersion());
	LockItem.Mode = DataLockMode.Shared;
	BeginTransaction();
	Try
		Block.Lock();
		Selection = Query.Execute().Select();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

	If VersionFound(Selection, ExtensionsDetails) Then
		ExtensionsVersion = Selection.Ref;
	Else
		// Create an extensions version.
		RoundedSessionStartDate = RoundedSessionStartDate();
		Block = New DataLock;
		LockItem = Block.Add("Catalog.ExtensionsVersions");
		LockItem.SetValue("Ref", FlagOfAddingNewVersion());
		BeginTransaction();
		Try
			Block.Lock();
			// Double check that the version is not yet created
			// (which is unlikely but possible in between transactions).
			QueryResult = Query.Execute();
			Selection = QueryResult.Select();
			If VersionFound(Selection, ExtensionsDetails) Then
				ExtensionsVersion = Selection.Ref;
			Else
				Object = ServiceItem();
				Object.MetadataDetails = ExtensionsDetails;
				Object.DateOfLastUse = RoundedSessionStartDate;
				Object.Write();
				If Selection.Count() = 1 Then
					EnableDeleteObsoleteExtensionsVersionsParametersJob(True);
				EndIf;
				ExtensionsVersion = Object.Ref;
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

// For the ExtensionsVersion function and the AddNewExtensionVersion procedure.
Function RequestExtensionsActiveVersions()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ExtensionsVersions.Ref AS Ref,
	|	ExtensionsVersions.MetadataDetails AS ExtensionsDetails
	|FROM
	|	Catalog.ExtensionsVersions AS ExtensionsVersions
	|WHERE
	|	NOT ExtensionsVersions.DeletionMark";
	
	Return Query;
	
EndFunction

// For the ExtensionsVersion function.
Function VersionFound(Selection, ExtensionsDetails)

	While Selection.Next() Do
		If Selection.ExtensionsDetails = ExtensionsDetails Then
			Return True;
		EndIf;
	EndDo;

	Return False;

EndFunction

// For the ExtensionsVersion function.
Function FlagOfAddingNewVersion()

	Return Catalogs.ExtensionsVersions.GetRef(
		New UUID("61ce6265-abb2-11ea-87d6-b06ebfbf08c7"));

EndFunction

// For the ExtensionsVersion function and the DeleteObsoleteParametersVersions,
// RegisterExtensionsVersionUsage procedures.
//
Function RoundedSessionStartDate(SessionStarted = '00010101')

	If ValueIsFilled(SessionStarted) Then
		Return BegOfHour(SessionStarted);
	EndIf;

	Return BegOfHour(GetCurrentInfoBaseSession().SessionStarted);

EndFunction

// For the ExtensionsVersion function and the DeleteObsoleteParametersVersions,
// RegisterExtensionsVersionUsage procedures.
//
Function ServiceItem(Ref = Undefined)

	If Ref = Undefined Then
		CatalogItem = CreateItem();
		Query = New Query;
		Query.Text =
		"SELECT
		|	ISNULL(MAX(ExtensionsVersions.Code), 0) AS MaxNumber
		|FROM
		|	Catalog.ExtensionsVersions AS ExtensionsVersions";
		Selection = Query.Execute().Select();
		CatalogItem.Code = ?(Selection.Next(), Selection.MaxNumber, 0) + 1;
	Else
		CatalogItem = Ref.GetObject();
		If CatalogItem = Undefined Then
			Return Undefined;
		EndIf;
	EndIf;

	CatalogItem.AdditionalProperties.Insert("DontControlObjectsToDelete");
	CatalogItem.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	CatalogItem.DataExchange.Recipients.AutoFill = False;
	CatalogItem.DataExchange.Load = True;

	Return CatalogItem;

EndFunction

// This method is required by DeleteObsoleteParametersVersions procedure.
Function OtherExtensionsVersion(MinSessionStartDate = '39991231')

	Query = New Query;
	Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
	Query.SetParameter("MinSessionStartDate", MinSessionStartDate);
	Query.Text =
	"SELECT TOP 1
	|	ExtensionsVersions.Ref AS Ref
	|FROM
	|	Catalog.ExtensionsVersions AS ExtensionsVersions
	|WHERE
	|	ExtensionsVersions.Ref <> &ExtensionsVersion
	|	AND ExtensionsVersions.DateOfLastUse < &MinSessionStartDate
	|	AND NOT ExtensionsVersions.DeletionMark";
	
	// If another user is editing the "ExtensionsVersions" catalog,
	// wait till it's finished.
	Block = New DataLock;
	LockItem = Block.Add("Catalog.ExtensionsVersions");
	LockItem.Mode = DataLockMode.Shared;

	BeginTransaction();
	Try
		Block.Lock();
		Selection = Query.Execute().Select();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;

	Return Undefined;

EndFunction

// This method is required by DeleteObsoleteParametersVersions procedure.
Procedure DisableScheduledJobIfRequired()

	// Disabling the scheduled job if only one extension version is left.
	Block = New DataLock;
	LockItem = Block.Add("Catalog.ExtensionsVersions");
	LockItem.Mode = DataLockMode.Shared;

	Query = New Query;
	Query.Text =
	"SELECT TOP 2
	|	ExtensionsVersions.Ref AS Ref
	|FROM
	|	Catalog.ExtensionsVersions AS ExtensionsVersions
	|WHERE
	|	NOT ExtensionsVersions.DeletionMark";

	BeginTransaction();
	Try
		Block.Lock();
		Selection = Query.Execute().Select();
		If Selection.Count() = 0 Or Selection.Count() = 1 And Selection.Next() 
			And Selection.Ref = SessionParameters.ExtensionsVersion Then

			EnableDeleteObsoleteExtensionsVersionsParametersJob(False);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

// For the LastExtensionsVersion function.
//
// Returns:
//  Structure:
//   * ExtensionsVersion - CatalogRef.ExtensionsVersions
//   * UpdateDate - Date
//   * UpdateID - UUID
//
Function NewStoredPropertiesOfExtensionsVersion()
	
	Result = New Structure;
	Result.Insert("ExtensionsVersion", EmptyRef());
	Result.Insert("UpdateDate", '00010101');
	Result.Insert("UpdateID",
		CommonClientServer.BlankUUID());
	
	Return Result;
	
EndFunction

// For the RegisterExtensionsVersionUsage procedure.
Procedure UpdateExtensionsVersionLastUsedDate(ExtensionsVersion) Export

	RoundedSessionStartDate = RoundedSessionStartDate();
	Query = RequestLastUsedDateCheck(ExtensionsVersion, RoundedSessionStartDate);
	
	// If another user is updating the last use date,
	// wait till the it's finished to avoid exclusive locks.
	Block = New DataLock;
	LockItem = Block.Add("Catalog.ExtensionsVersions");
	LockItem.SetValue("Ref", ExtensionsVersion);
	LockItem.Mode = DataLockMode.Shared;

	BeginTransaction();
	Try
		Block.Lock();
		QueryResult = Query.Execute();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

	If Not QueryResult.IsEmpty() Then
		Block = New DataLock;
		LockItem = Block.Add("Catalog.ExtensionsVersions");
		LockItem.SetValue("Ref", ExtensionsVersion);
		BeginTransaction();
		Try
			Block.Lock();
			Object = ServiceItem(ExtensionsVersion);

			If Object <> Undefined And Object.DateOfLastUse < RoundedSessionStartDate Then

				Object.DateOfLastUse = RoundedSessionStartDate;
				Object.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;

EndProcedure

// For the RegisterExtensionsVersionUsage procedure.
Function RequestLastUsedDateCheck(ExtensionsVersion, RoundedSessionStartDate = Undefined)
	
	If RoundedSessionStartDate = Undefined Then
		RoundedSessionStartDate = RoundedSessionStartDate();
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ExtensionsVersion", ExtensionsVersion);
	Query.SetParameter("DateOfLastUse", RoundedSessionStartDate);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.ExtensionsVersions AS ExtensionsVersions
	|WHERE
	|	NOT ExtensionsVersions.DeletionMark
	|	AND ExtensionsVersions.Ref = &ExtensionsVersion
	|	AND ExtensionsVersions.DateOfLastUse < &DateOfLastUse";
	
	Return Query;
	
EndFunction

// For the procedures RegisterExtensionsVersionUsage,
// UpdateExtensionVersionLastUsedDate, and AddNewExtensionVersion.
//
Procedure UpdateLatestExtensionsVersion(ExtensionsVersion)

	If DataBaseConfigurationChangedDynamically() Or ExtensionsChangedDynamically() Then
		Return;
	EndIf;

	StoredProperties = LastExtensionsVersion();
	If StoredProperties.ExtensionsVersion = ExtensionsVersion Then
		Return;
	EndIf;

	If Common.FileInfobase() Or ExclusiveMode() Then
		InstallLatestExtensionVersions(ExtensionsVersion);
		Return;
	EndIf;
	
	ProcedureName = "StandardSubsystemsServer.InstallLatestExtensionVersions";
	Filter = New Structure("MethodName, State", ProcedureName, BackgroundJobState.Active);
	VersionAsString = Lower(ExtensionsVersion.UUID());
	
	FoundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	For Each FoundJob In FoundJobs Do
		If StrFind(FoundJob.Description, VersionAsString) > 0 Then
			Return;
		EndIf;
	EndDo;
	
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Phiên bản phần mở rộng: Cài đặt phiên bản gần nhất %1';
			|ru = 'Версии расширений: Установка последней версии %1';
			|en = 'Extension versions: Install a new version of %1'; fa = 'Extension versions: Install a new version of %1';
			|it = 'Версии расширений: Установка последней версии %1';
			|pl = 'Extension versions: Install a new version of %1';
			|tr = 'Uzantı sürümleri: En son sürüm olan %1 sürümünün yüklenmesi'",
			Common.DefaultLanguageCode()),
		VersionAsString);
	
	JobParameters = CommonClientServer.ValueInArray(ExtensionsVersion);
	
	// The procedure name must be as specified in the ProcedureName variable.
	BackgroundJobs.Execute("StandardSubsystemsServer.InstallLatestExtensionVersions",
		JobParameters,, JobDescription);
	
EndProcedure

// Intended for "UpdateLatestExtensionsVersion" procedure.
Procedure InstallLatestExtensionVersions(ExtensionsVersion) Export
	
	If Not Common.FileInfobase() Then
		
		If DataBaseConfigurationChangedDynamically()
		 Or ExtensionsChangedDynamically() Then
			Return;
		EndIf;
		
		StoredProperties = LastExtensionsVersion();
		If StoredProperties.ExtensionsVersion = ExtensionsVersion Then
			Return;
		EndIf;
	EndIf;
	
	ParameterName = "StandardSubsystems.Core.LastExtensionsVersion";
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ExtensionVersionParameters");
	LockItem.SetValue("ExtensionsVersion", Catalogs.ExtensionsVersions.EmptyRef());
	LockItem.SetValue("ParameterName", ParameterName);
	
	BeginTransaction();
	Try
		Block.Lock();
		StoredProperties = LastExtensionsVersion();
		If StoredProperties.ExtensionsVersion <> ExtensionsVersion
		   And Not DataBaseConfigurationChangedDynamically()
		   And Not ExtensionsChangedDynamically() Then
			
			StoredProperties.ExtensionsVersion = ExtensionsVersion;
			StoredProperties.UpdateDate   = CurrentSessionDate();
			StoredProperties.UpdateID = New UUID;
			StandardSubsystemsServer.SetExtensionParameter(ParameterName, StoredProperties, True);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// For the DynamicallyChangedExtensions function.
Function ChangesInExtensionsComposition(CurrentComposition, NewContent)
	NewMap1 = New Map;
	For Each Extension In StrSplit(NewContent, Chars.LF) Do
		If StrStartsWith(Extension, "#") Or Not ValueIsFilled(Extension) Then
			Continue;
		EndIf;
		NameAndHash = StrSplit(Extension, " ");
		NewMap1.Insert(NameAndHash[0], Extension);
	EndDo;

	CurrentMap = New Map;
	For Each Extension In StrSplit(CurrentComposition, Chars.LF) Do
		If StrStartsWith(Extension, "#") Or Not ValueIsFilled(Extension) Then
			Continue;
		EndIf;
		NameAndHash = StrSplit(Extension, " ");
		CurrentMap.Insert(NameAndHash[0], Extension);
	EndDo;

	Added2 = 0;
	IsChanged  = 0;
	NewItemsList = New Array;
	For Each NewExtension In NewMap1 Do
		FoundItem = CurrentMap[NewExtension.Key];
		If FoundItem = Undefined Then
			Added2 = Added2 + 1;
			NewItemsList.Add(NewExtension.Key);
		ElsIf FoundItem <> NewExtension.Value Then
			IsChanged = IsChanged + 1;
			CurrentMap.Delete(NewExtension.Key);
		Else
			CurrentMap.Delete(NewExtension.Key);
		EndIf;
	EndDo;
	Deleted = CurrentMap.Count();

	Result = New Structure;
	Result.Insert("Added2", Added2);
	Result.Insert("IsChanged", IsChanged);
	Result.Insert("Deleted", Deleted);
	Result.Insert("NewItemsList", NewItemsList);

	Return Result;
EndFunction

// For the InstalledExtensions function and RestoreRegisteredInstalledExtensionsComposition procedure.
Procedure SetTheInitialRegisteredState(Source, Receiver = Undefined)

	If Receiver = Undefined Then
		UpdateTheRegisteredStateInTheSessionParameter(Source);
	Else
		Receiver.Insert("BasicRegisteredStatus", Source.MainState);
		Receiver.Insert("FixesRegisteredStatus", Source.PatchesState);
	EndIf;

EndProcedure

// For the ExtensionsChangedDynamically and DynamicallyChangedExtensions functions.
Procedure RegisterChangesToInstalledExtensions(InstalledExtensions, Unchanged)

	If SessionParameters.InstalledExtensions.BasicRegisteredStatus = InstalledExtensions.MainState
		And SessionParameters.InstalledExtensions.FixesRegisteredStatus = InstalledExtensions.PatchesState Then
		Return;
	EndIf;

	DefaultLanguageCode = Common.DefaultLanguageCode();
	Comment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '1. Đã:
			 |- mở rộng:
			 |""%1""
			 |- sửa lỗi:
			 |""%2""
			 |2. Trở thành:
			 |- mở rộng:
			 |""%3""
			 |- sửa lỗi:
			 |""%4""
			 |3. Thành phần mới như khi khởi động phiên làm việc: %5';
			 |ru = '1. Было:
			 |- расширения:
			 |""%1""
			 |- исправления:
			 |""%2""
			 |2. Стало:
			 |- расширения:
			 |""%3""
			 |- исправления:
			 |""%4""
			 |3. Новый состав, как при запуске сеанса: %5';
			 |en = '1. Previously:
			 |- Extensions:
			 |""%1""
			 |- Patches:
			 |""%2""
			 |2. Now:
			 |- Extensions:
			 |""%3""
			 |- Patches:
			 |""%4""
			 |3. New composition as at session start: %5'; fa = '1. Previously:
			 |- Extensions:
			 |""%1""
			 |- Patches:
			 |""%2""
			 |2. Now:
			 |- Extensions:
			 |""%3""
			 |- Patches:
			 |""%4""
			 |3. New composition as at session start: %5';
			 |it = '1. Era:
			 |- estensioni:
			 |""%1""
			 |- correzioni:
			 |""%2""
			 |2. Diventa:
			 |- estensioni:
			 |""%3""
			 |- correzioni:
			 |""%4""
			 |3. Nuova composizione, come in avvio di sessione: %5';
			 |pl = '1. Było:
			 |- rozszerzenia:
			 |""%1""
			 |- korekty:
			 |""%2""
			 |2. Stało:
			 |- rozszerzenia:
			 |""%3""
			 |- korekty:
			 |""%4""
			 |3. Nowy skład, jak podczas uruchomienia sesji: %5';
			 |tr = '1. Önce:
			 |- uzantılar:
			 |""%1""
			 |- düzeltmeler:
			 |""%2""
			 |2. Sonra:
			 |- uzantılar:
			 |""%3""
			 |- düzeltmeler:
			 |""%4""
			 |3. Oturumun açılması sırasında olduğu gibi yeni içerik: %5'", DefaultLanguageCode),
		SessionParameters.InstalledExtensions.BasicRegisteredStatus,
		SessionParameters.InstalledExtensions.FixesRegisteredStatus,
		InstalledExtensions.MainState, InstalledExtensions.PatchesState, 
			?(Unchanged, NStr("vi = 'Có';
								|ru = 'Да';
								|en = 'Yes'; fa = 'بله';
								|it = 'Sì';
								|pl = 'Tak';
								|tr = 'Evet'", DefaultLanguageCode), NStr("vi = 'Không';
																		|ru = 'Нет';
																		|en = 'No'; fa = 'خیر';
																		|it = 'No';
																		|pl = 'Nie';
																		|tr = 'Hayır'", DefaultLanguageCode)));

	WriteLogEvent(
		NStr("vi = 'Phần mở rộng cấu hình. Đã tìm thấy có thay đổi trong các phần mở rộng được cài đặt';
			|ru = 'Расширения конфигурации.Обнаружено изменение установленных расширений';
			|en = 'Configuration extensions.Installed extension change is detected'; fa = 'Configuration extensions.Installed extension change is detected';
			|it = 'Estensioni di configurazione. Rilevata modifica delle estensioni installate';
			|pl = 'Rozszerzenia konfiguracji.Wykryto zmianę zainstalowanych rozszerzeń';
			|tr = 'Yapılandırma uzantıları.Ayarlanan uzantıların değişimi bulundu'",
		Common.DefaultLanguageCode()), EventLogLevel.Information,,, Comment);

	UpdateTheRegisteredStateInTheSessionParameter(InstalledExtensions);

EndProcedure

// For the RegisterExtensionsCompositionChange,
// SetInitialRegisteredState procedures.
//
Procedure UpdateTheRegisteredStateInTheSessionParameter(InstalledExtensions)

	Properties = New Structure(SessionParameters.InstalledExtensions);
	Properties.BasicRegisteredStatus    = InstalledExtensions.MainState;
	Properties.FixesRegisteredStatus = InstalledExtensions.PatchesState;

	SessionParameters.InstalledExtensions = New FixedStructure(Properties);

EndProcedure

// For procedure AddAdditionalInformationRecords of the manager module of information register ExtensionVersionParameters.
// 
//
// Returns:
//  Structure:
//   * ConnectedNow - String - Enabled session extensions including patches.
//   * Disabled1  - String - Disabled session extensions including patches.
//   * All          - String - All database extensions including patches.
//
Function DescriptionExtensionsForJournal() Export

	Result = New Structure;

	Result.Insert("ConnectedNow", ExtensionsChecksums(
		ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied), "All", False));

	Result.Insert("Disabled1", ExtensionsChecksums(
		ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionDisabled), "All", False));

	Result.Insert("All", ExtensionsChecksums(
		ConfigurationExtensions.Get(), "All", False));

	Return Result;

EndFunction

#EndRegion

#EndIf