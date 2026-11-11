#Region Public

// Use the VNA depreciation.
// 
// Returns:
//  Boolean - Use the impairment in the
Function UseFixedAssetImpairment() Export
	Return GetFunctionalOption("UseFixedAssetImpairment");
EndFunction

#EndRegion
