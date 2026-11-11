// @strict-types

#Region Public

#Region ExtensionStatistics

// Commits an extension operation event in the "Custom" event group
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	EventIdentifier - String - event ID received in the service Manager's personal account (length 36).
//
// Example:
//	Tsclient.Fixedextension statistics ("2f1df77a-9f07-11e9-9d8c-0242ac1d0004")
//
Procedure CaptureExtensionStatisticsEvent(Val EventIdentifier) Export
EndProcedure

#EndRegion

#EndRegion