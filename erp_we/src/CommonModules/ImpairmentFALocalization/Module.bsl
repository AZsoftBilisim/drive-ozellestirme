////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Impairment of non-current assets".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region Posting

// 
// Parameters:
// 	DocumentMechanisms - Array -
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export

	
EndProcedure

// 
// Parameters:
// 	Query - Query - 
// 	QueryTexts - ValueList - 
// 	Registers - String -
Procedure AddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure

#EndRegion

#Region RegAccountingTransactions

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
QueryText = "";
	
	
	Return QueryText;
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion


#EndRegion
