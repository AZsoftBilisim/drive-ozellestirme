////////////////////////////////////////////////////////////////////////////////
// Expansion of the subsystem "Individuals" for UT, KA2, UP2.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Checks that the document series for the transmitted document type is specified correctly.
//
// Parameters:
//	DocumentKind - CatalogRef.DocumentKindsOfPersons	- type of document for which you want to
//																check the validity of the series
//	Series - String												- series of documents
//	ErrorText - String										- error text if the series is specified incorrectly.
//
// Returns:
//	Boolean - the result of the check, the truth is correct, the Lie is not.
//
Function DocumentSeriesIsListedCorrectly(DocumentKind, Val Series , ErrorText) Export
	
	WithoutError = True;
	
	PersonsClientServerTMLocalization.DocumentSeriesIsListedCorrectly(DocumentKind, Series, ErrorText, WithoutError);
	
	Return WithoutError;
	
EndFunction

// Checks that the document number for the transmitted document type is specified correctly.
//
// Parameters:
//	DocumentKind - CatalogRef.DocumentKindsOfPersons	- type of document to
//																check the correct number for
//	Number - String												- document number
//	ErrorText - String										- error text if the number is entered incorrectly.
//
// Returns:
//	Boolean - the result of the check, the truth is correct, the Lie is not.
//
Function DocumentNumberIsCorrect(DocumentKind, Val Number, ErrorText) Export
	
	WithoutError = True;
	
	PersonsClientServerTMLocalization.DocumentNumberIsCorrect(DocumentKind, Number, ErrorText, WithoutError);
	
	Return WithoutError;
	
EndFunction

// Returns the series type of the identity document
//
// Parameters:
//	DocumentKind - CatalogRef.DocumentKindsOfPersons
//
// Returns:
//	Number	- the type of series for the document, 0 - there are no requirements for the series.
//
Function TypeOfIdentityDocumentSeries(DocumentKind) Export
	
	DocumentType = 0;
	
	PersonsClientServerTMLocalization.TypeOfIdentityDocumentSeries(DocumentKind, DocumentType);
	
	Return DocumentType;
	
EndFunction

// Returns the type number of the document proving the identity
//
// Parameters:
//	DocumentKind - CatalogRef.DocumentKindsOfPersons
//
// Returns:
//	Number	- the number type for the document, 0 - there are no requirements for the number.
//
Function TypeOfIdentityDocumentNumber(DocumentKind) Export
	
	DocumentType = 0;
	
	PersonsClientServerTMLocalization.TypeOfIdentityDocumentNumber(DocumentKind, DocumentType);
	
	Return DocumentType;
	
EndFunction

#EndRegion

