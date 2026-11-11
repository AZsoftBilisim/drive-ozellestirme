
#Region Public

// Calculates the approximate annual IRR rate for a payment schedule with an arbitrary frequency. Corresponds to the Excel function chistendom.
// The calculation is performed using the Newton method.
// IRR is the internal rate of return at which the investment is equal to the present value of future earnings, i.e. NPV = 0.
//
// Parameters:
//    Payments_2 - Array of Number - Payment amounts according to the schedule. At least one payment in the schedule must be positive and one negative.
//    Dates - Array of Date - Payment date. The date indexes in the array must match the corresponding amount indexes in the payment array.
//    Assumption - Number - Estimated bid (set as a number: for example, 0.25 corresponds to 25%).
//                            Optional parameter, by default, the original rate = 0.1.
//
// Returns:
//    Number, Undefined - The IRR rate. If the bid could not be calculated or the input data is incorrect, it is returned Indefinitely.
//
Function IRR(Payments_2, Dates, Assumption = Undefined) Export
	
	If Assumption = Undefined Then
		X0 = 0.1;
	Else
		X0 = Assumption;
	EndIf;
	
	ConvertIncomingParametersToCHISTVNDOH(Payments_2, Dates);
	
	If Not CheckIncomingCHISTVNDOHParameters(Payments_2) Then
		Return Undefined;
	EndIf;
	
	Deadlines = New Array;
	For Indus = 0 To Dates.Count() - 1 Do
		Deadlines.Add((Dates[0] - Dates[Indus]) / 31536000); // In days
	EndDo;
	
	X1 = 0.0;
	Tolerance = 0.00000001;
	
	MaxIterations = 500;
	NumberOfIterations = 0;
	
	While NumberOfIterations < MaxIterations Do
		
		Denominator = Total_DF_XIRR(Payments_2, Deadlines, X0);
		If Denominator = 0 Then
			Return Undefined;
		EndIf;
		
		X1 = X0 - Total_F_XIRR(Payments_2, Deadlines, X0) / Denominator;
		Error = ModuleNumbers(X1 - X0);
		X0 = X1;
		
		If Error <= Tolerance Then
			Return X0;
		EndIf;
		
		NumberOfIterations = NumberOfIterations + 1;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Calculates the NPV value for a payment schedule with the same frequency. Corresponds to the Excel NPV function.
// Payments should not include the initial investment, it is deducted from the result.
// Net present value (NPV) is the sum of discounted payment flows reduced to the starting date.
//
// Parameters:
//    Rate1 - Number - Discount rate (set as a number: for example, 0.25 corresponds to 25%).
//    Payments_2 - Array of Number - Payment amounts according to the schedule.
//
// Returns:
//    Number - NPV value.
//
Function PPP(Rate1, Payments_2) Export
	
	Rez = 0;
	
	For PeriodNumber = 0 To Payments_2.Count()-1 Do
		Rez = Rez + QuotedNPVPayment(Rate1, Payments_2[PeriodNumber], PeriodNumber+1);
	EndDo;
	
	Return Rez;
	
EndFunction

// Calculates the NPV value for a payment schedule with an arbitrary frequency. Corresponds to the Excel function XNPV.
// Payments must include the initial investment.
// Net present value (NPV) is the sum of discounted payment flows reduced to the starting date.
//
// Parameters:
//    Rate1 - Number - Discount rate (set as a number: for example, 0.25 corresponds to 25%).
//    Payments_2 - Array of Number - Payment amounts according to the schedule.
//    Dates - Array of Date - Payment date. The date indexes in the array must match the corresponding amount indexes in the payment array.
//
// Returns:
//    Number - NPV value.
//
Function Thorns(Rate1, Payments_2, Dates) Export
	
	Rez = 0;
	
	Deadlines = New Array;
	For Indus = 0 To Dates.Count() - 1 Do
		Deadlines.Add((Dates[Indus] - Dates[0]) / 31536000); // In days
	EndDo;
	
	For PeriodNumber = 0 To Payments_2.Count()-1 Do
		Rez = Rez + QuotedPaymentXNPV(Rate1, Payments_2[PeriodNumber], Deadlines[PeriodNumber]);
	EndDo;
	
	Return Rez;
	
EndFunction

// Generates a table to convert the amount of currency control. and regl. accounting's. 
// 
// Parameters:
// 	QueryTexts - ValueList - 
// 	TableName - String - 
// 	MultipleCompanies - Boolean - flag for getting query tables for conversion to currency for several organizations
//
Procedure QueryTextTTCurrencyConversionFactors(
			QueryTexts,
			TableName = "TTCurrencyConversionFactors",
			MultipleCompanies = False) Export
	
	QueryText = "
	|SELECT
	|	PeriodsTable.ARAPCurrency,
	|	PeriodsTable.Date,
	|	&OrganizationFields,
	|	MAX(ExchangeRates.Period) AS DateOfCourse
	|INTO TableOfSettlementPeriods
	|FROM
	|	PeriodsTable
	|	,&CompanyTable
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates AS ExchangeRates
	|	ON
	|		ExchangeRates.Currency = PeriodsTable.ARAPCurrency
	|		AND ExchangeRates.Period <= PeriodsTable.DATE
	|		AND &BaseCurrencyCondition
	|GROUP BY
	|	PeriodsTable.ARAPCurrency,
	|	&GroupingOrganizations,
	|	PeriodsTable.Date
	|";
	
	AdjustmentOfCurrencyTranslationSubqueryByOrganization(QueryText, "TableOfSettlementPeriods", MultipleCompanies);
	QueryTexts.Add(QueryText, "TableOfSettlementPeriods");
	
	QueryText = "
	|SELECT
	|	PeriodsTable.ARAPCurrency,
	|	PeriodsTable.Date,
	|	&OrganizationFields,
	|	MAX(ExchangeRates.Period) AS DateOfCourse
	|INTO TableOfManPeriods
	|FROM
	|	PeriodsTable
	|	,&CompanyTable
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates AS ExchangeRates
	|	ON
	|		ExchangeRates.Currency = &CurrencyOfMan
	|		AND ExchangeRates.Period <= PeriodsTable.DATE
	|		AND &BaseCurrencyCondition
	|GROUP BY
	|	PeriodsTable.ARAPCurrency,
	|	&GroupingOrganizations,
	|	PeriodsTable.Date
	|";
	
	AdjustmentOfCurrencyTranslationSubqueryByOrganization(QueryText, "TableOfManPeriods", MultipleCompanies);
	QueryTexts.Add(QueryText, "TableOfManPeriods");
	
	QueryText = "
	|SELECT
	|	PeriodsTable.ARAPCurrency,
	|	PeriodsTable.Date,
	|	&OrganizationFields,
	|	MAX(ExchangeRates.Period) AS DateOfCourse
	|INTO TableOfLocalPeriods
	|FROM
	|	PeriodsTable
	|	,&CompanyTable
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates AS ExchangeRates
	|	ON
	|		&CurrencyCondition
	|		AND ExchangeRates.Period <= PeriodsTable.DATE
	|		AND &BaseCurrencyCondition
	|GROUP BY
	|	PeriodsTable.ARAPCurrency,
	|	&GroupingOrganizations,
	|	PeriodsTable.Date
	|";
	
	AdjustmentOfCurrencyTranslationSubqueryByOrganization(QueryText, "TableOfLocalPeriods", MultipleCompanies);
	QueryTexts.Add(QueryText, "TableOfLocalPeriods");
	
	QueryText = "
	|SELECT
	|	PeriodsTable.ARAPCurrency,
	|	PeriodsTable.Date,
	|	&OrganizationFields,
	|	ExchangeRates.CourseNumerator AS CourseNumerator,
	|	ExchangeRates.CourseDenominator AS CourseDenominator,
	|	ManExchangeRates.CourseNumerator AS CourseNumeratorMan,
	|	ManExchangeRates.CourseDenominator AS CourseDenominatorMan,
	|	CASE
	|		WHEN ExchangeRates.CourseDenominator <> 0 AND ManExchangeRates.CourseNumerator <> 0 THEN
	|			ExchangeRates.CourseNumerator * ManExchangeRates.CourseDenominator / (ExchangeRates.CourseDenominator * ManExchangeRates.CourseNumerator)
	|		ELSE
	|			0
	|	END AS ManConversionFactor,
	|	CASE
	|		WHEN ExchangeRates.CourseDenominator <> 0 AND LocalExchangeRates.CourseNumerator <> 0 THEN
	|			ExchangeRates.CourseNumerator * LocalExchangeRates.CourseDenominator / (ExchangeRates.CourseDenominator * LocalExchangeRates.CourseNumerator)
	|		ELSE
	|			0
	|	END AS LocalConversionRatio
	|INTO TTCurrencyConversionFactors
	|FROM
	|	PeriodsTable
	|	
	|	LEFT JOIN
	|		TableOfSettlementPeriods
	|	ON
	|		TableOfSettlementPeriods.Date = PeriodsTable.Date
	|		AND TableOfSettlementPeriods.ARAPCurrency = PeriodsTable.ARAPCurrency
	|		AND &OrganizationConditionsAccordingToTableOfSettlementPeriods
	|		
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates AS ExchangeRates
	|	ON
	|		ExchangeRates.Period = TableOfSettlementPeriods.DateOfCourse
	|		AND ExchangeRates.Currency = TableOfSettlementPeriods.ARAPCurrency
	|		AND &BaseCurrencyConditionInTableOfSettlementPeriods
	|		
	|	LEFT JOIN
	|		TableOfManPeriods
	|	ON
	|		TableOfManPeriods.Date = PeriodsTable.Date
	|		AND TableOfManPeriods.ARAPCurrency = PeriodsTable.ARAPCurrency
	|		AND &OrganizationCriteriaForManPeriodTable
	|		
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates AS ManExchangeRates
	|	ON
	|		ManExchangeRates.Period = TableOfManPeriods.DateOfCourse
	|		AND ManExchangeRates.Currency = &CurrencyOfMan
	|		AND &ConditionOfBaseCurrencyAccordingToTableOfPeriodsOfMan
	|		
	|	LEFT JOIN
	|		TableOfLocalPeriods
	|	ON
	|		TableOfLocalPeriods.Date = PeriodsTable.Date
	|		AND TableOfLocalPeriods.ARAPCurrency = PeriodsTable.ARAPCurrency
	|		AND &OrganizationCriteriaForLocalPeriodTable
	|		
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates AS LocalExchangeRates
	|	ON
	|		LocalExchangeRates.Period = TableOfLocalPeriods.DateOfCourse
	|		AND &CurrencyConditionByLocalPeriodTable
	|INDEX BY
	|	PeriodsTable.ARAPCurrency,
	|	&GroupingOrganizations,
	|	PeriodsTable.Date
	|";
	
	If MultipleCompanies Then
		
		QueryText = StrReplace(QueryText, "&OrganizationFields", "
							|	PeriodsTable.Organization");
		QueryText = StrReplace(QueryText, "&OrganizationConditionsAccordingToTableOfSettlementPeriods",
							"PeriodsTable.Organization = TableOfSettlementPeriods.Organization");
		QueryText = StrReplace(QueryText, "&BaseCurrencyConditionInTableOfSettlementPeriods",
							"ExchangeRates.BaseCurrency = TableOfSettlementPeriods.ComplCurrency");
		QueryText = StrReplace(QueryText, "&OrganizationCriteriaForManPeriodTable",
							"PeriodsTable.Organization = TableOfManPeriods.Organization");
		QueryText = StrReplace(QueryText, "&ConditionOfBaseCurrencyAccordingToTableOfPeriodsOfMan",
							"ManExchangeRates.BaseCurrency = TableOfManPeriods.ComplCurrency");
		QueryText = StrReplace(QueryText, "&OrganizationCriteriaForLocalPeriodTable",
							"PeriodsTable.Organization = TableOfLocalPeriods.Organization");
		QueryText = StrReplace(QueryText, "&CurrencyConditionByLocalPeriodTable",
							"LocalExchangeRates.Currency = TableOfLocalPeriods.ComplCurrency
							|		AND LocalExchangeRates.BaseCurrency = TableOfLocalPeriods.ComplCurrency");
		QueryText = StrReplace(QueryText, "&GroupingOrganizations", "
							|	PeriodsTable.Organization");
		
	Else
		
		QueryText = StrReplace(QueryText, "&OrganizationFields,", "");
		QueryText = StrReplace(QueryText, "&OrganizationConditionsAccordingToTableOfSettlementPeriods", "TRUE");
		QueryText = StrReplace(QueryText, "&BaseCurrencyConditionInTableOfSettlementPeriods",
							"ExchangeRates.BaseCurrency = &ComplCurrency");
		QueryText = StrReplace(QueryText, "&OrganizationCriteriaForManPeriodTable", "TRUE");
		QueryText = StrReplace(QueryText, "&ConditionOfBaseCurrencyAccordingToTableOfPeriodsOfMan",
							"ManExchangeRates.BaseCurrency = &ComplCurrency");
		QueryText = StrReplace(QueryText, "&OrganizationCriteriaForLocalPeriodTable", "TRUE");
		QueryText = StrReplace(QueryText, "&CurrencyConditionByLocalPeriodTable",
							"LocalExchangeRates.Currency = &ComplCurrency
							|		AND LocalExchangeRates.BaseCurrency = &ComplCurrency");
		QueryText = StrReplace(QueryText, "&GroupingOrganizations,", "");
		
	EndIf;
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

#EndRegion

#Region Internal

#Region HandlersForMonthClosingStages

#Region LoansDepositsAndBorrowingsIssuedInterestCharge

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_LoansDepositsAndBorrowingsIssuedInterestCharge(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.LoansDepositsAndBorrowingsIssuedInterestCharge);
	
	NewRow.MultilingualName = "vi = 'Trích các khoản cho vay tiền gửi và các khoản vay được xuất (thủ công)';
								|ru = 'Начисления по кредитам депозитам и выданным займам (вручную)';
								|en = 'Credit, deposit and loan interest charge (manual)';
								|it = 'Su prestiti a depositi e prestiti (manualmente)';
								|pl = 'Naliczanie dla kredytów depozytów i wydanych pożyczek (ręcznie)';
								|tr = 'Krediler, mevduatlar ve verilen krediler üzerindeki tahakkuklar (manuel)'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute = NStr("vi = 'Tính';
								|ru = 'Начислить';
								|en = 'Accrue'; fa = 'محاسبه';
								|it = 'Accreditare';
								|pl = 'Accrue';
								|tr = 'Tahakkuk et'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"FinancialInstruments.Usage_AccrualsOnLoansDepositsAndLoansIssued");
	NewRow.ActionExecute = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.LoanAndDepositInterestCharge.Forms.ListForm.FullName());
EndProcedure

// Stage handlers.

Procedure Usage_AccrualsOnLoansDepositsAndLoansIssued(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("UseLoanAndDepositContracts") Then
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Hợp đồng tín dụng và tiền gửi không được sử dụng.';
				|ru = 'Договоры кредитов и депозитов не используются.';
				|en = 'Loan and deposit contracts are not used.'; fa = 'Loan and deposit contracts are not used.';
				|it = 'Gli accordi di prestito e di deposito non vengono utilizzati.';
				|pl = 'Umowy kredytów i depozytów nie są stosowane.';
				|tr = 'Kredi ve mevduat sözleşmeleri kullanılmıyor.'", Common.DefaultLanguageCode()));
		Return;
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT
	|	Schedule.ScheduleOption AS ScheduleOption 
	|INTO Schedules
	|FROM
	|	InformationRegister.ScheduleOfAccrualsForLoansAndDeposits AS Schedule
	|	
	|	INNER JOIN Catalog.LoanAndDepositContracts AS Contract
	|	ON Schedule.ScheduleOption.Owner = Contract.Ref
	|		AND Schedule.ScheduleOption.Used
	|		AND Contract.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|		AND Schedule.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|WHERE
	|	Contract.Organization IN (&CompanyArray)
	|
	|UNION ALL
	|
	|SELECT
	|	Schedule.ScheduleOption AS ScheduleOption
	|FROM
	|	InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS Schedule
	|
	|	INNER JOIN Catalog.LoanAndDepositContracts AS Contract
	|	ON Schedule.ScheduleOption.Owner = Contract.Ref
	|		AND Schedule.ScheduleOption.Used
	|		AND Contract.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|		AND Schedule.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|WHERE
	|	Contract.Organization IN (&CompanyArray)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Contract.Organization AS Organization,
	|	Contract.Ref AS Contract,
	|	Schedule.Interests AS AccrualPercentPlan,
	|	Schedule.Fee AS AccrualFeePlan,
	|	0 AS AccrualPercentActual,
	|	0 AS AccrualFeeActual
	|INTO TTPlanFactUnfolded
	|FROM
	|	InformationRegister.ScheduleOfAccrualsForLoansAndDeposits AS Schedule
	|
	|	INNER JOIN Catalog.LoanAndDepositContracts AS Contract
	|	ON Schedule.ScheduleOption.Owner = Contract.Ref
	|		AND Contract.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|		AND Schedule.ScheduleOption.Used
	|		AND Schedule.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|WHERE
	|	Contract.Organization IN (&CompanyArray)
	|
	|UNION ALL
	|
	|SELECT
	|	Contracts.Organization,
	|	Calculations.Contract AS Contract,
	|	0 AS AccrualPercentPlan,
	|	0 AS AccrualFeePlan,
	|	CASE WHEN Calculations.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|		THEN Calculations.Sum
	|		ELSE 0
	|	END AS AccrualPercentActual,
	|	CASE WHEN Calculations.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|		THEN Calculations.Sum
	|		ELSE 0
	|	END AS AccrualFeeActual
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS Calculations
	|
	|	INNER JOIN Catalog.LoanAndDepositContracts AS Contracts
	|	ON Calculations.Contract = Contracts.Ref
	|		AND Contracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|		AND Calculations.ScheduleType = VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)
	|		AND Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|WHERE
	|	Contracts.Organization IN (&CompanyArray)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPlanFact.Organization AS Organization,
	|	TTPlanFact.Contract AS Contract,
	|	SUM(TTPlanFact.AccrualPercentPlan) AS AccrualPercentPlan,
	|	SUM(TTPlanFact.AccrualFeePlan) AS AccrualFeePlan,
	|	SUM(TTPlanFact.AccrualPercentActual) AS AccrualPercentActual,
	|	SUM(TTPlanFact.AccrualFeeActual) AS AccrualFeeActual
	|INTO Variances
	|FROM
	|	TTPlanFactUnfolded AS TTPlanFact
	|GROUP BY
	|	TTPlanFact.Organization,
	|	TTPlanFact.Contract
	|HAVING
	|	SUM(TTPlanFact.AccrualPercentPlan) - SUM(TTPlanFact.AccrualPercentActual) > 0
	|		OR SUM(TTPlanFact.AccrualFeePlan) - SUM(TTPlanFact.AccrualFeeActual) > 0";
	
	Query.Execute();
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.Schedules = 0 Then
			
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có lịch trình tích lũy và thanh toán cho các thỏa thuận cho vay và tiền gửi.';
				|ru = 'Нет графиков начислений и оплат по договорам кредитов и депозитов.';
				|en = 'No schedules of accruals and payments under credit and deposit contracts.'; fa = 'No schedules of accruals and payments under credit and deposit contracts.';
				|it = 'Non ci sono dei piani di accrediti e pagamenti secondo gli accordi di prestiti e depositi.';
				|pl = 'Brak harmonogramów naliczeń i płatności wg kontraktów kredytowych i depozytowych.';
				|tr = 'Kredi ve mevduat sözleşmelerinde tahakkuk ve ödeme planı bulunmamaktadır.'", Common.DefaultLanguageCode()));
		
	Else
		
		MonthEndTransactionsServer.CaptureUsageHandlerResultsForOrganizations(
			HandlerParameters,
			NStr("vi = 'Đối với doanh nghiệp ""%1"" cho kỳ %2, có sự sai lệch trong các khoản tích lũy theo kế hoạch và thực tế theo các thỏa thuận cho vay và tiền gửi.';
				|ru = 'По организации ""%1"" за период %2 есть отклонения в плановых и фактических начислениях по договорам кредитов и депозитов.';
				|en = 'There are variances in the planned and actual accruals under credit and deposit contracts of the ""%1"" company for period %2.'; fa = 'There are variances in the planned and actual accruals under credit and deposit contracts of the ""%1"" company for period %2.';
				|it = 'Secondo l''organizzazione ""%1"" per il periodo %2 vi sono delle deviazioni degli accantonamenti previsti e effettivi per i contratti di prestiti e depositi.';
				|pl = 'Wg firmy ""%1"" za okres %2 są odchylenia w planowych i faktycznych naliczeniach wg kontraktów kredytowych i depozytowych.';
				|tr = '%2 döneminde ""%1"" iş yeri için kredi ve mevduat sözleşmesi kapsamında planlanan ve gerçekleşen tahakkuklarda sapmalar var.'", Common.DefaultLanguageCode()),
			Query,
			"Variances",
			False,
			True);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

Function Total_F_XIRR(Payments_2, Deadlines, Argument)
	
	Rez = 0;
	
	For Indus = 0 To Payments_2.Count() - 1 Do
		Rez = Rez + F_XIRR(Payments_2[Indus], Deadlines[Indus], Argument);
	EndDo;
	
	Return Rez;
	
EndFunction

Function Total_DF_XIRR(Payments_2, Deadlines, Argument)
	
	Rez = 0;
	
	For Indus = 0 To Payments_2.Count() - 1 Do
		Rez = Rez + DF_XIRR(Payments_2[Indus], Deadlines[Indus], Argument);
	EndDo;
	
	Return Rez;
	
EndFunction

Function F_XIRR(Payment_, DueDate, Argument)
	
	If Argument <= -1 Then
		Argument = -1 + 0.000000000001;
	EndIf;
	
	Return Payment_ * Pow((1 + Argument), DueDate);
	
EndFunction

Function DF_XIRR(Payment_, DueDate, Argument)
	
	If Argument <= -1 Then
		Argument = -1 + 0.000000000001;
	EndIf;
	
	Return DueDate * Payment_ * Pow((1 + Argument), (DueDate - 1));
	
EndFunction

Function ModuleNumbers(Number)
	
	Return Max(Number, -Number);
	
EndFunction

Function QuotedNPVPayment(Rate1, Payment_, PeriodNumber)
	
	Return Payment_ / Pow((Rate1 + 1), PeriodNumber);
	
EndFunction

Function QuotedPaymentXNPV(Rate1, Payment_, DueDate)
	
	Return Payment_ / Pow((Rate1 + 1), DueDate);
	
EndFunction

Procedure ConvertIncomingParametersToCHISTVNDOH(Payments_2, Dates)
	
	If Payments_2.Count() <> Dates.Count() Then
		Return;
	EndIf;
	
	ScheduleOfPayments = New ValueTable; 
	ScheduleOfPayments.Columns.Add("Date", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
	ScheduleOfPayments.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription(AllowedSign.Any));
	
	For Indus = 0 To Payments_2.UBound() Do
		If Payments_2[Indus] <> 0 Then
			NewRow = ScheduleOfPayments.Add();
			NewRow.Date = Dates[Indus];
			NewRow.Sum = Payments_2[Indus];
		EndIf;
	EndDo;
	
	ScheduleOfPayments.GroupBy("Date", "Sum");
	
	Dates = ScheduleOfPayments.UnloadColumn("Date");
	Payments_2 = ScheduleOfPayments.UnloadColumn("Sum");
	
EndProcedure

Function CheckIncomingCHISTVNDOHParameters(Payments_2)
	
	ThereIsPositiveAmount = False;
	ThereIsNegativeAmount = False;
	
	For Indus = 0 To Payments_2.UBound() Do
		If Not ThereIsPositiveAmount And Payments_2[Indus] > 0 Then
			ThereIsPositiveAmount = True;
		ElsIf Not ThereIsNegativeAmount And Payments_2[Indus] < 0 Then
			ThereIsNegativeAmount = True;
		EndIf;
		If ThereIsPositiveAmount And ThereIsNegativeAmount Then
			Break;
		EndIf;
	EndDo;
	
	If Not (ThereIsPositiveAmount And ThereIsNegativeAmount) Then
		MessageText = NStr("vi = 'Không thể tính tỷ suất IRR hàng năm gần đúng. Hãy kiểm tra tính chính xác của lịch biểu thanh toán: ít nhất một khoản thanh toán trong lịch biểu phải là số dương và một khoản là số âm.';
							|ru = 'Невозможно рассчитать приблизительную годовую ставку IRR. Проверьте корректность графика платежей: по крайней мере один платеж в графике должен быть положительный и один отрицательный.';
							|en = 'Cannot calculate an approximate yearly IRR rate. Check the correctness of the payment schedule: at least one payment in the schedule must be positive and one negative.'; fa = 'Cannot calculate an approximate yearly IRR rate. Check the correctness of the payment schedule: at least one payment in the schedule must be positive and one negative.';
							|it = 'Impossibile calcolare l''aliquota annuale approssimativa IRR. Verificare l''esattezza del grafico dei pagamenti: almeno un pagamento nel grafico deve essere positivo, e uno negativo.';
							|pl = 'Obliczenie przybliżonej rocznej stopy IRR nie jest możliwe. Sprawdź poprawność harmonogramu płatności: co najmniej jedna płatność w harmonogramie powinna być dodatnia i jedna ujemna.';
							|tr = 'Yıllık IRR oranını yaklaşık olarak hesaplamak mümkün değildir. Ödeme planının doğruluğunu kontrol et: programdaki en az bir ödeme pozitif ve bir negatif olmalıdır.'");
		Raise MessageText;
	EndIf;
	
	Return ThereIsPositiveAmount And ThereIsNegativeAmount;
	
EndFunction

// Replaces lines in currency conversion subqueries
//
// Parameters:
//	QueryText - String - the text of the request in which the correction is performed
//	TableName - String - name of the temporary table
//	MultipleCompanies - Boolean - whether there is a list of organizations
//
Procedure AdjustmentOfCurrencyTranslationSubqueryByOrganization(QueryText, TableName, MultipleCompanies)
	
	If MultipleCompanies Then
		
		QueryText = StrReplace(QueryText, "&OrganizationFields", "
							|	PeriodsTable.Organization,
							|	Companies.LocalAccountingCurrency AS ComplCurrency");
		QueryText = StrReplace(QueryText, ",&CompanyTable", "
							|	INNER JOIN Catalog.Companies AS Companies
							|		ON PeriodsTable.Organization = Companies.Ref");
		QueryText = StrReplace(QueryText, "&BaseCurrencyCondition",
							"ExchangeRates.BaseCurrency = Companies.LocalAccountingCurrency");
		QueryText = StrReplace(QueryText, "&GroupingOrganizations", "
							|	PeriodsTable.Organization,
							|	Companies.LocalAccountingCurrency");
		
		If TableName = "TableOfLocalPeriods" Then
			QueryText = StrReplace(QueryText, "&CurrencyCondition",
							"ExchangeRates.Currency = Companies.LocalAccountingCurrency");
		EndIf;
		
	Else
		
		QueryText = StrReplace(QueryText, "&OrganizationFields,", "");
		QueryText = StrReplace(QueryText, ",&CompanyTable", "");
		QueryText = StrReplace(QueryText, "&BaseCurrencyCondition",
							"ExchangeRates.BaseCurrency = &ComplCurrency");
		QueryText = StrReplace(QueryText, "&GroupingOrganizations,", "");
		
		If TableName = "TableOfLocalPeriods" Then
			QueryText = StrReplace(QueryText, "&CurrencyCondition",
							"ExchangeRates.Currency = &ComplCurrency");
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion