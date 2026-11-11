////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Input of lease settlement balances".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

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

// The function returns the request text for additional temporary tables that are required for reflection in regulated accounting.
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	QueryTexts = New Array;
	
	
	Return StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
EndFunction

#EndRegion

#Region DocumentForm

Procedure OnExecuteCommand(CommandName, Form) Export
	
	Object = Form.Object;
	
	
EndProcedure

#EndRegion

#Region FillingInAccordingToOperationalAccountingData

Function BalancesByTypeOfOperation(Date, BusinessOperation, Companies, AdditionalSelection = Undefined, ParametersForFillingBalances = Undefined) Export

	Result = Undefined;
	
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

Procedure InitializeDocumentBeforeFillingItOut(Object) Export

	
EndProcedure

#EndRegion


#EndRegion
