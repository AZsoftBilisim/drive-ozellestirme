////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Changing the terms of the lease agreement".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region Posting

// 
// Parameters:
//  Object - DocumentObject.LeaseTermAdjustment -
//  AuxiliaryAttributes - Structure -
// 	NotCheckedAttributeArray - Array of String -
// 	Cancel - Boolean
Procedure FillCheckProcessing(Object, AuxiliaryAttributes, NotCheckedAttributeArray, Cancel) Export

	
EndProcedure

Function RequestTextForCheckingFixedAssets() Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

Procedure ReportInspectionOfFixedAssets(Selection, Object, Cancel) Export
	
	
EndProcedure

Procedure SupplementValuesOfParameters(ValuesOfHoldingParameters, Attributes) Export
	
	
EndProcedure

#EndRegion

#Region Mechanisms

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

#EndRegion

#Region RegAccountingTransactions

Function TextOfReflectionInLocalAccounting() Export
	
	QueryText = "";
	
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region DocumentForm

// LongDesc
// 
// Parameters:
// 	Form - ClientApplicationForm - Contains:
//				* Items - FormAllItems - 
Procedure SetConditionalAppearance(Form) Export

	
EndProcedure

Function TextOfRequestForFillingInServiceDetailsOfTS() Export
	
	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

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
//  QueryTexts - ValueList - List of texts of the request for holding.
//
Procedure TablesOfDeferredMotionFormation(QueryTexts) Export
	
	
EndProcedure

Function RequestTextFillingInTSByAgreement() Export
	
	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableInitialOtherExpensesCostGeneration() Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion
