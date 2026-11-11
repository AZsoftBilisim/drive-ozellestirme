////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Input of Balances of nodes, depreciation components".
// 
////////////////////////////////////////////////////////////////////////////////

#Region Private

#Region FormFixedAssets

Procedure FormAssets_ConfigureDependentFormElements(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure FormFixedAssets_WhenExecutingCommand(CommandName, Form) Export
	
	Object = Form.Object;
	
	
EndProcedure

#EndRegion

#Region FALineEditingForm

Procedure FormForEditingOS_StringWhenReadingFileOnServer(Form) Export

	
EndProcedure

Procedure FormEditStringOS_ConfigureDependentFormElements(Form, StructureOfChangedProps) Export

	
EndProcedure

// 
// Parameters:
//  ObjectOrStringData - LineOfATabularSection - 
//  AuxiliaryAttributes - Structure - 
//  AttributeParameters - Array of Structure -
//  Action - String -
//  ChangedBankingDetails - Array of String -
// 
Procedure FillInDetailsDependingOnProperties(ObjectOrStringData, AuxiliaryAttributes, AttributeParameters, Action, ChangedBankingDetails) Export

	
EndProcedure

#EndRegion

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
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

// 
// Parameters:
//  QueryTexts - ValueList - List of texts of the request for holding.
// 
// Returns:
//  String - Query text
Function QueryTextTableInitialFixedAssetsInformation(QueryTexts) Export
	
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

// 
// Parameters:
//  QueryTexts - ValueList - List of texts of the request for holding.
// 
// Returns:
//  String - Query text
Function QueryTextTableAccountingProcedureForOSBU(QueryTexts) Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction

// 
// Returns:
//  String - Query text
Function QueryTextTableFACost() Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

// 
// Returns:
//  String - Query text
Function QueryTextTableFixedAssetsDepreciationCharge() Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction


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

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.OBEntrySubAssetsAndComponentsOfDepreciation - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure Posting(Object, Cancel, PostingMode) Export
	
EndProcedure

// Called from the corresponding document handler
// 
// Parameters:
//  Object - DocumentObject.OBEntrySubAssetsAndComponentsOfDepreciation - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.OBEntrySubAssetsAndComponentsOfDepreciation - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  FillingText - String, Undefined - Text used to fill in the document. 
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, FillingText, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.OBEntrySubAssetsAndComponentsOfDepreciation - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure UndoPosting(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
// 
// Parameters:
//  Object - DocumentObject.OBEntrySubAssetsAndComponentsOfDepreciation - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure BeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	
	
EndProcedure

// Called from the corresponding document handler
// 
// Parameters:
//  Object - DocumentObject.OBEntrySubAssetsAndComponentsOfDepreciation - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.OBEntrySubAssetsAndComponentsOfDepreciation - processed object
//  CopiedObject - DocumentObject.OBEntrySubAssetsAndComponentsOfDepreciation - The source document that is the copy source.
//
Procedure OnCopy(Object, CopiedObject) Export
	
	
EndProcedure

#EndRegion

#Region FillingInAccordingToOperationalAccountingData

Function BalancesByTypeOfOperation(Date, Companies, AdditionalSelection = Undefined, ParametersForFillingBalances = Undefined) Export

	
	Return Undefined;
	
EndFunction


#EndRegion

#Region Other

Procedure InitializeDocumentBeforeFillingItOut(Object) Export

	
EndProcedure

Procedure AddAuxiliaryDetails(Object, ThisIsStringData, AuxiliaryAttributes) Export

	
EndProcedure

#EndRegion

#EndRegion