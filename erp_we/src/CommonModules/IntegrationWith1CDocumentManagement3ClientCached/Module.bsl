////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module integration1sdocumentoclientpovtisp, client, repeat. Usage
////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns the value of the Warn Participant Protection setting.
//
// Returns:
//   Boolean
//
Function WarnWhenProtectingParticipant() Export
	
	Return CommonServerCall.CommonSettingsStorageLoad(
		"SettingsNoLongerShow",
		"ShowWarningWhenSettingProtectionOfParticipantOfAction",
		True);
	
EndFunction

// Checks whether the transmitted document type describes UP to 3.
//
// Parameters:
//   XDTOObjectType - String - object type.
//
// Returns:
//   Boolean
//
Function IsDocumentBefore3(XDTOObjectType) Export
	
	Return IntegrationWith1CDocumentManagement3ServerCall.IsDocumentBefore3(XDTOObjectType);
	
EndFunction

// Checks whether the passed type describes a known review object.
//
// Parameters:
//   XDTOObjectType - String - object type.
//
// Returns:
//   Boolean
//
Function ThisIsWellKnownObjectOfReview(XDTOObjectType) Export
	
	Return IntegrationWith1CDocumentManagement3ServerCall.ThisIsWellKnownObjectOfReview(XDTOObjectType);
	
EndFunction

#EndRegion