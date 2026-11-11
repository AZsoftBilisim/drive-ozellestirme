#Region Internal   

// Returns a structure with predefined selection levels for accounting reflection settings.
//
// Returns:
//   Structure - a structure where keys and values correspond to selection levels:
//			* AccrualRetentionLevel - String - the selection level for accruals and deductions.
//			* DivisionLevel - String - the level of selection by division.
//			* LevelPersonnelDocuments - String - the level of selection according to personnel documents.
//			* LevelOneTimeDocuments - String - the level of selection for one-time documents.
//			* ManualTaxLevel - String - the level of selection for manual tax.
//
Function SelectionLevels() Export

	Levels = New Structure();
	Levels.Insert("AccrualRetentionLevel", "AccrualRetentionLevel");
	Levels.Insert("DivisionLevel",       "DivisionLevel");
	Levels.Insert("LevelPersonnelDocuments",   "LevelPersonnelDocuments");
	Levels.Insert("LevelOneTimeDocuments",    "LevelOneTimeDocuments");
	Levels.Insert("ManualTaxLevel",         "ManualTaxLevel");
	
	Return Levels;
	
EndFunction	

#EndRegion
