///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Generates a data areas update plan and saves it to the infobase.
//
// Parameters:
//  LibraryID  - String - a configuration name or library ID,
//  AllHandlers    - ValueTable - list of all update handlers,
//  MandatorySeparatedHandlers    - ValueTable - List of required update handlers with SharedData = False.
//    
//  SourceIBVersion - String - an original infobase version,
//  IBMetadataVersion - String - configuration version (from metadata).
//
Procedure GenerateDataAreaUpdatePlan(LibraryID, AllHandlers, 
	MandatorySeparatedHandlers, SourceIBVersion, IBMetadataVersion) Export
	
	If Common.DataSeparationEnabled()
		And Not Common.SeparatedDataUsageAvailable() Then
		
		UpdateHandlers = AllHandlers.CopyColumns(); // ValueTable
		For Each HandlerRow In AllHandlers Do
			// When generating area update plan, mandatory (*) handlers are not added by default.
			If HandlerRow.Version = "*" Then
				Continue;
			EndIf;
			FillPropertyValues(UpdateHandlers.Add(), HandlerRow);
		EndDo;
		
		For Each RequiredHandler In MandatorySeparatedHandlers Do
			HandlerRow = UpdateHandlers.Add();
			FillPropertyValues(HandlerRow, RequiredHandler);
			HandlerRow.Version = "*";
		EndDo;
		
		FilterParameters = InfobaseUpdateInternal.HandlerFIlteringParameters();
		FilterParameters.GetSeparated = True;
		DataAreaUpdatePlan = InfobaseUpdateInternal.UpdateInIntervalHandlers(
			UpdateHandlers, SourceIBVersion, IBMetadataVersion, FilterParameters);
			
		PlanDetails = New Structure;
		PlanDetails.Insert("VersionFrom1", SourceIBVersion);
		PlanDetails.Insert("VersionTo1", IBMetadataVersion);
		PlanDetails.Insert("Plan", DataAreaUpdatePlan);
		
		RecordManager = InformationRegisters.SubsystemsVersions.CreateRecordManager();
		RecordManager.SubsystemName = LibraryID;
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.SubsystemsVersions");
		LockItem.SetValue("SubsystemName", LibraryID);
		
		BeginTransaction();
		Try
			Block.Lock();
			
			RecordManager.Read();
			
			If ShouldSaveExchangePlanChanges() Then
				PreviousUpdatePlan = RecordManager.UpdatePlan.Get();
				CurrentAsteriskHandlers = New Array;
				If PreviousUpdatePlan <> Undefined Then
					FilterParameters = New Structure;
					FilterParameters.Insert("RegistrationVersion", "*");
					CurrentAsteriskHandlers = PreviousUpdatePlan.Plan.Rows.FindRows(FilterParameters, True);
				EndIf;
				
				For Each Version In PlanDetails.Plan.Rows Do
					If Version.Version <> "*" Then
						Continue;
					EndIf;
					
					For Each Handler In CurrentAsteriskHandlers Do
						FoundHandler = Version.Rows.Find(Handler.Procedure, "Procedure");
						If FoundHandler = Undefined Then
							FillPropertyValues(Version.Rows.Add(), Handler);
						EndIf;
					EndDo;
				EndDo;
			EndIf;
			
			RecordManager.UpdatePlan = New ValueStorage(PlanDetails, New Deflation(9));
			RecordManager.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		UpdatePlanEmpty = DataAreaUpdatePlan.Rows.Count() = 0;
		
		If LibraryID = Metadata.Name Then
			// The configuration version can be set only if all the libraries are up-to-date.
			// Otherwise, the area update mechanism doesn't start and the libraries won't be updated.
			UpdatePlanEmpty = False;
			
			// Checking whether each plan is empty.
			Libraries = New ValueTable;
			Libraries.Columns.Add("Name", Metadata.InformationRegisters.SubsystemsVersions.Dimensions.SubsystemName.Type);
			Libraries.Columns.Add("Version", Metadata.InformationRegisters.SubsystemsVersions.Resources.Version.Type);
			
			SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
			For Each SubsystemName In SubsystemsDetails.Order Do
				SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
				If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
					// The library has no module, therefore no update handlers.
					Continue;
				EndIf;
				
				LibraryRow = Libraries.Add();
				LibraryRow.Name = SubsystemDetails.Name;
				LibraryRow.Version = SubsystemDetails.Version;
			EndDo;
			
			Query = New Query;
			Query.SetParameter("Libraries", Libraries);
			Query.Text =
				"SELECT
				|	Libraries.Name AS Name,
				|	Libraries.Version AS Version
				|INTO Libraries
				|FROM
				|	&Libraries AS Libraries
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	Libraries.Name AS Name,
				|	Libraries.Version AS Version,
				|	SubsystemsVersions.UpdatePlan AS UpdatePlan,
				|	CASE
				|		WHEN SubsystemsVersions.Version = Libraries.Version
				|			THEN TRUE
				|		ELSE FALSE
				|	END AS Updated1
				|FROM
				|	Libraries AS Libraries
				|		LEFT JOIN InformationRegister.SubsystemsVersions AS SubsystemsVersions
				|		ON Libraries.Name = SubsystemsVersions.SubsystemName";
				
			BeginTransaction();
			Try
				Block = New DataLock;
				LockItem = Block.Add("InformationRegister.SubsystemsVersions");
				LockItem.Mode = DataLockMode.Shared;
				Block.Lock();
				
				Result = Query.Execute();
				
				CommitTransaction();
			Except
				RollbackTransaction();
				Raise;
			EndTry;
			
			Selection = Result.Select();
			While Selection.Next() Do
				
				If Not Selection.Updated1 Then
					UpdatePlanEmpty = False;
					
					CommentTemplate = NStr("vi = 'Đã cập nhật phiên bản cấu hình trước khi cập nhật phiên bản thư viện %1';
											|ru = 'Обновление версии конфигурации было выполнено до обновления версии библиотеки %1';
											|en = 'Configuration version update was performed before updating %1 library version'; fa = 'Configuration version update was performed before updating %1 library version';
											|it = 'L''aggiornamento della versione di configurazione è stato eseguito prima dell''aggiornamento della versione della libreria %1';
											|pl = 'Aktualizacja wersji konfiguracji została wykonana do aktualizacji wersji biblioteki %1';
											|tr = 'Yapılandırma sürümü, kütüphanenin bir sürümünü güncellemeden önce güncellendi. %1'");
					CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, Selection.Name);
					WriteLogEvent(
						InfobaseUpdate.EventLogEvent(),
						EventLogLevel.Error,
						,
						,
						CommentText1);
					
					Break;
				EndIf;
				
				If Selection.UpdatePlan = Undefined Then
					LibraryUpdatePlanDetails = Undefined;
				Else
					LibraryUpdatePlanDetails = Selection.UpdatePlan.Get();
				EndIf;
				
				If LibraryUpdatePlanDetails = Undefined Then
					UpdatePlanEmpty = False;
					
					CommentTemplate = NStr("vi = 'Không có kế hoạch cập nhật thư viện %1';
											|ru = 'Не существует план обновления библиотеки %1';
											|en = 'The update plan for library %1 does not exist'; fa = 'The update plan for library %1 does not exist';
											|it = 'Non esiste un piano di aggiornamento della biblioteca %1';
											|pl = 'Nie istnieje planu aktualizacji biblioteki %1';
											|tr = '%1 kütüphanesinin güncelleme planı mevcut değil'");
					CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, Selection.Name);
					WriteLogEvent(
						InfobaseUpdate.EventLogEvent(),
						EventLogLevel.Error,
						,
						,
						CommentText1);
					
					Break;
				EndIf;
				
				If LibraryUpdatePlanDetails.VersionTo1 <> Selection.Version Then
					UpdatePlanEmpty = False;
					
					CommentTemplate = NStr("vi = 'Đã tìm thấy kế hoạch cập nhật không hợp lệ cho thư viện %1
						| Cần có kế hoạch cập nhật sang phiên bản %2, đã tìm thấy kế hoạch cập nhật sang phiên bản %3';
						|ru = 'Обнаружен некорректный план обновления библиотеки %1
						|Требуется план обновления на версию %2, найден план для обновления на версию %3';
						|en = 'Incorrect update plan of the %1 library is detected.
						|Plan for updating to version %2 is required, plan for updating to version %3 is found.'; fa = 'Incorrect update plan of the %1 library is detected.
						|Plan for updating to version %2 is required, plan for updating to version %3 is found.';
						|it = 'Rilevato errata piano di aggiornamento della libreria %1
						|è Necessario un piano di aggiornamento su versione %2, è stato trovato un piano per l''aggiornamento alla versione %3';
						|pl = 'Został wykryty niepoprawny plan aktualizacji biblioteki %1
						|Wymagany jest plan aktualizacji do wersji %2, jest znaleziony plan dla aktualizacji do wersji %3';
						|tr = '%1 kütüphanesi için geçersiz güncelleme planı tespit edildi.
						|%2 sürümüne güncelleme planı gerekirken, %3 sürümüne güncelleme planı bulundu.'");
					CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, Selection.Name, String(LibraryUpdatePlanDetails.VersionTo1), String(Selection.Version));
					WriteLogEvent(
						InfobaseUpdate.EventLogEvent(),
						EventLogLevel.Error,
						,
						,
						CommentText1);
					
					Break;
				EndIf;
				
				If LibraryUpdatePlanDetails.Plan.Rows.Count() > 0 Then
					UpdatePlanEmpty = False;
					Break;
				EndIf;
				
			EndDo;
		EndIf;
		
		If UpdatePlanEmpty Then
			
			// The update plan has no separated real-time or exclusive handlers.
			// Search for deferred separated handlers.
			DeferredFilterParameters = InfobaseUpdateInternal.HandlerFIlteringParameters();
			DeferredFilterParameters.GetSeparated = True;
			DeferredFilterParameters.UpdateMode = "Deferred";
			
			DeferredHandlers = InfobaseUpdateInternal.UpdateInIntervalHandlers(UpdateHandlers, SourceIBVersion, IBMetadataVersion, DeferredFilterParameters);
			
			// No separated deferred handlers, install a new version of the library.
			If DeferredHandlers.Rows.Count() = 0 Then
			
				SetAllDataAreasVersion(LibraryID, SourceIBVersion, IBMetadataVersion);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Blocks the record in the DataAreasSubsystemsVersions information register that corresponds to the current data area,
// and returns the record key.
//
// Returns:
//   InformationRegisterRecordKey.DataAreasSubsystemsVersions
//
Function LockDataAreaVersions() Export
	
	RecordKey = Undefined;
	If Common.DataSeparationEnabled() Then
		
		If Common.SeparatedDataUsageAvailable() Then
			SetPrivilegedMode(True);
		EndIf;
		
		RecordKey = SubsystemVersionsRecordKey();
		
	EndIf;
	
	If RecordKey <> Undefined Then
		For AttemptNumber = 1 To 2 Do
			Result = DataAreaLockResult(RecordKey, AttemptNumber);
			If Result = "Success" Then
				Break;
			EndIf;
		EndDo;
	EndIf;
	Return RecordKey;
	
EndFunction

// Unlocks the record in the DataAreasSubsystemsVersions information register.
//
// Parameters: 
//   RecordKey - InformationRegisterRecordKey.DataAreasSubsystemsVersions
//
Procedure UnlockDataAreaVersions(RecordKey) Export
	
	If RecordKey <> Undefined Then
		UnlockDataForEdit(RecordKey);
	EndIf;
	
EndProcedure

Function ScheduledTimeWhenTheAreaUpdateStarts() Export
	
	FilterOfTasks = New Structure;
	FilterOfTasks.Insert("MethodName", "InfobaseUpdateInternalSaaS.UpdateCurrentDataArea");
	JobsExecuteUpdateCurrentDataArea = ScheduledJobsServer.FindJobs(FilterOfTasks);
	If JobsExecuteUpdateCurrentDataArea.Count() > 0 Then
		ScheduledStartTime = (JobsExecuteUpdateCurrentDataArea[0].ScheduledStartTime - Date(1, 1, 1)) * 1000 + JobsExecuteUpdateCurrentDataArea[0].Milliseconds;
	Else
		ScheduledStartTime = CurrentUniversalDateInMilliseconds();
	EndIf;
	
	Return ScheduledStartTime;
	
EndFunction

Function AreasUpdatedToVersion(SubsystemName, Version) Export
	Query = New Query;
	Query.SetParameter("SubsystemName", SubsystemName);
	Query.SetParameter("Version", Version);
	Query.Text =
		"SELECT
		|	DataAreasSubsystemsVersions.DataAreaAuxiliaryData AS DataAreaAuxiliaryData,
		|	DataAreasSubsystemsVersions.DeferredHandlersRegistrationCompleted AS
		|		DeferredHandlersRegistrationCompleted
		|FROM
		|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
		|WHERE
		|	DataAreasSubsystemsVersions.SubsystemName = &SubsystemName
		|	AND DataAreasSubsystemsVersions.Version = &Version";
	AreasUpdatedToVersion = Query.Execute().Unload();
	
	Return AreasUpdatedToVersion;
EndFunction

// See InfobaseUpdate.RegisterNewSubsystem.
Procedure RegisterNewSubsystem(SubsystemName, VersionNumber, StandardProcessing) Export
	
	If Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	StandardProcessing = False;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataAreasSubsystemsVersions.SubsystemName AS SubsystemName
	|FROM
	|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions";
	
	ConfigurationSubsystems = Query.Execute().Unload().UnloadColumn("SubsystemName");
	
	If ConfigurationSubsystems.Count() > 0 Then
		// This is not the first launch of a program
		If ConfigurationSubsystems.Find(SubsystemName) = Undefined Then
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			DataArea = ModuleSaaSOperations.SessionSeparatorValue();
			Record = InformationRegisters.DataAreasSubsystemsVersions.CreateRecordManager();
			Record.SubsystemName = SubsystemName;
			Record.DataAreaAuxiliaryData = DataArea;
			Record.Version = ?(VersionNumber = "", "0.0.0.1", VersionNumber);
			Record.Write();
		EndIf;
	EndIf;
	
	InformationRecords = InfobaseUpdateInternal.InfobaseUpdateInfo();
	ElementIndex = InformationRecords.NewSubsystems.Find(SubsystemName);
	If ElementIndex <> Undefined Then
		InformationRecords.NewSubsystems.Delete(ElementIndex);
		InfobaseUpdateInternal.WriteInfobaseUpdateInfo(InformationRecords);
	EndIf;
	
EndProcedure

// Returns a table of subsystem versions used in the configuration.
// The procedure is used for batch import and export of information about subsystem versions.
//
// Returns:
//   ValueTable:
//     * SubsystemName - String - a subsystem name.
//     * Version        - String - a subsystem version.
//
Function SubsystemsVersions(StandardProcessing) Export
	
	If Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return Undefined;
	EndIf;
	
	StandardProcessing = False;
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	Query = New Query;
	Query.SetParameter("DataAreaAuxiliaryData", ModuleSaaSOperations.SessionSeparatorValue());
	Query.Text =
	"SELECT
	|	SubsystemsVersions.SubsystemName AS SubsystemName,
	|	SubsystemsVersions.Version AS Version
	|FROM
	|	InformationRegister.DataAreasSubsystemsVersions AS SubsystemsVersions
	|WHERE
	|	SubsystemsVersions.DataAreaAuxiliaryData = &DataAreaAuxiliaryData";
	
	Return Query.Execute().Unload();

EndFunction

Procedure FillTagThisMainConfig(PreviousConfigurationName) Export
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.DataAreasSubsystemsVersions");
	LockItem.SetValue("SubsystemName", PreviousConfigurationName);

	Query = New Query;
	Query.SetParameter("SubsystemName", PreviousConfigurationName);
	Query.Text = 
		"SELECT
		|	DataAreasSubsystemsVersions.SubsystemName AS SubsystemName,
		|	DataAreasSubsystemsVersions.DataAreaAuxiliaryData AS DataAreaAuxiliaryData
		|FROM
		|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
		|WHERE
		|	DataAreasSubsystemsVersions.SubsystemName = &SubsystemName
		|	AND DataAreasSubsystemsVersions.IsMainConfiguration = FALSE";
	
	BeginTransaction();
	Try
		Block.Lock();

		Selection = Query.Execute().Select();
		While Selection.Next() Do
			// Flag IsMainConfiguration is cleared for the previous configuration.
			RecordManager = InformationRegisters.DataAreasSubsystemsVersions.CreateRecordManager();
			RecordManager.SubsystemName = Selection.SubsystemName;
			RecordManager.DataAreaAuxiliaryData = Selection.DataAreaAuxiliaryData;
			RecordManager.Read();
			
			RecordManager.IsMainConfiguration = True;
			RecordManager.Write();
		EndDo;

		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

Function MainConfigurationInDataArea() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	SubsystemsVersions.SubsystemName AS SubsystemName,
		|	SubsystemsVersions.Version AS Version
		|FROM
		|	InformationRegister.DataAreasSubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	SubsystemsVersions.IsMainConfiguration = TRUE";
	QueryResult = Query.Execute();
	
	Return QueryResult;
	
EndFunction

Function DataAreaSubsystemVersionsRecord() Export
	RecordSet = InformationRegisters.DataAreasSubsystemsVersions.CreateRecordSet();
	Return RecordSet;
EndFunction

Function UpdateProgressReport() Export
	
	Return "Report.DataAreasUpdateProgress.Form";
	
EndFunction

Procedure DeleteTasksForUpdatingAreas() Export
	
	FilterJobs = New Structure;
	FilterJobs.Insert("MethodName", "InfobaseUpdateInternalSaaS.UpdateCurrentDataArea");
	Jobs = ScheduledJobsServer.FindJobs(FilterJobs);
	
	For Each Job In Jobs Do
		ScheduledJobsServer.DeleteJob(Job);
	EndDo;
	
EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// See InfobaseUpdateSSL.BeforeUpdateInfobase.
Procedure BeforeUpdateInfobase() Export
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		SharedDataVersion = InfobaseUpdateInternal.IBVersion(Metadata.Name, True);
		If InfobaseUpdateInternal.UpdateRequired(Metadata.Version, SharedDataVersion) Then
			Message = NStr("vi = 'Chưa thực hiện phần chung cập nhật cơ sở thông tin.
				|Hãy liên hệ với người quản trị.';
				|ru = 'Не выполнена общая часть обновления информационной базы.
				|Обратитесь к администратору.';
				|en = 'General part of the infobase update is not performed.
				|Contact the Administrator.'; fa = 'General part of the infobase update is not performed.
				|Contact the Administrator.';
				|it = 'La parte generale dell''aggiornamento del database delle informazioni non è stata completata.
				|Contattare l''amministratore.';
				|pl = 'Nie jest wykonana ogólna część aktualizacji bazy informacyjnej.
				|Zwróć się do administratora.';
				|tr = 'Infobase güncellemesinin ortak kısmı yürütülemiyor.
				|Yöneticiye başvurun.'");
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Error,,, Message);
			Raise Message;
		EndIf;
	EndIf;
	
EndProcedure	

// For internal use only.
Procedure OnDetermineIBVersion(Val LibraryID, Val GetSharedDataVersion, StandardProcessing, IBVersion) Export
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable()
		And Not GetSharedDataVersion Then
		
		StandardProcessing = False;
		
		AllVersionsOfSubsystems = (LibraryID = Undefined);
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		
		QueryText = 
		"SELECT
		|	DataAreasSubsystemsVersions.Version,
		|	DataAreasSubsystemsVersions.SubsystemName
		|FROM
		|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
		|WHERE
		|	&Condition
		|	AND DataAreasSubsystemsVersions.DataAreaAuxiliaryData = &DataAreaAuxiliaryData";
		
		If AllVersionsOfSubsystems Then
			QueryText = StrReplace(QueryText, "&Condition", "TRUE");
		Else
			QueryText = StrReplace(QueryText, "&Condition", "DataAreasSubsystemsVersions.SubsystemName = &SubsystemName");
		EndIf;
		
		Query = New Query(QueryText);
		Query.SetParameter("SubsystemName", LibraryID);
		Query.SetParameter("DataAreaAuxiliaryData", ModuleSaaSOperations.SessionSeparatorValue());
		ValueTable = Query.Execute().Unload();
		IBVersion = "";
		If ValueTable.Count() > 0 Then
			If Not AllVersionsOfSubsystems Then
				IBVersion = TrimAll(ValueTable[0].Version);
			Else
				SubsystemsVersions = New Map;
				For Each VersionRow In ValueTable Do
					SubsystemsVersions.Insert(VersionRow.SubsystemName, TrimAll(VersionRow.Version));
				EndDo;
				
				IBVersion = SubsystemsVersions;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure OnDefineDataAreaUpdateMode(StandardProcessing, Result) Export
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		StandardProcessing = False;
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		
		QueryText = 
			"SELECT TOP 1
			|	1
			|FROM
			|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
			|WHERE
			|	DataAreasSubsystemsVersions.DataAreaAuxiliaryData = &DataAreaAuxiliaryData";
		Query = New Query(QueryText);
		Query.SetParameter("DataAreaAuxiliaryData", ModuleSaaSOperations.SessionSeparatorValue());
		If Query.Execute().IsEmpty() Then
			Result = "InitialFilling";
			Return;
		EndIf;
		
		Query = New Query;
		Query.Text = 
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
			|WHERE
			|	DataAreasSubsystemsVersions.SubsystemName = &BaseConfigurationName
			|	AND DataAreasSubsystemsVersions.DataAreaAuxiliaryData = &DataAreaAuxiliaryData";
		Query.SetParameter("BaseConfigurationName", Metadata.Name);
		Query.SetParameter("DataAreaAuxiliaryData", ModuleSaaSOperations.SessionSeparatorValue());
		
		// Making decision based on the IsMainConfiguration attribute filled earlier
		If Query.Execute().IsEmpty() Then
			Result = "MigrationFromAnotherApplication";
		Else
			Result = "VersionUpdate";
		EndIf;
		
	EndIf;
	
EndProcedure

// For internal use only.
Procedure OnSetIBVersion(Val LibraryID, Val VersionNumber, StandardProcessing, IsMainConfiguration, ExecutedRegistration = Undefined) Export
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		StandardProcessing = False;
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		
		DataArea = ModuleSaaSOperations.SessionSeparatorValue();
		
		RecordManager = InformationRegisters.DataAreasSubsystemsVersions.CreateRecordManager();
		RecordManager.DataAreaAuxiliaryData = DataArea;
		RecordManager.SubsystemName = LibraryID;
		RecordManager.Version = VersionNumber;
		RecordManager.IsMainConfiguration = IsMainConfiguration;
		If ExecutedRegistration <> Undefined Then
			RecordManager.DeferredHandlersRegistrationCompleted = ExecutedRegistration;
		EndIf;
		RecordManager.Write();
		
	EndIf;
	
EndProcedure

// For internal use only.
Procedure WhenInstallingSubsystemVersions(SubsystemsVersions, StandardProcessing) Export
	
	If Not Common.DataSeparationEnabled()
		Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	DataArea = ModuleSaaSOperations.SessionSeparatorValue();
	
	RecordSet = InformationRegisters.DataAreasSubsystemsVersions.CreateRecordSet();
	
	For Each Version In SubsystemsVersions Do
		NewRecord = RecordSet.Add();
		NewRecord.DataAreaAuxiliaryData = DataArea;
		NewRecord.SubsystemName = Version.SubsystemName;
		NewRecord.Version = Version.Version;
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

// For internal use only.
Procedure OnCheckDeferredUpdateHandlersRegistration(RegistrationCompleted, StandardProcessing) Export
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		StandardProcessing = False;
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	DataAreasSubsystemsVersions.SubsystemName
			|FROM
			|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
			|WHERE
			|	NOT DataAreasSubsystemsVersions.DeferredHandlersRegistrationCompleted
			|	AND DataAreasSubsystemsVersions.DataAreaAuxiliaryData = &DataAreaAuxiliaryData";
			
		Query.SetParameter("DataAreaAuxiliaryData", ModuleSaaSOperations.SessionSeparatorValue());
		Result = Query.Execute().Unload();
		RegistrationCompleted = (Result.Count() = 0);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure OnMarkDeferredUpdateHandlersRegistration(SubsystemName, Value, StandardProcessing) Export
	
	If Not (Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable()) Then
		Return;
	EndIf;
		
	StandardProcessing = False;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.DataAreasSubsystemsVersions");
	If SubsystemName <> Undefined Then
		LockItem.SetValue("SubsystemName", SubsystemName);
	EndIf;
	
	BeginTransaction();
	Try
		Block.Lock();

		RecordSet = InformationRegisters.DataAreasSubsystemsVersions.CreateRecordSet();
		If SubsystemName <> Undefined Then
			RecordSet.Filter.SubsystemName.Set(SubsystemName);
		EndIf;
		RecordSet.Read();
		
		For Each RegisterRecord In RecordSet Do
			RegisterRecord.DeferredHandlersRegistrationCompleted = Value;
		EndDo;
		RecordSet.Write();

		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// For internal use only.
Procedure OnSendSubsystemVersions(DataElement, ItemSend, Val InitialImageCreating, StandardProcessing) Export
	
	If Not Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If ItemSend = DataItemSend.Delete
		Or ItemSend = DataItemSend.Ignore Then
		
		// No overriding for a standard data processor.
		
	ElsIf TypeOf(DataElement) = Type("InformationRegisterRecordSet.SubsystemsVersions") Then
		
		If InitialImageCreating Then
			
			SubsystemsVersions = New Map;
			Query = New Query;
			Query.Text =
				"SELECT
				|	DataAreasSubsystemsVersions.Version AS Version,
				|	DataAreasSubsystemsVersions.SubsystemName
				|FROM
				|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions";
			Result = Query.Execute().Unload();
			For Each TableRow In Result Do
				SubsystemsVersions.Insert(TableRow.SubsystemName, TableRow.Version);
			EndDo;
			
			For Each SetRow In DataElement Do
				
				If SubsystemsVersions[SetRow.SubsystemName] = Undefined Then
					SetRow.Version = "";
				Else
					SetRow.Version = SubsystemsVersions[SetRow.SubsystemName];
				EndIf;
				
			EndDo;
			
		Else
			
			// Exporting the register during the initial image creation only.
			ItemSend = DataItemSend.Ignore;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("InfobaseUpdateInternalSaaS.UpdateCurrentDataArea");
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.DataAreasSubsystemsVersions);
	
EndProcedure

// See JobsQueueOverridable.OnDefineScheduledJobsUsage.
Procedure OnDefineScheduledJobsUsage(UsageTable) Export
	
	NewRow = UsageTable.Add();
	NewRow.ScheduledJob = "DataAreasUpdate";
	NewRow.Use       = True;
	
EndProcedure

// See InfobaseUpdateSSL.AfterUpdateInfobase.
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	If Common.SeparatedDataUsageAvailable() Then
		
		LockParameters = IBConnections.GetDataAreaSessionLock();
		If Not LockParameters.Use Then
			Return;
		EndIf;
		LockParameters.Use = False;
		IBConnections.SetDataAreaSessionLock(LockParameters);
		Return;
		
	EndIf;
	
	If Not ExclusiveMode() Then
		MetadataObject = Metadata.ScheduledJobs.Find("DataAreasUpdate");
		Job = ScheduledJobsServer.GetScheduledJob(MetadataObject);
		JobName = MetadataObject.Name;
		// ACC:280 Exception handling is not required.
		Try
			BackgroundJobs.Execute(Metadata.ScheduledJobs[JobName].MethodName,, Job.Key, Job.Description);
		Except
			// Meaning that the job is running. Do not handle exceptions.
			// 
		EndTry;
		// ACC:280-on
	EndIf;
	
EndProcedure

// See ExportImportDataOverridable.AfterImportData.
Procedure AfterImportData(Container) Export
	
	InformationRecords = InfobaseUpdateInternal.InfobaseUpdateInfo();
	UpdateCompleted = InformationRecords.DeferredUpdateCompletedSuccessfully;
	If UpdateCompleted <> True Then
		CheckForPendingPendingUpdateHandlers();
		InfobaseUpdateInternal.ReregisterDataForDeferredUpdate();
	EndIf;
	InfobaseUpdateInternal.CanlcelDeferredUpdateHandlersRegistration(, True);
	
EndProcedure

// Called before data export.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - a container
//    manager used for data export. For more information, see the comment
//    to ExportImportDataContainerManager handler interface.
//
Procedure BeforeExportData(Container) Export
	
	If Not Common.SubsystemExists("CloudTechnology.ExportImportData") Then
		Return;
	EndIf;
	
	FileName = Container.CreateCustomFile("xml", DataTypeForSubsystemsVersionsExportImport());
	SubsystemsVersions = New Structure();
	
	SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails().ByNames;
	For Each SubsystemDetails In SubsystemsDetails Do
		SubsystemsVersions.Insert(SubsystemDetails.Key, InfobaseUpdate.IBVersion(SubsystemDetails.Key));
	EndDo;
	
	ModuleExportImportData = Common.CommonModule("ExportImportData");
	ModuleExportImportData.WriteObjectToFile(SubsystemsVersions, FileName);
	
	Container.SetNumberOfObjects(FileName, SubsystemsVersions.Count());
	
EndProcedure

// Called before data import.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container manager used for data import.
//    For details, see comments to the API of ExportImportDataContainerManager.
//    
//
Procedure BeforeImportData(Container) Export
	
	If Not Common.SubsystemExists("CloudTechnology.ExportImportData") Then
		Return;
	EndIf;
	
	FileName = Container.GetCustomFile(DataTypeForSubsystemsVersionsExportImport());
	
	ModuleExportImportData = Common.CommonModule("ExportImportData");
	SubsystemsVersions = ModuleExportImportData.ReadObjectFromFile(FileName);
	
	BeginTransaction();
	
	Try
		
		For Each SubsystemVersion In SubsystemsVersions Do
			InfobaseUpdateInternal.SetIBVersion(SubsystemVersion.Key, SubsystemVersion.Value, (SubsystemVersion.Key = Metadata.Name));
			OnMarkDeferredUpdateHandlersRegistration(SubsystemVersion.Key, True, True);
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// See SSLSubsystemsIntegration.OnGetUpdatePriority.
Procedure OnGetUpdatePriority(Priority) Export
	Priority = Constants.DataAreasUpdatePriority.Get();
EndProcedure

// Intended to be used on form "ApplicationUpdateResult"
//
Function AreasUpdateProgressReport() Export
	
	Return "Report.DataAreasUpdateProgress.Form";
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdateHandlers

Function DataTypeForSubsystemsVersionsExportImport()
	
	Return "1cfresh\ApplicationData\SubstemVersions";
	
EndFunction

#EndRegion

#Region DataAreasUpdate

// Returns the record key for DataAreasSubsystemsVersions information register.
//
// Returns: 
//   InformationRegisterRecordKeyInformationRegisterName - the DataAreasSubsystemsVersions information register record key.
//
Function SubsystemVersionsRecordKey()
	
	KeyValues = New Structure;
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		
		KeyValues.Insert("DataAreaAuxiliaryData", ModuleSaaSOperations.SessionSeparatorValue());
		KeyValues.Insert("SubsystemName", "");
		RecordKey = ModuleSaaSOperations.CreateAuxiliaryDataInformationRegisterEntryKey(
			InformationRegisters.DataAreasSubsystemsVersions, KeyValues);
		
	EndIf;
	
	Return RecordKey;
	
EndFunction


// Selects all data areas with outdated versions
// and generates background jobs for
// updating when necessary.
//
Procedure ScheduleDataAreaUpdate()
	
	If Not Common.DataSeparationEnabled()
		Or Not Common.SubsystemExists("CloudTechnology.JobsQueue") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	MetadataVersion = Metadata.Version;
	If IsBlankString(MetadataVersion) Then
		Return;
	EndIf;
	
	SharedDataVersion = InfobaseUpdateInternal.IBVersion(Metadata.Name, True);
	If InfobaseUpdateInternal.UpdateRequired(MetadataVersion, SharedDataVersion) Then
		// Shared data is not updated. There's no point in planning the area update.
		// 
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataAreas.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|		LEFT JOIN InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
	|		ON DataAreas.DataAreaAuxiliaryData = DataAreasSubsystemsVersions.DataAreaAuxiliaryData
	|			AND (DataAreasSubsystemsVersions.SubsystemName = &SubsystemName)
	|		LEFT JOIN InformationRegister.DataAreaActivityRating AS DataAreaActivityRating
	|		ON DataAreas.DataAreaAuxiliaryData = DataAreaActivityRating.DataAreaAuxiliaryData
	|WHERE
	|	DataAreas.Status IN (VALUE(Enum.DataAreaStatuses.Used))
	|	AND ISNULL(DataAreasSubsystemsVersions.Version, """") <> &Version
	|
	|ORDER BY
	|	ISNULL(DataAreaActivityRating.Rating, 9999999),
	|	DataArea";
	Query.SetParameter("SubsystemName", Metadata.Name);
	Query.SetParameter("Version", MetadataVersion);
	Result = ExecuteQueryOutsideTransaction(Query);
	If Result.IsEmpty() Then // Preliminary reading, perhaps with dirty read parts.
		Return;
	EndIf;
	
	DataAreas = Result.Unload().UnloadColumn("DataArea");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataAreasSubsystemsVersions.DataAreaAuxiliaryData AS DataArea,
	|	DataAreasSubsystemsVersions.Version AS Version
	|FROM
	|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
	|WHERE
	|	DataAreasSubsystemsVersions.DataAreaAuxiliaryData IN (&DataArea)
	|	AND DataAreasSubsystemsVersions.SubsystemName = &SubsystemName";
	Query.SetParameter("SubsystemName", Metadata.Name);
	Query.SetParameter("DataArea", DataAreas);
	AreasVersions = New Map;
	ConfigurationVersionsInAreas = Query.Execute().Unload();
	For Each TableRow In ConfigurationVersionsInAreas Do
		AreasVersions.Insert(TableRow.DataArea, TableRow.Version);
	EndDo;
	
	YouNeedToSetTheScheduledStartTime = False;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		
		ModuleSaaSTechnology = Common.CommonModule("CloudTechnology");
		CTLLibraryVersion = ModuleSaaSTechnology.LibraryVersion();
		YouNeedToSetTheScheduledStartTime = CommonClientServer.CompareVersions(CTLLibraryVersion, "2.0.1.0") > 0;
		
		If YouNeedToSetTheScheduledStartTime Then
	
			ScheduledStartTime = CurrentUniversalDate();
			
		EndIf;
		
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		KeyValues = New Structure;
		KeyValues.Insert("DataAreaAuxiliaryData", Selection.DataArea);
		KeyValues.Insert("SubsystemName", "");
		RecordKey = ModuleSaaSOperations.CreateAuxiliaryDataInformationRegisterEntryKey(
			InformationRegisters.DataAreasSubsystemsVersions, KeyValues);
		
		LockingError = False;
		
		Block = New DataLock;
		
		LockItem = Block.Add("InformationRegister.DataAreasSubsystemsVersions");
		LockItem.SetValue("DataAreaAuxiliaryData", Selection.DataArea);
		LockItem.SetValue("SubsystemName", Metadata.Name);
		LockItem.Mode = DataLockMode.Shared;
		
		LockItem = Block.Add("InformationRegister.DataAreas");
		LockItem.SetValue("DataAreaAuxiliaryData", Selection.DataArea);
		LockItem.Mode = DataLockMode.Shared;
			
		BeginTransaction();
		Try
			Try
				LockDataForEdit(RecordKey); // The lock will be removed after the transaction is completed.
			Except
				LockingError = True;
				Raise;
			EndTry;
		
			Block.Lock();
			
			AreaStatus = ModuleSaaSOperations.DataAreaStatus(Selection.DataArea);
			AreaVersion = AreasVersions[Selection.DataArea];
			If AreaStatus = Undefined
				Or AreaStatus <> Enums["DataAreaStatuses"].Used
				Or (AreaVersion <> Undefined And AreaVersion = MetadataVersion) Then
				
				// Records do not match the original selection.
				CommitTransaction();
				Continue;
			EndIf;
			
			FilterJobs = New Structure;
			FilterJobs.Insert("MethodName", "InfobaseUpdateInternalSaaS.UpdateCurrentDataArea");
			FilterJobs.Insert("Key", "1");
			FilterJobs.Insert("DataArea", Selection.DataArea);
			Jobs = ModuleJobsQueue.GetJobs(FilterJobs);
			If Jobs.Count() > 0 Then
				// The area update job already exists.
				CommitTransaction();
				Continue;
			EndIf;
			
			HasExtensionsChangingStructure = False;
			JobStartParameters = New Array;
			
			// ACC:287-off CTL extension method is called.
			If Common.SubsystemExists("CloudTechnology.ExtensionsSaaS") Then
				ModuleExtensionsSaaS = Common.CommonModule("ExtensionsSaaS");
				ExtensionsIDs = ModuleExtensionsSaaS.ActivateDisabledExtensionsInScope(Selection.DataArea,
					HasExtensionsChangingStructure);
				JobStartParameters.Add(ExtensionsIDs);
			EndIf;
			// ACC:287-on
			
			JobParameters = New Structure;
			JobParameters.Insert("MethodName"    , "InfobaseUpdateInternalSaaS.UpdateCurrentDataArea");
			JobParameters.Insert("Parameters"    , JobStartParameters);
			JobParameters.Insert("Key"         , "1");
			JobParameters.Insert("DataArea", Selection.DataArea);
			JobParameters.Insert("ExclusiveExecution", True);
			JobParameters.Insert("RestartCountOnFailure", 3);
			
			If YouNeedToSetTheScheduledStartTime Then
				AreaTimeZone = ModuleSaaSOperations.GetTimeZoneOfDataArea(Selection.DataArea);
				JobParameters.Insert("ScheduledStartTime", ToLocalTime(ScheduledStartTime, AreaTimeZone));
				ScheduledStartTime = ScheduledStartTime + 1;
			EndIf;
			
			ModuleJobsQueue.AddJob(JobParameters);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			If LockingError Then
				Continue;
			EndIf;
			Raise;
		EndTry;
		
	EndDo;
	
EndProcedure

// Updates the infobase version in the current data area and removes the session locks (if any).
// 
//
Procedure UpdateCurrentDataArea(ActivatedExtensions = Undefined) Export
	
	If ActivatedExtensions = Undefined Then
		ActivatedExtensions = New Array;
	EndIf;
	
	HasError = False;
	SetPrivilegedMode(True);
	
	Try
		InfobaseUpdate.UpdateInfobase();
	Except
		HasError = True;
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
	EndTry;
	
	For Each Id In ActivatedExtensions Do
		
		Extensions = ConfigurationExtensions.Get(New Structure("UUID", Id), 
			ConfigurationExtensionsSource.SessionApplied);
		If Extensions.Count() = 0 Then
			Continue;
		EndIf;
		
		Extensions[0].Active = False;
		Extensions[0].Write();
		
	EndDo;
	
	If HasError Then
		Raise ErrorText;
	EndIf;
	
EndProcedure

// DataAreasUpdate scheduled job handler.
// Selects all data areas with outdated versions
// and generates background IBUpdate jobs for them when necessary.
//
Procedure DataAreasUpdate() Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	// Do not call "OnStartExecuteScheduledJob" as all required actions are performed ad-hoc.
	// 
	
	ScheduleDataAreaUpdate();
	
EndProcedure

// For internal use only.
Function EarliestDataAreaVersion() Export
	
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		ExceptionText = NStr("vi = 'Không thể gọi ra hàm %1
		                             |từ phiên làm việc có giá trị chia tách đã đặt trong mô hình dịch vụ.';
		                             |ru = 'Вызов функции %1
		                             |недоступен из сеансов с установленным значением разделителей модели сервиса.';
		                             |en = 'Cannot call function %1
		                             |from sessions where the SaaS separators value is set.'; fa = 'Cannot call function %1
		                             |from sessions where the SaaS separators value is set.';
		                             |it = 'Chiamata della funzione %1
		                             |non disponibile dalle sessioni con valore impostato dei divisori del modello di servizio.';
		                             |pl = 'Wywołanie funkcji %1
		                             |jest niedostępne z sesji z ustanowioną wartością separatorów modelu serwisu.';
		                             |tr = '%1
		                             | fonksiyonu, ayarlanmış SaaS modeli ayırıcı değeri olan oturumlardan çağırılamaz.'");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionText,
			"InfobaseUpdateInternalCached.EarliestDataAreaVersion");
		
		Raise(ExceptionText, ErrorCategory.ConfigurationError);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("SubsystemName", Metadata.Name);
	Query.Text =
	"SELECT DISTINCT
	|	DataAreasSubsystemsVersions.Version AS Version
	|FROM
	|	InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
	|WHERE
	|	DataAreasSubsystemsVersions.SubsystemName = &SubsystemName";
	
	Selection = Query.Execute().Select();
	
	EarliestIBVersion = Undefined;
	
	While Selection.Next() Do
		If CommonClientServer.CompareVersions(Selection.Version, EarliestIBVersion) > 0 Then
			EarliestIBVersion = Selection.Version;
		EndIf
	EndDo;
	
	Return EarliestIBVersion;
	
EndFunction

// For internal use only.
Procedure SetAllDataAreasVersion(LibraryID, SourceIBVersion, IBMetadataVersion)
	
	Block = New DataLock;
	Block.Add("InformationRegister.DataAreasSubsystemsVersions");
	Block.Add("InformationRegister.DataAreas");
	
	BeginTransaction();
	Try
		Block.Lock();
		
		RecordSet = InformationRegisters.DataAreasSubsystemsVersions.CreateRecordSet();
		RecordSet.Filter.SubsystemName.Set(LibraryID, True);
		RecordSet.Read();
		
		// Change existing records.
		For Each Record In RecordSet Do
			If Record.Version = SourceIBVersion Then
				Record.Version = IBMetadataVersion;
				Record.DeferredHandlersRegistrationCompleted = False;
			EndIf;
		EndDo;
		
		// Add missing records.
		Query = New Query;
		Query.Text =
		"SELECT
		|	DataAreas.DataAreaAuxiliaryData AS DataArea
		|FROM
		|	InformationRegister.DataAreas AS DataAreas
		|		LEFT JOIN InformationRegister.DataAreasSubsystemsVersions AS DataAreasSubsystemsVersions
		|		ON DataAreas.DataAreaAuxiliaryData = DataAreasSubsystemsVersions.DataAreaAuxiliaryData
		|WHERE
		|	DataAreas.Status = VALUE(Enum.DataAreaStatuses.Used)
		|	AND DataAreasSubsystemsVersions.DataAreaAuxiliaryData IS NULL";
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			Record = RecordSet.Add();
			Record.DataAreaAuxiliaryData = Selection.DataArea;
			Record.SubsystemName = LibraryID;
			Record.Version = IBMetadataVersion;			
		EndDo;
		
		RecordSet.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

Function ShouldSaveExchangePlanChanges()
	Query = New Query;
	Query.SetParameter("SubsystemName", Metadata.Name);
	Query.Text =
		"SELECT
		|	SubsystemsVersions.UpdatePlan AS UpdatePlan
		|FROM
		|	InformationRegister.SubsystemsVersions AS SubsystemsVersions
		|WHERE
		|	SubsystemsVersions.SubsystemName = &SubsystemName";
	Result = Query.Execute().Unload();
	
	If Result.Count() = 0 Then
		Return False;
	EndIf;
	
	UpdatePlan = Result[0].UpdatePlan.Get();
	If UpdatePlan = Undefined Then
		Return False;
	EndIf;
	
	If UpdatePlan.VersionTo1 = Metadata.Version Then
		Return True;
	EndIf;
	
	Return False;
EndFunction

Function DataAreaLockResult(RecordKey, AttemptNumber)
	
	Try
		LockDataForEdit(RecordKey);
	Except
		If AttemptNumber = 1 Then
			IdleTimeEnd = CurrentSessionDate() + 20;
			While CurrentSessionDate() < IdleTimeEnd Do
				// Wait till the lock is released.
			EndDo;
			Return "Repeat";
		EndIf;
		WriteLogEvent(InfobaseUpdate.EventLogEvent() + "." 
			+ NStr("vi = 'Cập nhật vùng dữ liệu';
					|ru = 'Обновление области данных';
					|en = 'Data area update'; fa = 'به‌روزرسانی ناحیه داده';
					|it = 'Aggiornamento dell''area Dati';
					|pl = 'Aktualizacja obszaru danych';
					|tr = 'Veri alanı güncellemesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise(NStr("vi = 'Chưa thực hiện cập nhật vùng dữ liệu. Đã phong tỏa việc ghi lại phiên bản vùng dữ liệu.';
					|ru = 'Обновление области данных не выполнено. Запись версий области данных заблокирована.';
					|en = 'Failed to update the data area. Saving data area versions is disabled.'; fa = 'Failed to update the data area. Saving data area versions is disabled.';
					|it = 'Failed to update the data area. Saving data area versions is disabled.';
					|pl = 'Failed to update the data area. Saving data area versions is disabled.';
					|tr = 'Veri alanı güncellenmedi. Veri alanı sürüm kaydı kilitlendi.'"));
	EndTry;
	
	Return "Success";
	
EndFunction

Procedure CheckForPendingPendingUpdateHandlers()
	
	AllDeferredHandlers = New Array;
	UpdateIterations = InfobaseUpdateInternal.UpdateIterations();
	For Each UpdateIteration In UpdateIterations Do
		FilterParameters = New Structure;
		FilterParameters.Insert("ExecutionMode", "Deferred");
		HandlersTable = UpdateIteration.Handlers;
		
		Handlers = HandlersTable.FindRows(FilterParameters);
		For Each Handler In Handlers Do
			AllDeferredHandlers.Add(Handler.Procedure);
		EndDo;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.SetParameter("Status", Enums.UpdateHandlersStatuses.Completed);
	Query.SetParameter("AllDeferred", AllDeferredHandlers);
	Query.Text =
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode
		|	AND UpdateHandlers.Status <> &Status
		|	AND NOT UpdateHandlers.HandlerName IN (&AllDeferred)";
	MissingHandlers = Query.Execute().Unload();
	
	// The following handlers runs as real-time handlers in the shared mode. Delete such handlers. 
	For Each MissingHandler In MissingHandlers Do
		RecordManager = InformationRegisters.UpdateHandlers.CreateRecordManager();
		RecordManager.HandlerName = MissingHandler.HandlerName;
		RecordManager.Delete();
	EndDo;
	
EndProcedure

Function ExecuteQueryOutsideTransaction(Val Query)
	
	If TransactionActive() Then
		Raise(NStr("vi = 'Giao tác đang hoạt động. Không thể thực hiện truy vấn ngoài giao tác.';
					|ru = 'Транзакция активна. Выполнение запроса вне транзакции невозможно.';
					|en = 'The transaction is active. Cannot execute a query outside the transaction.'; fa = 'The transaction is active. Cannot execute a query outside the transaction.';
					|it = 'La transazione è attiva. Il completamento della richiesta al di fuori della transazione non è possibile.';
					|pl = 'Transakcja jest aktywna. Wykonywanie zapytania poza transakcją nie jest możliwe.';
					|tr = 'İşlem aktif. İşlemin dışında bir sorgu yürütülemiyor.'"));
	EndIf;
	
	AttemptsNumber = 0;
	
	Result = Undefined;
	While True Do
		Try
			Result = Query.Execute(); // Reading outside a transaction. This might cause the following error:
			                                // "Could not continue scan with NOLOCK due to data movement"
			                                // In case of the error, try to read again.
			Break;
		Except
			AttemptsNumber = AttemptsNumber + 1;
			If AttemptsNumber = 5 Then
				Raise;
			EndIf;
		EndTry;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion
