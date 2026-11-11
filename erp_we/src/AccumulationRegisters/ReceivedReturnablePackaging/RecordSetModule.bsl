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
	|	Table.Period              AS Period,
	|	Table.DocumentInflow AS DocumentInflow,
	|	Table.Products        AS Products,
	|	Table.Characteristic      AS Characteristic,
	|	Table.Partner             AS Partner,
	|	Table.DepositIsRequired   AS DepositIsRequired,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.Count
	|		ELSE
	|			-Table.Count
	|	END                      AS CountBeforeWrite,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.Sum
	|		ELSE
	|			-Table.Sum
	|	END                      AS SumBeforeWrite
	|INTO RegisteredRecordsAcceptedReturnPackagingBeforeRecording
	|FROM
	|	AccumulationRegister.ReceivedReturnablePackaging AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND NOT &IsNew
	|";
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
	|	ChangesTable.Period                      AS Period,
	|	ChangesTable.DocumentInflow         AS DocumentInflow,
	|	ChangesTable.Products                AS Products,
	|	ChangesTable.Characteristic              AS Characteristic,
	|	ChangesTable.Partner                     AS Partner,
	|	ChangesTable.DepositIsRequired           AS DepositIsRequired,
	|	SUM(ChangesTable.CountUpdate)  AS CountUpdate,
	|	SUM(ChangesTable.SumUpdate)       AS SumUpdate
	|INTO RegisteredRecordsAcceptedReturnPackagingChange
	|FROM
	|	(SELECT
	|		Table.Period                 AS Period,
	|		Table.DocumentInflow    AS DocumentInflow,
	|		Table.Products           AS Products,
	|		Table.Characteristic         AS Characteristic,
	|		Table.Partner                AS Partner,
	|		Table.DepositIsRequired      AS DepositIsRequired,
	|		Table.CountBeforeWrite AS CountUpdate,
	|		Table.SumBeforeWrite      AS SumUpdate
	|	FROM
	|		RegisteredRecordsAcceptedReturnPackagingBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Period              AS Period,
	|		Table.DocumentInflow AS DocumentInflow,
	|		Table.Products        AS Products,
	|		Table.Characteristic      AS Characteristic,
	|		Table.Partner             AS Partner,
	|		Table.DepositIsRequired   AS DepositIsRequired,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.Count
	|			ELSE
	|				Table.Count
	|		END                      AS CountUpdate,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.Sum
	|			ELSE
	|				Table.Sum
	|		END                      AS SumUpdate
	|	FROM
	|		AccumulationRegister.ReceivedReturnablePackaging AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Period,
	|	ChangesTable.DocumentInflow,
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Partner,
	|	ChangesTable.DepositIsRequired
	|
	|HAVING
	|	SUM(ChangesTable.CountUpdate) > 0
	|	OR SUM(ChangesTable.SumUpdate) > 0
	|;
	|DROP RegisteredRecordsAcceptedReturnPackagingBeforeRecording
	|";
	
	QueryResultsArray = Query.ExecuteBatch();
	QueryResult = QueryResultsArray[0]; // QueryResult
	Selection = QueryResult.Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"RegisteredRecordsAcceptedReturnPackagingChange", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

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
		|	InitialEntries.DocumentInflow AS DocumentInflow,
		|	InitialEntries.DepositIsRequired AS DepositIsRequired,
		|	InitialEntries.Sum AS Sum,
		|	InitialEntries.ReversingEntry AS ReversingEntry
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.ReceivedReturnablePackaging AS InitialEntries
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
		|	Table.DocumentInflow AS DocumentInflow
		|INTO QueueDataForAdditionalDocumentsManBalance
		|FROM
		|	(SELECT
		|		InitialEntries.Recorder AS Recorder,
		|		InitialEntries.Period AS Period,
		|		InitialEntries.Active AS Active,
		|		InitialEntries.RecordType AS RecordType,
		|		InitialEntries.DocumentInflow AS DocumentInflow,
		|		InitialEntries.DepositIsRequired AS DepositIsRequired,
		|		InitialEntries.Sum AS Sum,
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
		|		Records.DocumentInflow AS DocumentInflow,
		|		Records.DepositIsRequired AS DepositIsRequired,
		|		-Records.Sum AS Sum,
		|		Records.ReversingEntry AS ReversingEntry
		|	FROM
		|		AccumulationRegister.ReceivedReturnablePackaging AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.DocumentInflow,
		|	Table.DepositIsRequired,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.Sum) <> 0
		|
		|INDEX BY
		|	DocumentInflow
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

#EndIf
