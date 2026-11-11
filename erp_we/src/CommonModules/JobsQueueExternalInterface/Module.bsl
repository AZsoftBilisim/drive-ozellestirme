
#Region Public

// See InfobaseUpdateSSL.OnAddUpdateHandlers
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
Procedure OnAddUpdateHandlers(Handlers) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.JobsProperties);
	
EndProcedure

// Returns the storage ID as a string.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	String - storage ID. 
//
Function StorageID() Export
EndFunction

#EndRegion 
