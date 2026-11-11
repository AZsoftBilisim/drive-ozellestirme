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
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
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
Procedure OnWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  CopiedObject - DocumentObject.AllocationOfOtherCosts - The source document that is the copy source.
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

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
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

//Registers the document for reflection in the regulated accounting.
//Parameters:
//	Document - DocumentRef.AllocationOfOtherCosts - document to reflect.
//
Procedure RegisterDocumentReflection(Document) Export
	
				
EndProcedure

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return "";
	
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
#Region FillType

// Set the signs of AC and TA.
// 
// Parameters:
//  Object - DocumentObject.AllocationOfOtherCosts - Distribution document.
//  AccountingKind - String - Type of accounting
//  DistributionSettings - Structure - Distribution settings.
Procedure SetSignsOfBUITa(Object, AccountingKind, DistributionSettings, SettingsOfACAndTACorrespondTo) Export
	
	
	Return; // so that the method is not empty without the personal data. 
	
EndProcedure

#EndRegion

#Region DocumentGeneration

// Find the right document.
// 
// Parameters:
//  DocumentDistributions - DocumentObject.AllocationOfOtherCosts - Distribution document.
//  AccountingKind - String - Type of accounting.
//  FillParameters - Structure - Parameters for filling in the document.
// 
// Returns:
//  Boolean - Indicates that the document has been found.
Function FindRightDocument(DocumentDistributions, AccountingKind, FillParameters) Export
	
	DocumentFound = False;
	
	If DocumentDistributions.LocalAccounting And DocumentDistributions.TaxAccounting Then
		DocumentFound = CheckComplianceOfLocalTaxSettingsWithAIT(FillParameters);
	ElsIf DocumentDistributions.TaxAccounting Then
		DocumentFound = CheckComplianceOfSettingsWithNalAIT(FillParameters);
	ElsIf DocumentDistributions.LocalAccounting Then
		DocumentFound = CheckComplianceOfSettingsWithLocalAIT(FillParameters);
	EndIf;
	
	Return DocumentFound;
	
EndFunction

// Generates cost allocation documents when completing the closing of the month.
//
// Parameters:
//	HandlerParameters - Structure -
//	ItemsTable - ValueTable -
//
Procedure FormationOfDocumentsAndDistributionOfOtherCosts(HandlerParameters, ItemsTable) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	DistributionParameters = New Structure("ExpenseParameters", ItemsTable);
	DistributionParameters.Insert("CompanyArray", CalculationParameters.CompanyArray);
	DistributionParameters.Insert("RegistrationPeriod", CalculationParameters.RegistrationPeriod);
	
	Try
		FormationResults = Documents.AllocationOfOtherCosts.GenerateDocuments(DistributionParameters, Undefined);
	Except
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo chứng từ phân bổ chi phí trong kỳ %1 do lỗi:
				|%2';
				|ru = 'Не удалось создать документы распределения расходов за период %1 из-за ошибки:
				|%2';
				|en = 'Cannot generate expense allocation documents for the period %1 due to the error:
				|%2'; fa = 'Cannot generate expense allocation documents for the period %1 due to the error:
				|%2';
				|it = 'Не удалось создать документы распределения расходов за период %1 из-за ошибки:
				|%2';
				|pl = 'Nie można utworzyć dokumentów dystrybucyjnych za okres %1 z powodu błędu:
				|%2';
				|tr = '%1 dönemi için gider dağıtım belgelerinin oluşturulamama hatası:
				|%2'", Common.DefaultLanguageCode()),
			CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
			DetailErrorDescription(ErrorInfo()));
		
		MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
			HandlerParameters,
			ErrorText);
		
	EndTry;
	
	For Each OrganizationResults In FormationResults Do
		
		FormationDetails = OrganizationResults.Value;
		
		If Not FormationDetails.ErrorsDescription.Count() Then
			Continue;
		EndIf;
		
		For Each ErrorDescription In FormationDetails.ErrorsDescription Do
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorDescription.ErrorText,
				OrganizationResults.Key,
				,
				,
				ErrorDescription.ExpenseItem);
		EndDo;
		
	EndDo;
	
	DataProcessors.MonthEndClosingOperations.RegisterStageCalculationProblems(HandlerParameters);
	
EndProcedure

// Allocates expenses for the financial result when completing the closing of the month.
//
// Parameters:
//	HandlerParameters - Structure -
//	ResultTable2 - ValueStorage - contains a table of values
//	DocumentsWithNewRegisteredRecords - ValueStorage - contains a table of values
//
Procedure ExpenseAllocationToFinancialResult(HandlerParameters, ResultTable2, DocumentsWithNewRegisteredRecords) Export
	
	Period = HandlerParameters.CalculationParameters.RegistrationPeriod;

	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;

	Table = ResultTable2.Get();
	CostCalculationAppliedAlgorithms.CorrectTypingOfColumnsInTableOfValues(Table);
	
	Query.SetParameter("ResultTable2", Table);
	
	Query.Text =
	"SELECT
	|	*
	|INTO AllocationResult
	|FROM
	|	&ResultTable2 AS T
	|";
	
	Query.Execute();
	
	Query.SetParameter("DocumentsWithNewRegisteredRecords", DocumentsWithNewRegisteredRecords.Get());
	
	Query.Text =
	"SELECT
	|	T.Recorder
	|INTO DocumentsWithNewRegisteredRecords
	|FROM
	|	&ResultTable2 AS T
	|INDEX BY
	|	Recorder
	|";
	
	Query.Execute();
	
	Documents.AllocationOfOtherCosts.DistributeNextPortionOfExpensesForFinancialResult(
		HandlerParameters,
		Query.TempTablesManager,
		Period);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

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

#EndRegion

#Region DocumentGeneration
	
Function CheckComplianceOfLocalTaxSettingsWithAIT(FillParameters)
	
	SettingsCorrespondTo = False;
	
	Return SettingsCorrespondTo;
	
EndFunction

Function CheckComplianceOfSettingsWithLocalAIT(FillParameters)
	
	SettingsCorrespondTo = False;
	
	Return SettingsCorrespondTo;
	
EndFunction

Function CheckComplianceOfSettingsWithNalAIT(FillParameters)
	
	SettingsCorrespondTo = False;
	
	Return SettingsCorrespondTo;
	
EndFunction

#EndRegion

#EndRegion
