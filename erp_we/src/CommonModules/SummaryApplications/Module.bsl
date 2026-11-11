#Region Internal

// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//  HandlersArray - Array - message handler.
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
EndProcedure

// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  HandlersArray - Array - message handler.
//
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export
EndProcedure

//@skip-warning
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
EndProcedure

// Processing incoming messages with type {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d }SetSynopticExchange.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataAreaCode - Number - data area code,
//  Parameters - Structure - ID of the backup,
//
Procedure ConfigureUploadingToSummaryApp_(DataAreaCode, Parameters) Export
EndProcedure

// Processing incoming messages with type {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d }SetCorrSynopticExchange.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataAreaCode - Number - data area code,
//  Parameters - Structure - ID of the backup,
//
Procedure ConfigureUploadingToSummaryApp(DataAreaCode, Parameters) Export
EndProcedure

// Processing incoming messages with type {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d }PushSynopticExchangeStep1.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataAreaCode - Number - data area code,
//  Parameters - Structure - ID of the backup,
//
Procedure InteractiveLaunchOfUploadingToSummaryApplication(DataAreaCode, Parameters) Export 
EndProcedure

// Processing incoming messages with type {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d }PushSynopticExchangeStep2.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataAreaCode - Number - data area code,
//  Parameters - Structure - ID of the backup,
//
Procedure InteractiveLaunchOfDownloadToSummaryApplication(DataAreaCode, Parameters) Export 
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - Array of MetadataObject
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	Types.Add(Metadata.InformationRegisters.SummaryApplicationsImportQueue);
	Types.Add(Metadata.InformationRegisters.SummaryApplicationsImportState);
	Types.Add(Metadata.InformationRegisters.SummaryApplicationsExportState);
	Types.Add(Metadata.Constants.UseExportToSummaryApplication);
	Types.Add(Metadata.InformationRegisters.DeleteSummaryApplicationsObjectsExportOrder);
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	Settings - See ScheduledJobsOverridable.OnDefineScheduledJobSettings.Settings
//
Procedure OnDefineScheduledJobSettings(Settings) Export
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
EndProcedure

// Routine task Summary of the application Upload.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure ExportJob() Export
EndProcedure

// The routine task of the summary application of the load planning.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure TaskLoadPlanning() Export
EndProcedure

// Handler for subscribing to the event before writing the Object.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure BeforeWriteObject(Source, Cancel) Export
EndProcedure

// Handler for subscribing to a document Record event.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure BeforeWritingDocument(Source, Cancel, WriteMode, PostingMode) Export
EndProcedure

// Handler for subscribing to the pre-Recordset event.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure BeforeRecordingSet(Source, Cancel, Replacing) Export
EndProcedure

// Handler for subscribing to the event before recording the calculation Set.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure BeforeRecordingCalculationSet(Source, Cancel, Replacing, WriteOnly, WriteActualActionPeriod, WriteRecalculations) Export
EndProcedure

// Handler for subscribing to the event before deleting an Object.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure BeforeDeleteObject(Source, Cancel) Export
EndProcedure

#Region DataTransferSubsystemIntegration

// Returns a description of the logical storage data.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  StorageID - String - ID of the logical storage.
//  DataID    - String - ID of the storage data.
// 
// Returns:
//   Structure - description of the State of the queue job:
//    * FileName - String - file name.
//    * Size - Number - file size in bytes.
//    * Data - BinaryData - binary data of the task description file.
//
Function LongDesc(StorageID, DataID) Export
EndFunction

// Returns the logical data storage.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataDetails - Structure - description of storage data.
// 
// Returns:
//   BinaryData -
//
Function Data(DataDetails) Export
EndFunction

// Writes data to logical storage.
// @skip-warning EmptyMethod - a feature of the implementation.
// Performs actions:
// - saves the data file to the file storage
// - schedules the task queue for file processing tasks
// - returns the task id in the response.
// 
// Parameters:
//	DataDetails - Structure - description of storage data:
//	 * FileName - String - file name.
//	 * Size - Number - file size in bytes.
//	 * Data - BinaryData, String - binary data of the file or the location of the file on disk.
// 
// Returns:
//   Structure:
//     * ConfigurationName - String - configuration name.
//     * ConfigurationVersion - String - configuration version.
//     * LoadingIsInProgress - Boolean - indicates that the download is in progress.
//     * ReceivedMessageNumber - Number - number of processed messages.
//     * ObjectsImported - Number - the number of objects loaded.
//     * CompletedWithErrors - Boolean - indicates completion with errors.
//     * ErrorDescription - String - error description.
//     * ResendingRequired - Boolean - True if you need to resend data that is currently
//                                             in the queue.
Function Load(DataDetails) Export
EndFunction

#EndRegion

#EndRegion
