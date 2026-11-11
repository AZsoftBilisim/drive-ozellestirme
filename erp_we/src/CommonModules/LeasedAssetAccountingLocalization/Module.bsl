////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "FA lease".
// 
////////////////////////////////////////////////////////////////////////////////


#Region Private


#Region Other

// Determines whether lease accounting is used in accordance with the FSB 25/2018 standard.
//
// Parameters:
//  Organization - CatalogRef.Companies, Array of CatalogRef.Companies, Undefined - The organization for which the accounting order is checked.
//  Period	 - Date - On what date to check (if not specified, it is checked for the current date).
//  ConsiderBeginningOfTransition - Boolean - True, if you need to take into account the beginning of the transition to a new standard.
// 
// Returns:
//  Boolean, Undefined - True if lease accounting is used according to FSB 
//                    25/2018 for the specified organization or for any organization if the organization is not specified.
//
Function LeaseAccountingAccordingToFSB25_2018IsUsed(Organization = Undefined, Period = '000101010000', ConsiderBeginningOfTransition = False) Export

	LeaseAccountingAccordingToFSB25_2018IsUsed = Undefined;
	

	Return LeaseAccountingAccordingToFSB25_2018IsUsed;
	
EndFunction

// Defines the start date of lease accounting in accordance with the FSB 25/2018 standard
// 
// Parameters:
// 	Organization - CatalogRef.Companies -
// Returns:
// 	Date, Undefined - 
Function StartOfLeaseAccountingUnderFSB25_2018(Organization) Export
	
	TheBeginningOfTheAccounting = Undefined;
	
	
	Return TheBeginningOfTheAccounting;
	
EndFunction

// See ReportsOptionsOverridable.CustomizeReportsOptions.
//
Procedure CustomizeReportsOptions(Settings) Export


EndProcedure

Procedure GenerateTaskRegisterEntries(Document, TablesData) Export

	
EndProcedure

#EndRegion

#EndRegion