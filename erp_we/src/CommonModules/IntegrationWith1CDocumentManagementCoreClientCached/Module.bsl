////////////////////////////////////////////////////////////////////////////////
// subsystem "integration with 1C:Document management"
// Module of integration1sdocumentobase functionclientpovtisp, client, repeat. Usage
////////////////////////////////////////////////////////////////////////////////

#Region Private

// Gets the version of the service UP to.
//
// Returns:
//   String - service version.
//
Function ServiceVersion() Export
	
	Return IntegrationWith1CDocumentManagementCoreServerCall.ServiceVersion();
	
EndFunction

// Gets the availability of the functionality of the version of the Document Management web service.
//
// Parameters:
//   ServiceVersion - String - a version of the Document Management web service containing the required functionality.
//
// Returns:
//   Boolean - True if the web Document Management service of the specified version is available.
//
Function FunctionalityOfServiceVersionIsAvailable(ServiceVersion = "") Export
	
	Return IntegrationWith1CDocumentManagementCoreServerCall.FunctionalityOfServiceVersionIsAvailable(
		ServiceVersion);
	
EndFunction

// Checks whether attached files are used BEFORE.
//
// Returns:
//   Boolean
//
Function UseAttachedFiles1CDocumentManagement() Export
	
	Return IntegrationWith1CDocumentManagementCoreServerCall.UseAttachedFiles1CDocumentManagement();
	
EndFunction

// Returns the maximum allowed file size from the corresponding constant.
//
// Returns:
//   Number
//
Function MaximumFileSize_() Export
	
	Return IntegrationWith1CDocumentManagementCoreServerCall.MaximumFileSize_();
	
EndFunction

// Checks whether integration is configured for the specified object of the integrated system.
//
// Parameters:
//   ObjectIS - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - the IC object being checked.
//
// Returns:
//   Boolean
//
Function IntegrationConfiguredForObject(ObjectIS) Export
	
	Return IntegrationWith1CDocumentManagementCoreServerCall.IntegrationConfiguredForObject(ObjectIS);
	
EndFunction

// Returns the settings of the Workflow database.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCoreServerCall.GetSettings
//
Function GetSettings() Export
	
	Return IntegrationWith1CDocumentManagementCoreServerCall.GetSettings();
	
EndFunction

// Checks whether the integrated system can create electronic
// signatures for 1C objects:Document management.
//
// Returns:
//   Boolean
//
Function CreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem() Export
	
	Return IntegrationWith1CDocumentManagementCoreServerCall.CreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem();
	
EndFunction

#EndRegion