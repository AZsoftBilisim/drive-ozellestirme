
#Region Public

// Returns a flag for using the service's merchant profile in the app.
//
// Returns:
//  Boolean
Function Used() Export
	
	Return False;
	
EndFunction

// Updates the settings for using the service's merchant profile in the app.
// Call On changes to the data affecting the result of redefinition in the Personal Service.Enabling
// @skip-check module-empty-method - a feature of the implementation.
Procedure UpdatePersonalAreaUsage() Export
EndProcedure

#EndRegion

#Region Internal

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
//  Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.PersonalAreaOfServiceSettingsInDataAreas);
	
EndProcedure

#EndRegion