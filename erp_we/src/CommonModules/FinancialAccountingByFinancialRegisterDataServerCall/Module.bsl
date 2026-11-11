
#Region Internal

// User settings for operational accounting analysis.
// 
// Parameters:
//  ReportName - String - Report name
//  UserSettingsValues - Structure - Values of user settings
// 
// Returns:
//  DataCompositionUserSettings -
Function CustomSettingsForAnalysisOfOperationalAccounting(ReportName, UserSettingsValues) Export
	
	ReportObject = Reports[ReportName].Create();
	Return ReportObject.UserSettings(UserSettingsValues);
	
EndFunction

#EndRegion
