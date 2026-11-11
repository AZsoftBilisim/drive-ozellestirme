
#Region Public

#Region CreatingTasksForEndOfMonth

// Complements the request text of the mechanism for generating monthly closing tasks.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
Procedure AddTextOfRequestForTasksByEndOfMonth(Query, QueryText, TempTablesQueryText, TemporaryTableNames) Export
	
	If Not GetFunctionalOption("UseFinancialAccounting") Then
		Return;
	EndIf;
	
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

#Region HandlersForMonthClosingStages

#Region DocumentPostingInFinancialAccounting

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
// 	CurrentParent - String - group ID.
Procedure AddStage_DocumentPostingInFinancialAccounting(StepsTable,CurrentParent) Export

	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.DocumentPostingInFinancialAccounting,
		False, False, True);
	
	NewRow.MultilingualName = "vi = 'Phản ánh các chứng từ trong kế toán quốc tế';
								|ru = 'Отражение документов в международном учете';
								|en = 'Record documents in financial accounting';
								|it = 'Visualizzazione dei documenti in contabilità internazionale';
								|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
								|tr = 'Finansal muhasebede belge kaydı'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Hiển thị';
								|ru = 'Отразить';
								|en = 'Record'; fa = 'ثبت';
								|it = 'Riportare';
								|pl = 'Record';
								|tr = 'Kaydet'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"FinancialAccountingOfMonthEndClosing.Use_ReflectionOfDocumentsInInternationalAccounting");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"FinancialAccountingOfMonthEndClosing.Execute_ReflectionOfDocumentsInInternationalAccounting");
	NewRow.ActionMoreDetails  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.DataProcessors.DocumentPostingInFinancialAccounting.Forms.Form.FullName());
	
EndProcedure

// Performs a check of the need to complete the closing stage of the month.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Use_ReflectionOfDocumentsInInternationalAccounting(HandlerParameters) Export
	
	VerifyUseOfInternationalAccounting(HandlerParameters);
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("FinancialAccountingEntriesBasedOnOperationalAccountingData")
	 And Not GetFunctionalOption("GenerateFinancialAccountingEntriesByLocalAccountingData") Then
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Lập bút toán theo dữ liệu kế toán hoạt động và pháp quy không được sử dụng.';
				|ru = 'Формирование проводок по данным оперативного и регламентированного учета не используется.';
				|en = 'Posting generation for real-time and local accounting data is not used.'; fa = 'Posting generation for real-time and local accounting data is not used.';
				|it = 'La creazione di movimenti sui dati della contabilità operativa e regolamentata non è utilizzata.';
				|pl = 'Tworzenie księgowań wg danych ewidencji operacyjnej i regulaminowej nie jest używane.';
				|tr = 'Operasyonel ve yerel muhasebe verilerine göre girişlerin oluşturulması kullanılmaz.'", Common.DefaultLanguageCode()));
	EndIf;
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text = 
	"SELECT
	|	FinancialAccountingChartsOfAccountsForCompanies.Organization AS Ref
	|INTO TTOrganizations
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(
	|			&EndOfPeriod,
	|			Organization IN (&CompanyArray)) AS FinancialAccountingChartsOfAccountsForCompanies";
	
	Query.Execute();
	
	If MonthEndTransactionsServer.TemporaryTableSize(Query, "TTOrganizations", HandlerParameters) = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có doanh nghiệp cần phản ánh kế toán quốc tế.';
				|ru = 'Нет организаций с необходимостью отражения международного учета.';
				|en = 'There are no companies that require recording in financial accounting.'; fa = 'There are no companies that require recording in financial accounting.';
				|it = 'Non ci sono organizzazioni che devono obbligatoriamente riportare nella contabilità internazionale.';
				|pl = 'Brak organizacji z koniecznością odzwierciedlenia ewidencji międzynarodowej.';
				|tr = 'Uluslararası muhasebeyi yansıtması gereken herhangi bir iş yeri yoktur.'", Common.DefaultLanguageCode()));
		Return;
		
	EndIf;
	
	Query.Text = 
	"SELECT
	|	DocumentReflection.DateRecord AS DateRecord,
	|	DocumentReflection.Recorder AS Recorder,
	|	DocumentReflection.Status AS Status
	|INTO DocumentReflection
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentReflection
	|	INNER JOIN TTOrganizations AS Companies
	|		ON DocumentReflection.Organization = Companies.Ref
	|WHERE
	|	DocumentReflection.DateRecord <= &EndOfPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(DocumentReflection.DateRecord) AS StartDate,
	|	COUNT(DISTINCT DocumentReflection.Recorder) AS Count
	|FROM
	|	DocumentReflection AS DocumentReflection
	|WHERE
	|	DocumentReflection.Status IN
	|		(VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting),
	|		 VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting))
	|HAVING
	|	COUNT(DocumentReflection.Recorder) > 0
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(DocumentReflection.DateRecord) AS StartDate,
	|	COUNT(DISTINCT DocumentReflection.Recorder) AS Count
	|FROM
	|	DocumentReflection AS DocumentReflection
	|WHERE
	|	DocumentReflection.Status IN
	|		(VALUE(Enum.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined),
	|		 VALUE(Enum.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken))
	|HAVING
	|	COUNT(DocumentReflection.Recorder) > 0";
	
	ResultsArray = Query.ExecuteBatch();
	
	ThereArePendingReflections = Not ResultsArray[1].IsEmpty();
	ThereAreNotReflectedInAccounting = Not ResultsArray[2].IsEmpty();
	
	If ThereArePendingReflections Then
		
		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đang chờ phản ánh vào kế toán: %1 chứng từ';
					|ru = 'Ожидает отражения в учете документов: %1';
					|en = 'Documents awaiting posting in accounting: %1'; fa = 'Documents awaiting posting in accounting: %1';
					|it = 'Si aspetta una visualizzazione nella contabilizzazione dei documenti: %1';
					|pl = 'Oczekuje odzwierciedlenia w ewidencji dokumentów: %1';
					|tr = 'Belge hesabında yansıtılmayı bekliyor: %1'", Common.DefaultLanguageCode()),
				TrimAll(ResultsArray[1].Unload()[0].Count)));
		
	EndIf;
	
	If ThereAreNotReflectedInAccounting Then
		
		MonthEndTransactionsServer.SetStateExecutedWithErrors(
			HandlerParameters,
			StringFunctionsClientServer.SubstituteParametersToString(
				?(GetFunctionalOption("SettingOfPostingByAccountingObjects"),
					NStr("vi = 'Không phản ánh vào kế toán: %1 chứng từ';
						|ru = 'Не отражено в учете документов: %1';
						|en = 'Not recorded in document accounting: %1'; fa = 'Not recorded in document accounting: %1';
						|it = 'Non registrato nella contabilità dei documenti: %1';
						|pl = 'Nie wyświetlono w ewidencji dokumentów: %1';
						|tr = 'Belge hesabında yansıtılmadı: %1'", Common.DefaultLanguageCode()),
					NStr("vi = 'Không phản ánh vào kế toán các chứng từ do không có quy tắc phản ánh: %1';
						|ru = 'Не отражено в учете документов из-за отсутствия правил отражения: %1';
						|en = 'Not recorded in document accounting since there are no recording rules: %1'; fa = 'Not recorded in document accounting since there are no recording rules: %1';
						|it = 'Non visualizzato nella contabilizzazione dei documenti a causa dell''assenza di regole di visualizzazione: %1';
						|pl = 'Nie odzwierciedlono w ewidencji dokumentów z powodu braku reguł odzwierciedlenia: %1';
						|tr = 'Yansıtma kuralı olmadığı için belge hesabında yansıtılmadı: %1'", Common.DefaultLanguageCode())),
				TrimAll(ResultsArray[2].Unload()[0].Count)));
		
	EndIf;
	
EndProcedure

// Performs the closing stage of the month.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Execute_ReflectionOfDocumentsInInternationalAccounting(HandlerParameters) Export
	
	ReflectionParameters = FinancialAccountingPostingServer.ReflectionParametersInInternationalAccounting();
	ReflectionParameters.Companies = HandlerParameters.CalculationParameters.CompanyArray;
	ReflectionParameters.EndDate = EndOfMonth(HandlerParameters.CalculationParameters.RegistrationPeriod);
	
	FinancialAccountingPostingServer.RecordInInternationalAccounting(ReflectionParameters);
	
EndProcedure

#EndRegion

#Region ReclassificationOfLongTermAssetsAndLiabilities

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
// 	CurrentParent - String - group ID.
Procedure AddStage_ReclassificationOfLongTermAssetsAndLiabilities(StepsTable, CurrentParent) Export

	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.ReclassificationOfLongTermAssetsAndLiabilitiesInt,
		False, False, True);
	
	NewRow.MultilingualName = "vi = 'Phân loại lại tài sản dài hạn và nợ phải trả (kế toán quốc tế)';
								|ru = 'Реклассификация долгосрочных активов и обязательств (международный учет)';
								|en = 'Reclassification of long-term assets and liabilities (financial accounting)';
								|it = 'Reclassification of long-term assets and liabilities (financial accounting)';
								|pl = 'Reclassification of long-term assets and liabilities (financial accounting)';
								|tr = 'Uzun vadeli varlıkların ve yükümlülüklerin yeniden sınıflandırılması (uluslararası muhasebe)'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Thực hiện';
								|ru = 'Выполнить';
								|en = 'Run'; fa = 'اجرا';
								|it = 'Eseguire';
								|pl = 'Run';
								|tr = 'Yürüt'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"FinancialAccountingOfMonthEndClosing.Use_ReclassificationOfNonCurrentAssetsLiabilities");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"FinancialAccountingOfMonthEndClosing.Perform_ReclassificationOfLongTermAssetsLiabilities");
	NewRow.ActionMoreDetails = ActionDescription_OpenListOfDocumentsIntRoutineOperation();
	NewRow.TypesOfRoutineOperations.Add(Enums.PeriodEndTransactionsTypesFinancialAccounting.ReclassificationOfLongTermAssetsAndLiabilities);
	
EndProcedure

// Performs a check of the need to complete the closing stage of the month.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Use_ReclassificationOfNonCurrentAssetsLiabilities(HandlerParameters) Export
	
	VerifyUseOfInternationalAccounting(HandlerParameters);
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("SettingOfPostingByAccountingObjects") Then
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không sử dụng lập bút toán theo đối tượng kế toán.';
				|ru = 'Формирование проводок по объектам учета не используется.';
				|en = 'Entry generation by accounting objects is not used.'; fa = 'Entry generation by accounting objects is not used.';
				|it = 'Non è utilizzata la creazione movimenti per oggetti di contabilità.';
				|pl = 'Tworzenie księgowań według obiektów ewidencji nie jest używane.';
				|tr = 'Muhasebe nesnesine ilişkin girişlerin oluşturulması kullanılmıyor.'",
			Common.DefaultLanguageCode()));
	Else
		CheckNeedForReflectionInInternationalAccounting(HandlerParameters, True);
		
		Query = New Query;
		MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
		
		Query.Text = "
		|SELECT DISTINCT
		|	Companies.Ref AS Organization
		|FROM
		|	TTOrganizations AS Companies
		|";
		
		Result = Query.Execute();
		
		If Result.IsEmpty() Then
			MonthEndTransactionsServer.SetStateDisabled(
				HandlerParameters,
				NStr("vi = 'Không hỗ trợ phân chia tài sản và nợ phải trả thành ngắn hạn/dài hạn.';
					|ru = 'Деление активов и обязательств на краткосрочные/долгосрочные не используется.';
					|en = 'Division of assets and liabilities into short-term or long-term ones is not used.'; fa = 'Division of assets and liabilities into short-term or long-term ones is not used.';
					|it = 'Non è utilizzata la divisione di attivi e obbligazioni di breve e lungo termine.';
					|pl = 'Podział aktywów i zobowiązań na krótkoterminowe/długoterminowe nie jest używany.';
					|tr = 'Varlık ve yükümlülüklerin kısa vadeli/uzun vadeli olarak bölünmesi kullanılmıyor.'",
				Common.DefaultLanguageCode()));
		Else
			Companies = Result.Unload().UnloadColumn("Organization");
			MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, Companies.Count());
		EndIf;
	EndIf;
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	If MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, False, "TTOrganizations") Then
		Return;
	EndIf;
	
	ReclassificationOrganizations = FinancialAccountingByFinancialRegisterData.OrganizationsReclassifyingNonCurrentAssetsLiabilities(
		Companies, HandlerParameters.CalculationParameters.RegistrationPeriod);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query, "TTOrganizations");
	
	Query.Text = "
	|SELECT
	|	Companies.Ref
	|INTO TTOrganizations
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.Ref IN (&ReclassificationOrganizations)
	|";
	
	Query.SetParameter("ReclassificationOrganizations", ReclassificationOrganizations);
	Query.Execute();
	
	PresenceOfOperationIsMandatory = ReclassificationOrganizations.Count() > 0;
	
	CheckAvailabilityOfDocumentRoutineOperationInternationalAccounting(HandlerParameters,,, PresenceOfOperationIsMandatory);
	
EndProcedure

// Performs the closing stage of the month.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Perform_ReclassificationOfLongTermAssetsLiabilities(HandlerParameters) Export
	
	CompleteTasksByEndOfMonth(HandlerParameters);
	
EndProcedure

#EndRegion

#Region ExchangeDifferenceCalculationInFunctionalCurrency

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
// 	CurrentParent - String - group ID.
//
Procedure AddStage_ExchangeDifferenceCalculationInFunctionalCurrency(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.ExchangeDifferenceCalculationInFunctionalCurrency,
		False, False, True);
	
	NewRow.MultilingualName = "vi = 'Tính toán chênh lệch tỷ giá hối đoái trong tiền tệ chức năng';
								|ru = 'Расчет курсовых разниц в функциональной валюте';
								|en = 'Exchange difference calculation in the functional currency';
								|it = 'Calcolo delle differenze di cambio nella valuta funzionale';
								|pl = 'Rozliczenie różnic w walucie funkcjonalnej';
								|tr = 'Fonksiyonel para birimi cinsinden kur farkı hesaplaması'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Tính toán';
								|ru = 'Рассчитать';
								|en = 'Calculate'; fa = 'محاسبه';
								|it = 'Calcolare';
								|pl = 'Calculate';
								|tr = 'Hesapla'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"FinancialAccountingOfMonthEndClosing.Use_CalculationOfExchangeDifferencesInFunctionalCurrency");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"FinancialAccountingOfMonthEndClosing.Perform_CalculationOfExchangeDifferencesInFunctionalCurrency");
	NewRow.ActionMoreDetails = ActionDescription_OpenListOfDocumentsIntRoutineOperation();
	NewRow.TypesOfRoutineOperations.Add(Enums.PeriodEndTransactionsTypesFinancialAccounting.ExchangeDifferenceCalculationFunctionalCurrency);
EndProcedure

// Performs a check of the need to complete the closing stage of the month.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Use_CalculationOfExchangeDifferencesInFunctionalCurrency(HandlerParameters) Export
	
	VerifyUseOfInternationalAccounting(HandlerParameters);
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	CheckNeedForReflectionInInternationalAccounting(HandlerParameters);
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	Query.Text = 
	"SELECT DISTINCT
	|	TTOrganizations.ChartOfAccounts AS ChartOfAccounts
	|FROM
	|	TTOrganizations AS TTOrganizations";
	SamplingByChartOfAccounts = Query.Execute().Select();
	
	TotalNotClosed = 0;
	While SamplingByChartOfAccounts.Next() Do
		NotClosedAccordingToChartOfAccounts = Documents.PeriodEndTransactionFinancialAccounting.UncoveredExchangeDifferences(
			SamplingByChartOfAccounts.ChartOfAccounts,
			HandlerParameters.CalculationParameters.CompanyArray,
			EndOfMonth(HandlerParameters.CalculationParameters.RegistrationPeriod),
			True);
		
		MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, NotClosedAccordingToChartOfAccounts);
		TotalNotClosed = TotalNotClosed + NotClosedAccordingToChartOfAccounts;
	EndDo;
	
	If TotalNotClosed <> 0 Then
		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters,
			NStr("vi = 'Có chênh lệch tỷ giá chưa đóng tháng để tính toán.';
				|ru = 'Есть незакрытые курсовые разницы для расчета.';
				|en = 'There are unclosed exchange differences for calculation.'; fa = 'There are unclosed exchange differences for calculation.';
				|it = 'Ci sono differenze di cambio non chiuse per la contabilità.';
				|pl = 'Są niezamknięte różnice kursowe do obliczania.';
				|tr = 'Hesaplar için kapatılmamış kur farkları var'", Common.DefaultLanguageCode()));
	Else
		CheckAvailabilityOfDocumentRoutineOperationInternationalAccounting(HandlerParameters);
	EndIf;
	
EndProcedure

// Performs the closing stage of the month.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Perform_CalculationOfExchangeDifferencesInFunctionalCurrency(HandlerParameters) Export
	
	GenerateDocumentRoutineOperationInt(HandlerParameters);
	
EndProcedure

#EndRegion

#Region ClosingOfGLAccountsOfIncomeAndExpensesFinancialAcconting

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
// 	CurrentParent - String - group ID.
Procedure AddStage_ClosingOfGLAccountsOfIncomeAndExpensesFinancialAcconting(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.ClosingOfGLAccountsOfIncomeAndExpensesFinancialAcconting,
		False, False, True);
	
	NewRow.MultilingualName = "vi = 'Đóng tài khoản kế toán thu nhập và chi phí';
								|ru = 'Закрытие счетов учета доходов и расходов';
								|en = 'Closing of ledger accounts of income and expenses';
								|it = 'Chiusura dei conti di ricavi e spese';
								|pl = 'Zamknięcie kont ewidencji przychodów i rozchodów';
								|tr = 'Gelir ve gider muhasebe hesapların kapatılması'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Thực hiện';
								|ru = 'Выполнить';
								|en = 'Run'; fa = 'اجرا';
								|it = 'Eseguire';
								|pl = 'Run';
								|tr = 'Yürüt'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"FinancialAccountingOfMonthEndClosing.Use_ClosingAccountsForIncomeAndExpensesInt");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"FinancialAccountingOfMonthEndClosing.Perform_ClosingOfAccountsForAccountingOfIncomeAndExpensesOfMU");
	NewRow.ActionMoreDetails = ActionDescription_OpenListOfDocumentsIntRoutineOperation();
	NewRow.TypesOfRoutineOperations.Add(Enums.PeriodEndTransactionsTypesFinancialAccounting.ClosingOfGLAccountsOfIncomeAndExpenses);
EndProcedure

// Performs a check of the need to complete the closing stage of the month.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Use_ClosingAccountsForIncomeAndExpensesInt(HandlerParameters) Export
	
	VerifyUseOfInternationalAccounting(HandlerParameters);
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	CheckNeedForReflectionInInternationalAccounting(HandlerParameters);
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	Query.Text = 
	"SELECT DISTINCT
	|	TTOrganizations.ChartOfAccounts AS ChartOfAccounts
	|FROM
	|	TTOrganizations AS TTOrganizations";
	SamplingByChartOfAccounts = Query.Execute().Select();
	
	TotalNotClosed = 0;
	While SamplingByChartOfAccounts.Next() Do
		NotClosedAccordingToChartOfAccounts = Documents.PeriodEndTransactionFinancialAccounting.ThereAreUnclosedIncomeExpenseAccounts(
			SamplingByChartOfAccounts.ChartOfAccounts,
			HandlerParameters.CalculationParameters.CompanyArray,
			EndOfMonth(HandlerParameters.CalculationParameters.RegistrationPeriod));
		MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, NotClosedAccordingToChartOfAccounts);
		TotalNotClosed = TotalNotClosed + NotClosedAccordingToChartOfAccounts;
	EndDo;
	
	If TotalNotClosed <> 0 Then
		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters,
			NStr("vi = 'Có tài khoannr kế toán chưa đóng.';
				|ru = 'Есть незакрытые счета учета.';
				|en = 'There are unclosed ledger accounts.'; fa = 'There are unclosed ledger accounts.';
				|it = 'Ci sono conti non chiusi per la contabilità.';
				|pl = 'Są niezamknięte konta księgowe.';
				|tr = 'Kapatılmamış defterikebir hesapları bulunuyor'", Common.DefaultLanguageCode()));
	Else
		CheckAvailabilityOfDocumentRoutineOperationInternationalAccounting(HandlerParameters,,, True);
	EndIf;
	
EndProcedure

// Performs the closing stage of the month.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Perform_ClosingOfAccountsForAccountingOfIncomeAndExpensesOfMU(HandlerParameters) Export
	
	GenerateDocumentRoutineOperationInt(HandlerParameters);
	
EndProcedure

#EndRegion

#Region ExchangeDifferenceCalculationInPresentationCurrency

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
// 	CurrentParent - String - group ID.
Procedure AddStage_ExchangeDifferenceCalculationInPresentationCurrency(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.ExchangeDifferenceCalculationInPresentationCurrency,
		False, False, True);
	
	NewRow.MultilingualName = "vi = 'Tính toán chênh lệch tỷ giá theo tiền tệ trình bày';
								|ru = 'Расчет курсовых разниц в валюте представления';
								|en = 'Exchange difference calculation in the presentation currency';
								|it = 'Calcolo delle differenze di cambio nella valuta di presentazione';
								|pl = 'Rozliczenie różnic kursowych w walucie prezentacji';
								|tr = 'Sunum para birimi cinsinden kur farklarının hesaplanması'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Tính toán';
								|ru = 'Рассчитать';
								|en = 'Calculate'; fa = 'محاسبه';
								|it = 'Calcolare';
								|pl = 'Calculate';
								|tr = 'Hesapla'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"FinancialAccountingOfMonthEndClosing.Use_CalculationOfExchangeDifferencesInPresentationCurrency");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"FinancialAccountingOfMonthEndClosing.Perform_CalculationOfExchangeDifferencesInCurrencyOfPresentation");
	NewRow.ActionMoreDetails = ActionDescription_OpenListOfDocumentsIntRoutineOperation();
	NewRow.TypesOfRoutineOperations.Add(Enums.PeriodEndTransactionsTypesFinancialAccounting.ExchangeDifferenceCalculationPresentationCurrency);
EndProcedure

// Performs a check of the need to complete the closing stage of the month.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Use_CalculationOfExchangeDifferencesInPresentationCurrency(HandlerParameters) Export
	
	If Not VerifyUseOfInternationalAccounting(HandlerParameters) Then
		Return;
	EndIf;
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	CheckNeedForReflectionInInternationalAccounting(HandlerParameters);
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	Query.Text = 
	"SELECT TOP 1
	|	TTOrganizations.ChartOfAccounts AS ChartOfAccounts
	|FROM
	|	TTOrganizations AS TTOrganizations
	|WHERE
	|	TTOrganizations.CurrencyFunctional <> TTOrganizations.ChartOfAccounts.PresentationCurrency
	|;
	|
	|////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTOrganizations.ChartOfAccounts AS ChartOfAccounts
	|FROM
	|	TTOrganizations AS TTOrganizations
	|";
	QueryResults = Query.ExecuteBatch();

	If QueryResults[0].IsEmpty() Then
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Tiền tệ chức năng trùng với tiền tệ trình bày.';
				|ru = 'Функциональная валюта совпадает с валютой представления.';
				|en = 'Functional currency matches the presentation currency.'; fa = 'Functional currency matches the presentation currency.';
				|it = 'La valuta funzionale coincide con la valuta di presentazione.';
				|pl = 'Waluta funkcjonalna jest zbieżna z walutą przedłożenia.';
				|tr = 'Fonksiyonel para birimi sunum para birimi ile eşleşiyor.'", Common.DefaultLanguageCode()));
		Return;
	EndIf;
	
	SamplingByChartOfAccounts = QueryResults[1].Select();
	
	TotalNotRecalculated = 0;
	While SamplingByChartOfAccounts.Next() Do
		
		NotRecalculatedAccordingToChartOfAccounts = Documents.PeriodEndTransactionFinancialAccounting.NotTranslatedIntoPresentationCurrency(
			SamplingByChartOfAccounts.ChartOfAccounts,
			HandlerParameters.CalculationParameters.CompanyArray,
			EndOfMonth(HandlerParameters.CalculationParameters.RegistrationPeriod),
			True);
		
		MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, TotalNotRecalculated);
		TotalNotRecalculated = TotalNotRecalculated + NotRecalculatedAccordingToChartOfAccounts;
	EndDo;
	
	If TotalNotRecalculated <> 0 Then
		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters,
			NStr("vi = 'Có chênh lệch tỷ giá chưa đóng tháng để tính toán.';
				|ru = 'Есть незакрытые курсовые разницы для расчета.';
				|en = 'There are unclosed exchange differences for calculation.'; fa = 'There are unclosed exchange differences for calculation.';
				|it = 'Ci sono differenze di cambio non chiuse per la contabilità.';
				|pl = 'Są niezamknięte różnice kursowe do obliczania.';
				|tr = 'Hesaplar için kapatılmamış kur farkları var'", Common.DefaultLanguageCode()));
	Else
		CheckAvailabilityOfDocumentRoutineOperationInternationalAccounting(HandlerParameters);
	EndIf;
	
EndProcedure

// Performs the closing stage of the month.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Perform_CalculationOfExchangeDifferencesInCurrencyOfPresentation(HandlerParameters) Export
	
	GenerateDocumentRoutineOperationInt(HandlerParameters);
	
EndProcedure

#EndRegion

#Region SettingOfClosingDateForPostingInFinancialAccounting

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
// 	CurrentParent - String - group ID.
Procedure AddStage_SettingOfClosingDateForPostingInFinancialAccounting(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.SettingOfClosingDateForPostingInFinancialAccounting,
		False, False, True);
	
	NewRow.MultilingualName = "vi = 'Ngày cấm lập bút toán';
								|ru = 'Дата запрета формирования проводок';
								|en = 'Closing date of posting generation';
								|it = 'Data divieto formazione voci di contabilità';
								|pl = 'Data zakazu tworzenia księgowania';
								|tr = 'Girişlerin düzenlenmesinin engel tarihi'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Cài đặt';
								|ru = 'Установить';
								|en = 'Set'; fa = 'مجموعه';
								|it = 'Impostare';
								|pl = 'Set';
								|tr = 'Ayarla'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"FinancialAccountingOfMonthEndClosing.Usage_SettingDateWhenTransactionsAreNotGeneratedInt");
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"FinancialAccountingOfMonthEndClosing.Registration_SettingDateOfBanOnGeneratingTransactionsInt");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.InformationRegisters.ClosingDatesOfFinancialAccountingPostingGeneration.Forms.ClosingDatesOfAccountingPostingGeneration.FullName());
EndProcedure

// Performs a check of the need to complete the closing stage of the month.
//
// Parameters:
//	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification.
//
Procedure Usage_SettingDateWhenTransactionsAreNotGeneratedInt(HandlerParameters) Export
	
	VerifyUseOfInternationalAccounting(HandlerParameters);
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	CheckNeedForReflectionInInternationalAccounting(HandlerParameters);
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
EndProcedure

// Initializes the name of the stage of setting the date of the ban on the formation of transactions
//
// Parameters:
// 	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
//
Procedure Registration_SettingDateOfBanOnGeneratingTransactionsInt(HandlerParameters) Export
	
	PeriodEndClosingDate = FinancialAccountingOfGeneralPurpose.ClosingDateOfPostingGeneration(HandlerParameters.CalculationParameters.CompanyArray);
	
	HandlerParameters.Data_Stage.Description = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Ngày cấm lập bút toán %1';
			|ru = 'Дата запрета формирования проводок %1';
			|en = 'Posting generation closing date %1'; fa = 'Posting generation closing date %1';
			|it = 'Data del divieto di creazione dei movimenti %1';
			|pl = 'Data zakazu tworzenia księgowań %1';
			|tr = 'Giriş kaydetme kapanış tarihi %1''dir'"),
		Format(PeriodEndClosingDate, "DLF=DD"));
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

#EndRegion

#Region Other

// Description of the action "Open document list form "" Routine operation (international accounting)""".
// The selection by operation type is taken from the types of regular Operations property of the description of the month closing stage.
//
// Returns:
//	Structure - See MonthEndTransactionsServer.StructureOfActionDescription
//
Function ActionDescription_OpenListOfDocumentsIntRoutineOperation() Export
	
	LongDesc = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.PeriodEndTransactionFinancialAccounting.Forms.ListForm.FullName(),
		True);
	
	Return LongDesc;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region Internal

#Region UniversalChecksOfMonthClosingStages

// Checks the use of international accounting.
//
// Parameters:
//	HandlerParameters - Structure - parameters of the stage event handler.
//	
// Returns:
//	Boolean - an indication of the use of international accounting.
//
Function VerifyUseOfInternationalAccounting(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("UseFinancialAccounting") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không có kế toán IFRS.';
				|ru = 'Международный финансовый учет не ведется.';
				|en = 'Financial accounting is not kept.'; fa = 'Financial accounting is not kept.';
				|it = 'La contabilità finanziaria internazionale non viene mantenuta.';
				|pl = 'Międzynarodowa ewidencja finansowa nie jest prowadzona.';
				|tr = 'Genel muhasebe uygulanmıyor.'", Common.DefaultLanguageCode()));
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

// Checks whether it is necessary to generate international accounting entries for at least one calculated organization in the calculated period.
//
// Parameters:
//	HandlerParameters 			  - Structure - parameters of the stage event handler
//	OnlyGenerateTemporaryTable - Boolean - if True, then there is no need to change the state of the stage.
//	
// Returns:
//	Boolean - indicates the presence of settings.
//
Function CheckNeedForReflectionInInternationalAccounting(HandlerParameters, OnlyGenerateTemporaryTable = False) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query, "TTOrganizations");
	
	Query.Text =
	"SELECT
	|	T.Organization AS Ref,
	|	T.ChartOfAccounts AS ChartOfAccounts,
	|	CASE
	|		WHEN T.ChartOfAccounts.AccountingInFunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal)
	|			THEN T.Organization.LocalAccountingCurrency
	|		ELSE &ManagementAccountingCurrency
	|	END AS CurrencyFunctional
	|INTO TTOrganizations
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(&EndOfPeriod, Organization IN (&CompanyArray)) AS T
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			Enum.PeriodEndTransactionsTypesFinancialAccounting AS TypesOfRoutineOperations
	|		WHERE
	|			TypesOfRoutineOperations.Ref IN (&TransactionTypes)
	|			AND TypesOfRoutineOperations.Ref <> VALUE(Enum.PeriodEndTransactionsTypesFinancialAccounting.ReclassificationOfLongTermAssetsAndLiabilities)
	|			AND TypesOfRoutineOperations.Ref <> VALUE(Enum.PeriodEndTransactionsTypesFinancialAccounting.ClosingOfGLAccountsOfIncomeAndExpenses)
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	T.Organization AS Ref,
	|	T.ChartOfAccounts AS ChartOfAccounts,
	|	CASE
	|		WHEN T.ChartOfAccounts.AccountingInFunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal)
	|			THEN T.Organization.LocalAccountingCurrency
	|		ELSE &ManagementAccountingCurrency
	|	END AS CurrencyFunctional
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(&EndOfPeriod, Organization IN (&CompanyArray)) AS T
	|WHERE
	|	(VALUE(Enum.PeriodEndTransactionsTypesFinancialAccounting.ReclassificationOfLongTermAssetsAndLiabilities) IN (&TransactionTypes)
	|	AND T.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities = TRUE)
	|	OR
	|	(VALUE(Enum.PeriodEndTransactionsTypesFinancialAccounting.ClosingOfGLAccountsOfIncomeAndExpenses) IN (&TransactionTypes)
	|	AND T.PostingGenerationSetting.ClosingOfIncomeAndExpenseAccounts IN (&TimeFenceForClosingAccounts))
	|INDEX BY
	|	Ref,
	|	ChartOfAccounts
	|";
	
	TimeFenceForClosingAccounts = New Array();
	TimeFenceForClosingAccounts.Add(Enums.ClosingOfIncomeAndExpenseAccounts.Monthly);
	
	If EndOfMonth(HandlerParameters.CalculationParameters.RegistrationPeriod) = EndOfYear(HandlerParameters.CalculationParameters.RegistrationPeriod) Then
		TimeFenceForClosingAccounts.Add(Enums.ClosingOfIncomeAndExpenseAccounts.AtYearEnd);
	EndIf;
	
	Query.SetParameter("TimeFenceForClosingAccounts", TimeFenceForClosingAccounts);
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("TransactionTypes", HandlerParameters.Data_Stage.TypesOfRoutineOperations);
	Query.Execute();
	
	If MonthEndTransactionsServer.TemporaryTableSize(Query, "TTOrganizations", HandlerParameters) = 0 Then
		
		If Not OnlyGenerateTemporaryTable Then
			MonthEndTransactionsServer.NoNeedToSetState(
				HandlerParameters,
				NStr("vi = 'Không cần phản ánh vào kế toán quốc tế.';
					|ru = 'Не требуется отражение в международном учете.';
					|en = 'General ledger posting is not required.'; fa = 'General ledger posting is not required.';
					|it = 'Non è richiesto il riporto in contabilità internazionale.';
					|pl = 'Nie jest wymagane odzwierciedlenie w ewidencji międzynarodowej.';
					|tr = 'Uluslararası muhasebede yansıtılması gerekmiyor.'", Common.DefaultLanguageCode()));
		EndIf;
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

// Checks the availability of "Routine operation (international accounting)" documents.
//
// Parameters:
//	HandlerParameters 		- Structure - parameters of the stage event handler
//	OperationType 		 		- EnumRef.PeriodEndTransactionsTypesFinancialAccounting - document operation type
//									if not specified, the operation types from the types of regulatory Operations property of this stage are analyzed
//	NameOfOrganizationSelectionTable - String - name of the temporary table for selecting documents by organization
//									organizations in the specified table must be in the field named "Link"
//	PresenceOfDocumentIsMandatory - Boolean - indicates whether the document is required.
//	
Procedure CheckAvailabilityOfDocumentRoutineOperationInternationalAccounting(HandlerParameters,
	Val OperationType = Undefined, NameOfOrganizationSelectionTable = "TTOrganizations", PresenceOfDocumentIsMandatory = False) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	If Not ValueIsFilled(NameOfOrganizationSelectionTable) Then
		
		// Verification for all calculated organizations.
		Query.Text =
		"SELECT
		|	Companies.Ref
		|INTO TTOrganizations
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.Ref IN(&CompanyArray)";
		
		Query.Execute();
		
	EndIf;
	
	Query.Text =
	"SELECT DISTINCT
	|	Operations.Ref    AS OperationType,
	|	Companies.Ref AS Organization,
	|	FinancialAccountingChartsOfAccounts.ChartOfAccounts AS ChartOfAccounts
	|INTO TTOperations
	|FROM
	|	Enum.PeriodEndTransactionsTypesFinancialAccounting AS Operations
	|
	|	INNER JOIN
	|		TTOrganizations AS Companies
	|	ON
	|		TRUE
	|
	|	INNER JOIN 
	|		InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(&EndOfPeriod) AS FinancialAccountingChartsOfAccounts
	|	ON
	|		Companies.Ref = FinancialAccountingChartsOfAccounts.Organization
	|WHERE
	|	Operations.Ref IN (&TransactionTypes)
	|	AND FinancialAccountingChartsOfAccounts.PostingGenerationSetting <> VALUE(Catalog.FinancialAccountingPostingGenerationSetting.EmptyRef)
	|	AND CASE
	|		WHEN Operations.Ref = VALUE(Enum.PeriodEndTransactionsTypesFinancialAccounting.ReclassificationOfLongTermAssetsAndLiabilities)
	|			THEN FinancialAccountingChartsOfAccounts.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities = TRUE
	|		WHEN Operations.Ref = VALUE(Enum.PeriodEndTransactionsTypesFinancialAccounting.ClosingOfGLAccountsOfIncomeAndExpenses)
	|			THEN FinancialAccountingChartsOfAccounts.PostingGenerationSetting.ClosingOfIncomeAndExpenseAccounts IN (&TimeFenceForClosingAccounts)
	|		ELSE TRUE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Operations.OperationType AS OperationType,
	|	Operations.Organization AS Organization,
	|	Operations.ChartOfAccounts AS ChartOfAccounts,
	|	COUNT(PeriodEndTransaction.Ref) AS DocumentsCount
	|FROM
	|	TTOperations AS Operations
	|	LEFT JOIN Document.PeriodEndTransactionFinancialAccounting AS PeriodEndTransaction
	|		ON (PeriodEndTransaction.Organization = Operations.Organization)
	|			AND (PeriodEndTransaction.ChartOfAccounts = Operations.ChartOfAccounts)
	|			AND (PeriodEndTransaction.OperationType = Operations.OperationType)
	|			AND (PeriodEndTransaction.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|			AND (PeriodEndTransaction.Posted)
	|
	|GROUP BY
	|	Operations.ChartOfAccounts,
	|	Operations.OperationType,
	|	Operations.Organization
	|
	|ORDER BY
	|	Operations.OperationType,
	|	Operations.Organization";
	
	If ValueIsFilled(NameOfOrganizationSelectionTable) Then
		Query.Text = StrReplace(Query.Text, "TTOrganizations", NameOfOrganizationSelectionTable);
	EndIf;
	
	HasErrors    = False;
	ThereAreDocuments_ = False;
	Period 		= CostCalculationProtocol.PresentationOfCalculationPeriod(HandlerParameters.CalculationParameters.RegistrationPeriod);
	TransactionTypes  = ?(ValueIsFilled(OperationType),
		TMCommonUseClientServer.Array(OperationType),
		HandlerParameters.Data_Stage.TypesOfRoutineOperations);
	
	TimeFenceForClosingAccounts = New Array();
	TimeFenceForClosingAccounts.Add(Enums.ClosingOfIncomeAndExpenseAccounts.Monthly);
	
	If EndOfMonth(HandlerParameters.CalculationParameters.RegistrationPeriod) = EndOfYear(HandlerParameters.CalculationParameters.RegistrationPeriod) Then
		TimeFenceForClosingAccounts.Add(Enums.ClosingOfIncomeAndExpenseAccounts.AtYearEnd);
	EndIf;
	
	Query.SetParameter("TimeFenceForClosingAccounts", TimeFenceForClosingAccounts);
	Query.SetParameter("TransactionTypes", TransactionTypes);
	
	Selection = Query.Execute().Select();
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, Selection.Count());
	
	While Selection.Next() Do
		
		If Selection.DocumentsCount > 1 Then
			
			HasErrors = True;
			MonthEndTransactionsServer.SetStateFailed(
				HandlerParameters,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Theo doanh nghiệp ""%1"" theo hệ thống tài khoản ""%2"" trong kỳ %3 đã lập nhiều chứng từ giao dịch thường kỳ ""%4"".';
						|ru = 'По организации ""%1"" по плану счетов ""%2"" за период %3 сформировано несколько документов регламентных операций ""%4"" .';
						|en = 'Several period-end transaction documents ""%4"" have been generated for company ""%1"" as per chart of accounts ""%2"" in period %3.'; fa = 'Several period-end transaction documents ""%4"" have been generated for company ""%1"" as per chart of accounts ""%2"" in period %3.';
						|it = 'Per l''organizzazione ""%1"" in base al piano dei conti ""%2"" per il periodo %3 sono stati creati alcuni documenti di operazioni regolatorie ""%4"".';
						|pl = 'Dla firmy ""%1"" wg planu kont ""%2"" za okres %3 utworzono kilka dokumentów operacji reglamentowanych ""%4"" .';
						|tr = '%3 dönemi için ""%2"" hesap planındaki ""%1"" iş yeri için birkaç ""%4"" dönem sonu işlemleri oluşturuldu.'", Common.DefaultLanguageCode()),
					Selection.Organization,
					Selection.ChartOfAccounts,
					Period,
					TrimAll(Selection.OperationType)));
					
			Continue;
			
		ElsIf Selection.DocumentsCount = 0 Then
			
			If Not PresenceOfDocumentIsMandatory Then
				// There is no data for calculation and there is no regulatory document - calculation is not required.
			Else
				// There are data for calculation, but there is no regulatory document - the calculation is not performed.
				HasErrors = True;
				MonthEndTransactionsServer.SetStateFailed(
					HandlerParameters,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Doanh nghiệp ""%1"" theo hệ thống tài khoản ""%2"" trong kỳ %3 chưa lập giao dịch thường kỳ ""%4"".';
							|ru = 'По организации ""%1"" по плану счетов ""%2"" за период %3 не сформирована регламентная операция ""%4"".';
							|en = 'The period-end transaction ""%4"" has not been generated for company ""%1"" as per chart of accounts ""%2"" in period %3.'; fa = 'The period-end transaction ""%4"" has not been generated for company ""%1"" as per chart of accounts ""%2"" in period %3.';
							|it = 'Per l''organizzazione ""%1"" in base al piano dei conti ""%2"" per il periodo %3 non è creata l''operazione regolatoria ""%4"".';
							|pl = 'Dla firmy ""%1"" wg planu kont ""%2"" za okres %3 nie utworzono operacji reglamentowanej ""%4"".';
							|tr = '%3 dönemi için ""%2"" hesap planındaki ""%1"" iş yeri için ""%4"" dönem sonu işlemi oluşturulmadı.'", Common.DefaultLanguageCode()),
						Selection.Organization,
						Selection.ChartOfAccounts,
						Period,
						TrimAll(Selection.OperationType)));
			EndIf;
			
		Else // there is one document
			ThereAreDocuments_ = True;
		EndIf;
		
	EndDo;
	
	If Not PresenceOfDocumentIsMandatory And Not HasErrors And Not ThereAreDocuments_ Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong kỳ %1 không có dữ liệu để tính và không có chứng từ ""Giao dịch thường kỳ (kế toán quốc tế)"".';
					|ru = 'За период %1 нет данных для расчета и отсутствует документ ""Регламентная операция (международный учет)"".';
					|en = 'No data for calculation and no ""Period-end transaction — Financial accounting"" document for period %1.'; fa = 'No data for calculation and no ""Period-end transaction — Financial accounting"" document for period %1.';
					|it = 'Per il periodo %1 non ci sono dati per la contabilizzazione e manca il documento ""Operazione di routine (contabilità internazionale)"".';
					|pl = 'Za okres %1 nie ma danych do obliczenia i nie ma dokumentu ""Operacja reglamentowana (ewidencja międzynarodowa)"".';
					|tr = '%1 dönemi için hesaplama için veri yok ve ""Dönem sonu işlemi - Finansal muhasebe"" belgesi bulunmuyor.'", Common.DefaultLanguageCode()),
				Period));
		
	EndIf;
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query,
		"TTOperations" + ?(Not ValueIsFilled(NameOfOrganizationSelectionTable), ", TTOrganizations", ""));
	
EndProcedure

#EndRegion

#Region FormationOfRoutineOperations

// Generates documents " Routine operation (international accounting)".
//
// Parameters:
//	HandlerParameters 	- Structure - parameters of the stage event handler
//	OperationType 			- EnumRef.PeriodEndTransactionsTypesFinancialAccounting - document operation type
//								if not specified, documents with all types of operations are created from the types of regulatory Operations property of this stage
//	TaskData_ - See MonthEndTransactionsServer.MonthlyTasks
//	DestroyTTOrganizations - Boolean - indicates whether the temporary Intrusion table should be deleted.
//
// Returns:
//	Boolean - the presence of errors when creating documents
//	
Function GenerateDocumentRoutineOperationInt(HandlerParameters,
	Val OperationType = Undefined, TaskData_ = Undefined, DestroyTTOrganizations = True) Export
	
	HasErrors = False;
	
	If Not CheckNeedForReflectionInInternationalAccounting(HandlerParameters, True) Then
		Return HasErrors;
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	QueryText =
	"SELECT
	|	T.Ref AS Organization,
	|	T.ChartOfAccounts AS ChartOfAccounts,
	|	CASE
	|		WHEN PeriodEndTransaction.Ref IS NULL
	|			THEN UNDEFINED
	|		ELSE PeriodEndTransaction.Ref
	|	END AS RegulatoryDocument
	|INTO TTDocuments
	|FROM
	|	TTOrganizations AS T
	|		LEFT JOIN Document.PeriodEndTransactionFinancialAccounting AS PeriodEndTransaction
	|		ON (PeriodEndTransaction.ChartOfAccounts = T.ChartOfAccounts)
	|			AND (PeriodEndTransaction.Organization = T.Ref)
	|			AND (PeriodEndTransaction.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|			AND (PeriodEndTransaction.OperationType = &OperationType)
	|			AND (PeriodEndTransaction.Posted)
	|WHERE
	|	&AdditionalSelection
	|INDEX BY
	|	ChartOfAccounts,
	|	Organization,
	|	RegulatoryDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.ChartOfAccounts AS ChartOfAccounts,
	|	T.Organization AS Organization,
	|	MAX(T.RegulatoryDocument) AS RegulatoryDocument
	|INTO TTCurrentDocuments
	|FROM
	|	TTDocuments AS T
	|
	|GROUP BY
	|	T.ChartOfAccounts,
	|	T.Organization
	|
	|INDEX BY
	|	ChartOfAccounts,
	|	Organization,
	|	RegulatoryDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.ChartOfAccounts AS ChartOfAccounts,
	|	T.Organization AS Organization,
	|	T.RegulatoryDocument,
	|	CASE
	|		WHEN T.RegulatoryDocument <> T2.RegulatoryDocument
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Delete
	|FROM
	|	TTDocuments AS T
	|		LEFT JOIN TTCurrentDocuments AS T2
	|		ON 
	|			T.ChartOfAccounts = T2.ChartOfAccounts
	|			AND T.Organization = T2.Organization
	|
	|ORDER BY
	|	Organization";
	
	If TypeOf(TaskData_) = Type("Structure") And TaskData_.Property("Organization") Then
		Query.SetParameter("Companies", TaskData_.Organization);
		AdditionalSelection = "T.Ref IN (&Companies)";
	Else
		AdditionalSelection = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&AdditionalSelection", AdditionalSelection);
	Query.Text = QueryText;
	
	TransactionTypes = ?(ValueIsFilled(OperationType),
		TMCommonUseClientServer.Array(OperationType),
		HandlerParameters.Data_Stage.TypesOfRoutineOperations);
	
	For Each OperationType In TransactionTypes Do
		
		Query.SetParameter("OperationType", OperationType);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			If Not ValueIsFilled(Selection.RegulatoryDocument) Then
				RegulatoryDocument = Documents.PeriodEndTransactionFinancialAccounting.CreateDocument();
			Else
				RegulatoryDocument = Selection.RegulatoryDocument.GetObject();
			EndIf;
			
			RegulatoryDocument.AdditionalProperties.Insert("CompletingMonthClosingStage", True);
			
			Try
			
				If Selection.Delete Then
					RegulatoryDocument.SetDeletionMark(True);
					Continue;
				ElsIf RegulatoryDocument.Posted Then
					RegulatoryDocument.Write(DocumentWriteMode.UndoPosting);
				EndIf;
				
				RegulatoryDocument.Date 	     	= EndOfMonth(HandlerParameters.CalculationParameters.RegistrationPeriod);
				RegulatoryDocument.ChartOfAccounts 	= Selection.ChartOfAccounts;
				RegulatoryDocument.Organization 	= Selection.Organization;
				RegulatoryDocument.OperationType   	= OperationType;
				RegulatoryDocument.EmployeeResponsible 	= Users.CurrentUser();
				
				RegulatoryDocument.Write(DocumentWriteMode.Posting);
				
			Except
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã kết thúc bị lỗi khi lập chứng từ ""Giao dịch thường kỳ (kế toán quốc tế)"" theo doanh nghiệp ""%1"" và hệ thống tài khoản ""%2"" trong kỳ %3:
						|%4';
						|ru = 'Формирование документа ""Регламентная операция (международный учет)"" по организации ""%1"" и плану счетов ""%2"" за период %3 завершилось с ошибкой:
						|%4';
						|en = 'Generation of the ""Period-end transaction — Financial accounting"" document by the ""%1"" company and ""%2"" chart of accounts for period %3 was completed with an error:
						|%4'; fa = 'Generation of the ""Period-end transaction — Financial accounting"" document by the ""%1"" company and ""%2"" chart of accounts for period %3 was completed with an error:
						|%4';
						|it = 'Creazione del documento ""Operazione regolatoria (contabilità internazionale)"" per l''organizzazione ""%1"" e piano dei conti ""%2"" per il periodo %3 completata con errore:
						|%4';
						|pl = 'Tworzenie dokumentu ""Operacja reglamentowana (ewidencja międzynarodowa)"" wg firmy ""%1"" i planu kont ""%2"" za okres %3 zakończyło się z błędem:
						|%4';
						|tr = '""%1"" iş yeri için "" Dönem sonu işlemi - Finansal muhasebe"" belgesinin ve %3 dönemi için ""%2"" hesap planının oluşturulması şu hatayla sona erdi:
						|%4'", Common.DefaultLanguageCode()),
					Selection.Organization,
					Selection.ChartOfAccounts,
					CostCalculationProtocol.PresentationOfCalculationPeriod(HandlerParameters.CalculationParameters.RegistrationPeriod),
					DetailErrorDescription(ErrorInfo()));
				
				HasErrors = True;
				ConfiguringGenerationOfTransactionsWithErrors = Undefined;
				RegulatoryDocument.AdditionalProperties.Property("ConfiguringGenerationOfTransactionsWithErrors", ConfiguringGenerationOfTransactionsWithErrors);
				
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
					HandlerParameters,
					ErrorText,
					Selection.Organization,
					,
					,
					ConfiguringGenerationOfTransactionsWithErrors);
				
			EndTry;
			
		EndDo;
		
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query, "TTDocuments, TTCurrentDocuments");
		
	EndDo;
	
	If DestroyTTOrganizations Then
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query, "TTOrganizations");
	EndIf;
	
	Return HasErrors;
	
EndFunction

#EndRegion

#Region CheckingCompletionOfTasksForCalculationAndFormationOfRegisteredRecords

// For documents registered for reflection in international accounting, it generates an array of string messages
// about the non-fulfillment of deferred tasks for calculations, distributions, and the formation of movements.
// 
// Parameters:
//	ReflectionStatus - EnumRef.StatusesOfPostingsInFinancialAccounting - selection of documents by THE Status of reflection in MFIS
//	DateRecord - Date - task selection no later than the submitted date
//	Organization - CatalogRef.Companies, Array of CatalogRef.Companies - selection of tasks by organization
//	Document - DocumentRef, Array of DocumentRef - Selection Of Tasks By Document
//	More - Boolean - If set to True, it adds the dates of the periods from which the tasks are required to be completed
// 
// Returns:
//	Array of String - descriptions of unfulfilled deferred tasks
//
Function OutstandingDeferredTasks(ReflectionStatus, DateRecord, Organization, Document, More = False) Export
	
	TasksNotCompleted = New Array();
	SelectionOfTasksByDocument = ValueIsFilled(Document);
	
	Query = New Query();
	Query.SetParameter("NewSettlements", GetFunctionalOption("NewOnlineARAPAccounting"));
	Query.SetParameter("DocumentTypes", NonCurrentAssetsCached.IdsOfDocumentsForGeneratingDeferredTraffic());
	
	QueryText = "";
	
	If SelectionOfTasksByDocument Then
		QueryText = QueryText + "
		|SELECT
		|	InventoryCost.Recorder AS Recorder,
		|	InventoryCost.Organization AS Organization
		|INTO TTCostOfGoods_
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|WHERE
		|	InventoryCost.Recorder IN (&Document)
		|	AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND InventoryCost.Active
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	VendorsARAPAccounting.Recorder AS Recorder,
		|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|INTO TTSettlementsWithSuppliers
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|WHERE
		|	VendorsARAPAccounting.Recorder IN (&Document)
		|	AND VendorsARAPAccounting.Active
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CustomersARAPAccounting.Recorder AS Recorder,
		|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|INTO TTSettlementsWithCustomers
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
		|WHERE
		|	CustomersARAPAccounting.Recorder IN (&Document)
		|	AND CustomersARAPAccounting.Active
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FACost.Recorder AS Recorder,
		|	FACost.Organization AS Organization,
		|	FACost.ExpensesCapitalizationDimension AS ExpensesCapitalizationDimension
		|INTO CostTTOfFA
		|FROM
		|	AccumulationRegister.FACost AS FACost
		|WHERE
		|	FACost.Recorder IN (&Document)
		|	AND FACost.Active
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	IACost.Recorder AS Recorder,
		|	IACost.Organization AS Organization,
		|	IACost.IntangibleAsset AS IntangibleAsset
		|INTO CostOfIAIsTT
		|FROM
		|	AccumulationRegister.IACost AS IACost
		|WHERE
		|	IACost.Recorder IN (&Document)
		|	AND IACost.Active
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FixedAssetsDocuments.Ref AS Ref,
		|	FixedAssetsDocuments.Organization AS Organization,
		|	FixedAssetsDocuments.FixedAsset AS FixedAsset
		|INTO TTFADocuments
		|FROM
		|	InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
		|WHERE
		|	FixedAssetsDocuments.Ref IN (&Document)
		|	AND FixedAssetsDocuments.RefType IN (&DocumentTypes)
		|	AND FixedAssetsDocuments.Posted
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	IntangibleAssetsDocuments.Ref AS Ref,
		|	IntangibleAssetsDocuments.Organization AS Organization,
		|	IntangibleAssetsDocuments.IntangibleAsset AS IntangibleAsset
		|INTO TTDocumentsOnIA
		|FROM
		|	InformationRegister.IntangibleAssetsDocuments AS IntangibleAssetsDocuments
		|WHERE
		|	IntangibleAssetsDocuments.Ref IN (&Document)
		|	AND IntangibleAssetsDocuments.RefType IN (&DocumentTypes)
		|	AND IntangibleAssetsDocuments.Posted";
	EndIf;
	
	QueryText = QueryText + ?(IsBlankString(QueryText), "", Common.QueryBatchSeparator()) + "
	|SELECT
	|	MIN(JobsForCalculatingCost.Month) AS Period
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
	|	INNER JOIN InformationRegister.JobsForCalculatingCost AS JobsForCalculatingCost
	|		ON DocumentPostingInFinancialAccounting.Organization = JobsForCalculatingCost.Organization
	|		 AND DocumentPostingInFinancialAccounting.DateRecord >= JobsForCalculatingCost.Month";
	
	If SelectionOfTasksByDocument Then
		QueryText = QueryText + "
		|	INNER JOIN TTCostOfGoods_ AS InventoryCost
		|		ON DocumentPostingInFinancialAccounting.Recorder = InventoryCost.Recorder
		|		 AND DocumentPostingInFinancialAccounting.Organization = InventoryCost.Organization";
	EndIf;
	
	QueryText = QueryText + "
	|WHERE
	|	&SelectionByReflectionStatus
	|	AND &SelectionByReflectionDate
	|	AND &FilterByCompany
	|	AND &FilterByDocument
	|HAVING
	|	NOT MIN(JobsForCalculatingCost.Month) IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(JobsForAllocatingARAP.Month) AS Period
	|FROM
	|	(SELECT
	|		MIN(JobsForAllocatingVendorsARAP.Month) AS MONTH
	|	FROM
	|		InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
	|		INNER JOIN InformationRegister.JobsForAllocatingVendorsARAP AS JobsForAllocatingVendorsARAP
	|			ON DocumentPostingInFinancialAccounting.Organization = JobsForAllocatingVendorsARAP.AccountingDimensionByPartners.Organization
	|			 AND DocumentPostingInFinancialAccounting.DateRecord >= JobsForAllocatingVendorsARAP.Month";
	
	If SelectionOfTasksByDocument Then
		QueryText = QueryText + "
		|		INNER JOIN TTSettlementsWithSuppliers AS VendorsARAPAccounting
		|			ON DocumentPostingInFinancialAccounting.Recorder = VendorsARAPAccounting.Recorder
		|			 AND JobsForAllocatingVendorsARAP.AccountingDimensionByPartners = VendorsARAPAccounting.AccountingDimensionByPartners";
	EndIf;
	
	QueryText = QueryText + "
	|	WHERE
	|		NOT &NewSettlements
	|		AND &SelectionByReflectionStatus
	|		AND &SelectionByReflectionDate
	|		AND &FilterByCompany
	|		AND &FilterByDocument
	|
	|	UNION ALL
	|
	|	SELECT
	|		MIN(JobsForAllocatingCustomersARAP.Month) AS MONTH
	|	FROM
	|		InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
	|		INNER JOIN InformationRegister.JobsForAllocatingCustomersARAP AS JobsForAllocatingCustomersARAP
	|			ON DocumentPostingInFinancialAccounting.Organization = JobsForAllocatingCustomersARAP.AccountingDimensionByPartners.Organization
	|			 AND DocumentPostingInFinancialAccounting.DateRecord >= JobsForAllocatingCustomersARAP.Month";
	
	If SelectionOfTasksByDocument Then
		QueryText = QueryText + "
		|		INNER JOIN TTSettlementsWithCustomers AS CustomersARAPAccounting
		|			ON DocumentPostingInFinancialAccounting.Recorder = CustomersARAPAccounting.Recorder
		|			 AND JobsForAllocatingCustomersARAP.AccountingDimensionByPartners = CustomersARAPAccounting.AccountingDimensionByPartners";
	EndIf;
	
	QueryText = QueryText + "
	|	WHERE
	|		NOT &NewSettlements
	|		AND &SelectionByReflectionStatus
	|		AND &SelectionByReflectionDate
	|		AND &FilterByCompany
	|		AND &FilterByDocument
	|	) AS JobsForAllocatingARAP
	|HAVING
	|	NOT MIN(JobsForAllocatingARAP.Month) IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(JobsForCalculatingNonCurrentAssetCost.Month) AS Period
	|FROM
	|	(SELECT
	|		MIN(JobsForCalculatingNonCurrentAssetCost.Month) AS MONTH
	|	FROM
	|		InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
	|		INNER JOIN InformationRegister.JobsForCalculatingNonCurrentAssetCost AS JobsForCalculatingNonCurrentAssetCost
	|			ON DocumentPostingInFinancialAccounting.Organization = JobsForCalculatingNonCurrentAssetCost.Organization
	|			 AND DocumentPostingInFinancialAccounting.DateRecord >= JobsForCalculatingNonCurrentAssetCost.Month";
	
	If SelectionOfTasksByDocument Then
		QueryText = QueryText + "
		|		INNER JOIN CostTTOfFA AS FACost
		|			ON DocumentPostingInFinancialAccounting.Recorder = FACost.Recorder
		|			 AND DocumentPostingInFinancialAccounting.Organization = FACost.Organization
		|			 AND JobsForCalculatingNonCurrentAssetCost.AccountingObject = FACost.ExpensesCapitalizationDimension";
	EndIf;
	
	QueryText = QueryText + "
	|	WHERE
	|		&SelectionByReflectionStatus
	|		AND &SelectionByReflectionDate
	|		AND &FilterByCompany
	|		AND &FilterByDocument";
	
	If SelectionOfTasksByDocument Then
		QueryText = QueryText + "
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		MIN(JobsForCalculatingNonCurrentAssetCost.Month) AS Month
		|	FROM
		|		InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
		|		INNER JOIN InformationRegister.JobsForCalculatingNonCurrentAssetCost AS JobsForCalculatingNonCurrentAssetCost
		|			ON DocumentPostingInFinancialAccounting.Organization = JobsForCalculatingNonCurrentAssetCost.Organization
		|			 AND DocumentPostingInFinancialAccounting.DateRecord >= JobsForCalculatingNonCurrentAssetCost.Month
		|		INNER JOIN CostOfIAIsTT AS IACost
		|			ON DocumentPostingInFinancialAccounting.Recorder = IACost.Recorder
		|			 AND DocumentPostingInFinancialAccounting.Organization = IACost.Organization
		|			 AND JobsForCalculatingNonCurrentAssetCost.AccountingObject = IACost.IntangibleAsset
		|	WHERE
		|		&SelectionByReflectionStatus
		|		AND &SelectionByReflectionDate
		|		AND &FilterByCompany
		|		AND &FilterByDocument";
	EndIf;
	
	QueryText = QueryText + "
	|	) AS JobsForCalculatingNonCurrentAssetCost
	|HAVING
	|	NOT MIN(JobsForCalculatingNonCurrentAssetCost.Month) IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(JobsForGeneratingFixedAssetRecords.Month) AS Period
	|FROM
	|	(SELECT
	|		MIN(JobsForGeneratingFixedAssetRecords.Month) AS MONTH
	|	FROM
	|		InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
	|		INNER JOIN InformationRegister.JobsForGeneratingFixedAssetRecords AS JobsForGeneratingFixedAssetRecords
	|			ON DocumentPostingInFinancialAccounting.Organization = JobsForGeneratingFixedAssetRecords.Organization
	|			 AND DocumentPostingInFinancialAccounting.DateRecord >= JobsForGeneratingFixedAssetRecords.Month";
	
	If SelectionOfTasksByDocument Then
		QueryText = QueryText + "
		|		INNER JOIN TTFADocuments AS FixedAssetsDocuments
		|			ON DocumentPostingInFinancialAccounting.Recorder = FixedAssetsDocuments.Ref
		|			 AND DocumentPostingInFinancialAccounting.Organization = FixedAssetsDocuments.Organization
		|			 AND JobsForGeneratingFixedAssetRecords.AccountingObject = FixedAssetsDocuments.FixedAsset";
	EndIf;
	
	QueryText = QueryText + "
	|	WHERE
	|		&SelectionByReflectionStatus
	|		AND &SelectionByReflectionDate
	|		AND &FilterByCompany
	|		AND &FilterByDocument";
	
	If SelectionOfTasksByDocument Then
		QueryText = QueryText + "
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		MIN(JobsForGeneratingFixedAssetRecords.Month) AS Month
		|	FROM
		|		InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
		|		INNER JOIN InformationRegister.JobsForGeneratingFixedAssetRecords AS JobsForGeneratingFixedAssetRecords
		|			ON DocumentPostingInFinancialAccounting.Organization = JobsForGeneratingFixedAssetRecords.Organization
		|			 AND DocumentPostingInFinancialAccounting.DateRecord >= JobsForGeneratingFixedAssetRecords.Month
		|		INNER JOIN TTDocumentsOnIA AS IntangibleAssetsDocuments
		|			ON DocumentPostingInFinancialAccounting.Recorder = IntangibleAssetsDocuments.Ref
		|			 AND DocumentPostingInFinancialAccounting.Organization = IntangibleAssetsDocuments.Organization
		|			 AND JobsForGeneratingFixedAssetRecords.AccountingObject = IntangibleAssetsDocuments.IntangibleAsset
		|	WHERE
		|		&SelectionByReflectionStatus
		|		AND &SelectionByReflectionDate
		|		AND &FilterByCompany
		|		AND &FilterByDocument";
	EndIf;
	
	QueryText = QueryText + "
	|	) AS JobsForGeneratingFixedAssetRecords
	|HAVING
	|	NOT MIN(JobsForGeneratingFixedAssetRecords.Month) IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(JobsForMonthEndClosing.Month) AS Period
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
	|	INNER JOIN InformationRegister.JobsForMonthEndClosing AS JobsForMonthEndClosing
	|		ON DocumentPostingInFinancialAccounting.Organization = JobsForMonthEndClosing.Organization
	|		 AND DocumentPostingInFinancialAccounting.DateRecord >= JobsForMonthEndClosing.Month
	|		 AND VALUETYPE(DocumentPostingInFinancialAccounting.Recorder) = TYPE(Document.RDExpenseRecognition)
	|		 AND JobsForMonthEndClosing.Operation = VALUE(Catalog.MonthEndClosingOperations.RDExpenseRecognition)
	|WHERE
	|	&SelectionByReflectionStatus
	|	AND &SelectionByReflectionDate
	|	AND &FilterByCompany
	|	AND &FilterByDocument
	|HAVING
	|	NOT MIN(JobsForMonthEndClosing.Month) IS NULL
	|";
	
	If ValueIsFilled(ReflectionStatus) Then
		SelectionByReflectionStatus = "DocumentPostingInFinancialAccounting.Status IN (&ReflectionStatus)";
		Query.SetParameter("ReflectionStatus", ReflectionStatus);
	Else
		SelectionByReflectionStatus = "TRUE";
	EndIf;
	
	If ValueIsFilled(DateRecord) Then
		SelectionByReflectionDate = "DocumentPostingInFinancialAccounting.DateRecord <= &DateRecord";
		Query.SetParameter("DateRecord", DateRecord);
	Else
		SelectionByReflectionDate = "TRUE";
	EndIf;
	
	If ValueIsFilled(Organization) Then
		FilterByCompany = "DocumentPostingInFinancialAccounting.Organization IN (&Organization)";
		Query.SetParameter("Organization", Organization);
	Else
		FilterByCompany = "TRUE";
	EndIf;
	
	If SelectionOfTasksByDocument Then
		FilterByDocument = "DocumentPostingInFinancialAccounting.Recorder IN (&Document)";
		Query.SetParameter("Document", Document);
	Else
		FilterByDocument = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SelectionByReflectionStatus", SelectionByReflectionStatus);
	QueryText = StrReplace(QueryText, "&SelectionByReflectionDate", SelectionByReflectionDate);
	QueryText = StrReplace(QueryText, "&FilterByCompany", FilterByCompany);
	QueryText = StrReplace(QueryText, "&FilterByDocument", FilterByDocument);
	
	SetPrivilegedMode(True);
	Query.Text = QueryText;
	Results = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	TasksNotCompleted.Add(NStr("vi = 'Chưa tính giá vốn';
								|ru = 'Расчет себестоимости не выполнен';
								|en = 'Cost is not calculated'; fa = 'Cost is not calculated';
								|it = 'Расчет себестоимости не выполнен';
								|pl = 'Cost is not calculated';
								|tr = 'Maliyet hesaplaması gerçekleştirilmedi'"));
	TasksNotCompleted.Add(NStr("vi = 'Chưa phân bổ hạch toán';
								|ru = 'Распределение расчетов не выполнено';
								|en = 'AR/AP are not allocated'; fa = 'AR/AP are not allocated';
								|it = 'Распределение расчетов не выполнено';
								|pl = 'AR/AP are not allocated';
								|tr = 'Hesapların dağılımı gerçekleştirilmedi'"));
	TasksNotCompleted.Add(NStr("vi = 'Chưa tính giá trị TSCĐ hữu hình và TSCĐ vô hình';
								|ru = 'Расчет стоимости ОС и НМА не выполнен';
								|en = 'FIxed asset and intangible asset value is not calculated'; fa = 'FIxed asset and intangible asset value is not calculated';
								|it = 'Расчет стоимости ОС и НМА не выполнен';
								|pl = 'FIxed asset and intangible asset value is not calculated';
								|tr = 'SV ve maddi olmayan varlıkların ücret hesaplaması gerçekleştirilmedi'"));
	TasksNotCompleted.Add(NStr("vi = 'Chưa tạo bản ghi kết chuyển ghi nhận TSCĐ hữu hình và TSCĐ vô hình';
								|ru = 'Формирование движений по учету ОС и НМА не выполнено';
								|en = 'Register records by accounting of fixed assets and intangible assets are not generated'; fa = 'Register records by accounting of fixed assets and intangible assets are not generated';
								|it = 'Формирование движений по учету ОС и НМА не выполнено';
								|pl = 'Register records by accounting of fixed assets and intangible assets are not generated';
								|tr = 'SV ve maddi olmayan varlık hesaplarının akış oluşturulması gerçekleştirilmemiş'"));
	TasksNotCompleted.Add(NStr("vi = 'Chưa ghi nhận chi phí nghiên cứu và triển khai';
								|ru = 'Признание расходов по исследованиям и разработкам не выполнено';
								|en = 'R&D expense recognition is not performed'; fa = 'R&D expense recognition is not performed';
								|it = 'Признание расходов по исследованиям и разработкам не выполнено';
								|pl = 'R&D expense recognition is not performed';
								|tr = 'Araştırma ve geliştirmeye ilişkin masrafların muhasebeleştirilmesi gerçekleştirilmemiş'"));
	
	JobsCount = TasksNotCompleted.Count();
	NumberOfResults = Results.Count();
	
	For JobNumber = 1 To JobsCount Do
		JobIndex = JobsCount - JobNumber;
		ResultIndex = NumberOfResults - JobNumber;
		
		If Results[ResultIndex].IsEmpty() Then
			TasksNotCompleted.Delete(JobIndex);
		ElsIf More Then
			Selection = Results[ResultIndex].Select();
			Selection.Next();
			TasksNotCompleted[JobIndex] = StrTemplate(
				NStr("vi = '%1 từ %2.';
					|ru = '%1 с %2.';
					|en = '%1 from %2.'; fa = '%1 from %2.';
					|it = '%1 с %2.';
					|pl = '%1 from %2.';
					|tr = '%2''den %1.'"),
				TasksNotCompleted[JobIndex],
				Format(Selection.Period, NStr("vi = 'ДФ=ММ.гггг;';
												|ru = 'ДФ=MM.yyyy;';
												|en = 'DF=MM/yyyy;'; fa = 'DF=MM/yyyy;';
												|it = 'ДФ=ММ.гггг;';
												|pl = 'DF=MM/yyyy;';
												|tr = 'TB=AA.yyyy;'")));
		Else
			TasksNotCompleted[JobIndex] = TasksNotCompleted[JobIndex] + ".";
		EndIf;
	EndDo;
	
	Return TasksNotCompleted;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region FormationOfTasksForEndOfMonthServiceTasks

Function MatchingRequestsToControlRegisters(Query)
	
	MatchingQueryTexts = New Map();
	
	If GetFunctionalOption("SettingOfPostingByAccountingObjects") Then
		MatchingQueryTexts.Insert("ChangesTableCustomersARAPAccounting", QueryTextCustomersARAPAccounting(Query));
		MatchingQueryTexts.Insert("ChangesTableVendorsARAPAccounting", QueryTextVendorsARAPAccounting(Query));
		MatchingQueryTexts.Insert("ChangesTableFinancialInstrumentsARAP", QueryTextFinancialInstrumentsARAP(Query));
		MatchingQueryTexts.Insert("ChangesTableLeaseServicesPaymentSchedule", QueryTextLeaseServicesPaymentSchedule(Query));
		MatchingQueryTexts.Insert("ChangesTableScheduleOfPaymentForLoansAndDeposits", QueryTextScheduleOfPaymentForLoansAndDeposits(Query));
	EndIf;
	
	Return MatchingQueryTexts;
	
EndFunction

Function QueryTextCustomersARAPAccounting(Query)
	
	TempTablesQueryText = "
	|SELECT DISTINCT
	|	ChangesTable.Month AS Month,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.Document Document
	|INTO TTPeriodsOfChanges_SettlementsWithCustomers
	|FROM 
	|	ChangesTableCustomersARAPAccounting AS ChangesTable
	|
	|INDEX BY
	|	Month,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	TempTable = "TTPeriodsOfChanges_SettlementsWithCustomers";
	QueryText = GeneralTextOfReclassificationRequest(TempTable);
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(
		QueryText, TempTablesQueryText, TempTable);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextVendorsARAPAccounting(Query)
	
	TempTablesQueryText = "
	|SELECT DISTINCT
	|	ChangesTable.Month AS Month,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.Document AS Document
	|INTO TTChangePeriods_SettlementsWithSuppliers
	|FROM
	|	ChangesTableVendorsARAPAccounting AS ChangesTable
	|
	|INDEX BY
	|	Month,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	TempTable = "TTChangePeriods_SettlementsWithSuppliers";
	QueryText = GeneralTextOfReclassificationRequest(TempTable);
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(
		QueryText, TempTablesQueryText, TempTable);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextFinancialInstrumentsARAP(Query)
	
	TempTablesQueryText = "
	|SELECT
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Month,
	|	ChangesTable.AccountingDimensionByPartners.Organization AS Organization,
	|	ChangesTable.Recorder AS Document
	|INTO TTPeriodsOfChanges_SettlementsOnFinancialInstruments
	|FROM
	|	ChangesTableFinancialInstrumentsARAP AS ChangesTable
	|WHERE
	|	ChangesTable.Sum <> 0 OR ChangesTable.SumCompl <> 0 OR ChangesTable.SumMan <> 0
	|GROUP BY
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH),
	|	ChangesTable.AccountingDimensionByPartners.Organization,
	|	ChangesTable.Recorder
	|INDEX BY
	|	Month,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	TempTable = "TTPeriodsOfChanges_SettlementsOnFinancialInstruments";
	QueryText = GeneralTextOfReclassificationRequest(TempTable);
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(
		QueryText, TempTablesQueryText, TempTable);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextLeaseServicesPaymentSchedule(Query)
	
	TempTablesQueryText = "
	|SELECT
	|	MIN(BEGINOFPERIOD(ChangesTable.Date, MONTH)) AS BeginOfPeriod,
	|	MAX(ENDOFPERIOD(ChangesTable.Date, MONTH)) AS EndOfPeriod,
	|	ChangesTable.Contract.Organization AS Organization,
	|	ChangesTable.Recorder AS Recorder
	|INTO TTPeriodOfChanges_ScheduleOfPaymentsForRentalServices
	|FROM
	|	ChangesTableLeaseServicesPaymentSchedule AS ChangesTable
	|GROUP BY
	|	ChangesTable.Contract.Organization,
	|	ChangesTable.Recorder
	|";
	
	DataSource = "TTPeriodOfChanges_ScheduleOfPaymentsForRentalServices";
	PlacementTable = "TTPeriodsOfChanges_ScheduleOfPaymentsForRentalServices";
	
	TempTablesQueryText = TempTablesQueryText
		+ Common.QueryBatchSeparator()
		+ RequestTextPeriodsForChangesToPaymentSchedule(DataSource, PlacementTable)
		+ Common.QueryBatchSeparator();
		
	QueryText = GeneralTextOfReclassificationRequest(PlacementTable);
	TemporaryTable = DataSource + "," + PlacementTable;
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(
		QueryText, TempTablesQueryText, TemporaryTable);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextScheduleOfPaymentForLoansAndDeposits(Query)
	
	TempTablesQueryText = "
	|SELECT
	|	MIN(BEGINOFPERIOD(ChangesTable.Period, MONTH)) AS BeginOfPeriod,
	|	MAX(ENDOFPERIOD(ChangesTable.Period, MONTH)) AS EndOfPeriod,
	|	ChangesTable.ScheduleOption.Owner.Organization AS Organization,
	|	UNDEFINED AS Recorder
	|INTO TTChangePeriod_PaymentScheduleForLoansAndDeposits
	|FROM
	|	ChangesTableScheduleOfPaymentForLoansAndDeposits AS ChangesTable
	|GROUP BY
	|	ChangesTable.ScheduleOption.Owner.Organization
	|";
	
	DataSource = "TTChangePeriod_PaymentScheduleForLoansAndDeposits";
	PlacementTable = "TTPeriodsOfChanges_PaymentScheduleForLoansAndDeposits";
	
	TempTablesQueryText = TempTablesQueryText
		+ Common.QueryBatchSeparator()
		+ RequestTextPeriodsForChangesToPaymentSchedule(DataSource, PlacementTable)
		+ Common.QueryBatchSeparator();
		
	QueryText = GeneralTextOfReclassificationRequest(PlacementTable);
	TemporaryTable = DataSource + "," + PlacementTable;
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(
		QueryText, TempTablesQueryText, TemporaryTable);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function RequestTextPeriodsForChangesToPaymentSchedule(DataSource, PlacementTable)
	
	QueryText = "
	|SELECT
	|	BEGINOFPERIOD(PeriodEndTransaction.Date, MONTH) AS Month,
	|	PaymentScheduleChangePeriod.Organization AS Organization,
	|	PaymentScheduleChangePeriod.Recorder AS Document
	|INTO PlacementTable
	|FROM
	|	&DataSource AS PaymentScheduleChangePeriod
	|	INNER JOIN Document.PeriodEndTransactionFinancialAccounting AS PeriodEndTransaction
	|		ON PeriodEndTransaction.Organization = PaymentScheduleChangePeriod.Organization
	|		 AND PeriodEndTransaction.Date BETWEEN PaymentScheduleChangePeriod.BeginOfPeriod AND PaymentScheduleChangePeriod.EndOfPeriod
	|		 AND PeriodEndTransaction.Posted
	|GROUP BY
	|	BEGINOFPERIOD(PeriodEndTransaction.Date, MONTH),
	|	PaymentScheduleChangePeriod.Organization,
	|	PaymentScheduleChangePeriod.Recorder
	|INDEX BY
	|	Month,
	|	Organization
	|";
	
	QueryText = StrReplace(QueryText, "&DataSource", DataSource);
	QueryText = StrReplace(QueryText, "PlacementTable", PlacementTable);
	
	Return QueryText;
	
EndFunction

Function GeneralTextOfReclassificationRequest(DataSource)
	
	QueryText = "
	|SELECT DISTINCT
	|	ChangesTable.Month AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.ReclassificationOfLongTermAssetsAndLiabilitiesInt) AS Operation,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.Document AS Document
	|FROM 
	|	&DataSource AS ChangesTable
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
	|		ON ChangesTable.Organization = AccountingPolicy.Organization
	|		 AND ChangesTable.Month >= AccountingPolicy.Period
	|	INNER JOIN InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS ChartsOfAccounts
	|		ON ChangesTable.Organization = ChartsOfAccounts.Organization
	|		 AND ChangesTable.Month >= ChartsOfAccounts.Period
	|WHERE
	|	AccountingPolicy.DurationOfCompanyOperatingCycle > 0
	|	AND ChartsOfAccounts.PostingGenerationSetting.DivisionIntoShortTermLongTermAssetsAndLiabilities
	|	AND AccountingPolicy.Period IN (
	|		SELECT
	|			MAX(AccountingPolicyPeriods.Period)
	|		FROM
	|			InformationRegister.FinancialAccountingPolicy AS AccountingPolicyPeriods
	|		WHERE
	|			AccountingPolicyPeriods.Organization = ChangesTable.Organization
	|			AND AccountingPolicyPeriods.Period <= ChangesTable.Month
	|		)
	|	AND ChartsOfAccounts.Period IN (
	|		SELECT
	|			MAX(ChartOfAccountsPeriods.Period)
	|		FROM
	|			InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS ChartOfAccountsPeriods
	|		WHERE
	|			ChartOfAccountsPeriods.Organization = ChangesTable.Organization
	|			AND ChartOfAccountsPeriods.ChartOfAccounts = ChartsOfAccounts.ChartOfAccounts
	|			AND ChartOfAccountsPeriods.Period <= ChangesTable.Month
	|		)
	|";
	
	QueryText = StrReplace(QueryText, "&DataSource", DataSource);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region CompletingTasksByEndOfMonthServiceTasks

Procedure CompleteTasksByEndOfMonth(HandlerParameters)
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	BeginOfPeriod = BegOfMonth(CalculationParameters.RegistrationPeriod);
	EndOfPeriod  = EndOfMonth(CalculationParameters.RegistrationPeriod);
	
	TransactionTypes = New Array();
	
	For Each OperationType In HandlerParameters.Data_Stage.TypesOfRoutineOperations Do
		If RoutineOperationIsRequiredInSpecifiedPeriod(OperationType, BeginOfPeriod) Then
			TransactionTypes.Add(OperationType);
		EndIf;
	EndDo;
	
	If TransactionTypes.Count() = 0 Then
		Return;
	EndIf;
	
	TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber();
	
	BeginTransaction();
	
	Try
		
		MonthEndTransactionsServer.BlockTaskRegister(
			TaskNumberBeforeCalculation,
			CalculationParameters.CompanyArray,
			HandlerParameters.Data_Stage.Code);
		
		TaskData_ = MonthEndTransactionsServer.MonthlyTasks(
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
				|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
				|%2';
				|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
				|%2';
				|tr = 'Dönem %1 için hesaplama yapılırken bir hata oluştu:
				|%2'", Common.DefaultLanguageCode()),
			CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
			DetailErrorDescription(ErrorInfo()));
		
		MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
			HandlerParameters,
			ErrorText,
			CalculationParameters.CompanyArray,
			CalculationParameters.RegistrationPeriod);
		
	EndTry;
	
	HasErrors = GenerateDocumentRoutineOperationInt(HandlerParameters, TransactionTypes, TaskData_);
	
	If Not HasErrors Then
		
		BeginTransaction();
		
		Try
			
			MonthEndTransactionsServer.BlockTaskRegister(
				TaskNumberBeforeCalculation,
				CalculationParameters.CompanyArray,
				HandlerParameters.Data_Stage.Code);
			
			MonthEndTransactionsServer.FixCalculation(
				Undefined,
				HandlerParameters.Data_Stage.Code,
				TaskData_.TemporaryTable);
			
			CreateTasksForNextPeriod(CalculationParameters, TransactionTypes, TaskData_);
			
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
					|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
					|%2';
					|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
					|%2';
					|tr = 'Dönem %1 için hesaplama yapılırken bir hata oluştu:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(BeginOfPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				CalculationParameters.CompanyArray,
				CalculationParameters.RegistrationPeriod);
			
		EndTry;
		
	EndIf;
	
EndProcedure

Function RoutineOperationIsRequiredInSpecifiedPeriod(OperationType, Period)
	
	Periodicity = PeriodicityOfRoutineOperations(OperationType);
	
	If Periodicity = Enums.Periodicity.Month Then
		Return True;
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		Return (Month(Period) % 3 = 0);
	ElsIf Periodicity = Enums.Periodicity.Year Then
		Return (Month(Period) = 12);
	Else
		Raise NStr("vi = 'Sai định kỳ của giao dịch thường kỳ';
					|ru = 'Неверная периодичность регламентной операции';
					|en = 'Incorrect frequency of the period-end transaction'; fa = 'Incorrect frequency of the period-end transaction';
					|it = 'Periodicità errata dell''operazione di routine';
					|pl = 'Niepoprawna okresowość operacji reglametnowanej';
					|tr = 'Dönem sonu işlemin hatalı zaman sınırı'");
	EndIf; 
	
EndFunction

Function PeriodicityOfRoutineOperations(OperationType)
	
	Return Enums.Periodicity.Month;
	
EndFunction

Procedure CreateTasksForNextPeriod(CalculationParameters, TransactionTypes, TaskData_)
	
	If TransactionTypes.Find(Enums.PeriodEndTransactionsTypesFinancialAccounting.ReclassificationOfLongTermAssetsAndLiabilities) = Undefined Then
		Return;
	EndIf;
	
	BeginningOfNextPeriod = AddMonth(BegOfMonth(CalculationParameters.RegistrationPeriod), 1);
	
	OrganizationsOfNextPeriod = FinancialAccountingByFinancialRegisterData.OrganizationsReclassifyingNonCurrentAssetsLiabilities(
		TaskData_.Organization, BeginningOfNextPeriod);
		
	QueryText = "
	|SELECT
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
	|	TTCacheBorders AS BorderCache
	|WHERE
	|	BorderCache.Organization IN(&Companies)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTCacheBorders
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TaskData_.TemporaryTable;
	Query.SetParameter("Companies", OrganizationsOfNextPeriod);
	Query.Execute();
	
	InformationRegisters.JobsForMonthEndClosing.CreateTasksForNextPeriod(
		Query.TempTablesManager,
		BeginningOfNextPeriod);
	
EndProcedure

#EndRegion

#EndRegion
