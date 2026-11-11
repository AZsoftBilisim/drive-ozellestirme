#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueue();
		Return;
	EndIf;
	
	PrepareDataForRegisteringTasksInNonOperationalQueue();
	
	If Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	LockForUpdate = True;
	
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew",    AdditionalProperties.DocumentProperties.IsNew);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	Table.Period AS Period,
	|	Table.GiftCertificate AS GiftCertificate,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.Sum
	|		ELSE -Table.Sum
	|	END AS SumBeforeWrite
	|INTO 
	|	GiftCertificatesBeforeWrite
	|FROM
	|	AccumulationRegister.GiftCertificates AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND NOT &IsNew";
	
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;
	
	CreateNonOperationalQueueJobsWhenWriting();
	
	If Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and placed in a temporary table.
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	ChangesTable.Period AS Period,
	|	ChangesTable.GiftCertificate AS GiftCertificate,
	|	SUM(ChangesTable.SumUpdate) AS SumUpdate
	|INTO ChangesTableGiftCertificates
	|FROM
	|	(SELECT
	|		Table.Period AS Period,
	|		Table.GiftCertificate AS GiftCertificate,
	|		Table.SumBeforeWrite AS SumUpdate
	|	FROM
	|		GiftCertificatesBeforeWrite AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period AS Period,
	|		Table.GiftCertificate AS GiftCertificate,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.Sum
	|			ELSE
	|				Table.Sum
	|		END AS SumUpdate
	|	FROM
	|		AccumulationRegister.GiftCertificates AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Period,
	|	ChangesTable.GiftCertificate
	|
	|HAVING
	|	SUM(ChangesTable.SumUpdate) > 0
	|;
	|DROP GiftCertificatesBeforeWrite
	|";
	
	Query.ExecuteBatch();
	
EndProcedure

#EndRegion

#Region Private

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
		|	InitialEntries.Sum AS Sum,
		|	InitialEntries.GiftCertificate AS GiftCertificate,
		|	InitialEntries.ReversingEntry AS ReversingEntry
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.GiftCertificates AS InitialEntries
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
		|	Table.GiftCertificate AS GiftCertificate
		|INTO QueueDataForAdditionalDocumentsManBalance
		|FROM
		|	(SELECT
		|		InitialEntries.Recorder AS Recorder,
		|		InitialEntries.Period AS Period,
		|		InitialEntries.Active AS Active,
		|		InitialEntries.RecordType AS RecordType,
		|		InitialEntries.Sum AS Sum,
		|		InitialEntries.GiftCertificate AS GiftCertificate,
		|		InitialEntries.ReversingEntry AS ReversingEntry
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
		|		-Records.Sum AS Sum,
		|		Records.GiftCertificate AS GiftCertificate,
		|		Records.ReversingEntry AS ReversingEntry
		|	FROM
		|		AccumulationRegister.GiftCertificates AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.GiftCertificate,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.Sum) <> 0
		|
		|INDEX BY
		|	GiftCertificate
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
