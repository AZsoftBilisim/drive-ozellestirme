
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

// displays a message to the user if there is a nomenclature in the table of goods for import, 
// with the CCD numbers off.
//
// Parameters:
//	Object - DocumentObject, Structure - object that is being checked in the table part.
//	Goods - FormDataCollection - the goods table of the document with the following required fields:
//		* Products - CatalogRef.Products - product.
//	DocumentDate - Date - date of the document, to verify its use in traceability.
//	TabularSectionName - String - name of the table part to highlight the cell with an error in it.
//	NameOfProductItemInTablePart - String - name of the table part's props to highlight the error in it.
//
Procedure CheckCorrectnessOfCCDProductSettings(Object,
												  Goods,
												  DocumentDate,
												  TabularSectionName = "Goods",
												  NameOfProductItemInTablePart = "Products") Export
	
	
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
//@skip-warning
Procedure Posting(Object, Cancel, PostingMode) Export
	
		
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
//@skip-warning
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
//@skip-warning
Procedure Filling(Object, FillingData, StandardProcessing) Export
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
//@skip-warning
Procedure UndoPosting(Object, Cancel) Export
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
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
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
//@skip-warning
Procedure OnWrite(Object, Cancel) Export
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  CopiedObject - DocumentObject.CCDImport - The source document that is the copy source.
//
//@skip-warning
Procedure OnCopy(Object, CopiedObject) Export
EndProcedure

#EndRegion

// Sets the mask for entering the customs Declaration number.
//
// Parameters:
// 	Mask - String - Mask for entering the customs Declaration number
//
Procedure SetMaskOfCustomsDeclarationNumber(Mask) Export
	
	
EndProcedure

#Region AttachableCommands

//@skip-warning
// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
EndProcedure

//@skip-warning
// Adds a command of creation of the document "expense report".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
Procedure AddGenerateCommand(GenerationCommands) Export
EndProcedure

// @skip-warning
// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters.
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
EndProcedure

//@skip-warning
// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
Procedure AddPrintCommands(PrintCommands) Export
	
	
EndProcedure

#EndRegion
#Region RegAccountingTransactions

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	//@skip-warning
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	QueryTexts = New Array;
	
	
	Return StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
EndFunction


#EndRegion
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

