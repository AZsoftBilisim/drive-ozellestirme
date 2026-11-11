
#Region Public

// Returns a table of validation modules.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//   RestoreSettings_ - Boolean - whether or not you need to restore saved processing settings.
//   GettingPastResult - Boolean - whether or not you want to get the saved result.
//
// Returns:
//   ValueTable - table with columns:
//     * Id - UUID - verification ID.
//     * Check - Boolean - to select validation, the value of this field must be True.
//     * Name - String - module name.
//     * Description - String - short name of the check for the user.
//     * LongDesc - String - description of the check for the user.
//     * SettingsForm - String - name of the settings form, description:
//          See CheckingAndCorrectingDataOverridable.OnFillChecks.
//     * Settings - Structure - a structure containing any serializable type, description:
//       ** Fields - Arbitrary - an arbitrary set of fields.
//          See CheckingAndCorrectingDataOverridable.OnFillChecks.
//     * TemporaryData - Structure - a structure containing any serializable type, description:
//       ** Fields - Arbitrary - an arbitrary set of fields.
//          See CheckingAndCorrectingDataOverridable.OnFillChecks.
//     * YouNeedToFillInSettings - Boolean - in the lines where you need to fill in the settings, 
//          the value of this field will be True.
//     * Date - Date - date of the last check.
//     * Correct - Boolean - flag for the last check.
//     * IssuesFound - Boolean - result of the last check.
//     * ResultPresentation - String - result of the last check.
//     * SpreadsheetDocument - Arbitrary - the file with the result of the last check.
//
Function Checks(RestoreSettings_ = False, Val GettingPastResult = False) Export
EndFunction

// Searches for problems for selected rows and fills in the Result column.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//   Checks - ValueTable - a table obtained using the Check () function.
//   Correct - Boolean - The truth is, if you want to fix.
//   SaveResult - Boolean - if True, then the result will be saved to the attached file.
//
// Returns:
//   Boolean - True - the check is completed, False - you need to fill in the settings.
//
Function CheckData_(Checks, Correct = False, SaveResult = False) Export
EndFunction

// Extracts a tabular document from the zip archive of the attached file.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//   AttachedFile - CatalogRef.DataCheckAndAdjustmentHistoryAttachedFiles - the file from which
//      you want to extract the table document.
//
// Returns:
//   SpreadsheetDocument - a tabular document extracted from the archive. If the tabular document is not
//      found, an exception will be thrown.
//
Function TableDocumentFromAttachedFile(AttachedFile) Export
EndFunction

// Returns an indication of BSP implementation.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//   Boolean - The truth is embedded, the Lie is not.
//
Function ImplementedSSL() Export
EndFunction

// Returns the module by name.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//   Name - String - name of the shared module.
//
// Returns:
//   CommonModule - General module.
//
Function Module(Name) Export
EndFunction

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
		
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs["DataCheckAndAdjustmentHistory"],
		ExportImportData.ActionWithLinksDoNotUnloadObject());	
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs["DataCheckAndAdjustmentHistoryAttachedFiles"],
		ExportImportData.ActionWithLinksDoNotUnloadObject());	
	
EndProcedure

#EndRegion
