#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueue();
		Return;
	EndIf;
	
	PrepareDataForRegisteringTasksInNonOperationalQueue();
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	CreateTableOfPaymentObjects();
	InformationRegisters.ScheduleOfPayments.SetDataLocksForGraphCalculation(
		AdditionalProperties.TableOfPaymentObjects, "AccumulationRegister.FinancialInstrumentsARAP", "Contract");
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	
	QueryTextsForGettingChangeTable = 
		MonthEndTransactionsServer.QueryTextsForCaseChangeTable(Metadata(), Filter);
	
	Query = New Query;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text = QueryTextsForGettingChangeTable.InitialDataSampleText;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
	AdditionalProperties.Insert("SampleTextOfChangeTable", QueryTextsForGettingChangeTable.SampleTextOfChangeTable);
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;
	
	CreateNonOperationalQueueJobsWhenWriting();
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForFinancialInstruments(
		AdditionalProperties.TableOfPaymentObjects.UnloadColumn("PaymentObject"));
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and is placed in a temporary table for subsequent recording in the task registers.
	Query = New Query;
	Query.Text = AdditionalProperties.SampleTextOfChangeTable;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);	
	
	Query.Execute();
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text = "
	|SELECT DISTINCT
	|	Table.AccountingDimensionByPartners,
	|	Table.Contract,
	|	Table.AmountType,
	|	Table.ARAPDocument,
	|	Table.Currency
	|INTO RegisteredRecordsSettlementsOnFinancialInstrumentsChange
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND (Table.BeingPaid <> 0
	|	OR Table.Sum <> 0)
	|";
	
	Selection = Query.Execute().Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"RegisteredRecordsSettlementsOnFinancialInstrumentsChange", Selection.Next() And Selection.Count > 0);

	Query.SetParameter("Period", Common.ObjectAttributeValue(Filter.Recorder.Value, "Date"));
	Query.Text =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(&Period, MONTH)                  AS Period,
	|	Changes.ARAPDocument                    AS Document,
	|	Changes.AccountingDimensionByPartners.Counterparty AS Counterparty
	|FROM
	|	ChangesTableFinancialInstrumentsARAP AS Changes
	|WHERE
	|	VALUETYPE(&Recorder) IN (TYPE(Document.ReceivingLeaseServices), TYPE(Document.LeaseTermAdjustment),
	|			TYPE(Document.BankAccountReceiptNote))";
	
	NdsupChanges = Query.Execute().Unload();
	VATAccountingERP.ReflectInVATAccountingChangesInSettlementsOnFinancialInstruments(NdsupChanges);
	
EndProcedure

#EndRegion

#Region Private

// Generates a table of orders that were previously in the movements and that will now be recorded.
//
Procedure CreateTableOfPaymentObjects()

	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.Text = "
	|SELECT DISTINCT
	|	Table.Contract AS PaymentObject
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND Table.Contract <> UNDEFINED
	|";
	
	TableOfPaymentObjects = Query.Execute().Unload();
	
	TableOfNewPaymentObjects = Unload(, "Contract");
	TableOfNewPaymentObjects.GroupBy("Contract");
	For Each Record In TableOfNewPaymentObjects Do
		If Not ValueIsFilled(Record.Contract) Then
			Continue;
		EndIf;
		If TableOfPaymentObjects.Find(Record.Contract, "PaymentObject") = Undefined Then
			TableOfPaymentObjects.Add().PaymentObject = Record.Contract;
		EndIf;
	EndDo;
	
	AdditionalProperties.Insert("TableOfPaymentObjects", TableOfPaymentObjects);
	
EndProcedure

#Region BackdateJobQueue

Procedure PrepareDataForRegisteringTasksInNonOperationalQueue()
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") 
		And GetFunctionalOption("UseBalanceSheetStatement") Then
		
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager;
		Query.Text = "
		|SELECT
		|	InitialEntries.Recorder AS Recorder,
		|	InitialEntries.Period AS Period,
		|	InitialEntries.Active AS Active,
		|	InitialEntries.RecordType AS RecordType,
		|	InitialEntries.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	InitialEntries.Contract AS Contract,
		|	InitialEntries.AmountType AS AmountType,
		|	InitialEntries.BusinessOperation AS BusinessOperation,
		|	InitialEntries.ReversingEntry AS ReversingEntry,
		|	InitialEntries.SumMan AS SumMan
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.FinancialInstrumentsARAP AS InitialEntries
		|WHERE
		|	InitialEntries.Recorder = &Recorder";
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Execute();
		
		AdditionalProperties.Insert("TemporaryTableManagerJobQueue", Query.TempTablesManager);
		
	EndIf;
	
EndProcedure

Procedure CreateNonOperationalQueueJobsWhenWriting()
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") 
		And GetFunctionalOption("UseBalanceSheetStatement") Then
		
		Query = New Query;
		Query.TempTablesManager = AdditionalProperties.TemporaryTableManagerJobQueue;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Text = "
		|SELECT DISTINCT
		|	Table.Recorder AS Document,
		|	Table.Period AS TaskPeriod,
		|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|INTO QueueDataForAdditionalDocumentsManBalance
		|FROM
		|	(SELECT
		|		InitialEntries.Recorder AS Recorder,
		|		InitialEntries.Period AS Period,
		|		InitialEntries.Active AS Active,
		|		InitialEntries.RecordType AS RecordType,
		|		InitialEntries.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		InitialEntries.Contract AS Contract,
		|		InitialEntries.AmountType AS AmountType,
		|		InitialEntries.BusinessOperation AS BusinessOperation,
		|		InitialEntries.ReversingEntry AS ReversingEntry,
		|		InitialEntries.SumMan AS SumMan
		|	FROM
		|		VT_TaskQueueInitialEntries AS InitialEntries
		|
		|	UNION ALL
		|
		|	SELECT
		|		Records.Recorder AS Recorder,
		|		Records.Period AS Period,
		|		Records.Active AS Active,
		|		Records.RecordType AS RecordType,
		|		Records.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		Records.Contract AS Contract,
		|		Records.AmountType AS AmountType,
		|		Records.BusinessOperation AS BusinessOperation,
		|		Records.ReversingEntry AS ReversingEntry,
		|		-Records.SumMan AS SumMan
		|	FROM
		|		AccumulationRegister.FinancialInstrumentsARAP AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.AccountingDimensionByPartners,
		|	Table.Contract,
		|	Table.AmountType,
		|	Table.BusinessOperation,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.SumMan) <> 0
		|
		|INDEX BY
		|	AccountingDimensionByPartners
		|;
		|DROP VT_TaskQueueInitialEntries";

		Query.Execute();

		BackdateJobQueue.CreateNonOperationalQueueJobsWhenRecordingRecordset(ThisObject,
			Query.TempTablesManager);
		TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager,
			"QueueDataForAdditionalDocumentsManBalance");
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf