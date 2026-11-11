
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
//  CopiedObject - DocumentObject - The source document that is the copy source.
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
#Region DocumentGeneration

// Called from Documents.Distributionof revenue directionsof activity.Setdatecreated()
// Before generating the documents.
// 
// Parameters:
//	Period - Date - The beginning of the month for which you need to create documents.
//	Organization - Array, Undefined - List of organizations for which documents are generated. If the list is empty,
//												documents are generated for all organizations.
// 	TempTablesManager - TempTablesManager - The temporary table Manager contains an Organization table 
// 	                                            with sections for creating documents.
//
Procedure BeforeCreatingDocumentsForPeriod(Period, Organization, TempTablesManager) Export
	
	
EndProcedure

// Distributes income by line of business when completing the closing of the month.
// 
// Parameters:
//  HandlerParameters - Structure -
//  CompanyArray - Array of CatalogRef.Companies -
//
Procedure DistributeIncomeByLineOfBusiness(HandlerParameters, CompanyArray) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	BeginOfPeriod = BegOfMonth(CalculationParameters.RegistrationPeriod);
	EndOfPeriod  = EndOfMonth(CalculationParameters.RegistrationPeriod);
	
	TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber();
	
	CalculatedOrganizations = New Array;
	
	BeginTransaction();
	
	Try
		
		MonthEndTransactionsServer.BlockTaskRegister(
			TaskNumberBeforeCalculation,
			CalculationParameters.CompanyArray,
			HandlerParameters.Data_Stage.Code);
		
		DataToDistribution = MonthEndTransactionsServer.MonthlyTasks(
			BeginOfPeriod,
			EndOfPeriod,
			TaskNumberBeforeCalculation,
			CalculationParameters.CompanyArray,
			HandlerParameters.Data_Stage.Code);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
				|%2';
				|ru = 'При выполнении расчета за период %1 произошла ошибка:
				|%2';
				|en = 'An error occurred when calculating for the %1 period:
				|%2'; fa = 'An error occurred when calculating for the %1 period:
				|%2';
				|it = 'При выполнении расчета за период %1 произошла ошибка:
				|%2';
				|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
				|%2';
				|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
				|%2'"),
			CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
			DetailErrorDescription(ErrorInfo()));
		
		MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
			HandlerParameters,
			ErrorText,
			CalculationParameters.CompanyArray,
			CalculationParameters.RegistrationPeriod);
		
	EndTry;
	
	For Each CurrentCompany In CompanyArray Do
		
		Try
			
			Documents.AllocationOfIncomeByLinesOfBusiness.CreateDocumentsForPeriod(
				BeginOfPeriod, 
				CurrentCompany);
				
			If Not DataToDistribution.Organization.Find(CurrentCompany) = Undefined
				And CalculatedOrganizations.Find(CurrentCompany) = Undefined Then
				CalculatedOrganizations.Add(CurrentCompany);
			EndIf;
			
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Việc phân bổ thu nhập cho các mảng hoạt động trong kỳ %1 đã kết thúc bị lỗi
					|%2';
					|ru = 'Распределение доходов по направлениям деятельности за период %1 завершилось с ошибкой:
					|%2';
					|en = 'Income allocation by lines of business for the period %1 ended with the error:
					|%2'; fa = 'Income allocation by lines of business for the period %1 ended with the error:
					|%2';
					|it = 'Распределение доходов по направлениям деятельности за период %1 завершилось с ошибкой:
					|%2';
					|pl = 'Podział dochodów wg kierunków działalności za okres %1 jest zakończony z błędem:
					|%2';
					|tr = 'Dönem %1 için iş kollarına göre gelir dağıtımı  hata ile sona erdi:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(BeginOfPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				CurrentCompany,
				BeginOfPeriod);
			
		EndTry;
			
	EndDo;
	
	If CalculatedOrganizations.Count() > 0 Then
		
		BeginTransaction();
		
		Try
			
			MonthEndTransactionsServer.BlockTaskRegister(
				TaskNumberBeforeCalculation,
				CalculatedOrganizations,
				HandlerParameters.Data_Stage.Code);
			
			MonthEndTransactionsServer.FixCalculation(
				Undefined,
				HandlerParameters.Data_Stage.Code,
				DataToDistribution.TemporaryTable);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
					|%2';
					|ru = 'При выполнении расчета за период %1 произошла ошибка:
					|%2';
					|en = 'An error occurred when calculating for the %1 period:
					|%2'; fa = 'An error occurred when calculating for the %1 period:
					|%2';
					|it = 'При выполнении расчета за период %1 произошла ошибка:
					|%2';
					|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
					|%2';
					|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
					|%2'"),
				CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				CalculatedOrganizations,
				CalculationParameters.RegistrationPeriod);
			
		EndTry;
		
	EndIf;
	
	DataProcessors.MonthEndClosingOperations.RegisterStageCalculationProblems(HandlerParameters);
	
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

// Changes the text of the formation of unproceeded
// 
// Parameters:
// 	QueryText - String - The text of the query formation unproceeded
// 	Query - Query - Request for document execution
//  QueryTexts - ValueList - A list of document execution requests.
//
Procedure ChangeQueryTextOfTableTTOtherExpenses(QueryText, Query, QueryTexts) Export
	
EndProcedure



#EndRegion

#EndRegion
