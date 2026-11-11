#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("FutureExpenseCommitments");
	CalculationOfDiscountInterestExpensesLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.CalculationOfDiscountInterestExpenses") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		CalculationOfDiscountInterestExpenses(Query, DocumentRef);
		CalculationOfInterestExpenseOfDiscountingReserves(Query, Document);
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableDiscountInterestExpense(QueryTexts, Registers);
		QueryTextTableOtherExpenses(QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(QueryTexts, Registers);
		QueryTextFutureExpenseCommitments(QueryTexts, Registers);
		CalculationOfDiscountInterestExpensesLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
		
	CalculationOfDiscountInterestExpensesLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "calculation of exchange differences".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
// 	Undefined
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CalculationOfDiscountInterestExpenses) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CalculationOfDiscountInterestExpenses.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CalculationOfDiscountInterestExpenses);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseMultipleCurrencies";
		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.DetailedCalculationOfDiscountingInterestExpenseWriteOff.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;	
	ReportCommand = Reports.DetailedCalculationOfDiscountingOfProvisionsAndContingentLiabilities.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	CalculationOfDiscountInterestExpensesLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure
// Returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CalculationOfDiscountInterestExpensesLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return CalculationOfDiscountInterestExpensesLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction
#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Internal

#Region CalculationOfDiscountInterestExpenses

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_CalculationOfDiscountInterestExpenses(StepsTable,CurrentParent) Export
	
	GenerateFutureExpenseCommitments = True;
	GenerateFutureExpenseCommitments = GetFunctionalOption("GenerateFutureExpenseCommitments");
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.CalculationOfDiscountInterestExpenses);
		
	NewRow.MultilingualName = "vi = 'Tính chi phí tính chiết khấu theo phần trăm';
								|ru = 'Расчет процентных расходов дисконтирования';
								|en = 'Calculate discounting interest expenses';
								|it = 'Calcolo spese di interessi di sconto';
								|pl = 'Obliczenie kosztów odsetkowych dyskontowania';
								|tr = 'İskonto faiz giderlerinin hesaplanması'"; // @NStr-1
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.CalculationOfDiscountInterestExpenses.Use_CalculationOfInterestExpenseDiscounting");
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.CalculationOfDiscountInterestExpenses.Registration_CalculationOfInterestExpenseDiscounting");
	NewRow.ActionExecute = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"Documents.CalculationOfDiscountInterestExpenses.Perform_CalculationOfInterestExpenseDiscounting");
		NewRow.PerformedAtPreliminaryClosingOfMonth = True;
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		"Report.DetailedCalculationOfDiscountingInterestExpenseWriteOff.ObjectForm");
		
	If Not (GetFunctionalOption("NewOnlineARAPAccounting")
		Or GenerateFutureExpenseCommitments) Then
			NewRow.DisabledByFO = True;
	EndIf;
EndProcedure

// Stage handlers.

// Parameters:
// 	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
Procedure Use_CalculationOfInterestExpenseDiscounting(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	PeriodInRecalculationRange = MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, True);
		HandlerParameters.ExplanationTable_.Clear(); 
		
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text = 
		"SELECT TOP 1
		|	DiscountInterestExpense.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|FROM
		|	AccumulationRegister.DiscountInterestExpense AS DiscountInterestExpense
		|WHERE
		|	DiscountInterestExpense.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND DiscountInterestExpense.Active
		|	AND VALUETYPE(DiscountInterestExpense.Recorder) = TYPE(Document.CalculationOfDiscountInterestExpenses)
		|	AND DiscountInterestExpense.AccountingDimensionByPartners.Organization IN(&CompanyArray)
		|	AND DiscountInterestExpense.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	DiscountInterestExpenseBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|FROM
		|	AccumulationRegister.DiscountInterestExpense.Balance(&BorderEndOfPeriod,
		|		AccountingDimensionByPartners.Organization IN (&CompanyArray)) AS DiscountInterestExpenseBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	FutureExpenseCommitments.ReserveKind AS ReserveKind
		|FROM
		|	AccumulationRegister.FutureExpenseCommitments AS FutureExpenseCommitments
		|WHERE
		|	FutureExpenseCommitments.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND FutureExpenseCommitments.Active
		|	AND VALUETYPE(FutureExpenseCommitments.Recorder) = TYPE(Document.CalculationOfDiscountInterestExpenses)
		|	AND FutureExpenseCommitments.Organization IN (&CompanyArray)
		|	AND FutureExpenseCommitments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	FutureExpenseCommitmentsBalance.ReserveKind AS ReserveKind
		|FROM
		|	AccumulationRegister.FutureExpenseCommitments.Balance(&BorderEndOfPeriod, Organization IN (&CompanyArray)) AS
		|		FutureExpenseCommitmentsBalance
		|WHERE
		|	FutureExpenseCommitmentsBalance.DiscountingAmountManBalance <> 0
		|	OR FutureExpenseCommitmentsBalance.DiscountingAmountComplBalance <> 0
		|";
	QueryResult = Query.ExecuteBatch();
	
	ThereIsWriteOffOfInterestExpensesReserves = True;
	ThereIsNoInterestForWriteOffOfReserves = True;
	ThereIsWriteOffOfInterestExpensesReserves = Not QueryResult[2].IsEmpty();
	ThereIsNoInterestForWriteOffOfReserves = QueryResult[3].IsEmpty();
	ThereIsWriteOffOfInterestExpenses = Not QueryResult[0].IsEmpty() And ThereIsWriteOffOfInterestExpensesReserves;
	NoInterestDeductible = QueryResult[1].IsEmpty() And ThereIsNoInterestForWriteOffOfReserves;
	
	ReEvaluationRequired = Documents.ExchangeDifferenceCalculation.ReEvaluationRequired(
		CalculationParameters.CompanyArray,
		CalculationParameters.EndOfPeriod,
		New Structure("DiscountInterestExpense"));
	
	If Not ReEvaluationRequired And Not PeriodInRecalculationRange Then
		
		If ThereIsWriteOffOfInterestExpenses Then
			
			// the handler is executed
			
		ElsIf NoInterestDeductible Then
			
			// No calculation is required.
			MonthEndTransactionsServer.NoNeedToSetState(
				HandlerParameters,
				NStr("vi = 'Không có chi phí tính chiết khấu theo phần trăm cần ghi giảm.';
					|ru = 'Нет процентных расходов дисконтирования к списанию.';
					|en = 'No discounting interest expenses to write off.'; fa = 'No discounting interest expenses to write off.';
					|it = 'Non vi sono spese di interessi di sconto in storno.';
					|pl = 'Brak kosztów odsetkowych dyskontowania do rozchodu.';
					|tr = 'Gider yazılacak herhangi bir iskonto faiz gideri yoktur.'", Common.DefaultLanguageCode()));
			
		EndIf;
		
	Else
		
		If PeriodInRecalculationRange Then
			
			CalculationStart = MonthEndTransactionsServer.CalculationStart(
				HandlerParameters.Data_Stage.Code,
				HandlerParameters.CalculationParameters.EndOfPeriod,
				Undefined,
				CalculationParameters.CompanyArray);
			OperationText = NStr("vi = 'Tạo bản ghi kết chuyển chi phí tính chiết khấu theo phần trăm bắt đầu từ kỳ %1';
								|ru = 'Формирование движений по процентным расходам дисконтирования начиная с периода %1';
								|en = 'Generate register records by discounting interest expenses starting from %1'; fa = 'Generate register records by discounting interest expenses starting from %1';
								|it = 'Creazione dei movimenti per spese di interessi di sconto a partire dal periodo %1';
								|pl = 'Utworzenie przepływów według kosztów odsetkowych dyskontowania zaczynając z okresu %1';
								|tr = 'Dönem iskonto faiz giderindeki hareketlerin oluşumu %1'", Common.DefaultLanguageCode());
			
			MonthEndTransactionsServer.SetStateFailed(
				HandlerParameters,
				StringFunctionsClientServer.SubstituteParametersToString(
					OperationText,
					CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationStart)));
			
		EndIf;
		
		If ReEvaluationRequired Then
			
			ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
				Metadata.Reports.DetailedCalculationOfCurrencyRevaluation.FullName() + ".Form", True);
			ActionMoreDetails.FormParameters.Insert("GenerateOnOpen", True);
			ActionMoreDetails.FormParameters.Insert("AllCompanies", Not ValueIsFilled(HandlerParameters.CalculationParameters.CompanyArray));
			
			If PeriodInRecalculationRange Then
				MonthEndTransactionsServer.SetStateFailed(
					HandlerParameters,
					NStr("vi = 'Tính chênh lệch tỷ giá theo chi phí tính chiết khấu phần trăm.';
						|ru = 'Расчет курсовых разниц по процентным расходам дисконтирования.';
						|en = 'Calculate exchange differences for discounting interest expenses.'; fa = 'Calculate exchange differences for discounting interest expenses.';
						|it = 'Calcolo delle differenze di tasso di cambio per spese di interessi di sconto.';
						|pl = 'Obliczenie różnic kursowych według kosztów odsetkowych dyskontowania.';
						|tr = 'İskonto faiz gideri üzerindeki kur farklarının hesaplanması.'", Common.DefaultLanguageCode()),
					MonthEndTransactionsServer.DefaultDetailsText(),
					ActionMoreDetails);
			Else
				MonthEndTransactionsServer.SetStateExecutedWithErrors(
					HandlerParameters,
					NStr("vi = 'Tính chênh lệch tỷ giá theo chi phí tính chiết khấu phần trăm.';
						|ru = 'Расчет курсовых разниц по процентным расходам дисконтирования.';
						|en = 'Calculate exchange differences for discounting interest expenses.'; fa = 'Calculate exchange differences for discounting interest expenses.';
						|it = 'Calcolo delle differenze di tasso di cambio per spese di interessi di sconto.';
						|pl = 'Obliczenie różnic kursowych według kosztów odsetkowych dyskontowania.';
						|tr = 'İskonto faiz gideri üzerindeki kur farklarının hesaplanması.'", Common.DefaultLanguageCode()),
					MonthEndTransactionsServer.DefaultDetailsText(),
					ActionMoreDetails);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
// 	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
Procedure Registration_CalculationOfInterestExpenseDiscounting(HandlerParameters) Export
	
	HandlerParameters.Data_Stage.Description = NStr("vi = 'Tính chi phí tính chiết khấu theo phần trăm';
													|ru = 'Расчет процентных расходов дисконтирования';
													|en = 'Calculate discounting interest expenses'; fa = 'محاسبه هزینه‌های بهره تنزیل';
													|it = 'Calcolo spese di interessi di sconto';
													|pl = 'Obliczenie kosztów odsetkowych dyskontowania';
													|tr = 'İskonto faiz giderlerinin hesaplanması'");
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Thực hiện';
													|ru = 'Выполнить';
													|en = 'Run'; fa = 'اجرا';
													|it = 'Eseguire';
													|pl = 'Run';
													|tr = 'Yürüt'");
	
EndProcedure

Procedure Perform_CalculationOfInterestExpenseDiscounting(HandlerParameters) Export
	
	NewOnlineARAPAccountingIsUsed = GetFunctionalOption("NewOnlineARAPAccounting");
	
	CalculationParameters = HandlerParameters.CalculationParameters;

	CalculationStart = MonthEndTransactionsServer.CalculationStart(
		HandlerParameters.Data_Stage.Code,
		CalculationParameters.EndOfPeriod,
		,
		CalculationParameters.CompanyArray);
				
	KeyOperationName = StringFunctionsClientServer.SubstituteParametersToString(
			"MonthEndTransactions.%1",
			TrimAll(HandlerParameters.Data_Stage.Code));
	MeasurementDetails 		= PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperationName);
	DataVolume	= 0;
	
	While CalculationStart <= HandlerParameters.CalculationParameters.EndOfPeriod Do
	
		JobNumber 	 	= MonthEndTransactionsServer.IncreaseTaskNumber();
		PeriodEnding 	= EndOfMonth(CalculationStart);
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(CalculationStart, CalculationParameters.CompanyArray);
		
		BeginTransaction();
		
		Try
			
			MonthEndTransactionsServer.BlockTaskRegister(
				JobNumber,
				AvailableCompanies,
				HandlerParameters.Data_Stage.Code);
			
			CalculationDataForMonth = MonthEndTransactionsServer.MonthlyTasks(
				CalculationStart,
				PeriodEnding,
				JobNumber,
				AvailableCompanies,
				HandlerParameters.Data_Stage.Code);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi thực hiện tính trong kỳ %1 đã xảy ra lỗi:
					|%2';
					|ru = 'При выполнении расчета за период %1 произошла ошибка:
					|%2';
					|en = 'An error occurred when calculating for the %1 period:
					|%2'; fa = 'An error occurred when calculating for the %1 period:
					|%2';
					|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
					|%2';
					|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
					|%2';
					|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				AvailableCompanies,
				CalculationStart);
			
		EndTry;
		
		Query = New Query;
		Query.SetParameter("PeriodEnding", PeriodEnding);
		Query.TempTablesManager = CalculationDataForMonth.TemporaryTable;
		Query.Text = 
			"SELECT
			|	CalculationOfInterestExpense.Organization AS Organization,
			|	CalculationOfInterestExpense.Ref AS Ref
			|INTO TTLocalOperations
			|FROM
			|	Document.CalculationOfDiscountInterestExpenses AS CalculationOfInterestExpense
			|WHERE
			|	NOT CalculationOfInterestExpense.DeletionMark
			|	AND CalculationOfInterestExpense.Date BETWEEN BEGINOFPERIOD(&PeriodEnding, MONTH) AND &PeriodEnding
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	BorderCache.Organization AS Organization,
			|	ISNULL(TTLocalOperations.Ref, VALUE(Document.CalculationOfDiscountInterestExpenses.EmptyRef)) AS CalculationOfInterestExpense
			|FROM
			|	BorderCache AS BorderCache
			|		LEFT JOIN TTLocalOperations AS TTLocalOperations
			|		ON BorderCache.Organization = TTLocalOperations.Organization
			|TOTALS BY
			|	Organization
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP TTLocalOperations";
		
		QueryResult = Query.Execute();
		SelectionByOrganization_ = QueryResult.Select(QueryResultIteration.ByGroups);
		
		OrganizationsToWriteOffInterestInNextPeriod = New Array;
		
		While SelectionByOrganization_.Next() Do
			
			SelectionByDocuments = SelectionByOrganization_.Select();
			While SelectionByDocuments.Next() Do
				If Not SelectionByDocuments.CalculationOfInterestExpense.IsEmpty() Then
					DocumentClosingOfMonth = SelectionByDocuments.CalculationOfInterestExpense.GetObject();
					DocumentClosingOfMonth.AdditionalProperties.Insert("MonthEndTransactions", True);
					DocumentClosingOfMonth.SetDeletionMark(True);
				Else
					DocumentClosingOfMonth = Documents.CalculationOfDiscountInterestExpenses.CreateDocument();
				EndIf;
			EndDo;
			
			If Not DocumentClosingOfMonth.Ref.IsEmpty() Then
				DocumentClosingOfMonth.SetDeletionMark(False);
			EndIf;
			DocumentClosingOfMonth.Date = PeriodEnding;
			DocumentClosingOfMonth.Organization = SelectionByOrganization_.Organization;
			
			DocumentClosingOfMonth.Write(DocumentWriteMode.Posting);
			
			DataVolume = DataVolume + 1;
			
		EndDo;
		
		Query.Text = 
			"SELECT DISTINCT
			|	DimensionKeysOfAccountingByPartners.Organization
			|FROM
			|	AccumulationRegister.DiscountInterestExpense.Balance AS DiscountInterestExpenseBalance
			|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
			|			INNER JOIN BorderCache AS BorderCache
			|			ON DimensionKeysOfAccountingByPartners.Organization = BorderCache.Organization
			|		ON DiscountInterestExpenseBalance.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
			|
			|UNION ALL
			|
			|SELECT
			|	FutureExpenseCommitmentsBalance.Organization AS Organization
			|FROM
			|	AccumulationRegister.FutureExpenseCommitments.Balance(&PeriodEnding, Organization IN
			|		(SELECT
			|			T.Organization
			|		FROM
			|			BorderCache AS T)) AS FutureExpenseCommitmentsBalance
			|WHERE
			|	FutureExpenseCommitmentsBalance.DiscountingAmountManBalance <> 0
			|	OR FutureExpenseCommitmentsBalance.DiscountingAmountComplBalance <> 0
			|";
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			OrganizationsToWriteOffInterestInNextPeriod.Add(Selection.Organization);
		EndDo;
		
		BeginTransaction();
		
		Try
			
			MonthEndTransactionsServer.BlockTaskRegister(
				JobNumber,
				AvailableCompanies,
				HandlerParameters.Data_Stage.Code);
			
			MonthEndTransactionsServer.FixCalculation(
				Undefined,
				HandlerParameters.Data_Stage.Code,
				CalculationDataForMonth.TemporaryTable);
				
			Query.SetParameter("Companies", OrganizationsToWriteOffInterestInNextPeriod);
			Query.Text = 
				"SELECT
				|	*
				|INTO TTCacheBorders
				|FROM
				|	BorderCache AS BorderCache
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP BorderCache
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT DISTINCT
				|	*
				|INTO BorderCache
				|FROM
				|	TTCacheBorders AS TTCacheBorders
				|WHERE
				|	TTCacheBorders.Organization IN(&Companies)
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|DROP TTCacheBorders";
			Query.Execute();
			
			InformationRegisters.JobsForMonthEndClosing.CreateTasksForNextPeriod(
				Query.TempTablesManager,
				PeriodEnding + 1);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi thực hiện tính trong kỳ %1 đã xảy ra lỗi:
					|%2';
					|ru = 'При выполнении расчета за период %1 произошла ошибка:
					|%2';
					|en = 'An error occurred when calculating for the %1 period:
					|%2'; fa = 'An error occurred when calculating for the %1 period:
					|%2';
					|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
					|%2';
					|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
					|%2';
					|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				AvailableCompanies,
				CalculationStart);
			
		EndTry;
		
		If NewOnlineARAPAccountingIsUsed Then
			ReEvaluationRequired = Documents.ExchangeDifferenceCalculation.ReEvaluationRequired(
				AvailableCompanies,
				CalculationParameters.EndOfPeriod,
				New Structure("DiscountInterestExpense"));
			
			If ReEvaluationRequired Then
				Documents.ExchangeDifferenceCalculation.ReassessDiscountAmounts(
					AvailableCompanies,
					CalculationStart);
			EndIf;
		EndIf;
		
		CalculationStart = PeriodEnding + 1;
		
	EndDo;
	
	If NewOnlineARAPAccountingIsUsed Then
		// control revaluation, if there was no
		ReEvaluationRequired = Documents.ExchangeDifferenceCalculation.ReEvaluationRequired(
			AvailableCompanies,
			CalculationParameters.EndOfPeriod,
			New Structure("DiscountInterestExpense"));
			
		If ReEvaluationRequired Then
			Documents.ExchangeDifferenceCalculation.ReassessDiscountAmounts(
				AvailableCompanies,
				CalculationParameters.EndOfPeriod);
		EndIf;
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	Companies.ParentCompany AS ParentCompany
	|FROM
	|	Document.CalculationOfDiscountInterestExpenses AS DocumentData
	|		LEFT JOIN Catalog.Companies AS Companies
	|		ON DocumentData.Organization = Companies.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	EndOfPeriod = EndOfMonth(Attributes.Date);
	BeginOfPeriod = BegOfMonth(Attributes.Date);
	Query.SetParameter("Period",                   Attributes.Date);
	Query.SetParameter("EndOfPeriod",             EndOfPeriod);
	Query.SetParameter("BeginOfPeriod",            BeginOfPeriod);
	Query.SetParameter("EndOfPeriodIncluding",      New Boundary(EndOfPeriod, BoundaryType.Including));
	Query.SetParameter("BeginningOfNextPeriod",  BegOfMonth(AddMonth(EndOfPeriod, 1)));
	Query.SetParameter("Organization",              Attributes.Organization);
	Query.SetParameter("ParentCompany",      Attributes.ParentCompany);

	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableDiscountInterestExpense(QueryTexts, Registers = Undefined)

	RegisterName = "DiscountInterestExpense";
	
	QueryText = "
	|SELECT
	|	Table.RecordType AS RecordType,
	|	Table.Period AS Period,
	|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Table.ARAPObject AS ARAPObject,
	|	Table.Currency AS Currency,
	|	Table.ARAPDocument AS ARAPDocument,
	|
	|	Table.DiscountingAmount AS DiscountingAmount,
	|	Table.DiscountingAmountCompl AS DiscountingAmountCompl,
	|	Table.DiscountingAmountMan AS DiscountingAmountMan,
	|
	|	Table.DiscountRate AS DiscountRate,
	|	Table.ActualDebtWithoutVAT AS ActualDebtWithoutVAT,
	|	Table.DiscountedDebtWithoutVAT AS DiscountedDebtWithoutVAT,
	|	Table.CalculatedInterestBalance AS CalculatedInterestBalance,
	|
	|	Table.FinRecordID AS FinRecordID,
	|	Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	&TTName AS Table
	|";
	
	QueryText = StrReplace(QueryText, "&TTName", "Table" + RegisterName);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(QueryTexts)

	RegisterName = "TTInitialOtherExpenses";
	
	QueryText = AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses();
	QueryText = QueryText + "UNION ALL" + "
	|SELECT
	|	Table.Period AS Period,
	|	Table.RecordType AS RecordType,
	|	Table.Organization AS Organization,
	|	Table.Department AS Department,
	|	Table.ExpenseItem AS ExpenseItem,
	|	Table.DimensionOfExpenses AS DimensionOfExpenses,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
	|
	|	Table.SumMan AS AmountIncludingVAT,
	|	Table.SumMan AS AmountExcludingVAT,
	|	Table.SumMan AS AmountExcludingVATMan,
	|	Table.SumCompl AS AmountIncludingVATCompl,
	|	Table.SumCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	Table.CostTD AS CostTD,
	|
	|	Table.BusinessOperation AS BusinessOperation,
	|	Table.ItemsLocationAttributes,
	|	Table.FinRecordID AS FinRecordID,
	|	Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TableOtherExpenses AS Table
	|
	|UNION ALL
	|
	|SELECT
	|	&EndOfPeriod AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	Table.Organization AS Organization,
	|	Table.Department AS Department,
	|	Table.ExpenseItem AS ExpenseItem,
	|	Table.DimensionOfExpenses AS DimensionOfExpenses,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
	|
	|	Table.DiscountingAmountMan AS AmountIncludingVAT,
	|	Table.DiscountingAmountMan AS AmountExcludingVAT,
	|	Table.DiscountingAmountMan AS AmountExcludingVATMan,
	|	Table.DiscountingAmountCompl AS AmountIncludingVATCompl,
	|	Table.DiscountingAmountCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	Table.DiscountingAmountCompl AS CostTD,
	|
	|	Table.BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	Table.FinRecordID AS FinRecordID,
	|	Table.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTProvisionsAndContingentLiabilities AS Table
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(QueryTexts, Registers = Undefined)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(QueryTexts, Registers = Undefined)

	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	//If there are NO documents.There is a table of the query ("In the movement of the counterparty income expenses", the text of the query) Then
	//	The text of the request for the movement of the counterparty Income expenses (the text of the request);
	//Endings;
	
	QueryText = 
	"SELECT
	|	Table.Period AS Period,
	|	Table.BusinessOperation AS BusinessOperation,
	|	Table.Organization AS Organization,
	|	Table.Department AS Department,
	|
	|	Table.Partner AS Partner,
	|	Table.Counterparty AS Counterparty,
	|	Table.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	Table.Contract AS Contract,
	|	Table.ARAPObject AS ARAPObject,
	|	Table.LineOfBusinessItems AS LineOfBusinessItems,
	|	Table.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|	Table.DimensionOfRevenue AS DimensionOfRevenue,
	|	Table.DimensionOfExpenses AS DimensionOfExpenses,
	|	Table.Currency AS Currency,
	|	Table.AmountInCurrency AS AmountInCurrency,
	|	Table.ARAPCurrency AS ARAPCurrency,
	|	Table.AmountInARAPCurrency AS AmountInARAPCurrency,
	|	Table.FinRecordID AS FinRecordID,
	|
	|	Table.Sum AS Sum,
	|	Table.AmountExcludingVAT AS AmountExcludingVAT,
	|	Table.SumCompl AS SumCompl,
	|	Table.LocalAmountExcludingVAT AS LocalAmountExcludingVAT,
	|
	|	Table.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	&TTName AS Table
	|
	|ORDER BY
	|	Table.Period";
	
	QueryText = StrReplace(QueryText, "&TTName", "Table" + RegisterName);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
Function QueryTextFutureExpenseCommitments(QueryTexts, Registers = Undefined)

	RegisterName = "FutureExpenseCommitments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&EndOfPeriod AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableOfReserves.Organization AS Organization,
	|	TableOfReserves.ReserveKind AS ReserveKind,
	|	TableOfReserves.LineOfBusiness AS LineOfBusiness,
	|	TableOfReserves.ProvisionObject AS ProvisionObject,
	|	TableOfReserves.DiscountingAmountMan AS DiscountingAmountMan,
	|	TableOfReserves.DiscountingAmountCompl AS DiscountingAmountCompl,
	|	TableOfReserves.FinRecordID AS FinRecordID,
	|	TableOfReserves.BusinessOperation AS BusinessOperation,
	|	TableOfReserves.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTProvisionsAndContingentLiabilities AS TableOfReserves";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
#EndRegion

#Region CalculationOfDiscountInterestExpenses

Procedure CalculationOfDiscountInterestExpenses(Query, DocumentRef)
	// First you need to spread out the calculation of exchange rate differences for the revaluation operation of the discount
	Query.Text = 
	"SELECT
	|	ExchangeDifferenceCalculation.Ref AS Ref
	|FROM
	|	Document.ExchangeDifferenceCalculation AS ExchangeDifferenceCalculation
	|WHERE
	|	ExchangeDifferenceCalculation.Posted
	|	AND ExchangeDifferenceCalculation.Date = &EndOfPeriod
	|	AND ExchangeDifferenceCalculation.Organization = &Organization
	|	AND ExchangeDifferenceCalculation.BusinessOperation = VALUE(Enum.BusinessTransactions.RevaluationOfDiscountAmounts)";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RevaluationDocument = Selection.Ref.GetObject(); // DocumentObject.ExchangeDifferenceCalculation
		RevaluationDocument.Write(DocumentWriteMode.UndoPosting);
	EndDo; 
	
	Query.Text = 
	"SELECT
	|	FinancialAccountingPolicy.InterestExpenseWriteOffItem AS WriteOffItem,
	|	FinancialAccountingPolicy.WriteOffsDimensionOfInterestExpense AS DimensionWriteOffs
	|FROM
	|	InformationRegister.FinancialAccountingPolicy.SliceLast(&EndOfPeriod, Organization = &ParentCompany) AS FinancialAccountingPolicy
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscountInterestExpenseBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	DiscountInterestExpenseBalance.ARAPObject AS ARAPObject,
	|	DiscountInterestExpenseBalance.Currency AS Currency,
	|	DiscountInterestExpenseBalance.ARAPDocument AS ARAPDocument,
	|	DiscountInterestExpenseBalance.DiscountingAmountBalance AS DiscountingAmountBalance,
	|	DiscountInterestExpenseBalance.DiscountingAmountComplBalance AS DiscountingAmountComplBalance,
	|	DiscountInterestExpenseBalance.DiscountingAmountManBalance AS DiscountingAmountManBalance,
	|	DiscountInterestExpenseBalance.AccountingDimensionByPartners.Contract AS Contract
	|INTO TTInterestBalances
	|FROM
	|	AccumulationRegister.DiscountInterestExpense.Balance(&EndOfPeriodIncluding, AccountingDimensionByPartners.Organization = &Organization) AS DiscountInterestExpenseBalance
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency,
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscountInterestExpenseTurnovers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	DiscountInterestExpenseTurnovers.ARAPObject AS ARAPObject,
	|	DiscountInterestExpenseTurnovers.Currency AS Currency,
	|	DiscountInterestExpenseTurnovers.ARAPDocument AS ARAPDocument,
	|	SUM(DiscountInterestExpenseTurnovers.DiscountingAmountTurnover) AS DiscountingAmountTurnover,
	|	SUM(DiscountInterestExpenseTurnovers.DiscountingAmountComplTurnover) AS DiscountingAmountComplTurnover,
	|	SUM(DiscountInterestExpenseTurnovers.DiscountingAmountManTurnover) AS DiscountingAmountManTurnover,
	|	DiscountInterestExpenseTurnovers.AccountingDimensionByPartners.Contract AS Contract
	|INTO TTRevolutions
	|FROM
	|	AccumulationRegister.DiscountInterestExpense.Turnovers(&EndOfPeriod, &EndOfPeriod, Recorder, AccountingDimensionByPartners.Organization = &Organization) AS DiscountInterestExpenseTurnovers
	|WHERE
	|	VALUETYPE(DiscountInterestExpenseTurnovers.Recorder) = TYPE(Document.CalculationOfDiscountInterestExpenses)
	|
	|GROUP BY
	|	DiscountInterestExpenseTurnovers.AccountingDimensionByPartners,
	|	DiscountInterestExpenseTurnovers.Currency,
	|	DiscountInterestExpenseTurnovers.ARAPObject,
	|	DiscountInterestExpenseTurnovers.ARAPDocument,
	|	DiscountInterestExpenseTurnovers.AccountingDimensionByPartners.Contract
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency,
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TTInterestBalances.AccountingDimensionByPartners, TTRevolutions.AccountingDimensionByPartners) AS AccountingDimensionByPartners,
	|	ISNULL(TTInterestBalances.ARAPObject, TTRevolutions.ARAPObject) AS ARAPObject,
	|	ISNULL(TTInterestBalances.Currency, TTRevolutions.Currency) AS Currency,
	|	ISNULL(TTInterestBalances.ARAPDocument, TTRevolutions.ARAPDocument) AS ARAPDocument,
	|	ISNULL(TTInterestBalances.DiscountingAmountBalance, 0) - ISNULL(TTRevolutions.DiscountingAmountTurnover, 0) AS DiscountingAmountBalance,
	|	ISNULL(TTInterestBalances.DiscountingAmountComplBalance, 0) - ISNULL(TTRevolutions.DiscountingAmountComplTurnover, 0) AS DiscountingAmountComplBalance,
	|	ISNULL(TTInterestBalances.DiscountingAmountManBalance, 0) - ISNULL(TTRevolutions.DiscountingAmountManTurnover, 0) AS DiscountingAmountManBalance,
	|	ISNULL(TTInterestBalances.Contract, TTRevolutions.Contract) AS Contract
	|INTO TTInterestBalancesMore
	|FROM
	|	TTInterestBalances AS TTInterestBalances
	|		FULL JOIN TTRevolutions AS TTRevolutions
	|		ON TTInterestBalances.AccountingDimensionByPartners = TTRevolutions.AccountingDimensionByPartners
	|			AND TTInterestBalances.ARAPObject = TTRevolutions.ARAPObject
	|			AND TTInterestBalances.Currency = TTRevolutions.Currency
	|			AND TTInterestBalances.ARAPDocument = TTRevolutions.ARAPDocument
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency,
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FinancialAccountingPolicySliceLast.AccountingForDiscountedAccountsPayableToVendors AS AccountingForDiscountedAccountsPayableToVendors
	|INTO TTNextPeriodPolicy
	|FROM
	|	InformationRegister.FinancialAccountingPolicy.SliceLast(&BeginningOfNextPeriod, Organization = &ParentCompany) AS FinancialAccountingPolicySliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTInterestBalancesMore.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTInterestBalancesMore.ARAPObject AS ARAPObject,
	|	TTInterestBalancesMore.Currency AS Currency,
	|	TTInterestBalancesMore.ARAPDocument AS ARAPDocument,
	|	SUM(DocumentAmountsInAccountingCurrency.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(DocumentAmountsInAccountingCurrency.VATAmount) AS VATAmount
	|INTO TTVATAmount_
	|FROM
	|	TTInterestBalancesMore AS TTInterestBalancesMore
	|		INNER JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
	|		ON TTInterestBalancesMore.ARAPDocument = DocumentAmountsInAccountingCurrency.Recorder
	|
	|GROUP BY
	|	TTInterestBalancesMore.AccountingDimensionByPartners,
	|	TTInterestBalancesMore.ARAPObject,
	|	TTInterestBalancesMore.Currency,
	|	TTInterestBalancesMore.ARAPDocument
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency,
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTInterestBalancesMore.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTInterestBalancesMore.Currency AS Currency,
	|	TTInterestBalancesMore.ARAPObject AS ARAPObject,
	|	TTInterestBalancesMore.ARAPObject.Organization AS Organization,
	|	TTInterestBalancesMore.ARAPObject.Department AS Department,
	|	TTInterestBalancesMore.ARAPObject.Partner AS Partner,
	|	TTInterestBalancesMore.ARAPObject.Counterparty AS Counterparty,
	|	TTInterestBalancesMore.ARAPObject.Contract AS Contract,
	|	TTInterestBalancesMore.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	TTInterestBalancesMore.ARAPDocument AS ARAPDocument,
	|	VendorsARAPAccountingByDueDatesBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	ISNULL(VendorsARAPAccountingByDueDatesBalance.DebtBalance, 0) AS DebtBalance,
	|	TTInterestBalancesMore.DiscountingAmountBalance AS DiscountingAmountBalance,
	|	TTInterestBalancesMore.DiscountingAmountComplBalance AS DiscountingAmountComplBalance,
	|	TTInterestBalancesMore.DiscountingAmountManBalance AS DiscountingAmountManBalance,
	|	NOT ISNULL(TTNextPeriodPolicy.AccountingForDiscountedAccountsPayableToVendors, FALSE) AS DiscountingStopped,
	|	VendorsARAPAccountingByDueDatesBalance.PlannedRepaymentDate IS NULL AS DebtClosed,
	|	ISNULL(CounterpartyContracts.DiscountRate, 0) AS DiscountRate,
	|	ISNULL(TTVATAmount_.AmountExcludingVAT, 0) AS AmountExcludingVAT,
	|	ISNULL(TTVATAmount_.VATAmount, 0) + ISNULL(TTVATAmount_.AmountExcludingVAT, 0) AS AmountIncludingVAT,
	|	ISNULL(CounterpartyContracts.VATRate, VALUE(Catalog.VATRates.EXCLUDINGVAT)) AS VATRate
	|INTO TTCalculationData
	|FROM
	|	TTInterestBalancesMore AS TTInterestBalancesMore
	|		LEFT JOIN AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
	|				&EndOfPeriodIncluding,
	|				(AccountingDimensionByPartners, ARAPObject, Currency, ARAPDocument) IN
	|					(SELECT
	|						TTInterestBalancesMore.AccountingDimensionByPartners,
	|						TTInterestBalancesMore.ARAPObject,
	|						TTInterestBalancesMore.Currency,
	|						TTInterestBalancesMore.ARAPDocument
	|					FROM
	|						TTInterestBalancesMore)) AS VendorsARAPAccountingByDueDatesBalance
	|		ON TTInterestBalancesMore.AccountingDimensionByPartners = VendorsARAPAccountingByDueDatesBalance.AccountingDimensionByPartners
	|			AND TTInterestBalancesMore.Currency = VendorsARAPAccountingByDueDatesBalance.Currency
	|			AND TTInterestBalancesMore.ARAPObject = VendorsARAPAccountingByDueDatesBalance.ARAPObject
	|			AND TTInterestBalancesMore.ARAPDocument = VendorsARAPAccountingByDueDatesBalance.ARAPDocument
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON TTInterestBalancesMore.Contract = CounterpartyContracts.Ref
	|		LEFT JOIN TTVATAmount_ AS TTVATAmount_
	|		ON TTInterestBalancesMore.AccountingDimensionByPartners = TTVATAmount_.AccountingDimensionByPartners
	|			AND TTInterestBalancesMore.ARAPObject = TTVATAmount_.ARAPObject
	|			AND TTInterestBalancesMore.Currency = TTVATAmount_.Currency
	|			AND TTInterestBalancesMore.ARAPDocument = TTVATAmount_.ARAPDocument,
	|	TTNextPeriodPolicy AS TTNextPeriodPolicy
	|WHERE
	|	NOT(TTInterestBalancesMore.DiscountingAmountBalance = 0
	|				AND TTInterestBalancesMore.DiscountingAmountComplBalance = 0
	|				AND TTInterestBalancesMore.DiscountingAmountManBalance = 0)";
	
	QueryResult = Query.ExecuteBatch();
	
	SamplingAccountingPolicies = QueryResult[0].Select();
	WriteOffOfExpenses = New Structure("AssetRef,Dimension,BusinessOperation");
	WriteOffOfExpenses.BusinessOperation = Enums.BusinessTransactions.DiscountingInterestWriteOff;
	If SamplingAccountingPolicies.Next() Then
		WriteOffOfExpenses.AssetRef = SamplingAccountingPolicies.WriteOffItem;
		WriteOffOfExpenses.Dimension = SamplingAccountingPolicies.DimensionWriteOffs;
	EndIf;
	
	TMCommonUse.AddIDsToTemporaryTable("TTCalculationData", Query.TempTablesManager, "FinRecordID");
	
	Query.Text = "
	|SELECT
	|	Data.AccountingDimensionByPartners                          AS AccountingDimensionByPartners,
	|	Data.Currency                                             AS Currency,
	|	Data.ARAPObject                                     AS ARAPObject,
	|	ARAPObjects.Organization                               AS Organization,
	|	ARAPObjects.Department                             AS Department,
	|	ARAPObjects.Partner                                   AS Partner,
	|	ARAPObjects.Counterparty                                AS Counterparty,
	|	ARAPObjects.Contract                                   AS Contract,
	|	ISNULL(
	|		ISNULL(
	|			CounterpartyContracts.ContractRateOption, 
	|			IntercompanyContracts.ContractRateOption), 
	|		VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption,
	|	ARAPObjects.LineOfBusiness                   AS LineOfBusiness,
	|	Data.ARAPDocument                                  AS ARAPDocument,
	|	Data.PlannedRepaymentDate                             AS PlannedRepaymentDate,
	|	Data.DebtBalance                                        AS DebtBalance,
	|	Data.DiscountingAmountBalance                        AS DiscountingAmountBalance,
	|	Data.DiscountingAmountComplBalance                    AS DiscountingAmountComplBalance,
	|	Data.DiscountingAmountManBalance                     AS DiscountingAmountManBalance,
	|	Data.DiscountingStopped                          AS DiscountingStopped,
	|	Data.DebtClosed                               AS DebtClosed,
	|	Data.DiscountRate                              AS DiscountRate,
	|	Data.AmountExcludingVAT                                        AS AmountExcludingVAT,
	|	Data.AmountIncludingVAT                                          AS AmountIncludingVAT,
	|	Data.VATRate                                          AS VATRate,
	|	Data.FinRecordID                             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DiscountingInterestWriteOff) AS BusinessTransactionSetting
	|FROM
	|	TTCalculationData AS Data
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|			LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|			ON ARAPObjects.Contract = CounterpartyContracts.Ref
	|			LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
	|			ON ARAPObjects.Contract = IntercompanyContracts.Ref
	|		ON Data.ARAPObject = ARAPObjects.Ref
	|ORDER BY
	|	Data.PlannedRepaymentDate
	|TOTALS
	|	MAX(Currency),
	|	SUM(DebtBalance),
	|	MAX(DiscountingAmountBalance),
	|	MAX(DiscountingStopped),
	|	MAX(DebtClosed),
	|	MAX(DiscountRate),
	|	MAX(AmountExcludingVAT),
	|	MAX(AmountIncludingVAT),
	|	MAX(VATRate),
	|	MAX(Contract),
	|	MAX(ContractRateOption)
	|BY
	|	Data.ARAPDocument,
	|	Data.ARAPObject"; 
		
	SelectionByDocuments = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	Organization                    = Query.Parameters.Organization;
	CurrencyExchangeRateCache                 = ProcessingOfExchangeRatesTM.InitializeCurrencyExchangeRateCache();
	ContractExchangeRateCache         = ProcessingOfExchangeRatesTM.InitializeCacheOfContractExchangeRates();
	ManagementAccountingCurrency     = SettingsValueCached.ManagementAccountingCurrency();
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	RegisterRecords = PrepareSetsOfRegisteredRecords(DocumentRef);
	EndOfPeriod = Query.Parameters.EndOfPeriod;
	While SelectionByDocuments.Next() Do
		
		SelectionByCalculationObject_ = SelectionByDocuments.Select(QueryResultIteration.ByGroups);
		
		While SelectionByCalculationObject_.Next() Do
			
			Selection =  SelectionByCalculationObject_.Select();
			
			If SelectionByCalculationObject_.DebtBalance = 0 
				Or SelectionByCalculationObject_.DiscountingStopped 
				Or SelectionByCalculationObject_.DiscountRate = 0 
				Or SelectionByCalculationObject_.DebtClosed Then
				// All debts have been closed or discounting has been disabled (including the discount rate indicated 0), we write off all interest on the document.
				If Selection.Next() Then 
					If Not (Selection.DiscountingAmountBalance = 0 
						And Selection.DiscountingAmountManBalance = 0 
						And Selection.DiscountingAmountComplBalance = 0) Then
						Movement = RegisterRecords.DiscountInterestExpense.AddExpense();
						FillPropertyValues(Movement, Selection);
						Movement.Period = EndOfPeriod;
						Movement.DiscountingAmount = Selection.DiscountingAmountBalance;
						Movement.DiscountingAmountMan = Selection.DiscountingAmountManBalance;
						Movement.DiscountingAmountCompl = Selection.DiscountingAmountComplBalance;
						
						AddTrafficOtherExpenses(RegisterRecords, Selection, WriteOffOfExpenses);
						AddMovementCounterpartyIncomeExpenses(RegisterRecords, Selection, WriteOffOfExpenses);
					EndIf;
				EndIf;
				
			Else
				
				DatesArray  = New Array;
				ArrayOfAmounts = New Array;
				
				// We calculate the remaining interest on the closing date of the month
				DatesArray.Add(BegOfDay(EndOfPeriod));
				ArrayOfAmounts.Add(0);
				
				While Selection.Next() Do 
					If Selection.PlannedRepaymentDate <= EndOfPeriod Then
						DatesArray.Add(EndOfPeriod + 1);
					Else 
						DatesArray.Add(Selection.PlannedRepaymentDate);
					EndIf;  
					ArrayOfAmounts.Add(Selection.DebtBalance);
				EndDo;
				
				// We will allocate a part without VAT
				If TypeOf(SelectionByCalculationObject_.ARAPDocument) = Type("DocumentRef.SourceDocument") Then
					VATRate = VATAccountingERPClientServer.ValueOfVATRate(SelectionByCalculationObject_.VATRate) / 100;
					AmountIncludingVAT = SelectionByCalculationObject_.DebtBalance;
					AmountExcludingVAT = SelectionByCalculationObject_.DebtBalance / (1 + VATRate);
				Else
					AmountIncludingVAT = SelectionByCalculationObject_.AmountIncludingVAT;
					AmountExcludingVAT = SelectionByCalculationObject_.AmountExcludingVAT;
				EndIf;
				
				ShareDebtBalance              = ?(AmountIncludingVAT = 0, 0, SelectionByCalculationObject_.DebtBalance/AmountIncludingVAT);
				DebtBalanceExcludingVAT            = Round(AmountExcludingVAT * ShareDebtBalance, 2);
				ArrayOfAmounts                   = TMCommonUseClientServer.DistributeProportionally(DebtBalanceExcludingVAT, ArrayOfAmounts);
				PresentValue         = Round(FinancialInstruments.Thorns(SelectionByCalculationObject_.DiscountRate/100,
					ArrayOfAmounts, 
					DatesArray), 2);
				CalculatedInterestBalance = DebtBalanceExcludingVAT - PresentValue;
				
				If CalculatedInterestBalance = SelectionByCalculationObject_.DiscountingAmountBalance Then
					Continue;
				EndIf;
				
				AmountToBeDebited_ = SelectionByCalculationObject_.DiscountingAmountBalance - CalculatedInterestBalance;
				If AmountToBeDebited_ = 0 Then
					Continue;
				EndIf;
				ContractBasedCourse = SelectionByCalculationObject_.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract;
				
				
				If ContractBasedCourse And ManagementAccountingCurrency = SelectionByCalculationObject_.Currency Then
					ManSExchangeRate = ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(
						SelectionByCalculationObject_.Contract, 
						EndOfPeriod, 
						ContractExchangeRateCache);
				Else
					ManSExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(
						ManagementAccountingCurrency, 
						EndOfPeriod, 
						CurrencyExchangeRateCache,
						LocalAccountingCurrency);
				EndIf;
				
				If ContractBasedCourse Then
					MutualSettlementsExchangeRate = ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(
						SelectionByCalculationObject_.Contract, 
						EndOfPeriod, 
						ContractExchangeRateCache);
				Else
					MutualSettlementsExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(
						SelectionByCalculationObject_.Currency, 
						EndOfPeriod, 
						CurrencyExchangeRateCache,
						LocalAccountingCurrency);
				EndIf;
				
				// Fixed interest calculation indicators:
				ActualDebtWithoutVAT = 0;
				Counter = ArrayOfAmounts.Count();
				While Counter > 0 Do 
					Counter = Counter - 1;
					ActualDebtWithoutVAT = ActualDebtWithoutVAT + ArrayOfAmounts[Counter];
				EndDo;
				DiscountedDebtWithoutVAT = PresentValue;
				CalculatedInterestBalance        = ActualDebtWithoutVAT - DiscountedDebtWithoutVAT; 
				
				Movement = RegisterRecords.DiscountInterestExpense.AddExpense();
				Selection.Reset();
				Selection.Next();
				FillPropertyValues(Movement, Selection);
				Movement.Period                                  = EndOfPeriod;
				
				Movement.DiscountingAmount                    = AmountToBeDebited_;
				Movement.DiscountingAmountMan                 = Round(?(ManSExchangeRate = 0, 0, AmountToBeDebited_*MutualSettlementsExchangeRate/ManSExchangeRate), 2);
				Movement.DiscountingAmountCompl                = Round(AmountToBeDebited_ * MutualSettlementsExchangeRate, 2);
				
				Movement.ActualDebtWithoutVAT          = ActualDebtWithoutVAT;
				Movement.DiscountedDebtWithoutVAT     = DiscountedDebtWithoutVAT;
				Movement.CalculatedInterestBalance            = CalculatedInterestBalance;
				
				Movement.ActualDebtWithoutVATCompl      = Round(ActualDebtWithoutVAT * MutualSettlementsExchangeRate, 2);
				Movement.DiscountedDebtWithoutVATCompl = Round(DiscountedDebtWithoutVAT * MutualSettlementsExchangeRate, 2);
				Movement.CalculatedInterestBalanceCompl        = Round(CalculatedInterestBalance * MutualSettlementsExchangeRate, 2);
				
				Movement.ActualDebtWithoutVATMan       = Round(?(ManSExchangeRate = 0, 0, ActualDebtWithoutVAT*MutualSettlementsExchangeRate/ManSExchangeRate), 2);
				Movement.DiscountedDebtWithoutVATMan  = Round(?(ManSExchangeRate = 0, 0, DiscountedDebtWithoutVAT*MutualSettlementsExchangeRate/ManSExchangeRate), 2);
				Movement.CalculatedInterestBalanceMan         = Round(?(ManSExchangeRate = 0, 0, CalculatedInterestBalance*MutualSettlementsExchangeRate/ManSExchangeRate), 2);
				
				AddTrafficOtherExpenses(RegisterRecords, Selection, WriteOffOfExpenses);
				AddMovementCounterpartyIncomeExpenses(RegisterRecords, Selection, WriteOffOfExpenses);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	RegisterRecords.DiscountInterestExpense.Write();
	AddTemporaryTables(Query, RegisterRecords);

EndProcedure
Procedure CalculationOfInterestExpenseOfDiscountingReserves(Query, DocumentRef)
	
	AccountingPoliciesTaxSettings.SupplementTemporaryTableManagerWithCurrentParametersForAccountingPolicies(
		Metadata.InformationRegisters.FinancialAccountingPolicy.Name,
		Query.TempTablesManager,
		Query.Parameters.EndOfPeriod,
		"TTAccountingPolicyOfFinancialAccounting",
		Query.Parameters.Organization);

	Query.Text =
	"SELECT
	|	Reserves.Ref AS Ref
	|INTO TypesOfReservesForDiscounting
	|FROM
	|	Catalog.Reserves AS Reserves
	|WHERE
	|	Reserves.ProvisionDiscounting
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReserveBalances.Organization AS Organization,
	|	ReserveBalances.ReserveKind AS ReserveKind,
	|	ReserveBalances.LineOfBusiness AS LineOfBusiness,
	|	ReserveBalances.ProvisionObject AS ProvisionObject,
	|	ReserveBalances.ProvisionObject.BusinessUnitAccruals AS Department,
	|	-ReserveBalances.SumManBalance AS SumMan,
	|	-ReserveBalances.SumComplBalance AS SumCompl,
	|	ReserveBalances.DiscountingAmountManBalance AS DiscountingAmountMan,
	|	ReserveBalances.DiscountingAmountComplBalance AS DiscountingAmountCompl
	|INTO ReservesDataPreliminary
	|FROM
	|	AccumulationRegister.FutureExpenseCommitments.Balance(
	|			&BeginOfPeriod,
	|			(Organization, ReserveKind) IN
	|				(SELECT
	|					&Organization,
	|					T.Ref
	|				FROM
	|					TypesOfReservesForDiscounting AS T)) AS ReserveBalances
	|
	|UNION ALL
	|
	|SELECT
	|	Reserves.Organization,
	|	Reserves.ReserveKind,
	|	Reserves.LineOfBusiness,
	|	Reserves.ProvisionObject,
	|	Reserves.ProvisionObject.BusinessUnitAccruals,
	|	CASE
	|		WHEN Reserves.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN 1
	|		ELSE -1
	|	END * Reserves.SumMan,
	|	CASE
	|		WHEN Reserves.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN 1
	|		ELSE -1
	|	END * Reserves.SumCompl,
	|	CASE
	|		WHEN Reserves.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN 1
	|		ELSE -1
	|	END * Reserves.DiscountingAmountMan,
	|	CASE
	|		WHEN Reserves.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN 1
	|		ELSE -1
	|	END * Reserves.DiscountingAmountCompl
	|FROM
	|	AccumulationRegister.FutureExpenseCommitments AS Reserves
	|WHERE
	|	Reserves.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (Reserves.Organization, Reserves.ReserveKind) IN
	|			(SELECT
	|				&Organization,
	|				T.Ref
	|			FROM
	|				TypesOfReservesForDiscounting AS T)
	|	AND VALUETYPE(Reserves.Recorder) <> TYPE(Document.CalculationOfDiscountInterestExpenses)
	|	AND Reserves.Active
	|	AND NOT Reserves.CalculationOfCost
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReservesData.Organization AS Organization,
	|	ReservesData.ReserveKind AS ReserveKind,
	|	ReservesData.LineOfBusiness AS LineOfBusiness,
	|	ReservesData.ProvisionObject AS ProvisionObject,
	|	ReservesData.Department AS Department,
	|	SUM(ReservesData.SumMan) AS SumMan,
	|	SUM(ReservesData.SumCompl) AS SumCompl,
	|	SUM(ReservesData.DiscountingAmountMan) AS DiscountingAmountMan,
	|	SUM(ReservesData.DiscountingAmountCompl) AS DiscountingAmountCompl
	|INTO ReservesData
	|FROM
	|	ReservesDataPreliminary AS ReservesData
	|
	|GROUP BY
	|	ReservesData.Organization,
	|	ReservesData.ReserveKind,
	|	ReservesData.LineOfBusiness,
	|	ReservesData.ProvisionObject,
	|	ReservesData.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfReserves.Organization AS Organization,
	|	TableOfReserves.ReserveKind AS ReserveKind,
	|	TableOfReserves.LineOfBusiness AS LineOfBusiness,
	|	TableOfReserves.ProvisionObject AS ProvisionObject,
	|	TableOfReserves.Department AS Department,
	|	FinancialAccountingPolicy.ItemOfInterestExpenseWriteOffOfProvisionDiscounting AS ExpenseItem,
	|	FinancialAccountingPolicy.AnalyticsOfInterestExpenseWriteOffOfProvisionDiscounting AS DimensionOfExpenses,
	|	VALUE(Enum.BusinessTransactions.DiscountingInterestWriteOff) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.DiscountingInterestWriteOff) AS BusinessTransactionSetting,
	|	TableOfReserves.DiscountingAmountMan AS DiscountingAmountMan,
	|	TableOfReserves.SumMan AS SumMan,
	|	TableOfReserves.DiscountingAmountCompl AS DiscountingAmountCompl,
	|	TableOfReserves.SumCompl AS SumCompl,
	|	BidTable.DiscountRate AS DiscountRate,
	|	DATEDIFF(CASE
	|					WHEN BEGINOFPERIOD(&EndOfPeriod, MONTH) >= BEGINOFPERIOD(TimeTable.CompletionDate, MONTH)
	|						THEN TimeTable.CompletionDate
	|					ELSE &EndOfPeriod
	|				END, TimeTable.CompletionDate, DAY) AS DifferenceOfDays
	|FROM
	|	ReservesData AS TableOfReserves
	|		INNER JOIN InformationRegister.ProvisionDiscountingRates.SliceLast(&EndOfPeriodIncluding, Organization = &Organization) AS BidTable
	|		ON TableOfReserves.Organization = BidTable.Organization
	|			AND TableOfReserves.ReserveKind = BidTable.ReserveKind
	|		INNER JOIN InformationRegister.PeriodOfDiscountingOfProvisionsAndContingentLiabilities.SliceLast AS TimeTable
	|		ON TableOfReserves.ProvisionObject = TimeTable.ProvisionObject
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS FinancialAccountingPolicy
	|		ON TableOfReserves.Organization = FinancialAccountingPolicy.Organization
	|WHERE
	|	(TableOfReserves.DiscountingAmountMan <> 0
	|			OR TableOfReserves.DiscountingAmountCompl <> 0)
	|	AND TimeTable.CompletionDate <> DATETIME(1, 1, 1)
	|	AND FinancialAccountingPolicy.AccountForDiscountingOfProvisionsAndContingentLiabilities";
	QueryResult = Query.Execute();
	
	TableOfReserves = QueryResult.Unload();
	For Each ReserveLine In TableOfReserves Do
		
		ReserveLine.DiscountingAmountMan = ReserveLine.DiscountingAmountMan
			- Round(ReserveLine.SumMan*(1 - 1/Round(Pow(1 + ReserveLine.DiscountRate/100, ReserveLine.DifferenceOfDays/365), 10)), 2);
			
		ReserveLine.DiscountingAmountCompl = ReserveLine.DiscountingAmountCompl
			- Round(ReserveLine.SumCompl*(1 - 1/Round(Pow(1 + ReserveLine.DiscountRate/100, ReserveLine.DifferenceOfDays/365), 10)), 2);
	EndDo;
	
	Query.SetParameter("TableOfReserves", TableOfReserves);
	Query.Text =
	"SELECT
	|	Reserves.Organization AS Organization,
	|	Reserves.ReserveKind AS ReserveKind,
	|	Reserves.LineOfBusiness AS LineOfBusiness,
	|	Reserves.ProvisionObject AS ProvisionObject,
	|	Reserves.Department AS Department,
	|	Reserves.DiscountingAmountMan AS DiscountingAmountMan,
	|	Reserves.DiscountingAmountCompl AS DiscountingAmountCompl,
	|	Reserves.ExpenseItem AS ExpenseItem,
	|	Reserves.DimensionOfExpenses AS DimensionOfExpenses,
	|	Reserves.BusinessOperation AS BusinessOperation,
	|	Reserves.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO DiscountTableOfReserves
	|FROM
	|	&TableOfReserves AS Reserves
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Reserves.Organization AS Organization,
	|	Reserves.ReserveKind AS ReserveKind,
	|	Reserves.LineOfBusiness AS LineOfBusiness,
	|	Reserves.ProvisionObject AS ProvisionObject,
	|	Reserves.Department AS Department,
	|	Reserves.DiscountingAmountMan AS DiscountingAmountMan,
	|	Reserves.DiscountingAmountCompl AS DiscountingAmountCompl,
	|	Reserves.ExpenseItem AS ExpenseItem,
	|	Reserves.DimensionOfExpenses AS DimensionOfExpenses,
	|	Reserves.BusinessOperation AS BusinessOperation,
	|	Reserves.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TTProvisionsAndContingentLiabilities
	|FROM
	|	DiscountTableOfReserves AS Reserves";
	
	QueryResult = Query.Execute();
	
	TMCommonUse.AddIDsToTemporaryTable("TTProvisionsAndContingentLiabilities",
		Query.TempTablesManager, "FinRecordID");
	
EndProcedure
Procedure AddMovementCounterpartyIncomeExpenses(RegisterRecords, Selection, WriteOffOfExpenses)
	
	Expenses = RegisterRecords.DiscountInterestExpense[RegisterRecords.DiscountInterestExpense.Count()-1];
	Movement = RegisterRecords.RecordsCounterpartyIncomeExpenses.Add();
	
	Movement.Period = Expenses.Period;
	Movement.BusinessOperation = WriteOffOfExpenses.BusinessOperation;
	Movement.Organization = Selection.Organization;
	Movement.Department = Selection.Department;
	Movement.CounterpartyLineOfBusiness = Selection.LineOfBusiness;
	Movement.Partner = Selection.Partner;
	Movement.Counterparty = Selection.Counterparty;
	Movement.Contract = Selection.Contract;
	Movement.ARAPObject = Selection.ARAPObject;
	Movement.LineOfBusinessItems = Selection.LineOfBusiness;
	Movement.IncomeAndExpenseItem = WriteOffOfExpenses.AssetRef;
	Movement.DimensionOfExpenses = WriteOffOfExpenses.Dimension;
	
	Movement.Sum = Expenses.DiscountingAmountMan;
	Movement.SumCompl = Expenses.DiscountingAmountCompl;
	
	Movement.Currency = Selection.Currency;
	Movement.AmountInCurrency = Expenses.DiscountingAmount;
	
	Movement.ARAPCurrency = Selection.Currency;
	Movement.AmountInARAPCurrency = Expenses.DiscountingAmount;
	
	Movement.FinRecordID = Expenses.FinRecordID;
	Movement.SourceOfARAPFinancialAccountingGroup = Selection.ARAPObject;
	
EndProcedure

Procedure AddTrafficOtherExpenses(RegisterRecords, Selection, WriteOffOfExpenses)
	
	Expenses = RegisterRecords.DiscountInterestExpense[RegisterRecords.DiscountInterestExpense.Count()-1];
	Movement = RegisterRecords.OtherExpenses.Add();
	
	Movement.Period = Expenses.Period;
	Movement.BusinessOperation = WriteOffOfExpenses.BusinessOperation;
	Movement.Organization = Selection.Organization;
	Movement.Department = Selection.Department;
	Movement.LineOfBusiness = Selection.LineOfBusiness;
	Movement.ExpenseItem = WriteOffOfExpenses.AssetRef;
	Movement.DimensionOfExpenses = WriteOffOfExpenses.Dimension;
	
	Movement.Sum = Expenses.DiscountingAmountMan;
	Movement.SumMan = Expenses.DiscountingAmountMan;
	Movement.SumCompl = Expenses.DiscountingAmountCompl;
	Movement.CostTD = Expenses.DiscountingAmountCompl;
	
	Movement.FinRecordID = Expenses.FinRecordID;
	Movement.BusinessTransactionSetting = Expenses.BusinessTransactionSetting;
	
EndProcedure

Function PrepareSetsOfRegisteredRecords(DocumentRef)
	
	Result = New Structure;
	
	Set = AccumulationRegisters.DiscountInterestExpense.CreateRecordSet();
	Set.Filter.Recorder.Set(DocumentRef);
	Result.Insert("DiscountInterestExpense", Set);
	
	Set = AccumulationRegisters.OtherExpenses.CreateRecordSet();
	Set.Filter.Recorder.Set(DocumentRef);
	Result.Insert("OtherExpenses", Set);
	
	Set = AccumulationRegisters.RecordsCounterpartyIncomeExpenses.CreateRecordSet();
	Set.Filter.Recorder.Set(DocumentRef);
	Result.Insert("RecordsCounterpartyIncomeExpenses", Set);
	
	Return Result;
	
EndFunction

Procedure AddTemporaryTables(Query, RegisterRecords)
	
	Query.TempTablesManager = New TempTablesManager;
	
	QueryText = 
	"SELECT
	| *
	|INTO TTName
	|FROM
	|	&Data AS T";
	For Each Set In RegisterRecords Do
		Query.Text = StrReplace(QueryText, "TTName", "Table" + Set.Key);
		VT = Set.Value.Unload(); // ValueTable
		VT.Columns.Delete("Recorder");
		VT.Columns.Delete("PointInTime");
		VT.Columns.Delete("LineNumber");
		Query.SetParameter("Data", VT);
		Query.Execute();
	EndDo;
	Query.Parameters.Delete("Data");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf