////////////////////////////////////////////////////////////////////////////////
// Subsystem "System state audit".
// Redefined procedures and functions.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Allows you to fill in the description of inspection groups.
// Called when filling in the Catalog of the accounting rulerreferences.
//
// Parameters:
//	TableOfInspectionGroups - See AuditOfSystemState.TableOfSystemStateCheckGroups 
//
Procedure FillInVerificationGroupsForRegistration(TableOfInspectionGroups) Export
EndProcedure

// Allows you to fill in the description of checks.
// Called when filling in the Catalog of the accounting rulerreferences.
//
// Parameters:
//	TableOfChecks - See AuditOfSystemState.SystemStateCheckTable 
//
Procedure FillOutChecksForRegistration(TableOfChecks) Export
EndProcedure

#EndRegion
