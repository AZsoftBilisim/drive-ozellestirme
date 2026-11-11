////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document"
// Module 
////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns all integration rules that were not marked for deletion.
//
// Returns:
//   See Catalogs.RulesForIntegrationWith1CDocumentManagement3.AllIntegrationRules
//
Function AllIntegrationRules() Export
	
	Return Catalogs.RulesForIntegrationWith1CDocumentManagement3.AllIntegrationRules();
	
EndFunction

// Returns a selection of integration rules with selection by type and type of object BEFORE,
// but without selection by key Attributes.
//
// Parameters:
//   ObjectTypeDM - String - the type of object BEFORE specified in the rules.
//   DocumentKindDMID - String - filled in if the object BEFORE is a document.
//
// Returns:
//   See Catalogs.RulesForIntegrationWith1CDocumentManagement3.CommonSetOfIntegrationRules
//
Function CommonSetOfIntegrationRules(ObjectTypeDM, DocumentKindDMID = "") Export
	
	Return Catalogs.RulesForIntegrationWith1CDocumentManagement3.CommonSetOfIntegrationRules(
		ObjectTypeDM,
		DocumentKindDMID);
	
EndFunction

// Returns the main employee of the Cur of the 1C user:Document management.
//
// Returns:
//   See IntegrationWith1CDocumentManagement3.MainEmployeeOfCurrentUser
//
Function MainEmployeeOfCurrentUser() Export
	
	Return IntegrationWith1CDocumentManagement3.MainEmployeeOfCurrentUser();
	
EndFunction

#EndRegion