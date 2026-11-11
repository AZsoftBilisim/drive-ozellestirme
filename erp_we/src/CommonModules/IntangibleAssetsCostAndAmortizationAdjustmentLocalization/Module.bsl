////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Adjustment of the cost and depreciation of IA".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Procedure AddAuxiliaryDetails(Object, AuxiliaryAttributes) Export

	
EndProcedure

Procedure ConfigureDependentFormElements(Form, StructureOfChangedProps) Export

	
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

Procedure TablesOfDeferredMotionFormation(QueryTexts) Export

	
EndProcedure

Procedure SetConditionalAppearance(Form) Export

	
EndProcedure

// Fill in the document.
// 
// Parameters:
//  Object - DocumentObject.IntangibleAssetsCostAndAmortizationAdjustment - Object
//  QueryResult - QueryResult - query result
Procedure FillInDocument_(Object, QueryResult) Export
	
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

Function QueryTextTableInitialIntangibleAssetsInformation(QueryTexts) Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region RegAccountingTransactions

Function TextOfReflectionInLocalAccounting() Export

	QueryText = "";	
	
	
	Return QueryText;
	
EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion

#EndRegion
