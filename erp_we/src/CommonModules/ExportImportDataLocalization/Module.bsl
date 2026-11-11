
#Region Public

// Called before uploading data.
// See ExportImportDataOverridable.BeforeExportData
//
Procedure BeforeExportData(Container) Export
	
	
EndProcedure

// See ExportImportDataOverridable.BeforeImportData
Procedure BeforeImportData(Container) Export
	
	
EndProcedure

// Called after data is uploaded.
// See ExportImportDataOverridable.AfterExportData
//
Procedure AfterExportData(Container) Export
	
	
EndProcedure

// Called after loading data.
// See ExportImportDataOverridable.AfterImportData
//
Procedure AfterImportData(Container) Export
	
	
EndProcedure

// Fills in an array of types that are excluded from uploading and loading data.
// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export	
	
	
EndProcedure

// Fills in an array of undivided data types that do not require link matching
// when loading data into another information database, because correct link matching
// is guaranteed using other mechanisms.
// See ExportImportDataOverridable.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport
//
Procedure OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types) Export
	
	
EndProcedure

// Fills in an array of undivided data types that support link matching
// when uploading data to another information database.
// See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport 
//
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	
EndProcedure

#EndRegion