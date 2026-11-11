////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Conclusion of a lease agreement".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region RegAccountingTransactions

Function TextOfReflectionInLocalAccounting() Export

	QueryText = "";
	
	
	Return QueryText;
	
EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#Region Posting

Procedure OnWrite(Object, Cancel) Export
	
	
EndProcedure

// 
// Parameters:
// 	DocumentMechanisms - Array -
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export

	
EndProcedure

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure AddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure

Procedure SupplementValuesOfParameters(Attributes, ValuesOfHoldingParameters) Export
	
	
EndProcedure

Function QueryTextTableTTExpenses() Export
	
	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

#EndRegion


#EndRegion
