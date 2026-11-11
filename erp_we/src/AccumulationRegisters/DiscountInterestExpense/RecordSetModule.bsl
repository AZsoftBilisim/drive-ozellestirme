#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueue();
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	PrepareDataForRegisteringTasksInNonOperationalQueue();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;

	CreateNonOperationalQueueJobsWhenWriting();

EndProcedure

#EndRegion

#Region Private

#Region BackdateJobQueue

Procedure PrepareDataForRegisteringTasksInNonOperationalQueue()
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager;
		Query.Text = "
		|SELECT
		|	InitialEntries.Active AS Active,
		|	InitialEntries.RecordType AS RecordType,
		|	InitialEntries.Period AS Period,
		|	InitialEntries.Recorder AS Recorder,
		|	InitialEntries.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	InitialEntries.ARAPObject AS ARAPObject,
		|	InitialEntries.Currency AS Currency,
		|	InitialEntries.ARAPDocument AS ARAPDocument,
		|	InitialEntries.DiscountingAmount AS DiscountingAmount,
		|	InitialEntries.DiscountingAmountCompl AS DiscountingAmountCompl,
		|	InitialEntries.DiscountingAmountMan AS DiscountingAmountMan,
		|	InitialEntries.DiscountRate AS DiscountRate,
		|	InitialEntries.FinRecordID AS FinRecordID,
		|	InitialEntries.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	InitialEntries.ReversingEntry AS ReversingEntry
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.DiscountInterestExpense AS InitialEntries
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
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		Query = New Query;
		Query.TempTablesManager = AdditionalProperties.TemporaryTableManagerJobQueue;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Text = "
		|SELECT DISTINCT
		|	Table.Recorder AS Document,
		|	Table.Period AS TaskPeriod,
		|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	SUM(Table.DiscountingAmountMan) AS DiscountingAmountMan
		|INTO QueueDataForAdditionalDocuments
		|FROM
		|	(SELECT
		|		InitialEntries.Active AS Active,
		|		InitialEntries.RecordType AS RecordType,
		|		InitialEntries.Period AS Period,
		|		InitialEntries.Recorder AS Recorder,
		|		InitialEntries.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		InitialEntries.ARAPObject AS ARAPObject,
		|		InitialEntries.Currency AS Currency,
		|		InitialEntries.ARAPDocument AS ARAPDocument,
		|		InitialEntries.DiscountingAmount AS DiscountingAmount,
		|		InitialEntries.DiscountingAmountCompl AS DiscountingAmountCompl,
		|		InitialEntries.DiscountingAmountMan AS DiscountingAmountMan,
		|		InitialEntries.DiscountRate AS DiscountRate,
		|		InitialEntries.FinRecordID AS FinRecordID,
		|		InitialEntries.BusinessTransactionSetting AS BusinessTransactionSetting,
		|		InitialEntries.ReversingEntry AS ReversingEntry
		|	FROM
		|		VT_TaskQueueInitialEntries AS InitialEntries
		|
		|	UNION ALL
		|
		|	SELECT
		|		Records.Active AS Active,
		|		Records.RecordType AS RecordType,
		|		Records.Period AS Period,
		|		Records.Recorder AS Recorder,
		|		Records.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		Records.ARAPObject AS ARAPObject,
		|		Records.Currency AS Currency,
		|		Records.ARAPDocument AS ARAPDocument,
		|		-Records.DiscountingAmount AS DiscountingAmount,
		|		-Records.DiscountingAmountCompl AS DiscountingAmountCompl,
		|		-Records.DiscountingAmountMan AS DiscountingAmountMan,
		|		Records.DiscountRate AS DiscountRate,
		|		Records.FinRecordID AS FinRecordID,
		|		Records.BusinessTransactionSetting AS BusinessTransactionSetting,
		|		Records.ReversingEntry AS ReversingEntry
		|	FROM
		|		AccumulationRegister.DiscountInterestExpense AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|		Table.Active,
		|		Table.RecordType,
		|		Table.Period,
		|		Table.Recorder,
		|		Table.AccountingDimensionByPartners ,
		|		Table.ARAPObject,
		|		Table.Currency,
		|		Table.ARAPDocument,
		|		Table.DiscountRate,
		|		Table.FinRecordID,
		|		Table.BusinessTransactionSetting,
		|		Table.ReversingEntry
		|HAVING
		|	SUM(Table.DiscountingAmount) <> 0 OR SUM(Table.DiscountingAmountCompl) <> 0
		|	OR SUM(Table.DiscountingAmountMan) <> 0
		|
		|INDEX BY
		|	AccountingDimensionByPartners
		|;
		|DROP VT_TaskQueueInitialEntries";

		Query.Execute();

		BackdateJobQueue.CreateNonOperationalQueueJobsWhenRecordingRecordset(ThisObject,
			Query.TempTablesManager);
		TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager,
			"QueueDataForAdditionalDocuments");
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf