#Region Internal

// Detailed error representation
// Used to handle warnings about an obsolete method in configurations with compatibility mode prior to 8.3.17.
// 
// Parameters:
// 	ErrorInfo - ErrorInfo
// Returns:
// 	String
Function DetailedErrorText(ErrorInfo) Export
	
	//@skip-warning
	Return DetailErrorDescription(ErrorInfo);
	
EndFunction

// Brief representation of the error
// Used to handle warnings about an obsolete method in configurations with compatibility mode prior to 8.3.17.
// 
// Parameters:
// 	ErrorInfo - ErrorInfo
// Returns:
// 	String
Function ShortErrorText(ErrorInfo) Export
	
	//@skip-warning
	Return BriefErrorDescription(ErrorInfo);
	
EndFunction
	
#EndRegion