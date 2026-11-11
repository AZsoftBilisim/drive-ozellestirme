
#Region Public

// Defines the information search link.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	InformationSearchRef - String - address.
//	
// Example:
//	If you add a search string to the link address, and go to this address, then
//	as a result we should go to the search results form.
//	
Procedure DefineInformationSearchLink(InformationSearchRef) Export
EndProcedure

// Defines common Templates with informational links.
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  ArrayOfTemplates - Array of SpreadsheetDocument - array of shared layouts.
//
Procedure CommonTemplatesWithInformationLinks(ArrayOfTemplates) Export
EndProcedure

// Defines an array of full paths to forms that use informational links.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  ArrayOfForms - Array of String - array of complete paths to forms.
//
Procedure FormsWithInformationLinks(ArrayOfForms) Export
EndProcedure

#EndRegion