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
	
	DocumentMechanisms.Add("DocumentsRegistry");
	
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
//     * Table_RegisterName - ValueTable - the data table to be reflected in the register (instead of the _register name, the name of the register itself is substituted).
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.PeriodEndTransactionFinancialAccounting") Then
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
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
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
	
	If AccessRight("Insert", Metadata.Documents.PeriodEndTransactionFinancialAccounting) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PeriodEndTransactionFinancialAccounting.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PeriodEndTransactionFinancialAccounting);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseFinancialAccounting";
	EndIf;
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Return; //In the future, the command code will be added
	
EndProcedure

// Determines the number of all currency balances for which exchange differences are not calculated.
// (Staticvalue*Exchange Rate Of The Functional Currency <> Remaining Functional Currency).
//
// Parameters:
//  ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - The chart of accounts, which are selected currency balances.
//  Companies - Array of CatalogRef.Companies -
//              - CatalogRef.Companies - Selection of organizations for which currency balances are determined.
//  OnDate - Date - The date on which the functional currency balances and exchange rate are determined. If not set, then the current one.
//  OnlyFirst_ - Boolean - True if you only need to check that there is no need to calculate exchange rate differences.
//
// Returns:
//  Number - the number of balances that have discrepancies between the calculated and actual balances in the functional currency.
//
Function UncoveredExchangeDifferences(ChartOfAccounts, Companies, Val OnDate = Undefined, OnlyFirst_ = False) Export
	
	QueryText = 
	"SELECT
	|	RelativeExchangeRates.BaseCurrency AS BaseCurrency,
	|	RelativeExchangeRates.Currency AS Currency,
	|	RelativeExchangeRates.CourseNumerator AS CourseNumerator,
	|	RelativeExchangeRates.CourseDenominator AS CourseDenominator
	|INTO TTExchangeRates_
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&OnDate,
	|			BaseCurrency IN (
	|				SELECT
	|					Companies.LocalAccountingCurrency AS LocalAccountingCurrency
	|				FROM
	|					Catalog.Companies AS Companies
	|				WHERE
	|					Companies.Ref IN (&Companies))) AS RelativeExchangeRates
	|INDEX BY
	|	BaseCurrency,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InternationalBalance.Account,
	|	InternationalBalance.ChartOfAccounts,
	|	InternationalBalance.Organization,
	|	InternationalBalance.Department,
	|	InternationalBalance.LineOfBusiness,
	|	InternationalBalance.Currency,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN InternationalBalance.ExtDimension1
	|		ELSE NULL
	|	END AS ExtDimension1,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN InternationalBalance.ExtDimension2
	|		ELSE NULL
	|	END AS ExtDimension2,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN InternationalBalance.ExtDimension3
	|		ELSE NULL
	|	END AS ExtDimension3,
	|	SUM(InternationalBalance.SumBalance) AS SumBalance,
	|	SUM(InternationalBalance.SumSplittedBalanceDr) AS SumBalanceDr,
	|	SUM(InternationalBalance.SumSplittedBalanceCr) AS SumBalanceCr,
	|	SUM(InternationalBalance.CurrencyAmountBalance) AS CurrencyAmountBalance
	|INTO TTAccountBalances
	|FROM
	|	AccountingRegister.International.Balance(
	|			&Boundary,
	|			Account.Currency1 AND NOT Account.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency,
	|			,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization IN (&Companies)) AS InternationalBalance
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay1
	|		ON InternationalBalance.Account = InternationalExtdimensionDay1.Ref
	|			AND (InternationalExtdimensionDay1.LineNumber = 1)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay2
	|		ON InternationalBalance.Account = InternationalExtdimensionDay2.Ref
	|			AND (InternationalExtdimensionDay2.LineNumber = 2)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay3
	|		ON InternationalBalance.Account = InternationalExtdimensionDay3.Ref
	|			AND (InternationalExtdimensionDay3.LineNumber = 3)
	|
	|GROUP BY
	|	InternationalBalance.Account,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN InternationalBalance.ExtDimension1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN InternationalBalance.ExtDimension2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN InternationalBalance.ExtDimension3
	|		ELSE NULL
	|	END,
	|	InternationalBalance.ChartOfAccounts,
	|	InternationalBalance.Organization,
	|	InternationalBalance.Department,
	|	InternationalBalance.LineOfBusiness,
	|	InternationalBalance.Currency
	|
	|UNION ALL
	|
	|SELECT
	|	AccountBalances.Account,
	|	AccountBalances.ChartOfAccounts,
	|	AccountBalances.Organization,
	|	AccountBalances.Department,
	|	AccountBalances.LineOfBusiness,
	|	AccountBalances.Currency,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN AccountBalances.ExtDimension1
	|		ELSE NULL
	|	END AS ExtDimension1,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN AccountBalances.ExtDimension2
	|		ELSE NULL
	|	END AS ExtDimension2,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN AccountBalances.ExtDimension3
	|		ELSE NULL
	|	END AS ExtDimension3,
	|	SUM(AccountBalances.SumBalance) AS SumBalance,
	|	SUM(AccountBalances.SumSplittedBalanceDr) AS SumBalanceDr,
	|	SUM(AccountBalances.SumSplittedBalanceCr) AS SumBalanceCr,
	|	SUM(AccountBalances.CurrencyAmountBalance) AS CurrencyAmountBalance
	|FROM
	|	AccountingRegister.InternationalWithoutCorrespondence.Balance(
	|			&Boundary,
	|			Account.Currency1 AND NOT Account.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency,
	|			,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization IN (&Companies)) AS AccountBalances
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay1
	|		ON AccountBalances.Account = InternationalExtdimensionDay1.Ref
	|			AND (InternationalExtdimensionDay1.LineNumber = 1)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay2
	|		ON AccountBalances.Account = InternationalExtdimensionDay2.Ref
	|			AND (InternationalExtdimensionDay2.LineNumber = 2)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay3
	|		ON AccountBalances.Account = InternationalExtdimensionDay3.Ref
	|			AND (InternationalExtdimensionDay3.LineNumber = 3)
	|
	|GROUP BY
	|	AccountBalances.Account,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN AccountBalances.ExtDimension1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN AccountBalances.ExtDimension2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN AccountBalances.ExtDimension3
	|		ELSE NULL
	|	END,
	|	AccountBalances.ChartOfAccounts,
	|	AccountBalances.Organization,
	|	AccountBalances.Department,
	|	AccountBalances.LineOfBusiness,
	|	AccountBalances.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract AS Contract,
	|	ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator AS CourseNumerator,
	|	ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator AS CourseDenominator
	|INTO TTExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|
	|FROM
	|	InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&OnDate, ) AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|INDEX BY
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAccountBalances.ExtDimension1 AS ExtDimension
	|INTO TTBalancesOfAccountsAllExtDimension
	|FROM
	|	TTAccountBalances
	|	
	|UNION ALL
	|		
	|SELECT
	|	TTAccountBalances.ExtDimension2
	|FROM
	|	TTAccountBalances
	|		
	|UNION ALL
	|		
	|SELECT
	|	TTAccountBalances.ExtDimension3
	|FROM
	|	TTAccountBalances	
	|
	|INDEX BY
	|	ExtDimension
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CounterpartyContracts.Ref                                             AS Contract,
	|	CounterpartyContracts.ContractRateOption                               AS ContractRateOption,
	|	CounterpartyContracts.ARAPCurrency                               AS ARAPCurrency,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator, 1)   AS CourseNumerator,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator, 1) AS CourseDenominator
	|INTO TTContracts
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|		
	|		LEFT JOIN TTExchangeRatesOfSettlementsUnderContractsCutOfLatest AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|		ON CounterpartyContracts.Ref = ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract
	|		
	|		INNER JOIN TTBalancesOfAccountsAllExtDimension AS TTBalancesOfAccountsAllExtDimension
	|		ON TTBalancesOfAccountsAllExtDimension.ExtDimension = CounterpartyContracts.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	IntercompanyContracts.Ref                                       AS Contract,
	|	IntercompanyContracts.ContractRateOption                         AS ContractRateOption,
	|	IntercompanyContracts.ARAPCurrency                         AS ARAPCurrency,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator, 1)   AS CourseNumerator,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator, 1) AS CourseDenominator
	|FROM
	|	Catalog.IntercompanyContracts AS IntercompanyContracts
	|		
	|		LEFT JOIN TTExchangeRatesOfSettlementsUnderContractsCutOfLatest AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|		ON IntercompanyContracts.Ref = ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract
	|		
	|		INNER JOIN TTBalancesOfAccountsAllExtDimension AS TTBalancesOfAccountsAllExtDimension
	|		ON TTBalancesOfAccountsAllExtDimension.ExtDimension = IntercompanyContracts.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountBalances.Account                                                AS Account,
	|	AccountBalances.ChartOfAccounts                                          AS ChartOfAccounts,
	|	AccountBalances.Organization                                         AS Organization,
	|	AccountBalances.Department                                       AS Department,
	|	AccountBalances.LineOfBusiness                             AS LineOfBusiness,
	|	AccountBalances.ExtDimension1                                           AS ExtDimension1,
	|	AccountBalances.ExtDimension2                                           AS ExtDimension2,
	|	AccountBalances.ExtDimension3                                           AS ExtDimension3,
	|	AccountBalances.Currency                                              AS Currency,
	|	AccountBalances.CurrencyAmountBalance                                AS CurrencyAmountBalance,
	|	AccountBalances.SumBalance                                        AS SumBalance,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.ContractRateOption,
	|			TTContracts2.ContractRateOption),
	|		ISNULL(
	|			TTContracts3.ContractRateOption,
	|			VALUE(Enum.ContractRateOptions.Mutable))) AS ContractRateOption,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.CourseNumerator,
	|			TTContracts2.CourseNumerator),
	|		ISNULL(
	|			TTContracts3.CourseNumerator,
	|			1))                                                       AS CourseNumerator,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.CourseDenominator,
	|			TTContracts2.CourseDenominator),
	|		ISNULL(
	|			TTContracts3.CourseDenominator,
	|			1))                                                       AS CourseDenominator,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.ARAPCurrency,
	|			TTContracts2.ARAPCurrency),
	|		ISNULL(
	|			TTContracts3.ARAPCurrency,
	|			UNDEFINED))                                            AS ARAPCurrency
	|INTO AccountBalancesWithContractExchangeRateTT
	|FROM
	|	TTAccountBalances AS AccountBalances
	|		LEFT JOIN TTContracts AS TTContracts1
	|		ON AccountBalances.ExtDimension1 = TTContracts1.Contract
	|		LEFT JOIN TTContracts AS TTContracts2
	|		ON AccountBalances.ExtDimension2 = TTContracts2.Contract
	|		LEFT JOIN TTContracts AS TTContracts3
	|		ON AccountBalances.ExtDimension3 = TTContracts3.Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTBalancesWithRateOfContract.Account                    AS Account,
	|	TTBalancesWithRateOfContract.ChartOfAccounts              AS ChartOfAccounts,
	|	TTBalancesWithRateOfContract.Organization             AS Organization,
	|	TTBalancesWithRateOfContract.Department           AS Department,
	|	TTBalancesWithRateOfContract.LineOfBusiness AS LineOfBusiness,
	|	TTBalancesWithRateOfContract.ExtDimension1               AS ExtDimension1,
	|	TTBalancesWithRateOfContract.ExtDimension2               AS ExtDimension2,
	|	TTBalancesWithRateOfContract.ExtDimension3               AS ExtDimension3,
	|	TTBalancesWithRateOfContract.Currency                  AS Currency,
	|	TTBalancesWithRateOfContract.CurrencyAmountBalance    AS CurrencyAmountBalance,
	|	TTBalancesWithRateOfContract.SumBalance            AS SumBalance,
	|	TTBalancesWithRateOfContract.ContractRateOption    AS ContractRateOption,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND TTBalancesWithRateOfContract.Currency = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseNumerator
	|		ELSE TTExchangeRates_.CourseNumerator
	|	END                                            AS CourseNumerator,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND TTBalancesWithRateOfContract.Currency = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseDenominator
	|		ELSE TTExchangeRates_.CourseDenominator
	|	END                                            AS CourseDenominator,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND CASE
	|					WHEN TTBalancesWithRateOfContract.ChartOfAccounts.AccountingInFunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal)
	|						THEN TTBalancesWithRateOfContract.Organization.LocalAccountingCurrency
	|					ELSE &ManagementAccountingCurrency
	|				END = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseNumerator
	|		ELSE TTFunctionalCurrencyExchangeRates.CourseNumerator
	|	END                                            AS RateIsNumeratorOfFunctionalCurrency,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND CASE
	|					WHEN TTBalancesWithRateOfContract.ChartOfAccounts.AccountingInFunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal)
	|						THEN TTBalancesWithRateOfContract.Organization.LocalAccountingCurrency
	|					ELSE &ManagementAccountingCurrency
	|				END = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseDenominator
	|		ELSE TTFunctionalCurrencyExchangeRates.CourseDenominator
	|	END                                            AS ExchangeRateDenominator_FunctionalCurrency
	|INTO TTAccountBalancesWithExchangeRates
	|FROM
	|	AccountBalancesWithContractExchangeRateTT AS TTBalancesWithRateOfContract
	|		LEFT JOIN TTExchangeRates_ AS TTExchangeRates_
	|		ON TTBalancesWithRateOfContract.Organization.LocalAccountingCurrency = TTExchangeRates_.BaseCurrency
	|			AND TTBalancesWithRateOfContract.Currency = TTExchangeRates_.Currency
	|		LEFT JOIN TTExchangeRates_ AS TTFunctionalCurrencyExchangeRates
	|		ON TTBalancesWithRateOfContract.Organization.LocalAccountingCurrency = TTFunctionalCurrencyExchangeRates.BaseCurrency
	|			AND (CASE
	|				WHEN TTBalancesWithRateOfContract.ChartOfAccounts.AccountingInFunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal)
	|					THEN TTBalancesWithRateOfContract.Organization.LocalAccountingCurrency = TTFunctionalCurrencyExchangeRates.Currency
	|				ELSE &ManagementAccountingCurrency = TTFunctionalCurrencyExchangeRates.Currency
	|			END)
	|WHERE
	|	TTBalancesWithRateOfContract.ContractRateOption <> VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	AccountBalances.Account,
	|	AccountBalances.Currency AS Currency,
	|	(CAST(AccountBalances.CurrencyAmountBalance 
	|		* AccountBalances.CourseNumerator 
	|		/ AccountBalances.CourseDenominator 
	|		/ AccountBalances.RateIsNumeratorOfFunctionalCurrency 
	|		* AccountBalances.ExchangeRateDenominator_FunctionalCurrency AS NUMBER(31,2))) - AccountBalances.SumBalance AS ExchangeDifference,
	|	AccountBalances.ChartOfAccounts,
	|	AccountBalances.Organization,
	|	AccountBalances.Department,
	|	AccountBalances.LineOfBusiness,
	|	AccountBalances.ExtDimension1,
	|	AccountBalances.ExtDimension2,
	|	AccountBalances.ExtDimension3
	|FROM
	|	TTAccountBalancesWithExchangeRates AS AccountBalances
	|
	|WHERE
	|	(CAST(AccountBalances.CurrencyAmountBalance 
	|		* AccountBalances.CourseNumerator 
	|		/ AccountBalances.CourseDenominator 
	|		/ AccountBalances.RateIsNumeratorOfFunctionalCurrency 
	|		* AccountBalances.ExchangeRateDenominator_FunctionalCurrency AS NUMBER(31,2))) - AccountBalances.SumBalance <> 0";
	
	Return TotalRemainingExchangeDifferences(QueryText, ChartOfAccounts, Companies, OnDate, OnlyFirst_);
	
EndFunction

// Determines the amount of all Balances in the functional currency that have not been converted to the presentation currency.
// (Remaining in the functional currency*The coefficient of counting the value of the representation <> The remaining value of the representation).
//
// Parameters:
//  ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - The chart of accounts, which are selected currency balances.
//  Companies - Array of CatalogRef.Companies -
//              - CatalogRef.Companies - Selection of organizations for which currency balances are determined.
//  OnDate - Date - The date on which the functional currency balances and exchange rate are determined. If not set, then the current one.
//  OnlyFirst_ - Boolean - True if you only need to check that there is no need to calculate exchange rate differences.
//
// Returns:
//  Number - the number of balances in the functional currency that have discrepancies between the calculated and actual
//          balances in the presentation currency.
//
Function NotTranslatedIntoPresentationCurrency(ChartOfAccounts, Companies, OnDate = Undefined, OnlyFirst_ = False) Export

	QueryText = 
	"SELECT
	|	DateSettings.ChartOfAccounts AS ChartOfAccounts,
	|	DateSettings.Organization AS Organization,
	|	DateSettings.PostingGenerationSetting AS PostingGenerationSetting,
	|	AccountingPolicies.IncomeFromTranslationToPresentationCurrency AS ForeignExchangeGain,
	|	AccountingPolicies.ExpensesDifferencesArisingFromConversionToPresentationCurrency AS GLAccountOfExchangeLoss
	|INTO TTAccountsKr
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(
	|			&OnDate,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization IN (&Companies)) AS DateSettings
	|		LEFT JOIN Catalog.FinancialAccountingPostingGenerationSetting AS AccountingPolicies
	|		ON DateSettings.PostingGenerationSetting = AccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ExcludeFromRecalculationToPresentationCurrency.Account AS Account
	|INTO TTAccountExceptions
	|FROM
	|	Catalog.FinancialAccountingPostingGenerationSetting.ExcludeFromRecalculationToPresentationCurrency AS ExcludeFromRecalculationToPresentationCurrency
	|
	|UNION ALL
	|
	|SELECT
	|	TTAccountsKr.ForeignExchangeGain
	|FROM
	|	TTAccountsKr AS TTAccountsKr
	|WHERE
	|	TTAccountsKr.ForeignExchangeGain <> VALUE(ChartOfAccounts.International.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	TTAccountsKr.GLAccountOfExchangeLoss
	|FROM
	|	TTAccountsKr AS TTAccountsKr
	|WHERE
	|	TTAccountsKr.GLAccountOfExchangeLoss <> VALUE(ChartOfAccounts.International.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RelativeExchangeRates.BaseCurrency AS BaseCurrency,
	|	RelativeExchangeRates.Currency AS Currency,
	|	RelativeExchangeRates.CourseNumerator AS CourseNumerator,
	|	RelativeExchangeRates.CourseDenominator AS CourseDenominator
	|INTO TTExchangeRates_
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&OnDate,
	|			BaseCurrency IN (
	|				SELECT
	|					Companies.LocalAccountingCurrency AS LocalAccountingCurrency
	|				FROM
	|					Catalog.Companies AS Companies
	|				WHERE
	|					Companies.Ref IN (&Companies))) AS RelativeExchangeRates
	|INDEX BY
	|	BaseCurrency,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InternationalBalance.Account AS Account,
	|	InternationalBalance.ChartOfAccounts AS ChartOfAccounts,
	|	InternationalBalance.Organization AS Organization,
	|	InternationalBalance.Department AS Department,
	|	InternationalBalance.LineOfBusiness AS LineOfBusiness,
	|	InternationalBalance.Currency AS Currency,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN InternationalBalance.ExtDimension1
	|		ELSE NULL
	|	END AS ExtDimension1,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN InternationalBalance.ExtDimension2
	|		ELSE NULL
	|	END AS ExtDimension2,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN InternationalBalance.ExtDimension3
	|		ELSE NULL
	|	END AS ExtDimension3,
	|	SUM(InternationalBalance.SumBalance) AS SumBalance,
	|	SUM(InternationalBalance.PresentationAmountBalance) AS PresentationAmountBalance
	|INTO TTAccountBalances
	|FROM
	|	AccountingRegister.International.Balance(
	|			&Boundary,
	|			NOT Account IN (SELECT Account FROM TTAccountExceptions),
	|			,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization IN (&Companies)) AS InternationalBalance
	|		INNER JOIN TTAccountsKr AS KRAccountingAccounts
	|		ON InternationalBalance.ChartOfAccounts = KRAccountingAccounts.ChartOfAccounts
	|			AND InternationalBalance.Organization = KRAccountingAccounts.Organization
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay1
	|		ON (InternationalExtdimensionDay1.LineNumber = 1)
	|			AND InternationalBalance.Account = InternationalExtdimensionDay1.Ref
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay2
	|		ON (InternationalExtdimensionDay2.LineNumber = 2)
	|			AND InternationalBalance.Account = InternationalExtdimensionDay2.Ref
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay3
	|		ON (InternationalExtdimensionDay3.LineNumber = 3)
	|			AND InternationalBalance.Account = InternationalExtdimensionDay3.Ref
	|
	|GROUP BY
	|	InternationalBalance.Account,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN InternationalBalance.ExtDimension1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN InternationalBalance.ExtDimension2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN InternationalBalance.ExtDimension3
	|		ELSE NULL
	|	END,
	|	InternationalBalance.ChartOfAccounts,
	|	InternationalBalance.Organization,
	|	InternationalBalance.Department,
	|	InternationalBalance.LineOfBusiness,
	|	InternationalBalance.Currency
	|
	|UNION ALL
	|
	|SELECT
	|	AccountBalances.Account AS Account,
	|	AccountBalances.ChartOfAccounts AS ChartOfAccounts,
	|	AccountBalances.Organization AS Organization,
	|	AccountBalances.Department AS Department,
	|	AccountBalances.LineOfBusiness AS LineOfBusiness,
	|	AccountBalances.Currency AS Currency,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN AccountBalances.ExtDimension1
	|		ELSE NULL
	|	END AS ExtDimension1,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN AccountBalances.ExtDimension2
	|		ELSE NULL
	|	END AS ExtDimension2,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN AccountBalances.ExtDimension3
	|		ELSE NULL
	|	END AS ExtDimension3,
	|	SUM(AccountBalances.SumBalance) AS SumBalance,
	|	SUM(AccountBalances.PresentationAmountBalance) AS PresentationAmountBalance
	|FROM
	|	AccountingRegister.InternationalWithoutCorrespondence.Balance(
	|			&Boundary,
	|			NOT Account IN (SELECT Account FROM TTAccountExceptions),
	|			,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization IN (&Companies)) AS AccountBalances
	|		INNER JOIN TTAccountsKr AS KRAccountingAccounts
	|		ON AccountBalances.ChartOfAccounts = KRAccountingAccounts.ChartOfAccounts
	|			AND AccountBalances.Organization = KRAccountingAccounts.Organization
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay1
	|		ON (InternationalExtdimensionDay1.LineNumber = 1)
	|			AND AccountBalances.Account = InternationalExtdimensionDay1.Ref
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay2
	|		ON (InternationalExtdimensionDay2.LineNumber = 2)
	|			AND AccountBalances.Account = InternationalExtdimensionDay2.Ref
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay3
	|		ON (InternationalExtdimensionDay3.LineNumber = 3)
	|			AND AccountBalances.Account = InternationalExtdimensionDay3.Ref
	|
	|GROUP BY
	|	AccountBalances.Account,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN AccountBalances.ExtDimension1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN AccountBalances.ExtDimension2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN AccountBalances.ExtDimension3
	|		ELSE NULL
	|	END,
	|	AccountBalances.ChartOfAccounts,
	|	AccountBalances.Organization,
	|	AccountBalances.Department,
	|	AccountBalances.LineOfBusiness,
	|	AccountBalances.Currency
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ContractCourse.Contract AS Contract,
	|	ContractCourse.CourseNumerator AS CourseNumerator,
	|	ContractCourse.CourseDenominator AS CourseDenominator
	|INTO ContractTTCourses
	|FROM
	|	InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&OnDate) AS ContractCourse
	|INDEX BY
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAccountBalances.ExtDimension1 AS ExtDimension
	|INTO TTBalancesOfAccountsAllExtDimension
	|FROM
	|	TTAccountBalances
	|	
	|UNION ALL
	|		
	|SELECT
	|	TTAccountBalances.ExtDimension2
	|FROM
	|	TTAccountBalances
	|		
	|UNION ALL
	|		
	|SELECT
	|	TTAccountBalances.ExtDimension3
	|FROM
	|	TTAccountBalances
	|
	|INDEX BY
	|	ExtDimension
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CounterpartyContracts.Ref                                             AS Contract,
	|	CounterpartyContracts.ContractRateOption                               AS ContractRateOption,
	|	CounterpartyContracts.ARAPCurrency                               AS ARAPCurrency,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator, 1)   AS CourseNumerator,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator, 1) AS CourseDenominator
	|INTO TTContracts
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|		LEFT JOIN ContractTTCourses AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|		ON CounterpartyContracts.Ref = ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract
	|		INNER JOIN TTBalancesOfAccountsAllExtDimension AS TTBalancesOfAccountsAllExtDimension
	|		ON TTBalancesOfAccountsAllExtDimension.ExtDimension = CounterpartyContracts.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	IntercompanyContracts.Ref                                       AS Contract,
	|	IntercompanyContracts.ContractRateOption                         AS ContractRateOption,
	|	IntercompanyContracts.ARAPCurrency                         AS ARAPCurrency,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator, 1)   AS CourseNumerator,
	|	ISNULL(ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator, 1) AS CourseDenominator
	|FROM
	|	Catalog.IntercompanyContracts AS IntercompanyContracts
	|		LEFT JOIN ContractTTCourses AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|		ON IntercompanyContracts.Ref = ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract
	|		INNER JOIN TTBalancesOfAccountsAllExtDimension AS TTBalancesOfAccountsAllExtDimension
	|		ON TTBalancesOfAccountsAllExtDimension.ExtDimension = IntercompanyContracts.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountBalances.Account                                                AS Account,
	|	AccountBalances.ChartOfAccounts                                          AS ChartOfAccounts,
	|	AccountBalances.Organization                                         AS Organization,
	|	AccountBalances.Department                                       AS Department,
	|	AccountBalances.LineOfBusiness                             AS LineOfBusiness,
	|	AccountBalances.ExtDimension1                                           AS ExtDimension1,
	|	AccountBalances.ExtDimension2                                           AS ExtDimension2,
	|	AccountBalances.ExtDimension3                                           AS ExtDimension3,
	|	AccountBalances.Currency                                              AS Currency,
	|	AccountBalances.PresentationAmountBalance                           AS PresentationAmountBalance,
	|	AccountBalances.SumBalance                                        AS SumBalance,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.ContractRateOption,
	|			TTContracts2.ContractRateOption),
	|		ISNULL(
	|			TTContracts3.ContractRateOption,
	|			VALUE(Enum.ContractRateOptions.Mutable))) AS ContractRateOption,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.CourseNumerator,
	|			TTContracts2.CourseNumerator),
	|		ISNULL(
	|			TTContracts3.CourseNumerator,
	|			1))                                                       AS CourseNumerator,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.CourseDenominator,
	|			TTContracts2.CourseDenominator),
	|		ISNULL(
	|			TTContracts3.CourseDenominator,
	|			1))                                                       AS CourseDenominator,
	|	ISNULL(
	|		ISNULL(
	|			TTContracts1.ARAPCurrency,
	|			TTContracts2.ARAPCurrency),
	|		ISNULL(
	|			TTContracts3.ARAPCurrency,
	|			UNDEFINED))                                            AS ARAPCurrency
	|INTO AccountBalancesWithContractExchangeRateTT
	|FROM
	|	TTAccountBalances AS AccountBalances
	|		LEFT JOIN TTContracts AS TTContracts1
	|		ON AccountBalances.ExtDimension1 = TTContracts1.Contract
	|		LEFT JOIN TTContracts AS TTContracts2
	|		ON AccountBalances.ExtDimension2 = TTContracts2.Contract
	|		LEFT JOIN TTContracts AS TTContracts3
	|		ON AccountBalances.ExtDimension3 = TTContracts3.Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTBalancesWithRateOfContract.Account                      AS Account,
	|	TTBalancesWithRateOfContract.ChartOfAccounts                AS ChartOfAccounts,
	|	TTBalancesWithRateOfContract.Organization               AS Organization,
	|	TTBalancesWithRateOfContract.Department             AS Department,
	|	TTBalancesWithRateOfContract.LineOfBusiness   AS LineOfBusiness,
	|	TTBalancesWithRateOfContract.ExtDimension1                 AS ExtDimension1,
	|	TTBalancesWithRateOfContract.ExtDimension2                 AS ExtDimension2,
	|	TTBalancesWithRateOfContract.ExtDimension3                 AS ExtDimension3,
	|	TTBalancesWithRateOfContract.Currency                    AS Currency,
	|	TTBalancesWithRateOfContract.PresentationAmountBalance AS PresentationAmountBalance,
	|	TTBalancesWithRateOfContract.SumBalance              AS SumBalance,
	|	TTBalancesWithRateOfContract.ContractRateOption      AS ContractRateOption,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND TTBalancesWithRateOfContract.ChartOfAccounts.PresentationCurrency = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseNumerator
	|		ELSE PresentationCurrencyRates.CourseNumerator
	|	END                                              AS ExchangeRateNumeratorOfPresentationCurrency,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND TTBalancesWithRateOfContract.ChartOfAccounts.PresentationCurrency = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseDenominator
	|		ELSE PresentationCurrencyRates.CourseDenominator
	|	END                                              AS ExchangeRateDenominatorOfPresentationCurrency,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND CASE
	|					WHEN TTBalancesWithRateOfContract.ChartOfAccounts.AccountingInFunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal)
	|						THEN TTBalancesWithRateOfContract.Organization.LocalAccountingCurrency
	|					ELSE &ManagementAccountingCurrency
	|				END = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseNumerator
	|		ELSE FunctionalCurrencyExchangeRates.CourseNumerator
	|	END                                              AS RateIsNumeratorOfFunctionalCurrency,
	|	CASE
	|		WHEN TTBalancesWithRateOfContract.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|				AND CASE
	|					WHEN TTBalancesWithRateOfContract.ChartOfAccounts.AccountingInFunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal)
	|						THEN TTBalancesWithRateOfContract.Organization.LocalAccountingCurrency
	|					ELSE &ManagementAccountingCurrency
	|				END = TTBalancesWithRateOfContract.ARAPCurrency
	|			THEN TTBalancesWithRateOfContract.CourseDenominator
	|		ELSE FunctionalCurrencyExchangeRates.CourseDenominator
	|	END                                              AS ExchangeRateDenominator_FunctionalCurrency
	|INTO TTAccountBalancesWithExchangeRates
	|FROM
	|	AccountBalancesWithContractExchangeRateTT AS TTBalancesWithRateOfContract
	|	LEFT JOIN
	|		TTExchangeRates_ AS PresentationCurrencyRates
	|	ON
	|		TTBalancesWithRateOfContract.Organization.LocalAccountingCurrency = PresentationCurrencyRates.BaseCurrency
	|		AND TTBalancesWithRateOfContract.ChartOfAccounts.PresentationCurrency = PresentationCurrencyRates.Currency
	|
	|	LEFT JOIN
	|		TTExchangeRates_ AS FunctionalCurrencyExchangeRates
	|	ON
	|		TTBalancesWithRateOfContract.Organization.LocalAccountingCurrency = FunctionalCurrencyExchangeRates.BaseCurrency
	|		AND CASE 
	|			WHEN TTBalancesWithRateOfContract.ChartOfAccounts.AccountingInFunctionalCurrency = VALUE(Enum.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal)
	|				THEN TTBalancesWithRateOfContract.Organization.LocalAccountingCurrency = FunctionalCurrencyExchangeRates.Currency
	|			ELSE &ManagementAccountingCurrency = FunctionalCurrencyExchangeRates.Currency
	|		END
	|WHERE
	|	TTBalancesWithRateOfContract.ContractRateOption <> VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	AccountBalances.Account AS Account,
	|	AccountBalances.Currency AS Currency,
	|	CAST(AccountBalances.SumBalance 
	|		* AccountBalances.RateIsNumeratorOfFunctionalCurrency
	|		/ AccountBalances.ExchangeRateDenominator_FunctionalCurrency 
	|		/ AccountBalances.ExchangeRateNumeratorOfPresentationCurrency 
	|		* AccountBalances.ExchangeRateDenominatorOfPresentationCurrency AS NUMBER(31,2)) AS EAPAmount,
	|	AccountBalances.PresentationAmountBalance AS EAPAmountBalance,
	|	(CAST(AccountBalances.SumBalance 
	|		* AccountBalances.RateIsNumeratorOfFunctionalCurrency 
	|		/ AccountBalances.ExchangeRateDenominator_FunctionalCurrency
	|		/ AccountBalances.ExchangeRateNumeratorOfPresentationCurrency
	|		* AccountBalances.ExchangeRateDenominatorOfPresentationCurrency AS NUMBER(31,2))) - AccountBalances.PresentationAmountBalance AS ExchangeDifference,
	|	AccountBalances.ChartOfAccounts AS ChartOfAccounts,
	|	AccountBalances.Organization AS Organization,
	|	AccountBalances.Department AS Department,
	|	AccountBalances.LineOfBusiness AS LineOfBusiness,
	|	AccountBalances.ExtDimension1 AS ExtDimension1,
	|	AccountBalances.ExtDimension2 AS ExtDimension2,
	|	AccountBalances.ExtDimension3 AS ExtDimension3
	|FROM
	|	TTAccountBalancesWithExchangeRates AS AccountBalances
	|WHERE
	|	ISNULL(AccountBalances.Currency, VALUE(Catalog.Currencies.EmptyRef)) <> AccountBalances.ChartOfAccounts.PresentationCurrency
	|	AND (CAST(AccountBalances.SumBalance 
	|		* AccountBalances.RateIsNumeratorOfFunctionalCurrency 
	|		/ AccountBalances.ExchangeRateDenominator_FunctionalCurrency
	|		/ AccountBalances.ExchangeRateNumeratorOfPresentationCurrency
	|		* AccountBalances.ExchangeRateDenominatorOfPresentationCurrency AS NUMBER(31,2))) - AccountBalances.PresentationAmountBalance <> 0";

	Return TotalRemainingExchangeDifferences(QueryText, ChartOfAccounts, Companies, OnDate, OnlyFirst_);

EndFunction

// Determines the number of unclosed income and expense accounts as of the date.
// 
// Parameters:
//  ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - The chart of accounts that is being checked.
//  Companies - Array of CatalogRef.Companies -
//              - CatalogRef.Companies - Selection of organizations for which verification is performed.
//  OnDate - Date - The date on which the check is performed. If not set, then the current one.
// Returns:
// 	Number - number of unclosed accounts
Function ThereAreUnclosedIncomeExpenseAccounts(ChartOfAccounts, Companies, OnDate = Undefined) Export
	
	If ValueIsFilled(OnDate) Then
		OnDate = EndOfDay(OnDate);
	Else
		OnDate = EndOfDay(CurrentSessionDate());
	EndIf;
	
	TimeFenceForClosingAccounts = New Array();
	TimeFenceForClosingAccounts.Add(Enums.ClosingOfIncomeAndExpenseAccounts.Monthly);
	
	If EndOfMonth(OnDate) = EndOfYear(OnDate) Then
		TimeFenceForClosingAccounts.Add(Enums.ClosingOfIncomeAndExpenseAccounts.AtYearEnd);
	EndIf;
	
	QueryText = 
	"SELECT
	|	DateSettings.ChartOfAccounts AS ChartOfAccounts,
	|	DateSettings.PostingGenerationSetting AS PostingGenerationSetting
	|INTO TTSettingsForGeneratingTransactions
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(
	|			&OnDate,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization IN (&Companies)) AS DateSettings
	|		INNER JOIN Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
	|		ON DateSettings.PostingGenerationSetting = TransactionGenerationSettings.Ref
	|WHERE
	|	TransactionGenerationSettings.ClosingOfIncomeAndExpenseAccounts IN (&TimeFenceForClosingAccounts)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.ChartOfAccounts AS ChartOfAccounts,
	|	T.Account AS Account
	|INTO TTClosingAccounts
	|FROM
	|	(SELECT
	|		TransactionGenerationSettings.ChartOfAccounts AS ChartOfAccounts,
	|		IncomeAccounts.Account AS Account
	|	FROM
	|		TTSettingsForGeneratingTransactions AS TransactionGenerationSettings
	|			INNER JOIN Catalog.FinancialAccountingPostingGenerationSetting.IncomeAccounts AS IncomeAccounts
	|			ON TransactionGenerationSettings.PostingGenerationSetting = IncomeAccounts.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TransactionGenerationSettings.ChartOfAccounts,
	|		ExpenseAccounts.Account
	|	FROM
	|		TTSettingsForGeneratingTransactions AS TransactionGenerationSettings
	|			INNER JOIN Catalog.FinancialAccountingPostingGenerationSetting.ExpenseAccounts AS ExpenseAccounts
	|			ON TransactionGenerationSettings.PostingGenerationSetting = ExpenseAccounts.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TransactionGenerationSettings.ChartOfAccounts,
	|		AccountsOfProfitLoss.Account
	|	FROM
	|		TTSettingsForGeneratingTransactions AS TransactionGenerationSettings
	|			INNER JOIN Catalog.FinancialAccountingPostingGenerationSetting.AccountsOfProfitLoss AS AccountsOfProfitLoss
	|			ON TransactionGenerationSettings.PostingGenerationSetting = AccountsOfProfitLoss.Ref) AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InternationalBalance.Account AS Account,
	|	InternationalBalance.ChartOfAccounts AS ChartOfAccounts,
	|	InternationalBalance.Organization AS Organization,
	|	InternationalBalance.Department AS Department,
	|	InternationalBalance.LineOfBusiness AS LineOfBusiness,
	|	InternationalBalance.Currency AS Currency,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN InternationalBalance.ExtDimension1
	|		ELSE NULL
	|	END AS ExtDimension1,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN InternationalBalance.ExtDimension2
	|		ELSE NULL
	|	END AS ExtDimension2,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN InternationalBalance.ExtDimension3
	|		ELSE NULL
	|	END AS ExtDimension3,
	|	SUM(InternationalBalance.SumBalance) AS SumBalance,
	|	SUM(InternationalBalance.SumSplittedBalanceDr) AS SumBalanceDr,
	|	SUM(InternationalBalance.SumSplittedBalanceCr) AS SumBalanceCr,
	|	SUM(InternationalBalance.CurrencyAmountBalance) AS CurrencyAmountBalance
	|
	|FROM
	|	AccountingRegister.International.Balance(
	|			&Boundary,
	|			Account IN
	|				(SELECT T.Account FROM TTClosingAccounts AS T),
	|			,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization IN (&Companies)) AS InternationalBalance
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay1
	|		ON InternationalBalance.Account = InternationalExtdimensionDay1.Ref
	|			AND (InternationalExtdimensionDay1.LineNumber = 1)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay2
	|		ON InternationalBalance.Account = InternationalExtdimensionDay2.Ref
	|			AND (InternationalExtdimensionDay2.LineNumber = 2)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay3
	|		ON InternationalBalance.Account = InternationalExtdimensionDay3.Ref
	|			AND (InternationalExtdimensionDay3.LineNumber = 3)
	|
	|GROUP BY
	|	InternationalBalance.Account,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN InternationalBalance.ExtDimension1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN InternationalBalance.ExtDimension2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN InternationalBalance.ExtDimension3
	|		ELSE NULL
	|	END,
	|	InternationalBalance.ChartOfAccounts,
	|	InternationalBalance.Organization,
	|	InternationalBalance.Department,
	|	InternationalBalance.LineOfBusiness,
	|	InternationalBalance.Currency
	|	
	|HAVING
	|	SUM(InternationalBalance.SumBalance) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	AccountBalances.Account AS Account,
	|	AccountBalances.ChartOfAccounts AS ChartOfAccounts,
	|	AccountBalances.Organization AS Organization,
	|	AccountBalances.Department AS Department,
	|	AccountBalances.LineOfBusiness AS LineOfBusiness,
	|	AccountBalances.Currency AS Currency,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN AccountBalances.ExtDimension1
	|		ELSE NULL
	|	END AS ExtDimension1,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN AccountBalances.ExtDimension2
	|		ELSE NULL
	|	END AS ExtDimension2,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN AccountBalances.ExtDimension3
	|		ELSE NULL
	|	END AS ExtDimension3,
	|	SUM(AccountBalances.SumBalance) AS SumBalance,
	|	SUM(AccountBalances.SumSplittedBalanceDr) AS SumBalanceDr,
	|	SUM(AccountBalances.SumSplittedBalanceCr) AS SumBalanceCr,
	|	SUM(AccountBalances.CurrencyAmountBalance) AS CurrencyAmountBalance
	|
	|FROM
	|	AccountingRegister.InternationalWithoutCorrespondence.Balance(
	|			&Boundary,
	|			Account IN
	|				(SELECT T.Account FROM TTClosingAccounts AS T),
	|			,
	|			ChartOfAccounts = &ChartOfAccounts AND Organization IN (&Companies)) AS AccountBalances
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay1
	|		ON AccountBalances.Account = InternationalExtdimensionDay1.Ref
	|			AND (InternationalExtdimensionDay1.LineNumber = 1)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay2
	|		ON AccountBalances.Account = InternationalExtdimensionDay2.Ref
	|			AND (InternationalExtdimensionDay2.LineNumber = 2)
	|		LEFT JOIN ChartOfAccounts.International.ExtDimensionTypes AS InternationalExtdimensionDay3
	|		ON AccountBalances.Account = InternationalExtdimensionDay3.Ref
	|			AND (InternationalExtdimensionDay3.LineNumber = 3)
	|
	|GROUP BY
	|	AccountBalances.Account,
	|	CASE
	|		WHEN InternationalExtdimensionDay1.Currency1
	|			THEN AccountBalances.ExtDimension1
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay2.Currency1
	|			THEN AccountBalances.ExtDimension2
	|		ELSE NULL
	|	END,
	|	CASE
	|		WHEN InternationalExtdimensionDay3.Currency1
	|			THEN AccountBalances.ExtDimension3
	|		ELSE NULL
	|	END,
	|	AccountBalances.ChartOfAccounts,
	|	AccountBalances.Organization,
	|	AccountBalances.Department,
	|	AccountBalances.LineOfBusiness,
	|	AccountBalances.Currency
	|	
	|HAVING
	|	SUM(AccountBalances.SumBalance) <> 0";
	
	Query = New Query(QueryText);
	Query.SetParameter("OnDate", OnDate);
	Query.SetParameter("Boundary", New Boundary(OnDate, BoundaryType.Including));
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("Companies", Companies);
	Query.SetParameter("TimeFenceForClosingAccounts", TimeFenceForClosingAccounts);
	
	Selection = Query.Execute().Select();
	
	Return Selection.Count();
	
EndFunction

// Determines the availability of long-term assets and liabilities subject to reclassification to short
// -term for transferred entities at the end of the transferred period.
// 
// Parameters:
//  Companies - Array of CatalogRef.Companies -
//              - CatalogRef.Companies - Organizations that are being checked for.
//  Period - Date - The date that defines the monthly interval in which the check is performed.
// 
// Returns:
// 	Boolean - availability of reclassifiable long-term assets and liabilities
//
Function ThereAreReclassifiableNonCurrentAssetsLiabilities(Companies, Period) Export
	
	ReclassificationData = FinancialAccountingByFinancialRegisterData.DataOnReclassificationOfNonCurrentAssetsLiabilities(
		Companies, Period);
	
	Return ReclassificationData.Tables.Count() > 0;
	
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

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("OperationType");
	
	StandardProcessing = False;
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	TransactionTypes = Enums.PeriodEndTransactionsTypesFinancialAccounting;
	If Data.OperationType = TransactionTypes.ClosingOfGLAccountsOfIncomeAndExpenses Then
		StandardProcessing = False;
		Presentation = StrTemplate(
							InternationalReportingServerCall.PresentationOfClosingIncomeExpenses(),
							Data.Number,
							Data.Date);
							
	ElsIf Data.OperationType = TransactionTypes.ExchangeDifferenceCalculationFunctionalCurrency Then
		StandardProcessing = False;
		Presentation = StrTemplate(
							InternationalReportingServerCall.PresentationCalculationOfExchangeDifferencesInFunctionalCurrency(),
							Data.Number,
							Data.Date);
							
	ElsIf Data.OperationType = TransactionTypes.ExchangeDifferenceCalculationFunctionalCurrency Then
		StandardProcessing = False;
		Presentation = StrTemplate(
							InternationalReportingServerCall.PresentationCalculationOfExchangeDifferencesCurrencyOfPresentation(),
							Data.Number,
							Data.Date);
	EndIf; 
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible
	|FROM
	|	Document.PeriodEndTransactionFinancialAccounting AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period", Attributes.Period);
	Query.SetParameter("Organization", Attributes.Organization);
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID("Document.PeriodEndTransactionFinancialAccounting"));
	Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.PeriodEndTransactionFinancialAccounting);
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("Number", Attributes.Number);
	Query.SetParameter("Comment", Attributes.Comment);
	Query.SetParameter("Posted", Attributes.Posted);
	Query.SetParameter("DeletionMark", Attributes.DeletionMark);
	Query.SetParameter("EmployeeResponsible", Attributes.EmployeeResponsible);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	UNDEFINED AS Author,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Comment AS Comment,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	&Period AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	0 AS Sum,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.PeriodEndTransactionFinancialAccounting";
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.PeriodEndTransactionFinancialAccounting"));
	ParameterValues.Insert("BusinessOperation", Enums.BusinessTransactions.PeriodEndTransactionFinancialAccounting);
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText, FullDocumentName, SynonymForDocumentTable, False);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

Function TotalRemainingExchangeDifferences(QueryText, ChartOfAccounts, Companies, Val OnDate, OnlyFirst_)
	
	If ValueIsFilled(OnDate) Then
		OnDate = EndOfDay(OnDate);
	Else
		OnDate = EndOfDay(CurrentSessionDate());
	EndIf;
	
	If Not OnlyFirst_ Then
		QueryText = StrReplace(QueryText, " TOP 1", "");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("OnDate", OnDate);
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("Companies", Companies);
	Query.SetParameter("Boundary", New Boundary(OnDate, BoundaryType.Including));
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	
	Return Query.Execute().Select().Count();
	
EndFunction

#EndRegion

#EndIf
