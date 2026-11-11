#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueue();
		Return;
	EndIf;
	
	PrepareDataForRegisteringTasksInNonOperationalQueue();
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
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
	
	If TypeOf(Filter.Recorder.Value) = Type("DocumentRef.CashAccountReceiptNote") Then
		AdditionalProperties.Insert("PaymentScheduleCalculationDates", PaymentScheduleCalculationDates());
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;
	
	CreateNonOperationalQueueJobsWhenWriting();
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and is placed in a temporary table for subsequent recording in the task registers.
	Query = New Query;
	Query.Text = AdditionalProperties.SampleTextOfChangeTable;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);	
	
	Query.Execute();
	
	If TypeOf(Filter.Recorder.Value) = Type("DocumentRef.CashAccountReceiptNote") Then
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForExpectedCashReceipts(
			AdditionalProperties.PaymentScheduleCalculationDates);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Generates an array of dates in which register movements change.
//
Function PaymentScheduleCalculationDates()

	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.Text = "
	|SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, DAY) AS DateOfCalculation
	|FROM
	|	AccumulationRegister.CashAccountBalance AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|";
	
	SettlementDates_ = Query.Execute().Unload().UnloadColumn("DateOfCalculation");
	
	NewSettlementDates = UnloadColumn("Period");
	For Each NewSettlementDate In NewSettlementDates Do
		NewCalculationDateStartOfDay = BegOfDay(NewSettlementDate);
		If SettlementDates_.Find(NewCalculationDateStartOfDay) = Undefined Then
			SettlementDates_.Add(NewCalculationDateStartOfDay);
		EndIf;
	EndDo;
	
	Return SettlementDates_;
	
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
		|	InitialEntries.CashAccount AS CashAccount,
		|	InitialEntries.Organization AS Organization,
		|	InitialEntries.ReversingEntry AS ReversingEntry,
		|	InitialEntries.SumMan AS SumMan
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.CashAccountBalance AS InitialEntries
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
		|		InitialEntries.CashAccount AS CashAccount,
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
		|		Records.CashAccount AS CashAccount,
		|		Records.Organization AS Organization,
		|		Records.ReversingEntry AS ReversingEntry,
		|		-Records.SumMan AS SumMan
		|	FROM
		|		AccumulationRegister.CashAccountBalance AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.CashAccount,
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