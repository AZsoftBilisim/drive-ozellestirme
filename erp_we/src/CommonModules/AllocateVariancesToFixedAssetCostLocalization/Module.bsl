////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Attribution of deviations to the cost of the FA".
// 
////////////////////////////////////////////////////////////////////////////////

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

#Region Other

// Adds the details of the document header to the request text.
//  Details are added instead of the parameter "&Modernization_requisitydocument".
//
// Parameters:
//  QueryText - String	 - Source text of the request.
//  TableName	 - String	 - Synonym for the document table in the query.
//
Procedure AddDocumentDetailsToRequestText(QueryText, TableName) Export

	LocalizationFields = 
	"UNDEFINED AS TargetFinancingApplicationOption
	|	,DocumentData.AccountingProcedureTA AS AccountingProcedureTA";
	

	QueryText = StrReplace(QueryText, "&DocumentAttributes", LocalizationFields);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.AllocateVariancesToFixedAssetCost - the document being processed.
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
//  Object - DocumentObject.AllocateVariancesToFixedAssetCost - The object being processed.
//  Cancel - Boolean - 
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//  ItemDetailsParameters - See NonCurrentAssetsClientServer.PropertyValuesOfDependentProps__FA
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes, ItemDetailsParameters) Export
	
	
EndProcedure

// Called from the corresponding document handler
// 
// Parameters:
//  Object - DocumentObject.AllocateVariancesToFixedAssetCost - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  FillingText - String - 
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
Procedure Filling(Object, FillingData, FillingText, StandardProcessing) Export
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.AllocateVariancesToFixedAssetCost - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure UndoPosting(Object, Cancel) Export
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.AllocateVariancesToFixedAssetCost - processed object
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
//  Object - DocumentObject.AllocateVariancesToFixedAssetCost - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.AllocateVariancesToFixedAssetCost - processed object
//  CopiedObject - DocumentObject.AllocateVariancesToFixedAssetCost - The source document that is the copy source.
//
Procedure OnCopy(Object, CopiedObject) Export
	
EndProcedure

#EndRegion

#Region AttachableCommands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
EndProcedure

// Adds a command of creation of the document "expense report".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Procedure AddGenerateCommand(GenerationCommands) Export

EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// Adds print commands.
// 
// Parameters:
// 	PrintCommands - See PrintManagement.CreatePrintCommandsCollection
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
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
Procedure TablesForCalculatingCost(Query, QueryTexts) Export
	
	
EndProcedure

//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//
Procedure TablesOfDeferredMotionFormation(Query, QueryTexts) Export
	
	
EndProcedure

Procedure AddRequestTextFACostTable(ListOfMergeRequests) Export

	
EndProcedure

Procedure AddRequestTextTableTTInitialOtherExpenses(ListOfMergeRequests) Export

	
EndProcedure
 
Procedure AddAuxiliaryDetails(Object, AuxiliaryAttributes) Export

	
EndProcedure
 
#EndRegion

#Region DocumentForm

Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
EndProcedure

Procedure OnReadAtServer(Form, CurrentObject) Export
	
EndProcedure
 
Procedure OnReadCreateAtServer(Form) Export

	
EndProcedure

Procedure AfterWriteAtServer(Form) Export

	
EndProcedure

Procedure FillInServiceParameters(DocumentServiceParameters) Export

	
EndProcedure

Procedure ConfigureDependentFormElements(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure SetConditionalAppearance(Form) Export

	
EndProcedure
  
#EndRegion

#Region Posting

Function QueryTextTableAccountingProcedureForOSBU() Export
	
	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOSBUDepreciationParameters(QueryTexts) Export
	
	QueryText = Undefined;
	
	
	Return QueryText;

EndFunction


#EndRegion

#Region DocumentForm


#EndRegion

#Region Other


#EndRegion

#EndRegion
