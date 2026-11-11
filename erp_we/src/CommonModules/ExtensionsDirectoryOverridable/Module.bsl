#Region Public

// Before changing the usage value in the application. 
// The Overridable event handler is called from a split session. Called before 
//  the event for changing the value of the extension Directory usage in the application is called.
// Parameters:
//  Use - Boolean - if the value of the parameter being passed is True, the event should be interpreted as
//   enabling the Extension Catalog. For the transmitted value of the application code, if the value is False, this
//   is an event for disabling the Extension Catalog.
//  
//@skip-check module-empty-method
Procedure UsingInAppBeforeChangeValue(Use) Export
EndProcedure

// Requests to the service manager are allowed.
// The Overridable event handler is called before executing the request to the Service Manager. Allows you to describe 
//  exceptions for extensions by public ID
// 
// Parameters:
//  PublicId - String - public extension ID from the Service Manager
// 
// Returns:
//  Boolean - True if the transmitted extension can be accessed by the Service Manager using the public ID
//
Function ServiceManagerRequestsAllowed(PublicId) Export
	Return False;
EndFunction

#EndRegion