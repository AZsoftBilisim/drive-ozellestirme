////////////////////////////////////////////////////////////////////////////////
// Subsystem "Basic functionality in the service model".
// General-purpose server procedures and functions:
// - Support for security profiles.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Process requests to use external resources
// 
// Parameters: 
//  RequestsIDs -  Array of UUID 
// 
// Returns: 
//  Structure:
// * PermissionApplicationRequired - Boolean
// * IDOfPackage - UUID
Function ProcessRequestsToUseExternalResources(Val RequestsIDs) Export
	
	Result = New Structure("PermissionApplicationRequired, IDOfPackage");
	
	Manager = SafeModeManagerInternalSaaS.PermissionsApplicationManager(
		RequestsIDs);
	
	If Manager.MustApplyPermissionsInServersCluster() Then
		
		Result.PermissionApplicationRequired = True;
		
		Result.IDOfPackage = SafeModeManagerInternalSaaS.PackageOfAppliedRequests(
			Manager.WriteStateToXMLString());
		
	Else
		
		Result.PermissionApplicationRequired = False;
		Manager.CompleteApplyRequestsToUseExternalResources();
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion