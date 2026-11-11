#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueue();
		Return;
	EndIf;
	
	PrepareDataForRegisteringTasksInNonOperationalQueue();
	
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
	
	CreateTableOfPaymentObjects();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;
	
	CreateNonOperationalQueueJobsWhenWriting();
	
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
	
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForCashInTransit(AdditionalProperties.TableOfPaymentObjects);
	
EndProcedure

#EndRegion

#Region Private

// Generates a table of senders and recipients who were previously in the movements and who will be recorded.
//
Procedure CreateTableOfPaymentObjects()
	
	TypesOfTransfersBetweenStorageLocations = New Array;
	TypesOfTransfersBetweenStorageLocations.Add(Enums.CashTransferKinds.CashDepositToBank);
	TypesOfTransfersBetweenStorageLocations.Add(Enums.CashTransferKinds.CashCollectionFromBank_);
	TypesOfTransfersBetweenStorageLocations.Add(Enums.CashTransferKinds.TransferToAnotherCashAccount);
	TypesOfTransfersBetweenStorageLocations.Add(Enums.CashTransferKinds.CashTransferToOtherAccount);
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.Text = "
	|SELECT DISTINCT
	|	CashInTransit.Recipient AS BankAccountCashAccount,
	|	
	|	CASE WHEN CashTransferKind IN (
	|		VALUE(Enum.CashTransferKinds.CashDepositToBank),
	|		VALUE(Enum.CashTransferKinds.CashCollectionFromBank_),
	|		VALUE(Enum.CashTransferKinds.CashTransferToOtherAccount),
	|		VALUE(Enum.CashTransferKinds.TransferToAnotherCashAccount))
	|	THEN
	|		CashInTransit.Sender
	|	WHEN CashTransferKind IN (
	|		VALUE(Enum.CashTransferKinds.ForeignExchangeBuying),
	|		VALUE(Enum.CashTransferKinds.ForeignExchangeSelling))
	|	THEN
	|		CashInTransit.Counterparty
	|	END AS PaymentObject
	|FROM
	|	AccumulationRegister.CashInTransit AS CashInTransit
	|WHERE
	|	CashInTransit.Recorder = &Recorder
	|	AND CASE WHEN CashTransferKind IN (
	|		VALUE(Enum.CashTransferKinds.CashDepositToBank),
	|		VALUE(Enum.CashTransferKinds.CashCollectionFromBank_),
	|		VALUE(Enum.CashTransferKinds.CashTransferToOtherAccount),
	|		VALUE(Enum.CashTransferKinds.TransferToAnotherCashAccount))
	|	THEN
	|		CashInTransit.Sender
	|	WHEN CashTransferKind IN (
	|		VALUE(Enum.CashTransferKinds.ForeignExchangeBuying),
	|		VALUE(Enum.CashTransferKinds.ForeignExchangeSelling))
	|	THEN
	|		CashInTransit.Counterparty
	|	END <> UNDEFINED
	|	AND CashInTransit.CashTransferKind <> VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)
	|";
	
	TableOfPaymentObjects = Query.Execute().Unload();
	
	TableOfNewPaymentObjects = PaymentObjectsByRecordSet();
	
	For Each Record In TableOfNewPaymentObjects Do
		
		If Record.CashTransferKind = Enums.CashTransferKinds.CashReceiptFromBankByAcquiring Then
			Continue;
		EndIf;
		
		TheStructureOfTheSearch = New Structure;;
		TheStructureOfTheSearch.Insert("BankAccountCashAccount", Record.Recipient);
		If TypesOfTransfersBetweenStorageLocations.Find(Record.CashTransferKind) <> Undefined Then
			If ValueIsFilled(Record.Sender) Then
				TheStructureOfTheSearch.Insert("PaymentObject", Record.Sender);
			Else
				Continue;
			EndIf;
		Else
			TheStructureOfTheSearch.Insert("PaymentObject", Record.Counterparty);
		EndIf;
		
		If Not TableOfPaymentObjects.FindRows(TheStructureOfTheSearch).Count() Then
			NewRow = TableOfPaymentObjects.Add();
			NewRow.PaymentObject = TheStructureOfTheSearch.PaymentObject;
			NewRow.BankAccountCashAccount = TheStructureOfTheSearch.BankAccountCashAccount;
		EndIf;
	EndDo;
	
	AdditionalProperties.Insert("TableOfPaymentObjects", TableOfPaymentObjects);
	
EndProcedure

Function PaymentObjectsByRecordSet()

	Query = New Query;
	Query.Text = 
		"SELECT
		|	RecordSet.RecordType AS RecordType,
		|	RecordSet.Recorder AS Recorder,
		|	RecordSet.Organization AS Organization,
		|	RecordSet.CashTransferKind AS CashTransferKind,
		|	RecordSet.Recipient AS Recipient,
		|	RecordSet.Sender AS Sender,
		|	RecordSet.Counterparty AS Counterparty,
		|	RecordSet.Contract AS Contract,
		|	RecordSet.Currency AS Currency,
		|	RecordSet.Sum AS Sum
		|INTO RecordsTable
		|FROM
		|	&RecordSet AS RecordSet
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ISNULL(Receipt.CashTransferKind, Expense.CashTransferKind) AS CashTransferKind,
		|	ISNULL(Receipt.Recipient, Expense.Recipient) AS Recipient,
		|	ISNULL(Receipt.Sender, Expense.Sender) AS Sender,
		|	ISNULL(Receipt.Counterparty, Expense.Counterparty) AS Counterparty,
		|	ISNULL(Receipt.Sum, 0) - ISNULL(Expense.Sum, 0) AS Sum
		|FROM
		|	(SELECT
		|		RecordsTable.Recorder AS Recorder,
		|		RecordsTable.Organization AS Organization,
		|		RecordsTable.CashTransferKind AS CashTransferKind,
		|		RecordsTable.Recipient AS Recipient,
		|		RecordsTable.Sender AS Sender,
		|		RecordsTable.Counterparty AS Counterparty,
		|		RecordsTable.Contract AS Contract,
		|		RecordsTable.Currency AS Currency,
		|		SUM(RecordsTable.Sum) AS Sum
		|	FROM
		|		RecordsTable AS RecordsTable
		|	WHERE
		|		RecordsTable.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	
		|	GROUP BY
		|		RecordsTable.Recorder,
		|		RecordsTable.Organization,
		|		RecordsTable.CashTransferKind,
		|		RecordsTable.Recipient,
		|		RecordsTable.Sender,
		|		RecordsTable.Counterparty,
		|		RecordsTable.Contract,
		|		RecordsTable.Currency) AS Receipt
		|		FULL JOIN (SELECT
		|			RecordsTable.Recorder AS Recorder,
		|			RecordsTable.Organization AS Organization,
		|			RecordsTable.CashTransferKind AS CashTransferKind,
		|			RecordsTable.Recipient AS Recipient,
		|			RecordsTable.Sender AS Sender,
		|			RecordsTable.Counterparty AS Counterparty,
		|			RecordsTable.Contract AS Contract,
		|			RecordsTable.Currency AS Currency,
		|			SUM(RecordsTable.Sum) AS Sum
		|		FROM
		|			RecordsTable AS RecordsTable
		|		WHERE
		|			RecordsTable.RecordType = VALUE(AccumulationRecordType.Expense)
		|		
		|		GROUP BY
		|			RecordsTable.Recorder,
		|			RecordsTable.Organization,
		|			RecordsTable.CashTransferKind,
		|			RecordsTable.Recipient,
		|			RecordsTable.Sender,
		|			RecordsTable.Counterparty,
		|			RecordsTable.Contract,
		|			RecordsTable.Currency) AS Expense
		|		ON Receipt.Recorder = Expense.Recorder
		|			AND Receipt.Organization = Expense.Organization
		|			AND Receipt.CashTransferKind = Expense.CashTransferKind
		|			AND Receipt.Recipient = Expense.Recipient
		|			AND Receipt.Sender = Expense.Sender
		|			AND Receipt.Counterparty = Expense.Counterparty
		|			AND Receipt.Contract = Expense.Contract
		|			AND Receipt.Currency = Expense.Currency
		|WHERE
		|	ISNULL(Receipt.Sum, 0) - ISNULL(Expense.Sum, 0) <> 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP RecordsTable";
	
	Query.SetParameter("RecordSet", Unload());
	
	Return Query.Execute().Unload();

EndFunction

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
		|	InitialEntries.Recipient AS Recipient,
		|	InitialEntries.Organization AS Organization,
		|	InitialEntries.ReversingEntry AS ReversingEntry,
		|	InitialEntries.SumMan AS SumMan
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.CashInTransit AS InitialEntries
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
		|	Table.Organization AS Organization,
		|	VALUE(Catalog.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords) AS JobKind
		|FROM
		|	(SELECT
		|		InitialEntries.Recorder AS Recorder,
		|		InitialEntries.Period AS Period,
		|		InitialEntries.Active AS Active,
		|		InitialEntries.RecordType AS RecordType,
		|		InitialEntries.Recipient AS Recipient,
		|		InitialEntries.Organization AS Organization,
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
		|		Records.Recipient AS Recipient,
		|		Records.Organization AS Organization,
		|		Records.ReversingEntry AS ReversingEntry,
		|		-Records.SumMan AS SumMan
		|	FROM
		|		AccumulationRegister.CashInTransit AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.Recipient,
		|	Table.Organization,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.SumMan) <> 0
		|;
		|DROP VT_TaskQueueInitialEntries";

		DataForRegisteringTasks = Query.Execute().Unload();

		BackdateJobQueue.CreateNonOperationalQueueJobsWhenRecordingRecordset(ThisObject, Undefined,
			DataForRegisteringTasks);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf