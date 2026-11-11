#Region Internal

// See ExportImportDataOverridable.AfterImportData.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure AfterImportData(Container) Export
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
EndProcedure

// Creates template tasks in the Cur data area.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure CreateQueueJobsUsingTemplatesInCurScope() Export
EndProcedure

// See SaaSOperationsOverridable.OnEnableSeparationByDataAreas.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OnEnableSeparationByDataAreas() Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
//	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs.JobsQueue,
		ExportImportData.ActionWithLinksDoNotChange());

	Types.Add(Metadata.InformationRegisters.HistoryOfStartsOfJobsInQueue);
	Types.Add(Metadata.Constants.LogLaunchesJobsInQueue);
	Types.Add(Metadata.Constants.StoragePeriodForHistoryOfQueueJobLaunchesHours);
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs.DeleteJobsQueue,
		ExportImportData.ActionWithLinksDoNotChange());
	
EndProcedure

#EndRegion
