// @strict-types

#Region Public

// Opens the form of an extension object from the extensions catalog
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	PublicId - String - public extension ID from the Service Manager
// 	CallbackDescription - CallbackDescription - optional, allows you to process the closing of the form.
// 		The procedure that will process the call of the alert description will receive
// 		a value of the type "Enumeration Link" as the first parameter.Extension States", describing the state of the extension at the time of closing the form
// 		(for details, see the description of the "Open Form" method of the global context).
//
Procedure OpenExtensionObject(Val PublicId, Val CallbackDescription = Undefined) Export
EndProcedure

// Opens the extensions directory.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OpenExtensionsDirectory() Export 
EndProcedure

// Suggest the user to rate the extension. 
// You can use it only after successfully calling the Extension catalog.Information about the user's assessment.
// The result should be analyzed and, if necessary, called
// Client Extension catalog.Suggest the user to evaluate the expansion.
// When calling this procedure, the user will be shown a question with three 
// possible answers: "Rate", "Rate later", "No more offer".
// If the user has already selected the answer "No more offer", the question dialog will not appear.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//  PublicId - String - public extension ID from the Service Manager
//  SuggestionText - String - the text of the offer shown to the user.
//   If no text is specified, the standard text will be used
Procedure SuggestUserToRateExtension(PublicId, SuggestionText = "") Export
EndProcedure

#EndRegion
