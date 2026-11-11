// @strict-types

#Region Public

// Sets the user's default rights.
// It is called when working in the service model, if the user's rights are updated in
// the service manager without administrative rights.
// @skip-check module-empty-method - Overridable method.
//
// Parameters:
//  User - CatalogRef.Users - the user 
//                 who needs to set the default permissions.
//  AccessAllowed - Boolean - indicates whether access is allowed. 
//                   If True, access is allowed, if False, access is denied.
//
Procedure SetDefaultRights(User, AccessAllowed = True) Export
	
	TMAccessManagement.SetDefaultRights(User, AccessAllowed);
	
EndProcedure

// Sets the user's access rights to the data area API.
// It is called when working in the service model, if the user's rights are updated in 
// the service manager without administrative rights.
// @skip-check module-empty-method - Overridable method.
//
// Parameters:
//  User - CatalogRef.Users - the user who needs to set API access rights.
//  AccessAllowed - Boolean - indicates whether access is allowed.  
//                   If True, access is allowed, if False, access is denied.
//
Procedure SetAccessToThisDataArea(User, AccessAllowed = True) Export
	
	TMAccessManagement.SetAccessToThisDataArea(User, AccessAllowed);
	
EndProcedure

#EndRegion
