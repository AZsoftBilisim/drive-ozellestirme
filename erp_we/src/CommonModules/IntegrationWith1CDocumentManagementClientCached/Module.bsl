////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module integration1sdocumentclientpovtisp, client, repeat. usage
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Returns True if the term "Correspondents" is used.
//
// Returns:
//   Boolean
//
Function UseTermCorrespondents() Export
	
	Return Not IntegrationWith1CDocumentManagementCoreServerCall.FunctionalityOfServiceVersionIsAvailable("2.1.0.1");
	
EndFunction

#EndRegion