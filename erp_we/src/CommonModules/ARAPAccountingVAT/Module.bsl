#Region Internal

// Creates a structure of parameters for the preparation of temporary tables with the calculations
// 
// Parameters:
//  InitialParameters - Undefined, Structure - custom structure with filled in values
// 
// Returns:
// 	Structure - LongDesc:
//   * StartDate                    - Date -
//   * EndDate                 - Date -
//   * Companies                   - Undefined, CatalogRef.Companies, Array of CatalogRef.Companies -
//   * ARAPDocument             - Undefined, DocumentRef - additional filter for the settlement document
//   * CreateEmptyTable          - Boolean - allows you to create a temporary table frame without data
//   * NewOnlineARAPAccounting - Boolean - mutual settlements "online" / " offline"
//   * EnableOrganizationSelection - Boolean - apply selection by organization
//   * ManualIndexFields           - Array of String - the ability to override the index field of the result
//   * TakeIntoAccountReservationOfAdvances   - Boolean - if "True", credited advances
//                                     that were previously reserved will not be included in the selection.
//   * SelectionParametersForSettlementDocument - Structure - For selection according to a temporary table with settlement documents, where:
//   	** FieldName - String - Name of the field that contains the document
//   	** SelectionTableName_ - String - name of the temporary table that contains the document
//   * AdvanceSelectionRule          - EnumRef.ProcedureOfRegisteringTaxInvoicesForPrepayment - the rule of selection of advances.
//
Function InitializeParametersForPreparationOfAdvancePayments(InitialParameters = Undefined) Export
	
	CalculationParameters_ = New Structure;
	
	DateEmpty = '00010101';
	
	CalculationParameters_.Insert("StartDate",           DateEmpty);
	CalculationParameters_.Insert("EndDate",        DateEmpty);
	CalculationParameters_.Insert("Companies",          Undefined);
	CalculationParameters_.Insert("ARAPDocument",    Undefined);
	CalculationParameters_.Insert("CreateEmptyTable", False);
	CalculationParameters_.Insert("NewOnlineARAPAccounting",
		GetFunctionalOption("NewOnlineARAPAccounting"));
	CalculationParameters_.Insert("EnableOrganizationSelection", False);
	
	// For selection according to a temporary table with settlement documents
	SelectionParametersForSettlementDocument = New Structure;
	SelectionParametersForSettlementDocument.Insert("FieldName",          "ARAPDocument");
	SelectionParametersForSettlementDocument.Insert("SelectionTableName_", "");
	
	CalculationParameters_.Insert("SelectionParametersForSettlementDocument", SelectionParametersForSettlementDocument);
	
	CalculationParameters_.Insert("ManualIndexFields",         New Array);
	CalculationParameters_.Insert("TakeIntoAccountReservationOfAdvances", False);
	CalculationParameters_.Insert("AdvanceSelectionRule", Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllPayments);
	
	FillInParameterProperties(CalculationParameters_, InitialParameters);
	
	Return CalculationParameters_;
	
EndFunction

#Region PrepaymentsFromCustomer

// Prepare a temporary table "calculationsclienta_avances"
// Creates a temporary table with columns:
// 	  Calculation document;
// 	  Document Recorder;
// 	  Organization;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Directions of activity;
// 	  Counterparty;
// 	  Contract;
// 	  Datavance;
// 	  Document currency;
// 	  SummaAvancaVal - the amount in the document currency;
// 	  SummaAvance;
// 	  SummaAvansaUpr;
// 	  SummaAvansaRegl.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_SettlementsWithCustomers_Advances(TempTablesManager, CalculationParameters) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	SetRequestParametersForPreparationOfAdvancePayments(Query, CalculationParameters);
	
	Query.Text =
	"// New settlement architecture 
	|	SELECT
	|	Calculations.ARAPDocument AS ARAPDocument,
	|	Calculations.DocumentRecorder AS DocumentRecorder,
	|	Calculations.ARAPObject.Organization AS Organization,
	|	Calculations.ARAPObject.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	MIN(Calculations.OccurrenceDate) AS AdvanceDate,
	|	FALSE AS SettlementOfARAP
	|INTO SelectionOfAdvances
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|WHERE
	|	&NewOnlineARAPAccounting
	|	AND NOT &CreateEmptyTable
	|	AND Calculations.Period BETWEEN &StartDate AND &EndDate
	|	AND (NOT &EnableOrganizationSelection
	|			OR Calculations.ARAPObject.Organization IN (&Companies))
	|	AND &TextSelectionByParameters
	|	AND Calculations.OccurrenceDate BETWEEN &StartDate AND &EndDate
	|	AND Calculations.Active = TRUE
	|	AND CASE
	|		WHEN CAST(Calculations.DocumentRecorder AS Document.ARAPSettlement).OperationKind IN (&TypesOfOperationsOfAdvanceTransfer)
	|			THEN Calculations.DocumentRecorder = Calculations.ARAPDocument
	|		ELSE TRUE
	|	END
	|
	|GROUP BY
	|	Calculations.ARAPDocument,
	|	Calculations.DocumentRecorder,
	|	Calculations.ARAPObject.Organization,
	|	Calculations.ARAPObject.Organization.LocalAccountingCurrency
	|
	|HAVING
	|	SUM(Calculations.Prepayment * CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -1
	|			ELSE 1
	|		END * CASE
	|		WHEN Calculations.ReversingEntry
	|			THEN -1
	|			ELSE 1
	|		END) > 0
	|
	|UNION ALL
	|
	|	SELECT
	|	NestedQuery.ARAPDocument AS ARAPDocument,
	|	NestedQuery.DocumentRecorder AS DocumentRecorder,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	MIN(NestedQuery.OccurrenceDate) AS AdvanceDate,
	|	TRUE AS SettlementOfARAP
	|FROM
	|	(SELECT
	|		Calculations.ARAPDocument AS ARAPDocument,
	|		Calculations.DocumentRecorder AS DocumentRecorder,
	|		Calculations.ARAPObject.Organization AS Organization,
	|		Calculations.ARAPObject.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|		MIN(Calculations.OccurrenceDate) AS OccurrenceDate
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|			LEFT JOIN Document.ARAPSettlement AS DocumentSettlementOfARAP
	|			ON Calculations.DocumentRecorder = DocumentSettlementOfARAP.Ref
	|			LEFT JOIN Document.ReversingEntry AS DocumentReversingEntry
	|			ON Calculations.DocumentRecorder = DocumentReversingEntry.Ref
	|	WHERE
	|		&NewOnlineARAPAccounting
	|		AND NOT &CreateEmptyTable
	|		AND Calculations.Period BETWEEN &StartDate AND &EndDate
	|		AND (NOT &EnableOrganizationSelection
	|				OR Calculations.ARAPObject.Organization IN (&Companies))
	|		AND (NOT &EnableSelectionBasedOnSettlementDocument
	|				OR Calculations.ARAPDocument IN (&ARAPDocument))
	|		AND CASE WHEN NOT DocumentSettlementOfARAP.Ref IS NULL
	|			THEN DocumentSettlementOfARAP.OperationKind IN (&TypesOfOperationsOfAdvanceTransfer)
	|			WHEN NOT DocumentReversingEntry.Ref IS NULL
	|			THEN CAST(DocumentReversingEntry.ReversedDocument AS Document.ARAPSettlement).OperationKind IN (&TypesOfOperationsOfAdvanceTransfer)
	|		END
	|		AND Calculations.OccurrenceDate BETWEEN &StartDate AND &EndDate
	|		AND Calculations.Active = TRUE
	|		AND Calculations.DocumentRecorder <> Calculations.ARAPDocument
	|		AND CASE
	|				WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllExceptSettledDuringDay)
	|					THEN DATEDIFF(Calculations.OccurrenceDate, Calculations.Period, DAY) < 1
	|				WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffWithinFiveCalendarDays)
	|					THEN DATEDIFF(Calculations.OccurrenceDate, Calculations.Period, DAY) < 5
	|				WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeMonthEnd)
	|					THEN Calculations.Period <= ENDOFPERIOD(Calculations.OccurrenceDate, MONTH)
	|				WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeQuarterEnd)
	|					THEN Calculations.Period <= ENDOFPERIOD(Calculations.OccurrenceDate, QUARTER)
	|				ELSE TRUE
	|			END
	|	
	|	GROUP BY
	|		Calculations.ARAPDocument,
	|		Calculations.DocumentRecorder,
	|		Calculations.ARAPObject,
	|		Calculations.ARAPObject.Organization,
	|		Calculations.ARAPObject.Organization.LocalAccountingCurrency
	|	
	|	HAVING
	|		SUM(Calculations.Prepayment * CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -1
	|			ELSE 1
	|		END * CASE
	|		WHEN Calculations.ReversingEntry
	|			THEN -1
	|			ELSE 1
	|		END) > 0) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.ARAPDocument,
	|	NestedQuery.DocumentRecorder,
	|	NestedQuery.Organization,
	|	NestedQuery.LocalAccountingCurrency
	|
	|UNION ALL
	|
	|// The old architecture of mutual settlements
	|SELECT
	|	Calculations.ARAPDocument,
	|	Calculations.Recorder,
	|	Calculations.AccountingDimensionByPartners.Organization,
	|	Calculations.AccountingDimensionByPartners.Organization.LocalAccountingCurrency,
	|	NULL,
	|	FALSE
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|WHERE
	|	NOT &NewOnlineARAPAccounting
	|	AND NOT &CreateEmptyTable
	|	AND Calculations.Period BETWEEN &StartDate AND &EndDate
	|	AND (NOT &EnableOrganizationSelection
	|			OR Calculations.AccountingDimensionByPartners.Organization IN (&Companies))
	|	AND &TextSelectionByParameters
	|	AND Calculations.Active = TRUE
	|	AND (Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND Calculations.PrepaymentLocal > 0
	|			OR Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND Calculations.PrepaymentLocal < 0)
	|
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners.Organization,
	|	Calculations.AccountingDimensionByPartners.Organization.LocalAccountingCurrency,
	|	Calculations.Recorder,
	|	Calculations.ARAPDocument
	|
	|HAVING
	|	SUM(CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Calculations.PrepaymentLocal
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Calculations.PrepaymentLocal
	|		END) > 0
	|
	|INDEX BY
	|	DocumentRecorder,
	|	ARAPDocument,
	|	Organization
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculations.ARAPDocument AS ARAPDocument,
	|	Calculations.DocumentRecorder AS DocumentRecorder,
	|	Calculations.ARAPObject.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	Calculations.ARAPObject.Counterparty AS Counterparty,
	|	Calculations.ARAPObject.Contract AS Contract,
	|	Calculations.ReversingEntry AS ReversingEntry,
	|	MIN(SelectionOfAdvances.AdvanceDate) AS AdvanceDate,
	|	MAX(CASE
	|				WHEN Calculations.ARAPDocument REFS Document.CashAccountReceiptNote
	|					THEN CAST(Calculations.ARAPDocument AS Document.CashAccountReceiptNote).Currency
	|				WHEN Calculations.ARAPDocument REFS Document.BankAccountReceiptNote
	|					THEN CAST(Calculations.ARAPDocument AS Document.BankAccountReceiptNote).Currency
	|				WHEN Calculations.ARAPDocument REFS Document.SourceDocument
	|					THEN CAST(Calculations.ARAPDocument AS Document.SourceDocument).Currency
	|				ELSE Calculations.Currency
	|		END) AS DocumentCurrency,
	|	SUM(CASE
	|			WHEN Calculations.ARAPDocument REFS Document.CashAccountReceiptNote
	|					AND CAST(Calculations.ARAPDocument AS Document.CashAccountReceiptNote).Currency = SelectionOfAdvances.LocalAccountingCurrency
	|				THEN Calculations.PrepaymentLocal
	|			WHEN Calculations.ARAPDocument REFS Document.BankAccountReceiptNote
	|					AND CAST(Calculations.ARAPDocument AS Document.BankAccountReceiptNote).Currency = SelectionOfAdvances.LocalAccountingCurrency
	|				THEN Calculations.PrepaymentLocal
	|			ELSE
	|				Calculations.Prepayment
	|		END
	|		* CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AdvanceAmountVal,
	|	SUM(Calculations.Prepayment * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AdvanceAmount,
	|	SUM(Calculations.PrepaymentMan * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AdvanceAmountOfMan,
	|	SUM(Calculations.PrepaymentLocal * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AmountOfSchedAdvance
	|INTO SettlementsWithClients_Advances_Preliminary
	|FROM
	|	SelectionOfAdvances AS SelectionOfAdvances
	|
	|	INNER JOIN 
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|	ON
	|		SelectionOfAdvances.DocumentRecorder    = Calculations.DocumentRecorder
	|		AND  SelectionOfAdvances.ARAPDocument   = Calculations.ARAPDocument
	|		AND  SelectionOfAdvances.Organization         = Calculations.ARAPObject.Organization
	|		AND  Calculations.Period BETWEEN &StartDate AND &EndDate
	|		AND  Calculations.OccurrenceDate BETWEEN &StartDate AND &EndDate
	|		AND  Calculations.Active  = TRUE
	|		AND  &NewOnlineARAPAccounting
	|
	|GROUP BY
	|	Calculations.ARAPDocument,
	|	Calculations.DocumentRecorder,
	|	Calculations.ARAPObject.Organization,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.ReversingEntry
	|
	|HAVING
	|	SUM(Calculations.Prepayment * CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -1
	|			ELSE 1
	|		END * CASE
	|		WHEN Calculations.ReversingEntry
	|			THEN -1
	|			ELSE 1
	|		END) > 0
	|
	|UNION ALL
	|
	|// The old architecture of mutual settlements
	|SELECT
	|	Calculations.ARAPDocument AS ARAPDocument,
	|	Calculations.Recorder AS DocumentRecorder,
	|	Calculations.AccountingDimensionByPartners.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.SalesOrder AS ARAPObject,
	|	Calculations.SalesOrder.LineOfBusiness AS LineOfBusiness,
	|	Calculations.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	Calculations.AccountingDimensionByPartners.Contract AS Contract, 
	|	FALSE AS ReversingEntry,
	|	MIN(BEGINOFPERIOD(Calculations.Period, DAY)) AS AdvanceDate,
	|	MAX(CASE
	|		WHEN Calculations.ARAPDocument REFS Document.CashAccountReceiptNote
	|			THEN CAST(Calculations.ARAPDocument AS Document.CashAccountReceiptNote).Currency
	|		WHEN Calculations.ARAPDocument REFS Document.BankAccountReceiptNote
	|			THEN CAST(Calculations.ARAPDocument AS Document.BankAccountReceiptNote).Currency
	|		WHEN Calculations.ARAPDocument REFS Document.SourceDocument
	|			THEN CAST(Calculations.ARAPDocument AS Document.SourceDocument).Currency
	|		ELSE Calculations.Currency
	|	END) AS DocumentCurrency,
	|	SUM(CASE
	|			WHEN Calculations.ARAPDocument REFS Document.CashAccountReceiptNote
	|					AND CAST(Calculations.ARAPDocument AS Document.CashAccountReceiptNote).Currency = SelectionOfAdvances.LocalAccountingCurrency
	|				THEN Calculations.PrepaymentLocal
	|			WHEN Calculations.ARAPDocument REFS Document.BankAccountReceiptNote
	|					AND CAST(Calculations.ARAPDocument AS Document.BankAccountReceiptNote).Currency = SelectionOfAdvances.LocalAccountingCurrency
	|				THEN Calculations.PrepaymentLocal
	|			ELSE
	|				Calculations.Prepayment
	|		END
	|		* CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN 1
	|			ELSE -1
	|		END) AS AdvanceAmountVal,
	|	SUM(CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Calculations.Prepayment
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Calculations.Prepayment
	|		END) AS AdvanceAmount,
	|	SUM(CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Calculations.PrepaymentMan
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Calculations.PrepaymentMan
	|		END) AS AdvanceAmountOfMan,
	|	SUM(CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Calculations.PrepaymentLocal
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Calculations.PrepaymentLocal
	|		END) AS AmountOfSchedAdvance
	|FROM
	|	SelectionOfAdvances AS SelectionOfAdvances
	|
	|	INNER JOIN 
	|		AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|	ON
	|		SelectionOfAdvances.DocumentRecorder    = Calculations.Recorder
	|		AND  SelectionOfAdvances.ARAPDocument   = Calculations.ARAPDocument
	|		AND  SelectionOfAdvances.Organization         = Calculations.AccountingDimensionByPartners.Organization
	|		AND  Calculations.Period BETWEEN &StartDate AND &EndDate
	|		AND  Calculations.Active  = TRUE
	|		AND  NOT &NewOnlineARAPAccounting
	|
	|GROUP BY
	|	Calculations.ARAPDocument,
	|	Calculations.Recorder,
	|	Calculations.AccountingDimensionByPartners.Organization,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.SalesOrder,
	|	Calculations.SalesOrder.LineOfBusiness,
	|	Calculations.AccountingDimensionByPartners.Counterparty
	|
	|HAVING
	|	SUM(CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Calculations.Prepayment
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Calculations.Prepayment
	|		END) > 0
	|
	|INDEX BY
	|	ARAPDocument
	|;
	|
	|SELECT
	|	Calculations.ARAPDocument AS ARAPDocument,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	MIN(SelectionOfAdvances.AdvanceDate) AS AdvanceDate,
	|	MAX(CASE
	|			WHEN Calculations.ARAPDocument REFS Document.CashAccountReceiptNote
	|				THEN CAST(Calculations.ARAPDocument AS Document.CashAccountReceiptNote).Currency
	|			WHEN Calculations.ARAPDocument REFS Document.BankAccountReceiptNote
	|				THEN CAST(Calculations.ARAPDocument AS Document.BankAccountReceiptNote).Currency
	|			WHEN Calculations.ARAPDocument REFS Document.SourceDocument
	|				THEN CAST(Calculations.ARAPDocument AS Document.SourceDocument).Currency
	|			ELSE Calculations.Currency
	|		END) AS DocumentCurrency,
	|	SUM(CASE
	|			WHEN Calculations.ARAPDocument REFS Document.CashAccountReceiptNote
	|					AND CAST(Calculations.ARAPDocument AS Document.CashAccountReceiptNote).Currency = SelectionOfAdvances.LocalAccountingCurrency
	|				THEN Calculations.PrepaymentLocal
	|			WHEN Calculations.ARAPDocument REFS Document.BankAccountReceiptNote
	|					AND CAST(Calculations.ARAPDocument AS Document.BankAccountReceiptNote).Currency = SelectionOfAdvances.LocalAccountingCurrency
	|				THEN Calculations.PrepaymentLocal
	|			ELSE Calculations.Prepayment
	|		END * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AdvanceAmountVal,
	|	SUM(Calculations.Prepayment * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AdvanceAmount,
	|	SUM(Calculations.PrepaymentMan * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AdvanceAmountOfMan,
	|	SUM(Calculations.PrepaymentLocal * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AmountOfSchedAdvance
	|INTO SettlementOfPrepayment
	|
	|FROM
	|	SelectionOfAdvances AS SelectionOfAdvances
	|		INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|		ON (SelectionOfAdvances.DocumentRecorder = Calculations.DocumentRecorder)
	|			AND (SelectionOfAdvances.ARAPDocument = Calculations.ARAPDocument)
	|			AND (SelectionOfAdvances.Organization = Calculations.ARAPObject.Organization)
	|			AND (Calculations.Period BETWEEN &StartDate AND &EndDate)
	|			AND (Calculations.OccurrenceDate BETWEEN &StartDate AND &EndDate)
	|			AND (Calculations.Active = TRUE)
	|			AND (Calculations.RecordType = VALUE(AccumulationRecordType.Expense))
	|		INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations_Receipt
	|		ON (SelectionOfAdvances.DocumentRecorder = Calculations_Receipt.DocumentRecorder)
	|			AND (SelectionOfAdvances.ARAPDocument = Calculations_Receipt.ARAPDocument)
	|			AND (SelectionOfAdvances.Organization = Calculations_Receipt.ARAPObject.Organization)
	|			AND (Calculations_Receipt.Period BETWEEN &StartDate AND &EndDate)
	|			AND (Calculations_Receipt.OccurrenceDate BETWEEN &StartDate AND &EndDate)
	|			AND (Calculations_Receipt.Active = TRUE)
	|			AND (Calculations_Receipt.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND (Calculations_Receipt.ARAPObject = Calculations.CalculationObjectReceiver)
	|			AND (Calculations_Receipt.AccountingDimensionByPartners = Calculations.DestinationAccountingDimensionByPartners))
	|			
	|WHERE
	|	SelectionOfAdvances.SettlementOfARAP = TRUE
	|
	|GROUP BY
	|	Calculations.ARAPDocument,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject
	|
	|INDEX BY
	|	ARAPDocument,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	AdvanceDate,
	|	DocumentCurrency
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculations.ARAPDocument AS ARAPDocument,
	|	Calculations.DocumentRecorder AS DocumentRecorder,
	|	Calculations.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.LineOfBusiness AS LineOfBusiness,
	|	Calculations.Counterparty AS Counterparty,
	|	Calculations.Contract AS Contract,
	|	Calculations.AdvanceDate AS AdvanceDate,
	|	Calculations.DocumentCurrency AS DocumentCurrency,
	|	Calculations.AdvanceAmountVal + ISNULL(SettlementOfPrepayment.AdvanceAmountVal,0) AS AdvanceAmountVal,
	|	Calculations.AdvanceAmount + ISNULL(SettlementOfPrepayment.AdvanceAmount,0) AS AdvanceAmount,
	|	Calculations.AdvanceAmountOfMan + ISNULL(SettlementOfPrepayment.AdvanceAmountOfMan,0) AS AdvanceAmountOfMan,
	|	Calculations.AmountOfSchedAdvance + ISNULL(SettlementOfPrepayment.AmountOfSchedAdvance,0) AS AmountOfSchedAdvance
	|INTO SettlementsWithCustomers_Advances
	|FROM
	|	SettlementsWithClients_Advances_Preliminary AS Calculations
	|
	|	LEFT JOIN 
	|		SettlementOfPrepayment AS SettlementOfPrepayment
	|	ON
	|		Calculations.ARAPDocument = SettlementOfPrepayment.ARAPDocument
	|		AND Calculations.AccountingDimensionByPartners = SettlementOfPrepayment.AccountingDimensionByPartners
	|		AND Calculations.ARAPObject = SettlementOfPrepayment.ARAPObject
	|		AND Calculations.AdvanceDate = SettlementOfPrepayment.AdvanceDate
	|		AND Calculations.DocumentCurrency = SettlementOfPrepayment.DocumentCurrency
	|;
	|
	|DROP SelectionOfAdvances
	|
	|;
	|
	|DROP SettlementsWithClients_Advances_Preliminary
	|
	|;
	|
	|DROP SettlementOfPrepayment
	|";
	
	SetIndexFields(Query, CalculationParameters, "SettlementsWithCustomers_Advances");
	
	PathParameters = InitializeParametersForSelectingAdvances_FieldPathsAndReplacementText();
	ProcessRequestTextForSelectingAdvancesBasedOnParameters(Query, CalculationParameters, PathParameters);
	
	Query.Execute();
	
EndProcedure

// Prepare a temporary table "Calculation by clients_Repayment of balances"
// Creates a temporary table with columns:
// 	  Calculation document;
// 	  Organization;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Document Recorder;
// 	  Counterparty;
// 	  Contract;
// 	  Directions of activity;
// 	  Iscontragent - the counterparty for which the advance arose;
// 	  IshDogovor - Contract Under Which there Was an advance;
// 	  From the direction of activity - the direction in which the advance arose;
// 	  Coralitikauchetapopartners;
// 	  Initial analyticsaccounts to partners - analytics for which an advance was formed;
// 	  Account Object Box;
// 	  Initial account objectobject - the settlement object for which the advance payment was generated;
// 	  Datavance;
// 	  Data settlement;
// 	  EVENTSNAK - If the repayment occurred due to the offset of the advance, then EVENTSNAK >= 0,
// 	                If the repayment occurred due to the repayment/write-off of debt, then EVENTSNAK < 0;
// 	  Type of event - the event in connection with which the advance payment occurred. Possible events:
// 	         - Enumeration.Economic operations.Write-offs of loan indebtedness,
// 	         - Enumeration.Economic operations.Return payment to the client,
// 	         - Enumeration.Economic operations.Offsetting the client;
// 	  Document currency;
// 	  Repayment totals;
// 	  Repayment Amount - the amount in the document currency;
// 	  The sum of the repayment of the;
// 	  The sum of the cancellation rules.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_SettlementsWithCustomers_RepaymentOfAdvances(TempTablesManager, CalculationParameters) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	SetRequestParametersForPreparationOfAdvancePayments(Query, CalculationParameters);
	
	Query.Text =
	"// New settlement architecture
	|SELECT
	|	Calculations.ARAPDocument AS ARAPDocument,
	|	Calculations.DocumentRecorder AS DocumentRecorder,
	|	Calculations.ARAPObject.Organization AS Organization,
	|	Calculations.ARAPObject.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	MIN(Calculations.OccurrenceDate) AS AdvanceDate,
	|	MAX(Calculations.Period) AS MaturityDate,
	|	SUM(CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 0
	|			WHEN Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|				THEN CASE
	|						WHEN VALUETYPE(Calculations.DocumentRecorder) IN (&TypesOfReturnDocuments_AdvancesReceived)
	|							THEN -Calculations.Prepayment
	|						ELSE 0
	|					END
	|			WHEN Calculations.BusinessOperation IN (VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement),
	|												VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment),
	|												VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno))
	|				THEN Calculations.Prepayment
	|			ELSE -Calculations.Prepayment
	|		END) AS EventSign,
	|	SUM(Calculations.Prepayment * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS RepaymentAmount,
	|	NOT ARAPSettlementTransfer.Ref IS NULL AS SettlementOfPrepayment
	|	
	|INTO SelectionOfAdvanceRepayments
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|		LEFT JOIN Document.ARAPSettlement AS ARAPSettlementTransfer
	|		ON (Calculations.DocumentRecorder = ARAPSettlementTransfer.Ref)
	|			AND (ARAPSettlementTransfer.OperationKind IN (&TypesOfOperationsOfAdvanceTransfer))
	|		LEFT JOIN Document.ARAPSettlement AS ARAPSettlement
	|		ON (Calculations.DocumentRecorder = ARAPSettlement.Ref)
	|
	|WHERE
	|	&NewOnlineARAPAccounting
	|	AND NOT &CreateEmptyTable
	|	AND (NOT &EnableOrganizationSelection
	|			OR Calculations.ARAPObject.Organization IN (&Companies))
	|	AND &TextSelectionByParameters
	|	AND Calculations.Period BETWEEN &StartDate AND &EndDate
	|	AND Calculations.Active = TRUE
	|	AND Calculations.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment)
	|	AND CASE
	|			WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllExceptSettledDuringDay)
	|				THEN DATEDIFF(Calculations.OccurrenceDate, Calculations.Period, DAY) < 1
	|			WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffWithinFiveCalendarDays)
	|				THEN DATEDIFF(Calculations.OccurrenceDate, Calculations.Period, DAY) < 5
	|			WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeMonthEnd)
	|				THEN Calculations.Period <= ENDOFPERIOD(Calculations.OccurrenceDate, MONTH)
	|			WHEN &AdvanceSelectionRule = VALUE(Enum.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeQuarterEnd)
	|				THEN Calculations.Period <= ENDOFPERIOD(Calculations.OccurrenceDate, QUARTER)
	|			ELSE TRUE
	|		END
	|	AND CASE WHEN NOT ARAPSettlement.Ref IS NULL AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN ARAPSettlement.OperationKind IN (&TypesOfOperationsOfAdvanceTransfer)
	|		ELSE TRUE
	|	END
	|		
	|	GROUP BY
	|		Calculations.ARAPDocument,
	|		Calculations.DocumentRecorder,
	|		Calculations.ARAPObject.Organization,
	|		Calculations.ARAPObject.Organization.LocalAccountingCurrency,
	|		NOT ARAPSettlementTransfer.Ref IS NULL
	|	
	|	HAVING
	|		SUM(Calculations.Prepayment * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|			END * CASE
	|				WHEN Calculations.ReversingEntry
	|					THEN -1
	|				ELSE 1
	|				END) > 0
	|
	|UNION ALL
	|
	|//The old architecture of mutual settlements
	|SELECT
	|	Calculations.ARAPDocument AS ARAPDocument,
	|	Calculations.Recorder AS DocumentRecorder,
	|	Calculations.AccountingDimensionByPartners.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	NULL AS AdvanceDate,
	|	Calculations.Period AS MaturityDate,
	|	SUM(CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					AND Calculations.PrepaymentLocal > 0
	|				THEN Calculations.PrepaymentLocal
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND Calculations.PrepaymentLocal < 0
	|				THEN Calculations.PrepaymentLocal
	|			ELSE 0
	|		END) AS EventSign,
	|	SUM(Calculations.Prepayment * CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN 1
	|		ELSE -1
	|		END) AS RepaymentAmount,
	|	FALSE AS SettlementOfPrepayment
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|WHERE
	|	NOT &NewOnlineARAPAccounting
	|	AND NOT &CreateEmptyTable
	|	AND (NOT &EnableOrganizationSelection
	|			OR Calculations.AccountingDimensionByPartners.Organization IN (&Companies))
	|	AND &TextSelectionByParameters
	|	AND Calculations.Period BETWEEN &StartDate AND &EndDate
	|	AND Calculations.Active = TRUE
	|
	|GROUP BY
	|	Calculations.ARAPDocument,
	|	Calculations.Recorder,
	|	Calculations.AccountingDimensionByPartners.Organization,
	|	Calculations.AccountingDimensionByPartners.Organization.LocalAccountingCurrency,
	|	Calculations.Period
	|
	|HAVING
	|	SUM(Calculations.PrepaymentLocal * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|			ELSE -1
	|		END) > 0
	|
	|INDEX BY
	|	ARAPDocument,
	|	DocumentRecorder,
	|	Organization,
	|	LocalAccountingCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculations_Receipt.ARAPDocument AS ARAPDocument,
	|	Calculations.ARAPObject.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.DocumentRecorder AS DocumentRecorder,
	|	Calculations.ARAPObject.Counterparty AS Counterparty,
	|	Calculations.ARAPObject.Contract AS Contract,
	|	Calculations.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN NOT Calculations.CorARAPObject = &EmptyCalculationObject
	|				AND NOT ISNULL(Calculations.CorARAPObject.Object = UNDEFINED, TRUE)
	|			THEN Calculations.CorARAPObject.Counterparty
	|		ELSE Calculations.ARAPObject.Counterparty
	|	END AS ExCounterparty,
	|	CASE
	|		WHEN NOT Calculations.CorARAPObject = &EmptyCalculationObject
	|				AND NOT ISNULL(Calculations.CorARAPObject.Object = UNDEFINED, TRUE)
	|			THEN Calculations.CorARAPObject.Contract
	|		ELSE Calculations.ARAPObject.Contract
	|	END AS Exodus,
	|	CASE
	|		WHEN NOT Calculations.CorARAPObject = &EmptyCalculationObject
	|				AND NOT ISNULL(Calculations.CorARAPObject.Object = UNDEFINED, TRUE)
	|			THEN Calculations.CorARAPObject.LineOfBusiness
	|		ELSE Calculations.ARAPObject.LineOfBusiness
	|	END AS ExhDirectionOfActivity,
	|	Calculations.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	CASE
	|		WHEN Calculations.CorPartnerAccountingDimension <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|			THEN Calculations.CorPartnerAccountingDimension
	|		ELSE Calculations.AccountingDimensionByPartners
	|	END AS ExAnalyticsOfACCOUNTINGByPartners,
	|	Calculations.CorARAPObject AS CorARAPObject,
	|	CASE
	|		WHEN NOT Calculations.CorARAPObject = &EmptyCalculationObject
	|				AND NOT ISNULL(Calculations.CorARAPObject.Object = UNDEFINED, TRUE)
	|			THEN Calculations.CorARAPObject
	|		ELSE Calculations.ARAPObject
	|	END AS SourceObjectOfCalculations_,
	|	SelectionOfAdvanceRepayments.AdvanceDate AS AdvanceDate,
	|	SelectionOfAdvanceRepayments.MaturityDate AS MaturityDate,
	|	SelectionOfAdvanceRepayments.EventSign AS EventSign,
	|	CASE
	|		WHEN Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.APWriteOff)
	|			THEN VALUE(Enum.BusinessTransactions.APWriteOff)
	|		WHEN Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|			THEN VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|		WHEN Calculations.BusinessOperation IN (VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement),
	|												VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno))
	|			THEN VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)
	|		WHEN SelectionOfAdvanceRepayments.EventSign < 0
	|			THEN VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|		ELSE UNDEFINED
	|	END AS EventKind,
	|	CASE
	|		WHEN Calculations_Receipt.ARAPDocument REFS Document.CashAccountReceiptNote
	|			THEN CAST(Calculations_Receipt.ARAPDocument AS Document.CashAccountReceiptNote).Currency
	|		WHEN Calculations_Receipt.ARAPDocument REFS Document.BankAccountReceiptNote
	|			THEN CAST(Calculations_Receipt.ARAPDocument AS Document.BankAccountReceiptNote).Currency
	|		WHEN Calculations_Receipt.ARAPDocument REFS Document.SourceDocument
	|			THEN CAST(Calculations_Receipt.ARAPDocument AS Document.SourceDocument).Currency
	|		ELSE Calculations_Receipt.Currency
	|	END AS DocumentCurrency,
	|	CASE
	|		WHEN Calculations_Receipt.ARAPDocument REFS Document.CashAccountReceiptNote
	|				AND CAST(Calculations_Receipt.ARAPDocument AS Document.CashAccountReceiptNote).Currency = SelectionOfAdvanceRepayments.LocalAccountingCurrency
	|			THEN Calculations.DebtLocal
	|		WHEN Calculations_Receipt.ARAPDocument REFS Document.BankAccountReceiptNote
	|				AND CAST(Calculations_Receipt.ARAPDocument AS Document.BankAccountReceiptNote).Currency = SelectionOfAdvanceRepayments.LocalAccountingCurrency
	|			THEN Calculations.DebtLocal
	|		ELSE Calculations.Debt
	|	END AS DebtShaft,
	|	Calculations.Debt AS Debt,
	|	Calculations.ARAPMan AS ARAPMan,
	|	Calculations.DebtLocal AS DebtLocal
	|INTO SettlementsWithClients_RepaymentsWithImplicitOffset
	|FROM
	|	SelectionOfAdvanceRepayments AS SelectionOfAdvanceRepayments
	|		INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|		ON SelectionOfAdvanceRepayments.DocumentRecorder = Calculations.DocumentRecorder
	|			AND SelectionOfAdvanceRepayments.Organization = Calculations.ARAPObject.Organization
	|			AND (Calculations.RecordType = VALUE(AccumulationRecordType.Expense))
	|			AND (Calculations.Period BETWEEN &StartDate AND &EndDate)
	|			AND (Calculations.Active = TRUE)
	|			AND (Calculations.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment))
	|			AND (NOT Calculations.ReversingEntry)
	|			AND (Calculations.Debt > 0)
	|			AND (SelectionOfAdvanceRepayments.SettlementOfPrepayment)
	|		INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations_Receipt
	|		ON (Calculations_Receipt.RecordType = VALUE(AccumulationRecordType.Receipt))
	|			AND SelectionOfAdvanceRepayments.ARAPDocument = Calculations_Receipt.ARAPDocument
	|			AND (Calculations.ARAPObject = Calculations_Receipt.ARAPObject)
	|			AND (Calculations.AccountingDimensionByPartners = Calculations_Receipt.AccountingDimensionByPartners)
	|			AND (Calculations.DocumentRecorder = Calculations_Receipt.DocumentRecorder) 
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPDocument,
	|	DocumentCurrency
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|// New settlement architecture
	|SELECT
	|	NestedQuery.ARAPDocument AS ARAPDocument,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.DocumentRecorder AS DocumentRecorder,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Contract AS Contract,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.ReversingEntry AS ReversingEntry,
	|	MAX(NestedQuery.ExCounterparty) AS ExCounterparty,
	|	MAX(NestedQuery.Exodus) AS Exodus,
	|	MAX(NestedQuery.ExhDirectionOfActivity) AS ExhDirectionOfActivity,
	|	MAX(NestedQuery.CorPartnerAccountingDimension) AS CorPartnerAccountingDimension,
	|	MAX(NestedQuery.InitialAccountingAnalyticsForPartners) AS InitialAccountingAnalyticsForPartners,
	|	MAX(NestedQuery.CorARAPObject) AS CorARAPObject,
	|	MAX(NestedQuery.SourceObjectOfCalculations_) AS SourceObjectOfCalculations_,
	|	MIN(NestedQuery.AdvanceDate) AS AdvanceDate,
	|	MAX(NestedQuery.MaturityDate) AS MaturityDate,
	|	MAX(NestedQuery.EventSign) AS EventSign,
	|	MAX(NestedQuery.EventKind) AS EventKind,
	|	MAX(NestedQuery.DocumentCurrency) AS DocumentCurrency,
	|	SUM(NestedQuery.RepaymentAmountVal) AS RepaymentAmountVal,
	|	SUM(NestedQuery.RepaymentAmount) AS RepaymentAmount,
	|	SUM(NestedQuery.ManRepaymentAmount) AS ManRepaymentAmount,
	|	SUM(NestedQuery.LocalRepaymentAmount) AS LocalRepaymentAmount
	|INTO SettlementsWithCustomers_RepaymentOfAdvances_Preliminary
	|FROM
	|	(SELECT
	|		NestedQuery.ARAPDocument AS ARAPDocument,
	|		NestedQuery.ARAPObject.Organization AS Organization,
	|		NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		NestedQuery.ARAPObject AS ARAPObject,
	|		NestedQuery.DocumentRecorder AS DocumentRecorder,
	|		NestedQuery.ARAPObject.Counterparty AS Counterparty,
	|		NestedQuery.ARAPObject.Contract AS Contract,
	|		NestedQuery.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|		NestedQuery.ReversingEntry AS ReversingEntry,
	|		MAX(CASE
	|			WHEN NOT NestedQuery.CorARAPObject = &EmptyCalculationObject
	|					AND NOT ISNULL(NestedQuery.CorARAPObject.Object = UNDEFINED, TRUE)
	|				THEN NestedQuery.CorARAPObject.Counterparty
	|			ELSE NestedQuery.ARAPObject.Counterparty
	|		END) AS ExCounterparty,
	|		MAX(CASE
	|			WHEN NOT NestedQuery.CorARAPObject = &EmptyCalculationObject
	|					AND NOT ISNULL(NestedQuery.CorARAPObject.Object = UNDEFINED, TRUE)
	|				THEN NestedQuery.CorARAPObject.Contract
	|			ELSE NestedQuery.ARAPObject.Contract
	|		END) AS Exodus,
	|		MAX(CASE
	|			WHEN NOT NestedQuery.CorARAPObject = &EmptyCalculationObject
	|					AND NOT ISNULL(NestedQuery.CorARAPObject.Object = UNDEFINED, TRUE)
	|				THEN NestedQuery.CorARAPObject.LineOfBusiness
	|			ELSE NestedQuery.ARAPObject.LineOfBusiness
	|		END) AS ExhDirectionOfActivity,
	|		MAX(NestedQuery.CorPartnerAccountingDimension) AS CorPartnerAccountingDimension,
	|		CASE
	|		WHEN NestedQuery.CorPartnerAccountingDimension <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|			THEN NestedQuery.CorPartnerAccountingDimension
	|		ELSE NestedQuery.AccountingDimensionByPartners
	|		END AS InitialAccountingAnalyticsForPartners,
	|		MAX(NestedQuery.CorARAPObject) AS CorARAPObject,
	|		MAX(CASE
	|			WHEN NOT NestedQuery.CorARAPObject = &EmptyCalculationObject
	|					AND NOT ISNULL(NestedQuery.CorARAPObject.Object = UNDEFINED, TRUE)
	|				THEN NestedQuery.CorARAPObject
	|			ELSE NestedQuery.ARAPObject
	|		END) AS SourceObjectOfCalculations_,
	|		MIN(NestedQuery.AdvanceDate) AS AdvanceDate,
	|		MAX(NestedQuery.MaturityDate) AS MaturityDate,
	|		MAX(NestedQuery.EventSign) AS EventSign,
	|		MAX(NestedQuery.EventKind) AS EventKind,
	|		MAX(NestedQuery.DocumentCurrency) AS DocumentCurrency,
	|		SUM(NestedQuery.RepaymentAmountVal) AS RepaymentAmountVal,
	|		SUM(NestedQuery.RepaymentAmount) AS RepaymentAmount,
	|		SUM(NestedQuery.ManRepaymentAmount) AS ManRepaymentAmount,
	|		SUM(NestedQuery.LocalRepaymentAmount) AS LocalRepaymentAmount
	|	FROM
	|		(SELECT
	|			Calculations.ARAPDocument AS ARAPDocument,
	|			CASE
	|			WHEN SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|					AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN ISNULL(Reservation_Receipt.CorPartnerAccountingDimension, Calculations.CorPartnerAccountingDimension)
	|			ELSE Calculations.AccountingDimensionByPartners
	|			END AS AccountingDimensionByPartners,
	|			CASE
	|			WHEN SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|					AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN ISNULL(Reservation_Receipt.CorARAPObject, Calculations.CorARAPObject)
	|			ELSE Calculations.ARAPObject
	|			END AS ARAPObject,
	|			Calculations.DocumentRecorder AS DocumentRecorder,
	|			Calculations.ReversingEntry AS ReversingEntry,
	|			MAX(CASE
	|				WHEN SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|						AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN UNDEFINED
	|				ELSE ISNULL(Reservation_Receipt.CorARAPObject, Calculations.CorARAPObject)
	|			END) AS CorARAPObject,
	|			MAX(CASE
	|				WHEN SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|						AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN UNDEFINED
	|				ELSE ISNULL(Reservation_Receipt.CorPartnerAccountingDimension, Calculations.CorPartnerAccountingDimension)
	|			END) AS CorPartnerAccountingDimension,
	|			MIN(SelectionOfAdvanceRepayments.AdvanceDate) AS AdvanceDate,
	|			MAX(SelectionOfAdvanceRepayments.MaturityDate) AS MaturityDate,
	|			MAX(SelectionOfAdvanceRepayments.EventSign) AS EventSign,
	|			MAX(CASE
	|				WHEN Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.APWriteOff)
	|					THEN VALUE(Enum.BusinessTransactions.APWriteOff)
	|				WHEN Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|					THEN VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|				WHEN Calculations.BusinessOperation IN (VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement),
	|														VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno))
	|					THEN VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)
	|				WHEN SelectionOfAdvanceRepayments.EventSign < 0
	|					THEN VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|				ELSE UNDEFINED
	|			END) AS EventKind,
	|			MAX(CASE
	|				WHEN Calculations.ARAPDocument REFS Document.CashAccountReceiptNote
	|					THEN CAST(Calculations.ARAPDocument AS Document.CashAccountReceiptNote).Currency
	|				WHEN Calculations.ARAPDocument REFS Document.BankAccountReceiptNote
	|					THEN CAST(Calculations.ARAPDocument AS Document.BankAccountReceiptNote).Currency
	|				WHEN Calculations.ARAPDocument REFS Document.SourceDocument
	|					THEN CAST(Calculations.ARAPDocument AS Document.SourceDocument).Currency
	|				ELSE Calculations.Currency
	|			END) AS DocumentCurrency,
	|			SUM(CASE
	|				WHEN Calculations.ARAPDocument REFS Document.CashAccountReceiptNote
	|						AND CAST(Calculations.ARAPDocument AS Document.CashAccountReceiptNote).Currency = SelectionOfAdvanceRepayments.LocalAccountingCurrency
	|					THEN Calculations.PrepaymentLocal
	|				WHEN Calculations.ARAPDocument REFS Document.BankAccountReceiptNote
	|						AND CAST(Calculations.ARAPDocument AS Document.BankAccountReceiptNote).Currency = SelectionOfAdvanceRepayments.LocalAccountingCurrency
	|					THEN Calculations.PrepaymentLocal
	|				ELSE Calculations.Prepayment
	|			END * CASE
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN -1
	|				ELSE 1
	|			END) AS RepaymentAmountVal,
	|			SUM(Calculations.Prepayment * CASE
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN -1
	|				ELSE 1
	|			END) AS RepaymentAmount,
	|			SUM(Calculations.PrepaymentMan * CASE
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN -1
	|				ELSE 1
	|			END) AS ManRepaymentAmount,
	|			SUM(Calculations.PrepaymentLocal * CASE
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN -1
	|				ELSE 1
	|			END) AS LocalRepaymentAmount
	|		FROM
	|			SelectionOfAdvanceRepayments AS SelectionOfAdvanceRepayments
	|				INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|				ON SelectionOfAdvanceRepayments.DocumentRecorder = Calculations.DocumentRecorder
	|					AND SelectionOfAdvanceRepayments.ARAPDocument = Calculations.ARAPDocument
	|					AND SelectionOfAdvanceRepayments.Organization = Calculations.ARAPObject.Organization
	|					AND (Calculations.Period BETWEEN &StartDate AND &EndDate)
	|					AND (Calculations.Active = TRUE)
	|					AND (Calculations.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment))
	|				LEFT JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS Reservation_Receipt
	|				ON Calculations.DocumentRecorder = Reservation_Receipt.DocumentRecorder
	|					AND Calculations.ARAPDocument = Reservation_Receipt.ARAPDocument
	|					AND Calculations.ARAPObject.Organization = Reservation_Receipt.ARAPObject.Organization
	|					AND (Reservation_Receipt.RecordType = VALUE(AccumulationRecordType.Receipt))
	|					AND (Reservation_Receipt.BusinessOperation = VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment))
	|					AND (Calculations.Active = TRUE)
	|		WHERE
	|			CASE WHEN NOT SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|					THEN TRUE
	|				ELSE NOT (Calculations.AccountingDimensionByPartners, Calculations.ARAPDocument, Calculations.Currency) IN
	|							(SELECT
	|								CustomersARAPAccounting.AccountingDimensionByPartners,
	|								CustomersARAPAccounting.ARAPDocument,
	|								CustomersARAPAccounting.DocumentCurrency
	|							FROM
	|								SettlementsWithClients_RepaymentsWithImplicitOffset AS CustomersARAPAccounting
	|							
	|							UNION ALL
	|
	|							SELECT
	|								CustomersARAPAccounting.CorPartnerAccountingDimension,
	|								CustomersARAPAccounting.ARAPDocument,
	|								CustomersARAPAccounting.DocumentCurrency
	|							FROM
	|								SettlementsWithClients_RepaymentsWithImplicitOffset AS CustomersARAPAccounting)
	|			END
	|	
	|		GROUP BY
	|			Calculations.ARAPDocument,
	|			Calculations.DocumentRecorder,
	|			Calculations.ReversingEntry,
	|			CASE
	|				WHEN SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|					AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN ISNULL(Reservation_Receipt.CorPartnerAccountingDimension, Calculations.CorPartnerAccountingDimension)
	|				ELSE Calculations.AccountingDimensionByPartners
	|			END,
	|			CASE
	|				WHEN SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|					AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN ISNULL(Reservation_Receipt.CorARAPObject, Calculations.CorARAPObject)
	|				ELSE Calculations.ARAPObject
	|			END) AS NestedQuery
	|
	|	GROUP BY
	|		NestedQuery.ARAPDocument,
	|		NestedQuery.ARAPObject.Organization,
	|		NestedQuery.AccountingDimensionByPartners,
	|		NestedQuery.ARAPObject,
	|		NestedQuery.ReversingEntry,
	|		NestedQuery.DocumentRecorder,
	|		NestedQuery.ARAPObject.Counterparty,
	|		NestedQuery.ARAPObject.Contract,
	|		NestedQuery.ARAPObject.LineOfBusiness,
	|		CASE
	|			WHEN NestedQuery.CorPartnerAccountingDimension <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|				THEN NestedQuery.CorPartnerAccountingDimension
	|			ELSE NestedQuery.AccountingDimensionByPartners
	|		END
	|	
	|	UNION ALL
	|
	|	SELECT
	|		Calculations.ARAPDocument,
	|		Calculations.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.ARAPObject,
	|		Calculations.DocumentRecorder,
	|		Calculations.Counterparty,
	|		Calculations.Contract,
	|		Calculations.LineOfBusiness,
	|		FALSE,
	|		Calculations.ExCounterparty,
	|		Calculations.Exodus,
	|		Calculations.ExhDirectionOfActivity,
	|		Calculations.CorPartnerAccountingDimension,
	|		Calculations.ExAnalyticsOfACCOUNTINGByPartners,
	|		Calculations.CorARAPObject,
	|		Calculations.SourceObjectOfCalculations_,
	|		Calculations.AdvanceDate,
	|		Calculations.MaturityDate,
	|		Calculations.EventSign,
	|		Calculations.EventKind,
	|		Calculations.DocumentCurrency,
	|		Calculations.DebtShaft,
	|		Calculations.Debt,
	|		Calculations.ARAPMan,
	|		Calculations.DebtLocal
	|	FROM
	|		SettlementsWithClients_RepaymentsWithImplicitOffset AS Calculations) AS NestedQuery
	|WHERE
	|	CASE
	|		WHEN NestedQuery.ReversingEntry = TRUE
	|			THEN NestedQuery.RepaymentAmount < 0
	|		ELSE NestedQuery.RepaymentAmount > 0
	|	END
	|
	|GROUP BY
	|	NestedQuery.ARAPDocument,
	|	NestedQuery.Organization,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.DocumentRecorder,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Contract,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.ReversingEntry
	|
	|UNION ALL
	|
	|// The old architecture of mutual settlements
	|SELECT
	|	Calculations.ARAPDocument,
	|	Calculations.AccountingDimensionByPartners.Organization,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.SalesOrder,
	|	Calculations.Recorder,
	|	Calculations.AccountingDimensionByPartners.Counterparty,
	|	Calculations.AccountingDimensionByPartners.Contract,
	|	Calculations.SalesOrder.LineOfBusiness,
	|	FALSE,
	|	Calculations.AccountingDimensionByPartners.Counterparty,
	|	Calculations.AccountingDimensionByPartners.Contract,
	|	Calculations.SalesOrder.LineOfBusiness,
	|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef),
	|	Calculations.AccountingDimensionByPartners,
	|	&EmptyCalculationObject,
	|	Calculations.SalesOrder,
	|	MAX(BEGINOFPERIOD(ISNULL(ReceiptOfCash.BankPostingDate, SourceDocumentsData.RecorderDate), DAY)),
	|	MAX(SelectionOfAdvanceRepayments.MaturityDate),
	|	MAX(SelectionOfAdvanceRepayments.EventSign),
	|	MAX(CASE
	|			WHEN Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.APWriteOff)
	|				THEN VALUE(Enum.BusinessTransactions.APWriteOff)
	|			WHEN Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment)
	|				THEN VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment)
	|			WHEN SelectionOfAdvanceRepayments.EventSign < 0
	|				THEN VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|			ELSE VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)
	|		END),
	|	MAX(CASE
	|			WHEN Calculations.ARAPDocument REFS Document.CashAccountReceiptNote
	|				THEN CAST(Calculations.ARAPDocument AS Document.CashAccountReceiptNote).Currency
	|			WHEN Calculations.ARAPDocument REFS Document.BankAccountReceiptNote
	|				THEN CAST(Calculations.ARAPDocument AS Document.BankAccountReceiptNote).Currency
	|			WHEN Calculations.ARAPDocument REFS Document.SourceDocument
	|				THEN CAST(Calculations.ARAPDocument AS Document.SourceDocument).Currency
	|			ELSE Calculations.Currency
	|		END),
	|	SUM(CASE
	|			WHEN Calculations.ARAPDocument REFS Document.CashAccountReceiptNote
	|					AND CAST(Calculations.ARAPDocument AS Document.CashAccountReceiptNote).Currency = SelectionOfAdvanceRepayments.LocalAccountingCurrency
	|				THEN Calculations.PrepaymentLocal
	|			WHEN Calculations.ARAPDocument REFS Document.BankAccountReceiptNote
	|					AND CAST(Calculations.ARAPDocument AS Document.BankAccountReceiptNote).Currency = SelectionOfAdvanceRepayments.LocalAccountingCurrency
	|				THEN Calculations.PrepaymentLocal
	|			ELSE Calculations.Prepayment
	|		END * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|			ELSE -1
	|		END),
	|		SUM(Calculations.Prepayment * CASE
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN 1
	|				ELSE -1
	|			END),
	|		SUM(Calculations.PrepaymentMan * CASE
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN 1
	|				ELSE -1
	|			END),
	|		SUM(Calculations.PrepaymentLocal * CASE
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN 1
	|				ELSE -1
	|			END)
	|	FROM
	|		SelectionOfAdvanceRepayments AS SelectionOfAdvanceRepayments
	|		INNER JOIN AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|		ON SelectionOfAdvanceRepayments.DocumentRecorder = Calculations.Recorder
	|			AND SelectionOfAdvanceRepayments.ARAPDocument = Calculations.ARAPDocument
	|			AND SelectionOfAdvanceRepayments.Organization = Calculations.AccountingDimensionByPartners.Organization
	|			AND (Calculations.Period BETWEEN &StartDate AND &EndDate)
	|			AND (Calculations.Active = TRUE)
	|		LEFT JOIN Document.BankAccountReceiptNote AS ReceiptOfCash
	|		ON SelectionOfAdvanceRepayments.ARAPDocument = ReceiptOfCash.Ref
	|		LEFT JOIN InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|		ON SelectionOfAdvanceRepayments.ARAPDocument = SourceDocumentsData.Document
	|			AND SelectionOfAdvanceRepayments.Organization = SourceDocumentsData.Organization
	|
	|	GROUP BY
	|		Calculations.ARAPDocument,
	|		Calculations.AccountingDimensionByPartners.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.SalesOrder,
	|		Calculations.Recorder,
	|		Calculations.AccountingDimensionByPartners.Counterparty,
	|		Calculations.AccountingDimensionByPartners.Contract,
	|		Calculations.SalesOrder.LineOfBusiness
	|
	|HAVING
	|	SUM(Calculations.Prepayment * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|			ELSE -1
	|		END) > 0
	|
	|INDEX BY
	|	ARAPDocument,
	|	Organization,
	|	DocumentRecorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Repayments.ARAPDocument AS ARAPDocument,
	|	Repayments.Organization AS Organization,
	|	Repayments.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Repayments.ARAPObject AS ARAPObject,
	|	Repayments.DocumentRecorder AS DocumentRecorder,
	|	Repayments.Counterparty AS Counterparty,
	|	Repayments.Contract AS Contract,
	|	Repayments.LineOfBusiness AS LineOfBusiness,
	|	Repayments.ExCounterparty AS ExCounterparty,
	|	Repayments.Exodus AS Exodus,
	|	Repayments.ExhDirectionOfActivity AS ExhDirectionOfActivity,
	|	Repayments.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	Repayments.InitialAccountingAnalyticsForPartners AS InitialAccountingAnalyticsForPartners,
	|	Repayments.CorARAPObject AS CorARAPObject,
	|	Repayments.SourceObjectOfCalculations_ AS SourceObjectOfCalculations_,
	|	Repayments.AdvanceDate AS AdvanceDate,
	|	Repayments.MaturityDate AS MaturityDate,
	|	Repayments.ReversingEntry AS ReversingEntry,
	|	MAX(Repayments.EventSign) AS EventSign,
	|	MAX(CASE
	|			WHEN Repayments.EventKind = UNDEFINED
	|			// If the type of event could not be identified immediately, we look at secondary signs
	|				THEN CASE
	|						WHEN ISNULL(EventKinds.BusinessOperation, UNDEFINED) = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|							THEN VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|						WHEN ISNULL(EventKinds.BusinessOperation, UNDEFINED) IN (VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement),
	|																							VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno))
	|							THEN VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)
	|						WHEN Repayments.EventSign < 0
	|							THEN VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|						ELSE VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)
	|					END
	|			ELSE Repayments.EventKind
	|		END) AS EventKind,
	|	MAX(Repayments.DocumentCurrency) AS DocumentCurrency,
	|	MAX(Repayments.RepaymentAmount) AS RepaymentAmount,
	|	MAX(Repayments.RepaymentAmountVal) AS RepaymentAmountVal,
	|	MAX(Repayments.ManRepaymentAmount) AS ManRepaymentAmount,
	|	MAX(Repayments.LocalRepaymentAmount) AS LocalRepaymentAmount
	|INTO SettlementsWithCustomers_RepaymentOfAdvances
	|FROM
	|SettlementsWithCustomers_RepaymentOfAdvances_Preliminary AS Repayments
	|	
	|	LEFT JOIN
	|		// We connect to the register, and not to the finished temporary table in order to take into account reservations
	|		// that were outside the offset period
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Reservation
	|	ON
	|		&NewOnlineARAPAccounting
	|		AND &TakeIntoAccountReservationOfAdvances
	|		AND Repayments.DocumentRecorder    = Reservation.DocumentRecorder
	|		AND Repayments.ARAPDocument      = Reservation.ARAPDocument
	|		AND Repayments.SourceObjectOfCalculations_ = Reservation.ARAPObject
	|		AND Reservation.Period            <= &EndDate
	|		AND Repayments.Organization            = Reservation.ARAPObject.Organization
	|		AND Reservation.RecordType       = VALUE(AccumulationRecordType.Expense)
	|		AND Reservation.BusinessOperation
	|			= VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment)
	|
	|	LEFT JOIN
	|		// We find the type of event if initially it was not possible to identify
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS EventKinds
	|	ON
	|		&NewOnlineARAPAccounting
	|		AND Repayments.EventKind          = UNDEFINED
	|		AND Repayments.DocumentRecorder = EventKinds.DocumentRecorder
	|		AND EventKinds.Period            <= &EndDate
	|		AND EventKinds.RecordType       = VALUE(AccumulationRecordType.Expense)
	|		AND EventKinds.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|			 VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement),
	|			 VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno))
	|
	|WHERE
	|	Reservation.ARAPDocument IS NULL
	|
	|GROUP BY
	|	Repayments.ARAPDocument,
	|	Repayments.Organization,
	|	Repayments.AccountingDimensionByPartners,
	|	Repayments.ARAPObject,
	|	Repayments.DocumentRecorder,
	|	Repayments.Counterparty,
	|	Repayments.Contract,
	|	Repayments.LineOfBusiness,
	|	Repayments.ExCounterparty,
	|	Repayments.Exodus,
	|	Repayments.ExhDirectionOfActivity,
	|	Repayments.CorPartnerAccountingDimension,
	|	Repayments.InitialAccountingAnalyticsForPartners,
	|	Repayments.CorARAPObject,
	|	Repayments.SourceObjectOfCalculations_,
	|	Repayments.AdvanceDate,
	|	Repayments.MaturityDate,
	|	Repayments.ReversingEntry
	|
	|UNION ALL
	|
	|SELECT
	|	ReservingParishes.ARAPDocument AS ARAPDocument,
	|	ReservingParishes.ARAPObject.Organization AS Organization,
	|	ReservingParishes.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ReservingParishes.ARAPObject AS ARAPObject,
	|	ReservingParishes.DocumentRecorder AS DocumentRecorder,
	|	ReservingParishes.ARAPObject.Counterparty AS Counterparty,
	|	ReservingParishes.ARAPObject.Contract AS Contract,
	|	ReservingParishes.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	MAX(ReservationCosts.ARAPObject.Counterparty) AS ExCounterparty,
	|	MAX(ReservationCosts.ARAPObject.Contract) AS Exodus,
	|	MAX(ReservationCosts.ARAPObject.LineOfBusiness) AS ExhDirectionOfActivity,
	|	MAX(ReservationCosts.CorPartnerAccountingDimension) AS CorPartnerAccountingDimension,
	|	MAX(ReservationCosts.AccountingDimensionByPartners) AS InitialAccountingAnalyticsForPartners,
	|	MAX(ReservationCosts.CorARAPObject) AS CorARAPObject,
	|	MAX(ReservationCosts.ARAPObject) AS SourceObjectOfCalculations_, // the object from which the funds were reserved
	|	MIN(ReservationCosts.OccurrenceDate) AS AdvanceDate,
	|	MAX(ReservationCosts.Period) AS MaturityDate,
	|	FALSE AS ReversingEntry,
	|	MAX(ReservingParishes.ReservationAmountShaft) AS EventSign,
	|	VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment) AS EventKind,
	|	MAX(ReservingParishes.DocumentCurrency) AS DocumentCurrency,
	|	MAX(ReservingParishes.ReservationAmount) AS RepaymentAmount,
	|	MAX(ReservingParishes.ReservationAmountShaft) AS RepaymentAmountVal,
	|	MAX(ReservingParishes.ManReservationAmount) AS ManRepaymentAmount,
	|	MAX(ReservingParishes.LocalReservationAmount) AS LocalRepaymentAmount
	|FROM
	|	(SELECT
	|		Calculations.ARAPDocument,
	|		Calculations.ARAPObject.Organization AS Organization,
	|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject AS ARAPObject,
	|		Calculations.DocumentRecorder AS DocumentRecorder,
	|		MAX(CASE
	|				WHEN Calculations.ARAPDocument REFS Document.CashAccountReceiptNote
	|					THEN CAST(Calculations.ARAPDocument AS Document.CashAccountReceiptNote).Currency
	|				WHEN Calculations.ARAPDocument REFS Document.BankAccountReceiptNote
	|					THEN CAST(Calculations.ARAPDocument
	|									AS Document.BankAccountReceiptNote).Currency
	|				WHEN Calculations.ARAPDocument REFS Document.SourceDocument
	|					THEN CAST(Calculations.ARAPDocument AS Document.SourceDocument).Currency
	|				ELSE Calculations.Currency
	|		END) AS DocumentCurrency,
	|		SUM(CASE
	|				WHEN Calculations.ARAPDocument REFS Document.CashAccountReceiptNote
	|						AND CAST(Calculations.ARAPDocument
	|									AS Document.CashAccountReceiptNote).Currency = Calculations.ARAPObject.Organization.LocalAccountingCurrency
	|					THEN Calculations.PrepaymentLocal
	|				WHEN Calculations.ARAPDocument REFS Document.BankAccountReceiptNote
	|						AND CAST(Calculations.ARAPDocument
	|									AS Document.BankAccountReceiptNote).Currency = Calculations.ARAPObject.Organization.LocalAccountingCurrency
	|					THEN Calculations.PrepaymentLocal
	|				ELSE
	|					Calculations.Prepayment
	|		END) AS ReservationAmountShaft,
	|		SUM(Calculations.Prepayment) AS ReservationAmount,
	|		SUM(Calculations.PrepaymentMan) AS ManReservationAmount,
	|		SUM(Calculations.PrepaymentLocal) AS LocalReservationAmount
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|	WHERE
	|		&NewOnlineARAPAccounting
	|		AND &TakeIntoAccountReservationOfAdvances
	|		AND NOT &CreateEmptyTable
	|		AND (NOT &EnableOrganizationSelection
	|			OR Calculations.ARAPObject.Organization IN (&Companies))
	|		AND (&TextSelectionByParameters)
	|		AND Calculations.Period BETWEEN &StartDate AND &EndDate
	|		AND Calculations.Active  = TRUE
	|		AND Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment)
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND Calculations.Prepayment > 0
	|	
	|	GROUP BY
	|		Calculations.ARAPDocument,
	|		Calculations.ARAPObject.Organization,
	|		Calculations.ARAPObject.Organization.LocalAccountingCurrency,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.ARAPObject,
	|		Calculations.DocumentRecorder
	|
	|	) AS ReservingParishes
	|
	|	INNER JOIN
	|		// The expenses contain data on the advance from which funds were reserved
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS ReservationCosts
	|	ON
	|		ReservingParishes.DocumentRecorder    = ReservationCosts.DocumentRecorder
	|		AND  ReservingParishes.ARAPDocument   = ReservationCosts.ARAPDocument
	|		AND  ReservingParishes.Organization         = ReservationCosts.ARAPObject.Organization
	|		AND  ReservationCosts.Period BETWEEN &StartDate AND &EndDate
	|		AND  ReservationCosts.Active  = TRUE
	|		AND  ReservationCosts.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND  ReservationCosts.BusinessOperation = VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment)
	|
	|GROUP BY
	|	ReservingParishes.ARAPDocument,
	|	ReservingParishes.ARAPObject.Organization,
	|	ReservingParishes.AccountingDimensionByPartners,
	|	ReservingParishes.ARAPObject,
	|	ReservingParishes.DocumentRecorder
	|
	|HAVING
	|	SUM(ReservingParishes.ReservationAmount) > 0
	|
	|
	|INDEX BY
	|	ARAPDocument,
	|	SourceObjectOfCalculations_,
	|	InitialAccountingAnalyticsForPartners,
	|	AdvanceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SelectionOfAdvanceRepayments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SettlementsWithCustomers_RepaymentOfAdvances_Preliminary
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SettlementsWithClients_RepaymentsWithImplicitOffset
	|;
	|";
	
	SetIndexFields(Query, CalculationParameters, "SettlementsWithCustomers_RepaymentOfAdvances");
	
	PathParameters = InitializeParametersForSelectingAdvances_FieldPathsAndReplacementText();
	ProcessRequestTextForSelectingAdvancesBasedOnParameters(Query, CalculationParameters, PathParameters);
	
	Query.Execute();
	
EndProcedure

// Prepare a temporary table "CalculaTIon_transfErences_"
// Creates a temporary table with columns:
// 	  Organization;
// 	  Document payments;
// 	  Transfer Document;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Counterparty;
// 	  Directions of activity;  
// 	  Division;
// 	  Coralitikauchetapopartners;
// 	  Account Object Box;
// 	  CorContragent;
// 	  Root direction of activity;  
// 	  Corps Division;
// 	  Period;
// 	  Setting up an economic operation
// 	  Record ID;
// 	  Currency;
// 	  Prepayment;
// 	  PrepaymentRegl;
// 	  PrepaymentUpr.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_SettlementsWithClients_TransfersOfAdvances(TempTablesManager, CalculationParameters) Export
		
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	SetRequestParametersForPreparationOfAdvancePayments(Query, CalculationParameters);

	Query.Text =
	"SELECT
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.TransferDocument AS PrepaymentsSettlementDocument,
	|	NestedQuery.DocumentPayments AS DocumentPayments,
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	NestedQuery.CorARAPObject AS CorARAPObject,
	|	NestedQuery.CorCounterparty AS CorCounterparty,
	|	NestedQuery.CorLineOfBusiness AS CorLineOfBusiness,
	|	NestedQuery.DebitBusinessUnit AS DebitBusinessUnit,
	|	NestedQuery.Period AS Period,
	|	NestedQuery.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	NestedQuery.FinRecordID AS FinRecordID,
	|	NestedQuery.ReversingEntry AS ReversingEntry,
	|	NestedQuery.Currency AS Currency,
	|	SUM(NestedQuery.Prepayment) AS Prepayment,
	|	SUM(NestedQuery.PrepaymentLocal) AS PrepaymentLocal,
	|	SUM(NestedQuery.PrepaymentMan) AS PrepaymentMan
	|INTO SettlementsWithClients_TransfersOfAdvances_Preliminary
	|FROM
	|	(SELECT
	|		CustomersARAPAccountingByDueDates.ARAPObject.Organization AS Organization,
	|		CustomersARAPAccountingByDueDates.DocumentRecorder AS TransferDocument,
	|		CustomersARAPAccountingByDueDates.ARAPDocument AS DocumentPayments,
	|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CustomersARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|		CustomersARAPAccountingByDueDates.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|		CustomersARAPAccountingByDueDates.ARAPObject.Department AS Department,
	|		CustomersARAPAccountingByDueDates.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|		CustomersARAPAccountingByDueDates.CorARAPObject AS CorARAPObject,
	|		CustomersARAPAccountingByDueDates.CorPartnerAccountingDimension.Counterparty AS CorCounterparty,
	|		CustomersARAPAccountingByDueDates.CorARAPObject.LineOfBusiness AS CorLineOfBusiness,
	|		CustomersARAPAccountingByDueDates.CorARAPObject.Department AS DebitBusinessUnit,
	|		CustomersARAPAccountingByDueDates.Period AS Period,
	|		CustomersARAPAccountingByDueDates.BusinessTransactionSetting AS BusinessTransactionSetting,
	|		CustomersARAPAccountingByDueDates.FinRecordID AS FinRecordID,
	|		CustomersARAPAccountingByDueDates.ReversingEntry AS ReversingEntry,
	|		CustomersARAPAccountingByDueDates.Currency AS Currency,
	|		CustomersARAPAccountingByDueDates.Prepayment AS Prepayment,
	|		CustomersARAPAccountingByDueDates.PrepaymentLocal AS PrepaymentLocal,
	|		CustomersARAPAccountingByDueDates.PrepaymentMan AS PrepaymentMan
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|			LEFT JOIN Document.ARAPSettlement AS ARAPSettlement
	|			ON CustomersARAPAccountingByDueDates.DocumentRecorder = ARAPSettlement.Ref
	|				AND (ARAPSettlement.OperationKind IN (&TypesOfOperationsOfAdvanceTransfer))
	|			LEFT JOIN Document.ARAPSettlement AS StornoDebtSBeingOffsettingARAPOffsetting
	|			ON (CAST(CustomersARAPAccountingByDueDates.DocumentRecorder AS Document.ReversingEntry).ReversedDocument = StornoDebtSBeingOffsettingARAPOffsetting.Ref)
	|				AND (StornoDebtSBeingOffsettingARAPOffsetting.OperationKind IN (&TypesOfOperationsOfAdvanceTransfer))
	|	WHERE
	|		CustomersARAPAccountingByDueDates.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment)
	|		AND CustomersARAPAccountingByDueDates.Active
	|		AND NOT ISNULL(ARAPSettlement.Ref, ISNULL(StornoDebtSBeingOffsettingARAPOffsetting.Ref, NULL)) IS NULL
	|		AND CustomersARAPAccountingByDueDates.Active
	|		AND CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND CustomersARAPAccountingByDueDates.Period BETWEEN &StartDate AND &EndDate
	|		AND CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Organization IN(&Companies)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomersARAPAccountingByDueDates.ARAPObject.Organization,
	|		CustomersARAPAccountingByDueDates.DocumentRecorder,
	|		CustomersARAPAccountingByDueDates_Receipt.ARAPDocument,
	|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners,
	|		CustomersARAPAccountingByDueDates.ARAPObject,
	|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Counterparty,
	|		CustomersARAPAccountingByDueDates.ARAPObject.LineOfBusiness,
	|		CustomersARAPAccountingByDueDates.ARAPObject.Department,
	|		CustomersARAPAccountingByDueDates.CorPartnerAccountingDimension,
	|		CustomersARAPAccountingByDueDates.CorARAPObject,
	|		CustomersARAPAccountingByDueDates.CorPartnerAccountingDimension.Counterparty,
	|		CustomersARAPAccountingByDueDates.CorARAPObject.LineOfBusiness,
	|		CustomersARAPAccountingByDueDates.CorARAPObject.Department,
	|		CustomersARAPAccountingByDueDates.Period,
	|		CustomersARAPAccountingByDueDates.BusinessTransactionSetting,
	|		CustomersARAPAccountingByDueDates.FinRecordID,
	|		CustomersARAPAccountingByDueDates.ReversingEntry,
	|		CustomersARAPAccountingByDueDates.Currency,
	|		CustomersARAPAccountingByDueDates.Debt,
	|		CustomersARAPAccountingByDueDates.DebtLocal,
	|		CustomersARAPAccountingByDueDates.ARAPMan
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|			LEFT JOIN Document.ARAPSettlement AS ARAPSettlement
	|			ON CustomersARAPAccountingByDueDates.DocumentRecorder = ARAPSettlement.Ref
	|				AND (ARAPSettlement.OperationKind IN (&TypesOfOperationsOfAdvanceTransfer))
	|			LEFT JOIN Document.ARAPSettlement AS StornoDebtSBeingOffsettingARAPOffsetting
	|			ON (CAST(CustomersARAPAccountingByDueDates.DocumentRecorder AS Document.ReversingEntry).ReversedDocument = StornoDebtSBeingOffsettingARAPOffsetting.Ref)
	|				AND (StornoDebtSBeingOffsettingARAPOffsetting.OperationKind IN (&TypesOfOperationsOfAdvanceTransfer))
	|			INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates_Receipt
	|			ON (CustomersARAPAccountingByDueDates_Receipt.RecordType = VALUE(AccumulationRecordType.Receipt))
	|				AND CustomersARAPAccountingByDueDates.ARAPObject = CustomersARAPAccountingByDueDates_Receipt.ARAPObject
	|				AND CustomersARAPAccountingByDueDates.AccountingDimensionByPartners = CustomersARAPAccountingByDueDates_Receipt.AccountingDimensionByPartners
	|				AND CustomersARAPAccountingByDueDates.DocumentRecorder = CustomersARAPAccountingByDueDates_Receipt.DocumentRecorder
	|	WHERE
	|		CustomersARAPAccountingByDueDates.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment)
	|		AND CustomersARAPAccountingByDueDates.Active
	|		AND NOT ISNULL(ARAPSettlement.Ref, ISNULL(StornoDebtSBeingOffsettingARAPOffsetting.Ref, NULL)) IS NULL
	|		AND CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND CustomersARAPAccountingByDueDates.Period BETWEEN &StartDate AND &EndDate
	|		AND CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Organization IN(&Companies)
	|		AND CustomersARAPAccountingByDueDates.Debt <> 0) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.Currency,
	|	NestedQuery.CorPartnerAccountingDimension,
	|	NestedQuery.Department,
	|	NestedQuery.DebitBusinessUnit,
	|	NestedQuery.DocumentPayments,
	|	NestedQuery.CorLineOfBusiness,
	|	NestedQuery.FinRecordID,
	|	NestedQuery.Period,
	|	NestedQuery.Organization,
	|	NestedQuery.CorARAPObject,
	|	NestedQuery.CorCounterparty,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.Counterparty,
	|	NestedQuery.BusinessTransactionSetting,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.TransferDocument,
	|	NestedQuery.ReversingEntry
	|
	|INDEX BY
	|	DocumentPayments,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	CorPartnerAccountingDimension,
	|	CorARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettlementsWithClients_TransfersOfAdvances.DocumentPayments AS DocumentPayments,
	|	SettlementsWithClients_TransfersOfAdvances.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	SettlementsWithClients_TransfersOfAdvances.ARAPObject AS ARAPObject,
	|	SettlementsWithClients_TransfersOfAdvances.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	SettlementsWithClients_TransfersOfAdvances.CorARAPObject AS CorARAPObject,
	|	SettlementsWithClients_TransfersOfAdvances.Currency AS Currency,
	|	SettlementsWithClients_TransfersOfAdvances.FinRecordID AS FinRecordID,
	|	SUM(SettlementsWithClients_TransfersOfAdvances.Prepayment) AS Prepayment,
	|	SUM(SettlementsWithClients_TransfersOfAdvances.PrepaymentLocal) AS PrepaymentLocal,
	|	SUM(SettlementsWithClients_TransfersOfAdvances.PrepaymentMan) AS PrepaymentMan
	|INTO HyphenationSelections
	|FROM
	|	SettlementsWithClients_TransfersOfAdvances_Preliminary AS SettlementsWithClients_TransfersOfAdvances
	|
	|GROUP BY
	|	SettlementsWithClients_TransfersOfAdvances.Organization,
	|	SettlementsWithClients_TransfersOfAdvances.DocumentPayments,
	|	SettlementsWithClients_TransfersOfAdvances.AccountingDimensionByPartners,
	|	SettlementsWithClients_TransfersOfAdvances.ARAPObject,
	|	SettlementsWithClients_TransfersOfAdvances.CorPartnerAccountingDimension,
	|	SettlementsWithClients_TransfersOfAdvances.CorARAPObject,
	|	SettlementsWithClients_TransfersOfAdvances.Currency,
	|	SettlementsWithClients_TransfersOfAdvances.FinRecordID
	|
	|HAVING
	|	SUM(SettlementsWithClients_TransfersOfAdvances.Prepayment) <> 0
	|
	|INDEX BY
	|	DocumentPayments,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	CorPartnerAccountingDimension,
	|	CorARAPObject,
	|	Currency,
	|	FinRecordID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettlementsWithClients_TransfersOfAdvances.Organization AS Organization,
	|	SettlementsWithClients_TransfersOfAdvances.PrepaymentsSettlementDocument AS PrepaymentsSettlementDocument,
	|	SettlementsWithClients_TransfersOfAdvances.DocumentPayments AS DocumentPayments,
	|	SettlementsWithClients_TransfersOfAdvances.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	SettlementsWithClients_TransfersOfAdvances.ARAPObject AS ARAPObject,
	|	SettlementsWithClients_TransfersOfAdvances.Counterparty AS Counterparty,
	|	SettlementsWithClients_TransfersOfAdvances.LineOfBusiness AS LineOfBusiness,
	|	SettlementsWithClients_TransfersOfAdvances.Department AS Department,
	|	SettlementsWithClients_TransfersOfAdvances.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	SettlementsWithClients_TransfersOfAdvances.CorARAPObject AS CorARAPObject,
	|	SettlementsWithClients_TransfersOfAdvances.CorCounterparty AS CorCounterparty,
	|	SettlementsWithClients_TransfersOfAdvances.CorLineOfBusiness AS CorLineOfBusiness,
	|	SettlementsWithClients_TransfersOfAdvances.DebitBusinessUnit AS DebitBusinessUnit,
	|	SettlementsWithClients_TransfersOfAdvances.Period AS Period,
	|	SettlementsWithClients_TransfersOfAdvances.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	SettlementsWithClients_TransfersOfAdvances.FinRecordID AS FinRecordID,
	|	SettlementsWithClients_TransfersOfAdvances.ReversingEntry AS ReversingEntry,
	|	SettlementsWithClients_TransfersOfAdvances.Currency AS Currency,
	|	SettlementsWithClients_TransfersOfAdvances.Prepayment AS Prepayment,
	|	SettlementsWithClients_TransfersOfAdvances.PrepaymentLocal AS PrepaymentLocal,
	|	SettlementsWithClients_TransfersOfAdvances.PrepaymentMan AS PrepaymentMan
	|INTO SettlementsWithClients_TransfersOfAdvances
	|FROM
	|	SettlementsWithClients_TransfersOfAdvances_Preliminary AS SettlementsWithClients_TransfersOfAdvances
	|		INNER JOIN HyphenationSelections AS HyphenationSelections
	|		ON SettlementsWithClients_TransfersOfAdvances.DocumentPayments = HyphenationSelections.DocumentPayments
	|			AND SettlementsWithClients_TransfersOfAdvances.AccountingDimensionByPartners = HyphenationSelections.AccountingDimensionByPartners
	|			AND SettlementsWithClients_TransfersOfAdvances.ARAPObject = HyphenationSelections.ARAPObject
	|			AND SettlementsWithClients_TransfersOfAdvances.CorPartnerAccountingDimension = HyphenationSelections.CorPartnerAccountingDimension
	|			AND SettlementsWithClients_TransfersOfAdvances.CorARAPObject = HyphenationSelections.CorARAPObject
	|			AND SettlementsWithClients_TransfersOfAdvances.Currency = HyphenationSelections.Currency
	|			AND SettlementsWithClients_TransfersOfAdvances.FinRecordID = HyphenationSelections.FinRecordID
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SettlementsWithClients_TransfersOfAdvances_Preliminary
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP HyphenationSelections";
	
	SetIndexFields(Query, CalculationParameters, "SettlementsWithClients_TransfersOfAdvances");
	
	Query.Execute();
	
EndProcedure

// Prepare a temporary table of "Received balances for cancellations and losses"
// Creates a temporary table with columns:
//   Organization;
//   Directions of activity;
//   Counterparty;
//   Contract;
//   From the direction of activity - the direction in which the advance arose;
//   Iscontragent - the counterparty for which the advance arose;
//   IshDogovor - Contract Under Which there Was an advance;
//   Settlement document;
//   Initial analyticsaccounts to partners - analytics for which an advance was formed;
//   Initial account objectobject - the settlement object for which the advance payment was generated;
//   Datavance;
//   Cancellation date - if it Is Empty, then it Is The Balance;
//   Document currency;
//   Document Recorder;
//   SummaVal - the amount in the document currency;
//   SummaUpr;
//   Summareg;
//   The amount.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_ReceivedAdvancesInTermsOfRepaymentsAndBalances(TempTablesManager, CalculationParameters) Export
	
	ParametersForCalculatingRepaymentReceipts = InitializeParametersForPreparationOfAdvancePayments(CalculationParameters);
	ParametersForCalculatingRepaymentReceipts.ManualIndexFields.Clear();
	If ValueIsFilled(CalculationParameters.Companies) Then
		ParametersForCalculatingRepaymentReceipts.EnableOrganizationSelection = True;
	EndIf;
	
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager,
		"SettlementsWithCustomers_Advances") Then
		PrepareVT_SettlementsWithCustomers_Advances(
			TempTablesManager,
			ParametersForCalculatingRepaymentReceipts);
	EndIf;
	
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(TempTablesManager,
		"SettlementsWithCustomers_RepaymentOfAdvances") Then
		PrepareVT_SettlementsWithCustomers_RepaymentOfAdvances(
			TempTablesManager,
			ParametersForCalculatingRepaymentReceipts);
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	SetRequestParametersForPreparationOfAdvancePayments(Query, CalculationParameters);
	
	Query.Text =
	"SELECT
	|	RepaymentOfAdvances.Organization AS Organization,
	|	RepaymentOfAdvances.ARAPDocument AS ARAPDocument,
	|	RepaymentOfAdvances.InitialAccountingAnalyticsForPartners AS InitialAccountingAnalyticsForPartners,
	|	RepaymentOfAdvances.SourceObjectOfCalculations_ AS SourceObjectOfCalculations_,
	|	RepaymentOfAdvances.AdvanceDate AS AdvanceDate,
	|	SUM(RepaymentOfAdvances.RepaymentAmountVal) AS RepaymentAmountVal,
	|	SUM(RepaymentOfAdvances.ManRepaymentAmount) AS ManRepaymentAmount,
	|	SUM(RepaymentOfAdvances.LocalRepaymentAmount) AS LocalRepaymentAmount,
	|	SUM(RepaymentOfAdvances.RepaymentAmount) AS RepaymentAmount
	|INTO RepaymentsOfAdvances_Collapsed
	|FROM
	|	SettlementsWithCustomers_RepaymentOfAdvances AS RepaymentOfAdvances
	|
	|GROUP BY
	|	RepaymentOfAdvances.Organization,
	|	RepaymentOfAdvances.ARAPDocument,
	|	RepaymentOfAdvances.AdvanceDate,
	|	RepaymentOfAdvances.InitialAccountingAnalyticsForPartners,
	|	RepaymentOfAdvances.SourceObjectOfCalculations_
	|
	|INDEX BY
	|	ARAPDocument,
	|	SourceObjectOfCalculations_,
	|	InitialAccountingAnalyticsForPartners,
	|	AdvanceDate
	|; 
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReceiptOfAdvances.Organization AS Organization,
	|	ReceiptOfAdvances.LineOfBusiness AS LineOfBusiness,
	|	ReceiptOfAdvances.Counterparty AS Counterparty,
	|	ReceiptOfAdvances.Contract AS Contract,
	|	ReceiptOfAdvances.ARAPObject AS ARAPObject,
	|	ReceiptOfAdvances.ARAPDocument AS ARAPDocument,
	|	ReceiptOfAdvances.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ReceiptOfAdvances.AdvanceDate AS AdvanceDate,
	|	MAX(ReceiptOfAdvances.DocumentCurrency) AS DocumentCurrency,
	|	SUM(ReceiptOfAdvances.AdvanceAmountVal) AS AdvanceAmountVal,
	|	SUM(ReceiptOfAdvances.AdvanceAmountOfMan) AS AdvanceAmountOfMan,
	|	SUM(ReceiptOfAdvances.AmountOfSchedAdvance) AS AmountOfSchedAdvance,
	|	SUM(ReceiptOfAdvances.AdvanceAmount) AS AdvanceAmount
	|INTO AdvanceReceipts_Collapsed
	|FROM
	|	SettlementsWithCustomers_Advances AS ReceiptOfAdvances
	|GROUP BY
	|	ReceiptOfAdvances.Organization,
	|	ReceiptOfAdvances.LineOfBusiness,
	|	ReceiptOfAdvances.Counterparty,
	|	ReceiptOfAdvances.Contract,
	|	ReceiptOfAdvances.ARAPObject,
	|	ReceiptOfAdvances.ARAPDocument,
	|	ReceiptOfAdvances.AdvanceDate,
	|	ReceiptOfAdvances.AccountingDimensionByPartners
	|
	|INDEX BY
	|	ARAPDocument,
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	AdvanceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AdvanceData.Organization AS Organization,
	|	AdvanceData.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	AdvanceData.ARAPObject AS ARAPObject,
	|	AdvanceData.ARAPDocument AS ARAPDocument,
	|	AdvanceData.AdvanceDate AS AdvanceDate,
	|	AdvanceData.InitialAccountingAnalyticsForPartners AS InitialAccountingAnalyticsForPartners,
	|	AdvanceData.SourceObjectOfCalculations_ AS SourceObjectOfCalculations_,
	|	AdvanceData.DocumentCurrency AS DocumentCurrency,
	|	AdvanceData.Counterparty AS Counterparty,
	|	AdvanceData.Contract AS Contract,
	|	AdvanceData.LineOfBusiness AS LineOfBusiness,
	|	AdvanceData.ExCounterparty AS ExCounterparty,
	|	AdvanceData.Exodus AS Exodus,
	|	AdvanceData.ExhDirectionOfActivity AS ExhDirectionOfActivity
	|INTO DataOnAdvancesReceived
	|FROM
	|	(SELECT DISTINCT
	|		ReceiptOfAdvances.Organization AS Organization,
	|		ReceiptOfAdvances.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		ReceiptOfAdvances.ARAPObject AS ARAPObject,
	|		ReceiptOfAdvances.AccountingDimensionByPartners AS InitialAccountingAnalyticsForPartners,
	|		ReceiptOfAdvances.ARAPObject AS SourceObjectOfCalculations_,
	|		ReceiptOfAdvances.ARAPDocument AS ARAPDocument,
	|		ReceiptOfAdvances.AdvanceDate AS AdvanceDate,
	|		ReceiptOfAdvances.DocumentCurrency AS DocumentCurrency,
	|		ReceiptOfAdvances.Counterparty AS Counterparty,
	|		ReceiptOfAdvances.Contract AS Contract,
	|		ReceiptOfAdvances.LineOfBusiness AS LineOfBusiness,
	|		ReceiptOfAdvances.Counterparty AS ExCounterparty,
	|		ReceiptOfAdvances.Contract AS Exodus,
	|		ReceiptOfAdvances.LineOfBusiness AS ExhDirectionOfActivity
	|	FROM
	|		SettlementsWithCustomers_Advances AS ReceiptOfAdvances
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		RepaymentOfAdvances.Organization AS Organization,
	|		RepaymentOfAdvances.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CASE
	|			WHEN RepaymentOfAdvances.EventKind = VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment)
	|				THEN RepaymentOfAdvances.SourceObjectOfCalculations_
	|			ELSE RepaymentOfAdvances.ARAPObject
	|		END AS ARAPObject,
	|		RepaymentOfAdvances.InitialAccountingAnalyticsForPartners AS InitialAccountingAnalyticsForPartners,
	|		RepaymentOfAdvances.SourceObjectOfCalculations_ AS SourceObjectOfCalculations_,
	|		RepaymentOfAdvances.ARAPDocument AS ARAPDocument,
	|		RepaymentOfAdvances.AdvanceDate AS AdvanceDate,
	|		RepaymentOfAdvances.DocumentCurrency AS DocumentCurrency,
	|		RepaymentOfAdvances.Counterparty AS Counterparty,
	|		RepaymentOfAdvances.Contract AS Contract,
	|		RepaymentOfAdvances.LineOfBusiness AS LineOfBusiness,
	|		RepaymentOfAdvances.ExCounterparty AS ExCounterparty,
	|		RepaymentOfAdvances.Exodus AS Exodus,
	|		RepaymentOfAdvances.ExhDirectionOfActivity AS ExhDirectionOfActivity
	|	FROM
	|		SettlementsWithCustomers_RepaymentOfAdvances AS RepaymentOfAdvances) AS AdvanceData
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Prepayments.Organization AS Organization,
	|	Prepayments.LineOfBusiness AS LineOfBusiness,
	|	Prepayments.Counterparty AS Counterparty,
	|	Prepayments.Contract AS Contract,
	|	Prepayments.ARAPObject AS ARAPObject,
	|	Prepayments.ExhDirectionOfActivity AS ExhDirectionOfActivity,
	|	Prepayments.ExCounterparty AS ExCounterparty,
	|	Prepayments.Exodus AS Exodus,
	|	Prepayments.ARAPDocument AS ARAPDocument,
	|	Prepayments.InitialAccountingAnalyticsForPartners AS InitialAccountingAnalyticsForPartners,
	|	Prepayments.SourceObjectOfCalculations_ AS SourceObjectOfCalculations_,
	|	Prepayments.AdvanceDate AS AdvanceDate,
	|	Prepayments.MaturityDate AS MaturityDate,
	|	Prepayments.DocumentCurrency AS DocumentCurrency,
	|	Prepayments.DocumentRecorder AS DocumentRecorder,
	|	Prepayments.SumCurr AS SumCurr,
	|	Prepayments.SumMan AS SumMan,
	|	Prepayments.SumCompl AS SumCompl,
	|	Prepayments.Sum AS Sum
	|INTO AdvancesReceivedByRepaymentsAndBalances
	|FROM
	|	(SELECT
	|		RepaymentOfAdvances.Organization AS Organization,
	|		RepaymentOfAdvances.LineOfBusiness AS LineOfBusiness,
	|		RepaymentOfAdvances.Counterparty AS Counterparty,
	|		RepaymentOfAdvances.Contract AS Contract,
	|		RepaymentOfAdvances.ARAPObject AS ARAPObject,
	|		RepaymentOfAdvances.ExhDirectionOfActivity AS ExhDirectionOfActivity,
	|		RepaymentOfAdvances.ExCounterparty AS ExCounterparty,
	|		RepaymentOfAdvances.Exodus AS Exodus,
	|		RepaymentOfAdvances.ARAPDocument AS ARAPDocument,
	|		RepaymentOfAdvances.InitialAccountingAnalyticsForPartners AS InitialAccountingAnalyticsForPartners,
	|		RepaymentOfAdvances.SourceObjectOfCalculations_ AS SourceObjectOfCalculations_,
	|		RepaymentOfAdvances.AdvanceDate AS AdvanceDate,
	|		RepaymentOfAdvances.MaturityDate AS MaturityDate,
	|		MAX(RepaymentOfAdvances.DocumentCurrency) AS DocumentCurrency,
	|		RepaymentOfAdvances.DocumentRecorder AS DocumentRecorder,
	|		SUM(RepaymentOfAdvances.RepaymentAmountVal) AS SumCurr,
	|		SUM(RepaymentOfAdvances.ManRepaymentAmount) AS SumMan,
	|		SUM(RepaymentOfAdvances.LocalRepaymentAmount) AS SumCompl,
	|		SUM(RepaymentOfAdvances.RepaymentAmount) AS Sum
	|	FROM
	|		SettlementsWithCustomers_RepaymentOfAdvances AS RepaymentOfAdvances
	|	GROUP BY
	|		RepaymentOfAdvances.Organization,
	|		RepaymentOfAdvances.LineOfBusiness,
	|		RepaymentOfAdvances.Counterparty,
	|		RepaymentOfAdvances.Contract,
	|		RepaymentOfAdvances.ARAPObject,
	|		RepaymentOfAdvances.ExhDirectionOfActivity,
	|		RepaymentOfAdvances.ExCounterparty,
	|		RepaymentOfAdvances.Exodus,
	|		RepaymentOfAdvances.ARAPDocument,
	|		RepaymentOfAdvances.DocumentRecorder,
	|		RepaymentOfAdvances.AdvanceDate,
	|		RepaymentOfAdvances.MaturityDate,
	|		RepaymentOfAdvances.InitialAccountingAnalyticsForPartners,
	|		RepaymentOfAdvances.SourceObjectOfCalculations_
	|
	|	UNION ALL
	|
	|	SELECT
	|		ReceiptOfAdvances.Organization AS Organization,
	|		ReceiptOfAdvances.LineOfBusiness AS LineOfBusiness,
	|		ReceiptOfAdvances.Counterparty AS Counterparty,
	|		ReceiptOfAdvances.Contract AS Contract,
	|		ReceiptOfAdvances.ARAPObject AS ARAPObject,
	|		ReceiptOfAdvances.LineOfBusiness AS ExhDirectionOfActivity,
	|		ReceiptOfAdvances.Counterparty AS ExCounterparty,
	|		ReceiptOfAdvances.Contract AS Exodus,
	|		ReceiptOfAdvances.ARAPDocument AS ARAPDocument,
	|		ReceiptOfAdvances.AccountingDimensionByPartners AS InitialAccountingAnalyticsForPartners,
	|		ReceiptOfAdvances.ARAPObject AS SourceObjectOfCalculations_,
	|		ReceiptOfAdvances.AdvanceDate AS AdvanceDate,
	|		DATETIME(1, 1, 1) AS MaturityDate,
	|		MAX(ReceiptOfAdvances.DocumentCurrency) AS DocumentCurrency,
	|		UNDEFINED AS DocumentRecorder,
	|		SUM(ReceiptOfAdvances.AdvanceAmountVal - ISNULL(RepaymentOfAdvances.RepaymentAmountVal, 0)) AS SumCurr,
	|		SUM(ReceiptOfAdvances.AdvanceAmountOfMan - ISNULL(RepaymentOfAdvances.ManRepaymentAmount, 0)) AS SumMan,
	|		SUM(ReceiptOfAdvances.AmountOfSchedAdvance - ISNULL(RepaymentOfAdvances.LocalRepaymentAmount, 0)) AS SumCompl,
	|		SUM(ReceiptOfAdvances.AdvanceAmount - ISNULL(RepaymentOfAdvances.RepaymentAmount, 0)) AS Sum
	|	FROM
	|		AdvanceReceipts_Collapsed AS ReceiptOfAdvances
	|			LEFT JOIN RepaymentsOfAdvances_Collapsed AS RepaymentOfAdvances
	|			ON ReceiptOfAdvances.ARAPDocument = RepaymentOfAdvances.ARAPDocument
	|			AND ReceiptOfAdvances.ARAPObject = RepaymentOfAdvances.SourceObjectOfCalculations_
	|			AND ReceiptOfAdvances.AccountingDimensionByPartners = RepaymentOfAdvances.InitialAccountingAnalyticsForPartners
	|			AND ReceiptOfAdvances.AdvanceDate = RepaymentOfAdvances.AdvanceDate
	|	WHERE
	|		&NewOnlineARAPAccounting = TRUE
	|
	|	GROUP BY
	|		ReceiptOfAdvances.Organization,
	|		ReceiptOfAdvances.LineOfBusiness,
	|		ReceiptOfAdvances.Counterparty,
	|		ReceiptOfAdvances.Contract,
	|		ReceiptOfAdvances.ARAPObject,
	|		ReceiptOfAdvances.ARAPDocument,
	|		ReceiptOfAdvances.AdvanceDate,
	|		ReceiptOfAdvances.AccountingDimensionByPartners
	|
	|	UNION ALL
	|
	|	SELECT
	|		AdvanceData.Organization,
	|		AdvanceData.LineOfBusiness,
	|		AdvanceData.Counterparty,
	|		AdvanceData.Contract,
	|		AdvanceData.ARAPObject,
	|		AdvanceData.ExhDirectionOfActivity,
	|		AdvanceData.ExCounterparty,
	|		AdvanceData.Exodus,
	|		AdvanceData.ARAPDocument,
	|		AdvanceData.InitialAccountingAnalyticsForPartners,
	|		AdvanceData.SourceObjectOfCalculations_,
	|		AdvanceData.AdvanceDate,
	|		DATETIME(1, 1, 1) AS MaturityDate,
	|		MAX(AdvanceData.DocumentCurrency) AS DocumentCurrency,
	|		UNDEFINED AS DocumentRecorder,
	|		-SUM(CASE
	|			WHEN BalancesOnAdvances.ARAPDocument REFS Document.CashAccountReceiptNote
	|			AND CAST(BalancesOnAdvances.ARAPDocument AS
	|				Document.CashAccountReceiptNote).Currency = AdvanceData.Organization.LocalAccountingCurrency
	|				THEN BalancesOnAdvances.PrepaymentLocalBalance
	|			WHEN BalancesOnAdvances.ARAPDocument REFS Document.BankAccountReceiptNote
	|			AND CAST(BalancesOnAdvances.ARAPDocument AS
	|				Document.BankAccountReceiptNote).Currency = AdvanceData.Organization.LocalAccountingCurrency
	|				THEN BalancesOnAdvances.PrepaymentLocalBalance
	|			ELSE BalancesOnAdvances.PrepaymentBalance + BalancesOnAdvances.ForReturnBalance
	|		END) AS SumCurr,
	|		-SUM(BalancesOnAdvances.PrepaymentManBalance) AS SumMan,
	|		-SUM(BalancesOnAdvances.PrepaymentLocalBalance) AS SumCompl,
	|		-SUM(BalancesOnAdvances.PrepaymentBalance + BalancesOnAdvances.ForReturnBalance) AS Sum
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&EndDateIncluding,
	|		NOT &NewOnlineARAPAccounting
	|		AND (AccountingDimensionByPartners, SalesOrder, ARAPDocument) IN
	|			(SELECT
	|				AdvanceData.AccountingDimensionByPartners,
	|				AdvanceData.ARAPObject,
	|				AdvanceData.ARAPDocument
	|			FROM
	|				DataOnAdvancesReceived AS AdvanceData)) AS BalancesOnAdvances
	|			INNER JOIN DataOnAdvancesReceived AS AdvanceData
	|			ON BalancesOnAdvances.AccountingDimensionByPartners = AdvanceData.AccountingDimensionByPartners
	|			AND BalancesOnAdvances.SalesOrder = AdvanceData.ARAPObject
	|			AND BalancesOnAdvances.ARAPDocument = AdvanceData.ARAPDocument
	|	GROUP BY
	|		AdvanceData.Organization,
	|		AdvanceData.LineOfBusiness,
	|		AdvanceData.Counterparty,
	|		AdvanceData.Contract,
	|		AdvanceData.ARAPObject,
	|		AdvanceData.ExhDirectionOfActivity,
	|		AdvanceData.ExCounterparty,
	|		AdvanceData.Exodus,
	|		AdvanceData.ARAPDocument,
	|		AdvanceData.InitialAccountingAnalyticsForPartners,
	|		AdvanceData.SourceObjectOfCalculations_,
	|		AdvanceData.AdvanceDate) AS Prepayments
	|WHERE
	|	TRUE
	|	AND (Prepayments.AdvanceDate BETWEEN &StartDate AND &EndDate)
	|	AND Prepayments.SumCurr <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DataOnAdvancesReceived
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SettlementsWithCustomers_Advances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SettlementsWithCustomers_RepaymentOfAdvances
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RepaymentsOfAdvances_Collapsed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP AdvanceReceipts_Collapsed
	|";
	
	SetIndexFields(Query, CalculationParameters, "AdvancesReceivedByRepaymentsAndBalances");
	
	PathParameters = InitializeParametersForSelectingAdvances_FieldPathsAndReplacementText();
	ProcessRequestTextForSelectingAdvancesBasedOnParameters(Query, CalculationParameters, PathParameters);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#Region PrepaymentsToVendor

// Prepare a temporary table "computersposters_avances"
// Creates a temporary table with the columns:
// 	  Calculation document;
// 	  Document Recorder;
// 	  Organization;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Directions of activity;
// 	  Counterparty;
// 	  Contract;
// 	  Datavance;
// 	  Document currency;
// 	  SummaAvancaVal - the amount in the document currency;
// 	  SummaAvance;
// 	  SummaAvansaUpr;
// 	  SummaAvansaRegl.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_SettlementsWithSuppliers_Advances(TempTablesManager, CalculationParameters) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	SetRequestParametersForPreparationOfAdvancePayments(Query, CalculationParameters);
	
	Query.Text =
	"// New settlement architecture
	|SELECT
	|	Calculations.ARAPDocument AS ARAPDocument,
	|	Calculations.DocumentRecorder AS DocumentRecorder,
	|	Calculations.ARAPObject.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	Calculations.ARAPObject.Counterparty AS Counterparty,
	|	Calculations.ARAPObject.Contract AS Contract,
	|	MIN(SelectionOfAdvances.AdvanceDate) AS AdvanceDate,
	|	MAX(CASE
	|			WHEN Calculations.ARAPDocument REFS Document.CashVoucher
	|				THEN CAST(Calculations.ARAPDocument AS Document.CashVoucher).Currency
	|			WHEN Calculations.ARAPDocument REFS Document.BankAccountIssue
	|				THEN CAST(Calculations.ARAPDocument AS Document.BankAccountIssue).Currency
	|			ELSE Calculations.Currency
	|		END) AS DocumentCurrency,
	|	SUM(CASE
	|			WHEN Calculations.ARAPDocument REFS Document.CashVoucher
	|					AND CAST(Calculations.ARAPDocument AS Document.CashVoucher).Currency
	|						= SelectionOfAdvances.LocalAccountingCurrency
	|					AND Calculations.PrepaymentLocal > 0
	|				THEN Calculations.PrepaymentLocal
	|			WHEN Calculations.ARAPDocument REFS Document.BankAccountIssue
	|					AND CAST(Calculations.ARAPDocument AS Document.BankAccountIssue).Currency
	|						= SelectionOfAdvances.LocalAccountingCurrency
	|					AND Calculations.PrepaymentLocal > 0
	|				THEN Calculations.PrepaymentLocal
	|			ELSE Calculations.Prepayment
	|		END
	|		* CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AdvanceAmountVal,
	|	SUM(Calculations.Prepayment * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AdvanceAmount,
	|	SUM(Calculations.PrepaymentMan * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AdvanceAmountOfMan,
	|	SUM(Calculations.PrepaymentLocal * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AmountOfSchedAdvance
	|INTO SettlementsWithSuppliers_Advances
	|FROM
	|	(SELECT
	|		Calculations.ARAPDocument,
	|		Calculations.DocumentRecorder,
	|		Calculations.ARAPObject.Organization AS Organization,
	|		Calculations.ARAPObject.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|		MIN(Calculations.OccurrenceDate) AS AdvanceDate
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|	WHERE
	|		&NewOnlineARAPAccounting
	|		AND NOT &CreateEmptyTable
	|		AND Calculations.Period BETWEEN &StartDate AND &EndDate
	|		AND (NOT &EnableOrganizationSelection
	|			OR Calculations.ARAPObject.Organization IN (&Companies))
	|		AND (&TextSelectionByParameters)
	|		AND Calculations.OccurrenceDate BETWEEN &StartDate AND &EndDate
	|		AND Calculations.Active  = TRUE
	|		
	|	GROUP BY
	|		Calculations.ARAPDocument,
	|		Calculations.DocumentRecorder,
	|		Calculations.ARAPObject.Organization,
	|		Calculations.ARAPObject.Organization.LocalAccountingCurrency
	|	
	|	HAVING
	|		SUM(Calculations.Prepayment * CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -1
	|			ELSE 1
	|		END * CASE
	|		WHEN Calculations.ReversingEntry
	|			THEN -1
	|			ELSE 1
	|		END) > 0
	|	
	|	) AS SelectionOfAdvances
	|
	|	INNER JOIN 
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|	ON
	|		SelectionOfAdvances.DocumentRecorder    = Calculations.DocumentRecorder
	|		AND  SelectionOfAdvances.ARAPDocument   = Calculations.ARAPDocument
	|		AND  SelectionOfAdvances.Organization         = Calculations.ARAPObject.Organization
	|		AND  Calculations.Period BETWEEN &StartDate AND &EndDate
	|		AND  Calculations.OccurrenceDate BETWEEN &StartDate AND &EndDate
	|		AND  Calculations.Active  = TRUE
	|
	|WHERE
	|	TRUE
	|	AND (CAST(Calculations.ARAPDocument AS Document.BankAccountIssue).ProcessedByBank
	|			OR NOT Calculations.ARAPDocument REFS Document.BankAccountIssue)
	|	
	|GROUP BY
	|	Calculations.ARAPDocument,
	|	Calculations.DocumentRecorder,
	|	Calculations.ARAPObject.Organization,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject
	|
	|HAVING
	|	SUM(Calculations.Prepayment * CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -1
	|			ELSE 1
	|		END * CASE
	|		WHEN Calculations.ReversingEntry
	|			THEN -1
	|			ELSE 1
	|		END) > 0
	|
	|UNION ALL
	|
	|// The old architecture of mutual settlements
	|SELECT
	|	Calculations.ARAPDocument AS ARAPDocument,
	|	Calculations.Recorder AS DocumentRecorder,
	|	Calculations.AccountingDimensionByPartners.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.PurchaseOrder AS ARAPObject,
	|	Calculations.PurchaseOrder.LineOfBusiness AS LineOfBusiness,
	|	Calculations.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	Calculations.AccountingDimensionByPartners.Contract AS Contract,
	|	MIN(Calculations.Period) AS AdvanceDate,
	|	MAX(CASE
	|			WHEN Calculations.ARAPDocument REFS Document.CashVoucher
	|				THEN CAST(Calculations.ARAPDocument AS Document.CashVoucher).Currency
	|			WHEN Calculations.ARAPDocument REFS Document.BankAccountIssue
	|				THEN CAST(Calculations.ARAPDocument AS Document.BankAccountIssue).Currency
	|			ELSE Calculations.Currency
	|		END) AS DocumentCurrency,
	|	SUM(CASE
	|			WHEN Calculations.ARAPDocument REFS Document.CashVoucher
	|					AND CAST(Calculations.ARAPDocument AS Document.CashVoucher).Currency
	|						= SelectionOfAdvances.LocalAccountingCurrency
	|					AND Calculations.PrepaymentLocal > 0
	|				THEN Calculations.PrepaymentLocal
	|			WHEN Calculations.ARAPDocument REFS Document.BankAccountIssue
	|					AND CAST(Calculations.ARAPDocument AS Document.BankAccountIssue).Currency
	|						= SelectionOfAdvances.LocalAccountingCurrency
	|					AND Calculations.PrepaymentLocal > 0
	|				THEN Calculations.PrepaymentLocal
	|			ELSE (Calculations.Prepayment + Calculations.ForReturn)
	|		END
	|		* CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			ELSE 1
	|		END) AS AdvanceAmountVal,
	|	SUM((Calculations.Prepayment + Calculations.ForReturn) * CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|		END) AS AdvanceAmount,
	|	SUM(Calculations.PrepaymentMan * CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|		END) AS AdvanceAmountOfMan,
	|	SUM(Calculations.PrepaymentLocal * CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|		END) AS AmountOfSchedAdvance
	|FROM
	|	(SELECT
	|		Calculations.ARAPDocument AS ARAPDocument,
	|		Calculations.Recorder AS DocumentRecorder,
	|		Calculations.AccountingDimensionByPartners.Organization AS Organization,
	|		Calculations.AccountingDimensionByPartners.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|	WHERE
	|		NOT &NewOnlineARAPAccounting
	|		AND NOT &CreateEmptyTable
	|		AND Calculations.Period BETWEEN &StartDate AND &EndDate
	|		AND (NOT &EnableOrganizationSelection
	|			OR Calculations.AccountingDimensionByPartners.Organization IN (&Companies))
	|		AND (&TextSelectionByParameters)
	|		AND Calculations.Active = TRUE
	|
	|	GROUP BY
	|		Calculations.AccountingDimensionByPartners.Organization,
	|		Calculations.Recorder,
	|		Calculations.ARAPDocument,
	|		Calculations.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
	|
	|	HAVING
	|		SUM((Calculations.Prepayment + Calculations.ForReturn) *
	|			CASE
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|					THEN -1
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN 1
	|			END) > 0
	|
	|	) AS SelectionOfAdvances
	|
	|	INNER JOIN 
	|		AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|	ON
	|		SelectionOfAdvances.DocumentRecorder    = Calculations.Recorder
	|		AND  SelectionOfAdvances.ARAPDocument   = Calculations.ARAPDocument
	|		AND  SelectionOfAdvances.Organization         = Calculations.AccountingDimensionByPartners.Organization
	|		AND  Calculations.Period BETWEEN &StartDate AND &EndDate
	|		AND  Calculations.Active  = TRUE
	|
	|WHERE
	|	TRUE
	|	AND (CAST(Calculations.ARAPDocument AS Document.BankAccountIssue).ProcessedByBank
	|			OR NOT Calculations.ARAPDocument REFS Document.BankAccountIssue)
	|	
	|GROUP BY
	|	Calculations.ARAPDocument,
	|	Calculations.Recorder,
	|	Calculations.AccountingDimensionByPartners.Organization,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.PurchaseOrder,
	|	Calculations.PurchaseOrder.LineOfBusiness,
	|	Calculations.AccountingDimensionByPartners.Counterparty
	|
	|HAVING
	|	SUM((Calculations.Prepayment + Calculations.ForReturn) * CASE 
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -1
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 1
	|		END) > 0
	|
	|INDEX BY
	|	ARAPDocument
	|";
	
	SetIndexFields(Query, CalculationParameters, "SettlementsWithSuppliers_Advances");
	
	PathParameters = InitializeParametersForSelectingAdvances_FieldPathsAndReplacementText();
	ProcessRequestTextForSelectingAdvancesBasedOnParameters(Query, CalculationParameters, PathParameters);
	
	Query.Execute();
	
EndProcedure

// Prepare a temporary table "Settlements by suppliers_Repayment of balances"
// Creates a temporary table with columns:
// 	  Calculation document;
// 	  Organization;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Document Recorder;
// 	  Counterparty;
// 	  Contract;
// 	  Directions of activity;
// 	  Iscontragent - the counterparty for which the advance arose;
// 	  IshDogovor - Contract Under Which there Was an advance;
// 	  From the direction of activity - the direction in which the advance arose;
// 	  Coralitikauchetapopartners;
// 	  Initial analyticsaccounts to partners - analytics for which an advance was formed;
// 	  Account Object Box;
// 	  Initial account objectobject - the settlement object for which the advance payment was generated;
// 	  Datavance;
// 	  Data settlement;
// 	  EVENTSNAK - If the repayment occurred due to the offset of the advance, then EVENTSNAK >= 0,
// 	                If the repayment occurred due to the repayment/write-off of debt, then EVENTSNAK < 0;
// 	  Type of event - the event in connection with which the advance payment occurred. Possible events:
// 	         - Enumeration.Economic operations.Return of the supplier's moneyreferences,
// 	         - Enumeration.Economic operations.Offsetting to the supplier;
// 	  Document currency;
// 	  Repayment totals;
// 	  Repayment Amount - the amount in the document currency;
// 	  The sum of the repayment of the;
// 	  The sum of the cancellation rules.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_SettlementsWithSuppliers_RepaymentOfAdvances(TempTablesManager, CalculationParameters) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	SetRequestParametersForPreparationOfAdvancePayments(Query, CalculationParameters);
	
	Query.Text =
	"// New settlement architecture
	|SELECT
	|	Calculations.ARAPDocument AS ARAPDocument,
	|	Calculations.DocumentRecorder AS DocumentRecorder,
	|	Calculations.ARAPObject.Organization AS Organization,
	|	Calculations.ARAPObject.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	MIN(Calculations.OccurrenceDate) AS AdvanceDate,
	|	MAX(Calculations.Period) AS MaturityDate,
	|		SUM(CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 0
	|			WHEN Calculations.BusinessOperation IN
	|					(VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement),
	|					VALUE(Enum.BusinessTransactions.SettlementOfPrepayment),
	|					VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno))
	|				THEN Calculations.Prepayment
	|			ELSE
	|				-Calculations.Prepayment
	|		END) AS EventSign,
	|	SUM(Calculations.Prepayment * CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -1
	|		ELSE 1
	|	END) AS RepaymentAmount,
	|	NOT ARAPSettlement.Ref IS NULL AS SettlementOfPrepayment
	|
	|INTO SelectionOfAdvanceRepayments
	|
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|		LEFT JOIN Document.ARAPSettlement AS ARAPSettlement
	|		ON Calculations.DocumentRecorder = ARAPSettlement.Ref
	|			AND (ARAPSettlement.OperationKind IN (&TypesOfOperationsOfAdvanceTransfer))
	|WHERE
	|	&NewOnlineARAPAccounting
	|	AND NOT &CreateEmptyTable
	|	AND (NOT &EnableOrganizationSelection
	|			OR Calculations.ARAPObject.Organization IN (&Companies))
	|	AND &TextSelectionByParameters
	|	AND Calculations.Period BETWEEN &StartDate AND &EndDate
	|	AND Calculations.Active = TRUE
	|
	|GROUP BY
	|	Calculations.ARAPDocument,
	|	Calculations.DocumentRecorder,
	|	Calculations.ARAPObject.Organization,
	|	Calculations.ARAPObject.Organization.LocalAccountingCurrency,
	|	NOT ARAPSettlement.Ref IS NULL
	|
	|HAVING
	|	SUM(Calculations.Prepayment * CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -1
	|			ELSE 1
	|		END * CASE
	|		WHEN Calculations.ReversingEntry
	|			THEN -1
	|			ELSE 1
	|		END) > 0
	|
	|UNION ALL
	|
	|//The old architecture of mutual settlements
	|SELECT
	|	Calculations.ARAPDocument AS ARAPDocument,
	|	Calculations.Recorder AS DocumentRecorder,
	|	Calculations.AccountingDimensionByPartners.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	NULL AS AdvanceDate,
	|	Calculations.Period AS MaturityDate,
	|	SUM(CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 0
	|			WHEN Calculations.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement),
	|					VALUE(Enum.BusinessTransactions.SettlementOfPrepayment),
	|					VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno)
	|					)
	|				THEN Calculations.PrepaymentLocal
	|			ELSE
	|				-Calculations.PrepaymentLocal
	|		END) AS EventSign,
	|	SUM(Calculations.PrepaymentLocal * CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -1
	|		ELSE 1
	|		END) AS RepaymentAmount,
	|	FALSE AS SettlementOfPrepayment
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|WHERE
	|	NOT &NewOnlineARAPAccounting
	|	AND NOT &CreateEmptyTable
	|	AND (NOT &EnableOrganizationSelection
	|			OR Calculations.AccountingDimensionByPartners.Organization IN (&Companies))
	|	AND &TextSelectionByParameters
	|	AND Calculations.Period BETWEEN &StartDate AND &EndDate
	|	AND Calculations.Active = TRUE
	|
	|GROUP BY
	|	Calculations.ARAPDocument,
	|	Calculations.Recorder,
	|	Calculations.AccountingDimensionByPartners.Organization,
	|	Calculations.AccountingDimensionByPartners.Organization.LocalAccountingCurrency,
	|	Calculations.Period
	|
	|HAVING
	|	SUM(Calculations.PrepaymentLocal * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) > 0
	|
	|INDEX BY
	|	ARAPDocument,
	|	DocumentRecorder,
	|	Organization,
	|	LocalAccountingCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculations_Receipt.ARAPDocument AS ARAPDocument,
	|	Calculations.ARAPObject.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.DocumentRecorder AS DocumentRecorder,
	|	Calculations.ARAPObject.Counterparty AS Counterparty,
	|	Calculations.ARAPObject.Contract AS Contract,
	|	Calculations.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN NOT Calculations.CorARAPObject = &EmptyCalculationObject
	|		AND NOT ISNULL(Calculations.CorARAPObject.Object = UNDEFINED, TRUE)
	|			THEN Calculations.CorARAPObject.Counterparty
	|		ELSE Calculations.ARAPObject.Counterparty
	|	END AS ExCounterparty,
	|	CASE
	|		WHEN NOT Calculations.CorARAPObject = &EmptyCalculationObject
	|		AND NOT ISNULL(Calculations.CorARAPObject.Object = UNDEFINED, TRUE)
	|			THEN Calculations.CorARAPObject.Contract
	|		ELSE Calculations.ARAPObject.Contract
	|	END AS Exodus,
	|	CASE
	|		WHEN NOT Calculations.CorARAPObject = &EmptyCalculationObject
	|		AND NOT ISNULL(Calculations.CorARAPObject.Object = UNDEFINED, TRUE)
	|			THEN Calculations.CorARAPObject.LineOfBusiness
	|		ELSE Calculations.ARAPObject.LineOfBusiness
	|	END AS ExhDirectionOfActivity,
	|	Calculations.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	CASE
	|		WHEN Calculations.CorPartnerAccountingDimension <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|			THEN Calculations.CorPartnerAccountingDimension
	|		ELSE Calculations.AccountingDimensionByPartners
	|	END AS ExAnalyticsOfACCOUNTINGByPartners,
	|	Calculations.CorARAPObject AS CorARAPObject,
	|	CASE
	|		WHEN NOT Calculations.CorARAPObject = &EmptyCalculationObject
	|		AND NOT ISNULL(Calculations.CorARAPObject.Object = UNDEFINED, TRUE)
	|			THEN Calculations.CorARAPObject
	|		ELSE Calculations.ARAPObject
	|	END AS SourceObjectOfCalculations_,
	|	SelectionOfAdvanceRepayments.AdvanceDate AS AdvanceDate,
	|	SelectionOfAdvanceRepayments.MaturityDate AS MaturityDate,
	|	SelectionOfAdvanceRepayments.EventSign AS EventSign,
	|	CASE
	|		WHEN
	|			Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromVendor)
	|			THEN VALUE(Enum.BusinessTransactions.RefundFromVendor)
	|		WHEN Calculations.BusinessOperation IN (VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement),
	|											VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno))
	|			THEN VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement)
	|		ELSE UNDEFINED
	|	END AS EventKind,
	|	CASE
	|		WHEN Calculations_Receipt.ARAPDocument REFS Document.CashVoucher
	|			THEN CAST(Calculations_Receipt.ARAPDocument AS Document.CashVoucher).Currency
	|		WHEN Calculations_Receipt.ARAPDocument REFS Document.BankAccountIssue
	|			THEN CAST(Calculations_Receipt.ARAPDocument AS Document.BankAccountIssue).Currency
	|		ELSE Calculations.Currency
	|	END AS DocumentCurrency,
	|	CASE
	|		WHEN Calculations_Receipt.ARAPDocument REFS Document.CashVoucher
	|		AND CAST(Calculations_Receipt.ARAPDocument AS
	|			Document.CashVoucher).Currency = SelectionOfAdvanceRepayments.LocalAccountingCurrency
	|		AND Calculations.DebtLocal > 0
	|			THEN Calculations.DebtLocal
	|		WHEN Calculations_Receipt.ARAPDocument REFS Document.BankAccountIssue
	|		AND CAST(Calculations_Receipt.ARAPDocument AS
	|			Document.BankAccountIssue).Currency = SelectionOfAdvanceRepayments.LocalAccountingCurrency
	|		AND Calculations.DebtLocal > 0
	|			THEN Calculations.DebtLocal
	|		ELSE Calculations.Debt
	|	END AS RepaymentAmountVal,
	|	Calculations.Debt AS RepaymentAmount,
	|	Calculations.ARAPMan AS ManRepaymentAmount,
	|	Calculations.DebtLocal AS LocalRepaymentAmount
	|INTO SettlementsWithSuppliers_RepaymentWithImplicitOffset
	|FROM
	|	SelectionOfAdvanceRepayments AS SelectionOfAdvanceRepayments
	|		INNER JOIN AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|		ON SelectionOfAdvanceRepayments.DocumentRecorder = Calculations.DocumentRecorder
	|		AND SelectionOfAdvanceRepayments.Organization = Calculations.ARAPObject.Organization
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Calculations.Period BETWEEN &StartDate AND &EndDate
	|		AND Calculations.Active = TRUE
	|		AND Calculations.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment)
	|		AND NOT Calculations.ReversingEntry
	|		AND Calculations.Debt > 0
	|		AND SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|		AND &NewOnlineARAPAccounting
	|		INNER JOIN AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations_Receipt
	|		ON Calculations_Receipt.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND SelectionOfAdvanceRepayments.ARAPDocument = Calculations_Receipt.ARAPDocument
	|		AND Calculations.ARAPObject = Calculations_Receipt.ARAPObject
	|		AND Calculations.AccountingDimensionByPartners = Calculations_Receipt.AccountingDimensionByPartners
	|		AND Calculations.DocumentRecorder = Calculations_Receipt.DocumentRecorder
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPDocument,
	|	DocumentCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// New settlement architecture
	|SELECT
	|	NestedQuery.ARAPDocument AS ARAPDocument,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.DocumentRecorder AS DocumentRecorder,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Contract AS Contract,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.ReversingEntry AS ReversingEntry,
	|	MAX(NestedQuery.ExCounterparty) AS ExCounterparty,
	|	MAX(NestedQuery.Exodus) AS Exodus,
	|	MAX(NestedQuery.ExhDirectionOfActivity) AS ExhDirectionOfActivity,
	|	MAX(NestedQuery.CorPartnerAccountingDimension) AS CorPartnerAccountingDimension,
	|	MAX(NestedQuery.InitialAccountingAnalyticsForPartners) AS InitialAccountingAnalyticsForPartners,
	|	MAX(NestedQuery.CorARAPObject) AS CorARAPObject,
	|	MAX(NestedQuery.SourceObjectOfCalculations_) AS SourceObjectOfCalculations_,
	|	MIN(NestedQuery.AdvanceDate) AS AdvanceDate,
	|	MAX(NestedQuery.MaturityDate) AS MaturityDate,
	|	MAX(NestedQuery.EventSign) AS EventSign,
	|	MAX(NestedQuery.EventKind) AS EventKind,
	|	MAX(NestedQuery.DocumentCurrency) AS DocumentCurrency,
	|	SUM(NestedQuery.RepaymentAmountVal) AS RepaymentAmountVal,
	|	SUM(NestedQuery.RepaymentAmount) AS RepaymentAmount,
	|	SUM(NestedQuery.ManRepaymentAmount) AS ManRepaymentAmount,
	|	SUM(NestedQuery.LocalRepaymentAmount) AS LocalRepaymentAmount
	|INTO SettlementsWithSuppliers_RepaymentOfAdvances_Preliminary
	|FROM
	|	(SELECT
	|		NestedQuery.ARAPDocument AS ARAPDocument,
	|		NestedQuery.ARAPObject.Organization AS Organization,
	|		NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		NestedQuery.ARAPObject AS ARAPObject,
	|		NestedQuery.DocumentRecorder AS DocumentRecorder,
	|		NestedQuery.ARAPObject.Counterparty AS Counterparty,
	|		NestedQuery.ARAPObject.Contract AS Contract,
	|		NestedQuery.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|		NestedQuery.ReversingEntry AS ReversingEntry,
	|		MAX(CASE
	|			WHEN NOT NestedQuery.CorARAPObject = &EmptyCalculationObject
	|					AND NOT ISNULL(NestedQuery.CorARAPObject.Object = UNDEFINED, TRUE)
	|				THEN NestedQuery.CorARAPObject.Counterparty
	|			ELSE NestedQuery.ARAPObject.Counterparty
	|		END) AS ExCounterparty,
	|		MAX(CASE
	|			WHEN NOT NestedQuery.CorARAPObject = &EmptyCalculationObject
	|					AND NOT ISNULL(NestedQuery.CorARAPObject.Object = UNDEFINED, TRUE)
	|				THEN NestedQuery.CorARAPObject.Contract
	|			ELSE NestedQuery.ARAPObject.Contract
	|		END) AS Exodus,
	|		MAX(CASE
	|			WHEN NOT NestedQuery.CorARAPObject = &EmptyCalculationObject
	|					AND NOT ISNULL(NestedQuery.CorARAPObject.Object = UNDEFINED, TRUE)
	|				THEN NestedQuery.CorARAPObject.LineOfBusiness
	|			ELSE NestedQuery.ARAPObject.LineOfBusiness
	|		END) AS ExhDirectionOfActivity,
	|		MAX(NestedQuery.CorPartnerAccountingDimension) AS CorPartnerAccountingDimension,
	|		CASE
	|			WHEN NestedQuery.CorPartnerAccountingDimension <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|				THEN NestedQuery.CorPartnerAccountingDimension
	|			ELSE NestedQuery.AccountingDimensionByPartners
	|		END AS InitialAccountingAnalyticsForPartners,
	|		MAX(NestedQuery.CorARAPObject) AS CorARAPObject,
	|		MAX(CASE
	|			WHEN NOT NestedQuery.CorARAPObject = &EmptyCalculationObject
	|					AND NOT ISNULL(NestedQuery.CorARAPObject.Object = UNDEFINED, TRUE)
	|				THEN NestedQuery.CorARAPObject
	|			ELSE NestedQuery.ARAPObject
	|		END) AS SourceObjectOfCalculations_,
	|		MIN(NestedQuery.AdvanceDate) AS AdvanceDate,
	|		MAX(NestedQuery.MaturityDate) AS MaturityDate,
	|		MAX(NestedQuery.EventSign) AS EventSign,
	|		MAX(NestedQuery.EventKind) AS EventKind,
	|		MAX(NestedQuery.DocumentCurrency) AS DocumentCurrency,
	|		SUM(NestedQuery.RepaymentAmountVal) AS RepaymentAmountVal,
	|		SUM(NestedQuery.RepaymentAmount) AS RepaymentAmount,
	|		SUM(NestedQuery.ManRepaymentAmount) AS ManRepaymentAmount,
	|		SUM(NestedQuery.LocalRepaymentAmount) AS LocalRepaymentAmount
	|	FROM
	|		(SELECT
	|			Calculations.ARAPDocument AS ARAPDocument,
	|			CASE
	|				WHEN SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|						AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN Calculations.CorPartnerAccountingDimension
	|				ELSE Calculations.AccountingDimensionByPartners
	|			END AS AccountingDimensionByPartners,
	|			CASE
	|				WHEN SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|					AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.CorARAPObject
	|			ELSE Calculations.ARAPObject
	|			END AS ARAPObject,
	|			Calculations.DocumentRecorder AS DocumentRecorder,
	|			Calculations.ReversingEntry AS ReversingEntry,
	|			MAX(CASE
	|				WHEN SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|						AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN UNDEFINED
	|				ELSE Calculations.CorARAPObject
	|			END) AS CorARAPObject,
	|			MAX(CASE
	|				WHEN SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|						AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN UNDEFINED
	|				ELSE Calculations.CorPartnerAccountingDimension
	|			END) AS CorPartnerAccountingDimension,
	|			MIN(SelectionOfAdvanceRepayments.AdvanceDate) AS AdvanceDate,
	|			MAX(SelectionOfAdvanceRepayments.MaturityDate) AS MaturityDate,
	|			MAX(SelectionOfAdvanceRepayments.EventSign) AS EventSign,
	|			MAX(
	|			CASE
	|				WHEN Calculations.BusinessOperation
	|						= VALUE(Enum.BusinessTransactions.RefundFromVendor)
	|					THEN VALUE(Enum.BusinessTransactions.RefundFromVendor)
	|				WHEN Calculations.BusinessOperation
	|						IN (VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement),
	|							VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno))
	|					THEN VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement)
	|				ELSE
	|					UNDEFINED
	|			END) AS EventKind,
	|			MAX(CASE
	|				WHEN Calculations.ARAPDocument REFS Document.CashVoucher
	|					THEN CAST(Calculations.ARAPDocument AS Document.CashVoucher).Currency
	|				WHEN Calculations.ARAPDocument REFS Document.BankAccountIssue
	|					THEN CAST(Calculations.ARAPDocument AS Document.BankAccountIssue).Currency
	|				ELSE Calculations.Currency
	|				END) AS DocumentCurrency,
	|			SUM(CASE
	|				WHEN Calculations.ARAPDocument REFS Document.CashVoucher
	|							AND CAST(Calculations.ARAPDocument AS Document.CashVoucher).Currency
	|							= SelectionOfAdvanceRepayments.LocalAccountingCurrency
	|						AND Calculations.PrepaymentLocal > 0
	|					THEN Calculations.PrepaymentLocal
	|				WHEN Calculations.ARAPDocument REFS Document.BankAccountIssue
	|						AND CAST(Calculations.ARAPDocument AS Document.BankAccountIssue).Currency
	|							= SelectionOfAdvanceRepayments.LocalAccountingCurrency
	|						AND Calculations.PrepaymentLocal > 0
	|					THEN Calculations.PrepaymentLocal
	|				ELSE Calculations.Prepayment
	|				END
	|				* CASE
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN -1
	|				ELSE 1
	|				END) AS RepaymentAmountVal,
	|			SUM(Calculations.Prepayment * CASE
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN -1
	|				ELSE 1
	|				END) AS RepaymentAmount,
	|			SUM(Calculations.PrepaymentMan * CASE
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN -1
	|				ELSE 1
	|				END) AS ManRepaymentAmount,
	|			SUM(Calculations.PrepaymentLocal * CASE
	|				WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN -1
	|				ELSE 1
	|				END) AS LocalRepaymentAmount
	|		FROM
	|			SelectionOfAdvanceRepayments AS SelectionOfAdvanceRepayments
	|				INNER JOIN AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|				ON SelectionOfAdvanceRepayments.DocumentRecorder = Calculations.DocumentRecorder
	|					AND SelectionOfAdvanceRepayments.ARAPDocument = Calculations.ARAPDocument
	|					AND SelectionOfAdvanceRepayments.Organization = Calculations.ARAPObject.Organization
	|					AND (Calculations.Period BETWEEN &StartDate AND &EndDate)
	|					AND (Calculations.Active = TRUE)
	|					AND &NewOnlineARAPAccounting
	|
	|		WHERE
	|			CASE
	|				WHEN NOT SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|					THEN TRUE
	|				ELSE NOT (Calculations.AccountingDimensionByPartners, Calculations.ARAPDocument, Calculations.Currency) IN
	|						(SELECT
	|							VendorsARAPAccounting.AccountingDimensionByPartners,
	|							VendorsARAPAccounting.ARAPDocument,
	|							VendorsARAPAccounting.DocumentCurrency
	|						FROM
	|							SettlementsWithSuppliers_RepaymentWithImplicitOffset AS VendorsARAPAccounting
	|						
	|						UNION ALL
	|
	|						SELECT
	|							VendorsARAPAccounting.CorPartnerAccountingDimension,
	|							VendorsARAPAccounting.ARAPDocument,
	|							VendorsARAPAccounting.DocumentCurrency
	|						FROM
	|							SettlementsWithSuppliers_RepaymentWithImplicitOffset AS VendorsARAPAccounting)
	|			END
	|	
	|		GROUP BY
	|			Calculations.ARAPDocument,
	|			Calculations.DocumentRecorder,
	|			Calculations.ReversingEntry,
	|			CASE
	|				WHEN SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|					AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN Calculations.CorPartnerAccountingDimension
	|				ELSE Calculations.AccountingDimensionByPartners
	|			END,
	|			CASE
	|				WHEN SelectionOfAdvanceRepayments.SettlementOfPrepayment
	|					AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN Calculations.CorARAPObject
	|				ELSE Calculations.ARAPObject
	|			END) AS NestedQuery
	|
	|	GROUP BY
	|		NestedQuery.ARAPDocument,
	|		NestedQuery.ARAPObject.Organization,
	|		NestedQuery.AccountingDimensionByPartners,
	|		NestedQuery.ARAPObject,
	|		NestedQuery.DocumentRecorder,
	|		NestedQuery.ARAPObject.Counterparty,
	|		NestedQuery.ARAPObject.Contract,
	|		NestedQuery.ARAPObject.LineOfBusiness,
	|		NestedQuery.ReversingEntry,
	|		CASE
	|			WHEN NestedQuery.CorPartnerAccountingDimension <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|				THEN NestedQuery.CorPartnerAccountingDimension
	|			ELSE NestedQuery.AccountingDimensionByPartners
	|		END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.ARAPDocument,
	|		Calculations.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.ARAPObject,
	|		Calculations.DocumentRecorder,
	|		Calculations.Counterparty,
	|		Calculations.Contract,
	|		Calculations.LineOfBusiness,
	|		FALSE,
	|		Calculations.ExCounterparty,
	|		Calculations.Exodus,
	|		Calculations.ExhDirectionOfActivity,
	|		Calculations.CorPartnerAccountingDimension,
	|		Calculations.ExAnalyticsOfACCOUNTINGByPartners,
	|		Calculations.CorARAPObject,
	|		Calculations.SourceObjectOfCalculations_,
	|		Calculations.AdvanceDate,
	|		Calculations.MaturityDate,
	|		Calculations.EventSign,
	|		Calculations.EventKind,
	|		Calculations.DocumentCurrency,
	|		Calculations.RepaymentAmountVal,
	|		Calculations.RepaymentAmount,
	|		Calculations.ManRepaymentAmount,
	|		Calculations.LocalRepaymentAmount
	|	FROM
	|		SettlementsWithSuppliers_RepaymentWithImplicitOffset AS Calculations) AS NestedQuery
	|WHERE
	|	CASE
	|		WHEN NestedQuery.ReversingEntry = TRUE
	|			THEN NestedQuery.RepaymentAmount < 0
	|		ELSE NestedQuery.RepaymentAmount > 0
	|	END
	|
	|GROUP BY
	|	NestedQuery.ARAPDocument,
	|	NestedQuery.Organization,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.DocumentRecorder,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Contract,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.ReversingEntry
	|
	|UNION ALL
	|
	|// The old architecture of mutual settlements
	|SELECT
	|	Calculations.ARAPDocument,
	|	Calculations.AccountingDimensionByPartners.Organization,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.PurchaseOrder,
	|	Calculations.Recorder,
	|	Calculations.AccountingDimensionByPartners.Counterparty,
	|	Calculations.AccountingDimensionByPartners.Contract,
	|	Calculations.PurchaseOrder.LineOfBusiness,
	|	FALSE,
	|	Calculations.AccountingDimensionByPartners.Counterparty,
	|	Calculations.AccountingDimensionByPartners.Contract,
	|	Calculations.PurchaseOrder.LineOfBusiness,
	|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef),
	|	Calculations.AccountingDimensionByPartners,
	|	&EmptyCalculationObject,
	|	Calculations.PurchaseOrder,
	|	MIN(Calculations.PaymentDate) AS AdvanceDate,
	|	MAX(SelectionOfAdvanceRepayments.MaturityDate),
	|	MAX(SelectionOfAdvanceRepayments.EventSign),
	|	MAX(
	|		CASE
	|			WHEN SelectionOfAdvanceRepayments.EventSign < 0
	|				THEN VALUE(Enum.BusinessTransactions.RefundFromVendor)
	|			ELSE
	|				VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement)
	|		END) AS EventKind,
	|	MAX(CASE
	|			WHEN Calculations.ARAPDocument REFS Document.CashVoucher
	|				THEN CAST(Calculations.ARAPDocument AS Document.CashVoucher).Currency
	|			WHEN Calculations.ARAPDocument REFS Document.BankAccountIssue
	|				THEN CAST(Calculations.ARAPDocument AS Document.BankAccountIssue).Currency
	|			ELSE Calculations.Currency
	|		END) AS DocumentCurrency,
	|	SUM(CASE
	|			WHEN Calculations.ARAPDocument REFS Document.CashVoucher
	|					AND CAST(Calculations.ARAPDocument AS Document.CashVoucher).Currency
	|						= SelectionOfAdvanceRepayments.LocalAccountingCurrency
	|					AND Calculations.PrepaymentLocal > 0
	|				THEN Calculations.PrepaymentLocal
	|			WHEN Calculations.ARAPDocument REFS Document.BankAccountIssue
	|					AND CAST(Calculations.ARAPDocument AS Document.BankAccountIssue).Currency
	|						= SelectionOfAdvanceRepayments.LocalAccountingCurrency
	|					AND Calculations.PrepaymentLocal > 0
	|				THEN Calculations.PrepaymentLocal
	|			ELSE Calculations.Prepayment
	|		END
	|		* CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) AS RepaymentAmountVal,
	|	SUM(Calculations.Prepayment * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END),
	|	SUM(Calculations.PrepaymentMan * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END),
	|	SUM(Calculations.PrepaymentLocal * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END)
	|FROM
	|	SelectionOfAdvanceRepayments AS SelectionOfAdvanceRepayments
	|		INNER JOIN AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|		ON SelectionOfAdvanceRepayments.DocumentRecorder = Calculations.Recorder
	|			AND SelectionOfAdvanceRepayments.ARAPDocument = Calculations.ARAPDocument
	|			AND SelectionOfAdvanceRepayments.Organization = Calculations.AccountingDimensionByPartners.Organization
	|			AND (Calculations.Period BETWEEN &StartDate AND &EndDate)
	|			AND (Calculations.Active = TRUE)
	|			AND NOT &NewOnlineARAPAccounting
	|
	|GROUP BY
	|	Calculations.ARAPDocument,
	|	Calculations.AccountingDimensionByPartners.Organization,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.PurchaseOrder,
	|	Calculations.Recorder,
	|	Calculations.AccountingDimensionByPartners.Counterparty,
	|	Calculations.AccountingDimensionByPartners.Contract,
	|	Calculations.AccountingDimensionByPartners.LineOfBusiness
	|
	|HAVING
	|	SUM(Calculations.Prepayment * CASE
	|			WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -1
	|			ELSE 1
	|		END) > 0
	|
	|INDEX BY
	|	ARAPDocument,
	|	Organization,
	|	DocumentRecorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Repayments.ARAPDocument AS ARAPDocument,
	|	Repayments.Organization AS Organization,
	|	Repayments.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Repayments.ARAPObject AS ARAPObject,
	|	Repayments.DocumentRecorder AS DocumentRecorder,
	|	Repayments.Counterparty AS Counterparty,
	|	Repayments.Contract AS Contract,
	|	Repayments.LineOfBusiness AS LineOfBusiness,
	|	Repayments.ReversingEntry AS ReversingEntry,
	|	Repayments.ExCounterparty AS ExCounterparty,
	|	Repayments.Exodus AS Exodus,
	|	Repayments.ExhDirectionOfActivity AS ExhDirectionOfActivity,
	|	Repayments.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	Repayments.InitialAccountingAnalyticsForPartners AS InitialAccountingAnalyticsForPartners,
	|	Repayments.CorARAPObject AS CorARAPObject,
	|	Repayments.SourceObjectOfCalculations_ AS SourceObjectOfCalculations_,
	|	Repayments.AdvanceDate AS AdvanceDate,
	|	Repayments.MaturityDate AS MaturityDate,
	|	MAX(Repayments.EventSign) AS EventSign,
	|	MAX(CASE
	|		WHEN Repayments.EventKind = UNDEFINED
	|		// If the type of event could not be identified immediately, we look at secondary signs
	|			THEN CASE
	|				WHEN ISNULL(EventKinds.BusinessOperation, UNDEFINED) =
	|						VALUE(Enum.BusinessTransactions.RefundFromVendor)
	|					THEN VALUE(Enum.BusinessTransactions.RefundFromVendor)
	|				WHEN ISNULL(EventKinds.BusinessOperation, UNDEFINED) IN
	|						(VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement),
	|						VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno))
	|					THEN VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement)
	|				WHEN Repayments.EventSign < 0
	|					THEN VALUE(Enum.BusinessTransactions.RefundFromVendor)
	|				ELSE
	|					VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement)
	|			END
	|		ELSE
	|			Repayments.EventKind
	|	END) AS EventKind,
	|	MAX(Repayments.DocumentCurrency) AS DocumentCurrency,
	|	MAX(Repayments.RepaymentAmount) AS RepaymentAmount,
	|	MAX(Repayments.RepaymentAmountVal) AS RepaymentAmountVal,
	|	MAX(Repayments.ManRepaymentAmount) AS ManRepaymentAmount,
	|	MAX(Repayments.LocalRepaymentAmount) AS LocalRepaymentAmount
	|INTO SettlementsWithSuppliers_RepaymentOfAdvances
	|FROM
	|	SettlementsWithSuppliers_RepaymentOfAdvances_Preliminary AS Repayments
	|	
	|	LEFT JOIN
	|		// We find the type of event if initially it was not possible to identify
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS EventKinds
	|	ON
	|		&NewOnlineARAPAccounting
	|		AND Repayments.EventKind          = UNDEFINED
	|		AND Repayments.DocumentRecorder = EventKinds.DocumentRecorder
	|		AND EventKinds.Period            <= &EndDate
	|		AND EventKinds.RecordType       = VALUE(AccumulationRecordType.Expense)
	|		AND EventKinds.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.RefundFromVendor),
	|			 VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement),
	|			VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno))
	|
	|GROUP BY
	|	Repayments.ARAPDocument,
	|	Repayments.Organization,
	|	Repayments.AccountingDimensionByPartners,
	|	Repayments.ARAPObject,
	|	Repayments.DocumentRecorder,
	|	Repayments.Counterparty,
	|	Repayments.Contract,
	|	Repayments.LineOfBusiness,
	|	Repayments.ReversingEntry,
	|	Repayments.ExCounterparty,
	|	Repayments.Exodus,
	|	Repayments.ExhDirectionOfActivity,
	|	Repayments.CorPartnerAccountingDimension,
	|	Repayments.InitialAccountingAnalyticsForPartners,
	|	Repayments.CorARAPObject,
	|	Repayments.SourceObjectOfCalculations_,
	|	Repayments.AdvanceDate,
	|	Repayments.MaturityDate
	|
	|INDEX BY
	|	ARAPDocument
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SelectionOfAdvanceRepayments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SettlementsWithSuppliers_RepaymentOfAdvances_Preliminary
	|; 
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SettlementsWithSuppliers_RepaymentWithImplicitOffset
	|;
	|";
	
	SetIndexFields(Query, CalculationParameters, "SettlementsWithSuppliers_RepaymentOfAdvances");
	
	PathParameters = InitializeParametersForSelectingAdvances_FieldPathsAndReplacementText();
	ProcessRequestTextForSelectingAdvancesBasedOnParameters(Query, CalculationParameters, PathParameters);
	
	Query.Execute();
	
EndProcedure

// Prepare a temporary table "computationsproviders_transferances"
// Creates a temporary table with columns:
// 	  Organization;
// 	  Document payments;
// 	  Transfer Document;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Counterparty;
// 	  Directions of activity;  
// 	  Division;
// 	  Coralitikauchetapopartners;
// 	  Account Object Box;
// 	  CorContragent;
// 	  Root direction of activity;  
// 	  Corps Division;
// 	  Period;
// 	  Setting up an economic operation
// 	  Record ID;
// 	  Currency;
// 	  Prepayment;
// 	  PrepaymentRegl;
// 	  PrepaymentUpr.
//
// Parameters:
//  TempTablesManager - TempTablesManager - 
//  CalculationParameters        - See InitializeParametersForPreparationOfAdvancePayments
Procedure PrepareVT_SettlementsWithSuppliers_TransfersOfAdvances(TempTablesManager, CalculationParameters) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	SetRequestParametersForPreparationOfAdvancePayments(Query, CalculationParameters);

	Query.Text =
	"SELECT
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.TransferDocument AS TransferDocument,
	|	NestedQuery.DocumentPayments AS DocumentPayments,
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	NestedQuery.CorARAPObject AS CorARAPObject,
	|	NestedQuery.CorCounterparty AS CorCounterparty,
	|	NestedQuery.CorLineOfBusiness AS CorLineOfBusiness,
	|	NestedQuery.DebitBusinessUnit AS DebitBusinessUnit,
	|	NestedQuery.Period AS Period,
	|	NestedQuery.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	NestedQuery.FinRecordID AS FinRecordID,
	|	NestedQuery.ReversingEntry AS ReversingEntry,
	|	NestedQuery.Currency AS Currency,
	|	SUM(NestedQuery.Prepayment) AS Prepayment,
	|	SUM(NestedQuery.PrepaymentLocal) AS PrepaymentLocal,
	|	SUM(NestedQuery.PrepaymentMan) AS PrepaymentMan
	|INTO SettlementsWithSuppliers_TransfersOfAdvances_Preliminary
	|FROM
	|	(SELECT
	|		VendorsARAPAccountingByDueDates.ARAPObject.Organization AS Organization,
	|		VendorsARAPAccountingByDueDates.DocumentRecorder AS TransferDocument,
	|		VendorsARAPAccountingByDueDates.ARAPDocument AS DocumentPayments,
	|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		VendorsARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|		VendorsARAPAccountingByDueDates.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|		VendorsARAPAccountingByDueDates.ARAPObject.Department AS Department,
	|		VendorsARAPAccountingByDueDates.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|		VendorsARAPAccountingByDueDates.CorARAPObject AS CorARAPObject,
	|		VendorsARAPAccountingByDueDates.CorPartnerAccountingDimension.Counterparty AS CorCounterparty,
	|		VendorsARAPAccountingByDueDates.CorARAPObject.LineOfBusiness AS CorLineOfBusiness,
	|		VendorsARAPAccountingByDueDates.CorARAPObject.Department AS DebitBusinessUnit,
	|		VendorsARAPAccountingByDueDates.Period AS Period,
	|		VendorsARAPAccountingByDueDates.BusinessTransactionSetting AS BusinessTransactionSetting,
	|		VendorsARAPAccountingByDueDates.FinRecordID AS FinRecordID,
	|		VendorsARAPAccountingByDueDates.Currency AS Currency,
	|		VendorsARAPAccountingByDueDates.ReversingEntry AS ReversingEntry,
	|		VendorsARAPAccountingByDueDates.Prepayment AS Prepayment,
	|		VendorsARAPAccountingByDueDates.PrepaymentLocal AS PrepaymentLocal,
	|		VendorsARAPAccountingByDueDates.PrepaymentMan AS PrepaymentMan
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|			LEFT JOIN Document.ARAPSettlement AS ARAPSettlement
	|			ON VendorsARAPAccountingByDueDates.DocumentRecorder = ARAPSettlement.Ref
	|				AND (ARAPSettlement.OperationKind IN (&TypesOfOperationsOfAdvanceTransfer))
	|			LEFT JOIN Document.ARAPSettlement AS StornoDebtSBeingOffsettingARAPOffsetting
	|			ON (CAST(VendorsARAPAccountingByDueDates.DocumentRecorder AS Document.ReversingEntry).ReversedDocument = StornoDebtSBeingOffsettingARAPOffsetting.Ref)
	|				AND (StornoDebtSBeingOffsettingARAPOffsetting.OperationKind IN (&TypesOfOperationsOfAdvanceTransfer))
	|	WHERE
	|		VendorsARAPAccountingByDueDates.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment)
	|		AND VendorsARAPAccountingByDueDates.DocumentRecorder <> VendorsARAPAccountingByDueDates.ARAPDocument
	|		AND VendorsARAPAccountingByDueDates.Active
	|		AND NOT ISNULL(ARAPSettlement.Ref, ISNULL(StornoDebtSBeingOffsettingARAPOffsetting.Ref, NULL)) IS NULL
	|		AND VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND VendorsARAPAccountingByDueDates.Period BETWEEN &StartDate AND &EndDate
	|		AND VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Organization IN(&Companies)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VendorsARAPAccountingByDueDates.ARAPObject.Organization,
	|		VendorsARAPAccountingByDueDates.DocumentRecorder,
	|		VendorsARAPAccountingByDueDates.ARAPDocument,
	|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners,
	|		VendorsARAPAccountingByDueDates.ARAPObject,
	|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Counterparty,
	|		VendorsARAPAccountingByDueDates.ARAPObject.LineOfBusiness,
	|		VendorsARAPAccountingByDueDates.ARAPObject.Department,
	|		VendorsARAPAccountingByDueDates.CorPartnerAccountingDimension,
	|		VendorsARAPAccountingByDueDates.CorARAPObject,
	|		VendorsARAPAccountingByDueDates.CorPartnerAccountingDimension.Counterparty,
	|		VendorsARAPAccountingByDueDates.CorARAPObject.LineOfBusiness,
	|		VendorsARAPAccountingByDueDates.CorARAPObject.Department,
	|		VendorsARAPAccountingByDueDates.Period,
	|		VendorsARAPAccountingByDueDates.BusinessTransactionSetting,
	|		VendorsARAPAccountingByDueDates.FinRecordID,
	|		VendorsARAPAccountingByDueDates.Currency,
	|		VendorsARAPAccountingByDueDates.ReversingEntry,
	|		VendorsARAPAccountingByDueDates.Debt,
	|		VendorsARAPAccountingByDueDates.DebtLocal,
	|		VendorsARAPAccountingByDueDates.ARAPMan
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|			LEFT JOIN Document.ARAPSettlement AS ARAPSettlement
	|			ON VendorsARAPAccountingByDueDates.DocumentRecorder = ARAPSettlement.Ref
	|				AND (ARAPSettlement.OperationKind IN (&TypesOfOperationsOfAdvanceTransfer))
	|			LEFT JOIN Document.ARAPSettlement AS StornoDebtSBeingOffsettingARAPOffsetting
	|			ON (CAST(VendorsARAPAccountingByDueDates.DocumentRecorder AS Document.ReversingEntry).ReversedDocument = StornoDebtSBeingOffsettingARAPOffsetting.Ref)
	|				AND (StornoDebtSBeingOffsettingARAPOffsetting.OperationKind IN (&TypesOfOperationsOfAdvanceTransfer))
	|			INNER JOIN AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates_Receipt
	|			ON (VendorsARAPAccountingByDueDates_Receipt.RecordType = VALUE(AccumulationRecordType.Receipt))
	|				AND VendorsARAPAccountingByDueDates.ARAPObject = VendorsARAPAccountingByDueDates_Receipt.ARAPObject
	|				AND VendorsARAPAccountingByDueDates.AccountingDimensionByPartners = VendorsARAPAccountingByDueDates_Receipt.AccountingDimensionByPartners
	|				AND VendorsARAPAccountingByDueDates.DocumentRecorder = VendorsARAPAccountingByDueDates_Receipt.DocumentRecorder
	|	WHERE
	|		VendorsARAPAccountingByDueDates.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment)
	|		AND VendorsARAPAccountingByDueDates.Active
	|		AND NOT ISNULL(ARAPSettlement.Ref, ISNULL(StornoDebtSBeingOffsettingARAPOffsetting.Ref, NULL)) IS NULL
	|		AND VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND VendorsARAPAccountingByDueDates.Period BETWEEN &StartDate AND &EndDate
	|		AND VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Organization IN(&Companies)
	|		AND VendorsARAPAccountingByDueDates.Debt > 0) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.Currency,
	|	NestedQuery.CorPartnerAccountingDimension,
	|	NestedQuery.Department,
	|	NestedQuery.DebitBusinessUnit,
	|	NestedQuery.DocumentPayments,
	|	NestedQuery.CorLineOfBusiness,
	|	NestedQuery.FinRecordID,
	|	NestedQuery.Period,
	|	NestedQuery.Organization,
	|	NestedQuery.CorARAPObject,
	|	NestedQuery.CorCounterparty,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.Counterparty,
	|	NestedQuery.BusinessTransactionSetting,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.TransferDocument,
	|	NestedQuery.ReversingEntry
	|
	|INDEX BY
	|	DocumentPayments,
	|	ARAPObject,
	|	CorPartnerAccountingDimension,
	|	CorARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettlementsWithSuppliers_TransfersOfAdvances.DocumentPayments AS DocumentPayments,
	|	SettlementsWithSuppliers_TransfersOfAdvances.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	SettlementsWithSuppliers_TransfersOfAdvances.ARAPObject AS ARAPObject,
	|	SettlementsWithSuppliers_TransfersOfAdvances.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	SettlementsWithSuppliers_TransfersOfAdvances.CorARAPObject AS CorARAPObject,
	|	SettlementsWithSuppliers_TransfersOfAdvances.Currency AS Currency,
	|	SUM(SettlementsWithSuppliers_TransfersOfAdvances.Prepayment) AS Prepayment,
	|	SUM(SettlementsWithSuppliers_TransfersOfAdvances.PrepaymentLocal) AS PrepaymentLocal,
	|	SUM(SettlementsWithSuppliers_TransfersOfAdvances.PrepaymentMan) AS PrepaymentMan,
	|	SettlementsWithSuppliers_TransfersOfAdvances.FinRecordID AS FinRecordID
	|INTO HyphenationSelections
	|FROM
	|	SettlementsWithSuppliers_TransfersOfAdvances_Preliminary AS SettlementsWithSuppliers_TransfersOfAdvances
	|
	|GROUP BY
	|	SettlementsWithSuppliers_TransfersOfAdvances.Organization,
	|	SettlementsWithSuppliers_TransfersOfAdvances.DocumentPayments,
	|	SettlementsWithSuppliers_TransfersOfAdvances.AccountingDimensionByPartners,
	|	SettlementsWithSuppliers_TransfersOfAdvances.ARAPObject,
	|	SettlementsWithSuppliers_TransfersOfAdvances.CorPartnerAccountingDimension,
	|	SettlementsWithSuppliers_TransfersOfAdvances.CorARAPObject,
	|	SettlementsWithSuppliers_TransfersOfAdvances.Currency,
	|	SettlementsWithSuppliers_TransfersOfAdvances.FinRecordID
	|
	|HAVING
	|	SUM(SettlementsWithSuppliers_TransfersOfAdvances.Prepayment) <> 0
	|
	|INDEX BY
	|	DocumentPayments,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	CorPartnerAccountingDimension,
	|	CorARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettlementsWithSuppliers_TransfersOfAdvances.Organization AS Organization,
	|	SettlementsWithSuppliers_TransfersOfAdvances.TransferDocument AS TransferDocument,
	|	SettlementsWithSuppliers_TransfersOfAdvances.DocumentPayments AS DocumentPayments,
	|	SettlementsWithSuppliers_TransfersOfAdvances.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	SettlementsWithSuppliers_TransfersOfAdvances.ARAPObject AS ARAPObject,
	|	SettlementsWithSuppliers_TransfersOfAdvances.Counterparty AS Counterparty,
	|	SettlementsWithSuppliers_TransfersOfAdvances.LineOfBusiness AS LineOfBusiness,
	|	SettlementsWithSuppliers_TransfersOfAdvances.Department AS Department,
	|	SettlementsWithSuppliers_TransfersOfAdvances.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	SettlementsWithSuppliers_TransfersOfAdvances.CorARAPObject AS CorARAPObject,
	|	SettlementsWithSuppliers_TransfersOfAdvances.CorCounterparty AS CorCounterparty,
	|	SettlementsWithSuppliers_TransfersOfAdvances.CorLineOfBusiness AS CorLineOfBusiness,
	|	SettlementsWithSuppliers_TransfersOfAdvances.DebitBusinessUnit AS DebitBusinessUnit,
	|	SettlementsWithSuppliers_TransfersOfAdvances.Period AS Period,
	|	SettlementsWithSuppliers_TransfersOfAdvances.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	SettlementsWithSuppliers_TransfersOfAdvances.FinRecordID AS FinRecordID,
	|	SettlementsWithSuppliers_TransfersOfAdvances.ReversingEntry AS ReversingEntry,
	|	SettlementsWithSuppliers_TransfersOfAdvances.Currency AS Currency,
	|	SettlementsWithSuppliers_TransfersOfAdvances.Prepayment AS Prepayment,
	|	SettlementsWithSuppliers_TransfersOfAdvances.PrepaymentLocal AS PrepaymentLocal,
	|	SettlementsWithSuppliers_TransfersOfAdvances.PrepaymentMan AS PrepaymentMan
	|INTO SettlementsWithSuppliers_TransfersOfAdvances
	|FROM
	|	SettlementsWithSuppliers_TransfersOfAdvances_Preliminary AS SettlementsWithSuppliers_TransfersOfAdvances
	|		INNER JOIN HyphenationSelections AS HyphenationSelections
	|		ON SettlementsWithSuppliers_TransfersOfAdvances.DocumentPayments = HyphenationSelections.DocumentPayments
	|			AND SettlementsWithSuppliers_TransfersOfAdvances.AccountingDimensionByPartners = HyphenationSelections.AccountingDimensionByPartners
	|			AND SettlementsWithSuppliers_TransfersOfAdvances.ARAPObject = HyphenationSelections.ARAPObject
	|			AND SettlementsWithSuppliers_TransfersOfAdvances.CorPartnerAccountingDimension = HyphenationSelections.CorPartnerAccountingDimension
	|			AND SettlementsWithSuppliers_TransfersOfAdvances.CorARAPObject = HyphenationSelections.CorARAPObject
	|			AND SettlementsWithSuppliers_TransfersOfAdvances.Currency = HyphenationSelections.Currency
	|			AND SettlementsWithSuppliers_TransfersOfAdvances.FinRecordID = HyphenationSelections.FinRecordID
	|
	|INDEX BY
	|	Organization,
	|	DocumentPayments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SettlementsWithSuppliers_TransfersOfAdvances_Preliminary
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP HyphenationSelections";
	
	SetIndexFields(Query, CalculationParameters, "SettlementsWithSuppliers_TransfersOfAdvances");
	
	Query.Execute();
	
EndProcedure

#EndRegion

#Region SearchForPaymentGroundsAndDocuments

// Creates a structure for search parameters for payment grounds and payment documents
// 
// Parameters:
// 	SearchMode_ - Number - matching the search mode code:
// 		1 - Search for payment documents; 
// 		2 - Search for the basis (objects) of the payment.
// 
// Returns:
// 	Structure - Contains:
// 	* SearchMode_ - Number - matching the search mode code:
// 		1 - Search for payment documents; 
// 		2 - Search for the basis (objects) of the payment.
// 	* Companies - CatalogRef.Companies, Array of CatalogRef.Companies -
// 	* Documents   - Array of DocumentRef - documents that are used to search for payments.
// 	* OnDate      - Date - for a cross-section of found documents on the date
// 	* AdvancesOnly - Boolean - If "True", only advance payments will be refunded
// 	* RestrictPaymentDocumentTypes - Boolean - If "True", payment documents will be limited to the possible types
// 	                                                of incoming and outgoing payment documents.
// 	* LimitTypesOfPaymentGrounds  - Boolean - If "True", the payment grounds will be limited to the possible types
// 	                                                of incoming and outgoing documents.
// 	* SelectionParametersForDocumentTable - Structure - For selection according to a temporary table with documents, where:
//  	** FieldName - String - Name of the field that contains the document
//  	** SelectionTableName_ - String - name of the temporary table that contains the document
//
Function InitializeSearchParametersForPaymentBasesAndDocuments(SearchMode_ = 1) Export
	
	SearchParameters = New Structure;
	
	SearchParameters.Insert("SearchMode_",  SearchMode_);
	SearchParameters.Insert("Companies",  Undefined);
	SearchParameters.Insert("Documents",    New Array);
	SearchParameters.Insert("OnDate",       Date(1,1,1));
	SearchParameters.Insert("AdvancesOnly", False);
	SearchParameters.Insert("RestrictPaymentDocumentTypes", False);
	SearchParameters.Insert("LimitTypesOfPaymentGrounds", False);
	
	// Documents for which it is necessary to find payment documents
	SelectionParametersForDocumentTable = New Structure;
	SelectionParametersForDocumentTable.Insert("FieldName",          "");
	SelectionParametersForDocumentTable.Insert("SelectionTableName_", "");
	
	SearchParameters.Insert("SelectionParametersForDocumentTable", SelectionParametersForDocumentTable);
	
	Return SearchParameters;
	
EndFunction

// Prepare a temporary table "Calculation by clients_The basis of the Payment document"
// Creates a temporary table with columns:
// 	  Organization;
// 	  Document payments - payment document;
// 	  The basis of payment is a paid document;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Directions of activity;
// 	  Counterparty;
// 	  Contract;
// 	  Payment totals;
// 	  Payment totalupr;
// 	  The amount of the payment is correct.
// 
// Parameters:
// 	TempTablesManager - TempTablesManager - 
// 	SearchParameters         - See InitializeSearchParametersForPaymentBasesAndDocuments
Procedure PrepareVT_SettlementsWithClients_GroundsAndPaymentDocuments(TempTablesManager, SearchParameters) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT
	|	Calculations.Organization                            AS Organization,
	|	Calculations.DocumentPayments                         AS DocumentPayments,
	|	Calculations.BasisOfPayment                        AS BasisOfPayment,
	|	Calculations.AccountingDimensionByPartners              AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject                         AS ARAPObject,
	|	Calculations.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	Calculations.ARAPObject.Counterparty              AS Counterparty,
	|	Calculations.ARAPObject.Contract                 AS Contract,
	|	SUM(Calculations.PayAmount)                     AS PayAmount,
	|	SUM(Calculations.ManPaymentAmount)                  AS ManPaymentAmount,
	|	SUM(Calculations.PaymentAmountLocal)                 AS PaymentAmountLocal
	|INTO SettlementsWithClients_GroundsAndPaymentDocuments
	|FROM
	|	(SELECT
	|		Calculations.ARAPObject.Organization AS Organization,
	|		Calculations.AccountingDimensionByPartners  AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject             AS ARAPObject,
	|		Calculations.ARAPDocument          AS DocumentPayments,
	|		Calculations.DocumentRecorder        AS BasisOfPayment,
	|		Calculations.Prepayment                 AS PayAmount,
	|		Calculations.PrepaymentMan              AS ManPaymentAmount,
	|		Calculations.PrepaymentLocal             AS PaymentAmountLocal
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_DocumentRecorder_SearchMode_2_ARAPDocument
	|	WHERE
	|		Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Prepayment <> 0
	|		AND &NewOnlineARAPAccounting
	|		AND Calculations.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement),
	|			 VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.ARAPObject.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.ARAPObject,
	|		Calculations.DocumentRecorder,
	|		&PaymentBasisField_SettlementObject,
	|		Calculations.Debt,
	|		Calculations.ARAPMan,
	|		Calculations.DebtLocal
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_ARAPObject_SearchMode_2_DocumentRecorder
	|	WHERE
	|		Calculations.ARAPDocument <> Calculations.DocumentRecorder
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Debt <> 0
	|		AND &NewOnlineARAPAccounting
	|		AND NOT &AdvancesOnly
	|		AND Calculations.BusinessOperation <>
	|			VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.ARAPObject.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.ARAPObject,
	|		Calculations.DocumentRecorder,
	|		Calculations.ARAPDocument,
	|		Calculations.Debt,
	|		Calculations.ARAPMan,
	|		Calculations.DebtLocal
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_ARAPDocument_SearchMode_2_DocumentRecorder
	|	WHERE
	|		Calculations.ARAPDocument <> Calculations.ARAPObject.Object
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Debt <> 0
	|		AND &NewOnlineARAPAccounting
	|		AND NOT &AdvancesOnly
	|		AND Calculations.BusinessOperation <>
	|			VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.AccountingDimensionByPartners.Organization AS Organization,
	|		Calculations.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
	|		Calculations.SalesOrder                          AS ARAPObject,
	|		Calculations.ARAPDocument                     AS DocumentPayments,
	|		Calculations.Recorder                           AS BasisOfPayment,
	|		Calculations.Prepayment                            AS PayAmount,
	|		Calculations.PrepaymentMan                         AS ManPaymentAmount,
	|		Calculations.PrepaymentLocal                        AS PaymentAmountLocal
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_Recorder_SearchMode_2_ARAPDocument
	|	WHERE
	|		Calculations.Recorder <> Calculations.SalesOrder.Object
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Prepayment <> 0
	|		AND NOT &NewOnlineARAPAccounting
	|		AND Calculations.BusinessOperation <>
	|			VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.AccountingDimensionByPartners.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.SalesOrder,
	|		Calculations.Recorder,
	|		&PaymentBasisField_CustomerOrder,
	|		Calculations.Prepayment,
	|		Calculations.PrepaymentMan,
	|		Calculations.PrepaymentLocal
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_SalesOrder_SearchMode_2_Recorder
	|	WHERE
	|		Calculations.Recorder = Calculations.ARAPDocument
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Prepayment <> 0
	|		AND NOT &NewOnlineARAPAccounting
	|		AND Calculations.BusinessOperation <>
	|			VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.AccountingDimensionByPartners.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.SalesOrder,
	|		Calculations.Recorder,
	|		&PaymentBasisField_CustomerOrder,
	|		Calculations.Debt,
	|		Calculations.ARAPMan,
	|		Calculations.DebtLocal
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_SalesOrder_SearchMode_2_Recorder
	|	WHERE
	|		Calculations.ARAPDocument <> Calculations.Recorder
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Debt <> 0
	|		AND NOT &NewOnlineARAPAccounting
	|		AND NOT &AdvancesOnly
	|		AND Calculations.BusinessOperation <>
	|			VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.AccountingDimensionByPartners.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.SalesOrder,
	|		Calculations.Recorder,
	|		Calculations.ARAPDocument,
	|		Calculations.Debt,
	|		Calculations.ARAPMan,
	|		Calculations.DebtLocal
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_ARAPDocument_SearchMode_2_Recorder
	|	WHERE
	|		Calculations.ARAPDocument <> Calculations.SalesOrder.Object
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Debt <> 0
	|		AND NOT &NewOnlineARAPAccounting
	|		AND NOT &AdvancesOnly
	|		AND Calculations.BusinessOperation <>
	|			VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|	) AS Calculations
	|
	|WHERE
	|	(NOT &EnableOrganizationSelection
	|			OR Calculations.Organization IN (&Companies))
	|	AND (NOT &LimitTypesOfPaymentGrounds
	|		OR VALUETYPE(Calculations.BasisOfPayment) IN (&MTypesOfPaymentGroundsOutgoing))
	|
	|GROUP BY
	|	Calculations.Organization,
	|	Calculations.DocumentPayments,
	|	Calculations.BasisOfPayment,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.ARAPObject.LineOfBusiness,
	|	Calculations.ARAPObject.Counterparty,
	|	Calculations.ARAPObject.Contract
	|
	|INDEX BY
	|	DocumentPayments
	|
	|";
	
	RequestPostProcessing_SearchForPaymentGroundsAndDocuments(Query, SearchParameters);
	
	Query.Execute();
	
EndProcedure

// Prepare a temporary table "Settlements by suppliers_The basis of the Payment document"
// Creates a temporary table with columns:
// 	  Organization;
// 	  Document payments - payment document;
// 	  The basis of payment is a paid document;
// 	  Analyticaccounts to partners;
// 	  Accounting objects;
// 	  Directions of activity;
// 	  Counterparty;
// 	  Contract;
// 	  Payment totals;
// 	  Payment totalupr;
// 	  The amount of the payment is correct.
// 
// Parameters:
// 	TempTablesManager - TempTablesManager - 
// 	SearchParameters         - See InitializeSearchParametersForPaymentBasesAndDocuments
Procedure PrepareVT_SettlementsWithSuppliers_GroundsAndPaymentDocuments(TempTablesManager, SearchParameters) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT
	|	Calculations.Organization                            AS Organization,
	|	Calculations.DocumentPayments                         AS DocumentPayments,
	|	Calculations.BasisOfPayment                        AS BasisOfPayment,
	|	Calculations.AccountingDimensionByPartners              AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject                         AS ARAPObject,
	|	Calculations.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	Calculations.ARAPObject.Counterparty              AS Counterparty,
	|	Calculations.ARAPObject.Contract                 AS Contract,
	|	SUM(Calculations.PayAmount)                     AS PayAmount,
	|	SUM(Calculations.ManPaymentAmount)                  AS ManPaymentAmount,
	|	SUM(Calculations.PaymentAmountLocal)                 AS PaymentAmountLocal
	|INTO SettlementsWithSuppliers_GroundsAndPaymentDocuments
	|FROM
	|	(SELECT
	|		Calculations.ARAPObject.Organization AS Organization,
	|		Calculations.AccountingDimensionByPartners  AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject             AS ARAPObject,
	|		Calculations.ARAPDocument          AS DocumentPayments,
	|		Calculations.DocumentRecorder        AS BasisOfPayment,
	|		Calculations.Prepayment                 AS PayAmount,
	|		Calculations.PrepaymentMan              AS ManPaymentAmount,
	|		Calculations.PrepaymentLocal             AS PaymentAmountLocal
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_DocumentRecorder_SearchMode_2_ARAPDocument
	|	WHERE
	|		Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Prepayment <> 0
	|		AND &NewOnlineARAPAccounting
	|		AND Calculations.BusinessOperation =
	|			VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.ARAPObject.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.ARAPObject,
	|		Calculations.DocumentRecorder,
	|		&PaymentBasisField_SettlementObject,
	|		Calculations.Debt,
	|		Calculations.ARAPMan,
	|		Calculations.DebtLocal
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_ARAPObject_SearchMode_2_DocumentRecorder
	|	WHERE
	|		Calculations.ARAPDocument <> Calculations.DocumentRecorder
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Debt <> 0
	|		AND &NewOnlineARAPAccounting
	|		AND NOT &AdvancesOnly
	|		AND Calculations.BusinessOperation <>
	|			VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.ARAPObject.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.ARAPObject,
	|		Calculations.DocumentRecorder,
	|		Calculations.ARAPDocument,
	|		Calculations.Debt,
	|		Calculations.ARAPMan,
	|		Calculations.DebtLocal
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_ARAPDocument_SearchMode_2_DocumentRecorder
	|	WHERE
	|		Calculations.ARAPDocument <> Calculations.ARAPObject.Object
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Debt <> 0
	|		AND &NewOnlineARAPAccounting
	|		AND NOT &AdvancesOnly
	|		AND Calculations.BusinessOperation <>
	|			VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.AccountingDimensionByPartners.Organization AS Organization,
	|		Calculations.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
	|		Calculations.PurchaseOrder                       AS ARAPObject,
	|		Calculations.ARAPDocument                     AS DocumentPayments,
	|		Calculations.Recorder                           AS BasisOfPayment,
	|		Calculations.Prepayment                            AS PayAmount,
	|		Calculations.PrepaymentMan                         AS ManPaymentAmount,
	|		Calculations.PrepaymentLocal                        AS PaymentAmountLocal
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_Recorder_SearchMode_2_ARAPDocument
	|	WHERE
	|		Calculations.Recorder <> Calculations.PurchaseOrder.Object
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Prepayment <> 0
	|		AND NOT &NewOnlineARAPAccounting
	|		AND Calculations.BusinessOperation <>
	|			VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.AccountingDimensionByPartners.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.PurchaseOrder,
	|		Calculations.Recorder,
	|		&PaymentBasisField_OrderToSupplier,
	|		Calculations.Prepayment,
	|		Calculations.PrepaymentMan,
	|		Calculations.PrepaymentLocal
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_PurchaseOrder_SearchMode_2_Recorder
	|	WHERE
	|		Calculations.Recorder = Calculations.ARAPDocument
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Prepayment <> 0
	|		AND NOT &NewOnlineARAPAccounting
	|		AND Calculations.BusinessOperation <>
	|			VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.AccountingDimensionByPartners.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.PurchaseOrder,
	|		Calculations.Recorder,
	|		&PaymentBasisField_OrderToSupplier,
	|		Calculations.Debt,
	|		Calculations.ARAPMan,
	|		Calculations.DebtLocal
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_PurchaseOrder_SearchMode_2_Recorder
	|	WHERE
	|		Calculations.ARAPDocument <> Calculations.Recorder
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Debt <> 0
	|		AND NOT &NewOnlineARAPAccounting
	|		AND NOT &AdvancesOnly
	|		AND Calculations.BusinessOperation <>
	|			VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.AccountingDimensionByPartners.Organization,
	|		Calculations.AccountingDimensionByPartners,
	|		Calculations.PurchaseOrder,
	|		Calculations.Recorder,
	|		Calculations.ARAPDocument,
	|		Calculations.Debt,
	|		Calculations.ARAPMan,
	|		Calculations.DebtLocal
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|			INNER JOIN TableOfSelectionOfGroundsAndPaymentDocuments AS TableOfSelectionOfGroundsAndPaymentDocuments
	|				ON &SearchMode_1_ARAPDocument_SearchMode_2_Recorder
	|	WHERE
	|		Calculations.ARAPDocument <> Calculations.PurchaseOrder.Object
	|		AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND Calculations.Period <= &EndDate
	|		AND Calculations.Debt <> 0
	|		AND NOT &NewOnlineARAPAccounting
	|		AND NOT &AdvancesOnly
	|		AND Calculations.BusinessOperation <>
	|			VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|	) AS Calculations
	|
	|WHERE
	|	(NOT &EnableOrganizationSelection
	|			OR Calculations.Organization IN (&Companies))
	|	AND (NOT &RestrictPaymentDocumentTypes
	|		OR VALUETYPE(Calculations.DocumentPayments) IN (&MTypesOfPaymentDocumentsOutgoing))
	|	AND (NOT &LimitTypesOfPaymentGrounds
	|		OR VALUETYPE(Calculations.BasisOfPayment) IN (&MTypesOfPaymentGroundsIncoming))
	|
	|GROUP BY
	|	Calculations.Organization,
	|	Calculations.DocumentPayments,
	|	Calculations.BasisOfPayment,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.ARAPObject.LineOfBusiness,
	|	Calculations.ARAPObject.Counterparty,
	|	Calculations.ARAPObject.Contract
	|
	|INDEX BY
	|	DocumentPayments
	|
	|";
	
	RequestPostProcessing_SearchForPaymentGroundsAndDocuments(Query, SearchParameters);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure FillInParameterProperties(Receiver, Source)
	
	DestinationType  = TypeOf(Receiver);
	SourceType  = TypeOf(Source);
	
	If DestinationType = Type("Structure") And SourceType = Type("Structure") Then
			For Each ReceiverElement In Receiver Do
				SourceValue_ = Undefined;
				If Source.Property(ReceiverElement.Key, SourceValue_) Then
					FillInParameterProperties(Receiver[ReceiverElement.Key], SourceValue_);
				EndIf;
			EndDo;
	ElsIf DestinationType <> Type("Structure") And SourceType <> Type("Structure") Then
		Receiver = Common.CopyRecursive(Source);
	EndIf;
	
EndProcedure

// Sets the necessary parameters for executing requests based on settlement data
//
// Parameters:
//  Query           - Query - 
//  CalculationParameters - See InitializeParametersForPreparationOfAdvancePayments
Procedure SetRequestParametersForPreparationOfAdvancePayments(Query, CalculationParameters)
	
	If Not ValueIsFilled(CalculationParameters.EndDate) Then
		EndDate        = Date(3000, 1, 1);
		EndDateIncluding = Undefined;
	Else
		EndDate        = CalculationParameters.EndDate;
		EndDateIncluding = New Boundary(EndDate);
	EndIf;
	
	DateEmpty        = '00010101';
	
	If ValueIsFilled(CalculationParameters.Companies) Then
		Companies                 = CalculationParameters.Companies;
	Else
		Companies                 = Undefined;
	EndIf;
	
	ARAPDocument = ?(ValueIsFilled(CalculationParameters.ARAPDocument),
							CalculationParameters.ARAPDocument, Undefined);
	
	If ValueIsFilled(CalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_)
		Or ValueIsFilled(ARAPDocument) Then
		EnableSelectionBasedOnSettlementDocument = True;
	Else
		EnableSelectionBasedOnSettlementDocument = False;
	EndIf;
	
	TypesOfReturnDocuments_AdvancesReceived = New Array;
	TypesOfReturnDocuments_AdvancesReceived.Add(Type("DocumentRef.BankAccountIssue"));
	TypesOfReturnDocuments_AdvancesReceived.Add(Type("DocumentRef.CashVoucher")); 
	
	TypesOfOperationsOfAdvanceTransfer = New Array;
	TypesOfOperationsOfAdvanceTransfer.Add(Enums.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty);
	TypesOfOperationsOfAdvanceTransfer.Add(Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties);
	TypesOfOperationsOfAdvanceTransfer.Add(Enums.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty);
	TypesOfOperationsOfAdvanceTransfer.Add(Enums.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties);
	TypesOfOperationsOfAdvanceTransfer.Add(Enums.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies);
	TypesOfOperationsOfAdvanceTransfer.Add(Enums.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies);

	Query.SetParameter("StartDate",           CalculationParameters.StartDate);
	Query.SetParameter("EndDate",        EndDate);
	Query.SetParameter("EndDateIncluding", EndDateIncluding);
	Query.SetParameter("CreateEmptyTable", CalculationParameters.CreateEmptyTable);
	Query.SetParameter("DateEmpty",           DateEmpty);
	Query.SetParameter("Companies",          Companies);
	Query.SetParameter("ARAPDocument",    ARAPDocument);
	Query.SetParameter("EmptyCalculationObject", Catalogs.ARAPObjects.EmptyRef());
	Query.SetParameter("TakeIntoAccountReservationOfAdvances",        CalculationParameters.TakeIntoAccountReservationOfAdvances);
	Query.SetParameter("NewOnlineARAPAccounting",     CalculationParameters.NewOnlineARAPAccounting);
	Query.SetParameter("EnableSelectionBasedOnSettlementDocument", EnableSelectionBasedOnSettlementDocument);
	Query.SetParameter("EnableOrganizationSelection",        CalculationParameters.EnableOrganizationSelection);
	Query.SetParameter("TypesOfReturnDocuments_AdvancesReceived", TypesOfReturnDocuments_AdvancesReceived);
	Query.SetParameter("AdvanceSelectionRule", CalculationParameters.AdvanceSelectionRule);
	Query.SetParameter("TypesOfOperationsOfAdvanceTransfer", TypesOfOperationsOfAdvanceTransfer);
	
EndProcedure

// Overrides the index of the request
// 
// Parameters:
// 	Query - Query -
// 	CalculationParameters - See InitializeParametersForPreparationOfAdvancePayments
// 	TableName - String - name of the temporary table where we change the order of indexes
Procedure SetIndexFields(Query, CalculationParameters, TableName)
	
	MIndexFields = CalculationParameters.ManualIndexFields;
	
	If Not ValueIsFilled(MIndexFields) Then
		Return;
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(Query.Text);
	
	For Each Package In QuerySchema.QueryBatch Do
		If Package.PlacementTable = TableName Then
			
			Package.Order.Clear();
			For Each IndexField In MIndexFields Do
				Package.Index.Add(IndexField);
			EndDo;
			
		EndIf;
	EndDo;
	
	Query.Text = QuerySchema.GetQueryText();
	
EndProcedure

// Processing a request for selection based on a settlement document
// 
// Parameters:
// 	Query - Query -
// 	CalculationParameters - See InitializeParametersForPreparationOfAdvancePayments
// 	PathParameters   - See InitializeParametersForSelectingAdvances_FieldPathsAndReplacementText
//
Procedure ProcessRequestTextForSelectingAdvancesBasedOnParameters(Query, CalculationParameters, PathParameters)
	
	MSelectionByParameters = New Array;
	
	
	FilterFieldName    = CalculationParameters.SelectionParametersForSettlementDocument.FieldName;
	SelectionTableName_ = CalculationParameters.SelectionParametersForSettlementDocument.SelectionTableName_;
	
	FullPath = PathParameters.FullPath_SettlementDocument;
	
	If ValueIsFilled(SelectionTableName_) Then
		
		TextTemplate1 = "%1 IN
		|			(SELECT
		|				%2 AS Ref
		|			FROM
		|				%3 AS T
		|			)
		|";
		
		MSelectionByParameters.Add(StrTemplate(TextTemplate1, FullPath, FilterFieldName, SelectionTableName_));
		
	Else
		
		TextTemplate1 = "(NOT &EnableSelectionBasedOnSettlementDocument OR %1 IN (&ARAPDocument))";
		MSelectionByParameters.Add(StrTemplate(TextTemplate1, FullPath));
		
	EndIf;
	
	
	TextSelectionByParameters = StrConcat(MSelectionByParameters, " And ");
	Query.Text = StrReplace(Query.Text, PathParameters.ReplacementText, TextSelectionByParameters);
	
EndProcedure

// Initialize parameters to specify paths to fields and text for replacing selection by parameters
//
// Returns:
//  Structure - Contains:
//  	* ReplacementText                  - String - Replaced text in the request
//  	* FullPath_SettlementDocument - String - Full path to the settlement document
//
Function InitializeParametersForSelectingAdvances_FieldPathsAndReplacementText()
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("ReplacementText", "&TextSelectionByParameters");
	
	ParametersStructure.Insert("FullPath_SettlementDocument", "ARAPDocument");
	
	Return ParametersStructure;
	
EndFunction

// Sets the necessary parameters for executing requests based on settlement data
//
// Parameters:
//  Query           - Query - 
//  SearchParameters  - See InitializeSearchParametersForPaymentBasesAndDocuments
Procedure RequestPostProcessing_SearchForPaymentGroundsAndDocuments(Query, SearchParameters)
	
	// Data preparation
	
	// - end date
	If Not ValueIsFilled(SearchParameters.OnDate) Then
		EndDate        = Date(3000, 1, 1);
		EndDateIncluding = Undefined;
	Else
		EndDate        = SearchParameters.OnDate;
		EndDateIncluding = New Boundary(EndDate);
	EndIf;
	
	// - organizations
	If ValueIsFilled(SearchParameters.Companies) Then
		Companies                 = SearchParameters.Companies;
		EnableOrganizationSelection = True;
	Else
		Companies                 = Undefined;
		EnableOrganizationSelection = False;
	EndIf;
	
	// - initialization of the document table for selection
	MTypesOfSelectionDocuments = New Array;
	
	For Each Document In SearchParameters.Documents Do
		MTypesOfSelectionDocuments.Add(TypeOf(Document));
	EndDo;
	
	DocumentsTable = New ValueTable;
	DocumentsTable.Columns.Add("DocumentOfSelection", New TypeDescription(MTypesOfSelectionDocuments));
	
	For Each Document In SearchParameters.Documents Do
		NewString = DocumentsTable.Add();
		NewString.DocumentOfSelection = Document;
	EndDo;
	
	// - types of payment documents
	
	MTypesOfPaymentDocumentsOutgoing = New Array;
	MTypesOfPaymentDocumentsOutgoing.Add(Type("DocumentRef.BankAccountIssue"));
	MTypesOfPaymentDocumentsOutgoing.Add(Type("DocumentRef.CashVoucher"));
	MTypesOfPaymentDocumentsOutgoing.Add(Type("DocumentRef.SourceDocument"));
	MTypesOfPaymentDocumentsOutgoing.Add(Type("DocumentRef.ARAPSettlement"));
	
	// - types of payment bases (objects)
	
	MTypesOfPaymentGroundsIncoming = New Array;
	MTypesOfPaymentGroundsIncoming.Add(Type("DocumentRef.VendorInvoice"));
	MTypesOfPaymentGroundsIncoming.Add(Type("DocumentRef.VendorInvoiceServicesAndAssets"));
	MTypesOfPaymentGroundsIncoming.Add(Type("DocumentRef.SourceDocument"));
	
	MTypesOfPaymentGroundsOutgoing = New Array;
	MTypesOfPaymentGroundsOutgoing.Add(Type("DocumentRef.CustomerInvoice"));
	MTypesOfPaymentGroundsOutgoing.Add(Type("DocumentRef.CustomerInvoiceServicesAndAssets"));
	MTypesOfPaymentGroundsOutgoing.Add(Type("DocumentRef.SourceDocument"));
	
	// Setting parameters
	
	Query.SetParameter("Companies",                        Companies);
	Query.SetParameter("EndDate",                      EndDate);
	Query.SetParameter("EndDateIncluding",               EndDateIncluding);
	Query.SetParameter("DocumentsTable",                  DocumentsTable);
	Query.SetParameter("EnableOrganizationSelection",        EnableOrganizationSelection);
	Query.SetParameter("AdvancesOnly",                       SearchParameters.AdvancesOnly);
	Query.SetParameter("RestrictPaymentDocumentTypes",     SearchParameters.RestrictPaymentDocumentTypes);
	Query.SetParameter("LimitTypesOfPaymentGrounds",      SearchParameters.LimitTypesOfPaymentGrounds);
	Query.SetParameter("MTypesOfPaymentDocumentsOutgoing",    MTypesOfPaymentDocumentsOutgoing);
	Query.SetParameter("MTypesOfPaymentGroundsIncoming",      MTypesOfPaymentGroundsIncoming);
	Query.SetParameter("MTypesOfPaymentGroundsOutgoing",     MTypesOfPaymentGroundsOutgoing);
	
	Query.SetParameter("NewOnlineARAPAccounting",
		GetFunctionalOption("NewOnlineARAPAccounting"));
	
	// Request text processing
	
	// - The text of the selection of documents
	
	FilterFieldName    = SearchParameters.SelectionParametersForDocumentTable.FieldName;
	SelectionTableName_ = SearchParameters.SelectionParametersForDocumentTable.SelectionTableName_;
	
	TimeTableSelectionIsSet = ValueIsFilled(SelectionTableName_) And ValueIsFilled(FilterFieldName);
	
	If Not TimeTableSelectionIsSet Then
		
		SelectionTableName_ = "TableOfSelectionOfGroundsAndPaymentDocuments";
		FilterFieldName    = "DocumentOfSelection";
		
		RequestTextForCreatingSelectionTable = 
		"SELECT DISTINCT
		|	DocumentsTable.DocumentOfSelection AS DocumentOfSelection
		|INTO TableOfSelectionOfGroundsAndPaymentDocuments_Preliminary
		|FROM
		|	&DocumentsTable AS DocumentsTable
		|;
		|
		|SELECT
		|	DocumentsTable.DocumentOfSelection,
		|	ARAPObjects.Ref AS ARAPObject
		|INTO TableOfSelectionOfGroundsAndPaymentDocuments
		|FROM
		|	TableOfSelectionOfGroundsAndPaymentDocuments_Preliminary AS DocumentsTable
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON DocumentsTable.DocumentOfSelection = ARAPObjects.Object
		|				AND NOT ARAPObjects.DeletionMark
		|
		|INDEX BY
		|	DocumentOfSelection
		|;
		|
		|DROP TableOfSelectionOfGroundsAndPaymentDocuments_Preliminary
		|";
		
	Else
		
		RequestTextForCreatingSelectionTable = 
		"SELECT DISTINCT
		|	NameOfDocumentField AS DocumentOfSelection,
		|	ARAPObjects.Ref AS ARAPObject
		|INTO TableOfSelectionOfGroundsAndPaymentDocuments
		|FROM
		|	NameOfBaseSelectionTableAndPaymentDocuments AS DocumentsTable
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON DocumentsTable.NameOfDocumentField = ARAPObjects.Object
		|				AND NOT ARAPObjects.DeletionMark
		|
		|INDEX BY
		|	DocumentOfSelection
		|";
		
	EndIf;
	
	QueryTextFromSelectionTable = "DROP TableOfSelectionOfGroundsAndPaymentDocuments";
	
	Query.Text = RequestTextForCreatingSelectionTable
					+ Common.QueryBatchSeparator() + Query.Text
					+ Common.QueryBatchSeparator() + QueryTextFromSelectionTable;
	
	Query.Text = StrReplace(Query.Text, "NameOfBaseSelectionTableAndPaymentDocuments", SelectionTableName_);
	Query.Text = StrReplace(Query.Text, "NameOfDocumentField",                           FilterFieldName);
	
	If SearchParameters.SearchMode_ = 1 Then
		
		// connection fields
		
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_DocumentRecorder_SearchMode_2_ARAPDocument",
			"Calculations.DocumentRecorder = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
			
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_ARAPObject_SearchMode_2_DocumentRecorder",
			"Calculations.ARAPObject = TableOfSelectionOfGroundsAndPaymentDocuments.ARAPObject");
			
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_ARAPDocument_SearchMode_2_DocumentRecorder",
			"Calculations.ARAPDocument = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
			
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_Recorder_SearchMode_2_ARAPDocument",
			"Calculations.Recorder = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
			
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_SalesOrder_SearchMode_2_Recorder",
			"Calculations.SalesOrder = TableOfSelectionOfGroundsAndPaymentDocuments.ARAPObject");
			
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_PurchaseOrder_SearchMode_2_Recorder",
			"Calculations.PurchaseOrder = TableOfSelectionOfGroundsAndPaymentDocuments.ARAPObject");
			
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_ARAPDocument_SearchMode_2_Recorder",
			"Calculations.ARAPDocument = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
		
		
		// selection fields
		
		Query.Text = StrReplace(Query.Text, "&PaymentBasisField_SettlementObject",
			"TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
			
		Query.Text = StrReplace(Query.Text, "&PaymentBasisField_CustomerOrder",
			"TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
			
		Query.Text = StrReplace(Query.Text, "&PaymentBasisField_OrderToSupplier",
			"TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
		
	ElsIf SearchParameters.SearchMode_ = 2 Then
		
		// connection fields
		
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_DocumentRecorder_SearchMode_2_ARAPDocument",
			"Calculations.ARAPDocument = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
			
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_ARAPObject_SearchMode_2_DocumentRecorder",
			"Calculations.DocumentRecorder = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
			
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_ARAPDocument_SearchMode_2_DocumentRecorder",
			"Calculations.DocumentRecorder = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
			
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_Recorder_SearchMode_2_ARAPDocument",
			"Calculations.ARAPDocument = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
			
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_SalesOrder_SearchMode_2_Recorder",
			"Calculations.Recorder = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
			
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_PurchaseOrder_SearchMode_2_Recorder",
			"Calculations.Recorder = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
			
		Query.Text = StrReplace(Query.Text, "&SearchMode_1_ARAPDocument_SearchMode_2_Recorder",
			"Calculations.Recorder = TableOfSelectionOfGroundsAndPaymentDocuments.DocumentOfSelection");
		
		
		// selection fields
		
		Query.Text = StrReplace(Query.Text, "&PaymentBasisField_SettlementObject",
			"Calculations.ARAPObject.Object");
			
		Query.Text = StrReplace(Query.Text, "&PaymentBasisField_CustomerOrder",
			"Calculations.SalesOrder.Object");
			
		Query.Text = StrReplace(Query.Text, "&PaymentBasisField_OrderToSupplier",
			"Calculations.PurchaseOrder.Object");
		
	EndIf;
	
EndProcedure

#EndRegion
