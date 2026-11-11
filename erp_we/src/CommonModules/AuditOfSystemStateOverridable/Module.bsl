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
	
	MonthEndTransactionsServer.FillInVerificationGroupsForRegistration(TableOfInspectionGroups);
	Documents.StandardCosting2_2.FillInVerificationGroupsForRegistration(TableOfInspectionGroups);
	AuditOfSystemStateLocalization.FillInVerificationGroupsForRegistration(TableOfInspectionGroups);
EndProcedure

// Allows you to fill in the description of checks.
// Called when filling in the Catalog of the accounting rulerreferences.
//
// Parameters:
//	TableOfChecks - See AuditOfSystemState.SystemStateCheckTable
//
Procedure FillOutChecksForRegistration(TableOfChecks) Export
	
	MonthEndTransactionsServer.FillOutChecksForRegistration(TableOfChecks);
	Documents.StandardCosting2_2.FillOutChecksForRegistration(TableOfChecks);
	AuditOfSystemStateLocalization.FillOutChecksForRegistration(TableOfChecks);
EndProcedure

#EndRegion
