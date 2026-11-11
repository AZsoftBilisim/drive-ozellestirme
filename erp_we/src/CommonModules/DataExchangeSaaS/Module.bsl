///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region SSLSubsystemsEventHandlers

// The "After determining recipients" handler.
// It is called when objects are registered in the exchange plan.
// Sets up a constant that shows whether data has been changed
// and sends a message about changes with the current data area number to the service manager.
//
// Parameters:
//   Data         - CatalogObject
//                  - DocumentObject - an object for getting values of attributes and other properties.
//   Recipients     - Array of ExchangePlanRef - exchange plan nodes.
//   ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
Procedure AfterDetermineRecipients(Data, Recipients, ExchangePlanName) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	If Common.DataSeparationEnabled() Then
		
		If Data.DataExchange.Load Then
			Return;
		EndIf;
		
		If Recipients.Count() > 0
			And DataExchangeSaaSCached.IsDataSynchronizationExchangePlan(ExchangePlanName)
			And Not Constants.DataChangesRecorded.Get() Then
			
			If ModuleSaaSOperations.SessionWithoutSeparators() Then
				
				SetDataChangeFlag();
			Else
				
				FilterOfTasks = New Structure;
				FilterOfTasks.Insert("MethodName", "DataExchangeSaaS.SetDataChangeFlag");
				FilterOfTasks.Insert("Key", "1");
				
				SetPrivilegedMode(True);
				TheTaskIsAlreadyRunning = BackgroundJobs.GetBackgroundJobs(FilterOfTasks).Count() > 0;
				If TheTaskIsAlreadyRunning Then
					
					Return;
					
				EndIf;
				
				Try
					BackgroundJobs.Execute("DataExchangeSaaS.SetDataChangeFlag",, "1");
				Except
					WriteLogEvent(NStr("vi = 'Trao đổi dữ liệu';
										|ru = 'Обмен данными';
										|en = 'Data exchange'; fa = 'تبادل داده';
										|it = 'Scambio di dati';
										|pl = 'Wymiana danych';
										|tr = 'Veri değişimi'", Common.DefaultLanguageCode()),
						EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				EndTry;
			EndIf;
			
		EndIf;
		
	Else
		
		// Export the changes for application data only
		// (separated by "DataAreaMainData").
		If StandaloneModeInternal.IsStandaloneWorkplace()
			And Not ModuleSaaSOperations.IsSeparatedMetadataObject(Data.Metadata(),
				ModuleSaaSOperations.MainDataSeparator()) Then
			
			CommonClientServer.DeleteValueFromArray(Recipients, StandaloneModeInternal.ApplicationInSaaS());
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills mapping of method names and their aliases for calling from a job queue.
//
// Parameters:
//   NamesAndAliasesMap - Map of KeyAndValue - Method names and their aliases:
//     Key is the method alias. For example, ClearDataArea.
//     Value is the name of the method to be called. For example, SaaSOperations.ClearDataArea.
//                If Undefined, it is assumed that the name matches the alias. 
//                
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("DataExchangeSaaS.SetDataChangeFlag"); 
	NamesAndAliasesMap.Insert("DataExchangeSaaS.ExecuteDataExchange");
	NamesAndAliasesMap.Insert("DataExchangeSaaS.ExecuteDataExchangeScenarioActionInFirstInfobase");
	NamesAndAliasesMap.Insert("DataExchangeSaaS.ExecuteDataExchangeScenarioActionInSecondInfobase");
	NamesAndAliasesMap.Insert("DataExchangeInternalPublication.RunDataExchangeByScenario");
	NamesAndAliasesMap.Insert("DataExchangeInternalPublication.RunTaskQueue");
	NamesAndAliasesMap.Insert("DataExchangeInternalPublication.ExportToFileTransferServiceForInfobaseNode");
	NamesAndAliasesMap.Insert("DataExchangeInternalPublication.ImportFromFileTransferServiceForInfobaseNode");

EndProcedure

// Generates the list of infobase parameters.
//
// Parameters:
//   ParametersTable - ValueTable - Table of parameter details. For column details, 
//                                         See SaaSOperations.ПолучитьТаблицуПараметровИБ.
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleSaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "AccountPasswordRecoveryAddress");
	EndIf;
	
EndProcedure

// Fills a structure with arrays of supported versions of the subsystems that can have versions.
// Subsystem names are used as structure keys.
// Implements the "InterfaceVersion" web service functionality.
// This procedure must return current version sets, therefore its body must be changed accordingly before use. See the example below.
//
// Parameters:
//   SupportedVersionsStructure - Structure - subsystem names and their corresponding sets of supported versions.
//	                                 The structure key is the name of the subsystem,
//                                   and the value is an array of supported version names.
//
// Example:
//	 // FilesTransferService
//	 VersionsArray = New Array;
//	 VersionsArray.Add("1.0.1.1");	
//	 VersionsArray.Add("1.0.2.1"); 
//	 SupportedVersionsStructure.Insert("FilesTransferService", VersionsArray);
//	 // End FilesTransferService
//
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
	
	VersionsArray = New Array;
	VersionsArray.Add("2.0.1.6");
	VersionsArray.Add("2.1.1.7");
	VersionsArray.Add("2.1.2.1");
	VersionsArray.Add("2.1.5.17");
	VersionsArray.Add("2.1.6.1");
	VersionsArray.Add("2.4.5.1");
	SupportedVersionsStructure.Insert("DataExchangeSaaS", VersionsArray);
	
	VersionsArray = New Array();
	VersionsArray.Add("1.0.0.1");
	SupportedVersionsStructure.Insert("UpdatingRulesForRegisteringObjectsInServiceModel", VersionsArray);
	
EndProcedure

// Gets a list of message handlers that are processed by the library subsystems.
// 
// Parameters:
//  Handlers - ValueTable - See the field list in MessagesExchange.NewTableOfMessageHandlers.
// 
Procedure OnDefineMessagesChannelsHandlers(Handlers) Export
	
	DataExchangeMessagesMessageHandler.GetMessagesChannelsHandlers(Handlers);
	
EndProcedure

// Adds parameters of client logic upon system startup for the data exchange subsystem in SaaS mode.
//
// Parameters:
//   Parameters - Structure - Names and values of the client startup parameters.
//                           For details, See CommonOverridable.OnAddClientParametersOnStart.
//
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	SetPrivilegedMode(True);
	
	Parameters.Insert("IsStandaloneWorkplace",
		StandaloneModeInternal.IsStandaloneWorkplace());
	Parameters.Insert("SynchronizeDataWithWebApplicationOnStart",
		StandaloneModeInternal.SynchronizeDataWithWebApplicationOnStart());
	Parameters.Insert("SynchronizeDataWithWebApplicationOnExit",
		StandaloneModeInternal.SynchronizeDataWithWebApplicationOnExit());
	Parameters.Insert("StandaloneModeParameters", StandaloneModeParametersOnExit());
	
EndProcedure

// Fills parameter structures required by the
// application client code.
//
// Parameters:
//   Parameters   - Structure - a parameter structure.
//
Procedure OnAddClientParameters(Parameters) Export
	
	AddClientRunParameters(Parameters);
	
EndProcedure

// Fills in an array of types excluded from data import and export.
//
// Parameters:
//   Types - Array of MetadataObject - metadata objects excluded from export and import.
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Constants.DataForDeferredUpdate);
	Types.Add(Metadata.Constants.ORMCachedValuesRefreshDate);
	Types.Add(Metadata.Constants.DataChangesRecorded);
	Types.Add(Metadata.Constants.SubordinateDIBNodeSettings);
	Types.Add(Metadata.Constants.LastStandaloneWorkstationPrefix);
	
	ModuleExportImportData = Common.CommonModule("ExportImportData");
	ModuleExportImportData.AddTypeExcludedFromUploadingUploads(Types,
		Metadata.Catalogs.DataExchangeScenarios, ModuleExportImportData.ActionWithLinksDoNotUnloadObject());
		
	ModuleExportImportData.AddTypeExcludedFromUploadingUploads(Types,
		Metadata.Catalogs.DataExchangesSessions, ModuleExportImportData.ActionWithLinksDoNotUnloadObject());
		
	ModuleExportImportData.AddTypeExcludedFromUploadingUploads(Types,
		Metadata.Catalogs.ExchangeMessageTransportSettings, ModuleExportImportData.ActionWithLinksDoNotUnloadObject());
		
	ModuleSaaSTechnology = Common.CommonModule("CloudTechnology");
	CTLVersion = ModuleSaaSTechnology.LibraryVersion();
	
	Types.Add(Metadata.InformationRegisters.CommonInfobasesNodesSettings);
	Types.Add(Metadata.InformationRegisters.DeleteDataExchangeTransportSettings);
	Types.Add(Metadata.InformationRegisters.DataAreaExchangeTransportSettings);
	Types.Add(Metadata.InformationRegisters.DataAreasDataExchangeMessages);
	Types.Add(Metadata.InformationRegisters.DeleteDataExchangeResults);
	Types.Add(Metadata.InformationRegisters.DataAreaDataExchangeStates);
	Types.Add(Metadata.InformationRegisters.DataAreasSuccessfulDataExchangeStates);
		
	If CommonClientServer.CompareVersions(CTLVersion, "2.0.9.0") < 0 Then
		
		Types.Add(Metadata.InformationRegisters.ArchiveOfExchangeMessages);
		Types.Add(Metadata.InformationRegisters.ObjectsDataToRegisterInExchanges);
		Types.Add(Metadata.InformationRegisters.DataExchangeTasksInternalPublication);
		Types.Add(Metadata.InformationRegisters.CommonNodeDataChanges);
		Types.Add(Metadata.InformationRegisters.SynchronizationCircuit);
		Types.Add(Metadata.InformationRegisters.ExchangeMessageArchiveSettings);
		Types.Add(Metadata.InformationRegisters.XDTODataExchangeSettings);
		Types.Add(Metadata.InformationRegisters.DataSyncEventHandlers);
		Types.Add(Metadata.InformationRegisters.ObjectsUnregisteredDuringLoop);
		Types.Add(Metadata.InformationRegisters.PredefinedNodesAliases);
		Types.Add(Metadata.InformationRegisters.SynchronizedObjectPublicIDs);
		Types.Add(Metadata.InformationRegisters.DataExchangeResults);
		Types.Add(Metadata.InformationRegisters.SystemMessageExchangeSessions);
		Types.Add(Metadata.InformationRegisters.InfobaseObjectsMaps);

	EndIf;
	
EndProcedure

// Deletes exchange message files that are not deleted due to system failures.
// Files placed more than 24 hours ago are deleted (the files are calculated based on the universal current date)
// Analyzing IR.DataAreasDataExchangeMessages.
//
Procedure OnDeleteObsoleteExchangeMessages() Export
	
	QueryText =
	"SELECT
	|	DataExchangeMessages.MessageID AS MessageID,
	|	DataExchangeMessages.MessageFileName AS FileName,
	|	DataExchangeMessages.DataAreaAuxiliaryData AS DataAreaAuxiliaryData,
	|	DataExchangeMessages.MessageStoredDate AS MessageStoredDate
	|FROM
	|	InformationRegister.DataAreasDataExchangeMessages AS DataExchangeMessages
	|WHERE
	|	DataExchangeMessages.MessageStoredDate < &UpdateDate
	|
	|ORDER BY
	|	DataAreaAuxiliaryData";
	
	UniversalDate = CurrentUniversalDate();
	
	Query = New Query;
	Query.SetParameter("UpdateDate", UniversalDate - 60 * 60 * 24);
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	SessionParameters.DataAreaUsage = True;
	DataAreaAuxiliaryData = Undefined;
	
	While Selection.Next() Do
		
		If DataAreaAuxiliaryData <> Selection.DataAreaAuxiliaryData Then
			
			DataAreaAuxiliaryData = Selection.DataAreaAuxiliaryData;
			SessionParameters.DataAreaValue = DataAreaAuxiliaryData;
			
		EndIf;
		
		CommonSettingsNode = Undefined;
		
		CommonSettingsQuery = New Query(
		"SELECT
		|	CommonInfobasesNodesSettings.InfobaseNode AS InfobaseNode
		|FROM
		|	InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
		|WHERE
		|	CommonInfobasesNodesSettings.MessageForDataMapping = &MessageForDataMapping");
		CommonSettingsQuery.SetParameter("MessageForDataMapping", Selection.MessageID);
		
		CommonSettingsSelection = CommonSettingsQuery.Execute().Select();
		If CommonSettingsSelection.Next() Then
			If Not (Selection.MessageStoredDate < UniversalDate - 60 * 60 * 24 * 7) Then
				Continue;
			EndIf;
			
			CommonSettingsNode = CommonSettingsSelection.InfobaseNode;
		EndIf;
		
		MessageFileFullName = CommonClientServer.GetFullFileName(DataExchangeServer.TempFilesStorageDirectory(), Selection.FileName);
		
		MessageFile = New File(MessageFileFullName);
		
		If MessageFile.Exists() Then
			
			Try
				DeleteFiles(MessageFile.FullName);
			Except
				WriteLogEvent(NStr("vi = 'Trao đổi dữ liệu';
									|ru = 'Обмен данными';
									|en = 'Data exchange'; fa = 'تبادل داده';
									|it = 'Scambio di dati';
									|pl = 'Wymiana danych';
									|tr = 'Veri değişimi'", Common.DefaultLanguageCode()),
					EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				Continue;
			EndTry;
		EndIf;
		
		// Deleting information about an exchange message file from the storage
		RecordStructure = New Structure;
		RecordStructure.Insert("MessageID", String(Selection.MessageID));
		InformationRegisters.DataAreasDataExchangeMessages.DeleteRecord(RecordStructure);
		
		If Not CommonSettingsNode = Undefined Then
			RecordStructure = New Structure;
			RecordStructure.Insert("InfobaseNode",          CommonSettingsNode);
			RecordStructure.Insert("MessageForDataMapping", "");
			
			DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "CommonInfobasesNodesSettings");
		EndIf;
		
	EndDo;
	
	SessionParameters.DataAreaUsage = False;
	
EndProcedure

// Gets a file from the storage by the file ID.
// If a file with the specified ID is not found, an exception is thrown.
// If the file is found, its name is returned, and the information about the file is deleted from the storage.
//
// Parameters:
//  FileID - UUID - an ID of the file being received.
//  FileName           - String - a file name from the storage.
//  DeleteFileFromStorage - Boolean - Indicates if the information about the exchange message file must be removed from the storage.
//
Procedure OnReceiveFileFromStorage(Val FileID, FileName, DeleteFileFromStorage = True) Export
	
	QueryText =
	"SELECT
	|	DataExchangeMessages.MessageFileName AS FileName
	|FROM
	|	InformationRegister.DataAreasDataExchangeMessages AS DataExchangeMessages
	|WHERE
	|	DataExchangeMessages.MessageID = &MessageID";
	
	Query = New Query;
	Query.SetParameter("MessageID", String(FileID));
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		LongDesc = NStr("vi = 'Không tìm thấy tệp có tên định danh %1.';
						|ru = 'Файл с идентификатором %1 не обнаружен.';
						|en = 'The file with ID %1 is not found.'; fa = 'The file with ID %1 is not found.';
						|it = 'File con identificatore %1 non trovato.';
						|pl = 'Plik z identyfikatorem %1 nie jest ujawniony.';
						|tr = '%1 kimlikli dosya bulunamadı.'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(LongDesc, String(FileID));
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	FileName = Selection.FileName;
	
	// Deleting information about an exchange message file from the storage
	If DeleteFileFromStorage Then
		RecordStructure = New Structure;
		RecordStructure.Insert("MessageID", String(FileID));
		InformationRegisters.DataAreasDataExchangeMessages.DeleteRecord(RecordStructure);
	EndIf;
	
EndProcedure

// Saving a file to the storage
//
// Parameters:
//   RecordStructure - Structure - names and values of the DataAreasDataExchangeMessages information register dimensions.
//
Procedure OnPutFileToStorage(Val RecordStructure) Export
	
	InformationRegisters.DataAreasDataExchangeMessages.AddRecord(RecordStructure);
	
EndProcedure

// Deleting a file from storage
//
// Parameters:
//   RecordStructure - Structure - names and values of the DataAreasDataExchangeMessages information register dimensions.
//
Procedure OnDeleteFileFromStorage(Val RecordStructure) Export
	
	DataExchangeInternal.DeleteRecordSetFromInformationRegister(RecordStructure, "DataAreasDataExchangeMessages");
	
EndProcedure

// Register built-in data handlers.
//
// When a new shared data notification is received, call procedures NewDataAvailable from modules registered with GetSuppliedDataHandlers.
// XDTODataObject Descriptor passed to the procedure.
// If NewDataAvailable sets Import to True,
//
// the data is imported, and the descriptor and the data file path are passed to the
// ProcessNewData procedure. The file is automatically deleted once the procedure is executed.
// If a file is not specified in the service manager, the parameter value is Undefined.
// 
//
// Parameters:
//   Handlers - ValueTable - Table to add handlers to. Has the following columns:
//        * DataKind - String - code of the data kind processed by the handler.
//        * HandlerCode - String - string(20) - used for recovery after a data processing error.
//        * Handler - CommonModule - a module that contains the following procedures:
//            NewDataAvailable(Descriptor, Import) Export
//            ProcessNewData(Descriptor, PathToFile) Export
//            DataProcessingCanceled(Descriptor) Export
//
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	RegisterSuppliedDataHandlers(Handlers);
	
EndProcedure

// Handler that clears the UseDataSynchronization constant.
//
// Parameters:
//  Cancel - Boolean - indicates that the synchronization disabling is canceled.
//                   If its value is True, the synchronization is not disabled.
//
Procedure OnDisableDataSynchronization(Cancel) Export
	
	Constants.UseOfflineModeSaaS.Set(False);
	Constants.UseDataSynchronizationSaaSWithLocalApplication.Set(False);
	Constants.UseDataSynchronizationSaaSWithWebApplication.Set(False);
	
EndProcedure

#EndRegion

// Checks whether shared data can be written in a standalone workstation.
// An object cannot be written in a standalone workstation if all these conditions are met:
//	1. The object is a standalone workstation.
//	2. The object is a shared metadata object.
//	3. The object is included in a standalone exchange plan.
//	4. The object is not included in an exception list.
// 
// Parameters:
//  Object - Arbitrary - Data source.
//  Cancel - Boolean - Cancel flag.
Procedure BeforeWriteCommonData(Object, Cancel) Export
	
	If Object.DataExchange.Load Then
		Return;
	EndIf;
	
	ReadOnly = False;
	StandaloneModeInternal.DefineDataChangeCapability(Object.Metadata(), ReadOnly);
	
	If ReadOnly Then
		ErrorString = NStr("vi = 'Cấm thay đổi dữ liệu không chia tách (%1) được kết nhập từ ứng dụng trong chỗ làm việc độc lập.
		|Hãy liên hệ với người quản trị.';
		|ru = 'Изменение неразделенных данных (%1), загружаемых из приложения, в Автономном рабочем месте запрещено.
		|Обратитесь к администратору.';
		|en = 'Standalone workstations don''t support modification of imported shared data (%1).
		|Please contact the administrator.'; fa = 'Standalone workstations don''t support modification of imported shared data (%1).
		|Please contact the administrator.';
		|it = 'Non è consentito modificare i dati non condivisi (%1) scaricati dall''applicazione in un luogo di lavoro offline.
		|Contattare l''amministratore.';
		|pl = 'Zmiana niepodzielonych danych (%1), pobieranych z aplikacji, na Autonomicznym miejscu pracy jest zabroniona.
		|Zwróć się do administratora.';
		|tr = 'Çevrimdışı çalışma alanında paylaşılan verilerin (%1) değiştirilmesi yasaktır. 
		| Yönetici ile iletişime geçin.'");
		ErrorString = StringFunctionsClientServer.SubstituteParametersToString(ErrorString, String(Object));
		Raise ErrorString;
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.DataSynchronizationWithWebApplication;
	Setting.UseExternalResources      = True;
	Setting.AvailableSaaS          = False;
	Setting.AvailableAtStandaloneWorkstation = True;
	
EndProcedure

Procedure ChangeTheIndicationOfTheNeedForDataExchangeInTheServiceModel(ItIsNecessaryToPerformAnExchange, AdditionalParameters = Undefined) Export
	
	ItIsNecessaryToPerformAnExchange = (ItIsNecessaryToPerformAnExchange = True); // Protect from non-Boolean values.
	
	IdleInterval = 180; // A 200-second long attempt. (180-sec timeout + 20-sec attempt to lock 1C:Enterprise.)
	AttemptsNumber = 65; // 3 hour and 30 minutes by default (12,600 seconds).
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		
		If AdditionalParameters.Property("IdleInterval") Then
			
			IdleInterval = AdditionalParameters.IdleInterval;
			
		EndIf;
		
		If AdditionalParameters.Property("AttemptsNumber") Then
			
			AttemptsNumber = AdditionalParameters.AttemptsNumber;
			
		EndIf;
		
	EndIf;
	
	DataLock = New DataLock;
	LockItem = DataLock.Add("Constant.DataChangesRecorded");
	LockItem.Mode = DataLockMode.Exclusive;
	
	TheValueOfTheConstantHasBeenChanged = False;
	For AttemptToChange = 1 To AttemptsNumber Do
		
		BeginTransaction();
		Try
			
			DataLock.Lock();
			Constants.DataChangesRecorded.Set(ItIsNecessaryToPerformAnExchange);
			TheValueOfTheConstantHasBeenChanged = True;
			
			CommitTransaction();
			Break;
			
		Except
			
			RollbackTransaction();
			If Common.SubsystemExists("CloudTechnology") Then
				
				ModuleCommonCTL = Common.CommonModule("CommonCTL");
				ModuleCommonCTL.Pause(IdleInterval);
				
			EndIf;
			
		EndTry
		
	EndDo;
	
	If Not TheValueOfTheConstantHasBeenChanged Then
		
		ExceptionText = NStr("vi = 'Lỗi phong tỏa hằng ""Ghi nhận thay đổi dữ liệu"".
			|Hãy thử lại sau.';
			|ru = 'Ошибка блокировки константы ""Зарегистрированы изменения данных"".
			|Повторите попытку позже.';
			|en = 'Cannot lock the ""Data changes recorded"" constant.
			|Try again later.'; fa = 'Cannot lock the ""Data changes recorded"" constant.
			|Try again later.';
			|it = 'Errore di blocco della costante ""Modifiche registrate ai dati"".
			|Riprovare più tardi.';
			|pl = 'Błąd blokowania stałej ""Zarejestrowano zmianę danych"".
			|Powtórz próbę później.';
			|tr = '""Veri değişiklikleri kaydedildi"" sabiti kilitleme hatası.
			|Sonra tekrar deneyin.'", Common.DefaultLanguageCode());
		
		WriteLogEvent(DataSyncronizationLogEvent(),
			EventLogLevel.Error, , , ExceptionText);
		Raise ExceptionText;
		
	EndIf;
	
EndProcedure

// Enables the flag that shows whether the data is changed and sends a message about the change with the number of the current area
// to the service manager.
//
Procedure SetDataChangeFlag() Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
	
	ModuleSaaSOperationsCTLCached = Common.CommonModule("SaaSOperationsCTLCached");
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesExchange = Common.CommonModule("MessagesExchange");
	
	SetPrivilegedMode(True);
	
	DataArea = ModuleSaaSOperations.SessionSeparatorValue();
	
	BeginTransaction();
	Try
		ModuleMessagesExchange.SendMessage("DataExchange\ManagingApplication\DataChangeFlag",
						New Structure("NodeCode", DataExchangeServer.ExchangePlanNodeCodeString(DataArea)),
						ModuleSaaSOperationsCTLCached.ServiceManagerEndpoint());
			
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	ChangeTheIndicationOfTheNeedForDataExchangeInTheServiceModel(True);
	
EndProcedure

// Fills in the passed array with the common modules used as
//  incoming message interface handlers.
//
// Parameters:
//  HandlersArray - Array - an array of handlers.
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
	
	HandlersArray.Add(MessagesDataExchangeAdministrationControlInterface);
	HandlersArray.Add(MessagesDataExchangeAdministrationManagementInterface);
	HandlersArray.Add(DataExchangeMessagesControlInterface);
	HandlersArray.Add(DataExchangeMessagesManagementInterface);
	
	If Common.SubsystemExists("CloudTechnology") Then
		ModuleMessagesDistributedCommandsExecutionInterface = Common.CommonModule(
			"MessagesDistributedCommandExecutionInterface");
		HandlersArray.Add(ModuleMessagesDistributedCommandsExecutionInterface);
	EndIf;
	
EndProcedure

// Fills in the passed array with the common modules used as
//  outgoing message interface handlers.
//
// Parameters:
//  HandlersArray - Array - an array of handlers.
//
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export
	
	HandlersArray.Add(MessagesDataExchangeAdministrationControlInterface);
	HandlersArray.Add(MessagesDataExchangeAdministrationManagementInterface);
	HandlersArray.Add(DataExchangeMessagesControlInterface);
	HandlersArray.Add(DataExchangeMessagesManagementInterface);
	
	If Common.SubsystemExists("CloudTechnology") Then
		ModuleMessagesDistributedCommandsExecutionInterface = Common.CommonModule(
			"MessagesDistributedCommandExecutionInterface");
		HandlersArray.Add(ModuleMessagesDistributedCommandsExecutionInterface);
	EndIf;
	
EndProcedure

// Infobase update handler.

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
		
	Handler = Handlers.Add();
	Handler.SharedData = True;
	Handler.HandlerManagement = True;
	Handler.Version = "*";
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "DataExchangeSaaS.FillSeparatedDataHandlers";
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "DataExchangeSaaS.SetPredefinedNodeCodes";
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.SharedData = True;
	Handler.ExclusiveMode = False;
	Handler.Procedure = "DataExchangeSaaS.LockEndpoints";

EndProcedure

// Fills in separated data handler that depends on shared data change.
//
// Parameters:
//   Parameters - Structure - a handler parameter structure:
//     * SeparatedHandlers - ValueTable
//                              - Undefined - See the description
//       of the InfobaseUpdate.NewUpdateHandlerTable function.
//       Undefined is passed upon direct call (without using the infobase version
//       update functionality).
// 
Procedure FillSeparatedDataHandlers(Parameters = Undefined) Export
	
	If Parameters <> Undefined Then
		
		Handlers = Parameters.SeparatedHandlers;
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.ExecutionMode = "Seamless";
		Handler.Procedure = "DataExchangeSaaS.SetPredefinedNodeCodes";
		
		Handlers = Parameters.SeparatedHandlers;
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.ExecutionMode = "Seamless";
		Handler.Procedure = "Catalogs.ExchangeMessageTransportSettings.ProcessDataForMigrationToNewVersion";

	EndIf;
	
EndProcedure

// Determines and sets a code and a predefined node description
// for each exchange plan used in the SaaS mode.
// The code is generated based on a separator value.
// Description - generated based on the application caption or, if the caption is blank, 
// based on the current data area presentation from the InformationRegister.DataAreas register.
//
Procedure SetPredefinedNodeCodes() Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If DataExchangeSaaSCached.IsDataSynchronizationExchangePlan(ExchangePlan.Name) Then
			
			ThisNode = ExchangePlans[ExchangePlan.Name].ThisNode();
			
			BeginTransaction();
			Try
			    Block = New DataLock;
			    LockItem = Block.Add(Common.TableNameByRef(ThisNode));
			    LockItem.SetValue("Ref", ThisNode);
			    Block.Lock();
				
				If IsBlankString(Common.ObjectAttributeValue(ThisNode, "Code")) Then
				
					LockDataForEdit(ThisNode);
					ThisNodeObject = ThisNode.GetObject();
					
					ThisNodeObject.Code = ExchangePlanNodeCodeInService(ModuleSaaSOperations.SessionSeparatorValue());
					ThisNodeObject.Description = TrimAll(GeneratePredefinedNodeDescription());
					ThisNodeObject.DataExchange.Load = True;
					ThisNodeObject.Write();
					
				EndIf;

			    CommitTransaction();
			Except
			    RollbackTransaction();
			    Raise;
			EndTry;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Locks all endpoints except for the service manager endpoint.
//
Procedure LockEndpoints() Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return;
	EndIf;
	
	ModuleSaaSOperationsCTLCached = Common.CommonModule("SaaSOperationsCTLCached");
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("ExchangePlan.MessagesExchange");
		Block.Lock();
		
		Query = New Query(
		"SELECT
		|	MessagesExchange.Ref AS Ref
		|FROM
		|	ExchangePlan.MessagesExchange AS MessagesExchange
		|WHERE
		|	NOT MessagesExchange.ThisNode
		|	AND MessagesExchange.Ref <> &ServiceManagerEndpoint
		|	AND NOT MessagesExchange.Locked");
		Query.SetParameter("ServiceManagerEndpoint", ModuleSaaSOperationsCTLCached.ServiceManagerEndpoint());
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			Endpoint = Selection.Ref.GetObject(); // ExchangePlanObject.MessagesExchange
			Endpoint.Locked = True;
			Endpoint.Write();
			
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// For internal use
//
Procedure OnSendDataToSlave(DataElement, ItemSend, Val InitialImageCreating, Recipient) Export
	
	If Recipient = Undefined 
		Or ItemSend = DataItemSend.Delete
		Or ItemSend = DataItemSend.Ignore
		Or TypeOf(DataElement) = Type("ObjectDeletion")
		Then
		
		// No overriding for a standard data processor.
		Return;
		
	EndIf;
	
	// For objects separated by an auxiliary delimiter, clear the delimiter
	// information when exporting from data area to a local workstation.
	// Previously, this was done only when creating the initial image,  
	// as there were no objects involved in recurring exchange.
	
	If Common.DataSeparationEnabled()
		And StandaloneModeInternal.IsStandaloneWorkstationNode(Recipient.Ref) Then
		
		If Not Recipient.AdditionalProperties.Property("MetadataProperties1") Then
			
			// Added for recurring exchange because, when creating the initial image, it is added from
			// StandaloneWorkstationCreationWizard.WriteInstallationPackageToTempStorage().
			Recipient.AdditionalProperties.Insert("MetadataProperties1", New Map);
			
		EndIf;
		
		ItemMetadata = DataElement.Metadata();
		
		MetadataProperties1 = Recipient.AdditionalProperties.MetadataProperties1.Get(ItemMetadata);
		If MetadataProperties1 = Undefined Then
			MetadataProperties1 = NewPropertiesOfStandaloneWorkstationMetadata(ItemMetadata);
			Recipient.AdditionalProperties.MetadataProperties1[ItemMetadata] = MetadataProperties1;
		EndIf;
		
		If MetadataProperties1.IsSeparatedMetadataObject Then
			
			If InitialImageCreating Then
				
				// When creating the initial image, separated objects are not included in
				// the image (1cv8.1CD) and will be exported separately.
				ItemSend = DataItemSend.Ignore;
				
			EndIf;
			
			If MetadataProperties1.IsSeparatedMetadataObjectAuxiliaryData Then
				
				If MetadataProperties1.IsRecordSet Then
					
					FilterElement = DataElement.Filter.Find("DataAreaAuxiliaryData");
					If FilterElement <> Undefined Then
						FilterElement.Value = 0;
					EndIf;
					
					For Each Record In DataElement Do
						Record[MetadataProperties1.AuxiliaryDataSeparator] = 0;
					EndDo;
					
				Else
					DataElement[MetadataProperties1.AuxiliaryDataSeparator] = 0;
				EndIf;
				
			EndIf;
			
			If InitialImageCreating Then
				
				StandaloneModeInternal.OpenRecordInitialImageData(Recipient);
				StandaloneModeInternal.WriteInitialImageDataElement(DataElement, MetadataProperties1, Recipient);
				StandaloneModeInternal.CloseInitialImageDataWrite(Recipient);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

//

// For internal use
//
Procedure OnSendDataToMaster(DataElement, ItemSend, Recipient) Export
	
	If ItemSend = DataItemSend.Ignore Then
		//
	ElsIf StandaloneModeInternal.IsStandaloneWorkplace() Then
		
		If TypeOf(DataElement) = Type("ObjectDeletion") Then
			
			MetadataObject = DataElement.Ref.Metadata();
			
		Else
			
			MetadataObject = DataElement.Metadata();
			
		EndIf;
		
		If Common.SubsystemExists("CloudTechnology") Then
			
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			
			If Not ModuleSaaSOperations.IsSeparatedMetadataObject(MetadataObject,
					ModuleSaaSOperations.MainDataSeparator()) Then
				
				ItemSend = DataItemSend.Ignore;
				
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// For internal use
//
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender) Export
	
	If ItemReceive = DataItemReceive.Ignore Then
		//
	ElsIf Common.DataSeparationEnabled() Then
		
		If TypeOf(DataElement) = Type("ObjectDeletion") Then
			
			MetadataObject = DataElement.Ref.Metadata();
			
		Else
			
			MetadataObject = DataElement.Metadata();
			
		EndIf;
		
		If Common.SubsystemExists("CloudTechnology") Then
			
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			
			If Not ModuleSaaSOperations.IsSeparatedMetadataObject(MetadataObject,
					ModuleSaaSOperations.MainDataSeparator()) Then
				
				ItemReceive = DataItemReceive.Ignore;
				
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

//

// Generates an application name in SaaS mode.
// 
// Returns:
//  String - Application name.
//
Function GeneratePredefinedNodeDescription() Export
	
	DefaultApplicationName = NStr("vi = 'Ứng dụng trên Internet';
									|ru = 'Приложение в Интернете';
									|en = 'Web application'; fa = 'Web application';
									|it = 'Applicazione nel internet';
									|pl = 'Aplikacja w Internecie';
									|tr = 'İnternet uygulaması'");
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return DefaultApplicationName;
	EndIf;
		
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	ApplicationName = ModuleSaaSOperations.GetAppName();
	
	Return ?(IsBlankString(ApplicationName), DefaultApplicationName, ApplicationName);
EndFunction

// Generates an exchange plan node code for the specified data area.
//
// Parameters:
//   AreaNumber - Number - a separator value. 
//
// Returns:
//   String - an exchange plan node code for the specified data area. 
//
Function ExchangePlanNodeCodeInService(Val AreaNumber) Export
	
	If TypeOf(AreaNumber) <> Type("Number") Then
		Raise NStr("vi = 'Sai kiểu tham số số [1].';
					|ru = 'Неправильный тип параметра номер [1].';
					|en = 'Invalid type in parameter number [1].'; fa = 'Invalid type in parameter number [1].';
					|it = 'Tipo errato del parametro numero [1].';
					|pl = 'Nieprawidłowy typ parametru numer [1].';
					|tr = 'Geçersiz parametre numarası [1].'");
	EndIf;
	
	Result = "S0[AreaNumber]";
	
	Return StrReplace(Result, "[AreaNumber]", Format(AreaNumber, "ND=7; NLZ=; NG=0"));
	
EndFunction

Procedure GetDataExchangesStates(TempTablesManager) Export
	
	Query = New Query(
	"SELECT
	|	DataExchangesStates.InfobaseNode AS InfobaseNode,
	|	DataExchangesStates.StartDate AS StartDate,
	|	DataExchangesStates.EndDate AS EndDate,
	|	CASE
	|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted)
	|				OR DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
	|			THEN 2
	|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed2)
	|			THEN CASE
	|					WHEN ISNULL(IssuesCount.Count, 0) > 0
	|						THEN 2
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END AS ExchangeExecutionResult
	|INTO DataExchangeStatesImport
	|FROM
	|	InformationRegister.DataAreaDataExchangeStates AS DataExchangesStates
	|		LEFT JOIN IssuesCount AS IssuesCount
	|		ON DataExchangesStates.InfobaseNode = IssuesCount.InfobaseNode
	|			AND DataExchangesStates.ActionOnExchange = IssuesCount.ActionOnExchange
	|WHERE
	|	DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataImport)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataExchangesStates.InfobaseNode AS InfobaseNode,
	|	DataExchangesStates.StartDate AS StartDate,
	|	DataExchangesStates.EndDate AS EndDate,
	|	CASE
	|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
	|			THEN 2
	|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed2)
	|			THEN CASE
	|					WHEN ISNULL(IssuesCount.Count, 0) > 0
	|						THEN 2
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END AS ExchangeExecutionResult
	|INTO DataExchangeStatesExport
	|FROM
	|	InformationRegister.DataAreaDataExchangeStates AS DataExchangesStates
	|		LEFT JOIN IssuesCount AS IssuesCount
	|		ON DataExchangesStates.InfobaseNode = IssuesCount.InfobaseNode
	|			AND DataExchangesStates.ActionOnExchange = IssuesCount.ActionOnExchange
	|WHERE
	|	DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataExport)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SuccessfulDataExchangesStates.InfobaseNode AS InfobaseNode,
	|	SuccessfulDataExchangesStates.EndDate AS EndDate
	|INTO SuccessfulDataExchangeStatesImport
	|FROM
	|	InformationRegister.DataAreasSuccessfulDataExchangeStates AS SuccessfulDataExchangesStates
	|WHERE
	|	SuccessfulDataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataImport)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SuccessfulDataExchangesStates.InfobaseNode AS InfobaseNode,
	|	SuccessfulDataExchangesStates.EndDate AS EndDate
	|INTO SuccessfulDataExchangeStatesExport
	|FROM
	|	InformationRegister.DataAreasSuccessfulDataExchangeStates AS SuccessfulDataExchangesStates
	|WHERE
	|	SuccessfulDataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataExport)	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataExchangeTasksInternalPublication.InfobaseNode AS InfobaseNode,
	|	MAX(DataExchangeTasksInternalPublication.CreationDate) AS CreationDate
	|INTO NONCompletedTasks
	|FROM
	|	InformationRegister.DataExchangeTasksInternalPublication AS DataExchangeTasksInternalPublication
	|WHERE
	|	DataExchangeTasksInternalPublication.OperationSuccessful = FALSE
	|	AND DataExchangeTasksInternalPublication.OperationFailed = FALSE
	|
	|GROUP BY
	|	DataExchangeTasksInternalPublication.InfobaseNode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataExchangeTasksInternalPublication.InfobaseNode AS InfobaseNode,
	|	MAX(DataExchangeTasksInternalPublication.CreationDate) AS CreationDate,
	|	MIN(DataExchangeTasksInternalPublication.TaskNumber) AS TaskNumber
	|INTO IncompleteTasksTasksNumbers
	|FROM
	|	NONCompletedTasks AS TempTable
	|		LEFT JOIN InformationRegister.DataExchangeTasksInternalPublication AS DataExchangeTasksInternalPublication
	|		ON TempTable.InfobaseNode = DataExchangeTasksInternalPublication.InfobaseNode
	|			AND TempTable.CreationDate = DataExchangeTasksInternalPublication.CreationDate
	|WHERE
	|	DataExchangeTasksInternalPublication.OperationSuccessful = FALSE
	|	AND DataExchangeTasksInternalPublication.OperationFailed = FALSE
	|
	|GROUP BY
	|	DataExchangeTasksInternalPublication.InfobaseNode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.InfobaseNode AS InfobaseNode,
	|	MAX(NestedQuery.CreationDate) AS CreationDate
	|INTO GroupedLastCompletedTasks
	|FROM
	|	(SELECT
	|		DataExchangeTasksInternalPublication.InfobaseNode AS InfobaseNode,
	|		DataExchangeTasksInternalPublication.CreationDate AS CreationDate
	|	FROM
	|		InformationRegister.DataExchangeTasksInternalPublication AS DataExchangeTasksInternalPublication
	|	WHERE
	|		DataExchangeTasksInternalPublication.OperationSuccessful = TRUE
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DataExchangeTasksInternalPublication.InfobaseNode,
	|		DataExchangeTasksInternalPublication.CreationDate
	|	FROM
	|		InformationRegister.DataExchangeTasksInternalPublication AS DataExchangeTasksInternalPublication
	|	WHERE
	|		DataExchangeTasksInternalPublication.OperationFailed = TRUE) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.InfobaseNode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.InfobaseNode AS InfobaseNode,
	|	MAX(NestedQuery.CreationDate) AS CreationDate,
	|	MAX(NestedQuery.TaskNumber) AS TaskNumber
	|INTO LastCompletedTasksTasksNumbers
	|FROM
	|	(SELECT
	|		DataExchangeTasksInternalPublication.InfobaseNode AS InfobaseNode,
	|		MAX(DataExchangeTasksInternalPublication.CreationDate) AS CreationDate,
	|		MAX(DataExchangeTasksInternalPublication.TaskNumber) AS TaskNumber
	|	FROM
	|		GroupedLastCompletedTasks AS GroupedLastCompletedTasks
	|			LEFT JOIN InformationRegister.DataExchangeTasksInternalPublication AS DataExchangeTasksInternalPublication
	|			ON GroupedLastCompletedTasks.InfobaseNode = DataExchangeTasksInternalPublication.InfobaseNode
	|				AND GroupedLastCompletedTasks.CreationDate = DataExchangeTasksInternalPublication.CreationDate
	|	WHERE
	|		DataExchangeTasksInternalPublication.OperationSuccessful = TRUE
	|	
	|	GROUP BY
	|		DataExchangeTasksInternalPublication.InfobaseNode
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DataExchangeTasksInternalPublication.InfobaseNode,
	|		MAX(DataExchangeTasksInternalPublication.CreationDate),
	|		MAX(DataExchangeTasksInternalPublication.TaskNumber)
	|	FROM
	|		GroupedLastCompletedTasks AS GroupedLastCompletedTasks
	|			LEFT JOIN InformationRegister.DataExchangeTasksInternalPublication AS DataExchangeTasksInternalPublication
	|			ON GroupedLastCompletedTasks.InfobaseNode = DataExchangeTasksInternalPublication.InfobaseNode
	|				AND GroupedLastCompletedTasks.CreationDate = DataExchangeTasksInternalPublication.CreationDate
	|	WHERE
	|		DataExchangeTasksInternalPublication.OperationFailed = TRUE
	|	
	|	GROUP BY
	|		DataExchangeTasksInternalPublication.InfobaseNode) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.InfobaseNode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IncompleteTasksTasksNumbers.InfobaseNode AS InfobaseNode,
	|	IncompleteTasksTasksNumbers.CreationDate AS CreationDate,
	|	IncompleteTasksTasksNumbers.TaskNumber AS TaskNumber
	|INTO OutstandingTasks
	|FROM
	|	IncompleteTasksTasksNumbers AS IncompleteTasksTasksNumbers
	|		LEFT JOIN LastCompletedTasksTasksNumbers AS LastCompletedTasksTasksNumbers
	|		ON IncompleteTasksTasksNumbers.InfobaseNode = LastCompletedTasksTasksNumbers.InfobaseNode
	|			AND IncompleteTasksTasksNumbers.CreationDate <= LastCompletedTasksTasksNumbers.CreationDate
	|			AND IncompleteTasksTasksNumbers.TaskNumber < LastCompletedTasksTasksNumbers.TaskNumber
	|WHERE
	|	LastCompletedTasksTasksNumbers.InfobaseNode IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OutstandingTasks.InfobaseNode AS InfobaseNode,
	|	DataExchangeTasksInternalPublication.Action AS Action
	|INTO CurrentNodeTasks
	|FROM
	|	OutstandingTasks AS OutstandingTasks
	|		LEFT JOIN InformationRegister.DataExchangeTasksInternalPublication AS DataExchangeTasksInternalPublication
	|		ON OutstandingTasks.InfobaseNode = DataExchangeTasksInternalPublication.InfobaseNode
	|			AND OutstandingTasks.CreationDate = DataExchangeTasksInternalPublication.CreationDate
	|			AND OutstandingTasks.TaskNumber = DataExchangeTasksInternalPublication.TaskNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP NONCompletedTasks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP IncompleteTasksTasksNumbers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GroupedLastCompletedTasks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP LastCompletedTasksTasksNumbers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OutstandingTasks");
	
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure GetMessagesToMapData(TempTablesManager) Export
	
	Query = New Query(
	"SELECT
	|	CommonInfobasesNodesSettings.InfobaseNode AS InfobaseNode,
	|	CASE
	|		WHEN COUNT(CommonInfobasesNodesSettings.MessageForDataMapping) > 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS MessageReceivedForDataMapping,
	|	MAX(DataExchangeMessages.MessageStoredDate) AS LastMessageStoragePlacementDate
	|INTO MessagesForDataMapping
	|FROM
	|	InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
	|		INNER JOIN InformationRegister.DataAreasDataExchangeMessages AS DataExchangeMessages
	|		ON (DataExchangeMessages.MessageID = CommonInfobasesNodesSettings.MessageForDataMapping)
	|
	|GROUP BY
	|	CommonInfobasesNodesSettings.InfobaseNode");
	
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure AdaptTheTextOfTheRequestAboutTheResultsOfTheExchangeInTheService(QueryText) Export
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		QueryText = StrReplace(QueryText,	"InformationRegister.DataExchangesStates", 
													"InformationRegister.DataAreaDataExchangeStates");
		
	EndIf;
	
EndProcedure

// Sends a message.
// 
// Parameters:
//  Message - XDTODataObject - a message.
// 
// Returns:
//  UUID - New session ID
//
Function SendMessage(Val Message) Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Raise NStr("vi = 'Không có bộ quản lý dịch vụ.';
					|ru = 'Отсутствует менеджер сервиса.';
					|en = 'There is no Service manager.'; fa = 'There is no Service manager.';
					|it = 'manager del servizio assente.';
					|pl = 'Brak menadżera serwisu.';
					|tr = 'Servis Yöneticisi eksik.'");
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	ModuleSaaSOperationsCTLCached = Common.CommonModule("SaaSOperationsCTLCached");
	
	Message.Body.Zone = ModuleSaaSOperations.SessionSeparatorValue();
	Message.Body.SessionId = InformationRegisters.SystemMessageExchangeSessions.NewSession();
	
	ModuleMessagesSaaS.SendMessage(Message,
		ModuleSaaSOperationsCTLCached.ServiceManagerEndpoint(),
		True);
	
	Return Message.Body.SessionId;
	
EndFunction

Procedure UpdateDataAreaTransportSettings(Parameters) Export
	
	Peer                = Parameters.Peer;
	ThisNodeCode                 = Parameters.ThisNodeCode;
	CorrespondentCode            = Parameters.CorrespondentCode;
	CorrespondentEndpoint  = Parameters.CorrespondentEndpoint;
	IsCorrespondent             = Parameters.IsCorrespondent;
	SSL200CompatibilityMode = Parameters.SSL200CompatibilityMode;
	ThisNodeAlias           = Parameters.ThisNodeAlias;
	
	If IsCorrespondent Then
		If Not IsBlankString(ThisNodeAlias) Then
			RelativeInformationExchangeDirectory = ExchangeMessagesDirectoryName(CorrespondentCode, ThisNodeAlias);
		Else
			RelativeInformationExchangeDirectory = ExchangeMessagesDirectoryName(CorrespondentCode, ThisNodeCode);
		EndIf;
	Else
		If Not IsBlankString(ThisNodeAlias) Then
			RelativeInformationExchangeDirectory = ExchangeMessagesDirectoryName(ThisNodeAlias, CorrespondentCode);
		Else
			RelativeInformationExchangeDirectory = ExchangeMessagesDirectoryName(ThisNodeCode, CorrespondentCode);
		EndIf;
	EndIf;
	
	TransportSettings = InformationRegisters.DataAreasExchangeTransportSettings.TransportSettings(CorrespondentEndpoint);
	
	If TransportSettings.DefaultExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FILE Then
		
		// Exchange using network directory
		
		FILECommonInformationExchangeDirectory = TrimAll(TransportSettings.FILEDataExchangeDirectory);
		
		If IsBlankString(FILECommonInformationExchangeDirectory) Then
			
			MessageString = NStr("vi = 'Chưa đặt thư mục trao đổi thông tin đối với điểm kết thúc ""%1"".';
								|ru = 'Не задан каталог обмена информацией для конечной точки ""%1"".';
								|en = 'The data exchange directory for the endpoint %1 is not specified.'; fa = 'The data exchange directory for the endpoint %1 is not specified.';
								|it = 'La directory di condivisione delle informazioni per l''endpoint non è specificata ""%1"".';
								|pl = 'Nie jest podany katalog wymiany informacji dla punktu końcowego ""%1"".';
								|tr = '""%1"" uç noktası için bilgi değişimi klasörü belirlenmedi.'");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(CorrespondentEndpoint));
			Raise MessageString;
		EndIf;
		
		CommonDirectory = New File(FILECommonInformationExchangeDirectory);
		
		If Not CommonDirectory.Exists() Then
			
			MessageString = NStr("vi = 'Thư mục trao đổi thông tin ""%1"" không tồn tại.';
								|ru = 'Каталог обмена информацией ""%1"" не существует.';
								|en = 'The exchange directory %1 does not exist.'; fa = 'The exchange directory %1 does not exist.';
								|it = 'La directory di condivisione delle informazioni ""%1"" non esiste.';
								|pl = 'Katalog wymiany informacji ""%1"" nie istnieje.';
								|tr = '""%1"" bilgi değişimi dizini yok.'");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, FILECommonInformationExchangeDirectory);
			Raise MessageString;
		EndIf;
		
		If Not SSL200CompatibilityMode Then
			
			FILEAbsoluteDataExchangeDirectory = CommonClientServer.GetFullFileName(
				FILECommonInformationExchangeDirectory,
				RelativeInformationExchangeDirectory);
			
			// Creating a message exchange directory
			AbsoluteDirectory = New File(FILEAbsoluteDataExchangeDirectory);
			If Not AbsoluteDirectory.Exists() Then
				CreateDirectory(AbsoluteDirectory.FullName);
			EndIf;
			
			// Saving exchange message transfer settings for the current data area
			RecordStructure = New Structure;
			RecordStructure.Insert("Peer", Peer);
			RecordStructure.Insert("CorrespondentEndpoint", CorrespondentEndpoint);
			RecordStructure.Insert("DataExchangeDirectory", RelativeInformationExchangeDirectory);
			
			InformationRegisters.DataAreaExchangeTransportSettings.UpdateRecord(RecordStructure);
		EndIf;
		
	ElsIf TransportSettings.DefaultExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then
		
		// Data exchange over a  FTP server.
		
		FTPSettings = ExchangeMessagesTransport.FTPConnectionSetup();
		FTPSettings.Server               = TransportSettings.FTPServer;
		FTPSettings.Port                 = TransportSettings.FTPConnectionPort;
		FTPSettings.UserName      = TransportSettings.FTPConnectionUser;
		FTPSettings.UserPassword   = TransportSettings.FTPConnectionPassword;
		FTPSettings.PassiveConnection  = TransportSettings.FTPConnectionPassiveConnection;
		FTPSettings.SecureConnection = DataExchangeServer.SecureConnection(TransportSettings.FTPConnectionPath);
		
		FTPConnection = ExchangeMessagesTransport.FTPConnection(FTPSettings);
		
		AbsoluteDataExchangeDirectory = CommonClientServer.GetFullFileName(
			TransportSettings.FTPPath,
			RelativeInformationExchangeDirectory);

		If Not ExchangeMessagesTransport.FTPDirectoryExist(AbsoluteDataExchangeDirectory, RelativeInformationExchangeDirectory, FTPConnection) Then
			FTPConnection.CreateDirectory(AbsoluteDataExchangeDirectory);
		EndIf;
		
		// Saving exchange message transfer settings for the current data area
		RecordStructure = New Structure;
		RecordStructure.Insert("Peer", Peer);
		RecordStructure.Insert("CorrespondentEndpoint", CorrespondentEndpoint);
		RecordStructure.Insert("DataExchangeDirectory", RelativeInformationExchangeDirectory);
		
		InformationRegisters.DataAreaExchangeTransportSettings.UpdateRecord(RecordStructure);
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không hỗ trợ dạng truyền thông điệp trao đổi ""%1"" đối với điểm cuối %2.';
				|ru = 'Вид транспорта сообщений обмена ""%1"" для конечной точки %2 не поддерживается.';
				|en = 'The endpoint %2 doesn''t support the exchange message transport type %1.'; fa = 'The endpoint %2 doesn''t support the exchange message transport type %1.';
				|it = 'La modalità di trasporto dei messaggi di scambio ""%1"" per l''endpoint %2 non è supportata.';
				|pl = 'Rodzaj transportu komunikatów wymiany ""%1"" dla punktu końcowego %2 nie jest obsługiwany.';
				|tr = 'Değişim mesajlarının ""%1"" araç türü %2 uç noktası için desteklenmiyor.'"),
			String(TransportSettings.DefaultExchangeMessagesTransportKind),
			String(CorrespondentEndpoint));
	EndIf;
		
EndProcedure

// Data synchronization setup event for the event log
// 
// Returns:
//  String - Logged event as a String
//
Function EventLogEventDataSynchronizationSetup() Export
	
	Return NStr("vi = 'Trao đổi dữ liệu trong mô hình dịch vụ.Tùy chỉnh đồng bộ dữ liệu';
				|ru = 'Обмен данными в модели сервиса.Настройка синхронизации данных';
				|en = 'Data exchange SaaS.Data synchronization setup'; fa = 'Data exchange SaaS.Data synchronization setup';
				|it = 'Scambio di dati nel modello di servizio.Configurazione della sincronizzazione dei dati';
				|pl = 'Wymiana danych w modelu serwisu.Ustawienia synchronizacji danych';
				|tr = 'SaaS modunda veri değişimi.Veri senkronizasyonu ayarı'",
		Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Export service procedures and functions

// Exports data in exchange between data areas.
//
// Parameters:
//  Cancel         - Boolean - a cancellation flag. It is set to True if an error occurs during the data export
//  Peer - ExchangePlanRef - an exchange plan node, for which data is being exported.
// 
Procedure RunDataExport(Cancel, Val Peer) Export
	
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	ExchangeParameters.ExecuteImport1 = False;
	ExchangeParameters.ExecuteExport2 = True;
	ExchangeParameters.TransportID = "SM";
	
	DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
		Peer, ExchangeParameters, Cancel);
		
EndProcedure

// Imports data in exchange between data areas.
//
// Parameters:
//  Cancel         - Boolean - a cancellation flag. It is selected if an error occurs during the data import.
//  Peer - ExchangePlanRef - an exchange plan node, for which data is imported.
// 
Procedure RunDataImport(Cancel, Val Peer, MessageForDataMapping = False) Export
	
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	ExchangeParameters.ExecuteImport1 = True;
	ExchangeParameters.ExecuteExport2 = False;
	ExchangeParameters.TransportID = "SM";
	ExchangeParameters.MessageForDataMapping = MessageForDataMapping;
	
	DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
		Peer, ExchangeParameters, Cancel);
		
EndProcedure

// Initiates data exchange between two infobases.
//
// Parameters:
//   DataExchangeScenario - ValueTable
//
Procedure ExecuteDataExchange(DataExchangeScenario) Export
	
	SetPrivilegedMode(True);
	
	// Resetting a cumulative data change flag for exchange
	ChangeTheIndicationOfTheNeedForDataExchangeInTheServiceModel(False);
	
	If DataExchangeScenario.Count() > 0 Then
		
		// Run the scenario.
		ExecuteDataExchangeScenarioActionInFirstInfobase(0, DataExchangeScenario);
		
	EndIf;
	
EndProcedure

// Executing an exchange scenario action set in a value table row for the first infobase among the infobases exchanging data.
//
// Parameters:
//   ScenarioRowIndex - Number - a row index in the DataExchangeScenario table.
//   DataExchangeScenario - ValueTable
//
Procedure ExecuteDataExchangeScenarioActionInFirstInfobase(ScenarioRowIndex, DataExchangeScenario) Export
	
	SetPrivilegedMode(True);
	
	If ScenarioRowIndex > DataExchangeScenario.Count() - 1 Then
		FinishDataExchangeScenarioExecution(ScenarioRowIndex, DataExchangeScenario);
		Return;
	EndIf;
	
	ActionToBeExecutedDetailsEL = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thực hiện một bước trong kịch bản đồng bộ (%1/%2).';
			|ru = 'Выполнение шага сценария синхронизации (%1/%2).';
			|en = 'Running synchronization scenario… Step %1/%2.'; fa = 'Running synchronization scenario… Step %1/%2.';
			|it = 'Esecuzione del passo dello scenario della sincronizzazione (%1/%2).';
			|pl = 'Wykonanie kroku scenariusza synchronizacji (%1/%2).';
			|tr = 'Senkronizasyon senaryosu adımını yürüt (%1/%2).'"), ScenarioRowIndex + 1, DataExchangeScenario.Count())
		+ Chars.LF + DataExchangeScenarioRowDetails(ScenarioRowIndex, DataExchangeScenario);
	WriteLogEvent(DataSyncronizationLogEvent(),
		EventLogLevel.Information, , , ActionToBeExecutedDetailsEL);
	
	ScenarioRow = DataExchangeScenario[ScenarioRowIndex];
	
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Cancel",          False);
	ResultingStructure.Insert("StartDate",     CurrentSessionDate());
	ResultingStructure.Insert("CompletedOn", '00010101');
	ResultingStructure.Insert("Information",     "");
	
	InfobaseNode = Undefined;
	
	If ScenarioRow.InfobaseNumber = 1 Then
		
		Try
			InfobaseNode = FindInfobaseNode(ScenarioRow.ExchangePlanName, ScenarioRow.InfobaseNodeCode);
			
			If Not DataExchangeServer.SynchronizationSetupCompleted(InfobaseNode) Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa hoàn thành tùy chỉnh đồng bộ dữ liệu trong ứng dụng ""%1"".';
						|ru = 'Настройка синхронизации данных в приложении ""%1"" не завершена.';
						|en = 'Data synchronization setup in ""%1"" is not completed.'; fa = 'Data synchronization setup in ""%1"" is not completed.';
						|it = 'L''impostazione della sincronizzazione dati in posizione ""%1"" non è completata.';
						|pl = 'Nie zakończono ustawienia synchronizacji danych w aplikacji ""%1"".';
						|tr = '""%1"" uygulamasında veri senkronizasyon ayarı tamamlanmadı.'"),
					InfobaseNode);
			ElsIf DataExchangeServer.MessageWithDataForMappingReceived(InfobaseNode) Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong ứng dụng ""%1"" đã kết nhập thông điệp để so sánh thủ công.';
						|ru = 'В приложение ""%1"" загружено сообщение для ручного сопоставления.';
						|en = 'A message that requires manual mapping has been imported to ""%1"".'; fa = 'A message that requires manual mapping has been imported to ""%1"".';
						|it = 'Nell''applicazione""%1"" è caricato il messaggio di confronto manuale.';
						|pl = 'Do aplikacji ""%1"" załadowana wiadomość dla porównania ręcznego.';
						|tr = '""%1"" uygulamasına manuel eşleştirme için mesaj yüklendi.'"),
					InfobaseNode);
			ElsIf ScenarioRow.CurrentAction = "DataImport" Then
				RunDataImport(ResultingStructure.Cancel, InfobaseNode);
			ElsIf ScenarioRow.CurrentAction = "DataExport" Then
				RunDataExport(ResultingStructure.Cancel, InfobaseNode);
			Else
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Thao tác không xác định ""%1"" khi trao đổi dữ liệu giữa các vùng dữ liệu.';
						|ru = 'Неизвестное действие ""%1"" при обмене данными между областями данных.';
						|en = 'Unknown action (%1) is detected during data exchange.'; fa = 'Unknown action (%1) is detected during data exchange.';
						|it = 'Azione sconosciuta ""%1"" quando si scambiano dati tra le aree dati.';
						|pl = 'Nieznana czynność ""%1"" podczas wymiany danych między obszarami danych.';
						|tr = 'Veri alanları arasında veri değişimi sırasında bilinmeyen ""%1"" işlemi.'"),
					ScenarioRow.CurrentAction);
			EndIf;
		Except
			ResultingStructure.Cancel = True;
			ResultingStructure.Information = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			ResultingStructure.CompletedOn = CurrentSessionDate();
			
			WriteLogEvent(DataSyncronizationLogEvent(),
				EventLogLevel.Error, , , ActionToBeExecutedDetailsEL + Chars.LF + ResultingStructure.Information);
				
			FillPropertyValues(ScenarioRow, ResultingStructure);
				
			ExecuteDataExchangeScenarioActionInFirstInfobase(ScenarioRowIndex + 1, DataExchangeScenario);
			Return;
		EndTry;
		
		ResultingStructure.CompletedOn = CurrentSessionDate();
		
		FillPropertyValues(ScenarioRow, ResultingStructure);
		
		ExecuteDataExchangeScenarioActionInFirstInfobase(ScenarioRowIndex + 1, DataExchangeScenario);
		
	ElsIf ScenarioRow.InfobaseNumber = 2 Then
		
		Try
			InfobaseNode = FindInfobaseNode(ScenarioRow.ExchangePlanName, ScenarioRow.ThisNodeCode);
			
			WSProxyDetails = CorrespondentWSProxyDetails(InfobaseNode);
			
			If WSProxyDetails.WSProxy = Undefined Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể nhận mô tả WS-proxy đối với ứng dụng ""%1"".';
						|ru = 'Не удалось получить описание WS-прокси для приложения ""%1"".';
						|en = 'Cannot get WS proxy details for ""%1"".'; fa = 'Cannot get WS proxy details for ""%1"".';
						|it = 'Non è stato possibile ottenere la descrizione WS-proxy per l''applicazione ""%1"".';
						|pl = 'Nie udało się otrzymać opis proxy WS dla aplikacji ""%1"".';
						|tr = '""%1"" uygulaması için WS proxy sunucu ayrıntıları alınamadı.'"),
					InfobaseNode);
			Else
				DataExchangeScenarioParameter = ?(WSProxyDetails.XDTOSerializationSupported,
					XDTOSerializer.WriteXDTO(DataExchangeScenario),
					ValueToStringInternal(DataExchangeScenario));
					
				WSProxyDetails.WSProxy.StartExchangeExecutionInSecondDataBase(ScenarioRowIndex, DataExchangeScenarioParameter);
			EndIf;
		Except
			ResultingStructure.Cancel = True;
			ResultingStructure.Information = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			ResultingStructure.CompletedOn = CurrentSessionDate();
			
			WriteLogEvent(DataSyncronizationLogEvent(),
				EventLogLevel.Error, , , ActionToBeExecutedDetailsEL + Chars.LF + ResultingStructure.Information);
				
			FillPropertyValues(ScenarioRow, ResultingStructure);
				
			ExecuteDataExchangeScenarioActionInFirstInfobase(ScenarioRowIndex + 1, DataExchangeScenario);
		EndTry;
		
	EndIf;
	
EndProcedure

// Executing an exchange scenario action set in a value table row for the second infobase among the infobases exchanging data.
//
// Parameters:
//   ScenarioRowIndex - Number - a row index in the DataExchangeScenario table.
//   DataExchangeScenario - ValueTable
//
Procedure ExecuteDataExchangeScenarioActionInSecondInfobase(ScenarioRowIndex, DataExchangeScenario) Export
	
	ActionToBeExecutedDetailsEL = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thực hiện một bước trong kịch bản đồng bộ (%1/%2).';
			|ru = 'Выполнение шага сценария синхронизации (%1/%2).';
			|en = 'Running synchronization scenario… Step %1/%2.'; fa = 'Running synchronization scenario… Step %1/%2.';
			|it = 'Esecuzione del passo dello scenario della sincronizzazione (%1/%2).';
			|pl = 'Wykonanie kroku scenariusza synchronizacji (%1/%2).';
			|tr = 'Senkronizasyon senaryosu adımını yürüt (%1/%2).'"), ScenarioRowIndex + 1, DataExchangeScenario.Count())
		+ Chars.LF + DataExchangeScenarioRowDetails(ScenarioRowIndex, DataExchangeScenario);
	WriteLogEvent(DataSyncronizationLogEvent(),
		EventLogLevel.Information, , , ActionToBeExecutedDetailsEL);
	
	SetPrivilegedMode(True);
	
	ScenarioRow = DataExchangeScenario[ScenarioRowIndex];
	
	If ScenarioRow.ExecutionQueueNumber = 1 Then
		// Resetting a cumulative data change flag for exchange.
		ChangeTheIndicationOfTheNeedForDataExchangeInTheServiceModel(False);
	EndIf;
	
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Cancel",          False);
	ResultingStructure.Insert("StartDate",     CurrentSessionDate());
	ResultingStructure.Insert("CompletedOn", '00010101');
	ResultingStructure.Insert("Information",     "");
	
	InfobaseNode = Undefined;
	Try
		InfobaseNode = FindInfobaseNode(ScenarioRow.ExchangePlanName, ScenarioRow.InfobaseNodeCode);
	Except
		ResultingStructure.Cancel = True;
		ResultingStructure.Information = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataSyncronizationLogEvent(),
			EventLogLevel.Error, , , ActionToBeExecutedDetailsEL + Chars.LF + ResultingStructure.Information);
			
		FinishDataExchangeScenarioExecution(ScenarioRowIndex, DataExchangeScenario, ResultingStructure);
		Return;
	EndTry;
	
	Try
		If Not DataExchangeServer.SynchronizationSetupCompleted(InfobaseNode) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa hoàn thành tùy chỉnh đồng bộ dữ liệu trong ứng dụng ""%1"".';
					|ru = 'Настройка синхронизации данных в приложении ""%1"" не завершена.';
					|en = 'Data synchronization setup in ""%1"" is not completed.'; fa = 'Data synchronization setup in ""%1"" is not completed.';
					|it = 'L''impostazione della sincronizzazione dati in posizione ""%1"" non è completata.';
					|pl = 'Nie zakończono ustawienia synchronizacji danych w aplikacji ""%1"".';
					|tr = '""%1"" uygulamasında veri senkronizasyon ayarı tamamlanmadı.'"),
				InfobaseNode);
		ElsIf DataExchangeServer.MessageWithDataForMappingReceived(InfobaseNode) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong ứng dụng ""%1"" đã kết nhập thông điệp để so sánh thủ công.';
					|ru = 'В приложение ""%1"" загружено сообщение для ручного сопоставления.';
					|en = 'A message that requires manual mapping has been imported to ""%1"".'; fa = 'A message that requires manual mapping has been imported to ""%1"".';
					|it = 'Nell''applicazione""%1"" è caricato il messaggio di confronto manuale.';
					|pl = 'Do aplikacji ""%1"" załadowana wiadomość dla porównania ręcznego.';
					|tr = '""%1"" uygulamasına manuel eşleştirme için mesaj yüklendi.'"),
				InfobaseNode);
		ElsIf ScenarioRow.CurrentAction = "DataImport" Then
			RunDataImport(ResultingStructure.Cancel, InfobaseNode);
		ElsIf ScenarioRow.CurrentAction = "DataExport" Then
			RunDataExport(ResultingStructure.Cancel, InfobaseNode);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Thao tác không xác định ""%1"" khi trao đổi dữ liệu giữa các vùng dữ liệu.';
					|ru = 'Неизвестное действие ""%1"" при обмене данными между областями данных.';
					|en = 'Unknown action (%1) is detected during data exchange.'; fa = 'Unknown action (%1) is detected during data exchange.';
					|it = 'Azione sconosciuta ""%1"" quando si scambiano dati tra le aree dati.';
					|pl = 'Nieznana czynność ""%1"" podczas wymiany danych między obszarami danych.';
					|tr = 'Veri alanları arasında veri değişimi sırasında bilinmeyen ""%1"" işlemi.'"),
				ScenarioRow.CurrentAction);
		EndIf;
	Except
		ResultingStructure.Cancel = True;
		ResultingStructure.Information = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataSyncronizationLogEvent(),
			EventLogLevel.Error, , , ActionToBeExecutedDetailsEL + Chars.LF + ResultingStructure.Information);
	EndTry;
	ResultingStructure.CompletedOn = CurrentSessionDate();
	
	FillPropertyValues(ScenarioRow, ResultingStructure);
	
	// End of scenario.
	If ScenarioRowIndex = DataExchangeScenario.Count() - 1 Then
		FinishDataExchangeScenarioExecution(ScenarioRowIndex, DataExchangeScenario, ResultingStructure);
		Return;
	EndIf;
	
	Try
		WSProxyDetails = CorrespondentWSProxyDetails(InfobaseNode);
		
		If WSProxyDetails.WSProxy = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể nhận mô tả WS-proxy đối với ứng dụng ""%1"".';
					|ru = 'Не удалось получить описание WS-прокси для приложения ""%1"".';
					|en = 'Cannot get WS proxy details for ""%1"".'; fa = 'Cannot get WS proxy details for ""%1"".';
					|it = 'Non è stato possibile ottenere la descrizione WS-proxy per l''applicazione ""%1"".';
					|pl = 'Nie udało się otrzymać opis proxy WS dla aplikacji ""%1"".';
					|tr = '""%1"" uygulaması için WS proxy sunucu ayrıntıları alınamadı.'"),
				InfobaseNode);
		Else
			DataExchangeScenarioParameter = ?(WSProxyDetails.XDTOSerializationSupported,
				XDTOSerializer.WriteXDTO(DataExchangeScenario),
				ValueToStringInternal(DataExchangeScenario));
			
			WSProxyDetails.WSProxy.StartExchangeExecutionInFirstDataBase(ScenarioRowIndex + 1, DataExchangeScenarioParameter);
		EndIf;
	Except
		ResultingStructure.Cancel = True;
		ResultingStructure.Information = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		ResultingStructure.CompletedOn = CurrentSessionDate();
		
		WriteLogEvent(DataSyncronizationLogEvent(),
			EventLogLevel.Error, , , ActionToBeExecutedDetailsEL + Chars.LF + ResultingStructure.Information);
			
		FillPropertyValues(ScenarioRow, ResultingStructure);
			
		FinishDataExchangeScenarioExecution(ScenarioRowIndex, DataExchangeScenario, ResultingStructure);
	EndTry;
	
EndProcedure

// Deletes an exchange node in the current infobase.
//
Procedure DeleteSynchronizationSetting(ExchangePlanName, CorrespondentNodeCode) Export
	
	Peer = FindInfobaseNode(ExchangePlanName, CorrespondentNodeCode);
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Xử lý xóa tùy chỉnh đồng bộ ""%1"" với ứng dụng ""%2"".';
			|ru = 'Обработка сообщения удаления настройки синхронизации ""%1"" с приложением ""%2"".';
			|en = 'Processing the message that will delete synchronization between ""%1"" and ""%2"".'; fa = 'Processing the message that will delete synchronization between ""%1"" and ""%2"".';
			|it = 'Gestire il messaggio di eliminazione delle impostazioni di sincronizzazione ""%1"" con l''applicazione ""%2"".';
			|pl = 'Przetwarzanie komunikatu usuwania ustawienia synchronizacji ""%1"" z aplikacją ""%2"".';
			|tr = '""%2"" eki olan ""%1"" senkronizasyon ayarını silme mesajını işle.'"),
		ExchangePlanName, CorrespondentNodeCode);
	
	WriteLogEvent(EventLogEventDataSynchronizationSetup(),
		EventLogLevel.Information, , , MessageText);
	
	TransportSettings = InformationRegisters.DataAreaExchangeTransportSettings.TransportSettings(Peer);
	
	If TransportSettings <> Undefined Then
		
		If TransportSettings.DefaultExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FILE Then
			
			If Not IsBlankString(TransportSettings.FILECommonInformationExchangeDirectory)
				And Not IsBlankString(TransportSettings.RelativeInformationExchangeDirectory) Then
				
				AbsoluteDataExchangeDirectory = CommonClientServer.GetFullFileName(
					TransportSettings.FILECommonInformationExchangeDirectory,
					TransportSettings.RelativeInformationExchangeDirectory);
				
				AbsoluteDirectory = New File(AbsoluteDataExchangeDirectory);
				
				Try
					DeleteFiles(AbsoluteDirectory.FullName);
				Except
					WriteLogEvent(EventLogEventDataSynchronizationSetup(),
						EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				EndTry;
				
			EndIf;
			
		ElsIf TransportSettings.DefaultExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then
			
			Try
				
				FTPSettings = ExchangeMessagesTransport.FTPConnectionSetup();
				FTPSettings.Server               = TransportSettings.FTPServer;
				FTPSettings.Port                 = TransportSettings.FTPConnectionPort;
				FTPSettings.UserName      = TransportSettings.FTPConnectionUser;
				FTPSettings.UserPassword   = TransportSettings.FTPConnectionPassword;
				FTPSettings.PassiveConnection  = TransportSettings.FTPConnectionPassiveConnection;
				FTPSettings.SecureConnection = DataExchangeServer.SecureConnection(TransportSettings.FTPConnectionPath);
				
				FTPConnection = ExchangeMessagesTransport.FTPConnection(FTPSettings);
				
				If ExchangeMessagesTransport.FTPDirectoryExist(
					TransportSettings.FTPPath,
					TransportSettings.RelativeInformationExchangeDirectory, 
					FTPConnection) Then
					
					FTPConnection.Delete(TransportSettings.FTPPath);
					
				EndIf;
				
			Except
				WriteLogEvent(EventLogEventDataSynchronizationSetup(),
					EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
			
		EndIf;
		
	EndIf;
	
	DeleteExchangePlanNode(Peer);
	
EndProcedure

Procedure DeleteExchangePlanNode(Ref) Export
	
	If Ref = Undefined Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	BeginTransaction();
	Try
		Block = New DataLock;
	    LockItem = Block.Add(Common.TableNameByRef(Ref));
	    LockItem.SetValue("Ref", Ref);
	    Block.Lock();
		
		Object = Ref.GetObject();
		
		If Object <> Undefined Then
			Object.AdditionalProperties.Insert("DeleteSyncSetting");
			Object.Delete();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(EventLogEventDataSynchronizationSetup(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Function ExchangeMessagesDirectoryName(Val Code1, Val Code2)
	
	Return StringFunctionsClientServer.SubstituteParametersToString("Exchange %1-%2", Code1, Code2);
	
EndFunction

// Registers built-in data handlers.
//
Procedure RegisterSuppliedDataHandlers(Val Handlers)
	
	Handler = Handlers.Add();
	Handler.DataKind = SuppliedDataKindID();
	Handler.HandlerCode = SuppliedDataKindID();
	Handler.Handler = DataExchangeSaaS;
	
	Handler = Handlers.Add();
	Handler.DataKind = IdOfTypeOfDataSuppliedRegistrationRules();
	Handler.HandlerCode = IdOfTypeOfDataSuppliedRegistrationRules();
	Handler.Handler = DataExchangeSaaS;
	
EndProcedure

// The procedure is called when a new data notification is received.
// In the procedure body, check whether the application requires this data. 
// If it requires, select the Import check box.
// 
// Parameters:
//   Descriptor   - XDTODataObject Descriptor.
//   ToImport    - Boolean - a return value.
//
Procedure NewDataAvailable(Val Descriptor, ToImport) Export
	
	If Descriptor.DataType = SuppliedDataKindID()
		Or Descriptor.DataType = IdOfTypeOfDataSuppliedRegistrationRules() Then
		
		SuppliedRulesDetails = ParseSuppliedDataDescriptor(Descriptor);
		
		If SuppliedRulesDetails.ConfigurationName = Metadata.Name
			And SuppliedRulesDetails.ConfigurationVersion = Metadata.Version
			And Metadata.ExchangePlans.Find(SuppliedRulesDetails.ExchangePlanName) <> Undefined
			And DataExchangeCached.ExchangePlanUsedInSaaS(SuppliedRulesDetails.ExchangePlanName)
			And DataExchangeServer.IsSeparatedSSLExchangePlan(SuppliedRulesDetails.ExchangePlanName) Then // Rules are compatible with the infobase
			
			ToImport = True;
			
		Else
			
			ToImport = False;
			
			MessageText = NStr("vi = 'Các quy tắc trao đổi có sẵn không phù hợp với cấu hình hiện tại và được dùng cho sơ đồ trao đổi %1 cấu hình %2 phiên bản %3';
								|ru = 'Поставляемые правила обмена не подходят для текущей конфигурации и предназначены для плана обмена %1 конфигурации %2 версии %3';
								|en = 'The built-in exchange rules are not intended for the current configuration. They are intended for exchange plan %1 of configuration %2 v.%3'; fa = 'The built-in exchange rules are not intended for the current configuration. They are intended for exchange plan %1 of configuration %2 v.%3';
								|it = 'Le regole di scambio fornite non sono appropriate per la configurazione corrente e sono progettate per il piano di scambio %1 di configurazione %2 della versione %3';
								|pl = 'Dostarczane reguły wymiany nie pasują do bieżącej konfiguracji i przeznaczone są dla planu wymiany %1 konfiguracji %2 wersji %3';
								|tr = 'Yerleşik değişim kuralları geçerli yapılandırma için uygun değildir ve %3 sürümü %2 yapılandırmasının %1 değişim planı için tasarlanmıştır.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
				SuppliedRulesDetails.ExchangePlanName, SuppliedRulesDetails.ConfigurationName, SuppliedRulesDetails.ConfigurationVersion);
			
			WriteLogEvent(NStr("vi = 'Các quy tắc trao đổi dữ liệu có sẵn.Đã hủy kết nhập quy tắc có sẵn';
								|ru = 'Поставляемые правила обмена данными.Загрузка поставляемых правил отменена';
								|en = 'Built-in data exchange rules.Import of built-in rules is canceled'; fa = 'Built-in data exchange rules.Import of built-in rules is canceled';
								|it = 'Regole di comunicazione fornite.Il caricamento delle regole fornite è stato annullato';
								|pl = 'Dostarczane reguły wymiany danych.Pobieranie dostarczanych reguł są anulowane';
								|tr = 'Yerleşik veri değişimi kuralları.Yerleşik kuralları yükleme iptal edildi'",
				Common.DefaultLanguageCode()), EventLogLevel.Information,,, MessageText);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure is called after calling NewDataAvailable, it parses the data.
//
// Parameters:
//   Descriptor   - XDTODataObject Descriptor.
//   PathToFile   - String, Undefined - Full name of the extracted file. 
//                  The file is automatically deleted once the procedure is completed.
//                  If a file is not specified, it is set to Undefined.
//
Procedure ProcessNewData(Val Descriptor, Val PathToFile) Export
	
	If Descriptor.DataType = SuppliedDataKindID()
		Or Descriptor.DataType = IdOfTypeOfDataSuppliedRegistrationRules() Then
		
		ProcessSuppliedExchangeRules(Descriptor, PathToFile, Descriptor.DataType);
		
	EndIf;
	
EndProcedure

// Runs if data processing is failed due to an error.
//
Procedure DataProcessingCanceled(Val Descriptor) Export 
	
EndProcedure

// Returns the ID of a built-in data kind for data exchange rules.
//
// Returns:
//   String
//
Function SuppliedDataKindID()
	
	Return "ER"; // Do not localize.
	
EndFunction

// Returns the ID of a built-in data kind for data exchange rules.
//
// Returns:
//   String
//
Function IdOfTypeOfDataSuppliedRegistrationRules()
	
	Return "RR"; // Do not localize.
	
EndFunction

Function SuppliedRulesDetails()
	
	Return New Structure("ConfigurationName, ConfigurationVersion, ExchangePlanName, Use");
	
EndFunction

Function ParseSuppliedDataDescriptor(Descriptor)
	
	SuppliedRulesDetails = SuppliedRulesDetails();
	
	For Each SuppliedDataCharacteristic In Descriptor.Properties.Property Do
		
		SuppliedRulesDetails[SuppliedDataCharacteristic.Code] = SuppliedDataCharacteristic.Value;
		
	EndDo;
	
	Return SuppliedRulesDetails;
	
EndFunction

Procedure ProcessSuppliedExchangeRules(Descriptor, PathToFile, DataKind)
	
	SetPrivilegedMode(True);
	
	// Read the characteristics of a built-in data instance.
	SuppliedRulesDetails = ParseSuppliedDataDescriptor(Descriptor);
	ExchangePlanName = SuppliedRulesDetails.ExchangePlanName;
	
	If DataKind = IdOfTypeOfDataSuppliedRegistrationRules() Then
		
		If SuppliedRulesDetails.Use Then
			DataExchangeServer.DownloadSuppliedObjectRegistrationRules(ExchangePlanName, PathToFile);
		Else
			DataExchangeServer.DeleteSuppliedObjectRegistrationRules(ExchangePlanName);
		EndIf;
		
	Else
		
		If SuppliedRulesDetails.Use Then
			DataExchangeServer.ImportSuppliedRules(ExchangePlanName, PathToFile);
		Else
			DataExchangeServer.DeleteSuppliedRules(ExchangePlanName);
		EndIf;
		
	EndIf;
	
	DataExchangeServerCall.ResetObjectsRegistrationMechanismCache();
	RefreshReusableValues();
	
EndProcedure

// Returns:
//   ExchangePlanManager
// 
Function EndpointsExchangePlanManager() Export
	
	MetadataMessagesExchange = Metadata.FindByType(Metadata.DefinedTypes.MessagesQueueEndpoint.Type.Types()[0]).FullName();
	If MetadataMessagesExchange = Undefined Then
		Raise NStr("vi = 'Chưa xác định quy tắc trao đổi các điểm cuối.';
					|ru = 'Не определен план обмена конечных точек.';
					|en = 'Endpoint exchange plan is not defined.'; fa = 'Endpoint exchange plan is not defined.';
					|it = 'Piano di scambio di endpoint non determinato.';
					|pl = 'Nie określono planu wymiany punktów końcowych.';
					|tr = 'Uç noktaların değişim planı belirlenmedi.'");
	EndIf;
	
	Return Common.ObjectManagerByFullName(MetadataMessagesExchange);
	
EndFunction

Procedure FinishDataExchangeScenarioExecution(ScenarioRowIndex, DataExchangeScenario, ResultingStructure = Undefined)
	
	WriteLogEvent(DataSyncronizationLogEvent(),
		EventLogLevel.Information, , , NStr("vi = 'Kết thúc thực hiện kịch bản đồng bộ.';
											|ru = 'Завершение выполнения сценария синхронизации.';
											|en = 'Finishing the synchronization scenario.'; fa = 'Finishing the synchronization scenario.';
											|it = 'Completamento dell''esecuzione dello scenario di sincronizzazione.';
											|pl = 'Zakończenie wykonania scenariusza synchronizacji.';
											|tr = 'Senkronizasyon komut dosyasını tamamla.'"));
		
	If Not ResultingStructure = Undefined Then
		ResultingStructure.CompletedOn = CurrentSessionDate();
		
		ScenarioRow = DataExchangeScenario[ScenarioRowIndex];
		FillPropertyValues(ScenarioRow, ResultingStructure);
	EndIf;
	
	Try
		WSServiceProxy = DataExchangeSaaSCached.GetExchangeServiceWSProxy();
		WSServiceProxy.CommitExchange(XDTOSerializer.WriteXDTO(DataExchangeScenario));
	Except
		WriteLogEvent(DataSyncronizationLogEvent(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

Function DataExchangeScenarioRowDetails(ScenarioRowIndex, DataExchangeScenario)
	
	StringStructure = New Structure;
	StringStructure.Insert("ExecutionQueueNumber");
	StringStructure.Insert("InfobaseNumber");
	StringStructure.Insert("CurrentAction");
	StringStructure.Insert("Application1Code");
	StringStructure.Insert("Application2Code");
	StringStructure.Insert("Mode");
	
	FillPropertyValues(StringStructure, DataExchangeScenario[ScenarioRowIndex]);
	
	LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'STT: %1, Ứng dụng: %2, Thao tác: %3(%4), Chế độ: %5.';
			|ru = 'ПорядковыйНомер: %1, Приложение: %2, Действие: %3(%4), Режим: %5.';
			|en = 'SequenceNumber: %1, Application: %2, Action: %3(%4), Mode: %5.'; fa = 'SequenceNumber: %1, Application: %2, Action: %3(%4), Mode: %5.';
			|it = 'ПорядковыйНомер: %1, Applicazione: %2, Azione %3(%4), Modalità: %5.';
			|pl = 'ПорядковыйНомер: %1, Aplikacja: %2, Działanie: %3(%4), Tryb: %5.';
			|tr = 'SıraNumarası: %1, Uygulama: %2, Eylem: %3(%4), Mod: %5.'"),
		StringStructure.ExecutionQueueNumber,
		?(StringStructure.InfobaseNumber = 1, StringStructure.Application1Code, StringStructure.Application2Code),
		StringStructure.CurrentAction,
		?(StringStructure.InfobaseNumber = 1, StringStructure.Application2Code, StringStructure.Application1Code),
		StringStructure.Mode);
	
	Return LongDesc;
	
EndFunction

Function CorrespondentWSProxyDetails(Peer)
	
	LongDesc = New Structure;
	LongDesc.Insert("WSProxy",                       Undefined);
	LongDesc.Insert("XDTOSerializationSupported", True);
	
	CorrespondentVersions = CorrespondentVersions(Peer);
		
	If CorrespondentVersions.Find("2.4.5.1") <> Undefined Then
		
		LongDesc.WSProxy = DataExchangeSaaSCached.GetWSProxyOfCorrespondent_2_4_5_1(Peer);
		
	ElsIf CorrespondentVersions.Find("2.1.6.1") <> Undefined Then
		
		LongDesc.WSProxy = DataExchangeSaaSCached.GetWSProxyOfCorrespondent_2_1_6_1(Peer);
	
	ElsIf CorrespondentVersions.Find("2.0.1.6") <> Undefined Then
		
		LongDesc.WSProxy = DataExchangeSaaSCached.GetWSProxyOfCorrespondent_2_0_1_6(Peer);
		
	Else
		
		LongDesc.WSProxy = DataExchangeSaaSCached.GetWSProxyOfCorrespondent(Peer);
		LongDesc.XDTOSerializationSupported = False;
		
	EndIf;
	
	Return LongDesc;
	
EndFunction

// For internal use
//
Procedure CreateExchangeSetting(ConnectionSettings,
			IsCorrespondent = False,
			SSL200CompatibilityMode = False,
			ThisNodeAlias = "") Export
			
	ThisNodeCode = Common.ObjectAttributeValue(ExchangePlans[ConnectionSettings.ExchangePlanName].ThisNode(), "Code");
	// Checking whether code is specified for the current node
	If IsBlankString(ThisNodeCode) Then
		// The node code is set in the infobase update handler
		MessageString = NStr("vi = 'Đối với nút trao đổi dữ liệu định trước ""%1"" chưa đặt mã.';
							|ru = 'Для предопределенного узла плана обмена ""%1"" не задан код.';
							|en = 'Code of the predefined exchange plan node %1 is not specified.'; fa = 'Code of the predefined exchange plan node %1 is not specified.';
							|it = 'Non è stato specificato alcun codice per il nodo ""%1""predefinito del piano di scambio.';
							|pl = 'Dla predefiniowanego węzła planu wymiany ""%1"" nie jest ustawiony kod.';
							|tr = '""%1"" önceden tanımlanmış değişim planı düğümü için kod belirlenmedi.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ConnectionSettings.ExchangePlanName);
		Raise MessageString;
	EndIf;
	
	// Creating or updating a correspondent node
	Peer = ExchangePlans[ConnectionSettings.ExchangePlanName].FindByCode(ConnectionSettings.CorrespondentCode);
			
	BeginTransaction();
	Try
		If Not Peer.IsEmpty() Then
			Block = New DataLock;
		    LockItem = Block.Add(Common.TableNameByRef(Peer));
		    LockItem.SetValue("Ref", Peer);
		    Block.Lock();
		EndIf;
		
		// Checking a prefix of the current infobase
		If IsBlankString(GetFunctionalOption("InfobasePrefix")) Then
			If IsBlankString(ConnectionSettings.Prefix) Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Để tiếp tục tùy chỉnh đồng bộ dữ liệu, cần
					|đặt tiền tố cơ sở thông tin trong ứng dụng ""%1"".';
					|ru = 'Для продолжения настройки синхронизации данных необходимо
					|задать префикс информационной базы в приложении ""%1"".';
					|en = 'To continue data synchronization setup,
					|specify an infobase prefix in ""%1"".'; fa = 'To continue data synchronization setup,
					|specify an infobase prefix in ""%1"".';
					|it = 'Per continuare a configurare la sincronizzazione dei dati, è necessario
					|impostare il prefisso del database di informazioni nell''applicazione ""%1"".';
					|pl = 'Aby kontynuować konfigurację synchronizacji danych, należy
					|ustawić prefiks bazy informacji w aplikacji „%1”.';
					|tr = 'Veri senkronizasyonu ayarını sürdürmek için
					| ""%1"" uygulamasında Infobase''in ön ekini belirleyin.'"),
					Metadata.Synonym);
			EndIf;
				
			DataExchangeServer.SetInfobasePrefix(ConnectionSettings.Prefix);
		EndIf;
		
		CheckCode = False;
		
		If Peer.IsEmpty() Then
			CorrespondentObject = ExchangePlans[ConnectionSettings.ExchangePlanName].CreateNode();
			CorrespondentObject.Code = ConnectionSettings.CorrespondentCode;
			CheckCode = True;
		Else
			LockDataForEdit(Peer);
			CorrespondentObject = Peer.GetObject();
		EndIf;
		
		CorrespondentObject.Description = ConnectionSettings.PeerInfobaseName;
		
		DataExchangeEvents.SetNodeFilterValues(CorrespondentObject, ConnectionSettings.Settings);
		
		CorrespondentObject.SentNo = 0;
		CorrespondentObject.ReceivedNo     = 0;
		
		CorrespondentObject.RegisterChanges = True;
		
		CorrespondentObject.DataExchange.Load = True;
		CorrespondentObject.Write();
		
		If Not IsBlankString(ThisNodeAlias) Then
			RegisterManager = Common.CommonModule("InformationRegisters.PredefinedNodesAliases");
			VirtualCodes = RegisterManager.CreateRecordSet();
			VirtualCode = VirtualCodes.Add();
			VirtualCode.Peer = CorrespondentObject.Ref;
			VirtualCode.NodeCode       = ThisNodeAlias;
			
			VirtualCodes.Write();
		EndIf;
		
		If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
			
			DatabaseObjectsTable = DataExchangeXDTOServer.SupportedObjectsInFormat(ConnectionSettings.ExchangePlanName,
				"SendReceive", CorrespondentObject.Ref);
			CorrespondentObjectsTable = DatabaseObjectsTable.CopyColumns();
			
			For Each BaseObjectsRow In DatabaseObjectsTable Do
				CorrespondentObjectsRow = CorrespondentObjectsTable.Add();
				FillPropertyValues(CorrespondentObjectsRow, BaseObjectsRow, "Version, Object");
				CorrespondentObjectsRow.Send  = BaseObjectsRow.Receive;
				CorrespondentObjectsRow.Receive = BaseObjectsRow.Send;
			EndDo;
			
			XDTOSettingManager = Common.CommonModule("InformationRegisters.XDTODataExchangeSettings");
			XDTOSettingManager.UpdateSettings2(
				CorrespondentObject.Ref, "SupportedObjects", DatabaseObjectsTable);
			XDTOSettingManager.UpdateCorrespondentSettings(
				CorrespondentObject.Ref, "SupportedObjects", CorrespondentObjectsTable);
			
			RecordStructure = New Structure;
			RecordStructure.Insert("InfobaseNode",       CorrespondentObject.Ref);
			RecordStructure.Insert("CorrespondentExchangePlanName", ConnectionSettings.ExchangePlanName);
			
			DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "XDTODataExchangeSettings");
		EndIf;
		
		// Shared node data.
		InformationRegisters.CommonInfobasesNodesSettings.UpdatePrefixes(
			CorrespondentObject.Ref,
			ConnectionSettings.Prefix);
			
		If Not DataExchangeServer.SynchronizationSetupCompleted(CorrespondentObject.Ref) Then
			DataExchangeServer.CompleteDataSynchronizationSetup(CorrespondentObject.Ref);
		EndIf;
		
		Peer = CorrespondentObject.Ref;
		
		ActualCorrespondentCode = Common.ObjectAttributeValue(Peer, "Code");
		
		If CheckCode And ConnectionSettings.CorrespondentCode <> ActualCorrespondentCode Then
			
			MessageString = NStr("vi = 'Lỗi ấn định mã cho nút của cơ sở trao đổi dữ liệu.
				|Giá trị ấn định ""%1""
				|Giá trị thực tế ""%2"".';
				|ru = 'Ошибка назначения кода узла корреспондента.
				|Назначенное значение ""%1""
				|Фактическое значение ""%2"".';
				|en = 'Error assigning ID to a peer infobase node.
				|Assigned ID: %1.
				|Actual ID: %2.'; fa = 'Error assigning ID to a peer infobase node.
				|Assigned ID: %1.
				|Actual ID: %2.';
				|it = 'Assegnazione del codice host corrispondente non riuscita.
				|Valore assegnato ""%1""
				|Valore effettivo ""%2"".';
				|pl = 'Błąd przeznaczenia kodu węzła korespondenta.
				|Określona wartość ""%1""
				|Wartość faktyczna ""%2"".';
				|tr = 'Muhabir düğüm kodu ataması başarısız oldu.
				|Atanan değer ""%1""
				|Gerçek değer ""%2"".'");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
				ConnectionSettings.CorrespondentCode, ActualCorrespondentCode);
			Raise MessageString;
		EndIf;
		
		// Operations with transport settings.
		Parameters = New Structure;
		Parameters.Insert("Peer", Peer);
		Parameters.Insert("ThisNodeCode", ThisNodeCode);
		Parameters.Insert("CorrespondentCode", ConnectionSettings.CorrespondentCode);
		Parameters.Insert("CorrespondentEndpoint", ConnectionSettings.CorrespondentEndpoint);
		Parameters.Insert("IsCorrespondent", IsCorrespondent);
		Parameters.Insert("SSL200CompatibilityMode", SSL200CompatibilityMode);
		Parameters.Insert("ThisNodeAlias", ThisNodeAlias);
		
		UpdateDataAreaTransportSettings(Parameters);
		
		ConnectionSettings.Peer = Peer;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure CreateExchangeSetting_3_0_1_1(ConnectionSettings,
		IsCorrespondent = False,
		SSL200CompatibilityMode = False,
		ThisNodeAlias = "") Export
		
	ThisNodeCode = ConnectionSettings.SourceInfobaseID;
	
	// Checking whether code is specified for the current node.
	If IsBlankString(ThisNodeCode) Then
		// The node code is set in the infobase update handler.
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối với nút trao đổi dữ liệu định trước ""%1"" chưa đặt mã.';
				|ru = 'Для предопределенного узла плана обмена ""%1"" не задан код.';
				|en = 'Code of the predefined exchange plan node %1 is not specified.'; fa = 'Code of the predefined exchange plan node %1 is not specified.';
				|it = 'Non è stato specificato alcun codice per il nodo ""%1""predefinito del piano di scambio.';
				|pl = 'Dla predefiniowanego węzła planu wymiany ""%1"" nie jest ustawiony kod.';
				|tr = '""%1"" önceden tanımlanmış değişim planı düğümü için kod belirlenmedi.'"),
			ConnectionSettings.ExchangePlanName);
	EndIf;
		
	SetPrefix = False;
	If IsBlankString(DataExchangeServer.InfobasePrefix()) Then
		If IsBlankString(ConnectionSettings.Prefix) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để tiếp tục tùy chỉnh đồng bộ dữ liệu, cần
				|đặt tiền tố cơ sở thông tin trong ứng dụng ""%1"".';
				|ru = 'Для продолжения настройки синхронизации данных необходимо
				|задать префикс информационной базы в приложении ""%1"".';
				|en = 'To continue data synchronization setup,
				|specify an infobase prefix in ""%1"".'; fa = 'To continue data synchronization setup,
				|specify an infobase prefix in ""%1"".';
				|it = 'Per continuare a configurare la sincronizzazione dei dati, è necessario
				|impostare il prefisso del database di informazioni nell''applicazione ""%1"".';
				|pl = 'Aby kontynuować konfigurację synchronizacji danych, należy
				|ustawić prefiks bazy informacji w aplikacji „%1”.';
				|tr = 'Veri senkronizasyonu ayarını sürdürmek için
				| ""%1"" uygulamasında Infobase''in ön ekini belirleyin.'"),
				Metadata.Synonym);
		EndIf;
		
		SetPrefix = True;
	Else
		ConnectionSettings.Prefix = DataExchangeServer.InfobasePrefix();
	EndIf;
	
	// Creating or updating a correspondent node.
	Peer = ExchangePlans[ConnectionSettings.ExchangePlanName].FindByCode(
		ConnectionSettings.DestinationInfobaseID);
	
	BeginTransaction();
	Try
		If Not Peer.IsEmpty() Then
			Block = New DataLock;
		    LockItem = Block.Add(Common.TableNameByRef(Peer));
		    LockItem.SetValue("Ref", Peer);
		    Block.Lock();
		EndIf;
		
		If SetPrefix Then
			DataExchangeServer.SetInfobasePrefix(ConnectionSettings.Prefix);
		EndIf;
		
		CheckCode = False;
		If Peer.IsEmpty() Then
			CorrespondentObject = ExchangePlans[ConnectionSettings.ExchangePlanName].CreateNode();
			CorrespondentObject.Code = ConnectionSettings.DestinationInfobaseID;
			
			If Common.HasObjectAttribute("SettingsMode", CorrespondentObject.Metadata())
				And ConnectionSettings.Property("SettingID") Then
				CorrespondentObject.SettingsMode = ConnectionSettings.SettingID;
			EndIf;
			
			CheckCode = True;
		Else
			LockDataForEdit(Peer);
			CorrespondentObject = Peer.GetObject();
		EndIf;
		
		CorrespondentObject.Description = ConnectionSettings.PeerInfobaseName;
		
		If CheckCode Then
			CorrespondentObject.Fill(Undefined);
		EndIf;
		
		CorrespondentObject.SentNo = 0;
		CorrespondentObject.ReceivedNo     = 0;
		
		CorrespondentObject.RegisterChanges = True;
		
		// Exchange format version.
		If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName)
			And ConnectionSettings.Property("XDTOCorrespondentSettings") Then
			
			CorrespondentObject.ExchangeFormatVersion = DataExchangeXDTOServer.MaxCommonFormatVersion(
				ConnectionSettings.ExchangePlanName, ConnectionSettings.XDTOCorrespondentSettings.SupportedVersions);
				
		EndIf;
		
		CorrespondentObject.DataExchange.Load = True;
		CorrespondentObject.Write();
		
		Peer = CorrespondentObject.Ref;
		
		// XDTO correspondent settings.
		If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
			
			If ConnectionSettings.Property("XDTOCorrespondentSettings") Then
				InformationRegisters.XDTODataExchangeSettings.UpdateCorrespondentSettings(Peer,
					"SupportedObjects",
					ConnectionSettings.XDTOCorrespondentSettings.SupportedObjects.Get());
			EndIf;
			
			InformationRegisters.XDTODataExchangeSettings.UpdateCorrespondentSettings(Peer,
				"CorrespondentDataArea",
				ConnectionSettings.CorrespondentDataArea);
			
			RecordStructure = New Structure;
			RecordStructure.Insert("InfobaseNode",       Peer);
			RecordStructure.Insert("CorrespondentExchangePlanName", ConnectionSettings.ExchangePlanName);
			
			DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "XDTODataExchangeSettings");
			
		EndIf;
		
		// Shared node data.
		InformationRegisters.CommonInfobasesNodesSettings.UpdatePrefixes(
			Peer,
			ConnectionSettings.Prefix,
			ConnectionSettings.CorrespondentPrefix);
			
		If Not IsBlankString(ThisNodeAlias) Then
			RegisterManager = Common.CommonModule("InformationRegisters.PredefinedNodesAliases");
			VirtualCodes = RegisterManager.CreateRecordSet();
			VirtualCode = VirtualCodes.Add();
			VirtualCode.Peer = Peer;
			VirtualCode.NodeCode       = ThisNodeAlias;
			
			VirtualCodes.Write();
		EndIf;
		
		ActualCorrespondentCode = Common.ObjectAttributeValue(Peer, "Code");
		
		If CheckCode
			And ConnectionSettings.DestinationInfobaseID <> ActualCorrespondentCode Then
			MessageString = NStr("vi = 'Lỗi ấn định mã cho nút cơ sở trao đổi dữ liệu.
				|Giá trị ấn định ""%1""
				|Giá trị thực tế ""%2"".';
				|ru = 'Ошибка назначения кода узла корреспондента.
				|Назначенное значение ""%1""
				|Фактическое значение ""%2"".';
				|en = 'Error assigning ID to a peer infobase node.
				|Assigned ID: %1.
				|Actual ID: %2.'; fa = 'Error assigning ID to a peer infobase node.
				|Assigned ID: %1.
				|Actual ID: %2.';
				|it = 'Assegnazione del codice host corrispondente non riuscita.
				|Valore assegnato ""%1""
				|Valore effettivo ""%2"".';
				|pl = 'Błąd przeznaczenia kodu węzła korespondenta.
				|Określona wartość ""%1""
				|Wartość faktyczna ""%2"".';
				|tr = 'Muhabir düğüm kodu ataması başarısız oldu.
				|Atanan değer ""%1""
				|Gerçek değer ""%2"".'");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
				ConnectionSettings.DestinationInfobaseID,
				ActualCorrespondentCode);
			Raise MessageString;
		EndIf;
		
		// Operations with transport settings.
		Parameters = New Structure;
		Parameters.Insert("Peer", Peer);
		Parameters.Insert("ThisNodeCode", ThisNodeCode);
		Parameters.Insert("CorrespondentCode", ConnectionSettings.DestinationInfobaseID);
		Parameters.Insert("CorrespondentEndpoint", ConnectionSettings.CorrespondentEndpoint);
		Parameters.Insert("IsCorrespondent", IsCorrespondent);
		Parameters.Insert("SSL200CompatibilityMode", SSL200CompatibilityMode);
		Parameters.Insert("ThisNodeAlias", ThisNodeAlias);
		
		UpdateDataAreaTransportSettings(Parameters);
				
		TransportSettings = New Structure;
		TransportSettings.Insert("CorrespondentEndpoint", ConnectionSettings.CorrespondentEndpoint);
		TransportSettings.Insert("PeerInfobaseName", ConnectionSettings.PeerInfobaseName);
		TransportSettings.Insert("CorrespondentDataArea", ConnectionSettings.CorrespondentDataArea);
		TransportSettings.Insert("InternalPublication", False);
				
		ExchangeMessagesTransport.SaveTransportSettings(Peer, "SM", TransportSettings, True);
		
		ConnectionSettings.Peer = Peer;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Updates settings and sets default values for a node
//
Procedure UpdateExchangeSetting(
		Val Peer,
		Val DefaultNodeValues) Export
	
	BeginTransaction();
	Try
	    Block = New DataLock;
	    LockItem = Block.Add(Common.TableNameByRef(Peer));
	    LockItem.SetValue("Ref", Peer);
	    Block.Lock();
	    
		LockDataForEdit(Peer);
		CorrespondentObject = Peer.GetObject();

	    // Set default values. 
		DataExchangeEvents.SetDefaultNodeValues(CorrespondentObject, DefaultNodeValues);
		
		CorrespondentObject.AdditionalProperties.Insert("GettingExchangeMessage");
		CorrespondentObject.Write();

	    CommitTransaction();
	Except
	    RollbackTransaction();
	    Raise;
	EndTry;
	
EndProcedure

// Saves session data and sets the CompletedSuccessfully flag value to True
//
Procedure SaveSessionData(Val Message, Val Presentation = "") Export
	
	If Not IsBlankString(Presentation) Then
		Presentation = " "+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '{%1}';
																							|ru = '{%1}';
																							|en = '{%1}'; fa = '{%1}';
																							|it = '{%1}';
																							|pl = '{%1}';
																							|tr = '{%1}'"), Presentation);
	EndIf;
	
	MessageString = NStr("vi = 'Đã kết thúc thành công phiên trao đổi thông điệp của hệ thống ""%1"".%2';
						|ru = 'Сессия обмена сообщениями системы ""%1"" успешно завершена.%2';
						|en = 'Message exchange session %1 is completed. %2'; fa = 'Message exchange session %1 is completed. %2';
						|it = 'La sessione di messaggistica di sistema ""%1"" è stata completata con successo.%2';
						|pl = 'Sesja wymiany komunikatów systemu ""%1"" jest pomyślnie zakończona.%2';
						|tr = '""%1"" sisteminin mesaj değişimi oturumu tamamlandı.%2'",
		Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
		String(Message.Body.SessionId), Presentation);
	WriteLogEvent(EventLogEventSystemMessagesExchangeSessions(),
		EventLogLevel.Information,,, MessageString);
	InformationRegisters.SystemMessageExchangeSessions.SaveSessionData(Message.Body.SessionId, Message.Body.Data);
	
EndProcedure

// Sets the CompletedSuccessfully flag value to True for a session passed to the procedure
//
Procedure CommitSuccessfulSession(Val Message, Val Presentation = "") Export
	
	If Not IsBlankString(Presentation) Then
		Presentation = " " + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '{%1}';
																							|ru = '{%1}';
																							|en = '{%1}'; fa = '{%1}';
																							|it = '{%1}';
																							|pl = '{%1}';
																							|tr = '{%1}'"), Presentation);
	EndIf;
	
	MessageString = NStr("vi = 'Đã kết thúc thành công phiên trao đổi thông điệp của hệ thống ""%1"".%2';
						|ru = 'Сессия обмена сообщениями системы ""%1"" успешно завершена.%2';
						|en = 'Message exchange session %1 is completed. %2'; fa = 'Message exchange session %1 is completed. %2';
						|it = 'La sessione di messaggistica di sistema ""%1"" è stata completata con successo.%2';
						|pl = 'Sesja wymiany komunikatów systemu ""%1"" jest pomyślnie zakończona.%2';
						|tr = '""%1"" sisteminin mesaj değişimi oturumu tamamlandı.%2'",
		Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
		String(Message.Body.SessionId), Presentation);
	WriteLogEvent(EventLogEventSystemMessagesExchangeSessions(),
		EventLogLevel.Information,,, MessageString);
	InformationRegisters.SystemMessageExchangeSessions.CommitSuccessfulSession(Message.Body.SessionId);
	
EndProcedure

// Sets the CompletedWithError flag value to False for a session passed to the procedure
//
Procedure CommitUnsuccessfulSession(Val Message, Val Presentation = "") Export
	
	If Not IsBlankString(Presentation) Then
		Presentation = " " + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '{%1}';
																							|ru = '{%1}';
																							|en = '{%1}'; fa = '{%1}';
																							|it = '{%1}';
																							|pl = '{%1}';
																							|tr = '{%1}'"), Presentation);
	EndIf;
	
	MessageString = NStr("vi = 'Lỗi thực hiện phiên trao đổi thông điệp của hệ thống ""%1"".%2
		|Mô tả lỗi từ cơ sở trao đổi dữ liệu: %3';
		|ru = 'Ошибка выполнения сессии обмена сообщениями системы ""%1"".%2
		|Описание ошибки из корреспондента: %3';
		|en = 'Message exchange failed. Session: %1. %2.
		|Error details from the peer infobase: %3'; fa = 'Message exchange failed. Session: %1. %2.
		|Error details from the peer infobase: %3';
		|it = 'Impossibile eseguire la sessione di messaggistica di sistema ""%1"".%2
		|Descrizione dell''errore del corrispondente: %3';
		|pl = 'Błąd wykonania sesji wymiany komunikatów systemu ""%1"".%2
		|Opis błędu z korespondenta: %3';
		|tr = '""%1"" sisteminin mesaj değişimi oturumunu yürütme hatası.%2
		|Hatanın ilgili kişiden açıklaması:%3'", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
		String(Message.Body.SessionId), Presentation, Message.Body.ErrorDescription);
	WriteLogEvent(EventLogEventSystemMessagesExchangeSessions(),
		EventLogLevel.Error,,, MessageString);
		
	InformationRegisters.SystemMessageExchangeSessions.CommitUnsuccessfulSession(
		Message.Body.SessionId, Message.Body.ErrorDescription);
	
EndProcedure

// Returns a minimum required platform version
// 
// Returns:
//  String 
//
Function RequiredPlatformVersion() Export
	
	PlatformVersion = "";
	DataExchangeSaaSOverridable.OnDefineRequiredApplicationVersion(PlatformVersion);
	If ValueIsFilled(PlatformVersion) Then
		Return PlatformVersion;
	EndIf;

	PlatformVersion = StandardSubsystemsServer.CompatibilityModeVersion();
	PlatformVersion = StrSplit(PlatformVersion, ".");
	
	// Deleting an additional number (last number) from the version number
	PlatformVersion.Delete(3);
	Return StrConcat(PlatformVersion, ".");
	
EndFunction

// Data synchronization monitor event for the event log
// 
// Returns:
//  String - Logged event as a String
//
Function EventLogEventDataSynchronizationMonitor() Export
	
	Return NStr("vi = 'Trao đổi dữ liệu trong mô hình dịch vụ.Kiểm soát đồng bộ dữ liệu';
				|ru = 'Обмен данными в модели сервиса.Монитор синхронизации данных';
				|en = 'Data exchange SaaS.Data synchronization monitor'; fa = 'Data exchange SaaS.Data synchronization monitor';
				|it = 'Scambio di dati nel modello di servizio.Pannello di controllo della sincronizzazione dei dati';
				|pl = 'Wymiana danych w modelu serwisu.Monitor synchronizacji danych';
				|tr = 'SaaS modunda veri değişimi.Veri senkronizasyonu izleyicisi'",
		Common.DefaultLanguageCode());
	
EndFunction

// Data synchronization event for the event log
// 
// Returns:
//  String - Logged event as a String
//
Function DataSyncronizationLogEvent() Export
	
	Return NStr("vi = 'Trao đổi dữu liệu trong mô hình dịch vụ.Đồng bộ dữ liệu';
				|ru = 'Обмен данными в модели сервиса.Синхронизация данных';
				|en = 'Data exchange SaaS.Data synchronization'; fa = 'Data exchange SaaS.Data synchronization';
				|it = 'Scambio di dati nel modello di servizio.Sincronizzazione dei dati';
				|pl = 'Wymiana danych w modelu serwisu.Synchronizacja danych';
				|tr = 'SaaS modunda veri değişimi.Veri senkronizasyonu'",
		Common.DefaultLanguageCode());
	
EndFunction

Function EventLogEventSystemMessagesExchangeSessions()
	
	Return NStr("vi = 'Trao đổi dữ liệu trong mô hình dịch vụ.Phiên trao đổi thông điệp hệ thống';
				|ru = 'Обмен данными в модели сервиса.Сессии обмена сообщениями системы';
				|en = 'Data exchange SaaS.Message exchange sessions'; fa = 'Data exchange SaaS.Message exchange sessions';
				|it = 'Scambio di dati nel modello di servizio.Sessione di messaggistica di sistema';
				|pl = 'Wymiana danych w modelu serwisu.Sesje wymiany komunikatów systemu';
				|tr = 'SaaS modunda veri değişimi.Sistemin mesaj değişimi oturumları'",
		Common.DefaultLanguageCode());
	
EndFunction


////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the Data Exchange Monitor

// For internal use
// 
// Parameters:
//  MethodExchangePlans - Array of String - Array of exchange plan names (as in the configuration)
//  AdditionalExchangePlanProperties - String - Additional properties of the exchange plan
//  OnlyFailedExchanges - Boolean
// 
// Returns:
//  ValueTable - Table of the data exchange monitor
//
Function DataExchangeMonitorTable(Val MethodExchangePlans, Val AdditionalExchangePlanProperties = "", Val OnlyFailedExchanges = False) Export
	
	QueryText = "SELECT
	|	DataExchangesStates.InfobaseNode AS InfobaseNode,
	|	DataExchangesStates.EndDate AS EndDate,
	|	CASE
	|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed2)
	|			OR DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
	|			THEN 0
	|		ELSE 1
	|	END AS ExchangeExecutionResult
	|INTO DataExchangeStatesImport
	|FROM
	|	InformationRegister.DataAreaDataExchangeStates AS DataExchangesStates
	|WHERE
	|	DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataImport)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataExchangesStates.InfobaseNode AS InfobaseNode,
	|	DataExchangesStates.EndDate AS EndDate,
	|	CASE
	|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed2)
	|			OR DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
	|			THEN 0
	|		ELSE 1
	|	END AS ExchangeExecutionResult
	|INTO DataExchangeStatesExport
	|FROM
	|	InformationRegister.DataAreaDataExchangeStates AS DataExchangesStates
	|WHERE
	|	DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataExport)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SuccessfulDataExchangesStates.InfobaseNode AS InfobaseNode,
	|	SuccessfulDataExchangesStates.EndDate AS EndDate
	|INTO SuccessfulDataExchangeStatesImport
	|FROM
	|	InformationRegister.DataAreasSuccessfulDataExchangeStates AS SuccessfulDataExchangesStates
	|WHERE
	|	SuccessfulDataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataImport)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SuccessfulDataExchangesStates.InfobaseNode AS InfobaseNode,
	|	SuccessfulDataExchangesStates.EndDate AS EndDate
	|INTO SuccessfulDataExchangeStatesExport
	|FROM
	|	InformationRegister.DataAreasSuccessfulDataExchangeStates AS SuccessfulDataExchangesStates
	|WHERE
	|	SuccessfulDataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataExport)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExchangePlans.ExchangePlanName AS ExchangePlanName,
	|	ExchangePlans.InfobaseNode AS InfobaseNode,
	|	ExchangePlans.DataAreaMainData AS DataArea,
	|
	|	&AdditionalExchangePlanProperties,
	|
	|	ISNULL(DataExchangeStatesExport.ExchangeExecutionResult, 0) AS LastDataExportResult,
	|	ISNULL(DataExchangeStatesImport.ExchangeExecutionResult, 0) AS LastDataImportResult,
	|	DataExchangeStatesImport.EndDate AS LastImportDate,
	|	DataExchangeStatesExport.EndDate AS LastExportDate,
	|	SuccessfulDataExchangeStatesImport.EndDate AS LastSuccessfulImportDate,
	|	SuccessfulDataExchangeStatesExport.EndDate AS LastSuccessfulExportDate
	|FROM
	|	ConfigurationExchangePlans AS ExchangePlans
	|		LEFT JOIN DataExchangeStatesImport AS DataExchangeStatesImport
	|		ON ExchangePlans.InfobaseNode = DataExchangeStatesImport.InfobaseNode
	|		LEFT JOIN DataExchangeStatesExport AS DataExchangeStatesExport
	|		ON ExchangePlans.InfobaseNode = DataExchangeStatesExport.InfobaseNode
	|		LEFT JOIN SuccessfulDataExchangeStatesImport AS SuccessfulDataExchangeStatesImport
	|		ON ExchangePlans.InfobaseNode = SuccessfulDataExchangeStatesImport.InfobaseNode
	|		LEFT JOIN SuccessfulDataExchangeStatesExport AS SuccessfulDataExchangeStatesExport
	|		ON ExchangePlans.InfobaseNode = SuccessfulDataExchangeStatesExport.InfobaseNode
	|
	|WHERE &Filter
	|
	|ORDER BY
	|	ExchangePlans.ExchangePlanName,
	|	ExchangePlans.Description";
	
	SetPrivilegedMode(True);
	
	TempTablesManager = New TempTablesManager;
	
	PrepareExchangePlansNodesDataForMonitor(TempTablesManager, MethodExchangePlans, AdditionalExchangePlanProperties);
	
	QueryText = StrReplace(QueryText, "&AdditionalExchangePlanProperties,",
		GetAdditionalPropertiesOfExchangePlanAsString(AdditionalExchangePlanProperties));
	
	If OnlyFailedExchanges Then
		Filter = "
			|WHERE
			|	    ISNULL(DataExchangeStatesExport.ExchangeExecutionResult, 0) <> 0
			|	OR ISNULL(DataExchangeStatesImport.ExchangeExecutionResult, 0) <> 0";
	Else
		Filter = "";
	EndIf;
	
	QueryText = StrReplace(QueryText, "WHERE &Filter", Filter);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	
	SynchronizationSettings = Query.Execute().Unload();
	SynchronizationSettings.Columns.Add("LastImportDatePresentation");
	SynchronizationSettings.Columns.Add("LastExportDatePresentation");
	SynchronizationSettings.Columns.Add("LastSuccessfulImportDatePresentation");
	SynchronizationSettings.Columns.Add("LastSuccessfulExportDatePresentation");
	
	For Each SyncSetup In SynchronizationSettings Do
		
		SyncSetup.LastImportDatePresentation         = DataExchangeServer.RelativeSynchronizationDate(SyncSetup.LastImportDate);
		SyncSetup.LastExportDatePresentation         = DataExchangeServer.RelativeSynchronizationDate(SyncSetup.LastExportDate);
		SyncSetup.LastSuccessfulImportDatePresentation = DataExchangeServer.RelativeSynchronizationDate(SyncSetup.LastSuccessfulImportDate);
		SyncSetup.LastSuccessfulExportDatePresentation = DataExchangeServer.RelativeSynchronizationDate(SyncSetup.LastSuccessfulExportDate);
		
	EndDo;
	
	Return SynchronizationSettings;
EndFunction

// For internal use
// 
Function GetAdditionalPropertiesOfExchangePlanAsString(Val PropertiesAsString)
	
	Result = "";
	
	Template = "ExchangePlans.[PropertyAsString] AS [PropertyAsString]";
	
	ArrayProperties = StrSplit(PropertiesAsString, ",", False);
	
	For Each PropertyAsString In ArrayProperties Do
		
		PropertyAsStringInQuery = StrReplace(Template, "[PropertyAsString]", PropertyAsString);
		
		Result = Result + PropertyAsStringInQuery + ", ";
		
	EndDo;
	
	Return Result;
EndFunction

// For internal use
// 
Procedure PrepareExchangePlansNodesDataForMonitor(Val TempTablesManager, Val MethodExchangePlans, Val AdditionalExchangePlanProperties)
	
	AdditionalExchangePlanPropertiesAsString = ?(IsBlankString(AdditionalExchangePlanProperties), "", AdditionalExchangePlanProperties + ", ");
	
	Query = New Query;
	
	QueryTemplate = "
	|
	|UNION ALL
	|
	|////////////////////////////////////////////////////////"
	+
	"
	|SELECT
	|
	|	&AdditionalExchangePlanProperties,
	|
	|	Ref                      AS InfobaseNode,
	|	DataAreaMainData AS DataAreaMainData,
	|	Description                AS Description,
	|	""ExchangePlanNameSynonym""   AS ExchangePlanName
	|FROM
	|	&ExchangePlanName
	|WHERE
	|	RegisterChanges
	|	AND NOT DeletionMark
	|";
	
	QueryText = "";
	
	If MethodExchangePlans.Count() > 0 Then
		
		TextTemplate1 = "ExchangePlan.%1";
		
		For Each ExchangePlanName In MethodExchangePlans Do
			
			NameOfTheStringExchangePlan = StrTemplate(TextTemplate1, ExchangePlanName);
			
			ExchangePlanQueryText = StrReplace(QueryTemplate,              "&ExchangePlanName", NameOfTheStringExchangePlan);
			ExchangePlanQueryText = StrReplace(ExchangePlanQueryText, "ExchangePlanNameSynonym", Metadata.ExchangePlans[ExchangePlanName].Synonym);
			ExchangePlanQueryText = StrReplace(ExchangePlanQueryText, "&AdditionalExchangePlanProperties,", AdditionalExchangePlanPropertiesAsString);
			
			// Deleting a join literal for the first table
			If IsBlankString(QueryText) Then
				
				ExchangePlanQueryText = StrReplace(ExchangePlanQueryText, "UNION ALL", "");
				
			EndIf;
			
			QueryText = QueryText + ExchangePlanQueryText;
			
		EndDo;
		
	Else
		
		AdditionalPropertiesWithoutDataSourceAsString = "";
		
		If Not IsBlankString(AdditionalExchangePlanProperties) Then
			
			AdditionalProperties = StrSplit(AdditionalExchangePlanProperties, ",");
			
			AdditionalPropertiesWithoutDataSource = New Array;
			
			For Each Property In AdditionalProperties Do
				
				AdditionalPropertiesWithoutDataSource.Add(StrReplace("UNDEFINED AS [Property]", "[Property]", Property));
				
			EndDo;
			
			AdditionalPropertiesWithoutDataSourceAsString = StrConcat(AdditionalPropertiesWithoutDataSource) + ", ";
			
		EndIf;
		
		QueryText = "
		|SELECT
		|
		|	&AdditionalPropertiesWithoutDataSourceAsString,
		|
		|	UNDEFINED AS InfobaseNode,
		|	0            AS DataAreaMainData,
		|	UNDEFINED AS Description,
		|	UNDEFINED AS ExchangePlanName
		|";
		
		QueryText = StrReplace(QueryText, "&AdditionalPropertiesWithoutDataSourceAsString,", AdditionalPropertiesWithoutDataSourceAsString);
		
	EndIf;
	
	QueryTextResult = "
	|////////////////////////////////////////////////////////
	|SELECT
	|
	|	&AdditionalExchangePlanProperties,
	|
	|	InfobaseNode,
	|	DataAreaMainData,
	|	Description,
	|	ExchangePlanName
	|INTO ConfigurationExchangePlans
	|FROM
	|	&QueryText
	|	AS NestedQuery
	|;
	|";
	
	RequestInsertionText = StrTemplate("(%1)", QueryText);
	QueryTextResult = StrReplace(QueryTextResult, "&QueryText", RequestInsertionText);
	QueryTextResult = StrReplace(QueryTextResult, "&AdditionalExchangePlanProperties,", AdditionalExchangePlanPropertiesAsString);
	
	Query.Text = QueryTextResult;
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Local service procedures and functions

Function FindInfobaseNode(Val ExchangePlanName, Val NodeCode)
	
	DataArea = StringFunctionsClientServer.StringToNumber(NodeCode);
	
	NodeCodeWithPrefix = ExchangePlanNodeCodeInService(DataArea);
	
	// Searching for a node by S00000123 node code format.
	Result = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeCodeWithPrefix);
	
	If Result = Undefined Then
		
		// Searching for a node by old 0000123 node code format
		Result = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeCode);
		
	EndIf;
	
	If Result = Undefined
		And DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		
		Query = New Query(
		"SELECT
		|	T.Ref AS ExchangeNode
		|FROM
		|	#ExchangePlanTable AS T
		|WHERE
		|	NOT T.ThisNode");
		
		Query.Text = StrReplace(Query.Text,
			"#ExchangePlanTable", "ExchangePlan." + ExchangePlanName);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			CorrespondentDataArea = InformationRegisters.XDTODataExchangeSettings.CorrespondentSettingValue(Selection.ExchangeNode,
				"CorrespondentDataArea");
			
			If CorrespondentDataArea = DataArea Then
				Result = Selection.ExchangeNode;
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Result = Undefined Then
		
		Message = NStr("vi = 'Không tìm thấy nút sơ đồ trao đổi. Tên sơ đồ trao đổi %1; mã nút %2 hoặc %3';
						|ru = 'Не найден узел плана обмена. Имя плана обмена %1; код узла %2 или %3';
						|en = 'Cannot find a node in the exchange plan %1. Node ID %2 or %3'; fa = 'Cannot find a node in the exchange plan %1. Node ID %2 or %3';
						|it = 'Non è stato trovato un nodo del piano di scambio. Nome del piano di scambio %1; codice del nodo %2 oppure %3';
						|pl = 'Nie jest znaleziony węzeł planu wymiany. Nazwa planu wymiany %1; kod węzła %2 lub %3';
						|tr = 'Değişim planı düğümü bulunamadı. Değişim planı adı %1; düğüm kodu %2 veya %3'");
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, ExchangePlanName, NodeCode, NodeCodeWithPrefix);
		
		Raise Message;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function CorrespondentVersions(Val InfobaseNode)
	
	SettingsStructure = InformationRegisters.DataAreaExchangeTransportSettings.TransportSettingsWS(InfobaseNode);
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("URL",      SettingsStructure.WSWebServiceURL);
	ConnectionParameters.Insert("UserName", SettingsStructure.WSUserName);
	ConnectionParameters.Insert("Password", SettingsStructure.WSPassword);
	
	Return Common.GetInterfaceVersions(ConnectionParameters, "DataExchangeSaaS");
EndFunction

// Returns the DataExchangeSaaS subsystem parameters that are required upon terminating
// user sessions.
//
// Returns:
//  Structure - parameters.
//
Function StandaloneModeParametersOnExit()
	
	ParametersOnExit = New Structure;
	
	If StandaloneModeInternal.IsStandaloneWorkplace() Then
		
		DataExchangeExecutionFormParameters = StandaloneModeInternal.DataExchangeExecutionFormParameters();
		SynchronizationWithServiceNotExecutedLongTime = StandaloneModeInternal.SynchronizationWithServiceNotExecutedLongTime();
		
	Else
		
		DataExchangeExecutionFormParameters = New Structure;
		SynchronizationWithServiceNotExecutedLongTime = False;
		
	EndIf;
	
	ParametersOnExit.Insert("DataExchangeExecutionFormParameters", DataExchangeExecutionFormParameters);
	ParametersOnExit.Insert("SynchronizationWithServiceNotExecutedLongTime", SynchronizationWithServiceNotExecutedLongTime);
	
	Return ParametersOnExit;
EndFunction

// Adds parameters of client logic for the data exchange subsystem in SaaS mode.
//
Procedure AddClientRunParameters(Parameters)
	
EndProcedure

Function NewPropertiesOfStandaloneWorkstationMetadata(ItemMetadata)
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	AuxiliaryDataSeparator = ModuleSaaSOperations.AuxiliaryDataSeparator();
	
	MetadataProperties1 = New Structure();
	MetadataProperties1.Insert(
		"IsSeparatedMetadataObject",
		ModuleSaaSOperations.IsSeparatedMetadataObject(ItemMetadata));
	MetadataProperties1.Insert(
		"IsSeparatedMetadataObjectAuxiliaryData",
		ModuleSaaSOperations.IsSeparatedMetadataObject(ItemMetadata, AuxiliaryDataSeparator));
	MetadataProperties1.Insert(
		"AuxiliaryDataSeparator",
		AuxiliaryDataSeparator);
	MetadataProperties1.Insert(
		"IsRecordSet",
		Common.IsRegister(ItemMetadata)
			Or Common.IsSequence(ItemMetadata)
			Or Common.BaseTypeNameByMetadataObject(ItemMetadata) = "Recalculations");
			
	Return MetadataProperties1;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Getting links to the general information pages of the service

// Returns a reference address by ID
// For internal use.
//
Function RefAddressFromInformationCenter(Val Id)
	Result = "";
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Return Result;
	EndIf;
	
	ModuleInformationCenterServer = Common.CommonModule("InformationCenterServer");
	
	SetPrivilegedMode(True);
	Try
		RefData = ModuleInformationCenterServer.ContextualLinkByID(Id);
	Except
		// In case the method is not found.
		RefData = Undefined;
	EndTry;
	
	If RefData <> Undefined Then
		Result = RefData.Address;
	EndIf;
	
	Return Result;
EndFunction

// Returns an address of reference to an article of thin client setup
// For internal use.
// 
// Returns:
//  String
//
Function ThinClientSetupGuideAddress() Export
	
	Return RefAddressFromInformationCenter("ThinClientSetupInstruction");
	
EndFunction

Procedure OnCreateStandaloneWorkstation() Export
	
	If UsersInternalSaaS.UserRegisteredAsShared(
			InfoBaseUsers.CurrentUser().UUID) Then
		
		Raise NStr("vi = 'Chỉ có thể tạo chỗ làm việc độc lập dưới tên người sử dụng được chia tách.
			|Người sử dụng hiện tại là không chia tách.';
			|ru = 'Создать автономное рабочее место можно только от имени разделенного пользователя.
			|Текущий пользователь является неразделенным.';
			|en = 'You can create a standalone workstation only under a separated user.
			|The current user is a shared user.'; fa = 'You can create a standalone workstation only under a separated user.
			|The current user is a shared user.';
			|it = 'È possibile creare un''area di lavoro autonoma solo per conto dell''utente condiviso.
			|L''utente corrente è indiviso.';
			|pl = 'Utworzyć autonomiczne miejsce pracy można tylko w imieniu podzielonego użytkownika.
			|Bieżący użytkownik jest niepodzielony.';
			|tr = 'Çevrimdışı çalışma alanı yalnızca paylaşımlı kullanıcı adına oluşturulabilir.
			|Geçerli kullanıcı paylaşımlı değildir.'");
		
	EndIf;
	
EndProcedure

#EndRegion