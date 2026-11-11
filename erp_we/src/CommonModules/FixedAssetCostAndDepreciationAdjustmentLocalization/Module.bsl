////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Cost adjustment and depreciation of the OS".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region EventHandlers

// Called from the corresponding document handler
// 
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  FillingText - String - 
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
Procedure Filling(Object, FillingData, FillingText, StandardProcessing) Export
	
	
EndProcedure

#EndRegion

#EndRegion

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

Procedure SetConditionalAppearance(Form) Export

	
EndProcedure

Function QueryTextFillInByAccountingData() Export

	QueryText = Undefined;
	

	Return QueryText;

EndFunction
 
// 
// Parameters:
//  Object - DocumentObject.FixedAssetCostAndDepreciationAdjustment - 
//  FormServiceParameters - Structure - 
// 
// Returns:
//  Boolean - 
Function GetParametersOfAccountingPoliciesForPeriod(Object, FormServiceParameters) Export
	
	ReglParametersAreReceived = False;
	
	
	Return ReglParametersAreReceived;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.FixedAssetCostAndDepreciationAdjustment - 
//  Basis - DocumentRef.ChangeFixedAssetFinancialDetails2_4 - 
// 
// Returns:
//  Boolean - 
Function FillInDocumentBasedOnChangeInFAParameters(Object, Basis) Export
	
	ContinuePopulation = True;
	
	
	Return ContinuePopulation;
	
EndFunction

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

Procedure TablesOfDeferredMotionFormation(QueryTexts) Export

	
EndProcedure
 
Function QueryTextTableInitialFixedAssetsInformation(QueryTexts) Export

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
	
	QueryText = "";

	
	Return QueryText;
	
EndFunction

#EndRegion

#Region DocumentForm

Procedure ProcessResultOfFillingInDepreciationCalculationParameters(Object, ParametersForCalculation, AccountingSection) Export
	
	
EndProcedure

#EndRegion


#EndRegion
