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

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure AddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure

// The procedure supplements the text of the request for a document to be processed in the document Registry.
//
// Parameters:
//  Query - Query - General request for document execution.
//  TextOfEvent - ValueListItem - text of the event request.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure AddRequestTextToDocumentRegistry(Query, TextOfEvent, Registers) Export
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	
EndProcedure
#EndRegion

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.ReceivedTaxInvoicePrepayment - the document being processed.
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
//  Object - DocumentObject.ReceivedTaxInvoicePrepayment - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array of String - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	NotCheckedAttributeArray = New Array();
	
	If Not Object.DrawnUpByCommissionAgentOnBehalfOfSeller Then
		NotCheckedAttributeArray.Add("Sellers");
	EndIf;
	
	If Not Object.Corrective Then
		NotCheckedAttributeArray.Add("Prepayments.OriginalTaxInvoice");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.ReceivedTaxInvoicePrepayment - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.ReceivedTaxInvoicePrepayment - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure UndoPosting(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.ReceivedTaxInvoicePrepayment - processed object
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
//  Object - DocumentObject.ReceivedTaxInvoicePrepayment - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.ReceivedTaxInvoicePrepayment - processed object
//  CopiedObject - DocumentObject.ReceivedTaxInvoicePrepayment - The source document that is the copy source.
//
Procedure OnCopy(Object, CopiedObject) Export
	
	
EndProcedure

#EndRegion

#Region AttachableCommands

// Defines a list of creation commands based on.
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//	Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - ValueTable - A table with report commands. For changes.
//       See the description of parameter 1 of the report variationreferences procedure.Before adding Team reports().
//   Parameters - Structure - Auxiliary parameters. For reading.
//       See the description of the 2 parameters of the procedure variationreportable.Before adding Team reports().
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection.
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array of DocumentRef.ReceivedTaxInvoicePrepayment - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	
EndProcedure

#EndRegion
#Region RegAccountingTransactions

// Generates the request text to reflect the document in the regulated accounting.
//
// Parameters:
//	QueryText - String - Query text
//
Procedure GenerateReflectionTextInLocalAccounting(QueryText) Export
	
	
EndProcedure

// Generates the request text for additional temporary tables
// required for reflection in regulated accounting
//
// Parameters:
//  QueryText - String - Text of the request for creating temporary tables.
//
Procedure GenerateRequestTextTTForReflectionInLocalAccounting(QueryText) Export
	
	
EndProcedure

#EndRegion
#Region Other

// Fill in the code of the invoice operation type
// 
// Parameters:
// 	Object - DocumentObject.ReceivedTaxInvoicePrepayment - Document where the operation type code is filled in
Procedure FillInOperationTypeCode(Object) Export
	
	
EndProcedure

// Will override the VAT rate, which is specified in the invoice
// 
// Parameters:
// 	AdvanceVATRate - CatalogRef.VATRates - VAT rate
Procedure SetAdvanceVATRate(AdvanceVATRate) Export
	
	
EndProcedure

// Complements the text of the request for receiving data of payment documents
// 
// Parameters:
// 	ArrayOfRequestTexts - Array of String - An array of the text of the request for these documents
// 	Query - Query - Request for setting parameters
//
Procedure AddRequestTextsForTheseDocuments(ArrayOfRequestTexts, Query) Export
	
	
EndProcedure

// Complements the array of object managers that form the "See also" link in the workplace.
// 
// Parameters:
// 	ArrayOfManagersSeeAlso - Array of String - Full names of objects to get the RM reference
//
Procedure FillInManagersSeeAlsoWorkplace(ArrayOfManagersSeeAlso) Export
	
	
EndProcedure

#EndRegion

#EndRegion

