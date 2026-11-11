////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Entering balances of non-current assets".
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

// Adds to the request text the document details of the input statesnotable Actives2_4
//
// Parameters:
//  QueryText - String	 - Source text of the request that should contain the field "&Enter the states_reference_active_requisit_folder".
//  TableName	 - String	 - Name of the document table.
//
Procedure AddHeaderDetailsToRequestText(QueryText, TableName) Export

	FieldsLocalization = "NULL";
	
	
	QueryText = StrReplace(QueryText, "&EnteringBalancesOfNonCurrentAssets_HeaderDetails", FieldsLocalization);
	
EndProcedure

#EndRegion

#Region Internal

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.EntryOfCapitalAssetsBalance2_4 - the document being processed.
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
//  Object - DocumentObject.EntryOfCapitalAssetsBalance2_4 - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.EntryOfCapitalAssetsBalance2_4 - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  FillingText - String, Undefined - Text used to fill in the document. 
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, FillingText, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.EntryOfCapitalAssetsBalance2_4 - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure UndoPosting(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
// 
// Parameters:
//  Object - DocumentObject.EntryOfCapitalAssetsBalance2_4 - processed object
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
//  Object - DocumentObject.EntryOfCapitalAssetsBalance2_4 - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.EntryOfCapitalAssetsBalance2_4 - processed object
//  CopiedObject - DocumentObject.EntryOfCapitalAssetsBalance2_4 - The source document that is the copy source.
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
// Returns:
//  String - Query text
Function QueryTextTableInitialFixedAssetsInformation(QueryTexts) Export
	
	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

// 
// Returns:
//  String - Query text
Function QueryTextTableInitialIntangibleAssetsInformation(QueryTexts) Export
	
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

// 
// Returns:
//  String - Query text
Function QueryTextTableIACost() Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

// 
// Returns:
//  String - Query text
Function QueryTextTableIntangibleAssetsAmortizationCharge() Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

// 
// Returns:
//  String - Query text
Function QueryTextTableFixedAssetsAccountingProcedureManagementAccounting() Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction

// 
// Returns:
//  String - Query text
Function QueryTextTableIntangibleAssetsAccountingProcedureManagementAccounting() Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction
 
Function AdaptedCaseSensitiveQueryText(RegisterName, RedefiningParameterCalculation, SynonymForDocumentTable) Export

	QueryText = Undefined;
	QueryTexts = New ValueList;
	
	
	Return QueryText;
	
EndFunction

Procedure ProcessFABeforeWriting(Object) Export

	
EndProcedure

Procedure ProcessIABeforeRecording(Object) Export

	
EndProcedure

// Adds parameters for selecting articles and Analytics.
// 
// Parameters:
// 	ItemsAndDimensionsSelectionParameters - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
Procedure AddOptionsForSelectingArticlesAndAnalytics(ItemsAndDimensionsSelectionParameters) Export

	
EndProcedure

#EndRegion

#Region FormFixedAssets

Procedure FormAssets_ConfigureDependentFormElements(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure FixedAssetsForm_AddParametersForSelectingArticlesAndAnalytics(ItemsAndDimensionsSelectionParameters) Export

	
EndProcedure

Procedure FormFixedAssets_WhenExecutingCommand(CommandName, Form) Export
	
	Object = Form.Object;
	
	
EndProcedure

#EndRegion

#Region FormIntangibleAssets

Procedure FormIntangibleAssets__DependentFormElements(Form, StructureOfChangedProps) Export

	
EndProcedure
 
Procedure FormIntangibleAssets_WhenExecutingCommand(CommandName, Form) Export
	
	Object = Form.Object;
	
	
EndProcedure
 
#EndRegion

#Region FormLeasedFixedAssets_

Procedure FormLeasedFixedAssets_ConfigureDependentElementsOfForm(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure FormLeasedFixedAssets_WhenExecutingCommand_(CommandName, Form) Export
	
	Object = Form.Object;
	
	
EndProcedure

#EndRegion

#Region FormLeasedFixedAssets

Procedure LeasedFixedAssetsForm_ConfigureDependentFormElements(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure FormLeasedFixedAssets_WhenExecutingCommand(CommandName, Form) Export
	
	Object = Form.Object;
	
	
EndProcedure

#EndRegion

#Region FormOfLeasingItemsOnBalance

Procedure FormLeaseItemsOnBalance_ConfigureDependentFormItems(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure FormIntangibleAssets_SupplementParametersForSelectingArticlesAndAnalysts(ItemsAndDimensionsSelectionParameters) Export

	
EndProcedure

Procedure FormLeasingItemsForBalance_WhenExecutingCommand(CommandName, Form) Export
	
	Object = Form.Object;
	
	
EndProcedure

#EndRegion

#Region FormOfInvestmentInNonCurrentAssets

Procedure FormOfInvestmentInNonCurrentAssets_ConfigureDependentElementsOfForm(Form, StructureOfChangedProps) Export

	
EndProcedure
 
#EndRegion

#Region FormSettlementsUnderLeaseAgreements

Procedure LeaseSettlementForm_ConfigureDependentFormElements(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure FormSettlementsUnderLeaseAgreements_WhenExecutingCommand(CommandName, Form) Export
	
	Object = Form.Object;
	
	
EndProcedure

#EndRegion

#Region FALineEditingForm

Procedure FormForEditingOS_StringWhenReadingFileOnServer(Form) Export

	
EndProcedure

Procedure FormEditStringOS_ConfigureDependentFormElements(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure FormForEditingOS_LineWhenChangingProps(TagName, Form, AdditionalParameters) Export

	
EndProcedure

Procedure FormForEditingOSString_FillInFADetails(Form) Export

	
EndProcedure

#EndRegion

#Region IALineEditingForm

Procedure IALineEditingForm_OnChangeAttribute(TagName, Form, AdditionalParameters) Export

	
EndProcedure

Procedure FormEditStringNMA_ConfigureDependentFormElements(Form, StructureOfChangedProps) Export

	
EndProcedure

Procedure IALineEditingForm_WhenReadingDataOnServer(Form) Export

	
EndProcedure

Procedure FormForEditingLineNMA_FillInIADetails(Form) Export

	
EndProcedure

Procedure LineEditingFormNMA_FillInDefaultValues(Form) Export

	
EndProcedure
 
#EndRegion

#Region Other

Procedure InitializeDocumentBeforeFillingItOut(Object) Export

	
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

Procedure AddAuxiliaryDetails(Object, ThisIsStringData, AuxiliaryAttributes) Export

	
EndProcedure

Procedure AddAuxiliaryDetailsBasedOnLineData(Object, RowData, AuxiliaryAttributes) Export

	
EndProcedure

Procedure FillInDefaultValues(RowData, Object) Export
	
	
EndProcedure

Function BalancesByTypeOfOperation(Date, BusinessOperation, Companies, AdditionalSelection = Undefined, ParametersForFillingBalances = Undefined) Export

	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

// 
// Parameters:
//  QueryTexts - Array -
// 
// Returns:
//  String - Query text
Function QueryTextTableAccountingProcedureForOSBU(QueryTexts) Export

	QueryText = Undefined;
	

	Return QueryText;
	
EndFunction

// 
// Parameters:
//  QueryTexts - Array -
// 
// Returns:
//  String - Query text
Function QueryTextTableIABookkeepingProcedureBookkeepingAndTaxAccounting(QueryTexts) Export

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
//  QueryTexts - Array - 
// 
// Returns:
//  String - Query text
Function QueryTextTableIADepreciationParametersBookkeepingAndTaxAccounting(QueryTexts) Export
	
	QueryText = Undefined;


	Return QueryText;
	
EndFunction


#EndRegion

#Region FALineEditingForm

Procedure FormOfEditingLineOS_OrderOfAccountingForBUWhenChanging(Form, ChangedBankingDetails) Export


EndProcedure

Procedure FormForEditingLineOS_DepreciationMethodBUWhenChanging(Form) Export
	
	
EndProcedure

Procedure FormForEditingOS_LineIsMainMeansWhenChanging(Form) Export

	
EndProcedure


#EndRegion

#Region IALineEditingForm


#EndRegion


#EndRegion
