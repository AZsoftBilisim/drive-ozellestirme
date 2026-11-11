////////////////////////////////////////////////////////////////////////////////
// Subsystem "Basic functionality in the service model".
// General-purpose server procedures and functions:
// - Support for working in the service model.
//
////////////////////////////////////////////////////////////////////////////////
// @strict-types

#Region Internal

// Returns the endpoint for sending messages to the service Manager.
//
// Returns:
//  ExchangePlanRef.MessagesExchange - the node corresponding to the service manager.
//
Function ServiceManagerEndpoint() Export
	
	Return SaaSOperationsCTL.ServiceManagerEndpoint();
	
EndFunction

// Returns the HTTP connection to the Service Manager.
// The calling code must independently set the privileged mode.
// 
// Parameters: 
//  ServerData - See CommonClientServer.URIStructure
//  Timeout - Number - See SaaSOperationsCTL.ConnectingToServiceManager.Timeout
// 
// Returns: 
//  HTTPConnection - connection with the service manager
// (See SaaSOperationsCTL.ConnectingToServiceManager)
Function ConnectingToServiceManager(ServerData, Timeout = 60) Export
	
	Return SaaSOperationsCTL.ConnectingToServiceManager(ServerData, Timeout);
	
EndFunction

Function AuthenticationProviderURL() Export
	
	Return SaaSOperationsCTL.AuthenticationProviderURL()
	
EndFunction

Function AccessTokenAuthenticationOfInternalAPIRequests() Export
	
	Return SaaSOperationsCTL.AccessTokenAuthenticationOfInternalAPIRequests();
	
EndFunction

#EndRegion
