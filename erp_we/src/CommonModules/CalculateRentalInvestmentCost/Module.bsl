////////////////////////////////////////////////////////////////////////////////
// Procedures related of operation "Calculation of cost of investment in lease".
// 
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region HandlersForMonthClosingStages

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage(StepsTable, CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.CalculateRentalInvestmentCost);
		
	NewRow.MultilingualName = "vi = 'Tính giá trị đầu tư cho thuê';
								|ru = 'Расчет стоимости инвестиции в аренду';
								|en = 'Calculate rental investment cost';
								|it = 'Calculate rental investment cost';
								|pl = 'Calculate rental investment cost';
								|tr = 'Kiralama yatırımının değerinin hesaplanması'"; // @NStr-1
	NewRow.PreviousStages_.Add(Catalogs.MonthEndClosingOperations.UpdatingRecordsOfFixedAssetsAndIntangibleAssets);
	
	NewRow.TextExecute = NStr("vi = 'Thực hiện';
								|ru = 'Выполнить';
								|en = 'Run'; fa = 'اجرا';
								|it = 'Выполнить';
								|pl = 'Run';
								|tr = 'Gerçekleştir'");
	
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"CalculateRentalInvestmentCost.DetermineOperationStatus");
		
	NewRow.ActionExecute = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"CalculateRentalInvestmentCost.ExecuteOperation");
		
EndProcedure

// Defines the Status of Operation "USE_ACCOUNTING_INVESTMENT_TEND".
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
Procedure DetermineOperationStatus(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(HandlerParameters.CalculationParameters.Period) Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Đã tắt sử dụng kế toán tài sản dài hạn.';
				|ru = 'Учет внеоборотных активов отключен.';
				|en = 'Accounting of fixed assets is disabled.'; fa = 'Accounting of fixed assets is disabled.';
				|it = 'La contabilità degli attivi non circolanti è disattivata.';
				|pl = 'Ewidencja aktyw pozaobrotowych jest odłączona.';
				|tr = 'Duran varlıkların muhasebeleştirilmesi devre dışı bırakılmıştır.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	If MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, True) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.ProvideAssetsToLeasee2_4 AS ProvideAssetsToLeasee
	|WHERE
	|	ProvideAssetsToLeasee.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ProvideAssetsToLeasee.Organization IN (&CompanyArray)
	|	AND ProvideAssetsToLeasee.Posted
	|	AND ProvideAssetsToLeasee.Contract.ContractType IN (&TypesOfContractsUnderFSB25)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.ChangeRentalTerms AS ChangingConditions
	|WHERE
	|	ChangingConditions.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ChangingConditions.Organization IN (&CompanyArray)
	|	AND ChangingConditions.Posted
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then

		ExplanationText = StrTemplate(
			NStr("vi = 'Trong kỳ %1 không có nhiệm vụ để hạch toán giao dịch này.';
				|ru = 'За период %1 нет заданий для расчета данной операции.';
				|en = 'No jobs to calculate this operation for the %1 period.'; fa = 'No jobs to calculate this operation for the %1 period.';
				|it = 'Per il periodo %1 non ci sono compiti per il calcolo di questa operazione.';
				|pl = 'Za okres %1 nie ma zadań do obliczenia danej operacji.';
				|tr = 'Bu işlemi hesaplamak için dönem %1 için herhangi bir görev yoktur.'", Common.DefaultLanguageCode()),
			CostCalculationProtocol.PresentationOfCalculationPeriod(HandlerParameters.CalculationParameters.RegistrationPeriod));
			
		MonthEndTransactionsServer.NoNeedToSetState(HandlerParameters, ExplanationText);
			
	EndIf;
		
EndProcedure

// Performs the Operation "Calculation of the cost of the investment in the lease".
// 
// Parameters:
//  HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
Procedure ExecuteOperation(HandlerParameters) Export

	CalculationParameters = HandlerParameters.CalculationParameters;
			
	OperationParametersList = OperationParametersList(CalculationParameters);
	
	CalculationStart = MonthEndTransactionsServer.CalculationStart(
		HandlerParameters.Data_Stage.Code,
		CalculationParameters.Period,,
		CalculationParameters.CompanyArray);
	
	HasErrors = False;
	
	While CalculationStart <= OperationParametersList.EndOfPeriod Do
		
		JobNumber = MonthEndTransactionsServer.IncreaseTaskNumber();
		
		PeriodEnding = EndOfMonth(CalculationStart);
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(CalculationStart, CalculationParameters.CompanyArray);
		OperationParametersList.CompanyArray = AvailableCompanies;
		
		JobNumber = InformationRegisters.JobsForMonthEndClosing.IncreaseTaskNumber();
		
		BeginTransaction();
		
		Try
			
			 MonthEndTransactionsServer.BlockTaskRegister(
				JobNumber,
				OperationParametersList.CompanyArray,
				HandlerParameters.Data_Stage.Code);
			
			CalculationDataForMonth = MonthEndTransactionsServer.MonthlyTasks(
				CalculationStart,
				PeriodEnding,
				JobNumber,
				OperationParametersList.CompanyArray,
				HandlerParameters.Data_Stage.Code);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi thực hiện tính toán trong kỳ %1, đã xảy ra lỗi:
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
				CostCalculationProtocol.PresentationOfCalculationPeriod(OperationParametersList.RegistrationPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			 MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				OperationParametersList.CompanyArray,
				CalculationStart);
			
		EndTry;
		
		ThereAreErrorsInPerformingCalculation = False;
		
		Try
			
			OperationParametersList.BeginOfPeriod = CalculationStart;
			OperationParametersList.EndOfPeriod = PeriodEnding;
			
			// The procedure can only be performed monthly
			//@skip-check query-in-loop
			PerformOperationInMonth(OperationParametersList);
			
			ThereAreErrorsInPerformingCalculation = MonthEndTransactionsServer.ThereAreErrorsInPerformingCalculation(
				HandlerParameters.Data_Stage.Code,
				OperationParametersList.CompanyArray, 
				CalculationStart);
											
		Except
			
			HasErrors = True;
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				DetailErrorDescription(ErrorInfo()),
				OperationParametersList.CompanyArray,
				CalculationStart);
			
		EndTry;
		
		If ThereAreErrorsInPerformingCalculation Then
			HasErrors = True;
		EndIf;
		
		If HasErrors Then
			Break;
		EndIf;
		
		MonthEndTransactionsServer.DeleteTasksToBeCalculatedForCurPeriod(HandlerParameters, CalculationDataForMonth);
		
		CalculationStart = PeriodEnding + 1;
		
	EndDo;
	
EndProcedure

// Performs the Operation "Calculation of the cost of the investment in the lease" for documents.
// 
// Parameters:
//  ReferencesArrray - Array of DocumentRef - Documents for which transactions are generated
Procedure PerformOperationOfOperationOnDocuments(ReferencesArrray) Export
	
	If Not GetFunctionalOption("UseNonCurrentAssets2_4") Then
		Return;
	EndIf; 
	
	OperationParametersList = OperationParametersList();
	OperationParametersList.ReturnDocumentsToReflection = False;
	OperationParametersList.GenerateJobs = False;
	OperationParametersList.DocumentsList = ReferencesArrray;
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentsList.Organization AS Organization,
	|	DocumentsList.Date AS Date
	|FROM
	|	(SELECT
	|		DocumentData.Organization AS Organization,
	|		BEGINOFPERIOD(DocumentData.Date, MONTH) AS Date
	|	FROM
	|		Document.ProvideAssetsToLeasee2_4 AS DocumentData
	|	WHERE
	|		DocumentData.Ref IN (&ReferencesArrray)
	|		AND DocumentData.Posted
	|
	|		AND NOT (TRUE IN (
	|			SELECT TOP 1 
	|				TRUE 
	|			FROM 
	|				AccumulationRegister.OtherExpenses AS OtherExpenses 
	|			WHERE 
	|				OtherExpenses.Recorder = DocumentData.Ref
	|				AND OtherExpenses.BusinessOperation IN (&ListBT)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentData.Organization AS Organization,
	|		BEGINOFPERIOD(DocumentData.Date, MONTH) AS Date
	|	FROM
	|		Document.ChangeRentalTerms AS DocumentData
	|	WHERE
	|		DocumentData.Ref IN (&ReferencesArrray)
	|		AND DocumentData.Posted
	|
	|		AND NOT (TRUE IN (
	|			SELECT TOP 1 
	|				TRUE 
	|			FROM 
	|				AccumulationRegister.OtherExpenses AS OtherExpenses 
	|			WHERE 
	|				OtherExpenses.Recorder = DocumentData.Ref
	|				AND OtherExpenses.BusinessOperation IN (&ListBT)))
	|
	|	) AS DocumentsList
	|
	|ORDER BY
	|	Date,
	|	Organization
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	
	ListBT = New Array;
	ListBT.Add(Enums.BusinessTransactions.ProvideAssetsToLeasee);
	ListBT.Add(Enums.BusinessTransactions.ChangeRentalTerms);
	Query.SetParameter("ListBT", ListBT);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
	
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(Selection.Date, CommonClientServer.ValueInArray(Selection.Organization));
		
		OperationParametersList.CompanyArray = AvailableCompanies;
		OperationParametersList.BeginOfPeriod = BegOfMonth(Selection.Date);
		OperationParametersList.EndOfPeriod = EndOfMonth(Selection.Date);
		
		// We perform the operation only if it has not been performed yet (so as not to spoil the movement).
		CalculationStart = MonthEndTransactionsServer.CalculationStart(
			Catalogs.MonthEndClosingOperations.CalculateRentalInvestmentCost,
			OperationParametersList.BeginOfPeriod,,
			OperationParametersList.CompanyArray);
		
		If CalculationStart <= OperationParametersList.BeginOfPeriod Then
			// It is performed in a cycle, because execution is possible only in one month
			//@skip-check query-in-loop
			PerformOperationInMonth(OperationParametersList);
		EndIf;
	
	EndDo;
	
EndProcedure

#EndRegion

#Region JobsForMonthEndClosing

// Defines the period from which it is required to perform the "Cost calculation of operation of the investment in the lease".
//
// Parameters:
//  Organization   - CatalogRef.Companies - 
//  BeginOfPeriod - Date - The period being checked.
// 
// Returns:
//  Date - The date from which the calculation is required.
//
Function NextPeriodOfOperation(Organization, BeginOfPeriod) Export
	
	QueryText =
	"SELECT
	|	MIN(DocumentsTable.Period) AS Period
	|FROM
	|	(SELECT
	|		ProvideAssetsToLeasee.Date AS Period
	|	FROM
	|		Document.ProvideAssetsToLeasee2_4 AS ProvideAssetsToLeasee
	|	WHERE
	|		ProvideAssetsToLeasee.Date >= &BeginOfPeriod
	|		AND ProvideAssetsToLeasee.Organization IN (&Organization)
	|		AND ProvideAssetsToLeasee.Posted
	|		AND ProvideAssetsToLeasee.Contract.ContractType IN (&TypesOfContractsUnderFSB25)
	|	
	|	UNION ALL
	|
	|	SELECT
	|		ChangingConditions.Date AS Period
	|	FROM
	|		Document.ChangeRentalTerms AS ChangingConditions
	|	WHERE
	|		ChangingConditions.Date >= &BeginOfPeriod
	|		AND ChangingConditions.Organization IN (&Organization)
	|		AND ChangingConditions.Posted
	|	
	|	) AS DocumentsTable";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("BeginOfPeriod", BegOfMonth(BeginOfPeriod));
	Query.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	Selection = Result.Select();
	If Selection.Next() Then
		Return ?(ValueIsFilled(Selection.Period), BegOfMonth(Selection.Period), '000101010000');
	EndIf;

	Return '000101010000';
	
EndFunction

// Generates tasks for performing an operation when the source data changes.
// 
// Parameters:
//  Document - DocumentObject - Document.
//  TempTablesManager - TempTablesManager - Table data.
Procedure GenerateJobs(Document, TempTablesManager) Export

	If Not GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		Return;
	EndIf;
	
	If RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document) Then
		Return;
	EndIf;
	
	TablesToUse = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	
	TablesList = New Array;
	TablesList.Add("OtherExpenses_TasksForCalculatingCostOfInvestmentInLease");
	TablesList.Add("ProvideAssetsToLeasee2_4");
	TablesList.Add("ChangeRentalTerms");

	DefineChangesForGeneratingTasks(TempTablesManager);

	DataJoinText = NonCurrentAssets.GenerateTextForCombiningDataToFormTask(TablesList, TempTablesManager);
	
	// Documents are always registered, because during the execution, deferred movements are deleted.
	RegisterDocument = 
		TypeOf(Document.Ref) = Type("DocumentRef.ProvideAssetsToLeasee2_4")
		Or TypeOf(Document.Ref) = Type("DocumentRef.ChangeRentalTerms");
	
	If RegisterDocument Then
		
		ListOfMergeRequests = New Array;
		
		If DataJoinText <> "" Then
			ListOfMergeRequests.Add(DataJoinText);
		EndIf; 
			
		QueryText =
		"SELECT
		|	ChangedData.IBDocumentDate AS Period,
		|	ChangedData.Organization AS Organization,
		|	ChangedData.Ref AS Document,
		|	"""" AS TableName
		|FROM
		|	InformationRegister.DocumentsRegistry AS ChangedData
		|
		|WHERE
		|	ChangedData.Ref = &Ref
		|	AND ChangedData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ProvideAssetsToLeasee),
		|		VALUE(Enum.BusinessTransactions.ChangeRentalTerms))
		|";
		
		ListOfMergeRequests.Add(QueryText);
		
		DataJoinText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf; 
	
	If DataJoinText = "" Then
		TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TablesToUse);
		Return;
	EndIf;

	QueryText =
	"SELECT
	|	VALUE(Catalog.MonthEndClosingOperations.CalculateRentalInvestmentCost) AS Operation,
	|	ChangedData.Organization AS Organization,
	|	ChangedData.Document AS Document,
	|
	|	MIN(CASE 
	|				WHEN ChangedData.Period < &AccountingStartDate24
	|					THEN &AccountingStartDate24
	|				WHEN NOT OBEntry.Date IS NULL
	|					THEN DATEADD(BEGINOFPERIOD(OBEntry.Date, MONTH), MONTH, 1)
	|				ELSE ChangedData.Period
	|			END) AS Month
	|FROM
	|	&DataJoinText AS ChangedData
	|
	|		LEFT JOIN Document.OBEntryOtherExpenses AS OBEntry
	|		ON OBEntry.Ref = ChangedData.Document
	|
	|GROUP BY
	|	ChangedData.Organization,
	|	ChangedData.Document";
	
	QueryText = StrReplace(QueryText, "&DataJoinText", "(" + DataJoinText + ")");

	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Ref", Document.Ref);
	Query.SetParameter("AccountingStartDate24", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntriesBasedOnSampleData(Selection);
	
	SetPrivilegedMode(False);
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TablesToUse);
	
EndProcedure

// Determines whether movements are recorded when performing an operation.
// 
// Parameters:
//  Document - DocumentObject -
// 
// Returns:
//  Boolean
Function RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document) Export

	Return Document <> Undefined
			And Document.AdditionalProperties.Property(OperationName());
	
EndFunction

#EndRegion

#Region FormationOfTablesForCarryingOut

// Generates the query text for the "Other expenses" register table.
// 
// Parameters:
//  QueryTexts - ValueList - Request texts
Procedure QueryTextTableOtherExpenses(QueryTexts) Export
	
	Add_Fields = "RowID";
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));
	
	#Region RevaluationToFairCost // Dr 91.02 - Cr 58.AP
	QueryText =
	"SELECT
	|	CostAdjustment_.Date                       AS Period,
	|	VALUE(AccumulationRecordType.Receipt)           AS RecordType,
	|	CostAdjustment_.Organization                AS Organization,
	|	CostAdjustment_.Contract.Department      AS Department,
	|	CostAdjustment_.ExpenseItem             AS ExpenseItem,
	|	CostAdjustment_.DimensionOfExpenses          AS DimensionOfExpenses,
	|	CostAdjustment_.Contract.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                                     AS VATActivityType,
	|	
	|	CostAdjustment_.ManSExpenses - CostAdjustment_.FairValueManag AS AmountIncludingVAT,
	|	CostAdjustment_.ManSExpenses - CostAdjustment_.FairValueManag AS AmountExcludingVAT,
	|	CostAdjustment_.ManSExpenses - CostAdjustment_.FairValueManag AS AmountExcludingVATMan,
	|	CostAdjustment_.LocalExpenses - CostAdjustment_.FairValueLocal AS AmountIncludingVATCompl,
	|	CostAdjustment_.LocalExpenses - CostAdjustment_.FairValueLocal AS AmountExcludingVATCompl,
	|	0                                                AS PermanentDifference,
	|
	|	CostAdjustment_.LocalExpenses - CostAdjustment_.FairValueLocal AS CostTD,
	|	&HO_RevaluationOfFI                                 AS BusinessOperation,
	|	UNDEFINED                                     AS ItemsLocationAttributes,
	|	CostAdjustment_.RowID        AS FinRecordID,
	|	&SettingUpHO_RevaluationOfFI                        AS BusinessTransactionSetting,
	|	CostAdjustment_.RowID        AS RowID
	|
	|FROM
	|	DataFA AS CostAdjustment_
	|
	|WHERE
	|	CostAdjustment_.Ref = &Ref
	|	AND CostAdjustment_.LocalExpenses > CostAdjustment_.FairValueLocal
	|	AND CostAdjustment_.FairValueLocal > 0
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region ClosingExpensesForTransferToLease // Dr 58.AP - Cr 58.VA
	QueryText =
	"SELECT
	|	RentalDocuments.Date                            AS Period,
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	WriteOffOfExpenses.Organization                    AS Organization,
	|	WriteOffOfExpenses.Department                  AS Department,
	|	WriteOffOfExpenses.ExpenseItem                 AS ExpenseItem,
	|	WriteOffOfExpenses.DimensionOfExpenses              AS DimensionOfExpenses,
	|	WriteOffOfExpenses.LineOfBusiness        AS LineOfBusiness,
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	WriteOffOfExpenses.Sum                          AS AmountIncludingVAT,
	|	WriteOffOfExpenses.AmountExcludingVAT                    AS AmountExcludingVAT,
	|	WriteOffOfExpenses.SumMan                       AS AmountExcludingVATMan,
	|	WriteOffOfExpenses.SumCompl                      AS AmountIncludingVATCompl,
	|	WriteOffOfExpenses.SumCompl                      AS AmountExcludingVATCompl,
	|	0                                               AS PermanentDifference,
	|	WriteOffOfExpenses.SumCompl                      AS CostTD,
	|
	|	RentalDocuments.BusinessOperation           AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|	RentalDocuments.RowID             AS FinRecordID,
	|	RentalDocuments.SettingUpHO                     AS BusinessTransactionSetting,
	|	RentalDocuments.RowID             AS RowID
	|
	|FROM
	|	RentalTransferCosts AS WriteOffOfExpenses
	|		INNER JOIN RentalDocuments AS RentalDocuments
	|		ON RentalDocuments.FixedAsset = WriteOffOfExpenses.DimensionOfExpenses
	|
	|WHERE
	|	RentalDocuments.Ref = &Ref
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, "TTInitialOtherExpenses");
	
	QueryTexts.Add(AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(Add_Fields), "TTOtherExpenses_");
	QueryTexts.Add(AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(Add_Fields), "OtherExpenses", True);
	
EndProcedure

// Generates the query text for the "Other Income" register table.
// 
// Parameters:
//  QueryTexts - ValueList - Request texts
Procedure QueryTextTableOtherIncome(QueryTexts) Export
	
	QueryText =
	"SELECT
	|	CostAdjustment_.Date AS Period,
	|	
	|	CostAdjustment_.Organization AS Organization,
	|	CostAdjustment_.Contract.Department AS Department,
	|	CostAdjustment_.IncomeItem AS IncomeItem,
	|	CostAdjustment_.DimensionOfRevenue AS DimensionOfRevenue,
	|	
	|	CostAdjustment_.FairValueManag - CostAdjustment_.ManSExpenses AS Sum,
	|	CostAdjustment_.FairValueManag - CostAdjustment_.ManSExpenses AS SumMan,
	|	CostAdjustment_.FairValueLocal - CostAdjustment_.LocalExpenses AS SumCompl,
	|	0 AS PermanentDifference,
	|	CostAdjustment_.FairValueLocal - CostAdjustment_.LocalExpenses AS CostTD,
	|	
	|	&SettingUpHO_RevaluationOfFI AS BusinessOperation,
	|	CostAdjustment_.Contract.LineOfBusiness AS LineOfBusiness,
	|	
	|	CostAdjustment_.RowID AS FinRecordID,
	|	&SettingUpHO_RevaluationOfFI AS BusinessTransactionSetting
	|	
	|FROM
	|	DataFA AS CostAdjustment_
	|WHERE
	|	CostAdjustment_.Ref = &Ref
	|	AND CostAdjustment_.FairValueLocal > CostAdjustment_.LocalExpenses
	|";
	
	QueryTexts.Add(QueryText, "OtherIncome", True);
	
EndProcedure

// Generates the Query Text for the table of the register "Investment in rent".
// Returns:
//  String
// 
Function QueryTextTableInvestmentInRent() Export
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN CostAdjustment_.FairValueLocal > CostAdjustment_.LocalExpenses THEN
	|			VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	CostAdjustment_.Ref               AS Recorder,
	|	CostAdjustment_.Date                 AS Period,
	|	CostAdjustment_.Organization          AS Organization,
	|	CostAdjustment_.Contract              AS Contract,
	|	CostAdjustment_.ARAPCurrency AS Currency,
	|	CostAdjustment_.FixedAsset     AS FixedAsset,
	|	DocumentData.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	0                                          AS RentalPayments,
	|	CASE
	|		WHEN CostAdjustment_.FairValueLocal > CostAdjustment_.LocalExpenses THEN
	|			CostAdjustment_.FairValueLocal - CostAdjustment_.LocalExpenses
	|		ELSE
	|			CostAdjustment_.LocalExpenses - CostAdjustment_.FairValueLocal
	|	END AS RentalPaymentsLocal,
	|	CASE
	|		WHEN CostAdjustment_.FairValueLocal > CostAdjustment_.LocalExpenses THEN
	|			CostAdjustment_.FairValueManag - CostAdjustment_.ManSExpenses
	|		ELSE
	|			CostAdjustment_.ManSExpenses - CostAdjustment_.FairValueManag
	|	END AS RentalPaymentsManag,
	|	0                                          AS NonGuaranteedResidualValueLocal,
	|	0                                          AS NonGuaranteedResidualValueManag,
	|	0                                          AS InterestDiscount,
	|	0                                          AS InterestDiscountLocal,
	|	0                                          AS InterestDiscountMan,
	|	&SettingUpHO_RevaluationOfFI                  AS BusinessTransactionSetting,
	|	CostAdjustment_.RowID  AS FinRecordID
	|FROM
	|	DataFA AS CostAdjustment_
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = CostAdjustment_.Ref
	|WHERE
	|	CostAdjustment_.Ref = &Ref
	|	AND CostAdjustment_.FairValueLocal > 0
	|";
	
	Return QueryText;
	
EndFunction

// Generates the Query Text for the register table "Schedule of accrual of interest on income rent".
// 
// Parameters:
//  QueryTexts - ValueList - Request texts
Procedure QueryTextTableScheduleOfInterestChargesOnIncomeRental(QueryTexts) Export
	
	RegisterName = "ScheduleOfInterestChargesOnIncomeRental";
	
	QueryText =
	"SELECT
	|	DocumentData.Period                AS ChangeDate,
	|	DocumentData.Contract               AS Contract,
	|	DocumentData.Ref                AS EffectiveContractTerms,
	|	ChartTable.Date                   AS Date,
	|	ChartTable.FixedAsset       AS FixedAsset,
	|	ChartTable.Interests               AS Interests,
	|	ChartTable.InterestAdjustment AS InterestAdjustment
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN TableScheduleOfAccrualOfInterest AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

// Generates the query text for the register table "Movement Nomenclature Income Expenses".
// 
// Parameters:
//  QueryTexts - ValueList - Request texts
Procedure QueryTextTableReflectionOfDocumentsInLocalAccounting(QueryTexts) Export

	QueryText =
	"SELECT 
	|	RentalDocuments.Recorder AS Document,
	|	RentalDocuments.Organization AS Organization,
	|	BEGINOFPERIOD(RentalDocuments.Date, DAY) AS DateRecord
	|
	|FROM
	|	RentalDocuments AS RentalDocuments
	|
	|WHERE
	|	RentalDocuments.Recorder = &Ref
	|";
	
	QueryTexts.Add(QueryText, "ReflectionOfDocumentsInLocalAccounting", True);
	
EndProcedure

// Sets the request parameters that are used when performing the operation.
// 
// Parameters:
//  Query - Query - Query
Procedure SetRequestParameters(Query) Export
	
	Query.SetParameter(
		"BO_CloseFixedAssetWriteOffExpenses",
		Enums.BusinessTransactions.CloseFixedAssetWriteOffExpenses);
	
	Query.SetParameter(
		"SettingUpHO_ClosingExpensesFromFADebiting", 
		Catalogs.BusinessTransactionsSettings.CloseFixedAssetWriteOffExpenses);
	
	Query.SetParameter(
		"BO_CloseFixedAssetSalesExpenses", 
		Enums.BusinessTransactions.CloseFixedAssetSalesExpenses);
		
	Query.SetParameter(
		"SettingUpHO_ClosingExpensesFromFAImplementation", 
		Catalogs.BusinessTransactionsSettings.CloseFixedAssetSalesExpenses);
	
	Query.SetParameter(
		"BO_CloseFixedAssetSalesExpensesWithDeferredTitleTransfer", 
		Enums.BusinessTransactions.CloseFixedAssetSalesExpensesWithDeferredTitleTransfer);
	
	Query.SetParameter(
		"SettingUpHO_ClosingExpensesFromOSSImplementationByDeferredTransferOfRights", 
		Catalogs.BusinessTransactionsSettings.CloseFixedAssetSalesExpensesWithDeferredTitleTransfer);
	
	Query.SetParameter(
		"BO_CloseExpensesOnFixedAssetSalesAfterTheTitleTransfer", 
		Enums.BusinessTransactions.CloseExpensesOnFixedAssetSalesAfterTheTitleTransfer);
	
	Query.SetParameter(
		"SettingUpHo_ClosingExpensesFromFAImplementationAfterTransferOfRights", 
		Catalogs.BusinessTransactionsSettings.CloseExpensesOnFixedAssetSalesAfterTheTitleTransfer);
	
	Query.SetParameter(
		"BO_CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets", 
		Enums.BusinessTransactions.CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets);
	
	Query.SetParameter(
		"SettingHO_AdjustmentOfCostOfInventoryRegisteredAtDisposalOfFA", 
		Catalogs.BusinessTransactionsSettings.CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets);
	
	Query.SetParameter(
		"BO_AdjustmentOfExpensesFromDisposalOfFixedAssets", 
		Enums.BusinessTransactions.AdjustmentOfExpensesFromDisposalOfFixedAssets);
	
	Query.SetParameter(
		"SettingHO_AdjustmentOfExpensesFromDisposalOfFA", 
		Catalogs.BusinessTransactionsSettings.AdjustmentOfExpensesFromDisposalOfFixedAssets);
	
	Query.SetParameter(
		"GenerateInventoryOwnerAttributesByFinancialAccountingGroups", 
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	Query.SetParameter(
		"IDOfUnusedFinRecord", 
		DocumentsPosting.IDOfUnusedFinRecord());
		
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure PerformOperationInMonth(OperationParametersList)
	
	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(OperationParametersList.BeginOfPeriod) Then
		Return;
	EndIf;

	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("CalculateRentalInvestmentCost.PerformOperationInMonth");
	
	OperationParametersList.DataVolume = 0;
	OperationParametersList.TempTablesManager = New TempTablesManager;
	
	PrepareTemporaryTables(OperationParametersList);
	SelectDocumentsAndRecordRegisteredRecords(OperationParametersList);
	
	OperationParametersList.TempTablesManager.Close();
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, OperationParametersList.DataVolume);
	
EndProcedure

Procedure PrepareTemporaryTables(OperationParametersList)
	
	QueryTexts = New ValueList;

#Region RentalDocuments

	QueryText = 
	"SELECT
	|	FAHandover.Ref                   AS Ref,
	|	FAHandover.Date                     AS Date,
	|	FAHandover.Organization              AS Organization,
	|	FAHandover.Department            AS Department,
	|	FAHandover.Contract                  AS Contract,
	|	FAHandover.Contract.ARAPCurrency AS ARAPCurrency,
	|
	|	FAHandover.ExpenseItemAccounting         AS ExpenseItemAccounting,
	|	FAHandover.ExpensesDimensionAccounting      AS ExpensesDimensionAccounting,
	|	FAHandover.IncomeItem            AS IncomeItem,
	|	FAHandover.DimensionOfRevenue         AS DimensionOfRevenue,
	|
	|	FATable.LineNumber               AS LineNumber,
	|	FATable.RowID       AS RowID,
	|	FATable.FixedAsset          AS FixedAsset,
	|	FATable.RentalEndDate       AS RentalEndDate,
	|	FATable.FairValueLocal AS FairValueLocal,
	|	FATable.FairValueManag  AS FairValueManag,
	|	FATable.NonGuaranteedResidualValueLocal                  AS NonGuaranteedResidualValueLocal,
	|	FATable.NonGuaranteedResidualValueManag                   AS NonGuaranteedResidualValueManag,
	|	FATable.RentalPayments           AS RentalPayments,
	|	FATable.AdvancePaymentsLocal      AS AdvancePaymentsLocal,
	|	FATable.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually,
	|	VALUE(Enum.BusinessTransactions.ProvideAssetsToLeasee) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProvideAssetsToLeasee) AS SettingUpHO
	|
	|INTO RentalDocuments
	|
	|FROM
	|	Document.ProvideAssetsToLeasee2_4 AS FAHandover
	|		
	|		INNER JOIN Document.ProvideAssetsToLeasee2_4.FA AS FATable
	|		ON FATable.Ref = FAHandover.Ref
	|WHERE
	|	FAHandover.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND FAHandover.Organization IN (&CompanyArray)
	|	AND FAHandover.Posted
	|	AND (FAHandover.Ref IN (&DocumentsList)
	|		OR &WithoutSelectionOfDocuments)
	|	AND FAHandover.Contract.ContractType IN (&TypesOfContractsUnderFSB25)
	|
	|UNION ALL
	|
	|SELECT
	|	ChangingConditions.Ref        AS Ref,
	|	ChangingConditions.Date          AS Date,
	|	ChangingConditions.Organization   AS Organization,
	|	ChangingConditions.Department AS Department,
	|	ChangingConditions.Contract       AS Contract,
	|	ChangingConditions.Contract.ARAPCurrency AS ARAPCurrency,
	|
	|	UNDEFINED                   AS ExpenseItemAccounting,
	|	UNDEFINED                   AS ExpensesDimensionAccounting,
	|	UNDEFINED                   AS IncomeItem,
	|	UNDEFINED                   AS DimensionOfRevenue,
	|
	|	FATable.LineNumber          AS LineNumber,
	|	FATable.RowID  AS RowID,
	|	FATable.FixedAsset     AS FixedAsset,
	|	FATable.RentalEndDate       AS RentalEndDate,
	|	0                              AS FairValueLocal,
	|	0                              AS FairValueManag,
	|	FATable.NonGuaranteedResidualValueLocal             AS NonGuaranteedResidualValueLocal,
	|	FATable.NonGuaranteedResidualValueManag              AS NonGuaranteedResidualValueManag,
	|	FATable.RentalPayments      AS RentalPayments,
	|	0                              AS AdvancePaymentsLocal,
	|	FATable.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually,
	|	VALUE(Enum.BusinessTransactions.ChangeRentalTerms) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ChangeRentalTerms) AS SettingUpHO
	|FROM
	|	Document.ChangeRentalTerms AS ChangingConditions
	|		
	|		INNER JOIN Document.ChangeRentalTerms.FA AS FATable
	|		ON FATable.Ref = ChangingConditions.Ref
	|WHERE
	|	ChangingConditions.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ChangingConditions.Organization IN (&CompanyArray)
	|	AND ChangingConditions.Posted
	|	AND (ChangingConditions.Ref IN (&DocumentsList)
	|		OR &WithoutSelectionOfDocuments)
	|
	|INDEX BY
	|	Organization,
	|	FixedAsset,
	|	BusinessOperation
	|";

	QueryTexts.Add(QueryText, "RentalDocuments");

#EndRegion

#Region TTCurrencyConversionFactors

	QueryText = 
	"SELECT DISTINCT
	|	DocumentsData.Organization AS Organization,
	|	DocumentsData.ARAPCurrency AS ARAPCurrency,
	|	DocumentsData.Date AS Date
	|INTO PeriodsTable
	|FROM
	|	RentalDocuments AS DocumentsData
	|
	|INDEX BY
	|	Organization,
	|	ARAPCurrency,
	|	Date";
	QueryTexts.Add(QueryText, "PeriodsTable");
	FinancialInstruments.QueryTextTTCurrencyConversionFactors(QueryTexts, "TTCurrencyConversionFactors", True);

#EndRegion

#Region Balance

	QueryText = "
	|SELECT
	|	ChartTable.Ref				AS Ref,
	|	ChartTable.Date					AS Date,
	|	ChartTable.FixedAsset		AS FixedAsset,
	|	ChartTable.Interests				AS Interests,
	|	DocumentData.TheInterestAccrualScheduleIsEnteredManually
	|INTO DocumentDataTableScheduleOfAccrualOfInterest
	|FROM
	|	RentalDocuments AS DocumentData
	|		INNER JOIN Document.ProvideAssetsToLeasee2_4.InterestAccrualSchedule AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref
	|			AND DocumentData.FixedAsset = ChartTable.FixedAsset
	|
	|UNION ALL
	|
	|SELECT
	|	ChartTable.Ref				AS Ref,
	|	ChartTable.Date					AS Date,
	|	ChartTable.FixedAsset		AS FixedAsset,
	|	ChartTable.Interests				AS Interests,
	|	DocumentData.TheInterestAccrualScheduleIsEnteredManually
	|FROM
	|	RentalDocuments AS DocumentData
	|		INNER JOIN Document.ChangeRentalTerms.InterestAccrualSchedule AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref
	|			AND DocumentData.FixedAsset = ChartTable.FixedAsset
	|WHERE
	|	ChartTable.Date >= BEGINOFPERIOD(DocumentData.Date,MONTH)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ServicePaymentSchedules.ChangeDate) AS ChangeDate,
	|	ServicePaymentSchedules.Contract                 AS Contract,
	|	ServicePaymentSchedules.FixedAsset        AS FixedAsset,
	|	DocumentData.Ref                    AS Ref,
	|	DocumentData.Date                      AS Date
	|INTO CurrentTermsAndConditionsBeforeChangesToContract
	|FROM
	|	RentalDocuments AS DocumentData
	|		INNER JOIN InformationRegister.ScheduleOfPaymentsForIncomeRentalServices AS ServicePaymentSchedules
	|		ON DocumentData.Contract = ServicePaymentSchedules.Contract
	|			AND DocumentData.FixedAsset = ServicePaymentSchedules.FixedAsset
	|WHERE
	|	ServicePaymentSchedules.ChangeDate < BEGINOFPERIOD(DocumentData.Date,DAY)
	|	AND DocumentData.BusinessOperation
	|		= VALUE(Enum.BusinessTransactions.ChangeRentalTerms)
	|GROUP BY
	|	DocumentData.Date,
	|	DocumentData.Ref,
	|	ServicePaymentSchedules.Contract,
	|	ServicePaymentSchedules.FixedAsset
	|INDEX BY
	|	Contract,
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ActualConditions.Ref AS Ref,
	|	ChartTable.FixedAsset AS FixedAsset,
	|	SUM(ChartTable.RentalService - ChartTable.RentalServiceVAT) AS RentalPayments
	|INTO RentalPaymentsBeforeChange
	|FROM
	|	InformationRegister.ScheduleOfPaymentsForIncomeRentalServices AS ChartTable
	|		INNER JOIN CurrentTermsAndConditionsBeforeChangesToContract AS ActualConditions
	|		ON ActualConditions.Contract = ChartTable.Contract
	|			AND ActualConditions.FixedAsset = ChartTable.FixedAsset
	|			AND ActualConditions.ChangeDate = ChartTable.ChangeDate
	|WHERE
	|	ChartTable.Date >= BEGINOFPERIOD(ActualConditions.Date,DAY)
	|GROUP BY
	|	ActualConditions.Ref,
	|	ChartTable.FixedAsset
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ActualConditions.Ref AS Ref,
	|	ChartTable.FixedAsset AS FixedAsset,
	|	SUM(ChartTable.Interests) AS InterestDiscount
	|INTO InterestBeforeChange
	|FROM
	|	InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS ChartTable
	|		INNER JOIN CurrentTermsAndConditionsBeforeChangesToContract AS ActualConditions
	|		ON ActualConditions.Contract = ChartTable.Contract
	|			AND ActualConditions.FixedAsset = ChartTable.FixedAsset
	|			AND ActualConditions.ChangeDate = ChartTable.ChangeDate
	|WHERE
	|	ChartTable.Date >= BEGINOFPERIOD(ActualConditions.Date,MONTH)
	|GROUP BY
	|	ActualConditions.Ref,
	|	ChartTable.FixedAsset
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChartTable.Ref				AS Ref,
	|	ChartTable.Date					AS Date,
	|	ChartTable.FixedAsset		AS FixedAsset,
	|	ChartTable.RentalService		AS RentalService,
	|	ChartTable.RentalServiceVAT	AS RentalServiceVAT
	|INTO DocumentDataTableServicePaymentSchedule
	|FROM
	|	RentalDocuments AS DocumentData
	|		INNER JOIN Document.ProvideAssetsToLeasee2_4.ServicePaymentSchedule AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref
	|			AND DocumentData.FixedAsset = ChartTable.FixedAsset
	|
	|UNION ALL
	|
	|SELECT
	|	ChartTable.Ref				AS Ref,
	|	ChartTable.Date					AS Date,
	|	ChartTable.FixedAsset		AS FixedAsset,
	|	ChartTable.RentalService		AS RentalService,
	|	ChartTable.RentalServiceVAT	AS RentalServiceVAT
	|FROM
	|	RentalDocuments AS DocumentData
	|		INNER JOIN Document.ChangeRentalTerms.ServicePaymentSchedule AS ChartTable
	|		ON DocumentData.Ref = ChartTable.Ref
	|			AND DocumentData.FixedAsset = ChartTable.FixedAsset
	|WHERE
	|	ChartTable.Date >= BEGINOFPERIOD(DocumentData.Date, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.Department AS Department,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|	OtherExpenses.ExpenseItem AS ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	SUM(OtherExpenses.Sum) AS Sum,
	|	SUM(OtherExpenses.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(OtherExpenses.SumMan) AS SumMan,
	|
	|	SUM(OtherExpenses.SumCompl) AS SumCompl
	|
	|INTO RentalTransferCosts
	|
	|FROM
	|	(SELECT
	|		OtherExpenses.Organization AS Organization,
	|		OtherExpenses.Department AS Department,
	|		OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|		OtherExpenses.ExpenseItem AS ExpenseItem,
	|		OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|
	|		OtherExpenses.SumBalance AS Sum,
	|		OtherExpenses.AmountExcludingVATBalance AS AmountExcludingVAT,
	|		OtherExpenses.SumManBalance AS SumMan,
	|
	|		OtherExpenses.SumComplBalance AS SumCompl
	|	FROM
	|		AccumulationRegister.OtherExpenses.Balance(
	|			&BeginningOfNextPeriod,
	|			Organization IN (&CompanyArray)
	|				AND DimensionOfExpenses IN (
	|					SELECT
	|						RentalDocuments.FixedAsset
	|					FROM
	|						RentalDocuments AS RentalDocuments)
	|		) AS OtherExpenses
	|
	|	UNION ALL
	|
	|	SELECT
	|		OtherExpenses.Organization AS Organization,
	|		OtherExpenses.Department AS Department,
	|		OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|		OtherExpenses.ExpenseItem AS ExpenseItem,
	|		OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|
	|		CASE
	|			WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN OtherExpenses.Sum
	|			ELSE -OtherExpenses.Sum
	|		END AS Sum,
	|
	|		CASE
	|			WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN OtherExpenses.AmountExcludingVAT
	|			ELSE -OtherExpenses.AmountExcludingVAT
	|		END AS AmountExcludingVAT,
	|
	|		CASE
	|			WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN OtherExpenses.SumMan
	|			ELSE -OtherExpenses.SumMan
	|		END AS SumMan,
	|
	|		CASE
	|			WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN OtherExpenses.SumCompl
	|			ELSE -OtherExpenses.SumCompl
	|		END AS SumCompl
	|
	|	FROM
	|		AccumulationRegister.OtherExpenses AS OtherExpenses
	|	WHERE
	|		OtherExpenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND OtherExpenses.Organization IN (&CompanyArray)
	|		AND OtherExpenses.SourceKind = VALUE(Enum.MovementSourcesKinds.CalculateRentalInvestmentCost)
	|		AND OtherExpenses.DimensionOfExpenses IN (
	|				SELECT
	|					RentalDocuments.FixedAsset
	|				FROM
	|					RentalDocuments AS RentalDocuments)
	|
	|		) AS OtherExpenses
	|
	|GROUP BY
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses
	|
	|INDEX BY
	|	DimensionOfExpenses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Expenses.DimensionOfExpenses AS FixedAsset,
	|	SUM(Expenses.SumMan)   AS ManSExpenses,
	|	SUM(Expenses.SumCompl)  AS LocalExpenses
	|INTO ExpenseAmount
	|FROM
	|	RentalTransferCosts AS Expenses
	|GROUP BY
	|	Expenses.DimensionOfExpenses
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvestmentInRent.Ref AS Ref,
	|	InvestmentInRent.FixedAsset AS FixedAsset,
	|	SUM(InvestmentInRent.RentalPayments) AS RentalPayments,
	|	SUM(InvestmentInRent.InterestDiscount) AS InterestDiscount,
	|	SUM(InvestmentInRent.NonGuaranteedResidualValueManag) AS NonGuaranteedResidualValueManag,
	|	SUM(InvestmentInRent.NonGuaranteedResidualValueLocal) AS NonGuaranteedResidualValueLocal,
	|	SUM(InvestmentInRent.NRIMan) AS NRIMan,
	|	SUM(InvestmentInRent.NRILocal) AS NRILocal
	|INTO BalanceOfInvestmentInLeases
	|FROM
	|	(SELECT
	|		RentalDocuments.Ref AS Ref,
	|		InvestmentInRent.FixedAsset AS FixedAsset,
	|		InvestmentInRent.RentalPaymentsBalance AS RentalPayments,
	|		-InvestmentInRent.InterestDiscountBalance AS InterestDiscount,
	|		InvestmentInRent.NonGuaranteedResidualValueManagBalance AS NonGuaranteedResidualValueManag,
	|		InvestmentInRent.NonGuaranteedResidualValueLocalBalance AS NonGuaranteedResidualValueLocal,
	|		InvestmentInRent.RentalPaymentsManagBalance + InvestmentInRent.InterestDiscountManBalance AS NRIMan,
	|		InvestmentInRent.RentalPaymentsLocalBalance + InvestmentInRent.InterestDiscountLocalBalance AS NRILocal
	|	FROM
	|		AccumulationRegister.InvestmentInRent.Balance(
	|				&BeginningOfBorderPeriod,
	|				(Organization, FixedAsset) IN
	|					(SELECT
	|						T.Organization,
	|						T.FixedAsset
	|					FROM
	|						RentalDocuments AS T)) AS InvestmentInRent
	|			
	|			INNER JOIN RentalDocuments AS RentalDocuments
	|			ON InvestmentInRent.Organization = RentalDocuments.Organization
	|				AND InvestmentInRent.FixedAsset = RentalDocuments.FixedAsset
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RentalDocuments.Ref AS Ref,
	|		InvestmentInRent.FixedAsset,
	|		CASE
	|			WHEN InvestmentInRent.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -InvestmentInRent.RentalPayments
	|			ELSE InvestmentInRent.RentalPayments
	|		END,
	|		CASE
	|			WHEN InvestmentInRent.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -InvestmentInRent.InterestDiscount
	|			ELSE InvestmentInRent.InterestDiscount
	|		END,
	|		CASE
	|			WHEN InvestmentInRent.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -InvestmentInRent.NonGuaranteedResidualValueManag
	|			ELSE InvestmentInRent.NonGuaranteedResidualValueManag
	|		END,
	|		CASE
	|			WHEN InvestmentInRent.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -InvestmentInRent.NonGuaranteedResidualValueLocal
	|			ELSE InvestmentInRent.NonGuaranteedResidualValueLocal
	|		END,
	|		CASE
	|			WHEN InvestmentInRent.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -InvestmentInRent.RentalPaymentsManag
	|			ELSE InvestmentInRent.RentalPaymentsManag
	|		END + CASE
	|			WHEN InvestmentInRent.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN InvestmentInRent.InterestDiscountMan
	|			ELSE -InvestmentInRent.InterestDiscountMan
	|		END,
	|		CASE
	|			WHEN InvestmentInRent.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -InvestmentInRent.RentalPaymentsLocal
	|			ELSE InvestmentInRent.RentalPaymentsLocal
	|		END + CASE
	|			WHEN InvestmentInRent.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN InvestmentInRent.InterestDiscountLocal
	|			ELSE -InvestmentInRent.InterestDiscountLocal
	|		END
	|	FROM
	|		AccumulationRegister.InvestmentInRent AS InvestmentInRent
	|			INNER JOIN RentalDocuments AS RentalDocuments
	|			ON InvestmentInRent.Organization = RentalDocuments.Organization
	|				AND InvestmentInRent.FixedAsset = RentalDocuments.FixedAsset
	|				AND InvestmentInRent.Recorder <> RentalDocuments.Ref
	|				AND (InvestmentInRent.Period >= &BeginOfPeriod)
	|				AND InvestmentInRent.Period < RentalDocuments.Date) AS InvestmentInRent
	|
	|GROUP BY
	|	InvestmentInRent.FixedAsset,
	|	InvestmentInRent.Ref
	|
	|INDEX BY
	|	FixedAsset,
	|	Ref
	|";
	QueryTexts.Add(QueryText);

#EndRegion

#Region DataFA

	QueryText = "
	|SELECT
	|	RentalDocuments.Ref                    AS Ref,
	|	RentalDocuments.Date                      AS Date,
	|	RentalDocuments.Organization               AS Organization,
	|	RentalDocuments.Department             AS Department,
	|	RentalDocuments.Contract                   AS Contract,
	|	RentalDocuments.ARAPCurrency      AS ARAPCurrency,
	|	RentalDocuments.BusinessOperation     AS BusinessOperation,
	|
	|	RentalDocuments.ExpenseItemAccounting          AS ExpenseItem,
	|	RentalDocuments.ExpensesDimensionAccounting       AS DimensionOfExpenses,
	|	RentalDocuments.IncomeItem             AS IncomeItem,
	|	RentalDocuments.DimensionOfRevenue          AS DimensionOfRevenue,
	|
	|	RentalDocuments.LineNumber               AS LineNumber,
	|	RentalDocuments.RowID       AS RowID,
	|	RentalDocuments.FixedAsset          AS FixedAsset,
	|	PRESENTATION(RentalDocuments.FixedAsset) AS FixedAssetPresentation,
	|	RentalDocuments.RentalEndDate       AS RentalEndDate,
	|	RentalDocuments.FairValueLocal AS FairValueLocal,
	|	RentalDocuments.FairValueManag  AS FairValueManag,
	|	RentalDocuments.NonGuaranteedResidualValueLocal                  AS NonGuaranteedResidualValueLocal,
	|	RentalDocuments.NonGuaranteedResidualValueManag                   AS NonGuaranteedResidualValueManag,
	|	RentalDocuments.RentalPayments           AS RentalPayments,
	|	0                                         AS ChangeInLeasePayments,
	|	RentalDocuments.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually,
	|
	|	ExpenseAmount.LocalExpenses                 AS LocalExpenses,
	|	ExpenseAmount.ManSExpenses                  AS ManSExpenses,
	|	CASE
	|		WHEN RentalDocuments.FairValueLocal > 0 THEN
	|			RentalDocuments.FairValueLocal - RentalDocuments.AdvancePaymentsLocal
	|		ELSE
	|			ExpenseAmount.LocalExpenses - RentalDocuments.AdvancePaymentsLocal
	|	END AS PresentValueLocal
	|INTO DataFA
	|FROM
	|	RentalDocuments AS RentalDocuments
	|		INNER JOIN ExpenseAmount AS ExpenseAmount
	|		ON ExpenseAmount.FixedAsset = RentalDocuments.FixedAsset
	|WHERE
	|	RentalDocuments.BusinessOperation = VALUE(Enum.BusinessTransactions.ProvideAssetsToLeasee)
	|
	|UNION ALL
	|
	|SELECT
	|	RentalDocuments.Ref                    AS Ref,
	|	RentalDocuments.Date                      AS Date,
	|	RentalDocuments.Organization               AS Organization,
	|	RentalDocuments.Department             AS Department,
	|	RentalDocuments.Contract                   AS Contract,
	|	RentalDocuments.ARAPCurrency      AS ARAPCurrency,
	|	RentalDocuments.BusinessOperation     AS BusinessOperation,
	|
	|	RentalDocuments.ExpenseItemAccounting          AS ExpenseItem,
	|	RentalDocuments.ExpensesDimensionAccounting       AS DimensionOfExpenses,
	|	RentalDocuments.IncomeItem             AS IncomeItem,
	|	RentalDocuments.DimensionOfRevenue          AS DimensionOfRevenue,
	|
	|	RentalDocuments.LineNumber               AS LineNumber,
	|	RentalDocuments.RowID       AS RowID,
	|	RentalDocuments.FixedAsset          AS FixedAsset,
	|	PRESENTATION(RentalDocuments.FixedAsset) AS FixedAssetPresentation,
	|	RentalDocuments.RentalEndDate       AS RentalEndDate,
	|	RentalDocuments.FairValueLocal AS FairValueLocal,
	|	RentalDocuments.FairValueManag  AS FairValueManag,
	|	RentalDocuments.NonGuaranteedResidualValueLocal - BalanceOfInvestmentInLeases.NonGuaranteedResidualValueLocal AS NonGuaranteedResidualValueLocal,
	|	RentalDocuments.NonGuaranteedResidualValueManag - BalanceOfInvestmentInLeases.NonGuaranteedResidualValueManag AS NonGuaranteedResidualValueManag,
	|	RentalDocuments.RentalPayments           AS RentalPayments,
	|	RentalDocuments.RentalPayments
	|		- ISNULL(RentalPaymentsBeforeChange.RentalPayments, 0) AS ChangeInLeasePayments,
	|	RentalDocuments.TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually,
	|
	|	ExpenseAmount.LocalExpenses                 AS LocalExpenses,
	|	ExpenseAmount.ManSExpenses                  AS ManSExpenses,
	|	(ISNULL(RentalPaymentsBeforeChange.RentalPayments, 0)
	|		- ISNULL(InterestBeforeChange.InterestDiscount, 0))
	|			* TTCourses.LocalConversionRatio
	|		+ ISNULL(ExpenseAmount.LocalExpenses, 0) AS PresentValueLocal
	|FROM
	|	RentalDocuments AS RentalDocuments
	|		INNER JOIN BalanceOfInvestmentInLeases AS BalanceOfInvestmentInLeases
	|		ON BalanceOfInvestmentInLeases.FixedAsset = RentalDocuments.FixedAsset
	|		LEFT JOIN RentalPaymentsBeforeChange AS RentalPaymentsBeforeChange
	|		ON RentalPaymentsBeforeChange.FixedAsset = RentalDocuments.FixedAsset
	|			AND RentalPaymentsBeforeChange.Ref = RentalDocuments.Ref
	|		LEFT JOIN InterestBeforeChange AS InterestBeforeChange
	|		ON InterestBeforeChange.FixedAsset = RentalDocuments.FixedAsset
	|			AND InterestBeforeChange.Ref = RentalDocuments.Ref
	|		LEFT JOIN ExpenseAmount AS ExpenseAmount
	|		ON ExpenseAmount.FixedAsset = RentalDocuments.FixedAsset
	|		INNER JOIN TTCurrencyConversionFactors AS TTCourses
	|			ON RentalDocuments.ARAPCurrency = TTCourses.ARAPCurrency
	|			 AND RentalDocuments.Organization = TTCourses.Organization
	|			 AND RentalDocuments.Date = TTCourses.Date
	|WHERE
	|	RentalDocuments.BusinessOperation = VALUE(Enum.BusinessTransactions.ChangeRentalTerms)
	|";
	QueryTexts.Add(QueryText, "DataFA");

#EndRegion
	
	QueryText = StrConcat(QueryTexts.UnloadValues(), Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = OperationParametersList.TempTablesManager;
	Query.SetParameter("CompanyArray", OperationParametersList.CompanyArray);
	Query.SetParameter("BeginOfPeriod", OperationParametersList.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", OperationParametersList.EndOfPeriod);
	Query.SetParameter("BeginningOfBorderPeriod", New Boundary(OperationParametersList.BeginOfPeriod, BoundaryType.Excluding));
	Query.SetParameter("BeginningOfNextPeriod", OperationParametersList.EndOfPeriod + 1);
	Query.SetParameter("EndOfPeriod", OperationParametersList.EndOfPeriod);
	Query.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	Query.SetParameter("CurrencyOfMan", SettingsValueCached.ManagementAccountingCurrency());
	
	If OperationParametersList.DocumentsList <> Undefined Then
		Query.SetParameter("DocumentsList", OperationParametersList.DocumentsList);
		Query.SetParameter("WithoutSelectionOfDocuments", False);
	Else
		Query.SetParameter("DocumentsList", New Array);
		Query.SetParameter("WithoutSelectionOfDocuments", True);
	EndIf;
	
	Query.Execute();
	
	LeasedAssetAccounting.CalculateInterestRatesOfProfitableRentInBatches(OperationParametersList.TempTablesManager);
	
	TMCommonUse.DestroyTemporaryTables(OperationParametersList.TempTablesManager,,
		"RentalDocuments,TableScheduleOfAccrualOfInterest,RentalTransferCosts,DataFA,ExpenseAmount,InterestBeforeChange")
	
EndProcedure

Procedure SelectDocumentsAndRecordRegisteredRecords(OperationParametersList)
	
	QueryText = 
	"SELECT DISTINCT
	|	RentalDocuments.Ref      AS Ref,
	|	RentalDocuments.Date        AS Period,
	|	RentalDocuments.Organization AS Organization
	|FROM
	|	RentalDocuments AS RentalDocuments
	|
	|ORDER BY
	|	Period,
	|	Organization,
	|	Ref";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = OperationParametersList.TempTablesManager;
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(OperationParametersList.TempTablesManager);
	
	While Selection.Next() Do
	
		BeginTransaction();
		Try
			
			TablesOfConduct = PrepareDocumentMovementTables(OperationParametersList.TempTablesManager, Selection);
			
			DocumentObject = DocumentsPosting.DocumentEmulation(Selection.Ref, Selection.Period);
			
			SetFlagForOperation(DocumentObject);
		
			NonCurrentAssetsInternal.WriteMotionTables(
				TablesOfConduct, 
				DocumentObject, 
				OperationParametersList.TempTablesManager,
				False, 
				OperationName(), 
				Enums.MovementSourcesKinds.CalculateRentalInvestmentCost,
				OperationParametersList.BeginOfPeriod);
		
			NonCurrentAssetsInternal.UpdateRegisteredRecordsOfAssetsLiabilities(Selection.Ref);
			
			If OperationParametersList.GenerateJobs Then
				DocumentsPosting.CreateTasksForDeferredRegisteredRecords(DocumentObject, OperationParametersList.TempTablesManager);
			EndIf;
			
			If OperationParametersList.ReturnDocumentsToReflection Then
				NonCurrentAssetsInternal.ReturnDocumentsToReflection(
					Selection.Ref, Selection.Organization, Selection.Period, TablesOfConduct);
			EndIf;
			
			OperationParametersList.DataVolume = OperationParametersList.DataVolume + 1;
			
			TMCommonUse.DestroyTemporaryTables(OperationParametersList.TempTablesManager,, TTUsed);
		
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = NStr("vi = 'Không thể tạo bản ghi kết chuyển theo chứng từ %1, theo nguyên nhân:
                                |%2';
                                |ru = 'Не удалось сформировать движения по документу %1, по причине:
                                |%2';
                                |en = 'Cannot generate register records for document %1. Reason:
                                |%2'; fa = 'Cannot generate register records for document %1. Reason:
                                |%2';
                                |it = 'Non è stato possibile creare i movimenti per il documento %1 a causa di:
                                |%2';
                                |pl = 'Nie udało ruchów według doukumentu %1, z powodu:
                                |%2';
                                |tr = 'Belge %1 üzerinde hareket oluşturmak mümkün değildi, sebep:
                                |%2'");
			
			ErrorText = StrTemplate(ErrorText, 
				String(Selection.Ref),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			Raise ErrorText;
			
		EndTry;
		
	EndDo;
	
EndProcedure

Function PrepareDocumentMovementTables(TempTablesManager, Selection)
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);

	ObjectManager = Common.ObjectManagerByRef(Selection.Ref);
	TablesOfConduct = ObjectManager.TablesOfRegisteredRecordsWhenCalculatingCostOfInvestmentInLease(Selection.Ref, TempTablesManager);
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
	
	Return TablesOfConduct;
	
EndFunction

// Parameters of the execution of operation "Calculation of the cost of the investment in the lease".
// 
// Parameters:
//  CalculationParameters - Structure - Parameters for calculating the month closing operation.
// 
// Returns:
//  Structure - Contains Parameters:
// 		* CompanyArray - Array of CatalogRef.Companies - Organizations for which the operation is performed.
// 		* BeginOfPeriod - Date - The beginning of the period in which the operation is performed.
// 		* EndOfPeriod - Date - The end of the period in which the operation is performed.
// 		* ReturnDocumentsToReflection - Boolean - True, if the documents need to be returned to reflection in Local and international accounting.
// 		* DocumentsList - Array, Undefined - Documents to perform the operation for.
//		* DataVolume - Number - The number of processed data.
//		* TempTablesManager - TempTablesManager - temporary table manager.
Function OperationParametersList(CalculationParameters = Undefined)
	
	OperationParametersList = New Structure;
	OperationParametersList.Insert("CompanyArray", New Array);
	OperationParametersList.Insert("BeginOfPeriod", '000101010000');
	OperationParametersList.Insert("EndOfPeriod", '000101010000');
	OperationParametersList.Insert("ReturnDocumentsToReflection", True);
	OperationParametersList.Insert("GenerateJobs", True);
	OperationParametersList.Insert("DocumentsList", Undefined);
	OperationParametersList.Insert("DataVolume", 0);
	OperationParametersList.Insert("TempTablesManager", New TempTablesManager);
	
	If CalculationParameters <> Undefined Then
		OperationParametersList.CompanyArray = CalculationParameters.CompanyArray;
		OperationParametersList.BeginOfPeriod = BegOfMonth(CalculationParameters.Period);
		OperationParametersList.EndOfPeriod = EndOfMonth(CalculationParameters.Period);
	EndIf;
	
	Return OperationParametersList;
	
EndFunction

Procedure DefineChangesForGeneratingTasks(TempTablesManager)
	
	ListOfRequests = New Array;
	
	If TempTablesManager.Tables.Find("RegisteredRecordsOtherExpensesUpdate") <> Undefined Then
		
		QueryText =
		"SELECT DISTINCT
		|	BEGINOFPERIOD(FixedAssetsDocuments.Date, MONTH) AS Period,
		|	Table.Organization                      AS Organization,
		|	FixedAssetsDocuments.Ref                     AS Document
		|INTO OtherExpenses_TasksForCalculatingCostOfInvestmentInLeaseUpdate
		|FROM
		|	RegisteredRecordsOtherExpensesUpdate AS Table
		|	INNER JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments 
		|		ON FixedAssetsDocuments.Date >= Table.BegOfMonth
		|			AND FixedAssetsDocuments.FixedAsset = Table.DimensionOfExpenses
		|			AND FixedAssetsDocuments.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.ProvideAssetsToLeasee),
		|				VALUE(Enum.BusinessTransactions.ChangeRentalTerms))
		|";
	
		ListOfRequests.Add(QueryText);
		
	EndIf;

	If ListOfRequests.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = StrConcat(ListOfRequests,  Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure SetFlagForOperation(DocumentObject) Export
	
	DocumentObject.AdditionalProperties.Insert(OperationName(), True);
	
EndProcedure

Function OperationName()
	Return "CalculateRentalInvestmentCost";
EndFunction

#EndRegion
