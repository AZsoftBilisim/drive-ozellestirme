////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Conclusion of a lease agreement".
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

#Region Internal

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure AddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure

Function TextOfReflectionInLocalAccounting() Export
	
	QueryText = "";
	
	
	Return QueryText;
	
EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
EndProcedure

Procedure FillInAttributesOfTablePartBeforeWrite(Object, AuxiliaryAttributes) Export

	
EndProcedure

Procedure SupplementValuesOfParameters(ValuesOfHoldingParameters, Attributes) Export
	
	
EndProcedure

Function QueryTextTableTTInitialOtherExpenses() Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

#EndRegion

