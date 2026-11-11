////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Cost Calculation Registrar".
// 
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

#EndRegion

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure Posting(Object, Cancel, PostingMode) Export
	
EndProcedure

#EndRegion

#Region RegAccountingTransactions

// Registers the document for reflection in the regulated accounting.
//
// Parameters:
//	Document - DocumentRef.CostCalculationRecorder - document to reflect.
//
Procedure RegisterDocumentReflection(Document) Export
	
EndProcedure

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
// that are required for reflection in regulated accounting.
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	QueryTexts = New Array;
	
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Return QueryText;
	
EndFunction


#EndRegion

#EndRegion

#Region Private

#Region Posting

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure AddRequestTexts(Query, QueryTexts, Registers) Export

EndProcedure

#EndRegion


#EndRegion