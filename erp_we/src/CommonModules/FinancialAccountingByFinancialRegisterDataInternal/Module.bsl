#Region Internal

#Region ReclassificationOfRegisterBalances

// Returns the text of the request for the selection of register balances with a maturity equal to the duration of the operating
// cycle of the organization for the reclassification of long-term assets and liabilities into short-term.
// The composition and names of the sample fields correspond to all dimensions and resources of the accumulation register.
// The result of the selection is placed in a temporary table with the name of the accumulation register.
// The request text uses parameters:
//  An array of organizations is an array from the Reference link.Organizations - selection by organizations for which the analysis of balances is performed
//  The beginning of the period - Date is the date of the beginning of the month in which the register balances are analyzed
//  End of the period - Date - the end date of the month in which the register balances are analyzed
//  Period border - The border with the "Including" view - the border of the end of the month, for which the register balances are calculated
// 
// Returns:
//  String - Query text
//
Function TextOfRequestForBalancesForReclassification(RegisterName) Export
	
	If RegisterName = "CustomersARAPAccountingByDueDates" Then
		QueryText = TextOfRequestForBalancesForReclassificationSettlementsWithCustomersByTerms();
	ElsIf RegisterName = "VendorsARAPAccountingByDueDates" Then
		QueryText = TextOfRequestForBalancesForReclassificationSettlementsWithSuppliersByTerms();
	ElsIf RegisterName = "FinancialInstrumentsARAP" Then
		QueryText = TextOfRequestForBalancesForReclassificationSettlementsOnFinancialInstruments();
	Else
		MessageText = StrTemplate(
			NStr("vi = 'Đối với biểu ghi ""%1"" không có hàm sự kiện nhận số dư để tái phân loại';
				|ru = 'Для регистра ""%1"" отсутствует обработчик получения остатков для реклассификации';
				|en = 'Handler of receiving balance for reclassification is missing in the ""%1"" register'; fa = 'Handler of receiving balance for reclassification is missing in the ""%1"" register';
				|it = 'Per il registro ""%1"" manca l''elaboratore di ricezione dei saldi per la riclassificazione';
				|pl = 'Dla rejestru ""%1"" nie ma procesora danych przyjęcia otrzymania sald do reklasyfikacji';
				|tr = '""%1"" kaydı için, yeniden sınıflandırılacak bakiyeleri almak için işleyici eksik'"),
			RegisterName);
		Raise MessageText;
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the text of the data sampling request for performing the operation of reclassifying long-term assets and
// liabilities into short-term ones based on previously received balances with a maturity equal to the duration
// of the operating cycle of the organization. According to the data of the balances, pairs of incoming and outgoing "movements" are formed,
// fed to the input of the MFP translator for accounting objects, which are processed in it according to general rules,
// like ordinary register movements.
// The data source of the query is a temporary table with the name of the accumulation register, obtained when executing
// a query with text from the Text Request function for classification.
// The composition and names of the sample fields correspond to all dimensions and resources of the accumulation register and the necessary
// requisites, including standard ones.
// The result of the selection is placed in a temporary table named according to the rule of "Movement" + the name of the accumulation register.
// The following parameters are used in the request text:
//  Registrar - Document link.Regulationoperationinternational Accounting - a link to the document on which the reclassification transactions will be generated
//  Date of operation - Date - date of operation of reclassification of long-term assets and liabilities into short-term
// 
// Returns:
//  String - Query text
//
Function TextOfRequestForReclassificationOfBalances(RegisterName) Export
	
	If RegisterName = "CustomersARAPAccountingByDueDates" Then
		QueryText = TextOfRequestForReclassificationOfBalancesSettlementsWithCustomersByTerms();
	ElsIf RegisterName = "VendorsARAPAccountingByDueDates" Then
		QueryText = TextOfRequestForReclassificationOfBalancesSettlementsWithSuppliersByTerms();
	ElsIf RegisterName = "FinancialInstrumentsARAP" Then
		QueryText = TextOfRequestForReclassificationOfBalancesSettlementsOnFinancialInstruments();
	Else
		MessageText = StrTemplate(
			NStr("vi = 'Đối với biểu ghi ""%1"" không có hàm sự kiện lập bản ghi kết chuyển tái phân loại số dư';
				|ru = 'Для регистра ""%1"" отсутствует обработчик формирования движений реклассификации остатков';
				|en = 'Handler of generating balance reclassification records is missing in the ""%1"" register'; fa = 'Handler of generating balance reclassification records is missing in the ""%1"" register';
				|it = 'Per il registro ""%1"" manca l''elaboratore di creazione dei movimenti di riclassificazione dei saldi';
				|pl = 'Dla rejestru ""%1"" nie ma procesora danych utworzenia przepływów reklasyfikacji sald';
				|tr = '""%1"" kaydı için, bakiye yeniden sınıflandırma hareketi oluşturma işleyicisi bulunmuyor'"),
			RegisterName);
		Raise MessageText;
	EndIf;
	
	Return StrReplace(QueryText, "PlacementTable", "RegisterRecords" + RegisterName);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region ReclassificationOfBalancesAndSettlementsWithCustomersByTerms

Function TextOfRequestForBalancesForReclassificationSettlementsWithCustomersByTerms()
	
	QueryText = "
	|SELECT
	|	CustomersARAPAccountingBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	CustomersARAPAccountingBalance.Currency AS Currency,
	|	CustomersARAPAccountingBalance.ARAPDocument AS ARAPDocument,
	|	CustomersARAPAccountingBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	CustomersARAPAccountingBalance.OccurrenceDate AS OccurrenceDate,
	|	CustomersARAPAccountingBalance.DebtBalance AS Debt,
	|	CustomersARAPAccountingBalance.DebtLocalBalance AS DebtLocal,
	|	CustomersARAPAccountingBalance.ARAPManBalance AS ARAPMan,
	|	CustomersARAPAccountingBalance.PrepaymentBalance AS Prepayment,
	|	CustomersARAPAccountingBalance.PrepaymentLocalBalance AS PrepaymentLocal,
	|	CustomersARAPAccountingBalance.PrepaymentManBalance AS PrepaymentMan
	|INTO CustomersARAPAccountingByDueDates
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
	|		&PeriodBoundary,
	|		AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|		AND PlannedRepaymentDate > &EndOfPeriod
	|	) AS CustomersARAPAccountingBalance
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(
	|		&EndOfPeriod,
	|		Organization IN (&CompanyArray)
	|	) AS FinancialAccountingPolicy
	|	ON CustomersARAPAccountingBalance.AccountingDimensionByPartners.Organization = FinancialAccountingPolicy.Organization
	|WHERE
	|	FinancialAccountingPolicy.DurationOfCompanyOperatingCycle > 0
	|	AND CustomersARAPAccountingBalance.PlannedRepaymentDate BETWEEN
	|		DATEADD(&BeginOfPeriod, MONTH, FinancialAccountingPolicy.DurationOfCompanyOperatingCycle)
	|		AND ENDOFPERIOD(DATEADD(&BeginOfPeriod, MONTH, FinancialAccountingPolicy.DurationOfCompanyOperatingCycle), MONTH)
	|";
	
	Return QueryText;
	
EndFunction

Function TextOfRequestForReclassificationOfBalancesSettlementsWithCustomersByTerms()
	
	QueryText = "
	|SELECT
	|	TRUE AS Active,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS Period,
	|	&Recorder AS DocumentRecorder,
	|	CustomersARAPAccountingBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	CustomersARAPAccountingBalance.Currency AS Currency,
	|	CustomersARAPAccountingBalance.ARAPDocument AS ARAPDocument,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS PlannedRepaymentDate,
	|	CustomersARAPAccountingBalance.OccurrenceDate AS OccurrenceDate,
	|	CustomersARAPAccountingBalance.Debt AS Debt,
	|	CustomersARAPAccountingBalance.DebtLocal AS DebtLocal,
	|	CustomersARAPAccountingBalance.ARAPMan AS ARAPMan,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	0 AS PrepaymentMan,
	|	CustomersARAPAccountingBalance.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfLongTermAssetsAndLiabilities) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|INTO PlacementTable
	|FROM
	|	CustomersARAPAccountingByDueDates AS CustomersARAPAccountingBalance
	|WHERE
	|	CustomersARAPAccountingBalance.Debt <> 0
	|	OR CustomersARAPAccountingBalance.DebtLocal <> 0
	|	OR CustomersARAPAccountingBalance.ARAPMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE AS Active,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS Period,
	|	&Recorder AS DocumentRecorder,
	|	CustomersARAPAccountingBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	CustomersARAPAccountingBalance.Currency AS Currency,
	|	CustomersARAPAccountingBalance.ARAPDocument AS ARAPDocument,
	|	CustomersARAPAccountingBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	CustomersARAPAccountingBalance.OccurrenceDate AS OccurrenceDate,
	|	CustomersARAPAccountingBalance.Debt AS Debt,
	|	CustomersARAPAccountingBalance.DebtLocal AS DebtLocal,
	|	CustomersARAPAccountingBalance.ARAPMan AS ARAPMan,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	0 AS PrepaymentMan,
	|	CustomersARAPAccountingBalance.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfLongTermAssetsAndLiabilities) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	CustomersARAPAccountingByDueDates AS CustomersARAPAccountingBalance
	|WHERE
	|	CustomersARAPAccountingBalance.Debt <> 0
	|	OR CustomersARAPAccountingBalance.DebtLocal <> 0
	|	OR CustomersARAPAccountingBalance.ARAPMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE AS Active,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS Period,
	|	&Recorder AS DocumentRecorder,
	|	CustomersARAPAccountingBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	CustomersARAPAccountingBalance.Currency AS Currency,
	|	CustomersARAPAccountingBalance.ARAPDocument AS ARAPDocument,
	|	CustomersARAPAccountingBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	CustomersARAPAccountingBalance.OccurrenceDate AS OccurrenceDate,
	|	0 AS Debt,
	|	0 AS DebtLocal,
	|	0 AS ARAPMan,
	|	CustomersARAPAccountingBalance.Prepayment AS Prepayment,
	|	CustomersARAPAccountingBalance.PrepaymentLocal AS PrepaymentLocal,
	|	CustomersARAPAccountingBalance.PrepaymentMan AS PrepaymentMan,
	|	CustomersARAPAccountingBalance.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfLongTermAssetsAndLiabilities) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	CustomersARAPAccountingByDueDates AS CustomersARAPAccountingBalance
	|WHERE
	|	CustomersARAPAccountingBalance.Prepayment <> 0
	|	OR CustomersARAPAccountingBalance.PrepaymentLocal <> 0
	|	OR CustomersARAPAccountingBalance.PrepaymentMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE AS Active,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS Period,
	|	&Recorder AS DocumentRecorder,
	|	CustomersARAPAccountingBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	CustomersARAPAccountingBalance.Currency AS Currency,
	|	CustomersARAPAccountingBalance.ARAPDocument AS ARAPDocument,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS PlannedRepaymentDate,
	|	CustomersARAPAccountingBalance.OccurrenceDate AS OccurrenceDate,
	|	0 AS Debt,
	|	0 AS DebtLocal,
	|	0 AS ARAPMan,
	|	CustomersARAPAccountingBalance.Prepayment AS Prepayment,
	|	CustomersARAPAccountingBalance.PrepaymentLocal AS PrepaymentLocal,
	|	CustomersARAPAccountingBalance.PrepaymentMan AS PrepaymentMan,
	|	CustomersARAPAccountingBalance.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfLongTermAssetsAndLiabilities) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	CustomersARAPAccountingByDueDates AS CustomersARAPAccountingBalance
	|WHERE
	|	CustomersARAPAccountingBalance.Prepayment <> 0
	|	OR CustomersARAPAccountingBalance.PrepaymentLocal <> 0
	|	OR CustomersARAPAccountingBalance.PrepaymentMan <> 0
	|";

	Return QueryText;
	
EndFunction

#EndRegion

#Region ReclassificationOfRegisterBalancesSettlementsWithSuppliersByTerms

Function TextOfRequestForBalancesForReclassificationSettlementsWithSuppliersByTerms()
	
	QueryText = "
	|SELECT
	|	VendorsARAPAccountingBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingBalance.Currency AS Currency,
	|	VendorsARAPAccountingBalance.ARAPDocument AS ARAPDocument,
	|	VendorsARAPAccountingBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	VendorsARAPAccountingBalance.OccurrenceDate AS OccurrenceDate,
	|	VendorsARAPAccountingBalance.DebtBalance AS Debt,
	|	VendorsARAPAccountingBalance.DebtLocalBalance AS DebtLocal,
	|	VendorsARAPAccountingBalance.ARAPManBalance AS ARAPMan,
	|	VendorsARAPAccountingBalance.PrepaymentBalance AS Prepayment,
	|	VendorsARAPAccountingBalance.PrepaymentLocalBalance AS PrepaymentLocal,
	|	VendorsARAPAccountingBalance.PrepaymentManBalance AS PrepaymentMan
	|INTO VendorsARAPAccountingByDueDates
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
	|		&PeriodBoundary,
	|		AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|		AND PlannedRepaymentDate > &EndOfPeriod
	|	) AS VendorsARAPAccountingBalance
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(
	|		&EndOfPeriod,
	|		Organization IN (&CompanyArray)
	|	) AS FinancialAccountingPolicy
	|	ON VendorsARAPAccountingBalance.AccountingDimensionByPartners.Organization = FinancialAccountingPolicy.Organization
	|WHERE
	|	FinancialAccountingPolicy.DurationOfCompanyOperatingCycle > 0
	|	AND VendorsARAPAccountingBalance.PlannedRepaymentDate BETWEEN
	|		DATEADD(&BeginOfPeriod, MONTH, FinancialAccountingPolicy.DurationOfCompanyOperatingCycle)
	|		AND ENDOFPERIOD(DATEADD(&BeginOfPeriod, MONTH, FinancialAccountingPolicy.DurationOfCompanyOperatingCycle), MONTH)
	|";
	
	Return QueryText;
	
EndFunction

Function TextOfRequestForReclassificationOfBalancesSettlementsWithSuppliersByTerms()
	
	QueryText = "
	|SELECT
	|	TRUE AS Active,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS Period,
	|	&Recorder AS DocumentRecorder,
	|	VendorsARAPAccountingBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingBalance.Currency AS Currency,
	|	VendorsARAPAccountingBalance.ARAPDocument AS ARAPDocument,
	|	VendorsARAPAccountingBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	VendorsARAPAccountingBalance.OccurrenceDate AS OccurrenceDate,
	|	VendorsARAPAccountingBalance.Debt AS Debt,
	|	VendorsARAPAccountingBalance.DebtLocal AS DebtLocal,
	|	VendorsARAPAccountingBalance.ARAPMan AS ARAPMan,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	0 AS PrepaymentMan,
	|	VendorsARAPAccountingBalance.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfLongTermAssetsAndLiabilities) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|INTO PlacementTable
	|FROM
	|	VendorsARAPAccountingByDueDates AS VendorsARAPAccountingBalance
	|WHERE
	|	VendorsARAPAccountingBalance.Debt <> 0
	|	OR VendorsARAPAccountingBalance.DebtLocal <> 0
	|	OR VendorsARAPAccountingBalance.ARAPMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE AS Active,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS Period,
	|	&Recorder AS DocumentRecorder,
	|	VendorsARAPAccountingBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingBalance.Currency AS Currency,
	|	VendorsARAPAccountingBalance.ARAPDocument AS ARAPDocument,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS PlannedRepaymentDate,
	|	VendorsARAPAccountingBalance.OccurrenceDate AS OccurrenceDate,
	|	VendorsARAPAccountingBalance.Debt AS Debt,
	|	VendorsARAPAccountingBalance.DebtLocal AS DebtLocal,
	|	VendorsARAPAccountingBalance.ARAPMan AS ARAPMan,
	|	0 AS Prepayment,
	|	0 AS PrepaymentLocal,
	|	0 AS PrepaymentMan,
	|	VendorsARAPAccountingBalance.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfLongTermAssetsAndLiabilities) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	VendorsARAPAccountingByDueDates AS VendorsARAPAccountingBalance
	|WHERE
	|	VendorsARAPAccountingBalance.Debt <> 0
	|	OR VendorsARAPAccountingBalance.DebtLocal <> 0
	|	OR VendorsARAPAccountingBalance.ARAPMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE AS Active,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS Period,
	|	&Recorder AS DocumentRecorder,
	|	VendorsARAPAccountingBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingBalance.Currency AS Currency,
	|	VendorsARAPAccountingBalance.ARAPDocument AS ARAPDocument,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS PlannedRepaymentDate,
	|	VendorsARAPAccountingBalance.OccurrenceDate AS OccurrenceDate,
	|	0 AS Debt,
	|	0 AS DebtLocal,
	|	0 AS ARAPMan,
	|	VendorsARAPAccountingBalance.Prepayment AS Prepayment,
	|	VendorsARAPAccountingBalance.PrepaymentLocal AS PrepaymentLocal,
	|	VendorsARAPAccountingBalance.PrepaymentMan AS PrepaymentMan,
	|	VendorsARAPAccountingBalance.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfLongTermAssetsAndLiabilities) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	VendorsARAPAccountingByDueDates AS VendorsARAPAccountingBalance
	|WHERE
	|	VendorsARAPAccountingBalance.Prepayment <> 0
	|	OR VendorsARAPAccountingBalance.PrepaymentLocal <> 0
	|	OR VendorsARAPAccountingBalance.PrepaymentMan <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE AS Active,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS Period,
	|	&Recorder AS DocumentRecorder,
	|	VendorsARAPAccountingBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingBalance.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingBalance.Currency AS Currency,
	|	VendorsARAPAccountingBalance.ARAPDocument AS ARAPDocument,
	|	VendorsARAPAccountingBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	VendorsARAPAccountingBalance.OccurrenceDate AS OccurrenceDate,
	|	0 AS Debt,
	|	0 AS DebtLocal,
	|	0 AS ARAPMan,
	|	VendorsARAPAccountingBalance.Prepayment AS Prepayment,
	|	VendorsARAPAccountingBalance.PrepaymentLocal AS PrepaymentLocal,
	|	VendorsARAPAccountingBalance.PrepaymentMan AS PrepaymentMan,
	|	VendorsARAPAccountingBalance.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfLongTermAssetsAndLiabilities) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	VendorsARAPAccountingByDueDates AS VendorsARAPAccountingBalance
	|WHERE
	|	VendorsARAPAccountingBalance.Prepayment <> 0
	|	OR VendorsARAPAccountingBalance.PrepaymentLocal <> 0
	|	OR VendorsARAPAccountingBalance.PrepaymentMan <> 0
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region ReclassificationOfBalancesAndSettlementsOnFinancialInstruments

Function TextOfRequestForBalancesForReclassificationSettlementsOnFinancialInstruments()
	
	QueriesTexts = New Array();
	
#Region SettlementsOnLoansAndDeposits
	
#Region ReclassificationOfReceivedLoansAndDepositsToLongTerm
	
	QueriesTexts.Add("
	|SELECT
	|	FinancialInstrumentsARAP.Contract AS Contract,
	|	FinancialInstrumentsARAP.AmountType AS AmountType,
	|	FinancialInstrumentsARAP.Currency AS Currency,
	|	DATEADD(DATEADD(&BeginOfPeriod, MONTH, FinancialAccountingPolicy.DurationOfCompanyOperatingCycle + 1), DAY, -1) AS BeginningOfLongTermPeriod,
	|	MAX(FinancialInstrumentsARAP.AccountingDimensionByPartners) AS AccountingDimensionByPartners,
	|	MAX(FinancialInstrumentsARAP.ARAPDocument) AS ARAPDocument,
	|	SUM(CASE
	|		WHEN FinancialInstrumentsARAP.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN FinancialInstrumentsARAP.SumExpense
	|		ELSE FinancialInstrumentsARAP.SumReceipt
	|	END) AS Sum
	|INTO TTProceedsFromLoansAndDeposits
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(
	|		&BeginOfPeriod,
	|		&EndOfPeriod,
	|		Period,
	|		Contract REFS Catalog.LoanAndDepositContracts
	|		AND AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|	) AS FinancialInstrumentsARAP
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(
	|		&EndOfPeriod,
	|		Organization IN (&CompanyArray)
	|	) AS FinancialAccountingPolicy
	|		ON FinancialInstrumentsARAP.AccountingDimensionByPartners.Organization = FinancialAccountingPolicy.Organization
	|WHERE
	|	CASE
	|		WHEN FinancialInstrumentsARAP.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN FinancialInstrumentsARAP.SumExpense
	|		ELSE FinancialInstrumentsARAP.SumReceipt
	|	END > 0
	|	AND FinancialAccountingPolicy.DurationOfCompanyOperatingCycle > 0
	|GROUP BY
	|	FinancialInstrumentsARAP.Contract,
	|	FinancialInstrumentsARAP.AmountType,
	|	FinancialInstrumentsARAP.Currency,
	|	FinancialAccountingPolicy.DurationOfCompanyOperatingCycle
	|INDEX BY
	|	Contract,
	|	AmountType,
	|	Currency
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	ProceedsFromLoansAndDeposits.Contract AS Contract,
	|	ProceedsFromLoansAndDeposits.AmountType AS AmountType,
	|	SUM(CASE
	|		WHEN ProceedsFromLoansAndDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|			THEN PaymentSchedule.Sum
	|		WHEN ProceedsFromLoansAndDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|			THEN PaymentSchedule.Interests
	|		WHEN ProceedsFromLoansAndDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|			THEN PaymentSchedule.Fee
	|		ELSE 0
	|	END) AS AmountTotal,
	|	SUM(CASE
	|		WHEN ProceedsFromLoansAndDeposits.BeginningOfLongTermPeriod > PaymentSchedule.Period
	|			THEN 0
	|		WHEN ProceedsFromLoansAndDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|			THEN PaymentSchedule.Sum
	|		WHEN ProceedsFromLoansAndDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|			THEN PaymentSchedule.Interests
	|		WHEN ProceedsFromLoansAndDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|			THEN PaymentSchedule.Fee
	|		ELSE 0
	|	END) AS LongTermAmount
	|INTO TTPaymentScheduleForLoansAndDeposits
	|FROM
	|	TTProceedsFromLoansAndDeposits AS ProceedsFromLoansAndDeposits
	|	INNER JOIN InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS PaymentSchedule
	|		ON ProceedsFromLoansAndDeposits.Contract = PaymentSchedule.ScheduleOption.Owner
	|		 AND NOT PaymentSchedule.ScheduleOption.DeletionMark
	|		 AND PaymentSchedule.ScheduleOption.Used
	|GROUP BY
	|	ProceedsFromLoansAndDeposits.Contract,
	|	ProceedsFromLoansAndDeposits.AmountType
	|HAVING
	|	SUM(CASE
	|		WHEN ProceedsFromLoansAndDeposits.BeginningOfLongTermPeriod > PaymentSchedule.Period
	|			THEN 0
	|		WHEN ProceedsFromLoansAndDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|			THEN PaymentSchedule.Sum
	|		WHEN ProceedsFromLoansAndDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|			THEN PaymentSchedule.Interests
	|		WHEN ProceedsFromLoansAndDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|			THEN PaymentSchedule.Fee
	|		ELSE 0
	|	END) > 0
	|INDEX BY
	|	Contract,
	|	AmountType
	|");
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	ProceedsFromLoansAndDeposits.Contract AS Contract
	|INTO TTLoanAndDepositAgreements
	|FROM
	|	TTProceedsFromLoansAndDeposits AS ProceedsFromLoansAndDeposits
	|INDEX BY
	|	Contract
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	FinancialInstrumentsARAP.Contract AS Contract,
	|	FinancialInstrumentsARAP.AmountType AS AmountType,
	|	FinancialInstrumentsARAP.Currency AS Currency,
	|	CASE
	|		WHEN FinancialInstrumentsARAP.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN FinancialInstrumentsARAP.SumExpense
	|		ELSE FinancialInstrumentsARAP.SumReceipt
	|	END AS Sum
	|INTO TTReceiptsOfLoansAndDepositsTotal
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(,
	|		&EndOfPeriod,,
	|		Contract IN
	|		(SELECT
	|			LoanAndDepositContracts.Contract
	|		FROM
	|			TTLoanAndDepositAgreements AS LoanAndDepositContracts)
	|	) AS FinancialInstrumentsARAP
	|WHERE
	|	CASE
	|		WHEN FinancialInstrumentsARAP.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN FinancialInstrumentsARAP.SumExpense
	|		ELSE FinancialInstrumentsARAP.SumReceipt
	|	END > 0
	|INDEX BY
	|	Contract,
	|	AmountType,
	|	Currency
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	FinancialInstrumentsARAP.Contract AS Contract,
	|	FinancialInstrumentsARAP.AmountType AS AmountType,
	|	FinancialInstrumentsARAP.Currency AS Currency,
	|	CASE
	|		WHEN FinancialInstrumentsARAP.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN -1
	|		ELSE 1
	|	END * FinancialInstrumentsARAP.SumBalance AS Sum
	|INTO TTLoanAndDepositBalances
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|		&PeriodBoundary,
	|		Contract IN
	|		(SELECT
	|			LoanAndDepositContracts.Contract
	|		FROM
	|			TTLoanAndDepositAgreements AS LoanAndDepositContracts)
	|	) AS FinancialInstrumentsARAP
	|WHERE
	|	CASE
	|		WHEN FinancialInstrumentsARAP.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN -1
	|		ELSE 1
	|	END * FinancialInstrumentsARAP.SumBalance > 0
	|INDEX BY
	|	Contract,
	|	AmountType,
	|	Currency
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	ProceedsFromLoansAndDeposits.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ProceedsFromLoansAndDeposits.Contract AS Contract,
	|	ProceedsFromLoansAndDeposits.AmountType AS AmountType,
	|	ProceedsFromLoansAndDeposits.ARAPDocument AS ARAPDocument,
	|	ProceedsFromLoansAndDeposits.Currency AS Currency,
	|	ProceedsFromLoansAndDeposits.BeginningOfLongTermPeriod AS PlannedRepaymentDate,
	|	CASE
	|		WHEN ISNULL(LoanAndDepositBalances.Sum, 0) < CASE
	|			WHEN (ISNULL(ReceiptsOfLoansAndDepositsTotal.Sum, ProceedsFromLoansAndDeposits.Sum) - ProceedsFromLoansAndDeposits.Sum)
	|				< (ScheduleOfPaymentForLoansAndDeposits.AmountTotal - ScheduleOfPaymentForLoansAndDeposits.LongTermAmount)
	|				THEN ISNULL(ReceiptsOfLoansAndDepositsTotal.Sum, ProceedsFromLoansAndDeposits.Sum)
	|					- (ScheduleOfPaymentForLoansAndDeposits.AmountTotal - ScheduleOfPaymentForLoansAndDeposits.LongTermAmount)
	|			ELSE ProceedsFromLoansAndDeposits.Sum
	|		END
	|			THEN ISNULL(LoanAndDepositBalances.Sum, 0)
	|		ELSE CASE
	|			WHEN (ISNULL(ReceiptsOfLoansAndDepositsTotal.Sum, ProceedsFromLoansAndDeposits.Sum) - ProceedsFromLoansAndDeposits.Sum)
	|				< (ScheduleOfPaymentForLoansAndDeposits.AmountTotal - ScheduleOfPaymentForLoansAndDeposits.LongTermAmount)
	|				THEN ISNULL(ReceiptsOfLoansAndDepositsTotal.Sum, ProceedsFromLoansAndDeposits.Sum)
	|					- (ScheduleOfPaymentForLoansAndDeposits.AmountTotal - ScheduleOfPaymentForLoansAndDeposits.LongTermAmount)
	|			ELSE ProceedsFromLoansAndDeposits.Sum
	|		END
	|	END AS Sum
	|INTO TTReclassificationOfProceedsFromLoansAndDeposits
	|FROM
	|	TTProceedsFromLoansAndDeposits AS ProceedsFromLoansAndDeposits
	|	INNER JOIN TTPaymentScheduleForLoansAndDeposits AS ScheduleOfPaymentForLoansAndDeposits
	|		ON ProceedsFromLoansAndDeposits.Contract = ScheduleOfPaymentForLoansAndDeposits.Contract
	|		 AND ProceedsFromLoansAndDeposits.AmountType = ScheduleOfPaymentForLoansAndDeposits.AmountType
	|	LEFT JOIN TTReceiptsOfLoansAndDepositsTotal AS ReceiptsOfLoansAndDepositsTotal
	|		ON ProceedsFromLoansAndDeposits.Contract = ReceiptsOfLoansAndDepositsTotal.Contract
	|		 AND ProceedsFromLoansAndDeposits.AmountType = ReceiptsOfLoansAndDepositsTotal.AmountType
	|		 AND ProceedsFromLoansAndDeposits.Currency = ReceiptsOfLoansAndDepositsTotal.Currency
	|	LEFT JOIN TTLoanAndDepositBalances AS LoanAndDepositBalances
	|		ON ProceedsFromLoansAndDeposits.Contract = LoanAndDepositBalances.Contract
	|		 AND ProceedsFromLoansAndDeposits.AmountType = LoanAndDepositBalances.AmountType
	|		 AND ProceedsFromLoansAndDeposits.Currency = LoanAndDepositBalances.Currency
	|WHERE
	|	ISNULL(ReceiptsOfLoansAndDepositsTotal.Sum, ProceedsFromLoansAndDeposits.Sum)
	|		> (ScheduleOfPaymentForLoansAndDeposits.AmountTotal - ScheduleOfPaymentForLoansAndDeposits.LongTermAmount)
	|	AND ISNULL(LoanAndDepositBalances.Sum, 0) > 0
	|");
	
	QueriesTexts.Add("
	|DROP TTLoanAndDepositAgreements");
	
	QueriesTexts.Add("
	|DROP TTProceedsFromLoansAndDeposits");
	
	QueriesTexts.Add("
	|DROP TTReceiptsOfLoansAndDepositsTotal");
	
	QueriesTexts.Add("
	|DROP TTLoanAndDepositBalances");
	
	QueriesTexts.Add("
	|DROP TTPaymentScheduleForLoansAndDeposits");
	
#EndRegion
	
#Region ReclassificationOfLoanAndDepositBalancesToShortTerm
	
	QueriesTexts.Add("
	|SELECT
	|	LoanAndDepositContracts.Ref AS Ref,
	|	LoanAndDepositContracts.ARAPCurrency AS Currency,
	|	AccountingDimensionByPartners.DimensionKey AS DimensionKey,
	|	DATEADD(DATEADD(&BeginOfPeriod, MONTH, FinancialAccountingPolicy.DurationOfCompanyOperatingCycle), DAY, -1) AS BeginningOfRepaymentPeriod,
	|	DATEADD(ENDOFPERIOD(DATEADD(&BeginOfPeriod, MONTH, FinancialAccountingPolicy.DurationOfCompanyOperatingCycle), MONTH), DAY, -1) AS EndOfRepaymentPeriod
	|INTO TTLoanAndDepositAgreements
	|FROM
	|	Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
	|	INNER JOIN InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|		ON LoanAndDepositContracts.Organization = AccountingDimensionByPartners.Organization
	|		 AND LoanAndDepositContracts.Counterparty = AccountingDimensionByPartners.Counterparty
	|		 AND LoanAndDepositContracts.Partner = AccountingDimensionByPartners.Partner
	|		 AND AccountingDimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		 AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = AccountingDimensionByPartners.LineOfBusiness
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(
	|		&EndOfPeriod,
	|		Organization IN (&CompanyArray)
	|	) AS FinancialAccountingPolicy
	|		ON LoanAndDepositContracts.Organization = FinancialAccountingPolicy.Organization
	|WHERE
	|	LoanAndDepositContracts.Organization IN (&CompanyArray)
	|	AND FinancialAccountingPolicy.DurationOfCompanyOperatingCycle > 0
	|INDEX BY
	|	Ref,
	|	Currency
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	LoanAndDepositContracts.DimensionKey AS AccountingDimensionByPartners,
	|	LoanAndDepositContracts.Ref AS Contract,
	|	LoanAndDepositContracts.Currency AS Currency,
	|	TypesOfGraphSums.Ref AS AmountType,
	|	MAX(PaymentSchedule.Period) AS PlannedRepaymentDate,
	|	MAX(CASE
	|		WHEN TypesOfGraphSums.Ref = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|			THEN PaymentSchedule.AmountTotal
	|		WHEN TypesOfGraphSums.Ref = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|			THEN PaymentSchedule.InterestTotal
	|		WHEN TypesOfGraphSums.Ref = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|			THEN PaymentSchedule.FeeTotal
	|		ELSE 0
	|	END) AS AmountTotal,
	|	SUM(CASE
	|		WHEN TypesOfGraphSums.Ref = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|			THEN PaymentSchedule.Sum
	|		WHEN TypesOfGraphSums.Ref = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|			THEN PaymentSchedule.Interests
	|		WHEN TypesOfGraphSums.Ref = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|			THEN PaymentSchedule.Fee
	|		ELSE 0
	|	END) AS Sum
	|INTO TTPaymentScheduleForLoansAndDeposits
	|FROM
	|	TTLoanAndDepositAgreements AS LoanAndDepositContracts
	|	INNER JOIN InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS PaymentSchedule
	|		ON LoanAndDepositContracts.Ref = PaymentSchedule.ScheduleOption.Owner
	|		 AND NOT PaymentSchedule.ScheduleOption.DeletionMark
	|		 AND PaymentSchedule.ScheduleOption.Used
	|		 AND PaymentSchedule.Period BETWEEN LoanAndDepositContracts.BeginningOfRepaymentPeriod AND LoanAndDepositContracts.EndOfRepaymentPeriod
	|	INNER JOIN Enum.LoanAndDepositScheduleAmountTypes AS TypesOfGraphSums
	|		ON TRUE
	|WHERE
	|	CASE
	|		WHEN TypesOfGraphSums.Ref = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|			THEN PaymentSchedule.Sum
	|		WHEN TypesOfGraphSums.Ref = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|			THEN PaymentSchedule.Interests
	|		WHEN TypesOfGraphSums.Ref = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|			THEN PaymentSchedule.Fee
	|		ELSE 0
	|	END > 0
	|GROUP BY
	|	LoanAndDepositContracts.DimensionKey,
	|	LoanAndDepositContracts.Ref,
	|	LoanAndDepositContracts.Currency,
	|	TypesOfGraphSums.Ref
	|INDEX BY
	|	Contract,
	|	Currency,
	|	AmountType
	|");
	
	QueriesTexts.Add("
	|DROP TTLoanAndDepositAgreements");
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	ScheduleOfPaymentForLoansAndDeposits.Contract AS Contract
	|INTO TTLoanAndDepositAgreements
	|FROM
	|	TTPaymentScheduleForLoansAndDeposits AS ScheduleOfPaymentForLoansAndDeposits
	|INDEX BY
	|	Contract
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	FinancialInstrumentsARAP.Contract AS Contract,
	|	FinancialInstrumentsARAP.Currency AS Currency,
	|	FinancialInstrumentsARAP.AmountType AS AmountType,
	|	MAX(FinancialInstrumentsARAP.AccountingDimensionByPartners) AS AccountingDimensionByPartners,
	|	MAX(FinancialInstrumentsARAP.ARAPDocument) AS ARAPDocument,
	|	CASE
	|		WHEN SUM(CASE
	|			WHEN FinancialInstrumentsARAP.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN FinancialInstrumentsARAP.SumExpense
	|			ELSE FinancialInstrumentsARAP.SumReceipt
	|		END) < 0
	|			THEN 0
	|		ELSE SUM(CASE
	|			WHEN FinancialInstrumentsARAP.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN FinancialInstrumentsARAP.SumExpense
	|			ELSE FinancialInstrumentsARAP.SumReceipt
	|		END)
	|	END AS OrderReceiptAmount,
	|	CASE
	|		WHEN SUM(CASE
	|			WHEN FinancialInstrumentsARAP.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN FinancialInstrumentsARAP.SumReceipt
	|			ELSE FinancialInstrumentsARAP.SumExpense
	|		END) < 0
	|			THEN 0
	|		ELSE SUM(CASE
	|			WHEN FinancialInstrumentsARAP.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN FinancialInstrumentsARAP.SumReceipt
	|			ELSE FinancialInstrumentsARAP.SumExpense
	|		END)
	|	END AS PayAmount
	|INTO TTTurnoverOfLoansAndDeposits
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(,
	|		&EndOfPeriod,,
	|		Contract IN
	|		(SELECT
	|			LoanAndDepositContracts.Contract
	|		FROM
	|			TTLoanAndDepositAgreements AS LoanAndDepositContracts)
	|	) AS FinancialInstrumentsARAP
	|GROUP BY
	|	FinancialInstrumentsARAP.Contract,
	|	FinancialInstrumentsARAP.Currency,
	|	FinancialInstrumentsARAP.AmountType
	|INDEX BY
	|	Contract,
	|	Currency,
	|	AmountType
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	FinancialInstrumentsARAP.Contract AS Contract,
	|	FinancialInstrumentsARAP.Currency AS Currency,
	|	FinancialInstrumentsARAP.AmountType AS AmountType,
	|	CASE
	|		WHEN FinancialInstrumentsARAP.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN -1
	|		ELSE 1
	|	END * FinancialInstrumentsARAP.SumBalance AS Sum
	|INTO TTLoanAndDepositBalances
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|		&BeginOfPeriod,
	|		Contract IN
	|		(SELECT
	|			LoanAndDepositContracts.Contract
	|		FROM
	|			TTLoanAndDepositAgreements AS LoanAndDepositContracts)
	|	) AS FinancialInstrumentsARAP
	|WHERE
	|	CASE
	|		WHEN FinancialInstrumentsARAP.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN -1
	|		ELSE 1
	|	END * FinancialInstrumentsARAP.SumBalance > 0
	|INDEX BY
	|	Contract,
	|	Currency,
	|	AmountType
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	ScheduleOfPaymentForLoansAndDeposits.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ScheduleOfPaymentForLoansAndDeposits.Contract AS Contract,
	|	ScheduleOfPaymentForLoansAndDeposits.AmountType AS AmountType,
	|	ISNULL(TurnoverOfLoansAndDeposits.ARAPDocument, UNDEFINED) AS ARAPDocument,
	|	ScheduleOfPaymentForLoansAndDeposits.Currency AS Currency,
	|	ScheduleOfPaymentForLoansAndDeposits.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	CASE
	|		WHEN ISNULL(LoanAndDepositBalances.Sum, 0) < CASE
	|			WHEN ISNULL(TurnoverOfLoansAndDeposits.OrderReceiptAmount, 0) < ScheduleOfPaymentForLoansAndDeposits.AmountTotal
	|				THEN ScheduleOfPaymentForLoansAndDeposits.Sum + ISNULL(TurnoverOfLoansAndDeposits.OrderReceiptAmount, 0) - ScheduleOfPaymentForLoansAndDeposits.AmountTotal
	|			WHEN ISNULL(TurnoverOfLoansAndDeposits.PayAmount, 0) > ScheduleOfPaymentForLoansAndDeposits.AmountTotal
	|				THEN ScheduleOfPaymentForLoansAndDeposits.Sum + ISNULL(TurnoverOfLoansAndDeposits.PayAmount, 0) - ScheduleOfPaymentForLoansAndDeposits.AmountTotal
	|			ELSE ScheduleOfPaymentForLoansAndDeposits.Sum
	|		END
	|			THEN ISNULL(LoanAndDepositBalances.Sum, 0)
	|		ELSE CASE
	|			WHEN ISNULL(TurnoverOfLoansAndDeposits.OrderReceiptAmount, 0) < ScheduleOfPaymentForLoansAndDeposits.AmountTotal
	|				THEN ScheduleOfPaymentForLoansAndDeposits.Sum + ISNULL(TurnoverOfLoansAndDeposits.OrderReceiptAmount, 0) - ScheduleOfPaymentForLoansAndDeposits.AmountTotal
	|			WHEN ISNULL(TurnoverOfLoansAndDeposits.PayAmount, 0) > ScheduleOfPaymentForLoansAndDeposits.AmountTotal
	|				THEN ScheduleOfPaymentForLoansAndDeposits.Sum + ISNULL(TurnoverOfLoansAndDeposits.PayAmount, 0) - ScheduleOfPaymentForLoansAndDeposits.AmountTotal
	|			ELSE ScheduleOfPaymentForLoansAndDeposits.Sum
	|		END
	|	END AS Sum
	|INTO TTReclassificationOfLoanAndDepositBalances
	|FROM
	|	TTPaymentScheduleForLoansAndDeposits AS ScheduleOfPaymentForLoansAndDeposits
	|	LEFT JOIN TTTurnoverOfLoansAndDeposits AS TurnoverOfLoansAndDeposits
	|		ON ScheduleOfPaymentForLoansAndDeposits.Contract = TurnoverOfLoansAndDeposits.Contract
	|		 AND ScheduleOfPaymentForLoansAndDeposits.Currency = TurnoverOfLoansAndDeposits.Currency
	|		 AND ScheduleOfPaymentForLoansAndDeposits.AmountType = TurnoverOfLoansAndDeposits.AmountType
	|	LEFT JOIN TTLoanAndDepositBalances AS LoanAndDepositBalances
	|		ON ScheduleOfPaymentForLoansAndDeposits.Contract = LoanAndDepositBalances.Contract
	|		 AND ScheduleOfPaymentForLoansAndDeposits.Currency = LoanAndDepositBalances.Currency
	|		 AND ScheduleOfPaymentForLoansAndDeposits.AmountType = LoanAndDepositBalances.AmountType
	|WHERE
	|	ISNULL(TurnoverOfLoansAndDeposits.OrderReceiptAmount, 0) > (ScheduleOfPaymentForLoansAndDeposits.AmountTotal - ScheduleOfPaymentForLoansAndDeposits.Sum)
	|	AND ISNULL(LoanAndDepositBalances.Sum, 0) > 0
	|");
	
	QueriesTexts.Add("
	|DROP TTLoanAndDepositAgreements");
	
	QueriesTexts.Add("
	|DROP TTPaymentScheduleForLoansAndDeposits");
	
	QueriesTexts.Add("
	|DROP TTTurnoverOfLoansAndDeposits");
	
	QueriesTexts.Add("
	|DROP TTLoanAndDepositBalances");
	
#EndRegion
	
#EndRegion
	
#Region LeaseSettlements
	
#Region ReclassificationOfReceivedLeaseServicesToLongTerm
	
	QueriesTexts.Add("
	|SELECT
	|	FinancialInstrumentsARAP.Period AS Period,
	|	FinancialInstrumentsARAP.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	FinancialInstrumentsARAP.Contract AS Contract,
	|	FinancialInstrumentsARAP.ARAPDocument AS ARAPDocument,
	|	FinancialInstrumentsARAP.Currency AS Currency,
	|	FinancialAccountingPolicy.DurationOfCompanyOperatingCycle AS DurationOfCompanyOperatingCycle,
	|	FinancialInstrumentsARAP.SumExpense AS Sum
	|INTO TTReceiptsOfLeaseObligationsForPeriods
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(
	|		&BeginOfPeriod,
	|		&EndOfPeriod,
	|		Day,
	|		Contract REFS Catalog.LeaseContract
	|		AND AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|	) AS FinancialInstrumentsARAP
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(
	|		&EndOfPeriod,
	|		Organization IN (&CompanyArray)
	|	) AS FinancialAccountingPolicy
	|		ON FinancialInstrumentsARAP.AccountingDimensionByPartners.Organization = FinancialAccountingPolicy.Organization
	|WHERE
	|	FinancialInstrumentsARAP.SumExpense > 0
	|	AND FinancialAccountingPolicy.DurationOfCompanyOperatingCycle > 0
	|	AND FinancialInstrumentsARAP.AmountType = VALUE(Enum.TypesOfLeasePayments.LeaseObligations)
	|INDEX BY
	|	Period,
	|	Contract
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	ReceiptsOfLeaseObligations.Contract AS Contract,
	|	MIN(TermsOfLeaseContracts.Period) AS Period
	|INTO TTPeriodsOfLeaseTerms
	|FROM
	|	TTReceiptsOfLeaseObligationsForPeriods AS ReceiptsOfLeaseObligations
	|	INNER JOIN InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseContracts
	|		ON ReceiptsOfLeaseObligations.Contract = TermsOfLeaseContracts.Contract
	|		 AND ReceiptsOfLeaseObligations.Period <= TermsOfLeaseContracts.Period
	|WHERE
	|	TermsOfLeaseContracts.Active
	|	AND TermsOfLeaseContracts.State = VALUE(Enum.CounterpartyContractStates.Valid)
	|GROUP BY
	|	ReceiptsOfLeaseObligations.Contract
	|INDEX BY
	|	Contract,
	|	Period
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	PeriodsOfTermsOfLeaseAgreements.Contract AS Contract,
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms
	|INTO TTTermsOfLeaseAgreements
	|FROM
	|	TTPeriodsOfLeaseTerms AS PeriodsOfTermsOfLeaseAgreements
	|	INNER JOIN InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseContracts
	|		ON PeriodsOfTermsOfLeaseAgreements.Contract = TermsOfLeaseContracts.Contract
	|		 AND PeriodsOfTermsOfLeaseAgreements.Period = TermsOfLeaseContracts.Period
	|WHERE
	|	TermsOfLeaseContracts.Active
	|	AND TermsOfLeaseContracts.State = VALUE(Enum.CounterpartyContractStates.Valid)
	|INDEX BY
	|	Contract,
	|	EffectiveContractTerms
	|");
	
	QueriesTexts.Add("
	|DROP TTPeriodsOfLeaseTerms");
	
	QueriesTexts.Add("
	|SELECT
	|	ReceiptsOfLeaseObligations.Contract AS Contract,
	|	ReceiptsOfLeaseObligations.Currency AS Currency,
	|	DATEADD(DATEADD(&BeginOfPeriod, MONTH, ReceiptsOfLeaseObligations.DurationOfCompanyOperatingCycle + 1), DAY, -1) AS BeginningOfLongTermPeriod,
	|	MAX(ReceiptsOfLeaseObligations.AccountingDimensionByPartners) AS AccountingDimensionByPartners,
	|	MAX(ReceiptsOfLeaseObligations.ARAPDocument) AS ARAPDocument,
	|	SUM(ReceiptsOfLeaseObligations.Sum) AS Sum
	|INTO TTReceiptsOfLeaseObligations
	|FROM
	|	TTReceiptsOfLeaseObligationsForPeriods AS ReceiptsOfLeaseObligations
	|GROUP BY
	|	ReceiptsOfLeaseObligations.Contract,
	|	ReceiptsOfLeaseObligations.Currency,
	|	ReceiptsOfLeaseObligations.DurationOfCompanyOperatingCycle
	|INDEX BY
	|	Contract,
	|	Currency
	|");
	
	QueriesTexts.Add("
	|DROP TTReceiptsOfLeaseObligationsForPeriods");
	
	QueriesTexts.Add("
	|SELECT
	|	ReceiptsOfLeaseObligations.Contract AS Contract,
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	SUM(CASE
	|		WHEN InterestAccrualSchedule.Date < ReceiptsOfLeaseObligations.BeginningOfLongTermPeriod
	|			THEN 0
	|		ELSE InterestAccrualSchedule.Interests
	|	END) AS LongTermAmount
	|INTO TTOfInterestAccrualOnRent
	|FROM
	|	TTReceiptsOfLeaseObligations AS ReceiptsOfLeaseObligations
	|	INNER JOIN TTTermsOfLeaseAgreements AS TermsOfLeaseContracts
	|		ON ReceiptsOfLeaseObligations.Contract = TermsOfLeaseContracts.Contract
	|	INNER JOIN InformationRegister.LeaseInterestAccrualSchedule AS InterestAccrualSchedule
	|		ON TermsOfLeaseContracts.Contract = InterestAccrualSchedule.Contract
	|		 AND TermsOfLeaseContracts.EffectiveContractTerms = InterestAccrualSchedule.EffectiveContractTerms
	|		 AND InterestAccrualSchedule.Active
	|GROUP BY
	|	ReceiptsOfLeaseObligations.Contract,
	|	TermsOfLeaseContracts.EffectiveContractTerms
	|HAVING
	|	SUM(CASE
	|		WHEN InterestAccrualSchedule.Date < ReceiptsOfLeaseObligations.BeginningOfLongTermPeriod
	|			THEN 0
	|		ELSE InterestAccrualSchedule.Interests
	|	END) > 0
	|INDEX BY
	|	Contract,
	|	EffectiveContractTerms
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	ReceiptsOfLeaseObligations.Contract AS Contract,
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	SUM(ServiceAccrualSchedule.RentalService
	|		+ ServiceAccrualSchedule.DepositPayment
	|		+ ServiceAccrualSchedule.BuyoutValue
	|	) AS AmountTotal,
	|	SUM(CASE
	|		WHEN ServiceAccrualSchedule.Date < ReceiptsOfLeaseObligations.BeginningOfLongTermPeriod
	|			THEN 0
	|		ELSE ServiceAccrualSchedule.RentalService - ServiceAccrualSchedule.RentalServiceVAT
	|			+ ServiceAccrualSchedule.DepositPayment - ServiceAccrualSchedule.SecurityPaymentVATAmount
	|			+ ServiceAccrualSchedule.BuyoutValue - ServiceAccrualSchedule.BuyoutValueVAT
	|	END) AS LongTermAmount
	|INTO TTOfAccrualOfRentalServices
	|FROM
	|	TTReceiptsOfLeaseObligations AS ReceiptsOfLeaseObligations
	|	INNER JOIN TTTermsOfLeaseAgreements AS TermsOfLeaseContracts
	|		ON ReceiptsOfLeaseObligations.Contract = TermsOfLeaseContracts.Contract
	|	INNER JOIN InformationRegister.LeaseServicesAccrualSchedule AS ServiceAccrualSchedule
	|		ON TermsOfLeaseContracts.Contract = ServiceAccrualSchedule.Contract
	|		 AND TermsOfLeaseContracts.EffectiveContractTerms = ServiceAccrualSchedule.EffectiveContractTerms
	|		 AND ServiceAccrualSchedule.Active
	|GROUP BY
	|	ReceiptsOfLeaseObligations.Contract,
	|	TermsOfLeaseContracts.EffectiveContractTerms
	|HAVING
	|	SUM(CASE
	|		WHEN ServiceAccrualSchedule.Date < ReceiptsOfLeaseObligations.BeginningOfLongTermPeriod
	|			THEN 0
	|		ELSE ServiceAccrualSchedule.RentalService - ServiceAccrualSchedule.RentalServiceVAT
	|			+ ServiceAccrualSchedule.DepositPayment - ServiceAccrualSchedule.SecurityPaymentVATAmount
	|			+ ServiceAccrualSchedule.BuyoutValue - ServiceAccrualSchedule.BuyoutValueVAT
	|	END) > 0
	|INDEX BY
	|	Contract,
	|	EffectiveContractTerms
	|");
	
	QueriesTexts.Add("
	|DROP TTTermsOfLeaseAgreements");
	
	QueriesTexts.Add("
	|SELECT
	|	AccrualsOfRentalServices.Contract AS Contract,
	|	SUM(AccrualsOfRentalServices.AmountTotal) AS AmountTotal,
	|	SUM(AccrualsOfRentalServices.LongTermAmount - ISNULL(InterestAccrualsOnLeases.LongTermAmount, 0)) AS LongTermAmount
	|INTO TTLeaseAccrualsAccordingToSchedules
	|FROM
	|	TTOfAccrualOfRentalServices AS AccrualsOfRentalServices
	|	LEFT JOIN TTOfInterestAccrualOnRent AS InterestAccrualsOnLeases
	|		ON AccrualsOfRentalServices.Contract = InterestAccrualsOnLeases.Contract
	|		 AND AccrualsOfRentalServices.EffectiveContractTerms = InterestAccrualsOnLeases.EffectiveContractTerms
	|WHERE
	|	AccrualsOfRentalServices.LongTermAmount > ISNULL(InterestAccrualsOnLeases.LongTermAmount, 0)
	|GROUP BY
	|	AccrualsOfRentalServices.Contract
	|INDEX BY
	|	Contract
	|");
	
	QueriesTexts.Add("
	|DROP TTOfInterestAccrualOnRent");
	
	QueriesTexts.Add("
	|DROP TTOfAccrualOfRentalServices");
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	ReceiptsOfLeaseObligations.Contract AS Contract
	|INTO TTLeaseAgreements
	|FROM
	|	TTReceiptsOfLeaseObligations AS ReceiptsOfLeaseObligations
	|INDEX BY
	|	Contract
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	FinancialInstrumentsARAP.Contract AS Contract,
	|	FinancialInstrumentsARAP.Currency AS Currency,
	|	FinancialInstrumentsARAP.SumExpense AS Sum
	|INTO TTReceiptsOfLeaseLiabilitiesTotal
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(,
	|		&EndOfPeriod,,
	|		Contract IN
	|		(SELECT
	|			LeaseContract.Contract
	|		FROM
	|			TTLeaseAgreements AS LeaseContract)
	|		AND AmountType = VALUE(Enum.TypesOfLeasePayments.LeaseObligations)
	|	) AS FinancialInstrumentsARAP
	|WHERE
	|	FinancialInstrumentsARAP.SumExpense > 0
	|INDEX BY
	|	Contract,
	|	Currency
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	FinancialInstrumentsARAP.Contract AS Contract,
	|	FinancialInstrumentsARAP.Currency AS Currency,
	|	-FinancialInstrumentsARAP.SumBalance AS Sum
	|INTO TTBalanceOfLeaseLiabilities
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|		&PeriodBoundary,
	|		Contract IN
	|		(SELECT
	|			LeaseContract.Contract
	|		FROM
	|			TTLeaseAgreements AS LeaseContract)
	|		AND AmountType = VALUE(Enum.TypesOfLeasePayments.LeaseObligations)
	|	) AS FinancialInstrumentsARAP
	|WHERE
	|	FinancialInstrumentsARAP.SumBalance < 0
	|INDEX BY
	|	Contract,
	|	Currency
	|");

	QueriesTexts.Add("
	|SELECT
	|	ReceiptsOfLeaseObligations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ReceiptsOfLeaseObligations.Contract AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations) AS AmountType,
	|	ReceiptsOfLeaseObligations.ARAPDocument AS ARAPDocument,
	|	ReceiptsOfLeaseObligations.Currency AS Currency,
	|	ReceiptsOfLeaseObligations.BeginningOfLongTermPeriod AS PlannedRepaymentDate,
	|	CASE
	|		WHEN ISNULL(BalancesOfLeaseLiabilities.Sum, 0) < CASE
	|			WHEN (ISNULL(ReceiptsOfLeaseObligationsTotal.Sum, ReceiptsOfLeaseObligations.Sum) - ReceiptsOfLeaseObligations.Sum)
	|				< (LeaseAccrualsAccordingToSchedules.AmountTotal - LeaseAccrualsAccordingToSchedules.LongTermAmount)
	|				THEN ISNULL(ReceiptsOfLeaseObligationsTotal.Sum, ReceiptsOfLeaseObligations.Sum)
	|					- (LeaseAccrualsAccordingToSchedules.AmountTotal - LeaseAccrualsAccordingToSchedules.LongTermAmount)
	|			ELSE ReceiptsOfLeaseObligations.Sum
	|		END
	|			THEN ISNULL(BalancesOfLeaseLiabilities.Sum, 0)
	|		ELSE CASE
	|			WHEN (ISNULL(ReceiptsOfLeaseObligationsTotal.Sum, ReceiptsOfLeaseObligations.Sum) - ReceiptsOfLeaseObligations.Sum)
	|				< (LeaseAccrualsAccordingToSchedules.AmountTotal - LeaseAccrualsAccordingToSchedules.LongTermAmount)
	|				THEN ISNULL(ReceiptsOfLeaseObligationsTotal.Sum, ReceiptsOfLeaseObligations.Sum)
	|					- (LeaseAccrualsAccordingToSchedules.AmountTotal - LeaseAccrualsAccordingToSchedules.LongTermAmount)
	|			ELSE ReceiptsOfLeaseObligations.Sum
	|		END
	|	END AS Sum
	|INTO TTReclassificationOfRentalIncome
	|FROM
	|	TTReceiptsOfLeaseObligations AS ReceiptsOfLeaseObligations
	|	INNER JOIN TTLeaseAccrualsAccordingToSchedules AS LeaseAccrualsAccordingToSchedules
	|		ON ReceiptsOfLeaseObligations.Contract = LeaseAccrualsAccordingToSchedules.Contract
	|	LEFT JOIN TTReceiptsOfLeaseLiabilitiesTotal AS ReceiptsOfLeaseObligationsTotal
	|		ON ReceiptsOfLeaseObligations.Contract = ReceiptsOfLeaseObligationsTotal.Contract
	|		 AND ReceiptsOfLeaseObligations.Currency = ReceiptsOfLeaseObligationsTotal.Currency
	|	LEFT JOIN TTBalanceOfLeaseLiabilities AS BalancesOfLeaseLiabilities
	|		ON ReceiptsOfLeaseObligations.Contract = BalancesOfLeaseLiabilities.Contract
	|		 AND ReceiptsOfLeaseObligations.Currency = BalancesOfLeaseLiabilities.Currency
	|WHERE
	|	ISNULL(ReceiptsOfLeaseObligationsTotal.Sum, ReceiptsOfLeaseObligations.Sum)
	|		> (LeaseAccrualsAccordingToSchedules.AmountTotal - LeaseAccrualsAccordingToSchedules.LongTermAmount)
	|	AND ISNULL(BalancesOfLeaseLiabilities.Sum, 0) > 0
	|");
	
	QueriesTexts.Add("
	|DROP TTLeaseAgreements");
	
	QueriesTexts.Add("
	|DROP TTReceiptsOfLeaseObligations");
	
	QueriesTexts.Add("
	|DROP TTReceiptsOfLeaseLiabilitiesTotal");
	
	QueriesTexts.Add("
	|DROP TTBalanceOfLeaseLiabilities");
	
	QueriesTexts.Add("
	|DROP TTLeaseAccrualsAccordingToSchedules");
	
#EndRegion
	
#Region ReclassificationOfLeaseSettlementBalancesToShortTerm
	
	QueriesTexts.Add("
	|SELECT
	|	LeaseContract.Ref AS Ref,
	|	LeaseContract.ARAPCurrency AS Currency,
	|	AccountingDimensionByPartners.DimensionKey AS DimensionKey,
	|	DATEADD(DATEADD(&BeginOfPeriod, MONTH, FinancialAccountingPolicy.DurationOfCompanyOperatingCycle), DAY, -1) AS BeginningOfRepaymentPeriod,
	|	DATEADD(ENDOFPERIOD(DATEADD(&BeginOfPeriod, MONTH, FinancialAccountingPolicy.DurationOfCompanyOperatingCycle), MONTH), DAY, -1) AS EndOfRepaymentPeriod
	|INTO TTLeaseAgreements
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|	INNER JOIN InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|		ON LeaseContract.Organization = AccountingDimensionByPartners.Organization
	|		 AND LeaseContract.Counterparty = AccountingDimensionByPartners.Counterparty
	|		 AND LeaseContract.Partner = AccountingDimensionByPartners.Partner
	|		 AND AccountingDimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		 AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = AccountingDimensionByPartners.LineOfBusiness
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(
	|		&EndOfPeriod,
	|		Organization IN (&CompanyArray)
	|	) AS FinancialAccountingPolicy
	|		ON LeaseContract.Organization = FinancialAccountingPolicy.Organization
	|WHERE
	|	LeaseContract.Organization IN (&CompanyArray)
	|	AND FinancialAccountingPolicy.DurationOfCompanyOperatingCycle > 0
	|INDEX BY
	|	Ref
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract AS Contract,
	|	TermsOfLeaseContracts.BeginningOfRepaymentPeriod AS BeginningOfRepaymentPeriod,
	|	MAX(TermsOfLeaseContracts.EndOfValidityPeriod) AS EndOfRepaymentPeriod
	|INTO TTTermsOfLeaseAgreements
	|FROM
	|	(SELECT
	|		TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|		TermsOfLeaseContracts.Contract AS Contract,
	|		LeaseContract.BeginningOfRepaymentPeriod AS BeginningOfRepaymentPeriod,
	|		MIN(ISNULL(
	|			DATEADD(TermsOfLeaseAgreementsAreNotValid.Period, DAY, -1),
	|			LeaseContract.EndOfRepaymentPeriod)
	|		) AS EndOfValidityPeriod
	|	FROM
	|		InformationRegister.TermsOfLeaseContracts.SliceLast(
	|			&BeginOfPeriod,
	|			Contract IN
	|			(SELECT
	|				LeaseContract.Ref
	|			FROM
	|				TTLeaseAgreements AS LeaseContract)
	|		) AS TermsOfLeaseContracts
	|		INNER JOIN TTLeaseAgreements AS LeaseContract
	|			ON TermsOfLeaseContracts.Contract = LeaseContract.Ref
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseAgreementsAreNotValid
	|			ON TermsOfLeaseAgreementsAreNotValid.Contract = TermsOfLeaseContracts.Contract
	|			 AND TermsOfLeaseAgreementsAreNotValid.Period >= &BeginOfPeriod
	|			 AND TermsOfLeaseAgreementsAreNotValid.Period <= LeaseContract.EndOfRepaymentPeriod
	|			 AND TermsOfLeaseAgreementsAreNotValid.State = VALUE(Enum.CounterpartyContractStates.Closed)
	|			 AND TermsOfLeaseAgreementsAreNotValid.Active
	|	WHERE
	|		TermsOfLeaseContracts.State = VALUE(Enum.CounterpartyContractStates.Valid)
	|	GROUP BY
	|		TermsOfLeaseContracts.EffectiveContractTerms,
	|		TermsOfLeaseContracts.Contract,
	|		LeaseContract.BeginningOfRepaymentPeriod,
	|		LeaseContract.EndOfRepaymentPeriod
	|	HAVING
	|		MIN(ISNULL(
	|			DATEADD(TermsOfLeaseAgreementsAreNotValid.Period, DAY, -1),
	|			LeaseContract.EndOfRepaymentPeriod)
	|		) >= LeaseContract.BeginningOfRepaymentPeriod
	|
	|	UNION ALL
	|
	|	SELECT
	|		TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|		TermsOfLeaseContracts.Contract AS Contract,
	|		LeaseContract.BeginningOfRepaymentPeriod AS BeginningOfRepaymentPeriod,
	|		MIN(ISNULL(
	|			DATEADD(TermsOfLeaseAgreementsAreNotValid.Period, DAY, -1),
	|			LeaseContract.EndOfRepaymentPeriod)
	|		) AS EndOfValidityPeriod
	|	FROM
	|		InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseContracts
	|		INNER JOIN TTLeaseAgreements AS LeaseContract
	|			ON TermsOfLeaseContracts.Contract = LeaseContract.Ref
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts AS TermsOfLeaseAgreementsAreNotValid
	|			ON TermsOfLeaseAgreementsAreNotValid.Contract = TermsOfLeaseContracts.Contract
	|			 AND TermsOfLeaseAgreementsAreNotValid.Period > TermsOfLeaseContracts.Period
	|			 AND TermsOfLeaseAgreementsAreNotValid.Period <= LeaseContract.EndOfRepaymentPeriod
	|			 AND TermsOfLeaseAgreementsAreNotValid.State = VALUE(Enum.CounterpartyContractStates.Closed)
	|			 AND TermsOfLeaseAgreementsAreNotValid.Active
	|	WHERE
	|		TermsOfLeaseContracts.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND TermsOfLeaseContracts.State = VALUE(Enum.CounterpartyContractStates.Valid)
	|		AND TermsOfLeaseContracts.Active
	|	GROUP BY
	|		TermsOfLeaseContracts.EffectiveContractTerms,
	|		TermsOfLeaseContracts.Contract,
	|		LeaseContract.BeginningOfRepaymentPeriod,
	|		LeaseContract.EndOfRepaymentPeriod
	|	HAVING
	|		MIN(ISNULL(
	|			DATEADD(TermsOfLeaseAgreementsAreNotValid.Period, DAY, -1),
	|			LeaseContract.EndOfRepaymentPeriod)
	|		) >= LeaseContract.BeginningOfRepaymentPeriod
	|	) AS TermsOfLeaseContracts
	|GROUP BY
	|	TermsOfLeaseContracts.EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract,
	|	TermsOfLeaseContracts.BeginningOfRepaymentPeriod
	|INDEX BY
	|	EffectiveContractTerms,
	|	Contract
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract AS Contract,
	|	SUM(InterestAccrualSchedule.Interests) AS Sum
	|INTO TTOfInterestAccrualOnRent
	|FROM
	|	TTTermsOfLeaseAgreements AS TermsOfLeaseContracts
	|	INNER JOIN InformationRegister.LeaseInterestAccrualSchedule AS InterestAccrualSchedule
	|		ON TermsOfLeaseContracts.EffectiveContractTerms = InterestAccrualSchedule.EffectiveContractTerms
	|		 AND TermsOfLeaseContracts.Contract = InterestAccrualSchedule.Contract
	|		 AND InterestAccrualSchedule.Date BETWEEN TermsOfLeaseContracts.BeginningOfRepaymentPeriod AND TermsOfLeaseContracts.EndOfRepaymentPeriod
	|		 AND InterestAccrualSchedule.Active
	|GROUP BY
	|	TermsOfLeaseContracts.EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract
	|HAVING
	|	SUM(InterestAccrualSchedule.Interests) > 0
	|INDEX BY
	|	EffectiveContractTerms,
	|	Contract
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	TermsOfLeaseContracts.EffectiveContractTerms AS EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract AS Contract,
	|	MAX(ServiceAccrualSchedule.Date) AS PlannedRepaymentDate,
	|	SUM(ServiceAccrualSchedule.RentalService
	|		+ ServiceAccrualSchedule.DepositPayment
	|		+ ServiceAccrualSchedule.BuyoutValue
	|	) AS AmountTotal,
	|	SUM(CASE
	|		WHEN ServiceAccrualSchedule.Date < TermsOfLeaseContracts.BeginningOfRepaymentPeriod
	|			THEN 0
	|		ELSE ServiceAccrualSchedule.RentalService - ServiceAccrualSchedule.RentalServiceVAT
	|			+ ServiceAccrualSchedule.DepositPayment - ServiceAccrualSchedule.SecurityPaymentVATAmount
	|			+ ServiceAccrualSchedule.BuyoutValue - ServiceAccrualSchedule.BuyoutValueVAT
	|	END) AS Sum
	|INTO TTOfAccrualOfRentalServices
	|FROM
	|	TTTermsOfLeaseAgreements AS TermsOfLeaseContracts
	|	INNER JOIN InformationRegister.LeaseServicesAccrualSchedule AS ServiceAccrualSchedule
	|		ON TermsOfLeaseContracts.EffectiveContractTerms = ServiceAccrualSchedule.EffectiveContractTerms
	|		 AND TermsOfLeaseContracts.Contract = ServiceAccrualSchedule.Contract
	|		 AND ServiceAccrualSchedule.Date <= TermsOfLeaseContracts.EndOfRepaymentPeriod
	|		 AND ServiceAccrualSchedule.Active
	|GROUP BY
	|	TermsOfLeaseContracts.EffectiveContractTerms,
	|	TermsOfLeaseContracts.Contract
	|HAVING
	|	SUM(CASE
	|		WHEN ServiceAccrualSchedule.Date < TermsOfLeaseContracts.BeginningOfRepaymentPeriod
	|			THEN 0
	|		ELSE ServiceAccrualSchedule.RentalService - ServiceAccrualSchedule.RentalServiceVAT
	|			+ ServiceAccrualSchedule.DepositPayment - ServiceAccrualSchedule.SecurityPaymentVATAmount
	|			+ ServiceAccrualSchedule.BuyoutValue - ServiceAccrualSchedule.BuyoutValueVAT
	|	END) > 0
	|INDEX BY
	|	EffectiveContractTerms,
	|	Contract
	|");
	
	QueriesTexts.Add("
	|DROP TTTermsOfLeaseAgreements");
	
	QueriesTexts.Add("
	|SELECT
	|	LeaseContract.DimensionKey AS AccountingDimensionByPartners,
	|	LeaseContract.Ref AS Contract,
	|	LeaseContract.Currency AS Currency,
	|	MAX(AccrualsOfRentalServices.PlannedRepaymentDate) AS PlannedRepaymentDate,
	|	SUM(AccrualsOfRentalServices.AmountTotal) AS AmountTotal,
	|	SUM(AccrualsOfRentalServices.Sum - ISNULL(InterestAccrualsOnLeases.Sum, 0)) AS Sum
	|INTO TTLeaseAccrualsAccordingToSchedules
	|FROM
	|	TTLeaseAgreements AS LeaseContract
	|	INNER JOIN TTOfAccrualOfRentalServices AS AccrualsOfRentalServices
	|		ON LeaseContract.Ref = AccrualsOfRentalServices.Contract
	|	LEFT JOIN TTOfInterestAccrualOnRent AS InterestAccrualsOnLeases
	|		ON AccrualsOfRentalServices.EffectiveContractTerms = InterestAccrualsOnLeases.EffectiveContractTerms
	|		 AND AccrualsOfRentalServices.Contract = InterestAccrualsOnLeases.Contract
	|WHERE
	|	AccrualsOfRentalServices.Sum > ISNULL(InterestAccrualsOnLeases.Sum, 0)
	|GROUP BY
	|	LeaseContract.DimensionKey,
	|	LeaseContract.Ref,
	|	LeaseContract.Currency
	|INDEX BY
	|	Contract,
	|	Currency
	|");
	
	QueriesTexts.Add("
	|DROP TTLeaseAgreements");
	
	QueriesTexts.Add("
	|DROP TTOfInterestAccrualOnRent");
	
	QueriesTexts.Add("
	|DROP TTOfAccrualOfRentalServices");
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	LeaseAccrualsAccordingToSchedules.Contract AS Contract
	|INTO TTLeaseAgreements
	|FROM
	|	TTLeaseAccrualsAccordingToSchedules AS LeaseAccrualsAccordingToSchedules
	|INDEX BY
	|	Contract
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	FinancialInstrumentsARAP.Contract AS Contract,
	|	FinancialInstrumentsARAP.Currency AS Currency,
	|	MAX(FinancialInstrumentsARAP.AccountingDimensionByPartners) AS AccountingDimensionByPartners,
	|	MAX(FinancialInstrumentsARAP.ARAPDocument) AS ARAPDocument,
	|	CASE
	|		WHEN SUM(FinancialInstrumentsARAP.SumExpense) < 0
	|			THEN 0
	|		ELSE SUM(FinancialInstrumentsARAP.SumExpense)
	|	END AS OrderReceiptAmount,
	|	CASE
	|		WHEN SUM(FinancialInstrumentsARAP.SumReceipt) < 0
	|			THEN 0
	|		ELSE SUM(FinancialInstrumentsARAP.SumReceipt)
	|	END AS RepaymentAmount
	|INTO TTTurnoverOfLeaseObligations
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(,
	|		&EndOfPeriod,,
	|		Contract IN
	|		(SELECT
	|			LeaseContract.Contract
	|		FROM
	|			TTLeaseAgreements AS LeaseContract)
	|		AND AmountType = VALUE(Enum.TypesOfLeasePayments.LeaseObligations)
	|	) AS FinancialInstrumentsARAP
	|GROUP BY
	|	FinancialInstrumentsARAP.Contract,
	|	FinancialInstrumentsARAP.Currency
	|INDEX BY
	|	Contract,
	|	Currency
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	FinancialInstrumentsARAP.Contract AS Contract,
	|	FinancialInstrumentsARAP.Currency AS Currency,
	|	-FinancialInstrumentsARAP.SumBalance AS Sum
	|INTO TTBalanceOfLeaseLiabilities
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|		&BeginOfPeriod,
	|		Contract IN
	|		(SELECT
	|			LeaseContract.Contract
	|		FROM
	|			TTLeaseAgreements AS LeaseContract)
	|		AND AmountType = VALUE(Enum.TypesOfLeasePayments.LeaseObligations)
	|	) AS FinancialInstrumentsARAP
	|WHERE
	|	FinancialInstrumentsARAP.SumBalance < 0
	|INDEX BY
	|	Contract,
	|	Currency
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	LeaseAccrualsAccordingToSchedules.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	LeaseAccrualsAccordingToSchedules.Contract AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations) AS AmountType,
	|	ISNULL(TurnoverOfLeaseObligations.ARAPDocument, UNDEFINED) AS ARAPDocument,
	|	LeaseAccrualsAccordingToSchedules.Currency AS Currency,
	|	LeaseAccrualsAccordingToSchedules.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	CASE
	|		WHEN ISNULL(BalancesOfLeaseLiabilities.Sum, 0) < CASE
	|			WHEN ISNULL(TurnoverOfLeaseObligations.OrderReceiptAmount, 0) < LeaseAccrualsAccordingToSchedules.AmountTotal
	|				THEN LeaseAccrualsAccordingToSchedules.Sum + ISNULL(TurnoverOfLeaseObligations.OrderReceiptAmount, 0) - LeaseAccrualsAccordingToSchedules.AmountTotal
	|			WHEN ISNULL(TurnoverOfLeaseObligations.RepaymentAmount, 0) > LeaseAccrualsAccordingToSchedules.AmountTotal
	|				THEN LeaseAccrualsAccordingToSchedules.Sum + ISNULL(TurnoverOfLeaseObligations.RepaymentAmount, 0) - LeaseAccrualsAccordingToSchedules.AmountTotal
	|			ELSE LeaseAccrualsAccordingToSchedules.Sum
	|		END
	|			THEN ISNULL(BalancesOfLeaseLiabilities.Sum, 0)
	|		ELSE CASE
	|			WHEN ISNULL(TurnoverOfLeaseObligations.OrderReceiptAmount, 0) < LeaseAccrualsAccordingToSchedules.AmountTotal
	|				THEN LeaseAccrualsAccordingToSchedules.Sum + ISNULL(TurnoverOfLeaseObligations.OrderReceiptAmount, 0) - LeaseAccrualsAccordingToSchedules.AmountTotal
	|			WHEN ISNULL(TurnoverOfLeaseObligations.RepaymentAmount, 0) > LeaseAccrualsAccordingToSchedules.AmountTotal
	|				THEN LeaseAccrualsAccordingToSchedules.Sum + ISNULL(TurnoverOfLeaseObligations.RepaymentAmount, 0) - LeaseAccrualsAccordingToSchedules.AmountTotal
	|			ELSE LeaseAccrualsAccordingToSchedules.Sum
	|		END
	|	END AS Sum
	|INTO TTReclassificationOfLeaseBalances
	|FROM
	|	TTLeaseAccrualsAccordingToSchedules AS LeaseAccrualsAccordingToSchedules
	|	LEFT JOIN TTTurnoverOfLeaseObligations AS TurnoverOfLeaseObligations
	|		ON LeaseAccrualsAccordingToSchedules.Contract = TurnoverOfLeaseObligations.Contract
	|		 AND LeaseAccrualsAccordingToSchedules.Currency = TurnoverOfLeaseObligations.Currency
	|	LEFT JOIN TTBalanceOfLeaseLiabilities AS BalancesOfLeaseLiabilities
	|		ON LeaseAccrualsAccordingToSchedules.Contract = BalancesOfLeaseLiabilities.Contract
	|		 AND LeaseAccrualsAccordingToSchedules.Currency = BalancesOfLeaseLiabilities.Currency
	|WHERE
	|	ISNULL(TurnoverOfLeaseObligations.OrderReceiptAmount, 0) > (LeaseAccrualsAccordingToSchedules.AmountTotal - LeaseAccrualsAccordingToSchedules.Sum)
	|	AND ISNULL(BalancesOfLeaseLiabilities.Sum, 0) > 0
	|");
	
	QueriesTexts.Add("
	|DROP TTLeaseAgreements");
	
	QueriesTexts.Add("
	|DROP TTLeaseAccrualsAccordingToSchedules");
	
	QueriesTexts.Add("
	|DROP TTTurnoverOfLeaseObligations");
	
	QueriesTexts.Add("
	|DROP TTBalanceOfLeaseLiabilities");
	
#EndRegion
	
#EndRegion
	
#Region ExchangeRates
	
	QueriesTexts.Add("
	|SELECT
	|	ExchangeRates.Currency AS Currency,
	|	ExchangeRates.BaseCurrency AS BaseCurrency,
	|	ExchangeRates.CourseNumerator AS CourseNumerator,
	|	ExchangeRates.CourseDenominator AS CourseDenominator
	|INTO TTExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&EndOfPeriod) AS ExchangeRates
	|INDEX BY
	|	Currency,
	|	BaseCurrency
	|");
	
#EndRegion
	
#Region SummaryTable
	
	QueriesTexts.Add("
	|SELECT
	|	ReclassificationOfFinancialInstruments.ReclassificationOfBalances AS ReclassificationOfBalances,
	|	ReclassificationOfFinancialInstruments.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ReclassificationOfFinancialInstruments.Contract AS Contract,
	|	ReclassificationOfFinancialInstruments.AmountType AS AmountType,
	|	ReclassificationOfFinancialInstruments.ARAPDocument AS ARAPDocument,
	|	ReclassificationOfFinancialInstruments.Currency AS Currency,
	|	ReclassificationOfFinancialInstruments.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	ReclassificationOfFinancialInstruments.Sum AS Sum,
	|	CASE
	|		WHEN ReclassificationOfFinancialInstruments.Currency = Companies.LocalAccountingCurrency
	|			THEN ReclassificationOfFinancialInstruments.Sum
	|		WHEN ExchangeRates.Currency IS NULL
	|			THEN 0
	|		WHEN ExchangeRates.CourseDenominator = 0
	|			THEN 0
	|		ELSE CAST(ReclassificationOfFinancialInstruments.Sum
	|			* ExchangeRates.CourseNumerator / ExchangeRates.CourseDenominator
	|			AS NUMBER(31, 2))
	|	END AS SumCompl,
	|	CASE
	|		WHEN ReclassificationOfFinancialInstruments.Currency = Constants.ManagementAccountingCurrency
	|			THEN ReclassificationOfFinancialInstruments.Sum
	|		WHEN ExchangeRates.Currency IS NULL OR ManExchangeRates.Currency IS NULL
	|			THEN 0
	|		WHEN ExchangeRates.CourseDenominator = 0 OR ManExchangeRates.CourseNumerator = 0
	|			THEN 0
	|		ELSE CAST(ReclassificationOfFinancialInstruments.Sum
	|			* ExchangeRates.CourseNumerator / ExchangeRates.CourseDenominator
	|			/ ManExchangeRates.CourseNumerator * ManExchangeRates.CourseDenominator
	|			AS NUMBER(31, 2))
	|	END AS SumMan
	|INTO FinancialInstrumentsARAP
	|FROM
	|	(SELECT
	|		FALSE AS ReclassificationOfBalances,
	|		ReclassificationOfLoansAndDeposits.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		ReclassificationOfLoansAndDeposits.Contract AS Contract,
	|		ReclassificationOfLoansAndDeposits.AmountType AS AmountType,
	|		ReclassificationOfLoansAndDeposits.ARAPDocument AS ARAPDocument,
	|		ReclassificationOfLoansAndDeposits.Currency AS Currency,
	|		ReclassificationOfLoansAndDeposits.PlannedRepaymentDate AS PlannedRepaymentDate,
	|		ReclassificationOfLoansAndDeposits.Sum AS Sum
	|	FROM
	|		TTReclassificationOfProceedsFromLoansAndDeposits AS ReclassificationOfLoansAndDeposits
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TRUE AS ReclassificationOfBalances,
	|		ReclassificationOfLoansAndDeposits.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		ReclassificationOfLoansAndDeposits.Contract AS Contract,
	|		ReclassificationOfLoansAndDeposits.AmountType AS AmountType,
	|		ReclassificationOfLoansAndDeposits.ARAPDocument AS ARAPDocument,
	|		ReclassificationOfLoansAndDeposits.Currency AS Currency,
	|		ReclassificationOfLoansAndDeposits.PlannedRepaymentDate AS PlannedRepaymentDate,
	|		ReclassificationOfLoansAndDeposits.Sum AS Sum
	|	FROM
	|		TTReclassificationOfLoanAndDepositBalances AS ReclassificationOfLoansAndDeposits
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		FALSE AS ReclassificationOfBalances,
	|		ReclassificationOfLeaseServices.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		ReclassificationOfLeaseServices.Contract AS Contract,
	|		ReclassificationOfLeaseServices.AmountType AS AmountType,
	|		ReclassificationOfLeaseServices.ARAPDocument AS ARAPDocument,
	|		ReclassificationOfLeaseServices.Currency AS Currency,
	|		ReclassificationOfLeaseServices.PlannedRepaymentDate AS PlannedRepaymentDate,
	|		ReclassificationOfLeaseServices.Sum AS Sum
	|	FROM
	|		TTReclassificationOfRentalIncome AS ReclassificationOfLeaseServices
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TRUE AS ReclassificationOfBalances,
	|		ReclassificationOfLeaseServices.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		ReclassificationOfLeaseServices.Contract AS Contract,
	|		ReclassificationOfLeaseServices.AmountType AS AmountType,
	|		ReclassificationOfLeaseServices.ARAPDocument AS ARAPDocument,
	|		ReclassificationOfLeaseServices.Currency AS Currency,
	|		ReclassificationOfLeaseServices.PlannedRepaymentDate AS PlannedRepaymentDate,
	|		ReclassificationOfLeaseServices.Sum AS Sum
	|	FROM
	|		TTReclassificationOfLeaseBalances AS ReclassificationOfLeaseServices
	|	) AS ReclassificationOfFinancialInstruments
	|	INNER JOIN Catalog.Companies AS Companies
	|		ON ReclassificationOfFinancialInstruments.AccountingDimensionByPartners.Organization = Companies.Ref
	|	LEFT JOIN Constants AS Constants
	|		ON TRUE
	|	LEFT JOIN TTExchangeRates AS ExchangeRates
	|		ON ReclassificationOfFinancialInstruments.Currency = ExchangeRates.Currency
	|		 AND Companies.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|	LEFT JOIN TTExchangeRates AS ManExchangeRates
	|		ON Constants.ManagementAccountingCurrency = ManExchangeRates.Currency
	|		 AND Companies.LocalAccountingCurrency = ManExchangeRates.BaseCurrency
	|");
	
	QueriesTexts.Add("
	|DROP TTReclassificationOfProceedsFromLoansAndDeposits");
	
	QueriesTexts.Add("
	|DROP TTReclassificationOfLoanAndDepositBalances");
	
	QueriesTexts.Add("
	|DROP TTReclassificationOfRentalIncome");
	
	QueriesTexts.Add("
	|DROP TTReclassificationOfLeaseBalances");
	
	QueriesTexts.Add("
	|DROP TTExchangeRates");
	
#EndRegion
	
	Return StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
EndFunction

Function TextOfRequestForReclassificationOfBalancesSettlementsOnFinancialInstruments()
	
	QueryText = "
	|SELECT
	|	TRUE AS Active,
	|	CASE
	|		WHEN SettlementsOnInstruments.Contract.ContractKind IN (
	|			VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing),
	|			VALUE(Enum.ContractKindsOfFinancialInstruments.Lease))
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS Period,
	|	&Recorder AS Recorder,
	|	SettlementsOnInstruments.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	SettlementsOnInstruments.Contract AS Contract,
	|	SettlementsOnInstruments.AmountType AS AmountType,
	|	SettlementsOnInstruments.ARAPDocument AS ARAPDocument,
	|	SettlementsOnInstruments.Currency AS Currency,
	|	CASE
	|		WHEN SettlementsOnInstruments.ReclassificationOfBalances
	|			THEN SettlementsOnInstruments.PlannedRepaymentDate
	|		ELSE ENDOFPERIOD(&DateOfTransaction, MONTH)
	|	END AS PlannedRepaymentDate,
	|	SettlementsOnInstruments.Sum AS Sum,
	|	SettlementsOnInstruments.SumCompl AS SumCompl,
	|	SettlementsOnInstruments.SumMan AS SumMan,
	|	SettlementsOnInstruments.FinRecordID AS RowID,
	|	SettlementsOnInstruments.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfLongTermAssetsAndLiabilities) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|INTO PlacementTable
	|FROM
	|	FinancialInstrumentsARAP AS SettlementsOnInstruments
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE AS Active,
	|	CASE
	|		WHEN SettlementsOnInstruments.Contract.ContractKind IN (
	|			VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing),
	|			VALUE(Enum.ContractKindsOfFinancialInstruments.Lease))
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	ENDOFPERIOD(&DateOfTransaction, MONTH) AS Period,
	|	&Recorder AS Recorder,
	|	SettlementsOnInstruments.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	SettlementsOnInstruments.Contract AS Contract,
	|	SettlementsOnInstruments.AmountType AS AmountType,
	|	SettlementsOnInstruments.ARAPDocument AS ARAPDocument,
	|	SettlementsOnInstruments.Currency AS Currency,
	|	CASE
	|		WHEN SettlementsOnInstruments.ReclassificationOfBalances
	|			THEN ENDOFPERIOD(&DateOfTransaction, MONTH)
	|		ELSE SettlementsOnInstruments.PlannedRepaymentDate
	|	END AS PlannedRepaymentDate,
	|	SettlementsOnInstruments.Sum AS Sum,
	|	SettlementsOnInstruments.SumCompl AS SumCompl,
	|	SettlementsOnInstruments.SumMan AS SumMan,
	|	SettlementsOnInstruments.FinRecordID AS RowID,
	|	SettlementsOnInstruments.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfLongTermAssetsAndLiabilities) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	FinancialInstrumentsARAP AS SettlementsOnInstruments
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion
