
#Region Public

// Returns a flag for using the general user login settings in the service
// @skip-warning
// @skip-check module-empty-method - a feature of the implementation.
// 
// Returns:
//  Boolean
Function UseCommonSettingsOfServiceUserAuthorization() Export
EndFunction

// Update the service user's activity.
// @skip-warning
// @skip-check module-empty-method - a feature of the implementation.
// 
// Parameters:
//  CurrentUser - Undefined - Current authorized user
//  					- CatalogRef.Users
//  LastActivityDate - Undefined - The beginning of the day of the date of the current session
//							- Date
Procedure UpdateActivityOfServiceUser(
	CurrentUser = Undefined,
	LastActivityDate = Undefined) Export
EndProcedure

#EndRegion
