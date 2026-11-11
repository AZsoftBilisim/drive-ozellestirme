
#Region Internal

// Routine task procedure Processing of user messages
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure HandlingUserAlerts() Export
	
EndProcedure

// Sends alerts to user sessions
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure DeliverAlerts(DeliveredAlerts) Export
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	Settings - See ScheduledJobsOverridable.OnDefineScheduledJobSettings.Settings
//
Procedure OnDefineScheduledJobSettings(Settings) Export
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export 	
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
	
EndProcedure

#EndRegion