////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data upload and download".
// 
// The procedures and functions of this module allow you to upload and download
// additional reports and processing.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called when registering custom data upload handlers.
// in this procedure, you need to add information about registered custom
// data upload handlers to the handler table. See ExportImportDataOverridable.OnRegisterDataExportHandlers.
// @skip-check module-empty-method - a feature of the implementation.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
EndProcedure

#EndRegion