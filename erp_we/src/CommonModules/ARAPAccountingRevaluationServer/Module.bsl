#Region Public

//Recalculates all exchange rate differences for the specified period.
//
// Parameters:
//	CompanyArray - Array of CatalogRef.Companies- The list of organizations that need to be re-evaluated.
//	BeginOfPeriod - Date - The beginning of the period of translation of exchange differences.
//	EndOfPeriod - Date - The end of the period of translation of exchange differences.
//  Parameters - See RevaluationParameters
//
Procedure PerformRevaluationForPeriod(CompanyArray, Val BeginOfPeriod, Val EndOfPeriod, Parameters) Export
	
	MeasurementName = "ARAPAccounting.CalculationOfExchangeDifferencesByTerms" + ?(Parameters.TheseAreSettlementsWithCustomers,".Customers",".Vendors");
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(MeasurementName);
	Parameters.Insert("ProcessedItemsTotal", 0);
	RevaluationDocuments = Documents.ExchangeDifferenceCalculation.RevaluationDocumentsForOrganizations(
		CompanyArray, BeginOfPeriod, EndOfPeriod, Parameters.TheseAreSettlementsWithCustomers);	
	Parameters.Insert("RevaluationDocuments", RevaluationDocuments);	
	BusinessOperation = Enums.BusinessTransactions.RevaluationOfVendorsARAPAccounting;
	If Parameters.TheseAreSettlementsWithCustomers Then
		BusinessOperation = Enums.BusinessTransactions.RevaluationOfCustomersARAP;
	EndIf;
	Parameters.Insert("BusinessOperation", BusinessOperation);
	Parameters.Insert("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	
	BeginOfPeriod = BegOfMonth(BeginOfPeriod);
	EndOfPeriod = EndOfMonth(BeginOfPeriod);

	DaysOfReassessment = DaysOfReassessment(CompanyArray, BeginOfPeriod, EndOfPeriod, Parameters);
	Parameters.Insert("DaysOfReassessment", DaysOfReassessment);
	DeleteExchangeDifferencesForPeriod(CompanyArray, BeginOfPeriod, EndOfPeriod, Parameters);
	For Each Day In DaysOfReassessment Do
		Date = Day.Date;
		If EndOfDay(Day.Date) = EndOfMonth(Day.Date) Then
			Date = EndOfDay(Day.Date);
		EndIf;
		PerformRevaluationOnDate(CompanyArray, Date, Parameters);
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, Parameters.ProcessedItemsTotal);
	
EndProcedure

// Returns the structure of parameters required for registering a document for deferred distribution of calculations.
// 
// Returns:
// 	Structure - LongDesc:
//  *TheseAreSettlementsWithCustomers - Boolean - True if these are payments to customers.
//  *RevaluationByDays - Boolean - The truth is if it is necessary to reevaluate every day, otherwise only on the days of payment.
//  *ReFillingTARegisters - Boolean - True if the calculation of coursework for TA is performed.
//
Function RevaluationParameters(TheseAreSettlementsWithCustomers = Undefined, RevaluationByDays = Undefined) Export
	
	Result = New Structure;
	Result.Insert("TheseAreSettlementsWithCustomers", TheseAreSettlementsWithCustomers);
	
	If RevaluationByDays = Undefined Then
		Result.Insert("RevaluationByDays", Constants.RevalueCurrencyByDays.Get());
	Else
		Result.Insert("RevaluationByDays", RevaluationByDays);
	EndIf;
	Result.Insert("ReFillingTARegisters", False);

	Return Result;
	
EndFunction


#EndRegion

#Region Private

//Adds entries to the revaluation on the same date.
//
// Parameters:
//	CompanyArray - Array of CatalogRef.Companies - The list of organizations that need to be re-evaluated.
//	Period - Date - The date at the end of which the revaluation should be performed.
//  Parameters - See RevaluationParameters 
//
Procedure PerformRevaluationOnDate(CompanyArray, Period, Parameters) Export

	TheseAreSettlementsWithCustomers = Parameters.TheseAreSettlementsWithCustomers;
	RevaluationByDays = Parameters.RevaluationByDays;
	
	Query = New Query;
	#Region QueryText
	QueryText = 
	"SELECT
	|	AccountingAnalyticsForPartners.DimensionKey                              AS AccountingDimensionByPartners,
	|	AccountingAnalyticsForPartners.Organization                                AS Organization,
	|	AccountingAnalyticsForPartners.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	&ManagementAccountingCurrency                                          AS ManagementAccountingCurrency,
	|	AccountingAnalyticsForPartners.Contract                                    AS Contract,
	|	ISNULL(CounterpartyContracts.RevalueGoodsAndServicesForConsignmentNotification, FALSE) AS RevalueGoodsAndServicesForConsignmentNotification,
	|	NOT ISNULL(CounterpartyContracts.DoNotApply67FZRegulationWhenRevaluatingCustomerARAPOpenItems, FALSE) AS ApplyProvisionsOf67FZ,
	|	ISNULL(CounterpartyContracts.ContractType, UNDEFINED)             AS ContractType,
	|	ISNULL(
	|		ISNULL(
	|			CounterpartyContracts.ContractRateOption, 
	|			IntercompanyContracts.ContractRateOption), 
	|		VALUE(Enum.ContractRateOptions.Mutable))         AS ContractRateOption
	|INTO VtAccountingAnalyticsByPartners
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingAnalyticsForPartners 
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON AccountingAnalyticsForPartners.Contract = CounterpartyContracts.Ref
	|		LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
	|		ON AccountingAnalyticsForPartners.Contract = IntercompanyContracts.Ref
	|WHERE
	|	AccountingAnalyticsForPartners.Organization IN (&CompanyArray)
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	LocalAccountingCurrency,
	|	ManagementAccountingCurrency,
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Turnovers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Turnovers.ARAPObject AS ARAPObject,
	|	Turnovers.Currency AS Currency,
	|	Turnovers.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	Turnovers.ARAPDocument AS ARAPDocument,
	|	Turnovers.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	Turnovers.OccurrenceDate AS OccurrenceDate,
	|	Turnovers.DocumentPayments AS DocumentPayments,
	|	SUM(Turnovers.DebtExpense) AS DebtExpense,
	|	SUM(Turnovers.DebtLocalExpense) AS DebtLocalExpense,
	|	Turnovers.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers
	|
	|INTO TTTurnoverAccordingToPaymentDocuments
	|FROM
	|	(SELECT
	|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject AS ARAPObject,
	|		Calculations.Currency AS Currency,
	|		Calculations.AccountingDimensionByPartners.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|		Calculations.ARAPDocument AS ARAPDocument,
	|		Calculations.PlannedRepaymentDate AS PlannedRepaymentDate,
	|		Calculations.OccurrenceDate AS OccurrenceDate,
	|		CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN Calculations.Debt
	|			ELSE 0
	|		END AS DebtExpense,
	|		CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN Calculations.DebtLocal
	|			ELSE 0
	|		END AS DebtLocalExpense,
	|		Calculations.DocumentRecorder AS DocumentPayments,
	|		&TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|		INNER JOIN VtAccountingAnalyticsByPartners AS Dimension
	|			ON Calculations.AccountingDimensionByPartners = Dimension.AccountingDimensionByPartners
	|				AND (Calculations.Currency <> Dimension.LocalAccountingCurrency
	|					OR Calculations.Currency <> &ManagementAccountingCurrency)
	|		WHERE
	|			Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND VALUETYPE(Calculations.DocumentRecorder) <> TYPE(Document.ExchangeDifferenceCalculation)
	|			AND VALUETYPE(Calculations.DocumentRecorder) <> TYPE(Document.ARAPAccountingScheduleAdjustment)
	|			AND Calculations.Debt <> 0
	|			AND Calculations.BusinessOperation <> &ApplyingPrepayment
	|	) AS Turnovers
	|
	|GROUP BY
	|	Turnovers.AccountingDimensionByPartners,
	|	Turnovers.ARAPObject,
	|	Turnovers.Currency,
	|	Turnovers.LocalAccountingCurrency,
	|	Turnovers.ARAPDocument,
	|	Turnovers.PlannedRepaymentDate,
	|	Turnovers.OccurrenceDate,
	|	Turnovers.DocumentPayments,
	|	Turnovers.TheseAreSettlementsWithCustomers
	|	
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency,
	|	ARAPDocument,
	|	PlannedRepaymentDate,
	|	OccurrenceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Turnovers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Turnovers.ARAPObject AS ARAPObject,
	|	Turnovers.Currency AS Currency,
	|	Turnovers.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	Turnovers.ARAPDocument AS ARAPDocument,
	|	Turnovers.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	Turnovers.OccurrenceDate AS OccurrenceDate,
	|	SUM(Turnovers.DebtExpense) AS DebtExpense,
	|	SUM(Turnovers.DebtLocalExpense) AS DebtLocalExpense,
	|	Turnovers.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers
	|
	|INTO WRevolutionsPerDay
	|FROM
	|	TTTurnoverAccordingToPaymentDocuments AS Turnovers
	|
	|GROUP BY
	|	Turnovers.AccountingDimensionByPartners,
	|	Turnovers.ARAPObject,
	|	Turnovers.Currency,
	|	Turnovers.LocalAccountingCurrency,
	|	Turnovers.ARAPDocument,
	|	Turnovers.PlannedRepaymentDate,
	|	Turnovers.OccurrenceDate,
	|	Turnovers.TheseAreSettlementsWithCustomers
	|	
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency,
	|	ARAPDocument,
	|	PlannedRepaymentDate,
	|	OccurrenceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Turnovers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Turnovers.ARAPObject AS ARAPObject,
	|	Turnovers.Currency AS Currency,
	|	Turnovers.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	Turnovers.ARAPDocument AS ARAPDocument,
	|	SUM(Turnovers.DebtExpense) AS DebtExpense,
	|	SUM(Turnovers.DebtLocalExpense) AS DebtLocalExpense,
	|	Turnovers.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers
	|
	|INTO TTRevolutionsPerDayWithoutDates
	|FROM
	|	TTTurnoverAccordingToPaymentDocuments AS Turnovers
	|
	|GROUP BY
	|	Turnovers.AccountingDimensionByPartners,
	|	Turnovers.ARAPObject,
	|	Turnovers.Currency,
	|	Turnovers.LocalAccountingCurrency,
	|	Turnovers.ARAPDocument,
	|	Turnovers.TheseAreSettlementsWithCustomers
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
	|	BalanceAndTurnovers.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
	|	BalanceAndTurnovers.ARAPObject               AS ARAPObject,
	|	BalanceAndTurnovers.Currency                       AS Currency,
	|	BalanceAndTurnovers.ComplCurrency                   AS ComplCurrency,
	|	BalanceAndTurnovers.ARAPDocument            AS ARAPDocument,
	|	BalanceAndTurnovers.PlannedRepaymentDate       AS PlannedRepaymentDate,
	|	BalanceAndTurnovers.OccurrenceDate            AS OccurrenceDate,
	|	BalanceAndTurnovers.ContractRateOption         AS ContractRateOption,
	|	SUM(BalanceAndTurnovers.PrepaymentBalance)     AS PrepaymentBalance,
	|	SUM(BalanceAndTurnovers.PrepaymentLocalBalance) AS PrepaymentLocalBalance,
	|	SUM(BalanceAndTurnovers.PrepaymentManBalance)  AS PrepaymentManBalance,
	|	SUM(BalanceAndTurnovers.DebtBalance)           AS DebtBalance,
	|	SUM(BalanceAndTurnovers.DebtLocalBalance)       AS DebtLocalBalance,
	|	SUM(BalanceAndTurnovers.ARAPManBalance)        AS ARAPManBalance,
	|	BalanceAndTurnovers.TheseAreSettlementsWithCustomers         AS TheseAreSettlementsWithCustomers
	|INTO TTBalancesAtEndOfDay
	|FROM 
	|	(SELECT
	|		CalculationsByTermsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CalculationsByTermsBalance.ARAPObject            AS ARAPObject,
	|		CalculationsByTermsBalance.Currency                    AS Currency,
	|		AccountingAnalyticsForPartners.LocalAccountingCurrency   AS ComplCurrency,
	|		CalculationsByTermsBalance.ARAPDocument         AS ARAPDocument,
	|		CalculationsByTermsBalance.PlannedRepaymentDate    AS PlannedRepaymentDate,
	|		CalculationsByTermsBalance.OccurrenceDate         AS OccurrenceDate,
	|		AccountingAnalyticsForPartners.ContractRateOption             AS ContractRateOption,
	|		CalculationsByTermsBalance.PrepaymentBalance         AS PrepaymentBalance,
	|		CalculationsByTermsBalance.PrepaymentLocalBalance     AS PrepaymentLocalBalance,
	|		CalculationsByTermsBalance.PrepaymentManBalance      AS PrepaymentManBalance,
	|		CalculationsByTermsBalance.DebtBalance               AS DebtBalance,
	|		CalculationsByTermsBalance.DebtLocalBalance           AS DebtLocalBalance,
	|		CalculationsByTermsBalance.ARAPManBalance            AS ARAPManBalance,
	|		&TheseAreSettlementsWithCustomers                            AS TheseAreSettlementsWithCustomers
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
	|				&BeginOfPeriod,
	|				NOT (Currency, Currency) IN (
	|					SELECT 
	|						AccountingAnalyticsForPartners.LocalAccountingCurrency,
	|						AccountingAnalyticsForPartners.ManagementAccountingCurrency
	|					FROM
	|						VtAccountingAnalyticsByPartners AS AccountingAnalyticsForPartners
	|					)
	|			) AS CalculationsByTermsBalance
	|			INNER JOIN VtAccountingAnalyticsByPartners AS AccountingAnalyticsForPartners
	|				ON CalculationsByTermsBalance.AccountingDimensionByPartners = AccountingAnalyticsForPartners.AccountingDimensionByPartners
	|
	|	UNION ALL
	|
	|	SELECT
	|		CalculationsOnTimingOfTurnover.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
	|		CalculationsOnTimingOfTurnover.ARAPObject                    AS ARAPObject,
	|		CalculationsOnTimingOfTurnover.Currency                            AS Currency,
	|		AccountingAnalyticsForPartners.LocalAccountingCurrency   AS ComplCurrency,
	|		CalculationsOnTimingOfTurnover.ARAPDocument                 AS ARAPDocument,
	|		CalculationsOnTimingOfTurnover.PlannedRepaymentDate            AS PlannedRepaymentDate,
	|		CalculationsOnTimingOfTurnover.OccurrenceDate                 AS OccurrenceDate,
	|		AccountingAnalyticsForPartners.ContractRateOption             AS ContractRateOption,
	|		CASE WHEN CalculationsOnTimingOfTurnover.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CalculationsOnTimingOfTurnover.Prepayment
	|			ELSE -CalculationsOnTimingOfTurnover.Prepayment
	|		END                                                      AS PrepaymentBalance,
	|		CASE WHEN CalculationsOnTimingOfTurnover.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CalculationsOnTimingOfTurnover.PrepaymentLocal
	|			ELSE -CalculationsOnTimingOfTurnover.PrepaymentLocal
	|		END                                                      AS PrepaymentLocalBalance,
	|		CASE WHEN CalculationsOnTimingOfTurnover.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CalculationsOnTimingOfTurnover.PrepaymentMan
	|			ELSE -CalculationsOnTimingOfTurnover.PrepaymentMan
	|		END                                                      AS PrepaymentManBalance,
	|		CASE WHEN CalculationsOnTimingOfTurnover.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CalculationsOnTimingOfTurnover.Debt
	|			ELSE -CalculationsOnTimingOfTurnover.Debt
	|		END                                                      AS DebtBalance,
	|		CASE WHEN CalculationsOnTimingOfTurnover.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CalculationsOnTimingOfTurnover.DebtLocal
	|			ELSE -CalculationsOnTimingOfTurnover.DebtLocal
	|		END                                                      AS DebtLocalBalance,
	|		CASE WHEN CalculationsOnTimingOfTurnover.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CalculationsOnTimingOfTurnover.ARAPMan
	|			ELSE -CalculationsOnTimingOfTurnover.ARAPMan
	|		END                                                      AS ARAPManBalance,
	|		&TheseAreSettlementsWithCustomers                                      AS TheseAreSettlementsWithCustomers
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsOnTimingOfTurnover
	|			INNER JOIN VtAccountingAnalyticsByPartners AS AccountingAnalyticsForPartners
	|				ON CalculationsOnTimingOfTurnover.AccountingDimensionByPartners = AccountingAnalyticsForPartners.AccountingDimensionByPartners
	|				AND (CalculationsOnTimingOfTurnover.Currency <> AccountingAnalyticsForPartners.LocalAccountingCurrency
	|						OR CalculationsOnTimingOfTurnover.Currency <> AccountingAnalyticsForPartners.ManagementAccountingCurrency)
	|	WHERE
	|		CalculationsOnTimingOfTurnover.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND VALUETYPE(CalculationsOnTimingOfTurnover.DocumentRecorder) <> TYPE(Document.ExchangeDifferenceCalculation)
	|) AS BalanceAndTurnovers
	|		
	|GROUP BY
	|	BalanceAndTurnovers.AccountingDimensionByPartners ,
	|	BalanceAndTurnovers.ARAPObject,
	|	BalanceAndTurnovers.Currency,
	|	BalanceAndTurnovers.ComplCurrency,
	|	BalanceAndTurnovers.ARAPDocument,
	|	BalanceAndTurnovers.PlannedRepaymentDate,
	|	BalanceAndTurnovers.OccurrenceDate,
	|	BalanceAndTurnovers.ContractRateOption,
	|	BalanceAndTurnovers.TheseAreSettlementsWithCustomers
	|	
	|HAVING
	|	SUM(BalanceAndTurnovers.PrepaymentBalance) <> 0
	|	OR SUM(BalanceAndTurnovers.PrepaymentLocalBalance) <> 0
	|	OR SUM(BalanceAndTurnovers.PrepaymentManBalance) <> 0
	|	OR SUM(BalanceAndTurnovers.DebtBalance) <> 0
	|	OR SUM(BalanceAndTurnovers.DebtLocalBalance) <> 0
	|	OR SUM(BalanceAndTurnovers.ARAPManBalance) <> 0
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency,
	|	ARAPDocument,
	|	PlannedRepaymentDate,
	|	OccurrenceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.BaseCurrency AS BaseCurrency,
	|	CurrencyExchangeRate.CourseNumerator AS CourseNumerator,
	|	CurrencyExchangeRate.CourseDenominator AS CourseDenominator
	|INTO TTExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&BorderEndOfDay) AS CurrencyExchangeRate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExchangeRatesUnderContracts.Contract AS Contract,
	|	ExchangeRatesUnderContracts.CourseNumerator AS CourseNumerator,
	|	ExchangeRatesUnderContracts.CourseDenominator AS CourseDenominator
	|INTO TTExchangeRatesUnderContracts
	|FROM
	|	InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&BorderEndOfDay) AS ExchangeRatesUnderContracts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalancesAtEndOfDay.AccountingDimensionByPartners                      AS AccountingDimensionByPartners,
	|	BalancesAtEndOfDay.ARAPObject                                 AS ARAPObject,
	|	BalancesAtEndOfDay.Currency                                         AS Currency,
	|	BalancesAtEndOfDay.ComplCurrency                                     AS ComplCurrency,
	|	BalancesAtEndOfDay.ARAPDocument                              AS ARAPDocument,
	|	BalancesAtEndOfDay.PlannedRepaymentDate                         AS PlannedRepaymentDate,
	|	BalancesAtEndOfDay.OccurrenceDate                              AS OccurrenceDate,
	|	AccountingAnalyticsForPartners.ContractRateOption                   AS ContractRateOption,
	|	AccountingAnalyticsForPartners.RevalueGoodsAndServicesForConsignmentNotification AS RevalueGoodsAndServicesForConsignmentNotification,
	|	AccountingAnalyticsForPartners.ApplyProvisionsOf67FZ                 AS ApplyProvisionsOf67FZ,
	|	AccountingAnalyticsForPartners.ContractType                            AS ContractType,
	|	BalancesAtEndOfDay.PrepaymentBalance                              AS PrepaymentBalance,
	|	BalancesAtEndOfDay.PrepaymentLocalBalance                          AS PrepaymentLocalBalance,
	|	BalancesAtEndOfDay.PrepaymentManBalance                           AS PrepaymentManBalance,
	|	BalancesAtEndOfDay.DebtBalance                                    AS DebtBalance,
	|	BalancesAtEndOfDay.DebtLocalBalance                                AS DebtLocalBalance,
	|	BalancesAtEndOfDay.ARAPManBalance                                 AS ARAPManBalance,
	|	CASE WHEN AccountingAnalyticsForPartners.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|			THEN ISNULL(ExchangeRatesUnderContracts.CourseNumerator,1)
	|		WHEN AccountingAnalyticsForPartners.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|				AND BalancesAtEndOfDay.ARAPObject.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|			THEN ISNULL(ExchangeRatesAccordingToDocuments.RateARAPCurrencyNumerator,1)
	|		ELSE 
	|			ISNULL(ExchangeRates.CourseNumerator,1)
	|	END                                                                           AS CourseNumeratorLocal,
	|	CASE WHEN AccountingAnalyticsForPartners.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|			THEN ISNULL(ExchangeRatesUnderContracts.CourseDenominator,1)
	|		WHEN AccountingAnalyticsForPartners.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|				AND BalancesAtEndOfDay.ARAPObject.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|			THEN ISNULL(ExchangeRatesAccordingToDocuments.RateARAPCurrencyDenominator,1)
	|		ELSE
	|			ISNULL(ExchangeRates.CourseDenominator,1)
	|	END                                                                           AS CourseDenominatorLocal,
	|	CASE WHEN AccountingAnalyticsForPartners.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|					AND BalancesAtEndOfDay.Currency = &ManagementAccountingCurrency
	|			THEN ISNULL(ExchangeRatesUnderContracts.CourseNumerator,1)
	|		WHEN AccountingAnalyticsForPartners.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|				AND BalancesAtEndOfDay.ARAPObject.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|			THEN 
	|				ISNULL(ExchangeRatesAccordingToDocuments.RateManagementAccountingCurrencyNumerator,1)
	|		ELSE
	|			ISNULL(ManSExchangeRate.CourseNumerator,1)
	|	END                                                                           AS CourseNumeratorMan,
	|	CASE WHEN AccountingAnalyticsForPartners.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|					AND BalancesAtEndOfDay.Currency = &ManagementAccountingCurrency
	|			THEN ISNULL(ExchangeRatesUnderContracts.CourseDenominator,1)
	|		WHEN AccountingAnalyticsForPartners.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|				AND BalancesAtEndOfDay.ARAPObject.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|			THEN 
	|				ISNULL(ExchangeRatesAccordingToDocuments.RateManagementAccountingCurrencyDenominator,1)
	|		ELSE 
	|			ISNULL(ManSExchangeRate.CourseDenominator,1)
	|	END                                                                           AS CourseDenominatorMan,
	|	BalancesAtEndOfDay.TheseAreSettlementsWithCustomers                                          AS TheseAreSettlementsWithCustomers
	|INTO TTBalancesWithExchangeRates
	|FROM
	|	TTBalancesAtEndOfDay AS BalancesAtEndOfDay
	|		INNER JOIN VtAccountingAnalyticsByPartners AS AccountingAnalyticsForPartners
	|			ON BalancesAtEndOfDay.AccountingDimensionByPartners = AccountingAnalyticsForPartners.AccountingDimensionByPartners
	|		LEFT JOIN TTExchangeRates AS ManSExchangeRate
	|			ON BalancesAtEndOfDay.ComplCurrency = ManSExchangeRate.BaseCurrency
	|			AND ManSExchangeRate.Currency = &ManagementAccountingCurrency
	|		LEFT JOIN TTExchangeRates AS ExchangeRates
	|			ON BalancesAtEndOfDay.Currency = ExchangeRates.Currency
	|			AND BalancesAtEndOfDay.ComplCurrency = ExchangeRates.BaseCurrency
	|		LEFT JOIN TTExchangeRatesUnderContracts AS ExchangeRatesUnderContracts
	|			ON ExchangeRatesUnderContracts.Contract = AccountingAnalyticsForPartners.Contract
	|		LEFT JOIN InformationRegister.DocumentCurrenciesAndRates AS ExchangeRatesAccordingToDocuments
	|			ON BalancesAtEndOfDay.ARAPObject.Object = ExchangeRatesAccordingToDocuments.Document
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency,
	|	ARAPDocument,
	|	PlannedRepaymentDate,
	|	OccurrenceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTBalancesWithExchangeRates.AccountingDimensionByPartners                      AS AccountingDimensionByPartners,
	|	TTBalancesWithExchangeRates.ARAPObject                                 AS ARAPObject,
	|	TTBalancesWithExchangeRates.Currency                                         AS Currency,
	|	TTBalancesWithExchangeRates.ARAPDocument                              AS ARAPDocument,
	|	TTBalancesWithExchangeRates.PlannedRepaymentDate                         AS PlannedRepaymentDate,
	|	TTBalancesWithExchangeRates.OccurrenceDate                              AS OccurrenceDate,
	|	TTBalancesWithExchangeRates.ContractRateOption                           AS ContractRateOption,
	|	TTBalancesWithExchangeRates.RevalueGoodsAndServicesForConsignmentNotification      AS RevalueGoodsAndServicesForConsignmentNotification,
	|	TTBalancesWithExchangeRates.ApplyProvisionsOf67FZ                         AS ApplyProvisionsOf67FZ,
	|	TTBalancesWithExchangeRates.ContractType                                    AS ContractType,
	|	TTBalancesWithExchangeRates.PrepaymentBalance                              AS PrepaymentBalance,
	|	TTBalancesWithExchangeRates.PrepaymentLocalBalance                          AS PrepaymentLocalBalance,
	|	TTBalancesWithExchangeRates.PrepaymentManBalance                           AS PrepaymentManBalance,
	|	ISNULL(RevolutionsPerDay.DebtExpense, 0)                            AS DebtExpense,
	|	ISNULL(RevolutionsPerDay.DebtLocalExpense, 0)                        AS DebtLocalExpense,
	|	TTBalancesWithExchangeRates.DebtBalance                                    AS DebtBalance,
	|	TTBalancesWithExchangeRates.DebtLocalBalance                                AS DebtLocalBalance,
	|	TTBalancesWithExchangeRates.CourseNumeratorLocal 
	|		/ TTBalancesWithExchangeRates.CourseDenominatorLocal                      AS LocalCourse,
	|	CAST(TTBalancesWithExchangeRates.DebtBalance 
	|		* TTBalancesWithExchangeRates.CourseNumeratorLocal / TTBalancesWithExchangeRates.CourseDenominatorLocal AS NUMBER(31,2)) AS DebtLocalBalanceSettlement,
	|	TTBalancesWithExchangeRates.ARAPManBalance                                 AS ARAPManBalance,
	|	CAST(TTBalancesWithExchangeRates.DebtBalance 
	|		* TTBalancesWithExchangeRates.CourseNumeratorLocal / TTBalancesWithExchangeRates.CourseDenominatorLocal
	|			/ TTBalancesWithExchangeRates.CourseNumeratorMan * TTBalancesWithExchangeRates.CourseDenominatorMan AS NUMBER(31,2)) AS ManSDebtSettlementBalance,
	|	TTBalancesWithExchangeRates.TheseAreSettlementsWithCustomers                           AS TheseAreSettlementsWithCustomers
	|INTO TtToCalculate
	|FROM
	|	TTBalancesWithExchangeRates AS TTBalancesWithExchangeRates
	|	LEFT JOIN WRevolutionsPerDay AS RevolutionsPerDay
	|		ON TTBalancesWithExchangeRates.AccountingDimensionByPartners = RevolutionsPerDay.AccountingDimensionByPartners
	|			AND TTBalancesWithExchangeRates.ARAPObject = RevolutionsPerDay.ARAPObject
	|			AND TTBalancesWithExchangeRates.Currency = RevolutionsPerDay.Currency
	|			AND TTBalancesWithExchangeRates.ARAPDocument = RevolutionsPerDay.ARAPDocument
	|			AND TTBalancesWithExchangeRates.PlannedRepaymentDate = RevolutionsPerDay.PlannedRepaymentDate
	|			AND TTBalancesWithExchangeRates.OccurrenceDate = RevolutionsPerDay.OccurrenceDate
	|WHERE
	|	(NOT RevolutionsPerDay.ARAPObject IS NULL
	|		OR &DateOfCalculation = ENDOFPERIOD(&DateOfCalculation, MONTH)
	|		OR &RevaluationByDays)
	|	AND (TTBalancesWithExchangeRates.DebtLocalBalance
	|			- CAST(TTBalancesWithExchangeRates.DebtBalance 
	|			* TTBalancesWithExchangeRates.CourseNumeratorLocal / TTBalancesWithExchangeRates.CourseDenominatorLocal AS NUMBER(31,2)) >= 0.01 
	|		OR TTBalancesWithExchangeRates.DebtLocalBalance
	|			- CAST(TTBalancesWithExchangeRates.DebtBalance 
	|			* TTBalancesWithExchangeRates.CourseNumeratorLocal / TTBalancesWithExchangeRates.CourseDenominatorLocal AS NUMBER(31,2)) <= -0.01 
	|		OR TTBalancesWithExchangeRates.ARAPManBalance
	|			- CAST(TTBalancesWithExchangeRates.DebtBalance 
	|			* TTBalancesWithExchangeRates.CourseNumeratorLocal / TTBalancesWithExchangeRates.CourseDenominatorLocal
	|				/ TTBalancesWithExchangeRates.CourseNumeratorMan * TTBalancesWithExchangeRates.CourseDenominatorMan AS NUMBER(31,2)) >= 0.01
	|		OR TTBalancesWithExchangeRates.ARAPManBalance
	|			- CAST(TTBalancesWithExchangeRates.DebtBalance 
	|			* TTBalancesWithExchangeRates.CourseNumeratorLocal / TTBalancesWithExchangeRates.CourseDenominatorLocal
	|				/ TTBalancesWithExchangeRates.CourseNumeratorMan * TTBalancesWithExchangeRates.CourseDenominatorMan AS NUMBER(31,2)) <= -0.01
	|		OR TTBalancesWithExchangeRates.PrepaymentBalance = 0
	|			AND (TTBalancesWithExchangeRates.PrepaymentLocalBalance <> 0
	|				OR TTBalancesWithExchangeRates.PrepaymentManBalance <> 0)
	|		OR TTBalancesWithExchangeRates.DebtBalance = 0
	|			AND (TTBalancesWithExchangeRates.DebtLocalBalance <> 0
	|				OR TTBalancesWithExchangeRates.ARAPManBalance <> 0))
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency,
	|	ARAPDocument,
	|	PlannedRepaymentDate,
	|	OccurrenceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BalancesAtEndOfDay.ARAPObject              AS ARAPObject,
	|	BalancesAtEndOfDay.AccountingDimensionByPartners   AS AccountingDimensionByPartners,
	|	BalancesAtEndOfDay.Currency                      AS Currency,
	|	BalancesAtEndOfDay.TheseAreSettlementsWithCustomers        AS TheseAreSettlementsWithCustomers
	|INTO TTBalanceAnalytic
	|FROM 
	|	TTBalancesAtEndOfDay AS BalancesAtEndOfDay
	|	
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ARAPAccountingRecorder.Ref                      AS Ref,
	|	ARAPAccountingRecorder.ARAPObject              AS ARAPObject,
	|	ARAPAccountingRecorder.AccountingDimensionByPartners   AS AccountingDimensionByPartners,
	|	ARAPAccountingRecorder.Currency                      AS Currency,
	|	DimensionLeftovers.TheseAreSettlementsWithCustomers          AS TheseAreSettlementsWithCustomers,
	|	COUNT(ISNULL(Table.LineNumber,0))     AS TotalRecords
	|FROM
	|	Document.ARAPAccountingRecorder AS ARAPAccountingRecorder
	|		INNER JOIN TTBalanceAnalytic AS DimensionLeftovers
	|			ON DimensionLeftovers.ARAPObject = ARAPAccountingRecorder.ARAPObject
	|				AND DimensionLeftovers.AccountingDimensionByPartners = ARAPAccountingRecorder.AccountingDimensionByPartners
	|				AND DimensionLeftovers.Currency = ARAPAccountingRecorder.Currency
	|				AND ARAPAccountingRecorder.PaymentType_ = &PaymentType_
	|		
	|		LEFT JOIN #TableName AS Table
	|			ON Table.Recorder = ARAPAccountingRecorder.Ref
	|		
	|GROUP BY
	|	ARAPAccountingRecorder.Ref,
	|	ARAPAccountingRecorder.ARAPObject,
	|	ARAPAccountingRecorder.AccountingDimensionByPartners,
	|	ARAPAccountingRecorder.Currency,
	|	DimensionLeftovers.TheseAreSettlementsWithCustomers
	|
	|HAVING
	|	COUNT(ISNULL(Table.LineNumber,0)) < &PortionSize
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CalculationsOnTimingOfTurnover.Recorder                       AS Recorder,
	|	&TheseAreSettlementsWithCustomers                                    AS TheseAreSettlementsWithCustomers
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsOnTimingOfTurnover
	|		INNER JOIN VtAccountingAnalyticsByPartners AS AccountingAnalyticsForPartners
	|			ON CalculationsOnTimingOfTurnover.AccountingDimensionByPartners = AccountingAnalyticsForPartners.AccountingDimensionByPartners
	|WHERE
	|	CalculationsOnTimingOfTurnover.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND VALUETYPE(CalculationsOnTimingOfTurnover.DocumentRecorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.AccountingDimensionByPartners                      AS AccountingDimensionByPartners,
	|	T.ARAPObject                                 AS ARAPObject,
	|	T.Currency                                         AS Currency,
	|	T.TheseAreSettlementsWithCustomers                           AS TheseAreSettlementsWithCustomers,
	|	T.Organization                                    AS Organization
	|FROM (
	|	SELECT
	|		TtToCalculate.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
	|		TtToCalculate.ARAPObject                    AS ARAPObject,
	|		TtToCalculate.Currency                            AS Currency,
	|		TtToCalculate.TheseAreSettlementsWithCustomers              AS TheseAreSettlementsWithCustomers,
	|		Dimension.Organization                        AS Organization
	|	FROM TtToCalculate AS TtToCalculate
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|			ON TtToCalculate.AccountingDimensionByPartners = Dimension.DimensionKey
	|) AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TtToCalculate.TheseAreSettlementsWithCustomers                  AS TheseAreSettlementsWithCustomers,
	|	TtToCalculate.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
	|	TtToCalculate.ARAPObject                        AS ARAPObject,
	|	TtToCalculate.Currency                                AS Currency,
	|	TtToCalculate.ARAPDocument                     AS ARAPDocument,
	|	TtToCalculate.PlannedRepaymentDate                AS PlannedRepaymentDate,
	|	TtToCalculate.OccurrenceDate                     AS OccurrenceDate,
	|	TtToCalculate.AccountingDimensionByPartners.Organization AS Organization,
	|	TtToCalculate.ContractRateOption                  AS ContractRateOption,
	|	TtToCalculate.DebtLocalBalance                       AS DebtLocalBalance,
	|	TtToCalculate.DebtLocalBalanceSettlement              AS DebtLocalBalanceSettlement,
	|	TtToCalculate.ARAPManBalance                        AS ARAPManBalance,
	|	TtToCalculate.ManSDebtSettlementBalance               AS ManSDebtSettlementBalance,
	|	TtToCalculate.PrepaymentBalance                     AS PrepaymentBalance,
	|	TtToCalculate.PrepaymentLocalBalance                 AS PrepaymentLocalBalance,
	|	TtToCalculate.PrepaymentManBalance                  AS PrepaymentManBalance,
	|	MAX(ISNULL(CalculationsByTerms.SettlementProcedure, """")) AS SettlementProcedure,
	|	MAX(ISNULL(CalculationsByTerms.DocumentCurrency, """")) AS DocumentCurrency
	|FROM TtToCalculate AS TtToCalculate
	|	LEFT JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|		ON TtToCalculate.TheseAreSettlementsWithCustomers
	|			AND TtToCalculate.AccountingDimensionByPartners = CalculationsByTerms.AccountingDimensionByPartners
	|			AND TtToCalculate.ARAPObject = CalculationsByTerms.ARAPObject
	|			AND TtToCalculate.Currency = CalculationsByTerms.Currency
	|			AND TtToCalculate.ARAPDocument = CalculationsByTerms.ARAPDocument
	|			AND TtToCalculate.PlannedRepaymentDate = CalculationsByTerms.PlannedRepaymentDate
	|			AND CalculationsByTerms.Active
	|GROUP BY
	|	TtToCalculate.TheseAreSettlementsWithCustomers,
	|	TtToCalculate.AccountingDimensionByPartners,
	|	TtToCalculate.ARAPObject,
	|	TtToCalculate.Currency,
	|	TtToCalculate.ARAPDocument,
	|	TtToCalculate.PlannedRepaymentDate,
	|	TtToCalculate.OccurrenceDate,
	|	TtToCalculate.ContractRateOption,
	|	TtToCalculate.PrepaymentBalance,
	|	TtToCalculate.PrepaymentLocalBalance,
	|	TtToCalculate.PrepaymentManBalance,
	|	TtToCalculate.DebtLocalBalance,
	|	TtToCalculate.DebtLocalBalanceSettlement,
	|	TtToCalculate.ARAPManBalance,
	|	TtToCalculate.ManSDebtSettlementBalance";
	#EndRegion

	Query.SetParameter("TheseAreSettlementsWithCustomers", TheseAreSettlementsWithCustomers);
	If TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText, "#TableName", Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.FullName());
		Query.SetParameter("ApplyingPrepayment", Enums.BusinessTransactions.CustomerPrepaymentSettlement);
		Query.SetParameter("PaymentType_", Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	Else
		QueryText = StrReplace(QueryText, "#TableName", Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.FullName());
		Query.SetParameter("ApplyingPrepayment", Enums.BusinessTransactions.VendorPrepaymentSettlement);
		Query.SetParameter("PaymentType_", Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
		QueryText = StrReplace(QueryText, 
				Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.FullName(),
				Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.FullName());
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("CompanyArray", CompanyArray);
	Query.SetParameter("ManagementAccountingCurrency", Parameters.ManagementAccountingCurrency);
	
	BorderEndOfDay = New Boundary(EndOfDay(Period),BoundaryType.Including);
	Query.SetParameter("BeginOfPeriod", BegOfDay(Period));
	Query.SetParameter("EndOfPeriod", EndOfDay(Period));
	Query.SetParameter("BorderEndOfDay", BorderEndOfDay);
	Query.SetParameter("DateOfCalculation", Period);
	Query.SetParameter("PortionSize", OnlineARAPAccountingServer.RecordPortionSize());
	If RevaluationByDays = Undefined Then
		RevaluationByDays = Constants.RevalueCurrencyByDays.Get();
	EndIf;
	Query.SetParameter("RevaluationByDays", RevaluationByDays);
	
	QueryResults = Query.ExecuteBatch();
	LastIndex = QueryResults.UBound();
	SearchFields = "TheseAreSettlementsWithCustomers, AccountingDimensionByPartners, ARAPObject, Currency"; 
	ObjectsToRevaluation = QueryResults[LastIndex-1].Unload();
	Parameters.ProcessedItemsTotal = Parameters.ProcessedItemsTotal + ObjectsToRevaluation.Count();
	DetailedRecords    = QueryResults[LastIndex].Unload();
	DetailedRecords.Indexes.Add(SearchFields);
	ExchangeRateDifferencesForDeletion = QueryResults[LastIndex-2].Unload();
	SettlementRegistrars = QueryResults[LastIndex-3].Unload();
	SettlementRegistrars.Indexes.Add(SearchFields);
	TheStructureOfTheSearch = New Structure(SearchFields);
	
	Order = OnlineARAPAccountingServer.Order(Period,"",Type("DocumentRef.ExchangeDifferenceCalculation"),"9","99");
	RecordPortionSize = OnlineARAPAccountingServer.RecordPortionSize();
	
	ChangesTable = New ValueTable;
	ChangesTable.Columns.Add("Recorder", Documents.AllRefsType());
	ChangesTable.Columns.Add("Period", New TypeDescription("Date"));
	ChangesTable.Columns.Add("AccountingDimensionByPartners", New TypeDescription("CatalogRef.DimensionKeysOfAccountingByPartners"));
	ContractWithConsignor = Enums.ContractTypes.WithConsignor;
	If TheseAreSettlementsWithCustomers Then
		RevaluationIsPositive 	= Enums.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain;
		RevaluationNegative 	= Enums.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss;
		RevaluationPositiveCat 	= Catalogs.BusinessTransactionsSettings.ExchangeDifferencesCustomersExchangeGain;
		RevaluationNegativeCat 	= Catalogs.BusinessTransactionsSettings.ExchangeDifferencesCustomersExchangeLoss;
		RecordSet = AccumulationRegisters.CustomersARAPAccountingByDueDates.CreateRecordSet();
	Else
		RevaluationIsPositive 	= Enums.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss;
		RevaluationNegative 	= Enums.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain;
		RevaluationPositiveCat 	= Catalogs.BusinessTransactionsSettings.ExchangeDifferencesVendorsExchangeLoss;
		RevaluationNegativeCat 	= Catalogs.BusinessTransactionsSettings.ExchangeDifferencesVendorsExchangeGain;
		RecordSet = AccumulationRegisters.VendorsARAPAccountingByDueDates.CreateRecordSet();
	EndIf;
	RecordSet.AdditionalProperties.Insert("CheckCaseChanges", True);
	For Each RevaluationLine In ObjectsToRevaluation Do

		If Parameters.RevaluationDocuments.Count() = 1 Then
			DocumentRecorder = Parameters.RevaluationDocuments[0].Ref; //DocumentRef
		Else
			DocumentSearchStructure = New Structure("Date, Organization", BegOfMonth(Period), RevaluationLine.Organization);
			FoundDocuments = Parameters.RevaluationDocuments.FindRows(DocumentSearchStructure);// Array of ValueTableRow
			DocumentRecorder = FoundDocuments[0].Ref; //DocumentRef
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, RevaluationLine);
		RowsOfDetailedRecords = DetailedRecords.FindRows(TheStructureOfTheSearch);

		NwRw = ChangesTable.Add();
		NwRw.Recorder = DocumentRecorder;
		NwRw.Period = BegOfDay(Period);
		NwRw.AccountingDimensionByPartners = RevaluationLine.AccountingDimensionByPartners;
		If RowsOfDetailedRecords.Count() > 0 And Not Parameters.ReFillingTARegisters Then
			TableOfFreeRegistrars = ExchangeRateDifferenceRecorders(RevaluationLine, SettlementRegistrars, RowsOfDetailedRecords.Count() * 4);
			AccountLogger = 0;
			NumberOfLines_1 = 0;
			
			ARAPAccountingRecorder = TableOfFreeRegistrars[AccountLogger].Ref;
			RecordSet.Filter.Recorder.Set(ARAPAccountingRecorder);
			RecordSet.Read();
			DeleteExchangeDifferencesPerDay(Period, RecordSet);
			RowToDelete = ExchangeRateDifferencesForDeletion.Find(ARAPAccountingRecorder,"Recorder");
			If RowToDelete <> Undefined Then
				ExchangeRateDifferencesForDeletion.Delete(RowToDelete);
			EndIf;
			
			For Each RowOfDetailedRecords In RowsOfDetailedRecords Do
				
				#Region PositiveExchangeRateDifference
				If RowOfDetailedRecords.DebtLocalBalance < RowOfDetailedRecords.DebtLocalBalanceSettlement 
					Or RowOfDetailedRecords.ARAPManBalance < RowOfDetailedRecords.ManSDebtSettlementBalance Then
					NwRw = RecordSet.Add();
					FillPropertyValues(NwRw, RowOfDetailedRecords);
					
					NwRw.Recorder           = TableOfFreeRegistrars[AccountLogger].Ref;
					NwRw.DocumentRecorder   = DocumentRecorder;
					NwRw.Period                = EndOfDay(Period);
					NwRw.OperationProcedure       = Order;
					NwRw.SettlementProcedure         = Order;
					NwRw.RecordType           = AccumulationRecordType.Receipt;
					NwRw.BusinessOperation = RevaluationIsPositive;
					NwRw.Currency                = RowOfDetailedRecords.Currency;
					NwRw.BusinessTransactionSetting 	= RevaluationPositiveCat;
					NwRw.FinRecordID			= String(New UUID);
					NwRw.SettlementRecordType			= Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtIncrease;

					If RowOfDetailedRecords.DebtLocalBalance < RowOfDetailedRecords.DebtLocalBalanceSettlement Then
						NwRw.DebtLocal = RowOfDetailedRecords.DebtLocalBalanceSettlement - RowOfDetailedRecords.DebtLocalBalance;
					EndIf;
					If RowOfDetailedRecords.ARAPManBalance < RowOfDetailedRecords.ManSDebtSettlementBalance Then
						NwRw.ARAPMan = RowOfDetailedRecords.ManSDebtSettlementBalance - RowOfDetailedRecords.ARAPManBalance;
					EndIf;
					
					NumberOfLines_1 = NumberOfLines_1 + 1;
					If NumberOfLines_1 = RecordPortionSize Then
						NumberOfLines_1 = 0;
						AccountLogger = AccountLogger + 1;
						RecordSet.Write();
						RecordSet.Filter.Recorder.Set(TableOfFreeRegistrars[AccountLogger].Ref);
						RecordSet.Read();
					EndIf;
					
				EndIf;
				#EndRegion
				
				#Region NegativeExchangeRateDifference
				If RowOfDetailedRecords.DebtLocalBalance > RowOfDetailedRecords.DebtLocalBalanceSettlement 
					Or RowOfDetailedRecords.ARAPManBalance > RowOfDetailedRecords.ManSDebtSettlementBalance Then
					NwRw = RecordSet.Add();
					FillPropertyValues(NwRw, RowOfDetailedRecords);
					
					NwRw.Recorder           = TableOfFreeRegistrars[AccountLogger].Ref;
					NwRw.DocumentRecorder   = DocumentRecorder;
					NwRw.Period                = EndOfDay(Period);
					NwRw.OperationProcedure       = Order;
					NwRw.SettlementProcedure         = Order;
					NwRw.RecordType           = AccumulationRecordType.Expense;
					NwRw.BusinessOperation = RevaluationNegative;
					NwRw.Currency                = RowOfDetailedRecords.Currency;
					NwRw.BusinessTransactionSetting 	= RevaluationNegativeCat;
					NwRw.FinRecordID			= String(New UUID);
					NwRw.SettlementRecordType			= Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtDecrease;

					If RowOfDetailedRecords.DebtLocalBalance > RowOfDetailedRecords.DebtLocalBalanceSettlement Then
						NwRw.DebtLocal = RowOfDetailedRecords.DebtLocalBalance - RowOfDetailedRecords.DebtLocalBalanceSettlement;
					EndIf;
					If RowOfDetailedRecords.ARAPManBalance > RowOfDetailedRecords.ManSDebtSettlementBalance Then
						NwRw.ARAPMan = RowOfDetailedRecords.ARAPManBalance - RowOfDetailedRecords.ManSDebtSettlementBalance;
					EndIf;
					
					NumberOfLines_1 = NumberOfLines_1 + 1;
					If NumberOfLines_1 = RecordPortionSize Then
						NumberOfLines_1 = 0;
						AccountLogger = AccountLogger + 1;
						RecordSet.Write();
						RecordSet.Filter.Recorder.Set(TableOfFreeRegistrars[AccountLogger].Ref);
						RecordSet.Read();
					EndIf;
					
				EndIf;
				#EndRegion
				
				#Region AdjustmentOfPrepaymentToZero
				If RowOfDetailedRecords.PrepaymentBalance = 0
					And (RowOfDetailedRecords.PrepaymentLocalBalance > 0
						Or RowOfDetailedRecords.PrepaymentManBalance > 0) Then
					
					NwRw = RecordSet.Add();
					FillPropertyValues(NwRw, RowOfDetailedRecords);
					
					NwRw.Recorder           = TableOfFreeRegistrars[AccountLogger].Ref;
					NwRw.DocumentRecorder   = DocumentRecorder;
					NwRw.Period                = EndOfDay(Period);
					NwRw.OperationProcedure       = Order;
					NwRw.SettlementProcedure         = Order;
					NwRw.RecordType           = AccumulationRecordType.Expense;
					NwRw.BusinessOperation = RevaluationIsPositive;
					NwRw.Currency                = RowOfDetailedRecords.Currency;
					NwRw.BusinessTransactionSetting 	= RevaluationPositiveCat;
					NwRw.FinRecordID			= String(New UUID);
					NwRw.SettlementRecordType			= Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentDecrease;

					If RowOfDetailedRecords.PrepaymentLocalBalance > 0 Then
						NwRw.PrepaymentLocal = RowOfDetailedRecords.PrepaymentLocalBalance;
					EndIf;
					If RowOfDetailedRecords.PrepaymentManBalance > 0 Then
						NwRw.PrepaymentMan = RowOfDetailedRecords.PrepaymentManBalance;
					EndIf;
					
					NumberOfLines_1 = NumberOfLines_1 + 1;
					If NumberOfLines_1 = RecordPortionSize Then
						NumberOfLines_1 = 0;
						AccountLogger = AccountLogger + 1;
						RecordSet.Write();
						RecordSet.Filter.Recorder.Set(TableOfFreeRegistrars[AccountLogger].Ref);
						RecordSet.Read();
					EndIf;
					
				EndIf;
				
				If RowOfDetailedRecords.PrepaymentBalance = 0
					And (RowOfDetailedRecords.PrepaymentLocalBalance < 0
						Or RowOfDetailedRecords.PrepaymentManBalance < 0) Then
					
					NwRw = RecordSet.Add();
					FillPropertyValues(NwRw, RowOfDetailedRecords);
					
					NwRw.Recorder           = TableOfFreeRegistrars[AccountLogger].Ref;
					NwRw.DocumentRecorder   = DocumentRecorder;
					NwRw.Period                = BegOfDay(Period);
					NwRw.OperationProcedure       = Order;
					NwRw.SettlementProcedure         = Order;
					NwRw.RecordType           = AccumulationRecordType.Receipt;
					NwRw.BusinessOperation = RevaluationNegative;
					NwRw.Currency                = RowOfDetailedRecords.Currency;
					NwRw.BusinessTransactionSetting 	= RevaluationNegativeCat;
					NwRw.FinRecordID			= String(New UUID);
					NwRw.SettlementRecordType			= Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease;
					
					If RowOfDetailedRecords.PrepaymentLocalBalance < 0 Then
						NwRw.PrepaymentLocal = -RowOfDetailedRecords.PrepaymentLocalBalance;
					EndIf;
					If RowOfDetailedRecords.PrepaymentManBalance < 0 Then
						NwRw.PrepaymentMan = -RowOfDetailedRecords.PrepaymentManBalance;
					EndIf;
					
					NumberOfLines_1 = NumberOfLines_1 + 1;
					If NumberOfLines_1 = RecordPortionSize Then
						NumberOfLines_1 = 0;
						AccountLogger = AccountLogger + 1;
						RecordSet.Write();
						RecordSet.Filter.Recorder.Set(TableOfFreeRegistrars[AccountLogger].Ref);
						RecordSet.Read();
					EndIf;
					
				EndIf;
				#EndRegion
				
			EndDo;
			RecordSet.Write();
		EndIf;

	EndDo; //by objects of revaluation
	

	For Each RowToDelete In ExchangeRateDifferencesForDeletion Do
		
		If RowToDelete.TheseAreSettlementsWithCustomers Then
			RecordSet = AccumulationRegisters.CustomersARAPAccountingByDueDates.CreateRecordSet();
		Else
			RecordSet = AccumulationRegisters.VendorsARAPAccountingByDueDates.CreateRecordSet();
		EndIf;
		RecordSet.AdditionalProperties.Insert("CheckCaseChanges", True);
		
		RecordSet.Filter.Recorder.Set(RowToDelete.Recorder);
		RecordSet.Read();
		If DeleteExchangeDifferencesPerDay(Period, RecordSet) Then
			RecordSet.Write(); //remove the old exchange rate differences
		EndIf;
	EndDo;

	CollapseFields = "Recorder";
	CollapseFields = "Recorder, Period, AccountingDimensionByPartners";
	ChangesTable.GroupBy(CollapseFields);
	LocalAccntingServer.RegisterDocumentsOfSettlementsWithPartnersForReflectionInLocalAccounting(ChangesTable);
	FinancialAccountingPostingServer.RegisterDocumentsOfSettlementsWithPartnersForReflectionInInternationalAccounting(ChangesTable);

	If TheseAreSettlementsWithCustomers <> Undefined Then
		For Each Organization In CompanyArray Do
			
			DocumentsForCalculatingExchangeDifferences = Documents.ExchangeDifferenceCalculation.RevaluationDocuments(Organization,
				Period, Period,
				TheseAreSettlementsWithCustomers);
			DocumentRecorder = DocumentsForCalculatingExchangeDifferences[BegOfMonth(Period)];
			
			If TheseAreSettlementsWithCustomers Then
				SetOfRegisteredRecordsOnDocuments = AccumulationRegisters.CustomersARAPAccountingByDocuments.CreateRecordSet();
			Else
				SetOfRegisteredRecordsOnDocuments = AccumulationRegisters.VendorsARAPAccountingByDocuments.CreateRecordSet();
			EndIf;
			
			SetOfRegisteredRecordsOnDocuments.Filter.Recorder.Set(DocumentRecorder);
			SetOfRegisteredRecordsOnDocuments.Read();
			If SetOfRegisteredRecordsOnDocuments.Count() > 0 Then
				SetOfRegisteredRecordsOnDocuments.Clear();
				SetOfRegisteredRecordsOnDocuments.Write();
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Function DeleteExchangeDifferencesPerDay(Period, RecordSet)
	
	IndexOf = 0;
	ThereWasDeletion = False;
	While IndexOf < RecordSet.Count() Do
		Record = RecordSet[IndexOf];
		
		If BegOfDay(Record.Period) = BegOfDay(Period)
			And TypeOf(Record.DocumentRecorder) = Type("DocumentRef.ExchangeDifferenceCalculation") Then
			RecordSet.Delete(Record);
			ThereWasDeletion = True;
			Continue;
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
	Return ThereWasDeletion;
	
EndFunction

// Deletes the Registered Record of exchange rate differences for the period only for those days
// for which there will be no more revaluation in the Cur period.
// For example, a payment was made on a different date and there are no more objects for revaluation on the Cur date
// , or there was a revaluation mode by day, but the revaluation mode became on the payment date and the end of the month.
// 
Procedure DeleteExchangeDifferencesForPeriod(CompanyArray, BeginOfPeriod, EndOfPeriod, Parameters)
	
	If Parameters.TheseAreSettlementsWithCustomers = Undefined Then
		MeasurementName = "ARAPAccounting.CalculationOfExchangeDifferencesByTerms.Delete";
	Else
		MeasurementName = "ARAPAccounting.CalculationOfExchangeDifferencesByTerms" + ?(Parameters.TheseAreSettlementsWithCustomers,".Customers",".Vendors")+".Delete";
	EndIf;
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(MeasurementName);
	
	#Region QueryText
	QueryText = 
	"SELECT
	|	DaysOfReassessment.Date AS Date
	|INTO TTRevaluationDays
	|FROM
	|	&DaysOfReassessment AS DaysOfReassessment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Days when there are no exchange rate differences - days in which there will be no exchange rate Registered Records during the new calculation
	|SELECT
	|	NestedQuery.Date AS Date,
	|	SUM(NestedQuery.PreviousRevaluation) AS PreviousRevaluation
	|INTO TTPreviousRevaluation
	|FROM
	|	(SELECT
	|		DaysOfReassessment.Date AS Date,
	|		1 AS PreviousRevaluation
	|	FROM
	|		TTRevaluationDays AS DaysOfReassessment
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		BEGINOFPERIOD(Calculations.Period, DAY) AS Date,
	|		-1 AS PreviousRevaluation
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|			LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			ON Calculations.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|			LEFT JOIN Catalog.Companies AS Companies
	|			ON (DimensionKeysOfAccountingByPartners.Organization = Companies.Ref)
	|	WHERE
	|		Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Companies.Ref IN(&Companies)
	|		AND Calculations.DocumentRecorder REFS Document.ExchangeDifferenceCalculation
	|) AS NestedQuery
	|GROUP BY
	|	NestedQuery.Date
	|HAVING
	|	SUM(NestedQuery.PreviousRevaluation) = -1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Recorders of settlements for the specified period, which have Registered Records of exchange rate differences
	// , provided that there are dates when there are no exchange rate differences
	|SELECT DISTINCT
	|	&TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
	|	CalculationsByTerms.Recorder AS ARAPAccountingRecorder,
	|	COUNT(Revaluation.Date) AS DatesOfAbsenceOfExchangeDifferences
	|INTO TTSettlementLoggers
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeys
	|	ON CalculationsByTerms.AccountingDimensionByPartners = DimensionKeys.Ref
	|	LEFT JOIN TTPreviousRevaluation AS Revaluation
	|	ON TRUE
	|WHERE
	|	CalculationsByTerms.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DimensionKeys.Organization IN (&Companies)
	|	AND VALUETYPE(CalculationsByTerms.DocumentRecorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|GROUP BY
	|	CalculationsByTerms.Recorder
	|HAVING
	|	COUNT(Revaluation.Date) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// All Registered Records of the calculation Recorders, except for the Registered Records of exchange rate differences on the days of absence
	|SELECT
	|	&TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
	|	*
	|INTO TTMotionRecorders
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS SettlementsWithByTerms
	|		INNER JOIN TTSettlementLoggers AS SettlementRegistrars
	|		ON SettlementsWithByTerms.Recorder = SettlementRegistrars.ARAPAccountingRecorder
	|WHERE
	|	NOT (VALUETYPE(SettlementsWithByTerms.DocumentRecorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|		AND BEGINOFPERIOD(SettlementsWithByTerms.Period, DAY) IN (SELECT Date FROM TTPreviousRevaluation))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Recorders of calculations that were left without RegisteringRecords
	|SELECT
	|	SettlementRegistrars.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers,
	|	SettlementRegistrars.ARAPAccountingRecorder AS Recorder
	|FROM
	|	TTSettlementLoggers AS SettlementRegistrars
	|		LEFT JOIN TTMotionRecorders AS LoggerRegisteredRecords_
	|		ON SettlementRegistrars.ARAPAccountingRecorder = LoggerRegisteredRecords_.Recorder
	|WHERE
	|	LoggerRegisteredRecords_.Recorder IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	*
	|FROM
	|	TTMotionRecorders AS LoggerRegisteredRecords_
	|
	|TOTALS
	|	MAX(TheseAreSettlementsWithCustomers)
	|BY
	|	Recorder";
	#EndRegion
	
	If Not Parameters.TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText, 
				Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.FullName(),
				Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.FullName());
	EndIf;
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DaysOfReassessment", Parameters.DaysOfReassessment);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("Companies", CompanyArray);
	Query.SetParameter("TheseAreSettlementsWithCustomers", Parameters.TheseAreSettlementsWithCustomers);
	PackageResult = Query.ExecuteBatch();
	LastPackage_ = PackageResult.UBound();
	
	Selection = PackageResult[LastPackage_].Select(QueryResultIteration.ByGroups);
	ProcessedItemsTotal = 0;
	While Selection.Next() Do
		If Selection.TheseAreSettlementsWithCustomers Then
			RecordSet = AccumulationRegisters.CustomersARAPAccountingByDueDates.CreateRecordSet();
		Else
			RecordSet = AccumulationRegisters.VendorsARAPAccountingByDueDates.CreateRecordSet();
		EndIf;
		RecordSet.Filter.Recorder.Set(Selection.Recorder);
		RegisterRecords = Selection.Select();
		While RegisterRecords.Next() Do
			FillPropertyValues(RecordSet.Add(), RegisterRecords);
		EndDo;
		RecordSet.Write();
 		ProcessedItemsTotal = ProcessedItemsTotal + 1;
	EndDo;
	
	// Registrars who remained motionless
	Selection = PackageResult[LastPackage_-1].Select();
	While Selection.Next() Do
		If Selection.TheseAreSettlementsWithCustomers Then
			RecordSet = AccumulationRegisters.CustomersARAPAccountingByDueDates.CreateRecordSet();
		Else
			RecordSet = AccumulationRegisters.VendorsARAPAccountingByDueDates.CreateRecordSet();
		EndIf;
		RecordSet.Filter.Recorder.Set(Selection.Recorder);
		RecordSet.Write();
		ProcessedItemsTotal = ProcessedItemsTotal + 1;
	EndDo;
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, ProcessedItemsTotal);
	
EndProcedure

Function DaysOfReassessment(CompanyArray, BeginOfPeriod, EndOfPeriod, Parameters)
	
	#Region QueryText
	QueryText = "
	|SELECT DISTINCT
	|	Calculations.Currency AS Currency,
	|	BEGINOFPERIOD(Calculations.Period, DAY) AS Period
	|INTO TTCurrencyTurnover
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|	LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|		ON Calculations.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|
	|	LEFT JOIN Catalog.Companies AS Companies
	|		ON DimensionKeysOfAccountingByPartners.Organization = Companies.Ref
	|WHERE
	|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Companies.Ref IN (&Companies)
	|	AND (Calculations.Currency <> &ManagementAccountingCurrency OR Calculations.Currency <> Companies.LocalAccountingCurrency)
	|	AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND Calculations.Debt <> 0
	|;";
	If Not Parameters.TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText, 
				Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.FullName(),
				Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.FullName());
	EndIf;
	QueryText = QueryText + "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTCurrencyTurnover.Period AS Date
	|FROM
	|	TTCurrencyTurnover AS TTCurrencyTurnover
	|
	|UNION
	|
	|SELECT DISTINCT
	|	ExchangeRates.Period
	|FROM
	|	InformationRegister.RelativeExchangeRates AS ExchangeRates
	|WHERE
	|	ExchangeRates.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND &RevaluationByDays
	|
	|UNION
	|
	|SELECT
	|	BEGINOFPERIOD(&EndOfPeriod, DAY)
	|
	|ORDER BY
	|	Date";
	#EndRegion
	
	Query = New Query(QueryText);
	Query.SetParameter("BeginOfPeriod", BegOfDay(BeginOfPeriod));
	Query.SetParameter("EndOfPeriod",  EndOfDay(EndOfPeriod));
	Query.SetParameter("Companies",   CompanyArray);
	Query.SetParameter("ManagementAccountingCurrency",  Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("RevaluationByDays",  Parameters.RevaluationByDays);
	
	Selection = Query.Execute().Unload();
	
	Return Selection;
	
EndFunction

Function ExchangeRateDifferenceRecorders(CurrentParameters, SettlementRegistrars, RecordsCount)
	
	If RecordsCount = 0 Then
		NumberOfRegistrars = 0;
	Else
		NumberOfRegistrars = Int(RecordsCount/OnlineARAPAccountingServer.RecordPortionSize()) + 1;
	EndIf;
	
	Filter = New Structure("ARAPObject,AccountingDimensionByPartners,Currency,TheseAreSettlementsWithCustomers");
	FillPropertyValues(Filter, CurrentParameters);
	
	PaymentType_ = ?(CurrentParameters.TheseAreSettlementsWithCustomers, Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting, Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
	DocumentsTable = SettlementRegistrars.Copy(Filter); // See.FreeSettlementRegistrars
	
	While DocumentsTable.Count() < NumberOfRegistrars Do
		DocumentObject = Documents.ARAPAccountingRecorder.CreateDocument();
		DocumentObject.Currency = CurrentParameters.Currency;
		DocumentObject.AccountingDimensionByPartners = CurrentParameters.AccountingDimensionByPartners;
		DocumentObject.Organization = CurrentParameters.Organization;
		DocumentObject.ARAPObject = CurrentParameters.ARAPObject;
		DocumentObject.PaymentType_ = PaymentType_;
		DocumentObject.Date = CurrentSessionDate();
		DocumentObject.Write(DocumentWriteMode.Posting);
		
		NwRw = DocumentsTable.Add();
		NwRw.Ref = DocumentObject.Ref;
	EndDo;
	
	Return DocumentsTable;
	
EndFunction


#EndRegion

