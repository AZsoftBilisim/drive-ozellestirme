
#Region Public

#Region RDExpenseRecognition

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
// 	CurrentParent - String - group ID.
Procedure AddStage_RDExpenseRecognition(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.RDExpenseRecognition);
	
	NewRow.MultilingualName = "vi = 'Ghi nhận chi phí về nghiên cứu và phát triển';
								|ru = 'Признание расходов по исследованиям и разработкам';
								|en = 'R&D expense recognition';
								|it = 'Riconoscimento delle spese di ricerche e sviluppi';
								|pl = 'Uznanie rozchodów wg badań i opracowań';
								|tr = 'Ar-Ge giderlerinin muhasebeleştirilmesi'"; // @NStr-1
	NewRow.PreviousStages_.Add(Catalogs.MonthEndClosingOperations.LotsAndCostCalculation);
	NewRow.TextExecute = NStr("vi = 'Tính toán';
								|ru = 'Рассчитать';
								|en = 'Calculate'; fa = 'محاسبه';
								|it = 'Calcolare';
								|pl = 'Calculate';
								|tr = 'Hesapla'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"RDExpensesAccounting.Use_RecognitionOfResearchAndDevelopmentExpenses");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"RDExpensesAccounting.Perform_RecognitionOfResearchAndDevelopmentExpenses");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.RDExpenseRecognition.Forms.RDExpenseRecognitionWorkplace.FullName());
EndProcedure

// Checking whether the month closing stage should be used.
//
// Parameters:
//  HandlerParameters - Structure - parameters of the stage event handler.
Procedure Use_RecognitionOfResearchAndDevelopmentExpenses(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text = RequestTextStateOfRecognitionOfResearchAndDevelopmentExpenditure();
	Query.SetParameter("EconomicOperationCompletionOfStage", Enums.BusinessTransactions.CompletionOfResearchAndDevelopmentStages);
	Query.SetParameter("RefType", Common.MetadataObjectID("Document.RDExpenseRecognition"));
	
	Query.Execute();
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.TT_OrganizationsWithResearchRecognition = 0 And TemporaryTableSizes.TT_OrganizationsWithStageCompletion = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có doanh nghiệp mà cần ghi nhận chi phí nghiên cứu và triển khai';
				|ru = 'Нет организаций, для которых необходимо выполнять признание расходов по исследованиям и разработкам';
				|en = 'There are no companies that require R&D expense recognition'; fa = 'There are no companies that require R&D expense recognition';
				|it = 'Non esistono imprese per cui bisogna eseguire il riconoscimento delle spese di ricerche e sviluppi';
				|pl = 'Brak firm, dla których należy wykonać uznanie rozchodów wg badań i opracowań';
				|tr = 'Ar-Ge harcamalarını muhasebeleştirmenin gerekli olduğu herhangi bir iş yeri yoktur'", Common.DefaultLanguageCode()));
	
	Else
		MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, True);
	EndIf;
	
	TemporaryTableOfOrganizations = HandlerParameters.TempTablesManager.Tables.Find("TT_OrganizationsWithResearchRecognition"); 
	If Not TemporaryTableOfOrganizations = Undefined Then
		OrganizationsWithResearchRecognition = TemporaryTableOfOrganizations.GetData().Unload();
		MonthEndTransactionsServer.SetAdditionalHandlerProperty(HandlerParameters, "OrganizationsWithResearchRecognition", OrganizationsWithResearchRecognition);
	EndIf;
	
EndProcedure

// The step of closing the month.
//
// Parameters:
//  HandlerParameters - Structure - parameters of the stage event handler.
//
Procedure Perform_RecognitionOfResearchAndDevelopmentExpenses(HandlerParameters) Export
		
	CalculationParameters = HandlerParameters.CalculationParameters;
	AdditionalProperties = HandlerParameters.Data_Stage.AdditionalProperties;
	
 	BeginOfPeriod = MonthEndTransactionsServer.CalculationStart(HandlerParameters.Data_Stage.Code, CalculationParameters.EndOfPeriod,,
		CalculationParameters.CompanyArray);
		
	HasErrors = False;
	
	While BeginOfPeriod <= CalculationParameters.EndOfPeriod Do
		
		MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("MonthEndTransactions." 
			+ String(HandlerParameters.Data_Stage.Code));
		
		PeriodEnding = EndOfMonth(BeginOfPeriod);
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(BeginOfPeriod, CalculationParameters.CompanyArray);
		TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber();
		
		// Stage 1. Preparation of work with tasks.
		
		BeginTransaction();
		
		Try
			MonthEndTransactionsServer.BlockTaskRegister(TaskNumberBeforeCalculation, AvailableCompanies,
				HandlerParameters.Data_Stage.Code);
			CalculationDataForMonth = MonthEndTransactionsServer.MonthlyTasks(BeginOfPeriod, PeriodEnding, TaskNumberBeforeCalculation,
				AvailableCompanies, HandlerParameters.Data_Stage.Code);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr(
					"vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
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
					|tr = 'Dönem %1 için hesaplama yapılırken bir hata oluştu:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(BeginOfPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(HandlerParameters, ErrorText,
				AvailableCompanies, BeginOfPeriod);
		EndTry;
		
		// Stage 2. Calculation by organizations and period.
		
		BeginTransaction();
		
		Try
			
			TempTableManager = New TempTablesManager();
			
			DataVolume = PrepareDataOfDocumentsOnRecognitionOfExpenses(
				CalculationDataForMonth.Organization, BeginOfPeriod, TempTableManager);
				
			ClearingMovementOfExpenseRecognitionDocuments(TempTableManager);
			PerformRecognitionOfResearchExpenses(BeginOfPeriod, AdditionalProperties, TempTableManager);
			PerformExpenseRecognitionAtEndOfStage(CalculationDataForMonth.Organization, BeginOfPeriod, TempTableManager);
			GenerateTasksForCalculatingCostOfVNA(BeginOfPeriod, PeriodEnding, TempTableManager);
			
			CommitTransaction();
		Except
			
			RollbackTransaction();
			
			HasErrors = True;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr(
					"vi = 'Đã thực hiện ghi nhận chi phí nghiên cứu và triển khai trong kỳ %1 bị lỗi:
					|%2';
					|ru = 'Выполнение признания расходов по исследованиям и разработкам за период %1 завершилось с ошибкой:
					|%2';
					|en = 'R&D expense recognition in %1 period has completed with an error:
					|%2'; fa = 'R&D expense recognition in %1 period has completed with an error:
					|%2';
					|it = 'Esecuzione del riconoscimento delle spese di ricerche e sviluppi per il periodo %1 è terminato con errore:
					|%2';
					|pl = 'Wykonanie uznania rozchodów wg badań i opracowań za okres %1 zostało zakończone z błędem:
					|%2';
					|tr = '%1 dönemi için Ar-Ge harcamalarının muhasebeleştirilmesi şu hatayla başarısız oldu:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(BeginOfPeriod),
				DetailErrorDescription(ErrorInfo()));
				
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(HandlerParameters, ErrorText,
				CalculationDataForMonth.Organization, BeginOfPeriod);
		EndTry;
		
		
		If HasErrors Then
			Break;
		EndIf;
		
		// Stage 3. Completion of work with tasks.
		
		MonthEndTransactionsServer.DeleteTasksToBeCalculatedForCurPeriod(HandlerParameters, CalculationDataForMonth);
		
		BeginOfPeriod = PeriodEnding + 1;
		
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume/10);
			
	EndDo;
	
EndProcedure

// Complements the request text of the mechanism for generating monthly closing tasks.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
Procedure AddTextOfRequestForTasksByEndOfMonth(Query, QueryText, TempTablesQueryText, TemporaryTableNames) Export
	
	MatchingRequests = MatchingRequestsToControlRegisters(Query);
	
	For Each MapItem In MatchingRequests Do
		MonthEndTransactionsServer.AddTableNamesForTasks(Query, MapItem.Key);
		MonthEndTransactionsServer.AddTaskRequestText(MapItem.Key,
			MapItem.Value,
			Query.TempTablesManager.Tables,
			QueryText,
			TempTablesQueryText,
			TemporaryTableNames);
	EndDo;
	
EndProcedure

#EndRegion

#Region CapitalizationStructure

// Overriding a report query of Structuralmaterial
// 
// Returns:
// 	String - Request text for IA
//
Function RequestTextIACapitalizationStructure() Export
	
	QueryText =
	"SELECT
	|	OtherExpenses.Organization					AS Organization,
	|	OtherExpenses.Department					AS Department,
	|	OtherExpenses.LineOfBusiness		AS LineOfBusiness,
	|	OtherExpenses.ExpenseItem				AS ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses				AS DimensionOfExpenses,
	|	OtherExpenses.Recorder					AS Recorder,
	|	OtherExpenses.ExpenseItem.ExpenseKind	AS ExpenseKind,
	|	OtherExpenses.RowID			AS RowID,
	|	SUM(CASE
	|		WHEN &DataByCost = 1
	|			THEN OtherExpenses.Sum
	|		WHEN &DataByCost = 2
	|			THEN OtherExpenses.SumMan
	|		WHEN &DataByCost = 3
	|			THEN OtherExpenses.SumCompl
	|		ELSE CASE
	|			WHEN &ByEnterprise
	|				THEN OtherExpenses.Sum
	|			ELSE OtherExpenses.SumMan
	|		END
	|	END)										AS Sum,
	|	SUM(OtherExpenses.PermanentDifference)		AS AmountPermanentDifferences,
	|	SUM(OtherExpenses.CostTD)		AS AmountTemporaryDifferences,
	|	SUM(OtherExpenses.SumCompl
	|			- OtherExpenses.PermanentDifference
	|			- OtherExpenses.CostTD)	AS AmountFA
	|INTO TTMovement
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|WHERE
	|	OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND OtherExpenses.DimensionOfExpenses = &Object
	|GROUP BY
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses,
	|	OtherExpenses.Recorder,
	|	OtherExpenses.ExpenseItem.ExpenseKind,
	|	OtherExpenses.RowID
	|
	|INDEX BY
	|	Recorder,
	|	RowID
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(RDExpenseRecognitionAllocation.ZoomRatio) AS ZoomRatio,
	|	RDExpenseRecognitionAllocation.Ref				AS Ref
	|INTO TTTotalRatio
	|FROM
	|	Document.RDExpenseRecognition.Allocation AS
	|		RDExpenseRecognitionAllocation
	|WHERE
	|	RDExpenseRecognitionAllocation.Ref IN
	|		(SELECT
	|			TTMovement.Recorder
	|		FROM
	|			TTMovement)
	|GROUP BY
	|	RDExpenseRecognitionAllocation.Ref
	|
	|INDEX BY
	|	Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTMovement.Organization																	AS Organization,
	|	RDExpenseRecognitionRDTopicsStages.TopicStage	AS TopicStage,
	|	ISNULL(RDExpenseRecognitionAllocation.ZoomRatio, 0) /
	|		ISNULL(TTTotalRatio.ZoomRatio, 1)											AS ZoomRatio,
	|	TTMovement.Recorder																	AS Recorder
	|INTO TTThemesStages
	|FROM
	|	TTMovement AS TTMovement
	|		LEFT JOIN TTTotalRatio AS TTTotalRatio
	|		ON TTMovement.Recorder = TTTotalRatio.Ref
	|		LEFT JOIN Document.RDExpenseRecognition.Allocation AS
	|			RDExpenseRecognitionAllocation
	|		ON TTMovement.Recorder = RDExpenseRecognitionAllocation.Ref
	|		AND TTMovement.RowID = RDExpenseRecognitionAllocation.RowID
	|		LEFT JOIN Document.RDExpenseRecognition.RDTopicsStages AS
	|			RDExpenseRecognitionRDTopicsStages
	|		ON TTMovement.Recorder = RDExpenseRecognitionRDTopicsStages.Ref
	|WHERE
	|	TTMovement.Recorder REFS Document.RDExpenseRecognition
	|
	|INDEX BY
	|	Organization,
	|	TopicStage
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTMovement.Organization				AS Organization,
	|	TTMovement.Department			AS Department,
	|	TTMovement.LineOfBusiness	AS LineOfBusiness,
	|	TTMovement.ExpenseItem 			AS ExpenseItem,
	|	TTMovement.Recorder				AS Recorder,
	|	TTMovement.ExpenseKind				AS ExpenseKind,
	|	NULL								AS TopicStage,
	|	TTMovement.Sum					AS Sum,
	|	TTMovement.AmountPermanentDifferences					AS AmountPermanentDifferences,
	|	TTMovement.AmountTemporaryDifferences					AS AmountTemporaryDifferences,
	|	TTMovement.AmountFA					AS AmountFA
	|FROM
	|	TTMovement AS TTMovement
	|WHERE
	|	NOT TTMovement.Recorder REFS Document.RDExpenseRecognition
	|
	|UNION ALL
	|
	|SELECT
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness,
	|	OtherExpenses.ExpenseItem,	
	|	OtherExpenses.Recorder,
	|	OtherExpenses.ExpenseItem.ExpenseKind,
	|	TTThemesStages.TopicStage,
	|	CASE
	|		WHEN &DataByCost = 1
	|			THEN OtherExpenses.Sum * TTThemesStages.ZoomRatio
	|		WHEN &DataByCost = 2
	|			THEN OtherExpenses.SumMan * TTThemesStages.ZoomRatio
	|		WHEN &DataByCost = 3
	|			THEN OtherExpenses.SumCompl * TTThemesStages.ZoomRatio
	|		ELSE CASE
	|			WHEN &ByEnterprise
	|				THEN OtherExpenses.Sum * TTThemesStages.ZoomRatio
	|			ELSE OtherExpenses.SumMan * TTThemesStages.ZoomRatio
	|		END
	|	END,
	|OtherExpenses.PermanentDifference * TTThemesStages.ZoomRatio,
	|OtherExpenses.CostTD * TTThemesStages.ZoomRatio,
	|(OtherExpenses.SumCompl - OtherExpenses.PermanentDifference - OtherExpenses.CostTD) * TTThemesStages.ZoomRatio
	|
	|FROM
	|	TTThemesStages AS TTThemesStages
	|		INNER JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
	|		ON OtherExpenses.Organization = OtherExpenses.Organization
	|		AND TTThemesStages.TopicStage = OtherExpenses.DimensionOfExpenses
	|		AND TTThemesStages.Recorder <> OtherExpenses.Recorder
	|		AND OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|WHERE
	|	TTThemesStages.TopicStage.Development = TRUE";

	Return QueryText;
	
EndFunction

// Overriding a report query of Structuralmaterial
// 
// Returns:
// 	String - Request text for IA
//
Function QueryTextCapitalizationStructure() Export
	
	QueryText =
	"SELECT ALLOWED
	|	OtherExpenses.Organization					AS Organization,
	|	OtherExpenses.Department					AS Department,
	|	OtherExpenses.LineOfBusiness		AS LineOfBusiness,
	|	OtherExpenses.ExpenseItem				AS ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses				AS DimensionOfExpenses,
	|	OtherExpenses.Recorder					AS Recorder,
	|	OtherExpenses.ExpenseItem.ExpenseKind	AS ExpenseKind,
	|	UNDEFINED								AS TopicStage,
	|	CASE
	|		WHEN &DataByCost = 1
	|			THEN OtherExpenses.Sum
	|		WHEN &DataByCost = 2
	|			THEN OtherExpenses.SumMan
	|		WHEN &DataByCost = 3
	|			THEN OtherExpenses.SumCompl
	|		ELSE CASE
	|			WHEN &ByEnterprise
	|				THEN OtherExpenses.Sum
	|			ELSE OtherExpenses.SumMan
	|		END
	|	END										AS Sum,
	|	OtherExpenses.PermanentDifference				AS AmountPermanentDifferences,
	|	OtherExpenses.CostTD				AS AmountTemporaryDifferences,
	|	OtherExpenses.SumCompl
	|			- OtherExpenses.PermanentDifference
	|			- OtherExpenses.CostTD	AS AmountFA
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|WHERE
	|	OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND OtherExpenses.DimensionOfExpenses = &Object";

	Return QueryText;
	
EndFunction

#EndRegion

// Returns the settings of accounting policies for the recognition of expenditure on research
// 
// Parameters:
// 	BeginOfPeriod - Date -
// 	CompanyArray - Array of CatalogRef.Companies, Undefined - 
// Returns:
// 	ValueTable - table with columns:
// 		*Organization - CatalogRef.Companies -
// 		*ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems - 
// 		*DimensionOfExpenses - Characteristic.ExpenseItems -
// 		*AccountingPolicy - String -
Function SettingsForRecognizingCompanyResearchExpenses(BeginOfPeriod, CompanyArray = Undefined) Export
	
	QueryTexts = New Array;
	
	QueryText = "SELECT ALLOWED
	|	CatCompanies.ParentCompany AS Organization,
	|	CatCompanies.Ref AS BranchOffice
	|INTO TTParentOrganizations
	|FROM
	|	Catalog.Companies AS CatCompanies
	|WHERE
	|	CASE
	|		WHEN &FilterByCompanies
	|			THEN CatCompanies.Ref IN (&CompanyArray)
	|		ELSE TRUE
	|	END
	|
	|INDEX BY
	|	Organization";
	QueryTexts.Add(QueryText);
	QueryTexts.Add(RDExpensesAccountingLocalization.QueryTextAccountingPolicyOfBU());
	QueryTexts.Add(QueryTextAccountingPolicyOfMa());
	
	QueryText = "SELECT DISTINCT
	|	ParentOrganizations.Organization AS Organization,
	|	ISNULL(TTAccountingPolicyBuhAccounting.ExpenseItemForRD, UNDEFINED) AS ExpenseItem,
	|	ISNULL(TTAccountingPolicyBuhAccounting.ExpensesDimensionResearchExpenses, UNDEFINED) AS DimensionOfExpenses,
	|	""Accounting"" AS AccountingPolicy
	|FROM
	|	TTParentOrganizations AS ParentOrganizations
	|		LEFT JOIN TTAccountingPolicyBuhAccounting AS TTAccountingPolicyBuhAccounting
	|		ON ParentOrganizations.Organization = TTAccountingPolicyBuhAccounting.Organization
	|WHERE
	|	ISNULL(TTAccountingPolicyBuhAccounting.AccountingForRAndDAccordingToFsb26, FALSE) = TRUE
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ParentOrganizations.Organization AS Organization,
	|	ISNULL(TTAccountingPolicyOfFinAccounting.ExpenseItemForRD, UNDEFINED) AS ExpenseItem,
	|	ISNULL(TTAccountingPolicyOfFinAccounting.ExpensesDimensionResearchExpenses, UNDEFINED) AS DimensionOfExpenses,
	|	""FinAccounting"" AS AccountingPolicy
	|FROM
	|	TTParentOrganizations AS ParentOrganizations
	|		LEFT JOIN TTAccountingPolicyOfFinAccounting AS TTAccountingPolicyOfFinAccounting
	|		ON ParentOrganizations.Organization = TTAccountingPolicyOfFinAccounting.Organization
	|WHERE
	|	ISNULL(TTAccountingPolicyOfFinAccounting.RecognizeResearchExpensesInCurrentPeriod, FALSE) = TRUE";
	QueryTexts.Add(QueryText);
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("CompanyArray", CompanyArray);
	Query.SetParameter("FilterByCompanies", ValueIsFilled(CompanyArray));
	
	QueryResult = Query.Execute();
	
	Return QueryResult.Unload();
	
EndFunction

#EndRegion

#Region Private

#Region CreatingTasksForEndOfMonth

Function MatchingRequestsToControlRegisters(Query)
	
	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("ChangesTableOtherExpenses", QueryTextOtherExpenses(Query));
	Return MatchingQueryTexts;
	
EndFunction

Function QueryTextOtherExpenses(Query)
	
	NameOfCurrentAccountingPoliciesTable = "CurrentAccountingPolicies_OtherExpenses";
	TemporaryTableNames = NameOfCurrentAccountingPoliciesTable;
	
	TemporaryTableQueryTexts = New Array;
	TemporaryTableQueryTexts.Add(RequestTextForCurrentAccountingPolicies("ChangesTableOtherExpenses", NameOfCurrentAccountingPoliciesTable));

	// The application of the recognition of research expenses for the organization is checked
	
	TextsAssociation = New Array;
	
	If Query.TempTablesManager.Tables.Find("RegisteredRecordsOtherExpensesUpdate") <> Undefined Then
	
		QueryText = 
		"SELECT DISTINCT
		|	TT_TableOfChanges.BegOfMonth AS Month,
		|	VALUE(Catalog.MonthEndClosingOperations.RDExpenseRecognition) AS Operation,
		|	TT_TableOfChanges.Organization AS Organization,
		|	TT_TableOfChanges.Recorder AS Document
		|FROM
		|	RegisteredRecordsOtherExpensesUpdate AS TT_TableOfChanges
		|		INNER JOIN CurrentAccountingPolicies_OtherExpenses AS TT_ACAccountingPolicies
		|		ON TT_TableOfChanges.Organization = TT_ACAccountingPolicies.Organization
		|		INNER JOIN Catalog.RDTopicsStages AS RDTopicsStages
		|		ON TT_TableOfChanges.DimensionOfExpenses = RDTopicsStages.Ref
		|WHERE
		|	ISNULL(TT_ACAccountingPolicies.InternationalRecognitionForResearch, FALSE) = TRUE
		|	AND (TT_TableOfChanges.SumUpdate <> 0
		|		OR TT_TableOfChanges.AmountExcludingVATUpdate <> 0
		|		OR TT_TableOfChanges.SumComplUpdate <> 0
		|		OR TT_TableOfChanges.PermanentDifferenceUpdate <> 0
		|		OR TT_TableOfChanges.CostTDUpdate <> 0
		|		OR TT_TableOfChanges.SumManUpdate <> 0)";
		
		TextsAssociation.Add(QueryText);
		
	EndIf;
	
	//Checks for the presence of entered stage completions for the organization
	
	TempTablesQueryText =
	"SELECT
	|	TT_TableOfChanges.Period AS Period,
	|	TT_TableOfChanges.Organization AS Organization,
	|	COUNT(DocumentsRegistry.Ref) AS StageCompletionDocuments
	|INTO TT_CompletedStages
	|FROM
	|	ChangesTableOtherExpenses AS TT_TableOfChanges
	|		INNER JOIN Catalog.RDTopicsStages AS RDTopicsStages
	|		ON TT_TableOfChanges.DimensionOfExpenses = RDTopicsStages.Ref
	|		INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentsRegistry.RefType = &RefType
	|			AND DocumentsRegistry.BusinessOperation = &BusinessOperation
	|			AND TT_TableOfChanges.Organization = DocumentsRegistry.Organization
	|			AND DocumentsRegistry.IBDocumentDate BETWEEN BEGINOFPERIOD(TT_TableOfChanges.Period,
	|				MONTH) AND ENDOFPERIOD(TT_TableOfChanges.Period, MONTH)
	|			AND DocumentsRegistry.Posted = TRUE
	|WHERE
	|	TT_TableOfChanges.Sum <> 0
	|		OR TT_TableOfChanges.AmountExcludingVAT <> 0
	|		OR TT_TableOfChanges.SumCompl <> 0
	|		OR TT_TableOfChanges.PermanentDifference <> 0
	|		OR TT_TableOfChanges.CostTD <> 0
	|		OR TT_TableOfChanges.SumMan <> 0
	|
	|GROUP BY
	|	TT_TableOfChanges.Period,
	|	TT_TableOfChanges.Organization
	|HAVING
	|	COUNT(DocumentsRegistry.Ref) > 0
	|
	|INDEX BY
	|	Period,
	|	Organization";
	
	Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.CompletionOfResearchAndDevelopmentStages);
	Query.SetParameter("RefType", Common.MetadataObjectID("Document.RDExpenseRecognition"));
	
	TemporaryTableNames = TemporaryTableNames + ", TT_CompletedStages";
	TemporaryTableQueryTexts.Add(TempTablesQueryText);
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(TT_TableOfChanges.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.RDExpenseRecognition) AS Operation,
	|	TT_TableOfChanges.Organization AS Organization,
	|	TT_TableOfChanges.Recorder AS Document
	|FROM
	|	ChangesTableOtherExpenses AS TT_TableOfChanges
	|WHERE
	|	(TT_TableOfChanges.Organization, TT_TableOfChanges.Period) IN
	|		(SELECT
	|			TT_CompletedStages.Organization,
	|			TT_CompletedStages.Period
	|		FROM
	|			TT_CompletedStages)";
	TextsAssociation.Add(QueryText);
	
	QueryText= StrConcat(TextsAssociation, TMCommonUse.QuerySeparatorInJoin(True));
	TempTablesQueryText = StrConcat(TemporaryTableQueryTexts, Common.QueryBatchSeparator()) 
		+ Common.QueryBatchSeparator();
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(
		QueryText, 
		TempTablesQueryText,
		TemporaryTableNames);
		
	Return StructureOfQueryTexts_;
	
EndFunction

// Text of the request for the current accounting policy for recognizing research expenses.
//
// Parameters:
// 	NameOfChangeTable - String - name of the temporary calculation change table.
// 	NameOfPreparedTable - String - name of the temporary table to place the current accounting policies in.
//
// Returns:
//  String - Query text
//
Function RequestTextForCurrentAccountingPolicies(NameOfChangeTable, NameOfPreparedTable)
	
	QueryTexts = New Array;
	
	QueryText =
	"SELECT DISTINCT
	|	TT_TableOfChanges.Period AS Period,
	|	TT_TableOfChanges.Organization AS Organization,
	|	ISNULL(Companies.ParentCompany, TT_TableOfChanges.Organization) AS OrganizationOfAccountingPolicy
	|INTO Tt_OrganizationOfAccountingPolicy
	|FROM
	|	#ChangesTable AS TT_TableOfChanges
	|		LEFT JOIN Catalog.Companies AS Companies
	|		ON TT_TableOfChanges.Organization = Companies.Ref
	|		AND Companies.BranchOffice";
	
	QueryTexts.Add(QueryText);
	QueryTexts.Add(RDExpensesAccountingLocalization.RequestTextAccountingPoliciesAC());
	QueryTexts.Add(RequestTextAccountingPoliciesOfMa());
	
	QueryText =
	"SELECT
	|	TT_TableOfChanges.Period AS Period,
	|	TT_TableOfChanges.Organization AS Organization,
	|	TT_ACAccountingPolicies.InternationalRecognitionForResearch AS InternationalRecognitionForResearch
	|INTO #NameOfPreparedTable
	|FROM
	|	Tt_OrganizationOfAccountingPolicy AS TT_TableOfChanges
	|		LEFT JOIN TT_ACAccountingPolicies AS TT_ACAccountingPolicies
	|		ON TT_TableOfChanges.OrganizationOfAccountingPolicy = TT_ACAccountingPolicies.Organization
	|		AND TT_TableOfChanges.Period = TT_ACAccountingPolicies.Period
	|
	|UNION ALL
	|
	|SELECT
	|	TT_TableOfChanges.Period AS Period,
	|	TT_TableOfChanges.Organization AS Organization,
	|	TT_AccountingPoliciesOfMa.InternationalRecognitionForResearch
	|FROM
	|	Tt_OrganizationOfAccountingPolicy AS TT_TableOfChanges
	|		LEFT JOIN TT_AccountingPoliciesOfMa AS TT_AccountingPoliciesOfMa
	|		ON TT_TableOfChanges.OrganizationOfAccountingPolicy = TT_AccountingPoliciesOfMa.Organization
	|		AND TT_TableOfChanges.Period = TT_AccountingPoliciesOfMa.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_ACAccountingPolicies
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_AccountingPoliciesOfMa
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Tt_OrganizationOfAccountingPolicy";
		
	QueryTexts.Add(QueryText);
		
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
			
	QueryText = StrReplace(QueryText, "#ChangesTable", NameOfChangeTable);
	QueryText = StrReplace(QueryText, "#NameOfPreparedTable", NameOfPreparedTable);

	Return QueryText;
	
EndFunction

// Generates tasks for calculating the cost of fixed assets and IA, if the amount of expenses that is allocated to fixed assets and IA has been changed.
//
Procedure GenerateTasksForCalculatingCostOfVNA(BeginOfPeriod, EndOfPeriod, TempTableManager)

	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(BeginOfPeriod) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	Query.Text = 
	"SELECT DISTINCT
	|	Table.Period AS Period,
	|	Table.Organization AS Organization,
	|	Table.DimensionOfExpenses AS AccountingObject,
	|	Table.Recorder AS Document
	|INTO OtherExpenses_TasksForCalculatingCostOfHPAUpdate
	|FROM
	|	(SELECT
	|		ChangesTable.Period AS Period,
	|		ChangesTable.Recorder AS Recorder,
	|		ChangesTable.Organization AS Organization,
	|		ChangesTable.Department AS Department,
	|		ChangesTable.ExpenseItem AS ExpenseItem,
	|		ChangesTable.DimensionOfExpenses AS DimensionOfExpenses,
	|		ChangesTable.LineOfBusiness AS LineOfBusiness,
	|		CASE
	|			WHEN ChangesTable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN ChangesTable.Sum
	|			ELSE 0
	|		END AS Sum,
	|		CASE
	|			WHEN ChangesTable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN ChangesTable.AmountExcludingVAT
	|			ELSE 0
	|		END AS AmountExcludingVAT,
	|		CASE
	|			WHEN ChangesTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN ChangesTable.SumCompl
	|			ELSE 0
	|		END AS SumCompl,
	|		CASE
	|			WHEN ChangesTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN ChangesTable.PermanentDifference
	|			ELSE 0
	|		END AS PermanentDifference,
	|		CASE
	|			WHEN ChangesTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN ChangesTable.CostTD
	|			ELSE 0
	|		END AS CostTD
	|	FROM
	|		AccumulationRegister.OtherExpenses AS ChangesTable
	|	WHERE
	|		ChangesTable.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND (ChangesTable.LotCalculation
	|				OR ChangesTable.CalculationOfCost)
	|		AND (ChangesTable.DimensionOfExpenses REFS Catalog.Assets
	|				OR ChangesTable.DimensionOfExpenses REFS Catalog.ConstructionObjects
	|				OR ChangesTable.DimensionOfExpenses REFS Catalog.IntangibleAssets)
	|		AND ChangesTable.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|		AND (ChangesTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				OR ChangesTable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|		AND ChangesTable.Recorder IN
	|				(SELECT
	|					TTCache.Ref
	|				FROM
	|					TTCacheModifiedDocuments AS TTCache)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ChangesTable.Period,
	|		ChangesTable.Recorder,
	|		ChangesTable.Organization,
	|		ChangesTable.Department,
	|		ChangesTable.ExpenseItem,
	|		ChangesTable.DimensionOfExpenses,
	|		ChangesTable.LineOfBusiness,
	|		CASE
	|			WHEN ChangesTable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN -ChangesTable.Sum
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN ChangesTable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN -ChangesTable.AmountExcludingVAT
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN ChangesTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN -ChangesTable.SumCompl
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN ChangesTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN -ChangesTable.PermanentDifference
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN ChangesTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN -ChangesTable.CostTD
	|			ELSE 0
	|		END
	|	FROM
	|		TTCashOtherExpenses AS ChangesTable
	|	WHERE
	|		(ChangesTable.DimensionOfExpenses REFS Catalog.Assets
	|				OR ChangesTable.DimensionOfExpenses REFS Catalog.ConstructionObjects
	|				OR ChangesTable.DimensionOfExpenses REFS Catalog.IntangibleAssets)
	|		AND ChangesTable.ExpenseItem.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|		AND (ChangesTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				OR ChangesTable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|		AND ChangesTable.Recorder IN
	|				(SELECT
	|					TTCache.Ref
	|				FROM
	|					TTCacheModifiedDocuments AS TTCache)
	|
	|) AS Table
	|
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	Table.Department,
	|	Table.ExpenseItem,
	|	Table.Organization,
	|	Table.DimensionOfExpenses,
	|	Table.LineOfBusiness
	|
	|HAVING
	|	(SUM(Table.Sum) <> 0
	|		OR SUM(Table.AmountExcludingVAT) <> 0
	|		OR SUM(Table.SumCompl) <> 0
	|		OR SUM(Table.PermanentDifference) <> 0
	|		OR SUM(Table.CostTD) <> 0)";
	
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Result = Query.ExecuteBatch(); 
	Selection = Result.Get(Result.UBound()).Select();
	Selection.Next();
	
	TablesData = New Structure;
	TablesData.Insert("TempTablesManager", Query.TempTablesManager);
	TablesData.Insert("OtherExpenses_TasksForCalculatingCostOfHPAUpdate", Selection.Count > 0);
	
	FACostCalculation.GenerateJobs(Undefined, TablesData);

EndProcedure

#EndRegion

Function QueryTextAccountingPolicyOfMa()
	
	Return
	"SELECT
	|	ParentOrganizations.Organization							AS Organization,
	|	SliceTable.RecognizeResearchExpensesInCurrentPeriod	AS RecognizeResearchExpensesInCurrentPeriod,
	|	SliceTable.ExpenseItemForRD		AS ExpenseItemForRD,
	|	SliceTable.ExpensesDimensionResearchExpenses	AS ExpensesDimensionResearchExpenses
	|INTO TTAccountingPolicyOfFinAccounting
	|FROM
	|	TTParentOrganizations AS ParentOrganizations
	|		LEFT JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(&BeginOfPeriod, 
	|			Organization IN
	|			(SELECT
	|				ParentOrganizations.Organization
	|			FROM
	|				TTParentOrganizations AS ParentOrganizations)) AS SliceTable
	|		ON ParentOrganizations.Organization = SliceTable.Organization
	|
	|INDEX BY
	|	Organization";
	
EndFunction

Function RequestTextAccountingPoliciesOfMa()
	
	Return
	"SELECT
	|	TT_TableOfChanges.Period AS Period,
	|	TT_TableOfChanges.Organization AS Organization,
	|	MAX(AccountingPolicyOfMa.Period) AS PeriodOfAccountingPolicyOfMa
	|INTO TT_PeriodsOfMaAccountingPolicy
	|FROM
	|	Tt_OrganizationOfAccountingPolicy AS TT_TableOfChanges
	|		LEFT JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicyOfMa
	|		ON TT_TableOfChanges.OrganizationOfAccountingPolicy = AccountingPolicyOfMa.Organization
	|		AND TT_TableOfChanges.Period >= AccountingPolicyOfMa.Period
	|GROUP BY
	|	TT_TableOfChanges.Period,
	|	TT_TableOfChanges.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT_PeriodsOfMaAccountingPolicy.Period AS Period,
	|	TT_PeriodsOfMaAccountingPolicy.Organization AS Organization,
	|	AccountingPolicyOfMa.RecognizeResearchExpensesInCurrentPeriod AS InternationalRecognitionForResearch
	|INTO TT_AccountingPoliciesOfMa
	|FROM
	|	TT_PeriodsOfMaAccountingPolicy AS TT_PeriodsOfMaAccountingPolicy
	|		LEFT JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicyOfMa
	|		ON TT_PeriodsOfMaAccountingPolicy.Organization = AccountingPolicyOfMa.Organization
	|		AND TT_PeriodsOfMaAccountingPolicy.PeriodOfAccountingPolicyOfMa = AccountingPolicyOfMa.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_PeriodsOfMaAccountingPolicy";
	
EndFunction

Function RequestTextStateOfRecognitionOfResearchAndDevelopmentExpenditure()
	
	QueryTexts = New Array;

	#Region TT_OrganizationsWithResearchRecognition

	// Organizations for which research expenses are recognized according to the accounting policy.
	QueryText = "SELECT ALLOWED
	|	CatCompanies.ParentCompany AS Organization,
	|	CatCompanies.Ref AS BranchOffice
	|INTO TTParentOrganizations
	|FROM
	|	Catalog.Companies AS CatCompanies
	|WHERE
	|	CatCompanies.Ref IN (&CompanyArray)
	|
	|INDEX BY
	|	Organization";
	
	QueryTexts.Add(QueryText);
	QueryTexts.Add(RDExpensesAccountingLocalization.QueryTextAccountingPolicyOfBU());
	QueryTexts.Add(QueryTextAccountingPolicyOfMa());
	
	QueryText = "SELECT
	|	OtherExpensesBalance.Organization AS Organization,
	|	OtherExpensesBalance.SumComplBalance AS AmountAccounting,
	|	CASE
	|		WHEN OtherExpensesBalance.SumManBalance <> 0
	|			THEN OtherExpensesBalance.SumManBalance
	|		WHEN OtherExpensesBalance.SumBalance <> 0
	|			THEN OtherExpensesBalance.SumBalance
	|		ELSE OtherExpensesBalance.AmountExcludingVATBalance
	|	END AS AmountOfUU
	|INTO TT_Balance
	|FROM
	|	AccumulationRegister.OtherExpenses.Balance(&BorderEndOfPeriod, Organization IN (&CompanyArray)
	|	AND DimensionOfExpenses REFS Catalog.RDTopicsStages) AS OtherExpensesBalance
	|
	|INDEX BY
	|	Organization
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ParentOrganizations.BranchOffice AS Organization,
	|	ISNULL(TTAccountingPolicyBuhAccounting.AccountingForRAndDAccordingToFsb26, FALSE) AS RecognizingResearch,
	|	ISNULL(TTAccountingPolicyBuhAccounting.ExpenseItemForRD, UNDEFINED) AS ExpenseItem,
	|	ISNULL(TTAccountingPolicyBuhAccounting.ExpensesDimensionResearchExpenses, UNDEFINED) AS DimensionOfExpenses,
	|	ISNULL(TTAccountingPolicyBuhAccounting.ExpenseItemForRD.ExpensesOccur, UNDEFINED) AS ExpensesOccur,
	|	""Accounting"" AS AccountingPolicy
	|INTO TT_OrganizationsWithResearchRecognition
	|FROM
	|	TTParentOrganizations AS ParentOrganizations
	|		LEFT JOIN TTAccountingPolicyBuhAccounting AS TTAccountingPolicyBuhAccounting
	|		ON ParentOrganizations.Organization = TTAccountingPolicyBuhAccounting.Organization
	|		LEFT JOIN TT_Balance AS TT_Balance
	|		ON ParentOrganizations.BranchOffice = TT_Balance.Organization
	|WHERE
	|	ISNULL(TTAccountingPolicyBuhAccounting.AccountingForRAndDAccordingToFsb26, FALSE) = TRUE
	|	AND TT_Balance.AmountAccounting <> 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ParentOrganizations.BranchOffice AS Organization,
	|	ISNULL(TTAccountingPolicyOfFinAccounting.RecognizeResearchExpensesInCurrentPeriod, FALSE),
	|	ISNULL(TTAccountingPolicyOfFinAccounting.ExpenseItemForRD, UNDEFINED) AS ExpenseItem,
	|	ISNULL(TTAccountingPolicyOfFinAccounting.ExpensesDimensionResearchExpenses, UNDEFINED) AS DimensionOfExpenses,
	|	ISNULL(TTAccountingPolicyOfFinAccounting.ExpenseItemForRD.ExpensesOccur, UNDEFINED) AS ExpensesOccur,
	|	""FinAccounting"" AS AccountingPolicy
	|FROM
	|	TTParentOrganizations AS ParentOrganizations
	|		LEFT JOIN TTAccountingPolicyOfFinAccounting AS TTAccountingPolicyOfFinAccounting
	|		ON ParentOrganizations.Organization = TTAccountingPolicyOfFinAccounting.Organization
	|		LEFT JOIN TT_Balance AS TT_Balance
	|		ON ParentOrganizations.BranchOffice = TT_Balance.Organization
	|WHERE
	|	ISNULL(TTAccountingPolicyOfFinAccounting.RecognizeResearchExpensesInCurrentPeriod, FALSE) = TRUE
	|	AND TT_Balance.AmountOfUU <> 0";

	QueryTexts.Add(QueryText);

	#EndRegion

	#Region TT_OrganizationsWithStageCompletion

	// Organizations for which the documents for completing the research and development phase were introduced.
	
	QueryText = "SELECT DISTINCT
	|	DocumentsRegistry.Organization AS Organization
	|INTO TT_OrganizationsWithStageCompletion
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.RefType = &RefType
	|	AND DocumentsRegistry.BusinessOperation = &EconomicOperationCompletionOfStage
	|	AND DocumentsRegistry.Organization IN (&CompanyArray)
	|	AND DocumentsRegistry.IBDocumentDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DocumentsRegistry.Posted = TRUE
	|
	|INDEX BY
	|	Organization";

	QueryTexts.Add(QueryText);

	#EndRegion

	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

Function GetDistributionTable(Document, DistributionData)

	Allocation = DistributionData.CopyColumns();
	DistributionLines = DistributionData.FindRows(New Structure("Ref", Document));
	For Each DistributionString In DistributionLines Do
		String = Allocation.Add();
		FillPropertyValues(String, DistributionString); 
	EndDo;
	
	Return Allocation;
		
EndFunction

Function GetTextOfExpenseRecognitionRequest(BusinessOperation)
	
	QueryTexts = New Array();
	
	If BusinessOperation = Enums.BusinessTransactions.RecognitionOfResearchExpenses Then
		QueryText = "SELECT
		|	OrganizationsWithResearchRecognition.Organization AS Organization,
		|	OrganizationsWithResearchRecognition.AccountingPolicy AS AccountingPolicy
		|INTO TT_OrganizationsWithResearchRecognition
		|FROM
		|	&OrganizationsWithResearchRecognition AS OrganizationsWithResearchRecognition
		|
		|INDEX BY
		|	Organization,
		|	AccountingPolicy
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OtherExpensesBalance.Organization AS Organization,
		|	OtherExpensesBalance.Department AS Department,
		|	OtherExpensesBalance.LineOfBusiness AS LineOfBusiness,
		|	OtherExpensesBalance.ExpenseItem AS ExpenseItem,
		|	OtherExpensesBalance.DimensionOfExpenses AS DimensionOfExpenses,
		|	ISNULL(TT_RecognitionDocuments.Document,
		|		VALUE(Document.RDExpenseRecognition.EmptyRef)) AS RecognitionDocument,
		|	&BusinessOperation AS BusinessOperation,
		|	OtherExpensesBalance.SumBalance AS Sum,
		|	OtherExpensesBalance.AmountExcludingVATBalance AS AmountExcludingVAT,
		|	OtherExpensesBalance.SumComplBalance AS SumCompl,
		|	OtherExpensesBalance.SumManBalance AS SumMan,
		|	OtherExpensesBalance.PermanentDifferenceBalance AS PermanentDifference,
		|	OtherExpensesBalance.AITAmountBalance AS AITAmount
		|INTO TT_Balance
		|FROM
		|	AccumulationRegister.OtherExpenses.Balance(&BorderEndOfPeriod, Organization IN (&Companies)
		|	AND DimensionOfExpenses REFS Catalog.RDTopicsStages
		|	AND CAST(DimensionOfExpenses AS Catalog.RDTopicsStages).Development = FALSE) AS
		|		OtherExpensesBalance
		|		LEFT JOIN TT_RecognitionDocuments AS TT_RecognitionDocuments
		|		ON OtherExpensesBalance.Organization = TT_RecognitionDocuments.Organization
		|		AND OtherExpensesBalance.DimensionOfExpenses = TT_RecognitionDocuments.TopicStage
		|		AND TT_RecognitionDocuments.BusinessOperation = &BusinessOperation
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_Balance.Organization,
		|	TT_Balance.Department,
		|	TT_Balance.LineOfBusiness,
		|	TT_Balance.ExpenseItem,
		|	TT_Balance.DimensionOfExpenses,
		|	TT_Balance.RecognitionDocument,
		|	TT_Balance.BusinessOperation,
		|	TT_Balance.Sum,
		|	TT_Balance.AmountExcludingVAT,
		|	TT_Balance.SumCompl,
		|	TT_Balance.SumMan,
		|	TT_Balance.PermanentDifference,
		|	TT_Balance.AITAmount
		|FROM
		|	TT_Balance AS TT_Balance
		|		INNER JOIN TT_OrganizationsWithResearchRecognition AS TT_OrganizationsWithResearchRecognition
		|		ON TT_Balance.Organization = TT_OrganizationsWithResearchRecognition.Organization
		|WHERE
		|	TT_OrganizationsWithResearchRecognition.AccountingPolicy = ""Accounting""
		|	AND TT_Balance.SumCompl <> 0
		|
		|UNION
		|
		|SELECT
		|	TT_Balance.Organization,
		|	TT_Balance.Department,
		|	TT_Balance.LineOfBusiness,
		|	TT_Balance.ExpenseItem,
		|	TT_Balance.DimensionOfExpenses,
		|	TT_Balance.RecognitionDocument,
		|	TT_Balance.BusinessOperation,
		|	TT_Balance.Sum,
		|	TT_Balance.AmountExcludingVAT,
		|	TT_Balance.SumCompl,
		|	TT_Balance.SumMan,
		|	TT_Balance.PermanentDifference,
		|	TT_Balance.AITAmount
		|FROM
		|	TT_Balance AS TT_Balance
		|		INNER JOIN TT_OrganizationsWithResearchRecognition AS TT_OrganizationsWithResearchRecognition
		|		ON TT_Balance.Organization = TT_OrganizationsWithResearchRecognition.Organization
		|WHERE
		|	TT_OrganizationsWithResearchRecognition.AccountingPolicy = ""FinAccounting""
		|	AND TT_Balance.Sum + TT_Balance.SumMan + TT_Balance.AmountExcludingVAT <> 0";
		QueryTexts.Add(QueryText);
	Else
		QueryText = "SELECT
		|	OtherExpensesBalance.Organization AS Organization,
		|	OtherExpensesBalance.Department AS Department,
		|	OtherExpensesBalance.LineOfBusiness AS LineOfBusiness,
		|	OtherExpensesBalance.ExpenseItem AS ExpenseItem,
		|	OtherExpensesBalance.DimensionOfExpenses AS DimensionOfExpenses,
		|	ISNULL(TT_RecognitionDocuments.Document,
		|		VALUE(Document.RDExpenseRecognition.EmptyRef)) AS RecognitionDocument,
		|	&BusinessOperation AS BusinessOperation,
		|	OtherExpensesBalance.SumBalance AS Sum,
		|	OtherExpensesBalance.AmountExcludingVATBalance AS AmountExcludingVAT,
		|	OtherExpensesBalance.SumComplBalance AS SumCompl,
		|	OtherExpensesBalance.PermanentDifferenceBalance AS PermanentDifference,
		|	OtherExpensesBalance.CostTDBalance AS CostTD,
		|	OtherExpensesBalance.SumManBalance AS SumMan,
		|	OtherExpensesBalance.AITAmountBalance AS AITAmount
		|FROM
		|	AccumulationRegister.OtherExpenses.Balance(&BorderEndOfPeriod, Organization IN (&Companies)
		|	AND DimensionOfExpenses REFS Catalog.RDTopicsStages) AS OtherExpensesBalance
		|		LEFT JOIN TT_RecognitionDocuments AS TT_RecognitionDocuments
		|		ON OtherExpensesBalance.Organization = TT_RecognitionDocuments.Organization
		|		AND OtherExpensesBalance.DimensionOfExpenses = TT_RecognitionDocuments.TopicStage
		|		AND (TT_RecognitionDocuments.BusinessOperation = &BusinessOperation)";
		QueryTexts.Add(QueryText);
	EndIf;
	
	QueryText = "SELECT
	|	tt_RecognitionDocumentsCollapsed.Document AS Ref,
	|	RDExpenseRecognitionAllocation.Department AS Department,
	|	RDExpenseRecognitionAllocation.LineOfBusiness AS LineOfBusiness,
	|	RDExpenseRecognitionAllocation.ZoomRatio AS ZoomRatio,
	|	RDExpenseRecognitionAllocation.ExpenseRecognitionTypeAC AS ExpenseRecognitionTypeAC,
	|	RDExpenseRecognitionAllocation.ExpenseItemAccounting AS ExpenseItemAccounting,
	|	RDExpenseRecognitionAllocation.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
	|	RDExpenseRecognitionAllocation.ExpenseItemAccounting.EnteredInTaxAccounting AS
	|		ItemOfExpensesAcceptanceForTaxAccountingOfAC,
	|	RDExpenseRecognitionAllocation.ExpenseRecognitionTypeTA AS ExpenseRecognitionTypeTA,
	|	RDExpenseRecognitionAllocation.ExpenseItemAccounting.ExpensesOccur AS TypeOfACExpenses,
	|	RDExpenseRecognitionAllocation.ExpenseItemTaxAccounting AS ExpenseItemTaxAccounting,
	|	RDExpenseRecognitionAllocation.ExpensesDimensionTaxAccounting AS ExpensesDimensionTaxAccounting,
	|	RDExpenseRecognitionAllocation.ExpenseItemTaxAccounting.EnteredInTaxAccounting AS
	|		ItemOfExpenditureAcceptanceForTaxAccountingTa,
	|	CASE
	|		WHEN
	|			RDExpenseRecognitionAllocation.ExpenseRecognitionTypeMA = VALUE(Enum.RDExpenseRecognitionTypes.EmptyRef)
	|			THEN RDExpenseRecognitionAllocation.ExpenseRecognitionTypeAC
	|		ELSE RDExpenseRecognitionAllocation.ExpenseRecognitionTypeMA
	|	END AS ExpenseRecognitionTypeMA,
	|	CASE
	|		WHEN
	|			RDExpenseRecognitionAllocation.ExpenseRecognitionTypeMA = VALUE(Enum.RDExpenseRecognitionTypes.EmptyRef)
	|			THEN RDExpenseRecognitionAllocation.ExpenseItemAccounting
	|		ELSE RDExpenseRecognitionAllocation.ExpenseItemManagementAccounting
	|	END AS ExpenseItemManagementAccounting,
	|	CASE
	|		WHEN
	|			RDExpenseRecognitionAllocation.ExpenseRecognitionTypeMA = VALUE(Enum.RDExpenseRecognitionTypes.EmptyRef)
	|			THEN RDExpenseRecognitionAllocation.ExpensesDimensionAccounting
	|		ELSE RDExpenseRecognitionAllocation.ExpensesDimensionManagementAccounting
	|	END AS ExpensesDimensionManagementAccounting,
	|	CASE
	|		WHEN
	|			RDExpenseRecognitionAllocation.ExpenseRecognitionTypeMA = VALUE(Enum.RDExpenseRecognitionTypes.EmptyRef)
	|			THEN RDExpenseRecognitionAllocation.ExpenseItemAccounting.ExpensesOccur
	|		ELSE RDExpenseRecognitionAllocation.ExpenseItemManagementAccounting.ExpensesOccur
	|	END AS TypeOfMaExpenses,
	|	RDExpenseRecognitionAllocation.RowID AS RowID
	|FROM
	|	tt_RecognitionDocumentsCollapsed AS tt_RecognitionDocumentsCollapsed
	|		LEFT JOIN Document.RDExpenseRecognition.Allocation AS
	|			RDExpenseRecognitionAllocation
	|		ON tt_RecognitionDocumentsCollapsed.Document = RDExpenseRecognitionAllocation.Ref
	|WHERE
	|	tt_RecognitionDocumentsCollapsed.BusinessOperation = &BusinessOperation
	|	AND tt_RecognitionDocumentsCollapsed.Stage = &Stage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	tt_RecognitionDocumentsCollapsed.Document AS RecognitionDocument,
	|	tt_RecognitionDocumentsCollapsed.Organization AS Organization,
	|	tt_RecognitionDocumentsCollapsed.Organization AS Stage
	|FROM
	|	tt_RecognitionDocumentsCollapsed AS tt_RecognitionDocumentsCollapsed
	|WHERE
	|	tt_RecognitionDocumentsCollapsed.BusinessOperation = &BusinessOperation
	|	AND tt_RecognitionDocumentsCollapsed.Stage = &Stage";
	
	QueryTexts.Add(QueryText);
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator()) ;
	
	Return QueryText;
	
EndFunction

Function GetExpenseRecognitionTable()
	
	ExpenseRecognitionTable =  New ValueTable();
	ExpenseRecognitionTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	ExpenseRecognitionTable.Columns.Add("DepartmentDr", New TypeDescription("CatalogRef.BusinessStructure"));
	ExpenseRecognitionTable.Columns.Add("LineOfBusinessDr", New TypeDescription("CatalogRef.LinesOfBusiness"));
	ExpenseRecognitionTable.Columns.Add("ExpenseItemDr", New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems"));
	ExpenseRecognitionTable.Columns.Add("DimensionOfExpensesDr", Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type);
	ExpenseRecognitionTable.Columns.Add("DepartmentCr", New TypeDescription("CatalogRef.BusinessStructure"));
	ExpenseRecognitionTable.Columns.Add("LineOfBusinessCr", New TypeDescription("CatalogRef.LinesOfBusiness"));
	ExpenseRecognitionTable.Columns.Add("ExpenseItemCr", New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems"));
	ExpenseRecognitionTable.Columns.Add("DimensionOfExpensesCr", Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type);
	ExpenseRecognitionTable.Columns.Add("RowID", New TypeDescription("String",,,New StringQualifiers(36)));
	ExpenseRecognitionTable.Columns.Add("SumCompl", New TypeDescription("Number",,,New NumberQualifiers(15,2)));
	ExpenseRecognitionTable.Columns.Add("SumMan", New TypeDescription("Number",,,New NumberQualifiers(15,2)));
	ExpenseRecognitionTable.Columns.Add("Sum", New TypeDescription("Number",,,New NumberQualifiers(15,2)));
	ExpenseRecognitionTable.Columns.Add("AmountExcludingVAT", New TypeDescription("Number",,,New NumberQualifiers(15,2)));
	ExpenseRecognitionTable.Columns.Add("AmountFA", New TypeDescription("Number",,,New NumberQualifiers(15,2)));
	ExpenseRecognitionTable.Columns.Add("PermanentDifference", New TypeDescription("Number",,,New NumberQualifiers(15,2)));
	ExpenseRecognitionTable.Columns.Add("CostTD", New TypeDescription("Number",,,New NumberQualifiers(15,2)));
	ExpenseRecognitionTable.Columns.Add("AITAmount", New TypeDescription("Number",,,New NumberQualifiers(15,2)));
	ExpenseRecognitionTable.Columns.Add("ApplyCoefficient", New TypeDescription("Boolean"));
	ExpenseRecognitionTable.Columns.Add("ArticleIsAcceptedForTaxAccounting", New TypeDescription("Boolean"));
	
	Return ExpenseRecognitionTable;
	
EndFunction

Function IncreasingCoefficientIsApplied(TypeOfExpenseRecognition)
	
	CoefficientIsApplied = True;
	
	If TypeOfExpenseRecognition = Enums.RDExpenseRecognitionTypes.MoveToAnotherTheme
		Or TypeOfExpenseRecognition = Enums.RDExpenseRecognitionTypes.IncludeInProductionCosts
		Or Not ValueIsFilled(TypeOfExpenseRecognition) Then
			CoefficientIsApplied = False;
	EndIf;
	
	Return CoefficientIsApplied;
	
EndFunction

Function PrepareDataOfDocumentsOnRecognitionOfExpenses(Companies, Period, TempTableManager)

	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	Query.Text = "SELECT
	|	RDExpenseRecognition.Organization AS Organization,
	|	RDExpenseRecognition.Ref AS Document,
	|	RDExpenseRecognition.BusinessOperation AS BusinessOperation,
	|	BEGINOFPERIOD(&EndOfPeriod, DAY) AS DateRecord
	|INTO DocumentsToBeReflected
	|FROM
	|	Document.RDExpenseRecognition AS RDExpenseRecognition
	|WHERE
	|	RDExpenseRecognition.Organization IN (&Companies)
	|	AND RDExpenseRecognition.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND RDExpenseRecognition.Posted
	|
	|INDEX BY
	|	Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RDExpenseRecognitionAllocation.Ref AS Document,
	|	RDExpenseRecognitionAllocation.ExpensesDimensionAccounting AS Dimension
	|INTO TT_ReclassificationDocuments
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected
	|		INNER JOIN Document.RDExpenseRecognition.Allocation AS
	|			RDExpenseRecognitionAllocation
	|		ON DocumentsToBeReflected.Document = RDExpenseRecognitionAllocation.Ref
	|WHERE
	|	RDExpenseRecognitionAllocation.ExpensesDimensionAccounting
	|		REFS Catalog.RDTopicsStages
	|	AND
	|		RDExpenseRecognitionAllocation.ExpensesDimensionAccounting <> VALUE(Catalog.RDTopicsStages.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	RDExpenseRecognitionAllocation.Ref AS Document,
	|	RDExpenseRecognitionAllocation.ExpensesDimensionTaxAccounting AS Dimension
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected
	|		INNER JOIN Document.RDExpenseRecognition.Allocation AS
	|			RDExpenseRecognitionAllocation
	|		ON DocumentsToBeReflected.Document = RDExpenseRecognitionAllocation.Ref
	|WHERE
	|	RDExpenseRecognitionAllocation.ExpensesDimensionTaxAccounting
	|		REFS Catalog.RDTopicsStages
	|	AND
	|		RDExpenseRecognitionAllocation.ExpensesDimensionTaxAccounting <> VALUE(Catalog.RDTopicsStages.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	RDExpenseRecognitionAllocation.Ref AS Document,
	|	RDExpenseRecognitionAllocation.ExpensesDimensionManagementAccounting AS Dimension
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected
	|		INNER JOIN Document.RDExpenseRecognition.Allocation AS
	|			RDExpenseRecognitionAllocation
	|		ON DocumentsToBeReflected.Document = RDExpenseRecognitionAllocation.Ref
	|WHERE
	|	RDExpenseRecognitionAllocation.ExpensesDimensionManagementAccounting
	|		REFS Catalog.RDTopicsStages
	|	AND
	|		RDExpenseRecognitionAllocation.ExpensesDimensionManagementAccounting <> VALUE(Catalog.RDTopicsStages.EmptyRef)
	|
	|INDEX BY
	|	Document,
	|	Dimension
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsToBeReflected.Organization AS Organization,
	|	DocumentsToBeReflected.Document AS Document,
	|	RDExpenseRecognitionRDTopicsStages.TopicStage AS TopicStage,
	|	DocumentsToBeReflected.BusinessOperation AS BusinessOperation,
	|	MAX(CASE
	|		WHEN TT_ReclassificationDocuments.Document IS NULL
	|			THEN 1
	|		ELSE 2
	|	END) AS Stage
	|INTO TT_RecognitionDocuments
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected
	|		LEFT JOIN Document.RDExpenseRecognition.RDTopicsStages AS
	|			RDExpenseRecognitionRDTopicsStages
	|		ON DocumentsToBeReflected.Document = RDExpenseRecognitionRDTopicsStages.Ref
	|		LEFT JOIN TT_ReclassificationDocuments AS TT_ReclassificationDocuments
	|		ON RDExpenseRecognitionRDTopicsStages.TopicStage = TT_ReclassificationDocuments.Dimension
	|		AND
	|			RDExpenseRecognitionRDTopicsStages.Ref <> TT_ReclassificationDocuments.Document
	|GROUP BY
	|	DocumentsToBeReflected.Organization,
	|	DocumentsToBeReflected.Document,
	|	RDExpenseRecognitionRDTopicsStages.TopicStage,
	|	DocumentsToBeReflected.BusinessOperation
	|
	|INDEX BY
	|	TopicStage,
	|	Organization,
	|	BusinessOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_RecognitionDocuments.Document AS Document,
	|	TT_RecognitionDocuments.BusinessOperation AS BusinessOperation,
	|	TT_RecognitionDocuments.Organization AS Organization,
	|	TT_RecognitionDocuments.Stage
	|INTO tt_RecognitionDocumentsCollapsed
	|FROM
	|	TT_RecognitionDocuments AS TT_RecognitionDocuments
	|GROUP BY
	|	TT_RecognitionDocuments.Document,
	|	TT_RecognitionDocuments.BusinessOperation,
	|	TT_RecognitionDocuments.Organization,
	|	TT_RecognitionDocuments.Stage
	|
	|INDEX BY
	|	Document,
	|	BusinessOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherExpenses.Period,
	|	OtherExpenses.Recorder,
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses,
	|	OtherExpenses.Sum,
	|	OtherExpenses.AmountExcludingVAT,
	|	OtherExpenses.SumCompl,
	|	OtherExpenses.PermanentDifference,
	|	OtherExpenses.CostTD,
	|	OtherExpenses.SumMan
	|INTO TTCashOtherExpenses
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected
	|		INNER JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
	|		ON OtherExpenses.Recorder = DocumentsToBeReflected.Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsToBeReflected.Document AS Ref
	|INTO TTCacheModifiedDocuments
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	tt_RecognitionDocumentsCollapsed.Document,
	|	tt_RecognitionDocumentsCollapsed.BusinessOperation,
	|	tt_RecognitionDocumentsCollapsed.Organization,
	|	tt_RecognitionDocumentsCollapsed.Stage
	|FROM
	|	tt_RecognitionDocumentsCollapsed AS tt_RecognitionDocumentsCollapsed
	|";
	
	Query.SetParameter("Companies", Companies);
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Period));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Period));

	Return Query.Execute().Select().Count();
	
EndFunction

Procedure ClearingMovementOfExpenseRecognitionDocuments(TempTableManager)

	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	Query.Text = "SELECT DISTINCT
	|	DocumentsToBeReflected.Document
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected";
	
	QueryResult = Query.Execute();
	
	Try
		
		Block = New DataLock;

		LockItem = Block.Add("Document.RDExpenseRecognition");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = QueryResult;
		LockItem.UseFromDataSource("Ref", "Document");

		LockItem = Block.Add("AccumulationRegister.OtherExpenses.RecordSet");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = QueryResult;
		LockItem.UseFromDataSource("Recorder", "Document");
		
		LockItem = Block.Add("AccumulationRegister.RecordsIncomeExpensesOtherAssetsLiabilities.RecordSet");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = QueryResult;
		LockItem.UseFromDataSource("Recorder", "Document");
		
		Block.Lock();

		SelectionDetailRecords = QueryResult.Select();

		While SelectionDetailRecords.Next() Do

			RecordSet = AccumulationRegisters.OtherExpenses.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(SelectionDetailRecords.Document);
			RecordSet.Write();
			
			RecordSet = AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(SelectionDetailRecords.Document);
			RecordSet.Write();
			
		EndDo;
		
		RDExpensesAccountingLocalization.ReturnDocumentsToReflection(TempTableManager);
		
	Except
		
		ErrorText = DetailErrorDescription(ErrorInfo());

		Raise ErrorText;

	EndTry;

	RDExpensesAccountingLocalization.ClearingMovementOfExpenseRecognitionDocuments(TempTableManager);
	
EndProcedure

Procedure GenerateDocumentsRecognizingResearchExpenses(RecognitionData, DistributionData, DistributionDocuments, Period, AdditionalProperties, TempTableManager)
	
	Companies = CommonClientServer.CollapseArray(
		AdditionalProperties.OrganizationsWithResearchRecognition.UnloadColumn("Organization"));
	
	For Each Organization In Companies Do
		
		DistributionOfExpensesForOrganizationOfAC = AdditionalProperties.OrganizationsWithResearchRecognition.FindRows(
			New Structure("Organization, AccountingPolicy", Organization, "Accounting"));
		DistributionOfExpensesForOrganizationOfMa = AdditionalProperties.OrganizationsWithResearchRecognition.FindRows(
			New Structure("Organization, AccountingPolicy", Organization, "FinAccounting"));
			
		AnalyticsForRecognition = RecognitionData.Copy(
			New Structure("Organization, RecognitionDocument", Organization, Documents.RDExpenseRecognition.EmptyRef()),
			"DimensionOfExpenses");
		AnalyticsForRecognition.GroupBy("DimensionOfExpenses");
			
		If AnalyticsForRecognition.Count() > 0 Then
			
			RecognitionDocument = Documents.RDExpenseRecognition.CreateDocument();
			RecognitionDocument.Organization = Organization;
			RecognitionDocument.BusinessOperation = Enums.BusinessTransactions.RecognitionOfResearchExpenses;
			RecognitionDocument.Date = EndOfMonth(Period);
	
			For Each AnalyticsLine_ In AnalyticsForRecognition Do
				SubjectLine_ = RecognitionDocument.RDTopicsStages.Add();
				SubjectLine_.TopicStage = AnalyticsLine_.DimensionOfExpenses;
			EndDo;
	
			Allocation = RecognitionDocument.Allocation.Unload();
			Allocation.Columns.Add("TypeOfMaExpenses");
			Allocation.Columns.Add("TypeOfACExpenses");
			
			DistributionString = Allocation.Add();
			DistributionString.ExpenseRecognitionTypeTA = Enums.RDExpenseRecognitionTypes.DoNotRecognizeExpenses;
			If DistributionOfExpensesForOrganizationOfAC.Count() > 0 Then
				DistributionString.ExpensesDimensionAccounting = DistributionOfExpensesForOrganizationOfAC[0].DimensionOfExpenses;
				DistributionString.ExpenseItemAccounting = DistributionOfExpensesForOrganizationOfAC[0].ExpenseItem;
				DistributionString.ExpenseRecognitionTypeAC = Enums.RDExpenseRecognitionTypes.RecognitionAsCurrentExpenses;
				DistributionString.TypeOfACExpenses = DistributionOfExpensesForOrganizationOfAC[0].ExpensesOccur;
			Else
				DistributionString.ExpenseRecognitionTypeAC = Enums.RDExpenseRecognitionTypes.DoNotRecognizeExpenses;
			EndIf;
			If DistributionOfExpensesForOrganizationOfMa.Count() > 0 Then
				DistributionString.ExpensesDimensionManagementAccounting = DistributionOfExpensesForOrganizationOfMa[0].DimensionOfExpenses;
				DistributionString.ExpenseItemManagementAccounting = DistributionOfExpensesForOrganizationOfMa[0].ExpenseItem;
				DistributionString.ExpenseRecognitionTypeMA = Enums.RDExpenseRecognitionTypes.RecognitionAsCurrentExpenses;
				DistributionString.TypeOfMaExpenses = DistributionOfExpensesForOrganizationOfMa[0].ExpensesOccur;
			Else
				DistributionString.ExpenseRecognitionTypeMA = Enums.RDExpenseRecognitionTypes.DoNotRecognizeExpenses;
			EndIf;
			DistributionString.ZoomRatio = 1;
			
			//Let's add the sample data with data from the created document
			RecognitionDocument.Allocation.Load(Allocation);
			RecognitionDocument.Write(DocumentWriteMode.Posting);
			
			LineDocument = DistributionDocuments.Add();
			LineDocument.RecognitionDocument = RecognitionDocument.Ref;
			LineDocument.Organization = Organization;
			
			DistributionTableRow = DistributionData.Add();
			FillPropertyValues(DistributionTableRow, DistributionString);
			DistributionTableRow.Ref = RecognitionDocument.Ref;
			
			RecognitionDataLines = RecognitionData.FindRows(New Structure("Organization, RecognitionDocument",
				Organization,
				Documents.RDExpenseRecognition.EmptyRef()));
			For Each RecognitionDataString In RecognitionDataLines Do
				RecognitionDataString.RecognitionDocument = RecognitionDocument.Ref;
			EndDo;
		EndIf;
	EndDo;
	
	// We will update the temporary table with the changed documents for the subsequent formation of tasks for calculating the cost of FA and IA
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	Query.SetParameter("DistributionDocuments", DistributionDocuments);
	Query.Text = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTCacheModifiedDocuments
	|;
	|
	|SELECT
	|	DistributionDocuments.RecognitionDocument AS Ref
	|INTO CreatedDocuments
	|FROM
	|	&DistributionDocuments AS DistributionDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsToBeReflected.Document AS Ref
	|INTO TTCacheModifiedDocuments
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected
	|
	|UNION ALL
	|
	|SELECT
	|	CreatedDocuments.Ref
	|FROM
	|	CreatedDocuments AS CreatedDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP CreatedDocuments";
	
	Query.Execute();
		
EndProcedure

Procedure PerformRecognitionOfResearchExpenses(Period, AdditionalProperties, TempTableManager)
	
	If AdditionalProperties.Property("OrganizationsWithResearchRecognition") 
		And AdditionalProperties.OrganizationsWithResearchRecognition.Count()> 0 Then
		
		BusinessOperation = Enums.BusinessTransactions.RecognitionOfResearchExpenses;
		DateOfCalculation = EndOfMonth(Period);
		
		Query = New Query;
		Query.TempTablesManager = TempTableManager;
		Query.Text = GetTextOfExpenseRecognitionRequest(BusinessOperation);
		Query.SetParameter("BorderEndOfPeriod", New Boundary(DateOfCalculation, BoundaryType.Including));
		Query.SetParameter("Companies", AdditionalProperties.OrganizationsWithResearchRecognition.UnloadColumn("Organization"));
		Query.SetParameter("OrganizationsWithResearchRecognition", AdditionalProperties.OrganizationsWithResearchRecognition);
		Query.SetParameter("BusinessOperation", BusinessOperation);
		Query.SetParameter("Stage", 1);
		
		QueryResult = Query.ExecuteBatch();
		
		RecognitionData = QueryResult[2].Unload();
		RecognitionData.Indexes.Add("RecognitionDocument");
		RecognitionData.Indexes.Add("DimensionOfExpenses, RecognitionDocument");
		RecognitionData.Indexes.Add("Organization, RecognitionDocument");
		
		DistributionData = QueryResult[3].Unload();
		DistributionData.Indexes.Add("Ref");
		
		DistributionDocuments = QueryResult[4].Unload();
		
		GenerateDocumentsRecognizingResearchExpenses(
			RecognitionData,
			DistributionData,
			DistributionDocuments,
			Period,
			AdditionalProperties,
			TempTableManager);
		
		ExpenseRecognitionTable = GetExpenseRecognitionTable();
		
		For Each LineRecognitionDocument In DistributionDocuments Do
			
			RecognitionDocument = LineRecognitionDocument.RecognitionDocument;
			
			RegisteredRecordsOtherExpenses = AccumulationRegisters.OtherExpenses.CreateRecordSet();
			RegisteredRecordsOtherExpenses.Filter.Recorder.Set(RecognitionDocument);
			
			AnalyticsForRecognition = RecognitionData.Copy(New Structure("RecognitionDocument", RecognitionDocument), "DimensionOfExpenses");
			AnalyticsForRecognition.GroupBy("DimensionOfExpenses");
			
			For Each AnalyticsLine_ In AnalyticsForRecognition Do
				
				DataRows = RecognitionData.FindRows(New Structure("DimensionOfExpenses, RecognitionDocument", 
				AnalyticsLine_.DimensionOfExpenses, RecognitionDocument));
				
				If DataRows.Count() > 0 Then
					
					Allocation = GetDistributionTable(RecognitionDocument, DistributionData);
					
					If Allocation.Count() > 0 Then
						
						For Each DataString1 In DataRows Do
							
							ExpenseRecognitionTable.Clear();
							
							ArrayOfCoefficients = Allocation.UnloadColumn("ZoomRatio");
							SumOfLocalDistribution = Common.DistributeAmountInProportionToCoefficients(DataString1.SumCompl, ArrayOfCoefficients);
							AmountOfManDistribution_ = Common.DistributeAmountInProportionToCoefficients(DataString1.SumMan, ArrayOfCoefficients);
							AmountDistribution = Common.DistributeAmountInProportionToCoefficients(DataString1.Sum, ArrayOfCoefficients);
							AmountWithoutVATDistribution = Common.DistributeAmountInProportionToCoefficients(DataString1.AmountExcludingVAT, ArrayOfCoefficients);
							ConstantDifferenceDistribution = Common.DistributeAmountInProportionToCoefficients(DataString1.PermanentDifference, ArrayOfCoefficients);
							
							For Cnt = 0 To ArrayOfCoefficients.Count() - 1 Do
								
								DistributionString = Allocation[Cnt];
								Sum = ?(AmountDistribution = Undefined, 0, AmountDistribution[Cnt]);
								SumCompl = ?(SumOfLocalDistribution = Undefined, 0, SumOfLocalDistribution[Cnt]);
								SumMan = ?(AmountOfManDistribution_ = Undefined, 0, AmountOfManDistribution_[Cnt]);
								PermanentDifference = ?(ConstantDifferenceDistribution = Undefined, 0, ConstantDifferenceDistribution[Cnt]);
								
								If ValueIsFilled(DistributionString.ExpenseItemManagementAccounting) Then
									If DistributionString.TypeOfMaExpenses = Enums.ExpenseTypes.TypeOfExpensesProduction Then
										AmountExcludingVAT = ?(AmountWithoutVATDistribution = Undefined, 0, AmountWithoutVATDistribution[Cnt]);
									Else
										AmountExcludingVAT = 0;
									EndIf;
								Else
									If DistributionString.TypeOfACExpenses = Enums.ExpenseTypes.TypeOfExpensesProduction Then
										AmountExcludingVAT = ?(AmountWithoutVATDistribution = Undefined, 0, AmountWithoutVATDistribution[Cnt]);
									Else
										AmountExcludingVAT = 0;
									EndIf;
								EndIf;
								
								//Performing the recognition of expenses in the BU
								If DistributionString.ExpenseRecognitionTypeAC <> Enums.RDExpenseRecognitionTypes.DoNotRecognizeExpenses
									And SumCompl <> 0 Then
									
									String = ExpenseRecognitionTable.Add();
									String.Organization = DataString1.Organization;
									String.DepartmentCr = DataString1.Department;
									String.LineOfBusinessCr = DataString1.LineOfBusiness;
									String.ExpenseItemCr = DataString1.ExpenseItem;
									String.DimensionOfExpensesCr = DataString1.DimensionOfExpenses;
									String.DepartmentDr = ?(ValueIsFilled(DistributionString.Department), DistributionString.Department, String.DepartmentCr);
									String.LineOfBusinessDr = ?(ValueIsFilled(DistributionString.LineOfBusiness), DistributionString.LineOfBusiness, String.LineOfBusinessCr);
									String.ExpenseItemDr = DistributionString.ExpenseItemAccounting;
									String.DimensionOfExpensesDr = DistributionString.ExpensesDimensionAccounting;
									String.RowID = DistributionString.RowID;
									String.SumCompl = SumCompl;
									String.PermanentDifference = ?(PermanentDifference > 0, PermanentDifference, 0);
									String.CostTD = SumCompl- String.PermanentDifference;
									
								EndIf;
								
								//Performing the recognition of expenses in the UU
								If DistributionString.ExpenseRecognitionTypeMA <> Enums.RDExpenseRecognitionTypes.DoNotRecognizeExpenses Then
									
									String = ExpenseRecognitionTable.Add();
									String.Organization = DataString1.Organization;
									String.DepartmentCr = DataString1.Department;
									String.LineOfBusinessCr = DataString1.LineOfBusiness;
									String.ExpenseItemCr = DataString1.ExpenseItem;
									String.DimensionOfExpensesCr = DataString1.DimensionOfExpenses;
									String.DepartmentDr = ?(ValueIsFilled(DistributionString.Department), DistributionString.Department, String.DepartmentCr);
									String.LineOfBusinessDr = ?(ValueIsFilled(DistributionString.LineOfBusiness), DistributionString.LineOfBusiness, String.LineOfBusinessCr);
									String.ExpenseItemDr = DistributionString.ExpenseItemManagementAccounting;
									String.DimensionOfExpensesDr = DistributionString.ExpensesDimensionManagementAccounting;
									String.RowID = DistributionString.RowID;
									
									String.Sum = Sum;
									String.AmountExcludingVAT = AmountExcludingVAT;
									String.SumMan = SumMan;
									
								EndIf;
							EndDo;
							
							ExpenseRecognitionTable.GroupBy(
							"Organization, DepartmentCr, LineOfBusinessCr, ExpenseItemCr,
							|DimensionOfExpensesCr, DepartmentDr, LineOfBusinessDr, ExpenseItemDr,
							|DimensionOfExpensesDr, RowID",
							"SumCompl, SumMan, Sum, AmountExcludingVAT, PermanentDifference, CostTD");
							
							For Each ExpenseRecognitionLine In ExpenseRecognitionTable Do
								
								DebitingLine = RegisteredRecordsOtherExpenses.Add();
								DebitingLine.RecordType = AccumulationRecordType.Expense;
								DebitingLine.Organization = ExpenseRecognitionLine.Organization;
								DebitingLine.Department = ExpenseRecognitionLine.DepartmentCr;
								DebitingLine.LineOfBusiness = ExpenseRecognitionLine.LineOfBusinessCr;
								DebitingLine.ExpenseItem = ExpenseRecognitionLine.ExpenseItemCr;
								DebitingLine.DimensionOfExpenses = ExpenseRecognitionLine.DimensionOfExpensesCr;
								DebitingLine.Period = DateOfCalculation;
								DebitingLine.FinRecordID = New UUID();
								DebitingLine.RowID = ExpenseRecognitionLine.RowID;
								DebitingLine.Sum = ExpenseRecognitionLine.Sum;
								DebitingLine.AmountExcludingVAT = ExpenseRecognitionLine.AmountExcludingVAT;
								DebitingLine.SumMan = ExpenseRecognitionLine.SumMan;
								DebitingLine.SumCompl = ExpenseRecognitionLine.SumCompl;
								DebitingLine.PermanentDifference = ExpenseRecognitionLine.PermanentDifference;
								DebitingLine.CostTD = ExpenseRecognitionLine.CostTD;
								
								RecognitionString = RegisteredRecordsOtherExpenses.Add();
								RecognitionString.Organization = DataString1.Organization;
								RecognitionString.RecordType = AccumulationRecordType.Receipt;
								RecognitionString.Department = ExpenseRecognitionLine.DepartmentDr;
								RecognitionString.LineOfBusiness = ExpenseRecognitionLine.LineOfBusinessDr;
								RecognitionString.ExpenseItem = ExpenseRecognitionLine.ExpenseItemDr;
								RecognitionString.DimensionOfExpenses = ExpenseRecognitionLine.DimensionOfExpensesDr;
								RecognitionString.Period = DateOfCalculation;
								RecognitionString.FinRecordID = DebitingLine.FinRecordID;
								RecognitionString.RowID = ExpenseRecognitionLine.RowID;
								RecognitionString.Sum = ExpenseRecognitionLine.Sum;
								RecognitionString.AmountExcludingVAT = ExpenseRecognitionLine.AmountExcludingVAT;
								RecognitionString.SumMan = ExpenseRecognitionLine.SumMan;
								RecognitionString.SumCompl = ExpenseRecognitionLine.SumCompl;
								RecognitionString.PermanentDifference = ExpenseRecognitionLine.PermanentDifference;
								RecognitionString.CostTD = ExpenseRecognitionLine.CostTD;
								
							EndDo;
						EndDo;
					EndIf;
				EndIf;
			EndDo;
			
			RegisteredRecordsOtherExpenses.Write();
			
			RegisterRecords = New Structure("OtherExpenses", RegisteredRecordsOtherExpenses);
			
			CashFlowsIncomeExpensesOtherAssetsLiabilities(
					RegisterRecords,
					RecognitionDocument,
					DateOfCalculation,
					BusinessOperation);
			
			If GetFunctionalOption("UseBalanceSheetStatement") 
				And Not GetFunctionalOption("NewOnlineARAPAccounting") Then
				DataProcessors.FlowOfAssetsAndLiabilities.ReflectDocumentsInManagementBalanceSheet(RecognitionDocument, RegisterRecords);
			EndIf;
			FinancialAccountingPostingServer.AbilityToReflect(
			New Structure("Ref, RegisterRecords, Date, Organization", RecognitionDocument, RegisterRecords, DateOfCalculation, LineRecognitionDocument.Organization),
			New Structure,
			RegisterRecords);
			If RegisterRecords.Property("DocumentPostingInFinancialAccounting") Then
				IAReflectionRegisteredRecords = RegisterRecords.DocumentPostingInFinancialAccounting; //InformationRegisterRecordSet - 
				IAReflectionRegisteredRecords.Write();
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure PerformExpenseRecognitionAtEndOfStage(Companies, Period, TempTableManager)
	
	BusinessOperation = Enums.BusinessTransactions.CompletionOfResearchAndDevelopmentStages;
	DateOfCalculation= EndOfMonth(Period);
	
	//For the HO "Completion of research and development stages" recognition goes in two stages:
	//the first is the implementation of recognition and reclassification;
	//the second is the recognition of documents that contain topics for which expenses were reclassified earlier in the same month.
	For Stage = 1 To 2 Do
		
		Query = New Query;
		Query.TempTablesManager = TempTableManager;
		Query.Text = GetTextOfExpenseRecognitionRequest(BusinessOperation);
		Query.SetParameter("BorderEndOfPeriod", New Boundary(DateOfCalculation, BoundaryType.Including));
		Query.SetParameter("Companies", Companies);
		Query.SetParameter("BusinessOperation", BusinessOperation);
		Query.SetParameter("Stage", Stage);
	
		QueryResult = Query.ExecuteBatch();
		
		RecognitionData = QueryResult[0].Unload();
		RecognitionData.Indexes.Add("RecognitionDocument");
		RecognitionData.Indexes.Add("DimensionOfExpenses, RecognitionDocument");
		
		DistributionData = QueryResult[1].Unload();
		DistributionData.Indexes.Add("Ref");
			
		StageCompletionDocuments_ = QueryResult[2].Unload();
	
		ExpenseRecognitionTable = GetExpenseRecognitionTable();
		
		For Each LineRecognitionDocument In StageCompletionDocuments_ Do
			
			RecognitionDocument = LineRecognitionDocument.RecognitionDocument;
			
			RegisteredRecordsOtherExpenses = AccumulationRegisters.OtherExpenses.CreateRecordSet();
			RegisteredRecordsOtherExpenses.Filter.Recorder.Set(RecognitionDocument);
			
			RegisterRecordTable = RegisteredRecordsOtherExpenses.Unload();
			RegisterRecordTable.Columns.Add("ApplyCoefficient", New TypeDescription("Boolean"));
			
			AnalyticsForRecognition = RecognitionData.Copy(New Structure("RecognitionDocument", RecognitionDocument), "DimensionOfExpenses");
			AnalyticsForRecognition.GroupBy("DimensionOfExpenses");
			
			For Each AnalyticsLine_ In AnalyticsForRecognition Do
	
		 		DataRows = RecognitionData.FindRows(New Structure("DimensionOfExpenses, RecognitionDocument", 
					AnalyticsLine_.DimensionOfExpenses, RecognitionDocument));
	
				If DataRows.Count() > 0 Then
	
					Allocation = GetDistributionTable(RecognitionDocument, DistributionData);
	
					If Allocation.Count() > 0 Then
						
						For Each DataString1 In DataRows Do
							
							ExpenseRecognitionTable.Clear();
							
							ArrayOfCoefficients = Allocation.UnloadColumn("ZoomRatio");
							SumOfLocalDistribution = Common.DistributeAmountInProportionToCoefficients(DataString1.SumCompl, ArrayOfCoefficients);
							AmountOfManDistribution_ = Common.DistributeAmountInProportionToCoefficients(DataString1.SumMan, ArrayOfCoefficients);
							AmountDistribution = Common.DistributeAmountInProportionToCoefficients(DataString1.Sum, ArrayOfCoefficients);
							AmountWithoutVATDistribution = Common.DistributeAmountInProportionToCoefficients(DataString1.AmountExcludingVAT, ArrayOfCoefficients);
							ConstantDifferenceDistribution = Common.DistributeAmountInProportionToCoefficients(DataString1.PermanentDifference, ArrayOfCoefficients);
							TimeDifferenceDistribution = Common.DistributeAmountInProportionToCoefficients(DataString1.CostTD, ArrayOfCoefficients);
							AmountOfPersonalIncomeTaxDistribution =  Common.DistributeAmountInProportionToCoefficients(DataString1.AITAmount, ArrayOfCoefficients);
							
							For Cnt = 0 To ArrayOfCoefficients.Count() - 1 Do
								
								DistributionString = Allocation[Cnt];
								SumCompl = ?(SumOfLocalDistribution = Undefined, 0, SumOfLocalDistribution[Cnt]);
								SumMan = ?(AmountOfManDistribution_ = Undefined, 0, AmountOfManDistribution_[Cnt]);
								Sum = ?(AmountDistribution = Undefined, 0, AmountDistribution[Cnt]);
								PermanentDifference = ?(ConstantDifferenceDistribution = Undefined, 0, ConstantDifferenceDistribution[Cnt]);
								CostTD = ?(TimeDifferenceDistribution = Undefined, 0, TimeDifferenceDistribution[Cnt]);
								AmountFA = SumCompl - PermanentDifference - CostTD;
								AITAmount = ?(AmountOfPersonalIncomeTaxDistribution = Undefined, 0, AmountOfPersonalIncomeTaxDistribution[Cnt]);
								
								If ValueIsFilled(DistributionString.ExpenseItemManagementAccounting) Then
									If DistributionString.TypeOfMaExpenses = Enums.ExpenseTypes.TypeOfExpensesProduction Then
										AmountExcludingVAT = ?(AmountWithoutVATDistribution = Undefined, 0, AmountWithoutVATDistribution[Cnt]);
									Else
										AmountExcludingVAT = 0;
									EndIf;
								Else
									If DistributionString.TypeOfACExpenses = Enums.ExpenseTypes.TypeOfExpensesProduction Then
										AmountExcludingVAT = ?(AmountWithoutVATDistribution = Undefined, 0, AmountWithoutVATDistribution[Cnt]);
									Else
										AmountExcludingVAT = 0;
									EndIf;
								EndIf;
								
								//Performing the recognition of expenses in the BU
								If DistributionString.ExpenseRecognitionTypeAC <> Enums.RDExpenseRecognitionTypes.DoNotRecognizeExpenses
									And SumCompl <> 0 Then
										
									String = ExpenseRecognitionTable.Add();
									String.DepartmentDr = DistributionString.Department;
									String.LineOfBusinessDr = DistributionString.LineOfBusiness;
									String.ExpenseItemDr = DistributionString.ExpenseItemAccounting;
									String.DimensionOfExpensesDr = DistributionString.ExpensesDimensionAccounting;
									String.Organization = DataString1.Organization;
									String.DepartmentCr = DataString1.Department;
									String.LineOfBusinessCr = DataString1.LineOfBusiness;
									String.ExpenseItemCr = DataString1.ExpenseItem;
									String.DimensionOfExpensesCr = DataString1.DimensionOfExpenses;
									String.RowID = DistributionString.RowID;
									String.ApplyCoefficient = IncreasingCoefficientIsApplied(DistributionString.ExpenseRecognitionTypeTA);
									
									String.SumCompl = SumCompl;
									String.CostTD = SumCompl;
										
								EndIf;
									
								//Performing the recognition of expenses in the UU
								If DistributionString.ExpenseRecognitionTypeMA <> Enums.RDExpenseRecognitionTypes.DoNotRecognizeExpenses Then
									
									String = ExpenseRecognitionTable.Add();
									String.DepartmentDr = DistributionString.Department;
									String.LineOfBusinessDr = DistributionString.LineOfBusiness;
									String.ExpenseItemDr = DistributionString.ExpenseItemManagementAccounting;
									String.DimensionOfExpensesDr = DistributionString.ExpensesDimensionManagementAccounting;
									String.Organization = DataString1.Organization;
									String.DepartmentCr = DataString1.Department;
									String.LineOfBusinessCr = DataString1.LineOfBusiness;
									String.ExpenseItemCr = DataString1.ExpenseItem;
									String.DimensionOfExpensesCr = DataString1.DimensionOfExpenses;
									String.RowID = DistributionString.RowID;
									String.ApplyCoefficient = IncreasingCoefficientIsApplied(DistributionString.ExpenseRecognitionTypeTA);
									
									String.Sum = Sum;
									String.AmountExcludingVAT = AmountExcludingVAT;
									String.SumMan = SumMan;
									
								EndIf;
								
								//Performing the recognition of expenses in NU
								If (AmountFA <> 0 Or PermanentDifference <> 0 Or CostTD <> 0)
									And ValueIsFilled(DistributionString.ExpenseRecognitionTypeTA) Then
									
									String = ExpenseRecognitionTable.Add();
									String.DepartmentDr = DistributionString.Department;
									String.LineOfBusinessDr = DistributionString.LineOfBusiness;
									String.ExpenseItemDr = DistributionString.ExpenseItemTaxAccounting;
									String.DimensionOfExpensesDr = DistributionString.ExpensesDimensionTaxAccounting;
									String.Organization = DataString1.Organization;
									String.DepartmentCr = DataString1.Department;
									String.LineOfBusinessCr = DataString1.LineOfBusiness;
									String.ExpenseItemCr = DataString1.ExpenseItem;
									String.DimensionOfExpensesCr = DataString1.DimensionOfExpenses;
									String.RowID = DistributionString.RowID;
									String.ApplyCoefficient = IncreasingCoefficientIsApplied(DistributionString.ExpenseRecognitionTypeTA);
									String.ArticleIsAcceptedForTaxAccounting = DistributionString.ItemOfExpenditureAcceptanceForTaxAccountingTa;
									
									String.PermanentDifference = PermanentDifference;
									String.CostTD = CostTD - SumCompl;
									String.AmountFA = AmountFA;
									
								EndIf;
								
								// According to the amount of personal income tax, we only work out the reclassification of expenses to another type of asset or topic
								// Other cases are worked out by recognizing expenses of the personal income tax
								If AITAmount <> 0 
									And ValueIsFilled(DistributionString.ExpenseRecognitionTypeTA) 
									And (DistributionString.ExpenseRecognitionTypeTA = Enums.RDExpenseRecognitionTypes.RecognitionAsIntangibleAssets
										Or DistributionString.ExpenseRecognitionTypeTA = Enums.RDExpenseRecognitionTypes.MoveToAnotherTheme
										Or DistributionString.ExpenseRecognitionTypeTA = Enums.RDExpenseRecognitionTypes.RecognitionAsDeferredExpenses) Then
									
									String = ExpenseRecognitionTable.Add();
									String.DepartmentDr = DistributionString.Department;
									String.LineOfBusinessDr = DistributionString.LineOfBusiness;
									String.ExpenseItemDr = DistributionString.ExpenseItemTaxAccounting;
									String.DimensionOfExpensesDr = DistributionString.ExpensesDimensionTaxAccounting;
									String.Organization = DataString1.Organization;
									String.DepartmentCr = DataString1.Department;
									String.LineOfBusinessCr = DataString1.LineOfBusiness;
									String.ExpenseItemCr = DataString1.ExpenseItem;
									String.DimensionOfExpensesCr = DataString1.DimensionOfExpenses;
									String.RowID = DistributionString.RowID;
									
									String.AITAmount = AITAmount;
									
								EndIf;
								
							EndDo;
							
							ExpenseRecognitionTable.GroupBy(
								"Organization, DepartmentCr, LineOfBusinessCr, ExpenseItemCr, DimensionOfExpensesCr, ArticleIsAcceptedForTaxAccounting,
								|DepartmentDr, LineOfBusinessDr, ExpenseItemDr, DimensionOfExpensesDr,
								|RowID, ApplyCoefficient",
								"SumCompl, SumMan, Sum, AmountExcludingVAT, PermanentDifference, CostTD, AITAmount, AmountFA");
							
							For Each ExpenseRecognitionLine In ExpenseRecognitionTable Do
								
								DebitingLine = RegisterRecordTable.Add();
								DebitingLine.RecordType = AccumulationRecordType.Expense;
								DebitingLine.Organization = ExpenseRecognitionLine.Organization;
								DebitingLine.Department = ExpenseRecognitionLine.DepartmentCr;
								DebitingLine.LineOfBusiness = ExpenseRecognitionLine.LineOfBusinessCr;
								DebitingLine.ExpenseItem = ExpenseRecognitionLine.ExpenseItemCr;
								DebitingLine.DimensionOfExpenses = ExpenseRecognitionLine.DimensionOfExpensesCr;
								DebitingLine.Period = DateOfCalculation;
								DebitingLine.FinRecordID = New UUID();
								DebitingLine.RowID = ExpenseRecognitionLine.RowID;
								DebitingLine.Sum = ExpenseRecognitionLine.Sum;
								DebitingLine.AmountExcludingVAT = ExpenseRecognitionLine.AmountExcludingVAT;
								DebitingLine.SumMan = ExpenseRecognitionLine.SumMan;
								DebitingLine.SumCompl = ExpenseRecognitionLine.SumCompl;
								DebitingLine.PermanentDifference = ExpenseRecognitionLine.PermanentDifference;
								DebitingLine.CostTD = ExpenseRecognitionLine.CostTD;
								DebitingLine.AITAmount = ExpenseRecognitionLine.AITAmount;
								
								RecognitionString = RegisterRecordTable.Add();
								RecognitionString.Organization = DataString1.Organization;
								RecognitionString.RecordType = AccumulationRecordType.Receipt;
								RecognitionString.Department = ExpenseRecognitionLine.DepartmentDr;
								RecognitionString.LineOfBusiness = ExpenseRecognitionLine.LineOfBusinessDr;
								RecognitionString.ExpenseItem = ExpenseRecognitionLine.ExpenseItemDr;
								RecognitionString.DimensionOfExpenses = ExpenseRecognitionLine.DimensionOfExpensesDr;
								RecognitionString.Period = DateOfCalculation;
								RecognitionString.FinRecordID = DebitingLine.FinRecordID;
								RecognitionString.RowID = ExpenseRecognitionLine.RowID;
								RecognitionString.Sum = ExpenseRecognitionLine.Sum;
								RecognitionString.AmountExcludingVAT = ExpenseRecognitionLine.AmountExcludingVAT;
								RecognitionString.SumMan = ExpenseRecognitionLine.SumMan;
								RecognitionString.SumCompl = ExpenseRecognitionLine.SumCompl;
								If ExpenseRecognitionLine.ArticleIsAcceptedForTaxAccounting = True Then
									RecognitionString.PermanentDifference = ExpenseRecognitionLine.PermanentDifference;
								Else
									RecognitionString.PermanentDifference = ExpenseRecognitionLine.AmountFA + ExpenseRecognitionLine.PermanentDifference;
								EndIf;
								RecognitionString.CostTD = ExpenseRecognitionLine.CostTD;
								RecognitionString.AITAmount = ExpenseRecognitionLine.AITAmount;
								RecognitionString.ApplyCoefficient = ExpenseRecognitionLine.ApplyCoefficient;
								
							EndDo;
						EndDo;
					EndIf;
				EndIf;
			EndDo;
			
			If RegisterRecordTable.Count() > 0 Then
		
				RDExpensesAccountingLocalization.ApplyBoostingFactor(RegisterRecordTable,
							RecognitionDocument, LineRecognitionDocument.Organization, DateOfCalculation);
	
				RegisteredRecordsOtherExpenses.Load(RegisterRecordTable);
				RegisteredRecordsOtherExpenses.SetActive(True);
				RegisteredRecordsOtherExpenses.Write();
				
				RegisterRecords = New Structure("OtherExpenses", RegisteredRecordsOtherExpenses);
			
				CashFlowsIncomeExpensesOtherAssetsLiabilities(
						RegisterRecords,
						RecognitionDocument,
						DateOfCalculation,
						BusinessOperation);
				
				If GetFunctionalOption("UseBalanceSheetStatement") 
					And Not GetFunctionalOption("NewOnlineARAPAccounting") Then
					DataProcessors.FlowOfAssetsAndLiabilities.ReflectDocumentsInManagementBalanceSheet(RecognitionDocument, RegisterRecords);
				EndIf;
				FinancialAccountingPostingServer.AbilityToReflect(
					New Structure("Ref, RegisterRecords, Date, Organization", RecognitionDocument, RegisterRecords, DateOfCalculation, LineRecognitionDocument.Organization),
					New Structure,
					RegisterRecords);
				If RegisterRecords.Property("DocumentPostingInFinancialAccounting") Then
					IAReflectionRegisteredRecords = RegisterRecords.DocumentPostingInFinancialAccounting; //InformationRegisterRecordSet - 
					IAReflectionRegisteredRecords.Write();
				EndIf;
			EndIf;
		EndDo;
	EndDo;

EndProcedure

Procedure CashFlowsIncomeExpensesOtherAssetsLiabilities(RegisterRecords, RecognitionDocument, DateOfCalculation, BusinessOperation)
	
	ComplAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(
							Common.ObjectAttributeValue(RecognitionDocument, "Organization"));
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	OtherExpenses.RecordType AS RecordType,
		|	OtherExpenses.Organization AS Organization,
		|	OtherExpenses.Department AS Department,
		|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
		|	OtherExpenses.ExpenseItem AS ExpenseItem,
		|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
		|	OtherExpenses.SumCompl AS SumCompl,
		|	OtherExpenses.Sum AS Sum,
		|	OtherExpenses.AmountExcludingVAT AS AmountExcludingVAT,
		|	OtherExpenses.FinRecordID AS FinRecordID
		|INTO TTRecordsData
		|FROM
		|	&OtherExpenses AS OtherExpenses
		|
		|INDEX BY
		|	FinRecordID
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&Period AS Period,
		|	&BusinessOperation AS BusinessOperation,
		|	IncomingRegisteredRecords.Organization AS Organization,
		|	ConsumableRegisteredRecords.Department AS Department,
		|	ConsumableRegisteredRecords.LineOfBusiness AS LineOfBusiness,
		|	ConsumableRegisteredRecords.ExpenseItem AS AssetRef,
		|	ConsumableRegisteredRecords.DimensionOfExpenses AS DimensionOfExpenses,
		|	IncomingRegisteredRecords.Department AS DebitBusinessUnit,
		|	IncomingRegisteredRecords.LineOfBusiness AS CorLineOfBusiness,
		|	IncomingRegisteredRecords.ExpenseItem AS CorItem,
		|	IncomingRegisteredRecords.DimensionOfExpenses AS CorExpenditureDimension,
		|	SUM(IncomingRegisteredRecords.SumCompl) AS SumCompl,
		|	SUM(IncomingRegisteredRecords.Sum * &ConversionRateToManCurrency) AS Sum,
		|	SUM(CASE
		|		WHEN CAST(IncomingRegisteredRecords.ExpenseItem AS
		|			ChartOfCharacteristicTypes.ExpenseItems).CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|		OR
		|		NOT &CompanyManagementAccounting
		|			THEN 0
		|		ELSE IncomingRegisteredRecords.AmountExcludingVAT * &ConversionRateToManCurrency
		|	END) AS SumMan,
		|	SUM(IncomingRegisteredRecords.Sum) AS AmountInCurrency,
		|	&Currency AS Currency
		|FROM
		|	TTRecordsData AS IncomingRegisteredRecords
		|		LEFT JOIN TTRecordsData AS ConsumableRegisteredRecords
		|		ON IncomingRegisteredRecords.FinRecordID = ConsumableRegisteredRecords.FinRecordID
		|		AND IncomingRegisteredRecords.RecordType <> ConsumableRegisteredRecords.RecordType
		|WHERE
		|	IncomingRegisteredRecords.RecordType = &RecordTypeReceipt
		|	AND IncomingRegisteredRecords.SumCompl + IncomingRegisteredRecords.Sum <> 0
		|GROUP BY
		|	IncomingRegisteredRecords.Organization,
		|	ConsumableRegisteredRecords.Department,
		|	ConsumableRegisteredRecords.LineOfBusiness,
		|	ConsumableRegisteredRecords.ExpenseItem,
		|	ConsumableRegisteredRecords.DimensionOfExpenses,
		|	IncomingRegisteredRecords.Department,
		|	IncomingRegisteredRecords.LineOfBusiness,
		|	IncomingRegisteredRecords.ExpenseItem,
		|	IncomingRegisteredRecords.DimensionOfExpenses";
	
	Query.SetParameter("OtherExpenses", RegisterRecords.OtherExpenses.Unload());
	Query.SetParameter("RecordTypeReceipt", AccumulationRecordType.Receipt);
	Query.SetParameter("Period", DateOfCalculation);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("Currency", ComplAccountingCurrency);
	Query.SetParameter("ConversionRateToManCurrency", ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
																	ComplAccountingCurrency,
																	Constants.ManagementAccountingCurrency.Get(), 
																	DateOfCalculation));
	Query.SetParameter("CompanyManagementAccounting", CalculationOfCostCached.CompanyManagementAccounting(
																	BegOfMonth(DateOfCalculation)));
	
	QueryResult = Query.Execute();
	
	RegisteredRecordsAssetsLiabilities = AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.CreateRecordSet();
	RegisteredRecordsAssetsLiabilities.Filter.Recorder.Set(RecognitionDocument);
	
	RegisteredRecordsAssetsLiabilities.Load(QueryResult.Unload());
	RegisteredRecordsAssetsLiabilities.Write();

	RegisterRecords.Insert("RecordsIncomeExpensesOtherAssetsLiabilities", RegisteredRecordsAssetsLiabilities); 

EndProcedure

#EndRegion