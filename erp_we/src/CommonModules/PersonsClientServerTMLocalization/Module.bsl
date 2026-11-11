////////////////////////////////////////////////////////////////////////////////
// Extension of the subsystem "Individuals" for TM, KA2, UP2 (localization).
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Checks that the document series for the transmitted document type is specified correctly.
//
// Parameters:
//	DocumentKind - CatalogRef.DocumentKindsOfPersons	- type of document for which you want to
// 																check the validity of the series
//	Series - String - series of documents
//	ErrorText - String - error text if the series is specified incorrectly.
//	WithoutError - Boolean - Verification Flag
//
Procedure DocumentSeriesIsListedCorrectly(DocumentKind, Val Series , ErrorText, WithoutError) Export
	
	
EndProcedure

// Checks that the document number for the transmitted document type is specified correctly.
//
// Parameters:
//	DocumentKind - CatalogRef.DocumentKindsOfPersons	- type of document to
//																check the correct number for
//	Number - String - document number
//	ErrorText - String - error text if the number is entered incorrectly.
//	WithoutError - Boolean - Verification Flag
//
Procedure DocumentNumberIsCorrect(DocumentKind, Val Number, ErrorText, WithoutError) Export
	
	
EndProcedure

// Returns the series type of the identity document
//
// Parameters:
//	DocumentKind - CatalogRef.DocumentKindsOfPersons
//	DocumentType - Number
//
Procedure TypeOfIdentityDocumentSeries(DocumentKind, DocumentType) Export
	
	
EndProcedure

// Returns the type number of the document proving the identity
//
// Parameters:
//	DocumentKind - CatalogRef.DocumentKindsOfPersons
//	DocumentType - Number
//
Procedure TypeOfIdentityDocumentNumber(DocumentKind, DocumentType) Export
	
	
EndProcedure

#EndRegion

