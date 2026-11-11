#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure BeforeWrite(Cancel, Replacing)
		
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
		AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	Calculations.Recorder               AS Recorder,
	|	Calculations.Period                    AS Period,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.SalesOrder              AS SalesOrder,
	|	Calculations.ARAPDocument         AS ARAPDocument,
	|	Calculations.Currency                    AS Currency,
	|
	|	Calculations.Debt             AS Debt,
	|	Calculations.ARAPMan          AS ARAPMan,
	|	Calculations.DebtLocal         AS DebtLocal,
	|	Calculations.Prepayment       AS Prepayment,
	|	Calculations.PrepaymentMan    AS PrepaymentMan,
	|	Calculations.PrepaymentLocal   AS PrepaymentLocal,
	|	Calculations.DepositForPackage      AS DepositForPackage,
	|	Calculations.DepositForPackageLocal  AS DepositForPackageLocal,
	|
	|	Calculations.BusinessOperation         AS BusinessOperation,
	|	Calculations.CashFlowItem AS CashFlowItem
	|INTO SettlementsWithClientsOnDocumentsInitialRegisteredRecords
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|WHERE
	|	Calculations.Recorder = &Recorder
	|");
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	QueryText =
	"SELECT DISTINCT
	|	Table.Period                       AS Period,
	|	Table.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
	|	Table.SalesOrder                 AS ARAPObject,
	|	Table.ARAPDocument            AS ARAPDocument,
	|	Table.Recorder                  AS Recorder
	|INTO SettlementsWithClientsOnDocumentsChanges
	|FROM
	|	(SELECT
	|		Calculations.Recorder               AS Recorder,
	|		Calculations.Period                    AS Period,
	|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Calculations.SalesOrder              AS SalesOrder,
	|		Calculations.ARAPDocument         AS ARAPDocument,
	|		Calculations.Currency                    AS Currency,
	|
	|		Calculations.Debt             AS Debt,
	|		Calculations.ARAPMan          AS ARAPMan,
	|		Calculations.DebtLocal         AS DebtLocal,
	|		Calculations.Prepayment       AS Prepayment,
	|		Calculations.PrepaymentMan    AS PrepaymentMan,
	|		Calculations.PrepaymentLocal   AS PrepaymentLocal,
	|		Calculations.DepositForPackage      AS DepositForPackage,
	|		Calculations.DepositForPackageLocal  AS DepositForPackageLocal,
	|
	|		Calculations.BusinessOperation         AS BusinessOperation,
	|		Calculations.CashFlowItem AS CashFlowItem
	|	FROM
	|		SettlementsWithClientsOnDocumentsInitialRegisteredRecords AS Calculations
	|		
	|	UNION ALL
	|		
	|	SELECT
	|		Calculations.Recorder               AS Recorder,
	|		Calculations.Period                    AS Period,
	|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Calculations.SalesOrder              AS SalesOrder,
	|		Calculations.ARAPDocument         AS ARAPDocument,
	|		Calculations.Currency                    AS Currency,
	|
	|		-Calculations.Debt             AS Debt,
	|		-Calculations.ARAPMan          AS ARAPMan,
	|		-Calculations.DebtLocal         AS DebtLocal,
	|		-Calculations.Prepayment       AS Prepayment,
	|		-Calculations.PrepaymentMan    AS PrepaymentMan,
	|		-Calculations.PrepaymentLocal   AS PrepaymentLocal,
	|		-Calculations.DepositForPackage      AS DepositForPackage,
	|		-Calculations.DepositForPackageLocal  AS DepositForPackageLocal,
	|
	|		Calculations.BusinessOperation         AS BusinessOperation,
	|		Calculations.CashFlowItem AS CashFlowItem
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|	WHERE Calculations.Recorder = &Recorder
	|) AS Table
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	Table.AccountingDimensionByPartners,
	|	Table.SalesOrder,
	|	Table.ARAPDocument,
	|	Table.Currency,
	|	Table.BusinessOperation,
	|	Table.CashFlowItem
	|HAVING
	|	SUM(Table.Debt) <> 0 OR SUM(Table.ARAPMan) <> 0 OR SUM(Table.DebtLocal) <> 0
	|	OR SUM(Table.Prepayment) <> 0 OR SUM(Table.PrepaymentMan) <> 0 OR SUM(Table.PrepaymentLocal) <> 0
	|	OR SUM(Table.DepositForPackage) <> 0 OR SUM(Table.DepositForPackageLocal) <> 0
	|";
	ArrayOfRequestTexts.Add(QueryText);
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	Table.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
	|	Table.ARAPObject               AS ARAPObject,
	|	Table.Recorder                  AS Document
	|INTO SettlementsWithClientsAccordingToDocumentsTasksForSettlementsWithClients
	|FROM
	|	SettlementsWithClientsOnDocumentsChanges AS Table
	|WHERE
	|	VALUETYPE(Table.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)";
	ArrayOfRequestTexts.Add(QueryText);
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		QueryText =
		"SELECT DISTINCT
		|	BEGINOFPERIOD(Changes.Period, MONTH)         AS Period,
		|	Changes.ARAPDocument                    AS Document,
		|	Changes.AccountingDimensionByPartners.Counterparty AS Counterparty
		|FROM
		|	SettlementsWithClientsOnDocumentsChanges AS Changes";
		
		ArrayOfRequestTexts.Add(QueryText);
	EndIf;
	
	ArrayOfRequestTexts.Add("DROP SettlementsWithClientsOnDocumentsChanges");
	ArrayOfRequestTexts.Add("DROP SettlementsWithClientsOnDocumentsInitialRegisteredRecords");
	
	Query = New Query(StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator()));
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	Result = Query.ExecuteBatch();
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		VATAccountingERP.ReflectChangesInSettlementsWithCustomersInVATAccounting(Result[2].Unload());
	EndIf;
	
EndProcedure

#EndRegion

#EndIf