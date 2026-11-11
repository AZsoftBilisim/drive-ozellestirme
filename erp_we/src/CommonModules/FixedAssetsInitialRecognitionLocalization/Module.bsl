////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Acceptance of the OS".
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

#Region Private

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - the document being processed.
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
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - processed object
//  Cancel - Boolean - 
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//  AuxiliaryAttributes - Structure -
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes, AuxiliaryAttributes) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  FillingText - String, Undefined - Text used to fill in the document. 
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, FillingText, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure UndoPosting(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - processed object
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
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - processed object
//  CopiedObject - DocumentObject.FixedAssetsInitialRecognition2_4 - The source document that is the copy source.
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

Function GetDataForPrintedFormOS1(PrintParameters, ObjectsArray) Export
	
	DataForPrintedForm = Undefined;
	
	
	Return DataForPrintedForm;
	
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
	
	QueryText = "";
	
	Return QueryText;
	
EndFunction

#EndRegion
#Region Posting

Function AdaptedCaseSensitiveQueryText(RegisterName, RedefiningParameterCalculation, SynonymForDocumentTable) Export

	QueryText = Undefined;
	QueryTexts = New ValueList;
	
	
	Return QueryText;

EndFunction

Procedure ValuesOfHoldingParameters(ValuesOfHoldingParameters) Export

	
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

Procedure AddRequestTextTrafficTableIncomeExpensesOtherAssetsLiabilities(ListOfMergeRequests) Export

	
EndProcedure

Procedure CheckHeaderDetails_(Object, Cancel) Export

	
EndProcedure

Function CheckOrderDoNotTakeIntoAccountIncludeInExpenses(Object, Cancel) Export

	CheckCompleted = False;
	
	
	Return CheckCompleted;
	
EndFunction

Function QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts) Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFACost(Query, QueryTexts) Export

	QueryText = Undefined;
	
	
	Return QueryText;

EndFunction

Function QueryTextTableFixedAssetsDepreciationCharge(Query, QueryTexts) Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Add_Fields) Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

Function QueryTextTableAccountingProcedureForOSBU() Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsAccountingProcedureManagementAccounting() Export

	QueryText = Undefined;
	
	
	Return QueryText;

EndFunction

Function QueryTextTableFixedAssetsAccountingProcedure() Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOSBUDepreciationParameters() Export
	
	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

// 
// Parameters:
// 	Object - DocumentObject.FixedAssetsInitialRecognition2_4 - 
// 	Cancel - Boolean
Procedure CheckAcceptanceForAccountingUnderLeaseAgreementBeforeWrite(Object, Cancel) Export
	
	
EndProcedure

#EndRegion

#Region DocumentForm
 
Procedure OnReadCreateAtServer(Form) Export

	
EndProcedure

Procedure AfterWriteAtServer(Form, CurrentObject, WriteParameters) Export

	
EndProcedure

Procedure OnChangeAttribute(TagName, Form, AdditionalParameters) Export

	
EndProcedure

Procedure OnExecuteCommand(CommandName, Form) Export
	
	
EndProcedure

Procedure FAFixedAssetOnChange(Form, ChangedBankingDetails) Export

	
EndProcedure

Procedure FACostInAccountingOnChange(Form, CurrentData) Export

	
EndProcedure

Procedure ProcessingElementSelection(Form, ChangedBankingDetails) Export


EndProcedure

Procedure ConfigureDependentFormElements(Form, StructureOfChangedProps) Export

	
EndProcedure
 
// 
// Parameters:
// 	ConditionalAppearance - ConditionalAppearance - 
// 	Items - FormItems - 
Procedure SetConditionalAppearance(ConditionalAppearance, Items) Export
	
	
EndProcedure

#EndRegion

#Region FillingInDocument_

// Fills in the document based on the object of operation.
// 
// Parameters:
//  Object - DocumentObject.FixedAssetsInitialRecognition2_4 - 
//  Basis - CatalogRef.Assets
Procedure FillInBasedOnObjectOfOperation(Object, Basis) Export

	
EndProcedure

Procedure FillInBasedOnAcceptanceForAccountingOrEnteringBalances(Object, Basis) Export

	
EndProcedure

// 
// Parameters:
// 	Object - DocumentObject.FixedAssetsInitialRecognition2_4 - 
// 	Basis - DocumentRef.SigningOfLeaseContract - 
Procedure FillInBasedOnConclusionOfLeaseAgreement(Object, Basis) Export

	
EndProcedure

// 
// Parameters:
// 	Object - DocumentObject.FixedAssetsInitialRecognition2_4 - 
// 	Basis - DocumentRef.LeaseTermAdjustment - 
Procedure FillInOnBasisOfRentalTermsADJUSTMENTChanges(Object, Basis) Export

	
EndProcedure

// 
// Parameters:
// 	Object - DocumentObject.FixedAssetsInitialRecognition2_4 - 
//	ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems -
Procedure FillInBasedOnGroupOS(Object, ExpenseItem) Export
EndProcedure

#EndRegion

#Region Other

Procedure AddAuxiliaryDetails(Object, AuxiliaryAttributes) Export

	
EndProcedure

Procedure FillInCost(Object, StringsList, FATable) Export

	
EndProcedure

// Adds parameters for selecting articles and Analytics.
// 
// Parameters:
// 	ArticleSelectionAndAnalyticsOptions - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
Procedure AddOptionsForSelectingArticlesAndAnalytics(ArticleSelectionAndAnalyticsOptions) Export

	
EndProcedure

#EndRegion

#Region Posting


#EndRegion

#Region FillingInDocument_


#EndRegion

#Region DocumentForm


#EndRegion

#EndRegion
