#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure prepares the data for the reconciliation table with the coefficients in the form of a reconciliation monitor
// 
// Parameters:
//    ReconciliationParameters - Structure - Structure with parameters to fill in.
//    ResultAddress - String - The address in the temporary storage where the result of the procedure will be placed.
//
Procedure GetReconciliationData(ReconciliationParameters, ResultAddress) Export
	
	MeasurementReceivingData = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DataProcessor.SettlementReconciliationMonitor.GetReconciliationData");

	QueryText = QueryTextReconciliationMonitorData();
	Sort = ReconciliationParameters.AllSortingFields;
	If ReconciliationParameters.Sort <> "CounterpartyName_" Then
		IndexOf = Sort.Find(ReconciliationParameters.Sort);
		If IndexOf <> Undefined Then
			Sort.Delete(IndexOf);
		EndIf;
		Sort.Insert(0,ReconciliationParameters.Sort);
	EndIf;
	SortingLine = StrConcat(Sort,",");
	SortingLine = "
	|ORDER BY
	|" + SortingLine;
	
	Query = New Query;
	Query.Text = QueryText + SortingLine;
	Query.SetParameter("BeginOfPeriod", ReconciliationParameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", ReconciliationParameters.EndOfPeriod);
	Query.SetParameter("TypesOfCalculations_", ReconciliationParameters.TypesOfCalculations_);
	Query.SetParameter("Organization", ReconciliationParameters.Organization);
	Query.SetParameter("ComplCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(ReconciliationParameters.Organization));
	Query.SetParameter("Counterparty", ReconciliationParameters.Counterparty);
	Query.SetParameter("ForAllCounterparties", Not ValueIsFilled(ReconciliationParameters.Counterparty));
	Query.SetParameter("OnlyOurCompanies", ReconciliationParameters.OnlyOurCompanies);
	Query.SetParameter("Manager", ReconciliationParameters.Manager);
	Query.SetParameter("ForAllManagers", Not ValueIsFilled(ReconciliationParameters.Manager));
	Query.SetParameter("Currency", Undefined);
	Query.SetParameter("ForAllCurrencies", True);
	Query.SetParameter("ContractsWithoutTurnover", ReconciliationParameters.IncludeContractsWithoutTurnover);
	Query.SetParameter("TypesOfRentalAmountToBeReconciled", Documents.ARAPReconciliation2_5_11.TypesOfRentalAmountsToBeReconciled());
	Query.SetParameter("OutputRecorders", False);
	Query.SetParameter("IsBlankString", "");
	For Each Status In ReconciliationStatuses() Do
		Query.SetParameter(Status.Name, Status.Name);
	EndDo;
	
	QueryResult = Query.Execute();
	ReconciliationData = New ValueTable;
	For Each ResultColumn In QueryResult.Columns Do
		ReconciliationData.Columns.Add(ResultColumn.Name, ResultColumn.ValueType);
	EndDo;
	StringType50 = Common.StringTypeDetails(50);
	NumberType1 = Common.TypeDescriptionNumber(1);
	TypeAmount = CurrencyRateOperations.MoneyFieldTypeDescription();
	ReconciliationData.Columns.Add("ReconciliationStatusPresentation", StringType50);
	ReconciliationData.Columns.Add("ReconciliationStatusImage", NumberType1);
	ReconciliationData.Columns.Add("OurDebtHasBeenVerified", TypeAmount);
	ReconciliationData.Columns.Add("CounterpartySDebtHasBeenReconciled", TypeAmount);
	ReconciliationData.Columns.Add("Reconciliation20", StringType50);
	ReconciliationData.Columns.Add("CodeTypeOfCalculations", StringType50);
	ReconciliationData.Columns.Add("ExchangeOfEDIPresentationHasNotBeenCompleted", StringType50);
	
	Selection = QueryResult.Select();
	
	// Fill in the text fields line by line and simultaneously calculate the totals
	CacheNotCompletedEDOTextExchange = New Map;
	
	DebtTotals = New Structure();
	DebtTotals.Insert("AccountsPayableOfCompany", New Structure);
	DebtTotals.AccountsPayableOfCompany.Insert("Total", 0);
	DebtTotals.AccountsPayableOfCompany.Insert("Verified_", 0);
	
	DebtTotals.Insert("CounterpartySDebt", New Structure);
	DebtTotals.CounterpartySDebt.Insert("Total", 0);
	DebtTotals.CounterpartySDebt.Insert("Verified_", 0);
	
	CounterpartySDebt = DebtTotals.CounterpartySDebt;
	AccountsPayableOfCompany = DebtTotals.AccountsPayableOfCompany;
	
	SelectionByStatus = ReconciliationParameters.ReconciliationStatuses;
	ReconciliationStatuses = ReconciliationStatuses(True);
	StatusVerified = ReconciliationStatuses["Reconciled"];
	ReconciliationStatusResults = New Map;// the key is the string Status of the reconciliation, the value is the number of counterparties
	For Each Status In ReconciliationStatuses Do
		ReconciliationStatusResults.Insert(Status.Key, 0);
	EndDo;
	ThereAreDiscrepancies = StatusThereAreDiscrepancies().Name;
	ReconciliationStatusResults.Insert(ThereAreDiscrepancies, 0);
	
	While Selection.Next() Do
		
		// To calculate statistics in the total mass of counterparties, we do not select by Status immediately in the request.
		// Counterparties that do not pass the reconciliation Status are not added to the final table below.
		ReconciliationStatusResults[Selection.ReconciliationStatus] = ReconciliationStatusResults[Selection.ReconciliationStatus] + 1;
		ReconciliationStatusResults[ThereAreDiscrepancies] = ReconciliationStatusResults[ThereAreDiscrepancies] + Number(Selection.ThereAreDiscrepancies);
		CounterpartySDebt.Total = CounterpartySDebt.Total + Selection.CounterpartySDebtIsLocal;
		AccountsPayableOfCompany.Total = AccountsPayableOfCompany.Total + Selection.OurDebtIsLocal;
		If StatusVerified[Selection.ReconciliationStatus] <> Undefined Then
			CounterpartySDebt.Verified_ = CounterpartySDebt.Verified_ + Selection.CounterpartySDebtIsLocal;
			AccountsPayableOfCompany.Verified_ = AccountsPayableOfCompany.Verified_ + Selection.OurDebtIsLocal;
		EndIf;
		
		If Not SelectionByStatus[Selection.ReconciliationStatus]
			 Or ReconciliationParameters.ThereAreDiscrepancies And Not Selection.ThereAreDiscrepancies Then
			Continue;
		EndIf;
		
		NewRow = ReconciliationData.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.CodeTypeOfCalculations = StrReplace(Format(Selection.CodeCalculationTypeNumber, "NG=0"),"0","");
		Status = ReconciliationStatuses[Selection.ReconciliationStatus];
		NewRow.ReconciliationStatusPresentation = Status.Presentation;
		NewRow.ReconciliationStatusImage = Status.Picture;
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("Counterparties", ReconciliationData);
	Result.Insert("ReconciliationStatusResults", ReconciliationStatusResults);
	Result.Insert("DebtTotals", DebtTotals);
	
	PutToTempStorage(Result, ResultAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementReceivingData, Selection.Count()/100);
	
EndProcedure

// The function returns a description of the reconciliation Statuses in the form of a correctly ordered array or match
// Parameters:
//  ReturnMatch - Boolean - Sets the type of value to return
//
// Returns:
//  Array of Structure, 
//  Matching From Key Value - description of reconciliation Statuses
//
Function ReconciliationStatuses(ReturnMatch = False) Export
	
	Required2 = NewStatus("ReconciliationIsRequired", NStr("vi = 'Yêu cầu đối chiếu';
															|ru = 'Требуется сверка';
															|en = 'Reconciliation is required'; fa = 'تطبیق الزامی است';
															|it = 'Reconciliation is required';
															|pl = 'Reconciliation is required';
															|tr = 'Mutabakat gerekiyor'"),2);//red ball
	CreatedOn_ = NewStatus("CreatedOn_", String(Enums.StatusesOfARAPReconciliation2_5_11.CreatedOn_),0);//grey ball
	OnReconciliation = NewStatus("OnReconciliation", String(Enums.StatusesOfARAPReconciliation2_5_11.OnReconciliation),1);//yellow ball
	ReconciledWithDisputes = NewStatus("ReconciledWithDisputes", String(Enums.StatusesOfARAPReconciliation2_5_11.ReconciledWithDisputes),4);//The green jackdaw
	ReconciledWithoutDisputes = NewStatus("ReconciledWithoutDisputes", String(Enums.StatusesOfARAPReconciliation2_5_11.ReconciledWithoutDisputes),4);//The green jackdaw
	
	If ReturnMatch Then
		Result = New Map;
		Result.Insert(Required2.Name, Required2);
		Result.Insert(CreatedOn_.Name, CreatedOn_);
		Result.Insert(OnReconciliation.Name, OnReconciliation);
		Result.Insert(ReconciledWithDisputes.Name, ReconciledWithDisputes);
		Result.Insert(ReconciledWithoutDisputes.Name, ReconciledWithoutDisputes);
			
		Reconciled = New Map;
		Reconciled.Insert(ReconciledWithDisputes.Name,True);
		Reconciled.Insert(ReconciledWithoutDisputes.Name,True);
		Result.Insert("Reconciled",Reconciled);
	Else
		Result = New Array;
		Result.Add(Required2);
		Result.Add(CreatedOn_);
		Result.Add(OnReconciliation);
		Result.Add(ReconciledWithDisputes);
		Result.Add(ReconciledWithoutDisputes);
	EndIf;
		
	Return Result;
	
EndFunction

// Returns a description of the selection based on discrepancies in the reconciliation documents 
//
// Returns:
//  Structure - Status There Are Discrepancies:
// * Name - String - Id
// * Presentation - String - Custom Presentation.
//
Function StatusThereAreDiscrepancies() Export
	
	Return New Structure("Name,Presentation", "ThereAreDiscrepancies", NStr("vi = 'Đã ghi nhận sự khác biệt';
																			|ru = 'Зафиксированы расхождения';
																			|en = 'Discrepancies are recorded'; fa = 'مغایرت‌ها ثبت شده‌اند';
																			|it = 'Discrepancies are recorded';
																			|pl = 'Discrepancies are recorded';
																			|tr = 'Tutarsızlıklar tespit edildi'"));
	
EndFunction

// Query Text calculation documents.
// 
// Returns:
//  String - Query Text calculation documents
Function QueryTextCalculationData() Export
	
	QueryText =
	"SELECT ALLOWED
	|	BEGINOFPERIOD(NestedQuery.Period, DAY) AS Period,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Counterparty AS Counterparty,
	|	CASE 
	|		WHEN NestedQuery.Contract IN (
	|			VALUE(Catalog.CounterpartyContracts.EmptyRef),
	|			VALUE(Catalog.IntercompanyContracts.EmptyRef))
	|		THEN UNDEFINED
	|		ELSE NestedQuery.Contract
	|	END AS Contract,
	|	NestedQuery.Manager AS Manager,
	|	NestedQuery.Currency AS Currency,
	|	SUM(NestedQuery.AccountsPayableOfCompany) AS AccountsPayableOfCompany,
	|	SUM(NestedQuery.CounterpartySDebt) AS CounterpartySDebt,
	|	SUM(NestedQuery.OurDebtIsLocal) AS OurDebtIsLocal,
	|	SUM(NestedQuery.CounterpartySDebtIsLocal) AS CounterpartySDebtIsLocal,
	|	NestedQuery.Ref AS Ref,
	|	NestedQuery.PaymentType_ AS PaymentType_,
	|	NestedQuery.Order AS Order,
	|	VALUETYPE(NestedQuery.Ref) = TYPE(Document.LoanAndDepositInterestCharge) AS ThisIsAccrualOfLoansAndDeposits
	|	
	|INTO TTARAPDocuments
	|FROM 
	|	(SELECT
	|		Calculations.Period AS Period,
	|		Dimension.Organization AS Organization,
	|		Dimension.Counterparty AS Counterparty,
	|		Dimension.Contract AS Contract,
	|		ISNULL(Counterparties.Partner.MainManager, UNDEFINED) AS Manager,
	|		Calculations.Currency AS Currency,
	|		CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.Prepayment
	|			ELSE -Calculations.Prepayment
	|		END AS AccountsPayableOfCompany,
	|		CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.Debt
	|			ELSE -Calculations.Debt
	|		END AS CounterpartySDebt,
	|		CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.PrepaymentLocal
	|			ELSE -Calculations.PrepaymentLocal
	|		END AS OurDebtIsLocal,
	|		CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.DebtLocal
	|			ELSE -Calculations.DebtLocal
	|		END AS CounterpartySDebtIsLocal,
	|		Calculations.DocumentRecorder AS Ref,
	|		VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|		10 AS Order
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON Calculations.AccountingDimensionByPartners = Dimension.DimensionKey
	|		LEFT JOIN Catalog.Counterparties AS Counterparties
	|		ON Dimension.Counterparty = Counterparties.Ref
	|	WHERE
	|		Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND (&ForAllCurrencies OR Calculations.Currency = &Currency)
	|		AND Dimension.Organization IN (&Organization)
	|		AND (&ForAllCounterparties OR Dimension.Counterparty IN (&Counterparty))
	|		AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|			OR &OnlyOurCompanies AND VALUETYPE(Dimension.Counterparty) = TYPE(Catalog.Companies))
	|		AND VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) IN (&TypesOfCalculations_)
	|		AND Calculations.Debt - Calculations.Prepayment <> 0
	|		AND NOT VALUETYPE(Calculations.DocumentRecorder) IN (
	|			TYPE(Document.OBEntryOfLeaseSettlements),
	|			TYPE(Document.OBEntryFinancialInstruments),
	|			TYPE(Document.OBEntryARAP),
	|			TYPE(Document.RegisterAdjustment),
	|			TYPE(Document.ReversingEntry))
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		Calculations.Period AS Period,
	|		Dimension.Organization AS Organization,
	|		Dimension.Counterparty AS Counterparty,
	|		Dimension.Contract AS Contract,
	|		ISNULL(Counterparties.Partner.MainManager, UNDEFINED) AS Manager,
	|		Calculations.Currency AS Currency,
	|		CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.Debt
	|			ELSE -Calculations.Debt
	|		END AS AccountsPayableOfCompany,
	|		CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.Prepayment
	|			ELSE -Calculations.Prepayment
	|		END AS CounterpartySDebt,
	|		CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.DebtLocal
	|			ELSE -Calculations.DebtLocal
	|		END AS OurDebtIsLocal,
	|		CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.PrepaymentLocal
	|			ELSE -Calculations.PrepaymentLocal
	|		END AS CounterpartySDebtIsLocal,
	|		Calculations.DocumentRecorder AS Ref,
	|		VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|		20 AS Order
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON Calculations.AccountingDimensionByPartners = Dimension.DimensionKey
	|		LEFT JOIN Catalog.Counterparties AS Counterparties
	|		ON Dimension.Counterparty = Counterparties.Ref
	|	WHERE
	|		Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND (&ForAllCurrencies OR Calculations.Currency = &Currency)
	|		AND Dimension.Organization IN (&Organization)
	|		AND (&ForAllCounterparties OR Dimension.Counterparty IN (&Counterparty))
	|		AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|			OR &OnlyOurCompanies AND VALUETYPE(Dimension.Counterparty) = TYPE(Catalog.Companies))
	|		AND VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) IN (&TypesOfCalculations_)
	|		AND Calculations.Debt - Calculations.Prepayment <> 0
	|		AND NOT VALUETYPE(Calculations.DocumentRecorder) IN (
	|			TYPE(Document.OBEntryOfLeaseSettlements),
	|			TYPE(Document.OBEntryFinancialInstruments),
	|			TYPE(Document.OBEntryARAP),
	|			TYPE(Document.RegisterAdjustment),
	|			TYPE(Document.ReversingEntry))
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		Calculations.Period AS Period,
	|		Contracts.Organization AS Organization,
	|		Contracts.Counterparty AS Counterparty,
	|		Calculations.Contract AS Contract,
	|		ISNULL(Counterparties.Partner.MainManager, UNDEFINED) AS Manager,
	|		Calculations.Currency AS Currency,
	|		CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Calculations.Sum
	|			ELSE 0
	|		END AS AccountsPayableOfCompany,
	|		CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.Sum
	|			ELSE 0
	|		END AS CounterpartySDebt,
	|		CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Calculations.SumCompl
	|			ELSE 0
	|		END AS OurDebtIsLocal,
	|		CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.SumCompl
	|			ELSE 0
	|		END AS CounterpartySDebtIsLocal,
	|		Calculations.Recorder AS Ref,
	|		CASE 
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|					OR Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|		END AS PaymentType_,
	|		CASE 
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN 31
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|					OR Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|				THEN 32
	|		END AS Order
	|	FROM
	|		AccumulationRegister.FinancialInstrumentsARAP AS Calculations
	|		INNER JOIN Catalog.LoanAndDepositContracts AS Contracts
	|		ON Calculations.Contract = Contracts.Ref
	|		LEFT JOIN Catalog.Counterparties AS Counterparties
	|		ON Contracts.Counterparty = Counterparties.Ref
	|	WHERE
	|		Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND (&ForAllCurrencies OR Calculations.Currency = &Currency)
	|		AND Contracts.Organization IN (&Organization)
	|		AND (&ForAllCounterparties OR Contracts.Counterparty IN (&Counterparty))
	|		AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|			OR &OnlyOurCompanies AND VALUETYPE(Contracts.Counterparty) = TYPE(Catalog.Companies))
	|		AND Calculations.Sum <> 0
	|		AND CASE 
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|					OR Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|		END IN (&TypesOfCalculations_)
	|		AND NOT VALUETYPE(Calculations.Recorder) IN (
	|			TYPE(Document.OBEntryOfLeaseSettlements),
	|			TYPE(Document.OBEntryFinancialInstruments),
	|			TYPE(Document.OBEntryARAP),
	|			TYPE(Document.RegisterAdjustment),
	|			TYPE(Document.ReversingEntry))
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		Calculations.Period AS Period,
	|		Contracts.Organization AS Organization,
	|		Contracts.Counterparty AS Counterparty,
	|		Calculations.Contract AS Contract,
	|		ISNULL(Counterparties.Partner.MainManager, UNDEFINED) AS Manager,
	|		Calculations.Currency AS Currency,
	|		CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Calculations.Sum
	|			ELSE 0
	|		END AS AccountsPayableOfCompany,
	|		CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.Sum
	|			ELSE 0
	|		END AS CounterpartySDebt,
	|		CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Calculations.SumCompl
	|			ELSE 0
	|		END AS OurDebtIsLocal,
	|		CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.SumCompl
	|			ELSE 0
	|		END AS CounterpartySDebtIsLocal,
	|		Calculations.Recorder AS Ref,
	|		VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor) AS PaymentType_,
	|		33 AS Order
	|	FROM
	|		AccumulationRegister.FinancialInstrumentsARAP AS Calculations
	|		INNER JOIN Catalog.LeaseContract AS Contracts
	|		ON Calculations.Contract = Contracts.Ref
	|		LEFT JOIN Catalog.Counterparties AS Counterparties
	|		ON Contracts.Counterparty = Counterparties.Ref
	|	WHERE
	|		Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND (&ForAllCurrencies OR Calculations.Currency = &Currency)
	|		AND Contracts.Organization IN (&Organization)
	|		AND (&ForAllCounterparties OR Contracts.Counterparty IN (&Counterparty))
	|		AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|			OR &OnlyOurCompanies AND VALUETYPE(Contracts.Counterparty) = TYPE(Catalog.Companies))
	|		AND Calculations.Sum <> 0
	|		AND VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor) IN (&TypesOfCalculations_)
	|		AND NOT VALUETYPE(Calculations.Recorder) IN (
	|			TYPE(Document.OBEntryOfLeaseSettlements),
	|			TYPE(Document.OBEntryFinancialInstruments),
	|			TYPE(Document.OBEntryARAP),
	|			TYPE(Document.RegisterAdjustment),
	|			TYPE(Document.ReversingEntry))
	|) AS NestedQuery
	|WHERE
	|	(&ForAllManagers OR NestedQuery.Manager = &Manager)
	|
	|GROUP BY
	|	BEGINOFPERIOD(NestedQuery.Period, DAY),
	|	NestedQuery.Organization,
	|	NestedQuery.Counterparty,
	|	CASE 
	|		WHEN NestedQuery.Contract IN (
	|			VALUE(Catalog.CounterpartyContracts.EmptyRef),
	|			VALUE(Catalog.IntercompanyContracts.EmptyRef))
	|		THEN UNDEFINED
	|		ELSE NestedQuery.Contract
	|	END,
	|	NestedQuery.Manager,
	|	NestedQuery.Currency,
	|	NestedQuery.Ref,
	|	NestedQuery.PaymentType_,
	|	NestedQuery.Order
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.Currency AS Currency,
	|	SUM(Balance.AccountsPayableOfCompany) AS AccountsPayableOfCompany,
	|	SUM(Balance.CounterpartySDebt) AS CounterpartySDebt,
	|	SUM(Balance.OurDebtIsLocal) AS OurDebtIsLocal,
	|	SUM(Balance.CounterpartySDebtIsLocal) AS CounterpartySDebtIsLocal,
	|	Balance.PaymentType_ AS PaymentType_,
	|	Balance.Order AS Order
	|INTO TTBalancesByTypeOfCalculations
	|FROM
	|	(SELECT
	|		CalculationsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CalculationsBalance.Currency AS Currency,
	|		CalculationsBalance.PrepaymentBalance AS AccountsPayableOfCompany,
	|		CalculationsBalance.DebtBalance AS CounterpartySDebt,
	|		CalculationsBalance.PrepaymentLocalBalance AS OurDebtIsLocal,
	|		CalculationsBalance.DebtLocalBalance AS CounterpartySDebtIsLocal,
	|		VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|		10 AS Order
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&EndOfPeriod, 
	|			(&ForAllCurrencies OR Currency = &Currency)
	|			AND AccountingDimensionByPartners.Organization IN (&Organization)
	|			AND (&ForAllCounterparties OR AccountingDimensionByPartners.Counterparty IN (&Counterparty))
	|			AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|				OR &OnlyOurCompanies AND VALUETYPE(AccountingDimensionByPartners.Counterparty) = TYPE(Catalog.Companies))
	|			AND (VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) IN (&TypesOfCalculations_))
	|		) AS CalculationsBalance
	|		
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CalculationsBalance.Currency AS Currency,
	|		CalculationsBalance.DebtBalance AS AccountsPayableOfCompany,
	|		CalculationsBalance.PrepaymentBalance AS CounterpartySDebt,
	|		CalculationsBalance.DebtLocalBalance AS OurDebtIsLocal,
	|		CalculationsBalance.PrepaymentLocalBalance AS CounterpartySDebtIsLocal,
	|		VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|		20 AS Order
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(&EndOfPeriod, 
	|			(&ForAllCurrencies OR Currency = &Currency)
	|			AND AccountingDimensionByPartners.Organization IN (&Organization)
	|			AND (&ForAllCounterparties OR AccountingDimensionByPartners.Counterparty IN (&Counterparty))
	|			AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|				OR &OnlyOurCompanies AND VALUETYPE(AccountingDimensionByPartners.Counterparty) = TYPE(Catalog.Companies))
	|			AND (VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) IN (&TypesOfCalculations_))
	|		) AS CalculationsBalance
	|		
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CalculationsBalance.Currency AS Currency,
	|		CASE WHEN CalculationsBalance.SumBalance < 0
	|			THEN -CalculationsBalance.SumBalance
	|			ELSE 0 
	|		END AS AccountsPayableOfCompany,
	|		CASE WHEN CalculationsBalance.SumBalance > 0
	|			THEN CalculationsBalance.SumBalance
	|			ELSE 0 
	|		END AS CounterpartySDebt,
	|		CASE WHEN CalculationsBalance.SumComplBalance < 0
	|			THEN -CalculationsBalance.SumComplBalance
	|			ELSE 0 
	|		END AS OurDebtIsLocal,
	|		CASE WHEN CalculationsBalance.SumComplBalance > 0
	|			THEN CalculationsBalance.SumComplBalance
	|			ELSE 0 
	|		END AS CounterpartySDebtIsLocal,
	|		VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting) AS PaymentType_,
	|		31 AS Order
	|	FROM
	|		AccumulationRegister.FinancialInstrumentsARAP.Balance(&EndOfPeriod, 
	|			(&ForAllCurrencies OR Currency = &Currency)
	|			AND AccountingDimensionByPartners.Organization IN (&Organization)
	|			AND (&ForAllCounterparties OR AccountingDimensionByPartners.Counterparty IN (&Counterparty))
	|			AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|				OR &OnlyOurCompanies AND VALUETYPE(AccountingDimensionByPartners.Counterparty) = TYPE(Catalog.Companies))
	|			AND (VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting) IN (&TypesOfCalculations_))
	|			AND (Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing))
	|		) AS CalculationsBalance
	|		
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CalculationsBalance.Currency AS Currency,
	|		CASE WHEN CalculationsBalance.SumBalance > 0
	|			THEN CalculationsBalance.SumBalance
	|			ELSE 0 
	|		END AS AccountsPayableOfCompany,
	|		CASE WHEN CalculationsBalance.SumBalance < 0
	|			THEN -CalculationsBalance.SumBalance
	|			ELSE 0 
	|		END AS CounterpartySDebt,
	|		CASE WHEN CalculationsBalance.SumComplBalance > 0
	|			THEN CalculationsBalance.SumComplBalance
	|			ELSE 0 
	|		END AS OurDebtIsLocal,
	|		CASE WHEN CalculationsBalance.SumComplBalance < 0
	|			THEN -CalculationsBalance.SumComplBalance
	|			ELSE 0 
	|		END AS CounterpartySDebtIsLocal,
	|		VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting) AS PaymentType_,
	|		32 AS Order
	|	FROM
	|		AccumulationRegister.FinancialInstrumentsARAP.Balance(&EndOfPeriod, 
	|			(&ForAllCurrencies OR Currency = &Currency)
	|			AND AccountingDimensionByPartners.Organization IN (&Organization)
	|			AND (&ForAllCounterparties OR AccountingDimensionByPartners.Counterparty IN (&Counterparty))
	|			AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|				OR &OnlyOurCompanies AND VALUETYPE(AccountingDimensionByPartners.Counterparty) = TYPE(Catalog.Companies))
	|			AND (VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting) IN (&TypesOfCalculations_))
	|			AND (Contract.ContractKind IN (
	|				VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit),
	|				VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)))
	|		) AS CalculationsBalance
	|
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CalculationsBalance.Currency AS Currency,
	|		CASE 
	|			WHEN CalculationsBalance.SumBalance < 0 
	|				THEN -CalculationsBalance.SumBalance 
	|			ELSE 0 
	|		END AS AccountsPayableOfCompany,
	|		CASE 
	|			WHEN CalculationsBalance.SumBalance > 0 
	|				THEN CalculationsBalance.SumBalance 
	|			ELSE 0
	|		END AS CounterpartySDebt,
	|		CASE 
	|			WHEN CalculationsBalance.SumComplBalance < 0 
	|				THEN -CalculationsBalance.SumComplBalance 
	|			ELSE 0 
	|		END AS OurDebtIsLocal,
	|		CASE 
	|			WHEN CalculationsBalance.SumComplBalance > 0 
	|				THEN CalculationsBalance.SumComplBalance 
	|			ELSE 0
	|		END AS CounterpartySDebtIsLocal,
	|		VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor) AS PaymentType_,
	|		33 AS Order
	|	FROM
	|		AccumulationRegister.FinancialInstrumentsARAP.Balance(&EndOfPeriod, 
	|			(&ForAllCurrencies OR Currency = &Currency)
	|			AND AccountingDimensionByPartners.Organization IN (&Organization)
	|			AND (&ForAllCounterparties OR AccountingDimensionByPartners.Counterparty IN (&Counterparty))
	|			AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|				OR &OnlyOurCompanies AND VALUETYPE(AccountingDimensionByPartners.Counterparty) = TYPE(Catalog.Companies))
	|			AND (VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor) IN (&TypesOfCalculations_))
	|			AND AmountType IN (&TypesOfRentalAmountToBeReconciled)
	|			AND VALUETYPE(Contract) = TYPE(Catalog.LeaseContract)
	|		) AS CalculationsBalance
	|) AS Balance
	|
	|GROUP BY
	|	Balance.AccountingDimensionByPartners,
	|	Balance.Currency,
	|	Balance.PaymentType_,
	|	Balance.Order
	|
	|INDEX BY
	|	AccountingDimensionByPartners
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	BalanceAndTurnovers.Counterparty AS Counterparty,
	|	BalanceAndTurnovers.Currency AS Currency,
	|	SUM(BalanceAndTurnovers.AccountsPayableOfCompany) AS AccountsPayableOfCompany,
	|	SUM(BalanceAndTurnovers.CounterpartySDebt) AS CounterpartySDebt,
	|	SUM(BalanceAndTurnovers.TurnoverIsOurDebt) AS TurnoverIsOurDebt,
	|	SUM(BalanceAndTurnovers.TurnoverDebtOfCounterparty) AS TurnoverDebtOfCounterparty,
	|	SUM(BalanceAndTurnovers.OurDebtIsLocal) AS OurDebtIsLocal,
	|	SUM(BalanceAndTurnovers.CounterpartySDebtIsLocal) AS CounterpartySDebtIsLocal,
	|	SUM(BalanceAndTurnovers.TurnoverIsOurDebtToLocal) AS TurnoverIsOurDebtToLocal,
	|	SUM(BalanceAndTurnovers.TurnoverDebtOfCounterpartyLocal) AS TurnoverDebtOfCounterpartyLocal,
	|	MAX(BalanceAndTurnovers.ThereAreRevolutions) AS ThereAreRevolutions,
	|	BalanceAndTurnovers.PaymentType_ AS PaymentType_,
	|	CASE 
	|		WHEN BalanceAndTurnovers.Contract IN (
	|			VALUE(Catalog.CounterpartyContracts.EmptyRef),
	|			VALUE(Catalog.LoanAndDepositContracts.EmptyRef),
	|			VALUE(Catalog.LeaseContract.EmptyRef),
	|			VALUE(Catalog.IntercompanyContracts.EmptyRef))
	|		THEN UNDEFINED
	|		ELSE BalanceAndTurnovers.Contract
	|	END AS Contract,
	|	BalanceAndTurnovers.Manager AS Manager,
	|	BalanceAndTurnovers.Organization AS Organization,
	|	BalanceAndTurnovers.Order AS Order
	|INTO TTBalancesAndTurnoverUnderContracts
	|FROM
	|	(SELECT
	|		Dimension.Organization AS Organization,
	|		Dimension.Counterparty AS Counterparty,
	|		Dimension.Contract AS Contract,
	|		ISNULL(Counterparties.Partner.MainManager, UNDEFINED) AS Manager,
	|		BalancesByTypeOfCalculations.Currency AS Currency,
	|		BalancesByTypeOfCalculations.AccountsPayableOfCompany AS AccountsPayableOfCompany,
	|		BalancesByTypeOfCalculations.CounterpartySDebt AS CounterpartySDebt,
	|		0 AS TurnoverIsOurDebt,
	|		0 AS TurnoverDebtOfCounterparty,
	|		BalancesByTypeOfCalculations.OurDebtIsLocal AS OurDebtIsLocal,
	|		BalancesByTypeOfCalculations.CounterpartySDebtIsLocal AS CounterpartySDebtIsLocal,
	|		0 AS TurnoverIsOurDebtToLocal,
	|		0 AS TurnoverDebtOfCounterpartyLocal,
	|		FALSE AS ThereAreRevolutions,
	|		BalancesByTypeOfCalculations.PaymentType_ AS PaymentType_,
	|		BalancesByTypeOfCalculations.Order AS Order
	|	FROM
	|		TTBalancesByTypeOfCalculations AS BalancesByTypeOfCalculations
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|			ON BalancesByTypeOfCalculations.AccountingDimensionByPartners = Dimension.DimensionKey
	|		LEFT JOIN Catalog.Counterparties AS Counterparties
	|			ON Dimension.Counterparty = Counterparties.Ref
	|
	|	UNION ALL
	|	
	|	SELECT
	|		Turnovers.Organization AS Organization,
	|		Turnovers.Counterparty AS Counterparty,
	|		Turnovers.Contract AS Contract,
	|		Turnovers.Manager AS Manager,
	|		Turnovers.Currency AS Currency,
	|		0 AS AccountsPayableOfCompany,
	|		0 AS CounterpartySDebt,
	|		SUM(Turnovers.AccountsPayableOfCompany) AS TurnoverIsOurDebt,
	|		SUM(Turnovers.CounterpartySDebt) AS TurnoverDebtOfCounterparty,
	|		0 AS OurDebtIsLocal,
	|		0 AS CounterpartySDebtIsLocal,
	|		SUM(Turnovers.OurDebtIsLocal) AS TurnoverIsOurDebtToLocal,
	|		SUM(Turnovers.CounterpartySDebtIsLocal) AS TurnoverDebtOfCounterpartyLocal,
	|		COUNT(Turnovers.Ref) > 0 AS ThereAreRevolutions,
	|		Turnovers.PaymentType_ AS PaymentType_,
	|		Turnovers.Order AS Order
	|	FROM
	|		TTARAPDocuments AS Turnovers
	|		
	|	GROUP BY
	|		Turnovers.Organization,
	|		Turnovers.Counterparty,
	|		Turnovers.Contract,
	|		Turnovers.Manager,
	|		Turnovers.Currency,
	|		Turnovers.PaymentType_,
	|		Turnovers.Order
	|	
	|	UNION ALL
	|	
	|//Contracts without turnover
	|	SELECT
	|		Contracts.Organization AS Organization,
	|		Contracts.Counterparty AS Counterparty,
	|		Contracts.Ref AS Contract,
	|		ISNULL(Counterparties.Partner.MainManager, UNDEFINED) AS Manager,
	|		Contracts.ARAPCurrency AS Currency,
	|		0 AS AccountsPayableOfCompany,
	|		0 AS CounterpartySDebt,
	|		0 AS TurnoverIsOurDebt,
	|		0 AS TurnoverDebtOfCounterparty,
	|		0 AS OurDebtIsLocal,
	|		0 AS CounterpartySDebtIsLocal,
	|		0 AS TurnoverIsOurDebtToLocal,
	|		0 AS TurnoverDebtOfCounterpartyLocal,
	|		FALSE AS ThereAreRevolutions,
	|		CASE 
	|			WHEN Contracts.ContractType IN (
	|					VALUE(Enum.ContractTypes.WithCustomer),
	|					VALUE(Enum.ContractTypes.WithConsignee),
	|					//++ Deprecated_Recycling 24
	|					VALUE(Enum.ContractTypes.ReceiptForTolling),
	|					//-- Outdated_Recycling 24
	|					VALUE(Enum.ContractTypes.ReceiptForTolling2_5),
	|					VALUE(Enum.ContractTypes.ReceivingForCustody),
	|					VALUE(Enum.ContractTypes.TransferToCustody),
	|					VALUE(Enum.ContractTypes.CustomerInvoiceOutsourcedSale),
	|					VALUE(Enum.ContractTypes.SalesViaCommissionAgent))
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			WHEN Contracts.ContractType IN (
	|					VALUE(Enum.ContractTypes.WithVendor),
	|					VALUE(Enum.ContractTypes.WithConsignor),
	|					//++ Deprecated_Recycling 24
	|					VALUE(Enum.ContractTypes.TransferToTolling),
	|					//-- Outdated_Recycling 24
	|					VALUE(Enum.ContractTypes.TransferToTolling2_5),
	|					VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries),
	|					VALUE(Enum.ContractTypes.Import),
	|					VALUE(Enum.ContractTypes.PurchaseEAEU))
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		END AS PaymentType_,
	|		CASE 
	|			WHEN Contracts.ContractType IN (
	|					VALUE(Enum.ContractTypes.WithCustomer),
	|					VALUE(Enum.ContractTypes.WithConsignee),
	|					//++ Deprecated_Recycling 24
	|					VALUE(Enum.ContractTypes.ReceiptForTolling),
	|					//-- Outdated_Recycling 24
	|					VALUE(Enum.ContractTypes.ReceiptForTolling2_5),
	|					VALUE(Enum.ContractTypes.ReceivingForCustody))
	|				THEN 10
	|			WHEN Contracts.ContractType IN (
	|					VALUE(Enum.ContractTypes.WithVendor),
	|					VALUE(Enum.ContractTypes.WithConsignor),
	|					//++ Deprecated_Recycling 24
	|					VALUE(Enum.ContractTypes.TransferToTolling),
	|					//-- Outdated_Recycling 24
	|					VALUE(Enum.ContractTypes.TransferToTolling2_5),
	|					VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries),
	|					VALUE(Enum.ContractTypes.Import),
	|					VALUE(Enum.ContractTypes.PurchaseEAEU))
	|				THEN 20
	|		END AS Order
	|	FROM
	|		Catalog.CounterpartyContracts AS Contracts
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON Contracts.Counterparty = Counterparties.Ref
	|	WHERE
	|		&ContractsWithoutTurnover
	|		AND NOT Contracts.DeletionMark
	|		AND Contracts.Organization IN (&Organization)
	|		AND (&ForAllCounterparties OR Contracts.Counterparty IN (&Counterparty))
	|		AND (&ForAllCurrencies OR Contracts.ARAPCurrency = &Currency)
	|		AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|			OR &OnlyOurCompanies AND VALUETYPE(Contracts.Counterparty) = TYPE(Catalog.Companies))
	|		AND CASE 
	|			WHEN Contracts.ContractType IN (
	|					VALUE(Enum.ContractTypes.WithCustomer),
	|					VALUE(Enum.ContractTypes.WithConsignee),
	|					//++ Deprecated_Recycling 24
	|					VALUE(Enum.ContractTypes.ReceiptForTolling),
	|					//-- Outdated_Recycling 24
	|					VALUE(Enum.ContractTypes.ReceiptForTolling2_5),
	|					VALUE(Enum.ContractTypes.ReceivingForCustody))
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			WHEN Contracts.ContractType IN (
	|					VALUE(Enum.ContractTypes.WithVendor),
	|					VALUE(Enum.ContractTypes.WithConsignor),
	|					//++ Deprecated_Recycling 24
	|					VALUE(Enum.ContractTypes.TransferToTolling),
	|					//-- Outdated_Recycling 24
	|					VALUE(Enum.ContractTypes.TransferToTolling2_5),
	|					VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries),
	|					VALUE(Enum.ContractTypes.Import),
	|					VALUE(Enum.ContractTypes.PurchaseEAEU))
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		END IN (&TypesOfCalculations_)
	|	{WHERE
	|		CASE 
	|			WHEN Contracts.ContractType IN (
	|					VALUE(Enum.ContractTypes.WithCustomer),
	|					VALUE(Enum.ContractTypes.WithConsignee),
	|					//++ Deprecated_Recycling 24
	|					VALUE(Enum.ContractTypes.ReceiptForTolling),
	|					//-- Outdated_Recycling 24
	|					VALUE(Enum.ContractTypes.ReceiptForTolling2_5),
	|					VALUE(Enum.ContractTypes.ReceivingForCustody))
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			WHEN Contracts.ContractType IN (
	|					VALUE(Enum.ContractTypes.WithVendor),
	|					VALUE(Enum.ContractTypes.WithConsignor),
	|					//++ Deprecated_Recycling 24
	|					VALUE(Enum.ContractTypes.TransferToTolling),
	|					//-- Outdated_Recycling 24
	|					VALUE(Enum.ContractTypes.TransferToTolling2_5),
	|					VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries),
	|					VALUE(Enum.ContractTypes.Import),
	|					VALUE(Enum.ContractTypes.PurchaseEAEU))
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		END AS PaymentType_,
	|		TRUE AS ContractsWithoutTurnover}
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Contracts.Organization AS Organization,
	|		Contracts.Counterparty AS Counterparty,
	|		Contracts.Ref AS Contract,
	|		ISNULL(Counterparties.Partner.MainManager, UNDEFINED) AS Manager,
	|		Contracts.ARAPCurrency AS Currency,
	|		0 AS AccountsPayableOfCompany,
	|		0 AS CounterpartySDebt,
	|		0 AS TurnoverIsOurDebt,
	|		0 AS TurnoverDebtOfCounterparty,
	|		0 AS OurDebtIsLocal,
	|		0 AS CounterpartySDebtIsLocal,
	|		0 AS TurnoverIsOurDebtToLocal,
	|		0 AS TurnoverDebtOfCounterpartyLocal,
	|		FALSE AS ThereAreRevolutions,
	|		CASE 
	|			WHEN Contracts.ContractType = VALUE(Enum.TypesOfIntercompanyContracts.PurchaseAndSale)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			WHEN Contracts.ContractType = VALUE(Enum.TypesOfIntercompanyContracts.Consignment)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		END AS PaymentType_,
	|		CASE 
	|			WHEN Contracts.ContractType = VALUE(Enum.TypesOfIntercompanyContracts.PurchaseAndSale)
	|				THEN 10
	|			WHEN Contracts.ContractType = VALUE(Enum.TypesOfIntercompanyContracts.Consignment)
	|				THEN 20
	|		END AS Order
	|	FROM
	|		Catalog.CounterpartyContracts AS Contracts
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON Contracts.Counterparty = Counterparties.Ref
	|	WHERE
	|		&ContractsWithoutTurnover
	|		AND NOT Contracts.DeletionMark
	|		AND Contracts.Organization IN (&Organization)
	|		AND (&ForAllCounterparties OR Contracts.Counterparty IN (&Counterparty))
	|		AND (&ForAllCurrencies OR Contracts.ARAPCurrency = &Currency)
	|		AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|			OR &OnlyOurCompanies AND VALUETYPE(Contracts.Counterparty) = TYPE(Catalog.Companies))
	|		AND CASE 
	|			WHEN Contracts.ContractType = VALUE(Enum.TypesOfIntercompanyContracts.PurchaseAndSale)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			WHEN Contracts.ContractType  = VALUE(Enum.TypesOfIntercompanyContracts.Consignment)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		END IN (&TypesOfCalculations_)
	|	{WHERE
	|		CASE 
	|			WHEN Contracts.ContractType = VALUE(Enum.TypesOfIntercompanyContracts.PurchaseAndSale)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			WHEN Contracts.ContractType  = VALUE(Enum.TypesOfIntercompanyContracts.Consignment)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		END AS PaymentType_,
	|		TRUE AS ContractsWithoutTurnover}
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Contracts.Organization AS Organization,
	|		Contracts.Counterparty AS Counterparty,
	|		Contracts.Ref AS Contract,
	|		ISNULL(Counterparties.Partner.MainManager, UNDEFINED) AS Manager,
	|		Contracts.ARAPCurrency AS Currency,
	|		0 AS AccountsPayableOfCompany,
	|		0 AS CounterpartySDebt,
	|		0 AS TurnoverIsOurDebt,
	|		0 AS TurnoverDebtOfCounterparty,
	|		0 AS OurDebtIsLocal,
	|		0 AS CounterpartySDebtIsLocal,
	|		0 AS TurnoverIsOurDebtToLocal,
	|		0 AS TurnoverDebtOfCounterpartyLocal,
	|		FALSE AS ThereAreRevolutions,
	|		CASE 
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|					OR Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|		END AS PaymentType_,
	|		CASE 
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN 31
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|					OR Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|				THEN 32
	|		END AS Order
	|	FROM
	|		Catalog.LoanAndDepositContracts AS Contracts
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON Contracts.Counterparty = Counterparties.Ref
	|	WHERE
	|		&ContractsWithoutTurnover
	|		AND NOT Contracts.DeletionMark
	|		AND Contracts.Organization IN (&Organization)
	|		AND (&ForAllCounterparties OR Contracts.Counterparty IN (&Counterparty))
	|		AND (&ForAllCurrencies OR Contracts.ARAPCurrency = &Currency)
	|		AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|			OR &OnlyOurCompanies AND VALUETYPE(Contracts.Counterparty) = TYPE(Catalog.Companies))
	|		AND CASE 
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|					OR Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|		END IN (&TypesOfCalculations_)
	|	{WHERE
	|		CASE 
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|			WHEN Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|					OR Contracts.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|		END AS PaymentType_,
	|		TRUE AS ContractsWithoutTurnover}
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Contracts.Organization AS Organization,
	|		Contracts.Counterparty AS Counterparty,
	|		Contracts.Ref AS Contract,
	|		ISNULL(Counterparties.Partner.MainManager, UNDEFINED) AS Manager,
	|		Contracts.ARAPCurrency AS Currency,
	|		0 AS AccountsPayableOfCompany,
	|		0 AS CounterpartySDebt,
	|		0 AS TurnoverIsOurDebt,
	|		0 AS TurnoverDebtOfCounterparty,
	|		0 AS OurDebtIsLocal,
	|		0 AS CounterpartySDebtIsLocal,
	|		0 AS TurnoverIsOurDebtToLocal,
	|		0 AS TurnoverDebtOfCounterpartyLocal,
	|		FALSE AS ThereAreRevolutions,
	|		VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor) AS PaymentType_,
	|		33 AS Order
	|	FROM
	|		Catalog.LeaseContract AS Contracts
	|		INNER JOIN Catalog.Counterparties AS Counterparties
	|		ON Contracts.Counterparty = Counterparties.Ref
	|	WHERE
	|		&ContractsWithoutTurnover
	|		AND NOT Contracts.DeletionMark
	|		AND Contracts.Organization IN (&Organization)
	|		AND (&ForAllCounterparties OR Contracts.Counterparty IN (&Counterparty))
	|		AND (&ForAllCurrencies OR Contracts.ARAPCurrency = &Currency)
	|		AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|			OR &OnlyOurCompanies AND VALUETYPE(Contracts.Counterparty) = TYPE(Catalog.Companies))
	|		AND (VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor) IN (&TypesOfCalculations_))
	|	{WHERE
	|		VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor) AS PaymentType_,
	|		TRUE AS ContractsWithoutTurnover}
	|	) BalanceAndTurnovers
	|WHERE
	|	(&ForAllManagers OR BalanceAndTurnovers.Manager = &Manager)
	|
	|GROUP BY
	|	BalanceAndTurnovers.Organization,
	|	BalanceAndTurnovers.Counterparty,
	|	CASE 
	|		WHEN BalanceAndTurnovers.Contract IN (
	|			VALUE(Catalog.CounterpartyContracts.EmptyRef),
	|			VALUE(Catalog.LoanAndDepositContracts.EmptyRef),
	|			VALUE(Catalog.LeaseContract.EmptyRef),
	|			VALUE(Catalog.IntercompanyContracts.EmptyRef))
	|		THEN UNDEFINED
	|		ELSE BalanceAndTurnovers.Contract
	|	END,
	|	BalanceAndTurnovers.Manager,
	|	BalanceAndTurnovers.Currency,
	|	BalanceAndTurnovers.PaymentType_,
	|	BalanceAndTurnovers.Order
	|;
	|
	|";
	
	Return QueryText;
	
EndFunction
#EndRegion

#Region Private

//Returns:
//  Structure of KeyAndValue :
//   Name - String - string Status identifier.
//   Presentation - String - Presentation of the Status in the user interface.
//   Picture - Number - Index in the picture Collectionlight.
//
Function NewStatus(Name = "", Presentation = "", Picture = 0)
	
	Result = New Structure;
	Result.Insert("Name", Name);
	Result.Insert("Presentation", Presentation);
	Result.Insert("Picture", Picture);
	
	Return Result;
	
EndFunction

Function QueryTextReconciliationMonitorData()
	
	QueryText = QueryTextCalculationData() + 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TypesOfCalculations_.Organization AS Organization,
	|	TypesOfCalculations_.Counterparty AS Counterparty,
	|	TypesOfCalculations_.Currency AS Currency,
	|	SUM(TypesOfCalculations_.CodeTypeOfCalculations) AS Code
	|INTO TTCalculationTypeCodes
	|FROM
	|	(SELECT DISTINCT
	|		BalanceAndTurnovers.Organization AS Organization,
	|		BalanceAndTurnovers.Counterparty AS Counterparty,
	|		BalanceAndTurnovers.Currency AS Currency,
	|		CASE 
	|			WHEN BalanceAndTurnovers.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN 1
	|			WHEN BalanceAndTurnovers.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				THEN 20
	|			WHEN BalanceAndTurnovers.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting)
	|				THEN 300
	|			WHEN BalanceAndTurnovers.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.DebtorARAPAccounting)
	|				THEN 4000
	|			WHEN BalanceAndTurnovers.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor)
	|				THEN 50000
	|			ELSE
	|				0
	|		END AS CodeTypeOfCalculations
	|	FROM
	|		TTBalancesAndTurnoverUnderContracts AS BalanceAndTurnovers) AS TypesOfCalculations_
	|GROUP BY
	|	TypesOfCalculations_.Organization,
	|	TypesOfCalculations_.Counterparty,
	|	TypesOfCalculations_.Currency
	|
	|INDEX BY
	|	Organization,
	|	Counterparty,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceAndTurnovers.Counterparty AS Counterparty,
	|	BalanceAndTurnovers.Currency AS Currency,
	|	SUM(BalanceAndTurnovers.AccountsPayableOfCompany) AS AccountsPayableOfCompany,
	|	SUM(BalanceAndTurnovers.CounterpartySDebt) AS CounterpartySDebt,
	|	SUM(BalanceAndTurnovers.TurnoverIsOurDebt) AS TurnoverIsOurDebt,
	|	SUM(BalanceAndTurnovers.TurnoverDebtOfCounterparty) AS TurnoverDebtOfCounterparty,
	|	SUM(BalanceAndTurnovers.OurDebtIsLocal) AS OurDebtIsLocal,
	|	SUM(BalanceAndTurnovers.CounterpartySDebtIsLocal) AS CounterpartySDebtIsLocal,
	|	SUM(BalanceAndTurnovers.TurnoverIsOurDebtToLocal) AS TurnoverIsOurDebtToLocal,
	|	SUM(BalanceAndTurnovers.TurnoverDebtOfCounterpartyLocal) AS TurnoverDebtOfCounterpartyLocal,
	|	MAX(BalanceAndTurnovers.ThereAreRevolutions) AS ThereAreRevolutions,
	|	CalculationTypeCodes.Code AS CodeTypeOfCalculations,
	|	BalanceAndTurnovers.Manager AS Manager,
	|	ISNULL(Users.Description, &IsBlankString) AS Manager_Name_,
	|	ISNULL(Counterparties.Description, 
	|		ISNULL(Companies.Description, &IsBlankString)) AS CounterpartyName_,
	|	BalanceAndTurnovers.Organization AS Organization,
	|	BalanceAndTurnovers.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	MIN(BalanceAndTurnovers.Order) AS Order
	|INTO TTBalancesAndRevolutions
	|FROM 
	|	TTBalancesAndTurnoverUnderContracts AS BalanceAndTurnovers
	|	LEFT JOIN Catalog.Users AS Users
	|		ON BalanceAndTurnovers.Manager = Users.Ref
	|	LEFT JOIN Catalog.Counterparties AS Counterparties
	|		ON BalanceAndTurnovers.Counterparty = Counterparties.Ref
	|	LEFT JOIN Catalog.Companies AS Companies
	|		ON BalanceAndTurnovers.Counterparty = Companies.Ref
	|	LEFT JOIN TTCalculationTypeCodes AS CalculationTypeCodes
	|		ON BalanceAndTurnovers.Organization = CalculationTypeCodes.Organization
	|		AND BalanceAndTurnovers.Counterparty = CalculationTypeCodes.Counterparty
	|		AND BalanceAndTurnovers.Currency = CalculationTypeCodes.Currency
	|
	|GROUP BY
	|	BalanceAndTurnovers.Counterparty,
	|	BalanceAndTurnovers.Currency,
	|	BalanceAndTurnovers.Manager,
	|	CalculationTypeCodes.Code,
	|	ISNULL(Users.Description, &IsBlankString),
	|	ISNULL(Counterparties.Description, 
	|		ISNULL(Companies.Description, &IsBlankString)),
	|	BalanceAndTurnovers.Organization
	|	
	|INDEX BY
	|	Organization,
	|	Counterparty,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(NestedQuery.DateOfLastOperation) AS DateOfLastOperation,
	|	NestedQuery.Currency AS Currency,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Recorder AS Recorder,
	|	NestedQuery.EDIState AS EDIState,
	|	SUM(NestedQuery.TotalDocuments) AS TotalDocuments,
	|	SUM(NestedQuery.NotExchangeIsCompleted_) AS NotExchangeIsCompleted_,
	|	SUM(NestedQuery.ExchangeIsCompleted_) AS ExchangeIsCompleted_,
	|	MAX(NestedQuery.EDIParticipant) AS EDIParticipant
	|INTO TTCalculationsData
	|FROM
	|	(SELECT
	|		MAX(SettlementDocuments.Period) AS DateOfLastOperation,
	|		SettlementDocuments.Currency AS Currency,
	|		SettlementDocuments.Organization AS Organization,
	|		SettlementDocuments.Counterparty AS Counterparty,
	|		UNDEFINED AS Recorder,
	|		UNDEFINED AS EDIState,
	|		COUNT(SettlementDocuments.Ref) AS TotalDocuments,
	|		0 AS NotExchangeIsCompleted_,
	|		0 AS ExchangeIsCompleted_,
	|		FALSE AS EDIParticipant
	|	FROM
	|		TTARAPDocuments AS SettlementDocuments
	|		LEFT JOIN InformationRegister.StatesByEDIAccountingObjects AS EDOStates
	|		ON SettlementDocuments.Ref = EDOStates.ObjectReference
	|	GROUP BY
	|		SettlementDocuments.Organization,
	|		SettlementDocuments.Counterparty,
	|		SettlementDocuments.Currency
	|) NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Organization,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Currency,
	|	NestedQuery.Recorder,
	|	NestedQuery.EDIState
	|
	|INDEX BY
	|	Organization,
	|	Counterparty,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Reconciliation.Ref AS Ref,
	|	Reconciliation.Status AS Status,
	|	Reconciliation.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	Reconciliation.EndOfPeriod AS EndOfPeriod,
	|	CASE
	|		WHEN Reconciliation.Status = VALUE(Enum.StatusesOfARAPReconciliation2_5_11.ReconciledWithDisputes)
	|			THEN Reconciliation.Date
	|			ELSE DATETIME(1,1,1)
	|	END AS DateVerifiedWithDisagreements,
	|	CASE
	|		WHEN Reconciliation.Status = VALUE(Enum.StatusesOfARAPReconciliation2_5_11.ReconciledWithoutDisputes)
	|			THEN Reconciliation.Date
	|			ELSE DATETIME(1,1,1)
	|	END AS DateIsVerifiedWithoutDisagreement,
	|	Reconciliation.Counterparty AS Counterparty,
	|	Reconciliation.Organization AS Organization,
	|	ISNULL(Totals.Contract, UNDEFINED) AS Contract,
	|	Reconciliation.Currency AS Currency,
	|	Reconciliation.ReconciliationInCurrency AS ReconciliationInCurrency
	|INTO TTReconciliationDocumentsForContracts
	|FROM
	|	Document.ARAPReconciliation2_5_11 AS Reconciliation
	|	LEFT JOIN Document.ARAPReconciliation2_5_11.SummaryRecords AS Totals
	|	ON Reconciliation.Ref = Totals.Ref
	|WHERE
	|	Reconciliation.Posted
	|	AND Reconciliation.Status <> VALUE(Enum.StatusesOfARAPReconciliation2_5_11.IsRejected)
	|	AND Reconciliation.Organization IN (&Organization)
	|	AND (&ForAllCounterparties OR Reconciliation.Counterparty IN (&Counterparty))
	|	AND (NOT &OnlyOurCompanies OR NOT &ForAllCounterparties
	|		OR &OnlyOurCompanies AND VALUETYPE(Reconciliation.Counterparty) = TYPE(Catalog.Companies))
	|	AND (&ForAllManagers OR Reconciliation.Manager = &Manager)
	|	AND Reconciliation.BeginOfPeriod <= &EndOfPeriod
	|	AND Reconciliation.EndOfPeriod >= &BeginOfPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Reconciliation.Ref AS Ref,
	|	Reconciliation.Status AS Status,
	|	Reconciliation.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	Reconciliation.EndOfPeriod AS EndOfPeriod,
	|	Reconciliation.DateVerifiedWithDisagreements AS DateVerifiedWithDisagreements,
	|	Reconciliation.DateIsVerifiedWithoutDisagreement AS DateIsVerifiedWithoutDisagreement,
	|	Reconciliation.Counterparty AS Counterparty,
	|	Reconciliation.Organization AS Organization,
	|	Reconciliation.Currency AS Currency,
	|	Reconciliation.ReconciliationInCurrency AS ReconciliationInCurrency
	|INTO TTReconciliationDocumentsForPeriod
	|FROM
	|	TTReconciliationDocumentsForContracts AS Reconciliation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	COUNT(Reconciliation.Ref) AS TotalDocuments,
	|	SUM(Reconciliation.CreatedOn_) AS CreatedOn_,
	|	SUM(Reconciliation.OnReconciliation) AS OnReconciliation,
	|	SUM(Reconciliation.ReconciledWithDisputes) AS ReconciledWithDisputes,
	|	SUM(Reconciliation.ReconciledWithoutDisputes) AS ReconciledWithoutDisputes,
	|	MAX(Reconciliation.ThereAreDiscrepancies) AS ThereAreDiscrepancies,
	|	MAX(Reconciliation.EndOfPeriod) AS MaximumReconciliationPeriod,
	|	MAX(Reconciliation.DateVerifiedWithDisagreements) AS DateVerifiedWithDisagreements,
	|	MAX(Reconciliation.DateIsVerifiedWithoutDisagreement) AS DateIsVerifiedWithoutDisagreement,
	|	Reconciliation.Counterparty AS Counterparty,
	|	Reconciliation.Organization AS Organization,
	|	Reconciliation.Currency AS ReconciliationCurrency,
	|	Reconciliation.ReconciliationInCurrency AS ReconciliationInCurrency
	|INTO TTReconciliationDocuments
	|FROM
	|	(SELECT
	|		Reconciliation.Ref AS Ref,
	|		Reconciliation.Status AS Status,
	|		CASE 
	|			WHEN Reconciliation.Status = VALUE(Enum.StatusesOfARAPReconciliation2_5_11.CreatedOn_)
	|				THEN 1
	|			ELSE 0
	|		END CreatedOn_,
	|		CASE 
	|			WHEN Reconciliation.Status = VALUE(Enum.StatusesOfARAPReconciliation2_5_11.OnReconciliation)
	|				THEN 1
	|			ELSE 0
	|		END AS OnReconciliation,
	|		CASE 
	|			WHEN Reconciliation.Status = VALUE(Enum.StatusesOfARAPReconciliation2_5_11.ReconciledWithDisputes)
	|				THEN 1
	|			ELSE 0
	|		END AS ReconciledWithDisputes,
	|		CASE 
	|			WHEN Reconciliation.Status = VALUE(Enum.StatusesOfARAPReconciliation2_5_11.ReconciledWithoutDisputes)
	|				THEN 1
	|			ELSE 0
	|		END AS ReconciledWithoutDisputes,
	|		Reconciliation.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|		Reconciliation.EndOfPeriod AS EndOfPeriod,
	|		Reconciliation.DateVerifiedWithDisagreements AS DateVerifiedWithDisagreements,
	|		Reconciliation.DateIsVerifiedWithoutDisagreement AS DateIsVerifiedWithoutDisagreement,
	|		Reconciliation.Counterparty AS Counterparty,
	|		Reconciliation.Organization AS Organization,
	|		Reconciliation.Currency AS Currency,
	|		Reconciliation.ReconciliationInCurrency AS ReconciliationInCurrency
	|	FROM
	|		TTReconciliationDocumentsForPeriod AS Reconciliation
	|	WHERE
	|		TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.ARAPReconciliation2_5_11.SummaryRecords AS TSSummaryRecords
	|			WHERE
	|				Reconciliation.Ref = TSSummaryRecords.Ref
	|				AND TSSummaryRecords.PaymentType_ IN (&TypesOfCalculations_))) AS Reconciliation
	|	
	|GROUP BY
	|	Reconciliation.Organization,
	|	Reconciliation.Counterparty,
	|	Reconciliation.Currency,
	|	Reconciliation.ReconciliationInCurrency
	|	
	|INDEX BY
	|	Organization,
	|	Counterparty,
	|	ReconciliationCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationData.Organization AS Organization,
	|	CalculationData.Counterparty AS Counterparty,
	|	CalculationData.SettlementsCurrency AS SettlementsCurrency,
	|	CalculationData.ThereIsReconciliationReport AS ThereIsReconciliationReport,
	|	CalculationData.ReconciliationCurrency AS ReconciliationCurrency,
	|	CalculationData.Reconciliation AS Reconciliation
	|	
	|INTO TTAvailabilityOfReconciliationPreliminary
	|FROM
	|	(SELECT DISTINCT
	|		SettlementDocuments.Organization AS Organization,
	|		SettlementDocuments.Counterparty AS Counterparty,
	|		SettlementDocuments.Currency AS SettlementsCurrency,
	|		ISNULL(ReconciliationDocuments.Currency, UNDEFINED) AS ReconciliationCurrency,
	|		ReconciliationDocuments.Currency IS NOT NULL AS ThereIsReconciliationReport,
	|		Details_3.Ref AS Reconciliation
	|		
	|	FROM
	|		TTARAPDocuments AS SettlementDocuments
	|		LEFT JOIN Document.ARAPReconciliation2_5_11.DetailedRecords AS Details_3
	|		ON SettlementDocuments.Ref = Details_3.ARAPDocument
	|			AND (SettlementDocuments.ThisIsAccrualOfLoansAndDeposits
	|					AND SettlementDocuments.Currency = Details_3.DocumentCurrency
	|				OR NOT SettlementDocuments.ThisIsAccrualOfLoansAndDeposits)
	|		LEFT JOIN TTReconciliationDocumentsForPeriod AS ReconciliationDocuments
	|		ON Details_3.Ref = ReconciliationDocuments.Ref
	|	WHERE
	|		TRUE IN (SELECT TOP 1
	|					TRUE 
	|				FROM 
	|					TTReconciliationDocumentsForPeriod AS Reconciliation 
	|				WHERE 
	|					Details_3.Ref = Reconciliation.Ref)
	|		
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		BalanceAndTurnovers.Organization AS Organization,
	|		BalanceAndTurnovers.Counterparty AS Counterparty,
	|		BalanceAndTurnovers.Currency AS SettlementsCurrency,
	|		ISNULL(ReconciliationDocumentsForContracts.Currency, UNDEFINED) AS ReconciliationCurrency,
	|		ReconciliationDocumentsForContracts.Currency IS NOT NULL AS ThereIsReconciliationReport,
	|		ReconciliationDocumentsForContracts.Ref AS Reconciliation
	|	FROM
	|		TTBalancesAndTurnoverUnderContracts AS BalanceAndTurnovers
	|		LEFT JOIN TTReconciliationDocumentsForContracts AS ReconciliationDocumentsForContracts
	|			ON BalanceAndTurnovers.Organization = ReconciliationDocumentsForContracts.Organization
	|			AND BalanceAndTurnovers.Counterparty = ReconciliationDocumentsForContracts.Counterparty
	|			AND BalanceAndTurnovers.Contract = ReconciliationDocumentsForContracts.Contract
	|			AND (BalanceAndTurnovers.Currency = ReconciliationDocumentsForContracts.Currency
	|				OR BalanceAndTurnovers.Currency <> &ComplCurrency
	|					AND NOT ReconciliationDocumentsForContracts.ReconciliationInCurrency)
	|	) AS CalculationData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationData.Organization AS Organization,
	|	CalculationData.Counterparty AS Counterparty,
	|	CalculationData.SettlementsCurrency AS SettlementsCurrency,
	|	MAX(CalculationData.ThereIsReconciliationReport) AS ThereIsReconciliationReport
	|	
	|INTO TTAvailabilityOfReconciliation
	|FROM
	|	TTAvailabilityOfReconciliationPreliminary AS CalculationData
	|GROUP BY
	|	CalculationData.Organization,
	|	CalculationData.Counterparty,
	|	CalculationData.SettlementsCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	UNDEFINED AS Organization,
	|	UNDEFINED AS Counterparty,
	|	FALSE AS ThereAreDiscrepancies,
	|	FALSE AS CompanyIsConnected,
	|	FALSE AS CounterpartyIsConnected
	|INTO TTReconciliationServiceData
	|WHERE
	|	FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceAndTurnovers.Counterparty AS Counterparty,
	|	BalanceAndTurnovers.Currency AS Currency,
	|	BalanceAndTurnovers.AccountsPayableOfCompany AS AccountsPayableOfCompany,
	|	BalanceAndTurnovers.CounterpartySDebt AS CounterpartySDebt,
	|	BalanceAndTurnovers.TurnoverIsOurDebt AS TurnoverIsOurDebt,
	|	BalanceAndTurnovers.TurnoverDebtOfCounterparty AS TurnoverDebtOfCounterparty,
	|	BalanceAndTurnovers.OurDebtIsLocal AS OurDebtIsLocal,
	|	BalanceAndTurnovers.CounterpartySDebtIsLocal AS CounterpartySDebtIsLocal,
	|	BalanceAndTurnovers.TurnoverIsOurDebtToLocal AS TurnoverIsOurDebtToLocal,
	|	BalanceAndTurnovers.TurnoverDebtOfCounterpartyLocal AS TurnoverDebtOfCounterpartyLocal,
	|	BalanceAndTurnovers.ThereAreRevolutions AS ThereAreRevolutions,
	|	
	|	AvailabilityOfReconciliation.ThereIsReconciliationReport AS ThereIsReconciliationReport,
	|	CASE 
	|		WHEN AvailabilityOfReconciliation.ThereIsReconciliationReport
	|			THEN ISNULL(ReconciliationDocumentsInCurrency.MaximumReconciliationPeriod,
	|					ISNULL(ReconciliationDocuments.MaximumReconciliationPeriod, DATETIME(3999,1,1)))
	|			ELSE DATETIME(3999,1,1)
	|	END AS MaximumReconciliationPeriod,
	|	CASE 
	|		WHEN AvailabilityOfReconciliation.ThereIsReconciliationReport
	|			THEN ISNULL(ReconciliationDocumentsInCurrency.DateVerifiedWithDisagreements,
	|					ISNULL(ReconciliationDocuments.DateVerifiedWithDisagreements, DATETIME(1,1,1)))
	|			ELSE DATETIME(1,1,1)
	|	END AS DateVerifiedWithDisagreements,
	|	CASE 
	|		WHEN AvailabilityOfReconciliation.ThereIsReconciliationReport
	|			THEN ISNULL(ReconciliationDocumentsInCurrency.DateIsVerifiedWithoutDisagreement,
	|					ISNULL(ReconciliationDocuments.DateIsVerifiedWithoutDisagreement, DATETIME(1,1,1)))
	|			ELSE DATETIME(1,1,1)
	|	END AS DateIsVerifiedWithoutDisagreement,
	|	CASE 
	|		WHEN AvailabilityOfReconciliation.ThereIsReconciliationReport
	|			THEN ISNULL(ReconciliationDocumentsInCurrency.CreatedOn_,
	|					ISNULL(ReconciliationDocuments.CreatedOn_, 0))
	|			ELSE 0
	|	END AS CreatedOn_,
	|	CASE 
	|		WHEN AvailabilityOfReconciliation.ThereIsReconciliationReport
	|			THEN ISNULL(ReconciliationDocumentsInCurrency.OnReconciliation,
	|					ISNULL(ReconciliationDocuments.OnReconciliation, 0))
	|			ELSE 0
	|	END AS OnReconciliation,
	|	CASE 
	|		WHEN AvailabilityOfReconciliation.ThereIsReconciliationReport
	|			THEN ISNULL(ReconciliationDocumentsInCurrency.ReconciledWithDisputes,
	|					ISNULL(ReconciliationDocuments.ReconciledWithDisputes, 0))
	|			ELSE 0
	|	END AS ReconciledWithDisputes,
	|	CASE 
	|		WHEN AvailabilityOfReconciliation.ThereIsReconciliationReport
	|			THEN ISNULL(ReconciliationDocumentsInCurrency.ReconciledWithoutDisputes,
	|					ISNULL(ReconciliationDocuments.ReconciledWithoutDisputes, 0))
	|			ELSE 0
	|	END AS ReconciledWithoutDisputes,
	|	CASE 
	|		WHEN AvailabilityOfReconciliation.ThereIsReconciliationReport
	|			THEN ISNULL(ReconciliationDocumentsInCurrency.ThereAreDiscrepancies,
	|					ISNULL(ReconciliationDocuments.ThereAreDiscrepancies, FALSE))
	|			ELSE FALSE
	|	END AS ThereAreDiscrepancies,
	|		
	|	BalanceAndTurnovers.Manager AS Manager,
	|	BalanceAndTurnovers.Organization AS Organization,
	|	BalanceAndTurnovers.Manager_Name_ AS Manager_Name_,
	|	BalanceAndTurnovers.CounterpartyName_ AS CounterpartyName_,
	|	BalanceAndTurnovers.CodeTypeOfCalculations AS CodeTypeOfCalculations,
	|	BalanceAndTurnovers.Order AS Order
	|
	|INTO TTBalancesTurnoverReconciliationDocuments
	|FROM 
	|	TTBalancesAndRevolutions AS BalanceAndTurnovers
	|	LEFT JOIN TTReconciliationDocuments AS ReconciliationDocuments
	|		ON BalanceAndTurnovers.Organization = ReconciliationDocuments.Organization
	|		AND BalanceAndTurnovers.Counterparty = ReconciliationDocuments.Counterparty
	|		AND NOT ReconciliationDocuments.ReconciliationInCurrency
	|	LEFT JOIN TTReconciliationDocuments AS ReconciliationDocumentsInCurrency
	|		ON BalanceAndTurnovers.Organization = ReconciliationDocumentsInCurrency.Organization
	|		AND BalanceAndTurnovers.Counterparty = ReconciliationDocumentsInCurrency.Counterparty
	|		AND BalanceAndTurnovers.Currency = ReconciliationDocumentsInCurrency.ReconciliationCurrency
	|		AND ReconciliationDocumentsInCurrency.ReconciliationInCurrency
	|	LEFT JOIN TTAvailabilityOfReconciliation AS AvailabilityOfReconciliation
	|		ON BalanceAndTurnovers.Organization = AvailabilityOfReconciliation.Organization
	|		AND BalanceAndTurnovers.Counterparty = AvailabilityOfReconciliation.Counterparty
	|		AND BalanceAndTurnovers.Currency = AvailabilityOfReconciliation.SettlementsCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReconciliationBalancesTurnover.Counterparty AS Counterparty,
	|	ReconciliationBalancesTurnover.Currency AS Currency,
	|	CASE 
	|		WHEN ReconciliationBalancesTurnover.AccountsPayableOfCompany - ReconciliationBalancesTurnover.CounterpartySDebt > 0
	|			THEN ReconciliationBalancesTurnover.AccountsPayableOfCompany - ReconciliationBalancesTurnover.CounterpartySDebt
	|		ELSE 0
	|	END AS AccountsPayableOfCompany,
	|	CASE 
	|		WHEN ReconciliationBalancesTurnover.CounterpartySDebt - ReconciliationBalancesTurnover.AccountsPayableOfCompany  > 0
	|			THEN ReconciliationBalancesTurnover.CounterpartySDebt - ReconciliationBalancesTurnover.AccountsPayableOfCompany
	|		ELSE 0
	|	END AS CounterpartySDebt,
	|	ReconciliationBalancesTurnover.TurnoverIsOurDebt AS TurnoverIsOurDebt,
	|	ReconciliationBalancesTurnover.TurnoverDebtOfCounterparty AS TurnoverDebtOfCounterparty,
	|	CASE 
	|		WHEN ReconciliationBalancesTurnover.OurDebtIsLocal - ReconciliationBalancesTurnover.CounterpartySDebtIsLocal > 0
	|			THEN ReconciliationBalancesTurnover.OurDebtIsLocal - ReconciliationBalancesTurnover.CounterpartySDebtIsLocal
	|		ELSE 0
	|	END AS OurDebtIsLocal,
	|	CASE 
	|		WHEN ReconciliationBalancesTurnover.CounterpartySDebtIsLocal - ReconciliationBalancesTurnover.OurDebtIsLocal > 0
	|			THEN ReconciliationBalancesTurnover.CounterpartySDebtIsLocal - ReconciliationBalancesTurnover.OurDebtIsLocal
	|		ELSE 0
	|	END AS CounterpartySDebtIsLocal,
	|	ReconciliationBalancesTurnover.TurnoverIsOurDebtToLocal AS TurnoverIsOurDebtToLocal,
	|	ReconciliationBalancesTurnover.TurnoverDebtOfCounterpartyLocal AS TurnoverDebtOfCounterpartyLocal,
	|	ReconciliationBalancesTurnover.AccountsPayableOfCompany <> 0 OR ReconciliationBalancesTurnover.CounterpartySDebt <> 0 AS ThereIsExpandedBalance,
	|	ReconciliationBalancesTurnover.ThereAreRevolutions AS ThereAreRevolutions,
	|		
	|	CASE
	|		WHEN NOT ReconciliationBalancesTurnover.ThereIsReconciliationReport
	|				OR ISNULL(CalculationData.DateOfLastOperation, DATETIME(1,1,1))
	|					>= ReconciliationBalancesTurnover.MaximumReconciliationPeriod
	|			THEN &ReconciliationIsRequired
	|		WHEN ReconciliationBalancesTurnover.CreatedOn_ > 0
	|			THEN &CreatedOn_
	|		WHEN ReconciliationBalancesTurnover.CreatedOn_ = 0 
	|				AND ReconciliationBalancesTurnover.OnReconciliation > 0
	|			THEN &OnReconciliation
	|		WHEN ReconciliationBalancesTurnover.CreatedOn_ = 0 
	|				AND ReconciliationBalancesTurnover.OnReconciliation = 0
	|				AND ReconciliationBalancesTurnover.ReconciledWithDisputes > 0
	|				AND ReconciliationBalancesTurnover.MaximumReconciliationPeriod
	|					>= ISNULL(CalculationData.DateOfLastOperation, DATETIME(1,1,1))
	|				AND ReconciliationBalancesTurnover.DateVerifiedWithDisagreements > ReconciliationBalancesTurnover.DateIsVerifiedWithoutDisagreement
	|			THEN &ReconciledWithDisputes
	|		WHEN ReconciliationBalancesTurnover.CreatedOn_ = 0 
	|				AND ReconciliationBalancesTurnover.OnReconciliation = 0
	|				AND (ReconciliationBalancesTurnover.ReconciledWithDisputes = 0
	|					OR ReconciliationBalancesTurnover.DateIsVerifiedWithoutDisagreement >= ReconciliationBalancesTurnover.DateVerifiedWithDisagreements)
	|				AND ReconciliationBalancesTurnover.ReconciledWithoutDisputes > 0
	|				AND ReconciliationBalancesTurnover.MaximumReconciliationPeriod
	|					>= ISNULL(CalculationData.DateOfLastOperation, DATETIME(1,1,1))
	|			THEN &ReconciledWithoutDisputes
	|	END AS ReconciliationStatus,
	|	CASE
	|		WHEN ReconciliationBalancesTurnover.ThereIsReconciliationReport
	|				OR ISNULL(CalculationData.DateOfLastOperation, DATETIME(1,1,1))
	|					>= ReconciliationBalancesTurnover.MaximumReconciliationPeriod
	|			THEN 0
	|			ELSE 1
	|	END AS ThereIsReconciliationReport,
	|	ReconciliationBalancesTurnover.ThereAreDiscrepancies AS ThereAreDiscrepancies,
	|	ReconciliationBalancesTurnover.ThereAreDiscrepancies AS ThereAreDiscrepanciesInReconciliationDocument,
	|	ReconciliationBalancesTurnover.MaximumReconciliationPeriod AS MaximumReconciliationPeriod,
	|	
	|	
	|	ISNULL(ReconciliationServiceData.ThereAreDiscrepancies, FALSE) AS ReconciliationServiceThereAreDiscrepancies,
	|	
	|	ISNULL(CalculationData.DateOfLastOperation, DATETIME(1,1,1)) AS DateOfLastOperation,
	|	ISNULL(CalculationData.TotalDocuments, 0) AS TotalDocuments,
	|	ISNULL(CalculationData.NotExchangeIsCompleted_, 0) AS EDIExchangeHasNotBeenCompleted,
	|	CASE WHEN ISNULL(CalculationData.EDIParticipant, FALSE)
	|				AND ISNULL(CalculationData.NotExchangeIsCompleted_, 0) = 0
	|		THEN 2
	|		ELSE 1
	|	END AS ExchangeOfEDIStatusHasBeenCompleted,
	|	ISNULL(CalculationData.EDIParticipant, FALSE) AS EDIParticipant,
	|	
	|	ISNULL(ReconciliationServiceData.CompanyIsConnected, FALSE) AS ReconciliationServiceEnabledCompany,
	|	ISNULL(ReconciliationServiceData.CounterpartyIsConnected, FALSE) AS CounterpartyReconciliationServiceIsEnabled,
	|	
	|	ReconciliationBalancesTurnover.Manager AS Manager,
	|	ReconciliationBalancesTurnover.Organization AS Organization,
	|	ReconciliationBalancesTurnover.Manager_Name_ AS Manager_Name_,
	|	ReconciliationBalancesTurnover.CounterpartyName_ AS CounterpartyName_,
	|	ReconciliationBalancesTurnover.CodeTypeOfCalculations AS CodeCalculationTypeNumber,
	|	ReconciliationBalancesTurnover.Order AS Order,
	|	ISNULL(ReconciliationComments.Comment,&IsBlankString) AS Comment
	|FROM 
	|	TTBalancesTurnoverReconciliationDocuments AS ReconciliationBalancesTurnover
	|	LEFT JOIN TTCalculationsData AS CalculationData
	|		ON ReconciliationBalancesTurnover.Organization = CalculationData.Organization
	|		AND ReconciliationBalancesTurnover.Counterparty = CalculationData.Counterparty
	|		AND ReconciliationBalancesTurnover.Currency = CalculationData.Currency
	|	LEFT JOIN TTReconciliationServiceData AS ReconciliationServiceData
	|		ON ReconciliationBalancesTurnover.Organization = ReconciliationServiceData.Organization
	|		AND ReconciliationBalancesTurnover.Counterparty = ReconciliationServiceData.Counterparty
	|	LEFT JOIN InformationRegister.CommentsOnReconciliationOfSettlements AS ReconciliationComments
	|		ON ReconciliationBalancesTurnover.Organization = ReconciliationComments.Organization
	|		AND ReconciliationBalancesTurnover.Counterparty = ReconciliationComments.Counterparty";

	Return QueryText;
	
EndFunction

#EndRegion

#EndIf