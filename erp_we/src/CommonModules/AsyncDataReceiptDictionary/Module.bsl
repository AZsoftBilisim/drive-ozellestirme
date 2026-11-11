// @strict-types

#Region Public

#Region ReturnCodes

// Returns the data error code.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	Number - standard return code by method name.
//
Function ReturnCodeDataError() Export
EndFunction

// Returns the authorization denial code.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	Number - standard return code by method name.
//
Function AuthorizationDeniedReturnCode() Export
EndFunction

// Returns the internal error code.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	Number - standard return code by method name.
//
Function ReturnCodeInternalError() Export
EndFunction

// Returns the execution code with warnings.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	Number - standard return code by method name.
//
Function ReturnCodeCompletedWithWarnings() Export
EndFunction

// Returns the success code.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	Number - standard return code by method name.
//
Function ReturnCodeCompleted() Export
EndFunction

// Returns the code for waiting for data.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	Number - standard return code by method name.
//
Function StateCodePending() Export
EndFunction

// Returns the code for missing data.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	Number - standard return code by method name.
//
Function ReturnCodeNotFound() Export
EndFunction

#EndRegion

#Region FilesTypes

// Returns a string with the JSON file type
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	String - "json"
//
Function JSONType() Export
EndFunction

// Returns a string with the XLSX file type
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	String - "xlsx"
//
Function TypeXLSX() Export
EndFunction

// Returns a string with the PDF file type
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Returns:
//	String - "pdf"
//
Function TypePDF() Export
EndFunction

#EndRegion

#EndRegion
