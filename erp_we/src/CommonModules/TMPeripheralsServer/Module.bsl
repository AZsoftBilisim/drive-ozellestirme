
#Region Public

// Compares the passed version of the FFD for relevance (currently the current version is 1.0.5 or 1.1).
//
// Parameters:
//  FDFVersion - String - FFD version.
// 
// Returns:
//  Boolean - The version is current.
//
Function Ffd1_0_5OrFFD1_1FormatIsSupported(FDFVersion) Export
	
	Return FDFVersion = "1.0.5" Or FDFVersion = "1.1";
	
EndFunction

#EndRegion

#Region Internal

#Region Localization


#EndRegion

#EndRegion