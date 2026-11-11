////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Purchase of leased operating systems".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region Mechanisms

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

// Adds parameters for selecting articles and Analytics.
// 
// Parameters:
// 	ArticleSelectionAndAnalyticsOptions - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
Procedure AddOptionsForSelectingArticlesAndAnalytics(ArticleSelectionAndAnalyticsOptions) Export

	
EndProcedure

#EndRegion

#Region EventHandlers 

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure
#EndRegion

#Region RegAccountingTransactions

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
	
	QueryText = "";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region DocumentForm

Procedure OnChangeAttribute(TagName, Form, AdditionalParameters) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure ConfigureDependentFormElements(Form, StructureOfChangedProps) Export

	
EndProcedure

#EndRegion

#Region Posting

Procedure OnWrite(Object, Cancel) Export

	
EndProcedure

Procedure AddAuxiliaryDetails(AuxiliaryAttributes, Object) Export
	
	
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

//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//
Procedure AddTablesOfDeferredFormationOfRegisteredRecords(Query, QueryTexts) Export
	
	
EndProcedure

// 
// Parameters:
//  Query - Query -
//  QueryTexts - ValueList -
// 	ListOfMergeRequests - Array - 
Procedure AddRequestTextFACostTable(Query, QueryTexts, ListOfMergeRequests) Export

	
EndProcedure

// 
// Parameters:
// 	ListOfMergeRequests - ValueList - 
Procedure AddRequestTextTableSettlementsOnFinancialInstruments(ListOfMergeRequests) Export

	
EndProcedure

// 
// Parameters:
// 	Query - Query - 
// 	QueryTexts - ValueList - 
// 	ListOfMergeRequests - ValueList - 
Procedure AddRequestTextTableTTInitialOtherExpenses(Query, QueryTexts, ListOfMergeRequests) Export
	
	
EndProcedure

// 
// Parameters:
// 	Query - Query - 
// 	QueryTexts - ValueList - 
// 	ListOfMergeRequests - ValueList - 
Procedure AddRequestTextOtherExpensesBatchTable(Query, QueryTexts, ListOfMergeRequests) Export

	
EndProcedure

// 
// Parameters:
//  QueryTexts - ValueList
// 	ListOfMergeRequests - Array - 
Procedure AddQueryTextToOtherIncomeTable(QueryTexts, ListOfMergeRequests) Export
	
	
EndProcedure

#EndRegion


#EndRegion
