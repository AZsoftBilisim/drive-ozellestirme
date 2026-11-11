////////////////////////////////////////////////////////////////////////////////
// subsystem "integration with 1C:Document management"
// Module Integration1 Document management Database functionality Client: global, client
////////////////////////////////////////////////////////////////////////////////

#Region Private

// performed when the lifetime of the access token to the 1C web service expires:Document flow.
//
Procedure WhenLifetimeOfAccessTokenExpires() Export
	
	IntegrationWith1CDocumentManagementCoreServerCall.ResetInternetConnectionCache();
	
EndProcedure

#EndRegion