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
	
	QueryTextsForGettingChangeTable = 
		MonthEndTransactionsServer.QueryTextsForCaseChangeTable(Metadata(), Filter);
	
	Query = New Query;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text = QueryTextsForGettingChangeTable.InitialDataSampleText;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
	AdditionalProperties.Insert("SampleTextOfChangeTable",
		QueryTextsForGettingChangeTable.SampleTextOfChangeTable);
	
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
	
	Query = New Query;
	Query.Text = AdditionalProperties.SampleTextOfChangeTable;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.Execute();
	
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
		|	InitialEntries.AmountType AS AmountType,
		|	InitialEntries.Sum AS Sum,
		|	InitialEntries.SumMan AS SumMan,
		|	InitialEntries.SumCompl AS SumCompl,
		|	InitialEntries.PermanentDifference AS PermanentDifference,
		|	InitialEntries.CostTD AS CostTD,
		|	InitialEntries.BusinessOperation AS BusinessOperation,
		|	InitialEntries.RowID AS RowID,
		|	InitialEntries.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	InitialEntries.FinRecordID AS FinRecordID,
		|	InitialEntries.ReversingEntry AS ReversingEntry
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.LossAllowance AS InitialEntries
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
		|	SUM(Table.SumMan) AS SumMan
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
		|		InitialEntries.AmountType AS AmountType,
		|		InitialEntries.Sum AS Sum,
		|		InitialEntries.SumMan AS SumMan,
		|		InitialEntries.SumCompl AS SumCompl,
		|		InitialEntries.PermanentDifference AS PermanentDifference,
		|		InitialEntries.CostTD AS CostTD,
		|		InitialEntries.BusinessOperation AS BusinessOperation,
		|		InitialEntries.RowID AS RowID,
		|		InitialEntries.BusinessTransactionSetting AS BusinessTransactionSetting,
		|		InitialEntries.FinRecordID AS FinRecordID,
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
		|		Records.AmountType AS AmountType,
		|		-Records.Sum AS Sum,
		|		-Records.SumMan AS SumMan,
		|		-Records.SumCompl AS SumCompl,
		|		-Records.PermanentDifference AS PermanentDifference,
		|		-Records.CostTD AS CostTD,
		|		Records.BusinessOperation AS BusinessOperation,
		|		Records.RowID AS RowID,
		|		Records.BusinessTransactionSetting AS BusinessTransactionSetting,
		|		Records.FinRecordID AS FinRecordID,
		|		Records.ReversingEntry AS ReversingEntry
		|	FROM
		|		AccumulationRegister.LossAllowance AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|		Table.Active,
		|		Table.RecordType,
		|		Table.Period,
		|		Table.Recorder,
		|		Table.AccountingDimensionByPartners,
		|		Table.ARAPObject,
		|		Table.Currency,
		|		Table.ARAPDocument,
		|		Table.AmountType,
		|		Table.BusinessOperation,
		|		Table.RowID,
		|		Table.BusinessTransactionSetting,
		|		Table.FinRecordID,
		|		Table.ReversingEntry
		|HAVING
		|	SUM(Table.Sum) <> 0 OR SUM(Table.SumMan) <> 0 OR SUM(Table.SumCompl) <> 0
		|	OR SUM(Table.PermanentDifference) <> 0 OR SUM(Table.CostTD) <> 0
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
