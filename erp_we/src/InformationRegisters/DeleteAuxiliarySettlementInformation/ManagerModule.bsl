
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Fills in the register of auxiliary information on changes in operational payment registers.
// 
// Parameters:
// 	TempTableManager - TempTablesManager - A Manager that contains a table with changes.
// 	TheseAreSettlementsWithCustomers - Boolean - these are settlements with clients.
Procedure FillInSupportingInformation(TempTableManager, TheseAreSettlementsWithCustomers = True) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	Query.Text = "
	|SELECT DISTINCT
	|	CASE WHEN Changes.ARAPDocument REFS Document.SourceDocument
	|						AND Changes.ARAPDocument <> VALUE(Document.SourceDocument.EmptyRef)
	|		THEN Changes.ARAPDocument
	|		ELSE Changes.Document
	|	END                                           AS ARAPDocument,
	|	BEGINOFPERIOD(CASE WHEN Changes.PaymentDate = DATETIME(1,1,1) OR Changes.ReversingEntry
	|							THEN Changes.RecorderDate
	|						ELSE Changes.PaymentDate
	|					END , DAY)      AS PlannedRepaymentDate
	|INTO ChangesToSupportingInformation
	|FROM
	|	&ChangeCalculations AS Changes
	|WHERE
	|	Changes.Sum <> 0 OR Changes.ToShip <> 0 OR Changes.AmountDue <> 0
	|;
	|SELECT
	|	Changes.ARAPDocument                                            AS ARAPDocument,
	|	Changes.PlannedRepaymentDate                                       AS PlannedRepaymentDate,
	|	MIN(ISNULL(Calculations.Recorder, UNDEFINED))                    AS DocumentRecorder,
	|	MAX(ISNULL(Calculations.LinkedDocument, UNDEFINED))             AS LinkedDocument,
	|	MIN(ISNULL(Calculations.OperationProcedure, UNDEFINED))                AS OperationProcedure,
	|	MIN(ISNULL(Calculations.SettlementProcedureByPaymentDate, UNDEFINED))     AS SettlementProcedure,
	|	MIN(ISNULL(Calculations.DocumentCurrency, UNDEFINED))                AS DocumentCurrency,
	|	MAX(ISNULL(Calculations.CashFlowItem, UNDEFINED)) AS CashFlowItem
	|FROM
	|	ChangesToSupportingInformation AS Changes
	|		LEFT JOIN &Calculations AS Calculations
	|			ON Changes.ARAPDocument = Calculations.Recorder
	|				AND Changes.PlannedRepaymentDate = BEGINOFPERIOD(CASE WHEN Calculations.PaymentDate = DATETIME(1,1,1) OR Calculations.ReversingEntry
	|																		THEN Calculations.RecorderDate
	|																	ELSE Calculations.PaymentDate
	|																END , DAY)
	|				AND (Calculations.Sum <> 0 OR Calculations.ToShip <> 0 OR Calculations.AmountDue <> 0)
	|WHERE
	|	VALUETYPE(Changes.ARAPDocument) <> TYPE(Document.SourceDocument)
	|GROUP BY
	|	Changes.ARAPDocument,
	|	Changes.PlannedRepaymentDate
	|
	|UNION
	|
	|SELECT
	|	Changes.ARAPDocument                                            AS ARAPDocument,
	|	Changes.PlannedRepaymentDate                                       AS PlannedRepaymentDate,
	|	MIN(ISNULL(Calculations.Recorder, UNDEFINED))                    AS DocumentRecorder,
	|	MAX(ISNULL(Calculations.LinkedDocument, UNDEFINED))             AS LinkedDocument,
	|	MIN(ISNULL(Calculations.OperationProcedure, UNDEFINED))                AS OperationProcedure,
	|	MIN(ISNULL(Calculations.SettlementProcedureByPaymentDate, UNDEFINED))     AS SettlementProcedure,
	|	MIN(ISNULL(Calculations.DocumentCurrency, UNDEFINED))                AS DocumentCurrency,
	|	MAX(ISNULL(Calculations.CashFlowItem, UNDEFINED)) AS CashFlowItem
	|FROM
	|	ChangesToSupportingInformation AS Changes
	|		LEFT JOIN &Calculations AS Calculations
	|			ON Changes.ARAPDocument = Calculations.ARAPDocument
	|				AND Changes.PlannedRepaymentDate = BEGINOFPERIOD(CASE WHEN Calculations.PaymentDate = DATETIME(1,1,1) OR Calculations.ReversingEntry
	|																		THEN Calculations.RecorderDate
	|																	ELSE Calculations.PaymentDate
	|																END , DAY)
	|				AND (Calculations.Sum <> 0 OR Calculations.ToShip <> 0 OR Calculations.AmountDue <> 0)
	|WHERE
	|	VALUETYPE(Changes.ARAPDocument) = TYPE(Document.SourceDocument)
	|GROUP BY
	|	Changes.ARAPDocument,
	|	Changes.PlannedRepaymentDate
	|;
	|DROP ChangesToSupportingInformation";
	If TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text,"&ChangeCalculations","SettlementsWithCustomersChanges");
		Query.Text = StrReplace(Query.Text,"&Calculations","AccumulationRegister.CustomersARAPAccounting");
	Else
		Query.Text = StrReplace(Query.Text,"&ChangeCalculations","VendorsARAPAccountingChanges");
		Query.Text = StrReplace(Query.Text,"&Calculations","AccumulationRegister.VendorsARAPAccounting");
		Query.Text = StrReplace(Query.Text,"ToShip","ToReceive");
	EndIf;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RecordSet = CreateRecordSet();
		RecordSet.Filter.ARAPDocument.Set(Selection.ARAPDocument);
		RecordSet.Filter.PlannedRepaymentDate.Set(Selection.PlannedRepaymentDate);
		If Selection.DocumentRecorder <> Undefined Then
			FillPropertyValues(RecordSet.Add(), Selection);
		EndIf;
		RecordSet.Write();
	EndDo;
EndProcedure

#EndRegion

#EndIf
