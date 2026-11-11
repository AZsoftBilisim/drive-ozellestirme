////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Acceptance of depreciation units and components for accounting".
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

// Adds the details of the document header to the request text.
//  Details are added instead of the parameter "&Acceptingaccount_requisitydocument".
//
// Parameters:
//  QueryText - String				 - Source text of the request.
//  TableName	 - String, Undefined	 - Synonym for the document table in the query.
//  	For empty values, you have to pass on "Undefined".
//
Procedure AddDocumentDetailsToRequestText(QueryText, TableName = Undefined) Export
	
	LocalizationFields = "NULL";
	
	QueryText = StrReplace(QueryText, "&AcceptanceForAccountingOS_DocumentDetails", LocalizationFields);
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

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
	
	QueryText = "";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Posting

Procedure FillInInitializationParameters(Query, Attributes) Export

	
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

Procedure TablesForCalculatingCost(Query, QueryTexts) Export
	
	
EndProcedure
	
#EndRegion

#EndRegion

#Region Private

#Region Posting

// 
// Returns:
//  String - Query text
Function QueryTextTableAccountingProcedureForOSBU() Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

// 
// Returns:
//  String - Query text
Function QueryTextTableOSBUDepreciationParameters() Export
	
	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOwnersInformation(QueryTexts) Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction


Function QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts) Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFACost(QueryTexts) Export

	QueryText = Undefined;
	
	
	Return QueryText;

EndFunction

#EndRegion

#Region Other

// 
// Parameters:
//  Object - DocumentObject.RecognizeSubAssetsComponentsOfDepreciation - 
//  AuxiliaryAttributes - Structure - 
Procedure AddAuxiliaryDetails(Object, AuxiliaryAttributes) Export
	
	
EndProcedure

#EndRegion

#EndRegion
